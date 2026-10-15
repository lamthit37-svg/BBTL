// thienlong_lua_mass — đối soát hàng loạt LUA-GEN: chạy mọi đơn vị do bộ dịch sinh trên runtime lua và so vết với vết
// LuaPlus.dll mà TOOLS/port/luagen/mass_oracle.py ghi (docs/giao-viec/LUA-GEN/THIET-KE.md).
//   thienlong_lua_mass --summary <oracle.tsv> [--oracle-traces <thư mục>] [--dump <thư mục>] [--only <đơn vị>...]
// --summary: bảng unit/status/lines/sha256 của trọng tài (Test/golden/lua_mass/oracle.tsv). --oracle-traces: thư mục
// <đơn vị>.trace của trọng tài; có thì in dòng lệch đầu tiên của mỗi đơn vị lệch. --dump: ghi vết của phía này.
// Đơn vị mà trọng tài báo timeout bị bỏ qua: vết gốc của nó dừng ở chỗ hết ngân sách lệnh của móc đếm, phía này không
// có móc ấy (THIET-KE, "Khác gốc"). Mã thoát: 0 mọi đơn vị khớp, 1 có lệch hay lỗi dữ liệu, 2 cách dùng.
#include "io/file.hpp"
#include "io/platform.hpp"
#include "lua/vm.hpp"
#include "luagen/units.hpp"
#include "luamass/trace.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <functional>
#include <ios>
#include <memory>
#include <map>
#include <print>
#include <ranges>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace {

namespace io = game::io;

constexpr std::string_view kUsage =
    "cách dùng: thienlong_lua_mass --summary <oracle.tsv> [--oracle-traces <thư mục>] [--dump <thư mục>]"
    " [--only <đơn vị>...]";

// Dòng lệch in tối đa chừng này byte mỗi phía, đủ nhận ra lời gọi mà không làm tràn console.
constexpr std::size_t kShownBytes = 240;

struct Request {
    std::string summary;
    std::string oracle_traces;
    std::string dump;
    std::set<std::string, std::less<>> only;
};

// Một dòng của bảng trọng tài.
struct Expected {
    bool is_timeout = false;
    std::uint64_t lines = 0;
    std::string sha256;
};

using Table = std::map<std::string, Expected, std::less<>>;

[[nodiscard]] int fail_usage(std::string_view message) {
    std::println(stderr, "thienlong_lua_mass: {}\n{}", message, kUsage);
    return 2;
}

[[nodiscard]] bool parse_request(std::span<const std::string> args, Request& request) {
    std::size_t index = 0;
    while (index < args.size()) {
        const std::string_view flag = args[index];
        if (flag == "--only") {
            ++index;
            while (index < args.size() && !args[index].starts_with("--")) request.only.insert(args[index++]);
            continue;
        }
        if (index + 1 >= args.size()) return false;
        const std::string& value = args[index + 1];
        if (flag == "--summary")
            request.summary = value;
        else if (flag == "--oracle-traces")
            request.oracle_traces = value;
        else if (flag == "--dump")
            request.dump = value;
        else
            return false;
        index += 2;
    }
    return !request.summary.empty();
}

[[nodiscard]] bool is_sha256_hex(std::string_view text) {
    constexpr std::size_t kHexDigits = 64;
    return text.size() == kHexDigits &&
           std::ranges::all_of(text, [](char one) { return (one >= '0' && one <= '9') || (one >= 'a' && one <= 'f'); });
}

// Bảng của mass_oracle.py: dòng chú thích "#", dòng tên cột, rồi unit<TAB>status<TAB>lines<TAB>sha256. Tệp nằm ngoài mã
// nên mọi dòng hỏng là lỗi dữ liệu có số dòng, không check.
[[nodiscard]] bool parse_table(std::string_view text, Table& table) {
    std::size_t number = 0;
    for (const auto range : text | std::views::split('\n')) {
        ++number;
        std::string_view line(range.begin(), range.end());
        if (line.ends_with('\r')) line.remove_suffix(1);
        if (line.empty() || line.starts_with('#') || line.starts_with("unit\t")) continue;
        std::array<std::string_view, 4> fields{};
        std::size_t count = 0;
        for (const auto field : line | std::views::split('\t')) {
            if (count == fields.size()) {
                count = fields.size() + 1;
                break;
            }
            fields.at(count++) = std::string_view(field.begin(), field.end());
        }
        Expected row{.is_timeout = fields[1] == "timeout", .lines = 0, .sha256 = std::string(fields[3])};
        const char* const last = std::to_address(fields[2].end());
        const auto [end, error] = std::from_chars(std::to_address(fields[2].begin()), last, row.lines);
        const bool is_status = fields[1] == "ok" || row.is_timeout;
        const bool is_number = !fields[2].empty() && error == std::errc{} && end == last;
        if (count != fields.size() || fields[0].empty() || !is_status || !is_number || !is_sha256_hex(fields[3]) ||
            !table.try_emplace(std::string(fields[0]), std::move(row)).second) {
            std::println(stderr, "thienlong_lua_mass: bảng trọng tài hỏng ở dòng {}", number);
            return false;
        }
    }
    return true;
}

