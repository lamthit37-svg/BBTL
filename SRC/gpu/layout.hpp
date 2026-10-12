// Bố cục gắn tài nguyên của một pipeline, dựng từ phản chiếu shader và không phụ thuộc backend: mỗi
// register space một nhóm, cộng khối push constant. Hai backend đọc cùng cấu trúc này để dựng
// descriptor set layout (Vulkan) và root signature (D3D12), và để kiểm BindEntry lúc tạo nhóm. Thay
// macro SRT của _Ref (bố cục khai tay ở cả C++ lẫn shader, lệch nhau là sai lúc chạy) và root
// signature viết tay của Wicked. Dùng nội bộ trong module.
// Nguồn: Forge2 src/gpu/layout.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; bỏ {} thừa của các
// thành viên vector và StageSet ở SpaceLayout, ProgramLayout.
#pragma once

#include "core/error.hpp"
#include "gpu/binding.hpp"
#include "gpu/types.hpp"
#include "shader/reflection.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <vector>

namespace game::gpu {

// Khác gốc: bỏ {} mà clang-tidy báo thừa ở thành viên vector và StageSet của hai struct dưới.
struct SpaceLayout {
    // Xếp theo binding của Vulkan tăng dần; rỗng khi pipeline không dùng space này.
    std::vector<shader::Resource> resources;
    // Cỡ cbuffer của từng phần tử trong resources; 0 với loại không phải cbuffer.
    std::vector<std::uint32_t> block_bytes;
    // Space có một mảng không chặn (count 0): nhóm của nó cần BindGroupDesc::capacity và được cập
    // nhật khi đang dùng.
    bool is_unbounded = false;
    // Băm của mọi thứ quyết định bố cục: hai space cùng băm dùng chung được nhóm gắn.
    std::uint64_t hash = 0;
};

struct ProgramLayout {
    std::array<SpaceLayout, kMaxBindGroups> spaces{};
    // Cỡ khối push constant, làm tròn lên bội của 4; 0 khi không có.
    std::uint32_t push_bytes = 0;
    shader::StageSet push_stages;
    shader::StageSet stages;
    std::uint64_t hash = 0;
};

// InvalidArgument khi: một tài nguyên nằm ở register space từ kMaxBindGroups trở lên (trừ khối
// push constant); khối push constant vượt kMaxPushBytes; một space có hai mảng không chặn, hoặc
// mảng không chặn không phải chỗ gắn cuối của space (Vulkan chỉ cho mảng cỡ biến thiên ở binding
// lớn nhất — đặt mảng ấy một mình một space là cách đơn giản nhất); pipeline có quá
// kMaxUnboundedArrays mảng không chặn.
[[nodiscard]] core::Result<ProgramLayout> make_layout(const shader::ProgramReflection& program);

// Chỗ gắn (type, slot) của space; nullptr khi space không có.
[[nodiscard]] const shader::Resource* find_resource(const SpaceLayout& space, shader::RegisterType type,
    std::uint32_t slot) noexcept;

// Loại tài nguyên gắn được vào một chỗ.
enum class BoundKind : std::uint8_t {
    kBuffer,
    kView,
    kSampler,
};

[[nodiscard]] BoundKind bound_kind(shader::ResourceKind kind) noexcept;

// Kiểm entries so với bố cục của space: chỗ gắn có thật, đúng loại tài nguyên, phần tử trong mảng
// (hoặc trong capacity với mảng không chặn), không trùng. is_complete: mọi chỗ gắn có cỡ cố định
// của space phải có mặt đủ mọi phần tử (lúc tạo nhóm); false khi cập nhật.
[[nodiscard]] core::Status check_entries(const SpaceLayout& space, std::span<const BindEntry> entries,
    std::uint32_t capacity, bool is_complete);

// Kiểm entries của một lần cập nhật nhóm: như check_entries không đòi đủ, và mọi entry phải rơi
// vào mảng không chặn của space — chỗ gắn cỡ cố định không được ghi lại khi nhóm có thể đang nằm
// trong một lệnh đã nộp.
[[nodiscard]] core::Status check_update(const SpaceLayout& space, std::span<const BindEntry> entries,
    std::uint32_t capacity);

// Mảng không chặn của space; nullptr khi space không có.
[[nodiscard]] const shader::Resource* unbounded_resource(const SpaceLayout& space) noexcept;

// Cỡ cbuffer của resource, một phần tử của space.resources; 0 với loại không phải cbuffer.
[[nodiscard]] std::uint32_t block_size(const SpaceLayout& space, const shader::Resource& resource);

} // namespace game::gpu
