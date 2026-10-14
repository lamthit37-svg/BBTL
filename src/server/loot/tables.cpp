// Bảng rơi đồ: xem tables.hpp.
#include "loot/tables.hpp"

#include "item/catalog.hpp"
#include "item/rows.hpp"
#include "item/types.hpp"
#include "loot/chance.hpp"
#include "loot/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <iterator>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::loot {

using Fail = std::unexpected<std::string>;
using Loaded = std::expected<void, std::string>;

namespace {

using item::tsv::Bounds;
using item::tsv::Cells;
using item::tsv::Rows;

constexpr std::int64_t kMaxId = std::numeric_limits<std::int32_t>::max();
constexpr std::int64_t kMaxU32 = std::numeric_limits<std::uint32_t>::max();
constexpr std::size_t kFirstPairColumn = 4;       // id, box_value, loại phát thanh, cờ ép khoá, rồi tới các cặp
constexpr std::size_t kMaxPackEntries = 1024;     // bảng thật 256; trần để số cặp luôn vừa uint16_t
constexpr std::int64_t kMaxOrigin = 6;            // item::Origin::kDailyBoss
constexpr std::int64_t kMaxBroadcast = 1'000'000;
constexpr std::int64_t kMaxLevelDelta = 100'000;
constexpr std::uint32_t kMaxGapPpm = 10 * kPpm;   // hệ số chênh cấp lớn nhất chấp nhận: gấp 10 lần
constexpr std::int64_t kMaxWeight = 1'000'000'000;
constexpr std::size_t kMaxSamples = 8;

} // namespace

// Bộ nạp: friend của LootTables để ghi thẳng vào thành viên.
struct LootLoader {
    static Loaded read_packs(LootTables& out, std::string_view text, const item::Catalog& catalog);
    static Loaded read_monsters(LootTables& out, std::string_view text);
    static Loaded read_gaps(LootTables& out, std::string_view text);
    static Loaded read_rate_items(LootTables& out, std::string_view text, const item::Catalog& catalog);
    static Loaded read_boxes(LootTables& out, std::string_view text, const item::Catalog& catalog);
};

namespace {

void note_unknown(Diagnostics& diagnostics, std::string_view table, std::size_t line, std::int64_t item) {
    if (diagnostics.samples.size() >= kMaxSamples) return;
    diagnostics.samples.push_back(std::string(table) + ":" + std::to_string(line) + ": vật phẩm " + std::to_string(item)
        + " không có trong catalog, bỏ qua");
}

// Đọc một dòng gói. Dòng hỏng thì lỗi nằm ở cells.error().
void read_pack_row(std::vector<PackEntry>& entries, const Rows& rows, Cells& cells, const item::Catalog& catalog,
    Pack& pack, Diagnostics& diagnostics) {
    pack.id = PackId{static_cast<std::uint32_t>(cells.integer(0, Bounds{0, kMaxU32}))};
    pack.value = cells.integer(1, Bounds{1, kMaxId});
    pack.broadcast = static_cast<std::int32_t>(cells.optional_integer(2, Bounds{0, kMaxBroadcast}, -1));
    pack.force_bind = cells.integer(3, Bounds{0, 1}) != 0;
    pack.begin = static_cast<std::uint32_t>(entries.size());
    bool ended = false;
    for (std::size_t col = kFirstPairColumn; col < rows.column_count(); col += 2) {
        const std::int64_t id = cells.optional_integer(col, Bounds{1, kMaxId}, -1);
        if (id < 0) {
            ended = true;
            continue;
        }
        if (ended) {
            cells.fail(col, "ô vật phẩm chen sau ô trống");
            break;
        }
        const std::int64_t origin = cells.optional_integer(col + 1, Bounds{0, kMaxOrigin}, kInheritOrigin);
        const item::TemplateId item{static_cast<std::uint32_t>(id)};
        if (catalog.find(item) == nullptr) {
            ++diagnostics.unknown_pack_items;
            note_unknown(diagnostics, "drop_packages", rows.line(), id);
            continue;
        }
        entries.push_back(PackEntry{.item = item, .origin = static_cast<std::int8_t>(origin)});
    }
    pack.count = static_cast<std::uint16_t>(entries.size() - pack.begin);
}

} // namespace

