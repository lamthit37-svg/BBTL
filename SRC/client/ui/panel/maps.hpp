// Bản đồ lớn (SceneMap) và bản đồ thế giới (LargeMap). Thứ tự mở, đóng và đổi tầng chép từ
// SceneMap.lua và LargeMap.lua ở G:\TLBB\_content\source\Interface. Nút trên minimap gọi
// ToggleSceneMap và ToggleLargeMap không tham số: coi là chế độ 2 (đang mở thì đóng).
// Khác gốc: chưa có widget TLBB_WorldMap nên chưa có thành đang chọn; đóng bản đồ thế giới
// không tự mở lại bản đồ cảnh. Danh sách tầng hiện bằng tên tiếng Việt, id giữ nguyên.
#pragma once

#include "ui/panel/deck.hpp"

#include <cstdint>
#include <string_view>

namespace game::ui::panel {

// Đối số của sự kiện bản đồ: 0 đóng, 1 mở, 2 đảo, 3 mở cảnh khác (chỉ bản đồ lớn).
enum class MapToggle : std::uint8_t { kClose, kOpen, kFlip, kOther };

// 4294967295: LargeMap_Click_NormalScene bỏ qua, không có thành.
inline constexpr std::uint32_t kNoCity = 4294967295U;
// Tuyết cảnh Lạc Dương dùng chung id 0 sau khi mở bản đồ.
inline constexpr int kSnowLuoyang = 242;

struct Maps {
    bool is_world_open = false;
    bool is_scene_open = false;
    // Cảnh người chơi đang đứng, và cảnh bản đồ đang vẽ. -1 khi chưa có.
    int here = -1;
    int chosen = -1;
    // Nhóm tầng, -1 khi cảnh không có tầng. floor là chỉ số 0 trong nhóm.
    int group = -1;
    int floor = 0;
    // Đúng khi cảnh đang vẽ là cảnh người chơi đứng, trước khi đổi 242 thành 0.
    bool shows_here = true;
    // Thành đang chọn trên bản đồ thế giới; -1 khi chưa bấm.
    int world_choice = -1;
};

struct SceneAsk {
    MapToggle order = MapToggle::kClose;
    int scene_id = -1;
    int here = -1;
};

// Đổi cảnh thì đóng bản đồ lớn, như SCENE_TRANSED. Lần đầu gán here không tính là đổi.
void follow_here(Maps& maps, int here) noexcept;
void note_world(Maps& maps, MapToggle order) noexcept;
void note_scene(Maps& maps, SceneAsk ask) noexcept;
// Bấm một thành. kNoCity thì không làm gì.
void choose_city(Maps& maps, std::uint32_t scene_id) noexcept;
// Chỉ số mục combo bắt đầu từ 1, như ComboBoxAddItem. Sai nhóm hoặc sai chỉ số thì bỏ.
void pick_floor(Maps& maps, int index) noexcept;
// Về bản đồ cảnh đang đứng, như SceneMap_Show_CurrentScene.
void show_here(Maps& maps) noexcept;

// SceneMap_RawZoom: âm hoặc lớn hơn 4 thì bỏ; từ 3 trở lên kẹp về 2.
[[nodiscard]] int clamped_zoom(int step) noexcept;
// SceneMap_Frame_On_ResetPos: rộng không đọc được hoặc không quá 960 thì kéo chữ vào.
[[nodiscard]] bool label_is_inset(std::string_view resolution) noexcept;

// Nút bấm của layout. Không phải nút bản đồ thì không đổi trạng thái.
void press_map(Maps& maps, std::string_view window) noexcept;

// Hiện đúng một trong hai bảng, hoặc giấu cả hai. Tiêu đề là tên cảnh đã dịch.
// resolution là chuỗi View_Resoution, để đặt chữ SceneMap_Text3.
void paint_maps(Deck& deck, const Maps& maps, std::string_view title, std::string_view resolution);

} // namespace game::ui::panel
