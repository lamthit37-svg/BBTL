// Đo nhịp mà màn hình thật hiện ra: mỗi lần desktop của màn chính nhận ảnh mới (DXGI Desktop Duplication),
// ghi mốc QPC LastPresentTime, rồi in khoảng cách giữa hai lần theo đơn vị nhịp quét. Đây là cái người chơi thấy,
// sau cả swapchain lẫn DWM; nhịp phía CPU của bảng đo trong client không thấy khung bị DWM giữ hay lặp (đo
// 2026-10-13: CPU đều mà màn hiện p95 trên 33 ms).
// Muốn mỗi lần quét đều có hình mới thì cảnh phải đổi mỗi khung: chạy client với --walk. Khoảng 2 nhịp trở lên là
// một khung bị hiện hai lần, tức chuyển động giật.
// Không lưu ảnh, không tạo cửa sổ, không đụng chuột hay bàn phím.
// Chạy (chỉ Windows): thienlong_screen_pace [--delay <giây>] [--seconds <giây>]
#include "core/number.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "io/platform.hpp"

// Header con của DXGI và D3D11 cần kiểu của windows.h nên đứng sau.
#include <d3d11.h>
#include <d3dcommon.h>
#include <dxgi.h>
#include <dxgi1_2.h>
#include <profileapi.h>
#include <windef.h>
#include <winerror.h>
#include <wingdi.h>
#include <winnt.h>
#include <winuser.h>
#include <wrl/client.h>

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <iterator>
#include <optional>
#include <print>
#include <span>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace {

using Microsoft::WRL::ComPtr;

// Trần của hai tham số thời gian: một lượt đo dài hơn không cho thêm gì mà giữ desktop duplication lâu.
constexpr std::uint32_t kMaxSeconds = 120;
// Trần số mẫu: 1000 lần cập nhật mỗi giây là quá mọi màn hiện có.
constexpr std::size_t kMaxSamplesPerSecond = 1000;
// Mỗi lần chờ ảnh mới tối đa chừng này mili giây, để vòng đo còn xét hạn khi màn đứng yên.
constexpr unsigned kAcquireTimeoutMs = 100;

struct Options {
    std::uint32_t delay_seconds = 3;
    std::uint32_t seconds = 6;
};

[[nodiscard]] std::optional<std::uint32_t> seconds_of(std::string_view text) noexcept {
    const game::core::OptionalUnsigned parsed = game::core::parse_unsigned(text, 10);
    if (!parsed || parsed->length != text.size() || parsed->value > kMaxSeconds) return std::nullopt;
    return static_cast<std::uint32_t>(parsed->value);
}

[[nodiscard]] std::optional<Options> parse(std::span<const char* const> arguments) {
    Options options;
    for (std::size_t index = 1; index < arguments.size(); index += 2) {
        if (index + 1 >= arguments.size()) return std::nullopt;
        const std::string_view key{arguments[index]};
        const std::optional<std::uint32_t> value = seconds_of(arguments[index + 1]);
        if (!value) return std::nullopt;
        if (key == "--delay") {
            options.delay_seconds = *value;
        } else if (key == "--seconds" && *value > 0) {
            options.seconds = *value;
        } else {
            return std::nullopt;
        }
    }
    return options;
}

// Màn chính và adapter đang lái nó.
struct Screen {
    ComPtr<IDXGIAdapter1> adapter;
    ComPtr<IDXGIOutput1> output;
    DXGI_OUTPUT_DESC desc{};
};

[[nodiscard]] std::optional<Screen> primary_screen() {
    // IID lấy từ hằng của SDK (dxguid), không qua __uuidof: phần mở rộng của MSVC, Clang -Werror từ chối.
    void* made = nullptr;
    if (FAILED(CreateDXGIFactory1(IID_IDXGIFactory1, &made))) return std::nullopt;
    ComPtr<IDXGIFactory1> factory;
    factory.Attach(static_cast<IDXGIFactory1*>(made));
    const HMONITOR__* const primary = MonitorFromPoint(POINT{.x = 0, .y = 0}, MONITOR_DEFAULTTOPRIMARY);
    ComPtr<IDXGIAdapter1> adapter;
    for (UINT adapter_index = 0; factory->EnumAdapters1(adapter_index, &adapter) != DXGI_ERROR_NOT_FOUND;
        ++adapter_index) {
        ComPtr<IDXGIOutput> output;
        for (UINT output_index = 0; adapter->EnumOutputs(output_index, &output) != DXGI_ERROR_NOT_FOUND;
            ++output_index) {
            Screen screen;
            if (FAILED(output->GetDesc(&screen.desc)) || screen.desc.Monitor != primary) continue;
            if (FAILED(output.As(&screen.output))) return std::nullopt;
            screen.adapter = std::move(adapter);
            return screen;
        }
    }
    return std::nullopt;
}

