// Một pipeline trộn alpha không độ sâu cho mọi quad giao diện. Register space của shader: 1 là ảnh
// (t0, s0) và mặt nạ (t1, s1) của lô; hằng của lệnh vẽ (cỡ vùng vẽ, ô mặt nạ) đi bằng push
// constant. Một khung: ghi đỉnh của mọi quad vào buffer của slot, rồi mỗi lô là một lệnh vẽ chỉ số
// trên khối chỉ số dùng chung. Mỗi texture có sẵn một nhóm gắn với mặt nạ trắng (không che); nhóm
// của cặp (ảnh, mặt nạ) khác chỉ dựng khi lô đầu tiên dùng tới và giữ lại cho các khung sau.
// Nguồn: bản mới của dự án, theo mẫu render/forward.cpp (nhóm chất liệu, slot). Pipeline do
// Catalog tạo và đưa vào; UiPass không nạp shader và không huỷ pipeline.
#include "render/ui.hpp"

#include "core/error.hpp"
#include "gpu/binding.hpp"
#include "gpu/command.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/upload.hpp"
#include "shader/reflection.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::render {

namespace {

constexpr std::uint32_t kMaxQuadCount = 1U << 15;
constexpr std::uint32_t kStartQuads = 2048;
constexpr std::uint32_t kVerticesPerQuad = 4;
constexpr std::uint32_t kIndicesPerQuad = 6;
constexpr std::uint32_t kTextureSpace = 1;
// Register của ảnh và của mặt nạ trong space 1 (t và s cùng số).
constexpr std::uint32_t kImageSlot = 0;
constexpr std::uint32_t kMaskSlot = 1;

// Khớp struct Screen của ui.hlsli.
struct ScreenBlock {
    // Rộng, cao của vùng vẽ; thành phần z là 1 khi ảnh của lô chứa màu đã nhân alpha, 0 khi là ảnh
    // thẳng (UiTexture::is_premultiplied).
    std::array<float, 4> size{};
    // Ô mặt nạ của lô: trái, trên, rộng, cao.
    std::array<float, 4> mask{0.0F, 0.0F, 1.0F, 1.0F};
};
static_assert(sizeof(ScreenBlock) == 32);

// Chỉ số của khối quad dùng chung: quad n dùng đỉnh 4n, 4n + 1, 4n + 2 rồi 4n, 4n + 2, 4n + 3.
std::vector<std::uint32_t> quad_indices() {
    std::vector<std::uint32_t> indices;
    indices.reserve(std::size_t{kMaxQuadCount} * kIndicesPerQuad);
    for (std::uint32_t quad = 0; quad < kMaxQuadCount; ++quad) {
        const std::uint32_t base = quad * kVerticesPerQuad;
        const std::array<std::uint32_t, kIndicesPerQuad> corner = {base, base + 1, base + 2, base, base + 2, base + 3};
        indices.insert(indices.end(), corner.begin(), corner.end());
    }
    return indices;
}

// Mô hình một ảnh một chất liệu: chất liệu nhận ảnh làm màu nền nên tải lên ở dạng sRGB; sampler
// kẹp mép, lọc tuyến tính, không mip.
resource::Model model_of(const resource::Image& image) {
    resource::Model model;
    model.images.push_back(image);
    model.images.back().has_mips = false;
    resource::Sampler sampler;
    sampler.name = "render.ui";
    sampler.wrap_u = resource::Wrap::kClamp;
    sampler.wrap_v = resource::Wrap::kClamp;
    sampler.has_mip = false;
    model.samplers.push_back(sampler);
    resource::Material material;
    material.name = "render.ui";
    material.color.image = 0;
    material.color.sampler = 0;
    model.materials.push_back(material);
    return model;
}

// Một texture của giao diện: view và sampler để gắn, cùng nhóm gắn nó với mặt nạ trắng. uploaded
// giữ ảnh do UiPass tự tải lên; rỗng khi view là của nơi gọi (add_view).
struct UiTexture {
    std::optional<resource::Uploaded> uploaded;
    gpu::TextureViewHandle view{};
    gpu::SamplerHandle sampler{};
    gpu::BindGroupHandle group{};
    // View của nơi gọi (add_view) là ảnh của Canvas: màu đã nhân alpha.
    bool is_premultiplied = false;
};

// Nhóm gắn của một cặp (ảnh, mặt nạ) có mặt nạ thật.
struct MaskedGroup {
    std::uint32_t texture = kUiWhite;
    std::uint32_t mask = kUiWhite;
    gpu::BindGroupHandle group{};
};

// Buffer đỉnh của một slot và số quad nó chứa được.
struct Slot {
    gpu::BufferHandle vertices{};
    std::uint32_t capacity = 0;
};

} // namespace

