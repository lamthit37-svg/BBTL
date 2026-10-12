// Pipeline D3D12: root signature 1.1 (mảng không chặn là DESCRIPTORS_VOLATILE để update khi đang
// nộp), PSO đồ hoạ cổ điển, PSO stream chỉ khi bật phép thử khoảng độ sâu. Một nhóm gắn là một
// hoặc hai descriptor table (tài nguyên và sampler) trong heap nhìn thấy từ shader.
// Nguồn: Forge2 src/gpu/d3d12/programs.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; thân vòng
// có nhánh tách hàm một lượt hoặc đưa điều kiện dừng lên điều kiện lặp; chữ ký dài gom tham số;
// include trực tiếp header của từng tên; Clang bỏ qua __uuidof của IID_PPV_ARGS; pragma C4324 chỉ
// khi dịch bằng MSVC.
#include "gpu/d3d12/device.hpp"

#include "core/error.hpp"
#include "core/log.hpp"
#include "core/text.hpp"
#include "gpu/binding.hpp"
#include "gpu/check.hpp"
#include "gpu/d3d12/convert.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/layout.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <combaseapi.h>
#include <d3d12.h>
#include <d3dcommon.h>
#include <dxgiformat.h>
#include <minwindef.h>
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <mutex>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <variant>
#include <vector>

#if defined(__clang__)
// __uuidof của IID_PPV_ARGS không có dạng chuẩn.
#pragma clang diagnostic ignored "-Wlanguage-extension-token"
#endif

