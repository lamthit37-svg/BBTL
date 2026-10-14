// Hộp rơi: quyền nhặt (chủ, mốc ai cũng nhặt được), hạn bằng tick, nhặt hai bước (kế hoạch rồi lấy khỏi hộp), nhặt hết khi túi
// gần đầy, khoá khi nhặt, và một vòng trọn từ lúc quái chết tới lúc đồ nằm trong túi.
#include "loot_support.hpp"

#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/types.hpp"
#include "loot/box.hpp"
#include "loot/roller.hpp"
#include "loot/types.hpp"
#include "test.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <expected>
#include <initializer_list>
#include <optional>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using loot::DropBox;
using loot::PickTicket;

constexpr ids::CharacterId kOwner{7};
constexpr ids::CharacterId kStranger{8};

bool failed_with(const std::expected<PickTicket, item::Error>& result, item::Error error) {
    return !result.has_value() && result.error() == error;
}

DropBox box_with(Bench& bench, std::initializer_list<std::uint32_t> ids, std::optional<ids::CharacterId> owner = kOwner) {
    DropBox box;
    box.owner = owner;
    box.expires_at = ids::Tick{1000};
    for (const std::uint32_t id : ids) {
        if (!box.put(bench.make(id))) std::abort();
    }
    return box;
}

void rights_and_expiry(Context& context) {
    Bench bench;
    DropBox box = box_with(bench, {kPotion});
    context.expect(box.can_pick(kOwner, ids::Tick{5}) && !box.can_pick(kStranger, ids::Tick{5}), "chỉ chủ nhặt được");
    context.expect(!box.expired(ids::Tick{999}) && box.expired(ids::Tick{1000}) && box.expired(ids::Tick{5000}), "hết hạn đúng tại expires_at");

    box.public_from = ids::Tick{600};
    context.expect(!box.can_pick(kStranger, ids::Tick{599}) && box.can_pick(kStranger, ids::Tick{600}) && box.can_pick(kStranger, ids::Tick{900}),
        "người lạ nhặt được từ public_from");
    context.expect(box.can_pick(kOwner, ids::Tick{0}), "chủ luôn nhặt được");

    DropBox free_box = box_with(bench, {kPotion}, std::nullopt);
    context.expect(free_box.can_pick(kStranger, ids::Tick{0}) && free_box.can_pick(kOwner, ids::Tick{0}), "hộp không chủ ai cũng nhặt");

    item::Planner planner = bench.planner();
    context.expect(failed_with(loot::plan_pick(box, 0, kOwner, ids::Tick{1000}, bench.world.catalog, planner), item::Error::kBoxExpired),
        "hộp hết hạn: chủ cũng không nhặt được");
    context.expect(failed_with(loot::plan_pick(box, 0, kStranger, ids::Tick{1000}, bench.world.catalog, planner), item::Error::kBoxExpired),
        "hộp hết hạn báo hết hạn trước quyền");
    DropBox other = box_with(bench, {kPotion});
    context.expect(failed_with(loot::plan_pick(other, 0, kStranger, ids::Tick{10}, bench.world.catalog, planner), item::Error::kNotOwner),
        "người lạ bị từ chối");
    context.expect(failed_with(loot::plan_pick(other, 1, kOwner, ids::Tick{10}, bench.world.catalog, planner), item::Error::kNoSuchEntry),
        "ô trống");
    context.expect(failed_with(loot::plan_pick(other, loot::kBoxCapacity, kOwner, ids::Tick{10}, bench.world.catalog, planner),
                       item::Error::kNoSuchEntry),
        "chỉ số đúng bằng cỡ hộp");
    context.expect(failed_with(loot::plan_pick(other, static_cast<std::size_t>(-1), kOwner, ids::Tick{10}, bench.world.catalog, planner),
                       item::Error::kNoSuchEntry),
        "chỉ số cực đoan");
    context.expect(std::move(planner).finish().slots.empty(), "mọi lần bị từ chối không để lại thay đổi trong kế hoạch");
}

