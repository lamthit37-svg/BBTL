// Mua bán ở cửa hàng NPC: giá, cổng cấp và loại, nguyên tử (lỗi không để lại gì), danh sách mua lại, sửa, thu hồi phế phẩm, và
// một ca bảo toàn tiền/vật phẩm trên chuỗi thao tác ngẫu nhiên đối chiếu với mô hình độc lập.
#include "shop_support.hpp"

#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/price.hpp"
#include "item/types.hpp"
#include "shop/npc_shop.hpp"
#include "shop/tables.hpp"
#include "shop/trade.hpp"
#include "shop/types.hpp"
#include "test.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using shop::NpcShop;
using shop::SoldList;

constexpr std::uint32_t kGeneral = 1;
constexpr std::uint32_t kIngotShop = 2;
constexpr std::uint32_t kWeaponShop = 3;
constexpr std::uint32_t kDoubleShop = 4;
constexpr std::uint32_t kClosedShop = 5;
constexpr std::uint32_t kLowShop = 6;

// Ngày giá trong thế giới thử: thuốc 100, thảo dược 375, kiếm 1000 (cấp 10), nhẫn 1000.
std::string standard_tables() {
    ShopSpec general{.id = kGeneral};
    general.goods = {
        GoodsSpec{.item = kPotion, .group = "5", .stock = "3"},     // 0: 500 / nhóm, tồn 3
        GoodsSpec{.item = kHerb, .group = "1", .stock = "-1"},      // 1: 375
        GoodsSpec{.item = kSword, .group = "1", .stock = "-1"},     // 2: 1000
        GoodsSpec{.item = kWhiteRing, .group = "1", .stock = "-1"}, // 3: 1000
        GoodsSpec{.item = kPotion, .group = "15", .stock = "-1"},   // 4: 1500 / nhóm, 15 cái mỗi nhóm (chồng 20)
    };
    ShopSpec ingot{.id = kIngotShop, .currency = 5};
    ingot.goods = {GoodsSpec{.item = kPotion, .group = "5", .stock = "-1", .price = "30"},
        GoodsSpec{.item = kHerb, .group = "1", .stock = "-1", .price = "12", .discount = "50"}};
    ShopSpec weapon{.id = kWeaponShop, .repair_level = 15, .buy_level = 15, .repair_type = 4, .buy_kind = 4};
    weapon.goods = {GoodsSpec{.item = kSword}};
    ShopSpec twice{.id = kDoubleShop, .can_buy_back = 0, .scale = "2"};
    twice.goods = {GoodsSpec{.item = kPotion, .group = "1"}};
    ShopSpec closed{.id = kClosedShop, .repair_type = 6, .buy_kind = 8};
    ShopSpec low{.id = kLowShop, .repair_level = 5, .buy_level = 5};
    return shops_table({general, ingot, weapon, twice, closed, low});
}

item::Plan plan_of(const Planner& planner) {
    Planner copy = planner;
    return std::move(copy).finish();
}

template <typename T>
bool refused(const std::expected<T, Error>& result, Error expected) {
    return !result.has_value() && result.error() == expected;
}

// Đặt thẳng một món vào ô túi, với độ bền cho trước.
Instance with_durability(ShopBench& bench, std::uint32_t id, std::uint16_t durability) {
    Instance made = bench.base.make(id);
    made.durability = durability;
    return made;
}

shop::BuyRequest line_of(std::size_t line, std::uint16_t groups = 1) { return shop::BuyRequest{.line = line, .groups = groups}; }

// ----- mua -----------------------------------------------------------------------------------------------------------------

void buy_with_gold_and_ingot(Context& context) {
    ShopBench bench(standard_tables());
    NpcShop store = bench.open(kGeneral);
    bench.fund(Currency::kGold, 10000);
    context.expect(bench.buy(store, 0).has_value(), "mua một nhóm thuốc");
    context.expect(bench.money() == 9500 && bench.base.inventory.count_of(TemplateId{kPotion}) == 5, "trừ 500 vàng, được 5 thuốc");
    context.expect(store.lines()[0].stock == 2, "tồn kho còn hai nhóm");
    context.expect(bench.buy(store, 1).has_value() && bench.money() == 9125, "thảo dược 375");
    context.expect(bench.base.inventory.count_of(TemplateId{kHerb}) == 1 && bench.base.inventory.get(material(0)) != nullptr, "thảo dược vào túi nguyên liệu");

    NpcShop ingot = bench.open(kIngotShop);
    bench.fund(Currency::kIngot, 100);
    context.expect(bench.buy(ingot, 0).has_value() && bench.money(Currency::kIngot) == 70, "nguyên bảo: giá ghi sẵn 30 cho cả nhóm");
    context.expect(bench.buy(ingot, 1).has_value() && bench.money(Currency::kIngot) == 64, "chiết khấu 50%: 12 thành 6");
    context.expect(bench.money() == 9125, "mua bằng nguyên bảo không đụng vàng");
}

