// Test của core::utf8_from_gbk: tên ảnh GBK của all.material giải ra đúng tên tệp UTF-8 trên mọi nền. Trên Windows mọi
// cặp byte và mọi byte đơn còn được so với MultiByteToWideChar(936), nguồn của bảng sinh.
#include "core/check.hpp"
#include "core/gbk.hpp"
#include "test.hpp"

#if defined(_WIN32)
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep

#include <stringapiset.h>
#endif

#include <array>
#include <cstddef>
#include <optional>
#include <string>
#include <string_view>

namespace game::test {
namespace {

void ascii_and_chinese_names_decode(Context& context) {
    context.expect(core::utf8_from_gbk("") == std::string(), "chuỗi rỗng ra rỗng");
    context.expect(core::utf8_from_gbk("Material/a_b.dds") == std::string("Material/a_b.dds"), "ASCII giữ nguyên");
    const std::string_view with_zero("a\0b", 3);
    context.expect(core::utf8_from_gbk(with_zero) == std::string(with_zero), "byte 0 là ASCII, không cắt chuỗi");
    // "0树木/树干01.dds" của all.material: 树 CA F7, 木 C4 BE, 干 B8 C9.
    const std::optional<std::string> tree = core::utf8_from_gbk("0\xCA\xF7\xC4\xBE/\xCA\xF7\xB8\xC9" "01.dds");
    context.expect(tree == std::string("0树木/树干01.dds"), "thư mục và tên chữ Hán giải ra UTF-8");
    context.expect(core::utf8_from_gbk("\x80") == std::string("€"), "byte đơn 0x80 là dấu euro như trang 936");
    context.expect(core::utf8_from_gbk("\xA1\xA1") == std::string("　"), "dấu cách toàn khổ");
}

void invalid_bytes_are_rejected(Context& context) {
    context.expect(!core::utf8_from_gbk("abc\xCA").has_value(), "byte đầu đứng cuối chuỗi là hỏng");
    context.expect(!core::utf8_from_gbk("\x81\x7F").has_value(), "đuôi 0x7F không thuộc GBK");
    context.expect(!core::utf8_from_gbk("\x81\x30").has_value(), "đuôi dưới 0x40 không thuộc GBK");
    context.expect(!core::utf8_from_gbk("\xFF").has_value(), "byte 0xFF không giải được");
    context.expect(!core::utf8_from_gbk("\xCA\xF7\xFF").has_value(), "một ký tự hỏng làm hỏng cả chuỗi");
}

#if defined(_WIN32)
// Kết quả của Windows cho cùng dãy byte: UTF-8, hoặc nullopt khi MultiByteToWideChar từ chối.
[[nodiscard]] std::optional<std::string> windows_936(std::string_view bytes) {
    const int size = static_cast<int>(bytes.size());
    std::array<wchar_t, 4> wide{};
    // data() đi kèm độ dài tường minh, không cần ký tự kết thúc; tidy không thấy tham số độ dài (STD-02).
    // NOLINTBEGIN(bugprone-suspicious-stringview-data-usage)
    const int count =
        MultiByteToWideChar(936, MB_ERR_INVALID_CHARS, bytes.data(), size, wide.data(), static_cast<int>(wide.size()));
    // NOLINTEND(bugprone-suspicious-stringview-data-usage)
    if (count <= 0) return std::nullopt;
    return core::narrow(std::wstring_view(wide.data(), static_cast<std::size_t>(count)));
}

// Số dãy (byte lead đứng một mình, rồi lead với từng byte đuôi) mà hai bên giải khác nhau.
[[nodiscard]] int mismatches_after(unsigned lead) {
    int wrong = 0;
    const std::array<char, 1> single{static_cast<char>(lead)};
    const std::string_view alone(single.data(), single.size());
    if (core::utf8_from_gbk(alone) != windows_936(alone)) ++wrong;
    for (unsigned trail = 0x00; trail <= 0xFF; ++trail) {
        const std::array<char, 2> pair{static_cast<char>(lead), static_cast<char>(trail)};
        const std::string_view both(pair.data(), pair.size());
        if (core::utf8_from_gbk(both) != windows_936(both)) ++wrong;
    }
    return wrong;
}

void table_matches_windows_936(Context& context) {
    int wrong = 0;
    for (unsigned lead = 0x80; lead <= 0xFF; ++lead) {
        wrong += mismatches_after(lead);
    }
    context.expect(wrong == 0, "mọi byte đơn và cặp byte giải giống MultiByteToWideChar(936)");
}
#endif

constexpr std::array kCases{
    Case{.name = "ascii_and_chinese_names_decode", .body = &ascii_and_chinese_names_decode},
    Case{.name = "invalid_bytes_are_rejected", .body = &invalid_bytes_are_rejected},
#if defined(_WIN32)
    Case{.name = "table_matches_windows_936", .body = &table_matches_windows_936},
#endif
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gbk_tests: mọi ca phải qua");
    return 0;
}
