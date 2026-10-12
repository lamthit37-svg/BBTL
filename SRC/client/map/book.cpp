#include "client/map/book.hpp"

#include "core/number.hpp"

#include <algorithm>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::client::map {
namespace {

// Tên cảnh và tên tệp dài nhất nhận được: name_len và file_len của SceneRef là 16 bit.
constexpr std::size_t kMaxCellBytes = std::numeric_limits<decltype(SceneRef::name_len)>::max();

struct Cells {
    std::string_view one;
    std::string_view two;
    std::string_view three;
    std::string_view four;
    std::string_view five;
    // Cột thứ 6: tệp lưới đi (.path); rỗng khi dòng ngắn hơn.
    std::string_view six;
    // Cột thứ 11 (szSceneMap); rỗng khi dòng ngắn hơn.
    std::string_view radar;
    // Cột thứ 16 và 17: mặt cắt xa và gần của camera; rỗng khi dòng ngắn hơn.
    std::string_view far_clip;
    std::string_view near_clip;
    bool is_ready = false;
};

// Số cột nằm giữa tệp lưới đi (cột thứ 6) và token minimap (cột thứ 11), rồi giữa token đó và
// mặt cắt xa (cột thứ 16).
constexpr int kCellsBeforeRadar = 4;
constexpr int kCellsBeforeClip = 4;

struct Seen {
    int id = 0;
    bool has = false;
};

[[nodiscard]] bool is_file_name(std::string_view name) noexcept {
    if (name.empty() || name == "." || name == "..") return false;
    return !name.contains('/') && !name.contains('\\');
}

[[nodiscard]] char lower_ascii(char letter) noexcept {
    const auto code = static_cast<unsigned char>(letter);
    if (std::isupper(code) == 0) return letter;
    return static_cast<char>(std::tolower(code));
}

[[nodiscard]] bool letters_match(std::string_view left, std::string_view right, std::size_t index) noexcept {
    return lower_ascii(left[index]) == lower_ascii(right[index]);
}

[[nodiscard]] bool same_ascii(std::string_view left, std::string_view right) noexcept {
    if (left.size() != right.size()) return false;
    bool is_same = true;
    for (std::size_t index = 0; index < left.size(); ++index) {
        is_same = is_same && letters_match(left, right, index);
    }
    return is_same;
}

[[nodiscard]] std::string_view stem_of(std::string_view file) noexcept {
    const std::size_t dot = file.rfind('.');
    if (dot == std::string_view::npos) return file;
    return file.substr(0, dot);
}

struct Cursor {
    std::string_view rest;
    bool is_done = false;
};

[[nodiscard]] std::string_view next_cell(Cursor& cursor) noexcept {
    if (cursor.is_done) return {};
    const std::size_t tab = cursor.rest.find('\t');
    if (tab == std::string_view::npos) {
        const std::string_view cell = cursor.rest;
        cursor.rest = {};
        cursor.is_done = true;
        return cell;
    }
    const std::string_view cell = cursor.rest.substr(0, tab);
    cursor.rest.remove_prefix(tab + 1);
    return cell;
}

[[nodiscard]] Cells take_cells(std::string_view line) noexcept {
    Cursor cursor{.rest = line};
    Cells cells;
    cells.one = next_cell(cursor);
    cells.two = next_cell(cursor);
    cells.three = next_cell(cursor);
    cells.four = next_cell(cursor);
    cells.five = next_cell(cursor);
    for (int skipped = 0; skipped < kCellsBeforeRadar; ++skipped)
        static_cast<void>(next_cell(cursor));
    cells.radar = next_cell(cursor);
    cells.is_ready = is_file_name(cells.five);
    return cells;
}

[[nodiscard]] bool keep_row(const Cells& cells) noexcept {
    if (!cells.is_ready) return false;
    if (cells.one == "INT" || cells.one == "STRING") return false;
    if (cells.one.starts_with('#')) return false;
    if (cells.two.size() > kMaxCellBytes || cells.five.size() > kMaxCellBytes) return false;
    if (cells.radar.size() > kMaxCellBytes) return false;
    return core::parse_whole_int(cells.one).has_value() && core::parse_whole_int(cells.three).has_value() &&
        core::parse_whole_int(cells.four).has_value();
}
    if (*near_clip <= 0 || *far_clip <= *near_clip) return;
    row.far_clip = *far_clip;
    row.near_clip = *near_clip;
}

