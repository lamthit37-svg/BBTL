// Chữ và đồng hồ của minimap (MiniMap_Frame): tên cảnh, toạ độ cảnh và canh giờ, theo
// MiniMap_UpdateSceneName và Minimap_CoordinateUpdate. Ảnh cảnh và mũi tên là việc của radar.
// Nguồn: MiniMap.lua (UpdateSceneName, CoordinateUpdate) và FalagardSceneMap (GetMouseScenePos,
// onMouseEnters, onMouseMove, onMouseLeaves). GetMouseScenePos đẩy int(x), int(z).
// Khác gốc: tên cảnh đã dịch nên chọn phông theo số byte UTF-8 (bản gốc đếm byte GBK); canh giờ
// do người gọi đưa vì giờ trong game là của máy chủ.
#pragma once

#include "ui/panel/deck.hpp"

#include <cstdint>
#include <string_view>

namespace game::ui::panel {

// Số canh giờ của một ngày (Tý tới Hợi), cũng là số chấm giờ quanh đồng hồ minimap.
inline constexpr std::uint8_t kWatches = 12;

struct MapSeen {
    // Tên cảnh để hiện; rỗng thì ô tên để trống.
    std::string_view title;
    // Toạ độ cảnh sẽ in: chỗ đứng, hay điểm dưới chuột khi chuột nằm trên map.
    float player_x = 0.0F;
    float player_z = 0.0F;
    // Canh giờ trong game, 0 (Tý) tới kWatches - 1 (Hợi); số lớn hơn thì coi là Hợi.
    std::uint8_t watch = 0;
};

// Ghi chỉ thị của minimap. Chuỗi mượn của seen phải sống tới hết khung.
void fill_minimap(Deck& deck, const MapSeen& seen);

// Trạng thái chuột trên map để chọn số in ra, theo onMouseEnters / onMouseMove / onMouseLeaves.
struct Hover {
    bool was_inside = false;
    bool is_inside = false;
    bool is_on_scene = false;
    float scene_x = 0.0F;
    float scene_z = 0.0F;
    float held_x = 0.0F;
    float held_z = 0.0F;
    float player_x = 0.0F;
    float player_z = 0.0F;
};

// Số đang hiện và số giữ lại cho lần chuột vẫn trên map mà phép ra ngoài cảnh.
struct PlaceText {
    float across = 0.0F;
    float down = 0.0F;
    bool is_inside = false;
    float held_x = 0.0F;
    float held_z = 0.0F;
};

// Rời map thì chỗ đứng. Vào map mà ngoài cảnh thì 0. Đang trên map mà ngoài cảnh thì giữ số cũ.
[[nodiscard]] PlaceText coordinate_of(const Hover& hover) noexcept;

} // namespace game::ui::panel
