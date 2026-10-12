// Gom phản chiếu shader thành bố cục chỗ gắn dùng chung giữa các chương trình.
// Tên tài nguyên không vào băm: khác tên mà cùng bố cục vẫn chung một nhóm.
// Mảng không chặn phải là chỗ gắn cuối và chỉ một; cbuffer không được không chặn.
// Nguồn: Forge2 src/gpu/layout.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; thân vòng lặp có
// nhánh của check_unique, check_complete, make_layout, check_entries tách hàm hoặc đổi thành phép
// tìm (ghi tại chỗ); ProgramLayout trong make_layout khai rồi gán trường; include trực tiếp header
// của mọi tên dùng tới.
#include "gpu/layout.hpp"

#include "core/error.hpp"
#include "core/hash.hpp"
#include "gpu/binding.hpp"
#include "gpu/handle.hpp"
#include "gpu/types.hpp"
#include "shader/reflection.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <span>
#include <utility>
#include <variant>

namespace game::gpu {

namespace {

using core::ErrorCode;
using core::fail;
using shader::RegisterType;
using shader::Resource;
using shader::ResourceKind;

[[nodiscard]] std::uint64_t hash_fields(std::uint64_t seed, std::span<const std::uint32_t> fields) noexcept {
    return core::hash_combine(seed, core::fnv1a(std::as_bytes(fields)));
}

// Băm một chỗ gắn: mọi trường mà descriptor set layout và root signature phụ thuộc. Tên không vào
// băm: hai shader đặt tên khác nhau cho cùng một bố cục vẫn dùng chung nhóm.
[[nodiscard]] std::uint64_t hash_resource(std::uint64_t seed, const Resource& resource,
    std::uint32_t block_bytes) noexcept {
    const std::array<std::uint32_t, 7> fields{std::to_underlying(resource.kind), resource.slot, resource.binding,
        resource.count, resource.stages.bits(), resource.stride, block_bytes};
    return hash_fields(seed, fields);
}

void add_resource(SpaceLayout& space, const shader::ProgramReflection& program, const Resource& resource) {
    const bool has_block = resource.block != shader::kNoBlock;
    const std::uint32_t block_bytes = has_block ? program.blocks.at(resource.block).size : 0;
    space.resources.push_back(resource);
    space.block_bytes.push_back(block_bytes);
    space.hash = hash_resource(space.hash, resource, block_bytes);
}

// Mảng không chặn phải đứng cuối (binding lớn nhất) và chỉ có một.
[[nodiscard]] core::Status check_unbounded(SpaceLayout& space) {
    const auto is_open = [](const Resource& resource) { return resource.count == 0; };
    const auto open = std::ranges::count_if(space.resources, is_open);
    if (open == 0) return core::ok();
    if (open > 1) return fail(ErrorCode::kInvalidArgument, "một space có hai mảng không chặn");
    const Resource& last = space.resources.back();
    if (!is_open(last)) {
        return fail(ErrorCode::kInvalidArgument, "mảng không chặn không phải chỗ gắn cuối của space", "{}", last.name);
    }
    // cbuffer không làm mảng không chặn: giới hạn uniform buffer của nhiều thiết bị chỉ vài chục.
    if (last.kind == ResourceKind::kUniformBuffer) {
        return fail(ErrorCode::kInvalidArgument, "cbuffer không làm mảng không chặn được", "{}", last.name);
    }
    space.is_unbounded = true;
    return core::ok();
}

[[nodiscard]] core::Status add_push(ProgramLayout& layout, const shader::ProgramReflection& program,
    const Resource& resource) {
    const std::uint32_t size = program.blocks.at(resource.block).size;
    const std::uint32_t rounded = (size + 3U) & ~3U;
    if (rounded > kMaxPushBytes) {
        return fail(ErrorCode::kInvalidArgument, "khối push constant vượt kMaxPushBytes", "{} byte", size);
    }
    layout.push_bytes = rounded;
    layout.push_stages = resource.stages;
    return core::ok();
}

[[nodiscard]] core::Status place(ProgramLayout& layout, const shader::ProgramReflection& program,
    const Resource& resource) {
    if (resource.kind == ResourceKind::kPushConstant) return add_push(layout, program, resource);
    if (resource.space >= kMaxBindGroups) {
        return fail(ErrorCode::kInvalidArgument, "register space vượt kMaxBindGroups", "{} ở space{}", resource.name,
            resource.space);
    }
    // Mọi phần phía sau (mảng không chặn đứng cuối, băm) dựa vào thứ tự binding tăng dần mà
    // shader::normalize bảo đảm; phản chiếu dựng tay sai thứ tự bị từ chối ở đây.
    SpaceLayout& space = layout.spaces.at(resource.space);
    const bool is_ordered = space.resources.empty() || space.resources.back().binding < resource.binding;
    if (!is_ordered) {
        return fail(ErrorCode::kInvalidArgument, "phản chiếu không xếp theo binding tăng dần", "{}", resource.name);
    }
    add_resource(space, program, resource);
    return core::ok();
}

[[nodiscard]] std::uint32_t element_count(const Resource& resource, std::uint32_t capacity) noexcept {
    return resource.count == 0 ? capacity : resource.count;
}

[[nodiscard]] bool holds(const Bound& resource, BoundKind kind) noexcept {
    switch (kind) {
    case BoundKind::kBuffer: return std::holds_alternative<BufferRange>(resource);
    case BoundKind::kView: return std::holds_alternative<TextureViewHandle>(resource);
    case BoundKind::kSampler: return std::holds_alternative<SamplerHandle>(resource);
    }
    return false;
}

[[nodiscard]] core::Status check_entry(const SpaceLayout& space, const BindEntry& entry, std::uint32_t capacity) {
    const Resource* const resource = find_resource(space, entry.type, entry.slot);
    if (resource == nullptr) {
        return fail(ErrorCode::kInvalidArgument, "nhóm gắn: shader không có chỗ gắn này", "lớp {} chỉ số {}",
            std::to_underlying(entry.type), entry.slot);
    }
    if (entry.element >= element_count(*resource, capacity)) {
        return fail(ErrorCode::kInvalidArgument, "nhóm gắn: phần tử nằm ngoài mảng", "{}[{}]", resource->name,
            entry.element);
    }
    if (!holds(entry.resource, bound_kind(resource->kind))) {
        return fail(ErrorCode::kInvalidArgument, "nhóm gắn: sai loại tài nguyên cho chỗ gắn", "{}", resource->name);
    }
    return core::ok();
}

[[nodiscard]] bool is_same_place(const BindEntry& left, const BindEntry& right) noexcept {
    return left.type == right.type && left.slot == right.slot && left.element == right.element;
}

// Khác gốc: lambda is_same và phép none_of trong thân vòng lặp của check_unique tách ra đây.
// Entry thứ index không trùng chỗ gắn với entry nào đứng trước nó.
[[nodiscard]] bool is_new_place(std::span<const BindEntry> entries, std::size_t index) noexcept {
    const BindEntry& entry = entries.subspan(index, 1).front();
    const auto is_same = [&](const BindEntry& earlier) { return is_same_place(earlier, entry); };
    return std::ranges::none_of(entries.first(index), is_same);
}

// Mỗi chỗ gắn tối đa một entry.
[[nodiscard]] core::Status check_unique(std::span<const BindEntry> entries) {
    // Khác gốc: gốc là vòng for có continue và return fail trong thân; ở đây vòng chỉ tìm entry
    // trùng đầu tiên, cùng thứ tự duyệt, rồi mới trả lỗi.
    std::size_t index = 1;
    while (index < entries.size() && is_new_place(entries, index)) {
        ++index;
    }
    if (index >= entries.size()) return core::ok();
    const BindEntry& entry = entries.subspan(index, 1).front();
    return fail(ErrorCode::kInvalidArgument, "nhóm gắn: một chỗ gắn có hai entry", "lớp {} chỉ số {}",
        std::to_underlying(entry.type), entry.slot);
}

// Số entry của entries rơi vào chỗ gắn resource.
[[nodiscard]] std::size_t entries_for(std::span<const BindEntry> entries, const Resource& resource) noexcept {
    const RegisterType type = shader::register_type(resource.kind);
    const auto is_here = [&](const BindEntry& entry) { return entry.type == type && entry.slot == resource.slot; };
    return static_cast<std::size_t>(std::ranges::count_if(entries, is_here));
}

// Mọi chỗ gắn cỡ cố định có đủ entry (entries đã qua check_unique và check_entry).
[[nodiscard]] core::Status check_complete(const SpaceLayout& space, std::span<const BindEntry> entries) {
    // Khác gốc: gốc là vòng for có continue và return fail trong thân; ở đây find_if_not tìm chỗ
    // gắn thiếu đầu tiên, cùng thứ tự duyệt.
    const auto is_filled = [entries](const Resource& resource) {
        return resource.count == 0 || entries_for(entries, resource) == resource.count;
    };
    const auto missing = std::ranges::find_if_not(space.resources, is_filled);
    if (missing == space.resources.end()) return core::ok();
    return fail(ErrorCode::kInvalidArgument, "nhóm gắn: thiếu tài nguyên cho chỗ gắn", "{}", missing->name);
}

// Khác gốc: gốc viết ba vòng for có câu if (!status) return trong thân (hai ở make_layout, một ở
// check_entries); ở đây một hàm chung chạy check trên từng phần tử theo thứ tự và dừng ở lỗi đầu
// tiên.
template <class Item, class Check>
[[nodiscard]] core::Status first_failure(std::span<Item> items, const Check& check) {
    core::Status status = core::ok();
    for (auto item = items.begin(); item != items.end() && status; ++item) {
        status = check(*item);
    }
    return status;
}

// Khác gốc: phần còn lại của thân vòng lặp thứ hai trong make_layout tách ra đây: kiểm mảng không
// chặn của một space, rồi gộp băm của nó và đếm vào open.
[[nodiscard]] core::Status close_space(ProgramLayout& layout, SpaceLayout& space, std::uint32_t& open) {
    const core::Status checked = check_unbounded(space);
    if (!checked) return checked;
    layout.hash = core::hash_combine(layout.hash, space.hash);
    open += space.is_unbounded ? 1U : 0U;
    return core::ok();
}

} // namespace

core::Result<ProgramLayout> make_layout(const shader::ProgramReflection& program) {
    // Khác gốc: gốc viết ProgramLayout layout{.stages = program.stages}; các trường StageSet đã bỏ
    // {} nên khởi tạo chỉ định thiếu trường bị -Wmissing-field-initializers chặn.
    ProgramLayout layout;
    layout.stages = program.stages;
    // program.resources đã xếp theo (space, lớp register, slot): cùng thứ tự với binding tăng dần.
    const auto place_one = [&layout, &program](const Resource& resource) { return place(layout, program, resource); };
    const core::Status placed = first_failure(std::span(program.resources), place_one);
    if (!placed) return std::unexpected(placed.error());
    std::uint32_t open = 0;
    const auto close_one = [&](SpaceLayout& space) { return close_space(layout, space, open); };
    const core::Status closed = first_failure(std::span<SpaceLayout>(layout.spaces), close_one);
    if (!closed) return std::unexpected(closed.error());
    if (open > kMaxUnboundedArrays) {
        return fail(ErrorCode::kInvalidArgument, "pipeline có quá kMaxUnboundedArrays mảng không chặn");
    }
    const std::array<std::uint32_t, 2> push{layout.push_bytes, layout.push_stages.bits()};
    layout.hash = hash_fields(layout.hash, push);
    return layout;
}

const shader::Resource* find_resource(const SpaceLayout& space, shader::RegisterType type,
    std::uint32_t slot) noexcept {
    const auto matches = [&](const Resource& resource) {
        return shader::register_type(resource.kind) == type && resource.slot == slot;
    };
    const auto found = std::ranges::find_if(space.resources, matches);
    return found == space.resources.end() ? nullptr : std::to_address(found);
}

core::Status check_update(const SpaceLayout& space, std::span<const BindEntry> entries, std::uint32_t capacity) {
    const Resource* const open = unbounded_resource(space);
    if (open == nullptr) return fail(ErrorCode::kInvalidArgument, "nhóm không có mảng không chặn");
    const RegisterType type = shader::register_type(open->kind);
    const auto is_open = [&](const BindEntry& entry) { return entry.type == type && entry.slot == open->slot; };
    if (!std::ranges::all_of(entries, is_open)) {
        return fail(ErrorCode::kInvalidArgument, "cập nhật nhóm: chỉ mảng không chặn được ghi lại");
    }
    return check_entries(space, entries, capacity, false);
}

const shader::Resource* unbounded_resource(const SpaceLayout& space) noexcept {
    return space.is_unbounded ? &space.resources.back() : nullptr;
}

std::uint32_t block_size(const SpaceLayout& space, const shader::Resource& resource) {
    const auto index = static_cast<std::size_t>(&resource - space.resources.data());
    return space.block_bytes.at(index);
}

// Không default: thêm loại tài nguyên mà quên ở đây là C4062.
BoundKind bound_kind(shader::ResourceKind kind) noexcept {
    switch (kind) {
    case ResourceKind::kSampler: return BoundKind::kSampler;
    case ResourceKind::kTexture:
    case ResourceKind::kRwTexture:
    case ResourceKind::kInputAttachment: return BoundKind::kView;
    case ResourceKind::kBuffer:
    case ResourceKind::kRwBuffer:
    case ResourceKind::kTexelBuffer:
    case ResourceKind::kRwTexelBuffer:
    case ResourceKind::kUniformBuffer:
    case ResourceKind::kPushConstant:
    case ResourceKind::kAccelerationStructure: return BoundKind::kBuffer;
    }
    return BoundKind::kBuffer;
}

core::Status check_entries(const SpaceLayout& space, std::span<const BindEntry> entries, std::uint32_t capacity,
    bool is_complete) {
    if (space.is_unbounded != (capacity != 0)) {
        return fail(ErrorCode::kInvalidArgument, "nhóm gắn: capacity phải khác 0 đúng khi space có mảng không chặn");
    }
    const auto check_one = [&space, capacity](const BindEntry& entry) { return check_entry(space, entry, capacity); };
    const core::Status checked = first_failure(entries, check_one);
    if (!checked) return checked;
    const core::Status unique = check_unique(entries);
    if (!unique) return unique;
    return is_complete ? check_complete(space, entries) : core::ok();
}

} // namespace game::gpu
