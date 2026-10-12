#pragma once
// Cấu hình tạm cho test chạy exe thật của máy chủ: bản chép của SERVER/config nằm cạnh exe test.
// Trong bản chép, gate nghe 127.0.0.1 ở cổng 0 và mọi [[process]] của cluster.toml khai cổng 0: hệ
// điều hành cấp cổng lúc nghe, tiến trình báo cổng thật ở dòng `ready` (mục 3.1 của
// docs/KE-HOACH-SERVER.md), nên hai lượt test chạy cùng lúc không bao giờ tranh cổng. Khoá danh
// tính sinh trong cây dựng.
// Vì sao không đưa thẳng cấu hình thật cho tiến trình sẽ nghe cổng: cấu hình thật cho gate nghe mọi
// địa chỉ ở cổng cố định. Hai lượt ctest chạy cùng lúc sẽ tranh cổng, Windows thêm rule tường lửa
// cho từng đường dẫn exe của cây dựng, và khoá danh tính bị ghi vào SERVER/data của cây nguồn.

#include "io/file.hpp"
#include "io/platform.hpp"
#include "support/gate_key.hpp"

#include <cstddef>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>

namespace game::test {

// Địa chỉ nghe của mọi cổng trong cấu hình tạm: loopback, cổng do hệ điều hành cấp.
inline constexpr std::string_view kLoopbackAny = "127.0.0.1:0";

// Khoá `key` đứng đầu dòng, theo sau là dấu cách hoặc dấu bằng.
[[nodiscard]] inline bool has_key(std::string_view line, std::string_view key) noexcept {
    if (!line.starts_with(key)) return false;
    const std::string_view rest = line.substr(key.size());
    return rest.starts_with(' ') || rest.starts_with('=');
}

// Giá trị trong cặp nháy đầu tiên của dòng; rỗng khi dòng không có đủ hai dấu nháy.
[[nodiscard]] inline std::optional<std::string_view> quoted_value(std::string_view line) noexcept {
    const std::size_t open = line.find('"');
    if (open == std::string_view::npos) return std::nullopt;
    const std::size_t close = line.find('"', open + 1);
    if (close == std::string_view::npos) return std::nullopt;
    return line.substr(open + 1, close - open - 1);
}

// Dòng `key = "..."` thành `key = "127.0.0.1:0"`, giữ nguyên phần còn lại của dòng. Dòng không có
// đủ hai dấu nháy thì trả rỗng.
[[nodiscard]] inline std::optional<std::string> with_loopback(std::string_view line) {
    const std::optional<std::string_view> value = quoted_value(line);
    if (!value) return std::nullopt;
    const std::size_t open = line.find('"');
    return std::format("{}{}{}", line.substr(0, open + 1), kLoopbackAny, line.substr(open + 1 + value->size()));
}

// Dòng `port = <số>` thành `port = 0`, giữ nguyên phần còn lại. Dòng không có số sau dấu bằng thì
// trả rỗng.
[[nodiscard]] inline std::optional<std::string> with_any_port(std::string_view line) {
    const std::size_t equals = line.find('=');
    if (equals == std::string_view::npos) return std::nullopt;
    const std::size_t first = line.find_first_not_of(' ', equals + 1);
    if (first == std::string_view::npos) return std::nullopt;
    const std::size_t after = line.find_first_not_of("0123456789", first);
    if (after == first) return std::nullopt;
    const std::string_view tail = after == std::string_view::npos ? std::string_view{} : line.substr(after);
    return std::format("{}0{}", line.substr(0, first), tail);
}

// Dòng kế tiếp của text (không kèm dấu xuống dòng); text bị cắt bỏ phần đã đọc.
[[nodiscard]] inline std::string_view take_line(std::string_view& text) noexcept {
    const std::size_t end = text.find('\n');
    const std::string_view line = text.substr(0, end);
    text.remove_prefix(end == std::string_view::npos ? text.size() : end + 1);
    return line;
}

// Chữ của gate.toml với hai dòng `game`, `auth` của bảng [listen] đổi sang 127.0.0.1:0. Rỗng khi
// không thấy đúng hai dòng đó: gate.toml đổi bố cục thì test đỏ, không lặng lẽ chạy tiếp với địa
// chỉ thật.
[[nodiscard]] inline std::optional<std::string> listen_on_loopback(std::string_view text) {
    std::string out;
    bool in_listen = false;
    int replaced = 0;
    while (!text.empty()) {
        const std::string_view line = take_line(text);
        if (line.starts_with('[')) in_listen = line.starts_with("[listen]");
        const bool is_address = in_listen && (has_key(line, "game") || has_key(line, "auth"));
        const std::optional<std::string> changed = is_address ? with_loopback(line) : std::nullopt;
        replaced += changed ? 1 : 0;
        out += changed ? std::string_view{*changed} : line;
        out += '\n';
    }
    if (replaced != 2) return std::nullopt;
    return out;
}

// Số đếm khi đổi cổng của các khối [[process]]: số khối, số khối nghe đúng 127.0.0.1, số dòng port
// đã đổi.
struct ProcessCount {
    int blocks = 0;
    int loopback = 0;
    int ports = 0;
};

// Chữ của cluster.toml với dòng `port` của mọi khối [[process]] đổi thành 0; bảng khác, kể cả
// [postgres], giữ nguyên. Rỗng khi không có khối nào, khi một khối không nghe đúng 127.0.0.1 (cổng
// 0 chỉ hợp lệ ở đó), hoặc khi số dòng port đã đổi khác số khối: lệch thì test đỏ, không chạy tiếp
// với cổng cố định của cấu hình thật.
[[nodiscard]] inline std::optional<std::string> processes_on_any_port(std::string_view text) {
    std::string out;
    bool in_process = false;
    ProcessCount count;
    while (!text.empty()) {
        const std::string_view line = take_line(text);
        if (line.starts_with('[')) in_process = line.starts_with("[[process]]");
        if (line.starts_with("[[process]]")) ++count.blocks;
        const bool is_host = in_process && has_key(line, "host");
        if (is_host && quoted_value(line) == std::string_view{"127.0.0.1"}) ++count.loopback;
        const bool is_port = in_process && has_key(line, "port");
        const std::optional<std::string> changed = is_port ? with_any_port(line) : std::nullopt;
        count.ports += changed ? 1 : 0;
        out += changed ? std::string_view{*changed} : line;
        out += '\n';
    }
    const bool is_whole = count.blocks > 0 && count.loopback == count.blocks && count.ports == count.blocks;
    if (!is_whole) return std::nullopt;
    return out;
}

// Nơi lấy và nơi đặt của một lần chép cấu hình; hai thư mục cùng kiểu nên đi theo tên.
struct TomlCopy {
    std::filesystem::path from;
    std::filesystem::path into;
};

// Chép mọi tệp .toml của `from` vào `into`, trừ tệp bí mật *.local.toml. false khi không đọc được
// thư mục nguồn hoặc một tệp chép hỏng.
[[nodiscard]] inline bool copy_public_toml(const TomlCopy& copy) {
    std::error_code error;
    std::filesystem::directory_iterator entry{copy.from, error};
    while (!error && entry != std::filesystem::directory_iterator{}) {
        const std::filesystem::path name = entry->path().filename();
        const std::string text = io::utf8_of(name);
        const bool is_wanted = text.ends_with(".toml") && !text.ends_with(".local.toml");
        if (is_wanted) std::filesystem::copy_file(entry->path(), copy.into / name, error);
        if (!error) entry.increment(error);
    }
    return !error;
}

// Xoá thư mục tạm cũ rồi dựng lại <root>/config và <root>/data/gate. Kiểm lỗi sau từng lệnh: lệnh
// sau không được xoá mất lỗi của lệnh trước (thư mục cũ bị khoá thì dừng ngay ở bước xoá).
[[nodiscard]] inline bool reset_stage(const std::filesystem::path& root) {
    std::error_code error;
    std::filesystem::remove_all(root, error);
    if (error) return false;
    std::filesystem::create_directories(root / "config", error);
    if (error) return false;
    std::filesystem::create_directories(root / "data" / "gate", error);
    return !error;
}

using Rewrite = std::optional<std::string> (*)(std::string_view);

// Đọc tệp, đưa chữ qua `change`, ghi đè. false khi không đọc được, `change` trả rỗng, hoặc ghi hỏng.
[[nodiscard]] inline bool rewrite_file(const std::filesystem::path& file, Rewrite change) {
    const io::TextResult text = io::read_text(file);
    if (!text) return false;
    const std::optional<std::string> changed = change(*text);
    if (!changed) return false;
    std::ofstream out{file, std::ios::binary | std::ios::trunc};
    out << *changed;
    out.close();
    return static_cast<bool>(out);
}

// Dựng <thư mục exe>/<name>/config từ thư mục cấu hình thật `source`, với mọi cổng nghe là
// 127.0.0.1:0; thư mục <name> cũ bị xoá trước. Trả thư mục để đưa cho --config: đường dẫn tương đối
// trong cấu hình (khoá danh tính, log) tính từ đó nên rơi vào <thư mục exe>/<name>, không rơi vào
// SERVER/ của cây nguồn. Rỗng khi một bước hỏng. Chưa sinh khoá danh tính: test nào chạy gate thì
// gọi thêm ensure_gate_identity với thư mục trả về. Cổng thật đọc ở dòng `ready`.
[[nodiscard]] inline std::optional<std::filesystem::path> stage_config(const std::filesystem::path& source,
    std::string_view name) {
    const std::filesystem::path root = io::executable_directory() / io::path_from_utf8(name);
    std::filesystem::path config = root / "config";
    if (!reset_stage(root)) return std::nullopt;
    if (!copy_public_toml({.from = source, .into = config})) return std::nullopt;
    if (!rewrite_file(config / "gate.toml", &listen_on_loopback)) return std::nullopt;
    if (!rewrite_file(config / "cluster.toml", &processes_on_any_port)) return std::nullopt;
    return config;
}

} // namespace game::test
