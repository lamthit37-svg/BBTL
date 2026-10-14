#pragma once
// Kiểu chung của lõi chiến đấu: kênh sát thương, toạ độ, quan hệ, sự kiện đầu ra. Lõi thuần: không mạng, không
// đồng hồ thật; thời gian là tick (ids::Tick), ngẫu nhiên là dice::Dice do nơi gọi đưa vào.
//
// Nguồn: GameServer 2008 Common/GameDefine2.h (DAMAGE_TYPE_*), GameDefine_Attr.h (giới hạn thuộc tính),
// Skills/Combat_Core.*, EventModule/EventCore.*. Khác gốc ghi tại chỗ bằng "Khác gốc:".

#include "actor/numeric.hpp"
#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>

namespace game::combat {

// Sáu kênh sát thương, đúng thứ tự DAMAGE_TYPE_P, M, COLD, FIRE, LIGHT, POISON. "Light" là hệ điện của bản gốc
// (client 2026 gọi là Huyền).
enum class Channel : std::uint8_t { kPhysical, kMagic, kCold, kFire, kLight, kPoison };
inline constexpr std::size_t kChannelCount = 6;
using ChannelDamage = actor::EnumArray<Channel, std::int32_t, kChannelCount>;

// Bốn hệ nguyên tố (băng, lửa, điện, độc) là bốn kênh cuối.
enum class Element : std::uint8_t { kCold, kFire, kLight, kPoison };
inline constexpr std::size_t kElementCount = 4;
using ElementValues = actor::EnumArray<Element, std::int32_t, kElementCount>;

[[nodiscard]] constexpr Channel channel_of(Element element) noexcept {
    return static_cast<Channel>(static_cast<std::size_t>(element) + 2U);
}
[[nodiscard]] constexpr Element element_of(Channel channel) noexcept {
    return static_cast<Element>(static_cast<std::size_t>(channel) - 2U);
}

// Toạ độ trên mặt đất, centimet nguyên (cùng đơn vị với dây và zone).
struct Position {
    std::int32_t x_cm = 0;
    std::int32_t z_cm = 0;