Loaded LootLoader::read_packs(LootTables& out, std::string_view text, const item::Catalog& catalog) {
    Rows rows(text);
    if (rows.error()) return Fail("drop_packages: " + *rows.error());
    const std::size_t columns = rows.column_count();
    if (rows.name(0) != "id" || rows.name(1) != "box_value") return Fail("drop_packages: hai cột đầu phải là id và box_value");
    if (columns < kFirstPairColumn + 2 || (columns - kFirstPairColumn) % 2 != 0
        || (columns - kFirstPairColumn) / 2 > kMaxPackEntries) {
        return Fail("drop_packages: số cột " + std::to_string(columns) + " không khớp bố cục 4 cột đầu và các cặp");
    }
    Cells cells(rows, "drop_packages");
    while (rows.next()) {
        Pack pack;
        read_pack_row(out.pack_entries_, rows, cells, catalog, pack, out.diagnostics_);
        if (cells.error()) return Fail(*cells.error());
        if (pack.count == 0) ++out.diagnostics_.empty_packs;
        out.packs_.push_back(pack);
    }
    if (rows.error()) return Fail("drop_packages: " + *rows.error());
    std::ranges::sort(out.packs_, {}, &Pack::id);
    const auto dup = std::ranges::adjacent_find(out.packs_, {}, &Pack::id);
    if (dup != out.packs_.end()) return Fail("drop_packages: gói " + std::to_string(dup->id.value()) + " xuất hiện hai lần");
    return {};
}

Loaded LootLoader::read_monsters(LootTables& out, std::string_view text) {
    Rows rows(text);
    if (rows.error()) return Fail("monster_drops: " + *rows.error());
    constexpr std::size_t kFirstPack = 3;
    const std::size_t columns = rows.column_count();
    if (rows.name(0) != "id" || rows.name(1) != "mvalue" || rows.name(2) != "drop_type" || rows.name(3) != "did_1") {
        return Fail("monster_drops: bốn cột đầu phải là id, mvalue, drop_type, did_1");
    }
    if (columns <= kFirstPack || columns - kFirstPack > kMaxPacksPerMonster) {
        return Fail("monster_drops: số cột gói " + std::to_string(columns - kFirstPack) + " ngoài 1.." + std::to_string(kMaxPacksPerMonster));
    }
    Cells cells(rows, "monster_drops");
    while (rows.next()) {
        MonsterDrop drop;
        drop.monster = ids::MonsterTemplateId{static_cast<std::uint32_t>(cells.integer(0, Bounds{0, kMaxU32}))};
        drop.value = cells.integer(1, Bounds{0, kMaxId});
        drop.ruler = cells.integer(2, Bounds{0, 1}) == 0 ? Ruler::kCommon : Ruler::kBoss;
        bool ended = false;
        for (std::size_t col = kFirstPack; col < columns && !cells.error(); ++col) {
            const std::int64_t id = cells.optional_integer(col, Bounds{0, kMaxU32}, -1);
            if (id < 0) {
                ended = true;
                continue;
            }
            if (ended) {
                cells.fail(col, "gói chen sau ô trống");
                break;
            }
            const PackId pack{static_cast<std::uint32_t>(id)};
            if (out.pack(pack) == nullptr) {
                cells.fail(col, "gói " + std::to_string(id) + " không có trong drop_packages");
                break;
            }
            drop.packs.at(drop.pack_count++) = pack;
        }
        if (cells.error()) return Fail(*cells.error());
        out.monsters_.push_back(drop);
    }
    if (rows.error()) return Fail("monster_drops: " + *rows.error());
    std::ranges::sort(out.monsters_, {}, &MonsterDrop::monster);
    const auto dup = std::ranges::adjacent_find(out.monsters_, {}, &MonsterDrop::monster);
    if (dup != out.monsters_.end()) return Fail("monster_drops: quái " + std::to_string(dup->monster.value()) + " xuất hiện hai lần");
    return {};
}