void buy_failures_leave_nothing(Context& context) {
    ShopBench bench(standard_tables());
    NpcShop store = bench.open(kGeneral);
    bench.fund(Currency::kGold, 600);
    const auto before = fingerprint(bench.base.inventory);
    const std::vector<shop::Line> lines(store.lines().begin(), store.lines().end());
    const std::uint64_t revision = store.revision();
    const auto buy = [&bench, &store](const shop::BuyRequest& request, Planner& planner) {
        return shop::plan_buy(store, request, bench.base.factory, bench.base.dice, bench.base.serials, bench.now, planner);
    };
    Planner planner = bench.base.planner();
    context.expect(refused(buy(line_of(2), planner), Error::kInsufficientFunds), "1000 vàng mà có 600");
    context.expect(refused(buy(line_of(0, 0), planner), Error::kBadCount), "0 nhóm");
    context.expect(refused(buy(line_of(0, shop::kMaxBuyGroups + 1), planner), Error::kBadCount), "quá trần số nhóm");
    context.expect(refused(buy(line_of(99), planner), Error::kNoSuchEntry), "dòng ngoài miền");
    context.expect(refused(buy(line_of(0, 4), planner), Error::kSoldOut), "bốn nhóm khi tồn ba");
    context.expect(plan_of(planner).empty(), "kế hoạch rỗng sau mọi lỗi");
    context.expect(fingerprint(bench.base.inventory) == before && store.revision() == revision
            && std::ranges::equal(store.lines(), lines),
        "kho đồ và cửa hàng không đổi");

    // Lỗi ở bước sau (hết chỗ) sau khi các bước trước đã dựng: planner phải về đúng trạng thái trước lời gọi.
    for (std::uint16_t slot = 0; slot < 19; ++slot) bench.base.put(bag(slot), bench.base.make(kSword));
    bench.fund(Currency::kGold, 100000);
    Planner busy = bench.base.planner();
    context.expect(shop::plan_buy(store, line_of(2, 1), bench.base.factory, bench.base.dice, bench.base.serials, bench.now, busy).has_value(),
        "một kiếm vào ô cuối");
    const item::Plan midway = plan_of(busy);
    context.expect(refused(buy(line_of(2, 3), busy), Error::kBagFull), "ba kiếm nữa: hết chỗ");
    context.expect(plan_of(busy) == midway, "planner giữ nguyên như trước lời gọi hỏng (mua dở không để lại tiền đã trừ)");
    context.expect(busy.balance(item::account_of(Currency::kGold)) == 99000, "chỉ trừ tiền của lượt thành công");
}

void buy_groups_and_stacks(Context& context) {
    ShopBench bench(standard_tables());
    NpcShop store = bench.open(kGeneral);
    bench.fund(Currency::kGold, 100000);
    bench.base.put(bag(0), bench.base.make(kPotion, 10));
    const std::uint64_t cursor = bench.base.serials.cursor();
    context.expect(bench.buy(store, 4, 3).has_value(), "ba nhóm 15 thuốc");
    context.expect(bench.base.serials.cursor() - cursor == 3, "sinh theo chồng đầy (20, 20, 5): ba serial, không phải 45");
    // 10 sẵn có + 45 = 55 thuốc; chồng tối đa 20: lấp ô cũ rồi chia: 20, 20, 15.
    const auto count_at = [&bench](std::uint16_t slot) {
        const Instance* held = bench.base.inventory.get(bag(slot));
        return held == nullptr ? 0 : held->count;
    };
    context.expect(count_at(0) == 20 && count_at(1) == 20 && count_at(2) == 15 && count_at(3) == 0, "chồng 20, 20, 15");
    context.expect(bench.money() == 100000 - 4500, "trả ba nhóm x 1500");
    context.expect(bench.buy(store, 2, 3).has_value(), "ba kiếm một lượt");
    std::set<std::uint64_t> serials;
    std::size_t swords = 0;
    for (const auto& slot : bench.base.inventory.view(Place::kBaseBag)) {
        if (slot && slot->tmpl.value() == kSword) {
            ++swords;
            serials.insert(slot->serial.value());
        }
    }
    context.expect(swords == 3 && serials.size() == 3, "ba món riêng biệt, ba serial khác nhau");
    context.expect(bench.buy(store, 1, shop::kMaxBuyGroups).has_value() && bench.base.inventory.count_of(TemplateId{kHerb}) == shop::kMaxBuyGroups,
        "đúng trần số nhóm một lượt được mua");
}

