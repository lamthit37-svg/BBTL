// Đọc GLB bằng cgltf: JSON, buffer, accessor (kể cả sparse) đã được kiểm. Ảnh nhúng, data-URI
// và file cạnh: PNG/JPEG giải ở image.cpp, DDS giữ khối ở dds.cpp. Biến đổi nút lấy ma trận cục bộ.
// Chỉ số sparse đọc nguyên. Float32 không giữ 16777217, nên không giải chỉ số bằng float.
// Buffer view nén EXT_meshopt_compression giải bằng meshoptimizer SAU cgltf_validate: bộ giải mã
// assert tiền điều kiện chứ không báo lỗi, nên mô tả phải qua kiểm trước (Wicked bản orio giải
// trước khi kiểm). Tệp đòi extension ngoài danh sách kRequired bị từ chối, không dựng thiếu.
// Khác gốc: vòng có nhánh tách hàm hoặc while, thân không còn if; khối sau case thành hàm; cộng
// con trỏ đổi thành span hoặc hiệu uintptr_t; lời gọi lồng đặt biến trung gian. Công thức, toán
// tử và thứ tự kiểm giữ nguyên. __clang_analyzer__ tắt thân cgltf: tidy báo nhầm biên jsmn.
// Bản dịch thật vẫn bật CGLTF_IMPLEMENTATION.
#include "resource/model.hpp"

#include "resource/dds.hpp"

#include "core/error.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "io/file.hpp"
#include "math/matrix.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"

#include "resource/image.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <expected>
#include <limits>
#include <memory>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#ifndef __clang_analyzer__
#define CGLTF_IMPLEMENTATION
#endif
#include <cgltf.h>
#include <meshoptimizer.h>

namespace game::resource {

namespace {

namespace core = game::core;

using core::Status;
using Gltf = cgltf_data;
using Accessor = cgltf_accessor;
using Attribute = cgltf_attribute;
using PrimitiveIn = cgltf_primitive;
using ComponentType = cgltf_component_type;
using Channel = cgltf_animation_channel;
using Meshopt = cgltf_meshopt_compression;
using CameraOrtho = cgltf_camera_orthographic;
using UvField = math::Float2 Vertex::*;
using MorphField = math::Float3 MorphVertex::*;
using MorphUvField = math::Float2 MorphVertex::*;
using Vertices = std::vector<Vertex>;
using Morphs = std::vector<MorphVertex>;
using Indices = std::vector<std::uint32_t>;
using Floats = std::vector<float>;
using ImageResult = core::Result<Image>;
using MaybeIndex = std::optional<std::uint32_t>;
using AttrSpan = std::span<const Attribute>;
using Byte = const std::uint8_t*;
using PrimIn = const PrimitiveIn&;
using MorphSrc = const cgltf_morph_target&;
using MeshSrc = const cgltf_mesh&;
using GltfRef = const Gltf&;
using Encoded = std::span<const std::byte>;
using AccessorPtr = const Accessor*;
using MapSrc = const cgltf_material_mapping&;

struct GltfFree {
    static void operator()(cgltf_data* data) noexcept { cgltf_free(data); }
};

using GltfPtr = std::unique_ptr<cgltf_data, GltfFree>;

struct HeapFree {
    // cgltf_free gọi free (SH-02).
    // NOLINTNEXTLINE(cppcoreguidelines-no-malloc, cppcoreguidelines-owning-memory)
    static void operator()(void* owned_memory) noexcept { std::free(owned_memory); }
};

using HeapPtr = std::unique_ptr<void, HeapFree>;

[[nodiscard]] core::Failure bad(core::Message message) {
    return core::fail(core::ErrorCode::kCorrupt, message);
}

[[nodiscard]] core::Failure unsupported(core::Message message) {
    return core::fail(core::ErrorCode::kUnsupported, message);
}

// Đọc tệp qua io của THIENLONG rồi chép sang fs::Bytes: fs/file của Forge2 là Win32, bản dựng
// thiết bị không có nó (shader/package.cpp đã đi đường này trước).
[[nodiscard]] core::Result<fs::Bytes> read_bytes(std::string_view path) {
    const io::TextResult text = io::read_text(io::path_from_utf8(path));
    if (!text) {
        const core::ErrorCode code =
            text.error() == io::FileError::kNotFound ? core::ErrorCode::kNotFound : core::ErrorCode::kIo;
        return core::fail(code, "không đọc được tệp", "{}", path);
    }
    fs::Bytes bytes(text->size());
    std::ranges::copy(std::as_bytes(std::span(*text)), bytes.span().begin());
    return bytes;
}

template <class T>
[[nodiscard]] core::Failure failure_of(const core::Result<T>& result) {
    // Chỉ lúc thất bại: error() là UB.
    const core::Error& error = result.error();
    return core::Failure(error);
}

template <class Step>
[[nodiscard]] Status each_index(std::size_t count, const Step& step) {
    Status status = core::ok();
    std::size_t index = 0;
    // Khác gốc: while thay for+if.
    while (status && index < count) {
        status = step(index);
        ++index;
    }
    return status;
}

template <class Range, class Step>
[[nodiscard]] Status each_item(const Range& items, const Step& step) {
    Status status = core::ok();
    auto cursor = std::ranges::begin(items);
    const auto end = std::ranges::end(items);
    // Khác gốc: while thay for+if.
    while (status && cursor != end) {
        status = step(*cursor);
        ++cursor;
    }
    return status;
}

template <class Item>
void append_moved(std::vector<Item>& out, Item& value) {
    const std::size_t count = out.size();
    out.resize(count + 1);
    out.back() = std::move(value);
}

[[nodiscard]] core::Failure gltf_fail(cgltf_result code) {
    if (code == cgltf_result_out_of_memory) {
        return core::fail(core::ErrorCode::kOutOfMemory, "hết bộ nhớ khi đọc GLB");
    }
    const bool invalid = code == cgltf_result_invalid_json || code == cgltf_result_invalid_gltf;
    if (invalid) return core::fail(core::ErrorCode::kCorrupt, "GLB không hợp lệ");
    if (code == cgltf_result_file_not_found) return core::fail(core::ErrorCode::kNotFound, "GLB thiếu buffer");
    if (code == cgltf_result_data_too_short) return core::fail(core::ErrorCode::kCorrupt, "GLB thiếu dữ liệu");
    return core::fail(core::ErrorCode::kCorrupt, "không đọc được GLB");
}

// Khác gốc: 16 float qua memcpy rồi chỉ số hằng, không chỉ số con trỏ.
[[nodiscard]] math::Matrix4 matrix_from(const float* values) noexcept {
    std::array<float, 16> cells{};
    float* destination = cells.data();
    std::memcpy(destination, values, sizeof(cells));
    const math::Vector4 column0(cells[0], cells[1], cells[2], cells[3]);
    const math::Vector4 column1(cells[4], cells[5], cells[6], cells[7]);
    const math::Vector4 column2(cells[8], cells[9], cells[10], cells[11]);
    const math::Vector4 column3(cells[12], cells[13], cells[14], cells[15]);
    return {column0, column1, column2, column3};
}

[[nodiscard]] std::uint32_t index_of(const void* one, const void* base, std::size_t step) noexcept {
    // Khác gốc: hiệu uintptr_t, cùng thương trừ hai con trỏ.
    static_assert(sizeof(const void*) == sizeof(std::uintptr_t));
    const auto item_address = std::bit_cast<std::uintptr_t>(one);
    const auto base_address = std::bit_cast<std::uintptr_t>(base);
    const std::uintptr_t delta = item_address - base_address;
    const std::uintptr_t index = delta / step;
    return static_cast<std::uint32_t>(index);
}

[[nodiscard]] std::string text_of(const char* value) {
    if (value == nullptr) return {};
    return value;
}

// Khác gốc: chép float qua span, không cộng con trỏ.
void copy_floats(const float* data, std::size_t count, Floats& out) {
    if (data == nullptr || count == 0) return;
    const std::span<const float> source(data, count);
    const auto first = source.begin();
    const auto last = source.end();
    out.assign(first, last);
}

[[nodiscard]] Status unpack(const Accessor* accessor, Floats& raw, std::size_t components) {
    if (accessor == nullptr) return core::fail(core::ErrorCode::kCorrupt, "accessor trống");
    const bool overflows = components == 0 || accessor->count > std::numeric_limits<std::size_t>::max() / components;
    if (overflows) return core::fail(core::ErrorCode::kOverflow, "accessor quá lớn");
    raw.resize(accessor->count * components);
    float* destination = raw.data();
    const std::size_t room = raw.size();
    const cgltf_size written = cgltf_accessor_unpack_floats(accessor, destination, room);
    if (written != raw.size()) return bad("accessor hỏng");
    return core::ok();
}

[[nodiscard]] Status components_ok(const Accessor* source, std::size_t expect, core::Message note) {
    if (cgltf_num_components(source->type) != expect) return bad(note);
    return core::ok();
}

[[nodiscard]] Status read_positions(const Accessor* accessor, Vertices& vertices) {
    const Status kind = components_ok(accessor, 3, "vị trí không phải VEC3");
    if (!kind) return kind;
    Floats raw;
    const Status status = unpack(accessor, raw, 3);
    if (!status) return status;
    vertices.resize(accessor->count);
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * 3;
        vertices[index].position = {.x = raw[base], .y = raw[base + 1], .z = raw[base + 2]};
    }
    return core::ok();
}

[[nodiscard]] Status read_normals(const Accessor* accessor, Vertices& vertices) {
    const Status kind = components_ok(accessor, 3, "pháp tuyến không phải VEC3");
    if (!kind) return kind;
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    Floats raw;
    const Status status = unpack(accessor, raw, 3);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * 3;
        vertices[index].normal = {.x = raw[base], .y = raw[base + 1], .z = raw[base + 2]};
    }
    return core::ok();
}

[[nodiscard]] Status read_tangents(const Accessor* accessor, Vertices& vertices) {
    const Status kind = components_ok(accessor, 4, "tiếp tuyến không phải VEC4");
    if (!kind) return kind;
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    Floats raw;
    const Status status = unpack(accessor, raw, 4);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * 4;
        vertices[index].tangent = {.x = raw[base], .y = raw[base + 1], .z = raw[base + 2], .w = raw[base + 3]};
    }
    return core::ok();
}

[[nodiscard]] Status read_uvs(const Accessor* accessor, Vertices& vertices, UvField field) {
    const Status kind = components_ok(accessor, 2, "uv không phải VEC2");
    if (!kind) return kind;
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    Floats raw;
    const Status status = unpack(accessor, raw, 2);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * 2;
        vertices[index].*field = {.x = raw[base], .y = raw[base + 1]};
    }
    return core::ok();
}

