/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/combat/codec.cpp
 *  PHÂN HỆ   : Server / Combat / Codec
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mã hoá và giải mã bản ghi chiến đấu: phiên bản 2 ghi nhịp ngay sau số
 *    phiên bản
 *  - Phiên bản 1 không có nhịp, mọi bước là 20 Hz; phiên bản lạ là lỗi
 *  - Dữ liệu từ database là thù địch: sai miền thì trả lỗi, không assert
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "combat/codec.hpp"

#include "combat/arena.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "protocol/wire.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <string_view>

namespace game::combat {
namespace {

constexpr std::uint8_t kFlagByPlayer = 1U << 0U;
constexpr std::uint8_t kFlagCritical = 1U << 1U;
constexpr std::uint8_t kKnownFlags = kFlagByPlayer | kFlagCritical;

CodecError from_wire(protocol::WireError error) noexcept {
    switch (error) {
    case protocol::WireError::kTruncated: return CodecError::kTruncated;
    case protocol::WireError::kTrailingBytes: return CodecError::kTrailing;
    case protocol::WireError::kTooLong:
    case protocol::WireError::kBodyTooLarge: return CodecError::kTooLarge;
    default: return CodecError::kBadValue;
    }
}

[[nodiscard]] bool valid_buff(const SavedBuff& buff) noexcept {
    if (buff.continuance < -1 || buff.elapsed < 0) return false;
    // Buff còn trong danh sách thì chưa hết hạn: đã hết hạn thì không được lưu.
    return buff.continuance < 0 || buff.elapsed < buff.continuance;
}

[[nodiscard]] bool known_rate(std::int64_t hz) noexcept {
    if (hz == 20) return true;
    if (hz == 30) return true;
    return hz == 40;
}

[[nodiscard]] bool valid(const CombatRecord& record) noexcept {
    if (!known_rate(record.hz)) return false;
    const bool skills_big = record.skills.size() > kMaxSkills;
    const bool cooldowns_big = record.cooldowns.size() > kMaxCooldowns;
    const bool buffs_big = record.buffs.size() > kMaxBuffs;
    const bool too_big = skills_big || cooldowns_big || buffs_big;
    if (too_big) return false;
    for (std::size_t i = 0; i < record.skills.size(); ++i) {
        const SkillEntry& entry = record.skills.at(i);
        if (entry.level == 0 || entry.level > kMaxSkillLevel) return false;
        if (i > 0 && record.skills.at(i - 1).id >= entry.id) return false;
    }
    for (std::size_t i = 0; i < record.cooldowns.size(); ++i) {
        const SavedCooldown& cooldown = record.cooldowns.at(i);
        if (cooldown.id < 0 || cooldown.remaining_ticks == 0) return false;
        if (i > 0 && record.cooldowns.at(i - 1).id >= cooldown.id) return false;
    }
    return std::ranges::all_of(record.buffs, valid_buff);
}

} // namespace

std::string_view describe(CodecError error) noexcept {
    switch (error) {
    case CodecError::kTruncated: return "bản ghi chiến đấu bị cụt";
    case CodecError::kBadKind: return "bản ghi chiến đấu sai loại";
    case CodecError::kBadVersion: return "phiên bản bản ghi chiến đấu chưa hiểu";
    case CodecError::kBadValue: return "giá trị trong bản ghi chiến đấu ngoài miền";
    case CodecError::kTrailing: return "bản ghi chiến đấu còn byte thừa";
    case CodecError::kTooLarge: return "bản ghi chiến đấu quá lớn";
    }
    return "lỗi bản ghi chiến đấu lạ";
}

std::expected<void, CodecError> encode_combat(const CombatRecord& record, Bytes& out) {
    if (!valid(record)) return std::unexpected(CodecError::kBadValue);
    protocol::Writer writer(out);
    writer.u16(kRecordVersion);
    writer.u16(static_cast<std::uint16_t>(record.hz));
    writer.count(record.skills.size(), kMaxSkills);
    for (const SkillEntry& entry : record.skills) {
        writer.u32(entry.id);
        writer.u8(entry.level);
    }
    writer.count(record.cooldowns.size(), kMaxCooldowns);
    for (const SavedCooldown& cooldown : record.cooldowns) {
        writer.i32(cooldown.id);
        writer.u32(cooldown.remaining_ticks);
    }
    writer.count(record.buffs.size(), kMaxBuffs);
    for (const SavedBuff& buff : record.buffs) {
        writer.u32(buff.effect);
        writer.u32(buff.skill);
        writer.u64(buff.caster_character);
        writer.u8(static_cast<std::uint8_t>((buff.by_player ? kFlagByPlayer : 0U) | (buff.critical ? kFlagCritical : 0U)));
        writer.i64(buff.continuance);
        writer.i64(buff.elapsed);
        writer.i32(buff.refix);
        for (const std::int32_t value : buff.slot) writer.i32(value);
    }
    const protocol::WireStatus status = writer.finish(kRecordKind);
    if (!status) return std::unexpected(from_wire(status.error()));
    return {};
}

std::expected<CombatRecord, CodecError> decode_combat(protocol::ByteView bytes) {
    const auto peeked = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!peeked) return std::unexpected(from_wire(peeked.error()));
    if (!peeked->has_value()) return std::unexpected(CodecError::kTruncated);
    const protocol::Frame frame = **peeked;
    if (frame.kind != kRecordKind) return std::unexpected(CodecError::kBadKind);
    if (bytes.size() != protocol::kHeaderBytes + frame.body_bytes) return std::unexpected(CodecError::kTrailing);
    protocol::Reader reader(bytes.subspan(protocol::kHeaderBytes, frame.body_bytes));
    const std::uint16_t version = reader.u16();
    const bool legacy = version == kLegacyRecordVersion;
    const bool current = version == kRecordVersion;
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    const bool unknown = !legacy && !current;
    if (unknown) return std::unexpected(CodecError::kBadVersion);
    CombatRecord record;
    record.hz = kTicksPerSecond;
    if (current) record.hz = static_cast<std::int64_t>(reader.u16());
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    const std::size_t skills = reader.count(kMaxSkills);
    record.skills.reserve(skills);
    for (std::size_t i = 0; i < skills && reader.is_ok(); ++i) {
        SkillEntry entry;
        entry.id = reader.u32();
        entry.level = reader.u8();
        record.skills.push_back(entry);
    }
    const std::size_t cooldowns = reader.count(kMaxCooldowns);
    record.cooldowns.reserve(cooldowns);
    for (std::size_t i = 0; i < cooldowns && reader.is_ok(); ++i) {
        SavedCooldown cooldown;
        cooldown.id = reader.i32();
        cooldown.remaining_ticks = reader.u32();
        record.cooldowns.push_back(cooldown);
    }
    const std::size_t buffs = reader.count(kMaxBuffs);
    record.buffs.reserve(buffs);
    bool flags_ok = true;
    for (std::size_t i = 0; i < buffs && reader.is_ok(); ++i) {
        SavedBuff buff;
        buff.effect = reader.u32();
        buff.skill = reader.u32();
        buff.caster_character = reader.u64();
        const std::uint8_t flags = reader.u8();
        flags_ok = flags_ok && (flags & ~kKnownFlags) == 0;
        buff.by_player = (flags & kFlagByPlayer) != 0;
        buff.critical = (flags & kFlagCritical) != 0;
        buff.continuance = reader.i64();
        buff.elapsed = reader.i64();
        buff.refix = reader.i32();
        for (std::int32_t& value : buff.slot) value = reader.i32();
        record.buffs.push_back(buff);
    }
    const protocol::WireStatus status = reader.finish();
    if (!status) return std::unexpected(from_wire(status.error()));
    if (!flags_ok || !valid(record)) return std::unexpected(CodecError::kBadValue);
    return record;
}

} // namespace game::combat
