// Bộ đọc năm bảng ngoại hình và các hàm tra (xem appearance.hpp).
// Nguồn: TLBB Dev src/tables/appearance.cpp@e0d89a6 (cột và luật khoá). Khác gốc: đọc bằng
// table::RowReader; giới là Race; khoá faces, hairs là (id, race).
#include "look/appearance.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace game::look {
namespace {

constexpr std::uint32_t kMaxShort = 0xFFFFU;
constexpr std::uint32_t kMaxLong = 0xFFFFFFFFU;

struct ActionName {
    std::string_view name;
    Action action;
};

struct WeaponName {
    std::string_view name;
    Weapon weapon;
};

constexpr std::array<ActionName, 6> kActions{
    {{.name = "idle", .action = Action::kIdle}, {.name = "idle_alt", .action = Action::kIdleAlt},
        {.name = "idle_alt2", .action = Action::kIdleAlt2}, {.name = "run", .action = Action::kRun},
        {.name = "combat_idle", .action = Action::kCombatIdle}, {.name = "combat_run", .action = Action::kCombatRun}}};

constexpr std::array<WeaponName, 7> kWeapons{{{.name = "none", .weapon = Weapon::kNone},
    {.name = "spear", .weapon = Weapon::kSpear}, {.name = "blade", .weapon = Weapon::kBlade},
    {.name = "dual_short", .weapon = Weapon::kDualShort}, {.name = "short", .weapon = Weapon::kShort},
    {.name = "fan", .weapon = Weapon::kFan}, {.name = "ring", .weapon = Weapon::kRing}}};

std::optional<Action> action_of(std::string_view name) {
    const auto found = std::ranges::find(kActions, name, &ActionName::name);
    if (found == kActions.end()) return std::nullopt;
    return found->action;
}

std::optional<Weapon> weapon_of(std::string_view name) {
    const auto found = std::ranges::find(kWeapons, name, &WeaponName::name);
    if (found == kWeapons.end()) return std::nullopt;
    return found->weapon;
}

// Mọi dòng của bảng qua một bộ đọc một dòng; dừng ở dòng sai đầu tiên.
template <typename Row>
Rows<Row> read_all(const table::Tsv& table, Row (*read_row)(table::RowReader&)) {
    std::vector<Row> rows;
    rows.reserve(table.rows.size());
    std::optional<std::string> failure;
    for (std::size_t index = 0; index < table.rows.size() && !failure; ++index) {
        // NOLINTNEXTLINE(misc-const-correctness): giả dương, read_row nhận RowReader& (HP-07)
        table::RowReader reader(table, index);
        rows.push_back(read_row(reader));
        failure = reader.error();
    }
    if (failure) return std::unexpected(*failure);
    return rows;
}

Race race_of(table::RowReader& reader) {
    return static_cast<Race>(reader.number("race", 0, 1));
}

// Tên material cách nhau bằng ";".
std::vector<std::string> split_materials(std::string_view cell) {
    std::vector<std::string> names;
    std::size_t start = 0;
    while (start < cell.size()) {
        const std::size_t stop = cell.find(';', start);
        const std::size_t end = stop == std::string_view::npos ? cell.size() : stop;
        names.emplace_back(cell.substr(start, end - start));
        start = end + 1;
    }
    return names;
}

PlayerBody body_row(table::RowReader& reader) {
    PlayerBody body;
    body.race = race_of(reader);
    body.name = reader.text("name");
    body.template_name = reader.text("template");
    body.skeleton = reader.text("skeleton");
    body.face = static_cast<std::uint16_t>(reader.number("face", 0, kMaxShort));
    body.hair = static_cast<std::uint16_t>(reader.number("hair", 0, kMaxShort));
    body.body = static_cast<std::uint16_t>(reader.number("body", 1, kMaxShort));
    body.arm = static_cast<std::uint16_t>(reader.number("arm", 1, kMaxShort));
    body.foot = static_cast<std::uint16_t>(reader.number("foot", 1, kMaxShort));
    body.anim_set = reader.number("anim_set", 0, kMaxLong);
    body.height = reader.positive("height");
    return body;
}

FaceRow face_row(table::RowReader& reader) {
    FaceRow face;
    face.id = static_cast<std::uint16_t>(reader.number("id", 0, kMaxShort));
    face.race = race_of(reader);
    face.mesh = reader.text("mesh");
    face.is_creatable = reader.flag("creatable");
    return face;
}

HairRow hair_row(table::RowReader& reader) {
    HairRow hair;
    hair.id = static_cast<std::uint16_t>(reader.number("id", 0, kMaxShort));
    hair.race = race_of(reader);
    hair.mesh = reader.text("mesh");
    hair.accessory = reader.text("accessory");
    hair.is_creatable = reader.flag("creatable");
    return hair;
}

OutfitRow outfit_row(table::RowReader& reader) {
    OutfitRow outfit;
    outfit.id = static_cast<std::uint16_t>(reader.number("id", 1, kMaxShort));
    outfit.race = race_of(reader);
    outfit.mesh = reader.text("mesh");
    outfit.materials = split_materials(reader.text("materials"));
    return outfit;
}

// Hành động và loại vũ khí là tên; tên lạ là lỗi của dòng.
AnimRow anim_row(table::RowReader& reader) {
    AnimRow anim;
    anim.set = reader.number("set", 0, kMaxLong);
    const std::string_view action_name = reader.text("action");
    const std::string_view weapon_name = reader.text("weapon");
    const std::optional<Action> action = action_of(action_name);
    const std::optional<Weapon> weapon = weapon_of(weapon_name);
    if (action) anim.action = *action;
    if (weapon) anim.weapon = *weapon;
    if (!action) reader.reject("action", std::format("tên hành động lạ \"{}\"", action_name));
    if (!weapon) reader.reject("weapon", std::format("tên loại vũ khí lạ \"{}\"", weapon_name));
    anim.anim = reader.text("anim");
    anim.clip = reader.text("clip");
    return anim;
}

// Khoá của hàng trước phải nhỏ hơn khoá của hàng sau: bảng không có khoá trùng.
template <typename Row, typename Key>
std::optional<std::string> check_unique(std::span<const Row> rows, Key key, std::string_view name) {
    const auto repeats = [&key](const Row& left, const Row& right) { return key(left) == key(right); };
    const auto found = std::ranges::adjacent_find(rows, repeats);
    if (found == rows.end()) return std::nullopt;
    return std::format("bảng {} có khoá trùng", name);
}

template <typename Row, typename Key>
Rows<Row> sorted_unique(Rows<Row> rows, Key key, std::string_view name) {
    if (!rows) return rows;
    const auto before = [&key](const Row& left, const Row& right) { return key(left) < key(right); };
    std::ranges::sort(*rows, before);
    const std::optional<std::string> repeated = check_unique<Row>(*rows, key, name);
    if (repeated) return std::unexpected(*repeated);
    return rows;
}

template <typename Row>
Rows<Row> not_empty(Rows<Row> rows, std::string_view name) {
    if (rows && rows->empty()) return std::unexpected(std::format("bảng {} không có dòng nào", name));
    return rows;
}

} // namespace

