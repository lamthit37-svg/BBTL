#include "scenedata/ai_rules.hpp"

#include "scenedata/detail/cells.hpp"
#include "scenedata/tables.hpp"
#include "scenedata/types.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::scenedata {
namespace {

using detail::Cells;

constexpr std::int32_t kMaxInt = 2'000'000'000;

struct NamedFunction {
    std::string_view name;
    AiFunction function;
};

constexpr std::array<NamedFunction, 35> kFunctions{{
    {.name = "const", .function = AiFunction::kConst},
    {.name = "get_buff_state", .function = AiFunction::kGetBuffState},
    {.name = "get_ai_state", .function = AiFunction::kGetAiState},
    {.name = "get_hp", .function = AiFunction::kGetHp},
    {.name = "get_mp", .function = AiFunction::kGetMp},
    {.name = "rand", .function = AiFunction::kRand},
    {.name = "get_enemy_buff_state", .function = AiFunction::kGetEnemyBuffState},
    {.name = "get_enemy_mp", .function = AiFunction::kGetEnemyMp},
    {.name = "get_enemy_hp", .function = AiFunction::kGetEnemyHp},
    {.name = "get_enemy_sect", .function = AiFunction::kGetEnemySect},
    {.name = "get_enemy_level", .function = AiFunction::kGetEnemyLevel},
    {.name = "is_can_speak", .function = AiFunction::kIsCanSpeak},
    {.name = "is_has_enemy", .function = AiFunction::kIsHasEnemy},
    {.name = "get_enemy_sex", .function = AiFunction::kGetEnemySex},
    {.name = "get_camp", .function = AiFunction::kGetCamp},
    {.name = "get_pk", .function = AiFunction::kGetPk},
    {.name = "get_enemy_team_num", .function = AiFunction::kGetEnemyTeamNum},
    {.name = "is_enemy_has_special_item", .function = AiFunction::kIsEnemyHasSpecialItem},
    {.name = "get_single_damage", .function = AiFunction::kGetSingleDamage},
    {.name = "get_enemy_num", .function = AiFunction::kGetEnemyNum},
    {.name = "is_boss", .function = AiFunction::kIsBoss},
    {.name = "is_can_skill", .function = AiFunction::kIsCanSkill},
    {.name = "be_skill", .function = AiFunction::kBeSkill},
    {.name = "to_flee", .function = AiFunction::kToFlee},
    {.name = "to_skill", .function = AiFunction::kToSkill},
    {.name = "to_summon", .function = AiFunction::kToSummon},
    {.name = "to_long_attack", .function = AiFunction::kToLongAttack},
    {.name = "to_follow", .function = AiFunction::kToFollow},
    {.name = "to_speak", .function = AiFunction::kToSpeak},
    {.name = "to_assist_teammate", .function = AiFunction::kToAssistTeammate},
    {.name = "call_other_monster_by_group", .function = AiFunction::kCallOtherMonsterByGroup},
    {.name = "call_other_monster_by_team", .function = AiFunction::kCallOtherMonsterByTeam},
    {.name = "set_base_ai_type", .function = AiFunction::kSetBaseAiType},
    {.name = "set_patrol_id", .function = AiFunction::kSetPatrolId},
    {.name = "start_patrol", .function = AiFunction::kStartPatrol},
}};

constexpr std::array<std::string_view, kAiSectionCount> kSectionNames{"common", "skill", "beskill", "damage", "dead"};

struct NamedCompare {
    std::string_view name;
    AiCompare compare;
};

constexpr std::array<NamedCompare, 6> kCompares{{
    {.name = "eq", .compare = AiCompare::kEq},
    {.name = "ne", .compare = AiCompare::kNe},
    {.name = "lt", .compare = AiCompare::kLt},
    {.name = "le", .compare = AiCompare::kLe},
    {.name = "gt", .compare = AiCompare::kGt},
    {.name = "ge", .compare = AiCompare::kGe},
}};

constexpr std::array<std::string_view, 15> kRuleColumns{"ai_id", "rule_index", "section", "priority", "times", "part",
    "seq", "function", "op", "value", "arg_0", "arg_1", "arg_2", "skill_id", "value_name"};
constexpr std::array<std::string_view, 2> kListedColumns{"ai_id", "rules"};

[[nodiscard]] std::unexpected<LoadError> fail(std::string_view file, std::string_view what) {
    return std::unexpected(LoadError{std::string(file) + ": " + std::string(what)});
}

// Ô số nguyên bắt buộc: khác các bảng cảnh, bảng luật không có ô rỗng hợp lệ.
std::int32_t required_int(Cells& cells, std::string_view column, std::int32_t low, std::int32_t high) {
    const std::optional<std::int32_t> value = cells.int_opt(column, low, high);
    if (!value) {
        cells.reject(column, "ô rỗng");
        return 0;
    }
    return *value;
}

// Đoạn thứ `section` của kịch bản. Qua std::span để chỉ số lúc chạy được kiểm biên ở chế độ hardening; section luôn
// < kAiSectionCount (read_section chỉ trả chỉ số của kSectionNames).
[[nodiscard]] std::vector<AiRule>& section_of(AiScript& script, std::size_t section) noexcept {
    return std::span<std::vector<AiRule>, kAiSectionCount>{script.sections}[section];
}

// Một dòng bảng: một nguyên tử cùng đầu luật của nó.
struct Row {
    std::int32_t ai_id = 0;
    std::uint32_t rule_index = 0;
    std::size_t section = 0;
    std::int32_t priority = 0;
    std::int32_t times = 0;
    bool condition = false;
    std::uint32_t seq = 0;
    AiAtom atom;
};

std::size_t read_section(Cells& cells) {
    const std::string name = cells.text("section");
    const auto at = std::ranges::find(kSectionNames, name);
    if (at == kSectionNames.end()) {
        cells.reject("section", "đoạn lạ");
        return 0;
    }
    return static_cast<std::size_t>(at - kSectionNames.begin());
}

bool read_part(Cells& cells) {
    const std::string part = cells.text("part");
    if (part != "if" && part != "do") cells.reject("part", "phải là if hoặc do");
    return part == "if";
}

AiFunction read_function(Cells& cells, bool condition) {
    const std::string name = cells.text("function");
    const std::optional<AiFunction> function = ai_function_from_name(name);
    if (!function) {
        cells.reject("function", "hàm lạ: " + name.substr(0, 64));
        return AiFunction::kConst;
    }
    if (is_condition(*function) != condition) cells.reject("function", name + " sai vế (if/do)");
    return *function;
}

AiCompare read_compare(Cells& cells, bool condition) {
    const std::string name = cells.text("op");
    if (!condition) {
        if (!name.empty()) cells.reject("op", "hành động không có so sánh");
        return AiCompare::kEq;
    }
    const auto at = std::ranges::find(kCompares, name, &NamedCompare::name);
    if (at == kCompares.end()) {
        cells.reject("op", "so sánh lạ");
        return AiCompare::kEq;
    }
    return at->compare;
}

Row read_row(Cells& cells) {
    Row row;
    row.ai_id = required_int(cells, "ai_id", 0, kMaxInt);
    row.rule_index = static_cast<std::uint32_t>(required_int(cells, "rule_index", 0, kMaxInt));
    row.section = read_section(cells);
    row.priority = required_int(cells, "priority", -1, kMaxInt);
    row.times = required_int(cells, "times", -1, kMaxInt);
    row.condition = read_part(cells);
    row.seq = static_cast<std::uint32_t>(required_int(cells, "seq", 0, kMaxInt));
    row.atom.function = read_function(cells, row.condition);
    row.atom.compare = read_compare(cells, row.condition);
    row.atom.value = required_int(cells, "value", -kMaxInt, kMaxInt);
    row.atom.args[0] = required_int(cells, "arg_0", -kMaxInt, kMaxInt);
    row.atom.args[1] = required_int(cells, "arg_1", -kMaxInt, kMaxInt);
    row.atom.args[2] = required_int(cells, "arg_2", -kMaxInt, kMaxInt);
    const std::int32_t skill = required_int(cells, "skill_id", -kMaxInt, kMaxInt);
    const std::int32_t expected_skill = takes_skill_id(row.atom.function) ? row.atom.args[0] : -1;
    if (skill != expected_skill) cells.reject("skill_id", "lệch arg_0 (hoặc khác -1 ở hàm không mang kỹ năng)");
    if (!row.condition && row.atom.value != 0) cells.reject("value", "hành động không có giá trị so sánh");
    return row;
}

// Gom các dòng liên tiếp thành luật rồi thành kịch bản. Giữ trạng thái của luật đang mở.
class Builder {
public:
    // Trả câu lỗi (chưa có tiền tố tệp:dòng) hoặc nullopt.
    [[nodiscard]] std::optional<std::string> add(const Row& row) {
        if (scripts_.empty() || scripts_.back().ai_id != row.ai_id) {
            if (!scripts_.empty() && row.ai_id < scripts_.back().ai_id) return "kịch bản không sắp ai_id tăng dần";
            if (scripts_.size() >= kMaxAiScripts) return "quá nhiều kịch bản";
            scripts_.push_back(AiScript{.ai_id = row.ai_id, .sections = {}});
            rules_in_script_ = 0;
            open_ = false;
            last_rule_index_.reset();
        }
        if (!open_ || row.rule_index != last_rule_index_) {
            if (const std::optional<std::string> problem = open_rule(row)) return problem;
        }
        return append_atom(row);
    }

