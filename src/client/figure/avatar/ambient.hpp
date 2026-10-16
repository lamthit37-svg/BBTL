/*==============================================================================
 *  THIENLONG  |  VẬT THỂ MODEL CÓ XƯƠNG TRONG CẢNH
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/avatar/ambient.hpp
 *  PHÂN HỆ   : Figure / Avatar
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Object Model của cảnh gồm frame (nút có đường đi, ví dụ Dummy02 của quạ bay) và lưới có
 *    xương gắn vào nút đó. Mỗi khung: đường đi của nút cho ma trận gắn, clip của skeleton cho
 *    ma trận skin. Hai clip lặp độc lập theo độ dài của chính nó, như Ogre phát mọi
 *    AnimationState bật lặp.
 *  - Không dính GPU. Bản mới của dự án, dùng lại anim::Rig, anim::apply và cầu resource::bones_of
 *    của Avatar. Khác gốc: client gốc phát clip có tên "auto"; ở đây lấy clip tên "auto", không
 *    có thì clip đầu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "anim/asset.hpp"
#include "anim/pose.hpp"
#include "anim/rig.hpp"
#include "core/error.hpp"
#include "math/matrix.hpp"

#include <cstddef>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::avatar {

// Hai tệp GLB của một vật thể và nút của frame mà lưới gắn vào.
struct AmbientFiles {
    // Tệp .frame.glb: nút có hoặc không có đường đi.
    std::filesystem::path frame;
    // Tệp .skeleton.glb mà lưới liên kết: xương và clip vỗ cánh, vẫy, lay.
    std::filesystem::path skeleton;
    // Tên nút của frame (Dummy02, Bip01...).
    std::string node;
};

class Ambient {
public:
    // Lỗi khi thiếu tệp, tệp hỏng, frame không có nút đó hay skeleton không dựng được rig.
    [[nodiscard]] static core::Result<Ambient> load(const AmbientFiles& files);

    // Dựng tư thế ở giây seconds kể từ lúc cảnh mở; hai clip tự lặp. Lỗi khi clip trỏ xương không
    // có.
    [[nodiscard]] core::Status update(float seconds);

    // Ma trận của nút frame so với chỗ đặt vật thể. Đơn vị khi frame đứng yên ở gốc.
    [[nodiscard]] const math::Matrix4& attach() const noexcept { return attach_; }
    // Ma trận skin theo handle xương, hợp lệ tới lần update kế.
    [[nodiscard]] std::span<const math::Matrix4> joints() const noexcept { return joints_; }

private:
    Ambient(anim::Rig frame_rig, anim::Rig rig)
        : frame_rig_(std::move(frame_rig)), rig_(std::move(rig)) {}

    anim::Rig frame_rig_;
    std::size_t node_ = 0;
    std::optional<anim::Animation> frame_clip_;
    anim::Rig rig_;
    std::optional<anim::Animation> clip_;
    anim::Pose frame_pose_;
    std::vector<anim::Affine> frame_skin_;
    std::vector<anim::Transform> frame_derived_;
    anim::Pose pose_;
    std::vector<anim::Affine> skin_;
    std::vector<anim::Transform> derived_;
    math::Matrix4 attach_ = math::Matrix4::identity();
    std::vector<math::Matrix4> joints_;
};

} // namespace game::avatar
