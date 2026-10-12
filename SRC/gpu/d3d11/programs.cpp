// Shader, pipeline và nhóm gắn của D3D11. DXBC vào Create*Shader; semantic của layout đỉnh lấy từ
// phản chiếu vertex shader. Khác gốc: trạng thái raster/depth/blend nằm trên pipeline, không cache
// toàn cục như bgfx.
#include "gpu/d3d11/device.hpp"

#include "core/error.hpp"
#include "gpu/binding.hpp"
#include "gpu/check.hpp"
#include "gpu/d3d11/binding_map.hpp"
#include "gpu/d3d11/convert.hpp"
#include "gpu/d3d11/hresult.hpp"
#include "gpu/device.hpp"
#include "gpu/handle.hpp"
#include "gpu/layout.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "shader/package.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <basetsd.h>
#include <combaseapi.h>
#include <d3d11.h>
#include <d3dcommon.h>
#include <dxgiformat.h>
#include <unknwn.h> // IWYU pragma: keep
#include <winerror.h>
#include <winnt.h>
#include <wrl/client.h>

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>

#if defined(__clang__)
// __uuidof trong IID_PPV_ARGS không có dạng chuẩn.
#pragma clang diagnostic ignored "-Wlanguage-extension-token"
#endif

// View D3D11 là union; enum của SDK không có giá trị 0 (UB-03, UB-06).
// NOLINTBEGIN(cppcoreguidelines-pro-type-union-access,bugprone-invalid-enum-default-initialization)

