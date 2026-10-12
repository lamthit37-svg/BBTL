// Tệp sinh bởi TOOLS/server/gen_protocol.py từ src/shared/protocol/catalog/*.tsv; không sửa tay.
// Sửa bảng rồi chạy lại: python -B TOOLS/server/gen_protocol.py
// Mẫu của từng tin cho tests/protocol_catalog_tests.cpp: nhỏ nhất, lớn nhất theo mọi trần, thường gặp. Giá trị C++ và
// byte mong đợi cùng sinh từ một mẫu Python, byte do bộ mã hoá Python độc lập tính.
#pragma once

#include "protocol/messages.hpp"
#include "protocol/wire.hpp"

#include <array>
#include <bit>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <variant>
#include <vector>

namespace game::test::samples {

// Bộ giải mã nào nhận tin: mỗi bit một bộ.
inline constexpr std::uint8_t kGameClient = 1;
inline constexpr std::uint8_t kGameServer = 2;
inline constexpr std::uint8_t kAuthClient = 4;
inline constexpr std::uint8_t kAuthServer = 8;

using Check = std::expected<bool, protocol::WireError>;
// Bộ đệm ghi của hàm mã hoá mẫu; tên ngắn để chữ ký nằm trọn một dòng (AGENTS.md mục 7).
using Buffer = std::vector<std::byte>;

// Một mẫu: khung đầy đủ do Python tính, hàm mã hoá giá trị C++ của mẫu, hàm giải mã thân bằng bộ
// giải mã đầu tiên nhận tin rồi so với giá trị mẫu.
struct Sample {
    std::string_view name;
    std::span<const std::uint8_t> frame;
    protocol::WireStatus (*encode)(Buffer& out) = nullptr;
    Check (*decode)(protocol::ByteView body) = nullptr;
    std::uint8_t decoders = 0;
};

// Mảng N byte, byte thứ i là (start + i * step) mod 256; cùng công thức với protocol_wire.py.
template <std::size_t N>
[[nodiscard]] std::array<std::byte, N> pattern(std::uint8_t start, std::uint8_t step) {
    std::array<std::byte, N> out{};
    for (std::size_t i = 0; i < N; ++i) {
        out.at(i) = static_cast<std::byte>((start + (i * step)) & 0xFFU);
    }
    return out;
}

// Chữ đúng bytes byte UTF-8, xen chữ 1, 2, 3, 4 byte rồi bù bằng 'a'; cùng thuật toán với
// fill_text của protocol_wire.py, nên mẫu lớn nhất chạm đúng trần.
[[nodiscard]] inline std::string wide_text(std::size_t bytes) {
    constexpr std::array<std::string_view, 4> kParts{"A", "\xC3\xA9", "\xE1\xBB\x87", "\xF0\xA0\x80\x80"};
    std::string out;
    std::size_t index = 0;
    while (out.size() + kParts.at(index % 4).size() <= bytes) {
        out += kParts.at(index++ % 4);
    }
    out.append(bytes - out.size(), 'a');
    return out;
}

// Kết quả giải mã giữ đúng kiểu Message và bằng giá trị mong đợi.
template <class Message, class Result>
[[nodiscard]] Check holds(const Result& result, const Message& wanted) {
    if (!result) return std::unexpected(result.error());
    const auto* message = std::get_if<Message>(&*result);
    return message != nullptr && *message == wanted;
}

[[nodiscard]] inline protocol::CharacterSummary character_summary_min() {
    protocol::CharacterSummary value;
    value.id = 0U;
    value.level = 0U;
    value.gender = protocol::Gender::kFemale;
    value.face = 0U;
    value.hair = 0U;
    value.school = 0U;
    value.scene = 0U;
    return value;
}

[[nodiscard]] inline protocol::CharacterSummary character_summary_max() {
    protocol::CharacterSummary value;
    value.id = 18446744073709551615U;
    value.name = wide_text(protocol::kCharacterSummaryNameBytes);
    value.level = 65535U;
    value.gender = protocol::Gender::kMale;
    value.face = 65535U;
    value.hair = 65535U;
    value.school = 255U;
    value.scene = 65535U;
    return value;
}

[[nodiscard]] inline protocol::CharacterSummary character_summary_typical() {
    protocol::CharacterSummary value;
    value.id = 1009U;
    value.name = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    value.level = 3027U;
    value.gender = protocol::Gender::kMale;
    value.face = 5045U;
    value.hair = 6054U;
    value.school = 151U;
    value.scene = 8072U;
    return value;
}

[[nodiscard]] inline protocol::Hello hello_min() {
    protocol::Hello value;
    value.version = 0U;
    value.platform = protocol::Platform::kWindows;
    value.build = 0U;
    return value;
}

[[nodiscard]] inline protocol::Hello hello_max() {
    protocol::Hello value;
    value.version = 65535U;
    value.platform = protocol::Platform::kIos;
    value.build = 4294967295U;
    return value;
}

[[nodiscard]] inline protocol::Hello hello_typical() {
    protocol::Hello value;
    value.version = 1009U;
    value.platform = protocol::Platform::kAndroid;
    value.build = 3027U;
    return value;
}

[[nodiscard]] inline protocol::Login login_min() {
    protocol::Login value;
    return value;
}

[[nodiscard]] inline protocol::Login login_max() {
    protocol::Login value;
    value.account = wide_text(protocol::kLoginAccountBytes);
    value.ticket = wide_text(protocol::kLoginTicketBytes);
    return value;
}

[[nodiscard]] inline protocol::Login login_typical() {
    protocol::Login value;
    value.account = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    value.ticket = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    return value;
}

[[nodiscard]] inline protocol::Resume resume_min() {
    protocol::Resume value;
    value.token = pattern<protocol::kResumeTokenBytes>(0, 0);
    return value;
}

[[nodiscard]] inline protocol::Resume resume_max() {
    protocol::Resume value;
    value.token = pattern<protocol::kResumeTokenBytes>(255, 0);
    return value;
}

[[nodiscard]] inline protocol::Resume resume_typical() {
    protocol::Resume value;
    value.token = pattern<protocol::kResumeTokenBytes>(1, 7);
    return value;
}

[[nodiscard]] inline protocol::Ping ping_min() {
    protocol::Ping value;
    value.client_time = std::chrono::milliseconds{0};
    return value;
}

[[nodiscard]] inline protocol::Ping ping_max() {
    protocol::Ping value;
    value.client_time = std::chrono::milliseconds{4294967295};
    return value;
}

[[nodiscard]] inline protocol::Ping ping_typical() {
    protocol::Ping value;
    value.client_time = std::chrono::milliseconds{30};
    return value;
}

[[nodiscard]] inline protocol::Logout logout_min() {
    return {};
}

[[nodiscard]] inline protocol::Logout logout_max() {
    return {};
}

[[nodiscard]] inline protocol::Logout logout_typical() {
    return {};
}

[[nodiscard]] inline protocol::CreateCharacter create_character_min() {
    protocol::CreateCharacter value;
    value.gender = protocol::Gender::kFemale;
    value.face = 0U;
    value.hair = 0U;
    return value;
}

[[nodiscard]] inline protocol::CreateCharacter create_character_max() {
    protocol::CreateCharacter value;
    value.name = wide_text(protocol::kCreateCharacterNameBytes);
    value.gender = protocol::Gender::kMale;
    value.face = 65535U;
    value.hair = 65535U;
    return value;
}

[[nodiscard]] inline protocol::CreateCharacter create_character_typical() {
    protocol::CreateCharacter value;
    value.name = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    value.gender = protocol::Gender::kMale;
    value.face = 3027U;
    value.hair = 4036U;
    return value;
}

[[nodiscard]] inline protocol::DeleteCharacter delete_character_min() {
    protocol::DeleteCharacter value;
    value.character = 0U;
    return value;
}

[[nodiscard]] inline protocol::DeleteCharacter delete_character_max() {
    protocol::DeleteCharacter value;
    value.character = 18446744073709551615U;
    return value;
}

[[nodiscard]] inline protocol::DeleteCharacter delete_character_typical() {
    protocol::DeleteCharacter value;
    value.character = 1009U;
    return value;
}

[[nodiscard]] inline protocol::EnterGame enter_game_min() {
    protocol::EnterGame value;
    value.character = 0U;
    return value;
}

[[nodiscard]] inline protocol::EnterGame enter_game_max() {
    protocol::EnterGame value;
    value.character = 18446744073709551615U;
    return value;
}

[[nodiscard]] inline protocol::EnterGame enter_game_typical() {
    protocol::EnterGame value;
    value.character = 1009U;
    return value;
}

[[nodiscard]] inline protocol::Move move_min() {
    protocol::Move value;
    value.x_cm = std::bit_cast<float>(0xFF7FFFFFU);
    value.z_cm = std::bit_cast<float>(0xFF7FFFFFU);
    value.tick = 0U;
    return value;
}

[[nodiscard]] inline protocol::Move move_max() {
    protocol::Move value;
    value.x_cm = std::bit_cast<float>(0x7F7FFFFFU);
    value.z_cm = std::bit_cast<float>(0x7F7FFFFFU);
    value.tick = 4294967295U;
    return value;
}

[[nodiscard]] inline protocol::Move move_typical() {
    protocol::Move value;
    value.x_cm = std::bit_cast<float>(0x3FA00000U);
    value.z_cm = std::bit_cast<float>(0x40100000U);
    value.tick = 3027U;
    return value;
}

[[nodiscard]] inline protocol::CreateAccount create_account_min() {
    protocol::CreateAccount value;
    return value;
}

[[nodiscard]] inline protocol::CreateAccount create_account_max() {
    protocol::CreateAccount value;
    value.account = wide_text(protocol::kCreateAccountAccountBytes);
    value.password = wide_text(protocol::kCreateAccountPasswordBytes);
    return value;
}

[[nodiscard]] inline protocol::CreateAccount create_account_typical() {
    protocol::CreateAccount value;
    value.account = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    value.password = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    return value;
}

[[nodiscard]] inline protocol::SignIn sign_in_min() {
    protocol::SignIn value;
    return value;
}

[[nodiscard]] inline protocol::SignIn sign_in_max() {
    protocol::SignIn value;
    value.account = wide_text(protocol::kSignInAccountBytes);
    value.password = wide_text(protocol::kSignInPasswordBytes);
    return value;
}

[[nodiscard]] inline protocol::SignIn sign_in_typical() {
    protocol::SignIn value;
    value.account = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    value.password = "Thi\xC3\xAAn Long B\xC3\xA1t B\xE1\xBB\x99";
    return value;
}

[[nodiscard]] inline protocol::Welcome welcome_min() {
    protocol::Welcome value;
    value.version = 0U;
    value.server_time = std::chrono::milliseconds{0};
    value.heartbeat = std::chrono::seconds{0};
    return value;
}

[[nodiscard]] inline protocol::Welcome welcome_max() {
    protocol::Welcome value;
    value.version = 65535U;
    value.server_time = std::chrono::milliseconds{9223372036854775807};
    value.heartbeat = std::chrono::seconds{65535};
    return value;
}

[[nodiscard]] inline protocol::Welcome welcome_typical() {
    protocol::Welcome value;
    value.version = 1009U;
    value.server_time = std::chrono::milliseconds{60};
    value.heartbeat = std::chrono::seconds{90};
    return value;
}

[[nodiscard]] inline protocol::SessionStart session_start_min() {
    protocol::SessionStart value;
    value.token = pattern<protocol::kSessionStartTokenBytes>(0, 0);
    return value;
}

[[nodiscard]] inline protocol::SessionStart session_start_max() {
    protocol::SessionStart value;
    value.token = pattern<protocol::kSessionStartTokenBytes>(255, 0);
    return value;
}

[[nodiscard]] inline protocol::SessionStart session_start_typical() {
    protocol::SessionStart value;
    value.token = pattern<protocol::kSessionStartTokenBytes>(1, 7);
    return value;
}

[[nodiscard]] inline protocol::ContentKey content_key_min() {
    protocol::ContentKey value;
    value.key = pattern<protocol::kContentKeyKeyBytes>(0, 0);
    return value;
}

[[nodiscard]] inline protocol::ContentKey content_key_max() {
    protocol::ContentKey value;
    value.key = pattern<protocol::kContentKeyKeyBytes>(255, 0);
    return value;
}

[[nodiscard]] inline protocol::ContentKey content_key_typical() {
    protocol::ContentKey value;
    value.key = pattern<protocol::kContentKeyKeyBytes>(1, 7);
    return value;
}

[[nodiscard]] inline protocol::Pong pong_min() {
    protocol::Pong value;
    value.client_time = std::chrono::milliseconds{0};
    value.server_time = std::chrono::milliseconds{0};
    return value;
}

[[nodiscard]] inline protocol::Pong pong_max() {
    protocol::Pong value;
    value.client_time = std::chrono::milliseconds{4294967295};
    value.server_time = std::chrono::milliseconds{9223372036854775807};
    return value;
}

[[nodiscard]] inline protocol::Pong pong_typical() {
    protocol::Pong value;
    value.client_time = std::chrono::milliseconds{30};
    value.server_time = std::chrono::milliseconds{60};
    return value;
}

[[nodiscard]] inline protocol::Reject reject_min() {
    protocol::Reject value;
    value.request = 0U;
    value.code = protocol::ErrorCode::kMalformed;
    return value;
}

[[nodiscard]] inline protocol::Reject reject_max() {
    protocol::Reject value;
    value.request = 65535U;
    value.code = protocol::ErrorCode::kCannotAttack;
    return value;
}

[[nodiscard]] inline protocol::Reject reject_typical() {
    protocol::Reject value;
    value.request = 1009U;
    value.code = protocol::ErrorCode::kVersionMismatch;
    return value;
}

[[nodiscard]] inline protocol::Goodbye goodbye_min() {
    protocol::Goodbye value;
    value.reason = protocol::DisconnectReason::kLoggedOut;
    return value;
}

[[nodiscard]] inline protocol::Goodbye goodbye_max() {
    protocol::Goodbye value;
    value.reason = protocol::DisconnectReason::kContentMismatch;
    return value;
}

[[nodiscard]] inline protocol::Goodbye goodbye_typical() {
    protocol::Goodbye value;
    value.reason = protocol::DisconnectReason::kLoginElsewhere;
    return value;
}

[[nodiscard]] inline protocol::ContentStamp content_stamp_min() {
    protocol::ContentStamp value;
    value.stamp = pattern<protocol::kContentStampStampBytes>(0, 0);
    return value;
}

[[nodiscard]] inline protocol::ContentStamp content_stamp_max() {
    protocol::ContentStamp value;
    value.stamp = pattern<protocol::kContentStampStampBytes>(255, 0);
    return value;
}

[[nodiscard]] inline protocol::ContentStamp content_stamp_typical() {
    protocol::ContentStamp value;
    value.stamp = pattern<protocol::kContentStampStampBytes>(1, 7);
    return value;
}

[[nodiscard]] inline protocol::CharacterList character_list_min() {
    protocol::CharacterList value;
    return value;
}

[[nodiscard]] inline protocol::CharacterList character_list_max() {
    protocol::CharacterList value;
    value.characters.assign(8, character_summary_max());
    return value;
}

[[nodiscard]] inline protocol::CharacterList character_list_typical() {
    protocol::CharacterList value;
    value.characters.assign(2, character_summary_typical());
    return value;
}

[[nodiscard]] inline protocol::Position position_min() {
    protocol::Position value;
    value.x_cm = std::bit_cast<float>(0xFF7FFFFFU);
    value.z_cm = std::bit_cast<float>(0xFF7FFFFFU);
    value.tick = 0U;
    return value;
}

[[nodiscard]] inline protocol::Position position_max() {
    protocol::Position value;
    value.x_cm = std::bit_cast<float>(0x7F7FFFFFU);
    value.z_cm = std::bit_cast<float>(0x7F7FFFFFU);
    value.tick = 4294967295U;
    return value;
}

[[nodiscard]] inline protocol::Position position_typical() {
    protocol::Position value;
    value.x_cm = std::bit_cast<float>(0x3FA00000U);
    value.z_cm = std::bit_cast<float>(0x40100000U);
    value.tick = 3027U;
    return value;
}

[[nodiscard]] inline protocol::Ticket ticket_min() {
    protocol::Ticket value;
    value.token = pattern<protocol::kTicketTokenBytes>(0, 0);
    return value;
}

[[nodiscard]] inline protocol::Ticket ticket_max() {
    protocol::Ticket value;
    value.token = pattern<protocol::kTicketTokenBytes>(255, 0);
    return value;
}

[[nodiscard]] inline protocol::Ticket ticket_typical() {
    protocol::Ticket value;
    value.token = pattern<protocol::kTicketTokenBytes>(1, 7);
    return value;
}

[[nodiscard]] inline protocol::WireStatus encode_hello_min(Buffer& out) {
    return protocol::encode(out, hello_min());
}

[[nodiscard]] inline Check decode_hello_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Hello::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, hello_min());
}

