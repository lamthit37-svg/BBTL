// Context WGL. Cửa sổ giả chỉ để lấy địa chỉ hàm, rồi context lõi 4.6 / 4.5 / 4.3 trên cửa sổ ẩn.
// Hai biến xuất khiến NVIDIA Optimus và AMD PowerXpress chọn GPU rời: chọn nhầm iGPU là tụt xuống
// vài khung mỗi giây.
#include "gpu/gles/context.hpp"

#include "core/win32.hpp"
#include "gpu/gles/probe.hpp"

#include <cstring>
#include <string>
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫

    ~Native() {
        if (context != nullptr && wglGetCurrentContext() == context) wglMakeCurrent(nullptr, nullptr);
        if (context != nullptr) wglDeleteContext(context);
        if (window_dc != nullptr) ReleaseDC(window, window_dc);
        if (hidden_dc != nullptr) ReleaseDC(hidden, hidden_dc);
        if (hidden != nullptr) DestroyWindow(hidden);
        if (library != nullptr) FreeLibrary(library);
    }
};

GlContext::GlContext(std::unique_ptr<Native> native) : native_(std::move(native)) {}

GlContext::~GlContext() = default;

GlContext::GlContext(GlContext&&) noexcept = default;
GlContext& GlContext::operator=(GlContext&&) noexcept = default;

bool GlContext::make_current() {
    if (native_ == nullptr || native_->context == nullptr) return false;
    const DWORD thread = GetCurrentThreadId();
    const HDC dc = native_->window_dc != nullptr ? native_->window_dc : native_->hidden_dc;
    if (native_->owner == thread && wglGetCurrentContext() == native_->context) return true;
    if (wglMakeCurrent(dc, native_->context) != TRUE) return false;
    native_->owner = thread;
    thread_bind.context = native_->context;
    return true;
}

core::Status GlContext::attach_window(void* window) {
    if (native_ == nullptr || window == nullptr) {
        return fail(ErrorCode::kInvalidArgument, "swapchain GLES thiếu cửa sổ");
    }
    auto* const handle = static_cast<HWND>(window);
    if (native_->window == handle && native_->window_dc != nullptr) return core::ok();
    if (wglGetCurrentContext() == native_->context) wglMakeCurrent(nullptr, nullptr);
    if (native_->window_dc != nullptr) ReleaseDC(native_->window, native_->window_dc);
    native_->window = nullptr;
    native_->window_dc = nullptr;
    native_->owner = 0;
    HDC dc = GetDC(handle);
    if (dc == nullptr) return fail(ErrorCode::kUnsupported, "không lấy được DC của cửa sổ");
    if (GetPixelFormat(dc) == 0) {
        const int attributes[]{kDrawWindow, 1, kSupportGl, 1, kDoubleBuffer, 1, kAcceleration,
            kFullAcceleration, kPixelType, kTypeRgba, kColorBits, 32, kAlphaBits, 8, kDepthBits, 24,
            kSrgb, 1, 0};
        int chosen = 0;
        UINT count = 0;
        const BOOL ok = native_->choose_format != nullptr &&
            native_->choose_format(dc, attributes, nullptr, 1, &chosen, &count) == TRUE && count > 0;
        int format = ok ? chosen : legacy_format(dc);
        if (!ok) {
            const int plain[]{kDrawWindow, 1, kSupportGl, 1, kDoubleBuffer, 1, kPixelType, kTypeRgba,
                kColorBits, 32, kAlphaBits, 8, kDepthBits, 24, 0};
            UINT plain_count = 0;
            if (native_->choose_format != nullptr &&
                native_->choose_format(dc, plain, nullptr, 1, &chosen, &plain_count) == TRUE &&
                plain_count > 0) {
                format = chosen;
            }
        }
        if (!apply_format(dc, format)) {
            ReleaseDC(handle, dc);
            return fail(ErrorCode::kUnsupported, "cửa sổ không nhận pixel format OpenGL");
        }
    }
    native_->window = handle;
    native_->window_dc = dc;
    native_->owner = 0;
    if (!make_current()) return fail(ErrorCode::kUnsupported, "không gắn được context vào cửa sổ");
    return core::ok();
}

void GlContext::swap_buffers() {
    if (native_ != nullptr && native_->window_dc != nullptr) SwapBuffers(native_->window_dc);
}

