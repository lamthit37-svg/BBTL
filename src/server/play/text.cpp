/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/text.cpp
 *  PHÂN HỆ   : Server / Play / Text
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt sách chữ: nạp bảng khoá-chữ, thay tham số {n}, cắt chữ theo ranh
 *    giới UTF-8.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "play/text.hpp"

#include "ops/ops.hpp"
#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::play {

namespace {

[[nodiscard]] bool is_continuation(char byte) noexcept {
    return (static_cast<unsigned char>(byte) & 0xC0U) == 0x80U;
}

// {n} với n là 1 đến 3 chữ số thập phân: tham số thứ n. Mọi dạng khác của dấu { giữ nguyên.
struct Placeholder {
    std::size_t index = 0;
    std::size_t close = 0;  // vị trí dấu }
};

[[nodiscard]] std::optional<Placeholder> placeholder_at(std::string_view source, std::size_t open) {
    if (source[open] != '{') return std::nullopt;
    std::size_t close = open + 1;
    std::size_t index = 0;
    while (close < source.size() && source[close] >= '0' && source[close] <= '9' && close - open <= 3) {
        index = (index * 10) + static_cast<std::size_t>(source[close] - '0');
        ++close;
    }
    if (close == open + 1 || close >= source.size() || source[close] != '}') return std::nullopt;
    return Placeholder{.index = index, .close = close};
}

// Chữ của tham số thứ `at`; chỉ số ngoài danh sách cho rỗng (dữ liệu hỏng không làm hỏng câu).
[[nodiscard]] std::string param_text(const ops::TextRef& text, std::size_t slot, const Names& names,
    const ops::Context& context) {
    if (slot >= text.params.size()) return {};
    const ops::TextParam& param = text.params[slot];
    if (param.kind == ops::TextParam::Kind::kPlayer) return std::string{names.player};
    if (param.kind == ops::TextParam::Kind::kNpc) return std::string{names.npc};
    return std::to_string(ops::param_value(param, context));
}

} // namespace

std::size_t TextBook::add(const table::Tsv& two_columns) {
    std::size_t added = 0;
    for (const std::vector<std::string>& row : two_columns.rows) {
        if (row.size() < 2 || row[0].empty()) continue;
        by_id_.insert_or_assign(ops::string_id(row[0]), row[1]);
        ++added;
    }
    return added;
}

const std::string* TextBook::find(std::uint32_t id) const noexcept {
    const auto found = by_id_.find(id);
    return found == by_id_.end() ? nullptr : &found->second;
}

std::string clip_utf8(std::string text, std::size_t max_bytes) {
    if (text.size() <= max_bytes) return text;
    std::size_t cut = max_bytes;
    while (cut > 0 && is_continuation(text[cut])) --cut;
    text.resize(cut);
    return text;
}

std::string render(const TextBook& book, const ops::TextRef& text, const Names& names, const ops::Context& context,
    std::size_t max_bytes) {
    const std::string* pattern = book.find(text.id);
    if (pattern == nullptr) return {};
    const std::string_view source{*pattern};
    std::string out;
    out.reserve(source.size());
    for (std::size_t cursor = 0; cursor < source.size() && out.size() <= max_bytes; ++cursor) {
        const std::optional<Placeholder> hole = placeholder_at(source, cursor);
        if (!hole) {
            out.push_back(source[cursor]);
            continue;
        }
        out += param_text(text, hole->index, names, context);
        cursor = hole->close;
    }
    return clip_utf8(std::move(out), max_bytes);
}

} // namespace game::play
