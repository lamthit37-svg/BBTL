// Bảng nhiệm vụ nhận được và bộ lọc của nó (xem outline.hpp). Thứ tự các phép xét trong passes giữ
// đúng thứ tự của hàm 0x1406ddeb0 của Game.exe 2026.
#include "quest/outline.hpp"

#include "quest/log.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::quest {
namespace {

constexpr std::int32_t kLowest = std::numeric_limits<std::int32_t>::min();
constexpr std::int32_t kHighest = std::numeric_limits<std::int32_t>::max();
// Môn phái của máy chủ gốc đánh số 0..15; ô sect ngoài khoảng đó không đòi môn phái nào.
constexpr std::int32_t kLastSect = 15;
// Cột hidden bằng 1 là giấu, bằng 2 là hiện với tên riêng của loại máy chủ.
constexpr std::int32_t kHidden = 1;
constexpr std::int32_t kRenamed = 2;
// Kết quả GetMissionInfo_Kind khi kind ngoài 0..199: số 0, script nối thành chữ.
constexpr std::string_view kNoKindTitle = "0";
constexpr std::int32_t kLastTitledKind = 199;
// Sáu nhiệm vụ "hào hiệp võ dụ" mà bộ lọc xét riêng.
constexpr std::int32_t kEdictCard = 3138;
constexpr std::int32_t kEdictTokens = 3139;
constexpr std::int32_t kEdictOpen = 3140;
constexpr std::array<std::int32_t, 3> kEdictChain = {3141, 3142, 3143};

[[nodiscard]] std::int32_t whole(table::RowReader& reader, std::string_view column) {
    return reader.integer(column, kLowest, kHighest);
}

[[nodiscard]] OutlineRow outline_row(table::RowReader& reader) {
    OutlineRow row;
    row.id = whole(reader, "id");
    row.mission = whole(reader, "mission");
    row.kind = whole(reader, "kind");
    row.sect = whole(reader, "sect");
    row.level = whole(reader, "level");
    row.min_level = whole(reader, "min_level");
    row.max_level = whole(reader, "max_level");
    row.scene = whole(reader, "scene");
    row.needs = {whole(reader, "requires_1"), whole(reader, "requires_2"), whole(reader, "requires_3")};
    row.x = whole(reader, "x");
    row.z = whole(reader, "z");
    row.hidden = whole(reader, "hidden");
    row.hidden_original = whole(reader, "hidden_original");
    row.hidden_light = whole(reader, "hidden_light");
    row.npc = reader.text("npc");
    row.name = reader.text("name");
    row.name_original = reader.text("name_original");
    row.name_light = reader.text("name_light");
    row.scene_name = reader.text("scene_name");
    return row;
}

// Cột hidden mà loại máy chủ của seeker xét: máy chủ gốc trước, rồi máy chủ nhẹ, rồi máy chủ
// thường (0x1406ddf27..0x1406ddf5b).
[[nodiscard]] std::int32_t hidden_mark(const OutlineRow& row, const Seeker& seeker) noexcept {
    if (seeker.is_original) return row.hidden_original;
    return seeker.is_light ? row.hidden_light : row.hidden;
}

// Ô sect cho môn phái của seeker qua: kAny, đúng môn phái, ngoài 0..15, hoặc 9.
[[nodiscard]] bool sect_fits(std::int32_t wanted, std::int32_t sect) noexcept {
    if (wanted == kAny || wanted == sect) return true;
    const bool is_listed = wanted >= 0 && wanted <= kLastSect;
    return !is_listed || wanted == kNoSect;
}

// Một nhiệm vụ tiền đề: kAny là không đòi, không thì phải đã xong.
[[nodiscard]] bool need_met(const Log& log, std::int32_t need) noexcept {
    return need == kAny || is_done(log, need);
}

[[nodiscard]] bool kind_in_range(std::int32_t kind) noexcept {
    return kind >= 1 && std::cmp_less_equal(kind, kKindCount);
}

// Đang giữ nhiệm vụ id trong một ô bất kỳ, kể cả ô trống mang id trùng (vòng 0x1406de093 của mã
// gốc không lọc id âm).
[[nodiscard]] bool slot_has(const Log& log, std::int32_t mission) noexcept {
    return std::ranges::contains(log.slots, mission, &Slot::mission);
}

// Phép xét riêng của sáu nhiệm vụ hào hiệp võ dụ (0x1406de0bc..0x1406de1ae); nhiệm vụ khác luôn
// qua.
[[nodiscard]] bool edict_allows(std::int32_t mission, const Seeker& seeker, const Log& log) noexcept {
    if (mission == kEdictCard) return seeker.edict.has_card;
    if (mission == kEdictTokens) return seeker.edict.tokens > 0;
    if (mission == kEdictOpen) return seeker.edict.stage != 1;
    if (!std::ranges::contains(kEdictChain, mission)) return true;
    if (seeker.edict.stage == 0) return false;
    const auto is_held = [&log](std::int32_t link) noexcept { return holds(log, link); };
    return std::ranges::none_of(kEdictChain, is_held);
}

// Một dòng có lọt bộ lọc không, theo đúng thứ tự xét của mã gốc.
[[nodiscard]] bool passes(const OutlineRow& row, const Seeker& seeker, const Log& log) noexcept {
    if (hidden_mark(row, seeker) == kHidden) return false;
    const std::int32_t level = effective_level(seeker);
    if (level < row.min_level || level > row.max_level) return false;
    if (!sect_fits(row.sect, seeker.sect)) return false;
    if (!kind_in_range(row.kind)) return false;
    if (is_done(log, row.mission)) return false;
    const auto is_met = [&log](std::int32_t need) noexcept { return need_met(log, need); };
    if (!std::ranges::all_of(row.needs, is_met)) return false;
    if (slot_has(log, row.mission)) return false;
    return edict_allows(row.mission, seeker, log);
}

// Tên hiển thị của một dòng: tên riêng của loại máy chủ khi cột hidden của loại đó bằng 2 và tên
// riêng khác rỗng; tên của máy chủ nhẹ xét sau nên thắng (0x1406ddc76..0x1406ddcf0).
[[nodiscard]] std::string_view shown_name(const OutlineRow& row, const Seeker& seeker) noexcept {
    std::string_view name = row.name;
    const bool has_original = seeker.is_original && row.hidden_original == kRenamed && !row.name_original.empty();
    if (has_original) name = row.name_original;
    const bool has_light = seeker.is_light && row.hidden_light == kRenamed && !row.name_light.empty();
    if (has_light) name = row.name_light;
    return name;
}

} // namespace

