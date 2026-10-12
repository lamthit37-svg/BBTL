// Quét ngoặc một lượt. Khối con chỉ được dựng khi find() hỏi tên đó.
#include "fx/script.hpp"

#include <charconv>
#include <utility>

namespace game::fx {
namespace {

[[nodiscard]] bool is_space(char letter) noexcept {
    return letter == ' ' || letter == '\t' || letter == '\r' || letter == '\n';
}

[[nodiscard]] std::string_view trim(std::string_view text) noexcept {
    while (!text.empty() && is_space(text.front()))
        text.remove_prefix(1);
    while (!text.empty() && is_space(text.back()))
        text.remove_suffix(1);
    return text;
}

[[nodiscard]] std::string_view strip_comment(std::string_view text) noexcept {
    const std::size_t mark = text.find("//");
    if (mark == std::string_view::npos) return text;
    return text.substr(0, mark);
}

[[nodiscard]] std::vector<std::string_view> words_of(std::string_view text) {
    std::vector<std::string_view> words;
    std::size_t index = 0;
    while (index < text.size()) {
        while (index < text.size() && is_space(text[index]))
            ++index;
        if (index >= text.size()) break;
        const std::size_t start = index;
        while (index < text.size() && !is_space(text[index]))
            ++index;
        words.push_back(text.substr(start, index - start));
    }
    return words;
}

[[nodiscard]] std::string name_of(std::string_view line, std::size_t name_word) {
    const std::vector<std::string_view> words = words_of(trim(strip_comment(line)));
    if (name_word >= words.size()) return {};
    return std::string(words[name_word]);
}

struct Cursor {
    std::string_view text;
    std::size_t at = 0;
};

[[nodiscard]] std::string_view take_line(Cursor& cursor) {
    if (cursor.at >= cursor.text.size()) return {};
    const std::size_t end = cursor.text.find('\n', cursor.at);
    const std::size_t stop = end == std::string_view::npos ? cursor.text.size() : end;
    const std::string_view line = cursor.text.substr(cursor.at, stop - cursor.at);
    cursor.at = stop < cursor.text.size() ? stop + 1 : cursor.text.size();
    return trim(strip_comment(line));
}

[[nodiscard]] std::string_view peek_line(const Cursor& cursor) {
    Cursor copy = cursor;
    return take_line(copy);
}

[[nodiscard]] ScriptProperty property_of(std::string_view line) {
    const std::vector<std::string_view> words = words_of(line);
    ScriptProperty property;
    if (words.empty()) return property;
    property.key = std::string(words.front());
    for (std::size_t index = 1; index < words.size(); ++index)
        property.args.emplace_back(words[index]);
    return property;
}

[[nodiscard]] ScriptBlock parse_block(Cursor& cursor, std::string_view opener);

[[nodiscard]] bool opens_child(const Cursor& cursor) noexcept {
    return peek_line(cursor) == "{";
}

void read_child(Cursor& cursor, ScriptBlock& block, std::string_view line) {
    static_cast<void>(take_line(cursor));
    block.children.push_back(parse_block(cursor, line));
}

void take_body_line(Cursor& cursor, ScriptBlock& block) {
    const std::string_view line = take_line(cursor);
    if (line.empty() || line == "{") return;
    if (line == "}") return;
    if (opens_child(cursor)) return read_child(cursor, block, line);
    block.properties.push_back(property_of(line));
}

[[nodiscard]] bool is_closer(const Cursor& cursor) noexcept {
    return peek_line(cursor) == "}";
}

ScriptBlock parse_block(Cursor& cursor, std::string_view opener) {
    ScriptBlock block;
    const std::vector<std::string_view> head = words_of(opener);
    for (const std::string_view word : head)
        block.head.emplace_back(word);
    while (cursor.at < cursor.text.size() && !is_closer(cursor))
        take_body_line(cursor, block);
    if (is_closer(cursor)) static_cast<void>(take_line(cursor));
    return block;
}

} // namespace

std::optional<float> parse_float(std::string_view text) {
    if (!text.empty() && text.front() == '+') text.remove_prefix(1);
    if (text.empty()) return std::nullopt;
    float value = 0.0F;
    // from_chars đòi hai con trỏ biên. Khoảng đó đúng độ dài view, không đi quá.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic)
    const char* const last = text.data() + text.size();
    const std::from_chars_result parsed = std::from_chars(text.data(), last, value);
    if (parsed.ec != std::errc{} || parsed.ptr != last) return std::nullopt;
    return value;
}

bool parse_bool(std::string_view text) {
    return text == "true" || text == "yes" || text == "1";
}

std::optional<std::string_view> ScriptBlock::arg(std::string_view key, std::size_t index) const {
    for (const ScriptProperty& property : properties) {
        if (property.key != key || index >= property.args.size()) continue;
        return std::string_view(property.args[index]);
    }
    return std::nullopt;
}

float ScriptBlock::number(std::string_view key, float fallback, std::size_t index) const {
    const std::optional<std::string_view> text = arg(key, index);
    if (!text) return fallback;
    const std::optional<float> value = parse_float(*text);
    return value ? *value : fallback;
}

bool ScriptBlock::flag(std::string_view key, bool fallback) const {
    const std::optional<std::string_view> text = arg(key, 0);
    if (!text) return fallback;
    return parse_bool(*text);
}

std::string_view ScriptBlock::word(std::size_t index) const {
    if (index >= head.size()) return {};
    return head[index];
}

namespace {

// Chỗ bắt đầu của dòng đứng ngay trước dấu { ở brace: dòng mang tên của khối.
[[nodiscard]] std::size_t name_line_at(std::string_view text, std::size_t brace) noexcept {
    std::size_t at = brace;
    while (at > 0 && is_space(text[at - 1]))
        --at;
    if (at == 0) return 0;
    const std::size_t break_at = text.rfind('\n', at - 1);
    return break_at == std::string_view::npos ? 0 : break_at + 1;
}

} // namespace

void ScriptIndex::index_blocks() {
    int depth = 0;
    std::size_t outer_open = 0;
    for (std::size_t index = 0; index < text_.size(); ++index) {
        const char letter = text_[index];
        if (letter == '{') {
            if (depth == 0) outer_open = index;
            ++depth;
        }
        if (letter != '}' || depth == 0) continue;
        --depth;
        if (depth != 0) continue;
        const std::size_t block_line = name_line_at(text_, outer_open);
        const std::size_t line_end = text_.find('\n', block_line);
        const std::size_t stop = line_end == std::string::npos ? text_.size() : line_end;
        const std::string name = name_of(std::string_view(text_).substr(block_line, stop - block_line), name_word_);
        if (name.empty() || spans_.contains(name)) continue;
        spans_.emplace(name, Span{.begin = block_line, .end = index + 1});
    }
}

ScriptIndex::ScriptIndex(std::string text, std::size_t name_word) : text_(std::move(text)), name_word_(name_word) {
    index_blocks();
}

bool ScriptIndex::contains(std::string_view name) const {
    return spans_.contains(std::string(name));
}

const ScriptBlock* ScriptIndex::find(std::string_view name) {
    const auto parsed = parsed_.find(std::string(name));
    if (parsed != parsed_.end()) return &parsed->second;
    const auto span = spans_.find(std::string(name));
    if (span == spans_.end()) return nullptr;
    Cursor cursor;
    const std::size_t begin = span->second.begin;
    const std::size_t count = span->second.end - begin;
    cursor.text = std::string_view(text_).substr(begin, count);
    const std::string_view opener = take_line(cursor);
    ScriptBlock block = parse_block(cursor, opener);
    const auto stored = parsed_.emplace(std::string(name), std::move(block));
    return &stored.first->second;
}

} // namespace game::fx
