/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Shader/shader_tests.cpp
 *  PHÂN HỆ   : Shader / Shader Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Test của shader và fs. Trọng tâm là đọc gói shader (tiêu chí của bước B3):
 *    gói dựng trong bộ nhớ bằng write_package, Package::parse đọc lại và so
 *    từng trường; dữ liệu hỏng (cắt cụt, lật byte, magic, phiên bản, offset
 *    vượt biên) phải ra lỗi Corrupt chứ không sập. Kèm phản chiếu khứ hồi,
 *    merge, check_interface, các hàm parse của types, tổng kiểm XXH3, codec lz4
 *    và zstd, find và rfind của fs/stream, bảng băm Buny.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Mã được kiểm chép từ Forge2; giá trị vàng (XXH3, MurmurHash64A, bảng băm, khoá biến thể) đo bằng cả mã gốc
// Forge2@d7fcd76 lẫn bản chép, hai bên trùng nhau. Các offset trong tệp gói là đặc tả byte của định dạng F2SH phiên
// bản 1. Test tự chứa: không GPU, không DXC, không đọc tệp ngoài; tệp tạm của ca load nằm ở thư mục làm việc và bị
// xoá khi xong.

#include "core/check.hpp"
#include "core/error.hpp"
#include "fs/buny.hpp"
#include "fs/codec.hpp"
#include "fs/stream.hpp"
#include "shader/compiler.hpp"
#include "shader/detail/reconcile.hpp"
#include "shader/detail/roots.hpp"
#include "shader/manifest.hpp"
#include "shader/package.hpp"
#include "shader/reflection.hpp"
#include "shader/spirv.hpp"
#include "shader/types.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using shader::Attribute;
using shader::Block;
using shader::Package;
using shader::PackageSource;
using shader::PackageVariant;
using shader::Resource;
using shader::ResourceKind;
using shader::Scalar;
using shader::Stage;
using shader::StageReflection;
using shader::Target;
using shader::Variable;

using Buffer = std::vector<std::byte>;
using View = std::span<const std::byte>;
using Attributes = std::vector<Attribute>;
using Found = core::Result<std::optional<std::uint64_t>>;

// Mốc dữ liệu mẫu
constexpr std::string_view kSampleText = "Thiên Long Bát Bộ";
constexpr std::uint64_t kOptionsHash = 0x0123'4567'89AB'CDEFULL;
constexpr std::string_view kTempFile = "shader_tests_goi_tam.f2s";

// Bố cục tệp gói F2SH phiên bản 1: header 64 byte (tổng kiểm 8 byte ở offset 48), rồi bảng bản
// dịch 48 byte mỗi bản ghi, rồi bảng phụ thuộc 16 byte mỗi bản ghi. Gói mẫu có hai bản dịch.
constexpr std::size_t kHeaderSize = 64;
constexpr std::size_t kChecksumAt = 48;
constexpr std::size_t kVariantsAt = kHeaderSize;
constexpr std::size_t kVariantSize = 48;
constexpr std::size_t kDependenciesAt = kVariantsAt + (2 * kVariantSize);
// Trong một bản ghi bản dịch: khoá ở +16, offset bytecode ở +32.
constexpr std::size_t kKeyInVariant = 16;
constexpr std::size_t kCodeInVariant = 32;

// Luồng mẫu cho find và rfind: khúc quét của fs/stream.cpp là 64 KiB. Mẫu đặt vắt qua biên khúc
// thứ nhất khi quét xuôi từ đầu, và vắt qua biên khúc thứ nhất khi quét lùi từ cuối.
constexpr std::size_t kChunk = std::size_t{64} * 1024;
constexpr std::size_t kHaystackSize = 200'000;
constexpr std::string_view kNeedle = "NEEDLE";
constexpr std::uint64_t kForwardHit = kChunk - 3;
constexpr std::uint64_t kBackwardHit = kHaystackSize - kChunk - 3;

[[nodiscard]] View bytes_of(std::string_view text) noexcept {
    return std::as_bytes(std::span(text));
}

template <class T>
[[nodiscard]] bool failed_with(const core::Result<T>& result, core::ErrorCode code) noexcept {
    return !result && result.error().code() == code;
}

// Dãy byte tất định từ một bộ sinh đồng dư tuyến tính, hạt giống là chính số byte: test không phụ
// thuộc <random>, và hai dãy khác cỡ thì khác nội dung.
[[nodiscard]] Buffer noise(std::size_t count) {
    Buffer bytes(count);
    auto state = static_cast<std::uint32_t>(count);
    for (std::byte& value : bytes) {
        state = (state * 1664525U) + 1013904223U;
        value = static_cast<std::byte>(state >> 24U);
    }
    return bytes;
}

// Mốc phản chiếu mẫu
// Tài nguyên ở space 0, binding theo luật dịch của lớp register (b +0, t +1000, u +2000, s +3000).
[[nodiscard]] Resource resource_at(std::string_view name, ResourceKind kind, std::uint32_t slot) {
    Resource resource;
    resource.name = name;
    resource.kind = kind;
    resource.slot = slot;
    resource.binding = slot + shader::binding_shift(shader::register_type(kind));
    return resource;
}

// Một biến float4 (16 byte) ở offset trong khối.
[[nodiscard]] Variable float4_at(std::string_view name, std::uint32_t offset) {
    Variable variable;
    variable.name = name;
    variable.offset = offset;
    variable.size = 16;
    variable.scalar = Scalar::kFloat;
    variable.bits = 32;
    variable.rows = 1;
    variable.columns = 4;
    return variable;
}

// Khối 32 byte "Frame" của cbuffer và khối 16 byte "Draw" của push constant.
[[nodiscard]] std::vector<Block> sample_blocks() {
    Block frame;
    frame.name = "Frame";
    frame.size = 32;
    frame.variables.push_back(float4_at("fog_color", 0));
    frame.variables.push_back(float4_at("sun_direction", 16));
    Block draw;
    draw.name = "Draw";
    draw.size = 16;
    draw.variables.push_back(float4_at("tint", 0));
    std::vector<Block> blocks;
    blocks.push_back(std::move(frame));
    blocks.push_back(std::move(draw));
    return blocks;
}

// Thêm một thuộc tính float 32 bit; location là thứ tự thêm.
void add_attribute(Attributes& list, std::string_view semantic, std::uint8_t components) {
    Attribute attribute;
    attribute.semantic = semantic;
    attribute.location = static_cast<std::uint32_t>(list.size());
    attribute.scalar = Scalar::kFloat;
    attribute.bits = 32;
    attribute.components = components;
    list.push_back(std::move(attribute));
}

// Pixel shader mẫu: cbuffer b0, texture t1, sampler s0 và một khối push constant.
[[nodiscard]] StageReflection pixel_reflection() {
    StageReflection reflection;
    reflection.stage = Stage::kPixel;
    reflection.entry = "main_ps";
    reflection.blocks = sample_blocks();
    Resource frame = resource_at("Frame", ResourceKind::kUniformBuffer, 0);
    frame.block = 0;
    Resource albedo = resource_at("albedo", ResourceKind::kTexture, 1);
    albedo.shape = shader::TextureShape::kTex2D;
    albedo.sample = Scalar::kFloat;
    Resource draw = resource_at("Draw", ResourceKind::kPushConstant, 0);
    draw.space = shader::kPushSpace;
    draw.block = 1;
    reflection.resources.push_back(std::move(draw));
    reflection.resources.push_back(resource_at("linear_sampler", ResourceKind::kSampler, 0));
    reflection.resources.push_back(std::move(albedo));
    reflection.resources.push_back(std::move(frame));
    add_attribute(reflection.inputs, "TEXCOORD", 2);
    add_attribute(reflection.inputs, "NORMAL", 3);
    add_attribute(reflection.outputs, "SV_Target", 4);
    shader::normalize(reflection);
    return reflection;
}

// Vertex shader mẫu: dùng chung cbuffer "Frame" với pixel shader, đầu ra khớp đầu vào của nó.
[[nodiscard]] StageReflection vertex_reflection() {
    StageReflection reflection;
    reflection.stage = Stage::kVertex;
    reflection.entry = "main_vs";
    reflection.blocks = sample_blocks();
    reflection.blocks.pop_back();
    Resource frame = resource_at("Frame", ResourceKind::kUniformBuffer, 0);
    frame.block = 0;
    reflection.resources.push_back(std::move(frame));
    add_attribute(reflection.inputs, "POSITION", 3);
    add_attribute(reflection.outputs, "TEXCOORD", 2);
    add_attribute(reflection.outputs, "NORMAL", 3);
    shader::normalize(reflection);
    return reflection;
}

// Mốc gói mẫu
// Pixel shader "terrain" với hai bản dịch SPIR-V (không define, và có hai define) cùng hai tệp phụ
// thuộc. Bytecode là byte giả: bộ đọc gói không hiểu nội dung của nó.
[[nodiscard]] PackageSource sample_source() {
    PackageSource source;
    source.name = "terrain";
    source.stage = Stage::kPixel;
    source.debug = true;
    source.options_hash = kOptionsHash;
    PackageVariant plain;
    plain.target = Target::kSpirV;
    plain.code = noise(40);
    plain.reflection = pixel_reflection();
    PackageVariant foggy;
    foggy.target = Target::kSpirV;
    foggy.defines = {"SHADOW=2", "FOG"};
    foggy.code = noise(52);
    foggy.reflection = pixel_reflection();
    source.variants.push_back(std::move(plain));
    source.variants.push_back(std::move(foggy));
    const shader::Dependency main_file{.path = "shaders/terrain.ps.hlsl", .hash = 0x1111};
    const shader::Dependency shared_file{.path = "shaders/common.hlsl", .hash = 0x2222};
    source.dependencies.push_back(main_file);
    source.dependencies.push_back(shared_file);
    return source;
}

