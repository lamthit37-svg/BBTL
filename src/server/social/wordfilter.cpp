#include "social/wordfilter.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <iterator>
#include <memory>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

// ---------------------------------------------------------------------------------------------
// Mã hoá: đọc UTF-8 nới lỏng (byte hỏng thành U+FFFD, tiêu thụ đúng 1 byte) và gập chữ.
// ---------------------------------------------------------------------------------------------

constexpr char32_t kReplacement = 0xFFFD;
// Phần tử đệm trong luồng: không có từ cấm nào chứa nó nên bộ khớp tự về gốc, không bắc cầu qua dấu câu.
constexpr char32_t kBreak = 0xFFFF'FFFFU;
constexpr std::size_t kMaxPatternLength = 256;
constexpr std::size_t kMaxRegexRules = 4096;
constexpr std::size_t kMaxRegexUnits = 63;
constexpr std::size_t kShortAsciiLimit = 3;
constexpr std::size_t kMaxClassRanges = 8192;
constexpr char32_t kMaxCodepoint = 0x10FFFF;

struct Decoded {
    char32_t cp = kReplacement;
    std::uint8_t size = 1;
};

[[nodiscard]] bool is_continuation(std::string_view text, std::size_t index) noexcept {
    return index < text.size() && (static_cast<std::uint8_t>(text[index]) & 0xC0U) == 0x80U;
}

[[nodiscard]] Decoded decode_at(std::string_view text, std::size_t pos) noexcept {
    const auto lead = static_cast<std::uint8_t>(text[pos]);
    if (lead < 0x80U) return {.cp = lead, .size = 1};
    if (lead >= 0xC2U && lead <= 0xDFU && is_continuation(text, pos + 1)) {
        const char32_t cp = (static_cast<char32_t>(lead & 0x1FU) << 6U) | (static_cast<std::uint8_t>(text[pos + 1]) & 0x3FU);
        return {.cp = cp, .size = 2};
    }
    if (lead >= 0xE0U && lead <= 0xEFU && is_continuation(text, pos + 1) && is_continuation(text, pos + 2)) {
        const char32_t cp = (static_cast<char32_t>(lead & 0x0FU) << 12U) |
                            (static_cast<char32_t>(static_cast<std::uint8_t>(text[pos + 1]) & 0x3FU) << 6U) |
                            (static_cast<std::uint8_t>(text[pos + 2]) & 0x3FU);
        const bool surrogate = cp >= 0xD800U && cp <= 0xDFFFU;
        if (cp >= 0x800U && !surrogate) return {.cp = cp, .size = 3};
        return {};
    }
    if (lead >= 0xF0U && lead <= 0xF4U && is_continuation(text, pos + 1) && is_continuation(text, pos + 2) &&
        is_continuation(text, pos + 3)) {
        const char32_t cp = (static_cast<char32_t>(lead & 0x07U) << 18U) |
                            (static_cast<char32_t>(static_cast<std::uint8_t>(text[pos + 1]) & 0x3FU) << 12U) |
                            (static_cast<char32_t>(static_cast<std::uint8_t>(text[pos + 2]) & 0x3FU) << 6U) |
                            (static_cast<std::uint8_t>(text[pos + 3]) & 0x3FU);
        if (cp >= 0x10000U && cp <= kMaxCodepoint) return {.cp = cp, .size = 4};
    }
    return {};
}

void append_utf8(std::string& out, char32_t cp) {
    if (cp < 0x80U) {
        out.push_back(static_cast<char>(cp));
    } else if (cp < 0x800U) {
        out.push_back(static_cast<char>(0xC0U | (cp >> 6U)));
        out.push_back(static_cast<char>(0x80U | (cp & 0x3FU)));
    } else if (cp < 0x10000U) {
        out.push_back(static_cast<char>(0xE0U | (cp >> 12U)));
        out.push_back(static_cast<char>(0x80U | ((cp >> 6U) & 0x3FU)));
        out.push_back(static_cast<char>(0x80U | (cp & 0x3FU)));
    } else {
        out.push_back(static_cast<char>(0xF0U | (cp >> 18U)));
        out.push_back(static_cast<char>(0x80U | ((cp >> 12U) & 0x3FU)));
        out.push_back(static_cast<char>(0x80U | ((cp >> 6U) & 0x3FU)));
        out.push_back(static_cast<char>(0x80U | (cp & 0x3FU)));
    }
}

[[nodiscard]] bool in_range(char32_t cp, char32_t first, char32_t last) noexcept { return cp >= first && cp <= last; }

