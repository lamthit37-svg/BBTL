// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
// Bốn pipeline cùng shader, cùng bố cục gắn: bit 0 của chỉ số là chất liệu hai mặt (không loại mặt
// sau), bit 1 là trộn alpha (không ghi độ sâu). Register space của shader: 0 là hằng của khung, 1
// là chất liệu, 2 là bảng khớp và ma trận instanced; hằng của lệnh vẽ đi bằng push constant.
// Một khung: gom lệnh vẽ của mọi instance (dựng bảng khớp của từng skin một lần), ghi buffer của
// slot, xếp lệnh (đục trước, trộn alpha sau và xa trước), rồi mới ghi lệnh.
// Đèn điểm chọn như Ogre chọn cho shader ba đèn của bản gốc: sau hai đèn chính là đèn điểm gần gốc
// vật thể nhất mà tầm của nó cộng bán kính bao còn với tới. Bản sao instanced của một model vẽ
// bằng một lệnh cho mỗi primitive, dù các bản nhận đèn khác nhau: chỉ số đèn của từng bản nằm
// trong buffer worlds cạnh ma trận của nó (append_copies), không nằm ở hằng của lệnh vẽ.
// Vật thể đứng yên và bản sao có hình cầu bao nằm hẳn ngoài khung nhìn không sinh lệnh vẽ nào.
#include "render/forward.hpp"

#include "core/bits.hpp"
#include "core/error.hpp"
#include "gpu/binding.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "math/matrix.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "render/detail/shaders.hpp"
#include "render/shade.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/upload.hpp"
#include "shader/reflection.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::render {

