// Phần dùng chung của các lượt vẽ trong module render: thư mục gói shader mặc định, cặp shader của
// một pipeline nạp từ gói .f2s và phép trộn alpha chuẩn. forward.cpp và ui.cpp cùng dùng để hai
// lượt vẽ nạp shader theo đúng một cách. Nội bộ module render.
// Gói shader nằm ngoài exe (cạnh exe, hoặc giải nén từ APK) nên có thể cũ hơn mã: lúc nạp, cỡ khối
// hằng trong phản chiếu của gói được so với cỡ mà mã C++ ghi. Lệch thì từ chối ngay, vì shader cũ
// đọc khối bố cục mới sẽ lấy rác làm chỉ số buffer (trên PowerVR cả khung bị huỷ, không lỗi GL).
#pragma once

#include "core/error.hpp"
#include "core/system.hpp"
#include "core/text.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"
#include "gpu/pipeline.hpp"
#include "shader/package.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <string>
#include <string_view>

namespace game::render::detail {

// Thư mục con chứa gói .f2s nằm cạnh exe, dùng khi người gọi không nêu thư mục.
inline constexpr std::wstring_view kShaderFolder = L"shaders";

// Thư mục gói shader: chosen khi khác rỗng, không thì <thư mục exe>/shaders.
[[nodiscard]] inline std::string shader_folder(const std::string& chosen) {
    if (!chosen.empty()) return chosen;
    const std::wstring beside_exe = (core::exe_directory() / kShaderFolder).wstring();
    return core::narrow(beside_exe);
}

// Trộn alpha thẳng: màu nguồn nhân alpha cộng màu đích nhân phần còn lại.
[[nodiscard]] inline gpu::BlendState alpha_blend() noexcept {
    gpu::BlendState blend;
    blend.is_enabled = true;
    blend.src_color = gpu::BlendFactor::kSrcAlpha;
    blend.dst_color = gpu::BlendFactor::kOneMinusSrcAlpha;
    blend.dst_alpha = gpu::BlendFactor::kOneMinusSrcAlpha;
    return blend;
}

// Cỡ (byte) của hai khối hằng mà mã C++ ghi cho một pipeline: khối của khung (cbuffer ở space 0)
// và khối của lệnh vẽ (push constant). 0 là không kiểm khối đó.
struct BlockSizes {
    std::uint32_t frame = 0;
    std::uint32_t draw = 0;
};

// Lỗi khi một khối hằng của shader có cỡ khác cỡ mã ghi.
[[nodiscard]] inline core::Status check_block(const shader::StageReflection& stage, const shader::Resource& resource,
    BlockSizes sizes, std::string_view name) {
    const bool is_draw = resource.kind == shader::ResourceKind::kPushConstant;
    const bool is_cbuffer = resource.kind == shader::ResourceKind::kUniformBuffer;
    const bool is_frame = is_cbuffer && resource.space == 0;
    const std::uint32_t frame = is_frame ? sizes.frame : 0;
    const std::uint32_t wanted = is_draw ? sizes.draw : frame;
    if (wanted == 0 || resource.block >= stage.blocks.size()) return core::ok();
    const std::uint32_t found = stage.blocks[resource.block].size;
    if (found == wanted) return core::ok();
    return core::fail(core::ErrorCode::kInvalidArgument, "gói shader lệch đời với mã",
        "{}: khối hằng {} byte, mã ghi {} byte", name, found, wanted);
}

[[nodiscard]] inline core::Status check_blocks(const shader::StageReflection& stage, BlockSizes sizes,
    std::string_view name) {
    core::Status status = core::ok();
    for (const shader::Resource& resource : stage.resources) {
        status = status ? check_block(stage, resource, sizes, name) : status;
    }
    return status;
}

// Hai shader của pipeline (0 là đỉnh, 1 là điểm ảnh); tay nắm chỉ cần tới khi dựng xong pipeline.
struct ShaderPair {
    explicit ShaderPair(gpu::Device& owner) noexcept : device(&owner) {}
    ShaderPair(const ShaderPair&) = delete;
    ShaderPair& operator=(const ShaderPair&) = delete;
    ShaderPair(ShaderPair&&) = delete;
    ShaderPair& operator=(ShaderPair&&) = delete;
    ~ShaderPair() {
        device->destroy(handles.front());
        device->destroy(handles.back());
    }

    // Nạp gói <folder>/<name>.f2s và tạo shader cho backend của thiết bị vào ô index.
    // InvalidArgument khi khối hằng của gói khác cỡ khai ở sizes.
    [[nodiscard]] core::Status load(std::size_t index, const std::string& folder, std::string_view name);

    gpu::Device* device;
    std::array<gpu::ShaderHandle, 2> handles{};
    // Đặt trước khi load nếu muốn kiểm cỡ khối hằng của gói.
    BlockSizes sizes{};
};

inline core::Status ShaderPair::load(std::size_t index, const std::string& folder, std::string_view name) {
    const auto package = shader::Package::load(shader::package_path(folder, name));
    if (!package) return std::unexpected(package.error());
    const shader::Target target = gpu::shader_target(device->adapter().backend);
    const shader::Variant* variant = package->find(target);
    const core::ErrorCode missing = core::ErrorCode::kUnsupported;
    if (variant == nullptr) return core::fail(missing, "gói shader thiếu bản cho backend", name);
    const core::Status fitted = check_blocks(variant->reflection, sizes, name);
    if (!fitted) return fitted;
    const gpu::ShaderDesc shader_desc{.name = name, .variant = variant};
    const core::Result<gpu::ShaderHandle> made = device->create_shader(shader_desc);
    if (!made) return std::unexpected(made.error());
    handles.at(index) = *made;
    return core::ok();
}

} // namespace game::render::detail
