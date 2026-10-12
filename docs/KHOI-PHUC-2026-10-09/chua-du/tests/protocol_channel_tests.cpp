// Kênh: nhận từng byte, hai trần, hộp nhận chừa chỗ cho mẩu đọc kế tiếp (inbox_room), kênh hỏng là
// hỏng hẳn, lỗi kênh bọc lỗi dây theo tên. Tách từ protocol_tests.cpp để mỗi tệp không quá 500
// dòng.
#include "core/check.hpp"
#include "protocol/channel.hpp"
#include "protocol/wire.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

namespace protocol = game::protocol;
using protocol::ByteView;
using protocol::Channel;
using protocol::ChannelError;
using protocol::WireError;
using protocol::Writer;
using Bytes = std::vector<std::byte>;

[[nodiscard]] Bytes raw(std::initializer_list<unsigned> values) {
    Bytes out;
    for (const unsigned value : values) {
        out.push_back(static_cast<std::byte>(value));
    }
    return out;
}

[[nodiscard]] Bytes joined(Bytes head, const Bytes& tail) {
    head.insert(head.end(), tail.begin(), tail.end());
    return head;
}

// Kết quả có lỗi đúng loại: dùng chung cho ChannelStatus và NextFrame.
[[nodiscard]] bool failed(const auto& result, auto error) {
    return !result.has_value() && result.error() == error;
}

constexpr protocol::ChannelLimits kSmall{.inbox_bytes = 24, .outbox_bytes = 20, .max_body = 16};
// Trần client chặt của X-BA-02: đúng một khung thân 4.096 byte, không chừa gì.
constexpr protocol::ChannelLimits kTight{.inbox_bytes = 4104, .max_body = 4096};

[[nodiscard]] Bytes frame_of(std::uint16_t kind, const Bytes& body) {
    Bytes out;
    Writer writer{out};
    writer.bytes(body);
    core::check(writer.finish(kind).has_value(), "frame_of: khung mẫu phải mã hoá được");
    return out;
}

struct Seen {
    std::vector<std::uint16_t> kinds;
    Bytes bodies;
};

// Lấy khung kế: true khi lấy được, false khi còn thiếu byte, nullopt khi kênh báo lỗi.
[[nodiscard]] std::optional<bool> pull(Channel& channel, Seen& seen) {
    const protocol::NextFrame frame = channel.next();
    if (!frame) return std::nullopt;
    if (!frame->has_value()) return false;
    seen.kinds.push_back((*frame)->kind);
    seen.bodies.insert(seen.bodies.end(), (*frame)->body.begin(), (*frame)->body.end());
    return true;
}

// Rút hết khung đã đủ; false khi kênh báo lỗi.
[[nodiscard]] bool drain(Channel& channel, Seen& seen) {
    std::optional<bool> took = true;
    while (took.value_or(false)) {
        took = pull(channel, seen);
    }
    return took.has_value();
}

// Một lần nhận như bên gọi tuân bất biến: mẩu không quá chunk, không quá inbox_room(), rồi rút hết
// khung. Trả số byte đã đưa vào; 0 khi kênh báo lỗi hay không còn chỗ.
[[nodiscard]] std::size_t step(Channel& channel, ByteView rest, std::size_t chunk, Seen& seen) {
    const std::size_t size = std::min({chunk, channel.inbox_room(), rest.size()});
    if (size == 0 || !channel.receive(rest.first(size))) return 0;
    return drain(channel, seen) ? size : 0;
}

// Đưa cả luồng qua step; true khi đưa hết mà kênh không báo lỗi.
[[nodiscard]] bool feed(Channel& channel, ByteView stream, std::size_t chunk, Seen& seen) {
    std::size_t size = 1;
    while (size != 0 && !stream.empty()) {
        size = step(channel, stream, chunk, seen);
        stream = stream.subspan(size);
    }
    return stream.empty();
}

// Đưa cả luồng theo mẩu cố định chunk byte, không nhìn inbox_room(), rút hết khung sau mỗi mẩu.
[[nodiscard]] bool feed_fixed(Channel& channel, ByteView stream, std::size_t chunk, Seen& seen) {
    bool good = true;
    for (std::size_t done = 0; good && done < stream.size(); done += chunk) {
        const ByteView piece = stream.subspan(done, std::min(chunk, stream.size() - done));
        good = channel.receive(piece).has_value() && drain(channel, seen);
    }
    return good;
}

