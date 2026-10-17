/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/upload.hpp
 *  PHÂN HỆ   : Resource / Upload
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tải Model lên GPU. Buffer đỉnh, chỉ số và độ lệch morph nằm ở bộ nhớ thiết
 *    bị. Ảnh RGBA8 thành texture đủ mức mip, sampler glTF thành sampler của
 *    thiết bị. Trung chuyển qua write_buffer và copy_buffer_to_texture. upload
 *    chờ GPU xong vì đây là lúc nạp, không phải đường vẽ mỗi khung.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Nướng chuỗi mip là phần đắt nhất và thuần CPU: stage_images làm việc đó ở luồng nạp, upload_queued nhận kết quả để
// luồng gọi (luồng vẽ) chỉ còn chép byte lên GPU. Nguồn: Forge2 src/resource/upload.hpp@d7fcd76. Khác gốc: bỏ {} thừa
// của các thành viên vector; include theo misc-include-cleaner (core/error.hpp, gpu/format.hpp, resource/image.hpp
// thay cho gpu/resource.hpp).

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
class CommandList;
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

// max_edge khác 0: ảnh khối nén có chuỗi mip bỏ các mức đầu tới khi cạnh dài nhất không quá max_edge (giữ ít nhất
// một mức). Texture GPU lấy cỡ của mức đầu còn lại (mips.front()). Ảnh RGBA8 và ảnh không mip không đổi.
[[nodiscard]] core::Result<StagedImage> stage_image(const Image& image, ColorSpace space, std::uint32_t max_edge = 0);

// Chuỗi mip của mọi ảnh của model theo chỉ số ảnh, mỗi ảnh trong đúng không gian màu mà upload sẽ
// dùng cho nó (image_format). Thuần CPU, không đụng thiết bị: gọi ở luồng nạp rồi đưa kết quả cho
// upload_queued, để luồng vẽ chỉ còn chép lên GPU.
// max_edge như stage_image.
[[nodiscard]] core::Result<std::vector<StagedImage>> stage_images(const Model& model, std::uint32_t max_edge = 0);

// Chuỗi mip nướng sẵn của các ảnh của một model, theo chỉ số ảnh (kết quả của stage_images).
using Baked = std::span<const StagedImage>;

// sRGB khi ảnh chỉ làm màu (nền, phát sáng, diffuse, gloss, sheen, specular color).
// Khe dữ liệu (kim loại, normal, che, coat...) kéo về tuyến tính, kể cả khi cùng ảnh.
[[nodiscard]] gpu::Format image_format(const Model& model, std::uint32_t index) noexcept;

// Một đoạn chỉ số trong buffer indices của GpuPrimitive.
struct IndexRange {
    std::uint32_t first = 0;
    std::uint32_t count = 0;
};

struct GpuPrimitive {
    gpu::BufferHandle vertices{};
    // Mức đủ chi tiết ở [0, index_count), rồi các mức thô dần của Primitive::lods nối tiếp trong cùng buffer.
    gpu::BufferHandle indices{};
    std::uint32_t vertex_count = 0;
    std::uint32_t index_count = 0;
    // Đoạn chỉ số của từng mức thô, mức 1 trước. Rỗng khi primitive không có mức nào.
    std::vector<IndexRange> lods;
    // Khối của Primitive::tiles, trỏ vào mức 0 của indices. Rỗng khi vẽ nguyên primitive.
    std::vector<Tile> tiles;
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
    friend class UploadBatch;
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
[[nodiscard]] core::Result<Uploaded> upload_queued(gpu::Device& device, const Model& model,
    Baked baked);

// Gom nhiều lần nạp liền nhau thành MỘT lần nộp. Mỗi lần nộp riêng của upload_queued chặn luồng gọi
// hàng chục ms trên GPU tile (đo 2026-10-17 trên PowerVR GE8320: 151 lần nộp của một lần nạp cảnh,
// trung vị 25 ms, tổng 3,6 s), nên nạp N mesh có ảnh tốn N lần chặn. Ở đây lệnh chép ảnh của mọi
// mesh ghi vào một danh sách chung, buffer trung chuyển của chúng sống tới flush, và flush nộp một
// lần rồi trả chúng. Chỉ có tác dụng khi thiết bị có bộ nhớ hợp nhất
// (DeviceCaps::has_unified_memory: lưới đã ghi thẳng, chỉ ảnh cần lệnh chép); thiết bị khác thì
// place đi thẳng upload_queued. Luồng gọi của một batch là luồng ghi lệnh của thiết bị. Ràng buộc
// người gọi: mọi Uploaded do batch trả ra chưa có byte ảnh cho tới flush, nên phải flush trước khi
// vẽ bằng chúng và trước khi huỷ chúng; và không gọi end_frame giữa place và flush vì end_frame thu
// hồi danh sách chưa nộp.
class UploadBatch {
public:
    explicit UploadBatch(gpu::Device& device) noexcept : device_(&device) {}
    // Quên flush thì destructor nộp nốt; lỗi lúc ấy không báo được, nên chỗ gọi nên flush và đọc
    // lỗi.
    ~UploadBatch();
    UploadBatch(const UploadBatch&) = delete;
    UploadBatch& operator=(const UploadBatch&) = delete;
    UploadBatch(UploadBatch&&) = delete;
    UploadBatch& operator=(UploadBatch&&) = delete;

    // Như upload_queued(device, model, baked) nhưng lệnh chép ảnh chờ ở flush.
    [[nodiscard]] core::Result<Uploaded> place(const Model& model, Baked baked);
    // Nộp danh sách chung bằng một lần nộp rồi trả buffer trung chuyển. Không có gì chờ thì không
    // làm gì.
    [[nodiscard]] core::Status flush();
    [[nodiscard]] bool has_pending() const noexcept { return commands_ != nullptr; }

private:
    gpu::Device* device_ = nullptr;
    // Danh sách lệnh mở của lượt; rỗng tới khi có mesh đầu tiên cần chép ảnh.
    gpu::CommandList* commands_ = nullptr;
    // Buffer trung chuyển của các ảnh đã ghi vào commands_.
    std::vector<gpu::BufferHandle> staging_;
};

} // namespace game::resource
