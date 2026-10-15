/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/types.hpp
 *  PHÂN HỆ   : Gpu / Types
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểu nền của tầng đồ hoạ (RHI): backend, cờ, phép so sánh, trộn màu, hình
 *    học lời gọi vẽ — phần không gắn với tài nguyên nào. Fork từ rhi/types.hpp
 *    của Platium; phủ các enum tương ứng trong Graphics/Interfaces/IGraphics.h
 *    của _Ref và wiGraphics.h của Wicked. Không tên nào lấy của Vulkan hay
 *    D3D12: khái niệm chỉ một phía có thì nằm sau một khả năng của thiết bị
 *    (DeviceCaps). Quy ước chốt một lần cho cả hai backend: NDC có Y hướng lên,
 *    độ sâu [0, 1], mặt trước ngược chiều kim đồng hồ, độ sâu đảo (gần là 1, xa
 *    là 0). Backend Vulkan bù trục Y bằng viewport chiều cao âm, nên ma trận
 *    chiếu của module math dùng chung cho cả hai mà không lật gì.
 *  - Nguồn: Forge2 src/gpu/types.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố
 *    k.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>
#include <type_traits>
#include <utility>

namespace game::gpu {

enum class Backend : std::uint8_t {
    kVulkan,
    kD3D12,
    kD3D11,
    // OpenGL 4.3 trên Windows, OpenGL ES 3.1 trên Android. Đường cuối khi không có Vulkan 1.3.
    kGles,
};

// "vulkan", "d3d12", "d3d11", "gles".
[[nodiscard]] std::string_view name(Backend backend) noexcept;
// Không phân biệt hoa thường; rỗng khi không phải tên backend.
[[nodiscard]] std::optional<Backend> parse_backend(std::string_view text) noexcept;

// Enum dạng cờ khai vào đây thì có toán tử bit; viết tay bốn toán tử cho từng enum là nhân bản.
template <class E>
inline constexpr bool kIsFlags = false;

template <class E>
concept Flags = std::is_enum_v<E> && kIsFlags<E>;

template <Flags E>
[[nodiscard]] constexpr E operator|(E left, E right) noexcept {
    return static_cast<E>(std::to_underlying(left) | std::to_underlying(right));
}

template <Flags E>
[[nodiscard]] constexpr E operator&(E left, E right) noexcept {
    return static_cast<E>(std::to_underlying(left) & std::to_underlying(right));
}

template <Flags E>
constexpr E& operator|=(E& left, E right) noexcept {
    left = left | right;
    return left;
}

// Mọi bit của wanted đều bật trong value.
template <Flags E>
[[nodiscard]] constexpr bool has(E value, E wanted) noexcept {
    return (std::to_underlying(value) & std::to_underlying(wanted)) == std::to_underlying(wanted);
}

// Có ít nhất một bit chung.
template <Flags E>
[[nodiscard]] constexpr bool overlaps(E value, E other) noexcept {
    return (std::to_underlying(value) & std::to_underlying(other)) != 0;
}

// Ba loại hàng đợi có nguyên ở cả hai API: graphics, compute, transfer của Vulkan; DIRECT, COMPUTE,
// COPY của D3D12.
enum class QueueType : std::uint8_t {
    kGraphics,
    kCompute,
    kCopy,
};

inline constexpr std::size_t kQueueCount = 3;

enum class CompareOp : std::uint8_t {
    kNever,
    kLess,
    kEqual,
    kLessOrEqual,
    kGreater,
    kNotEqual,
    kGreaterOrEqual,
    kAlways,
};

enum class StencilOp : std::uint8_t {
    kKeep,
    kZero,
    kReplace,
    kIncrementClamp,
    kDecrementClamp,
    kInvert,
    kIncrementWrap,
    kDecrementWrap,
};

enum class BlendFactor : std::uint8_t {
    kZero,
    kOne,
    kSrcColor,
    kOneMinusSrcColor,
    kDstColor,
    kOneMinusDstColor,
    kSrcAlpha,
    kOneMinusSrcAlpha,
    kDstAlpha,
    kOneMinusDstAlpha,
    kSrcAlphaSaturate,
    // Hằng đặt bằng CommandList::set_blend_constants.
    kConstant,
    kOneMinusConstant,
};

enum class BlendOp : std::uint8_t {
    kAdd,
    kSubtract,
    kReverseSubtract,
    kMin,
    kMax,
};

enum class CullMode : std::uint8_t {
    kNone,
    kFront,
    kBack,
};

// Chiều quấn của mặt trước trong NDC. Vì Vulkan bù trục Y bằng viewport chứ không bằng ma trận,
// giá trị này không phải đảo theo backend.
enum class FrontFace : std::uint8_t {
    kCounterClockwise,
    kClockwise,
};

enum class FillMode : std::uint8_t {
    kSolid,
    kWireframe,
};

enum class Topology : std::uint8_t {
    kPointList,
    kLineList,
    kLineStrip,
    kTriangleList,
    kTriangleStrip,
    // Cho tessellation; số điểm điều khiển ở GraphicsPipelineDesc::patch_points.
    kPatchList,
};

enum class IndexType : std::uint8_t {
    kUint16,
    kUint32,
};

// Việc làm với attachment lúc bắt đầu và lúc kết thúc vẽ. Không có mặc định ở chỗ dùng: trên GPU
// chia ô (mọi điện thoại), mỗi lần nạp và ghi attachment là băng thông thật, nên phải khai tay.
enum class LoadOp : std::uint8_t {
    kLoad,
    kClear,
    kDiscard,
};

enum class StoreOp : std::uint8_t {
    kStore,
    kDiscard,
};

// Gốc ở góc trên trái của đích vẽ, y hướng xuống, tính bằng điểm ảnh — như cả hai API. (NDC thì Y
// hướng lên; backend Vulkan tự lật viewport.)
struct Viewport {
    float x = 0.0F;
    float y = 0.0F;
    float width = 0.0F;
    float height = 0.0F;
    float min_depth = 0.0F;
    float max_depth = 1.0F;
};

struct Scissor {
    std::int32_t x = 0;
    std::int32_t y = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

struct ClearColor {
    float red = 0.0F;
    float green = 0.0F;
    float blue = 0.0F;
    float alpha = 1.0F;

