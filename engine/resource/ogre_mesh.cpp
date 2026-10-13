// Bộ đọc theo TOOLS/glb/ogre_mesh.py: độ dài chunk M_MESH của client sai, nên chỉ dùng độ dài
// để nhảy qua edge list, pose, animation và extremes. Gán xương là bản ghi 16 byte xếp khít.
#include "resource/ogre_mesh.hpp"

#include "core/text.hpp"
#include "core/win32.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "resource/dds.hpp"
#include "resource/image.hpp"

#if defined(_WIN32)
#include <windows.h>
#endif

#include <meshoptimizer.h>

#include <array>
#include <charconv>
#include <cstdint>
#include <cstring>
#include <limits>
#include <mutex>
#include <string>
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
constexpr std::uint32_t kCacheVersion = 1;
constexpr char kCacheMagic[4] = {'T', 'L', 'M', 'S'};

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
        while (found != end && *found != std::byte{'\n'}) ++found;
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
    if (submesh.has_operation && submesh.operation != kTriangleList) return cursor.fail("mesh không phải danh sách tam giác");
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
    if (element.semantic == kDiffuse && (element.type == kColour || element.type == kColourArgb || element.type == kColourAbgr)) {
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
};

struct MaterialLook {
    std::string texture;
    Alpha alpha = Alpha::kOpaque;
    float cutoff = 0.5F;
    float scroll_u = 0.0F;
    float scroll_v = 0.0F;
    float offset_u = 0.0F;
    float offset_v = 0.0F;
    bool double_sided = false;
    bool unlit = false;
    bool has_scroll = false;
    bool has_offset = false;
};

using MaterialRules = std::vector<std::pair<std::string, MaterialRule>>;

[[nodiscard]] std::string_view trim_left(std::string_view line) noexcept {
    while (!line.empty() && (line.front() == ' ' || line.front() == '\t')) line.remove_prefix(1);
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
    const bool lower = line.find("<baseTexture>") != std::string_view::npos;
    const bool upper = line.find("<BaseTexture>") != std::string_view::npos;
    return lower || upper;
}

