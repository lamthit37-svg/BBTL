// Ánh sáng của cảnh cho lượt vẽ: đổi số của tệp cảnh (Stage) và mốc môi trường theo giờ của bầu
// trời sang render::Lighting, theo cách Render.dll của client 2026 áp chúng vào Ogre (đọc tĩnh):
// - Enviroment (0xE1150): ambient cho cả cảnh lẫn nhân vật, sương; nền của khung là màu sương khi
//   cảnh có sương, không thì màu "background".
// - Đèn "#FairyMainLightOne" và "#FairyMainLightTwo" (0x10C320): hai đèn chính; nhân vật nhận
//   đúng màu đèn nhân cường độ.
// - Cảnh có bầu trời (0xF4260): mốc theo giờ đè ambient, màu và tầm sương, màu và specular của hai
//   đèn chính; nhân vật nhận ambient và màu đèn riêng của mốc. Hướng đèn vẫn là của tệp cảnh.
// Giờ trong ngày của bản gốc do trò chơi đặt; chưa lần được nguồn nên dùng kOfflineDayTime
// (docs/NGHI-NGO.md mục 28).
#pragma once

#include "client/stage/stage.hpp"
#include "gpu/types.hpp"
#include "math/vector.hpp"
#include "render/forward.hpp"

#include <vector>

namespace game::client {

// Giữa trưa, tính bằng phần của một ngày.
inline constexpr float kOfflineDayTime = 0.5F;

class SceneLight {
public:
    // Ánh sáng mặc định của render::Lighting trên nền xám xanh, cho khung không có cảnh.
    SceneLight() = default;
    // Ánh sáng của stage tại thời điểm time (phần của ngày, 0..1).
    SceneLight(const Stage& stage, float time);

    // Mượn mảng đèn điểm của đối tượng này: chỉ dùng khi nó còn sống và chưa bị gán lại.
    [[nodiscard]] render::Lighting view() const noexcept;
    // Màu xoá của khung, đã đổi sang tuyến tính cho đích vẽ sRGB.
    [[nodiscard]] gpu::ClearColor clear_color() const noexcept;

private:
    render::Lighting base_;
    std::vector<render::Lamp> lamps_;
    // Màu nền trong không gian gamma, như số của tệp cảnh.
    math::Vector3 backdrop_{0.2479F, 0.2722F, 0.3140F};
};

// Ánh sáng của stage ở giờ mặc định khi chưa có máy chủ.
[[nodiscard]] SceneLight light_of(const Stage& stage);

} // namespace game::client