    friend constexpr bool operator==(const ClearColor&, const ClearColor&) = default;
};

// Độ sâu xoá mặc định là 0: độ sâu đảo, xa là 0.
struct ClearDepth {
    float depth = 0.0F;
    std::uint32_t stencil = 0;

    friend constexpr bool operator==(const ClearDepth&, const ClearDepth&) = default;
};

// Trần cứng; mọi mảng cố định ở tầng trên lấy số từ đây.
inline constexpr std::uint32_t kMaxColorTargets = 8;
inline constexpr std::uint32_t kMaxVertexBuffers = 8;
inline constexpr std::uint32_t kMaxVertexAttributes = 16;
// Số nhóm gắn (register space 0 tới kMaxBindGroups - 1) của một pipeline.
inline constexpr std::uint32_t kMaxBindGroups = 8;
// Số mảng không chặn của một pipeline. Trần sức chứa của mỗi mảng (DeviceCaps::max_unbounded) là
// một phần tư giới hạn của thiết bị, nên ba mảng cộng mọi chỗ gắn cỡ cố định vẫn nằm trong giới
// hạn.
inline constexpr std::uint32_t kMaxUnboundedArrays = 3;
// Mức Vulkan bảo đảm cho maxPushConstantsSize; root signature của D3D12 có 64 DWORD cho mọi thứ.
inline constexpr std::uint32_t kMaxPushBytes = 128;

// Bước dòng và offset bắt buộc của dữ liệu ảnh trong buffer trung chuyển khi chép sang texture:
// D3D12_TEXTURE_DATA_PITCH_ALIGNMENT và D3D12_TEXTURE_DATA_PLACEMENT_ALIGNMENT. Vulkan không đòi
// nhưng nhận. Chỗ gọi dựng dữ liệu theo hai số này thì chạy được ở cả hai backend.
inline constexpr std::uint32_t kTextureRowAlignment = 256;
inline constexpr std::uint32_t kTextureOffsetAlignment = 512;

// Căn của một cbuffer trong buffer: BufferRange::offset là bội của số này, và buffer phải còn đủ
// chỗ cho cỡ cbuffer làm tròn lên bội của nó. D3D12 bắt đúng 256; Vulkan cho phép thiết bị đòi tới
// 256. Một hằng thay cho một giới hạn hỏi lúc chạy: dữ liệu dựng một lần chạy được mọi nơi.
inline constexpr std::uint32_t kUniformAlignment = 256;

inline constexpr std::uint64_t kWholeSize = ~std::uint64_t{0};
inline constexpr std::uint32_t kAllMips = ~std::uint32_t{0};
inline constexpr std::uint32_t kAllLayers = ~std::uint32_t{0};

} // namespace game::gpu
