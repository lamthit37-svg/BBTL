// Ảnh màu đi qua ba bố cục: Undefined trước lần vẽ đầu, ColorTarget trong lượt vẽ, ShaderRead giữa
// hai lượt. Ảnh độ sâu và ảnh màu đa mẫu là Transient: chỉ sống trong lượt vẽ nên mỗi lượt bắt đầu
// lại từ Undefined.
#include "render/canvas.hpp"

#include "core/error.hpp"
#include "gpu/barrier.hpp"
#include "gpu/command.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"

#include <array>
#include <expected>
#include <memory>
#include <optional>
#include <span>
#include <utility>

namespace game::render {

namespace {

// Một ảnh cùng view trọn ảnh của nó.
struct Image {
    gpu::TextureHandle texture{};
    gpu::TextureViewHandle view{};
};

// Rào của ảnh độ sâu: vào lượt vẽ từ Undefined.
[[nodiscard]] gpu::TextureBarrier depth_barrier(gpu::TextureHandle texture) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = gpu::SyncStage::kEarlyDepth | gpu::SyncStage::kLateDepth;
    barrier.stage_after = barrier.stage_before;
    barrier.access_after = gpu::Access::kDepthWrite;
    barrier.layout_after = gpu::TextureLayout::kDepthWrite;
    return barrier;
}

// Rào của ảnh màu đa mẫu: vào lượt vẽ từ Undefined.
[[nodiscard]] gpu::TextureBarrier color_barrier(gpu::TextureHandle texture) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = gpu::SyncStage::kColorOutput;
    barrier.stage_after = gpu::SyncStage::kColorOutput;
    barrier.access_after = gpu::Access::kColorWrite;
    barrier.layout_after = gpu::TextureLayout::kColorTarget;
    return barrier;
}

} // namespace

struct Canvas::State {
    State() = default;
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;
    ~State() {
        if (device == nullptr) return;
        for (const Image& image : {depth, multisampled, color}) {
            device->destroy(image.view);
            device->destroy(image.texture);
        }
    }

    [[nodiscard]] core::Result<Image> make_image(const gpu::TextureDesc& texture) const;
    [[nodiscard]] core::Status make_images();

    gpu::Device* device = nullptr;
    CanvasDesc desc{};
    Image color;
    // Rỗng khi desc.samples là 1: vẽ thẳng vào color.
    Image multisampled;
    Image depth;
    // Ảnh màu đã qua ít nhất một lần end nên đang ở bố cục ShaderRead.
    bool is_drawn = false;
};

core::Result<Image> Canvas::State::make_image(const gpu::TextureDesc& texture) const {
    const core::Result<gpu::TextureHandle> made = device->create_texture(texture);
    if (!made) return std::unexpected(made.error());
    gpu::TextureViewDesc view;
    view.name = texture.name;
    view.texture = *made;
    const core::Result<gpu::TextureViewHandle> viewed = device->create_view(view);
    if (!viewed) device->destroy(*made);
    if (!viewed) return std::unexpected(viewed.error());
    return Image{.texture = *made, .view = *viewed};
}

core::Status Canvas::State::make_images() {
    gpu::TextureDesc sampled;
    sampled.name = "render.canvas.color";
    sampled.format = desc.color_format;
    sampled.width = desc.width;
    sampled.height = desc.height;
    sampled.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kSampled;
    sampled.clear_color = desc.clear;
    const core::Result<Image> made_color = make_image(sampled);
    if (!made_color) return std::unexpected(made_color.error());
    color = *made_color;
    gpu::TextureDesc deep;
    deep.name = "render.canvas.depth";
    deep.format = desc.depth_format;
    deep.width = desc.width;
    deep.height = desc.height;
    deep.samples = desc.samples;
    deep.usage = gpu::TextureUsage::kDepthStencilTarget | gpu::TextureUsage::kTransient;
    const core::Result<Image> made_depth = make_image(deep);
    if (!made_depth) return std::unexpected(made_depth.error());
    depth = *made_depth;
    if (desc.samples == 1) return core::ok();
    gpu::TextureDesc many = sampled;
    many.name = "render.canvas.multisampled";
    many.samples = desc.samples;
    many.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kTransient;
    const core::Result<Image> made_many = make_image(many);
    if (!made_many) return std::unexpected(made_many.error());
    multisampled = *made_many;
    return core::ok();
}

