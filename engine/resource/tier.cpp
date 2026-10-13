// Đọc TLTX và chọn tệp theo tier. Khối đưa thẳng lên GPU, không giải ra RGBA.
#include "resource/tier.hpp"

#include "fs/disk.hpp"
#include "fs/path.hpp"
#include "resource/dds.hpp"
#include "resource/image.hpp"

#include <cstdint>
#include <cstring>
#include <string>

namespace game::resource {
namespace {

constexpr std::uint32_t kMagic = 0x58544C54U;
constexpr std::uint16_t kVersion = 1;
constexpr std::uint32_t kHeaderBytes = 20;
constexpr std::uint32_t kMaxEdge = 16384;
constexpr std::uint32_t kMaxMips = 16;
constexpr std::uint16_t kAstc4x4 = 1;
constexpr std::uint16_t kEtc2Rgba = 2;
constexpr std::uint16_t kEtc2Rgb = 3;

struct Kind {
    gpu::Format format = gpu::Format::kUnknown;
    std::uint32_t block_bytes = 0;
};

[[nodiscard]] std::uint16_t read_u16(std::span<const std::byte> bytes, std::size_t offset) noexcept {
    std::uint16_t value = 0;
    std::memcpy(&value, bytes.data() + offset, sizeof(value));
    return value;
}

[[nodiscard]] std::uint32_t read_u32(std::span<const std::byte> bytes, std::size_t offset) noexcept {
    std::uint32_t value = 0;
    std::memcpy(&value, bytes.data() + offset, sizeof(value));
    return value;
}

// Bốn byte đầu "TLTX" đọc theo thứ tự byte nhỏ trước, như mọi trường số của tệp.
[[nodiscard]] bool is_tltx(std::span<const std::byte> bytes) noexcept {
    return bytes.size() >= sizeof(std::uint32_t) && read_u32(bytes, 0) == kMagic;
}

[[nodiscard]] Kind kind_of(std::uint16_t kind) noexcept {
    if (kind == kAstc4x4) return {gpu::Format::kAstc4x4Unorm, 16};
    if (kind == kEtc2Rgba) return {gpu::Format::kEtc2Rgba8Unorm, 16};
    if (kind == kEtc2Rgb) return {gpu::Format::kEtc2Rgb8Unorm, 8};
    return {};
}

[[nodiscard]] std::uint32_t block_count(std::uint32_t pixels) noexcept {
    return (pixels + 3U) / 4U;
}

[[nodiscard]] std::uint32_t level_bytes(std::uint32_t width, std::uint32_t height, std::uint32_t block_bytes) noexcept {
    return block_count(width) * block_count(height) * block_bytes;
}

[[nodiscard]] core::Failure bad_tltx() {
    return core::fail(core::ErrorCode::kInvalidArgument, "TLTX hỏng");
}

} // namespace

std::string tier_relative(std::string_view relative, TextureTier tier) {
    if (tier == TextureTier::kAstc) return std::string("mobile/astc/") + std::string(relative);
    if (tier == TextureTier::kEtc2) return std::string("mobile/etc2/") + std::string(relative);
    return std::string(relative);
}

std::string texture_file(std::string_view root, std::string_view relative, TextureTier tier) {
    const std::string plain = fs::join(root, relative);
    if (tier == TextureTier::kBc) return plain;
    const std::string side = fs::join(root, tier_relative(relative, tier));
    if (fs::is_file(side)) return side;
    return plain;
}

core::Result<Image> read_tltx(std::span<const std::byte> bytes) {
    if (bytes.size() < kHeaderBytes || !is_tltx(bytes)) return bad_tltx();
    if (read_u16(bytes, 4) != kVersion) return bad_tltx();
    const Kind kind = kind_of(read_u16(bytes, 6));
    if (kind.block_bytes == 0) return bad_tltx();
    const std::uint32_t width = read_u32(bytes, 8);
    const std::uint32_t height = read_u32(bytes, 12);
    const std::uint32_t mips = read_u32(bytes, 16);
    const bool is_edge = width >= 1 && height >= 1 && width <= kMaxEdge && height <= kMaxEdge;
    if (!is_edge || mips < 1 || mips > kMaxMips) return bad_tltx();
    Image image;
    image.width = width;
    image.height = height;
    image.blocks = kind.format;
    std::size_t cursor = kHeaderBytes;
    std::uint32_t level_w = width;
    std::uint32_t level_h = height;
    for (std::uint32_t index = 0; index < mips; ++index) {
        const std::uint32_t size = level_bytes(level_w, level_h, kind.block_bytes);
        if (cursor + size > bytes.size()) return bad_tltx();
        const auto payload = bytes.subspan(cursor, size);
        image.levels.emplace_back(payload.begin(), payload.end());
        cursor += size;
        level_w = level_w > 1 ? level_w / 2 : 1;
        level_h = level_h > 1 ? level_h / 2 : 1;
    }
    if (cursor != bytes.size()) return bad_tltx();
    return image;
}

core::Result<Image> read_stored(std::span<const std::byte> bytes) {
    if (is_tltx(bytes)) return read_tltx(bytes);
    if (bytes.size() >= 4 && bytes[0] == std::byte{'D'} && bytes[1] == std::byte{'D'} && bytes[2] == std::byte{'S'} &&
        bytes[3] == std::byte{' '}) {
        return read_dds(bytes);
    }
    return decode_image(bytes);
}

} // namespace game::resource
