/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/gate/motion.hpp
 *  PHÂN HỆ   : Server / Gate / Motion
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bước đi ở gate: server làm chủ vị trí. Mỗi Move của client được xếp vào
 *    đường đi của guard::Pace, máy chủ đi theo bằng đồng hồ của gate; client
 *    không bao giờ tự đặt mốc và không bị đóng phiên vì tốc độ. Thiết kế ở
 *    docs/SERVER-DI-CHUYEN.md. Thuần (không I/O) để test được không cần mạng;
 *    table.cpp gửi Position và báo zone theo kết quả.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "guard/pace.hpp"
#include "protocol/messages.hpp"

#include <cstdint>

namespace game::gate {

// Nhịp của Pace (30 tick/giây), tách khỏi nhịp vòng gate (kTickNs, 60/giây).
inline constexpr std::int64_t kMotionTickNs = 1'000'000'000 / 30;

// Tick Pace của máy chủ lúc now_ns (đồng hồ đơn điệu của gate). Quay vòng modulo 2^32 như Pace
// mong.
[[nodiscard]] std::uint32_t motion_tick(std::int64_t now_ns) noexcept;

enum class MotionAct : std::uint8_t {
    kAccept, // nhận bước: gate gọi chase() để máy chủ đi theo
    kCorrect, // không nhận hoặc lệch quá xa: gửi Position kéo về mốc, đường chờ đã bỏ
    kOutOfOrder, // chưa vào game / chưa có mốc: Reject kOutOfOrder
};

struct MotionOutcome {
    MotionAct act = MotionAct::kOutOfOrder;
    protocol::Position position{}; // chỉ có nghĩa khi act là kCorrect
};

class Motion {
public:
    // Máy chủ đặt mốc: vào game, hồi sinh, kéo về. Trả Position cần gửi cho client. Tick client đếm
    // lại từ 0 sau mỗi mốc. resync_cm: quãng client được lệch tối đa (guard::Pace::reset).
    [[nodiscard]] protocol::Position place(guard::Anchor at, std::int64_t now_ns,
        float resync_cm) noexcept;
    // Xếp một Move vào đường đi. Không dời mốc: gọi chase() ngay sau kAccept. Không có mốc thì
    // kOutOfOrder.
    [[nodiscard]] MotionOutcome judge(const protocol::Move& move) noexcept;
    // Máy chủ đi theo đường đã nhận tới now_ns; trả những chỗ vừa đi qua để báo zone. Mọi lần dời
    // mốc phải qua đây rồi báo zone, để vị trí zone luôn bằng mốc của Pace.
    [[nodiscard]] guard::Trail chase(std::int64_t now_ns) noexcept;
    // Còn đường chờ: gate phải gọi chase() ở các nhịp sau dù client không gửi thêm Move.
    [[nodiscard]] bool pending() const noexcept { return placed_ && pace_.pending(); }
    // Rời game / đóng kết nối: bỏ mốc, bước sau bị từ chối tới khi máy chủ đặt mốc lại.
    void clear() noexcept;
    [[nodiscard]] bool placed() const noexcept { return placed_; }
    [[nodiscard]] guard::Anchor anchor() const noexcept { return pace_.anchor(); }

private:
    [[nodiscard]] MotionOutcome pull_back() const noexcept;

    guard::Pace pace_;
    bool placed_ = false;
    std::uint32_t client_tick_ = 0; // tick client của bước nhận gần nhất, gửi lại khi kéo về
};

} // namespace game::gate