[[nodiscard]] Status read_colors(const Accessor* accessor, Vertices& vertices) {
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    const std::size_t components = cgltf_num_components(accessor->type);
    if (components != 3 && components != 4) return bad("màu đỉnh lạ");
    Floats raw;
    const Status status = unpack(accessor, raw, components);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * components;
        const float alpha = components == 4 ? raw[base + 3] : 1.0F;
        vertices[index].color = {.x = raw[base], .y = raw[base + 1], .z = raw[base + 2], .w = alpha};
    }
    return core::ok();
}

[[nodiscard]] Status read_weights(const Accessor* accessor, Vertices& vertices) {
    const Status kind = components_ok(accessor, 4, "trọng số không phải VEC4");
    if (!kind) return kind;
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    Floats raw;
    const Status status = unpack(accessor, raw, 4);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * 4;
        vertices[index].weights = {.x = raw[base], .y = raw[base + 1], .z = raw[base + 2], .w = raw[base + 3]};
    }
    return core::ok();
}

[[nodiscard]] Status store_joint(float value, std::uint16_t& out) {
    // uint16 cắt 70000 ra 4464. Khớp là số nguyên 0..65535.
    const bool in_range = value >= 0.0F && value <= 65535.0F;
    if (!in_range) return bad("khớp ngoài miền");
    const auto joint = static_cast<std::uint16_t>(value);
    const bool whole = static_cast<float>(joint) == value;
    if (!whole) return bad("khớp không nguyên");
    out = joint;
    return core::ok();
}

// Khác gốc: bốn khớp viết thẳng, dừng ở khớp lỗi đầu, không if trong for.
[[nodiscard]] Status read_joint(const Floats& raw, Vertex& vertex, std::size_t index) {
    const std::size_t base = index * 4;
    const Status lane0 = store_joint(raw[base], vertex.joints[0]);
    if (!lane0) return lane0;
    const Status lane1 = store_joint(raw[base + 1], vertex.joints[1]);
    if (!lane1) return lane1;
    const Status lane2 = store_joint(raw[base + 2], vertex.joints[2]);
    if (!lane2) return lane2;
    return store_joint(raw[base + 3], vertex.joints[3]);
}

[[nodiscard]] Status read_joints(const Accessor* accessor, Vertices& vertices) {
    const Status kind = components_ok(accessor, 4, "khớp không phải VEC4");
    if (!kind) return kind;
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    Floats raw;
    const Status status = unpack(accessor, raw, 4);
    if (!status) return status;
    const auto read = [&](std::size_t index) { return read_joint(raw, vertices[index], index); };
    return each_index(vertices.size(), read);
}

[[nodiscard]] Status apply_texcoord(const Attribute& attribute, Vertices& vertices) {
    if (attribute.index == 0) return read_uvs(attribute.data, vertices, &Vertex::uv);
    if (attribute.index == 1) return read_uvs(attribute.data, vertices, &Vertex::uv1);
    return core::ok();
}

[[nodiscard]] Status apply_color(const Attribute& attribute, Vertices& vertices) {
    if (attribute.index != 0) return core::ok();
    return read_colors(attribute.data, vertices);
}

[[nodiscard]] Status apply_joints(const Attribute& attribute, Vertices& vertices) {
    if (attribute.index != 0) return core::ok();
    return read_joints(attribute.data, vertices);
}

[[nodiscard]] Status apply_weight(const Attribute& attribute, Vertices& vertices) {
    if (attribute.index != 0) return core::ok();
    return read_weights(attribute.data, vertices);
}

// Khác gốc: if trong switch đưa ra hàm, switch chỉ còn một lệnh mỗi case.
[[nodiscard]] Status apply_attribute(const Attribute& attribute, Vertices& vertices) {
    if (attribute.data == nullptr) return core::ok();
    switch (attribute.type) {
    case cgltf_attribute_type_position: return read_positions(attribute.data, vertices);
    case cgltf_attribute_type_normal: return read_normals(attribute.data, vertices);
    case cgltf_attribute_type_tangent: return read_tangents(attribute.data, vertices);
    case cgltf_attribute_type_texcoord: return apply_texcoord(attribute, vertices);
    case cgltf_attribute_type_color: return apply_color(attribute, vertices);
    case cgltf_attribute_type_joints: return apply_joints(attribute, vertices);
    case cgltf_attribute_type_weights: return apply_weight(attribute, vertices);
    case cgltf_attribute_type_invalid:
    case cgltf_attribute_type_custom:
    case cgltf_attribute_type_max_enum: return core::ok();
    }
    return core::ok();
}

[[nodiscard]] const Attribute* position_at(AttrSpan attributes, std::size_t index) noexcept {
    const Attribute& attribute = attributes[index];
    const bool kind = attribute.type == cgltf_attribute_type_position;
    const bool usable = kind && attribute.data != nullptr;
    if (!usable) return nullptr;
    return &attributes[index];
}

// glTF không bắt POSITION đứng đầu. Đọc pháp tuyến trước khi có đỉnh sẽ báo lệch số.
[[nodiscard]] const Attribute* position_attribute(const PrimitiveIn& primitive) noexcept {
    const std::span<const Attribute> attributes(primitive.attributes, primitive.attributes_count);
    const Attribute* found = nullptr;
    std::size_t index = 0;
    while (found == nullptr && index < attributes.size()) {
        found = position_at(attributes, index);
        ++index;
    }
    return found;
}

[[nodiscard]] Status apply_other(const Attribute& attribute, Vertices& vertices) {
    if (attribute.type == cgltf_attribute_type_position) return core::ok();
    return apply_attribute(attribute, vertices);
}

[[nodiscard]] Status read_attributes(const PrimitiveIn& primitive, Primitive& out) {
    const Attribute* position = position_attribute(primitive);
    if (position == nullptr) return core::fail(core::ErrorCode::kCorrupt, "lưới thiếu vị trí");
    const Status positions = read_positions(position->data, out.vertices);
    if (!positions) return positions;
    const std::span<const Attribute> attributes(primitive.attributes, primitive.attributes_count);
    const auto apply = [&](std::size_t index) { return apply_other(attributes[index], out.vertices); };
    return each_index(attributes.size(), apply);
}

// Khác gốc: byte đầu qua memcpy, không chỉ số con trỏ.
[[nodiscard]] Status read_byte(const std::uint8_t* data, std::uint32_t& out) {
    std::uint8_t byte = 0;
    std::memcpy(&byte, data, sizeof(byte));
    out = byte;
    return core::ok();
}

// Khác gốc: khối sau case r_16u thành hàm riêng.
[[nodiscard]] Status read_u16(const std::uint8_t* data, std::uint32_t& out) {
    std::uint16_t value = 0;
    std::memcpy(&value, data, sizeof(value));
    out = value;
    return core::ok();
}

[[nodiscard]] Status read_u32(const std::uint8_t* data, std::uint32_t& out) {
    std::memcpy(&out, data, sizeof(out));
    return core::ok();
}

[[nodiscard]] Status read_integer(Byte data, ComponentType type, std::uint32_t& out) {
    switch (type) {
    case cgltf_component_type_r_8u: return read_byte(data, out);
    case cgltf_component_type_r_16u: return read_u16(data, out);
    case cgltf_component_type_r_32u: return read_u32(data, out);
    case cgltf_component_type_r_8:
    case cgltf_component_type_r_16:
    case cgltf_component_type_r_32f:
    case cgltf_component_type_invalid:
    case cgltf_component_type_max_enum: return bad("chỉ số lạ");
    }
    return bad("chỉ số lạ");
}

// Không span: offset có thể là một-qua-cuối.
[[nodiscard]] Byte byte_at(Byte data, std::size_t offset) noexcept {
    if (data == nullptr || offset == 0) return data;
    const auto base = std::bit_cast<std::uintptr_t>(data);
    return std::bit_cast<Byte>(base + offset);
}

struct SparseRead {
    const Accessor* accessor = nullptr;
    const std::uint8_t* slots = nullptr;
    const std::uint8_t* values = nullptr;
    Indices* indices = nullptr;
    std::size_t limit = 0;
};

[[nodiscard]] Status overlay_one(const SparseRead& read, std::size_t index) {
    const cgltf_accessor_sparse& sparse = read.accessor->sparse;
    const std::size_t slot_stride = cgltf_component_size(sparse.indices_component_type);
    const std::uint8_t* slot_bytes = byte_at(read.slots, index * slot_stride);
    std::uint32_t slot = 0;
    const Status slot_status = read_integer(slot_bytes, sparse.indices_component_type, slot);
    if (!slot_status) return slot_status;
    if (slot >= read.indices->size()) return bad("chỉ số hỏng");
    const std::size_t value_offset = index * read.accessor->stride;
    const std::uint8_t* value_bytes = byte_at(read.values, value_offset);
    std::uint32_t value = 0;
    const Status value_status = read_integer(value_bytes, read.accessor->component_type, value);
    if (!value_status) return value_status;
    if (value >= read.limit) return bad("chỉ số ngoài miền");
    (*read.indices)[slot] = value;
    return core::ok();
}

[[nodiscard]] Status overlay_sparse(const Accessor* accessor, Indices& indices, std::size_t limit) {
    const cgltf_accessor_sparse& sparse = accessor->sparse;
    const std::uint8_t* slot_view = cgltf_buffer_view_data(sparse.indices_buffer_view);
    const std::uint8_t* value_view = cgltf_buffer_view_data(sparse.values_buffer_view);
    if (slot_view == nullptr || value_view == nullptr) return bad("chỉ số hỏng");
    const std::uint8_t* slots = byte_at(slot_view, sparse.indices_byte_offset);
    const std::uint8_t* values = byte_at(value_view, sparse.values_byte_offset);
    const SparseRead read{.accessor = accessor, .slots = slots, .values = values, .indices = &indices, .limit = limit};
    return each_index(sparse.count, [&](std::size_t index) { return overlay_one(read, index); });
}

[[nodiscard]] bool index_inside(std::uint32_t index, std::size_t limit) noexcept {
    return index < limit;
}

// Khác gốc: vòng kiểm thành all_of, dừng ở chỉ số đầu vượt miền.
[[nodiscard]] Status check_indices(const Indices& indices, std::size_t limit) {
    const auto inside = [&](std::uint32_t index) noexcept { return index_inside(index, limit); };
    if (!std::ranges::all_of(indices, inside)) return bad("chỉ số ngoài miền");
    return core::ok();
}

[[nodiscard]] Status read_dense_indices(const Accessor* accessor, Indices& indices) {
    if (accessor->buffer_view == nullptr) {
        indices.assign(accessor->count, 0);
        return core::ok();
    }
    indices.resize(accessor->count);
    std::uint32_t* destination = indices.data();
    const std::size_t room = indices.size();
    const cgltf_size written = cgltf_accessor_unpack_indices(accessor, destination, sizeof(std::uint32_t), room);
    if (written != indices.size()) return bad("chỉ số hỏng");
    return core::ok();
}

[[nodiscard]] Status one_index(Byte data, AccessorPtr accessor, Indices& out, std::size_t index) {
    const std::size_t offset = index * accessor->stride;
    const std::uint8_t* element = byte_at(data, offset);
    return read_integer(element, accessor->component_type, out[index]);
}