// Hz đang đặt của màn, đọc ngay trước khi đo: client đổi Hz lúc mở cửa sổ và trả lại khi thoát. 0 khi không đọc được.
[[nodiscard]] std::uint32_t refresh_hz(const DXGI_OUTPUT_DESC& desc) noexcept {
    DEVMODEW mode{};
    mode.dmSize = sizeof(mode);
    if (EnumDisplaySettingsW(std::data(desc.DeviceName), ENUM_CURRENT_SETTINGS, &mode) == FALSE) return 0;
    return mode.dmDisplayFrequency >= 2 ? mode.dmDisplayFrequency : 0;
}

// Một lần đọc được ảnh mới. merged là số lần cập nhật DWM gộp vào lần đọc này (AccumulatedFrames - 1): vòng đo chậm
// một nhịp thì hai ảnh dồn vào một lần đọc, khoảng trước nó dài hai nhịp mà màn không hề lặp khung.
struct Sample {
    std::int64_t stamp = 0;
    std::uint32_t merged = 0;
};

struct Capture {
    std::vector<Sample> samples;
    std::uint32_t lost = 0;
    HRESULT failure = S_OK;
};

// Ghi mốc mỗi lần ảnh desktop đổi cho tới hạn. Mất quyền duplication (đổi chế độ màn, màn khoá) thì dựng lại.
[[nodiscard]] bool capture(const Screen& screen, ID3D11Device* device, std::chrono::seconds span, Capture& out) {
    ComPtr<IDXGIOutputDuplication> duplication;
    out.failure = screen.output->DuplicateOutput(device, &duplication);
    if (FAILED(out.failure)) return false;
    const std::size_t room = static_cast<std::size_t>(span.count()) * kMaxSamplesPerSecond;
    out.samples.reserve(room);
    const auto deadline = std::chrono::steady_clock::now() + span;
    while (std::chrono::steady_clock::now() < deadline && out.samples.size() < room) {
        if (duplication == nullptr) {
            static_cast<void>(screen.output->DuplicateOutput(device, &duplication));
            if (duplication == nullptr) std::this_thread::sleep_for(std::chrono::milliseconds{200});
            continue;
        }
        DXGI_OUTDUPL_FRAME_INFO info{};
        ComPtr<IDXGIResource> image;
        const HRESULT got = duplication->AcquireNextFrame(kAcquireTimeoutMs, &info, &image);
        if (got == DXGI_ERROR_WAIT_TIMEOUT) continue;
        if (got == DXGI_ERROR_ACCESS_LOST) {
            duplication.Reset();
            ++out.lost;
            if (out.lost > 8) {
                out.failure = got;
                return false;
            }
            // Màn vừa đổi chế độ thì DuplicateOutput có thể chưa nhận ngay; thử lại ở vòng sau.
            static_cast<void>(screen.output->DuplicateOutput(device, &duplication));
            if (duplication == nullptr) std::this_thread::sleep_for(std::chrono::milliseconds{200});
            continue;
        }
        if (FAILED(got)) {
            out.failure = got;
            return false;
        }
        // LastPresentTime 0 là chỉ con trỏ đổi, không có ảnh mới.
        if (info.LastPresentTime.QuadPart != 0) {
            const std::uint32_t merged = info.AccumulatedFrames > 1 ? info.AccumulatedFrames - 1 : 0;
            out.samples.push_back(Sample{.stamp = info.LastPresentTime.QuadPart, .merged = merged});
        }
        out.failure = duplication->ReleaseFrame();
        if (FAILED(out.failure)) return false;
    }
    return true;
}

[[nodiscard]] double at_rank(std::span<const double> sorted, double rank) noexcept {
    const auto index = static_cast<std::size_t>(rank * static_cast<double>(sorted.size() - 1));
    return sorted[index];
}