namespace {

using detail::alpha_blend;
using detail::ShaderPair;

constexpr std::uint32_t kNone = std::numeric_limits<std::uint32_t>::max();
constexpr std::size_t kPipelines = 4;
constexpr std::uint32_t kTwoSided = 1;
constexpr std::uint32_t kBlended = 2;
// Sức chứa ban đầu của bảng khớp; tăng gấp đôi khi một khung cần nhiều hơn.
constexpr std::uint32_t kStartJoints = 256;
// Số ma trận thế giới buffer instanced chứa lúc tạo. Tăng gấp đôi khi một khung cần nhiều hơn.
constexpr std::uint32_t kStartWorlds = 1024;
// Đèn chính là directional nên khoảng cách trong công thức suy giảm của bản gốc luôn là 1; tầm và
// số mũ là mặc định của LightObject (100000 và 1).
constexpr float kSunFade = 1.0F - (1.0F / 100000.0F);

// Khớp struct Lamp của model.hlsli.
struct LampWords {
    math::Float4 place{};
    math::Float4 color{};
};

// Khớp struct Frame của model.hlsli.
struct FrameBlock {
    std::array<math::Float4, 4> view_proj{};
    math::Float4 depth_row{};
    math::Float4 eye{};
    std::array<math::Float4, 2> sun_toward{};
    std::array<math::Float4, 4> sun_color{};
    math::Float4 fog_kind{};
    math::Float4 fog_range{};
    math::Float4 fog_color{};
    math::Float4 rules{};
    std::array<LampWords, kLampSlots> lamps{};
};
static_assert(sizeof(FrameBlock) == 1280);

// Ô cuối của FrameBlock::lamps là đèn tắt: lệnh vẽ không có đèn điểm trỏ vào đó, để shader không
// bao giờ đọc mảng bằng chỉ số ngoài biên (GLES không bảo đảm gì cho phép đọc ấy).
constexpr auto kDarkLamp = static_cast<std::uint32_t>(kLampSlots - 1);

// Khớp struct Draw của model.hlsli.
struct DrawBlock {
    std::array<math::Float4, 3> world{};
    math::Float4 base_color{};
    math::Float4 glow{};
    math::Float4 diffuse{};
    math::Float4 specular{};
    std::uint32_t joint_base = 0;
    std::uint32_t joint_count = 0;
    std::uint32_t flags = 0;
    std::uint32_t lamp = kDarkLamp;
};
static_assert(sizeof(DrawBlock) == gpu::kMaxPushBytes);

// Khớp struct Joint của model.vs.hlsl: ba hàng đầu của ma trận skin.
struct JointRows {
    math::Float4 row0{};
    math::Float4 row1{};
    math::Float4 row2{};
};
static_assert(sizeof(JointRows) == 48);

[[nodiscard]] core::Failure bad(core::Message message) {
    return core::fail(core::ErrorCode::kInvalidArgument, message);
}

[[nodiscard]] constexpr gpu::VertexAttribute attribute(std::uint32_t location, gpu::Format format,
    std::size_t offset) noexcept {
    const auto bytes = static_cast<std::uint32_t>(offset);
    return {.location = location, .buffer = 0, .format = format, .offset = bytes};
}

// Theo location của vertex shader: thứ tự trường của Vertex trong model.vs.hlsl.
constexpr std::array<gpu::VertexAttribute, 6> kAttributes{
    attribute(0, gpu::Format::kRgb32Float, offsetof(resource::Vertex, position)),
    attribute(1, gpu::Format::kRgb32Float, offsetof(resource::Vertex, normal)),
    attribute(2, gpu::Format::kRg32Float, offsetof(resource::Vertex, uv)),
    attribute(3, gpu::Format::kRgba32Float, offsetof(resource::Vertex, color)),
    attribute(4, gpu::Format::kRgba16Uint, offsetof(resource::Vertex, joints)),
    attribute(5, gpu::Format::kRgba32Float, offsetof(resource::Vertex, weights)),
};

[[nodiscard]] JointRows rows_of(const math::Matrix4& matrix) noexcept {
    const math::Matrix4 rows = math::transpose(matrix);
    JointRows stored;
    stored.row0 = math::store(rows.col0());
    stored.row1 = math::store(rows.col1());
    stored.row2 = math::store(rows.col2());
    return stored;
}

[[nodiscard]] std::array<math::Float4, 3> world_rows(const math::Matrix4& matrix) noexcept {
    const JointRows rows = rows_of(matrix);
    return {rows.row0, rows.row1, rows.row2};
}

[[nodiscard]] math::Float4 rgb_and(const math::Vector3& color, float last) noexcept {
    return math::store(math::Vector4(color, last));
}

// Bình phương khoảng cách xa nhất từ gốc tới một đỉnh của primitive khi nó đứng ở node.
[[nodiscard]] float farthest_squared(const resource::Primitive& primitive, const math::Matrix4& node) noexcept {
    float squared = 0.0F;
    for (const resource::Vertex& vertex : primitive.vertices) {
        const math::Point3 local(vertex.position.x, vertex.position.y, vertex.position.z);
        const math::Vector3 placed((node * local).xyz());
        squared = std::max(squared, math::dot(placed, placed));
    }
    return squared;
}

// Bình phương khoảng cách xa nhất từ gốc tới một đỉnh của lưới khi lưới đứng ở node.
[[nodiscard]] float reach_of(const resource::Mesh& mesh, const math::Matrix4& node) noexcept {
    float squared = 0.0F;
    for (const resource::Primitive& primitive : mesh.primitives) {
        squared = std::max(squared, farthest_squared(primitive, node));
    }
    return squared;
}

// Chất liệu specular-glossiness lấy màu khuếch tán làm màu nền.
[[nodiscard]] bool is_specular(const resource::Material& material) noexcept {
    return material.shading == resource::Shading::kSpecular;
}

[[nodiscard]] const resource::TexSlot& base_slot(const resource::Material& material) noexcept {
    return is_specular(material) ? material.diffuse_map : material.color;
}

[[nodiscard]] std::uint32_t pipeline_of(const resource::Material* material) noexcept {
    if (material == nullptr) return 0;
    const std::uint32_t sides = material->double_sided ? kTwoSided : 0;
    return material->alpha == resource::Alpha::kBlend ? sides | kBlended : sides;
}

// Bốn cột của một ma trận thế giới, cùng bố cục float4x4 trong buffer worlds.
struct WorldWords {
    std::array<math::Float4, 4> columns{};
};
static_assert(sizeof(WorldWords) == 64);

struct ModelBuffers {
    gpu::BufferHandle palette{};
    gpu::BufferHandle worlds{};
};

struct StorageDesc {
    std::string_view name;
    std::uint64_t bytes = 0;
};

struct Slot {
    gpu::BufferHandle frame{};
    gpu::BufferHandle palette{};
    gpu::BufferHandle worlds{};
    gpu::BindGroupHandle frame_group{};
    gpu::BindGroupHandle palette_group{};
    // Số khớp bảng khớp chứa được, và số ma trận buffer worlds chứa được.
    std::uint32_t capacity = 0;
    std::uint32_t world_capacity = 0;
    // palette hoặc worlds vừa đổi: nhóm gắn space 2 phải dựng lại trước khi vẽ.
    bool models_dirty = false;
};

// Khoảng của một skin trong bảng khớp của khung; count 0 là lưới không skin.
struct Skinning {
    std::uint32_t base = 0;
    std::uint32_t count = 0;
};

// Một lệnh vẽ đã gom.
struct Item {
    const resource::GpuPrimitive* primitive = nullptr;
    gpu::BindGroupHandle material{};
    DrawBlock block{};
    std::uint32_t pipeline = 0;
    std::uint32_t instances = 1;
    // Khoảng cách dọc hướng nhìn, để xếp lưới trộn alpha từ xa tới gần.
    float distance = 0.0F;
};

// Lệnh nào vẽ trước: lưới đục trước lưới trộn; trong lưới trộn thì xa trước; lưới đục gom theo
// pipeline để ít lần đổi trạng thái.
[[nodiscard]] bool draws_before(const Item& left, const Item& right) noexcept {
    const bool left_blended = (left.pipeline & kBlended) != 0;
    const bool right_blended = (right.pipeline & kBlended) != 0;
    if (left_blended != right_blended) return right_blended;
    if (left_blended) return left.distance > right.distance;
    return left.pipeline < right.pipeline;
}

void draw_item(gpu::CommandList& list, const resource::GpuPrimitive& part, std::uint32_t instances) {
    list.bind_vertex_buffer(0, part.vertices, 0);
    if (part.index_count == 0) {
        gpu::DrawArguments plain;
        plain.vertex_count = part.vertex_count;
        plain.instance_count = instances;
        list.draw(plain);
        return;
    }
    gpu::DrawIndexedArguments indexed;
    indexed.index_count = part.index_count;
    indexed.instance_count = instances;
    list.bind_index_buffer(part.indices, gpu::IndexType::kUint32, 0);
    list.draw_indexed(indexed);
}

// Một instance đang được gom.
struct Pass {
    const Instance* instance = nullptr;
    std::span<const math::Matrix4> nodes;
    const Camera* camera = nullptr;
    const Lighting* lighting = nullptr;
    // Lưới của nút đang gom vẽ bằng bản sao instanced; world_base là chỉ số ma trận đầu của nút.
    bool is_copied = false;
    std::uint32_t world_base = 0;
    // Đèn điểm của instance khi nó không vẽ bằng bản sao.
    std::uint32_t lamp = kNoLamp;
    // Bán kính bao của model ở tư thế nghỉ (Drawable::radius_).
    float radius = 0.0F;
};

// Một lưới của instance đã có chỗ đứng trong khung: ma trận thế giới, và lệnh vẽ mẫu mang sẵn ma
// trận ấy cùng khoảng bảng khớp.
struct Placed {
    std::uint32_t mesh = 0;
    math::Matrix4 world = math::Matrix4::identity();
    Item base{};
};

[[nodiscard]] math::Vector3 center_of(const resource::Primitive& primitive) noexcept {
    if (primitive.vertices.empty()) return math::Vector3(0.0F);
    math::Vector3 low(std::numeric_limits<float>::max());
    math::Vector3 high(-std::numeric_limits<float>::max());
    for (const resource::Vertex& vertex : primitive.vertices) {
        const math::Vector3 point(vertex.position.x, vertex.position.y, vertex.position.z);
        low = math::min(low, point);
        high = math::max(high, point);
    }
    return (low + high) * 0.5F;
}

// Khoảng cách xa nhất từ gốc model tới một đỉnh khi mọi nút ở tư thế nghỉ. Lưới có skin đo ở tư
// thế bind (gần đúng: nhân vật cử động không ra xa hơn bao nhiêu so với tầm đèn).
struct RadiusScan {
    const resource::Model* model = nullptr;
    std::span<const math::Matrix4> rest;
    float squared = 0.0F;
};

void scan_node(RadiusScan& scan, std::size_t index) noexcept {
    const resource::Node& node = scan.model->nodes[index];
    if (!node.mesh || *node.mesh >= scan.model->meshes.size()) return;
    const resource::Mesh& mesh = scan.model->meshes[*node.mesh];
    const math::Matrix4 placed = node.skin ? math::Matrix4::identity() : scan.rest[index];
    scan.squared = std::max(scan.squared, reach_of(mesh, placed));
}

[[nodiscard]] float radius_of(const resource::Model& model, std::span<const math::Matrix4> rest) noexcept {
    RadiusScan scan;
    scan.model = &model;
    scan.rest = rest;
    const std::size_t count = std::min(model.nodes.size(), rest.size());
    for (std::size_t index = 0; index < count; ++index) {
        scan_node(scan, index);
    }
    return std::sqrt(scan.squared);
}

[[nodiscard]] std::vector<math::Vector3> centers_of(const resource::Mesh& mesh) {
    std::vector<math::Vector3> centers;
    centers.reserve(mesh.primitives.size());
    for (const resource::Primitive& primitive : mesh.primitives) {
        centers.push_back(center_of(primitive));
    }
    return centers;
}

} // namespace

