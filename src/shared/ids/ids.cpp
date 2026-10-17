/*==============================================================================
 *  THIENLONG  |  SHARED
 *------------------------------------------------------------------------------
 *  TỆP       : src/shared/ids/ids.cpp
 *  PHÂN HỆ   : Shared / Ids / Ids
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Khẳng định id không chuyển ngầm và tick làm tròn lên.
 *  - slice_ms cộng đủ 1000 ms mỗi giây ở nhịp 20, 30 và 40.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ids/ids.hpp"

#include <type_traits>

namespace game::ids {

// Kiểu khác tag là kiểu khác: không chuyển ngầm giữa các id.
static_assert(!std::is_convertible_v<ItemTemplateId, SkillId>);
static_assert(!std::is_convertible_v<std::uint32_t, ItemTemplateId>);
static_assert(std::is_trivially_copyable_v<ItemTemplateId>);
static_assert(std::is_trivially_copyable_v<EntityHandle>);
static_assert(sizeof(CharacterId) == sizeof(std::uint64_t));

// Hạn một mili giây vẫn là một tick, nửa giây ở 20 Hz là mười tick.
static_assert(to_ticks(1, 20).count == 1);
static_assert(to_ticks(500, 20).count == 10);
static_assert(to_ticks(0, 20).count == 0);
constexpr Tick kFrom{5};
constexpr TickSpan kBack{-9};
static_assert(advance(kFrom, kBack).value() == 0);
static_assert(slice_ms(1, 20) == 50);
static_assert(slice_ms(1, 40) == 25);
static_assert(slice_ms(1, 30) == 33);
static_assert(slice_ms(2, 30) == 33);
static_assert(slice_ms(3, 30) == 34);
static_assert(slice_ms(0, 20) == 0);
static_assert(ticks_to_ms_up(1, 20) == 50);
static_assert(ticks_to_ms_up(20, 20) == 1000);
static_assert(ticks_to_ms_up(1, 30) == 34);
static_assert(ticks_to_ms_up(60, 30) == 2000);
static_assert(ticks_to_ms_up(0, 20) == 0);
static_assert(rescale_ticks_up(60, 20, 20) == 60);
static_assert(rescale_ticks_up(60, 20, 40) == 120);
static_assert(rescale_ticks_up(60, 20, 30) == 90);
static_assert(rescale_ticks_up(1, 30, 30) == 1);
static_assert(rescale_ticks_up(1, 30, 20) == 1);
static_assert(rescale_ticks_up(0, 20, 40) == 0);
static_assert(rescale_ticks_down(2, 30, 20) == 1);
static_assert(rescale_ticks_down(4, 20, 40) == 8);
static_assert(rescale_ticks_up(55, 20, 40) == 110);
static_assert(rescale_ticks_up(55, 20, 30) == 83);

constexpr std::int64_t sum_slices(std::int64_t hz) {
    std::int64_t total = 0;
    const auto steps = static_cast<std::uint64_t>(hz);
    for (std::uint64_t i = 1; i <= steps; ++i)
        total += slice_ms(i, hz);
    return total;
}
static_assert(sum_slices(20) == 1000);
static_assert(sum_slices(30) == 1000);
static_assert(sum_slices(40) == 1000);

} // namespace game::ids
