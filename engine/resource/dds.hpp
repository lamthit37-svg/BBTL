// Đọc DDS thô của client gốc: DXT1/DXT3/DXT5 thành khối BCn, A8R8G8B8 thành RGBA8.
// Không giải khối, không nướng mip. Từ chối cube, volume và DX10.
#pragma once

#include "core/error.hpp"
#include "resource/image.hpp"

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

namespace game::resource {

// `bytes` là cả tệp. Ảnh khối nén có levels; ảnh 32 bit chỉ có rgba của mức 0.
[[nodiscard]] core::Result<Image> read_dds(std::span<const std::byte> bytes);

// GLB cook ghi URI `tên.dds.png`. Bỏ đuôi `.png` thì ra tệp DDS gốc. Rỗng nếu không phải dạng đó.
[[nodiscard]] std::string dds_sibling(std::string_view path);

} // namespace game::resource
