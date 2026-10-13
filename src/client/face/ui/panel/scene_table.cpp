// Bảng cảnh của các bảng bản đồ (xem scene_table.hpp).
#include "ui/panel/scene_table.hpp"

#include "core/number.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr std::size_t kColumns = 25;
// Số dòng tối đa nhận: bảng gốc có 680 dòng; trần để tệp hỏng không ăn hết bộ nhớ.
constexpr std::size_t kMaxRows = 4096;

// Chỉ số cột của bảng.
constexpr std::size_t kId = 0;
constexpr std::size_t kName = 1;
constexpr std::size_t kWidth = 2;
constexpr std::size_t kDepth = 3;
constexpr std::size_t kToken = 10;
constexpr std::size_t kIconX = 11;
constexpr std::size_t kIconY = 12;
constexpr std::size_t kLabelX = 13;
constexpr std::size_t kLabelY = 14;
constexpr std::size_t kSign = 17;
constexpr std::size_t kIconSet = 18;
constexpr std::size_t kIconNormal = 19;
constexpr std::size_t kHoverSet = 20;
constexpr std::size_t kIconHover = 21;
constexpr std::size_t kWorld = 24;

using Cells = std::array<std::string_view, kColumns>;

// Tách một dòng thành đủ kColumns ô; thiếu ô thì dòng hỏng.
[[nodiscard]] std::optional<Cells> split_cells(std::string_view line) {
    Cells cells;
    std::size_t index = 0;
    while (index < kColumns) {
        const std::size_t tab = line.find('\t');
        cells.at(index++) = line.substr(0, tab);
        if (tab == std::string_view::npos) break;
        line.remove_prefix(tab + 1);
    }
    if (index < kColumns) return std::nullopt;
    return cells;
}

[[nodiscard]] std::optional<SceneRow> row_of(std::string_view line) {
    const std::optional<Cells> cells = split_cells(line);
    if (!cells) return std::nullopt;
    const std::optional<int> id = core::parse_whole_int(cells->at(kId));
    const std::optional<int> width = core::parse_whole_int(cells->at(kWidth));
    const std::optional<int> depth = core::parse_whole_int(cells->at(kDepth));
    if (!id || !width || !depth) return std::nullopt;
    SceneRow row;
    row.id = *id;
    row.name = std::string(cells->at(kName));
    row.width = static_cast<float>(*width);
    row.depth = static_cast<float>(*depth);
    row.token = std::string(cells->at(kToken));
    row.icon_x = core::parse_whole_int(cells->at(kIconX)).value_or(0);
    row.icon_y = core::parse_whole_int(cells->at(kIconY)).value_or(0);
    row.label_x = core::parse_whole_int(cells->at(kLabelX)).value_or(0);
    row.label_y = core::parse_whole_int(cells->at(kLabelY)).value_or(0);
    row.sign = std::string(cells->at(kSign));
    row.icon_set = std::string(cells->at(kIconSet));
    row.icon_normal = std::string(cells->at(kIconNormal));
    row.hover_set = std::string(cells->at(kHoverSet));
    row.icon_hover = std::string(cells->at(kIconHover));
    row.world = core::parse_whole_int(cells->at(kWorld)).value_or(0);
    return row;
}

} // namespace

SceneTable SceneTable::from_text(std::string_view text) {
    SceneTable table;
    while (!text.empty() && table.rows_.size() < kMaxRows) {
        const std::size_t end = text.find('\n');
        std::string_view line = text.substr(0, end);
        text.remove_prefix(end == std::string_view::npos ? text.size() : end + 1);
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty()) continue;
        if (std::optional<SceneRow> row = row_of(line)) table.rows_.push_back(std::move(*row));
    }
    return table;
}

const SceneRow* SceneTable::find(int id) const noexcept {
    const auto found = std::ranges::find(rows_, id, &SceneRow::id);
    return found == rows_.end() ? nullptr : &*found;
}

} // namespace game::ui::panel
