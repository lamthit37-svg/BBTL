// Cửa hàng của một NPC lúc chạy: mở theo cảnh, tồn kho làm mới theo tick, cửa hàng ngẫu nhiên chọn hàng theo trọng số không hoàn
// lại, và một vòng qua mọi cửa hàng trong bảng thật.
#include "shop_support.hpp"

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
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using shop::NpcShop;
using shop::ShopId;

constexpr std::int64_t kRefreshMs = 600000;                       // 12000 tick ở 20 Hz
constexpr std::uint64_t kRefreshTicks = 12000;

ShopSpec limited_shop(std::int64_t refresh_ms = kRefreshMs) {
    ShopSpec spec;
    spec.id = 1;
    spec.refresh_ms = refresh_ms;
    spec.goods = {GoodsSpec{.item = kPotion, .group = "1", .stock = "3"}, GoodsSpec{.item = kHerb, .group = "1", .stock = "-1"}};
    return spec;
}

void refresh_restores_stock(Context& context) {
    ShopBench bench(shops_table({limited_shop()}));
    NpcShop store = bench.open(1);
    context.expect(store.has_refresh() && store.next_refresh().value() == bench.now.value() + kRefreshTicks, "hẹn làm mới sau 600 s = 12000 tick");
    context.expect(store.lines().size() == 2 && store.lines()[0].stock == 3 && store.lines()[1].stock == shop::kUnlimited, "tồn kho ban đầu");
    bench.fund(Currency::kGold, 10000);
    context.expect(bench.buy(store, 0, 2).has_value() && store.lines()[0].stock == 1, "mua hai nhóm còn một");
    const std::uint64_t after_buy = store.revision();
    context.expect(bench.buy(store, 1, 3).has_value() && store.lines()[1].stock == shop::kUnlimited && store.revision() == after_buy,
        "hàng không hạn không đổi tồn kho, không tăng revision");

    context.expect(!store.tick(ids::Tick{store.next_refresh().value() - 1}, bench.base.dice) && store.lines()[0].stock == 1, "chưa tới hạn thì chưa làm mới");
    context.expect(store.tick(store.next_refresh(), bench.base.dice) && store.lines()[0].stock == 3, "tới hạn thì tồn kho về giá trị của bảng");
    context.expect(store.revision() > after_buy, "revision tăng khi làm mới");
    const ids::Tick again = store.next_refresh();
    context.expect(!store.tick(again, bench.base.dice), "làm mới khi không có gì đổi không báo thay đổi");
    context.expect(store.next_refresh().value() == again.value() + kRefreshTicks, "hạn kế tính từ lúc làm mới");
}

void missed_intervals_refresh_once(Context& context) {
    ShopBench bench(shops_table({limited_shop()}));
    NpcShop store = bench.open(1);
    bench.fund(Currency::kGold, 10000);
    context.expect(bench.buy(store, 0, 3).has_value() && store.lines()[0].stock == 0, "bán hết hàng giới hạn");
    const ids::Tick late{bench.now.value() + (10 * kRefreshTicks) + 7};
    context.expect(store.tick(late, bench.base.dice) && store.lines()[0].stock == 3, "lỡ mười hạn vẫn chỉ làm mới một lần");
    context.expect(store.next_refresh().value() == late.value() + kRefreshTicks, "hạn kế tính từ bây giờ, không bù");
}

void no_refresh_shop(Context& context) {
    ShopBench bench(shops_table({limited_shop(0)}));
    NpcShop store = bench.open(1);
    bench.fund(Currency::kGold, 10000);
    context.expect(!store.has_refresh(), "refresh_ms = 0: không làm mới");
    context.expect(bench.buy(store, 0, 3).has_value(), "mua hết");
    context.expect(!store.tick(ids::Tick{bench.now.value() + 100'000'000}, bench.base.dice) && store.lines()[0].stock == 0, "không bao giờ làm mới");
}