struct Forward::State {
    State() = default;
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;
    ~State();

    [[nodiscard]] core::Status make_pipelines();
    [[nodiscard]] core::Result<gpu::PipelineHandle> make_pipeline(std::span<const gpu::ShaderHandle> shaders,
        std::uint32_t kind);
    [[nodiscard]] core::Status store_pipeline(const ShaderPair& shaders, std::uint32_t kind);
    struct KindPass {
        const ShaderPair* shaders = nullptr;
        core::Status* status = nullptr;
    };
    void store_kind(KindPass pass, std::uint32_t kind);
    [[nodiscard]] core::Status make_slot(Slot& slot);
    void fill_slot(Slot& slot, core::Status& status);
    [[nodiscard]] core::Result<gpu::BufferHandle> storage(StorageDesc request) const;
    [[nodiscard]] core::Status grow_joints(Slot& slot) const;
    [[nodiscard]] core::Status grow_matrices(Slot& slot) const;
    [[nodiscard]] core::Result<gpu::BindGroupHandle> models_group(ModelBuffers buffers);
    [[nodiscard]] core::Status bind_models(Slot& slot);
    [[nodiscard]] core::Status ensure_models(Slot& slot);
    [[nodiscard]] core::Status make_fallback();
    [[nodiscard]] core::Result<gpu::BindGroupHandle> buffer_group(std::uint32_t space, shader::RegisterType type,
        gpu::BufferHandle buffer);
    [[nodiscard]] core::Result<gpu::BindGroupHandle> material_group(const resource::Uploaded& uploaded,
        const resource::Material* material);
    struct MaterialPass {
        Drawable* drawable = nullptr;
        const resource::Uploaded* uploaded = nullptr;
        const resource::Material* material = nullptr;
        core::Status* status = nullptr;
    };
    void add_material(MaterialPass pass);

    struct Take {
        const Instance* instance = nullptr;
        const Camera* camera = nullptr;
        const Lighting* lighting = nullptr;
        core::Status* status = nullptr;
    };
    [[nodiscard]] core::Status collect(const Take& take);
    [[nodiscard]] bool enters_frame(Pass& pass);
    void collect_indexed(Pass& pass, std::size_t index);
    void collect_node(Pass& pass, std::size_t index);
    void place_world(Pass& pass, std::size_t index, Skinning skinning, Placed& placed);
    void append_copies(Pass& pass, const math::Matrix4& node);
    void add_parts(const Pass& pass, const Placed& placed);
    [[nodiscard]] Skinning skin_of(const Pass& pass, const resource::Node& node);
    void add_joint(const Pass& pass, const resource::Skin& skin, std::size_t joint);
    void add_item(const Pass& pass, const Placed& placed, std::size_t part);
    void take_instance(Take take);
    [[nodiscard]] core::Status write(Slot& slot, const Camera& camera, const Lighting& lights) const;
    [[nodiscard]] core::Status write_palette(const Slot& slot) const;
    [[nodiscard]] core::Status write_worlds(const Slot& slot) const;
    struct Emit {
        gpu::CommandList* list = nullptr;
        const Slot* slot = nullptr;
        std::uint32_t* bound = nullptr;
    };
    void bind_changed(Emit emit, const Item& item) const;
    void draw_one(Emit emit, const Item& item) const;
    void emit(gpu::CommandList& list, const Slot& slot) const;

    gpu::Device* device = nullptr;
    ForwardDesc desc{};
    std::array<gpu::PipelineHandle, kPipelines> pipelines{};
    std::vector<Slot> slots;
    // Ảnh trắng 1x1 và sampler mặc định, cho chất liệu không có texture màu nền.
    resource::Uploaded fallback;
    // Vùng làm việc của một lần draw, giữ lại giữa các khung để không cấp phát lại.
    std::vector<Item> items;
    std::vector<JointRows> palette;
    std::vector<WorldWords> world_words;
    // Vị trí bảng khớp của từng skin của instance đang gom; kNone là chưa dựng.
    std::vector<std::uint32_t> skin_bases;
    // Khung nhìn của lần draw đang chạy.
    Frustum frustum{};
    // Bản sao còn thấy của instance đang gom, theo thứ tự ghi vào buffer worlds, kèm đèn của từng
    // bản.
    std::vector<SeenCopy> seen;
};

