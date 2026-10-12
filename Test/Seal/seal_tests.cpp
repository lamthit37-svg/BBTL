// Gói .tlpak: byte mở ra trùng byte đưa vào, sai khoá và sai dấu bị từ chối, cây thư mục đi một
// vòng.
#include "core/check.hpp"
#include "io/file.hpp"
#include "seal/package.hpp"
#include "seal/tree.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <ios>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::test {
namespace {

namespace seal = game::seal;

constexpr std::string_view kFirstName = "âm/một.bin";
constexpr std::string_view kSecondName = "CongRen_Login.mp3";
constexpr std::string_view kMagic = "TLBBPAK1";

struct Packed {
    seal::Key key;
    seal::Blob package;
    bool ready = false;
};

struct Scratch {
    std::filesystem::path path;

    explicit Scratch(std::filesystem::path folder) : path(std::move(folder)) {
        std::error_code error;
        std::filesystem::remove_all(path, error);
    }
    Scratch(const Scratch&) = delete;
    Scratch& operator=(const Scratch&) = delete;
    Scratch(Scratch&&) = delete;
    Scratch& operator=(Scratch&&) = delete;
    // NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
    ~Scratch() {
        std::error_code error;
        std::filesystem::remove_all(path, error);
    }
};

template <class Result>
[[nodiscard]] bool failed_with(const Result& result, seal::Error error) {
    return !result.has_value() && result.error() == error;
}

[[nodiscard]] bool blob_is(seal::Bytes bytes, std::string_view text) {
    if (bytes.size() != text.size()) return false;
    bool same = true;
    for (std::size_t index = 0; index < text.size(); ++index) {
        const auto unit = static_cast<unsigned char>(text[index]);
        same = same && bytes[index] == static_cast<std::byte>(unit);
    }
    return same;
}

[[nodiscard]] bool starts_with_magic(seal::Bytes package) {
    if (package.size() < kMagic.size()) return false;
    return blob_is(package.first(kMagic.size()), kMagic);
}

void fill_pair(std::array<seal::Item, 2>& items) {
    items[0].name = std::string(kFirstName);
    items[0].bytes.assign(32, std::byte{0x11});
    items[0].bytes[0] = std::byte{0};
    items[1].name = std::string(kSecondName);
    items[1].bytes.assign(32, std::byte{0x22});
}

[[nodiscard]] Packed pack_pair() {
    Packed packed;
    auto key = seal::random_key();
    if (!key) return packed;
    std::array<seal::Item, 2> items;
    fill_pair(items);
    auto package = seal::seal(*key, items);
    if (!package) return packed;
    packed.key = std::move(*key);
    packed.package = std::move(*package);
    packed.ready = true;
    return packed;
}

void flip_at(seal::Blob& package, std::size_t offset) {
    if (offset >= package.size()) return;
    const auto unit = static_cast<unsigned>(package[offset]);
    package[offset] = static_cast<std::byte>(unit ^ 1U);
}

// NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast)
[[nodiscard]] bool plant_file(const std::filesystem::path& path, seal::Bytes bytes) {
    std::error_code error;
    std::filesystem::create_directories(path.parent_path(), error);
    if (error) return false;
    std::ofstream file(path, std::ios::binary | std::ios::trunc);
    if (!file.is_open()) return false;
    if (bytes.empty()) return true;
    const auto* raw = reinterpret_cast<const char*>(bytes.data());
    file.write(raw, static_cast<std::streamsize>(bytes.size()));
    return static_cast<bool>(file);
}

[[nodiscard]] bool file_is(const std::filesystem::path& path, seal::Bytes bytes) {
    std::error_code error;
    const auto size = std::filesystem::file_size(path, error);
    if (error || size != bytes.size()) return false;
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) return false;
    std::vector<std::byte> body(bytes.size());
    if (body.empty()) return true;
    auto* raw = reinterpret_cast<char*>(body.data());
    file.read(raw, static_cast<std::streamsize>(body.size()));
    const auto got = file.gcount();
    const bool whole = std::cmp_equal(got, body.size());
    return whole && std::ranges::equal(body, bytes);
}
// NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast)

