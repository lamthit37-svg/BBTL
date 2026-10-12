// Đọc và ghi gói shader F2SH: magic little-endian, header 64 byte, phiên bản 1.
// Checksum phủ cả tệp trừ chính trường ấy, nên byte lật ở tên hoặc cờ cũng lộ.
// Nguồn: Forge2 src/shader/package.cpp@d7fcd76. Khác gốc: Package::load đọc tệp bằng io::read_text
// của THIENLONG thay fs::read_file của Forge2 (fs/file không được chép); thân vòng lặp của
// read_variants và read_dependencies tách thành hàm, câu if trong vòng của variant_text thành phép
// chọn, hai phép kiểm đầu vào của write_package tách thành check_source (ghi tại chỗ); tham số và
// biến tên at thành start.
#include "shader/package.hpp"

#include "core/error.hpp"
#include "fs/codec.hpp"
#include "fs/stream.hpp"
#include "io/file.hpp"
#include "shader/failure.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"
#include "shader/wire.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::shader {

namespace {

using FileView = std::span<const std::byte>;

// "F2SH" đọc như một số little-endian.
constexpr std::uint32_t kMagic = 0x48533246U;
constexpr std::uint32_t kVersion = 1;
constexpr std::size_t kHeaderSize = 64;
constexpr std::size_t kVariantSize = 48;
constexpr std::size_t kDependencySize = 16;
constexpr std::size_t kCodeAlign = 8;
constexpr std::uint8_t kDebugBit = 1;

struct Range {
    std::uint32_t offset = 0;
    std::uint32_t size = 0;
};

struct Header {
    std::uint32_t magic = 0;
    std::uint32_t version = 0;
    std::uint32_t file_size = 0;
    std::uint32_t variant_count = 0;
    std::uint32_t variants_offset = 0;
    std::uint32_t dependency_count = 0;
    std::uint32_t dependencies_offset = 0;
    Range name{};
    std::uint8_t stage = 0;
    std::uint8_t flags = 0;
    std::uint64_t options_hash = 0;
    // XXH3-64 của cả tệp trừ chính trường này.
    std::uint64_t checksum = 0;
};

// Vị trí của trường checksum trong header.
constexpr std::size_t kChecksumAt = 48;

// Tổng kiểm phủ cả header: một byte lật ở tên, cờ hay options_hash cũng phải bị phát hiện, không
// chỉ ở phần thân.
[[nodiscard]] std::uint64_t checksum_of(std::span<const std::byte> file) {
    fs::Checksum sum;
    sum.update(file.first(kChecksumAt));
    sum.update(file.subspan(kChecksumAt + sizeof(std::uint64_t)));
    return sum.digest();
}

[[nodiscard]] Range read_range(Reader& reader) noexcept {
    Range range;
    range.offset = reader.get<std::uint32_t>();
    range.size = reader.get<std::uint32_t>();
    return range;
}

[[nodiscard]] Header read_header(Reader& reader) noexcept {
    Header header;
    header.magic = reader.get<std::uint32_t>();
    header.version = reader.get<std::uint32_t>();
    header.file_size = reader.get<std::uint32_t>();
    header.variant_count = reader.get<std::uint32_t>();
    header.variants_offset = reader.get<std::uint32_t>();
    header.dependency_count = reader.get<std::uint32_t>();
    header.dependencies_offset = reader.get<std::uint32_t>();
    header.name = read_range(reader);
    header.stage = reader.get<std::uint8_t>();
    header.flags = reader.get<std::uint8_t>();
    reader.skip(sizeof(std::uint16_t));
    header.options_hash = reader.get<std::uint64_t>();
    header.checksum = reader.get<std::uint64_t>();
    return header;
}

void write_range(Writer& out, Range range) {
    out.put(range.offset);
    out.put(range.size);
}

// Vùng range của tệp; nullopt khi nó chạm header hoặc vượt cuối tệp.
[[nodiscard]] std::optional<std::span<const std::byte>> view(std::span<const std::byte> file, Range range) noexcept {
    const bool starts = range.offset >= kHeaderSize && range.offset <= file.size();
    if (!starts || range.size > file.size() - range.offset) return std::nullopt;
    return file.subspan(range.offset, range.size);
}

// Bảng count bản ghi, mỗi bản ghi record byte, bắt đầu ở offset.
[[nodiscard]] std::optional<std::span<const std::byte>> table(std::span<const std::byte> file, std::uint32_t offset,
    std::uint32_t count, std::size_t record) {
    if (count > file.size() / record) return std::nullopt;
    return view(file, {.offset = offset, .size = static_cast<std::uint32_t>(count * record)});
}

[[nodiscard]] std::string text_of(std::span<const std::byte> raw) {
    std::string text(raw.size(), '\0');
    if (!raw.empty()) std::memcpy(text.data(), raw.data(), raw.size());
    return text;
}

[[nodiscard]] bool has_variant(std::span<const Variant> variants, const Variant& wanted) noexcept {
    const auto same = [&](const Variant& other) { return other.target == wanted.target && other.key == wanted.key; };
    return std::ranges::any_of(variants, same);
}

[[nodiscard]] Result<Variant> read_variant(std::span<const std::byte> file, Reader& reader) {
    const auto target = reader.get<std::uint8_t>();
    reader.skip(3);
    const Range defines = read_range(reader);
    reader.skip(sizeof(std::uint32_t));
    Variant variant;
    variant.key = reader.get<std::uint64_t>();
    variant.code_hash = reader.get<std::uint64_t>();
    const Range code = read_range(reader);
    const Range reflection = read_range(reader);
    if (reader.failed() || target >= kTargetCount) return corrupt("gói shader sai đích dịch");
    const auto text = view(file, defines);
    const auto code_bytes = view(file, code);
    const auto reflection_bytes = view(file, reflection);
    const bool inside = text && code_bytes && reflection_bytes;
    const bool placed = inside && code.offset % kCodeAlign == 0;
    if (!placed) return corrupt("gói shader có bản dịch sai vị trí");
    Result<StageReflection> decoded = decode(*reflection_bytes);
    if (!decoded) return pass(decoded);
    variant.target = static_cast<Target>(target);
    variant.defines = text_of(*text);
    variant.code = *code_bytes;
    variant.reflection = std::move(*decoded);
    variant.reflection_hash = fs::checksum(*reflection_bytes);
    return variant;
}

// Khác gốc: thân vòng lặp của read_variants tách ra đây; vòng lặp dừng ở lỗi đầu tiên như gốc.
[[nodiscard]] Status add_variant(FileView file, Reader& reader, std::vector<Variant>& variants) {
    Result<Variant> variant = read_variant(file, reader);
    if (!variant) return pass(variant);
    const bool repeated = has_variant(variants, *variant);
    if (repeated) return corrupt("gói shader có hai bản dịch trùng khoá");
    variants.push_back(std::move(*variant));
    return ok();
}

[[nodiscard]] Status read_variants(std::span<const std::byte> file, const Header& header,
    std::vector<Variant>& variants) {
    const auto records = table(file, header.variants_offset, header.variant_count, kVariantSize);
    if (!records) return corrupt("gói shader sai bảng bản dịch");
    Reader reader(*records);
    variants.reserve(header.variant_count);
    Status added = ok();
    for (std::uint32_t index = 0; added && index < header.variant_count; ++index) {
        added = add_variant(file, reader, variants);
    }
    return added;
}

// Khác gốc: thân vòng lặp của read_dependencies tách ra đây.
[[nodiscard]] Status add_dependency(FileView file, Reader& reader, std::vector<Dependency>& list) {
    const Range path = read_range(reader);
    const auto hash = reader.get<std::uint64_t>();
    const auto text = view(file, path);
    if (!text) return corrupt("gói shader có đường dẫn phụ thuộc sai vị trí");
    list.push_back({.path = text_of(*text), .hash = hash});
    return ok();
}

[[nodiscard]] Status read_dependencies(std::span<const std::byte> file, const Header& header,
    std::vector<Dependency>& dependencies) {
    const std::uint32_t count = header.dependency_count;
    const auto records = table(file, header.dependencies_offset, count, kDependencySize);
    if (!records) return corrupt("gói shader sai bảng phụ thuộc");
    Reader reader(*records);
    dependencies.reserve(count);
    Status added = ok();
    for (std::uint32_t index = 0; added && index < count; ++index) {
        added = add_dependency(file, reader, dependencies);
    }
    return added;
}

// Thêm data vào cuối out và trả vị trí của nó.
[[nodiscard]] Range put_blob(Writer& out, std::span<const std::byte> data) {
    const Range range{
        .offset = static_cast<std::uint32_t>(out.size()), .size = static_cast<std::uint32_t>(data.size())};
    out.put_bytes(data);
    return range;
}

[[nodiscard]] Range put_text(Writer& out, std::string_view text) {
    return put_blob(out, std::as_bytes(std::span(text)));
}

// Ghi các khối của một bản dịch vào cuối out rồi điền bản ghi 48 byte của nó ở offset start.
void write_variant(Writer& out, std::size_t start, const PackageVariant& variant) {
    const Range defines = put_text(out, variant_text(variant.defines));
    const Range reflection = put_blob(out, encode(variant.reflection));
    out.align(kCodeAlign);
    const Range code = put_blob(out, variant.code);
    Writer record;
    record.put(std::to_underlying(variant.target));
    record.fill(3);
    write_range(record, defines);
    record.fill(sizeof(std::uint32_t));
    record.put(variant_key(variant.defines));
    record.put(fs::checksum(variant.code));
    write_range(record, code);
    write_range(record, reflection);
    out.overwrite(start, record.bytes());
}

void write_dependency(Writer& out, std::size_t start, const Dependency& dependency) {
    const Range path = put_text(out, dependency.path);
    Writer record;
    write_range(record, path);
    record.put(dependency.hash);
    out.overwrite(start, record.bytes());
}

// Khác gốc: không có ở gốc. Mã lỗi của core ứng với lỗi đọc tệp của io::read_text.
[[nodiscard]] ErrorCode code_of(io::FileError error) noexcept {
    switch (error) {
    case io::FileError::kNotFound: return ErrorCode::kNotFound;
    case io::FileError::kUnreadable: return ErrorCode::kIo;
    case io::FileError::kTooLarge: return ErrorCode::kOutOfRange;
    }
    return ErrorCode::kUnknown;
}

[[nodiscard]] core::Failure read_failure(io::FileError error, std::string_view path) noexcept {
    return fail(code_of(error), "không đọc được gói shader", "{}: {}", path, io::describe(error));
}

[[nodiscard]] bool has_duplicates(std::span<const PackageVariant> variants) {
    std::vector<std::pair<Target, std::uint64_t>> keys;
    keys.reserve(variants.size());
    for (const PackageVariant& variant : variants) {
        keys.emplace_back(variant.target, variant_key(variant.defines));
    }
    std::ranges::sort(keys);
    return std::ranges::adjacent_find(keys) != keys.end();
}

// Khác gốc: hai phép kiểm đầu vào của write_package tách ra đây để hàm ấy không quá 40 dòng.
[[nodiscard]] Status check_source(const PackageSource& source) {
    if (source.variants.empty()) {
        return fail(ErrorCode::kInvalidArgument, "gói shader cần ít nhất một bản dịch", source.name);
    }
    if (has_duplicates(source.variants)) {
        return fail(ErrorCode::kInvalidArgument, "hai bản dịch trùng đích và tập define", source.name);
    }
    return ok();
}

} // namespace

