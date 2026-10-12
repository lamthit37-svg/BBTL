// Đọc .ttex đã nấu (TLBBTEX phiên bản 2) ra RGBA8. BC1/BC3 giải mip đầu; RGBA8 và R8 chép thẳng.
// Nguồn định dạng: TLBB Dev src/cooked/cooked.cpp read_cooked_texture. Chỉ mip 0 để hạt nhỏ
// khỏi giữ cả chuỗi trong RAM.
#pragma once

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace game::fx {

struct DecodedImage {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::vector<std::uint8_t> rgba;
};

[[nodiscard]] std::optional<DecodedImage> decode_ttex(std::span<const std::byte> bytes);

} // namespace game::fx

