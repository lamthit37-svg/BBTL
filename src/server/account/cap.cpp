#include "account/cap.hpp"

#include <array>
#include <limits>

namespace game::account {
namespace {

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

} // namespace

bool seal_cap(secure::ByteView key, std::uint64_t account, std::uint64_t expiry, std::span<std::byte, kCapBytes> out) {
    if (account == 0 || account > static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max())) return false;
    put_u64(out.first(8), account);
    put_u64(out.subspan(8, 8), expiry);
    return secure::mac32(key, out.first(16), out.subspan(16));
}

CapStatus open_cap(secure::ByteView key, std::span<const std::byte, kCapBytes> in, std::uint64_t now, Cap& cap) {
    std::array<std::byte, 32> tag{};
    for (std::size_t index = 0; index < tag.size(); ++index) tag[index] = in[16 + index];
    if (!secure::mac32_verify(key, in.first(16), tag)) return CapStatus::kBad;
    cap.account = get_u64(in.first(8));
    cap.expiry = get_u64(in.subspan(8, 8));
    if (cap.account == 0 || cap.account > static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max())) {
        return CapStatus::kBad;
    }
    if (cap.expiry <= now) return CapStatus::kExpired;
    return CapStatus::kOk;
}

} // namespace game::account