void roundtrip_keeps_bytes(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    const auto opened = seal::open_all(packed.key, packed.package);
    context.expect(opened.has_value(), "mở lại được cả gói");
    if (!opened) return;
    context.expect(opened->size() == 2, "bảng kê không nằm trong danh sách người dùng");
    context.expect(opened->at(0).name == kFirstName, "tên có dấu giữ nguyên");
    context.expect(opened->at(0).bytes.size() == 32, "mục đầu đủ 32 byte");
    context.expect(opened->at(0).bytes[0] == std::byte{0}, "byte NUL trong nội dung còn nguyên");
    context.expect(opened->at(0).bytes[1] == std::byte{0x11}, "byte sau NUL còn nguyên");
    context.expect(opened->at(1).name == kSecondName, "hoa thường của tên không bị hạ");
    context.expect(opened->at(1).bytes.size() == 32, "mục sau đủ 32 byte");
    context.expect(opened->at(1).bytes[0] == std::byte{0x22}, "nội dung mục sau còn nguyên");
}

void manifest_lists_user_names(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    const auto body = seal::open_named(packed.key, packed.package, seal::kManifestName);
    context.expect(body.has_value(), "mở được bảng kê đã niêm");
    if (!body) return;
    const std::string text = std::string(kFirstName) + "\n" + std::string(kSecondName) + "\n";
    context.expect(blob_is(*body, text), "bảng kê là từng tên một dòng");
}

void wrong_key_is_rejected(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    auto other = seal::random_key();
    context.expect(other.has_value(), "có khoá thứ hai");
    if (!other) return;
    const auto opened = seal::open_all(*other, packed.package);
    context.expect(failed_with(opened, seal::Error::kWrongKey), "sai khoá");
    context.expect(seal::describe(seal::Error::kWrongKey) == "sai khoá", "lời báo sai khoá");
}

void flipped_ciphertext_stops_that_item(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    context.expect(packed.package.size() > 100, "byte 100 nằm trong mục đầu");
    seal::Blob broken = packed.package;
    flip_at(broken, 100);
    const auto first = seal::open_named(packed.key, broken, kFirstName);
    context.expect(failed_with(first, seal::Error::kCorrupt), "mục bị sửa dấu là hỏng");
    const auto verified = seal::verify_bytes(packed.key, broken);
    context.expect(failed_with(verified, seal::Error::kCorrupt), "xác thực cả gói thấy mục hỏng");
    const auto second = seal::open_named(packed.key, broken, kSecondName);
    context.expect(second.has_value(), "mục kia vẫn mở được");
    if (!second) return;
    context.expect(second->size() == 32 && second->front() == std::byte{0x22}, "nội dung mục kia");
}

void flipped_key_check_is_wrong_key(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    seal::Blob broken = packed.package;
    flip_at(broken, 32);
    const auto opened = seal::open_all(packed.key, broken);
    context.expect(failed_with(opened, seal::Error::kWrongKey), "sai khối kiểm khoá");
}

void bad_magic_is_rejected(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    seal::Blob broken = packed.package;
    flip_at(broken, 0);
    const auto opened = seal::open_all(packed.key, broken);
    context.expect(failed_with(opened, seal::Error::kBadMagic), "sai phép thuật");
}

void bad_version_and_flags(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    seal::Blob version = packed.package;
    flip_at(version, 8);
    const auto old = seal::open_all(packed.key, version);
    context.expect(failed_with(old, seal::Error::kBadVersion), "sai số bản");
    seal::Blob flags = packed.package;
    flip_at(flags, 10);
    const auto marked = seal::open_all(packed.key, flags);
    context.expect(failed_with(marked, seal::Error::kBadVersion), "cờ khác 0");
}

void dirty_reserved_is_corrupt(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    seal::Blob broken = packed.package;
    flip_at(broken, 48);
    const auto opened = seal::open_all(packed.key, broken);
    context.expect(failed_with(opened, seal::Error::kCorrupt), "vùng dành riêng phải là 0");
}

void truncated_package_is_corrupt(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    seal::Blob short_head = packed.package;
    short_head.resize(60);
    const auto head = seal::open_all(packed.key, short_head);
    context.expect(failed_with(head, seal::Error::kCorrupt), "cụt đầu gói");
    seal::Blob short_tail = packed.package;
    short_tail.pop_back();
    const auto tail = seal::open_all(packed.key, short_tail);
    context.expect(failed_with(tail, seal::Error::kCorrupt), "cụt một byte cuối");
}

