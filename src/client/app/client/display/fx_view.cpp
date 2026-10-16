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
};
static_assert(sizeof(FxVertex) == render::kFxStride);
static_assert(offsetof(FxVertex, u) == render::kFxUv);
static_assert(offsetof(FxVertex, red) == render::kFxColour);

[[nodiscard]] resource::Model model_of(const resource::Image& image, bool repeats) {
    resource::Model model;
    model.images.push_back(image);
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

// Cách shader đọc ảnh (FxPush::mode.y). Ảnh nén của điện thoại không sửa từng điểm ảnh ở CPU được, nên alpha của kiểu
// "one one" và độ tối của khói do shader tính.
enum class ImageUse : std::uint8_t { kKeep = 0, kOpaque = 1, kSmoke = 2 };

[[nodiscard]] ImageUse image_use_of(fx::Blend blend) noexcept {
    if (blend == fx::Blend::kAdd) return ImageUse::kOpaque;
    if (blend == fx::Blend::kDarken) return ImageUse::kSmoke;
    return ImageUse::kKeep;
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

// Cách đổi màu đỉnh của fx sang màu shader nhận, theo material của lô.
struct Tint {
    float gain = 1.0F;
    // Sai với kiểu trộn "one one": alpha của đỉnh không tham gia, shader nhận 1.
    bool keeps_alpha = true;
};

[[nodiscard]] float unit(float value) noexcept {
    return std::clamp(value, 0.0F, 1.0F);
}

[[nodiscard]] FxVertex vertex_of(const fx::BillboardVertex& source, Tint tint) noexcept {
    FxVertex vertex;
    vertex.x = source.x;
    vertex.y = source.y;
    vertex.z = source.z;
    vertex.u = source.u;
    vertex.v = source.v;
    vertex.red = unit(source.red) * tint.gain;
    vertex.green = unit(source.green) * tint.gain;
    vertex.blue = unit(source.blue) * tint.gain;
    vertex.alpha = tint.keeps_alpha ? unit(source.alpha) : 1.0F;
    return vertex;
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
    // src_alpha one_minus_src_alpha: pipeline trộn alpha, shader không nhân sẵn alpha vào rgb.
    bool is_straight = false;
    ImageUse use = ImageUse::kKeep;
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

} // namespace

struct FxView::Body {
    gpu::Device* device = nullptr;
    gpu::PipelineHandle pipeline{};
    gpu::PipelineHandle blend_pipeline{};
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

    [[nodiscard]] core::Result<std::uint32_t> add_image(const resource::Image& image, bool repeats);
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

core::Result<std::uint32_t> FxView::Body::add_image(const resource::Image& image, bool repeats) {
    const resource::Model model = model_of(image, repeats);
    core::Result<resource::Uploaded> uploaded = resource::upload_queued(*device, model);
    if (!uploaded) return std::unexpected(uploaded.error());
    std::array<gpu::BindEntry, 2> entries;
    entries.front().type = shader::RegisterType::kResource;
    entries.front().resource = uploaded->images().front().view;
    entries.back().type = shader::RegisterType::kSampler;
    entries.back().resource = uploaded->samplers().front();
    gpu::BindGroupDesc group;
    group.name = "fx.texture";
    group.pipeline = pipeline;
    group.space = kTextureSpace;
    group.entries = entries;
    const core::Result<gpu::BindGroupHandle> bound = device->create_bind_group(group);
    if (!bound) return std::unexpected(bound.error());
    textures.push_back(KeptTexture{.uploaded = std::move(*uploaded), .group = *bound});
    return static_cast<std::uint32_t>(textures.size() - 1);
}

core::Result<std::uint32_t> FxView::Body::load_texture(const fx::Paint& paint) {
    core::Result<resource::Image> image = read_image(data_root, paint.image, tier);
    if (!image) return std::unexpected(image.error());
    image->name = paint.image;
    const bool repeats =
        paint.scroll_u != 0.0F || paint.scroll_v != 0.0F || paint.scale_u != 1.0F || paint.scale_v != 1.0F;
    return add_image(*image, repeats);
}

// Mỗi ảnh chỉ đọc đĩa một lần cho mỗi cách dùng alpha; ảnh hỏng được nhớ để không đọc lại mỗi khung.
std::optional<std::uint32_t> FxView::Body::texture_of(const fx::Paint& paint) {
    const bool repeats =
        paint.scroll_u != 0.0F || paint.scroll_v != 0.0F || paint.scale_u != 1.0F || paint.scale_v != 1.0F;
    const std::string key = std::format("{}|{}", paint.image, repeats);
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
    if (paint == nullptr || paint->blend == fx::Blend::kOther) return;
    const bool is_straight = paint->blend == fx::Blend::kAlpha || paint->blend == fx::Blend::kDarken;
    if (is_straight && !blend_pipeline) return;
    const auto cached = by_paint.find(paint);
    const std::optional<std::uint32_t> texture =
        cached != by_paint.end() ? cached->second : by_paint.emplace(paint, texture_of(*paint)).first->second;
    const std::size_t quads = batch.vertices.size() / 4U;
    if (!texture || quads == 0) return;
    BatchDraw draw;
    draw.texture = *texture;
    draw.first = static_cast<std::uint32_t>(frame.vertices.size() / 4U);
    draw.quads = static_cast<std::uint32_t>(quads);
    draw.is_straight = is_straight;
    draw.use = image_use_of(paint->blend);
    const Tint tint{.gain = paint->gain, .keeps_alpha = paint->blend != fx::Blend::kAdd};
    const float shift_u = paint->scroll_u * scene_age;
    const float shift_v = paint->scroll_v * scene_age;
    for (const fx::BillboardVertex& source : std::span(batch.vertices).first(quads * 4U)) {
        fx::BillboardVertex shifted = source;
        shifted.u = (source.u * paint->scale_u) + shift_u;
        shifted.v = (source.v * paint->scale_v) + shift_v;
        frame.vertices.push_back(vertex_of(shifted, tint));
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

struct FxBind {
    gpu::PipelineHandle pipeline{};
    bool straight = false;
    ImageUse use = ImageUse::kKeep;
};

void bind_fx(gpu::CommandList& list, const render::Camera& camera, const FxBind& bind) {
    FxGpuPush push;
    push.view_proj = math::store(camera.projection * camera.view);
    push.mode.x = bind.straight ? 1.0F : 0.0F;
    push.mode.y = static_cast<float>(bind.use);
    list.bind_pipeline(bind.pipeline);
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
        const FxBind bind{.pipeline = draw.is_straight ? blend_pipeline : pipeline,
            .straight = draw.is_straight,
            .use = draw.use};
        bind_fx(*pass.list, *pass.camera, bind);
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

std::unique_ptr<FxView> FxView::open(gpu::Device& device, gpu::PipelineHandle pipeline, gpu::PipelineHandle blend) {
    if (!pipeline) {
        std::println(stderr, "Hiệu ứng: bỏ qua, không dựng được bộ vẽ");
        return nullptr;
    }
    auto body = std::make_unique<Body>();
    body->device = &device;
    body->pipeline = pipeline;
    body->blend_pipeline = blend;
    if (!blend) std::println(stderr, "Hiệu ứng: không có pipeline trộn alpha, sương và bọt suối không vẽ");
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
