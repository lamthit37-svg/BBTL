// Biên giới libsodium. Mật mã không tự viết: XChaCha20-Poly1305, BLAKE2b, crypto_kdf.
// Ngữ cảnh KDF đúng 8 byte "TLBBPAK_" như gói TLBBPAK1. Id khoá con do người gọi chọn.
#include "seal/detail/sodium.hpp"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <sodium.h>

namespace game::seal::detail {
namespace {

constexpr std::size_t kNonce = crypto_aead_xchacha20poly1305_ietf_NPUBBYTES;
constexpr std::size_t kTag = crypto_aead_xchacha20poly1305_ietf_ABYTES;
constexpr char kContext[crypto_kdf_CONTEXTBYTES] = {'T', 'L', 'B', 'B', 'P', 'A', 'K', '_'};

static_assert(kNonce == 24);
static_assert(kTag == 16);
static_assert(crypto_kdf_KEYBYTES == 32);

const unsigned char* as_raw(const std::byte* pointer) noexcept {
    return reinterpret_cast<const unsigned char*>(pointer);
}

unsigned char* as_raw(std::byte* pointer) noexcept {
    return reinterpret_cast<unsigned char*>(pointer);
}

const unsigned char* or_null(std::span<const std::byte> bytes) noexcept {
    if (bytes.empty()) return nullptr;
    return as_raw(bytes.data());
}

} // namespace

bool ready() noexcept {
    return sodium_init() >= 0;
}

void wipe(std::span<std::byte> region) noexcept {
    if (region.empty()) return;
    sodium_memzero(region.data(), region.size());
}

bool fill_random(std::span<std::byte> out) noexcept {
    if (!ready()) return false;
    if (out.empty()) return true;
    randombytes_buf(out.data(), out.size());
    return true;
}

bool derive(SecretOut out, Secret root, std::uint64_t subkey_id) noexcept {
    if (!ready()) return false;
    const int failed =
        crypto_kdf_derive_from_key(as_raw(out.data()), out.size(), subkey_id, kContext, as_raw(root.data()));
    return failed == 0;
}

bool blake16(HashOut out, Secret key, std::span<const std::byte> message) noexcept {
    if (!ready()) return false;
    const int failed = crypto_generichash(as_raw(out.data()), out.size(), or_null(message), message.size(),
        as_raw(key.data()), key.size());
    return failed == 0;
}

bool equal16(HashIn left, HashIn right) noexcept {
    return crypto_verify_16(as_raw(left.data()), as_raw(right.data())) == 0;
}

bool seal_box(const Box& box) noexcept {
    if (!ready()) return false;
    const bool sized = box.destination.size() == box.source.size() + kNonce + kTag;
    if (!sized) return false;
    randombytes_buf(box.destination.data(), kNonce);
    unsigned long long written = 0;
    const auto body = box.destination.subspan(kNonce);
    const unsigned char* message = or_null(box.source);
    const unsigned char* extra = or_null(box.extra);
    const int failed = crypto_aead_xchacha20poly1305_ietf_encrypt(as_raw(body.data()), &written, message,
        box.source.size(), extra, box.extra.size(), nullptr, as_raw(box.destination.data()), as_raw(box.key.data()));
    if (failed != 0) return false;
    return written == box.source.size() + kTag;
}

bool open_box(const Box& box) noexcept {
    if (!ready()) return false;
    if (box.source.size() < kNonce + kTag) return false;
    const bool sized = box.destination.size() + kNonce + kTag == box.source.size();
    if (!sized) return false;
    unsigned long long written = 0;
    unsigned char unused = 0;
    unsigned char* plain = box.destination.empty() ? &unused : as_raw(box.destination.data());
    const auto body = box.source.subspan(kNonce);
    const int failed = crypto_aead_xchacha20poly1305_ietf_decrypt(plain, &written, nullptr, as_raw(body.data()),
        body.size(), or_null(box.extra), box.extra.size(), as_raw(box.source.data()), as_raw(box.key.data()));
    if (failed != 0) wipe(box.destination);
    if (failed != 0) return false;
    return written == box.destination.size();
}

} // namespace game::seal::detail
