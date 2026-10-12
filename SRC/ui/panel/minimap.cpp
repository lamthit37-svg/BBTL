#include "ui/panel/minimap.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <span>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

// Thẻ màu của tên cảnh và của toạ độ trong script gốc.
constexpr std::string_view kTitleTint = "#gFF0FA0";
constexpr std::string_view kPlaceTint = "#cFDFF73";
// Tên ngắn hơn chừng này byte thì dùng phông lớn, không thì phông bitmap gọn hơn.
constexpr std::size_t kShortTitle = 10;
// Toạ độ ngoài khoảng này (hay không phải số) thì hiện 0: không ép kiểu một số thực vô nghĩa.
constexpr float kCoordinateLimit = 1.0e6F;

constexpr Key kTitleText{.window = "MiniMap_Placename", .name = "Text"};
constexpr Key kPlaceText{.window = "MiniMap_Coordinate", .name = "Text"};
constexpr Key kWatchImage{.window = "MiniMap_ChineseTime", .name = "SetCurrentImage"};

constexpr std::array<std::string_view, kWatches> kDots = {
    "MiniMap_TimeDot1",
    "MiniMap_TimeDot2",
    "MiniMap_TimeDot3",
    "MiniMap_TimeDot4",
    "MiniMap_TimeDot5",
    "MiniMap_TimeDot6",
    "MiniMap_TimeDot7",
    "MiniMap_TimeDot8",
    "MiniMap_TimeDot9",
    "MiniMap_TimeDot10",
    "MiniMap_TimeDot11",
    "MiniMap_TimeDot12",
};

void fill_title(Deck& deck, std::string_view title) {
    if (title.empty()) return;
    const std::string_view font = title.size() < kShortTitle ? "YouYuan9.75" : "SongTiBmp12";
    const gui::Override chosen{.window = "MiniMap_Placename", .name = "Font", .value = font};
    deck.set(chosen);
    std::string& text = deck.compose(kTitleText);
    text.append(kTitleTint).append(title);
}

// Phần nguyên của toạ độ, như GetMouseScenePos trả số nguyên.
int whole(float value) noexcept {
    if (!(std::abs(value) < kCoordinateLimit)) return 0;
    return static_cast<int>(value);
}

void fill_place(Deck& deck, const MapSeen& seen) {
    std::string& text = deck.compose(kPlaceText);
    const int across = whole(seen.player_x);
    const int down = whole(seen.player_z);
    std::format_to(std::back_inserter(text), "{}{}  {}", kPlaceTint, across, down);
}

// Đồng hồ: ảnh chữ của canh giờ và đúng một chấm sáng ở vị trí của nó.
void fill_watch(Deck& deck, std::uint8_t watch) {
    const std::size_t now = std::min<std::size_t>(watch, kWatches - 1U);
    std::string& image = deck.compose(kWatchImage);
    std::format_to(std::back_inserter(image), "Time{}", now + 1U);
    const std::span<const std::string_view> dots(kDots);
    for (const std::string_view dot : dots.first(now))
        deck.hide(dot);
    for (const std::string_view dot : dots.subspan(now + 1U))
        deck.hide(dot);
}

} // namespace

PlaceText coordinate_of(const Hover& hover) noexcept {
    PlaceText shown;
    shown.held_x = hover.held_x;
    shown.held_z = hover.held_z;
    if (!hover.is_inside) {
        shown.across = hover.player_x;
        shown.down = hover.player_z;
        return shown;
    }
    shown.is_inside = true;
    if (hover.is_on_scene) {
        shown.across = hover.scene_x;
        shown.down = hover.scene_z;
        shown.held_x = hover.scene_x;
        shown.held_z = hover.scene_z;
        return shown;
    }
    if (!hover.was_inside) {
        shown.held_x = 0.0F;
        shown.held_z = 0.0F;
    }
    shown.across = shown.held_x;
    shown.down = shown.held_z;
    return shown;
}

void fill_minimap(Deck& deck, const MapSeen& seen) {
    fill_title(deck, seen.title);
    fill_place(deck, seen);
    fill_watch(deck, seen.watch);
}

} // namespace game::ui::panel
