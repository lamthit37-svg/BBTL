// Dựng PSO của bảng catalog từ gói .f2s. Mỗi cặp shader nạp một lần cho mọi biến thể của nó.
// Bốn biến thể model khác nhau ở cull và blend; chỉ số ô trùng bit mà forward chọn chất liệu.
#include "render/catalog.hpp"

#include "core/clock.hpp"
#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/types.hpp"
#include "render/detail/shaders.hpp"
#include "render/ui.hpp"
#include "resource/model.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <print>
#include <ratio>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::render {
namespace {

using detail::alpha_blend;
using detail::ShaderPair;

[[nodiscard]] constexpr gpu::VertexAttribute attribute(std::uint32_t location, gpu::Format format,
    std::size_t offset) noexcept {
    return {.location = location, .buffer = 0, .format = format, .offset = static_cast<std::uint32_t>(offset)};
}

// Theo location của model.vs.slang: thứ tự trường của resource::Vertex.
constexpr std::array<gpu::VertexAttribute, 6> kModelAttributes{
    attribute(0, gpu::Format::kRgb32Float, offsetof(resource::Vertex, position)),
    attribute(1, gpu::Format::kRgb32Float, offsetof(resource::Vertex, normal)),
    attribute(2, gpu::Format::kRg32Float, offsetof(resource::Vertex, uv)),
    attribute(3, gpu::Format::kRgba32Float, offsetof(resource::Vertex, color)),
    attribute(4, gpu::Format::kRgba16Uint, offsetof(resource::Vertex, joints)),
    attribute(5, gpu::Format::kRgba32Float, offsetof(resource::Vertex, weights)),
};

constexpr std::array<gpu::VertexAttribute, 3> kUiAttributes{
    attribute(0, gpu::Format::kRg32Float, offsetof(UiVertex, x)),
    attribute(1, gpu::Format::kRg32Float, offsetof(UiVertex, u)),
    attribute(2, gpu::Format::kR32Uint, offsetof(UiVertex, colour)),
};

constexpr std::array<gpu::VertexAttribute, 3> kFxAttributes{
    attribute(0, gpu::Format::kRgb32Float, 0),
    attribute(1, gpu::Format::kRg32Float, kFxUv),
    attribute(2, gpu::Format::kRgba32Float, kFxColour),
};

// Hai hệ số scene_blend cho cả màu và alpha. Client gốc để separate = 0 nên hai kênh cùng một cặp.
[[nodiscard]] gpu::BlendState fx_factors(gpu::BlendFactor src, gpu::BlendFactor dst) noexcept {
    gpu::BlendState blend;
    blend.is_enabled = true;
    blend.src_color = src;
    blend.dst_color = dst;
    blend.src_alpha = src;
    blend.dst_alpha = dst;
    return blend;
}

void note_required(const Entry& entry, const core::Error& error, std::optional<core::Error>& required) {
    if (!entry.is_required || required.has_value()) return;
    required = error;
}

// Bit chất liệu của PSO model; địa hình là đục hai mặt (như chất liệu "dia-hinh" của nó), model đục không discard
// giữ bit hai mặt của chỉ số và không bao giờ trộn.
[[nodiscard]] constexpr std::uint32_t model_kind(Pso pso) noexcept {
    if (pso == Pso::kTerrain) return kModelTwoSided;
    const bool is_solid = pso == Pso::kModelSolid || pso == Pso::kModelSolidTwoSided;
    if (is_solid) return static_cast<std::uint32_t>(pso) & kModelTwoSided;
    return static_cast<std::uint32_t>(pso);
}
static_assert(model_kind(Pso::kModelSolid) == 0 && model_kind(Pso::kModelSolidTwoSided) == kModelTwoSided);

[[nodiscard]] core::Result<gpu::PipelineHandle> make_model(gpu::Device& device, const CatalogDesc& desc,
    const Entry& entry, std::span<const gpu::ShaderHandle> shaders) {
    const std::uint32_t kind = model_kind(entry.pso);
    const bool is_blended = (kind & kModelBlended) != 0;
    const bool is_two_sided = (kind & kModelTwoSided) != 0;
    const gpu::VertexBufferLayout layout{.stride = sizeof(resource::Vertex)};
    const gpu::BlendState blend = is_blended ? alpha_blend() : gpu::BlendState{};
    gpu::GraphicsPipelineDesc pipeline;
    pipeline.name = entry.name;
    pipeline.shaders = shaders;
    pipeline.vertex_buffers = std::span(&layout, 1);
    pipeline.vertex_attributes = kModelAttributes;
    pipeline.raster.cull = is_two_sided ? gpu::CullMode::kNone : gpu::CullMode::kBack;
    pipeline.depth.format = desc.depth;
    pipeline.depth.is_tested = true;
    pipeline.depth.is_written = !is_blended;
    pipeline.color_formats = std::span(&desc.color, 1);
    pipeline.samples = desc.samples;
    pipeline.blends = std::span(&blend, 1);
    return device.create_pipeline(pipeline);
}

[[nodiscard]] core::Result<gpu::PipelineHandle> make_ui(gpu::Device& device, const CatalogDesc& desc,
    std::span<const gpu::ShaderHandle> shaders) {
    const gpu::VertexBufferLayout layout{.stride = sizeof(UiVertex)};
    const gpu::BlendState blend = alpha_blend();
    gpu::GraphicsPipelineDesc pipeline;
    pipeline.name = "render.ui";
    pipeline.shaders = shaders;
    pipeline.vertex_buffers = std::span(&layout, 1);
    pipeline.vertex_attributes = kUiAttributes;
    pipeline.raster.cull = gpu::CullMode::kNone;
    pipeline.depth.format = desc.depth;
    pipeline.depth.is_tested = false;
    pipeline.depth.is_written = false;
    pipeline.color_formats = std::span(&desc.color, 1);
    pipeline.samples = desc.samples;
    pipeline.blends = std::span(&blend, 1);
    return device.create_pipeline(pipeline);
}

[[nodiscard]] core::Result<gpu::PipelineHandle> make_fx(gpu::Device& device, const CatalogDesc& desc,
    std::span<const gpu::ShaderHandle> shaders, const gpu::BlendState& blend, std::string_view name) {
    const gpu::VertexBufferLayout layout{.stride = kFxStride};
    gpu::GraphicsPipelineDesc pipeline;
    pipeline.name = name;
    pipeline.shaders = shaders;
    pipeline.vertex_buffers = std::span(&layout, 1);
    pipeline.vertex_attributes = kFxAttributes;
    pipeline.raster.cull = gpu::CullMode::kNone;
    pipeline.depth.format = desc.depth;
    pipeline.depth.is_tested = true;
    pipeline.depth.is_written = false;
    pipeline.color_formats = std::span(&desc.color, 1);
    pipeline.samples = desc.samples;
    pipeline.blends = std::span(&blend, 1);
    return device.create_pipeline(pipeline);
}

[[nodiscard]] core::Result<gpu::PipelineHandle> build_fx(gpu::Device& device,
    const CatalogDesc& desc, std::span<const gpu::ShaderHandle> shaders, gpu::BlendFactor src,
    gpu::BlendFactor dst, std::string_view name) {
    const gpu::BlendState blend = fx_factors(src, dst);
    return make_fx(device, desc, shaders, blend, name);
}

[[nodiscard]] constexpr std::string_view tier_name(Tier tier) noexcept {
    switch (tier) {
    case Tier::kBootstrap: return "0";
    case Tier::kEssential: return "1";
    case Tier::kScene: return "2";
    case Tier::kOptional: return "3";
    }
    std::unreachable();
}

void report_created(gpu::Backend backend, Tier tier, std::uint32_t created, core::Clock::time_point began) {
    const auto elapsed = core::Clock::now() - began;
    const double millis = std::chrono::duration<double, std::milli>(elapsed).count();
    std::println("Pipeline: {} tầng {} tạo {} PSO trong {:.1f} ms", gpu::name(backend), tier_name(tier), created,
        millis);
}

} // namespace