Forward::State::~State() {
    if (device == nullptr) return;
    for (const Slot& slot : slots) {
        device->destroy(slot.frame_group);
        device->destroy(slot.palette_group);
        device->destroy(slot.frame);
        device->destroy(slot.palette);
        device->destroy(slot.worlds);
    }
    for (const gpu::PipelineHandle pipeline : pipelines) {
        device->destroy(pipeline);
    }
}

core::Result<gpu::PipelineHandle> Forward::State::make_pipeline(std::span<const gpu::ShaderHandle> shaders,
    std::uint32_t kind) {
    const bool is_blended = (kind & kBlended) != 0;
    const bool is_two_sided = (kind & kTwoSided) != 0;
    const gpu::VertexBufferLayout layout{.stride = sizeof(resource::Vertex)};
    const gpu::BlendState blend = is_blended ? alpha_blend() : gpu::BlendState{};
    gpu::GraphicsPipelineDesc pipeline;
    pipeline.name = "render.forward.model";
    pipeline.shaders = shaders;
    pipeline.vertex_buffers = std::span(&layout, 1);
    pipeline.vertex_attributes = kAttributes;
    pipeline.raster.cull = is_two_sided ? gpu::CullMode::kNone : gpu::CullMode::kBack;
    pipeline.depth.format = desc.depth_format;
    pipeline.depth.is_tested = true;
    pipeline.depth.is_written = !is_blended;
    pipeline.color_formats = std::span(&desc.color_format, 1);
    pipeline.samples = desc.samples;
    pipeline.blends = std::span(&blend, 1);
    return device->create_pipeline(pipeline);
}

core::Status Forward::State::make_pipelines() {
    const std::string directory = detail::shader_folder(desc.shader_dir);
    ShaderPair shaders(*device);
    shaders.sizes = {.frame = sizeof(FrameBlock), .draw = sizeof(DrawBlock)};
    const core::Status vertex = shaders.load(0, directory, "model.vs");
    if (!vertex) return vertex;
    const core::Status pixel = shaders.load(1, directory, "model.ps");
    if (!pixel) return pixel;
    core::Status status = core::ok();
    KindPass pass;
    pass.shaders = &shaders;
    pass.status = &status;
    for (std::uint32_t kind = 0; kind < kPipelines; ++kind) {
        store_kind(pass, kind);
    }
    return status;
}

core::Status Forward::State::store_pipeline(const ShaderPair& shaders, std::uint32_t kind) {
    const core::Result<gpu::PipelineHandle> made = make_pipeline(shaders.handles, kind);
    if (!made) return std::unexpected(made.error());
    pipelines.at(kind) = *made;
    return core::ok();
}

void Forward::State::store_kind(KindPass pass, std::uint32_t kind) {
    if (!*pass.status) return;
    *pass.status = store_pipeline(*pass.shaders, kind);
}

core::Result<gpu::BindGroupHandle> Forward::State::buffer_group(std::uint32_t space, shader::RegisterType type,
    gpu::BufferHandle buffer) {
    gpu::BindEntry entry;
    entry.type = type;
    entry.resource = gpu::BufferRange{.buffer = buffer};
    gpu::BindGroupDesc group;
    group.name = "render.forward.frame";
    group.pipeline = pipelines.front();
    group.space = space;
    group.entries = std::span(&entry, 1);
    return device->create_bind_group(group);
}

core::Result<gpu::BufferHandle> Forward::State::storage(StorageDesc request) const {
    gpu::BufferDesc buffer;
    buffer.name = request.name;
    buffer.size = request.bytes;
    buffer.usage = gpu::BufferUsage::kStorage;
    buffer.memory = gpu::MemoryDomain::kUpload;
    return device->create_buffer(buffer);
}

core::Status Forward::State::grow_joints(Slot& slot) const {
    const auto needed = static_cast<std::uint32_t>(palette.size());
    if (needed <= slot.capacity) return core::ok();
    const std::uint32_t count = std::max(needed, slot.capacity * 2);
    const std::uint64_t bytes = std::uint64_t{count} * sizeof(JointRows);
    StorageDesc request;
    request.name = "render.forward.palette";
    request.bytes = bytes;
    const core::Result<gpu::BufferHandle> made = storage(request);
    if (!made) return std::unexpected(made.error());
    device->destroy(slot.palette);
    slot.palette = *made;
    slot.capacity = count;
    slot.models_dirty = true;
    return core::ok();
}

core::Status Forward::State::grow_matrices(Slot& slot) const {
    const auto needed = static_cast<std::uint32_t>(world_words.size());
    if (needed <= slot.world_capacity) return core::ok();
    const std::uint32_t count = std::max(needed, slot.world_capacity * 2);
    const std::uint64_t bytes = std::uint64_t{count} * sizeof(WorldWords);
    StorageDesc request;
    request.name = "render.forward.worlds";
    request.bytes = bytes;
    const core::Result<gpu::BufferHandle> made = storage(request);
    if (!made) return std::unexpected(made.error());
    device->destroy(slot.worlds);
    slot.worlds = *made;
    slot.world_capacity = count;
    slot.models_dirty = true;
    return core::ok();
}

core::Result<gpu::BindGroupHandle> Forward::State::models_group(ModelBuffers buffers) {
    std::array<gpu::BindEntry, 2> entries;
    gpu::BindEntry& joints = entries.front();
    joints.type = shader::RegisterType::kResource;
    joints.slot = 0;
    joints.resource = gpu::BufferRange{.buffer = buffers.palette};
    gpu::BindEntry& copies = entries.back();
    copies.type = shader::RegisterType::kResource;
    copies.slot = 1;
    copies.resource = gpu::BufferRange{.buffer = buffers.worlds};
    gpu::BindGroupDesc group;
    group.name = "render.forward.models";
    group.pipeline = pipelines.front();
    group.space = 2;
    group.entries = entries;
    return device->create_bind_group(group);
}

