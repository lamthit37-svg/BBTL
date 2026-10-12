// Liệt kê qua EnumDisplayMonitors: mỗi HMONITOR là một vùng của desktop ảo, đúng thứ cửa sổ có thể
// nằm lên. Tên card và tên màn hình tra thêm bằng EnumDisplayDevicesW. Gốc đi theo chiều ngược
// (thiết bị trước, vùng sau) nên máy không có thiết bị hiển thị nào phải rẽ sang nhánh dự phòng.
// Nguồn: Forge2 src/window/monitor.cpp@d7fcd76. Khác gốc (so với Forge2): enumerator mang tiền tố
// k; macro của windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32
// include trực tiếp; thân vòng lặp có nhánh tách thành hàm (ghi tại chỗ); khởi tạo aggregate ghi
// tên thành viên; biến tên at đổi thành slot.
#include "window/monitor.hpp"

#include "core/error.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "window/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

#include <shellscalingapi.h>
#include <windef.h>
#include <winerror.h>
#include <wingdi.h>
#include <winnt.h>
#include <winuser.h>

namespace game::window {

namespace {

// Tỉ lệ của gốc: cửa sổ nên chiếm tới 3/4 màn hình, không nhỏ hơn 3/4 của mức đó, cạnh chia hết 8.
constexpr double kDisplayFraction = 0.75;
constexpr double kMinDesiredFraction = 0.75;
constexpr std::uint32_t kSizeFactor = 8;
constexpr double kMillimetersPerInch = 25.4;

// DC của một thiết bị hiển thị, xoá khi ra khỏi phạm vi.
class DeviceContext {
public:
    explicit DeviceContext(const wchar_t* device) noexcept : handle_(CreateDCW(L"DISPLAY", device, nullptr, nullptr)) {}
    ~DeviceContext() {
        if (handle_ != nullptr) DeleteDC(handle_);
    }
    DeviceContext(const DeviceContext&) = delete;
    DeviceContext& operator=(const DeviceContext&) = delete;
    DeviceContext(DeviceContext&&) = delete;
    DeviceContext& operator=(DeviceContext&&) = delete;

