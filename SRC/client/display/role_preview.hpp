#pragma once
// Người mẫu của bảng chọn và màn tạo: một người chơi có xương đứng trong cảnh tl3chuangjian, vẽ
// bằng chính lượt Forward của màn hình. Bản 2026 đặt người mẫu thẳng vào cảnh ở cả hai màn (Game.exe
// 0x14063d97a cho ba ô của bảng chọn, 0x140641e60 cho màn tạo); cửa sổ CreateRole_Model của layout
// để trống (xem ui/panel/role_pose.hpp).

#include "client/display/player.hpp"
#include "core/error.hpp"
#include "render/forward.hpp"

#include <cstdint>
#include <memory>
#include <vector>

namespace game::client {

// Ngoại hình đang vẽ, để biết lúc nào phải nạp lại lưới: giới, mặt, tóc và ba món trang phục (áo,
// bao tay, giày; 0 là bộ mặc định của giới).
struct RoleLook {
    std::uint8_t sex = 0;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t body = 0;
    std::uint16_t arm = 0;
    std::uint16_t foot = 0;

    friend bool operator==(const RoleLook&, const RoleLook&) = default;
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
class RoleShot {
public:
    using ShotResult = core::Result<RoleShot>;

    // Lỗi của PlayerActor::create khi bảng ngoại hình hay skeleton không nạp được.
    [[nodiscard]] static ShotResult create(const PlayerDesc& player, const MeshLoader& load);

    RoleShot(RoleShot&&) noexcept;
    RoleShot& operator=(RoleShot&&) noexcept;
    RoleShot(const RoleShot&) = delete;
    RoleShot& operator=(const RoleShot&) = delete;
    ~RoleShot();

    [[nodiscard]] bool matches(RoleLook look) const noexcept;
    // Đổi lưới. false khi không dựng được; người mẫu cũ còn.
    [[nodiscard]] bool retarget(const PlayerDesc& player, const MeshLoader& load_mesh);
    // Dựng tư thế tại stand: bảng chọn để chân theo ô, màn tạo để chân ở chỗ của thủ tục tạo.
    [[nodiscard]] core::Status pose(const Stand& stand);
    // Thêm bộ phận vào danh sách vẽ thế giới. pose phải vừa chạy.
    void append(std::vector<render::Instance>& out) const;

private:
    struct State;

    explicit RoleShot(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::client
