// Kiểm mô tả tài nguyên và dựng chương trình shader, dùng chung cho hai backend: phép kiểm như
// nhau ở mọi API, và hai bản chép của cùng một phép kiểm là hai chỗ để lệch. _Ref kiểm bằng ASSERT
// (bản Release bỏ, mô tả sai đi thẳng xuống trình điều khiển); Platium kiểm lẻ trong từng backend.
// Ở đây mô tả sai là InvalidArgument kèm tên trường, trước khi chạm API. Dùng nội bộ trong module.
// Nguồn: Forge2 src/gpu/check.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k.
#pragma once

#include "core/error.hpp"
#include "gpu/device.hpp"
#include "gpu/layout.hpp"

#include <cstdint>
#include <span>

namespace game::gpu {

[[nodiscard]] core::Status check_buffer(const BufferDesc& desc);
[[nodiscard]] core::Status check_texture(const TextureDesc& desc, const DeviceCaps& caps);

// View đã điền mọi giá trị mặc định: định dạng thật, số mip và số lớp thật.
struct ViewRange {
    Format format = Format::kUnknown;
    ViewAspect aspect = ViewAspect::kAll;
    std::uint32_t first_mip = 0;
    std::uint32_t mip_count = 1;
    std::uint32_t first_layer = 0;
    std::uint32_t layer_count = 1;
};

// InvalidArgument khi khoảng mip hay lớp vượt texture, kind không hợp số lớp (Cube cần 6), định
// dạng ép kiểu mà texture thiếu Reinterpret hoặc khác cỡ khối, hay aspect không có trong định dạng.
[[nodiscard]] core::Result<ViewRange> resolve_view(const TextureViewDesc& view, const TextureDesc& texture);

// [offset, offset + count) nằm trong buffer dài size.
[[nodiscard]] core::Status check_span(std::uint64_t size, std::uint64_t offset, std::uint64_t count);

// Khoảng thật của một BufferRange trên buffer dài size (kWholeSize thành tới hết); InvalidArgument
// khi vượt biên hoặc rỗng.
[[nodiscard]] core::Result<std::uint64_t> resolve_range(const BufferRange& range, std::uint64_t size);

// Sức chứa của nhóm có mảng không chặn nằm trong trần của thiết bị (DeviceCaps::max_unbounded,
// max_unbounded_samplers); Unsupported khi thiết bị không có bindless hoặc capacity vượt trần.
[[nodiscard]] core::Status check_capacity(const SpaceLayout& space, std::uint32_t capacity, const DeviceCaps& caps);

// Một vùng chép giữa buffer và texture, đã điền mọi mặc định và đã kiểm biên ở cả hai phía.
struct CopyRegion {
    std::uint64_t buffer_offset = 0;
    // Bước dòng trong buffer tính bằng byte, và số hàng khối của một lát.
    std::uint32_t row_bytes = 0;
    std::uint32_t rows = 0;
    std::uint32_t mip = 0;
    std::uint32_t first_layer = 0;
    std::uint32_t layer_count = 1;
    std::uint32_t x = 0;
    std::uint32_t y = 0;
    std::uint32_t z = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::uint32_t depth = 0;
};

// Bố cục dữ liệu trong buffer, như nhau ở hai backend: các dòng của một lát cách nhau row_bytes,
// các lát của texture 3D nối liền nhau (rows dòng mỗi lát), các lớp của mảng nối liền nhau. Chép
// nhiều lớp một lần thì cỡ một lớp phải là bội của kTextureOffsetAlignment (D3D12 đặt mỗi lớp ở
// một offset căn như vậy). InvalidArgument khi vùng ra ngoài mức mip, lệch biên khối của định dạng
// nén, sai căn, hay texture đa mẫu; OutOfRange khi dữ liệu vượt buffer; Unsupported cho định dạng
// độ sâu kèm stencil (hai phần nằm ở hai mặt phẳng, chưa chép được).
[[nodiscard]] core::Result<CopyRegion> resolve_copy(const BufferTextureCopy& region, const TextureDesc& texture,
    std::uint64_t buffer_size);

// Vùng chép giữa hai texture với mọi cỡ đã điền. InvalidArgument khi hai texture khác định dạng,
// khác số mẫu, một bên là 3D còn bên kia không, hay vùng ra ngoài một trong hai mức mip.
[[nodiscard]] core::Result<TextureCopy> resolve_copy(const TextureCopy& region, const TextureDesc& source,
    const TextureDesc& target);

// Cỡ gắn của một khoảng buffer vào chỗ gắn resource của space, theo luật chung của hai backend:
// - cbuffer: offset là bội của kUniformAlignment; chỗ gọi để kWholeSize thì gắn đúng cỡ khối của
//   shader; khoảng phải chứa trọn khối, và buffer phải còn đủ cỡ khối làm tròn lên
//   kUniformAlignment kể từ offset (D3D12 gắn theo bội của 256);
// - buffer có cấu trúc: offset và cỡ là bội của cỡ phần tử.
// InvalidArgument khi sai căn; OutOfRange khi vượt buffer.
[[nodiscard]] core::Result<std::uint64_t> resolve_binding(const SpaceLayout& space, const shader::Resource& resource,
    const BufferRange& range, std::uint64_t buffer_size);

// Phản chiếu gộp và bố cục gắn của một bộ stage.
struct Program {
    shader::ProgramReflection reflection{};
    ProgramLayout layout{};
};

// Gộp các stage (shader::merge), kiểm chữ ký giữa hai stage liền nhau theo thứ tự đường ống
// (shader::check_interface) và dựng bố cục. stages theo thứ tự bất kỳ.
[[nodiscard]] core::Result<Program> make_program(std::span<const shader::StageReflection> stages);

// Kiểm phần của GraphicsPipelineDesc không cần biết backend: số đích, định dạng, thuộc tính đỉnh
// khớp đầu vào của vertex shader, blends đúng số lượng.
[[nodiscard]] core::Status check_pipeline(const GraphicsPipelineDesc& desc, const Program& program,
    const DeviceCaps& caps);

// Đầu vào của vertex shader ứng với một thuộc tính đỉnh; nullptr khi shader không có location ấy.
[[nodiscard]] const shader::Attribute* find_input(const shader::ProgramReflection& program,
    std::uint32_t location) noexcept;

} // namespace game::gpu