// unpack_indices trả 0 khi accessor sparse, kể cả khi buffer nền có dữ liệu.
[[nodiscard]] Status read_base_indices(const Accessor* accessor, Indices& indices) {
    if (accessor->buffer_view == nullptr) {
        indices.assign(accessor->count, 0);
        return core::ok();
    }
    const std::uint8_t* view = cgltf_buffer_view_data(accessor->buffer_view);
    if (view == nullptr) return bad("chỉ số hỏng");
    const std::uint8_t* data = byte_at(view, accessor->offset);
    indices.resize(accessor->count);
    const auto read = [&](std::size_t index) { return one_index(data, accessor, indices, index); };
    return each_index(indices.size(), read);
}

[[nodiscard]] Status read_indices(const Accessor* accessor, Indices& indices, std::size_t limit) {
    if (accessor == nullptr) {
        indices.clear();
        return core::ok();
    }
    // Khác gốc: cgltf_bool là int, so với 0.
    const bool is_sparse = accessor->is_sparse != 0;
    const Status base = is_sparse ? read_base_indices(accessor, indices) : read_dense_indices(accessor, indices);
    if (!base) return base;
    if (!is_sparse) return check_indices(indices, limit);
    const Status overlaid = overlay_sparse(accessor, indices, limit);
    if (!overlaid) return overlaid;
    return check_indices(indices, limit);
}

void fill_sequential(Indices& indices, std::size_t count) {
    indices.resize(count);
    for (std::size_t index = 0; index < count; ++index) {
        indices[index] = static_cast<std::uint32_t>(index);
    }
}

[[nodiscard]] Status set_indices(const PrimitiveIn& source, Primitive& primitive) {
    if (source.indices == nullptr) {
        fill_sequential(primitive.indices, primitive.vertices.size());
        return core::ok();
    }
    return read_indices(source.indices, primitive.indices, primitive.vertices.size());
}

[[nodiscard]] MaybeIndex image_index(const cgltf_texture_view& view, const Gltf& data) noexcept {
    if (view.texture == nullptr || view.texture->image == nullptr) return std::nullopt;
    return index_of(view.texture->image, data.images, sizeof(cgltf_image));
}

[[nodiscard]] MaybeIndex sampler_index(const cgltf_texture_view& view, const Gltf& data) noexcept {
    if (view.texture == nullptr || view.texture->sampler == nullptr) return std::nullopt;
    return index_of(view.texture->sampler, data.samplers, sizeof(cgltf_sampler));
}

struct MinFilter {
    Filter min = Filter::kLinear;
    Filter mip = Filter::kLinear;
    bool has_mip = true;
};

[[nodiscard]] Filter mag_of(cgltf_filter_type type) noexcept {
    switch (type) {
    case cgltf_filter_type_nearest: return Filter::kNearest;
    case cgltf_filter_type_undefined:
    case cgltf_filter_type_linear:
    case cgltf_filter_type_nearest_mipmap_nearest:
    case cgltf_filter_type_linear_mipmap_nearest:
    case cgltf_filter_type_nearest_mipmap_linear:
    case cgltf_filter_type_linear_mipmap_linear: return Filter::kLinear;
    }
    return Filter::kLinear;
}

[[nodiscard]] MinFilter min_of(cgltf_filter_type type) noexcept {
    switch (type) {
    case cgltf_filter_type_nearest: return {.min = Filter::kNearest, .mip = Filter::kNearest, .has_mip = false};
    case cgltf_filter_type_linear: return {.min = Filter::kLinear, .mip = Filter::kNearest, .has_mip = false};
    case cgltf_filter_type_nearest_mipmap_nearest:
        return {.min = Filter::kNearest, .mip = Filter::kNearest, .has_mip = true};
    case cgltf_filter_type_linear_mipmap_nearest:
        return {.min = Filter::kLinear, .mip = Filter::kNearest, .has_mip = true};
    case cgltf_filter_type_nearest_mipmap_linear:
        return {.min = Filter::kNearest, .mip = Filter::kLinear, .has_mip = true};
    case cgltf_filter_type_undefined:
    case cgltf_filter_type_linear_mipmap_linear:
        return {.min = Filter::kLinear, .mip = Filter::kLinear, .has_mip = true};
    }
    return {.min = Filter::kLinear, .mip = Filter::kLinear, .has_mip = true};
}

[[nodiscard]] Wrap wrap_of(cgltf_wrap_mode mode) noexcept {
    switch (mode) {
    case cgltf_wrap_mode_repeat: return Wrap::kRepeat;
    case cgltf_wrap_mode_mirrored_repeat: return Wrap::kMirror;
    case cgltf_wrap_mode_clamp_to_edge: return Wrap::kClamp;
    }
    return Wrap::kRepeat;
}

[[nodiscard]] Sampler read_sampler(const cgltf_sampler& source) {
    Sampler sampler;
    sampler.name = text_of(source.name);
    sampler.mag = mag_of(source.mag_filter);
    const MinFilter min = min_of(source.min_filter);
    sampler.min = min.min;
    sampler.mip = min.mip;
    sampler.has_mip = min.has_mip;
    sampler.wrap_u = wrap_of(source.wrap_s);
    sampler.wrap_v = wrap_of(source.wrap_t);
    return sampler;
}

[[nodiscard]] Alpha alpha_of(cgltf_alpha_mode mode) noexcept {
    switch (mode) {
    case cgltf_alpha_mode_opaque: return Alpha::kOpaque;
    case cgltf_alpha_mode_mask: return Alpha::kMask;
    case cgltf_alpha_mode_blend: return Alpha::kBlend;
    case cgltf_alpha_mode_max_enum: return Alpha::kOpaque;
    }
    return Alpha::kOpaque;
}

[[nodiscard]] std::uint32_t uv_of(cgltf_int value) noexcept {
    if (value < 0) return 0;
    return static_cast<std::uint32_t>(value);
}

// Khác gốc: span cố định rồi memcpy, không suy biến mảng thành con trỏ.
[[nodiscard]] math::Float3 float3_of(std::span<const float, 3> values) noexcept {
    std::array<float, 3> cell{};
    float* destination = cell.data();
    const float* source = values.data();
    std::memcpy(destination, source, sizeof(cell));
    return {.x = cell[0], .y = cell[1], .z = cell[2]};
}

// Khác gốc: span cố định rồi memcpy, không suy biến mảng thành con trỏ.
[[nodiscard]] math::Float4 float4_of(std::span<const float, 4> values) noexcept {
    std::array<float, 4> cell{};
    float* destination = cell.data();
    const float* source = values.data();
    std::memcpy(destination, source, sizeof(cell));
    return {.x = cell[0], .y = cell[1], .z = cell[2], .w = cell[3]};
}

// Scale = 1 khi có texture. View vắng thì calloc để 0.
[[nodiscard]] TexSlot read_slot(const cgltf_texture_view& view, const Gltf& data) {
    TexSlot slot;
    if (view.texture == nullptr) return slot;
    slot.image = image_index(view, data);
    slot.sampler = sampler_index(view, data);
    slot.uv = uv_of(view.texcoord);
    slot.scale = view.scale;
    if (view.has_transform == 0) return slot;
    slot.offset = {.x = view.transform.offset[0], .y = view.transform.offset[1]};
    slot.repeat = {.x = view.transform.scale[0], .y = view.transform.scale[1]};
    slot.rotation = view.transform.rotation;
    if (view.transform.has_texcoord == 0) return slot;
    slot.uv = uv_of(view.transform.texcoord);
    return slot;
}

void read_metallic(const cgltf_pbr_metallic_roughness& pbr, const Gltf& data, Material& material) {
    material.base_color = float4_of(pbr.base_color_factor);
    material.metallic = pbr.metallic_factor;
    material.roughness = pbr.roughness_factor;
    material.color = read_slot(pbr.base_color_texture, data);
    material.surface = read_slot(pbr.metallic_roughness_texture, data);
}

void read_gloss(const cgltf_pbr_specular_glossiness& source, const Gltf& data, Material& material) {
    material.shading = Shading::kSpecular;
    material.diffuse = float4_of(source.diffuse_factor);
    material.gloss_color = float3_of(source.specular_factor);
    material.glossiness = source.glossiness_factor;
    material.diffuse_map = read_slot(source.diffuse_texture, data);
    material.gloss_map = read_slot(source.specular_glossiness_texture, data);
}

[[nodiscard]] Coat read_coat(const cgltf_clearcoat& source, const Gltf& data) {
    Coat coat;
    coat.factor = source.clearcoat_factor;
    coat.roughness = source.clearcoat_roughness_factor;
    coat.strength = read_slot(source.clearcoat_texture, data);
    coat.roughness_map = read_slot(source.clearcoat_roughness_texture, data);
    coat.normal = read_slot(source.clearcoat_normal_texture, data);
    return coat;
}

[[nodiscard]] Transmit read_transmit(const cgltf_transmission& source, const Gltf& data) {
    Transmit transmit;
    transmit.factor = source.transmission_factor;
    transmit.texture = read_slot(source.transmission_texture, data);
    return transmit;
}

[[nodiscard]] Sheen read_sheen(const cgltf_sheen& source, const Gltf& data) {
    Sheen sheen;
    sheen.color = float3_of(source.sheen_color_factor);
    sheen.roughness = source.sheen_roughness_factor;
    sheen.color_map = read_slot(source.sheen_color_texture, data);
    sheen.roughness_map = read_slot(source.sheen_roughness_texture, data);
    return sheen;
}

[[nodiscard]] Specular read_specular(const cgltf_specular& source, const Gltf& data) {
    Specular specular;
    specular.color = float3_of(source.specular_color_factor);
    specular.factor = source.specular_factor;
    specular.factor_map = read_slot(source.specular_texture, data);
    specular.color_map = read_slot(source.specular_color_texture, data);
    return specular;
}

[[nodiscard]] Anisotropy read_anisotropy(const cgltf_anisotropy& source, const Gltf& data) {
    Anisotropy anisotropy;
    anisotropy.strength = source.anisotropy_strength;
    anisotropy.rotation = source.anisotropy_rotation;
    anisotropy.texture = read_slot(source.anisotropy_texture, data);
    return anisotropy;
}

[[nodiscard]] Volume read_volume(const cgltf_volume& source, const Gltf& data) {
    Volume volume;
    volume.thickness = source.thickness_factor;
    volume.attenuation = float3_of(source.attenuation_color);
    volume.distance = source.attenuation_distance;
    volume.thickness_map = read_slot(source.thickness_texture, data);
    return volume;
}

[[nodiscard]] Iridescence read_iridescence(const cgltf_iridescence& source, const Gltf& data) {
    Iridescence iridescence;
    iridescence.factor = source.iridescence_factor;
    iridescence.ior = source.iridescence_ior;
    iridescence.thickness_min = source.iridescence_thickness_min;
    iridescence.thickness_max = source.iridescence_thickness_max;
    iridescence.factor_map = read_slot(source.iridescence_texture, data);
    iridescence.thickness_map = read_slot(source.iridescence_thickness_texture, data);
    return iridescence;
}

