// Bảng cửa hàng: cách đọc hàng và luật cổng, kho ngẫu nhiên, bảng cảnh, phế phẩm, công thức giá, lỗi bảng, và đối chiếu với
// bảng thật bằng một bộ tách độc lập.
#include "shop_support.hpp"

#include "item/types.hpp"
#include "shop/tables.hpp"
#include "shop/trade.hpp"
#include "shop/types.hpp"
#include "test.hpp"

#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using shop::ShopId;

// Nạp bảng thử; trả thông điệp lỗi hoặc rỗng nếu nạp được.
std::string load_error(const std::string& shops, const std::string& pool = {}, const std::string& scenes = {},
    const std::string& junk = {}) {
    const Bench bench;
    const auto loaded = shop::ShopTables::load({.shops = shops, .scene_limits = scenes, .random_goods = pool, .junk_recycle = junk}, bench.world.catalog);
    return loaded ? std::string{} : loaded.error();
}

bool has(const std::string& text, std::string_view needle) { return text.find(needle) != std::string::npos; }

ShopSpec basic_shop() {
    return ShopSpec{.goods = {
        GoodsSpec{.item = kPotion, .group = "5", .stock = "3"},
        GoodsSpec{.item = kUnknownItem},
        GoodsSpec{.item = kHerb, .group = "-1", .stock = "0"},
        GoodsSpec{.item = kSword, .group = "200", .stock = "-1", .price = "7", .discount = "40"},
        GoodsSpec{.item = 0},
        GoodsSpec{.item = kWhiteRing},
    }};
}

void fixed_goods(Context& context) {
    ShopBench bench(shops_table({basic_shop()}));
    const shop::ShopDef* def = bench.tables.find(ShopId{1});
    context.expect(def != nullptr && !def->random && def->currency == Currency::kGold, "cửa hàng 1 cố định, tiền vàng");
    if (def == nullptr) return;
    const auto goods = bench.tables.goods(*def);
    // Mã lạ bị bỏ và đếm; mã 0 chặn mọi khối sau nó; PNUM < 0 thành 1, > 100 thành 100; PMAX 0 thành không hạn (2008).
    context.expect(goods.size() == 3, "ba hàng: thuốc, thảo dược, kiếm");
    context.expect(bench.tables.diagnostics().unknown_goods == 1, "một mã lạ được đếm");
    if (goods.size() != 3) return;
    context.expect(goods[0].item.value() == kPotion && goods[0].group == 5 && goods[0].capacity == 3, "thuốc: nhóm 5, tồn 3");
    context.expect(goods[1].item.value() == kHerb && goods[1].group == 1 && goods[1].capacity == shop::kUnlimited, "thảo dược: PNUM -1 thành 1, PMAX 0 thành không hạn");
    context.expect(goods[2].item.value() == kSword && goods[2].group == shop::kMaxGroupSize && goods[2].listed_price == 7
            && goods[2].discount_percent == 40,
        "kiếm: PNUM 200 kẹp về 100, giá ghi sẵn 7, chiết khấu 40");
    context.expect(goods[0].discount_percent == 100, "chiết khấu mặc định 100");
}

void num_limits_scan(Context& context) {
    ShopSpec spec = basic_shop();
    spec.goods = {GoodsSpec{.item = kPotion}, GoodsSpec{.item = kHerb}, GoodsSpec{.item = kSword}};
    spec.num = 2;  // Num là số khối 2008 đọc, không phải số hàng thật
    ShopBench bench(shops_table({spec}));
    const shop::ShopDef* def = bench.tables.find(ShopId{1});
    context.expect(def != nullptr && bench.tables.goods(*def).size() == 2, "Num = 2 chỉ đọc hai khối đầu");
    spec.num = 0;
    ShopBench none(shops_table({spec}));
    const shop::ShopDef* empty = none.tables.find(ShopId{1});
    context.expect(empty != nullptr && none.tables.goods(*empty).empty(), "Num = 0 không có hàng");
}

