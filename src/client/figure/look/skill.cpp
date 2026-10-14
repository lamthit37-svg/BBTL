// Bộ đọc năm bảng đòn đánh và hàm giải (xem skill.hpp).
#include "look/skill.hpp"

#include "core/number.hpp"
#include "look/appearance.hpp"
#include "look/detail/rows.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <functional>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace game::look {
namespace {

using detail::read_all;
using detail::sorted_unique;

constexpr std::uint32_t kMaxLong = 0xFFFFFFFFU;

Race race_of(table::RowReader& reader) {
    return static_cast<Race>(reader.number("race", 0, 1));
}

// Ô số thực có thể rỗng: rỗng thì fallback.
float real_or(table::RowReader& reader, std::string_view column, float fallback) {
    if (reader.text(column).empty()) return fallback;
    return reader.real(column);
}

// Mảng mốc của kịch bản (BreakTime, HitTime, ShakeTime): các số cách nhau bằng dấu cách; mốc âm (-1 là "không
// có") bị bỏ. Chữ không phải số là lỗi của dòng.
std::vector<float> moments(table::RowReader& reader, std::string_view column) {
    const std::string_view cell = reader.text(column);
    std::vector<float> found;
    std::size_t start = 0;
    while (start < cell.size()) {
        const std::size_t stop = std::min(cell.find(' ', start), cell.size());
        const std::string_view word = cell.substr(start, stop - start);
        start = stop + 1;
        if (word.empty()) continue;
        const core::OptionalDouble parsed = core::parse_double(word);
        const bool is_number = parsed && parsed->length == word.size() && std::isfinite(parsed->value);
        if (!is_number) {
            reader.reject(column, std::format("\"{}\" không phải danh sách số", cell));
            return {};
        }
        if (parsed->value >= 0.0) found.push_back(static_cast<float>(parsed->value));
    }
    return found;
}

MoveRow move_row(table::RowReader& reader) {
    MoveRow move;
    move.skill = reader.number("skill", 0, kMaxLong);
    move.name = reader.text("name");
    move.step = reader.number("step", 0, kMaxLong);
    move.action = reader.number("action", 0, kMaxLong);
    move.kind = static_cast<ActionKind>(reader.number("kind", 0, 2));
    move.send_ms = reader.number("send_ms", 0, kMaxLong);
    return move;
}

ActionRow action_row(table::RowReader& reader) {
    ActionRow action;
    action.race = race_of(reader);
    action.action = reader.number("action", 0, kMaxLong);
    const std::string_view weapon_name = reader.text("weapon");
    const std::optional<Weapon> weapon = weapon_named(weapon_name);
    if (weapon) {
        action.weapon = *weapon;
    } else {
        reader.reject("weapon", std::format("tên loại vũ khí lạ \"{}\"", weapon_name));
    }
    action.script = reader.text("script");
    return action;
}

ScriptRow script_row(table::RowReader& reader) {
    ScriptRow script;
    script.name = reader.text("script");
    script.animation = reader.text("animation");
    script.break_times = moments(reader, "break_time");
    script.hit_times = moments(reader, "hit_time");
    script.shake_times = moments(reader, "shake_time");
    return script;
}

struct KindName {
    std::string_view name;
    EventKind kind;
};

constexpr std::array<KindName, 4> kKinds{{{.name = "AnimEffect", .kind = EventKind::kAnimEffect},
    {.name = "Ribbon", .kind = EventKind::kRibbon}, {.name = "Sound", .kind = EventKind::kSound},
    {.name = "SceneLight", .kind = EventKind::kSceneLight}}};

EventRow event_row(table::RowReader& reader) {
    EventRow event;
    event.script = reader.text("script");
    event.order = reader.number("order", 0, kMaxLong);
    const std::string_view kind_name = reader.text("kind");
    const auto kind = std::ranges::find(kKinds, kind_name, &KindName::name);
    if (kind != kKinds.end()) {
        event.kind = kind->kind;
    } else {
        reader.reject("kind", std::format("loại khối lạ \"{}\"", kind_name));
    }
    event.time = real_or(reader, "time", 0.0F);
    event.point = reader.text("point");
    event.name = reader.text("name");
    event.offset = {real_or(reader, "px", 0.0F), real_or(reader, "py", 0.0F), real_or(reader, "pz", 0.0F)};
    event.rotation = {real_or(reader, "rw", 1.0F), real_or(reader, "rx", 0.0F), real_or(reader, "ry", 0.0F),
        real_or(reader, "rz", 0.0F)};
    event.is_attached = reader.text("attach") == "true";
    event.props = reader.text("props");
    return event;
}

SkillClipRow clip_row(table::RowReader& reader) {
    SkillClipRow clip;
    clip.race = race_of(reader);
    clip.animation = reader.text("animation");
    clip.anim = reader.text("anim");
    clip.clip = reader.text("clip");
    return clip;
}

StrikeEvent strike_event(const EventRow& row) {
    return StrikeEvent{.kind = row.kind,
        .time = row.time,
        .point = row.point,
        .name = row.name,
        .offset = row.offset,
        .rotation = row.rotation,
        .is_attached = row.is_attached,
        .props = row.props};
}

std::tuple<int, std::uint32_t, int> action_key(const ActionRow& row) {
    return {static_cast<int>(row.race), row.action, static_cast<int>(row.weapon)};
}

const ActionRow* action_exact(std::span<const ActionRow> actions, Race race, std::uint32_t action, Weapon weapon) {
    const std::tuple<int, std::uint32_t, int> key{static_cast<int>(race), action, static_cast<int>(weapon)};
    const auto found = std::ranges::lower_bound(actions, key, std::less<>{}, action_key);
    return found != actions.end() && action_key(*found) == key ? &*found : nullptr;
}

// Hành động của loại vũ khí; không có dòng thì dòng tay không (như clip_of của look.cpp).
const ActionRow* action_for(std::span<const ActionRow> actions, Race race, std::uint32_t action, Weapon weapon) {
    const ActionRow* own = action_exact(actions, race, action, weapon);
    if (own != nullptr || weapon == Weapon::kNone) return own;
    return action_exact(actions, race, action, Weapon::kNone);
}

const ScriptRow* script_named(std::span<const ScriptRow> scripts, std::string_view name) {
    const auto name_of = [](const ScriptRow& row) { return std::string_view(row.name); };
    const auto found = std::ranges::lower_bound(scripts, name, std::less<>{}, name_of);
    return found != scripts.end() && found->name == name ? &*found : nullptr;
}

std::pair<int, std::string_view> clip_key(const SkillClipRow& row) {
    return {static_cast<int>(row.race), std::string_view(row.animation)};
}

const SkillClipRow* clip_named(std::span<const SkillClipRow> clips, Race race, std::string_view animation) {
    const std::pair<int, std::string_view> key{static_cast<int>(race), animation};
    const auto found = std::ranges::lower_bound(clips, key, std::less<>{}, clip_key);
    return found != clips.end() && clip_key(*found) == key ? &*found : nullptr;
}

// Khối con của kịch bản, đã xếp theo (script, order).
std::vector<StrikeEvent> events_of(std::span<const EventRow> events, std::string_view script) {
    const auto script_of = [](const EventRow& row) { return std::string_view(row.script); };
    const auto range = std::ranges::equal_range(events, script, std::less<>{}, script_of);
    std::vector<StrikeEvent> found;
    found.reserve(range.size());
    for (const EventRow& row : range) found.push_back(strike_event(row));
    return found;
}

} // namespace

