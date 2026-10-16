#include "client/display/fx_view.hpp"

#include "client/stage/stage.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "fx/billboard.hpp"
#include "fx/cast.hpp"
#include "fx/field.hpp"
#include "gpu/binding.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "io/file.hpp"
#include "math/matrix.hpp"
#include "math/types.hpp"
#include "render/camera.hpp"
#include "render/catalog.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/tier.hpp"
#include "resource/upload.hpp"
#include "scene/placement.hpp"
#include "shader/reflection.hpp"
#include <algorithm>
#include <array>
#include <bit>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
#include <functional>
#include <iterator>
#include <map>
#include <unordered_map>
#include <memory>
#include <optional>
#include <print>
#include <ratio>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client {
namespace {

constexpr std::uint32_t kTextureSpace = 1;
// Sức chứa đầu tiên của bộ đệm quad; khung cần hơn thì bộ đệm lớn lên theo luỹ thừa của hai.
constexpr std::uint32_t kFirstQuads = 1024;
// Sau chừng này giây kể từ lúc nhận cảnh, khi các hệ đã phát đủ hạt, ghi một dòng số đo của khung.
constexpr float kReportAfter = 3.0F;

struct FxVertex {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
    float u = 0.0F;
    float v = 0.0F;
    float red = 1.0F;
    float green = 1.0F;
    float blue = 1.0F;
    float alpha = 1.0F;
    float cover_u = 0.0F;
    float cover_v = 0.0F;
};
static_assert(sizeof(FxVertex) == render::kFxStride);
static_assert(offsetof(FxVertex, u) == render::kFxUv);
static_assert(offsetof(FxVertex, red) == render::kFxColour);

[[nodiscard]] resource::Model model_of(const resource::Image& image, const resource::Image& cover, bool repeats) {
    resource::Model model;
    model.images.push_back(image);
    model.images.push_back(cover);
    resource::Sampler sampler;
    sampler.name = "fx";
    const resource::Wrap wrap = repeats ? resource::Wrap::kRepeat : resource::Wrap::kClamp;
    sampler.wrap_u = wrap;
    sampler.wrap_v = wrap;
    sampler.has_mip = false;
    model.samplers.push_back(sampler);
    resource::Material material;
    material.name = "fx";
    material.color.image = 0;
    material.color.sampler = 0;
    model.materials.push_back(material);
    return model;
}

// Điện thoại mở bản đã nấu (mobile/astc, mobile/etc2) thay ảnh gốc: gói APK không mang PNG của Material/.
[[nodiscard]] core::Result<resource::Image> read_image(const std::filesystem::path& root, std::string_view image,
    resource::TextureTier tier) {
    const std::string chosen = resource::texture_file(io::utf8_of(root), image, tier);
    const io::TextResult bytes = io::read_text(io::path_from_utf8(chosen));
    if (!bytes) return core::fail(core::ErrorCode::kNotFound, "không đọc được tệp ảnh", io::describe(bytes.error()));
    return resource::read_stored(std::as_bytes(std::span(*bytes)));
}

// Tấm sương của cảnh đăng nhập. Không dựng: chúng phủ trời thành một lớp xám.
[[nodiscard]] bool is_mist(std::string_view name) noexcept {
    const bool directional = name.contains("方向雾");
    const bool sheets = name.contains("远景雾片");
    return directional || sheets;
}

[[nodiscard]] fx::Spawn spawn_of(const FxPlace& place) {
    const scene::Placement& placement = place.placement;
    fx::Spawn spawn;
    spawn.name = place.name;
    spawn.is_effect = place.is_effect;
    spawn.node.position = {.x = placement.position.x, .y = placement.position.y, .z = placement.position.z};
    spawn.node.orientation.x = placement.orientation.x;
    spawn.node.orientation.y = placement.orientation.y;
    spawn.node.orientation.z = placement.orientation.z;
    spawn.node.orientation.w = placement.orientation.w;
    spawn.node.scale = {.x = placement.scale.x, .y = placement.scale.y, .z = placement.scale.z};
    return spawn;
}

[[nodiscard]] fx::CameraAxes axes_of(const render::Camera& camera) {
    const math::Matrix4& view = camera.view;
    fx::CameraAxes axes;
    axes.right = {.x = view.at(0, 0), .y = view.at(1, 0), .z = view.at(2, 0)};
    axes.up = {.x = view.at(0, 1), .y = view.at(1, 1), .z = view.at(2, 1)};
    const float backward_x = view.at(0, 2);
    const float backward_y = view.at(1, 2);
    const float backward_z = view.at(2, 2);
    axes.forward = {.x = -backward_x, .y = -backward_y, .z = -backward_z};
    const float shift_x = view.at(3, 0);
    const float shift_y = view.at(3, 1);
    const float shift_z = view.at(3, 2);
    // look_at_rh: hàng 0, 1, 2 là right, up, backward; mắt = -R^T * t.
    axes.eye.x = -(((axes.right.x * shift_x) + (axes.up.x * shift_y)) + (backward_x * shift_z));
    axes.eye.y = -(((axes.right.y * shift_x) + (axes.up.y * shift_y)) + (backward_y * shift_z));
    axes.eye.z = -(((axes.right.z * shift_x) + (axes.up.z * shift_y)) + (backward_z * shift_z));
    return axes;
}

[[nodiscard]] float unit(float value) noexcept {
    return std::clamp(value, 0.0F, 1.0F);
}

// Gain nhân sau khi kẹp rgb về 0..1, đúng vertex shader gốc (saturate rồi mới nhân BLEND_OP).
// Alpha không kẹp ở đây: mốc opacity đo được tới 2, shader kẹp sau khi nhân alpha của ảnh.
[[nodiscard]] FxVertex vertex_of(const fx::BillboardVertex& source, float gain) noexcept {
    FxVertex vertex;
    vertex.x = source.x;
    vertex.y = source.y;
    vertex.z = source.z;
    vertex.u = source.u;
    vertex.v = source.v;
    vertex.red = unit(source.red) * gain;
    vertex.green = unit(source.green) * gain;
    vertex.blue = unit(source.blue) * gain;
    vertex.alpha = source.alpha;
    return vertex;
}

void place_uv(float& across, float& down, float source_u, float source_v, float scale_u,
    float scale_v, float shift_u, float shift_v, float anim_u, float anim_v, float age) noexcept {
    across = (source_u * scale_u) + shift_u + (anim_u * age);
    down = (source_v * scale_v) + shift_v + (anim_v * age);
}

void append_kind(std::string& text, std::string_view kind, std::uint32_t count) {
    if (!text.empty()) text += ", ";
    text += std::format("{} {}", kind, count);
}

// " (DirectionRandomiser 1, SequenceFrame 4)": loại affector nào làm bao nhiêu hệ bị bỏ.
[[nodiscard]] std::string kinds_text(const fx::Tally& tally) {
    std::string text;
    for (const auto& [kind, count] : tally.affectors) {
        append_kind(text, kind, count);
    }
    return std::format(" ({})", text);
}

void append_reason(std::string& text, const fx::Tally& tally, fx::Skip skip) {
    const std::uint32_t count = tally.count(skip);
    if (count == 0) return;
    text += text.empty() ? ": " : "; ";
    text += std::format("{} {}", count, fx::describe(skip));
    if (skip == fx::Skip::kUnknownAffector) text += kinds_text(tally);
}

// Rỗng khi không bỏ gì; không thì ": 5 affector chưa hỗ trợ; 1 material không cộng sáng".
[[nodiscard]] std::string skipped_text(const fx::Tally& tally) {
    std::string text;
    for (const fx::Skip skip : fx::kSkips) {
        append_reason(text, tally, skip);
    }
    return text;
}

[[nodiscard]] double millis_since(core::Clock::time_point began) {
    return std::chrono::duration<double, std::milli>(core::Clock::now() - began).count();
}

struct KeptTexture {
    resource::Uploaded uploaded;
    gpu::BindGroupHandle group{};
};

// Bộ đệm đỉnh của một slot và số quad nó chứa được.
struct SlotBuffer {
    gpu::BufferHandle vertices{};
    std::uint32_t quads = 0;
};

struct BatchDraw {
    std::uint32_t texture = 0;
    std::uint32_t first = 0;
    std::uint32_t quads = 0;
    // Chỉ số fx::Blend, cũng là ô trong Body::pipelines.
    std::uint8_t kind = 0;
    // 0: không nhân ảnh thứ hai. Khác 0 là BLEND_OP_1 (1, 2 hoặc 4).
    float cover_gain = 0.0F;
};

// Hình của một khung: đỉnh của mọi lô nối nhau, bốn đỉnh một quad, và lệnh vẽ của từng lô.
struct Frame {
    std::vector<FxVertex> vertices;
    std::vector<BatchDraw> draws;
};

// Nơi ghi lệnh vẽ của khung.
struct Pass {
    gpu::CommandList* list = nullptr;
    const render::Camera* camera = nullptr;
    std::uint32_t slot = 0;
};

[[nodiscard]] resource::Image white_image() {
    resource::Image image;
    image.name = "fx.white";
    image.width = 1;
    image.height = 1;
    image.rgba = {255, 255, 255, 255};
    image.has_mips = false;
    return image;
}

void bind_texture(std::array<gpu::BindEntry, 4>& entries, std::uint32_t slot,
    gpu::TextureViewHandle view, gpu::SamplerHandle sampler) {
    const std::size_t base = static_cast<std::size_t>(slot) * 2U;
    entries[base].type = shader::RegisterType::kResource;
    entries[base].slot = slot;
    entries[base].resource = view;
    entries[base + 1].type = shader::RegisterType::kSampler;
    entries[base + 1].slot = slot;
    entries[base + 1].resource = sampler;
}

[[nodiscard]] bool uv_repeats(const fx::Paint& paint) noexcept {
    const bool slides = paint.scroll_u != 0.0F || paint.scroll_v != 0.0F;
    const bool shifted = paint.shift_u != 0.0F || paint.shift_v != 0.0F;
    const bool scaled = paint.scale_u != 1.0F || paint.scale_v != 1.0F;
    const bool cover_moves = paint.cover_scroll_u != 0.0F || paint.cover_scroll_v != 0.0F;
    const bool cover_shifted = paint.cover_shift_u != 0.0F || paint.cover_shift_v != 0.0F;
    const bool cover_scaled = paint.cover_scale_u != 1.0F || paint.cover_scale_v != 1.0F;
    return slides || shifted || scaled || cover_moves || cover_shifted || cover_scaled;
}

} // namespace

