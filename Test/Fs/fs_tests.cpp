// Test của fs: đường dẫn, tệp, thao tác trên đĩa, theo dõi thư mục. Mã được kiểm chép từ Forge2;
// các ca ở đây giữ hành vi gốc sau khi thân các vòng lặp của nó đổi hình dạng cho qua cổng. Bảng kỳ
// vọng của path là kết quả in ra từ src/fs/path.cpp nguyên văn của Forge2 @d7fcd76; các ca tệp, đĩa
// và watcher theo tests/fs/fs_test.cpp của Forge2. Mọi tệp ghi vào một thư mục tạm riêng nằm trong
// thư mục làm việc hiện tại, xoá cả cây khi xong. Ca watcher chờ có hạn trên biến điều kiện, không
// ngủ một khoảng cố định. Chỉ dựng trên Windows như phần .cpp của fs.
#include "core/check.hpp"
#include "core/error.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "fs/stream.hpp"
#include "fs/watcher.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <format>
#include <mutex>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

#include <processthreadsapi.h>

namespace game::test {
namespace {

using core::ErrorCode;
using core::view_bytes;
using core::view_text;

using Names = std::vector<std::string>;

// Hạn chờ một sự kiện của watcher; bình thường sự kiện tới trong vài mili giây.
constexpr std::chrono::seconds kPatience{10};

// Thư mục tạm của lần chạy, tương đối so với thư mục làm việc hiện tại.
[[nodiscard]] const std::string& tree_root() {
    static const std::string kRoot = std::format("fs_tests_tmp.{}", GetCurrentProcessId());
    return kRoot;
}

// Xoá cả cây thư mục tạm; chưa có thì không làm gì.
void remove_tree() {
    const std::filesystem::path native(core::widen(tree_root()));
    std::error_code ec;
    std::filesystem::remove_all(native, ec);
}

// Thư mục riêng của một ca bên trong thư mục tạm, đã tạo sẵn.
[[nodiscard]] std::string case_dir(Context& context, std::string_view name) {
    std::string dir = fs::join(tree_root(), name);
    context.expect(fs::create_directory(dir).has_value(), "tạo được thư mục của ca");
    return dir;
}

// Nội dung tệp dạng chuỗi; nullopt khi không đọc được.
[[nodiscard]] std::optional<std::string> text_in(std::string_view path) {
    const auto read = fs::read_file(path);
    if (!read) return std::nullopt;
    return std::string(view_text(read->span()));
}

// Mã lỗi của một kết quả hỏng; nullopt khi kết quả tốt.
template <class T>
[[nodiscard]] std::optional<ErrorCode> code_of(const core::Result<T>& result) {
    if (result) return std::nullopt;
    return result.error().code();
}

// Tên đã sắp theo byte; rỗng khi liệt kê hỏng.
[[nodiscard]] Names sorted(core::Result<Names> names) {
    if (!names) return {};
    std::ranges::sort(*names);
    return std::move(*names);
}

// Đường dẫn và dạng chuẩn của nó với '/' rồi với '\'.
struct NormalizeCase {
    std::string_view path;
    std::string_view forward;
    std::string_view backward;
    bool is_absolute = false;
};

constexpr std::array kNormalizeCases{
    NormalizeCase{.path = "a/./b//c/../d", .forward = "a/b/d", .backward = R"(a\b\d)"},
    NormalizeCase{.path = "a/b/..", .forward = "a/", .backward = R"(a\)"},
    NormalizeCase{.path = "../../a/..", .forward = "../../", .backward = R"(..\..\)"},
    NormalizeCase{.path = "a/..", .forward = ".", .backward = "."},
    NormalizeCase{.path = "", .forward = "", .backward = ""},
    NormalizeCase{.path = ".", .forward = ".", .backward = "."},
    NormalizeCase{.path = "..", .forward = "..", .backward = ".."},
    NormalizeCase{.path = "../..", .forward = "../..", .backward = R"(..\..)"},
    NormalizeCase{.path = "a/../b", .forward = "b", .backward = "b"},
    NormalizeCase{.path = "a/../b/c", .forward = "b/c", .backward = R"(b\c)"},
    NormalizeCase{.path = "a/../../b", .forward = "../b", .backward = R"(..\b)"},
    NormalizeCase{.path = "a/b/c/../../d", .forward = "a/d", .backward = R"(a\d)"},
    NormalizeCase{.path = R"(a\b/c\..\d)", .forward = "a/b/d", .backward = R"(a\b\d)"},
    NormalizeCase{.path = R"(a//b\\c)", .forward = "a/b/c", .backward = R"(a\b\c)"},
    NormalizeCase{.path = "a/b/", .forward = "a/b/", .backward = R"(a\b\)"},
    NormalizeCase{.path = "./a", .forward = "a", .backward = "a"},
    NormalizeCase{.path = "a/./", .forward = "a/", .backward = R"(a\)"},
    NormalizeCase{.path = "C:a/..", .forward = ".", .backward = "."},
    NormalizeCase{.path = "thư mục/./tệp có dấu.txt",
        .forward = "thư mục/tệp có dấu.txt",
        .backward = R"(thư mục\tệp có dấu.txt)"},
    NormalizeCase{.path = R"(C:\x\..)", .forward = "C:/", .backward = R"(C:\)", .is_absolute = true},
    NormalizeCase{.path = "C:/..", .forward = "C:/", .backward = R"(C:\)", .is_absolute = true},
    NormalizeCase{.path = "C:/a/..", .forward = "C:/", .backward = R"(C:\)", .is_absolute = true},
    NormalizeCase{.path = "C:/../Windows", .forward = "C:/Windows", .backward = R"(C:\Windows)", .is_absolute = true},
    NormalizeCase{
        .path = R"(c:\Thư mục\..\tệp.txt)", .forward = "c:/tệp.txt", .backward = R"(c:\tệp.txt)", .is_absolute = true},
    NormalizeCase{.path = "/", .forward = "/", .backward = R"(\)", .is_absolute = true},
    NormalizeCase{.path = "/..", .forward = "/", .backward = R"(\)", .is_absolute = true},
    NormalizeCase{.path = "/../a", .forward = "/a", .backward = R"(\a)", .is_absolute = true},
    NormalizeCase{.path = "///a", .forward = "/a", .backward = R"(\a)", .is_absolute = true},
    NormalizeCase{.path = "//server/share/..", .forward = "//server/", .backward = R"(\\server\)", .is_absolute = true},
    NormalizeCase{.path = R"(\\máy\chia sẻ\tệp)",
        .forward = "//máy/chia sẻ/tệp",
        .backward = R"(\\máy\chia sẻ\tệp)",
        .is_absolute = true},
};

void expect_normalized(Context& context, const NormalizeCase& one) {
    context.expect(fs::normalize(one.path) == one.forward, one.path);
    context.expect(fs::normalize(one.path, '\\') == one.backward, one.path);
    context.expect(fs::is_absolute(one.path) == one.is_absolute, one.path);
    context.expect(fs::is_normalized(one.path) == (one.path == one.forward), one.path);
}

void path_normalize_follows_original(Context& context) {
    for (const NormalizeCase& one : kNormalizeCases) {
        expect_normalized(context, one);
    }
}

struct JoinCase {
    std::string_view dir;
    std::string_view name;
    std::string_view joined;
};

constexpr std::array kJoinCases{
    JoinCase{.dir = "C:/", .name = "..", .joined = "C:/"},
    JoinCase{.dir = "base/", .name = "C:/abs", .joined = "C:/abs"},
    JoinCase{.dir = "", .name = "x", .joined = "x"},
    JoinCase{.dir = "", .name = "", .joined = ""},
    JoinCase{.dir = "dir", .name = "", .joined = "dir"},
    JoinCase{.dir = "dir", .name = "/abs/path", .joined = "/abs/path"},
    JoinCase{.dir = "a/b", .name = "../c", .joined = "a/c"},
    JoinCase{.dir = R"(a\b)", .name = R"(c\d)", .joined = "a/b/c/d"},
    JoinCase{.dir = "a/", .name = "b/", .joined = "a/b"},
    JoinCase{.dir = "thư mục", .name = "tệp.txt", .joined = "thư mục/tệp.txt"},
    JoinCase{.dir = "//máy/chia sẻ", .name = "../x", .joined = "//máy/x"},
};

void path_join_follows_original(Context& context) {
    for (const JoinCase& one : kJoinCases) {
        context.expect(fs::join(one.dir, one.name) == one.joined, one.joined);
    }
}

// Các phần của một đường dẫn; has_parent và has_extension là hai optional của split.
struct PartsCase {
    std::string_view path;
    std::string_view parent;
    std::string_view name;
    std::string_view stem;
    std::string_view extension;
    bool has_parent = false;
    bool has_extension = false;
};

constexpr std::array kPartsCases{
    PartsCase{.path = "a/b/c.tar.gz",
        .parent = "a/b",
        .name = "c.tar.gz",
        .stem = "c.tar",
        .extension = "gz",
        .has_parent = true,
        .has_extension = true},
    PartsCase{.path = R"(dir\tệp.TXT)",
        .parent = "dir",
        .name = "tệp.TXT",
        .stem = "tệp",
        .extension = "TXT",
        .has_parent = true,
        .has_extension = true},
    PartsCase{.path = "C:/x.y",
        .parent = "C:/",
        .name = "x.y",
        .stem = "x",
        .extension = "y",
        .has_parent = true,
        .has_extension = true},
    PartsCase{.path = "/a", .parent = "/", .name = "a", .stem = "a", .extension = "", .has_parent = true},
    PartsCase{.path = "/", .parent = "/", .name = "", .stem = "", .extension = "", .has_parent = true},
    PartsCase{.path = "a/..", .parent = "a", .name = "..", .stem = "..", .extension = "", .has_parent = true},
    PartsCase{.path = "a/b/", .parent = "a/b", .name = "", .stem = "", .extension = "", .has_parent = true},
    PartsCase{.path = "tên.có.chấm/tệp",
        .parent = "tên.có.chấm",
        .name = "tệp",
        .stem = "tệp",
        .extension = "",
        .has_parent = true},
    PartsCase{.path = "a", .parent = "", .name = "a", .stem = "a", .extension = ""},
    PartsCase{.path = ".gitignore", .parent = "", .name = ".gitignore", .stem = ".gitignore", .extension = ""},
};

void expect_parts(Context& context, const PartsCase& one) {
    context.expect(fs::parent(one.path) == one.parent, one.path);
    context.expect(fs::file_name(one.path) == one.name, one.path);
    context.expect(fs::stem(one.path) == one.stem, one.path);
    context.expect(fs::extension(one.path) == one.extension, one.path);
    const fs::PathParts parts = fs::split(one.path);
    context.expect(parts.parent.has_value() == one.has_parent, one.path);
    context.expect(parts.parent.value_or("") == one.parent, one.path);
    context.expect(parts.stem == one.stem, one.path);
    context.expect(parts.extension.has_value() == one.has_extension, one.path);
    context.expect(parts.extension.value_or("") == one.extension, one.path);
}

void path_parts_follow_original(Context& context) {
    for (const PartsCase& one : kPartsCases) {
        expect_parts(context, one);
    }
}

struct EditCase {
    std::string_view path;
    std::string_view ext;
    std::string_view appended;
    std::string_view replaced;
};

constexpr std::array kEditCases{
    EditCase{.path = "a/b.txt", .ext = ".bin", .appended = "a/b.txt.bin", .replaced = "a/b.bin"},
    EditCase{.path = "a/b.txt", .ext = "", .appended = "a/b.txt", .replaced = "a/b"},
    EditCase{.path = "a.b/c", .ext = "x", .appended = "a.b/c.x", .replaced = "a.b/c.x"},
    EditCase{.path = "a/b", .ext = "txt", .appended = "a/b.txt", .replaced = "a/b.txt"},
    EditCase{.path = "a", .ext = "", .appended = "a", .replaced = "a"},
    EditCase{.path = ".gitignore", .ext = "bak", .appended = ".gitignore.bak", .replaced = ".gitignore.bak"},
    EditCase{.path = "tệp.tar.gz", .ext = "zip", .appended = "tệp.tar.gz.zip", .replaced = "tệp.tar.zip"},
    EditCase{.path = "a/b.", .ext = "x", .appended = "a/b..x", .replaced = "a/b.x"},
};

void expect_edits(Context& context, const EditCase& one) {
    context.expect(fs::append_extension(one.path, one.ext) == one.appended, one.appended);
    context.expect(fs::replace_extension(one.path, one.ext) == one.replaced, one.replaced);
}

void path_extension_edits_follow_original(Context& context) {
    for (const EditCase& one : kEditCases) {
        expect_edits(context, one);
    }
}

void file_append_then_seek_reads_from_sought_position(Context& context) {
    const std::string path = fs::join(case_dir(context, "append"), "append.bin");
    context.expect(fs::write_file(path, view_bytes("0123456789")).has_value(), "ghi tệp mẫu");
    auto file = fs::File::open(path, fs::Mode::kRead | fs::Mode::kWrite | fs::Mode::kAppend);
    context.expect(file.has_value(), "mở đọc ghi nối đuôi");
    if (!file) return;
    context.expect(file->write(view_bytes("XY")).has_value(), "ghi nối đuôi");
    context.expect(file->seek(fs::Seek::kBegin, 2).has_value(), "seek về vị trí 2");
    std::array<std::byte, 3> out{};
    context.expect(file->read(out).value_or(0) == 3, "đọc đủ 3 byte");
    context.expect(view_text(out) == "234", "đọc từ vị trí vừa seek, không từ cuối tệp");
    context.expect(file->size().value_or(0) == 12, "cỡ sau khi nối là 12");
}

void file_counts_buffered_bytes_and_reads_short(Context& context) {
    const std::string path = fs::join(case_dir(context, "buffered"), "tệp có dấu.bin");
    auto writer = fs::File::open(path, fs::Mode::kWrite);
    context.expect(writer.has_value(), "mở ghi tệp tên có dấu");
    if (!writer) return;
    context.expect(writer->write(view_bytes("hello")).has_value(), "ghi hello");
    context.expect(writer->write({}).value_or(1) == 0, "ghi rỗng trả 0");
    context.expect(writer->size().value_or(0) == 5, "size tính cả byte còn trong bộ đệm");
    context.expect(writer->close().has_value(), "đóng tệp ghi");
    auto reader = fs::File::open(path, fs::Mode::kRead);
    context.expect(reader.has_value(), "mở đọc");
    if (!reader) return;
    std::array<std::byte, 16> out{};
    context.expect(reader->read(out).value_or(0) == 5, "đọc ngắn ở cuối tệp");
    context.expect(reader->at_end(), "at_end ngay khi vị trí chạm cỡ");
    context.expect(reader->read(out).value_or(9) == 0, "đọc ở EOF trả 0, không lỗi");
    std::array<std::byte, 4> piece{};
    context.expect(reader->read_at(3, piece).value_or(0) == 2, "read_at vắt qua cuối tệp");
    context.expect(reader->read_at(99, piece).value_or(9) == 0, "read_at sau cuối tệp trả 0");
}

void file_open_reports_missing_and_directory(Context& context) {
    const std::string dir = case_dir(context, "open");
    const auto absent = fs::File::open(fs::join(dir, "không có"), fs::Mode::kRead);
    context.expect(code_of(absent) == ErrorCode::kNotFound, "tệp thiếu là NotFound");
    const auto folder = fs::File::open(dir, fs::Mode::kRead);
    context.expect(code_of(folder) == ErrorCode::kIsADirectory, "mở thư mục là IsADirectory");
    const auto unusable = fs::File::open(fs::join(dir, "x"), fs::Mode::kAllowRead);
    context.expect(code_of(unusable) == ErrorCode::kInvalidArgument, "thiếu Read và Write");
}

void file_truncate_flushes_pulls_back_and_extends(Context& context) {
    const std::string path = fs::join(case_dir(context, "truncate"), "cat.bin");
    context.expect(fs::write_file(path, view_bytes("0123456789")).has_value(), "ghi tệp mẫu");
    auto file = fs::File::open(path, fs::Mode::kRead | fs::Mode::kWrite);
    context.expect(file.has_value(), "mở đọc ghi");
    if (!file) return;
    // "ab" còn trong bộ đệm ghi: cắt phải đẩy nó trước, không thì lần đẩy sau nới tệp trở lại.
    context.expect(file->seek(fs::Seek::kBegin, 8).has_value(), "seek về vị trí 8");
    context.expect(file->write(view_bytes("ab")).has_value(), "ghi ab vào bộ đệm");
    context.expect(file->truncate(5).has_value(), "cắt về 5");
    context.expect(file->size().value_or(0) == 5, "cỡ là 5");
    // Vị trí 10 vượt cỡ mới nên lùi về 5: "Z" nối ngay sau "01234".
    context.expect(file->write(view_bytes("Z")).has_value(), "ghi Z ở vị trí đã lùi");
    context.expect(file->truncate(8).has_value(), "nới tới 8");
    context.expect(file->close().has_value(), "đóng");
    context.expect(text_in(path) == std::string("01234Z\0\0", 8), "cắt bỏ đuôi, nới thêm số 0");
    auto reader = fs::File::open(path, fs::Mode::kRead);
    context.expect(reader.has_value(), "mở chỉ đọc");
    if (!reader) return;
    const auto refused = reader->truncate(1);
    context.expect(code_of(refused) == ErrorCode::kPermissionDenied, "không cắt tệp chỉ đọc");
}

void file_maps_content_and_empty_file(Context& context) {
    const std::string dir = case_dir(context, "mapped");
    const std::string path = fs::join(dir, "mapped.bin");
    const auto content = view_bytes("mapped content");
    context.expect(fs::write_file(path, content).has_value(), "ghi tệp mẫu");
    const auto mapped = fs::MappedFile::open(path);
    context.expect(mapped.has_value(), "ánh xạ tệp");
    if (!mapped) return;
    const auto writer = fs::File::open(path, fs::Mode::kWrite);
    context.expect(!writer.has_value(), "tệp đang ánh xạ không mở cắt rỗng được");
    context.expect(view_text(mapped->bytes()) == "mapped content", "nội dung ánh xạ");
    mapped->prefetch(4, 1000);
    const std::string blank = fs::join(dir, "empty.bin");
    context.expect(fs::write_file(blank, {}).has_value(), "ghi tệp rỗng");
    const auto empty = fs::MappedFile::open(blank);
    context.expect(empty && empty->bytes().empty(), "ánh xạ tệp rỗng trả vùng rỗng");
}

constexpr std::array<std::size_t, 5> kChunks{1, 4'095, 65'536, 100'000, 7};

// Dữ liệu không lặp theo chu kỳ ngắn, để lệch một byte là thấy.
[[nodiscard]] std::vector<std::byte> sample(std::size_t size) {
    std::vector<std::byte> data(size);
    for (std::size_t index = 0; index < size; ++index) {
        data.at(index) = static_cast<std::byte>(((index * 7) + (index / 97)) & 0xFFU);
    }
    return data;
}

// Ghi data theo các khúc lẻ nối nhau; false khi một lần ghi không trọn khúc.
[[nodiscard]] bool write_in_chunks(fs::File& file, std::span<const std::byte> data) {
    std::size_t done = 0;
    bool is_whole = true;
    for (std::size_t turn = 0; is_whole && done < data.size(); ++turn) {
        const std::size_t count = std::min(kChunks.at(turn % kChunks.size()), data.size() - done);
        is_whole = file.write(data.subspan(done, count)).value_or(0) == count;
        done += count;
    }
    return is_whole;
}

// Đọc theo các khúc lẻ tới khi đầy out hoặc hết tệp; trả số byte đọc được.
[[nodiscard]] std::size_t read_in_chunks(fs::File& file, std::span<std::byte> out) {
    std::size_t done = 0;
    std::size_t got = 1;
    for (std::size_t turn = 0; got != 0 && done < out.size(); ++turn) {
        const std::size_t count = std::min(kChunks.at(turn % kChunks.size()), out.size() - done);
        got = file.read(out.subspan(done, count)).value_or(0);
        done += got;
    }
    return done;
}

// Tệp lớn hơn bộ đệm 64 KiB: khúc nhỏ đi qua bộ đệm, khúc lớn đi thẳng xuống hệ điều hành.
void file_crosses_buffer_in_both_directions(Context& context) {
    const std::string path = fs::join(case_dir(context, "large"), "large.bin");
    const std::vector<std::byte> data = sample(300'000);
    auto writer = fs::File::open(path, fs::Mode::kWrite);
    context.expect(writer.has_value(), "mở ghi");
    if (!writer) return;
    context.expect(write_in_chunks(*writer, data), "ghi trọn từng khúc");
    context.expect(writer->size().value_or(0) == data.size(), "cỡ trước khi đóng");
    context.expect(writer->close().has_value(), "đóng");
    const auto whole = fs::read_file(path);
    context.expect(whole && std::ranges::equal(whole->span(), data), "read_file trùng dữ liệu");
    auto reader = fs::File::open(path, fs::Mode::kRead);
    context.expect(reader.has_value(), "mở đọc");
    if (!reader) return;
    std::vector<std::byte> back(data.size() + 1'000);
    const std::size_t got = read_in_chunks(*reader, back);
    context.expect(got == data.size(), "đọc theo khúc dừng đúng ở cuối tệp");
    const std::span<const std::byte> read = std::span(back).first(std::min(got, back.size()));
    context.expect(std::ranges::equal(read, data), "nội dung đọc theo khúc trùng dữ liệu");
    const auto mapped = reader->map();
    context.expect(mapped && std::ranges::equal(*mapped, data), "map trùng dữ liệu");
}

void file_writes_atomically(Context& context) {
    const std::string dir = case_dir(context, "atomic");
    const std::string path = fs::join(dir, "cấu hình.txt");
    const auto first = fs::write_file_atomic(path, view_bytes("bản một"));
    context.expect(first.has_value(), "ghi nguyên tử lần đầu");
    const auto second = fs::write_file_atomic(path, view_bytes("bản hai dài hơn"));
    context.expect(second.has_value(), "ghi đè nguyên tử");
    context.expect(text_in(path) == "bản hai dài hơn", "thấy bản mới đủ");
    context.expect(sorted(fs::list_files(dir)) == Names{"cấu hình.txt"}, "không để lại tệp tạm");
    const std::string nowhere = fs::join(dir, "không có/tệp.txt");
    const auto failed = fs::write_file_atomic(nowhere, view_bytes("x"));
    context.expect(!failed.has_value(), "thư mục đích thiếu là lỗi");
}

void disk_builds_deep_tree_and_resolves_dot_dot(Context& context) {
    const std::string dir = case_dir(context, "tree");
    std::string deep = dir;
    for (int level = 0; level < 48; ++level) {
        deep += "/d";
    }
    context.expect(fs::create_directories(deep).has_value(), "tạo cây 48 cấp");
    context.expect(fs::is_directory(deep), "cấp cuối là thư mục");
    context.expect(fs::create_directories(deep).has_value(), "cây đã có là thành công");
    context.expect(fs::create_directories("").has_value(), "đường dẫn rỗng là thành công");
    // Chuẩn hoá trước khi tạo: đi theo chuỗi thô thì thư mục "a" bị tạo thừa.
    const std::string dotted = fs::join(dir, "a") + "/../b/c";
    context.expect(fs::create_directories(dotted).has_value(), "tạo a/../b/c");
    context.expect(fs::is_directory(fs::join(dir, "b/c")), "b/c được tạo");
    context.expect(!fs::exists(fs::join(dir, "a")), "a không bị tạo thừa");
}

void disk_refuses_directory_over_file(Context& context) {
    const std::string dir = case_dir(context, "blocked");
    const std::string blocker = fs::join(dir, "tệp chắn");
    context.expect(fs::write_file(blocker, view_bytes("x")).has_value(), "ghi tệp chắn");
    const auto under = fs::create_directories(fs::join(blocker, "x/y"));
    context.expect(!under.has_value(), "không tạo cây dưới một tệp");
    const auto taken = fs::create_directory(blocker);
    context.expect(code_of(taken) == ErrorCode::kNotADirectory, "trùng tên một tệp là lỗi");
    context.expect(fs::create_directory(dir).has_value(), "thư mục đã có là thành công");
}

void disk_lists_files_by_extension(Context& context) {
    const std::string dir = case_dir(context, "list");
    const bool is_ready = fs::write_file(fs::join(dir, "một.txt"), view_bytes("1")) &&
        fs::write_file(fs::join(dir, "hai.TXT"), view_bytes("22")) &&
        fs::write_file(fs::join(dir, "ba.bin"), view_bytes("333")) &&
        fs::create_directory(fs::join(dir, "thư mục con"));
    context.expect(is_ready, "ghi ba tệp và một thư mục con");
    const Names all{"ba.bin", "hai.TXT", "một.txt"};
    context.expect(sorted(fs::list_files(dir)) == all, "mọi tệp, không tính thư mục");
    context.expect(sorted(fs::list_files(dir, "*")) == all, "* là mọi tệp");
    context.expect(sorted(fs::list_files(dir, "*.*")) == all, "*.* là mọi tệp");
    const Names text{"hai.TXT", "một.txt"};
    context.expect(sorted(fs::list_files(dir, ".txt")) == text, "lọc không phân biệt hoa thường");
    context.expect(sorted(fs::list_files(dir, "txt")) == text, "phần mở rộng không cần dấu chấm");
    context.expect(sorted(fs::list_files(dir, "*.bin")) == Names{"ba.bin"}, "lọc *.bin");
    context.expect(sorted(fs::list_directories(dir)) == Names{"thư mục con"}, "thư mục con");
    const auto missing = fs::list_files(fs::join(dir, "không có"));
    context.expect(!missing.has_value(), "liệt kê thư mục thiếu là lỗi");
}

void disk_reports_kind_size_and_time(Context& context) {
    const std::string dir = case_dir(context, "info");
    const std::string path = fs::join(dir, "ba.bin");
    const std::string absent = fs::join(dir, "không có");
    context.expect(fs::write_file(path, view_bytes("333")).has_value(), "ghi tệp");
    const auto known = fs::info(path);
    const bool is_sized = known && known->kind == fs::Kind::kFile && known->size == 3;
    context.expect(is_sized, "info trả loại và cỡ");
    const auto gone = fs::info(absent);
    context.expect(gone && gone->kind == fs::Kind::kMissing, "thiếu là Missing, không phải lỗi");
    context.expect(fs::is_file(path) && !fs::is_directory(path), "tệp là tệp");
    context.expect(fs::is_directory(dir) && !fs::is_file(dir), "thư mục là thư mục");
    context.expect(fs::exists(path) && !fs::exists(absent), "exists");
    const auto never = fs::last_write(absent);
    context.expect(code_of(never) == ErrorCode::kNotFound, "last_write của tệp thiếu");
    const auto written = fs::last_write(path);
    const bool is_dated = written && written->time_since_epoch().count() > 0;
    context.expect(is_dated, "last_write của tệp có");
}

void disk_copies_renames_and_removes(Context& context) {
    const std::string dir = case_dir(context, "move");
    const std::string one = fs::join(dir, "một.txt");
    const std::string two = fs::join(dir, "hai.txt");
    const std::string three = fs::join(dir, "ba.bin");
    const bool is_ready = fs::write_file(one, view_bytes("1")) && fs::write_file(two, view_bytes("22")) &&
        fs::write_file(three, view_bytes("333"));
    context.expect(is_ready, "ghi ba tệp");
    context.expect(fs::copy(three, one).has_value(), "chép đè lên tệp đã có");
    context.expect(text_in(one) == "333", "đích mang nội dung nguồn");
    context.expect(fs::rename(two, three).has_value(), "đổi tên đè lên tệp đã có");
    context.expect(text_in(three) == "22", "đích mang nội dung của tên cũ");
    context.expect(!fs::exists(two), "tên cũ không còn");
    context.expect(fs::remove(three).has_value(), "xoá tệp");
    context.expect(!fs::remove(three).has_value(), "xoá tệp thiếu là lỗi");
    context.expect(sorted(fs::list_files(dir)) == Names{"một.txt"}, "còn đúng một tệp");
}

struct Event {
    std::string path;
    fs::Change change = fs::Change::kModified;
};

// Điều một ca chờ: ít nhất count sự kiện loại change có path kết thúc bằng tail.
struct Wanted {
    std::string_view tail;
    fs::Change change = fs::Change::kCreated;
    std::size_t count = 1;
};

// Sự kiện gom về từ luồng theo dõi. Ca test chờ có hạn trên biến điều kiện: sự kiện tới là thức
// ngay, không tới thì hết hạn và ca báo sai chứ không treo.
class Events {
public:
    void add(std::string_view path, fs::Change change) {
        Event event{.path = std::string(path), .change = change};
        const std::scoped_lock lock(mutex_);
        seen_.push_back(std::move(event));
        arrived_.notify_all();
    }

    // false khi hết kPatience mà chưa đủ.
    [[nodiscard]] bool wait(const Wanted& wanted) {
        std::unique_lock lock(mutex_);
        const auto is_enough = [&] { return count(wanted) >= wanted.count; };
        return arrived_.wait_for(lock, kPatience, is_enough);
    }

private:
    // Gọi khi đang giữ mutex_.
    [[nodiscard]] std::size_t count(const Wanted& wanted) const {
        const auto matches = [&](const Event& event) {
            return event.change == wanted.change && event.path.ends_with(wanted.tail);
        };
        return static_cast<std::size_t>(std::ranges::count_if(seen_, matches));
    }

    // Bảo vệ seen_.
    std::mutex mutex_;
    std::condition_variable arrived_;
    std::vector<Event> seen_;
};

// events phải sống lâu hơn watcher trả về: hàm gọi lại giữ tham chiếu tới nó.
[[nodiscard]] core::Result<fs::Watcher> watch(std::string_view dir, fs::Change changes, Events& events) {
    const auto callback = [&events](std::string_view path, fs::Change change) { events.add(path, change); };
    return fs::Watcher::start(dir, changes, callback);
}

// Tên dài hơn 99 byte UTF-8: bản _Ref làm luồng theo dõi quay vô hạn với tên như thế.
constexpr std::string_view kLongName =
    "tệp tin có tên tiếng Việt rất dài, vượt quá chín mươi chín byte UTF-8 mà bản gốc làm quay "
    "vô hạn.txt";

void watcher_reports_create_and_delete(Context& context) {
    const std::string dir = case_dir(context, "watch");
    Events events;
    const auto watcher = watch(dir, fs::Change::kCreated | fs::Change::kDeleted, events);
    context.expect(watcher.has_value(), "bắt đầu theo dõi");
    if (!watcher) return;
    const std::string path = fs::join(dir, kLongName);
    context.expect(fs::write_file(path, view_bytes("x")).has_value(), "ghi tệp tên dài");
    const Wanted created{.tail = path, .change = fs::Change::kCreated};
    context.expect(events.wait(created), "báo Created kèm đường dẫn đủ, tên dài có dấu");
    context.expect(fs::remove(path).has_value(), "xoá tệp");
    const Wanted deleted{.tail = path, .change = fs::Change::kDeleted};
    context.expect(events.wait(deleted), "báo Deleted");
}

constexpr std::size_t kBurst = 100;

[[nodiscard]] bool write_numbered(std::string_view dir, std::size_t index) {
    const std::string name = std::format("loạt-{}.tmp", index);
    return fs::write_file(fs::join(dir, name), view_bytes("y")).has_value();
}

// Cổng giữ luồng theo dõi đứng trong hàm gọi lại cho tới khi ca test mở. Trong lúc đó nhân gom các
// thay đổi vào bộ đệm của handle, nên lần đọc kế trả nhiều bản ghi một lượt.
class Gate {
public:
    void open() {
        const std::scoped_lock lock(mutex_);
        is_open_ = true;
        opened_.notify_all();
    }

    // Trả về khi cổng mở; hết kPatience thì đi tiếp để huỷ watcher không bao giờ treo.
    void pass() {
        std::unique_lock lock(mutex_);
        const bool is_passed = opened_.wait_for(lock, kPatience, [&] { return is_open_; });
        static_cast<void>(is_passed);
    }

private:
    // Bảo vệ is_open_.
    std::mutex mutex_;
    std::condition_variable opened_;
    bool is_open_ = false;
};

// Tệp đầu giữ luồng theo dõi ở cổng, các tệp sau dồn lại trong bộ đệm của nhân: mở cổng thì lần
// đọc kế mang cả loạt bản ghi, đi qua vòng tách bản ghi của watcher (đã đo: không có cổng thì
// mỗi lần đọc chỉ có một bản ghi và vòng ấy không bao giờ lặp).
void watcher_reports_every_record_of_one_read(Context& context) {
    const std::string dir = case_dir(context, "burst");
    Events events;
    Gate gate;
    const auto callback = [&](std::string_view path, fs::Change change) {
        events.add(path, change);
        gate.pass();
    };
    const auto watcher = fs::Watcher::start(dir, fs::Change::kCreated, callback);
    context.expect(watcher.has_value(), "bắt đầu theo dõi");
    if (!watcher) return;
    std::size_t written = write_numbered(dir, 0) ? 1U : 0U;
    const Wanted first{.tail = ".tmp", .change = fs::Change::kCreated};
    context.expect(events.wait(first), "tệp đầu được báo, luồng theo dõi đứng ở cổng");
    for (std::size_t index = 1; index < kBurst; ++index) {
        written += write_numbered(dir, index) ? 1U : 0U;
    }
    context.expect(written == kBurst, "ghi đủ loạt tệp");
    gate.open();
    const Wanted all{.tail = ".tmp", .change = fs::Change::kCreated, .count = kBurst};
    context.expect(events.wait(all), "mọi bản ghi của một lần đọc đều được báo");
}

void watcher_move_assignment_switches_directory(Context& context) {
    const std::string first = case_dir(context, "watch-a");
    const std::string second = case_dir(context, "watch-b");
    Events events;
    auto watcher = watch(first, fs::Change::kCreated, events);
    auto other = watch(second, fs::Change::kCreated, events);
    context.expect(watcher && other, "hai watcher bắt đầu theo dõi");
    if (!watcher || !other) return;
    // Gán đè: luồng cũ dừng và join trước, rồi trạng thái nó đang dùng mới bị huỷ.
    *watcher = std::move(*other);
    const std::string path = fs::join(second, "sau khi gán.txt");
    context.expect(fs::write_file(path, view_bytes("z")).has_value(), "ghi vào thư mục thứ hai");
    const Wanted created{.tail = path, .change = fs::Change::kCreated};
    context.expect(events.wait(created), "watcher đã gán đè vẫn báo thay đổi");
}

void watcher_refuses_bad_arguments(Context& context) {
    const std::string dir = case_dir(context, "watch-bad");
    Events events;
    const auto no_callback = fs::Watcher::start(dir, fs::Change::kCreated, {});
    context.expect(code_of(no_callback) == ErrorCode::kInvalidArgument, "thiếu hàm gọi lại");
    const auto no_events = watch(dir, fs::Change::kOverflow, events);
    context.expect(code_of(no_events) == ErrorCode::kInvalidArgument, "chưa chọn sự kiện nào");
    const auto missing = watch(fs::join(dir, "không có"), fs::Change::kCreated, events);
    context.expect(code_of(missing) == ErrorCode::kNotFound, "thư mục thiếu trả lỗi qua Result");
}

constexpr std::array kCases{
    Case{.name = "path_normalize_follows_original", .body = &path_normalize_follows_original},
    Case{.name = "path_join_follows_original", .body = &path_join_follows_original},
    Case{.name = "path_parts_follow_original", .body = &path_parts_follow_original},
    Case{.name = "path_extension_edits_follow_original", .body = &path_extension_edits_follow_original},
    Case{.name = "file_append_then_seek_reads_from_sought_position",
        .body = &file_append_then_seek_reads_from_sought_position},
    Case{.name = "file_counts_buffered_bytes_and_reads_short", .body = &file_counts_buffered_bytes_and_reads_short},
    Case{.name = "file_open_reports_missing_and_directory", .body = &file_open_reports_missing_and_directory},
    Case{.name = "file_truncate_flushes_pulls_back_and_extends", .body = &file_truncate_flushes_pulls_back_and_extends},
    Case{.name = "file_maps_content_and_empty_file", .body = &file_maps_content_and_empty_file},
    Case{.name = "file_crosses_buffer_in_both_directions", .body = &file_crosses_buffer_in_both_directions},
    Case{.name = "file_writes_atomically", .body = &file_writes_atomically},
    Case{.name = "disk_builds_deep_tree_and_resolves_dot_dot", .body = &disk_builds_deep_tree_and_resolves_dot_dot},
    Case{.name = "disk_refuses_directory_over_file", .body = &disk_refuses_directory_over_file},
    Case{.name = "disk_lists_files_by_extension", .body = &disk_lists_files_by_extension},
    Case{.name = "disk_reports_kind_size_and_time", .body = &disk_reports_kind_size_and_time},
    Case{.name = "disk_copies_renames_and_removes", .body = &disk_copies_renames_and_removes},
    Case{.name = "watcher_reports_create_and_delete", .body = &watcher_reports_create_and_delete},
    Case{.name = "watcher_reports_every_record_of_one_read", .body = &watcher_reports_every_record_of_one_read},
    Case{.name = "watcher_move_assignment_switches_directory", .body = &watcher_move_assignment_switches_directory},
    Case{.name = "watcher_refuses_bad_arguments", .body = &watcher_refuses_bad_arguments},
};

// Chạy mọi ca trong thư mục tạm rồi dọn nó trước khi main kiểm kết quả: check dừng tiến trình
// ngay, nên việc dọn không thể đứng sau. Cây còn sót sau khi dọn (handle rò) tính là một lỗi.
[[nodiscard]] std::int32_t run_in_temp_tree() {
    remove_tree();
    const bool is_made = fs::create_directory(tree_root()).has_value();
    core::check(is_made, "fs_tests: không tạo được thư mục tạm");
    const std::int32_t failures = run_all(kCases);
    remove_tree();
    const bool is_clean = !fs::exists(tree_root());
    if (!is_clean) static_cast<void>(std::fputs("fs_tests: thư mục tạm chưa dọn sạch\n", stderr));
    return failures + (is_clean ? 0 : 1);
}

} // namespace
} // namespace game::test

// Dựng đường dẫn và dọn thư mục tạm có cấp phát; ném ở đây thì tiến trình dừng, test đỏ (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
int main() {
    SetConsoleOutputCP(CP_UTF8);
    game::core::check(game::test::run_in_temp_tree() == 0, "fs_tests: mọi ca phải qua");
    return 0;
}