// Đưa chữ-số các kiểu viết khác về ASCII chữ thường: toàn góc, chữ toán học, khoanh tròn, có ngoặc.
// Ký hiệu và dấu câu KHÔNG đổi (client gốc cấm "＾" toàn góc, không cấm "^").
[[nodiscard]] char32_t fold_letter(char32_t cp) noexcept {
    if (in_range(cp, U'A', U'Z')) return cp - U'A' + U'a';
    if (cp < 0x80U) return cp;
    if (in_range(cp, 0xFF21U, 0xFF3AU)) return cp - 0xFF21U + U'a';
    if (in_range(cp, 0xFF41U, 0xFF5AU)) return cp - 0xFF41U + U'a';
    if (in_range(cp, 0xFF10U, 0xFF19U)) return cp - 0xFF10U + U'0';
    if (in_range(cp, 0x1D400U, 0x1D6A3U)) {
        const char32_t index = (cp - 0x1D400U) % 52U;
        return U'a' + (index < 26U ? index : index - 26U);
    }
    if (in_range(cp, 0x1D7CEU, 0x1D7FFU)) return U'0' + ((cp - 0x1D7CEU) % 10U);
    if (in_range(cp, 0x24B6U, 0x24CFU)) return U'a' + (cp - 0x24B6U);
    if (in_range(cp, 0x24D0U, 0x24E9U)) return U'a' + (cp - 0x24D0U);
    if (in_range(cp, 0x249CU, 0x24B5U)) return U'a' + (cp - 0x249CU);
    if (in_range(cp, 0x2460U, 0x2468U)) return U'1' + (cp - 0x2460U);
    if (cp == 0x24EAU) return U'0';
    return cp;
}

struct CodeSpan {
    char32_t first;
    char32_t last;
};

[[nodiscard]] constexpr CodeSpan span(char32_t first, char32_t last) noexcept { return {.first = first, .last = last}; }

// Dấu câu hết câu: ranh giới cứng. Xếp tăng theo `first`.
constexpr std::array kHardBreaks{
    span(0x09U, 0x0DU), span(U'!', U'!'), span(U',', U','), span(U'.', U'.'), span(U':', U';'),
    span(U'?', U'?'),   span(0x85U, 0x85U), span(0x2025U, 0x2026U), span(0x2028U, 0x2029U),
    span(0x3001U, 0x3002U), span(0xFF01U, 0xFF01U), span(0xFF0CU, 0xFF0CU), span(0xFF0EU, 0xFF0EU),
    span(0xFF1AU, 0xFF1BU), span(0xFF1FU, 0xFF1FU),
};

// Ký tự chen được bỏ qua khi khớp từ không chứa ký hiệu: dấu cách, điều khiển, ký hiệu ASCII, ký tự vô
// hình, dấu kết hợp, mũi tên/hình khối/biểu tượng, dấu câu CJK còn lại, emoji. Xếp tăng theo `first`.
constexpr std::array kSoftSeparators{
    span(0x00U, 0x2FU),       span(0x3AU, 0x40U),       span(0x5BU, 0x60U),       span(0x7BU, 0xBFU),
    span(0xD7U, 0xD7U),       span(0xF7U, 0xF7U),       span(0x0300U, 0x036FU),   span(0x061CU, 0x061CU),
    span(0x115FU, 0x1160U),   span(0x17B4U, 0x17B5U),   span(0x180BU, 0x180EU),   span(0x2000U, 0x206FU),
    span(0x20A0U, 0x20FFU),   span(0x2190U, 0x2BFFU),   span(0x2E00U, 0x2E7FU),   span(0x3000U, 0x3004U),
    span(0x3008U, 0x3020U),   span(0x3030U, 0x3030U),   span(0x303DU, 0x303FU),   span(0xFE00U, 0xFE6FU),
    span(0xFEFFU, 0xFF0FU),   span(0xFF1AU, 0xFF20U),   span(0xFF3BU, 0xFF40U),   span(0xFF5BU, 0xFF65U),
    span(0xFFE0U, 0xFFFFU),   span(0x1F000U, 0x1FAFFU), span(0xE0000U, 0xE007FU),
};

template <std::size_t N>
[[nodiscard]] bool in_spans(const std::array<CodeSpan, N>& spans, char32_t cp) noexcept {
    // Mảng xếp tăng theo first và các đoạn không chồng: tìm đoạn cuối có first <= cp.
    const auto after = std::ranges::upper_bound(spans, cp, {}, &CodeSpan::first);
    return after != spans.begin() && cp <= std::prev(after)->last;
}

[[nodiscard]] bool is_hard_break(char32_t folded) noexcept { return in_spans(kHardBreaks, folded); }

[[nodiscard]] bool is_separator(char32_t folded) noexcept {
    return folded == kReplacement || is_hard_break(folded) || in_spans(kSoftSeparators, folded);
}

[[nodiscard]] bool is_ascii_alnum(char32_t cp) noexcept {
    return in_range(cp, U'a', U'z') || in_range(cp, U'0', U'9') || in_range(cp, U'A', U'Z');
}

// ---------------------------------------------------------------------------------------------
// Luồng đã chuẩn hoá của một chuỗi cần quét, kèm khoảng byte gốc của từng phần tử.
// ---------------------------------------------------------------------------------------------

