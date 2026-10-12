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

} // namespace game::window
