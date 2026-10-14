// Hộp rơi: xem box.hpp.
#include "loot/box.hpp"

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/planner.hpp"
#include "item/types.hpp"

#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <optional>
#include <vector>

namespace game::loot {
namespace {

using Unexpected = std::unexpected<item::Error>;

// Kiểm hạn và quyền trước mọi thao tác nhặt.
std::expected<void, item::Error> check_rights(const DropBox& box, ids::CharacterId who, ids::Tick now) noexcept {
    if (box.expired(now)) return Unexpected(item::Error::kBoxExpired);
    if (!box.can_pick(who, now)) return Unexpected(item::Error::kNotOwner);
    return {};
}

// Món sẽ vào túi: khoá ngay nếu quy tắc vật phẩm có cờ khoá-khi-nhặt (2008 khoá lúc nhặt, không lúc rơi).
item::Instance for_pickup(const item::Instance& instance, const item::Catalog& catalog) {
    item::Instance out = instance;
    const item::Template* tmpl = catalog.find(instance.tmpl);
    if (tmpl != nullptr && tmpl->rule.pick_bind) out.bound = true;
    return out;
}

} // namespace

bool DropBox::can_pick(ids::CharacterId who, ids::Tick now) const noexcept {
    if (!owner || *owner == who) return true;
    return public_from.has_value() && now >= *public_from;
}

std::size_t DropBox::item_count() const noexcept {
    return static_cast<std::size_t>(std::ranges::count_if(slots, [](const auto& slot) { return slot.has_value(); }));
}

const item::Instance* DropBox::item(std::size_t index) const noexcept {
    if (index >= slots.size()) return nullptr;
    const std::optional<item::Instance>& slot = *std::next(slots.begin(), static_cast<std::ptrdiff_t>(index));
    return slot ? &*slot : nullptr;
}

bool DropBox::put(const item::Instance& instance) {
    const auto free = std::ranges::find_if(slots, [](const auto& slot) { return !slot.has_value(); });
    if (free == slots.end()) return false;
    *free = instance;
    return true;
}

std::expected<PickTicket, item::Error> plan_pick(const DropBox& box, std::size_t index, ids::CharacterId who, ids::Tick now,
    const item::Catalog& catalog, item::Planner& planner) {
    const item::Instance* instance = box.item(index);
    if (instance == nullptr) return Unexpected(item::Error::kNoSuchEntry);
    if (const auto rights = check_rights(box, who, now); !rights) return Unexpected(rights.error());
    if (const item::Result added = planner.add(for_pickup(*instance, catalog)); !added) return Unexpected(added.error());
    return PickTicket{.index = static_cast<std::uint8_t>(index), .serial = instance->serial};
}

std::expected<std::vector<PickTicket>, item::Error> plan_pick_all(const DropBox& box, ids::CharacterId who, ids::Tick now,
    const item::Catalog& catalog, item::Planner& planner) {
    if (const auto rights = check_rights(box, who, now); !rights) return Unexpected(rights.error());
    std::vector<PickTicket> tickets;
    std::optional<item::Error> first_failure;
    for (std::size_t index = 0; index < box.slots.size(); ++index) {
        if (box.item(index) == nullptr) continue;
        const auto ticket = plan_pick(box, index, who, now, catalog, planner);
        if (ticket) {
            tickets.push_back(*ticket);
        } else if (!first_failure) {
            first_failure = ticket.error();
        }
    }
    if (tickets.empty()) return Unexpected(first_failure.value_or(item::Error::kNoSuchEntry));
    return tickets;
}

std::expected<item::Instance, item::Error> take(DropBox& box, const PickTicket& ticket) {
    if (ticket.index >= box.slots.size()) return Unexpected(item::Error::kNoSuchEntry);
    std::optional<item::Instance>& slot = *std::next(box.slots.begin(), ticket.index);
    if (!slot || slot->serial != ticket.serial) return Unexpected(item::Error::kStalePlan);
    const item::Instance out = *slot;
    slot.reset();
    return out;
}

} // namespace game::loot