inline constexpr std::array<std::uint8_t, 15> kHelloMinFrame{
    0x07, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kHelloMin{.name = "Hello/min",
    .frame = kHelloMinFrame,
    .encode = &encode_hello_min,
    .decode = &decode_hello_min,
    .decoders = kGameClient | kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_hello_max(Buffer& out) {
    return protocol::encode(out, hello_max());
}

[[nodiscard]] inline Check decode_hello_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Hello::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, hello_max());
}

inline constexpr std::array<std::uint8_t, 15> kHelloMaxFrame{
    0x07, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0xFF, 0xFF, 0x03, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kHelloMax{.name = "Hello/max",
    .frame = kHelloMaxFrame,
    .encode = &encode_hello_max,
    .decode = &decode_hello_max,
    .decoders = kGameClient | kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_hello_typical(Buffer& out) {
    return protocol::encode(out, hello_typical());
}

[[nodiscard]] inline Check decode_hello_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Hello::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, hello_typical());
}

inline constexpr std::array<std::uint8_t, 15> kHelloTypicalFrame{
    0x07, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0xF1, 0x03, 0x02, 0xD3, 0x0B, 0x00, 0x00};

inline constexpr Sample kHelloTypical{.name = "Hello/typical",
    .frame = kHelloTypicalFrame,
    .encode = &encode_hello_typical,
    .decode = &decode_hello_typical,
    .decoders = kGameClient | kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_login_min(Buffer& out) {
    return protocol::encode(out, login_min());
}

[[nodiscard]] inline Check decode_login_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Login::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, login_min());
}

