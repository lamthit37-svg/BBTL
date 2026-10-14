// DDS của _goc: DXT1 là BC1, DXT3 là BC2, DXT5 là BC3. Mip ghi khít, khối 4x4 kể cả mức 1x1.
#include "resource/dds.hpp"

#include "gpu/format.hpp"

#include <cstdint>
#include <cstring>
#include <limits>
#include <vector>

namespace game::resource {
namespace {

constexpr std::uint32_t kMagic = 0x20534444U;
constexpr std::uint32_t kHeaderBytes = 128;
constexpr std::uint32_t kHeaderSize = 124;
constexpr std::uint32_t kMipFlag = 0x20000U;
constexpr std::uint32_t kFourccFlag = 0x4U;
constexpr std::uint32_t kRgbFlag = 0x40U;
constexpr std::uint32_t kCube = 0x200U;
constexpr std::uint32_t kVolume = 0x200000U;
constexpr std::uint32_t kDxt1 = 0x31545844U;
constexpr std::uint32_t kDxt2 = 0x32545844U;
constexpr std::uint32_t kDxt3 = 0x33545844U;
constexpr std::uint32_t kDxt5 = 0x35545844U;
constexpr std::uint32_t kDx10 = 0x30315844U;

struct Head {
    std::uint32_t flags = 0;
    std::uint32_t height = 0;
    std::uint32_t width = 0;
    std::uint32_t mips = 1;
    std::uint32_t pixel_flags = 0;
    std::uint32_t fourcc = 0;
    std::uint32_t bits = 0;
    std::uint32_t red = 0;
    std::uint32_t green = 0;
    std::uint32_t blue = 0;
    std::uint32_t alpha = 0;
    std::uint32_t caps2 = 0;
};

[[nodiscard]] core::Failure corrupt(core::Message message) {
    return core::fail(core::ErrorCode::kCorrupt, message);
}

[[nodiscard]] core::Failure unsupported(core::Message message) {
    return core::fail(core::ErrorCode::kUnsupported, message);
}

[[nodiscard]] bool take_u32(std::span<const std::byte> bytes, std::size_t offset, std::uint32_t& out) noexcept {
    if (offset > bytes.size() || bytes.size() - offset < 4) return false;
    std::uint32_t value = 0;
    std::memcpy(&value, bytes.data() + offset, 4);
    out = value;
    return true;
}

[[nodiscard]] core::Result<Head> read_head(std::span<const std::byte> bytes) {
    if (bytes.size() < kHeaderBytes) return corrupt("DDS cụt header");
    std::uint32_t magic = 0;
    std::uint32_t size = 0;
    const bool has_magic = take_u32(bytes, 0, magic);
    const bool has_size = take_u32(bytes, 4, size);
    if (!has_magic || !has_size || magic != kMagic || size != kHeaderSize) return corrupt("DDS không đúng header");
    Head head;
    if (!take_u32(bytes, 8, head.flags)) return corrupt("DDS cụt cờ");
    if (!take_u32(bytes, 12, head.height)) return corrupt("DDS cụt cao");
    if (!take_u32(bytes, 16, head.width)) return corrupt("DDS cụt rộng");
    std::uint32_t stored_mips = 0;
    if (!take_u32(bytes, 28, stored_mips)) return corrupt("DDS cụt mip");
    if (!take_u32(bytes, 80, head.pixel_flags)) return corrupt("DDS cụt định dạng");
    if (!take_u32(bytes, 84, head.fourcc)) return corrupt("DDS cụt fourcc");
    if (!take_u32(bytes, 88, head.bits)) return corrupt("DDS cụt bit");
    if (!take_u32(bytes, 92, head.red)) return corrupt("DDS cụt kênh đỏ");
    if (!take_u32(bytes, 96, head.green)) return corrupt("DDS cụt kênh lục");
    if (!take_u32(bytes, 100, head.blue)) return corrupt("DDS cụt kênh lam");
    if (!take_u32(bytes, 104, head.alpha)) return corrupt("DDS cụt kênh alpha");
    if (!take_u32(bytes, 112, head.caps2)) return corrupt("DDS cụt caps2");
    const bool has_mips = (head.flags & kMipFlag) != 0 && stored_mips > 0;
    if (has_mips) head.mips = stored_mips;
    if (head.width == 0 || head.height == 0) return corrupt("DDS cỡ bằng không");
    return head;
}

[[nodiscard]] bool is_surface(const Head& head) noexcept {
    const bool cube = (head.caps2 & kCube) != 0;
    const bool volume = (head.caps2 & kVolume) != 0;
    return !cube && !volume;
}

[[nodiscard]] gpu::Format block_format(std::uint32_t fourcc) noexcept {
    if (fourcc == kDxt1) return gpu::Format::kBc1Unorm;
    if (fourcc == kDxt2 || fourcc == kDxt3) return gpu::Format::kBc2Unorm;
    if (fourcc == kDxt5) return gpu::Format::kBc3Unorm;
    return gpu::Format::kUnknown;
}

[[nodiscard]] bool is_bgra(const Head& head) noexcept {
    const bool rgb = (head.pixel_flags & kRgbFlag) != 0 && (head.pixel_flags & kFourccFlag) == 0;
    const bool masks =
        head.bits == 32 && head.red == 0x00FF0000U && head.green == 0x0000FF00U && head.blue == 0x000000FFU;
    return rgb && masks;
}

[[nodiscard]] std::uint32_t mip_edge(std::uint32_t size, std::uint32_t level) noexcept {
    return std::max(size >> std::min(level, 31U), 1U);
}

[[nodiscard]] core::Result<std::vector<std::byte>> copy_level(std::span<const std::byte>& rest, gpu::Format format,
    std::uint32_t width, std::uint32_t height) {
    const std::uint64_t rows = gpu::row_count(format, height);
    const std::uint64_t row = gpu::row_bytes(format, width);
    if (row != 0 && rows > std::numeric_limits<std::uint64_t>::max() / row) return corrupt("DDS mip quá lớn");
    const std::uint64_t bytes = rows * row;
    if (bytes > rest.size()) return corrupt("DDS cụt mip");
    const std::span<const std::byte> taken = rest.first(static_cast<std::size_t>(bytes));
    rest = rest.subspan(taken.size());
    return std::vector<std::byte>(taken.begin(), taken.end());
}

[[nodiscard]] core::Result<Image> read_blocks(const Head& head, std::span<const std::byte> payload,
    gpu::Format format) {
    const std::uint32_t limit = gpu::full_mip_count(head.width, head.height);
    if (head.mips > limit) return corrupt("DDS nhiều mip hơn chuỗi đầy đủ");
    Image image;
    image.width = head.width;
    image.height = head.height;
    image.blocks = format;
    image.levels.reserve(head.mips);
    std::span<const std::byte> rest = payload;
    for (std::uint32_t level = 0; level < head.mips; ++level) {
        const std::uint32_t width = mip_edge(head.width, level);
        const std::uint32_t height = mip_edge(head.height, level);
        auto copied = copy_level(rest, format, width, height);
        if (!copied) return std::unexpected(copied.error());
        image.levels.push_back(std::move(*copied));
    }
    return image;
}

void write_bgra(std::vector<std::uint8_t>& rgba, std::size_t index, std::span<const std::byte> packed,
    bool keep_alpha) {
    const auto blue = static_cast<std::uint8_t>(packed[index]);
    const auto green = static_cast<std::uint8_t>(packed[index + 1]);
    const auto red = static_cast<std::uint8_t>(packed[index + 2]);
    const auto stored = static_cast<std::uint8_t>(packed[index + 3]);
    rgba[index] = red;
    rgba[index + 1] = green;
    rgba[index + 2] = blue;
    rgba[index + 3] = keep_alpha ? stored : static_cast<std::uint8_t>(255);
}

void store_bgra(std::span<const std::byte> packed, bool keep_alpha, std::vector<std::uint8_t>& rgba) {
    rgba.resize(packed.size());
    for (std::size_t index = 0; index + 3 < packed.size(); index += 4) {
        write_bgra(rgba, index, packed, keep_alpha);
    }
}

[[nodiscard]] core::Result<Image> read_bgra(const Head& head, std::span<const std::byte> payload) {
    const std::uint64_t pixels = std::uint64_t{head.width} * head.height;
    if (pixels > std::numeric_limits<std::uint64_t>::max() / 4) return corrupt("DDS quá lớn");
    const std::uint64_t bytes = pixels * 4;
    if (bytes > payload.size()) return corrupt("DDS cụt điểm ảnh");
    Image image;
    image.width = head.width;
    image.height = head.height;
    const std::span<const std::byte> packed = payload.first(static_cast<std::size_t>(bytes));
    store_bgra(packed, head.alpha != 0, image.rgba);
    return image;
}

} // namespace

namespace {

[[nodiscard]] bool ends_ci(std::string_view text, std::string_view suffix) noexcept {
    if (text.size() < suffix.size()) return false;
    const std::string_view tail = text.substr(text.size() - suffix.size());
    for (std::size_t index = 0; index < suffix.size(); ++index) {
        const unsigned char left = static_cast<unsigned char>(tail[index]);
        const unsigned char right = static_cast<unsigned char>(suffix[index]);
        const unsigned char folded = left >= 'A' && left <= 'Z' ? static_cast<unsigned char>(left - 'A' + 'a') : left;
        if (folded != right) return false;
    }
    return true;
}

} // namespace

std::string dds_sibling(std::string_view path) {
    if (!ends_ci(path, ".png")) return {};
    const std::string_view stem = path.substr(0, path.size() - 4);
    if (!ends_ci(stem, ".dds")) return {};
    return std::string(stem);
}

core::Result<Image> read_dds(std::span<const std::byte> bytes) {
    auto head = read_head(bytes);
    if (!head) return std::unexpected(head.error());
    if (!is_surface(*head)) return unsupported("DDS cube hoặc volume");
    if (head->fourcc == kDx10) return unsupported("DDS DX10");
    const gpu::Format blocks = block_format(head->fourcc);
    const bool is_fourcc = (head->pixel_flags & kFourccFlag) != 0;
    const std::span<const std::byte> payload = bytes.subspan(kHeaderBytes);
    if (is_fourcc && blocks != gpu::Format::kUnknown) return read_blocks(*head, payload, blocks);
    if (is_bgra(*head)) return read_bgra(*head, payload);
    return unsupported("DDS không phải DXT hoặc A8R8G8B8");
}

} // namespace game::resource
