#include "actor/codec.hpp"

#include "actor/body.hpp"
#include "actor/rules.hpp"
#include "protocol/wire.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <string_view>
#include <utility>

namespace game::actor {
namespace {

CodecError from_wire(protocol::WireError error) noexcept {
    switch (error) {
    case protocol::WireError::kTruncated: return CodecError::kTruncated;
    case protocol::WireError::kTrailingBytes: return CodecError::kTrailing;
    case protocol::WireError::kTooLong:
    case protocol::WireError::kBodyTooLarge: return CodecError::kTooLarge;
    default: return CodecError::kBadValue;
    }
}

bool valid(const Record& record) noexcept {
    if (record.sect >= kSectSlots || record.level == 0) return false;
    if (record.remain_points < 0 || record.hp < 0 || record.mp < 0 || record.rage < 0 || record.strike_points < 0) return false;
    if (std::ranges::any_of(record.points, [](std::int32_t point) { return point < 0; })) return false;
    if (record.alive != (record.hp > 0)) return false;
    if (record.inner_arts.size() > kMaxInnerArtsPerRecord) return false;
    for (std::size_t i = 0; i < record.inner_arts.size(); ++i) {
        if (record.inner_arts[i].second == 0) return false;
        if (i > 0 && record.inner_arts[i - 1].first >= record.inner_arts[i].first) return false;
    }
    return true;
}

} // namespace

std::string_view describe(CodecError error) noexcept {
    switch (error) {
    case CodecError::kTruncated: return "bản ghi thân thể bị cụt";
    case CodecError::kBadKind: return "bản ghi thân thể sai loại";
    case CodecError::kBadVersion: return "phiên bản bản ghi thân thể chưa hiểu";
    case CodecError::kBadValue: return "giá trị trong bản ghi thân thể ngoài miền";
    case CodecError::kTrailing: return "bản ghi thân thể còn byte thừa";
    case CodecError::kTooLarge: return "bản ghi thân thể quá lớn";
    }
    return "lỗi bản ghi thân thể lạ";
}

std::expected<void, CodecError> encode_record(const Record& record, Bytes& out) {
    if (!valid(record)) return std::unexpected(CodecError::kBadValue);
    protocol::Writer writer(out);
    writer.u16(kRecordVersion);
    writer.u8(record.sect);
    writer.u16(record.level);
    writer.u64(record.exp);
    for (const std::int32_t point : record.points) writer.i32(point);
    writer.i32(record.remain_points);
    writer.i32(record.hp);
    writer.i32(record.mp);
    writer.i32(record.rage);
    writer.i32(record.strike_points);
    writer.boolean(record.alive);
    writer.count(record.inner_arts.size(), kMaxInnerArtsPerRecord);
    for (const auto& [id, level] : record.inner_arts) {
        writer.u32(id);
        writer.u16(level);
    }
    const protocol::WireStatus status = writer.finish(kRecordKind);
    if (!status) return std::unexpected(from_wire(status.error()));
    return {};
}

std::expected<Record, CodecError> decode_record(protocol::ByteView bytes, std::uint16_t max_level) {
    const auto peeked = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!peeked) return std::unexpected(from_wire(peeked.error()));
    if (!peeked->has_value()) return std::unexpected(CodecError::kTruncated);
    const protocol::Frame frame = **peeked;
    if (frame.kind != kRecordKind) return std::unexpected(CodecError::kBadKind);
    if (bytes.size() != protocol::kHeaderBytes + frame.body_bytes) return std::unexpected(CodecError::kTrailing);
    protocol::Reader reader(bytes.subspan(protocol::kHeaderBytes, frame.body_bytes));
    if (reader.u16() != kRecordVersion) {
        return std::unexpected(reader.is_ok() ? CodecError::kBadVersion : CodecError::kTruncated);
    }
    Record record;
    record.sect = reader.u8();
    record.level = reader.u16();
    record.exp = reader.u64();
    for (std::int32_t& point : record.points) point = reader.i32();
    record.remain_points = reader.i32();
    record.hp = reader.i32();
    record.mp = reader.i32();
    record.rage = reader.i32();
    record.strike_points = reader.i32();
    record.alive = reader.boolean();
    const std::size_t arts = reader.count(kMaxInnerArtsPerRecord);
    record.inner_arts.reserve(arts);
    for (std::size_t i = 0; i < arts && reader.is_ok(); ++i) {
        const std::uint32_t id = reader.u32();
        const std::uint16_t level = reader.u16();
        record.inner_arts.emplace_back(id, level);
    }
    const protocol::WireStatus status = reader.finish();
    if (!status) return std::unexpected(from_wire(status.error()));
    if (!valid(record) || record.level > max_level) return std::unexpected(CodecError::kBadValue);
    return record;
}

} // namespace game::actor
