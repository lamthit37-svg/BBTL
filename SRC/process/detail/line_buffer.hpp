#pragma once
// Ghép byte từ ống thành một dòng, không giữ quá trần. Dòng đúng trần chỉ xong khi byte kế là
// xuống dòng; byte khác là lỗi, không cấp phát thêm.

#include "process/process.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <utility>

namespace game::process::detail {

enum class FeedKind : std::uint8_t { kNeedMore, kLine, kTooLong };

// line có nghĩa khi kind là kLine; rest là phần của chunk chưa xét tới.
struct Feed {
    FeedKind kind = FeedKind::kNeedMore;
    std::string line;
    std::string rest;
};

inline void finish_line(std::string& pending, Feed& fed) {
    fed.line = std::exchange(pending, {});
    fed.kind = FeedKind::kLine;
}

inline void push_payload(std::string& pending, char byte, Feed& fed) {
    if (pending.size() >= kLineCeiling) {
        fed.kind = FeedKind::kTooLong;
        return;
    }
    pending.push_back(byte);
}

// `\r` sát `\n` là CRLF, không tính vào trần: giữ `\r` lại cho tới khi thấy byte sau.
inline void feed_byte(std::string& pending, char byte, bool& held_cr, Feed& fed) {
    const bool had_cr = std::exchange(held_cr, false);
    if (byte == '\n') {
        finish_line(pending, fed);
        return;
    }
    if (had_cr) push_payload(pending, '\r', fed);
    if (fed.kind != FeedKind::kNeedMore) return;
    if (byte == '\r') {
        held_cr = true;
        return;
    }
    push_payload(pending, byte, fed);
}

// Đưa chunk vào pending cho tới khi xong một dòng hoặc gặp dòng quá trần.
[[nodiscard]] inline Feed feed(std::string& pending, std::string_view chunk, bool& held_cr) {
    Feed fed;
    std::size_t index = 0;
    while (index < chunk.size() && fed.kind == FeedKind::kNeedMore) {
        feed_byte(pending, chunk[index], held_cr, fed);
        ++index;
    }
    fed.rest.assign(chunk.substr(index));
    return fed;
}

} // namespace game::process::detail