struct FxView::Body {
    gpu::Device* device = nullptr;
    std::array<gpu::PipelineHandle, fx::kDrawnBlends> pipelines{};
    // Mẫu chỉ số 0 1 2, 0 2 3 lặp cho từng quad, dùng chung cho mọi slot.
    gpu::BufferHandle indices{};
    std::uint32_t indexed_quads = 0;
    std::vector<SlotBuffer> slots;
    std::vector<KeptTexture> textures;
    // Ảnh đã tải theo đường dẫn và kiểu lặp của sampler; rỗng là ảnh không nạp được.
    std::map<std::string, std::optional<std::uint32_t>, std::less<>> by_image;
    // Lối tắt của texture_of theo chính material trong bảng của library (địa chỉ ổn định tới lần load kế):
    // mỗi lô mỗi khung chỉ còn một lần tra băm con trỏ, không dựng chuỗi khoá. load() xoá cùng library.
    std::unordered_map<const fx::Paint*, std::optional<std::uint32_t>> by_paint;
    // Đỉnh và lệnh vẽ của khung, giữ qua các khung để không cấp phát lại.
    Frame scratch;
    std::unique_ptr<fx::Library> library;
    std::unique_ptr<fx::Cast> cast;
    std::filesystem::path data_root;
    // Bản texture của thiết bị (FxView::load); kBc là ảnh gốc của PC.
    resource::TextureTier tier = resource::TextureTier::kBc;
    // Tuổi của cảnh đang vẽ và các số đo cho dòng log một lần của nó.
    float scene_age = 0.0F;
    double decode_ms = 0.0;
    bool is_reported = false;
    bool has_complained = false;

