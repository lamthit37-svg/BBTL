// Nạp danh mục nhiệm vụ từ các bảng mission_*.tsv. Mọi ô là dữ liệu từ tệp nên bị coi là thù địch: ô sai kiểu, id ngoài miền,
// tham chiếu treo tới ops::Program, seq không liền và từ khoá lạ đều là lỗi nạp có số dòng, không có check/assert.
#include "mission/catalog.hpp"

#include "mission/book.hpp"
#include "ops/ops.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace game::mission {

namespace {

constexpr std::int32_t kMaxInt = std::numeric_limits<std::int32_t>::max();
constexpr std::int32_t kSceneLimit = 100000;
constexpr std::size_t kMaxQuests = 20000;  // trần số dòng nhiệm vụ (thực tế ~1,4 nghìn)
constexpr std::size_t kMaxObjectives = 16;
constexpr std::size_t kMaxRewards = 128;  // bảng thật có script tới 97 dòng thưởng điều kiện

template <typename Enum>
struct Word {
    std::string_view text;
    Enum value;
};

template <typename Enum, std::size_t Count>
[[nodiscard]] std::optional<Enum> lookup(const std::array<Word<Enum>, Count>& words, std::string_view text) noexcept {
    for (const Word<Enum>& word : words) {
        if (word.text == text) return word.value;
    }
    return std::nullopt;
}

constexpr std::array<Word<ObjectiveKind>, 8> kObjectiveWords{{
    {.text = "talk", .value = ObjectiveKind::kTalk},
    {.text = "kill", .value = ObjectiveKind::kKill},
    {.text = "loot", .value = ObjectiveKind::kLoot},
    {.text = "deliver", .value = ObjectiveKind::kDeliver},
    {.text = "area", .value = ObjectiveKind::kArea},
    {.text = "escort", .value = ObjectiveKind::kEscort},
    {.text = "progress", .value = ObjectiveKind::kProgress},
    {.text = "collect", .value = ObjectiveKind::kCollect},
}};
constexpr std::array<Word<RewardGroup>, 3> kGroupWords{{
    {.text = "fixed", .value = RewardGroup::kFixed},
    {.text = "choice", .value = RewardGroup::kChoice},
    {.text = "hidden", .value = RewardGroup::kHidden},
}};
constexpr std::array<Word<RewardKind>, 5> kRewardWords{{
    {.text = "money", .value = RewardKind::kMoney},
    {.text = "bound_money", .value = RewardKind::kBoundMoney},
    {.text = "exp", .value = RewardKind::kExp},
    {.text = "item", .value = RewardKind::kItem},
    {.text = "relation", .value = RewardKind::kRelation},
}};
constexpr std::array<Word<HookEvent>, 3> kHookWords{{
    {.text = "kill", .value = HookEvent::kKill},
    {.text = "enter_area", .value = HookEvent::kEnterArea},
    {.text = "item_changed", .value = HookEvent::kItemChanged},
}};

}  // namespace

std::string_view describe(LoadError error) noexcept {
    switch (error) {
        case LoadError::kNone: return "không lỗi";
        case LoadError::kBadCell: return "ô sai kiểu hoặc ngoài miền";
        case LoadError::kUnknownWord: return "từ khoá không thuộc tập đóng";
        case LoadError::kDuplicateScript: return "script trùng";
        case LoadError::kUnknownScript: return "bảng phụ trỏ tới script không có";
        case LoadError::kBadReference: return "tham chiếu tới điều kiện hay bộ hiệu ứng không có";
        case LoadError::kBadOrder: return "seq không liền từ 0";
        case LoadError::kTooLarge: return "vượt trần kích thước";
    }
    return "lỗi không rõ";
}

// Người dựng đứng ngoài namespace ẩn danh vì là friend của Catalog.
class CatalogBuilder {
public:
    CatalogBuilder(Catalog& catalog, const Tables& tables, const Options& options)
        : catalog_(catalog), tables_(tables), options_(options) {}