inline constexpr std::array<std::uint8_t, 12> kLoginMinFrame{
    0x04, 0x00, 0x00, 0x00, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kLoginMin{.name = "Login/min",
    .frame = kLoginMinFrame,
    .encode = &encode_login_min,
    .decode = &decode_login_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_login_max(Buffer& out) {
    return protocol::encode(out, login_max());
}

[[nodiscard]] inline Check decode_login_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Login::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, login_max());
}

inline constexpr std::array<std::uint8_t, 588> kLoginMaxFrame{0x44, 0x02, 0x00, 0x00, 0x02, 0x01, 0x00, 0x00, 0x40,
    0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0x61, 0x00, 0x02, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80,
    0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9,
    0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3,
    0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41,
    0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80,
    0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80,
    0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9,
    0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3,
    0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41,
    0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80,
    0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80,
    0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9,
    0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0x61};

inline constexpr Sample kLoginMax{.name = "Login/max",
    .frame = kLoginMaxFrame,
    .encode = &encode_login_max,
    .decode = &decode_login_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_login_typical(Buffer& out) {
    return protocol::encode(out, login_typical());
}

[[nodiscard]] inline Check decode_login_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Login::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, login_typical());
}

inline constexpr std::array<std::uint8_t, 54> kLoginTypicalFrame{0x2E, 0x00, 0x00, 0x00, 0x02, 0x01, 0x00, 0x00, 0x15,
    0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3, 0xA1, 0x74, 0x20, 0x42,
    0xE1, 0xBB, 0x99, 0x15, 0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3,
    0xA1, 0x74, 0x20, 0x42, 0xE1, 0xBB, 0x99};

inline constexpr Sample kLoginTypical{.name = "Login/typical",
    .frame = kLoginTypicalFrame,
    .encode = &encode_login_typical,
    .decode = &decode_login_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_resume_min(Buffer& out) {
    return protocol::encode(out, resume_min());
}

[[nodiscard]] inline Check decode_resume_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Resume::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, resume_min());
}

inline constexpr std::array<std::uint8_t, 24> kResumeMinFrame{0x10, 0x00, 0x00, 0x00, 0x03, 0x01, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kResumeMin{.name = "Resume/min",
    .frame = kResumeMinFrame,
    .encode = &encode_resume_min,
    .decode = &decode_resume_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_resume_max(Buffer& out) {
    return protocol::encode(out, resume_max());
}

[[nodiscard]] inline Check decode_resume_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Resume::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, resume_max());
}

inline constexpr std::array<std::uint8_t, 24> kResumeMaxFrame{0x10, 0x00, 0x00, 0x00, 0x03, 0x01, 0x00, 0x00, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kResumeMax{.name = "Resume/max",
    .frame = kResumeMaxFrame,
    .encode = &encode_resume_max,
    .decode = &decode_resume_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_resume_typical(Buffer& out) {
    return protocol::encode(out, resume_typical());
}

[[nodiscard]] inline Check decode_resume_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Resume::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, resume_typical());
}

inline constexpr std::array<std::uint8_t, 24> kResumeTypicalFrame{0x10, 0x00, 0x00, 0x00, 0x03, 0x01, 0x00, 0x00, 0x01,
    0x08, 0x0F, 0x16, 0x1D, 0x24, 0x2B, 0x32, 0x39, 0x40, 0x47, 0x4E, 0x55, 0x5C, 0x63, 0x6A};

inline constexpr Sample kResumeTypical{.name = "Resume/typical",
    .frame = kResumeTypicalFrame,
    .encode = &encode_resume_typical,
    .decode = &decode_resume_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_ping_min(Buffer& out) {
    return protocol::encode(out, ping_min());
}

[[nodiscard]] inline Check decode_ping_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Ping::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, ping_min());
}

inline constexpr std::array<std::uint8_t, 12> kPingMinFrame{
    0x04, 0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kPingMin{.name = "Ping/min",
    .frame = kPingMinFrame,
    .encode = &encode_ping_min,
    .decode = &decode_ping_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_ping_max(Buffer& out) {
    return protocol::encode(out, ping_max());
}

[[nodiscard]] inline Check decode_ping_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Ping::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, ping_max());
}

