// Dạng nhị phân của phản chiếu shader, phiên bản định dạng 1.
// Mỗi loại phần tử có số byte tối thiểu để Reader::count chặn số phần tử.
// Hai tài nguyên trùng space, loại register và slot được coi là một.
// Nguồn: Forge2 src/shader/reflection.cpp@d7fcd76. Khác gốc: ba vòng for dừng ở lỗi đầu tiên
// (add_stage, merge, check_interface) đi qua hàm chung first_error; thân vòng lặp của renumber và
// merge tách thành hàm (ghi tại chỗ).
#include "shader/reflection.hpp"

#include "fs/codec.hpp"
#include "shader/failure.hpp"
#include "shader/types.hpp"
#include "shader/wire.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <span>
#include <string>
#include <string_view>
#include <tuple>
#include <utility>
#include <vector>

namespace game::shader {

namespace {

using StageRef = const StageReflection&;
using ResourceRef = const Resource&;
using AttributeList = std::vector<Attribute>;

constexpr ErrorCode kBad = ErrorCode::kInvalidArgument;

constexpr std::uint8_t kFormatVersion = 1;

// Số byte ít nhất của một phần tử trong dạng nhị phân; Reader::count dùng để chặn số phần tử.
constexpr std::size_t kLeastResource = 38;
constexpr std::size_t kLeastVariable = 20;
constexpr std::size_t kLeastBlock = 12;
constexpr std::size_t kLeastAttribute = 15;

constexpr std::uint8_t kArrayBit = 1U << 0U;
constexpr std::uint8_t kMultisampleBit = 1U << 1U;
constexpr std::uint8_t kComparisonBit = 1U << 2U;
constexpr std::uint8_t kRawBit = 1U << 3U;

// Chỗ gắn của một tài nguyên: hai tài nguyên trùng chỗ gắn là một.
[[nodiscard]] auto place(const Resource& resource) noexcept {
    return std::tuple(resource.space, register_type(resource.kind), resource.slot);
}

[[nodiscard]] char letter(RegisterType group) noexcept {
    switch (group) {
    case RegisterType::kConstant: return 'b';
    case RegisterType::kResource: return 't';
    case RegisterType::kUnordered: return 'u';
    case RegisterType::kSampler: return 's';
    }
    return '?';
}

[[nodiscard]] std::uint8_t pack_flags(const Resource& resource) noexcept {
    std::uint8_t flags = 0;
    if (resource.array) flags |= kArrayBit;
    if (resource.multisample) flags |= kMultisampleBit;
    if (resource.comparison) flags |= kComparisonBit;
    if (resource.raw) flags |= kRawBit;
    return flags;
}

void write(Writer& out, const Resource& resource);
void write(Writer& out, const Variable& variable);
void write(Writer& out, const Block& block);
void write(Writer& out, const Attribute& attribute);

template <class T>
void write_list(Writer& out, const std::vector<T>& list) {
    out.put(static_cast<std::uint32_t>(list.size()));
    for (const T& item : list) {
        write(out, item);
    }
}

void write(Writer& out, const Resource& resource) {
    out.put_text(resource.name);
    out.put(std::to_underlying(resource.kind));
    out.put(resource.space);
    out.put(resource.slot);
    out.put(resource.binding);
    out.put(resource.count);
    out.put(std::to_underlying(resource.shape));
    out.put(pack_flags(resource));
    out.put(std::to_underlying(resource.sample));
    out.put(resource.image_format);
    out.put(resource.stride);
    out.put(resource.block);
    out.put(resource.stages.bits());
}

void write(Writer& out, const Variable& variable) {
    out.put_text(variable.name);
    out.put(variable.offset);
    out.put(variable.size);
    out.put(std::to_underlying(variable.scalar));
    out.put(variable.bits);
    out.put(variable.rows);
    out.put(variable.columns);
    out.put(variable.elements);
}

void write(Writer& out, const Block& block) {
    out.put_text(block.name);
    out.put(block.size);
    write_list(out, block.variables);
}

void write(Writer& out, const Attribute& attribute) {
    out.put_text(attribute.semantic);
    out.put(attribute.index);
    out.put(attribute.location);
    out.put(std::to_underlying(attribute.scalar));
    out.put(attribute.bits);
    out.put(attribute.components);
}

void write_group(Writer& out, const std::array<std::uint32_t, 3>& group) {
    for (const std::uint32_t size : group) {
        out.put(size);
    }
}

// Giá trị ngoài miền của enum làm hỏng lượt đọc thay vì thành một enumerator không tồn tại.
template <class E>
[[nodiscard]] E read_enum(Reader& reader, E last) noexcept {
    const auto value = reader.get<std::uint8_t>();
    if (value <= std::to_underlying(last)) return static_cast<E>(value);
    reader.fail();
    return last;
}

[[nodiscard]] Resource read_resource(Reader& reader) {
    Resource resource;
    resource.name = reader.get_text();
    resource.kind = read_enum(reader, ResourceKind::kInputAttachment);
    resource.space = reader.get<std::uint32_t>();
    resource.slot = reader.get<std::uint32_t>();
    resource.binding = reader.get<std::uint32_t>();
    resource.count = reader.get<std::uint32_t>();
    resource.shape = read_enum(reader, TextureShape::kCube);
    const auto flags = reader.get<std::uint8_t>();
    resource.array = (flags & kArrayBit) != 0;
    resource.multisample = (flags & kMultisampleBit) != 0;
    resource.comparison = (flags & kComparisonBit) != 0;
    resource.raw = (flags & kRawBit) != 0;
    resource.sample = read_enum(reader, Scalar::kStruct);
    resource.image_format = reader.get<std::uint32_t>();
    resource.stride = reader.get<std::uint32_t>();
    resource.block = reader.get<std::uint32_t>();
    resource.stages = StageSet::from_bits(reader.get<std::uint16_t>());
    return resource;
}

[[nodiscard]] Variable read_variable(Reader& reader) {
    Variable variable;
    variable.name = reader.get_text();
    variable.offset = reader.get<std::uint32_t>();
    variable.size = reader.get<std::uint32_t>();
    variable.scalar = read_enum(reader, Scalar::kStruct);
    variable.bits = reader.get<std::uint8_t>();
    variable.rows = reader.get<std::uint8_t>();
    variable.columns = reader.get<std::uint8_t>();
    variable.elements = reader.get<std::uint32_t>();
    return variable;
}

template <class T, class Read>
[[nodiscard]] std::vector<T> read_list(Reader& reader, std::size_t least, const Read& read) {
    const std::uint32_t count = reader.count(least);
    std::vector<T> list;
    list.reserve(count);
    for (std::uint32_t index = 0; index < count; ++index) {
        list.push_back(read(reader));
    }
    return list;
}

[[nodiscard]] Block read_block(Reader& reader) {
    Block block;
    block.name = reader.get_text();
    block.size = reader.get<std::uint32_t>();
    block.variables = read_list<Variable>(reader, kLeastVariable, read_variable);
    return block;
}

[[nodiscard]] Attribute read_attribute(Reader& reader) {
    Attribute attribute;
    attribute.semantic = reader.get_text();
    attribute.index = reader.get<std::uint32_t>();
    attribute.location = reader.get<std::uint32_t>();
    attribute.scalar = read_enum(reader, Scalar::kStruct);
    attribute.bits = reader.get<std::uint8_t>();
    attribute.components = reader.get<std::uint8_t>();
    return attribute;
}

[[nodiscard]] bool has_block(const std::vector<Block>& blocks, const Resource& resource) noexcept {
    return resource.block == kNoBlock || resource.block < blocks.size();
}

[[nodiscard]] bool blocks_valid(const StageReflection& reflection) noexcept {
    const auto valid = [&](const Resource& resource) { return has_block(reflection.blocks, resource); };
    return std::ranges::all_of(reflection.resources, valid);
}

// Hai khai báo của cùng một chỗ gắn có tả cùng một tài nguyên không. Tên và stage không tính.
[[nodiscard]] bool same_resource(const Resource& left, const Resource& right) noexcept {
    const bool same_type = left.kind == right.kind && left.count == right.count;
    const bool same_texture = left.shape == right.shape && left.array == right.array &&
        left.multisample == right.multisample && left.sample == right.sample;
    const bool same_detail = left.comparison == right.comparison && left.raw == right.raw &&
        left.stride == right.stride && left.image_format == right.image_format;
    return same_type && same_texture && same_detail;
}

[[nodiscard]] const Block* block_of(const std::vector<Block>& blocks, const Resource& resource) {
    if (resource.block == kNoBlock) return nullptr;
    return &blocks.at(resource.block);
}

[[nodiscard]] bool same_block(const Block* left, const Block* right) noexcept {
    if (left == nullptr || right == nullptr) return left == right;
    return left->size == right->size && left->variables == right->variables;
}

[[nodiscard]] Status append(ProgramReflection& program, StageRef stage, const Resource& resource) {
    const auto named = [&](const Resource& other) { return other.name == resource.name; };
    const bool taken = std::ranges::any_of(program.resources, named);
    if (taken) return fail(ErrorCode::kInvalidArgument, "cùng tên mà khác chỗ gắn", resource.name);
    Resource added = resource;
    added.stages = StageSet(stage.stage);
    const Block* block = block_of(stage.blocks, resource);
    if (block != nullptr) {
        added.block = static_cast<std::uint32_t>(program.blocks.size());
        program.blocks.push_back(*block);
    }
    program.resources.push_back(std::move(added));
    return ok();
}

[[nodiscard]] Status add_resource(ProgramReflection& program, StageRef stage, ResourceRef item) {
    const auto placed = [&](const Resource& other) { return place(other) == place(item); };
    const auto found = std::ranges::find_if(program.resources, placed);
    if (found == program.resources.end()) return append(program, stage, item);
    const bool matches = same_resource(*found, item);
    if (!matches) {
        const std::string_view left = found->name;
        const std::string_view right = item.name;
        return fail(kBad, "một chỗ gắn, hai khai báo khác nhau", "{} và {}", left, right);
    }
    const Block* mine = block_of(stage.blocks, item);
    const Block* theirs = block_of(program.blocks, *found);
    if (!same_block(mine, theirs)) {
        return fail(ErrorCode::kInvalidArgument, "cbuffer khác bố cục giữa các stage", found->name);
    }
    found->stages.add(stage.stage);
    return ok();
}

// Khác gốc: gốc viết ba vòng for có câu if (!status) return pass(status) trong thân, ở add_stage,
// merge và check_interface. Ở đây một hàm chung: gọi step cho từng phần tử theo thứ tự, dừng ở lỗi
// đầu tiên và trả lỗi ấy; ok khi không phần tử nào lỗi.
template <class Range, class Step>
[[nodiscard]] Status first_error(const Range& items, const Step& step) {
    Status status = ok();
    auto it = std::ranges::begin(items);
    while (status && it != std::ranges::end(items)) {
        status = step(*it);
        ++it;
    }
    return status;
}

[[nodiscard]] Status add_stage(ProgramReflection& program, const StageReflection& stage) {
    if (program.stages.has(stage.stage)) {
        return fail(ErrorCode::kInvalidArgument, "hai stage trùng loại", tag(stage.stage));
    }
    program.stages.add(stage.stage);
    const auto add = [&](const Resource& item) { return add_resource(program, stage, item); };
    if (Status added = first_error(stage.resources, add); !added) return pass(added);
    if (stage.stage == Stage::kVertex) program.inputs = stage.inputs;
    if (stage.stage == Stage::kPixel) program.outputs = stage.outputs;
    if (stage.stage == Stage::kCompute) program.group_size = stage.group_size;
    if (stage.stage == Stage::kHull) program.control_points = stage.control_points;
    return ok();
}

// Khác gốc: thân vòng lặp của renumber tách ra đây.
void reindex(std::vector<Block>& ordered, const std::vector<Block>& blocks, Resource& resource) {
    if (resource.block == kNoBlock) return;
    ordered.push_back(blocks.at(resource.block));
    resource.block = static_cast<std::uint32_t>(ordered.size() - 1);
}

// Chép các block theo thứ tự tài nguyên đã xếp và đánh lại chỉ số.
void renumber(std::vector<Resource>& resources, std::vector<Block>& blocks) {
    std::vector<Block> ordered;
    ordered.reserve(blocks.size());
    for (Resource& resource : resources) {
        reindex(ordered, blocks, resource);
    }
    blocks = std::move(ordered);
}

// Khác gốc: thân vòng lặp của merge tách ra đây.
[[nodiscard]] Status merge_stage(ProgramReflection& program, const StageReflection& stage) {
    if (!blocks_valid(stage)) return corrupt("phản chiếu trỏ tới cbuffer không có");
    return add_stage(program, stage);
}

[[nodiscard]] Status check_input(const StageReflection& from, const Attribute& input) {
    const auto same = [&](const Attribute& output) {
        return output.semantic == input.semantic && output.index == input.index;
    };
    const auto found = std::ranges::find_if(from.outputs, same);
    const std::string_view word = input.semantic;
    const auto index = input.index;
    if (found == from.outputs.end()) {
        return fail(kBad, "đầu vào không có ở stage trước", "{}{}", word, index);
    }
    const bool typed = found->scalar == input.scalar && found->bits == input.bits;
    const bool fits = typed && input.components <= found->components;
    if (fits) return ok();
    return fail(kBad, "đầu vào khác kiểu với stage trước", "{}{}", word, index);
}

// "[n]" cho mảng n phần tử; rỗng khi none, giá trị của "không phải mảng".
[[nodiscard]] std::string extent(std::uint32_t count, std::uint32_t none) {
    if (count == none) return {};
    return std::format("[{}]", count);
}

void describe_block(std::string& out, const Block& block) {
    for (const Variable& variable : block.variables) {
        const std::string array = extent(variable.elements, 0);
        const auto offset = variable.offset;
        const auto size = variable.size;
        const std::string_view scalar = name(variable.scalar);
        const auto bits = variable.bits;
        const auto rows = variable.rows;
        const auto columns = variable.columns;
        const std::string& label = variable.name;
        std::format_to(std::back_inserter(out), "      +{} {}", offset, size);
        std::format_to(std::back_inserter(out), " byte {}{}", scalar, bits);
        std::format_to(std::back_inserter(out), " {}x{} {}{}\n", rows, columns, label, array);
    }
}

void describe_resource(std::string& out, StageRef reflection, const Resource& resource) {
    const RegisterType group = register_type(resource.kind);
    const std::string array = extent(resource.count, 1);
    const auto space = resource.space;
    const char mark = letter(group);
    const auto slot = resource.slot;
    const auto binding = resource.binding;
    const std::string_view kind = name(resource.kind);
    std::format_to(std::back_inserter(out), "  space {} {}{}", space, mark, slot);
    std::format_to(std::back_inserter(out), " binding {}", binding);
    std::format_to(std::back_inserter(out), " {} {}{}\n", kind, resource.name, array);
    const Block* block = block_of(reflection.blocks, resource);
    if (block == nullptr) return;
    std::format_to(std::back_inserter(out), "    {} byte\n", block->size);
    describe_block(out, *block);
}

void describe_signature(std::string& out, PathView title, const AttributeList& attributes) {
    for (const Attribute& attribute : attributes) {
        const auto place = attribute.location;
        const std::string_view word = attribute.semantic;
        const std::string_view scalar = name(attribute.scalar);
        const auto bits = attribute.bits;
        const auto parts = attribute.components;
        std::format_to(std::back_inserter(out), "  {} {}", title, place);
        std::format_to(std::back_inserter(out), " {}{}", word, attribute.index);
        std::format_to(std::back_inserter(out), " {}{}x{}\n", scalar, bits, parts);
    }
}

} // namespace

RegisterType register_type(ResourceKind kind) noexcept {
    switch (kind) {
    case ResourceKind::kSampler: return RegisterType::kSampler;
    case ResourceKind::kTexture:
    case ResourceKind::kBuffer:
    case ResourceKind::kTexelBuffer:
    case ResourceKind::kAccelerationStructure:
    case ResourceKind::kInputAttachment: return RegisterType::kResource;
    case ResourceKind::kRwTexture:
    case ResourceKind::kRwBuffer:
    case ResourceKind::kRwTexelBuffer: return RegisterType::kUnordered;
    case ResourceKind::kUniformBuffer:
    case ResourceKind::kPushConstant: return RegisterType::kConstant;
    }
    return RegisterType::kResource;
}

std::string_view name(ResourceKind kind) noexcept {
    switch (kind) {
    case ResourceKind::kSampler: return "Sampler";
    case ResourceKind::kTexture: return "Texture";
    case ResourceKind::kRwTexture: return "RwTexture";
    case ResourceKind::kBuffer: return "Buffer";
    case ResourceKind::kRwBuffer: return "RwBuffer";
    case ResourceKind::kTexelBuffer: return "TexelBuffer";
    case ResourceKind::kRwTexelBuffer: return "RwTexelBuffer";
    case ResourceKind::kUniformBuffer: return "UniformBuffer";
    case ResourceKind::kPushConstant: return "PushConstant";
    case ResourceKind::kAccelerationStructure: return "AccelerationStructure";
    case ResourceKind::kInputAttachment: return "InputAttachment";
    }
    return {};
}

std::string_view name(Scalar scalar) noexcept {
    switch (scalar) {
    case Scalar::kNone: return "none";
    case Scalar::kInt: return "int";
    case Scalar::kUInt: return "uint";
    case Scalar::kFloat: return "float";
    case Scalar::kStruct: return "struct";
    }
    return {};
}

void normalize(StageReflection& reflection) {
    std::ranges::stable_sort(reflection.resources, {}, place);
    renumber(reflection.resources, reflection.blocks);
    std::ranges::stable_sort(reflection.inputs, {}, &Attribute::location);
    std::ranges::stable_sort(reflection.outputs, {}, &Attribute::location);
}

Result<ProgramReflection> merge(std::span<const StageReflection> stages) {
    ProgramReflection program;
    const auto add = [&](const StageReflection& stage) { return merge_stage(program, stage); };
    if (Status added = first_error(stages, add); !added) return pass(added);
    std::ranges::stable_sort(program.resources, {}, place);
    renumber(program.resources, program.blocks);
    return program;
}

Status check_interface(const StageLink& link) {
    const StageReflection& producer = *link.producer;
    const StageReflection& consumer = *link.consumer;
    const auto check = [&](const Attribute& input) { return check_input(producer, input); };
    return first_error(consumer.inputs, check);
}

std::vector<std::byte> encode(const StageReflection& reflection) {
    Writer out;
    out.put(kFormatVersion);
    out.put(std::to_underlying(reflection.stage));
    out.put_text(reflection.entry);
    write_group(out, reflection.group_size);
    out.put(reflection.control_points);
    write_list(out, reflection.resources);
    write_list(out, reflection.blocks);
    write_list(out, reflection.inputs);
    write_list(out, reflection.outputs);
    return out.take();
}

Result<StageReflection> decode(std::span<const std::byte> data) {
    Reader reader(data);
    const auto version = reader.get<std::uint8_t>();
    if (version != kFormatVersion) return corrupt("phản chiếu shader sai phiên bản");
    StageReflection reflection;
    reflection.stage = read_enum(reader, Stage::kLibrary);
    reflection.entry = reader.get_text();
    for (std::uint32_t& size : reflection.group_size) {
        size = reader.get<std::uint32_t>();
    }
    reflection.control_points = reader.get<std::uint32_t>();
    reflection.resources = read_list<Resource>(reader, kLeastResource, read_resource);
    reflection.blocks = read_list<Block>(reader, kLeastBlock, read_block);
    reflection.inputs = read_list<Attribute>(reader, kLeastAttribute, read_attribute);
    reflection.outputs = read_list<Attribute>(reader, kLeastAttribute, read_attribute);
    const bool whole = !reader.failed() && reader.remaining() == 0;
    if (!whole) return corrupt("phản chiếu shader cụt hoặc sai miền");
    if (!blocks_valid(reflection)) return corrupt("phản chiếu trỏ tới cbuffer không có");
    return reflection;
}

std::uint64_t fingerprint(const StageReflection& reflection) {
    return fs::checksum(encode(reflection));
}

std::uint64_t fingerprint(const ProgramReflection& reflection) {
    Writer out;
    out.put(kFormatVersion);
    out.put(reflection.stages.bits());
    write_group(out, reflection.group_size);
    out.put(reflection.control_points);
    write_list(out, reflection.resources);
    write_list(out, reflection.blocks);
    write_list(out, reflection.inputs);
    write_list(out, reflection.outputs);
    return fs::checksum(out.bytes());
}

std::string describe(const StageReflection& reflection) {
    std::string out;
    const std::string_view kind = tag(reflection.stage);
    std::format_to(std::back_inserter(out), "stage {} entry {}\n", kind, reflection.entry);
    for (const Resource& resource : reflection.resources) {
        describe_resource(out, reflection, resource);
    }
    describe_signature(out, "in", reflection.inputs);
    describe_signature(out, "out", reflection.outputs);
    const bool grouped = reflection.group_size != std::array<std::uint32_t, 3>{};
    if (grouped) {
        const auto width = reflection.group_size.at(0);
        const auto height = reflection.group_size.at(1);
        const auto depth = reflection.group_size.at(2);
        std::format_to(std::back_inserter(out), "  group {} {} {}\n", width, height, depth);
    }
    if (reflection.control_points != 0) {
        std::format_to(std::back_inserter(out), "  control points {}\n", reflection.control_points);
    }
    return out;
}

} // namespace game::shader