    Body() = default;
    Body(const Body&) = delete;
    Body& operator=(const Body&) = delete;
    Body(Body&&) = delete;
    Body& operator=(Body&&) = delete;
    ~Body();

    [[nodiscard]] core::Result<resource::Image> cover_image(const fx::Paint& paint) const;
    [[nodiscard]] core::Result<std::uint32_t> add_image(const resource::Image& image, const resource::Image& cover,
        bool repeats);
    [[nodiscard]] core::Result<std::uint32_t> load_texture(const fx::Paint& paint);
    [[nodiscard]] std::optional<std::uint32_t> texture_of(const fx::Paint& paint);
    void take_batch(Frame& frame, const fx::BillboardBatch& batch);
    // Nạp trước ảnh của mọi hệ đang sống, để lần vẽ đầu của cảnh không đọc đĩa và giải mã ảnh giữa khung.
    void warm_textures();
    [[nodiscard]] core::Status grow_indices(std::uint32_t quads);
    [[nodiscard]] core::Status grow_vertices(SlotBuffer& buffer, std::uint32_t quads) const;
    [[nodiscard]] core::Status submit(const Pass& pass, const Frame& frame);
    void draw_batch(gpu::CommandList& list, const BatchDraw& draw) const;
    void report_adopted(std::size_t places) const;
    void report_frame(const Frame& frame, std::size_t fields);
    void complain(const core::Error& error);
};