Loaded LootLoader::read_gaps(LootTables& out, std::string_view text) {
    Rows rows(text);
    if (rows.error()) return Fail("drop_level_gap_factors: " + *rows.error());
    const std::size_t delta_col = rows.column("level_delta");
    const std::size_t rate_col = rows.column("rate");
    if (delta_col == Rows::npos || rate_col == Rows::npos) return Fail("drop_level_gap_factors: thiếu cột level_delta hay rate");
    Cells cells(rows, "drop_level_gap_factors");
    while (rows.next()) {
        const std::int64_t delta = cells.integer(delta_col, Bounds{-kMaxLevelDelta, kMaxLevelDelta});
        const std::optional<std::uint32_t> ppm = parse_ppm(cells.text(rate_col), kMaxGapPpm);
        if (!ppm) cells.fail(rate_col, "không phải số thập phân trong 0..10");
        if (cells.error() || !ppm) return Fail(cells.error().value_or("drop_level_gap_factors: hệ số hỏng"));
        out.gaps_.emplace_back(delta, *ppm);
    }
    if (rows.error()) return Fail("drop_level_gap_factors: " + *rows.error());
    std::ranges::sort(out.gaps_, {}, &std::pair<std::int64_t, std::uint32_t>::first);
    const auto dup = std::ranges::adjacent_find(out.gaps_, {}, &std::pair<std::int64_t, std::uint32_t>::first);
    if (dup != out.gaps_.end()) return Fail("drop_level_gap_factors: chênh lệch " + std::to_string(dup->first) + " xuất hiện hai lần");
    return {};
}

Loaded LootLoader::read_rate_items(LootTables& out, std::string_view text, const item::Catalog& catalog) {
    if (text.empty()) return {};
    Rows rows(text);
    if (rows.error()) return Fail("item_drop_rates: " + *rows.error());
    const std::size_t item_col = rows.column("item_id");
    const std::size_t chance_col = rows.column("drop_chance");
    const std::size_t message_col = rows.column("sends_message");
    if (item_col == Rows::npos || chance_col == Rows::npos || message_col == Rows::npos) {
        return Fail("item_drop_rates: thiếu cột item_id, drop_chance hay sends_message");
    }
    Cells cells(rows, "item_drop_rates");
    while (rows.next()) {
        const std::int64_t id = cells.integer(item_col, Bounds{1, kMaxId});
        const std::int64_t chance = cells.integer(chance_col, Bounds{0, kMaxWeight});
        const bool announce = cells.integer(message_col, Bounds{0, 1}) != 0;
        if (cells.error()) return Fail(*cells.error());
        const item::TemplateId item{static_cast<std::uint32_t>(id)};
        if (catalog.find(item) == nullptr) {
            ++out.diagnostics_.unknown_rate_items;
            note_unknown(out.diagnostics_, "item_drop_rates", rows.line(), id);
            continue;
        }
        out.rate_items_.push_back(Pick{.item = item, .announce = announce});
        out.rate_weights_.push_back(static_cast<std::uint32_t>(chance));
    }
    if (rows.error()) return Fail("item_drop_rates: " + *rows.error());
    return {};
}

namespace {

struct BoxRow {
    std::string key;
    std::int64_t index = 0;
    Pick pick;
    std::uint32_t weight = 0;
};

} // namespace

Loaded LootLoader::read_boxes(LootTables& out, std::string_view text, const item::Catalog& catalog) {
    if (text.empty()) return {};
    Rows rows(text);
    if (rows.error()) return Fail("loot_box_entries: " + *rows.error());
    const std::size_t key_col = rows.column("box_key");
    const std::size_t index_col = rows.column("index");
    const std::size_t item_col = rows.column("item_id");
    const std::size_t rate_col = rows.column("rate");
    const std::size_t notice_col = rows.column("notice");
    if (key_col == Rows::npos || index_col == Rows::npos || item_col == Rows::npos || rate_col == Rows::npos
        || notice_col == Rows::npos) {
        return Fail("loot_box_entries: thiếu cột box_key, index, item_id, rate hay notice");
    }
    Cells cells(rows, "loot_box_entries");
    std::vector<BoxRow> kept;
    while (rows.next()) {
        BoxRow row;
        row.key = std::string(cells.text(key_col));
        if (row.key.empty()) cells.fail(key_col, "khoá hộp trống");
        row.index = cells.integer(index_col, Bounds{0, kMaxId});
        const std::int64_t id = cells.integer(item_col, Bounds{1, kMaxId});
        row.weight = static_cast<std::uint32_t>(cells.integer(rate_col, Bounds{0, kMaxWeight}));
        const bool announce = cells.integer(notice_col, Bounds{0, 1}) != 0;
        if (cells.error()) return Fail(*cells.error());
        row.pick = Pick{.item = item::TemplateId{static_cast<std::uint32_t>(id)}, .announce = announce};
        if (catalog.find(row.pick.item) == nullptr) {
            ++out.diagnostics_.unknown_box_items;
            note_unknown(out.diagnostics_, "loot_box_entries", rows.line(), id);
            continue;
        }
        kept.push_back(std::move(row));
    }
    if (rows.error()) return Fail("loot_box_entries: " + *rows.error());
    std::ranges::sort(kept, [](const BoxRow& a, const BoxRow& b) { return a.key != b.key ? a.key < b.key : a.index < b.index; });
    const auto dup = std::ranges::adjacent_find(kept, [](const BoxRow& a, const BoxRow& b) { return a.key == b.key && a.index == b.index; });
    if (dup != kept.end()) return Fail("loot_box_entries: hộp " + dup->key + " có hai dòng index " + std::to_string(dup->index));
    for (const BoxRow& row : kept) {
        if (out.boxes_.empty() || out.boxes_.back().key != row.key) {
            out.boxes_.push_back(LootTables::BoxRange{
                .key = row.key, .begin = static_cast<std::uint32_t>(out.box_items_.size()), .count = 0});
        }
        ++out.boxes_.back().count;
        out.box_items_.push_back(row.pick);
        out.box_weights_.push_back(row.weight);
    }
    return {};
}

