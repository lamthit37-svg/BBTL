// Số vàng của thư viện chuẩn và máy ảo (ctest lua_golden_tests): chạy Test/golden/lua/lib_cases.lua trên game_luaplus (LuaPlus
// dựng từ third_party/luaplus) bằng C API như Game.exe (luaL_loadbuffer, lua_pcall), rồi so từng dòng __emit với cột kết quả của
// lib_cases.tsv. Hai tệp do TOOLS/port/lua_rt_golden.py sinh bằng cách chạy đúng chương trình ấy trên LuaPlus.dll của client
// 2026: gồm lời gọi thư viện chuẩn (base, string, table, math), thứ tự duyệt của mọi bảng thư viện, và phép toán của máy ảo
// (số học và ép chuỗi, `^` XOR, nối chuỗi, so sánh, metamethod, index/set trên mọi kiểu, call, for số, vararg, hàm dựng bảng).
// Mọi ca chạy trong CÙNG MỘT máy Lua theo đúng thứ tự (hạt math.random và đối tượng của setup_ops là trạng thái chung).
//
// Ca lệch nghĩa là bản dựng của dự án (trình dịch, cờ, CRT) làm hành vi khác máy gốc: sửa ở gốc (module luanum, hoặc chỗ vá
// "Khác gốc" của LuaPlus ghi ở third_party/luaplus/NGUON.txt), không nới so sánh. Ngoại lệ có chủ ý duy nhất: hàm toán lấy từ
// thư viện toán của máy dựng (sin, cos, ...) được lệch DLL tối đa một ulp ở giá trị `%.17g` sau dấu `~`; chuỗi tostring (14
// chữ số) vẫn phải khớp từng ký tự.
#include "io/file.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <format>
#include <memory>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

// Header của LuaPlus là mã C, không có extern "C".
extern "C" {
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
}

