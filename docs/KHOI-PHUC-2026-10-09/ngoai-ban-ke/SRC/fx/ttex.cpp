#include "fx/ttex.hpp"

#include <cstring>
#include <string_view>

namespace game::fx {
namespace {

constexpr std::string_view kMagic = "TLBBTEX ";

struct Header {
    std::uint16_t format = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::span<const std::byte> payload;
};

[[nodiscard]] std::uint16_t read_u16(std::span<const std::byte> bytes, std::size_t offset) {
    std::uint16_t value = 0;
    std::memcpy(&value, bytes.subspan(offset, sizeof(value)).data(), sizeof(value));
    return value;
}

[[nodiscard]] std::uint32_t read_u32(std::span<const std::byte> bytes, std::size_t offset) {
    std::uint32_t value = 0;
    std::memcpy(&value, bytes.subspan(offset, sizeof(value)).data(), sizeof(value));
    return value;
}

[[nodiscard]] std::optional<Header> read_header(std::span<const std::byte> bytes) {
    if (bytes.size() < 28 || std::string_view(reinterpret_cast<const char*>(bytes.data()), 8) != kMagic)
        return std::nullopt;
    Header header;
    if (read_u16(bytes, 8) != 2) return std::nullopt;
    header.format = read_u16(bytes, 10);
    header.width = read_u32(bytes, 14);
    header.height = read_u32(bytes, 18);
    const std::uint32_t size = read_u32(bytes, 24);
    if (header.width == 0 || header.height == 0 || bytes.size() < 28U + size) return std::nullopt;
    header.payload = bytes.subspan(28, size);
    return header;
}

[[nodiscard]] std::uint8_t channel5(std::uint16_t colour, int shift) {
    const auto bits = static_cast<std::uint8_t>((colour >> shift) & 31U);
    return static_cast<std::uint8_t>((bits * 255U) / 31U);
}

[[nodiscard]] std::uint8_t channel6(std::uint16_t colour) {
    const auto bits = static_cast<std::uint8_t>((colour >> 5U) & 63U);
    return static_cast<std::uint8_t>((bits * 255U) / 63U);
}

void write_rgb(std::uint8_t* pixel, std::uint16_t colour, std::uint8_t alpha) {
    pixel[0] = channel5(colour, 11);
    pixel[1] = channel6(colour);
    pixel[2] = channel5(colour, 0);
    pixel[3] = alpha;
}

void mix_rgb(std::uint8_t* pixel, const std::uint8_t* from, const std::uint8_t* to, int from_w, int to_w) {
    pixel[0] = static_cast<std::uint8_t>((from[0] * from_w + to[0] * to_w) / (from_w + to_w));
    pixel[1] = static_cast<std::uint8_t>((from[1] * from_w + to[1] * to_w) / (from_w + to_w));
    pixel[2] = static_cast<std::uint8_t>((from[2] * from_w + to[2] * to_w) / (from_w + to_w));
    pixel[3] = 255;
}

void paint_bc1_block(std::uint8_t* image, std::uint32_t width, std::uint32_t row, std::uint32_t column,
    std::span<const std::byte> block) {
    std::uint16_t colour0 = 0;
    std::uint16_t colour1 = 0;
    std::memcpy(&colour0, block.data(), 2);
    std::memcpy(&colour1, block.data() + 2, 2);
    std::uint8_t palette[4][4];
    write_rgb(palette[0], colour0, 255);
    write_rgb(palette[1], colour1, 255);
    if (colour0 > colour1) {
        mix_rgb(palette[2], palette[0], palette[1], 2, 1);
        mix_rgb(palette[3], palette[0], palette[1], 1, 2);
    } else {
        mix_rgb(palette[2], palette[0], palette[1], 1, 1);
        palette[3][0] = palette[3][1] = palette[3][2] = 0;
        palette[3][3] = 0;
    }
    std::uint32_t indices = 0;
    std::memcpy(&indices, block.data() + 4, 4);
    for (int texel = 0; texel < 16; ++texel) {
        const std::uint32_t x = column + static_cast<std::uint32_t>(texel % 4);
        const std::uint32_t y = row + static_cast<std::uint32_t>(texel / 4);
        if (x >= width) continue;
        const std::uint32_t slot = (indices >> (texel * 2)) & 3U;
        std::memcpy(image + ((y * width + x) * 4U), palette[slot], 4);
    }
}

[[nodiscard]] DecodedImage decode_bc1(const Header& header) {
    DecodedImage image;
    image.width = header.width;
    image.height = header.height;
    image.rgba.assign(static_cast<std::size_t>(header.width) * header.height * 4U, 0);
    std::size_t offset = 0;
    for (std::uint32_t row = 0; row < header.height; row += 4) {
        for (std::uint32_t column = 0; column < header.width; column += 4) {
            if (offset + 8 > header.payload.size()) return image;
            paint_bc1_block(image.rgba.data(), header.width, row, column, header.payload.subspan(offset, 8));
            offset += 8;
        }
    }
    return image;
}

[[nodiscard]] DecodedImage decode_rgba(const Header& header) {
    DecodedImage image;
    image.width = header.width;
    image.height = header.height;
    const std::size_t count = static_cast<std::size_t>(header.width) * header.height * 4U;
    if (header.payload.size() < count) return {};
    image.rgba.resize(count);
    std::memcpy(image.rgba.data(), header.payload.data(), count);
    return image;
}

} // namespace

std::optional<DecodedImage> decode_ttex(std::span<const std::byte> bytes) {
    const std::optional<Header> header = read_header(bytes);
    if (!header) return std::nullopt;
    if (header->format == 2) return decode_bc1(*header);
    if (header->format == 1) return decode_rgba(*header);
    return std::nullopt;
}

} // namespace game::fx

