// Đọc năng lực của context GL đang current. Thứ tự lời gọi GL giữ như hai bản từng nằm riêng ở
// context_wgl.cpp và context_egl.cpp; chỗ hai dòng API khác nhau được ghi ngay tại hàm.
#include "gpu/gles/probe.hpp"

#include "core/log.hpp"
#include "gpu/gles/gl_api.hpp"
#include "gpu/gles/pick.hpp"

#include <atomic>
#include <cstdint>
#include <string>
#include <string_view>

namespace game::gpu::gles {
namespace {

// Chuỗi C mà GL trả dưới kiểu GLubyte*. Rỗng khi driver trả null.
[[nodiscard]] std::string_view text_of(const std::uint8_t* bytes) noexcept {
    if (bytes == nullptr) return {};
    // unsigned char và char được phép trỏ cùng vùng nhớ; GL không có bản trả char*.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    return reinterpret_cast<const char*>(bytes);
}

[[nodiscard]] std::string copy_string(const GlFunctions& api, std::uint32_t name) {
    const std::uint8_t* bytes = api.get_string(name);
    return std::string(text_of(bytes));
}

[[nodiscard]] int integer_of(const GlFunctions& api, std::uint32_t name) {
    int value = 0;
    api.get_integer(name, &value);
    return value;
}

// Truy vấn driver không biết để lại GL_INVALID_ENUM; xoá để lỗi ấy không lọt sang lệnh sau.
void clear_error(const GlFunctions& api) {
    while (api.get_error() != 0) {
    }
}

[[nodiscard]] bool has_extension(const GlFunctions& api, std::string_view name) {
    int count = 0;
    api.get_integer(GL_NUM_EXTENSIONS, &count);
    if (api.get_stringi == nullptr) return false;
    bool is_found = false;
    for (int index = 0; index < count && !is_found; ++index) {
        const auto slot = static_cast<std::uint32_t>(index);
        const std::uint8_t* bytes = api.get_stringi(GL_EXTENSIONS, slot);
        is_found = bytes != nullptr && text_of(bytes) == name;
    }
    return is_found;
}

// Compute có từ OpenGL 4.3 và OpenGL ES 3.1.
[[nodiscard]] bool has_compute(const GlProfile& profile) noexcept {
    if (profile.is_es) return profile.major > 3 || profile.minor >= 1;
    return profile.major > 4 || (profile.major == 4 && profile.minor >= 3);
}

void read_anisotropy(GlProfile& profile, const GlFunctions& api) {
    if (has_extension(api, "GL_EXT_texture_filter_anisotropic")) {
        const int most = integer_of(api, GL_MAX_TEXTURE_MAX_ANISOTROPY);
        profile.max_anisotropy = static_cast<std::uint32_t>(most);
    }
    clear_error(api);
}

// probe.renderer phải có trước: tên card quyết định is_discrete và is_software.
void read_profile(GlProbe& probe, const GlFunctions& api, GlFlavor flavor) {
    GlProfile& profile = probe.profile;
    profile.major = integer_of(api, GL_MAJOR_VERSION);
    profile.minor = integer_of(api, GL_MINOR_VERSION);
    profile.is_es = flavor == GlFlavor::kEmbedded;
    const RendererClass kind = classify_renderer(probe.renderer);
    profile.is_discrete = kind.is_discrete;
    profile.is_software = kind.is_software;
    profile.has_clip_control = api.clip_control != nullptr;
    profile.has_buffer_storage = api.buffer_storage != nullptr;
    profile.has_srgb = true;
    profile.has_debug = api.debug_callback != nullptr;
    profile.has_compute = has_compute(profile);
    profile.max_texture = static_cast<std::uint32_t>(integer_of(api, GL_MAX_TEXTURE_SIZE));
    profile.max_samples = static_cast<std::uint32_t>(integer_of(api, GL_MAX_SAMPLES));
    const int uniform_blocks = integer_of(api, GL_MAX_UNIFORM_BUFFER_BINDINGS);
    profile.max_uniform_blocks = static_cast<std::uint32_t>(uniform_blocks);
    clear_error(api);
    const int storage_blocks = integer_of(api, GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS);
    profile.max_storage_blocks = static_cast<std::uint32_t>(storage_blocks);
    clear_error(api);
    apply_storage_floor(profile);
    // Chỉ context desktop hỏi anisotropy; bản EGL chưa từng hỏi nên ES giữ mặc định 1.
    if (flavor == GlFlavor::kDesktop) read_anisotropy(profile, api);
}

// Bảy tham số và const void* là chữ ký GLDEBUGPROC của đặc tả (lệch API-03). Bộ đếm mà user trỏ
// tới vốn không const: set_debug_sink của context nhận nó dưới dạng con trỏ thường.
// NOLINTBEGIN(readability-function-size,cppcoreguidelines-pro-type-const-cast)
void GL_APIENTRY on_debug(std::uint32_t, std::uint32_t type, std::uint32_t, std::uint32_t severity,
    std::int32_t, const char* message, const void* user) {
    const auto* errors = static_cast<const std::atomic<std::uint64_t>*>(user);
    if (type == GL_DEBUG_TYPE_ERROR && errors != nullptr) {
        const_cast<std::atomic<std::uint64_t>*>(errors)->fetch_add(1, std::memory_order_relaxed);
    }
    if (severity == GL_DEBUG_SEVERITY_HIGH || type == GL_DEBUG_TYPE_ERROR) {
        core::warn("gles: {}", message != nullptr ? message : "");
    }
}
// NOLINTEND(readability-function-size,cppcoreguidelines-pro-type-const-cast)

} // namespace

GlProbe probe_context(const GlFunctions& api, GlFlavor flavor) {
    GlProbe probe;
    probe.renderer = copy_string(api, GL_RENDERER);
    probe.driver = copy_string(api, GL_VERSION);
    read_profile(probe, api, flavor);
    return probe;
}

DebugProc debug_sink() noexcept {
    return &on_debug;
}

} // namespace game::gpu::gles