void scopes_and_decimals(Context& context) {
    ShopSpec spec;
    spec.id = 1;
    spec.buy_kind = 9;
    spec.repair_type = 1;
    ShopSpec none = spec;
    none.id = 2;
    none.buy_kind = 8;
    ShopSpec defence = spec;
    defence.id = 3;
    defence.buy_kind = 2;
    defence.repair_type = 2;
    ShopSpec odd = spec;
    odd.id = 4;
    odd.buy_kind = 7;
    odd.repair_type = 6;  // 2008: sửa chỉ biết 1..4, giá trị khác không sửa gì
    odd.repair_cost = "0.5";
    odd.scale = "1.25";
    odd.repair_rate = "0.8";
    ShopSpec fine = spec;
    fine.id = 5;
    fine.scale = "0.00184";  // làm tròn nửa lên đến phần nghìn
    ShopBench bench(shops_table({spec, none, defence, odd, fine}));
    using shop::Scope;
    const auto def = [&bench](std::uint32_t id) { return *bench.tables.find(ShopId{id}); };
    context.expect(def(1).buy_scope == Scope::kAll && def(1).repair_scope == Scope::kAll, "loại 9 thu mua mọi thứ, sửa loại 1 sửa mọi thứ");
    context.expect(def(2).buy_scope == Scope::kNone, "loại 8 không thu mua");
    context.expect(def(3).buy_scope == Scope::kDefence && def(3).repair_scope == Scope::kDefence, "loại 2 là phòng cụ");
    context.expect(def(4).buy_scope == Scope::kMedicine && def(4).repair_scope == Scope::kNone, "loại 7 thu mua thuốc; sửa loại 6 không sửa gì");
    context.expect(def(4).repair_permille == 500 && def(4).scale_permille == 1250, "số thập phân thành phần nghìn");
    context.expect(bench.tables.diagnostics().repair_rate_not_one == 1, "một cửa hàng có tỉ lệ sửa khác 1 được đếm");
    context.expect(def(5).scale_permille == 2, "0,00184 làm tròn thành 2 phần nghìn");
}

void table_errors(Context& context) {
    const auto with = [](auto edit) {
        ShopSpec spec = basic_shop();
        edit(spec);
        return shops_table({spec});
    };
    context.expect(has(load_error(with([](ShopSpec& s) { s.currency = 17; })), "currency"), "tiền ngoài 1..16 là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.currency = 0; })), "currency"), "tiền 0 là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.scale = "0"; })), "scale"), "hệ số cửa hàng 0 là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.scale = "abc"; })), "scale"), "hệ số không phải số là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.scale = "1."; })), "scale"), "dấu chấm cụt là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.scale = "-1"; })), "scale"), "hệ số âm là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.scale = "100001"; })), "scale"), "hệ số vượt 100 lần là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.goods.at(0).discount = "0"; })), "shops"), "chiết khấu 0 là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.goods.at(0).discount = "1001"; })), "shops"), "chiết khấu quá 1000 là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.goods.at(0).price = "x"; })), "shops"), "giá không phải số là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.num = 201; })), "shops"), "Num quá 200 là lỗi");
    context.expect(has(load_error(with([](ShopSpec& s) { s.id = 0; })), "shops"), "mã cửa hàng 0 là lỗi");
    context.expect(has(load_error(shops_table({ShopSpec{.id = 4}, ShopSpec{.id = 4}})), "hai lần"), "mã cửa hàng trùng là lỗi");
    context.expect(has(load_error(""), "shops"), "thiếu bảng là lỗi");

    std::string wrong_header = shops_table({basic_shop()});
    wrong_header.replace(wrong_header.find("repair_level"), 12, "repair_xxxxx");
    context.expect(has(load_error(wrong_header), "repair_level"), "tên cột đầu sai bị chặn");
    std::string wrong_width = shops_table({basic_shop()});
    wrong_width.replace(wrong_width.find("\tcolumn_28"), 10, "\tcolumn_28\textra");
    context.expect(!load_error(wrong_width).empty(), "số cột không phải 29 + 6k bị chặn");
    context.expect(!load_error(shops_table({basic_shop()}).substr(0, 60)).empty(), "bảng cụt bị chặn");
}

