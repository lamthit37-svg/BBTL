// Swapchain flip-model và timeline (ID3D12Fence) của backend D3D12. Hình dạng acquire rồi present
// giống Vulkan: D3D12 lấy chỉ số ảnh hiện tại, present là một lời gọi riêng.
// Nguồn: Forge2 src/gpu/d3d12/swapchain.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include "gpu/d3d12/device.hpp"

#include <vector>

namespace game::gpu::d3d12 {

class Timeline12 final : public Timeline {
public:
    Timeline12(D3d12Device& device, Microsoft::WRL::ComPtr<ID3D12Fence> fence) noexcept
        : device_(&device), fence_(std::move(fence)) {}
    [[nodiscard]] std::uint64_t completed() const noexcept override;
    [[nodiscard]] Status wait(std::uint64_t value, std::chrono::nanoseconds timeout) override;
    void signal(std::uint64_t value) override;
    [[nodiscard]] ID3D12Fence* fence() const noexcept { return fence_.Get(); }

private:
    D3d12Device* device_;
    Microsoft::WRL::ComPtr<ID3D12Fence> fence_;
};

class Swapchain12 final : public Swapchain {
public:
    Swapchain12(D3d12Device& device, Microsoft::WRL::ComPtr<IDXGISwapChain3> swap, HWND window, Format format,
        PresentMode mode, std::uint32_t width, std::uint32_t height, UINT flags);
    ~Swapchain12() override;
    Swapchain12(const Swapchain12&) = delete;
    Swapchain12& operator=(const Swapchain12&) = delete;
    Swapchain12(Swapchain12&&) = delete;
    Swapchain12& operator=(Swapchain12&&) = delete;

    [[nodiscard]] Result<std::uint32_t> acquire() override;
    [[nodiscard]] TextureHandle image(std::uint32_t index) const override;
    [[nodiscard]] TextureViewHandle view(std::uint32_t index) const override;
    [[nodiscard]] std::uint32_t image_count() const noexcept override;
    [[nodiscard]] Status present() override;
    [[nodiscard]] Status resize(std::uint32_t width, std::uint32_t height) override;
    [[nodiscard]] Format format() const noexcept override { return format_; }
    [[nodiscard]] PresentMode present_mode() const noexcept override { return mode_; }
    [[nodiscard]] std::uint32_t width() const noexcept override { return width_; }
    [[nodiscard]] std::uint32_t height() const noexcept override { return height_; }

    [[nodiscard]] bool is_awaiting_submit() const noexcept { return is_awaiting_; }
    void mark_submitted() noexcept { is_awaiting_ = false; }

private:
    [[nodiscard]] Status adopt_images();
    [[nodiscard]] Status adopt_one(UINT index);
    void release_images();

    friend class D3d12Device;

    D3d12Device* device_;
    Microsoft::WRL::ComPtr<IDXGISwapChain3> swap_;
    HWND window_ = nullptr;
    Format format_ = Format::kBgra8UnormSrgb;
    PresentMode mode_ = PresentMode::kFifo;
    std::uint32_t width_ = 0;
    std::uint32_t height_ = 0;
    UINT flags_ = 0;
    bool is_awaiting_ = false;
    std::vector<TextureHandle> images_;
    std::vector<TextureViewHandle> views_;
};

} // namespace game::gpu::d3d12