inline constexpr std::array<std::uint8_t, 12> kPingMaxFrame{
    0x04, 0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kPingMax{.name = "Ping/max",
    .frame = kPingMaxFrame,
    .encode = &encode_ping_max,
    .decode = &decode_ping_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_ping_typical(Buffer& out) {
    return protocol::encode(out, ping_typical());
}

[[nodiscard]] inline Check decode_ping_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Ping::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, ping_typical());
}

inline constexpr std::array<std::uint8_t, 12> kPingTypicalFrame{
    0x04, 0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x1E, 0x00, 0x00, 0x00};

inline constexpr Sample kPingTypical{.name = "Ping/typical",
    .frame = kPingTypicalFrame,
    .encode = &encode_ping_typical,
    .decode = &decode_ping_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_logout_min(Buffer& out) {
    return protocol::encode(out, logout_min());
}

[[nodiscard]] inline Check decode_logout_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Logout::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, logout_min());
}

inline constexpr std::array<std::uint8_t, 8> kLogoutMinFrame{0x00, 0x00, 0x00, 0x00, 0x05, 0x01, 0x00, 0x00};

inline constexpr Sample kLogoutMin{.name = "Logout/min",
    .frame = kLogoutMinFrame,
    .encode = &encode_logout_min,
    .decode = &decode_logout_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_logout_max(Buffer& out) {
    return protocol::encode(out, logout_max());
}

[[nodiscard]] inline Check decode_logout_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Logout::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, logout_max());
}

inline constexpr std::array<std::uint8_t, 8> kLogoutMaxFrame{0x00, 0x00, 0x00, 0x00, 0x05, 0x01, 0x00, 0x00};

inline constexpr Sample kLogoutMax{.name = "Logout/max",
    .frame = kLogoutMaxFrame,
    .encode = &encode_logout_max,
    .decode = &decode_logout_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_logout_typical(Buffer& out) {
    return protocol::encode(out, logout_typical());
}

[[nodiscard]] inline Check decode_logout_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Logout::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, logout_typical());
}

inline constexpr std::array<std::uint8_t, 8> kLogoutTypicalFrame{0x00, 0x00, 0x00, 0x00, 0x05, 0x01, 0x00, 0x00};

inline constexpr Sample kLogoutTypical{.name = "Logout/typical",
    .frame = kLogoutTypicalFrame,
    .encode = &encode_logout_typical,
    .decode = &decode_logout_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_create_character_min(Buffer& out) {
    return protocol::encode(out, create_character_min());
}

[[nodiscard]] inline Check decode_create_character_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CreateCharacter::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, create_character_min());
}

inline constexpr std::array<std::uint8_t, 15> kCreateCharacterMinFrame{
    0x07, 0x00, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kCreateCharacterMin{.name = "CreateCharacter/min",
    .frame = kCreateCharacterMinFrame,
    .encode = &encode_create_character_min,
    .decode = &decode_create_character_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_create_character_max(Buffer& out) {
    return protocol::encode(out, create_character_max());
}

[[nodiscard]] inline Check decode_create_character_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CreateCharacter::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, create_character_max());
}

inline constexpr std::array<std::uint8_t, 63> kCreateCharacterMaxFrame{0x37, 0x00, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00,
    0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0x61, 0x61, 0x02, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kCreateCharacterMax{.name = "CreateCharacter/max",
    .frame = kCreateCharacterMaxFrame,
    .encode = &encode_create_character_max,
    .decode = &decode_create_character_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_create_character_typical(Buffer& out) {
    return protocol::encode(out, create_character_typical());
}

[[nodiscard]] inline Check decode_create_character_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CreateCharacter::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, create_character_typical());
}

inline constexpr std::array<std::uint8_t, 36> kCreateCharacterTypicalFrame{0x1C, 0x00, 0x00, 0x00, 0x01, 0x02, 0x00,
    0x00, 0x15, 0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3, 0xA1, 0x74,
    0x20, 0x42, 0xE1, 0xBB, 0x99, 0x02, 0xD3, 0x0B, 0xC4, 0x0F};

inline constexpr Sample kCreateCharacterTypical{.name = "CreateCharacter/typical",
    .frame = kCreateCharacterTypicalFrame,
    .encode = &encode_create_character_typical,
    .decode = &decode_create_character_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_delete_character_min(Buffer& out) {
    return protocol::encode(out, delete_character_min());
}

[[nodiscard]] inline Check decode_delete_character_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::DeleteCharacter::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, delete_character_min());
}

inline constexpr std::array<std::uint8_t, 16> kDeleteCharacterMinFrame{
    0x08, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kDeleteCharacterMin{.name = "DeleteCharacter/min",
    .frame = kDeleteCharacterMinFrame,
    .encode = &encode_delete_character_min,
    .decode = &decode_delete_character_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_delete_character_max(Buffer& out) {
    return protocol::encode(out, delete_character_max());
}

[[nodiscard]] inline Check decode_delete_character_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::DeleteCharacter::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, delete_character_max());
}

inline constexpr std::array<std::uint8_t, 16> kDeleteCharacterMaxFrame{
    0x08, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kDeleteCharacterMax{.name = "DeleteCharacter/max",
    .frame = kDeleteCharacterMaxFrame,
    .encode = &encode_delete_character_max,
    .decode = &decode_delete_character_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_delete_character_typical(Buffer& out) {
    return protocol::encode(out, delete_character_typical());
}

[[nodiscard]] inline Check decode_delete_character_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::DeleteCharacter::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, delete_character_typical());
}

inline constexpr std::array<std::uint8_t, 16> kDeleteCharacterTypicalFrame{
    0x08, 0x00, 0x00, 0x00, 0x02, 0x02, 0x00, 0x00, 0xF1, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kDeleteCharacterTypical{.name = "DeleteCharacter/typical",
    .frame = kDeleteCharacterTypicalFrame,
    .encode = &encode_delete_character_typical,
    .decode = &decode_delete_character_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_enter_game_min(Buffer& out) {
    return protocol::encode(out, enter_game_min());
}

[[nodiscard]] inline Check decode_enter_game_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::EnterGame::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, enter_game_min());
}

inline constexpr std::array<std::uint8_t, 16> kEnterGameMinFrame{
    0x08, 0x00, 0x00, 0x00, 0x03, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kEnterGameMin{.name = "EnterGame/min",
    .frame = kEnterGameMinFrame,
    .encode = &encode_enter_game_min,
    .decode = &decode_enter_game_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_enter_game_max(Buffer& out) {
    return protocol::encode(out, enter_game_max());
}

[[nodiscard]] inline Check decode_enter_game_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::EnterGame::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, enter_game_max());
}

inline constexpr std::array<std::uint8_t, 16> kEnterGameMaxFrame{
    0x08, 0x00, 0x00, 0x00, 0x03, 0x02, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kEnterGameMax{.name = "EnterGame/max",
    .frame = kEnterGameMaxFrame,
    .encode = &encode_enter_game_max,
    .decode = &decode_enter_game_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_enter_game_typical(Buffer& out) {
    return protocol::encode(out, enter_game_typical());
}

[[nodiscard]] inline Check decode_enter_game_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::EnterGame::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, enter_game_typical());
}

inline constexpr std::array<std::uint8_t, 16> kEnterGameTypicalFrame{
    0x08, 0x00, 0x00, 0x00, 0x03, 0x02, 0x00, 0x00, 0xF1, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kEnterGameTypical{.name = "EnterGame/typical",
    .frame = kEnterGameTypicalFrame,
    .encode = &encode_enter_game_typical,
    .decode = &decode_enter_game_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_move_min(Buffer& out) {
    return protocol::encode(out, move_min());
}

[[nodiscard]] inline Check decode_move_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Move::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, move_min());
}

