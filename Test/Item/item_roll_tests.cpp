// Sinh trang bị: cột ItemSegQuality theo nguồn, phân bố phẩm chất, trọng số thuộc tính, tư chất, ô đá và Factory.
// Hai tầng số: bảng thử dựng tay (số tự đặt, tính tay) và bảng thật (số đọc độc lập từ chính tệp TSV bằng bộ tách
// tab riêng của test, không qua bộ nạp của module).
#include "item_support.hpp"

#include "item/catalog.hpp"
#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/limits.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"
#include "test.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <map>
#include <optional>
#include <set>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using item::Instance;
using item::Origin;
using item::RollContext;
using item::TemplateId;

// ----- đồ phụ ---------------------------------------------------------------------------------------------------

// Bảng ItemSegQuality thử: dòng 1 có ô ở cột c bằng c + 1 (nhìn id biết ngay cột nào được đọc); dòng 2 giống dòng 1
// nhưng cột tách 24 (rèn không nguyên liệu, điểm lắp 5) là -1 và cột gộp 7 là 5.
std::string identity_rules() {
    std::string out = "# schema 1\ncolumn_0";
    for (int i = 1; i <= 190; ++i) out += "\tcolumn_" + std::to_string(i);
    out += "\n";
    for (int rule = 1; rule <= 2; ++rule) {
        std::vector<std::string> cells{std::to_string(rule)};
        for (int c = 0; c < 190; ++c) {
            int value = c + 1;
            if (rule == 2 && c == 24) value = -1;
            if (rule == 2 && c == 7) value = 5;
            cells.push_back(std::to_string(value));
        }
        out += join(cells) + "\n";
    }
    return out;
}

std::string identity_affects() {
    std::string out = "# schema 1\ncolumn_0\ttotal\tc2\tc3\tc4\tc5\tc6\tc7\tc8\tc9\tc10\n";
    for (int id = 1; id <= 191; ++id) out += join({std::to_string(id), "1000", "1000", "0", "0", "0", "0", "0", "0", "0", "0"}) + "\n";
    return out;
}

item::RollTables load_rolls(const std::string& rules, const std::string& affects, const std::string& values = seg_values_table()) {
    auto rolls = item::RollTables::load({.values_shared = values, .values_server = {}, .affects = affects, .quality_rules = rules,
        .apt_rates = apt_table()});
    if (!rolls) {
        std::fprintf(stderr, "load_rolls: %s\n", rolls.error().c_str());
        std::abort();
    }
    return std::move(*rolls);
}

struct Tally {
    std::map<std::uint32_t, std::uint64_t> by_value;
    std::uint64_t total = 0;
};

// Quay `n` lần trang bị `id` và gom giá trị của thuộc tính `attr` (chỉ các lần có thuộc tính đó).
Tally tally_attr(const item::Factory& factory, std::uint32_t id, const RollContext& ctx, std::uint16_t attr, int n,
    std::uint64_t seed) {
    dice::Dice dice(seed);
    item::SerialAllocator serials(1, 1'000'000);
    Tally tally;
    for (int i = 0; i < n; ++i) {
        const auto made = factory.create({.tmpl = TemplateId{id}, .roll = ctx}, dice, serials);
        if (!made) continue;
        for (std::size_t k = 0; k < made->attr_count; ++k) {
            if (made->attrs.at(k).id.value() != attr) continue;
            ++tally.by_value[static_cast<std::uint32_t>(made->attrs.at(k).value)];
            ++tally.total;
        }
    }
    return tally;
}

bool is_affect(const std::optional<std::uint32_t>& got, std::uint32_t want) noexcept { return got.has_value() && *got == want; }

bool near(double actual, double expected, double tolerance) { return std::fabs(actual - expected) <= tolerance; }

double share(const Tally& tally, std::uint32_t value) {
    const auto it = tally.by_value.find(value);
    return tally.total == 0 || it == tally.by_value.end() ? 0.0 : static_cast<double>(it->second) / static_cast<double>(tally.total);
}

// ----- ca thử ---------------------------------------------------------------------------------------------------

