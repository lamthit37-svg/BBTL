// Bắt tay: lời chào 42 byte, lời đáp 96 byte, chữ ký phủ cả hai khoá tạm và phiên bản.
#include "secure/secure.hpp"

#include "secure/detail/bytes.hpp"
#include "secure/detail/sodium.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstring>
#include <expected>
#include <span>
#include <utility>

namespace game::secure {
namespace {

void fill_transcript(std::span<std::byte> out, ByteView client_key, ByteView server_key) noexcept {
    core::check(out.size() == kTranscriptBytes, "cỡ bản ghi ký lệch");
    core::check(client_key.size() == kEphemeralBytes, "cỡ khoá tạm client lệch");
    core::check(server_key.size() == kEphemeralBytes, "cỡ khoá tạm máy chủ lệch");
    std::memcpy(out.data(), client_key.data(), client_key.size());
    std::memcpy(out.subspan(kEphemeralBytes).data(), server_key.data(), server_key.size());
    const std::size_t label_at = (kEphemeralBytes * 2);
    std::memcpy(out.subspan(label_at).data(), kLabel.data(), kLabel.size());
    detail::write_u16(out.subspan(label_at + kLabelBytes), kSecureVersion);
}

} // namespace

ServerHandshake::ServerHandshake(const Identity& identity) noexcept : identity_(&identity) {}

ServerHandshake::~ServerHandshake() {
    wipe_ephemeral();
    detail::wipe(hello_);
    detail::wipe(reply_);
}

ServerHandshake::ServerHandshake(ServerHandshake&& other) noexcept {
    *this = std::move(other);
}

ServerHandshake& ServerHandshake::operator=(ServerHandshake&& other) noexcept {
    if (this == &other) return *this;
    wipe_ephemeral();
    detail::wipe(hello_);
    detail::wipe(reply_);
    identity_ = other.identity_;
    hello_ = other.hello_;
    filled_ = other.filled_;
    server_public_ = other.server_public_;
    server_secret_ = other.server_secret_;
    reply_ = other.reply_;
    keys_ = std::move(other.keys_);
    keys_taken_ = other.keys_taken_;
    stage_ = other.stage_;
    error_ = other.error_;
    other.wipe_ephemeral();
    detail::wipe(other.hello_);
    detail::wipe(other.reply_);
    other.identity_ = nullptr;
    other.filled_ = 0;
    other.keys_taken_ = false;
    other.stage_ = Stage::kMoved;
    return *this;
}

void ServerHandshake::wipe_ephemeral() noexcept {
    detail::wipe(server_public_);
    detail::wipe(server_secret_);
}

void ServerHandshake::break_with(Error error) noexcept {
    error_ = error;
    stage_ = Stage::kBroken;
    wipe_ephemeral();
    detail::wipe(keys_.send);
    detail::wipe(keys_.receive);
    detail::wipe(hello_);
    detail::wipe(reply_);
}

std::size_t ServerHandshake::take(ByteView input) noexcept {
    const std::size_t room = kClientHelloBytes - filled_;
    const std::size_t take = input.size() < room ? input.size() : room;
    if (take == 0) return 0;
    const std::span<std::byte> dest = std::span{hello_}.subspan(filled_, take);
    std::memcpy(dest.data(), input.data(), take);
    filled_ += take;
    return take;
}

bool ServerHandshake::hello_ok() const noexcept {
    const ByteView label{hello_.data(), kLabelBytes};
    if (!std::ranges::equal(label, ByteView{kLabel})) return false;
    const ByteView version_bytes = std::span{hello_}.subspan(kLabelBytes, 2);
    return detail::read_u16(version_bytes) == kSecureVersion;
}

bool ServerHandshake::derive() noexcept {
    const detail::KeyPairOut pair{.public_key = server_public_, .secret = server_secret_};
    if (!detail::ephemeral_keypair(pair)) {
        error_ = Error::kRandom;
        return false;
    }
    std::memcpy(reply_.data(), server_public_.data(), server_public_.size());
    std::array<std::byte, kTranscriptBytes> transcript{};
    const ByteView client_key = std::span{hello_}.subspan(kLabelBytes + 2);
    fill_transcript(transcript, client_key, server_public_);
    const std::span<std::byte> signature = std::span{reply_}.subspan(kEphemeralBytes);
    const ByteView secret = identity_->secret_view();
    const detail::DetachedSign request{.signature = signature, .message = transcript, .secret = secret};
    if (!detail::sign_detached(request)) {
        error_ = Error::kRandom;
        return false;
    }
    // NOLINTNEXTLINE(modernize-use-designated-initializers): designated một dòng không vừa 120 cột
    const detail::Exchange exchange{keys_.receive, keys_.send, server_public_, server_secret_, client_key};
    if (!detail::session_server(exchange)) {
        error_ = Error::kAuthentication;
        return false;
    }
    stage_ = Stage::kDone;
    return true;
}

AbsorbResult ServerHandshake::absorb(ByteView input) noexcept {
    if (stage_ == Stage::kBroken) return std::unexpected(error_);
    if (stage_ != Stage::kCollect) return std::unexpected(Error::kState);
    const std::size_t consumed = take(input);
    if (filled_ != kClientHelloBytes) return Absorb{.consumed = consumed};
    if (!hello_ok()) {
        break_with(Error::kProtocol);
        return std::unexpected(error_);
    }
    if (!derive()) {
        break_with(error_);
        return std::unexpected(error_);
    }
    wipe_ephemeral();
    return Absorb{.consumed = consumed};
}

ByteView ServerHandshake::reply() const noexcept {
    if (stage_ != Stage::kDone) return {};
    return reply_;
}

SessionKeys ServerHandshake::take_keys() noexcept {
    core::check(stage_ == Stage::kDone, "chưa bắt tay xong");
    core::check(!keys_taken_, "khoá phiên đã được lấy");
    keys_taken_ = true;
    return std::move(keys_);
}

void ClientHandshake::wipe_secret() noexcept {
    detail::wipe(secret_);
}

ClientHandshake::~ClientHandshake() {
    wipe_secret();
}

ClientHandshake::ClientHandshake(ClientHandshake&& other) noexcept {
    *this = std::move(other);
}

ClientHandshake& ClientHandshake::operator=(ClientHandshake&& other) noexcept {
    if (this == &other) return *this;
    wipe_secret();
    public_ = other.public_;
    secret_ = other.secret_;
    hello_ = other.hello_;
    stage_ = other.stage_;
    other.wipe_secret();
    detail::wipe(other.public_);
    detail::wipe(other.hello_);
    other.stage_ = Stage::kMoved;
    return *this;
}

Result<ClientHandshake> ClientHandshake::begin() {
    ClientHandshake client;
    const detail::KeyPairOut pair{.public_key = client.public_, .secret = client.secret_};
    if (!detail::ephemeral_keypair(pair)) return std::unexpected(Error::kRandom);
    std::memcpy(client.hello_.data(), kLabel.data(), kLabel.size());
    detail::write_u16(std::span{client.hello_}.subspan(kLabelBytes), kSecureVersion);
    const std::span<std::byte> key = std::span{client.hello_}.subspan(kLabelBytes + 2);
    std::memcpy(key.data(), client.public_.data(), key.size());
    client.stage_ = Stage::kWait;
    return client;
}

ByteView ClientHandshake::hello() const noexcept {
    if (stage_ != Stage::kWait && stage_ != Stage::kFinished) return {};
    return hello_;
}

Result<SessionKeys> ClientHandshake::finish(ByteView reply, PublicKey pinned) noexcept {
    if (stage_ != Stage::kWait) return std::unexpected(Error::kState);
    if (reply.size() != kServerHelloBytes) {
        wipe_secret();
        stage_ = Stage::kFinished;
        return std::unexpected(Error::kProtocol);
    }
    std::array<std::byte, kTranscriptBytes> transcript{};
    const ByteView server_key = reply.first(kEphemeralBytes);
    fill_transcript(transcript, public_, server_key);
    const ByteView signature = reply.subspan(kEphemeralBytes);
    const detail::DetachedCheck check{.signature = signature, .message = transcript, .public_key = pinned.bytes};
    const bool signed_ok = detail::verify_detached(check);
    SessionKeys keys;
    // NOLINTNEXTLINE(modernize-use-designated-initializers): designated một dòng không vừa 120 cột
    const detail::Exchange exchange{keys.receive, keys.send, public_, secret_, server_key};
    const bool derived = signed_ok && detail::session_client(exchange);
    wipe_secret();
    stage_ = Stage::kFinished;
    if (!signed_ok) return std::unexpected(Error::kAuthentication);
    if (!derived) return std::unexpected(Error::kAuthentication);
    return keys;
}

} // namespace game::secure
