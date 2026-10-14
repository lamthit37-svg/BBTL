// Dựng danh mục nhiệm vụ nhỏ cho test từ các dòng viết tay, dùng đúng bộ nạp và cột của bảng thật. Điều kiện và hiệu ứng
// viết thẳng dạng dòng TSV của ops_conditions/ops_effects (mã bộ đếm từ 1) nên test nhìn thấy đúng dữ liệu mà bộ chạy ăn.
#pragma once

#include "mission/catalog.hpp"
#include "ops/ops.hpp"
#include "table/tsv.hpp"

#include <array>
#include <concepts>
#include <cstdint>
#include <expected>
#include <initializer_list>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {

struct QuestRow {
    std::uint32_t script = 0;
    std::int32_t quest = 0;
    std::string source = "table";
    std::string status = "ok";
    std::string reason = {};
    int in_client = 1;
    std::int32_t kind = 0;
    std::int32_t level = 1;
    std::string repeat = "once";
    std::string name = "Q";
    std::int32_t accept_scene = 0;
    std::int32_t accept_guid = 0;
    std::int32_t turn_scene = 0;
    std::int32_t turn_guid = 0;
    std::int32_t accept_cond = -1;
    std::int32_t ready_cond = -1;
    std::int32_t accept_fx = -1;
    std::int32_t submit_fx = -1;
    std::int32_t abandon_fx = -1;
    std::int32_t next_quest = -1;
    std::uint32_t next_script = 0;
    std::int32_t penalty = 0;
    std::int32_t ban_slot = -1;
    std::int32_t ban_seconds = 0;
};

namespace data_detail {

inline std::string cell(const std::string& text) { return text; }
inline std::string cell(std::string_view text) { return std::string(text); }
inline std::string cell(const char* text) { return {text}; }
template <std::integral Number>
std::string cell(Number value) {
    return std::to_string(value);
}

// Ghi một dòng TSV từ các ô (số, chuỗi) cách nhau tab.
template <typename... Cells>
void row(std::string& out, const Cells&... cells) {
    bool first = true;
    const auto put = [&](const auto& one) {
        if (!first) out += '\t';
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-array-to-pointer-decay): ô TSV viết bằng chuỗi literal (HP-07)
        out += cell(one);
        first = false;
    };
    (put(cells), ...);
    out += '\n';
}

}  // namespace data_detail

// NOLINTBEGIN(cppcoreguidelines-non-private-member-variables-in-classes): bộ dựng dữ liệu thử — các chuỗi TSV công khai để test thêm dòng hỏng thẳng vào bảng (HP-07)
class MissionData {
public:
    MissionData() {
        data_detail::row(quests_, "script", "quest", "source", "status", "reason", "in_client", "kind", "level", "repeat",
            "name", "accept_scene", "accept_guid", "turn_scene", "turn_guid", "accept_cond", "ready_cond", "accept_fx",
            "submit_fx", "abandon_fx", "next_quest", "next_script", "penalty", "ban_slot", "ban_seconds");
        data_detail::row(objectives_, "script", "seq", "kind", "index", "target", "count", "item", "rate", "scene", "flag", "name");
        data_detail::row(rewards_, "script", "seq", "group", "kind", "ref", "count", "cond");
        data_detail::row(prereqs_, "script", "prereq");
        data_detail::row(hooks_, "script", "seq", "event", "effects");
        data_detail::row(npcs_, "script", "role", "guid", "scene", "name", "how");
        data_detail::row(autos_, "level", "quest", "script", "pre_quest", "event", "full_level", "complete_idx", "record_idx", "message");
        data_detail::row(groups_, "group", "template", "name");
        data_detail::row(conditions_, "set", "clause", "seq", "op", "neg", "a1", "a2", "a3", "word");
        data_detail::row(effects_, "set", "seq", "op", "a1", "a2", "a3", "text", "args", "cond");
    }

    void quest(const QuestRow& r) {
        data_detail::row(quests_, r.script, r.quest, r.source, r.status, r.reason, r.in_client, r.kind, r.level, r.repeat, r.name,
            r.accept_scene, r.accept_guid, r.turn_scene, r.turn_guid, r.accept_cond, r.ready_cond, r.accept_fx, r.submit_fx,
            r.abandon_fx, r.next_quest, r.next_script, r.penalty, r.ban_slot, r.ban_seconds);
    }

    void objective(std::uint32_t script, int seq, std::string_view kind, int index, std::int32_t target, int count,
        std::int32_t item = 0, int rate = 0, int scene = 0, int flag = 0, std::string_view name = "") {
        data_detail::row(objectives_, script, seq, kind, index, target, count, item, rate, scene, flag, name);
    }

