// UTF-8, BOM, CR và LF cuối. Không suy ra cột hay tham chiếu.
#include "content/utf8.hpp"

#include "content/detail/scan.hpp"

#include <cstddef>
#include <string_view>

namespace game::content {
namespace {

using Size = std::size_t;

[[nodiscard]] bool continuation(unsigned char byte) noexcept {
    return byte >= 0x80 && byte <= 0xBF;
}

[[nodiscard]] std::size_t sequence_length(unsigned char lead) noexcept {
    if (lead <= 0x7F) return 1;
    if (lead >= 0xC2 && lead <= 0xDF) return 2;
    if (lead >= 0xE0 && lead <= 0xEF) return 3;
    if (lead >= 0xF0 && lead <= 0xF4) return 4;
    return 0;
}

struct Utf8Bytes {
    unsigned char lead = 0;
    unsigned char second = 0;
};

struct ByteSpan {
    Size origin = 0;
    Size count = 0;
};

[[nodiscard]] bool range_ok(Utf8Bytes bytes) noexcept {
    if (bytes.lead == 0xE0) return bytes.second >= 0xA0;
    if (bytes.lead == 0xED) return bytes.second <= 0x9F;
    if (bytes.lead == 0xF0) return bytes.second >= 0x90;
    if (bytes.lead == 0xF4) return bytes.second <= 0x8F;
    return true;
}

[[nodiscard]] bool accept_tail(TextView text, ByteSpan span) noexcept {
    bool valid = true;
    for (Size i = 1; valid && i < span.count; ++i)
        valid = continuation(static_cast<unsigned char>(text[span.origin + i]));
    return valid;
}

[[nodiscard]] bool accept_sequence(TextView text, ByteSpan span) noexcept {
    if (!accept_tail(text, span)) return false;
    if (span.count < 3) return true;
    const Utf8Bytes bytes{
        .lead = static_cast<unsigned char>(text[span.origin]),
        .second = static_cast<unsigned char>(text[span.origin + 1]),
    };
    return range_ok(bytes);
}

[[nodiscard]] std::size_t utf8_span(TextView text, std::size_t index) noexcept {
    if (index >= text.size()) return 0;
    const auto lead = static_cast<unsigned char>(text[index]);
    const std::size_t length = sequence_length(lead);
    if (length == 0 || index + length > text.size()) return 0;
    const ByteSpan span{.origin = index, .count = length};
    if (!accept_sequence(text, span)) return 0;
    return length;
}

struct Utf8Walk {
    std::size_t index = 0;
    bool bad = false;
};

void advance_utf8(Utf8Walk& walk, TextView text) noexcept {
    if (walk.bad || walk.index >= text.size()) return;
    const std::size_t length = utf8_span(text, walk.index);
    walk.bad = length == 0;
    if (walk.bad) return;
    walk.index += length;
}

[[nodiscard]] std::size_t utf8_error(TextView text) noexcept {
    Utf8Walk walk;
    while (walk.index < text.size() && !walk.bad)
        advance_utf8(walk, text);
    if (!walk.bad) return TextView::npos;
    return walk.index;
}

[[nodiscard]] bool has_bom(TextView text) noexcept {
    return text.size() >= 3 && text[0] == '\xEF' && text[1] == '\xBB' && text[2] == '\xBF';
}

} // namespace

bool file_bytes_ok(TextView text, TextView path, IssueList& issues) {
    const std::size_t utf8 = utf8_error(text);
    if (utf8 != TextView::npos) {
        add_issue(issues, path, line_of(text, utf8), "byte UTF-8 hỏng");
        return false;
    }
    if (has_bom(text)) {
        add_issue(issues, path, 1, "có BOM");
        return false;
    }
    const auto carriage = text.find('\r');
    if (carriage != TextView::npos) {
        add_issue(issues, path, line_of(text, carriage), "có ký tự CR");
        return false;
    }
    if (text.empty() || text.back() != '\n') {
        add_issue(issues, path, 1, "thiếu xuống dòng cuối");
        return false;
    }
    return true;
}

} // namespace game::content