[[nodiscard]] Scatter read_scatter(const cgltf_diffuse_transmission& source, const Gltf& data) {
    Scatter scatter;
    scatter.factor = source.diffuse_transmission_factor;
    scatter.color = float3_of(source.diffuse_transmission_color_factor);
    scatter.factor_map = read_slot(source.diffuse_transmission_texture, data);
    scatter.color_map = read_slot(source.diffuse_transmission_color_texture, data);
    return scatter;
}

void take_gloss(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_pbr_specular_glossiness == 0) return;
    read_gloss(source.pbr_specular_glossiness, data, material);
}

void take_coat(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_clearcoat == 0) return;
    material.coat = read_coat(source.clearcoat, data);
}

void take_transmit(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_transmission == 0) return;
    material.transmission = read_transmit(source.transmission, data);
}

void take_sheen(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_sheen == 0) return;
    material.sheen = read_sheen(source.sheen, data);
}

void take_specular(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_specular == 0) return;
    material.specular = read_specular(source.specular, data);
}

void take_anisotropy(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_anisotropy == 0) return;
    material.anisotropy = read_anisotropy(source.anisotropy, data);
}

void take_volume(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_volume == 0) return;
    material.volume = read_volume(source.volume, data);
}

void take_iridescence(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_iridescence == 0) return;
    material.iridescence = read_iridescence(source.iridescence, data);
}

void take_scatter(const cgltf_material& source, const Gltf& data, Material& material) {
    if (source.has_diffuse_transmission == 0) return;
    material.scatter = read_scatter(source.diffuse_transmission, data);
}

void take_scalars(const cgltf_material& source, Material& material) {
    if (source.has_ior != 0) material.ior = source.ior.ior;
    if (source.has_dispersion != 0) material.dispersion = source.dispersion.dispersion;
    if (source.has_emissive_strength != 0) {
        material.emissive_strength = source.emissive_strength.emissive_strength;
    }
}

// Khác gốc: chuỗi if tách hàm để cognitive không vượt 10. Thứ tự gán giữ nguyên.
void read_extensions(const cgltf_material& source, const Gltf& data, Material& material) {
    take_gloss(source, data, material);
    take_coat(source, data, material);
    take_transmit(source, data, material);
    take_sheen(source, data, material);
    take_specular(source, data, material);
    take_anisotropy(source, data, material);
    take_volume(source, data, material);
    take_iridescence(source, data, material);
    take_scatter(source, data, material);
    take_scalars(source, material);
}

[[nodiscard]] Material read_material(const cgltf_material& source, const Gltf& data) {
    Material material;
    material.name = text_of(source.name);
    material.double_sided = source.double_sided != 0;
    material.unlit = source.unlit != 0;
    material.alpha = alpha_of(source.alpha_mode);
    material.alpha_cutoff = source.alpha_cutoff;
    material.emissive = float3_of(source.emissive_factor);
    material.normal = read_slot(source.normal_texture, data);
    material.occlusion = read_slot(source.occlusion_texture, data);
    material.emissive_map = read_slot(source.emissive_texture, data);
    if (source.has_pbr_metallic_roughness != 0) {
        read_metallic(source.pbr_metallic_roughness, data, material);
    }
    read_extensions(source, data, material);
    if (source.extras.data != nullptr) material.extras = source.extras.data;
    return material;
}

[[nodiscard]] ImageResult finish_image(const cgltf_image& source, Encoded encoded) {
    auto image = read_stored(encoded);
    if (!image) return failure_of(image);
    image->name = text_of(source.name);
    return image;
}

[[nodiscard]] core::Result<Image> image_from_view(const cgltf_image& source) {
    const bool missing = source.buffer_view == nullptr || source.buffer_view->buffer == nullptr;
    if (missing) return bad("ảnh không có dữ liệu");
    const cgltf_buffer_view& view = *source.buffer_view;
    const cgltf_buffer& buffer = *view.buffer;
    if (buffer.data == nullptr) return bad("ảnh chưa có byte");
    const bool offset_ok = view.offset <= buffer.size;
    const bool fits = offset_ok && view.size <= buffer.size - view.offset;
    if (!fits) return bad("ảnh vượt buffer");
    const auto* bytes = static_cast<const std::byte*>(buffer.data);
    const std::span<const std::byte> whole(bytes, buffer.size);
    const std::span<const std::byte> encoded = whole.subspan(view.offset, view.size);
    return finish_image(source, encoded);
}

// Khác gốc: if ở push_kept, ngoài for.
void push_kept(std::string& out, char character) {
    const bool space = character == ' ' || character == '\t';
    const bool line = character == '\n' || character == '\r';
    const bool is_blank = space || line;
    if (is_blank) return;
    out.push_back(character);
}

[[nodiscard]] std::string strip_ws(std::string_view text) {
    std::string out;
    out.reserve(text.size());
    for (const char character : text) {
        push_kept(out, character);
    }
    return out;
}

[[nodiscard]] core::Result<std::size_t> base64_size(std::string_view payload) {
    if (payload.size() % 4 != 0) return bad("base64 lệch");
    std::size_t pad = 0;
    const bool one_pad = !payload.empty() && payload.back() == '=';
    if (one_pad) pad = 1;
    const bool two_pad = payload.size() >= 2 && payload[payload.size() - 2] == '=';
    if (two_pad) pad = 2;
    const std::size_t groups = payload.size() / 4;
    return (groups * 3) - pad;
}

// Khác gốc: strchr và strncmp thành find, so bảy ký tự ";base64".
[[nodiscard]] std::optional<std::size_t> base64_comma(const char* uri) noexcept {
    const std::string_view text(uri);
    const std::size_t comma = text.find(',');
    if (comma == std::string_view::npos) return std::nullopt;
    if (comma < 7) return std::nullopt;
    const std::string_view mark = text.substr(comma - 7, 7);
    if (mark != ";base64") return std::nullopt;
    return comma;
}

[[nodiscard]] core::Result<Image> image_from_data(const cgltf_image& source) {
    const std::optional<std::size_t> comma = base64_comma(source.uri);
    if (!comma) return bad("ảnh data-URI không phải base64");
    const std::string_view text(source.uri);
    const std::string_view tail = text.substr(*comma + 1);
    const std::string payload = strip_ws(tail);
    const auto size = base64_size(payload);
    if (!size) return failure_of(size);
    if (*size == 0) return bad("ảnh data-URI rỗng");
    const cgltf_options options{};
    void* raw = nullptr;
    const char* payload_chars = payload.c_str();
    const cgltf_result code = cgltf_load_buffer_base64(&options, *size, payload_chars, &raw);
    const bool failed = code != cgltf_result_success || raw == nullptr;
    if (failed) return bad("base64 của ảnh hỏng");
    const HeapPtr held(raw);
    const auto* bytes = static_cast<const std::byte*>(held.get());
    const std::span<const std::byte> encoded(bytes, *size);
    return finish_image(source, encoded);
}

[[nodiscard]] bool is_inside(std::string_view path, std::string_view root) noexcept {
    if (path == root) return true;
    if (!path.starts_with(root)) return false;
    if (root.ends_with('/')) return true;
    return path.size() > root.size() && path[root.size()] == '/';
}

// "." là thư mục hiện tại. join đã giải "..", nên đường còn "../" là thoát khỏi cwd.
[[nodiscard]] bool stays_inside(std::string_view path, std::string_view root) noexcept {
    if (root != ".") return is_inside(path, root);
    if (path == "..") return false;
    return !path.starts_with("../");
}

[[nodiscard]] ImageResult image_from_file(const cgltf_image& source, const ImageScope& scope) {
    auto path = image_path(source.uri, scope);
    if (!path) return failure_of(path);
    const std::string sibling = dds_sibling(*path);
    const bool use_dds = !sibling.empty() && fs::is_file(sibling);
    std::string chosen = use_dds ? sibling : *path;
    if (scope.tier != TextureTier::kBc && !scope.root.empty()) {
        const std::string root = fs::normalize(scope.root);
        const std::string full = fs::normalize(chosen);
        const bool inside = full.starts_with(root) && full.size() > root.size() && full[root.size()] == '/';
        if (inside) chosen = texture_file(root, full.substr(root.size() + 1), scope.tier);
    }
    auto bytes = read_bytes(chosen);
    if (!bytes) return failure_of(bytes);
    const std::span<const std::byte> encoded = bytes->span();
    return finish_image(source, encoded);
}

[[nodiscard]] bool is_data_uri(const char* uri) noexcept {
    if (uri == nullptr) return false;
    return std::strncmp(uri, "data:", 5) == 0;
}

[[nodiscard]] char lower_ascii(char value) noexcept {
    if (value < 'A' || value > 'Z') return value;
    return static_cast<char>(value - 'A' + 'a');
}

// Khác gốc: for có if thành while, so tới ký tự lệch đầu tiên.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tail rồi suffix (API-03)
[[nodiscard]] bool tail_matches(std::string_view tail, std::string_view suffix) noexcept {
    std::size_t index = 0;
    bool same = true;
    while (same && index < suffix.size()) {
        const char left = lower_ascii(tail[index]);
        const char right = lower_ascii(suffix[index]);
        same = left == right;
        ++index;
    }
    return same;
}

[[nodiscard]] bool ends_with_ci(std::string_view text, std::string_view suffix) noexcept {
    if (text.size() < suffix.size()) return false;
    const std::string_view tail = text.substr(text.size() - suffix.size());
    return tail_matches(tail, suffix);
}

[[nodiscard]] std::string_view uri_path(std::string_view uri) noexcept {
    const std::size_t cut = uri.find_first_of("?#");
    if (cut == std::string_view::npos) return uri;
    return uri.substr(0, cut);
}

// Khớp mime và hậu tố. "notes_basis.png" không phải ảnh Basis.
[[nodiscard]] bool is_gpu_mime(std::string_view mime) noexcept {
    return mime == "image/ktx2" || mime == "image/ktx" || mime == "image/basis";
}

[[nodiscard]] bool is_gpu_uri(std::string_view uri) noexcept {
    const std::string_view path = uri_path(uri);
    if (ends_with_ci(path, ".ktx2")) return true;
    if (ends_with_ci(path, ".ktx")) return true;
    return ends_with_ci(path, ".basis");
}

[[nodiscard]] core::Result<Image> read_image(const cgltf_image& source, const ImageScope& scope) {
    if (source.mime_type != nullptr && is_gpu_mime(source.mime_type)) {
        return unsupported("ảnh KTX hoặc Basis");
    }
    if (source.uri != nullptr && is_gpu_uri(source.uri)) return unsupported("ảnh KTX hoặc Basis");
    if (source.buffer_view != nullptr) return image_from_view(source);
    if (is_data_uri(source.uri)) return image_from_data(source);
    if (source.uri != nullptr) return image_from_file(source, scope);
    return bad("ảnh không có dữ liệu");
}