std::string variant_text(std::span<const std::string> defines) {
    std::vector<std::string_view> sorted(defines.begin(), defines.end());
    std::ranges::sort(sorted);
    const auto repeated = std::ranges::unique(sorted);
    sorted.erase(repeated.begin(), repeated.end());
    std::string text;
    for (const std::string_view define : sorted) {
        // Khác gốc: gốc viết if (!text.empty()) text += ';' trong thân vòng lặp.
        text += text.empty() ? "" : ";";
        text += define;
    }
    return text;
}

std::uint64_t variant_key(std::span<const std::string> defines) {
    const std::string text = variant_text(defines);
    if (text.empty()) return kDefaultVariant;
    return fs::checksum(std::as_bytes(std::span(text)));
}

Result<Package> Package::parse(fs::Bytes bytes) {
    Package package;
    package.bytes_ = std::move(bytes);
    const std::span<const std::byte> file = std::as_const(package.bytes_).span();
    if (file.size() < kHeaderSize) return corrupt("gói shader cụt");
    Reader reader(file.first(kHeaderSize));
    const Header header = read_header(reader);
    const bool known = header.magic == kMagic && header.version == kVersion;
    if (!known) return corrupt("gói shader sai magic hoặc phiên bản");
    if (header.file_size != file.size()) return corrupt("gói shader sai cỡ");
    if (checksum_of(file) != header.checksum) return corrupt("gói shader sai tổng kiểm");
    if (header.stage >= kStageCount) return corrupt("gói shader sai stage");
    const auto name = view(file, header.name);
    if (!name) return corrupt("gói shader có tên sai vị trí");
    package.name_ = text_of(*name);
    package.stage_ = static_cast<Stage>(header.stage);
    package.debug_ = (header.flags & kDebugBit) != 0;
    package.options_hash_ = header.options_hash;
    if (Status read = read_variants(file, header, package.variants_); !read) return pass(read);
    Status read = read_dependencies(file, header, package.dependencies_);
    if (!read) return pass(read);
    return package;
}

