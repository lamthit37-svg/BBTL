// Test của core: đổi mã UTF-8 và wchar_t, cắt và kiểm UTF-8, mã lỗi và chi tiết của Error.
// Win32: wchar_t là UTF-16, mã hệ thống là Win32. POSIX: wchar_t là UTF-32, mã là errno.
#include "core/check.hpp"
#include "core/error.hpp"
#include "core/function.hpp"
#include "core/number.hpp"
#include "core/range.hpp"
#include "core/text.hpp"
#include "test.hpp"

#include <array>
#if !defined(_WIN32)
#include <cerrno>
#endif
#include <cstdint>
#include <format>
#include <limits>
#include <optional>
#include <string>
#include <string_view>

namespace game::test {
namespace {

void text_round_trips_utf8_and_utf16(Context& context) noexcept {
    const std::string_view source = "Thiên Long Bát Bộ — 天龍八部";
    const std::wstring wide = core::widen(source);
    context.expect(wide == L"Thiên Long Bát Bộ — 天龍八部", "UTF-8 sang wchar_t đúng từng ký tự");
    context.expect(core::narrow(wide) == source, "wchar_t về lại đúng chuỗi UTF-8 ban đầu");
    context.expect(core::widen("").empty(), "chuỗi UTF-8 rỗng ra rỗng");
    context.expect(core::narrow(L"").empty(), "wchar_t rỗng ra rỗng");
}

void utf8_cut_keeps_whole_characters(Context& context) noexcept {
    // a=1, ế=E1 BA BF, b=1.
    const std::string_view text = "aếb";
    context.expect(core::utf8_prefix(text, 2) == "a", "cắt giữa ký tự thì lùi về đầu ký tự");
    context.expect(core::utf8_prefix(text, 4) == "aế", "cắt đúng ranh ký tự thì giữ nguyên");
    context.expect(core::utf8_prefix(text, 99) == text, "giới hạn lớn hơn chuỗi thì trả cả chuỗi");
    context.expect(core::utf8_suffix(text, 2) == "b", "đuôi bắt đầu ở đầu một ký tự");
    context.expect(core::utf8_suffix(text, 4) == "ếb", "đuôi đúng ranh ký tự thì giữ nguyên");
}

struct Utf8Case {
    std::string_view bytes;
    std::string_view what;
    bool is_valid = false;
};

constexpr std::array kUtf8Cases{
    Utf8Case{.bytes = "", .what = "chuỗi rỗng", .is_valid = true},
    Utf8Case{.bytes = "abc", .what = "ASCII ngắn", .is_valid = true},
    Utf8Case{.bytes = "0123456789abcdefXYZ", .what = "ASCII dài hơn 16 byte", .is_valid = true},
    Utf8Case{.bytes = "tiếng Việt có dấu", .what = "hai và ba byte", .is_valid = true},
    Utf8Case{.bytes = "天龍八部", .what = "chữ Hán ba byte", .is_valid = true},
    Utf8Case{.bytes = "\xF0\x9F\x98\x80", .what = "U+1F600 bốn byte", .is_valid = true},
    Utf8Case{.bytes = "12345678\xE1\xBA\xBFzzzzzzzz", .what = "ASCII kẹp đa byte", .is_valid = true},
    Utf8Case{.bytes = "\x80", .what = "byte tiếp nối đứng một mình"},
    Utf8Case{.bytes = "\xC0\xAF", .what = "dạng hai byte dài quá mức"},
    Utf8Case{.bytes = "\xE0\x80\x80", .what = "dạng ba byte dài quá mức"},
    Utf8Case{.bytes = "\xED\xA0\x80", .what = "nửa cặp thay thế UTF-16"},
    Utf8Case{.bytes = "\xF4\x90\x80\x80", .what = "điểm mã trên U+10FFFF"},
    Utf8Case{.bytes = "\xF5\x80\x80\x80", .what = "byte đầu F5"},
    Utf8Case{.bytes = "\xE1\xBA", .what = "dãy ba byte bị cụt"},
    Utf8Case{.bytes = "abc\xE1\xBA", .what = "dãy bị cụt ở cuối chuỗi"},
    Utf8Case{.bytes = "12345678\xFF", .what = "byte hỏng sau đoạn ASCII tám byte"},
    Utf8Case{.bytes = "\xE1\xBA\xBF\x80", .what = "byte tiếp nối thừa sau dãy hợp lệ"},
};

void utf8_validation_follows_rfc_3629(Context& context) noexcept {
    for (const Utf8Case& one : kUtf8Cases) {
        context.expect(core::is_valid_utf8(one.bytes) == one.is_valid, one.what);
    }
}

// utf8_step đọc từng ký tự để vẽ chữ: đủ bốn độ dài, và dãy hỏng luôn tiến một byte.
static_assert(core::utf8_step("A").code == U'A' && core::utf8_step("A").length == 1);
static_assert(core::utf8_step("\xE1\xBA\xBF").code == U'ế');
static_assert(core::utf8_step("").length == 0);

void utf8_step_reads_one_character(Context& context) noexcept {
    const core::Utf8Step two = core::utf8_step("\xC4\x91i");
    context.expect(two.code == U'đ' && two.length == 2, "đ dài hai byte");
    const core::Utf8Step three = core::utf8_step("\xE1\xBA\xBFn");
    context.expect(three.code == U'ế' && three.length == 3, "ế dài ba byte");
    const core::Utf8Step four = core::utf8_step("\xF0\x9F\x98\x80");
    context.expect(four.code == U'\U0001F600' && four.length == 4, "ngoài BMP dài bốn byte");
    const core::Utf8Step stray = core::utf8_step("\x80"
                                                 "a");
    context.expect(stray.code == 0xFFFD && stray.length == 1, "byte tiếp nối lạc chỗ");
    const core::Utf8Step cut = core::utf8_step("\xE1\xBA");
    context.expect(cut.code == 0xFFFD && cut.length == 1, "dãy bị cụt");
    const core::Utf8Step wrong = core::utf8_step("\xE1"
                                                 "ab");
    context.expect(wrong.code == 0xFFFD && wrong.length == 1, "byte tiếp nối sai");
    context.expect(core::utf8_step("").length == 0, "chuỗi rỗng không tiến");
}

void error_keeps_code_message_and_place(Context& context) noexcept {
    const core::Failure failure = core::fail(core::ErrorCode::kNotFound, "không mở được tệp", "a/b.txt");
    const core::Error& error = failure.error();
    context.expect(error.code() == core::ErrorCode::kNotFound, "mã lỗi giữ nguyên");
    context.expect(error.message() == "không mở được tệp", "thông điệp tĩnh giữ nguyên");
    context.expect(error.detail() == "a/b.txt", "chi tiết ngắn nằm nội tuyến");
    context.expect(!error.truncated(), "chi tiết ngắn không bị cắt");
    context.expect(error.file().ends_with("core_tests.cpp"), "vị trí là tệp gọi fail");
    context.expect(error.line() != 0, "vị trí có số dòng");
    context.expect(core::name(core::ErrorCode::kDeviceLost) == "DeviceLost", "tên mã lỗi");
}

// string và format có thể ném; tiến trình dừng.
void error_detail_outgrows_inline(Context& context) {
    const std::string longer(core::Error::kInlineCapacity + 40, 'x');
    const core::Failure heaped = core::fail(core::ErrorCode::kCorrupt, "dữ liệu hỏng", longer);
    context.expect(heaped.error().detail() == longer, "chi tiết dài hơn chỗ nội tuyến vẫn đủ");
    const std::string huge(core::Error::kMaxDetail + 100, 'y');
    const core::Failure cut = core::fail(core::ErrorCode::kCorrupt, "dữ liệu hỏng", huge);
    context.expect(cut.error().truncated(), "chi tiết quá trần được đánh dấu đã cắt");
    context.expect(cut.error().detail().size() == core::Error::kMaxDetail, "giữ đúng trần");
    const core::Failure formatted =
        core::fail(core::ErrorCode::kOutOfRange, "khoá ngoài miền", "{} = {}", "tốc độ", 12);
    context.expect(formatted.error().detail() == "tốc độ = 12", "chi tiết dạng std::format");
}

void error_maps_and_prints_system_codes(Context& context) {
#if defined(_WIN32)
    constexpr std::uint32_t kMissing = 2;
    constexpr std::uint32_t kDenied = 5;
#else
    constexpr std::uint32_t kMissing = ENOENT;
    constexpr std::uint32_t kDenied = EACCES;
#endif
    context.expect(core::from_system(kMissing) == core::ErrorCode::kNotFound, "thiếu tệp là NotFound");
    context.expect(core::from_system(kDenied) == core::ErrorCode::kPermissionDenied, "từ chối quyền");
    context.expect(core::from_system(0xFFFF'FFF0U) == core::ErrorCode::kUnknown, "mã lạ");
    const core::Failure failure = core::fail_system(kMissing, "không mở được tệp", "x.bin");
    context.expect(failure.error().code() == core::ErrorCode::kNotFound, "mã suy từ hệ thống");
    context.expect(failure.error().system() == kMissing, "mã gốc của hệ thống giữ lại");
    const std::string message = core::system_message(kMissing);
    context.expect(!message.empty(), "hệ điều hành có thông điệp cho mã thiếu tệp");
    const std::string line = std::format("{}", failure.error());
    const std::string marker = std::format("[hệ thống {:#x}: ", kMissing);
    context.expect(line.contains("NotFound: không mở được tệp (x.bin)"), "dòng in mã và chi tiết");
    context.expect(line.contains(marker), "dòng in mã hệ thống");
    context.expect(line.contains("Test/Core/core_tests.cpp:"), "đường dẫn in ra dùng dấu /");
}

void const_move_only_calls(Context& context) {
    int value = 0;
    const core::MoveOnlyFunction<int() const> call([&value] { return ++value; });
    context.expect(static_cast<bool>(call), "chữ ký const dựng được");
    context.expect(call() == 1, "lời gọi const chạy lambda");
    const core::MoveOnlyFunction<int() const> empty;
    context.expect(!empty, "chữ ký const mặc định là rỗng");
}

// Chuỗi và số mong đợi của parse_whole_int; nullopt là chuỗi bị từ chối.
struct WholeCase {
    std::string_view text;
    std::optional<int> wanted;
};

constexpr std::array kWholeCases{
    WholeCase{.text = "0", .wanted = 0},
    WholeCase{.text = "251", .wanted = 251},
    WholeCase{.text = "2147483647", .wanted = std::numeric_limits<int>::max()},
    WholeCase{.text = "2147483648", .wanted = std::nullopt},
    WholeCase{.text = "4294967296", .wanted = std::nullopt},
    WholeCase{.text = "", .wanted = std::nullopt},
    WholeCase{.text = "12a", .wanted = std::nullopt},
    WholeCase{.text = " 12", .wanted = std::nullopt},
    WholeCase{.text = "+12", .wanted = std::nullopt},
    WholeCase{.text = "-1", .wanted = std::nullopt},
    WholeCase{.text = "1.0", .wanted = std::nullopt},
};

void whole_int_takes_the_entire_text(Context& context) noexcept {
    for (const WholeCase& item : kWholeCases)
        context.expect(core::parse_whole_int(item.text) == item.wanted, item.text);
}

// bytes + (page_size - 1) tràn uint64 khi bytes gần max: phép cộng quấn làm số trang tính ra 0.
// Yêu cầu khổng lồ phải invalid, yêu cầu nhỏ vẫn được.
void page_allocator_rejects_huge_request(Context& context) {
    core::PageAllocator alloc(1024ULL * 1024ULL, 4096);
    context.expect(!alloc.allocate(0).valid(), "0 byte không cấp");
    constexpr std::uint64_t huge = (std::numeric_limits<std::uint64_t>::max)();
    context.expect(!alloc.allocate(huge).valid(), "bytes gần max không quấn thành đoạn nhỏ");
    context.expect(!alloc.allocate(huge - 4096).valid(), "bytes tràn phép cộng cũng từ chối");
    context.expect(alloc.allocate(1).valid(), "1 byte vẫn được một trang");
}

constexpr std::array kCases{
    Case{.name = "text_round_trips_utf8_and_utf16", .body = &text_round_trips_utf8_and_utf16},
    Case{.name = "utf8_cut_keeps_whole_characters", .body = &utf8_cut_keeps_whole_characters},
    Case{.name = "utf8_validation_follows_rfc_3629", .body = &utf8_validation_follows_rfc_3629},
    Case{.name = "utf8_step_reads_one_character", .body = &utf8_step_reads_one_character},
    Case{.name = "error_keeps_code_message_and_place", .body = &error_keeps_code_message_and_place},
    Case{.name = "error_detail_outgrows_inline", .body = &error_detail_outgrows_inline},
    Case{.name = "error_maps_and_prints_system_codes", .body = &error_maps_and_prints_system_codes},
    Case{.name = "const_move_only_calls", .body = &const_move_only_calls},
    Case{.name = "whole_int_takes_the_entire_text", .body = &whole_int_takes_the_entire_text},
    Case{.name = "page_allocator_rejects_huge_request", .body = &page_allocator_rejects_huge_request},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "core_tests: mọi ca phải qua");
    return 0;
}