[[nodiscard]] std::string sha256_hex(std::string_view bytes) {
    std::array<std::byte, 32> digest{};
    const bool hashed = game::secure::sha256(std::as_bytes(std::span(bytes)), digest);
    return hashed ? game::secure::hex_encode(digest) : std::string();
}

[[nodiscard]] std::string_view shown(std::string_view line) { return line.substr(0, kShownBytes); }

// Dòng đầu tiên khác nhau giữa vết gốc và vết của phía này (đánh số từ 1).
void print_first_difference(std::string_view oracle, std::string_view ours) {
    std::size_t number = 1;
    while (!oracle.empty() || !ours.empty()) {
        const std::string_view left = oracle.substr(0, oracle.find('\n'));
        const std::string_view right = ours.substr(0, ours.find('\n'));
        if (left != right || oracle.empty() != ours.empty()) {
            std::println("  dòng {}:\n    gốc: {}\n    ta:  {}", number, oracle.empty() ? "<hết>" : shown(left),
                         ours.empty() ? "<hết>" : shown(right));
            return;
        }
        oracle.remove_prefix(std::min(oracle.size(), left.size() + 1));
        ours.remove_prefix(std::min(ours.size(), right.size() + 1));
        ++number;
    }
}

[[nodiscard]] std::filesystem::path trace_path(const std::filesystem::path& folder, std::string_view unit) {
    return folder / io::path_from_utf8(std::string(unit).append(".trace"));
}

[[nodiscard]] bool write_trace(const std::filesystem::path& file, std::string_view bytes) {
    std::ofstream out(file, std::ios::binary);
    out.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
    out.close();
    return !out.fail();
}

struct Counts {
    std::size_t matched = 0;
    std::size_t differed = 0;
    std::size_t skipped = 0;
    std::size_t unknown = 0;
};

} // namespace

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
int main(const int argc, const char* const* const argv) {
    io::use_utf8_console();
    const std::vector<std::string> args = io::command_arguments(argc, argv);
    Request request;
    if (!parse_request(args, request)) return fail_usage("đối số sai");
    const io::TextResult summary = io::read_text(io::path_from_utf8(request.summary));
    if (!summary) {
        std::println(stderr, "thienlong_lua_mass: {}: {}", request.summary, io::describe(summary.error()));
        return 1;
    }
    Table table;
    if (!parse_table(*summary, table)) return 1;
    const std::filesystem::path dump = io::path_from_utf8(request.dump);
    if (!request.dump.empty()) {
        std::error_code error;
        std::filesystem::create_directories(dump, error);
        if (error) {
            std::println(stderr, "thienlong_lua_mass: không tạo được {}: {}", request.dump, error.message());
            return 1;
        }
    }
    const game::lua::Chunk& world = game::lua::gen::world();
    Counts counts;
    std::set<std::string_view, std::less<>> seen;
    for (const game::lua::gen::UnitEntry& entry : game::lua::gen::units()) {
        if (!request.only.empty() && !request.only.contains(entry.name)) continue;
        seen.insert(entry.name);
        const auto row = table.find(entry.name);
        if (row == table.end()) {
            std::println("thiếu ở trọng tài: {}", entry.name);
            ++counts.unknown;
            continue;
        }
        if (row->second.is_timeout) {
            ++counts.skipped;
            continue;
        }
        const std::string bytes = game::luamass::trace_unit({.name = entry.name, .chunks = entry.chunks}, world);
        if (!request.dump.empty() && !write_trace(trace_path(dump, entry.name), bytes)) {
            std::println(stderr, "thienlong_lua_mass: không ghi được vết của {}", entry.name);
            return 1;
        }
        if (sha256_hex(bytes) == row->second.sha256) {
            ++counts.matched;
            continue;
        }
        ++counts.differed;
        std::println("lệch {}: {} dòng, gốc {} dòng", entry.name, std::ranges::count(bytes, '\n'), row->second.lines);
        if (request.oracle_traces.empty()) continue;
        const io::TextResult oracle = io::read_text(trace_path(io::path_from_utf8(request.oracle_traces), entry.name));
        if (oracle)
            print_first_difference(*oracle, bytes);
        else
            std::println("  không đọc được vết gốc: {}", io::describe(oracle.error()));
    }
    // Đơn vị trọng tài có mà bộ dịch không sinh là lệch danh sách (mass_units.py và bộ dịch phải cùng một danh sách).
    for (const auto& [name, row] : table) {
        if ((request.only.empty() || request.only.contains(name)) && !seen.contains(name)) {
            std::println("thiếu ở mã sinh: {}", name);
            ++counts.unknown;
        }
    }
    std::println("khớp {}, lệch {}, bỏ qua (gốc timeout) {}, thiếu {}", counts.matched, counts.differed,
                 counts.skipped, counts.unknown);
    return counts.differed == 0 && counts.unknown == 0 ? 0 : 1;
}