// Khác gốc: gốc gọi fs::read_file của Forge2 (CreateFileW, đọc thẳng vào fs::Bytes). THIENLONG đã
// có io::read_text nên đọc qua nó rồi chép sang fs::Bytes: thêm một lần chép, tệp bị chặn ở trần
// cỡ của io, và lỗi của io đổi sang core::Error.
Result<Package> Package::load(std::string_view path) {
    const io::TextResult text = io::read_text(io::path_from_utf8(path));
    if (!text) return read_failure(text.error(), path);
    fs::Bytes bytes(text->size());
    std::ranges::copy(std::as_bytes(std::span(*text)), bytes.span().begin());
    return parse(std::move(bytes));
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): thư mục rồi tên, như fs::join của gốc (lệch
// API-03).
std::string package_path(std::string_view output, std::string_view name) {
    const std::filesystem::path folder(output);
    const std::string file = std::format("{}.{}", name, kPackageExtension);
    return (folder / file).string();
}

const Variant* Package::find(Target target, std::uint64_t key) const noexcept {
    const auto wanted = [&](const Variant& variant) { return variant.target == target && variant.key == key; };
    const auto found = std::ranges::find_if(variants_, wanted);
    return found == variants_.end() ? nullptr : &*found;
}

Result<std::vector<std::byte>> write_package(const PackageSource& source) {
    if (Status checked = check_source(source); !checked) return pass(checked);
    Writer out;
    out.fill(kHeaderSize);
    const std::size_t variants_at = out.size();
    out.fill(source.variants.size() * kVariantSize);
    const std::size_t dependencies_at = out.size();
    out.fill(source.dependencies.size() * kDependencySize);
    const Range name = put_text(out, source.name);
    for (std::size_t index = 0; index < source.variants.size(); ++index) {
        write_variant(out, variants_at + (index * kVariantSize), source.variants.at(index));
    }
    for (std::size_t index = 0; index < source.dependencies.size(); ++index) {
        const std::size_t start = dependencies_at + (index * kDependencySize);
        write_dependency(out, start, source.dependencies.at(index));
    }
    if (out.size() > std::numeric_limits<std::uint32_t>::max()) {
        return fail(ErrorCode::kOverflow, "gói shader vượt 4 GiB", source.name);
    }
    Writer header;
    header.put(kMagic);
    header.put(kVersion);
    header.put(static_cast<std::uint32_t>(out.size()));
    header.put(static_cast<std::uint32_t>(source.variants.size()));
    header.put(static_cast<std::uint32_t>(variants_at));
    header.put(static_cast<std::uint32_t>(source.dependencies.size()));
    header.put(static_cast<std::uint32_t>(dependencies_at));
    write_range(header, name);
    header.put(std::to_underlying(source.stage));
    header.put(source.debug ? kDebugBit : std::uint8_t{0});
    header.fill(sizeof(std::uint16_t));
    header.put(source.options_hash);
    header.fill(kHeaderSize - header.size());
    out.overwrite(0, header.bytes());
    Writer checksum;
    checksum.put(checksum_of(out.bytes()));
    out.overwrite(kChecksumAt, checksum.bytes());
    return out.take();
}

} // namespace game::shader
