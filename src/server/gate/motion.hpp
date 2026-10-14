#pragma once
// Bước đi ở gate: server làm chủ vị trí. Mỗi Move của client đi qua guard::Pace với tick do đồng hồ
// máy chủ tính; client không bao giờ tự đặt mốc. Thiết kế ở docs/SERVER-DI-CHUYEN.md.
// Thuần (không I/O) để test được không cần mạng; table.cpp gửi Position / Goodbye theo kết quả.

#include "guard/pace.hpp"
#include "protocol/messages.hpp"

#include <cstdint>

namespace game::gate {

// Nhịp của Pace (30 tick/giây), tách khỏi nhịp vòng gate (kTickNs, 60/giây).
inline constexpr std::int64_t kMotionTickNs = 1'000'000'000 / 30;

// Tick Pace của máy chủ lúc now_ns (đồng hồ đơn điệu của gate). Quay vòng modulo 2^32 như Pace mong.
[[nodiscard]] std::uint32_t motion_tick(std::int64_t now_ns) noexcept;

enum class MotionAct : std::uint8_t {
    kAccept, // nhận bước, không gửi gì
    kCorrect, // không nhận: gửi Position kéo về mốc
    kKick, // vi phạm lặp lại: đóng phiên (DisconnectReason::kKicked)
    kOutOfOrder, // chưa vào game / chưa có mốc: Reject kOutOfOrder
};

struct MotionOutcome {
    MotionAct act = MotionAct::kOutOfOrder;
    protocol::Position position{}; // chỉ có nghĩa khi act là kCorrect
};

class Motion {
public:
    // Máy chủ đặt mốc: vào game, hồi sinh, dịch chuyển hợp lệ. Trả Position cần gửi cho client.
    // Tick client đếm lại từ 0 sau mỗi mốc.
    [[nodiscard]] protocol::Position place(guard::Anchor at, std::int64_t now_ns) noexcept;
    // Đo một Move. Không có mốc thì kOutOfOrder.
    [[nodiscard]] MotionOutcome judge(const protocol::Move& move, std::int64_t now_ns) noexcept;
    // Rời game / đóng kết nối: bỏ mốc, bước sau bị từ chối tới khi máy chủ đặt mốc lại.
    void clear() noexcept;
    [[nodiscard]] bool placed() const noexcept { return placed_; }
    [[nodiscard]] guard::Anchor anchor() const noexcept { return pace_.anchor(); }

private:
    guard::Pace pace_;
    bool placed_ = false;
    std::uint32_t client_tick_ = 0; // tick client của bước nhận gần nhất, gửi lại khi kéo về
};

} // namespace game::gate