void buy_commit_order(Context& context) {
    ShopBench bench(standard_tables());
    NpcShop store = bench.open(kGeneral);
    bench.fund(Currency::kGold, 100000);
    Bench other;  // người mua thứ hai: kho đồ riêng
    if (!other.inventory.restore_balance(item::account_of(Currency::kGold), 100000)) std::abort();

    // Hai người cùng dựng vé trên tồn kho 3 nhóm, mỗi người lấy 2: chỉ người commit trước hợp lệ.
    Planner mine = bench.base.planner();
    Planner theirs = other.planner();
    const auto first = shop::plan_buy(store, line_of(0, 2), bench.base.factory, bench.base.dice, bench.base.serials, bench.now, mine);
    const auto second = shop::plan_buy(store, line_of(0, 2), other.factory, other.dice, other.serials, bench.now, theirs);
    context.expect(first.has_value() && second.has_value(), "cả hai dựng được trên cùng revision");
    if (!first || !second) return;
    context.expect(bench.base.inventory.apply(std::move(mine).finish()).has_value() && store.commit(*first).has_value(), "người thứ nhất áp dụng và commit");
    context.expect(store.lines()[0].stock == 1, "còn một nhóm");
    const auto late = store.commit(*second);
    context.expect(refused(late, Error::kStalePlan), "vé thứ hai cũ: kStalePlan");
    context.expect(store.lines()[0].stock == 1, "tồn kho không bị trừ thêm");

    // Làm đúng quy trình (dựng, áp dụng, commit rồi mới tới người sau): người sau thấy tồn thật và bị từ chối.
    Planner retry = other.planner();
    const auto again = shop::plan_buy(store, line_of(0, 2), other.factory, other.dice, other.serials, bench.now, retry);
    context.expect(refused(again, Error::kSoldOut), "người thứ hai dựng lại sau commit: hết hàng");
}

// ----- bán và mua lại -------------------------------------------------------------------------------------------------------

void sell_prices_and_gates(Context& context) {
    ShopBench bench(standard_tables());
    const shop::ShopDef& general = *bench.tables.find(shop::ShopId{kGeneral});
    const item::Catalog& catalog = bench.base.world.catalog;
    const item::PriceRules rules{};
    bench.base.put(bag(0), bench.base.make(kSword));
    bench.base.put(bag(1), bench.base.make(kPotion, 7));
    bench.base.put(bag(2), bench.base.make(kNoSell));
    bench.base.put(bag(3), bench.base.make(kSectSword));
    bench.base.put(material(0), bench.base.make(kHerb, 4));

    Planner planner = bench.base.planner();
    const auto sword = shop::plan_sell(general, catalog, rules, bag(0), planner);
    context.expect(sword && sword->price == 250 && sword->item.tmpl.value() == kSword && sword->remember, "kiếm 1000 x 25% = 250");
    const auto potions = shop::plan_sell(general, catalog, rules, bag(1), planner);
    context.expect(potions && potions->price == 175 && potions->item.count == 7, "chồng 7 thuốc: 100 x 7 x 25% = 175, bán cả chồng");
    const auto herbs = shop::plan_sell(general, catalog, rules, material(0), planner);
    context.expect(herbs && herbs->price == 375, "thảo dược ở túi nguyên liệu bán được: 375 x 4 x 25%");
    context.expect(planner.balance(item::account_of(Currency::kGold)) == 250 + 175 + 375, "ví cộng dồn trong kế hoạch");
    context.expect(planner.get(bag(0)) == nullptr && planner.get(bag(1)) == nullptr && planner.get(material(0)) == nullptr, "ba ô trống trong kế hoạch");
    context.expect(bench.base.inventory.get(bag(0)) != nullptr, "Inventory chưa đổi trước apply");

    Planner fresh = bench.base.planner();
    context.expect(refused(shop::plan_sell(general, catalog, rules, bag(2), fresh), Error::kForbidden), "đồ cấm bán");
    context.expect(refused(shop::plan_sell(general, catalog, rules, bag(9), fresh), Error::kSlotEmpty), "ô trống");
    context.expect(refused(shop::plan_sell(general, catalog, rules, bag(500), fresh), Error::kNoSuchSlot), "ô ngoài biên");
    context.expect(refused(shop::plan_sell(general, catalog, rules, worn(0), fresh), Error::kWrongPlace), "ô trang bị không bán qua đường này");
    context.expect(refused(shop::plan_sell(general, catalog, rules, SlotRef{.place = Place::kBank, .index = 0}, fresh), Error::kWrongPlace), "kho không bán");
    context.expect(plan_of(fresh).empty(), "mọi lỗi để kế hoạch rỗng");

    // Mỗi kiểm tra cổng dùng một planner mới: bán thành công làm ô trống trong kế hoạch.
    const auto sell = [&bench, &catalog, &rules](const shop::ShopDef& shop, SlotRef from) {
        Planner own = bench.base.planner();
        return shop::plan_sell(shop, catalog, rules, from, own);
    };
    const auto& low = *bench.tables.find(shop::ShopId{kLowShop});
    context.expect(refused(sell(low, bag(0)), Error::kShopRefuses), "kiếm cấp 10 vượt buy_level 5");
    context.expect(sell(low, bag(1)).has_value(), "thuốc cấp 1 nằm trong buy_level 5");
    const auto& closed = *bench.tables.find(shop::ShopId{kClosedShop});
    context.expect(refused(sell(closed, bag(0)), Error::kShopRefuses), "cửa hàng không thu mua");
    const auto& weapon = *bench.tables.find(shop::ShopId{kWeaponShop});
    context.expect(refused(sell(weapon, bag(1)), Error::kShopRefuses), "cửa hàng vũ khí không nhận thuốc");
    context.expect(refused(sell(weapon, bag(3)), Error::kShopRefuses), "kiếm cấp 20 vượt buy_level 15 của cửa hàng vũ khí");
    context.expect(sell(weapon, bag(0)).has_value(), "kiếm cấp 10 vào cửa hàng vũ khí");
    const auto& twice = *bench.tables.find(shop::ShopId{kDoubleShop});
    const auto pricey = sell(twice, bag(0));
    context.expect(pricey && pricey->price == 500 && !pricey->remember, "hệ số cửa hàng 2: 500, và không ghi mua lại");
}