[[nodiscard]] Buffer sample_file() {
    core::Result<Buffer> bytes = shader::write_package(sample_source());
    core::check(bytes.has_value(), "shader_tests: gói mẫu phải dựng được");
    return std::move(*bytes);
}

// Package::parse nhận quyền sở hữu một fs::Bytes: mỗi lượt đọc chép dữ liệu thử sang khối riêng.
[[nodiscard]] core::Result<Package> parse(View file) {
    fs::Bytes bytes(file.size());
    std::ranges::copy(file, bytes.span().begin());
    return Package::parse(std::move(bytes));
}

[[nodiscard]] bool is_corrupt(View file) {
    return failed_with(parse(file), core::ErrorCode::kCorrupt);
}

// Thông điệp lỗi của lượt đọc, rỗng khi đọc được. Thông điệp là chuỗi tĩnh nên sống lâu hơn Error.
[[nodiscard]] std::string_view parse_message(View file) {
    const core::Result<Package> package = parse(file);
    if (package) return {};
    return package.error().message();
}

[[nodiscard]] std::uint32_t load_u32(View file, std::size_t offset) noexcept {
    std::uint32_t value = 0;
    std::memcpy(&value, file.subspan(offset, sizeof(value)).data(), sizeof(value));
    return value;
}

// Một chỗ sửa trong tệp gói: ghi value (u32 little-endian) vào offset; message là thông điệp lỗi
// mà lượt đọc phải trả sau khi tổng kiểm được đóng dấu lại.
struct Patch {
    std::size_t offset = 0;
    std::uint32_t value = 0;
    std::string_view what;
    std::string_view message;
};

void apply(std::span<std::byte> file, const Patch& patch) noexcept {
    const std::span<std::byte> field = file.subspan(patch.offset, sizeof(patch.value));
    std::memcpy(field.data(), &patch.value, field.size());
}

// Đóng dấu lại tổng kiểm (XXH3-64 của cả tệp trừ chính trường 8 byte ở offset 48), để dữ liệu đã
// sửa đi qua bước kiểm tổng và chạm tới các bước kiểm sau nó. Tiền điều kiện: tệp đủ 64 byte.
void restamp(std::span<std::byte> file) {
    fs::Checksum sum;
    sum.update(file.first(kChecksumAt));
    sum.update(file.subspan(kChecksumAt + sizeof(std::uint64_t)));
    const std::uint64_t digest = sum.digest();
    std::memcpy(file.subspan(kChecksumAt, sizeof(digest)).data(), &digest, sizeof(digest));
}

// Mốc đọc gói
void package_reads_back_header_fields(Context& context) {
    const PackageSource source = sample_source();
    const core::Result<Package> package = parse(sample_file());
    context.expect(package.has_value(), "gói mẫu đọc lại được");
    if (!package) return;
    context.expect(package->name() == "terrain", "tên gói");
    context.expect(package->stage() == Stage::kPixel, "stage");
    context.expect(package->debug(), "cờ gỡ lỗi");
    context.expect(package->options_hash() == kOptionsHash, "băm tuỳ chọn dịch");
    context.expect(package->variants().size() == 2, "đủ hai bản dịch");
    const bool has_dependencies = std::ranges::equal(package->dependencies(), source.dependencies);
    context.expect(has_dependencies, "đủ hai tệp phụ thuộc, đúng đường dẫn và băm");
    context.expect(package->find(Target::kDxil) == nullptr, "gói không có bản DXIL");
    context.expect(package->find(Target::kSpirV, 0x1234) == nullptr, "gói không có khoá lạ");
}

// Một bản dịch đọc lại phải khớp bản đã ghi ở mọi trường.
void expect_variant(Context& context, const Package& package, const PackageVariant& wanted) {
    const std::uint64_t key = shader::variant_key(wanted.defines);
    const shader::Variant* found = package.find(wanted.target, key);
    context.expect(found != nullptr, "tìm được bản dịch theo đích và khoá");
    if (found == nullptr) return;
    context.expect(found->target == wanted.target, "đích dịch");
    context.expect(found->key == key, "khoá là băm của tập define");
    context.expect(found->defines == shader::variant_text(wanted.defines), "define ở dạng chuẩn");
    context.expect(std::ranges::equal(found->code, wanted.code), "bytecode giữ nguyên từng byte");
    context.expect(found->code_hash == fs::checksum(wanted.code), "băm bytecode là XXH3 của nó");
    context.expect(found->reflection == wanted.reflection, "phản chiếu giữ nguyên");
    const std::uint64_t fingerprint = shader::fingerprint(wanted.reflection);
    context.expect(found->reflection_hash == fingerprint, "băm phản chiếu là dấu vân của nó");
    const auto address = std::bit_cast<std::uintptr_t>(found->code.data());
    context.expect(address % 8 == 0, "bytecode nằm ở địa chỉ bội số 8");
}

void package_reads_back_every_variant(Context& context) {
    const PackageSource source = sample_source();
    const core::Result<Package> package = parse(sample_file());
    context.expect(package.has_value(), "gói mẫu đọc lại được");
    if (!package) return;
    for (const PackageVariant& wanted : source.variants) {
        expect_variant(context, *package, wanted);
    }
    const shader::Variant* plain = package->find(Target::kSpirV);
    context.expect(plain != nullptr && plain->defines.empty(), "khoá mặc định là bản không define");
}

void package_file_follows_the_byte_layout(Context& context) {
    const Buffer file = sample_file();
    const View whole(file);
    context.expect(std::ranges::equal(whole.first(4), bytes_of("F2SH")), "bốn byte đầu là F2SH");
    context.expect(load_u32(file, 4) == 1, "phiên bản định dạng là 1");
    context.expect(load_u32(file, 8) == file.size(), "trường cỡ tệp bằng cỡ thật");
    context.expect(load_u32(file, 12) == 2, "hai bản dịch");
    context.expect(load_u32(file, 16) == kVariantsAt, "bảng bản dịch ngay sau header");
    context.expect(load_u32(file, 20) == 2, "hai tệp phụ thuộc");
    context.expect(load_u32(file, 24) == kDependenciesAt, "bảng phụ thuộc ngay sau bảng bản dịch");
    const std::size_t second = kVariantsAt + kVariantSize;
    context.expect(load_u32(file, kVariantsAt + kCodeInVariant) % 8 == 0, "bytecode một căn 8 byte");
    context.expect(load_u32(file, second + kCodeInVariant) % 8 == 0, "bytecode hai căn 8 byte");
    Buffer stamped = file;
    restamp(stamped);
    context.expect(stamped == file, "tổng kiểm ở offset 48 phủ cả tệp trừ chính nó");
}

void write_rejects_empty_and_repeated_variants(Context& context) {
    PackageSource empty = sample_source();
    empty.variants.clear();
    const core::Result<Buffer> none = shader::write_package(empty);
    context.expect(failed_with(none, core::ErrorCode::kInvalidArgument), "không có bản dịch nào");
    PackageSource repeated = sample_source();
    repeated.variants.back().defines.clear();
    const core::Result<Buffer> twice = shader::write_package(repeated);
    context.expect(failed_with(twice, core::ErrorCode::kInvalidArgument), "hai bản trùng đích, khoá");
    context.expect(!twice && twice.error().detail() == "terrain", "chi tiết lỗi là tên gói");
}

