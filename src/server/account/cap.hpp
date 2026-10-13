#pragma once
// Vé năng lực auth cấp sau khi đổi vé đăng nhập. Store chỉ tin account id nằm trong vé này.
// 8 byte id, 8 byte hết hạn (giây Unix), 4 byte key id, 32 byte HMAC trên 20 byte đầu.
// HMAC dùng khoá con tách miền từ ipc.key (không dùng thẳng khoá bọc khung). Key id là 4 byte đầu
// của một khoá con khác: xoay ipc.key (khoá lộ) thì mọi cap cũ bị thu hồi với kRevoked, phân biệt
// được với cap bị sửa (kBad) trong log và test.

#include "secure/secure.hpp"

#include <array>
#include <cstdint>
#include <span>

namespace game::account {

inline constexpr std::size_t kCapBytes = 52;
// Ban không chờ cap hết hạn: mỗi lệnh store hỏi lại auth (kStanding, nhớ tối đa kStandingTtl).
// Gate chưa có đường làm mới cap giữa phiên nên TTL giữ bằng một phiên chơi dài.
inline constexpr std::uint64_t kCapTtlSeconds = std::uint64_t{8} * 60 * 60;

struct Cap {
    std::uint64_t account = 0;
    std::uint64_t expiry = 0;
};

enum class CapStatus : std::uint8_t { kOk, kBad, kExpired, kRevoked };

// Key id của khoá hiện hành; 0 khi không dựng được khoá con.
[[nodiscard]] std::uint32_t cap_key_id(secure::ByteView key);

[[nodiscard]] bool seal_cap(secure::ByteView key, std::uint64_t account, std::uint64_t expiry,
    std::span<std::byte, kCapBytes> out);

[[nodiscard]] CapStatus open_cap(secure::ByteView key, std::span<const std::byte, kCapBytes> in, std::uint64_t now,
    Cap& cap);

} // namespace game::account
