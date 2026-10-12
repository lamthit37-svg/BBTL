// Con trỏ hệ thống lấy bằng LoadCursorW(nullptr, ...) và không bao giờ bị huỷ; con trỏ nạp từ tệp
// thuộc về tiến trình và huỷ bằng DestroyCursor.
// Nguồn: Forge2 src/window/cursor.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; macro của
// windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32 include trực tiếp.
#include "window/cursor.hpp"

#include "core/error.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <cstddef>
#include <cstdint>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include <errhandlingapi.h>
#include <windef.h>
#include <wingdi.h>
#include <winuser.h>

namespace game::window {

namespace {

// Tên tài nguyên con trỏ của hệ thống. Không default: thêm hình mà quên ở đây là C4062.
[[nodiscard]] const wchar_t* resource_of(SystemCursor shape) noexcept {
    switch (shape) {
    case SystemCursor::kArrow: return IDC_ARROW;
    case SystemCursor::kText: return IDC_IBEAM;
    case SystemCursor::kWait: return IDC_WAIT;
    case SystemCursor::kCross: return IDC_CROSS;
    case SystemCursor::kHand: return IDC_HAND;
    case SystemCursor::kMove: return IDC_SIZEALL;
    case SystemCursor::kResizeVertical: return IDC_SIZENS;
    case SystemCursor::kResizeHorizontal: return IDC_SIZEWE;
    case SystemCursor::kResizeDiagonalDown: return IDC_SIZENWSE;
    case SystemCursor::kResizeDiagonalUp: return IDC_SIZENESW;
    case SystemCursor::kForbidden: return IDC_NO;
    }
    return IDC_ARROW;
}

void destroy_cursor(void* handle) noexcept {
    DestroyCursor(static_cast<HCURSOR>(handle));
}

// Windows dùng BGRA đã nhân alpha. SDL_CreateColorCursor của Dev làm bước này trong thư viện.
void store_bgra(std::span<std::uint8_t> pixels, std::span<const std::uint8_t> rgba, std::size_t index) {
    const std::size_t source = index * 4U;
    const auto red = static_cast<unsigned>(rgba[source]);
    const auto green = static_cast<unsigned>(rgba[source + 1]);
    const auto blue = static_cast<unsigned>(rgba[source + 2]);
    const auto alpha = static_cast<unsigned>(rgba[source + 3]);
    pixels[source] = static_cast<std::uint8_t>((blue * alpha) / 255U);
    pixels[source + 1] = static_cast<std::uint8_t>((green * alpha) / 255U);
    pixels[source + 2] = static_cast<std::uint8_t>((red * alpha) / 255U);
    pixels[source + 3] = static_cast<std::uint8_t>(alpha);
}

void copy_bgra(void* bits, const Cursor::RgbaCursor& picture) {
    const std::size_t count = static_cast<std::size_t>(picture.width) * picture.height;
    const std::span<std::uint8_t> pixels(static_cast<std::uint8_t*>(bits), count * 4U);
    for (std::size_t index = 0; index < count; ++index)
        store_bgra(pixels, picture.rgba, index);
}

constexpr std::uint32_t kMaxCursorEdge = 256;

[[nodiscard]] bool fits_cursor(const Cursor::RgbaCursor& picture) noexcept {
    const bool edge = picture.width > 0 && picture.height > 0;
    const bool small = picture.width <= kMaxCursorEdge && picture.height <= kMaxCursorEdge;
    if (!edge || !small) return false;
    const std::size_t need = static_cast<std::size_t>(picture.width) * picture.height * 4U;
    const bool bytes = picture.rgba.size() == need;
    const bool hot = picture.hot_x < picture.width && picture.hot_y < picture.height;
    return bytes && hot;
}

struct DrawnBitmap {
    HBITMAP handle = nullptr;
    void* bits = nullptr;
};

[[nodiscard]] DrawnBitmap color_bitmap(const Cursor::RgbaCursor& picture) {
    BITMAPINFO info{};
    info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    info.bmiHeader.biWidth = static_cast<decltype(info.bmiHeader.biWidth)>(picture.width);
    const auto edge = static_cast<decltype(info.bmiHeader.biHeight)>(picture.height);
    info.bmiHeader.biHeight = -edge;
    info.bmiHeader.biPlanes = 1;
    info.bmiHeader.biBitCount = 32;
    info.bmiHeader.biCompression = BI_RGB;
    DrawnBitmap drawn;
    drawn.handle = CreateDIBSection(nullptr, &info, DIB_RGB_COLORS, &drawn.bits, nullptr, 0);
    return drawn;
}

void discard_bitmap(HBITMAP handle) noexcept {
    if (handle != nullptr) DeleteObject(handle);
}

// Mặt nạ AND toàn 0: Windows Vista trở đi lấy độ trong suốt từ alpha của ảnh màu.
[[nodiscard]] HBITMAP blank_mask(const Cursor::RgbaCursor& picture) {
    const auto wide = static_cast<std::size_t>(picture.width);
    const auto high = static_cast<std::size_t>(picture.height);
    const std::size_t stride = ((wide + 15U) / 16U) * 2U;
    const std::vector<std::uint8_t> bits(stride * high, 0);
    const int columns = static_cast<int>(wide);
    const int rows = static_cast<int>(high);
    return CreateBitmap(columns, rows, 1, 1, bits.data());
}

struct IconRequest {
    HBITMAP color = nullptr;
    HBITMAP mask = nullptr;
    std::uint16_t hot_x = 0;
    std::uint16_t hot_y = 0;
};

struct IconBits {
    HCURSOR handle = nullptr;
    std::uint32_t error = 0;
};

[[nodiscard]] IconBits make_icon(IconRequest request) {
    ICONINFO icon{};
    icon.fIcon = FALSE;
    icon.xHotspot = request.hot_x;
    icon.yHotspot = request.hot_y;
    icon.hbmMask = request.mask;
    icon.hbmColor = request.color;
    IconBits made;
    made.handle = CreateIconIndirect(&icon);
    if (made.handle == nullptr) made.error = GetLastError();
    discard_bitmap(request.mask);
    discard_bitmap(request.color);
    return made;
}

} // namespace

Cursor Cursor::system(SystemCursor shape) noexcept {
    return {LoadCursorW(nullptr, resource_of(shape)), nullptr};
}

core::Result<Cursor> Cursor::from_file(std::string_view path) {
    const std::wstring wide = core::widen(path);
    const HCURSOR handle = LoadCursorFromFileW(wide.c_str());
    if (handle == nullptr) return core::fail_system(GetLastError(), "không nạp được con trỏ", path);
    return Cursor(handle, std::shared_ptr<void>(handle, destroy_cursor));
}

core::Result<Cursor> Cursor::from_rgba(RgbaCursor picture) {
    if (!fits_cursor(picture)) return core::fail(core::ErrorCode::kInvalidArgument, "ảnh con trỏ không hợp lệ");
    const DrawnBitmap drawn = color_bitmap(picture);
    if (drawn.handle == nullptr || drawn.bits == nullptr) {
        discard_bitmap(drawn.handle);
        return core::fail_system(GetLastError(), "không tạo được ảnh con trỏ");
    }
    copy_bgra(drawn.bits, picture);
    HBITMAP mask = blank_mask(picture);
    if (mask == nullptr) {
        discard_bitmap(drawn.handle);
        return core::fail_system(GetLastError(), "không tạo được mặt nạ con trỏ");
    }
    const IconRequest request{.color = drawn.handle, .mask = mask, .hot_x = picture.hot_x, .hot_y = picture.hot_y};
    const IconBits icon = make_icon(request);
    if (icon.handle == nullptr) return core::fail_system(icon.error, "không tạo được con trỏ màu");
    return Cursor(icon.handle, std::shared_ptr<void>(icon.handle, destroy_cursor));
}

} // namespace game::window
