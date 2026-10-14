#pragma once
// Mã hoá/giải mã các khối dữ liệu lưu bền của lõi xã hội (bang, liên minh, sổ quan hệ, hộp thư, bảng xếp
// hạng, thành phố). Dùng lại tầng byte của protocol (protocol::Writer/Reader: little-endian, UTF-8 kiểm
// chặt, mọi số phần tử có trần trước khi cấp phát) nên dữ liệu đọc từ database coi như thù địch: sai
// một byte là trả lỗi, không bao giờ assert.
//
// Mỗi khối là một khung của protocol (đầu 8 byte) có `kind` riêng trong dải 0x5100 trở lên, rồi thân
// bắt đầu bằng số phiên bản u16. Đổi bố cục thì tăng phiên bản; bản đọc từ chối phiên bản nó chưa hiểu.
// Các kind này chỉ nằm trong database, không bao giờ đi qua mạng.
// Trần: một khối không quá protocol::kMaxBodyBytes (64 KiB); bên mã hoá báo kTooLarge nếu vượt.

#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <string_view>
#include <vector>

namespace game::social {

enum class CodecError : std::uint8_t {
    kTruncated = 1,  // thiếu byte (khung hoặc thân)
    kBadKind,        // kind khác kind mong đợi
    kBadVersion,     // phiên bản chưa hiểu
    kBadValue,       // số, enum, văn bản ngoài miền; danh sách trùng hoặc sai bất biến
    kTrailing,       // còn byte sau thân
    kTooLarge,       // vượt 64 KiB hoặc quá trần số phần tử
};

[[nodiscard]] std::string_view describe(CodecError error) noexcept;

namespace blob {
// 0x5102 bỏ trống: thành viên bang nằm trong khối bang, không có khối riêng.
inline constexpr std::uint16_t kGuild = 0x5101;
inline constexpr std::uint16_t kRelation = 0x5103;
inline constexpr std::uint16_t kMailbox = 0x5104;
inline constexpr std::uint16_t kRank = 0x5105;
inline constexpr std::uint16_t kCity = 0x5106;
inline constexpr std::uint16_t kLeague = 0x5107;
} // namespace blob

using Bytes = std::vector<std::byte>;
using CodecResult = std::expected<void, CodecError>;

// Mở khung ở đầu `bytes`: kiểm đầu khung, kind và việc không còn byte thừa; trả thân của khung.
[[nodiscard]] std::expected<protocol::ByteView, CodecError> open_blob(protocol::ByteView bytes, std::uint16_t kind);

// Đổi lỗi tầng byte sang CodecError.
[[nodiscard]] CodecError from_wire(protocol::WireError error) noexcept;

// Kết thúc một Writer: lỗi tầng byte thành CodecError.
[[nodiscard]] CodecResult finish_blob(protocol::Writer& writer, std::uint16_t kind);

// Kết thúc một Reader: lỗi tích luỹ của Reader hoặc byte thừa thành CodecError.
[[nodiscard]] CodecResult finish_read(const protocol::Reader& reader);

} // namespace game::social
