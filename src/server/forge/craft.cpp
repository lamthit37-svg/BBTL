// Chế biến ở lò rèn: xem craft.hpp.
#include "forge/craft.hpp"

#include "forge/tables.hpp"

#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <expected>
#include <span>
#include <utility>

namespace game::forge {

namespace {

using Unexpected = std::unexpected<item::Error>;

// Lỗi của ô không có đồ: Planner::get trả nullptr cho cả ô ngoài biên lẫn ô trống nên hỏi remove_at để biết cái nào.
[[nodiscard]] item::Error empty_slot_error(const item::Planner& planner, item::SlotRef where) {
    item::Planner probe = planner;
    const item::Result probed = probe.remove_at(where, 1);
    return probed ? item::Error::kSlotEmpty : probed.error();
}

// Trừ cả bộ vật liệu; lỗi thì `planner` có thể đã đổi một phần, nên bên gọi chỉ truyền bản thử.
[[nodiscard]] item::Result take_all(item::Planner& planner, std::span<const Material> set) {
    for (const Material& material : set) {
        if (const item::Result taken = planner.remove_count(material.item, material.count); !taken) return taken;
    }
    return {};
}

} // namespace

std::expected<CraftReport, item::Error> plan_craft(const ForgeTables& tables, Kind kind, item::SlotRef from,
    const item::Factory& factory, dice::Dice& dice, item::SerialAllocator& serials, ids::Tick now, item::Planner& planner) {
    if (!item::is_bag(from.place)) return Unexpected(item::Error::kWrongPlace);
    const item::Instance* held = planner.get(from);
    if (held == nullptr) return Unexpected(empty_slot_error(planner, from));
    const Recipe* recipe = tables.find(kind, held->tmpl);
    if (recipe == nullptr) return Unexpected(item::Error::kNoSuchEntry);
    const item::TemplateId input = held->tmpl;
    const bool bound = held->bound;  // đọc trước: remove_at làm `held` không còn nghĩa

    item::Planner trial = planner;
    if (const item::Result removed = trial.remove_at(from, 1); !removed) return Unexpected(removed.error());

    // Bộ chính trước; thiếu thì thử bộ thay thế trên một bản sao mới (bộ chính có thể đã trừ dở).
    bool used_substitute = false;
    item::Planner primary = trial;
    item::Result stocked = take_all(primary, tables.needs(*recipe));
    if (stocked) {
        trial = std::move(primary);
    } else if (stocked.error() == item::Error::kNotEnoughItems && recipe->alt_count > 0) {
        item::Planner alternative = trial;
        stocked = take_all(alternative, tables.alternative(*recipe));
        if (stocked) {
            trial = std::move(alternative);
            used_substitute = true;
        }
    }
    if (!stocked) return Unexpected(stocked.error());

    if (recipe->gold > 0) {
        if (const item::Result paid = trial.spend(item::Currency::kGold, recipe->gold); !paid) return Unexpected(paid.error());
    }

    // Sinh món ra sau cùng để kiểm hỏng nào rẻ cũng đã qua, không phí serial.
    const item::CreateRequest request{
        .tmpl = recipe->output, .count = 1, .picked = false, .now = now, .roll = item::RollContext{.origin = item::Origin::kForge, .forge_level = 0}};
    std::expected<item::Instance, item::Error> made = factory.create(request, dice, serials);
    if (!made) return Unexpected(made.error());
    made->bound = made->bound || bound;
    if (const item::Result added = trial.add(*made); !added) return Unexpected(added.error());

    planner = std::move(trial);
    return CraftReport{.input = input, .produced = *made, .gold = recipe->gold, .used_substitute = used_substitute};
}

} // namespace game::forge
