/*==============================================================================
 *  THIENLONG  |  SHARED
 *------------------------------------------------------------------------------
 *  TỆP       : src/shared/protocol/messages.cpp
 *  PHÂN HỆ   : Shared / Protocol / Messages
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tệp sinh bởi gen_protocol.py từ các bảng .tsv trong catalog/; không sửa
 *    tay.
 *  - Sửa bảng rồi chạy: python -B TOOLS/server/gen_protocol.py
 *  - Mã hoá và giải mã của danh mục tin: mỗi tin một hàm ghi và một hàm đọc
 *    từng trường theo order. Mọi byte đi qua Writer và Reader của wire.hpp, nên
 *    trần, UTF-8 và byte thừa chỉ kiểm ở một chỗ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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

void put_bonus_kind(Writer& writer, BonusKind value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] BonusKind get_bonus_kind(Reader& reader) {
    const auto value = static_cast<BonusKind>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_combat_kind(Writer& writer, CombatKind value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] CombatKind get_combat_kind(Reader& reader) {
    const auto value = static_cast<CombatKind>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_dialog_close_reason(Writer& writer, DialogCloseReason value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] DialogCloseReason get_dialog_close_reason(Reader& reader) {
    const auto value = static_cast<DialogCloseReason>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_dialog_mode(Writer& writer, DialogMode value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] DialogMode get_dialog_mode(Reader& reader) {
    const auto value = static_cast<DialogMode>(reader.u8());
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

void put_entity_state(Writer& writer, EntityState value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] EntityState get_entity_state(Reader& reader) {
    const auto value = static_cast<EntityState>(reader.u8());
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

void put_mark_stage(Writer& writer, MarkStage value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] MarkStage get_mark_stage(Reader& reader) {
    const auto value = static_cast<MarkStage>(reader.u8());
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

void put_quest_notice_kind(Writer& writer, QuestNoticeKind value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] QuestNoticeKind get_quest_notice_kind(Reader& reader) {
    const auto value = static_cast<QuestNoticeKind>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_respawn_place(Writer& writer, RespawnPlace value) {
    if (!is_valid(value)) writer.fail(WireError::kBadEnum);
    writer.u8(std::to_underlying(value));
}

[[nodiscard]] RespawnPlace get_respawn_place(Reader& reader) {
    const auto value = static_cast<RespawnPlace>(reader.u8());
    if (!is_valid(value)) reader.fail(WireError::kBadEnum);
    return value;
}

void put_bag_slot(Writer& writer, const BagSlot& message) {
    writer.u16(message.slot);
    writer.u32(message.item);
    writer.u16(message.count);
    writer.boolean(message.bound);
}

[[nodiscard]] BagSlot get_bag_slot(Reader& reader) {
    BagSlot message;
    message.slot = reader.u16();
    message.item = reader.u32();
    message.count = reader.u16();
    message.bound = reader.boolean();
    return message;
}

void put_buff_entry(Writer& writer, const BuffEntry& message) {
    writer.u32(message.effect);
    writer.i32(message.serial);
    writer.u32(message.sender);
    writer.u16(message.skill);
    writer.i32(message.remaining_ms);
}

[[nodiscard]] BuffEntry get_buff_entry(Reader& reader) {
    BuffEntry message;
    message.effect = reader.u32();
    message.serial = reader.i32();
    message.sender = reader.u32();
    message.skill = reader.u16();
    message.remaining_ms = reader.i32();
    return message;
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
    writer.u16(message.portrait);
    writer.u16(message.equip_set);
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
    message.portrait = reader.u16();
    message.equip_set = reader.u16();
    return message;
}

void put_dialog_bonus(Writer& writer, const DialogBonus& message) {
    put_bonus_kind(writer, message.kind);
    writer.i32(message.a);
    writer.i32(message.b);
    writer.i32(message.c);
}

[[nodiscard]] DialogBonus get_dialog_bonus(Reader& reader) {
    DialogBonus message;
    message.kind = get_bonus_kind(reader);
    message.a = reader.i32();
    message.b = reader.i32();
    message.c = reader.i32();
    return message;
}

void put_dialog_choice(Writer& writer, const DialogChoice& message) {
    writer.u16(message.index);
    writer.i32(message.icon);
    writer.text(message.text, kDialogChoiceTextBytes);
}

[[nodiscard]] DialogChoice get_dialog_choice(Reader& reader) {
    DialogChoice message;
    message.index = reader.u16();
    message.icon = reader.i32();
    message.text = reader.text(kDialogChoiceTextBytes);
    return message;
}

void put_dialog_line(Writer& writer, const DialogLine& message) {
    writer.text(message.text, kDialogLineTextBytes);
}

[[nodiscard]] DialogLine get_dialog_line(Reader& reader) {
    DialogLine message;
    message.text = reader.text(kDialogLineTextBytes);
    return message;
}

void put_dialog_mark(Writer& writer, const DialogMark& message) {
    writer.u16(message.quest);
    put_mark_stage(writer, message.stage);
}

[[nodiscard]] DialogMark get_dialog_mark(Reader& reader) {
    DialogMark message;
    message.quest = reader.u16();
    message.stage = get_mark_stage(reader);
    return message;
}

void put_pos_entry(Writer& writer, const PosEntry& message) {
    writer.u32(message.id);
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
    writer.u16(message.direction);
    writer.u32(message.tick);
    put_entity_state(writer, message.state);
}

[[nodiscard]] PosEntry get_pos_entry(Reader& reader) {
    PosEntry message;
    message.id = reader.u32();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.direction = reader.u16();
    message.tick = reader.u32();
    message.state = get_entity_state(reader);
    return message;
}

// list:u32, tối đa kQuestSlotParamsCount phần tử.
void put_list_1(Writer& writer, const std::vector<std::uint32_t>& values) {
    writer.count(values.size(), kQuestSlotParamsCount);
    for (const auto& value : values) {
        writer.u32(value);
    }
}

[[nodiscard]] std::vector<std::uint32_t> get_list_1(Reader& reader) {
    const std::size_t count = reader.count(kQuestSlotParamsCount);
    std::vector<std::uint32_t> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(reader.u32());
    }
    return values;
}

void put_quest_slot(Writer& writer, const QuestSlot& message) {
    writer.u16(message.quest);
    writer.i32(message.script);
    writer.u8(message.flags);
    put_list_1(writer, message.params);
}

[[nodiscard]] QuestSlot get_quest_slot(Reader& reader) {
    QuestSlot message;
    message.quest = reader.u16();
    message.script = reader.i32();
    message.flags = reader.u8();
    message.params = get_list_1(reader);
    return message;
}

void put_skill_entry(Writer& writer, const SkillEntry& message) {
    writer.u16(message.skill);
    writer.u8(message.level);
    writer.u32(message.cooldown_ms);
}

[[nodiscard]] SkillEntry get_skill_entry(Reader& reader) {
    SkillEntry message;
    message.skill = reader.u16();
    message.level = reader.u8();
    message.cooldown_ms = reader.u32();
    return message;
}

void put_ui_string(Writer& writer, const UiString& message) {
    writer.text(message.text, kUiStringTextBytes);
}

[[nodiscard]] UiString get_ui_string(Reader& reader) {
    UiString message;
    message.text = reader.text(kUiStringTextBytes);
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
    writer.u16(message.portrait);
    writer.u16(message.equip_set);
}

[[nodiscard]] CreateCharacter get_create_character(Reader& reader) {
    CreateCharacter message;
    message.name = reader.text(kCreateCharacterNameBytes);
    message.gender = get_gender(reader);
    message.face = reader.u16();
    message.hair = reader.u16();
    message.portrait = reader.u16();
    message.equip_set = reader.u16();
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

void put_talk(Writer& writer, const Talk& message) {
    writer.u32(message.npc);
}

[[nodiscard]] Talk get_talk(Reader& reader) {
    Talk message;
    message.npc = reader.u32();
    return message;
}

void put_dialog_choose(Writer& writer, const DialogChoose& message) {
    writer.u64(message.session);
    writer.u16(message.index);
}

[[nodiscard]] DialogChoose get_dialog_choose(Reader& reader) {
    DialogChoose message;
    message.session = reader.u64();
    message.index = reader.u16();
    return message;
}

void put_quest_accept(Writer& writer, const QuestAccept& message) {
    writer.u64(message.session);
    writer.u16(message.quest);
}

[[nodiscard]] QuestAccept get_quest_accept(Reader& reader) {
    QuestAccept message;
    message.session = reader.u64();
    message.quest = reader.u16();
    return message;
}

void put_quest_turn_in(Writer& writer, const QuestTurnIn& message) {
    writer.u64(message.session);
    writer.u16(message.quest);
    writer.i32(message.reward);
}

[[nodiscard]] QuestTurnIn get_quest_turn_in(Reader& reader) {
    QuestTurnIn message;
    message.session = reader.u64();
    message.quest = reader.u16();
    message.reward = reader.i32();
    return message;
}

void put_quest_abandon(Writer& writer, const QuestAbandon& message) {
    writer.u16(message.quest);
}

[[nodiscard]] QuestAbandon get_quest_abandon(Reader& reader) {
    QuestAbandon message;
    message.quest = reader.u16();
    return message;
}

void put_dialog_close(Writer& writer, const DialogClose& message) {
    writer.u64(message.session);
}

[[nodiscard]] DialogClose get_dialog_close(Reader& reader) {
    DialogClose message;
    message.session = reader.u64();
    return message;
}

// list:i32, tối đa kExecuteScriptParamsCount phần tử.
void put_list_2(Writer& writer, const std::vector<std::int32_t>& values) {
    writer.count(values.size(), kExecuteScriptParamsCount);
    for (const auto& value : values) {
        writer.i32(value);
    }
}

[[nodiscard]] std::vector<std::int32_t> get_list_2(Reader& reader) {
    const std::size_t count = reader.count(kExecuteScriptParamsCount);
    std::vector<std::int32_t> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(reader.i32());
    }
    return values;
}

void put_execute_script(Writer& writer, const ExecuteScript& message) {
    writer.i32(message.script);
    writer.text(message.function, kExecuteScriptFunctionBytes);
    put_list_2(writer, message.params);
}

[[nodiscard]] ExecuteScript get_execute_script(Reader& reader) {
    ExecuteScript message;
    message.script = reader.i32();
    message.function = reader.text(kExecuteScriptFunctionBytes);
    message.params = get_list_2(reader);
    return message;
}

void put_cast_skill(Writer& writer, const CastSkill& message) {
    writer.u16(message.seq);
    writer.u16(message.skill);
    writer.u32(message.target);
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
}

[[nodiscard]] CastSkill get_cast_skill(Reader& reader) {
    CastSkill message;
    message.seq = reader.u16();
    message.skill = reader.u16();
    message.target = reader.u32();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    return message;
}

void put_respawn(Writer& writer, const Respawn& message) {
    put_respawn_place(writer, message.place);
}

[[nodiscard]] Respawn get_respawn(Reader& reader) {
    Respawn message;
    message.place = get_respawn_place(reader);
    return message;
}

void put_pick_up(Writer& writer, const PickUp& message) {
    writer.u32(message.drop);
}

[[nodiscard]] PickUp get_pick_up(Reader& reader) {
    PickUp message;
    message.drop = reader.u32();
    return message;
}

void put_ask_target(Writer& writer, const AskTarget& message) {
    writer.u32(message.id);
}

[[nodiscard]] AskTarget get_ask_target(Reader& reader) {
    AskTarget message;
    message.id = reader.u32();
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
void put_list_3(Writer& writer, const std::vector<CharacterSummary>& values) {
    writer.count(values.size(), kCharacterListCharactersCount);
    for (const auto& value : values) {
        put_character_summary(writer, value);
    }
}

[[nodiscard]] std::vector<CharacterSummary> get_list_3(Reader& reader) {
    const std::size_t count = reader.count(kCharacterListCharactersCount);
    std::vector<CharacterSummary> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_character_summary(reader));
    }
    return values;
}

void put_character_list(Writer& writer, const CharacterList& message) {
    put_list_3(writer, message.characters);
    writer.boolean(message.can_create);
}

[[nodiscard]] CharacterList get_character_list(Reader& reader) {
    CharacterList message;
    message.characters = get_list_3(reader);
    message.can_create = reader.boolean();
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
    writer.u32(message.self_id);
}

[[nodiscard]] SceneEnter get_scene_enter(Reader& reader) {
    SceneEnter message;
    message.scene = reader.u16();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.direction = reader.u16();
    message.self_id = reader.u32();
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
    put_entity_state(writer, message.state);
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
    message.state = get_entity_state(reader);
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
    put_entity_state(writer, message.state);
}

[[nodiscard]] EntityPos get_entity_pos(Reader& reader) {
    EntityPos message;
    message.id = reader.u32();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.direction = reader.u16();
    message.tick = reader.u32();
    message.state = get_entity_state(reader);
    return message;
}

void put_entity_vitals(Writer& writer, const EntityVitals& message) {
    writer.u32(message.id);
    writer.u8(message.hp_percent);
    writer.u8(message.mp_percent);
    writer.i32(message.rage);
}

[[nodiscard]] EntityVitals get_entity_vitals(Reader& reader) {
    EntityVitals message;
    message.id = reader.u32();
    message.hp_percent = reader.u8();
    message.mp_percent = reader.u8();
    message.rage = reader.i32();
    return message;
}

void put_entity_flags(Writer& writer, const EntityFlags& message) {
    writer.u32(message.id);
    writer.u8(message.flags);
}

[[nodiscard]] EntityFlags get_entity_flags(Reader& reader) {
    EntityFlags message;
    message.id = reader.u32();
    message.flags = reader.u8();
    return message;
}

// list:record:PosEntry, tối đa kEntityPosBatchPlacesCount phần tử.
void put_list_4(Writer& writer, const std::vector<PosEntry>& values) {
    writer.count(values.size(), kEntityPosBatchPlacesCount);
    for (const auto& value : values) {
        put_pos_entry(writer, value);
    }
}

[[nodiscard]] std::vector<PosEntry> get_list_4(Reader& reader) {
    const std::size_t count = reader.count(kEntityPosBatchPlacesCount);
    std::vector<PosEntry> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_pos_entry(reader));
    }
    return values;
}

void put_entity_pos_batch(Writer& writer, const EntityPosBatch& message) {
    put_list_4(writer, message.places);
}

[[nodiscard]] EntityPosBatch get_entity_pos_batch(Reader& reader) {
    EntityPosBatch message;
    message.places = get_list_4(reader);
    return message;
}

void put_world_time(Writer& writer, const WorldTime& message) {
    writer.u8(message.period);
}

[[nodiscard]] WorldTime get_world_time(Reader& reader) {
    WorldTime message;
    message.period = reader.u8();
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

// list:record:DialogLine, tối đa kDialogOpenLinesCount phần tử.
void put_list_5(Writer& writer, const std::vector<DialogLine>& values) {
    writer.count(values.size(), kDialogOpenLinesCount);
    for (const auto& value : values) {
        put_dialog_line(writer, value);
    }
}

[[nodiscard]] std::vector<DialogLine> get_list_5(Reader& reader) {
    const std::size_t count = reader.count(kDialogOpenLinesCount);
    std::vector<DialogLine> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_dialog_line(reader));
    }
    return values;
}

// list:record:DialogChoice, tối đa kDialogOpenChoicesCount phần tử.
void put_list_6(Writer& writer, const std::vector<DialogChoice>& values) {
    writer.count(values.size(), kDialogOpenChoicesCount);
    for (const auto& value : values) {
        put_dialog_choice(writer, value);
    }
}

[[nodiscard]] std::vector<DialogChoice> get_list_6(Reader& reader) {
    const std::size_t count = reader.count(kDialogOpenChoicesCount);
    std::vector<DialogChoice> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_dialog_choice(reader));
    }
    return values;
}

// list:record:DialogMark, tối đa kDialogOpenMarksCount phần tử.
void put_list_7(Writer& writer, const std::vector<DialogMark>& values) {
    writer.count(values.size(), kDialogOpenMarksCount);
    for (const auto& value : values) {
        put_dialog_mark(writer, value);
    }
}

[[nodiscard]] std::vector<DialogMark> get_list_7(Reader& reader) {
    const std::size_t count = reader.count(kDialogOpenMarksCount);
    std::vector<DialogMark> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_dialog_mark(reader));
    }
    return values;
}

// list:record:DialogBonus, tối đa kDialogOpenBonusesCount phần tử.
void put_list_8(Writer& writer, const std::vector<DialogBonus>& values) {
    writer.count(values.size(), kDialogOpenBonusesCount);
    for (const auto& value : values) {
        put_dialog_bonus(writer, value);
    }
}

[[nodiscard]] std::vector<DialogBonus> get_list_8(Reader& reader) {
    const std::size_t count = reader.count(kDialogOpenBonusesCount);
    std::vector<DialogBonus> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_dialog_bonus(reader));
    }
    return values;
}

void put_dialog_open(Writer& writer, const DialogOpen& message) {
    writer.u64(message.session);
    writer.u32(message.npc);
    put_dialog_mode(writer, message.mode);
    put_list_5(writer, message.lines);
    put_list_6(writer, message.choices);
    put_list_7(writer, message.marks);
    writer.i32(message.panel_quest);
    put_list_8(writer, message.bonuses);
}

[[nodiscard]] DialogOpen get_dialog_open(Reader& reader) {
    DialogOpen message;
    message.session = reader.u64();
    message.npc = reader.u32();
    message.mode = get_dialog_mode(reader);
    message.lines = get_list_5(reader);
    message.choices = get_list_6(reader);
    message.marks = get_list_7(reader);
    message.panel_quest = reader.i32();
    message.bonuses = get_list_8(reader);
    return message;
}

void put_dialog_closed(Writer& writer, const DialogClosed& message) {
    writer.u64(message.session);
    put_dialog_close_reason(writer, message.reason);
}

[[nodiscard]] DialogClosed get_dialog_closed(Reader& reader) {
    DialogClosed message;
    message.session = reader.u64();
    message.reason = get_dialog_close_reason(reader);
    return message;
}

// list:record:QuestSlot, tối đa kQuestBookSlotsCount phần tử.
void put_list_9(Writer& writer, const std::vector<QuestSlot>& values) {
    writer.count(values.size(), kQuestBookSlotsCount);
    for (const auto& value : values) {
        put_quest_slot(writer, value);
    }
}

[[nodiscard]] std::vector<QuestSlot> get_list_9(Reader& reader) {
    const std::size_t count = reader.count(kQuestBookSlotsCount);
    std::vector<QuestSlot> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_quest_slot(reader));
    }
    return values;
}

void put_quest_book(Writer& writer, const QuestBook& message) {
    put_list_9(writer, message.slots);
    writer.bytes(message.done);
}

[[nodiscard]] QuestBook get_quest_book(Reader& reader) {
    QuestBook message;
    message.slots = get_list_9(reader);
    reader.bytes(message.done);
    return message;
}

void put_quest_notice(Writer& writer, const QuestNotice& message) {
    put_quest_notice_kind(writer, message.kind);
    writer.i32(message.quest);
    writer.text(message.text, kQuestNoticeTextBytes);
    writer.i64(message.value);
    writer.i32(message.ref);
}

[[nodiscard]] QuestNotice get_quest_notice(Reader& reader) {
    QuestNotice message;
    message.kind = get_quest_notice_kind(reader);
    message.quest = reader.i32();
    message.text = reader.text(kQuestNoticeTextBytes);
    message.value = reader.i64();
    message.ref = reader.i32();
    return message;
}

// list:i32, tối đa kUiCommandIntsCount phần tử.
void put_list_10(Writer& writer, const std::vector<std::int32_t>& values) {
    writer.count(values.size(), kUiCommandIntsCount);
    for (const auto& value : values) {
        writer.i32(value);
    }
}

[[nodiscard]] std::vector<std::int32_t> get_list_10(Reader& reader) {
    const std::size_t count = reader.count(kUiCommandIntsCount);
    std::vector<std::int32_t> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(reader.i32());
    }
    return values;
}

// list:record:UiString, tối đa kUiCommandStringsCount phần tử.
void put_list_11(Writer& writer, const std::vector<UiString>& values) {
    writer.count(values.size(), kUiCommandStringsCount);
    for (const auto& value : values) {
        put_ui_string(writer, value);
    }
}

[[nodiscard]] std::vector<UiString> get_list_11(Reader& reader) {
    const std::size_t count = reader.count(kUiCommandStringsCount);
    std::vector<UiString> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_ui_string(reader));
    }
    return values;
}

void put_ui_command(Writer& writer, const UiCommand& message) {
    writer.i32(message.index);
    writer.i32(message.mode);
    put_list_10(writer, message.ints);
    put_list_11(writer, message.strings);
}

[[nodiscard]] UiCommand get_ui_command(Reader& reader) {
    UiCommand message;
    message.index = reader.i32();
    message.mode = reader.i32();
    message.ints = get_list_10(reader);
    message.strings = get_list_11(reader);
    return message;
}

void put_self_stats_2_of_2(Writer& writer, const SelfStats& message) {
    writer.i32(message.poison_defence);
}

void put_self_stats(Writer& writer, const SelfStats& message) {
    writer.u16(message.level);
    writer.u64(message.exp);
    writer.u64(message.money);
    writer.u64(message.bound_money);
    writer.u8(message.sect);
    writer.i32(message.strength);
    writer.i32(message.spirit);
    writer.i32(message.constitution);
    writer.i32(message.concentration);
    writer.i32(message.dexterity);
    writer.i32(message.free_points);
    writer.i32(message.hp_restore);
    writer.i32(message.mp_restore);
    writer.i32(message.physical_attack);
    writer.i32(message.physical_defence);
    writer.i32(message.magic_attack);
    writer.i32(message.magic_defence);
    writer.i32(message.hit);
    writer.i32(message.miss);
    writer.i32(message.critical_hit);
    writer.i32(message.strike_point);
    writer.i32(message.attack_speed);
    writer.i32(message.move_speed);
    writer.i32(message.cold_attack);
    writer.i32(message.cold_defence);
    writer.i32(message.fire_attack);
    writer.i32(message.fire_defence);
    writer.i32(message.lightning_attack);
    writer.i32(message.lightning_defence);
    writer.i32(message.poison_attack);
    put_self_stats_2_of_2(writer, message);
}

void get_self_stats_2_of_2(Reader& reader, SelfStats& message) {
    message.poison_defence = reader.i32();
}

[[nodiscard]] SelfStats get_self_stats(Reader& reader) {
    SelfStats message;
    message.level = reader.u16();
    message.exp = reader.u64();
    message.money = reader.u64();
    message.bound_money = reader.u64();
    message.sect = reader.u8();
    message.strength = reader.i32();
    message.spirit = reader.i32();
    message.constitution = reader.i32();
    message.concentration = reader.i32();
    message.dexterity = reader.i32();
    message.free_points = reader.i32();
    message.hp_restore = reader.i32();
    message.mp_restore = reader.i32();
    message.physical_attack = reader.i32();
    message.physical_defence = reader.i32();
    message.magic_attack = reader.i32();
    message.magic_defence = reader.i32();
    message.hit = reader.i32();
    message.miss = reader.i32();
    message.critical_hit = reader.i32();
    message.strike_point = reader.i32();
    message.attack_speed = reader.i32();
    message.move_speed = reader.i32();
    message.cold_attack = reader.i32();
    message.cold_defence = reader.i32();
    message.fire_attack = reader.i32();
    message.fire_defence = reader.i32();
    message.lightning_attack = reader.i32();
    message.lightning_defence = reader.i32();
    message.poison_attack = reader.i32();
    get_self_stats_2_of_2(reader, message);
    return message;
}

void put_self_vitals(Writer& writer, const SelfVitals& message) {
    writer.i32(message.hp);
    writer.i32(message.hp_max);
    writer.i32(message.mp);
    writer.i32(message.mp_max);
    writer.i32(message.rage);
    writer.i32(message.rage_max);
}

[[nodiscard]] SelfVitals get_self_vitals(Reader& reader) {
    SelfVitals message;
    message.hp = reader.i32();
    message.hp_max = reader.i32();
    message.mp = reader.i32();
    message.mp_max = reader.i32();
    message.rage = reader.i32();
    message.rage_max = reader.i32();
    return message;
}

// list:record:BagSlot, tối đa kSelfBagSlotsCount phần tử.
void put_list_12(Writer& writer, const std::vector<BagSlot>& values) {
    writer.count(values.size(), kSelfBagSlotsCount);
    for (const auto& value : values) {
        put_bag_slot(writer, value);
    }
}

[[nodiscard]] std::vector<BagSlot> get_list_12(Reader& reader) {
    const std::size_t count = reader.count(kSelfBagSlotsCount);
    std::vector<BagSlot> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_bag_slot(reader));
    }
    return values;
}

void put_self_bag(Writer& writer, const SelfBag& message) {
    put_list_12(writer, message.slots);
}

[[nodiscard]] SelfBag get_self_bag(Reader& reader) {
    SelfBag message;
    message.slots = get_list_12(reader);
    return message;
}

void put_skill_cast(Writer& writer, const SkillCast& message) {
    writer.u16(message.seq);
    writer.u32(message.source);
    writer.u16(message.skill);
    writer.u32(message.target);
    writer.f32(message.x_cm);
    writer.f32(message.z_cm);
    writer.u8(message.level);
}

[[nodiscard]] SkillCast get_skill_cast(Reader& reader) {
    SkillCast message;
    message.seq = reader.u16();
    message.source = reader.u32();
    message.skill = reader.u16();
    message.target = reader.u32();
    message.x_cm = reader.f32();
    message.z_cm = reader.f32();
    message.level = reader.u8();
    return message;
}

void put_skill_cast_end(Writer& writer, const SkillCastEnd& message) {
    writer.u32(message.source);
    writer.u16(message.skill);
    writer.boolean(message.interrupted);
}

[[nodiscard]] SkillCastEnd get_skill_cast_end(Reader& reader) {
    SkillCastEnd message;
    message.source = reader.u32();
    message.skill = reader.u16();
    message.interrupted = reader.boolean();
    return message;
}

void put_combat_event(Writer& writer, const CombatEvent& message) {
    writer.u32(message.source);
    writer.u32(message.target);
    writer.u16(message.skill);
    put_combat_kind(writer, message.kind);
    writer.i32(message.value);
    writer.u8(message.flags);
}

[[nodiscard]] CombatEvent get_combat_event(Reader& reader) {
    CombatEvent message;
    message.source = reader.u32();
    message.target = reader.u32();
    message.skill = reader.u16();
    message.kind = get_combat_kind(reader);
    message.value = reader.i32();
    message.flags = reader.u8();
    return message;
}

void put_entity_died(Writer& writer, const EntityDied& message) {
    writer.u32(message.id);
    writer.u32(message.killer);
}

[[nodiscard]] EntityDied get_entity_died(Reader& reader) {
    EntityDied message;
    message.id = reader.u32();
    message.killer = reader.u32();
    return message;
}

void put_death_notice(Writer& writer, const DeathNotice& message) {
    writer.u64(message.exp_lost);
    writer.u64(message.money_lost);
}

[[nodiscard]] DeathNotice get_death_notice(Reader& reader) {
    DeathNotice message;
    message.exp_lost = reader.u64();
    message.money_lost = reader.u64();
    return message;
}

// list:record:SkillEntry, tối đa kSelfSkillsSkillsCount phần tử.
void put_list_13(Writer& writer, const std::vector<SkillEntry>& values) {
    writer.count(values.size(), kSelfSkillsSkillsCount);
    for (const auto& value : values) {
        put_skill_entry(writer, value);
    }
}

[[nodiscard]] std::vector<SkillEntry> get_list_13(Reader& reader) {
    const std::size_t count = reader.count(kSelfSkillsSkillsCount);
    std::vector<SkillEntry> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_skill_entry(reader));
    }
    return values;
}

void put_self_skills(Writer& writer, const SelfSkills& message) {
    put_list_13(writer, message.skills);
}

[[nodiscard]] SelfSkills get_self_skills(Reader& reader) {
    SelfSkills message;
    message.skills = get_list_13(reader);
    return message;
}

void put_skill_cooldown(Writer& writer, const SkillCooldown& message) {
    writer.u16(message.skill);
    writer.u32(message.ms);
}

[[nodiscard]] SkillCooldown get_skill_cooldown(Reader& reader) {
    SkillCooldown message;
    message.skill = reader.u16();
    message.ms = reader.u32();
    return message;
}

// list:record:BuffEntry, tối đa kBuffListBuffsCount phần tử.
void put_list_14(Writer& writer, const std::vector<BuffEntry>& values) {
    writer.count(values.size(), kBuffListBuffsCount);
    for (const auto& value : values) {
        put_buff_entry(writer, value);
    }
}

[[nodiscard]] std::vector<BuffEntry> get_list_14(Reader& reader) {
    const std::size_t count = reader.count(kBuffListBuffsCount);
    std::vector<BuffEntry> values;
    values.reserve(count);
    for (std::size_t i = 0; i < count && reader.is_ok(); ++i) {
        values.push_back(get_buff_entry(reader));
    }
    return values;
}

void put_buff_list(Writer& writer, const BuffList& message) {
    writer.u32(message.id);
    put_list_14(writer, message.buffs);
}

[[nodiscard]] BuffList get_buff_list(Reader& reader) {
    BuffList message;
    message.id = reader.u32();
    message.buffs = get_list_14(reader);
    return message;
}

// Thân phải hết đúng lúc đọc xong trường cuối; lỗi đầu tiên của reader được giữ.
template <class Message>
[[nodiscard]] std::expected<Message, WireError> checked(const Reader& reader, Message message) {
    const WireStatus status = reader.finish();
    if (!status) return std::unexpected(status.error());
    return message;
}

[[nodiscard]] GameServerResult decode_game_server_2_of_2(std::uint16_t kind, Reader& reader) {
    switch (kind) {
    case DeathNotice::kKind: return checked(reader, get_death_notice(reader));
    case SelfSkills::kKind: return checked(reader, get_self_skills(reader));
    case SkillCooldown::kKind: return checked(reader, get_skill_cooldown(reader));
    case BuffList::kKind: return checked(reader, get_buff_list(reader));
    default: return std::unexpected(WireError::kUnknownKind);
    }
}

} // namespace

bool is_valid(AvatarFrame value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 2;
}

bool is_valid(BonusKind value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 5;
}

bool is_valid(CombatKind value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 4;
}

bool is_valid(DialogCloseReason value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 8;
}

bool is_valid(DialogMode value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 6;
}

bool is_valid(DisconnectReason value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 9;
}

bool is_valid(EntityKind value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 6;
}

bool is_valid(EntityState value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 3;
}

bool is_valid(ErrorCode value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 43;
}

bool is_valid(Gender value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 2;
}

bool is_valid(MarkStage value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 3;
}

bool is_valid(Platform value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 3;
}

bool is_valid(QuestNoticeKind value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 12;
}

bool is_valid(RespawnPlace value) noexcept {
    const auto raw = std::to_underlying(value);
    return raw >= 1 && raw <= 2;
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

WireStatus encode(std::vector<std::byte>& out, const Talk& message) {
    Writer writer{out};
    put_talk(writer, message);
    return writer.finish(Talk::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const DialogChoose& message) {
    Writer writer{out};
    put_dialog_choose(writer, message);
    return writer.finish(DialogChoose::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const QuestAccept& message) {
    Writer writer{out};
    put_quest_accept(writer, message);
    return writer.finish(QuestAccept::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const QuestTurnIn& message) {
    Writer writer{out};
    put_quest_turn_in(writer, message);
    return writer.finish(QuestTurnIn::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const QuestAbandon& message) {
    Writer writer{out};
    put_quest_abandon(writer, message);
    return writer.finish(QuestAbandon::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const DialogClose& message) {
    Writer writer{out};
    put_dialog_close(writer, message);
    return writer.finish(DialogClose::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const ExecuteScript& message) {
    Writer writer{out};
    put_execute_script(writer, message);
    return writer.finish(ExecuteScript::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const CastSkill& message) {
    Writer writer{out};
    put_cast_skill(writer, message);
    return writer.finish(CastSkill::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Respawn& message) {
    Writer writer{out};
    put_respawn(writer, message);
    return writer.finish(Respawn::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const PickUp& message) {
    Writer writer{out};
    put_pick_up(writer, message);
    return writer.finish(PickUp::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const AskTarget& message) {
    Writer writer{out};
    put_ask_target(writer, message);
    return writer.finish(AskTarget::kKind);
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

WireStatus encode(std::vector<std::byte>& out, const EntityFlags& message) {
    Writer writer{out};
    put_entity_flags(writer, message);
    return writer.finish(EntityFlags::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const EntityPosBatch& message) {
    Writer writer{out};
    put_entity_pos_batch(writer, message);
    return writer.finish(EntityPosBatch::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const WorldTime& message) {
    Writer writer{out};
    put_world_time(writer, message);
    return writer.finish(WorldTime::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const Ticket& message) {
    Writer writer{out};
    put_ticket(writer, message);
    return writer.finish(Ticket::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const DialogOpen& message) {
    Writer writer{out};
    put_dialog_open(writer, message);
    return writer.finish(DialogOpen::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const DialogClosed& message) {
    Writer writer{out};
    put_dialog_closed(writer, message);
    return writer.finish(DialogClosed::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const QuestBook& message) {
    Writer writer{out};
    put_quest_book(writer, message);
    return writer.finish(QuestBook::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const QuestNotice& message) {
    Writer writer{out};
    put_quest_notice(writer, message);
    return writer.finish(QuestNotice::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const UiCommand& message) {
    Writer writer{out};
    put_ui_command(writer, message);
    return writer.finish(UiCommand::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SelfStats& message) {
    Writer writer{out};
    put_self_stats(writer, message);
    return writer.finish(SelfStats::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SelfVitals& message) {
    Writer writer{out};
    put_self_vitals(writer, message);
    return writer.finish(SelfVitals::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SelfBag& message) {
    Writer writer{out};
    put_self_bag(writer, message);
    return writer.finish(SelfBag::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SkillCast& message) {
    Writer writer{out};
    put_skill_cast(writer, message);
    return writer.finish(SkillCast::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SkillCastEnd& message) {
    Writer writer{out};
    put_skill_cast_end(writer, message);
    return writer.finish(SkillCastEnd::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const CombatEvent& message) {
    Writer writer{out};
    put_combat_event(writer, message);
    return writer.finish(CombatEvent::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const EntityDied& message) {
    Writer writer{out};
    put_entity_died(writer, message);
    return writer.finish(EntityDied::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const DeathNotice& message) {
    Writer writer{out};
    put_death_notice(writer, message);
    return writer.finish(DeathNotice::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SelfSkills& message) {
    Writer writer{out};
    put_self_skills(writer, message);
    return writer.finish(SelfSkills::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const SkillCooldown& message) {
    Writer writer{out};
    put_skill_cooldown(writer, message);
    return writer.finish(SkillCooldown::kKind);
}

WireStatus encode(std::vector<std::byte>& out, const BuffList& message) {
    Writer writer{out};
    put_buff_list(writer, message);
    return writer.finish(BuffList::kKind);
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
    case Talk::kKind: return checked(reader, get_talk(reader));
    case DialogChoose::kKind: return checked(reader, get_dialog_choose(reader));
    case QuestAccept::kKind: return checked(reader, get_quest_accept(reader));
    case QuestTurnIn::kKind: return checked(reader, get_quest_turn_in(reader));
    case QuestAbandon::kKind: return checked(reader, get_quest_abandon(reader));
    case DialogClose::kKind: return checked(reader, get_dialog_close(reader));
    case ExecuteScript::kKind: return checked(reader, get_execute_script(reader));
    case CastSkill::kKind: return checked(reader, get_cast_skill(reader));
    case Respawn::kKind: return checked(reader, get_respawn(reader));
    case PickUp::kKind: return checked(reader, get_pick_up(reader));
    case AskTarget::kKind: return checked(reader, get_ask_target(reader));
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
    case EntityFlags::kKind: return checked(reader, get_entity_flags(reader));
    case EntityPosBatch::kKind: return checked(reader, get_entity_pos_batch(reader));
    case WorldTime::kKind: return checked(reader, get_world_time(reader));
    case DialogOpen::kKind: return checked(reader, get_dialog_open(reader));
    case DialogClosed::kKind: return checked(reader, get_dialog_closed(reader));
    case QuestBook::kKind: return checked(reader, get_quest_book(reader));
    case QuestNotice::kKind: return checked(reader, get_quest_notice(reader));
    case UiCommand::kKind: return checked(reader, get_ui_command(reader));
    case SelfStats::kKind: return checked(reader, get_self_stats(reader));
    case SelfVitals::kKind: return checked(reader, get_self_vitals(reader));
    case SelfBag::kKind: return checked(reader, get_self_bag(reader));
    case SkillCast::kKind: return checked(reader, get_skill_cast(reader));
    case SkillCastEnd::kKind: return checked(reader, get_skill_cast_end(reader));
    case CombatEvent::kKind: return checked(reader, get_combat_event(reader));
    case EntityDied::kKind: return checked(reader, get_entity_died(reader));
    default: return decode_game_server_2_of_2(frame.kind, reader);
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
