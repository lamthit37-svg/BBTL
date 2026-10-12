// Bản texture của điện thoại, nấu một lần, nằm cạnh DDS của PC.
// PC đọc BCn tại chỗ. Android và iOS ưu tiên ASTC, không có thì ETC2, thiếu tệp thì DDS.
#pragma once

#include "core/error.hpp"
#include "resource/image.hpp"

#include <cstdint>
#include <span>
#include <string>
#include <string_view>

namespace game::resource {

// kBc là tệp gốc. Hai kia là thư mục mobile/astc và mobile/etc2, cùng đường tương đối.
enum class TextureTier : std::uint8_t { kBc, kAstc, kEtc2 };

// Đường tương đối dưới data root. kBc giữ nguyên relative.
[[nodiscard]] std::string tier_relative(std::string_view relative, TextureTier tier);

// Tệp sẽ mở: sibling của tier nếu có trên đĩa, không thì relative dưới root.
[[nodiscard]] std::string texture_file(std::string_view root, std::string_view relative, TextureTier tier);

// TLTX phiên bản 1: khối ASTC 4x4 hoặc ETC2 đã nấu, mip khít, không giải.
[[nodiscard]] core::Result<Image> read_tltx(std::span<const std::byte> bytes);

// TLTX, DDS, rồi PNG hoặc JPEG.
[[nodiscard]] core::Result<Image> read_stored(std::span<const std::byte> bytes);

} // namespace game::resource
