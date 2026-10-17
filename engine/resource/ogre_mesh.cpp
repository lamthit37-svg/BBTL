/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/ogre_mesh.cpp
 *  PHÂN HỆ   : Resource / Ogre Mesh
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ đọc theo TOOLS/glb/ogre_mesh.py: độ dài chunk M_MESH của client sai,
 *    nên chỉ dùng độ dài để nhảy qua edge list, pose, animation và extremes.
 *    Gán xương là bản ghi 16 byte xếp khít.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "resource/ogre_mesh.hpp"

#include "core/gbk.hpp"
#include "core/text.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "resource/dds.hpp"
#include "resource/image.hpp"
#include "resource/lod.hpp"

#include <meshoptimizer.h>

#include <algorithm>
#include <array>
#include <charconv>
#include <cstdint>
#include <cstring>
#include <limits>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::resource {
namespace {

constexpr std::uint16_t kHeader = 0x1000;
constexpr std::uint16_t kMesh = 0x3000;
constexpr std::uint16_t kSubmesh = 0x4000;
constexpr std::uint16_t kOperation = 0x4010;
constexpr std::uint16_t kBone = 0x4100;
constexpr std::uint16_t kAlias = 0x4200;
constexpr std::uint16_t kGeometry = 0x5000;
constexpr std::uint16_t kDeclaration = 0x5100;
constexpr std::uint16_t kElement = 0x5110;
constexpr std::uint16_t kBuffer = 0x5200;
constexpr std::uint16_t kBufferData = 0x5210;
constexpr std::uint16_t kSkeleton = 0x6000;
constexpr std::uint16_t kMeshBone = 0x7000;
constexpr std::uint16_t kLod = 0x8000;
constexpr std::uint16_t kLodUsage = 0x8100;
constexpr std::uint16_t kLodManual = 0x8110;
constexpr std::uint16_t kLodGenerated = 0x8120;
constexpr std::uint16_t kBounds = 0x9000;
constexpr std::uint16_t kNames = 0xA000;
constexpr std::uint16_t kNameItem = 0xA100;
constexpr std::uint16_t kEdges = 0xB000;
constexpr std::uint16_t kPoses = 0xC000;
constexpr std::uint16_t kAnimations = 0xD000;
constexpr std::uint16_t kExtremes = 0xE000;
constexpr std::uint16_t kTriangleList = 4;
// Bản 2 thêm mức chi tiết của build_lods sau chỉ số mỗi primitive. Bản 1 vẫn đọc được: mức chi
// tiết khi ấy dựng lúc chạy như trước.
constexpr std::uint32_t kCacheVersion = 2;
constexpr std::uint32_t kPlainCacheVersion = 1;
constexpr char kCacheMagic[4] = {'T', 'L', 'M', 'S'};
// Trần của số đếm đọc từ cache, kiểm trước khi cấp phát: tệp hỏng không xin hàng GB. Mesh lớn
// nhất của dữ liệu TLBB dưới 100 nghìn đỉnh; build_lods sinh 3 mức.
constexpr std::uint32_t kMaxCacheVertices = std::uint32_t{1} << 22U;
constexpr std::uint32_t kMaxCacheIndices = std::uint32_t{1} << 24U;
constexpr std::uint32_t kMaxCacheLods = 8;

constexpr std::uint16_t kPosition = 1;
constexpr std::uint16_t kNormal = 4;
constexpr std::uint16_t kDiffuse = 5;
constexpr std::uint16_t kTexcoord = 7;
constexpr std::uint16_t kTangent = 9;
constexpr std::uint16_t kFloat2 = 1;
constexpr std::uint16_t kFloat3 = 2;
constexpr std::uint16_t kFloat4 = 3;
constexpr std::uint16_t kColour = 4;
constexpr std::uint16_t kUbyte4 = 9;
constexpr std::uint16_t kColourArgb = 10;
constexpr std::uint16_t kColourAbgr = 11;

struct Cursor {
    std::span<const std::byte> data;
    std::size_t at = 0;
    const char* error = nullptr;

    [[nodiscard]] std::size_t remaining() const noexcept { return data.size() - at; }

    [[nodiscard]] bool fail(const char* message) noexcept {
        error = message;
        return false;
    }

    [[nodiscard]] bool take(std::size_t size, const char* message) noexcept {
        if (error != nullptr) return false;
        if (size > remaining()) return fail(message);
        at += size;
        return true;
    }

    [[nodiscard]] bool copy_bytes(std::size_t size, void* dest, const char* message) noexcept {
        if (error != nullptr) return false;
        if (size > remaining()) return fail(message);
        std::memcpy(dest, data.data() + at, size);
        at += size;
        return true;
    }

    [[nodiscard]] bool u8(std::uint8_t& out) noexcept { return copy_bytes(1, &out, "mesh cụt"); }
    [[nodiscard]] bool u16(std::uint16_t& out) noexcept { return copy_bytes(2, &out, "mesh cụt"); }
    [[nodiscard]] bool u32(std::uint32_t& out) noexcept { return copy_bytes(4, &out, "mesh cụt"); }
    [[nodiscard]] bool f32(float& out) noexcept { return copy_bytes(4, &out, "mesh cụt"); }

    [[nodiscard]] bool line(std::string& out) noexcept {
        if (error != nullptr) return false;
        const std::byte* begin = data.data() + at;
        const std::byte* end = data.data() + data.size();
        const std::byte* found = begin;
        while (found != end && *found != std::byte{'\n'})
            ++found;
        if (found == end) return fail("chuỗi mesh không có dấu kết");
        out.assign(reinterpret_cast<const char*>(begin), static_cast<std::size_t>(found - begin));
        at += static_cast<std::size_t>(found - begin) + 1;
        return true;
    }

    [[nodiscard]] bool peek_id(std::uint16_t& id) const noexcept {
        if (remaining() < 6) return false;
        std::memcpy(&id, data.data() + at, 2);
        return true;
    }

    [[nodiscard]] bool begin(std::uint16_t expected) noexcept {
        std::uint16_t id = 0;
        std::uint32_t length = 0;
        if (!u16(id) || !u32(length)) return false;
        if (id != expected) return fail("mesh sai chunk");
        return true;
    }

