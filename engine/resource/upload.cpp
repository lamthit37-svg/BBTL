// Trung chuyển lưới và RGBA8 lên GPU. Buffer Upload nhận byte từ CPU, lệnh chép đưa sang bộ nhớ
// thiết bị, rồi một rào để lần vẽ sau đọc được. Texture mới tạo ở bố cục chưa định, nên phải
// chuyển sang CopyDest trước lệnh chép và sang ShaderRead sau đó. Nướng chuỗi mip là việc thuần CPU
// và không đụng thiết bị (stage_image), nên gọi được ở luồng nạp trước khi tới lượt tải lên GPU.
// Khác gốc: ngữ cảnh của một lần tải (thiết bị, danh sách lệnh, model, buffer trung chuyển, tay nắm
// đã tạo) gom vào lớp Transfer và các bước tải thành hàm thành viên của nó, thay cho hàm tự do
// chuyền năm tới bảy tham số; stage_buffer trả tay nắm thay cho tham số ra. byte_view của gốc thành
// bytes_of nhận vector có kiểu (hết con trỏ void kèm hai số), pack_level nhận cả Source, window_end
// nhập vào write_texel. Nướng mip đọc và ghi qua std::span thay cho cộng con trỏ (add_row của gốc
// thành add_run nhận một đoạn hàng). Đo 2026-10-08 trên i5-14600KF, stage_images bốn ảnh cỡ 2048,
// trung vị 135 tới 165 vòng: chậm hơn bản con trỏ 1 tới 2,4% với MSVC /O2, 0,6 tới 1,5% với Clang
// -O2, dưới ngưỡng 3% đã định. downsample_into bỏ noexcept vì nó cấp phát. Thứ tự lời gọi thiết bị,
// công thức và thông điệp lỗi giữ nguyên; tests/resource_upload_tests.cpp canh các điều này.
#include "resource/upload.hpp"

#include "core/error.hpp"
#include "gpu/command.hpp"
#include "gpu/device.hpp"
#include "gpu/format.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <limits>
#include <ranges>
#include <type_traits>
#include <utility>
#include <vector>

namespace game::resource {

namespace {

namespace gpu = game::gpu;
namespace core = game::core;

static_assert(std::is_trivially_copyable_v<Vertex>);
static_assert(std::is_trivially_copyable_v<MorphVertex>);
static_assert(sizeof(MorphVertex) == 3 * sizeof(math::Float3) + 2 * sizeof(math::Float2) + sizeof(math::Float4));
static_assert(sizeof(Vertex) == 96);

[[nodiscard]] core::Failure overflow(core::Message message) {
    return core::fail(core::ErrorCode::kOverflow, message);
}

[[nodiscard]] ColorSpace space_of(gpu::Format format) noexcept {
    if (format == gpu::Format::kRgba8UnormSrgb) return ColorSpace::kSrgb;
    return ColorSpace::kLinear;
}

// Chạy một bước cho từng phần tử và trả lỗi đầu tiên; sau lỗi thì không gọi bước nữa. Có hàm này
// thì thân các vòng nạp vẫn phẳng: bước là một lời gọi, không phải câu if trong vòng lặp (PH-01).
template <typename Range, typename Step>
[[nodiscard]] core::Status each_status(const Range& range, const Step& step) {
    core::Status status = core::ok();
    for (const auto& item : range) {
        status = status ? step(item) : status;
    }
    return status;
}

struct Usage {
    bool srgb = false;
    bool linear = false;
};

void mark_slot(const TexSlot& slot, std::uint32_t index, bool& hit) noexcept {
    if (slot.image.has_value() && *slot.image == index) hit = true;
}

void mark_core(const Material& material, std::uint32_t index, Usage& usage) noexcept {
    mark_slot(material.color, index, usage.srgb);
    mark_slot(material.emissive_map, index, usage.srgb);
    mark_slot(material.diffuse_map, index, usage.srgb);
    mark_slot(material.gloss_map, index, usage.srgb);
    mark_slot(material.surface, index, usage.linear);
    mark_slot(material.normal, index, usage.linear);
    mark_slot(material.occlusion, index, usage.linear);
}

void mark_coat(const std::optional<Coat>& coat, std::uint32_t index, Usage& usage) noexcept {
    if (!coat.has_value()) return;
    mark_slot(coat->strength, index, usage.linear);
    mark_slot(coat->roughness_map, index, usage.linear);
    mark_slot(coat->normal, index, usage.linear);
}

void mark_sheen(const std::optional<Sheen>& sheen, std::uint32_t index, Usage& usage) noexcept {
    if (!sheen.has_value()) return;
    mark_slot(sheen->color_map, index, usage.srgb);
    mark_slot(sheen->roughness_map, index, usage.linear);
}

void mark_specular(const std::optional<Specular>& specular, std::uint32_t index, Usage& usage) noexcept {
    if (!specular.has_value()) return;
    mark_slot(specular->color_map, index, usage.srgb);
    mark_slot(specular->factor_map, index, usage.linear);
}

void mark_scatter(const std::optional<Scatter>& scatter, std::uint32_t index, Usage& usage) noexcept {
    if (!scatter.has_value()) return;
    mark_slot(scatter->color_map, index, usage.srgb);
    mark_slot(scatter->factor_map, index, usage.linear);
}

void mark_rest(const Material& material, std::uint32_t index, Usage& usage) noexcept {
    mark_coat(material.coat, index, usage);
    mark_sheen(material.sheen, index, usage);
    mark_specular(material.specular, index, usage);
    mark_scatter(material.scatter, index, usage);
    if (material.transmission.has_value()) {
        mark_slot(material.transmission->texture, index, usage.linear);
    }
    if (material.anisotropy.has_value()) {
        mark_slot(material.anisotropy->texture, index, usage.linear);
    }
    if (material.volume.has_value()) {
        mark_slot(material.volume->thickness_map, index, usage.linear);
    }
    if (material.iridescence.has_value()) {
        mark_slot(material.iridescence->factor_map, index, usage.linear);
        mark_slot(material.iridescence->thickness_map, index, usage.linear);
    }
}

[[nodiscard]] bool is_color_only(const Model& model, std::uint32_t index) noexcept {
    Usage usage;
    for (const Material& material : model.materials) {
        mark_core(material, index, usage);
        mark_rest(material, index, usage);
    }
    return usage.srgb && !usage.linear;
}

[[nodiscard]] core::Result<std::span<const std::byte>> byte_view(const void* data, std::size_t count,
    std::size_t stride) {
    if (count == 0) return core::fail(core::ErrorCode::kInvalidArgument, "buffer rỗng");
    if (stride == 0 || count > std::numeric_limits<std::size_t>::max() / stride) {
        return overflow("buffer quá lớn");
    }
    const auto* bytes = static_cast<const std::byte*>(data);
    return std::span<const std::byte>(bytes, count * stride);
}

void release_primitive(gpu::Device& device, GpuPrimitive& primitive) noexcept {
    device.destroy(primitive.vertices);
    device.destroy(primitive.indices);
    for (const gpu::BufferHandle handle : primitive.morphs) {
        device.destroy(handle);
    }
    primitive = {};
}

void release_mesh(gpu::Device& device, GpuMesh& mesh) noexcept {
    for (GpuPrimitive& primitive : mesh.primitives) {
        release_primitive(device, primitive);
    }
}

void release_meshes(gpu::Device& device, std::vector<GpuMesh>& meshes) noexcept {
    for (GpuMesh& mesh : meshes) {
        release_mesh(device, mesh);
    }
    meshes.clear();
}

void release_images(gpu::Device& device, std::vector<GpuImage>& images) noexcept {
    for (GpuImage& image : images) {
        device.destroy(image.view);
        device.destroy(image.texture);
        image = {};
    }
    images.clear();
}

void release_samplers(gpu::Device& device, std::vector<gpu::SamplerHandle>& samplers,
    gpu::SamplerHandle& fallback) noexcept {
    for (const gpu::SamplerHandle handle : samplers) {
        device.destroy(handle);
    }
    samplers.clear();
    device.destroy(fallback);
    fallback = {};
}

// Buffer trung chuyển. Destructor trả chúng sau khi GPU đã chép xong, hoặc khi nạp thất bại.
class Scratch {
public:
    Scratch(gpu::Device& device, Baked baked) noexcept : device_(&device), baked_(baked) {}
    Scratch(const Scratch&) = delete;
    Scratch& operator=(const Scratch&) = delete;
    Scratch(Scratch&&) = delete;
    Scratch& operator=(Scratch&&) = delete;
    ~Scratch() { release(); }

