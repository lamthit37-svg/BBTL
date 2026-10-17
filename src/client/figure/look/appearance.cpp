// Bộ đọc năm bảng ngoại hình và các hàm tra (xem appearance.hpp).
// Nguồn: TLBB Dev src/tables/appearance.cpp@e0d89a6 (cột và luật khoá). Khác gốc: đọc bằng
// table::RowReader; giới là Race; khoá faces, hairs là (id, race).
#include "look/appearance.hpp"

#include "look/detail/rows.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
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

using detail::not_empty;
using detail::read_all;
using detail::sorted_unique;

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

constexpr std::array<ActionName, 8> kActions{
    {{.name = "idle", .action = Action::kIdle}, {.name = "idle_alt", .action = Action::kIdleAlt},
        {.name = "idle_alt2", .action = Action::kIdleAlt2}, {.name = "run", .action = Action::kRun},
        {.name = "jump_stand", .action = Action::kJumpStand}, {.name = "jump_run", .action = Action::kJumpRun},
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

RacedAnimRow raced_anim_row(table::RowReader& reader) {
    RacedAnimRow row;
    row.race = race_of(reader);
    row.anim = anim_row(reader);
    return row;
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

Rows<RacedAnimRow> read_raced_anims(const table::Tsv& table) {
    const auto key = [](const RacedAnimRow& row) {
        const AnimRow& anim = row.anim;
        const int action = static_cast<int>(anim.action);
        const int weapon = static_cast<int>(anim.weapon);
        return std::tuple(static_cast<int>(row.race), anim.set, action, weapon);
    };
    auto rows = read_all<RacedAnimRow>(table, raced_anim_row);
    return not_empty(sorted_unique(std::move(rows), key, "raced_anims"), "raced_anims");
}

std::optional<Weapon> weapon_named(std::string_view name) {
    return weapon_of(name);
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

const AnimRow* find_raced_anim(std::span<const RacedAnimRow> rows, Race race, std::uint32_t set,
    Action action, Weapon weapon) {
    const auto matches = [=](const RacedAnimRow& row) {
        const AnimRow& anim = row.anim;
        const bool is_cell = anim.set == set && anim.action == action && anim.weapon == weapon;
        return row.race == race && is_cell;
    };
    const auto found = std::ranges::find_if(rows, matches);
    return found == rows.end() ? nullptr : &found->anim;
}

} // namespace game::look