void random_pool(Context& context) {
    ShopSpec spec{.id = 7, .refresh_ms = 100000, .num = 2, .random = 1, .path = "../Public/Config/RandShop/60wufang.ini"};
    spec.goods = {GoodsSpec{.item = kPotion}};  // hàng cố định của cửa hàng ngẫu nhiên bị bỏ qua
    const std::string pool = pool_table({
        PoolSpec{.key = "workshop_60", .item = kPotion, .count = "2  ", .per_unit = "3", .odds_a = "5", .value = "9", .rebate = "80"},
        PoolSpec{.key = "workshop_60", .item = kHerb, .count = "1", .odds_a = "", .odds_b = "2", .value = "300"},
        PoolSpec{.key = "workshop_60", .item = kSword, .odds_a = "1", .declared = 0},
        PoolSpec{.key = "workshop_60", .item = kUnknownItem},
        PoolSpec{.key = "gems", .item = kHerb},
    });
    ShopBench bench(shops_table({spec}), pool);
    const shop::ShopDef* def = bench.tables.find(ShopId{7});
    context.expect(def != nullptr && def->random && def->pick_count == 2 && def->goods_count == 0, "cửa hàng ngẫu nhiên chọn 2 mục, không hàng cố định");
    if (def == nullptr) return;
    const auto entries = bench.tables.pool(*def);
    context.expect(entries.size() == 2, "kho workshop_60: hai mục (một ngoài Total, một mã lạ bị bỏ)");
    context.expect(bench.tables.diagnostics().unknown_pool_items == 1, "mã lạ của kho được đếm");
    if (entries.size() != 2) return;
    context.expect(entries[0].goods.item.value() == kPotion && entries[0].goods.capacity == 2 && entries[0].goods.group == 3
            && entries[0].odds == 5 && entries[0].goods.listed_price == 9 && entries[0].goods.discount_percent == 80,
        "mục 1: tồn 2 (ô có dấu cách thừa), nhóm 3, odds 5, giá 9, chiết khấu 80");
    context.expect(entries[1].goods.item.value() == kHerb && entries[1].odds == 2 && entries[1].goods.discount_percent == 100,
        "mục 2: odds lấy từ cột thứ hai, chiết khấu mặc định 100");

    ShopSpec lost = spec;
    lost.path = "../Public/Config/RandShop/khong_co.ini";
    context.expect(has(load_error(shops_table({lost}), pool), "khong_co"), "đường dẫn kho lạ là lỗi");
    ShopSpec missing = spec;
    missing.path = "../Public/Config/RandShop/shide.ini";
    context.expect(has(load_error(shops_table({missing}), pool), "mentor_virtue"), "kho không có dòng nào là lỗi");
    context.expect(has(load_error(shops_table({spec}), pool_table({PoolSpec{.key = "workshop_60", .item = kPotion, .odds_a = "", .odds_b = ""}})), "odds"),
        "mục thiếu cả hai odds là lỗi");
    context.expect(has(load_error(shops_table({spec}), pool_table({PoolSpec{.key = "workshop_60", .item = kPotion, .rebate = "0"}})), "random_shop_goods"),
        "chiết khấu kho 0 là lỗi");
}

