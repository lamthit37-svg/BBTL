// Tải Model lên GPU. Buffer đỉnh, chỉ số và độ lệch morph nằm ở bộ nhớ thiết bị. Ảnh RGBA8 thành
// texture đủ mức mip, sampler glTF thành sampler của thiết bị. Trung chuyển qua write_buffer và
// copy_buffer_to_texture. upload chờ GPU xong vì đây là lúc nạp, không phải đường vẽ mỗi khung.
// Nướng chuỗi mip là phần đắt nhất và thuần CPU: stage_images làm việc đó ở luồng nạp, upload_queued
// nhận kết quả để luồng gọi (luồng vẽ) chỉ còn chép byte lên GPU.
// Nguồn: Forge2 src/resource/upload.hpp@d7fcd76. Khác gốc: bỏ {} thừa của các thành viên vector;
// include theo misc-include-cleaner (core/error.hpp, gpu/format.hpp, resource/image.hpp thay cho
// gpu/resource.hpp).
#pragma once

#include "core/error.hpp"
#include "gpu/format.hpp"
#include "gpu/handle.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

namespace game::gpu {
class Device;
}

namespace game::resource {

// Không gian khi hạ mip. Srgb thì trung bình trong ánh sáng tuyến tính rồi mã hoá lại, nếu không
// mức nhỏ sẽ tối hơn ảnh gốc.
enum class ColorSpace : std::uint8_t { kLinear, kSrgb };

struct StagedMip {
    std::uint64_t offset = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

// Mọi mức mip, mỗi mức theo bước dòng đã đệm, offset căn kTextureOffsetAlignment.
struct StagedImage {
    std::vector<std::byte> bytes;
    std::vector<StagedMip> mips;
};

// Byte RGBA8 của mức 0 theo bước dòng đã đệm. Dòng cuối không đệm, khớp staged_bytes.
[[nodiscard]] core::Result<std::vector<std::byte>> stage_rgba(const Image& image);

[[nodiscard]] core::Result<StagedImage> stage_image(const Image& image, ColorSpace space);

// Chuỗi mip của mọi ảnh của model theo chỉ số ảnh, mỗi ảnh trong đúng không gian màu mà upload sẽ
// dùng cho nó (image_format). Thuần CPU, không đụng thiết bị: gọi ở luồng nạp rồi đưa kết quả cho
// upload_queued, để luồng vẽ chỉ còn chép lên GPU.
[[nodiscard]] core::Result<std::vector<StagedImage>> stage_images(const Model& model);

// Chuỗi mip nướng sẵn của các ảnh của một model, theo chỉ số ảnh (kết quả của stage_images).
using Baked = std::span<const StagedImage>;

// sRGB khi ảnh chỉ làm màu (nền, phát sáng, diffuse, gloss, sheen, specular color).
// Khe dữ liệu (kim loại, normal, che, coat...) kéo về tuyến tính, kể cả khi cùng ảnh.
[[nodiscard]] gpu::Format image_format(const Model& model, std::uint32_t index) noexcept;

struct GpuPrimitive {
    gpu::BufferHandle vertices{};
    gpu::BufferHandle indices{};
    std::uint32_t vertex_count = 0;
    std::uint32_t index_count = 0;
    // Một buffer cho mỗi morph target, phần tử là MorphVertex.
    std::vector<gpu::BufferHandle> morphs;
};

struct GpuMesh {
    std::vector<GpuPrimitive> primitives;
};

struct GpuImage {
    gpu::TextureHandle texture{};
    gpu::TextureViewHandle view{};
    gpu::Format format = gpu::Format::kRgba8Unorm;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t mips = 1;
};

// Sở hữu tay nắm tạo bởi upload. Huỷ đối tượng này trước Device: destructor gọi Device::destroy.
class Uploaded {
public:
    Uploaded() = default;
    ~Uploaded();
    Uploaded(const Uploaded&) = delete;
    Uploaded& operator=(const Uploaded&) = delete;
    Uploaded(Uploaded&&) noexcept;
    Uploaded& operator=(Uploaded&&) noexcept;

    [[nodiscard]] std::span<const GpuMesh> meshes() const noexcept { return meshes_; }
    [[nodiscard]] std::span<const GpuImage> images() const noexcept { return images_; }
    [[nodiscard]] std::span<const gpu::SamplerHandle> samplers() const noexcept { return samplers_; }
    // Dùng khi texture glTF không khai sampler. Tay nắm rỗng nếu mô hình không có ảnh.
    [[nodiscard]] gpu::SamplerHandle default_sampler() const noexcept { return fallback_; }

private:
    friend core::Result<Uploaded> place(gpu::Device& device, const Model& model, bool wait, Baked baked);
    friend core::Result<Uploaded> upload(gpu::Device& device, const Model& model);
    friend core::Result<Uploaded> upload_queued(gpu::Device& device, const Model& model);
    void adopt(gpu::Device& device, std::vector<GpuMesh> meshes, std::vector<GpuImage> images,
        std::vector<gpu::SamplerHandle> samplers, gpu::SamplerHandle fallback) noexcept;
    void release() noexcept;

    gpu::Device* device_ = nullptr;
    std::vector<GpuMesh> meshes_;
    std::vector<GpuImage> images_;
    std::vector<gpu::SamplerHandle> samplers_;
    gpu::SamplerHandle fallback_{};
};

// Chờ GPU xong rồi mới trả. Buffer sẵn sàng cho nạp đỉnh; texture ở bố cục ShaderRead.
[[nodiscard]] core::Result<Uploaded> upload(gpu::Device& device, const Model& model);

// Nộp lệnh chép rồi trả ngay. Hàng đồ hoạ chạy lệnh này trước lệnh vẽ nộp sau. Buffer trung
// chuyển bị huỷ hoãn, còn sống tới khi GPU qua lần nộp vừa chép, nên khung hình không phải
// wait_idle từng mesh.
[[nodiscard]] core::Result<Uploaded> upload_queued(gpu::Device& device, const Model& model);

// Như trên, với chuỗi mip đã nướng sẵn ở luồng nạp: baked có đúng một chuỗi cho mỗi ảnh của model,
// lệch số là lỗi kInvalidArgument. Luồng gọi không còn nướng mip.
[[nodiscard]] core::Result<Uploaded> upload_queued(gpu::Device& device, const Model& model, Baked baked);

} // namespace game::resource

