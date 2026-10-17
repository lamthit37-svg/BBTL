/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/codec.cpp
 *  PHÂN HỆ   : Net / Carrier / Codec
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc và ghi khung byte của carrier. Little-endian, kiểm biên từng trường, không memcpy struct.
 *  - Nguồn thuật toán: GameNetworkingSockets v1.6.1 commit d534c19.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "net/detail/pipe.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <utility>

namespace game::net::detail {

void write_u8(Cursor& cursor, std::uint8_t value) {
    if (cursor.bad || cursor.at >= cursor.buf.size()) {
        cursor.bad = true;
        return;
    }
    cursor.buf[cursor.at] = static_cast<std::byte>(value);
    ++cursor.at;
}
void write_u16(Cursor& cursor, std::uint16_t value) {
    if (cursor.bad || cursor.at > cursor.buf.size() || cursor.buf.size() - cursor.at < 2) {
        cursor.bad = true;
        return;
    }
    cursor.buf[cursor.at] = static_cast<std::byte>(value & 0xffU);
    cursor.buf[cursor.at + 1] = static_cast<std::byte>(value >> 8U);
    cursor.at += 2;
}
void copy_bytes(std::span<std::byte> dest, std::span<const std::byte> src) {
    for (std::size_t index = 0; index < src.size(); ++index)
        dest[index] = src[index];
}
void write_bytes(Cursor& cursor, std::span<const std::byte> data) {
    if (cursor.bad || cursor.at > cursor.buf.size() ||
        data.size() > cursor.buf.size() - cursor.at) {
        cursor.bad = true;
        return;
    }
    const std::span<std::byte> dest = cursor.buf.subspan(cursor.at, data.size());
    copy_bytes(dest, data);
    cursor.at += data.size();
}
std::uint8_t read_u8(View& view) {
    if (view.bad || view.at >= view.buf.size()) {
        view.bad = true;
        return 0;
    }
    const auto value = static_cast<std::uint8_t>(view.buf[view.at]);
    ++view.at;
    return value;
}
std::uint16_t read_u16(View& view) {
    if (view.bad || view.at > view.buf.size() || view.buf.size() - view.at < 2) {
        view.bad = true;
        return 0;
    }
    const auto lo = static_cast<std::uint16_t>(view.buf[view.at]);
    const auto hi = static_cast<std::uint16_t>(view.buf[view.at + 1]);
    view.at += 2;
    return static_cast<std::uint16_t>(lo | static_cast<std::uint16_t>(hi << 8U));
}
std::span<const std::byte> read_bytes(View& view, std::size_t size) {
    if (view.bad || view.at > view.buf.size() || size > view.buf.size() - view.at) {
        view.bad = true;
        return {};
    }
    const std::span<const std::byte> part = view.buf.subspan(view.at, size);
    view.at += size;
    return part;
}
std::uint8_t foreign_flags(std::uint8_t flags) noexcept {
    const auto mask = static_cast<std::uint8_t>(~kKnownFlags);
    return static_cast<std::uint8_t>(flags & mask);
}
bool ack_bit(const std::array<std::byte, kAckBytes>& raw, std::size_t index) noexcept {
    const auto current = static_cast<unsigned>(raw[index / 8U]);
    const unsigned shift = static_cast<unsigned>(index % 8U);
    return (current & (1U << shift)) != 0;
}
void set_ack_bit(std::array<std::byte, kAckBytes>& raw, std::size_t index) noexcept {
    const auto current = static_cast<unsigned>(raw[index / 8U]);
    const unsigned shift = static_cast<unsigned>(index % 8U);
    raw[index / 8U] = static_cast<std::byte>(current | (1U << shift));
}
int add_if_set(const std::array<std::byte, kAckBytes>& raw, std::uint16_t newest,
    std::uint16_t cursor) {
    const auto index = static_cast<std::size_t>(static_cast<std::uint16_t>(newest - 1U - cursor));
    if (index >= kAckSpan) return 0;
    if (!ack_bit(raw, index)) return 0;
    return 1;
}
int newer_received(std::uint16_t newest, const std::array<std::byte, kAckBytes>& raw,
    std::uint16_t seq) {
    int count = 1;
    int steps = 0;
    std::uint16_t cursor = static_cast<std::uint16_t>(newest - 1U);
    while (cursor != seq && count < kFastGap && steps < static_cast<int>(kAckSpan)) {
        count += add_if_set(raw, newest, cursor);
        cursor = static_cast<std::uint16_t>(cursor - 1U);
        ++steps;
    }
    return count;
}
std::uint16_t bit_seq(std::uint16_t newest, std::size_t index) noexcept {
    const auto back = static_cast<std::uint16_t>(index);
    return static_cast<std::uint16_t>(newest - 1U - back);
}
void fill_ack_bit(State& state, std::array<std::byte, kAckBytes>& raw, std::size_t index) {
    const std::uint16_t seq = bit_seq(state.highest, index);
    if (!storage_test(state, seq)) return;
    set_ack_bit(raw, index);
}
void write_ack_bits(Cursor& cursor, State& state) {
    std::array<std::byte, kAckBytes> raw{};
    for (std::size_t index = 0; index < kAckSpan; ++index)
        fill_ack_bit(state, raw, index);
    write_bytes(cursor, raw);
}
std::size_t header_size(bool has_ack) noexcept {
    std::size_t size = 8;
    if (has_ack) size += 4 + kAckBytes;
    return size;
}
void write_ack_block(Cursor& cursor, State& state) {
    write_u16(cursor, state.highest);
    write_u16(cursor, static_cast<std::uint16_t>(kAckSpan));
    write_ack_bits(cursor, state);
}
void write_header(Cursor& cursor, State& state, std::uint16_t number) {
    const bool has_ack = state.have_recv;
    std::uint8_t flags = kFlagStop;
    if (has_ack) flags = static_cast<std::uint8_t>(flags | kFlagAck);
    write_u8(cursor, kVersion);
    write_u8(cursor, flags);
    write_u16(cursor, number);
    write_u16(cursor, oldest_or(state, state.next_number));
    if (has_ack) write_ack_block(cursor, state);
    write_u16(cursor, 0);
}
void stamp_frames(Cursor& cursor, bool has_ack) noexcept {
    const std::size_t at = header_size(has_ack) - 2;
    const auto bytes = static_cast<std::uint16_t>(cursor.at - header_size(has_ack));
    cursor.buf[at] = static_cast<std::byte>(bytes & 0xffU);
    cursor.buf[at + 1] = static_cast<std::byte>(bytes >> 8U);
}
void write_frame(Cursor& cursor, const Frag& frag) {
    write_u8(cursor, frag.kind);
    write_u8(cursor, frag.lane);
    write_u16(cursor, frag.message);
    write_u16(cursor, frag.index);
    write_u16(cursor, frag.count);
    write_u16(cursor, static_cast<std::uint16_t>(frag.payload.size()));
    write_bytes(cursor, frag.payload);
}
bool push_frame(View& view, std::vector<Frame>& frames) {
    if (frames.size() >= kMaxFrames) {
        view.bad = true;
        return false;
    }
    Frame frame;
    frame.kind = read_u8(view);
    frame.lane = read_u8(view);
    frame.message = read_u16(view);
    frame.index = read_u16(view);
    frame.count = read_u16(view);
    const std::uint16_t size = read_u16(view);
    const bool size_bad = size == 0 || size > kChunk;
    if (size_bad) view.bad = true;
    frame.payload = read_bytes(view, size);
    const bool kind_bad = frame.kind != kKindReliable && frame.kind != kKindUnreliable;
    const bool lane_bad = frame.lane >= kCarrierLanes;
    const bool message_bad = frame.message == 0;
    const bool count_bad = frame.count == 0 || frame.count > 96 || frame.index >= frame.count;
    if (kind_bad || lane_bad || message_bad || count_bad) view.bad = true;
    if (view.bad) return false;
    frames.push_back(frame);
    return true;
}
bool parse_frames(View& view, std::vector<Frame>& frames) {
    while (!view.bad && view.at < view.buf.size()) {
        if (!push_frame(view, frames)) return false;
    }
    return !view.bad && view.at == view.buf.size();
}
bool parse_packet(std::span<const std::byte> packet, Parsed& parsed) {
    View view{.buf = packet, .at = 0, .bad = false};
    const std::uint8_t version = read_u8(view);
    parsed.flags = read_u8(view);
    parsed.number = read_u16(view);
    const bool version_bad = version != kVersion || parsed.number == 0;
    const bool missing_stop = (parsed.flags & kFlagStop) == 0;
    const std::uint8_t unknown = foreign_flags(parsed.flags);
    const bool flags_bad = missing_stop || unknown != 0;
    if (version_bad || flags_bad) view.bad = true;
    parsed.stop_before = read_u16(view);
    parsed.has_ack = (parsed.flags & kFlagAck) != 0;
    if (parsed.has_ack) {
        parsed.ack_newest = read_u16(view);
        const std::uint16_t span = read_u16(view);
        if (span != kAckSpan || parsed.ack_newest == 0) view.bad = true;
        const std::span<const std::byte> raw = read_bytes(view, kAckBytes);
        if (!view.bad) copy_bytes(std::span<std::byte>{parsed.ack_bits}, raw);
    }
    const std::uint16_t frame_bytes = read_u16(view);
    if (view.bad) return false;
    const bool short_body = view.buf.size() - view.at != frame_bytes;
    if (short_body) return false;
    return parse_frames(view, parsed.frames);
}

} // namespace game::net::detail
