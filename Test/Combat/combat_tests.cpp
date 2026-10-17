// Lõi chiến đấu: bộ nạp bảng, cú pháp vai, công thức sát thương, chỉ số theo buff, trúng/né/hội tâm theo hạt giống
// cố định, hồi chiêu, buff hết hạn đúng nhịp, chu kỳ, khiên, chết và hồi sinh, gom khí và gián đoạn, đòn vùng,
// logic chưa hỗ trợ, lưu và khôi phục.
//
// Số vàng của một đòn (hạt giống -> trúng/trượt, hội tâm, sát thương) và chỉ số của hai người mẫu tính độc lập bằng
// TOOLS/server/golden_combat.py từ chính các bảng trong dev/server/tables, theo công thức Float2Int của bản 2008
// và bản Python của bộ xúc xắc; không lấy từ đầu ra của C++. Các số về nhịp (buff 1000 ms sống đúng 20 bước, hồi chiêu
// 3000 ms đúng 60 bước...) suy từ hợp đồng nhịp ghi ở arena.hpp. Dữ liệu tổng hợp (kỹ năng 1001..1014, hiệu ứng
// 9001..9012) dựng ngay trong test theo cùng bố cục cột với bảng thật; bảng thật được nạp riêng để đối chiếu cột.
#include "actor/body.hpp"
#include "actor/rules.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/codec.hpp"
#include "combat/damage.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "dice/dice.hpp"
#include "ids/ids.hpp"
#include "protocol/wire.hpp"
#include "support/actor_rules.hpp"
#include "support/keep_forever.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

// Các thử nghiệm nằm trong namespace combat để gọi thẳng tên của module (google-build-using-namespace cấm using-directive).
namespace game::combat {
namespace {

using test::Case;
using test::Context;
using test::real_rules;
using test::slurp_table;

// ---------------------------------------------------------------------------------------------------------
// Người mẫu (chỉ số tính bằng golden_combat.py stats <phái> <cấp>)

struct Person {
    std::uint8_t sect;
    std::uint16_t level;
    std::array<std::int32_t, actor::kPrimaryCount> points;
    std::int32_t remain;
};

// Võ Đang 60: HP 6510, MP 4336, công ngoại 337, công nội 1692, thủ ngoại 612, thủ nội 961, trúng 694, né 248,
// hội tâm 7, dao động 20.
constexpr Person kWudang{3, 60, {13, 127, 75, 63, 37}, 5};
// Thiếu Lâm 60: HP 14465, MP 2250, công ngoại 1243, công nội 290, thủ ngoại 1672, thủ nội 510, trúng 652, né 201,
// hội tâm 6, dao động 10.
constexpr Person kShaolin{0, 60, {100, 13, 138, 26, 38}, 5};

actor::Record record_of(const Person& who) {
    actor::Record record;
    record.sect = who.sect;
    record.level = who.level;
    record.points = who.points;
    record.remain_points = who.remain;
    record.hp = std::numeric_limits<std::int32_t>::max();
    record.mp = std::numeric_limits<std::int32_t>::max();
    return record;
}

// ---------------------------------------------------------------------------------------------------------
// Dựng bảng TSV tổng hợp theo bố cục cột của bảng thật (các chỉ số cột lặp lại của catalog.cpp; bảng thật được
// nạp riêng ở ca catalog_real_tables, nơi Python đọc cột theo tên để đối chiếu).

class Grid {
public:
    Grid(std::size_t columns, std::string_view first_name, std::size_t marker, std::string_view marker_name) {
        header_.reserve(columns);
        for (std::size_t i = 0; i < columns; ++i) header_.push_back("column_" + std::to_string(i));
        header_.at(0) = std::string(first_name);
        header_.at(marker) = std::string(marker_name);
    }

    std::size_t add_row(std::int32_t fill) {
        rows_.emplace_back(header_.size(), std::to_string(fill));
        return rows_.size() - 1;
    }

    void set(std::size_t row, std::size_t column, std::int64_t value) {
        rows_.at(row).at(column) = std::to_string(value);
    }

    [[nodiscard]] std::string text() const {
        std::string out = join(header_);
        for (const std::vector<std::string>& row : rows_) {
            out += '\n';
            out += join(row);
        }
        out += '\n';
        return out;
    }

private:
    static std::string join(const std::vector<std::string>& cells) {
        std::string out;
        for (std::size_t i = 0; i < cells.size(); ++i) {
            if (i > 0) out += '\t';
            out += cells.at(i);
        }
        return out;
    }

    std::vector<std::string> header_;
    std::vector<std::vector<std::string>> rows_;
};

struct SkillSpec {
    std::uint32_t id = 0;
    std::int32_t type = 2;             // 0 gom khí, 1 dẫn, 2 tức thời, 3 bị động
    std::int32_t cooldown_id = -1;
    std::int32_t select = 1;           // 1 chọn người, 4 tự thân, 0 không chọn
    std::int32_t targeting = 5;        // 5 một người, 0 tự thân, 4 quanh bản thân
    std::int32_t action_ms = 500;
    std::int32_t range_m = 20;
    std::int32_t radius_m = 0;
    std::int32_t max_targets = 0;
    std::int32_t accuracy = -1;
    std::int32_t disrupt_chance = 0;
    std::uint32_t level_one = 0;
    bool passive = false;
};

struct LevelSpec {
    std::uint32_t id = 0;
    std::int32_t logic = 0;
    std::int32_t cooldown_ms = 0;
    std::int32_t charge_ms = -1;
    std::int32_t mana = -1;             // loại 4 (tiêu nội lực theo số) khi >= 0
    std::array<std::int32_t, kSkillParamCount> param{};

    LevelSpec() { param.fill(-1); }
};

struct EffectSpec {
    std::uint32_t id = 0;
    std::int32_t logic = 0;
    bool over_timed = false;
    bool dispellable = false;
    bool fade_offline = false;
    bool timing_offline = false;
    std::int32_t continuance_ms = 0;
    std::int32_t interval_ms = 0;
    std::array<std::int32_t, kEffectParamCount> param{};
};

namespace col {
// skills.tsv
constexpr std::size_t kSkillColumns = 102;
constexpr std::size_t kSkillMarker = 96;
// skill_levels.tsv
constexpr std::size_t kLevelColumns = 54;
// effects.tsv
constexpr std::size_t kEffectColumns = 76;
} // namespace col

void add_skill(Grid& grid, const SkillSpec& spec) {
    const std::size_t row = grid.add_row(0);
    grid.set(row, 0, spec.id);
    grid.set(row, 1, -1);                  // không phái: kỹ năng chung, ai cũng dùng được
    grid.set(row, 10, -1);                 // không tâm pháp
    grid.set(row, 12, spec.type);
    grid.set(row, 13, spec.cooldown_id);
    grid.set(row, 21, spec.passive ? 1 : 0);
    grid.set(row, 22, spec.select);
    grid.set(row, 27, -1);
    grid.set(row, 33, spec.targeting);
    grid.set(row, 34, spec.action_ms);
    grid.set(row, 35, spec.range_m);       // mét; bộ nạp đổi sang centimet
    grid.set(row, 36, -1);                 // đứng phe: địch
    grid.set(row, 37, 1);                  // chỉ nhắm địch
    grid.set(row, 38, -1);
    grid.set(row, 43, spec.radius_m);
    grid.set(row, 44, spec.max_targets);
    grid.set(row, 48, spec.level_one);
    grid.set(row, 97, spec.accuracy);
    grid.set(row, 99, spec.disrupt_chance);
}

void add_level(Grid& grid, const LevelSpec& spec) {
    const std::size_t row = grid.add_row(0);
    grid.set(row, 0, spec.id);
    grid.set(row, 5, spec.logic);
    grid.set(row, 6, spec.cooldown_ms);
    grid.set(row, 7, spec.charge_ms);
    grid.set(row, 8, -1);
    for (std::size_t t = 0; t < kConditionTerms; ++t) {
        const std::size_t base = 10 + (4 * t);
        const bool mana = t == 0 && spec.mana >= 0;
        grid.set(row, base, mana ? static_cast<std::int32_t>(TermKind::kManaByValue) : -1);
        grid.set(row, base + 1, mana ? spec.mana : -1);
        grid.set(row, base + 2, -1);
    }
    grid.set(row, 21, -1);
    for (std::size_t k = 0; k < kSkillParamCount; ++k) grid.set(row, 25 + (2 * k), spec.param.at(k));
}

void add_effect(Grid& grid, const EffectSpec& spec) {
    const std::size_t row = grid.add_row(0);
    grid.set(row, 0, spec.id);
    grid.set(row, 2, spec.logic);
    grid.set(row, 4, spec.over_timed ? 1 : 0);
    grid.set(row, 5, -1);
    grid.set(row, 7, -1);
    grid.set(row, 9, -1);
    grid.set(row, 11, spec.dispellable ? 1 : 0);
    grid.set(row, 17, spec.fade_offline ? 1 : 0);
    grid.set(row, 18, spec.timing_offline ? 1 : 0);
    grid.set(row, 20, spec.continuance_ms);
    grid.set(row, 21, spec.interval_ms);
    for (std::size_t k = 0; k < kEffectParamCount; ++k) grid.set(row, 28 + (3 * k), spec.param.at(k));
}

// Chữ của mọi bảng nạp vào Catalog. `view()` trỏ vào các chuỗi này nên đối tượng phải sống lâu hơn Catalog đã nạp.
struct CatalogStrings {
    std::string skills, levels, effects, collections, camps, skill_logics, effect_logics;

