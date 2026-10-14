// Tổng thuộc tính cộng của trang bị đang mặc: xem bonus.hpp.
#include "item/bonus.hpp"

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <vector>

namespace game::item {
namespace {

void add(std::array<std::int64_t, kAttrCount>& sum, AttrId id, std::int64_t value) noexcept {
    if (id.value() < kAttrCount) sum.at(id.value()) += value;
}

} // namespace

std::vector<AttrValue> equipment_bonuses(const Inventory& inventory, const Catalog& catalog) {
    std::array<std::int64_t, kAttrCount> sum{};
    for (const std::optional<Instance>& slot : inventory.view(Place::kEquip)) {
        if (!slot) continue;
        const Instance& item = *slot;
        const Template* tmpl = catalog.find(item.tmpl);
        if (tmpl == nullptr || tmpl->kind != Kind::kEquipment) continue;
        // Hết độ bền thì không cho gì (món không hao mòn có max_durability 0 nên luôn cho).
        if (tmpl->equip.max_durability > 0 && item.durability == 0) continue;
        for (std::size_t i = 0; i < kBaseAttrCount; ++i) {
            add(sum, AttrId{static_cast<std::uint16_t>(kAttrBasePhysicalAttack + i)}, tmpl->equip.base.at(i));
        }
        for (std::size_t i = 0; i < item.attr_count && i < item.attrs.size(); ++i) {
            const AttrValue& attr = item.attrs.at(i);
            // Thuộc tính ngẫu nhiên (id < 58) của đồ chưa giám định còn ẩn; phần cộng tư chất lên thuộc tính nền thì không.
            if (!item.identified && attr.id.value() < kRollableAttrs) continue;
            add(sum, attr.id, attr.value);
        }
        for (std::size_t g = 0; g < item.gem_slots && g < item.gems.size(); ++g) {
            const Template* gem = catalog.find(item.gems.at(g));
            if (gem == nullptr || gem->kind != Kind::kGem) continue;
            for (const AttrValue& attr : catalog.gem_attrs(*gem)) add(sum, attr.id, attr.value);
        }
    }
    std::vector<AttrValue> out;
    for (std::size_t id = 0; id < kAttrCount; ++id) {
        const std::int64_t value = std::clamp<std::int64_t>(sum.at(id), std::numeric_limits<std::int32_t>::min(),
            std::numeric_limits<std::int32_t>::max());
        if (value != 0) out.push_back(AttrValue{.id = AttrId{static_cast<std::uint16_t>(id)}, .value = static_cast<std::int32_t>(value)});
    }
    return out;
}

} // namespace game::item
