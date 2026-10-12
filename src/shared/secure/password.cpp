// Băm mật khẩu và byte ngẫu nhiên. Mật mã nằm ở libsodium; tệp này chỉ đổi kiểu.
#include "secure/secure.hpp"

#include "secure/detail/sodium.hpp"

#include <algorithm>
#include <array>
#include <span>
#include <vector>

namespace game::secure {

bool fill_random(std::span<std::byte> out) noexcept {
    return detail::random_bytes(out);
}

bool sha256(ByteView data, std::span<std::byte> out) noexcept {
    return detail::sha256(data, out);
}

bool hash_password(std::string_view password, PasswordPolicy policy, std::string& out) {
    std::array<char, 128> buffer{};
    const detail::PasswordRequest request{
        .out = buffer,
        .password = password,
        .ops = policy.ops,
        .mem_bytes = policy.mem_bytes,
    };
    if (!detail::hash_password(request)) return false;
    out.assign(buffer.data());
    wipe_bytes(std::as_writable_bytes(std::span{buffer}));
    return !out.empty();
}

bool verify_password(std::string_view hash, std::string_view password) noexcept {
    return detail::verify_password(hash, password);
}

void wipe_bytes(std::span<std::byte> region) noexcept {
    detail::wipe(region);
}

std::optional<std::vector<std::byte>> ipc_seal(ByteView key, ByteView plain) {
    std::array<std::byte, 24> nonce{};
    if (!fill_random(nonce)) return std::nullopt;
    std::vector<std::byte> boxed(nonce.size() + plain.size() + 16);
    std::copy(nonce.begin(), nonce.end(), boxed.begin());
    const std::span<std::byte> cipher = std::span{boxed}.subspan(nonce.size());
    if (!detail::aead_seal(key, nonce, plain, cipher)) return std::nullopt;
    return boxed;
}

std::optional<std::vector<std::byte>> ipc_open(ByteView key, ByteView boxed) {
    constexpr std::size_t kNonce = 24;
    constexpr std::size_t kTag = 16;
    if (boxed.size() < kNonce + kTag) return std::nullopt;
    const ByteView nonce = boxed.first(kNonce);
    const ByteView cipher = boxed.subspan(kNonce);
    std::vector<std::byte> plain(cipher.size() - kTag);
    if (!detail::aead_open(key, nonce, cipher, plain)) return std::nullopt;
    return plain;
}

bool mac32(ByteView key, ByteView message, std::span<std::byte> tag) {
    return detail::mac32(key, message, tag);
}

bool mac32_verify(ByteView key, ByteView message, ByteView tag) noexcept {
    return detail::mac32_verify(key, message, tag);
}

} // namespace game::secure
