/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/fx/area.hpp
 *  PHÂN HỆ   : Place / Fx / Area
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Chỗ sinh hạt của emitter vùng theo _initParticle của Plugin_ParticleFX bản
 *    TLBB (G:\XTLBB\Bin64). Ellipsoid và Cylinder ở đó đã bị viết lại, khác
 *    OGRE gốc; Box và HollowEllipsoid giống gốc.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "fx/system.hpp"
#include "ogre/vec3.hpp"

namespace game::fx {

class Field;

// Điểm sinh trong không gian của hệ cho Box, Ring, Ellipsoid, HollowEllipsoid, Cylinder. Rút số
// ngẫu nhiên của field theo đúng thứ tự gốc. Point và Polar trả vị trí của emitter.
[[nodiscard]] ogre::Vec3 area_point(Field& field, const EmitterDef& emitter);

} // namespace game::fx