    [[nodiscard]] CatalogText view() const {
        return CatalogText{.skills = skills, .skill_levels = levels, .effects = effects, .id_collections = collections,
            .camp_relations = camps, .skill_logics = skill_logics, .effect_logics = effect_logics};
    }
};

// Kỹ năng: nhắm, tầm, uy lực... Mỗi kỹ năng có đúng một dòng cấp (cấp 1) mang số id `id + 4000`.
void add_pair(Grid& skills, Grid& levels, SkillSpec skill, const LevelSpec& level) {
    skill.level_one = level.id;
    add_skill(skills, skill);
    add_level(levels, level);
}

LevelSpec level_of(std::uint32_t skill, std::int32_t logic, std::int32_t effect) {
    LevelSpec level;
    level.id = skill + 4000;
    level.logic = logic;
    level.param.at(0) = effect;
    return level;
}

// Chín kỹ năng và mười hai hiệu ứng tổng hợp. Mã logic dùng đúng số của bảng thật: kỹ năng 0 (chuẩn: vai target ở
// tham số 0), 1 (tự thân ở tham số 0), 8 (bị động giáp), 701 (bí pháp, chưa hỗ trợ), 4000 (không có trong bảng logic).
void build_skills(Grid& skills, Grid& levels) {
    SkillSpec strike;
    strike.id = 1001;
    strike.action_ms = 1000;
    LevelSpec strike_level = level_of(1001, 0, 9001);
    strike_level.mana = 10;
    add_pair(skills, levels, strike, strike_level);

    SkillSpec self_buff;
    self_buff.id = 1002;
    self_buff.select = 4;
    self_buff.targeting = 0;
    add_pair(skills, levels, self_buff, level_of(1002, 1, 9002));

    SkillSpec cooled = self_buff;
    cooled.id = 1003;
    cooled.cooldown_id = 7;
    cooled.action_ms = 1000;
    LevelSpec cooled_level = level_of(1003, 1, 9012);
    cooled_level.cooldown_ms = 3000;
    add_pair(skills, levels, cooled, cooled_level);

    SkillSpec area;
    area.id = 1004;
    area.select = 0;
    area.targeting = 4;
    area.radius_m = 5;
    area.accuracy = 100;
    add_pair(skills, levels, area, level_of(1004, 0, 9005));

    SkillSpec lethal;
    lethal.id = 1005;
    lethal.accuracy = 100;
    add_pair(skills, levels, lethal, level_of(1005, 0, 9006));

    SkillSpec heal = self_buff;
    heal.id = 1006;
    add_pair(skills, levels, heal, level_of(1006, 1, 9007));

    SkillSpec secret = self_buff;
    secret.id = 1007;
    add_pair(skills, levels, secret, level_of(1007, 701, 9012));

    SkillSpec missing = self_buff;
    missing.id = 1008;
    add_pair(skills, levels, missing, level_of(1008, 1, 77777));

    SkillSpec unknown = self_buff;
    unknown.id = 1009;
    add_pair(skills, levels, unknown, level_of(1009, 4000, 9012));

    SkillSpec rate_buff = self_buff;
    rate_buff.id = 1010;
    add_pair(skills, levels, rate_buff, level_of(1010, 1, 9008));

    SkillSpec armor = self_buff;
    armor.id = 1011;
    armor.type = 3;
    armor.passive = true;
    LevelSpec armor_level = level_of(1011, 8, 50);
    armor_level.param.at(1) = 0;
    add_pair(skills, levels, armor, armor_level);

    SkillSpec capped = area;
    capped.id = 1012;
    capped.max_targets = 2;
    add_pair(skills, levels, capped, level_of(1012, 0, 9005));

    SkillSpec charged = self_buff;
    charged.id = 1013;
    charged.type = 0;
    LevelSpec charged_level = level_of(1013, 1, 9012);
    charged_level.charge_ms = 1000;
    add_pair(skills, levels, charged, charged_level);

    SkillSpec flinching = charged;
    flinching.id = 1014;
    flinching.disrupt_chance = 100;
    LevelSpec flinching_level = charged_level;
    flinching_level.id = 1014 + 4000;
    add_pair(skills, levels, flinching, flinching_level);
}

EffectSpec effect_of(std::uint32_t id, std::int32_t logic) {
    EffectSpec effect;
    effect.id = id;
    effect.logic = logic;
    return effect;
}

void build_effects(Grid& effects) {
    add_effect(effects, effect_of(9001, 3));  // sát thương công thức, mọi cộng thêm 0

    EffectSpec stat = effect_of(9002, 11);    // +100 công ngoại, +50 thủ ngoại, +200 HP tối đa trong 1000 ms
    stat.over_timed = true;
    stat.dispellable = true;
    stat.continuance_ms = 1000;
    stat.param.at(0) = 100;
    stat.param.at(1) = 50;
    stat.param.at(12) = 200;
    add_effect(effects, stat);

    EffectSpec dot = effect_of(9003, 10);     // cứ 1000 ms phát hiệu ứng con 9004, sống 3000 ms
    dot.over_timed = true;
    dot.continuance_ms = 3000;
    dot.interval_ms = 1000;
    dot.param.at(0) = 9004;
    add_effect(effects, dot);

    EffectSpec flat = effect_of(9004, 1);     // sát thương thẳng 100
    flat.param.at(0) = 100;
    add_effect(effects, flat);
    flat.id = 9005;                           // 50
    flat.param.at(0) = 50;
    add_effect(effects, flat);
    flat.id = 9006;                           // chí mạng
    flat.param.at(0) = 1'000'000;
    add_effect(effects, flat);

    EffectSpec restore = effect_of(9007, 4);  // hồi 500 HP
    restore.param.at(0) = 500;
    add_effect(effects, restore);

    EffectSpec rate = effect_of(9008, 12);    // +10% công ngoại gốc trong 1000 ms
    rate.over_timed = true;
    rate.continuance_ms = 1000;
    rate.param.at(0) = 10;
    add_effect(effects, rate);

    EffectSpec shield = effect_of(9009, 26);  // khiên 150 máu hút 100% sát thương
    shield.over_timed = true;
    shield.continuance_ms = 5000;
    shield.param.at(0) = 150;
    shield.param.at(1) = 100;
    add_effect(effects, shield);

    EffectSpec timed = effect_of(9010, 11);   // +7 công ngoại, 60 000 ms, tính giờ cả lúc ngoại tuyến
    timed.over_timed = true;
    timed.timing_offline = true;
    timed.continuance_ms = 60'000;
    timed.param.at(0) = 7;
    add_effect(effects, timed);

    EffectSpec vanishing = effect_of(9011, 11);  // +3 công ngoại, tan khi ngoại tuyến (không được lưu)
    vanishing.over_timed = true;
    vanishing.fade_offline = true;
    vanishing.continuance_ms = 60'000;
    vanishing.param.at(0) = 3;
    add_effect(effects, vanishing);

    add_effect(effects, effect_of(9012, 0));  // đánh dấu: không làm gì
}

CatalogStrings synthetic_strings(const std::string& skill_logics, const std::string& effect_logics) {
    Grid skills(col::kSkillColumns, "skill_id", col::kSkillMarker, "column_96");
    Grid levels(col::kLevelColumns, "id", 5, "logic_id");
    Grid effects(col::kEffectColumns, "data_index", 2, "logic_id");
    build_skills(skills, levels);
    build_effects(effects);
    CatalogStrings out;
    out.skills = skills.text();
    out.levels = levels.text();
    out.effects = effects.text();
    out.collections = "category_id\tcategory_note\trow_id_kind\tid_count\tid_1\n1\tghi chú\t0\t1\t105\n";
    out.camps = "column_0\tcolumn_1\tcolumn_2\n0\t1\t0\n1\t0\t1\n";  // phe 0 và 1 thù nhau, mỗi phe thân với chính nó
    out.skill_logics = skill_logics;
    out.effect_logics = effect_logics;
    return out;
}

std::optional<CatalogStrings> load_synthetic_strings() {
    const std::optional<std::string> skill_logics = slurp_table("server/skill_logics.tsv");
    const std::optional<std::string> effect_logics = slurp_table("server/effect_logics.tsv");
    if (!skill_logics || !effect_logics) return std::nullopt;
    return synthetic_strings(*skill_logics, *effect_logics);
}

// Chín bảng THẬT của máy chủ (cùng kiểu chuỗi với bảng tổng hợp).
std::optional<CatalogStrings> load_real_strings() {
    CatalogStrings loaded;
    const std::array<std::pair<std::string*, const char*>, 7> files{{
        {&loaded.skills, "shared/skills.tsv"},
        {&loaded.levels, "shared/skill_levels.tsv"},
        {&loaded.effects, "server/effects.tsv"},
        {&loaded.collections, "shared/id_collections.tsv"},
        {&loaded.camps, "server/camp_relations.tsv"},
        {&loaded.skill_logics, "server/skill_logics.tsv"},
        {&loaded.effect_logics, "server/effect_logics.tsv"},
    }};
    for (const auto& [target, name] : files) {
        std::optional<std::string> text = slurp_table(name);
        if (!text) return std::nullopt;
        *target = std::move(*text);
    }
    return loaded;
}

std::optional<Catalog> load_catalog_from(const CatalogStrings* strings, const char* label) {
    if (strings == nullptr) return std::nullopt;
    Loaded<Catalog> loaded = load_catalog(strings->view());
    if (!loaded) {
        static_cast<void>(std::fprintf(stderr, "lỗi nạp bảng %s: %s\n", label, loaded.error().what.c_str()));
        return std::nullopt;
    }
    return std::move(*loaded);
}

const CatalogStrings* synthetic_strings_cached(Context& context) {
    static const CatalogStrings* const kStrings = test::keep_forever(load_synthetic_strings());
    context.expect(kStrings != nullptr, "đọc được skill_logics.tsv và effect_logics.tsv thật");
    return kStrings;
}

const Catalog* synthetic_catalog(Context& context) {
    static const Catalog* const kCatalog = test::keep_forever(load_catalog_from(synthetic_strings_cached(context), "tổng hợp"));
    context.expect(kCatalog != nullptr, "nạp được catalog tổng hợp");
    return kCatalog;
}

const Catalog* real_catalog(Context& context) {
    static const Catalog* const kCatalog = test::keep_forever(
        load_catalog_from(test::keep_forever(load_real_strings()), "thật"));
    context.expect(kCatalog != nullptr, "nạp được catalog từ bảng thật");
    return kCatalog;
}

// ---------------------------------------------------------------------------------------------------------
// Cảnh dựng nhanh

struct Scene {
    Scene(const Catalog& catalog, std::uint64_t seed, std::int64_t hz = 20) : dice(seed), arena(catalog, dice, {}, hz) {}

