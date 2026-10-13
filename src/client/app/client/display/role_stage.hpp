// Phần của hai thủ tục CGamePro_CharSel và CGamePro_CharCreate (Game.exe) đứng giữa giao diện và
// camera chọn nhân vật: mỗi nhịp nó cập nhật camera, đổi con lăn thành lệnh phóng, và cho camera
// chạy khi giao diện đổi ô hay đổi giới.
// - Màn tạo (Init 0x1406413e0, nhịp 0x1406414b0, con lăn 0x1406418be, ChangeNewRoleEquipSet
//   0x140641210): vào màn thì camera đứng ở tư thế của giới thủ tục còn nhớ; mỗi lần đặt bộ đồ thì
//   chạy xuôi (nữ) hay ngược (nam) trên CameraTrack.
// - Bảng chọn (đổi ô 0x14063c480, nhịp 0x14063cfa0, con lăn 0x14063d41e): đổi ô thì chạy track nối
//   hai ô; đang chạy mà đòi ô thứ ba thì chờ tới nơi rồi mới đi tiếp, đòi quay lại ô vừa rời thì
//   đảo chiều ngay.
// Một nấc lăn đặt tốc độ phóng ±1 và cộng ±5 vào bộ đếm; mỗi nhịp bộ đếm lùi 1 về 0, tới 0 thì thôi
// phóng. Hai thủ tục giữ bộ đếm riêng.
// Vào bảng chọn (Init 0x14063d620) camera chạy NGƯỢC track của ô từ thời điểm 1,1 giây: lướt chừng một
// giây vào mắt của ô, không đứng sẵn.
// Khác gốc: không kiểm hai ô đều có nhân vật trước khi chạy (giao diện chỉ cho chọn ô có nhân vật);
// con lăn phóng ở mọi chỗ trên màn hình (bản gốc bỏ sự kiện mà giao diện đã nhận).
#pragma once

#include "control/char_camera.hpp"
#include "ui/panel/role_pose.hpp"

#include <cstdint>
#include <optional>

namespace game::client {

// Đồng hồ và con lăn của một khung. Mỗi chiều lăn nhiều nấc trong một khung vẫn là một sự kiện.
struct StageFrame {
    std::uint32_t now_ms = 0;
    float seconds = 0.0F;
    bool is_wheel_up = false;
    bool is_wheel_down = false;
};

class RoleStage {
public:
    // Một khung khi cảnh chọn nhân vật đang hiện. O(1).
    void step(const ui::panel::ShownModel& model, const StageFrame& frame) noexcept;
    // Không có trước lần step đầu.
    [[nodiscard]] std::optional<control::TrackPose> camera() const noexcept;
    // Cảnh 3D vừa hiện: lần step kế chạy lại track vào ô, để cú zoom không trôi trong lúc nạp.
    void replay() noexcept;

private:
    enum class Scene : std::uint8_t { kNone, kSelect, kCreate };
    // Cờ và bộ đếm con lăn của một thủ tục (+0x3f0, +0x3f4 của màn tạo; +0x5a0, +0x5a4 của bảng chọn).
    struct Wheel {
        bool is_rolling = false;
        std::int32_t ticks = 0;
    };

    void step_create(const ui::panel::ShownModel& model, const StageFrame& frame) noexcept;
    void step_select(const ui::panel::ShownModel& model, const StageFrame& frame) noexcept;
    void roll(Wheel& wheel, const StageFrame& frame) noexcept;
    // Nút phóng đang giữ thì tốc độ là hướng đó mỗi khung. Không giữ thì con lăn còn chạy thì
    // để nguyên tốc độ của nó, hết lăn thì về 0.
    void drive_zoom(std::int8_t zoom, Wheel& wheel) noexcept;
    void rest_at(std::uint8_t slot) noexcept;
    void select_slot(std::uint8_t slot) noexcept;

    control::CharCamera camera_;
    Scene scene_ = Scene::kNone;
    Wheel create_wheel_;
    Wheel select_wheel_;
    // Màn tạo: số đã thấy của ShownModel::entries và outfit_calls.
    std::uint32_t entries_ = 0;
    std::uint32_t outfit_calls_ = 0;
    // Bảng chọn: ô đang đứng (+0x588), ô vừa rời (+0x590), ô chờ (+0x58c) và ô giao diện đòi lần
    // trước.
    std::uint8_t slot_ = 0;
    std::uint8_t previous_ = 0;
    std::optional<std::uint8_t> pending_;
    std::uint8_t wanted_ = 0;
};

} // namespace game::client