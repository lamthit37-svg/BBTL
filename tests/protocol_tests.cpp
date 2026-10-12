// Tầng byte và kênh: byte viết tay cho từng kiểu ở giá trị biên, mỗi WireError có ca sinh ra nó,
// UTF-8 sai bị từ chối hai chiều, peek_frame ở mọi độ dài đầu, kênh nhận từng byte và hai trần.
#include "core/check.hpp"
#include "protocol/channel.hpp"
#include "protocol/wire.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

namespace protocol = game::protocol;
using protocol::ByteView;
using protocol::ChannelError;
using protocol::Reader;
using protocol::WireError;
using protocol::Writer;
using Bytes = std::vector<std::byte>;

constexpr std::uint16_t kKind = 0x0101;

[[nodiscard]] Bytes raw(std::initializer_list<unsigned> values) {
    Bytes out;
    for (const unsigned value : values)
        out.push_back(static_cast<std::byte>(value));
    return out;
}

[[nodiscard]] Bytes joined(Bytes head, const Bytes& tail) {
    head.insert(head.end(), tail.begin(), tail.end());
    return head;
}

[[nodiscard]] Bytes chars(std::string_view text) {
    const ByteView view = std::as_bytes(std::span{text});
    return {view.begin(), view.end()};
}

// Thân text trên dây: u16 số byte rồi các byte, tính tay cho chuỗi ngắn hơn 256 byte.
[[nodiscard]] Bytes text_body(std::string_view text) {
    return joined(raw({static_cast<unsigned>(text.size()), 0}), chars(text));
}

// Thân do write ghi, sau khi kiểm finish thành công và đầu khung đúng số byte, mã tin, cờ 0.
template <class Write>
[[nodiscard]] std::optional<Bytes> body_of(Write write) {
    Bytes out;
    Writer writer{out};
    write(writer);
    if (!writer.finish(kKind) || out.size() < protocol::kHeaderBytes) return std::nullopt;
    const ByteView body = ByteView{out}.subspan(protocol::kHeaderBytes);
    const auto size = static_cast<unsigned>(body.size());
    const Bytes header = raw({size & 0xFFU, (size >> 8U) & 0xFFU, size >> 16U, 0, 1, 1, 0, 0});
    if (!std::ranges::equal(ByteView{out}.first(protocol::kHeaderBytes), header)) return {};
    return Bytes{body.begin(), body.end()};
}

// Lỗi finish trả sau khi write ghi; out phải về đúng cỡ lúc tạo Writer.
template <class Write>
[[nodiscard]] std::optional<WireError> write_error(Write write) {
    Bytes out = raw({0xAA});
    Writer writer{out};
    write(writer);
    const protocol::WireStatus status = writer.finish(kKind);
    if (status || out != raw({0xAA})) return std::nullopt;
    return status.error();
}

[[nodiscard]] std::optional<WireError> read_error(const Reader& reader) {
    const protocol::WireStatus status = reader.finish();
    return status ? std::nullopt : std::optional{status.error()};
}

// Lỗi khi ghi một text với trần 64 byte; nullopt khi ghi được.
[[nodiscard]] std::optional<WireError> text_error(std::string_view text) {
    return write_error([&](Writer& out) { out.text(text, 64); });
}

// Kết quả có lỗi đúng loại: dùng chung cho FrameResult, ChannelStatus và NextFrame.
[[nodiscard]] bool failed(const auto& result, auto error) {
    return !result.has_value() && result.error() == error;
}

void header_golden(Context& context) {
    Bytes out = raw({0x77});
    Writer writer{out};
    writer.u16(0x0102);
    context.expect(writer.finish(0x8105).has_value(), "finish thành công");
    context.expect(out == raw({0x77, 2, 0, 0, 0, 0x05, 0x81, 0, 0, 0x02, 0x01}), "đầu khung");
    std::vector<std::byte> empty;
    Writer none{empty};
    context.expect(none.finish(0x0102).has_value() && empty == raw({0, 0, 0, 0, 2, 1, 0, 0}), "thân 0 byte");
}