void origin_columns(Context& context) {
    const item::RollTables rolls = load_rolls(identity_rules(), identity_affects());
    // Nguồn trực tiếp: cột = giá trị enum, ô = cột + 1.
    const std::array<Origin, 7> direct{Origin::kMonster, Origin::kLeader, Origin::kHeadman, Origin::kChest, Origin::kDungeonBoss,
        Origin::kHourlyBoss, Origin::kDailyBoss};
    for (std::size_t c = 0; c < direct.size(); ++c) {
        const auto affect = rolls.affect_for(1, RollContext{.origin = direct.at(c)}, 0);
        context.expect(is_affect(affect, static_cast<std::uint32_t>(c + 1)), "nguồn trực tiếp đọc đúng cột");
    }
    // Rèn không nguyên liệu: cột tách 19 + điểm lắp (nhãn trong tệp gốc "19-无材料制造_00号装配点").
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 0}, 0), 20), "rèn cấp 0 điểm 0 = cột 19");
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 0}, 18), 38), "rèn cấp 0 điểm 18 = cột 37");
    // Nguyên liệu cấp N: tách 38 + 19 * (N - 1) + điểm.
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 1}, 0), 39), "cấp 1 điểm 0 = cột 38");
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 3}, 18), 38 + 19 * 2 + 18 + 1), "cấp 3 điểm 18");
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 8}, 18), 190), "cấp 8 điểm 18 = cột 189");
    // Điểm lắp ngoài 0..18 không có cột tách: dùng cột gộp (7 cho cấp 0, 8 + cấp cho cấp N).
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 0}, 19), 8), "điểm 19 cấp 0 dùng cột gộp 7");
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 3}, 23), 12), "điểm 23 cấp 3 dùng cột gộp 11");
    // Ô tách là -1 thì lấy ô gộp.
    context.expect(is_affect(rolls.affect_for(2, {.origin = Origin::kForge, .forge_level = 0}, 5), 5), "ô tách -1 lấy ô gộp (giá trị 5)");
    // Cấp ngoài miền bị kẹp về 8 chứ không đọc ngoài mảng; dòng luật lạ và ô -1 không ra gì.
    context.expect(is_affect(rolls.affect_for(1, {.origin = Origin::kForge, .forge_level = 200}, 18), 190), "cấp 200 kẹp về 8");
    context.expect(!rolls.affect_for(3, {}, 0).has_value(), "dòng luật không có");
    context.expect(!rolls.affect_for(1, {.origin = static_cast<Origin>(200)}, 0).has_value(), "nguồn lạ không đọc ngoài mảng");
    const auto weights = rolls.tier_weights(1);
    context.expect(weights.has_value() && weights->at(0) == 1000 && weights->at(8) == 0, "trọng số chín phẩm chất");
    context.expect(!rolls.tier_weights(999).has_value(), "phân bố không có");
}

void segment_lookup(Context& context) {
    const World w = make_world();
    // Đoạn 100..109, thuộc tính a: 1000 + 10 * (đoạn - 100) + a, thuộc tính >= 6 là -1.
    context.expect(w.rolls.segment_value(105, item::AttrId{2}) == 1052, "đoạn 105 thuộc tính 2");
    context.expect(w.rolls.segment_value(100, item::AttrId{0}) == 1000, "đoạn đầu");
    context.expect(w.rolls.segment_value(109, item::AttrId{5}) == 1095, "đoạn cuối");
    context.expect(w.rolls.segment_value(110, item::AttrId{2}) == 1092, "đoạn thiếu lùi về đoạn lớn nhất nhỏ hơn cùng nghìn");
    context.expect(!w.rolls.segment_value(99, item::AttrId{2}).has_value(), "đoạn dưới đoạn đầu không có");
    context.expect(!w.rolls.segment_value(1100, item::AttrId{2}).has_value(), "lùi không vượt sang nghìn khác");
    context.expect(!w.rolls.segment_value(105, item::AttrId{6}).has_value(), "ô -1 không có giá trị");
    context.expect(!w.rolls.segment_value(105, item::AttrId{64}).has_value(), "thuộc tính ngoài miền");
    context.expect(w.rolls.aptitude_percent(100, item::AttrId{58}) == 10, "tư chất 100 = 10%");
    context.expect(w.rolls.aptitude_percent(0, item::AttrId{58}) == 0 && w.rolls.aptitude_percent(256, item::AttrId{58}) == 0,
        "tư chất ngoài 1..255");
    context.expect(w.rolls.aptitude_percent(100, item::AttrId{5}) == 0, "thuộc tính không phải nền");
}