[[nodiscard]] Camera perspective_camera(Camera camera, const cgltf_camera_perspective& source) {
    camera.kind = CameraKind::kPerspective;
    if (source.has_aspect_ratio != 0) camera.perspective.aspect = source.aspect_ratio;
    camera.perspective.yfov = source.yfov;
    if (source.has_zfar != 0) camera.perspective.zfar = source.zfar;
    camera.perspective.znear = source.znear;
    return camera;
}

[[nodiscard]] Camera ortho_camera(Camera camera, const cgltf_camera_orthographic& source) {
    camera.kind = CameraKind::kOrthographic;
    camera.orthographic.xmag = source.xmag;
    camera.orthographic.ymag = source.ymag;
    camera.orthographic.zfar = source.zfar;
    camera.orthographic.znear = source.znear;
    return camera;
}

[[nodiscard]] const cgltf_camera_perspective& perspective_of(const cgltf_camera& source) noexcept {
    // Đúng nhánh (UB-03).
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-union-access)
    const cgltf_camera_perspective& perspective = source.data.perspective;
    return perspective;
}

[[nodiscard]] const CameraOrtho& orthographic_of(const cgltf_camera& source) noexcept {
    // Đúng nhánh (UB-03).
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-union-access)
    const CameraOrtho& orthographic = source.data.orthographic;
    return orthographic;
}

[[nodiscard]] core::Result<Camera> read_camera(const cgltf_camera& source) {
    Camera camera;
    camera.name = text_of(source.name);
    switch (source.type) {
    case cgltf_camera_type_perspective: return perspective_camera(camera, perspective_of(source));
    case cgltf_camera_type_orthographic: return ortho_camera(camera, orthographic_of(source));
    case cgltf_camera_type_invalid:
    case cgltf_camera_type_max_enum: return bad("camera thiếu kiểu");
    }
    return bad("camera thiếu kiểu");
}

[[nodiscard]] LightKind light_kind(cgltf_light_type type) noexcept {
    switch (type) {
    case cgltf_light_type_directional: return LightKind::kDirectional;
    case cgltf_light_type_point: return LightKind::kPoint;
    case cgltf_light_type_spot: return LightKind::kSpot;
    case cgltf_light_type_invalid:
    case cgltf_light_type_max_enum: return LightKind::kDirectional;
    }
    return LightKind::kDirectional;
}

[[nodiscard]] core::Result<Light> read_light(const cgltf_light& source) {
    const bool missing = source.type == cgltf_light_type_invalid || source.type == cgltf_light_type_max_enum;
    if (missing) return bad("đèn thiếu kiểu");
    Light light;
    light.name = text_of(source.name);
    light.color = float3_of(source.color);
    light.intensity = source.intensity;
    light.kind = light_kind(source.type);
    light.range = source.range;
    light.inner_cone = source.spot_inner_cone_angle;
    light.outer_cone = source.spot_outer_cone_angle;
    return light;
}

void push_child(Node& node, const cgltf_node& source, const Gltf& data, std::size_t index) {
    const std::span<cgltf_node*> children(source.children, source.children_count);
    const std::uint32_t child = index_of(children[index], data.nodes, sizeof(cgltf_node));
    node.children.push_back(child);
}

// Tịnh tiến, xoay, tỉ lệ đúng như tệp khai; thành phần vắng là mặc định của glTF.
[[nodiscard]] NodeParts parts_of(const cgltf_node& source) noexcept {
    NodeParts parts;
    if (source.has_translation != 0) parts.translation = float3_of(source.translation);
    if (source.has_rotation != 0) parts.rotation = float4_of(source.rotation);
    if (source.has_scale != 0) parts.scale = float3_of(source.scale);
    return parts;
}

[[nodiscard]] Node read_node(const cgltf_node& source, const Gltf& data) {
    Node node;
    node.name = text_of(source.name);
    std::array<cgltf_float, 16> local{};
    cgltf_float* cells = local.data();
    cgltf_node_transform_local(&source, cells);
    node.local = matrix_from(cells);
    if (source.has_matrix == 0) node.parts = parts_of(source);
    if (source.mesh != nullptr) node.mesh = index_of(source.mesh, data.meshes, sizeof(cgltf_mesh));
    if (source.skin != nullptr) node.skin = index_of(source.skin, data.skins, sizeof(cgltf_skin));
    if (source.camera != nullptr) {
        node.camera = index_of(source.camera, data.cameras, sizeof(cgltf_camera));
    }
    if (source.light != nullptr) node.light = index_of(source.light, data.lights, sizeof(cgltf_light));
    node.children.reserve(source.children_count);
    for (std::size_t index = 0; index < source.children_count; ++index) {
        push_child(node, source, data, index);
    }
    copy_floats(source.weights, source.weights_count, node.weights);
    return node;
}

void push_joint(Skin& skin, const cgltf_skin& source, const Gltf& data, std::size_t index) {
    const std::span<cgltf_node*> joints(source.joints, source.joints_count);
    const std::uint32_t joint = index_of(joints[index], data.nodes, sizeof(cgltf_node));
    skin.joints.push_back(joint);
}

void store_bind(Skin& skin, const Floats& raw, std::size_t index) {
    const float* values = raw.data();
    const std::span<const float> all(values, raw.size());
    const std::span<const float> cells = all.subspan(index * 16, 16);
    const float* cell = cells.data();
    skin.inverse_bind[index] = matrix_from(cell);
}

[[nodiscard]] Status read_inverse_bind(const cgltf_skin& source, Skin& skin) {
    if (source.inverse_bind_matrices == nullptr) return core::ok();
    if (source.inverse_bind_matrices->count != source.joints_count) return bad("xương lệch ma trận");
    const Status kind = components_ok(source.inverse_bind_matrices, 16, "xương không phải MAT4");
    if (!kind) return kind;
    Floats raw;
    const Status status = unpack(source.inverse_bind_matrices, raw, 16);
    if (!status) return status;
    skin.inverse_bind.resize(source.inverse_bind_matrices->count);
    for (std::size_t index = 0; index < skin.inverse_bind.size(); ++index) {
        store_bind(skin, raw, index);
    }
    return core::ok();
}

[[nodiscard]] Status read_skin(const cgltf_skin& source, const Gltf& data, Skin& skin) {
    skin.name = text_of(source.name);
    if (source.skeleton != nullptr) {
        skin.skeleton = index_of(source.skeleton, data.nodes, sizeof(cgltf_node));
    }
    skin.joints.reserve(source.joints_count);
    for (std::size_t index = 0; index < source.joints_count; ++index) {
        push_joint(skin, source, data, index);
    }
    return read_inverse_bind(source, skin);
}

[[nodiscard]] TrackKind kind_of(cgltf_animation_path_type path) noexcept {
    switch (path) {
    case cgltf_animation_path_type_translation: return TrackKind::kTranslation;
    case cgltf_animation_path_type_rotation: return TrackKind::kRotation;
    case cgltf_animation_path_type_scale: return TrackKind::kScale;
    case cgltf_animation_path_type_weights: return TrackKind::kWeights;
    case cgltf_animation_path_type_invalid:
    case cgltf_animation_path_type_max_enum: return TrackKind::kTranslation;
    }
    return TrackKind::kTranslation;
}

[[nodiscard]] Interpolation interpolation_of(cgltf_interpolation_type type) noexcept {
    switch (type) {
    case cgltf_interpolation_type_step: return Interpolation::kStep;
    case cgltf_interpolation_type_linear: return Interpolation::kLinear;
    case cgltf_interpolation_type_cubic_spline: return Interpolation::kCubic;
    case cgltf_interpolation_type_max_enum: return Interpolation::kLinear;
    }
    return Interpolation::kLinear;
}

[[nodiscard]] std::size_t width_of(TrackKind kind) noexcept {
    switch (kind) {
    case TrackKind::kTranslation:
    case TrackKind::kScale: return 3;
    case TrackKind::kRotation: return 4;
    case TrackKind::kWeights: return 1;
    }
    return 0;
}

[[nodiscard]] bool is_animated(const Channel& channel) noexcept {
    // Không nút hoặc path lạ thì bỏ kênh, không từ chối tệp.
    const bool known = channel.target_path != cgltf_animation_path_type_invalid &&
        channel.target_path != cgltf_animation_path_type_max_enum;
    return known && channel.target_node != nullptr;
}

[[nodiscard]] bool sampler_whole(const cgltf_animation_sampler* sampler) noexcept {
    const bool present = sampler != nullptr;
    const bool has_input = present && sampler->input != nullptr;
    return has_input && sampler->output != nullptr;
}

// validate không so kiểu: xoay VEC3 vẫn lọt, Track sẽ đọc lệch.
[[nodiscard]] Status read_track(const Channel& channel, const Gltf& data, Track& track) {
    const cgltf_animation_sampler* sampler = channel.sampler;
    if (!sampler_whole(sampler)) return bad("kênh hoạt hình thiếu sampler");
    track.node = index_of(channel.target_node, data.nodes, sizeof(cgltf_node));
    track.kind = kind_of(channel.target_path);
    track.interpolation = interpolation_of(sampler->interpolation);
    if (cgltf_num_components(sampler->input->type) != 1) return bad("thời điểm không phải SCALAR");
    const std::size_t components = cgltf_num_components(sampler->output->type);
    if (components != width_of(track.kind)) return bad("kênh hoạt hình sai kiểu");
    const Status times = unpack(sampler->input, track.times, 1);
    if (!times) return times;
    return unpack(sampler->output, track.values, components);
}

[[nodiscard]] Topology topology_of(cgltf_primitive_type type) noexcept {
    switch (type) {
    case cgltf_primitive_type_points: return Topology::kPoints;
    case cgltf_primitive_type_lines: return Topology::kLines;
    case cgltf_primitive_type_line_loop: return Topology::kLineLoop;
    case cgltf_primitive_type_line_strip: return Topology::kLineStrip;
    case cgltf_primitive_type_triangles: return Topology::kTriangles;
    case cgltf_primitive_type_triangle_strip: return Topology::kTriangleStrip;
    case cgltf_primitive_type_triangle_fan: return Topology::kTriangleFan;
    case cgltf_primitive_type_invalid:
    case cgltf_primitive_type_max_enum: return Topology::kTriangles;
    }
    return Topology::kTriangles;
}

[[nodiscard]] Status read_morph3(const Accessor* accessor, Morphs& vertices, MorphField field) {
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    if (cgltf_num_components(accessor->type) != 3) return bad("morph không phải VEC3");
    Floats raw;
    const Status status = unpack(accessor, raw, 3);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * 3;
        vertices[index].*field = {.x = raw[base], .y = raw[base + 1], .z = raw[base + 2]};
    }
    return core::ok();
}

