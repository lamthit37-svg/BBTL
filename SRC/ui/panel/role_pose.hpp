// Người mẫu của bảng chọn và màn tạo, như giao diện đưa cho phần hiển thị. Script gốc gọi
// GameProduceLogin:ModelRotBegin(±1) khi giữ nút xoay và ModelRotEnd(0) khi nhả (CreateRole.lua, chú
// thích "每秒-1圈"). Nhịp của thủ tục tạo (Game.exe 0x1406416f1) cộng spin * 6,28318548 * (mili giây
// / 1000) vào thành phần y của hướng người mẫu đang là hiện tại của giới, rồi SetRotation.
// ModelZoom(±1) và con lăn đặt tốc độ phóng của camera (control/char_camera.hpp).
#pragma once

#include <cstdint>
#include <string_view>

namespace game::ui::panel {

// Đúng mẫu bit float mà Game.exe nhân (0x140c1be24).
inline constexpr float kFullTurn = 6.28318548F;
inline constexpr float kSpinLeft = -1.0F;
inline constexpr float kSpinRight = 1.0F;

inline constexpr std::string_view kSelectTurnLeft = "SelectRole_Role2_Model_TurnLeft";
inline constexpr std::string_view kSelectTurnRight = "SelectRole_Role2_Model_TurnRight";

// yaw radian, spin là số vòng mỗi giây (âm là sang trái). 0 là nhìn thẳng vào camera.
struct RolePose {
    float yaw = 0.0F;
    float spin = 0.0F;
};

// Người mẫu đang hiện. Cả hai màn đặt người vào cảnh: script tạo vẫn gán fake object
// "CreateRole_Woman" / "CreateRole_Man" cho cửa sổ CreateRole_Model, nhưng Game.exe 2026 không tạo
// fake object nào tên như vậy (không có chuỗi "CreateRole_" trong tệp), nên cửa sổ đó để trống.
struct ShownModel {
    // Bảng chọn và bảng tạo dùng cảnh tl3chuangjian, không phải phông tài khoản.
    bool on_role_scene = false;
    // Có nhân vật đứng trong cảnh.
    bool in_world = false;
    // Màn tạo: người đứng ở chỗ của thủ tục tạo (control::kCreateFeet, tỉ lệ 1,5), không ở ô.
    bool is_creating = false;
    // Ô 0..2 của bảng chọn. Chân lấy từ control::role_place.
    std::uint8_t slot = 0;
    // Màn tạo: số lần thủ tục được vào, giới nó nhớ lúc vào (0 nữ, 1 nam), số lần
    // ChangeNewRoleEquipSet và hướng phóng ModelZoom đang giữ (-1 lùi, 1 tiến).
    std::uint32_t entries = 0;
    std::uint8_t entry_sex = 0;
    std::uint32_t outfit_calls = 0;
    std::int8_t zoom = 0;
    // Màn tạo: môn phái đang xem trước (0..14), người mẫu là mẫu riêng của môn; -1 là người mẫu tự
    // chọn với mặt, tóc, bộ đồ ở dưới.
    std::int8_t sect = -1;
    std::uint8_t sex = 0;
    // Id bảng ngoại hình của mặt, tóc và id hình trang phục của áo, bao tay, giày; 0 là mặc định
    // của giới. Ở bảng tạo, mặt và tóc là dòng cao mô mà người mẫu của client gốc dùng.
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t body = 0;
    std::uint16_t arm = 0;
    std::uint16_t foot = 0;
    float yaw = 0.0F;
};

inline void hold_turn(RolePose& pose, float spin) noexcept {
    pose.spin = spin;
}

inline void advance_yaw(RolePose& pose, float seconds) noexcept {
    pose.yaw += pose.spin * kFullTurn * seconds;
}

} // namespace game::ui::panel