    dice::Dice dice;
    Arena arena;
    std::uint32_t last_index = 0;
};

ids::EntityHandle add_person(Scene& scene, const actor::Rules& rules, const Person& who, Position at,
    std::uint64_t character = 0) {
    const ids::EntityHandle handle{++scene.last_index, 1};
    Fighter fighter(handle, FighterKind::kHuman, actor::Body::human(rules, actor::BodyLimits{}, record_of(who)));
    fighter.position = at;
    fighter.character = character;
    return scene.arena.add(std::move(fighter)).has_value() ? handle : ids::EntityHandle{};
}

void make_hostile(Arena& arena) {
    arena.set_relation_policy([](const Fighter&, const Fighter&) { return Relation::kEnemy; });
}

void run_ticks(Arena& arena, std::int32_t count) {
    for (std::int32_t i = 0; i < count; ++i) arena.tick();
}

std::vector<Event> events_of(const Arena& arena, EventKind kind) {
    std::vector<Event> out;
    for (const Event& event : arena.events()) {
        if (event.kind == kind) out.push_back(event);
    }
    return out;
}

// Sự kiện hồi máu do người khác gây ra (loại bỏ hồi tự nhiên, vốn có người gây trùng người nhận).
std::vector<Event> heals_by_others(const Arena& arena) {
    std::vector<Event> out;
    for (const Event& event : arena.events()) {
        if (event.kind == EventKind::kHealed && event.actor != event.target) out.push_back(event);
    }
    return out;
}

std::int32_t stat_of(Scene& scene, ids::EntityHandle who, actor::Stat which) {
    const Fighter* fighter = scene.arena.find(who);
    return fighter == nullptr ? -1 : fighter->body.stat(which);
}

bool has_buff(Scene& scene, ids::EntityHandle who, std::uint32_t effect) {
    const Fighter* fighter = scene.arena.find(who);
    return fighter != nullptr && fighter->find_buff_by_effect(effect) != nullptr;
}

EffectOrigin origin_from(ids::EntityHandle caster) {
    EffectOrigin origin;
    origin.caster = caster;
    return origin;
}

// ---------------------------------------------------------------------------------------------------------
// Bộ nạp bảng

void catalog_real_tables(Context& context) {
    const Catalog* catalog = real_catalog(context);
    if (catalog == nullptr) return;
    context.expect(catalog->skill_count() == 4586 && catalog->level_count() == 20667 && catalog->effect_count() == 9860,
        "số dòng skills, skill_levels, effects (đếm bằng Python)");
    context.expect(catalog->skill_logics().size() >= 100 && catalog->effect_logics().size() >= 60, "bảng logic có đủ dòng");
    context.expect(catalog->skill_logic(0) != nullptr && catalog->skill_logic(0)->handler == "standard" &&
            catalog->skill_logic(701) != nullptr && catalog->skill_logic(701)->handler == "unsupported" &&
            catalog->effect_logic(3) != nullptr && catalog->effect_logic(3)->handler == "damage_attack",
        "logic 0, 701 và hiệu ứng 3 có mã xử lý như bảng ghi");
    context.expect(catalog->skill_logic(999) == nullptr && catalog->effect_logic(-1) == nullptr, "logic vắng trả null");

    // Kỹ năng 281 (伏虎拳, Thiếu Lâm): các số dưới đây Python đọc theo TÊN cột của skills.tsv.
    const SkillTemplate* fist = catalog->skill(281);
    context.expect(fist != nullptr && fist->sect == 0 && fist->type == SkillType::kInstant &&
            fist->select == SelectType::kCharacter && fist->targeting == TargetLogic::kSpecificUnit &&
            fist->range_cm == 200 && fist->action_time_ms == 800 && fist->cooldown_id == -1 && fist->stand == -1 &&
            fist->target_by_stand == 1 && fist->delay_ms == 400 && fist->accuracy == -1 && fist->must_use_weapon &&
            fist->disrupt_chance == 50 && fist->disrupt_time_permille == 100 && fist->instance.at(0) == 281U &&
            fist->instance.at(1) == 282U && fist->instance.at(2) != 0U && fist->skill_class == 1,
        "mẫu kỹ năng 281");
    const SkillLevel* fist_level = catalog->level_of(281, 1);
    context.expect(fist_level != nullptr && fist_level->id == 281U && fist_level->logic == 0 && fist_level->cooldown_ms == 800 &&
            fist_level->charge_ms == -1 && fist_level->channel_ms == -1 && fist_level->target_level == -1 &&
            fist_level->terms.at(0).kind == -1 && fist_level->param.at(0) == 201 && fist_level->param.at(1) == -1,
        "dòng cấp 1 của 281");
    const Effect* fist_effect = catalog->effect(201);
    context.expect(fist_effect != nullptr && fist_effect->logic == 3 && !fist_effect->over_timed && fist_effect->impact_id == 25 &&
            fist_effect->param.at(0) == 58 && fist_effect->param.at(1) == 58 && fist_effect->param.at(2) == 0 &&
            fist_effect->param.at(4) == 2 && fist_effect->param.at(6) == 0,
        "hiệu ứng 201");
    // Kỹ năng 282 (金刚伏魔圈): đòn vùng quanh bản thân có tiêu hao nội lực.
    const SkillTemplate* circle = catalog->skill(282);
    const SkillLevel* circle_level = catalog->level_of(282, 1);
    context.expect(circle != nullptr && circle->cooldown_id == 53 && circle->accuracy == 85 && circle->radius_cm == 500 &&
            circle->targeting == TargetLogic::kAroundSelf && circle->select == SelectType::kNone &&
            circle->max_targets == 10 && circle->range_cm == -100 && circle->delay_ms == 800,
        "mẫu kỹ năng 282");
    context.expect(circle_level != nullptr && circle_level->id == 293U && circle_level->cooldown_ms == 80000 &&
            circle_level->terms.at(0).kind == static_cast<std::int32_t>(TermKind::kManaByValue) &&
            circle_level->terms.at(0).first == 33 && circle_level->param.at(0) == 213 && circle_level->param.at(2) == 442,
        "dòng cấp 1 của 282");
    // Hai kỹ năng trợ giúp của bảng thật khai thời gian ra chiêu -1 (không có): bộ nạp coi là 0 chứ không từ chối cả bảng.
    context.expect(catalog->skill(3296) != nullptr && catalog->skill(3296)->action_time_ms == 0 &&
            catalog->skill(3325) != nullptr && catalog->skill(3325)->action_time_ms == 0,
        "thời gian ra chiêu -1 coi là 0");
    context.expect(catalog->level_of(281, 0) == nullptr && catalog->level_of(281, 17) == nullptr &&
            catalog->level_of(4294967295U, 1) == nullptr && catalog->skill(4294967295U) == nullptr,
        "cấp 0, cấp 17 và id lạ không có dòng");
    const Collection* set = catalog->collection(1);
    context.expect(set != nullptr && set->kind == 0 && set->ids == std::vector<std::int32_t>({105, 108, 106}) &&
            set->contains(108) && !set->contains(7) && set->is_buff_kind() && catalog->collection(-5) == nullptr,
        "tập id 1");
    // Ma trận phe đọc từ camp_relations.tsv (Python liệt kê ô khác 0): phe 1 thân với 1, 9, 10; phe 2 thân với 3.
    context.expect(catalog->camp_relation(1, 1) == Relation::kFriend && catalog->camp_relation(1, 0) == Relation::kEnemy &&
            catalog->camp_relation(1, 9) == Relation::kFriend && catalog->camp_relation(0, 10) == Relation::kFriend &&
            catalog->camp_relation(2, 3) == Relation::kFriend && catalog->camp_relation(3, 2) == Relation::kFriend &&
            catalog->camp_relation(4, 5) == Relation::kEnemy && catalog->camp_relation(3, 3) == Relation::kEnemy,
        "ma trận phe thật");
    context.expect(catalog->camp_relation(-1, 0) == Relation::kFriend && catalog->camp_relation(0, 99) == Relation::kFriend,
        "phe lạ coi là bạn");
}

void catalog_rejects_bad_tables(Context& context) {
    const CatalogStrings* good = synthetic_strings_cached(context);
    if (good == nullptr) return;
    context.expect(load_catalog(good->view()).has_value(), "bản gốc nạp được");
    const auto rejects = [&](std::string CatalogStrings::*field, const std::string& replacement, std::string_view needle,
                             std::string_view what) {
        CatalogStrings copy = *good;
        copy.*field = replacement;
        const Loaded<Catalog> result = load_catalog(copy.view());
        context.expect(!result.has_value(), what);
        if (!result) context.expect(result.error().what.find(needle) != std::string::npos, what);
    };
    const std::string header = "logic_id\thandler\troles\tfidelity\tnote\n";
    rejects(&CatalogStrings::skill_logics, header + "0\tkhong_co\t\tfull\tx\n", "handler", "tên mã xử lý lạ");
    rejects(&CatalogStrings::skill_logics, header + "0\tstandard\t\tmaybe\tx\n", "fidelity", "độ trung thực lạ");
    rejects(&CatalogStrings::skill_logics, header + "0\tstandard\t0:bogus\tfull\tx\n", "roles", "vai lạ");
    rejects(&CatalogStrings::skill_logics, header + "0\tstandard\t\tfull\tx\n0\tstandard\t\tfull\ty\n", "lặp", "logic lặp");
    rejects(&CatalogStrings::skill_logics, header + "5000\tstandard\t\tfull\tx\n", "logic_id", "số logic vượt trần");
    rejects(&CatalogStrings::skill_logics, header + "-2\tstandard\t\tfull\tx\n", "logic_id", "số logic âm");
    rejects(&CatalogStrings::effect_logics, header + "3\tunsupported\t\tfull\tx\n", "handler", "hiệu ứng không có handler unsupported");
    rejects(&CatalogStrings::skills, "", "", "bảng kỹ năng rỗng");
    rejects(&CatalogStrings::skills, "id\tcolumn_1\n1\t2\n", "cột", "bảng kỹ năng thiếu cột");
    rejects(&CatalogStrings::effects, "data_index\tcolumn_1\n1\t2\n", "cột", "bảng hiệu ứng thiếu cột");
    rejects(&CatalogStrings::levels, "id\tcolumn_1\n1\t2\n", "cột", "bảng cấp thiếu cột");

    // Id lặp: nhân đôi dòng dữ liệu đầu của mỗi bảng.
    const auto doubled = [](const std::string& text) {
        const std::size_t first = text.find('\n') + 1;
        const std::size_t end = text.find('\n', first);
        return text + text.substr(first, end - first + 1);
    };
    rejects(&CatalogStrings::skills, doubled(good->skills), "lặp", "id kỹ năng lặp");
    rejects(&CatalogStrings::levels, doubled(good->levels), "lặp", "id cấp lặp");
    rejects(&CatalogStrings::effects, doubled(good->effects), "lặp", "id hiệu ứng lặp");
    // Ô hỏng: id kỹ năng không phải số.
    std::string broken = good->skills;
    const std::size_t at = broken.find("\n1001\t");
    context.expect(at != std::string::npos, "tìm thấy dòng kỹ năng 1001");
    if (at != std::string::npos) broken.replace(at + 1, 4, "abcd");
    rejects(&CatalogStrings::skills, broken, "skills.tsv", "ô id kỹ năng hỏng");
}

void roles_grammar(Context& context) {
    const auto parsed = parse_roles("0:target;1:self@2;2:rank3*4;3:cut_cooldown+5;4:combo1;5:enemy_rest;6:friend2@7*8+9");
    context.expect(parsed.has_value() && parsed->size() == 7, "bảy vai hợp lệ");
    if (parsed && parsed->size() == 7) {
        const std::vector<Role>& roles = *parsed;
        context.expect(roles.at(0).kind == RoleKind::kTarget && roles.at(0).param == 0 && roles.at(0).chance == -1 &&
                roles.at(0).repeat == -1 && roles.at(0).aux == -1,
            "vai target");
        context.expect(roles.at(1).kind == RoleKind::kSelf && roles.at(1).param == 1 && roles.at(1).chance == 2, "xác suất");
        context.expect(roles.at(2).kind == RoleKind::kRank && roles.at(2).arg == 3 && roles.at(2).repeat == 4, "hạng và số lần");
        context.expect(roles.at(3).kind == RoleKind::kCutCooldown && roles.at(3).aux == 5, "giảm hồi chiêu và ô phụ");
        context.expect(roles.at(4).kind == RoleKind::kCombo && roles.at(4).arg == 1, "đoạn liên kích");
        context.expect(roles.at(5).kind == RoleKind::kEnemyRest, "địch từ thứ hai");
        context.expect(roles.at(6).kind == RoleKind::kFriendRank && roles.at(6).arg == 2 && roles.at(6).chance == 7 &&
                roles.at(6).repeat == 8 && roles.at(6).aux == 9,
            "đủ ba hậu tố");
    }
    context.expect(parse_roles("").has_value() && parse_roles("")->empty() && parse_roles("-").has_value() &&
            parse_roles("-")->empty(),
        "rỗng và dấu gạch là không có vai");
    for (const std::string_view bad : {"0:bogus", "x:target", "0target", "-1:target", "64:target", "0:rank16", "0:combo4",
             "0:cut_cooldown", "0:target@", "0:target@x", "0:target;", ";0:target", "0:target;;1:self", "0:", ":target",
             "0:rank", "0:sub@-1"}) {
        context.expect(!parse_roles(bad).has_value(), bad);
    }
    std::string many = "0:target";
    for (int i = 0; i < 64; ++i) many += ";1:target";
    context.expect(!parse_roles(many).has_value(), "quá 64 vai");
}

// ---------------------------------------------------------------------------------------------------------
// Công thức (số tính tay)

void damage_formulas(Context& context) {
    context.expect(hit_rate(694, 201) == 77 && hit_rate(0, 0) == 50 && hit_rate(5000, 1) == 99 && hit_rate(1, 1000) == 0,
        "tỉ lệ trúng: 694*100/895 = 77; điểm kẹp 1..1000");
    context.expect(is_hit(77, 76) && !is_hit(77, 77) && is_hit(100, 99) && is_hit(150, 99) && !is_hit(-5, 0), "ngưỡng trúng");
    context.expect(is_critical(7, 6) && !is_critical(7, 7) && !is_critical(0, 0) && is_critical(500, 99) && !is_critical(-3, 0),
        "ngưỡng hội tâm kẹp 0..100");
    context.expect(verify_general(0) == 1 && verify_general(-5) == 1 && verify_general(40) == 40 && verify_trait(-5) == 0 &&
            verify_resist(300) == 200 && verify_resist(-300) == -200 && verify_hit_miss(0) == 1 && verify_hit_miss(2000) == 1000 &&
            verify_critical(150) == 100 && verify_critical(-1) == 0,
        "kẹp miền");

    AttackerView attacker;
    attacker.attack_phy = 1000;
    attacker.attack_magic = 900;
    attacker.attack_element[Element::kCold] = 400;
    attacker.attack_element[Element::kPoison] = 100;
    attacker.resist_reduce[Element::kCold] = 10;
    DefenderView defender;
    defender.defence_phy = 500;
    defender.defence_magic = 300;
    defender.resist_element[Element::kCold] = 30;
    defender.resist_element[Element::kPoison] = -50;
    defender.immunity_phy = 30;
    defender.immunity_magic = 25;
    const ChannelDamage plain = channel_damage(attacker, defender, Additions{});
    // ngoại: 1000^2/1500 = 666, miễn 30% cắt xuống: 666 - 199 = 467; nội: 900^2/1200 = 675, miễn 25% làm tròn: 675 - 169 = 506;
    // băng: kháng 30 - giảm 10 = 20 -> 400*80/100 = 320; độc: kháng -50 -> 100*150/100 = 150.
    context.expect(plain[Channel::kPhysical] == 467 && plain[Channel::kMagic] == 506 && plain[Channel::kCold] == 320 &&
            plain[Channel::kFire] == 0 && plain[Channel::kLight] == 0 && plain[Channel::kPoison] == 150,
        "sáu kênh");
    context.expect(total(plain) == 467 + 506 + 320 + 150, "tổng sáu kênh");
    Additions add;
    add.attack[Channel::kPhysical] = 500;
    add.defence[Channel::kMagic] = -200;
    add.attack[Channel::kFire] = 40;
    add.defence[Channel::kFire] = 20;
    const ChannelDamage boosted = channel_damage(attacker, defender, add);
    // ngoại: 1500^2/2000 = 1125, cắt 337 -> 788; nội: thủ 100 -> 810, cắt làm tròn 202,5 lên 203 -> 607; lửa: 40*(100-20)/100 = 32.
    context.expect(boosted[Channel::kPhysical] == 788 && boosted[Channel::kMagic] == 607 && boosted[Channel::kFire] == 32,
        "cộng thêm công, bớt thủ, kháng cộng thêm");
    defender.resist_element[Element::kCold] = 500;
    defender.resist_element[Element::kPoison] = -500;
    const ChannelDamage extremes = channel_damage(attacker, defender, Additions{});
    context.expect(extremes[Channel::kCold] == 0 && extremes[Channel::kPoison] == 200,
        "kháng kẹp 200 rồi 100: không âm; kháng âm kẹp -100 nên gấp đôi");
    attacker.attack_phy = 100000;
    defender.defence_phy = 1;
    defender.immunity_phy = 0;
    context.expect(channel_damage(attacker, defender, Additions{})[Channel::kPhysical] == 99999,
        "công 100000 không tràn int32: 10^10/100001 = 99999");

    context.expect(fluctuation_percent(20, 0) == 20 && fluctuation_percent(20, 99) == -19 && fluctuation_percent(20, 50) == 0 &&
            fluctuation_percent(7, 0) == 7 && fluctuation_percent(7, 25) == 4 && fluctuation_percent(10, 49) == 0,
        "dao động: 2*biên*(50-roll)/100, âm cắt về 0, dương từ 0,5 lên");
    context.expect(apply_fluctuation(666, 8) == 719 && apply_fluctuation(666, -19) == 540 && apply_fluctuation(5, 10) == 5 &&
            apply_fluctuation(0, 50) == 0,
        "áp dao động cắt về 0");
    context.expect(refix_percent(1000, 25) == 1250 && refix_percent(1000, -50) == 500 && refix_percent(333, 10) == 366 &&
            refix_percent(7, -100) == 0 && refix_percent(7, -150) == -3,
        "cường hóa phần trăm");
    ChannelDamage huge;
    huge[Channel::kPhysical] = std::numeric_limits<std::int32_t>::max();
    huge[Channel::kMagic] = std::numeric_limits<std::int32_t>::max();
    context.expect(total(huge) == 2LL * std::numeric_limits<std::int32_t>::max(), "tổng dùng 64 bit");
}

// ---------------------------------------------------------------------------------------------------------
// Chỉ số theo buff

void attributes_with_buffs(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
    context.expect(who.generation != 0, "thêm được người");
    using actor::Stat;
    context.expect(stat_of(scene, who, Stat::kAttackPhy) == 337 && stat_of(scene, who, Stat::kDefencePhy) == 612 &&
            stat_of(scene, who, Stat::kMaxHp) == 6510,
        "chỉ số gốc (golden_combat.py stats 3 60)");
    // Buff 9002 (+100 công ngoại, +50 thủ ngoại, +200 HP tối đa) và 9008 (+10% công ngoại gốc: 337*10/100 = 33,7 -> 34).
    context.expect(scene.arena.cast(who, 1002, 1, Target{who, {0, 0}, 0}) == CastOutcome::kOk, "ra chiêu buff");
    scene.arena.tick();  // hiệu ứng giao ở bước 1
    context.expect(stat_of(scene, who, Stat::kAttackPhy) == 337 + 100 && stat_of(scene, who, Stat::kDefencePhy) == 612 + 50 &&
            stat_of(scene, who, Stat::kMaxHp) == 6510 + 200 && has_buff(scene, who, 9002),
        "buff điểm cộng thẳng");
    static_cast<void>(scene.arena.send_effect(who, 9008, origin_from(who)));
    scene.arena.tick();
    context.expect(stat_of(scene, who, Stat::kAttackPhy) == 337 + 100 + 34, "buff phần trăm cộng dồn: 337 + 100 + 34");
    // Hết hạn: 9002 giao ở bước 1 nên tan ở bước 21; 9008 giao ở bước 2 nên tan ở bước 22.
    run_ticks(scene.arena, 19);  // bước 3..21
    context.expect(stat_of(scene, who, Stat::kAttackPhy) == 337 + 34 && !has_buff(scene, who, 9002) && has_buff(scene, who, 9008),
        "9002 tan ở bước 21, 9008 còn");
    scene.arena.tick();  // bước 22
    context.expect(stat_of(scene, who, Stat::kAttackPhy) == 337 && stat_of(scene, who, Stat::kMaxHp) == 6510 &&
            !has_buff(scene, who, 9008),
        "hết buff thì về chỉ số gốc");
}

void passive_armor(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
    Fighter* fighter = scene.arena.find(who);
    if (fighter == nullptr) {
        context.expect(false, "có người");
        return;
    }
    actor::Modifiers equipment;
    equipment.equip_base[actor::Stat::kDefencePhy] = 200;
    fighter->body.set_equipment(equipment);
    context.expect(fighter->body.stat(actor::Stat::kDefencePhy) == 612 + 200, "thủ ngoại gốc cộng điểm trang bị 200");
    context.expect(scene.arena.learn(who, 1011, 1), "học kỹ năng bị động");
    scene.arena.refresh(who);
    // Bị động cộng 50% điểm thủ gốc của trang bị: 200 * 50 / 100 = 100.
    context.expect(fighter->body.stat(actor::Stat::kDefencePhy) == 612 + 200 + 100, "bị động giáp +50% điểm trang bị");
    context.expect(scene.arena.cast(who, 1011, 1, Target{who, {0, 0}, 0}) == CastOutcome::kForbidden, "kỹ năng bị động không ra chiêu được");
}

// ---------------------------------------------------------------------------------------------------------
// Một đòn: trúng, né, hội tâm theo hạt giống

struct StrikeGolden {
    std::uint64_t seed;
    bool hit;
    bool critical;
    std::int32_t damage;
};

struct StrikeRun {
    CastOutcome outcome = CastOutcome::kNoCaster;
    std::vector<Event> damage;
    std::size_t misses = 0;
    std::int32_t victim_hp = 0;
    std::int32_t victim_max_hp = 0;
};

// A ra chiêu `skill` về phía B (cách `distance_cm`), rồi chạy `ticks` bước.
StrikeRun run_strike(const Catalog& catalog, const actor::Rules& rules, std::uint64_t seed, std::uint32_t skill,
    const Person& attacker, const Person& victim, std::int32_t distance_cm, std::int32_t ticks) {
    Scene scene(catalog, seed);
    make_hostile(scene.arena);
    const ids::EntityHandle a = add_person(scene, rules, attacker, {0, 0});
    const ids::EntityHandle b = add_person(scene, rules, victim, {distance_cm, 0});
    scene.arena.learn(a, skill, 1);
    if (Fighter* fighter = scene.arena.find(a)) fighter->weapon_type = 1;
    StrikeRun run;
    run.outcome = scene.arena.cast(a, skill, 1, Target{b, {distance_cm, 0}, 0});
    run_ticks(scene.arena, ticks);
    run.damage = events_of(scene.arena, EventKind::kDamaged);
    run.misses = events_of(scene.arena, EventKind::kMissed).size();
    if (const Fighter* fighter = scene.arena.find(b)) {
        run.victim_hp = fighter->body.hp();
        run.victim_max_hp = fighter->body.stat(actor::Stat::kMaxHp);
    }
    return run;
}

void check_strike(Context& context, const StrikeRun& run, const StrikeGolden& want, std::uint64_t arrival_tick) {
    context.expect(run.outcome == CastOutcome::kOk, "đã nhận lệnh ra chiêu");
    if (!want.hit) {
        context.expect(run.misses == 1 && run.damage.empty() && run.victim_hp == run.victim_max_hp, "trượt: không mất máu");
        return;
    }
    context.expect(run.misses == 0 && run.damage.size() == 1, "trúng: đúng một lần mất máu");
    if (run.damage.size() != 1) return;
    const Event& hit = run.damage.front();
    context.expect(hit.value == want.damage && (hit.extra != 0) == want.critical && hit.tick.value() == arrival_tick,
        "sát thương, cờ hội tâm và bước tới đích khớp số vàng");
    context.expect(run.victim_hp == run.victim_max_hp - want.damage, "HP còn lại");
}

void strike_golden_seeds(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    // Võ Đang đánh Thiếu Lâm: trúng 77%, hội tâm 7%, dao động 20%. Hạt 5 trượt (xúc xắc 85 >= 77); hạt 1, 2, 3 trúng
    // với dao động +20%, -3%?, +... (xúc xắc dao động 0, 89, 5); hạt 6 trúng và hội tâm (xúc xắc 21, 3, 0).
    constexpr std::array<StrikeGolden, 5> kGolden{{
        {5, false, false, 0},
        {1, true, false, 1627},
        {2, true, false, 1153},
        {3, true, false, 1600},
        {6, true, true, 3254},
    }};
    for (const StrikeGolden& want : kGolden) {
        const StrikeRun run = run_strike(*catalog, *rules, want.seed, 1001, kWudang, kShaolin, 500, 1);
        check_strike(context, run, want, 1);
        context.expect(run.victim_max_hp == 14465, "HP tối đa Thiếu Lâm 60");
    }
}

void real_skill_cast(Context& context) {
    const Catalog* catalog = real_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    // Phục Hổ Quyền (281) của Thiếu Lâm 60 vào Võ Đang 60: hiệu ứng 201 cộng 58 công ngoại, 58 công nội, 2 công điện.
    // Đòn tới đích sau 400 ms = 8 bước. Số vàng từ golden_combat.py scan <n> thật.
    constexpr std::array<StrikeGolden, 5> kGolden{{
        {2, false, false, 0},
        {1, true, false, 1075},
        {3, true, false, 1065},
        {4, true, false, 970},
        {6, true, true, 2150},
    }};
    for (const StrikeGolden& want : kGolden) {
        const StrikeRun early = run_strike(*catalog, *rules, want.seed, 281, kShaolin, kWudang, 150, 7);
        context.expect(early.outcome == CastOutcome::kOk && early.damage.empty() && early.victim_hp == early.victim_max_hp,
            "7 bước chưa tới đích: chưa mất máu");
        const StrikeRun run = run_strike(*catalog, *rules, want.seed, 281, kShaolin, kWudang, 150, 8);
        check_strike(context, run, want, 8);
        context.expect(run.victim_max_hp == 6510, "HP tối đa Võ Đang 60");
    }
    // Ngoài tầm (2 m + 1 m sai số) thì bị từ chối ngay.
    const StrikeRun far = run_strike(*catalog, *rules, 1, 281, kShaolin, kWudang, 301, 8);
    context.expect(far.outcome == CastOutcome::kOutOfRange && far.damage.empty(), "ngoài tầm");
    const StrikeRun edge = run_strike(*catalog, *rules, 1, 281, kShaolin, kWudang, 300, 8);
    context.expect(edge.outcome == CastOutcome::kOk, "đúng sát mép tầm cộng sai số vẫn ra được");
}

void cast_refusals(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const Catalog* real = real_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || real == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 3);
    make_hostile(scene.arena);
    const ids::EntityHandle a = add_person(scene, *rules, kWudang, {0, 0});
    const ids::EntityHandle b = add_person(scene, *rules, kShaolin, {500, 0});
    const Target at_b{b, {500, 0}, 0};
    context.expect(scene.arena.cast(ids::EntityHandle{99, 1}, 1001, 1, at_b) == CastOutcome::kNoCaster, "người ra chiêu không có");
    context.expect(scene.arena.cast(a, 31337, 1, at_b) == CastOutcome::kUnknownSkill, "kỹ năng lạ");
    context.expect(scene.arena.cast(a, 1001, 1, Target{ids::EntityHandle{99, 1}, {0, 0}, 0}) == CastOutcome::kInvalidTarget,
        "mục tiêu không có");
    context.expect(scene.arena.cast(a, 1001, 1, Target{b, {500, 0}, 0}) == CastOutcome::kOk, "ra chiêu thường");
    context.expect(scene.arena.cast(a, 1001, 1, at_b) == CastOutcome::kBusy, "đang bận hành động");
    run_ticks(scene.arena, 20);  // hết 1000 ms khoá hành động
    context.expect(scene.arena.cast(a, 1001, 1, at_b) == CastOutcome::kOk, "hết khoá thì ra chiêu tiếp được");