namespace game::gpu::d3d12 {

// View và root parameter là union; enum của SDK không có giá trị 0 (UB-03, UB-06).
// NOLINTBEGIN(cppcoreguidelines-pro-type-union-access,bugprone-invalid-enum-default-initialization)

using core::ErrorCode;
using core::fail;
using core::ok;
using core::Result;
using core::Status;
using Microsoft::WRL::ComPtr;

using Caps = DeviceCaps;
using CpuHandle = D3D12_CPU_DESCRIPTOR_HANDLE;
using GraphicsDesc = D3D12_GRAPHICS_PIPELINE_STATE_DESC;
using ComputeDesc = D3D12_COMPUTE_PIPELINE_STATE_DESC;
using Device12 = ID3D12Device;
using Device2 = ID3D12Device2;
using ConstDevice = const D3d12Device;
using Library12 = ID3D12PipelineLibrary;
using State12 = ComPtr<ID3D12PipelineState>;
using Elements = std::vector<D3D12_INPUT_ELEMENT_DESC>;
using Bytes = std::vector<std::byte>;
using Reflections = std::vector<shader::StageReflection>;
using Stages = std::array<const Shader*, shader::kStageCount>;
using ShaderList = std::span<const ShaderHandle>;
using RootParameters = std::vector<D3D12_ROOT_PARAMETER1>;
using PipelineDesc = GraphicsPipelineDesc;
using Group = BindGroup;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr UINT kCbufferMax = 65'536;

namespace {

struct TableBuild {
    std::vector<D3D12_DESCRIPTOR_RANGE1> ranges;
    D3D12_SHADER_VISIBILITY visibility = D3D12_SHADER_VISIBILITY_ALL;
    bool is_sampler = false;
    std::uint32_t space = 0;
    UINT count = 0;
};

struct Gathered {
    std::array<const Shader*, shader::kStageCount> stages{};
    Program program;
};

struct ShaderSlots {
    const Shader* vertex = nullptr;
    const Shader* hull = nullptr;
    const Shader* domain = nullptr;
    const Shader* geometry = nullptr;
    const Shader* pixel = nullptr;
};

// C4324 báo khoảng đệm sau enum. Bố cục stream D3D12 bắt payload nằm ở căn con trỏ (8 byte trên
// x64), nên chỗ đệm ấy là hợp đồng, không phải thừa. Pragma chỉ MSVC hiểu.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
template <D3D12_PIPELINE_STATE_SUBOBJECT_TYPE Type, class Payload>
struct alignas(8) StreamItem {
    D3D12_PIPELINE_STATE_SUBOBJECT_TYPE type = Type;
    Payload value{};
};
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

using Tables = std::vector<TableBuild>;

struct TableRequest {
    const SpaceLayout* space = nullptr;
    bool samplers = false;
    const Caps* caps = nullptr;
};

struct KindMatch {
    const shader::Resource* resource = nullptr;
    bool samplers = false;
    const Caps* caps = nullptr;
};

struct SpaceAdd {
    Tables* tables = nullptr;
    Layout* layout = nullptr;
    const SpaceLayout* space = nullptr;
    std::uint32_t index = 0;
    const Caps* caps = nullptr;
};

struct ShaderTake {
    Stages* stages = nullptr;
    Reflections* reflections = nullptr;
};

struct AttributeRef {
    const PipelineDesc* desc = nullptr;
    const Program* program = nullptr;
    const VertexAttribute* attribute = nullptr;
};

struct ElementSource {
    const PipelineDesc* desc = nullptr;
    const Program* program = nullptr;
};

struct GraphicsFill {
    const PipelineDesc* desc = nullptr;
    const Layout* layout = nullptr;
    const Gathered* gathered = nullptr;
    const ShaderSlots* slots = nullptr;
    const Elements* elements = nullptr;
};

struct StreamParts {
    const D3D12_DEPTH_STENCIL_DESC1* depth = nullptr;
    const ShaderSlots* slots = nullptr;
};

struct GraphicsLoad {
    Library12* library = nullptr;
    std::string_view name;
};

struct NullSpan {
    shader::ResourceKind kind = shader::ResourceKind::kBuffer;
    UINT start = 0;
    UINT count = 0;
    bool sampler = false;
};

struct NullQuery {
    const shader::Resource* resource = nullptr;
    bool samplers = false;
};

struct CountQuery {
    const shader::Resource* resource = nullptr;
    bool samplers = false;
    const Caps* caps = nullptr;
};

struct IndexQuery {
    const shader::Resource* wanted = nullptr;
    UINT element = 0;
    bool samplers = false;
    const Caps* caps = nullptr;
};

struct IndexWalk {
    UINT cursor = 0;
    bool is_found = false;
};

struct UniformSpan {
    const Buffer* buffer = nullptr;
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
};

struct RawSpan {
    ID3D12Resource* resource = nullptr;
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
    bool is_uav = false;
};

struct StructuredSpan {
    ID3D12Resource* resource = nullptr;
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
    std::uint32_t stride = 0;
    bool is_uav = false;
};

struct SlotWrite {
    const Group* group = nullptr;
    const SpaceLayout* space = nullptr;
    const shader::Resource* resource = nullptr;
    UINT element = 0;
};

struct StorageWrite {
    const shader::Resource* resource = nullptr;
    ID3D12Resource* buffer = nullptr;
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
    bool is_uav = false;
    CpuHandle cpu{};
};

struct GroupNeed {
    UINT resources = 0;
    UINT samplers = 0;
};

struct StreamRequest {
    const GraphicsDesc* info = nullptr;
    const DepthState* depth = nullptr;
    const ShaderSlots* slots = nullptr;
};

struct GraphicsReady {
    GraphicsDesc info{};
    ShaderSlots slots{};
    const Layout* layout = nullptr;
    Elements elements;
    Pipeline pipeline;
    // SemanticName của input layout trỏ vào chuỗi của gathered. gathered phải sống tới khi tạo PSO.
    Gathered gathered;
};

enum class HeldMatch : std::uint8_t { kSkip, kSame, kClash };

template <class Value>
[[nodiscard]] auto unexpected_error(const Value& status) {
    const auto& error = status.error();
    return std::unexpected(error);
}

// .at() trên chỉ số space nội bộ (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
[[nodiscard]] bool is_same_layout(const ProgramLayout& left, const ProgramLayout& right) noexcept {
    if (left.push_bytes != right.push_bytes) return false;
    if (left.stages != right.stages) return false;
    if (left.push_stages != right.push_stages) return false;
    bool differs = false;
    // Khác gốc: dừng khi băm space lệch, cùng phép so (PH-01).
    for (std::uint32_t space = 0; space < kMaxBindGroups && !differs; ++space) {
        const std::uint64_t left_hash = left.spaces.at(space).hash;
        const std::uint64_t right_hash = right.spaces.at(space).hash;
        differs = left_hash != right_hash;
    }
    return !differs;
}

[[nodiscard]] D3D12_ROOT_SIGNATURE_FLAGS deny_flags(shader::StageSet stages) noexcept {
    auto flags = D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;
    flags |= D3D12_ROOT_SIGNATURE_FLAG_DENY_MESH_SHADER_ROOT_ACCESS;
    flags |= D3D12_ROOT_SIGNATURE_FLAG_DENY_AMPLIFICATION_SHADER_ROOT_ACCESS;
    if (!stages.has(shader::Stage::kVertex)) {
        flags |= D3D12_ROOT_SIGNATURE_FLAG_DENY_VERTEX_SHADER_ROOT_ACCESS;
    }
    if (!stages.has(shader::Stage::kHull)) {
        flags |= D3D12_ROOT_SIGNATURE_FLAG_DENY_HULL_SHADER_ROOT_ACCESS;
    }
    if (!stages.has(shader::Stage::kDomain)) {
        flags |= D3D12_ROOT_SIGNATURE_FLAG_DENY_DOMAIN_SHADER_ROOT_ACCESS;
    }
    if (!stages.has(shader::Stage::kGeometry)) {
        flags |= D3D12_ROOT_SIGNATURE_FLAG_DENY_GEOMETRY_SHADER_ROOT_ACCESS;
    }
    if (!stages.has(shader::Stage::kPixel)) {
        flags |= D3D12_ROOT_SIGNATURE_FLAG_DENY_PIXEL_SHADER_ROOT_ACCESS;
    }
    return flags;
}

[[nodiscard]] UINT descriptor_count(const shader::Resource& resource, const Caps& caps) noexcept {
    if (resource.count != 0) return resource.count;
    if (resource.kind == shader::ResourceKind::kSampler) return caps.max_unbounded_samplers;
    return caps.max_unbounded;
}

[[nodiscard]] Status accept_kind(shader::ResourceKind kind) {
    switch (kind) {
    case shader::ResourceKind::kSampler:
    case shader::ResourceKind::kTexture:
    case shader::ResourceKind::kRwTexture:
    case shader::ResourceKind::kBuffer:
    case shader::ResourceKind::kRwBuffer:
    case shader::ResourceKind::kTexelBuffer:
    case shader::ResourceKind::kRwTexelBuffer:
    case shader::ResourceKind::kUniformBuffer: return ok();
    case shader::ResourceKind::kPushConstant:
    case shader::ResourceKind::kAccelerationStructure:
    case shader::ResourceKind::kInputAttachment:
        return fail(ErrorCode::kUnsupported, "loại tài nguyên này chưa có trên D3D12");
    }
    return fail(ErrorCode::kUnsupported, "loại tài nguyên này chưa có trên D3D12");
}

[[nodiscard]] D3D12_DESCRIPTOR_RANGE_TYPE range_type(shader::ResourceKind kind) noexcept {
    switch (kind) {
    case shader::ResourceKind::kSampler: return D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
    case shader::ResourceKind::kTexture:
    case shader::ResourceKind::kBuffer:
    case shader::ResourceKind::kTexelBuffer: return D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
    case shader::ResourceKind::kRwTexture:
    case shader::ResourceKind::kRwBuffer:
    case shader::ResourceKind::kRwTexelBuffer: return D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
    case shader::ResourceKind::kUniformBuffer: return D3D12_DESCRIPTOR_RANGE_TYPE_CBV;
    case shader::ResourceKind::kPushConstant:
    case shader::ResourceKind::kAccelerationStructure:
    case shader::ResourceKind::kInputAttachment: return D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
    }
    return D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
}

[[nodiscard]] bool skips_kind(const shader::Resource& resource, bool samplers) noexcept {
    const bool is_sampler = resource.kind == shader::ResourceKind::kSampler;
    return is_sampler != samplers;
}

void add_stage(shader::StageSet& stages, const shader::Resource& resource, bool samplers) noexcept {
    if (skips_kind(resource, samplers)) return;
    stages.add(resource.stages);
}

[[nodiscard]] shader::StageSet table_stages(const SpaceLayout& space, bool samplers) noexcept {
    shader::StageSet stages;
    // Khác gốc: lọc sampler trong add_stage (PH-01).
    for (const shader::Resource& resource : space.resources) {
        add_stage(stages, resource, samplers);
    }
    return stages;
}

[[nodiscard]] Status add_range(TableBuild& out, const shader::Resource& binding, const Caps& caps) {
    const Status accepted = accept_kind(binding.kind);
    if (!accepted) return accepted;
    if (binding.count == 0 && !caps.bindless) {
        return fail(ErrorCode::kUnsupported, "thiết bị không có bindless");
    }
    const UINT count = descriptor_count(binding, caps);
    if (count == 0) return fail(ErrorCode::kUnsupported, "thiết bị không có bindless");
    D3D12_DESCRIPTOR_RANGE1 range{};
    range.RangeType = range_type(binding.kind);
    range.NumDescriptors = count;
    range.BaseShaderRegister = binding.slot;
    range.RegisterSpace = binding.space;
    range.OffsetInDescriptorsFromTableStart = D3D12_DESCRIPTOR_RANGE_OFFSET_APPEND;
    range.Flags = D3D12_DESCRIPTOR_RANGE_FLAG_NONE;
    if (binding.count == 0) range.Flags = D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE;
    out.ranges.push_back(range);
    out.count += count;
    return ok();
}

[[nodiscard]] Status add_matching(TableBuild& table, const KindMatch& match) {
    if (skips_kind(*match.resource, match.samplers)) return ok();
    return add_range(table, *match.resource, *match.caps);
}

[[nodiscard]] Status fill_table(TableBuild& table, const TableRequest& request) {
    const SpaceLayout& space = *request.space;
    const shader::StageSet stages = table_stages(space, request.samplers);
    table.visibility = to_visibility(stages);
    Status added = ok();
    const auto end = space.resources.end();
    // Khác gốc: dừng ở range lỗi đầu, cùng thứ tự add_range (PH-01).
    for (auto resource = space.resources.begin(); resource != end && added; ++resource) {
        KindMatch match;
        match.resource = &*resource;
        match.samplers = request.samplers;
        match.caps = request.caps;
        added = add_matching(table, match);
    }
    return added;
}

[[nodiscard]] Status add_space(const SpaceAdd& add) {
    const SpaceLayout& space = *add.space;
    if (space.resources.empty()) return ok();
    Layout& layout = *add.layout;
    layout.used |= 1U << add.index;
    TableBuild resources;
    resources.space = add.index;
    TableRequest resources_request;
    resources_request.space = &space;
    resources_request.samplers = false;
    resources_request.caps = add.caps;
    const Status filled = fill_table(resources, resources_request);
    if (!filled) return filled;
    TableBuild samplers;
    samplers.space = add.index;
    samplers.is_sampler = true;
    TableRequest sampler_request;
    sampler_request.space = &space;
    sampler_request.samplers = true;
    sampler_request.caps = add.caps;
    const Status filled_samplers = fill_table(samplers, sampler_request);
    if (!filled_samplers) return filled_samplers;
    if (!resources.ranges.empty()) add.tables->push_back(std::move(resources));
    if (!samplers.ranges.empty()) add.tables->push_back(std::move(samplers));
    return ok();
}

void bind_tables(Layout& layout, const Tables& tables, RootParameters& parameters) {
    for (std::size_t index = 0; index < tables.size(); ++index) {
        const TableBuild& table = tables.at(index);
        D3D12_ROOT_PARAMETER1& parameter = parameters.at(index);
        parameter.ParameterType = D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
        parameter.DescriptorTable.NumDescriptorRanges = static_cast<UINT>(table.ranges.size());
        parameter.DescriptorTable.pDescriptorRanges = table.ranges.data();
        parameter.ShaderVisibility = table.visibility;
        TableRef& ref = table.is_sampler ? layout.samplers.at(table.space) : layout.resources.at(table.space);
        ref.root = static_cast<UINT>(index);
        ref.count = table.count;
    }
}

[[nodiscard]] Status take_shader(ConstDevice& device, ShaderHandle handle, const ShaderTake& out) {
    const Shader* const shader = device.find(handle);
    if (shader == nullptr) return fail(kBad, "pipeline: shader đã chết");
    const shader::Stage stage = shader->reflection.stage;
    const bool is_blocked =
        stage == shader::Stage::kMesh || stage == shader::Stage::kAmplification || stage == shader::Stage::kLibrary;
    if (is_blocked) return fail(ErrorCode::kUnsupported, "mesh và ray tracing chưa có");
    const auto index = std::to_underlying(stage);
    if (out.stages->at(index) != nullptr) return fail(kBad, "pipeline: một stage có hai shader");
    out.stages->at(index) = shader;
    out.reflections->push_back(shader->reflection);
    return ok();
}

[[nodiscard]] Result<Gathered> gather(const D3d12Device& device, ShaderList handles) {
    Gathered gathered;
    Reflections reflections;
    reflections.reserve(handles.size());
    ShaderTake taken;
    taken.stages = &gathered.stages;
    taken.reflections = &reflections;
    Status status = ok();
    const auto end = handles.end();
    // Khác gốc: dừng ở shader lỗi đầu, cùng thứ tự take_shader (PH-01).
    for (auto handle = handles.begin(); handle != end && status; ++handle) {
        status = take_shader(device, *handle, taken);
    }
    if (!status) return unexpected_error(status);
    Result<Program> program = make_program(reflections);
    if (!program) return unexpected_error(program);
    gathered.program = std::move(*program);
    return gathered;
}

[[nodiscard]] D3D12_SHADER_BYTECODE bytecode(const Shader& shader) noexcept {
    D3D12_SHADER_BYTECODE code{};
    code.pShaderBytecode = shader.code.data();
    code.BytecodeLength = shader.code.size();
    return code;
}

void assign_stage(D3D12_SHADER_BYTECODE& slot, const Shader* shader) noexcept {
    if (shader == nullptr) return;
    slot = bytecode(*shader);
}

// .at() trên chỉ số stage nội bộ (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
[[nodiscard]] ShaderSlots shader_slots(const Gathered& gathered) noexcept {
    ShaderSlots slots;
    const auto& stages = gathered.stages;
    const auto vertex = std::to_underlying(shader::Stage::kVertex);
    const auto hull = std::to_underlying(shader::Stage::kHull);
    const auto domain = std::to_underlying(shader::Stage::kDomain);
    const auto geometry = std::to_underlying(shader::Stage::kGeometry);
    const auto pixel = std::to_underlying(shader::Stage::kPixel);
    slots.vertex = stages.at(vertex);
    slots.hull = stages.at(hull);
    slots.domain = stages.at(domain);
    slots.geometry = stages.at(geometry);
    slots.pixel = stages.at(pixel);
    return slots;
}

[[nodiscard]] D3D12_RENDER_TARGET_BLEND_DESC blend_desc(const BlendState& state) noexcept {
    D3D12_RENDER_TARGET_BLEND_DESC desc{};
    desc.BlendEnable = state.is_enabled ? TRUE : FALSE;
    desc.SrcBlend = to_dxgi(state.src_color);
    desc.DestBlend = to_dxgi(state.dst_color);
    desc.BlendOp = to_dxgi(state.color_op);
    desc.SrcBlendAlpha = to_dxgi(state.src_alpha);
    desc.DestBlendAlpha = to_dxgi(state.dst_alpha);
    desc.BlendOpAlpha = to_dxgi(state.alpha_op);
    desc.RenderTargetWriteMask = state.write_mask;
    return desc;
}

[[nodiscard]] BlendState blend_at(std::span<const BlendState> blends, std::size_t index) noexcept {
    if (blends.empty()) return {};
    if (blends.size() == 1) return blends.front();
    const auto slice = blends.subspan(index, 1);
    return slice.front();
}

[[nodiscard]] D3D12_DEPTH_STENCILOP_DESC face_of(const StencilFace& face) noexcept {
    D3D12_DEPTH_STENCILOP_DESC desc{};
    desc.StencilFailOp = to_dxgi(face.fail);
    desc.StencilDepthFailOp = to_dxgi(face.depth_fail);
    desc.StencilPassOp = to_dxgi(face.pass);
    desc.StencilFunc = to_dxgi(face.compare);
    return desc;
}

[[nodiscard]] D3D12_DEPTH_STENCIL_DESC depth_desc(const DepthState& state) noexcept {
    D3D12_DEPTH_STENCIL_DESC desc{};
    desc.DepthEnable = state.is_tested ? TRUE : FALSE;
    desc.DepthWriteMask = state.is_written ? D3D12_DEPTH_WRITE_MASK_ALL : D3D12_DEPTH_WRITE_MASK_ZERO;
    desc.DepthFunc = to_dxgi(state.compare);
    desc.StencilEnable = state.is_stencil_tested ? TRUE : FALSE;
    desc.StencilReadMask = state.stencil_read_mask;
    desc.StencilWriteMask = state.stencil_write_mask;
    desc.FrontFace = face_of(state.front);
    desc.BackFace = face_of(state.back);
    return desc;
}

[[nodiscard]] D3D12_DEPTH_STENCIL_DESC1 depth_bounds(const DepthState& state) noexcept {
    const D3D12_DEPTH_STENCIL_DESC base = depth_desc(state);
    D3D12_DEPTH_STENCIL_DESC1 desc{};
    desc.DepthEnable = base.DepthEnable;
    desc.DepthWriteMask = base.DepthWriteMask;
    desc.DepthFunc = base.DepthFunc;
    desc.StencilEnable = base.StencilEnable;
    desc.StencilReadMask = base.StencilReadMask;
    desc.StencilWriteMask = base.StencilWriteMask;
    desc.FrontFace = base.FrontFace;
    desc.BackFace = base.BackFace;
    desc.DepthBoundsTestEnable = state.is_bounds_tested ? TRUE : FALSE;
    return desc;
}

[[nodiscard]] D3D12_RASTERIZER_DESC raster_desc(const RasterState& state) noexcept {
    D3D12_RASTERIZER_DESC desc{};
    desc.FillMode = to_dxgi(state.fill);
    desc.CullMode = to_dxgi(state.cull);
    desc.FrontCounterClockwise = state.front_face == FrontFace::kCounterClockwise ? TRUE : FALSE;
    desc.DepthBias = static_cast<INT>(state.depth_bias);
    desc.DepthBiasClamp = state.depth_bias_clamp;
    desc.SlopeScaledDepthBias = state.depth_bias_slope;
    desc.DepthClipEnable = state.is_depth_clipped ? TRUE : FALSE;
    desc.MultisampleEnable = TRUE;
    desc.ConservativeRaster =
        state.is_conservative ? D3D12_CONSERVATIVE_RASTERIZATION_MODE_ON : D3D12_CONSERVATIVE_RASTERIZATION_MODE_OFF;
    return desc;
}

[[nodiscard]] D3D12_PRIMITIVE_TOPOLOGY ia_topology(const PipelineDesc& desc) noexcept {
    if (desc.topology != Topology::kPatchList) return to_topology(desc.topology);
    const auto base = static_cast<int>(D3D_PRIMITIVE_TOPOLOGY_1_CONTROL_POINT_PATCHLIST);
    const auto points = static_cast<int>(desc.patch_points);
    return static_cast<D3D12_PRIMITIVE_TOPOLOGY>(base + points - 1);
}

void copy_strides(Pipeline& pipeline, std::span<const VertexBufferLayout> buffers) noexcept {
    const auto buffer_count = buffers.size();
    const auto stride_count = pipeline.strides.size();
    const auto count = std::min(buffer_count, stride_count);
    const auto strides = buffers.first(count) | std::views::transform(&VertexBufferLayout::stride);
    const auto begin = pipeline.strides.begin();
    std::ranges::copy(strides, begin);
}

[[nodiscard]] Status add_element(Elements& elements, const AttributeRef& input) {
    const PipelineDesc& desc = *input.desc;
    const Program& program = *input.program;
    const VertexAttribute& attribute = *input.attribute;
    const shader::Attribute* const found = find_input(program.reflection, attribute.location);
    if (found == nullptr) return fail(kBad, "pipeline: shader không có location này");
    if (attribute.buffer >= desc.vertex_buffers.size()) {
        return fail(kBad, "pipeline: khe đỉnh vượt biên");
    }
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
    const VertexBufferLayout& buffer = desc.vertex_buffers[attribute.buffer];
    D3D12_INPUT_ELEMENT_DESC element{};
    element.SemanticName = found->semantic.c_str();
    element.SemanticIndex = found->index;
    element.Format = to_dxgi(attribute.format);
    element.InputSlot = attribute.buffer;
    element.AlignedByteOffset = attribute.offset;
    const bool per_instance = buffer.is_per_instance;
    element.InputSlotClass =
        per_instance ? D3D12_INPUT_CLASSIFICATION_PER_INSTANCE_DATA : D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA;
    element.InstanceDataStepRate = per_instance ? 1U : 0U;
    elements.push_back(element);
    return ok();
}

[[nodiscard]] Status fill_elements(Elements& elements, const ElementSource& source) {
    Status added = ok();
    const auto end = source.desc->vertex_attributes.end();
    // Khác gốc: dừng ở attribute lỗi đầu, cùng thứ tự add_element (PH-01).
    for (auto attribute = source.desc->vertex_attributes.begin(); attribute != end && added; ++attribute) {
        const VertexAttribute& item = *attribute;
        AttributeRef input;
        input.desc = source.desc;
        input.program = source.program;
        input.attribute = &item;
        added = add_element(elements, input);
    }
    return added;
}

void fill_targets(GraphicsDesc& info, const PipelineDesc& desc) {
    info.NumRenderTargets = static_cast<UINT>(desc.color_formats.size());
    for (std::size_t index = 0; index < desc.color_formats.size(); ++index) {
        // RTVFormats là mảng 8 ô cố định của struct D3D12; vòng chạy đúng
        // color_formats.size().
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index,cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
        info.RTVFormats[index] = to_dxgi(desc.color_formats[index]);
        const BlendState blend = blend_at(desc.blends, index);
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
        info.BlendState.RenderTarget[index] = blend_desc(blend);
    }
    if (desc.color_formats.empty()) info.BlendState.RenderTarget[0] = blend_desc({});
    info.BlendState.AlphaToCoverageEnable = desc.is_alpha_to_coverage ? TRUE : FALSE;
    info.BlendState.IndependentBlendEnable = desc.blends.size() > 1 ? TRUE : FALSE;
}

void fill_graphics(GraphicsDesc& info, const GraphicsFill& fill) {
    const PipelineDesc& desc = *fill.desc;
    const Layout& layout = *fill.layout;
    const ShaderSlots& slots = *fill.slots;
    const Elements& elements = *fill.elements;
    info.pRootSignature = layout.signature.Get();
    assign_stage(info.VS, slots.vertex);
    assign_stage(info.PS, slots.pixel);
    assign_stage(info.HS, slots.hull);
    assign_stage(info.DS, slots.domain);
    assign_stage(info.GS, slots.geometry);
    info.InputLayout.pInputElementDescs = elements.empty() ? nullptr : elements.data();
    info.InputLayout.NumElements = static_cast<UINT>(elements.size());
    info.PrimitiveTopologyType = to_topology_type(desc.topology);
    info.RasterizerState = raster_desc(desc.raster);
    info.DepthStencilState = depth_desc(desc.depth);
    fill_targets(info, desc);
    info.SampleMask = 0xFFFFFFFF;
    info.SampleDesc.Count = std::max(desc.samples, 1U);
    info.DSVFormat = DXGI_FORMAT_UNKNOWN;
    if (desc.depth.format != Format::kUnknown) info.DSVFormat = to_dxgi(desc.depth.format);
    static_cast<void>(fill.gathered);
}

template <D3D12_PIPELINE_STATE_SUBOBJECT_TYPE Type, class Payload>
void append_item(Bytes& out, const Payload& value) {
    using Item = StreamItem<Type, Payload>;
    const std::size_t align = alignof(Item);
    const std::size_t base = (out.size() + align - 1) & ~(align - 1);
    out.resize(base);
    Item item{};
    item.value = value;
    // Xếp item POD vào luồng byte: đọc bộ nhớ của chính nó (UB-03).
    // NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast,cppcoreguidelines-pro-bounds-pointer-arithmetic)
    const auto* bytes = reinterpret_cast<const std::byte*>(&item);
    const auto end = out.end();
    out.insert(end, bytes, bytes + sizeof(Item));
    // NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast,cppcoreguidelines-pro-bounds-pointer-arithmetic)
}

void append_formats(Bytes& out, const GraphicsDesc& info) {
    D3D12_RT_FORMAT_ARRAY targets{};
    targets.NumRenderTargets = info.NumRenderTargets;
    // NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index): hai mảng cố định của
    // struct D3D12, cùng chạy tới NumRenderTargets.
    for (UINT index = 0; index < info.NumRenderTargets; ++index) {
        targets.RTFormats[index] = info.RTVFormats[index];
    }
    // NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RENDER_TARGET_FORMATS>(out, targets);
}

[[nodiscard]] Bytes bounds_stream(const GraphicsDesc& info, const StreamParts& parts) {
    const D3D12_DEPTH_STENCIL_DESC1& depth = *parts.depth;
    const ShaderSlots& slots = *parts.slots;
    Bytes out;
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_ROOT_SIGNATURE>(out, info.pRootSignature);
    if (slots.vertex != nullptr) {
        append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_VS>(out, info.VS);
    }
    if (slots.pixel != nullptr) {
        append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PS>(out, info.PS);
    }
    if (slots.domain != nullptr) {
        append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DS>(out, info.DS);
    }
    if (slots.hull != nullptr) {
        append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_HS>(out, info.HS);
    }
    if (slots.geometry != nullptr) {
        append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_GS>(out, info.GS);
    }
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_BLEND>(out, info.BlendState);
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SAMPLE_MASK>(out, info.SampleMask);
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_RASTERIZER>(out, info.RasterizerState);
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL1>(out, depth);
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_INPUT_LAYOUT>(out, info.InputLayout);
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_PRIMITIVE_TOPOLOGY>(out, info.PrimitiveTopologyType);
    append_formats(out, info);
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_DEPTH_STENCIL_FORMAT>(out, info.DSVFormat);
    append_item<D3D12_PIPELINE_STATE_SUBOBJECT_TYPE_SAMPLE_DESC>(out, info.SampleDesc);
    return out;
}

[[nodiscard]] bool load_graphics(GraphicsLoad load, const GraphicsDesc& desc, State12& state) {
    if (load.library == nullptr || load.name.empty()) return false;
    const std::wstring wide = core::widen(load.name);
    const HRESULT loaded = load.library->LoadGraphicsPipeline(wide.c_str(), &desc, IID_PPV_ARGS(&state));
    return SUCCEEDED(loaded);
}

[[nodiscard]] bool load_compute(GraphicsLoad load, const ComputeDesc& desc, State12& state) {
    if (load.library == nullptr || load.name.empty()) return false;
    const std::wstring wide = core::widen(load.name);
    const HRESULT loaded = load.library->LoadComputePipeline(wide.c_str(), &desc, IID_PPV_ARGS(&state));
    return SUCCEEDED(loaded);
}

void store_named(Library12* library, std::string_view name, ID3D12PipelineState* state) {
    if (library == nullptr || state == nullptr || name.empty()) return;
    const std::wstring wide = core::widen(name);
    std::ignore = library->StorePipeline(wide.c_str(), state);
}

void null_cbv(Device12* device, CpuHandle cpu) noexcept {
    const D3D12_CONSTANT_BUFFER_VIEW_DESC desc{};
    device->CreateConstantBufferView(&desc, cpu);
}

void null_srv_texture(Device12* device, CpuHandle cpu) noexcept {
    D3D12_SHADER_RESOURCE_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    desc.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
    desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
    desc.Texture2D.MipLevels = 1;
    device->CreateShaderResourceView(nullptr, &desc, cpu);
}

void null_srv_buffer(Device12* device, CpuHandle cpu) noexcept {
    D3D12_SHADER_RESOURCE_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_R32_TYPELESS;
    desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
    desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
    desc.Buffer.NumElements = 1;
    desc.Buffer.Flags = D3D12_BUFFER_SRV_FLAG_RAW;
    device->CreateShaderResourceView(nullptr, &desc, cpu);
}

void null_uav_texture(Device12* device, CpuHandle cpu) noexcept {
    D3D12_UNORDERED_ACCESS_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    desc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
    device->CreateUnorderedAccessView(nullptr, nullptr, &desc, cpu);
}

void null_uav_buffer(Device12* device, CpuHandle cpu) noexcept {
    D3D12_UNORDERED_ACCESS_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_R32_TYPELESS;
    desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
    desc.Buffer.NumElements = 1;
    desc.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_RAW;
    device->CreateUnorderedAccessView(nullptr, nullptr, &desc, cpu);
}

void null_sampler(Device12* device, CpuHandle cpu) noexcept {
    D3D12_SAMPLER_DESC desc{};
    desc.Filter = D3D12_FILTER_MIN_MAG_MIP_POINT;
    desc.AddressU = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
    desc.AddressV = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
    desc.AddressW = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
    desc.ComparisonFunc = D3D12_COMPARISON_FUNC_NEVER;
    device->CreateSampler(&desc, cpu);
}

void null_one(Device12* device, shader::ResourceKind kind, CpuHandle cpu) noexcept {
    switch (kind) {
    case shader::ResourceKind::kUniformBuffer: null_cbv(device, cpu); return;
    case shader::ResourceKind::kTexture: null_srv_texture(device, cpu); return;
    case shader::ResourceKind::kBuffer:
    case shader::ResourceKind::kTexelBuffer: null_srv_buffer(device, cpu); return;
    case shader::ResourceKind::kRwTexture: null_uav_texture(device, cpu); return;
    case shader::ResourceKind::kRwBuffer:
    case shader::ResourceKind::kRwTexelBuffer: null_uav_buffer(device, cpu); return;
    case shader::ResourceKind::kSampler: null_sampler(device, cpu); return;
    case shader::ResourceKind::kPushConstant:
    case shader::ResourceKind::kAccelerationStructure:
    case shader::ResourceKind::kInputAttachment: return;
    }
}

[[nodiscard]] CpuHandle cpu_at(ConstDevice& device, UINT slot, bool sampler) noexcept {
    if (sampler) return device.sampler_cpu(slot);
    return device.resource_cpu(slot);
}

void null_span(ConstDevice& device, NullSpan span) {
    for (UINT index = 0; index < span.count; ++index) {
        Device12* const hardware = device.device();
        const CpuHandle cpu = cpu_at(device, span.start + index, span.sampler);
        null_one(hardware, span.kind, cpu);
    }
}

void null_resource(ConstDevice& device, const NullQuery& query, UINT& cursor) {
    if (skips_kind(*query.resource, query.samplers)) return;
    const Caps& caps = device.caps();
    const UINT count = descriptor_count(*query.resource, caps);
    NullSpan span;
    span.kind = query.resource->kind;
    span.start = cursor;
    span.count = count;
    span.sampler = query.samplers;
    null_span(device, span);
    cursor += count;
}

void null_table(ConstDevice& device, const SpaceLayout& space, UINT start, bool samplers) {
    UINT cursor = start;
    // Khác gốc: lọc sampler trong null_resource (PH-01).
    for (const shader::Resource& resource : space.resources) {
        NullQuery query;
        query.resource = &resource;
        query.samplers = samplers;
        null_resource(device, query, cursor);
    }
}

void add_count(UINT& total, const CountQuery& query) noexcept {
    if (skips_kind(*query.resource, query.samplers)) return;
    total += descriptor_count(*query.resource, *query.caps);
}

[[nodiscard]] UINT table_count(const SpaceLayout& space, bool samplers, const Caps& caps) noexcept {
    UINT total = 0;
    // Khác gốc: lọc sampler trong add_count (PH-01).
    for (const shader::Resource& resource : space.resources) {
        CountQuery query;
        query.resource = &resource;
        query.samplers = samplers;
        query.caps = &caps;
        add_count(total, query);
    }
    return total;
}

void on_index(IndexWalk& walk, const shader::Resource& item, const IndexQuery& query) noexcept {
    if (skips_kind(item, query.samplers)) return;
    const shader::Resource& wanted = *query.wanted;
    const bool is_wanted = item.slot == wanted.slot && item.kind == wanted.kind;
    if (!is_wanted) {
        walk.cursor += descriptor_count(item, *query.caps);
        return;
    }
    walk.cursor += query.element;
    walk.is_found = true;
}

[[nodiscard]] UINT table_index(const SpaceLayout& space, const IndexQuery& query) noexcept {
    IndexWalk walk;
    const auto end = space.resources.end();
    // Khác gốc: dừng khi gặp chỗ gắn, cùng thứ tự cộng descriptor (PH-01).
    for (auto resource = space.resources.begin(); resource != end && !walk.is_found; ++resource) {
        on_index(walk, *resource, query);
    }
    if (walk.is_found) return walk.cursor;
    return walk.cursor + query.element;
}

[[nodiscard]] Status write_uniform(Device12* device, const UniformSpan& span, CpuHandle cpu) {
    if (span.size > kCbufferMax) return fail(kBad, "nhóm gắn: cbuffer vượt 64 KiB");
    D3D12_CONSTANT_BUFFER_VIEW_DESC desc{};
    desc.BufferLocation = span.buffer->gpu_address + span.offset;
    // D3D12 đòi cỡ CBV là bội của 256 dù cbuffer của shader nhỏ hơn. BufferRange bảo phần làm tròn
    // vẫn nằm trong buffer.
    constexpr UINT kCbvAlignment = D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT;
    const UINT bytes = static_cast<UINT>(span.size);
    desc.SizeInBytes = (bytes + kCbvAlignment - 1) / kCbvAlignment * kCbvAlignment;
    device->CreateConstantBufferView(&desc, cpu);
    return ok();
}

[[nodiscard]] Status write_raw(Device12* device, const RawSpan& span, CpuHandle cpu) {
    if (span.offset % 4 != 0 || span.size % 4 != 0) {
        return fail(kBad, "nhóm gắn: offset buffer không căn 4");
    }
    if (span.is_uav) {
        D3D12_UNORDERED_ACCESS_VIEW_DESC desc{};
        desc.Format = DXGI_FORMAT_R32_TYPELESS;
        desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
        desc.Buffer.FirstElement = span.offset / 4;
        desc.Buffer.NumElements = static_cast<UINT>(span.size / 4);
        desc.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_RAW;
        device->CreateUnorderedAccessView(span.resource, nullptr, &desc, cpu);
        return ok();
    }
    D3D12_SHADER_RESOURCE_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_R32_TYPELESS;
    desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
    desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
    desc.Buffer.FirstElement = span.offset / 4;
    desc.Buffer.NumElements = static_cast<UINT>(span.size / 4);
    desc.Buffer.Flags = D3D12_BUFFER_SRV_FLAG_RAW;
    device->CreateShaderResourceView(span.resource, &desc, cpu);
    return ok();
}

[[nodiscard]] Status write_structured(Device12* device, const StructuredSpan& span, CpuHandle cpu) {
    if (span.stride == 0) return fail(kBad, "nhóm gắn: buffer có cấu trúc thiếu stride");
    const bool is_uav_view = span.is_uav;
    if (is_uav_view) {
        D3D12_UNORDERED_ACCESS_VIEW_DESC desc{};
        desc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
        desc.Buffer.FirstElement = span.offset / span.stride;
        desc.Buffer.NumElements = static_cast<UINT>(span.size / span.stride);
        desc.Buffer.StructureByteStride = span.stride;
        device->CreateUnorderedAccessView(span.resource, nullptr, &desc, cpu);
        return ok();
    }
    D3D12_SHADER_RESOURCE_VIEW_DESC desc{};
    desc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
    desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
    desc.Format = DXGI_FORMAT_UNKNOWN;
    desc.Buffer.FirstElement = span.offset / span.stride;
    desc.Buffer.NumElements = static_cast<UINT>(span.size / span.stride);
    desc.Buffer.StructureByteStride = span.stride;
    device->CreateShaderResourceView(span.resource, &desc, cpu);
    return ok();
}

[[nodiscard]] Status write_storage(Device12* device, const StorageWrite& write) {
    const shader::Resource& resource = *write.resource;
    if (resource.stride != 0) {
        StructuredSpan span;
        span.resource = write.buffer;
        span.offset = write.offset;
        span.size = write.size;
        span.stride = resource.stride;
        span.is_uav = write.is_uav;
        return write_structured(device, span, write.cpu);
    }
    RawSpan span;
    span.resource = write.buffer;
    span.offset = write.offset;
    span.size = write.size;
    span.is_uav = write.is_uav;
    return write_raw(device, span, write.cpu);
}

[[nodiscard]] Status write_buffer(ConstDevice& device, const SlotWrite& slot, BufferRange range) {
    const shader::Resource& resource = *slot.resource;
    const Buffer* const buffer = device.find(range.buffer);
    if (buffer == nullptr) return fail(kBad, "nhóm gắn: buffer đã chết");
    const bool is_uniform = resource.kind == shader::ResourceKind::kUniformBuffer;
    const BufferUsage wanted = is_uniform ? BufferUsage::kUniform : BufferUsage::kStorage;
    if (!has(buffer->usage, wanted)) {
        return fail(kBad, "nhóm gắn: buffer thiếu Uniform hoặc Storage");
    }
    const Result<std::uint64_t> size = resolve_binding(*slot.space, resource, range, buffer->size);
    if (!size) return unexpected_error(size);
    const Caps& caps = device.caps();
    IndexQuery query;
    query.wanted = &resource;
    query.element = slot.element;
    query.samplers = false;
    query.caps = &caps;
    const UINT index = table_index(*slot.space, query);
    const CpuHandle cpu = device.resource_cpu(slot.group->resource_at + index);
    Device12* const hardware = device.device();
    if (is_uniform) {
        UniformSpan span;
        span.buffer = buffer;
        span.offset = range.offset;
        span.size = *size;
        return write_uniform(hardware, span, cpu);
    }
    const bool is_uav =
        resource.kind == shader::ResourceKind::kRwBuffer || resource.kind == shader::ResourceKind::kRwTexelBuffer;
    StorageWrite write;
    write.resource = &resource;
    write.buffer = buffer->resource.Get();
    write.offset = range.offset;
    write.size = *size;
    write.is_uav = is_uav;
    write.cpu = cpu;
    return write_storage(hardware, write);
}

[[nodiscard]] Status write_view(ConstDevice& device, SlotWrite slot, TextureViewHandle handle) {
    const shader::Resource& resource = *slot.resource;
    const View* const view = device.find(handle);
    if (view == nullptr) return fail(kBad, "nhóm gắn: view đã chết");
    const Texture* const texture = device.find(view->texture);
    if (texture == nullptr) return fail(kBad, "nhóm gắn: texture đã chết");
    const bool is_written = resource.kind == shader::ResourceKind::kRwTexture;
    const TextureUsage wanted = is_written ? TextureUsage::kStorage : TextureUsage::kSampled;
    if (!has(texture->desc.usage, wanted)) {
        return fail(kBad, "nhóm gắn: texture thiếu Sampled hoặc Storage");
    }
    const UINT source = is_written ? view->uav : view->srv;
    if (source == kNoDescriptor) return fail(kBad, "nhóm gắn: view không có descriptor đúng loại");
    const Caps& caps = device.caps();
    IndexQuery query;
    query.wanted = &resource;
    query.element = slot.element;
    query.samplers = false;
    query.caps = &caps;
    const UINT index = table_index(*slot.space, query);
    Device12* const hardware = device.device();
    const CpuHandle destination = device.resource_cpu(slot.group->resource_at + index);
    const CpuHandle source_cpu = device.staging_cpu(source);
    hardware->CopyDescriptorsSimple(1, destination, source_cpu, D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
    return ok();
}

[[nodiscard]] Status write_sampler(ConstDevice& device, SlotWrite slot, SamplerHandle handle) {
    const Sampler* const sampler = device.find(handle);
    if (sampler == nullptr) return fail(kBad, "nhóm gắn: sampler đã chết");
    const shader::Resource& resource = *slot.resource;
    const Caps& caps = device.caps();
    IndexQuery query;
    query.wanted = &resource;
    query.element = slot.element;
    query.samplers = true;
    query.caps = &caps;
    const UINT index = table_index(*slot.space, query);
    Device12* const hardware = device.device();
    const CpuHandle destination = device.sampler_cpu(slot.group->sampler_at + index);
    const CpuHandle source_cpu = device.sampler_staging_cpu(sampler->index);
    hardware->CopyDescriptorsSimple(1, destination, source_cpu, D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);
    return ok();
}

[[nodiscard]] Status write_entry(ConstDevice& device, const Group& group, const BindEntry& entry) {
    const SpaceLayout& space = group.layout->program.spaces.at(group.space);
    const shader::Resource* const resource = find_resource(space, entry.type, entry.slot);
    if (resource == nullptr) return fail(kBad, "nhóm gắn: chỗ gắn không có");
    SlotWrite slot;
    slot.group = &group;
    slot.space = &space;
    slot.resource = resource;
    slot.element = entry.element;
    if (const auto* range = std::get_if<BufferRange>(&entry.resource)) {
        return write_buffer(device, slot, *range);
    }
    if (const auto* view = std::get_if<TextureViewHandle>(&entry.resource)) {
        return write_view(device, slot, *view);
    }
    if (const auto* sampler = std::get_if<SamplerHandle>(&entry.resource)) {
        return write_sampler(device, slot, *sampler);
    }
    return fail(kBad, "nhóm gắn: kiểu tài nguyên lạ");
}

[[nodiscard]] Status take_resources(D3d12Device& device, Group& group, UINT resources) {
    if (resources == 0) return ok();
    const std::optional<UINT> slot = device.allocate_resource(resources);
    if (!slot) return fail(ErrorCode::kExhausted, "hết descriptor tài nguyên");
    group.resource_at = *slot;
    group.resource_count = resources;
    return ok();
}

[[nodiscard]] Status take_samplers(D3d12Device& device, Group& group, UINT samplers) {
    if (samplers == 0) return ok();
    const std::optional<UINT> slot = device.allocate_sampler(samplers);
    if (!slot) return fail(ErrorCode::kExhausted, "hết descriptor sampler");
    group.sampler_at = *slot;
    group.sampler_count = samplers;
    return ok();
}

[[nodiscard]] Status take_group_slots(D3d12Device& device, Group& group, GroupNeed need) {
    // Khác gốc: allocate_resource tách take_resources (PH-01).
    const Status resources = take_resources(device, group, need.resources);
    if (!resources) return resources;
    return take_samplers(device, group, need.samplers);
}

void null_group(ConstDevice& device, const Group& group, const SpaceLayout& space) {
    if (group.resource_count != 0) null_table(device, space, group.resource_at, false);
    if (group.sampler_count != 0) null_table(device, space, group.sampler_at, true);
}

// is_same_layout dùng .at() nội bộ (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
[[nodiscard]] HeldMatch match_held(const Layout& held, const ProgramLayout& program) noexcept {
    if (held.program.hash != program.hash) return HeldMatch::kSkip;
    if (is_same_layout(held.program, program)) return HeldMatch::kSame;
    return HeldMatch::kClash;
}

[[nodiscard]] HRESULT open_stream(Device2* device, const StreamRequest& request, State12& state) {
    const D3D12_DEPTH_STENCIL_DESC1 bounds = depth_bounds(*request.depth);
    StreamParts parts;
    parts.depth = &bounds;
    parts.slots = request.slots;
    const Bytes stream = bounds_stream(*request.info, parts);
    D3D12_PIPELINE_STATE_STREAM_DESC streamed{};
    streamed.SizeInBytes = stream.size();
    // Struct của D3D12 nhận con trỏ không hằng dù chỉ đọc luồng.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-const-cast)
    streamed.pPipelineStateSubobjectStream = const_cast<std::byte*>(stream.data());
    return device->CreatePipelineState(&streamed, IID_PPV_ARGS(&state));
}

[[nodiscard]] Status emit_signature(D3d12Device& device, Layout& layout, const Tables& tables) {
    const bool has_push = layout.program.push_bytes != 0;
    const std::size_t count = tables.size() + (has_push ? 1U : 0U);
    RootParameters parameters(count);
    bind_tables(layout, tables, parameters);
    if (has_push) {
        D3D12_ROOT_PARAMETER1& parameter = parameters.back();
        parameter.ParameterType = D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
        parameter.Constants.ShaderRegister = 0;
        parameter.Constants.RegisterSpace = shader::kPushSpace;
        parameter.Constants.Num32BitValues = layout.program.push_bytes / 4;
        parameter.ShaderVisibility = to_visibility(layout.program.push_stages);
        const auto root_index = tables.size();
        layout.push_root = static_cast<UINT>(root_index);
    }
    D3D12_VERSIONED_ROOT_SIGNATURE_DESC versioned{};
    versioned.Version = D3D_ROOT_SIGNATURE_VERSION_1_1;
    const auto parameter_count = parameters.size();
    versioned.Desc_1_1.NumParameters = static_cast<UINT>(parameter_count);
    versioned.Desc_1_1.pParameters = parameters.empty() ? nullptr : parameters.data();
    versioned.Desc_1_1.Flags = deny_flags(layout.program.stages);
    ComPtr<ID3DBlob> blob;
    ComPtr<ID3DBlob> errors;
    const HRESULT serialized = D3D12SerializeVersionedRootSignature(&versioned, &blob, &errors);
    if (errors != nullptr) {
        const auto* text = static_cast<const char*>(errors->GetBufferPointer());
        core::warn("D3D12: {}", text);
    }
    if (FAILED(serialized)) return device.failed(serialized, "không tạo được root signature");
    Device12* const hardware = device.device();
    const void* const bytes = blob->GetBufferPointer();
    const auto bytes_size = blob->GetBufferSize();
    const HRESULT created = hardware->CreateRootSignature(0, bytes, bytes_size, IID_PPV_ARGS(&layout.signature));
    if (FAILED(created)) return device.failed(created, "không tạo được root signature");
    return ok();
}

[[nodiscard]] Result<GraphicsReady> ready_graphics(D3d12Device& device, const PipelineDesc& desc) {
    const Result<Gathered> gathered = gather(device, desc.shaders);
    if (!gathered) return unexpected_error(gathered);
    const Status checked = check_pipeline(desc, gathered->program, device.caps());
    if (!checked) return unexpected_error(checked);
    const Result<const Layout*> layout = device.layout_for(gathered->program.layout);
    if (!layout) return unexpected_error(layout);
    GraphicsReady ready;
    ready.gathered = std::move(*gathered);
    ElementSource source;
    source.desc = &desc;
    source.program = &ready.gathered.program;
    const Status input = fill_elements(ready.elements, source);
    if (!input) return unexpected_error(input);
    ready.slots = shader_slots(ready.gathered);
    const Gathered& gathered_ref = ready.gathered;
    GraphicsFill fill;
    fill.desc = &desc;
    fill.layout = *layout;
    fill.gathered = &gathered_ref;
    fill.slots = &ready.slots;
    fill.elements = &ready.elements;
    fill_graphics(ready.info, fill);
    ready.layout = *layout;
    ready.pipeline.layout = ready.layout;
    ready.pipeline.topology = ia_topology(desc);
    copy_strides(ready.pipeline, desc.vertex_buffers);
    return ready;
}

// Return của ready_graphics chuyển Gathered. Chuỗi semantic ngắn nằm trong SSO, con trỏ SemanticName
// hỏng sau lần chuyển ấy. Gắn lại khi GraphicsReady đã nằm yên trong Result, trước CreatePSO.
[[nodiscard]] Status rebind_elements(GraphicsReady& ready, const PipelineDesc& desc) {
    ElementSource source;
    source.desc = &desc;
    source.program = &ready.gathered.program;
    ready.elements.clear();
    const Status input = fill_elements(ready.elements, source);
    if (!input) return input;
    const Elements& elements = ready.elements;
    ready.info.InputLayout.pInputElementDescs = elements.empty() ? nullptr : elements.data();
    ready.info.InputLayout.NumElements = static_cast<UINT>(elements.size());
    return ok();
}

} // namespace

Result<const Layout*> D3d12Device::layout_for(const ProgramLayout& program) {
    const std::scoped_lock lock(layout_mutex_);
    const Layout* found = nullptr;
    bool clashes = false;
    const auto end = layouts_.end();
    // Khác gốc: nhánh trong vòng tách ra match_held, dừng khi trùng hoặc va (PH-01).
    for (auto held = layouts_.begin(); held != end && found == nullptr && !clashes; ++held) {
        const std::unique_ptr<Layout>& owned = *held;
        const HeldMatch match = match_held(*owned, program);
        found = match == HeldMatch::kSame ? owned.get() : found;
        clashes = match == HeldMatch::kClash;
    }
    if (clashes) return fail(ErrorCode::kInternal, "hai bố cục gắn khác nhau trùng băm");
    if (found != nullptr) return found;
    auto layout = std::make_unique<Layout>();
    layout->program = program;
    const Status filled = fill_signature(*layout);
    if (!filled) return unexpected_error(filled);
    const Layout* const result = layout.get();
    layouts_.push_back(std::move(layout));
    return result;
}

Status D3d12Device::fill_signature(Layout& layout) {
    Tables tables;
    Status added = ok();
    // Khác gốc: dừng ở space lỗi đầu, cùng thứ tự add_space (PH-01).
    for (std::uint32_t space = 0; space < kMaxBindGroups && added; ++space) {
        const SpaceLayout& slot = layout.program.spaces.at(space);
        SpaceAdd add;
        add.tables = &tables;
        add.layout = &layout;
        add.space = &slot;
        add.index = space;
        add.caps = &caps_;
        added = add_space(add);
    }
    if (!added) return added;
    return emit_signature(*this, layout, tables);
}

Result<ShaderHandle> D3d12Device::create_shader(const ShaderDesc& desc) {
    if (desc.variant == nullptr) return fail(kBad, "shader: thiếu bản dịch");
    if (desc.variant->target != shader::Target::kDxil) {
        return fail(kBad, "shader: D3D12 chỉ nhận DXIL");
    }
    if (desc.variant->code.empty()) return fail(kBad, "shader: mã DXIL rỗng");
    Shader shader;
    shader.code.assign(desc.variant->code.begin(), desc.variant->code.end());
    shader.reflection = desc.variant->reflection;
    const ShaderHandle handle = shaders_.insert(std::move(shader));
    if (handle) return handle;
    return fail(ErrorCode::kExhausted, "hết ô trong bảng shader");
}

Result<PipelineHandle> D3d12Device::create_pipeline(const PipelineDesc& desc) {
    Result<GraphicsReady> ready = ready_graphics(*this, desc);
    if (!ready) return unexpected_error(ready);
    GraphicsReady& built = *ready;
    const Status rebound = rebind_elements(built, desc);
    if (!rebound) return unexpected_error(rebound);
    const bool use_bounds = desc.depth.is_bounds_tested;
    HRESULT created = S_OK;
    if (use_bounds) {
        StreamRequest request;
        request.info = &built.info;
        request.depth = &desc.depth;
        request.slots = &built.slots;
        Device2* const hardware = device_.Get();
        // Khác gốc: nhánh bounds tách open_stream (PH-01).
        created = open_stream(hardware, request, built.pipeline.state);
    }
    if (use_bounds && FAILED(created)) return failed(created, "không tạo được pipeline đồ hoạ");
    if (use_bounds) return keep_pipeline(std::move(built.pipeline), desc.name);
    GraphicsLoad library;
    library.library = library_.Get();
    library.name = desc.name;
    if (load_graphics(library, built.info, built.pipeline.state)) {
        return keep_pipeline(std::move(built.pipeline), desc.name);
    }
    created = device_->CreateGraphicsPipelineState(&built.info, IID_PPV_ARGS(&built.pipeline.state));
    if (FAILED(created)) return failed(created, "không tạo được pipeline đồ hoạ");
    return keep_pipeline(std::move(built.pipeline), desc.name);
}

Result<PipelineHandle> D3d12Device::create_pipeline(const ComputePipelineDesc& desc) {
    const std::array<ShaderHandle, 1> shaders{desc.shader};
    const Result<Gathered> gathered = gather(*this, shaders);
    if (!gathered) return unexpected_error(gathered);
    const bool is_compute = gathered->program.reflection.stages.has(shader::Stage::kCompute);
    if (!is_compute) return fail(kBad, "pipeline compute cần shader stage Compute");
    const Result<const Layout*> layout = layout_for(gathered->program.layout);
    if (!layout) return unexpected_error(layout);
    const auto compute = std::to_underlying(shader::Stage::kCompute);
    const Shader* const shader = gathered->stages.at(compute);
    if (shader == nullptr) return fail(kBad, "pipeline compute cần shader stage Compute");
    ComputeDesc info{};
    info.pRootSignature = (*layout)->signature.Get();
    info.CS = bytecode(*shader);
    Pipeline pipeline;
    pipeline.layout = *layout;
    pipeline.is_compute = true;
    GraphicsLoad library;
    library.library = library_.Get();
    library.name = desc.name;
    if (load_compute(library, info, pipeline.state)) {
        return keep_pipeline(std::move(pipeline), desc.name);
    }
    const HRESULT created = device_->CreateComputePipelineState(&info, IID_PPV_ARGS(&pipeline.state));
    if (FAILED(created)) return failed(created, "không tạo được pipeline compute");
    return keep_pipeline(std::move(pipeline), desc.name);
}

Result<PipelineHandle> D3d12Device::keep_pipeline(Pipeline pipeline, std::string_view name) {
    set_name(pipeline.state.Get(), name);
    store_named(library_.Get(), name, pipeline.state.Get());
    const PipelineHandle handle = pipelines_.insert(std::move(pipeline));
    if (handle) return handle;
    return fail(ErrorCode::kExhausted, "hết ô trong bảng pipeline");
}

Result<BindGroupHandle> D3d12Device::create_bind_group(const BindGroupDesc& desc) {
    const Pipeline* const pipeline = pipelines_.find(desc.pipeline);
    if (pipeline == nullptr) return fail(kBad, "nhóm gắn: pipeline đã chết");
    if (desc.space >= kMaxBindGroups) return fail(kBad, "nhóm gắn: space vượt kMaxBindGroups");
    const SpaceLayout& space = pipeline->layout->program.spaces.at(desc.space);
    if (space.resources.empty()) return fail(kBad, "nhóm gắn: pipeline không dùng space này");
    const Status checked = check_entries(space, desc.entries, desc.capacity, true);
    if (!checked) return unexpected_error(checked);
    const Status sized = check_capacity(space, desc.capacity, caps_);
    if (!sized) return unexpected_error(sized);
    Group group;
    group.layout = pipeline->layout;
    group.space = desc.space;
    group.capacity = desc.capacity;
    const UINT resources = table_count(space, false, caps_);
    const UINT samplers = table_count(space, true, caps_);
    GroupNeed need;
    need.resources = resources;
    need.samplers = samplers;
    const Status slots = take_group_slots(*this, group, need);
    if (!slots) discard(group);
    if (!slots) return unexpected_error(slots);
    null_group(*this, group, space);
    const Status written = write_group(group, desc.entries);
    if (!written) discard(group);
    if (!written) return unexpected_error(written);
    const BindGroupHandle handle = groups_.insert(group);
    if (handle) return handle;
    discard(group);
    return fail(ErrorCode::kExhausted, "hết ô trong bảng nhóm gắn");
}

Status D3d12Device::update_bind_group(BindGroupHandle group, std::span<const BindEntry> entries) {
    const Group* const found = groups_.find(group);
    if (found == nullptr) return fail(kBad, "update_bind_group: nhóm đã chết");
    const SpaceLayout& space = found->layout->program.spaces.at(found->space);
    const Status checked = check_update(space, entries, found->capacity);
    if (!checked) return checked;
    return write_group(*found, entries);
}

// Chữ ký chốt ở header, không thêm const (API-06).
// NOLINTNEXTLINE(readability-make-member-function-const)
Status D3d12Device::write_group(const Group& group, std::span<const BindEntry> entries) {
    Status written = ok();
    const auto end = entries.end();
    // Khác gốc: dừng ở entry lỗi đầu, cùng thứ tự write_entry (PH-01).
    for (auto entry = entries.begin(); entry != end && written; ++entry) {
        written = write_entry(*this, group, *entry);
    }
    return written;
}

// NOLINTEND(cppcoreguidelines-pro-type-union-access,bugprone-invalid-enum-default-initialization)
} // namespace game::gpu::d3d12