struct UiPass::State {
    State() = default;
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;
    ~State();

    [[nodiscard]] core::Status open();
    [[nodiscard]] core::Status make_indices();
    [[nodiscard]] core::Status grow(Slot& slot, std::uint32_t quads) const;
    [[nodiscard]] core::Result<gpu::BindGroupHandle> make_group(const UiTexture& image, const UiTexture& mask) const;
    [[nodiscard]] core::Result<UiTexture> make_texture(const resource::Image& image) const;
    [[nodiscard]] core::Result<std::uint32_t> add_texture(const resource::Image& image);
    [[nodiscard]] core::Result<std::uint32_t> add_view(gpu::TextureViewHandle view);
    [[nodiscard]] core::Status replace_texture(std::uint32_t index, const resource::Image& image);
    void drop_masked(std::uint32_t index);
    [[nodiscard]] std::optional<gpu::BindGroupHandle> group_of(const UiBatch& batch);
    void draw_batch(gpu::CommandList& list, const UiBatch& batch, UiScreen screen);

    gpu::Device* device = nullptr;
    UiDesc desc;
    gpu::PipelineHandle pipeline{};
    gpu::BufferHandle indices{};
    std::vector<Slot> slots;
    std::vector<UiTexture> textures;
    std::vector<MaskedGroup> masked;
    std::uint32_t draws = 0;
};

UiPass::State::~State() {
    if (device == nullptr) return;
    for (const MaskedGroup& pair : masked)
        device->destroy(pair.group);
    for (const UiTexture& texture : textures)
        device->destroy(texture.group);
    for (const Slot& slot : slots)
        device->destroy(slot.vertices);
    device->destroy(indices);
}

core::Status UiPass::State::make_indices() {
    const std::vector<std::uint32_t> values = quad_indices();
    gpu::BufferDesc buffer;
    buffer.name = "render.ui.indices";
    buffer.size = std::uint64_t{values.size()} * sizeof(std::uint32_t);
    buffer.usage = gpu::BufferUsage::kIndex;
    buffer.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made = device->create_buffer(buffer);
    if (!made) return std::unexpected(made.error());
    indices = *made;
    return device->write_buffer(indices, 0, std::as_bytes(std::span(values)));
}

// Buffer đỉnh của slot đủ chỗ cho quads quad; tăng gấp đôi khi thiếu.
core::Status UiPass::State::grow(Slot& slot, std::uint32_t quads) const {
    if (quads <= slot.capacity) return core::ok();
    const std::uint32_t wanted = std::max({quads, slot.capacity * 2, kStartQuads});
    const std::uint32_t count = std::min(kMaxQuadCount, wanted);
    gpu::BufferDesc buffer;
    buffer.name = "render.ui.vertices";
    buffer.size = std::uint64_t{count} * kVerticesPerQuad * sizeof(UiVertex);
    buffer.usage = gpu::BufferUsage::kVertex;
    buffer.memory = gpu::MemoryDomain::kUpload;
    const core::Result<gpu::BufferHandle> made = device->create_buffer(buffer);
    if (!made) return std::unexpected(made.error());
    device->destroy(slot.vertices);
    slot.vertices = *made;
    slot.capacity = count;
    return core::ok();
}

// Nhóm gắn một ảnh (t0, s0) cùng mặt nạ của nó (t1, s1).
core::Result<gpu::BindGroupHandle> UiPass::State::make_group(const UiTexture& image, const UiTexture& mask) const {
    std::array<gpu::BindEntry, 4> entries;
    entries.at(0).type = shader::RegisterType::kResource;
    entries.at(0).slot = kImageSlot;
    entries.at(0).resource = image.view;
    entries.at(1).type = shader::RegisterType::kSampler;
    entries.at(1).slot = kImageSlot;
    entries.at(1).resource = image.sampler;
    entries.at(2).type = shader::RegisterType::kResource;
    entries.at(2).slot = kMaskSlot;
    entries.at(2).resource = mask.view;
    entries.at(3).type = shader::RegisterType::kSampler;
    entries.at(3).slot = kMaskSlot;
    entries.at(3).resource = mask.sampler;
    gpu::BindGroupDesc group;
    group.name = "render.ui.texture";
    group.pipeline = pipeline;
    group.space = kTextureSpace;
    group.entries = entries;
    return device->create_bind_group(group);
}