[[nodiscard]] Status read_morph_uv(const Accessor* accessor, Morphs& vertices, MorphUvField field) {
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    if (cgltf_num_components(accessor->type) != 2) return bad("uv morph không phải VEC2");
    Floats raw;
    const Status status = unpack(accessor, raw, 2);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * 2;
        vertices[index].*field = {.x = raw[base], .y = raw[base + 1]};
    }
    return core::ok();
}

[[nodiscard]] Status read_morph_color(const Accessor* accessor, Morphs& vertices) {
    if (accessor->count != vertices.size()) return bad("số đỉnh lệch");
    const std::size_t components = cgltf_num_components(accessor->type);
    if (components != 3 && components != 4) return bad("màu morph lạ");
    Floats raw;
    const Status status = unpack(accessor, raw, components);
    if (!status) return status;
    for (std::size_t index = 0; index < vertices.size(); ++index) {
        const std::size_t base = index * components;
        const float alpha = components == 4 ? raw[base + 3] : 1.0F;
        vertices[index].color = {.x = raw[base], .y = raw[base + 1], .z = raw[base + 2], .w = alpha};
    }
    return core::ok();
}

[[nodiscard]] Status morph_texcoord(const Attribute& attribute, Morphs& vertices) {
    if (attribute.index == 0) return read_morph_uv(attribute.data, vertices, &MorphVertex::uv);
    if (attribute.index == 1) return read_morph_uv(attribute.data, vertices, &MorphVertex::uv1);
    return core::ok();
}

[[nodiscard]] Status apply_morph_color(const Attribute& attribute, Morphs& vertices) {
    if (attribute.index != 0) return core::ok();
    return read_morph_color(attribute.data, vertices);
}

[[nodiscard]] Status apply_morph(const Attribute& attribute, Morphs& vertices) {
    if (attribute.data == nullptr) return core::ok();
    switch (attribute.type) {
    case cgltf_attribute_type_position: return read_morph3(attribute.data, vertices, &MorphVertex::position);
    case cgltf_attribute_type_normal: return read_morph3(attribute.data, vertices, &MorphVertex::normal);
    case cgltf_attribute_type_tangent: return read_morph3(attribute.data, vertices, &MorphVertex::tangent);
    case cgltf_attribute_type_texcoord: return morph_texcoord(attribute, vertices);
    case cgltf_attribute_type_color: return apply_morph_color(attribute, vertices);
    case cgltf_attribute_type_joints:
    case cgltf_attribute_type_weights:
    case cgltf_attribute_type_invalid:
    case cgltf_attribute_type_custom:
    case cgltf_attribute_type_max_enum: return core::ok();
    }
    return core::ok();
}

void note_morph(const Attribute& attribute, MorphTarget& target) {
    if (attribute.data == nullptr) return;
    const bool is_uv = attribute.type == cgltf_attribute_type_texcoord && attribute.index == 0;
    const bool is_uv1 = attribute.type == cgltf_attribute_type_texcoord && attribute.index == 1;
    const bool is_color = attribute.type == cgltf_attribute_type_color && attribute.index == 0;
    if (is_uv) target.has_uv = true;
    if (is_uv1) target.has_uv1 = true;
    if (is_color) target.has_color = true;
}

[[nodiscard]] Status read_one_morph(MorphSrc source, MorphTarget& target, std::size_t index) {
    const std::span<const Attribute> attributes(source.attributes, source.attributes_count);
    note_morph(attributes[index], target);
    return apply_morph(attributes[index], target.vertices);
}

[[nodiscard]] Status read_target(MorphSrc source, std::size_t count, MorphTarget& target) {
    target.vertices.resize(count);
    const auto read = [&](std::size_t index) { return read_one_morph(source, target, index); };
    return each_index(source.attributes_count, read);
}

[[nodiscard]] Status read_one_target(PrimIn source, Primitive& primitive, std::size_t index) {
    const std::span<const cgltf_morph_target> targets(source.targets, source.targets_count);
    const std::size_t count = primitive.vertices.size();
    return read_target(targets[index], count, primitive.targets[index]);
}

[[nodiscard]] Status read_targets(const PrimitiveIn& source, Primitive& primitive) {
    primitive.targets.resize(source.targets_count);
    const auto read = [&](std::size_t index) { return read_one_target(source, primitive, index); };
    return each_index(source.targets_count, read);
}

[[nodiscard]] Status read_one_mapping(MapSrc mapping, const Gltf& data, Primitive& primitive) {
    if (mapping.material == nullptr) return bad("biến thể thiếu chất liệu");
    VariantUse use;
    use.variant = static_cast<std::uint32_t>(mapping.variant);
    use.material = index_of(mapping.material, data.materials, sizeof(cgltf_material));
    primitive.variants.push_back(use);
    return core::ok();
}

[[nodiscard]] Status read_mappings(PrimIn source, const Gltf& data, Primitive& primitive) {
    primitive.variants.reserve(source.mappings_count);
    const std::span<const cgltf_material_mapping> mappings(source.mappings, source.mappings_count);
    const auto read = [&](std::size_t index) { return read_one_mapping(mappings[index], data, primitive); };
    return each_index(mappings.size(), read);
}

[[nodiscard]] Status read_primitive(PrimIn source, const Gltf& data, Primitive& primitive) {
    if (source.has_draco_mesh_compression != 0) return unsupported("lưới nén Draco");
    const Status attributes = read_attributes(source, primitive);
    if (!attributes) return attributes;
    const Status indices = set_indices(source, primitive);
    if (!indices) return indices;
    primitive.topology = topology_of(source.type);
    const Status targets = read_targets(source, primitive);
    if (!targets) return targets;
    const Status mappings = read_mappings(source, data, primitive);
    if (!mappings) return mappings;
    if (source.material == nullptr) return core::ok();
    primitive.material = index_of(source.material, data.materials, sizeof(cgltf_material));
    return core::ok();
}

// Khác gốc: if trong for thành câu bảo vệ của name_one.
void name_one(const cgltf_mesh& source, MorphTarget& target, std::size_t index) {
    if (index >= source.target_names_count) return;
    // Khác gốc: span thay target_names[index].
    const std::span<char*> names(source.target_names, source.target_names_count);
    const char* name = names[index];
    target.name = text_of(name);
}

void name_targets(const cgltf_mesh& source, Primitive& primitive) {
    for (std::size_t index = 0; index < primitive.targets.size(); ++index) {
        name_one(source, primitive.targets[index], index);
    }
}

[[nodiscard]] Status check_target_count(const Primitive& primitive, std::size_t count) {
    if (primitive.targets.size() != count) return bad("số morph lệch");
    return core::ok();
}

[[nodiscard]] Status check_empty_mesh(const Mesh& mesh) {
    if (mesh.weights.empty()) return core::ok();
    return bad("trọng số không có morph");
}

[[nodiscard]] Status check_targets(const Mesh& mesh) {
    if (mesh.primitives.empty()) return check_empty_mesh(mesh);
    const std::size_t count = mesh.primitives.front().targets.size();
    const auto check = [&](const Primitive& primitive) { return check_target_count(primitive, count); };
    const Status status = each_item(mesh.primitives, check);
    if (!status) return status;
    if (mesh.weights.empty()) return core::ok();
    if (mesh.weights.size() != count) return bad("trọng số morph lệch");
    return core::ok();
}

[[nodiscard]] Status read_one_primitive(MeshSrc source, GltfRef data, Mesh& out, std::size_t slot) {
    const std::span<const PrimitiveIn> primitives(source.primitives, source.primitives_count);
    return read_primitive(primitives[slot], data, out.primitives[slot]);
}

[[nodiscard]] Status read_mesh(const cgltf_mesh& source, const Gltf& data, Mesh& mesh) {
    mesh.name = text_of(source.name);
    mesh.primitives.resize(source.primitives_count);
    const auto read = [&](std::size_t index) { return read_one_primitive(source, data, mesh, index); };
    const Status status = each_index(source.primitives_count, read);
    if (!status) return status;
    copy_floats(source.weights, source.weights_count, mesh.weights);
    for (Primitive& primitive : mesh.primitives) {
        name_targets(source, primitive);
    }
    return check_targets(mesh);
}

[[nodiscard]] Status append_channel(const Channel& channel, const Gltf& data, Clip& clip) {
    if (!is_animated(channel)) return core::ok();
    Track& track = clip.tracks.emplace_back();
    return read_track(channel, data, track);
}

[[nodiscard]] Status read_clip(const cgltf_animation& animation, const Gltf& data, Clip& clip) {
    clip.name = text_of(animation.name);
    clip.tracks.reserve(animation.channels_count);
    const std::span<const Channel> channels(animation.channels, animation.channels_count);
    const auto append = [&](std::size_t index) { return append_channel(channels[index], data, clip); };
    return each_index(channels.size(), append);
}

void push_scene_root(const Gltf& data, Model& model, std::size_t index) {
    const std::span<cgltf_node*> nodes(data.scene->nodes, data.scene->nodes_count);
    const std::uint32_t node = index_of(nodes[index], data.nodes, sizeof(cgltf_node));
    model.roots.push_back(node);
}

void add_scene_roots(const Gltf& data, Model& model) {
    model.roots.reserve(data.scene->nodes_count);
    for (std::size_t index = 0; index < data.scene->nodes_count; ++index) {
        push_scene_root(data, model, index);
    }
}

// Khác gốc: if trong for thành câu bảo vệ của push_orphan.
void push_orphan(const cgltf_node& node, Model& model, std::size_t index) {
    if (node.parent != nullptr) return;
    model.roots.push_back(static_cast<std::uint32_t>(index));
}

void add_orphan_roots(const Gltf& data, Model& model) {
    const std::span<const cgltf_node> nodes(data.nodes, data.nodes_count);
    for (std::size_t index = 0; index < nodes.size(); ++index) {
        push_orphan(nodes[index], model, index);
    }
}

// Khác gốc: gọi void rồi return.
void read_roots(const Gltf& data, Model& model) {
    if (data.scene == nullptr) {
        add_orphan_roots(data, model);
        return;
    }
    add_scene_roots(data, model);
}

[[nodiscard]] Status check_node_weights(const Node& node, const Mesh& mesh) {
    if (mesh.primitives.empty()) return bad("trọng số không có morph");
    if (node.weights.size() != mesh.primitives.front().targets.size()) return bad("trọng số nút lệch");
    return core::ok();
}

// Khác gốc: bốn làn viết thẳng, trọng số 0 bỏ qua khớp, dừng ở khớp lỗi đầu.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): weight rồi joint (API-03)
[[nodiscard]] Status check_weight(float weight, std::uint16_t joint, std::size_t joint_count) {
    if (weight == 0.0F) return core::ok();
    if (joint >= joint_count) return bad("khớp ngoài xương");
    return core::ok();
}

