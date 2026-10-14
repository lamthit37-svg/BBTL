// Đồ phụ cho test của lõi vật phẩm: dựng bảng TSV nhỏ trong bộ nhớ (luật, đồ thường, trang bị, đá quý, bảng ItemSeg)
// để mỗi ca tự đứng được, không phụ thuộc dev/server/tables. Số ở đây là số của TEST, đặt tường minh; số thật nằm ở
// bảng và được kiểm riêng bằng ca đọc bảng thật (item_catalog_tests).
#pragma once

#include "item/catalog.hpp"
#include "item/codec.hpp"
#include "item/factory.hpp"
#include "item/inventory.hpp"
#include "item/limits.hpp"
#include "item/planner.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"

#include "test.hpp"

#include "dice/dice.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iterator>
#include <map>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {

// Id mẫu của thế giới thử.
inline constexpr std::uint32_t kPotion = 30000001;      // thuốc, chồng 20, túi đạo cụ
inline constexpr std::uint32_t kUniqueRing = 30000002;  // đồ duy nhất
inline constexpr std::uint32_t kHerb = 20100001;        // nguyên liệu, chồng 250, túi nguyên liệu
inline constexpr std::uint32_t kQuestItem = 40000001;   // nhiệm vụ, chồng 99, túi nhiệm vụ
inline constexpr std::uint32_t kSword = 10100001;       // kiếm trắng, cấp 10, khoá khi mặc
inline constexpr std::uint32_t kSectSword = 10100002;   // kiếm cấp 20 chỉ phái 3
inline constexpr std::uint32_t kWhiteRing = 10100003;   // nhẫn trắng, điểm lắp 6
inline constexpr std::uint32_t kBlueRing = 10200001;    // nhẫn lam, điểm lắp 6, sinh ngẫu nhiên
inline constexpr std::uint32_t kCharm = 10100004;       // bùa, điểm lắp 12
inline constexpr std::uint32_t kGem = 50101001;         // đá quý, +10 tấn công vật lý
inline constexpr std::uint32_t kPickBound = 30000003;   // đồ khoá khi nhặt
inline constexpr std::uint32_t kNoSell = 30000004;      // đồ không bán được
inline constexpr std::uint32_t kUnknownItem = 99999999;  // không có trong catalog: thử mã lạ của bảng

inline std::string join(const std::vector<std::string>& cells) {
    std::string line;
    for (std::size_t i = 0; i < cells.size(); ++i) {
        if (i != 0) line += '\t';
        line += cells[i];
    }
    return line;
}

inline std::string rules_table() {
    // index discard tile shortcut sell exchange use pickbind equipbind unique + 5 cột client thêm
    const std::vector<std::array<int, 10>> rows{
        {1, 0, 0, 0, 0, 0, 0, 0, 0, 0},  // 1: không gì cả
        {2, 1, 0, 0, 1, 1, 1, 0, 1, 0},  // 2: trang bị khoá khi mặc
        {5, 1, 1, 1, 1, 1, 1, 0, 0, 0},  // 5: đồ chồng bán được
        {6, 1, 1, 0, 0, 1, 1, 0, 0, 0},  // 6: đồ chồng không bán
        {7, 1, 0, 0, 1, 1, 1, 0, 0, 1},  // 7: duy nhất
        {8, 1, 0, 0, 1, 1, 1, 1, 0, 0},  // 8: khoá khi nhặt
        {9, 1, 0, 0, 0, 1, 1, 0, 0, 0},  // 9: không bán
    };
    std::string out = "# schema 1\nindex\tcolumn_1\tcolumn_2\tcolumn_3\tcolumn_4\tcolumn_5\tcolumn_6\tcolumn_7\tcolumn_8\tcolumn_9"
                      "\tcolumn_10\tcolumn_11\tcolumn_12\tcolumn_13\tcolumn_14\n";
    for (const auto& row : rows) {
        std::vector<std::string> cells;
        for (const int v : row) cells.push_back(std::to_string(v));
        for (int i = 0; i < 5; ++i) cells.emplace_back("0");
        out += join(cells) + "\n";
    }
    return out;
}

struct CommonRow {
    std::uint32_t id = 0;
    int item_class = 3;
    int quality = 0;
    int type = 0;
    int level = 1;
    int base_price = 100;
    int sale_price = 10;
    int rule = 5;
    int tile = 20;
    int max_owned = -1;
};