struct Stream {
    std::vector<char32_t> cps;
    std::vector<std::uint32_t> begin;
    std::vector<std::uint32_t> end;
    // Có ký tự chen (hoặc đầu chuỗi) ngay trước phần tử này trong văn bản gốc; chỉ luồng lỏng dùng, để biết
    // một từ ASCII ngắn có đứng thành cụm riêng không dù dấu cách đã bị bỏ khỏi luồng.
    std::vector<bool> gap_before;

    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): (từ, đến) theo thứ tự byte, mọi nơi gọi đặt tên rõ
    void push(char32_t cp, std::size_t from, std::size_t to, bool gap = false) {
        cps.push_back(cp);
        begin.push_back(static_cast<std::uint32_t>(from));
        end.push_back(static_cast<std::uint32_t>(to));
        gap_before.push_back(gap);
    }
};

// Luồng "lỏng": bỏ ký tự chen mềm, ranh giới cứng thành kBreak (gộp các ranh giới liên tiếp).
[[nodiscard]] Stream build_loose(std::string_view text) {
    Stream stream;
    stream.cps.reserve(text.size());
    bool gap = true;
    for (std::size_t pos = 0; pos < text.size();) {
        const Decoded decoded = decode_at(text, pos);
        const char32_t folded = fold_letter(decoded.cp);
        const std::size_t next = pos + decoded.size;
        if (is_hard_break(folded)) {
            if (stream.cps.empty() || stream.cps.back() != kBreak) stream.push(kBreak, pos, next, true);
            gap = true;
        } else if (is_separator(folded)) {
            gap = true;
        } else {
            stream.push(folded, pos, next, gap);
            gap = false;
        }
        pos = next;
    }
    return stream;
}

// Luồng "chặt": mọi điểm mã đã gập chữ, không bỏ gì.
[[nodiscard]] Stream build_strict(std::string_view text) {
    Stream stream;
    stream.cps.reserve(text.size());
    for (std::size_t pos = 0; pos < text.size();) {
        const Decoded decoded = decode_at(text, pos);
        stream.push(fold_letter(decoded.cp), pos, pos + decoded.size);
        pos += decoded.size;
    }
    return stream;
}

// ---------------------------------------------------------------------------------------------
// Aho-Corasick trên điểm mã. Cạnh lưu dạng CSR (mỗi nút một dải cạnh xếp theo ký tự) nên 145 nghìn từ
// tốn vài MB và tìm con là chia đôi.
// ---------------------------------------------------------------------------------------------

constexpr std::uint8_t kFlagShortAscii = 1U;

struct Match {
    std::size_t first = 0;  // chỉ số phần tử luồng đầu
    std::size_t last = 0;   // chỉ số phần tử luồng cuối
};

class Automaton {
public:
    void build(std::vector<std::u32string> patterns);
    [[nodiscard]] bool empty() const noexcept { return nodes_.size() <= 1; }
    [[nodiscard]] std::size_t pattern_count() const noexcept { return patterns_; }
    [[nodiscard]] std::size_t short_ascii_count() const noexcept { return short_ascii_; }

    // Gọi on_match(first, last, short_ascii) cho mọi lần khớp; on_match trả false để dừng sớm.
    template <class Callback>
    void scan(const std::vector<char32_t>& stream, const Callback& on_match) const {
        if (empty()) return;
        std::uint32_t state = 0;
        for (std::size_t index = 0; index < stream.size(); ++index) {
            const char32_t cp = stream[index];
            while (state != 0 && !child(state, cp).has_value()) state = nodes_[state].fail;
            if (const auto next = child(state, cp)) state = *next;
            std::uint32_t node = nodes_[state].len != 0 ? state : nodes_[state].dict;
            while (node != 0) {
                const Node& hit = nodes_[node];
                if (!on_match(index + 1 - hit.len, index, (hit.flags & kFlagShortAscii) != 0)) return;
                node = hit.dict;
            }
        }
    }

private:
    struct Node {
        std::uint32_t first_edge = 0;  // chỉ số cạnh đầu; cạnh cuối là first_edge của nút kế
        std::uint32_t fail = 0;
        std::uint32_t dict = 0;        // nút kết thúc từ gần nhất trên chuỗi fail (0 = không có)
        std::uint16_t len = 0;         // độ dài từ kết thúc ở nút này (0 = không phải nút kết thúc)
        std::uint8_t flags = 0;
    };

    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): nút là chỉ số, cp là điểm mã; hai kiểu khác nghĩa
    [[nodiscard]] std::optional<std::uint32_t> child(std::uint32_t node, char32_t cp) const {
        const auto first = edge_char_.begin() + nodes_[node].first_edge;
        const auto last = edge_char_.begin() + nodes_[static_cast<std::size_t>(node) + 1].first_edge;
        const auto found = std::lower_bound(first, last, cp);
        if (found == last || *found != cp) return std::nullopt;
        return edge_to_[static_cast<std::size_t>(found - edge_char_.begin())];
    }

    std::size_t patterns_ = 0;
    std::size_t short_ascii_ = 0;
    std::vector<Node> nodes_;  // thêm một nút lính cuối để biết cạnh cuối của nút cuối
    std::vector<char32_t> edge_char_;
    std::vector<std::uint32_t> edge_to_;
};