void rejects_bad_roll_tables(Context& context) {
    const std::string values = seg_values_table();
    const std::string affects = seg_affect_table();
    const std::string rules = seg_rules_table();
    const std::string apt = apt_table();
    const auto good = item::RollTables::load({.values_shared = values, .affects = affects, .quality_rules = rules, .apt_rates = apt});
    context.expect(good.has_value(), "bảng thử hợp lệ nạp được");
    context.expect(!item::RollTables::load({.affects = affects, .quality_rules = rules}), "không có đoạn nào phải báo lỗi");
    // Ô luật trỏ tới phân bố không có.
    std::string bad_rules = rules;
    bad_rules.replace(bad_rules.rfind("\t1\n"), 3, "\t9\n");
    const auto dangling = item::RollTables::load({.values_shared = values, .affects = affects, .quality_rules = bad_rules});
    context.expect(!dangling && dangling.error().find("9") != std::string::npos, "luật trỏ phân bố không có");
    // Dòng phân bố toàn 0.
    const std::string zero = "# schema 1\ncolumn_0\ttotal\tc2\tc3\tc4\tc5\tc6\tc7\tc8\tc9\tc10\n1\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\n";
    context.expect(!item::RollTables::load({.values_shared = values, .affects = zero, .quality_rules = rules}), "phân bố không trọng số");
    // Id phân bố không tăng.
    const std::string unsorted = "# schema 1\ncolumn_0\ttotal\tc2\tc3\tc4\tc5\tc6\tc7\tc8\tc9\tc10\n2\t1\t1\t0\t0\t0\t0\t0\t0\t0\t0\n"
                                 "1\t1\t1\t0\t0\t0\t0\t0\t0\t0\t0\n";
    context.expect(!item::RollTables::load({.values_shared = values, .affects = unsorted, .quality_rules = rules}), "id không tăng dần");
    // Thiếu cột và ô chữ.
    context.expect(!item::RollTables::load({.values_shared = "# schema 1\nindex\tc1\n1\t2\n", .affects = affects, .quality_rules = rules}),
        "đoạn thiếu cột");
    std::string letters = values;
    letters.replace(letters.find("1000"), 4, "10x0");
    context.expect(!item::RollTables::load({.values_shared = letters, .affects = affects, .quality_rules = rules}), "ô đoạn không phải số");
    // Cột "bảo lưu" không bị kiểm miền: giá trị lạ ở cột 59..64 không làm hỏng bảng.
    std::string reserved = "# schema 1\nindex";
    for (int i = 1; i <= 64; ++i) reserved += "\tcolumn_" + std::to_string(i);
    reserved += "\n";
    std::vector<std::string> row{"7"};
    for (int i = 0; i < 64; ++i) row.push_back(i >= 58 ? "-11121" : "5");
    reserved += join(row) + "\n";
    const auto lenient = item::RollTables::load({.values_shared = reserved, .affects = affects, .quality_rules = rules});
    context.expect(lenient.has_value(), "cột bảo lưu chấp nhận giá trị lạ");
    context.expect(lenient && lenient->segment_value(7, item::AttrId{3}) == 5 && !lenient->segment_value(7, item::AttrId{60}).has_value(),
        "cột bảo lưu không thành giá trị thuộc tính");
}