void variant_keys_ignore_order_and_repeats(Context& context) {
    const std::vector<std::string> ordered{"FOG", "SHADOW=2"};
    const std::vector<std::string> shuffled{"SHADOW=2", "FOG", "FOG"};
    context.expect(shader::variant_text(shuffled) == "FOG;SHADOW=2", "bỏ trùng, sắp, nối bằng ;");
    const std::uint64_t key = shader::variant_key(ordered);
    context.expect(shader::variant_key(shuffled) == key, "thứ tự và lặp không đổi khoá");
    context.expect(key == fs::checksum(bytes_of("FOG;SHADOW=2")), "khoá là XXH3 của dạng chuẩn");
    context.expect(key == 0xDFBF'7F99'1A24'CB01ULL, "khoá trùng giá trị đo ở bản gốc");
    context.expect(shader::variant_key({}) == shader::kDefaultVariant, "tập rỗng là khoá mặc định");
}

// Mốc gói hỏng
void parse_rejects_truncated_files(Context& context) {
    const Buffer file = sample_file();
    const View whole(file);
    std::size_t caught = 0;
    for (std::size_t length = 0; length < file.size(); ++length) {
        caught += static_cast<std::size_t>(is_corrupt(whole.first(length)));
    }
    context.expect(caught == file.size(), "cắt ở độ dài nào cũng ra Corrupt");
    context.expect(parse_message({}) == "gói shader cụt", "tệp rỗng");
    context.expect(parse_message(whole.first(kHeaderSize - 1)) == "gói shader cụt", "thiếu header");
    context.expect(parse_message(whole.first(kHeaderSize)) == "gói shader sai cỡ", "chỉ có header");
    context.expect(parse_message(whole.first(file.size() - 1)) == "gói shader sai cỡ", "thiếu 1 byte");
}

// Lật mọi bit của byte ở index: tổng kiểm phủ cả tệp nên lượt đọc phải ra Corrupt.
[[nodiscard]] bool is_flip_caught(View file, std::size_t index) {
    Buffer bent(file.begin(), file.end());
    bent.at(index) ^= std::byte{0xFF};
    return is_corrupt(bent);
}

void parse_rejects_every_flipped_byte(Context& context) {
    const Buffer file = sample_file();
    std::size_t caught = 0;
    for (std::size_t index = 0; index < file.size(); ++index) {
        caught += static_cast<std::size_t>(is_flip_caught(file, index));
    }
    context.expect(caught == file.size(), "lật byte nào cũng bị bắt, kể cả trong header");
}

enum class Outcome : std::uint8_t {
    kAccepted,
    kCorrupt,
    kOtherError,
};

constexpr std::size_t kOutcomeCount = 3;

// Đọc mọi byte mà gói cho mượn: span trỏ ra ngoài vùng nhớ của gói thì ASan dừng tiến trình.
[[nodiscard]] std::uint64_t touch(const Package& package) {
    std::uint64_t sum = 0;
    for (const shader::Variant& variant : package.variants()) {
        sum += fs::checksum(variant.code);
    }
    return sum;
}

// Lật byte ở index rồi đóng dấu lại tổng kiểm: chỉ còn các bước kiểm cấu trúc đứng giữa dữ liệu
// hỏng và bộ đọc.
[[nodiscard]] Outcome restamped_flip(View file, std::size_t index) {
    Buffer bent(file.begin(), file.end());
    bent.at(index) ^= std::byte{0xFF};
    restamp(bent);
    const core::Result<Package> package = parse(bent);
    if (!package && package.error().code() == core::ErrorCode::kCorrupt) return Outcome::kCorrupt;
    if (!package) return Outcome::kOtherError;
    static_cast<void>(touch(*package));
    return Outcome::kAccepted;
}

void parse_survives_flips_with_a_fresh_checksum(Context& context) {
    const Buffer file = sample_file();
    std::array<std::size_t, kOutcomeCount> counts{};
    for (std::size_t index = 0; index < file.size(); ++index) {
        ++counts.at(std::to_underlying(restamped_flip(file, index)));
    }
    const std::size_t accepted = counts.at(std::to_underlying(Outcome::kAccepted));
    const std::size_t corrupt = counts.at(std::to_underlying(Outcome::kCorrupt));
    context.expect(counts.at(std::to_underlying(Outcome::kOtherError)) == 0, "không mã lỗi nào khác");
    context.expect(accepted + corrupt == file.size(), "byte nào cũng được xử lý, không sập");
    context.expect(corrupt > 0, "có byte mà sửa nó thì gói bị từ chối");
    context.expect(accepted > 0, "có byte (bytecode, băm) mà sửa nó gói vẫn hợp lệ");
}

constexpr std::string_view kBadKind = "gói shader sai magic hoặc phiên bản";
constexpr std::string_view kBadVariants = "gói shader sai bảng bản dịch";
constexpr std::string_view kBadDependencies = "gói shader sai bảng phụ thuộc";
constexpr std::string_view kBadName = "gói shader có tên sai vị trí";
constexpr std::string_view kBadPlace = "gói shader có bản dịch sai vị trí";
constexpr std::string_view kBadPath = "gói shader có đường dẫn phụ thuộc sai vị trí";
constexpr std::string_view kBadReflection = "phản chiếu shader cụt hoặc sai miền";
constexpr std::uint32_t kFar = 0xFFFF'FFF0U;
constexpr std::uint32_t kHuge = 0xFFFF'FFFFU;

constexpr std::array kPatches{
    Patch{.offset = 0, .value = 0x4853'3247U, .what = "magic sai", .message = kBadKind},
    Patch{.offset = 4, .value = 2, .what = "phiên bản 2", .message = kBadKind},
    Patch{.offset = 8, .value = 64, .what = "cỡ tệp sai", .message = "gói shader sai cỡ"},
    Patch{.offset = 12, .value = kHuge, .what = "số bản dịch quá lớn", .message = kBadVariants},
    Patch{.offset = 16, .value = kFar, .what = "bảng bản dịch ngoài tệp", .message = kBadVariants},
    Patch{.offset = 16, .value = 8, .what = "bảng bản dịch trong header", .message = kBadVariants},
    Patch{.offset = 20, .value = kHuge, .what = "số phụ thuộc quá lớn", .message = kBadDependencies},
    Patch{.offset = 24, .value = kFar, .what = "bảng phụ thuộc ngoài tệp", .message = kBadDependencies},
    Patch{.offset = 28, .value = kFar, .what = "tên ngoài tệp", .message = kBadName},
    Patch{.offset = 28, .value = 8, .what = "tên trong header", .message = kBadName},
    Patch{.offset = 32, .value = kHuge, .what = "tên quá dài", .message = kBadName},
    Patch{.offset = 36, .value = 99, .what = "stage 99", .message = "gói shader sai stage"},
    Patch{.offset = kVariantsAt, .value = 7, .what = "đích 7", .message = "gói shader sai đích dịch"},
    Patch{.offset = kVariantsAt + 4, .value = kFar, .what = "define ngoài tệp", .message = kBadPlace},
    Patch{.offset = kVariantsAt + 32, .value = kFar, .what = "bytecode ngoài tệp", .message = kBadPlace},
    Patch{.offset = kVariantsAt + 36, .value = kHuge, .what = "bytecode quá dài", .message = kBadPlace},
    Patch{.offset = kVariantsAt + 40, .value = kFar, .what = "phản chiếu ngoài tệp", .message = kBadPlace},
    Patch{.offset = kVariantsAt + 44, .value = 1, .what = "phản chiếu 1 byte", .message = kBadReflection},
    Patch{.offset = kDependenciesAt, .value = kFar, .what = "đường dẫn ngoài tệp", .message = kBadPath},
    Patch{.offset = kDependenciesAt + 4, .value = kHuge, .what = "đường dẫn quá dài", .message = kBadPath},
};

// Sửa một trường rồi đóng dấu lại tổng kiểm: lượt đọc phải dừng ở đúng bước kiểm của trường ấy.
void expect_patch_rejected(Context& context, View file, const Patch& patch) {
    Buffer bent(file.begin(), file.end());
    apply(bent, patch);
    restamp(bent);
    context.expect(parse_message(bent) == patch.message, patch.what);
}

void parse_rejects_bad_fields(Context& context) {
    const Buffer file = sample_file();
    for (const Patch& patch : kPatches) {
        expect_patch_rejected(context, file, patch);
    }
}

void parse_rejects_misplaced_code_and_repeated_keys(Context& context) {
    const Buffer file = sample_file();
    const std::size_t code_at = kVariantsAt + kCodeInVariant;
    const Patch shifted{.offset = code_at,
        .value = load_u32(file, code_at) + 4,
        .what = "bytecode lệch căn 8 byte",
        .message = kBadPlace};
    expect_patch_rejected(context, file, shifted);
    // Chép khoá của bản ghi một sang bản ghi hai: hai bản cùng đích SPIR-V thành trùng khoá.
    Buffer repeated = file;
    const View first_key = View(file).subspan(kVariantsAt + kKeyInVariant, sizeof(std::uint64_t));
    const std::size_t second_key = kVariantsAt + kVariantSize + kKeyInVariant;
    std::ranges::copy(first_key, std::span(repeated).subspan(second_key).begin());
    restamp(repeated);
    const std::string_view message = parse_message(repeated);
    context.expect(message == "gói shader có hai bản dịch trùng khoá", "hai bản ghi trùng khoá");
}

// Mốc đọc gói từ tệp
[[nodiscard]] bool write_temp_file(View file) {
    std::string text(file.size(), '\0');
    std::memcpy(text.data(), file.data(), file.size());
    const std::filesystem::path path(kTempFile);
    std::ofstream output(path, std::ios::binary);
    output.write(text.data(), static_cast<std::streamsize>(text.size()));
    return output.good();
}

void load_reads_a_file_and_reports_a_missing_one(Context& context) {
    const Buffer file = sample_file();
    context.expect(write_temp_file(file), "ghi được tệp tạm ở thư mục làm việc");
    const core::Result<Package> loaded = Package::load(kTempFile);
    std::error_code failure;
    const bool removed = std::filesystem::remove(std::filesystem::path(kTempFile), failure);
    context.expect(removed && !failure, "xoá được tệp tạm");
    context.expect(loaded.has_value(), "load đọc được gói từ tệp");
    context.expect(loaded && loaded->name() == "terrain", "gói từ tệp mang đúng tên");
    context.expect(loaded && loaded->variants().size() == 2, "gói từ tệp đủ hai bản dịch");
    const core::Result<Package> absent = Package::load(kTempFile);
    context.expect(failed_with(absent, core::ErrorCode::kNotFound), "tệp không có là NotFound");
}

// Mốc phản chiếu
void reflection_round_trips(Context& context) {
    const StageReflection reflection = pixel_reflection();
    const Buffer bytes = shader::encode(reflection);
    const core::Result<StageReflection> decoded = shader::decode(bytes);
    context.expect(decoded && *decoded == reflection, "đọc lại ra đúng phản chiếu đã ghi");
    const std::uint64_t fingerprint = shader::fingerprint(reflection);
    context.expect(fingerprint == fs::checksum(bytes), "dấu vân là XXH3 của dạng nhị phân");
    StageReflection changed = reflection;
    changed.resources.front().count = 4;
    context.expect(shader::fingerprint(changed) != fingerprint, "đổi một trường thì dấu vân đổi");
    context.expect(reflection.resources.front().name == "Frame", "normalize xếp b0 đứng đầu");
    context.expect(reflection.resources.back().name == "Draw", "push constant đứng cuối");
    context.expect(reflection.resources.back().block == 1, "khối đánh số theo thứ tự tài nguyên");
    const std::string text = shader::describe(reflection);
    context.expect(text.starts_with("stage ps entry main_ps\n"), "describe: dòng đầu");
    context.expect(text.contains("  space 0 t1 binding 1001 Texture albedo\n"), "describe: texture");
    context.expect(text.contains("  space 0 s0 binding 3000 Sampler linear_sampler\n"), "sampler");
    context.expect(text.contains("      +16 16 byte float32 1x4 sun_direction\n"), "biến của khối");
    context.expect(text.contains("  in 1 NORMAL0 float32x3\n"), "describe: đầu vào");
}

[[nodiscard]] bool is_decode_corrupt(View data) {
    return failed_with(shader::decode(data), core::ErrorCode::kCorrupt);
}

[[nodiscard]] std::string_view decode_message(View data) {
    const core::Result<StageReflection> decoded = shader::decode(data);
    if (decoded) return {};
    return decoded.error().message();
}

// Ghi 0xFF vào byte ở index: lượt đọc hoặc nhận, hoặc ra Corrupt; không sập, không mã lỗi khác.
[[nodiscard]] bool is_bend_handled(View data, std::size_t index) {
    Buffer bent(data.begin(), data.end());
    bent.at(index) = std::byte{0xFF};
    const core::Result<StageReflection> decoded = shader::decode(bent);
    return decoded.has_value() || decoded.error().code() == core::ErrorCode::kCorrupt;
}

void reflection_rejects_truncated_and_bent_bytes(Context& context) {
    const Buffer bytes = shader::encode(pixel_reflection());
    const View whole(bytes);
    std::size_t caught = 0;
    std::size_t handled = 0;
    for (std::size_t index = 0; index < bytes.size(); ++index) {
        caught += static_cast<std::size_t>(is_decode_corrupt(whole.first(index)));
        handled += static_cast<std::size_t>(is_bend_handled(whole, index));
    }
    context.expect(caught == bytes.size(), "cắt ở độ dài nào cũng ra Corrupt");
    context.expect(handled == bytes.size(), "bẻ byte nào cũng được xử lý, không sập");
    Buffer versioned = bytes;
    versioned.at(0) = std::byte{9};
    context.expect(decode_message(versioned) == "phản chiếu shader sai phiên bản", "phiên bản 9");
    Buffer staged = bytes;
    staged.at(1) = std::byte{200};
    context.expect(decode_message(staged) == kBadReflection, "stage ngoài miền của enum");
    Buffer padded = bytes;
    padded.push_back(std::byte{0});
    context.expect(decode_message(padded) == kBadReflection, "byte thừa ở cuối");
}

void merge_unions_stages(Context& context) {
    const std::array stages{vertex_reflection(), pixel_reflection()};
    const core::Result<shader::ProgramReflection> program = shader::merge(stages);
    context.expect(program.has_value(), "vertex và pixel gộp được");
    if (!program) return;
    context.expect(program->resources.size() == 4, "cbuffer dùng chung chỉ có một mục");
    const Resource& frame = program->resources.front();
    context.expect(frame.name == "Frame" && frame.block == 0, "Frame đứng đầu, khối số 0");
    const bool is_shared = frame.stages.has(Stage::kVertex) && frame.stages.has(Stage::kPixel);
    context.expect(is_shared, "Frame mang cả hai stage");
    context.expect(!program->resources.back().stages.has(Stage::kVertex), "Draw chỉ của pixel");
    context.expect(program->blocks.size() == 2, "hai khối: Frame và Draw");
    context.expect(program->inputs == stages.front().inputs, "đầu vào là của vertex shader");
    context.expect(program->outputs == stages.back().outputs, "đầu ra là của pixel shader");
    const std::array reversed{stages.back(), stages.front()};
    const core::Result<shader::ProgramReflection> swapped = shader::merge(reversed);
    const bool is_same = swapped && shader::fingerprint(*swapped) == shader::fingerprint(*program);
    context.expect(is_same, "thứ tự stage không đổi dấu vân của chương trình");
}

[[nodiscard]] std::string_view merge_message(std::span<const StageReflection> stages) {
    const core::Result<shader::ProgramReflection> program = shader::merge(stages);
    if (program) return {};
    return program.error().message();
}

void merge_reports_conflicts(Context& context) {
    const StageReflection vertex = vertex_reflection();
    const StageReflection pixel = pixel_reflection();
    const std::array twice{pixel, pixel};
    context.expect(merge_message(twice) == "hai stage trùng loại", "hai pixel shader");
    StageReflection retyped = vertex;
    retyped.resources.front().kind = ResourceKind::kPushConstant;
    const std::array clashing{retyped, pixel};
    const std::string_view clash = merge_message(clashing);
    context.expect(clash == "một chỗ gắn, hai khai báo khác nhau", "b0 khác loại giữa hai stage");
    StageReflection moved = vertex;
    moved.resources.front().slot = 5;
    const std::array renamed{moved, pixel};
    context.expect(merge_message(renamed) == "cùng tên mà khác chỗ gắn", "Frame ở b5 và b0");
    StageReflection resized = vertex;
    resized.blocks.front().size = 48;
    const std::array uneven{resized, pixel};
    const std::string_view layout = merge_message(uneven);
    context.expect(layout == "cbuffer khác bố cục giữa các stage", "Frame 48 byte và 32 byte");
    StageReflection dangling = vertex;
    dangling.resources.front().block = 9;
    const std::array broken{dangling, pixel};
    const std::string_view missing = merge_message(broken);
    context.expect(missing == "phản chiếu trỏ tới cbuffer không có", "chỉ số khối ngoài mảng");
}

void interface_matches_outputs_to_inputs(Context& context) {
    const StageReflection vertex = vertex_reflection();
    const StageReflection pixel = pixel_reflection();
    context.expect(shader::check_interface(vertex, pixel).has_value(), "đầu ra khớp đầu vào");
    StageReflection narrower = pixel;
    narrower.inputs.front().components = 1;
    context.expect(shader::check_interface(vertex, narrower).has_value(), "đọc ít thành phần hơn");
    StageReflection hungry = pixel;
    add_attribute(hungry.inputs, "COLOR", 4);
    const core::Status absent = shader::check_interface(vertex, hungry);
    const bool is_absent = !absent && absent.error().message() == "đầu vào không có ở stage trước";
    context.expect(is_absent, "pixel đòi COLOR mà vertex không xuất");
    StageReflection wider = pixel;
    wider.inputs.front().components = 4;
    const core::Status mismatched = shader::check_interface(vertex, wider);
    const bool is_mismatched = !mismatched && mismatched.error().message() == "đầu vào khác kiểu với stage trước";
    context.expect(is_mismatched, "pixel đọc 4 thành phần, vertex xuất 2");
}

// Mốc types
[[nodiscard]] bool is_tag_round_trip(Stage stage) noexcept {
    return shader::parse_stage(shader::tag(stage)) == stage;
}

constexpr shader::ShaderModel kModel60{.major = 6, .minor = 0};
constexpr shader::ShaderModel kModel65{.major = 6, .minor = 5};
constexpr shader::ShaderModel kModel68{.major = 6, .minor = 8};

struct ModelCase {
    std::string_view text;
    std::optional<shader::ShaderModel> model;
};

constexpr std::array kModelCases{
    ModelCase{.text = "6.0", .model = kModel60},
    ModelCase{.text = "6.5", .model = kModel65},
    ModelCase{.text = "6_8", .model = kModel68},
    ModelCase{.text = "6.9", .model = std::nullopt},
    ModelCase{.text = "5.1", .model = std::nullopt},
    ModelCase{.text = "7.0", .model = std::nullopt},
    ModelCase{.text = "6-5", .model = std::nullopt},
    ModelCase{.text = "65", .model = std::nullopt},
    ModelCase{.text = "6.55", .model = std::nullopt},
    ModelCase{.text = "a.b", .model = std::nullopt},
};

void stages_targets_and_models_parse(Context& context) {
    std::size_t matched = 0;
    for (std::size_t index = 0; index < shader::kStageCount; ++index) {
        matched += static_cast<std::size_t>(is_tag_round_trip(static_cast<Stage>(index)));
    }
    context.expect(matched == shader::kStageCount, "parse_stage là chiều ngược của tag");
    context.expect(shader::parse_stage("ps") == Stage::kPixel, "ps là pixel");
    context.expect(shader::tag(Stage::kLibrary) == "lib", "library là lib");
    context.expect(!shader::parse_stage("xs") && !shader::parse_stage(""), "tên stage lạ, rỗng");
    context.expect(shader::parse_target("spirv") == Target::kSpirV, "spirv");
    context.expect(shader::parse_target("dxil") == Target::kDxil, "dxil");
    context.expect(!shader::parse_target("SPIRV"), "tên đích phân biệt hoa thường");
    context.expect(shader::name(Target::kSpirV) == "spirv", "tên của đích SPIR-V");
    context.expect(!shader::parse_model(""), "shader model rỗng");
    for (const ModelCase& one : kModelCases) {
        context.expect(shader::parse_model(one.text) == one.model, one.text);
    }
}

// Mốc fs: tổng kiểm và codec
void checksum_is_stable_xxh3(Context& context) {
    // Giá trị của dãy rỗng là vector thử công khai của XXH3-64 seed 0; hai giá trị kia đo bằng
    // xxhash 0.8.3 qua fs::checksum của Forge2 và của bản chép.
    const View text = bytes_of(kSampleText);
    context.expect(text.size() == 21, "chuỗi mẫu dài 21 byte UTF-8");
    context.expect(fs::checksum(text) == 0x5149'1831'14FC'90FDULL, "XXH3-64 của chuỗi mẫu");
    context.expect(fs::checksum({}) == 0x2D06'8005'38D3'94C2ULL, "XXH3-64 của dãy rỗng");
    std::array<std::byte, 256> ramp{};
    for (std::size_t index = 0; index < ramp.size(); ++index) {
        ramp.at(index) = static_cast<std::byte>(index);
    }
    context.expect(fs::checksum(ramp) == 0x9408'A443'3B95'2D71ULL, "XXH3-64 của dãy 0..255");
    fs::Checksum sum;
    sum.update(text.first(5));
    sum.update(text.subspan(5));
    context.expect(sum.digest() == fs::checksum(text), "tính dần qua hai khúc ra cùng kết quả");
}

// Khối 4 KiB dễ nén: một câu lặp lại.
[[nodiscard]] Buffer repeated_text() {
    Buffer data(4096);
    const View text = bytes_of(kSampleText);
    for (std::size_t index = 0; index < data.size(); ++index) {
        data.at(index) = text.subspan(index % text.size()).front();
    }
    return data;
}

void expect_codec_round_trip(Context& context, fs::buny::Format format) {
    const Buffer data = repeated_text();
    const int level = fs::codec::levels(format).standard;
    Buffer packed(data.size() - 1);
    const core::Result<std::optional<std::size_t>> wrote = fs::codec::encode(format, level, data, packed);
    const std::size_t size = wrote ? wrote->value_or(0) : 0;
    context.expect(size != 0 && size < data.size() / 4, "khối lặp nén còn dưới một phần tư");
    const View stored = View(packed).first(size);
    Buffer restored(data.size());
    context.expect(fs::codec::decode(format, stored, restored).has_value(), "giải nén được");
    context.expect(restored == data, "giải nén ra đúng dữ liệu gốc");
    Buffer shorter(data.size() - 1);
    const core::Status wrong = fs::codec::decode(format, stored, shorter);
    context.expect(failed_with(wrong, core::ErrorCode::kCorrupt), "cỡ ra sai là Corrupt");
    const Buffer random = noise(4096);
    const core::Result<std::optional<std::size_t>> raw = fs::codec::encode(format, level, random, packed);
    context.expect(raw && !raw->has_value(), "khối không nén được thì nullopt để lưu thô");
}

void codec_round_trips_lz4_and_zstd(Context& context) {
    expect_codec_round_trip(context, fs::buny::Format::kLz4Blocks);
    expect_codec_round_trip(context, fs::buny::Format::kZstdBlocks);
    const Buffer data = repeated_text();
    Buffer out(data.size());
    const auto packed = fs::codec::encode(fs::buny::Format::kRaw, 0, data, out);
    context.expect(failed_with(packed, core::ErrorCode::kInvalidArgument), "Raw không nén theo khối");
    const core::Status unpacked = fs::codec::decode(fs::buny::Format::kRaw, data, out);
    context.expect(failed_with(unpacked, core::ErrorCode::kInvalidArgument), "Raw không giải nén");
}

// Mốc fs: luồng
// Luồng chỉ đọc trên một vùng nhớ; mỗi lần read trả tối đa step byte để read_full phải lặp, và lần
// đọc thứ failing_read (đếm từ 1) trả lỗi Io. Dự án chưa có bản cài đặt Stream nào trong bộ nhớ.
class MemoryStream final : public fs::Stream {
public:
    MemoryStream(View data, std::size_t step) noexcept : Stream(fs::Mode::kRead), data_(data), step_(step) {}

    [[nodiscard]] core::Result<std::size_t> read(std::span<std::byte> out) override {
        ++reads_;
        if (reads_ == failing_read_) return core::fail(core::ErrorCode::kIo, "lỗi đọc giả");
        const std::size_t start = std::min(position_, data_.size());
        const std::size_t count = std::min({out.size(), data_.size() - start, step_});
        std::ranges::copy(data_.subspan(start, count), out.begin());
        position_ += count;
        return count;
    }

    [[nodiscard]] core::Status seek(fs::Seek base, std::int64_t offset) override {
        const core::Result<std::uint64_t> target = fs::seek_target(base, offset, position_, data_.size());
        if (!target) return std::unexpected(target.error());
        position_ = *target;
        return core::ok();
    }

    [[nodiscard]] std::uint64_t position() const noexcept override { return position_; }
    [[nodiscard]] core::Result<std::uint64_t> size() const override { return data_.size(); }

    void fail_at_read(std::uint32_t number) noexcept { failing_read_ = number; }

private:
    View data_;
    std::size_t step_;
    std::size_t position_ = 0;
    std::uint32_t reads_ = 0;
    std::uint32_t failing_read_ = 0;
};

void plant(Buffer& data, std::uint64_t position) {
    std::ranges::copy(bytes_of(kNeedle), std::span(data).subspan(position).begin());
}

// 200 000 byte chỉ gồm 'a', 'b', 'c', với mẫu ở kForwardHit và kBackwardHit.
[[nodiscard]] Buffer haystack() {
    Buffer data = noise(kHaystackSize);
    for (std::byte& value : data) {
        value = static_cast<std::byte>('a' + (std::to_integer<unsigned>(value) % 3U));
    }
    plant(data, kForwardHit);
    plant(data, kBackwardHit);
    return data;
}

[[nodiscard]] bool is_found_at(const Found& found, std::uint64_t position) noexcept {
    return found && *found == position;
}

[[nodiscard]] bool is_missing(const Found& found) noexcept {
    return found && !found->has_value();
}

void find_sees_matches_across_chunk_borders(Context& context) {
    const Buffer data = haystack();
    const View needle = bytes_of(kNeedle);
    const std::uint64_t whole = data.size();
    MemoryStream stream(data, 4096);
    const std::uint64_t short_reach = kForwardHit + needle.size() - 1;
    context.expect(is_missing(fs::find(stream, needle, short_reach)), "mẫu phải nằm trọn max_bytes");
    context.expect(stream.position() == 0, "không thấy thì vị trí về chỗ cũ");
    context.expect(is_found_at(fs::find(stream, needle, whole), kForwardHit), "mẫu vắt biên khúc");
    context.expect(stream.position() == kForwardHit, "thấy thì luồng đứng ở đầu chỗ khớp");
    context.expect(stream.seek(fs::Seek::kCurrent, 1).has_value(), "bước qua chỗ khớp");
    context.expect(is_found_at(fs::find(stream, needle, whole), kBackwardHit), "chỗ khớp kế");
    context.expect(stream.seek(fs::Seek::kCurrent, 1).has_value(), "bước qua chỗ khớp thứ hai");
    context.expect(is_missing(fs::find(stream, needle, whole)), "hết chỗ khớp");
    context.expect(stream.position() == kBackwardHit + 1, "hết chỗ khớp thì vị trí về chỗ cũ");
    context.expect(is_found_at(fs::find(stream, {}, whole), kBackwardHit + 1), "mẫu rỗng khớp ngay");
}

void rfind_sees_matches_across_chunk_borders(Context& context) {
    const Buffer data = haystack();
    const View needle = bytes_of(kNeedle);
    const std::uint64_t whole = data.size();
    MemoryStream stream(data, 4096);
    context.expect(stream.seek(fs::Seek::kEnd, 0).has_value(), "tới cuối luồng");
    context.expect(is_missing(fs::rfind(stream, needle, needle.size() - 1)), "tầm ngắn hơn mẫu");
    context.expect(stream.position() == whole, "không thấy thì vị trí về chỗ cũ");
    context.expect(is_found_at(fs::rfind(stream, needle, whole), kBackwardHit), "mẫu vắt biên khúc");
    context.expect(stream.position() == kBackwardHit, "thấy thì luồng đứng ở đầu chỗ khớp");
    context.expect(is_found_at(fs::rfind(stream, needle, whole), kForwardHit), "chỗ khớp đứng trước");
    context.expect(is_missing(fs::rfind(stream, needle, whole)), "hết chỗ khớp phía trước");
    context.expect(stream.position() == kForwardHit, "hết chỗ khớp thì vị trí về chỗ cũ");
}

void find_restores_position_after_a_read_error(Context& context) {
    const Buffer data = haystack();
    MemoryStream stream(data, 4096);
    context.expect(stream.seek(fs::Seek::kBegin, 100).has_value(), "tới vị trí 100");
    stream.fail_at_read(2);
    const Found found = fs::find(stream, bytes_of(kNeedle), data.size());
    context.expect(failed_with(found, core::ErrorCode::kIo), "lỗi đọc đi ra tới người gọi");
    context.expect(stream.position() == 100, "lỗi thì vị trí vẫn về chỗ cũ");
}

void read_helpers_loop_until_full_or_end(Context& context) {
    const Buffer data = noise(2000);
    const View whole(data);
    MemoryStream stream(data, 7);
    Buffer buffer(100);
    const core::Result<std::size_t> got = fs::read_full(stream, buffer);
    context.expect(got && *got == 100, "read_full lặp tới khi đầy dù mỗi lần chỉ được 7 byte");
    context.expect(std::ranges::equal(buffer, whole.first(100)), "đúng 100 byte đầu");
    const core::Result<fs::Bytes> rest = fs::read_all(stream);
    const bool is_rest = rest && std::ranges::equal(rest->span(), whole.subspan(100));
    context.expect(is_rest, "read_all lấy trọn phần còn lại");
    context.expect(stream.at_end(), "đã chạm cuối luồng");
    const core::Result<std::size_t> none = fs::read_full(stream, buffer);
    context.expect(none && *none == 0, "ở cuối luồng read_full trả 0, không lỗi");
    const core::Result<std::uint64_t> tail = fs::seek_target(fs::Seek::kEnd, -3, 0, 10);
    context.expect(tail && *tail == 7, "lùi 3 từ cuối luồng 10 byte");
    const core::Result<std::uint64_t> before = fs::seek_target(fs::Seek::kBegin, -1, 0, 10);
    context.expect(failed_with(before, core::ErrorCode::kInvalidArgument), "seek tới vị trí âm");
}

// Mốc fs: bảng băm Buny
void buny_table_finds_every_name(Context& context) {
    constexpr std::uint32_t kNameCount = 100;
    std::vector<std::string> names;
    names.reserve(kNameCount);
    for (std::uint32_t index = 0; index < kNameCount; ++index) {
        names.push_back(std::format("data/mesh_{}.glb", index));
    }
    std::vector<std::string_view> views(names.begin(), names.end());
    const std::optional<fs::buny::HashTable> table = fs::buny::HashTable::build(views);
    context.expect(table.has_value(), "100 tên khác nhau dựng được bảng");
    if (!table) return;
    context.expect(table->seed() == 0 && table->slots() == 201, "seed và số ô như bản gốc");
    const std::uint64_t words = fs::checksum(std::as_bytes(table->words()));
    context.expect(words == 0x5049'C25A'47AF'F08EULL, "bảng trùng từng word với bản gốc");
    std::size_t found = 0;
    for (std::size_t index = 0; index < views.size(); ++index) {
        found += static_cast<std::size_t>(table->candidate(views.at(index)) == index);
    }
    context.expect(found == views.size(), "tên nào cũng tra ra đúng chỉ số node của nó");
    views.back() = views.front();
    context.expect(!fs::buny::HashTable::build(views), "hai tên trùng thì không dựng được bảng");
}

struct NameCase {
    std::string_view name;
    bool is_safe = false;
};

constexpr std::array kNameCases{
    NameCase{.name = "a", .is_safe = true},
    NameCase{.name = "data/mesh/a.glb", .is_safe = true},
    NameCase{.name = "a/.../b", .is_safe = true},
    NameCase{.name = "/a"},
    NameCase{.name = "a/"},
    NameCase{.name = "a//b"},
    NameCase{.name = "."},
    NameCase{.name = "a/./b"},
    NameCase{.name = "a/../b"},
    NameCase{.name = "a/.."},
    NameCase{.name = "a\\b"},
    NameCase{.name = "c:/x"},
};

void buny_hash_and_names_follow_the_original(Context& context) {
    const View text = bytes_of(kSampleText);
    const std::uint64_t plain = fs::buny::murmur64a(text, 0);
    context.expect(plain == 0xE9A5'4E92'DEA7'7CB3ULL, "MurmurHash64A seed 0 của chuỗi mẫu");
    const std::uint64_t seeded = fs::buny::murmur64a(text, 7);
    context.expect(seeded == 0x438A'672A'1CB3'A33EULL, "MurmurHash64A seed 7 của chuỗi mẫu");
    context.expect(fs::buny::murmur64a({}, 0) == 0, "MurmurHash64A của dãy rỗng với seed 0");
    context.expect(!fs::buny::is_safe_name(""), "tên rỗng không an toàn");
    for (const NameCase& one : kNameCases) {
        context.expect(fs::buny::is_safe_name(one.name) == one.is_safe, one.name);
    }
}

// Slang ghi vào DXIL hậu tố "_0" sau mọi tên và mang semantic, còn SPIR-V mang tên sạch nhưng không
// có semantic: phản chiếu chuẩn lấy tên của SPIR-V và semantic của DXIL (shader/detail/reconcile.hpp).
void reconcile_takes_names_from_spirv_and_semantics_from_dxil(Context& context) {
    StageReflection truth = pixel_reflection();
    truth.inputs.back().index = 3;
    truth.outputs.front().index = 2;
    StageReflection spirv = truth;
    for (Attribute& attribute : spirv.inputs) {
        attribute.semantic.clear();
        attribute.index = 0;
    }
    for (Attribute& attribute : spirv.outputs) {
        attribute.semantic.clear();
        attribute.index = 0;
    }
    StageReflection dxil = truth;
    for (Resource& resource : dxil.resources) resource.name += "_0";
    for (Block& block : dxil.blocks) {
        block.name += "_0";
        for (Variable& variable : block.variables) variable.name += "_0";
    }
    const core::Result<StageReflection> merged = shader::detail::reconcile(spirv, dxil);
    context.expect(merged.has_value(), "hai bên cùng bố cục thì ghép được");
    if (!merged) return;
    context.expect(*merged == truth, "tên sạch của SPIR-V, semantic và index của DXIL");
}

// Mỗi chỗ hai bên bất đồng về bố cục là một lỗi Internal, không để lọt thành phản chiếu sai.
struct Drift {
    std::string_view what;
    void (*mutate)(StageReflection&);
};

constexpr std::array kDrifts{
    Drift{.what = "slot của tài nguyên", .mutate = [](StageReflection& side) { side.resources.front().slot += 1; }},
    Drift{.what = "binding của tài nguyên", .mutate = [](StageReflection& side) { side.resources.back().binding += 1; }},
    Drift{.what = "thiếu một tài nguyên", .mutate = [](StageReflection& side) { side.resources.pop_back(); }},
    Drift{.what = "loại tài nguyên",
        .mutate = [](StageReflection& side) { side.resources.at(1).kind = ResourceKind::kBuffer; }},
    Drift{.what = "offset của biến cbuffer",
        .mutate = [](StageReflection& side) { side.blocks.front().variables.back().offset += 4; }},
    Drift{.what = "số phần tử mảng của biến cbuffer",
        .mutate = [](StageReflection& side) { side.blocks.front().variables.front().elements = 2; }},
    Drift{.what = "cỡ cbuffer", .mutate = [](StageReflection& side) { side.blocks.front().size = 48; }},
    Drift{.what = "thiếu một biến cbuffer",
        .mutate = [](StageReflection& side) { side.blocks.front().variables.pop_back(); }},
    Drift{.what = "location của đầu vào", .mutate = [](StageReflection& side) { side.inputs.front().location = 9; }},
    Drift{.what = "số thành phần của đầu ra",
        .mutate = [](StageReflection& side) { side.outputs.front().components = 2; }},
    Drift{.what = "thiếu một đầu vào", .mutate = [](StageReflection& side) { side.inputs.pop_back(); }},
    Drift{.what = "tên entry", .mutate = [](StageReflection& side) { side.entry = "other"; }},
};

void reconcile_reports_every_kind_of_layout_drift(Context& context) {
    const StageReflection truth = pixel_reflection();
    const core::Result<StageReflection> same = shader::detail::reconcile(truth, truth);
    context.expect(same.has_value() && *same == truth, "hai bên y hệt nhau thì ghép nguyên");
    for (const Drift& drift : kDrifts) {
        StageReflection dxil = truth;
        drift.mutate(dxil);
        const core::Result<StageReflection> merged = shader::detail::reconcile(truth, dxil);
        context.expect(failed_with(merged, core::ErrorCode::kInternal), drift.what);
    }
}

// Bảng location theo semantic của bộ shader chuyển từ client gốc: đầu vào đỉnh và biến truyền mỗi
// bên một bảng (khớp INPUT_LOCATIONS và VARYING_LOCATIONS của TOOLS/port/hlsl_origin.py).
struct SlotCase {
    bool vertex_input = false;
    std::string_view semantic;
    std::uint32_t index = 0;
    std::optional<std::uint32_t> location;
};

constexpr std::array kSlotCases{
    SlotCase{.vertex_input = true, .semantic = "POSITION", .index = 0, .location = 0},
    SlotCase{.vertex_input = true, .semantic = "BLENDINDICES", .index = 0, .location = 2},
    SlotCase{.vertex_input = true, .semantic = "TEXCOORD", .index = 0, .location = 6},
    SlotCase{.vertex_input = true, .semantic = "TEXCOORD", .index = 7, .location = 13},
    SlotCase{.vertex_input = true, .semantic = "TEXCOORD", .index = 8, .location = std::nullopt},
    SlotCase{.vertex_input = true, .semantic = "TANGENT", .index = 1, .location = 15},
    SlotCase{.vertex_input = false, .semantic = "TEXCOORD", .index = 0, .location = 0},
    SlotCase{.vertex_input = false, .semantic = "TEXCOORD", .index = 10, .location = 10},
    SlotCase{.vertex_input = false, .semantic = "TEXCOORD", .index = 11, .location = std::nullopt},
    SlotCase{.vertex_input = false, .semantic = "COLOR", .index = 1, .location = 12},
    SlotCase{.vertex_input = false, .semantic = "NORMAL", .index = 0, .location = 15},
    SlotCase{.vertex_input = false, .semantic = "POSITION", .index = 0, .location = std::nullopt},
    SlotCase{.vertex_input = false, .semantic = "BINORMAL", .index = 0, .location = std::nullopt},
};

void semantic_location_follows_the_origin_tables(Context& context) {
    for (const SlotCase& one : kSlotCases) {
        const std::optional<std::uint32_t> found = shader::semantic_location(one.vertex_input, one.semantic, one.index);
        context.expect(found == one.location, std::format("{}{} vertex_input={}", one.semantic, one.index,
                                                  one.vertex_input));
    }
}

// Ở Locations::kSemantic chữ ký DXIL còn đầu vào khai mà không dùng, SPIR-V của Slang thì bỏ hẳn: đối
// chiếu bỏ đầu vào thừa ấy theo location. Ở kDeclared cùng chỗ thừa ấy vẫn là lỗi, và đầu vào SPIR-V
// không có ở DXIL là lỗi ở cả hai chế độ.
void reconcile_by_semantic_drops_unused_dxil_inputs(Context& context) {
    const StageReflection truth = pixel_reflection();
    StageReflection dxil = truth;
    Attribute unused = dxil.inputs.front();
    unused.semantic = "TEXCOORD";
    unused.index = 5;
    unused.location = 5;
    dxil.inputs.push_back(std::move(unused));
    shader::normalize(dxil);
    StageReflection spirv = truth;
    for (Attribute& attribute : spirv.inputs) {
        attribute.semantic.clear();
    }
    const core::Result<StageReflection> semantic = shader::detail::reconcile(spirv, dxil, shader::Locations::kSemantic);
    context.expect(semantic.has_value() && *semantic == truth, "đầu vào thừa của DXIL bị bỏ, semantic lấy đúng chỗ");
    const core::Result<StageReflection> declared = shader::detail::reconcile(spirv, dxil, shader::Locations::kDeclared);
    context.expect(failed_with(declared, core::ErrorCode::kInternal), "kDeclared vẫn đòi hai bên khớp đủ");
    StageReflection missing = dxil;
    missing.inputs.erase(missing.inputs.begin());
    const core::Result<StageReflection> absent = shader::detail::reconcile(spirv, missing, shader::Locations::kSemantic);
    context.expect(failed_with(absent, core::ErrorCode::kInternal), "đầu vào SPIR-V không có ở DXIL là lỗi");
}

// Bộ dựng SPIR-V tay cho test phản chiếu.
using SpirvWords = std::vector<std::uint32_t>;

// Chuỗi literal của SPIR-V: UTF-8, kết thúc bằng byte 0, đệm tới bội 4 byte, little-endian.
[[nodiscard]] SpirvWords spirv_literal(std::string_view text) {
    SpirvWords words((text.size() / 4) + 1, 0U);
    for (std::size_t index = 0; index < text.size(); ++index) {
        const auto byte = static_cast<std::uint32_t>(static_cast<unsigned char>(text[index]));
        words.at(index / 4) |= byte << ((index % 4) * 8);
    }
    return words;
}

// Một lệnh: word đầu là (số word << 16) | opcode, rồi toán hạng.
void spirv_op(SpirvWords& module, std::uint32_t code, const SpirvWords& operands) {
    const auto count = static_cast<std::uint32_t>(operands.size() + 1);
    module.push_back((count << 16U) | code);
    module.insert(module.end(), operands.begin(), operands.end());
}

// Lệnh có chuỗi đứng sau các toán hạng head.
void spirv_named(SpirvWords& module, std::uint32_t code, const SpirvWords& head, std::string_view text) {
    SpirvWords operands = head;
    const SpirvWords packed = spirv_literal(text);
    operands.insert(operands.end(), packed.begin(), packed.end());
    spirv_op(module, code, operands);
}

// Đúng dạng Slang 2026.17 sinh cho `float3x4 bones[4]; float4x4 viewProj;` ma trận theo cột (đã
// đối chiếu spirv-dis): mảng bọc trong struct `_Array_*` một thành viên, RowMajor và MatrixStride
// của mảng nằm trên thành viên của lớp bọc. Id: 1 float, 2 main, 3 vec4, 4 mat3v4, 5 int, 6 hằng
// 4, 7 mảng, 8 lớp bọc, 9 mat4v4, 10 khối, 11 con trỏ, 12 biến.
[[nodiscard]] Buffer wrapped_matrix_module() {
    constexpr std::uint32_t kName = 5;
    constexpr std::uint32_t kMemberName = 6;
    constexpr std::uint32_t kDecorate = 71;
    constexpr std::uint32_t kMemberDecorate = 72;
    constexpr std::uint32_t kBlock = 2;
    constexpr std::uint32_t kRowMajor = 4;
    constexpr std::uint32_t kArrayStride = 6;
    constexpr std::uint32_t kMatrixStride = 7;
    constexpr std::uint32_t kBinding = 33;
    constexpr std::uint32_t kDescriptorSet = 34;
    constexpr std::uint32_t kOffset = 35;
    constexpr std::uint32_t kUniform = 2;
    SpirvWords module{0x0723'0203U, 0x0001'0300U, 0U, 13U, 0U};
    spirv_op(module, 17, {1});
    spirv_op(module, 14, {0, 1});
    spirv_named(module, 15, {0, 2}, "main");
    spirv_named(module, kName, {8}, "_Array_default_matrix<float,3,4>4");
    spirv_named(module, kMemberName, {8, 0}, "data");
    spirv_named(module, kName, {10}, "GlobalParams_default");
    spirv_named(module, kMemberName, {10, 0}, "bones");
    spirv_named(module, kMemberName, {10, 1}, "viewProj");
    spirv_named(module, kName, {12}, "globalParams");
    spirv_op(module, kDecorate, {7, kArrayStride, 64});
    spirv_op(module, kMemberDecorate, {8, 0, kOffset, 0});
    spirv_op(module, kMemberDecorate, {8, 0, kRowMajor});
    spirv_op(module, kMemberDecorate, {8, 0, kMatrixStride, 16});
    spirv_op(module, kDecorate, {10, kBlock});
    spirv_op(module, kMemberDecorate, {10, 0, kOffset, 0});
    spirv_op(module, kMemberDecorate, {10, 1, kOffset, 256});
    spirv_op(module, kMemberDecorate, {10, 1, kRowMajor});
    spirv_op(module, kMemberDecorate, {10, 1, kMatrixStride, 16});
    spirv_op(module, kDecorate, {12, kBinding, 0});
    spirv_op(module, kDecorate, {12, kDescriptorSet, 0});
    spirv_op(module, 22, {1, 32});
    spirv_op(module, 23, {3, 1, 4});
    spirv_op(module, 24, {4, 3, 3});
    spirv_op(module, 21, {5, 32, 1});
    spirv_op(module, 43, {5, 6, 4});
    spirv_op(module, 28, {7, 4, 6});
    spirv_op(module, 30, {8, 7});
    spirv_op(module, 24, {9, 3, 4});
    spirv_op(module, 30, {10, 8, 9});
    spirv_op(module, 32, {11, kUniform, 10});
    spirv_op(module, 59, {11, 12, kUniform});
    Buffer bytes(module.size() * sizeof(std::uint32_t));
    std::memcpy(bytes.data(), module.data(), bytes.size());
    return bytes;
}

[[nodiscard]] Variable matrix_variable(std::string_view name, std::uint32_t offset, std::uint32_t size,
    std::uint8_t rows, std::uint32_t elements) {
    return Variable{.name = std::string(name), .offset = offset, .size = size, .scalar = Scalar::kFloat,
        .bits = 32, .rows = rows, .columns = 4, .elements = elements};
}

// Hồi quy: phản chiếu từng lấy bố cục ma trận ở thành viên chứa mảng (không có MatrixStride) nên
// báo bones 240 byte (64*3 + 48) trong khi DXIL báo 252 (64*3 + 60, phần tử cuối 4 cột float3),
// và 56 shader chuyển từ client gốc hỏng ở bước đối chiếu.
void spirv_reads_matrix_layout_from_array_wrappers(Context& context) {
    const Buffer code = wrapped_matrix_module();
    const core::Result<StageReflection> reflection = shader::reflect_spirv(code, Stage::kVertex, "main");
    context.expect(reflection.has_value(), "module đọc được");
    if (!reflection) return;
    const bool one_block = reflection->blocks.size() == 1;
    context.expect(one_block, "một cbuffer");
    if (!one_block) return;
    const Block& block = reflection->blocks.front();
    context.expect(block.size == 320, std::format("cỡ khối {}", block.size));
    const std::vector<Variable> expected{
        matrix_variable("bones", 0, 252, 3, 4),
        matrix_variable("viewProj", 256, 64, 4, 0),
    };
    const bool two = block.variables.size() == 2;
    const std::uint32_t bones = two ? block.variables.front().size : 0;
    context.expect(block.variables == expected, std::format("bones 252 byte, đọc được {}", bones));
}

// Hai dạng ma trận của ParamNamedAuto.inc client gốc trong module theo cột: mảng float3x4 (Slang
// bọc mảng ở SPIR-V) và row_major float4x4 khai riêng (Slang hạ về struct _MatrixStorage_ ở DXIL).
constexpr std::string_view kMatrixSource = "uniform float3x4 bones[4];\n"
                                           "uniform row_major float4x4 shadow;\n"
                                           "float4 main(float4 p : POSITION, uint i : BLENDINDICES)"
                                           " : SV_Position {\n"
                                           "    float4 w = float4(mul(bones[i], p), 1);\n"
                                           "    return w * shadow[i % 4];\n"
                                           "}\n";

[[nodiscard]] const Variable* variable_named(const Block& block, std::string_view name) {
    const auto found = std::ranges::find(block.variables, name, &Variable::name);
    if (found == block.variables.end()) return nullptr;
    return &*found;
}

// Hồi quy: hai bên phản chiếu từng lệch nhau ở cả hai dạng nên 56 shader chuyển từ client gốc hỏng ở
// bước đối chiếu SPIR-V với DXIL. Dịch thật bằng Slang và DXC.
void compile_reconciles_wrapped_matrices(Context& context) {
    const core::Result<shader::Compiler> compiler = shader::Compiler::create();
    context.expect(compiler.has_value(), "nạp được Slang và DXC");
    if (!compiler) return;
    shader::CompileOptions options;
    options.stage = Stage::kVertex;
    options.target = Target::kSpirV;
    const shader::MemorySource source{.path = "matrix.vs.slang", .text = kMatrixSource};
    const core::Result<shader::Compiled> compiled = compiler->compile(source, options);
    const std::string why = compiled ? std::string() : std::string(compiled.error().detail());
    context.expect(compiled.has_value(), std::format("dịch và đối chiếu được: {}", why));
    if (!compiled) return;
    const std::vector<Block>& blocks = compiled->reflection.blocks;
    context.expect(blocks.size() == 1, "một cbuffer");
    if (blocks.size() != 1) return;
    const Variable* bones = variable_named(blocks.front(), "bones");
    const Variable* shadow = variable_named(blocks.front(), "shadow");
    const Variable bones_expected = matrix_variable("bones", 0, 252, 3, 4);
    const Variable shadow_expected = matrix_variable("shadow", 256, 64, 4, 0);
    context.expect(bones != nullptr && *bones == bones_expected, "bones: 4 phần tử float3x4, 252 byte");
    context.expect(shadow != nullptr && *shadow == shadow_expected, "shadow: float4x4, 64 byte");
}

// Lệnh locations và khoá matrix= của danh sách shader.
void manifest_reads_locations_and_matrix_layout(Context& context) {
    constexpr std::string_view kText = "locations semantic\n"
                                       "shader a.vs a.slang matrix=row\n"
                                       "shader b.ps b.slang matrix=column\n";
    const core::Result<shader::Manifest> parsed = shader::Manifest::parse(kText, "C:/shaders");
    context.expect(parsed.has_value(), "danh sách hợp lệ đọc được");
    if (!parsed) return;
    context.expect(parsed->locations == shader::Locations::kSemantic, "locations semantic");
    const bool two = parsed->shaders.size() == 2;
    context.expect(two && parsed->shaders.front().row_major, "matrix=row");
    context.expect(two && !parsed->shaders.back().row_major, "matrix=column");
    const core::Result<shader::Manifest> plain = shader::Manifest::parse("shader a.vs a.slang\n", "C:/shaders");
    const bool declared = plain.has_value() && plain->locations == shader::Locations::kDeclared;
    context.expect(declared && !plain->shaders.front().row_major, "mặc định declared, ma trận theo cột");
    const core::Result<shader::Manifest> odd_locations = shader::Manifest::parse("locations random\n", "C:/shaders");
    context.expect(failed_with(odd_locations, core::ErrorCode::kInvalidArgument), "locations lạ là lỗi");
    const core::Result<shader::Manifest> odd_matrix =
        shader::Manifest::parse("shader a.vs a.slang matrix=diagonal\n", "C:/shaders");
    context.expect(failed_with(odd_matrix, core::ErrorCode::kInvalidArgument), "matrix lạ là lỗi");
}

void watch_roots_uses_directory_boundaries(Context& context) {
    shader::Manifest manifest;
    manifest.directory = "C:/shaders";
    manifest.include_dirs = {"C:/shaders/lib", "C:/shaders_extra", "C:/shaders/lib/deep", "C:/other", "C:/other"};
    const std::vector<std::string> wanted{"C:/other", "C:/shaders", "C:/shaders_extra"};
    context.expect(shader::detail::watch_roots(manifest) == wanted, "anh em không bị nuốt, con thì gộp, trùng thì một");

    shader::Manifest parent;
    parent.directory = "C:/proj/src";
    parent.include_dirs = {"C:/proj/src/a", "C:/proj"};
    const std::vector<std::string> covered{"C:/proj"};
    context.expect(shader::detail::watch_roots(parent) == covered, "cha phủ con dù khai sau");

    shader::Manifest bare;
    bare.directory = "";
    bare.include_dirs = {"lib"};
    const std::vector<std::string> both = shader::detail::watch_roots(bare);
    const bool bare_ok = both.size() == 2 && both[0].empty() && both[1] == "lib";
    context.expect(bare_ok, "thư mục rỗng không phủ mọi include");

    shader::Manifest slash;
    slash.directory = "C:/shaders/";
    slash.include_dirs = {"C:/shaders", "C:/shaders/lib"};
    const std::vector<std::string> same{"C:/shaders"};
    context.expect(shader::detail::watch_roots(slash) == same, "dấu / cuối vẫn là cùng thư mục");

    shader::Manifest hyphen;
    hyphen.directory = "C:/a";
    hyphen.include_dirs = {"C:/a-extra", "C:/a/child"};
    const std::vector<std::string> split{"C:/a", "C:/a-extra"};
    context.expect(shader::detail::watch_roots(hyphen) == split, "anh em có '-' không che mất thư mục con");
}

constexpr std::array kCases{
    Case{.name = "package_reads_back_header_fields", .body = &package_reads_back_header_fields},
    Case{.name = "package_reads_back_every_variant", .body = &package_reads_back_every_variant},
    Case{.name = "package_file_follows_the_byte_layout", .body = &package_file_follows_the_byte_layout},
    Case{.name = "write_rejects_empty_and_repeated_variants", .body = &write_rejects_empty_and_repeated_variants},
    Case{.name = "variant_keys_ignore_order_and_repeats", .body = &variant_keys_ignore_order_and_repeats},
    Case{.name = "parse_rejects_truncated_files", .body = &parse_rejects_truncated_files},
    Case{.name = "parse_rejects_every_flipped_byte", .body = &parse_rejects_every_flipped_byte},
    Case{.name = "parse_survives_flips_with_a_fresh_checksum", .body = &parse_survives_flips_with_a_fresh_checksum},
    Case{.name = "parse_rejects_bad_fields", .body = &parse_rejects_bad_fields},
    Case{.name = "parse_rejects_misplaced_code_and_repeated_keys",
        .body = &parse_rejects_misplaced_code_and_repeated_keys},
    Case{.name = "load_reads_a_file_and_reports_a_missing_one", .body = &load_reads_a_file_and_reports_a_missing_one},
    Case{.name = "reflection_round_trips", .body = &reflection_round_trips},
    Case{.name = "reflection_rejects_truncated_and_bent_bytes", .body = &reflection_rejects_truncated_and_bent_bytes},
    Case{.name = "merge_unions_stages", .body = &merge_unions_stages},
    Case{.name = "merge_reports_conflicts", .body = &merge_reports_conflicts},
    Case{.name = "interface_matches_outputs_to_inputs", .body = &interface_matches_outputs_to_inputs},
    Case{.name = "reconcile_takes_names_from_spirv_and_semantics_from_dxil",
        .body = &reconcile_takes_names_from_spirv_and_semantics_from_dxil},
    Case{.name = "reconcile_reports_every_kind_of_layout_drift", .body = &reconcile_reports_every_kind_of_layout_drift},
    Case{.name = "stages_targets_and_models_parse", .body = &stages_targets_and_models_parse},
    Case{.name = "checksum_is_stable_xxh3", .body = &checksum_is_stable_xxh3},
    Case{.name = "codec_round_trips_lz4_and_zstd", .body = &codec_round_trips_lz4_and_zstd},
    Case{.name = "find_sees_matches_across_chunk_borders", .body = &find_sees_matches_across_chunk_borders},
    Case{.name = "rfind_sees_matches_across_chunk_borders", .body = &rfind_sees_matches_across_chunk_borders},
    Case{.name = "find_restores_position_after_a_read_error", .body = &find_restores_position_after_a_read_error},
    Case{.name = "read_helpers_loop_until_full_or_end", .body = &read_helpers_loop_until_full_or_end},
    Case{.name = "buny_table_finds_every_name", .body = &buny_table_finds_every_name},
    Case{.name = "buny_hash_and_names_follow_the_original", .body = &buny_hash_and_names_follow_the_original},
    Case{.name = "watch_roots_uses_directory_boundaries", .body = &watch_roots_uses_directory_boundaries},
    Case{.name = "semantic_location_follows_the_origin_tables",
        .body = &semantic_location_follows_the_origin_tables},
    Case{.name = "reconcile_by_semantic_drops_unused_dxil_inputs",
        .body = &reconcile_by_semantic_drops_unused_dxil_inputs},
    Case{.name = "manifest_reads_locations_and_matrix_layout",
        .body = &manifest_reads_locations_and_matrix_layout},
    Case{.name = "spirv_reads_matrix_layout_from_array_wrappers",
        .body = &spirv_reads_matrix_layout_from_array_wrappers},
    Case{.name = "compile_reconciles_wrapped_matrices", .body = &compile_reconciles_wrapped_matrices},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "shader_tests: mọi ca phải qua");
    return 0;
}