// Đầu vào của B ở X-BA-02: khung thân 4.096 byte (đầu 00 10 00 00 01 01 00 00), khung thân 0 byte,
// khung thân 1 byte.
[[nodiscard]] Bytes chunked_stream() {
    const Bytes big = frame_of(0x0101, Bytes(protocol::kClientBodyBytes, std::byte{0x5A}));
    return joined(joined(big, frame_of(0x0102, {})), frame_of(0x0103, raw({7})));
}

[[nodiscard]] bool got_chunked(const Seen& seen) {
    const bool kinds = seen.kinds == std::vector<std::uint16_t>{0x0101, 0x0102, 0x0103};
    return kinds && seen.bodies.size() == 4097 && seen.bodies.back() == std::byte{7};
}

void channel_byte_by_byte(Context& context) {
    const Bytes stream = joined(
        joined(frame_of(0x0101, raw({1, 2, 3})), frame_of(0x0102, {})), frame_of(0x8101, raw({9})));
    Channel channel{protocol::ChannelLimits{}};
    Seen seen;
    for (const std::byte& one : stream) {
        context.expect(channel.receive(std::span{&one, 1}).has_value(), "nhận một byte");
        context.expect(pull(channel, seen).has_value(), "lấy khung không lỗi");
    }
    context.expect(seen.kinds == std::vector<std::uint16_t>{0x0101, 0x0102, 0x8101}, "ba khung");
    context.expect(seen.bodies == raw({1, 2, 3, 9}), "thân đúng thứ tự");
    const protocol::NextFrame rest = channel.next();
    context.expect(rest && !rest->has_value() && channel.inbox_held() == 0, "không còn byte");
}

void channel_inbox_limit(Context& context) {
    Channel channel{kSmall};
    const Bytes fill(24, std::byte{0});
    context.expect(channel.receive(fill).has_value() && channel.inbox_held() == 24, "đúng trần");
    context.expect(channel.inbox_room() == 0, "hết chỗ");
    context.expect(failed(channel.receive(raw({0})), ChannelError::kInboxFull), "vượt một byte");
    context.expect(channel.inbox_held() == 24, "không giữ thêm");
    context.expect(failed(channel.next(), ChannelError::kInboxFull), "kênh hỏng");
    Channel fresh{kSmall};
    const auto chunk = fresh.receive(Bytes(25, std::byte{0}));
    context.expect(!chunk && fresh.inbox_held() == 0, "một mẩu quá trần không giữ byte nào");
}

// X-BA-02, trần chặt 4.104: nhận 4.100 byte, rồi mẩu 8 byte theo inbox_room() trước mỗi lần nhận.
void channel_tight_inbox_follows_room(Context& context) {
    const Bytes stream = chunked_stream();
    Channel channel{kTight};
    Seen seen;
    context.expect(channel.inbox_room() == 4104, "kênh rỗng còn đủ trần");
    context.expect(channel.receive(ByteView{stream}.first(4100)).has_value(), "nhận 4.100 byte");
    context.expect(pull(channel, seen) == false && channel.inbox_room() == 4, "chưa đủ, còn 4");
    context.expect(feed(channel, ByteView{stream}.subspan(4100), 8, seen), "không kInboxFull");
    context.expect(got_chunked(seen), "đủ ba khung, đúng thân");
    context.expect(channel.inbox_held() == 0 && channel.inbox_room() == 4104, "trả lại đủ chỗ");
}

// Khung vừa trả bởi next không chiếm chỗ của lần nhận kế tiếp.
void channel_room_skips_returned_frame(Context& context) {
    const Bytes stream = chunked_stream();
    Channel channel{kTight};
    Seen seen;
    context.expect(channel.receive(ByteView{stream}.first(4104)).has_value(), "đúng một khung");
    context.expect(pull(channel, seen) == true && channel.inbox_held() == 4104, "khung còn giữ");
    context.expect(channel.inbox_room() == 4104, "khung đã trả không tính");
    context.expect(channel.receive(ByteView{stream}.subspan(4104)).has_value(), "nhận phần sau");
    context.expect(drain(channel, seen) && got_chunked(seen), "đủ ba khung");
}

constexpr std::array<std::size_t, 8> kChunks{1, 4, 5, 8, 13, 4100, 4104, 9000};

// Mẩu đủ cỡ, vắt qua ranh giới khung ở mọi chỗ: bên gọi tuân inbox_room() thì không lỗi.
void channel_room_any_chunk(Context& context) {
    const Bytes stream = chunked_stream();
    for (const std::size_t chunk : kChunks) {
        Channel channel{kTight};
        Seen seen;
        context.expect(feed(channel, stream, chunk, seen) && got_chunked(seen), "mẩu bất kỳ");
    }
}