core::Status Forward::State::bind_models(Slot& slot) {
    ModelBuffers buffers;
    buffers.palette = slot.palette;
    buffers.worlds = slot.worlds;
    const core::Result<gpu::BindGroupHandle> group = models_group(buffers);
    if (!group) return std::unexpected(group.error());
    device->destroy(slot.palette_group);
    slot.palette_group = *group;
    slot.models_dirty = false;
    return core::ok();
}

core::Status Forward::State::ensure_models(Slot& slot) {
    const core::Status joints = grow_joints(slot);
    if (!joints) return joints;
    const core::Status matrices = grow_matrices(slot);
    if (!matrices) return matrices;
    if (!slot.models_dirty) return core::ok();
    return bind_models(slot);
}

core::Status Forward::State::make_slot(Slot& slot) {
    gpu::BufferDesc buffer;
    buffer.name = "render.forward.frame";
    buffer.size = core::align_up(std::uint64_t{sizeof(FrameBlock)}, std::uint64_t{gpu::kUniformAlignment});
    buffer.usage = gpu::BufferUsage::kUniform;
    buffer.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made = device->create_buffer(buffer);
    if (!made) return std::unexpected(made.error());
    slot.frame = *made;
    const auto group = buffer_group(0, shader::RegisterType::kConstant, slot.frame);
    if (!group) return std::unexpected(group.error());
    slot.frame_group = *group;
    const std::uint64_t joint_bytes = std::uint64_t{kStartJoints} * sizeof(JointRows);
    StorageDesc joints;
    joints.name = "render.forward.palette";
    joints.bytes = joint_bytes;
    const core::Result<gpu::BufferHandle> stored = storage(joints);
    if (!stored) return std::unexpected(stored.error());
    slot.palette = *stored;
    slot.capacity = kStartJoints;
    const std::uint64_t world_bytes = std::uint64_t{kStartWorlds} * sizeof(WorldWords);
    StorageDesc matrices;
    matrices.name = "render.forward.worlds";
    matrices.bytes = world_bytes;
    const core::Result<gpu::BufferHandle> worlds = storage(matrices);
    if (!worlds) return std::unexpected(worlds.error());
    slot.worlds = *worlds;
    slot.world_capacity = kStartWorlds;
    return bind_models(slot);
}

core::Status Forward::State::make_fallback() {
    resource::Model white;
    resource::Image pixel;
    pixel.name = "render.white";
    pixel.width = 1;
    pixel.height = 1;
    pixel.rgba.assign(4, 255);
    white.images.push_back(std::move(pixel));
    core::Result<resource::Uploaded> uploaded = resource::upload(*device, white);
    if (!uploaded) return std::unexpected(uploaded.error());
    fallback = std::move(*uploaded);
    return core::ok();
}

core::Result<gpu::BindGroupHandle> Forward::State::material_group(const resource::Uploaded& uploaded,
    const resource::Material* material) {
    const resource::TexSlot none;
    const resource::TexSlot& slot = material != nullptr ? base_slot(*material) : none;
    const std::span<const resource::GpuImage> images = uploaded.images();
    const std::span<const gpu::SamplerHandle> samplers = uploaded.samplers();
    const bool has_image = slot.image && *slot.image < images.size();
    const bool has_sampler = slot.sampler && *slot.sampler < samplers.size();
    const gpu::TextureViewHandle white = fallback.images().front().view;
    const gpu::TextureViewHandle view = has_image ? core::at(images, *slot.image).view : white;
    const gpu::SamplerHandle own = uploaded.default_sampler();
    const gpu::SamplerHandle shared = own ? own : fallback.default_sampler();
    const gpu::SamplerHandle sampler = has_sampler ? core::at(samplers, *slot.sampler) : shared;
    std::array<gpu::BindEntry, 2> entries;
    entries.front().type = shader::RegisterType::kResource;
    entries.front().resource = view;
    entries.back().type = shader::RegisterType::kSampler;
    entries.back().resource = sampler;
    gpu::BindGroupDesc group;
    group.name = "render.forward.material";
    group.pipeline = pipelines.front();
    group.space = 1;
    group.entries = entries;
    return device->create_bind_group(group);
}

void Forward::State::add_joint(const Pass& pass, const resource::Skin& skin, std::size_t joint) {
    const std::span<const math::Matrix4> ready = pass.instance->joints;
    if (joint < ready.size()) {
        palette.push_back(rows_of(ready[joint]));
        return;
    }
    const std::uint32_t node = skin.joints.at(joint);
    const bool has_bind = joint < skin.inverse_bind.size();
    const math::Matrix4 bind = has_bind ? skin.inverse_bind.at(joint) : math::Matrix4::identity();
    const bool has_node = node < pass.nodes.size();
    const math::Matrix4 placed = has_node ? core::at(pass.nodes, node) : math::Matrix4::identity();
    palette.push_back(rows_of(placed * bind));
}

// Bảng khớp của skin mà nút dùng; dựng một lần cho mỗi skin của mỗi instance.
Skinning Forward::State::skin_of(const Pass& pass, const resource::Node& node) {
    const resource::Model& model = *pass.instance->drawable->model_;
    if (!node.skin || *node.skin >= model.skins.size()) return {};
    const resource::Skin& skin = model.skins.at(*node.skin);
    const auto count = static_cast<std::uint32_t>(skin.joints.size());
    std::uint32_t& base = skin_bases.at(*node.skin);
    if (base != kNone) return {.base = base, .count = count};
    base = static_cast<std::uint32_t>(palette.size());
    for (std::size_t joint = 0; joint < skin.joints.size(); ++joint) {
        add_joint(pass, skin, joint);
    }
    return {.base = base, .count = count};
}

namespace {

// Ô của Frame::lamps mà shader đọc cho một đèn đã chọn; không đèn nào với tới thì là ô đèn tắt.
[[nodiscard]] std::uint32_t lamp_slot(std::uint32_t lamp) noexcept {
    return lamp == kNoLamp ? kDarkLamp : lamp;
}

// Đèn điểm có ô trong Frame::lamps; đèn đứng sau không chiếu.
[[nodiscard]] std::span<const Lamp> frame_lamps(const Lighting& lighting) noexcept {
    return lighting.lamps.first(std::min(lighting.lamps.size(), kMaxLamps));
}

} // namespace

