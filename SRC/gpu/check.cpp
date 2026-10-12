// Kiểm mô tả texture, buffer, view và pipeline trước khi GPU tạo chúng.
// Cube đúng 6 lớp, CubeArray bội của 6; samples chỉ là 1, 2, 4 hoặc 8.
// Nguồn: Forge2 src/gpu/check.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; thân vòng lặp của
// check_inputs và check_pipeline tách hàm; check_features tách thêm check_patches và
// check_fill_and_blend; hai phép kiểm kind cuối resolve_view gom vào check_view_shape (đều ghi tại
// chỗ); khởi tạo Box ghi tên thành viên; include trực tiếp header của mọi tên dùng tới.
#include "gpu/check.hpp"

#include "core/error.hpp"
#include "gpu/binding.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"
#include "gpu/layout.hpp"
#include "gpu/pipeline.hpp"
#include "gpu/resource.hpp"
#include "gpu/types.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <algorithm>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <span>
#include <utility>

namespace game::gpu {

namespace {

using core::ErrorCode;
using core::fail;
using core::ok;
using core::Status;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;
constexpr ErrorCode kMissing = ErrorCode::kUnsupported;
constexpr ErrorCode kOutside = ErrorCode::kOutOfRange;

[[nodiscard]] bool is_array_kind(TextureKind kind) noexcept {
    return kind == TextureKind::kTex2DArray || kind == TextureKind::kCubeArray;
}

[[nodiscard]] bool is_cube_kind(TextureKind kind) noexcept {
    return kind == TextureKind::kCube || kind == TextureKind::kCubeArray;
}

// Số lớp phải hợp với loại: Cube đúng 6, CubeArray bội của 6, loại không phải mảng đúng 1.
[[nodiscard]] bool has_valid_layers(TextureKind kind, std::uint32_t layers) noexcept {
    if (kind == TextureKind::kCube) return layers == 6;
    if (kind == TextureKind::kCubeArray) return layers != 0 && layers % 6 == 0;
    if (kind == TextureKind::kTex2DArray || kind == TextureKind::kTex3D) return layers != 0;
    return layers == 1;
}

[[nodiscard]] Status check_shape(const TextureDesc& desc, const DeviceCaps& caps) {
    const std::uint32_t longest = std::max(desc.width, desc.height);
    if (desc.format == Format::kUnknown) return fail(kBad, "texture: format là Unknown");
    if (desc.width == 0 || desc.height == 0) return fail(kBad, "texture: rộng hoặc cao bằng 0");
    if (longest > caps.max_texture_size) {
        return fail(kBad, "texture: vượt cỡ lớn nhất của thiết bị", "{} > {}", longest, caps.max_texture_size);
    }
    if (!has_valid_layers(desc.kind, desc.depth_or_layers)) {
        return fail(kBad, "texture: depth_or_layers không hợp kind", "{}", desc.depth_or_layers);
    }
    if (desc.kind == TextureKind::kTex1D && desc.height != 1) return fail(kBad, "Tex1D phải cao 1");
    if (is_cube_kind(desc.kind) && desc.width != desc.height) return fail(kBad, "Cube phải vuông");
    return ok();
}

[[nodiscard]] Status check_levels(const TextureDesc& desc) {
    const std::uint32_t most = full_mip_count(desc.width, desc.height, depth_of(desc));
    const bool is_mip_valid = desc.mip_levels >= 1 && desc.mip_levels <= most;
    if (!is_mip_valid) return fail(kBad, "texture: mip_levels ngoài khoảng", "{}", desc.mip_levels);
    const bool is_sample_valid = desc.samples <= 8 && std::has_single_bit(desc.samples);
    if (!is_sample_valid) return fail(kBad, "texture: samples phải là 1, 2, 4 hoặc 8");
    if (desc.samples == 1) return ok();
    const bool is_flat = desc.kind == TextureKind::kTex2D || desc.kind == TextureKind::kTex2DArray;
    if (!is_flat || desc.mip_levels != 1) return fail(kBad, "texture đa mẫu phải là 2D, một mip");
    return ok();
}

[[nodiscard]] Status check_usage(const TextureDesc& desc) {
    using enum TextureUsage;
    const FormatInfo layout = info(desc.format);
    const bool is_depth = layout.aspect != FormatAspect::kColor;
    const TextureUsage targets = kColorTarget | kDepthStencilTarget;
    if (desc.usage == kNone) return fail(kBad, "texture: usage rỗng");
    const bool is_color_target = has(desc.usage, kColorTarget);
    if (is_depth && is_color_target) return fail(kBad, "định dạng độ sâu làm đích màu");
    if (!is_depth && has(desc.usage, kDepthStencilTarget)) {
        return fail(kBad, "định dạng màu làm đích độ sâu");
    }
    if (layout.is_compressed && overlaps(desc.usage, targets | kStorage)) {
        return fail(kBad, "định dạng nén không làm đích vẽ hay RWTexture được");
    }
    if (!has(desc.usage, kTransient)) return ok();
    const bool is_attachment_only = !overlaps(desc.usage, kSampled | kStorage | kCopySource | kCopyDest);
    if (!is_attachment_only || !overlaps(desc.usage, targets)) {
        return fail(kBad, "texture Transient chỉ được làm đích vẽ");
    }
    return ok();
}

[[nodiscard]] Status check_view_kind(TextureKind kind, std::uint32_t layers) {
    if (!has_valid_layers(kind, kind == TextureKind::kTex3D ? 1 : layers)) {
        return fail(kBad, "view: số lớp không hợp kind", "{}", layers);
    }
    return ok();
}

// Định dạng ép kiểu cần Reinterpret và cùng cỡ khối; phần Depth, Stencil phải có trong định dạng.
[[nodiscard]] Status check_view_format(const ViewRange& range, const TextureDesc& texture) {
    const bool is_cast = range.format != texture.format;
    if (is_cast && !has(texture.usage, TextureUsage::kReinterpret)) {
        return fail(kBad, "view đổi định dạng trên texture không có Reinterpret");
    }
    const FormatInfo viewed = info(range.format);
    const FormatInfo stored = info(texture.format);
    const bool is_same_block = viewed.block_bytes == stored.block_bytes && viewed.block_width == stored.block_width &&
        viewed.block_height == stored.block_height;
    if (!is_same_block) return fail(kBad, "view đổi sang định dạng khác cỡ khối");
    if (range.aspect == ViewAspect::kAll) return ok();
    const bool wants_stencil = range.aspect == ViewAspect::kStencil;
    const bool is_present = wants_stencil ? has_stencil(range.format) : has_depth(range.format);
    if (!is_present) return fail(kBad, "view: định dạng không có phần được chọn");
    return ok();
}

// Stage đứng ngay trước pixel shader trong đường ống, khi chỉ có hai stage ấy sinh và nhận chữ ký.
[[nodiscard]] const shader::StageReflection* find_stage(std::span<const shader::StageReflection> stages,
    shader::Stage stage) noexcept {
    const auto matches = [stage](const auto& item) { return item.stage == stage; };
    const auto found = std::ranges::find_if(stages, matches);
    return found == stages.end() ? nullptr : std::to_address(found);
}

// Chỉ cặp vertex rồi pixel được kiểm: chữ ký của hull, domain, geometry và mesh có thêm phần riêng
// (điểm điều khiển, hằng của patch, đầu ra theo primitive) mà phép kiểm chung chưa phủ.
[[nodiscard]] Status check_signatures(std::span<const shader::StageReflection> stages) {
    const shader::StageReflection* const vertex = find_stage(stages, shader::Stage::kVertex);
    const shader::StageReflection* const pixel = find_stage(stages, shader::Stage::kPixel);
    const bool is_direct = vertex != nullptr && pixel != nullptr && stages.size() == 2;
    return is_direct ? shader::check_interface(*vertex, *pixel) : ok();
}

[[nodiscard]] Status check_attribute(const GraphicsPipelineDesc& desc, const VertexAttribute& attribute,
    const shader::ProgramReflection& program) {
    if (attribute.buffer >= desc.vertex_buffers.size()) {
        return fail(kBad, "thuộc tính đỉnh trỏ tới buffer không khai", "location {}", attribute.location);
    }
    if (attribute.format == Format::kUnknown || info(attribute.format).is_compressed) {
        return fail(kBad, "thuộc tính đỉnh có định dạng không dùng được", "location {}", attribute.location);
    }
    if (find_input(program, attribute.location) == nullptr) {
        return fail(kBad, "vertex shader không có đầu vào ở location này", "location {}", attribute.location);
    }
    return ok();
}

// Khác gốc: lambda feeds và phép any_of trong thân vòng lặp của check_inputs tách ra đây.
[[nodiscard]] bool is_fed(const GraphicsPipelineDesc& desc, const shader::Attribute& input) {
    const auto feeds = [&](const VertexAttribute& item) { return item.location == input.location; };
    return std::ranges::any_of(desc.vertex_attributes, feeds);
}

// Mọi đầu vào của vertex shader phải có thuộc tính: thiếu thì shader đọc rác (Vulkan) hoặc pipeline
// bị từ chối không lời giải thích (D3D12).
[[nodiscard]] Status check_inputs(const GraphicsPipelineDesc& desc, const shader::ProgramReflection& program) {
    // Khác gốc: gốc là vòng for bỏ qua đầu vào đã có thuộc tính và trả lỗi ở đầu vào thiếu đầu
    // tiên; ở đây find_if tìm đúng đầu vào ấy, cùng thứ tự duyệt.
    const auto is_unfed = [&desc](const shader::Attribute& input) { return !is_fed(desc, input); };
    const auto unfed = std::ranges::find_if(program.inputs, is_unfed);
    if (unfed == program.inputs.end()) return ok();
    return fail(kBad, "đầu vào của vertex shader không có thuộc tính đỉnh", "{}{}", unfed->semantic, unfed->index);
}

[[nodiscard]] Status check_targets(const GraphicsPipelineDesc& desc) {
    const std::size_t colors = desc.color_formats.size();
    if (colors > kMaxColorTargets) return fail(kBad, "pipeline: quá kMaxColorTargets đích màu");
    const bool is_blend_count_valid = desc.blends.size() <= 1 || desc.blends.size() == colors;
    if (!is_blend_count_valid) return fail(kBad, "pipeline: blends không khớp số đích màu");
    const auto is_color = [](Format format) {
        return format != Format::kUnknown && !has_depth(format) && !info(format).is_compressed;
    };
    if (!std::ranges::all_of(desc.color_formats, is_color)) {
        return fail(kBad, "pipeline: định dạng đích màu không dùng được");
    }
    const bool is_depth_valid = desc.depth.format == Format::kUnknown || has_depth(desc.depth.format);
    if (!is_depth_valid) return fail(kBad, "pipeline: depth.format không phải định dạng độ sâu");
    const bool is_sample_valid = desc.samples <= 8 && std::has_single_bit(desc.samples);
    if (!is_sample_valid) return fail(kBad, "pipeline: samples phải là 1, 2, 4 hoặc 8");
    return ok();
}

// Khác gốc: check_features của gốc là một hàm bảy câu bảo vệ (cognitive complexity 15, trần 10).
// Hai câu đầu thành check_patches, hai câu cuối thành check_fill_and_blend; thứ tự kiểm giữ nguyên.
[[nodiscard]] Status check_patches(const GraphicsPipelineDesc& desc, const DeviceCaps& caps) {
    const bool wants_patch = desc.topology == Topology::kPatchList;
    if (wants_patch && !caps.tessellation) return fail(kMissing, "thiết bị không có tessellation");
    if (wants_patch && (desc.patch_points == 0 || desc.patch_points > 32)) {
        return fail(kBad, "pipeline: patch_points phải trong 1..32");
    }
    return ok();
}

[[nodiscard]] Status check_fill_and_blend(const GraphicsPipelineDesc& desc, const DeviceCaps& caps) {
    const bool lacks_wireframe = desc.raster.fill == FillMode::kWireframe && !caps.wireframe;
    if (lacks_wireframe) return fail(kMissing, "thiết bị không vẽ được khung dây");
    if (desc.blends.size() > 1 && !caps.independent_blend) {
        return fail(kMissing, "thiết bị không trộn riêng được từng đích màu");
    }
    return ok();
}

[[nodiscard]] Status check_features(const GraphicsPipelineDesc& desc, const DeviceCaps& caps) {
    const Status patches = check_patches(desc, caps);
    if (!patches) return patches;
    if (desc.raster.is_conservative && !caps.conservative_raster) {
        return fail(kMissing, "thiết bị không có conservative rasterization");
    }
    if (desc.depth.is_bounds_tested && !caps.depth_bounds) {
        return fail(kMissing, "thiết bị không có phép thử khoảng độ sâu");
    }
    if (!desc.raster.is_depth_clipped && !caps.depth_clamp) {
        return fail(kMissing, "thiết bị không kẹp được độ sâu");
    }
    return check_fill_and_blend(desc, caps);
}

// Cỡ của vùng theo một chiều khi chỗ gọi để 0: tới hết mức mip.
[[nodiscard]] std::uint32_t span_of(std::uint32_t asked, std::uint32_t start, std::uint32_t full) noexcept {
    if (asked != 0 || start >= full) return asked;
    return full - start;
}

// [start, start + size) nằm trong [0, full), không rỗng, và khớp biên khối block: bắt đầu ở biên
// khối, kết thúc ở biên khối hoặc ở mép mức mip.
[[nodiscard]] bool fits_axis(std::uint32_t start, std::uint32_t size, std::uint32_t full,
    std::uint32_t block) noexcept {
    const bool is_inside = size != 0 && start < full && size <= full - start;
    if (!is_inside) return false;
    const bool ends_on_block = size % block == 0 || start + size == full;
    return start % block == 0 && ends_on_block;
}

// Một hình hộp trong mức mip của một texture.
struct Box {
    std::uint32_t mip = 0;
    std::uint32_t x = 0;
    std::uint32_t y = 0;
    std::uint32_t z = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t depth = 0;
};

[[nodiscard]] bool fits_box(const Box& box, const TextureDesc& texture) noexcept {
    const FormatInfo layout = info(texture.format);
    const std::uint32_t full_width = mip_size(texture.width, box.mip);
    const std::uint32_t full_height = mip_size(texture.height, box.mip);
    const std::uint32_t full_depth = mip_size(depth_of(texture), box.mip);
    const bool is_flat = fits_axis(box.x, box.width, full_width, layout.block_width) &&
        fits_axis(box.y, box.height, full_height, layout.block_height);
    return is_flat && fits_axis(box.z, box.depth, full_depth, 1);
}

// Khoảng lớp [first, first + count) nằm trong texture và mip có thật.
[[nodiscard]] bool has_layers(const TextureDesc& texture, std::uint32_t mip, std::uint32_t first,
    std::uint32_t count) noexcept {
    const std::uint32_t layers = layer_count(texture);
    const bool is_inside = count >= 1 && first < layers && count <= layers - first;
    return mip < texture.mip_levels && is_inside;
}

// Bước dòng và căn của dữ liệu trong buffer; region đã có width, height, depth và rows.
[[nodiscard]] Status check_rows(const CopyRegion& region, Format format, std::uint64_t buffer_size) {
    const std::uint64_t tight = row_bytes(format, region.width);
    const std::uint32_t block = info(format).block_bytes;
    const bool is_row_valid =
        region.row_bytes % kTextureRowAlignment == 0 && region.row_bytes % block == 0 && region.row_bytes >= tight;
    if (!is_row_valid) return fail(kBad, "chép: row_bytes sai căn hoặc hẹp hơn một dòng");
    if (region.buffer_offset % kTextureOffsetAlignment != 0) {
        return fail(kBad, "chép: buffer_offset không căn theo kTextureOffsetAlignment");
    }
    const std::uint64_t layer_bytes = std::uint64_t{region.row_bytes} * region.rows * region.depth;
    const bool is_stacked = region.layer_count > 1;
    if (is_stacked && layer_bytes % kTextureOffsetAlignment != 0) {
        return fail(kBad, "chép nhiều lớp: cỡ một lớp không căn theo kTextureOffsetAlignment");
    }
    // Dòng cuối của lát cuối không cần phần đệm.
    const std::uint64_t total = (layer_bytes * region.layer_count) - (region.row_bytes - tight);
    return check_span(buffer_size, region.buffer_offset, total);
}

} // namespace

core::Result<CopyRegion> resolve_copy(const BufferTextureCopy& region, const TextureDesc& texture,
    std::uint64_t buffer_size) {
    if (!has_layers(texture, region.mip, region.first_layer, region.layer_count)) {
        return fail(kBad, "chép: mip hoặc lớp ngoài texture");
    }
    if (texture.samples != 1) return fail(kBad, "chép: texture đa mẫu không chép với buffer được");
    const bool is_planar = has_stencil(texture.format);
    if (is_planar) return fail(kMissing, "chép: định dạng có stencil chưa chép được");
    CopyRegion out{.buffer_offset = region.buffer_offset, .mip = region.mip};
    out.first_layer = region.first_layer;
    out.layer_count = region.layer_count;
    out.x = region.x;
    out.y = region.y;
    out.z = region.z;
    out.width = span_of(region.width, region.x, mip_size(texture.width, region.mip));
    out.height = span_of(region.height, region.y, mip_size(texture.height, region.mip));
    out.depth = span_of(region.depth, region.z, mip_size(depth_of(texture), region.mip));
    const Box box{.mip = region.mip,
        .x = out.x,
        .y = out.y,
        .z = out.z,
        .width = out.width,
        .height = out.height,
        .depth = out.depth};
    if (!fits_box(box, texture)) return fail(kBad, "chép: vùng ngoài mức mip hoặc lệch biên khối");
    const std::uint64_t padded = padded_row_bytes(texture.format, out.width);
    out.row_bytes = region.row_bytes == 0 ? static_cast<std::uint32_t>(padded) : region.row_bytes;
    out.rows = row_count(texture.format, out.height);
    const Status rows = check_rows(out, texture.format, buffer_size);
    if (!rows) return std::unexpected(rows.error());
    return out;
}

core::Result<TextureCopy> resolve_copy(const TextureCopy& region, const TextureDesc& source,
    const TextureDesc& target) {
    const bool is_same_kind = source.format == target.format && source.samples == target.samples &&
        (source.kind == TextureKind::kTex3D) == (target.kind == TextureKind::kTex3D);
    if (!is_same_kind) return fail(kBad, "chép texture: khác định dạng, số mẫu hoặc số chiều");
    const bool has_range = has_layers(source, region.source.mip, region.source.layer, region.layer_count) &&
        has_layers(target, region.target.mip, region.target.layer, region.layer_count);
    if (!has_range) return fail(kBad, "chép texture: mip hoặc lớp ngoài texture");
    const TexturePoint& from = region.source;
    const TexturePoint& destination = region.target;
    TextureCopy out = region;
    out.width = span_of(region.width, from.x, mip_size(source.width, from.mip));
    out.height = span_of(region.height, from.y, mip_size(source.height, from.mip));
    out.depth = span_of(region.depth, from.z, mip_size(depth_of(source), from.mip));
    const Box taken{.mip = from.mip,
        .x = from.x,
        .y = from.y,
        .z = from.z,
        .width = out.width,
        .height = out.height,
        .depth = out.depth};
    const Box placed{.mip = destination.mip,
        .x = destination.x,
        .y = destination.y,
        .z = destination.z,
        .width = out.width,
        .height = out.height,
        .depth = out.depth};
    const bool is_fitting = fits_box(taken, source) && fits_box(placed, target);
    if (!is_fitting) return fail(kBad, "chép texture: vùng ngoài mức mip hoặc lệch biên khối");
    return out;
}

Status check_buffer(const BufferDesc& desc) {
    if (desc.size == 0) return fail(kBad, "buffer: size bằng 0");
    if (desc.usage == BufferUsage::kNone) return fail(kBad, "buffer: usage rỗng");
    return ok();
}

Status check_texture(const TextureDesc& desc, const DeviceCaps& caps) {
    const Status shape = check_shape(desc, caps);
    if (!shape) return shape;
    const Status levels = check_levels(desc);
    if (!levels) return levels;
    return check_usage(desc);
}

namespace {

// Khác gốc: hai phép kiểm kind ở cuối resolve_view của gốc gom vào đây, thứ tự giữ nguyên
// (resolve_view của gốc có cognitive complexity 11, trần 10).
[[nodiscard]] Status check_view_shape(const TextureViewDesc& view, const TextureDesc& texture, std::uint32_t layers) {
    if (is_array_kind(view.kind) != is_array_kind(texture.kind) && is_cube_kind(view.kind)) {
        return fail(kBad, "view Cube trên texture không có sáu mặt");
    }
    return check_view_kind(view.kind, layers);
}

} // namespace

core::Result<ViewRange> resolve_view(const TextureViewDesc& view, const TextureDesc& texture) {
    const std::uint32_t layers = layer_count(texture);
    const bool is_inside = view.first_mip < texture.mip_levels && view.first_layer < layers;
    if (!is_inside) return fail(kBad, "view: mip hoặc lớp đầu ngoài texture");
    ViewRange range{.format = view.format, .aspect = view.aspect};
    range.first_mip = view.first_mip;
    range.first_layer = view.first_layer;
    if (range.format == Format::kUnknown) range.format = texture.format;
    const Status format = check_view_format(range, texture);
    if (!format) return std::unexpected(format.error());
    const std::uint32_t mips_left = texture.mip_levels - view.first_mip;
    const std::uint32_t layers_left = layers - view.first_layer;
    range.mip_count = view.mip_count == kAllMips ? mips_left : view.mip_count;
    range.layer_count = view.layer_count == kAllLayers ? layers_left : view.layer_count;
    const bool is_fitting = range.mip_count >= 1 && range.mip_count <= mips_left && range.layer_count >= 1 &&
        range.layer_count <= layers_left;
    if (!is_fitting) return fail(kBad, "view: khoảng mip hoặc lớp vượt texture");
    const Status kind = check_view_shape(view, texture, range.layer_count);
    if (!kind) return std::unexpected(kind.error());
    return range;
}

Status check_span(std::uint64_t size, std::uint64_t offset, std::uint64_t count) {
    const bool is_inside = offset <= size && count <= size - offset;
    if (is_inside) return ok();
    return fail(kOutside, "khoảng vượt biên buffer", "offset {} + {} > {}", offset, count, size);
}

core::Result<std::uint64_t> resolve_range(const BufferRange& range, std::uint64_t size) {
    if (range.offset >= size) return fail(kOutside, "BufferRange bắt đầu ngoài buffer");
    const std::uint64_t count = range.size == kWholeSize ? size - range.offset : range.size;
    const Status inside = check_span(size, range.offset, count);
    if (!inside) return std::unexpected(inside.error());
    if (count == 0) return fail(kBad, "BufferRange rỗng");
    return count;
}

Status check_capacity(const SpaceLayout& space, std::uint32_t capacity, const DeviceCaps& caps) {
    const shader::Resource* const open = unbounded_resource(space);
    if (open == nullptr) return ok();
    if (!caps.bindless) return fail(kMissing, "thiết bị thiếu mảng không chặn", "{}", open->name);
    const bool is_sampler = open->kind == shader::ResourceKind::kSampler;
    const std::uint32_t most = is_sampler ? caps.max_unbounded_samplers : caps.max_unbounded;
    if (capacity <= most) return ok();
    return fail(kMissing, "nhóm gắn: capacity vượt trần của thiết bị", "{} > {}", capacity, most);
}

namespace {

// NOLINTBEGIN(bugprone-easily-swappable-parameters): nội bộ, chỉ resolve_binding gọi (lệch API-03)
[[nodiscard]] core::Result<std::uint64_t> resolve_uniform(const BufferRange& range, std::uint64_t left,
    std::uint64_t block) {
    if (range.offset % kUniformAlignment != 0) {
        return fail(kBad, "nhóm gắn: offset của cbuffer không là bội của kUniformAlignment");
    }
    const std::uint64_t size = range.size == kWholeSize ? block : range.size;
    if (size < block) return fail(kBad, "nhóm gắn: khoảng buffer nhỏ hơn cbuffer của shader");
    const std::uint64_t padded = (size + kUniformAlignment - 1) / kUniformAlignment * kUniformAlignment;
    if (padded > left) return fail(kOutside, "nhóm gắn: cbuffer làm tròn 256 byte vượt buffer");
    return size;
}
// NOLINTEND(bugprone-easily-swappable-parameters)

} // namespace

core::Result<std::uint64_t> resolve_binding(const SpaceLayout& space, const shader::Resource& resource,
    const BufferRange& range, std::uint64_t buffer_size) {
    const core::Result<std::uint64_t> left = resolve_range(range, buffer_size);
    if (!left) return left;
    if (resource.kind == shader::ResourceKind::kUniformBuffer) {
        return resolve_uniform(range, buffer_size - range.offset, block_size(space, resource));
    }
    // ByteAddressBuffer đọc theo word 4 byte. Để kWholeSize thì phần lẻ cuối buffer bị bỏ.
    const std::uint64_t stride = resource.raw ? 4 : std::max<std::uint64_t>(resource.stride, 1);
    const std::uint64_t size = range.size == kWholeSize ? *left / stride * stride : *left;
    const bool is_aligned = range.offset % stride == 0 && size % stride == 0 && size != 0;
    if (!is_aligned) return fail(kBad, "nhóm gắn: khoảng buffer không là bội của cỡ phần tử");
    return size;
}

core::Result<Program> make_program(std::span<const shader::StageReflection> stages) {
    core::Result<shader::ProgramReflection> merged = shader::merge(stages);
    if (!merged) return std::unexpected(std::move(merged).error());
    const Status signatures = check_signatures(stages);
    if (!signatures) return std::unexpected(signatures.error());
    core::Result<ProgramLayout> layout = make_layout(*merged);
    if (!layout) return std::unexpected(std::move(layout).error());
    return Program{.reflection = std::move(*merged), .layout = std::move(*layout)};
}

namespace {

// Khác gốc: vòng for của check_pipeline có câu if (!checked) return checked trong thân; tách ra
// đây, vòng dừng ở thuộc tính sai đầu tiên và trả lỗi của nó.
[[nodiscard]] Status check_attributes(const GraphicsPipelineDesc& desc, const shader::ProgramReflection& program) {
    Status checked = ok();
    const auto end = desc.vertex_attributes.end();
    for (auto item = desc.vertex_attributes.begin(); item != end && checked; ++item) {
        checked = check_attribute(desc, *item, program);
    }
    return checked;
}

} // namespace

Status check_pipeline(const GraphicsPipelineDesc& desc, const Program& program, const DeviceCaps& caps) {
    const Status targets = check_targets(desc);
    if (!targets) return targets;
    const Status features = check_features(desc, caps);
    if (!features) return features;
    const bool has_extra_buffers = desc.vertex_buffers.size() > kMaxVertexBuffers;
    if (has_extra_buffers) return fail(kBad, "pipeline: quá kMaxVertexBuffers");
    if (desc.vertex_attributes.size() > kMaxVertexAttributes) {
        return fail(kBad, "pipeline: quá kMaxVertexAttributes");
    }
    const Status attributes = check_attributes(desc, program.reflection);
    if (!attributes) return attributes;
    return check_inputs(desc, program.reflection);
}

const shader::Attribute* find_input(const shader::ProgramReflection& program, std::uint32_t location) noexcept {
    const auto matches = [location](const auto& input) { return input.location == location; };
    const auto found = std::ranges::find_if(program.inputs, matches);
    return found == program.inputs.end() ? nullptr : std::to_address(found);
}

} // namespace game::gpu