void scene_limits(Context& context) {
    ShopSpec a;
    a.id = 1;
    ShopSpec b;
    b.id = 2;
    ShopSpec c;
    c.id = 3;
    const std::string scenes = scenes_table({{1, {0, 2, 2, 186}}, {2, {}}, {99, {5}}});
    ShopBench bench(shops_table({a, b, c}), {}, scenes);
    const shop::ShopDef& one = *bench.tables.find(ShopId{1});
    context.expect(bench.tables.allowed_in(one, ids::SceneId{186}) && bench.tables.allowed_in(one, ids::SceneId{0})
            && bench.tables.allowed_in(one, ids::SceneId{2}),
        "cảnh trong danh sách mở được (trùng lặp không sao)");
    context.expect(!bench.tables.allowed_in(one, ids::SceneId{1}) && !bench.tables.allowed_in(one, ids::SceneId{3}), "cảnh ngoài danh sách không mở được");
    context.expect(bench.tables.allowed_in(*bench.tables.find(ShopId{2}), ids::SceneId{77}), "dòng chỉ toàn -1 không giới hạn");
    context.expect(bench.tables.allowed_in(*bench.tables.find(ShopId{3}), ids::SceneId{77}), "cửa hàng không có dòng cảnh mở ở mọi nơi");
    context.expect(bench.tables.diagnostics().scene_rows_without_shop == 1, "dòng cảnh của cửa hàng không có được đếm");
    context.expect(has(load_error(shops_table({a}), {}, scenes_table({{1, {0}}, {1, {2}}})), "hai dòng"), "cửa hàng hai dòng cảnh là lỗi");
    context.expect(has(load_error(shops_table({a}), {}, scenes_table({{1, {70000}}})), "shop_scene_limits"), "cảnh ngoài uint16 là lỗi");
}

void junk_values(Context& context) {
    ShopBench bench(shops_table({basic_shop()}), {}, {}, junk_table({{kHerb, 25000}, {kPotion, 500}, {kUnknownItem, 7}}));
    context.expect(bench.tables.junk_value(TemplateId{kHerb}) == 25000 && bench.tables.junk_value(TemplateId{kPotion}) == 500, "giá phế phẩm");
    context.expect(!bench.tables.junk_value(TemplateId{kSword}).has_value(), "mã không thu hồi");
    context.expect(bench.tables.diagnostics().unknown_junk_items == 1, "mã lạ của phế phẩm được đếm");
    context.expect(has(load_error(shops_table({basic_shop()}), {}, {}, junk_table({{kHerb, 1}, {kHerb, 2}})), "hai lần"), "phế phẩm trùng là lỗi");
    context.expect(has(load_error(shops_table({basic_shop()}), {}, {}, junk_table({{kHerb, -3}})), "junk_recycle"), "giá phế phẩm âm là lỗi");
}

// Giá: vàng và giao tử đọc từ bảng vật phẩm, tiền khác dùng giá ghi sẵn; hệ số cửa hàng và chiết khấu nhân một lần.
void price_rules(Context& context) {
    Bench bench;
    const auto price = [&bench](const shop::ShopDef& shop, const shop::Goods& goods) {
        const auto value = shop::price_of(shop, goods, bench.world.catalog);
        return value ? *value : -1;
    };
    shop::ShopDef gold;
    gold.currency = Currency::kGold;
    shop::Goods potion{.item = TemplateId{kPotion}, .group = 5, .capacity = -1, .listed_price = 7, .discount_percent = 100};
    context.expect(price(gold, potion) == 500, "vàng: giá bảng 100 x nhóm 5, bỏ qua giá ghi sẵn");
    shop::ShopDef bound = gold;
    bound.currency = Currency::kBoundGold;
    context.expect(price(bound, potion) == 500, "giao tử cũng đọc từ bảng vật phẩm");
    shop::ShopDef ingot = gold;
    ingot.currency = Currency::kIngot;
    context.expect(price(ingot, potion) == 7, "nguyên bảo: giá ghi sẵn cho cả nhóm");
    ingot.scale_permille = 2000;
    context.expect(price(ingot, potion) == 14, "hệ số cửa hàng 2,0 nhân giá");
    potion.discount_percent = 50;
    context.expect(price(ingot, potion) == 7, "chiết khấu 50% sau hệ số 2,0");
    potion.listed_price = 3;
    ingot.scale_permille = 1000;
    context.expect(price(ingot, potion) == 2, "3 x 50% = 1,5 làm tròn nửa lên thành 2");
    potion.listed_price = 2;
    potion.discount_percent = 5;
    context.expect(price(ingot, potion) == 1, "hàng có giá không bao giờ về 0 vì chiết khấu");
    potion.listed_price = 0;
    context.expect(price(ingot, potion) == 0, "giá ghi sẵn 0 là cho không");
    potion.listed_price = std::numeric_limits<std::int32_t>::max();
    potion.discount_percent = 1000;
    ingot.scale_permille = 4'000'000'000U;  // ngoài miền bộ nạp cho phép: thử riêng đường tràn của phép nhân
    const auto huge = shop::price_of(ingot, potion, bench.world.catalog);
    context.expect(!huge && huge.error() == item::Error::kBadAmount, "giá tràn int64 báo kBadAmount");
    const auto lost = shop::price_of(gold, shop::Goods{.item = TemplateId{kUnknownItem}}, bench.world.catalog);
    context.expect(!lost && lost.error() == item::Error::kUnknownTemplate, "vàng mà vật phẩm không có trong catalog");
    shop::Goods sword{.item = TemplateId{kSword}, .group = 1, .capacity = -1, .listed_price = 0, .discount_percent = 100};
    gold.scale_permille = 1500;
    context.expect(price(gold, sword) == 1500, "kiếm giá 1000 x hệ số 1,5");
}

