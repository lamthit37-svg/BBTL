/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/screen.cpp
 *  PHÂN HỆ   : Render / Screen
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Ảnh swapchain mỗi khung đi từ Undefined (nội dung cũ bỏ, vì khung nào cũng
 *    xoá) sang ColorTarget rồi Present. Ảnh độ sâu là Transient như ở
 *    render/target.cpp. Nguồn: Forge2 src/render/screen.cpp@d7fcd76. Khác gốc:
 *    enumerator mang tiền tố k; bỏ khởi tạo {} thừa của State::swapchain;
 *    include trực tiếp header của mọi tên dùng tới.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "render/screen.hpp"

#include "core/error.hpp"
#include "gpu/barrier.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/resource.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <memory>
#include <span>
#include <utility>

namespace game::render {

namespace {

[[nodiscard]] core::Failure bad(core::Message message) {
    return core::fail(core::ErrorCode::kInvalidArgument, message);
}

} // namespace

using ColourImage = std::pair<gpu::TextureHandle, gpu::TextureViewHandle>;
using ColourResult = core::Result<ColourImage>;

struct Screen::State {
    State() = default;
    State(const State&) = delete;
    State& operator=(const State&) = delete;
    State(State&&) = delete;
    State& operator=(State&&) = delete;
    ~State() {
        if (device == nullptr) return;
        device->destroy(colour_ms_view);
        device->destroy(colour_ms);
        device->destroy(depth_view);
        device->destroy(depth);
    }

    [[nodiscard]] core::Status make_targets();
    // Ảnh độ sâu và view của nó, đúng cỡ hiện tại của swapchain.
    [[nodiscard]] core::Result<std::pair<gpu::TextureHandle, gpu::TextureViewHandle>> make_depth() const;
    // Cặp ảnh màu đa mẫu và view của nó; wanted sai thì trả cặp rỗng, vẽ thẳng vào ảnh swapchain.
    [[nodiscard]] core::Result<std::pair<gpu::TextureHandle, gpu::TextureViewHandle>> make_colour_ms(bool wanted) const;
    // Chuyển ảnh của khung và hai ảnh đích về bố cục vẽ; có ảnh đa mẫu thì kèm ảnh resolve.
    void to_render_layout(gpu::CommandList& list, bool is_multisampled) const;
    // Màu xoá của lượt vẽ tới: đen khi có khung con, không thì màu nền của cảnh.
    [[nodiscard]] gpu::ClearColor clear_now() const noexcept;
    // D3D12 chỉ xoá nhanh khi màu xoá khớp màu báo lúc tạo ảnh, lệch thì lớp kiểm tra cảnh báo:
    // màu nền đổi (sang cảnh khác, bật tắt khung con) thì dựng lại ảnh đa mẫu.
    [[nodiscard]] core::Status match_clear();

    gpu::Device* device = nullptr;
    ScreenDesc desc{};
    // Khai sau device và trước hai ảnh đích không quan trọng: swapchain tự chờ GPU khi bị huỷ.
    std::unique_ptr<gpu::Swapchain> swapchain;
    gpu::TextureHandle depth{};
    gpu::TextureViewHandle depth_view{};
    // Ảnh màu đa mẫu khi desc.samples trên 1; rỗng khi vẽ thẳng vào ảnh của swapchain.
    gpu::TextureHandle colour_ms{};
    gpu::TextureViewHandle colour_ms_view{};
    // Màu xoá đã báo cho colour_ms lúc tạo.
    gpu::ClearColor colour_ms_clear{};
    // Khung con xin từ set_view; chỉ có hiệu lực khi is_framed.
    ScreenView view{};
    // Ảnh của khung đang vẽ, từ lần begin gần nhất.
    std::uint32_t image = 0;

