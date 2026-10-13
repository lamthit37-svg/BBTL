// Ảnh của một model. PNG và JPEG giải ra RGBA8. DDS của client gốc giữ khối BCn và mip có sẵn,
// không giải và không nướng lại.
// Nguồn: Forge2 src/resource/image.hpp@d7fcd76. Khác gốc: thêm blocks và levels cho DDS.
#pragma once

#include "core/error.hpp"
#include "gpu/format.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <vector>

namespace game::resource {

struct Image {
    std::string name;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    // width * height * 4 byte khi blocks là kUnknown. Rỗng khi ảnh là khối nén.
    std::vector<std::uint8_t> rgba;
    // kUnknown: rgba là RGBA8. Khác: từng mức trong levels là khối nén xếp khít, mức 0 ở đầu.
    gpu::Format blocks = gpu::Format::kUnknown;
    std::vector<std::vector<std::byte>> levels;
    // false: nơi dùng chỉ lấy mức 0 (giao diện 2D: sampler không mip), nên bộ tải không nướng và không tải chuỗi mip.
    // Phông 384 x 9192 của HUD tốn 48 ms nướng mip trên luồng vẽ trước khi có cờ này (đo 2026-10-13).
    bool has_mips = true;
};

// `encoded` là một tệp PNG hoặc JPEG đủ. Kênh nào thiếu thì alpha = 255.
[[nodiscard]] core::Result<Image> decode_image(std::span<const std::byte> encoded);

// Đọc cả tệp rồi nhận PNG, JPEG hoặc DDS. Đường dẫn là UTF-8.
[[nodiscard]] core::Result<Image> load_image_file(std::string_view path);

} // namespace game::resource
