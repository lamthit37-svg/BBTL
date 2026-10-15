/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/account/play.hpp
 *  PHÂN HỆ   : Server / Account / Play
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Trạng thái chơi của một nhân vật dạng khối bền: thứ zone giữ trong bộ nhớ
 *    và store ghi xuống bảng player. Cấp, kinh nghiệm, sinh lực, tiền là số
 *    thường (cột của bảng, danh sách nhân vật và công cụ quản trị đọc thẳng);
 *    thân thể, sổ nhiệm vụ và túi là khối nhị phân có phiên bản của
 *    actor::codec, mission::codec và play::bag, store lưu nguyên văn và không
 *    giải mã.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Gói gọn thành một khung protocol (kind riêng, không đi tới client) để mang qua ba chặng: store → gate (trả lời Op::kEnter),
// gate → zone (ipc::Attach::play) và zone → store (Op::kSave). Bộ giải mã coi đầu vào là thù địch: độ dài, kích cỡ từng khối và
// byte thừa đều bị kiểm trước khi cấp phát.

#pragma once

#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <vector>

namespace game::account {

inline constexpr std::uint16_t kPlayKind = 0x7301;
inline constexpr std::uint16_t kPlayVersion = 1;
// Trần từng khối; tổng ba trần cộng phần số vẫn dưới kMaxBodyBytes của một khung protocol.
inline constexpr std::size_t kMaxBodyBlob = 2048;
inline constexpr std::size_t kMaxMissionBlob = std::size_t{32} * 1024;
inline constexpr std::size_t kMaxBagBlob = std::size_t{16} * 1024;
// Cỡ tối đa của một khối đã đóng gói (khung 8 byte + số cố định + ba khối có tiền tố 4 byte); khung rpc dựa vào số này.
inline constexpr std::size_t kMaxPackedPlay = protocol::kHeaderBytes + 64 + kMaxBodyBlob + kMaxMissionBlob + kMaxBagBlob;
// Trần số dư tiền (cùng trần một dòng của sổ cái: 2^40).
inline constexpr std::uint64_t kMoneyLimit = std::uint64_t{1} << 40U;

struct PlayRecord {
    std::uint16_t level = 1;
    std::uint64_t exp = 0;
    std::uint64_t money = 0;
    std::uint64_t bound = 0;
    std::int32_t hp = 1;
    std::int32_t mp = 0;
    // Rỗng là chưa có khối (nhân vật chưa từng vào game từ bản này): zone dựng mới từ các số ở trên.
    std::vector<std::byte> body;
    std::vector<std::byte> mission;
    std::vector<std::byte> bag;

    friend bool operator==(const PlayRecord&, const PlayRecord&) = default;
};

enum class [[nodiscard]] PlayError : std::uint8_t {
    kBadFrame = 1,  // khung, loại hay phiên bản sai
    kBadValue,      // số ngoài miền (cấp 0, tiền quá trần)
    kTooLarge,      // một khối vượt trần
    kTruncated,
    kTrailing,
};

[[nodiscard]] std::expected<std::vector<std::byte>, PlayError> pack(const PlayRecord& record);
[[nodiscard]] std::expected<PlayRecord, PlayError> unpack(protocol::ByteView bytes);

} // namespace game::account
