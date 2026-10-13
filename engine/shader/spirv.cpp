// Đọc module SPIR-V lấy entry, kiểu và chỗ gắn, không gọi trình điều khiển.
// Magic 0x07230203. Theo kiểu lồng tối đa 8 tầng: module thù địch có thể tạo vòng.
#include "shader/spirv.hpp"

#include "shader/failure.hpp"

#include <algorithm>
#include <cstring>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::shader {

namespace {

using Words = std::span<const std::uint32_t>;

constexpr std::uint32_t kMagic = 0x07230203U;
constexpr std::size_t kHeaderWords = 5;
constexpr std::uint32_t kNone = ~std::uint32_t{0};
// Độ sâu tối đa khi đi theo kiểu lồng nhau; module thật không quá 4, module thù địch có thể tạo
// vòng.
constexpr int kMaxDepth = 8;
constexpr std::uint32_t kBlockAlign = 16;

// Opcode, SPIR-V 1.6 mục 3.32; đối chiếu với spirv.h của Vulkan SDK 1.4.357.0.
constexpr std::uint16_t kOpName = 5;
constexpr std::uint16_t kOpMemberName = 6;
constexpr std::uint16_t kOpEntryPoint = 15;
constexpr std::uint16_t kOpExecutionMode = 16;
constexpr std::uint16_t kOpTypeBool = 20;
constexpr std::uint16_t kOpTypeInt = 21;
constexpr std::uint16_t kOpTypeFloat = 22;
constexpr std::uint16_t kOpTypeVector = 23;
constexpr std::uint16_t kOpTypeMatrix = 24;
constexpr std::uint16_t kOpTypeImage = 25;
constexpr std::uint16_t kOpTypeSampler = 26;
constexpr std::uint16_t kOpTypeSampledImage = 27;
constexpr std::uint16_t kOpTypeArray = 28;
constexpr std::uint16_t kOpTypeRuntimeArray = 29;
constexpr std::uint16_t kOpTypeStruct = 30;
constexpr std::uint16_t kOpTypePointer = 32;
constexpr std::uint16_t kOpConstant = 43;
constexpr std::uint16_t kOpVariable = 59;
constexpr std::uint16_t kOpLoad = 61;
constexpr std::uint16_t kOpAccessChain = 65;
constexpr std::uint16_t kOpInBoundsAccessChain = 66;
constexpr std::uint16_t kOpDecorate = 71;
constexpr std::uint16_t kOpMemberDecorate = 72;
constexpr std::uint16_t kOpCopyObject = 83;
constexpr std::uint16_t kOpSampledImage = 86;
constexpr std::uint16_t kOpImageSampleDrefImplicitLod = 89;
constexpr std::uint16_t kOpImageSampleDrefExplicitLod = 90;
constexpr std::uint16_t kOpImageSampleProjDrefImplicitLod = 93;
constexpr std::uint16_t kOpImageSampleProjDrefExplicitLod = 94;
constexpr std::uint16_t kOpImageDrefGather = 97;
constexpr std::uint16_t kOpImageSparseSampleDrefImplicitLod = 307;
constexpr std::uint16_t kOpImageSparseSampleDrefExplicitLod = 308;
constexpr std::uint16_t kOpImageSparseSampleProjDrefImplicitLod = 311;
constexpr std::uint16_t kOpImageSparseSampleProjDrefExplicitLod = 312;
constexpr std::uint16_t kOpImageSparseDrefGather = 315;
constexpr std::uint16_t kOpTypeAccelerationStructure = 5341;

constexpr std::uint32_t kDecorationBufferBlock = 3;
constexpr std::uint32_t kDecorationRowMajor = 4;
constexpr std::uint32_t kDecorationArrayStride = 6;
constexpr std::uint32_t kDecorationMatrixStride = 7;
constexpr std::uint32_t kDecorationBuiltIn = 11;
constexpr std::uint32_t kDecorationNonWritable = 24;
constexpr std::uint32_t kDecorationLocation = 30;
constexpr std::uint32_t kDecorationBinding = 33;
constexpr std::uint32_t kDecorationDescriptorSet = 34;
constexpr std::uint32_t kDecorationOffset = 35;

constexpr std::uint32_t kStorageUniformConstant = 0;
constexpr std::uint32_t kStorageInput = 1;
constexpr std::uint32_t kStorageUniform = 2;
constexpr std::uint32_t kStorageOutput = 3;
constexpr std::uint32_t kStoragePushConstant = 9;
constexpr std::uint32_t kStorageBuffer = 12;

constexpr std::uint32_t kDim1D = 0;
constexpr std::uint32_t kDim2D = 1;
constexpr std::uint32_t kDim3D = 2;
constexpr std::uint32_t kDimCube = 3;
constexpr std::uint32_t kDimRect = 4;
constexpr std::uint32_t kDimBuffer = 5;
constexpr std::uint32_t kDimSubpass = 6;

constexpr std::uint32_t kModeLocalSize = 17;
constexpr std::uint32_t kModeOutputVertices = 26;

constexpr std::uint32_t kModelVertex = 0;
constexpr std::uint32_t kModelHull = 1;
constexpr std::uint32_t kModelDomain = 2;
constexpr std::uint32_t kModelGeometry = 3;
constexpr std::uint32_t kModelPixel = 4;
constexpr std::uint32_t kModelCompute = 5;
constexpr std::uint32_t kModelTaskNv = 5267;
constexpr std::uint32_t kModelMeshNv = 5268;
constexpr std::uint32_t kModelTask = 5364;
constexpr std::uint32_t kModelMesh = 5365;

// Những gì module nói về một id: lệnh định nghĩa nó và các trang trí gắn vào nó.
struct Id {
    // Vị trí (tính bằng word) của lệnh định nghĩa; 0 khi chưa thấy, vì header chiếm word 0 tới 4.
    std::uint32_t at = 0;
    // Vị trí và số word của chuỗi tên; 0 khi không có OpName.
    std::uint32_t name = 0;
    std::uint32_t name_words = 0;
    std::uint32_t set = kNone;
    std::uint32_t binding = kNone;
    std::uint32_t location = kNone;
    std::uint32_t stride = 0;
    // Biến toàn cục mà giá trị này được nạp từ đó, theo dấu qua OpLoad và OpAccessChain.
    std::uint32_t origin = 0;
    bool builtin = false;
    bool buffer_block = false;
    bool read_only = false;
    // Sampler đã được dùng trong một phép lấy mẫu có so sánh.
    bool compared = false;
};

struct Member {
    std::uint32_t name = 0;
    std::uint32_t name_words = 0;
    std::uint32_t offset = 0;
    std::uint32_t matrix_stride = 0;
    bool row_major = false;
    bool read_only = false;
};

struct Module {
    std::vector<std::uint32_t> words;
    std::vector<Id> ids;
    // Khoá là (id của struct << 32) | chỉ số thành viên.
    std::unordered_map<std::uint64_t, Member> members;
    // Vị trí các lệnh OpEntryPoint và OpExecutionMode.
    std::vector<std::uint32_t> entries;
    std::vector<std::uint32_t> modes;
    // Một lệnh thiếu toán hạng hoặc trỏ tới id ngoài miền.
    bool broken = false;
};

// Word thứ index; 0 khi ngoài vùng, để lệnh cụt không thành đọc tràn.
[[nodiscard]] std::uint32_t word(Words words, std::size_t index) noexcept {
    if (index >= words.size()) return 0;
    return words.subspan(index, 1).front();
}

[[nodiscard]] std::uint16_t opcode(Words words) noexcept {
    return static_cast<std::uint16_t>(word(words, 0) & 0xFFFFU);
}

[[nodiscard]] Words slice(const Module& module, std::size_t start, std::size_t count) noexcept {
    const Words all = module.words;
    if (start > all.size() || count > all.size() - start) return {};
    return all.subspan(start, count);
}

[[nodiscard]] Id* find(Module& module, std::uint32_t id) noexcept {
    if (id >= module.ids.size()) return nullptr;
    return &module.ids.at(id);
}

[[nodiscard]] const Id& info(const Module& module, std::uint32_t id) noexcept {
    static const Id kMissing{};
    if (id >= module.ids.size()) return kMissing;
    return module.ids.at(id);
}

// Lệnh định nghĩa id; rỗng khi id không được định nghĩa.
[[nodiscard]] Words definition(const Module& module, std::uint32_t id) noexcept {
    const std::uint32_t start = info(module, id).at;
    if (start == 0) return {};
    const std::size_t count = word(module.words, start) >> 16U;
    return slice(module, start, count);
}

[[nodiscard]] constexpr std::uint64_t member_key(std::uint32_t type, std::uint32_t index) noexcept {
    return (std::uint64_t{type} << 32U) | index;
}

[[nodiscard]] Member member(const Module& module, std::uint32_t type, std::size_t index) {
    const auto found = module.members.find(member_key(type, static_cast<std::uint32_t>(index)));
    if (found == module.members.end()) return {};
    return found->second;
}

// Chuỗi kết thúc bằng byte 0 nằm trong count word kể từ start.
[[nodiscard]] std::string text(const Module& module, std::uint32_t start, std::uint32_t count) {
    const std::span<const std::byte> raw = std::as_bytes(slice(module, start, count));
    const auto end = std::ranges::find(raw, std::byte{0});
    const auto size = static_cast<std::size_t>(end - raw.begin());
    std::string out(size, '\0');
    if (size != 0) std::memcpy(out.data(), raw.data(), size);
    return out;
}

[[nodiscard]] std::string name_of(const Module& module, std::uint32_t id) {
    const Id& id_info = info(module, id);
    return text(module, id_info.name, id_info.name_words);
}

[[nodiscard]] constexpr bool has_zero_byte(std::uint32_t value) noexcept {
    return ((value - 0x01010101U) & ~value & 0x80808080U) != 0;
}

// Số word mà chuỗi bắt đầu ở words[first] chiếm, kể cả word chứa byte 0.
[[nodiscard]] std::size_t text_words(Words words, std::size_t first) noexcept {
    // Khác gốc: gốc là vòng for có câu if (word có byte 0) return index - first + 1 trong thân.
    std::size_t index = first;
    while (index < words.size() && !has_zero_byte(word(words, index))) {
        ++index;
    }
    if (index < words.size()) return index - first + 1;
    return words.size() - std::min(first, words.size());
}

// Số word ít nhất của những lệnh bộ đọc này mở ra; lệnh ngắn hơn là module hỏng.
[[nodiscard]] std::size_t least_words(std::uint16_t code) noexcept {
    switch (code) {
    case kOpTypeImage: return 9;
    case kOpSampledImage: return 5;
    case kOpMemberName:
    case kOpEntryPoint:
    case kOpTypeInt:
    case kOpTypeVector:
    case kOpTypeMatrix:
    case kOpTypeArray:
    case kOpTypePointer:
    case kOpConstant:
    case kOpVariable:
    case kOpLoad:
    case kOpAccessChain:
    case kOpInBoundsAccessChain:
    case kOpMemberDecorate:
    case kOpCopyObject:
    case kOpImageSampleDrefImplicitLod:
    case kOpImageSampleDrefExplicitLod:
    case kOpImageSampleProjDrefImplicitLod:
    case kOpImageSampleProjDrefExplicitLod:
    case kOpImageDrefGather:
    case kOpImageSparseSampleDrefImplicitLod:
    case kOpImageSparseSampleDrefExplicitLod:
    case kOpImageSparseSampleProjDrefImplicitLod:
    case kOpImageSparseSampleProjDrefExplicitLod:
    case kOpImageSparseDrefGather: return 4;
    case kOpName:
    case kOpExecutionMode:
    case kOpTypeFloat:
    case kOpTypeSampledImage:
    case kOpTypeRuntimeArray:
    case kOpDecorate: return 3;
    default: return 1;
    }
}

void define(Module& module, std::uint32_t id, std::size_t start) noexcept {
    Id* slot = find(module, id);
    if (slot == nullptr) module.broken = true;
    if (slot != nullptr) slot->at = static_cast<std::uint32_t>(start);
}

void record_name(Module& module, Words words, std::size_t start) noexcept {
    Id* slot = find(module, word(words, 1));
    if (slot == nullptr) return;
    slot->name = static_cast<std::uint32_t>(start + 2);
    slot->name_words = static_cast<std::uint32_t>(words.size() - 2);
}

void record_member_name(Module& module, Words words, std::size_t start) {
    Member& entry = module.members[member_key(word(words, 1), word(words, 2))];
    entry.name = static_cast<std::uint32_t>(start + 3);
    entry.name_words = static_cast<std::uint32_t>(words.size() - 3);
}

void record_decoration(Module& module, Words words) noexcept {
    Id* slot = find(module, word(words, 1));
    if (slot == nullptr) return;
    const std::uint32_t value = word(words, 3);
    switch (word(words, 2)) {
    case kDecorationBufferBlock: slot->buffer_block = true; break;
    case kDecorationArrayStride: slot->stride = value; break;
    case kDecorationBuiltIn: slot->builtin = true; break;
    case kDecorationNonWritable: slot->read_only = true; break;
    case kDecorationLocation: slot->location = value; break;
    case kDecorationBinding: slot->binding = value; break;
    case kDecorationDescriptorSet: slot->set = value; break;
    default: break;
    }
}

void record_member_decoration(Module& module, Words words) {
    Member& entry = module.members[member_key(word(words, 1), word(words, 2))];
    const std::uint32_t value = word(words, 4);
    switch (word(words, 3)) {
    case kDecorationRowMajor: entry.row_major = true; break;
    case kDecorationMatrixStride: entry.matrix_stride = value; break;
    case kDecorationNonWritable: entry.read_only = true; break;
    case kDecorationOffset: entry.offset = value; break;
    default: break;
    }
}

// Biến toàn cục đứng sau một id: chính nó nếu là biến, không thì biến mà nó được nạp từ đó.
[[nodiscard]] std::uint32_t root(const Module& module, std::uint32_t id) noexcept {
    if (opcode(definition(module, id)) == kOpVariable) return id;
    return info(module, id).origin;
}

// Kết quả ở word 2 thừa hưởng biến gốc của toán hạng ở word thứ source.
void inherit(Module& module, Words words, std::size_t source) noexcept {
    Id* slot = find(module, word(words, 2));
    if (slot == nullptr) return;
    slot->origin = root(module, word(words, source));
}

// Một phép lấy mẫu có so sánh: toán hạng ở word 3 là sampled image, gốc của nó là sampler.
void mark_compared(Module& module, Words words) noexcept {
    Id* sampler = find(module, info(module, word(words, 3)).origin);
    if (sampler == nullptr) return;
    sampler->compared = true;
}

// Khác gốc: gốc viết mỗi nhánh là return <lời gọi hàm void>; ở đây là lời gọi rồi return.
void record(Module& module, std::size_t start, Words words) {
    const std::uint16_t code = opcode(words);
    if (words.size() < least_words(code)) module.broken = true;
    if (module.broken) return;
    switch (code) {
    case kOpName: record_name(module, words, start); return;
    case kOpMemberName: record_member_name(module, words, start); return;
    case kOpEntryPoint: module.entries.push_back(static_cast<std::uint32_t>(start)); return;
    case kOpExecutionMode: module.modes.push_back(static_cast<std::uint32_t>(start)); return;
    case kOpDecorate: record_decoration(module, words); return;
    case kOpMemberDecorate: record_member_decoration(module, words); return;
    case kOpTypeBool:
    case kOpTypeInt:
    case kOpTypeFloat:
    case kOpTypeVector:
    case kOpTypeMatrix:
    case kOpTypeImage:
    case kOpTypeSampler:
    case kOpTypeSampledImage:
    case kOpTypeArray:
    case kOpTypeRuntimeArray:
    case kOpTypeStruct:
    case kOpTypePointer:
    case kOpTypeAccelerationStructure: define(module, word(words, 1), start); return;
    case kOpConstant:
    case kOpVariable: define(module, word(words, 2), start); return;
    case kOpLoad:
    case kOpAccessChain:
    case kOpInBoundsAccessChain:
    case kOpCopyObject: inherit(module, words, 3); return;
    case kOpSampledImage: inherit(module, words, 4); return;
    case kOpImageSampleDrefImplicitLod:
    case kOpImageSampleDrefExplicitLod:
    case kOpImageSampleProjDrefImplicitLod:
    case kOpImageSampleProjDrefExplicitLod:
    case kOpImageDrefGather:
    case kOpImageSparseSampleDrefImplicitLod:
    case kOpImageSparseSampleDrefExplicitLod:
    case kOpImageSparseSampleProjDrefImplicitLod:
    case kOpImageSparseSampleProjDrefExplicitLod:
    case kOpImageSparseDrefGather: mark_compared(module, words); return;
    default: return;
    }
}

// Ghi nhận lệnh ở start rồi dời start qua nó. false khi lệnh cụt (độ dài 0 hoặc vượt cuối module):
// khi đó không ghi nhận gì và start giữ nguyên.
// Khác gốc: thân vòng while của parse tách ra đây, giữ thứ tự kiểm độ dài trước khi ghi nhận.
[[nodiscard]] bool record_next(Module& module, std::size_t& start) {
    const std::size_t count = word(module.words, start) >> 16U;
    const bool fits = count != 0 && count <= module.words.size() - start;
    if (!fits) return false;
    record(module, start, slice(module, start, count));
    start += count;
    return true;
}

[[nodiscard]] Result<Module> parse(std::span<const std::byte> code) {
    const bool sized = code.size() >= kHeaderWords * 4 && code.size() % 4 == 0;
    if (!sized) return corrupt("SPIR-V sai cỡ");
    Module module;
    module.words.resize(code.size() / 4);
    std::memcpy(module.words.data(), code.data(), code.size());
    if (module.words.front() != kMagic) return corrupt("SPIR-V sai magic");
    const std::uint32_t bound = word(module.words, 3);
    // Mỗi id cần ít nhất một lệnh định nghĩa, nên bound không thể vượt số word.
    if (bound > module.words.size()) return corrupt("SPIR-V khai nhiều id hơn số lệnh");
    module.ids.resize(bound);
    // Khác gốc: gốc trả lỗi "lệnh cụt" ngay trong thân vòng while; ở đây vòng dừng ở lệnh cụt đầu
    // tiên rồi mới trả, vẫn trước phép kiểm module.broken.
    std::size_t start = kHeaderWords;
    bool fits = true;
    while (fits && start < module.words.size()) {
        fits = record_next(module, start);
    }
    if (!fits) return corrupt("SPIR-V có lệnh cụt");
    if (module.broken) return corrupt("SPIR-V có lệnh thiếu toán hạng hoặc id ngoài miền");
    return module;
}

// Kiểu sau khi bóc mọi tầng mảng.
struct Element {
    std::uint32_t type = 0;
    // Số phần tử; 0 khi có một tầng không chặn.
    std::uint32_t count = 1;
    // ArrayStride của tầng ngoài cùng.
    std::uint32_t stride = 0;
    bool array = false;
};

[[nodiscard]] std::uint32_t constant(const Module& module, std::uint32_t id) noexcept {
    const Words words = definition(module, id);
    if (opcode(words) != kOpConstant) return 0;
    return word(words, 3);
}

// Bóc một tầng mảng của element; false khi kiểu hiện tại không phải mảng, element giữ nguyên.
// Khác gốc: thân vòng for của strip_arrays tách ra đây.
[[nodiscard]] bool strip_layer(const Module& module, Element& element) noexcept {
    const Words words = definition(module, element.type);
    const std::uint16_t code = opcode(words);
    const bool is_array = code == kOpTypeArray || code == kOpTypeRuntimeArray;
    if (!is_array) return false;
    const std::uint32_t length = code == kOpTypeArray ? constant(module, word(words, 3)) : 0;
    if (!element.array) element.stride = info(module, element.type).stride;
    element.count = element.array ? element.count * length : length;
    element.array = true;
    element.type = word(words, 2);
    return true;
}

[[nodiscard]] Element strip_arrays(const Module& module, std::uint32_t type) noexcept {
    Element element{.type = type};
    bool stripped = true;
    for (int depth = 0; stripped && depth < kMaxDepth; ++depth) {
        stripped = strip_layer(module, element);
    }
    return element;
}

// Kiểu số: vô hướng, vector hay ma trận. DXC ghi floatRxC của HLSL thành ma trận SPIR-V gồm R
// vector C thành phần, nên số "cột" của SPIR-V là số hàng của HLSL.
struct Numeric {
    Scalar scalar = Scalar::kNone;
    std::uint8_t bits = 0;
    std::uint8_t rows = 0;
    std::uint8_t columns = 0;
};

[[nodiscard]] std::uint8_t narrow(std::uint32_t value) noexcept {
    return static_cast<std::uint8_t>(std::min<std::uint32_t>(value, 255));
}

// Một vô hướng: một hàng, một cột.
[[nodiscard]] constexpr Numeric single(Scalar scalar, std::uint8_t bits) noexcept {
    return {.scalar = scalar, .bits = bits, .rows = 1, .columns = 1};
}

[[nodiscard]] Numeric numeric(const Module& module, std::uint32_t type, int depth = 0) noexcept {
    const Words words = definition(module, type);
    const std::uint16_t code = opcode(words);
    if (code == kOpTypeStruct) return {.scalar = Scalar::kStruct};
    // bool của SPIR-V không có độ rộng; trong chữ ký nó chiếm một word như uint.
    if (code == kOpTypeBool) return single(Scalar::kUInt, 32);
    const std::uint8_t bits = narrow(word(words, 2));
    if (code == kOpTypeFloat) return single(Scalar::kFloat, bits);
    const Scalar integer = word(words, 3) != 0 ? Scalar::kInt : Scalar::kUInt;
    if (code == kOpTypeInt) return single(integer, bits);
    const bool compound = code == kOpTypeVector || code == kOpTypeMatrix;
    if (!compound || depth >= kMaxDepth) return {};
    Numeric inner = numeric(module, word(words, 2), depth + 1);
    const std::uint8_t count = narrow(word(words, 3));
    if (code == kOpTypeVector) inner.columns = count;
    if (code == kOpTypeMatrix) inner.rows = count;
    return inner;
}

[[nodiscard]] std::uint32_t struct_size(const Module& module, std::uint32_t type, int depth);

// Cỡ một phần tử kiểu type đứng ở thành viên holder của một struct.
[[nodiscard]] std::uint32_t element_size(const Module& module, std::uint32_t type, const Member& holder, int depth) {
    const Numeric shape = numeric(module, type);
    if (shape.scalar == Scalar::kStruct) return struct_size(module, type, depth + 1);
    const std::uint32_t bytes = shape.bits / 8U;
    const std::uint32_t rows = shape.rows;
    const std::uint32_t columns = shape.columns;
    const bool strided = rows > 1 && holder.matrix_stride != 0;
    if (!strided) return rows * columns * bytes;
    // RowMajor của SPIR-V là column_major của HLSL: columns cột, mỗi cột rows thành phần.
    if (holder.row_major) return (holder.matrix_stride * (columns - 1)) + (rows * bytes);
    return (holder.matrix_stride * (rows - 1)) + (columns * bytes);
}

[[nodiscard]] std::uint32_t member_size(const Module& module, std::uint32_t type, const Member& holder, int depth) {
    const Element element = strip_arrays(module, type);
    const std::uint32_t single = element_size(module, element.type, holder, depth);
    if (!element.array) return single;
    if (element.count == 0) return 0;
    return (element.stride * (element.count - 1)) + single;
}

// Cuối của thành viên xa nhất, không đệm đuôi: cùng con số mà phản chiếu D3D12 báo.
[[nodiscard]] std::uint32_t struct_size(const Module& module, std::uint32_t type, int depth) {
    if (depth >= kMaxDepth) return 0;
    const Words words = definition(module, type);
    std::uint32_t size = 0;
    for (std::size_t index = 2; index < words.size(); ++index) {
        const Member holder = member(module, type, index - 2);
        const std::uint32_t end = holder.offset + member_size(module, word(words, index), holder, depth);
        size = std::max(size, end);
    }
    return size;
}

[[nodiscard]] Variable variable_of(const Module& module, std::uint32_t type, std::size_t index) {
    const Member holder = member(module, type, index);
    const std::uint32_t member_type = word(definition(module, type), index + 2);
    const Element element = strip_arrays(module, member_type);
    const Numeric shape = numeric(module, element.type);
    Variable variable;
    variable.name = text(module, holder.name, holder.name_words);
    variable.offset = holder.offset;
    variable.size = member_size(module, member_type, holder, 0);
    variable.scalar = shape.scalar;
    variable.bits = shape.bits;
    variable.rows = shape.rows;
    variable.columns = shape.columns;
    variable.elements = element.array ? element.count : 0;
    return variable;
}

[[nodiscard]] Block block_of(const Module& module, std::uint32_t type, std::string name) {
    Block block;
    block.name = std::move(name);
    const std::size_t count = definition(module, type).size() - 2;
    for (std::size_t index = 0; index < count; ++index) {
        block.variables.push_back(variable_of(module, type, index));
    }
    const std::uint32_t size = struct_size(module, type, 0);
    block.size = (size + kBlockAlign - 1) / kBlockAlign * kBlockAlign;
    return block;
}

[[nodiscard]] TextureShape shape_of(std::uint32_t dim) noexcept {
    switch (dim) {
    case kDim1D: return TextureShape::kTex1D;
    case kDim2D:
    case kDimRect:
    case kDimSubpass: return TextureShape::kTex2D;
    case kDim3D: return TextureShape::kTex3D;
    case kDimCube: return TextureShape::kCube;
    default: return TextureShape::kNone;
    }
}

[[nodiscard]] ResourceKind image_kind(std::uint32_t dim, bool storage) noexcept {
    if (dim == kDimSubpass) return ResourceKind::kInputAttachment;
    const bool texel = dim == kDimBuffer;
    if (texel) return storage ? ResourceKind::kRwTexelBuffer : ResourceKind::kTexelBuffer;
    return storage ? ResourceKind::kRwTexture : ResourceKind::kTexture;
}

// OpTypeImage: word 2 kiểu mẫu, 3 dim, 5 arrayed, 6 multisample, 7 sampled (2 là storage), 8
// format.
void fill_image(const Module& module, Words image, Resource& resource) noexcept {
    const std::uint32_t dim = word(image, 3);
    resource.kind = image_kind(dim, word(image, 7) == 2);
    resource.shape = shape_of(dim);
    resource.array = word(image, 5) != 0;
    resource.multisample = word(image, 6) != 0;
    resource.sample = numeric(module, word(image, 2)).scalar;
    resource.image_format = word(image, 8);
}

[[nodiscard]] bool is_raw(std::string_view type_name) noexcept {
    return type_name.starts_with("type.ByteAddressBuffer") || type_name.starts_with("type.RWByteAddressBuffer");
}

// StructuredBuffer và ByteAddressBuffer: struct bọc một mảng không chặn. Chỉ đọc khi thành viên 0
// hoặc chính biến mang NonWritable.
void fill_buffer(const Module& module, std::uint32_t id, std::uint32_t type, Resource& resource) {
    const bool read_only = info(module, id).read_only || member(module, type, 0).read_only;
    resource.kind = read_only ? ResourceKind::kBuffer : ResourceKind::kRwBuffer;
    resource.raw = is_raw(name_of(module, type));
    if (resource.raw) return;
    const std::uint32_t array = word(definition(module, type), 2);
    resource.stride = info(module, array).stride;
}

void fill_struct(const Module& module, std::uint32_t id, std::uint32_t type, std::uint32_t storage,
    StageReflection& reflection, Resource& resource) {
    const bool uniform = storage == kStorageUniform && !info(module, type).buffer_block;
    const bool push = storage == kStoragePushConstant;
    if (!uniform && !push) {
        fill_buffer(module, id, type, resource);
        return;
    }
    resource.kind = push ? ResourceKind::kPushConstant : ResourceKind::kUniformBuffer;
    resource.block = static_cast<std::uint32_t>(reflection.blocks.size());
    reflection.blocks.push_back(block_of(module, type, resource.name));
}

// Đặt space, slot, binding. Khối push constant không có set: nó nhận kPushSpace để trùng với DXIL.
[[nodiscard]] Status place(const Module& module, std::uint32_t id, Resource& resource) {
    if (resource.kind == ResourceKind::kPushConstant) {
        resource.space = kPushSpace;
        return ok();
    }
    const Id& bound = info(module, id);
    const bool located = bound.set != kNone && bound.binding != kNone;
    if (!located) return corrupt("SPIR-V có tài nguyên thiếu set hoặc binding");
    const std::uint32_t shift = binding_shift(register_type(resource.kind));
    const bool shifted = bound.binding >= shift && bound.binding - shift < kShiftRange;
    if (!shifted) {
        return fail(ErrorCode::kCorrupt, "binding không khớp độ dịch của lớp register", "{} = {}", resource.name,
            bound.binding);
    }
    resource.space = bound.set;
    resource.binding = bound.binding;
    resource.slot = bound.binding - shift;
    return ok();
}

[[nodiscard]] bool is_resource_storage(std::uint32_t storage) noexcept {
    return storage == kStorageUniformConstant || storage == kStorageUniform || storage == kStoragePushConstant ||
        storage == kStorageBuffer;
}

// Thêm biến id vào reflection nếu nó là tài nguyên. OpVariable: word 1 kiểu con trỏ, 3 storage
// class; OpTypePointer: word 3 kiểu được trỏ.
[[nodiscard]] Status add_resource(const Module& module, std::uint32_t id, StageReflection& reflection) {
    const Words variable = definition(module, id);
    const std::uint32_t storage = word(variable, 3);
    const bool wanted = opcode(variable) == kOpVariable && is_resource_storage(storage);
    if (!wanted) return ok();
    const Words pointer = definition(module, word(variable, 1));
    const Element element = strip_arrays(module, word(pointer, 3));
    const Words base = definition(module, element.type);
    Resource resource;
    resource.name = name_of(module, id);
    // DXC tách bộ đếm của Append/Consume thành biến binding riêng. DXIL gom vào UAV.
    // Vulkan không có bộ đếm ấy: từ chối trước khi xét binding, để không thành Corrupt.
    if (resource.name.starts_with("counter.var.")) {
        return fail(ErrorCode::kUnsupported, "buffer có bộ đếm không có trên Vulkan", resource.name);
    }
    resource.count = element.array ? element.count : 1;
    resource.stages = StageSet(reflection.stage);
    switch (opcode(base)) {
    case kOpTypeSampler:
        resource.kind = ResourceKind::kSampler;
        resource.comparison = info(module, id).compared;
        break;
    case kOpTypeImage: fill_image(module, base, resource); break;
    case kOpTypeStruct: fill_struct(module, id, element.type, storage, reflection, resource); break;
    case kOpTypeAccelerationStructure: resource.kind = ResourceKind::kAccelerationStructure; break;
    case kOpTypeSampledImage:
        return fail(ErrorCode::kUnsupported, "combined image sampler không được hỗ trợ", resource.name);
    default: return fail(ErrorCode::kUnsupported, "kiểu tài nguyên SPIR-V lạ", resource.name);
    }
    if (Status placed = place(module, id, resource); !placed) return pass(placed);
    reflection.resources.push_back(std::move(resource));
    return ok();
}

[[nodiscard]] constexpr bool is_digit(char unit) noexcept {
    return unit >= '0' && unit <= '9';
}

[[nodiscard]] constexpr char upper(char unit) noexcept {
    const bool lower = unit >= 'a' && unit <= 'z';
    return lower ? static_cast<char>(unit - 'a' + 'A') : unit;
}

// "in.var.TEXCOORD1" thành semantic "TEXCOORD", index 1. Semantic của HLSL không phân biệt hoa
// thường nên đưa về chữ hoa, như phía DXIL.
void fill_semantic(std::string_view variable_name, Attribute& attribute) {
    const std::size_t dot = variable_name.rfind('.');
    std::string_view semantic = variable_name.substr(dot == std::string_view::npos ? 0 : dot + 1);
    std::size_t digits = 0;
    while (digits < semantic.size() && is_digit(semantic.at(semantic.size() - digits - 1))) {
        ++digits;
    }
    // Chín chữ số là đủ cho mọi chỉ số thật và không tràn 32 bit.
    digits = std::min<std::size_t>(digits, 9);
    for (const char digit : semantic.substr(semantic.size() - digits)) {
        attribute.index = (attribute.index * 10) + static_cast<std::uint32_t>(digit - '0');
    }
    semantic.remove_suffix(digits);
    attribute.semantic.resize(semantic.size());
    std::ranges::transform(semantic, attribute.semantic.begin(), upper);
}

void store_attribute(StageReflection& reflection, bool input, Attribute attribute) {
    std::vector<Attribute>& list = input ? reflection.inputs : reflection.outputs;
    list.push_back(std::move(attribute));
}

// Ma trận SPIR-V là một biến chiếm nhiều location. DXIL tách float4x4 thành từng hàng, semantic
// index liên tiếp. Tách cùng cách thì hai phản chiếu khớp.
void store_matrix(StageReflection& reflection, bool input, Attribute base, const Numeric& shape,
    std::uint32_t location) {
    for (std::uint8_t row = 0; row < shape.rows; ++row) {
        Attribute attribute = base;
        attribute.index = base.index + row;
        attribute.location = location + row;
        attribute.components = shape.columns;
        store_attribute(reflection, input, std::move(attribute));
    }
}

// Thêm biến giao diện id vào inputs hay outputs; biến builtin không có Location nên bị bỏ.
void add_attribute(const Module& module, std::uint32_t id, StageReflection& reflection) {
    const Words variable = definition(module, id);
    const std::uint32_t storage = word(variable, 3);
    const bool signal = storage == kStorageInput || storage == kStorageOutput;
    const Id& located = info(module, id);
    const bool wanted = opcode(variable) == kOpVariable && signal && located.location != kNone;
    if (!wanted || located.builtin) return;
    const Words pointer = definition(module, word(variable, 1));
    const Element element = strip_arrays(module, word(pointer, 3));
    const Numeric shape = numeric(module, element.type);
    Attribute attribute;
    fill_semantic(name_of(module, id), attribute);
    attribute.scalar = shape.scalar;
    attribute.bits = shape.bits;
    const bool input = storage == kStorageInput;
    if (shape.rows > 1) {
        store_matrix(reflection, input, attribute, shape, located.location);
        return;
    }
    attribute.location = located.location;
    attribute.components = shape.columns;
    store_attribute(reflection, input, std::move(attribute));
}

[[nodiscard]] bool model_matches(Stage stage, std::uint32_t model) noexcept {
    switch (stage) {
    case Stage::kVertex: return model == kModelVertex;
    case Stage::kHull: return model == kModelHull;
    case Stage::kDomain: return model == kModelDomain;
    case Stage::kGeometry: return model == kModelGeometry;
    case Stage::kPixel: return model == kModelPixel;
    case Stage::kCompute: return model == kModelCompute;
    case Stage::kMesh: return model == kModelMesh || model == kModelMeshNv;
    case Stage::kAmplification: return model == kModelTask || model == kModelTaskNv;
    case Stage::kLibrary: return true;
    }
    return false;
}

// OpEntryPoint: word 1 execution model, 2 id của hàm, từ 3 là tên, sau tên là các id giao diện.
struct Entry {
    std::uint32_t model = 0;
    std::uint32_t function = 0;
    Words interface;
};

[[nodiscard]] Entry entry_at(const Module& module, std::uint32_t start) noexcept {
    const std::size_t count = word(module.words, start) >> 16U;
    const Words words = slice(module, start, count);
    const std::size_t named = 3 + text_words(words, 3);
    return {
        .model = word(words, 1), .function = word(words, 2), .interface = words.subspan(std::min(named, words.size()))};
}

// Tên của entry point khai ở lệnh OpEntryPoint tại start.
// Khác gốc: thân vòng for của find_entry tách ra đây.
[[nodiscard]] std::string entry_name(const Module& module, std::uint32_t start) {
    const std::size_t count = word(module.words, start) >> 16U;
    return text(module, start + 3, static_cast<std::uint32_t>(count - 3));
}

// Khác gốc: gốc là vòng for có câu if (tên trùng) return entry_at(...) trong thân; find_if cũng
// dừng ở entry point đầu tiên trùng tên.
[[nodiscard]] Result<Entry> find_entry(const Module& module, std::string_view name) {
    const auto named = [&](std::uint32_t start) { return entry_name(module, start) == name; };
    const auto found = std::ranges::find_if(module.entries, named);
    const bool missing = found == module.entries.end();
    if (missing) return fail(ErrorCode::kNotFound, "SPIR-V không có entry point", name);
    return entry_at(module, *found);
}

// OpExecutionMode: word 1 id của hàm, 2 mode, từ 3 là tham số.
void apply_mode(const Module& module, std::uint32_t start, const Entry& entry, StageReflection& reflection) noexcept {
    const std::size_t count = word(module.words, start) >> 16U;
    const Words words = slice(module, start, count);
    if (word(words, 1) != entry.function) return;
    const std::uint32_t mode = word(words, 2);
    if (mode == kModeOutputVertices) reflection.control_points = word(words, 3);
    if (mode != kModeLocalSize) return;
    reflection.group_size = {word(words, 3), word(words, 4), word(words, 5)};
}

// Chữ ký vào ra và execution mode của entry point; thư viện nhiều hàm không có phần này.
[[nodiscard]] Status reflect_entry(const Module& module, StageReflection& reflection) {
    if (reflection.stage == Stage::kLibrary) return ok();
    Result<Entry> entry = find_entry(module, reflection.entry);
    if (!entry) return pass(entry);
    if (!model_matches(reflection.stage, entry->model)) {
        return fail(ErrorCode::kInvalidArgument, "entry point thuộc stage khác", reflection.entry);
    }
    for (const std::uint32_t id : entry->interface) {
        add_attribute(module, id, reflection);
    }
    for (const std::uint32_t start : module.modes) {
        apply_mode(module, start, *entry, reflection);
    }
    return ok();
}

} // namespace

bool is_spirv(std::span<const std::byte> code) noexcept {
    if (code.size() < sizeof(kMagic)) return false;
    std::uint32_t magic = 0;
    std::memcpy(&magic, code.data(), sizeof(magic));
    return magic == kMagic;
}

Result<StageReflection> reflect_spirv(std::span<const std::byte> code, Stage stage, std::string_view entry) {
    Result<Module> module = parse(code);
    if (!module) return pass(module);
    StageReflection reflection;
    reflection.stage = stage;
    reflection.entry = stage == Stage::kLibrary ? std::string() : std::string(entry);
    if (Status entered = reflect_entry(*module, reflection); !entered) return pass(entered);
    const auto count = static_cast<std::uint32_t>(module->ids.size());
    // Khác gốc: gốc viết if (!added) return pass(added) trong thân vòng for; ở đây vòng dừng ở lỗi
    // đầu tiên rồi mới trả.
    Status added = ok();
    for (std::uint32_t id = 0; added && id < count; ++id) {
        added = add_resource(*module, id, reflection);
    }
    if (!added) return pass(added);
    normalize(reflection);
    return reflection;
}

} // namespace game::shader