void sell_details(Context& context) {
    ShopBench bench(standard_tables());
    const shop::ShopDef& general = *bench.tables.find(shop::ShopId{kGeneral});
    const item::Catalog& catalog = bench.base.world.catalog;
    const item::PriceRules rules{};
    Instance blue = bench.base.make(kBlueRing);
    blue.identified = false;
    bench.base.put(bag(0), blue);
    bench.base.put(bag(1), with_durability(bench, kSword, 50));
    Planner planner = bench.base.planner();
    context.expect(shop::plan_sell(general, catalog, rules, bag(0), planner).value_or(shop::SellTicket{}).price == 100, "đồ lam chưa giám định: hệ số 10%");
    context.expect(shop::plan_sell(general, catalog, rules, bag(1), planner).value_or(shop::SellTicket{}).price == 125, "độ bền một nửa: giá một nửa");

    // Ô khoá.
    if (!bench.base.inventory.set_lock(bag(0), true)) std::abort();
    Planner locked = bench.base.planner();
    context.expect(refused(shop::plan_sell(general, catalog, rules, bag(0), locked), Error::kLocked), "ô đang khoá không bán được");
    context.expect(plan_of(locked).empty(), "ô khoá: kế hoạch rỗng");

    // Ví đầy: bán không được, và kho đồ không đổi.
    bench.fund(Currency::kGold, bench.base.inventory.wallet().cap(item::account_of(Currency::kGold)) - 10);
    const auto before = fingerprint(bench.base.inventory);
    Planner full = bench.base.planner();
    context.expect(refused(shop::plan_sell(general, catalog, rules, bag(1), full), Error::kOverCap), "tiền nhận vượt trần ví");
    context.expect(plan_of(full).empty() && fingerprint(bench.base.inventory) == before, "ví đầy: không bán gì, đồ vẫn ở túi");
}

void sell_and_buy_back(Context& context) {
    ShopBench bench(standard_tables());
    const shop::ShopDef& general = *bench.tables.find(shop::ShopId{kGeneral});
    const item::Catalog& catalog = bench.base.world.catalog;
    const item::PriceRules rules{};
    SoldList list;
    const Instance sword = bench.base.make(kSword);
    const Instance potions = bench.base.make(kPotion, 6);
    bench.base.put(bag(0), sword);
    bench.base.put(bag(1), potions);

    for (const std::uint16_t slot : {std::uint16_t{0}, std::uint16_t{1}}) {
        Planner planner = bench.base.planner();
        const auto ticket = shop::plan_sell(general, catalog, rules, bag(slot), planner);
        context.expect(ticket.has_value() && bench.base.inventory.apply(std::move(planner).finish()).has_value(), "bán và áp dụng");
        if (ticket) list.remember(*ticket);
    }
    context.expect(list.size() == 2 && list.top() != nullptr && list.top()->item.serial == potions.serial, "món vừa bán nằm trên cùng");
    context.expect(bench.money() == 250 + 150, "tiền nhận: 250 + 150");

    // Mua lại món trên cùng: đúng giá đã nhận, đúng serial cũ, rồi tới món bán trước nó.
    Planner back = bench.base.planner();
    const auto ticket = shop::plan_buy_back(list, back);
    context.expect(ticket && ticket->serial == potions.serial && back.balance(item::account_of(Currency::kGold)) == 250, "trả lại 150");
    if (!ticket) return;
    context.expect(bench.base.inventory.apply(std::move(back).finish()).has_value() && list.take(*ticket).has_value(), "áp dụng và lấy khỏi danh sách");
    const Instance* returned = bench.base.inventory.get(bag(0));
    context.expect(returned != nullptr && *returned == potions, "thuốc về túi nguyên vẹn (cùng serial, cùng nội dung)");
    context.expect(list.top() != nullptr && list.top()->item.serial == sword.serial, "kế tiếp là thanh kiếm");
    const auto stale = list.take(shop::BuyBackTicket{.serial = potions.serial});
    context.expect(refused(stale, Error::kStalePlan), "vé của món đã lấy ra: kStalePlan");

    // Thiếu tiền và hết chỗ.
    if (!bench.base.inventory.restore_balance(item::account_of(Currency::kGold), 100)) std::abort();
    Planner poor = bench.base.planner();
    context.expect(refused(shop::plan_buy_back(list, poor), Error::kInsufficientFunds), "thiếu tiền mua lại");
    bench.fund(Currency::kGold, 100000);
    for (std::uint16_t slot = 1; slot < 20; ++slot) bench.base.put(bag(slot), bench.base.make(kPotion));
    Planner packed = bench.base.planner();
    context.expect(refused(shop::plan_buy_back(list, packed), Error::kBagFull) && plan_of(packed).empty(), "túi đầy: không mua lại được, không trừ tiền");
    list.clear();
    Planner empty = bench.base.planner();
    context.expect(refused(shop::plan_buy_back(list, empty), Error::kNoSuchEntry), "danh sách rỗng");
}