void GlContext::set_interval(int interval) {
    if (native_ != nullptr && native_->swap_interval != nullptr) native_->swap_interval(interval);
}

void GlContext::set_debug_sink(std::atomic<std::uint64_t>* errors) noexcept {
    if (native_ == nullptr) return;
    native_->errors = errors;
    if (native_->api.debug_callback == nullptr || errors == nullptr) return;
    native_->api.enable(GL_DEBUG_OUTPUT);
    native_->api.enable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
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

core::Result<GlContext> open_context(bool debug) {
    Dummy dummy;
    if (!boot_dummy(dummy)) {
        destroy_dummy(dummy);
        return fail(ErrorCode::kUnsupported, "máy không mở được context OpenGL");
    }
    auto native = std::make_unique<GlContext::Native>();
    native->library = LoadLibraryW(L"opengl32.dll");
    auto get = [&native](const char* name) { return proc_of(native->library, name); };
    void* create_raw = get("wglCreateContextAttribsARB");
    void* choose_raw = get("wglChoosePixelFormatARB");
    void* interval_raw = get("wglSwapIntervalEXT");
    std::memcpy(&native->create_attribs, &create_raw, sizeof(create_raw));
    std::memcpy(&native->choose_format, &choose_raw, sizeof(choose_raw));
    std::memcpy(&native->swap_interval, &interval_raw, sizeof(interval_raw));
    if (native->create_attribs == nullptr) {
        destroy_dummy(dummy);
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "driver không có context OpenGL hiện đại");
    }
    native->hidden = make_window();
    native->hidden_dc = native->hidden != nullptr ? GetDC(native->hidden) : nullptr;
    int modern = 0;
    UINT modern_count = 0;
    const int attributes[]{kDrawWindow, 1, kSupportGl, 1, kDoubleBuffer, 1, kAcceleration,
        kFullAcceleration, kPixelType, kTypeRgba, kColorBits, 32, kAlphaBits, 8, kDepthBits, 24,
        kSrgb, 1, 0};
    const bool chose = native->hidden_dc != nullptr && native->choose_format != nullptr &&
        native->choose_format(native->hidden_dc, attributes, nullptr, 1, &modern, &modern_count) ==
            TRUE &&
        modern_count > 0;
    const int format = chose ? modern : legacy_format(native->hidden_dc);
    if (!apply_format(native->hidden_dc, format)) {
        destroy_dummy(dummy);
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "không chọn được pixel format OpenGL");
    }
    HGLRC real = nullptr;
    for (const Version& version : kTries) {
        const int flags = debug ? kDebugFlag : 0;
        const int list[]{kMajorAttrib, version.major, kMinorAttrib, version.minor, kProfileAttrib,
            kCoreProfile, kFlagsAttrib, flags, 0};
        real = native->create_attribs(native->hidden_dc, nullptr, list);
        if (real != nullptr) break;
    }
    destroy_dummy(dummy);
    if (real == nullptr || wglMakeCurrent(native->hidden_dc, real) != TRUE) {
        if (real != nullptr) wglDeleteContext(real);
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "không mở được OpenGL 4.3");
    }
    native->context = real;
    native->owner = GetCurrentThreadId();
    if (!load_functions(native->api, &wgl_proc, native->library)) {
        GlContext doomed(std::move(native));
        return fail(ErrorCode::kUnsupported, "driver thiếu hàm OpenGL mà engine cần");
    }
    GlProbe probe = probe_context(native->api, GlFlavor::kDesktop);
    native->renderer = std::move(probe.renderer);
    native->driver = std::move(probe.driver);
    native->profile = probe.profile;
    if (native->profile.has_clip_control) {
        native->api.clip_control(GL_LOWER_LEFT, GL_ZERO_TO_ONE);
    }
    if (!is_usable(native->profile)) {
        const int major = native->profile.major;
        const int minor = native->profile.minor;
        GlContext doomed(std::move(native));
        constexpr const char* kOldGl = "OpenGL dưới 4.3 hoặc thiếu SSBO";
        return fail(ErrorCode::kUnsupported, kOldGl, "{}.{}", major, minor);
    }
    return GlContext(std::move(native));
}

} // namespace game::gpu::gles