void two_step_pick(Context& context) {
    Bench bench;
    DropBox box = box_with(bench, {kPotion, kSword, kHerb});
    const item::Instance sword = *box.item(1);

    item::Planner planner = bench.planner();
    const auto ticket = loot::plan_pick(box, 1, kOwner, ids::Tick{10}, bench.world.catalog, planner);
    context.expect(ticket.has_value() && ticket->index == 1 && ticket->serial == sword.serial, "phiếu mang chỉ số và serial");
    context.expect(box.item_count() == 3, "dựng kế hoạch không đổi hộp");
    context.expect(bench.inventory.get(bag(0)) == nullptr, "dựng kế hoạch không đổi túi");
    if (!ticket) return;

    context.expect(bench.commit(std::move(planner)), "áp kế hoạch");
    const item::Instance* in_bag = bench.inventory.get(bag(0));
    context.expect(in_bag != nullptr && in_bag->serial == sword.serial, "đồ đã nằm trong túi");

    const auto taken = loot::take(box, *ticket);
    context.expect(taken.has_value() && *taken == sword, "take trả đúng món");
    context.expect(box.item_count() == 2 && box.item(1) == nullptr && box.item(0) != nullptr && box.item(2) != nullptr,
        "các ô còn lại giữ nguyên chỉ số");
    const auto again = loot::take(box, *ticket);
    context.expect(!again && again.error() == item::Error::kStalePlan, "phiếu dùng lần hai bị từ chối");

    // Ô bị đổi món giữa lúc dựng và lúc lấy.
    DropBox swapped = box_with(bench, {kPotion});
    item::Planner second = bench.planner();
    const auto stale = loot::plan_pick(swapped, 0, kOwner, ids::Tick{10}, bench.world.catalog, second);
    swapped.slots.front() = bench.make(kHerb);
    context.expect(stale && !loot::take(swapped, *stale) && swapped.item_count() == 1, "ô đã đổi món: take từ chối và không đổi hộp");
    context.expect(!loot::take(swapped, PickTicket{.index = 200, .serial = item::Serial{1}}) && swapped.item_count() == 1, "chỉ số phiếu ngoài hộp");
}

void pick_binds_on_pickup(Context& context) {
    Bench bench;
    DropBox box = box_with(bench, {kPickBound, kPotion});
    context.expect(!box.item(0)->bound, "đồ nằm trên đất chưa khoá");
    item::Planner planner = bench.planner();
    const auto ticket = loot::plan_pick(box, 0, kOwner, ids::Tick{10}, bench.world.catalog, planner);
    const auto other = loot::plan_pick(box, 1, kOwner, ids::Tick{10}, bench.world.catalog, planner);
    context.expect(ticket && other && bench.commit(std::move(planner)), "nhặt hai món");
    const item::Instance* locked = bench.inventory.get(bag(0));
    const item::Instance* loose = bench.inventory.get(bag(1));
    context.expect(locked != nullptr && locked->bound && loose != nullptr && !loose->bound, "chỉ đồ có cờ khoá-khi-nhặt bị khoá");
    context.expect(!box.item(0)->bound, "bản trong hộp không đổi");
}

void pick_all_partial(Context& context) {
    Bench bench;
    // 19 trong 20 ô mở của túi đạo cụ đã có kiếm; chỉ còn một ô trống.
    for (std::uint16_t i = 0; i < 19; ++i) bench.put(bag(i), bench.make(kSword));
    DropBox box = box_with(bench, {kSword, kSword, kPotion});
    item::Planner planner = bench.planner();
    const auto tickets = loot::plan_pick_all(box, kOwner, ids::Tick{10}, bench.world.catalog, planner);
    context.expect(tickets.has_value() && tickets->size() == 1 && tickets->front().index == 0, "chỉ món đầu cất vừa");
    if (!tickets) return;
    context.expect(bench.commit(std::move(planner)), "áp kế hoạch");
    for (const PickTicket& ticket : *tickets) context.expect(loot::take(box, ticket).has_value(), "lấy khỏi hộp");
    context.expect(box.item_count() == 2 && box.item(0) == nullptr && box.item(1) != nullptr && box.item(2) != nullptr, "hai món ở lại hộp");

    // Túi đã đầy: không món nào cất được, trả lỗi cất và hộp nguyên vẹn.
    item::Planner full = bench.planner();
    const auto none = loot::plan_pick_all(box, kOwner, ids::Tick{10}, bench.world.catalog, full);
    context.expect(!none && none.error() == item::Error::kBagFull, "túi đầy: kBagFull");
    context.expect(box.item_count() == 2, "hộp nguyên vẹn");

    // Đồ chồng được cất vào chồng cũ dù không còn ô trống.
    bench.put(bag(19), bench.make(kPotion, 3));
    item::Planner stack = bench.planner();
    const auto merged = loot::plan_pick_all(box, kOwner, ids::Tick{10}, bench.world.catalog, stack);
    context.expect(merged && merged->size() == 1 && merged->front().index == 2, "thuốc gộp vào chồng sẵn có");

    DropBox empty;
    empty.owner = kOwner;
    empty.expires_at = ids::Tick{1000};
    item::Planner nothing = bench.planner();
    const auto nobody = loot::plan_pick_all(empty, kOwner, ids::Tick{10}, bench.world.catalog, nothing);
    context.expect(!nobody && nobody.error() == item::Error::kNoSuchEntry, "hộp trống");
    const auto stranger = loot::plan_pick_all(box, kStranger, ids::Tick{10}, bench.world.catalog, nothing);
    context.expect(!stranger && stranger.error() == item::Error::kNotOwner, "người lạ nhặt hết bị từ chối");
    const auto late = loot::plan_pick_all(box, kOwner, ids::Tick{1000}, bench.world.catalog, nothing);
    context.expect(!late && late.error() == item::Error::kBoxExpired, "nhặt hết khi đã hết hạn");
}

