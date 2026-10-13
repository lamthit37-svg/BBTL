// Bản đồ thế giới của LargeMap (xem world_map.hpp).
#include "ui/panel/world_map.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/scene_table.hpp"

#include <algorithm>
#include <array>
#include <format>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

// Các cảnh phó bản: bấm vào thì widget không phát NormalSceneClicked (isCopyScene, 0x18008d900).
constexpr std::array<int, 8> kCopyScenes{0x24, 0x25, 0x26, 0x3D, 0x42, 0xA8, 0xEA, 0x118};

// Loại nút mà ảnh nhãn gốc đỏ (đo trung bình R - G của ảnh "khi trỏ" trong tga_MiniMap_Icon2: 129..165, các loại khác 0):
// phó bản và nơi đặc biệt. Còn lại nhãn đen.
constexpr std::array<std::string_view, 8> kRedSigns{
    "Sign13", "Sign14", "Sign15", "Sign16", "Sign17", "Sign18", "Sign55", "Sign66"};

[[nodiscard]] bool is_inside(const gui::Box& box, float across, float down) noexcept {
    return across >= box.x && across < box.x + box.w && down >= box.y && down < box.y + box.h;
}

// updataBackground: ảnh to hơn cửa sổ thì độ lệch nằm trong [cửa sổ - ảnh, 0]; nhỏ hơn thì ở giữa.
[[nodiscard]] float clamp_axis(float offset, float window, float whole) noexcept {
    if (whole <= window) return (window - whole) * 0.5F;
    return std::clamp(offset, window - whole, 0.0F);
}

// Kéo bằng nút phải bắt đầu trong cửa sổ (onDrapStart) và đi theo chuột tới khi nhả (onDrapMove):
// độ lệch mới = độ lệch lúc bắt đầu + độ dời của chuột.
void drag_by_pointer(WorldBoard& board, const WorldStep& step) {
    const bool is_held = step.pointer && step.pointer->is_right_down;
    if (!is_held) {
        board.is_dragging = false;
        return;
    }
    if (!board.is_dragging) {
        if (!is_inside(step.window, step.pointer->x, step.pointer->y)) return;
        board.is_dragging = true;
        board.drag_x = step.pointer->x;
        board.drag_y = step.pointer->y;
        board.drag_from_x = board.x;
        board.drag_from_y = board.y;
    }
    board.x = board.drag_from_x + (step.pointer->x - board.drag_x);
    board.y = board.drag_from_y + (step.pointer->y - board.drag_y);
}

} // namespace

gui::Box world_image_box() noexcept {
    return gui::Box{.x = 0.0F, .y = 0.0F, .w = kWorldTile * kWorldColumns, .h = kWorldTile * kWorldRows};
}

std::string world_cities(const SceneTable& table, const gui::StringBook& names) {
    std::string lines;
    for (const SceneRow& row : table.rows()) {
        if (row.world != kNormalWorld || row.icon_x == 0 || row.icon_y == 0) continue;
        // Nhãn dùng ảnh "khi trỏ" của bảng: resetWorldMap và SetCityHover đặt ảnh ở +0x120, mà
        // setCityNameHoverImage ghi vào đó; ảnh "thường" (+0x128) không còn chỗ nào đọc.
        const std::string_view title = names.find(row.name).value_or(std::string_view{});
        const bool is_red = std::ranges::find(kRedSigns, row.sign) != kRedSigns.end();
        lines += std::format("{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\n", row.id, row.icon_x, row.icon_y, row.label_x,
            row.label_y, row.sign, row.hover_set, row.icon_hover, title, is_red ? "red" : "");
    }
    return lines;
}

bool is_copy_scene(int city) noexcept {
    return std::ranges::find(kCopyScenes, city) != kCopyScenes.end();
}

int city_under(std::span<const gui::WorldHit> hits, float across, float down) noexcept {
    for (const gui::WorldHit& hit : hits | std::views::reverse) {
        if (is_inside(hit.box, across, down)) return hit.city;
    }
    return -1;
}

void step_world(WorldBoard& board, const WorldStep& step) {
    drag_by_pointer(board, step);
    const gui::Box whole = world_image_box();
    board.x = clamp_axis(board.x, step.window.w, whole.w);
    board.y = clamp_axis(board.y, step.window.h, whole.h);
    const bool is_pointing = step.pointer.has_value() && !board.is_dragging;
    board.hover = is_pointing ? city_under(step.hits, step.pointer->x, step.pointer->y) : -1;
}

void paint_world(Deck& deck, const WorldBoard& board, std::string_view cities, int here) {
    const gui::Box whole = world_image_box();
    const auto put = [&deck](std::string_view name, const std::string& value) {
        deck.set(gui::Override{.window = kWorldWindow, .name = name, .value = value});
    };
    put("WorldMapSize", std::format("{} {}", whole.w, whole.h));
    put("WorldMapView", std::format("{} {}", board.x, board.y));
    put("WorldMapCities", std::string(cities));
    put("WorldMapSelf", std::to_string(here));
    put("WorldMapHover", std::to_string(board.hover));
}

} // namespace game::ui::panel
