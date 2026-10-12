// Vị trí, hướng và tỉ lệ đặt một vật thể của cảnh, đọc từ ba thuộc tính "position", "orientation",
// "scale" đúng theo cách client gốc đọc, để vật thể nằm đúng toạ độ gốc từng bit.
// Nguồn port: OGRE 1.2.5 của client 2008 (G:\TLBB\_ref), StringConverter::parseReal, parseVector3,
// parseQuaternion, và WXPlacementObject.cpp, WXTransform.cpp. Giữ nguyên các điểm sau của bản gốc:
// - Số thực đọc bằng atof rồi ép về float: đọc thành double trước, thu về float sau (hai lần làm
//   tròn), không đọc thẳng thành float.
// - Chuỗi tách theo dấu cách, tab, xuống dòng; token rỗng bị bỏ.
// - Vector phải đủ 3 token, quaternion đủ 4; sai số token thì vector thành 0 0 0, quaternion thành
//   đơn vị. Vì vậy "scale" viết sai thành tỉ lệ 0, đúng như bản gốc.
// - Quaternion trong tệp theo thứ tự w x y z.
// - Thiếu thuộc tính: vị trí 0, hướng đơn vị, tỉ lệ 1.
// Hệ toạ độ là hệ của OGRE: tay phải, Y hướng lên, đơn vị centimet; không đổi gì.
#pragma once

#include "scene/scene_file.hpp"

#include <string_view>

namespace game::scene {

struct Vector3 {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;

    [[nodiscard]] bool operator==(const Vector3&) const = default;
};

struct Quaternion {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float w = 1.0F;

    [[nodiscard]] bool operator==(const Quaternion&) const = default;
};

// Phép đặt: tỉ lệ trước, rồi quay, rồi dời (ma trận T * R * S với vectơ cột).
struct Placement {
    Vector3 position;
    Quaternion orientation;
    Vector3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
};

// Một số thực theo parseReal: phần đầu chuỗi đọc được thành số, không đọc được thì 0.
[[nodiscard]] float parse_real(std::string_view text) noexcept;

// "x y z" theo parseVector3; số token khác 3 thì 0 0 0.
[[nodiscard]] Vector3 parse_vector3(std::string_view text) noexcept;

// "w x y z" theo parseQuaternion; số token khác 4 thì quaternion đơn vị.
[[nodiscard]] Quaternion parse_quaternion(std::string_view text) noexcept;

// Phép đặt của một vật thể, lấy từ ba thuộc tính của nó.
[[nodiscard]] Placement placement_of(const Object& object) noexcept;

} // namespace game::scene