// Vượt trần thật vẫn là kInboxFull: đưa 8 byte khi chỉ còn 4 byte chỗ.
void channel_tight_inbox_overflow(Context& context) {
    const Bytes stream = chunked_stream();
    Channel channel{kTight};
    context.expect(channel.receive(ByteView{stream}.first(4100)).has_value(), "nhận 4.100 byte");
    const auto over = channel.receive(ByteView{stream}.subspan(4100, 8));
    context.expect(failed(over, ChannelError::kInboxFull), "8 byte khi còn 4 là vượt trần");
    context.expect(channel.inbox_held() == 4100 && channel.inbox_room() == 0, "không giữ thêm");
}

// Trần sát của kết nối giữa các máy chủ: đúng một khung thân 65.536 byte, không chừa gì.
constexpr std::size_t kServerFrameBytes = protocol::kHeaderBytes + protocol::kMaxBodyBytes;
constexpr protocol::ChannelLimits kServerTight{.inbox_bytes = kServerFrameBytes};
constexpr std::array<std::size_t, 6> kServerChunks{7, 4096, 16384, 65540, 65544, 70000};

// Khung thân lớn nhất, khung thân 0 byte, khung thân 1 byte.
[[nodiscard]] Bytes server_stream() {
    const Bytes big = frame_of(0x8101, Bytes(protocol::kMaxBodyBytes, std::byte{0x3C}));
    return joined(joined(big, frame_of(0x8102, {})), frame_of(0x8103, raw({7})));
}

[[nodiscard]] bool got_server_stream(const Seen& seen) {
    const bool kinds = seen.kinds == std::vector<std::uint16_t>{0x8101, 0x8102, 0x8103};
    return kinds && seen.bodies.size() == 65537 && seen.bodies.back() == std::byte{7};
}

// Ở trần sát của server, bên gọi tuân inbox_room() thì mẩu cỡ nào cũng không lỗi.
void channel_server_tight_any_chunk(Context& context) {
    const Bytes stream = server_stream();
    for (const std::size_t chunk : kServerChunks) {
        Channel channel{kServerTight};
        Seen seen;
        const bool fed = feed(channel, stream, chunk, seen);
        context.expect(fed && got_server_stream(seen), "trần sát của server, mẩu bất kỳ");
        context.expect(channel.inbox_room() == kServerFrameBytes, "trả lại đủ chỗ");
    }
}

// Còn 4 byte chỗ mà đưa 8 byte: vượt trần thật, kênh không giữ byte nào của lần đó.
void channel_server_tight_overflow(Context& context) {
    const Bytes stream = server_stream();
    Channel channel{kServerTight};
    context.expect(channel.inbox_room() == 65544, "kênh rỗng còn đủ trần");
    context.expect(channel.receive(ByteView{stream}.first(65540)).has_value(), "nhận 65.540 byte");
    const auto over = channel.receive(ByteView{stream}.subspan(65540, 8));
    context.expect(failed(over, ChannelError::kInboxFull), "8 byte khi còn 4 là vượt trần");
    context.expect(channel.inbox_held() == 65540 && channel.inbox_room() == 0, "không giữ thêm");
}

// Trần mặc định chừa một mẩu kReadChunkBytes: đọc theo mẩu cố định qua hai khung lớn nhất.
void channel_default_inbox_takes_read_chunk(Context& context) {
    const Bytes big = frame_of(0x0101, Bytes(protocol::kMaxBodyBytes, std::byte{1}));
    const Bytes stream = joined(joined(joined(big, frame_of(0x0102, {})), big), chunked_stream());
    Channel channel{protocol::ChannelLimits{}};
    Seen seen;
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
    Case{.name = "channel_room_skips_returned_frame", .body = &channel_room_skips_returned_frame},
    Case{.name = "channel_room_any_chunk", .body = &channel_room_any_chunk},
    Case{.name = "channel_tight_inbox_overflow", .body = &channel_tight_inbox_overflow},
    Case{.name = "channel_server_tight_any_chunk", .body = &channel_server_tight_any_chunk},
    Case{.name = "channel_server_tight_overflow", .body = &channel_server_tight_overflow},
    Case{.name = "channel_default_inbox_takes_read_chunk",
        .body = &channel_default_inbox_takes_read_chunk},
    Case{.name = "channel_outbox_limit", .body = &channel_outbox_limit},
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
