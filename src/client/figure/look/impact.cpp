/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/impact.cpp
 *  PHÂN HỆ   : Figure / Look / Impact
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đếm tham chiếu hiệu ứng và đọc bảng impacts.tsv.
 *  - Khác gốc: id không có trong bảng vẫn có ô, nhưng kept_after_death là đúng
 *    để drop_dead không xoá hiệu ứng mà bảng không mô tả.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "look/impact.hpp"

#include "look/detail/rows.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::look {
namespace {

constexpr std::uint32_t kMaxId = 2'000'000'000;
constexpr std::uint32_t kMaxRefs = 1'000'000;
constexpr std::array<std::string_view, 10> kColumns{"id", "trigger_effect", "trigger_sound",
    "trigger_anchor", "continuous_effect", "continuous_sound", "continuous_anchor",
    "kept_after_death", "is_linear", "linear_anchor"};

[[nodiscard]] ImpactCue make_cue(ImpactCueKind kind, std::uint32_t id, std::string name,
    std::string anchor) {
    ImpactCue cue;
    cue.kind = kind;
    cue.id = id;
    cue.name = std::move(name);
    cue.anchor = std::move(anchor);
    return cue;
}

void push_once_effect(std::vector<ImpactCue>& cues, const ImpactRow& row) {
    const std::string name = row.trigger_effect;
    const std::string anchor = row.trigger_anchor;
    const ImpactCue cue = make_cue(ImpactCueKind::kOnce, row.id, name, anchor);
    cues.push_back(cue);
}

void push_once_sound(std::vector<ImpactCue>& cues, const ImpactRow& row) {
    const std::string name = row.trigger_sound;
    const ImpactCue cue = make_cue(ImpactCueKind::kSound, row.id, name, {});
    cues.push_back(cue);
}

void cue_once(std::vector<ImpactCue>& cues, const ImpactRow* row, bool show) {
    if (row == nullptr || !show) return;
    if (!row->trigger_effect.empty()) push_once_effect(cues, *row);
    if (!row->trigger_sound.empty()) push_once_sound(cues, *row);
}

void cue_attach(std::vector<ImpactCue>& cues, ImpactSlot& slot, const ImpactRow* row) {
    if (row == nullptr || row->continuous_effect.empty()) return;
    slot.continuous = row->continuous_effect;
    slot.anchor = row->continuous_anchor;
    const ImpactCue cue = make_cue(ImpactCueKind::kAttach, row->id, slot.continuous, slot.anchor);
    cues.push_back(cue);
}

void cue_detach(std::vector<ImpactCue>& cues, const ImpactSlot& slot) {
    if (slot.continuous.empty()) return;
    const ImpactCue cue = make_cue(ImpactCueKind::kDetach, slot.id, slot.continuous, slot.anchor);
    cues.push_back(cue);
}

void copy_row_flags(ImpactSlot& made, const ImpactRow* row) {
    if (row == nullptr) return;
    made.kept_after_death = row->kept_after_death;
    made.is_linear = row->is_linear;
    made.linear_anchor = row->linear_anchor;
}

bool open_slot(std::vector<ImpactSlot>& slots, std::uint32_t id, const ImpactRow* row) {
    if (slots.size() >= kMaxImpacts) return false;
    ImpactSlot made;
    made.id = id;
    copy_row_flags(made, row);
    slots.push_back(std::move(made));
    return true;
}

ImpactRow impact_row(table::RowReader& reader) {
    ImpactRow row;
    row.id = reader.number("id", 0, kMaxId);
    row.trigger_effect = std::string(reader.text("trigger_effect"));
    row.trigger_sound = std::string(reader.text("trigger_sound"));
    row.trigger_anchor = std::string(reader.text("trigger_anchor"));
    row.continuous_effect = std::string(reader.text("continuous_effect"));
    row.continuous_sound = std::string(reader.text("continuous_sound"));
    row.continuous_anchor = std::string(reader.text("continuous_anchor"));
    row.kept_after_death = reader.flag("kept_after_death");
    row.is_linear = reader.flag("is_linear");
    row.linear_anchor = std::string(reader.text("linear_anchor"));
    return row;
}

[[nodiscard]] std::string missing_impact_column(std::string_view column) {
    return std::format("bảng impacts thiếu cột {}", column);
}

[[nodiscard]] std::optional<std::string> absent_impact_column(const table::Tsv& table) {
    for (const std::string_view column : kColumns) {
        if (table::column_of(table, column)) continue;
        return missing_impact_column(column);
    }
    return std::nullopt;
}

[[nodiscard]] std::expected<table::Tsv, std::string> parse_table(std::string_view text) {
    table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(std::format("bảng impacts sai, {}", parsed.error()));
    const std::optional<std::string> missing = absent_impact_column(*parsed);
    if (missing) return std::unexpected(*missing);
    return std::move(*parsed);
}

} // namespace

