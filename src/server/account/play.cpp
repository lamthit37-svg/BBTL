/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/account/play.cpp
 *  PHÂN HỆ   : Server / Account / Play
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đóng gói và mở khối trạng thái chơi (PlayRecord) thành một khung protocol
 *    có phiên bản.
 *  - Bộ mở coi đầu vào là thù địch: kiểm khung, độ dài từng khối, miền số và
 *    byte thừa trước khi cấp phát.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "account/play.hpp"

#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <vector>

namespace game::account {

namespace {

constexpr std::int32_t kHpLimit = 100'000'000;
constexpr std::uint64_t kExpLimit = std::uint64_t{1} << 50U;

[[nodiscard]] bool in_range(const PlayRecord& record) noexcept {
    return record.level != 0 && record.exp <= kExpLimit && record.money <= kMoneyLimit && record.bound <= kMoneyLimit &&
           record.hp >= 0 && record.hp <= kHpLimit && record.mp >= 0 && record.mp <= kHpLimit;
}

void write_blob(protocol::Writer& writer, const std::vector<std::byte>& blob, std::size_t limit) {
    if (blob.size() > limit) {
        writer.fail(protocol::WireError::kTooLong);
        return;
    }
    writer.u32(static_cast<std::uint32_t>(blob.size()));
    writer.bytes(blob);
}

// Đọc một khối có tiền tố độ dài; độ dài vượt trần hay vượt số byte còn lại thì để Reader ghi lỗi, không cấp phát.
[[nodiscard]] std::vector<std::byte> read_blob(protocol::Reader& reader, std::size_t limit) {
    const std::uint32_t size = reader.u32();
    if (size > limit) {
        reader.fail(protocol::WireError::kTooLong);
        return {};
    }
    std::vector<std::byte> blob;
    if (!reader.is_ok() || size == 0) return blob;
    // Reader::bytes kiểm đủ byte rồi mới ghi; cấp phát sau khi size đã nằm dưới trần.
    blob.resize(size);
    reader.bytes(blob);
    if (!reader.is_ok()) blob.clear();
    return blob;
}

[[nodiscard]] PlayError error_of(protocol::WireError error) noexcept {
    switch (error) {
    case protocol::WireError::kTruncated: return PlayError::kTruncated;
    case protocol::WireError::kTrailingBytes: return PlayError::kTrailing;
    case protocol::WireError::kTooLong:
    case protocol::WireError::kBodyTooLarge: return PlayError::kTooLarge;
    default: return PlayError::kBadValue;
    }
}

} // namespace

std::expected<std::vector<std::byte>, PlayError> pack(const PlayRecord& record) {
    if (!in_range(record)) return std::unexpected(PlayError::kBadValue);
    std::vector<std::byte> out;
    protocol::Writer writer(out);
    writer.u16(kPlayVersion);
    writer.u16(record.level);
    writer.u64(record.exp);
    writer.u64(record.money);
    writer.u64(record.bound);
    writer.i32(record.hp);
    writer.i32(record.mp);
    write_blob(writer, record.body, kMaxBodyBlob);
    write_blob(writer, record.mission, kMaxMissionBlob);
    write_blob(writer, record.bag, kMaxBagBlob);
    if (const protocol::WireStatus done = writer.finish(kPlayKind); !done) return std::unexpected(error_of(done.error()));
    return out;
}

std::expected<PlayRecord, PlayError> unpack(protocol::ByteView bytes) {
    const protocol::FrameResult frame = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!frame || !frame->has_value() || (*frame)->kind != kPlayKind) return std::unexpected(PlayError::kBadFrame);
    const std::size_t total = protocol::kHeaderBytes + (*frame)->body_bytes;
    if (total != bytes.size()) return std::unexpected(PlayError::kBadFrame);
    protocol::Reader reader(bytes.subspan(protocol::kHeaderBytes, (*frame)->body_bytes));
    if (reader.u16() != kPlayVersion) return std::unexpected(PlayError::kBadFrame);
    PlayRecord record;
    record.level = reader.u16();
    record.exp = reader.u64();
    record.money = reader.u64();
    record.bound = reader.u64();
    record.hp = reader.i32();
    record.mp = reader.i32();
    record.body = read_blob(reader, kMaxBodyBlob);
    record.mission = read_blob(reader, kMaxMissionBlob);
    record.bag = read_blob(reader, kMaxBagBlob);
    if (const protocol::WireStatus done = reader.finish(); !done) return std::unexpected(error_of(done.error()));
    if (!in_range(record)) return std::unexpected(PlayError::kBadValue);
    return record;
}

} // namespace game::account