    void reward(std::uint32_t script, int seq, std::string_view group, std::string_view kind, std::int32_t ref,
        std::int64_t count, int cond = -1) {
        data_detail::row(rewards_, script, seq, group, kind, ref, count, cond);
    }

    void prereq(std::uint32_t script, std::int32_t prerequisite) { data_detail::row(prereqs_, script, prerequisite); }

    void hook(std::uint32_t script, int seq, std::string_view event, int effects) {
        data_detail::row(hooks_, script, seq, event, effects);
    }

    void npc(std::uint32_t script, std::string_view role, std::int32_t guid, int scene, std::string_view name = "-1") {
        data_detail::row(npcs_, script, role, guid, scene, name, "client");
    }

    void automatic(int level, std::int32_t quest_id, std::uint32_t script, int pre_quest, int full_level = -1,
        int complete_idx = -1, int record_idx = -1, std::string_view message = "") {
        data_detail::row(autos_, level, quest_id, script, pre_quest, 0, full_level, complete_idx, record_idx, message);
    }

    void group(std::uint32_t group_id, std::int32_t monster_template, std::string_view name) {
        data_detail::row(groups_, group_id, monster_template, name);
    }

    // Một dòng điều kiện: bộ `set`, mệnh đề `clause`, thứ tự `seq`, op, phủ định, a1..a3, từ.
    void cond(int set, int clause, int seq, std::string_view op, int neg, int a1, int a2 = 0, int a3 = 0,
        std::string_view word = "") {
        data_detail::row(conditions_, set, clause, seq, op, neg, a1, a2, a3, word);
    }

    void effect(int set, int seq, std::string_view op, int a1, int a2 = 0, int a3 = 0, std::string_view text = "",
        std::string_view args = "", int cond_id = -1) {
        data_detail::row(effects_, set, seq, op, a1, a2, a3, text, args, cond_id);
    }

    [[nodiscard]] static table::Tsv parsed(const std::string& text) {
        auto result = table::parse_tsv(text);
        return result ? std::move(*result) : table::Tsv{};
    }

    // Dòng thiếu ô hay bảng hỏng là lỗi nạp, không phải bảng rỗng: test thù địch cần thấy lỗi thật.
    [[nodiscard]] std::expected<mission::Catalog, mission::LoadFailure> build(const mission::Options& options = {}) const {
        auto program = ops::Program::load(parsed(conditions_), parsed(effects_));
        if (!program) {
            return std::unexpected(
                mission::LoadFailure{.error = mission::LoadError::kBadReference, .table = "ops", .detail = program.error().detail});
        }
        table::Tsv quests;
        table::Tsv objectives;
        table::Tsv rewards;
        table::Tsv prereqs;
        table::Tsv hooks;
        table::Tsv npcs;
        table::Tsv autos;
        table::Tsv groups;
        struct Slot {
            const char* name;
            const std::string* text;
            table::Tsv* out;
        };
        const std::array<Slot, 8> slots{{
            {.name = "mission_quests", .text = &quests_, .out = &quests},
            {.name = "mission_objectives", .text = &objectives_, .out = &objectives},
            {.name = "mission_rewards", .text = &rewards_, .out = &rewards},
            {.name = "mission_prereqs", .text = &prereqs_, .out = &prereqs},
            {.name = "mission_hooks", .text = &hooks_, .out = &hooks},
            {.name = "mission_npcs", .text = &npcs_, .out = &npcs},
            {.name = "mission_auto", .text = &autos_, .out = &autos},
            {.name = "mission_name_groups", .text = &groups_, .out = &groups},
        }};
        for (const Slot& slot : slots) {
            auto result = table::parse_tsv(*slot.text);
            if (!result) return std::unexpected(mission::LoadFailure{.error = mission::LoadError::kBadCell, .table = slot.name, .detail = result.error()});
            *slot.out = std::move(*result);
        }
        const mission::Tables tables{.quests = quests, .objectives = objectives, .rewards = rewards, .prereqs = prereqs, .hooks = hooks,
        .npcs = npcs, .autos = autos, .name_groups = groups};
        return mission::Catalog::load(std::move(*program), tables, options);
    }

    std::string quests_;
    std::string objectives_;
    std::string rewards_;
    std::string prereqs_;
    std::string hooks_;
    std::string npcs_;
    std::string autos_;
    std::string groups_;
    std::string conditions_;
    std::string effects_;
};
// NOLINTEND(cppcoreguidelines-non-private-member-variables-in-classes)

}  // namespace game::test
