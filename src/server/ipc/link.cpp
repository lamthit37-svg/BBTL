#include "ipc/link.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <chrono>
#include <utility>

namespace game::ipc {
namespace {

constexpr std::size_t kHeadBytes = 4;
constexpr std::size_t kPlainHead = 2 + 8;
// Hộp kín của ipc_seal thêm 24 byte nonce và 16 byte nhãn quanh bản rõ.
constexpr std::size_t kBoxOverhead = 24 + 16;
constexpr std::size_t kBoxMin = kBoxOverhead + kPlainHead;
constexpr std::size_t kBoxMax = kBoxMin + kBodyMax;
constexpr std::size_t kReadChunk = std::size_t{16} * 1024;
constexpr std::uint64_t kConnectTag = 1;

void put_u32(std::vector<std::byte>& out, std::uint32_t value) {
    for (unsigned shift = 0; shift < 32; shift += 8) {
        out.push_back(static_cast<std::byte>((value >> shift) & 0xFFU));
    }
}

[[nodiscard]] std::uint32_t get_u32(std::span<const std::byte> bytes) noexcept {
    std::uint32_t value = 0;
    for (unsigned index = 0; index < 4; ++index) {
        value |= std::to_integer<std::uint32_t>(bytes[index]) << (8U * index);
    }
    return value;
}

} // namespace

Link::Link(net::TcpStream stream, secure::ByteView key) : stream_(std::move(stream)) {
    core::check(key.size() == kKeyBytes, "khoá ipc phải đúng 32 byte");
    std::ranges::copy(key, key_.begin());
}

Link::~Link() { wipe(); }

Link::Link(Link&& other) noexcept
    : stream_(std::move(other.stream_)), key_(other.key_), outbox_(std::move(other.outbox_)), sent_(other.sent_),
      raw_(std::move(other.raw_)), inbox_(std::move(other.inbox_)), inbox_from_(other.inbox_from_),
      state_(other.state_) {
    other.wipe();
    other.sent_ = 0;
    other.state_ = LinkState::kBroken;
}

Link& Link::operator=(Link&& other) noexcept {
    if (this == &other) return *this;
    wipe();
    stream_ = std::move(other.stream_);
    key_ = other.key_;
    outbox_ = std::move(other.outbox_);
    sent_ = other.sent_;
    raw_ = std::move(other.raw_);
    inbox_ = std::move(other.inbox_);
    inbox_from_ = other.inbox_from_;
    state_ = other.state_;
    other.wipe();
    other.sent_ = 0;
    other.state_ = LinkState::kBroken;
    return *this;
}

void Link::wipe() noexcept {
    secure::wipe_bytes(key_);
    // Khung chưa lấy có thể mang tin riêng của người chơi: không để lại trong bộ nhớ đã trả.
    secure::wipe_bytes(raw_);
    raw_.clear();
    outbox_.clear();
    inbox_.clear();
    inbox_from_ = 0;
}

std::optional<Link> Link::connect(net::Endpoint target, secure::ByteView key, net::Milliseconds limit) {
    net::NetResult<net::TcpStream> began = net::TcpStream::begin_connect(target);
    if (!began) return std::nullopt;
    net::TcpStream stream = std::move(*began);
    net::PollSet poll;
    if (!poll.add(stream.handle(), kConnectTag)) return std::nullopt;
    poll.want_write(kConnectTag, true);
    const auto deadline = std::chrono::steady_clock::now() + limit;
    for (;;) {
        const net::NetResult<bool> done = stream.finish_connect();
        if (!done) return std::nullopt;
        if (*done) return Link(std::move(stream), key);
        const auto left = std::chrono::duration_cast<net::Milliseconds>(deadline - std::chrono::steady_clock::now());
        if (left.count() <= 0) return std::nullopt;
        net::PollEvents events;
        if (!poll.wait(left, events)) return std::nullopt;
    }
}

bool Link::send(std::uint16_t kind, std::uint64_t session, std::span<const std::byte> body) {
    if (state_ != LinkState::kUp || body.size() > kBodyMax) return false;
    std::vector<std::byte> plain;
    plain.reserve(kPlainHead + body.size());
    plain.push_back(static_cast<std::byte>(kind & 0xFFU));
    plain.push_back(static_cast<std::byte>(kind >> 8U));
    for (unsigned shift = 0; shift < 64; shift += 8) {
        plain.push_back(static_cast<std::byte>((session >> shift) & 0xFFU));
    }
    plain.insert(plain.end(), body.begin(), body.end());
    const std::size_t framed = kHeadBytes + kBoxOverhead + plain.size();
    if ((outbox_.size() - sent_) + framed > kOutboxMax) {
        secure::wipe_bytes(plain);
        return false;
    }
    std::optional<std::vector<std::byte>> boxed = secure::ipc_seal(key_, plain);
    secure::wipe_bytes(plain);
    if (!boxed) return false;
    put_u32(outbox_, static_cast<std::uint32_t>(boxed->size()));
    outbox_.insert(outbox_.end(), boxed->begin(), boxed->end());
    return true;
}

LinkState Link::write_out() {
    while (sent_ < outbox_.size()) {
        const std::span<const std::byte> rest = std::span<const std::byte>{outbox_}.subspan(sent_);
        const net::NetResult<std::size_t> wrote = stream_.send(rest);
        if (!wrote) return LinkState::kBroken;
        if (*wrote == 0) return LinkState::kUp;
        sent_ += *wrote;
    }
    outbox_.clear();
    sent_ = 0;
    return LinkState::kUp;
}

bool Link::split_frames() {
    std::size_t offset = 0;
    bool healthy = true;
    while (healthy && queued_frames() < kInboxMax && raw_.size() - offset >= kHeadBytes) {
        const std::span<const std::byte> view = std::span<const std::byte>{raw_}.subspan(offset);
        const std::uint32_t size = get_u32(view);
        if (size < kBoxMin || size > kBoxMax) {
            healthy = false;
            break;
        }
        if (view.size() < kHeadBytes + size) break;
        std::optional<std::vector<std::byte>> plain = secure::ipc_open(key_, view.subspan(kHeadBytes, size));
        if (!plain || plain->size() < kPlainHead) {
            healthy = false;
            break;
        }
        Frame frame;
        frame.kind = static_cast<std::uint16_t>(std::to_integer<unsigned>((*plain)[0]) |
            (std::to_integer<unsigned>((*plain)[1]) << 8U));
        for (unsigned index = 0; index < 8; ++index) {
            frame.session |= std::to_integer<std::uint64_t>((*plain)[2 + index]) << (8U * index);
        }
        frame.body.assign(plain->begin() + static_cast<std::ptrdiff_t>(kPlainHead), plain->end());
        secure::wipe_bytes(*plain);
        inbox_.push_back(std::move(frame));
        offset += kHeadBytes + size;
    }
    if (offset > 0) {
        secure::wipe_bytes(std::span<std::byte>{raw_}.first(offset));
        raw_.erase(raw_.begin(), raw_.begin() + static_cast<std::ptrdiff_t>(offset));
    }
    return healthy;
}

LinkState Link::read_in() {
    std::array<std::byte, kReadChunk> chunk{};
    LinkState outcome = LinkState::kUp;
    // Đọc tới khi socket hết byte hoặc hàng nhận đầy; chừa chỗ cho đúng một khung lớn nhất đang dở.
    while (queued_frames() < kInboxMax && raw_.size() < kHeadBytes + kBoxMax + kReadChunk) {
        const net::NetResult<std::size_t> got = stream_.receive(chunk);
        if (!got) {
            outcome = got.error() == net::NetError::kClosed ? LinkState::kClosed : LinkState::kBroken;
            break;
        }
        if (*got == 0) break;
        raw_.insert(raw_.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(*got));
        if (!split_frames()) return LinkState::kBroken;
    }
    secure::wipe_bytes(chunk);
    // Byte đã đọc trước khi bên kia đóng vẫn có thể là khung đủ: tách lần cuối rồi mới báo đóng.
    if (outcome != LinkState::kUp && !split_frames()) return LinkState::kBroken;
    return outcome;
}

LinkState Link::pump() {
    if (state_ != LinkState::kUp) return state_;
    LinkState written = write_out();
    if (written == LinkState::kBroken) {
        state_ = LinkState::kBroken;
        return state_;
    }
    const LinkState read = read_in();
    if (read != LinkState::kUp) state_ = read;
    return state_;
}

std::optional<Frame> Link::next() {
    if (inbox_from_ == inbox_.size()) return std::nullopt;
    Frame frame = std::move(inbox_[inbox_from_]);
    ++inbox_from_;
    if (inbox_from_ == inbox_.size()) {
        inbox_.clear();
        inbox_from_ = 0;
    } else if (inbox_from_ >= kInboxMax) {
        // Người đọc chậm hơn người ghi: bỏ phần đã lấy để vector không phình theo thời gian.
        inbox_.erase(inbox_.begin(), inbox_.begin() + static_cast<std::ptrdiff_t>(inbox_from_));
        inbox_from_ = 0;
    }
    return frame;
}

} // namespace game::ipc
