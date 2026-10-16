/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/actor/codec.hpp
 *  PHÂN HỆ   : Server / Actor / Codec
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mã hoá bản ghi thân thể bằng khung protocol, little-endian.
 *  - Phiên bản 1 khi chưa học kỹ năng. Phiên bản 2 khi danh sách không rỗng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Mã hoá/giải mã bản ghi bền của thân thể (actor::Record). Dùng tầng byte của protocol (little-endian,
// trần trước khi cấp phát); dữ liệu đọc từ database coi như thù địch: sai một byte là trả lỗi, không bao
// giờ assert. Khối là một khung protocol có kind riêng, thân bắt đầu bằng số phiên bản u16; đổi bố cục thì
// tăng phiên bản, bản đọc từ chối phiên bản nó chưa hiểu. Khối chỉ nằm trong database, không đi qua mạng.

#pragma once

#include "actor/body.hpp"
#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <string_view>
#include <vector>

namespace game::actor {

enum class CodecError : std::uint8_t {
    kTruncated = 1, // thiếu byte
    kBadKind,       // kind khác kind mong đợi
    kBadVersion,    // phiên bản chưa hiểu
    kBadValue,      // số ngoài miền, danh sách trùng hay sai thứ tự
    kTrailing,      // còn byte sau thân
    kTooLarge,      // vượt trần
};

[[nodiscard]] std::string_view describe(CodecError error) noexcept;

inline constexpr std::uint16_t kRecordKind = 0x5201;
// Phiên bản 1 là bố cục không có danh sách kỹ năng (danh sách rỗng). Byte khớp bản ghi đã lưu trước
// khi có học kỹ năng. Phiên bản 2 chỉ khi danh sách không rỗng: thêm số lượng rồi từng id u32, tăng
// dần. Bản đọc nhận cả hai.
inline constexpr std::uint16_t kRecordVersion = 1;
inline constexpr std::uint16_t kRecordVersionSkills = 2;
inline constexpr std::size_t kMaxInnerArtsPerRecord = 64;

using Bytes = std::vector<std::byte>;

// Ghi `record` thêm vào cuối `out`. Lỗi thì `out` giữ nguyên cỡ cũ.
[[nodiscard]] std::expected<void, CodecError> encode_record(const Record& record, Bytes& out);

// Giải mã một khối trọn vẹn (không byte thừa). `max_level` là cấp tối đa của bảng kinh nghiệm.
[[nodiscard]] std::expected<Record, CodecError> decode_record(protocol::ByteView bytes, std::uint16_t max_level);

} // namespace game::actor