// Chọn đèn cho instance và cho biết nó còn gì để vẽ trong khung. Có bản sao: seen nhận những bản
// còn chạm khung nhìn, mỗi bản kèm đèn của nó. Một bản: vật thể đứng yên ở tư thế nghỉ mà hình cầu
// bao nằm hẳn ngoài khung thì bỏ; model có skin hay đang được đặt tư thế thì không loại, vì bán
// kính bao của Drawable đo ở tư thế nghỉ chỉ gần đúng với chúng.
bool Forward::State::enters_frame(Pass& pass) {
    const Instance& instance = *pass.instance;
    const std::span<const Lamp> lamps = frame_lamps(*pass.lighting);
    if (!instance.copies.empty()) {
        see_copies({.copies = instance.copies, .lamps = lamps, .radius = pass.radius}, frustum, seen);
        return !seen.empty();
    }
    const Reach reach = reach_at(instance.world, pass.radius);
    const bool is_still = instance.nodes.empty() && instance.drawable->model_->skins.empty();
    if (is_still && !sphere_in_view(frustum, reach.centre, reach.radius)) return false;
    pass.lamp = nearest_lamp(lamps, reach);
    return true;
}

// Ma trận thế giới của từng bản sao còn thấy, nối vào buffer worlds theo thứ tự của seen. Ô hàng
// cuối, cột đầu của mỗi ma trận mang chỉ số đèn của bản đó: ma trận affine luôn có 0 ở ô ấy, và
// shader chỉ dùng ba hàng đầu khi đưa đỉnh ra thế giới (copy_lamp của model.vs đọc lại ô này).
void Forward::State::append_copies(Pass& pass, const math::Matrix4& node) {
    const std::span<const math::Matrix4> copies = pass.instance->copies;
    pass.world_base = static_cast<std::uint32_t>(world_words.size());
    for (const SeenCopy& copy : seen) {
        WorldWords words;
        words.columns = math::store(copies[copy.index] * node);
        words.columns.front().w = static_cast<float>(lamp_slot(copy.lamp));
        world_words.push_back(words);
    }
}

void Forward::State::place_world(Pass& pass, std::size_t index, Skinning skinning, Placed& placed) {
    const math::Matrix4 node = core::at(pass.nodes, index);
    pass.is_copied = !pass.instance->copies.empty() && skinning.count == 0;
    if (!pass.is_copied) {
        const math::Matrix4& own = pass.instance->world;
        placed.world = skinning.count > 0 ? own : own * node;
        return;
    }
    append_copies(pass, node);
    // Mốc xếp lưới trộn alpha của cả đám: bản còn thấy đầu tiên (enters_frame bảo đảm seen khác rỗng).
    placed.world = pass.instance->copies[seen.front().index] * node;
}

void Forward::State::add_item(const Pass& pass, const Placed& placed, std::size_t part) {
    const Drawable& drawable = *pass.instance->drawable;
    const resource::Model& model = *drawable.model_;
    const resource::Primitive& source = model.meshes.at(placed.mesh).primitives.at(part);
    const resource::GpuMesh& uploaded = core::at(drawable.uploaded_->meshes(), placed.mesh);
    const resource::GpuPrimitive& buffers = uploaded.primitives.at(part);
    const bool is_drawable = source.topology == resource::Topology::kTriangles && buffers.vertices;
    if (!is_drawable || buffers.vertex_count == 0) return;
    const bool has_material = source.material && *source.material < model.materials.size();
    const std::size_t slot = has_material ? *source.material : model.materials.size();
    const resource::Material* material = has_material ? &model.materials.at(slot) : nullptr;
    const math::Point3 center(drawable.centers_.at(placed.mesh).at(part));
    const math::Point3 placed_center((placed.world * center).xyz());
    Item item = placed.base;
    item.primitive = &buffers;
    item.material = drawable.materials_.at(slot);
    item.pipeline = pipeline_of(material);
    // Tay phải: phía trước camera là z âm.
    item.distance = -(pass.camera->view * placed_center).z();
    const ShadeAsk ask{.material = material, .lighting = pass.lighting, .is_actor = pass.instance->is_actor};
    const Shade shade = shade_of(ask);
    item.block.base_color = shade.base_color;
    item.block.glow = shade.glow;
    item.block.diffuse = shade.diffuse;
    item.block.specular = shade.specular;
    item.block.flags = desc.lights_at_vertices ? shade.flags & ~kPixelLit : shade.flags;
    if (pass.is_copied) {
        // Đèn của từng bản nằm trong buffer worlds; Draw::lamp giữ ô đèn tắt.
        item.instances = static_cast<std::uint32_t>(seen.size());
        item.block.flags |= kInstanced;
        item.block.joint_base = pass.world_base;
    } else {
        item.block.lamp = lamp_slot(pass.lamp);
    }
    items.push_back(item);
}

// Mỗi primitive của lưới một lệnh vẽ; lưới vẽ bằng bản sao thì lệnh ấy vẽ mọi bản còn thấy.
void Forward::State::add_parts(const Pass& pass, const Placed& placed) {
    const Drawable& drawable = *pass.instance->drawable;
    const resource::Model& model = *drawable.model_;
    const std::span<const resource::GpuMesh> meshes = drawable.uploaded_->meshes();
    const std::size_t sources = model.meshes.at(placed.mesh).primitives.size();
    const std::size_t parts = core::at(meshes, placed.mesh).primitives.size();
    for (std::size_t part = 0; part < std::min(sources, parts); ++part) {
        add_item(pass, placed, part);
    }
}

