// Bản đồ lớn của cảnh (xem scene_board.hpp).
#include "ui/panel/scene_board.hpp"

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/scene_table.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <format>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

// Cảnh từ cỡ này trở lên mới có chế độ 1 (SceneMap_Show, SceneMap_ZoomMode).
constexpr float kFullScene = 512.0F;
constexpr std::int32_t kMostMode = 2;
constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";

[[nodiscard]] bool is_small(const SceneRow& scene) noexcept {
    return scene.width < kFullScene || scene.depth < kFullScene;
}

// Đổi một khoảng cuộn (phần của cửa sổ) ra đơn vị cảnh theo điểm ảnh một đơn vị.
[[nodiscard]] float scene_units(float pixels, float per_unit) noexcept {
    return per_unit > 0.0F ? pixels / per_unit : 0.0F;
}

void scroll_by_buttons(SceneBoard& board, float pixels_per_unit, const BoardStep& step) {
    if (board.scroll == Scroll::kNone) return;
    const float move = kScrollStep * step.seconds * kScrollRate;
    const float across = scene_units(move * step.window.w, pixels_per_unit);
    const float down = scene_units(move * step.window.h, pixels_per_unit);
    if (board.scroll == Scroll::kUp) board.centre_z -= down;
    if (board.scroll == Scroll::kDown) board.centre_z += down;
    if (board.scroll == Scroll::kLeft) board.centre_x -= across;
    if (board.scroll == Scroll::kRight) board.centre_x += across;
    board.rest = kRestSeconds;
}

[[nodiscard]] bool is_inside(const gui::Box& box, const gui::Pointer& pointer) noexcept {
    return pointer.x >= box.x && pointer.x < box.x + box.w && pointer.y >= box.y && pointer.y < box.y + box.h;
}

// Kéo bằng nút phải: bản đồ đi theo chuột; thả thì bắt đầu đếm chờ.
void drag_by_pointer(SceneBoard& board, float pixels_per_unit, const BoardStep& step) {
    const bool is_held = step.pointer && step.pointer->is_right_down;
    if (!is_held) {
        board.is_dragging = false;
        return;
    }
    if (!board.is_dragging) {
        if (!is_inside(step.window, *step.pointer)) return;
        board.is_dragging = true;
        board.drag_x = step.pointer->x;
        board.drag_y = step.pointer->y;
        board.drag_centre_x = board.centre_x;
        board.drag_centre_z = board.centre_z;
    }
    board.centre_x = board.drag_centre_x - scene_units(step.pointer->x - board.drag_x, pixels_per_unit);
    board.centre_z = board.drag_centre_z - scene_units(step.pointer->y - board.drag_y, pixels_per_unit);
    board.rest = kRestSeconds;
}

// Người chơi vừa đi thì tâm theo họ, trừ lúc đang cuộn, kéo hay còn chờ (UpdateViewRect).
void follow_player(SceneBoard& board, const BoardStep& step) {
    const bool is_busy = board.is_dragging || board.scroll != Scroll::kNone;
    const bool is_moved = step.player.x != board.last_player.x || step.player.z != board.last_player.z;
    if (!is_busy && board.rest > 0.0F) board.rest = std::max(board.rest - step.seconds, 0.0F);
    if (board.is_here && is_moved && !is_busy && board.rest <= 0.0F) {
        board.centre_x = step.player.x;
        board.centre_z = step.player.z;
    }
    board.last_player = step.player;
}

} // namespace

void open_board(SceneBoard& board, const SceneRow& scene, Where player, bool is_here) {
    if (board.mode == 1 && is_small(scene)) board.mode = kMostMode;
    board.mode = std::min(board.mode, kMostMode);
    board.is_here = is_here;
    board.centre_x = is_here ? player.x : scene.width * 0.5F;
    board.centre_z = is_here ? player.z : scene.depth * 0.5F;
    board.last_player = player;
    board.rest = 0.0F;
    board.scroll = Scroll::kNone;
    board.is_dragging = false;
}

void zoom_board(SceneBoard& board, bool in, const SceneRow& scene) {
    std::int32_t mode = board.mode;
    if (in) {
        if (mode >= kMostMode) return;
        ++mode;
        if (is_small(scene) && mode == 1) mode = kMostMode;
    } else {
        if (mode <= 0) return;
        --mode;
        if (is_small(scene) && mode == 1) mode = 0;
    }
    board.mode = mode;
}

void press_board(SceneBoard& board, std::string_view window, const SceneRow& scene) {
    if (window == kScrollUp) board.scroll = Scroll::kUp;
    if (window == kScrollDown) board.scroll = Scroll::kDown;
    if (window == kScrollLeft) board.scroll = Scroll::kLeft;
    if (window == kScrollRight) board.scroll = Scroll::kRight;
    if (window == kZoomOut) zoom_board(board, false, scene);
    if (window == kZoomIn) zoom_board(board, true, scene);
}

void release_board(SceneBoard& board) noexcept {
    board.scroll = Scroll::kNone;
}

gui::BoardAsk board_ask(const SceneBoard& board, const SceneRow& scene, gui::Box window) noexcept {
    gui::BoardAsk ask;
    ask.scene_width = scene.width;
    ask.scene_depth = scene.depth;
    ask.window_width = window.w;
    ask.window_height = window.h;
    ask.mode = board.mode;
    ask.centre_x = board.centre_x;
    ask.centre_z = board.centre_z;
    return ask;
}

void step_board(SceneBoard& board, const SceneRow& scene, const BoardStep& step) {
    const gui::BoardView before = gui::board_view(board_ask(board, scene, step.window));
    scroll_by_buttons(board, before.pixels, step);
    drag_by_pointer(board, before.pixels, step);
    follow_player(board, step);
    const gui::BoardAsk ask = board_ask(board, scene, step.window);
    const gui::BoardView view = gui::board_view(ask);
    if (view.pixels > 0.0F) {
        board.centre_x = view.centre_x;
        board.centre_z = view.centre_z;
    }
    if (!step.pointer) return;
    const gui::SceneCursor cursor{.local_x = step.pointer->x - step.window.x, .local_y = step.pointer->y - step.window.y};
    const gui::SceneHit hit = gui::board_scene_at(ask, view, cursor);
    if (!hit.is_on_scene) return;
    board.coord_x = hit.x;
    board.coord_z = hit.z;
}

void paint_board(Deck& deck, const SceneBoard& board, const SceneRow& scene) {
    const auto put = [&deck](std::string_view name, const std::string& value) {
        deck.set(gui::Override{.window = kBoardWindow, .name = name, .value = value});
    };
    put("SceneMapZoom", std::to_string(board.mode));
    put("SceneMapSize", std::format("{} {}", scene.width, scene.depth));
    put("SceneMapCenter", std::format("{} {}", board.centre_x, board.centre_z));
    deck.set(gui::Override{.window = kBoardWindow, .name = "SceneMapSelf", .value = board.is_here ? kTrue : kFalse});
    // SceneMap_UpdateInfo: toạ độ viết thành số nguyên cách nhau bốn dấu cách.
    const std::string place = std::format("{}    {}", static_cast<int>(std::floor(board.coord_x)), static_cast<int>(std::floor(board.coord_z)));
    deck.set(gui::Override{.window = "SceneMap_Crood", .name = "Text", .value = place});
}

} // namespace game::ui::panel
