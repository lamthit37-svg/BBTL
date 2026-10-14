#pragma once
// Mã hoá/giải mã bản ghi bền của chiến đấu (CombatRecord: sổ kỹ năng, hồi chiêu còn lại, buff mang theo). Dùng tầng
// byte của protocol (little-endian, trần trước khi cấp phát); dữ liệu đọc từ database coi như thù địch: sai một byte
// là trả lỗi, không bao giờ assert. Khối là một khung protocol có kind riêng, thân bắt đầu bằng số phiên bản u16; đổi
// bố cục thì tăng phiên bản, bản đọc từ chối phiên bản nó chưa hiểu. Khối chỉ nằm trong database, không đi qua mạng.
// Bản ghi thân thể (actor::Record, kind 0x5201) là khối riêng; hai khối cùng thuộc một nhân vật nhưng lưu độc lập.

#include "combat/arena.hpp"
#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <string_view>
#include <vector>

namespace game::combat {

enum class CodecError : std::uint8_t {
    kTruncated = 1, // thiếu byte
    kBadKind,       // kind khác kind mong đợi
    kBadVersion,    // phiên bản chưa hiểu
    kBadValue,      // số ngoài miền, danh sách trùng hay sai thứ tự
    kTrailing,      // còn byte sau thân
    kTooLarge,      // vượt trần
};

[[nodiscard]] std::string_view describe(CodecError error) noexcept;

inline constexpr std::uint16_t kRecordKind = 0x5202;
inline constexpr std::uint16_t kRecordVersion = 1;
inline constexpr std::uint8_t kMaxSkillLevel = 16;  // kInnerArtSlots

using Bytes = std::vector<std::byte>;

// Ghi `record` thêm vào cuối `out`. Lỗi thì `out` giữ nguyên cỡ cũ. Bản ghi phải ở dạng chuẩn: kỹ năng và hồi chiêu
// sắp theo id tăng, không lặp (Arena::snapshot luôn cho dạng này).
[[nodiscard]] std::expected<void, CodecError> encode_combat(const CombatRecord& record, Bytes& out);

// Giải mã một khối trọn vẹn (không byte thừa).
[[nodiscard]] std::expected<CombatRecord, CodecError> decode_combat(protocol::ByteView bytes);

} // namespace game::combat
