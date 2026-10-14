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
static_assert(advance(Tick{5}, TickSpan{-9}).value() == 0);

} // namespace game::ids
