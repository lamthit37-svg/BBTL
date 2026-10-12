// Mô hình glTF, dạng nhị phân GLB là tệp người dùng đưa vào. Một tệp chứa lưới, morph, chất liệu
// PBR (kể cả extension Khronos mà cgltf đã tách), sampler, ảnh PNG hoặc JPEG, nút, xương, clip,
// camera, đèn và biến thể chất liệu. Ảnh giải ra RGBA8. Đầu ra của gltfpack nạp được: lưới lượng
// tử (KHR_mesh_quantization) và buffer view nén (EXT_meshopt_compression). Không nạp DDS, KTX2,
// Draco; tệp ĐÒI một extension lớp này không đọc trọn thì bị từ chối (Unsupported).
// Nguồn: Forge2 src/resource/model.hpp@d7fcd76. Khác gốc: thêm ImageScope, image_path và tham số
// root của load_glb_file, để ảnh ngoài được nằm ngoài thư mục của tệp GLB miễn là vẫn trong thư mục
// gốc dữ liệu (THIENLONG đặt GLB ở Model/, ảnh ở Material/; gốc chỉ nhận ảnh trong thư mục của tệp
// GLB); Vertex::joints là std::array thay mảng kiểu C; khởi tạo Float2, Float3, Float4 ghi tên
// thành viên; bỏ {} thừa của các thành viên string, vector, optional và Matrix4; include thêm
// <array> và <cstddef>; Node thêm parts (tịnh tiến, xoay, tỉ lệ đúng như tệp khai) cho hệ xương
// của anim/, nơi dấu của quaternion gốc không được mất qua ma trận.
#pragma once

#include "core/error.hpp"
#include "math/matrix.hpp"
#include "math/types.hpp"
#include "resource/image.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::resource {

struct Vertex {
    math::Float3 position{};
    math::Float3 normal{};
    math::Float4 tangent{.x = 1.0F, .y = 0.0F, .z = 0.0F, .w = 1.0F};
    math::Float2 uv{};
    math::Float2 uv1{};
    math::Float4 color{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
    std::array<std::uint16_t, 4> joints{};
    math::Float4 weights{};
};

// Độ lệch cộng vào đỉnh gốc. glTF ghi tiếp tuyến của morph là VEC3, không có thành phần w.
// uv và màu bằng 0 khi target không khai kênh đó; cờ trên MorphTarget nói kênh có trong tệp.
// JOINTS và WEIGHTS không phải kênh morph của glTF nên bị bỏ.
struct MorphVertex {
    math::Float3 position{};
    math::Float3 normal{};
    math::Float3 tangent{};
    math::Float2 uv{};
    math::Float2 uv1{};
    math::Float4 color{};
};

struct MorphTarget {
    std::string name;
    std::vector<MorphVertex> vertices;
    bool has_uv = false;
    bool has_uv1 = false;
    bool has_uv1 = false;
    bool has_color = false;
};

// Ánh xạ một biến thể chất liệu sang một material. variant là chỉ số trong Model::variants.
struct VariantUse {
    std::uint32_t variant = 0;
    std::uint32_t material = 0;
};

enum class Topology : std::uint8_t {
    kPoints,
    kLines,
    kLineLoop,
    kLineStrip,
    kTriangles,
    kTriangleStrip,
    kTriangleFan,
};

struct Primitive {
    std::vector<Vertex> vertices;
    std::vector<std::uint32_t> indices;
    std::vector<MorphTarget> targets;
    std::optional<std::uint32_t> material;
    std::vector<VariantUse> variants;
    Topology topology = Topology::kTriangles;
};

struct Mesh {
    std::string name;
    std::vector<Primitive> primitives;
    // Một trọng số mặc định cho mỗi morph target. Rỗng nghĩa là mọi trọng số bằng 0.
    std::vector<float> weights;
};

enum class Filter : std::uint8_t { kNearest, kLinear };

enum class Wrap : std::uint8_t { kRepeat, kMirror, kClamp };

// Bộ lọc glTF. Thiếu trong tệp thì phóng đại tuyến tính, thu nhỏ trilinear, wrap lặp.
// has_mip sai nghĩa là minFilter không có mip (NEAREST hoặc LINEAR): chỉ mức 0.
struct Sampler {
    std::string name;
    Filter mag = Filter::kLinear;
    Filter min = Filter::kLinear;
    Filter mip = Filter::kLinear;
    Wrap wrap_u = Wrap::kRepeat;
    Wrap wrap_v = Wrap::kRepeat;
    bool has_mip = true;
};

// Một khe texture. scale là normalScale hoặc strength; khe khác giữ 1.
// offset, repeat, rotation là KHR_texture_transform. Thiếu thì offset 0, repeat 1, rotation 0.
// uv là TEXCOORD sau khi transform đè, nếu có.
struct TexSlot {
    std::optional<std::uint32_t> image;
    std::optional<std::uint32_t> sampler;
    std::uint32_t uv = 0;
    float scale = 1.0F;
    math::Float2 offset{};
    math::Float2 repeat{.x = 1.0F, .y = 1.0F};
    float rotation = 0.0F;
};

enum class Alpha : std::uint8_t { kOpaque, kMask, kBlend };

// Specular khi tệp có KHR_materials_pbrSpecularGlossiness. Khối metallic vẫn được giữ.
enum class Shading : std::uint8_t { kMetallic, kSpecular };

struct Coat {
    float factor = 0.0F;
    float roughness = 0.0F;
    TexSlot strength{};
    TexSlot roughness_map{};
    TexSlot normal{};
};

struct Transmit {
    float factor = 0.0F;
    TexSlot texture{};
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
