// Ảnh nhúng trong GLB (PNG hoặc JPEG) giải ra RGBA8. Không phải DDS: DDS là ảnh đã nén khối cho
// GPU, do công cụ nấu asset ghi ra sau. glTF giữ ảnh gốc trong tệp mô hình.
// Nguồn: Forge2 src/resource/image.hpp@d7fcd76. Khác gốc: bỏ {} thừa của hai thành viên name, rgba;
// include thêm <cstddef> mà header dùng trực tiếp.
#pragma once

#include "core/error.hpp"

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
    // width * height * 4 byte, hàng trên cùng trước, thẳng như PNG.
    std::vector<std::uint8_t> rgba;
};

// `encoded` là một tệp PNG hoặc JPEG đủ. Kênh nào thiếu thì alpha = 255.
[[nodiscard]] core::Result<Image> decode_image(std::span<const std::byte> encoded);

} // namespace game::resource
