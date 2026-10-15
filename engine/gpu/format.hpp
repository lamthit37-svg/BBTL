/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/format.hpp
 *  PHÂN HỆ   : Gpu / Format
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Định dạng điểm ảnh của tầng đồ hoạ và số học bố cục của chúng (bước dòng,
 *    số hàng khối, cỡ một mức mip). Thay TinyImageFormat của _Ref (bảng sinh
 *    máy 239 định dạng) và Format của Wicked bằng tập có ánh xạ sang cả
 *    VkFormat lẫn DXGI_FORMAT; riêng ETC2, EAC và ASTC chỉ Vulkan có (GPU điện
 *    thoại), D3D12 báo không hỗ trợ qua Device::format_support. Platium chỉ có
 *    31 định dạng và không có nhánh mobile. Hàm ở đây là constexpr và không phụ
 *    thuộc backend, nên pipeline asset tính cỡ dữ liệu bằng đúng công thức mà
 *    tầng đồ hoạ dùng lúc chép.
 *  - Nguồn: Forge2 src/gpu/format.hpp@d7fcd76. Khác gốc: enumerator mang tiền
 *    tố k.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "gpu/types.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <numeric>
#include <optional>
#include <string_view>

namespace game::gpu {

// Thứ tự là hợp đồng với bảng tên ở format.cpp và hai bảng đổi của backend.
enum class Format : std::uint8_t {
    kUnknown,
    kR8Unorm,
    kR8Snorm,
    kR8Uint,
    kR8Sint,
    kRg8Unorm,
    kRg8Snorm,
    kRg8Uint,
    kRg8Sint,
    kRgba8Unorm,
    kRgba8UnormSrgb,
    kRgba8Snorm,
    kRgba8Uint,
    kRgba8Sint,
    kBgra8Unorm,
    kBgra8UnormSrgb,
    kR16Unorm,
    kR16Snorm,
    kR16Uint,
    kR16Sint,
    kR16Float,
    kRg16Unorm,
    kRg16Snorm,
    kRg16Uint,
    kRg16Sint,
    kRg16Float,
    kRgba16Unorm,
    kRgba16Snorm,
    kRgba16Uint,
    kRgba16Sint,
    kRgba16Float,
    kR32Uint,
    kR32Sint,
    kR32Float,
    kRg32Uint,
    kRg32Sint,
    kRg32Float,
    kRgb32Uint,
    kRgb32Sint,
    kRgb32Float,
    kRgba32Uint,
    kRgba32Sint,
    kRgba32Float,
    // Gói 32 bit: 10 bit mỗi kênh màu, 2 bit alpha.
    kRgb10A2Unorm,
    kRgb10A2Uint,
    kRg11B10Float,
    // Ba phần trị 9 bit chung một số mũ 5 bit.
    kRgb9E5Float,
    kD16Unorm,
    // Không phải GPU nào cũng có (AMD trên Vulkan thiếu); hỏi format_support trước khi dùng.
    kD24UnormS8Uint,
    kD32Float,
    kD32FloatS8Uint,
    // Nén khối của máy tính để bàn.
    kBc1Unorm,
    kBc1UnormSrgb,
    kBc2Unorm,
    kBc2UnormSrgb,
    kBc3Unorm,
    kBc3UnormSrgb,
    kBc4Unorm,
    kBc4Snorm,
    kBc5Unorm,
    kBc5Snorm,
    kBc6hUfloat,
    kBc6hSfloat,
    kBc7Unorm,
    kBc7UnormSrgb,
    // Nén khối của điện thoại: ETC2 và EAC là bắt buộc trên Vulkan của Android.
    kEtc2Rgb8Unorm,
    kEtc2Rgb8UnormSrgb,
    kEtc2Rgb8A1Unorm,
    kEtc2Rgb8A1UnormSrgb,
    kEtc2Rgba8Unorm,
    kEtc2Rgba8UnormSrgb,
    kEacR11Unorm,
    kEacR11Snorm,
    kEacRg11Unorm,
    kEacRg11Snorm,
    kAstc4x4Unorm,
    kAstc4x4UnormSrgb,
    kAstc5x5Unorm,
    kAstc5x5UnormSrgb,
    kAstc6x6Unorm,
    kAstc6x6UnormSrgb,
    kAstc8x8Unorm,
    kAstc8x8UnormSrgb,
    kAstc10x10Unorm,
    kAstc10x10UnormSrgb,
    kAstc12x12Unorm,
    kAstc12x12UnormSrgb,
};

inline constexpr std::size_t kFormatCount = std::to_underlying(Format::kAstc12x12UnormSrgb) + 1;

// "rgba8_unorm_srgb", "bc7_unorm", "astc_6x6_unorm": tên trong tệp asset và tệp cấu hình.
[[nodiscard]] std::string_view name(Format format) noexcept;
[[nodiscard]] std::optional<Format> parse_format(std::string_view text) noexcept;

enum class FormatAspect : std::uint8_t {
    kColor,
    kDepth,
    kDepthStencil,
};

struct FormatInfo {
    // Cỡ một khối tính bằng điểm ảnh; 1x1 với định dạng không nén.
    std::uint8_t block_width = 1;
    std::uint8_t block_height = 1;
    // Số byte của một khối; 0 cho Unknown.
    std::uint8_t block_bytes = 0;
    std::uint8_t channels = 0;
    FormatAspect aspect = FormatAspect::kColor;
    bool is_srgb = false;
    bool is_compressed = false;
};

namespace detail {

[[nodiscard]] constexpr FormatInfo plain(std::uint8_t bytes, std::uint8_t channels) noexcept {
    return {.block_bytes = bytes, .channels = channels};
}

[[nodiscard]] constexpr FormatInfo plain_srgb(std::uint8_t bytes, std::uint8_t channels) noexcept {
    return {.block_bytes = bytes, .channels = channels, .is_srgb = true};
}

[[nodiscard]] constexpr FormatInfo depth(std::uint8_t bytes, FormatAspect aspect) noexcept {
    const std::uint8_t channels = aspect == FormatAspect::kDepth ? 1 : 2;
    return {.block_bytes = bytes, .channels = channels, .aspect = aspect};
}

// Khối side x side điểm ảnh chiếm bytes byte.
[[nodiscard]] constexpr FormatInfo block(std::uint8_t side, std::uint8_t bytes, std::uint8_t channels,
    bool is_srgb) noexcept {
    return {.block_width = side,
        .block_height = side,
        .block_bytes = bytes,
        .channels = channels,
        .is_srgb = is_srgb,
        .is_compressed = true};
}

} // namespace detail

// Không default: thêm định dạng mà quên ở đây là C4062.
// Bảng tra một case một định dạng; chia nhỏ thì mất phép kiểm đủ ca của trình dịch (lệch PH-01).
// NOLINTNEXTLINE(readability-function-size)
[[nodiscard]] constexpr FormatInfo info(Format format) noexcept {
    using detail::block;
    using detail::depth;
    using detail::plain;
    using detail::plain_srgb;
    switch (format) {
    case Format::kUnknown: return {};
    case Format::kR8Unorm:
    case Format::kR8Snorm:
    case Format::kR8Uint:
    case Format::kR8Sint: return plain(1, 1);
    case Format::kRg8Unorm:
    case Format::kRg8Snorm:
    case Format::kRg8Uint:
    case Format::kRg8Sint: return plain(2, 2);
    case Format::kRgba8Unorm:
    case Format::kRgba8Snorm:
    case Format::kRgba8Uint:
    case Format::kRgba8Sint:
    case Format::kBgra8Unorm: return plain(4, 4);
    case Format::kRgba8UnormSrgb:
    case Format::kBgra8UnormSrgb: return plain_srgb(4, 4);
    case Format::kR16Unorm:
    case Format::kR16Snorm:
    case Format::kR16Uint:
    case Format::kR16Sint:
    case Format::kR16Float: return plain(2, 1);
    case Format::kRg16Unorm:
    case Format::kRg16Snorm:
    case Format::kRg16Uint:
    case Format::kRg16Sint:
    case Format::kRg16Float: return plain(4, 2);
    case Format::kRgba16Unorm:
    case Format::kRgba16Snorm:
    case Format::kRgba16Uint:
    case Format::kRgba16Sint:
    case Format::kRgba16Float: return plain(8, 4);
    case Format::kR32Uint:
    case Format::kR32Sint:
    case Format::kR32Float: return plain(4, 1);
    case Format::kRg32Uint:
    case Format::kRg32Sint:
    case Format::kRg32Float: return plain(8, 2);
    case Format::kRgb32Uint:
    case Format::kRgb32Sint:
    case Format::kRgb32Float: return plain(12, 3);
    case Format::kRgba32Uint:
    case Format::kRgba32Sint:
    case Format::kRgba32Float: return plain(16, 4);
    case Format::kRgb10A2Unorm:
    case Format::kRgb10A2Uint: return plain(4, 4);
    case Format::kRg11B10Float:
    case Format::kRgb9E5Float: return plain(4, 3);
    case Format::kD16Unorm: return depth(2, FormatAspect::kDepth);
    case Format::kD24UnormS8Uint: return depth(4, FormatAspect::kDepthStencil);
    case Format::kD32Float: return depth(4, FormatAspect::kDepth);
    case Format::kD32FloatS8Uint: return depth(8, FormatAspect::kDepthStencil);
    case Format::kBc1Unorm: return block(4, 8, 4, false);
    case Format::kBc1UnormSrgb: return block(4, 8, 4, true);
    case Format::kBc2Unorm:
    case Format::kBc3Unorm:
    case Format::kBc7Unorm: return block(4, 16, 4, false);
    case Format::kBc2UnormSrgb:
    case Format::kBc3UnormSrgb:
    case Format::kBc7UnormSrgb: return block(4, 16, 4, true);
    case Format::kBc4Unorm:
    case Format::kBc4Snorm: return block(4, 8, 1, false);
    case Format::kBc5Unorm:
    case Format::kBc5Snorm: return block(4, 16, 2, false);
    case Format::kBc6hUfloat:
    case Format::kBc6hSfloat: return block(4, 16, 3, false);
    case Format::kEtc2Rgb8Unorm: return block(4, 8, 3, false);
    case Format::kEtc2Rgb8UnormSrgb: return block(4, 8, 3, true);
    case Format::kEtc2Rgb8A1Unorm: return block(4, 8, 4, false);
    case Format::kEtc2Rgb8A1UnormSrgb: return block(4, 8, 4, true);
    case Format::kEtc2Rgba8Unorm: return block(4, 16, 4, false);
    case Format::kEtc2Rgba8UnormSrgb: return block(4, 16, 4, true);
    case Format::kEacR11Unorm:
    case Format::kEacR11Snorm: return block(4, 8, 1, false);
    case Format::kEacRg11Unorm:
    case Format::kEacRg11Snorm: return block(4, 16, 2, false);
    case Format::kAstc4x4Unorm: return block(4, 16, 4, false);
    case Format::kAstc4x4UnormSrgb: return block(4, 16, 4, true);
    case Format::kAstc5x5Unorm: return block(5, 16, 4, false);
    case Format::kAstc5x5UnormSrgb: return block(5, 16, 4, true);
    case Format::kAstc6x6Unorm: return block(6, 16, 4, false);
    case Format::kAstc6x6UnormSrgb: return block(6, 16, 4, true);
    case Format::kAstc8x8Unorm: return block(8, 16, 4, false);
    case Format::kAstc8x8UnormSrgb: return block(8, 16, 4, true);
    case Format::kAstc10x10Unorm: return block(10, 16, 4, false);
    case Format::kAstc10x10UnormSrgb: return block(10, 16, 4, true);
    case Format::kAstc12x12Unorm: return block(12, 16, 4, false);
    case Format::kAstc12x12UnormSrgb: return block(12, 16, 4, true);
    }
    return {};
}

namespace detail {

inline constexpr std::array kUintFormats{Format::kR8Uint, Format::kRg8Uint, Format::kRgba8Uint, Format::kR16Uint,
    Format::kRg16Uint, Format::kRgba16Uint, Format::kR32Uint, Format::kRg32Uint, Format::kRgb32Uint,
    Format::kRgba32Uint, Format::kRgb10A2Uint};

inline constexpr std::array kSintFormats{Format::kR8Sint, Format::kRg8Sint, Format::kRgba8Sint, Format::kR16Sint,
    Format::kRg16Sint, Format::kRgba16Sint, Format::kR32Sint, Format::kRg32Sint, Format::kRgb32Sint,
    Format::kRgba32Sint};

} // namespace detail

// Định dạng màu số nguyên: shader đọc ghi bằng uint hay int, giá trị xoá phải cùng kiểu, không lọc
// tuyến tính và không resolve đa mẫu bằng trung bình được.
[[nodiscard]] constexpr bool is_uint(Format format) noexcept {
    return std::ranges::find(detail::kUintFormats, format) != detail::kUintFormats.end();
}

[[nodiscard]] constexpr bool is_sint(Format format) noexcept {
    return std::ranges::find(detail::kSintFormats, format) != detail::kSintFormats.end();
}

[[nodiscard]] constexpr bool has_depth(Format format) noexcept {
    return info(format).aspect != FormatAspect::kColor;
}

[[nodiscard]] constexpr bool has_stencil(Format format) noexcept {
    return info(format).aspect == FormatAspect::kDepthStencil;
}

// Cỡ của mức mip level khi mức 0 dài size; không bao giờ dưới 1.
[[nodiscard]] constexpr std::uint32_t mip_size(std::uint32_t size, std::uint32_t level) noexcept {
    return std::max(size >> std::min(level, 31U), 1U);
}

// Số mức mip của một chuỗi đầy đủ tới 1x1.
[[nodiscard]] constexpr std::uint32_t full_mip_count(std::uint32_t width, std::uint32_t height,
    std::uint32_t depth = 1) noexcept {
    std::uint32_t longest = std::max({width, height, depth, 1U});
    std::uint32_t count = 1;
    for (; longest > 1; longest >>= 1U) {
        ++count;
    }
    return count;
}

// Số byte của một hàng khối rộng width điểm ảnh, chưa đệm. Ảnh BC rộng 5 điểm ảnh vẫn chiếm trọn
// hai khối.
[[nodiscard]] constexpr std::uint64_t row_bytes(Format format, std::uint32_t width) noexcept {
    const FormatInfo layout = info(format);
    const std::uint64_t blocks = (std::uint64_t{width} + layout.block_width - 1) / layout.block_width;
    return blocks * layout.block_bytes;
}

// Số hàng khối của ảnh cao height điểm ảnh.
[[nodiscard]] constexpr std::uint32_t row_count(Format format, std::uint32_t height) noexcept {
    const FormatInfo layout = info(format);
    return (height + layout.block_height - 1) / layout.block_height;
}

// Bước dòng đã đệm, cho dữ liệu nằm trong buffer trung chuyển: bội của kTextureRowAlignment (D3D12
// đòi) và của cỡ khối (Vulkan đo bước dòng bằng texel). Hai điều kiện chỉ tách nhau ở định dạng 12
// byte mỗi điểm ảnh (Rgb32*), khi đó bước là bội của 768.
[[nodiscard]] constexpr std::uint64_t padded_row_bytes(Format format, std::uint32_t width) noexcept {
    const std::uint64_t tight = row_bytes(format, width);
    const std::uint64_t block = std::max<std::uint64_t>(info(format).block_bytes, 1);
    const std::uint64_t step = std::lcm(std::uint64_t{kTextureRowAlignment}, block);
    return (tight + step - 1) / step * step;
}

// Số byte của một lớp ảnh width x height (một lát của texture 3D) trong buffer trung chuyển, các
// dòng theo bước đã đệm, dòng cuối không đệm.
// NOLINTBEGIN(bugprone-easily-swappable-parameters): rộng rồi cao như mọi API ảnh (lệch API-03)
[[nodiscard]] constexpr std::uint64_t staged_bytes(Format format, std::uint32_t width, std::uint32_t height) noexcept {
    const std::uint32_t rows = row_count(format, height);
    if (rows == 0) return 0;
    return (padded_row_bytes(format, width) * (rows - std::uint64_t{1})) + row_bytes(format, width);
}
// NOLINTEND(bugprone-easily-swappable-parameters)

} // namespace game::gpu
