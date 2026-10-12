// Nội dung của một cảnh mà phần hiển thị cần để vẽ: các vật thể tĩnh (tên mesh và phép đặt), các
// đèn directional và màu ambient. Trích từ scene::SceneFile; không biết gì về GPU hay tệp GLB, nên
// kiểm được bằng test và dùng được ở mọi cấu hình.
// Chưa lấy: địa hình, nước, hạt, hiệu ứng, Model có xương, đèn điểm, sương mù.
#pragma once

#include "scene/placement.hpp"
#include "scene/scene_file.hpp"

#include <string>
#include <vector>

namespace game::client {

// Màu tuyến tính ba kênh, như số ghi trong tệp cảnh.
struct Rgb {
    float red = 0.0F;
    float green = 0.0F;
    float blue = 0.0F;

    [[nodiscard]] bool operator==(const Rgb&) const = default;
};

// Một vật thể tĩnh (StaticEntity) có mesh.
struct Prop {
    // Tên mesh như trong tệp cảnh, ví dụ "敦煌/敦煌山洞.mesh"; tệp GLB là Model/<tên>.glb.
    std::string mesh;
    scene::Placement placement;
};

// Một đèn directional. direction là hướng tia sáng đi (từ đèn tới vật), theo quy ước của OGRE.
struct Sun {
    scene::Vector3 direction;
    Rgb colour;
};

struct Stage {
    // Theo đúng thứ tự StaticEntity trong tệp cảnh; vật thể không có "mesh name" bị bỏ.
    std::vector<Prop> props;
    std::vector<Sun> suns;
    Rgb ambient;
};

// Nội dung cần vẽ của một tệp cảnh đã đọc.
[[nodiscard]] Stage stage_of(const scene::SceneFile& file);

} // namespace game::client
