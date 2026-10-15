/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/pipeline.hpp
 *  PHÂN HỆ   : Gpu / Pipeline
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Shader và pipeline — BinaryShaderDesc, PipelineDesc, RasterizerStateDesc,
 *    DepthStateDesc, BlendStateDesc, VertexLayout của IGraphics.h trong _Ref và
 *    rhi/pipeline.hpp của Platium. Khác gốc:
 *  - shader vào bằng shader::Variant (mã kèm phản chiếu) của module shader; bố
 *    cục gắn tài nguyên của pipeline dựng từ phản chiếu ấy. _Ref bắt khai bố
 *    cục bằng macro SRT ở cả C++ lẫn shader, Platium chỉ có một bố cục bindless
 *    toàn cục;
 *  - tên ngữ nghĩa mà D3D12 cần cho từng thuộc tính đỉnh lấy từ phản chiếu của
 *    vertex shader theo location; Platium bắt chỗ gọi khai lại tên, _Ref khai
 *    enum ShaderSemantic;
 *  - không có đối tượng render pass hay framebuffer: pipeline chỉ cần định dạng
 *    của attachment (dynamic rendering của Vulkan 1.3, và D3D12 vốn vậy);
 *  - chữ ký giữa các stage được kiểm lúc tạo pipeline
 *    (shader::check_interface), trước khi D3D12 trả một HRESULT không tên.
 *  - Nguồn: Forge2 src/gpu/pipeline.hpp@d7fcd76. Khác gốc (so với Forge2):
 *    enumerator mang tiền tố k; bỏ {} thừa của các thành viên string_view và
 *    span ở ShaderDesc, GraphicsPipelineDesc, ComputePipelineDesc.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/types.hpp"
#include "shader/package.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <string_view>

namespace game::gpu {

// Đích dịch shader mà backend nhận: SPIR-V cho Vulkan, DXIL cho D3D12, DXBC cho D3D11, GLSL cho GLES.
[[nodiscard]] constexpr shader::Target shader_target(Backend backend) noexcept {
    if (backend == Backend::kD3D12) return shader::Target::kDxil;
    if (backend == Backend::kD3D11) return shader::Target::kDxbc;
    if (backend == Backend::kGles) return shader::Target::kGlsl;
    return shader::Target::kSpirV;
}

// Khác gốc: bỏ {} mà clang-tidy báo thừa ở mọi thành viên string_view và span của tệp này.
struct ShaderDesc {
    std::string_view name;
    // Bản dịch đúng đích của backend. Chỉ mượn trong lời gọi: Device chép mã và phản chiếu.
    const shader::Variant* variant = nullptr;
};

// Một buffer đỉnh của pipeline; vị trí trong GraphicsPipelineDesc::vertex_buffers là số khe.
struct VertexBufferLayout {
    std::uint32_t stride = 0;
    // Bước theo từng thể hiện (instance) thay vì từng đỉnh.
    bool is_per_instance = false;
};

struct VertexAttribute {
    // Location của đầu vào trong vertex shader: thứ tự khai báo trong struct đầu vào của HLSL.
    std::uint32_t location = 0;
    // Khe của buffer chứa thuộc tính.
    std::uint32_t buffer = 0;
    Format format = Format::kUnknown;
    std::uint32_t offset = 0;
};

struct RasterState {
    CullMode cull = CullMode::kBack;
    FrontFace front_face = FrontFace::kCounterClockwise;
    FillMode fill = FillMode::kSolid;
    // Giá trị thô truyền thẳng xuống; đơn vị phụ thuộc định dạng độ sâu ở cả hai API.
    float depth_bias = 0.0F;
    float depth_bias_slope = 0.0F;
    float depth_bias_clamp = 0.0F;
    // false: hình ngoài khoảng độ sâu bị kẹp thay vì bị cắt (bóng đổ của vật sau mặt phẳng gần).
    bool is_depth_clipped = true;
    // Cần DeviceCaps::conservative_raster.
    bool is_conservative = false;
};

struct StencilFace {
    StencilOp fail = StencilOp::kKeep;
    StencilOp depth_fail = StencilOp::kKeep;
    StencilOp pass = StencilOp::kKeep;
    CompareOp compare = CompareOp::kAlways;
};

struct DepthState {
    // Unknown: pipeline không có attachment độ sâu.
    Format format = Format::kUnknown;
    bool is_tested = false;
    bool is_written = false;
    // GreaterOrEqual vì độ sâu đảo (ClearDepth).
    CompareOp compare = CompareOp::kGreaterOrEqual;
    bool is_stencil_tested = false;
    StencilFace front{};
    StencilFace back{};
    std::uint8_t stencil_read_mask = 0xFF;
    std::uint8_t stencil_write_mask = 0xFF;
    // Bật phép thử khoảng độ sâu (CommandList::set_depth_bounds); cần DeviceCaps::depth_bounds.
    bool is_bounds_tested = false;
};

struct BlendState {
    bool is_enabled = false;
    BlendFactor src_color = BlendFactor::kOne;
    BlendFactor dst_color = BlendFactor::kZero;
    BlendOp color_op = BlendOp::kAdd;
    BlendFactor src_alpha = BlendFactor::kOne;
    BlendFactor dst_alpha = BlendFactor::kZero;
    BlendOp alpha_op = BlendOp::kAdd;
    // Bốn bit thấp là R, G, B, A.
    std::uint8_t write_mask = 0x0F;
};

struct GraphicsPipelineDesc {
    std::string_view name;
    // Mỗi stage tối đa một shader; stage đọc từ phản chiếu của chính shader. Phải có vertex shader
    // (hoặc mesh shader) — pixel shader được vắng với pipeline chỉ ghi độ sâu.
    std::span<const ShaderHandle> shaders;
    std::span<const VertexBufferLayout> vertex_buffers;
    std::span<const VertexAttribute> vertex_attributes;
    Topology topology = Topology::kTriangleList;
    // Số điểm điều khiển khi topology là PatchList.
    std::uint32_t patch_points = 0;
    RasterState raster{};
    DepthState depth{};
    std::span<const Format> color_formats;
    // Rỗng: mọi đích không trộn. Một phần tử: dùng cho mọi đích. Còn lại phải đủ color_formats.
    std::span<const BlendState> blends;
    std::uint32_t samples = 1;
    bool is_alpha_to_coverage = false;
};

struct ComputePipelineDesc {
    std::string_view name;
    ShaderHandle shader{};
};

} // namespace game::gpu
