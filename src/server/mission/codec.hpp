#pragma once
// Bản ghi nhị phân có phiên bản của sổ nhiệm vụ. `store` lưu khối này nguyên văn; mỗi khối là một khung của protocol (đầu 8 byte:
// loại và độ dài) với thân little-endian bắt đầu bằng số phiên bản u16, theo mẫu item::codec. Bộ giải mã coi đầu vào là thù địch:
// độ dài, số phần tử, ô trùng, mã tăng không ngặt, mặt nạ cờ và id ngoài miền đều bị kiểm; đọc vào bản nháp rồi mới gán nên
// khối hỏng không để lại gì trong Book.
//
// Bố cục thân (phiên bản 1):
//   u16 phiên bản | u64 ledger_seq | u64 mốc nhật ký | u16 số biên nhận | (u64 mã | u8 lý do) x số biên nhận |
//   u16 số ô dùng | (u8 chỉ số ô | i32 nhiệm vụ | i32 script | u8 cờ | u32 x 8 tham số) x số ô dùng |
//   u16 số từ "đã xong" khác 0 | (u8 chỉ số từ | u32 bit) x số từ, chỉ số tăng ngặt |
//   u16 số bộ đếm | (i32 chỉ số | i64 giá trị) x số bộ đếm, chỉ số tăng ngặt |
//   u16 số cờ | (i32 chỉ số) x số cờ, tăng ngặt

#include "mission/book.hpp"
#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <vector>

namespace game::mission {

inline constexpr std::uint16_t kCodecVersion = 1;
// Loại khung của khối lưu (không đi qua mạng nên không trùng danh mục tin của protocol).
inline constexpr std::uint16_t kBlobBook = 0x7101;

enum class [[nodiscard]] CodecError : std::uint8_t {
    kBadBlob = 1,   // khung, độ dài, phiên bản hoặc giá trị hỏng
    kEncodeFailed,  // sổ không hợp lệ hoặc vượt trần khung
};

using Blob = std::vector<std::byte>;

[[nodiscard]] std::expected<Blob, CodecError> encode(const Book& book);

// Giải mã và THAY toàn bộ `into`. Lỗi thì `into` giữ nguyên từng byte.
[[nodiscard]] std::expected<void, CodecError> decode(protocol::ByteView blob, Book& into);

}  // namespace game::mission