    // Kỹ năng thật 281 cần học và cần vũ khí.
    Scene real_scene(*real, 3);
    make_hostile(real_scene.arena);
    const ids::EntityHandle c = add_person(real_scene, *rules, kShaolin, {0, 0});
    const ids::EntityHandle d = add_person(real_scene, *rules, kWudang, {100, 0});
    const Target at_d{d, {100, 0}, 0};
    context.expect(real_scene.arena.cast(c, 281, 1, at_d) == CastOutcome::kNotLearned, "chưa học");
    static_cast<void>(real_scene.arena.learn(c, 281, 1));
    context.expect(real_scene.arena.cast(c, 281, 1, at_d) == CastOutcome::kNoWeapon, "tay không không dùng được kỹ năng cần vũ khí");
    real_scene.arena.find(c)->weapon_type = 1;
    context.expect(real_scene.arena.cast(c, 281, 2, at_d) == CastOutcome::kNotLearned, "cấp cao hơn cấp đã học");
    context.expect(real_scene.arena.cast(c, 281, 1, at_d) == CastOutcome::kOk, "đủ điều kiện");
    // Nội lực: 282 tiêu 33 nội lực, thiếu thì từ chối.
    static_cast<void>(real_scene.arena.learn(c, 282, 1));
    run_ticks(real_scene.arena, 20);
    Fighter* caster = real_scene.arena.find(c);
    static_cast<void>(caster->body.change_mp(-caster->body.mp()));
    context.expect(real_scene.arena.cast(c, 282, 1, Target{c, {0, 0}, 0}) == CastOutcome::kLackMana, "thiếu nội lực");
    static_cast<void>(caster->body.change_mp(33));
    context.expect(real_scene.arena.cast(c, 282, 1, Target{c, {0, 0}, 0}) == CastOutcome::kOk && caster->body.mp() == 0,
        "đủ 33 nội lực thì ra được và nội lực về 0");
}

// ---------------------------------------------------------------------------------------------------------
// Hồi chiêu và buff

void cooldown_exact_tick(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
    const Target self{who, {0, 0}, 0};
    context.expect(scene.arena.cast(who, 1003, 1, self) == CastOutcome::kOk, "ra chiêu ở bước 0");
    const Fighter* fighter = scene.arena.find(who);
    context.expect(fighter != nullptr && scene.arena.cooldown_remaining(*fighter, 7) == 60, "hồi chiêu 3000 ms là 60 bước");
    run_ticks(scene.arena, 59);
    context.expect(scene.arena.now().value() == 59 && scene.arena.cast(who, 1003, 1, self) == CastOutcome::kCooldown,
        "bước 59 còn hồi chiêu");
    context.expect(scene.arena.cooldown_remaining(*fighter, 7) == 1, "còn đúng 1 bước");
    scene.arena.tick();
    context.expect(scene.arena.now().value() == 60 && scene.arena.cooldown_remaining(*fighter, 7) == 0 &&
            fighter->cooldowns.empty(),
        "bước 60 hết hồi chiêu và nhóm bị dọn");
    context.expect(scene.arena.cast(who, 1003, 1, self) == CastOutcome::kOk, "bước 60 ra chiêu được");
    scene.arena.clear_cooldown(*scene.arena.find(who), 7);
    context.expect(scene.arena.cooldown_remaining(*fighter, 7) == 0, "xoá hồi chiêu");
    scene.arena.set_cooldown(*scene.arena.find(who), 7, 5);
    context.expect(scene.arena.cooldown_remaining(*fighter, 7) == 5, "đặt hồi chiêu 5 bước");
    scene.arena.set_cooldown(*scene.arena.find(who), -1, 5);
    context.expect(fighter->cooldowns.size() == 1, "nhóm -1 không có hồi chiêu");
}

void buff_expires_on_exact_tick(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
    context.expect(scene.arena.send_effect(who, 9002, origin_from(who)), "xếp hàng hiệu ứng");
    context.expect(scene.arena.pending_count() == 1 && !has_buff(scene, who, 9002), "chưa giao khi chưa tick");
    scene.arena.tick();
    context.expect(has_buff(scene, who, 9002) && scene.arena.pending_count() == 0, "giao ở bước 1");
    run_ticks(scene.arena, 19);  // bước 20
    context.expect(has_buff(scene, who, 9002), "bước 20 buff còn (đã trôi 19 bước)");
    scene.arena.tick();  // bước 21
    context.expect(!has_buff(scene, who, 9002), "bước 21 buff tan: sống đúng 20 bước sau khi nhận");
    const std::vector<Event> added = events_of(scene.arena, EventKind::kBuffAdded);
    const std::vector<Event> removed = events_of(scene.arena, EventKind::kBuffRemoved);
    context.expect(added.size() == 1 && added.front().tick.value() == 1 && added.front().id == 9002 && added.front().value == 20,
        "sự kiện nhận buff ở bước 1, kèm thời gian 20 bước");
    context.expect(removed.size() == 1 && removed.front().tick.value() == 21 && removed.front().id == 9002,
        "sự kiện mất buff ở bước 21");
    // Hiệu ứng không có trong bảng và người nhận không có.
    context.expect(!scene.arena.send_effect(ids::EntityHandle{99, 1}, 9002, origin_from(who)), "người nhận không có");
    scene.arena.clear_events();
    context.expect(!scene.arena.send_effect(who, 77777, origin_from(who)), "hiệu ứng không có trong bảng");
    const std::vector<Event> missing = events_of(scene.arena, EventKind::kUnsupported);
    context.expect(missing.size() == 1 && missing.front().id == 77777U &&
            missing.front().value == static_cast<std::int32_t>(UnsupportedReason::kMissingData),
        "báo thiếu dữ liệu hiệu ứng");
}

void periodic_damage(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle a = add_person(scene, *rules, kWudang, {0, 0});
    const ids::EntityHandle b = add_person(scene, *rules, kShaolin, {100, 0});
    context.expect(scene.arena.send_effect(b, 9003, origin_from(a)), "gửi hiệu ứng chu kỳ");
    run_ticks(scene.arena, 70);
    // Giao ở bước 1; chu kỳ 20 bước nên phát ở bước 21, 41, 61; sống 60 bước nên tan ở bước 61 (sau nhát cuối).
    std::vector<std::uint64_t> ticks;
    bool all_hundred = true;
    for (const Event& event : events_of(scene.arena, EventKind::kDamaged)) {
        ticks.push_back(event.tick.value());
        all_hundred = all_hundred && event.value == 100 && event.actor == a && event.target == b;
    }
    context.expect(ticks == std::vector<std::uint64_t>({21, 41, 61}) && all_hundred, "ba nhát 100 ở bước 21, 41, 61");
    const std::vector<Event> removed = events_of(scene.arena, EventKind::kBuffRemoved);
    context.expect(removed.size() == 1 && removed.front().tick.value() == 61, "buff tan ở bước 61");
    context.expect(!has_buff(scene, b, 9003), "không còn buff");
}

void shield_absorbs(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle a = add_person(scene, *rules, kWudang, {0, 0});
    const ids::EntityHandle b = add_person(scene, *rules, kShaolin, {100, 0});
    static_cast<void>(scene.arena.send_effect(b, 9009, origin_from(a)));
    scene.arena.tick();
    context.expect(has_buff(scene, b, 9009), "khiên đã giao");
    for (int hit = 1; hit <= 3; ++hit) {
        static_cast<void>(scene.arena.send_effect(b, 9005, origin_from(a)));
        scene.arena.tick();
        context.expect(events_of(scene.arena, EventKind::kDamaged).empty() && scene.arena.find(b)->body.hp() == 14465,
            "ba nhát 50 đầu bị khiên 150 máu hút hết");
    }
    context.expect(!has_buff(scene, b, 9009) && events_of(scene.arena, EventKind::kBuffRemoved).size() == 1, "hết máu khiên thì tan");
    static_cast<void>(scene.arena.send_effect(b, 9005, origin_from(a)));
    scene.arena.tick();
    const std::vector<Event> damaged = events_of(scene.arena, EventKind::kDamaged);
    context.expect(damaged.size() == 1 && damaged.front().value == 50 && scene.arena.find(b)->body.hp() == 14465 - 50,
        "nhát thứ tư không còn khiên: mất 50");
}

void heal_flow(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle a = add_person(scene, *rules, kWudang, {0, 0});
    const ids::EntityHandle b = add_person(scene, *rules, kShaolin, {100, 0});
    static_cast<void>(scene.arena.send_effect(b, 9005, origin_from(a)));
    scene.arena.tick();
    context.expect(scene.arena.find(b)->body.hp() == 14465 - 50, "mất 50 máu");
    static_cast<void>(scene.arena.send_effect(b, 9007, origin_from(a)));  // hồi 500, chỉ thiếu 50
    scene.arena.tick();
    const std::vector<Event> healed = heals_by_others(scene.arena);
    context.expect(scene.arena.find(b)->body.hp() == 14465 && healed.size() == 1 && healed.front().value == 500 &&
            healed.front().actor == a && healed.front().target == b,
        "hồi đầy máu, sự kiện ghi lượng tính được (500)");
    // Người đã chết không nhận hồi máu.
    static_cast<void>(scene.arena.kill(b, a));
    scene.arena.clear_events();
    static_cast<void>(scene.arena.send_effect(b, 9007, origin_from(a)));
    scene.arena.tick();
    context.expect(heals_by_others(scene.arena).empty() && scene.arena.find(b)->body.hp() == 0, "xác không được hồi máu");
}

// ---------------------------------------------------------------------------------------------------------
// Chết và hồi sinh

void death_and_revive(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    make_hostile(scene.arena);
    const ids::EntityHandle a = add_person(scene, *rules, kShaolin, {0, 0});
    const ids::EntityHandle b = add_person(scene, *rules, kWudang, {300, 0});
    context.expect(scene.arena.cast(a, 1005, 1, Target{b, {300, 0}, 0}) == CastOutcome::kOk, "ra chiêu chí mạng");
    scene.arena.tick();
    const Fighter* victim = scene.arena.find(b);
    context.expect(victim != nullptr && !victim->alive() && victim->body.hp() == 0 && victim->body.rage() == 0, "chết");
    const std::vector<Event> died = events_of(scene.arena, EventKind::kDied);
    const std::vector<Event> damaged = events_of(scene.arena, EventKind::kDamaged);
    context.expect(died.size() == 1 && died.front().actor == a && died.front().target == b && damaged.size() == 1 &&
            damaged.front().value == 1'000'000,
        "một sự kiện chết do A, sát thương ghi lượng tính được");
    run_ticks(scene.arena, 40);
    context.expect(scene.arena.cast(a, 1005, 1, Target{b, {300, 0}, 0}) == CastOutcome::kTargetDead, "không đánh xác");
    context.expect(scene.arena.cast(b, 1005, 1, Target{a, {0, 0}, 0}) == CastOutcome::kDead, "xác không ra chiêu");
    context.expect(!scene.arena.kill(b, a), "giết xác không có tác dụng");
    // Hồi sinh 50% HP (6510 / 2 = 3255, không lẻ) và 0 MP, nộ khí 100 điểm.
    scene.arena.clear_events();
    context.expect(!scene.arena.accept_relive(b), "chưa có đề nghị hồi sinh");
    context.expect(scene.arena.revive(b, actor::Revival{actor::Amount{.percent = true, .value = 50}, actor::Amount{.percent = true, .value = 0}, actor::Amount{.percent = false, .value = 100}}),
        "hồi sinh");
    context.expect(victim->alive() && victim->body.hp() == 3255 && victim->body.mp() == 0 && victim->body.rage() == 100,
        "50% HP, 0 MP, 100 nộ khí");
    const std::vector<Event> revived = events_of(scene.arena, EventKind::kRevived);
    context.expect(revived.size() == 1 && revived.front().target == b && revived.front().value == 3255, "sự kiện hồi sinh");
    context.expect(!scene.arena.revive(b, actor::Revival{}), "đang sống thì không hồi sinh");
    context.expect(scene.arena.cast(a, 1005, 1, Target{b, {300, 0}, 0}) == CastOutcome::kOk, "sống lại thì lại bị đánh được");
}

// ---------------------------------------------------------------------------------------------------------
// Gom khí, gián đoạn, đòn vùng, logic chưa hỗ trợ

void charge_and_interrupt(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    {
        Scene scene(*catalog, 1);
        const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
        const Target self{who, {0, 0}, 0};
        context.expect(scene.arena.cast(who, 1013, 1, self) == CastOutcome::kOk, "bắt đầu gom khí");
        context.expect(scene.arena.cast(who, 1013, 1, self) == CastOutcome::kBusy, "đang gom thì bận");
        run_ticks(scene.arena, 19);
        context.expect(events_of(scene.arena, EventKind::kImpact).empty() && events_of(scene.arena, EventKind::kCastFinished).empty(),
            "bước 19 chưa gom xong");
        scene.arena.tick();
        const std::vector<Event> finished = events_of(scene.arena, EventKind::kCastFinished);
        const std::vector<Event> impacts = events_of(scene.arena, EventKind::kImpact);
        context.expect(finished.size() == 1 && finished.front().tick.value() == 20 && impacts.size() == 1 &&
                impacts.front().tick.value() == 20,
            "gom 1000 ms xong ở bước 20");
    }
    {
        Scene scene(*catalog, 1);
        const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
        context.expect(scene.arena.cast(who, 1013, 1, Target{who, {0, 0}, 0}) == CastOutcome::kOk, "gom khí");
        run_ticks(scene.arena, 10);
        context.expect(scene.arena.cancel_cast(who) && !scene.arena.cancel_cast(who), "huỷ gom khí một lần");
        run_ticks(scene.arena, 30);
        context.expect(events_of(scene.arena, EventKind::kImpact).empty() && events_of(scene.arena, EventKind::kCastInterrupted).size() == 1,
            "huỷ thì không có hiệu ứng");
    }
    {
        // Bị đánh lúc đang gom: cộng thêm thời gian đã gom, tối đa 500 ms = 10 bước. Gom ở bước 0 (còn 20); tới bước 11 còn 9
        // (đã gom 11) nên chậm thêm 10 -> 19 và gom xong ở bước 30.
        Scene scene(*catalog, 1);
        const ids::EntityHandle a = add_person(scene, *rules, kWudang, {0, 0});
        const ids::EntityHandle b = add_person(scene, *rules, kShaolin, {100, 0});
        context.expect(scene.arena.cast(a, 1014, 1, Target{a, {0, 0}, 0}) == CastOutcome::kOk, "gom khí dễ gián đoạn");
        run_ticks(scene.arena, 10);
        static_cast<void>(scene.arena.send_effect(a, 9005, origin_from(b)));
        scene.arena.tick();  // bước 11: nhát 50 làm gián đoạn
        run_ticks(scene.arena, 18);  // bước 29
        // Nhát 50 cũng phát một sự kiện kImpact nên đo "gom xong" bằng kCastFinished của chính kỹ năng 1014.
        const auto finished_1014 = [&scene] {
            std::vector<Event> out;
            for (const Event& event : events_of(scene.arena, EventKind::kCastFinished)) {
                if (event.id == 1014U) out.push_back(event);
            }
            return out;
        };
        context.expect(finished_1014().empty(), "bước 29 chưa xong vì bị đẩy lùi");
        scene.arena.tick();
        const std::vector<Event> finished = finished_1014();
        context.expect(finished.size() == 1 && finished.front().tick.value() == 30, "xong ở bước 30");
    }
}

void area_targets(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    // Thành viên cùng "đội" khi character / 100 giống nhau.
    for (const std::uint32_t skill : {1004U, 1012U}) {
        Scene scene(*catalog, 1);
        scene.arena.set_relation_policy([](const Fighter& from, const Fighter& to) {
            return from.character / 100 == to.character / 100 ? Relation::kFriend : Relation::kEnemy;
        });
        const ids::EntityHandle caster = add_person(scene, *rules, kWudang, {0, 0}, 100);
        const ids::EntityHandle e1 = add_person(scene, *rules, kShaolin, {300, 0}, 200);   // 3 m, handle nhỏ hơn e3
        const ids::EntityHandle e2 = add_person(scene, *rules, kShaolin, {100, 0}, 201);   // 1 m
        const ids::EntityHandle e3 = add_person(scene, *rules, kShaolin, {0, 300}, 202);   // 3 m
        const ids::EntityHandle far_enemy = add_person(scene, *rules, kShaolin, {600, 0}, 203);  // 6 m: ngoài vòng 5 m
        const ids::EntityHandle friend_unit = add_person(scene, *rules, kShaolin, {200, 0}, 101);  // cùng đội
        const ids::EntityHandle corpse = add_person(scene, *rules, kShaolin, {250, 0}, 204);
        static_cast<void>(scene.arena.kill(corpse, caster));
        scene.arena.clear_events();
        context.expect(scene.arena.cast(caster, skill, 1, Target{caster, {0, 0}, 0}) == CastOutcome::kOk, "ra đòn vùng");
        scene.arena.tick();
        std::vector<ids::EntityHandle> order;
        bool all_fifty = true;
        for (const Event& event : events_of(scene.arena, EventKind::kDamaged)) {
            if (event.actor != caster) continue;
            order.push_back(event.target);
            // Đòn vùng có thể hội tâm (7%): khi đó nhát 50 gấp đôi, cờ nằm ở `extra`.
            all_fifty = all_fifty && event.value == (event.extra != 0 ? 100 : 50);
        }
        // Gần trước, cùng khoảng cách thì handle nhỏ trước; kỹ năng 1012 giới hạn hai mục tiêu.
        const std::vector<ids::EntityHandle> want = skill == 1004U ? std::vector<ids::EntityHandle>{e2, e1, e3}
                                                                   : std::vector<ids::EntityHandle>{e2, e1};
        context.expect(order == want && all_fifty, "thứ tự và số mục tiêu của đòn vùng");
        static_cast<void>(far_enemy);
        static_cast<void>(friend_unit);
    }
}

void relation_policy(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle a = add_person(scene, *rules, kWudang, {0, 0});
    const ids::EntityHandle b = add_person(scene, *rules, kWudang, {0, 0});
    const ids::EntityHandle c = add_person(scene, *rules, kWudang, {0, 0});
    scene.arena.find(a)->body.set_base_camp(0);
    scene.arena.find(b)->body.set_base_camp(1);
    scene.arena.find(c)->body.set_base_camp(0);
    const Fighter& fa = *scene.arena.find(a);
    const Fighter& fb = *scene.arena.find(b);
    const Fighter& fc = *scene.arena.find(c);
    context.expect(scene.arena.relation(fa, fb) == Relation::kEnemy && scene.arena.relation(fb, fa) == Relation::kEnemy &&
            scene.arena.relation(fa, fc) == Relation::kFriend && scene.arena.relation(fa, fa) == Relation::kFriend &&
            scene.arena.is_friend(fb, fb),
        "ma trận phe tổng hợp: 0 thù 1, mỗi phe thân với chính nó");
    scene.arena.set_relation_policy([](const Fighter&, const Fighter&) { return Relation::kFriend; });
    context.expect(scene.arena.relation(fa, fb) == Relation::kFriend, "chính sách riêng thắng ma trận");
}

void unsupported_and_missing_data(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1);
    const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
    const Target self{who, {0, 0}, 0};
    context.expect(scene.arena.cast(who, 1007, 1, self) == CastOutcome::kUnsupported, "logic 701 chưa có mã");
    const std::vector<Event> unsupported = events_of(scene.arena, EventKind::kUnsupported);
    context.expect(unsupported.size() == 1 && unsupported.front().id == 1007U &&
            unsupported.front().value == static_cast<std::int32_t>(UnsupportedReason::kUnknownLogic),
        "báo logic chưa có mã");
    scene.arena.clear_events();
    context.expect(scene.arena.cast(who, 1009, 1, self) == CastOutcome::kUnsupported && scene.arena.events().empty(),
        "logic không có trong bảng: từ chối, không sự kiện");
    context.expect(scene.arena.cast(who, 1008, 1, self) == CastOutcome::kOk, "kỹ năng trỏ hiệu ứng vắng vẫn ra chiêu");
    scene.arena.tick();
    const std::vector<Event> missing = events_of(scene.arena, EventKind::kUnsupported);
    context.expect(missing.size() == 1 && missing.front().id == 77777U &&
            missing.front().value == static_cast<std::int32_t>(UnsupportedReason::kMissingData),
        "báo thiếu dữ liệu hiệu ứng 77777");
    context.expect(describe(CastOutcome::kOk) != describe(CastOutcome::kCooldown) &&
            !describe(static_cast<CastOutcome>(250)).empty(),
        "describe có chữ cho mọi mã");
}