[[nodiscard]] Status check_influence(const Vertex& vertex, std::size_t joint_count) {
    const Status lane0 = check_weight(vertex.weights[0], vertex.joints[0], joint_count);
    if (!lane0) return lane0;
    const Status lane1 = check_weight(vertex.weights[1], vertex.joints[1], joint_count);
    if (!lane1) return lane1;
    const Status lane2 = check_weight(vertex.weights[2], vertex.joints[2], joint_count);
    if (!lane2) return lane2;
    return check_weight(vertex.weights[3], vertex.joints[3], joint_count);
}

[[nodiscard]] Status check_primitive_skin(const Primitive& primitive, std::size_t joint_count) {
    const auto check = [&](const Vertex& vertex) { return check_influence(vertex, joint_count); };
    return each_item(primitive.vertices, check);
}

[[nodiscard]] Status check_mesh_skin(const Mesh& mesh, std::size_t joint_count) {
    const auto check = [&](const Primitive& primitive) { return check_primitive_skin(primitive, joint_count); };
    return each_item(mesh.primitives, check);
}

[[nodiscard]] Status check_bound_skin(const Node& node, const Model& model) {
    if (!node.mesh.has_value() || !node.skin.has_value()) return core::ok();
    if (*node.mesh >= model.meshes.size()) return bad("nút trỏ lưới ngoài");
    if (*node.skin >= model.skins.size()) return bad("nút trỏ xương ngoài");
    const std::size_t joint_count = model.skins[*node.skin].joints.size();
    return check_mesh_skin(model.meshes[*node.mesh], joint_count);
}

[[nodiscard]] Status check_node_weights_if_any(const Node& node, const Model& model) {
    if (node.weights.empty()) return core::ok();
    if (!node.mesh.has_value()) return bad("nút có trọng số mà không có lưới");
    if (*node.mesh >= model.meshes.size()) return bad("nút trỏ lưới ngoài");
    return check_node_weights(node, model.meshes[*node.mesh]);
}

[[nodiscard]] Status check_node(const Node& node, const Model& model) {
    const Status weights = check_node_weights_if_any(node, model);
    if (!weights) return weights;
    return check_bound_skin(node, model);
}

[[nodiscard]] Status check_nodes(const Model& model) {
    return each_item(model.nodes, [&](const Node& node) { return check_node(node, model); });
}

[[nodiscard]] Status read_all_meshes(const Gltf& data, Model& model) {
    model.meshes.resize(data.meshes_count);
    const std::span<const cgltf_mesh> meshes(data.meshes, data.meshes_count);
    const auto read = [&](std::size_t index) { return read_mesh(meshes[index], data, model.meshes[index]); };
    return each_index(meshes.size(), read);
}

[[nodiscard]] Status push_image(const cgltf_image& source, const ImageScope& scope, Model& model) {
    auto image = read_image(source, scope);
    if (!image) return failure_of(image);
    Image taken = std::move(*image);
    append_moved(model.images, taken);
    return core::ok();
}

[[nodiscard]] Status read_all_images(const Gltf& data, const ImageScope& scope, Model& model) {
    model.images.reserve(data.images_count);
    const std::span<const cgltf_image> images(data.images, data.images_count);
    const auto push = [&](std::size_t index) { return push_image(images[index], scope, model); };
    return each_index(images.size(), push);
}

void read_all_samplers(const Gltf& data, Model& model) {
    model.samplers.resize(data.samplers_count);
    const std::span<const cgltf_sampler> samplers(data.samplers, data.samplers_count);
    for (std::size_t index = 0; index < samplers.size(); ++index) {
        model.samplers[index] = read_sampler(samplers[index]);
    }
}

void read_all_materials(const Gltf& data, Model& model) {
    model.materials.reserve(data.materials_count);
    const std::span<const cgltf_material> materials(data.materials, data.materials_count);
    for (const cgltf_material& source : materials) {
        Material material = read_material(source, data);
        append_moved(model.materials, material);
    }
}

[[nodiscard]] Status push_camera(const cgltf_camera& source, Model& model) {
    auto camera = read_camera(source);
    if (!camera) return failure_of(camera);
    Camera taken = std::move(*camera);
    append_moved(model.cameras, taken);
    return core::ok();
}

[[nodiscard]] Status read_all_cameras(const Gltf& data, Model& model) {
    model.cameras.reserve(data.cameras_count);
    const std::span<const cgltf_camera> cameras(data.cameras, data.cameras_count);
    const auto push = [&](std::size_t index) { return push_camera(cameras[index], model); };
    return each_index(cameras.size(), push);
}

[[nodiscard]] Status push_light(const cgltf_light& source, Model& model) {
    auto light = read_light(source);
    if (!light) return failure_of(light);
    Light taken = std::move(*light);
    append_moved(model.lights, taken);
    return core::ok();
}

[[nodiscard]] Status read_all_lights(const Gltf& data, Model& model) {
    model.lights.reserve(data.lights_count);
    const std::span<const cgltf_light> lights(data.lights, data.lights_count);
    const auto push = [&](std::size_t index) { return push_light(lights[index], model); };
    return each_index(lights.size(), push);
}

void push_variant(Model& model, const cgltf_material_variant& source) {
    const std::size_t count = model.variants.size();
    model.variants.resize(count + 1);
    model.variants.back().name = text_of(source.name);
}

void read_all_variants(const Gltf& data, Model& model) {
    model.variants.reserve(data.variants_count);
    const std::span<const cgltf_material_variant> variants(data.variants, data.variants_count);
    for (const cgltf_material_variant& source : variants) {
        push_variant(model, source);
    }
}

[[nodiscard]] Status push_node(const cgltf_node& source, const Gltf& data, Model& model) {
    if (source.has_mesh_gpu_instancing != 0) return unsupported("nhân bản GPU");
    Node node = read_node(source, data);
    append_moved(model.nodes, node);
    return core::ok();
}

[[nodiscard]] Status read_all_nodes(const Gltf& data, Model& model) {
    model.nodes.reserve(data.nodes_count);
    const std::span<const cgltf_node> nodes(data.nodes, data.nodes_count);
    const auto push = [&](std::size_t index) { return push_node(nodes[index], data, model); };
    return each_index(nodes.size(), push);
}

[[nodiscard]] Status read_all_skins(const Gltf& data, Model& model) {
    model.skins.resize(data.skins_count);
    const std::span<const cgltf_skin> skins(data.skins, data.skins_count);
    const auto read = [&](std::size_t index) { return read_skin(skins[index], data, model.skins[index]); };
    return each_index(skins.size(), read);
}

[[nodiscard]] Status read_all_clips(const Gltf& data, Model& model) {
    model.clips.resize(data.animations_count);
    const std::span<const cgltf_animation> clips(data.animations, data.animations_count);
    const auto read = [&](std::size_t index) { return read_clip(clips[index], data, model.clips[index]); };
    return each_index(clips.size(), read);
}

[[nodiscard]] Status fill_model(const Gltf& data, const ImageScope& scope, Model& model) {
    const Status meshes = read_all_meshes(data, model);
    if (!meshes) return meshes;
    const Status images = read_all_images(data, scope, model);
    if (!images) return images;
    read_all_samplers(data, model);
    read_all_materials(data, model);
    const Status cameras = read_all_cameras(data, model);
    if (!cameras) return cameras;
    const Status lights = read_all_lights(data, model);
    if (!lights) return lights;
    read_all_variants(data, model);
    const Status nodes = read_all_nodes(data, model);
    if (!nodes) return nodes;
    const Status skins = read_all_skins(data, model);
    if (!skins) return skins;
    const Status clips = read_all_clips(data, model);
    if (!clips) return clips;
    const Status checked = check_nodes(model);
    if (!checked) return checked;
    read_roots(data, model);
    return core::ok();
}

constexpr std::array<std::string_view, 18> kRequired{
    "EXT_meshopt_compression",
    "KHR_lights_punctual",
    "KHR_materials_anisotropy",
    "KHR_materials_clearcoat",
    "KHR_materials_diffuse_transmission",
    "KHR_materials_dispersion",
    "KHR_materials_emissive_strength",
    "KHR_materials_ior",
    "KHR_materials_iridescence",
    "KHR_materials_pbrSpecularGlossiness",
    "KHR_materials_sheen",
    "KHR_materials_specular",
    "KHR_materials_transmission",
    "KHR_materials_unlit",
    "KHR_materials_variants",
    "KHR_materials_volume",
    "KHR_mesh_quantization",
    "KHR_texture_transform",
};

[[nodiscard]] Status require_known(const char* raw) {
    // Ngoài kRequired (Draco, Basis, WebP, GPU, KHR_meshopt) thì từ chối.
    const std::string_view name = raw == nullptr ? std::string_view() : std::string_view(raw);
    const auto found = std::ranges::find(kRequired, name);
    if (found != kRequired.end()) return core::ok();
    return core::fail(core::ErrorCode::kUnsupported, "GLB cần extension chưa hỗ trợ", name);
}

[[nodiscard]] Status check_required(const Gltf& data) {
    // Khác gốc: span thay extensions_required[index].
    const std::span<char*> names(data.extensions_required, data.extensions_required_count);
    const auto require = [&](std::size_t index) { return require_known(names[index]); };
    return each_index(names.size(), require);
}

struct Orphan {
    cgltf_animation_channel* channel = nullptr;
    cgltf_node* node = nullptr;
};

[[nodiscard]] bool is_orphan(const Channel& channel) noexcept {
    // Clip motion không lưới: gỡ nút lúc validate (325/5126 clip Tripo).
    if (channel.target_path != cgltf_animation_path_type_weights) return false;
    if (channel.target_node == nullptr) return false;
    const cgltf_mesh* mesh = channel.target_node->mesh;
    return mesh == nullptr || mesh->primitives_count == 0;
}

// Khác gốc: if trong for thành câu bảo vệ của detach_channel.
void detach_channel(cgltf_animation_channel& channel, std::vector<Orphan>& orphans) {
    if (!is_orphan(channel)) return;
    const Orphan orphan{.channel = &channel, .node = channel.target_node};
    orphans.push_back(orphan);
    channel.target_node = nullptr;
}

void detach_clip(const cgltf_animation& animation, std::vector<Orphan>& orphans) {
    const std::span<cgltf_animation_channel> channels(animation.channels, animation.channels_count);
    for (cgltf_animation_channel& channel : channels) {
        detach_channel(channel, orphans);
    }
}

[[nodiscard]] std::vector<Orphan> detach_orphans(const Gltf& data) {
    std::vector<Orphan> orphans;
    const std::span<cgltf_animation> clips(data.animations, data.animations_count);
    for (const cgltf_animation& clip : clips) {
        detach_clip(clip, orphans);
    }
    return orphans;
}

void attach_orphans(std::span<const Orphan> orphans) noexcept {
    for (const Orphan& orphan : orphans) {
        orphan.channel->target_node = orphan.node;
    }
}

