// Test của mã sinh từ bảng danh mục (P2 đợt 2, vai C). Mỗi mẫu của protocol_samples.hpp phải mã
// hoá ra đúng byte do bộ mã hoá Python độc lập tính, giải mã lại ra đúng giá trị; thân cắt ở mọi độ
// dài là kTruncated, thừa một byte là kTrailingBytes, bộ giải mã sai cổng hoặc chiều là
// kUnknownKind. Thêm byte thật của Dev cho Hello và vài giá trị biên của enum, thời lượng.
#include "core/check.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "protocol_samples.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <span>
#include <variant>
#include <vector>

namespace {

namespace protocol = game::protocol;
namespace samples = game::test::samples;
using game::test::Context;
using protocol::WireError;
using samples::Sample;

[[nodiscard]] std::vector<std::byte> to_bytes(std::span<const std::uint8_t> data) {
    std::vector<std::byte> out;
    out.reserve(data.size());
    for (const std::uint8_t value : data)
        out.push_back(static_cast<std::byte>(value));
    return out;
}

[[nodiscard]] protocol::Frame frame_of(std::uint16_t kind, protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = kind;
    frame.body_bytes = body.size();
    return frame;
}

// Kind đọc từ byte 4 và 5 của khung mẫu (little-endian).
[[nodiscard]] std::uint16_t kind_of(const Sample& sample) {
    return static_cast<std::uint16_t>(sample.frame[4] + (sample.frame[5] * 256U));
}

template <class Result>
[[nodiscard]] bool fails_with(const Result& result, WireError error) {
    return !result.has_value() && result.error() == error;
}

void encode_matches_python(Context& context) {
    for (const Sample& sample : samples::kSamples) {
        std::vector<std::byte> out;
        const protocol::WireStatus status = sample.encode(out);
        context.expect(status.has_value() && out == to_bytes(sample.frame), sample.name);
    }
}

void peek_and_decode_round_trip(Context& context) {
    for (const Sample& sample : samples::kSamples) {
        const std::vector<std::byte> frame = to_bytes(sample.frame);
        const protocol::FrameResult peeked = protocol::peek_frame(frame, protocol::kMaxBodyBytes);
        const bool whole = peeked.has_value() && peeked->has_value() && (*peeked)->kind == kind_of(sample) &&
            (*peeked)->body_bytes + protocol::kHeaderBytes == frame.size();
        const samples::Check decoded = sample.decode(protocol::ByteView{frame}.subspan(protocol::kHeaderBytes));
        context.expect(whole && decoded.has_value() && *decoded, sample.name);
    }
}

// Mọi độ dài thân ngắn hơn thân đủ của một mẫu đều là kTruncated.
void expect_truncations(Context& context, const Sample& sample) {
    const std::vector<std::byte> frame = to_bytes(sample.frame);
    const protocol::ByteView body = protocol::ByteView{frame}.subspan(protocol::kHeaderBytes);
    for (std::size_t size = 0; size < body.size(); ++size)
        context.expect(fails_with(sample.decode(body.first(size)), WireError::kTruncated), sample.name);
}

// Tổng số lần cắt trên mọi mẫu ghi trong BAO-CAO-C (T8).
void every_truncation_fails(Context& context) {
    for (const Sample& sample : samples::kSamples)
        expect_truncations(context, sample);
}

void trailing_byte_fails(Context& context) {
    for (const Sample& sample : samples::kSamples) {
        std::vector<std::byte> frame = to_bytes(sample.frame);
        frame.push_back(std::byte{0});
        const protocol::ByteView body = protocol::ByteView{frame}.subspan(protocol::kHeaderBytes);
        context.expect(fails_with(sample.decode(body), WireError::kTrailingBytes), sample.name);
    }
}

// Bộ giải mã có bit trong mặt nạ nhận tin, bộ không có bit trả kUnknownKind.
template <class Decode>
void check_decoder(Context& context, const Sample& sample, std::uint8_t bit, Decode decode) {
    const std::vector<std::byte> frame = to_bytes(sample.frame);
    const protocol::ByteView body = protocol::ByteView{frame}.subspan(protocol::kHeaderBytes);
    const auto result = decode(frame_of(kind_of(sample), body), body);
    const bool accepts = (sample.decoders & bit) != 0;
    context.expect(accepts ? result.has_value() : fails_with(result, WireError::kUnknownKind), sample.name);
}

void decoders_follow_port_and_direction(Context& context) {
    for (const Sample& sample : samples::kSamples) {
        check_decoder(context, sample, samples::kGameClient, protocol::decode_game_client);
        check_decoder(context, sample, samples::kGameServer, protocol::decode_game_server);
        check_decoder(context, sample, samples::kAuthClient, protocol::decode_auth_client);
        check_decoder(context, sample, samples::kAuthServer, protocol::decode_auth_server);
    }
}

// Byte Hello của Dev: version 1, platform 2 (Android), build 0x01020304 (T9).
constexpr std::array<std::uint8_t, 15> kDevHello{
    0x07, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x02, 0x04, 0x03, 0x02, 0x01};

void dev_hello_bytes(Context& context) {
    protocol::Hello hello;
    hello.version = 1;
    hello.platform = protocol::Platform::kAndroid;
    hello.build = 0x0102'0304;
    std::vector<std::byte> out;
    context.expect(protocol::encode(out, hello).has_value(), "encode Hello");
    context.expect(out == to_bytes(kDevHello), "byte Hello giống Dev");
    const protocol::ByteView body = protocol::ByteView{out}.subspan(protocol::kHeaderBytes);
    const protocol::GameClientResult decoded =
        protocol::decode_game_client(frame_of(protocol::Hello::kKind, body), body);
    const auto* message = decoded.has_value() ? std::get_if<protocol::Hello>(&*decoded) : nullptr;
    context.expect(message != nullptr && *message == hello, "giải mã Hello của Dev");
}

// Reject.request là u16 thô (Lệch quy tắc trong BAO-CAO-C): mã tin lạ vẫn giải mã được.
void reject_keeps_unknown_request(Context& context) {
    const std::array<std::byte, 4> body{std::byte{0xEF}, std::byte{0xBE}, std::byte{0x01}, std::byte{0x00}};
    const protocol::GameServerResult decoded =
        protocol::decode_game_server(frame_of(protocol::Reject::kKind, body), body);
    const auto* message = decoded.has_value() ? std::get_if<protocol::Reject>(&*decoded) : nullptr;
    context.expect(message != nullptr && message->request == 0xBEEF, "Reject giữ mã tin lạ");
}

void bad_enum_fails_both_ways(Context& context) {
    const std::array<std::byte, 7> body{std::byte{0x01}, std::byte{0x00}, std::byte{0x00}, std::byte{0x04},
        std::byte{0x03}, std::byte{0x02}, std::byte{0x01}};
    const protocol::GameClientResult decoded =
        protocol::decode_game_client(frame_of(protocol::Hello::kKind, body), body);
    context.expect(fails_with(decoded, WireError::kBadEnum), "giải mã platform 0");
    protocol::Hello hello;
    hello.platform = static_cast<protocol::Platform>(9);
    std::vector<std::byte> out{std::byte{0x55}};
    context.expect(fails_with(protocol::encode(out, hello), WireError::kBadEnum), "mã hoá enum lạ");
    context.expect(out.size() == 1, "lỗi thì out giữ nguyên cỡ");
}

// millis64 trên dây là u64; số trên 2^63 - 1 không vừa milliseconds nên là kOutOfRange.
void millis64_out_of_range(Context& context) {
    std::array<std::byte, 12> body{};
    body[11] = std::byte{0x80};
    const protocol::GameServerResult decoded =
        protocol::decode_game_server(frame_of(protocol::Pong::kKind, body), body);
    context.expect(fails_with(decoded, WireError::kOutOfRange), "giải mã server_time 2^63");
    protocol::Pong pong;
    pong.server_time = std::chrono::milliseconds{-1};
    std::vector<std::byte> out;
    context.expect(fails_with(protocol::encode(out, pong), WireError::kOutOfRange), "mã hoá âm");
}

constexpr std::array kCases{
    game::test::Case{.name = "mã hoá khớp byte Python", .body = &encode_matches_python},
    game::test::Case{.name = "peek_frame và giải mã lại", .body = &peek_and_decode_round_trip},
    game::test::Case{.name = "cắt ở mọi độ dài", .body = &every_truncation_fails},
    game::test::Case{.name = "thừa một byte", .body = &trailing_byte_fails},
    game::test::Case{.name = "cổng và chiều", .body = &decoders_follow_port_and_direction},
    game::test::Case{.name = "byte Hello của Dev", .body = &dev_hello_bytes},
    game::test::Case{.name = "Reject giữ mã tin lạ", .body = &reject_keeps_unknown_request},
    game::test::Case{.name = "enum lạ", .body = &bad_enum_fails_both_ways},
    game::test::Case{.name = "millis64 quá cỡ", .body = &millis64_out_of_range},
};

} // namespace

int main() {
    game::core::check(game::test::run_all(kCases) == 0, "protocol_catalog_tests: mọi ca phải qua");
    return 0;
}