namespace game::gpu::d3d11 {

using core::ErrorCode;
using core::fail;
using core::ok;
using core::Result;
using core::Status;
using Microsoft::WRL::ComPtr;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kMissing = ErrorCode::kUnsupported;
constexpr ErrorCode kFull = ErrorCode::kExhausted;
constexpr ErrorCode kOutside = ErrorCode::kOutOfRange;

namespace {

using RasterDesc = D3D11_RASTERIZER_DESC;
using DepthDesc = D3D11_DEPTH_STENCIL_DESC;
using FaceDesc = D3D11_DEPTH_STENCILOP_DESC;
using BlendDesc = D3D11_BLEND_DESC;
using TargetBlend = D3D11_RENDER_TARGET_BLEND_DESC;
using Elements = std::vector<D3D11_INPUT_ELEMENT_DESC>;
using StageRef = shader::StageReflection;
using Attr = shader::Attribute;
using GfxDesc = GraphicsPipelineDesc;
using Child = ID3D11DeviceChild;
using shader::Stage;
using Srv = ComPtr<ID3D11ShaderResourceView>;
using Uav = ComPtr<ID3D11UnorderedAccessView>;
using Device = ID3D11Device;
using Linkage = ID3D11ClassLinkage;

struct Bytecode {
    const void* data = nullptr;
    std::size_t size = 0;
};

struct ShaderMake {
    D3d11Device* device = nullptr;
    Shader* shader = nullptr;
};

struct StagePack {
    std::array<const Shader*, shader::kStageCount> stages{};
    std::vector<shader::StageReflection> reflections;
};

struct Gather {
    const D3d11Device* device = nullptr;
    std::span<const ShaderHandle> handles;
    StagePack* pack = nullptr;
};

struct GraphicsBuild {
    D3d11Device* device = nullptr;
    const GraphicsPipelineDesc* desc = nullptr;
    const StagePack* pack = nullptr;
    Program* program = nullptr;
};

struct ElementInput {
    const GraphicsPipelineDesc* desc = nullptr;
    const shader::StageReflection* vertex = nullptr;
    const VertexAttribute* attribute = nullptr;
};

struct AttributePush {
    Elements* elements = nullptr;
    const GraphicsPipelineDesc* desc = nullptr;
    const shader::StageReflection* vertex = nullptr;
    const VertexAttribute* attribute = nullptr;
};

struct LayoutMake {
    D3d11Device* device = nullptr;
    Pipeline* pipeline = nullptr;
    const Shader* vertex = nullptr;
    const Elements* elements = nullptr;
};

struct EntryAdd {
    D3d11Device* device = nullptr;
    BindGroup* group = nullptr;
    const SpaceLayout* space = nullptr;
    const BindEntry* entry = nullptr;
};

struct GroupFill {
    D3d11Device* device = nullptr;
    BindGroup* group = nullptr;
    const SpaceLayout* space = nullptr;
    const BindGroupDesc* desc = nullptr;
};

struct StageQuery {
    const shader::Resource* resource = nullptr;
    std::uint32_t space = 0;
    std::uint32_t slot = 0;
};

struct BufferAdd {
    const EntryAdd* add = nullptr;
    const shader::Resource* resource = nullptr;
    const BufferRange* range = nullptr;
};

struct ViewAdd {
    const EntryAdd* add = nullptr;
    const shader::Resource* resource = nullptr;
    TextureViewHandle view{};
};

struct SamplerAdd {
    const EntryAdd* add = nullptr;
    const shader::Resource* resource = nullptr;
    SamplerHandle sampler{};
};

struct SpanAsk {
    ID3D11Buffer* resource = nullptr;
    std::uint64_t offset = 0;
    std::uint32_t bytes = 0;
    std::uint32_t stride = 0;
};

struct ViewSpan {
    ID3D11Buffer* resource = nullptr;
    UINT first = 0;
    UINT count = 0;
};

struct ItemFill {
    const shader::Resource* resource = nullptr;
    const BufferRange* range = nullptr;
    std::uint32_t bytes = 0;
    std::uint32_t space = 0;
    std::uint32_t slot = 0;
    bool is_uniform = false;
};

struct SlotQuery {
    std::uint32_t stored = 0;
    std::uint32_t space = 0;
    std::uint32_t slot = 0;
};

struct BufferMatch {
    const GroupBuffer* item = nullptr;
    std::uint32_t space = 0;
    const BindEntry* entry = nullptr;
};

struct ByteAsk {
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
    std::uint64_t buffer_size = 0;
    std::uint32_t previous = 0;
    std::uint32_t stride = 1;
    bool is_uniform = false;
};

struct StrideAsk {
    const D3d11Device* device = nullptr;
    const GroupBuffer* item = nullptr;
    const Buffer* buffer = nullptr;
};

struct BufferPatch {
    D3d11Device* device = nullptr;
    BindGroup* group = nullptr;
    const BindEntry* entry = nullptr;
    const BufferRange* range = nullptr;
};

struct StoragePatch {
    D3d11Device* device = nullptr;
    GroupBuffer* item = nullptr;
    Buffer* buffer = nullptr;
    const BufferRange* range = nullptr;
};

struct ViewPatch {
    D3d11Device* device = nullptr;
    BindGroup* group = nullptr;
    const BindEntry* entry = nullptr;
    TextureViewHandle view{};
};

struct SamplerPatch {
    D3d11Device* device = nullptr;
    BindGroup* group = nullptr;
    const BindEntry* entry = nullptr;
    SamplerHandle sampler{};
};

struct ShapeAsk {
    D3d11Device* device = nullptr;
    Buffer* buffer = nullptr;
    shader::ResourceKind kind = shader::ResourceKind::kUniformBuffer;
    std::uint32_t stride = 0;
};

struct ViewAttach {
    D3d11Device* device = nullptr;
    GroupBuffer* item = nullptr;
    Buffer* buffer = nullptr;
    const shader::Resource* resource = nullptr;
};

struct RefreshAsk {
    D3d11Device* device = nullptr;
    GroupBuffer* item = nullptr;
    Buffer* buffer = nullptr;
    std::uint32_t stride = 0;
};

struct UniformPatch {
    GroupBuffer* item = nullptr;
    const Buffer* buffer = nullptr;
    const BufferRange* range = nullptr;
};

template <class T>
using CreateShader = HRESULT (STDMETHODCALLTYPE Device::*)(const void*, SIZE_T, Linkage*, T**);

template <class Value>
[[nodiscard]] auto unexpected_error(const Value& status) {
    const auto& error = status.error();
    return std::unexpected(error);
}

template <class T>
void retire_com(D3d11Device& device, ComPtr<T>& object) {
    // MIDL che IUnknown.
    // NOLINTNEXTLINE(misc-include-cleaner)
    ComPtr<IUnknown> unknown;
    object.As(&unknown);
    device.retire(unknown);
    object.Reset();
}

// code đã dài ít nhất 4 byte.
[[nodiscard]] bool is_dxbc(std::span<const std::byte> code) noexcept {
    const auto byte_d = static_cast<unsigned char>(code[0]);
    const auto byte_x = static_cast<unsigned char>(code[1]);
    const auto byte_b = static_cast<unsigned char>(code[2]);
    const auto byte_c = static_cast<unsigned char>(code[3]);
    return byte_d == 'D' && byte_x == 'X' && byte_b == 'B' && byte_c == 'C';
}

[[nodiscard]] bool is_blocked(shader::Stage stage) noexcept {
    if (stage == shader::Stage::kMesh) return true;
    if (stage == shader::Stage::kAmplification) return true;
    return stage == shader::Stage::kLibrary;
}

template <class T>
[[nodiscard]] Status make_shader(const ShaderMake& make, CreateShader<T> create) {
    Bytecode code;
    code.data = make.shader->bytes.data();
    code.size = make.shader->bytes.size();
    ComPtr<T> typed;
    T** slot = typed.GetAddressOf();
    // Create*Shader không const.
    // NOLINTNEXTLINE(misc-const-correctness)
    ID3D11Device* hardware = make.device->device();
    const HRESULT created = (hardware->*create)(code.data, code.size, nullptr, slot);
    make.device->note_loss(created);
    if (FAILED(created)) return failed(created, "không tạo được shader D3D11");
    const HRESULT queried = typed.As(&make.shader->code);
    make.device->note_loss(queried);
    if (FAILED(queried)) return failed(queried, "không lấy được shader D3D11");
    return ok();
}

[[nodiscard]] Status compile_shader(D3d11Device& device, Shader& shader) {
    ShaderMake make;
    make.device = &device;
    make.shader = &shader;
    const shader::Stage stage = shader.reflection.stage;
    switch (stage) {
    case shader::Stage::kVertex: return make_shader<ID3D11VertexShader>(make, &ID3D11Device::CreateVertexShader);
    case shader::Stage::kPixel: return make_shader<ID3D11PixelShader>(make, &ID3D11Device::CreatePixelShader);
    case shader::Stage::kGeometry: return make_shader<ID3D11GeometryShader>(make, &ID3D11Device::CreateGeometryShader);
    case shader::Stage::kHull: return make_shader<ID3D11HullShader>(make, &ID3D11Device::CreateHullShader);
    case shader::Stage::kDomain: return make_shader<ID3D11DomainShader>(make, &ID3D11Device::CreateDomainShader);
    case shader::Stage::kCompute: return make_shader<ID3D11ComputeShader>(make, &ID3D11Device::CreateComputeShader);
    default: return fail(kMissing, "D3D11 không có stage này");
    }
}

[[nodiscard]] Result<Shader> build_shader(D3d11Device& device, const ShaderDesc& desc) {
    const shader::Variant* const variant = desc.variant;
    const bool missing = variant == nullptr || variant->code.size() < 4;
    if (missing) return fail(kBad, "shader: thiếu DXBC");
    if (!is_dxbc(variant->code)) return fail(kBad, "shader D3D11 cần DXBC");
    if (is_blocked(variant->reflection.stage)) {
        return fail(kMissing, "D3D11 không có mesh, amplification hay thư viện");
    }
    Shader shader;
    const auto first = variant->code.begin();
    const auto last = variant->code.end();
    shader.bytes.assign(first, last);
    shader.reflection = variant->reflection;
    const Status compiled = compile_shader(device, shader);
    if (!compiled) return unexpected_error(compiled);
    ID3D11DeviceChild* child = shader.code.Get();
    if (child == nullptr) return fail(kBad, "không lấy được shader D3D11");
    set_debug_name(*child, desc.name);
    return shader;
}

[[nodiscard]] Status take_shader(const D3d11Device& device, ShaderHandle handle, StagePack& pack) {
    const Shader* const shader = device.find(handle);
    if (shader == nullptr) return fail(kBad, "pipeline: shader đã chết");
    const auto index = std::to_underlying(shader->reflection.stage);
    if (index >= pack.stages.size()) return fail(kBad, "pipeline: stage lạ");
    // Chỉ số stage đã kiểm biên; mảng cố định không nhận chỉ số biến.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    if (pack.stages[index] != nullptr) return fail(kBad, "pipeline: một stage có hai shader");
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    pack.stages[index] = shader;
    pack.reflections.push_back(shader->reflection);
    return ok();
}

[[nodiscard]] Status gather_stages(const Gather& gather) {
    gather.pack->reflections.reserve(gather.handles.size());
    Status status = ok();
    const auto end = gather.handles.end();
    for (auto handle = gather.handles.begin(); handle != end && status; ++handle) {
        status = take_shader(*gather.device, *handle, *gather.pack);
    }
    return status;
}

[[nodiscard]] Status require_graphics(const StagePack& pack) {
    constexpr auto kVertexIndex = std::to_underlying(shader::Stage::kVertex);
    if (pack.stages[kVertexIndex] == nullptr) return fail(kBad, "pipeline: thiếu vertex shader");
    constexpr auto kComputeIndex = std::to_underlying(shader::Stage::kCompute);
    const bool has_compute = pack.stages[kComputeIndex] != nullptr;
    if (has_compute) return fail(kBad, "pipeline đồ hoạ không nhận compute");
    return ok();
}

[[nodiscard]] Status reject_missing(const GraphicsPipelineDesc& desc) {
    if (desc.raster.is_conservative) return fail(kMissing, "D3D11 không có conservative raster");
    if (desc.depth.is_bounds_tested) return fail(kMissing, "D3D11 không có phép thử khoảng độ sâu");
    return ok();
}

[[nodiscard]] const shader::StageReflection* vertex_stage(const StagePack& pack) noexcept {
    constexpr auto kVertexIndex = std::to_underlying(shader::Stage::kVertex);
    const Shader* const shader = pack.stages[kVertexIndex];
    if (shader == nullptr) return nullptr;
    return &shader->reflection;
}

[[nodiscard]] const Shader* stage_shader(const StagePack& pack, shader::Stage stage) noexcept {
    const auto index = std::to_underlying(stage);
    if (index >= pack.stages.size()) return nullptr;
    // Chỉ số stage đã kiểm biên; mảng cố định không nhận chỉ số biến.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    return pack.stages[index];
}

[[nodiscard]] const Attr* match_location(const StageRef& stage, std::uint32_t location) {
    const auto same = [location](const Attr& input) { return input.location == location; };
    const auto found = std::ranges::find_if(stage.inputs, same);
    if (found == stage.inputs.end()) return nullptr;
    return &*found;
}

[[nodiscard]] Status add_element(Elements& elements, const ElementInput& input) {
    const VertexAttribute& attribute = *input.attribute;
    const shader::Attribute* const found = match_location(*input.vertex, attribute.location);
    if (found == nullptr) return fail(kBad, "pipeline: shader không có location này");
    if (attribute.buffer >= input.desc->vertex_buffers.size()) {
        return fail(kBad, "pipeline: khe đỉnh vượt biên");
    }
    const VertexBufferLayout& buffer = input.desc->vertex_buffers[attribute.buffer];
    D3D11_INPUT_ELEMENT_DESC element{};
    // Layout chép semantic trong lời gọi.
    element.SemanticName = found->semantic.c_str();
    element.SemanticIndex = found->index;
    element.Format = to_dxgi(attribute.format);
    element.InputSlot = attribute.buffer;
    element.AlignedByteOffset = attribute.offset;
    const bool per_instance = buffer.is_per_instance;
    element.InputSlotClass = D3D11_INPUT_PER_VERTEX_DATA;
    if (per_instance) element.InputSlotClass = D3D11_INPUT_PER_INSTANCE_DATA;
    element.InstanceDataStepRate = 0;
    if (per_instance) element.InstanceDataStepRate = 1;
    elements.push_back(element);
    return ok();
}

[[nodiscard]] Status push_attribute(const AttributePush& push) {
    ElementInput input;
    input.desc = push.desc;
    input.vertex = push.vertex;
    input.attribute = push.attribute;
    return add_element(*push.elements, input);
}

[[nodiscard]] Status collect_elements(Elements& elements, const GraphicsBuild& build) {
    const shader::StageReflection* const vertex = vertex_stage(*build.pack);
    if (vertex == nullptr) return fail(kBad, "pipeline: thiếu vertex shader");
    Status added = ok();
    const auto end = build.desc->vertex_attributes.end();
    for (auto item = build.desc->vertex_attributes.begin(); item != end && added; ++item) {
        AttributePush push;
        push.elements = &elements;
        push.desc = build.desc;
        push.vertex = vertex;
        push.attribute = &*item;
        added = push_attribute(push);
    }
    return added;
}

[[nodiscard]] Status create_layout(const LayoutMake& make) {
    const Elements& elements = *make.elements;
    ID3D11Device* hardware = make.device->device();
    const D3D11_INPUT_ELEMENT_DESC* const first = elements.data();
    const auto count = static_cast<UINT>(elements.size());
    const void* const bytes = make.vertex->bytes.data();
    const std::size_t size = make.vertex->bytes.size();
    ID3D11InputLayout** slot = make.pipeline->inputs.GetAddressOf();
    const HRESULT created = hardware->CreateInputLayout(first, count, bytes, size, slot);
    make.device->note_loss(created);
    if (FAILED(created)) return failed(created, "không tạo được input layout");
    return ok();
}

[[nodiscard]] Status make_inputs(Pipeline& pipeline, const GraphicsBuild& build) {
    Elements elements;
    const Status added = collect_elements(elements, build);
    if (!added) return added;
    if (elements.empty()) return ok();
    const Shader* const vertex = stage_shader(*build.pack, shader::Stage::kVertex);
    if (vertex == nullptr) return fail(kBad, "pipeline: thiếu vertex shader");
    LayoutMake make;
    make.device = build.device;
    make.pipeline = &pipeline;
    make.vertex = vertex;
    make.elements = &elements;
    return create_layout(make);
}

// float ngoài miền int là UB.
[[nodiscard]] int bias_of(float bias) noexcept {
    const bool fits = bias >= -32768.0F && bias <= 32767.0F;
    if (!fits) return 0;
    return static_cast<int>(bias);
}

[[nodiscard]] RasterDesc raster_desc(const RasterState& state) noexcept {
    RasterDesc desc{};
    desc.FillMode = to_dxgi(state.fill);
    desc.CullMode = to_dxgi(state.cull);
    const bool is_ccw = state.front_face == FrontFace::kCounterClockwise;
    // D3D11 mặc định theo chiều kim.
    desc.FrontCounterClockwise = is_ccw ? TRUE : FALSE;
    desc.DepthBias = bias_of(state.depth_bias);
    desc.SlopeScaledDepthBias = state.depth_bias_slope;
    desc.DepthBiasClamp = state.depth_bias_clamp;
    desc.DepthClipEnable = state.is_depth_clipped ? TRUE : FALSE;
    desc.MultisampleEnable = TRUE;
    // set_scissor cần cờ này.
    desc.ScissorEnable = TRUE;
    desc.AntialiasedLineEnable = FALSE;
    return desc;
}

[[nodiscard]] FaceDesc face_of(const StencilFace& face) noexcept {
    FaceDesc desc{};
    desc.StencilFailOp = to_dxgi(face.fail);
    desc.StencilDepthFailOp = to_dxgi(face.depth_fail);
    desc.StencilPassOp = to_dxgi(face.pass);
    desc.StencilFunc = to_dxgi(face.compare);
    return desc;
}

[[nodiscard]] DepthDesc depth_desc(const DepthState& state) noexcept {
    DepthDesc desc{};
    desc.DepthEnable = state.is_tested ? TRUE : FALSE;
    const bool written = state.is_written;
    desc.DepthWriteMask = written ? D3D11_DEPTH_WRITE_MASK_ALL : D3D11_DEPTH_WRITE_MASK_ZERO;
    desc.DepthFunc = to_dxgi(state.compare);
    desc.StencilEnable = state.is_stencil_tested ? TRUE : FALSE;
    desc.StencilReadMask = state.stencil_read_mask;
    desc.StencilWriteMask = state.stencil_write_mask;
    desc.FrontFace = face_of(state.front);
    desc.BackFace = face_of(state.back);
    return desc;
}

[[nodiscard]] TargetBlend blend_desc(const BlendState& state) noexcept {
    TargetBlend desc{};
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
    if (index >= blends.size()) return {};
    return blends[index];
}

[[nodiscard]] std::size_t blend_count(const GraphicsPipelineDesc& desc) noexcept {
    const std::size_t colors = desc.color_formats.size();
    if (colors == 0) return 1;
    if (colors > kMaxColorTargets) return kMaxColorTargets;
    return colors;
}

void write_blend_target(BlendDesc& desc, const GfxDesc& pipe, std::size_t index) noexcept {
    const BlendState state = blend_at(pipe.blends, index);
    const TargetBlend native = blend_desc(state);
    switch (index) {
    case 0: desc.RenderTarget[0] = native; break;
    case 1: desc.RenderTarget[1] = native; break;
    case 2: desc.RenderTarget[2] = native; break;
    case 3: desc.RenderTarget[3] = native; break;
    case 4: desc.RenderTarget[4] = native; break;
    case 5: desc.RenderTarget[5] = native; break;
    case 6: desc.RenderTarget[6] = native; break;
    case 7: desc.RenderTarget[7] = native; break;
    default: break;
    }
}

void fill_blend(BlendDesc& desc, const GraphicsPipelineDesc& pipe) noexcept {
    const bool coverage = pipe.is_alpha_to_coverage;
    desc.AlphaToCoverageEnable = coverage ? TRUE : FALSE;
    const bool independent = pipe.blends.size() > 1;
    desc.IndependentBlendEnable = independent ? TRUE : FALSE;
    const std::size_t count = blend_count(pipe);
    for (std::size_t index = 0; index < count; ++index) {
        write_blend_target(desc, pipe, index);
    }
}

[[nodiscard]] Status make_raster(D3d11Device& device, Pipeline& pipeline, const RasterDesc& desc) {
    ID3D11Device* hardware = device.device();
    ID3D11RasterizerState** slot = pipeline.raster.GetAddressOf();
    const HRESULT created = hardware->CreateRasterizerState(&desc, slot);
    device.note_loss(created);
    if (FAILED(created)) return failed(created, "không tạo được rasterizer");
    return ok();
}

[[nodiscard]] Status make_depth(D3d11Device& device, Pipeline& pipeline, const DepthDesc& desc) {
    ID3D11Device* hardware = device.device();
    ID3D11DepthStencilState** slot = pipeline.depth.GetAddressOf();
    const HRESULT created = hardware->CreateDepthStencilState(&desc, slot);
    device.note_loss(created);
    if (FAILED(created)) return failed(created, "không tạo được depth stencil");
    return ok();
}

[[nodiscard]] Status make_blend(D3d11Device& device, Pipeline& pipeline, const BlendDesc& desc) {
    ID3D11Device* hardware = device.device();
    ID3D11BlendState** slot = pipeline.blend.GetAddressOf();
    const HRESULT created = hardware->CreateBlendState(&desc, slot);
    device.note_loss(created);
    if (FAILED(created)) return failed(created, "không tạo được blend state");
    return ok();
}

[[nodiscard]] Status make_states(D3d11Device& device, Pipeline& pipeline, const GfxDesc& desc) {
    const RasterDesc raster = raster_desc(desc.raster);
    const Status raster_status = make_raster(device, pipeline, raster);
    if (!raster_status) return raster_status;
    const DepthDesc depth = depth_desc(desc.depth);
    const Status depth_status = make_depth(device, pipeline, depth);
    if (!depth_status) return depth_status;
    BlendDesc blend{};
    fill_blend(blend, desc);
    return make_blend(device, pipeline, blend);
}

[[nodiscard]] Result<D3D_PRIMITIVE_TOPOLOGY> topology_of(const GraphicsPipelineDesc& desc) {
    if (desc.topology != Topology::kPatchList) return to_topology(desc.topology);
    const bool bad_points = desc.patch_points == 0 || desc.patch_points > 32;
    if (bad_points) return fail(kBad, "pipeline: patch_points phải trong 1..32");
    const auto base = static_cast<int>(D3D_PRIMITIVE_TOPOLOGY_1_CONTROL_POINT_PATCHLIST);
    const auto points = static_cast<int>(desc.patch_points);
    return static_cast<D3D_PRIMITIVE_TOPOLOGY>(base + points - 1);
}

void copy_strides(Pipeline& pipeline, std::span<const VertexBufferLayout> buffers) noexcept {
    const std::size_t buffer_count = buffers.size();
    const std::size_t stride_count = pipeline.strides.size();
    const std::size_t count = std::min(buffer_count, stride_count);
    for (std::size_t index = 0; index < count; ++index) {
        // Vòng đã kẹp theo size của strides và của buffers.
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index,cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
        pipeline.strides[index] = buffers[index].stride;
    }
}

template <class T>
[[nodiscard]] Status query_as(ID3D11DeviceChild& child, ComPtr<T>& out) {
    T** slot = out.GetAddressOf();
    const HRESULT queried = child.QueryInterface(IID_PPV_ARGS(slot));
    if (FAILED(queried)) return failed(queried, "không lấy được shader của pipeline");
    return ok();
}

[[nodiscard]] Status query_stage(Child& child, Stage stage, Pipeline& pipeline) {
    switch (stage) {
    case shader::Stage::kVertex: return query_as<ID3D11VertexShader>(child, pipeline.vertex);
    case shader::Stage::kPixel: return query_as<ID3D11PixelShader>(child, pipeline.pixel);
    case shader::Stage::kGeometry: return query_as<ID3D11GeometryShader>(child, pipeline.geometry);
    case shader::Stage::kHull: return query_as<ID3D11HullShader>(child, pipeline.hull);
    case shader::Stage::kDomain: return query_as<ID3D11DomainShader>(child, pipeline.domain);
    case shader::Stage::kCompute: return query_as<ID3D11ComputeShader>(child, pipeline.compute);
    default: return fail(kMissing, "D3D11 không có stage này");
    }
}

[[nodiscard]] Status adopt_one(Pipeline& pipeline, const Shader* shader) {
    if (shader == nullptr) return ok();
    ID3D11DeviceChild* child = shader->code.Get();
    if (child == nullptr) return fail(kBad, "pipeline: shader không có mã");
    return query_stage(*child, shader->reflection.stage, pipeline);
}

[[nodiscard]] Status adopt_stage(Pipeline& pipeline, const StagePack& pack, shader::Stage stage) {
    const Shader* const shader = stage_shader(pack, stage);
    return adopt_one(pipeline, shader);
}

[[nodiscard]] Status adopt_all(Pipeline& pipeline, const StagePack& pack) {
    const std::array<shader::Stage, 5> stages{shader::Stage::kVertex, shader::Stage::kPixel, shader::Stage::kGeometry,
        shader::Stage::kHull, shader::Stage::kDomain};
    Status status = ok();
    for (auto stage = stages.begin(); stage != stages.end() && status; ++stage) {
        status = adopt_stage(pipeline, pack, *stage);
    }
    return status;
}

[[nodiscard]] Result<Pipeline> assemble(const GraphicsBuild& build) {
    Pipeline pipeline;
    const Status inputs = make_inputs(pipeline, build);
    if (!inputs) return unexpected_error(inputs);
    const Result<D3D_PRIMITIVE_TOPOLOGY> topology = topology_of(*build.desc);
    if (!topology) return unexpected_error(topology);
    pipeline.topology = *topology;
    pipeline.is_compute = false;
    pipeline.depth_write = build.desc->depth.is_written;
    pipeline.layout = std::move(build.program->layout);
    copy_strides(pipeline, build.desc->vertex_buffers);
    const Status adopted = adopt_all(pipeline, *build.pack);
    if (!adopted) return unexpected_error(adopted);
    const Status states = make_states(*build.device, pipeline, *build.desc);
    if (!states) return unexpected_error(states);
    return pipeline;
}

[[nodiscard]] Result<Pipeline> build_graphics(D3d11Device& device, const GfxDesc& desc) {
    StagePack pack;
    Gather gather;
    gather.device = &device;
    gather.handles = desc.shaders;
    gather.pack = &pack;
    const Status gathered = gather_stages(gather);
    if (!gathered) return unexpected_error(gathered);
    Result<Program> program = make_program(pack.reflections);
    if (!program) return unexpected_error(program);
    const Status ready = require_graphics(pack);
    if (!ready) return unexpected_error(ready);
    const Status supported = reject_missing(desc);
    if (!supported) return unexpected_error(supported);
    Program& owned = *program;
    GraphicsBuild build;
    build.device = &device;
    build.desc = &desc;
    build.pack = &pack;
    build.program = &owned;
    return assemble(build);
}

[[nodiscard]] Status adopt_compute(Pipeline& pipeline, const Shader& shader) {
    ID3D11DeviceChild* child = shader.code.Get();
    if (child == nullptr) return fail(kBad, "pipeline: shader không có mã");
    return query_stage(*child, shader.reflection.stage, pipeline);
}

[[nodiscard]] Result<Pipeline> build_compute(const D3d11Device& device, const ComputePipelineDesc& desc) {
    const Shader* const shader = device.find(desc.shader);
    if (shader == nullptr) return fail(kBad, "pipeline: shader đã chết");
    if (shader->reflection.stage != shader::Stage::kCompute) {
        return fail(kBad, "pipeline compute cần shader stage Compute");
    }
    std::array<shader::StageReflection, 1> stages{shader->reflection};
    Result<Program> program = make_program(stages);
    if (!program) return unexpected_error(program);
    Pipeline pipeline;
    pipeline.is_compute = true;
    pipeline.layout = std::move(program->layout);
    const Status adopted = adopt_compute(pipeline, *shader);
    if (!adopted) return unexpected_error(adopted);
    return pipeline;
}

void name_child(ID3D11DeviceChild* child, std::string_view name) noexcept {
    if (child == nullptr) return;
    set_debug_name(*child, name);
}

void name_pipeline(const Pipeline& pipeline, std::string_view name) noexcept {
    ID3D11DeviceChild* vertex = pipeline.vertex.Get();
    name_child(vertex, name);
    ID3D11DeviceChild* pixel = pipeline.pixel.Get();
    name_child(pixel, name);
    ID3D11DeviceChild* geometry = pipeline.geometry.Get();
    name_child(geometry, name);
    ID3D11DeviceChild* hull = pipeline.hull.Get();
    name_child(hull, name);
    ID3D11DeviceChild* domain = pipeline.domain.Get();
    name_child(domain, name);
    ID3D11DeviceChild* compute = pipeline.compute.Get();
    name_child(compute, name);
    ID3D11DeviceChild* inputs = pipeline.inputs.Get();
    name_child(inputs, name);
    ID3D11DeviceChild* raster = pipeline.raster.Get();
    name_child(raster, name);
    ID3D11DeviceChild* depth = pipeline.depth.Get();
    name_child(depth, name);
    ID3D11DeviceChild* blend = pipeline.blend.Get();
    name_child(blend, name);
}

[[nodiscard]] GroupBinding binding_of(const StageQuery& query) noexcept {
    GroupBinding binding;
    binding.slot = resource_register(query.space, query.slot);
    const shader::StageSet stages = query.resource->stages;
    binding.in_vertex = stages.has(shader::Stage::kVertex);
    binding.in_pixel = stages.has(shader::Stage::kPixel);
    binding.in_compute = stages.has(shader::Stage::kCompute);
    return binding;
}

void apply_binding(GroupBinding& item, const GroupBinding& binding) noexcept {
    item.slot = binding.slot;
    item.in_vertex = binding.in_vertex;
    item.in_pixel = binding.in_pixel;
    item.in_compute = binding.in_compute;
}

[[nodiscard]] bool needs_shape(shader::ResourceKind kind) noexcept {
    if (kind == shader::ResourceKind::kBuffer) return true;
    if (kind == shader::ResourceKind::kRwBuffer) return true;
    if (kind == shader::ResourceKind::kTexelBuffer) return true;
    return kind == shader::ResourceKind::kRwTexelBuffer;
}

[[nodiscard]] bool needs_uav(shader::ResourceKind kind) noexcept {
    if (kind == shader::ResourceKind::kRwBuffer) return true;
    return kind == shader::ResourceKind::kRwTexelBuffer;
}

// raw là word 4 byte.
[[nodiscard]] std::uint32_t element_stride(const shader::Resource& resource) noexcept {
    if (resource.raw) return 4;
    return resource.stride;
}

[[nodiscard]] Status reject_odd_buffer(shader::ResourceKind kind) {
    if (kind == shader::ResourceKind::kAccelerationStructure) {
        return fail(kMissing, "D3D11 không có acceleration structure");
    }
    if (kind == shader::ResourceKind::kPushConstant) {
        return fail(kMissing, "D3D11 không gắn push constant trong nhóm");
    }
    return ok();
}

[[nodiscard]] Status check_usage(const Buffer& buffer, shader::ResourceKind kind) {
    const bool is_uniform = kind == shader::ResourceKind::kUniformBuffer;
    const BufferUsage wanted = is_uniform ? BufferUsage::kUniform : BufferUsage::kStorage;
    if (has(buffer.usage, wanted)) return ok();
    return fail(kBad, "nhóm gắn: buffer thiếu Uniform hoặc Storage");
}

[[nodiscard]] Result<std::uint32_t> narrow_bytes(std::uint64_t bytes) {
    const std::uint64_t limit = std::numeric_limits<std::uint32_t>::max();
    if (bytes > limit) return fail(kBad, "nhóm gắn: cỡ buffer không vừa uint32");
    return static_cast<std::uint32_t>(bytes);
}

[[nodiscard]] Result<ViewSpan> view_span(const SpanAsk& ask) {
    if (ask.resource == nullptr) return fail(kBad, "nhóm gắn: buffer chưa có tài nguyên");
    if (ask.stride == 0) return fail(kBad, "nhóm gắn: stride 0");
    const bool aligned = ask.offset % ask.stride == 0 && ask.bytes % ask.stride == 0;
    if (!aligned) return fail(kBad, "nhóm gắn: khoảng buffer không khớp stride");
    const std::uint64_t first = ask.offset / ask.stride;
    const std::uint64_t count = static_cast<std::uint64_t>(ask.bytes) / ask.stride;
    const std::uint64_t limit = std::numeric_limits<UINT>::max();
    const bool fits = first <= limit && count >= 1 && count <= limit;
    if (!fits) return fail(kBad, "nhóm gắn: số phần tử không vừa UINT");
    ViewSpan span;
    span.resource = ask.resource;
    span.first = static_cast<UINT>(first);
    span.count = static_cast<UINT>(count);
    return span;
}

[[nodiscard]] Status make_srv(D3d11Device& device, const ViewSpan& span, Srv& out) {
    D3D11_SHADER_RESOURCE_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_UNKNOWN;
    desc.ViewDimension = D3D11_SRV_DIMENSION_BUFFER;
    desc.Buffer.FirstElement = span.first;
    desc.Buffer.NumElements = span.count;
    ID3D11Device* hardware = device.device();
    ID3D11ShaderResourceView** slot = out.GetAddressOf();
    const HRESULT created = hardware->CreateShaderResourceView(span.resource, &desc, slot);
    device.note_loss(created);
    if (FAILED(created)) return failed(created, "không tạo được SRV buffer");
    return ok();
}

[[nodiscard]] Status make_uav(D3d11Device& device, const ViewSpan& span, Uav& out) {
    D3D11_UNORDERED_ACCESS_VIEW_DESC desc{};
    desc.Format = DXGI_FORMAT_UNKNOWN;
    desc.ViewDimension = D3D11_UAV_DIMENSION_BUFFER;
    desc.Buffer.FirstElement = span.first;
    desc.Buffer.NumElements = span.count;
    desc.Buffer.Flags = 0;
    ID3D11Device* hardware = device.device();
    ID3D11UnorderedAccessView** slot = out.GetAddressOf();
    const HRESULT created = hardware->CreateUnorderedAccessView(span.resource, &desc, slot);
    device.note_loss(created);
    if (FAILED(created)) return failed(created, "không tạo được UAV buffer");
    return ok();
}

// materialize đòi khoá immediate.
[[nodiscard]] Status shape_buffer(D3d11Device& device, Buffer& buffer, std::uint32_t stride) {
    const ImmediateGuard guard = device.lock_immediate();
    return device.materialize(buffer, stride);
}

[[nodiscard]] Status shape_needed(const ShapeAsk& ask) {
    if (!needs_shape(ask.kind)) return ok();
    return shape_buffer(*ask.device, *ask.buffer, ask.stride);
}

[[nodiscard]] Status attach_views(const ViewAttach& ask) {
    if (ask.resource->kind == shader::ResourceKind::kUniformBuffer) return ok();
    const std::uint32_t stride = element_stride(*ask.resource);
    if (stride == 0) return fail(kBad, "nhóm gắn: stride 0");
    ShapeAsk shape;
    shape.device = ask.device;
    shape.buffer = ask.buffer;
    shape.kind = ask.resource->kind;
    shape.stride = stride;
    const Status shaped = shape_needed(shape);
    if (!shaped) return shaped;
    SpanAsk span_ask;
    span_ask.resource = ask.buffer->resource.Get();
    span_ask.offset = ask.item->offset;
    span_ask.bytes = ask.item->bytes;
    span_ask.stride = stride;
    const Result<ViewSpan> span = view_span(span_ask);
    if (!span) return unexpected_error(span);
    const Status srv = make_srv(*ask.device, *span, ask.item->srv);
    if (!srv) return srv;
    if (!needs_uav(ask.resource->kind)) return ok();
    return make_uav(*ask.device, *span, ask.item->uav);
}

[[nodiscard]] GroupBuffer make_item(const ItemFill& fill) {
    GroupBuffer item;
    StageQuery query;
    query.resource = fill.resource;
    query.space = fill.space;
    query.slot = fill.slot;
    const GroupBinding binding = binding_of(query);
    apply_binding(item, binding);
    item.buffer = fill.range->buffer;
    item.is_uniform = fill.is_uniform;
    item.offset = fill.range->offset;
    item.bytes = fill.bytes;
    return item;
}

[[nodiscard]] Status add_buffer(const BufferAdd& input) {
    const EntryAdd& add = *input.add;
    const shader::Resource& resource = *input.resource;
    const BufferRange& range = *input.range;
    const Status odd = reject_odd_buffer(resource.kind);
    if (!odd) return odd;
    Buffer* const buffer = add.device->find(range.buffer);
    if (buffer == nullptr) return fail(kBad, "nhóm gắn: buffer đã chết");
    const Status usage = check_usage(*buffer, resource.kind);
    if (!usage) return usage;
    const Result<std::uint64_t> resolved = resolve_binding(*add.space, resource, range, buffer->size);
    if (!resolved) return unexpected_error(resolved);
    const Result<std::uint32_t> bytes = narrow_bytes(*resolved);
    if (!bytes) return unexpected_error(bytes);
    const bool is_uniform = resource.kind == shader::ResourceKind::kUniformBuffer;
    ItemFill fill;
    fill.resource = &resource;
    fill.range = &range;
    fill.bytes = *bytes;
    fill.space = add.group->space;
    fill.slot = add.entry->slot;
    fill.is_uniform = is_uniform;
    GroupBuffer item = make_item(fill);
    ViewAttach views;
    views.device = add.device;
    views.item = &item;
    views.buffer = buffer;
    views.resource = &resource;
    const Status viewed = attach_views(views);
    if (!viewed) return viewed;
    add.group->buffers.push_back(item);
    return ok();
}

[[nodiscard]] Status add_view(const ViewAdd& input) {
    const EntryAdd& add = *input.add;
    const shader::Resource& resource = *input.resource;
    if (resource.kind == shader::ResourceKind::kInputAttachment) {
        return fail(kMissing, "D3D11 không có input attachment");
    }
    if (add.device->find(input.view) == nullptr) return fail(kBad, "nhóm gắn: view đã chết");
    StageQuery query;
    query.resource = &resource;
    query.space = add.group->space;
    query.slot = add.entry->slot;
    GroupView item;
    const GroupBinding binding = binding_of(query);
    apply_binding(item, binding);
    item.view = input.view;
    add.group->views.push_back(item);
    return ok();
}

[[nodiscard]] Status add_sampler(const SamplerAdd& input) {
    const EntryAdd& add = *input.add;
    if (add.device->find(input.sampler) == nullptr) return fail(kBad, "nhóm gắn: sampler đã chết");
    StageQuery query;
    query.resource = input.resource;
    query.space = add.group->space;
    query.slot = add.entry->slot;
    GroupSampler item;
    const GroupBinding binding = binding_of(query);
    apply_binding(item, binding);
    item.sampler = input.sampler;
    add.group->samplers.push_back(item);
    return ok();
}

[[nodiscard]] Status add_entry(const EntryAdd& add) {
    if (add.entry->element != 0) return fail(kMissing, "D3D11 không gắn phần tử mảng bindless");
    const shader::Resource* const resource = find_resource(*add.space, add.entry->type, add.entry->slot);
    if (resource == nullptr) return fail(kBad, "nhóm gắn: chỗ gắn không có");
    const BufferRange* const range = std::get_if<BufferRange>(&add.entry->resource);
    if (range != nullptr) {
        BufferAdd input;
        input.add = &add;
        input.resource = resource;
        input.range = range;
        return add_buffer(input);
    }
    const TextureViewHandle* const view = std::get_if<TextureViewHandle>(&add.entry->resource);
    if (view != nullptr) {
        ViewAdd input;
        input.add = &add;
        input.resource = resource;
        input.view = *view;
        return add_view(input);
    }
    const SamplerHandle* const sampler = std::get_if<SamplerHandle>(&add.entry->resource);
    if (sampler != nullptr) {
        SamplerAdd input;
        input.add = &add;
        input.resource = resource;
        input.sampler = *sampler;
        return add_sampler(input);
    }
    return fail(kBad, "nhóm gắn: kiểu tài nguyên lạ");
}

[[nodiscard]] Status fill_group(const GroupFill& fill) {
    Status status = ok();
    const auto end = fill.desc->entries.end();
    for (auto entry = fill.desc->entries.begin(); entry != end && status; ++entry) {
        EntryAdd add;
        add.device = fill.device;
        add.group = fill.group;
        add.space = fill.space;
        add.entry = &*entry;
        status = add_entry(add);
    }
    return status;
}

[[nodiscard]] bool slot_match(const SlotQuery& query) noexcept {
    return query.stored == resource_register(query.space, query.slot);
}

// space trước slot, không đảo (lệch API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
template <class T>
[[nodiscard]] T* find_slot(std::vector<T>& items, std::uint32_t space, std::uint32_t slot) {
    const auto same = [&](const T& item) {
        SlotQuery query;
        query.stored = item.slot;
        query.space = space;
        query.slot = slot;
        return slot_match(query);
    };
    const auto found = std::ranges::find_if(items, same);
    if (found == items.end()) return nullptr;
    return &*found;
}
// NOLINTEND(bugprone-easily-swappable-parameters)

[[nodiscard]] bool buffer_match(const BufferMatch& match) noexcept {
    SlotQuery query;
    query.stored = match.item->slot;
    query.space = match.space;
    query.slot = match.entry->slot;
    if (!slot_match(query)) return false;
    const bool wants_uniform = match.entry->type == shader::RegisterType::kConstant;
    if (match.item->is_uniform != wants_uniform) return false;
    if (match.entry->type == shader::RegisterType::kUnordered) return match.item->uav != nullptr;
    if (match.entry->type == shader::RegisterType::kResource) return match.item->uav == nullptr;
    return wants_uniform;
}

[[nodiscard]] GroupBuffer* find_buffer(BindGroup& group, const BindEntry& entry) {
    const auto same = [&](const GroupBuffer& item) {
        BufferMatch match;
        match.item = &item;
        match.space = group.space;
        match.entry = &entry;
        return buffer_match(match);
    };
    const auto found = std::ranges::find_if(group.buffers, same);
    if (found == group.buffers.end()) return nullptr;
    return &*found;
}

[[nodiscard]] std::uint64_t asked_bytes(const ByteAsk& ask, std::uint64_t left) noexcept {
    if (ask.size != kWholeSize) return ask.size;
    if (ask.is_uniform) return ask.previous;
    if (ask.stride == 0) return 0;
    return left / ask.stride * ask.stride;
}

[[nodiscard]] Result<std::uint32_t> bound_bytes(const ByteAsk& ask) {
    if (ask.offset > ask.buffer_size) return fail(kOutside, "nhóm gắn: offset ngoài buffer");
    const std::uint64_t left = ask.buffer_size - ask.offset;
    const std::uint64_t bytes = asked_bytes(ask, left);
    if (bytes == 0 || bytes > left) return fail(kBad, "nhóm gắn: khoảng buffer không hợp lệ");
    return narrow_bytes(bytes);
}

[[nodiscard]] std::uint32_t known_stride(const StrideAsk& ask) noexcept {
    if (ask.buffer->stride != 0) return ask.buffer->stride;
    const Buffer* const previous = ask.device->find(ask.item->buffer);
    if (previous == nullptr) return 0;
    return previous->stride;
}

[[nodiscard]] Status refresh_srv(D3d11Device& device, GroupBuffer& item, const ViewSpan& span) {
    ComPtr<ID3D11ShaderResourceView> made;
    const Status created = make_srv(device, span, made);
    if (!created) return created;
    retire_com(device, item.srv);
    Srv moved = std::move(made);
    item.srv.Swap(moved);
    return ok();
}

[[nodiscard]] Status refresh_uav(D3d11Device& device, GroupBuffer& item, const ViewSpan& span) {
    ComPtr<ID3D11UnorderedAccessView> made;
    const Status created = make_uav(device, span, made);
    if (!created) return created;
    retire_com(device, item.uav);
    Uav moved = std::move(made);
    item.uav.Swap(moved);
    return ok();
}

[[nodiscard]] Status refresh_views(const RefreshAsk& ask) {
    const bool had_uav = ask.item->uav != nullptr;
    SpanAsk span_ask;
    span_ask.resource = ask.buffer->resource.Get();
    span_ask.offset = ask.item->offset;
    span_ask.bytes = ask.item->bytes;
    span_ask.stride = ask.stride;
    const Result<ViewSpan> span = view_span(span_ask);
    if (!span) return unexpected_error(span);
    const Status srv = refresh_srv(*ask.device, *ask.item, *span);
    if (!srv) return srv;
    if (!had_uav) return ok();
    return refresh_uav(*ask.device, *ask.item, *span);
}

[[nodiscard]] Status replace_uniform(const UniformPatch& patch) {
    const BufferRange& range = *patch.range;
    if (range.offset % kUniformAlignment != 0) {
        return fail(kBad, "nhóm gắn: offset của cbuffer không là bội của kUniformAlignment");
    }
    ByteAsk ask;
    ask.offset = range.offset;
    ask.size = range.size;
    ask.buffer_size = patch.buffer->size;
    ask.previous = patch.item->bytes;
    ask.is_uniform = true;
    ask.stride = 1;
    const Result<std::uint32_t> bytes = bound_bytes(ask);
    if (!bytes) return unexpected_error(bytes);
    patch.item->buffer = range.buffer;
    patch.item->offset = range.offset;
    patch.item->bytes = *bytes;
    return ok();
}

[[nodiscard]] Status replace_storage(const StoragePatch& patch) {
    StrideAsk stride_ask;
    stride_ask.device = patch.device;
    stride_ask.item = patch.item;
    stride_ask.buffer = patch.buffer;
    const std::uint32_t stride = known_stride(stride_ask);
    if (stride == 0) return fail(kBad, "nhóm gắn: stride 0");
    const Status shaped = shape_buffer(*patch.device, *patch.buffer, stride);
    if (!shaped) return shaped;
    ByteAsk ask;
    ask.offset = patch.range->offset;
    ask.size = patch.range->size;
    ask.buffer_size = patch.buffer->size;
    ask.previous = patch.item->bytes;
    ask.is_uniform = false;
    ask.stride = stride;
    const Result<std::uint32_t> bytes = bound_bytes(ask);
    if (!bytes) return unexpected_error(bytes);
    patch.item->buffer = patch.range->buffer;
    patch.item->offset = patch.range->offset;
    patch.item->bytes = *bytes;
    RefreshAsk refresh;
    refresh.device = patch.device;
    refresh.item = patch.item;
    refresh.buffer = patch.buffer;
    refresh.stride = stride;
    return refresh_views(refresh);
}

[[nodiscard]] Status update_buffer(const BufferPatch& patch) {
    GroupBuffer* const item = find_buffer(*patch.group, *patch.entry);
    if (item == nullptr) return fail(kBad, "update_bind_group: chỗ gắn không có trong nhóm");
    Buffer* const buffer = patch.device->find(patch.range->buffer);
    if (buffer == nullptr) return fail(kBad, "nhóm gắn: buffer đã chết");
    UniformPatch uniform;
    uniform.item = item;
    uniform.buffer = buffer;
    uniform.range = patch.range;
    if (item->is_uniform) return replace_uniform(uniform);
    StoragePatch storage;
    storage.device = patch.device;
    storage.item = item;
    storage.buffer = buffer;
    storage.range = patch.range;
    return replace_storage(storage);
}

[[nodiscard]] Status update_view(const ViewPatch& patch) {
    GroupView* const item = find_slot(patch.group->views, patch.group->space, patch.entry->slot);
    if (item == nullptr) return fail(kBad, "update_bind_group: chỗ gắn không có trong nhóm");
    if (patch.device->find(patch.view) == nullptr) return fail(kBad, "nhóm gắn: view đã chết");
    item->view = patch.view;
    return ok();
}

[[nodiscard]] Status update_sampler(const SamplerPatch& patch) {
    std::vector<GroupSampler>& items = patch.group->samplers;
    const std::uint32_t space = patch.group->space;
    const std::uint32_t slot = patch.entry->slot;
    GroupSampler* const item = find_slot(items, space, slot);
    if (item == nullptr) return fail(kBad, "update_bind_group: chỗ gắn không có trong nhóm");
    const bool dead = patch.device->find(patch.sampler) == nullptr;
    if (dead) return fail(kBad, "nhóm gắn: sampler đã chết");
    item->sampler = patch.sampler;
    return ok();
}

[[nodiscard]] Status update_one(D3d11Device& device, BindGroup& group, const BindEntry& entry) {
    if (entry.element != 0) return fail(kMissing, "D3D11 không gắn phần tử mảng bindless");
    const BufferRange* const range = std::get_if<BufferRange>(&entry.resource);
    if (range != nullptr) {
        BufferPatch patch;
        patch.device = &device;
        patch.group = &group;
        patch.entry = &entry;
        patch.range = range;
        return update_buffer(patch);
    }
    const TextureViewHandle* const view = std::get_if<TextureViewHandle>(&entry.resource);
    if (view != nullptr) {
        ViewPatch patch;
        patch.device = &device;
        patch.group = &group;
        patch.entry = &entry;
        patch.view = *view;
        return update_view(patch);
    }
    const SamplerHandle* const sampler = std::get_if<SamplerHandle>(&entry.resource);
    if (sampler != nullptr) {
        SamplerPatch patch;
        patch.device = &device;
        patch.group = &group;
        patch.entry = &entry;
        patch.sampler = *sampler;
        return update_sampler(patch);
    }
    return fail(kBad, "nhóm gắn: kiểu tài nguyên lạ");
}

void release_pipeline(D3d11Device& device, Pipeline& pipeline) {
    retire_com(device, pipeline.vertex);
    retire_com(device, pipeline.pixel);
    retire_com(device, pipeline.geometry);
    retire_com(device, pipeline.hull);
    retire_com(device, pipeline.domain);
    retire_com(device, pipeline.compute);
    retire_com(device, pipeline.inputs);
    retire_com(device, pipeline.raster);
    retire_com(device, pipeline.depth);
    retire_com(device, pipeline.blend);
}

void release_buffer(D3d11Device& device, GroupBuffer& item) {
    retire_com(device, item.srv);
    retire_com(device, item.uav);
}

void release_group(D3d11Device& device, BindGroup& group) {
    for (GroupBuffer& item : group.buffers) {
        release_buffer(device, item);
    }
}

} // namespace

Result<ShaderHandle> D3d11Device::create_shader(const ShaderDesc& desc) {
    Result<Shader> made = build_shader(*this, desc);
    if (!made) return unexpected_error(made);
    const Shader stored = std::move(*made);
    const ShaderHandle handle = shaders_.insert(stored);
    if (handle) return handle;
    return fail(kFull, "hết ô trong bảng shader");
}

Result<PipelineHandle> D3d11Device::create_pipeline(const GraphicsPipelineDesc& desc) {
    Result<Pipeline> built = build_graphics(*this, desc);
    if (!built) return unexpected_error(built);
    const Pipeline stored = std::move(*built);
    name_pipeline(stored, desc.name);
    const PipelineHandle handle = pipelines_.insert(stored);
    if (handle) return handle;
    return fail(kFull, "hết ô trong bảng pipeline");
}

Result<PipelineHandle> D3d11Device::create_pipeline(const ComputePipelineDesc& desc) {
    Result<Pipeline> built = build_compute(*this, desc);
    if (!built) return unexpected_error(built);
    const Pipeline stored = std::move(*built);
    name_pipeline(stored, desc.name);
    const PipelineHandle handle = pipelines_.insert(stored);
    if (handle) return handle;
    return fail(kFull, "hết ô trong bảng pipeline");
}

Result<BindGroupHandle> D3d11Device::create_bind_group(const BindGroupDesc& desc) {
    const Pipeline* const pipeline = find(desc.pipeline);
    if (pipeline == nullptr) return fail(kBad, "nhóm gắn: pipeline đã chết");
    if (desc.space >= kMaxBindGroups) return fail(kBad, "nhóm gắn: space vượt kMaxBindGroups");
    const SpaceLayout& space = pipeline->layout.spaces.at(desc.space);
    const DeviceCaps& limits = caps();
    const Status sized = check_capacity(space, desc.capacity, limits);
    if (!sized) return unexpected_error(sized);
    const Status checked = check_entries(space, desc.entries, desc.capacity, true);
    if (!checked) return unexpected_error(checked);
    BindGroup group;
    group.space = desc.space;
    GroupFill fill;
    fill.device = this;
    fill.group = &group;
    fill.space = &space;
    fill.desc = &desc;
    const Status written = fill_group(fill);
    if (!written) return unexpected_error(written);
    const BindGroup stored = std::move(group);
    const BindGroupHandle handle = groups_.insert(stored);
    if (handle) return handle;
    return fail(kFull, "hết ô trong bảng nhóm gắn");
}

Status D3d11Device::update_bind_group(BindGroupHandle group, EntrySpan entries) {
    BindGroup* const found = find(group);
    if (found == nullptr) return fail(kBad, "update_bind_group: nhóm đã chết");
    Status status = ok();
    const auto end = entries.end();
    for (auto entry = entries.begin(); entry != end && status; ++entry) {
        status = update_one(*this, *found, *entry);
    }
    return status;
}

void D3d11Device::destroy(ShaderHandle handle) {
    std::optional<Shader> removed = shaders_.remove(handle);
    if (!removed) return;
    retire_com(*this, removed->code);
}

void D3d11Device::destroy(PipelineHandle handle) {
    std::optional<Pipeline> removed = pipelines_.remove(handle);
    if (!removed) return;
    release_pipeline(*this, *removed);
}

void D3d11Device::destroy(BindGroupHandle handle) {
    std::optional<BindGroup> removed = groups_.remove(handle);
    if (!removed) return;
    release_group(*this, *removed);
}

// NOLINTEND(cppcoreguidelines-pro-type-union-access,bugprone-invalid-enum-default-initialization)

} // namespace game::gpu::d3d11
