/*==============================================================================
 *  THIENLONG  |  BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/sky_view.cpp
 *  PHÂN HỆ   : Client / Display
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt sky_view.hpp. Một cbuffer SkyBlock mỗi slot swapchain chứa mọi lệnh của khung
 *    (ô 0 là vòm, ô 1.. là nhóm 59 theo thứ tự vẽ); push constant chỉ mang chỉ số ô. Bố cục
 *    khớp sky.inc.slang.
 *  - Mọi nút của bầu trời nằm tại camera: ma trận nhìn bỏ tịnh tiến, nút chỉ còn độ lệch
 *    tương đối.
 *  - Sao: một bộ đệm đỉnh tĩnh (bốn đỉnh mỗi sao) dựng lúc nhận cảnh; mỗi khung chỉ ghi một ô
 *    SkyBlock (ô cuối). Sao vẽ trước các lớp nhóm 59 (nhóm 57 của bản gốc).
 *  - Vùng: hiện chỉ dùng vùng "backgroud" (hoặc vùng đầu); trộn nhiều vùng theo trọng số
 *    là việc của lượt sau (docs/TAILIEU/EN-SCENE-RENDER-DLL.md).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/sky_view.hpp"

#include "core/error.hpp"
#include "ensky/plan.hpp"
#include "ensky/sky.hpp"
#include "ensky/star.hpp"
#include "gpu/binding.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/resource.hpp"
#include "io/file.hpp"
#include "math/matrix.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"
#include "render/catalog.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/ogre_mesh.hpp"
#include "resource/upload.hpp"
#include "shader/reflection.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <map>
#include <optional>
#include <print>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client {
namespace {

constexpr std::uint32_t kBlockSpace = 0;
constexpr std::uint32_t kTextureSpace = 1;
// Số lệnh trong một SkyBlock; khớp kSkyDraws của sky.inc.slang.
constexpr std::size_t kDraws = 32;
// Ô cuối của SkyBlock thuộc về sao; vòm là ô 0, các lớp nhóm 59 là ô 1 tới kStarCell - 1.
constexpr std::size_t kStarCell = kDraws - 1U;
// Cỡ khung khi camera không khai chiều cao (điểm ảnh), để hình chữ nhật sao không suy biến.
constexpr float kFallbackHeight = 720.0F;
// Hằng cố định của vòm trong Render.dll: TURBIDITY không có trong XML.
constexpr float kDomeTurbidity = 0.2F;
constexpr float kHoursInDay = 24.0F;
// Mây: tile.z do mã ghi đè mỗi khung bằng height * 15 (Render.dll 0x1802e9370).
constexpr float kCloudTileScale = 15.0F;

// Ảnh hằng của vật liệu EnScene/* và mesh vòm của EnDome.
constexpr std::string_view kMieImage = "mie_gradient.dds";
constexpr std::string_view kCloudFogImage = "bmp_overhead_weak_fog.dds";
constexpr std::string_view kRingFogImage = "bmp_horizon_fog_strong.dds";
constexpr std::string_view kDomeMesh = "enskydome.mesh";
constexpr std::string_view kPlaneMesh = "ensky.plane";
constexpr std::string_view kMainRegion = "backgroud";

// misc.x của SkyDraw.
constexpr float kKindDome = 0.0F;
constexpr float kKindCloud = 1.0F;
constexpr float kKindRing = 2.0F;
constexpr float kKindBody = 3.0F;

struct SkyDrawBlock {
    std::array<math::Float4, 4> mvp{};
    math::Float4 world0{};
    math::Float4 world1{};
    math::Float4 world2{};
    math::Float4 a{};
    math::Float4 b{};
    math::Float4 sun{};
    math::Float4 light{};
    math::Float4 rim{};
    math::Float4 fog{};
    math::Float4 control{};
    math::Float4 ambient{};
    math::Float4 misc{};
};
static_assert(sizeof(SkyDrawBlock) == 256);

struct SkyBlock {
    std::array<SkyDrawBlock, kDraws> draws{};
};
static_assert(sizeof(SkyBlock) == render::kSkyFrameBytes);

// Đỉnh sao: khớp render::kStarStride, kStarCorner, kStarColour và location của star.vs.slang.
struct StarVertex {
    std::array<float, 3> position{};
    std::array<float, 2> corner{};
    std::array<float, 4> colour{};
};
static_assert(sizeof(StarVertex) == render::kStarStride);
static_assert(offsetof(StarVertex, corner) == render::kStarCorner);
static_assert(offsetof(StarVertex, colour) == render::kStarColour);

// Bốn góc của hình chữ nhật mỗi sao theo thứ tự chữ Z, như fx: (0,0) (1,0) (0,1) (1,1).
constexpr std::array<std::array<float, 2>, 4> kStarCorners{
    {{0.0F, 0.0F}, {1.0F, 0.0F}, {0.0F, 1.0F}, {1.0F, 1.0F}}};
constexpr std::array<std::uint32_t, 6> kStarQuad{0, 1, 2, 2, 1, 3};

struct SkyPush {
    std::array<std::uint32_t, 4> slot{};
};
static_assert(sizeof(SkyPush) == render::kSkyDrawBytes);

// Kiểu địa chỉ ảnh (U, V): lặp cả hai, lặp U kẹp V, kẹp cả hai.
enum class Wrapping : std::uint8_t { kRepeat, kRepeatClamp, kClamp };
constexpr std::size_t kWrappings = 3;

struct Texture {
    resource::Uploaded uploaded;
    gpu::TextureViewHandle view{};
};

struct TextureSet {
    std::array<std::string, 3> names;
    std::array<Wrapping, 3> wraps{};
};

[[nodiscard]] math::Float4 four(float red, float green, float blue, float alpha) noexcept {
    return math::Float4{.x = red, .y = green, .z = blue, .w = alpha};
}

[[nodiscard]] math::Float4 four(const ensky::Colour& colour, float alpha) noexcept {
    return four(colour.red, colour.green, colour.blue, alpha);
}

[[nodiscard]] math::Float4 four(const ogre::Vec3& value, float alpha) noexcept {
    return four(value.x, value.y, value.z, alpha);
}

[[nodiscard]] math::Quat quat_of(const ogre::Quat& value) noexcept {
    return {value.x, value.y, value.z, value.w};
}

[[nodiscard]] math::Vector3 vector_of(const ogre::Vec3& value) noexcept {
    return {value.x, value.y, value.z};
}

// T(offset) * R(orientation) * S(scale) của nút cảnh, tương đối với camera.
[[nodiscard]] math::Matrix4 node_matrix(const ensky::Draw& draw) noexcept {
    const math::Matrix4 place(quat_of(draw.orientation), vector_of(draw.offset));
    const math::Matrix4 grow = math::Matrix4::scale(vector_of(draw.scale));
    return place * grow;
}

[[nodiscard]] math::Float4 row_of(const math::Matrix4& matrix, std::size_t index) noexcept {
    math::Float4 row = math::store(matrix.row(index));
    row.w = 0.0F;
    return row;
}

// Ba hàng của R * S: hướng của đỉnh trong thế giới (không tịnh tiến).
void put_world(SkyDrawBlock& block, const ensky::Draw& draw) noexcept {
    const math::Matrix4 turn = math::Matrix4::rotation(quat_of(draw.orientation));
    const math::Matrix4 grow = math::Matrix4::scale(vector_of(draw.scale));
    const math::Matrix4 linear = turn * grow;
    block.world0 = row_of(linear, 0);
    block.world1 = row_of(linear, 1);
    block.world2 = row_of(linear, 2);
}

// Ma trận nhìn của camera bỏ tịnh tiến: bầu trời đứng tại camera.
[[nodiscard]] math::Matrix4 rotation_only(const math::Matrix4& view) noexcept {
    math::Matrix4 rotated = view;
    rotated.set_translation(math::Vector3(0.0F));
    return rotated;
}

// Độ cao mắt trong thế giới = y của cột tịnh tiến của nghịch đảo ma trận nhìn.
[[nodiscard]] float eye_height(const math::Matrix4& view) noexcept {
    const math::Matrix4 camera = math::affine_inverse(view);
    return camera.at(3, 1);
}

// Địa chỉ ảnh của mây vòng: V kẹp khi vOffset bằng 0, lặp khi khác 0 (Render.dll 0x18023bf50).
[[nodiscard]] Wrapping ring_wrapping(const ensky::RingLive& live) noexcept {
    return live.v_offset == 0.0F ? Wrapping::kRepeatClamp : Wrapping::kRepeat;
}

[[nodiscard]] std::string image_file(std::string_view name) {
    std::string path = "Material/";
    path.append(name);
    const bool is_targa = name.size() > 4 && name.substr(name.size() - 4) == ".tga";
    if (is_targa) path.append(".png");
    return path;
}

[[nodiscard]] gpu::AddressMode address_of(bool repeats) noexcept {
    return repeats ? gpu::AddressMode::kRepeat : gpu::AddressMode::kClampToEdge;
}

void bind_texture(std::array<gpu::BindEntry, 6>& entries, std::uint32_t unit,
    gpu::TextureViewHandle view, gpu::SamplerHandle sampler) {
    const std::size_t base = static_cast<std::size_t>(unit) * 2U;
    entries.at(base).type = shader::RegisterType::kResource;
    entries.at(base).slot = unit;
    entries.at(base).resource = view;
    entries.at(base + 1).type = shader::RegisterType::kSampler;
    entries.at(base + 1).slot = unit;
    entries.at(base + 1).resource = sampler;
}

// Góc của PT_PLANE: dấu của x, dấu của y (nhân nửa cạnh), rồi u, v.
using PlaneCorner = std::array<float, 4>;
constexpr std::array<PlaneCorner, 4> kPlaneCorners{{{-1.0F, -1.0F, 0.0F, 1.0F},
    {1.0F, -1.0F, 1.0F, 1.0F}, {-1.0F, 1.0F, 0.0F, 0.0F}, {1.0F, 1.0F, 1.0F, 0.0F}}};

[[nodiscard]] resource::Vertex corner_of(const PlaneCorner& corner, float half) {
    resource::Vertex vertex;
    vertex.position = {.x = corner[0] * half, .y = corner[1] * half, .z = 0.0F};
    vertex.normal = {.x = 0.0F, .y = 0.0F, .z = 1.0F};
    vertex.uv = {.x = corner[2], .y = corner[3]};
    return vertex;
}

// PT_PLANE của Ogre: 100 x 100, pháp tuyến +Z; chỉ số (0,1,2), (1,3,2).
[[nodiscard]] resource::Model plane_model() {
    const float half = ensky::kPlaneSize * 0.5F;
    resource::Primitive primitive;
    for (const PlaneCorner& corner : kPlaneCorners) {
        primitive.vertices.push_back(corner_of(corner, half));
    }
    primitive.indices = {0, 1, 2, 1, 3, 2};
    resource::Mesh mesh;
    mesh.name = std::string(kPlaneMesh);
    mesh.primitives.push_back(std::move(primitive));
    resource::Model model;
    model.meshes.push_back(std::move(mesh));
    return model;
}

// Khoá nhóm ảnh: tên ba ảnh và kiểu địa chỉ của từng ảnh.
[[nodiscard]] std::string key_of(const TextureSet& set) {
    const std::string names = std::format("{}|{}|{}", set.names[0], set.names[1], set.names[2]);
    const int first = static_cast<int>(set.wraps[0]);
    const int second = static_cast<int>(set.wraps[1]);
    const int third = static_cast<int>(set.wraps[2]);
    return std::format("{}|{}{}{}", names, first, second, third);
}

[[nodiscard]] core::Result<resource::Image> read_image(const std::string& file) {
    const io::TextResult bytes = io::read_text(io::path_from_utf8(file));
    if (!bytes) {
        const std::string_view why = io::describe(bytes.error());
        return core::fail(core::ErrorCode::kNotFound, "không đọc được ảnh", why);
    }
    const std::span<const char> text(*bytes);
    const std::span<const std::byte> raw = std::as_bytes(text);
    return resource::read_stored(raw);
}

[[nodiscard]] const ensky::Region& main_region(const ensky::Scene& scene) {
    const auto is_main = [](const ensky::Region& region) { return region.name == kMainRegion; };
    const auto found = std::ranges::find_if(scene.regions, is_main);
    return found != scene.regions.end() ? *found : scene.regions.front();
}

} // namespace

struct SkyView::Body {
    gpu::Device* device = nullptr;
    SkyPipelines pipelines;
    std::filesystem::path data_root;
    resource::TextureTier tier = resource::TextureTier::kBc;
    std::array<gpu::SamplerHandle, kWrappings> samplers{};
    // Mỗi slot swapchain một cbuffer và nhóm gắn nó (space 0).
    std::vector<gpu::BufferHandle> block_buffers;
    std::vector<gpu::BindGroupHandle> block_groups;
    std::map<std::string, std::optional<Texture>, std::less<>> textures;
    std::map<std::string, std::optional<resource::Uploaded>, std::less<>> meshes;
    std::map<std::string, gpu::BindGroupHandle, std::less<>> texture_groups;
    std::set<std::string, std::less<>> complained;
    // Playback giữ con trỏ vào scene: scene đứng yên trên heap cho tới khi adopt cảnh khác.
    std::unique_ptr<ensky::Scene> scene;
    std::optional<ensky::Playback> playback;
    ensky::DayClock clock;
    std::vector<ensky::Draw> plan;
    bool has_dome_ready = false;
    bool is_raw_color = false;
    // Sao: bộ đệm đỉnh và chỉ số tĩnh của cảnh hiện tại; star_indices = 0 khi không có sao để vẽ.
    gpu::BufferHandle star_vertices{};
    gpu::BufferHandle star_index_buffer{};
    std::uint32_t star_indices = 0;

    Body() = default;
    Body(const Body&) = delete;
    Body& operator=(const Body&) = delete;
    Body(Body&&) = delete;
    Body& operator=(Body&&) = delete;
    ~Body();

    void complain(const std::string& what, std::string_view why);
    [[nodiscard]] core::Status make_samplers();
    [[nodiscard]] core::Status make_slot(std::uint32_t slot);
    [[nodiscard]] const Texture* texture_of(std::string_view name);
    [[nodiscard]] const resource::Uploaded* mesh_of(std::string_view name);
    [[nodiscard]] std::optional<gpu::BindGroupHandle> group_of(const TextureSet& set);
    [[nodiscard]] core::Result<Texture> load_texture(std::string_view name) const;
    [[nodiscard]] core::Result<resource::Uploaded> load_mesh(std::string_view name) const;
    void warm();
    void release_stars();
    [[nodiscard]] core::Status build_stars();
    void fill_star(SkyDrawBlock& block, const math::Matrix4& view_proj,
        const render::Camera& camera) const;
    void draw_stars(gpu::CommandList& list, std::uint32_t slot);
    void fill_light(SkyDrawBlock& block) const;
    void fill_dome(SkyDrawBlock& block, const math::Matrix4& view_proj) const;
    void fill_cloud(SkyDrawBlock& block, const ensky::Draw& draw) const;
    void fill_ring(SkyDrawBlock& block, const ensky::Draw& draw, float eye_y) const;
    void fill_layer(SkyDrawBlock& block, const ensky::Draw& draw, const math::Matrix4& view_proj,
        float eye_y) const;
    [[nodiscard]] TextureSet dome_set() const;
    [[nodiscard]] std::optional<TextureSet> layer_set(const ensky::Draw& draw) const;
    [[nodiscard]] std::string_view mesh_name(const ensky::Draw& draw) const;
    void draw_layer(gpu::CommandList& list, std::uint32_t slot, const ensky::Draw& draw,
        std::uint32_t cell);
};

namespace {

void fill_rim(SkyDrawBlock& block, const ensky::Rim& rim) noexcept {
    block.sun.w = rim.scatter_strength;
    block.light.w = rim.scatter_power;
    block.rim = four(rim.strength, rim.power, rim.detect_power, rim.detect_width);
}

void draw_primitive(gpu::CommandList& list, const resource::GpuPrimitive& primitive) {
    list.bind_vertex_buffer(0, primitive.vertices, 0);
    list.bind_index_buffer(primitive.indices, gpu::IndexType::kUint32, 0);
    gpu::DrawIndexedArguments arguments;
    arguments.index_count = primitive.index_count;
    list.draw_indexed(arguments);
}

void draw_part(gpu::CommandList& list, const resource::GpuMesh& part) {
    for (const resource::GpuPrimitive& primitive : part.primitives) {
        draw_primitive(list, primitive);
    }
}

// Ghi một lệnh vẽ: mesh có thể gồm nhiều primitive, cùng một ô cbuffer.
void record(gpu::CommandList& list, std::uint32_t cell, const resource::Uploaded& mesh) {
    const SkyPush push{.slot = {cell, 0, 0, 0}};
    const std::span<const SkyPush> one(&push, 1);
    list.push_constants(std::as_bytes(one), 0);
    for (const resource::GpuMesh& part : mesh.meshes()) {
        draw_part(list, part);
    }
}

// Mỗi sao bốn đỉnh cùng vị trí và màu, khác góc; sáu chỉ số cho hai tam giác.
void push_star(const ensky::StarPoint& point, std::uint32_t base, std::vector<StarVertex>& vertices,
    std::vector<std::uint32_t>& indices) {
    StarVertex vertex{.position = point.position, .corner = {}, .colour = point.colour};
    for (const std::array<float, 2>& corner : kStarCorners) {
        vertex.corner = corner;
        vertices.push_back(vertex);
    }
    for (const std::uint32_t step : kStarQuad) {
        indices.push_back(base + step);
    }
}

} // namespace

SkyView::Body::~Body() {
    if (device == nullptr) return;
    release_stars();
    for (const auto& [key, group] : texture_groups) {
        device->destroy(group);
    }
    for (const gpu::BindGroupHandle group : block_groups) {
        device->destroy(group);
    }
    for (const gpu::BufferHandle buffer : block_buffers) {
        device->destroy(buffer);
    }
    for (const gpu::SamplerHandle sampler : samplers) {
        device->destroy(sampler);
    }
}

void SkyView::Body::complain(const std::string& what, std::string_view why) {
    if (!complained.insert(what).second) return;
    std::println(stderr, "Bầu trời: bỏ {}: {}", what, why);
}

core::Status SkyView::Body::make_samplers() {
    constexpr std::array<std::array<bool, 2>, kWrappings> kRepeats{
        {{true, true}, {true, false}, {false, false}}};
    for (std::size_t index = 0; index < kWrappings; ++index) {
        gpu::SamplerDesc desc;
        desc.name = "sky.sampler";
        desc.address_u = address_of(kRepeats.at(index)[0]);
        desc.address_v = address_of(kRepeats.at(index)[1]);
        const core::Result<gpu::SamplerHandle> made = device->create_sampler(desc);
        if (!made) return std::unexpected(made.error());
        samplers.at(index) = *made;
    }
    return core::ok();
}

core::Status SkyView::Body::make_slot(std::uint32_t slot) {
    if (slot < block_buffers.size() && block_buffers.at(slot)) return core::ok();
    gpu::BufferDesc buffer;
    buffer.name = "sky.block";
    buffer.size = sizeof(SkyBlock);
    buffer.usage = gpu::BufferUsage::kUniform;
    buffer.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made = device->create_buffer(buffer);
    if (!made) return std::unexpected(made.error());
    std::array<gpu::BindEntry, 1> entry;
    entry.at(0).type = shader::RegisterType::kConstant;
    entry.at(0).resource = gpu::BufferRange{.buffer = *made};
    gpu::BindGroupDesc group;
    group.name = "sky.block";
    group.pipeline = pipelines.dome;
    group.space = kBlockSpace;
    group.entries = entry;
    const core::Result<gpu::BindGroupHandle> bound = device->create_bind_group(group);
    if (!bound) {
        device->destroy(*made);
        return std::unexpected(bound.error());
    }
    const std::size_t count = std::size_t{slot} + 1U;
    if (block_buffers.size() < count) block_buffers.resize(count);
    if (block_groups.size() < count) block_groups.resize(count);
    block_buffers.at(slot) = *made;
    block_groups.at(slot) = *bound;
    return core::ok();
}

core::Result<Texture> SkyView::Body::load_texture(std::string_view name) const {
    const std::string root = io::utf8_of(data_root);
    const std::string file = resource::texture_file(root, image_file(name), tier);
    core::Result<resource::Image> image = read_image(file);
    if (!image) return std::unexpected(image.error());
    image->name = std::string(name);
    resource::Model model;
    model.images.push_back(std::move(*image));
    // Không chất liệu nào nhắc tới ảnh: nạp thô (UNORM), shader tự tính trong không gian gamma.
    core::Result<resource::Uploaded> uploaded = resource::upload_queued(*device, model);
    if (!uploaded) return std::unexpected(uploaded.error());
    const bool has_image = !uploaded->images().empty();
    if (!has_image) return core::fail(core::ErrorCode::kInvalidArgument, "thiếu ảnh sau nạp");
    const gpu::TextureViewHandle view = uploaded->images().front().view;
    return Texture{.uploaded = std::move(*uploaded), .view = view};
}

const Texture* SkyView::Body::texture_of(std::string_view name) {
    const auto found = textures.find(name);
    if (found != textures.end()) return found->second ? &*found->second : nullptr;
    core::Result<Texture> loaded = load_texture(name);
    if (!loaded) complain(std::string(name), loaded.error().message());
    std::optional<Texture> kept;
    if (loaded) kept = std::move(*loaded);
    const auto inserted = textures.emplace(std::string(name), std::move(kept));
    return inserted.first->second ? &*inserted.first->second : nullptr;
}

core::Result<resource::Uploaded> SkyView::Body::load_mesh(std::string_view name) const {
    const std::string root = io::utf8_of(data_root);
    const bool is_plane = name == kPlaneMesh;
    core::Result<resource::Model> model =
        is_plane ? plane_model() : resource::load_named_model(name, root, tier);
    if (!model) return std::unexpected(model.error());
    return resource::upload_queued(*device, *model);
}

const resource::Uploaded* SkyView::Body::mesh_of(std::string_view name) {
    const auto found = meshes.find(name);
    if (found != meshes.end()) return found->second ? &*found->second : nullptr;
    core::Result<resource::Uploaded> loaded = load_mesh(name);
    if (!loaded) complain(std::string(name), loaded.error().message());
    std::optional<resource::Uploaded> kept;
    if (loaded) kept = std::move(*loaded);
    const auto inserted = meshes.emplace(std::string(name), std::move(kept));
    return inserted.first->second ? &*inserted.first->second : nullptr;
}

std::optional<gpu::BindGroupHandle> SkyView::Body::group_of(const TextureSet& set) {
    const std::string key = key_of(set);
    const auto found = texture_groups.find(key);
    if (found != texture_groups.end()) return found->second;
    std::array<gpu::BindEntry, 6> entries;
    for (std::uint32_t unit = 0; unit < 3; ++unit) {
        const Texture* texture = texture_of(set.names.at(unit));
        if (texture == nullptr) return std::nullopt;
        const auto mode = static_cast<std::size_t>(set.wraps.at(unit));
        bind_texture(entries, unit, texture->view, samplers.at(mode));
    }
    gpu::BindGroupDesc group;
    group.name = "sky.textures";
    group.pipeline = pipelines.dome;
    group.space = kTextureSpace;
    group.entries = entries;
    const core::Result<gpu::BindGroupHandle> bound = device->create_bind_group(group);
    if (!bound) {
        complain(key, bound.error().message());
        return std::nullopt;
    }
    texture_groups.emplace(key, *bound);
    return *bound;
}

TextureSet SkyView::Body::dome_set() const {
    const ensky::Dome& dome = playback->sky().dome;
    const std::string& ray_ex = dome.texture_ex.empty() ? dome.texture : dome.texture_ex;
    TextureSet set;
    set.names = {std::string(kMieImage), dome.texture, ray_ex};
    set.wraps = {Wrapping::kRepeat, Wrapping::kRepeatClamp, Wrapping::kRepeatClamp};
    return set;
}

std::optional<TextureSet> SkyView::Body::layer_set(const ensky::Draw& draw) const {
    const ensky::Sky& sky = playback->sky();
    TextureSet set;
    if (draw.kind == ensky::Kind::kCloud) {
        const std::string& map = sky.clouds.at(draw.index).texture;
        set.names = {map, std::string(kCloudFogImage), std::string(kCloudFogImage)};
        set.wraps = {Wrapping::kRepeat, Wrapping::kClamp, Wrapping::kClamp};
        return set;
    }
    if (draw.kind == ensky::Kind::kRing) {
        const std::string& map = sky.rings.at(draw.index).texture;
        const Wrapping across = ring_wrapping(playback->rings()[draw.index]);
        set.names = {map, std::string(kRingFogImage), std::string(kRingFogImage)};
        set.wraps = {across, Wrapping::kRepeatClamp, Wrapping::kRepeatClamp};
        return set;
    }
    const bool is_moon = draw.kind == ensky::Kind::kMoon;
    const std::string& body = is_moon ? sky.moon.texture : sky.sun.texture;
    set.names = {body, body, body};
    set.wraps = {Wrapping::kRepeat, Wrapping::kRepeat, Wrapping::kRepeat};
    return set;
}

std::string_view SkyView::Body::mesh_name(const ensky::Draw& draw) const {
    const ensky::Sky& sky = playback->sky();
    if (draw.kind == ensky::Kind::kCloud) return sky.clouds.at(draw.index).mesh;
    if (draw.kind == ensky::Kind::kRing) return sky.rings.at(draw.index).mesh;
    return kPlaneMesh;
}

// Nạp trước mọi ảnh và mesh của cảnh để khung đầu không đọc đĩa giữa chừng.
void SkyView::Body::warm() {
    const bool has_mesh = mesh_of(kDomeMesh) != nullptr;
    const std::optional<gpu::BindGroupHandle> group = group_of(dome_set());
    has_dome_ready = has_mesh && group.has_value();
    for (const ensky::Draw& draw : ensky::plan_of(*playback)) {
        const std::optional<TextureSet> set = layer_set(draw);
        if (set) static_cast<void>(group_of(*set));
        static_cast<void>(mesh_of(mesh_name(draw)));
    }
}

void SkyView::Body::release_stars() {
    device->destroy(star_vertices);
    device->destroy(star_index_buffer);
    star_vertices = {};
    star_index_buffer = {};
    star_indices = 0;
}

// Dựng bộ đệm tĩnh từ đám sao của cảnh; bộ đệm upload ghi một lần, lúc chưa có khung nào dùng nó.
core::Status SkyView::Body::build_stars() {
    release_stars();
    const bool is_wanted = pipelines.star && playback->star().is_enabled();
    if (!is_wanted) return core::ok();
    const std::vector<ensky::StarPoint> points = playback->star().build();
    if (points.empty()) return core::ok();
    std::vector<StarVertex> vertices;
    std::vector<std::uint32_t> indices;
    vertices.reserve(points.size() * kStarCorners.size());
    indices.reserve(points.size() * kStarQuad.size());
    for (const ensky::StarPoint& point : points) {
        const auto base = static_cast<std::uint32_t>(vertices.size());
        push_star(point, base, vertices, indices);
    }
    gpu::BufferDesc vertex_desc;
    vertex_desc.name = "sky.star.vertices";
    vertex_desc.size = vertices.size() * sizeof(StarVertex);
    vertex_desc.usage = gpu::BufferUsage::kVertex;
    vertex_desc.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made_vertices = device->create_buffer(vertex_desc);
    if (!made_vertices) return std::unexpected(made_vertices.error());
    star_vertices = *made_vertices;
    gpu::BufferDesc index_desc;
    index_desc.name = "sky.star.indices";
    index_desc.size = indices.size() * sizeof(std::uint32_t);
    index_desc.usage = gpu::BufferUsage::kIndex;
    index_desc.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made_indices = device->create_buffer(index_desc);
    if (!made_indices) return std::unexpected(made_indices.error());
    star_index_buffer = *made_indices;
    const std::span<const StarVertex> vertex_span(vertices);
    const std::span<const std::uint32_t> index_span(indices);
    const auto vertex_bytes = std::as_bytes(vertex_span);
    const auto index_bytes = std::as_bytes(index_span);
    const core::Status wrote_vertices = device->write_buffer(star_vertices, 0, vertex_bytes);
    if (!wrote_vertices) return wrote_vertices;
    const core::Status wrote_indices = device->write_buffer(star_index_buffer, 0, index_bytes);
    if (!wrote_indices) return wrote_indices;
    star_indices = static_cast<std::uint32_t>(indices.size());
    return core::ok();
}

// Ô sao: StarSize = (cỡ, cỡ, 0, nhấp nháy), StarParams = (độ mạnh, độ hiện) và cỡ khung theo
// điểm ảnh (cỡ sprite của bản gốc tính bằng điểm ảnh của backbuffer).
void SkyView::Body::fill_star(SkyDrawBlock& block, const math::Matrix4& view_proj,
    const render::Camera& camera) const {
    const ensky::StarField& star = playback->star();
    const float height = camera.pixels_high > 0.0F ? camera.pixels_high : kFallbackHeight;
    const float across = std::abs(camera.projection.at(0, 0));
    const float up = std::abs(camera.projection.at(1, 1));
    const float width = across > 0.0F ? height * (up / across) : height;
    block.mvp = math::store(view_proj);
    block.a = four(star.size(), star.size(), 0.0F, star.flicker());
    block.b = four(star.intensity(), star.visibility(), width, height);
    block.misc = four(0.0F, 0.0F, is_raw_color ? 1.0F : 0.0F, 0.0F);
}

void SkyView::Body::draw_stars(gpu::CommandList& list, std::uint32_t slot) {
    const bool is_ready = star_indices > 0 && playback->star().is_shown();
    if (!is_ready) return;
    list.bind_pipeline(pipelines.star);
    list.bind_group(kBlockSpace, block_groups.at(slot));
    const SkyPush push{.slot = {static_cast<std::uint32_t>(kStarCell), 0, 0, 0}};
    const std::span<const SkyPush> one(&push, 1);
    list.push_constants(std::as_bytes(one), 0);
    list.bind_vertex_buffer(0, star_vertices, 0);
    list.bind_index_buffer(star_index_buffer, gpu::IndexType::kUint32, 0);
    gpu::DrawIndexedArguments arguments;
    arguments.index_count = star_indices;
    list.draw_indexed(arguments);
}

void SkyView::Body::fill_light(SkyDrawBlock& block) const {
    const ensky::EnvKey& env = playback->env();
    const float raw = is_raw_color ? 1.0F : 0.0F;
    block.sun = four(playback->sun().toward, 0.0F);
    block.light = four(env.light_one, 0.0F);
    block.fog = four(env.fog, 0.0F);
    block.ambient = four(env.ambient, 1.0F);
    block.misc = four(0.0F, 1.0F, raw, 0.0F);
}

void SkyView::Body::fill_dome(SkyDrawBlock& block, const math::Matrix4& view_proj) const {
    const ensky::Dome& dome = playback->sky().dome;
    const ensky::EnvKey& env = playback->env();
    fill_light(block);
    block.mvp = math::store(view_proj);
    block.a = four(playback->hour() / kHoursInDay, dome.height, dome.mie_amount, kDomeTurbidity);
    block.b = four(dome.vertex_height_effect, dome.sun_height_effect, dome.power, 0.0F);
    block.ambient = four(env.dome_ambient, env.dome_strength);
    block.misc.x = kKindDome;
}

void SkyView::Body::fill_cloud(SkyDrawBlock& block, const ensky::Draw& draw) const {
    const ensky::CloudLayer& layer = playback->sky().clouds.at(draw.index);
    const ensky::CloudLive& live = playback->clouds()[draw.index];
    const float depth = layer.height * kCloudTileScale;
    block.misc.x = kKindCloud;
    block.a = four(layer.tile[0], layer.tile[1], depth, layer.tile[3]);
    block.b = four(live.wind, 0.0F, 0.0F, 0.0F);
    block.control = four(live.fog, live.speed, live.ambient_blend, live.alpha);
    fill_rim(block, layer.rim);
}

void SkyView::Body::fill_ring(SkyDrawBlock& block, const ensky::Draw& draw, float eye_y) const {
    const ensky::RingLayer& layer = playback->sky().rings.at(draw.index);
    const ensky::RingLive& live = playback->rings()[draw.index];
    block.misc.x = kKindRing;
    block.a = four(layer.repeat, live.v_offset, layer.parallax, 1.0F);
    block.b = four(0.0F, eye_y, 0.0F, 0.0F);
    block.control = four(live.fog_blend, live.fade_range, live.ambient_blend, live.alpha);
    fill_rim(block, layer.rim);
}

void SkyView::Body::fill_layer(SkyDrawBlock& block, const ensky::Draw& draw,
    const math::Matrix4& view_proj, float eye_y) const {
    fill_light(block);
    block.mvp = math::store(view_proj * node_matrix(draw));
    put_world(block, draw);
    block.misc.x = kKindBody;
    if (draw.kind == ensky::Kind::kCloud) fill_cloud(block, draw);
    if (draw.kind == ensky::Kind::kRing) fill_ring(block, draw, eye_y);
}

void SkyView::Body::draw_layer(gpu::CommandList& list, std::uint32_t slot, const ensky::Draw& draw,
    std::uint32_t cell) {
    const std::optional<TextureSet> set = layer_set(draw);
    if (!set) return;
    const std::optional<gpu::BindGroupHandle> group = group_of(*set);
    const resource::Uploaded* mesh = mesh_of(mesh_name(draw));
    if (!group || mesh == nullptr) return;
    const bool is_body = draw.kind == ensky::Kind::kMoon || draw.kind == ensky::Kind::kSun;
    list.bind_pipeline(is_body ? pipelines.body : pipelines.cloud);
    list.bind_group(kBlockSpace, block_groups.at(slot));
    list.bind_group(kTextureSpace, *group);
    record(list, cell, *mesh);
}

SkyView::SkyView(std::unique_ptr<Body> body) : body_(std::move(body)) {}
SkyView::SkyView(SkyView&&) noexcept = default;
SkyView& SkyView::operator=(SkyView&&) noexcept = default;
SkyView::~SkyView() = default;

std::unique_ptr<SkyView> SkyView::open(gpu::Device& device, const SkyPipelines& pipelines) {
    const bool has_all = pipelines.dome && pipelines.cloud && pipelines.body;
    if (!has_all) {
        std::println(stderr, "Bầu trời: bỏ qua, không dựng được bộ vẽ");
        return nullptr;
    }
    auto body = std::make_unique<Body>();
    body->device = &device;
    body->pipelines = pipelines;
    body->is_raw_color = device.caps().is_raw_color;
    const core::Status sampled = body->make_samplers();
    if (!sampled) {
        std::println(stderr, "Bầu trời: bỏ qua, không tạo được sampler: {}", sampled.error());
        return nullptr;
    }
    return std::unique_ptr<SkyView>(new SkyView(std::move(body)));
}

void SkyView::load(const std::filesystem::path& data_root, resource::TextureTier tier) {
    body_->data_root = data_root;
    body_->tier = tier;
}

bool SkyView::adopt(const Stage& stage) {
    Body& body = *body_;
    body.playback.reset();
    body.scene.reset();
    body.plan.clear();
    body.has_dome_ready = false;
    body.release_stars();
    if (stage.en_scene.empty()) return false;
    const std::filesystem::path name = io::path_from_utf8(stage.en_scene);
    const io::TextResult bytes = io::read_text(body.data_root / "Scene" / name);
    if (!bytes) {
        body.complain(stage.en_scene, io::describe(bytes.error()));
        return false;
    }
    std::expected<ensky::Scene, ensky::Fault> read = ensky::read_scene(*bytes);
    if (!read || read->regions.empty()) {
        body.complain(stage.en_scene, "tệp .EnScene hỏng hoặc không có bầu trời");
        return false;
    }
    body.scene = std::make_unique<ensky::Scene>(std::move(*read));
    const ensky::Region& region = main_region(*body.scene);
    body.playback.emplace(region.sky);
    body.playback->update({.seconds = 0.0F, .hour = body.clock.hour()});
    body.warm();
    const core::Status stars = body.build_stars();
    if (!stars) body.complain("sao", stars.error().message());
    const std::string dome = body.has_dome_ready ? "có" : "không";
    std::println("Bầu trời: {} ({} lớp mây, {} mây vòng, vòm {}, giờ {:.2f})", stage.en_scene,
        region.sky.clouds.size(), region.sky.rings.size(), dome, body.clock.hour());
    return true;
}

void SkyView::pin_day(float fraction) {
    body_->clock.pin(fraction);
}

void SkyView::run_day() {
    body_->clock.run();
}

float SkyView::day_fraction() const {
    return body_->clock.fraction();
}

void SkyView::advance(float seconds) {
    Body& body = *body_;
    body.clock.advance(seconds);
    if (body.playback) body.playback->update({.seconds = seconds, .hour = body.clock.hour()});
}

bool SkyView::has_sky() const {
    return body_->playback.has_value();
}

std::optional<ensky::EnvKey> SkyView::env() const {
    if (!body_->playback || !body_->playback->has_env()) return std::nullopt;
    return body_->playback->env();
}

std::span<const std::string> SkyView::effects() const {
    if (!body_->playback) return {};
    return body_->playback->sky().effects;
}

std::uint32_t SkyView::env_serial() const {
    if (!body_->playback || !body_->playback->has_env()) return 0;
    return body_->playback->retimes();
}

void SkyView::prepare(std::uint32_t slot, const render::Camera& camera) {
    Body& body = *body_;
    if (!body.playback) return;
    const core::Status made = body.make_slot(slot);
    if (!made) {
        body.complain("cbuffer", made.error().message());
        return;
    }
    const math::Matrix4 view_proj = camera.projection * rotation_only(camera.view);
    const float eye_y = eye_height(camera.view);
    body.plan = ensky::plan_of(*body.playback);
    if (body.plan.size() + 1U > kStarCell) {
        body.plan.resize(kStarCell - 1U);
        body.complain("lệnh vẽ", "quá 30 lớp trong một khung");
    }
    SkyBlock block;
    body.fill_dome(block.draws.at(0), view_proj);
    for (std::size_t index = 0; index < body.plan.size(); ++index) {
        SkyDrawBlock& cell = block.draws.at(index + 1U);
        body.fill_layer(cell, body.plan.at(index), view_proj, eye_y);
    }
    if (body.star_indices > 0) body.fill_star(block.draws.at(kStarCell), view_proj, camera);
    const auto bytes = std::as_bytes(std::span(&block, 1));
    const gpu::BufferHandle target = body.block_buffers.at(slot);
    const core::Status written = body.device->write_buffer(target, 0, bytes);
    if (!written) body.complain("ghi cbuffer", written.error().message());
}

void SkyView::draw_dome(gpu::CommandList& list, std::uint32_t slot) {
    Body& body = *body_;
    const bool is_ready = body.playback && body.has_dome_ready && slot < body.block_groups.size();
    if (!is_ready) return;
    const resource::Uploaded* mesh = body.mesh_of(kDomeMesh);
    const std::optional<gpu::BindGroupHandle> group = body.group_of(body.dome_set());
    if (mesh == nullptr || !group) return;
    list.bind_pipeline(body.pipelines.dome);
    list.bind_group(kBlockSpace, body.block_groups.at(slot));
    list.bind_group(kTextureSpace, *group);
    record(list, 0, *mesh);
}

void SkyView::draw_layers(gpu::CommandList& list, std::uint32_t slot) {
    Body& body = *body_;
    const bool is_ready = body.playback && slot < body.block_groups.size();
    if (!is_ready) return;
    body.draw_stars(list, slot);
    for (std::size_t index = 0; index < body.plan.size(); ++index) {
        const auto cell = static_cast<std::uint32_t>(index + 1U);
        body.draw_layer(list, slot, body.plan.at(index), cell);
    }
}

} // namespace game::client