void tier_distribution(Context& context) {
    const World w = make_world();
    const item::Factory factory(w.catalog, w.rolls);
    // Nhẫn lam kBlueRing dùng luật 2: nguồn quái thường (cột 0) -> phân bố 2 = 50% độ lệch 0 và 50% độ lệch 8; mọi
    // nguồn khác -> phân bố 1 = luôn độ lệch 0. Giá trị thuộc tính 0 = 1000 + 10 * độ lệch.
    const Tally monster = tally_attr(factory, kBlueRing, {.origin = Origin::kMonster}, 0, 30000, 11);
    context.expect(monster.total > 10000, "đủ mẫu thuộc tính 0 (xác suất có mặt khoảng 41,7%)");
    context.expect(monster.by_value.size() == 2, "chỉ hai giá trị 1000 và 1080");
    context.expect(near(share(monster, 1000), 0.5, 0.015) && near(share(monster, 1080), 0.5, 0.015), "quái thường chia đôi hai phẩm chất");
    const Tally leader = tally_attr(factory, kBlueRing, {.origin = Origin::kLeader}, 0, 5000, 12);
    context.expect(leader.total > 1500 && leader.by_value.size() == 1 && share(leader, 1000) == 1.0, "thủ lĩnh luôn phẩm chất 1");
    const Tally forge = tally_attr(factory, kBlueRing, {.origin = Origin::kForge, .forge_level = 5}, 0, 5000, 13);
    context.expect(forge.total > 1500 && share(forge, 1000) == 1.0, "rèn dùng cột khác cột quái");
}

void attribute_selection(Context& context) {
    // Thêm các nhẫn lam thử: (a) trọng số 9:1 giữa thuộc tính 0 và 1, đúng một thuộc tính; (b) đòi 5 thuộc tính chỉ có
    // 2 có trọng số; (c) luật 0 (không sinh); (d) không có đoạn gốc; (e) luật không có trong bảng.
    const std::uint32_t k91 = 10200101, kShort = 10200102, kNoRule = 10200103, kNoBand = 10200104, kMissingRule = 10200105;
    const World w = make_world({
        EquipRow{.id = k91, .quality = 2, .point = 6, .seg_rule = 1, .band_start = 100, .attr_min = 1, .attr_max = 1,
            .weights = {{0, 9}, {1, 1}}},
        EquipRow{.id = kShort, .quality = 2, .point = 6, .seg_rule = 1, .band_start = 100, .attr_min = 5, .attr_max = 5,
            .weights = {{0, 3}, {1, 3}}},
        EquipRow{.id = kNoRule, .quality = 2, .point = 6, .seg_rule = 0, .band_start = 100, .attr_min = 2, .attr_max = 2,
            .weights = {{0, 1}, {1, 1}}},
        EquipRow{.id = kNoBand, .quality = 2, .point = 6, .seg_rule = 1, .band_start = -1, .attr_min = 2, .attr_max = 2,
            .weights = {{0, 1}, {1, 1}}},
        EquipRow{.id = kMissingRule, .quality = 2, .point = 6, .seg_rule = 77, .band_start = 100, .attr_min = 2, .attr_max = 2,
            .weights = {{0, 1}, {1, 1}}},
    });
    const item::Factory factory(w.catalog, w.rolls);
    dice::Dice dice(21);
    item::SerialAllocator serials(1, 1'000'000);
    std::uint64_t zero = 0;
    std::uint64_t one = 0;
    for (int i = 0; i < 20000; ++i) {
        const auto made = factory.create({.tmpl = TemplateId{k91}}, dice, serials);
        context.expect(made.has_value() && made->attr_count == 1, "đúng một thuộc tính");
        if (!made || made->attr_count != 1) return;
        (made->attrs.at(0).id.value() == 0 ? zero : one) += 1;
        context.expect(made->attrs.at(0).id.value() <= 1, "thuộc tính nằm trong tập trọng số");
    }
    context.expect(near(static_cast<double>(zero) / 20000.0, 0.9, 0.012), "trọng số 9:1 ra khoảng 90%");
    static_cast<void>(one);
    for (int i = 0; i < 200; ++i) {
        const auto made = factory.create({.tmpl = TemplateId{kShort}}, dice, serials);
        context.expect(made.has_value() && made->attr_count == 2, "đòi 5 chỉ có 2 trọng số: ra đúng 2");
        context.expect(made && made->attr_count == 2 && made->attrs.at(0).id != made->attrs.at(1).id, "hai thuộc tính khác nhau");
        const auto none = factory.create({.tmpl = TemplateId{kNoRule}}, dice, serials);
        context.expect(none.has_value() && none->attr_count == 0 && none->identified, "luật 0: không thuộc tính, đã giám định");
        const auto no_band = factory.create({.tmpl = TemplateId{kNoBand}}, dice, serials);
        context.expect(no_band.has_value() && no_band->attr_count == 0, "không đoạn gốc: không thuộc tính");
        const auto no_rule = factory.create({.tmpl = TemplateId{kMissingRule}}, dice, serials);
        context.expect(no_rule.has_value() && no_rule->attr_count == 2, "luật không có trong bảng: phẩm chất thấp nhất");
    }
}

