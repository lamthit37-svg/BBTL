// Bản đồ lớn của cảnh (SceneMap_Board, Falagard/SceneMap): chế độ phóng, tâm vùng thấy, các nút cuộn,
// nút phóng, kéo bằng nút phải, toạ độ dưới chuột. Việc vẽ ảnh nằm ở gui/paint.cpp (draw_board); bảng này
// chỉ giữ trạng thái và đưa nó qua Override: SceneMapZoom, SceneMapSize, SceneMapCenter, SceneMapSelf.
// Nguồn: FalagardSceneMap của CEGUIFalagard.dll 2026 (UpdateAllWindow 0x1800c73b0, SetViewByCenter
// 0x1800c70f0, updateSelf 0x1800cac80, onMouseButtonDown 0x1800c97a0, onMouseMove 0x1800c99e0, ScrollUp
// và các hàm cuộn 0x1800c6dd0..0x1800c6e60, hằng 0,01 ở 0x18012fe04, thời gian chờ 5 giây ở updateSelf) và
// SceneMap.lua (SceneMap_Show, SceneMap_FixZoom, SceneMap_ZoomMode, SceneMap_UpdateInfo).
// Khác gốc: tâm giữ theo đơn vị cảnh (gốc giữ độ lệch 0..1 của cửa sổ); chưa có cờ NPC và đội (cần máy
// chủ), tooltip, chế độ biệt thự và bỉ võ, chế độ 5 tới 13.
#pragma once

#include "gui/sheet.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/scene_table.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::string_view kBoardWindow = "SceneMap_Board";
// Mỗi khung cuộn 0,01 cửa sổ (DAT_18012fe04), tính ở 60 khung mỗi giây.
inline constexpr float kScrollStep = 0.01F;
inline constexpr float kScrollRate = 60.0F;
// Sau khi cuộn hay kéo, bản đồ chờ chừng này giây mới theo người chơi lại (updateSelf).
inline constexpr float kRestSeconds = 5.0F;
// Bốn nút cuộn của layout (DoScroll 1..4).
inline constexpr std::string_view kScrollUp = "SceneMap_MoveUp";
inline constexpr std::string_view kScrollDown = "SceneMap_MoveDown";
inline constexpr std::string_view kScrollLeft = "SceneMap_MoveL";
inline constexpr std::string_view kScrollRight = "SceneMap_MoveR";
inline constexpr std::string_view kZoomOut = "ScemeMap_ZoomButtons1";
inline constexpr std::string_view kZoomIn = "ScemeMap_ZoomButtons2";

enum class Scroll : std::uint8_t { kNone, kUp, kDown, kLeft, kRight };

// Chỗ người chơi trong cảnh, đơn vị cảnh.
struct Where {
    float x = 0.0F;
    float z = 0.0F;
};

struct SceneBoard {
    // SceneMapZoom; khởi tạo là 1 như constructor của FalagardSceneMap.
    std::int32_t mode = 1;
    float centre_x = 0.0F;
    float centre_z = 0.0F;
    // Giây còn lại tới lúc bản đồ theo người chơi lại.
    float rest = 0.0F;
    Scroll scroll = Scroll::kNone;
    // Kéo bằng nút phải: điểm chuột và tâm lúc bắt đầu kéo.
    bool is_dragging = false;
    float drag_x = 0.0F;
    float drag_y = 0.0F;
    float drag_centre_x = 0.0F;
    float drag_centre_z = 0.0F;
    // Cảnh đang vẽ là cảnh người chơi đứng: có mũi tên và theo người chơi.
    bool is_here = true;
    Where last_player;
    // Toạ độ dưới chuột lần cuối (SceneMap_UpdateInfo).
    float coord_x = 0.0F;
    float coord_z = 0.0F;
};

// SceneMap_Show: chế độ 1 chỉ dành cho cảnh 512 x 512 trở lên (nhỏ hơn thì về 2), chế độ trên 2 về 2; tâm
// ở người chơi khi xem cảnh của mình, không thì giữa cảnh.
void open_board(SceneBoard& board, const SceneRow& scene, Where player, bool is_here);

// SceneMap_ZoomMode: in là phóng to (nút cộng), không thì thu nhỏ (nút trừ); cảnh nhỏ bỏ chế độ 1.
void zoom_board(SceneBoard& board, bool in, const SceneRow& scene);

// Nút của layout được nhấn: bốn nút cuộn giữ hướng cho tới khi nhả; hai nút phóng đổi chế độ.
void press_board(SceneBoard& board, std::string_view window, const SceneRow& scene);
void release_board(SceneBoard& board) noexcept;

// Số liệu một khung: ô cửa sổ bản đồ, chuột, giây trôi qua và chỗ người chơi.
struct BoardStep {
    gui::Box window;
    std::optional<gui::Pointer> pointer;
    float seconds = 0.0F;
    Where player;
};

// Một khung: cuộn theo nút, kéo bằng nút phải, theo người chơi khi họ đi, kẹp tâm, cập nhật toạ độ.
void step_board(SceneBoard& board, const SceneRow& scene, const BoardStep& step);

// Số liệu BoardAsk của bảng với ô cửa sổ window.
[[nodiscard]] gui::BoardAsk board_ask(const SceneBoard& board, const SceneRow& scene, gui::Box window) noexcept;

// Chỉ thị của bản đồ lớn: chế độ, cỡ cảnh, tâm, mũi tên, toạ độ chuột.
void paint_board(Deck& deck, const SceneBoard& board, const SceneRow& scene);

} // namespace game::ui::panel