// Tải ảnh lên và gắn nó với mặt nạ trắng. Texture đầu tiên (điểm trắng) tự làm mặt nạ của mình.
core::Result<UiTexture> UiPass::State::make_texture(const resource::Image& image) const {
    const resource::Model model = model_of(image);
    core::Result<resource::Uploaded> uploaded = resource::upload_queued(*device, model);
    if (!uploaded) return std::unexpected(uploaded.error());
    UiTexture made;
    made.view = uploaded->images().front().view;
    made.sampler = uploaded->samplers().front();
    made.uploaded = std::move(*uploaded);
    const UiTexture& white = textures.empty() ? made : textures.front();
    const core::Result<gpu::BindGroupHandle> bound = make_group(made, white);
    if (!bound) return std::unexpected(bound.error());
    made.group = *bound;
    return made;
}

// Ảnh của nơi gọi: dùng sampler của điểm trắng (kẹp mép, lọc tuyến tính, không mip).
core::Result<std::uint32_t> UiPass::State::add_view(gpu::TextureViewHandle view) {
    UiTexture made;
    made.view = view;
    made.sampler = textures.front().sampler;
    made.is_premultiplied = true;
    const core::Result<gpu::BindGroupHandle> bound = make_group(made, textures.front());
    if (!bound) return std::unexpected(bound.error());
    made.group = *bound;
    textures.push_back(std::move(made));
    return static_cast<std::uint32_t>(textures.size() - 1);
}

core::Result<std::uint32_t> UiPass::State::add_texture(const resource::Image& image) {
    core::Result<UiTexture> made = make_texture(image);
    if (!made) return std::unexpected(made.error());
    textures.push_back(std::move(*made));
    return static_cast<std::uint32_t>(textures.size() - 1);
}

core::Status UiPass::State::replace_texture(std::uint32_t index, const resource::Image& image) {
    const bool is_known = index != kUiWhite && index < textures.size();
    const bool is_replaceable = is_known && textures.at(index).uploaded.has_value();
    if (!is_replaceable) {
        return core::fail(core::ErrorCode::kInvalidArgument, "texture giao diện không thay được");
    }
    core::Result<UiTexture> made = make_texture(image);
    if (!made) return std::unexpected(made.error());
    drop_masked(index);
    UiTexture& kept = textures.at(index);
    device->destroy(kept.group);
    kept = std::move(*made);
    return core::ok();
}

// Bỏ mọi nhóm cặp có texture index (làm ảnh hay làm mặt nạ): ảnh của nó sắp bị thay.
void UiPass::State::drop_masked(std::uint32_t index) {
    const auto uses = [index](const MaskedGroup& pair) { return pair.texture == index || pair.mask == index; };
    for (const MaskedGroup& pair : masked | std::views::filter(uses))
        device->destroy(pair.group);
    std::erase_if(masked, uses);
}

// Nhóm gắn của lô. Chỉ số lạ coi là điểm trắng. Lô có mặt nạ thật dùng nhóm của cặp, dựng lần
// đầu gặp; dựng hỏng thì nullopt và lô không vẽ, như renderer gốc bỏ batch khi thiếu mặt nạ.
std::optional<gpu::BindGroupHandle> UiPass::State::group_of(const UiBatch& batch) {
    const std::uint32_t texture = batch.texture < textures.size() ? batch.texture : kUiWhite;
    const std::uint32_t mask = batch.mask < textures.size() ? batch.mask : kUiWhite;
    if (mask == kUiWhite) return textures.at(texture).group;
    const auto is_pair = [texture, mask](const MaskedGroup& pair) {
        return pair.texture == texture && pair.mask == mask;
    };
    const auto known = std::ranges::find_if(masked, is_pair);
    if (known != masked.end()) return known->group;
    const core::Result<gpu::BindGroupHandle> made = make_group(textures.at(texture), textures.at(mask));
    if (!made) return std::nullopt;
    masked.push_back(MaskedGroup{.texture = texture, .mask = mask, .group = *made});
    return *made;
}

