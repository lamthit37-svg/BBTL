// Phần thuần CPU của ánh sáng một lệnh vẽ, tách khỏi forward.cpp để kiểm được bằng test không cần
// GPU: đổi chất liệu glTF, hoặc Pass mà người gọi đã điền, cùng ánh sáng của
// khung thành phần màu của khối hằng Draw mà model.hlsli đọc, chọn đèn điểm cho một vật thể, và
// chọn những bản sao instanced còn trong khung nhìn kèm đèn của từng bản.
// Không có Pass: ánh sáng nền là ambient của cảnh hoặc của nhân vật, cờ nhân màu đỉnh.
// Có Pass: ambient nhân hệ số của Pass rồi cộng emissive; đèn điểm là đèn gần gốc vật thể nhất
// mà tầm cộng bán kính bao còn với tới.
#pragma once

#include "math/matrix.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "render/forward.hpp"
#include "resource/model.hpp"

#include <cstdint>
#include <limits>
#include <span>
#include <vector>

namespace game::render {

// Bit của Draw::flags trong model.hlsli. kInstanced do forward.cpp đặt khi vẽ bản sao.
inline constexpr std::uint32_t kUnlit = 1;
inline constexpr std::uint32_t kInstanced = 2;
inline constexpr std::uint32_t kActor = 4;
inline constexpr std::uint32_t kPixelLit = 8;
inline constexpr std::uint32_t kNoFog = 16;
inline constexpr std::uint32_t kRawSum = 32;
inline constexpr std::uint32_t kSpecular = 64;
inline constexpr std::uint32_t kAddLight = 128;
inline constexpr std::uint32_t kVertexColor = 256;
// Ảnh surface nhân lên ảnh nền. Particle_2Tex của hạt mesh. Billboad không bật cờ này.
inline constexpr std::uint32_t kMaskTex = 512;
// Chất liệu không trộn alpha: shader trả alpha 1. forward.cpp đặt theo pipeline, shade_of không đặt.
inline constexpr std::uint32_t kOpaqueAlpha = 1024;

// Draw::lamp khi không đèn điểm nào với tới vật thể.
inline constexpr std::uint32_t kNoLamp = std::numeric_limits<std::uint32_t>::max();

// Phần màu của khối hằng Draw.
struct Shade {
    // rgb: hệ số nhân màu texture (màu nền glTF nhân 1, 2 hoặc 4 của chất liệu); a: hệ số alpha.
    math::Float4 base_color{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
    // rgb: ánh sáng nền; a: shininess.
    math::Float4 glow{};
    // rgb: diffuse của chất liệu; a: ngưỡng cắt alpha, 0 là không cắt.
    math::Float4 diffuse{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 0.0F};
    // rgb: specular của chất liệu nhân specular của đèn chính một.
    math::Float4 specular{};
    std::uint32_t flags = 0;
};

struct ShadeAsk {
    // Null: primitive không khai chất liệu.
    const resource::Material* material = nullptr;
    const Lighting* lighting = nullptr;
    bool is_actor = false;
};

// Tiền điều kiện: ask.lighting khác null.
[[nodiscard]] Shade shade_of(const ShadeAsk& ask) noexcept;

// Vật thể đang tìm đèn: gốc và bán kính bao trong thế giới.
struct Reach {
    math::Vector3 centre{0.0F, 0.0F, 0.0F};
    float radius = 0.0F;
};

// Chỉ số của đèn gần centre nhất trong các đèn còn với tới (khoảng cách không quá tầm cộng bán
// kính); kNoLamp khi không có. Đèn tầm không dương bị bỏ qua.
[[nodiscard]] std::uint32_t nearest_lamp(std::span<const Lamp> lamps, const Reach& reach) noexcept;

// Gốc và bán kính bao trong thế giới của một model đứng ở world. radius là bán kính bao của model ở
// tư thế nghỉ; nó được nhân với tỉ lệ lớn nhất trong ba trục của world, nên hình cầu trả về chứa
// trọn model kể cả khi tỉ lệ không đều.
[[nodiscard]] Reach reach_at(const math::Matrix4& world, float radius) noexcept;

// Một bản sao (Instance::copies) còn được vẽ trong khung.
struct SeenCopy {
    // Chỉ số trong Instance::copies.
    std::uint32_t index = 0;
    // Chỉ số đèn điểm của riêng bản này trong lamps; kNoLamp khi không đèn nào với tới.
    std::uint32_t lamp = kNoLamp;
};

struct CopyAsk {
    std::span<const math::Matrix4> copies;
    std::span<const Lamp> lamps;
    // Bán kính bao của model ở tư thế nghỉ.
    float radius = 0.0F;
};

// Ghi vào seen (nội dung cũ bị xoá) những bản sao có hình cầu bao còn chạm khung nhìn, theo thứ tự
// gốc, mỗi bản kèm đèn điểm của riêng nó. Bản nằm hẳn ngoài một mặt của khung thì bỏ. Tốn số bản
// sao nhân số đèn; không cấp phát khi seen đã đủ sức chứa.
void see_copies(const CopyAsk& ask, const Frustum& frustum, std::vector<SeenCopy>& seen);

} // namespace game::render
