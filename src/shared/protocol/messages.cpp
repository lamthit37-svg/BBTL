// Tệp sinh bởi TOOLS/server/gen_protocol.py từ src/shared/protocol/catalog/*.tsv; không sửa tay.
// Sửa bảng rồi chạy lại: python -B TOOLS/server/gen_protocol.py
// Mã hoá và giải mã của danh mục tin: mỗi tin một hàm ghi và một hàm đọc từng trường theo order. Mọi byte đi qua Writer
// và Reader của wire.hpp, nên trần, UTF-8 và byte thừa chỉ kiểm ở một chỗ.
#include "protocol/messages.hpp"

#include "protocol/wire.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <utility>
#include <vector>

namespace game::protocol {
namespace {

void put_millis32(Writer& writer, std::chrono::milliseconds value) {
    if (value.count() < 0 || value.count() > 0xFFFF'FFFF) writer.fail(WireError::kOutOfRange);
    writer.u32(static_cast<std::uint32_t>(value.count()));
}

[[nodiscard]] std::chrono::milliseconds get_millis32(Reader& reader) {
    return std::chrono::milliseconds{reader.u32()};
}

void put_millis64(Writer& writer, std::chrono::milliseconds value) {
    if (value.count() < 0) writer.fail(WireError::kOutOfRange);
    writer.u64(static_cast<std::uint64_t>(value.count()));
}

// Số u64 trên 2^63 - 1 không vừa rep int64 của milliseconds: kOutOfRange.
[[nodiscard]] std::chrono::milliseconds get_millis64(Reader& reader) {
    const std::uint64_t raw = reader.u64();
    const bool fits = std::cmp_less_equal(raw, std::numeric_limits<std::int64_t>::max());
    if (!fits) reader.fail(WireError::kOutOfRange);
    return std::chrono::milliseconds{fits ? static_cast<std::int64_t>(raw) : 0};
}

void put_seconds16(Writer& writer, std::chrono::seconds value) {
    if (value.count() < 0 || value.count() > 0xFFFF) writer.fail(WireError::kOutOfRange);
    writer.u16(static_cast<std::uint16_t>(value.count()));
}

[[nodiscard]] std::chrono::seconds get_seconds16(Reader& reader) {
    return std::chrono::seconds{reader.u16()};
}

void put_avatar_frame(Writer& writer, AvatarFrame value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] AvatarFrame get_avatar_frame(Reader& reader) {
    const auto value = static_cast<AvatarFrame>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_disconnect_reason(Writer& writer, DisconnectReason value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] DisconnectReason get_disconnect_reason(Reader& reader) {
    const auto value = static_cast<DisconnectReason>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_entity_kind(Writer& writer, EntityKind value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] EntityKind get_entity_kind(Reader& reader) {
    const auto value = static_cast<EntityKind>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_error_code(Writer& writer, ErrorCode value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u16(std::to_underlying(value));
}

[[nodiscard]] ErrorCode get_error_code(Reader& reader) {
    const auto value = static_cast<ErrorCode>(reader.u16());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_gender(Writer& writer, Gender value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] Gender get_gender(Reader& reader) {
    const auto value = static_cast<Gender>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_platform(Writer& writer, Platform value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] Platform get_platform(Reader& reader) {
    const auto value = static_cast<Platform>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_character_summary(Writer& writer, const CharacterSummary& message) {
    writer.u64(message.id);
    writer.text(message.name, kCharacterSummaryNameBytes);
    writer.u16(message.level);
    put_gender(writer, message.gender);
    writer.u16(message.face);
    writer.u16(message.hair);
    writer.u8(message.school);
    writer.u16(message.scene);
}

[[nodiscard]] CharacterSummary get_character_summary(Reader& reader) {
    CharacterSummary message;
    message.id = reader.u64();
    message.name = reader.text(kCharacterSummaryNameBytes);
    message.level = reader.u16();
    message.gender = get_gender(reader);
    message.face = reader.u16();
    message.hair = reader.u16();
    message.school = reader.u8();
    message.scene = reader.u16();
    return message;
}

void put_hello(Writer& writer, const Hello& message) {
    writer.u16(message.version);
    put_platform(writer, message.platform);
    writer.u32(message.build);
}

[[nodiscard]] Hello get_hello(Reader& reader) {
    Hello message;
    message.version = reader.u16();
    message.platform = get_platform(reader);
    message.build = reader.u32();
    return message;
}

void put_login(Writer& writer, const Login& message) {
    writer.text(message.account, kLoginAccountBytes);
    writer.text(message.ticket, kLoginTicketBytes);
}

[[nodiscard]] Login get_login(Reader& reader) {
    Login message;
    message.account = reader.text(kLoginAccountBytes);
    message.ticket = reader.text(kLoginTicketBytes);
    return message;
}

void put_resume(Writer& writer, const Resume& message) {
    writer.bytes(message.token);
}

[[nodiscard]] Resume get_resume(Reader& reader) {
    Resume message;
    reader.bytes(message.token);
    return message;
}

void put_ping(Writer& writer, const Ping& message) {
    put_millis32(writer, message.client_time);
}

[[nodiscard]] Ping get_ping(Reader& reader) {
    Ping message;
    message.client_time = get_millis32(reader);
    return message;
}

void put_create_character(Writer& writer, const CreateCharacter& message) {
    writer.text(message.name, kCreateCharacterNameBytes);
    put_gender(writer, message.gender);
    writer.u16(message.face);
    writer.u16(message.hair);
}

[[nodiscard]] CreateCharacter get_create_character(Reader& reader) {
    CreateCharacter message;
    message.name = reader.text(kCreateCharacterNameBytes);
    message.gender = get_gender(reader);
    message.face = reader.u16();
    message.hair = reader.u16();
    return message;
}

void put_delete_character(Writer& writer, const DeleteCharacter& message) {
    writer.u64(message.character);
}

[[nodiscard]] DeleteCharacter get_delete_character(Reader& reader) {
    DeleteCharacter message;
    message.character = reader.u64();
    return message;
}

void put_enter_game(Writer& writer, const EnterGame& message) {
    writer.u64(message.character);
}

[[nodiscard]] EnterGame get_enter_game(Reader& reader) {
    EnterGame message;
    message.character = reader.u64();
    return message;
}

void put_move(Writer& writer, const Move& message) {
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
    writer.u32(message.tick);
}

[[nodiscard]] Move get_move(Reader& reader) {
    Move message;
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.tick = reader.u32();
    return message;
}

void put_create_account(Writer& writer, const CreateAccount& message) {
    writer.text(message.account, kCreateAccountAccountBytes);
    writer.text(message.password, kCreateAccountPasswordBytes);
}

[[nodiscard]] CreateAccount get_create_account(Reader& reader) {
    CreateAccount message;
    message.account = reader.text(kCreateAccountAccountBytes);
    message.password = reader.text(kCreateAccountPasswordBytes);
    return message;
}

void put_sign_in(Writer& writer, const SignIn& message) {
    writer.text(message.account, kSignInAccountBytes);
    writer.text(message.password, kSignInPasswordBytes);
}

[[nodiscard]] SignIn get_sign_in(Reader& reader) {
    SignIn message;
    message.account = reader.text(kSignInAccountBytes);
    message.password = reader.text(kSignInPasswordBytes);
    return message;
}

void put_welcome(Writer& writer, const Welcome& message) {
    writer.u16(message.version);
    put_millis64(writer, message.server_time);
    put_seconds16(writer, message.heartbeat);
}

[[nodiscard]] Welcome get_welcome(Reader& reader) {
    Welcome message;
    message.version = reader.u16();
    message.server_time = get_millis64(reader);
    message.heartbeat = get_seconds16(reader);
    return message;
}

void put_session_start(Writer& writer, const SessionStart& message) {
    writer.bytes(message.token);
}

[[nodiscard]] SessionStart get_session_start(Reader& reader) {
    SessionStart message;
    reader.bytes(message.token);
    return message;
}

void put_content_key(Writer& writer, const ContentKey& message) {
    writer.bytes(message.key);
}

[[nodiscard]] ContentKey get_content_key(Reader& reader) {
    ContentKey message;
    reader.bytes(message.key);
    return message;
}

void put_pong(Writer& writer, const Pong& message) {
    put_millis32(writer, message.client_time);
    put_millis64(writer, message.server_time);
}

[[nodiscard]] Pong get_pong(Reader& reader) {
    Pong message;
    message.client_time = get_millis32(reader);
    message.server_time = get_millis64(reader);
    return message;
}

void put_reject(Writer& writer, const Reject& message) {
    writer.u16(message.request);
    put_error_code(writer, message.code);
}

[[nodiscard]] Reject get_reject(Reader& reader) {
    Reject message;
    message.request = reader.u16();
    message.code = get_error_code(reader);
    return message;
}

void put_goodbye(Writer& writer, const Goodbye& message) {
    put_disconnect_reason(writer, message.reason);
}

[[nodiscard]] Goodbye get_goodbye(Reader& reader) {
    Goodbye message;
    message.reason = get_disconnect_reason(reader);
    return message;
}

void put_content_stamp(Writer& writer, const ContentStamp& message) {
    writer.bytes(message.stamp);
}

[[nodiscard]] ContentStamp get_content_stamp(Reader& reader) {
    ContentStamp message;
    reader.bytes(message.stamp);
    return message;
}

void put_ui_config(Writer& writer, const UiConfig& message) {
    put_avatar_frame(writer, message.avatar_frame);
}

[[nodiscard]] UiConfig get_ui_config(Reader& reader) {
    UiConfig message;
    message.avatar_frame = get_avatar_frame(reader);
    return message;
}

// list:record:CharacterSummary, tối đa kCharacterListCharactersCount phần tử.
void put_list_1(Writer& writer, const std::vector<CharacterSummary>& values) {
    writer.count(values.size(), kCharacterListCharactersCount);
    for (const auto& value : values) {
        put_character_summary(writer, value);
    }
}

[[nodiscard]] std::vector<CharacterSummary> get_list_1(Reader& reader) {
    const std::size_t count = reader.count(kCharacterListCharactersCount);
    std::vector<CharacterSummary> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_character_summary(reader));
    }
    return values;
}

void put_character_list(Writer& writer, const CharacterList& message) {
    put_list_1(writer, message.characters);
}

[[nodiscard]] CharacterList get_character_list(Reader& reader) {
    CharacterList message;
    message.characters = get_list_1(reader);
    return message;
}

void put_position(Writer& writer, const Position& message) {
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
    writer.u32(message.tick);
}

[[nodiscard]] Position get_position(Reader& reader) {
    Position message;
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.tick = reader.u32();
    return message;
}

void put_scene_enter(Writer& writer, const SceneEnter& message) {
    writer.u16(message.scene);
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
    writer.u16(message.direction);
}

[[nodiscard]] SceneEnter get_scene_enter(Reader& reader) {
    SceneEnter message;
    message.scene = reader.u16();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.direction = reader.u16();
    return message;
}

void put_entity_appear(Writer& writer, const EntityAppear& message) {
    writer.u32(message.id);
    put_entity_kind(writer, message.kind);
    writer.u32(message.template_id);
    writer.text(message.name, kEntityAppearNameBytes);
    writer.u16(message.level);
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
    writer.u16(message.direction);
    writer.u16(message.speed_cm);
    writer.u8(message.hp_percent);
    writer.u8(message.gender);
    writer.u16(message.face);
    writer.u16(message.hair);
    writer.u8(message.school);
}

[[nodiscard]] EntityAppear get_entity_appear(Reader& reader) {
    EntityAppear message;
    message.id = reader.u32();
    message.kind = get_entity_kind(reader);
    message.template_id = reader.u32();
    message.name = reader.text(kEntityAppearNameBytes);
    message.level = reader.u16();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.direction = reader.u16();
    message.speed_cm = reader.u16();
    message.hp_percent = reader.u8();
    message.gender = reader.u8();
    message.face = reader.u16();
    message.hair = reader.u16();
    message.school = reader.u8();
    return message;
}

void put_entity_disappear(Writer& writer, const EntityDisappear& message) {
    writer.u32(message.id);
}

[[nodiscard]] EntityDisappear get_entity_disappear(Reader& reader) {
    EntityDisappear message;
    message.id = reader.u32();
    return message;
}

void put_entity_pos(Writer& writer, const EntityPos& message) {
    writer.u32(message.id);
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
    writer.u16(message.direction);
    writer.u32(message.tick);
}

[[nodiscard]] EntityPos get_entity_pos(Reader& reader) {
    EntityPos message;
    message.id = reader.u32();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.direction = reader.u16();
    message.tick = reader.u32();
    return message;
}

void put_entity_vitals(Writer& writer, const EntityVitals& message) {
    writer.u32(message.id);
    writer.u8(message.hp_percent);
}

[[nodiscard]] EntityVitals get_entity_vitals(Reader& reader) {
    EntityVitals message;
    message.id = reader.u32();
    message.hp_percent = reader.u8();
    return message;
}

void put_ticket(Writer& writer, const Ticket& message) {
    writer.bytes(message.token);
}

[[nodiscard]] Ticket get_ticket(Reader& reader) {
    Ticket message;
    reader.bytes(message.token);
    return message;
}

// Thân phải hết đúng lúc đọc xong trường cuối; lỗi đầu tiên của reader được giữ.
template <class Message>
[[nodiscard]] std::expected<Message, WireError> checked(const Reader& reader, Message message) {
    const WireStatus status = reader.finish();
    if (!status) return std::unexpected(status.error());
    return message;
}

} // namespace

bool is_valid(AvatarFrame value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 2;
}

bool is_valid(DisconnectReason value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 9;
}

bool is_valid(EntityKind value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 6;
}

bool is_valid(ErrorCode value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 32;
}

bool is_valid(Gender value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 2;
}

bool is_valid(Platform value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 3;
}

WireStatus encode(std::vector<std::byte>& out, const Hello& message) {
    Writer writer{out};
    put_hello(writer, message);
    return writer.finish(Hello::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Login& message) {
    Writer writer{out};
    put_login(writer, message);
    return writer.finish(Login::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Resume& message) {
    Writer writer{out};
    put_resume(writer, message);
    return writer.finish(Resume::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Ping& message) {
    Writer writer{out};
    put_ping(writer, message);
    return writer.finish(Ping::kKind);
}

WireStatus encode(std::vector<std::byte>& out, [[maybe_unused]] const Logout& message) {
    Writer writer{out};
    return writer.finish(Logout::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const CreateCharacter& message) {
    Writer writer{out};
    put_create_character(writer, message);
    return writer.finish(CreateCharacter::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const DeleteCharacter& message) {
    Writer writer{out};
    put_delete_character(writer, message);
    return writer.finish(DeleteCharacter::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const EnterGame& message) {
    Writer writer{out};
    put_enter_game(writer, message);
    return writer.finish(EnterGame::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Move& message) {
    Writer writer{out};
    put_move(writer, message);
    return writer.finish(Move::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const CreateAccount& message) {
    Writer writer{out};
    put_create_account(writer, message);
    return writer.finish(CreateAccount::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SignIn& message) {
    Writer writer{out};
    put_sign_in(writer, message);
    return writer.finish(SignIn::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Welcome& message) {
    Writer writer{out};
    put_welcome(writer, message);
    return writer.finish(Welcome::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SessionStart& message) {
    Writer writer{out};
    put_session_start(writer, message);
    return writer.finish(SessionStart::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const ContentKey& message) {
    Writer writer{out};
    put_content_key(writer, message);
    return writer.finish(ContentKey::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Pong& message) {
    Writer writer{out};
    put_pong(writer, message);
    return writer.finish(Pong::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Reject& message) {
    Writer writer{out};
    put_reject(writer, message);
    return writer.finish(Reject::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Goodbye& message) {
    Writer writer{out};
    put_goodbye(writer, message);
    return writer.finish(Goodbye::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const ContentStamp& message) {
    Writer writer{out};
    put_content_stamp(writer, message);
    return writer.finish(ContentStamp::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const UiConfig& message) {
    Writer writer{out};
    put_ui_config(writer, message);
    return writer.finish(UiConfig::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const CharacterList& message) {
    Writer writer{out};
    put_character_list(writer, message);
    return writer.finish(CharacterList::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Position& message) {
    Writer writer{out};
    put_position(writer, message);
    return writer.finish(Position::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SceneEnter& message) {
    Writer writer{out};
    put_scene_enter(writer, message);
    return writer.finish(SceneEnter::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const EntityAppear& message) {
    Writer writer{out};
    put_entity_appear(writer, message);
    return writer.finish(EntityAppear::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const EntityDisappear& message) {
    Writer writer{out};
    put_entity_disappear(writer, message);
    return writer.finish(EntityDisappear::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const EntityPos& message) {
    Writer writer{out};
    put_entity_pos(writer, message);
    return writer.finish(EntityPos::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const EntityVitals& message) {
    Writer writer{out};
    put_entity_vitals(writer, message);
    return writer.finish(EntityVitals::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Ticket& message) {
    Writer writer{out};
    put_ticket(writer, message);
    return writer.finish(Ticket::kKind);
}

GameClientResult decode_game_client(const Frame& frame, ByteView body) {
    Reader reader{body};
    switch (frame.kind) {
    case Hello::kKind: return checked(reader, get_hello(reader));
    case Login::kKind: return checked(reader, get_login(reader));
    case Resume::kKind: return checked(reader, get_resume(reader));
    case Ping::kKind: return checked(reader, get_ping(reader));
    case Logout::kKind: return checked(reader, Logout{});
    case CreateCharacter::kKind: return checked(reader, get_create_character(reader));
    case DeleteCharacter::kKind: return checked(reader, get_delete_character(reader));
    case EnterGame::kKind: return checked(reader, get_enter_game(reader));
    case Move::kKind: return checked(reader, get_move(reader));
    default: return std::unexpected(WireError::kUnknownKind);
    }
}

GameServerResult decode_game_server(const Frame& frame, ByteView body) {
    Reader reader{body};
    switch (frame.kind) {
    case Welcome::kKind: return checked(reader, get_welcome(reader));
    case SessionStart::kKind: return checked(reader, get_session_start(reader));
    case ContentKey::kKind: return checked(reader, get_content_key(reader));
    case Pong::kKind: return checked(reader, get_pong(reader));
    case Reject::kKind: return checked(reader, get_reject(reader));
    case Goodbye::kKind: return checked(reader, get_goodbye(reader));
    case ContentStamp::kKind: return checked(reader, get_content_stamp(reader));
    case UiConfig::kKind: return checked(reader, get_ui_config(reader));
    case CharacterList::kKind: return checked(reader, get_character_list(reader));
    case Position::kKind: return checked(reader, get_position(reader));
    case SceneEnter::kKind: return checked(reader, get_scene_enter(reader));
    case EntityAppear::kKind: return checked(reader, get_entity_appear(reader));
    case EntityDisappear::kKind: return checked(reader, get_entity_disappear(reader));
    case EntityPos::kKind: return checked(reader, get_entity_pos(reader));
    case EntityVitals::kKind: return checked(reader, get_entity_vitals(reader));
    default: return std::unexpected(WireError::kUnknownKind);
    }
}

AuthClientResult decode_auth_client(const Frame& frame, ByteView body) {
    Reader reader{body};
    switch (frame.kind) {
    case Hello::kKind: return checked(reader, get_hello(reader));
    case CreateAccount::kKind: return checked(reader, get_create_account(reader));
    case SignIn::kKind: return checked(reader, get_sign_in(reader));
    default: return std::unexpected(WireError::kUnknownKind);
    }
}

AuthServerResult decode_auth_server(const Frame& frame, ByteView body) {
    Reader reader{body};
    switch (frame.kind) {
    case Welcome::kKind: return checked(reader, get_welcome(reader));
    case Reject::kKind: return checked(reader, get_reject(reader));
    case Goodbye::kKind: return checked(reader, get_goodbye(reader));
    case Ticket::kKind: return checked(reader, get_ticket(reader));
    default: return std::unexpected(WireError::kUnknownKind);
    }
}

} // namespace game::protocol
