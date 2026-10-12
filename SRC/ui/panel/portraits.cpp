#include "ui/panel/portraits.hpp"

#include "core/number.hpp"
#include "gui/value.hpp"
#include "hero/hero.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <functional>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

// Chỉ số hai cột bảng cần: id và image.
struct Columns {
    std::size_t id = 0;
    std::size_t image = 0;
};

// Phần đang dựng của bảng.
struct Draft {
    std::vector<Portrait> rows;
    std::vector<std::string> imagesets;
};

std::optional<Columns> columns_of(const table::Tsv& table) {
    const auto id = table::column_of(table, "id");
    const auto image = table::column_of(table, "image");
    if (!id || !image) return std::nullopt;
    return Columns{.id = *id, .image = *image};
}

// Thêm một dòng của tệp vào bản nháp; dòng hỏng thì bỏ.
void take_row(Draft& draft, const Columns& columns, const std::vector<std::string>& cells) {
    const std::optional<int> id = core::parse_whole_int(cells.at(columns.id));
    const std::string& image = cells.at(columns.image);
    const std::optional<gui::ImageName> parsed = gui::parse_image(image);
    if (!id || !parsed) return;
    draft.rows.push_back(Portrait{.id = hero::PortraitId{*id}, .image = image});
    if (std::ranges::contains(draft.imagesets, parsed->set)) return;
    draft.imagesets.emplace_back(parsed->set);
}

} // namespace

Portraits Portraits::from_table(const table::Tsv& table) {
    Portraits portraits;
    const std::optional<Columns> columns = columns_of(table);
    if (!columns) return portraits;
    Draft draft;
    for (const std::vector<std::string>& cells : table.rows)
        take_row(draft, *columns, cells);
    // Xếp ổn định rồi bỏ id lặp: dòng gặp trước đứng đầu nhóm nên được giữ.
    std::ranges::stable_sort(draft.rows, std::less<>{}, &Portrait::id);
    const auto tail = std::ranges::unique(draft.rows, std::equal_to<>{}, &Portrait::id);
    draft.rows.erase(tail.begin(), tail.end());
    portraits.rows_ = std::move(draft.rows);
    portraits.imagesets_ = std::move(draft.imagesets);
    return portraits;
}

std::string_view Portraits::image_of(hero::PortraitId id) const noexcept {
    const auto found = std::ranges::lower_bound(rows_, id, std::less<>{}, &Portrait::id);
    if (found == rows_.end() || found->id != id) return {};
    return found->image;
}

} // namespace game::ui::panel