FxView::Body::~Body() {
    if (device == nullptr) return;
    for (const KeptTexture& texture : textures) {
        device->destroy(texture.group);
    }
    for (const SlotBuffer& buffer : slots) {
        device->destroy(buffer.vertices);
    }
    device->destroy(indices);
}

core::Result<std::uint32_t> FxView::Body::add_image(const resource::Image& image,
    const resource::Image& cover, bool repeats) {
    const resource::Model model = model_of(image, cover, repeats);
    core::Result<resource::Uploaded> uploaded = resource::upload_queued(*device, model);
    if (!uploaded) return std::unexpected(uploaded.error());
    if (uploaded->images().size() < 2 || uploaded->samplers().empty()) {
        return core::fail(core::ErrorCode::kInvalidArgument, "thiếu ảnh hạt");
    }
    const gpu::SamplerHandle sampler = uploaded->samplers().front();
    std::array<gpu::BindEntry, 4> entries;
    bind_texture(entries, 0, uploaded->images()[0].view, sampler);
    bind_texture(entries, 1, uploaded->images()[1].view, sampler);
    gpu::BindGroupDesc group;
    group.name = "fx.texture";
    group.pipeline = pipelines[static_cast<std::size_t>(fx::Blend::kAdd)];
    group.space = kTextureSpace;
    group.entries = entries;
    const core::Result<gpu::BindGroupHandle> bound = device->create_bind_group(group);
    if (!bound) return std::unexpected(bound.error());
    textures.push_back(KeptTexture{.uploaded = std::move(*uploaded), .group = *bound});
    return static_cast<std::uint32_t>(textures.size() - 1);
}

core::Result<resource::Image> FxView::Body::cover_image(const fx::Paint& paint) const {
    if (paint.cover_gain <= 0.0F) return white_image();
    core::Result<resource::Image> mask = read_image(data_root, paint.second, tier);
    if (!mask) return std::unexpected(mask.error());
    mask->name = paint.second;
    return std::move(*mask);
}

core::Result<std::uint32_t> FxView::Body::load_texture(const fx::Paint& paint) {
    core::Result<resource::Image> image = read_image(data_root, paint.image, tier);
    if (!image) return std::unexpected(image.error());
    image->name = paint.image;
    core::Result<resource::Image> cover = cover_image(paint);
    if (!cover) return std::unexpected(cover.error());
    return add_image(*image, *cover, uv_repeats(paint));
}

// Mỗi ảnh chỉ đọc đĩa một lần cho mỗi cách dùng alpha; ảnh hỏng được nhớ để không đọc lại mỗi khung.
std::optional<std::uint32_t> FxView::Body::texture_of(const fx::Paint& paint) {
    const std::string key = std::format("{}|{}|{}", paint.image, paint.second, uv_repeats(paint));
    const auto found = by_image.find(key);
    if (found != by_image.end()) return found->second;
    const core::Clock::time_point began = core::Clock::now();
    const core::Result<std::uint32_t> loaded = load_texture(paint);
    decode_ms += millis_since(began);
    if (!loaded) std::println(stderr, "Hiệu ứng: bỏ ảnh {}: {}", paint.image, loaded.error());
    const std::optional<std::uint32_t> texture = loaded ? std::optional<std::uint32_t>(*loaded) : std::nullopt;
    by_image.emplace(key, texture);
    return texture;
}

