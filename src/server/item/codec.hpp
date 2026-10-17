/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/item/codec.hpp
 *  PHÂN HỆ   : Server / Item / Codec
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bản ghi nhị phân có phiên bản của trạng thái vật phẩm: túi, trang bị, kho,
 *    ví. `store` lưu các khối này nguyên văn (KE-HOACH-SERVER mục 7), nên mỗi
 *    khối là một khung của protocol (đầu 8 byte: loại và độ dài) với thân
 *    little-endian bắt đầu bằng số phiên bản u16.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Bộ giải mã coi đầu vào là thù địch: độ dài, số phần tử, tham chiếu mẫu,
// ô trùng và serial trùng đều được kiểm. Đọc vào bản nháp rồi mới gán, nên
// khối hỏng không để lại gì trong Inventory.
//
// Bố cục thân:
//   phiên bản 1, túi / trang bị / kho: u16 phiên bản | u8 số nơi chứa | ... | u64 hạn dùng là tick
//   của nhịp 20. phiên bản 2: u16 phiên bản | u16 nhịp (20, 30 hoặc 40) | u8 số nơi chứa | ... |
//   u64 hạn dùng là tick của nhịp đó.
//     Lúc đọc, hạn được đổi sang dest_hz, làm tròn lên, cùng nhịp thì đúng nguyên số.
//     mỗi vật phẩm: u16 chỉ số ô | u64 serial | u32 mẫu | u16 số lượng | u8 cờ (bit0 khoá, bit1 đã
//     giám định) | u16 độ bền | u16 hao mòn | u8 lần sửa hỏng | u8 cường hoá | u8 tư chất | u8 số ô
//     đá | u32 đá x số ô đá | u8 số thuộc tính | (u16 id | i32 giá trị) x số thuộc tính | u64 hạn
//     dùng
//   khối ví (vẫn phiên bản 1, không có hạn): u16 phiên bản | u16 số tài khoản | mỗi tài khoản: u8
//   mã | i64 số dư
// Khối trang bị chỉ có nơi chứa kEquip; khối túi có kBaseBag, kMaterialBag, kQuestBag theo thứ tự;
// khối kho có kBank.

#pragma once

#include "item/catalog.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"

#include "protocol/wire.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <vector>

namespace game::item {

inline constexpr std::uint16_t kCodecVersion = 1;
// Túi, trang bị, kho. Phiên bản 2 ghi nhịp của hạn dùng. Ví không có hạn nên vẫn dùng
// kCodecVersion.
inline constexpr std::uint16_t kPlaceVersion = 2;
// Loại khung của khối lưu (không đi qua mạng nên không trùng danh mục tin của protocol).
inline constexpr std::uint16_t kBlobBags = 0x7001;
inline constexpr std::uint16_t kBlobEquipment = 0x7002;
inline constexpr std::uint16_t kBlobBank = 0x7003;
inline constexpr std::uint16_t kBlobWallet = 0x7004;

using Blob = std::vector<std::byte>;

// `hz` là nhịp của expires_at đang nằm trong inventory. Mặc định 20.
[[nodiscard]] std::expected<Blob, Error> encode_bags(const Inventory& inventory,
    std::int64_t hz = kTicksPerSecond);
[[nodiscard]] std::expected<Blob, Error> encode_equipment(const Inventory& inventory,
    std::int64_t hz = kTicksPerSecond);
[[nodiscard]] std::expected<Blob, Error> encode_bank(const Inventory& inventory,
    std::int64_t hz = kTicksPerSecond);
[[nodiscard]] std::expected<Blob, Error> encode_wallet(const Inventory& inventory);

// Giải mã và THAY nơi chứa tương ứng của `into`. Lỗi (kBadBlob) thì `into` giữ nguyên từng byte.
// Serial phải khác với mọi serial của các nơi chứa còn lại trong `into`, nên nạp cả bốn khối vào
// cùng một Inventory để bắt trùng chéo khối. Hạn dùng đọc ra là tick của `dest_hz`.
[[nodiscard]] std::expected<void, Error> decode_bags(protocol::ByteView blob,
    const Catalog& catalog, Inventory& into, std::int64_t dest_hz = kTicksPerSecond);
[[nodiscard]] std::expected<void, Error> decode_equipment(protocol::ByteView blob,
    const Catalog& catalog, Inventory& into, std::int64_t dest_hz = kTicksPerSecond);
[[nodiscard]] std::expected<void, Error> decode_bank(protocol::ByteView blob,
    const Catalog& catalog, Inventory& into, std::int64_t dest_hz = kTicksPerSecond);
[[nodiscard]] std::expected<void, Error> decode_wallet(protocol::ByteView blob, Inventory& into);

} // namespace game::item