    // Khung con có hiệu lực: có diện tích, nằm trọn trong ảnh swapchain và nhỏ hơn ảnh. Trùng trọn ảnh
    // thì không tính, để cỡ khớp tỉ lệ vẫn xoá bằng màu nền của cảnh.
    [[nodiscard]] bool is_framed() const noexcept;
    // Đặt viewport và scissor vào khung con; gọi ngay sau begin_rendering.
    void fit_view(gpu::CommandList& list) const;
};

bool Screen::State::is_framed() const noexcept {
    if (view.width == 0 || view.height == 0) return false;
    const std::uint64_t right = std::uint64_t{view.x} + view.width;
    const std::uint64_t bottom = std::uint64_t{view.y} + view.height;
    if (right > swapchain->width() || bottom > swapchain->height()) return false;
    const bool is_whole = view.width == swapchain->width() && view.height == swapchain->height();
    return !is_whole;
}

void Screen::State::fit_view(gpu::CommandList& list) const {
    gpu::Viewport viewport;
    viewport.x = static_cast<float>(view.x);
    viewport.y = static_cast<float>(view.y);
    viewport.width = static_cast<float>(view.width);
    viewport.height = static_cast<float>(view.height);
    list.set_viewport(viewport);
    gpu::Scissor scissor;
    scissor.x = static_cast<std::int32_t>(view.x);
    scissor.y = static_cast<std::int32_t>(view.y);
    scissor.width = view.width;
    scissor.height = view.height;
    list.set_scissor(scissor);
}

// Ảnh màu đa mẫu: vẽ vào đây rồi resolve xuống ảnh của swapchain, trên chip của GPU.
core::Result<std::pair<gpu::TextureHandle, gpu::TextureViewHandle>> Screen::State::make_colour_ms(bool wanted) const {
    constexpr std::pair<gpu::TextureHandle, gpu::TextureViewHandle> kNone{};
    if (!wanted) return kNone;
    gpu::TextureDesc colour_desc;
    colour_desc.name = "render.screen.colour_ms";
    colour_desc.format = swapchain->format();
    colour_desc.width = swapchain->width();
    colour_desc.height = swapchain->height();
    colour_desc.samples = desc.samples;
    colour_desc.usage = gpu::TextureUsage::kColorTarget | gpu::TextureUsage::kTransient;
    colour_desc.clear_color = clear_now();
    const core::Result<gpu::TextureHandle> made = device->create_texture(colour_desc);
    if (!made) return std::unexpected(made.error());
    gpu::TextureViewDesc view_desc;
    view_desc.name = "render.screen.colour_ms";
    view_desc.texture = *made;
    const core::Result<gpu::TextureViewHandle> viewed = device->create_view(view_desc);
    if (!viewed) device->destroy(*made);
    if (!viewed) return std::unexpected(viewed.error());
    return std::pair{*made, *viewed};
}

// Ảnh độ sâu của màn hình vẽ, đúng cỡ hiện tại của swapchain.
core::Result<std::pair<gpu::TextureHandle, gpu::TextureViewHandle>> Screen::State::make_depth() const {
    gpu::TextureDesc depth_desc;
    depth_desc.name = "render.screen.depth";
    depth_desc.format = desc.depth_format;
    depth_desc.width = swapchain->width();
    depth_desc.height = swapchain->height();
    depth_desc.samples = desc.samples;
    depth_desc.usage = gpu::TextureUsage::kDepthStencilTarget | gpu::TextureUsage::kTransient;
    const core::Result<gpu::TextureHandle> made = device->create_texture(depth_desc);
    if (!made) return std::unexpected(made.error());
    gpu::TextureViewDesc view_desc;
    view_desc.name = "render.screen.depth";
    view_desc.texture = *made;
    const core::Result<gpu::TextureViewHandle> viewed = device->create_view(view_desc);
    if (!viewed) device->destroy(*made);
    if (!viewed) return std::unexpected(viewed.error());
    return std::pair{*made, *viewed};
}

// Hai ảnh đích theo cỡ hiện tại của swapchain: ảnh độ sâu luôn, ảnh màu đa mẫu khi có yêu cầu.
// Ảnh cũ huỷ hoãn.
core::Status Screen::State::make_targets() {
    const auto made_depth = make_depth();
    if (!made_depth) return std::unexpected(made_depth.error());
    const auto made_colour = make_colour_ms(desc.samples > 1);
    if (!made_colour) return std::unexpected(made_colour.error());
    device->destroy(colour_ms_view);
    device->destroy(colour_ms);
    device->destroy(depth_view);
    device->destroy(depth);
    depth = made_depth->first;
    depth_view = made_depth->second;
    colour_ms = made_colour->first;
    colour_ms_view = made_colour->second;
    colour_ms_clear = clear_now();
    return core::ok();
}

gpu::ClearColor Screen::State::clear_now() const noexcept {
    if (is_framed()) return gpu::ClearColor{};
    return desc.clear;
}

core::Status Screen::State::match_clear() {
    const gpu::ClearColor clear = clear_now();
    const bool is_current = desc.samples <= 1 || clear == colour_ms_clear;
    if (is_current) return core::ok();
    const auto made = make_colour_ms(true);
    if (!made) return std::unexpected(made.error());
    device->destroy(colour_ms_view);
    device->destroy(colour_ms);
    colour_ms = made->first;
    colour_ms_view = made->second;
    colour_ms_clear = clear;
    return core::ok();
}

Screen::Screen(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Screen::Screen(Screen&&) noexcept = default;
Screen& Screen::operator=(Screen&&) noexcept = default;
Screen::~Screen() = default;

core::Result<Screen> Screen::create(gpu::Device& device, const ScreenDesc& desc) {
    if (desc.window == nullptr) return bad("màn hình vẽ thiếu cửa sổ");
    auto state = std::make_unique<State>();
    state->device = &device;
    state->desc = desc;
    // Ảnh đa mẫu rồi resolve làm PowerVR GE8320 (TB-X306F) chỉ còn màu xoá: TLBB đo
    // SIGSEGV ở resolve GLES và tắt MSAA. Vẽ thẳng vào ảnh swapchain một mẫu.
    if (device.adapter().backend == gpu::Backend::kGles && state->desc.samples > 1) {
        state->desc.samples = 1;
    }
    gpu::SwapchainDesc chain;
    chain.window = desc.window;
    chain.width = desc.width;
    chain.height = desc.height;
    chain.present_mode = desc.present_mode;
    core::Result<std::unique_ptr<gpu::Swapchain>> made = device.create_swapchain(chain);
    if (!made) return std::unexpected(made.error());
    state->swapchain = std::move(*made);
    const core::Status targets = state->make_targets();
    if (!targets) return std::unexpected(targets.error());
    return Screen(std::move(state));
}

gpu::Format Screen::color_format() const noexcept {
    return state_->swapchain->format();
}

gpu::Format Screen::depth_format() const noexcept {
    return state_->desc.depth_format;
}

std::uint32_t Screen::width() const noexcept {
    return state_->swapchain->width();
}

std::uint32_t Screen::height() const noexcept {
    return state_->swapchain->height();
}

std::uint32_t Screen::image_count() const noexcept {
    return state_->swapchain->image_count();
}

std::uint32_t Screen::samples() const noexcept {
    return state_->desc.samples;
}

gpu::Swapchain* Screen::swapchain() noexcept {
    return state_->swapchain.get();
}

void Screen::set_clear(const gpu::ClearColor& clear) noexcept {
    state_->desc.clear = clear;
}

void Screen::set_view(const ScreenView& view) noexcept {
    state_->view = view;
}

core::Result<std::uint32_t> Screen::begin(gpu::CommandList& list) {
    State& state = *state_;
    // Trước acquire: dựng lại ảnh hỏng thì chưa giữ ảnh nào của swapchain.
    const core::Status matched = state.match_clear();
    if (!matched) return std::unexpected(matched.error());
    const core::Result<std::uint32_t> index = state.swapchain->acquire();
    if (!index) return index;
    state.image = *index;
    const bool is_multisampled = state.desc.samples > 1;
    state.to_render_layout(list, is_multisampled);
    // Vẽ vào ảnh đa mẫu (nếu có) rồi resolve xuống ảnh của swapchain lúc kết thúc lượt vẽ.
    const gpu::TextureViewHandle frame_view = state.swapchain->view(state.image);
    gpu::ColorTarget color_target;
    color_target.view = is_multisampled ? state.colour_ms_view : frame_view;
    color_target.resolve = is_multisampled ? frame_view : gpu::TextureViewHandle{};
    // Có khung con thì xoá đen cả ảnh để hai dải ngoài khung là đen; viewport thu nhỏ không đổi
    // vùng xoá.
    const bool is_framed = state.is_framed();
    color_target.clear = state.clear_now();
    gpu::DepthTarget depth_target;
    depth_target.view = state.depth_view;
    gpu::RenderingDesc rendering;
    rendering.colors = std::span(&color_target, 1);
    rendering.depth = depth_target;
    list.begin_rendering(rendering);
    if (is_framed) state.fit_view(list);
    return index;
}

// Chuyển ảnh của khung về bố cục vẽ, kèm ảnh độ sâu và ảnh đa mẫu nếu có.
void Screen::State::to_render_layout(gpu::CommandList& list, bool is_multisampled) const {
    gpu::TextureBarrier colour_fence;
    colour_fence.texture = swapchain->image(image);
    colour_fence.stage_before = gpu::SyncStage::kColorOutput;
    colour_fence.stage_after = gpu::SyncStage::kColorOutput;
    colour_fence.access_after = gpu::Access::kColorWrite;
    colour_fence.layout_after = gpu::TextureLayout::kColorTarget;
    gpu::TextureBarrier depth_fence;
    depth_fence.texture = depth;
    depth_fence.stage_before = gpu::SyncStage::kEarlyDepth | gpu::SyncStage::kLateDepth;
    depth_fence.stage_after = depth_fence.stage_before;
    depth_fence.access_after = gpu::Access::kDepthWrite;
    depth_fence.layout_after = gpu::TextureLayout::kDepthWrite;
    if (is_multisampled) {
        gpu::TextureBarrier multisampled = colour_fence;
        multisampled.texture = colour_ms;
        const std::array<gpu::TextureBarrier, 3> barriers{colour_fence, multisampled, depth_fence};
        list.barrier({}, barriers, {});
        return;
    }
    const std::array<gpu::TextureBarrier, 2> barriers{colour_fence, depth_fence};
    list.barrier({}, barriers, {});
}

void Screen::end(gpu::CommandList& list, ScreenHandoff handoff) {
    const State& state = *state_;
    list.end_rendering();
    const bool is_copied = handoff == ScreenHandoff::kCopy;
    gpu::TextureBarrier color;
    color.texture = state.swapchain->image(state.image);
    color.stage_before = gpu::SyncStage::kColorOutput;
    color.access_before = gpu::Access::kColorWrite;
    color.layout_before = gpu::TextureLayout::kColorTarget;
    // Về Present: không quyền truy cập nào sau, stage ColorOutput nối chuỗi với semaphore trình
    // bày.
    color.stage_after = is_copied ? gpu::SyncStage::kCopy : gpu::SyncStage::kColorOutput;
    color.access_after = is_copied ? gpu::Access::kCopyRead : gpu::Access::kNone;
    color.layout_after = is_copied ? gpu::TextureLayout::kCopySource : gpu::TextureLayout::kPresent;
    list.barrier({}, std::span(&color, 1), {});
}

core::Status Screen::present() {
    return state_->swapchain->present();
}

core::Status Screen::resize(std::uint32_t width, std::uint32_t height) {
    State& state = *state_;
    if (width == 0 || height == 0) return bad("cỡ màn hình vẽ bằng 0");
    if (state.swapchain->is_current(width, height)) return core::ok();
    const core::Status resized = state.swapchain->resize(width, height);
    if (!resized) return resized;
    return state.make_targets();
}

} // namespace game::render