void unsigned_golden(Context& context) {
    const auto body = body_of([](Writer& out) {
        out.u8(0);
        out.u8(0xFF);
        out.u16(0);
        out.u16(0xFFFF);
        out.u32(0x01020304);
        out.u32(0xFFFF'FFFFU);
        out.u64(0x0102'0304'0506'0708U);
        out.u64(std::numeric_limits<std::uint64_t>::max());
    });
    const Bytes expected = raw({0x00, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0x04, 0x03, 0x02, 0x01, 0xFF, 0xFF, 0xFF, 0xFF,
        0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF});
    context.expect(body == expected, "byte của u8, u16, u32, u64");
    Reader reader{expected};
    context.expect(reader.u8() == 0 && reader.u8() == 0xFF, "đọc u8");
    context.expect(reader.u16() == 0 && reader.u16() == 0xFFFF, "đọc u16");
    context.expect(reader.u32() == 0x01020304 && reader.u32() == 0xFFFF'FFFFU, "đọc u32");
    context.expect(reader.u64() == 0x0102'0304'0506'0708U, "đọc u64");
    context.expect(reader.u64() == std::numeric_limits<std::uint64_t>::max(), "đọc u64 lớn nhất");
    context.expect(reader.finish().has_value(), "đọc hết thân");
}

void signed_golden(Context& context) {
    const auto body = body_of([](Writer& out) {
        out.i8(-128);
        out.i8(-1);
        out.i8(127);
        out.i16(std::numeric_limits<std::int16_t>::min());
        out.i16(-1);
        out.i32(std::numeric_limits<std::int32_t>::min());
        out.i32(0);
        out.i64(std::numeric_limits<std::int64_t>::min());
        out.i64(-1);
    });
    const Bytes expected = raw({0x80, 0xFF, 0x7F, 0x00, 0x80, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF});
    context.expect(body == expected, "byte của i8, i16, i32, i64");
    Reader reader{expected};
    context.expect(reader.i8() == -128 && reader.i8() == -1 && reader.i8() == 127, "đọc i8");
    context.expect(reader.i16() == std::numeric_limits<std::int16_t>::min(), "đọc i16 nhỏ nhất");
    context.expect(reader.i16() == -1, "đọc i16 -1");
    context.expect(reader.i32() == std::numeric_limits<std::int32_t>::min(), "đọc i32 nhỏ nhất");
    context.expect(reader.i32() == 0, "đọc i32 0");
    context.expect(reader.i64() == std::numeric_limits<std::int64_t>::min(), "đọc i64 nhỏ nhất");
    context.expect(reader.i64() == -1 && reader.finish().has_value(), "đọc i64 -1");
}

void float_bool_golden(Context& context) {
    const auto body = body_of([](Writer& out) {
        out.f32(0.0F);
        out.f32(-0.0F);
        out.f32(1.0F);
        out.f32(std::numeric_limits<float>::max());
        out.f32(std::numeric_limits<float>::lowest());
        out.boolean(false);
        out.boolean(true);
    });
    const Bytes expected = raw({0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x80, 0x3F, 0xFF, 0xFF,
        0x7F, 0x7F, 0xFF, 0xFF, 0x7F, 0xFF, 0x00, 0x01});
    context.expect(body == expected, "byte của f32 và bool");
    Reader reader{expected};
    context.expect(std::bit_cast<std::uint32_t>(reader.f32()) == 0, "đọc 0");
    context.expect(std::bit_cast<std::uint32_t>(reader.f32()) == 0x8000'0000U, "đọc -0 giữ dấu");
    context.expect(std::bit_cast<std::uint32_t>(reader.f32()) == 0x3F80'0000U, "đọc 1");
    context.expect(std::bit_cast<std::uint32_t>(reader.f32()) == 0x7F7F'FFFFU, "đọc lớn nhất");
    context.expect(std::bit_cast<std::uint32_t>(reader.f32()) == 0xFF7F'FFFFU, "đọc nhỏ nhất");
    context.expect(!reader.boolean() && reader.boolean() && reader.finish().has_value(), "bool");
}

// "ệ" là ba byte E1 BB 87: mười lần là 30 byte, dài đúng trần 30.
void text_bytes_count_golden(Context& context) {
    const std::string longest = "ệệệệệệệệệệ";
    const std::array payload{std::byte{1}, std::byte{0xFE}, std::byte{3}};
    const auto body = body_of([&](Writer& out) {
        out.text("", 0);
        out.text("Aé", 3);
        out.text(longest, 30);
        out.bytes(payload);
        out.count(0, 0);
        out.count(0xFFFF, 0xFFFF);
    });
    Bytes expected = raw({0x00, 0x00, 0x03, 0x00, 0x41, 0xC3, 0xA9, 0x1E, 0x00});
    for (int i = 0; i < 10; ++i)
        expected = joined(expected, raw({0xE1, 0xBB, 0x87}));
    expected = joined(expected, raw({0x01, 0xFE, 0x03, 0x00, 0x00, 0xFF, 0xFF}));
    context.expect(body == expected, "byte của text, bytes, count");
    expected.resize(expected.size() - 4);
    Reader reader{expected};
    context.expect(reader.text(0).empty() && reader.text(3) == "Aé", "đọc text ngắn");
    context.expect(reader.text(30) == longest, "đọc text dài đúng trần");
    std::array<std::byte, 3> got{};
    reader.bytes(got);
    context.expect(got == payload && reader.finish().has_value(), "đọc bytes");
}

void too_long_both_ways(Context& context) {
    const std::string over(0x1'0000, 'a');
    const auto text = write_error([](Writer& out) { out.text("abcde", 4); });
    context.expect(text == WireError::kTooLong, "ghi text quá trần");
    const auto huge = write_error([&](Writer& out) { out.text(over, over.size()); });
    context.expect(huge == WireError::kTooLong, "ghi text quá 65535 byte");
    const auto list = write_error([](Writer& out) { out.count(11, 10); });
    context.expect(list == WireError::kTooLong, "ghi count quá trần");
    const Bytes body = joined(text_body("abcde"), raw({0x0B, 0x00}));
    Reader reader{body};
    context.expect(reader.text(4).empty() && read_error(reader) == WireError::kTooLong, "text");
    Reader counted{ByteView{body}.subspan(7)};
    context.expect(counted.count(10) == 0 && read_error(counted) == WireError::kTooLong, "count");
}

// Số phần tử khai vượt số byte còn lại: không cấp phát theo số khai được, báo thiếu byte ngay.
void count_beyond_body_is_truncated(Context& context) {
    const Bytes body = raw({0xFF, 0xFF, 0x01});
    Reader reader{body};
    context.expect(reader.count(0xFFFF) == 0 && read_error(reader) == WireError::kTruncated, "dư");
    const Bytes one = raw({0x01, 0x00, 0x07});
    Reader fits{one};
    context.expect(fits.count(1) == 1 && fits.u8() == 7 && fits.finish().has_value(), "vừa thân");
}

void truncated_is_sticky(Context& context) {
    const Bytes body = raw({0x01, 0x02});
    Reader reader{ByteView{body}.first(1)};
    context.expect(reader.u16() == 0 && !reader.is_ok() && reader.u8() == 0, "lỗi dính");
    context.expect(read_error(reader) == WireError::kTruncated, "finish trả kTruncated");
    const Bytes short_text = raw({0x05, 0x00, 0x41});
    Reader text{short_text};
    context.expect(text.text(10).empty() && read_error(text) == WireError::kTruncated, "text");
    Reader empty{ByteView{}};
    context.expect(empty.u64() == 0 && read_error(empty) == WireError::kTruncated, "thân rỗng");
}

void trailing_bytes(Context& context) {
    const Bytes body = raw({0x01, 0x02});
    Reader reader{body};
    context.expect(reader.u8() == 1 && read_error(reader) == WireError::kTrailingBytes, "thừa");
}

void non_finite_both_ways(Context& context) {
    constexpr float kInfinity = std::numeric_limits<float>::infinity();
    const auto nan = write_error([](Writer& out) { out.f32(std::nanf("")); });
    context.expect(nan == WireError::kNonFinite, "ghi NaN");
    const auto inf = write_error([&](Writer& out) { out.f32(-kInfinity); });
    context.expect(inf == WireError::kNonFinite, "ghi âm vô cực");
    for (const Bytes& body :
        {raw({0, 0, 0xC0, 0x7F}), raw({0, 0, 0x80, 0x7F}), raw({0, 0, 0x80, 0xFF}), raw({1, 0, 0x80, 0x7F})}) {
        Reader reader{body};
        context.expect(std::bit_cast<std::uint32_t>(reader.f32()) == 0, "trả 0");
        context.expect(read_error(reader) == WireError::kNonFinite, "đọc NaN hay vô cực");
    }
}

void bad_bool_is_bad_enum(Context& context) {
    for (const Bytes& body : {raw({0x02}), raw({0xFF})}) {
        Reader reader{body};
        context.expect(!reader.boolean() && read_error(reader) == WireError::kBadEnum, "bool");
    }
}

constexpr auto kBadUtf8 = std::to_array<std::string_view>({"\xC0\x80", "\xC1\xBF", "\xE0\x80\x80", "\xE0\x9F\xBF",
    "\xED\xA0\x80", "\xED\xBF\xBF", "\xF4\x90\x80\x80", "\xF5\x80\x80\x80", "\x80", "a\xBF", "\xE1\xBB", "\xF0\x9F\x98",
    std::string_view{"a\0b", 3}, std::string_view{"\0", 1}, "\xF0\x80\x80\x80", "\xC3\xA9\xFF"});
constexpr auto kGoodUtf8 =
    std::to_array<std::string_view>({"a", "\x7F", "\xC2\x80", "\xDF\xBF", "\xE0\xA0\x80", "\xED\x9F\xBF",
        "\xEE\x80\x80", "\xEF\xBF\xBF", "\xF0\x90\x80\x80", "\xF0\x9F\x98\x80", "\xF4\x8F\xBF\xBF", "Thiên Long"});

void utf8_rejected_both_ways(Context& context) {
    for (const std::string_view text : kBadUtf8) {
        context.expect(text_error(text) == WireError::kBadText, "ghi UTF-8 sai");
        const Bytes body = text_body(text);
        Reader reader{body};
        context.expect(reader.text(64).empty() && read_error(reader) == WireError::kBadText, "đọc");
    }
}

void utf8_accepted_both_ways(Context& context) {
    for (const std::string_view text : kGoodUtf8) {
        context.expect(!text_error(text).has_value(), "ghi UTF-8 đúng");
        const Bytes wire = text_body(text);
        Reader reader{wire};
        context.expect(reader.text(64) == text && reader.finish().has_value(), "đọc UTF-8 đúng");
    }
}

void writer_failure_is_sticky(Context& context) {
    Bytes out = raw({0x55, 0x66});
    Writer writer{out};
    writer.u8(1);
    writer.fail(WireError::kOutOfRange);
    const std::size_t size = out.size();
    writer.u32(7);
    writer.text("abc", 8);
    writer.fail(WireError::kBadEnum);
    context.expect(out.size() == size && !writer.is_ok(), "sau lỗi không ghi thêm");
    const protocol::WireStatus status = writer.finish(kKind);
    context.expect(!status && status.error() == WireError::kOutOfRange, "giữ lỗi đầu tiên");
    context.expect(out == raw({0x55, 0x66}), "cắt về cỡ lúc tạo");
    const auto unknown = write_error([](Writer& out2) { out2.fail(WireError::kUnknownKind); });
    context.expect(unknown == WireError::kUnknownKind, "fail kUnknownKind qua finish");
    for (const WireError error : {WireError::kUnknownKind, WireError::kOutOfRange}) {
        Reader reader{ByteView{}};
        reader.fail(error);
        context.expect(reader.u8() == 0 && read_error(reader) == error, "Reader giữ lỗi");
    }
}

void body_too_large_both_ways(Context& context) {
    const Bytes big(protocol::kMaxBodyBytes, std::byte{1});
    const auto fits = body_of([&](Writer& out) { out.bytes(big); });
    context.expect(fits.has_value() && fits->size() == big.size(), "thân đúng 65536 byte");
    const auto over = write_error([&](Writer& out) {
        out.bytes(big);
        out.u8(0);
    });
    context.expect(over == WireError::kBodyTooLarge, "ghi thân 65537 byte");
    const Bytes header = raw({0x01, 0x10, 0, 0, 1, 1, 0, 0});
    const auto client = protocol::peek_frame(header, protocol::kClientBodyBytes);
    context.expect(failed(client, WireError::kBodyTooLarge), "4097 với trần 4096");
    const Bytes wide = raw({0x01, 0, 0x01, 0, 1, 1, 0, 0});
    const auto clamp = protocol::peek_frame(wide, std::numeric_limits<std::size_t>::max());
    context.expect(failed(clamp, WireError::kBodyTooLarge), "trần không quá 65536");
    const Bytes huge = raw({0xFF, 0xFF, 0xFF, 0xFF, 1, 1, 0, 0});
    const auto all = protocol::peek_frame(huge, protocol::kMaxBodyBytes);
    context.expect(failed(all, WireError::kBodyTooLarge), "thân khai 0xFFFFFFFF");
}

[[nodiscard]] bool no_frame(const protocol::FrameResult& result) {
    return result.has_value() && !result->has_value();
}

// peek_frame trả một khung đủ có đúng loại và độ dài thân.
[[nodiscard]] bool is_frame(const protocol::FrameResult& got, unsigned kind, std::size_t size) {
    return got && *got && (*got)->kind == kind && (*got)->body_bytes == size;
}

void peek_every_header_length(Context& context) {
    const Bytes good = raw({0x02, 0, 0, 0, 0x02, 0x01, 0, 0, 0xAA, 0xBB});
    const Bytes flags = raw({0x00, 0, 0, 0, 0x02, 0x01, 0x01, 0});
    const Bytes large = raw({0x01, 0x10, 0, 0, 0x02, 0x01, 0, 0});
    for (std::size_t size = 0; size < protocol::kHeaderBytes; ++size) {
        context.expect(no_frame(protocol::peek_frame(ByteView{good}.first(size), 16)), "đúng");
        context.expect(no_frame(protocol::peek_frame(ByteView{flags}.first(size), 16)), "cờ");
        context.expect(no_frame(protocol::peek_frame(ByteView{large}.first(size), 4096)), "trần");
    }
    context.expect(no_frame(protocol::peek_frame(ByteView{good}.first(9), 16)), "thiếu thân");
    context.expect(failed(protocol::peek_frame(flags, 16), WireError::kBadFlags), "cờ 1");
    context.expect(failed(protocol::peek_frame(large, 4096), WireError::kBodyTooLarge), "4097");
    context.expect(is_frame(protocol::peek_frame(good, 2), 0x0102, 2), "khung đủ");
    const Bytes high = raw({0, 0, 0, 0, 0x02, 0x01, 0, 0x80});
    context.expect(failed(protocol::peek_frame(high, 16), WireError::kBadFlags), "cờ 0x8000");
}

// Byte mẫu Hello của Dev: phiên bản 1, nền tảng 2, bản dựng 0x01020304.
void dev_hello_sample(Context& context) {
    const Bytes wire = raw({7, 0, 0, 0, 1, 1, 0, 0, 1, 0, 2, 4, 3, 2, 1});
    const auto frame = protocol::peek_frame(wire, protocol::kClientBodyBytes);
    context.expect(is_frame(frame, 0x0101, 7), "đầu khung");
    Reader reader{ByteView{wire}.subspan(protocol::kHeaderBytes)};
    context.expect(reader.u16() == 1 && reader.u8() == 2 && reader.u32() == 0x01020304, "thân");
    context.expect(reader.finish().has_value(), "đọc hết thân");
    const auto body = body_of([](Writer& out) {
        out.u16(1);
        out.u8(2);
        out.u32(0x01020304);
    });
    context.expect(body && joined(raw({7, 0, 0, 0, 1, 1, 0, 0}), *body) == wire, "mã hoá lại");
}

constexpr protocol::ChannelLimits kSmall{.inbox_bytes = 24, .outbox_bytes = 20, .max_body = 16};

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

// Lấy khung kế nếu đã đủ byte; false khi kênh báo lỗi.
[[nodiscard]] bool take_frame(protocol::Channel& channel, Seen& seen) {
    const protocol::NextFrame frame = channel.next();
    if (!frame) return false;
    if (!frame->has_value()) return true;
    seen.kinds.push_back((*frame)->kind);
    seen.bodies.insert(seen.bodies.end(), (*frame)->body.begin(), (*frame)->body.end());
    return true;
}

void channel_byte_by_byte(Context& context) {
    const Bytes stream =
        joined(joined(frame_of(0x0101, raw({1, 2, 3})), frame_of(0x0102, {})), frame_of(0x8101, raw({9})));
    protocol::Channel channel{protocol::ChannelLimits{}};
    Seen seen;
    for (const std::byte& one : stream) {
        context.expect(channel.receive(std::span{&one, 1}).has_value(), "nhận một byte");
        context.expect(take_frame(channel, seen), "lấy khung không lỗi");
    }
    context.expect(seen.kinds == std::vector<std::uint16_t>{0x0101, 0x0102, 0x8101}, "ba khung");
    context.expect(seen.bodies == raw({1, 2, 3, 9}), "thân đúng thứ tự");
    const protocol::NextFrame rest = channel.next();
    context.expect(rest && !rest->has_value() && channel.inbox_held() == 0, "không còn byte");
}

void channel_inbox_limit(Context& context) {
    protocol::Channel channel{kSmall};
    const Bytes fill(24, std::byte{0});
    context.expect(channel.receive(fill).has_value() && channel.inbox_held() == 24, "đúng trần");
    context.expect(failed(channel.receive(raw({0})), ChannelError::kInboxFull), "vượt một byte");
    context.expect(channel.inbox_held() == 24, "không giữ thêm");
    context.expect(failed(channel.next(), ChannelError::kInboxFull), "kênh hỏng");
    protocol::Channel fresh{kSmall};
    const auto chunk = fresh.receive(Bytes(25, std::byte{0}));
    context.expect(!chunk && fresh.inbox_held() == 0, "một mẩu quá trần không giữ byte nào");
}

void channel_outbox_limit(Context& context) {
    protocol::Channel channel{kSmall};
    const Bytes frame = frame_of(0x8101, raw({1, 2}));
    context.expect(channel.queue(frame).has_value() && channel.queue(frame).has_value(), "20");
    context.expect(failed(channel.queue(frame), ChannelError::kOutboxFull), "vượt trần");
    context.expect(channel.outgoing().size() == 20, "hộp gửi giữ nguyên");
    channel.mark_sent(10);
    context.expect(channel.queue(frame).has_value(), "gửi bớt thì thêm được");
    context.expect(std::ranges::equal(channel.outgoing(), joined(frame, frame)), "đúng thứ tự");
    channel.mark_sent(20);
    context.expect(channel.outgoing().empty(), "gửi hết");
}

void channel_broken_frame_is_final(Context& context) {
    protocol::Channel channel{kSmall};
    context.expect(channel.receive(raw({0, 0, 0, 0, 1, 1, 1, 0})).has_value(), "nhận đầu");
    context.expect(failed(channel.next(), ChannelError::kBadFlags), "cờ 1");
    context.expect(failed(channel.next(), ChannelError::kBadFlags), "lần hai");
    context.expect(failed(channel.receive(raw({0})), ChannelError::kBadFlags), "nhận sau hỏng");
    protocol::Channel client{protocol::ChannelLimits{.max_body = protocol::kClientBodyBytes}};
    context.expect(client.receive(raw({0x01, 0x10, 0, 0, 1, 1, 0, 0})).has_value(), "8 byte");
    context.expect(failed(client.next(), ChannelError::kBodyTooLarge), "4097");
}

void channel_error_wraps_wire(Context& context) {
    for (unsigned value = 1; value <= 10; ++value) {
        const auto wire = static_cast<WireError>(value);
        context.expect(protocol::unwrap(protocol::wrap(wire)) == wire, "bọc rồi mở");
        context.expect(protocol::describe(protocol::wrap(wire)) == protocol::describe(wire), "câu");
        context.expect(!protocol::describe(wire).empty(), "câu của WireError");
    }
    context.expect(!protocol::unwrap(ChannelError::kInboxFull), "kInboxFull riêng");
    context.expect(!protocol::unwrap(ChannelError::kOutboxFull), "kOutboxFull riêng");
}

constexpr std::array kCases{
    Case{.name = "header_golden", .body = &header_golden},
    Case{.name = "unsigned_golden", .body = &unsigned_golden},
    Case{.name = "signed_golden", .body = &signed_golden},
    Case{.name = "float_bool_golden", .body = &float_bool_golden},
    Case{.name = "text_bytes_count_golden", .body = &text_bytes_count_golden},
    Case{.name = "too_long_both_ways", .body = &too_long_both_ways},
    Case{.name = "count_beyond_body_is_truncated", .body = &count_beyond_body_is_truncated},
    Case{.name = "truncated_is_sticky", .body = &truncated_is_sticky},
    Case{.name = "trailing_bytes", .body = &trailing_bytes},
    Case{.name = "non_finite_both_ways", .body = &non_finite_both_ways},
    Case{.name = "bad_bool_is_bad_enum", .body = &bad_bool_is_bad_enum},
    Case{.name = "utf8_rejected_both_ways", .body = &utf8_rejected_both_ways},
    Case{.name = "utf8_accepted_both_ways", .body = &utf8_accepted_both_ways},
    Case{.name = "writer_failure_is_sticky", .body = &writer_failure_is_sticky},
    Case{.name = "body_too_large_both_ways", .body = &body_too_large_both_ways},
    Case{.name = "peek_every_header_length", .body = &peek_every_header_length},
    Case{.name = "dev_hello_sample", .body = &dev_hello_sample},
    Case{.name = "channel_byte_by_byte", .body = &channel_byte_by_byte},
    Case{.name = "channel_inbox_limit", .body = &channel_inbox_limit},
    Case{.name = "channel_outbox_limit", .body = &channel_outbox_limit},
    Case{.name = "channel_broken_frame_is_final", .body = &channel_broken_frame_is_final},
    Case{.name = "channel_error_wraps_wire", .body = &channel_error_wraps_wire},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "protocol_tests: mọi ca phải qua");
    return 0;
}