// Lô không có trong bảng, hoặc kiểu trộn chưa có pipeline, thì bỏ. Không vẽ bằng ảnh thay thế.
void FxView::Body::take_batch(Frame& frame, const fx::BillboardBatch& batch) {
    const fx::Paint* paint = library->palette().find(batch.material);
    if (paint == nullptr) return;
    const auto kind = static_cast<std::size_t>(paint->blend);
    if (kind >= pipelines.size() || !pipelines[kind]) return;
    const auto cached = by_paint.find(paint);
    const std::optional<std::uint32_t> texture =
        cached != by_paint.end() ? cached->second : by_paint.emplace(paint, texture_of(*paint)).first->second;
    const std::size_t quads = batch.vertices.size() / 4U;
    if (!texture || quads == 0) return;
    BatchDraw draw;
    draw.texture = *texture;
    draw.first = static_cast<std::uint32_t>(frame.vertices.size() / 4U);
    draw.quads = static_cast<std::uint32_t>(quads);
    draw.kind = static_cast<std::uint8_t>(kind);
    draw.cover_gain = paint->cover_gain;
    for (const fx::BillboardVertex& source : std::span(batch.vertices).first(quads * 4U)) {
        FxVertex vertex = vertex_of(source, paint->gain);
        place_uv(vertex.u, vertex.v, source.u, source.v, paint->scale_u, paint->scale_v,
            paint->shift_u, paint->shift_v, paint->scroll_u, paint->scroll_v, scene_age);
        place_uv(vertex.cover_u, vertex.cover_v, source.u, source.v, paint->cover_scale_u,
            paint->cover_scale_v, paint->cover_shift_u, paint->cover_shift_v, paint->cover_scroll_u,
            paint->cover_scroll_v, scene_age);
        frame.vertices.push_back(vertex);
    }
    frame.draws.push_back(draw);
}

void FxView::Body::warm_textures() {
    for (const fx::Field* field : cast->live()) {
        const fx::Paint* paint = library->palette().find(field->definition().material);
        if (paint == nullptr || paint->blend == fx::Blend::kOther) continue;
        if (by_paint.find(paint) == by_paint.end()) by_paint.emplace(paint, texture_of(*paint));
    }
}

// Huỷ buffer là huỷ hoãn (gpu/device.hpp), nên khung còn ở GPU vẫn đọc được mẫu chỉ số cũ.
core::Status FxView::Body::grow_indices(std::uint32_t quads) {
    if (quads <= indexed_quads) return core::ok();
    const std::uint32_t room = std::bit_ceil(std::max(quads, kFirstQuads));
    std::vector<std::uint32_t> pattern;
    pattern.reserve(std::size_t{room} * 6U);
    for (std::uint32_t quad = 0; quad < room; ++quad) {
        const std::uint32_t base = quad * 4U;
        // Đỉnh theo thứ tự chữ Z như fx/billboard.cpp đẩy (trên-trái, trên-phải, dưới-trái, dưới-phải). Mẫu
        // 0 1 2, 0 2 3 của quad giao diện (đỉnh xoay vòng) chỉ phủ 75% ô: mất cái nêm bên phải của mọi sprite.
        const std::array<std::uint32_t, 6> corner{base, base + 1U, base + 2U, base + 2U, base + 1U, base + 3U};
        pattern.insert(pattern.end(), corner.begin(), corner.end());
    }
    gpu::BufferDesc description;
    description.name = "fx.indices";
    description.size = pattern.size() * sizeof(std::uint32_t);
    description.usage = gpu::BufferUsage::kIndex;
    description.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made = device->create_buffer(description);
    if (!made) return std::unexpected(made.error());
    device->destroy(indices);
    indices = *made;
    indexed_quads = room;
    return device->write_buffer(indices, 0, std::as_bytes(std::span(pattern)));
}

// Slot là ảnh swapchain vừa acquire: GPU đã vẽ xong khung trước của nó, nên buffer của slot không
// còn được đọc và thay được ngay.
core::Status FxView::Body::grow_vertices(SlotBuffer& buffer, std::uint32_t quads) const {
    if (quads <= buffer.quads) return core::ok();
    const std::uint32_t room = std::bit_ceil(std::max(quads, kFirstQuads));
    gpu::BufferDesc description;
    description.name = "fx.vertices";
    description.size = std::uint64_t{room} * 4U * sizeof(FxVertex);
    description.usage = gpu::BufferUsage::kVertex;
    description.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made = device->create_buffer(description);
    if (!made) return std::unexpected(made.error());
    device->destroy(buffer.vertices);
    buffer.vertices = *made;
    buffer.quads = room;
    return core::ok();
}

