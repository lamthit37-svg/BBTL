#pragma once
// Người chơi trên màn hình: ngoại hình đã giải từ bảng, các lưới bộ phận đã tải lên GPU, tư thế
// theo clip (đứng, nghỉ, chạy) và hướng mặt xoay mượt. Nơi vẽ nạp lưới giúp qua MeshLoader, nên lớp
// này không giữ tài nguyên GPU: chỉ trỏ vào drawable do nơi vẽ sở hữu. Hướng mặt 0 là +z (quy ước
// của client gốc: hướng = atan2(dx, dz), mô hình quay quanh +y bằng Quaternion::FromAngleAxis). Bản
// mới của dự án, theo client_app/world_view.cpp của TLBB Dev (đặt nút mẫu, Gait, Turning).

#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "avatar/turning.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "look/look.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "render/forward.hpp"

#include <filesystem>
#include <functional>
#include <optional>
#include <string>
#include <vector>

namespace game::client {

// Tên lưới (tên gốc dưới Model/, không có .glb) thành drawable đã tải lên GPU của nơi vẽ; nullptr
// khi không nạp được. Drawable phải sống lâu hơn PlayerActor.
using MeshLoader = std::function<const render::Drawable*(const std::string& mesh)>;

struct PlayerDesc {
    // Thư mục dữ liệu client: Table/ và Model/.
    std::filesystem::path data_root;
    look::Race race = look::Race::kFemale;
    // Có thì dùng khối này; không thì bộ mặc định của giới.
    std::optional<look::Look> look;
    // Có thì người mẫu là mẫu riêng của môn (Table/sect_models.tsv), không phải look ở trên.
    std::optional<std::uint8_t> sect;
};

// Chỗ đứng của người chơi trong một khung: chân trên mặt đất (toạ độ thế giới), hướng mặt logic
// (radian) và đang đi hay không.
struct Stand {
    math::Point3 foot;
    float facing = 0.0F;
    // Tỉ lệ quanh chân; người mẫu của màn tạo đứng to gấp rưỡi.
    float scale = 1.0F;
    bool is_moving = false;
    // Cú nhảy bắt đầu trong khung này (kJumpStand hay kJumpRun của avatar::Stance), và chạm đất
    // trong khung này. Bắt đầu áp trước chạm đất.
    std::optional<avatar::Stance> jump;
    bool has_landed = false;
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
class PlayerActor {
public:
    // Nạp bảng, giải bộ mặc định của giới, nạp skeleton, clip và lưới bộ phận. Thiếu một lưới thì
    // bỏ lưới đó và ghi log; lỗi khi thiếu bảng, skeleton hay clip.
    [[nodiscard]] static core::Result<PlayerActor> create(const PlayerDesc& desc, const MeshLoader& load_mesh);

    // Dựng tư thế và ma trận đặt cho khung ở thời điểm now.
    [[nodiscard]] core::Status update(core::Clock::time_point now, const Stand& stand);

    // Thêm một instance cho mỗi bộ phận; ma trận skin trỏ vào bộ đệm của lần update gần nhất.
    void append(std::vector<render::Instance>& out) const;

    [[nodiscard]] const look::Figure& figure() const noexcept { return avatar_.figure(); }

private:
    PlayerActor(avatar::Avatar avatar, std::vector<const render::Drawable*> parts, bool fidget, bool demo);

    avatar::Avatar avatar_;
    avatar::Skinner skinner_;
    avatar::Gait gait_;
    avatar::Turning turning_;
    avatar::ClipLengths lengths_;
    std::vector<const render::Drawable*> parts_;
    math::Matrix4 placed_ = math::Matrix4::identity();
    // Môn phái: khung đầu phát bài múa một lần. fidget sai thì không múa lại lúc nghỉ.
    bool cue_demo_ = false;
};

} // namespace game::client
