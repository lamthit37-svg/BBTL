// Swapchain GL: vài texture màu, present blit lên framebuffer của cửa sổ rồi SwapBuffers.
#include "gpu/gles/device.hpp"

#include <algorithm>
#include <utility>
#include <vector>

namespace game::gpu::gles {
namespace {

using core::ErrorCode;
using core::fail;
using core::ok;

class GlSwapchain final : public Swapchain {
public:
    GlSwapchain(GlDevice& device, std::uint32_t width, std::uint32_t height, PresentMode mode)
        : device_(&device), width_(width), height_(height), mode_(mode) {}

    ~GlSwapchain() override {
        if (!device_->lock_context()) return;
        for (Sync fence : fences_) {
            if (fence != nullptr) device_->api().client_wait(fence, 0, GL_TIMEOUT_IGNORED);
            if (fence != nullptr) device_->api().delete_sync(fence);
        }
        device_->unlock_context();
        for (const TextureViewHandle view : views_)
            device_->destroy(view);
        for (const TextureHandle image : images_)
            device_->destroy(image);
    }

    [[nodiscard]] core::Result<std::uint32_t> acquire() override {
        if (width_ == 0 || height_ == 0) return fail(ErrorCode::kInvalidState, "swapchain GL cần resize");
        if (!device_->lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
        Sync fence = fences_.at(index_);
        if (fence != nullptr) device_->api().client_wait(fence, 0, GL_TIMEOUT_IGNORED);
        device_->unlock_context();
        return index_;
    }

    [[nodiscard]] TextureHandle image(std::uint32_t index) const override { return images_.at(index); }
    [[nodiscard]] TextureViewHandle view(std::uint32_t index) const override { return views_.at(index); }
    [[nodiscard]] std::uint32_t image_count() const noexcept override {
        return static_cast<std::uint32_t>(images_.size());
    }

    [[nodiscard]] core::Status present() override {
        if (!device_->lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
        GlTexture* texture = device_->texture(images_.at(index_));
        if (texture == nullptr) {
            device_->unlock_context();
            return fail(ErrorCode::kInvalidState, "present: ảnh swapchain đã chết");
        }
        GlFunctions& api = device_->api();
        const std::uint32_t read = device_->read_framebuffer();
        api.bind_framebuffer(GL_READ_FRAMEBUFFER, read);
        api.framebuffer_texture(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, texture->target, texture->name, 0);
        api.bind_framebuffer(GL_DRAW_FRAMEBUFFER, 0);
        api.blit_framebuffer(0, 0, static_cast<int>(width_), static_cast<int>(height_), 0, 0, static_cast<int>(width_),
            static_cast<int>(height_), GL_COLOR_BUFFER_BIT, GL_NEAREST);
        api.bind_framebuffer(GL_FRAMEBUFFER, 0);
        device_->context_swap();
        if (fences_.at(index_) != nullptr) api.delete_sync(fences_.at(index_));
        fences_.at(index_) = api.fence_sync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
        device_->unlock_context();
        index_ = (index_ + 1) % static_cast<std::uint32_t>(images_.size());
        return ok();
    }

    [[nodiscard]] core::Status resize(std::uint32_t width, std::uint32_t height) override {
        if (width == 0 || height == 0) return fail(ErrorCode::kInvalidArgument, "cỡ swapchain bằng 0");
        const core::Status idle = device_->wait_idle();
        if (!idle) return idle;
        for (const TextureViewHandle view : views_)
            device_->destroy(view);
        for (const TextureHandle image : images_)
            device_->destroy(image);
        views_.clear();
        images_.clear();
        width_ = width;
        height_ = height;
        return make_images(static_cast<std::uint32_t>(fences_.size()));
    }

    [[nodiscard]] Format format() const noexcept override { return Format::kRgba8UnormSrgb; }
    [[nodiscard]] PresentMode present_mode() const noexcept override { return mode_; }
    [[nodiscard]] std::uint32_t width() const noexcept override { return width_; }
    [[nodiscard]] std::uint32_t height() const noexcept override { return height_; }

    [[nodiscard]] core::Status make_images(std::uint32_t count) {
        fences_.assign(count, nullptr);
        for (std::uint32_t index = 0; index < count; ++index) {
            TextureDesc desc;
            desc.name = "gles.swapchain";
            desc.format = Format::kRgba8UnormSrgb;
            desc.width = width_;
            desc.height = height_;
            desc.usage = TextureUsage::kColorTarget | TextureUsage::kCopySource;
            const core::Result<TextureHandle> image = device_->create_texture(desc);
            if (!image) return std::unexpected(image.error());
            TextureViewDesc view;
            view.name = "gles.swapchain";
            view.texture = *image;
            const core::Result<TextureViewHandle> viewed = device_->create_view(view);
            if (!viewed) {
                device_->destroy(*image);
                return std::unexpected(viewed.error());
            }
            images_.push_back(*image);
            views_.push_back(*viewed);
        }
        index_ = 0;
        return ok();
    }

private:
    GlDevice* device_ = nullptr;
    std::uint32_t width_ = 0;
    std::uint32_t height_ = 0;
    PresentMode mode_ = PresentMode::kFifo;
    std::uint32_t index_ = 0;
    std::vector<TextureHandle> images_;
    std::vector<TextureViewHandle> views_;
    std::vector<Sync> fences_;
};

} // namespace

void GlDevice::context_swap() {
    context_.swap_buffers();
}

Result<std::unique_ptr<Swapchain>> GlDevice::create_swapchain(const SwapchainDesc& desc) {
    if (desc.window == nullptr || desc.width == 0 || desc.height == 0) {
        return fail(ErrorCode::kInvalidArgument, "swapchain GL thiếu cửa sổ hoặc cỡ");
    }
    const core::Status attached = context_.attach_window(desc.window);
    if (!attached) return std::unexpected(attached.error());
    // GL không có Mailbox. Chỉ Fifo mới chờ quét: nơi xin Mailbox (desktop) tự giữ nhịp bằng
    // đồng hồ của luồng vẽ, thêm chờ quét của driver thì hai nhịp giẫm nhau (đo trên WGL, màn
    // 60 Hz: khung nhảy 7/16/32 ms). Cửa sổ do DWM ghép nên không chờ quét cũng không xé hình.
    const bool is_vsync = desc.present_mode == PresentMode::kFifo;
    const int interval = is_vsync ? 1 : 0;
    context_.set_interval(interval);
    const std::uint32_t count = desc.image_count == 0 ? 2U : std::min(desc.image_count, 3U);
    auto chain = std::make_unique<GlSwapchain>(*this, desc.width, desc.height, desc.present_mode);
    const core::Status images = chain->make_images(count);
    if (!images) return std::unexpected(images.error());
    return chain;
}

} // namespace game::gpu::gles