[[nodiscard]] Status check_orphan(const Channel& channel) {
    const cgltf_animation_sampler* sampler = channel.sampler;
    if (!sampler_whole(sampler)) return bad("kênh hoạt hình thiếu sampler");
    const bool cubic = sampler->interpolation == cgltf_interpolation_type_cubic_spline;
    const std::size_t per_key = cubic ? 3 : 1;
    const std::size_t keys = sampler->input->count;
    const std::size_t values = sampler->output->count;
    if (keys == 0 || values == 0) return bad("trọng số morph không có khoá");
    if (keys > std::numeric_limits<std::size_t>::max() / per_key) {
        return core::fail(core::ErrorCode::kOverflow, "trọng số morph quá nhiều khoá");
    }
    // Không lưới: trọng số mỗi khoá là output/input, phải chia hết.
    if (values % (keys * per_key) != 0) return bad("trọng số morph lệch số khoá");
    return core::ok();
}

[[nodiscard]] Status check_orphans(std::span<const Orphan> orphans) {
    return each_item(orphans, [](const Orphan& orphan) { return check_orphan(*orphan.channel); });
}

[[nodiscard]] bool is_index_stride(std::size_t stride) noexcept {
    return stride == 2 || stride == 4;
}

// Khác gốc: tách &&; % 4 vẫn tính, không phụ.
[[nodiscard]] bool is_vertex_stride(std::size_t stride) noexcept {
    const bool wide = stride >= 4 && stride <= 256;
    const bool aligned = stride % 4 == 0;
    return wide && aligned;
}

[[nodiscard]] bool mode_fits(const Meshopt& packed) noexcept {
    switch (packed.mode) {
    // meshopt assert bước. Validate lọt stride 0 ở ATTRIBUTES.
    case cgltf_meshopt_compression_mode_attributes: return is_vertex_stride(packed.stride);
    case cgltf_meshopt_compression_mode_triangles: return is_index_stride(packed.stride) && packed.count % 3 == 0;
    case cgltf_meshopt_compression_mode_indices: return is_index_stride(packed.stride);
    case cgltf_meshopt_compression_mode_invalid:
    case cgltf_meshopt_compression_mode_max_enum: return false;
    }
    return false;
}

[[nodiscard]] bool octahedral_stride(std::size_t stride) noexcept {
    return stride == 4 || stride == 8;
}

// Bộ lọc chỉ cho đỉnh; mỗi bộ lọc một bước.
[[nodiscard]] bool filter_fits(const Meshopt& packed) noexcept {
    const bool is_vertex = packed.mode == cgltf_meshopt_compression_mode_attributes;
    switch (packed.filter) {
    case cgltf_meshopt_compression_filter_none: return true;
    case cgltf_meshopt_compression_filter_octahedral: return is_vertex && octahedral_stride(packed.stride);
    case cgltf_meshopt_compression_filter_quaternion: return is_vertex && packed.stride == 8;
    case cgltf_meshopt_compression_filter_exponential: return is_vertex;
    case cgltf_meshopt_compression_filter_max_enum: return false;
    }
    return false;
}

[[nodiscard]] int decode_stream(const Meshopt& packed, void* out, Byte source) noexcept {
    switch (packed.mode) {
    case cgltf_meshopt_compression_mode_attributes:
        return meshopt_decodeVertexBuffer(out, packed.count, packed.stride, source, packed.size);
    case cgltf_meshopt_compression_mode_triangles:
        return meshopt_decodeIndexBuffer(out, packed.count, packed.stride, source, packed.size);
    case cgltf_meshopt_compression_mode_indices:
        return meshopt_decodeIndexSequence(out, packed.count, packed.stride, source, packed.size);
    case cgltf_meshopt_compression_mode_invalid:
    case cgltf_meshopt_compression_mode_max_enum: return -1;
    }
    return -1;
}

// Khác gốc: return lời gọi void tách thành gọi rồi return.
void apply_filter(const Meshopt& packed, void* out) noexcept {
    switch (packed.filter) {
    case cgltf_meshopt_compression_filter_octahedral: meshopt_decodeFilterOct(out, packed.count, packed.stride); return;
    case cgltf_meshopt_compression_filter_quaternion:
        meshopt_decodeFilterQuat(out, packed.count, packed.stride);
        return;
    case cgltf_meshopt_compression_filter_exponential:
        meshopt_decodeFilterExp(out, packed.count, packed.stride);
        return;
    case cgltf_meshopt_compression_filter_none:
    case cgltf_meshopt_compression_filter_max_enum: return;
    }
}

[[nodiscard]] bool meshopt_inside(const Meshopt& packed, const cgltf_buffer& buffer) noexcept {
    const bool offset_ok = packed.offset <= buffer.size;
    return offset_ok && packed.size <= buffer.size - packed.offset;
}

[[nodiscard]] Status meshopt_ready(const Meshopt& packed, const cgltf_buffer_view& view) {
    const bool fits = mode_fits(packed) && filter_fits(packed);
    if (!fits) return bad("mô tả meshopt sai");
    const cgltf_buffer* buffer = packed.buffer;
    const bool missing = buffer == nullptr || buffer->data == nullptr;
    if (missing) return bad("meshopt thiếu buffer nén");
    const bool inside = meshopt_inside(packed, *buffer);
    if (!inside) return bad("vùng nén meshopt vượt buffer");
    const bool overflow = packed.count > std::numeric_limits<std::size_t>::max() / packed.stride;
    if (overflow) return core::fail(core::ErrorCode::kOverflow, "view meshopt quá lớn");
    const std::size_t bytes = packed.count * packed.stride;
    if (bytes != view.size) return bad("mô tả meshopt sai");
    return core::ok();
}

// count rồi stride (API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] std::size_t byte_count(std::size_t count, std::size_t stride) noexcept {
    return count * stride;
}

[[nodiscard]] Status decode_view(cgltf_buffer_view& view) {
    const Meshopt& packed = view.meshopt_compression;
    const Status ready = meshopt_ready(packed, view);
    if (!ready) return ready;
    const std::size_t size = byte_count(packed.count, packed.stride);
    if (size == 0) return core::ok();
    // view.data để cgltf_free gọi free (SH-02).
    // NOLINTNEXTLINE(cppcoreguidelines-no-malloc, cppcoreguidelines-owning-memory)
    void* uncompressed_bytes = std::malloc(byte_count(packed.count, packed.stride));
    if (uncompressed_bytes == nullptr) {
        return core::fail(core::ErrorCode::kOutOfMemory, "hết bộ nhớ giải meshopt");
    }
    HeapPtr out(uncompressed_bytes);
    const cgltf_buffer* buffer = packed.buffer;
    const auto* packed_bytes = static_cast<const std::uint8_t*>(buffer->data);
    const std::span<const std::uint8_t> whole(packed_bytes, buffer->size);
    const std::span<const std::uint8_t> compressed = whole.subspan(packed.offset, packed.size);
    void* destination = out.get();
    const std::uint8_t* source = compressed.data();
    const int decoded = decode_stream(packed, destination, source);
    if (decoded != 0) return bad("dữ liệu nén meshopt hỏng");
    apply_filter(packed, destination);
    view.data = out.release();
    return core::ok();
}

[[nodiscard]] Status decode_one_view(cgltf_buffer_view& view) {
    const bool skip = view.has_meshopt_compression == 0 || view.data != nullptr;
    if (skip) return core::ok();
    return decode_view(view);
}

[[nodiscard]] Status decode_meshopt(const Gltf& data) {
    const std::span<cgltf_buffer_view> views(data.buffer_views, data.buffer_views_count);
    const auto decode = [&](std::size_t index) { return decode_one_view(views[index]); };
    return each_index(views.size(), decode);
}

[[nodiscard]] Status validate(Gltf& data) {
    // Kiểm biến thể, chỉ số, accessor rồi mới tin con trỏ.
    const std::vector<Orphan> orphans = detach_orphans(data);
    const cgltf_result checked = cgltf_validate(&data);
    attach_orphans(orphans);
    if (checked != cgltf_result_success) return gltf_fail(checked);
    return check_orphans(orphans);
}

[[nodiscard]] core::Result<GltfPtr> parse_gltf(std::span<const std::byte> bytes, const char* path) {
    if (bytes.empty()) return core::fail(core::ErrorCode::kInvalidArgument, "GLB rỗng");
    const cgltf_options options{};
    cgltf_data* raw = nullptr;
    const std::byte* input = bytes.data();
    const std::size_t input_size = bytes.size();
    const cgltf_result parsed = cgltf_parse(&options, input, input_size, &raw);
    const bool parse_failed = parsed != cgltf_result_success || raw == nullptr;
    if (parse_failed) return gltf_fail(parsed);
    GltfPtr data{raw};
    const Status required = check_required(*data);
    if (!required) return failure_of(required);
    cgltf_data* parsed_data = data.get();
    const cgltf_result loaded = cgltf_load_buffers(&options, parsed_data, path);
    if (loaded != cgltf_result_success) return gltf_fail(loaded);
    const Status valid = validate(*data);
    if (!valid) return failure_of(valid);
    const Status decoded = decode_meshopt(*data);
    if (!decoded) return failure_of(decoded);
    return data;
}

} // namespace

// Khác gốc: trần là root, rỗng thì là thư mục của GLB.
core::Result<std::string> image_path(std::string_view uri, const ImageScope& scope) {
    if (scope.directory.empty()) return unsupported("ảnh nằm ngoài GLB");
    std::string decoded(uri);
    char* uri_chars = decoded.data();
    const cgltf_size length = cgltf_decode_uri(uri_chars);
    decoded.resize(length);
    if (decoded.empty()) return bad("ảnh URI rỗng");
    if (fs::is_absolute(decoded)) return unsupported("ảnh URI tuyệt đối");
    // Khác gốc: contains(':') cùng find != npos.
    const bool has_scheme = decoded.contains(':');
    if (has_scheme) return unsupported("ảnh URI có scheme");
    std::string full = fs::join(scope.directory, decoded);
    const std::string_view limit = scope.root.empty() ? scope.directory : scope.root;
    const std::string root = fs::normalize(limit);
    if (!stays_inside(full, root)) return unsupported("ảnh URI thoát thư mục");
    return full;
}

core::Result<Model> load_glb(std::span<const std::byte> bytes) {
    auto data = parse_gltf(bytes, nullptr);
    if (!data) return failure_of(data);
    Model model;
    const ImageScope scope;
    const core::Status filled = fill_model(**data, scope, model);
    if (!filled) return failure_of(filled);
    return model;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): path rồi root (API-03)
core::Result<Model> load_glb_file(std::string_view path, std::string_view root, TextureTier tier) {
    auto bytes = read_bytes(path);
    if (!bytes) return failure_of(bytes);
    const std::string owned(path);
    const std::span<const std::byte> file_bytes = bytes->span();
    const char* path_chars = owned.c_str();
    auto data = parse_gltf(file_bytes, path_chars);
    if (!data) return failure_of(data);
    Model model;
    ImageScope scope;
    scope.directory = fs::parent(owned);
    scope.root = root;
    scope.tier = tier;
    const core::Status filled = fill_model(**data, scope, model);
    if (!filled) return failure_of(filled);
    return model;
}

} // namespace game::resource
