// Bản ghi ChaCha20-Poly1305 IETF. Bộ đếm không đi trên dây và không quay vòng.
// SECURE_DROP_LENGTH_CHECK chỉ để chứng minh bộ dò có răng: bỏ kiểm độ dài rồi chép
// đúng số byte bên kia khai. Bản dựng thường không định nghĩa macro này.
#include "secure/secure.hpp"

#include "secure/detail/bytes.hpp"
#include "secure/detail/sodium.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <expected>
#include <span>
#include <utility>

namespace game::secure {
namespace {

constexpr unsigned kCounterBytes = 8;

void put_counter_byte(std::span<std::byte> nonce, unsigned shift, std::uint64_t counter) noexcept {
    const auto piece = static_cast<unsigned char>(counter >> (shift * 8U));
    const auto index = std::size_t{4} + shift;
    nonce[index] = static_cast<std::byte>(piece);
}

[[nodiscard]] std::array<std::byte, detail::kNonce> nonce_of(std::uint64_t counter) noexcept {
    std::array<std::byte, detail::kNonce> nonce{};
    for (unsigned shift = 0; shift < kCounterBytes; ++shift) {
        put_counter_byte(nonce, shift, counter);
    }
    return nonce;
}

} // namespace

RecordPipe::RecordPipe(SessionKeys keys) noexcept : keys_(std::move(keys)) {}

RecordPipe::~RecordPipe() {
    wipe_pending();
}

RecordPipe::RecordPipe(RecordPipe&& other) noexcept {
    *this = std::move(other);
}

RecordPipe& RecordPipe::operator=(RecordPipe&& other) noexcept {
    if (this == &other) return *this;
    wipe_pending();
    keys_ = std::move(other.keys_);
    send_counter_ = other.send_counter_;
    receive_counter_ = other.receive_counter_;
    pending_bytes_ = other.pending_bytes_;
    pending_ = other.pending_;
    broken_ = other.broken_;
    error_ = other.error_;
    other.wipe_pending();
    other.send_counter_ = 0;
    other.receive_counter_ = 0;
    other.broken_ = true;
    other.error_ = Error::kState;
    return *this;
}

void RecordPipe::wipe_pending() noexcept {
    detail::wipe(pending_bytes_);
    pending_ = 0;
}

void RecordPipe::break_with(Error error) noexcept {
    error_ = error;
    broken_ = true;
    wipe_pending();
    detail::wipe(keys_.send);
    detail::wipe(keys_.receive);
}

bool RecordPipe::pull(ByteView& input, Opened& opened, std::size_t need) noexcept {
    if (need < pending_) {
        break_with(Error::kProtocol);
        return false;
    }
    const std::size_t declared = need - pending_;
#if defined(SECURE_DROP_LENGTH_CHECK)
    std::memcpy(pending_bytes_.data() + pending_, input.data(), declared);
    pending_ += declared;
    opened.consumed += declared;
    return true;
#else
    if (pending_ + declared > pending_bytes_.size()) {
        break_with(Error::kProtocol);
        return false;
    }
    const std::size_t room = std::min(declared, input.size());
    if (room == 0) return false;
    const std::span<std::byte> dest = std::span{pending_bytes_}.subspan(pending_, room);
    std::memcpy(dest.data(), input.data(), room);
    pending_ += room;
    input = input.subspan(room);
    opened.consumed += room;
    return true;
#endif
}

bool RecordPipe::length_ok() const noexcept {
#if defined(SECURE_DROP_LENGTH_CHECK)
    return true;
#else
    const std::uint16_t body = body_length();
    if (body < kTagBytes + 1) return false;
    return body <= kMaxBodyBytes;
#endif
}

std::uint16_t RecordPipe::body_length() const noexcept {
    const ByteView header{pending_bytes_.data(), kRecordHeaderBytes};
    return detail::read_u16(header);
}

bool RecordPipe::decrypt(std::span<std::byte> plain, Opened& opened) noexcept {
    if (receive_counter_ == kCounterLast) {
        break_with(Error::kExhausted);
        return false;
    }
    const std::size_t plain_len = static_cast<std::size_t>(body_length()) - kTagBytes;
    core::check(plain.size() >= opened.written + plain_len, "vùng rõ không đủ một bản ghi");
    const std::array<std::byte, detail::kNonce> nonce = nonce_of(receive_counter_);
    const std::span<std::byte> held = std::span{pending_bytes_};
    const std::span<std::byte> cipher = held.subspan(kRecordHeaderBytes, body_length());
    const std::span<std::byte> out = plain.subspan(opened.written, plain_len);
    const ByteView header = held.first(kRecordHeaderBytes);
    // NOLINTNEXTLINE(modernize-use-designated-initializers): designated một dòng không vừa 120 cột
    const detail::OpenBox box{out, cipher, header, nonce, keys_.receive};
    if (!detail::open_box(box)) {
        break_with(Error::kRecord);
        return false;
    }
    opened.written += plain_len;
    wipe_pending();
    ++receive_counter_;
    return true;
}

OpenResult RecordPipe::open_bytes(ByteView input, std::span<std::byte> plain) noexcept {
    if (broken_) return std::unexpected(error_);
    core::check(plain.size() >= kMaxPlainBytes, "vùng rõ phải chứa một bản ghi");
    Opened opened;
    if (pending_ < kRecordHeaderBytes) {
        const bool pulled = pull(input, opened, kRecordHeaderBytes);
        static_cast<void>(pulled);
    }
    if (broken_) return std::unexpected(error_);
    if (pending_ < kRecordHeaderBytes) return opened;
    if (!length_ok()) {
        break_with(Error::kProtocol);
        return std::unexpected(error_);
    }
    const std::size_t need = kRecordHeaderBytes + body_length();
    if (pending_ < need) {
        const bool pulled = pull(input, opened, need);
        static_cast<void>(pulled);
    }
    if (broken_) return std::unexpected(error_);
    if (pending_ < need) return opened;
    if (!decrypt(plain, opened)) return std::unexpected(error_);
    return opened;
}

SealResult RecordPipe::seal(ByteView plain, std::span<std::byte> out) noexcept {
    if (broken_) return std::unexpected(error_);
    if (plain.empty() || plain.size() > kMaxPlainBytes) return std::unexpected(Error::kProtocol);
    if (send_counter_ == kCounterLast) {
        break_with(Error::kExhausted);
        return std::unexpected(error_);
    }
    const std::size_t body = plain.size() + kTagBytes;
    const std::size_t total = kRecordHeaderBytes + body;
    if (out.size() < total) return std::unexpected(Error::kCapacity);
    detail::write_u16(out.first(kRecordHeaderBytes), static_cast<std::uint16_t>(body));
    const std::array<std::byte, detail::kNonce> nonce = nonce_of(send_counter_);
    const std::span<std::byte> cipher = out.subspan(kRecordHeaderBytes, body);
    const ByteView header = out.first(kRecordHeaderBytes);
    // NOLINTNEXTLINE(modernize-use-designated-initializers): designated một dòng không vừa 120 cột
    const detail::Box box{cipher, plain, header, nonce, keys_.send};
    if (!detail::seal_box(box)) {
        break_with(Error::kRandom);
        return std::unexpected(error_);
    }
    ++send_counter_;
    return total;
}

void RecordPipe::advance_counters(CounterMarks marks) noexcept {
    send_counter_ = std::max(send_counter_, marks.send);
    receive_counter_ = std::max(receive_counter_, marks.receive);
}

} // namespace game::secure
