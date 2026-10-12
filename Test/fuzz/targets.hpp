// Năm đích fuzz của protocol (DE-BAI P2 đợt 2 §3.8), dùng chung cho fuzz tầng một
// (tests/protocol_fuzz_tests.cpp) và năm harness libFuzzer tầng hai (tests/fuzz/fuzz_*.cpp). Mỗi
// đích nhận byte bất kỳ và trả kBroken khi một bất biến bị phá: tin giải mã được thì mã hoá lại
// phải ra đúng byte khung cũ; kênh không giữ quá trần hộp nhận, không trả thân quá max_body; khung
// hợp lệ xếp vào hộp gửi thì hộp giữ đúng byte ấy. Sập, tràn hay UB thì sanitizer bắt.
// Nguồn: TLBB Dev tests/protocol_fuzz_test.cpp (đích peek_frame, đích giải mã theo chiều).
// Khác gốc: đích giải mã đòi mã hoá lại ra đúng byte; thêm đích kênh với hai bộ trần và hộp gửi.
#pragma once

#include "protocol/channel.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string_view>
#include <variant>
#include <vector>

namespace game::fuzz {

using protocol::ByteView;
using protocol::Channel;
using Limits = protocol::ChannelLimits;

// kSkipped: đầu vào bị từ chối đúng cách, không có gì để so. kAccepted: đã đi hết đường và khớp.
enum class Verdict : std::uint8_t { kSkipped = 1, kAccepted, kBroken };

// Mã hoá lại một tin đã giải mã; mã hoá lỗi thì trả rỗng, không bao giờ khớp một khung.
template <typename Message>
[[nodiscard]] std::vector<std::byte> reencode(const Message& message) {
    std::vector<std::byte> out;
    const auto put = [&out](const auto& alternative) { return protocol::encode(out, alternative); };
    if (!std::visit(put, message)) {
        out.clear();
    }
    return out;
}

// Khung đầu tiên của đầu vào qua một bộ giải mã. Byte sau khung bị bỏ qua.
template <typename Decode>
[[nodiscard]] Verdict roundtrip(Decode decode, ByteView input, std::size_t max_body) {
    const protocol::FrameResult peeked = protocol::peek_frame(input, max_body);
    if (!peeked || !peeked->has_value()) {
        return Verdict::kSkipped;
    }
    const protocol::Frame frame = **peeked;
    const std::size_t size = protocol::kHeaderBytes + frame.body_bytes;
    if (input.size() < size) {
        return Verdict::kSkipped;
    }
    const auto decoded = decode(frame, input.subspan(protocol::kHeaderBytes, frame.body_bytes));
    if (!decoded) {
        return Verdict::kSkipped;
    }
    const bool same = std::ranges::equal(reencode(*decoded), input.first(size));
    return same ? Verdict::kAccepted : Verdict::kBroken;
}

// Một lần lấy khung khỏi kênh: kAccepted là còn khung, kSkipped là hết khung hoặc kênh đã hỏng.
[[nodiscard]] inline Verdict take(Channel& channel, const Limits& limits) {
    const protocol::NextFrame next = channel.next();
    if (channel.inbox_held() > limits.inbox_bytes) {
        return Verdict::kBroken;
    }
    if (!next || !next->has_value()) {
        return Verdict::kSkipped;
    }
    return (*next)->body.size() > limits.max_body ? Verdict::kBroken : Verdict::kAccepted;
}

[[nodiscard]] inline bool drain(Channel& channel, const Limits& limits) {
    Verdict verdict = Verdict::kAccepted;
    while (verdict == Verdict::kAccepted) {
        verdict = take(channel, limits);
    }
    return verdict != Verdict::kBroken;
}

[[nodiscard]] inline bool give(protocol::Channel& channel, ByteView chunk, const protocol::ChannelLimits& limits) {
    if (!channel.receive(chunk)) {
        return channel.inbox_held() <= limits.inbox_bytes;
    }
    if (channel.inbox_held() > limits.inbox_bytes) {
        return false;
    }
    return drain(channel, limits);
}

// Cấp đầu vào vào một kênh theo mẩu 1 tới 13 byte (định theo độ dài), lấy hết khung sau mỗi mẩu.
[[nodiscard]] inline bool feed(ByteView input, const Limits& limits) {
    Channel channel{limits};
    const std::size_t piece = 1 + (input.size() % 13);
    bool held = true;
    for (std::size_t start = 0; held && start < input.size(); start += piece) {
        held = give(channel, input.subspan(start, std::min(piece, input.size() - start)), limits);
    }
    return held;
}

// Đầu vào là đúng một khung thì xếp vào hộp gửi vừa khít hai lần: lần đầu vào và hộp giữ đúng byte
// ấy, lần hai là kOutboxFull và hộp giữ nguyên.
[[nodiscard]] inline Verdict queue_whole(ByteView input) {
    const protocol::FrameResult peeked = protocol::peek_frame(input, protocol::kMaxBodyBytes);
    if (!peeked || !peeked->has_value()) {
        return Verdict::kSkipped;
    }
    if (protocol::kHeaderBytes + (*peeked)->body_bytes != input.size()) {
        return Verdict::kSkipped;
    }
    Limits limits;
    limits.outbox_bytes = input.size();
    Channel channel{limits};
    const bool first = channel.queue(input).has_value();
    const bool second = channel.queue(input).has_value();
    const bool same = std::ranges::equal(channel.outgoing(), input);
    return first && !second && same ? Verdict::kAccepted : Verdict::kBroken;
}

// Đích peek_frame cùng kênh: trần mặc định của server và trần của kết nối client.
[[nodiscard]] inline Verdict frame(ByteView input) {
    Limits client;
    client.inbox_bytes = protocol::kHeaderBytes + protocol::kClientBodyBytes;
    client.max_body = protocol::kClientBodyBytes;
    if (!feed(input, Limits{}) || !feed(input, client)) {
        return Verdict::kBroken;
    }
    return queue_whole(input);
}

[[nodiscard]] inline Verdict game_client(ByteView input) {
    return roundtrip(&protocol::decode_game_client, input, protocol::kClientBodyBytes);
}

[[nodiscard]] inline Verdict game_server(ByteView input) {
    return roundtrip(&protocol::decode_game_server, input, protocol::kMaxBodyBytes);
}

[[nodiscard]] inline Verdict auth_client(ByteView input) {
    return roundtrip(&protocol::decode_auth_client, input, protocol::kClientBodyBytes);
}

[[nodiscard]] inline Verdict auth_server(ByteView input) {
    return roundtrip(&protocol::decode_auth_server, input, protocol::kMaxBodyBytes);
}

struct Target {
    std::string_view name;
    Verdict (*check)(ByteView input) = nullptr;
};

inline constexpr std::array<Target, 5> kTargets{Target{.name = "frame", .check = &frame},
    Target{.name = "game_client", .check = &game_client}, Target{.name = "game_server", .check = &game_server},
    Target{.name = "auth_client", .check = &auth_client}, Target{.name = "auth_server", .check = &auth_server}};

} // namespace game::fuzz