void ImpactBook::reset(std::vector<ImpactRow> rows) {
    rows_ = std::move(rows);
    slots_.clear();
}

bool ImpactBook::known(std::uint32_t id) const noexcept {
    return find_row(id) != nullptr;
}

const ImpactRow* ImpactBook::find_row(std::uint32_t id) const noexcept {
    const auto found = std::ranges::lower_bound(rows_, id, {}, &ImpactRow::id);
    if (found == rows_.end() || found->id != id) return nullptr;
    return &*found;
}

std::vector<ImpactSlot>::iterator ImpactBook::find_slot(std::uint32_t id) noexcept {
    return std::ranges::find(slots_, id, &ImpactSlot::id);
}

std::vector<ImpactCue> ImpactBook::enable_new(std::uint32_t id, bool show) {
    std::vector<ImpactCue> cues;
    const ImpactRow* row = find_row(id);
    if (!open_slot(slots_, id, row)) return cues;
    ImpactSlot& slot = slots_.back();
    cue_once(cues, row, show);
    cue_attach(cues, slot, row);
    if (slot.refs < kMaxRefs) ++slot.refs;
    return cues;
}

std::vector<ImpactCue> ImpactBook::enable(std::uint32_t id, bool show) {
    std::vector<ImpactCue> cues;
    const auto slot = find_slot(id);
    if (slot == slots_.end()) return enable_new(id, show);
    if (slot->refs < kMaxRefs) ++slot->refs;
    return cues;
}

std::vector<ImpactCue> ImpactBook::disable(std::uint32_t id) {
    std::vector<ImpactCue> cues;
    const auto slot = find_slot(id);
    if (slot == slots_.end()) return cues;
    if (slot->refs > 0) --slot->refs;
    if (slot->refs > 0) return cues;
    cue_detach(cues, *slot);
    slots_.erase(slot);
    return cues;
}

std::vector<ImpactCue> ImpactBook::drop_dead() {
    std::vector<ImpactCue> cues;
    for (const ImpactSlot& slot : slots_) {
        if (!slot.kept_after_death) cue_detach(cues, slot);
    }
    std::erase_if(slots_, [](const ImpactSlot& slot) { return !slot.kept_after_death; });
    return cues;
}

std::vector<ImpactCue> ImpactBook::clear() {
    std::vector<ImpactCue> cues;
    for (const ImpactSlot& slot : slots_)
        cue_detach(cues, slot);
    slots_.clear();
    return cues;
}

std::expected<std::vector<ImpactRow>, std::string> parse_impacts(std::string_view text) {
    auto table = parse_table(text);
    if (!table) return std::unexpected(table.error());
    Rows<ImpactRow> rows = detail::read_all<ImpactRow>(*table, impact_row);
    if (!rows) return std::unexpected(std::format("bảng impacts sai, {}", rows.error()));
    const auto key = [](const ImpactRow& row) { return row.id; };
    rows = detail::sorted_unique(std::move(rows), key, "impacts");
    if (!rows) return std::unexpected(rows.error());
    return std::move(*rows);
}

} // namespace game::look