// ---------------------------------------------------------------------------------------------------------
// Lưu và khôi phục

CombatRecord sample_record() {
    CombatRecord record;
    record.skills = {{1001, 1}, {1003, 2}, {40000, 16}};
    record.cooldowns = {{7, 55}, {53, 4'000'000}};
    SavedBuff first;
    first.effect = 9002;
    first.skill = 1002;
    first.caster_character = 4242;
    first.by_player = true;
    first.critical = true;
    first.continuance = 20;
    first.elapsed = 4;
    first.refix = -10;
    first.slot = {1, -2, 3, -4, 5, -6, 7, -8};
    SavedBuff second;
    second.effect = 9010;
    second.continuance = -1;  // vô hạn
    record.buffs = {first, second};
    return record;
}

void codec_round_trip(Context& context) {
    const CombatRecord original = sample_record();
    Bytes bytes;
    context.expect(encode_combat(original, bytes).has_value() && !bytes.empty(), "mã hoá");
    const auto decoded = decode_combat(bytes);
    context.expect(decoded.has_value() && *decoded == original, "giải mã ra đúng bản ghi");
    Bytes again;
    context.expect(encode_combat(*decoded, again).has_value() && again == bytes, "mã hoá lại ra đúng byte cũ");
    // Nối vào cuối bộ đệm có sẵn.
    Bytes prefixed(3, std::byte{0xAA});
    context.expect(encode_combat(original, prefixed).has_value() && prefixed.size() == 3 + bytes.size() &&
            std::equal(bytes.begin(), bytes.end(), prefixed.begin() + 3),
        "nối thêm vào cuối");
    CombatRecord empty;
    Bytes empty_bytes;
    const auto empty_back = encode_combat(empty, empty_bytes).has_value() ? decode_combat(empty_bytes) : decode_combat({});
    context.expect(empty_back.has_value() && *empty_back == empty, "bản ghi rỗng");
    context.expect(kRecordKind == 0x5202 && kRecordVersion == 1, "kind và phiên bản đã chốt");
}