void box_capacity_guard(Context& context) {
    Bench bench;
    DropBox box;
    for (std::size_t i = 0; i < loot::kBoxCapacity; ++i) context.expect(box.put(bench.make(kPotion)), "đặt vào ô trống");
    context.expect(!box.put(bench.make(kPotion)) && box.item_count() == loot::kBoxCapacity, "hộp đầy từ chối món thứ 11");
    context.expect(box.item(loot::kBoxCapacity) == nullptr && box.item(static_cast<std::size_t>(-1)) == nullptr, "chỉ số ngoài hộp");
    DropBox untouched;
    context.expect(untouched.expired(ids::Tick{0}), "hộp mặc định đã hết hạn, không ai nhặt nhầm hộp chưa dựng");
}

// Vòng trọn: quái chết -> hộp của người chia -> nhặt vào túi -> serial không trùng, túi giữ đúng món.
void kill_to_bag(Context& context) {
    LootBench loot_bench(packs_table({PackSpec{.id = 1, .value = 50, .items = {{kPotion, -1}}},
                             PackSpec{.id = 2, .value = 50, .items = {{kSword, -1}}},
                             PackSpec{.id = 3, .value = 50, .items = {{kHerb, -1}}}}),
        monsters_table({MonsterSpec{.id = kTestMonster, .value = 50, .type = 1, .packs = {1, 2, 3}}}));
    const loot::Roller roller(loot_bench.tables, loot_bench.factory);
    const std::array<loot::Claimant, 2> claimants{claimant_of(7), claimant_of(8)};
    auto outcome = roller.roll_kill(kill_of(kTestMonster, 10, 100), claimants, loot_bench.dice, loot_bench.serials);
    context.expect(outcome.has_value() && outcome->boxes.size() == 2, "hai người, hai hộp");
    if (!outcome) return;

    Bench bag_bench;
    loot::Delivered& mine = outcome->boxes.front();
    context.expect(mine.owner == kOwner && mine.box.item_count() == 3, "hộp của người 7 có ba món (ba gói chắc chắn rơi)");
    item::Planner planner = bag_bench.planner();
    const auto not_mine = loot::plan_pick_all(outcome->boxes.back().box, kOwner, ids::Tick{101}, loot_bench.world.catalog, planner);
    context.expect(!not_mine && not_mine.error() == item::Error::kNotOwner, "hộp của người khác không nhặt được");
    const auto tickets = loot::plan_pick_all(mine.box, kOwner, ids::Tick{101}, loot_bench.world.catalog, planner);
    context.expect(tickets && tickets->size() == 3, "nhặt đủ ba món");
    if (!tickets) return;
    context.expect(bag_bench.commit(std::move(planner)), "áp kế hoạch");
    for (const PickTicket& ticket : *tickets) context.expect(loot::take(mine.box, ticket).has_value(), "lấy khỏi hộp");
    context.expect(mine.box.empty(), "hộp rỗng sau khi nhặt hết");
    context.expect(bag_bench.inventory.count_of(item::TemplateId{kSword}) == 1 && bag_bench.inventory.count_of(item::TemplateId{kHerb}) == 1,
        "đồ nằm trong túi đúng nơi mặc định");
}

constexpr std::array kCases{
    Case{"rights_and_expiry", rights_and_expiry},
    Case{"two_step_pick", two_step_pick},
    Case{"pick_binds_on_pickup", pick_binds_on_pickup},
    Case{"pick_all_partial", pick_all_partial},
    Case{"box_capacity_guard", box_capacity_guard},
    Case{"kill_to_bag", kill_to_bag},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