void scope_filters(Context& context) {
    Bench bench;
    const auto tmpl = [&bench](std::uint32_t id) -> const item::Template& { return *bench.world.catalog.find(TemplateId{id}); };
    using shop::Scope;
    context.expect(shop::accepts(Scope::kAll, tmpl(kPotion)) && !shop::accepts(Scope::kNone, tmpl(kPotion)), "kAll nhận mọi thứ, kNone không nhận gì");
    context.expect(shop::accepts(Scope::kWeapon, tmpl(kSword)) && !shop::accepts(Scope::kWeapon, tmpl(kWhiteRing)), "vũ khí chỉ điểm lắp 0");
    context.expect(shop::accepts(Scope::kAdorn, tmpl(kWhiteRing)) && !shop::accepts(Scope::kDefence, tmpl(kWhiteRing)), "nhẫn là trang sức");
    context.expect(!shop::accepts(Scope::kAdorn, tmpl(kCharm)), "bùa hộ thân (điểm 12) không thuộc ba nhóm của 2008");
    context.expect(!shop::accepts(Scope::kWeapon, tmpl(kPotion)) && !shop::accepts(Scope::kDefence, tmpl(kHerb)), "đồ thường không thuộc nhóm trang bị");
    context.expect(shop::accepts(Scope::kFood, tmpl(kPotion)) && shop::accepts(Scope::kMedicine, tmpl(kPotion)) && !shop::accepts(Scope::kFood, tmpl(kHerb)),
        "đồ ăn và thuốc cùng lớp 3");
    context.expect(shop::accepts(Scope::kMaterial, tmpl(kHerb)) && !shop::accepts(Scope::kMaterial, tmpl(kPotion)), "nguyên liệu lớp 2");
    context.expect(shop::covers_point(Scope::kAll, 20) && !shop::covers_point(Scope::kDefence, 0) && shop::covers_point(Scope::kDefence, 4)
            && !shop::covers_point(Scope::kDefence, 5) && shop::covers_point(Scope::kAdorn, 8) && !shop::covers_point(Scope::kAdorn, 9)
            && shop::covers_point(Scope::kWeapon, 0) && !shop::covers_point(Scope::kFood, 0),
        "biên của các nhóm điểm lắp");
}

