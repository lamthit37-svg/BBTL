// Bộ đọc DDS: DXT giữ nguyên khối và mip, A8R8G8B8 đổi sang RGBA8, cube và file cụt bị từ chối.
#include "core/check.hpp"
#include "core/error.hpp"
#include "gpu/format.hpp"
#include "resource/dds.hpp"
#include "resource/upload.hpp"
#include "test.hpp"

#include <array>
#include <bit>
#include <cstdint>
#include <cstring>
#include <span>
#include <vector>

namespace game::test {
namespace {

void put_u32(std::vector<std::byte>& out, std::uint32_t value) {
    const auto bytes = std::bit_cast<std::array<std::byte, 4>>(value);
    out.insert(out.end(), bytes.begin(), bytes.end());
}

void put_bytes(std::vector<std::byte>& out, std::span<const std::byte> bytes) {
    out.insert(out.end(), bytes.begin(), bytes.end());
}

// Header 128 byte. fourcc khác 0 thì bật cờ FourCC. alpha_mask 0 nghĩa là kênh alpha bỏ.
std::vector<std::byte> dds_file(std::uint32_t width, std::uint32_t height, std::uint32_t mips,
    std::uint32_t fourcc, std::uint32_t caps2, std::span<const std::byte> payload) {
    std::vector<std::byte> out;
    out.reserve(128 + payload.size());
    put_u32(out, 0x20534444U);
    put_u32(out, 124);
    const std::uint32_t flags = mips > 1 ? 0x20000U : 0;
    put_u32(out, flags);
    put_u32(out, height);
    put_u32(out, width);
    put_u32(out, 0);
    put_u32(out, 0);
    put_u32(out, mips);
    for (int index = 0; index < 11; ++index) put_u32(out, 0);
    put_u32(out, 32);
    const std::uint32_t pixel_flags = fourcc != 0 ? 0x4U : 0x40U;
    put_u32(out, pixel_flags);
    put_u32(out, fourcc);
    put_u32(out, fourcc == 0 ? 32 : 0);
    put_u32(out, fourcc == 0 ? 0x00FF0000U : 0);
    put_u32(out, fourcc == 0 ? 0x0000FF00U : 0);
    put_u32(out, fourcc == 0 ? 0x000000FFU : 0);
    put_u32(out, fourcc == 0 ? 0xFF000000U : 0);
    put_u32(out, 0);
    put_u32(out, caps2);
    put_u32(out, 0);
    put_u32(out, 0);
    put_u32(out, 0);
    put_bytes(out, payload);
    return out;
}

constexpr std::uint32_t kDxt1 = 0x31545844U;
constexpr std::uint32_t kDxt3 = 0x33545844U;
constexpr std::uint32_t kDxt5 = 0x35545844U;

void dxt1_keeps_block_and_mips(Context& context) {
    const std::array<std::byte, 40> payload{};
    const std::vector<std::byte> file = dds_file(8, 8, 2, kDxt1, 0, payload);
    const auto image = resource::read_dds(file);
    context.expect(image.has_value(), "DXT1 phải đọc được");
    if (!image) return;
    context.expect(image->blocks == gpu::Format::kBc1Unorm, "DXT1 là BC1");
    context.expect(image->width == 8 && image->height == 8, "cỡ mức 0");
    context.expect(image->levels.size() == 2, "hai mip");
    context.expect(image->rgba.empty(), "không giải ra RGBA");
    context.expect(image->levels[0].size() == 32, "mức 0 là bốn khối");
    context.expect(image->levels[1].size() == 8, "mức 1x1 vẫn một khối");
}

void dxt3_and_dxt5_block_sizes(Context& context) {
    const std::array<std::byte, 16> payload{};
    const std::vector<std::byte> dxt3 = dds_file(4, 4, 1, kDxt3, 0, payload);
    const std::vector<std::byte> dxt5 = dds_file(4, 4, 1, kDxt5, 0, payload);
    const auto bc2 = resource::read_dds(dxt3);
    const auto bc3 = resource::read_dds(dxt5);
    context.expect(bc2 && bc2->blocks == gpu::Format::kBc2Unorm, "DXT3 là BC2");
    context.expect(bc3 && bc3->blocks == gpu::Format::kBc3Unorm, "DXT5 là BC3");
    context.expect(bc2 && bc2->levels[0].size() == 16, "BC2 một khối 16 byte");
}

void bgra_swizzles_to_rgba(Context& context) {
    const std::array<std::byte, 4> pixel{std::byte{1}, std::byte{2}, std::byte{3}, std::byte{4}};
    const std::vector<std::byte> file = dds_file(1, 1, 1, 0, 0, pixel);
    const auto image = resource::read_dds(file);
    context.expect(image.has_value(), "A8R8G8B8 phải đọc được");
    if (!image) return;
    context.expect(image->blocks == gpu::Format::kUnknown, "ảnh 32 bit không phải khối nén");
    context.expect(image->rgba.size() == 4, "một điểm");
    context.expect(image->rgba[0] == 3 && image->rgba[1] == 2 && image->rgba[2] == 1 && image->rgba[3] == 4,
        "BGRA thành RGBA");
}

void truncated_mip_is_corrupt(Context& context) {
    const std::array<std::byte, 8> payload{};
    const std::vector<std::byte> file = dds_file(8, 8, 2, kDxt1, 0, payload);
    const auto image = resource::read_dds(file);
    const bool corrupt = !image && image.error().code() == core::ErrorCode::kCorrupt;
    context.expect(corrupt, "mip cụt là tệp hỏng");
}

void cube_is_unsupported(Context& context) {
    const std::array<std::byte, 8> payload{};
    const std::vector<std::byte> file = dds_file(4, 4, 1, kDxt1, 0x200U, payload);
    const auto image = resource::read_dds(file);
    const bool refused = !image && image.error().code() == core::ErrorCode::kUnsupported;
    context.expect(refused, "cube không nạp");
}

void stage_keeps_blocks(Context& context) {
    const std::array<std::byte, 40> payload{};
    const std::vector<std::byte> file = dds_file(8, 8, 2, kDxt1, 0, payload);
    const auto image = resource::read_dds(file);
    context.expect(image.has_value(), "DXT1 để xếp mip");
    if (!image) return;
    const auto staged = resource::stage_image(*image, resource::ColorSpace::kSrgb);
    context.expect(staged.has_value(), "xếp khối không nướng RGBA");
    if (!staged) return;
    context.expect(staged->mips.size() == 2, "giữ hai mip");
    context.expect(staged->mips[0].offset == 0, "mip 0 ở đầu");
    context.expect(staged->mips[1].offset == 512, "mip sau căn 512");
    context.expect(staged->bytes.size() == 520, "mip 0 đệm 272 byte, mip 1 tám byte ở offset 512");
    context.expect(staged->bytes[0] == payload[0], "byte khối không đổi");
}

constexpr std::array kCases{
    Case{.name = "dxt1_keeps_block_and_mips", .body = &dxt1_keeps_block_and_mips},
    Case{.name = "dxt3_and_dxt5_block_sizes", .body = &dxt3_and_dxt5_block_sizes},
    Case{.name = "bgra_swizzles_to_rgba", .body = &bgra_swizzles_to_rgba},
    Case{.name = "truncated_mip_is_corrupt", .body = &truncated_mip_is_corrupt},
    Case{.name = "cube_is_unsupported", .body = &cube_is_unsupported},
    Case{.name = "stage_keeps_blocks", .body = &stage_keeps_blocks},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "dds_tests: mọi ca phải qua");
    return 0;
}
