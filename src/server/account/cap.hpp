#pragma once
// Vé năng lực auth cấp sau khi đổi vé đăng nhập. Store chỉ tin account id nằm trong vé này.
// 8 byte id, 8 byte hết hạn (giây Unix), 32 byte HMAC. Ai sửa id thì HMAC không khớp.

#include "secure/secure.hpp"

#include <array>
#include <cstdint>
#include <span>

namespace game::account {

inline constexpr std::size_t kCapBytes = 48;
inline constexpr std::uint64_t kCapTtlSeconds = 8 * 60 * 60;

struct Cap {
    std::uint64_t account = 0;
    std::uint64_t expiry = 0;
};

enum class CapStatus : std::uint8_t { kOk, kBad, kExpired };

[[nodiscard]] bool seal_cap(secure::ByteView key, std::uint64_t account, std::uint64_t expiry,
    std::span<std::byte, kCapBytes> out);

[[nodiscard]] CapStatus open_cap(secure::ByteView key, std::span<const std::byte, kCapBytes> in, std::uint64_t now,
    Cap& cap);

} // namespace game::account