[[nodiscard]] const MaterialRules& rules_of(std::string_view root) {
    static MaterialRules rules;
    static std::string loaded;
    const std::string key(root);
    if (loaded == key) return rules;
    loaded = key;
    rules.clear();
    const std::string path = fs::join(fs::join(root, "Material"), "all.material");
    auto bytes = fs::read_file(path);
    if (!bytes) return rules;
    const std::string text(reinterpret_cast<const char*>(bytes->span().data()), bytes->span().size());
    std::size_t at = 0;
    while (at < text.size()) {
        const std::size_t end = text.find('\n', at);
        const std::string_view raw = std::string_view(text).substr(at, (end == std::string::npos ? text.size() : end) - at);
        at = end == std::string::npos ? text.size() : end + 1;
        std::string_view line = trim_left(raw);
        if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
        const std::size_t comment = line.find("//");
        if (comment != std::string_view::npos) line = trim_left(line.substr(0, comment));
        if (line.empty()) continue;
        if (line.starts_with("material ")) {
            std::string_view rest = trim_left(line.substr(9));
            const std::size_t colon = rest.find(':');
            std::string name(colon == std::string_view::npos ? first_token(rest) : trim_left(rest.substr(0, colon)));
            while (!name.empty() && (name.back() == ' ' || name.back() == '\t')) name.pop_back();
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
            set_field(rules.back().second.lighting, std::string(first_token(trim_left(line.substr(9)))));
        }
    }
    return rules;
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
    for (const char item : text) value = value * 10 + (item - '0');
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

void paint_rule(MaterialLook& look, const MaterialRule& rule) {
    if (!rule.texture.empty()) look.texture = rule.texture;
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
    if (!rule.blend.empty()) look.alpha = is_plain_blend(rule.blend) ? Alpha::kOpaque : Alpha::kBlend;
    if (rule.blend.empty() && !rule.rejection.empty()) apply_rejection(look, rule.rejection);
    if (!rule.cull.empty()) look.double_sided = rule.cull == "none";
    if (!rule.lighting.empty()) look.unlit = rule.lighting == "off";
}

[[nodiscard]] MaterialLook look_of(std::string_view root, const std::string& material, const std::string& alias) {
    MaterialLook look;
    if (!root.empty() && !material.empty()) {
        static std::mutex gate;
        const std::lock_guard<std::mutex> lock(gate);
        const MaterialRules& rules = rules_of(root);
        const MaterialRule* chain[8] = {};
        int count = 0;
        std::string name = material;
        while (count < 8 && !name.empty()) {
            const MaterialRule* rule = nullptr;
            for (const auto& item : rules) {
                if (item.first == name) rule = &item.second;
            }
            if (rule == nullptr) break;
            chain[count] = rule;
            ++count;
            name = rule->parent;
        }
        for (int index = count - 1; index >= 0; --index) paint_rule(look, *chain[index]);
        // Mẫu như Mtl_Model_Transperant_NoLight không có thân trong all.material. Tên nói
        // chất liệu trong suốt và không thắp sáng: suối pubu dùng mẫu này.
        if (!name.empty() && name.find("NoLight") != std::string::npos) look.unlit = true;
        const bool is_clear = name.find("Transperant") != std::string::npos || name.find("Transparent") != std::string::npos;
        if (!name.empty() && is_clear) look.alpha = Alpha::kBlend;
    }
    if (!alias.empty()) look.texture = alias;
    return look;
}

// all.material của client gốc ghi đường dẫn bằng GBK. fs mở tệp bằng UTF-8. Để nguyên thì
// CreateFileW trượt và shader nhận ảnh trắng thay cho vỏ cây, đá, lá.
[[nodiscard]] std::string utf8_path(std::string_view stored) {
    if (stored.empty() || core::is_valid_utf8(stored)) return std::string(stored);
#if defined(_WIN32)
    const int bytes = static_cast<int>(stored.size());
    const int wide_count = MultiByteToWideChar(936, MB_ERR_INVALID_CHARS, stored.data(), bytes, nullptr, 0);
    if (wide_count <= 0) return std::string(stored);
    std::wstring wide(static_cast<std::size_t>(wide_count), L'\0');
    MultiByteToWideChar(936, MB_ERR_INVALID_CHARS, stored.data(), bytes, wide.data(), wide_count);
    return core::narrow(wide);
#else
    return std::string(stored);
#endif
}

[[nodiscard]] bool attach_texture(Model& model, Material& material, std::string_view root, const std::string& texture,
    TextureTier tier) {
    if (texture.empty() || root.empty()) return true;
    std::string relative = utf8_path(texture);
    for (char& item : relative) {
        if (item == '\\') item = '/';
    }
    const std::string path = texture_file(root, std::string("Material/") + relative, tier);
    auto bytes = fs::read_file(path);
    if (!bytes) return true;
    auto image = read_stored(bytes->span());
    if (!image) return true;
    image->name = relative;
    material.color.image = static_cast<std::uint32_t>(model.images.size());
    model.images.push_back(std::move(*image));
    return true;
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
        material.alpha = look.alpha;
        material.alpha_cutoff = look.cutoff;
        material.double_sided = look.double_sided;
        material.unlit = look.unlit;
        if (look.has_scroll) material.emissive = math::Float3{look.scroll_u, look.scroll_v, 0.0F};
        if (!attach_texture(model, material, root, look.texture, tier)) return corrupt("ảnh mesh hỏng");
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
    while (!relative.empty() && (relative.front() == '/' || relative.front() == '\\')) relative.erase(relative.begin());
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
    const auto source_time = fs::last_write(source);
    const auto cache_time = fs::last_write(cache);
    if (!source_time || !cache_time) return false;
    return *cache_time >= *source_time;
}

[[nodiscard]] core::Result<std::vector<std::byte>> encode_vertices(const std::vector<Vertex>& vertices) {
    const std::size_t bound = meshopt_encodeVertexBufferBound(vertices.size(), sizeof(Vertex));
    std::vector<std::byte> out(bound);
    const std::size_t written = meshopt_encodeVertexBuffer(reinterpret_cast<unsigned char*>(out.data()), out.size(),
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

[[nodiscard]] core::Result<std::vector<std::byte>> encode_model(const Model& model) {
    std::vector<std::byte> out;
    out.insert(out.end(), reinterpret_cast<const std::byte*>(kCacheMagic),
        reinterpret_cast<const std::byte*>(kCacheMagic) + 4);
    put_u32(out, kCacheVersion);
    if (model.meshes.empty()) return corrupt("mesh rỗng");
    put_u32(out, static_cast<std::uint32_t>(model.meshes[0].primitives.size()));
    for (const Primitive& primitive : model.meshes[0].primitives) {
        const Material* material = primitive.material ? &model.materials[*primitive.material] : nullptr;
        const std::string name = material != nullptr ? material->name : std::string{};
        const bool has_image = material != nullptr && material->color.image.has_value();
        const std::string texture = has_image ? model.images[*material->color.image].name : std::string{};
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
    }
    return out;
}

[[nodiscard]] core::Result<Model> decode_model(std::span<const std::byte> bytes, std::string_view data_root,
    TextureTier tier) {
    if (bytes.size() < 8) return corrupt("cache mesh cụt");
    const bool magic = bytes[0] == std::byte{'T'} && bytes[1] == std::byte{'L'} && bytes[2] == std::byte{'M'} &&
        bytes[3] == std::byte{'S'};
    if (!magic) return corrupt("cache mesh sai");
    std::span<const std::byte> rest = bytes.subspan(4);
    std::uint32_t version = 0;
    std::uint32_t count = 0;
    if (!take_u32(rest, version) || version != kCacheVersion || !take_u32(rest, count)) return corrupt("cache mesh cụt");
    Model model;
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
        material.alpha = look.alpha;
        material.alpha_cutoff = look.cutoff;
        material.double_sided = look.double_sided;
        material.unlit = look.unlit;
        const std::string& texture = stored.empty() ? look.texture : stored;
        if (!attach_texture(model, material, data_root, texture, tier)) return corrupt("ảnh mesh hỏng");
        if (!take_u32(rest, vertex_count) || !take_u32(rest, index_count)) return corrupt("cache mesh cụt");
        if (!take_u32(rest, vertex_bytes) || !take_u32(rest, index_bytes)) return corrupt("cache mesh cụt");
        if (vertex_bytes > rest.size() || index_bytes > rest.size() - vertex_bytes) return corrupt("cache mesh cụt");
        Primitive primitive;
        primitive.vertices.resize(vertex_count);
        primitive.indices.resize(index_count);
        const int vertices = meshopt_decodeVertexBuffer(primitive.vertices.data(), vertex_count, sizeof(Vertex),
            reinterpret_cast<const unsigned char*>(rest.data()), vertex_bytes);
        rest = rest.subspan(vertex_bytes);
        const int indices = meshopt_decodeIndexBuffer(primitive.indices.data(), index_count, sizeof(std::uint32_t),
            reinterpret_cast<const unsigned char*>(rest.data()), index_bytes);
        rest = rest.subspan(index_bytes);
        if (vertices != 0 || indices != 0) return corrupt("cache mesh hỏng");
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

} // namespace

core::Result<Model> load_ogre_mesh(std::span<const std::byte> bytes, std::string_view data_root, TextureTier tier) {
    auto raw = parse_mesh(bytes);
    if (!raw) return std::unexpected(raw.error());
    return build_model(*raw, data_root, tier);
}

core::Result<Model> load_named_model(std::string_view name, std::string_view data_root, TextureTier tier) {
    if (name.empty()) return core::fail(core::ErrorCode::kInvalidArgument, "tên mesh rỗng");
    const std::string direct = fs::join(fs::join(data_root, "Model"), name);
    if (ends_ci(name, ".mesh")) {
        const std::string cache = cache_file(data_root, direct);
        if (cache_fresh(direct, cache)) {
            auto stored = fs::read_file(cache);
            if (stored) {
                auto decoded = decode_model(stored->span(), data_root, tier);
                if (decoded) {
                    ensure_static_root(*decoded);
                    ensure_skin(*decoded);
                    return decoded;
                }
            }
        }
        auto bytes = fs::read_file(direct);
        if (!bytes) return std::unexpected(bytes.error());
        auto model = load_ogre_mesh(bytes->span(), data_root, tier);
        if (!model) return model;
        ensure_static_root(*model);
        ensure_skin(*model);
        store_cache(cache, *model);
        return model;
    }
    if (ends_ci(name, ".glb")) return load_glb_file(direct, data_root, tier);
    const std::string as_mesh = direct + ".mesh";
    if (fs::is_file(as_mesh)) return load_named_model(std::string(name) + ".mesh", data_root, tier);
    const std::string as_glb = direct + ".glb";
    if (fs::is_file(as_glb)) return load_glb_file(as_glb, data_root, tier);
    return core::fail(core::ErrorCode::kNotFound, "không có mesh");
}

} // namespace game::resource
