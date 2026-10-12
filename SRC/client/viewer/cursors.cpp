#include "client/viewer/cursors.hpp"

#include "control/cursor_rules.hpp"
#include "core/error.hpp"
#include "core/number.hpp"
#include "io/file.hpp"
#include "window/cursor.hpp"

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::client {
namespace {

constexpr std::string_view kMagic = "TLBBTEX ";
constexpr std::uint32_t kMaxEdge = 256;

struct PictureFile {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    std::vector<std::uint8_t> rgba;
};

[[nodiscard]] std::uint16_t read_u16(std::span<const std::byte> bytes, std::size_t offset) {
    std::uint16_t value = 0;
    std::memcpy(&value, bytes.subspan(offset, sizeof(value)).data(), sizeof(value));
    return value;
}

[[nodiscard]] std::uint32_t read_u32(std::span<const std::byte> bytes, std::size_t offset) {
    std::uint32_t value = 0;
    std::memcpy(&value, bytes.subspan(offset, sizeof(value)).data(), sizeof(value));
    return value;
}

// TLBBTEX v2: định dạng RGBA8, loại phẳng, một mức. Đủ 28 byte mới được đọc số.
[[nodiscard]] bool header_is_rgba(std::string_view text, std::span<const std::byte> bytes) {
    if (text.size() < 28 || bytes.size() < 28) return false;
    const std::string_view magic = text.substr(0, kMagic.size());
    const bool is_magic = magic == kMagic;
    const bool version = read_u16(bytes, 8) == 2;
    const bool format = read_u16(bytes, 10) == 1;
    const bool flat = read_u16(bytes, 12) == 1;
    const bool one_mip = read_u16(bytes, 22) == 1;
    return is_magic && version && format && flat && one_mip;
}

[[nodiscard]] std::optional<PictureFile> read_rgba_ttex(const std::filesystem::path& path) {
    const io::TextResult text = io::read_text(path);
    if (!text) return std::nullopt;
    const auto bytes = std::as_bytes(std::span(text->data(), text->size()));
    if (!header_is_rgba(*text, bytes)) return std::nullopt;
    PictureFile picture;
    picture.width = read_u32(bytes, 14);
    picture.height = read_u32(bytes, 18);
    const bool small = picture.width > 0 && picture.width <= kMaxEdge;
    const bool short_edge = picture.height > 0 && picture.height <= kMaxEdge;
    if (!small || !short_edge) return std::nullopt;
    const std::uint32_t size = read_u32(bytes, 24);
    const std::size_t need = static_cast<std::size_t>(picture.width) * picture.height * 4U;
    if (size != need || bytes.size() < 28U + need) return std::nullopt;
    picture.rgba.resize(need);
    std::memcpy(picture.rgba.data(), bytes.subspan(28, need).data(), need);
    return picture;
}

struct CellWalk {
    std::string_view line;
    int wanted = 0;
    int seen = 0;
    std::size_t start = 0;
    std::optional<std::string_view> found;
};

void take_cell(CellWalk& walk, std::size_t index) {
    if (walk.found) return;
    const bool cut = index == walk.line.size() || walk.line[index] == '\t';
    if (!cut) return;
    if (walk.seen != walk.wanted) {
        ++walk.seen;
        walk.start = index + 1;
        return;
    }
    walk.found = walk.line.substr(walk.start, index - walk.start);
}

[[nodiscard]] std::string_view field_at(std::string_view line, int index) {
    CellWalk walk;
    walk.line = line;
    walk.wanted = index;
    for (std::size_t place = 0; place <= line.size(); ++place)
        take_cell(walk, place);
    if (!walk.found) return {};
    return *walk.found;
}

[[nodiscard]] std::string_view peel_space(std::string_view text) {
    if (!text.empty() && text.front() == ' ') return text.substr(1);
    if (!text.empty() && text.back() == ' ') return text.substr(0, text.size() - 1);
    return text;
}

[[nodiscard]] std::string trim_cell(std::string_view text) {
    std::string_view rest = text;
    while (peel_space(rest).size() != rest.size())
        rest = peel_space(rest);
    return std::string(rest);
}

struct Row {
    std::string kind;
    std::string file;
    int hot_x = 0;
    int hot_y = 0;
    bool has_hot = false;
};

[[nodiscard]] Row row_of(std::string_view line) {
    Row row;
    row.kind = trim_cell(field_at(line, 0));
    row.file = trim_cell(field_at(line, 1));
    const std::string hot_x_text = trim_cell(field_at(line, 2));
    const std::string hot_y_text = trim_cell(field_at(line, 3));
    const std::optional<int> hot_x = core::parse_whole_int(hot_x_text);
    const std::optional<int> hot_y = core::parse_whole_int(hot_y_text);
    if (!hot_x || !hot_y) return row;
    row.hot_x = *hot_x;
    row.hot_y = *hot_y;
    row.has_hot = true;
    return row;
}

void keep_row(GameCursors& cursors, const std::filesystem::path& root, const Row& row) {
    const std::optional<control::CursorKind> kind = control::cursor_named(row.kind);
    if (!kind || *kind == control::CursorKind::kSystem) return;
    const bool hot_ok = row.has_hot && row.hot_x <= 255 && row.hot_y <= 255;
    if (!hot_ok) {
        std::println(stderr, "Con trỏ: bỏ {}, hotspot không hợp lệ", row.kind);
        return;
    }
    const std::optional<PictureFile> picture = read_rgba_ttex(root / row.file);
    if (!picture) {
        std::println(stderr, "Con trỏ: bỏ {}, không đọc được ảnh", row.file);
        return;
    }
    window::Cursor::RgbaCursor bits;
    bits.width = picture->width;
    bits.height = picture->height;
    bits.hot_x = static_cast<std::uint16_t>(row.hot_x);
    bits.hot_y = static_cast<std::uint16_t>(row.hot_y);
    bits.rgba = picture->rgba;
    core::Result<window::Cursor> made = window::Cursor::from_rgba(bits);
    if (!made) {
        std::println(stderr, "Con trỏ: bỏ {}: {}", row.kind, made.error());
        return;
    }
    cursors.pictures.at(static_cast<std::size_t>(*kind)) = std::move(*made);
}

void take_line(GameCursors& cursors, const std::filesystem::path& root, std::string_view line) {
    if (line.empty() || line.front() == '#' || line.starts_with("kind")) return;
    keep_row(cursors, root, row_of(line));
}

struct LineWalk {
    std::size_t start = 0;
};

struct LineCut {
    GameCursors* cursors = nullptr;
    const std::filesystem::path* root = nullptr;
    std::string_view body;
    LineWalk* walk = nullptr;
};

void take_break(const LineCut& cut, std::size_t index) {
    const bool cut_line = index == cut.body.size() || cut.body[index] == '\n';
    if (!cut_line) return;
    std::string_view line = cut.body.substr(cut.walk->start, index - cut.walk->start);
    if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
    take_line(*cut.cursors, *cut.root, line);
    cut.walk->start = index + 1;
}

[[nodiscard]] std::size_t one_picture(const std::optional<window::Cursor>& picture) noexcept {
    return picture ? 1U : 0U;
}

[[nodiscard]] std::size_t picture_count(const GameCursors& cursors) noexcept {
    std::size_t count = 0;
    for (const std::optional<window::Cursor>& picture : cursors.pictures)
        count += one_picture(picture);
    return count;
}

} // namespace

GameCursors load_game_cursors(const std::filesystem::path& data_root) {
    GameCursors cursors;
    const std::filesystem::path table = data_root / "Interface" / "cursor" / "cursors.tsv";
    const io::TextResult text = io::read_text(table);
    if (!text) {
        std::println(stderr, "Con trỏ: không có bảng {}", io::utf8_of(table));
        return cursors;
    }
    LineWalk walk;
    LineCut cut;
    cut.cursors = &cursors;
    cut.root = &data_root;
    cut.body = std::string_view(*text);
    cut.walk = &walk;
    for (std::size_t index = 0; index <= cut.body.size(); ++index)
        take_break(cut, index);
    std::println("Con trỏ: {} ảnh", picture_count(cursors));
    return cursors;
}

} // namespace game::client