void report(const Capture& captured, std::uint32_t hz) {
    LARGE_INTEGER frequency{};
    QueryPerformanceFrequency(&frequency);
    const double tick_ms = 1000.0 / static_cast<double>(frequency.QuadPart);
    // Khoảng có ảnh bị gộp không xếp loại: nó dài vì vòng đo, không vì màn.
    std::vector<double> gaps;
    gaps.reserve(captured.samples.size());
    std::size_t merged_gaps = 0;
    for (std::size_t index = 1; index < captured.samples.size(); ++index) {
        const Sample& now = captured.samples[index];
        const std::int64_t step = now.stamp - captured.samples[index - 1].stamp;
        if (step <= 0) continue;
        if (now.merged > 0) {
            ++merged_gaps;
            continue;
        }
        gaps.push_back(static_cast<double>(step) * tick_ms);
    }
    std::println("Màn chính: {} Hz; {} lần ảnh mới, {} khoảng có ảnh gộp (bỏ khỏi thống kê), {} lần dựng lại duplication", hz,
        captured.samples.size(), merged_gaps, captured.lost);
    if (gaps.size() < 2 || hz == 0) {
        std::println("Không đủ mẫu để tính nhịp (cảnh có đang chuyển động không?)");
        return;
    }
    const double period = 1000.0 / static_cast<double>(hz);
    std::size_t one = 0;
    std::size_t two = 0;
    std::size_t more = 0;
    for (const double gap : gaps) {
        if (gap <= period * 1.5) {
            ++one;
        } else if (gap <= period * 2.5) {
            ++two;
        } else {
            ++more;
        }
    }
    std::ranges::sort(gaps);
    const auto share = [&](std::size_t count) { return 100.0 * static_cast<double>(count) / static_cast<double>(gaps.size()); };
    std::println("Khoảng giữa hai ảnh: trung vị {:.2f} ms, p95 {:.2f} ms, p99 {:.2f} ms, lớn nhất {:.2f} ms; nhịp quét {:.2f} ms",
        at_rank(gaps, 0.5), at_rank(gaps, 0.95), at_rank(gaps, 0.99), gaps.back(), period);
    std::println("Theo nhịp quét: 1 nhịp {} ({:.1f}%), 2 nhịp {} ({:.1f}%), 3 nhịp trở lên {} ({:.1f}%)", one, share(one),
        two, share(two), more, share(more));
}

int run(int argc, char** argv) {
    game::io::use_utf8_console();
    const std::optional<Options> options = parse(std::span<const char* const>{argv, static_cast<std::size_t>(argc)});
    if (!options) {
        std::println(stderr, "dùng: thienlong_screen_pace [--delay <giây, 0..{}>] [--seconds <giây, 1..{}>]",
            kMaxSeconds, kMaxSeconds);
        return 2;
    }
    const std::optional<Screen> screen = primary_screen();
    if (!screen) {
        std::println(stderr, "không tìm thấy màn chính qua DXGI");
        return 1;
    }
    ComPtr<ID3D11Device> device;
    const HRESULT made = D3D11CreateDevice(screen->adapter.Get(), D3D_DRIVER_TYPE_UNKNOWN, nullptr, 0, nullptr, 0,
        D3D11_SDK_VERSION, &device, nullptr, nullptr);
    if (FAILED(made)) {
        std::println(stderr, "không tạo được thiết bị D3D11 cho màn chính");
        return 1;
    }
    std::this_thread::sleep_for(std::chrono::seconds{options->delay_seconds});
    const std::uint32_t hz = refresh_hz(screen->desc);
    Capture captured;
    if (!capture(*screen, device.Get(), std::chrono::seconds{options->seconds}, captured)) {
        std::println(stderr, "desktop duplication lỗi 0x{:08X} (màn đang khoá, hoặc một tiến trình khác đang giữ duplication)",
            static_cast<std::uint32_t>(captured.failure));
        return 1;
    }
    report(captured, hz);
    const auto span_ticks = captured.samples.size() > 1 ? captured.samples.back().stamp - captured.samples.front().stamp : 0;
    if (span_ticks > 0) {
        LARGE_INTEGER frequency{};
        QueryPerformanceFrequency(&frequency);
        std::uint64_t updates = captured.samples.size() - 1;
        for (const Sample& sample : captured.samples) updates += sample.merged;
        const double seconds = static_cast<double>(span_ticks) / static_cast<double>(frequency.QuadPart);
        std::println("Ảnh mới mỗi giây (kể cả ảnh gộp): {:.1f}", static_cast<double>(updates) / seconds);
    }
    return 0;
}

} // namespace

// std::println và vector có thể ném (hết bộ nhớ, stdout đóng): main không để ngoại lệ thoát ra.
int main(int argc, char** argv) {
    try {
        return run(argc, argv);
    } catch (...) {
        static_cast<void>(std::fputs("thienlong_screen_pace: lỗi không lường trước\n", stderr));
        return 1;
    }
}
