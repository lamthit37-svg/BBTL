// Người mẫu xem trước môn phái (xem sect.hpp).
#include "look/sect.hpp"

#include "look/appearance.hpp"
#include "look/look.hpp"
#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>

namespace game::look {
namespace {

constexpr char kMeshMark = '|';

[[nodiscard]] Figure figure_of(table::RowReader& reader) {
    Figure figure;
    figure.template_name = reader.text("template");
    figure.skeleton = reader.text("skeleton");
    figure.idle = Clip{.anim = figure.skeleton, .name = std::string(reader.text("idle"))};
    figure.run = figure.idle;
    figure.idle_alt = Clip{.anim = figure.skeleton, .name = std::string(reader.text("demo"))};
    figure.idle_alt2 = figure.idle_alt;
    for (const auto mesh : reader.text("meshes") | std::views::split(kMeshMark)) {
        const std::string_view name(mesh.begin(), mesh.end());
        if (name.empty()) continue;
        Part part;
        part.mesh = name;
        figure.parts.push_back(std::move(part));
    }
    if (figure.skeleton.empty() || figure.idle.name.empty() || figure.idle_alt->name.empty() || figure.parts.empty()) {
        reader.reject("meshes", "dòng thiếu skeleton, animation hay lưới");
    }
    return figure;
}

// Locator của mẫu nhân vật giữ khe: xương, vị trí lệch, trục và góc radian như locators.tsv.
[[nodiscard]] LocatorRow slot_locator(table::RowReader& reader) {
    LocatorRow locator;
    locator.bone = reader.text("bone");
    locator.offset = {reader.real("x"), reader.real("y"), reader.real("z")};
    locator.axis = {reader.real("qx"), reader.real("qy"), reader.real("qz")};
    locator.angle = reader.real("qw");
    locator.is_translate_first = reader.flag("translate_first");
    return locator;
}

[[nodiscard]] Held held_of(table::RowReader& reader) {
    Held held;
    held.object = reader.text("object");
    held.locator = slot_locator(reader);
    for (const auto mesh : reader.text("meshes") | std::views::split(kMeshMark)) {
        const std::string_view name(mesh.begin(), mesh.end());
        if (!name.empty()) held.meshes.emplace_back(name);
    }
    if (held.meshes.empty()) reader.reject("meshes", "dòng không có lưới");
    return held;
}

// Khoá (race, sect) của dòng cần tìm; race theo cột: 0 nữ, 1 nam.
struct Key {
    std::uint32_t race = 0;
    std::uint8_t sect = 0;
};

[[nodiscard]] Key key_of(Race race, std::uint8_t sect) noexcept {
    const std::uint32_t code = race == Race::kFemale ? 0 : 1;
    return Key{.race = code, .sect = sect};
}

// Dòng thuộc khoá đã hỏi; ô race hay sect ngoài miền thì reader ghi lỗi.
[[nodiscard]] bool is_row_of(table::RowReader& reader, const Key& key) {
    const bool is_race = reader.number("race", 0, 1) == key.race;
    return is_race && reader.number("sect", 0, kSectCount - 1U) == key.sect;
}

[[nodiscard]] std::string bad_sect(std::uint8_t sect) {
    return std::format("môn {} ngoài 0..{}", sect, kSectCount - 1);
}

[[nodiscard]] std::string bad_table(std::string_view name, std::string_view why) {
    return std::format("bảng {} sai, {}", name, why);
}

} // namespace

std::expected<SectFigure, std::string> sect_figure(std::string_view text, Race race,
    std::uint8_t sect) {
    if (sect >= kSectCount) return std::unexpected(bad_sect(sect));
    const table::TsvResult table = table::parse_tsv(text);
    if (!table) return std::unexpected(bad_table("sect_models", table.error()));
    const Key key = key_of(race, sect);
    for (std::size_t row = 0; row < table->rows.size(); ++row) {
        table::RowReader reader(*table, row);
        const bool is_wanted = is_row_of(reader, key);
        if (!is_wanted && !reader.error()) continue;
        SectFigure found;
        found.figure = figure_of(reader);
        found.has_fidget = reader.flag("fidget");
        if (reader.error()) return std::unexpected(bad_table("sect_models", *reader.error()));
        return found;
    }
    const std::string none = std::format("không có môn {} của giới {}", sect, key.race);
    return std::unexpected(bad_table("sect_models", none));
}

std::expected<std::optional<Held>, std::string> sect_held(std::string_view text, Race race,
    std::uint8_t sect) {
    if (sect >= kSectCount) return std::unexpected(bad_sect(sect));
    const table::TsvResult table = table::parse_tsv(text);
    if (!table) return std::unexpected(bad_table("sect_held", table.error()));
    const Key key = key_of(race, sect);
    for (std::size_t row = 0; row < table->rows.size(); ++row) {
        table::RowReader reader(*table, row);
        const bool is_wanted = is_row_of(reader, key);
        if (!is_wanted && !reader.error()) continue;
        Held found = held_of(reader);
        if (reader.error()) return std::unexpected(bad_table("sect_held", *reader.error()));
        return found;
    }
    return std::nullopt;
}

} // namespace game::look