inline constexpr std::array<std::uint8_t, 20> kMoveMinFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00, 0xFF, 0xFF,
    0x7F, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kMoveMin{.name = "Move/min",
    .frame = kMoveMinFrame,
    .encode = &encode_move_min,
    .decode = &decode_move_min,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_move_max(Buffer& out) {
    return protocol::encode(out, move_max());
}

[[nodiscard]] inline Check decode_move_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Move::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, move_max());
}

inline constexpr std::array<std::uint8_t, 20> kMoveMaxFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00, 0xFF, 0xFF,
    0x7F, 0x7F, 0xFF, 0xFF, 0x7F, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kMoveMax{.name = "Move/max",
    .frame = kMoveMaxFrame,
    .encode = &encode_move_max,
    .decode = &decode_move_max,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_move_typical(Buffer& out) {
    return protocol::encode(out, move_typical());
}

[[nodiscard]] inline Check decode_move_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Move::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_client(frame, body);
    return holds(result, move_typical());
}

inline constexpr std::array<std::uint8_t, 20> kMoveTypicalFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00, 0x00,
    0x00, 0xA0, 0x3F, 0x00, 0x00, 0x10, 0x40, 0xD3, 0x0B, 0x00, 0x00};

inline constexpr Sample kMoveTypical{.name = "Move/typical",
    .frame = kMoveTypicalFrame,
    .encode = &encode_move_typical,
    .decode = &decode_move_typical,
    .decoders = kGameClient};

[[nodiscard]] inline protocol::WireStatus encode_create_account_min(Buffer& out) {
    return protocol::encode(out, create_account_min());
}

[[nodiscard]] inline Check decode_create_account_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CreateAccount::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_client(frame, body);
    return holds(result, create_account_min());
}

inline constexpr std::array<std::uint8_t, 12> kCreateAccountMinFrame{
    0x04, 0x00, 0x00, 0x00, 0x01, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kCreateAccountMin{.name = "CreateAccount/min",
    .frame = kCreateAccountMinFrame,
    .encode = &encode_create_account_min,
    .decode = &decode_create_account_min,
    .decoders = kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_create_account_max(Buffer& out) {
    return protocol::encode(out, create_account_max());
}

[[nodiscard]] inline Check decode_create_account_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CreateAccount::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_client(frame, body);
    return holds(result, create_account_max());
}

inline constexpr std::array<std::uint8_t, 204> kCreateAccountMaxFrame{0xC4, 0x00, 0x00, 0x00, 0x01, 0x05, 0x00, 0x00,
    0x40, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0x61, 0x80, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9,
    0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3,
    0xA9, 0xE1, 0xBB, 0x87, 0x61, 0x61};

inline constexpr Sample kCreateAccountMax{.name = "CreateAccount/max",
    .frame = kCreateAccountMaxFrame,
    .encode = &encode_create_account_max,
    .decode = &decode_create_account_max,
    .decoders = kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_create_account_typical(Buffer& out) {
    return protocol::encode(out, create_account_typical());
}

[[nodiscard]] inline Check decode_create_account_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CreateAccount::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_client(frame, body);
    return holds(result, create_account_typical());
}

inline constexpr std::array<std::uint8_t, 54> kCreateAccountTypicalFrame{0x2E, 0x00, 0x00, 0x00, 0x01, 0x05, 0x00, 0x00,
    0x15, 0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3, 0xA1, 0x74, 0x20,
    0x42, 0xE1, 0xBB, 0x99, 0x15, 0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42,
    0xC3, 0xA1, 0x74, 0x20, 0x42, 0xE1, 0xBB, 0x99};

inline constexpr Sample kCreateAccountTypical{.name = "CreateAccount/typical",
    .frame = kCreateAccountTypicalFrame,
    .encode = &encode_create_account_typical,
    .decode = &decode_create_account_typical,
    .decoders = kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_sign_in_min(Buffer& out) {
    return protocol::encode(out, sign_in_min());
}

[[nodiscard]] inline Check decode_sign_in_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::SignIn::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_client(frame, body);
    return holds(result, sign_in_min());
}

inline constexpr std::array<std::uint8_t, 12> kSignInMinFrame{
    0x04, 0x00, 0x00, 0x00, 0x02, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kSignInMin{.name = "SignIn/min",
    .frame = kSignInMinFrame,
    .encode = &encode_sign_in_min,
    .decode = &decode_sign_in_min,
    .decoders = kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_sign_in_max(Buffer& out) {
    return protocol::encode(out, sign_in_max());
}

[[nodiscard]] inline Check decode_sign_in_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::SignIn::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_client(frame, body);
    return holds(result, sign_in_max());
}

inline constexpr std::array<std::uint8_t, 204> kSignInMaxFrame{0xC4, 0x00, 0x00, 0x00, 0x02, 0x05, 0x00, 0x00, 0x40,
    0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0x61, 0x80, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80,
    0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9,
    0xE1, 0xBB, 0x87, 0x61, 0x61};

inline constexpr Sample kSignInMax{.name = "SignIn/max",
    .frame = kSignInMaxFrame,
    .encode = &encode_sign_in_max,
    .decode = &decode_sign_in_max,
    .decoders = kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_sign_in_typical(Buffer& out) {
    return protocol::encode(out, sign_in_typical());
}

[[nodiscard]] inline Check decode_sign_in_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::SignIn::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_client(frame, body);
    return holds(result, sign_in_typical());
}

inline constexpr std::array<std::uint8_t, 54> kSignInTypicalFrame{0x2E, 0x00, 0x00, 0x00, 0x02, 0x05, 0x00, 0x00, 0x15,
    0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3, 0xA1, 0x74, 0x20, 0x42,
    0xE1, 0xBB, 0x99, 0x15, 0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3,
    0xA1, 0x74, 0x20, 0x42, 0xE1, 0xBB, 0x99};

inline constexpr Sample kSignInTypical{.name = "SignIn/typical",
    .frame = kSignInTypicalFrame,
    .encode = &encode_sign_in_typical,
    .decode = &decode_sign_in_typical,
    .decoders = kAuthClient};

[[nodiscard]] inline protocol::WireStatus encode_welcome_min(Buffer& out) {
    return protocol::encode(out, welcome_min());
}

[[nodiscard]] inline Check decode_welcome_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Welcome::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, welcome_min());
}

inline constexpr std::array<std::uint8_t, 20> kWelcomeMinFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x81, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kWelcomeMin{.name = "Welcome/min",
    .frame = kWelcomeMinFrame,
    .encode = &encode_welcome_min,
    .decode = &decode_welcome_min,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_welcome_max(Buffer& out) {
    return protocol::encode(out, welcome_max());
}

[[nodiscard]] inline Check decode_welcome_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Welcome::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, welcome_max());
}

inline constexpr std::array<std::uint8_t, 20> kWelcomeMaxFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x81, 0x00, 0x00, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF};

inline constexpr Sample kWelcomeMax{.name = "Welcome/max",
    .frame = kWelcomeMaxFrame,
    .encode = &encode_welcome_max,
    .decode = &decode_welcome_max,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_welcome_typical(Buffer& out) {
    return protocol::encode(out, welcome_typical());
}

[[nodiscard]] inline Check decode_welcome_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Welcome::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, welcome_typical());
}

inline constexpr std::array<std::uint8_t, 20> kWelcomeTypicalFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x81, 0x00, 0x00, 0xF1,
    0x03, 0x3C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x5A, 0x00};

inline constexpr Sample kWelcomeTypical{.name = "Welcome/typical",
    .frame = kWelcomeTypicalFrame,
    .encode = &encode_welcome_typical,
    .decode = &decode_welcome_typical,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_session_start_min(Buffer& out) {
    return protocol::encode(out, session_start_min());
}

[[nodiscard]] inline Check decode_session_start_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::SessionStart::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, session_start_min());
}