void buy_back_ring_capacity(Context& context) {
    ShopBench bench(standard_tables());
    const shop::ShopDef& general = *bench.tables.find(shop::ShopId{kGeneral});
    const shop::ShopDef& no_back = *bench.tables.find(shop::ShopId{kDoubleShop});
    const item::Catalog& catalog = bench.base.world.catalog;
    const item::PriceRules rules{};
    SoldList list;
    std::vector<item::Serial> serials;
    for (std::uint16_t slot = 0; slot < 6; ++slot) {
        const Instance made = bench.base.make(kPotion, static_cast<std::uint16_t>(slot + 1));
        serials.push_back(made.serial);
        bench.base.put(bag(slot), made);
    }
    for (std::uint16_t slot = 0; slot < 6; ++slot) {
        Planner planner = bench.base.planner();
        const auto ticket = shop::plan_sell(general, catalog, rules, bag(slot), planner);
        if (!ticket || !bench.base.inventory.apply(std::move(planner).finish())) {
            context.expect(false, "bán được");
            return;
        }
        list.remember(*ticket);
    }
    context.expect(list.size() == shop::kSoldCapacity, "danh sách chỉ giữ 5 món");
    // Món thứ sáu đè món cũ nhất: lấy ra theo thứ tự mới nhất trước, và món bán đầu tiên đã mất.
    std::vector<item::Serial> back;
    while (list.top() != nullptr) {
        back.push_back(list.top()->item.serial);
        if (!list.take(shop::BuyBackTicket{.serial = list.top()->item.serial})) break;
    }
    const std::vector<item::Serial> expected{serials[5], serials[4], serials[3], serials[2], serials[1]};
    context.expect(back == expected, "ra theo thứ tự mới nhất trước; món đầu tiên bị đè");

    // Cửa hàng không cho mua lại: có tiền, không có danh sách.
    bench.base.put(bag(7), bench.base.make(kPotion, 2));
    Planner second = bench.base.planner();
    const auto ticket = shop::plan_sell(no_back, catalog, rules, bag(7), second);
    context.expect(ticket && !ticket->remember, "ticket không ghi mua lại");
    if (ticket) list.remember(*ticket);
    context.expect(list.size() == 0, "không có gì được ghi");
}

// ----- sửa --------------------------------------------------------------------------------------------------------------------

void repair_single(Context& context) {
    ShopBench bench(standard_tables());
    const shop::ShopDef& general = *bench.tables.find(shop::ShopId{kGeneral});
    const item::Catalog& catalog = bench.base.world.catalog;
    bench.base.put(worn(0), with_durability(bench, kSword, 50));
    bench.base.put(bag(0), with_durability(bench, kWhiteRing, 100));
    bench.base.put(bag(1), bench.base.make(kPotion));
    bench.fund(Currency::kGold, 1000);

    Planner planner = bench.base.planner();
    context.expect(refused(shop::plan_repair(general, catalog, bag(0), planner), Error::kNoChange), "đầy độ bền: kNoChange");
    context.expect(refused(shop::plan_repair(general, catalog, bag(1), planner), Error::kNoDurability), "thuốc không hao mòn");
    context.expect(refused(shop::plan_repair(general, catalog, bag(9), planner), Error::kSlotEmpty), "ô trống");
    context.expect(refused(shop::plan_repair(general, catalog, bag(500), planner), Error::kNoSuchSlot), "ô ngoài biên");
    context.expect(refused(shop::plan_repair(general, catalog, SlotRef{.place = Place::kBank, .index = 0}, planner), Error::kWrongPlace), "kho");
    const shop::ShopDef& low = *bench.tables.find(shop::ShopId{kLowShop});
    context.expect(refused(shop::plan_repair(low, catalog, worn(0), planner), Error::kShopRefuses), "kiếm cấp 10 vượt repair_level 5");
    const shop::ShopDef& closed = *bench.tables.find(shop::ShopId{kClosedShop});
    context.expect(refused(shop::plan_repair(closed, catalog, worn(0), planner), Error::kShopRefuses), "cửa hàng không sửa");
    context.expect(plan_of(planner).empty(), "lỗi để kế hoạch rỗng");

    const auto report = shop::plan_repair(general, catalog, worn(0), planner);
    context.expect(report && report->repaired == 1 && report->spent == 500 && !report->short_of_money, "sửa nửa độ bền kiếm 1000: 500");
    context.expect(bench.base.inventory.apply(std::move(planner).finish()).has_value(), "áp dụng");
    context.expect(bench.money() == 500 && bench.base.inventory.get(worn(0))->durability == 100, "đã đầy độ bền, còn 500 vàng");

    bench.base.put(worn(0), with_durability(bench, kSword, 0));
    Planner poor = bench.base.planner();
    context.expect(refused(shop::plan_repair(general, catalog, worn(0), poor), Error::kInsufficientFunds) && plan_of(poor).empty(), "sửa hỏng hẳn tốn 1000, chỉ có 500");

    // Cửa hàng chỉ sửa vũ khí không sửa nhẫn; cửa hàng loại phòng cụ không sửa kiếm.
    bench.base.put(bag(2), with_durability(bench, kWhiteRing, 10));
    const shop::ShopDef& weapon = *bench.tables.find(shop::ShopId{kWeaponShop});
    bench.fund(Currency::kGold, 5000);
    Planner gated = bench.base.planner();
    context.expect(refused(shop::plan_repair(weapon, catalog, bag(2), gated), Error::kShopRefuses), "nhẫn: cửa hàng vũ khí từ chối");
    context.expect(shop::plan_repair(weapon, catalog, worn(0), gated).has_value(), "kiếm: cửa hàng vũ khí nhận");
}

