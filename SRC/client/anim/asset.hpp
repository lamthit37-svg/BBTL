#pragma once
// Xương và animation theo đúng mô hình dữ liệu của OGRE 1.2.5 mà client gốc dùng: skeleton là danh
// sách xương (tên, handle, bind pose so với cha) cùng cạnh cha con; animation là các track, mỗi
// track một xương, mỗi khoá là ĐỘ LỆCH so với bind pose của xương đó.
// Nguồn: TLBB Dev src/cooked/asset.hpp@e0d89a6 (mục "Xương" và "Animation"). Khác gốc: kiểu nằm
// trong game::anim thay cho cooked, vì module này không đọc định dạng nấu của TLBB; bộ nạp từ GLB
// ở resource/rig.hpp dựng ra các kiểu này.

#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <cstdint>
#include <string>
#include <vector>

namespace game::anim {

// Xương: tên, handle, vị trí, hướng và scale so với cha. Bản ghi xương v1.10 CÓ thể mang scale:
// OgreSkeletonSerializer::readBone đọc thêm 3 float khi độ dài khai ở header chunk lớn hơn 36 (độ
// dài đó không tính tên xương; chunk có scale khai 48). 189 xương ở 88 tệp .skeleton của ref có
// scale, như skeleton lá cờ Cái Bang với 0,8447.
struct Bone {
    std::string name;
    std::uint16_t handle = 0;
    ogre::Vec3 position;
    ogre::Quat orientation;
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};

    friend bool operator==(const Bone&, const Bone&) = default;
};

// Một cạnh của cây xương: handle của xương con và handle của cha nó.
struct BoneParent {
    std::uint16_t child = 0;
    std::uint16_t parent = 0;

    friend constexpr bool operator==(const BoneParent&, const BoneParent&) = default;
};

struct SourceSkeleton {
    std::vector<Bone> bones;
    std::vector<BoneParent> parents;
    std::string animation_link;
    float animation_scale = 1.0F;
};

// Bit của BoneTrack::flags: thành phần nào có mặt trong MỌI khoá của track. Cùng giá trị với
// KF_ROTATION, KF_TRANSLATE, KF_SCALE của chunk 0x4120 trong OgreSkeletonSerializer của ref.
inline constexpr std::uint8_t kKeyRotation = 1;
inline constexpr std::uint8_t kKeyTranslate = 2;
inline constexpr std::uint8_t kKeyScale = 4;
inline constexpr std::uint8_t kKeyAll = kKeyRotation | kKeyTranslate | kKeyScale;

// Một khoá: độ lệch so với bind pose của xương tại thời điểm `time` (giây). Thành phần mà cờ của
// track không bật thì giữ mặc định: quay đơn vị, dịch 0, scale 1.
struct BoneKey {
    float time = 0.0F;
    ogre::Quat rotation;
    ogre::Vec3 translate;
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};

    friend constexpr bool operator==(const BoneKey&, const BoneKey&) = default;
};

// Track của một xương. Một track OGRE có thể gồm nhiều chunk khoá với cờ khác nhau; bộ nạp gộp
// chúng, lấy hợp các cờ, ghi giá trị mặc định cho khoá thiếu thành phần, và sắp khoá theo thời
// gian như _sortKeyFrames.
struct BoneTrack {
    std::uint16_t bone = 0;
    std::uint8_t flags = 0;
    std::vector<BoneKey> keys;

    friend bool operator==(const BoneTrack&, const BoneTrack&) = default;
};

struct Animation {
    std::string name;
    float length = 0.0F;
    std::vector<BoneTrack> tracks;

    friend bool operator==(const Animation&, const Animation&) = default;
};

// Animation nằm riêng khỏi SourceSkeleton: một bộ animation phục vụ được nhiều skeleton, như 430
// skeleton phụ của Model/all.obj.
using AnimationList = std::vector<Animation>;

} // namespace game::anim