// Lưới có skin đứng ở không gian của instance (glTF bỏ qua biến đổi của nút mang nó); lưới thường
// đứng ở nút của nó.
void Forward::State::collect_node(Pass& pass, std::size_t index) {
    const Drawable& drawable = *pass.instance->drawable;
    const resource::Model& model = *drawable.model_;
    const resource::Node& node = model.nodes.at(index);
    if (!node.mesh) return;
    const std::uint32_t mesh = *node.mesh;
    const std::span<const resource::GpuMesh> meshes = drawable.uploaded_->meshes();
    if (mesh >= model.meshes.size() || mesh >= meshes.size()) return;
    const Skinning skinning = skin_of(pass, node);
    Placed placed;
    placed.mesh = mesh;
    place_world(pass, index, skinning, placed);
    placed.base.block.world = world_rows(placed.world);
    placed.base.block.joint_base = skinning.base;
    placed.base.block.joint_count = skinning.count;
    add_parts(pass, placed);
}

void Forward::State::collect_indexed(Pass& pass, std::size_t index) {
    const resource::Model& model = *pass.instance->drawable->model_;
    if (!model.nodes.at(index).mesh) return;
    collect_node(pass, index);
}

core::Status Forward::State::collect(const Take& take) {
    const Instance& instance = *take.instance;
    const Drawable* drawable = instance.drawable;
    const bool is_ready = drawable != nullptr && drawable->model_ != nullptr;
    if (!is_ready) return bad("instance không có drawable đã chuẩn bị");
    const resource::Model& model = *drawable->model_;
    Pass pass;
    pass.instance = &instance;
    pass.nodes = instance.nodes.empty() ? drawable->rest() : instance.nodes;
    pass.camera = take.camera;
    pass.lighting = take.lighting;
    pass.radius = drawable->radius_;
    if (pass.nodes.size() != model.nodes.size()) return bad("số ma trận nút lệch số nút của model");
    const bool is_skinned = !instance.copies.empty() && !model.skins.empty();
    if (is_skinned) return bad("bản sao instanced không dùng cho model có skin");
    if (!enters_frame(pass)) return core::ok();
    skin_bases.assign(model.skins.size(), kNone);
    for (std::size_t index = 0; index < model.nodes.size(); ++index) {
        collect_indexed(pass, index);
    }
    return core::ok();
}

namespace {

[[nodiscard]] math::Float4 toward_of(const Sun& sun) noexcept {
    const float length = math::length(sun.toward);
    const bool has_direction = length > 0.0F;
    const math::Vector3 toward = has_direction ? sun.toward / length : math::Vector3::y_axis();
    return rgb_and(toward, 0.0F);
}

// fog_type và fog_params của bản gốc (AutoParamDataSource::setFog của OgreMain 2026): một ô bằng
// 1 theo kiểu sương; tầm bằng 0 thì nghịch đảo lấy 1.
void write_fog(FrameBlock& block, const Fog& fog) noexcept {
    std::array<float, 4> kind{};
    kind.at(static_cast<std::size_t>(fog.kind)) = 1.0F;
    const float span = fog.end - fog.start;
    const float inverse = span == 0.0F ? 1.0F : 1.0F / span;
    block.fog_kind = {.x = kind[0], .y = kind[1], .z = kind[2], .w = kind[3]};
    block.fog_range = {.x = fog.density, .y = fog.start, .z = fog.end, .w = inverse};
    block.fog_color = rgb_and(fog.color, 1.0F);
}

void write_suns(FrameBlock& block, const Lighting& lighting) noexcept {
    for (std::size_t index = 0; index < lighting.suns.size(); ++index) {
        const Sun& sun = lighting.suns.at(index);
        block.sun_toward.at(index) = toward_of(sun);
        block.sun_color.at(index) = rgb_and(sun.color * kSunFade, 1.0F);
        block.sun_color.at(index + 2) = rgb_and(sun.actor * kSunFade, 1.0F);
    }
}

// Ô chưa dùng và ô đèn tắt giữ tầm 1, số mũ 1, màu đen: công thức suy giảm ra 0 mà không chia 0.
void write_lamps(FrameBlock& block, std::span<const Lamp> lamps) noexcept {
    const LampWords dark{.place = {.w = 1.0F}, .color = {.w = 1.0F}};
    block.lamps.fill(dark);
    const std::size_t count = std::min(lamps.size(), kMaxLamps);
    for (std::size_t index = 0; index < count; ++index) {
        const Lamp& lamp = lamps[index];
        block.lamps.at(index).place = rgb_and(lamp.position, lamp.range);
        block.lamps.at(index).color = rgb_and(lamp.color, lamp.falloff);
    }
}

} // namespace

core::Status Forward::State::write(Slot& slot, const Camera& camera, const Lighting& lights) const {
    FrameBlock block;
    block.view_proj = math::store(camera.projection * camera.view);
    // Tay phải: phía trước camera là z âm, nên độ sâu là hàng z của view đổi dấu.
    block.depth_row = math::store(-math::transpose(camera.view).col2());
    block.eye = math::store(math::affine_inverse(camera.view).col3());
    write_suns(block, lights);
    write_fog(block, lights.fog);
    block.rules.x = lights.is_overbright ? 1.0F : 0.0F;
    write_lamps(block, lights.lamps);
    const auto frame_bytes = std::as_bytes(std::span(&block, 1));
    const core::Status status = device->write_buffer(slot.frame, 0, frame_bytes);
    if (!status) return status;
    const core::Status joints = write_palette(slot);
    if (!joints) return joints;
    return write_worlds(slot);
}

core::Status Forward::State::write_palette(const Slot& slot) const {
    if (palette.empty()) return core::ok();
    const auto bytes = std::as_bytes(std::span(palette));
    return device->write_buffer(slot.palette, 0, bytes);
}

core::Status Forward::State::write_worlds(const Slot& slot) const {
    if (world_words.empty()) return core::ok();
    const auto bytes = std::as_bytes(std::span(world_words));
    return device->write_buffer(slot.worlds, 0, bytes);
}