OutlineRows read_outline(const table::Tsv& table) {
    std::vector<OutlineRow> rows;
    rows.reserve(table.rows.size());
    for (std::size_t index = 0; index < table.rows.size(); ++index) {
        table::RowReader reader(table, index);
        rows.push_back(outline_row(reader));
        if (reader.error()) return std::unexpected(*reader.error());
    }
    return rows;
}

KindRows read_kinds(const table::Tsv& table) {
    std::vector<KindRow> rows;
    rows.reserve(table.rows.size());
    for (std::size_t index = 0; index < table.rows.size(); ++index) {
        table::RowReader reader(table, index);
        KindRow row;
        row.id = whole(reader, "id");
        row.name = reader.text("name");
        if (reader.error()) return std::unexpected(*reader.error());
        rows.push_back(std::move(row));
    }
    std::ranges::stable_sort(rows, {}, &KindRow::id);
    const auto repeats = std::ranges::unique(rows, {}, &KindRow::id);
    rows.erase(repeats.begin(), repeats.end());
    return rows;
}

std::string_view kind_title(std::span<const KindRow> kinds, std::int32_t kind) noexcept {
    if (kind < 0 || kind > kLastTitledKind) return kNoKindTitle;
    const auto found = std::ranges::lower_bound(kinds, kind, {}, &KindRow::id);
    if (found == kinds.end() || found->id != kind) return {};
    return found->name;
}

void collect_offers(std::span<const OutlineRow> rows, const Seeker& seeker, const Log& log, Offers& offers) {
    for (std::vector<std::uint32_t>& list : offers.by_kind) list.clear();
    for (std::size_t index = 0; index < rows.size(); ++index) {
        const OutlineRow& row = rows[index];
        if (!passes(row, seeker, log)) continue;
        offers.by_kind.at(static_cast<std::size_t>(row.kind) - 1).push_back(static_cast<std::uint32_t>(index));
    }
}

std::size_t offer_count(const Offers& offers, std::int32_t kind) noexcept {
    if (!kind_in_range(kind)) return 0;
    return offers.by_kind.at(static_cast<std::size_t>(kind) - 1).size();
}

std::optional<OfferView> offer_at(
    std::span<const OutlineRow> rows, const Offers& offers, const Seeker& seeker, const OfferAsk& ask) noexcept {
    const bool is_listed = ask.number >= 1 && std::cmp_less_equal(ask.number, offer_count(offers, ask.kind));
    if (!is_listed) return std::nullopt;
    const std::vector<std::uint32_t>& list = offers.by_kind.at(static_cast<std::size_t>(ask.kind) - 1);
    const std::size_t index = list.at(static_cast<std::size_t>(ask.number) - 1);
    if (index >= rows.size()) return std::nullopt;
    const OutlineRow& row = rows[index];
    if (hidden_mark(row, seeker) == kHidden) return std::nullopt;
    OfferView view;
    view.level = row.level == kAny ? effective_level(seeker) : row.level;
    view.min_level = row.min_level;
    view.max_level = row.max_level;
    view.npc = row.npc;
    view.scene_name = row.scene_name;
    view.name = shown_name(row, seeker);
    view.x = row.x;
    view.z = row.z;
    view.scene = row.scene;
    return view;
}

} // namespace game::quest