void open_rules(Context& context) {
    ShopSpec a = limited_shop();
    ShopSpec b = limited_shop();
    b.id = 2;
    ShopBench bench(shops_table({a, b}), {}, scenes_table({{1, {5, 9}}}));
    const auto here = NpcShop::open(bench.tables, ShopId{1}, ids::SceneId{9}, bench.now, bench.base.dice);
    context.expect(here.has_value(), "mở ở cảnh trong danh sách");
    const auto there = NpcShop::open(bench.tables, ShopId{1}, ids::SceneId{6}, bench.now, bench.base.dice);
    context.expect(!there && there.error() == item::Error::kWrongScene, "cảnh ngoài danh sách: kWrongScene");
    context.expect(NpcShop::open(bench.tables, ShopId{2}, ids::SceneId{6}, bench.now, bench.base.dice).has_value(), "cửa hàng không giới hạn mở ở mọi cảnh");
    const auto none = NpcShop::open(bench.tables, ShopId{3}, ids::SceneId{5}, bench.now, bench.base.dice);
    context.expect(!none && none.error() == item::Error::kNoSuchEntry, "cửa hàng không có: kNoSuchEntry");
}

void commit_rules(Context& context) {
    ShopBench bench(shops_table({limited_shop()}));
    NpcShop store = bench.open(1);
    const shop::BuyTicket stale{.line = 0, .groups = 1, .revision = store.revision() + 5};
    const auto old = store.commit(stale);
    context.expect(!old && old.error() == item::Error::kStalePlan, "vé của revision khác bị từ chối");
    const shop::BuyTicket far{.line = 9, .groups = 1, .revision = store.revision()};
    const auto missing = store.commit(far);
    context.expect(!missing && missing.error() == item::Error::kNoSuchEntry, "dòng ngoài miền");
    const shop::BuyTicket zero{.line = 0, .groups = 0, .revision = store.revision()};
    const auto no_groups = store.commit(zero);
    context.expect(!no_groups && no_groups.error() == item::Error::kBadCount, "số nhóm 0");
    const shop::BuyTicket many{.line = 0, .groups = 4, .revision = store.revision()};
    const auto sold_out = store.commit(many);
    context.expect(!sold_out && sold_out.error() == item::Error::kSoldOut && store.lines()[0].stock == 3, "quá tồn: kSoldOut, tồn không đổi");
    const shop::BuyTicket exact{.line = 0, .groups = 3, .revision = store.revision()};
    context.expect(store.commit(exact).has_value() && store.lines()[0].stock == 0, "trừ đúng bằng tồn");
    const auto twice = store.commit(exact);
    context.expect(!twice && twice.error() == item::Error::kStalePlan, "vé đã dùng không dùng lại được (revision đã đổi)");
}

ShopSpec random_spec(int pick, std::int64_t refresh_ms = kRefreshMs) {
    return ShopSpec{.id = 9, .refresh_ms = refresh_ms, .num = pick, .random = 1, .path = "../Public/Config/RandShop/shide.ini"};
}

std::string pool_of(std::vector<std::pair<std::uint32_t, std::string>> entries) {
    std::vector<PoolSpec> specs;
    for (auto& [item, odds] : entries) specs.push_back(PoolSpec{.key = "mentor_virtue", .item = item, .count = "2", .odds_a = std::move(odds)});
    return pool_table(specs);
}