Rows<MoveRow> read_moves(const table::Tsv& table) {
    const auto key = [](const MoveRow& row) { return std::pair(row.skill, row.step); };
    return sorted_unique(read_all<MoveRow>(table, move_row), key, "skill_moves");
}

Rows<ActionRow> read_actions(const table::Tsv& table) {
    return sorted_unique(read_all<ActionRow>(table, action_row), action_key, "skill_actions");
}

Rows<ScriptRow> read_scripts(const table::Tsv& table) {
    const auto key = [](const ScriptRow& row) { return std::string_view(row.name); };
    return sorted_unique(read_all<ScriptRow>(table, script_row), key, "skill_scripts");
}

Rows<EventRow> read_events(const table::Tsv& table) {
    const auto key = [](const EventRow& row) { return std::pair(std::string_view(row.script), row.order); };
    return sorted_unique(read_all<EventRow>(table, event_row), key, "skill_events");
}

Rows<SkillClipRow> read_skill_clips(const table::Tsv& table) {
    return sorted_unique(read_all<SkillClipRow>(table, clip_row), clip_key, "skill_clips");
}

std::size_t step_count(std::span<const MoveRow> moves, std::uint32_t skill) {
    return static_cast<std::size_t>(std::ranges::count(moves, skill, &MoveRow::skill));
}

std::vector<Strike> strikes_of(const SkillTables& tables, Race race, Weapon weapon, std::uint32_t skill) {
    const auto range = std::ranges::equal_range(tables.moves, skill, std::less<>{}, &MoveRow::skill);
    std::vector<Strike> strikes;
    for (const MoveRow& move : range) {
        const ActionRow* action = action_for(tables.actions, race, move.action, weapon);
        if (action == nullptr) continue;
        const ScriptRow* script = script_named(tables.scripts, action->script);
        if (script == nullptr) continue;
        const SkillClipRow* clip = clip_named(tables.clips, race, script->animation);
        if (clip == nullptr) continue;
        Strike strike;
        strike.skill = skill;
        strike.step = move.step;
        strike.action = move.action;
        strike.kind = move.kind;
        strike.send_ms = move.send_ms;
        strike.script = script->name;
        strike.clip = Clip{.anim = clip->anim, .name = clip->clip};
        strike.break_times = script->break_times;
        strike.hit_times = script->hit_times;
        strike.shake_times = script->shake_times;
        strike.events = events_of(tables.events, script->name);
        strikes.push_back(std::move(strike));
    }
    return strikes;
}

} // namespace game::look