    [[nodiscard]] std::expected<void, LoadFailure> run() {
        if (auto step = read_quests(); !step) return step;
        if (auto step = read_objectives(); !step) return step;
        if (auto step = read_rewards(); !step) return step;
        if (auto step = read_prereqs(); !step) return step;
        if (auto step = read_hooks(); !step) return step;
        if (auto step = read_npcs(); !step) return step;
        if (auto step = read_autos(); !step) return step;
        if (auto step = read_groups(); !step) return step;
        classify();
        return {};
    }

private:
    using Result = std::expected<void, LoadFailure>;

    [[nodiscard]] static std::unexpected<LoadFailure> failure(LoadError error, std::string_view table, std::string detail) {
        return std::unexpected(LoadFailure{.error = error, .table = std::string(table), .detail = std::move(detail)});
    }

    [[nodiscard]] static std::unexpected<LoadFailure> bad_cell(std::string_view table, const table::RowReader& reader) {
        const std::optional<std::string>& cause = reader.error();
        return failure(LoadError::kBadCell, table, cause.value_or(std::string{}));
    }

    [[nodiscard]] static std::string where(const table::Tsv& table, std::size_t row, std::string_view what) {
        return "dòng " + std::to_string(table.lines.at(row)) + ": " + std::string(what);
    }

    [[nodiscard]] bool cond_ok(std::int32_t id) const noexcept {
        return id == -1 || catalog_.program_.condition(id) != nullptr;
    }
    [[nodiscard]] bool effects_ok(std::int32_t id) const noexcept {
        return id == -1 || catalog_.program_.effect_list(id) != nullptr;
    }

    [[nodiscard]] Quest* quest_of_script(std::uint32_t script) {
        const auto found = catalog_.by_script_.find(script);
        return found == catalog_.by_script_.end() ? nullptr : &catalog_.quests_.at(found->second);
    }