inline constexpr std::array<std::uint8_t, 24> kSessionStartMinFrame{0x10, 0x00, 0x00, 0x00, 0x02, 0x81, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kSessionStartMin{.name = "SessionStart/min",
    .frame = kSessionStartMinFrame,
    .encode = &encode_session_start_min,
    .decode = &decode_session_start_min,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_session_start_max(Buffer& out) {
    return protocol::encode(out, session_start_max());
}

[[nodiscard]] inline Check decode_session_start_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::SessionStart::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, session_start_max());
}

inline constexpr std::array<std::uint8_t, 24> kSessionStartMaxFrame{0x10, 0x00, 0x00, 0x00, 0x02, 0x81, 0x00, 0x00,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kSessionStartMax{.name = "SessionStart/max",
    .frame = kSessionStartMaxFrame,
    .encode = &encode_session_start_max,
    .decode = &decode_session_start_max,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_session_start_typical(Buffer& out) {
    return protocol::encode(out, session_start_typical());
}

[[nodiscard]] inline Check decode_session_start_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::SessionStart::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, session_start_typical());
}

inline constexpr std::array<std::uint8_t, 24> kSessionStartTypicalFrame{0x10, 0x00, 0x00, 0x00, 0x02, 0x81, 0x00, 0x00,
    0x01, 0x08, 0x0F, 0x16, 0x1D, 0x24, 0x2B, 0x32, 0x39, 0x40, 0x47, 0x4E, 0x55, 0x5C, 0x63, 0x6A};

inline constexpr Sample kSessionStartTypical{.name = "SessionStart/typical",
    .frame = kSessionStartTypicalFrame,
    .encode = &encode_session_start_typical,
    .decode = &decode_session_start_typical,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_content_key_min(Buffer& out) {
    return protocol::encode(out, content_key_min());
}

[[nodiscard]] inline Check decode_content_key_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::ContentKey::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, content_key_min());
}

inline constexpr std::array<std::uint8_t, 40> kContentKeyMinFrame{0x20, 0x00, 0x00, 0x00, 0x03, 0x81, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kContentKeyMin{.name = "ContentKey/min",
    .frame = kContentKeyMinFrame,
    .encode = &encode_content_key_min,
    .decode = &decode_content_key_min,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_content_key_max(Buffer& out) {
    return protocol::encode(out, content_key_max());
}

[[nodiscard]] inline Check decode_content_key_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::ContentKey::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, content_key_max());
}

inline constexpr std::array<std::uint8_t, 40> kContentKeyMaxFrame{0x20, 0x00, 0x00, 0x00, 0x03, 0x81, 0x00, 0x00, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kContentKeyMax{.name = "ContentKey/max",
    .frame = kContentKeyMaxFrame,
    .encode = &encode_content_key_max,
    .decode = &decode_content_key_max,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_content_key_typical(Buffer& out) {
    return protocol::encode(out, content_key_typical());
}

[[nodiscard]] inline Check decode_content_key_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::ContentKey::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, content_key_typical());
}

inline constexpr std::array<std::uint8_t, 40> kContentKeyTypicalFrame{0x20, 0x00, 0x00, 0x00, 0x03, 0x81, 0x00, 0x00,
    0x01, 0x08, 0x0F, 0x16, 0x1D, 0x24, 0x2B, 0x32, 0x39, 0x40, 0x47, 0x4E, 0x55, 0x5C, 0x63, 0x6A, 0x71, 0x78, 0x7F,
    0x86, 0x8D, 0x94, 0x9B, 0xA2, 0xA9, 0xB0, 0xB7, 0xBE, 0xC5, 0xCC, 0xD3, 0xDA};

inline constexpr Sample kContentKeyTypical{.name = "ContentKey/typical",
    .frame = kContentKeyTypicalFrame,
    .encode = &encode_content_key_typical,
    .decode = &decode_content_key_typical,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_pong_min(Buffer& out) {
    return protocol::encode(out, pong_min());
}

[[nodiscard]] inline Check decode_pong_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Pong::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, pong_min());
}

inline constexpr std::array<std::uint8_t, 20> kPongMinFrame{0x0C, 0x00, 0x00, 0x00, 0x04, 0x81, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kPongMin{.name = "Pong/min",
    .frame = kPongMinFrame,
    .encode = &encode_pong_min,
    .decode = &decode_pong_min,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_pong_max(Buffer& out) {
    return protocol::encode(out, pong_max());
}

[[nodiscard]] inline Check decode_pong_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Pong::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, pong_max());
}

inline constexpr std::array<std::uint8_t, 20> kPongMaxFrame{0x0C, 0x00, 0x00, 0x00, 0x04, 0x81, 0x00, 0x00, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F};

inline constexpr Sample kPongMax{.name = "Pong/max",
    .frame = kPongMaxFrame,
    .encode = &encode_pong_max,
    .decode = &decode_pong_max,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_pong_typical(Buffer& out) {
    return protocol::encode(out, pong_typical());
}

[[nodiscard]] inline Check decode_pong_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Pong::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, pong_typical());
}

inline constexpr std::array<std::uint8_t, 20> kPongTypicalFrame{0x0C, 0x00, 0x00, 0x00, 0x04, 0x81, 0x00, 0x00, 0x1E,
    0x00, 0x00, 0x00, 0x3C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kPongTypical{.name = "Pong/typical",
    .frame = kPongTypicalFrame,
    .encode = &encode_pong_typical,
    .decode = &decode_pong_typical,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_reject_min(Buffer& out) {
    return protocol::encode(out, reject_min());
}

[[nodiscard]] inline Check decode_reject_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Reject::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, reject_min());
}

inline constexpr std::array<std::uint8_t, 12> kRejectMinFrame{
    0x04, 0x00, 0x00, 0x00, 0x06, 0x81, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00};

inline constexpr Sample kRejectMin{.name = "Reject/min",
    .frame = kRejectMinFrame,
    .encode = &encode_reject_min,
    .decode = &decode_reject_min,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_reject_max(Buffer& out) {
    return protocol::encode(out, reject_max());
}

[[nodiscard]] inline Check decode_reject_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Reject::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, reject_max());
}

inline constexpr std::array<std::uint8_t, 12> kRejectMaxFrame{
    0x04, 0x00, 0x00, 0x00, 0x06, 0x81, 0x00, 0x00, 0xFF, 0xFF, 0x20, 0x00};

inline constexpr Sample kRejectMax{.name = "Reject/max",
    .frame = kRejectMaxFrame,
    .encode = &encode_reject_max,
    .decode = &decode_reject_max,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_reject_typical(Buffer& out) {
    return protocol::encode(out, reject_typical());
}

[[nodiscard]] inline Check decode_reject_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Reject::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, reject_typical());
}

inline constexpr std::array<std::uint8_t, 12> kRejectTypicalFrame{
    0x04, 0x00, 0x00, 0x00, 0x06, 0x81, 0x00, 0x00, 0xF1, 0x03, 0x02, 0x00};

inline constexpr Sample kRejectTypical{.name = "Reject/typical",
    .frame = kRejectTypicalFrame,
    .encode = &encode_reject_typical,
    .decode = &decode_reject_typical,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_goodbye_min(Buffer& out) {
    return protocol::encode(out, goodbye_min());
}

[[nodiscard]] inline Check decode_goodbye_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Goodbye::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, goodbye_min());
}

inline constexpr std::array<std::uint8_t, 9> kGoodbyeMinFrame{0x01, 0x00, 0x00, 0x00, 0x07, 0x81, 0x00, 0x00, 0x01};