[[nodiscard]] bool is_short_ascii(const std::u32string& pattern) noexcept {
    return pattern.size() <= kShortAsciiLimit &&
           std::ranges::all_of(pattern, [](char32_t cp) { return is_ascii_alnum(cp); });
}

void Automaton::build(std::vector<std::u32string> patterns) {
    std::ranges::sort(patterns);
    const auto duplicates = std::ranges::unique(patterns);
    patterns.erase(duplicates.begin(), duplicates.end());
    patterns_ = patterns.size();
    short_ascii_ = static_cast<std::size_t>(std::ranges::count_if(patterns, is_short_ascii));

    // Bước 1: cây tiền tố dựng từ danh sách đã xếp (nút tạo theo thứ tự duyệt sâu, cha luôn nhỏ hơn con).
    struct Edge {
        std::uint32_t parent;
        char32_t cp;
        std::uint32_t child;
    };
    std::vector<Edge> edges;
    std::vector<std::uint16_t> lengths(1, 0);
    std::vector<std::uint8_t> flags(1, 0);
    std::vector<std::uint32_t> path(1, 0);
    const std::u32string* previous = nullptr;
    for (const std::u32string& pattern : patterns) {
        std::size_t common = 0;
        if (previous != nullptr) {
            const std::size_t limit = std::min(previous->size(), pattern.size());
            while (common < limit && (*previous)[common] == pattern[common]) ++common;
        }
        path.resize(common + 1);
        for (std::size_t depth = common; depth < pattern.size(); ++depth) {
            const auto id = static_cast<std::uint32_t>(lengths.size());
            edges.push_back({.parent = path.back(), .cp = pattern[depth], .child = id});
            lengths.push_back(0);
            flags.push_back(0);
            path.push_back(id);
        }
        lengths[path.back()] = static_cast<std::uint16_t>(pattern.size());
        flags[path.back()] = is_short_ascii(pattern) ? kFlagShortAscii : std::uint8_t{0};
        previous = &pattern;
    }

    // Bước 2: gom cạnh theo cha (sắp đếm ổn định nên ký tự của mỗi cha vẫn tăng dần).
    const std::size_t node_count = lengths.size();
    nodes_.assign(node_count + 1, Node{});
    for (const Edge& edge : edges) ++nodes_[static_cast<std::size_t>(edge.parent) + 1].first_edge;
    for (std::size_t node = 1; node <= node_count; ++node) nodes_[node].first_edge += nodes_[node - 1].first_edge;
    edge_char_.assign(edges.size(), 0);
    edge_to_.assign(edges.size(), 0);
    std::vector<std::uint32_t> cursor(node_count, 0);
    for (const Edge& edge : edges) {
        const std::size_t slot = static_cast<std::size_t>(nodes_[edge.parent].first_edge) + cursor[edge.parent]++;
        edge_char_[slot] = edge.cp;
        edge_to_[slot] = edge.child;
    }
    for (std::size_t node = 0; node < node_count; ++node) {
        nodes_[node].len = lengths[node];
        nodes_[node].flags = flags[node];
    }

    // Bước 3: liên kết fail và dict theo thứ tự rộng.
    std::vector<std::uint32_t> queue;
    queue.reserve(node_count);
    queue.push_back(0);
    for (std::size_t head = 0; head < queue.size(); ++head) {
        const std::uint32_t node = queue[head];
        for (std::uint32_t slot = nodes_[node].first_edge; slot < nodes_[static_cast<std::size_t>(node) + 1].first_edge; ++slot) {
            const std::uint32_t kid = edge_to_[slot];
            const char32_t cp = edge_char_[slot];
            std::uint32_t fail = 0;
            if (node != 0) {
                std::uint32_t walk = nodes_[node].fail;
                while (true) {
                    if (const auto hop = child(walk, cp)) {
                        fail = *hop;
                        break;
                    }
                    if (walk == 0) break;
                    walk = nodes_[walk].fail;
                }
            }
            nodes_[kid].fail = fail;
            nodes_[kid].dict = nodes_[fail].len != 0 ? fail : nodes_[fail].dict;
            queue.push_back(kid);
        }
    }
}

// ---------------------------------------------------------------------------------------------
// Mẫu type 11/12: dãy lớp ký tự, mỗi lớp có thể kèm '*' (cho phép lặp 0 lần trở lên). Đây là tập con
// của regex mà bảng thật dùng; cú pháp ngoài tập con làm dòng bị bỏ và đếm.
// ---------------------------------------------------------------------------------------------

