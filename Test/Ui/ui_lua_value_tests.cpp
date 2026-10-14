// Chuyển số của script (ui/panel/lua_value) so với chính LuaPlus.dll của client 2026
// (Test/golden/panel/lua_number_cases.tsv, sinh bằng TOOLS/port/lua_oracle.py với kịch bản
// TOOLS/port/oracle/lua_number_cases.lua), và cách đọc "TÊN|arg0|arg1|..." của sự kiện giao diện
// (ui/panel/events).
#include "ui/panel/lua_value.hpp"

#include "core/check.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <charconv>
#include <cstddef>
#include <cstdlib>
#include <format>
#include <limits>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

namespace game::test {
namespace {

constexpr std::string_view kNumberFile = "lua_number_cases.tsv";

// Một dòng của lua_number_cases.tsv: loại, đầu vào và kết quả.
struct NumberCase {
    std::string_view kind;
    std::string_view input;
    std::string_view result;
};

std::optional<NumberCase> parse_case(std::string_view line) {
    const std::size_t first = line.find('\t');
    const std::size_t second = first == std::string_view::npos ? first : line.find('\t', first + 1);
    if (second == std::string_view::npos) return std::nullopt;
    return NumberCase{
        .kind = line.substr(0, first), .input = line.substr(first + 1, second - first - 1), .result = line.substr(second + 1)};
}

// Các byte của chuỗi đầu vào, ghi dạng hex hai chữ số mỗi byte.
std::string bytes_of(std::string_view hex) {
    std::string out;
    out.reserve(hex.size() / 2);
    for (std::size_t at = 0; at + 1 < hex.size(); at += 2) {
        unsigned value = 0;
        const std::string_view pair = hex.substr(at, 2);
        const std::from_chars_result done = std::from_chars(std::to_address(pair.begin()), std::to_address(pair.end()), value, 16);
        core::check(done.ec == std::errc{}, "số vàng ghi byte đầu vào bằng hex");
        out.push_back(static_cast<char>(value));
    }
    return out;
}

// Số mà trọng tài ghi bằng %.17g, hay một trong ba từ inf, -inf, nan (nan của trọng tài mang dấu âm).
double number_of(std::string_view token) {
    if (token == "inf") return std::numeric_limits<double>::infinity();
    if (token == "-inf") return -std::numeric_limits<double>::infinity();
    if (token == "nan") return -std::numeric_limits<double>::quiet_NaN();
    const std::string owned(token);
    return std::strtod(owned.c_str(), nullptr);
}

void number_conversions_match_luaplus(Context& context) {
    if (kPanelGolden.empty()) return;
    const std::vector<GoldenBlock> blocks = read_golden(kNumberFile);
    context.expect(blocks.size() == 1, "số vàng có một khối");
    if (blocks.size() != 1) return;
    std::size_t cases = 0;
    for (const std::string& line : blocks.front().lines) {
        const std::optional<NumberCase> one = parse_case(line);
        context.expect(one.has_value(), "dòng số vàng đủ ba cột");
        if (!one) continue;
        ++cases;
        if (one->kind == "tonumber") {
            const std::string input = bytes_of(one->input);
            const std::optional<double> value = ui::panel::lua_tonumber(input);
            const std::string got = value ? ui::panel::lua_tostring(*value) : std::string("nil");
            context.expect(got == one->result, std::format("tonumber({}) ra {} đáng ra {}", one->input, got, one->result));
        } else {
            const std::string got = ui::panel::lua_tostring(number_of(one->input));
            context.expect(got == one->result, std::format("tostring({}) ra {} đáng ra {}", one->input, got, one->result));
        }
    }
    context.expect(cases > 90, "đọc đủ các ca của số vàng");
}

// "TÊN|a0|a1|...": số đối số tuỳ ý, đối số rỗng là chuỗi rỗng, tên rỗng không hợp lệ.
void posted_event_parses_arguments(Context& context) {
    const std::optional<ui::panel::PostedEvent> bare = ui::panel::PostedEvent::parse("PROGRESSBAR_BREAK");
    context.expect(bare.has_value() && bare->name == "PROGRESSBAR_BREAK" && bare->args.empty(), "chỉ có tên");
    const std::optional<ui::panel::PostedEvent> many = ui::panel::PostedEvent::parse("X|a||c|d|e|f");
    context.expect(many.has_value() && many->args.size() == 6, "sáu đối số, không giới hạn bốn");
    if (many && many->args.size() == 6) {
        context.expect(many->args.at(1).empty() && many->args.at(5) == "f", "đối số rỗng giữ chỗ");
        const std::vector<std::string_view> seen = many->arguments();
        context.expect(seen.size() == 6 && seen.at(0) == "a" && seen.at(2) == "c", "dạng mượn chuỗi");
    }
    const std::optional<ui::panel::PostedEvent> tail = ui::panel::PostedEvent::parse("X|");
    context.expect(tail.has_value() && tail->args.size() == 1 && tail->args.at(0).empty(), "dấu | cuối là một đối số rỗng");
    context.expect(!ui::panel::PostedEvent::parse("").has_value(), "rỗng không hợp lệ");
    context.expect(!ui::panel::PostedEvent::parse("|a").has_value(), "tên rỗng không hợp lệ");
}

// arg<k> dùng chung: đối số mới ghi đè, đối số không nêu giữ giá trị cũ (bộ gửi gốc không xoá giữa hai sự kiện).
void shared_arguments_persist(Context& context) {
    ui::panel::EventArgs args;
    const std::vector<std::string_view> first = {"a", "b", "c"};
    const ui::panel::UiEvent one = args.raise("E1", first);
    context.expect(one.arg(0) == "a" && one.arg(2) == "c" && one.table(1) == "a", "arg<k> và eventTable[k+1]");
    context.expect(!one.arg(3).has_value() && !one.table(0).has_value(), "ngoài kho là nil");
    const std::vector<std::string_view> second = {"x"};
    const ui::panel::UiEvent two = args.raise("E2", second);
    context.expect(two.arg(0) == "x" && two.arg(1) == "b" && two.arg(2) == "c", "đối số không nêu giữ giá trị cũ");
}

constexpr std::array kCases{
    Case{.name = "number_conversions_match_luaplus", .body = &number_conversions_match_luaplus},
    Case{.name = "posted_event_parses_arguments", .body = &posted_event_parses_arguments},
    Case{.name = "shared_arguments_persist", .body = &shared_arguments_persist},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_lua_value_tests: mọi ca phải qua");
    return 0;
}
