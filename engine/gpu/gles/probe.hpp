// Phần chung của context WGL và EGL sau khi context đã current và con trỏ hàm đã nạp: chép chuỗi
// nhận dạng, đọc năng lực vào GlProfile, và callback nhận thông điệp debug của driver. Hai tệp
// context chỉ còn giữ phần riêng của nền tảng (cửa sổ, pixel format, bề mặt).
#pragma once

#include "gpu/gles/gl_api.hpp"
#include "gpu/gles/pick.hpp"

#include <cstdint>
#include <string>

namespace game::gpu::gles {

// Dòng API của context: OpenGL lõi trên desktop hay OpenGL ES.
enum class GlFlavor : std::uint8_t {
    kDesktop,
    kEmbedded,
};

// Nhận dạng và năng lực đọc một lần lúc mở context.
struct GlProbe {
    std::string renderer;
    std::string driver;
    GlProfile profile;
};

// Đọc GL_RENDERER, GL_VERSION rồi các giới hạn của context đang current. Chuỗi rỗng khi driver
// trả null.
[[nodiscard]] GlProbe probe_context(const GlFunctions& api, GlFlavor flavor);

// Callback cho glDebugMessageCallback. Tham số user của nó phải trỏ tới bộ đếm lỗi kiểu
// std::atomic<std::uint64_t>, hoặc null khi không đếm.
[[nodiscard]] DebugProc debug_sink() noexcept;

} // namespace game::gpu::gles