std::expected<LootTables, std::string> LootTables::load(const LootSources& sources, const item::Catalog& catalog) {
    LootTables out;
    if (const Loaded packs = LootLoader::read_packs(out, sources.packs, catalog); !packs) return Fail(packs.error());
    if (const Loaded monsters = LootLoader::read_monsters(out, sources.monsters); !monsters) return Fail(monsters.error());
    if (const Loaded gaps = LootLoader::read_gaps(out, sources.level_gaps); !gaps) return Fail(gaps.error());
    if (const Loaded rates = LootLoader::read_rate_items(out, sources.rate_items, catalog); !rates) return Fail(rates.error());
    if (const Loaded boxes = LootLoader::read_boxes(out, sources.boxes, catalog); !boxes) return Fail(boxes.error());
    return out;
}

const MonsterDrop* LootTables::monster(ids::MonsterTemplateId id) const noexcept {
    const auto it = std::ranges::lower_bound(monsters_, id, {}, &MonsterDrop::monster);
    return it != monsters_.end() && it->monster == id ? &*it : nullptr;
}

const Pack* LootTables::pack(PackId id) const noexcept {
    const auto it = std::ranges::lower_bound(packs_, id, {}, &Pack::id);
    return it != packs_.end() && it->id == id ? &*it : nullptr;
}

std::span<const PackEntry> LootTables::entries(const Pack& pack) const noexcept {
    const std::span<const PackEntry> all(pack_entries_);
    if (pack.begin > all.size()) return {};
    return all.subspan(pack.begin).first(std::min<std::size_t>(pack.count, all.size() - pack.begin));
}

std::uint32_t LootTables::gap_ppm(std::int64_t level_delta) const noexcept {
    const auto it = std::ranges::lower_bound(gaps_, level_delta, {}, &std::pair<std::int64_t, std::uint32_t>::first);
    return it != gaps_.end() && it->first == level_delta ? it->second : kPpm;
}

std::optional<Pick> LootTables::pick_rate_item(dice::Dice& dice) const noexcept {
    const std::optional<std::size_t> index = dice.pick_weighted(rate_weights_);
    if (!index || *index >= rate_items_.size()) return std::nullopt;
    return *std::next(rate_items_.begin(), static_cast<std::ptrdiff_t>(*index));
}

bool LootTables::has_box(std::string_view key) const noexcept {
    const auto it = std::ranges::lower_bound(boxes_, key, std::less<>{},
        [](const BoxRange& range) { return std::string_view(range.key); });
    return it != boxes_.end() && it->key == key;
}

std::optional<Pick> LootTables::pick_box(std::string_view key, dice::Dice& dice) const noexcept {
    const auto it = std::ranges::lower_bound(boxes_, key, std::less<>{},
        [](const BoxRange& range) { return std::string_view(range.key); });
    if (it == boxes_.end() || it->key != key) return std::nullopt;
    const std::span<const std::uint32_t> all(box_weights_);
    if (it->begin > all.size() || it->count > all.size() - it->begin) return std::nullopt;
    const std::optional<std::size_t> index = dice.pick_weighted(all.subspan(it->begin, it->count));
    if (!index) return std::nullopt;
    return *std::next(box_items_.begin(), static_cast<std::ptrdiff_t>(it->begin + *index));
}

} // namespace game::loot
