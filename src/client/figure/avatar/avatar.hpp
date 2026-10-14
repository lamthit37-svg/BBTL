#pragma once
// Người chơi đã nạp đủ để ra tư thế mỗi khung, không chạm GPU: rig của skeleton chính của giới, bốn
// clip (đứng, hai động tác nghỉ, chạy) đã đổi sang animation theo OGRE, và danh sách lưới bộ phận
// của look::Figure (nơi vẽ tự nạp lưới lên GPU). Clip nằm ở tệp .skeleton của skeleton phụ nhưng
// được đánh giá trên bind pose của skeleton CHÍNH, như client gốc: dùng nhầm bind pose của tệp clip
// thì lệch tới 0,3 đơn vị (nữ).
// Đòn đánh và tuyệt chiêu của skill (look::Strike) nạp cùng, mỗi đòn một clip; Gait phát một lần.
// Skinner ra ma trận skin của khung từ Avatar và clip đang phát, dạng Matrix4 cho renderer: một
// mảng theo handle xương, dùng chung cho mọi bộ phận (mọi lưới bộ phận có skin trên skeleton
// chính). Bản mới của dự án, theo luồng của client_app/avatar.cpp của TLBB Dev: bind_pose, apply
// clip, rig.skin; phần lưới bộ phận và texture ở nơi vẽ.

#include "anim/asset.hpp"
#include "anim/pose.hpp"
#include "anim/rig.hpp"
#include "avatar/gait.hpp"
#include "avatar/locator.hpp"
#include "core/error.hpp"
#include "look/look.hpp"
#include "look/skill.hpp"
#include "math/matrix.hpp"
#include "ogre/quat.hpp"

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <span>
#include <vector>

namespace game::avatar {

class Avatar {
public:
    // Nạp skeleton chính và các clip của figure từ thư mục dữ liệu client (tệp dưới Model/). Lỗi
    // khi thiếu tệp, thiếu clip, hay clip của tệp phụ không cùng xương với skeleton chính.
    // strikes là các đòn cần có clip (look::strikes_of); clip đòn nằm ở tệp .skeleton riêng của skill. locators là
    // bảng locator của mọi mẫu: điểm gắn của khối con (AttachPoint) tra locator của mẫu nhân vật trước rồi mới tới xương.
    [[nodiscard]] static core::Result<Avatar> load(const look::Figure& figure, const std::filesystem::path& data_root,
        std::span<const look::Strike> strikes = {}, std::span<const look::LocatorRow> locators = {});

    [[nodiscard]] const look::Figure& figure() const noexcept { return figure_; }
    [[nodiscard]] const anim::Rig& rig() const noexcept { return rig_; }

    // Độ dài các clip cho Gait.
    [[nodiscard]] ClipLengths lengths() const noexcept;
    // Animation của thế đang phát; động tác nghỉ không có clip thì clip đứng.
    [[nodiscard]] const anim::Animation& animation(const Playing& playing) const noexcept;
    // Các đòn đã nạp, cùng thứ tự với chỉ số Playing::strike.
    [[nodiscard]] std::span<const look::Strike> strikes() const noexcept { return strike_defs_; }
    // Chỉ số của đòn (skill, step) trong strikes(); rỗng khi không nạp đòn đó.
    [[nodiscard]] std::optional<std::size_t> strike_index(std::uint32_t skill, std::uint32_t step) const noexcept;
    // Độ dài clip của đòn thứ index, giây.
    [[nodiscard]] float strike_length(std::size_t index) const noexcept;
    // Biến đổi (không gian mẫu nhân vật) của điểm gắn của khối con thứ event của đòn thứ strike kèm phần lệch của khối
    // (OffsetPos, OffsetRotation), như getLocatorWorldTransform rồi getBoneWorldTransform của LogicModel. Rỗng khi
    // khối không có điểm gắn hay tên không là locator lẫn xương.
    [[nodiscard]] std::optional<anim::Transform> event_pose(std::size_t strike, std::size_t event,
        std::span<const anim::Transform> bones) const;
    // Ma trận (không gian mẫu nhân vật) của từng mẫu con trong figure().held, cùng thứ tự, tính từ biến
    // đổi derived của xương ở khung này (Skinner::derived); người gọi nhân với ma trận đặt nhân vật.
    // Nạp vào out để không cấp phát mỗi khung.
    void mount_matrices(std::span<const anim::Transform> bones, std::vector<math::Matrix4>& out) const;
    // Biến đổi (không gian mẫu nhân vật) của điểm hiệu ứng 武器特效点 trên mẫu con thứ mount của figure().held (chỉ số
    // trong held): nút locator của mẫu con cộng phần lệch của locator đó trong mẫu vũ khí. Mẫu không có locator ấy thì ở
    // gốc mẫu con (LogicModel::addEffect của ref gắn vào locator không có thì dùng nút gốc). Rỗng khi mount ngoài held.
    [[nodiscard]] std::optional<anim::Transform> effect_pose(std::size_t mount,
        std::span<const anim::Transform> bones) const;
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
    std::optional<anim::Animation> jump_stand_;
    std::optional<anim::Animation> jump_run_;
    // Cùng chỉ số: định nghĩa đòn và clip của nó.
    std::vector<look::Strike> strike_defs_;
    std::vector<anim::Animation> strike_clips_;
    // Điểm gắn của từng khối con của từng đòn, cùng chỉ số với strike_defs_ rồi events.
    std::vector<std::vector<std::optional<Locator>>> event_points_;
    // Locator và tỉ lệ của từng mẫu con trong figure().held.
    struct Mount {
        Locator locator;
        ogre::Vec3 scale;
        // Điểm 武器特效点 trong mẫu vũ khí; rỗng khi mẫu không có.
        std::optional<Locator> effect_point;
    };
    std::vector<Mount> mounts_;
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
    // Biến đổi derived của xương theo handle (cùng khung với joints), cho Avatar::mount_matrices.
    [[nodiscard]] std::span<const anim::Transform> derived() const noexcept { return derived_; }

private:
    anim::Pose pose_;
    std::vector<anim::Affine> skin_;
    std::vector<anim::Transform> derived_;
    std::vector<math::Matrix4> joints_;
};

} // namespace game::avatar