void aptitude_and_count(Context& context) {
    const World w = make_world();
    const item::Factory factory(w.catalog, w.rolls);
    dice::Dice dice(31);
    item::SerialAllocator serials(1, 1'000'000);
    std::uint64_t two = 0;
    std::uint64_t three = 0;
    for (int i = 0; i < 20000; ++i) {
        const auto made = factory.create({.tmpl = TemplateId{kBlueRing}}, dice, serials);
        if (!made) {
            context.expect(false, "tạo nhẫn lam");
            return;
        }
        // Tư chất 100 cố định (apt_min = apt_max): nền 200 * 10% = 20 cho thuộc tính 58 và 59.
        context.expect(made->aptitude == 100, "tư chất theo khoảng của dòng");
        std::size_t base_attrs = 0;
        std::size_t random_attrs = 0;
        for (std::size_t k = 0; k < made->attr_count; ++k) {
            const item::AttrId id = made->attrs.at(k).id;
            if (id.value() >= item::kAttrBasePhysicalAttack) {
                ++base_attrs;
                context.expect(made->attrs.at(k).value == 20 && id.value() <= 59, "cộng tư chất = nền * 10 / 100");
            } else {
                ++random_attrs;
            }
        }
        context.expect(base_attrs == 2, "hai thuộc tính nền có giá trị -> hai dòng cộng tư chất");
        (random_attrs == 2 ? two : three) += (random_attrs == 2 || random_attrs == 3) ? 1 : 0;
        context.expect(random_attrs == 2 || random_attrs == 3, "số thuộc tính ngẫu nhiên trong [2, 3]");
        context.expect(!made->identified, "đồ lam có thuộc tính chưa giám định");
    }
    context.expect(near(static_cast<double>(two) / 20000.0, 0.5, 0.015), "hai hay ba thuộc tính đều khoảng một nửa");
    static_cast<void>(three);
}

void gem_slot_distribution(Context& context) {
    // Đồ lam có cột MaxGem là trần; số ô thật theo ngưỡng viết cứng của 2008 (ItemCreateRuler): trần 3 -> 0: 40%, 1: 40%,
    // 2: 16%, 3: 4%; trần 2 -> 0: 60%, 1: 30%, 2: 10%; trần 1 -> 1: 20%.
    const std::uint32_t k1 = 10200111, k2 = 10200112;
    const World w = make_world({
        EquipRow{.id = k1, .quality = 2, .point = 6, .gem_slots = 1},
        EquipRow{.id = k2, .quality = 2, .point = 6, .gem_slots = 2},
    });
    const item::Factory factory(w.catalog, w.rolls);
    dice::Dice dice(41);
    item::SerialAllocator serials(1, 10'000'000);
    const auto histogram = [&](std::uint32_t id) {
        std::array<std::uint64_t, 4> counts{};
        for (int i = 0; i < 40000; ++i) {
            const auto made = factory.create({.tmpl = TemplateId{id}}, dice, serials);
            if (made && made->gem_slots < counts.size()) ++counts.at(made->gem_slots);
        }
        return counts;
    };
    const auto frac = [](const std::array<std::uint64_t, 4>& counts, std::size_t i) { return static_cast<double>(counts.at(i)) / 40000.0; };
    const auto three = histogram(kBlueRing);
    context.expect(near(frac(three, 0), 0.40, 0.012) && near(frac(three, 1), 0.40, 0.012) && near(frac(three, 2), 0.16, 0.01) &&
            near(frac(three, 3), 0.04, 0.006),
        "trần 3 ô: 40/40/16/4");
    const auto two = histogram(k2);
    context.expect(near(frac(two, 0), 0.60, 0.012) && near(frac(two, 1), 0.30, 0.012) && near(frac(two, 2), 0.10, 0.008), "trần 2 ô: 60/30/10");
    const auto one = histogram(k1);
    context.expect(near(frac(one, 1), 0.20, 0.01) && near(frac(one, 0), 0.80, 0.01), "trần 1 ô: 80/20");
    // Đồ trắng lấy thẳng số ô từ bảng.
    const auto sword = factory.create({.tmpl = TemplateId{kSword}}, dice, serials);
    context.expect(sword.has_value() && sword->gem_slots == 0, "đồ trắng không quay ô đá");
}