void UiPass::State::draw_batch(gpu::CommandList& list, const UiBatch& batch, UiScreen screen) {
    const UiRect& box = batch.mask_box;
    if (!(box.width > 0.0F) || !(box.height > 0.0F)) return;
    const std::optional<gpu::BindGroupHandle> group = group_of(batch);
    if (!group) return;
    const std::uint32_t texture = batch.texture < textures.size() ? batch.texture : kUiWhite;
    const float premultiplied = textures.at(texture).is_premultiplied ? 1.0F : 0.0F;
    const ScreenBlock block{.size = {screen.width, screen.height, premultiplied, 0.0F},
        .mask = {box.x, box.y, box.width, box.height}};
    list.push_constants(std::as_bytes(std::span(&block, 1)), 0);
    list.bind_group(kTextureSpace, *group);
    gpu::DrawIndexedArguments draw;
    draw.index_count = batch.quad_count * kIndicesPerQuad;
    draw.first_index = batch.first_quad * kIndicesPerQuad;
    list.draw_indexed(draw);
    ++draws;
}

core::Status UiPass::State::open() {
    const core::Status shared = make_indices();
    if (!shared) return shared;
    slots.resize(std::max(desc.slots, 1U));
    resource::Image white;
    white.name = "render.ui.white";
    white.width = 1;
    white.height = 1;
    white.rgba.assign(4, 255);
    const core::Result<std::uint32_t> first = add_texture(white);
    if (!first) return std::unexpected(first.error());
    return core::ok();
}

UiPass::UiPass(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
UiPass::UiPass(UiPass&&) noexcept = default;
UiPass& UiPass::operator=(UiPass&&) noexcept = default;
UiPass::~UiPass() = default;

core::Result<UiPass> UiPass::create(gpu::Device& device, const UiDesc& desc, gpu::PipelineHandle pipeline) {
    if (!pipeline) return core::fail(core::ErrorCode::kInvalidArgument, "pipeline giao diện chưa có");
    auto state = std::make_unique<State>();
    state->device = &device;
    state->desc = desc;
    state->pipeline = pipeline;
    const core::Status opened = state->open();
    if (!opened) return std::unexpected(opened.error());
    return UiPass(std::move(state));
}

core::Result<std::uint32_t> UiPass::add_texture(const resource::Image& image) {
    return state_->add_texture(image);
}

core::Result<std::uint32_t> UiPass::add_view(gpu::TextureViewHandle view) {
    return state_->add_view(view);
}

core::Status UiPass::replace_texture(std::uint32_t index, const resource::Image& image) {
    return state_->replace_texture(index, image);
}

std::uint32_t UiPass::max_quads() noexcept {
    return kMaxQuadCount;
}

std::uint32_t UiPass::draw_count() const noexcept {
    return state_->draws;
}

core::Status UiPass::draw(const UiDraw& frame) {
    State& state = *state_;
    state.draws = 0;
    const std::size_t quads = frame.vertices.size() / kVerticesPerQuad;
    const bool is_whole = frame.vertices.size() % kVerticesPerQuad == 0;
    const core::ErrorCode bad = core::ErrorCode::kInvalidArgument;
    if (!is_whole || quads > kMaxQuadCount) return core::fail(bad, "số đỉnh giao diện không hợp lệ");
    if (frame.slot >= state.slots.size()) return core::fail(bad, "slot giao diện ngoài số buffer");
    if (quads == 0) return core::ok();
    Slot& slot = state.slots.at(frame.slot);
    const core::Status grown = state.grow(slot, static_cast<std::uint32_t>(quads));
    if (!grown) return grown;
    const core::Status written = state.device->write_buffer(slot.vertices, 0, std::as_bytes(frame.vertices));
    if (!written) return written;
    gpu::CommandList& list = *frame.list;
    list.bind_pipeline(state.pipeline);
    list.bind_vertex_buffer(0, slot.vertices, 0);
    list.bind_index_buffer(state.indices, gpu::IndexType::kUint32, 0);
    for (const UiBatch& batch : frame.batches)
        state.draw_batch(list, batch, frame.screen);
    return core::ok();
}

} // namespace game::render
