// Phép toán của radar và thanh: vùng ảnh cảnh đang thấy (FalagardSceneMap), quạt tròn của
// LookLikeRound (OgreCEGUIRenderer::doRender) và làm mượt thanh (FalagardSuperProgress).
// Nguồn: TLBB Dev src/gui/sheet.cpp@e0d89a6 (axis_uv, radar_uv, radar_tiles, radar_grid_exact,
// bar_step, round_fan, radar_tile_path). Khác gốc: tham số gom thành struct theo luật năm tham số;
// ô minimap mang tên tệp gốc của kho Scene (jpg_<token>_<cột>_<hàng>, đã đổi sang PNG) thay cho
// tên .ttex đã nấu; thêm arrow_frame (bản Dev không có mũi tên người chơi).
#include "gui/sheet.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <format>
#include <numbers>
#include <span>
#include <string>
#include <string_view>

namespace game::gui {
namespace {

constexpr float kRadarZoom = 4.0F;
constexpr float kCos22 = 0.92387953251128675612818318939679F;
constexpr float kSin22 = 0.3826834323650897717284599840304F;
constexpr float kSin45 = 0.70710678118654752440084436210485F;
constexpr float kHuge = 16777216.0F;
constexpr std::size_t kRimPairs = 16;
constexpr float kTurn = 2.0F * std::numbers::pi_v<float>;
constexpr float kDegreesPerRadian = 180.0F / std::numbers::pi_v<float>;
constexpr int kTurnDegrees = 360;

// Hệ số mx, my của 17 mốc vành, đúng thứ tự face1..face16 trong OgreCEGUIRenderer::doRender.
constexpr std::array<float, 34> kRim = {1.0F, 0.0F, kCos22, kSin22, kSin45, kSin45, kSin22, kCos22, 0.0F, 1.0F, -kSin22,
    kCos22, -kSin45, kSin45, -kCos22, kSin22, -1.0F, 0.0F, -kCos22, -kSin22, -kSin45, -kSin45, -kSin22, -kCos22, 0.0F,
    -1.0F, kSin22, -kCos22, kSin45, -kSin45, kCos22, -kSin22, 1.0F, 0.0F};

// Tâm và bán kính của quạt trong hệ toạ độ màn hình và hệ toạ độ ảnh.
struct FanCircle {
    float cx = 0.0F;
    float cy = 0.0F;
    float rx = 0.0F;
    float ry = 0.0F;
    float cu = 0.0F;
    float cv = 0.0F;
    float ru = 0.0F;
    float rv = 0.0F;
};

// Hệ số của một mốc vành.
struct RimStep {
    float mx = 0.0F;
    float my = 0.0F;
};

FanCircle circle_of(const FanView& view) noexcept {
    const float left = view.dest.x;
    const float right = view.dest.x + view.dest.w;
    const float top = view.dest.y;
    const float bottom = view.dest.y + view.dest.h;
    FanCircle circle;
    circle.rx = (right - left) * 0.5F;
    circle.ry = (top - bottom) * 0.5F;
    circle.cx = circle.rx + left;
    circle.cy = circle.ry + bottom;
    circle.ru = (view.u1 - view.u0) * 0.5F;
    circle.rv = (view.v1 - view.v0) * 0.5F;
    circle.cu = circle.ru + view.u0;
    circle.cv = circle.rv + view.v0;
    return circle;
}

void put_rim(Fan& fan, const FanCircle& circle, RimStep step) noexcept {
    fan.x = circle.cx + (circle.rx * step.mx);
    fan.y = circle.cy - (circle.ry * step.my);
    fan.u = circle.cu + (circle.ru * step.mx);
    fan.v = circle.cv - (circle.rv * step.my);
}

RimStep rim_at(std::size_t pair) noexcept {
    return RimStep{.mx = kRim.at(pair * 2), .my = kRim.at((pair * 2) + 1)};
}

// Cỡ ảnh cảnh, cỡ cửa sổ và vị trí người chơi trên một trục.
struct AxisAsk {
    float scene = 0.0F;
    float window = 0.0F;
    float player = 0.0F;
};

// Zoom và m_WindowZero của một trục sau SetViewByCenter rồi UpdateAllWindow.
struct ZoomAxis {
    float zoom = 0.0F;
    float zero = 0.0F;
    // Vùng thấy bị kẹp sát mép ảnh, không còn canh giữa người chơi.
    bool is_pinned = false;
};

ZoomAxis zoom_axis(const AxisAsk& ask) noexcept {
    ZoomAxis axis;
    if (ask.scene <= 0.0F || ask.window <= 0.0F) return axis;
    axis.zoom = ask.scene * kRadarZoom / ask.window;
    const float fraction = ask.window / (ask.scene * kRadarZoom);
    float origin = -((ask.player / ask.scene) - (fraction * 0.5F)) / fraction;
    const bool is_low = axis.zoom >= 1.0F && origin < 1.0F - axis.zoom;
    const bool is_high = axis.zoom >= 1.0F && origin > 0.0F;
    if (is_low) origin = 1.0F - axis.zoom;
    if (is_high) origin = 0.0F;
    axis.zero = origin;
    axis.is_pinned = is_low || is_high;
    return axis;
}

// Vị trí cạnh trái của vùng thấy theo một trục, như SetViewByCenter, kẹp sát mép ảnh.
float axis_uv(const AxisAsk& ask) noexcept {
    const ZoomAxis axis = zoom_axis(ask);
    if (axis.zoom == 0.0F) return 0.0F;
    return -axis.zero / axis.zoom;
}

// Vùng thấy theo trục canh giữa người chơi: có cỡ và chưa bị kẹp sát mép.
bool is_centred(const AxisAsk& ask) noexcept {
    const ZoomAxis axis = zoom_axis(ask);
    return axis.zoom != 0.0F && !axis.is_pinned;
}

} // namespace

void round_fan(const FanView& view, std::span<Fan, kRoundCount> out) noexcept {
    const FanCircle circle = circle_of(view);
    for (std::size_t pair = 0; pair < kRimPairs; ++pair) {
        const std::size_t base = pair * 3;
        out[base] = Fan{.x = circle.cx, .y = circle.cy, .u = circle.cu, .v = circle.cv};
        put_rim(out[base + 1], circle, rim_at(pair));
        put_rim(out[base + 2], circle, rim_at(pair + 1));
    }
}

Radar radar_uv(const RadarAsk& ask) noexcept {
    Radar view;
    const AxisAsk across{.scene = ask.scene_width, .window = ask.window_width, .player = ask.player_x};
    const AxisAsk down{.scene = ask.scene_depth, .window = ask.window_height, .player = ask.player_z};
    view.u0 = axis_uv(across);
    view.v0 = axis_uv(down);
    view.is_centred_u = is_centred(across);
    view.is_centred_v = is_centred(down);
    const bool has_width = ask.scene_width > 0.0F && ask.window_width > 0.0F;
    const bool has_depth = ask.scene_depth > 0.0F && ask.window_height > 0.0F;
    if (has_width) view.u1 = view.u0 + (ask.window_width / (ask.scene_width * kRadarZoom));
    if (has_depth) view.v1 = view.v0 + (ask.window_height / (ask.scene_depth * kRadarZoom));
    return view;
}

SceneHit scene_at(const RadarAsk& ask, SceneCursor cursor) noexcept {
    const ZoomAxis across = zoom_axis({.scene = ask.scene_width, .window = ask.window_width, .player = ask.player_x});
    const ZoomAxis down = zoom_axis({.scene = ask.scene_depth, .window = ask.window_height, .player = ask.player_z});
    if (across.zoom == 0.0F || down.zoom == 0.0F) return {};
    const float relative_x = cursor.local_x / ask.window_width;
    const float relative_y = cursor.local_y / ask.window_height;
    const float scene_x = ((relative_x - across.zero) * ask.scene_width) / across.zoom;
    const float scene_z = ((relative_y - down.zero) * ask.scene_depth) / down.zoom;
    const bool is_on_scene =
        scene_x >= 0.0F && scene_x <= ask.scene_width && scene_z >= 0.0F && scene_z <= ask.scene_depth;
    if (!is_on_scene) return {};
    return SceneHit{.x = scene_x, .z = scene_z, .is_on_scene = true};
}

namespace {

// Điểm ảnh một đơn vị cảnh của từng chế độ phóng (FalagardSceneMap::UpdateAllWindow).
constexpr float kBoardBase = 4.0F;
constexpr float kBoardMode1 = 0.8F;
constexpr float kBoardMode3 = 2.0F;
constexpr float kBoardMode4 = 0.9F;

float board_pixels(const BoardAsk& ask) noexcept {
    const bool is_big =
        ask.scene_width * kBoardBase >= ask.window_width || ask.scene_depth * kBoardBase >= ask.window_height;
    if (ask.mode == 0 && is_big) return ask.window_height / std::max(ask.scene_width, ask.scene_depth);
    if (ask.mode == 1) return kBoardBase * kBoardMode1;
    if (ask.mode == 3) return kBoardBase * kBoardMode3;
    if (ask.mode == 4) return kBoardBase * kBoardMode4;
    return kBoardBase;
}

// Một trục của bản đồ lớn: đoạn ảnh (0..1) hiện ra, đoạn của cửa sổ chứa nó và tâm đã kẹp.
struct BoardAxis {
    float low = 0.0F;
    float high = 1.0F;
    float start = 0.0F;
    float length = 0.0F;
    float centre = 0.0F;
};

struct BoardAxisAsk {
    float scene = 0.0F;
    float window = 0.0F;
    float pixels = 0.0F;
    float centre = 0.0F;
};

BoardAxis board_axis(const BoardAxisAsk& ask) noexcept {
    BoardAxis axis;
    const float content = ask.scene * ask.pixels;
    if (content < ask.window) {
        axis.start = (ask.window - content) * 0.5F;
        axis.length = content;
        axis.centre = ask.scene * 0.5F;
        return axis;
    }
    const float fraction = ask.window / content;
    axis.low = std::clamp((ask.centre / ask.scene) - (fraction * 0.5F), 0.0F, 1.0F - fraction);
    axis.high = axis.low + fraction;
    axis.length = ask.window;
    axis.centre = (axis.low + (fraction * 0.5F)) * ask.scene;
    return axis;
}

} // namespace

BoardView board_view(const BoardAsk& ask) noexcept {
    BoardView view;
    const bool is_sized =
        ask.scene_width > 0.0F && ask.scene_depth > 0.0F && ask.window_width > 0.0F && ask.window_height > 0.0F;
    if (!is_sized) return view;
    view.pixels = board_pixels(ask);
    const BoardAxis across = board_axis({.scene = ask.scene_width,
        .window = ask.window_width,
        .pixels = view.pixels,
        .centre = ask.centre_x});
    const BoardAxis down = board_axis({.scene = ask.scene_depth,
        .window = ask.window_height,
        .pixels = view.pixels,
        .centre = ask.centre_z});
    view.uv = Radar{.u0 = across.low, .v0 = down.low, .u1 = across.high, .v1 = down.high};
    view.dest = Box{.x = across.start, .y = down.start, .w = across.length, .h = down.length};
    view.centre_x = across.centre;
    view.centre_z = down.centre;
    return view;
}

SceneHit board_scene_at(const BoardAsk& ask, const BoardView& view, SceneCursor cursor) noexcept {
    const bool is_inside = view.dest.w > 0.0F && view.dest.h > 0.0F && cursor.local_x >= view.dest.x &&
        cursor.local_x < view.dest.x + view.dest.w && cursor.local_y >= view.dest.y &&
        cursor.local_y < view.dest.y + view.dest.h;
    if (!is_inside) return {};
    const float across = (cursor.local_x - view.dest.x) / view.dest.w;
    const float down = (cursor.local_y - view.dest.y) / view.dest.h;
    const float u = view.uv.u0 + (across * (view.uv.u1 - view.uv.u0));
    const float v = view.uv.v0 + (down * (view.uv.v1 - view.uv.v0));
    return SceneHit{.x = u * ask.scene_width, .z = v * ask.scene_depth, .is_on_scene = true};
}

int radar_tiles(float scene) noexcept {
    if (!(scene >= 1.0F) || scene >= kHuge) return 0;
    const int whole = static_cast<int>(scene);
    int count = whole / kRadarTile;
    if (whole % kRadarTile != 0) ++count;
    return count;
}

bool radar_grid_exact(float scene) noexcept {
    const int count = radar_tiles(scene);
    if (count <= 0) return false;
    return static_cast<int>(scene) == count * kRadarTile;
}

std::string radar_tile_path(std::string_view token, int column, int row) {
    if (column < 0 || row < 0 || token.empty()) return {};
    return std::format("Scene/jpg_{}_{}_{}.png", token, column, row);
}

std::size_t arrow_frame(const ArrowTurn& turn) noexcept {
    if (!std::isfinite(turn.facing)) return 0;
    // Hướng mặt của client gốc nằm trong 0..2pi; atan2 cho -pi..pi nên đưa về cùng khoảng trước
    // khi cắt phần lẻ của độ, nếu không khung lệch một nấc ở sát biên.
    float angle = std::fmod(turn.facing, kTurn);
    if (angle < 0.0F) angle += kTurn;
    const int degrees = static_cast<int>(angle * kDegreesPerRadian) % kTurnDegrees;
    return static_cast<std::size_t>(degrees) * turn.frames / static_cast<std::size_t>(kTurnDegrees);
}

float bar_step(const BarMove& move) noexcept {
    const float goal = std::clamp(move.target, 0.0F, 1.0F);
    float next = std::clamp(move.shown, 0.0F, 1.0F);
    const float step = std::max(move.seconds, 0.0F) * move.speed;
    if (next > goal) next = std::max(goal, next - step);
    if (next < goal) next = std::min(goal, next + step);
    return next;
}

} // namespace game::gui
