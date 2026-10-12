// Phản chiếu shader: tài nguyên, bố cục cbuffer, đầu vào, đầu ra của một stage, và phép gộp các
// stage thành phản chiếu của cả chương trình. Thay IShaderReflection.h của _Ref, vốn chỉ còn tên
// đầu vào đỉnh và cỡ nhóm compute: bố cục descriptor ở đó khai tay hai lần bằng macro SRT, một lần
// cho C++ và một lần cho shader. Ở đây một cấu trúc dùng cho cả DXIL lẫn SPIR-V, mỗi tài nguyên
// mang cả hai hệ toạ độ (register của D3D12, set và binding của Vulkan), nên tầng đồ hoạ dựng root
// signature và descriptor set layout từ cùng một nguồn. Cùng một tệp HLSL phải ra hai phản chiếu
// bằng nhau; phép thử của module giữ điều đó.
// Nguồn: Forge2 src/shader/reflection.hpp@d7fcd76. Khác gốc: bỏ {} thừa ở thành viên string, vector
// và StageSet của các struct.
#pragma once

#include "shader/types.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::shader {

enum class ResourceKind : std::uint8_t {
    kSampler,
    // Texture1D tới TextureCubeArray, chỉ đọc.
    kTexture,
    kRwTexture,
    // StructuredBuffer và ByteAddressBuffer.
    kBuffer,
    // RWStructuredBuffer, RWByteAddressBuffer, Append và Consume.
    kRwBuffer,
    // Buffer<T>.
    kTexelBuffer,
    // RWBuffer<T>.
    kRwTexelBuffer,
    // cbuffer và ConstantBuffer<T>.
    kUniformBuffer,
    // Khối khai bằng F2_PUSH_CONSTANTS (shader/builtin.hpp): push constant của Vulkan, root
    // constant của D3D12.
    kPushConstant,
    kAccelerationStructure,
    // SubpassInput; chỉ SPIR-V có.
    kInputAttachment,
};

// Lớp register của HLSL: b, t, u, s.
enum class RegisterType : std::uint8_t {
    kConstant,
    kResource,
    kUnordered,
    kSampler,
};

[[nodiscard]] RegisterType register_type(ResourceKind kind) noexcept;

// Khoảng cách giữa các lớp register trong một descriptor set của Vulkan: binding = slot + độ dịch,
// với b ở 0, t ở 1000, u ở 2000, s ở 3000 (cách của Wicked). Một mảng chiếm đúng một binding nên
// giới hạn là chỉ số register đầu của mỗi tài nguyên phải dưới kShiftRange.
inline constexpr std::uint32_t kShiftRange = 1000;

[[nodiscard]] constexpr std::uint32_t binding_shift(RegisterType group) noexcept {
    return kShiftRange * std::to_underlying(group);
}

// Register space dành riêng cho khối push constant ở phía D3D12; phía Vulkan khối ấy không có set.
inline constexpr std::uint32_t kPushSpace = 127;

inline constexpr std::uint32_t kNoBlock = ~std::uint32_t{0};

enum class TextureShape : std::uint8_t {
    kNone,
    kTex1D,
    kTex2D,
    kTex3D,
    kCube,
};

// Kiểu vô hướng của một biến, một thành phần đỉnh hay một mẫu texture. bool của HLSL nằm trong
// cbuffer là 4 byte và DXC ghi nó thành uint ở SPIR-V, nên cả hai đích báo UInt.
enum class Scalar : std::uint8_t {
    kNone,
    kInt,
    kUInt,
    kFloat,
    kStruct,
};

struct Resource {
    std::string name;
    ResourceKind kind = ResourceKind::kTexture;
    // Register space của D3D12, cũng là descriptor set của Vulkan.
    std::uint32_t space = 0;
    // Chỉ số register trong lớp của nó (t3 là 3).
    std::uint32_t slot = 0;
    // Binding của Vulkan: slot cộng binding_shift của lớp.
    std::uint32_t binding = 0;
    // Số phần tử của mảng; 0 là mảng không chặn.
    std::uint32_t count = 1;
    TextureShape shape = TextureShape::kNone;
    bool array = false;
    bool multisample = false;
    // SamplerComparisonState.
    bool comparison = false;
    // ByteAddressBuffer và RWByteAddressBuffer.
    bool raw = false;
    Scalar sample = Scalar::kNone;
    // SpvImageFormat khi shader khai [[vk::image_format]]; 0 khi không khai và ở DXIL.
    std::uint32_t image_format = 0;
    // Cỡ phần tử của buffer có cấu trúc; 0 cho loại khác.
    std::uint32_t stride = 0;
    // Chỉ số trong blocks của UniformBuffer và PushConstant; kNoBlock cho loại khác.
    std::uint32_t block = kNoBlock;
    StageSet stages;

