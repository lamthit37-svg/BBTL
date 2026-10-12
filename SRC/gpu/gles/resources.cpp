// Texture, view và sampler GL. Ảnh upload giữ thứ tự byte của RHI (không lật UV).
#include "gpu/gles/device.hpp"

#include "gpu/check.hpp"

#include <algorithm>

namespace game::gpu::gles {
namespace {

using core::ErrorCode;
using core::fail;

struct TexFormat {
    std::uint32_t internal = 0;
    std::uint32_t format = GL_RGBA;
    std::uint32_t type = GL_UNSIGNED_BYTE;
    bool srgb = false;
    bool depth = false;
};

[[nodiscard]] TexFormat tex_format(Format format) noexcept {
    switch (format) {
    case Format::kRgba8Unorm: return {GL_RGBA8, GL_RGBA, GL_UNSIGNED_BYTE, false, false};
    // Thiết bị màu thô (xem device.hpp): định dạng khai sRGB vẫn cất là RGBA8 thường, phần cứng
    // không đổi gì lúc lấy mẫu lẫn lúc ghi. Cờ srgb chỉ còn nghĩa "khai là sRGB", cho lệnh xoá.
    case Format::kRgba8UnormSrgb: return {GL_RGBA8, GL_RGBA, GL_UNSIGNED_BYTE, true, false};
    case Format::kD32Float: return {GL_DEPTH_COMPONENT32F, GL_DEPTH_COMPONENT, GL_FLOAT, false, true};
    case Format::kD24UnormS8Uint: return {GL_DEPTH24_STENCIL8, GL_DEPTH_COMPONENT, GL_FLOAT, false, true};
    default: return {};
    }
}

[[nodiscard]] std::uint32_t address_of(AddressMode mode) noexcept {
    switch (mode) {
    case AddressMode::kRepeat: return GL_REPEAT;
    case AddressMode::kMirrorRepeat: return GL_MIRRORED_REPEAT;
    case AddressMode::kClampToEdge: return GL_CLAMP_TO_EDGE;
    case AddressMode::kClampToBorder: return GL_CLAMP_TO_BORDER;
    }
    return GL_REPEAT;
}

[[nodiscard]] std::uint32_t min_filter(Filter min, Filter mip) noexcept {
    if (min == Filter::kNearest && mip == Filter::kNearest) return GL_NEAREST_MIPMAP_NEAREST;
    if (min == Filter::kNearest) return GL_NEAREST_MIPMAP_LINEAR;
    if (mip == Filter::kNearest) return GL_LINEAR_MIPMAP_NEAREST;
    return GL_LINEAR_MIPMAP_LINEAR;
}

} // namespace

Result<TextureHandle> GlDevice::create_texture(const TextureDesc& desc) {
    const core::Status checked = check_texture(desc, caps_);
    if (!checked) return std::unexpected(checked.error());
    if (desc.kind != TextureKind::kTex2D) {
        return fail(ErrorCode::kUnsupported, "GLES chỉ tạo texture 2D");
    }
    const TexFormat format = tex_format(desc.format);
    if (format.internal == 0) return fail(ErrorCode::kUnsupported, "định dạng texture GL chưa có");
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    GlTexture texture;
    texture.kind = desc.kind;
    texture.format = desc.format;
    texture.width = desc.width;
    texture.height = desc.height;
    texture.layers = desc.depth_or_layers;
    texture.mips = desc.mip_levels;
    texture.samples = desc.samples;
    texture.usage = desc.usage;
    texture.srgb = format.srgb;
    texture.is_target = has(desc.usage, TextureUsage::kColorTarget);
    texture.target = desc.samples > 1 ? GL_TEXTURE_2D_MULTISAMPLE : GL_TEXTURE_2D;
    api().gen_textures(1, &texture.name);
    api().bind_texture(texture.target, texture.name);
    // Tạo texture gắn nó vào đơn vị đang bật: bộ nhớ đệm trạng thái vẽ không còn đúng.
    invalidate_draw_cache();
    if (desc.samples > 1) {
        const int sample_count = static_cast<int>(desc.samples);
        const int image_width = static_cast<int>(desc.width);
        const int image_height = static_cast<int>(desc.height);
        const bool has_storage = api().tex_storage_multisample != nullptr;
        if (!has_storage && api().tex_image_multisample == nullptr) {
            api().delete_textures(1, &texture.name);
            unlock_context();
            return fail(ErrorCode::kUnsupported, "GL không có texture đa mẫu");
        }
        if (has_storage) {
            api().tex_storage_multisample(texture.target, sample_count, format.internal, image_width, image_height,
                GL_TRUE);
        } else {
            api().tex_image_multisample(texture.target, sample_count, format.internal, image_width, image_height,
                GL_TRUE);
        }
    } else {
        const std::uint32_t levels = std::max(desc.mip_levels, 1U);
        for (std::uint32_t level = 0; level < levels; ++level) {
            const int mip_width = std::max(static_cast<int>(desc.width >> level), 1);
            const int mip_height = std::max(static_cast<int>(desc.height >> level), 1);
            api().tex_image(texture.target, static_cast<int>(level), static_cast<int>(format.internal), mip_width,
                mip_height, 0, format.format, format.type, nullptr);
        }
        api().tex_parameter(texture.target, 0x813C, 0);
        api().tex_parameter(texture.target, 0x813D, static_cast<int>(levels - 1));
        api().tex_parameter(texture.target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        api().tex_parameter(texture.target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        api().tex_parameter(texture.target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        api().tex_parameter(texture.target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    texture_names_.push_back(texture.name);
    const std::uint64_t bytes = static_cast<std::uint64_t>(desc.width) * desc.height * 4U * desc.samples;
    used_bytes_ += bytes;
    const TextureHandle handle = textures_.insert(std::move(texture));
    unlock_context();
    if (!handle) return fail(ErrorCode::kOutOfMemory, "hết chỗ bảng texture GL");
    return handle;
}

Result<TextureViewHandle> GlDevice::create_view(const TextureViewDesc& desc) {
    GlTexture* texture = textures_.find(desc.texture);
    if (texture == nullptr) return fail(ErrorCode::kInvalidArgument, "view: texture đã chết");
    TextureDesc stored;
    stored.kind = texture->kind;
    stored.format = texture->format;
    stored.width = texture->width;
    stored.height = texture->height;
    stored.depth_or_layers = texture->layers;
    stored.mip_levels = texture->mips;
    stored.samples = texture->samples;
    stored.usage = texture->usage;
    const core::Result<ViewRange> range = resolve_view(desc, stored);
    if (!range) return std::unexpected(range.error());
    GlView view;
    view.texture = desc.texture;
    view.name = texture->name;
    view.target = texture->target;
    view.format = desc.format == Format::kUnknown ? texture->format : desc.format;
    view.width = texture->width;
    view.height = texture->height;
    view.samples = texture->samples;
    view.srgb = texture->srgb;
    view.is_target = texture->is_target;
    view.has_depth = has_depth(view.format);
    const TextureViewHandle handle = views_.insert(std::move(view));
    if (!handle) return fail(ErrorCode::kOutOfMemory, "hết chỗ bảng view GL");
    return handle;
}

Result<SamplerHandle> GlDevice::create_sampler(const SamplerDesc& desc) {
    if (!lock_context()) return fail(ErrorCode::kUnsupported, "context GL không current");
    GlSampler sampler;
    api().gen_samplers(1, &sampler.name);
    const std::uint32_t mag = desc.mag_filter == Filter::kNearest ? GL_NEAREST : GL_LINEAR;
    api().sampler_parameter(sampler.name, GL_TEXTURE_MAG_FILTER, static_cast<int>(mag));
    const std::uint32_t min = desc.min_filter == Filter::kNearest && desc.mip_filter == Filter::kNearest
        ? GL_NEAREST
        : min_filter(desc.min_filter, desc.mip_filter);
    api().sampler_parameter(sampler.name, GL_TEXTURE_MIN_FILTER, static_cast<int>(min));
    api().sampler_parameter(sampler.name, GL_TEXTURE_WRAP_S, static_cast<int>(address_of(desc.address_u)));
    api().sampler_parameter(sampler.name, GL_TEXTURE_WRAP_T, static_cast<int>(address_of(desc.address_v)));
    if (desc.max_anisotropy > 1 && caps_.max_anisotropy > 1) {
        const float limit = static_cast<float>(std::min(desc.max_anisotropy, caps_.max_anisotropy));
        api().sampler_parameterf(sampler.name, GL_TEXTURE_MAX_ANISOTROPY, limit);
    }
    sampler_names_.push_back(sampler.name);
    const SamplerHandle handle = samplers_.insert(std::move(sampler));
    unlock_context();
    if (!handle) return fail(ErrorCode::kOutOfMemory, "hết chỗ bảng sampler GL");
    return handle;
}

} // namespace game::gpu::gles
