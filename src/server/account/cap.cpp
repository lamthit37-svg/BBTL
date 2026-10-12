#include "account/cap.hpp"

#include <array>
#include <limits>
#include <string_view>

namespace game::account {
namespace {

constexpr std::size_t kSignedBytes = 20;

void put_u64(std::span<std::byte> out, std::uint64_t value) {
    for (std::size_t index = 0; index < 8; ++index) {
        out[index] = static_cast<std::byte>(value & 0xffU);
        value >>= 8U;
    }
}

[[nodiscard]] std::uint64_t get_u64(std::span<const std::byte> in) {
    std::uint64_t value = 0;
    for (std::size_t index = 0; index < 8; ++index) {
        value |= static_cast<std::uint64_t>(in[index]) << (8U * index);
    }
    return value;
}

void put_u32(std::span<std::byte> out, std::uint32_t value) {
    for (std::size_t index = 0; index < 4; ++index) {
        out[index] = static_cast<std::byte>(value & 0xffU);
        value >>= 8U;
    }
}

[[nodiscard]] std::uint32_t get_u32(std::span<const std::byte> in) {
    std::uint32_t value = 0;
    for (std::size_t index = 0; index < 4; ++index) {
        value |= static_cast<std::uint32_t>(in[index]) << (8U * index);
    }
    return value;
}

// Khoá con = HMAC(ipc.key, nhãn). Nhãn khác nhau thì khoá con độc lập.
[[nodiscard]] bool subkey(secure::ByteView key, std::string_view label, std::span<std::byte, 32> out) {
    return secure::mac32(key, std::as_bytes(std::span{label.data(), label.size()}), out);
}

} // namespace

std::uint32_t cap_key_id(secure::ByteView key) {
    std::array<std::byte, 32> id{};
    if (!subkey(key, "thienlong/cap-key-id/v1", id)) return 0;
    const std::uint32_t value = get_u32(id);
    secure::wipe_bytes(id);
    return value == 0 ? 1 : value;
}

bool seal_cap(secure::ByteView key, std::uint64_t account, std::uint64_t expiry, std::span<std::byte, kCapBytes> out) {
    if (account == 0 || account > static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max())) return false;
    const std::uint32_t id = cap_key_id(key);
    std::array<std::byte, 32> mac_key{};
    if (id == 0 || !subkey(key, "thienlong/cap-mac/v1", mac_key)) return false;
    put_u64(out.first(8), account);
    put_u64(out.subspan(8, 8), expiry);
    put_u32(out.subspan(16, 4), id);
    const bool sealed = secure::mac32(mac_key, out.first(kSignedBytes), out.subspan(kSignedBytes));
    secure::wipe_bytes(mac_key);
    return sealed;
}

CapStatus open_cap(secure::ByteView key, std::span<const std::byte, kCapBytes> in, std::uint64_t now, Cap& cap) {
    const std::uint32_t id = cap_key_id(key);
    if (id == 0) return CapStatus::kBad;
    std::array<std::byte, 32> mac_key{};
    if (!subkey(key, "thienlong/cap-mac/v1", mac_key)) return CapStatus::kBad;
    const bool genuine = secure::mac32_verify(mac_key, in.first(kSignedBytes), in.subspan(kSignedBytes));
    secure::wipe_bytes(mac_key);
    if (!genuine) {
        // Chữ ký không khớp. Key id khác khoá hiện hành thì đây là cap của khoá đã xoay (thu hồi).
        return get_u32(in.subspan(16, 4)) != id ? CapStatus::kRevoked : CapStatus::kBad;
    }
    cap.account = get_u64(in.first(8));
    cap.expiry = get_u64(in.subspan(8, 8));
    if (cap.account == 0 || cap.account > static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max())) {
        return CapStatus::kBad;
    }
    if (cap.expiry <= now) return CapStatus::kExpired;
    return CapStatus::kOk;
}

} // namespace game::account
