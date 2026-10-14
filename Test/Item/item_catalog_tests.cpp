// Danh mục mẫu vật phẩm: nạp bảng sai thì mọi túi, cửa hàng, rơi đồ lệch thầm, nên kiểm cột đọc đúng ý nghĩa với bảng
// dựng tay (số tự đặt rõ ràng) và với bảng thật (số lấy độc lập bằng Python từ chính tệp TSV, ghi ở từng ca).
#include "item_support.hpp"

#include "item/catalog.hpp"
#include "item/limits.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <string>

namespace game::test {
namespace {

using item::Catalog;
using item::Kind;
using item::Place;
using item::TemplateId;

void synthetic_fields(Context& context) {
    const World w = make_world();
    const item::Template* potion = w.catalog.find(TemplateId{kPotion});
    context.expect(potion != nullptr, "thuốc có trong danh mục");
    if (potion == nullptr) return;
    context.expect(potion->kind == Kind::kCommon && potion->stack_max == 20, "thuốc chồng 20");
    context.expect(potion->home == Place::kBaseBag, "thuốc ở túi đạo cụ");
    context.expect(w.catalog.find(TemplateId{kHerb})->home == Place::kMaterialBag, "lớp 2 vào túi nguyên liệu");
    context.expect(w.catalog.find(TemplateId{kQuestItem})->home == Place::kQuestBag, "lớp 4 vào túi nhiệm vụ");
    const item::Template* sword = w.catalog.find(TemplateId{kSword});
    context.expect(sword != nullptr && sword->kind == Kind::kEquipment && sword->stack_max == 1, "kiếm không chồng");
    context.expect(sword != nullptr && sword->rule.equip_bind && !sword->rule.tile, "kiếm khoá khi mặc");
    context.expect(sword != nullptr && sword->equip.base.at(0) == 500 && sword->equip.base.at(1) == 500, "nền kiếm 500/500");
    context.expect(sword != nullptr && sword->level == 10 && sword->equip.max_durability == 100, "cấp và độ bền");
    const item::Template* ring = w.catalog.find(TemplateId{kBlueRing});
    context.expect(ring != nullptr && ring->equip.weight_count == 6, "nhẫn lam có sáu trọng số");
    context.expect(ring != nullptr && w.catalog.weights(*ring).size() == 6, "span trọng số đủ sáu");
    const item::Template* gem = w.catalog.find(TemplateId{kGem});
    context.expect(gem != nullptr && w.catalog.gem_attrs(*gem).size() == 1, "đá có một thuộc tính");
    context.expect(gem != nullptr && w.catalog.gem_attrs(*gem).front().value == 10, "đá +10");
    context.expect(w.catalog.find(TemplateId{999}) == nullptr, "id lạ không có");
    context.expect(w.catalog.find(TemplateId{kUniqueRing})->max_owned == 1, "cờ unique thành max_owned 1");
}

void rejects_bad_tables(Context& context) {
    const std::string rules = rules_table();
    // tham chiếu luật không có
    const std::string bad_rule = common_table({CommonRow{.id = 30000009, .rule = 77}});
    const auto missing = Catalog::load({.rules = rules, .common = bad_rule});
    context.expect(!missing && missing.error().find("77") != std::string::npos, "luật 77 không có phải báo lỗi");
    // id trùng
    const std::string dup = common_table({CommonRow{.id = 30000009}, CommonRow{.id = 30000009}});
    context.expect(!Catalog::load({.rules = rules, .common = dup}), "id trùng phải báo lỗi");
    // ô không phải số
    std::string garbage = common_table({CommonRow{.id = 30000009}});
    garbage.replace(garbage.find("30000009"), 8, "3000x009");
    context.expect(!Catalog::load({.rules = rules, .common = garbage}), "id không phải số phải báo lỗi");
    // dòng thiếu ô
    const std::string cut = "# schema 1\nindex\tclass\n30000009\t3\t4\n";
    context.expect(!Catalog::load({.rules = rules, .common = cut}), "dòng sai số ô phải báo lỗi");
    // bảng luật rỗng
    context.expect(!Catalog::load({.rules = "# schema 1\nindex\tcolumn_1\n"}), "bảng luật không đủ cột phải báo lỗi");
    // trang bị ngoài điểm lắp
    EquipRow bad_point{.id = 10100099, .point = 40};
    context.expect(!Catalog::load({.rules = rules, .equipment = equipment_table({bad_point})}), "điểm lắp 40 ngoài miền");
}

void real_tables_load(Context& context) {
#ifdef GAME_SERVER_TABLES
    const std::string root = GAME_SERVER_TABLES;
    const std::string rules = read_text(root + "/shared/item_rules.tsv");
    const std::string common = read_text(root + "/shared/items_common.tsv");
    const std::string equipment = read_text(root + "/shared/equipment.tsv");
    const std::string gems = read_text(root + "/shared/gems.tsv");
    const std::string pets = read_text(root + "/shared/pet_equipment_base.tsv");
    const std::string extra = read_text(root + "/shared/equipment_extra_attributes.tsv");
    auto catalog = Catalog::load({.rules = rules, .common = common, .equipment = equipment, .gems = gems,
        .pet_equipment = pets, .extra_attributes = extra});
    context.expect(catalog.has_value(), "bảng thật phải nạp được");
    if (!catalog) {
        std::fprintf(stderr, "%s\n", catalog.error().c_str());
        return;
    }
    // Số dòng đếm độc lập bằng Python: 20501 + 24577 + 1195 + 875.
    context.expect(catalog->size() == 47148, "tổng số mẫu 47148");
    // Mọi mẫu đã qua kiểm chéo luật; kiểm vài ô đọc độc lập từ tệp.
    const item::Template* sword = catalog->find(TemplateId{10100000});
    context.expect(sword != nullptr && sword->level == 1 && sword->base_price == 20 && sword->sale_price == 16, "10100000: cấp và giá");
    context.expect(sword != nullptr && sword->equip.max_durability == 114 && sword->equip.base.at(0) == 75 &&
        sword->equip.base.at(1) == 75, "10100000: độ bền 114, nền 75/75");
    const item::Template* blue = catalog->find(TemplateId{10200008});
    context.expect(blue != nullptr && blue->equip.seg_rule == 17 && blue->equip.band_start == 80, "10200008: luật 17, đoạn 80");
    context.expect(blue != nullptr && blue->equip.attr_min == 3 && blue->equip.attr_max == 6, "10200008: 3..6 thuộc tính");
    context.expect(blue != nullptr && blue->equip.apt_min == 1 && blue->equip.apt_max == 250 && blue->equip.gem_slots == 3,
        "10200008: tư chất 1..250, ba ô đá");
    const item::Template* herb = catalog->find(TemplateId{20101001});
    context.expect(herb != nullptr && herb->stack_max == 250 && herb->base_price == 375 && herb->home == Place::kMaterialBag,
        "20101001: chồng 250, giá 375, túi nguyên liệu");
    const item::Template* gem = catalog->find(TemplateId{50101001});
    context.expect(gem != nullptr && catalog->gem_attrs(*gem).size() == 1 && catalog->gem_attrs(*gem).front().id.value() == 26 &&
        catalog->gem_attrs(*gem).front().value == 127, "50101001: thuộc tính 26 = 127");
    // Quy tắc: mọi mẫu trang bị có điểm lắp trong miền và mọi đồ chồng được có stack_max >= 1.
    bool sane = true;
    for (const item::Template& t : catalog->all()) {
        sane = sane && t.stack_max >= 1 && (t.kind != Kind::kEquipment || t.equip.point < item::kEquipSlots);
    }
    context.expect(sane, "mọi mẫu hợp lệ về cỡ chồng và điểm lắp");
#else
    static_cast<void>(context);
#endif
}

void real_limits_and_rolls_load(Context& context) {
#ifdef GAME_SERVER_TABLES
    const std::string root = GAME_SERVER_TABLES;
    const std::string limits = read_text(root + "/server/item_limits.tsv");
    const std::string caps = read_text(root + "/shared/money_caps_by_level.tsv");
    const auto loaded = item::Limits::load({.limits = limits, .gold_caps = caps});
    context.expect(loaded.has_value(), "item_limits.tsv nạp được");
    if (loaded) {
        context.expect(loaded->capacity.at(0) == 60 && loaded->capacity.at(4) == 100, "cỡ túi 60, kho 100");
        context.expect(loaded->unlocked.at(0) == 20, "mở sẵn 20 ô túi đạo cụ");
        context.expect(loaded->bank_gold_cap == 10'000'000, "trần vàng kho 10 triệu");
        // Trần vàng theo cấp: dòng 1 = 10000, dòng 150 = 100000000 (đọc từ tệp bằng awk).
        context.expect(loaded->gold_cap(1) == 10000 && loaded->gold_cap(150) == 100'000'000, "trần vàng cấp 1 và 150");
        context.expect(loaded->gold_cap(999) == 100'000'000, "cấp ngoài bảng lấy dòng cuối");
    }
    const std::string v1 = read_text(root + "/shared/item_segment_values.tsv");
    const std::string v_xjl = read_text(root + "/server/item_segment_values_xjl.tsv");
    const std::string v2 = read_text(root + "/server/item_segment_values.tsv");
    const std::string affects = read_text(root + "/server/item_segment_distributions_xjl.tsv");
    const std::string rules = read_text(root + "/server/item_segment_quality_rules_xjl.tsv");
    const std::string apt = read_text(root + "/shared/item_aptitude_rates.tsv");
    const auto rolls = item::RollTables::load({.values_shared = v1, .values_xjl = v_xjl, .values_server = v2, .affects = affects,
        .quality_rules = rules, .apt_rates = apt});
    context.expect(rolls.has_value(), "bảng ItemSeg thật nạp được");
    if (!rolls) {
        std::fprintf(stderr, "%s\n", rolls.error().c_str());
        return;
    }
    // Hợp client (615 đoạn), XJL7457 nhập thêm (1 đoạn: 151) và 0859602 (468 đoạn) có 628 đoạn khác nhau (đếm bằng Python).
    context.expect(rolls->segment_count() == 628, "628 đoạn ItemSegValue sau khi hợp");
    // ItemSegValue[1][max_hp_bonus] = 591 (dòng đầu của cả hai bảng); đoạn 80, thuộc tính 22 (physical_defence) đọc từ tệp.
    context.expect(rolls->segment_value(1, item::AttrId{0}) == 591, "đoạn 1, thuộc tính 0 = 591");
    context.expect(rolls->aptitude_percent(250, item::AttrId{58}) == 20 && rolls->aptitude_percent(1, item::AttrId{58}) == 2,
        "tư chất 250 cộng 20%, tư chất 1 cộng 2%");
#else
    static_cast<void>(context);
#endif
}

constexpr std::array kCases{
    Case{"synthetic_fields", synthetic_fields},
    Case{"rejects_bad_tables", rejects_bad_tables},
    Case{"real_tables_load", real_tables_load},
    Case{"real_limits_and_rolls_load", real_limits_and_rolls_load},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