void repair_all_stops_at_first_unaffordable(Context& context) {
    ShopBench bench(standard_tables());
    const shop::ShopDef& general = *bench.tables.find(shop::ShopId{kGeneral});
    const item::Catalog& catalog = bench.base.world.catalog;
    // Điểm 0 kiếm hao một nửa (500), điểm 6 nhẫn hao 20% (200), điểm 12 bùa hỏng hẳn (1000).
    bench.base.put(worn(0), with_durability(bench, kSword, 50));
    bench.base.put(worn(6), with_durability(bench, kWhiteRing, 80));
    bench.base.put(worn(12), with_durability(bench, kCharm, 0));
    const auto run = [&](std::int64_t gold) {
        if (!bench.base.inventory.restore_balance(item::account_of(Currency::kGold), gold)) std::abort();
        Planner planner = bench.base.planner();
        auto report = shop::plan_repair_all(general, catalog, planner);
        return std::pair{std::move(report), std::move(planner)};
    };

    auto [rich, rich_plan] = run(5000);
    context.expect(rich && rich->repaired == 3 && rich->spent == 1700 && !rich->short_of_money, "đủ tiền: sửa cả ba, 1700");
    auto [mid, mid_plan] = run(700);
    context.expect(mid && mid->repaired == 2 && mid->spent == 700 && mid->short_of_money, "700: kiếm và nhẫn, dừng ở bùa");
    context.expect(mid_plan.get(worn(0))->durability == 100 && mid_plan.get(worn(6))->durability == 100 && mid_plan.get(worn(12))->durability == 0, "bùa chưa sửa");
    auto [one, one_plan] = run(600);
    context.expect(one && one->repaired == 1 && one->spent == 500 && one->short_of_money, "600: chỉ kiếm (nhẫn 200 > 100 còn lại)");
    auto [none, none_plan] = run(100);
    context.expect(refused(none, Error::kInsufficientFunds) && plan_of(none_plan).empty(), "100: không sửa nổi món nào, kế hoạch rỗng");

    // Không nhảy sang món rẻ hơn: kiếm hỏng hẳn (1000) đứng trước nhẫn chỉ hao 1 điểm (10).
    bench.base.put(worn(0), with_durability(bench, kSword, 0));
    bench.base.put(worn(6), with_durability(bench, kWhiteRing, 99));
    bench.base.put(worn(12), with_durability(bench, kCharm, 100));
    auto [skip, skip_plan] = run(500);
    context.expect(refused(skip, Error::kInsufficientFunds), "500 < 1000 của kiếm: dừng ngay, không sửa nhẫn rẻ ở sau");

    // Không có gì cần sửa.
    bench.base.put(worn(0), with_durability(bench, kSword, 100));
    bench.base.put(worn(6), with_durability(bench, kWhiteRing, 100));
    auto [fine, fine_plan] = run(5000);
    context.expect(refused(fine, Error::kNoChange) && plan_of(fine_plan).empty(), "đầy hết: kNoChange");

    // Phạm vi: cửa hàng vũ khí chỉ sửa kiếm (cấp 10 trong repair_level 15); bùa và nhẫn bỏ qua.
    bench.base.put(worn(0), with_durability(bench, kSword, 50));
    bench.base.put(worn(6), with_durability(bench, kWhiteRing, 0));
    const shop::ShopDef& weapon = *bench.tables.find(shop::ShopId{kWeaponShop});
    Planner gated = bench.base.planner();
    const auto only = shop::plan_repair_all(weapon, catalog, gated);
    context.expect(only && only->repaired == 1 && only->spent == 500, "cửa hàng vũ khí chỉ sửa kiếm");
}

// ----- phế phẩm ---------------------------------------------------------------------------------------------------------------