void factory_contract(Context& context) {
    const World w = make_world();
    const item::Factory factory(w.catalog, w.rolls);
    dice::Dice dice(51);
    item::SerialAllocator serials(100, 103);
    const auto potion = factory.create({.tmpl = TemplateId{kPotion}, .count = 7}, dice, serials);
    context.expect(potion.has_value() && potion->count == 7 && potion->serial.value() == 100 && !potion->bound, "thuốc: số lượng và serial");
    context.expect(!factory.create({.tmpl = TemplateId{kPotion}, .count = 0}, dice, serials), "số lượng 0");
    context.expect(!factory.create({.tmpl = TemplateId{kPotion}, .count = 21}, dice, serials), "vượt cỡ chồng");
    context.expect(factory.create({.tmpl = TemplateId{4}}, dice, serials).error() == item::Error::kUnknownTemplate, "mẫu lạ");
    context.expect(factory.create({.tmpl = TemplateId{kBlueRing}, .roll = {.origin = Origin::kForge, .forge_level = 9}}, dice, serials)
                       .error() == item::Error::kBadOrigin,
        "cấp rèn 9 bị từ chối");
    context.expect(serials.cursor() == 101, "lỗi không làm mất serial");
    const auto bound = factory.create({.tmpl = TemplateId{kPickBound}, .picked = true}, dice, serials);
    const auto kept = factory.create({.tmpl = TemplateId{kPickBound}, .picked = false}, dice, serials);
    context.expect(bound.has_value() && bound->bound, "đồ khoá-khi-nhặt khoá khi nhặt");
    context.expect(kept.has_value() && !kept->bound, "không khoá khi không nhặt");
    context.expect(factory.create({.tmpl = TemplateId{kPotion}}, dice, serials).error() == item::Error::kSerialsExhausted, "hết khối serial");
    context.expect(serials.remaining() == 0, "khối serial cạn");
    // Trang bị trắng: độ bền đầy, đã giám định, không thuộc tính; hai thể hiện có serial khác nhau.
    item::SerialAllocator more(1000, 1010);
    const auto sword = factory.create({.tmpl = TemplateId{kSword}}, dice, more);
    const auto sword2 = factory.create({.tmpl = TemplateId{kSword}}, dice, more);
    context.expect(sword.has_value() && sword->durability == 100 && sword->identified && sword->attr_count == 0, "kiếm trắng nguyên vẹn");
    context.expect(sword && sword2 && sword->serial != sword2->serial && sword->expires_at == 0, "serial khác nhau, không hạn dùng");
}

void expiry(Context& context) {
    const World w = make_world();
    const std::string extra = "# schema 1\nindex\tduration_hours\n10100001\t24\n";
    auto catalog = item::Catalog::load({.rules = w.rules, .common = w.common, .equipment = w.equipment, .gems = w.gems, .extra_attributes = extra});
    context.expect(catalog.has_value(), "nạp thời hạn");
    if (!catalog) return;
    const item::Factory factory(*catalog, w.rolls);
    dice::Dice dice(61);
    item::SerialAllocator serials(1, 100);
    const auto made = factory.create({.tmpl = TemplateId{kSword}, .now = ids::Tick{1000}}, dice, serials);
    // 24 giờ = 86400 giây = 1.728.000 tick ở 20 tick mỗi giây.
    context.expect(made.has_value() && made->expires_at == 1000 + 24 * 3600 * item::kTicksPerSecond, "hạn dùng theo tick");
}

// ----- bảng thật -------------------------------------------------------------------------------------------------