void Forward::State::bind_changed(Emit emit, const Item& item) const {
    const bool is_new = item.pipeline != *emit.bound;
    if (!is_new) return;
    emit.list->bind_pipeline(pipelines.at(item.pipeline));
    emit.list->bind_group(0, emit.slot->frame_group);
    emit.list->bind_group(2, emit.slot->palette_group);
    *emit.bound = item.pipeline;
}

void Forward::State::draw_one(Emit emit, const Item& item) const {
    bind_changed(emit, item);
    emit.list->bind_group(1, item.material);
    const auto bytes = std::as_bytes(std::span(&item.block, 1));
    emit.list->push_constants(bytes, 0);
    draw_item(*emit.list, *item.primitive, item.instances);
}

void Forward::State::emit(gpu::CommandList& list, const Slot& slot) const {
    Emit emit;
    emit.list = &list;
    emit.slot = &slot;
    std::uint32_t bound = kNone;
    emit.bound = &bound;
    for (const Item& item : items) {
        draw_one(emit, item);
    }
}

Drawable::Drawable(Drawable&& other) noexcept
    : device_(std::exchange(other.device_, nullptr)),
      model_(std::exchange(other.model_, nullptr)),
      uploaded_(std::exchange(other.uploaded_, nullptr)),
      materials_(std::move(other.materials_)),
      rest_(std::move(other.rest_)),
      radius_(other.radius_),
      centers_(std::move(other.centers_)) {}

Drawable& Drawable::operator=(Drawable&& other) noexcept {
    if (this == &other) return *this;
    release();
    device_ = std::exchange(other.device_, nullptr);
    model_ = std::exchange(other.model_, nullptr);
    uploaded_ = std::exchange(other.uploaded_, nullptr);
    materials_ = std::move(other.materials_);
    rest_ = std::move(other.rest_);
    radius_ = other.radius_;
    centers_ = std::move(other.centers_);
    return *this;
}

Drawable::~Drawable() {
    release();
}

void Drawable::release() noexcept {
    if (device_ == nullptr) return;
    for (const gpu::BindGroupHandle group : materials_) {
        device_->destroy(group);
    }
    materials_.clear();
    device_ = nullptr;
}

Forward::Forward(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Forward::Forward(Forward&&) noexcept = default;
Forward& Forward::operator=(Forward&&) noexcept = default;
Forward::~Forward() = default;

core::Result<Forward> Forward::create(gpu::Device& device, const ForwardDesc& desc) {
    if (desc.slots == 0) return bad("renderer cần ít nhất một slot");
    auto state = std::make_unique<State>();
    state->device = &device;
    state->desc = desc;
    const core::Status pipelines = state->make_pipelines();
    if (!pipelines) return std::unexpected(pipelines.error());
    state->slots.resize(desc.slots);
    core::Status filled = core::ok();
    for (Slot& slot : state->slots) {
        state->fill_slot(slot, filled);
    }
    if (!filled) return std::unexpected(filled.error());
    const core::Status fallback = state->make_fallback();
    if (!fallback) return std::unexpected(fallback.error());
    return Forward(std::move(state));
}

void Forward::State::fill_slot(Slot& slot, core::Status& status) {
    if (!status) return;
    status = make_slot(slot);
}

core::Result<Drawable> Forward::prepare(const resource::Model& model, const resource::Uploaded& uploaded) {
    State& state = *state_;
    const bool is_same =
        uploaded.meshes().size() == model.meshes.size() && uploaded.images().size() == model.images.size();
    if (!is_same) return bad("uploaded không phải kết quả tải lên của model này");
    Drawable drawable;
    drawable.device_ = state.device;
    drawable.model_ = &model;
    drawable.uploaded_ = &uploaded;
    drawable.rest_ = rest_nodes(model);
    drawable.radius_ = radius_of(model, drawable.rest_);
    drawable.centers_.reserve(model.meshes.size());
    for (const resource::Mesh& mesh : model.meshes) {
        drawable.centers_.push_back(centers_of(mesh));
    }
    drawable.materials_.reserve(model.materials.size() + 1);
    core::Status status = core::ok();
    for (const resource::Material& material : model.materials) {
        State::MaterialPass pass;
        pass.drawable = &drawable;
        pass.uploaded = &uploaded;
        pass.material = &material;
        pass.status = &status;
        state.add_material(pass);
    }
    if (!status) return std::unexpected(status.error());
    State::MaterialPass plain;
    plain.drawable = &drawable;
    plain.uploaded = &uploaded;
    plain.status = &status;
    state.add_material(plain);
    if (!status) return std::unexpected(status.error());
    return drawable;
}

void Forward::State::add_material(MaterialPass pass) {
    if (!*pass.status) return;
    const auto group = material_group(*pass.uploaded, pass.material);
    if (!group) *pass.status = std::unexpected(group.error());
    if (group) pass.drawable->materials_.push_back(*group);
}

core::Status Forward::draw(gpu::CommandList& list, std::uint32_t slot, const Camera& camera, const Lighting& lighting,
    std::span<const Instance> instances) {
    State& state = *state_;
    if (slot >= state.slots.size()) return bad("slot ngoài số đã khai lúc tạo renderer");
    state.items.clear();
    state.palette.clear();
    state.world_words.clear();
    state.frustum = frustum_of(camera.projection * camera.view);
    core::Status status = core::ok();
    for (const Instance& instance : instances) {
        State::Take take;
        take.instance = &instance;
        take.camera = &camera;
        take.lighting = &lighting;
        take.status = &status;
        state.take_instance(take);
    }
    if (!status) return status;
    Slot& frame = state.slots.at(slot);
    const core::Status grown = state.ensure_models(frame);
    if (!grown) return grown;
    const core::Status written = state.write(frame, camera, lighting);
    if (!written) return written;
    std::ranges::stable_sort(state.items, draws_before);
    state.emit(list, frame);
    return core::ok();
}

void Forward::State::take_instance(Take take) {
    if (!*take.status) return;
    *take.status = collect(take);
}

std::uint32_t Forward::draw_count() const noexcept {
    return static_cast<std::uint32_t>(state_->items.size());
}

} // namespace game::render

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
