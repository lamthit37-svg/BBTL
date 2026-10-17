/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/fx/billboard.hpp
 *  PHÂN HỆ   : Place / Fx / Billboard
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dựng quad billboard của hạt đang sống. Đỉnh ở thế giới. UV texcoord:
 *    OgreTexCoordBillboardParticleRenderer và setTextureStacksAndSlices.
 *    Ribbon: BillboardChain, cạnh bằng nửa bề rộng, hướng theo mắt camera.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "fx/field.hpp"
#include "fx/strip.hpp"

#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace game::fx {

struct BillboardVertex {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float u = 0.0F;
    float v = 0.0F;
    float red = 1.0F;
    float green = 1.0F;
    float blue = 1.0F;
    float alpha = 1.0F;
};

struct CameraAxes {
    ogre::Vec3 right{.x = 1.0F};
    ogre::Vec3 up{.x = 0.0F, .y = 1.0F};
    ogre::Vec3 forward{.x = 0.0F, .y = 0.0F, .z = -1.0F};
    ogre::Vec3 eye{};
};

struct BillboardBatch {
    std::string material;
    std::vector<BillboardVertex> vertices;
};

// Một lô cho mỗi hệ còn hạt. material rỗng thì bỏ.
[[nodiscard]] std::vector<BillboardBatch> billboards_of(std::span<const Field* const> fields, CameraAxes camera);

// Cầu ở thế giới bao mọi đỉnh mà billboards_of dựng cho hệ này, để bỏ hệ nằm ngoài khung nhìn trước
// khi dựng quad (đo trên TB-X306F: dựng quad là 14% thời gian luồng vẽ). Chỉ có cho hạt billboard
// kiểu điểm, hai trục là trục camera nên tầm với không phụ thuộc camera. Ribbon, mesh và các kiểu
// theo hướng hạt hay hướng chung trả nullopt: luôn được vẽ.
struct GrainSphere {
    ogre::Vec3 centre{};
    float radius = 0.0F;
};

[[nodiscard]] std::optional<GrainSphere> grain_sphere(const Field& field);

// full_width: EffectBillboardChain nhân cả bề rộng, không nhân một nửa.
void append_chain(BillboardBatch& batch, std::span<const ChainSample> points, CameraAxes camera, bool full_width);

// Quad ngang cạnh projection, tâm tại node. Khác gốc: không bám địa hình.
void append_deck(BillboardBatch& batch, const Node& node, float size, Colour colour);

} // namespace game::fx
