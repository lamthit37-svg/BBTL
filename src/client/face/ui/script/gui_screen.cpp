#include "ui/script/gui_screen.hpp"

#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "ui/script/host.hpp"

#include <algorithm>
#include <cctype>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

// Đường dẫn layout so không phân biệt hoa thường ASCII, như kho Interface của client gốc (GuiLoader cũng khoá theo chữ thường).
bool same_path(std::string_view left, std::string_view right) noexcept {
    const auto lower = [](char code) { return static_cast<char>(std::tolower(static_cast<unsigned char>(code))); };
    return std::ranges::equal(left, right, {}, lower, lower);
}

std::optional<gui::GuiRange> find_layout(const gui::GuiAsset& asset, std::string_view layout) {
    const auto found = std::ranges::find_if(asset.layouts, [layout](const gui::GuiLayout& one) { return same_path(one.file, layout); });
    if (found == asset.layouts.end()) return std::nullopt;
    return found->windows;
}

} // namespace

bool GuiScreen::take_grown() noexcept {
    return std::exchange(is_grown_, false);
}

std::expected<gui::GuiRange, std::string> GuiScreen::load_layout(std::string_view layout) {
    if (const std::optional<gui::GuiRange> known = find_layout(loader_->asset(), layout)) return *known;
    const auto added = loader_->add_layout(layout);
    if (!added) return std::unexpected(added.error());
    is_grown_ = true;
    if (const std::optional<gui::GuiRange> now = find_layout(loader_->asset(), layout)) return *now;
    return std::unexpected(std::format("không thấy layout {} sau khi nạp", layout));
}

// Vị trí so với cửa sổ gốc = toạ độ màn hình của hai ô trừ nhau. Hub giữ ô theo lần dàn trang gần nhất và chỉ có ô của cửa
// sổ đang hiện; cửa sổ ẩn hay chưa dàn trang thì không biết.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký của Screen::offset, hai vai đã nêu tên ở đó.
std::optional<Spot> GuiScreen::offset(std::string_view window, std::string_view root) const {
    if (hub_ == nullptr) return std::nullopt;
    const std::optional<gui::Box> inner = hub_->box(window);
    const std::optional<gui::Box> outer = hub_->box(root);
    if (!inner || !outer) return std::nullopt;
    return Spot{.x = inner->x - outer->x, .y = inner->y - outer->y};
}

bool GuiScreen::hits(std::string_view window, Spot spot) const {
    if (hub_ == nullptr) return false;
    const std::optional<gui::Box> box = hub_->box(window);
    return box && spot.x >= box->x && spot.x < box->x + box->w && spot.y >= box->y && spot.y < box->y + box->h;
}

} // namespace game::ui::script