void recycle_junk(Context& context) {
    ShopBench bench(standard_tables(), {}, {}, junk_table({{kHerb, 25000}, {kPotion, 500}}));
    bench.base.put(material(0), bench.base.make(kHerb, 4));
    bench.base.put(bag(0), bench.base.make(kPotion, 7));
    bench.base.put(bag(1), bench.base.make(kSword));
    Planner planner = bench.base.planner();
    const auto herbs = shop::plan_recycle(bench.tables, material(0), 3, planner);
    context.expect(herbs && herbs->gold == 75000 && herbs->count == 3 && herbs->item.value() == kHerb, "3 thảo dược x 25000");
    context.expect(planner.get(material(0)) != nullptr && planner.get(material(0))->count == 1, "còn 1");
    const auto potions = shop::plan_recycle(bench.tables, bag(0), 7, planner);
    context.expect(potions && potions->gold == 3500 && planner.get(bag(0)) == nullptr, "cả chồng thuốc");
    const item::Plan before = plan_of(planner);
    context.expect(refused(shop::plan_recycle(bench.tables, bag(1), 1, planner), Error::kShopRefuses), "kiếm không phải phế phẩm");
    context.expect(refused(shop::plan_recycle(bench.tables, material(0), 2, planner), Error::kBadCount), "quá số có");
    context.expect(refused(shop::plan_recycle(bench.tables, material(0), 0, planner), Error::kBadCount), "số 0");
    context.expect(refused(shop::plan_recycle(bench.tables, bag(500), 1, planner), Error::kNoSuchSlot), "ô ngoài biên");
    context.expect(refused(shop::plan_recycle(bench.tables, bag(5), 1, planner), Error::kSlotEmpty), "ô trống");
    context.expect(refused(shop::plan_recycle(bench.tables, worn(0), 1, planner), Error::kWrongPlace), "ô trang bị");
    context.expect(plan_of(planner) == before, "mọi lỗi giữ nguyên kế hoạch");
    context.expect(bench.base.inventory.apply(std::move(planner).finish()).has_value() && bench.money() == 78500, "áp dụng: 78500 vàng");

    // Vượt trần ví: không bán được, đồ ở lại.
    bench.fund(Currency::kGold, bench.base.inventory.wallet().cap(item::account_of(Currency::kGold)) - 10);
    bench.base.put(material(1), bench.base.make(kHerb, 1));
    Planner over = bench.base.planner();
    context.expect(refused(shop::plan_recycle(bench.tables, material(1), 1, over), Error::kOverCap) && plan_of(over).empty(), "ví đầy");
}

// ----- bảo toàn ------------------------------------------------------------------------------------------------------------------

constexpr std::array<std::uint16_t, 3> kWornPoints{0, 6, 12};
constexpr std::array<std::uint32_t, 3> kGear{kSword, kWhiteRing, kCharm};