    friend constexpr bool operator==(const Position&, const Position&) noexcept = default;
};

[[nodiscard]] constexpr std::int64_t distance_sq_cm(Position a, Position b) noexcept {
    const std::int64_t dx = static_cast<std::int64_t>(a.x_cm) - b.x_cm;
    const std::int64_t dz = static_cast<std::int64_t>(a.z_cm) - b.z_cm;
    return (dx * dx) + (dz * dz);
}

enum class Relation : std::uint8_t { kFriend, kEnemy };

// Cờ đứng của hiệu ứng/kỹ năng (BEHAVIOR_TYPE_*): -1 địch, 0 trung lập, 1 thiện.
inline constexpr std::int32_t kStandHostile = -1;
inline constexpr std::int32_t kStandNeutral = 0;
inline constexpr std::int32_t kStandAmity = 1;

// Trần của lõi (cpp23 STD-15: mọi tài nguyên có trần).
inline constexpr std::size_t kMaxBuffs = 20;            // MAX_IMPACT_NUM
inline constexpr std::size_t kMaxCooldowns = 255;       // COOLDOWN_LIST_SIZE
inline constexpr std::size_t kMaxSkills = 512;          // số kỹ năng một nhân vật giữ trong sổ
inline constexpr std::size_t kMaxScanTargets = 100;     // trần số mục tiêu một lần quét vùng
inline constexpr std::size_t kMaxPending = 4096;        // trần hàng đợi hiệu ứng chờ
inline constexpr std::size_t kMaxEvents = 65536;        // trần hàng đợi sự kiện đầu ra
inline constexpr std::int32_t kMaxEffectiveResist = 100; // MAX_EFFECTIVE_RESIST
inline constexpr std::int32_t kMinResist = -200;        // LL_RESIST
inline constexpr std::int32_t kMaxResist = 200;         // UL_RESIST
inline constexpr std::int32_t kMinHitMiss = 1;          // LL_HIT_MISS
inline constexpr std::int32_t kMaxHitMiss = 1000;       // UL_HIT_MISS
inline constexpr std::int32_t kMaxCritical = 100;       // UL_CRITICAL
inline constexpr std::int32_t kStrikeSegment = 3;       // STRIKE_POINT_SEGMENT_SIZE
inline constexpr std::int32_t kMaxStrikeSegment = 3;    // MAX_STRIKE_POINT / STRIKE_POINT_SEGMENT_SIZE
inline constexpr std::int32_t kMinChannelMs = 500;      // ChannelAction: thời gian/chu kỳ dưới 500 ms bị coi là sai
inline constexpr std::int32_t kDefaultChannelIntervalMs = 2000;
inline constexpr std::int32_t kMaxDisturbChargeMs = 500; // OnDisturbForCharging: một lần bị đánh lùi tối đa 500 ms

// Loại sự kiện đầu ra. Lõi không có mạng: nơi gọi (zone/gate) đọc hàng đợi sự kiện rồi tự phát tin.
enum class EventKind : std::uint8_t {
    kCastStarted,      // actor bắt đầu dùng kỹ năng id; value = loại (0 tức thời, 1 gom, 2 dẫn)
    kCastFinished,     // kỹ năng id chạy xong
    kCastInterrupted,  // kỹ năng id bị ngắt
    kMissed,           // actor đánh trượt target (value = MissKind)
    kDamaged,          // target mất value HP do actor (extra bit 0 = bạo kích); value là sát thương tính được, không kẹp theo máu còn
    kHealed,           // target được hồi value HP do actor; value là lượng tính được, kể cả phần vượt mức tối đa (hồi tự nhiên thì đã kẹp)
    kManaChanged,      // target đổi value MP
    kRageChanged,      // target đổi value nộ khí
    kStrikeChanged,    // target đổi value điểm liên kích
    kImpact,           // target nhận hiệu ứng tức thời id (hình ảnh/âm thanh cho client)
    kBuffAdded,        // target nhận buff id (id = hiệu ứng), extra = số thứ tự buff
    kBuffRemoved,      // target mất buff id
    kBuffRefused,      // buff id bị từ chối (value = MissKind)
    kDied,             // target chết do actor
    kRevived,          // target hồi sinh
    kTeleport,         // target dịch chuyển tới `where`: id = cảnh đích cộng 1 (0 là cùng cảnh)
    kAggro,            // actor khiêu khích target (value 1 = đặt làm mục tiêu chính)
    kSpawn,            // actor xin tạo vật đặc biệt tại `where`: id = dữ liệu bẫy/tượng/triệu hồi, value = loại
                       // (SpawnKind), extra = kỹ năng sinh ra nó
    kMove,             // actor lướt/nhảy (kỹ năng khinh công) tới `where`: id = kỹ năng
    kFriendliness,     // actor tặng target value điểm thân thiện
    kCooldownCleared,  // target được xoá hồi chiêu id
    kUnsupported,      // thao tác cần module ngoài lõi (value = mã lý do UnsupportedReason)
    kThreat,           // actor ra chiêu về phía target (OnBeSkill): value = đứng của chiêu (-1 địch, 0, 1 thiện)
    kReliveOffered,    // target đã chết được đề nghị hồi sinh (Fighter::relive); value = phần trăm HP sau hồi sinh
};

enum class MissKind : std::uint8_t { kMiss, kImmune, kAbsorb };

enum class SpawnKind : std::uint8_t { kTrap, kTotem, kSummon, kPuppet, kPet, kMount, kShadow };

enum class UnsupportedReason : std::uint8_t {
    kScript,        // cần chạy script Lua
    kAirborne,      // cần trạng thái bay
    kUnknownLogic,  // logic chưa có mã
    kOutOfModule,   // thao tác thuộc module khác (nhiệm vụ, xã hội...)
    kMissingData,   // id hiệu ứng/kỹ năng không có dòng trong bảng (id = số thiếu)
};

struct Event {
    EventKind kind = EventKind::kCastStarted;
    ids::Tick tick;
    ids::EntityHandle actor;
    ids::EntityHandle target;
    std::uint32_t id = 0;
    std::int32_t value = 0;
    std::int32_t extra = 0;
    Position where;

    friend constexpr bool operator==(const Event&, const Event&) noexcept = default;
};

} // namespace game::combat
