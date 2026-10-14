#pragma once
// Công thức sát thương, trúng/né, hội tâm: hàm thuần trên số nguyên, không đụng thân thể hay cảnh. Mọi phép
// làm tròn kiểu Float2Int dùng actor::round_ratio nên cùng đầu vào cho cùng kết quả trên mọi nền tảng.
//
// Nguồn: GameServer 2008 Skills/Combat_Core.cpp (PhysicalDamage, MagicalDamage, Cold/Fire/Light/PoisonDamage,
// CalculateHitRate, IsHit, IsCriticalHit, độ dao động), Common/GameDefine_Attr.h (Attr_Verify*).
// Khác gốc ghi tại chỗ bằng "Khác gốc:".
//
// Thứ tự rút xúc xắc của một đòn (để dựng số vàng độc lập): mỗi mục tiêu rút trúng/né (nếu không phải bạn và
// kỹ năng không luôn trúng), rồi với mục tiêu bị trúng rút hội tâm (nếu đòn tấn công), rồi hiệu ứng sát
// thương rút dao động. Mọi lần rút là dice.below(100), tức Rand100 của bản gốc.

#include "combat/types.hpp"

#include <cstdint>

namespace game::combat {

// Số liệu của kẻ tấn công đưa vào công thức.
struct AttackerView {
    std::int32_t attack_phy = 0;
    std::int32_t attack_magic = 0;
    ElementValues attack_element;      // công theo hệ
    ElementValues resist_reduce;       // giảm kháng đối phương theo từng hệ
    std::int32_t hit = 0;
    std::int32_t critical = 0;
    std::int32_t fluctuation = 0;      // biên độ dao động, phần trăm
};

struct DefenderView {
    std::int32_t defence_phy = 0;
    std::int32_t defence_magic = 0;
    ElementValues resist_element;      // kháng theo hệ
    std::int32_t miss = 0;
    std::int32_t immunity_phy = 0;     // phần trăm, 0..100
    std::int32_t immunity_magic = 0;
};

// Điểm cộng thêm của riêng một hiệu ứng sát thương (tham số "vật công+", "nội công+"...) và của kỹ năng.
struct Additions {
    ChannelDamage attack;
    ChannelDamage defence;
};

// Attr_Verify*: kẹp giá trị vào miền hợp lệ.
[[nodiscard]] std::int32_t verify_general(std::int64_t value) noexcept;  // công/thủ ngoại-nội, tối thiểu 1
[[nodiscard]] std::int32_t verify_trait(std::int64_t value) noexcept;    // công hệ, tối thiểu 0
[[nodiscard]] std::int32_t verify_resist(std::int64_t value) noexcept;   // kháng, -200..200
[[nodiscard]] std::int32_t verify_hit_miss(std::int64_t value) noexcept; // 1..1000
[[nodiscard]] std::int32_t verify_critical(std::int64_t value) noexcept; // 0..100

// Tỉ lệ trúng phần trăm 0..100 từ điểm trúng và điểm né của hai bên.
[[nodiscard]] std::int32_t hit_rate(std::int64_t hit, std::int64_t miss) noexcept;
// Trúng khi roll (0..99) < rate (kẹp 0..100). Tỉ lệ 100 luôn trúng.
[[nodiscard]] bool is_hit(std::int64_t rate, std::int32_t roll) noexcept;
[[nodiscard]] bool is_critical(std::int64_t rate, std::int32_t roll) noexcept;

// Sát thương từng kênh trước dao động. atk²/(atk+def) cho ngoại và nội công rồi trừ miễn nhiễm; công hệ nhân
// (100 - kháng)/100 với kháng kẹp ±100. Không âm.
[[nodiscard]] ChannelDamage channel_damage(const AttackerView& attacker, const DefenderView& defender,
    const Additions& additions) noexcept;

// Hệ số dao động từ roll (0..99): Float2Int(2 * biên độ * (50 - roll) / 100), phần trăm cộng thêm (có thể âm).
[[nodiscard]] std::int32_t fluctuation_percent(std::int32_t amplitude, std::int32_t roll) noexcept;

// Áp dao động lên một giá trị: v + v * percent / 100 (chia nguyên cắt về 0, như bản gốc).
[[nodiscard]] std::int32_t apply_fluctuation(std::int32_t value, std::int32_t percent) noexcept;

// Cộng/trừ phần trăm kiểu RefixPowerByRate: Float2Int(value * (100 + percent) / 100).
[[nodiscard]] std::int32_t refix_percent(std::int64_t value, std::int64_t percent) noexcept;

// Tổng sáu kênh (kẹp int32).
[[nodiscard]] std::int64_t total(const ChannelDamage& damage) noexcept;

} // namespace game::combat