    Result read_quests() {
        const table::Tsv& table = tables_.quests;
        if (table.rows.size() > kMaxQuests) return failure(LoadError::kTooLarge, "mission_quests", "quá nhiều dòng");
        catalog_.quests_.reserve(table.rows.size());
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            Quest quest;
            quest.script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            quest.quest = reader.integer("quest", 0, kQuestIdLimit - 1);
            const std::string_view source = reader.text("source");
            const std::string_view status = reader.text("status");
            quest.reason = std::string(reader.text("reason"));
            quest.in_client = reader.flag("in_client");
            quest.kind = reader.integer("kind", -1, kMaxInt);
            quest.level = reader.integer("level", -1, kMaxInt);
            const std::string_view repeat = reader.text("repeat");
            quest.name = std::string(reader.text("name"));
            quest.name_id = quest.name.empty() ? 0U : ops::name_id(quest.name);
            quest.accept_scene = reader.integer("accept_scene", -1, kSceneLimit);
            quest.accept_guid = reader.integer("accept_guid", 0, kMaxInt);
            quest.turn_scene = reader.integer("turn_scene", -1, kSceneLimit);
            quest.turn_guid = reader.integer("turn_guid", 0, kMaxInt);
            quest.accept_cond = reader.integer("accept_cond", -1, kMaxInt);
            quest.ready_cond = reader.integer("ready_cond", -1, kMaxInt);
            quest.accept_fx = reader.integer("accept_fx", -1, kMaxInt);
            quest.submit_fx = reader.integer("submit_fx", -1, kMaxInt);
            quest.abandon_fx = reader.integer("abandon_fx", -1, kMaxInt);
            quest.next_quest = reader.integer("next_quest", -1, kQuestIdLimit - 1);
            quest.next_script = reader.number("next_script", 0, static_cast<std::uint32_t>(kMaxInt));
            quest.penalty = reader.integer("penalty", 0, kMaxInt);
            quest.ban_slot = reader.integer("ban_slot", -1, kMaxInt);
            quest.ban_seconds = reader.integer("ban_seconds", 0, kMaxInt);
            if (reader.error()) return bad_cell("mission_quests", reader);
            if (source != "table" && source != "script") {
                return failure(LoadError::kUnknownWord, "mission_quests", where(table, row, "source " + std::string(source)));
            }
            if (status != "ok" && status != "unsupported") {
                return failure(LoadError::kUnknownWord, "mission_quests", where(table, row, "status " + std::string(status)));
            }
            if (repeat != "once" && repeat != "loop") {
                return failure(LoadError::kUnknownWord, "mission_quests", where(table, row, "repeat " + std::string(repeat)));
            }
            quest.source = source == "table" ? Source::kTable : Source::kScript;
            quest.repeat = repeat == "loop" ? Repeat::kLoop : Repeat::kOnce;
            if (!cond_ok(quest.accept_cond) || !cond_ok(quest.ready_cond) || !effects_ok(quest.accept_fx) ||
                !effects_ok(quest.submit_fx) || !effects_ok(quest.abandon_fx)) {
                return failure(LoadError::kBadReference, "mission_quests", where(table, row, "script " + std::to_string(quest.script)));
            }
            if (status == "unsupported") {
                quest.support = Support::kUnsupported;
                if (quest.reason.empty()) quest.reason = "không rõ (bảng trích không ghi)";
            }
            if (!catalog_.by_script_.emplace(quest.script, catalog_.quests_.size()).second) {
                return failure(LoadError::kDuplicateScript, "mission_quests", where(table, row, std::to_string(quest.script)));
            }
            catalog_.quests_.push_back(std::move(quest));
        }
        return {};
    }

    Result read_objectives() {
        const table::Tsv& table = tables_.objectives;
        std::unordered_map<std::uint32_t, std::int32_t> next_seq;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            const std::int32_t seq = reader.integer("seq", 0, static_cast<std::int32_t>(kMaxObjectives) - 1);
            const std::string_view kind = reader.text("kind");
            Objective one;
            one.index = reader.integer("index", 0, static_cast<std::int32_t>(kParamCount) - 1);
            one.target = reader.integer("target", 0, kMaxInt);
            one.count = reader.integer("count", 0, 1000000);
            one.item = reader.integer("item", 0, kMaxInt);
            one.rate = reader.integer("rate", 0, 100);
            one.scene = reader.integer("scene", -1, kSceneLimit);
            one.flag = reader.integer("flag", 0, 100);
            const std::string_view name = reader.text("name");
            if (reader.error()) return bad_cell("mission_objectives", reader);
            const std::optional<ObjectiveKind> parsed = lookup(kObjectiveWords, kind);
            if (!parsed) return failure(LoadError::kUnknownWord, "mission_objectives", where(table, row, kind));
            one.kind = *parsed;
            one.name = name.empty() ? 0U : ops::name_id(name);
            Quest* const quest = quest_of_script(script);
            if (quest == nullptr) return failure(LoadError::kUnknownScript, "mission_objectives", where(table, row, std::to_string(script)));
            if (next_seq[script]++ != seq) return failure(LoadError::kBadOrder, "mission_objectives", where(table, row, std::to_string(script)));
            quest->objectives.push_back(one);
        }
        return {};
    }

    Result read_rewards() {
        const table::Tsv& table = tables_.rewards;
        std::unordered_map<std::uint32_t, std::int32_t> next_seq;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            const std::int32_t seq = reader.integer("seq", 0, static_cast<std::int32_t>(kMaxRewards) - 1);
            const std::string_view group = reader.text("group");
            const std::string_view kind = reader.text("kind");
            Reward one;
            one.ref = reader.integer("ref", 0, kMaxInt);
            one.count = reader.integer("count", 0, kMaxInt);
            one.cond = reader.integer("cond", -1, kMaxInt);
            if (reader.error()) return bad_cell("mission_rewards", reader);
            const std::optional<RewardGroup> parsed_group = lookup(kGroupWords, group);
            const std::optional<RewardKind> parsed_kind = lookup(kRewardWords, kind);
            if (!parsed_group || !parsed_kind) {
                return failure(LoadError::kUnknownWord, "mission_rewards", where(table, row, std::string(group) + "/" + std::string(kind)));
            }
            one.group = *parsed_group;
            one.kind = *parsed_kind;
            Quest* const quest = quest_of_script(script);
            if (quest == nullptr) return failure(LoadError::kUnknownScript, "mission_rewards", where(table, row, std::to_string(script)));
            if (!cond_ok(one.cond)) return failure(LoadError::kBadReference, "mission_rewards", where(table, row, "cond"));
            if (next_seq[script]++ != seq) return failure(LoadError::kBadOrder, "mission_rewards", where(table, row, std::to_string(script)));
            quest->rewards.push_back(one);
        }
        return {};
    }

    Result read_prereqs() {
        const table::Tsv& table = tables_.prereqs;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            const std::int32_t prereq = reader.integer("prereq", 0, kQuestIdLimit - 1);
            if (reader.error()) return bad_cell("mission_prereqs", reader);
            Quest* const quest = quest_of_script(script);
            if (quest == nullptr) return failure(LoadError::kUnknownScript, "mission_prereqs", where(table, row, std::to_string(script)));
            quest->prereqs.push_back(prereq);
        }
        return {};
    }

    Result read_hooks() {
        const table::Tsv& table = tables_.hooks;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            const std::string_view event = reader.text("event");
            Hook hook;
            hook.effects = reader.integer("effects", 1, kMaxInt);
            if (reader.error()) return bad_cell("mission_hooks", reader);
            const std::optional<HookEvent> parsed = lookup(kHookWords, event);
            if (!parsed) return failure(LoadError::kUnknownWord, "mission_hooks", where(table, row, event));
            hook.event = *parsed;
            Quest* const quest = quest_of_script(script);
            if (quest == nullptr) return failure(LoadError::kUnknownScript, "mission_hooks", where(table, row, std::to_string(script)));
            if (!effects_ok(hook.effects)) return failure(LoadError::kBadReference, "mission_hooks", where(table, row, "effects"));
            quest->hooks.push_back(hook);
        }
        return {};
    }

    Result read_npcs() {
        const table::Tsv& table = tables_.npcs;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            const std::string_view role = reader.text("role");
            const std::int32_t guid = reader.integer("guid", 0, kMaxInt);
            const std::int32_t scene = reader.integer("scene", -1, kSceneLimit);
            const std::string_view name = reader.text("name");
            if (reader.error()) return bad_cell("mission_npcs", reader);
            if (role != "give" && role != "turn" && role != "target") {
                return failure(LoadError::kUnknownWord, "mission_npcs", where(table, row, role));
            }
            if (quest_of_script(script) == nullptr) {
                return failure(LoadError::kUnknownScript, "mission_npcs", where(table, row, std::to_string(script)));
            }
            if (role == "target") continue;  // mục tiêu nói chuyện khớp bằng Objective, không dùng làm chỗ giao/trả
            const Offer offer{.script = script, .role = role == "give" ? NpcRole::kGive : NpcRole::kTurn};
            if (guid > 0) {
                catalog_.by_guid_[static_cast<std::uint32_t>(guid)].push_back(offer);
            } else if (!name.empty() && name != "-1") {
                catalog_.by_name_[{scene, ops::name_id(name)}].push_back(offer);
            }
        }
        return {};
    }

    Result read_autos() {
        const table::Tsv& table = tables_.autos;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            AutoRule rule;
            rule.level = reader.integer("level", -1, 1000);
            rule.quest = reader.integer("quest", -1, kQuestIdLimit - 1);
            rule.script = reader.number("script", 0, static_cast<std::uint32_t>(kMaxInt));
            rule.pre_quest = reader.integer("pre_quest", 0, kQuestIdLimit - 1);
            rule.event = reader.integer("event", 0, 255);
            rule.full_level = reader.integer("full_level", -1, 1000);
            rule.complete_idx = reader.integer("complete_idx", -1, static_cast<std::int32_t>(kParamCount) - 1);
            rule.record_idx = reader.integer("record_idx", -1, static_cast<std::int32_t>(kParamCount) - 1);
            rule.message = std::string(reader.text("message"));
            if (reader.error()) return bad_cell("mission_auto", reader);
            catalog_.autos_.push_back(std::move(rule));
        }
        return {};
    }

    Result read_groups() {
        const table::Tsv& table = tables_.name_groups;
        for (std::size_t row = 0; row < table.rows.size(); ++row) {
            table::RowReader reader(table, row);
            const std::uint32_t group = reader.number("group", 0, static_cast<std::uint32_t>(kMaxInt));
            const std::int32_t monster = reader.integer("template", -1, kMaxInt);
            if (reader.error()) return bad_cell("mission_name_groups", reader);
            if (monster > 0) catalog_.template_group_.emplace(static_cast<std::uint32_t>(monster), group);
        }
        return {};
    }

    // Lý do một nhiệm vụ đã nạp vẫn chưa có bộ chạy: phụ thuộc vào loại mục tiêu, không phụ thuộc bảng trích.
    [[nodiscard]] static std::string_view objective_gap(const Quest& quest) noexcept {
        for (const Objective& one : quest.objectives) {
            // Nhiệm vụ bảng cất tiến độ mục tiêu i ở tham số 1 + i: quá 7 mục tiêu thì không đủ 8 tham số của ô.
            if (quest.source == Source::kTable && static_cast<std::size_t>(one.index) + 1 >= kParamCount) {
                return "nhiều mục tiêu hơn số tham số của ô nhiệm vụ";
            }
            if (one.kind == ObjectiveKind::kEscort) return "mục tiêu hộ tống: cần NPC đi theo (vai AI/zone)";
            if (one.kind == ObjectiveKind::kLoot && one.flag != 0) {
                return "mục tiêu loot ngẫu nhiên theo bảng MissionItem (flag khác 0): chưa có bộ chạy";
            }
            const bool needs_npc = one.kind == ObjectiveKind::kTalk && one.target == 0 && one.name == 0;
            const bool needs_group = (one.kind == ObjectiveKind::kKill || one.kind == ObjectiveKind::kLoot) && one.target == 0;
            if (needs_npc || needs_group) return "mục tiêu không xác định được NPC hay quái";
        }
        return {};
    }

    [[nodiscard]] static std::uint8_t watch_of(const Quest& quest) noexcept {
        std::uint8_t watch = 0;
        for (const Objective& one : quest.objectives) {
            if (one.kind == ObjectiveKind::kKill || one.kind == ObjectiveKind::kLoot) watch |= kWatchKill;
            if (one.kind == ObjectiveKind::kArea) watch |= kWatchArea;
            if (one.kind == ObjectiveKind::kLoot || one.kind == ObjectiveKind::kDeliver ||
                one.kind == ObjectiveKind::kCollect) {
                watch |= kWatchItem;
            }
        }
        for (const Hook& hook : quest.hooks) {
            if (hook.event == HookEvent::kKill) watch |= kWatchKill;
            if (hook.event == HookEvent::kEnterArea) watch |= kWatchArea;
            if (hook.event == HookEvent::kItemChanged) watch |= kWatchItem;
        }
        return watch;
    }

    // Loại các id nhiệm vụ mà chuỗi tiền đề dẫn tới một vòng (kể cả nằm sau vòng): bóc dần các id đã giải được.
    [[nodiscard]] std::unordered_set<std::int32_t> unresolved_quests() const {
        std::unordered_map<std::int32_t, std::unordered_set<std::int32_t>> needs;
        for (const auto& [id, indices] : catalog_.by_quest_) {
            auto& deps = needs[id];
            for (const std::size_t index : indices) {
                for (const std::int32_t prereq : catalog_.quests_.at(index).prereqs) {
                    if (catalog_.by_quest_.contains(prereq)) deps.insert(prereq);
                }
            }
        }
        std::unordered_map<std::int32_t, std::vector<std::int32_t>> waiting;
        std::vector<std::int32_t> ready;
        std::unordered_map<std::int32_t, std::size_t> remaining;
        for (const auto& [id, deps] : needs) {
            remaining[id] = deps.size();
            if (deps.empty()) ready.push_back(id);
            for (const std::int32_t dep : deps) waiting[dep].push_back(id);
        }
        std::size_t resolved = 0;
        while (!ready.empty()) {
            const std::int32_t id = ready.back();
            ready.pop_back();
            ++resolved;
            for (const std::int32_t dependent : waiting[id]) {
                if (--remaining[dependent] == 0) ready.push_back(dependent);
            }
        }
        std::unordered_set<std::int32_t> stuck;
        if (resolved == needs.size()) return stuck;
        for (const auto& [id, count] : remaining) {
            if (count != 0) stuck.insert(id);
        }
        return stuck;
    }

    void classify() {
        Catalog& catalog = catalog_;
        for (std::size_t index = 0; index < catalog.quests_.size(); ++index) {
            catalog.by_quest_[catalog.quests_[index].quest].push_back(index);
        }
        for (auto& [id, indices] : catalog.by_quest_) {
            std::ranges::sort(indices, {}, [&](std::size_t index) { return catalog.quests_.at(index).script; });
        }
        for (Quest& quest : catalog.quests_) {
            quest.watch = watch_of(quest);
            if (quest.support != Support::kUnsupported) {
                if (const std::string_view gap = objective_gap(quest); !gap.empty()) {
                    quest.support = Support::kUnsupported;
                    quest.reason = std::string(gap);
                }
            }
            if (quest.support == Support::kRunnable && !quest.in_client && !options_.allow_not_in_client) {
                quest.support = Support::kNotInClient;
                quest.reason = "không có trong danh bạ nhiệm vụ của client 2026";
            }
        }
        const std::unordered_set<std::int32_t> stuck = unresolved_quests();
        for (Quest& quest : catalog.quests_) {
            if (quest.support == Support::kRunnable && stuck.contains(quest.quest)) {
                quest.support = Support::kBlocked;
                quest.reason = "chuỗi tiền đề có vòng";
            }
        }
        for (auto& [guid, offers] : catalog.by_guid_) std::ranges::sort(offers);
        for (auto& [key, offers] : catalog.by_name_) std::ranges::sort(offers);
        summarize();
    }

    void summarize() {
        Report& report = catalog_.report_;
        std::map<std::string, std::size_t> reasons;
        report.quests = catalog_.quests_.size();
        for (const Quest& quest : catalog_.quests_) {
            switch (quest.support) {
                case Support::kRunnable: ++report.runnable; break;
                case Support::kUnsupported: ++report.unsupported; break;
                case Support::kNotInClient: ++report.not_in_client; break;
                case Support::kBlocked: ++report.blocked; break;
            }
            if (!quest.runnable()) ++reasons[quest.reason];
            const bool missing = std::ranges::any_of(quest.prereqs, [&](std::int32_t prereq) {
                return !catalog_.by_quest_.contains(prereq);
            });
            if (missing) ++report.missing_prereq_quests;
        }
        report.reasons.assign(reasons.begin(), reasons.end());
    }

    // NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): danh bạ đang dựng, bảng và tuỳ chọn do nơi gọi sở hữu, sống lâu hơn người dựng, không sở hữu, không giữ qua tick (SH-04)
    Catalog& catalog_;
    const Tables& tables_;
    const Options& options_;
    // NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)
};

