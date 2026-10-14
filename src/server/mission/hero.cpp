#include "mission/hero.hpp"

#include "mission/book.hpp"
#include "mission/catalog.hpp"

#include <cstddef>
#include <cstdint>
#include <limits>
#include <utility>

namespace game::mission {

std::int32_t HeroFacade::bag_space() const noexcept { return who_.ports().items.free_slots(); }

std::int64_t HeroFacade::money(bool bound) const noexcept { return who_.ports().wallet.balance(bound); }

std::int64_t HeroFacade::item_count(std::uint32_t item) const noexcept { return who_.ports().items.count(item); }

bool HeroFacade::quest_active(std::uint32_t quest) const noexcept {
    return quest <= static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max()) &&
           who_.book().find(static_cast<std::int32_t>(quest)) != nullptr;
}

bool HeroFacade::quest_done(std::uint32_t quest) const noexcept {
    return quest <= static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max()) &&
           who_.book().is_done(static_cast<std::int32_t>(quest));
}

std::uint32_t HeroFacade::quest_name(std::uint32_t quest) const noexcept {
    if (catalog_ == nullptr || quest > static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max())) return 0;
    const Slot* const slot = who_.book().find(static_cast<std::int32_t>(quest));
    if (slot == nullptr || slot->script < 0) return 0;
    const Quest* const held = catalog_->by_script(static_cast<std::uint32_t>(slot->script));
    return held == nullptr ? 0 : held->name_id;
}

std::int32_t HeroFacade::quest_count() const noexcept { return who_.book().active(); }

std::int32_t HeroFacade::quest_slots_free() const noexcept { return who_.book().free_slots(); }

std::int32_t HeroFacade::objective(std::uint32_t quest, std::int32_t index) const noexcept {
    if (index < 0 || std::cmp_greater_equal(index, kParamCount) ||
        quest > static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max())) {
        return 0;
    }
    const Slot* const slot = who_.book().find(static_cast<std::int32_t>(quest));
    if (slot == nullptr) return 0;
    const std::uint32_t value = slot->params.at(static_cast<std::size_t>(index));
    return value > static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max())
               ? std::numeric_limits<std::int32_t>::max()
               : static_cast<std::int32_t>(value);
}

std::int64_t HeroFacade::counter(std::int32_t index) const noexcept { return who_.book().counter(index); }

bool HeroFacade::flag(std::int32_t index) const noexcept { return who_.book().flag(index); }

}  // namespace game::mission