struct CharClass {
    std::vector<CodeSpan> spans;  // đã hợp nhất, xếp tăng
    bool star = false;

    [[nodiscard]] bool contains(char32_t cp) const noexcept {
        const auto after = std::ranges::upper_bound(spans, cp, {}, &CodeSpan::first);
        return after != spans.begin() && cp <= std::prev(after)->last;
    }
};

struct RegexRule {
    std::vector<CharClass> units;
};

void add_span(std::vector<CodeSpan>& spans, char32_t first, char32_t last) {
    spans.push_back({.first = first, .last = last});
    // Luồng đã gập chữ thường, nên phần chữ hoa của đoạn được thêm bản chữ thường.
    const char32_t upper_first = std::max(first, U'A');
    const char32_t upper_last = std::min(last, U'Z');
    if (upper_first <= upper_last) spans.push_back({.first = fold_letter(upper_first), .last = fold_letter(upper_last)});
}

void merge_spans(std::vector<CodeSpan>& spans) {
    std::ranges::sort(spans, {}, &CodeSpan::first);
    std::vector<CodeSpan> merged;
    for (const CodeSpan& span : spans) {
        if (!merged.empty() && span.first <= merged.back().last + 1) {
            merged.back().last = std::max(merged.back().last, span.last);
        } else {
            merged.push_back(span);
        }
    }
    spans = std::move(merged);
}

// Đọc một lớp "[...]" bắt đầu tại text[pos] == '['. Trả vị trí sau ']' hoặc nullopt khi sai cú pháp.
[[nodiscard]] std::optional<std::size_t> parse_class(const std::vector<char32_t>& text, std::size_t pos, CharClass& out) {
    ++pos;
    if (pos < text.size() && text[pos] == U'^') return std::nullopt;  // lớp phủ định: ngoài tập con hỗ trợ
    while (pos < text.size() && text[pos] != U']') {
        char32_t cp = text[pos];
        if (cp == U'\\') {
            if (pos + 1 >= text.size()) return std::nullopt;
            const char32_t escaped = text[pos + 1];
            pos += 2;
            if (escaped == U's') {
                add_span(out.spans, 0x09U, 0x0DU);
                add_span(out.spans, U' ', U' ');
                add_span(out.spans, 0x3000U, 0x3000U);
                continue;
            }
            if (escaped == U'd') {
                add_span(out.spans, U'0', U'9');
                continue;
            }
            if (escaped == U'w') {
                add_span(out.spans, U'a', U'z');
                add_span(out.spans, U'A', U'Z');
                add_span(out.spans, U'0', U'9');
                add_span(out.spans, U'_', U'_');
                continue;
            }
            cp = escaped;
        } else {
            ++pos;
        }
        const bool is_range = pos + 1 < text.size() && text[pos] == U'-' && text[pos + 1] != U']';
        if (is_range) {
            char32_t last = text[pos + 1];
            pos += 2;
            if (last == U'\\') {
                if (pos >= text.size()) return std::nullopt;
                last = text[pos++];
            }
            if (last < cp) return std::nullopt;
            add_span(out.spans, cp, last);
        } else {
            add_span(out.spans, cp, cp);
            const char32_t folded = fold_letter(cp);
            if (folded != cp) add_span(out.spans, folded, folded);
        }
        if (out.spans.size() > kMaxClassRanges) return std::nullopt;
    }
    if (pos >= text.size()) return std::nullopt;
    merge_spans(out.spans);
    return pos + 1;
}

[[nodiscard]] std::optional<RegexRule> parse_rule(std::string_view source) {
    std::vector<char32_t> text;
    for (std::size_t pos = 0; pos < source.size();) {
        const Decoded decoded = decode_at(source, pos);
        if (decoded.cp == kReplacement) return std::nullopt;
        text.push_back(decoded.cp);
        pos += decoded.size;
    }
    RegexRule rule;
    std::size_t pos = 0;
    while (pos < text.size()) {
        if (text[pos] != U'[') return std::nullopt;
        CharClass unit;
        const auto after = parse_class(text, pos, unit);
        if (!after || unit.spans.empty()) return std::nullopt;
        pos = *after;
        if (pos < text.size() && text[pos] == U'*') {
            unit.star = true;
            ++pos;
        }
        rule.units.push_back(std::move(unit));
        if (rule.units.size() > kMaxRegexUnits) return std::nullopt;
    }
    const bool has_required = std::ranges::any_of(rule.units, [](const CharClass& unit) { return !unit.star; });
    if (!has_required) return std::nullopt;
    return rule;
}

// NFA theo bitmask: trạng thái i = đã khớp i đơn vị đầu. Mỗi trạng thái nhớ chỉ số bắt đầu nhỏ nhất.
class RegexRunner {
public:
    explicit RegexRunner(const RegexRule& rule) : units_(&rule.units) {}

