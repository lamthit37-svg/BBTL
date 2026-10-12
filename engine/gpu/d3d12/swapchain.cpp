// Swapchain flip-discard và timeline của D3D12. acquire trả chỉ số ảnh hiện tại; present là lời gọi
// riêng, cùng hình dạng Vulkan. Immediate chỉ bật tearing khi factory cho phép, không thì về Fifo.
// Nguồn: Forge2 src/gpu/d3d12/swapchain.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; vòng
// adopt_images đưa điều kiện dừng lên điều kiện lặp; hai if chọn tearing tách thành present_choice;
// ChosenFormat khởi tạo có tên trường; const HANDLE viết auto* const; include đúng header của từng
// tên; IID lấy từ hằng của SDK.
#include "gpu/d3d12/swapchain.hpp"

#include "core/error.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/resource.hpp"

#include <basetsd.h>
#include <combaseapi.h>
#include <d3d12.h>
#include <dxgi.h>
#include <dxgi1_2.h>
#include <dxgi1_4.h>
#include <dxgi1_5.h>
#include <dxgiformat.h>
#include <handleapi.h>
#include <synchapi.h>
#include <winbase.h>
#include <windef.h>
#include <winerror.h>
#include <winnt.h>
#include <winuser.h>
#include <wrl/client.h>

#include "gpu/com.hpp"

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <expected>
#include <memory>
#include <tuple>
#include <utility>