std::string resolved_shader_folder(const std::string& chosen) {
    return detail::shader_folder(chosen);
}

Catalog::Catalog(Catalog&& other) noexcept
    : device_(std::exchange(other.device_, nullptr)), desc_(std::move(other.desc_)), slots_(std::move(other.slots_)) {
    other.slots_ = {};
}

Catalog::~Catalog() {
    if (device_ == nullptr) return;
    for (const SlotState& slot : slots_) {
        device_->destroy(slot.handle);
    }
}

core::Result<Catalog> Catalog::open(gpu::Device& device, CatalogDesc desc) {
    Catalog catalog;
    catalog.device_ = &device;
    catalog.desc_ = std::move(desc);
    return catalog;
}

const Catalog::SlotState& Catalog::state_of(Pso pso) const noexcept {
    const auto index = static_cast<std::size_t>(pso);
    const std::size_t clamped = index < slots_.size() ? index : 0;
    // Pso là chỉ số ô. Giá trị lạ kẹp về 0.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    return slots_[clamped];
}

Catalog::SlotState& Catalog::state_of(Pso pso) noexcept {
    const auto index = static_cast<std::size_t>(pso);
    const std::size_t clamped = index < slots_.size() ? index : 0;
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    return slots_[clamped];
}

bool Catalog::tier_pending(Tier tier) const noexcept {
    for (const Entry& entry : entries()) {
        const bool waiting = entry.tier == tier && !state_of(entry.pso).tried;
        if (waiting) return true;
    }
    return false;
}

namespace {

// Entry cùng cặp (vertex, pixel) với pair, cùng tầng.
[[nodiscard]] bool shares_pair(const Entry& entry, Tier tier, const Entry& pair) noexcept {
    return entry.tier == tier && entry.vertex == pair.vertex && entry.pixel == pair.pixel;
}

} // namespace