    // Gọi on_match(first, last) cho mỗi lần khớp xong; on_match trả false để dừng sớm.
    template <class Callback>
    void run(const std::vector<char32_t>& stream, const Callback& on_match) const {
        const std::size_t count = units_->size();
        std::uint64_t active = 0;
        std::array<std::uint32_t, kMaxRegexUnits + 1> start{};
        for (std::size_t index = 0; index < stream.size(); ++index) {
            active |= 1U;
            start[0] = static_cast<std::uint32_t>(index);
            close(active, start);
            std::uint64_t next = 0;
            std::array<std::uint32_t, kMaxRegexUnits + 1> next_start{};
            for (std::size_t state = 0; state < count; ++state) {
                if (((active >> state) & 1U) == 0 || !(*units_)[state].contains(stream[index])) continue;
                add(next, next_start, (*units_)[state].star ? state : state + 1, start.at(state));
            }
            close(next, next_start, count);
            active = next;
            start = next_start;
            if (((active >> count) & 1U) != 0 && !on_match(start.at(count), index)) return;
        }
    }

private:
    static void add(std::uint64_t& set, std::array<std::uint32_t, kMaxRegexUnits + 1>& start, std::size_t state,
                    std::uint32_t from) noexcept {
        const std::uint64_t bit = std::uint64_t{1} << state;
        if ((set & bit) == 0 || from < start.at(state)) start.at(state) = from;
        set |= bit;
    }

    void close(std::uint64_t& set, std::array<std::uint32_t, kMaxRegexUnits + 1>& start) const noexcept {
        close(set, start, units_->size());
    }

    void close(std::uint64_t& set, std::array<std::uint32_t, kMaxRegexUnits + 1>& start, std::size_t count) const noexcept {
        for (std::size_t state = 0; state < count; ++state) {
            if (((set >> state) & 1U) != 0 && (*units_)[state].star) add(set, start, state + 1, start.at(state));
        }
    }

    const std::vector<CharClass>* units_;
};

// ---------------------------------------------------------------------------------------------
// Tên dành riêng.
// ---------------------------------------------------------------------------------------------

[[nodiscard]] std::string strict_key(std::string_view text) {
    std::string key;
    for (std::size_t pos = 0; pos < text.size();) {
        const Decoded decoded = decode_at(text, pos);
        append_utf8(key, fold_letter(decoded.cp));
        pos += decoded.size;
    }
    return key;
}

[[nodiscard]] std::string loose_key(std::string_view text) {
    std::string key;
    for (std::size_t pos = 0; pos < text.size();) {
        const Decoded decoded = decode_at(text, pos);
        const char32_t folded = fold_letter(decoded.cp);
        if (!is_separator(folded)) append_utf8(key, folded);
        pos += decoded.size;
    }
    return key;
}

struct NameSet {
    std::vector<std::string> strict;
    std::vector<std::string> loose;

    void finish() {
        for (auto* keys : {&strict, &loose}) {
            std::ranges::sort(*keys);
            const auto duplicates = std::ranges::unique(*keys);
            keys->erase(duplicates.begin(), duplicates.end());
        }
    }

    [[nodiscard]] bool contains(std::string_view name) const {
        if (std::ranges::binary_search(strict, strict_key(name))) return true;
        const std::string key = loose_key(name);
        return !key.empty() && std::ranges::binary_search(loose, key);
    }
};

void add_name(NameSet& set, std::string_view word) {
    set.strict.push_back(strict_key(word));
    if (std::string key = loose_key(word); !key.empty()) set.loose.push_back(std::move(key));
}

// ---------------------------------------------------------------------------------------------
// Đọc bảng.
// ---------------------------------------------------------------------------------------------

constexpr std::string_view kKindAll = "all";
constexpr std::string_view kKindGuild = "guild";
constexpr std::string_view kKindTeam = "team";
constexpr int kTypeBanned = 1;
constexpr int kTypeReservedAll = 2;
constexpr int kTypeReservedGuild = 3;
constexpr int kTypeRegexA = 11;
constexpr int kTypeRegexB = 12;

// Ô số nguyên không dấu nhỏ; nullopt khi không phải số.
[[nodiscard]] std::optional<int> small_int(std::string_view cell) noexcept {
    if (cell.empty() || cell.size() > 6) return std::nullopt;
    int value = 0;
    for (const char digit : cell) {
        if (digit < '0' || digit > '9') return std::nullopt;
        value = value * 10 + (digit - '0');
    }
    return value;
}

} // namespace

struct WordFilter::Impl {
    Automaton loose;
    Automaton strict;
    std::vector<RegexRule> rules;
    NameSet reserved_all;
    NameSet reserved_guild;
    NameSet reserved_team;
    FilterStats stats;
};