namespace game::gpu::d3d12 {

using core::ErrorCode;
using core::fail;
using core::ok;

namespace {

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kState = ErrorCode::kInvalidState;

struct ChosenFormat {
    Format format = Format::kBgra8UnormSrgb;
    DXGI_FORMAT dxgi = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
};

// Chỉ nhận bốn định dạng 8 bit không nén. Còn lại về BGRA sRGB, định dạng flip model nào cũng có.
[[nodiscard]] ChosenFormat choose_format(Format wanted) noexcept {
    ChosenFormat chosen;
    // Khác gốc: tên trường.
    if (wanted == Format::kBgra8Unorm) {
        chosen = {.format = wanted, .dxgi = DXGI_FORMAT_B8G8R8A8_UNORM};
    }
    if (wanted == Format::kBgra8UnormSrgb) {
        chosen = {.format = wanted, .dxgi = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB};
    }
    if (wanted == Format::kRgba8Unorm) {
        chosen = {.format = wanted, .dxgi = DXGI_FORMAT_R8G8B8A8_UNORM};
    }
    if (wanted == Format::kRgba8UnormSrgb) {
        chosen = {.format = wanted, .dxgi = DXGI_FORMAT_R8G8B8A8_UNORM_SRGB};
    }
    return chosen;
}

// Flip model không nhận định dạng _SRGB: CreateSwapChainForHwnd trả DXGI_ERROR_INVALID_CALL.
// Bộ đệm tạo bằng bản tuyến tính; sRGB do RTV áp. format() của swapchain vẫn là _SRGB.
[[nodiscard]] DXGI_FORMAT buffer_format(DXGI_FORMAT wanted) noexcept {
    if (wanted == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB) return DXGI_FORMAT_B8G8R8A8_UNORM;
    if (wanted == DXGI_FORMAT_R8G8B8A8_UNORM_SRGB) return DXGI_FORMAT_R8G8B8A8_UNORM;
    return wanted;
}

[[nodiscard]] bool tearing_allowed(IDXGIFactory4* factory) noexcept {
    Microsoft::WRL::ComPtr<IDXGIFactory5> newer;
    if (FAILED(factory->QueryInterface(com_iid(newer), com_pp(newer)))) return false;
    BOOL allow = FALSE;
    const HRESULT checked = newer->CheckFeatureSupport(DXGI_FEATURE_PRESENT_ALLOW_TEARING, &allow, sizeof(allow));
    return SUCCEEDED(checked) && allow == TRUE;
}

struct PresentChoice {
    PresentMode mode = PresentMode::kFifo;
    UINT flags = 0;
};

// Khác gốc: hai if tearing của create_swapchain tách ra đây (PH-01).
[[nodiscard]] PresentChoice present_choice(PresentMode wanted, bool can_tear) noexcept {
    PresentChoice choice;
    choice.mode = wanted;
    if (wanted == PresentMode::kImmediate && can_tear) {
        choice.flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;
    }
    if (wanted == PresentMode::kImmediate && !can_tear) choice.mode = PresentMode::kFifo;
    return choice;
}

[[nodiscard]] DWORD wait_ms(std::chrono::nanoseconds timeout) noexcept {
    if (timeout == std::chrono::nanoseconds::max()) return INFINITE;
    if (timeout.count() <= 0) return 0;
    const auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(timeout);
    if (milliseconds.count() >= static_cast<std::chrono::milliseconds::rep>(INFINITE)) {
        return INFINITE - 1;
    }
    return static_cast<DWORD>(milliseconds.count());
}

} // namespace

std::uint64_t Timeline12::completed() const noexcept {
    const UINT64 value = fence_->GetCompletedValue();
    if (value == UINT64_MAX) return 0;
    return value;
}

Status Timeline12::wait(std::uint64_t value, std::chrono::nanoseconds timeout) {
    if (completed() >= value) return ok();
    // Khác gốc: gốc khai const HANDLE; nay auto* const.
    auto* const event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (event == nullptr) return fail(ErrorCode::kInternal, "không tạo được sự kiện timeline");
    const HRESULT armed = fence_->SetEventOnCompletion(value, event);
    if (FAILED(armed)) CloseHandle(event);
    if (FAILED(armed)) return device_->failed(armed, "không chờ được timeline");
    const DWORD result = WaitForSingleObject(event, wait_ms(timeout));
    CloseHandle(event);
    if (fence_->GetCompletedValue() == UINT64_MAX) {
        return device_->failed(DXGI_ERROR_DEVICE_REMOVED, "timeline mất cùng thiết bị");
    }
    if (result == WAIT_TIMEOUT) return fail(ErrorCode::kTimeout, "hết giờ chờ timeline");
    if (result != WAIT_OBJECT_0) return fail(ErrorCode::kInternal, "chờ timeline thất bại");
    return ok();
}

void Timeline12::signal(std::uint64_t value) {
    const HRESULT signaled = fence_->Signal(value);
    if (FAILED(signaled)) std::ignore = device_->failed(signaled, "không đẩy được timeline");
}

// Tám tham số ở header; width/height/flags theo IDXGISwapChain3 (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters, readability-function-size)
Swapchain12::Swapchain12(D3d12Device& device, Microsoft::WRL::ComPtr<IDXGISwapChain3> swap, HWND window, Format format,
    PresentMode mode, std::uint32_t width, std::uint32_t height, UINT flags)
    // NOLINTEND(bugprone-easily-swappable-parameters, readability-function-size)
    : device_(&device),
      swap_(std::move(swap)),
      window_(window),
      format_(format),
      mode_(mode),
      width_(width),
      height_(height),
      flags_(flags) {}

Swapchain12::~Swapchain12() {
    if (device_ != nullptr) std::ignore = device_->wait_idle();
    release_images();
    if (device_ != nullptr) device_->collect_retired();
    swap_.Reset();
}

Status Swapchain12::adopt_one(UINT index) {
    Microsoft::WRL::ComPtr<ID3D12Resource> buffer;
    const HRESULT taken = swap_->GetBuffer(index, com_iid(buffer), com_pp(buffer));
    if (FAILED(taken)) return device_->failed(taken, "không lấy được ảnh swapchain");
    TextureDesc desc;
    desc.kind = TextureKind::kTex2D;
    desc.format = format_;
    desc.width = width_;
    desc.height = height_;
    desc.depth_or_layers = 1;
    desc.mip_levels = 1;
    desc.samples = 1;
    desc.usage = TextureUsage::kColorTarget | TextureUsage::kCopySource;
    const TextureHandle image = device_->adopt(std::move(buffer), desc);
    if (!image) return fail(ErrorCode::kExhausted, "hết ô trong bảng texture");
    TextureViewDesc view;
    view.texture = image;
    view.kind = TextureKind::kTex2D;
    const Result<TextureViewHandle> created = device_->create_view(view);
    if (!created) device_->release(image);
    if (!created) return std::unexpected(created.error());
    images_.push_back(image);
    views_.push_back(*created);
    return ok();
}

Status Swapchain12::adopt_images() {
    DXGI_SWAP_CHAIN_DESC1 info{};
    const HRESULT read = swap_->GetDesc1(&info);
    if (FAILED(read)) return device_->failed(read, "không đọc được swapchain");
    Status added = ok();
    // Khác gốc: if trong for lên điều kiện lặp; lỗi đầu vẫn release.
    for (UINT index = 0; index < info.BufferCount && added; ++index) {
        added = adopt_one(index);
    }
    if (!added) release_images();
    if (!added) return added;
    return ok();
}

void Swapchain12::release_images() {
    for (const TextureViewHandle view : views_) {
        device_->release(view);
    }
    for (const TextureHandle image : images_) {
        device_->release(image);
    }
    views_.clear();
    images_.clear();
}

Result<std::uint32_t> Swapchain12::acquire() {
    if (is_awaiting_) return fail(kState, "acquire chồng lên ảnh chưa present");
    RECT rect{};
    const BOOL read = GetClientRect(window_, &rect);
    if (read == FALSE) return fail(kState, "không đọc được kích thước cửa sổ");
    const auto width = static_cast<std::uint32_t>(std::max<LONG>(rect.right - rect.left, 0));
    const auto height = static_cast<std::uint32_t>(std::max<LONG>(rect.bottom - rect.top, 0));
    const bool is_same = width == width_ && height == height_ && width != 0 && height != 0;
    if (!is_same) return fail(kState, "swapchain cần resize");
    is_awaiting_ = true;
    return swap_->GetCurrentBackBufferIndex();
}

TextureHandle Swapchain12::image(std::uint32_t index) const {
    if (index >= images_.size()) return {};
    return images_.at(index);
}

TextureViewHandle Swapchain12::view(std::uint32_t index) const {
    if (index >= views_.size()) return {};
    return views_.at(index);
}

std::uint32_t Swapchain12::image_count() const noexcept {
    return static_cast<std::uint32_t>(images_.size());
}

Status Swapchain12::present() {
    if (!is_awaiting_) return fail(kState, "present khi chưa acquire");
    // Mailbox của DXGI không có: chờ quét như Fifo để không xé. Immediate mới trình ngay.
    const bool is_vsync = mode_ != PresentMode::kImmediate;
    const UINT sync = is_vsync ? 1U : 0U;
    const UINT flags =
        (flags_ & DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING) != 0 && sync == 0 ? DXGI_PRESENT_ALLOW_TEARING : 0U;
    const HRESULT presented = swap_->Present(sync, flags);
    is_awaiting_ = false;
    if (FAILED(presented)) return device_->failed(presented, "present thất bại");
    device_->note_presented();
    return ok();
}

Status Swapchain12::resize(std::uint32_t width, std::uint32_t height) {
    if (width == 0 || height == 0) return fail(kBad, "resize: cạnh bằng 0");
    const Status idle = device_->wait_idle();
    if (!idle) return idle;
    release_images();
    device_->collect_retired();
    is_awaiting_ = false;
    const HRESULT resized = swap_->ResizeBuffers(0, width, height, DXGI_FORMAT_UNKNOWN, flags_);
    if (FAILED(resized)) return device_->failed(resized, "không dựng lại được swapchain");
    width_ = width;
    height_ = height;
    return adopt_images();
}

Result<std::unique_ptr<Timeline>> D3d12Device::create_timeline(std::uint64_t initial) {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    Microsoft::WRL::ComPtr<ID3D12Fence> fence;
    const HRESULT created = device_->CreateFence(initial, D3D12_FENCE_FLAG_NONE, com_iid(fence), com_pp(fence));
    if (FAILED(created)) return failed(created, "không tạo được timeline");
    return std::make_unique<Timeline12>(*this, std::move(fence));
}

Result<std::unique_ptr<Swapchain>> D3d12Device::create_swapchain(const SwapchainDesc& desc) {
    if (loss() != DeviceLoss::kNone) return fail(ErrorCode::kDeviceLost, "thiết bị đã mất");
    if (desc.window == nullptr) return fail(kBad, "swapchain: thiếu HWND");
    if (desc.width == 0 || desc.height == 0) return fail(kBad, "swapchain: cạnh bằng 0");
    auto* const window = static_cast<HWND>(desc.window);
    const ChosenFormat format = choose_format(desc.format);
    const bool can_tear = tearing_allowed(factory_.Get());
    const PresentChoice present = present_choice(desc.present_mode, can_tear);
    DXGI_SWAP_CHAIN_DESC1 info{};
    info.Width = desc.width;
    info.Height = desc.height;
    info.Format = buffer_format(format.dxgi);
    info.SampleDesc.Count = 1;
    info.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    info.BufferCount = std::max(desc.image_count, 2U);
    info.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    info.AlphaMode = DXGI_ALPHA_MODE_IGNORE;
    info.Scaling = DXGI_SCALING_STRETCH;
    info.Flags = present.flags;
    Microsoft::WRL::ComPtr<IDXGISwapChain1> created;
    const HRESULT made =
        factory_->CreateSwapChainForHwnd(present_queue(), window, &info, nullptr, nullptr, created.GetAddressOf());
    if (FAILED(made)) return failed(made, "không tạo được swapchain");
    std::ignore = factory_->MakeWindowAssociation(window, DXGI_MWA_NO_ALT_ENTER);
    Microsoft::WRL::ComPtr<IDXGISwapChain3> swap;
    const HRESULT queried = created.As(&swap);
    if (FAILED(queried)) return failed(queried, "swapchain không có IDXGISwapChain3");
    if (present.mode == PresentMode::kMailbox) swap->SetMaximumFrameLatency(1);
    auto result = std::make_unique<Swapchain12>(*this, std::move(swap), window, format.format, present.mode, desc.width,
        desc.height, present.flags);
    const Status adopted = result->adopt_images();
    if (!adopted) return std::unexpected(adopted.error());
    return result;
}

} // namespace game::gpu::d3d12