    [[nodiscard]] bool operator==(const Resource&) const = default;
};

// Một biến ở cấp ngoài cùng của cbuffer. float3 là rows 1, columns 3; float4x3 là rows 4,
// columns 3.
struct Variable {
    std::string name;
    std::uint32_t offset = 0;
    std::uint32_t size = 0;
    Scalar scalar = Scalar::kNone;
    std::uint8_t bits = 0;
    std::uint8_t rows = 0;
    std::uint8_t columns = 0;
    // Số phần tử của mảng; 0 khi không phải mảng.
    std::uint32_t elements = 0;

    [[nodiscard]] bool operator==(const Variable&) const = default;
};

struct Block {
    std::string name;
    std::uint32_t size = 0;
    std::vector<Variable> variables;

    [[nodiscard]] bool operator==(const Block&) const = default;
};

// Một phần tử của chữ ký vào hay ra, không tính giá trị hệ thống (SV_Position, SV_VertexID); đầu ra
// của pixel shader là SV_Target với index là số render target.
struct Attribute {
    // "TEXCOORD" của TEXCOORD1; index là 1.
    std::string semantic;
    std::uint32_t index = 0;
    // Location của Vulkan; ở DXIL là thứ tự khai báo, trùng với location mà DXC gán.
    std::uint32_t location = 0;
    Scalar scalar = Scalar::kNone;
    std::uint8_t bits = 0;
    std::uint8_t components = 0;

    [[nodiscard]] bool operator==(const Attribute&) const = default;
};

struct StageReflection {
    Stage stage = Stage::kVertex;
    std::string entry;
    // Xếp theo (space, lớp register, slot); push constant đứng theo kPushSpace.
    std::vector<Resource> resources;
    std::vector<Block> blocks;
    // Xếp theo location.
    std::vector<Attribute> inputs;
    std::vector<Attribute> outputs;
    // numthreads của compute, mesh, amplification; 0 cho stage khác.
    std::array<std::uint32_t, 3> group_size{};
    // Số điểm điều khiển của hull shader.
    std::uint32_t control_points = 0;

    [[nodiscard]] bool operator==(const StageReflection&) const = default;
};

// Xếp resources và các chữ ký về thứ tự chuẩn, đánh lại chỉ số block. Hai bộ phản chiếu (DXIL,
// SPIR-V) gọi trước khi trả kết quả.
void normalize(StageReflection& reflection);

// Phản chiếu của cả chương trình (addPipelineReflection của _Ref).
struct ProgramReflection {
    StageSet stages;
    // Hợp của mọi stage, mỗi (space, lớp, slot) một mục, stages là các stage dùng nó.
    std::vector<Resource> resources;
    std::vector<Block> blocks;
    // Đầu vào của vertex shader và đầu ra của pixel shader.
    std::vector<Attribute> inputs;
    std::vector<Attribute> outputs;
    std::array<std::uint32_t, 3> group_size{};
    std::uint32_t control_points = 0;

    [[nodiscard]] bool operator==(const ProgramReflection&) const = default;
};

// Gộp các stage của một chương trình. InvalidArgument khi: hai stage trùng loại; cùng một chỗ gắn
// mà khác loại, số phần tử, hình texture hay bố cục cbuffer; cùng tên mà khác chỗ gắn (_Ref chỉ so
// tên).
[[nodiscard]] Result<ProgramReflection> merge(std::span<const StageReflection> stages);

// Đầu vào của stage sau phải có ở đầu ra của stage trước, cùng semantic, kiểu và số thành phần.
// D3D12 báo lỗi này lúc tạo pipeline bằng một HRESULT không tên; Vulkan chỉ báo khi bật validation.
[[nodiscard]] Status check_interface(const StageReflection& producer, const StageReflection& consumer);

// Dạng nhị phân dùng trong gói shader (shader/package.hpp).
[[nodiscard]] std::vector<std::byte> encode(const StageReflection& reflection);
// Corrupt khi dữ liệu cụt hay mang giá trị ngoài miền.
[[nodiscard]] Result<StageReflection> decode(std::span<const std::byte> data);

// XXH3-64 của dạng nhị phân: khoá cache layout và pipeline cho tầng đồ hoạ.
[[nodiscard]] std::uint64_t fingerprint(const StageReflection& reflection);
[[nodiscard]] std::uint64_t fingerprint(const ProgramReflection& reflection);

// Bản chữ nhiều dòng cho log và cho `f2-shader show`.
[[nodiscard]] std::string describe(const StageReflection& reflection);

[[nodiscard]] std::string_view name(ResourceKind kind) noexcept;
[[nodiscard]] std::string_view name(Scalar scalar) noexcept;

} // namespace game::shader