namespace {

struct FxGpuPush {
    std::array<math::Float4, 4> view_proj{};
    math::Float4 mode{};
};

void bind_fx(gpu::CommandList& list, const render::Camera& camera, gpu::PipelineHandle pipeline, float cover_gain) {
    FxGpuPush push;
    push.view_proj = math::store(camera.projection * camera.view);
    push.mode.x = cover_gain;
    list.bind_pipeline(pipeline);
    list.push_constants(std::as_bytes(std::span(&push, 1)), 0);
}

} // namespace

void FxView::Body::draw_batch(gpu::CommandList& list, const BatchDraw& draw) const {
    list.bind_group(kTextureSpace, textures.at(draw.texture).group);
    gpu::DrawIndexedArguments arguments;
    arguments.index_count = draw.quads * 6U;
    arguments.first_index = draw.first * 6U;
    list.draw_indexed(arguments);
}

core::Status FxView::Body::submit(const Pass& pass, const Frame& frame) {
    const auto quads = static_cast<std::uint32_t>(frame.vertices.size() / 4U);
    const core::Status indexed = grow_indices(quads);
    if (!indexed) return indexed;
    if (pass.slot >= slots.size()) slots.resize(std::size_t{pass.slot} + 1U);
    SlotBuffer& buffer = slots.at(pass.slot);
    const core::Status roomy = grow_vertices(buffer, quads);
    if (!roomy) return roomy;
    const core::Status written = device->write_buffer(buffer.vertices, 0, std::as_bytes(std::span(frame.vertices)));
    if (!written) return written;
    pass.list->bind_vertex_buffer(0, buffer.vertices, 0);
    pass.list->bind_index_buffer(indices, gpu::IndexType::kUint32, 0);
    for (const BatchDraw& draw : frame.draws) {
        bind_fx(*pass.list, *pass.camera, pipelines[draw.kind], draw.cover_gain);
        draw_batch(*pass.list, draw);
    }
    return core::ok();
}

void FxView::Body::report_adopted(std::size_t places) const {
    const fx::Tally& tally = cast->tally();
    const std::string skipped = skipped_text(tally);
    std::println("Hiệu ứng: {} chỗ đặt thành {} hệ hạt và {} dải; bỏ {}{}", places, tally.systems, tally.strips,
        tally.total_skipped(), skipped);
}

void FxView::Body::report_frame(const Frame& frame, std::size_t fields) {
    if (is_reported || scene_age < kReportAfter) return;
    is_reported = true;
    const std::size_t quads = frame.vertices.size() / 4U;
    std::println("Hiệu ứng: khung có {} quad trong {} lô từ {} Field; {} ảnh đã tải trong {:.1f} ms", quads,
        frame.draws.size(), fields, textures.size(), decode_ms);
}

// Lỗi vẽ lặp lại mỗi khung: chỉ ghi lần đầu.
void FxView::Body::complain(const core::Error& error) {
    if (has_complained) return;
    has_complained = true;
    std::println(stderr, "Hiệu ứng: không vẽ được khung: {}", error);
}

FxView::FxView(std::unique_ptr<Body> body) : body_(std::move(body)) {}
FxView::FxView(FxView&&) noexcept = default;
FxView& FxView::operator=(FxView&&) noexcept = default;
FxView::~FxView() = default;

std::unique_ptr<FxView> FxView::open(gpu::Device& device,
    std::span<const gpu::PipelineHandle> pipelines) {
    const std::size_t add = static_cast<std::size_t>(fx::Blend::kAdd);
    const bool has_add = pipelines.size() == fx::kDrawnBlends && static_cast<bool>(pipelines[add]);
    if (!has_add) {
        std::println(stderr, "Hiệu ứng: bỏ qua, không dựng được bộ vẽ");
        return nullptr;
    }
    auto body = std::make_unique<Body>();
    body->device = &device;
    for (std::size_t index = 0; index < pipelines.size(); ++index)
        body->pipelines[index] = pipelines[index];
    return std::unique_ptr<FxView>(new FxView(std::move(body)));
}