    [[nodiscard]] std::vector<AiScript> finish() && {
        for (AiScript& script : scripts_) {
            for (std::vector<AiRule>& rules : script.sections) {
                // Mã 2008 sắp danh sách luật theo ưu tiên giảm dần và giữ thứ tự tệp khi bằng nhau.
                std::ranges::stable_sort(rules, std::greater<>{}, &AiRule::priority);
            }
        }
        return std::move(scripts_);
    }

private:
    [[nodiscard]] std::optional<std::string> open_rule(const Row& row) {
        if (last_rule_index_ && row.rule_index <= *last_rule_index_) return "rule_index không tăng ngặt";
        if (rules_in_script_ >= kMaxAiRulesPerScript) return "kịch bản quá nhiều luật";
        std::vector<AiRule>& rules = section_of(scripts_.back(), row.section);
        rules.push_back(AiRule{
            .rule_index = row.rule_index, .priority = row.priority, .times = row.times, .conditions = {}, .actions = {}});
        section_ = row.section;
        rule_ = rules.size() - 1;
        open_ = true;
        in_actions_ = false;
        last_rule_index_ = row.rule_index;
        ++rules_in_script_;
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> append_atom(const Row& row) {
        AiRule& rule = section_of(scripts_.back(), section_)[rule_];
        if (row.section != section_ || row.priority != rule.priority || row.times != rule.times) {
            return "đầu luật lệch giữa các dòng của cùng một luật";
        }
        if (rule.conditions.size() + rule.actions.size() >= kMaxAiAtomsPerRule) return "luật quá nhiều nguyên tử";
        std::vector<AiAtom>& side = row.condition ? rule.conditions : rule.actions;
        if (row.condition && in_actions_) return "vế if đứng sau vế do";
        if (!row.condition) in_actions_ = true;
        if (row.seq != side.size()) return "seq không liền từ 0";
        side.push_back(row.atom);
        return std::nullopt;
    }

    std::vector<AiScript> scripts_;
    std::size_t section_ = 0;
    std::size_t rule_ = 0;
    bool open_ = false;
    bool in_actions_ = false;
    std::optional<std::uint32_t> last_rule_index_;
    std::size_t rules_in_script_ = 0;
};

struct Listed {
    std::int32_t ai_id = 0;
    std::uint32_t rules = 0;
};

[[nodiscard]] Loaded<std::vector<Listed>> read_listed(std::string_view text) {
    constexpr std::string_view kFile = "monster_ai_rule_files.tsv";
    if (text.size() > kMaxTableBytes) return fail(kFile, "bảng quá lớn");
    const table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return fail(kFile, parsed.error());
    if (parsed->rows.size() > kMaxAiScripts) return fail(kFile, "quá nhiều kịch bản");
    for (const std::string_view column : kListedColumns) {
        if (!table::column_of(*parsed, column)) return fail(kFile, "thiếu cột " + std::string(column));
    }
    std::vector<Listed> listed;
    listed.reserve(parsed->rows.size());
    for (std::size_t index = 0; index < parsed->rows.size(); ++index) {
        Cells cells(kFile, *parsed, index);
        const std::int32_t ai_id = required_int(cells, "ai_id", 0, kMaxInt);
        const std::int32_t rules = required_int(cells, "rules", 0, static_cast<std::int32_t>(kMaxAiRulesPerScript));
        if (cells.error()) return std::unexpected(LoadError{*cells.error()});
        listed.push_back(Listed{.ai_id = ai_id, .rules = static_cast<std::uint32_t>(rules)});
    }
    std::ranges::sort(listed, {}, &Listed::ai_id);
    const auto twin = std::ranges::adjacent_find(listed, {}, &Listed::ai_id);
    if (twin != listed.end()) return fail(kFile, "ai_id lặp: " + std::to_string(twin->ai_id));
    return listed;
}

[[nodiscard]] Loaded<std::vector<AiScript>> read_scripts(std::string_view text) {
    constexpr std::string_view kFile = "monster_ai_rules.tsv";
    if (text.size() > kMaxTableBytes) return fail(kFile, "bảng quá lớn");
    const auto newlines = static_cast<std::size_t>(std::ranges::count(text, '\n'));
    if (newlines > kMaxAiRows + 64) return fail(kFile, "bảng quá nhiều dòng");
    const table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return fail(kFile, parsed.error());
    if (parsed->rows.size() > kMaxAiRows) return fail(kFile, "bảng quá nhiều dòng");
    for (const std::string_view column : kRuleColumns) {
        if (!table::column_of(*parsed, column)) return fail(kFile, "thiếu cột " + std::string(column));
    }
    Builder builder;
    for (std::size_t index = 0; index < parsed->rows.size(); ++index) {
        Cells cells(kFile, *parsed, index);
        const Row row = read_row(cells);
        if (cells.error()) return std::unexpected(LoadError{*cells.error()});
        if (const std::optional<std::string> problem = builder.add(row)) {
            return fail(std::string(kFile) + ":" + std::to_string(parsed->lines[index]), *problem);
        }
    }
    return std::move(builder).finish();
}

} // namespace

std::optional<AiFunction> ai_function_from_name(std::string_view name) noexcept {
    const auto at = std::ranges::find(kFunctions, name, &NamedFunction::name);
    if (at == kFunctions.end()) return std::nullopt;
    return at->function;
}

std::string_view ai_function_name(AiFunction function) noexcept {
    const auto at = std::ranges::find(kFunctions, function, &NamedFunction::function);
    return at == kFunctions.end() ? std::string_view{} : at->name;
}

std::size_t AiScript::rule_count() const noexcept {
    std::size_t total = 0;
    for (const std::vector<AiRule>& rules : sections) total += rules.size();
    return total;
}

const AiScript* AiRuleTable::find(std::int32_t ai_id) const noexcept {
    const auto at = std::ranges::lower_bound(scripts_, ai_id, {}, &AiScript::ai_id);
    return at != scripts_.end() && at->ai_id == ai_id ? &*at : nullptr;
}

std::size_t AiRuleTable::rule_count() const noexcept {
    std::size_t total = 0;
    for (const AiScript& script : scripts_) total += script.rule_count();
    return total;
}

Loaded<AiRuleTable> parse_ai_rules(const AiRuleTexts& texts) {
    Loaded<std::vector<Listed>> listed = read_listed(texts.files);
    if (!listed) return std::unexpected(std::move(listed.error()));
    Loaded<std::vector<AiScript>> built = read_scripts(texts.rules);
    if (!built) return std::unexpected(std::move(built.error()));
    std::vector<AiScript> scripts;
    scripts.reserve(listed->size());
    for (const Listed& entry : *listed) {
        const auto at = std::ranges::lower_bound(*built, entry.ai_id, {}, &AiScript::ai_id);
        const bool present = at != built->end() && at->ai_id == entry.ai_id;
        const std::size_t found = present ? at->rule_count() : 0;
        if (found != entry.rules) {
            return fail("monster_ai_rule_files.tsv",
                "ai_id " + std::to_string(entry.ai_id) + " khai " + std::to_string(entry.rules) + " luật, bảng luật có " +
                    std::to_string(found));
        }
        scripts.push_back(present ? std::move(*at) : AiScript{.ai_id = entry.ai_id, .sections = {}});
    }
    const auto with_rules = std::ranges::count_if(scripts, [](const AiScript& script) { return script.rule_count() != 0; });
    if (built->size() != static_cast<std::size_t>(with_rules)) {
        return fail("monster_ai_rules.tsv", "có kịch bản không nằm trong monster_ai_rule_files.tsv");
    }
    return AiRuleTable(std::move(scripts));
}

} // namespace game::scenedata
