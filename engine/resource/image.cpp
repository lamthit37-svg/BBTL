// Giải PNG và JPEG nhúng trong GLB. stb_image là bộ giải đã có qua vcpkg; một lần định nghĩa ở
// tệp này.
#include "resource/image.hpp"

#include <cstdlib>

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_STATIC
#include <stb_image.h>

namespace game::resource {

namespace {

struct Pixels {
    Pixels() = default;
    std::uint8_t* data = nullptr;
    ~Pixels() { stbi_image_free(data); }
    Pixels(const Pixels&) = delete;
    Pixels& operator=(const Pixels&) = delete;
};

} // namespace

core::Result<Image> decode_image(std::span<const std::byte> encoded) {
    if (encoded.empty()) return core::fail(core::ErrorCode::kInvalidArgument, "ảnh rỗng");
    if (encoded.size() > static_cast<std::size_t>(INT_MAX)) {
        return core::fail(core::ErrorCode::kOverflow, "ảnh quá lớn");
    }
    int width = 0;
    int height = 0;
    int channels = 0;
    Pixels pixels;
    pixels.data = stbi_load_from_memory(reinterpret_cast<const stbi_uc*>(encoded.data()),
        static_cast<int>(encoded.size()), &width, &height, &channels, 4);
    if (pixels.data == nullptr || width <= 0 || height <= 0) {
        return core::fail(core::ErrorCode::kCorrupt, "không giải được ảnh");
    }
    Image image;
    image.width = static_cast<std::uint32_t>(width);
    image.height = static_cast<std::uint32_t>(height);
    const std::size_t bytes = static_cast<std::size_t>(image.width) * image.height * 4;
    image.rgba.assign(pixels.data, pixels.data + bytes);
    return image;
}

} // namespace game::resource