inline std::string common_table(const std::vector<CommonRow>& rows) {
    std::string out = "# schema 1\nindex\tclass\tquality\ttype\tmedindex\tresource_id\tname\tcolumn_7\tlevel\tbase_price\tsale_price"
                      "\tfit_rules\tcolumn_12\tcolumn_13\tcolumn_14\trequired_skill\trequired_skill_level\tmax_owned"
                      "\ttarget_object_type\ttype_description\tgrade\trecipe_id\tcolor\tsub_class\tcolumn_24\tcolumn_25\tcolumn_26\tis_consumed\n";
    for (const CommonRow& r : rows) {
        out += join({std::to_string(r.id), std::to_string(r.item_class), std::to_string(r.quality), std::to_string(r.type), "0",
                   "icon", "ten", "ten", std::to_string(r.level), std::to_string(r.base_price), std::to_string(r.sale_price),
                   std::to_string(r.rule), std::to_string(r.tile), "-1", "-1", "8", "1", std::to_string(r.max_owned), "-1",
                   "mota", "1", "0", "2000", "-1", "0", "0", "1", "1"})
            + "\n";
    }
    return out;
}

struct EquipRow {
    std::uint32_t id = 0;
    int quality = 1;
    int point = 0;
    int rule = 2;
    int level = 1;
    int sect = -1;
    int base_price = 1000;
    int max_durability = 100;
    int max_repairs = 3;
    int gem_slots = 0;
    std::array<int, 6> base{-1, -1, -1, -1, -1, -1};  // theo id thuộc tính 58..63
    int seg_rule = 1;
    int band_start = -1;
    int attr_min = 0;
    int attr_max = 0;
    int apt_min = 0;
    int apt_max = 0;
    std::map<int, int> weights{};  // id thuộc tính (0..57) -> trọng số
};

inline std::string equipment_header() {
    std::vector<std::string> head{"index_1", "class", "quality", "type", "index_2", "equip_point", "visual", "column_7", "set_id",
        "set_effect_value", "name", "lv", "required_sect", "column_13", "base_price", "sale_price", "max_durability",
        "column_17", "icon", "type_description", "column_20", "column_21", "column_22", "column_23"};
    const auto names = item::attr_names();
    for (std::size_t i = item::kRollableAttrs; i < item::kAttrCount; ++i) head.emplace_back(names.at(i));
    for (std::size_t i = 0; i < item::kRollableAttrs; ++i) head.emplace_back(names.at(i));
    for (const char* tail : {"quality_rules", "value_band_start", "attribute_count_min", "attribute_count_max", "aptitude_min",
             "aptitude_max", "upgraded_resource_id", "bag_slots", "box_slots", "is_broadcast", "roll_span", "tier", "column_100",
             "column_101", "column_102"}) {
        head.emplace_back(tail);
    }
    return join(head);
}

inline std::string equipment_table(const std::vector<EquipRow>& rows) {
    std::string out = "# schema 1\n" + equipment_header() + "\n";
    for (const EquipRow& r : rows) {
        std::vector<std::string> c{std::to_string(r.id), "1", std::to_string(r.quality), "0", "0", std::to_string(r.point), "1",
            std::to_string(r.rule), "-1", "-1", "ten", std::to_string(r.level), std::to_string(r.sect), "mota",
            std::to_string(r.base_price), std::to_string(r.base_price * 8 / 10), std::to_string(r.max_durability),
            std::to_string(r.max_repairs), "icon", "loai", "0", "0", "0", "-1"};
        for (const int b : r.base) c.push_back(std::to_string(b));
        for (int a = 0; std::cmp_less(a, item::kRollableAttrs); ++a) {
            const auto it = r.weights.find(a);
            c.push_back(std::to_string(it == r.weights.end() ? -1 : it->second));
        }
        for (const int v : {r.seg_rule, r.band_start, r.attr_min, r.attr_max, r.apt_min, r.apt_max, -1, 0, 0, 0, -1, -1, r.gem_slots, -1, -1}) {
            c.push_back(std::to_string(v));
        }
        out += join(c) + "\n";
    }
    return out;
}

