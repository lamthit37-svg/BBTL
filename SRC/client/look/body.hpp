// Khung nhìn mô hình trong cửa sổ FakeObject lúc tạo nhân vật. Ống kính đo từ Render.dll
// 0x17C10: FOV dọc 20 độ, mặt cắt gần 10. Mô hình đứng ở gốc, cao `height` centimet (cột
// height của player_bodies, là y của BoundingBox). Mắt ở +z, nhìn vào giữa thân, lùi đủ để
// chiều cao vừa khít góc nhìn. Khác gốc: camera chọn nhân vật của bản 2026 là CCamera_CharSel
// (animation của cảnh), chưa port; cửa sổ CreateRole_Model dùng khung này.
#pragma once

#include <array>

namespace game::look {

inline constexpr float kBodyFovDegrees = 20.0F;
inline constexpr float kBodyNear = 10.0F;
// tan(10 độ), nửa FOV dọc của fake object.
inline constexpr float kBodyHalfTan = 0.176326981F;

struct BodySight {
    std::array<float, 3> eye{};
    std::array<float, 3> target{};
};

// height không dương thì coi như 1 cm để mắt không nằm trong mô hình.
[[nodiscard]] constexpr BodySight body_sight(float height) noexcept {
    const float span = height > 1.0F ? height : 1.0F;
    const float half = span * 0.5F;
    BodySight sight;
    sight.target = {0.0F, half, 0.0F};
    sight.eye = {0.0F, half, half / kBodyHalfTan};
    return sight;
}

// Nữ 180 cm: nửa thân 90, lùi 90 / tan(10°) nằm trong (510, 511).
static_assert(body_sight(180.0F).target[1] == 90.0F);
static_assert(body_sight(180.0F).eye[2] > 510.0F && body_sight(180.0F).eye[2] < 511.0F);

} // namespace game::look
