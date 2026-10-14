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

} // namespace

std::expected<SectFigure, std::string> sect_figure(std::string_view text, Race race, std::uint8_t sect) {
    if (sect >= kSectCount) return std::unexpected(std::format("môn {} ngoài 0..{}", sect, kSectCount - 1));
    const table::TsvResult table = table::parse_tsv(text);
    if (!table) return std::unexpected(std::format("bảng sect_models sai, {}", table.error()));
    const std::uint32_t wanted = race == Race::kFemale ? 0 : 1;
    for (std::size_t row = 0; row < table->rows.size(); ++row) {
        table::RowReader reader(*table, row);
        const bool is_wanted =
            reader.number("race", 0, 1) == wanted && reader.number("sect", 0, kSectCount - 1U) == sect;
        if (!is_wanted && !reader.error()) continue;
        SectFigure found;
        found.figure = figure_of(reader);
        found.has_fidget = reader.flag("fidget");
        if (reader.error()) return std::unexpected(std::format("bảng sect_models sai, {}", *reader.error()));
        return found;
    }
    return std::unexpected(std::format("bảng sect_models không có môn {} của giới {}", sect, wanted));
}

} // namespace game::look
