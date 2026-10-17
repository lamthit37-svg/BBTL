/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/shader/dxil.cpp
 *  PHÂN HỆ   : Shader / Dxil
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc phản chiếu container DXIL qua giao diện phản chiếu của D3D12. Bảng
 *    thành phần đánh chỉ số bằng enum SDK; static_assert bắt bảng lệch enum.
 *    Trong cbuffer, cột ma trận và phần tử mảng nằm trên biên 16 byte. Nguồn:
 *    Forge2 src/shader/dxil.cpp@d7fcd76.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: macro của windows.h lấy từ core/win32.hpp; Block gán name sau khi khai; thân vòng có
// nhánh tách thành hàm; bỏ phản chiếu thư viện nhiều hàm (Slang không dịch Stage::kLibrary);
// add_resource nhận thẳng ID3D12ShaderReflection; location vào ra theo semantic khi
// Locations::kSemantic; lớp bọc _MatrixStorage_ của Slang báo lại thành ma trận.

#include "shader/dxil.hpp"

#include "shader/failure.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include "core/error.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <d3d12shader.h>
#include <d3dcommon.h>
#include <winerror.h>

#include <algorithm>
#include <array>
#include <bit>
#include <climits>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::shader {

namespace {

// Độ sâu tối đa khi đi theo struct lồng nhau trong cbuffer.
constexpr int kMaxDepth = 8;
// cbuffer của HLSL xếp mỗi cột ma trận và mỗi phần tử mảng vào biên 16 byte.
constexpr std::uint32_t kRegister = 16;

struct Numeric {
    Scalar scalar = Scalar::kNone;
    std::uint8_t bits = 0;
};

// Kiểu thành phần của chữ ký, đánh chỉ số bằng D3D_REGISTER_COMPONENT_TYPE.
constexpr std::array<Numeric, 10> kComponents{
    Numeric{.scalar = Scalar::kNone, .bits = 0},
    Numeric{.scalar = Scalar::kUInt, .bits = 32},
    Numeric{.scalar = Scalar::kInt, .bits = 32},
    Numeric{.scalar = Scalar::kFloat, .bits = 32},
    Numeric{.scalar = Scalar::kUInt, .bits = 16},
    Numeric{.scalar = Scalar::kInt, .bits = 16},
    Numeric{.scalar = Scalar::kFloat, .bits = 16},
    Numeric{.scalar = Scalar::kUInt, .bits = 64},
    Numeric{.scalar = Scalar::kInt, .bits = 64},
    Numeric{.scalar = Scalar::kFloat, .bits = 64},
};
static_assert(D3D_REGISTER_COMPONENT_FLOAT64 == 9, "bảng kComponents lệch enum của SDK");

// Kiểu mẫu của texture, đánh chỉ số bằng D3D_RESOURCE_RETURN_TYPE.
constexpr std::array<Scalar, 9> kSamples{
    Scalar::kNone,
    Scalar::kFloat,
    Scalar::kFloat,
    Scalar::kInt,
    Scalar::kUInt,
    Scalar::kFloat,
    Scalar::kNone,
    Scalar::kFloat,
    Scalar::kNone,
};
static_assert(D3D_RETURN_TYPE_CONTINUED == 8, "bảng kSamples lệch enum của SDK");

struct Dimension {
    TextureShape shape = TextureShape::kNone;
    bool array = false;
    bool multisample = false;
};

// Hình texture, đánh chỉ số bằng D3D_SRV_DIMENSION.
constexpr std::array<Dimension, 12> kDimensions{
    Dimension{.shape = TextureShape::kNone, .array = false, .multisample = false},
    Dimension{.shape = TextureShape::kNone, .array = false, .multisample = false},
    Dimension{.shape = TextureShape::kTex1D, .array = false, .multisample = false},
    Dimension{.shape = TextureShape::kTex1D, .array = true, .multisample = false},
    Dimension{.shape = TextureShape::kTex2D, .array = false, .multisample = false},
    Dimension{.shape = TextureShape::kTex2D, .array = true, .multisample = false},
    Dimension{.shape = TextureShape::kTex2D, .array = false, .multisample = true},
    Dimension{.shape = TextureShape::kTex2D, .array = true, .multisample = true},
    Dimension{.shape = TextureShape::kTex3D, .array = false, .multisample = false},
    Dimension{.shape = TextureShape::kCube, .array = false, .multisample = false},
    Dimension{.shape = TextureShape::kCube, .array = true, .multisample = false},
    Dimension{.shape = TextureShape::kNone, .array = false, .multisample = false},
};
static_assert(D3D_SRV_DIMENSION_BUFFEREX == 11, "bảng kDimensions lệch enum của SDK");

template <class T, std::size_t N>
[[nodiscard]] T lookup(const std::array<T, N>& table, std::size_t index) noexcept {
    if (index >= N) return T{};
    return table.at(index);
}

[[nodiscard]] constexpr std::uint32_t round_up(std::uint32_t value) noexcept {
    return (value + kRegister - 1) / kRegister * kRegister;
}

// Khác gốc: tách bit khỏi numeric cho trần cognitive.
[[nodiscard]] std::uint8_t bits_of(D3D_SHADER_VARIABLE_TYPE type) noexcept {
    const bool wide = type == D3D_SVT_DOUBLE || type == D3D_SVT_INT64 || type == D3D_SVT_UINT64;
    const bool half = type == D3D_SVT_FLOAT16 || type == D3D_SVT_INT16 || type == D3D_SVT_UINT16;
    const std::uint8_t narrow_bits = half ? 16 : 32;
    return wide ? 64 : narrow_bits;
}

// Khác gốc: tách khỏi numeric. float, double, half và min-float.
[[nodiscard]] bool is_real(D3D_SHADER_VARIABLE_TYPE type) noexcept {
    const bool real = type == D3D_SVT_FLOAT || type == D3D_SVT_DOUBLE || type == D3D_SVT_FLOAT16;
    const bool min_float = type == D3D_SVT_MIN16FLOAT || type == D3D_SVT_MIN10FLOAT;
    return real || min_float || type == D3D_SVT_MIN8FLOAT;
}

// Khác gốc: tách khỏi numeric. int đủ rộng và min-int.
[[nodiscard]] bool is_whole(D3D_SHADER_VARIABLE_TYPE type) noexcept {
    const bool whole = type == D3D_SVT_INT || type == D3D_SVT_INT16 || type == D3D_SVT_INT64;
    const bool min_int = type == D3D_SVT_MIN16INT || type == D3D_SVT_MIN12INT;
    return whole || min_int;
}

// D3D_SHADER_VARIABLE_TYPE có hơn sáu chục giá trị, phần lớn là kiểu đối tượng; chỉ kiểu số mới
// xuất hiện trong cbuffer. bool chiếm 4 byte và báo UInt như phía SPIR-V.
[[nodiscard]] Numeric numeric(D3D_SHADER_VARIABLE_TYPE type) noexcept {
    const std::uint8_t bits = bits_of(type);
    if (is_real(type)) return Numeric{.scalar = Scalar::kFloat, .bits = bits};
    if (is_whole(type)) return Numeric{.scalar = Scalar::kInt, .bits = bits};
    return Numeric{.scalar = Scalar::kUInt, .bits = bits};
}

[[nodiscard]] std::uint32_t type_size(ID3D12ShaderReflectionType* type, int depth);

// Trần kMaxDepth; chỉ số rồi độ sâu (lệch PH-08, API-03).
// Khác gốc: tách thân vòng. GetDesc lỗi thì bỏ thành viên.
// NOLINTNEXTLINE(misc-no-recursion,bugprone-easily-swappable-parameters)
[[nodiscard]] std::uint32_t member_end(ID3D12ShaderReflectionType* type, UINT index, int depth) {
    ID3D12ShaderReflectionType* member = type->GetMemberTypeByIndex(index);
    D3D12_SHADER_TYPE_DESC desc{};
    if (FAILED(member->GetDesc(&desc))) return 0;
    return desc.Offset + type_size(member, depth + 1);
}

// Cuối của thành viên xa nhất, không đệm đuôi.
// Trần kMaxDepth; số thành viên rồi độ sâu (lệch PH-08, API-03).
// NOLINTNEXTLINE(misc-no-recursion,bugprone-easily-swappable-parameters)
[[nodiscard]] std::uint32_t struct_size(ID3D12ShaderReflectionType* type, UINT members, int depth) {
    std::uint32_t size = 0;
    for (UINT index = 0; index < members; ++index) {
        size = std::max(size, member_end(type, index, depth));
    }
    return size;
}

// Đệ quy, trần kMaxDepth (PH-08).
// NOLINTNEXTLINE(misc-no-recursion)
[[nodiscard]] std::uint32_t element_size(ID3D12ShaderReflectionType* type, const D3D12_SHADER_TYPE_DESC& desc,
    int depth) {
    if (desc.Class == D3D_SVC_STRUCT) return struct_size(type, desc.Members, depth);
    const std::uint32_t bytes = numeric(desc.Type).bits / 8U;
    const std::uint32_t rows = std::max<std::uint32_t>(desc.Rows, 1);
    const std::uint32_t columns = std::max<std::uint32_t>(desc.Columns, 1);
    // column_major (mặc định của HLSL): columns cột, mỗi cột rows thành phần, cột nào cũng bắt đầu
    // ở biên 16 byte. row_major thì ngược lại.
    if (desc.Class == D3D_SVC_MATRIX_COLUMNS) {
        return (round_up(rows * bytes) * (columns - 1)) + (rows * bytes);
    }
    if (desc.Class == D3D_SVC_MATRIX_ROWS) {
        return (round_up(columns * bytes) * (rows - 1)) + (columns * bytes);
    }
    return rows * columns * bytes;
}

// Đệ quy, trần kMaxDepth (PH-08).
// NOLINTNEXTLINE(misc-no-recursion)
[[nodiscard]] std::uint32_t type_size(ID3D12ShaderReflectionType* type, int depth) {
    D3D12_SHADER_TYPE_DESC desc{};
    const bool readable = depth < kMaxDepth && SUCCEEDED(type->GetDesc(&desc));
    if (!readable) return 0;
    const std::uint32_t single = element_size(type, desc, depth);
    if (desc.Elements == 0) return single;
    return (round_up(single) * (desc.Elements - 1)) + single;
}

struct MatrixShape {
    std::uint8_t rows = 0;
    std::uint8_t columns = 0;
};

[[nodiscard]] constexpr bool is_dimension(char letter) noexcept {
    return letter >= '1' && letter <= '4';
}

// Slang hạ ma trận khai layout khác layout chung của module (row_major trong module theo cột, hay
// ngược lại) về struct `_MatrixStorage_<kiểu><R>x<C><layout>_N` có một thành viên `data` là mảng
// vector; DXC đặt tên kiểu thêm tiền tố "struct.". R và C đọc từ tên; nullopt khi không phải dạng
// ấy.
[[nodiscard]] std::optional<MatrixShape> storage_shape(std::string_view name) noexcept {
    constexpr std::string_view kStruct = "struct.";
    constexpr std::string_view kStorage = "_MatrixStorage_";
    if (name.starts_with(kStruct)) name.remove_prefix(kStruct.size());
    if (!name.starts_with(kStorage)) return std::nullopt;
    name.remove_prefix(kStorage.size());
    const std::size_t digit = name.find_first_of("1234");
    if (digit == std::string_view::npos) return std::nullopt;
    const std::string_view dims = name.substr(digit, 3);
    const bool crossed = dims.size() == 3 && dims[1] == 'x';
    const bool shaped = crossed && is_dimension(dims[0]) && is_dimension(dims[2]);
    if (!shaped) return std::nullopt;
    const auto rows = static_cast<std::uint8_t>(dims[0] - '0');
    const auto columns = static_cast<std::uint8_t>(dims[2] - '0');
    return MatrixShape{.rows = rows, .columns = columns};
}

// Kiểu số của thành viên data trong lớp bọc ma trận; nullopt khi struct không đúng dạng ấy.
[[nodiscard]] std::optional<Numeric> storage_numeric(ID3D12ShaderReflectionType* type,
    const D3D12_SHADER_TYPE_DESC& desc) {
    if (desc.Members != 1) return std::nullopt;
    ID3D12ShaderReflectionType* data = type->GetMemberTypeByIndex(0);
    D3D12_SHADER_TYPE_DESC inner{};
    if (FAILED(data->GetDesc(&inner))) return std::nullopt;
    const bool numeric_member = inner.Class == D3D_SVC_VECTOR || inner.Class == D3D_SVC_SCALAR;
    if (!numeric_member) return std::nullopt;
    return numeric(inner.Type);
}

// Struct thật báo Scalar::kStruct. Lớp bọc ma trận của Slang báo lại ma trận R×C như phía SPIR-V
// thấy: bố cục byte giống hệt, chỉ hình kiểu khác.
[[nodiscard]] Variable struct_variable(ID3D12ShaderReflectionType* type,
    const D3D12_SHADER_TYPE_DESC& desc, Variable variable) {
    variable.scalar = Scalar::kStruct;
    const std::string_view name = desc.Name != nullptr ? desc.Name : "";
    const std::optional<MatrixShape> shape = storage_shape(name);
    if (!shape) return variable;
    const std::optional<Numeric> element = storage_numeric(type, desc);
    if (!element) return variable;
    variable.scalar = element->scalar;
    variable.bits = element->bits;
    variable.rows = shape->rows;
    variable.columns = shape->columns;
    return variable;
}

// Một biến của cbuffer. size là cỡ do D3D báo; nullopt thì tính từ kiểu (thành viên của
// ConstantBuffer<T>, D3D không báo cỡ từng thành viên).
[[nodiscard]] Variable variable_of(std::string name, std::uint32_t offset, ID3D12ShaderReflectionType* type,
    std::optional<std::uint32_t> size) {
    Variable variable;
    variable.name = std::move(name);
    variable.offset = offset;
    variable.size = size.value_or(type_size(type, 0));
    D3D12_SHADER_TYPE_DESC desc{};
    if (FAILED(type->GetDesc(&desc))) return variable;
    variable.elements = desc.Elements;
    if (desc.Class == D3D_SVC_STRUCT) return struct_variable(type, desc, std::move(variable));
    const Numeric shape = numeric(desc.Type);
    variable.scalar = shape.scalar;
    variable.bits = shape.bits;
    variable.rows = static_cast<std::uint8_t>(std::min<UINT>(desc.Rows, UCHAR_MAX));
    variable.columns = static_cast<std::uint8_t>(std::min<UINT>(desc.Columns, UCHAR_MAX));
    return variable;
}

void add_variable(ID3D12ShaderReflectionVariable* variable, Block& block) {
    D3D12_SHADER_VARIABLE_DESC desc{};
    if (FAILED(variable->GetDesc(&desc))) return;
    block.variables.push_back(variable_of(desc.Name, desc.StartOffset, variable->GetType(), desc.Size));
}

// ConstantBuffer<T> tên: D3D báo một cbuffer chứa đúng một biến cùng tên, kiểu struct T. Trả kiểu
// ấy để mở ra từng thành viên, như phía SPIR-V thấy; nullptr khi là cbuffer thường.
[[nodiscard]] ID3D12ShaderReflectionType* wrapped_struct(ID3D12ShaderReflectionConstantBuffer* buffer,
    const D3D12_SHADER_BUFFER_DESC& desc, std::string_view name) {
    if (desc.Variables != 1) return nullptr;
    ID3D12ShaderReflectionVariable* variable = buffer->GetVariableByIndex(0);
    D3D12_SHADER_VARIABLE_DESC variable_desc{};
    if (FAILED(variable->GetDesc(&variable_desc))) return nullptr;
    if (name != variable_desc.Name) return nullptr;
    ID3D12ShaderReflectionType* type = variable->GetType();
    D3D12_SHADER_TYPE_DESC type_desc{};
    if (FAILED(type->GetDesc(&type_desc))) return nullptr;
    return type_desc.Class == D3D_SVC_STRUCT ? type : nullptr;
}

// Khác gốc: thân vòng của add_members tách ra. GetDesc lỗi thì bỏ thành viên.
void add_one_member(ID3D12ShaderReflectionType* type, UINT index, Block& block) {
    ID3D12ShaderReflectionType* member = type->GetMemberTypeByIndex(index);
    D3D12_SHADER_TYPE_DESC member_desc{};
    if (FAILED(member->GetDesc(&member_desc))) return;
    const char* name = type->GetMemberTypeName(index);
    block.variables.push_back(variable_of(name, member_desc.Offset, member, std::nullopt));
}

void add_members(ID3D12ShaderReflectionType* type, Block& block) {
    D3D12_SHADER_TYPE_DESC desc{};
    if (FAILED(type->GetDesc(&desc))) return;
    for (UINT index = 0; index < desc.Members; ++index) {
        add_one_member(type, index, block);
    }
}

[[nodiscard]] Block block_of(ID3D12ShaderReflectionConstantBuffer* buffer, std::string name) {
    Block block;
    block.name = std::move(name);
    D3D12_SHADER_BUFFER_DESC desc{};
    if (FAILED(buffer->GetDesc(&desc))) return block;
    block.size = desc.Size;
    ID3D12ShaderReflectionType* wrapped = wrapped_struct(buffer, desc, block.name);
    if (wrapped != nullptr) add_members(wrapped, block);
    if (wrapped != nullptr) return block;
    for (UINT index = 0; index < desc.Variables; ++index) {
        add_variable(buffer->GetVariableByIndex(index), block);
    }
    return block;
}

// nullopt cho loại module không hỗ trợ.
[[nodiscard]] std::optional<ResourceKind> kind_of(const D3D12_SHADER_INPUT_BIND_DESC& bind) noexcept {
    const bool buffer = bind.Dimension == D3D_SRV_DIMENSION_BUFFER;
    switch (bind.Type) {
    case D3D_SIT_CBUFFER: return bind.Space == kPushSpace ? ResourceKind::kPushConstant : ResourceKind::kUniformBuffer;
    case D3D_SIT_TEXTURE: return buffer ? ResourceKind::kTexelBuffer : ResourceKind::kTexture;
    case D3D_SIT_SAMPLER: return ResourceKind::kSampler;
    case D3D_SIT_UAV_RWTYPED: return buffer ? ResourceKind::kRwTexelBuffer : ResourceKind::kRwTexture;
    case D3D_SIT_STRUCTURED:
    case D3D_SIT_BYTEADDRESS: return ResourceKind::kBuffer;
    case D3D_SIT_UAV_RWSTRUCTURED:
    case D3D_SIT_UAV_RWBYTEADDRESS: return ResourceKind::kRwBuffer;
    case D3D_SIT_UAV_APPEND_STRUCTURED:
    case D3D_SIT_UAV_CONSUME_STRUCTURED:
    case D3D_SIT_UAV_RWSTRUCTURED_WITH_COUNTER: return std::nullopt;
    case D3D_SIT_RTACCELERATIONSTRUCTURE: return ResourceKind::kAccelerationStructure;
    case D3D_SIT_TBUFFER:
    case D3D_SIT_UAV_FEEDBACKTEXTURE: return std::nullopt;
    }
    return std::nullopt;
}

[[nodiscard]] bool is_image(ResourceKind kind) noexcept {
    const bool texture = kind == ResourceKind::kTexture || kind == ResourceKind::kRwTexture;
    const bool texel = kind == ResourceKind::kTexelBuffer || kind == ResourceKind::kRwTexelBuffer;
    return texture || texel;
}

void fill_image(const D3D12_SHADER_INPUT_BIND_DESC& bind, Resource& resource) noexcept {
    const Dimension dimension = lookup(kDimensions, static_cast<std::size_t>(bind.Dimension));
    resource.shape = dimension.shape;
    resource.array = dimension.array;
    resource.multisample = dimension.multisample;
    resource.sample = lookup(kSamples, static_cast<std::size_t>(bind.ReturnType));
}

[[nodiscard]] Resource resource_of(const D3D12_SHADER_INPUT_BIND_DESC& bind, ResourceKind kind) {
    Resource resource;
    resource.name = bind.Name;
    resource.kind = kind;
    resource.space = bind.Space;
    resource.slot = bind.BindPoint;
    const bool push = kind == ResourceKind::kPushConstant;
    resource.binding = push ? 0 : bind.BindPoint + binding_shift(register_type(kind));
    // Mảng không chặn: D3D báo 0, có bản báo UINT_MAX.
    resource.count = bind.BindCount == UINT_MAX ? 0 : bind.BindCount;
    if (is_image(kind)) fill_image(bind, resource);
    resource.comparison = (bind.uFlags & D3D_SIF_COMPARISON_SAMPLER) != 0;
    resource.raw = bind.Type == D3D_SIT_BYTEADDRESS || bind.Type == D3D_SIT_UAV_RWBYTEADDRESS;
    const bool buffer = kind == ResourceKind::kBuffer || kind == ResourceKind::kRwBuffer;
    // Với buffer có cấu trúc, NumSamples mang cỡ phần tử.
    if (buffer && !resource.raw) resource.stride = bind.NumSamples;
    return resource;
}

[[nodiscard]] bool has_place(const StageReflection& reflection, const Resource& resource) noexcept {
    const auto same = [&](const Resource& other) {
        const bool same_class = register_type(other.kind) == register_type(resource.kind);
        return same_class && other.space == resource.space && other.slot == resource.slot;
    };
    return std::ranges::any_of(reflection.resources, same);
}

[[nodiscard]] Status add_resource(ID3D12ShaderReflection& source, UINT index, StageReflection& reflection) {
    // Cấu trúc ra của SDK: enum ReturnType không có giá trị 0, GetResourceBindingDesc ghi đè cả.
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    D3D12_SHADER_INPUT_BIND_DESC bind{};
    const bool readable = SUCCEEDED(source.GetResourceBindingDesc(index, &bind));
    if (!readable || bind.Name == nullptr) return corrupt("phản chiếu DXIL không đọc được");
    const std::optional<ResourceKind> kind = kind_of(bind);
    const bool counted = bind.Type == D3D_SIT_UAV_APPEND_STRUCTURED || bind.Type == D3D_SIT_UAV_CONSUME_STRUCTURED ||
        bind.Type == D3D_SIT_UAV_RWSTRUCTURED_WITH_COUNTER;
    if (!kind && counted) {
        return fail(ErrorCode::kUnsupported, "buffer có bộ đếm không có trên Vulkan", bind.Name);
    }
    if (!kind) {
        return fail(ErrorCode::kUnsupported, "tbuffer và feedback texture không được hỗ trợ", bind.Name);
    }
    if (bind.BindPoint >= kShiftRange) {
        return fail(ErrorCode::kInvalidArgument, "chỉ số register phải dưới 1000", bind.Name);
    }
    Resource resource = resource_of(bind, *kind);
    resource.stages = StageSet(reflection.stage);
    // Hai hàm của một thư viện cùng dùng một tài nguyên.
    if (has_place(reflection, resource)) return ok();
    const bool blocked = *kind == ResourceKind::kUniformBuffer || *kind == ResourceKind::kPushConstant;
    if (blocked) {
        resource.block = static_cast<std::uint32_t>(reflection.blocks.size());
        reflection.blocks.push_back(block_of(source.GetConstantBufferByName(bind.Name), bind.Name));
    }
    reflection.resources.push_back(std::move(resource));
    return ok();
}

[[nodiscard]] char upper(char letter) noexcept {
    const bool lower = letter >= 'a' && letter <= 'z';
    return lower ? static_cast<char>(letter - 'a' + 'A') : letter;
}

// Một phía của chữ ký: danh sách đích và cách tính location.
struct Signature {
    std::vector<Attribute>* list = nullptr;
    Locations locations = Locations::kDeclared;
    // Đầu vào của vertex shader có bảng riêng ở Locations::kSemantic.
    bool vertex_input = false;
};

// SV_Target nhận đúng số của render target. Còn lại theo thứ tự khai báo (Slang gán location của
// SPIR-V cùng thứ tự ấy) hoặc theo bảng semantic_location.
[[nodiscard]] std::optional<std::uint32_t> location_of(const Signature& side,
    const Attribute& attribute, bool target) {
    if (target) return attribute.index;
    const bool declared = side.locations == Locations::kDeclared;
    if (declared) return static_cast<std::uint32_t>(side.list->size());
    return semantic_location(side.vertex_input, attribute.semantic, attribute.index);
}

// Semantic không có trong bảng của semantic_location.
[[nodiscard]] core::Failure off_table(std::string_view word, std::uint32_t number) {
    constexpr ErrorCode kCode = ErrorCode::kInvalidArgument;
    return fail(kCode, "semantic ngoài bảng location", "{}{}", word, number);
}

// Giá trị hệ thống (SV_Position, SV_VertexID...) không vào chữ ký, trừ SV_Target.
[[nodiscard]] Status add_attribute(const D3D12_SIGNATURE_PARAMETER_DESC& parameter,
    const Signature& side) {
    const bool target = parameter.SystemValueType == D3D_NAME_TARGET;
    const bool user = parameter.SystemValueType == D3D_NAME_UNDEFINED;
    const bool is_listed = target || user;
    if (!is_listed || parameter.SemanticName == nullptr) return ok();
    const Numeric shape = lookup(kComponents, static_cast<std::size_t>(parameter.ComponentType));
    Attribute attribute;
    attribute.semantic = parameter.SemanticName;
    std::ranges::transform(attribute.semantic, attribute.semantic.begin(), upper);
    attribute.index = parameter.SemanticIndex;
    const std::optional<std::uint32_t> location = location_of(side, attribute, target);
    if (!location) return off_table(attribute.semantic, attribute.index);
    attribute.location = *location;
    attribute.scalar = shape.scalar;
    attribute.bits = shape.bits;
    attribute.components = static_cast<std::uint8_t>(std::popcount(parameter.Mask));
    side.list->push_back(std::move(attribute));
    return ok();
}

// Khác gốc: thân vòng chữ ký vào tách ra. GetInputParameterDesc lỗi thì bỏ qua.
[[nodiscard]] Status add_input(ID3D12ShaderReflection& shader, UINT index, const Signature& side) {
    D3D12_SIGNATURE_PARAMETER_DESC parameter{};
    if (FAILED(shader.GetInputParameterDesc(index, &parameter))) return ok();
    return add_attribute(parameter, side);
}

// Khác gốc: thân vòng chữ ký ra tách ra. GetOutputParameterDesc lỗi thì bỏ qua.
[[nodiscard]] Status add_output(ID3D12ShaderReflection& shader, UINT index, const Signature& side) {
    D3D12_SIGNATURE_PARAMETER_DESC parameter{};
    if (FAILED(shader.GetOutputParameterDesc(index, &parameter))) return ok();
    return add_attribute(parameter, side);
}

[[nodiscard]] Status add_signatures(ID3D12ShaderReflection& shader, const D3D12_SHADER_DESC& desc,
    Locations locations, StageReflection& reflection) {
    Signature inputs{.list = &reflection.inputs, .locations = locations};
    inputs.vertex_input = reflection.stage == Stage::kVertex;
    const Signature outputs{.list = &reflection.outputs, .locations = locations};
    Status added = ok();
    for (UINT index = 0; index < desc.InputParameters && added; ++index) {
        added = add_input(shader, index, inputs);
    }
    for (UINT index = 0; index < desc.OutputParameters && added; ++index) {
        added = add_output(shader, index, outputs);
    }
    return added;
}

} // namespace

