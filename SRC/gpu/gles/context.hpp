// Context OpenGL: WGL trên Windows, EGL trên Android. Một context cho cả nạp tài nguyên và present.
// Cửa sổ ẩn giữ context khi chưa có swapchain; cửa sổ game chỉ được gắn lúc tạo swapchain.
#pragma once

#include "core/error.hpp"
#include "gpu/gles/gl_api.hpp"
#include "gpu/gles/pick.hpp"

#include <atomic>
#include <memory>
#include <string>
#include <string_view>

namespace game::gpu::gles {

class GlContext {
public:
    GlContext() = default;
    ~GlContext();
    GlContext(GlContext&&) noexcept;
    GlContext& operator=(GlContext&&) noexcept;
    GlContext(const GlContext&) = delete;
    GlContext& operator=(const GlContext&) = delete;

    [[nodiscard]] bool make_current();
    // Gắn HWND hoặc ANativeWindow. Pixel format phải tương thích với context.
    [[nodiscard]] core::Status attach_window(void* window);
    void swap_buffers();
    void set_interval(int interval);
    void set_debug_sink(std::atomic<std::uint64_t>* errors) noexcept;
    [[nodiscard]] const GlProfile& profile() const noexcept;
    [[nodiscard]] std::string_view renderer() const noexcept;
    [[nodiscard]] std::string_view driver() const noexcept;
    [[nodiscard]] GlFunctions& api() noexcept;
    [[nodiscard]] const GlFunctions& api() const noexcept;

private:
    struct Native;
    explicit GlContext(std::unique_ptr<Native> native);

    std::unique_ptr<Native> native_;

    friend core::Result<GlContext> open_context(bool debug);
};

// Context ẩn, đủ để liệt kê và để test không cửa sổ. Unsupported khi driver dưới mức dùng được.
[[nodiscard]] core::Result<GlContext> open_context(bool debug);

} // namespace game::gpu::gles
