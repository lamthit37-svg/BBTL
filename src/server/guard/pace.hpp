/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/guard/pace.hpp
 *  PHÂN HỆ   : Server / Guard / Pace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Máy chủ làm chủ vị trí trên mặt phẳng ngang (H1-B). Client khai chỗ đứng
 *    (Move), máy chủ xếp các chỗ đó thành đường đi rồi tự đi theo với tốc độ
 *    của nó; vị trí máy chủ không bao giờ lấy từ con số client khai mà vượt
 *    tốc. Mốc đầu do máy chủ đặt (reset: sinh ra, hồi sinh, kéo về), không bao
 *    giờ lấy từ bước đầu của client. Không xét độ cao: map có đồi, Y khác 0
 *    không phải bay.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn: Obj_Logic_Move (Obj_Character_Logic.cpp:449-544) của máy chủ 2008: mỗi nhịp tiến tốc độ ×
// thời gian dọc đường client gửi, không đóng phiên vì tốc độ (docs/giao-viec/HOAN-THIEN/H1-M.md).
// Khác gốc: (1) tốc độ là hằng kRunCmPerSec (phép đo 4,65 m/s của bộ chống gian lận tham chiếu, đổi
// sang centimet), gốc lấy theo thuộc tính người chơi; (2) quỹ kBankCm cộng dồn khi đứng yên để nhịp
// 30 Hz của Pace và nhịp 60 Hz của vòng gate không làm vị trí giật, trần bằng
// DEF_SERVER_ADJUST_POS_WARP_DIST (Common/GameDefine.h:538) nên đứng yên bao lâu rồi lao cũng chỉ
// nhảy tối đa chừng đó; (3) hàng đợi các chỗ client đã khai thay cho FindPath: gate không có lưới
// đi, mà mỗi đoạn client đã đi qua đều nằm trên lưới đi của client, nên đi dọc chúng không cắt góc
// xuyên tường như đuổi thẳng tới chỗ client.
//
// Thời gian chỉ lấy từ đồng hồ máy chủ (tick máy chủ); tick client chỉ để phát hiện tick lùi và
// không mua thêm quãng đường (G2). Tick client lùi hoặc số không hữu hạn: kRejected, bỏ cả đường
// đang chờ (G6). Không có phạt, không có đóng phiên: máy chủ bóp tốc độ ở kRunCmPerSec × kSlack, kẻ
// gian chỉ làm lệch màn hình của chính mình. Lệch tích luỹ quá xa (hàng đợi dài hơn quãng người
// thật đi được trong một hạn idle, hoặc đầy kNodes bước) thì kResync: kéo client về mốc.

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::guard {

// Tốc độ chạy tối đa của người thật, cm/giây. Nguồn 465 chưa rõ (docs/NGHI-NGO.md 81).
inline constexpr float kRunCmPerSec = 465.0F;
inline constexpr float kSlack = 1.05F;
inline constexpr float kTickSeconds = 1.0F / 30.0F;
// Quỹ quãng đường tối đa, cm. Nạp ở kRunCmPerSec × kSlack mỗi giây (tức 488 cm/s).
inline constexpr float kBankCm = 500.0F;
// Cách nhau tối thiểu giữa hai điểm báo cho zone; zone kiểm tường mỗi 20 cm dọc đoạn báo.
inline constexpr float kTrailCm = 20.0F;
// Số bước client tối đa chờ trong hàng đợi (người thật gửi 20 bước mỗi giây: đủ chừng 25 giây).
inline constexpr std::size_t kNodes = 512;
// Một lần đi tối đa kBankCm nên tối đa kBankCm / kTrailCm điểm, cộng điểm cuối và một chỗ dự phòng.
inline constexpr std::size_t kTrailMax = static_cast<std::size_t>(kBankCm / kTrailCm) + 2;

enum class [[nodiscard]] Verdict : std::uint8_t {
    kOk, // nhận bước: xếp vào đường đi, máy chủ đi theo ở advance()
    kRejected, // không nhận (số không hợp lệ, tick lùi): kéo client về anchor(), bỏ đường chờ
    kResync, // client lệch quá xa so với máy chủ: kéo client về anchor(), bỏ đường chờ, không phạt
    kNoAnchor, // máy chủ chưa đặt mốc: không nhận bước nào
};

struct Step {
    float x_cm = 0;
    float z_cm = 0;
    std::uint32_t tick = 0; // tick client khai, chỉ để phát hiện tick lùi
};

struct Anchor {
    float x_cm = 0;
    float z_cm = 0;
};

// Những chỗ máy chủ vừa đi qua trong một lần advance(), theo thứ tự; điểm cuối là mốc mới.
struct Trail {
    std::array<Anchor, kTrailMax> points{};
    std::size_t count = 0;
    [[nodiscard]] std::span<const Anchor> view() const noexcept { return {points.data(), count}; }
};

class Pace {
public:
    // Máy chủ đặt mốc: lúc vào bản đồ, hồi sinh, kéo về. Bỏ đường chờ và quỹ. resync_cm là quãng
    // chờ tối đa trước khi kResync (không nhỏ hơn hai lần kBankCm).
    void reset(Anchor at, std::uint32_t client_tick, std::uint32_t server_tick,
        float resync_cm) noexcept;
    // Xếp bước client khai vào cuối đường chờ. Không dời mốc: dời là việc của advance().
    [[nodiscard]] Verdict observe(Step step) noexcept;
    // Đi dọc đường chờ tới server_tick (đồng hồ máy chủ, client không chạm được), tối đa quỹ cho
    // phép.
    [[nodiscard]] Trail advance(std::uint32_t server_tick) noexcept;
    [[nodiscard]] bool pending() const noexcept { return count_ > 0; }
    [[nodiscard]] Anchor anchor() const noexcept { return {.x_cm = x_cm_, .z_cm = z_cm_}; }
    // Quãng đường còn lại từ mốc tới chỗ client khai gần nhất.
    [[nodiscard]] float lag_cm() const noexcept { return queued_cm_; }

private:
    struct Leg {
        float moved_cm = 0;
        bool reached = false;
    };

    void refill(std::uint32_t server_tick) noexcept;
    void walk(Trail& trail) noexcept;
    [[nodiscard]] Leg go_to(Anchor next) noexcept;
    [[nodiscard]] Verdict refuse(Verdict verdict) noexcept;
    [[nodiscard]] Anchor tail() const noexcept;
    void push(Anchor at) noexcept;
    void pop() noexcept;

    bool has_anchor_ = false;
    float x_cm_ = 0;
    float z_cm_ = 0;
    std::uint32_t client_tick_ = 0;
    std::uint32_t server_tick_ = 0;
    float bank_cm_ = 0;
    float resync_cm_ = 0;
    // Hàng đợi vòng các chỗ client đã khai, chưa tới; queued_cm_ là tổng độ dài từ mốc qua chúng.
    std::array<Anchor, kNodes> nodes_{};
    std::size_t head_ = 0;
    std::size_t count_ = 0;
    float queued_cm_ = 0;
};

} // namespace game::guard
