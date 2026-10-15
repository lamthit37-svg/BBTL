/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/governor.hpp
 *  PHÂN HỆ   : Core / Governor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ chọn trần khung hình theo năng lực đo được của máy, cho vòng vẽ không
 *    có ngân sách cố định (điện thoại, máy tính bảng). Màn 120 Hz không có
 *    nghĩa máy vẽ nổi 120 khung: vẽ không kịp thì mỗi khung trễ kéo giật cả
 *    cảnh, nên trần bắt đầu ở mức vững (tối đa 60) rồi mới thăm dò lên các mức
 *    cao hơn khi khung đo được còn dư sức, và lùi xuống khi trễ. Quyết định:
 *    các mức là phần nguyên của tần số quét (refresh, refresh/2, /3, /4; không
 *    dưới 30) để mỗi khung rơi đúng nhịp quét, không xen kẽ nhịp dài nhịp ngắn
 *    như 90 fps trên màn 120 Hz. Phán xét theo cửa sổ khung, không theo giây,
 *    nên không phụ thuộc đồng hồ và kiểm được bằng số liệu giả. Thăm dò hỏng
 *    thì lần thử lại kế tiếp lùi gấp đôi (tối đa 16 cửa sổ).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>

namespace game::core {

// Một khung đã vẽ xong. interval_ms là thời gian từ khung trước (đã gồm phần ngủ bù); busy_ms là phần việc thật (dựng, ghi
// lệnh, nộp; không gồm chờ nhịp quét).
struct FrameSample {
    double interval_ms = 0.0;
    double busy_ms = 0.0;
};

struct GovernorConfig {
    // Tần số quét của màn, Hz. Không biết (không dương) thì coi là 60.
    double refresh_hz = 60.0;
    // Trần của hạng máy (loop_plan(...).render_hz): không bao giờ thăm dò quá mức này.
    std::uint32_t ceiling_hz = 120;
};

class RateGovernor {
public:
    // Số khung mỗi lần phán xét. 90 khung ở 60 Hz là 1,5 giây.
    static constexpr std::size_t kWindow = 90;

    explicit RateGovernor(GovernorConfig config) noexcept;

    // Trần hiện hành, Hz: khung ngắn hơn 1000 / target_hz() thì vòng vẽ ngủ bù cho tới đủ.
    [[nodiscard]] double target_hz() const noexcept { return tiers_.at(index_); }

    // Báo một khung đã vẽ xong. true khi trần vừa đổi.
    [[nodiscard]] bool note_frame(FrameSample frame) noexcept;

    // Đổi tần số quét (màn đổi chế độ): dựng lại các mức và bắt đầu lại ở mức vững.
    void set_refresh(double refresh_hz) noexcept;

private:
    void build(double refresh_hz) noexcept;
    void fill_tiers(double refresh_hz) noexcept;
    [[nodiscard]] bool judge() noexcept;
    void step_down() noexcept;
    [[nodiscard]] bool can_step_up(double late, double heavy) const noexcept;
    void restart_window() noexcept;

    GovernorConfig config_;
    // Các mức giảm dần; chỉ [0, count_) có nghĩa.
    std::array<double, 4> tiers_{};
    std::size_t count_ = 1;
    std::size_t index_ = 0;
    std::size_t frames_ = 0;
    std::size_t late_ = 0;
    // Khung mà việc thật đã quá 70% ngân sách của mức cao hơn kế tiếp: lên mức đó sẽ không kịp.
    std::size_t heavy_ = 0;
    // Vừa lên mức và cửa sổ này là cửa sổ thử.
    bool is_probing_ = false;
    // Số cửa sổ phải chờ trước khi thăm dò lại, và mức lùi hiện hành (cửa sổ).
    std::uint32_t hold_ = 0;
    std::uint32_t backoff_ = 4;
};

} // namespace game::core
