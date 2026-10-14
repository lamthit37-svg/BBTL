// Nạp ops_conditions.tsv và ops_effects.tsv thành Program. Mọi ô là dữ liệu từ tệp nên bị coi là thù địch:
// op lạ, số ngoài miền, id bộ không liền và tham chiếu treo đều là lỗi nạp có dòng, không có check/assert.
#include "ops/ops.hpp"

#include "table/tsv.hpp"

#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::ops {
namespace {

using Failure = LoadFailure;

[[nodiscard]] Failure failure(LoadError error, std::size_t line, std::string detail) {
    return Failure{.error = error, .line = line, .detail = std::move(detail)};
}

struct MetricName {
    std::string_view name;
    Metric metric;
};

constexpr std::array<MetricName, kMetricCount> kMetricNames{{
    {.name = "level", .metric = Metric::kLevel},
    {.name = "item_count", .metric = Metric::kItemCount},
    {.name = "bag_space", .metric = Metric::kBagSpace},
    {.name = "money", .metric = Metric::kMoney},
    {.name = "objective", .metric = Metric::kObjective},
    {.name = "counter", .metric = Metric::kCounter},
    {.name = "sect", .metric = Metric::kSect},
    {.name = "gender", .metric = Metric::kGender},
    {.name = "team_size", .metric = Metric::kTeamSize},
    {.name = "quest_count", .metric = Metric::kQuestCount},
    {.name = "hour", .metric = Metric::kHour},
    {.name = "weekday", .metric = Metric::kWeekday},
    {.name = "minute", .metric = Metric::kMinute},
    {.name = "radio", .metric = Metric::kRadio},
    {.name = "ability", .metric = Metric::kAbility},
    {.name = "guild", .metric = Metric::kGuild},
    {.name = "clock", .metric = Metric::kClock},
    {.name = "monster", .metric = Metric::kMonster},
    {.name = "area", .metric = Metric::kArea},
    {.name = "event_item", .metric = Metric::kEventItem},
    {.name = "quest_slots_free", .metric = Metric::kSlotsFree},
}};

[[nodiscard]] std::optional<Metric> metric_named(std::string_view name) noexcept {
    for (const MetricName& entry : kMetricNames) {
        if (entry.name == name) return entry.metric;
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<std::int32_t> parse_int(std::string_view cell) noexcept {
    std::int32_t value = 0;
    const char* const first = std::to_address(cell.begin());
    const char* const last = std::to_address(cell.end());
    const auto [end, code] = std::from_chars(first, last, value);
    if (code != std::errc{} || end != last || cell.empty()) return std::nullopt;
    return value;
}

struct Columns {
    const table::Tsv* table = nullptr;
    std::size_t row = 0;

    [[nodiscard]] std::expected<std::string_view, Failure> text(std::string_view name) const {
        const auto index = table::column_of(*table, name);
        if (!index) return std::unexpected(failure(LoadError::kMissingColumn, 0, std::string(name)));
        return std::string_view(table->rows[row][*index]);
    }

    [[nodiscard]] std::expected<std::int32_t, Failure> number(std::string_view name) const {
        const auto cell = text(name);
        if (!cell) return std::unexpected(cell.error());
        const auto value = parse_int(*cell);
        if (!value) {
            return std::unexpected(failure(LoadError::kBadNumber, table->lines[row], std::string(name)));
        }
        return *value;
    }

    [[nodiscard]] Failure at_line(LoadError error, std::string detail) const {
        return failure(error, table->lines[row], std::move(detail));
    }
};

// Op của bảng điều kiện: "<đại lượng>_at_least", "<đại lượng>_is" hoặc một vị từ riêng.
struct ParsedOp {
    Op op = Op::kNever;
    Metric metric = Metric::kLevel;
};

[[nodiscard]] std::optional<ParsedOp> parse_op(std::string_view name) noexcept {
    struct Fixed {
        std::string_view name;
        Op op;
    };
    static constexpr std::array<Fixed, 11> kFixed{{
        {.name = "never", .op = Op::kNever},
        {.name = "team_leader", .op = Op::kTeamLeader},
        {.name = "skill_known", .op = Op::kSkillKnown},
        {.name = "quest_active", .op = Op::kQuestActive},
        {.name = "quest_done", .op = Op::kQuestDone},
        {.name = "flag_set", .op = Op::kFlagSet},
        {.name = "counter_vs_clock", .op = Op::kCounterVsClock},
        {.name = "target_name", .op = Op::kTargetName},
        {.name = "event_monster_name", .op = Op::kEventMonsterName},
        {.name = "quest_named", .op = Op::kQuestNamed},
        {.name = "impact_active", .op = Op::kImpactActive},
    }};
    for (const Fixed& entry : kFixed) {
        if (entry.name == name) return ParsedOp{.op = entry.op, .metric = Metric::kLevel};
    }
    constexpr std::string_view kAtLeast = "_at_least";
    constexpr std::string_view kIs = "_is";
    for (const auto& [suffix, op] : {std::pair{kAtLeast, Op::kAtLeast}, std::pair{kIs, Op::kIs}}) {
        if (name.size() > suffix.size() && name.ends_with(suffix)) {
            const auto metric = metric_named(name.substr(0, name.size() - suffix.size()));
            if (metric) return ParsedOp{.op = op, .metric = *metric};
        }
    }
    return std::nullopt;
}

[[nodiscard]] std::expected<Atom, Failure> read_atom(const Columns& columns) {
    const auto op_name = columns.text("op");
    if (!op_name) return std::unexpected(op_name.error());
    const auto parsed = parse_op(*op_name);
    if (!parsed) return std::unexpected(columns.at_line(LoadError::kUnknownOp, std::string(*op_name)));
    Atom atom;
    atom.op = parsed->op;
    atom.metric = parsed->metric;
    const auto negated = columns.number("neg");
    if (!negated) return std::unexpected(negated.error());
    if (*negated != 0 && *negated != 1) return std::unexpected(columns.at_line(LoadError::kOutOfRange, "neg"));
    atom.negated = *negated == 1;
    constexpr std::array<std::string_view, 3> kArgColumns{"a1", "a2", "a3"};
    for (std::size_t slot = 0; slot < kArgColumns.size(); ++slot) {
        const auto value = columns.number(kArgColumns.at(slot));
        if (!value) return std::unexpected(value.error());
        atom.arg.at(slot) = *value;
    }
    const auto word = columns.text("word");
    if (!word) return std::unexpected(word.error());
    if (atom.op == Op::kTargetName || atom.op == Op::kEventMonsterName || atom.op == Op::kQuestNamed) atom.name = name_id(*word);
    return atom;
}

// Lượng chọn trong clause: kAtLeast/kIs cần arity+1 số; không cần kiểm thêm (ô thừa bằng 0 theo công cụ trích).
[[nodiscard]] std::expected<std::vector<CondSet>, Failure> read_conditions(const table::Tsv& table) {
    std::vector<CondSet> sets;
    std::int32_t current = 0;
    std::int32_t clause_no = -1;
    for (std::size_t row = 0; row < table.rows.size(); ++row) {
        const Columns columns{.table = &table, .row = row};
        const auto set_id = columns.number("set");
        const auto clause = columns.number("clause");
        if (!set_id) return std::unexpected(set_id.error());
        if (!clause) return std::unexpected(clause.error());
        if (*set_id != current) {
            if (*set_id != current + 1) return std::unexpected(columns.at_line(LoadError::kSetIdGap, "set"));
            if (sets.size() >= kMaxProgramSets) return std::unexpected(columns.at_line(LoadError::kTooLarge, "set"));
            sets.emplace_back();
            current = *set_id;
            clause_no = -1;
        }
        if (*clause != clause_no) {
            if (*clause != clause_no + 1) return std::unexpected(columns.at_line(LoadError::kSetIdGap, "clause"));
            if (sets.back().clauses.size() >= kMaxClauses) {
                return std::unexpected(columns.at_line(LoadError::kTooLarge, "clause"));
            }
            sets.back().clauses.emplace_back();
            clause_no = *clause;
        }
        std::vector<Atom>& atoms = sets.back().clauses.back();
        if (atoms.size() >= kMaxAtoms) return std::unexpected(columns.at_line(LoadError::kTooLarge, "atom"));
        auto atom = read_atom(columns);
        if (!atom) return std::unexpected(atom.error());
        atoms.push_back(*atom);
    }
    return sets;
}

struct EffectName {
    std::string_view name;
    EffectOp op;
};

constexpr std::array<EffectName, 23> kEffectNames{{
    {.name = "give_item", .op = EffectOp::kGiveItem},
    {.name = "take_item", .op = EffectOp::kTakeItem},
    {.name = "give_money", .op = EffectOp::kGiveMoney},
    {.name = "take_money", .op = EffectOp::kTakeMoney},
    {.name = "give_exp", .op = EffectOp::kGiveExp},
    {.name = "quest_accept", .op = EffectOp::kQuestAccept},
    {.name = "quest_remove", .op = EffectOp::kQuestRemove},
    {.name = "quest_mark_done", .op = EffectOp::kQuestMarkDone},
    {.name = "objective_set", .op = EffectOp::kObjectiveSet},
    {.name = "objective_add", .op = EffectOp::kObjectiveAdd},
    {.name = "set_counter", .op = EffectOp::kSetCounter},
    {.name = "counter_add", .op = EffectOp::kCounterAdd},
    {.name = "set_counter_clock", .op = EffectOp::kSetCounterClock},
    {.name = "set_flag", .op = EffectOp::kSetFlag},
    {.name = "clear_flag", .op = EffectOp::kClearFlag},
    {.name = "notify", .op = EffectOp::kNotify},
    {.name = "announce", .op = EffectOp::kAnnounce},
    {.name = "teleport", .op = EffectOp::kTeleport},
    {.name = "open_shop", .op = EffectOp::kOpenShop},
    {.name = "signpost", .op = EffectOp::kSignpost},
    {.name = "signpost_pos", .op = EffectOp::kSignpostPos},
    {.name = "offer_next", .op = EffectOp::kOfferNext},
    {.name = "ui_command", .op = EffectOp::kUiCommand},
}};

[[nodiscard]] std::optional<EffectOp> effect_named(std::string_view name) noexcept {
    for (const EffectName& entry : kEffectNames) {
        if (entry.name == name) return entry.op;
    }
    return std::nullopt;
}

// "player", "npc" hoặc "<đại lượng>:<đối số>[:<đối số>]".
[[nodiscard]] std::optional<TextParam> parse_param(std::string_view text) noexcept {
    TextParam param;
    if (text == "player") return param;
    if (text == "npc") {
        param.kind = TextParam::Kind::kNpc;
        return param;
    }
    param.kind = TextParam::Kind::kMetric;
    const std::size_t colon = text.find(':');
    const auto metric = metric_named(text.substr(0, colon));
    if (!metric) return std::nullopt;
    param.metric = *metric;
    std::string_view rest = colon == std::string_view::npos ? std::string_view{} : text.substr(colon + 1);
    for (std::size_t slot = 0; slot < param.arg.size() && !rest.empty(); ++slot) {
        const std::size_t next = rest.find(':');
        const auto value = parse_int(rest.substr(0, next));
        if (!value) return std::nullopt;
        param.arg.at(slot) = *value;
        rest = next == std::string_view::npos ? std::string_view{} : rest.substr(next + 1);
    }
    return param;
}

[[nodiscard]] std::expected<std::vector<TextParam>, Failure> read_params(const Columns& columns,
    std::string_view cell) {
    auto params = parse_text_params(cell);
    if (!params) return std::unexpected(columns.at_line(LoadError::kUnknownMetric, std::string(cell)));
    return std::move(*params);
}

[[nodiscard]] std::expected<Effect, Failure> read_effect(const Columns& columns, std::size_t condition_count) {
    const auto op_name = columns.text("op");
    if (!op_name) return std::unexpected(op_name.error());
    const auto op = effect_named(*op_name);
    if (!op) return std::unexpected(columns.at_line(LoadError::kUnknownOp, std::string(*op_name)));
    Effect effect;
    effect.op = *op;
    constexpr std::array<std::string_view, 3> kArgColumns{"a1", "a2", "a3"};
    for (std::size_t slot = 0; slot < kArgColumns.size(); ++slot) {
        const auto value = columns.number(kArgColumns.at(slot));
        if (!value) return std::unexpected(value.error());
        effect.arg.at(slot) = *value;
    }
    const auto text = columns.text("text");
    const auto args = columns.text("args");
    const auto cond = columns.number("cond");
    if (!text) return std::unexpected(text.error());
    if (!args) return std::unexpected(args.error());
    if (!cond) return std::unexpected(cond.error());
    if (!text->empty()) effect.text.id = string_id(*text);
    auto params = read_params(columns, *args);
    if (!params) return std::unexpected(params.error());
    effect.text.params = std::move(*params);
    const bool known = *cond == -1 || (*cond >= 1 && std::cmp_less_equal(*cond, condition_count));
    if (!known) return std::unexpected(columns.at_line(LoadError::kBadReference, "cond"));
    effect.cond = *cond;
    return effect;
}

[[nodiscard]] std::expected<std::vector<EffectList>, Failure> read_effects(const table::Tsv& table,
    std::size_t condition_count) {
    std::vector<EffectList> lists;
    std::int32_t current = 0;
    for (std::size_t row = 0; row < table.rows.size(); ++row) {
        const Columns columns{.table = &table, .row = row};
        const auto set_id = columns.number("set");
        if (!set_id) return std::unexpected(set_id.error());
        if (*set_id != current) {
            if (*set_id != current + 1) return std::unexpected(columns.at_line(LoadError::kSetIdGap, "set"));
            if (lists.size() >= kMaxProgramSets) return std::unexpected(columns.at_line(LoadError::kTooLarge, "set"));
            lists.emplace_back();
            current = *set_id;
        }
        if (lists.back().effects.size() >= kMaxSetEffects) {
            return std::unexpected(columns.at_line(LoadError::kTooLarge, "effects"));
        }
        auto effect = read_effect(columns, condition_count);
        if (!effect) return std::unexpected(effect.error());
        lists.back().effects.push_back(std::move(*effect));
    }
    return lists;
}

}  // namespace

std::optional<std::vector<TextParam>> parse_text_params(std::string_view cell) {
    std::vector<TextParam> params;
    while (!cell.empty()) {
        const std::size_t comma = cell.find(',');
        const auto param = parse_param(cell.substr(0, comma));
        if (!param || params.size() >= 8) return std::nullopt;
        params.push_back(*param);
        cell = comma == std::string_view::npos ? std::string_view{} : cell.substr(comma + 1);
    }
    return params;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): bảng điều kiện rồi bảng hiệu ứng, mọi nơi gọi cùng thứ tự (HP-07)
std::expected<Program, LoadFailure> Program::load(const table::Tsv& conditions, const table::Tsv& effects) {
    auto sets = read_conditions(conditions);
    if (!sets) return std::unexpected(sets.error());
    auto lists = read_effects(effects, sets->size());
    if (!lists) return std::unexpected(lists.error());
    Program program;
    program.conditions_ = std::move(*sets);
    program.lists_ = std::move(*lists);
    return program;
}

const CondSet* Program::condition(std::int32_t id) const noexcept {
    if (id < 1 || static_cast<std::size_t>(id) > conditions_.size()) return nullptr;
    return &conditions_[static_cast<std::size_t>(id) - 1];
}

const EffectList* Program::effect_list(std::int32_t id) const noexcept {
    if (id < 1 || static_cast<std::size_t>(id) > lists_.size()) return nullptr;
    return &lists_[static_cast<std::size_t>(id) - 1];
}

bool Program::holds(std::int32_t condition_id, const Context& context) const noexcept {
    if (condition_id == -1) return true;
    const CondSet* const set = condition(condition_id);
    return set != nullptr && ops::holds(*set, context);
}

bool Program::has_effects(std::int32_t effects_id) const noexcept {
    return effects_id == -1 || effect_list(effects_id) != nullptr;
}

Plan Program::plan(std::int32_t effects_id, const Context& context) const {
    Plan result;
    const EffectList* const list = effect_list(effects_id);
    if (list == nullptr) return result;
    for (const Effect& effect : list->effects) {
        if (holds(effect.cond, context)) result.steps.push_back(&effect);
    }
    return result;
}

}  // namespace game::ops