void FxView::load(const std::filesystem::path& data_root, resource::TextureTier tier) {
    const core::Clock::time_point began = core::Clock::now();
    const std::filesystem::path folder = data_root / "effect";
    io::TextResult particles = io::read_text(folder / "all.particle");
    io::TextResult effects = io::read_text(folder / "all.effect");
    io::TextResult materials = io::read_text(folder / "materials.tsv");
    if (!particles || !effects || !materials) {
        const std::string where = io::utf8_of(folder);
        std::println(stderr, "Hiệu ứng: bỏ qua, {} thiếu all.particle, all.effect hoặc materials.tsv", where);
        return;
    }
    const std::size_t bytes = particles->size() + effects->size() + materials->size();
    fx::LibraryText text;
    text.particles = std::move(*particles);
    text.effects = std::move(*effects);
    text.materials = std::move(*materials);
    body_->cast.reset();
    body_->by_paint.clear();
    body_->data_root = data_root;
    body_->tier = tier;
    body_->library = std::make_unique<fx::Library>(std::move(text));
    body_->cast = std::make_unique<fx::Cast>(body_->library.get());
    const std::size_t paints = body_->library->palette().size();
    std::println("Hiệu ứng: nạp thư viện {:.1f} ms, {} byte, {} material", millis_since(began), bytes, paints);
}

std::uint32_t FxView::spawn(const fx::Spawn& spawn) {
    if (!body_->cast) return 0;
    const std::uint32_t handle = body_->cast->add(spawn);
    body_->warm_textures();
    return handle;
}

void FxView::move(std::uint32_t handle, const fx::Node& node) {
    if (body_->cast) body_->cast->move(handle, node);
}

void FxView::release(std::uint32_t handle) {
    if (body_->cast) body_->cast->release(handle);
}

bool FxView::is_live(std::uint32_t handle) const {
    return body_->cast && body_->cast->is_live(handle);
}

void FxView::adopt(const Stage& stage) {
    if (!body_->cast) return;
    body_->cast->clear();
    body_->scene_age = 0.0F;
    body_->is_reported = false;
    for (const FxPlace& place : stage.effects) {
        if (is_mist(place.name)) continue;
        const fx::Spawn spawn = spawn_of(place);
        body_->cast->add(spawn);
    }
    body_->warm_textures();
    body_->report_adopted(stage.effects.size());
}

void FxView::advance(float seconds) {
    if (!body_->cast || seconds < 0.0F) return;
    body_->scene_age += seconds;
    body_->cast->update(seconds);
}

std::vector<const fx::Field*> FxView::fields() const {
    if (!body_->cast) return {};
    return body_->cast->live();
}

const fx::Paint* FxView::paint(std::string_view material) const {
    if (!body_->library) return nullptr;
    return body_->library->palette().find(material);
}

void FxView::draw(gpu::CommandList& list, std::uint32_t slot, const render::Camera& camera,
    std::span<const fx::BillboardBatch> extra) {
    if (!body_->cast) return;
    const std::vector<const fx::Field*> fields = body_->cast->live();
    const fx::CameraAxes axes = axes_of(camera);
    std::vector<fx::BillboardBatch> batches = fx::billboards_of(fields, axes);
    std::vector<fx::BillboardBatch> strips = body_->cast->strips(axes);
    std::ranges::move(strips, std::back_inserter(batches));
    batches.insert(batches.end(), extra.begin(), extra.end());
    Frame& frame = body_->scratch;
    frame.vertices.clear();
    frame.draws.clear();
    std::size_t corners = 0;
    for (const fx::BillboardBatch& batch : batches) {
        corners += batch.vertices.size();
    }
    frame.vertices.reserve(corners);
    frame.draws.reserve(batches.size());
    for (const fx::BillboardBatch& batch : batches) {
        body_->take_batch(frame, batch);
    }
    body_->report_frame(frame, fields.size());
    if (frame.draws.empty()) return;
    const Pass pass{.list = &list, .camera = &camera, .slot = slot};
    const core::Status drawn = body_->submit(pass, frame);
    if (!drawn) body_->complain(drawn.error());
}

} // namespace game::client