namespace {

struct Builder {
    std::vector<std::u32string> loose_patterns;
    std::vector<std::u32string> strict_patterns;
    WordFilter::Impl* impl = nullptr;

    // Từ cấm: chuỗi có ký hiệu vào bộ chặt, còn lại vào bộ lỏng.
    void add_word(std::string_view word) {
        std::u32string pattern;
        bool has_separator = false;
        for (std::size_t pos = 0; pos < word.size();) {
            const Decoded decoded = decode_at(word, pos);
            if (decoded.cp == kReplacement) {
                ++impl->stats.ignored_words;
                return;
            }
            const char32_t folded = fold_letter(decoded.cp);
            has_separator = has_separator || is_separator(folded);
            pattern.push_back(folded);
            pos += decoded.size;
        }
        const bool single_ascii = pattern.size() == 1 && pattern.front() < 0x80U;
        if (pattern.empty() || pattern.size() > kMaxPatternLength || single_ascii) {
            ++impl->stats.ignored_words;
            return;
        }
        (has_separator ? strict_patterns : loose_patterns).push_back(std::move(pattern));
    }

    void add_rule(std::string_view source) const {
        auto rule = parse_rule(source);
        if (!rule || impl->rules.size() >= kMaxRegexRules) {
            ++impl->stats.regex_skipped;
            return;
        }
        impl->rules.push_back(std::move(*rule));
    }
};

[[nodiscard]] std::expected<void, std::string> read_words(std::string_view tsv, Builder& builder) {
    auto parsed = table::parse_tsv(tsv);
    if (!parsed) return std::unexpected(std::format("text_filter: {}", parsed.error()));
    if (parsed->header.size() < 3) return std::unexpected("text_filter: bảng phải có ít nhất 3 cột (id, text, type)");
    for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
        const auto& cells = parsed->rows[row];
        const auto type = small_int(cells[2]);
        if (!type) return std::unexpected(std::format("text_filter dòng {}: cột type không phải số", parsed->lines[row]));
        const std::string_view text = cells[1];
        if (*type == kTypeBanned) {
            builder.add_word(text);
        } else if (*type == kTypeRegexA || *type == kTypeRegexB) {
            builder.add_rule(text);
        } else if (*type == kTypeReservedAll) {
            add_name(builder.impl->reserved_all, text);
        } else if (*type == kTypeReservedGuild) {
            add_name(builder.impl->reserved_guild, text);
        }
        // Loại khác: bảng của client có thể thêm loại mới; bỏ qua thay vì làm hỏng cả bộ lọc.
    }
    return {};
}

[[nodiscard]] std::expected<void, std::string> read_reserved(std::string_view tsv, const Builder& builder) {
    auto parsed = table::parse_tsv(tsv);
    if (!parsed) return std::unexpected(std::format("full_compare_filters: {}", parsed.error()));
    if (parsed->header.size() < 3) return std::unexpected("full_compare_filters: bảng phải có ít nhất 3 cột (id, kind, text)");
    for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
        const auto& cells = parsed->rows[row];
        NameSet* target = cells[1] == kKindAll     ? &builder.impl->reserved_all
                          : cells[1] == kKindGuild ? &builder.impl->reserved_guild
                          : cells[1] == kKindTeam  ? &builder.impl->reserved_team
                                                   : nullptr;
        if (target == nullptr) {
            return std::unexpected(std::format("full_compare_filters dòng {}: loại '{}' lạ (all, guild hay team)",
                                               parsed->lines[row], cells[1]));
        }
        add_name(*target, cells[2]);
    }
    return {};
}

[[nodiscard]] std::expected<void, std::string> read_extra(std::string_view tsv, Builder& builder) {
    auto parsed = table::parse_tsv(tsv);
    if (!parsed) return std::unexpected(std::format("chat_blocked_words: {}", parsed.error()));
    if (parsed->header.size() < 2) return std::unexpected("chat_blocked_words: bảng phải có ít nhất 2 cột (index, word)");
    for (const auto& cells : parsed->rows) builder.add_word(cells[1]);
    return {};
}

// Hợp các khoảng byte chồng hoặc kề nhau.
void merge_ranges(std::vector<std::pair<std::uint32_t, std::uint32_t>>& ranges) {
    std::ranges::sort(ranges);
    std::vector<std::pair<std::uint32_t, std::uint32_t>> merged;
    for (const auto& range : ranges) {
        if (!merged.empty() && range.first <= merged.back().second) {
            merged.back().second = std::max(merged.back().second, range.second);
        } else {
            merged.push_back(range);
        }
    }
    ranges = std::move(merged);
}