#ifdef GAME_SERVER_TABLES
void real_affect_ids(Context& context) {
    const auto real = load_real(context);
    if (!real) return;
    const item::RollTables& rolls = real->rolls;
    // Số đọc bằng Python từ item_segment_quality_rules_xjl.tsv: dòng 17.
    const std::array<std::uint32_t, 7> direct{17, 27, 37, 47, 57, 67, 77};
    const std::array<Origin, 7> origins{Origin::kMonster, Origin::kLeader, Origin::kHeadman, Origin::kChest, Origin::kDungeonBoss,
        Origin::kHourlyBoss, Origin::kDailyBoss};
    for (std::size_t i = 0; i < direct.size(); ++i) {
        context.expect(is_affect(rolls.affect_for(17, {.origin = origins.at(i)}, 0), direct.at(i)), "dòng 17, nguồn trực tiếp");
    }
    // Rèn không nguyên liệu: nhẫn (6) 247, bùa (12) 197, điểm 14 là 397, điểm 15 là 137, các điểm khác 87.
    struct PointCase {
        std::uint8_t point;
        std::uint32_t affect;
    };
    const std::array<PointCase, 6> forge0{{{0, 87}, {6, 247}, {12, 197}, {14, 397}, {15, 137}, {18, 87}}};
    for (const PointCase& c : forge0) {
        context.expect(is_affect(rolls.affect_for(17, {.origin = Origin::kForge, .forge_level = 0}, c.point), c.affect), "rèn cấp 0 theo điểm lắp");
    }
    context.expect(is_affect(rolls.affect_for(17, {.origin = Origin::kForge, .forge_level = 3}, 0), 503), "cấp 3 điểm 0 dùng cột tách");
    context.expect(is_affect(rolls.affect_for(17, {.origin = Origin::kForge, .forge_level = 1}, 19), 97), "cấp 1 điểm 19 dùng cột gộp");
    context.expect(is_affect(rolls.affect_for(17, {.origin = Origin::kForge, .forge_level = 3}, 19), 117), "cấp 3 điểm 19 dùng cột gộp");
    const auto monster = rolls.tier_weights(17);
    const auto boss = rolls.tier_weights(57);
    const auto forged = rolls.tier_weights(97);
    context.expect(monster == std::array<std::uint32_t, 9>{84703, 14286, 1000, 10, 1, 0, 0, 0, 0}, "phân bố 17");
    context.expect(boss == std::array<std::uint32_t, 9>{79478, 20000, 500, 20, 2, 0, 0, 0, 0}, "phân bố 57");
    context.expect(forged == std::array<std::uint32_t, 9>{0, 0, 1000, 2000, 2000, 2000, 1800, 300, 30}, "phân bố 97 (tổng 10000 > tổng trọng số)");
}

