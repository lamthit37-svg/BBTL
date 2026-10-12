#pragma once
// Người chơi đã nạp đủ để ra tư thế mỗi khung, không chạm GPU: rig của skeleton chính của giới, bốn
// clip (đứng, hai động tác nghỉ, chạy) đã đổi sang animation theo OGRE, và danh sách lưới bộ phận
// của look::Figure (nơi vẽ tự nạp lưới lên GPU). Clip nằm ở tệp .skeleton của skeleton phụ nhưng
// được đánh giá trên bind pose của skeleton CHÍNH, như client gốc: dùng nhầm bind pose của tệp clip
// thì lệch tới 0,3 đơn vị (nữ).
// Skinner ra ma trận skin của khung từ Avatar và clip đang phát, dạng Matrix4 cho renderer: một
// mảng theo handle xương, dùng chung cho mọi bộ phận (mọi lưới bộ phận có skin trên skeleton
// chính). Bản mới của dự án, theo luồng của client_app/avatar.cpp của TLBB Dev: bind_pose, apply
// clip, rig.skin; phần lưới bộ phận và texture ở nơi vẽ.

#include "anim/asset.hpp"
#include "anim/pose.hpp"
#include "anim/rig.hpp"
#include "avatar/gait.hpp"
#include "core/error.hpp"
#include "look/look.hpp"
#include "math/matrix.hpp"
#include "ogre/quat.hpp"

#include <cstddef>
#include <filesystem>
#include <optional>
#include <span>
#include <vector>

namespace game::avatar {

class Avatar {
public:
    // Nạp skeleton chính và các clip của figure từ thư mục dữ liệu client (tệp dưới Model/). Lỗi
    // khi thiếu tệp, thiếu clip, hay clip của tệp phụ không cùng xương với skeleton chính.
    [[nodiscard]] static core::Result<Avatar> load(const look::Figure& figure, const std::filesystem::path& data_root);

    [[nodiscard]] const look::Figure& figure() const noexcept { return figure_; }
    [[nodiscard]] const anim::Rig& rig() const noexcept { return rig_; }

    // Độ dài bốn clip cho Gait.
    [[nodiscard]] ClipLengths lengths() const noexcept;
    // Animation của thế đang phát; động tác nghỉ không có clip thì clip đứng.
    [[nodiscard]] const anim::Animation& animation(Stance stance) const noexcept;
    // Áp phần chỉnh của figure (look::BoneTrim) lên tư thế cục bộ của clip đứng; không có thì thôi.
    void trim_idle(anim::Pose& pose) const noexcept;

private:
    Avatar(look::Figure figure, anim::Rig rig) : figure_(std::move(figure)), rig_(std::move(rig)) {}

    look::Figure figure_;
    anim::Rig rig_;
    anim::Animation idle_;
    std::optional<anim::Animation> idle_alt_;
    std::optional<anim::Animation> idle_alt2_;
    anim::Animation run_;
    // Handle của xương cần chỉnh và phép xoay thêm quanh trục z của nó.
    struct Trim {
        std::size_t handle = 0;
        ogre::Quat turn;
    };
    std::optional<Trim> trim_;
};

// Bộ đệm tư thế của một avatar: tái dùng giữa các khung để không cấp phát mỗi khung.
class Skinner {
public:
    // Dựng tư thế của clip đang phát rồi ma trận skin. Lỗi khi clip trỏ xương không có.
    [[nodiscard]] core::Status update(const Avatar& avatar, const Playing& playing);

    // Ma trận skin theo handle xương, hợp lệ tới lần update kế.
    [[nodiscard]] std::span<const math::Matrix4> joints() const noexcept { return joints_; }

private:
    anim::Pose pose_;
    std::vector<anim::Affine> skin_;
    std::vector<anim::Transform> derived_;
    std::vector<math::Matrix4> joints_;
};

} // namespace game::avatar
