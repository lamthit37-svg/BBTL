// Mô hình glTF, dạng nhị phân GLB là tệp người dùng đưa vào. Một tệp chứa lưới, morph, chất liệu
// PBR (kể cả extension Khronos mà cgltf đã tách), sampler, ảnh PNG hoặc JPEG, nút, xương, clip,
// camera, đèn và biến thể chất liệu. Ảnh giải ra RGBA8. Đầu ra của gltfpack nạp được: lưới lượng
// tử (KHR_mesh_quantization) và buffer view nén (EXT_meshopt_compression). Ảnh DDS ngoài (DXT1,
// DXT3, DXT5, A8R8G8B8) nạp thẳng. Không nạp KTX2, Draco; tệp đòi extension lớp này thì từ chối.
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
#include "resource/tier.hpp"

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
    // Mức mip lớn nhất được lấy mẫu (glTF không có; client đặt cho atlas mặt đất, nơi mip sâu hơn trộn ảnh kề nhau).
    float max_lod = 1000.0F;
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
};

struct Sheen {
    math::Float3 color{};
    float roughness = 0.0F;
    TexSlot color_map{};
    TexSlot roughness_map{};
};

// KHR_materials_specular. factor_map tuyến tính, color_map là sRGB.
struct Specular {
    math::Float3 color{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    float factor = 1.0F;
    TexSlot factor_map{};
    TexSlot color_map{};
};

struct Anisotropy {
    float strength = 0.0F;
    float rotation = 0.0F;
    TexSlot texture{};
};

// distance là mét. max nghĩa là chưa tắt, đúng mặc định của glTF khi không khai.
struct Volume {
    float thickness = 0.0F;
    math::Float3 attenuation{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    float distance = std::numeric_limits<float>::max();
    TexSlot thickness_map{};
};

struct Iridescence {
    float factor = 0.0F;
    float ior = 1.3F;
    float thickness_min = 100.0F;
    float thickness_max = 400.0F;
    TexSlot factor_map{};
    TexSlot thickness_map{};
};

// KHR_materials_diffuse_transmission. color_map là sRGB, factor_map tuyến tính.
struct Scatter {
    float factor = 0.0F;
    math::Float3 color{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    TexSlot factor_map{};
    TexSlot color_map{};
};

// Mặt đất lớp cọ (FairyTerrain của bản gốc): màu mỗi điểm là cọ nền và cọ phủ chọn theo ô của lưới
// địa hình, nhân lightmap; shader tự lấy mẫu từ ảnh cọ gốc nên không có ảnh nướng nào. Cả bốn ảnh là
// dữ liệu thô (RGBA8, không giải mã sRGB): bản gốc lọc và nhân màu thẳng trên số của texture.
// uv của đỉnh là toạ độ thế giới chuẩn hoá trên cả địa hình, (0, 0) ở ô đầu tiên.
struct Splat {
    // Mọi ảnh cọ ghép một tấm, màu đã nhân alpha, mỗi ảnh có viền đệm lặp mép để lọc không rỉ sang ảnh kề.
    TexSlot atlas{};
    // Một texel mỗi ô: pixmap nền và phủ (10 bit mỗi cái), orientation (4 bit mỗi lớp), cờ đường chéo.
    TexSlot cells{};
    // Lightmap phủ cả địa hình, hàng trên cùng là biên z lớn. Không có thì trắng.
    TexSlot light{};
    // Hàng 0: bốn góc theo orientation và cờ đường chéo. Từ hàng 1: hộp pixmap và phép đổi sang atlas.
    TexSlot table{};
};

struct Material {
    std::string name;
    math::Float4 base_color{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
    float metallic = 1.0F;
    float roughness = 1.0F;
    math::Float3 emissive{};
    float emissive_strength = 1.0F;
    Alpha alpha = Alpha::kOpaque;
    float alpha_cutoff = 0.5F;
    bool double_sided = false;
    bool unlit = false;
    Shading shading = Shading::kMetallic;
    TexSlot color{};
    TexSlot surface{};
    TexSlot normal{};
    TexSlot occlusion{};
    TexSlot emissive_map{};
    math::Float4 diffuse{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
    math::Float3 gloss_color{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    float glossiness = 1.0F;
    TexSlot diffuse_map{};
    TexSlot gloss_map{};
    std::optional<float> ior;
    std::optional<float> dispersion;
    std::optional<Coat> coat;
    std::optional<Transmit> transmission;
    std::optional<Sheen> sheen;
    std::optional<Specular> specular;
    std::optional<Anisotropy> anisotropy;
    std::optional<Volume> volume;
    std::optional<Iridescence> iridescence;
    std::optional<Scatter> scatter;
    // JSON extras của glTF, nguyên văn. Engine không đọc. Người gọi diễn giải nếu cần.
    std::string extras;
    // Khi có: shade_of dùng các hệ số này thay cho luật glTF mặc định. Cờ là bit của render::Shade.
    struct Pass {
        math::Float3 ambient{.x = 1.0F, .y = 1.0F, .z = 1.0F};
        math::Float4 diffuse{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
        math::Float3 specular{};
        float shininess = 0.0F;
        math::Float3 emissive{};
        float color_scale = 1.0F;
        std::uint32_t flags = 0;
        bool lit = true;
    };
    std::optional<Pass> pass;
    // Có thì vẽ bằng pipeline địa hình và bỏ qua mọi khe ảnh ở trên.
    std::optional<Splat> splat;
};

// Tịnh tiến, xoay, tỉ lệ đúng như tệp khai. Mặc định là đơn vị của glTF.
// Không có khi nút chỉ khai ma trận: xương của anim/ cần đúng dấu quaternion.
struct NodeParts {
    math::Float3 translation{};
    math::Float4 rotation{.w = 1.0F};
    math::Float3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
};

// Ma trận cột, cùng quy ước Matrix4. Nút không khai biến đổi thì là đơn vị.
struct Node {
    std::string name;
    math::Matrix4 local;
    std::optional<NodeParts> parts;
    std::optional<std::uint32_t> mesh;
    std::optional<std::uint32_t> skin;
    std::optional<std::uint32_t> camera;
    std::optional<std::uint32_t> light;
    std::vector<std::uint32_t> children;
    // Đè trọng số của lưới. Rỗng nghĩa là dùng Mesh::weights.
    std::vector<float> weights;
};

struct Skin {
    std::string name;
    std::optional<std::uint32_t> skeleton;
    std::vector<std::uint32_t> joints;
    std::vector<math::Matrix4> inverse_bind;
};

enum class CameraKind : std::uint8_t { kPerspective, kOrthographic };

// zfar và aspect rỗng nghĩa là glTF không khai: xa vô hạn, tỉ lệ lấy từ khung hình.
struct Perspective {
    std::optional<float> aspect;
    float yfov = 0.0F;
    std::optional<float> zfar;
    float znear = 0.0F;
};

struct Orthographic {
    float xmag = 0.0F;
    float ymag = 0.0F;
    float zfar = 0.0F;
    float znear = 0.0F;
};

struct Camera {
    std::string name;
    CameraKind kind = CameraKind::kPerspective;
    Perspective perspective{};
    Orthographic orthographic{};
};

enum class LightKind : std::uint8_t { kDirectional, kPoint, kSpot };

// range bằng 0 nghĩa là không tắt, đúng khi glTF bỏ trường range.
struct Light {
    std::string name;
    math::Float3 color{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    float intensity = 1.0F;
    LightKind kind = LightKind::kDirectional;
    float range = 0.0F;
    float inner_cone = 0.0F;
    float outer_cone = 0.785398163F;
};

struct Variant {
    std::string name;
};

enum class TrackKind : std::uint8_t { kTranslation, kRotation, kScale, kWeights };

enum class Interpolation : std::uint8_t { kLinear, kStep, kCubic };

// times là giây. values xếp khít, mỗi giá trị rộng: tịnh tiến và tỉ lệ 3 float, xoay 4 float (kiểu
// đã kiểm lúc nạp), trọng số morph thì bằng số morph. Linear và Step ghi một giá trị mỗi khoá;
// Cubic ghi ba: tiếp tuyến vào, giá trị, tiếp tuyến ra. Vậy số morph của kênh Weights là
// values.size() / times.size(), chia tiếp cho 3 khi Cubic. Clip của thư viện motion có thể mang
// kênh Weights cho nút không có lưới (lưới nằm ở tệp model): số morph khi ấy chỉ suy được từ phép
// chia trên, và phải được đối chiếu với lưới thật lúc ghép clip vào model.
struct Track {
    std::uint32_t node = 0;
    TrackKind kind = TrackKind::kTranslation;
    Interpolation interpolation = Interpolation::kLinear;
    std::vector<float> times;
    std::vector<float> values;
};

struct Clip {
    std::string name;
    std::vector<Track> tracks;
};

struct Model {
    std::vector<Mesh> meshes;
    std::vector<Image> images;
    std::vector<Sampler> samplers;
    std::vector<Material> materials;
    std::vector<Camera> cameras;
    std::vector<Light> lights;
    std::vector<Node> nodes;
    std::vector<Skin> skins;
    std::vector<Clip> clips;
    std::vector<Variant> variants;
    // Nút gốc của cảnh mặc định. Không có cảnh thì mọi nút không cha.
    std::vector<std::uint32_t> roots;
};

// `bytes` là cả tệp GLB, hoặc JSON glTF mà buffer nằm trong tệp. Ảnh data-URI nạp được ở đây.
// Ảnh trỏ file cạnh thì dùng load_glb_file.
[[nodiscard]] core::Result<Model> load_glb(std::span<const std::byte> bytes);

// Khác gốc: kiểu mới. Nơi một tệp GLB được tìm ảnh ngoài; gốc chỉ có thư mục của tệp GLB.
struct ImageScope {
    // Thư mục chứa tệp GLB: URI tương đối của ảnh tính từ đây.
    std::string_view directory;
    // Thư mục gốc dữ liệu, ảnh không được nằm ngoài; rỗng thì là directory.
    std::string_view root;
    // Điện thoại thử mobile/astc hoặc mobile/etc2 trước DDS. PC là kBc.
    TextureTier tier = TextureTier::kBc;
};

// Khác gốc: hàm nội bộ của gốc, nay công khai để test. Đường dẫn tệp của ảnh ngoài có URI `uri`
// (còn mã hoá phần trăm); Unsupported khi nó thoát khỏi scope.root, tuyệt đối hay có dấu ':'.
[[nodiscard]] core::Result<std::string> image_path(std::string_view uri, const ImageScope& scope);

// Đọc tệp rồi nạp. Đường dẫn dùng để tìm buffer và ảnh ngoài. Khác gốc: thêm root, thư mục gốc dữ
// liệu mà ảnh ngoài phải nằm trong; rỗng thì như gốc, ảnh phải nằm trong thư mục của tệp GLB.
[[nodiscard]] core::Result<Model> load_glb_file(std::string_view path, std::string_view root = {},
    TextureTier tier = TextureTier::kBc);

} // namespace game::resource