void random_shop_picks(Context& context) {
    const std::string pool = pool_of({{kPotion, "1"}, {kHerb, "1"}, {kSword, "1"}, {kWhiteRing, "1"}, {kCharm, "1"}});
    ShopBench bench(shops_table({random_spec(3)}), pool);
    NpcShop store = bench.open(9);
    context.expect(store.lines().size() == 3, "chọn đúng 3 mục");
    std::vector<std::uint32_t> seen;
    for (const shop::Line& line : store.lines()) {
        seen.push_back(line.goods.item.value());
        context.expect(line.stock == 2, "tồn kho bằng Count của mục");
    }
    std::ranges::sort(seen);
    context.expect(std::ranges::adjacent_find(seen) == seen.end(), "ba mục khác nhau (rút không hoàn lại)");

    // Xin nhiều hơn kho: lấy hết kho, mỗi mục đúng một lần.
    ShopBench all(shops_table({random_spec(200)}), pool);
    NpcShop everything = all.open(9);
    context.expect(everything.lines().size() == 5, "Num lớn hơn kho: lấy hết 5 mục");

    // Hàng chọn xếp theo thứ tự của kho, không theo thứ tự rút.
    const std::array<std::uint32_t, 5> pool_order{kPotion, kHerb, kSword, kWhiteRing, kCharm};
    for (std::uint64_t seed = 1; seed <= 40; ++seed) {
        dice::Dice dice(seed);
        auto opened = NpcShop::open(bench.tables, ShopId{9}, ids::SceneId{1}, bench.now, dice);
        if (!opened) {
            context.expect(false, "mở được");
            return;
        }
        std::size_t last = 0;
        bool ordered = true;
        for (const shop::Line& line : opened->lines()) {
            const auto at = std::ranges::find(pool_order, line.goods.item.value());
            const auto position = static_cast<std::size_t>(at - pool_order.begin());
            ordered = ordered && position >= last;
            last = position;
        }
        context.expect(ordered, "thứ tự theo kho");
    }
}

void random_shop_weights(Context& context) {
    // Một mục chọn từ bốn: tần suất xuất hiện phải theo trọng số 1 : 1 : 2 : 6.
    const std::string pool = pool_of({{kPotion, "1"}, {kHerb, "1"}, {kSword, "2"}, {kWhiteRing, "6"}});
    ShopBench bench(shops_table({random_spec(1)}), pool);
    std::map<std::uint32_t, int> hits;
    constexpr int kTrials = 20000;
    dice::Dice dice(2024);
    for (int i = 0; i < kTrials; ++i) {
        auto opened = NpcShop::open(bench.tables, ShopId{9}, ids::SceneId{1}, bench.now, dice);
        if (!opened || opened->lines().size() != 1) {
            context.expect(false, "mỗi lần mở có đúng một mục");
            return;
        }
        ++hits[opened->lines().front().goods.item.value()];
    }
    const auto share = [&hits](std::uint32_t id) { return static_cast<double>(hits[id]) / kTrials; };
    // Sai số chuẩn lớn nhất ~ sqrt(0,6 x 0,4 / 20000) = 0,0035; dung sai 0,02 là hơn năm độ lệch chuẩn.
    context.expect(std::abs(share(kPotion) - 0.1) < 0.02 && std::abs(share(kHerb) - 0.1) < 0.02, "trọng số 1/10");
    context.expect(std::abs(share(kSword) - 0.2) < 0.02, "trọng số 2/10");
    context.expect(std::abs(share(kWhiteRing) - 0.6) < 0.02, "trọng số 6/10");
}

void random_shop_refresh_rerolls(Context& context) {
    const std::string pool = pool_of({{kPotion, "1"}, {kHerb, "1"}, {kSword, "1"}, {kWhiteRing, "1"}, {kCharm, "1"}, {kUniqueRing, "1"}});
    ShopBench bench(shops_table({random_spec(2)}), pool);
    NpcShop store = bench.open(9);
    bench.fund(Currency::kGold, 1'000'000);
    std::size_t changes = 0;
    ids::Tick now = store.next_refresh();
    for (int i = 0; i < 30; ++i) {
        const std::vector<shop::Line> before(store.lines().begin(), store.lines().end());
        const std::uint64_t revision = store.revision();
        const bool changed = store.tick(now, bench.base.dice);
        const std::vector<shop::Line> after(store.lines().begin(), store.lines().end());
        context.expect(changed == (before != after) && changed == (store.revision() != revision), "tick báo đổi khi và chỉ khi hàng đổi");
        context.expect(after.size() == 2, "luôn hai mục sau khi làm mới");
        if (changed) ++changes;
        now = store.next_refresh();
    }
    context.expect(changes > 5, "chọn lại: nhiều lần làm mới cho tập hàng khác");
}

