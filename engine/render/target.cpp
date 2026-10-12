// Ảnh màu đi qua ba bố cục: Undefined trước lần vẽ đầu, ColorTarget trong lượt vẽ, CopySource sau
// khi chép ra buffer. Ảnh độ sâu là Transient: chỉ sống trong lượt vẽ, GPU chia ô không phải cấp bộ
// nhớ thật cho nó, nên mỗi lượt bắt đầu lại từ Undefined.
// Nguồn: Forge2 src/render/target.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; bỏ phép ép
// uint64 sang size_t của stride ở read mà GCC báo thừa (kèm static_assert nền 64 bit); include
// trực tiếp header của mọi tên dùng tới.
#include "render/target.hpp"

#include "capture/frame.hpp"
#include "core/error.hpp"
#include "gpu/barrier.hpp"
#include "gpu/command.hpp"
#include "gpu/format.hpp"
#include "gpu/resource.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::render {

namespace {

// Khác gốc: gốc ép gpu::padded_row_bytes (uint64) sang std::size_t khi gán stride ở read. Trên nền
// 64 bit hai kiểu cùng độ rộng (GCC báo -Wuseless-cast), nên bỏ phép ép và chặn nền 32 bit ở đây.
static_assert(sizeof(std::size_t) == sizeof(std::uint64_t), "render/target cần nền 64 bit");

[[nodiscard]] core::Failure bad(core::Message message) {
    return core::fail(core::ErrorCode::kInvalidArgument, message);
}

[[nodiscard]] core::Failure early(core::Message message) {
    return core::fail(core::ErrorCode::kInvalidState, message);
}

// Định dạng điểm ảnh của khung hình đọc ngược; rỗng khi định dạng màu không phải 8 bit bốn kênh.
[[nodiscard]] std::optional<capture::PixelFormat> pixel_format(gpu::Format format) noexcept {
    const bool is_rgba = format == gpu::Format::kRgba8Unorm || format == gpu::Format::kRgba8UnormSrgb;
    const bool is_bgra = format == gpu::Format::kBgra8Unorm || format == gpu::Format::kBgra8UnormSrgb;
    if (is_rgba) return capture::PixelFormat::kRgba8;
    if (is_bgra) return capture::PixelFormat::kBgra8;
    return std::nullopt;
}

} // namespace

struct Target::State {
    State() = default;
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;
    ~State() {
        if (device == nullptr) return;
        device->destroy(readback);
        device->destroy(depth_view);
        device->destroy(depth);
        device->destroy(color_view);
        device->destroy(color);
    }

    [[nodiscard]] core::Status make_color();
    [[nodiscard]] core::Status make_depth();
    [[nodiscard]] core::Status make_readback();

    gpu::Device* device = nullptr;
    TargetDesc desc{};
    gpu::TextureHandle color{};
    gpu::TextureViewHandle color_view{};
    gpu::TextureHandle depth{};
    gpu::TextureViewHandle depth_view{};
    gpu::BufferHandle readback{};
    // Ảnh màu đã qua ít nhất một lần end: nó đang ở bố cục CopySource và buffer có khung hình.
    bool is_drawn = false;
};

core::Status Target::State::make_color() {
    gpu::TextureDesc texture;
    texture.name = "render.target.color";
    texture.format = desc.color_format;
    texture.width = desc.width;
    texture.height = desc.height;
    texture.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kCopySource;
    texture.clear_color = desc.clear;
    const core::Result<gpu::TextureHandle> made = device->create_texture(texture);
    if (!made) return std::unexpected(made.error());
    color = *made;
    gpu::TextureViewDesc view;
    view.name = "render.target.color";
    view.texture = color;
    const core::Result<gpu::TextureViewHandle> viewed = device->create_view(view);
    if (!viewed) return std::unexpected(viewed.error());
    color_view = *viewed;
    return core::ok();
}

core::Status Target::State::make_depth() {
    gpu::TextureDesc texture;
    texture.name = "render.target.depth";
    texture.format = desc.depth_format;
    texture.width = desc.width;
    texture.height = desc.height;
    texture.usage = gpu::TextureUsage::kDepthStencilTarget | gpu::TextureUsage::kTransient;
    const core::Result<gpu::TextureHandle> made = device->create_texture(texture);
    if (!made) return std::unexpected(made.error());
    depth = *made;
    gpu::TextureViewDesc view;
    view.name = "render.target.depth";
    view.texture = depth;
    const core::Result<gpu::TextureViewHandle> viewed = device->create_view(view);
    if (!viewed) return std::unexpected(viewed.error());
    depth_view = *viewed;
    return core::ok();
}