    [[nodiscard]] HDC get() const noexcept { return handle_; }

private:
    HDC handle_ = nullptr;
};

[[nodiscard]] Rect to_rect(const RECT& rect) noexcept {
    return {.left = rect.left, .top = rect.top, .right = rect.right, .bottom = rect.bottom};
}

[[nodiscard]] bool by_height_then_width(Size left, Size right) noexcept {
    return std::tie(left.height, left.width) < std::tie(right.height, right.width);
}

// Mục adapter có tên thiết bị trùng device.
[[nodiscard]] std::optional<DISPLAY_DEVICEW> find_adapter(std::wstring_view device) noexcept {
    DISPLAY_DEVICEW adapter{};
    adapter.cb = sizeof(adapter);
    // Khác gốc: gốc là vòng for có câu if (tên trùng) return adapter trong thân.
    DWORD index = 0;
    bool is_listed = EnumDisplayDevicesW(nullptr, index, &adapter, 0) != FALSE;
    while (is_listed && device != std::data(adapter.DeviceName)) {
        ++index;
        is_listed = EnumDisplayDevicesW(nullptr, index, &adapter, 0) != FALSE;
    }
    if (!is_listed) return std::nullopt;
    return adapter;
}

// Tên màn hình đầu tiên gắn vào device; rỗng khi không có (phiên từ xa, màn hình ảo).
[[nodiscard]] std::string display_name(const wchar_t* device) {
    DISPLAY_DEVICEW display{};
    display.cb = sizeof(display);
    if (EnumDisplayDevicesW(device, 0, &display, 0) == FALSE) return {};
    return core::narrow(std::data(display.DeviceString));
}

[[nodiscard]] Size physical_size(const wchar_t* device) noexcept {
    const DeviceContext context(device);
    if (context.get() == nullptr) return {};
    const int width = std::max(GetDeviceCaps(context.get(), HORZSIZE), 0);
    const int height = std::max(GetDeviceCaps(context.get(), VERTSIZE), 0);
    const auto wide = static_cast<std::uint32_t>(width);
    const auto tall = static_cast<std::uint32_t>(height);
    return {.width = wide, .height = tall};
}

[[nodiscard]] Dpi effective_dpi(HMONITOR handle) noexcept {
    UINT horizontal = 0;
    UINT vertical = 0;
    if (FAILED(GetDpiForMonitor(handle, MDT_EFFECTIVE_DPI, &horizontal, &vertical))) return {};
    return {.x = horizontal, .y = vertical};
}

[[nodiscard]] std::vector<Size> display_modes(const wchar_t* device) {
    std::vector<Size> modes;
    DEVMODEW mode{};
    mode.dmSize = sizeof(mode);
    for (DWORD i = 0; EnumDisplaySettingsW(device, i, &mode) != FALSE; ++i) {
        const Size size{.width = mode.dmPelsWidth, .height = mode.dmPelsHeight};
        modes.push_back(size);
    }
    std::ranges::sort(modes, by_height_then_width);
    const auto repeated = std::ranges::unique(modes);
    modes.erase(repeated.begin(), repeated.end());
    return modes;
}

// Độ phân giải đang dùng; khi hệ thống không trả lời thì lấy cỡ của vùng màn hình.
[[nodiscard]] Size current_resolution(const wchar_t* device, const Rect& area) noexcept {
    DEVMODEW mode{};
    mode.dmSize = sizeof(mode);
    if (EnumDisplaySettingsW(device, ENUM_CURRENT_SETTINGS, &mode) == FALSE) return area.size();
    return {.width = mode.dmPelsWidth, .height = mode.dmPelsHeight};
}

// Chỉ số của mode trong modes, thêm vào đúng chỗ khi chưa có: chế độ hiện tại có thể không nằm
// trong danh sách hệ thống liệt kê (chế độ tuỳ biến của driver).
[[nodiscard]] std::size_t ensure_mode(std::vector<Size>& modes, Size mode) {
    auto slot = std::ranges::lower_bound(modes, mode, by_height_then_width);
    const bool is_listed = slot != modes.end() && *slot == mode;
    if (!is_listed) slot = modes.insert(slot, mode);
    return static_cast<std::size_t>(std::distance(modes.begin(), slot));
}

void fill_adapter(Monitor& monitor, std::wstring_view device) {
    const std::optional<DISPLAY_DEVICEW> adapter = find_adapter(device);
    if (!adapter) return;
    monitor.adapter = core::narrow(std::data(adapter->DeviceString));
    monitor.is_pruned = (adapter->StateFlags & DISPLAY_DEVICE_MODESPRUNED) != 0;
}

// Rỗng khi màn hình biến mất giữa lúc liệt kê.
[[nodiscard]] std::optional<Monitor> describe(HMONITOR handle) {
    MONITORINFOEXW info{};
    info.cbSize = sizeof(info);
    if (GetMonitorInfoW(handle, &info) == FALSE) return std::nullopt;
    const wchar_t* device = std::data(info.szDevice);
    Monitor monitor;
    monitor.device = core::narrow(device);
    monitor.rect = to_rect(info.rcMonitor);
    monitor.work_rect = to_rect(info.rcWork);
    monitor.is_primary = (info.dwFlags & MONITORINFOF_PRIMARY) != 0;
    fill_adapter(monitor, device);
    monitor.display = display_name(device);
    monitor.physical_mm = physical_size(device);
    monitor.dpi = effective_dpi(handle);
    monitor.modes = display_modes(device);
    monitor.current_mode = ensure_mode(monitor.modes, current_resolution(device, monitor.rect));
    return monitor;
}

// Callback của EnumDisplayMonitors: gom handle vào vector mà param trỏ tới. Ngoại lệ không được
// thoát qua biên C của Win32, nên hết bộ nhớ thì dừng liệt kê.
BOOL CALLBACK collect_handle(HMONITOR handle, HDC /*context*/, LPRECT /*area*/, LPARAM param) {
    // LPARAM là cách duy nhất Win32 chuyển con trỏ người dùng vào callback.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast, performance-no-int-to-ptr)
    auto* handles = reinterpret_cast<std::vector<HMONITOR>*>(param);
    try {
        handles->push_back(handle);
    } catch (...) {
        return FALSE;
    }
    return TRUE;
}

// Khác gốc: thân vòng lặp của largest tách ra đây.
template <class Accept>
void grow(std::optional<Size>& best, Size mode, const Accept& accept) {
    const Size floor = best.value_or(Size{});
    const bool is_growing = mode.width >= floor.width && mode.height >= floor.height;
    if (is_growing && accept(mode)) best = mode;
}

// Chế độ thoả accept mà rộng và cao đều không nhỏ hơn lựa chọn trước nó trong danh sách — vòng quét
// của getRecommendedResolution: danh sách đã sắp nên kết quả là chế độ lớn nhất thoả điều kiện.
template <class Accept>
[[nodiscard]] std::optional<Size> largest(std::span<const Size> modes, Accept accept) {
    std::optional<Size> best;
    for (const Size mode : modes) {
        grow(best, mode, accept);
    }
    return best;
}

struct Bounds {
    Size low{};
    Size high{};
};

[[nodiscard]] bool is_within(Size mode, const Bounds& bounds) noexcept {
    const bool is_above = mode.width >= bounds.low.width && mode.height >= bounds.low.height;
    return is_above && mode.width <= bounds.high.width && mode.height <= bounds.high.height;
}

using Modes = std::span<const Size>;

// Khác gốc: thân vòng lặp của largest_aligned tách ra đây.
[[nodiscard]] std::optional<Size> largest_multiple(Modes modes, const Bounds& bounds, std::uint32_t factor) {
    const auto accept = [factor, &bounds](Size mode) {
        const bool is_aligned = mode.width % factor == 0 && mode.height % factor == 0;
        return is_aligned && is_within(mode, bounds);
    };
    return largest(modes, accept);
}

// Thử cạnh chia hết cho 8, rồi 4, 2, 1: tránh các độ phân giải lẻ khi còn lựa chọn.
[[nodiscard]] std::optional<Size> largest_aligned(Modes modes, const Bounds& bounds) {
    std::optional<Size> found;
    for (std::uint32_t factor = kSizeFactor; factor > 0 && !found; factor >>= 1U) {
        found = largest_multiple(modes, bounds, factor);
    }
    return found;
}

[[nodiscard]] Size scaled(Size size, double fraction) noexcept {
    const auto width = static_cast<std::uint32_t>(size.width * fraction);
    const auto height = static_cast<std::uint32_t>(size.height * fraction);
    return {.width = width, .height = height};
}

} // namespace

namespace {

// Khác gốc: thân vòng lặp của monitors tách ra đây.
void add_described(std::vector<Monitor>& result, HMONITOR handle) {
    std::optional<Monitor> monitor = describe(handle);
    if (monitor) result.push_back(std::move(*monitor));
}

} // namespace

std::vector<Monitor> monitors() {
    std::vector<HMONITOR> handles;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    EnumDisplayMonitors(nullptr, nullptr, collect_handle, reinterpret_cast<LPARAM>(&handles));
    std::vector<Monitor> result;
    for (auto* const handle : handles) {
        add_described(result, handle);
    }
    std::ranges::stable_partition(result, &Monitor::is_primary);
    return result;
}

Dpi physical_dpi(const Monitor& monitor) noexcept {
    if (monitor.physical_mm.empty()) return {.x = 0, .y = 0};
    const Size resolution = monitor.resolution();
    const Size millimeters = monitor.physical_mm;
    const double horizontal = (resolution.width * kMillimetersPerInch) / millimeters.width;
    const double vertical = (resolution.height * kMillimetersPerInch) / millimeters.height;
    const auto dots_x = static_cast<std::uint32_t>(horizontal);
    const auto dots_y = static_cast<std::uint32_t>(vertical);
    return {.x = dots_x, .y = dots_y};
}

Size recommended_size(const Monitor& monitor) noexcept {
    const std::span<const Size> modes(monitor.modes);
    if (modes.size() <= 1) return monitor.resolution();
    const Size screen = monitor.resolution();
    const Size desired = scaled(screen, kDisplayFraction);
    const Size smallest = scaled(desired, kMinDesiredFraction);
    // Nới dần: bỏ sàn 3/4, rồi chỉ cần nhỏ hơn màn hình, rồi chỉ cần thấp hơn màn hình.
    const Bounds near_desired{.low = smallest, .high = desired};
    const Bounds up_to_desired{.low = Size{}, .high = desired};
    if (const auto found = largest_aligned(modes, near_desired)) return *found;
    if (const auto found = largest_aligned(modes, up_to_desired)) return *found;
    const auto is_smaller = [screen](Size mode) { return mode.width < screen.width && mode.height < screen.height; };
    if (const auto found = largest(modes, is_smaller)) return *found;
    const auto is_shorter = [screen](Size mode) { return mode.width <= screen.width && mode.height < screen.height; };
    return largest(modes, is_shorter).value_or(screen);
}

bool supports(const Monitor& monitor, Size mode) noexcept {
    return std::ranges::binary_search(monitor.modes, mode, by_height_then_width);
}

core::Status set_display_mode(const Monitor& monitor, Size mode) {
    DEVMODEW request{};
    request.dmSize = sizeof(request);
    request.dmPelsWidth = mode.width;
    request.dmPelsHeight = mode.height;
    request.dmFields = DM_PELSWIDTH | DM_PELSHEIGHT;
    const std::wstring device = core::widen(monitor.device);
    const LONG status = ChangeDisplaySettingsExW(device.c_str(), &request, nullptr, CDS_FULLSCREEN, nullptr);
    if (status == DISP_CHANGE_SUCCESSFUL) return core::ok();
    const bool is_bad_mode = status == DISP_CHANGE_BADMODE;
    const core::ErrorCode code = is_bad_mode ? core::ErrorCode::kUnsupported : core::ErrorCode::kIo;
    return core::fail(code, "không đổi được độ phân giải", "{} {}x{}, mã {}", monitor.device, mode.width, mode.height,
        status);
}

core::Status restore_display_mode(const Monitor& monitor) {
    const std::wstring device = core::widen(monitor.device);
    const LONG status = ChangeDisplaySettingsExW(device.c_str(), nullptr, nullptr, 0, nullptr);
    if (status == DISP_CHANGE_SUCCESSFUL) return core::ok();
    return core::fail(core::ErrorCode::kIo, "không trả được độ phân giải cũ", "{}, mã {}", monitor.device, status);
}

} // namespace game::window
