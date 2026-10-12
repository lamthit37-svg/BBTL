// Nhóm gắn tài nguyên (bind group): các tài nguyên của một register space, gắn vào pipeline bằng
// một lệnh — DescriptorSet, DescriptorData, updateDescriptorSet của _Ref; BindlessTable của
// Platium; BindResource và GetDescriptorIndex của Wicked. Bố cục của nhóm không khai ở đây: nó là
// phần phản chiếu shader của register space ấy, nên chỗ gọi chỉ nói "t3 là view này" đúng như viết
// trong HLSL. Một nhóm là descriptor set của Vulkan và một hoặc hai descriptor table của D3D12.
// Mảng không chặn trong shader (Texture2D bảng[] : register(t0, space2)) là bảng bindless: cùng cơ
// chế, thêm sức chứa khai lúc tạo và được cập nhật khi đang dùng. Ba bản tham chiếu mỗi bản chỉ có
// một trong hai đường (nhóm thường, hoặc bindless); thiết bị điện thoại thiếu descriptor indexing
// vẫn chạy được đường nhóm thường (DeviceCaps::bindless).
// Nguồn: Forge2 src/gpu/binding.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; bỏ {} thừa của
// BindEntry::resource, BindGroupDesc::name và BindGroupDesc::entries.
#pragma once

#include "gpu/handle.hpp"
#include "gpu/types.hpp"
#include "shader/reflection.hpp"

#include <cstdint>
#include <span>
#include <string_view>
#include <variant>

namespace game::gpu {

// Một khoảng của buffer. size bằng kWholeSize là tới hết buffer (với cbuffer: đúng cỡ khối của
// shader). cbuffer: offset là bội của kUniformAlignment và buffer còn đủ cỡ khối làm tròn lên 256
// byte. Buffer có cấu trúc: offset và cỡ là bội của cỡ phần tử; offset là bội của cả cỡ phần tử lẫn
// 256 thì chạy được trên mọi thiết bị.
struct BufferRange {
    BufferHandle buffer{};
    std::uint64_t offset = 0;
    std::uint64_t size = kWholeSize;
};

// Thứ gắn vào một chỗ: buffer cho cbuffer và các loại Buffer, view cho Texture và RWTexture,
// sampler cho SamplerState.
using Bound = std::variant<BufferRange, TextureViewHandle, SamplerHandle>;

struct BindEntry {
    // Lớp register và chỉ số như trong HLSL: register(t3) là {kResource, 3}.
    shader::RegisterType type = shader::RegisterType::kResource;
    std::uint32_t slot = 0;
    // Phần tử của mảng; 0 khi không phải mảng.
    std::uint32_t element = 0;
    // Khác gốc: bỏ {} mà clang-tidy báo thừa, ở đây và ở name, entries của struct dưới.
    Bound resource;
};

struct BindGroupDesc {
    std::string_view name;
    // Pipeline cho bố cục. Nhóm dùng được với mọi pipeline có cùng bố cục ở register space này.
    PipelineHandle pipeline{};
    std::uint32_t space = 0;
    // Nhóm không có mảng không chặn: phải đủ mọi chỗ gắn của space. Nhóm có mảng không chặn: phần
    // tử của mảng ấy được vắng, và shader không được đọc phần tử chưa gắn.
    std::span<const BindEntry> entries;
    // Sức chứa của mảng không chặn trong space này; 0 khi space không có mảng nào như vậy.
    std::uint32_t capacity = 0;
};

} // namespace game::gpu