void add_row(Book& book, const Cells& cells) {
    const std::optional<int> id = core::parse_whole_int(cells.one);
    const std::optional<int> x_size = core::parse_whole_int(cells.three);
    const std::optional<int> z_size = core::parse_whole_int(cells.four);
    if (!id || !x_size || !z_size) return;
    SceneRef row;
    row.id = *id;
    row.x_size = *x_size;
    row.z_size = *z_size;
    row.name_at = offset_of(book.text, cells.two);
    row.file_at = offset_of(book.text, cells.five);
    row.name_len = static_cast<std::uint16_t>(cells.two.size());
    row.file_len = static_cast<std::uint16_t>(cells.five.size());
    // Token chỉ là tên tệp trần: thứ khác (có dấu gạch chéo) thì coi như không có ảnh.
    const bool has_radar = is_file_name(cells.radar);
    row.radar_at = has_radar ? offset_of(book.text, cells.radar) : 0U;
    row.radar_len = has_radar ? static_cast<std::uint16_t>(cells.radar.size()) : std::uint16_t{0};
    const bool has_path = is_file_name(cells.six) && cells.six.size() <= kMaxCellBytes;
    row.path_at = has_path ? offset_of(book.text, cells.six) : 0U;
    row.path_len = has_path ? static_cast<std::uint16_t>(cells.six.size()) : std::uint16_t{0};
    take_clip(row, cells);
    book.rows.push_back(row);
}

void consider_line(Book& book, std::string_view line) {
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    const Cells cells = take_cells(line);
    if (!keep_row(cells)) return;
    add_row(book, cells);
}

void consume_line(Book& book, std::string_view& rest) {
    const std::size_t end = rest.find('\n');
    const bool is_last = end == std::string_view::npos;
    const std::string_view line = is_last ? rest : rest.substr(0, end);
    consider_line(book, line);
    if (is_last) {
        rest = {};
        return;
    }
    rest.remove_prefix(end + 1);
}

[[nodiscard]] bool row_less(const SceneRef& left, const SceneRef& right) noexcept {
    return left.id < right.id;
}

[[nodiscard]] bool keep_first(Seen& seen, int id) noexcept {
    if (seen.has && seen.id == id) return false;
    seen.id = id;
    seen.has = true;
    return true;
}

void push_kept(std::vector<SceneRef>& kept, Seen& seen, const SceneRef& row) {
    if (!keep_first(seen, row.id)) return;
    kept.push_back(row);
}

void compact_rows(std::vector<SceneRef>& rows) {
    std::ranges::stable_sort(rows, row_less);
    std::vector<SceneRef> kept;
    kept.reserve(rows.size());
    Seen seen;
    for (const SceneRef& row : rows)
        push_kept(kept, seen, row);
    rows.swap(kept);
}

[[nodiscard]] const SceneRef* pick_scene(const Book& book, const SceneRef* found, const SceneRef& row,
    std::string_view name) noexcept {
    if (found != nullptr) return found;
    const std::string_view file = file_of(book, row);
    const bool same_file = same_ascii(file, name);
    const bool same_stem = same_ascii(stem_of(file), name);
    if (same_file || same_stem) return &row;
    return nullptr;
}

} // namespace

BookResult read_book(std::string_view text) {
    Book book;
    book.text.assign(text.begin(), text.end());
    std::string_view rest(book.text);
    while (!rest.empty())
        consume_line(book, rest);
    if (book.rows.empty()) return std::unexpected(BookError::kBadTable);
    compact_rows(book.rows);
    return book;
}

std::string_view name_of(const Book& book, const SceneRef& row) noexcept {
    const std::string_view whole(book.text);
    return whole.substr(row.name_at, row.name_len);
}

std::string_view file_of(const Book& book, const SceneRef& row) noexcept {
    const std::string_view whole(book.text);
    return whole.substr(row.file_at, row.file_len);
}

std::string_view radar_of(const Book& book, const SceneRef& row) noexcept {
    const std::string_view whole(book.text);
    return whole.substr(row.radar_at, row.radar_len);
}

std::string_view path_of(const Book& book, const SceneRef& row) noexcept {
    const std::string_view whole(book.text);
    return whole.substr(row.path_at, row.path_len);
}

const SceneRef* find_id(const Book& book, int id) noexcept {
    const auto found = std::ranges::lower_bound(book.rows, id, {}, &SceneRef::id);
    if (found == book.rows.end() || found->id != id) return nullptr;
    return &*found;
}

const SceneRef* find_scene(const Book& book, std::string_view name) noexcept {
    const SceneRef* found = nullptr;
    for (const SceneRef& row : book.rows) {
        const ScenePick pick{.book = book, .found = found, .row = row, .name = name};
        found = pick_scene(pick);
    }
    return found;
}

std::string_view describe(BookError error) noexcept {
    switch (error) {
    case BookError::kBadTable: return "bảng cảnh không có dòng dùng được";
    case BookError::kUnknownScene: return "không có resid này trong bảng cảnh";
    }
    return "lỗi bảng cảnh không rõ";
}

} // namespace game::client::map