void codec_rejects_bad_input(Context& context) {
    const CombatRecord original = sample_record();
    Bytes bytes;
    context.expect(encode_combat(original, bytes).has_value(), "mã hoá");
    bool all_truncated = true;
    for (std::size_t length = 0; length < bytes.size(); ++length) {
        all_truncated = all_truncated && !decode_combat(protocol::ByteView(bytes.data(), length)).has_value();
    }
    context.expect(all_truncated, "mọi tiền tố ngắn hơn bị từ chối");
    Bytes trailing = bytes;
    trailing.push_back(std::byte{0});
    const auto trailing_result = decode_combat(trailing);
    context.expect(!trailing_result.has_value() && trailing_result.error() == CodecError::kTrailing, "byte thừa");
    // Lật từng bit: hoặc lỗi hoặc bản ghi hợp lệ mã hoá lại được; không bao giờ vi phạm bất biến.
    std::size_t accepted = 0;
    bool invariants_hold = true;
    for (std::size_t at = 0; at < bytes.size(); ++at) {
        for (int bit = 0; bit < 8; ++bit) {
            Bytes mutated = bytes;
            mutated.at(at) = mutated.at(at) ^ static_cast<std::byte>(1U << bit);
            const auto result = decode_combat(mutated);
            if (!result) continue;
            ++accepted;
            Bytes back;
            invariants_hold = invariants_hold && encode_combat(*result, back).has_value() && result->skills.size() <= kMaxSkills &&
                std::ranges::all_of(result->skills, [](const SkillEntry& entry) { return entry.level >= 1 && entry.level <= kMaxSkillLevel; });
        }
    }
    context.expect(invariants_hold, "bản ghi chấp nhận luôn hợp lệ");
    context.expect(accepted > 0 && accepted < bytes.size() * 8, "có lật bit vẫn hợp lệ (số liệu) nhưng không phải tất cả");
    Bytes wrong_version = bytes;
    wrong_version.at(protocol::kHeaderBytes) = std::byte{9};
    const auto version_result = decode_combat(wrong_version);
    context.expect(!version_result.has_value() && version_result.error() == CodecError::kBadVersion, "phiên bản lạ");
    Bytes wrong_kind = bytes;
    if (!wrong_kind.empty()) wrong_kind.front() = wrong_kind.front() ^ std::byte{1};
    context.expect(!decode_combat(wrong_kind).has_value(), "đầu khung hỏng");

    // Bản ghi vi phạm bất biến không mã hoá được và không để lại byte.
    Bytes sink;
    const auto refuses = [&](CombatRecord record, std::string_view what) {
        context.expect(!encode_combat(record, sink).has_value() && sink.empty(), what);
    };
    CombatRecord bad = original;
    bad.skills = {{5, 1}, {5, 2}};
    refuses(bad, "kỹ năng trùng id");
    bad = original;
    bad.skills = {{9, 1}, {5, 1}};
    refuses(bad, "kỹ năng sai thứ tự");
    bad = original;
    bad.skills = {{5, 0}};
    refuses(bad, "cấp 0");
    bad = original;
    bad.skills = {{5, 17}};
    refuses(bad, "cấp 17");
    bad = original;
    bad.cooldowns = {{7, 0}};
    refuses(bad, "hồi chiêu còn 0 bước");
    bad = original;
    bad.cooldowns = {{9, 5}, {9, 6}};
    refuses(bad, "nhóm hồi chiêu trùng");
    bad = original;
    bad.cooldowns = {{-1, 5}};
    refuses(bad, "nhóm hồi chiêu âm");
    bad = original;
    bad.buffs.front().elapsed = 20;  // đã hết hạn
    refuses(bad, "buff đã hết hạn không được lưu");
    bad = original;
    bad.buffs.front().continuance = -2;
    refuses(bad, "thời lượng âm lạ");
    bad = original;
    bad.buffs.front().elapsed = -1;
    refuses(bad, "đã trôi âm");
    bad = original;
    bad.skills.clear();
    for (std::uint32_t id = 0; id <= kMaxSkills; ++id) bad.skills.push_back({id, 1});
    refuses(bad, "quá nhiều kỹ năng");
    bad = original;
    bad.buffs.assign(kMaxBuffs + 1, original.buffs.front());
    refuses(bad, "quá nhiều buff");
    context.expect(!describe(CodecError::kTruncated).empty() && !describe(static_cast<CodecError>(99)).empty(), "describe");
}