core::Status Target::State::make_readback() {
    gpu::BufferDesc buffer;
    buffer.name = "render.target.readback";
    buffer.size = gpu::staged_bytes(desc.color_format, desc.width, desc.height);
    buffer.usage = gpu::BufferUsage::kCopyDest;
    buffer.memory = gpu::MemoryDomain::kReadback;
    const core::Result<gpu::BufferHandle> made = device->create_buffer(buffer);
    if (!made) return std::unexpected(made.error());
    readback = *made;
    return core::ok();
}

Target::Target(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Target::Target(Target&&) noexcept = default;
Target& Target::operator=(Target&&) noexcept = default;
Target::~Target() = default;

core::Result<Target> Target::create(gpu::Device& device, const TargetDesc& desc) {
    if (desc.width == 0 || desc.height == 0) return bad("đích vẽ có cỡ bằng 0");
    if (!pixel_format(desc.color_format)) return bad("định dạng màu không đọc ngược được");
    auto state = std::make_unique<State>();
    state->device = &device;
    state->desc = desc;
    const core::Status color = state->make_color();
    if (!color) return std::unexpected(color.error());
    const core::Status depth = state->make_depth();
    if (!depth) return std::unexpected(depth.error());
    const core::Status readback = state->make_readback();
    if (!readback) return std::unexpected(readback.error());
    return Target(std::move(state));
}

const TargetDesc& Target::desc() const noexcept {
    return state_->desc;
}

void Target::begin(gpu::CommandList& list) {
    const State& state = *state_;
    gpu::TextureBarrier color;
    color.texture = state.color;
    color.stage_before = state.is_drawn ? gpu::SyncStage::kCopy : gpu::SyncStage::kColorOutput;
    color.stage_after = gpu::SyncStage::kColorOutput;
    color.access_before = state.is_drawn ? gpu::Access::kCopyRead : gpu::Access::kNone;
    color.access_after = gpu::Access::kColorWrite;
    const gpu::TextureLayout was = gpu::TextureLayout::kCopySource;
    color.layout_before = state.is_drawn ? was : gpu::TextureLayout::kUndefined;
    color.layout_after = gpu::TextureLayout::kColorTarget;
    gpu::TextureBarrier depth;
    depth.texture = state.depth;
    depth.stage_before = gpu::SyncStage::kEarlyDepth | gpu::SyncStage::kLateDepth;
    depth.stage_after = depth.stage_before;
    depth.access_after = gpu::Access::kDepthWrite;
    depth.layout_after = gpu::TextureLayout::kDepthWrite;
    const std::array<gpu::TextureBarrier, 2> barriers{color, depth};
    list.barrier({}, barriers, {});
    gpu::ColorTarget color_target;
    color_target.view = state.color_view;
    color_target.clear = state.desc.clear;
    gpu::DepthTarget depth_target;
    depth_target.view = state.depth_view;
    gpu::RenderingDesc rendering;
    rendering.colors = std::span(&color_target, 1);
    rendering.depth = depth_target;
    list.begin_rendering(rendering);
}

void Target::end(gpu::CommandList& list) {
    State& state = *state_;
    list.end_rendering();
    gpu::TextureBarrier color;
    color.texture = state.color;
    color.stage_before = gpu::SyncStage::kColorOutput;
    color.stage_after = gpu::SyncStage::kCopy;
    color.access_before = gpu::Access::kColorWrite;
    color.access_after = gpu::Access::kCopyRead;
    color.layout_before = gpu::TextureLayout::kColorTarget;
    color.layout_after = gpu::TextureLayout::kCopySource;
    list.barrier({}, std::span(&color, 1), {});
    // Mặc định của vùng chép: trọn mức mip 0, các dòng theo bước đã đệm.
    const gpu::BufferTextureCopy region;
    list.copy_texture_to_buffer(state.color, state.readback, std::span(&region, 1));
    state.is_drawn = true;
}

core::Result<capture::Frame> Target::read() const {
    const State& state = *state_;
    const TargetDesc& desc = state.desc;
    if (!state.is_drawn) return early("đích vẽ chưa có khung nào");
    const std::uint64_t size = gpu::staged_bytes(desc.color_format, desc.width, desc.height);
    std::vector<std::byte> staged(static_cast<std::size_t>(size));
    const core::Status status = state.device->read_buffer(state.readback, 0, staged);
    if (!status) return std::unexpected(status.error());
    capture::FrameView view;
    view.pixels = staged;
    view.width = desc.width;
    view.height = desc.height;
    view.stride = gpu::padded_row_bytes(desc.color_format, desc.width);
    view.format = pixel_format(desc.color_format).value_or(capture::PixelFormat::kRgba8);
    return capture::Frame::copy(view);
}

} // namespace game::render
