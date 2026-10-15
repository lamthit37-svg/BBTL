// Màn hình và chế độ hiển thị — MonitorDesc, collectMonitorInfo, getMonitor*,
// getRecommendedResolution, setResolution, getResolutionSupport của _Ref (WindowsWindow.cpp,
// WindowSystem.cpp). Khác gốc:
// - monitors() liệt kê lại ở mỗi lần gọi, mỗi vùng màn hình của desktop một mục. Gốc liệt kê một
//   lần lúc khởi động vào mảng toàn cục: cắm, rút hay đổi độ phân giải bằng tay là danh sách cũ;
// - tên là UTF-8 dài tuỳ ý; gốc giữ WCHAR[32] và WCHAR[128];
// - dpi là DPI hiệu dụng của Windows (tỉ lệ người dùng chọn). Gốc tính DPI từ cỡ vật lý và chia
//   cho 0 khi màn hình ảo báo cỡ 0; bản an toàn là physical_dpi;
// - chế độ hiện tại luôn có trong modes; gốc ASSERT rồi dùng chỉ số UINT32_MAX ở Release;
// - set_display_mode trả lỗi của hệ thống và có restore_display_mode; gốc bỏ kết quả và không có
//   lối về.
// Nguồn: Forge2 src/window/monitor.hpp@d7fcd76. Khác gốc (so với Forge2): không.
#pragma once

#include "core/error.hpp"
#include "window/types.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <vector>

namespace game::window {

struct Monitor {
    // Tên thiết bị của Windows, kiểu "\\.\DISPLAY1": khoá cho các API hiển thị và để khớp với đầu
    // ra của DXGI.
    std::string device;
    // Tên card đồ hoạ và tên màn hình để hiển thị cho người dùng.
    std::string adapter;
    std::string display;
    // Vùng của màn hình trong desktop ảo, và phần còn lại sau khi trừ thanh tác vụ.
    Rect rect{};
    Rect work_rect{};
    // Cỡ vật lý tính bằng milimét; 0 khi hệ thống không biết.
    Size physical_mm{};
    Dpi dpi{};
    // Các độ phân giải hỗ trợ, không trùng, sắp theo chiều cao rồi chiều rộng.
    std::vector<Size> modes;
    // Chỉ số trong modes của chế độ đang dùng lúc liệt kê.
    std::size_t current_mode = 0;
    bool is_primary = false;
    // Hệ thống đã lọc bớt chế độ mà màn hình không nhận.
    bool is_pruned = false;

    // Độ phân giải đang dùng; Monitor dựng tay chưa có modes thì lấy cỡ của rect.
    [[nodiscard]] Size resolution() const noexcept {
        return current_mode < modes.size() ? modes.at(current_mode) : rect.size();
    }
};

// Mọi màn hình đang thuộc desktop, màn hình chính đứng đầu. Phiên làm việc có desktop thì danh
// sách không rỗng.
[[nodiscard]] std::vector<Monitor> monitors();

// DPI tính từ độ phân giải và cỡ vật lý; {0, 0} khi không biết cỡ vật lý.
[[nodiscard]] Dpi physical_dpi(const Monitor& monitor) noexcept;

// Cỡ vùng client nên dùng cho cửa sổ thường trên màn hình này: chế độ lớn nhất không vượt 3/4 màn
// hình, ưu tiên cỡ chia hết cho 8. Nới dần điều kiện khi không có chế độ nào khớp.
[[nodiscard]] Size recommended_size(const Monitor& monitor) noexcept;

[[nodiscard]] bool supports(const Monitor& monitor, Size mode) noexcept;

// Đổi độ phân giải của màn hình cho tới khi tiến trình thoát hoặc gọi restore_display_mode (cờ
// CDS_FULLSCREEN: không ghi vào registry).
[[nodiscard]] core::Status set_display_mode(const Monitor& monitor, Size mode);
[[nodiscard]] core::Status restore_display_mode(const Monitor& monitor);

// Kết quả nâng tần số quét. changed khi desktop đang ở after_hz và khác trước đó. offered_hz là
// mức cao nhất cùng độ phân giải mà driver liệt kê, 0 khi không có mức nào cao hơn before_hz.
// device là tên Windows ("\\.\DISPLAY1") để restore_display_mode trả lại chế độ trong registry.
struct RefreshLift {
    std::string device;
    std::uint32_t before_hz = 0;
    std::uint32_t after_hz = 0;
    std::uint32_t offered_hz = 0;
    bool changed = false;
};

// Xếp các tần số còn cao hơn current, giảm dần, không trùng. 0 và 1 là "mặc định của driver"
// trong DEVMODE, không phải số Hertz. out đầy thì giữ các mức cao nhất. Trả số đã ghi.
// O(n · out.size()) với n = offered.size(); n của một độ phân giải là vài chục, trần liệt kê ở
// raise_refresh là 512.
[[nodiscard]] constexpr std::size_t rank_refresh(std::uint32_t current, std::span<const std::uint32_t> offered,
    std::span<std::uint32_t> out) noexcept {
    std::size_t filled = 0;
    for (const std::uint32_t hz : offered) {
        if (hz < 2 || hz <= current) continue;
        std::size_t slot = 0;
        bool is_seen = false;
        while (slot < filled) {
            if (out[slot] == hz) {
                is_seen = true;
                break;
            }
            if (out[slot] < hz) break;
            ++slot;
        }
        if (is_seen || slot == out.size()) continue;
        const std::size_t last = filled < out.size() ? filled : out.size() - 1;
        for (std::size_t index = last; index > slot; --index) {
            out[index] = out[index - 1];
        }
        out[slot] = hz;
        if (filled < out.size()) ++filled;
    }
    return filled;
}

// Hz của màn đang chứa cửa sổ; 0 khi không đọc được. Không đổi chế độ.
[[nodiscard]] std::uint32_t display_refresh_hz(void* window) noexcept;

// Nâng tần số quét của màn đang chứa cửa sổ lên mức cao nhất cùng độ phân giải và cùng bpp,
// bỏ chế độ xen kẽ. Thử CDS_TEST trước rồi mới CDS_FULLSCREEN, nên mức driver từ chối không
// làm nhấp màn. Không đổi độ phân giải, không hạ tần số, không ghi registry. Mức đã áp dụng
// được hệ điều hành trả lại khi tiến trình thoát; gọi restore_display_mode khi thoát chủ động
// để desktop về sớm hơn. Không có mức cao hơn thì changed = false và vẫn thành công.
[[nodiscard]] core::Result<RefreshLift> raise_refresh(void* window);

} // namespace game::window
