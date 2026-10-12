// Swapchain flip-model và timeline của backend D3D11. Timeline là bộ đếm CPU cộng query sự kiện
// của thiết bị, không dùng ID3D11Fence, để header MinGW vẫn dịch được. Ảnh buffer là UNORM; RTV
// là sRGB khi chỗ gọi xin kBgra8UnormSrgb.
#pragma once

#include "gpu/d3d11/device.hpp"

#include <atomic>
#include <vector>

namespace game::gpu::d3d11 {

class Timeline11 final : public Timeline {
public:
    Timeline11(D3d11Device& device, std::uint64_t initial) noexcept;
    [[nodiscard]] std::uint64_t completed() const noexcept override;
    [[nodiscard]] Status wait(std::uint64_t value, std::chrono::nanoseconds timeout) override;
    void signal(std::uint64_t value) override;
    void publish(std::uint64_t value) noexcept;

private:
    D3d11Device* device_;
    std::atomic<std::uint64_t> value_;
};

struct SwapChainArgs {
    Microsoft::WRL::ComPtr<IDXGISwapChain> swap;
    HWND window = nullptr;
    Format format = Format::kBgra8UnormSrgb;
    PresentMode mode = PresentMode::kFifo;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    bool is_flip = false;
};

class Swapchain11 final : public Swapchain {
public:
    Swapchain11(D3d11Device& device, const SwapChainArgs& args);
    // Gắn buffer; gọi ngay sau constructor.
    [[nodiscard]] Status bind_images() { return adopt_images(); }
    ~Swapchain11() override;
    Swapchain11(const Swapchain11&) = delete;
    Swapchain11& operator=(const Swapchain11&) = delete;
    Swapchain11(Swapchain11&&) = delete;
    Swapchain11& operator=(Swapchain11&&) = delete;

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

private:
    [[nodiscard]] Status adopt_images();
    void release_images();
    void unbind_targets();

    D3d11Device* device_;
    Microsoft::WRL::ComPtr<IDXGISwapChain> swap_;
    Format format_ = Format::kBgra8UnormSrgb;
    PresentMode mode_ = PresentMode::kFifo;
    std::uint32_t width_ = 0;
    std::uint32_t height_ = 0;
    bool is_flip_ = false;
    std::vector<TextureHandle> images_;
    std::vector<TextureViewHandle> views_;
};

} // namespace game::gpu::d3d11
