/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/resource.hpp
 *  PHÂN HỆ   : Gpu / Resource
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mô tả tài nguyên: buffer, texture, view, sampler — BufferDesc,
 *    TextureDesc, RenderTargetDesc, SamplerDesc của IGraphics.h trong _Ref và
 *    rhi/resource.hpp của Platium. Mọi struct ở đây là mô tả thuần, không giữ
 *    tài nguyên: Device nhận mô tả và trả tay nắm. Khác gốc:
 *  - render target không phải loại tài nguyên riêng: là texture có
 *    TextureUsage::kColorTarget hay kDepthStencilTarget cộng một view (gốc dựng
 *    sẵn descriptor cho từng mip và từng lát);
 *  - mục đích dùng khai bằng cờ ngay lúc tạo, vì Vulkan bắt vậy; D3D12 suy cờ
 *    tài nguyên từ đó;
 *  - TextureUsage::kTransient cho attachment chỉ sống trong một render pass:
 *    GPU chia ô không phải cấp bộ nhớ thật cho nó (gốc và Platium không có);
 *  - bộ nhớ chọn theo ba miền Device, Upload, Readback thay cho
 *    ResourceMemoryUsage bốn giá trị.
 *  - Nguồn: Forge2 src/gpu/resource.hpp@d7fcd76. Khác gốc (so với Forge2):
 *    enumerator mang tiền tố k; bỏ {} thừa của thành viên name ở bốn struct mô
 *    tả.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "gpu/types.hpp"

#include <cstdint>
#include <string_view>