inline std::string gem_table() {
    std::vector<std::string> head{"index", "class", "quality", "type", "gem_index", "resource_id", "fit_rules", "name", "column_8",
        "base_price", "sale_price"};
    const auto names = item::attr_names();
    for (std::size_t i = 0; i < item::kRollableAttrs; ++i) head.emplace_back(names.at(i));
    for (const char* tail : {"base_physical_attack", "base_magic_attack", "base_hit", "base_physical_defence", "base_magic_defence",
             "base_miss", "color_rgba", "type_description", "effect_index"}) {
        head.emplace_back(tail);
    }
    std::vector<std::string> row{std::to_string(kGem), "5", "1", "1", "1", "icon", "5", "da", "mota", "1000", "100"};
    for (std::size_t i = 0; i < item::kRollableAttrs; ++i) row.emplace_back(i == 19 ? "10" : "-1");  // physical_attack
    for (const char* tail : {"-1", "-1", "-1", "-1", "-1", "-1", "FFFFFF09", "loai", "1"}) row.emplace_back(tail);
    return "# schema 1\n" + join(head) + "\n" + join(row) + "\n";
}

// ItemSeg thử: đoạn 100..109 có giá trị thuộc tính 0..5 = 1000 + 10*đoạn_lệch + thuộc_tính (dễ nhận ra), hai dòng
// ItemSegAffect: 1 -> độ lệch luôn 0; 2 -> độ lệch 0 hay 8 đều 50%. Dòng quality_rules 1 dùng affect 1 cho mọi cột;
// quality_rules 2 dùng affect 2 cho cột 0 và affect 1 cho các cột còn lại.
inline std::string seg_values_table() {
    std::string out = "# schema 1\nindex";
    for (int i = 1; i <= 64; ++i) out += "\tcolumn_" + std::to_string(i);
    out += "\n";
    for (int segment = 100; segment <= 109; ++segment) {
        std::vector<std::string> c{std::to_string(segment)};
        for (int attr = 0; attr < 64; ++attr) {
            c.push_back(attr < 6 ? std::to_string(1000 + 10 * (segment - 100) + attr) : "-1");
        }
        out += join(c) + "\n";
    }
    return out;
}

inline std::string seg_affect_table() {
    return "# schema 1\ncolumn_0\ttotal\tc2\tc3\tc4\tc5\tc6\tc7\tc8\tc9\tc10\n"
           "1\t1000\t1000\t0\t0\t0\t0\t0\t0\t0\t0\n"
           "2\t1000\t500\t0\t0\t0\t0\t0\t0\t0\t500\n";
}

inline std::string seg_rules_table() {
    std::string out = "# schema 1\ncolumn_0";
    for (int i = 1; i <= 190; ++i) out += "\tcolumn_" + std::to_string(i);
    out += "\n";
    std::vector<std::string> one{"1"};
    for (int i = 0; i < 190; ++i) one.emplace_back("1");
    std::vector<std::string> two{"2"};
    for (int i = 0; i < 190; ++i) two.emplace_back(i == 0 ? "2" : "1");
    return out + join(one) + "\n" + join(two) + "\n";
}

inline std::string apt_table() {
    std::string out = "# schema 1\naptitude_point\tphysical_attack\tphysical_defence\tmagic_attack\tmagic_defence\tmiss\thit\n";
    for (int apt = 1; apt <= 255; ++apt) {
        const std::string v = std::to_string(apt / 10);  // 1 điểm tư chất = 0,1% (thử)
        out += join({std::to_string(apt), v, v, v, v, v, v}) + "\n";
    }
    return out;
}

struct World {
    std::string rules, common, equipment, gems, seg_values, seg_affects, seg_rules, apt;
    item::Catalog catalog;
    item::RollTables rolls;
    item::Limits limits = item::Limits::defaults();
};

