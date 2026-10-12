// Chọn đường vẽ khi máy không có Vulkan 1.3 phần cứng. Không đo 90 khung như backend_pick của
// TLBB: bài đo ngắn ấy xếp nhầm Direct3D 11 trên RTX 5060. Điểm GL chỉ là 0 hoặc 1 (dùng được và
// không phải GPU CPU). Không cộng điểm cho MSAA, anisotropy hay timer vì forward không bật chúng.
#pragma once

#include <cstdint>
#include <string_view>

namespace game::gpu::gles {

// Năng lực đọc một lần lúc mở context. Điểm càng cao càng nên chọn khi phải ở lại GL.
struct GlProfile {
    int major = 0;
    int minor = 0;
    bool is_es = false;
    bool is_discrete = false;
    bool is_software = false;
    bool has_clip_control = false;
    bool has_buffer_storage = false;
    bool has_timer = false;
    bool has_srgb = false;
    bool has_debug = false;
    bool has_compute = false;
    std::uint32_t max_texture = 0;
    std::uint32_t max_anisotropy = 1;
    std::uint32_t max_samples = 1;
    std::uint32_t max_uniform_blocks = 0;
    std::uint32_t max_storage_blocks = 0;
};

struct RendererClass {
    bool is_discrete = false;
    bool is_software = false;
};

// Tên GL_RENDERER: card rời, GPU tích hợp, hay bộ dựng bằng CPU.
[[nodiscard]] RendererClass classify_renderer(std::string_view renderer) noexcept;

// Đủ SSBO và hai khối uniform. Không bắt glClipControl: GLES 3.1 không có extension đó trong lõi,
// shader tự đưa z [0,1] về [-1,1] khi context không có. Bắt extension thì GE8320 có thể bị loại.
[[nodiscard]] bool is_usable(const GlProfile& profile) noexcept;

// Driver có lúc trả 0 hoặc INVALID_ENUM cho số binding SSBO dù context đủ bản (NVIDIA 591 trên
// GL 4.6). Trần spec của 4.3 và ES 3.1 là 8; một SSBO của shader model nằm trong trần đó.
void apply_storage_floor(GlProfile& profile) noexcept;

// Điểm trong GL. Bản không dùng được là 0.
[[nodiscard]] int profile_score(const GlProfile& profile) noexcept;

enum class GraphicsChoice : std::uint8_t {
    kVulkan,
    kGles,
    kNone,
};

// Phần cứng Vulkan 1.3 trước. Không có thì GL dùng được. Cả hai chỉ còn bản CPU thì vẫn Vulkan.
[[nodiscard]] constexpr GraphicsChoice choose_graphics(bool has_hardware_vulkan, bool has_hardware_gl,
    bool has_any_vulkan, bool has_any_gl) noexcept {
    if (has_hardware_vulkan) return GraphicsChoice::kVulkan;
    if (has_hardware_gl) return GraphicsChoice::kGles;
    if (has_any_vulkan) return GraphicsChoice::kVulkan;
    if (has_any_gl) return GraphicsChoice::kGles;
    return GraphicsChoice::kNone;
}

} // namespace game::gpu::gles