inline constexpr Sample kGoodbyeMin{.name = "Goodbye/min",
    .frame = kGoodbyeMinFrame,
    .encode = &encode_goodbye_min,
    .decode = &decode_goodbye_min,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_goodbye_max(Buffer& out) {
    return protocol::encode(out, goodbye_max());
}

[[nodiscard]] inline Check decode_goodbye_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Goodbye::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, goodbye_max());
}

inline constexpr std::array<std::uint8_t, 9> kGoodbyeMaxFrame{0x01, 0x00, 0x00, 0x00, 0x07, 0x81, 0x00, 0x00, 0x09};

inline constexpr Sample kGoodbyeMax{.name = "Goodbye/max",
    .frame = kGoodbyeMaxFrame,
    .encode = &encode_goodbye_max,
    .decode = &decode_goodbye_max,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_goodbye_typical(Buffer& out) {
    return protocol::encode(out, goodbye_typical());
}

[[nodiscard]] inline Check decode_goodbye_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Goodbye::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, goodbye_typical());
}

inline constexpr std::array<std::uint8_t, 9> kGoodbyeTypicalFrame{0x01, 0x00, 0x00, 0x00, 0x07, 0x81, 0x00, 0x00, 0x02};

inline constexpr Sample kGoodbyeTypical{.name = "Goodbye/typical",
    .frame = kGoodbyeTypicalFrame,
    .encode = &encode_goodbye_typical,
    .decode = &decode_goodbye_typical,
    .decoders = kGameServer | kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_content_stamp_min(Buffer& out) {
    return protocol::encode(out, content_stamp_min());
}

[[nodiscard]] inline Check decode_content_stamp_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::ContentStamp::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, content_stamp_min());
}

inline constexpr std::array<std::uint8_t, 40> kContentStampMinFrame{0x20, 0x00, 0x00, 0x00, 0x08, 0x81, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kContentStampMin{.name = "ContentStamp/min",
    .frame = kContentStampMinFrame,
    .encode = &encode_content_stamp_min,
    .decode = &decode_content_stamp_min,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_content_stamp_max(Buffer& out) {
    return protocol::encode(out, content_stamp_max());
}

[[nodiscard]] inline Check decode_content_stamp_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::ContentStamp::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, content_stamp_max());
}

inline constexpr std::array<std::uint8_t, 40> kContentStampMaxFrame{0x20, 0x00, 0x00, 0x00, 0x08, 0x81, 0x00, 0x00,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kContentStampMax{.name = "ContentStamp/max",
    .frame = kContentStampMaxFrame,
    .encode = &encode_content_stamp_max,
    .decode = &decode_content_stamp_max,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_content_stamp_typical(Buffer& out) {
    return protocol::encode(out, content_stamp_typical());
}

[[nodiscard]] inline Check decode_content_stamp_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::ContentStamp::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, content_stamp_typical());
}

inline constexpr std::array<std::uint8_t, 40> kContentStampTypicalFrame{0x20, 0x00, 0x00, 0x00, 0x08, 0x81, 0x00, 0x00,
    0x01, 0x08, 0x0F, 0x16, 0x1D, 0x24, 0x2B, 0x32, 0x39, 0x40, 0x47, 0x4E, 0x55, 0x5C, 0x63, 0x6A, 0x71, 0x78, 0x7F,
    0x86, 0x8D, 0x94, 0x9B, 0xA2, 0xA9, 0xB0, 0xB7, 0xBE, 0xC5, 0xCC, 0xD3, 0xDA};

inline constexpr Sample kContentStampTypical{.name = "ContentStamp/typical",
    .frame = kContentStampTypicalFrame,
    .encode = &encode_content_stamp_typical,
    .decode = &decode_content_stamp_typical,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_character_list_min(Buffer& out) {
    return protocol::encode(out, character_list_min());
}

[[nodiscard]] inline Check decode_character_list_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CharacterList::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, character_list_min());
}

inline constexpr std::array<std::uint8_t, 10> kCharacterListMinFrame{
    0x02, 0x00, 0x00, 0x00, 0x01, 0x82, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kCharacterListMin{.name = "CharacterList/min",
    .frame = kCharacterListMinFrame,
    .encode = &encode_character_list_min,
    .decode = &decode_character_list_min,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_character_list_max(Buffer& out) {
    return protocol::encode(out, character_list_max());
}

[[nodiscard]] inline Check decode_character_list_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CharacterList::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, character_list_max());
}

inline constexpr std::array<std::uint8_t, 554> kCharacterListMaxFrame{0x22, 0x02, 0x00, 0x00, 0x01, 0x82, 0x00, 0x00,
    0x08, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0x61, 0x61, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0x61, 0x61, 0xFF, 0xFF, 0x02, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9,
    0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3,
    0xA9, 0xE1, 0xBB, 0x87, 0x61, 0x61, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3,
    0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41,
    0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0x61, 0x61, 0xFF, 0xFF,
    0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x30, 0x00, 0x41,
    0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80,
    0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80,
    0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0x61, 0x61, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80,
    0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0,
    0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0x61,
    0x61, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0,
    0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0x61, 0x61, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x30, 0x00, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87,
    0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB,
    0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1, 0xBB, 0x87, 0xF0, 0xA0, 0x80, 0x80, 0x41, 0xC3, 0xA9, 0xE1,
    0xBB, 0x87, 0x61, 0x61, 0xFF, 0xFF, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kCharacterListMax{.name = "CharacterList/max",
    .frame = kCharacterListMaxFrame,
    .encode = &encode_character_list_max,
    .decode = &decode_character_list_max,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_character_list_typical(Buffer& out) {
    return protocol::encode(out, character_list_typical());
}

[[nodiscard]] inline Check decode_character_list_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::CharacterList::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, character_list_typical());
}

inline constexpr std::array<std::uint8_t, 92> kCharacterListTypicalFrame{0x54, 0x00, 0x00, 0x00, 0x01, 0x82, 0x00, 0x00,
    0x02, 0x00, 0xF1, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x00, 0x54, 0x68, 0x69, 0xC3, 0xAA, 0x6E, 0x20,
    0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3, 0xA1, 0x74, 0x20, 0x42, 0xE1, 0xBB, 0x99, 0xD3, 0x0B, 0x02, 0xB5, 0x13,
    0xA6, 0x17, 0x97, 0x88, 0x1F, 0xF1, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x15, 0x00, 0x54, 0x68, 0x69, 0xC3,
    0xAA, 0x6E, 0x20, 0x4C, 0x6F, 0x6E, 0x67, 0x20, 0x42, 0xC3, 0xA1, 0x74, 0x20, 0x42, 0xE1, 0xBB, 0x99, 0xD3, 0x0B,
    0x02, 0xB5, 0x13, 0xA6, 0x17, 0x97, 0x88, 0x1F};

inline constexpr Sample kCharacterListTypical{.name = "CharacterList/typical",
    .frame = kCharacterListTypicalFrame,
    .encode = &encode_character_list_typical,
    .decode = &decode_character_list_typical,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_position_min(Buffer& out) {
    return protocol::encode(out, position_min());
}

[[nodiscard]] inline Check decode_position_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Position::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, position_min());
}

inline constexpr std::array<std::uint8_t, 20> kPositionMinFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x83, 0x00, 0x00, 0xFF,
    0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kPositionMin{.name = "Position/min",
    .frame = kPositionMinFrame,
    .encode = &encode_position_min,
    .decode = &decode_position_min,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_position_max(Buffer& out) {
    return protocol::encode(out, position_max());
}

[[nodiscard]] inline Check decode_position_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Position::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, position_max());
}