[[nodiscard]] inline World make_world(const std::vector<EquipRow>& extra_equipment = {}) {
    World w;
    w.rules = rules_table();
    w.common = common_table({
        CommonRow{.id = kPotion, .item_class = 3, .rule = 5, .tile = 20},
        CommonRow{.id = kUniqueRing, .item_class = 3, .rule = 7, .tile = 1},
        CommonRow{.id = kHerb, .item_class = 2, .base_price = 375, .rule = 5, .tile = 250},
        CommonRow{.id = kQuestItem, .item_class = 4, .rule = 6, .tile = 99},
        CommonRow{.id = kPickBound, .item_class = 3, .rule = 8, .tile = 1},
        CommonRow{.id = kNoSell, .item_class = 3, .rule = 9, .tile = 1},
    });
    std::vector<EquipRow> eq{
        EquipRow{.id = kSword, .quality = 1, .point = 0, .rule = 2, .level = 10, .base = {500, 500, -1, -1, -1, -1}},
        EquipRow{.id = kSectSword, .quality = 1, .point = 0, .rule = 2, .level = 20, .sect = 3},
        EquipRow{.id = kWhiteRing, .quality = 1, .point = 6, .rule = 2, .level = 1},
        EquipRow{.id = kCharm, .quality = 1, .point = 12, .rule = 2, .level = 1},
        EquipRow{.id = kBlueRing, .quality = 2, .point = 6, .rule = 2, .level = 1, .gem_slots = 3,
            .base = {200, 200, -1, -1, -1, -1}, .seg_rule = 2, .band_start = 100, .attr_min = 2, .attr_max = 3,
            .apt_min = 100, .apt_max = 100, .weights = {{0, 1}, {1, 1}, {2, 1}, {3, 1}, {4, 1}, {5, 1}}},
    };
    for (const EquipRow& r : extra_equipment) eq.push_back(r);
    w.equipment = equipment_table(eq);
    w.gems = gem_table();
    w.seg_values = seg_values_table();
    w.seg_affects = seg_affect_table();
    w.seg_rules = seg_rules_table();
    w.apt = apt_table();
    auto catalog = item::Catalog::load({.rules = w.rules, .common = w.common, .equipment = w.equipment, .gems = w.gems, .pet_equipment = {}, .extra_attributes = {}});
    if (!catalog) {
        std::fprintf(stderr, "make_world: catalog: %s\n", catalog.error().c_str());
        std::abort();
    }
    w.catalog = std::move(*catalog);
    auto rolls = item::RollTables::load({.values_shared = w.seg_values, .values_xjl = {}, .values_server = {}, .affects = w.seg_affects,
        .quality_rules = w.seg_rules, .apt_rates = w.apt});
    if (!rolls) {
        std::fprintf(stderr, "make_world: rolls: %s\n", rolls.error().c_str());
        std::abort();
    }
    w.rolls = std::move(*rolls);
    return w;
}

// Nội dung của trạng thái: nối các khối mã hoá của túi, trang bị, kho và ví. Hai Inventory cùng nội dung thì giống nhau
// từng byte ở mọi thứ được lưu (không gồm revision và khoá ô, vốn không lưu).
[[nodiscard]] inline std::vector<std::byte> contents(const item::Inventory& inventory) {
    std::vector<std::byte> out;
    for (const auto& blob : {item::encode_bags(inventory), item::encode_equipment(inventory), item::encode_bank(inventory),
             item::encode_wallet(inventory)}) {
        if (!blob) std::abort();
        out.insert(out.end(), blob->begin(), blob->end());
    }
    return out;
}

// Dấu vân tay = nội dung + revision: dùng để chứng minh thao tác bị từ chối không để lại gì.
[[nodiscard]] inline std::vector<std::byte> fingerprint(const item::Inventory& inventory) {
    std::vector<std::byte> out = contents(inventory);
    for (std::size_t shift = 0; shift < 64; shift += 8) out.push_back(static_cast<std::byte>(inventory.revision() >> shift));
    return out;
}

using item::Actor;
using item::Currency;
using item::Error;
using item::Instance;
using item::Place;
using item::Planner;
using item::Result;
using item::SlotRef;
using item::TemplateId;

inline SlotRef bag(std::uint16_t index) { return {.place = Place::kBaseBag, .index = index}; }
inline SlotRef material(std::uint16_t index) { return {.place = Place::kMaterialBag, .index = index}; }
inline SlotRef quest(std::uint16_t index) { return {.place = Place::kQuestBag, .index = index}; }
inline SlotRef bank(std::uint16_t index) { return {.place = Place::kBank, .index = index}; }
inline SlotRef worn(std::uint16_t index) { return {.place = Place::kEquip, .index = index}; }

inline bool is(const Result& result, Error expected) { return !result.has_value() && result.error() == expected; }