void real_blue_distribution(Context& context) {
    const auto real = load_real(context);
    if (!real) return;
    const item::Factory factory(real->catalog, real->rolls);
    // 10200008: luật 17, đoạn gốc 80, 3..6 thuộc tính, tư chất 1..250, nền 713/713. Thuộc tính 19 (physical_attack) có
    // trọng số 2/15; giá trị đoạn 80..84 = 893, 903, 914, 925, 935 (đọc từ shared/item_segment_values.tsv).
    const Tally monster = tally_attr(factory, 10200008, {.origin = Origin::kMonster}, 19, 40000, 71);
    context.expect(monster.total > 10000, "đủ mẫu physical_attack");
    context.expect(near(share(monster, 893), 0.84703, 0.012) && near(share(monster, 903), 0.14286, 0.01) && near(share(monster, 914), 0.01, 0.004),
        "quái thường: 84,7% / 14,3% / 1%");
    context.expect(share(monster, 893) + share(monster, 903) + share(monster, 914) + share(monster, 925) + share(monster, 935) > 0.9999,
        "mọi giá trị thuộc 5 phẩm chất đầu");
    const Tally boss = tally_attr(factory, 10200008, {.origin = Origin::kDungeonBoss}, 19, 40000, 72);
    context.expect(near(share(boss, 893), 0.79478, 0.012) && near(share(boss, 903), 0.2, 0.01) && near(share(boss, 914), 0.005, 0.003),
        "BOSS phó bản: 79,5% / 20% / 0,5%");

    // Kiểm từng thể hiện bằng số tự đọc từ tệp: mọi giá trị ngẫu nhiên là một ô của đoạn 80..88; tư chất trong 1..250 và
    // phần cộng nền = nền * tỉ lệ ItemAptRate / 100.
    const auto values = tsv_rows(real->v_client);
    std::map<int, const std::vector<std::string>*> by_segment;
    for (std::size_t i = 1; i < values.size(); ++i) by_segment[std::stoi(values[i][0])] = &values[i];
    const auto apt = tsv_rows(real->apt);
    dice::Dice dice(73);
    item::SerialAllocator serials(1, 10'000'000);
    int distinct_failures = 0;
    for (int n = 0; n < 4000; ++n) {
        const auto made = factory.create({.tmpl = TemplateId{10200008}}, dice, serials);
        context.expect(made.has_value(), "tạo 10200008");
        if (!made) return;
        std::set<std::uint16_t> seen;
        for (std::size_t k = 0; k < made->attr_count; ++k) {
            const item::AttrValue& a = made->attrs.at(k);
            distinct_failures += seen.insert(a.id.value()).second ? 0 : 1;
            if (a.id.value() >= item::kAttrBasePhysicalAttack) continue;
            bool allowed = false;
            for (int seg = 80; seg <= 88; ++seg) {
                allowed = allowed || std::stoi((*by_segment.at(seg))[static_cast<std::size_t>(a.id.value()) + 1]) == a.value;
            }
            context.expect(allowed, "giá trị ngẫu nhiên thuộc đoạn 80..88");
        }
        context.expect(made->aptitude >= 1 && made->aptitude <= 250, "tư chất 1..250");
        const auto& rates = apt.at(made->aptitude);  // dòng 0 là tiêu đề nên chỉ số = tư chất
        for (std::size_t k = 0; k < made->attr_count; ++k) {
            const item::AttrValue& a = made->attrs.at(k);
            if (a.id.value() == 58) context.expect(a.value == 713 * std::stoi(rates[1]) / 100, "phần cộng tư chất cho tấn công vật lý");
            if (a.id.value() == 59) context.expect(a.value == 713 * std::stoi(rates[3]) / 100, "phần cộng tư chất cho tấn công phép");
        }
    }
    context.expect(distinct_failures == 0, "không thuộc tính trùng");
}

void real_every_equipment_rolls(Context& context) {
    const auto real = load_real(context);
    if (!real) return;
    const item::Factory factory(real->catalog, real->rolls);
    dice::Dice dice(81);
    item::SerialAllocator serials(1, 10'000'000'000ULL);
    const std::array<RollContext, 5> contexts{{{.origin = Origin::kMonster}, {.origin = Origin::kChest}, {.origin = Origin::kDailyBoss},
        {.origin = Origin::kForge, .forge_level = 0}, {.origin = Origin::kForge, .forge_level = 8}}};
    std::uint64_t made_count = 0;
    std::uint64_t failures = 0;
    for (const item::Template& t : real->catalog.all()) {
        if (t.kind != item::Kind::kEquipment) continue;
        for (const RollContext& ctx : contexts) {
            const auto made = factory.create({.tmpl = t.id, .roll = ctx}, dice, serials);
            if (!made || made->attr_count > item::kMaxAttrs || made->durability != t.equip.max_durability) {
                ++failures;
                continue;
            }
            ++made_count;
        }
    }
    context.expect(failures == 0, "mọi trang bị trong bảng thật sinh được với mọi nguồn");
    context.expect(made_count > 100000, "đã thử cả 24577 trang bị x 5 nguồn");
}
#endif

void real_tables_cases(Context& context) {
#ifdef GAME_SERVER_TABLES
    real_affect_ids(context);
    real_blue_distribution(context);
    real_every_equipment_rolls(context);
#else
    static_cast<void>(context);
#endif
}

constexpr std::array kCases{
    Case{"origin_columns", origin_columns},
    Case{"segment_lookup", segment_lookup},
    Case{"rejects_bad_roll_tables", rejects_bad_roll_tables},
    Case{"tier_distribution", tier_distribution},
    Case{"attribute_selection", attribute_selection},
    Case{"aptitude_and_count", aptitude_and_count},
    Case{"gem_slot_distribution", gem_slot_distribution},
    Case{"factory_contract", factory_contract},
    Case{"expiry", expiry},
    Case{"real_tables_cases", real_tables_cases},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