void deterministic_per_seed(Context& context) {
    const std::string pool = pool_of({{kPotion, "3"}, {kHerb, "1"}, {kSword, "2"}, {kWhiteRing, "5"}, {kCharm, "1"}});
    ShopBench bench(shops_table({random_spec(3)}), pool);
    dice::Dice a(77);
    dice::Dice b(77);
    auto left = NpcShop::open(bench.tables, ShopId{9}, ids::SceneId{1}, bench.now, a);
    auto right = NpcShop::open(bench.tables, ShopId{9}, ids::SceneId{1}, bench.now, b);
    context.expect(left && right && std::ranges::equal(left->lines(), right->lines()), "cùng hạt giống ra cùng hàng");
}

#ifdef GAME_SERVER_TABLES
// Mở mọi cửa hàng của bảng thật ở một cảnh được phép: hàng nằm trong catalog, giá tính được, cửa hàng ngẫu nhiên chọn đủ số mục.
void real_shops_open(Context& context) {
    const std::optional<RealWorld> real = load_real(context);
    if (!real) return;
    const std::string root = GAME_SERVER_TABLES;
    const std::string shops_text = read_text(root + "/shared/shops.tsv");
    const std::string pool_text = read_text(root + "/server/random_shop_goods.tsv");
    const std::string scene_text = read_text(root + "/shared/shop_scene_limits.tsv");
    const auto loaded = shop::ShopTables::load({.shops = shops_text, .scene_limits = scene_text, .random_goods = pool_text, .junk_recycle = {}}, real->catalog);
    if (!loaded) {
        context.expect(false, "bảng thật nạp được");
        return;
    }
    dice::Dice dice(5);
    std::size_t opened = 0;
    std::size_t lines = 0;
    std::size_t gold_lines = 0;
    for (const shop::ShopDef& def : loaded->all()) {
        // Cảnh 65000 không nằm trong danh sách của cửa hàng nào; cảnh đầu tiên được phép thì mở được.
        context.expect(!NpcShop::open(*loaded, def.id, ids::SceneId{65000}, ids::Tick{1}, dice).has_value(), "cảnh lạ bị từ chối");
        std::uint16_t scene = 0;
        while (scene < 20000 && !loaded->allowed_in(def, ids::SceneId{scene})) ++scene;
        context.expect(scene < 20000, "mỗi cửa hàng thật có ít nhất một cảnh được phép");
        auto store = NpcShop::open(*loaded, def.id, ids::SceneId{scene}, ids::Tick{1}, dice);
        context.expect(store.has_value(), "mở được ở cảnh được phép");
        if (!store) continue;
        ++opened;
        if (def.random) {
            context.expect(store->lines().size() == std::min<std::size_t>(def.pick_count, loaded->pool(def).size()), "cửa hàng ngẫu nhiên chọn đủ số mục");
        }
        for (const shop::Line& line : store->lines()) {
            ++lines;
            const auto price = shop::price_of(def, line.goods, real->catalog);
            context.expect(price.has_value() && *price >= 0 && line.goods.group >= 1, "giá của mọi hàng tính được");
            if (price && shop::is_gold_like(def.currency)) {
                ++gold_lines;
                const item::Template* tmpl = real->catalog.find(line.goods.item);
                context.expect(tmpl != nullptr && (tmpl->base_price == 0 || *price > 0), "hàng bán bằng vàng có giá khi vật phẩm có giá");
            }
        }
    }
    context.expect(opened == loaded->all().size(), "mở được mọi cửa hàng");
    context.expect(lines > 8000 && gold_lines > 1000, "số hàng mở ra cỡ bảng thật");
}
#endif

constexpr std::array kCases{
    Case{"refresh_restores_stock", refresh_restores_stock},
    Case{"missed_intervals_refresh_once", missed_intervals_refresh_once},
    Case{"no_refresh_shop", no_refresh_shop},
    Case{"open_rules", open_rules},
    Case{"commit_rules", commit_rules},
    Case{"random_shop_picks", random_shop_picks},
    Case{"random_shop_weights", random_shop_weights},
    Case{"random_shop_refresh_rerolls", random_shop_refresh_rerolls},
    Case{"deterministic_per_seed", deterministic_per_seed},
#ifdef GAME_SERVER_TABLES
    Case{"real_shops_open", real_shops_open},
#endif
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