// Thế giới thử + kho đồ trống. Không sao chép hay dời được vì Factory giữ con trỏ vào World.
struct Bench {
    World world = make_world();
    item::Inventory inventory{world.limits};
    item::SerialAllocator serials{1, 1'000'000'000};
    item::Factory factory{world.catalog, world.rolls};
    dice::Dice dice{7};

    Bench() = default;
    Bench(const Bench&) = delete;
    Bench& operator=(const Bench&) = delete;
    Bench(Bench&&) = delete;
    Bench& operator=(Bench&&) = delete;
    ~Bench() = default;

    Instance make(std::uint32_t id, std::uint16_t count = 1, bool picked = false) {
        const auto made = factory.create({.tmpl = TemplateId{id}, .count = count, .picked = picked, .now = ids::Tick{}, .roll = {}}, dice, serials);
        if (!made) std::abort();
        return *made;
    }
    // Đặt thẳng vào ô (đường nạp từ bản ghi), bỏ qua luật.
    void put(SlotRef where, const Instance& value) {
        if (!inventory.restore(where, value)) std::abort();
    }
    Planner planner() { return Planner(inventory, world.catalog, serials); }
    [[nodiscard]] bool commit(Planner&& planner_value) { return inventory.apply(std::move(planner_value).finish()).has_value(); }
};

// Bộ tách TSV riêng của test, độc lập với bộ nạp của module: bỏ dòng trống và dòng bắt đầu bằng #, dòng đầu là
// tiêu đề cột. Dùng để lấy số kỳ vọng thẳng từ tệp bảng thật.
[[nodiscard]] inline std::vector<std::vector<std::string>> tsv_rows(const std::string& text) {
    std::vector<std::vector<std::string>> rows;
    std::istringstream in(text);
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty() || line.front() == '#') continue;
        std::vector<std::string> cells;
        std::size_t begin = 0;
        for (;;) {
            const std::size_t tab = line.find('\t', begin);
            cells.push_back(line.substr(begin, tab == std::string::npos ? std::string::npos : tab - begin));
            if (tab == std::string::npos) break;
            begin = tab + 1;
        }
        rows.push_back(std::move(cells));
    }
    return rows;
}

// Đọc tệp văn bản; rỗng khi không mở được.
[[nodiscard]] inline std::string read_text(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    if (!in) return {};
    return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

#ifdef GAME_SERVER_TABLES
// Bảng thật của dev/server/tables: catalog vật phẩm và bảng ItemSeg (bản XJL7457), nạp từ đường dẫn của máy dựng.
struct RealWorld {
    std::string rules, common, equipment, gems, pets, extra, v_client, v_xjl, v_server, affects, quality, apt;
    item::Catalog catalog;
    item::RollTables rolls;
};

[[nodiscard]] inline std::optional<RealWorld> load_real(Context& context) {
    const std::string root = GAME_SERVER_TABLES;
    RealWorld r;
    r.rules = read_text(root + "/shared/item_rules.tsv");
    r.common = read_text(root + "/shared/items_common.tsv");
    r.equipment = read_text(root + "/shared/equipment.tsv");
    r.gems = read_text(root + "/shared/gems.tsv");
    r.pets = read_text(root + "/shared/pet_equipment_base.tsv");
    r.extra = read_text(root + "/shared/equipment_extra_attributes.tsv");
    r.v_client = read_text(root + "/shared/item_segment_values.tsv");
    r.v_xjl = read_text(root + "/server/item_segment_values_xjl.tsv");
    r.v_server = read_text(root + "/server/item_segment_values.tsv");
    r.affects = read_text(root + "/server/item_segment_distributions_xjl.tsv");
    r.quality = read_text(root + "/server/item_segment_quality_rules_xjl.tsv");
    r.apt = read_text(root + "/shared/item_aptitude_rates.tsv");
    auto catalog = item::Catalog::load({.rules = r.rules, .common = r.common, .equipment = r.equipment, .gems = r.gems,
        .pet_equipment = r.pets, .extra_attributes = r.extra});
    auto rolls = item::RollTables::load({.values_shared = r.v_client, .values_xjl = r.v_xjl, .values_server = r.v_server,
        .affects = r.affects, .quality_rules = r.quality, .apt_rates = r.apt});
    context.expect(catalog.has_value() && rolls.has_value(), "bảng thật nạp được");
    if (!catalog || !rolls) {
        std::fprintf(stderr, "%s\n", (!catalog ? catalog.error() : rolls.error()).c_str());
        return std::nullopt;
    }
    r.catalog = std::move(*catalog);
    r.rolls = std::move(*rolls);
    return r;
}
#endif

} // namespace game::test