void snapshot_and_restore(Context& context) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 7);
    const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0}, 4242);
    static_cast<void>(scene.arena.learn(who, 1003, 1));
    static_cast<void>(scene.arena.learn(who, 1001, 1));
    context.expect(scene.arena.cast(who, 1003, 1, Target{who, {0, 0}, 0}) == CastOutcome::kOk, "ra chiêu có hồi chiêu");
    for (const std::uint32_t effect : {9002U, 9010U, 9011U}) static_cast<void>(scene.arena.send_effect(who, effect, origin_from(who)));
    run_ticks(scene.arena, 5);
    const Fighter* fighter = scene.arena.find(who);
    context.expect(fighter != nullptr && fighter->buff_count == 3, "ba buff đang mang");
    if (fighter == nullptr) return;
    const CombatRecord record = scene.arena.snapshot(*fighter);
    // Sổ kỹ năng sắp theo id; hồi chiêu còn 55 bước; buff 9011 tan khi ngoại tuyến nên không lưu. 9002 giao ở bước 1 nên
    // đã trôi 4 bước tại bước 5.
    context.expect(record.skills == std::vector<SkillEntry>({{1001, 1}, {1003, 1}}) &&
            record.cooldowns == std::vector<SavedCooldown>({{7, 55}}),
        "kỹ năng và hồi chiêu");
    context.expect(record.buffs.size() == 2 && record.buffs.at(0).effect == 9002 && record.buffs.at(0).continuance == 20 &&
            record.buffs.at(0).elapsed == 4 && record.buffs.at(0).by_player && record.buffs.at(0).caster_character == 4242 &&
            record.buffs.at(1).effect == 9010 && record.buffs.at(1).continuance == 1200 && record.buffs.at(1).elapsed == 4,
        "buff được lưu, buff tan khi ngoại tuyến bỏ");

    Bytes bytes;
    context.expect(encode_combat(record, bytes).has_value(), "mã hoá");
    const auto decoded = decode_combat(bytes);
    context.expect(decoded.has_value() && *decoded == record, "vòng mã hoá khép kín");
    if (!decoded) return;

    {
        Scene other(*catalog, 9);
        const ids::EntityHandle again = add_person(other, *rules, kWudang, {0, 0}, 4242);
        Fighter* restored = other.arena.find(again);
        other.arena.restore(*restored, *decoded, 30);
        context.expect(restored->skills.size() == 2 && other.arena.cooldown_remaining(*restored, 7) == 55 && restored->buff_count == 2,
            "khôi phục sổ kỹ năng, hồi chiêu, buff");
        // 9002 không tính giờ ngoại tuyến nên giữ nguyên đã trôi 4; 9010 tính giờ ngoại tuyến nên đã trôi 4 + 30.
        context.expect(restored->buffs.at(0).elapsed == 4 && restored->buffs.at(1).elapsed == 34, "chỉ buff tính giờ ngoại tuyến được cộng");
        context.expect(restored->body.stat(actor::Stat::kAttackPhy) == 337 + 100 + 7, "chỉ số tính lại theo buff khôi phục");
        run_ticks(other.arena, 16);  // 9002: 4 + 16 = 20 tan
        // Buff vừa tan chỉ bị gỡ khỏi mảng ở nhịp sau (đánh dấu fade_out trước), nên hỏi bằng find_buff_by_effect.
        context.expect(restored->find_buff_by_effect(9002) == nullptr && restored->find_buff_by_effect(9010) != nullptr &&
                restored->body.stat(actor::Stat::kAttackPhy) == 337 + 7,
            "buff khôi phục vẫn hết hạn đúng nhịp");
    }
    {
        Scene other(*catalog, 9);
        const ids::EntityHandle again = add_person(other, *rules, kWudang, {0, 0}, 4242);
        Fighter* restored = other.arena.find(again);
        other.arena.restore(*restored, *decoded, 2000);  // ngoại tuyến rất lâu: 9010 (60000 ms = 1200 bước) hết hạn
        context.expect(restored->buff_count == 1 && restored->buffs.at(0).effect == 9002 &&
                restored->body.stat(actor::Stat::kAttackPhy) == 337 + 100,
            "buff tính giờ ngoại tuyến hết hạn thì bị bỏ");
    }
    {
        // Hiệu ứng không còn trong bảng và dòng kỹ năng lặp hay cấp 0 bị bỏ khi khôi phục (bản ghi không qua bộ giải mã).
        CombatRecord odd;
        odd.skills = {{5, 1}, {5, 2}, {3, 0}};
        SavedBuff gone;
        gone.effect = 123456;
        gone.continuance = 10;
        SavedBuff instant;
        instant.effect = 9001;  // hiệu ứng tức thời không phải buff
        instant.continuance = 10;
        odd.buffs = {gone, instant};
        Scene other(*catalog, 9);
        const ids::EntityHandle again = add_person(other, *rules, kWudang, {0, 0}, 4242);
        Fighter* restored = other.arena.find(again);
        other.arena.restore(*restored, odd, 0);
        context.expect(restored->skills.size() == 1 && restored->skills.front().id == 5 && restored->buff_count == 0,
            "khôi phục bỏ dòng không hợp lệ");
    }
}

