/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/fight/combat.hpp
 *  PHÂN HỆ   : Client / Fight / Combat
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phần chiến đấu của chính người chơi, thuần logic: mục tiêu đang chọn,
 *    kỹ năng đã học và hồi chiêu, đánh tự động (đuổi tới mục tiêu rồi ra chiêu
 *    lặp lại), theo dõi chiêu đang chờ máy chủ xác nhận, số sát thương bay và
 *    trạng thái chết.
 *  - Không GPU, không mạng, không đồng hồ riêng: thời gian do nơi gọi đưa vào.
 *    Dùng chung PC, Android và iOS.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Client không đoán kết quả: chiêu chỉ là ý định gửi lên (cast), động tác chỉ chạy khi máy chủ xác nhận bằng SkillCast mang
// đúng seq (confirm), số bay chỉ hiện từ CombatEvent. Hợp đồng cùng protocol phiên bản 6 (docs/PROTOCOL-TIN.md nhóm 08).
//
// Cách hỏng đã tính trước (CL-03):
//   máy chủ không xác nhận chiêu            -> chiêu chờ hết hạn sau kCastWait, chiêu kế được gửi; không kẹt vĩnh viễn.
//   máy chủ từ chối liên tục (hồi chiêu...)  -> gửi lại không nhanh hơn kRetry; đánh tự động dừng với lý do không cứu được
//                                              (mục tiêu hỏng, chưa học, thiếu nội lực).
//   máy chủ từ chối vì quá tầm              -> thu ngắn tầm tiếp cận của client lần sau, để hai bên không lệch nhau mãi.
//   mục tiêu biến mất / chết giữa lúc đuổi   -> bỏ mục tiêu và đánh tự động.
//   chính mình chết                         -> không ra chiêu, không đánh tự động, tới khi sinh lực trở lại dương.
//   máy chủ gửi quá nhiều số bay             -> trần kMaxFloats, bỏ số cũ nhất.
//   dây kỹ năng có id lặp / quá nhiều        -> giữ bản đầu của mỗi id, trần kMaxKnown.
// Độ phức tạp: mọi thao tác O(số kỹ năng + số số bay); cả hai bị chặn bởi hằng ở đây.

#pragma once

#include "client/cast/note.hpp"
#include "core/clock.hpp"
#include "ui/panel/talk.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace game::client::fight {

using Time = core::Clock::time_point;

// Mét của game giữa người chơi và mục tiêu mà từ đó đánh tự động bắt đầu ra chiêu. Máy chủ kiểm tầm của từng chiêu; con số này
// chỉ là chỗ dừng đủ gần cho mọi chiêu cận chiến.
inline constexpr float kReach = 2.5F;
// Tầm tiếp cận không bị thu ngắn dưới mức này khi máy chủ kêu quá tầm.
inline constexpr float kMinReach = 0.6F;
// Mỗi lần máy chủ kêu quá tầm, tầm tiếp cận ngắn đi chừng này (mét).
inline constexpr float kReachStep = 0.7F;

// Chiêu gửi đi mà máy chủ không đáp (SkillCast với đúng seq) quá chừng này thì coi như mất.
inline constexpr std::chrono::milliseconds kCastWait{1500};
// Sau khi bị từ chối vì hồi chiêu, bận hay quá tầm, chờ chừng này mới gửi lại.
inline constexpr std::chrono::milliseconds kRetry{250};
// Một số bay sống chừng này kể từ lúc đến hạn hiện.
inline constexpr std::chrono::milliseconds kFloatLife{1200};

inline constexpr std::size_t kMaxFloats = 64;
inline constexpr std::size_t kMaxKnown = 128;

// Một con số bay trên đầu thực thể target (có thể là chính người chơi). Chưa hiện trước due: số được hẹn tới lúc đòn trúng
// trong động tác.
struct Float {
    std::uint32_t target = 0;
    cast::Blow kind = cast::Blow::kDamage;
    std::int32_t value = 0;
    bool is_critical = false;
    Time due;
};

// Chỗ nhắm của một chiêu: thực thể mục tiêu (0 là không có) và điểm đất theo mét của game.
struct Aim {
    std::uint32_t target = 0;
    float x = 0.0F;
    float z = 0.0F;
};

// Việc đánh tự động cần ở một khung: đi tới mục tiêu, hay ra chiêu.
struct Pursuit {
    bool is_approaching = false;
    std::optional<ui::panel::talk::Cast> order;
};

