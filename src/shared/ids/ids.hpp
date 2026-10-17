/*==============================================================================
 *  THIENLONG  |  SHARED
 *------------------------------------------------------------------------------
 *  TỆP       : src/shared/ids/ids.hpp
 *  PHÂN HỆ   : Shared / Ids / Ids
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Id mạnh của nội dung và thực thể (cpp23 KG-06..11). Mỗi id là một kiểu
 *    riêng nên không trộn được vật phẩm với kỹ năng. Nền số nguyên không dấu; 0
 *    là "không có" chỉ ở chỗ bảng gốc quy ước thế, còn nơi khác dùng
 *    std::optional. Id không có phép số học: chỉ so sánh, băm và đọc giá trị.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nguồn: TLBB Dev src/ids (docs/LOGIC.md mục 3). Khác gốc: một template StrongId thay cho từng
// enum class rời, để có chung băm và toán tử so sánh; thêm Tick/TickSpan. Nhịp chọn lúc zone
// khởi động (mặc định 20 Hz); mili giây làm tròn lên, không sớm hơn hợp đồng.

#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <limits>

namespace game::ids {

template <typename Tag, typename Rep>
class StrongId {
public:
    using Representation = Rep;

    constexpr StrongId() noexcept = default;
    constexpr explicit StrongId(Rep value) noexcept : value_(value) {}

    [[nodiscard]] constexpr Rep value() const noexcept { return value_; }

    friend constexpr bool operator==(StrongId, StrongId) noexcept = default;
    friend constexpr auto operator<=>(StrongId, StrongId) noexcept = default;

private:
    Rep value_{};
};

// Thực thể sống trong một cảnh: người, quái, NPC, vật rơi. Thế hệ tách khỏi chỉ số để tay nắm cũ
// không trỏ nhầm thực thể mới cấp lại cùng ô (cpp23 MMO-04).
struct EntityHandle {
    std::uint32_t index = 0;
    std::uint32_t generation = 0;

    friend constexpr bool operator==(EntityHandle, EntityHandle) noexcept = default;
    friend constexpr auto operator<=>(EntityHandle, EntityHandle) noexcept = default;
};

using CharacterId = StrongId<struct CharacterTag, std::uint64_t>;
using AccountId = StrongId<struct AccountTag, std::uint64_t>;
using ItemSerial = StrongId<struct ItemSerialTag, std::uint64_t>;
using SceneId = StrongId<struct SceneTag, std::uint16_t>;
using ItemTemplateId = StrongId<struct ItemTemplateTag, std::uint32_t>;
using SkillId = StrongId<struct SkillTag, std::uint32_t>;
using ImpactId = StrongId<struct ImpactTag, std::uint32_t>;
using InnerArtId = StrongId<struct InnerArtTag, std::uint32_t>;
using MonsterTemplateId = StrongId<struct MonsterTemplateTag, std::uint32_t>;
using NpcId = StrongId<struct NpcTag, std::uint32_t>;
using QuestId = StrongId<struct QuestTag, std::uint32_t>;
using GuildId = StrongId<struct GuildTag, std::uint64_t>;
using TeamId = StrongId<struct TeamTag, std::uint64_t>;
using PetId = StrongId<struct PetTag, std::uint64_t>;
using ShopId = StrongId<struct ShopTag, std::uint32_t>;
using SectId = StrongId<struct SectTag, std::uint8_t>;

// Số môn phái của client 2026 (0..15 trừ 9). Phái 15 chỉ có ở bản 2026, bản 14 môn phái của
// XJL7457 không có nó (docs/AUDIT/G-XJL7457.md mục 3).
inline constexpr std::uint8_t kSectNone = 9;
inline constexpr std::uint8_t kSectCount = 16;

// Mô phỏng chạy bước cố định; mọi hạn chờ và hồi chiêu tính bằng tick, không bằng đồng hồ thật
// (cpp23 MMO-03).
using Tick = StrongId<struct TickTag, std::uint64_t>;

// Khoảng giữa hai tick, có dấu để trừ hai mốc không quấn.
struct TickSpan {
    std::int64_t count = 0;

    friend constexpr bool operator==(TickSpan, TickSpan) noexcept = default;
    friend constexpr auto operator<=>(TickSpan, TickSpan) noexcept = default;
};

[[nodiscard]] constexpr TickSpan operator-(Tick later, Tick earlier) noexcept {
    return TickSpan{static_cast<std::int64_t>(later.value() - earlier.value())};
}

// Cộng không tràn: kết quả kẹp ở tick lớn nhất, và khoảng âm không lùi quá 0.
[[nodiscard]] constexpr Tick advance(Tick from, TickSpan span) noexcept {
    constexpr std::uint64_t kMax = std::numeric_limits<std::uint64_t>::max();
    if (span.count >= 0) {
        const auto add = static_cast<std::uint64_t>(span.count);
        return Tick{add > kMax - from.value() ? kMax : from.value() + add};
    }
    const std::uint64_t back = ~static_cast<std::uint64_t>(span.count) + 1U;
    return Tick{back > from.value() ? 0U : from.value() - back};
}

// Mili giây thiết kế sang tick, làm tròn lên: một hạn 1 ms không bao giờ thành 0 tick (cpp23 STD-15).
[[nodiscard]] constexpr TickSpan to_ticks(std::int64_t milliseconds, std::int64_t ticks_per_second) noexcept {
    if (milliseconds <= 0 || ticks_per_second <= 0) return TickSpan{0};
    constexpr std::int64_t kMilli = 1000;
    const std::int64_t whole = milliseconds / kMilli;
    const std::int64_t rest = milliseconds % kMilli;
    return TickSpan{
        (whole * ticks_per_second) + (((rest * ticks_per_second) + kMilli - 1) / kMilli)};
}

// Mili giây đã trôi tới hết tick `tick_index` (1-based), chia phần để không tràn.
[[nodiscard]] constexpr std::uint64_t ms_through(std::uint64_t tick_index,
    std::uint64_t hz) noexcept {
    if (hz == 0) return 0;
    const std::uint64_t whole = tick_index / hz;
    const std::uint64_t part = tick_index % hz;
    return (whole * 1000ULL) + ((part * 1000ULL) / hz);
}

// Độ dài mili giây của một tick. Mọi hz tick liên tiếp cộng đúng 1000. 30 Hz là 33, 33, 34.
[[nodiscard]] constexpr std::int64_t slice_ms(std::uint64_t tick_index,
    std::int64_t ticks_per_second) noexcept {
    if (tick_index == 0 || ticks_per_second <= 0) return 0;
    const auto step = static_cast<std::uint64_t>(ticks_per_second);
    const std::uint64_t end = ms_through(tick_index, step);
    const std::uint64_t start = ms_through(tick_index - 1ULL, step);
    return static_cast<std::int64_t>(end - start);
}

// Tick còn lại sang mili giây, làm tròn lên. 20 Hz đúng n*50; 30 Hz không được dùng 33 (60*33 =
// 1980).
[[nodiscard]] constexpr std::int64_t ticks_to_ms_up(std::int64_t ticks,
    std::int64_t ticks_per_second) noexcept {
    if (ticks <= 0 || ticks_per_second <= 0) return 0;
    constexpr std::int64_t kMilli = 1000;
    const std::int64_t room = std::numeric_limits<std::int64_t>::max() - (ticks_per_second - 1);
    if (ticks > room / kMilli) return std::numeric_limits<std::int64_t>::max();
    return ((ticks * kMilli) + ticks_per_second - 1) / ticks_per_second;
}

// Đổi số bước từ nhịp này sang nhịp kia. Cùng nhịp thì đúng nguyên số, nên ghi rồi đọc lại không
// dài thêm. Làm tròn lên: hạn không bao giờ xong sớm hơn hợp đồng mili giây.
[[nodiscard]] constexpr std::int64_t rescale_ticks_up(std::int64_t ticks, std::int64_t from_hz,
    std::int64_t to_hz) noexcept {
    const bool bad = ticks <= 0 || from_hz <= 0 || to_hz <= 0;
    if (bad) return 0;
    if (from_hz == to_hz) return ticks;
    constexpr std::int64_t kMax = std::numeric_limits<std::int64_t>::max();
    const std::int64_t room = (kMax - (from_hz - 1)) / to_hz;
    if (ticks > room) return kMax;
    return (ticks * to_hz + (from_hz - 1)) / from_hz;
}

// Phần đã trôi, làm tròn xuống, để phần còn lại làm tròn lên không bị phần đã trôi nuốt mất.
[[nodiscard]] constexpr std::int64_t rescale_ticks_down(std::int64_t ticks, std::int64_t from_hz,
    std::int64_t to_hz) noexcept {
    const bool bad = ticks <= 0 || from_hz <= 0 || to_hz <= 0;
    if (bad) return 0;
    if (from_hz == to_hz) return ticks;
    constexpr std::int64_t kMax = std::numeric_limits<std::int64_t>::max();
    if (ticks > kMax / to_hz) return kMax;
    return (ticks * to_hz) / from_hz;
}

} // namespace game::ids

template <typename Tag, typename Rep>
struct std::hash<game::ids::StrongId<Tag, Rep>> {
    [[nodiscard]] std::size_t operator()(game::ids::StrongId<Tag, Rep> id) const noexcept {
        return std::hash<Rep>{}(id.value());
    }
};