    [[nodiscard]] bool skip() noexcept {
        const std::size_t start = at;
        std::uint16_t id = 0;
        std::uint32_t length = 0;
        if (!u16(id) || !u32(length)) return false;
        const bool fits = length >= 6 && start <= data.size() && length <= data.size() - start;
        if (!fits) {
            at = start;
            return false;
        }
        at = start + length;
        return true;
    }
};

struct Element {
    std::uint16_t source = 0;
    std::uint16_t type = 0;
    std::uint16_t semantic = 0;
    std::uint16_t offset = 0;
    std::uint16_t index = 0;
};

struct Buffer {
    std::uint16_t bind = 0;
    std::uint16_t stride = 0;
    std::vector<std::byte> data;
};

struct Geometry {
    std::uint32_t count = 0;
    std::vector<Element> elements;
    std::vector<Buffer> buffers;
};

struct Weight {
    std::uint32_t vertex = 0;
    std::uint16_t bone = 0;
    float value = 0.0F;
};

struct Submesh {
    std::string material;
    bool uses_shared = false;
    std::vector<std::uint32_t> indices;
    Geometry geometry;
    bool has_geometry = false;
    std::uint16_t operation = kTriangleList;
    bool has_operation = false;
    std::vector<Weight> weights;
    std::string texture;
};

struct RawMesh {
    Geometry shared;
    bool has_shared = false;
    std::vector<Submesh> submeshes;
    std::vector<Weight> shared_weights;
};

[[nodiscard]] core::Failure corrupt(core::Message message) {
    return core::fail(core::ErrorCode::kCorrupt, message);
}

[[nodiscard]] std::uint16_t element_bytes(std::uint16_t type) noexcept {
    if (type <= 3) return static_cast<std::uint16_t>(4U * (type + 1U));
    if (type == kColour || type == kUbyte4 || type == kColourArgb || type == kColourAbgr) return 4;
    return 0;
}

[[nodiscard]] bool read_declaration(Cursor& cursor, Geometry& geometry) {
    if (!cursor.begin(kDeclaration)) return false;
    std::uint16_t id = 0;
    while (cursor.peek_id(id) && id == kElement) {
        if (!cursor.begin(kElement)) return false;
        Element element;
        if (!cursor.u16(element.source) || !cursor.u16(element.type) || !cursor.u16(element.semantic)) return false;
        if (!cursor.u16(element.offset) || !cursor.u16(element.index)) return false;
        geometry.elements.push_back(element);
    }
    return cursor.error == nullptr;
}

[[nodiscard]] bool read_buffer(Cursor& cursor, Geometry& geometry) {
    if (!cursor.begin(kBuffer)) return false;
    Buffer buffer;
    if (!cursor.u16(buffer.bind) || !cursor.u16(buffer.stride)) return false;
    if (buffer.stride == 0) return cursor.fail("buffer đỉnh có cỡ đỉnh 0");
    if (!cursor.begin(kBufferData)) return false;
    const std::uint64_t bytes = std::uint64_t{geometry.count} * buffer.stride;
    if (bytes > cursor.remaining()) return cursor.fail("mesh cụt đỉnh");
    buffer.data.resize(static_cast<std::size_t>(bytes));
    if (!cursor.copy_bytes(buffer.data.size(), buffer.data.data(), "mesh cụt đỉnh")) return false;
    geometry.buffers.push_back(std::move(buffer));
    return true;
}

[[nodiscard]] bool check_geometry(const Geometry& geometry, Cursor& cursor) {
    for (const Element& element : geometry.elements) {
        const std::uint16_t size = element_bytes(element.type);
        if (size == 0) return cursor.fail("kiểu thành phần đỉnh lạ");
        const Buffer* buffer = nullptr;
        for (const Buffer& item : geometry.buffers) {
            if (item.bind == element.source) buffer = &item;
        }
        if (buffer == nullptr) return cursor.fail("thành phần trỏ buffer không có");
        if (element.offset + size > buffer->stride) return cursor.fail("thành phần tràn khỏi cỡ đỉnh");
    }
    return true;
}

[[nodiscard]] bool read_geometry(Cursor& cursor, Geometry& geometry, bool& present) {
    if (!cursor.begin(kGeometry)) return false;
    if (!cursor.u32(geometry.count)) return false;
    present = geometry.count != 0;
    if (!present) return true;
    std::uint16_t id = 0;
    while (cursor.peek_id(id) && (id == kDeclaration || id == kBuffer)) {
        const bool read = id == kDeclaration ? read_declaration(cursor, geometry) : read_buffer(cursor, geometry);
        if (!read) return false;
    }
    return check_geometry(geometry, cursor);
}

[[nodiscard]] bool read_weights(Cursor& cursor, std::uint16_t chunk_id, std::vector<Weight>& weights) {
    while (cursor.remaining() >= 16) {
        std::uint16_t id = 0;
        std::memcpy(&id, cursor.data.data() + cursor.at, 2);
        if (id != chunk_id) return true;
        std::uint16_t ignored_id = 0;
        std::uint32_t length = 0;
        Weight weight;
        if (!cursor.u16(ignored_id) || !cursor.u32(length) || !cursor.u32(weight.vertex)) return false;
        if (!cursor.u16(weight.bone) || !cursor.f32(weight.value)) return false;
        weights.push_back(weight);
    }
    return true;
}

[[nodiscard]] bool read_indices(Cursor& cursor, Submesh& submesh) {
    std::uint8_t shared = 0;
    std::uint32_t count = 0;
    std::uint8_t wide = 0;
    if (!cursor.u8(shared) || !cursor.u32(count) || !cursor.u8(wide)) return false;
    submesh.uses_shared = shared != 0;
    const std::uint64_t bytes = std::uint64_t{count} * (wide != 0 ? 4U : 2U);
    if (bytes > cursor.remaining()) return cursor.fail("mesh cụt chỉ số");
    submesh.indices.resize(count);
    for (std::uint32_t index = 0; index < count; ++index) {
        if (wide != 0) {
            if (!cursor.u32(submesh.indices[index])) return false;
        } else {
            std::uint16_t narrow = 0;
            if (!cursor.u16(narrow)) return false;
            submesh.indices[index] = narrow;
        }
    }
    return true;
}

[[nodiscard]] bool read_submesh(Cursor& cursor, Submesh& submesh) {
    if (!cursor.begin(kSubmesh)) return false;
    if (!cursor.line(submesh.material) || !read_indices(cursor, submesh)) return false;
    std::uint16_t id = 0;
    while (cursor.peek_id(id)) {
        if (id == kGeometry) {
            if (!read_geometry(cursor, submesh.geometry, submesh.has_geometry)) return false;
        } else if (id == kOperation) {
            if (!cursor.begin(kOperation) || !cursor.u16(submesh.operation)) return false;
            submesh.has_operation = true;
        } else if (id == kBone) {
            if (!read_weights(cursor, kBone, submesh.weights)) return false;
        } else if (id == kAlias) {
            if (!cursor.begin(kAlias)) return false;
            std::string alias;
            if (!cursor.line(alias) || !cursor.line(submesh.texture)) return false;
        } else {
            break;
        }
    }
    if (submesh.has_operation && submesh.operation != kTriangleList)
        return cursor.fail("mesh không phải danh sách tam giác");
    return cursor.error == nullptr;
}

[[nodiscard]] bool read_lod_level(Cursor& cursor, bool manual) {
    if (!cursor.begin(kLodUsage)) return false;
    float depth = 0.0F;
    if (!cursor.f32(depth)) return false;
    if (manual) {
        if (!cursor.begin(kLodManual)) return false;
        std::string name;
        return cursor.line(name);
    }
    std::uint16_t id = 0;
    while (cursor.peek_id(id) && id == kLodGenerated) {
        if (!cursor.begin(kLodGenerated)) return false;
        std::uint32_t count = 0;
        std::uint8_t wide = 0;
        if (!cursor.u32(count) || !cursor.u8(wide)) return false;
        const std::uint64_t bytes = std::uint64_t{count} * (wide != 0 ? 4U : 2U);
        if (!cursor.take(static_cast<std::size_t>(bytes), "mesh cụt lod")) return false;
    }
    return true;
}

[[nodiscard]] bool read_lod(Cursor& cursor) {
    if (!cursor.begin(kLod)) return false;
    std::uint16_t levels = 0;
    std::uint8_t manual = 0;
    if (!cursor.u16(levels) || !cursor.u8(manual)) return false;
    const std::uint16_t extra = levels > 0 ? static_cast<std::uint16_t>(levels - 1) : 0;
    for (std::uint16_t index = 0; index < extra; ++index) {
        if (!read_lod_level(cursor, manual != 0)) return false;
    }
    return true;
}

[[nodiscard]] bool read_names(Cursor& cursor) {
    if (!cursor.begin(kNames)) return false;
    std::uint16_t id = 0;
    while (cursor.peek_id(id) && id == kNameItem) {
        if (!cursor.begin(kNameItem)) return false;
        std::uint16_t index = 0;
        std::string name;
        if (!cursor.u16(index) || !cursor.line(name)) return false;
    }
    return true;
}

[[nodiscard]] bool read_mesh_chunk(Cursor& cursor, std::uint16_t id, RawMesh& mesh) {
    if (id == kGeometry) return read_geometry(cursor, mesh.shared, mesh.has_shared);
    if (id == kSubmesh) {
        Submesh submesh;
        if (!read_submesh(cursor, submesh)) return false;
        mesh.submeshes.push_back(std::move(submesh));
        return true;
    }
    if (id == kSkeleton) {
        if (!cursor.begin(kSkeleton)) return false;
        std::string name;
        return cursor.line(name);
    }
    if (id == kMeshBone) return read_weights(cursor, kMeshBone, mesh.shared_weights);
    if (id == kBounds) {
        if (!cursor.begin(kBounds)) return false;
        float value = 0.0F;
        for (int index = 0; index < 7; ++index) {
            if (!cursor.f32(value)) return false;
        }
        return true;
    }
    if (id == kLod) return read_lod(cursor);
    if (id == kNames) return read_names(cursor);
    if (id == kEdges || id == kPoses || id == kAnimations || id == kExtremes) return cursor.skip();
    return false;
}

[[nodiscard]] const Buffer* buffer_of(const Geometry& geometry, std::uint16_t source) noexcept {
    for (const Buffer& buffer : geometry.buffers) {
        if (buffer.bind == source) return &buffer;
    }
    return nullptr;
}

[[nodiscard]] bool read_float(const Buffer& buffer, std::uint32_t vertex, std::uint16_t offset, float& out) noexcept {
    const std::size_t at = std::size_t{vertex} * buffer.stride + offset;
    if (at + 4 > buffer.data.size()) return false;
    std::memcpy(&out, buffer.data.data() + at, 4);
    return true;
}

void write_colour(Vertex& vertex, const std::byte* bytes, bool swap) noexcept {
    const auto blue = static_cast<std::uint8_t>(bytes[0]);
    const auto green = static_cast<std::uint8_t>(bytes[1]);
    const auto red = static_cast<std::uint8_t>(bytes[2]);
    const auto alpha = static_cast<std::uint8_t>(bytes[3]);
    const float scale = 1.0F / 255.0F;
    vertex.color.x = static_cast<float>(swap ? red : blue) * scale;
    vertex.color.y = static_cast<float>(green) * scale;
    vertex.color.z = static_cast<float>(swap ? blue : red) * scale;
    vertex.color.w = static_cast<float>(alpha) * scale;
}

[[nodiscard]] bool apply_element(const Element& element, const Buffer& buffer, std::uint32_t index, Vertex& vertex) {
    const std::size_t at = std::size_t{index} * buffer.stride + element.offset;
    const std::uint16_t size = element_bytes(element.type);
    if (size == 0 || at + size > buffer.data.size()) return false;
    const std::byte* bytes = buffer.data.data() + at;
    if (element.semantic == kPosition && element.type == kFloat3) {
        return read_float(buffer, index, element.offset, vertex.position.x) &&
            read_float(buffer, index, static_cast<std::uint16_t>(element.offset + 4), vertex.position.y) &&
            read_float(buffer, index, static_cast<std::uint16_t>(element.offset + 8), vertex.position.z);
    }
    if (element.semantic == kNormal && element.type == kFloat3) {
        return read_float(buffer, index, element.offset, vertex.normal.x) &&
            read_float(buffer, index, static_cast<std::uint16_t>(element.offset + 4), vertex.normal.y) &&
            read_float(buffer, index, static_cast<std::uint16_t>(element.offset + 8), vertex.normal.z);
    }
    if (element.semantic == kTexcoord && element.type == kFloat2 && element.index <= 1) {
        math::Float2& uv = element.index == 0 ? vertex.uv : vertex.uv1;
        return read_float(buffer, index, element.offset, uv.x) &&
            read_float(buffer, index, static_cast<std::uint16_t>(element.offset + 4), uv.y);
    }
    if (element.semantic == kTangent && (element.type == kFloat3 || element.type == kFloat4)) {
        if (!read_float(buffer, index, element.offset, vertex.tangent.x)) return false;
        if (!read_float(buffer, index, static_cast<std::uint16_t>(element.offset + 4), vertex.tangent.y)) return false;
        return read_float(buffer, index, static_cast<std::uint16_t>(element.offset + 8), vertex.tangent.z);
    }
    if (element.semantic == kDiffuse &&
        (element.type == kColour || element.type == kColourArgb || element.type == kColourAbgr)) {
        write_colour(vertex, bytes, element.type != kColourAbgr);
        return true;
    }
    return true;
}

[[nodiscard]] bool fill_vertices(const Geometry& geometry, std::vector<Vertex>& vertices) {
    vertices.assign(geometry.count, Vertex{});
    for (Vertex& vertex : vertices) {
        vertex.color = {1.0F, 1.0F, 1.0F, 1.0F};
        vertex.normal = {0.0F, 1.0F, 0.0F};
    }
    for (std::uint32_t index = 0; index < geometry.count; ++index) {
        for (const Element& element : geometry.elements) {
            const Buffer* buffer = buffer_of(geometry, element.source);
            if (buffer == nullptr) return false;
            if (!apply_element(element, *buffer, index, vertices[index])) return false;
        }
    }
    return true;
}

void apply_weights(const std::vector<Weight>& weights, std::vector<Vertex>& vertices) {
    std::vector<std::uint8_t> used(vertices.size(), 0);
    for (const Weight& weight : weights) {
        if (weight.vertex >= vertices.size()) continue;
        std::uint8_t& count = used[weight.vertex];
        if (count >= 4) continue;
        Vertex& vertex = vertices[weight.vertex];
        vertex.joints[count] = weight.bone;
        vertex.weights[count] = weight.value;
        ++count;
    }
}

struct MaterialRule {
    std::string parent;
    std::string texture;
    // scrollTex của TwoTex: ảnh phát sáng, không phải ảnh màu.
    std::string scroll;
    std::string blend;
    std::string cull;
    std::string rejection;
    std::string lighting;
    float scroll_u = 0.0F;
    float scroll_v = 0.0F;
    float offset_u = 0.0F;
    float offset_v = 0.0F;
    bool has_scroll = false;
    bool has_offset = false;
    // fog_override true: tấm cộng sáng không bị sương cảnh nhuộm đen.
    bool no_fog = false;
};

struct MaterialLook {
    std::string texture;
    // Mặt nạ (baseTexture) khi texture đã đổi thành scrollTex.
    std::string mask;
    std::string scroll;
    Alpha alpha = Alpha::kOpaque;
    float cutoff = 0.5F;
    float scroll_u = 0.0F;
    float scroll_v = 0.0F;
    float offset_u = 0.0F;
    float offset_v = 0.0F;
    // ColorX4 của mẫu TwoTex: nhân màu trước lần kẹp duy nhất của shader.
    float gain = 1.0F;
    bool double_sided = false;
    bool unlit = false;
    bool has_scroll = false;
    bool has_offset = false;
    bool no_fog = false;
};

using MaterialRules = std::vector<std::pair<std::string, MaterialRule>>;

[[nodiscard]] std::string_view trim_left(std::string_view line) noexcept {
    while (!line.empty() && (line.front() == ' ' || line.front() == '\t'))
        line.remove_prefix(1);
    return line;
}

[[nodiscard]] std::string_view first_token(std::string_view line) noexcept {
    const std::size_t cut = line.find_first_of(" \t");
    if (cut == std::string_view::npos) return line;
    return line.substr(0, cut);
}

[[nodiscard]] float number_of(std::string_view text) noexcept {
    float value = 0.0F;
    const char* first = text.data();
    const char* last = first + text.size();
    const std::from_chars_result read = std::from_chars(first, last, value);
    if (read.ec != std::errc{}) return 0.0F;
    return value;
}

[[nodiscard]] std::string_view last_token(std::string_view line) noexcept {
    const std::size_t cut = line.find_last_of(" \t");
    if (cut == std::string_view::npos) return line;
    return line.substr(cut + 1);
}

void remember_rule(MaterialRules& rules, std::string name, std::string parent) {
    MaterialRule rule;
    rule.parent = std::move(parent);
    rules.push_back({std::move(name), std::move(rule)});
}

void set_field(std::string& field, std::string value) {
    if (!field.empty()) return;
    field = std::move(value);
}

// all.material viết cả <baseTexture> và <BaseTexture> cho ảnh màu. Hai cách là cùng một ô.
[[nodiscard]] bool is_diffuse_alias(std::string_view line) noexcept {
    const bool lower = line.contains("<baseTexture>");
    const bool upper = line.contains("<BaseTexture>");
    return lower || upper;
}

// Ảnh thứ hai của Mtl_Model_TwoTex: dải sáng cuộn, không phải màu nền.
[[nodiscard]] bool is_scroll_alias(std::string_view line) noexcept {
    return line.starts_with("set_texture_alias") && line.contains("<scrollTex>");
}

// "fog_override true none": tắt sương. Dòng không có true thì giữ sương của cảnh.
[[nodiscard]] bool is_fog_off(std::string_view line) noexcept {
    return line.starts_with("fog_override") && line.contains("true");
}

// Đọc all.material của root thành danh sách luật theo thứ tự khai báo. Thiếu tệp thì danh sách rỗng.
[[nodiscard]] MaterialRules parse_rules(std::string_view root) {
    MaterialRules rules;
    const std::string path = fs::join(fs::join(root, "Material"), "all.material");
    auto bytes = fs::read_file(path);
    if (!bytes) return rules;
    const std::string text(reinterpret_cast<const char*>(bytes->span().data()), bytes->span().size());
    std::size_t at = 0;
    while (at < text.size()) {
        const std::size_t end = text.find('\n', at);
        const std::string_view raw =
            std::string_view(text).substr(at, (end == std::string::npos ? text.size() : end) - at);
        at = end == std::string::npos ? text.size() : end + 1;
        std::string_view line = trim_left(raw);
        const std::size_t comment = line.find("//");
        if (comment != std::string_view::npos) line = line.substr(0, comment);
        // Bỏ khoảng trắng cuối dòng (kể cả '\r' và chỗ trước chú thích): 1313 dòng set_texture_alias của
        // all.material có chúng (đo 2026-10-13), mà last_token lấy phần sau dấu cách cuối nên trả chuỗi rỗng và
        // chất liệu mất ảnh (tóc nhân vật trắng toát). scene_blend và alpha_rejection cũng so cả đuôi.
        while (!line.empty() && (line.back() == '\r' || line.back() == ' ' || line.back() == '\t')) {
            line.remove_suffix(1);
        }
        if (line.empty()) continue;
        if (line.starts_with("material ")) {
            std::string_view rest = trim_left(line.substr(9));
            const std::size_t colon = rest.find(':');
            std::string name(colon == std::string_view::npos ? first_token(rest) : trim_left(rest.substr(0, colon)));
            while (!name.empty() && (name.back() == ' ' || name.back() == '\t'))
                name.pop_back();
            std::string parent;
            if (colon != std::string_view::npos) parent = std::string(first_token(trim_left(rest.substr(colon + 1))));
            remember_rule(rules, std::move(name), std::move(parent));
        } else if (rules.empty()) {
            continue;
        } else if (line.starts_with("set_texture_alias") && is_diffuse_alias(line)) {
            rules.back().second.texture = std::string(last_token(line));
        } else if (line.starts_with("scroll_anim ")) {
            const std::string_view rest = trim_left(line.substr(12));
            const std::string_view across = first_token(rest);
            const std::string_view down = first_token(trim_left(rest.substr(across.size())));
            MaterialRule& rule = rules.back().second;
            rule.scroll_u = number_of(across);
            rule.scroll_v = number_of(down);
            rule.has_scroll = true;
        } else if (line.starts_with("scroll ")) {
            const std::string_view rest = trim_left(line.substr(7));
            const std::string_view across = first_token(rest);
            const std::string_view down = first_token(trim_left(rest.substr(across.size())));
            MaterialRule& rule = rules.back().second;
            rule.offset_u = number_of(across);
            rule.offset_v = number_of(down);
            rule.has_offset = true;
        } else if (line.starts_with("texture ")) {
            set_field(rules.back().second.texture, std::string(first_token(trim_left(line.substr(8)))));
        } else if (line.starts_with("scene_blend ")) {
            set_field(rules.back().second.blend, std::string(trim_left(line.substr(12))));
        } else if (line.starts_with("cull_hardware ")) {
            set_field(rules.back().second.cull, std::string(first_token(trim_left(line.substr(14)))));
        } else if (line.starts_with("alpha_rejection ")) {
            set_field(rules.back().second.rejection, std::string(trim_left(line.substr(16))));
        } else if (line.starts_with("lighting ")) {
            set_field(rules.back().second.lighting,
                std::string(first_token(trim_left(line.substr(9)))));
        }
        const bool takes_scroll = is_scroll_alias(line) && !rules.empty();
        if (takes_scroll) rules.back().second.scroll = std::string(last_token(line));
        const bool drops_fog = is_fog_off(line) && !rules.empty();
        if (drops_fog) rules.back().second.no_fog = true;
    }
    return rules;
}

// Bảng luật của một root đã phân tích, bất biến sau khi dựng nên nhiều luồng đọc mesh tra cùng lúc không cần khoá.
// index trỏ tên chất liệu tới luật khai sau cùng cùng tên (đúng ý của vòng quét tuần tự trước đây: khai sau thắng).
struct MaterialTable {
    MaterialRules rules;
    std::unordered_map<std::string, std::size_t> index;
};

// all.material giữ tên bằng byte GBK. Bảng thú chồng tên UTF-8 lên cùng một luật.
[[nodiscard]] std::string utf8_path(std::string_view stored);

void index_rule(MaterialTable& table, std::size_t position) {
    const std::string& name = table.rules[position].first;
    table.index.insert_or_assign(name, position);
    const std::string utf8 = utf8_path(name);
    if (utf8 != name) table.index.insert_or_assign(utf8, position);
}

// Bảng của root; dựng một lần cho mỗi root (đổi root thì dựng lại). Khoá chỉ bao việc dựng và lấy
// con trỏ, không bao việc tra: all.material có hàng nghìn luật, và tra tuần tự dưới một khoá chung
// đã làm 19 luồng đọc mesh đứng xếp hàng (đo 2026-10-13: 310 mesh của Đại Lý tốn 10 giây CPU cộng
// dồn trong load_named_model).
[[nodiscard]] std::shared_ptr<const MaterialTable> table_of(std::string_view root) {
    static std::mutex gate;
    static std::string loaded;
    static std::shared_ptr<const MaterialTable> table;
    const std::scoped_lock<std::mutex> lock(gate);
    if (table && loaded == root) return table;
    auto built = std::make_shared<MaterialTable>();
    built->rules = parse_rules(root);
    built->index.reserve(built->rules.size());
    for (std::size_t position = 0; position < built->rules.size(); ++position) {
        index_rule(*built, position);
    }
    loaded = std::string(root);
    table = std::move(built);
    return table;
}

[[nodiscard]] bool is_plain_blend(std::string_view blend) noexcept {
    return blend.empty() || blend == "replace" || blend == "one zero";
}

[[nodiscard]] bool is_number(std::string_view text) noexcept {
    if (text.empty()) return false;
    for (const char item : text) {
        if (item < '0' || item > '9') return false;
    }
    return true;
}

[[nodiscard]] int digits_of(std::string_view text) noexcept {
    int value = 0;
    for (const char item : text)
        value = value * 10 + (item - '0');
    return value;
}

void apply_rejection(MaterialLook& look, std::string_view text) {
    const std::size_t cut = text.find_first_of(" \t");
    if (cut == std::string_view::npos) return;
    const std::string_view op = text.substr(0, cut);
    const std::string_view number = first_token(trim_left(text.substr(cut)));
    if (!is_number(number)) return;
    const int value = digits_of(number);
    if (op == "greater") {
        look.alpha = Alpha::kMask;
        look.cutoff = (static_cast<float>(value) + 0.5F) / 255.0F;
    }
    if (op == "greater_equal") {
        look.alpha = Alpha::kMask;
        look.cutoff = (static_cast<float>(value) - 0.5F) / 255.0F;
    }
}

// ColorX4 thắng ColorX2. Tên mẫu không có trong all.material vẫn mang hệ số (TwoTex_Tex2_ColorX4).
void note_gain(MaterialLook& look, std::string_view name) {
    if (name.contains("ColorX4")) look.gain = 4.0F;
    const bool raises = name.contains("ColorX2");
    const bool below = look.gain < 4.0F;
    const bool doubles = raises && below;
    if (doubles) look.gain = 2.0F;
}

// scene_blend add và "one one" là cộng sáng (one, one). Không để alpha_rejection ghi đè sau đó.
void paint_blend(MaterialLook& look, std::string_view blend) {
    if (blend.empty()) return;
    const bool named_add = blend == "add";
    const bool factor_add = blend == "one one";
    const bool is_add = named_add || factor_add;
    if (is_add) look.alpha = Alpha::kAdd;
    if (is_add) return;
    const bool is_plain = is_plain_blend(blend);
    look.alpha = is_plain ? Alpha::kOpaque : Alpha::kBlend;
}

void paint_rule(MaterialLook& look, const MaterialRule& rule) {
    if (!rule.texture.empty()) look.texture = rule.texture;
    if (!rule.scroll.empty()) look.scroll = rule.scroll;
    if (rule.no_fog) look.no_fog = true;
    note_gain(look, rule.parent);
    if (rule.has_scroll) {
        look.scroll_u = rule.scroll_u;
        look.scroll_v = rule.scroll_v;
        look.has_scroll = true;
    }
    if (rule.has_offset) {
        look.offset_u = rule.offset_u;
        look.offset_v = rule.offset_v;
        look.has_offset = true;
    }
    paint_blend(look, rule.blend);
    const bool stays_add = look.alpha == Alpha::kAdd;
    const bool has_cut = !rule.rejection.empty();
    const bool open_blend = rule.blend.empty();
    const bool rejects = open_blend && has_cut && !stays_add;
    if (rejects) apply_rejection(look, rule.rejection);
    if (!rule.cull.empty()) look.double_sided = rule.cull == "none";
    if (!rule.lighting.empty()) look.unlit = rule.lighting == "off";
}

// Mesh một UV: scroll tĩnh và scroll_anim kéo cả mặt nạ lẫn ảnh sáng. Ảnh sáng là màu, mặt nạ giữ
// chỗ cũ.
void use_scroll(MaterialLook& look) {
    const bool is_add = look.alpha == Alpha::kAdd;
    const bool has_glow = !look.scroll.empty();
    const bool scrolls = is_add && has_glow;
    if (!scrolls) return;
    look.mask = look.texture;
    look.texture = look.scroll;
}

[[nodiscard]] MaterialLook look_of(std::string_view root, const std::string& material,
    const std::string& alias) {
    MaterialLook look;
    if (!root.empty() && !material.empty()) {
        note_gain(look, material);
        const std::shared_ptr<const MaterialTable> table = table_of(root);
        const MaterialRule* chain[8] = {};
        int count = 0;
        std::string name = material;
        while (count < 8 && !name.empty()) {
            const auto found = table->index.find(name);
            if (found == table->index.end()) break;
            const MaterialRule* rule = &table->rules[found->second].second;
            chain[count] = rule;
            ++count;
            name = rule->parent;
        }
        for (int index = count - 1; index >= 0; --index)
            paint_rule(look, *chain[index]);
        // Mẫu như Mtl_Model_Transperant_NoLight không có thân trong all.material. Tên nói
        // chất liệu trong suốt và không thắp sáng: suối pubu dùng mẫu này.
        // scene_blend add không bị nhánh trong suốt ghi đè: tấm thú cưỡi phải cộng sáng.
        if (!name.empty() && name.contains("NoLight")) look.unlit = true;
        note_gain(look, name);
        const bool is_clear = name.contains("Transperant") || name.contains("Transparent");
        const bool stays_add = look.alpha == Alpha::kAdd;
        const bool named = !name.empty();
        const bool clear_named = named && is_clear;
        const bool paints_clear = clear_named && !stays_add;
        if (paints_clear) look.alpha = Alpha::kBlend;
        use_scroll(look);
    }
    const bool is_add = look.alpha == Alpha::kAdd;
    const bool has_glow = !look.scroll.empty();
    const bool keeps_glow = is_add && has_glow;
    const bool takes_alias = !alias.empty() && !keeps_glow;
    if (takes_alias) look.texture = alias;
    return look;
}

// all.material của client gốc ghi đường dẫn bằng GBK. fs mở tệp bằng UTF-8. Để nguyên thì
// tệp không mở được và shader nhận ảnh trắng thay cho vỏ cây, đá, lá (trên Android và iOS trước
// khi có core::utf8_from_gbk: mọi ảnh dưới thư mục tên chữ Hán). Không phải GBK thì giữ nguyên.
[[nodiscard]] std::string utf8_path(std::string_view stored) {
    if (stored.empty() || core::is_valid_utf8(stored)) return std::string(stored);
    return core::utf8_from_gbk(stored).value_or(std::string(stored));
}

// Thiếu tệp thì bỏ qua, cùng hợp đồng cũ: một ảnh hỏng không làm rơi cả mesh.
[[nodiscard]] bool attach_slot(Model& model, TexSlot& slot, std::string_view root,
    const std::string& texture, TextureTier tier) {
    const bool skips = texture.empty() || root.empty();
    if (skips) return true;
    std::string relative = utf8_path(texture);
    std::ranges::replace(relative, '\\', '/');
    const std::string folder = std::string("Material/") + relative;
    const std::string path = texture_file(root, folder, tier);
    auto bytes = fs::read_file(path);
    if (!bytes) return true;
    auto image = read_stored(bytes->span());
    if (!image) return true;
    image->name = relative;
    slot.image = static_cast<std::uint32_t>(model.images.size());
    model.images.push_back(std::move(*image));
    return true;
}

void paint_gain(Material& material, float gain) {
    if (gain == 1.0F) return;
    material.base_color.x = gain;
    material.base_color.y = gain;
    material.base_color.z = gain;
    material.base_color.w = 1.0F;
}

// scroll_anim nằm ở emissive.xy: shader không đèn cộng nó vào UV. Tấm add buộc không đèn
// để tốc độ ấy chạy dù script không khai lighting off.
void apply_look(Material& material, const MaterialLook& look) {
    material.alpha = look.alpha;
    material.alpha_cutoff = look.cutoff;
    material.double_sided = look.double_sided;
    const bool is_add = look.alpha == Alpha::kAdd;
    material.unlit = look.unlit || is_add;
    material.suppress_fog = look.no_fog;
    paint_gain(material, look.gain);
    if (!look.has_scroll) return;
    material.emissive.x = look.scroll_u;
    material.emissive.y = look.scroll_v;
    material.emissive.z = 0.0F;
}

// Cache ghi tên ảnh màu. Tấm add lấy lại scrollTex từ script, kể cả khi ô cache bị sửa.
[[nodiscard]] std::string color_name(const MaterialLook& look, const std::string& stored) {
    const bool is_add = look.alpha == Alpha::kAdd;
    const bool has_glow = !look.scroll.empty();
    const bool keeps_glow = is_add && has_glow;
    const bool from_script = keeps_glow || stored.empty();
    if (from_script) return look.texture;
    return stored;
}

[[nodiscard]] bool bind_look(Model& model, Material& material, std::string_view root,
    const MaterialLook& look, const std::string& color, TextureTier tier) {
    apply_look(material, look);
    const bool color_ok = attach_slot(model, material.color, root, color, tier);
    if (!color_ok) return false;
    return attach_slot(model, material.surface, root, look.mask, tier);
}

void shift_uv(std::vector<Vertex>& vertices, float along_u, float along_v) {
    for (Vertex& vertex : vertices) {
        vertex.uv.x += along_u;
        vertex.uv.y += along_v;
    }
}

[[nodiscard]] core::Result<Model> build_model(const RawMesh& raw, std::string_view root, TextureTier tier) {
    if (!raw.has_shared && raw.submeshes.empty()) return corrupt("mesh không có hình học");
    Model model;
    Mesh mesh;
    for (const Submesh& submesh : raw.submeshes) {
        const Geometry* geometry = submesh.has_geometry ? &submesh.geometry : nullptr;
        if (submesh.uses_shared) geometry = raw.has_shared ? &raw.shared : nullptr;
        if (geometry == nullptr || submesh.indices.empty()) continue;
        Primitive primitive;
        if (!fill_vertices(*geometry, primitive.vertices)) return corrupt("đỉnh mesh hỏng");
        const std::vector<Weight>& weights = submesh.uses_shared ? raw.shared_weights : submesh.weights;
        apply_weights(weights, primitive.vertices);
        for (const std::uint32_t index : submesh.indices) {
            if (index >= primitive.vertices.size()) return corrupt("chỉ số mesh ngoài đỉnh");
        }
        primitive.indices = submesh.indices;
        Material material;
        material.name = submesh.material;
        material.metallic = 0.0F;
        material.roughness = 1.0F;
        const MaterialLook look = look_of(root, submesh.material, submesh.texture);
        if (look.has_offset) shift_uv(primitive.vertices, look.offset_u, look.offset_v);
        const bool bound = bind_look(model, material, root, look, look.texture, tier);
        if (!bound) return corrupt("ảnh mesh hỏng");
        primitive.material = static_cast<std::uint32_t>(model.materials.size());
        model.materials.push_back(std::move(material));
        mesh.primitives.push_back(std::move(primitive));
    }
    if (mesh.primitives.empty()) return corrupt("mesh không có tam giác");
    model.meshes.push_back(std::move(mesh));
    return model;
}

[[nodiscard]] core::Result<RawMesh> parse_mesh(std::span<const std::byte> bytes) {
    Cursor cursor{bytes};
    std::uint16_t header = 0;
    if (!cursor.u16(header) || header != kHeader) return corrupt("không phải tệp mesh OGRE");
    std::string version;
    if (!cursor.line(version)) return corrupt("mesh cụt");
    const bool known = version == "[MeshSerializer_v1.40]" || version == "[MeshSerializer_v1.30]";
    if (!known) return core::fail(core::ErrorCode::kUnsupported, "phiên bản mesh lạ");
    if (!cursor.begin(kMesh)) return corrupt("mesh sai chunk");
    std::uint8_t animated = 0;
    if (!cursor.u8(animated)) return corrupt("mesh cụt");
    RawMesh mesh;
    std::uint16_t id = 0;
    while (cursor.peek_id(id)) {
        if (!read_mesh_chunk(cursor, id, mesh)) break;
    }
    if (cursor.error != nullptr) return corrupt("mesh hỏng");
    return mesh;
}

void put_u32(std::vector<std::byte>& out, std::uint32_t value) {
    const auto* bytes = reinterpret_cast<const std::byte*>(&value);
    out.insert(out.end(), bytes, bytes + 4);
}

[[nodiscard]] bool take_u32(std::span<const std::byte>& rest, std::uint32_t& out) noexcept {
    if (rest.size() < 4) return false;
    std::memcpy(&out, rest.data(), 4);
    rest = rest.subspan(4);
    return true;
}

[[nodiscard]] std::string cache_file(std::string_view root, std::string_view mesh_file) {
    const std::string model = fs::join(root, "Model");
    std::string relative = std::string(mesh_file);
    if (relative.starts_with(model)) relative.erase(0, model.size());
    while (!relative.empty() && (relative.front() == '/' || relative.front() == '\\'))
        relative.erase(relative.begin());
    return fs::join(fs::join(root, "cache/mesh"), relative + ".tlms");
}

void note_lane(std::uint16_t& highest, bool& weighted, std::uint16_t joint, float weight) noexcept {
    if (!(weight > 0.0F)) return;
    weighted = true;
    if (joint > highest) highest = joint;
}

void note_vertex(std::uint16_t& highest, bool& weighted, const Vertex& vertex) noexcept {
    for (std::uint8_t lane = 0; lane < 4; ++lane)
        note_lane(highest, weighted, vertex.joints[lane], vertex.weights[lane]);
}

void note_primitive(std::uint16_t& highest, bool& weighted, const Primitive& primitive) noexcept {
    for (const Vertex& vertex : primitive.vertices)
        note_vertex(highest, weighted, vertex);
}

// Chỉ số khớp trên đỉnh là handle xương OGRE. Trần để một chỉ số rác không xin hàng nghìn ma trận.
constexpr std::uint16_t kJointCeiling = 1024;

// Mesh có trọng số mà không có skin thì shader để đỉnh ở tư thế bind: nhân vật đứng T-pose.
// Bảng khớp 0..handle cao nhất, đúng thứ tự ma trận skin theo handle mà Skinner đưa.
void ensure_skin(Model& model) {
    if (model.meshes.empty() || !model.skins.empty() || model.nodes.empty()) return;
    bool weighted = false;
    std::uint16_t highest = 0;
    for (const Primitive& primitive : model.meshes.front().primitives)
        note_primitive(highest, weighted, primitive);
    if (!weighted || highest > kJointCeiling) return;
    Skin skin;
    skin.name = "ogre";
    const std::size_t count = static_cast<std::size_t>(highest) + 1U;
    skin.joints.resize(count);
    for (std::size_t index = 0; index < count; ++index)
        skin.joints[index] = static_cast<std::uint32_t>(index);
    model.skins.push_back(std::move(skin));
    model.nodes.front().skin = 0;
}

// Mesh OGRE tĩnh không có nút. Bộ vẽ chỉ đi theo nút, nên thiếu nút thì mesh nạp xong mà không
// thành vật thể (hộp bao rỗng). Một nút gốc đơn vị trỏ vào lưới 0.
void ensure_static_root(Model& model) {
    if (model.meshes.empty() || !model.nodes.empty()) return;
    Node node;
    node.name = "mesh";
    node.local = math::Matrix4::identity();
    node.mesh = 0;
    model.nodes.push_back(std::move(node));
    model.roots.push_back(0);
}

[[nodiscard]] bool cache_fresh(std::string_view source, std::string_view cache) {
    if (!fs::is_file(cache)) return false;
    // Gói điện thoại (APK, iOS) chỉ mang cache đã nấu, không mang .mesh nguồn: nguồn vắng thì cache
    // là bản duy nhất.
    if (!fs::is_file(source)) return true;
    const auto source_time = fs::last_write(source);
    const auto cache_time = fs::last_write(cache);
    if (!source_time || !cache_time) return false;
    return *cache_time >= *source_time;
}

[[nodiscard]] core::Result<std::vector<std::byte>> encode_vertices(const std::vector<Vertex>& vertices) {
    const std::size_t bound = meshopt_encodeVertexBufferBound(vertices.size(), sizeof(Vertex));
    std::vector<std::byte> out(bound);
    const std::size_t written =
        meshopt_encodeVertexBuffer(reinterpret_cast<unsigned char*>(out.data()), out.size(),
            vertices.data(), vertices.size(), sizeof(Vertex));
    if (written == 0) return core::fail(core::ErrorCode::kCorrupt, "nén đỉnh thất bại");
    out.resize(written);
    return out;
}

[[nodiscard]] core::Result<std::vector<std::byte>> encode_indices(const std::vector<std::uint32_t>& indices,
    std::size_t vertex_count) {
    const std::size_t bound = meshopt_encodeIndexBufferBound(indices.size(), vertex_count);
    std::vector<std::byte> out(bound);
    const std::size_t written = meshopt_encodeIndexBuffer(reinterpret_cast<unsigned char*>(out.data()), out.size(),
        indices.data(), indices.size());
    if (written == 0 && !indices.empty()) return core::fail(core::ErrorCode::kCorrupt, "nén chỉ số thất bại");
    out.resize(written);
    return out;
}

// Bản 2: số mức rồi từng mức (số chỉ số, số byte, chỉ số nén cùng cách với mức 0).
[[nodiscard]] core::Status put_lods(std::vector<std::byte>& out, const Primitive& primitive) {
    put_u32(out, static_cast<std::uint32_t>(primitive.lods.size()));
    for (const std::vector<std::uint32_t>& level : primitive.lods) {
        auto packed = encode_indices(level, primitive.vertices.size());
        if (!packed) return std::unexpected(packed.error());
        put_u32(out, static_cast<std::uint32_t>(level.size()));
        put_u32(out, static_cast<std::uint32_t>(packed->size()));
        out.insert(out.end(), packed->begin(), packed->end());
    }
    return {};
}

[[nodiscard]] core::Result<std::vector<std::byte>> encode_model(const Model& model) {
    std::vector<std::byte> out;
    out.insert(out.end(), reinterpret_cast<const std::byte*>(kCacheMagic),
        reinterpret_cast<const std::byte*>(kCacheMagic) + 4);
    put_u32(out, kCacheVersion);
    if (model.meshes.empty()) return corrupt("mesh rỗng");
    put_u32(out, static_cast<std::uint32_t>(model.meshes[0].primitives.size()));
    // 1: build_lods đã chạy, mức rỗng là primitive không giảm được; 0: chưa tính.
    put_u32(out, model.has_lods ? 1U : 0U);
    for (const Primitive& primitive : model.meshes[0].primitives) {
        const Material* material =
            primitive.material ? &model.materials[*primitive.material] : nullptr;
        const std::string name = material != nullptr ? material->name : std::string{};
        const bool has_image = material != nullptr && material->color.image.has_value();
        const std::string texture =
            has_image ? model.images[*material->color.image].name : std::string{};
        put_u32(out, static_cast<std::uint32_t>(name.size()));
        out.insert(out.end(), reinterpret_cast<const std::byte*>(name.data()),
            reinterpret_cast<const std::byte*>(name.data()) + name.size());
        put_u32(out, static_cast<std::uint32_t>(texture.size()));
        out.insert(out.end(), reinterpret_cast<const std::byte*>(texture.data()),
            reinterpret_cast<const std::byte*>(texture.data()) + texture.size());
        put_u32(out, static_cast<std::uint32_t>(primitive.vertices.size()));
        put_u32(out, static_cast<std::uint32_t>(primitive.indices.size()));
        auto vertices = encode_vertices(primitive.vertices);
        if (!vertices) return std::unexpected(vertices.error());
        auto indices = encode_indices(primitive.indices, primitive.vertices.size());
        if (!indices) return std::unexpected(indices.error());
        put_u32(out, static_cast<std::uint32_t>(vertices->size()));
        put_u32(out, static_cast<std::uint32_t>(indices->size()));
        out.insert(out.end(), vertices->begin(), vertices->end());
        out.insert(out.end(), indices->begin(), indices->end());
        const core::Status lods = put_lods(out, primitive);
        if (!lods) return std::unexpected(lods.error());
    }
    return out;
}

struct MeshAsk {
    std::string_view data_root;
    TextureTier tier = TextureTier::kBc;
    LodUse lods = LodUse::kDrop;
};

// meshopt không kiểm chỉ số giải ra có nằm trong đỉnh: cache hỏng không được thành đọc vượt
// buffer đỉnh trên GPU.
[[nodiscard]] bool indices_inside(std::span<const std::uint32_t> indices,
    std::size_t vertex_count) {
    const auto outside = [vertex_count](std::uint32_t index) { return index >= vertex_count; };
    return std::ranges::none_of(indices, outside);
}

// Một mức của primitive; keep sai thì chỉ nhảy qua. Mức thô không dài hơn mức 0.
[[nodiscard]] bool take_level(std::span<const std::byte>& rest, Primitive& primitive, bool keep) {
    std::uint32_t index_count = 0;
    std::uint32_t packed = 0;
    if (!take_u32(rest, index_count) || !take_u32(rest, packed)) return false;
    const bool fits = index_count <= primitive.indices.size() && index_count % 3 == 0;
    if (!fits || packed > rest.size()) return false;
    const std::span<const std::byte> data = rest.first(packed);
    rest = rest.subspan(packed);
    if (!keep) return true;
    std::vector<std::uint32_t> level(index_count);
    const auto* source = reinterpret_cast<const unsigned char*>(data.data());
    const std::size_t stride = sizeof(std::uint32_t);
    const int failed = meshopt_decodeIndexBuffer(level.data(), index_count, stride, source, packed);
    if (failed != 0) return false;
    if (!indices_inside(level, primitive.vertices.size())) return false;
    primitive.lods.push_back(std::move(level));
    return true;
}

[[nodiscard]] bool take_lods(std::span<const std::byte>& rest, Primitive& primitive, bool keep) {
    std::uint32_t count = 0;
    if (!take_u32(rest, count) || count > kMaxCacheLods) return false;
    for (std::uint32_t level = 0; level < count; ++level) {
        if (!take_level(rest, primitive, keep)) return false;
    }
    return true;
}

[[nodiscard]] std::uint32_t version_of(std::span<const std::byte> bytes) noexcept {
    std::span<const std::byte> rest = bytes.subspan(std::min<std::size_t>(bytes.size(), 4));
    std::uint32_t version = 0;
    if (!take_u32(rest, version)) return 0;
    return version;
}

[[nodiscard]] core::Result<Model> decode_model(std::span<const std::byte> bytes,
    const MeshAsk& ask) {
    const std::string_view data_root = ask.data_root;
    const TextureTier tier = ask.tier;
    if (bytes.size() < 8) return corrupt("cache mesh cụt");
    const bool magic = bytes[0] == std::byte{'T'} && bytes[1] == std::byte{'L'} && bytes[2] == std::byte{'M'} &&
        bytes[3] == std::byte{'S'};
    if (!magic) return corrupt("cache mesh sai");
    std::span<const std::byte> rest = bytes.subspan(4);
    std::uint32_t version = 0;
    std::uint32_t count = 0;
    if (!take_u32(rest, version) || !take_u32(rest, count)) return corrupt("cache mesh cụt");
    const bool has_levels = version == kCacheVersion;
    if (!has_levels && version != kPlainCacheVersion) return corrupt("cache mesh khác bản");
    std::uint32_t lod_flag = 0;
    if (has_levels && !take_u32(rest, lod_flag)) return corrupt("cache mesh cụt");
    const bool keeps = ask.lods == LodUse::kKeep && lod_flag == 1;
    Model model;
    model.has_lods = keeps;
    Mesh mesh;
    for (std::uint32_t index = 0; index < count; ++index) {
        std::uint32_t name_size = 0;
        std::uint32_t vertex_count = 0;
        std::uint32_t index_count = 0;
        std::uint32_t vertex_bytes = 0;
        std::uint32_t index_bytes = 0;
        if (!take_u32(rest, name_size) || name_size > rest.size()) return corrupt("cache mesh cụt");
        Material material;
        material.name.assign(reinterpret_cast<const char*>(rest.data()), name_size);
        material.metallic = 0.0F;
        material.roughness = 1.0F;
        rest = rest.subspan(name_size);
        std::uint32_t texture_size = 0;
        if (!take_u32(rest, texture_size) || texture_size > rest.size()) return corrupt("cache mesh cụt");
        const std::string stored(reinterpret_cast<const char*>(rest.data()), texture_size);
        rest = rest.subspan(texture_size);
        const MaterialLook look = look_of(data_root, material.name, stored);
        const std::string chosen = color_name(look, stored);
        const bool bound = bind_look(model, material, data_root, look, chosen, tier);
        if (!bound) return corrupt("ảnh mesh hỏng");
        if (!take_u32(rest, vertex_count) || !take_u32(rest, index_count)) return corrupt("cache mesh cụt");
        if (!take_u32(rest, vertex_bytes) || !take_u32(rest, index_bytes)) return corrupt("cache mesh cụt");
        if (vertex_bytes > rest.size() || index_bytes > rest.size() - vertex_bytes) return corrupt("cache mesh cụt");
        const bool fits = vertex_count <= kMaxCacheVertices && index_count <= kMaxCacheIndices;
        if (!fits || index_count % 3 != 0) return corrupt("cache mesh quá cỡ");
        Primitive primitive;
        primitive.vertices.resize(vertex_count);
        primitive.indices.resize(index_count);
        const int vertices = meshopt_decodeVertexBuffer(primitive.vertices.data(), vertex_count, sizeof(Vertex),
            reinterpret_cast<const unsigned char*>(rest.data()), vertex_bytes);
        rest = rest.subspan(vertex_bytes);
        const int indices =
            meshopt_decodeIndexBuffer(primitive.indices.data(), index_count, sizeof(std::uint32_t),
                reinterpret_cast<const unsigned char*>(rest.data()), index_bytes);
        rest = rest.subspan(index_bytes);
        if (vertices != 0 || indices != 0) return corrupt("cache mesh hỏng");
        if (!indices_inside(primitive.indices, vertex_count)) return corrupt("cache mesh hỏng");
        if (has_levels && !take_lods(rest, primitive, keeps)) return corrupt("cache mesh cụt");
        primitive.material = static_cast<std::uint32_t>(model.materials.size());
        model.materials.push_back(std::move(material));
        mesh.primitives.push_back(std::move(primitive));
    }
    model.meshes.push_back(std::move(mesh));
    return model;
}

void store_cache(std::string_view path, const Model& model) {
    auto encoded = encode_model(model);
    if (!encoded) return;
    const std::string folder(fs::parent(path));
    if (!folder.empty()) static_cast<void>(fs::create_directories(folder));
    static_cast<void>(fs::write_file_atomic(path, *encoded));
}

[[nodiscard]] bool ends_ci(std::string_view text, std::string_view suffix) noexcept {
    if (text.size() < suffix.size()) return false;
    const std::string_view tail = text.substr(text.size() - suffix.size());
    for (std::size_t index = 0; index < suffix.size(); ++index) {
        unsigned char left = static_cast<unsigned char>(tail[index]);
        if (left >= 'A' && left <= 'Z') left = static_cast<unsigned char>(left - 'A' + 'a');
        if (left != static_cast<unsigned char>(suffix[index])) return false;
    }
    return true;
}

// Cache còn mới và đọc được thì dùng. Cache bản 1 coi như cũ khi còn .mesh gốc để nấu lại thành
// bản có mức chi tiết; gói điện thoại không mang .mesh nên vẫn dùng bản 1 nếu chỉ có nó.
[[nodiscard]] std::optional<Model> cached_model(const std::string& direct, const std::string& cache,
    const MeshAsk& ask) {
    if (!cache_fresh(direct, cache)) return std::nullopt;
    auto stored = fs::read_file(cache);
    if (!stored) return std::nullopt;
    const bool is_plain = version_of(stored->span()) == kPlainCacheVersion;
    if (is_plain && fs::is_file(direct)) return std::nullopt;
    auto decoded = decode_model(stored->span(), ask);
    if (!decoded) return std::nullopt;
    ensure_static_root(*decoded);
    ensure_skin(*decoded);
    return std::move(*decoded);
}

// Nấu .mesh gốc. Cache ghi kèm mức chi tiết của build_lods: cùng đỉnh và chỉ số cho cùng kết quả,
// nên máy chạy đọc mức sẵn thay vì giản lược (đo 2026-10-17 trên TB-X306F: giản lược là 51% CPU
// của luồng nạp).
[[nodiscard]] core::Result<Model> cooked_model(const std::string& direct, const std::string& cache,
    const MeshAsk& ask) {
    auto bytes = fs::read_file(direct);
    if (!bytes) return std::unexpected(bytes.error());
    auto model = load_ogre_mesh(bytes->span(), ask.data_root, ask.tier);
    if (!model) return model;
    ensure_static_root(*model);
    ensure_skin(*model);
    build_lods(*model);
    store_cache(cache, *model);
    if (ask.lods == LodUse::kDrop) drop_lods(*model);
    return model;
}

[[nodiscard]] core::Result<Model> load_mesh_file(const std::string& direct, const MeshAsk& ask) {
    const std::string cache = cache_file(ask.data_root, direct);
    std::optional<Model> cached = cached_model(direct, cache, ask);
    if (cached) return std::move(*cached);
    return cooked_model(direct, cache, ask);
}

void assign_material(Submesh& submesh, std::string_view name) {
    if (name.empty()) return;
    submesh.material.assign(name.begin(), name.end());
}

void assign_one(RawMesh& raw, std::span<const std::string> names, std::size_t index) {
    if (index >= raw.submeshes.size()) return;
    if (index >= names.size()) return;
    assign_material(raw.submeshes[index], names[index]);
}

void assign_materials(RawMesh& raw, std::span<const std::string> names) {
    for (std::size_t index = 0; index < raw.submeshes.size(); ++index)
        assign_one(raw, names, index);
}

} // namespace

