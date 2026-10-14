// Swapchain flip-model của D3D11. FLIP_DISCARD thất bại thì thử lại DISCARD một buffer.
// Timeline là bộ đếm CPU. GPU xong nhờ query sự kiện của thiết bị, không phải ID3D11Fence.
// Buffer là UNORM vì flip từ chối sRGB. RTV sRGB khi probe trên buffer ấy thành công.
// Khác gốc: không chép bgfx.
#include "gpu/d3d11/swapchain.hpp"

#include "core/error.hpp"
#include "gpu/d3d11/convert.hpp"
#include "gpu/d3d11/device.hpp"
#include "gpu/d3d11/hresult.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"

#include <combaseapi.h>
#include <d3d11.h>
#include <dxgi.h>
#include <dxgi1_2.h>
#include <dxgi1_3.h>
#include <dxgi1_4.h>
#include <dxgiformat.h>
#include <windef.h>
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

#include "gpu/com.hpp"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <expected>
#include <memory>
#include <thread>
#include <utility>
#include <vector>

namespace game::gpu::d3d11 {

namespace {

using core::fail;
using core::ok;
using Microsoft::WRL::ComPtr;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kState = ErrorCode::kInvalidState;

struct WaitAsk {
    Timeline11* timeline = nullptr;
    D3d11Device* device = nullptr;
    std::uint64_t value = 0;
    std::chrono::steady_clock::time_point start;
    std::chrono::nanoseconds timeout{};
};

struct BufferChoice {
    Format format = Format::kUnknown;
    DXGI_FORMAT dxgi = DXGI_FORMAT_UNKNOWN;
};

struct ChainRequest {
    HWND window = nullptr;
    UINT width = 0;
    UINT height = 0;
    DXGI_FORMAT format = DXGI_FORMAT_UNKNOWN;
    UINT count = 2;
    UINT flags = 0;
};

struct MadeChain {
    ComPtr<IDXGISwapChain1> swap;
    bool is_flip = true;
};

struct HwndCreate {
    IDXGIFactory2* factory = nullptr;
    ID3D11Device* device = nullptr;
    HWND window = nullptr;
    const DXGI_SWAP_CHAIN_DESC1* info = nullptr;
    const DXGI_SWAP_CHAIN_FULLSCREEN_DESC* full = nullptr;
    ComPtr<IDXGISwapChain1>* out = nullptr;
};

struct MakeArgs {
    ID3D11Device* device = nullptr;
    IDXGIFactory2* factory = nullptr;
    ChainRequest request{};
    MadeChain* made = nullptr;
};

struct OpenArgs {
    D3d11Device* device = nullptr;
    const SwapchainDesc* desc = nullptr;
    const BufferChoice* chosen = nullptr;
    IDXGIFactory2* factory = nullptr;
};

struct BuiltChain {
    const OpenArgs* args = nullptr;
    const ChainRequest* request = nullptr;
    const MadeChain* made = nullptr;
};

struct HoldArgs {
    D3d11Device* device = nullptr;
    IDXGISwapChain* swap = nullptr;
    UINT index = 0;
    Format wanted = Format::kUnknown;
};

struct HeldImage {
    TextureHandle image{};
    TextureViewHandle view{};
    Format format = Format::kUnknown;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

struct ChainSlots {
    std::vector<TextureHandle>* images = nullptr;
    std::vector<TextureViewHandle>* views = nullptr;
    Format* format = nullptr;
    std::uint32_t* width = nullptr;
    std::uint32_t* height = nullptr;
    D3d11Device* device = nullptr;
    IDXGISwapChain* swap = nullptr;
};

struct PresentInput {
    bool can_tear = false;
    PresentMode mode = PresentMode::kFifo;
    bool is_flip = false;
};

struct PresentArgs {
    UINT sync = 1;
    UINT flags = 0;
};

void raise_to(std::atomic<std::uint64_t>& slot, std::uint64_t value) noexcept {
    std::uint64_t seen = slot.load(std::memory_order_acquire);
    while (seen < value &&
        !slot.compare_exchange_weak(seen, value, std::memory_order_release, std::memory_order_acquire)) {
    }
}

[[nodiscard]] bool step(const WaitAsk& ask, Status& error) {
    if (ask.timeline->completed() >= ask.value) return false;
    if (ask.device->loss() != DeviceLoss::kNone) {
        error = fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
        return false;
    }
    const bool bounded = ask.timeout != std::chrono::nanoseconds::max();
    const auto now = std::chrono::steady_clock::now();
    const bool late = now - ask.start >= ask.timeout;
    if (bounded && late) {
        error = fail(ErrorCode::kTimeout, "hết giờ chờ timeline");
        return false;
    }
    ask.device->pump();
    const auto pause = std::chrono::milliseconds(1);
    std::this_thread::sleep_for(pause);
    return true;
}

[[nodiscard]] core::Failure hresult_failure(HRESULT code, core::Message message) {
    return failed(code, message);
}

[[nodiscard]] Result<BufferChoice> choose_buffer(Format wanted) {
    BufferChoice choice;
    choice.format = wanted;
    if (wanted == Format::kBgra8UnormSrgb) {
        choice.dxgi = DXGI_FORMAT_B8G8R8A8_UNORM;
        return choice;
    }
    choice.dxgi = to_dxgi(wanted);
    if (choice.dxgi == DXGI_FORMAT_UNKNOWN) {
        return fail(ErrorCode::kUnsupported, "swapchain không nhận định dạng này");
    }
    return choice;
}

[[nodiscard]] UINT clamp_count(std::uint32_t asked) noexcept {
    UINT count = asked;
    if (count == 0) count = 2;
    count = std::max<UINT>(count, 2);
    count = std::min<UINT>(count, 8);
    return count;
}

[[nodiscard]] UINT chain_flags(bool can_tear, PresentMode mode) noexcept {
    if (!can_tear) return 0;
    if (mode == PresentMode::kFifo) return 0;
    return DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;
}

[[nodiscard]] Result<ComPtr<IDXGIFactory2>> open_factory() {
    ComPtr<IDXGIFactory2> factory;
    IDXGIFactory2** slot = factory.GetAddressOf();
    const HRESULT created = CreateDXGIFactory2(0, com_iid(slot), com_pp(slot));
    if (FAILED(created)) return hresult_failure(created, "không tạo được factory DXGI");
    return factory;
}

void fill_common(DXGI_SWAP_CHAIN_DESC1& info, const ChainRequest& request) {
    info = {};
    info.Width = request.width;
    info.Height = request.height;
    info.Format = request.format;
    info.Stereo = FALSE;
    info.SampleDesc.Count = 1;
    info.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    info.Scaling = DXGI_SCALING_STRETCH;
    info.AlphaMode = DXGI_ALPHA_MODE_IGNORE;
    info.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    info.BufferCount = request.count;
    info.Flags = request.flags;
}

void fill_discard(DXGI_SWAP_CHAIN_DESC1& info) {
    info.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    info.BufferCount = 1;
    info.Flags = 0;
}

[[nodiscard]] HRESULT create_hwnd(const HwndCreate& create) {
    IDXGISwapChain1** slot = create.out->GetAddressOf();
    return create.factory->CreateSwapChainForHwnd(create.device, create.window, create.info, create.full, nullptr,
        slot);
}

[[nodiscard]] Status make_chain(const MakeArgs& args) {
    DXGI_SWAP_CHAIN_DESC1 info{};
    fill_common(info, args.request);
    DXGI_SWAP_CHAIN_FULLSCREEN_DESC windowed{};
    windowed.Windowed = TRUE;
    HwndCreate create;
    create.factory = args.factory;
    create.device = args.device;
    create.window = args.request.window;
    create.info = &info;
    create.full = &windowed;
    create.out = &args.made->swap;
    const HRESULT first = create_hwnd(create);
    if (SUCCEEDED(first)) return ok();
    args.made->swap.Reset();
    fill_discard(info);
    args.made->is_flip = false;
    const HRESULT second = create_hwnd(create);
    if (FAILED(second)) return failed(second, "không tạo được swapchain");
    return ok();
}

[[nodiscard]] SwapChainArgs chain_args(const BuiltChain& built) {
    SwapChainArgs chain;
    chain.swap = built.made->swap;
    chain.window = built.request->window;
    chain.format = built.args->chosen->format;
    chain.mode = built.args->desc->present_mode;
    chain.width = built.request->width;
    chain.height = built.request->height;
    chain.is_flip = built.made->is_flip;
    return chain;
}

[[nodiscard]] bool srgb_rtv_ok(ID3D11Device& device, ID3D11Texture2D& texture) {
    D3D11_RENDER_TARGET_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
    desc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
    // RTV desc là union SDK.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-union-access)
    desc.Texture2D.MipSlice = 0;
    ComPtr<ID3D11RenderTargetView> view;
    ID3D11RenderTargetView** slot = view.GetAddressOf();
    // Flip không nhận buffer sRGB; probe RTV sRGB trên UNORM.
    const HRESULT created = device.CreateRenderTargetView(&texture, &desc, slot);
    return SUCCEEDED(created);
}

[[nodiscard]] Format format_after_probe(bool srgb_ok) noexcept {
    // Probe hỏng thì báo UNORM, khớp buffer.
    if (srgb_ok) return Format::kBgra8UnormSrgb;
    return Format::kBgra8Unorm;
}

[[nodiscard]] Format image_format(ID3D11Device& device, ID3D11Texture2D& texture, Format wanted) {
    if (wanted != Format::kBgra8UnormSrgb) return wanted;
    const bool srgb_ok = srgb_rtv_ok(device, texture);
    return format_after_probe(srgb_ok);
}

[[nodiscard]] Result<ComPtr<ID3D11Texture2D>> take_buffer(IDXGISwapChain& swap, UINT index) {
    ComPtr<ID3D11Texture2D> texture;
    ID3D11Texture2D** slot = texture.GetAddressOf();
    const HRESULT taken = swap.GetBuffer(index, com_iid(slot), com_pp(slot));
    if (FAILED(taken)) return hresult_failure(taken, "không lấy được ảnh swapchain");
    return texture;
}

[[nodiscard]] Result<TextureViewHandle> view_of(D3d11Device& device, TextureHandle image) {
    TextureViewDesc desc;
    desc.texture = image;
    desc.format = Format::kUnknown;
    return device.create_view(desc);
}

[[nodiscard]] Result<HeldImage> hold_image(const HoldArgs& args) {
    IDXGISwapChain& swap = *args.swap;
    const Result<ComPtr<ID3D11Texture2D>> taken = take_buffer(swap, args.index);
    if (!taken) {
        const core::Error& error = taken.error();
        return std::unexpected(error);
    }
    ID3D11Texture2D* texture = taken->Get();
    D3D11_TEXTURE2D_DESC desc{};
    texture->GetDesc(&desc);
    ID3D11Device* raw = args.device->device();
    const Format format = image_format(*raw, *texture, args.wanted);
    SwapImage image;
    image.texture = texture;
    image.format = format;
    image.width = desc.Width;
    image.height = desc.Height;
    const Result<TextureHandle> adopted = args.device->adopt_swap_image(image);
    if (!adopted) {
        const core::Error& error = adopted.error();
        return std::unexpected(error);
    }
    const Result<TextureViewHandle> created = view_of(*args.device, *adopted);
    if (!created) args.device->destroy(*adopted);
    if (!created) {
        const core::Error& error = created.error();
        return std::unexpected(error);
    }
    HeldImage held;
    held.image = *adopted;
    held.view = *created;
    held.format = format;
    held.width = desc.Width;
    held.height = desc.Height;
    return held;
}

[[nodiscard]] Status keep_one(Status status, const ChainSlots& slots, UINT index) {
    if (!status) return status;
    HoldArgs args;
    args.device = slots.device;
    args.swap = slots.swap;
    args.index = index;
    args.wanted = *slots.format;
    const Result<HeldImage> held = hold_image(args);
    if (!held) {
        const core::Error& error = held.error();
        return std::unexpected(error);
    }
    *slots.format = held->format;
    *slots.width = held->width;
    *slots.height = held->height;
    slots.images->push_back(held->image);
    slots.views->push_back(held->view);
    return ok();
}

[[nodiscard]] PresentArgs present_args(const PresentInput& input) noexcept {
    PresentArgs args;
    const bool tear = input.can_tear && input.mode != PresentMode::kFifo && input.is_flip;
    if (tear) {
        args.sync = 0;
        args.flags = DXGI_PRESENT_ALLOW_TEARING;
        return args;
    }
    // Không xé thì mailbox chờ quét.
    if (input.mode != PresentMode::kImmediate) return args;
    args.sync = 0;
    return args;
}

void unbind_immediate(ID3D11DeviceContext& context) {
    context.OMSetRenderTargets(0, nullptr, nullptr);
}

using ChainPtr = Result<std::unique_ptr<Swapchain>>;

[[nodiscard]] ChainPtr adopt_chain(D3d11Device& device, const SwapChainArgs& chain) {
    auto concrete = std::make_unique<Swapchain11>(device, chain);
    const Status adopted = concrete->bind_images();
    if (!adopted) {
        const core::Error& error = adopted.error();
        return std::unexpected(error);
    }
    std::unique_ptr<Swapchain> result = std::move(concrete);
    return result;
}

[[nodiscard]] ChainPtr open_chain(const OpenArgs& args) {
    ChainRequest request;
    request.window = static_cast<HWND>(args.desc->window);
    request.width = args.desc->width;
    request.height = args.desc->height;
    request.format = args.chosen->dxgi;
    request.count = clamp_count(args.desc->image_count);
    const bool can_tear = args.device->allows_tearing();
    request.flags = chain_flags(can_tear, args.desc->present_mode);
    MadeChain made;
    MakeArgs make;
    make.device = args.device->device();
    make.factory = args.factory;
    make.request = request;
    make.made = &made;
    const Status created = make_chain(make);
    if (!created) {
        const core::Error& error = created.error();
        return std::unexpected(error);
    }
    const HRESULT associated = args.factory->MakeWindowAssociation(request.window, DXGI_MWA_NO_ALT_ENTER);
    static_cast<void>(associated);
    BuiltChain built;
    built.args = &args;
    built.request = &request;
    built.made = &made;
    const SwapChainArgs chain = chain_args(built);
    return adopt_chain(*args.device, chain);
}

} // namespace

Timeline11::Timeline11(D3d11Device& device, std::uint64_t initial) noexcept : device_(&device), value_(initial) {}

std::uint64_t Timeline11::completed() const noexcept {
    return value_.load(std::memory_order_acquire);
}

Status Timeline11::wait(std::uint64_t value, std::chrono::nanoseconds timeout) {
    WaitAsk ask;
    ask.timeline = this;
    ask.device = device_;
    ask.value = value;
    ask.start = std::chrono::steady_clock::now();
    ask.timeout = timeout;
    Status error = ok();
    while (step(ask, error)) {
    }
    return error;
}

void Timeline11::signal(std::uint64_t value) {
    publish(value);
}

void Timeline11::publish(std::uint64_t value) noexcept {
    raise_to(value_, value);
}

Swapchain11::Swapchain11(D3d11Device& device, const SwapChainArgs& args)
    : device_(&device),
      swap_(args.swap),
      format_(args.format),
      mode_(args.mode),
      width_(args.width),
      height_(args.height),
      is_flip_(args.is_flip) {}

Swapchain11::~Swapchain11() {
    release_images();
}

Result<std::uint32_t> Swapchain11::acquire() {
    if (images_.empty()) return fail(kState, "swapchain chưa có ảnh");
    return 0U;
}

TextureHandle Swapchain11::image(std::uint32_t index) const {
    if (index >= images_.size()) return {};
    return images_[index];
}

TextureViewHandle Swapchain11::view(std::uint32_t index) const {
    if (index >= views_.size()) return {};
    return views_[index];
}

std::uint32_t Swapchain11::image_count() const noexcept {
    return static_cast<std::uint32_t>(images_.size());
}

Status Swapchain11::present() {
    unbind_targets();
    PresentInput input;
    input.can_tear = device_->allows_tearing();
    input.mode = mode_;
    input.is_flip = is_flip_;
    const PresentArgs args = present_args(input);
    const HRESULT presented = swap_->Present(args.sync, args.flags);
    // OCCLUDED là cửa sổ thu nhỏ.
    if (presented == DXGI_STATUS_OCCLUDED) return ok();
    if (FAILED(presented)) device_->note_loss(presented);
    if (FAILED(presented)) return failed(presented, "present thất bại");
    return ok();
}

Status Swapchain11::resize(std::uint32_t width, std::uint32_t height) {
    if (width == 0 || height == 0) return fail(kBad, "resize: cạnh bằng 0");
    const Status idle = device_->wait_idle();
    if (!idle) return idle;
    release_images();
    const bool can_tear = device_->allows_tearing();
    UINT flags = 0;
    if (is_flip_) flags = chain_flags(can_tear, mode_);
    const DXGI_FORMAT keep = DXGI_FORMAT_UNKNOWN;
    const HRESULT resized = swap_->ResizeBuffers(0, width, height, keep, flags);
    if (FAILED(resized)) device_->note_loss(resized);
    if (FAILED(resized)) return failed(resized, "không dựng lại được swapchain");
    width_ = width;
    height_ = height;
    return adopt_images();
}

Status Swapchain11::adopt_images() {
    ChainSlots slots;
    slots.images = &images_;
    slots.views = &views_;
    slots.format = &format_;
    slots.width = &width_;
    slots.height = &height_;
    slots.device = device_;
    slots.swap = swap_.Get();
    // D3D11 chỉ cho GetBuffer(0), cả flip lẫn blt: runtime tự xoay các buffer sau mỗi Present, nên chuỗi
    // giữ đúng một ảnh. Hỏi chỉ số lớn hơn 0 là DXGI_ERROR_INVALID_CALL (đo 2026-10-13 ở
    // d3d11_swapchain_accepts_srgb: "không lấy được ảnh swapchain").
    const Status status = keep_one(ok(), slots, 0);
    if (!status) release_images();
    return status;
}

void Swapchain11::release_images() {
    // Gỡ đích vẽ.
    unbind_targets();
    for (const TextureViewHandle handle : views_) {
        device_->destroy(handle);
    }
    for (const TextureHandle handle : images_) {
        device_->destroy(handle);
    }
    views_.clear();
    images_.clear();
}

void Swapchain11::unbind_targets() {
    ImmediateGuard guard = device_->lock_immediate();
    ID3D11DeviceContext& context = guard.context();
    unbind_immediate(context);
}

Result<std::unique_ptr<Timeline>> D3d11Device::create_timeline(std::uint64_t initial) {
    std::unique_ptr<Timeline> timeline = std::make_unique<Timeline11>(*this, initial);
    return timeline;
}

D3d11Device::ChainResult D3d11Device::create_swapchain(const SwapchainDesc& desc) {
    if (desc.window == nullptr) return fail(kBad, "swapchain: thiếu HWND");
    if (desc.width == 0 || desc.height == 0) return fail(kBad, "swapchain: cạnh bằng 0");
    const Result<BufferChoice> chosen = choose_buffer(desc.format);
    if (!chosen) {
        const core::Error& error = chosen.error();
        return std::unexpected(error);
    }
    const Result<ComPtr<IDXGIFactory2>> factory = open_factory();
    if (!factory) {
        const core::Error& error = factory.error();
        return std::unexpected(error);
    }
    const BufferChoice& choice = *chosen;
    OpenArgs args;
    args.device = this;
    args.desc = &desc;
    args.chosen = &choice;
    args.factory = factory->Get();
    return open_chain(args);
}

} // namespace game::gpu::d3d11
