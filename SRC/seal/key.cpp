// Khoá gói: bản sao và bản chuyển đều xoá byte khi hết đời. sodium_memzero không bị tối ưu bỏ.
#include "seal/package.hpp"

#include "seal/detail/sodium.hpp"

#include <expected>

namespace game::seal {

Key::Key(const Key&) = default;

Key& Key::operator=(const Key& other) {
    if (this == &other) return *this;
    detail::wipe(bytes);
    bytes = other.bytes;
    return *this;
}

Key::Key(Key&& other) noexcept : bytes(other.bytes) {
    detail::wipe(other.bytes);
}

Key& Key::operator=(Key&& other) noexcept {
    if (this == &other) return *this;
    detail::wipe(bytes);
    bytes = other.bytes;
    detail::wipe(other.bytes);
    return *this;
}

Key::~Key() {
    detail::wipe(bytes);
}

KeyResult random_key() {
    Key key;
    const bool filled = detail::fill_random(key.bytes);
    if (!filled) return std::unexpected(Error::kCrypto);
    return key;
}

} // namespace game::seal
