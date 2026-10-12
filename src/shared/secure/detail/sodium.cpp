// Biên giới libsodium cho bắt tay và bản ghi. Mật mã không tự viết.
// NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast, misc-include-cleaner)
// Ép byte* sang unsigned char* là biên C của libsodium; header ô là sodium.h (HP-07).
#include "secure/detail/sodium.hpp"

#include "core/check.hpp"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <sodium.h>

#include <cstddef>
#include <span>

namespace game::secure::detail {
namespace {

void require_size(std::span<const std::byte> bytes, std::size_t need) noexcept {
    core::check(bytes.size() == need, "cỡ đối số libsodium lệch");
}

const unsigned char* raw(std::span<const std::byte> bytes) noexcept {
    return reinterpret_cast<const unsigned char*>(bytes.data());
}

unsigned char* raw_mut(std::span<std::byte> bytes) noexcept {
    return reinterpret_cast<unsigned char*>(bytes.data());
}

const unsigned char* or_null(std::span<const std::byte> bytes) noexcept {
    if (bytes.empty()) return nullptr;
    return raw(bytes);
}

} // namespace

bool ready() noexcept {
    return sodium_init() >= 0;
}

void wipe(std::span<std::byte> region) noexcept {
    if (region.empty()) return;
    sodium_memzero(region.data(), region.size());
}

bool random_bytes(std::span<std::byte> out) noexcept {
    if (!ready()) return false;
    if (out.empty()) return true;
    randombytes_buf(out.data(), out.size());
    return true;
}

bool ephemeral_keypair(KeyPairOut out) noexcept {
    if (!ready()) return false;
    require_size(out.public_key, kEphemeralPublic);
    require_size(out.secret, kEphemeralSecret);
    unsigned char* public_key = raw_mut(out.public_key);
    unsigned char* secret = raw_mut(out.secret);
    return crypto_kx_keypair(public_key, secret) == 0;
}

bool identity_keypair(KeyPairOut out) noexcept {
    if (!ready()) return false;
    require_size(out.public_key, kPublic);
    require_size(out.secret, kSecret);
    unsigned char* public_key = raw_mut(out.public_key);
    unsigned char* secret = raw_mut(out.secret);
    return crypto_sign_keypair(public_key, secret) == 0;
}

bool identity_from_seed(std::span<const std::byte> seed, KeyPairOut out) noexcept {
    if (!ready()) return false;
    require_size(seed, kSeed);
    require_size(out.public_key, kPublic);
    require_size(out.secret, kSecret);
    unsigned char* public_key = raw_mut(out.public_key);
    unsigned char* secret = raw_mut(out.secret);
    const unsigned char* seed_bytes = raw(seed);
    return crypto_sign_seed_keypair(public_key, secret, seed_bytes) == 0;
}

bool sign_detached(const DetachedSign& request) noexcept {
    if (!ready()) return false;
    require_size(request.signature, kSignature);
    require_size(request.secret, kSecret);
    unsigned char* signature = raw_mut(request.signature);
    const unsigned char* message = or_null(request.message);
    const auto length = request.message.size();
    const unsigned char* secret = raw(request.secret);
    const auto sign = crypto_sign_detached;
    return sign(signature, nullptr, message, length, secret) == 0;
}

bool verify_detached(const DetachedCheck& request) noexcept {
    if (!ready()) return false;
    require_size(request.signature, kSignature);
    require_size(request.public_key, kPublic);
    const unsigned char* signature = raw(request.signature);
    const unsigned char* message = or_null(request.message);
    const auto length = request.message.size();
    const unsigned char* public_key = raw(request.public_key);
    const auto verify = crypto_sign_verify_detached;
    return verify(signature, message, length, public_key) == 0;
}

bool session_server(const Exchange& exchange) noexcept {
    if (!ready()) return false;
    require_size(exchange.receive, kSession);
    require_size(exchange.send, kSession);
    require_size(exchange.own_public, kEphemeralPublic);
    require_size(exchange.own_secret, kEphemeralSecret);
    require_size(exchange.peer_public, kEphemeralPublic);
    unsigned char* receive = raw_mut(exchange.receive);
    unsigned char* send = raw_mut(exchange.send);
    const unsigned char* own_public = raw(exchange.own_public);
    const unsigned char* own_secret = raw(exchange.own_secret);
    const unsigned char* peer = raw(exchange.peer_public);
    const auto keys = crypto_kx_server_session_keys;
    return keys(receive, send, own_public, own_secret, peer) == 0;
}

bool session_client(const Exchange& exchange) noexcept {
    if (!ready()) return false;
    require_size(exchange.receive, kSession);
    require_size(exchange.send, kSession);
    require_size(exchange.own_public, kEphemeralPublic);
    require_size(exchange.own_secret, kEphemeralSecret);
    require_size(exchange.peer_public, kEphemeralPublic);
    unsigned char* receive = raw_mut(exchange.receive);
    unsigned char* send = raw_mut(exchange.send);
    const unsigned char* own_public = raw(exchange.own_public);
    const unsigned char* own_secret = raw(exchange.own_secret);
    const unsigned char* peer = raw(exchange.peer_public);
    const auto keys = crypto_kx_client_session_keys;
    return keys(receive, send, own_public, own_secret, peer) == 0;
}

bool seal_box(const Box& box) noexcept {
    if (!ready()) return false;
    const bool fits = box.cipher.size() == box.plain.size() + kTag;
    core::check(fits, "bản mã phải dài bằng bản rõ cộng dấu");
    require_size(box.nonce, kNonce);
    require_size(box.key, kSession);
    unsigned char* cipher = raw_mut(box.cipher);
    const unsigned char* plain = or_null(box.plain);
    const unsigned char* extra = or_null(box.associated);
    const auto plain_len = box.plain.size();
    const auto extra_len = box.associated.size();
    const unsigned char* nonce = raw(box.nonce);
    const unsigned char* key = raw(box.key);
    const auto enc = crypto_aead_chacha20poly1305_ietf_encrypt;
    const int failed = enc(cipher, nullptr, plain, plain_len, extra, extra_len, nullptr, nonce, key);
    return failed == 0;
}

bool open_box(const OpenBox& box) noexcept {
    if (!ready()) return false;
    const bool fits = box.cipher.size() == box.plain.size() + kTag;
    core::check(fits, "vùng rõ không khớp bản mã");
    require_size(box.nonce, kNonce);
    require_size(box.key, kSession);
    unsigned char* plain = raw_mut(box.plain);
    const unsigned char* cipher = raw(box.cipher);
    const unsigned char* extra = or_null(box.associated);
    const auto cipher_len = box.cipher.size();
    const auto extra_len = box.associated.size();
    const unsigned char* nonce = raw(box.nonce);
    const unsigned char* key = raw(box.key);
    const auto dec = crypto_aead_chacha20poly1305_ietf_decrypt;
    const int failed = dec(plain, nullptr, nullptr, cipher, cipher_len, extra, extra_len, nonce, key);
    if (failed != 0) wipe(box.plain);
    return failed == 0;
}

bool equal64(SecretPair pair) noexcept {
    require_size(pair.left, kSecret);
    require_size(pair.right, kSecret);
    return crypto_verify_64(raw(pair.left), raw(pair.right)) == 0;
}

} // namespace game::secure::detail

static_assert(crypto_kx_PUBLICKEYBYTES == game::secure::detail::kEphemeralPublic);
static_assert(crypto_kx_SECRETKEYBYTES == game::secure::detail::kEphemeralSecret);
static_assert(crypto_kx_SESSIONKEYBYTES == game::secure::detail::kSession);
static_assert(crypto_sign_PUBLICKEYBYTES == game::secure::detail::kPublic);
static_assert(crypto_sign_SECRETKEYBYTES == game::secure::detail::kSecret);
static_assert(crypto_sign_SEEDBYTES == game::secure::detail::kSeed);
static_assert(crypto_sign_BYTES == game::secure::detail::kSignature);
static_assert(crypto_aead_chacha20poly1305_ietf_ABYTES == game::secure::detail::kTag);
static_assert(crypto_aead_chacha20poly1305_ietf_NPUBBYTES == game::secure::detail::kNonce);
static_assert(crypto_aead_chacha20poly1305_ietf_KEYBYTES == game::secure::detail::kSession);
// NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast, misc-include-cleaner)