void missing_name_is_reported(Context& context) {
    const Packed packed = pack_pair();
    context.expect(packed.ready, "niêm được hai mục");
    if (!packed.ready) return;
    const auto opened = seal::open_named(packed.key, packed.package, "không-có.bin");
    context.expect(failed_with(opened, seal::Error::kMissing), "không có mục");
}

void rejected_names(Context& context) {
    auto key = seal::random_key();
    context.expect(key.has_value(), "có khoá");
    if (!key) return;
    const std::array<std::string_view, 6> names{"..", seal::kManifestName, "a/../b", "", "/a", "a\\b"};
    bool rejected = true;
    for (const std::string_view name : names) {
        seal::Item item;
        item.name = std::string(name);
        const std::span<const seal::Item> one(&item, 1);
        const auto sealed = seal::seal(*key, one);
        rejected = rejected && failed_with(sealed, seal::Error::kName);
    }
    context.expect(rejected, "tên cấm bị từ chối");
}

void duplicate_fold_is_rejected(Context& context) {
    auto key = seal::random_key();
    context.expect(key.has_value(), "có khoá");
    if (!key) return;
    std::array<seal::Item, 2> items;
    items[0].name = "A.wav";
    items[1].name = "a.wav";
    const auto sealed = seal::seal(*key, items);
    context.expect(failed_with(sealed, seal::Error::kDuplicate), "A.wav và a.wav là một tên");
}

void empty_package_has_no_user_items(Context& context) {
    auto key = seal::random_key();
    context.expect(key.has_value(), "có khoá");
    if (!key) return;
    const std::span<const seal::Item> none;
    const auto package = seal::seal(*key, none);
    context.expect(package.has_value(), "gói rỗng vẫn được niêm");
    if (!package) return;
    context.expect(starts_with_magic(*package), "đầu gói là TLBBPAK1");
    const auto opened = seal::open_all(*key, *package);
    context.expect(opened.has_value() && opened->empty(), "không có mục người dùng");
    const auto count = seal::verify_bytes(*key, *package);
    context.expect(count.has_value() && *count == 0, "xác thực đếm 0");
    const auto manifest = seal::open_named(*key, *package, seal::kManifestName);
    context.expect(manifest.has_value() && manifest->empty(), "bảng kê rỗng");
}

[[nodiscard]] bool plant_source(const std::filesystem::path& source) {
    const std::array<std::byte, 3> payload{std::byte{0}, std::byte{0xFF}, std::byte{0x10}};
    const auto nested = source / game::io::path_from_utf8("thử-âm/dữ.liệu");
    const std::array<std::byte, 1> tone{std::byte{0x7F}};
    const bool data = plant_file(nested, payload);
    const bool tone_file = plant_file(source / "CongRen_Login.mp3", tone);
    const bool empty = plant_file(source / game::io::path_from_utf8("trống.bin"), {});
    return data && tone_file && empty;
}

void directory_roundtrip(Context& context) {
    const Scratch scratch(std::filesystem::temp_directory_path() / "thienlong-seal-test");
    const auto source = scratch.path / "nguồn";
    const auto package = scratch.path / "gói.tlpak";
    const auto opened = scratch.path / "ra";
    context.expect(plant_source(source), "tạo cây có chữ và byte NUL");
    auto key = seal::random_key();
    context.expect(key.has_value(), "có khoá");
    if (!key) return;
    const auto key_path = scratch.path / "khoa.bin";
    const auto stored = seal::store_key(*key, key_path);
    context.expect(stored.has_value(), "ghi khoá 32 byte");
    const auto loaded = seal::load_key(key_path);
    context.expect(loaded.has_value(), "đọc lại khoá");
    if (!loaded) return;
    context.expect(std::ranges::equal(loaded->bytes, key->bytes), "khoá đọc ra trùng khoá ghi");
    const auto again = seal::store_key(*key, key_path);
    context.expect(failed_with(again, seal::Error::kIo), "không ghi đè khoá");
    const seal::TreePaths seal_paths{.from = &source, .into = &package};
    const auto saved = seal::seal_folder(*loaded, seal_paths);
    context.expect(saved.has_value() && saved->files == 3, "niêm ba tệp");
    const seal::TreePaths open_paths{.from = &package, .into = &opened};
    const auto extracted = seal::open_folder(*loaded, open_paths);
    context.expect(extracted.has_value() && extracted->files == 3, "mở ba tệp");
    const std::array<std::byte, 3> payload{std::byte{0}, std::byte{0xFF}, std::byte{0x10}};
    const auto data = opened / game::io::path_from_utf8("thử-âm/dữ.liệu");
    context.expect(file_is(data, payload), "byte NUL và tên có dấu đi đủ một vòng");
    const std::array<std::byte, 1> tone{std::byte{0x7F}};
    context.expect(file_is(opened / "CongRen_Login.mp3", tone), "hoa thường tên tệp còn nguyên");
    context.expect(file_is(opened / game::io::path_from_utf8("trống.bin"), {}), "tệp rỗng còn rỗng");
    const auto verified = seal::verify_folder(*loaded, package);
    context.expect(verified.has_value() && verified->files == 3, "xác thực đếm ba tệp");
    context.expect(verified.has_value() && verified->bytes == 4, "tổng byte thô là 4");
}