    void add(gpu::BufferHandle handle) { handles_.push_back(handle); }

    // Chuỗi mip của ảnh index: bản đã nướng sẵn ở luồng nạp khi người gọi đưa, không thì nướng tại
    // chỗ. Con trỏ trả về sống tới lần gọi kế.
    [[nodiscard]] core::Result<const StagedImage*> chain(const Image& source, ColorSpace space, std::uint32_t index) {
        if (index < baked_.size()) return &baked_[index];
        auto staged = stage_image(source, space);
        if (!staged) return std::unexpected(staged.error());
        fresh_ = std::move(*staged);
        return &fresh_;
    }

    void release() noexcept {
        if (device_ == nullptr) return;
        for (const gpu::BufferHandle handle : handles_) {
            device_->destroy(handle);
        }
        handles_.clear();
        device_ = nullptr;
    }

private:
    gpu::Device* device_ = nullptr;
    std::vector<gpu::BufferHandle> handles_{};
    Baked baked_;
    StagedImage fresh_;
};

struct Owned {
    std::vector<GpuMesh> meshes{};
    std::vector<GpuImage> images{};
    std::vector<gpu::SamplerHandle> samplers{};
    gpu::SamplerHandle fallback{};
};

struct ImageCopy {
    gpu::BufferHandle source{};
    gpu::TextureHandle target{};
    std::vector<gpu::BufferTextureCopy> regions{};
};

[[nodiscard]] core::Status stage_buffer(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    std::span<const std::byte> bytes, gpu::BufferUsage usage, std::string_view name, gpu::BufferHandle& out) {
    gpu::BufferDesc stage;
    stage.name = name;
    stage.size = bytes.size();
    stage.usage = gpu::BufferUsage::kCopySource;
    stage.memory = gpu::MemoryDomain::kUpload;
    auto upload = device.create_buffer(stage);
    if (!upload) return std::unexpected(upload.error());
    scratch.add(*upload);
    const core::Status written = device.write_buffer(*upload, 0, bytes);
    if (!written) return written;
    gpu::BufferDesc desc;
    desc.name = name;
    desc.size = bytes.size();
    desc.usage = usage;
    desc.memory = gpu::MemoryDomain::kDevice;
    auto buffer = device.create_buffer(desc);
    if (!buffer) return std::unexpected(buffer.error());
    out = *buffer;
    gpu::BufferCopy region;
    region.size = bytes.size();
    commands.copy_buffer(*upload, out, region);
    return core::ok();
}

// Một đích morph: byte của nó thành buffer riêng trên thiết bị.
[[nodiscard]] core::Status stage_morph(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    const MorphTarget& target, GpuPrimitive& out) {
    auto bytes = byte_view(target.vertices.data(), target.vertices.size(), sizeof(MorphVertex));
    if (!bytes) return std::unexpected(bytes.error());
    gpu::BufferHandle handle;
    const gpu::BufferUsage usage =
        gpu::BufferUsage::kVertex | gpu::BufferUsage::kCopyDest | gpu::BufferUsage::kCopySource;
    const core::Status staged = stage_buffer(device, commands, scratch, *bytes, usage, "morph", handle);
    if (!staged) return staged;
    out.morphs.push_back(handle);
    return core::ok();
}

[[nodiscard]] core::Status stage_morphs(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    const Primitive& source, GpuPrimitive& out) {
    const auto one = [&](const MorphTarget& target) { return stage_morph(device, commands, scratch, target, out); };
    return each_status(source.targets, one);
}

[[nodiscard]] core::Status fit_count(std::size_t count) {
    if (count > std::numeric_limits<std::uint32_t>::max()) return overflow("buffer quá lớn");
    return core::ok();
}

[[nodiscard]] core::Status stage_primitive(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    const Primitive& source, GpuPrimitive& out) {
    const core::Status vertices_fit = fit_count(source.vertices.size());
    if (!vertices_fit) return vertices_fit;
    const core::Status indices_fit = fit_count(source.indices.size());
    if (!indices_fit) return indices_fit;
    auto vertices = byte_view(source.vertices.data(), source.vertices.size(), sizeof(Vertex));
    if (!vertices) return std::unexpected(vertices.error());
    const gpu::BufferUsage vertex_usage =
        gpu::BufferUsage::kVertex | gpu::BufferUsage::kCopyDest | gpu::BufferUsage::kCopySource;
    const core::Status staged =
        stage_buffer(device, commands, scratch, *vertices, vertex_usage, "vertices", out.vertices);
    if (!staged) return staged;
    out.vertex_count = static_cast<std::uint32_t>(source.vertices.size());
    auto indices = byte_view(source.indices.data(), source.indices.size(), sizeof(std::uint32_t));
    if (!indices) return std::unexpected(indices.error());
    const gpu::BufferUsage index_usage =
        gpu::BufferUsage::kIndex | gpu::BufferUsage::kCopyDest | gpu::BufferUsage::kCopySource;
    const core::Status staged_indices =
        stage_buffer(device, commands, scratch, *indices, index_usage, "indices", out.indices);
    if (!staged_indices) return staged_indices;
    out.index_count = static_cast<std::uint32_t>(source.indices.size());
    return stage_morphs(device, commands, scratch, source, out);
}

// Một hình nguyên thuỷ: đỉnh, chỉ số và các đích morph của nó.
[[nodiscard]] core::Status stage_one_primitive(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    const Primitive& source, GpuMesh& out) {
    out.primitives.emplace_back();
    return stage_primitive(device, commands, scratch, source, out.primitives.back());
}

[[nodiscard]] core::Status stage_mesh(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    const Mesh& source, GpuMesh& out) {
    const auto one = [&](const Primitive& primitive) {
        return stage_one_primitive(device, commands, scratch, primitive, out);
    };
    return each_status(source.primitives, one);
}

// Một mắt lưới của model vào đúng ô của nó trong owned.
[[nodiscard]] core::Status stage_one_mesh(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    const Model& model, Owned& owned, std::size_t index) {
    return stage_mesh(device, commands, scratch, model.meshes.at(index), owned.meshes.at(index));
}

[[nodiscard]] core::Status stage_meshes(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch,
    const Model& model, Owned& owned) {
    owned.meshes.resize(model.meshes.size());
    const auto one = [&](std::size_t index) { return stage_one_mesh(device, commands, scratch, model, owned, index); };
    return each_status(std::views::iota(std::size_t{0}, model.meshes.size()), one);
}

[[nodiscard]] gpu::TextureBarrier copy_dest(gpu::TextureHandle texture) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = gpu::SyncStage::kAll;
    barrier.stage_after = gpu::SyncStage::kCopy;
    barrier.access_before = gpu::Access::kNone;
    barrier.access_after = gpu::Access::kCopyWrite;
    barrier.layout_before = gpu::TextureLayout::kUndefined;
    barrier.layout_after = gpu::TextureLayout::kCopyDest;
    return barrier;
}

[[nodiscard]] gpu::TextureBarrier shader_read(gpu::TextureHandle texture) noexcept {
    gpu::TextureBarrier barrier;
    barrier.texture = texture;
    barrier.stage_before = gpu::SyncStage::kCopy;
    barrier.stage_after = gpu::SyncStage::kAll;
    barrier.access_before = gpu::Access::kCopyWrite;
    barrier.access_after = gpu::Access::kShaderRead;
    barrier.layout_before = gpu::TextureLayout::kCopyDest;
    barrier.layout_after = gpu::TextureLayout::kShaderRead;
    return barrier;
}

void issue(gpu::CommandList& commands, std::span<const gpu::BufferBarrier> buffers,
    std::span<const gpu::TextureBarrier> textures) {
    if (buffers.empty() && textures.empty()) return;
    const std::span<const gpu::GlobalBarrier> none;
    commands.barrier(buffers, textures, none);
}

void add_regions(ImageCopy& copy, const StagedImage& staged) {
    for (std::uint32_t index = 0; index < staged.mips.size(); ++index) {
        const StagedMip& mip = staged.mips[index];
        gpu::BufferTextureCopy region;
        region.buffer_offset = mip.offset;
        region.mip = index;
        copy.regions.push_back(region);
    }
}

[[nodiscard]] core::Status prepare_image(gpu::Device& device, Scratch& scratch, const Model& model, std::uint32_t index,
    Owned& owned, std::vector<ImageCopy>& copies) {
    const Image& source = model.images[index];
    const gpu::Format format = image_format(model, index);
    const ColorSpace space = space_of(format);
    const core::Result<const StagedImage*> chain = scratch.chain(source, space, index);
    if (!chain) return std::unexpected(chain.error());
    const StagedImage* const staged = *chain;
    gpu::BufferDesc upload;
    upload.name = "image";
    upload.size = staged->bytes.size();
    upload.usage = gpu::BufferUsage::kCopySource;
    upload.memory = gpu::MemoryDomain::kUpload;
    auto buffer = device.create_buffer(upload);
    if (!buffer) return std::unexpected(buffer.error());
    scratch.add(*buffer);
    const core::Status written = device.write_buffer(*buffer, 0, staged->bytes);
    if (!written) return written;
    gpu::TextureDesc desc;
    desc.name = source.name;
    desc.format = format;
    desc.width = source.width;
    desc.height = source.height;
    desc.mip_levels = static_cast<std::uint32_t>(staged->mips.size());
    desc.usage = gpu::TextureUsage::kSampled | gpu::TextureUsage::kCopyDest | gpu::TextureUsage::kCopySource;
    auto texture = device.create_texture(desc);
    if (!texture) return std::unexpected(texture.error());
    GpuImage image;
    image.texture = *texture;
    image.format = desc.format;
    image.width = source.width;
    image.height = source.height;
    image.mips = desc.mip_levels;
    gpu::TextureViewDesc view;
    view.name = source.name;
    view.texture = image.texture;
    view.kind = gpu::TextureKind::kTex2D;
    auto created = device.create_view(view);
    if (!created) {
        owned.images.push_back(image);
        return std::unexpected(created.error());
    }
    image.view = *created;
    owned.images.push_back(image);
    ImageCopy copy;
    copy.source = *buffer;
    copy.target = image.texture;
    add_regions(copy, *staged);
    copies.push_back(std::move(copy));
    return core::ok();
}

[[nodiscard]] core::Status prepare_images(gpu::Device& device, Scratch& scratch, const Model& model, Owned& owned,
    std::vector<ImageCopy>& copies) {
    const auto one = [&](std::uint32_t index) { return prepare_image(device, scratch, model, index, owned, copies); };
    return each_status(std::views::iota(std::uint32_t{0}, model.images.size()), one);
}

void record_image_copy(gpu::CommandList& commands, const ImageCopy& copy) {
    commands.copy_buffer_to_texture(copy.source, copy.target, copy.regions);
}

void record_image_copies(gpu::CommandList& commands, std::span<const ImageCopy> copies) {
    for (const ImageCopy& copy : copies) {
        record_image_copy(commands, copy);
    }
}

void add_buffer_barrier(std::vector<gpu::BufferBarrier>& out, gpu::BufferHandle handle, gpu::Access after) {
    if (!handle) return;
    gpu::BufferBarrier barrier;
    barrier.buffer = handle;
    barrier.stage_before = gpu::SyncStage::kCopy;
    barrier.stage_after = gpu::SyncStage::kAll;
    barrier.access_before = gpu::Access::kCopyWrite;
    barrier.access_after = after;
    out.push_back(barrier);
}

void add_primitive_barriers(std::vector<gpu::BufferBarrier>& out, const GpuPrimitive& primitive) {
    add_buffer_barrier(out, primitive.vertices, gpu::Access::kVertexRead);
    add_buffer_barrier(out, primitive.indices, gpu::Access::kIndexRead);
    for (const gpu::BufferHandle handle : primitive.morphs) {
        add_buffer_barrier(out, handle, gpu::Access::kVertexRead);
    }
}

void add_mesh_barriers(std::vector<gpu::BufferBarrier>& out, const GpuMesh& mesh) {
    for (const GpuPrimitive& primitive : mesh.primitives) {
        add_primitive_barriers(out, primitive);
    }
}

void collect_buffer_barriers(const Owned& owned, std::vector<gpu::BufferBarrier>& out) {
    for (const GpuMesh& mesh : owned.meshes) {
        add_mesh_barriers(out, mesh);
    }
}

void collect_shader_barriers(const Owned& owned, std::vector<gpu::TextureBarrier>& out) {
    for (const GpuImage& image : owned.images) {
        out.push_back(shader_read(image.texture));
    }
}

void collect_copy_barriers(std::span<const ImageCopy> copies, std::vector<gpu::TextureBarrier>& out) {
    for (const ImageCopy& copy : copies) {
        out.push_back(copy_dest(copy.target));
    }
}

[[nodiscard]] bool has_work(const Model& model) noexcept {
    if (!model.images.empty()) return true;
    const auto has_primitive = [](const Mesh& mesh) { return !mesh.primitives.empty(); };
    return std::ranges::any_of(model.meshes, has_primitive);
}

[[nodiscard]] gpu::Filter to_gpu(Filter filter) noexcept {
    if (filter == Filter::kNearest) return gpu::Filter::kNearest;
    return gpu::Filter::kLinear;
}

// Mức lọc bất đẳng hướng của sampler model (16 là trần của mọi backend).
constexpr std::uint32_t kModelAnisotropy = 16;

[[nodiscard]] gpu::AddressMode to_address(Wrap wrap) noexcept {
    switch (wrap) {
    case Wrap::kRepeat: return gpu::AddressMode::kRepeat;
    case Wrap::kMirror: return gpu::AddressMode::kMirrorRepeat;
    case Wrap::kClamp: return gpu::AddressMode::kClampToEdge;
    }
    return gpu::AddressMode::kRepeat;
}

[[nodiscard]] core::Result<gpu::SamplerHandle> make_sampler(gpu::Device& device, const Sampler& source,
    std::string_view name) {
    gpu::SamplerDesc desc;
    desc.name = name.empty() ? std::string_view("sampler") : name;
    desc.mag_filter = to_gpu(source.mag);
    desc.min_filter = to_gpu(source.min);
    desc.mip_filter = to_gpu(source.mip);
    desc.address_u = to_address(source.wrap_u);
    desc.address_v = to_address(source.wrap_v);
    desc.address_w = desc.address_v;
    desc.max_lod = source.has_mip ? 1000.0F : 0.0F;
    // Lọc bất đẳng hướng: mặt đất và tường nhìn xiên (camera game nghiêng) không nhoè đi như lọc tam tuyến thường. Thiết bị
    // kẹp theo DeviceCaps::max_anisotropy; điểm gần nhất thì không áp dụng.
    const bool is_smooth = source.min == Filter::kLinear && source.mag == Filter::kLinear && source.has_mip;
    desc.max_anisotropy = is_smooth ? kModelAnisotropy : 1U;
    return device.create_sampler(desc);
}

// Một sampler của model vào đúng ô của nó trong owned.
[[nodiscard]] core::Status prepare_one_sampler(gpu::Device& device, const Model& model, Owned& owned,
    std::size_t index) {
    const Sampler& source = model.samplers.at(index);
    const std::string_view given = source.name;
    const std::string_view name = given.empty() ? std::string_view("sampler") : given;
    auto made = make_sampler(device, source, name);
    if (!made) return std::unexpected(made.error());
    owned.samplers.at(index) = *made;
    return core::ok();
}

[[nodiscard]] core::Status prepare_samplers(gpu::Device& device, const Model& model, Owned& owned) {
    if (model.images.empty()) return core::ok();
    auto fallback = make_sampler(device, Sampler{}, "default");
    if (!fallback) return std::unexpected(fallback.error());
    owned.fallback = *fallback;
    owned.samplers.resize(model.samplers.size());
    const auto one = [&](std::size_t index) { return prepare_one_sampler(device, model, owned, index); };
    return each_status(std::views::iota(std::size_t{0}, model.samplers.size()), one);
}

[[nodiscard]] core::Status fill(gpu::Device& device, gpu::CommandList& commands, Scratch& scratch, const Model& model,
    Owned& owned) {
    const core::Status meshes = stage_meshes(device, commands, scratch, model, owned);
    if (!meshes) return meshes;
    std::vector<ImageCopy> copies;
    const core::Status images = prepare_images(device, scratch, model, owned, copies);
    if (!images) return images;
    const core::Status samplers = prepare_samplers(device, model, owned);
    if (!samplers) return samplers;
    std::vector<gpu::TextureBarrier> to_copy;
    collect_copy_barriers(copies, to_copy);
    issue(commands, {}, to_copy);
    record_image_copies(commands, copies);
    std::vector<gpu::BufferBarrier> buffers;
    std::vector<gpu::TextureBarrier> to_sample;
    collect_buffer_barriers(owned, buffers);
    collect_shader_barriers(owned, to_sample);
    issue(commands, buffers, to_sample);
    return core::ok();
}

// Nộp hỏng: phải đóng khung trước khi trả, lỗi của end_frame thắng lỗi nộp.
[[nodiscard]] core::Status end_frame_after(gpu::Device& device, const core::Status& failure) {
    const core::Status ended = device.end_frame();
    if (!ended) return ended;
    return failure;
}

[[nodiscard]] core::Status submit(gpu::Device& device, gpu::CommandList* commands, bool wait) {
    gpu::CommandList* lists[] = {commands};
    gpu::SubmitDesc desc;
    desc.lists = lists;
    const core::Status sent = device.submit(gpu::QueueType::kGraphics, desc);
    if (!sent) return end_frame_after(device, sent);
    if (!wait) return core::ok();
    return device.wait_idle();
}

[[nodiscard]] core::Status record(gpu::Device& device, const Model& model, Scratch& scratch, Owned& owned, bool wait) {
    auto commands = device.begin_commands(gpu::QueueType::kGraphics);
    if (!commands) return std::unexpected(commands.error());
    const core::Status filled = fill(device, **commands, scratch, model, owned);
    if (!filled) return end_frame_after(device, filled);
    return submit(device, *commands, wait);
}

[[nodiscard]] bool is_blocked(const Image& image) noexcept {
    return image.blocks != gpu::Format::kUnknown;
}

[[nodiscard]] core::Status check_level(const Image& image, std::uint32_t level) {
    const std::uint32_t width = gpu::mip_size(image.width, level);
    const std::uint32_t height = gpu::mip_size(image.height, level);
    const std::uint64_t rows = gpu::row_count(image.blocks, height);
    const std::uint64_t row = gpu::row_bytes(image.blocks, width);
    if (row != 0 && rows > std::numeric_limits<std::uint64_t>::max() / row) return overflow("mip quá lớn");
    const bool matches = image.levels[level].size() == rows * row;
    if (!matches) return core::fail(core::ErrorCode::kCorrupt, "mip lệch số byte");
    return core::ok();
}

[[nodiscard]] core::Status check_blocks(const Image& image) {
    if (image.width == 0 || image.height == 0) return core::fail(core::ErrorCode::kInvalidArgument, "ảnh rỗng");
    if (image.levels.empty()) return core::fail(core::ErrorCode::kCorrupt, "ảnh nén không có mip");
    const std::uint32_t limit = gpu::full_mip_count(image.width, image.height);
    if (image.levels.size() > limit) return core::fail(core::ErrorCode::kCorrupt, "quá nhiều mip");
    for (std::uint32_t level = 0; level < image.levels.size(); ++level) {
        const core::Status checked = check_level(image, level);
        if (!checked) return checked;
    }
    return core::ok();
}

[[nodiscard]] core::Status check_image(const Image& image) {
    if (is_blocked(image)) return check_blocks(image);
    if (image.width == 0 || image.height == 0) {
        return core::fail(core::ErrorCode::kInvalidArgument, "ảnh rỗng");
    }
    if (image.width > std::numeric_limits<std::uint64_t>::max() / image.height) {
        return overflow("ảnh quá lớn");
    }
    const std::uint64_t pixels = std::uint64_t{image.width} * image.height;
    if (pixels > std::numeric_limits<std::uint64_t>::max() / 4) return overflow("ảnh quá lớn");
    const bool matches = image.rgba.size() == pixels * 4;
    if (!matches) return core::fail(core::ErrorCode::kCorrupt, "ảnh lệch số byte");
    return core::ok();
}

[[nodiscard]] std::uint64_t align_offset(std::uint64_t value) noexcept {
    constexpr std::uint64_t step = gpu::kTextureOffsetAlignment;
    return (value + step - 1) / step * step;
}

void write_blocked_row(std::byte* dest, std::span<const std::byte> source, std::uint64_t pitch, bool pad) {
    std::memcpy(dest, source.data(), source.size());
    if (!pad) return;
    std::memset(dest + source.size(), 0, static_cast<std::size_t>(pitch - source.size()));
}

[[nodiscard]] core::Status append_blocked(StagedImage& staged, gpu::Format format, std::uint32_t width,
    std::uint32_t height, std::span<const std::byte> tight) {
    const std::uint64_t bytes = gpu::staged_bytes(format, width, height);
    const std::uint64_t offset = align_offset(staged.bytes.size());
    if (offset > std::numeric_limits<std::size_t>::max() - bytes) return overflow("chuỗi mip quá lớn");
    staged.bytes.resize(static_cast<std::size_t>(offset + bytes));
    const std::uint64_t row = gpu::row_bytes(format, width);
    const std::uint64_t pitch = gpu::padded_row_bytes(format, width);
    const std::uint32_t rows = gpu::row_count(format, height);
    for (std::uint32_t index = 0; index < rows; ++index) {
        const bool last = index + 1 == rows;
        const std::uint64_t cursor = pitch * index;
        const std::span<const std::byte> source = tight.subspan(static_cast<std::size_t>(row * index),
            static_cast<std::size_t>(row));
        write_blocked_row(staged.bytes.data() + offset + cursor, source, pitch, !last);
    }
    StagedMip mip;
    mip.offset = offset;
    mip.width = width;
    mip.height = height;
    staged.mips.push_back(mip);
    return core::ok();
}

[[nodiscard]] core::Result<StagedImage> stage_blocks(const Image& image) {
    const core::Status checked = check_blocks(image);
    if (!checked) return std::unexpected(checked.error());
    StagedImage staged;
    for (std::uint32_t level = 0; level < image.levels.size(); ++level) {
        const std::uint32_t width = gpu::mip_size(image.width, level);
        const std::uint32_t height = gpu::mip_size(image.height, level);
        const std::span<const std::byte> tight = image.levels[level];
        const core::Status appended = append_blocked(staged, image.blocks, width, height, tight);
        if (!appended) return std::unexpected(appended.error());
    }
    return staged;
}

// Một mức nguồn để hạ nửa. Mức 0 trỏ thẳng vào ảnh đã giải mã, mức sau trỏ vào đệm của mức trước,
// nên không có bản sao nào của ảnh gốc trên đường nạp.
struct Source {
    const std::uint8_t* pixels = nullptr;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

// Mức 0 của một ảnh đã qua check_image.
[[nodiscard]] Source whole_image(const Image& image) noexcept {
    return {.pixels = image.rgba.data(), .width = image.width, .height = image.height};
}

// Cỡ lớn nhất một vùng nhớ của tiến trình, để so với số byte tính bằng 64 bit.
constexpr std::uint64_t kSizeLimit = std::numeric_limits<std::size_t>::max();

[[nodiscard]] core::Result<std::vector<std::byte>> pack_level(const Source& level) {
    const std::uint64_t tight = gpu::row_bytes(gpu::Format::kRgba8Unorm, level.width);
    const std::uint64_t pitch = gpu::padded_row_bytes(gpu::Format::kRgba8Unorm, level.width);
    const std::uint64_t bytes = gpu::staged_bytes(gpu::Format::kRgba8Unorm, level.width, level.height);
    const bool fits = bytes <= kSizeLimit && pitch <= kSizeLimit;
    if (!fits) return overflow("ảnh quá lớn");
    const auto row_size = static_cast<std::size_t>(tight);
    const auto row_step = static_cast<std::size_t>(pitch);
    std::vector<std::byte> out(static_cast<std::size_t>(bytes));
    const auto* pixels = reinterpret_cast<const std::byte*>(level.pixels);
    if (pitch == tight) {
        // Bề rộng chia hết cho căn lề dòng: cả mức là một khối liền, khỏi chép từng hàng.
        std::memcpy(out.data(), pixels, row_size * level.height);
        return out;
    }
    for (std::uint32_t row = 0; row < level.height; ++row) {
        std::memcpy(out.data() + (row * row_step), pixels + (row * row_size), row_size);
    }
    return out;
}

// Nướng mip là phần đắt nhất của việc nạp cảnh: ảnh 2048x2048 có hơn bốn triệu texel nguồn ở mức
// 0, mỗi texel đích phải giải mã bốn texel nguồn. pow() từng texel ở đó tốn hàng chục mili giây
// cho một ảnh, nên hai chiều của đường cong sRGB đi qua bảng tra dựng một lần.
constexpr std::size_t kEncodeSteps = 16384;

[[nodiscard]] float srgb_to_linear_exact(std::uint8_t encoded) noexcept {
    const float s = static_cast<float>(encoded) / 255.0F;
    if (s <= 0.04045F) return s / 12.92F;
    return std::pow((s + 0.055F) / 1.055F, 2.4F);
}

[[nodiscard]] std::uint8_t linear_to_srgb_exact(float linear) noexcept {
    const float clamped = std::clamp(linear, 0.0F, 1.0F);
    const float curved = std::pow(clamped, 1.0F / 2.4F);
    float encoded = 12.92F * clamped;
    if (clamped > 0.0031308F) encoded = 1.055F * curved - 0.055F;
    const long rounded = std::lround(encoded * 255.0F);
    return static_cast<std::uint8_t>(std::clamp(rounded, 0L, 255L));
}

// Bảng tra hai chiều: 256 giá trị sRGB 8 bit sang tuyến tính, và 16384 mức tuyến tính sang sRGB.
// Bước mã hoá 1/16383; đạo hàm của đường cong ở 0 là 12,92 nên sai lệch nhiều nhất 0,2/255 — dưới
// một nửa mức của một kênh 8 bit, không nhìn ra được, mà rẻ hơn pow() cả chục lần.
struct SrgbTable {
    std::array<float, 256> decode{};
    std::array<std::uint8_t, kEncodeSteps> encode{};
};

[[nodiscard]] SrgbTable build_srgb_table() {
    SrgbTable made;
    for (std::size_t index = 0; index < made.decode.size(); ++index) {
        made.decode.at(index) = srgb_to_linear_exact(static_cast<std::uint8_t>(index));
    }
    for (std::size_t index = 0; index < made.encode.size(); ++index) {
        const float linear = static_cast<float>(index) / static_cast<float>(kEncodeSteps - 1);
        made.encode.at(index) = linear_to_srgb_exact(linear);
    }
    return made;
}

// Bảng dựng một lần, ở luồng nào gọi trước; magic static của C++ lo phần khoá.
[[nodiscard]] const SrgbTable& srgb_table() {
    static const SrgbTable table = build_srgb_table();
    return table;
}

[[nodiscard]] std::uint8_t encode_srgb(float linear) noexcept {
    const float clamped = std::clamp(linear, 0.0F, 1.0F);
    const auto last = static_cast<float>(kEncodeSteps - 1);
    return srgb_table().encode.at(static_cast<std::size_t>(clamped * last + 0.5F));
}

struct Level {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::vector<std::uint8_t> rgba;
};

// Cả một mức đã hạ, làm nguồn cho mức kế.
[[nodiscard]] Source view_of(const Level& level) noexcept {
    return {.pixels = level.rgba.data(), .width = level.width, .height = level.height};
}

using Texel = std::span<const std::uint8_t, 4>;
using Pixels = std::span<const std::uint8_t>;

struct Window {
    std::uint32_t x0 = 0;
    std::uint32_t x1 = 0;
    std::uint32_t y0 = 0;
    std::uint32_t y1 = 0;
};

// Tổng của cửa sổ nguồn cho một texel đích. Tuyến tính cộng thẳng giá trị 8 bit (float giữ đúng
// tới 1020); sRGB cộng giá trị đã giải mã vì trung bình phải làm trong ánh sáng tuyến tính.
struct ChannelSum {
    float red = 0.0F;
    float green = 0.0F;
    float blue = 0.0F;
    float alpha = 0.0F;
    std::uint32_t count = 0;
};

template <bool AsSrgb>
void add_pixel(Texel pixel, ChannelSum& sum) noexcept {
    if constexpr (AsSrgb) {
        const SrgbTable& table = srgb_table();
        sum.red += table.decode.at(pixel[0]);
        sum.green += table.decode.at(pixel[1]);
        sum.blue += table.decode.at(pixel[2]);
    } else {
        sum.red += static_cast<float>(pixel[0]);
        sum.green += static_cast<float>(pixel[1]);
        sum.blue += static_cast<float>(pixel[2]);
    }
    sum.alpha += static_cast<float>(pixel[3]);
    ++sum.count;
}

// Cộng mọi điểm ảnh của một đoạn liền trong một hàng nguồn; đoạn dài bội của 4 byte. Điều kiện
// vòng lặp bảo đảm còn đủ một điểm ảnh trước mỗi lần cắt.
template <bool AsSrgb>
void add_run(Pixels run, ChannelSum& sum) noexcept {
    for (; run.size() >= 4; run = run.subspan(4)) {
        add_pixel<AsSrgb>(run.first<4>(), sum);
    }
}

template <bool AsSrgb>
void add_window(const Source& source, Window window, ChannelSum& sum) noexcept {
    const std::size_t stride = std::size_t{source.width} * 4;
    const std::size_t first = std::size_t{window.x0} * 4;
    const std::size_t length = std::size_t{window.x1 - window.x0} * 4;
    for (std::uint32_t row = window.y0; row < window.y1; ++row) {
        const auto* start = source.pixels + (static_cast<std::size_t>(row) * stride) + first;
        const Pixels run(start, length);
        add_run<AsSrgb>(run, sum);
    }
}

// Trung bình count texel rồi mã hoá lại theo hệ màu của mức. Cửa sổ 2x2 cho count 1, 2 hoặc 4 và
// phép chia chính xác; cạnh lẻ có cửa sổ ba texel, count thành 3, 6 hoặc 9. Kênh alpha luôn mã hoá
// thẳng, không qua đường cong. Hai nhánh viết thành if và else: câu return đứng sau một if constexpr
// không có else vẫn được dịch ở bản sRGB, và MSVC bản debug báo C4702 (mã không tới được).
template <bool AsSrgb>
[[nodiscard]] std::uint8_t encode_channel(float sum, std::uint32_t count) noexcept {
    const float mean = sum / static_cast<float>(count);
    if constexpr (AsSrgb) {
        return encode_srgb(mean);
    } else {
        const long rounded = std::lround(mean);
        return static_cast<std::uint8_t>(std::clamp(rounded, 0L, 255L));
    }
}

// Một mức đích đang ghi và mức nguồn của nó, gom lại để chữ ký hàm không quá năm tham số.
struct MipJob {
    Source source{};
    std::uint32_t dest_width = 0;
    std::uint32_t dest_height = 0;
    std::uint8_t* dest = nullptr;
};

template <bool AsSrgb>
void write_texel(const MipJob& job, std::uint32_t dest_x, std::uint32_t dest_y) noexcept {
    // Texel đích cuối của chiều lẻ nuốt nốt texel biên: cửa sổ 2x2 bỏ cạnh đó.
    const bool is_last_column = dest_x + 1 == job.dest_width;
    const bool is_last_row = dest_y + 1 == job.dest_height;
    Window window;
    window.x0 = dest_x * 2;
    window.y0 = dest_y * 2;
    window.x1 = is_last_column ? job.source.width : window.x0 + 2;
    window.y1 = is_last_row ? job.source.height : window.y0 + 2;
    ChannelSum sum;
    add_window<AsSrgb>(job.source, window, sum);
    if (sum.count == 0) return;
    std::uint8_t* texel = job.dest + (static_cast<std::size_t>(dest_y) * job.dest_width + dest_x) * 4;
    texel[0] = encode_channel<AsSrgb>(sum.red, sum.count);
    texel[1] = encode_channel<AsSrgb>(sum.green, sum.count);
    texel[2] = encode_channel<AsSrgb>(sum.blue, sum.count);
    texel[3] = encode_channel<false>(sum.alpha, sum.count);
}

template <bool AsSrgb>
void filter_row(const MipJob& job, std::uint32_t y) noexcept {
    for (std::uint32_t x = 0; x < job.dest_width; ++x) {
        write_texel<AsSrgb>(job, x, y);
    }
}

template <bool AsSrgb>
void build_level(const MipJob& job) noexcept {
    for (std::uint32_t y = 0; y < job.dest_height; ++y) {
        filter_row<AsSrgb>(job, y);
    }
}

// Hạ mức một nửa; đệm của mức đích được giữ lại giữa các vòng nên chỉ cấp phát một lần.
void downsample_into(Source source, Level& dest, bool as_srgb) noexcept {
    dest.width = std::max(source.width / 2, 1U);
    dest.height = std::max(source.height / 2, 1U);
    dest.rgba.resize(static_cast<std::size_t>(dest.width) * dest.height * 4);
    MipJob job;
    job.source = source;
    job.dest_width = dest.width;
    job.dest_height = dest.height;
    job.dest = dest.rgba.data();
    if (as_srgb) {
        build_level<true>(job);
        return;
    }
    build_level<false>(job);
}

[[nodiscard]] core::Status append_level(StagedImage& staged, const Source& level) {
    auto packed = pack_level(level);
    if (!packed) return std::unexpected(packed.error());
    const std::uint64_t offset = align_offset(staged.bytes.size());
    if (offset > kSizeLimit) return overflow("ảnh quá lớn");
    staged.bytes.resize(static_cast<std::size_t>(offset));
    staged.bytes.insert(staged.bytes.end(), packed->begin(), packed->end());
    StagedMip mip;
    mip.offset = offset;
    mip.width = level.width;
    mip.height = level.height;
    staged.mips.push_back(mip);
    return core::ok();
}

// Một mức kế của chuỗi: hạ nửa mức current, đóng gói, rồi để mức vừa sinh vào front và current.
[[nodiscard]] core::Status append_next(StagedImage& staged, Source& current, Level& front, Level& back, bool as_srgb) {
    downsample_into(current, back, as_srgb);
    const Source smaller{back.rgba.data(), back.width, back.height};
    const core::Status appended = append_level(staged, smaller);
    if (!appended) return appended;
    std::swap(front, back);
    current = Source{front.rgba.data(), front.width, front.height};
    return core::ok();
}

// Chuỗi mip của ảnh index vào cuối baked, trong không gian màu mà lần tải dùng cho ảnh đó.
[[nodiscard]] core::Status bake_image(const Model& model, std::uint32_t index, std::vector<StagedImage>& baked) {
    const gpu::Format format = image_format(model, index);
    const ColorSpace space = space_of(format);
    auto staged = stage_image(model.images[index], space);
    if (!staged) return std::unexpected(staged.error());
    baked.push_back(std::move(*staged));
    return core::ok();
}

} // namespace

core::Result<std::vector<std::byte>> stage_rgba(const Image& image) {
    const core::Status checked = check_image(image);
    if (!checked) return std::unexpected(checked.error());
    const Source whole = whole_image(image);
    return pack_level(whole);
}

core::Result<StagedImage> stage_image(const Image& image, ColorSpace space) {
    if (is_blocked(image)) return stage_blocks(image);
    const core::Status checked = check_image(image);
    if (!checked) return std::unexpected(checked.error());
    const bool as_srgb = space == ColorSpace::kSrgb;
    StagedImage staged;
    Source current = whole_image(image);
    const core::Status first = append_level(staged, current);
    if (!first) return std::unexpected(first.error());
    Level front;
    Level back;
    bool running = current.width > 1 || current.height > 1;
    core::Status status = core::ok();
    while (running) {
        status = append_next(staged, current, front, back, as_srgb);
        running = status.has_value() && (current.width > 1 || current.height > 1);
    }
    if (!status) return std::unexpected(status.error());
    return staged;
}

[[nodiscard]] gpu::Format color_view(gpu::Format format) noexcept {
    if (format == gpu::Format::kBc1Unorm) return gpu::Format::kBc1UnormSrgb;
    if (format == gpu::Format::kBc2Unorm) return gpu::Format::kBc2UnormSrgb;
    if (format == gpu::Format::kBc3Unorm) return gpu::Format::kBc3UnormSrgb;
    if (format == gpu::Format::kBc7Unorm) return gpu::Format::kBc7UnormSrgb;
    if (format == gpu::Format::kAstc4x4Unorm) return gpu::Format::kAstc4x4UnormSrgb;
    if (format == gpu::Format::kEtc2Rgb8Unorm) return gpu::Format::kEtc2Rgb8UnormSrgb;
    if (format == gpu::Format::kEtc2Rgba8Unorm) return gpu::Format::kEtc2Rgba8UnormSrgb;
    return format;
}

gpu::Format image_format(const Model& model, std::uint32_t index) noexcept {
    const gpu::Format blocks = model.images[index].blocks;
    if (blocks != gpu::Format::kUnknown && is_color_only(model, index)) return color_view(blocks);
    if (blocks != gpu::Format::kUnknown) return blocks;
    if (is_color_only(model, index)) return gpu::Format::kRgba8UnormSrgb;
    return gpu::Format::kRgba8Unorm;
}

core::Result<std::vector<StagedImage>> stage_images(const Model& model) {
    std::vector<StagedImage> baked;
    baked.reserve(model.images.size());
    for (std::uint32_t index = 0; index < model.images.size(); ++index) {
        const bool is_srgb = image_format(model, index) == gpu::Format::kRgba8UnormSrgb;
        auto staged = stage_image(model.images[index], is_srgb ? ColorSpace::kSrgb : ColorSpace::kLinear);
        if (!staged) return std::unexpected(staged.error());
        baked.push_back(std::move(*staged));
    }
    return baked;
}

Uploaded::~Uploaded() {
    release();
}

Uploaded::Uploaded(Uploaded&& other) noexcept
    : device_(std::exchange(other.device_, nullptr)),
      meshes_(std::move(other.meshes_)),
      images_(std::move(other.images_)),
      samplers_(std::move(other.samplers_)),
      fallback_(std::exchange(other.fallback_, {})) {}

Uploaded& Uploaded::operator=(Uploaded&& other) noexcept {
    if (this == &other) return *this;
    release();
    device_ = std::exchange(other.device_, nullptr);
    meshes_ = std::move(other.meshes_);
    images_ = std::move(other.images_);
    samplers_ = std::move(other.samplers_);
    fallback_ = std::exchange(other.fallback_, {});
    return *this;
}

void Uploaded::adopt(gpu::Device& device, std::vector<GpuMesh> meshes, std::vector<GpuImage> images,
    std::vector<gpu::SamplerHandle> samplers, gpu::SamplerHandle fallback) noexcept {
    device_ = &device;
    meshes_ = std::move(meshes);
    images_ = std::move(images);
    samplers_ = std::move(samplers);
    fallback_ = fallback;
}

void Uploaded::release() noexcept {
    if (device_ == nullptr) return;
    release_meshes(*device_, meshes_);
    release_images(*device_, images_);
    release_samplers(*device_, samplers_, fallback_);
    device_ = nullptr;
}

// baked rỗng thì chuỗi mip nướng tại chỗ; có thì phải đủ một chuỗi cho mỗi ảnh của model.
core::Result<Uploaded> place(gpu::Device& device, const Model& model, bool wait, Baked baked) {
    if (device.loss() != gpu::DeviceLoss::kNone) {
        return core::fail(core::ErrorCode::kDeviceLost, "thiết bị đã mất");
    }
    const bool is_matched = baked.empty() || baked.size() == model.images.size();
    if (!is_matched) return core::fail(core::ErrorCode::kInvalidArgument, "số chuỗi mip nướng sẵn khác số ảnh");
    if (!has_work(model)) return Uploaded{};
    Scratch scratch(device, baked);
    Owned owned;
    const core::Status status = record(device, model, scratch, owned, wait);
    if (!status) {
        release_meshes(device, owned.meshes);
        release_images(device, owned.images);
        release_samplers(device, owned.samplers, owned.fallback);
        return std::unexpected(status.error());
    }
    Uploaded loaded;
    loaded.adopt(device, std::move(owned.meshes), std::move(owned.images), std::move(owned.samplers), owned.fallback);
    owned.fallback = {};
    return loaded;
}

core::Result<Uploaded> upload(gpu::Device& device, const Model& model) {
    return place(device, model, true, {});
}

core::Result<Uploaded> upload_queued(gpu::Device& device, const Model& model) {
    return place(device, model, false, {});
}

core::Result<Uploaded> upload_queued(gpu::Device& device, const Model& model, Baked baked) {
    return place(device, model, false, baked);
}

} // namespace game::resource

