#pragma once
// Lời gọi libsodium cho bắt tay và bản ghi. Tệp này không kéo sodium.h, để header_check
// không cần include của thư viện. Cỡ khoá khoá với hằng của thư viện ở sodium.cpp.

#include <cstddef>
#include <cstdint>
#include <span>
#include <string_view>

namespace game::secure::detail {

inline constexpr std::size_t kPublic = 32;
inline constexpr std::size_t kSecret = 64;
inline constexpr std::size_t kSignature = 64;
inline constexpr std::size_t kSeed = 32;
inline constexpr std::size_t kEphemeralPublic = 32;
inline constexpr std::size_t kEphemeralSecret = 32;
inline constexpr std::size_t kSession = 32;
inline constexpr std::size_t kTag = 16;
inline constexpr std::size_t kNonce = 12;

struct KeyPairOut {
    std::span<std::byte> public_key;
    std::span<std::byte> secret;
};

struct Exchange {
    std::span<std::byte> receive;
    std::span<std::byte> send;
    std::span<const std::byte> own_public;
    std::span<const std::byte> own_secret;
    std::span<const std::byte> peer_public;
};

struct Box {
    std::span<std::byte> cipher;
    std::span<const std::byte> plain;
    std::span<const std::byte> associated;
    std::span<const std::byte> nonce;
    std::span<const std::byte> key;
};

struct OpenBox {
    std::span<std::byte> plain;
    std::span<const std::byte> cipher;
    std::span<const std::byte> associated;
    std::span<const std::byte> nonce;
    std::span<const std::byte> key;
};

struct DetachedSign {
    std::span<std::byte> signature;
    std::span<const std::byte> message;
    std::span<const std::byte> secret;
};

struct DetachedCheck {
    std::span<const std::byte> signature;
    std::span<const std::byte> message;
    std::span<const std::byte> public_key;
};

struct SecretPair {
    std::span<const std::byte> left;
    std::span<const std::byte> right;
};

[[nodiscard]] bool ready() noexcept;
void wipe(std::span<std::byte> region) noexcept;
[[nodiscard]] bool random_bytes(std::span<std::byte> out) noexcept;
[[nodiscard]] bool ephemeral_keypair(KeyPairOut out) noexcept;
[[nodiscard]] bool identity_keypair(KeyPairOut out) noexcept;
[[nodiscard]] bool identity_from_seed(std::span<const std::byte> seed, KeyPairOut out) noexcept;
[[nodiscard]] bool sign_detached(const DetachedSign& request) noexcept;
[[nodiscard]] bool verify_detached(const DetachedCheck& request) noexcept;
[[nodiscard]] bool session_server(const Exchange& exchange) noexcept;
[[nodiscard]] bool session_client(const Exchange& exchange) noexcept;
[[nodiscard]] bool seal_box(const Box& box) noexcept;
[[nodiscard]] bool open_box(const OpenBox& box) noexcept;
[[nodiscard]] bool equal64(SecretPair pair) noexcept;

// out đúng 32 byte. data rỗng vẫn băm được.
[[nodiscard]] bool sha256(std::span<const std::byte> data, std::span<std::byte> out) noexcept;

// out phải đủ 128 byte, kể cả dấu kết thúc. ops và mem_bytes là tham số Argon2id của libsodium
// (mem_bytes là byte, không phải KiB). Sai tham số hoặc hết entropy thì false, không abort.
struct PasswordRequest {
    std::span<char> out;
    std::string_view password;
    std::uint64_t ops = 0;
    std::size_t mem_bytes = 0;
};

[[nodiscard]] bool hash_password(const PasswordRequest& request) noexcept;
[[nodiscard]] bool verify_password(std::string_view hash, std::string_view password) noexcept;

// XChaCha20-Poly1305. nonce 24 byte, key 32 byte, cipher dài bằng plain cộng 16.
[[nodiscard]] bool aead_seal(std::span<const std::byte> key, std::span<const std::byte> nonce,
    std::span<const std::byte> plain, std::span<std::byte> cipher) noexcept;
[[nodiscard]] bool aead_open(std::span<const std::byte> key, std::span<const std::byte> nonce,
    std::span<const std::byte> cipher, std::span<std::byte> plain) noexcept;

// HMAC-SHA512-256. tag 32 byte, key 32 byte.
[[nodiscard]] bool mac32(std::span<const std::byte> key, std::span<const std::byte> message,
    std::span<std::byte> tag) noexcept;
[[nodiscard]] bool mac32_verify(std::span<const std::byte> key, std::span<const std::byte> message,
    std::span<const std::byte> tag) noexcept;

} // namespace game::secure::detail
