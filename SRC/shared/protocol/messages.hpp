// Tệp sinh bởi TOOLS/server/gen_protocol.py từ SRC/protocol/catalog/*.tsv; không sửa tay.
// Sửa bảng rồi chạy lại: python -B TOOLS/server/gen_protocol.py
// Danh mục tin của protocol (DE-BAI P2 đợt 2 §3): enum, hằng trần, struct của từng tin, encode và bốn bộ giải mã theo
// cổng (game, auth) và chiều (client gửi, server gửi).
#pragma once

#include "protocol/wire.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <string>
#include <variant>
#include <vector>

namespace game::protocol {

// Bản của danh mục; tin có since lớn hơn bản bên kia đang chạy thì bên kia chưa hiểu.
inline constexpr std::uint16_t kVersion = 1;

enum class DisconnectReason : std::uint8_t {
    kLoggedOut = 1,
    kLoginElsewhere = 2,
    kIdle = 3,
    kKicked = 4,
    kShutdown = 5,
    kProtocolViolation = 6,
    kVersionMismatch = 7,
    kServerFull = 8,
    kContentMismatch = 9,
};

// NOLINTNEXTLINE(performance-enum-size): cỡ trên dây theo bảng, giữ byte của Dev (HP-07)
enum class ErrorCode : std::uint16_t {
    kMalformed = 1,
    kVersionMismatch = 2,
    kNotAuthenticated = 3,
    kBadCredentials = 4,
    kSessionExpired = 5,
    kOutOfOrder = 6,
    kNameTaken = 7,
    kNameInvalid = 8,
    kCharacterLimit = 9,
    kNoSuchCharacter = 10,
    kMoveBlocked = 11,
    kRateLimited = 12,
    kServerFull = 13,
    kMaintenance = 14,
    kPasswordInvalid = 15,
    kBusy = 16,
    kNoSession = 17,
    kStaleSession = 18,
    kBadOption = 19,
    kTooFar = 20,
    kNoSuchEntity = 21,
    kQuestUnavailable = 22,
    kQuestLogFull = 23,
    kQuestState = 24,
    kBagFull = 25,
    kNotEnoughMoney = 26,
    kNotEnoughItems = 27,
    kDuplicate = 28,
    kCannotAbandon = 29,
    kBadChoice = 30,
    kOutOfRange = 31,
    kCannotAttack = 32,
};

enum class Gender : std::uint8_t {
    kFemale = 1,
    kMale = 2,
};

enum class Platform : std::uint8_t {
    kWindows = 1,
    kAndroid = 2,
    kIos = 3,
};

// Giá trị có trong bảng enum; giải mã gặp giá trị lạ là kBadEnum, mã hoá cũng vậy.
[[nodiscard]] bool is_valid(DisconnectReason value) noexcept;
[[nodiscard]] bool is_valid(ErrorCode value) noexcept;
[[nodiscard]] bool is_valid(Gender value) noexcept;
[[nodiscard]] bool is_valid(Platform value) noexcept;

// Trần của từng trường: số byte của text và bytes, số phần tử của list.
inline constexpr std::size_t kCharacterSummaryNameBytes = 48;
inline constexpr std::size_t kLoginAccountBytes = 64;
inline constexpr std::size_t kLoginTicketBytes = 512;
inline constexpr std::size_t kResumeTokenBytes = 16;
inline constexpr std::size_t kCreateCharacterNameBytes = 48;
inline constexpr std::size_t kCreateAccountAccountBytes = 64;
inline constexpr std::size_t kCreateAccountPasswordBytes = 128;
inline constexpr std::size_t kSignInAccountBytes = 64;
inline constexpr std::size_t kSignInPasswordBytes = 128;
inline constexpr std::size_t kSessionStartTokenBytes = 16;
inline constexpr std::size_t kContentKeyKeyBytes = 32;
inline constexpr std::size_t kContentStampStampBytes = 32;
inline constexpr std::size_t kCharacterListCharactersCount = 8;
inline constexpr std::size_t kTicketTokenBytes = 204;

// Record: Tóm tắt một nhân vật trong danh sách chọn nhân vật.
struct CharacterSummary {
    // CharacterId của Dev.
    std::uint64_t id = 0;
    // Tên nhân vật, UTF-8, tối đa 48 byte (kNameBytes của Dev).
    std::string name;
    std::uint16_t level = 0;
    Gender gender = Gender::kFemale;
    // Id mặt trong faces.tsv mà server đã lưu; server thay kDefaultLook bằng id thật lúc tạo nhân vật, nên ở đây không
    // có nghĩa mặc định.
    std::uint16_t face = 0;
    // Id tóc trong hairs.tsv mà server đã lưu (0 là id tóc hợp lệ); kDefaultLook chỉ có nghĩa trong CreateCharacter.
    std::uint16_t hair = 0;
    // Môn phái; 0 là chưa vào môn phái, giữ giá trị canh của Dev thay cho optional.
    std::uint8_t school = 0;
    // SceneId của Dev: cảnh nhân vật đang đứng.
    std::uint16_t scene = 0;
    friend bool operator==(const CharacterSummary&, const CharacterSummary&) = default;
};

// 0x0101, client gửi, cổng both, từ bản 1: Tin đầu tiên của mọi kết nối, báo phiên bản giao thức, nền tảng và bản dựng
// client.
struct Hello {
    static constexpr std::uint16_t kKind = 0x0101;
    // Phiên bản giao thức của client.
    std::uint16_t version = 0;
    Platform platform = Platform::kWindows;
    // Số bản dựng client.
    std::uint32_t build = 0;
    friend bool operator==(const Hello&, const Hello&) = default;
};

// 0x0102, client gửi, cổng game, từ bản 1: Đăng nhập cổng game bằng vé do cổng xác thực cấp, không bao giờ mang mật
// khẩu.
struct Login {
    static constexpr std::uint16_t kKind = 0x0102;
    // Tên tài khoản (kAccountBytes của Dev).
    std::string account;
    // Vé do cổng xác thực cấp.
    std::string ticket;
    friend bool operator==(const Login&, const Login&) = default;
};

// 0x0103, client gửi, cổng game, từ bản 1: Nối lại phiên cũ bằng token phiên sau khi rớt mạng.
struct Resume {
    static constexpr std::uint16_t kKind = 0x0103;
    // Token phiên nhận trong SessionStart.
    std::array<std::byte, kResumeTokenBytes> token{};
    friend bool operator==(const Resume&, const Resume&) = default;
};

// 0x0104, client gửi, cổng game, từ bản 1: Nhịp tim của client, mang giờ client để đo độ trễ khứ hồi.
struct Ping {
    static constexpr std::uint16_t kKind = 0x0104;
    // Giờ client lúc gửi, server trả lại nguyên trong Pong. Khác Dev (duration<uint32_t, milli>): ta dùng
    // std::chrono::milliseconds có dấu để trừ hai mốc không bị quấn; trên dây vẫn u32 như Dev, ghi số âm hay trên 2^32
    // - 1 ra kOutOfRange.
    std::chrono::milliseconds client_time = std::chrono::milliseconds::zero();
    friend bool operator==(const Ping&, const Ping&) = default;
};

// 0x0105, client gửi, cổng game, từ bản 1: Client chủ động rời phiên; thân rỗng.
struct Logout {
    static constexpr std::uint16_t kKind = 0x0105;
    friend bool operator==(const Logout&, const Logout&) = default;
};

// 0x0201, client gửi, cổng game, từ bản 1: Tạo nhân vật mới với tên, giới tính, khuôn mặt và kiểu tóc.
struct CreateCharacter {
    static constexpr std::uint16_t kKind = 0x0201;
    // Tên nhân vật muốn tạo.
    std::string name;
    Gender gender = Gender::kFemale;
    // 0 là mặt mặc định (kDefaultLook của Dev).
    std::uint16_t face = 0;
    // 0 là tóc mặc định (kDefaultLook của Dev).
    std::uint16_t hair = 0;
    friend bool operator==(const CreateCharacter&, const CreateCharacter&) = default;
};

// 0x0202, client gửi, cổng game, từ bản 1: Xoá một nhân vật của tài khoản.
struct DeleteCharacter {
    static constexpr std::uint16_t kKind = 0x0202;
    // CharacterId của Dev.
    std::uint64_t character = 0;
    friend bool operator==(const DeleteCharacter&, const DeleteCharacter&) = default;
};

// 0x0203, client gửi, cổng game, từ bản 1: Vào game bằng nhân vật đã chọn.
struct EnterGame {
    static constexpr std::uint16_t kKind = 0x0203;
    // CharacterId của Dev.
    std::uint64_t character = 0;
    friend bool operator==(const EnterGame&, const EnterGame&) = default;
};

// 0x0501, client gửi, cổng auth, từ bản 1: Tạo tài khoản mới ở cổng xác thực.
struct CreateAccount {
    static constexpr std::uint16_t kKind = 0x0501;
    // Tên tài khoản (kAccountBytes của Dev).
    std::string account;
    // Mật khẩu, chỉ đi qua cổng xác thực.
    std::string password;
    friend bool operator==(const CreateAccount&, const CreateAccount&) = default;
};

// 0x0502, client gửi, cổng auth, từ bản 1: Đăng nhập bằng mật khẩu ở cổng xác thực để nhận vé.
struct SignIn {
    static constexpr std::uint16_t kKind = 0x0502;
    // Tên tài khoản (kAccountBytes của Dev).
    std::string account;
    // Mật khẩu, chỉ đi qua cổng xác thực.
    std::string password;
    friend bool operator==(const SignIn&, const SignIn&) = default;
};

// 0x8101, server gửi, cổng both, từ bản 1: Server đáp Hello: phiên bản giao thức, giờ server và chu kỳ nhịp tim.
struct Welcome {
    static constexpr std::uint16_t kKind = 0x8101;
    // Phiên bản giao thức của server.
    std::uint16_t version = 0;
    // Giờ server theo mili giây. Khác Dev (duration<uint64_t, milli>): ta dùng std::chrono::milliseconds nền int64 có
    // dấu để trừ hai mốc không bị quấn; trên dây vẫn u64, nhưng số trên 2^63 - 1 (khoảng 292 triệu năm, chỉ có ở dữ
    // liệu hỏng) đọc ra kOutOfRange, ghi số âm cũng ra kOutOfRange.
    std::chrono::milliseconds server_time = std::chrono::milliseconds::zero();
    // Chu kỳ client phải gửi Ping. Khác Dev (duration<uint16_t>): ta dùng std::chrono::seconds có dấu cho cùng kiểu giờ
    // với phần còn lại; trên dây vẫn u16 như Dev, ghi số âm hay trên 65535 ra kOutOfRange.
    std::chrono::seconds heartbeat = std::chrono::seconds::zero();
    friend bool operator==(const Welcome&, const Welcome&) = default;
};

// 0x8102, server gửi, cổng game, từ bản 1: Server mở phiên và cấp token để nối lại sau này.
struct SessionStart {
    static constexpr std::uint16_t kKind = 0x8102;
    // Token phiên dùng cho Resume.
    std::array<std::byte, kSessionStartTokenBytes> token{};
    friend bool operator==(const SessionStart&, const SessionStart&) = default;
};

// 0x8103, server gửi, cổng game, từ bản 1: Khoá giải mã gói nội dung của phiên.
struct ContentKey {
    static constexpr std::uint16_t kKind = 0x8103;
    // Khoá giải mã gói nội dung.
    std::array<std::byte, kContentKeyKeyBytes> key{};
    friend bool operator==(const ContentKey&, const ContentKey&) = default;
};

// 0x8104, server gửi, cổng game, từ bản 1: Server đáp Ping, trả lại giờ client kèm giờ server.
struct Pong {
    static constexpr std::uint16_t kKind = 0x8104;
    // Giờ client lấy nguyên từ Ping. Khác Dev như Ping.client_time: std::chrono::milliseconds có dấu thay cho
    // duration<uint32_t, milli>, trên dây vẫn u32.
    std::chrono::milliseconds client_time = std::chrono::milliseconds::zero();
    // Giờ server lúc trả lời. Khác Dev như Welcome.server_time: nền int64 có dấu thay cho u64, số trên 2^63 - 1 đọc ra
    // kOutOfRange.
    std::chrono::milliseconds server_time = std::chrono::milliseconds::zero();
    friend bool operator==(const Pong&, const Pong&) = default;
};

// 0x8106, server gửi, cổng both, từ bản 1: Server từ chối một tin của client và nêu mã lỗi.
struct Reject {
    static constexpr std::uint16_t kKind = 0x8106;
    // Mã tin của client bị từ chối; để u16 thay vì enum để giữ nguyên byte của Dev và không chép mã tin vào enums.tsv.
    std::uint16_t request = 0;
    ErrorCode code = ErrorCode::kMalformed;
    friend bool operator==(const Reject&, const Reject&) = default;
};

// 0x8107, server gửi, cổng both, từ bản 1: Server báo sắp đóng kết nối và nêu lý do.
struct Goodbye {
    static constexpr std::uint16_t kKind = 0x8107;
    DisconnectReason reason = DisconnectReason::kLoggedOut;
    friend bool operator==(const Goodbye&, const Goodbye&) = default;
};

// 0x8108, server gửi, cổng game, từ bản 1: Dấu băm của gói nội dung để client đối chiếu với bản đang có.
struct ContentStamp {
    static constexpr std::uint16_t kKind = 0x8108;
    // Dấu băm của gói nội dung.
    std::array<std::byte, kContentStampStampBytes> stamp{};
    friend bool operator==(const ContentStamp&, const ContentStamp&) = default;
};

// 0x8201, server gửi, cổng game, từ bản 1: Danh sách nhân vật của tài khoản để chọn vào game.
struct CharacterList {
    static constexpr std::uint16_t kKind = 0x8201;
    // Tối đa 8 nhân vật mỗi tài khoản (kCharacterSlots của Dev).
    std::vector<CharacterSummary> characters;
    friend bool operator==(const CharacterList&, const CharacterList&) = default;
};

// 0x8501, server gửi, cổng auth, từ bản 1: Vé vào cổng game do cổng xác thực cấp sau khi đăng nhập đúng.
struct Ticket {
    static constexpr std::uint16_t kKind = 0x8501;
    // Vé vào cổng game (kConnectTokenBytes của Dev).
    std::array<std::byte, kTicketTokenBytes> token{};
    friend bool operator==(const Ticket&, const Ticket&) = default;
};

using GameClientMessage = std::variant<Hello, Login, Resume, Ping, Logout, CreateCharacter, DeleteCharacter, EnterGame>;
using GameClientResult = std::expected<GameClientMessage, WireError>;
using GameServerMessage =
    std::variant<Welcome, SessionStart, ContentKey, Pong, Reject, Goodbye, ContentStamp, CharacterList>;
using GameServerResult = std::expected<GameServerMessage, WireError>;
using AuthClientMessage = std::variant<Hello, CreateAccount, SignIn>;
using AuthClientResult = std::expected<AuthClientMessage, WireError>;
using AuthServerMessage = std::variant<Welcome, Reject, Goodbye, Ticket>;
using AuthServerResult = std::expected<AuthServerMessage, WireError>;

// Ghi một khung (đầu khung 8 byte cộng thân) vào cuối out; lỗi thì out giữ nguyên cỡ cũ.
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Hello& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Login& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Resume& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Ping& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Logout& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CreateCharacter& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const DeleteCharacter& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EnterGame& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CreateAccount& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SignIn& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Welcome& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SessionStart& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const ContentKey& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Pong& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Reject& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Goodbye& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const ContentStamp& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CharacterList& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Ticket& message);

// Giải mã thân của một khung đã tách bằng peek_frame. Kind không thuộc cổng hoặc chiều của bộ giải
// mã là kUnknownKind; còn byte sau trường cuối là kTrailingBytes.
[[nodiscard]] GameClientResult decode_game_client(const Frame& frame, ByteView body);
[[nodiscard]] GameServerResult decode_game_server(const Frame& frame, ByteView body);
[[nodiscard]] AuthClientResult decode_auth_client(const Frame& frame, ByteView body);
[[nodiscard]] AuthServerResult decode_auth_server(const Frame& frame, ByteView body);

} // namespace game::protocol