inline constexpr std::array<std::uint8_t, 20> kPositionMaxFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x83, 0x00, 0x00, 0xFF,
    0xFF, 0x7F, 0x7F, 0xFF, 0xFF, 0x7F, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kPositionMax{.name = "Position/max",
    .frame = kPositionMaxFrame,
    .encode = &encode_position_max,
    .decode = &decode_position_max,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_position_typical(Buffer& out) {
    return protocol::encode(out, position_typical());
}

[[nodiscard]] inline Check decode_position_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Position::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_game_server(frame, body);
    return holds(result, position_typical());
}

inline constexpr std::array<std::uint8_t, 20> kPositionTypicalFrame{0x0C, 0x00, 0x00, 0x00, 0x01, 0x83, 0x00, 0x00,
    0x00, 0x00, 0xA0, 0x3F, 0x00, 0x00, 0x10, 0x40, 0xD3, 0x0B, 0x00, 0x00};

inline constexpr Sample kPositionTypical{.name = "Position/typical",
    .frame = kPositionTypicalFrame,
    .encode = &encode_position_typical,
    .decode = &decode_position_typical,
    .decoders = kGameServer};

[[nodiscard]] inline protocol::WireStatus encode_ticket_min(Buffer& out) {
    return protocol::encode(out, ticket_min());
}

[[nodiscard]] inline Check decode_ticket_min(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Ticket::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_server(frame, body);
    return holds(result, ticket_min());
}

inline constexpr std::array<std::uint8_t, 212> kTicketMinFrame{0xCC, 0x00, 0x00, 0x00, 0x01, 0x85, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

inline constexpr Sample kTicketMin{.name = "Ticket/min",
    .frame = kTicketMinFrame,
    .encode = &encode_ticket_min,
    .decode = &decode_ticket_min,
    .decoders = kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_ticket_max(Buffer& out) {
    return protocol::encode(out, ticket_max());
}

[[nodiscard]] inline Check decode_ticket_max(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Ticket::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_server(frame, body);
    return holds(result, ticket_max());
}

inline constexpr std::array<std::uint8_t, 212> kTicketMaxFrame{0xCC, 0x00, 0x00, 0x00, 0x01, 0x85, 0x00, 0x00, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

inline constexpr Sample kTicketMax{.name = "Ticket/max",
    .frame = kTicketMaxFrame,
    .encode = &encode_ticket_max,
    .decode = &decode_ticket_max,
    .decoders = kAuthServer};

[[nodiscard]] inline protocol::WireStatus encode_ticket_typical(Buffer& out) {
    return protocol::encode(out, ticket_typical());
}

[[nodiscard]] inline Check decode_ticket_typical(protocol::ByteView body) {
    protocol::Frame frame;
    frame.kind = protocol::Ticket::kKind;
    frame.body_bytes = body.size();
    const auto result = protocol::decode_auth_server(frame, body);
    return holds(result, ticket_typical());
}

inline constexpr std::array<std::uint8_t, 212> kTicketTypicalFrame{0xCC, 0x00, 0x00, 0x00, 0x01, 0x85, 0x00, 0x00, 0x01,
    0x08, 0x0F, 0x16, 0x1D, 0x24, 0x2B, 0x32, 0x39, 0x40, 0x47, 0x4E, 0x55, 0x5C, 0x63, 0x6A, 0x71, 0x78, 0x7F, 0x86,
    0x8D, 0x94, 0x9B, 0xA2, 0xA9, 0xB0, 0xB7, 0xBE, 0xC5, 0xCC, 0xD3, 0xDA, 0xE1, 0xE8, 0xEF, 0xF6, 0xFD, 0x04, 0x0B,
    0x12, 0x19, 0x20, 0x27, 0x2E, 0x35, 0x3C, 0x43, 0x4A, 0x51, 0x58, 0x5F, 0x66, 0x6D, 0x74, 0x7B, 0x82, 0x89, 0x90,
    0x97, 0x9E, 0xA5, 0xAC, 0xB3, 0xBA, 0xC1, 0xC8, 0xCF, 0xD6, 0xDD, 0xE4, 0xEB, 0xF2, 0xF9, 0x00, 0x07, 0x0E, 0x15,
    0x1C, 0x23, 0x2A, 0x31, 0x38, 0x3F, 0x46, 0x4D, 0x54, 0x5B, 0x62, 0x69, 0x70, 0x77, 0x7E, 0x85, 0x8C, 0x93, 0x9A,
    0xA1, 0xA8, 0xAF, 0xB6, 0xBD, 0xC4, 0xCB, 0xD2, 0xD9, 0xE0, 0xE7, 0xEE, 0xF5, 0xFC, 0x03, 0x0A, 0x11, 0x18, 0x1F,
    0x26, 0x2D, 0x34, 0x3B, 0x42, 0x49, 0x50, 0x57, 0x5E, 0x65, 0x6C, 0x73, 0x7A, 0x81, 0x88, 0x8F, 0x96, 0x9D, 0xA4,
    0xAB, 0xB2, 0xB9, 0xC0, 0xC7, 0xCE, 0xD5, 0xDC, 0xE3, 0xEA, 0xF1, 0xF8, 0xFF, 0x06, 0x0D, 0x14, 0x1B, 0x22, 0x29,
    0x30, 0x37, 0x3E, 0x45, 0x4C, 0x53, 0x5A, 0x61, 0x68, 0x6F, 0x76, 0x7D, 0x84, 0x8B, 0x92, 0x99, 0xA0, 0xA7, 0xAE,
    0xB5, 0xBC, 0xC3, 0xCA, 0xD1, 0xD8, 0xDF, 0xE6, 0xED, 0xF4, 0xFB, 0x02, 0x09, 0x10, 0x17, 0x1E, 0x25, 0x2C, 0x33,
    0x3A, 0x41, 0x48, 0x4F, 0x56, 0x5D, 0x64, 0x6B, 0x72, 0x79, 0x80, 0x87, 0x8E};

inline constexpr Sample kTicketTypical{.name = "Ticket/typical",
    .frame = kTicketTypicalFrame,
    .encode = &encode_ticket_typical,
    .decode = &decode_ticket_typical,
    .decoders = kAuthServer};

inline constexpr std::array<Sample, 63> kSamples{kHelloMin, kHelloMax, kHelloTypical, kLoginMin, kLoginMax,
    kLoginTypical, kResumeMin, kResumeMax, kResumeTypical, kPingMin, kPingMax, kPingTypical, kLogoutMin, kLogoutMax,
    kLogoutTypical, kCreateCharacterMin, kCreateCharacterMax, kCreateCharacterTypical, kDeleteCharacterMin,
    kDeleteCharacterMax, kDeleteCharacterTypical, kEnterGameMin, kEnterGameMax, kEnterGameTypical, kMoveMin, kMoveMax,
    kMoveTypical, kCreateAccountMin, kCreateAccountMax, kCreateAccountTypical, kSignInMin, kSignInMax, kSignInTypical,
    kWelcomeMin, kWelcomeMax, kWelcomeTypical, kSessionStartMin, kSessionStartMax, kSessionStartTypical, kContentKeyMin,
    kContentKeyMax, kContentKeyTypical, kPongMin, kPongMax, kPongTypical, kRejectMin, kRejectMax, kRejectTypical,
    kGoodbyeMin, kGoodbyeMax, kGoodbyeTypical, kContentStampMin, kContentStampMax, kContentStampTypical,
    kCharacterListMin, kCharacterListMax, kCharacterListTypical, kPositionMin, kPositionMax, kPositionTypical,
    kTicketMin, kTicketMax, kTicketTypical};

} // namespace game::test::samples
