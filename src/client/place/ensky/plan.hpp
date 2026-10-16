/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/plan.hpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Danh sách lệnh vẽ của bầu trời trong một khung, đã xếp đúng thứ tự hàng
 *    đợi của Ogre: nhóm 59, ưu tiên tăng dần, cùng ưu tiên thì vật xa camera vẽ
 *    trước, hoà thì theo thứ tự tạo (mây, mây vòng, trăng, mặt trời).
 *  - Mỗi lệnh mang nút cảnh tương đối với camera (lớp vẽ chỉ cần ghép với ma
 *    trận nhìn đã bỏ tịnh tiến). Lớp có alpha không quá 1e-6 không được tạo nên
 *    không có lệnh.
 *  - Nguồn: Render.dll 2026 (EnCloud 0x180239b00, EnRingCloud 0x18023b0f0, EnMoon,
 *    EnSun), xem docs/TAILIEU/EN-SCENE-RENDER-DLL.md mục 3.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "ensky/sky.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::ensky {

enum class Kind : std::uint8_t { kCloud, kRing, kMoon, kSun };

// Lớp có alpha không quá mức này thì bản gốc xoá đối tượng (double ở 0x1802e9370).
inline constexpr double kMinAlpha = 1.0e-6;
// Ưu tiên nền của từng loại trong nhóm hàng đợi 59.
inline constexpr int kCloudPriority = 90;
inline constexpr int kRingPriority = 110;
inline constexpr int kBodyPriority = 90;
// Cỡ cạnh mặt phẳng dựng sẵn PT_PLANE của Ogre.
inline constexpr float kPlaneSize = 100.0F;

struct Draw {
    Kind kind = Kind::kCloud;
    // Chỉ số lớp trong Sky::clouds hay Sky::rings; không dùng cho trăng và mặt trời.
    std::size_t index = 0;
    int priority = 0;
    float distance_squared = 0.0F;
    std::uint32_t order = 0;
    // Nút cảnh tương đối với camera: T(offset) * R(orientation) * S(scale).
    ogre::Quat orientation;
    ogre::Vec3 offset;
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
};

// Hướng nút lớp mây khi tạo: yaw rotangle, rồi lật PI quanh z cục bộ khi turnoverMesh.
[[nodiscard]] ogre::Quat cloud_orientation(const CloudLayer& layer);

// Lệnh vẽ của nhóm 59 theo đúng thứ tự vẽ. Chỉ lớp alpha > kMinAlpha, trăng và mặt trời đang bật.
[[nodiscard]] std::vector<Draw> plan_of(const Playback& playback);

} // namespace game::ensky