// Chuỗi thao tác ngẫu nhiên; sau mỗi bước so ví và số lượng từng loại vật phẩm với mô hình độc lập chỉ dựng từ giấy hẹn và
// kết quả của các hàm giá. Thao tác bị từ chối phải để kho đồ và cửa hàng nguyên từng byte.
void conservation_fuzz(Context& context) {
    ShopBench bench(standard_tables(), {}, {}, junk_table({{kHerb, 3000}}));
    NpcShop store = bench.open(kGeneral);
    const shop::ShopDef& def = store.def();
    const item::Catalog& catalog = bench.base.world.catalog;
    const item::PriceRules rules{};
    SoldList sold;
    dice::Dice rng(20261014);
    constexpr std::int64_t kStart = 200000;
    bench.fund(Currency::kGold, kStart);
    std::int64_t gold = kStart;
    std::map<std::uint32_t, std::int64_t> items;  // mô hình số lượng
    std::size_t applied = 0;
    std::size_t refused_count = 0;

    for (int step = 0; step < 3000; ++step) {
        // Thỉnh thoảng người chơi mặc thêm đồ từ nguồn ngoài cửa hàng (nhặt, thưởng): có gì để sửa.
        if (rng.below(12) == 0) {
            const std::size_t which = rng.below(kWornPoints.size());
            const SlotRef at = worn(kWornPoints.at(which));
            if (bench.base.inventory.get(at) == nullptr) {
                Instance gear = bench.base.make(kGear.at(which));
                gear.durability = static_cast<std::uint16_t>(rng.below(101));
                bench.base.put(at, gear);
                ++items[kGear.at(which)];
            }
        }
        const auto before = fingerprint(bench.base.inventory);
        const std::uint64_t revision = store.revision();
        Planner planner = bench.base.planner();
        const std::uint64_t pick = rng.below(7);
        bool ok = false;
        std::int64_t gold_delta = 0;
        std::map<std::uint32_t, std::int64_t> item_delta;
        std::optional<shop::BuyTicket> bought;
        std::optional<shop::BuyBackTicket> back;
        std::optional<shop::SellTicket> sale;

        if (pick <= 1) {
            const std::size_t line = rng.below(store.lines().size());
            const auto groups = static_cast<std::uint16_t>(1 + rng.below(3));
            const auto ticket = shop::plan_buy(store, line_of(line, groups), bench.base.factory, bench.base.dice, bench.base.serials, bench.now, planner);
            if (ticket) {
                const shop::Line& chosen = store.lines()[line];
                const auto price = shop::price_of(def, chosen.goods, catalog);
                ok = price.has_value();
                gold_delta = -(price.value_or(0) * groups);
                item_delta[chosen.goods.item.value()] += std::int64_t{chosen.goods.group} * groups;
                bought = *ticket;
            }
        } else if (pick == 2) {
            const auto slot = static_cast<std::uint16_t>(rng.below(24));
            const SlotRef from = (slot % 3 == 0) ? material(static_cast<std::uint16_t>(slot / 3)) : bag(slot);
            const Instance* held = bench.base.inventory.get(from);
            const std::uint32_t id = held == nullptr ? 0 : held->tmpl.value();
            const std::uint16_t count = held == nullptr ? 0 : held->count;
            const auto ticket = shop::plan_sell(def, catalog, rules, from, planner);
            if (ticket) {
                ok = true;
                gold_delta = ticket->price;
                item_delta[id] -= count;
                sale = *ticket;
            }
        } else if (pick == 3) {
            const auto ticket = shop::plan_buy_back(sold, planner);
            if (ticket && sold.top() != nullptr) {
                ok = true;
                gold_delta = -sold.top()->price;
                item_delta[sold.top()->item.tmpl.value()] += sold.top()->item.count;
                back = *ticket;
            }
        } else if (pick == 4) {
            const auto report = shop::plan_repair_all(def, catalog, planner);
            if (report) {
                ok = true;
                gold_delta = -report->spent;
            }
        } else if (pick == 5) {
            const auto slot = static_cast<std::uint16_t>(rng.below(8));
            const Instance* held = bench.base.inventory.get(material(slot));
            const std::uint16_t count = held == nullptr ? 0 : held->count;
            const auto receipt = shop::plan_recycle(bench.tables, material(slot), count, planner);
            if (receipt) {
                ok = true;
                gold_delta = receipt->gold;
                item_delta[receipt->item.value()] -= receipt->count;
            }
        } else {
            // Đồ nhận từ nguồn khác: thêm vài món để có gì bán, thu hồi.
            const std::uint32_t id = (rng.below(2) == 0) ? kHerb : kPotion;
            const auto count = static_cast<std::uint16_t>(1 + rng.below(6));
            if (planner.add(bench.base.make(id, count))) {
                ok = true;
                item_delta[id] += count;
            }
        }

        if (!ok) {
            ++refused_count;
            context.expect(plan_of(planner).empty(), "thao tác bị từ chối không để lại gì trong kế hoạch");
            context.expect(fingerprint(bench.base.inventory) == before && store.revision() == revision, "kho đồ và cửa hàng không đổi khi bị từ chối");
            continue;
        }
        if (!bench.base.inventory.apply(std::move(planner).finish())) {
            context.expect(false, "kế hoạch hợp lệ phải áp dụng được");
            return;
        }
        if (bought) context.expect(store.commit(*bought).has_value(), "commit mua");
        if (sale) sold.remember(*sale);
        if (back) context.expect(sold.take(*back).has_value(), "lấy khỏi danh sách mua lại");
        ++applied;
        gold += gold_delta;
        for (const auto& [id, delta] : item_delta) items[id] += delta;

        const item::Wallet& wallet = bench.base.inventory.wallet();
        if (wallet.balance(Currency::kGold) != gold) {
            context.expect(false, "ví vàng khớp mô hình");
            return;
        }
        context.expect(wallet.balance(Currency::kGold) >= 0 && wallet.balance(Currency::kGold) <= wallet.cap(item::account_of(Currency::kGold)), "ví trong [0, trần]");
        for (const std::uint32_t id : {kPotion, kHerb, kSword, kWhiteRing, kCharm}) {
            if (static_cast<std::int64_t>(bench.base.inventory.count_of(TemplateId{id})) != items[id]) {
                context.expect(false, "số lượng vật phẩm khớp mô hình");
                return;
            }
        }
    }
    context.expect(applied > 500 && refused_count > 100, "chuỗi thao tác đủ đa dạng: nhiều bước thành công lẫn bị từ chối");
}

constexpr std::array kCases{
    Case{"buy_with_gold_and_ingot", buy_with_gold_and_ingot},
    Case{"buy_failures_leave_nothing", buy_failures_leave_nothing},
    Case{"buy_groups_and_stacks", buy_groups_and_stacks},
    Case{"buy_commit_order", buy_commit_order},
    Case{"sell_prices_and_gates", sell_prices_and_gates},
    Case{"sell_details", sell_details},
    Case{"sell_and_buy_back", sell_and_buy_back},
    Case{"buy_back_ring_capacity", buy_back_ring_capacity},
    Case{"repair_single", repair_single},
    Case{"repair_all_stops_at_first_unaffordable", repair_all_stops_at_first_unaffordable},
    Case{"recycle_junk", recycle_junk},
    Case{"conservation_fuzz", conservation_fuzz},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