Canvas::Canvas(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Canvas::Canvas(Canvas&&) noexcept = default;
Canvas& Canvas::operator=(Canvas&&) noexcept = default;
Canvas::~Canvas() = default;

core::Result<Canvas> Canvas::create(gpu::Device& device, const CanvasDesc& desc) {
    const bool is_sized = desc.width != 0 && desc.height != 0 && desc.samples != 0;
    if (!is_sized) return core::fail(core::ErrorCode::kInvalidArgument, "đích vẽ có cỡ bằng 0");
    auto state = std::make_unique<State>();
    state->device = &device;
    state->desc = desc;
    const core::Status made = state->make_images();
    if (!made) return std::unexpected(made.error());
    return Canvas(std::move(state));
}

const CanvasDesc& Canvas::desc() const noexcept {
    return state_->desc;
}

gpu::TextureViewHandle Canvas::color_view() const noexcept {
    return state_->color.view;
}

bool Canvas::is_bottom_up() const noexcept {
    return state_->device->adapter().backend == gpu::Backend::kGles;
}

void Canvas::begin(gpu::CommandList& list) {
    const State& state = *state_;
    const bool is_multisampled = state.desc.samples > 1;
    gpu::TextureBarrier sampled;
    sampled.texture = state.color.texture;
    const gpu::SyncStage output = gpu::SyncStage::kColorOutput;
    sampled.stage_before = state.is_drawn ? gpu::SyncStage::kPixelShader : output;
    sampled.stage_after = output;
    sampled.access_before = state.is_drawn ? gpu::Access::kShaderRead : gpu::Access::kNone;
    sampled.access_after = gpu::Access::kColorWrite;
    const gpu::TextureLayout read = gpu::TextureLayout::kShaderRead;
    sampled.layout_before = state.is_drawn ? read : gpu::TextureLayout::kUndefined;
    sampled.layout_after = gpu::TextureLayout::kColorTarget;
    const gpu::TextureBarrier deep = depth_barrier(state.depth.texture);
    const gpu::TextureBarrier many = color_barrier(state.multisampled.texture);
    const std::array<gpu::TextureBarrier, 3> barriers{sampled, deep, many};
    const std::span<const gpu::TextureBarrier> all(barriers);
    list.barrier({}, is_multisampled ? all : all.first(2), {});
    gpu::ColorTarget color_target;
    color_target.view = is_multisampled ? state.multisampled.view : state.color.view;
    color_target.resolve = is_multisampled ? state.color.view : gpu::TextureViewHandle{};
    color_target.clear = state.desc.clear;
    gpu::DepthTarget depth_target;
    depth_target.view = state.depth.view;
    gpu::RenderingDesc rendering;
    rendering.colors = std::span(&color_target, 1);
    rendering.depth = depth_target;
    list.begin_rendering(rendering);
}

void Canvas::end(gpu::CommandList& list) {
    State& state = *state_;
    list.end_rendering();
    gpu::TextureBarrier sampled;
    sampled.texture = state.color.texture;
    sampled.stage_before = gpu::SyncStage::kColorOutput;
    sampled.stage_after = gpu::SyncStage::kPixelShader;
    sampled.access_before = gpu::Access::kColorWrite;
    sampled.access_after = gpu::Access::kShaderRead;
    sampled.layout_before = gpu::TextureLayout::kColorTarget;
    sampled.layout_after = gpu::TextureLayout::kShaderRead;
    list.barrier({}, std::span(&sampled, 1), {});
    state.is_drawn = true;
}

} // namespace game::render