core::Result<Model> load_ogre_mesh(std::span<const std::byte> bytes, std::string_view data_root,
    TextureTier tier) {
    auto raw = parse_mesh(bytes);
    if (!raw) return std::unexpected(raw.error());
    return build_model(*raw, data_root, tier);
}

core::Result<Model> load_named_model(std::string_view name, std::string_view data_root,
    TextureTier tier, LodUse lods) {
    if (name.empty()) return core::fail(core::ErrorCode::kInvalidArgument, "tên mesh rỗng");
    const std::string direct = fs::join(fs::join(data_root, "Model"), name);
    const MeshAsk ask{.data_root = data_root, .tier = tier, .lods = lods};
    if (ends_ci(name, ".mesh")) return load_mesh_file(direct, ask);
    if (ends_ci(name, ".glb")) return load_glb_file(direct, data_root, tier);
    const std::string as_mesh = direct + ".mesh";
    const std::string mesh_name = std::string(name) + ".mesh";
    if (fs::is_file(as_mesh)) return load_named_model(mesh_name, data_root, tier, lods);
    const std::string as_glb = direct + ".glb";
    if (fs::is_file(as_glb)) return load_glb_file(as_glb, data_root, tier);
    return core::fail(core::ErrorCode::kNotFound, "không có mesh");
}

core::Result<Model> load_mesh_painted(std::string_view name, std::string_view data_root,
    std::span<const std::string> materials, TextureTier tier) {
    if (materials.empty()) return load_named_model(name, data_root, tier);
    if (name.empty()) return core::fail(core::ErrorCode::kInvalidArgument, "tên mesh rỗng");
    const std::string folder = fs::join(data_root, "Model");
    const std::string direct = fs::join(folder, name);
    auto bytes = fs::read_file(direct);
    if (!bytes) return std::unexpected(bytes.error());
    auto raw = parse_mesh(bytes->span());
    if (!raw) return std::unexpected(raw.error());
    assign_materials(*raw, materials);
    auto model = build_model(*raw, data_root, tier);
    if (!model) return model;
    ensure_static_root(*model);
    ensure_skin(*model);
    return model;
}

} // namespace game::resource