namespace game::test {
namespace {

#ifdef GAME_LUA_GOLDEN
constexpr std::string_view kGoldenFolder = GAME_LUA_GOLDEN;
#else
constexpr std::string_view kGoldenFolder;
#endif

// Dòng ngăn hai đoạn trong lib_cases.lua (MARKER của lua_rt_golden.py).
constexpr std::string_view kMarker = "-- ==== golden\n";
constexpr std::size_t kMaxReported = 40;

using Lines = std::vector<std::string>;

struct StateCloser {
    void operator()(lua_State* state) const noexcept { lua_close(state); }
};
using StatePtr = std::unique_ptr<lua_State, StateCloser>;

// __emit của chương trình số vàng: ghi chuỗi đối số đầu vào danh sách mà upvalue 1 trỏ tới.
int emit(lua_State* state) {
    auto* const lines = static_cast<Lines*>(lua_touserdata(state, lua_upvalueindex(1)));
    const char* const text = lua_tostring(state, 1);
    lines->emplace_back(text != nullptr ? std::string(text, lua_strlen(state, 1)) : std::string());
    return 0;
}

// Máy Lua như LuaPlus.dll của client 2026 dựng cho trọng tài: bốn thư viện chuẩn rồi __emit.
[[nodiscard]] StatePtr open_machine(Lines& lines) {
    StatePtr state(lua_open());
    lua_State* const raw = state.get();
    luaopen_base(raw);
    luaopen_string(raw);
    luaopen_table(raw);
    luaopen_math(raw);
    lua_settop(raw, 0);
    lua_pushstring(raw, "__emit");
    lua_pushlightuserdata(raw, &lines);
    lua_pushcclosure(raw, &emit, 1);
    lua_settable(raw, LUA_GLOBALSINDEX);
    return state;
}

// Nạp rồi chạy một đoạn; trả câu lỗi (rỗng khi thành công).
[[nodiscard]] std::string run_chunk(lua_State* state, std::string_view code, const char* name) {
    if (luaL_loadbuffer(state, code.data(), code.size(), name) == 0 && lua_pcall(state, 0, 0, 0) == 0) return {};
    const char* const message = lua_tostring(state, -1);
    std::string error = message != nullptr ? message : "?";
    lua_settop(state, 0);
    return error;
}

// ---- so kết quả ----

[[nodiscard]] bool tolerates_one_ulp(std::string_view id) {
    static constexpr std::array<std::string_view, 11> kNames = {
        "math.sin#", "math.cos#", "math.tan#", "math.asin#", "math.acos#", "math.atan#", "math.atan2#", "math.exp#", "math.log#",
        "math.log10#", "math.pow#"};
    return std::ranges::any_of(kNames, [&](std::string_view name) { return id.starts_with(name); });
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hai chuỗi số cùng vai, thứ tự không có nghĩa (so đối xứng).
[[nodiscard]] bool within_one_ulp(std::string_view want, std::string_view got) {
    double a = 0.0;
    double b = 0.0;
    const char* const want_end = std::to_address(want.end());
    const char* const got_end = std::to_address(got.end());
    const auto [pa, ea] = std::from_chars(std::to_address(want.begin()), want_end, a);
    const auto [pb, eb] = std::from_chars(std::to_address(got.begin()), got_end, b);
    if (ea != std::errc() || eb != std::errc() || pa != want_end || pb != got_end) return false;
    if (std::signbit(a) != std::signbit(b)) return a == b;
    const auto bits_a = std::bit_cast<std::int64_t>(a);
    const auto bits_b = std::bit_cast<std::int64_t>(b);
    const std::int64_t gap = bits_a > bits_b ? bits_a - bits_b : bits_b - bits_a;
    return gap <= 1;
}

// Hai dòng kết quả giống nhau, trừ các số sau dấu `~` (dấu `~` nằm trong chuỗi ngoặc kép không tính).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hai dòng cùng vai.
[[nodiscard]] bool equal_up_to_ulp(std::string_view want, std::string_view got) {
    constexpr std::string_view kEnd = ",)]};=| ";
    std::size_t i = 0;
    std::size_t j = 0;
    bool quoted = false;
    while (i < want.size() && j < got.size()) {
        if (want[i] != got[j]) return false;
        const char letter = want[i];
        ++i;
        ++j;
        if (letter == '"') quoted = !quoted;
        if (letter != '~' || quoted) continue;
        const std::size_t stop_a = std::min(want.find_first_of(kEnd, i), want.size());
        const std::size_t stop_b = std::min(got.find_first_of(kEnd, j), got.size());
        const std::string_view token_a = want.substr(i, stop_a - i);
        const std::string_view token_b = got.substr(j, stop_b - j);
        if (token_a != token_b && !within_one_ulp(token_a, token_b)) return false;
        i = stop_a;
        j = stop_b;
    }
    return i == want.size() && j == got.size();
}

// Một dòng của .tsv: id và dòng mà __emit phải ghi cho ca đó (`globals-order` ghi nguyên dòng; ca khác ghi id, tab, cột kết quả).
struct Row {
    std::string_view id;
    std::string expected;
};

[[nodiscard]] std::vector<Row> parse_rows(std::string_view text) {
    std::vector<Row> rows;
    std::size_t start = 0;
    while (start < text.size()) {
        const std::size_t stop = std::min(text.find('\n', start), text.size());
        std::string_view line = text.substr(start, stop - start);
        start = stop + 1;
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty() || line.starts_with('#')) continue;
        const std::size_t first = line.find('\t');
        if (first == std::string_view::npos) continue;
        const std::string_view id = line.substr(0, first);
        if (id == "globals-order") {
            rows.push_back({.id = id, .expected = std::string(line)});
            continue;
        }
        // id, đường dẫn, đối số, kết quả: kết quả là phần sau tab thứ ba (không chứa tab: PRELUDE đã thoát ký tự điều khiển).
        std::size_t cut = first;
        for (int skipped = 0; skipped < 2 && cut != std::string_view::npos; ++skipped) cut = line.find('\t', cut + 1);
        if (cut == std::string_view::npos) continue;
        rows.push_back({.id = id, .expected = std::format("{}\t{}", id, line.substr(cut + 1))});
    }
    return rows;
}

void library_matches_luaplus(Context& context) {
    if (kGoldenFolder.empty()) return; // thiết bị không thấy cây nguồn: không có số vàng để so
    const std::filesystem::path folder = io::path_from_utf8(kGoldenFolder);
    const io::TextResult table = io::read_text(folder / io::path_from_utf8("lib_cases.tsv"));
    const io::TextResult program = io::read_text(folder / io::path_from_utf8("lib_cases.lua"));
    context.expect(table.has_value(), "đọc được lib_cases.tsv");
    context.expect(program.has_value(), "đọc được lib_cases.lua");
    if (!table || !program) return;
    const std::size_t marker = program->find(kMarker);
    context.expect(marker != std::string::npos, "lib_cases.lua có dòng ngăn hai đoạn");
    if (marker == std::string::npos) return;

    Lines lines;
    const StatePtr state = open_machine(lines);
    const std::string first_error = run_chunk(state.get(), std::string_view(*program).substr(0, marker), "=golden-first");
    context.expect(first_error.empty(), std::format("đoạn golden-first chạy được: {}", first_error));
    const std::string main_error =
        run_chunk(state.get(), std::string_view(*program).substr(marker + kMarker.size()), "=golden");
    context.expect(main_error.empty(), std::format("đoạn golden chạy được: {}", main_error));

    const std::vector<Row> rows = parse_rows(*table);
    context.expect(rows.size() > 10000, "đủ ca");
    context.expect(lines.size() == rows.size(), std::format("số dòng __emit {} khác số ca {}", lines.size(), rows.size()));
    std::size_t mismatches = 0;
    for (std::size_t index = 0; index < std::min(lines.size(), rows.size()); ++index) {
        const Row& row = rows[index];
        const std::string& got = lines[index];
        if (got == row.expected || (tolerates_one_ulp(row.id) && equal_up_to_ulp(row.expected, got))) continue;
        ++mismatches;
        if (mismatches <= kMaxReported)
            context.expect(false, std::format("{}\n  muốn: {}\n  được: {}", row.id, row.expected.substr(0, 400), got.substr(0, 400)));
    }
    context.expect(mismatches == 0, std::format("{} ca lệch trên {}", mismatches, rows.size()));
}

constexpr std::array<Case, 1> kCases = {{{.name = "thư viện chuẩn và phép toán máy ảo khớp LuaPlus.dll", .body = &library_matches_luaplus}}};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
