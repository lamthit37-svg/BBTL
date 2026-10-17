/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/governor.hpp
 *  PHÂN HỆ   : Core / Governor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Trần khung theo sức máy đo được (điện thoại, tablet): bắt đầu ở mức vững
 *    (tối đa 60), thăm dò lên khi dư sức, lùi khi trễ; phán xét theo cửa sổ
 *    khung nên kiểm được bằng số liệu giả.
 *  - Thăm dò hỏng thì chờ gấp đôi (tối đa 16 cửa sổ); hỏng xa tầm thì 160.
 *  - Sau khi bắt đầu hoặc đổi mức, bỏ kSettle khung đầu (máy chạy chậm).
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

// Màn 120 Hz không có nghĩa máy vẽ nổi 120 khung: khung trễ kéo giật cả cảnh, nên trần bắt đầu ở
// mức vững. Mức là refresh, refresh/2, /3, /4 (không dưới 30) để mỗi khung rơi đúng nhịp quét,
// không xen kẽ nhịp dài nhịp ngắn như 90 fps trên màn 120 Hz.
class RateGovernor {
public:
    // Số khung mỗi lần phán xét. 90 khung ở 60 Hz là 1,5 giây.
    static constexpr std::size_t kWindow = 90;

    // Số khung bỏ qua sau khi đổi mức. Đo 2026-10-17 trên TB-X306F: vừa lên 60, 50 khung đầu chạy
    // 21 đến 24 ms rồi máy giữ 59,3 khung/giây. Nghi xung nhịp lên dần (chưa đọc được tần số trên
    // máy này). Tính cả đợt ấy thì mọi lần lên 60 đều bị coi là hỏng.
    static constexpr std::size_t kSettle = 90;

    // Số khung bỏ qua lúc bắt đầu (và khi đổi tần số quét): ngay sau nạp cảnh đợt chậm dài hơn,
    // 180 khung (3,8 giây) chạy 21 đến 23 ms mới ổn.
    static constexpr std::size_t kStartSettle = 240;

    explicit RateGovernor(GovernorConfig config) noexcept;

    // Trần hiện hành, Hz: khung ngắn hơn 1000 / target_hz() thì vòng vẽ ngủ bù cho tới đủ.
    [[nodiscard]] double target_hz() const noexcept { return tiers_.at(index_); }

    // Số khung còn bị bỏ qua trước cửa sổ kế (kiểm bằng số liệu giả cần biết).
    [[nodiscard]] std::size_t settle_left() const noexcept { return settle_; }

    // Báo một khung đã vẽ xong. true khi trần vừa đổi.
    [[nodiscard]] bool note_frame(FrameSample frame) noexcept;

    // Đổi tần số quét (màn đổi chế độ): dựng lại các mức và bắt đầu lại ở mức vững.
    void set_refresh(double refresh_hz) noexcept;

private:
    void build(double refresh_hz) noexcept;
    void fill_tiers(double refresh_hz) noexcept;
    [[nodiscard]] bool judge() noexcept;
    void step_down(double late) noexcept;
    void remember_far() noexcept;
    void count_far_hold() noexcept;
    [[nodiscard]] bool can_step_up(double late, double heavy) const noexcept;
    void restart_window() noexcept;

    GovernorConfig config_;
    // Các mức giảm dần; chỉ [0, count_) có nghĩa.
    std::array<double, 4> tiers_{};
    std::size_t count_ = 1;
    std::size_t index_ = 0;
    // Số khung còn phải bỏ qua (kSettle sau khi bắt đầu hoặc đổi mức).
    std::size_t settle_ = 0;
    std::size_t frames_ = 0;
    std::size_t late_ = 0;
    // Khung mà việc thật đã quá 70% ngân sách của mức cao hơn kế tiếp: lên mức đó sẽ không kịp.
    std::size_t heavy_ = 0;
    // Vừa lên mức và cửa sổ này là cửa sổ thử.
    bool is_probing_ = false;
    // Số cửa sổ phải chờ trước khi thăm dò lại, và mức lùi hiện hành (cửa sổ).
    std::uint32_t hold_ = 0;
    std::uint32_t backoff_ = 4;
    // Mức cao nhất (chỉ số nhỏ nhất) còn được thăm dò. Thăm dò xa tầm đẩy nó xuống ngay dưới mức
    // hỏng: thử lại chỉ thêm một đợt khung so le (đo 2026-10-17 trên TB-X306F). far_hold_ cửa sổ
    // sau thì quên, vì cảnh có thể đã nhẹ đi.
    std::size_t lowest_ = 0;
    std::uint32_t far_hold_ = 0;
};

} // namespace game::core