class Combat {
public:
    // Rời cảnh hay mất phiên: quên mục tiêu, chiêu chờ và số bay. Kỹ năng đã học và trạng thái chết giữ nguyên (do máy chủ nói).
    void leave() noexcept;

    // ---- tin của máy chủ ----
    // Toàn bộ kỹ năng đã học, thay bản cũ. cooldown_ms tính từ now.
    void learn(const ui::panel::talk::Skills& list, Time now);
    void cool(const ui::panel::talk::Cooldown& cooldown, Time now);
    // Sinh lực thật: không dương là đã chết, dương lại là đã hồi sinh.
    void vitals(const ui::panel::talk::Vitals& vitals) noexcept;
    void slain(const ui::panel::talk::Slain& notice) noexcept;
    void declined(ui::panel::talk::Decline why, Time now);
    // Máy chủ xác nhận một chiêu bằng SkillCast. true khi seq là của chiêu đang chờ: nơi vẽ chạy động tác của mình.
    [[nodiscard]] bool confirm(std::uint16_t seq) noexcept;
    void strike(const cast::Struck& blow, Time due);
    void died(const cast::Died& note, std::uint32_t self_id) noexcept;
    void vanished(std::uint32_t id) noexcept;

    // ---- việc người chơi làm ----
    // Chọn mục tiêu mà không đánh. Chọn lại đúng mục tiêu đang chọn thì giữ nguyên.
    void aim(std::uint32_t id) noexcept;
    // Chọn mục tiêu rồi đuổi và đánh tự động.
    void engage(std::uint32_t id) noexcept;
    // Thôi đánh tự động; mục tiêu vẫn được chọn.
    void disengage() noexcept { is_engaged_ = false; }
    void clear_target() noexcept;
    // Ra chiêu ngay (phím ô thao tác). Không có khi đã chết, đang chờ máy chủ, đang hồi chiêu hay đang chờ gửi lại.
    [[nodiscard]] std::optional<ui::panel::talk::Cast> cast(std::uint16_t skill, Time now, Aim where) noexcept;
    // Một khung đánh tự động. distance là khoảng cách tới mục tiêu (mét), rỗng khi mục tiêu không còn trong cảnh; is_busy là
    // người chơi đang chạy, nhảy hay giữa một đòn.
    [[nodiscard]] Pursuit pursue(Time now, std::optional<float> distance, bool is_busy) noexcept;
    // Bỏ các số đã hết hạn.
    void expire(Time now);

    // ---- đọc ----
    [[nodiscard]] std::optional<std::uint32_t> target() const noexcept { return target_; }
    [[nodiscard]] bool is_engaged() const noexcept { return is_engaged_; }
    [[nodiscard]] bool is_dead() const noexcept { return is_dead_; }
    [[nodiscard]] const std::optional<ui::panel::talk::Slain>& loss() const noexcept { return loss_; }
    [[nodiscard]] std::span<const Float> floats() const noexcept { return floats_; }
    // Id kỹ năng đã học theo thứ tự máy chủ gửi.
    [[nodiscard]] std::vector<std::uint32_t> learned() const;
    // Chiêu đánh tự động dùng: kỹ năng học đầu tiên, không có thì đánh thường (id 0).
    [[nodiscard]] std::uint16_t basic() const noexcept;
    // Hồi chiêu còn lại của kỹ năng; 0 khi dùng được hay không biết kỹ năng đó.
    [[nodiscard]] std::chrono::milliseconds cooldown_left(std::uint16_t skill, Time now) const noexcept;

private:
    struct Known {
        std::uint16_t skill = 0;
        std::uint8_t level = 0;
        Time ready_at;
    };
    struct Pending {
        std::uint16_t seq = 0;
        Time sent;
    };

    [[nodiscard]] Known* find(std::uint16_t skill) noexcept;
    [[nodiscard]] const Known* find(std::uint16_t skill) const noexcept;

    std::vector<Known> known_;
    std::optional<std::uint32_t> target_;
    bool is_engaged_ = false;
    bool is_dead_ = false;
    std::optional<ui::panel::talk::Slain> loss_;
    std::optional<Pending> pending_;
    std::uint16_t next_seq_ = 1;
    // Chưa gửi chiêu mới trước mốc này (sau lần bị từ chối).
    Time retry_at_;
    // Tầm tiếp cận hiện dùng và khoảng cách thấy ở khung đánh tự động gần nhất.
    float reach_ = kReach;
    float last_distance_ = 0.0F;
    std::vector<Float> floats_;
};

} // namespace game::client::fight
