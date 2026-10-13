// Bản đồ thế giới (LargeMap, widget Falagard/WorldMap): ảnh nền ghép từ lưới 5 x 4 ô 256 x 256 đặt trong
// cửa sổ, kéo bằng nút phải; các thành phố là nút và nhãn ở toạ độ của bảng cảnh; di chuột lên một thành
// thì nút đổi ảnh, nhấp trái thì mở bản đồ cảnh của thành đó (LargeMap_Click_NormalScene). Việc vẽ nằm ở
// gui/paint.cpp (draw_world); bảng này giữ độ lệch, thành đang trỏ và dựng lời gọi Override:
// WorldMapSize, WorldMapView, WorldMapCities, WorldMapSelf, WorldMapHover.
// Nguồn: FalagardWorldMap của CEGUIFalagard.dll 2026 (createBackground 0x18008b200, updataBackground
// 0x18008ea20, onDrapStart/Move/End 0x18008dcd0..0x18008dc00, createNewCity 0x18008c320, resetWorldMap
// 0x18008dd50, cityHover 0x18008ae40, onClick 0x18008db00, isCopyScene 0x18008d900, getCurrentSelectScene
// 0x18003fca0) và InitWorldMap của UI_CEGUI.dll (0x180027950: mỗi dòng bảng cảnh có cột 24 bằng loại bản đồ
// và chỗ đặt nút khác (0, 0) là một thành phố), LargeMap.lua.
// Khác gốc: kéo và kẹp tính ở đây thay vì trong widget; chưa có tooltip, bạn bè, đối địch, cờ chỉ huy và
// thông tin bang chiếm (cần máy chủ); mở bản đồ lần đầu ở góc trên trái như độ lệch khởi tạo của widget.
#pragma once

#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/scene_table.hpp"

#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::string_view kWorldWindow = "LargeMap_Frondground";
// Lưới ô của BackgroundName "WorldMap": BackgroundSize w:5 h:4, mỗi ô 256 điểm ảnh (0x18013a820).
inline constexpr int kWorldColumns = 5;
inline constexpr int kWorldRows = 4;
inline constexpr float kWorldTile = 256.0F;
// Loại bản đồ thế giới thường: InitWorldMap(0, ...) chỉ lấy những dòng bảng cảnh mang số này ở cột 24.
inline constexpr int kNormalWorld = 0;

struct WorldBoard {
    // Chỗ góc trên trái của ảnh nền so với góc trên trái của cửa sổ (FalagardWorldMap +0x500, +0x504 nhân
    // cỡ cửa sổ), điểm ảnh; step_world kẹp lại.
    float x = 0.0F;
    float y = 0.0F;
    // Kéo bằng nút phải: điểm chuột và độ lệch lúc bắt đầu (onDrapStart).
    bool is_dragging = false;
    float drag_x = 0.0F;
    float drag_y = 0.0F;
    float drag_from_x = 0.0F;
    float drag_from_y = 0.0F;
    // Thành đang trỏ (cityHover); -1 là không có (4294967295 của getCurrentSelectScene).
    int hover = -1;
};

// Cỡ ảnh nền ghép: kWorldColumns x kWorldRows ô.
[[nodiscard]] gui::Box world_image_box() noexcept;

// Các dòng WorldMapCities của bảng cảnh: id, nút x y, nhãn x y, loại nút, bộ ảnh và ảnh của nhãn, tên đã dịch, sắc
// nhãn ("red" hay rỗng), cách nhau bằng tab, mỗi thành một dòng. Tên đã dịch lấy từ names theo tên gốc; có tên thì
// nhãn vẽ bằng chữ (ảnh nhãn của bản gốc là chữ Hán dựng sẵn, lẫn với tên tiếng Việt ở mọi chỗ khác). Rỗng khi
// bảng không có thành nào.
[[nodiscard]] std::string world_cities(const SceneTable& table, const gui::StringBook& names);

// Bản đồ chỉ cho xem, không mở bản đồ cảnh (副本): isCopyScene.
[[nodiscard]] bool is_copy_scene(int city) noexcept;

// Số liệu một khung: ô cửa sổ, chuột và các chỗ bấm của lần dàn trang trước (cái vẽ sau nằm cuối).
struct WorldStep {
    gui::Box window;
    std::optional<gui::Pointer> pointer;
    std::span<const gui::WorldHit> hits;
};

// Một khung: kéo bằng nút phải, kẹp độ lệch (ảnh nhỏ hơn cửa sổ thì ở giữa), tìm thành đang trỏ.
void step_world(WorldBoard& board, const WorldStep& step);

// Thành dưới con trỏ lúc này (trong các hits), -1 khi không có. Dùng khi nhả nút để biết nhấp trúng thành nào.
[[nodiscard]] int city_under(std::span<const gui::WorldHit> hits, float across, float down) noexcept;

// Chỉ thị của bản đồ thế giới. cities là kết quả của world_cities (phải sống tới hết khung), here là cảnh
// người chơi đang đứng (dấu MySelf), -1 khi chưa có.
void paint_world(Deck& deck, const WorldBoard& board, std::string_view cities, int here);

} // namespace game::ui::panel