bool Catalog::tier_has(Tier tier, const Entry& pair) const noexcept {
    for (const Entry& entry : entries()) {
        const bool pending = shares_pair(entry, tier, pair) && !state_of(entry.pso).tried;
        if (pending) return true;
    }
    return false;
}

void Catalog::take_loaded(const Entry& entry, std::span<const gpu::ShaderHandle> shaders, const core::Status& loaded,
    std::uint32_t& created, std::optional<core::Error>& required) {
    SlotState& slot = state_of(entry.pso);
    if (slot.tried) return;
    slot.tried = true;
    if (!loaded) {
        slot.fault = loaded.error();
        note_required(entry, loaded.error(), required);
        return;
    }
    const core::Result<gpu::PipelineHandle> made = build(entry, shaders);
    if (!made) {
        slot.fault = made.error();
        note_required(entry, made.error(), required);
        return;
    }
    slot.handle = *made;
    ++created;
}

void Catalog::warm_family(Tier tier, const Entry& pair, std::uint32_t& created, std::optional<core::Error>& required) {
    if (!tier_has(tier, pair)) return;
    const std::string folder = detail::shader_folder(desc_.shader_dir);
    ShaderPair shaders(*device_);
    shaders.sizes = {.frame = pair.frame_bytes, .draw = pair.draw_bytes};
    core::Status loaded = shaders.load(0, folder, pair.vertex);
    if (loaded) loaded = shaders.load(1, folder, pair.pixel);
    for (const Entry& entry : entries()) {
        if (!shares_pair(entry, tier, pair)) continue;
        take_loaded(entry, shaders.handles, loaded, created, required);
    }
}

core::Result<gpu::PipelineHandle> Catalog::build(const Entry& entry, std::span<const gpu::ShaderHandle> shaders) const {
    const gpu::BlendFactor one = gpu::BlendFactor::kOne;
    const gpu::BlendFactor zero = gpu::BlendFactor::kZero;
    const gpu::BlendFactor src_alpha = gpu::BlendFactor::kSrcAlpha;
    const gpu::BlendFactor inv_alpha = gpu::BlendFactor::kOneMinusSrcAlpha;
    const gpu::BlendFactor src_colour = gpu::BlendFactor::kSrcColor;
    const gpu::BlendFactor inv_colour = gpu::BlendFactor::kOneMinusSrcColor;
    switch (entry.pso) {
    case Pso::kModelOpaque:
    case Pso::kModelTwoSided:
    case Pso::kModelBlend:
    case Pso::kModelBlendTwoSided:
    case Pso::kTerrain:
    case Pso::kModelSolid:
    case Pso::kModelSolidTwoSided: return make_model(*device_, desc_, entry, shaders);
    case Pso::kUi: return make_ui(*device_, desc_, shaders);
    case Pso::kFx: return build_fx(*device_, desc_, shaders, one, one, entry.name);
    case Pso::kFxAlphaAdd: return build_fx(*device_, desc_, shaders, src_alpha, one, entry.name);
    case Pso::kFxBlend: return build_fx(*device_, desc_, shaders, src_alpha, inv_alpha, entry.name);
    case Pso::kFxDarken: return build_fx(*device_, desc_, shaders, zero, inv_colour, entry.name);
    case Pso::kFxGlow: return build_fx(*device_, desc_, shaders, one, inv_colour, entry.name);
    case Pso::kFxColour:
        return build_fx(*device_, desc_, shaders, src_colour, inv_colour, entry.name);
    case Pso::kFxReplace: return build_fx(*device_, desc_, shaders, one, zero, entry.name);
    }
    std::unreachable();
}

void Catalog::warm_tier(Tier tier, std::uint32_t& created, std::optional<core::Error>& required) {
    for (const Entry& entry : entries()) {
        if (entry.tier != tier) continue;
        warm_family(tier, entry, created, required);
    }
}

core::Status Catalog::prepare(Tier tier) {
    if (!tier_pending(tier)) return core::ok();
    const core::Clock::time_point began = core::Clock::now();
    std::uint32_t created = 0;
    std::optional<core::Error> required;
    warm_tier(tier, created, required);
    report_created(device_->adapter().backend, tier, created, began);
    if (!required) return core::ok();
    return std::unexpected(*required);
}

gpu::PipelineHandle Catalog::get(Pso pso) const noexcept {
    return state_of(pso).handle;
}

const core::Error* Catalog::fault(Pso pso) const noexcept {
    const std::optional<core::Error>& fault = state_of(pso).fault;
    if (!fault) return nullptr;
    return &*fault;
}

std::array<gpu::PipelineHandle, kModelVariants> Catalog::models() const noexcept {
    return {get(Pso::kModelOpaque), get(Pso::kModelTwoSided), get(Pso::kModelBlend), get(Pso::kModelBlendTwoSided)};
}

} // namespace game::render
