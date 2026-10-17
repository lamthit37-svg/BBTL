/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/cadence.hpp
 *  PHÂN HỆ   : Core / Cadence
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nhịp màn thật của swapchain Fifo, suy từ lúc acquire trả ảnh: số nhịp quét
 *    màn giữ mỗi khung. Hàng chờ trình nuốt dao động của vòng lặp, nên khoảng
 *    vòng lặp không nói được màn có lặp ảnh hay không.
 *  - Chu kỳ quét tự đo từ các lần acquire phải chờ (ảnh nhả đúng lúc màn thay
 *    ảnh); số hệ điều hành báo chỉ là điểm xuất phát. Đo 2026-10-17 trên
 *    TB-X306F: Android báo 60,000 Hz, màn thật 59,87 Hz (16,703 ms).
 *  - PacedClock: mốc hoạt hoạ tiến theo lưới ấy thay vì theo lúc vòng lặp thức.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstdint>
#include <optional>

namespace game::core {

// Một khung vừa xin được ảnh. at_ms là mốc đồng hồ đơn điệu (ms, gốc tuỳ ý nhưng cố định).
// waited: acquire đã phải chờ ảnh được nhả, nên at_ms trùng lúc màn thay ảnh.
struct AcquireNote {
    double at_ms = 0.0;
    bool waited = false;
};

// Khung trước nằm trên màn bao nhiêu nhịp quét, và bằng bao nhiêu ms.
struct ShownSpan {
    std::uint32_t refreshes = 1;
    double interval_ms = 0.0;
};

// Mô hình lưới nhịp quét: khung đúng hẹn rơi vào nhịp kế của khung trước; tới muộn quá một phần
// tư nhịp là màn đã lặp ảnh. Đối chiếu 2026-10-17 với SurfaceFlinger trên TB-X306F (1846 khung):
// khung lặp và p95 khớp từng cửa sổ 10 giây, trong khi khoảng vòng lặp báo 16% khung trễ giả.
class FifoCadence {
public:
    // refresh_hz không dương hay không hữu hạn thì coi là 60.
    explicit FifoCadence(double refresh_hz) noexcept;

    // Báo một khung theo đúng thứ tự acquire. Khung đầu sau khi dựng hoặc reset trả một nhịp.
    [[nodiscard]] ShownSpan note(AcquireNote frame) noexcept;

    // Bỏ lưới (khung tiếp theo là khung đầu) nhưng giữ chu kỳ đã đo: nạp cảnh, ẩn cửa sổ, đổi cỡ.
    void reset() noexcept;

    // Chu kỳ quét đang dùng, ms.
    [[nodiscard]] double period_ms() const noexcept { return period_ms_; }

    // Chu kỳ theo số hệ điều hành báo lúc dựng, ms: đổi số báo thì dựng lại mô hình.
    [[nodiscard]] double nominal_ms() const noexcept { return nominal_ms_; }

private:
    void learn_period(double at_ms) noexcept;

    double nominal_ms_ = 0.0;
    double period_ms_ = 0.0;
    // Mốc nhịp quét mà khung trước được gán vào; rỗng là chưa có khung nào.
    std::optional<double> grid_ms_;
    // Lần acquire phải chờ gần nhất, và tổng các quãng giữa hai lần chờ liền nhau (ms, số nhịp).
    std::optional<double> last_wait_ms_;
    double span_ms_ = 0.0;
    double span_refreshes_ = 0.0;
};

// Mốc hoạt hoạ theo lưới nhịp trình. Fifo mà bề mặt không báo lúc trình (TB-X306F): luồng vẽ thức
// lệch ±6 ms quanh nhịp quét trong khi màn đổi ảnh đều, nên hoạt hoạ theo lúc thức làm cảnh nhích
// lúc ngắn lúc dài. Mỗi khung tiến đúng khoảng màn giữ khung trước (ShownSpan::interval_ms); lệch
// lúc thức quá most_lead_ms thì neo lại vào lúc thức. Không bao giờ lùi: mô phỏng nhịp cố định và
// hoạt ảnh coi mốc lùi là đứng hình rồi nhảy.
class PacedClock {
public:
    // most_lead_ms không dương hay không hữu hạn thì luôn neo vào lúc thức.
    explicit PacedClock(double most_lead_ms) noexcept;

    // Mốc của khung này (ms, cùng gốc với woke_ms). shown_ms là khoảng màn giữ khung trước theo
    // lưới; rỗng (không có lưới, khung đầu) thì neo vào lúc thức.
    [[nodiscard]] double next(double woke_ms, std::optional<double> shown_ms) noexcept;

    // Bỏ mốc cũ: khung kế neo vào lúc thức (vẫn không lùi sau mốc đã trả).
    void reset() noexcept;

    // Số khung đã tiến theo lưới và số lần neo vào lúc thức, cho dòng tổng kết. Neo nhiều trong lúc
    // chạy đều là lưới đếm sai.
    [[nodiscard]] std::uint64_t steps() const noexcept { return steps_; }
    [[nodiscard]] std::uint64_t anchors() const noexcept { return anchors_; }

private:
    double anchor(double woke_ms) noexcept;

    std::uint64_t steps_ = 0;
    std::uint64_t anchors_ = 0;
    double most_lead_ms_ = 0.0;
    // Mốc đã trả cho khung trước (luôn là mốc lớn nhất từng trả); rỗng là chưa có khung nào.
    std::optional<double> latest_ms_;
    // false sau reset: khung kế neo vào lúc thức thay vì tiến theo lưới.
    bool is_stepping_ = false;
};

} // namespace game::core
