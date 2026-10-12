// Context EGL cho Android. Cùng hợp đồng với context_wgl.cpp: một context, pbuffer khi chưa có cửa sổ.
#include "gpu/gles/context.hpp"

#include "gpu/gles/probe.hpp"

#include <EGL/egl.h>
#include <android/native_window.h>

#include <cstring>
#include <string>
#include <utility>

namespace game::gpu::gles {
namespace {

using core::ErrorCode;
using core::fail;

struct Version {
    EGLint minor = 2;
};

constexpr Version kTries[]{{2}, {1}};

void* egl_proc(const char* name, void*) {
    using EglFunction = void (*)();
    const EglFunction raw = eglGetProcAddress(name);
    void* address = nullptr;
    std::memcpy(&address, &raw, sizeof(address));
    return address;
}

[[nodiscard]] bool has_extension(EGLDisplay display, std::string_view name) {
    const char* text = eglQueryString(display, EGL_EXTENSIONS);
    if (text == nullptr) return false;
    const std::string_view all(text);
    for (std::size_t start = 0; start + name.size() <= all.size(); ++start) {
        if (all.substr(start, name.size()) != name) continue;
        const bool left = start == 0 || all[start - 1] == ' ';
        const std::size_t end = start + name.size();
        const bool right = end == all.size() || all[end] == ' ';
        if (left && right) return true;
    }
    return false;
}

} // namespace

struct GlContext::Native {
    EGLDisplay display = EGL_NO_DISPLAY;
    EGLContext context = EGL_NO_CONTEXT;
    EGLSurface pbuffer = EGL_NO_SURFACE;
    EGLSurface window = EGL_NO_SURFACE;
    EGLConfig config = nullptr;
    GlFunctions api{};
    GlProfile profile{};
    std::string renderer;
    std::string driver;
    std::atomic<std::uint64_t>* errors = nullptr;