// Từ ASCII ngắn chỉ tính khi đứng thành cụm riêng: phần tử liền kề (không có ký tự chen ở giữa trong văn
// bản gốc) mà là ASCII chữ-số thì từ dính vào chữ khác, không tính.
[[nodiscard]] bool touches_alnum(const Stream& stream, std::size_t first, std::size_t last) noexcept {
    const bool before = first > 0 && !stream.gap_before[first] && is_ascii_alnum(stream.cps[first - 1]);
    const bool after = last + 1 < stream.cps.size() && !stream.gap_before[last + 1] && is_ascii_alnum(stream.cps[last + 1]);
    return before || after;
}

} // namespace

WordFilter::WordFilter(std::unique_ptr<Impl> impl) : impl_(std::move(impl)) {}
WordFilter::~WordFilter() = default;

std::expected<std::unique_ptr<WordFilter>, std::string> WordFilter::parse(const FilterSources& sources) {
    auto impl = std::make_unique<Impl>();
    Builder builder;
    builder.impl = impl.get();
    if (auto words = read_words(sources.words_tsv, builder); !words) return std::unexpected(std::move(words.error()));
    if (!sources.reserved_tsv.empty()) {
        if (auto reserved = read_reserved(sources.reserved_tsv, builder); !reserved) return std::unexpected(std::move(reserved.error()));
    }
    if (!sources.extra_tsv.empty()) {
        if (auto extra = read_extra(sources.extra_tsv, builder); !extra) return std::unexpected(std::move(extra.error()));
    }
    impl->loose.build(std::move(builder.loose_patterns));
    impl->strict.build(std::move(builder.strict_patterns));
    impl->stats.loose_words = impl->loose.pattern_count();
    impl->stats.strict_words = impl->strict.pattern_count();
    impl->stats.short_ascii = impl->loose.short_ascii_count();
    impl->stats.regex_rules = impl->rules.size();
    for (NameSet* set : {&impl->reserved_all, &impl->reserved_guild, &impl->reserved_team}) {
        set->finish();
        impl->stats.reserved_names += set->strict.size();
    }
    return std::make_unique<WordFilter>(std::move(impl));
}

const FilterStats& WordFilter::stats() const noexcept { return impl_->stats; }

namespace {

// Quét `text` và trả các khoảng byte cấm đã hợp. `stop_at_first`: dừng ngay ở khoảng đầu tiên.
[[nodiscard]] std::vector<std::pair<std::uint32_t, std::uint32_t>> find_banned(const WordFilter::Impl& impl,
                                                                                 std::string_view text, bool stop_at_first) {
    std::vector<std::pair<std::uint32_t, std::uint32_t>> ranges;
    const std::string_view scanned = text.substr(0, WordFilter::kMaxScanBytes);
    const Stream loose = build_loose(scanned);
    impl.loose.scan(loose.cps, [&](std::size_t first, std::size_t last, bool short_ascii) {
        if (short_ascii && touches_alnum(loose, first, last)) return true;
        ranges.emplace_back(loose.begin[first], loose.end[last]);
        return !stop_at_first;
    });
    if (stop_at_first && !ranges.empty()) return ranges;
    const Stream strict = build_strict(scanned);
    impl.strict.scan(strict.cps, [&](std::size_t first, std::size_t last, bool /*short_ascii*/) {
        ranges.emplace_back(strict.begin[first], strict.end[last]);
        return !stop_at_first;
    });
    for (const RegexRule& rule : impl.rules) {
        if (stop_at_first && !ranges.empty()) break;
        RegexRunner{rule}.run(strict.cps, [&](std::size_t first, std::size_t last) {
            ranges.emplace_back(strict.begin[first], strict.end[last]);
            return !stop_at_first;
        });
    }
    if (text.size() > scanned.size()) {
        // Phần chưa quét không được lọt qua: coi cả đoạn đuôi là cấm.
        ranges.emplace_back(static_cast<std::uint32_t>(scanned.size()), static_cast<std::uint32_t>(text.size()));
    }
    merge_ranges(ranges);
    return ranges;
}

} // namespace

bool WordFilter::allowed(std::string_view text) const { return find_banned(*impl_, text, true).empty(); }

std::string WordFilter::mask(std::string_view text) const {
    const auto ranges = find_banned(*impl_, text, false);
    if (ranges.empty()) return std::string{text};
    std::string out;
    out.reserve(text.size());
    std::size_t pos = 0;
    for (const auto& [first, last] : ranges) {
        out.append(text.substr(pos, first - pos));
        for (std::size_t at = first; at < last;) {
            at += std::min<std::size_t>(decode_at(text, at).size, last - at);
            out.push_back('*');
        }
        pos = last;
    }
    out.append(text.substr(pos));
    return out;
}

bool WordFilter::reserved_name(NameKind kind, std::string_view name) const {
    if (impl_->reserved_all.contains(name)) return true;
    switch (kind) {
        case NameKind::kGuild: return impl_->reserved_guild.contains(name);
        case NameKind::kTeam: return impl_->reserved_team.contains(name);
        case NameKind::kCharacter: return false;
    }
    return false;
}

} // namespace game::social
