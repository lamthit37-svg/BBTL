#pragma once
// Ảnh đầu 3D của người chơi cho ô chân dung, như fake object "Player_Head" của client gốc: một bản
// mô hình người chơi thứ hai đứng yên ở gốc toạ độ, vẽ vào một render::Canvas bằng chính lượt
// Forward của màn hình, qua camera nhìn thẳng vào đầu. Giao diện lấy mẫu ảnh đó trong cửa sổ
// PlayerFrame_Head_3D, dưới mặt nạ của cửa sổ cha.
// Số đo của client 2026 (Render.dll, đọc tĩnh): texture vuông cạnh là cỡ cửa sổ làm tròn lên luỹ
// thừa 2 (ô 80 thành 128), nền (0, 0, 0, 0), camera phối cảnh FOV dọc 20 độ, mặt cắt gần 10 (RVA
// 0x17C10). Chỗ đặt mắt, điểm nhìn và góc quay mô hình lấy từ Table/head_cameras.tsv theo mẫu của
// mô hình (look/head.hpp, bảng Character_3DHead.txt của bản gốc). Ánh sáng và mặt cắt xa chưa đọc
// được (docs/NGHI-NGO.md mục 24).

#include "client/display/player.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "look/head.hpp"
#include "render/camera.hpp"
#include "render/forward.hpp"

#include <cstdint>
#include <memory>

namespace game::client {

// Camera của ảnh đầu theo bộ số của mô hình: FOV dọc 20 độ, mặt cắt gần 10, khung vuông.
[[nodiscard]] render::Camera head_camera(const look::HeadPose& pose) noexcept;

// Camera của ảnh toàn thân vừa khít FOV 20 độ, cho mô hình cao height.
[[nodiscard]] render::Camera body_camera(float height) noexcept;

struct HeadShotDesc {
    PlayerDesc player;
    // Lượt vẽ mô hình của màn hình; ảnh đầu vẽ bằng chính nó. Phải sống lâu hơn HeadShot.
    render::Forward* forward = nullptr;
    // Định dạng và số mẫu của lượt Forward sẽ vẽ vào ảnh: trùng với màn hình.
    gpu::Format color_format = gpu::Format::kRgba8UnormSrgb;
    gpu::Format depth_format = gpu::Format::kD32Float;
    std::uint32_t samples = 1;
    // Cạnh của texture theo điểm ảnh. Client gốc dùng cỡ cửa sổ làm tròn lên luỹ thừa 2 (ô 80 thành 128) và giao diện phủ
    // cả texture lên cửa sổ nên ảnh bị lấy mẫu lại và mờ; mặc định gấp đôi mỗi chiều (256 cho ô 80), giao diện lấy mẫu
    // tuyến tính xuống gần đúng 2:1 nên ảnh nét như khử răng cưa. Ảnh toàn thân (play.cpp) dùng 512 cho cửa sổ 246.
    std::uint32_t pixels = 256;
    // Toàn thân cho vòng xem của bảng nhân vật. Không bật thì là ảnh đầu của khung người chơi.
    bool is_body = false;
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
class HeadShot {
public:
    // Dựng mô hình (cùng bảng ngoại hình với người chơi) và ảnh đích. Mượn device: HeadShot phải bị
    // huỷ trước nó; drawable do load_mesh trả phải sống lâu hơn HeadShot. InvalidArgument khi desc
    // không có forward.
    [[nodiscard]] static core::Result<HeadShot> create(gpu::Device& device, const HeadShotDesc& desc,
        const MeshLoader& load_mesh);

    HeadShot(HeadShot&&) noexcept;
    HeadShot& operator=(HeadShot&&) noexcept;
    HeadShot(const HeadShot&) = delete;
    HeadShot& operator=(const HeadShot&) = delete;
    ~HeadShot();

    // Ghi lượt vẽ ảnh đầu vào list. Gọi ngoài mọi begin_rendering. slot là bộ buffer của forward
    // dành riêng cho lượt này trong khung, không trùng lượt màn hình.
    [[nodiscard]] core::Status record(gpu::CommandList& list, std::uint32_t slot);

    // Quay mô hình quanh trục đứng khi người dùng giữ nút xoay (RotateBeginEx / RotateEndEx của bảng
    // nhân vật): speed là số mà UI_CEGUI.dll đưa cho engine, 0 thì dừng, dương quay sang phải. Tốc độ thực là
    // speed vòng mỗi giây, cùng thang với ModelRotBegin của màn tạo nhân vật; đơn vị của engine chưa đọc
    // được (docs/NGHI-NGO.md).
    void set_spin(float speed) noexcept;

    // Ảnh màu để giao diện lấy mẫu; nội dung là của lần record gần nhất.
    [[nodiscard]] gpu::TextureViewHandle view() const noexcept;
    // Ảnh màu có hàng đầu là hàng dưới cùng của hình không (render::Canvas::is_bottom_up).
    [[nodiscard]] bool is_bottom_up() const noexcept;

private:
    struct State;

    explicit HeadShot(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::client
