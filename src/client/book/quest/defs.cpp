/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/book/quest/defs.cpp
 *  PHÂN HỆ   : Client / Sổ sách / Nhiệm vụ
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ đọc Script.dat (Game.exe 0x1406865b0) và kho bản ghi nhiệm vụ nạp trễ.
 *  - Tệp event là UTF-8 (gốc GBK); phần đọc khối MisDesc ở misdesc.cpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "quest/defs.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <map>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::quest {
namespace {

constexpr std::string_view kHeader = "MGR_TXT";
constexpr std::string_view kBlanks = " \t";
constexpr char kComment = ';';

[[nodiscard]] bool same_ignoring_case(std::string_view left, std::string_view right) noexcept {
    const auto lower = [](char letter) {
        return (letter >= 'A' && letter <= 'Z') ? static_cast<char>(letter - 'A' + 'a') : letter;
    };
    return std::ranges::equal(left, right, {}, lower, lower);
}

[[nodiscard]] std::string_view trimmed(std::string_view line) noexcept {
    const std::size_t first = line.find_first_not_of(kBlanks);
    if (first == std::string_view::npos) return {};
    const std::size_t last = line.find_last_not_of(kBlanks);
    return line.substr(first, last - first + 1);
}

// atoi của C trên số thập phân dương: dừng ở chữ không phải số; tràn thì kẹp về trần int32.
[[nodiscard]] std::int32_t c_atoi(std::string_view text) noexcept {
    constexpr std::int64_t kCap = std::numeric_limits<std::int32_t>::max();
    std::int64_t value = 0;
    for (const char letter : text) {
        if (letter < '0' || letter > '9') break;
        value = std::min((value * 10) + (letter - '0'), kCap);
    }
    return static_cast<std::int32_t>(value);
}

[[nodiscard]] std::string normal_path(std::string_view raw) {
    std::string path(raw);
    std::ranges::replace(path, '\\', '/');
    const std::size_t first = path.find_first_not_of('/');
    if (first == std::string::npos) return {};
    return path.substr(first);
}

// Dòng kế của văn bản (không có "\r\n"), đã cắt trắng hai đầu; đẩy from qua dấu xuống dòng.
// Script.dat của client là CRLF mà gốc vẫn nạp được (bộ lấy dòng TDU_GetLineFromMemory nằm trong
// DLL, chưa đọc mã), nên '\r' cuối dòng không được vào đường dẫn.
[[nodiscard]] std::string_view take_line(std::string_view text, std::size_t& from) noexcept {
    const std::size_t stop = std::min(text.find('\n', from), text.size());
    std::string_view line = text.substr(from, stop - from);
    from = stop + 1;
    if (line.ends_with('\r')) line.remove_suffix(1);
    return trimmed(line);
}

// Dòng "id=đường dẫn"; dòng không có '=' bị bỏ.
void add_entry(ScriptIndex& index, std::string_view line) {
    const std::size_t equals = line.find('=');
    if (equals == std::string_view::npos) return;
    const std::int32_t script = c_atoi(line.substr(0, equals));
    const std::string path = normal_path(line.substr(equals + 1));
    index.insert_or_assign(script, path);
}

} // namespace

std::expected<ScriptIndex, std::string> parse_script_index(std::string_view text) {
    ScriptIndex index;
    bool has_header = false;
    std::size_t from = 0;
    while (from < text.size()) {
        const std::string_view line = take_line(text, from);
        const bool is_skipped = line.empty() || line.front() == kComment;
        if (is_skipped) continue;
        if (has_header) add_entry(index, line);
        if (!has_header) has_header = same_ignoring_case(line, kHeader);
    }
    if (!has_header) return std::unexpected("Script.dat không có dòng MGR_TXT");
    return index;
}

DefBook::DefBook(ScriptIndex index, FileReader reader)
    : index_(std::move(index)), reader_(std::move(reader)) {}

const MissionDef& DefBook::find(std::int32_t script) const {
    static const MissionDef kFresh{};
    const auto found = entries_.find(script);
    if (found == entries_.end()) return kFresh;
    return found->second.def;
}

void DefBook::load(std::int32_t script) {
    Entry& entry = entries_[script];
    if (entry.is_done) return;
    entry.is_done = true;
    const auto path = index_.find(script);
    if (path == index_.end()) {
        notes_.push_back(std::format("script {} không có trong Script.dat", script));
        return;
    }
    const std::optional<std::string> text = reader_ ? reader_(path->second) : std::nullopt;
    if (!text) {
        notes_.push_back(std::format("script {}: không đọc được {}", script, path->second));
        return;
    }
    std::expected<MissionDef, std::string> parsed = parse_misdesc(*text);
    if (!parsed) {
        notes_.push_back(std::format("script {}: {} ({})", script, parsed.error(), path->second));
        return;
    }
    entry.def = std::move(*parsed);
}

std::vector<std::string> DefBook::take_notes() {
    return std::exchange(notes_, {});
}

} // namespace game::quest