namespace game::gpu {

// Nơi bộ nhớ nằm. Readback tách khỏi Upload vì cách cache khác nhau: đọc từ vùng Upload chậm hàng
// chục lần mà không có lỗi nào báo.
enum class MemoryDomain : std::uint8_t {
    // Bộ nhớ của GPU; CPU không đọc ghi trực tiếp được.
    kDevice,
    // CPU ghi, GPU đọc.
    kUpload,
    // GPU ghi, CPU đọc.
    kReadback,
};

// Giữ kiểu nền của gốc: tám cờ đã lấp kín 8 bit, thu nhỏ thì cờ kế tiếp hết chỗ (lệch KG-06).
// NOLINTNEXTLINE(performance-enum-size)
enum class BufferUsage : std::uint16_t {
    kNone = 0,
    kVertex = 1U << 0U,
    kIndex = 1U << 1U,
    // cbuffer.
    kUniform = 1U << 2U,
    // Buffer, StructuredBuffer, ByteAddressBuffer và bản RW của chúng.
    kStorage = 1U << 3U,
    kIndirect = 1U << 4U,
    kCopySource = 1U << 5U,
    kCopyDest = 1U << 6U,
    // Lấy được địa chỉ GPU (Device::address). Vulkan bắt khai lúc tạo; D3D12 buffer nào cũng có.
    kAddress = 1U << 7U,
};

template <>
inline constexpr bool kIsFlags<BufferUsage> = true;

// Giữ kiểu nền của gốc, cùng lý do với BufferUsage: tám cờ đã lấp kín 8 bit (lệch KG-06).
// NOLINTNEXTLINE(performance-enum-size)
enum class TextureUsage : std::uint16_t {
    kNone = 0,
    kSampled = 1U << 0U,
    // RWTexture: shader đọc ghi trực tiếp.
    kStorage = 1U << 1U,
    kColorTarget = 1U << 2U,
    kDepthStencilTarget = 1U << 3U,
    kCopySource = 1U << 4U,
    kCopyDest = 1U << 5U,
    // Chỉ dùng làm attachment trong một lần vẽ rồi bỏ (độ sâu, đích đa mẫu trước khi resolve).
    // Không kèm được Sampled, Storage hay Copy*.
    kTransient = 1U << 6U,
    // View được khai định dạng khác texture (cặp sRGB và tuyến tính trên cùng vùng nhớ). Phải khai
    // lúc tạo: Vulkan cần MUTABLE_FORMAT, D3D12 cần tài nguyên typeless, và cả hai làm trình điều
    // khiển bỏ vài tối ưu nên không bật sẵn.
    kReinterpret = 1U << 7U,
};

template <>
inline constexpr bool kIsFlags<TextureUsage> = true;

enum class TextureKind : std::uint8_t {
    kTex1D,
    kTex2D,
    kTex2DArray,
    kTex3D,
    kCube,
    kCubeArray,
};

struct BufferDesc {
    // Tên hiện trong RenderDoc, PIX và thông điệp của lớp kiểm tra.
    // Khác gốc: gốc viết name{}; clang-tidy báo thừa nên bỏ, ở đây và ở ba struct mô tả bên dưới.
    std::string_view name;
    std::uint64_t size = 0;
    BufferUsage usage = BufferUsage::kNone;
    MemoryDomain memory = MemoryDomain::kDevice;
};

struct TextureDesc {
    std::string_view name;
    TextureKind kind = TextureKind::kTex2D;
    Format format = Format::kUnknown;
    std::uint32_t width = 0;
    std::uint32_t height = 1;
    // Độ sâu của Tex3D; số lớp của mảng; Cube là 6, CubeArray là bội của 6.
    std::uint32_t depth_or_layers = 1;
    std::uint32_t mip_levels = 1;
    // 1, 2, 4 hoặc 8; trên 1 thì mip_levels phải là 1.
    std::uint32_t samples = 1;
    TextureUsage usage = TextureUsage::kNone;
    // Giá trị xoá mà đích vẽ này thường dùng. D3D12 ghi nó vào tài nguyên để đi đường xoá nhanh;
    // xoá bằng giá trị khác vẫn đúng nhưng chậm hơn và lớp kiểm tra nhắc mỗi khung. Vulkan bỏ qua.
    ClearColor clear_color{};
    ClearDepth clear_depth{};
};

// Phần của định dạng độ sâu kèm stencil mà view nhìn vào.
enum class ViewAspect : std::uint8_t {
    // Mọi phần của định dạng: view làm attachment.
    kAll,
    // Chỉ độ sâu, hoặc chỉ stencil: view để shader lấy mẫu (một view lấy mẫu chỉ được một phần).
    kDepth,
    kStencil,
};

// View tách khỏi texture vì cả hai API đều tách: một mảng texture có một view cả mảng để lấy mẫu
// và một view mỗi lớp để vẽ vào.
struct TextureViewDesc {
    std::string_view name;
    TextureHandle texture{};
    TextureKind kind = TextureKind::kTex2D;
    // Unknown: dùng định dạng của texture. Khác đi là view ép kiểu, cần TextureUsage::kReinterpret
    // và hai định dạng cùng cỡ khối.
    Format format = Format::kUnknown;
    ViewAspect aspect = ViewAspect::kAll;
    std::uint32_t first_mip = 0;
    std::uint32_t mip_count = kAllMips;
    std::uint32_t first_layer = 0;
    std::uint32_t layer_count = kAllLayers;
};

enum class Filter : std::uint8_t {
    kNearest,
    kLinear,
};

enum class AddressMode : std::uint8_t {
    kRepeat,
    kMirrorRepeat,
    kClampToEdge,
    kClampToBorder,
};

// Ba màu viền mà cả hai API có sẵn. Màu tuỳ ý cần phần mở rộng ở Vulkan và sampler động ở D3D12.
enum class BorderColor : std::uint8_t {
    kTransparentBlack,
    kOpaqueBlack,
    kOpaqueWhite,
};

struct SamplerDesc {
    std::string_view name;
    Filter min_filter = Filter::kLinear;
    Filter mag_filter = Filter::kLinear;
    Filter mip_filter = Filter::kLinear;
    AddressMode address_u = AddressMode::kRepeat;
    AddressMode address_v = AddressMode::kRepeat;
    AddressMode address_w = AddressMode::kRepeat;
    BorderColor border = BorderColor::kTransparentBlack;
    float mip_bias = 0.0F;
    float min_lod = 0.0F;
    float max_lod = 1000.0F;
    // 1 là tắt lọc bất đẳng hướng; kẹp theo DeviceCaps::max_anisotropy.
    std::uint32_t max_anisotropy = 1;
    // Khác Never là sampler so sánh (SamplerComparisonState), cho bóng đổ lọc bằng phần cứng.
    CompareOp compare = CompareOp::kNever;
};

// Số lớp của một texture theo cách cả hai API đếm: Tex3D có một lớp.
[[nodiscard]] constexpr std::uint32_t layer_count(const TextureDesc& desc) noexcept {
    return desc.kind == TextureKind::kTex3D ? 1U : desc.depth_or_layers;
}

// Độ sâu của mức mip 0: chỉ Tex3D khác 1.
[[nodiscard]] constexpr std::uint32_t depth_of(const TextureDesc& desc) noexcept {
    return desc.kind == TextureKind::kTex3D ? desc.depth_or_layers : 1U;
}

} // namespace game::gpu