    ~Native() {
        if (display == EGL_NO_DISPLAY) return;
        eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (window != EGL_NO_SURFACE) eglDestroySurface(display, window);
        if (pbuffer != EGL_NO_SURFACE) eglDestroySurface(display, pbuffer);
        if (context != EGL_NO_CONTEXT) eglDestroyContext(display, context);
        eglTerminate(display);
    }
};

GlContext::GlContext(std::unique_ptr<Native> native) : native_(std::move(native)) {}
GlContext::~GlContext() = default;
GlContext::GlContext(GlContext&&) noexcept = default;
GlContext& GlContext::operator=(GlContext&&) noexcept = default;

bool GlContext::make_current() {
    if (native_ == nullptr || native_->context == EGL_NO_CONTEXT) return false;
    const EGLSurface draw = native_->window != EGL_NO_SURFACE ? native_->window : native_->pbuffer;
    return eglMakeCurrent(native_->display, draw, draw, native_->context) == EGL_TRUE;
}

core::Status GlContext::attach_window(void* window) {
    if (native_ == nullptr || window == nullptr) {
        return fail(ErrorCode::kInvalidArgument, "swapchain GLES thiếu cửa sổ");
    }
    if (native_->window != EGL_NO_SURFACE) eglDestroySurface(native_->display, native_->window);
    auto* const target = static_cast<ANativeWindow*>(window);
    // Thiết bị màu thô (xem device.hpp): ảnh swapchain cất số đã mã hoá trong RGBA8 thường và
    // present là glBlitFramebuffer. Bề mặt mặc định của EGL không đổi gì lúc chép nên hình ra đúng;
    // bề mặt sRGB của EGL_KHR_gl_colorspace sẽ mã hoá thêm một lần.
    native_->window = eglCreateWindowSurface(native_->display, native_->config, target, nullptr);
    if (native_->window == EGL_NO_SURFACE) {
        return fail(ErrorCode::kUnsupported, "không tạo được bề mặt EGL");
    }
    if (!make_current()) return fail(ErrorCode::kUnsupported, "không gắn được context EGL");
    return core::ok();
}

void GlContext::swap_buffers() {
    if (native_ != nullptr && native_->window != EGL_NO_SURFACE) {
        eglSwapBuffers(native_->display, native_->window);
    }
}

void GlContext::set_interval(int interval) {
    if (native_ != nullptr) eglSwapInterval(native_->display, interval);
}

void GlContext::set_debug_sink(std::atomic<std::uint64_t>* errors) noexcept {
    if (native_ == nullptr) return;
    native_->errors = errors;
    if (native_->api.debug_callback == nullptr || errors == nullptr) return;
    native_->api.enable(GL_DEBUG_OUTPUT);
    const auto sink = debug_sink();
    native_->api.debug_callback(sink, errors);
}

const GlProfile& GlContext::profile() const noexcept {
    return native_->profile;
}

std::string_view GlContext::renderer() const noexcept {
    return native_->renderer;
}

std::string_view GlContext::driver() const noexcept {
    return native_->driver;
}

GlFunctions& GlContext::api() noexcept {
    return native_->api;
}

const GlFunctions& GlContext::api() const noexcept {
    return native_->api;
}

core::Result<GlContext> open_context(bool) {
    auto native = std::make_unique<GlContext::Native>();
    native->display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (native->display == EGL_NO_DISPLAY) {
        return fail(ErrorCode::kUnsupported, "không có màn hình EGL");
    }
    if (eglInitialize(native->display, nullptr, nullptr) != EGL_TRUE) {
        return fail(ErrorCode::kUnsupported, "eglInitialize thất bại");
    }
    // Không bắt pbuffer: một số GPU điện thoại chỉ có bề mặt cửa sổ. Context vẫn current được
    // nhờ EGL_KHR_surfaceless_context cho tới khi attach_window gắn ANativeWindow.
    const EGLint config_attributes[]{EGL_SURFACE_TYPE, EGL_WINDOW_BIT, EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_DEPTH_SIZE, 24, EGL_NONE};
    EGLint count = 0;
    if (eglChooseConfig(native->display, config_attributes, &native->config, 1, &count) != EGL_TRUE || count == 0) {
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "không chọn được config EGL");
    }
    for (const Version& version : kTries) {
        const EGLint context_attributes[]{
            EGL_CONTEXT_MAJOR_VERSION, 3, EGL_CONTEXT_MINOR_VERSION, version.minor, EGL_NONE};
        native->context = eglCreateContext(native->display, native->config, EGL_NO_CONTEXT, context_attributes);
        if (native->context != EGL_NO_CONTEXT) break;
    }
    if (native->context == EGL_NO_CONTEXT) {
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "không mở được OpenGL ES 3.1");
    }
    const EGLint pbuffer_attributes[]{EGL_WIDTH, 8, EGL_HEIGHT, 8, EGL_NONE};
    native->pbuffer = eglCreatePbufferSurface(native->display, native->config, pbuffer_attributes);
    if (native->pbuffer == EGL_NO_SURFACE) {
        while (eglGetError() != EGL_SUCCESS) {
        }
    }
    const bool has_pbuffer = native->pbuffer != EGL_NO_SURFACE;
    const bool is_surfaceless = has_extension(native->display, "EGL_KHR_surfaceless_context");
    EGLBoolean current = EGL_FALSE;
    if (has_pbuffer) {
        current = eglMakeCurrent(native->display, native->pbuffer, native->pbuffer, native->context);
    } else if (is_surfaceless) {
        current = eglMakeCurrent(native->display, EGL_NO_SURFACE, EGL_NO_SURFACE, native->context);
    }
    if (current != EGL_TRUE) {
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "không current được context EGL");
    }
    if (!load_functions(native->api, &egl_proc, nullptr)) {
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "driver thiếu hàm OpenGL ES mà engine cần");
    }
    GlProbe probe = probe_context(native->api, GlFlavor::kEmbedded);
    native->renderer = std::move(probe.renderer);
    native->driver = std::move(probe.driver);
    native->profile = probe.profile;
    if (native->profile.has_clip_control) {
        native->api.clip_control(GL_LOWER_LEFT, GL_ZERO_TO_ONE);
    }
    if (!is_usable(native->profile)) {
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "OpenGL ES dưới 3.1 hoặc thiếu SSBO");
    }
    return GlContext(std::move(native));
}

} // namespace game::gpu::gles