void durations_follow_hz(Context& context, std::int64_t hz) {
    const Catalog* catalog = synthetic_catalog(context);
    const actor::Rules* rules = real_rules(context);
    if (catalog == nullptr || rules == nullptr) return;
    Scene scene(*catalog, 1, hz);
    const ids::EntityHandle who = add_person(scene, *rules, kWudang, {0, 0});
    context.expect(scene.arena.send_effect(who, 9002, origin_from(who)), "xếp hàng buff");
    scene.arena.tick();
    run_ticks(scene.arena, static_cast<std::int32_t>(hz - 1));
    context.expect(has_buff(scene, who, 9002), "buff 1000 ms còn tới đúng số bước");
    scene.arena.tick();
    context.expect(!has_buff(scene, who, 9002), "buff tan ở bước kế, không sớm");
    const std::vector<Event> added = events_of(scene.arena, EventKind::kBuffAdded);
    context.expect(added.size() == 1 && added.front().value == static_cast<std::int32_t>(hz), "thời gian buff bằng số bước");

    Scene dots(*catalog, 2, hz);
    const ids::EntityHandle a = add_person(dots, *rules, kWudang, {0, 0});
    const ids::EntityHandle b = add_person(dots, *rules, kShaolin, {100, 0});
    context.expect(dots.arena.send_effect(b, 9003, origin_from(a)), "gửi độc");
    run_ticks(dots.arena, static_cast<std::int32_t>(hz * 3 + 2));
    std::vector<std::uint64_t> ticks;
    for (const Event& event : events_of(dots.arena, EventKind::kDamaged)) ticks.push_back(event.tick.value());
    const std::uint64_t step = static_cast<std::uint64_t>(hz);
    const std::vector<std::uint64_t> expect{1 + step, 1 + step * 2, 1 + step * 3};
    context.expect(ticks == expect, "ba nhát trong 3 giây mô phỏng");
    const std::vector<Event> removed = events_of(dots.arena, EventKind::kBuffRemoved);
    context.expect(removed.size() == 1 && removed.front().tick.value() == 1 + step * 3, "độc tan cùng nhát cuối");
}

void durations_follow_simulation_time(Context& context) {
    durations_follow_hz(context, 30);
    durations_follow_hz(context, 40);
}

constexpr std::array<Case, 23> kCases{{
    {"catalog_real_tables", catalog_real_tables},
    {"catalog_rejects_bad_tables", catalog_rejects_bad_tables},
    {"roles_grammar", roles_grammar},
    {"damage_formulas", damage_formulas},
    {"attributes_with_buffs", attributes_with_buffs},
    {"passive_armor", passive_armor},
    {"strike_golden_seeds", strike_golden_seeds},
    {"real_skill_cast", real_skill_cast},
    {"cast_refusals", cast_refusals},
    {"cooldown_exact_tick", cooldown_exact_tick},
    {"buff_expires_on_exact_tick", buff_expires_on_exact_tick},
    {"periodic_damage", periodic_damage},
    {"shield_absorbs", shield_absorbs},
    {"heal_flow", heal_flow},
    {"death_and_revive", death_and_revive},
    {"charge_and_interrupt", charge_and_interrupt},
    {"area_targets", area_targets},
    {"relation_policy", relation_policy},
    {"unsupported_and_missing_data", unsupported_and_missing_data},
    {"codec_round_trip", codec_round_trip},
    {"codec_rejects_bad_input", codec_rejects_bad_input},
    {"snapshot_and_restore", snapshot_and_restore},
    {"durations_follow_simulation_time", durations_follow_simulation_time},
}};

} // namespace
} // namespace game::combat

int main() {
    return game::test::run_all(game::combat::kCases);
}