std::expected<Catalog, LoadFailure> Catalog::load(ops::Program program, const Tables& tables, const Options& options) {
    Catalog catalog;
    catalog.program_ = std::move(program);
    CatalogBuilder builder(catalog, tables, options);
    if (auto done = builder.run(); !done) return std::unexpected(std::move(done.error()));
    return catalog;
}

const Quest* Catalog::by_script(std::uint32_t script) const noexcept {
    const auto found = by_script_.find(script);
    return found == by_script_.end() ? nullptr : &quests_.at(found->second);
}

std::vector<const Quest*> Catalog::variants(std::int32_t quest) const {
    std::vector<const Quest*> out;
    const auto found = by_quest_.find(quest);
    if (found == by_quest_.end()) return out;
    out.reserve(found->second.size());
    for (const std::size_t index : found->second) out.push_back(&quests_.at(index));
    return out;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): mã NPC và mã tên là hai khoá tra khác nhau, nơi gọi nêu tên (HP-07)
std::vector<Offer> Catalog::offers_at(std::uint32_t guid, std::int32_t scene, std::uint32_t name) const {
    std::vector<Offer> out;
    if (const auto found = by_guid_.find(guid); guid != 0 && found != by_guid_.end()) {
        out.insert(out.end(), found->second.begin(), found->second.end());
    }
    if (const auto found = by_name_.find({scene, name}); name != 0 && found != by_name_.end()) {
        out.insert(out.end(), found->second.begin(), found->second.end());
    }
    std::ranges::sort(out);
    out.erase(std::ranges::unique(out).begin(), out.end());
    return out;
}

std::uint32_t Catalog::group_of_template(std::uint32_t monster_template) const noexcept {
    const auto found = template_group_.find(monster_template);
    return found == template_group_.end() ? 0U : found->second;
}

}  // namespace game::mission