Result<StageReflection> reflect_dxil(ID3D12ShaderReflection& shader, Stage stage,
    std::string_view entry, Locations locations) {
    // Cấu trúc ra của SDK: enum MinFeatureLevel không có giá trị 0, GetDesc ghi đè cả.
    // NOLINTNEXTLINE(bugprone-invalid-enum-default-initialization)
    D3D12_SHADER_DESC desc{};
    if (FAILED(shader.GetDesc(&desc))) return corrupt("phản chiếu DXIL không đọc được");
    StageReflection reflection;
    reflection.stage = stage;
    reflection.entry = std::string(entry);
    Status added = ok();
    for (UINT index = 0; index < desc.BoundResources && added; ++index) {
        added = add_resource(shader, index, reflection);
    }
    if (!added) return pass(added);
    Status signatures = add_signatures(shader, desc, locations, reflection);
    if (!signatures) return pass(signatures);
    if (stage == Stage::kHull) reflection.control_points = desc.cControlPoints;
    const bool threaded = stage == Stage::kCompute || stage == Stage::kMesh;
    if (threaded || stage == Stage::kAmplification) {
        UINT width = 0;
        UINT height = 0;
        UINT depth = 0;
        shader.GetThreadGroupSize(&width, &height, &depth);
        reflection.group_size = {width, height, depth};
    }
    normalize(reflection);
    return reflection;
}

} // namespace game::shader