void refused_outputs(Context& context) {
    const Scratch scratch(std::filesystem::temp_directory_path() / "thienlong-seal-test");
    const auto source = scratch.path / "src";
    context.expect(plant_file(source / "a.bin", std::array<std::byte, 1>{std::byte{1}}), "có nguồn");
    auto key = seal::random_key();
    context.expect(key.has_value(), "có khoá");
    if (!key) return;
    const auto inside = source / "out.tlpak";
    const seal::TreePaths nested{.from = &source, .into = &inside};
    const auto self = seal::seal_folder(*key, nested);
    context.expect(failed_with(self, seal::Error::kIo), "không niêm gói nằm trong nguồn");
    std::error_code error;
    const bool partial = std::filesystem::exists(source / "out.tlpak.partial", error);
    context.expect(!error && !partial, "không để lại bản dở");
    const auto client = scratch.path / "thienlong" / "client" / "out.tlpak";
    const seal::TreePaths banned{.from = &source, .into = &client};
    const auto blocked = seal::seal_folder(*key, banned);
    context.expect(failed_with(blocked, seal::Error::kIo), "không ghi vào thư mục client");
    const auto marked = scratch.path / "thienlong" / "client" / "data";
    context.expect(plant_file(marked / "a.bin", std::array<std::byte, 1>{std::byte{2}}), "nguồn đánh dấu");
    const auto safe = scratch.path / "safe.tlpak";
    const seal::TreePaths allowed{.from = &marked, .into = &safe};
    const auto sealed = seal::seal_folder(*key, allowed);
    context.expect(sealed.has_value() && sealed->files == 1, "đọc nguồn trong tên client vẫn được");
}

constexpr std::array kCases{
    Case{.name = "roundtrip_keeps_bytes", .body = &roundtrip_keeps_bytes},
    Case{.name = "manifest_lists_user_names", .body = &manifest_lists_user_names},
    Case{.name = "wrong_key_is_rejected", .body = &wrong_key_is_rejected},
    Case{.name = "flipped_ciphertext_stops_that_item", .body = &flipped_ciphertext_stops_that_item},
    Case{.name = "flipped_key_check_is_wrong_key", .body = &flipped_key_check_is_wrong_key},
    Case{.name = "bad_magic_is_rejected", .body = &bad_magic_is_rejected},
    Case{.name = "bad_version_and_flags", .body = &bad_version_and_flags},
    Case{.name = "dirty_reserved_is_corrupt", .body = &dirty_reserved_is_corrupt},
    Case{.name = "truncated_package_is_corrupt", .body = &truncated_package_is_corrupt},
    Case{.name = "missing_name_is_reported", .body = &missing_name_is_reported},
    Case{.name = "rejected_names", .body = &rejected_names},
    Case{.name = "duplicate_fold_is_rejected", .body = &duplicate_fold_is_rejected},
    Case{.name = "empty_package_has_no_user_items", .body = &empty_package_has_no_user_items},
    Case{.name = "directory_roundtrip", .body = &directory_roundtrip},
    Case{.name = "refused_outputs", .body = &refused_outputs},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "seal_tests: mọi ca phải qua");
    return 0;
}