#ifdef GAME_SERVER_TABLES
// Đối chiếu với bảng thật bằng bộ tách độc lập (item_support: tsv_rows): đếm hàng của từng cửa hàng theo luật 2008 ghi lại từ đầu.
void real_tables(Context& context) {
    const std::optional<RealWorld> real = load_real(context);
    if (!real) return;
    const std::string root = GAME_SERVER_TABLES;
    const std::string shops_text = read_text(root + "/shared/shops.tsv");
    const std::string pool_text = read_text(root + "/server/random_shop_goods.tsv");
    const std::string scene_text = read_text(root + "/shared/shop_scene_limits.tsv");
    const std::string junk_text = read_text(root + "/shared/junk_recycle.tsv");
    const auto loaded = shop::ShopTables::load({.shops = shops_text, .scene_limits = scene_text, .random_goods = pool_text, .junk_recycle = junk_text}, real->catalog);
    context.expect(loaded.has_value(), "bảng thật nạp được");
    if (!loaded) {
        std::fprintf(stderr, "%s\n", loaded.error().c_str());
        return;
    }
    const std::vector<std::vector<std::string>> raw = tsv_rows(shops_text);
    context.expect(loaded->all().size() == raw.size() - 1, "số cửa hàng bằng số dòng của bảng");

    std::size_t expected_goods = 0;
    std::size_t expected_unknown = 0;
    std::size_t random_shops = 0;
    for (std::size_t r = 1; r < raw.size(); ++r) {
        const std::vector<std::string>& row = raw[r];
        const shop::ShopDef* def = loaded->find(ShopId{static_cast<std::uint32_t>(std::stoul(row[0]))});
        context.expect(def != nullptr, "cửa hàng có trong bảng đã nạp");
        if (def == nullptr) continue;
        if (row[12] == "1") {
            ++random_shops;
            context.expect(def->random && def->pick_count == std::stoul(row[11]) && !loaded->pool(*def).empty(), "cửa hàng ngẫu nhiên có kho");
            continue;
        }
        std::size_t known = 0;
        const std::size_t scan = std::min<std::size_t>(200, std::stoul(row[11]));
        for (std::size_t block = 0; block < scan; ++block) {
            const long code = std::stol(row[29 + (6 * block)]);
            if (code <= 0) break;
            if (real->catalog.find(TemplateId{static_cast<std::uint32_t>(code)}) == nullptr) {
                ++expected_unknown;
            } else {
                ++known;
            }
        }
        expected_goods += known;
        context.expect(loaded->goods(*def).size() == known, "số hàng của từng cửa hàng khớp bộ tách độc lập");
        for (const shop::Goods& goods : loaded->goods(*def)) {
            context.expect(goods.group >= 1 && goods.group <= shop::kMaxGroupSize && goods.discount_percent >= 1 && goods.capacity != 0,
                "hàng trong miền");
        }
        context.expect(def->currency == static_cast<Currency>(std::stoul(row[7])), "loại tiền khớp");
    }
    context.expect(loaded->diagnostics().unknown_goods == expected_unknown, "số mã lạ khớp");
    context.expect(random_shops == 14, "14 cửa hàng ngẫu nhiên");
    std::size_t total = 0;
    for (const shop::ShopDef& def : loaded->all()) total += loaded->goods(def).size();
    context.expect(total == expected_goods, "tổng hàng khớp");
    context.expect(loaded->diagnostics().scene_rows_without_shop == 0, "mọi dòng cảnh có cửa hàng");
    for (const shop::ShopDef& def : loaded->all()) context.expect(def.scene_limited, "mọi cửa hàng thật có danh sách cảnh");
    context.expect(loaded->junk_value(TemplateId{20310113}) == 500 && loaded->junk_value(TemplateId{38008156}) == 10000, "giá phế phẩm thật");
    context.expect(loaded->diagnostics().unknown_junk_items == 0, "mọi phế phẩm có trong catalog");
}
#endif

constexpr std::array kCases{
    Case{"fixed_goods", fixed_goods},
    Case{"num_limits_scan", num_limits_scan},
    Case{"scopes_and_decimals", scopes_and_decimals},
    Case{"table_errors", table_errors},
    Case{"random_pool", random_pool},
    Case{"scene_limits", scene_limits},
    Case{"junk_values", junk_values},
    Case{"price_rules", price_rules},
    Case{"scope_filters", scope_filters},
#ifdef GAME_SERVER_TABLES
    Case{"real_tables", real_tables},
#endif
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