Rows<PlayerBody> read_player_bodies(const table::Tsv& table) {
    auto rows = read_all<PlayerBody>(table, body_row);
    const auto key = [](const PlayerBody& row) { return static_cast<int>(row.race); };
    return not_empty(sorted_unique(std::move(rows), key, "player_bodies"), "player_bodies");
}

Rows<FaceRow> read_faces(const table::Tsv& table) {
    const auto key = [](const FaceRow& row) { return std::pair(row.id, static_cast<int>(row.race)); };
    return sorted_unique(read_all<FaceRow>(table, face_row), key, "faces");
}

Rows<HairRow> read_hairs(const table::Tsv& table) {
    const auto key = [](const HairRow& row) { return std::pair(row.id, static_cast<int>(row.race)); };
    return sorted_unique(read_all<HairRow>(table, hair_row), key, "hairs");
}

Rows<OutfitRow> read_outfits(const table::Tsv& table) {
    const auto key = [](const OutfitRow& row) { return std::pair(row.id, static_cast<int>(row.race)); };
    return sorted_unique(read_all<OutfitRow>(table, outfit_row), key, "outfits");
}

Rows<AnimRow> read_anim_sets(const table::Tsv& table) {
    const auto key = [](const AnimRow& row) {
        return std::tuple(row.set, static_cast<int>(row.action), static_cast<int>(row.weapon));
    };
    auto rows = read_all<AnimRow>(table, anim_row);
    return not_empty(sorted_unique(std::move(rows), key, "anim_sets"), "anim_sets");
}

const PlayerBody* find_body(std::span<const PlayerBody> rows, Race race) {
    const auto found = std::ranges::find(rows, race, &PlayerBody::race);
    return found == rows.end() ? nullptr : &*found;
}

const FaceRow* find_face(std::span<const FaceRow> rows, std::uint16_t id, Race race) {
    const auto matches = [id, race](const FaceRow& row) { return row.id == id && row.race == race; };
    const auto found = std::ranges::find_if(rows, matches);
    return found == rows.end() ? nullptr : &*found;
}

const HairRow* find_hair(std::span<const HairRow> rows, std::uint16_t id, Race race) {
    const auto matches = [id, race](const HairRow& row) { return row.id == id && row.race == race; };
    const auto found = std::ranges::find_if(rows, matches);
    return found == rows.end() ? nullptr : &*found;
}

const OutfitRow* find_outfit(std::span<const OutfitRow> rows, std::uint16_t id, Race race) {
    const auto matches = [id, race](const OutfitRow& row) { return row.id == id && row.race == race; };
    const auto found = std::ranges::find_if(rows, matches);
    return found == rows.end() ? nullptr : &*found;
}

const AnimRow* find_anim(std::span<const AnimRow> rows, std::uint32_t set, Action action, Weapon weapon) {
    const auto matches = [=](const AnimRow& row) {
        return row.set == set && row.action == action && row.weapon == weapon;
    };
    const auto found = std::ranges::find_if(rows, matches);
    return found == rows.end() ? nullptr : &*found;
}

} // namespace game::look
