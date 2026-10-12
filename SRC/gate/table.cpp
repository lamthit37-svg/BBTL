// Bảng kết nối của gate. Mọi số lấy từ byte nhận được đều kiểm trước khi dùng.
#include "gate/table.hpp"

#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <iterator>
#include <memory>
#include <print>
#include <optional>
#include <span>
#include <variant>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::gate {
namespace {

constexpr std::uint8_t kIpEmpty = 0;
constexpr std::uint8_t kIpLive = 1;
constexpr std::uint8_t kIpTomb = 2;
constexpr std::size_t kFrameBytes = secure::kMaxPlainBytes;
constexpr int kRecordBudget = 8;

struct Slot {
    std::uint32_t generation = 1;
    bool live = false;
    bool greeted = false;
    bool draining = false;
    bool send_queued = false;
    bool resume_queued = false;
    Drop drain_as = Drop::kLogout;
    net::Ipv4 address{};
    std::int64_t born_ns = 0;
    std::int64_t seen_ns = 0;
    std::int64_t credit = 0;
    std::int64_t credit_ns = 0;
    std::optional<secure::ServerHandshake> handshake;
    std::optional<secure::RecordPipe> pipe;
    std::array<std::byte, kFrameBytes> frame{};
    std::size_t frame_at = 0;
    std::array<std::byte, kOutboxBytes> outbox{};
    std::size_t out_from = 0;
    std::size_t out_at = 0;
    std::array<std::byte, kHeldBytes> held{};
    std::size_t held_at = 0;
    std::vector<std::byte> scratch;
};

struct IpSlot {
    std::uint32_t address = 0;
    std::uint32_t count = 0;
    std::uint8_t state = kIpEmpty;
};

struct Probe {
    IpSlot* slot = nullptr;
    bool stop = false;
};

[[nodiscard]] std::uint32_t pack(net::Ipv4 address) noexcept {
    const auto first = static_cast<std::uint32_t>(address[0]) << 24U;
    const auto second = static_cast<std::uint32_t>(address[1]) << 16U;
    const auto third = static_cast<std::uint32_t>(address[2]) << 8U;
    return first | second | third | address[3];
}

[[nodiscard]] std::size_t pow2_at_least(std::size_t value) noexcept {
    std::size_t size = 1;
    while (size < value) size *= 2;
    return size;
}

[[nodiscard]] std::optional<unsigned> prefix_of(std::string_view text) noexcept {
    if (text.empty() || text.size() > 2) return std::nullopt;
    unsigned value = 0;
    const char* const first = text.data();
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): from_chars cần con trỏ cuối
    const char* const last = first + text.size();
    const auto parsed = std::from_chars(first, last, value);
    if (parsed.ec != std::errc{} || parsed.ptr != last) return std::nullopt;
    if (value > 32) return std::nullopt;
    return value;
}

[[nodiscard]] std::uint32_t mask_of(unsigned prefix) noexcept {
    if (prefix == 0) return 0;
    return ~std::uint32_t{0} << (32U - prefix);
}

} // namespace

struct Engine {
    Limits limits;
    std::vector<Cidr> allow;
    std::vector<Cidr> deny;
    const secure::Identity* identity = nullptr;
    std::vector<Slot> slots;
    std::vector<std::uint32_t> free_slots;
    std::vector<Handle> closed;
    std::vector<Handle> pending;
    std::size_t pending_from = 0;
    std::vector<Handle> resume;
    std::size_t resume_from = 0;
    std::vector<IpSlot> ips;
    std::array<std::uint64_t, static_cast<std::size_t>(Drop::kCount)> drops{};
    std::int64_t log_credit = 5 * static_cast<std::int64_t>(kMilli);
    std::int64_t log_ns = 0;
    std::size_t live = 0;
};

namespace {

// Ô và thời điểm luôn đi cùng nhau. Tham chiếu vì đây là ngữ cảnh, không phải sở hữu.
// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members)
struct SlotNow {
    Engine& state;
    Slot& slot;
    std::uint32_t index = 0;
    std::int64_t now = 0;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

void log_drop(Engine& state, Drop reason, net::Ipv4 address, std::int64_t now);

[[nodiscard]] bool listed(const std::vector<Cidr>& rows, std::uint32_t address) noexcept {
    const auto matches = [&](const Cidr& row) { return (address & row.mask) == row.network; };
    return std::ranges::any_of(rows, matches);
}

[[nodiscard]] bool address_ok(const Engine& state, net::Ipv4 address) noexcept {
    const std::uint32_t packed = pack(address);
    if (listed(state.deny, packed)) return false;
    if (state.allow.empty()) return true;
    return listed(state.allow, packed);
}

[[nodiscard]] Probe walk_ip(IpSlot& slot, std::uint32_t address, IpSlot*& tomb) noexcept {
    if (slot.state == kIpEmpty) {
        IpSlot* const chosen = tomb != nullptr ? tomb : &slot;
        return Probe{.slot = chosen, .stop = true};
    }
    if (slot.state == kIpTomb && tomb == nullptr) tomb = &slot;
    if (slot.state == kIpLive && slot.address == address) return Probe{.slot = &slot, .stop = true};
    return {};
}

[[nodiscard]] IpSlot* find_ip(Engine& state, std::uint32_t address) noexcept {
    const std::size_t mask = state.ips.size() - 1;
    const std::size_t start = (static_cast<std::size_t>(address) * 0x9E3779B1U) & mask;
    IpSlot* tomb = nullptr;
    std::size_t step = 0;
    bool done = false;
    IpSlot* found = nullptr;
    while (step < state.ips.size() && !done) {
        const Probe probe = walk_ip(state.ips[(start + step) & mask], address, tomb);
        found = probe.stop ? probe.slot : found;
        done = probe.stop;
        ++step;
    }
    return found;
}

[[nodiscard]] bool gain_ip(Engine& state, net::Ipv4 address) noexcept {
    IpSlot* slot = find_ip(state, pack(address));
    if (slot == nullptr) return false;
    if (slot->state == kIpLive && slot->count >= state.limits.per_ip) return false;
    if (slot->state != kIpLive) {
        slot->state = kIpLive;
        slot->address = pack(address);
        slot->count = 0;
    }
    ++slot->count;
    return true;
}

void lose_ip(Engine& state, net::Ipv4 address) noexcept {
    IpSlot* slot = find_ip(state, pack(address));
    if (slot == nullptr || slot->state != kIpLive) return;
    if (slot->count > 0) --slot->count;
    if (slot->count == 0) slot->state = kIpTomb;
}

[[nodiscard]] Slot* live_slot(Engine& state, Handle handle) noexcept {
    if (handle.index >= state.slots.size()) return nullptr;
    Slot& slot = state.slots[handle.index];
    if (!slot.live || slot.generation != handle.generation) return nullptr;
    return &slot;
}

void remember_closed(Engine& state, Handle handle) {
    if (state.closed.size() == state.closed.capacity()) return;
    state.closed.push_back(handle);
}

void release(Engine& state, Slot& slot, std::uint32_t index, Drop reason) {
    if (!slot.live) return;
    const Handle handle{.index = index, .generation = slot.generation};
    log_drop(state, reason, slot.address, slot.seen_ns);
    lose_ip(state, slot.address);
    slot.live = false;
    slot.greeted = false;
    slot.draining = false;
    slot.handshake.reset();
    slot.pipe.reset();
    slot.frame_at = 0;
    slot.out_from = 0;
    slot.out_at = 0;
    slot.held_at = 0;
    slot.send_queued = false;
    slot.resume_queued = false;
    ++slot.generation;
    if (slot.generation == 0) slot.generation = 1;
    if (state.live > 0) --state.live;
    state.free_slots.push_back(index);
    remember_closed(state, handle);
    const auto which = static_cast<std::size_t>(reason);
    if (which >= state.drops.size()) return;
    auto counter = state.drops.begin();
    std::advance(counter, static_cast<std::ptrdiff_t>(which));
    ++*counter;
}

[[nodiscard]] bool enqueue(Slot& slot, secure::ByteView bytes) noexcept {
    const std::size_t held = slot.out_at - slot.out_from;
    if (bytes.size() > slot.outbox.size() - held) return false;
    const bool shift = slot.out_from > 0 && slot.out_at + bytes.size() > slot.outbox.size();
    const std::span<std::byte> box{slot.outbox};
    if (shift) {
        auto last = box.begin();
        std::advance(last, static_cast<std::ptrdiff_t>(slot.out_from + held));
        const auto shift_by = static_cast<std::ptrdiff_t>(slot.out_from);
        std::shift_left(box.begin(), last, shift_by);
        slot.out_at = held;
        slot.out_from = 0;
    }
    const std::span<std::byte> dest = box.subspan(slot.out_at, bytes.size());
    std::ranges::copy(bytes, dest.begin());
    slot.out_at += bytes.size();
    return true;
}

void push_handle(std::vector<Handle>& queue, std::size_t& from, Handle handle) {
    if (from == queue.size()) {
        queue.clear();
        from = 0;
    }
    queue.push_back(handle);
}

void note_out(Engine& state, Slot& slot, std::uint32_t index) {
    if (slot.out_at == slot.out_from || slot.send_queued) return;
    const Handle handle{.index = index, .generation = slot.generation};
    push_handle(state.pending, state.pending_from, handle);
    slot.send_queued = true;
}

[[nodiscard]] bool seal_to(Engine& state, Slot& slot, std::uint32_t index, secure::ByteView plain) {
    if (!slot.pipe) return false;
    std::array<std::byte, secure::kMaxRecordBytes> record{};
    const secure::SealResult wrote = slot.pipe->seal(plain, record);
    if (!wrote) return false;
    const secure::ByteView sealed{record.data(), *wrote};
    if (!enqueue(slot, sealed)) return false;
    note_out(state, slot, index);
    return true;
}

void send_goodbye(Engine& state, Slot& slot, std::uint32_t index, protocol::DisconnectReason why, Drop reason) {
    if (!slot.pipe) {
        release(state, slot, index, reason);
        return;
    }
    slot.scratch.clear();
    protocol::Goodbye message;
    message.reason = why;
    if (!protocol::encode(slot.scratch, message)) {
        release(state, slot, index, reason);
        return;
    }
    if (!seal_to(state, slot, index, slot.scratch)) {
        release(state, slot, index, Drop::kSlow);
        return;
    }
    slot.draining = true;
    slot.drain_as = reason;
}

void on_hello(Engine& state, Slot& slot, std::uint32_t index, const protocol::Hello& hello, std::int64_t now) {
    if (slot.greeted) {
        send_goodbye(state, slot, index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    const bool too_old = hello.version < state.limits.min_version;
    const bool too_new = hello.version > protocol::kVersion;
    if (too_old || too_new) {
        send_goodbye(state, slot, index, protocol::DisconnectReason::kVersionMismatch, Drop::kVersion);
        return;
    }
    slot.greeted = true;
    slot.scratch.clear();
    protocol::Welcome welcome;
    welcome.version = protocol::kVersion;
    welcome.server_time = std::chrono::milliseconds{now / kNsPerMs};
    welcome.heartbeat = std::chrono::seconds{1};
    if (!protocol::encode(slot.scratch, welcome) || !seal_to(state, slot, index, slot.scratch)) {
        release(state, slot, index, Drop::kSlow);
    }
}

void on_ping(Engine& state, Slot& slot, std::uint32_t index, const protocol::Ping& ping, std::int64_t now) {
    if (!slot.greeted) {
        send_goodbye(state, slot, index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    slot.scratch.clear();
    protocol::Pong pong;
    pong.client_time = ping.client_time;
    pong.server_time = std::chrono::milliseconds{now / kNsPerMs};
    const bool encoded = protocol::encode(slot.scratch, pong).has_value();
    if (!encoded || !seal_to(state, slot, index, slot.scratch)) release(state, slot, index, Drop::kSlow);
}

void on_logout(Engine& state, Slot& slot, std::uint32_t index) {
    send_goodbye(state, slot, index, protocol::DisconnectReason::kLoggedOut, Drop::kLogout);
}

[[nodiscard]] bool spend(Slot& slot, const Limits& limits, std::int64_t now) noexcept {
    std::int64_t span = now - slot.credit_ns;
    if (span < 0) span = 0;
    const std::int64_t cap = limits.per_second * static_cast<std::int64_t>(kMilli);
    if (span >= kNsPerSecond) slot.credit = cap;
    if (span < kNsPerSecond) slot.credit = std::min(cap, slot.credit + limits.per_second * span / kNsPerMs);
    slot.credit_ns = now;
    constexpr std::int64_t kOneMessage = 1000;
    if (slot.credit < kOneMessage) return false;
    slot.credit -= kOneMessage;
    return true;
}

void dispatch(SlotNow in, protocol::Frame frame, secure::ByteView body) {
    if (!spend(in.slot, in.state.limits, in.now)) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kKicked, Drop::kRate);
        return;
    }
    const bool is_hello = frame.kind == protocol::Hello::kKind;
    const bool is_ping = frame.kind == protocol::Ping::kKind;
    const bool is_logout = frame.kind == protocol::Logout::kKind;
    if (!is_hello && !is_ping && !is_logout) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kProtocolViolation, Drop::kForeign);
        return;
    }
    const protocol::GameClientResult decoded = protocol::decode_game_client(frame, body);
    if (!decoded) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    if (const auto* hello = std::get_if<protocol::Hello>(&*decoded)) {
        on_hello(in.state, in.slot, in.index, *hello, in.now);
    }
    if (const auto* ping = std::get_if<protocol::Ping>(&*decoded)) on_ping(in.state, in.slot, in.index, *ping, in.now);
    if (std::get_if<protocol::Logout>(&*decoded) != nullptr) on_logout(in.state, in.slot, in.index);
}

[[nodiscard]] bool take_frame(Engine& state, Slot& slot, std::uint32_t index, std::int64_t now) {
    if (!slot.live || slot.frame_at < protocol::kHeaderBytes) return false;
    const secure::ByteView buffer{slot.frame.data(), slot.frame_at};
    const protocol::FrameResult peeked = protocol::peek_frame(buffer, state.limits.frame_bytes);
    if (!peeked) {
        release(state, slot, index, Drop::kFrame);
        return false;
    }
    if (!peeked->has_value()) return false;
    const protocol::Frame frame = **peeked;
    const std::size_t total = protocol::kHeaderBytes + frame.body_bytes;
    if (total > slot.frame_at) return false;
    const std::span<const std::byte> frame_bytes{slot.frame.data(), slot.frame_at};
    const secure::ByteView body = frame_bytes.subspan(protocol::kHeaderBytes, frame.body_bytes);
    const SlotNow in{.state = state, .slot = slot, .index = index, .now = now};
    dispatch(in, frame, body);
    if (!slot.live) return false;
    const std::size_t rest = slot.frame_at - total;
    auto end = slot.frame.begin();
    std::advance(end, static_cast<std::ptrdiff_t>(slot.frame_at));
    const auto drop = static_cast<std::ptrdiff_t>(total);
    std::shift_left(slot.frame.begin(), end, drop);
    slot.frame_at = rest;
    return slot.frame_at >= protocol::kHeaderBytes;
}

void drain_frames(Engine& state, Slot& slot, std::uint32_t index, std::int64_t now) {
    while (take_frame(state, slot, index, now)) {
    }
}

[[nodiscard]] secure::ByteView append_plain(SlotNow in, secure::ByteView plain) {
    const std::size_t room = in.slot.frame.size() - in.slot.frame_at;
    if (room == 0) {
        release(in.state, in.slot, in.index, Drop::kFrame);
        return {};
    }
    const std::size_t take = std::min(room, plain.size());
    const std::span<std::byte> dest = std::span{in.slot.frame}.subspan(in.slot.frame_at, take);
    std::copy_n(plain.begin(), take, dest.begin());
    in.slot.frame_at += take;
    drain_frames(in.state, in.slot, in.index, in.now);
    return plain.subspan(take);
}

void push_plain(Engine& state, Slot& slot, std::uint32_t index, secure::ByteView plain, std::int64_t now) {
    const SlotNow in{.state = state, .slot = slot, .index = index, .now = now};
    secure::ByteView rest = plain;
    while (!rest.empty() && slot.live) {
        rest = append_plain(in, rest);
    }
}

enum class Feed : std::uint8_t { kError, kNeedMore, kProgress };

struct Fed {
    Feed feed = Feed::kError;
    std::size_t consumed = 0;
};

[[nodiscard]] Fed open_record(SlotNow in, secure::ByteView rest) {
    if (!in.slot.pipe.has_value()) return {};
    std::array<std::byte, secure::kMaxPlainBytes> plain{};
    secure::RecordPipe& pipe = in.slot.pipe.value();
    const secure::OpenResult opened = pipe.open_bytes(rest, plain);
    if (!opened) {
        release(in.state, in.slot, in.index, Drop::kSecure);
        return {};
    }
    if (opened->consumed == 0) return Fed{.feed = Feed::kNeedMore};
    if (opened->written > 0) {
        const secure::ByteView body{plain.data(), opened->written};
        push_plain(in.state, in.slot, in.index, body, in.now);
    }
    return Fed{.feed = Feed::kProgress, .consumed = opened->consumed};
}

[[nodiscard]] bool must_resume(const Slot& slot) noexcept {
    if (slot.held_at < secure::kRecordHeaderBytes) return false;
    const std::span<const std::byte> header = std::span{slot.held}.first(secure::kRecordHeaderBytes);
    const auto low = static_cast<unsigned>(header.front());
    const auto high = static_cast<unsigned>(header.back()) << 8U;
    const auto body = static_cast<std::uint16_t>(low | high);
    const bool bad_body = body < secure::kTagBytes + 1 || body > secure::kMaxBodyBytes;
    if (bad_body) return true;
    return slot.held_at >= secure::kRecordHeaderBytes + body;
}

void note_resume(Engine& state, Slot& slot, std::uint32_t index) {
    if (slot.resume_queued || !slot.live || !must_resume(slot)) return;
    const Handle handle{.index = index, .generation = slot.generation};
    push_handle(state.resume, state.resume_from, handle);
    slot.resume_queued = true;
}

void keep_rest(Engine& state, Slot& slot, std::uint32_t index, secure::ByteView rest) {
    if (!slot.live || rest.empty()) return;
    if (rest.size() > slot.held.size()) {
        release(state, slot, index, Drop::kSecure);
        return;
    }
    std::copy_n(rest.begin(), rest.size(), slot.held.begin());
    slot.held_at = rest.size();
    note_resume(state, slot, index);
}

[[nodiscard]] bool open_more(SlotNow in, secure::ByteView& rest, int& budget) {
    if (rest.empty() || budget <= 0 || !in.slot.live || !in.slot.pipe) return false;
    const Fed fed = open_record(in, rest);
    if (fed.feed != Feed::kProgress) return false;
    rest = rest.subspan(fed.consumed);
    --budget;
    return true;
}

void feed_records(Engine& state, Slot& slot, std::uint32_t index, secure::ByteView bytes, std::int64_t now) {
    slot.resume_queued = false;
    if (slot.held_at > slot.held.size() || bytes.size() > slot.held.size() - slot.held_at) {
        release(state, slot, index, Drop::kSecure);
        return;
    }
    std::array<std::byte, kHeldBytes> combined{};
    const std::size_t held = slot.held_at;
    std::copy_n(slot.held.begin(), held, combined.begin());
    std::copy_n(bytes.begin(), bytes.size(), std::span{combined}.subspan(held).begin());
    slot.held_at = 0;
    secure::ByteView rest{combined.data(), held + bytes.size()};
    int budget = kRecordBudget;
    const SlotNow in{.state = state, .slot = slot, .index = index, .now = now};
    while (open_more(in, rest, budget)) {
    }
    keep_rest(state, slot, index, rest);
}

void open_pipe(SlotNow in, secure::ByteView bytes, std::size_t consumed) {
    if (!in.slot.handshake.has_value()) {
        release(in.state, in.slot, in.index, Drop::kSecure);
        return;
    }
    secure::ServerHandshake& handshake = in.slot.handshake.value();
    const secure::ByteView reply = handshake.reply();
    if (!enqueue(in.slot, reply)) {
        release(in.state, in.slot, in.index, Drop::kSlow);
        return;
    }
    note_out(in.state, in.slot, in.index);
    secure::SessionKeys keys = handshake.take_keys();
    in.slot.handshake.reset();
    in.slot.pipe.emplace(std::move(keys));
    if (consumed >= bytes.size()) return;
    feed_records(in.state, in.slot, in.index, bytes.subspan(consumed), in.now);
}

void finish_handshake(Engine& state, Slot& slot, std::uint32_t index, secure::ByteView bytes, std::int64_t now) {
    if (!slot.handshake.has_value()) {
        release(state, slot, index, Drop::kSecure);
        return;
    }
    secure::ServerHandshake& handshake = slot.handshake.value();
    const secure::AbsorbResult absorbed = handshake.absorb(bytes);
    slot.seen_ns = now;
    if (!absorbed) {
        release(state, slot, index, Drop::kSecure);
        return;
    }
    if (!handshake.is_done()) return;
    const SlotNow in{.state = state, .slot = slot, .index = index, .now = now};
    open_pipe(in, bytes, absorbed->consumed);
}

void log_drop(Engine& state, Drop reason, net::Ipv4 address, std::int64_t now) {
    std::int64_t span = now - state.log_ns;
    if (span < 0) span = 0;
    const std::int64_t cap = 5 * static_cast<std::int64_t>(kMilli);
    if (span >= kNsPerSecond) state.log_credit = cap;
    if (span < kNsPerSecond) state.log_credit = std::min(cap, state.log_credit + 5 * span / kNsPerMs);
    state.log_ns = now;
    constexpr std::int64_t kOneMessage = 1000;
    if (state.log_credit < kOneMessage) return;
    state.log_credit -= kOneMessage;
    const unsigned first = address[0];
    const unsigned second = address[1];
    const unsigned third = address[2];
    const unsigned fourth = address[3];
    const std::string_view why = describe(reason);
    std::println(stderr, "gate: ngắt {}.{}.{}.{} {}", first, second, third, fourth, why);
}

} // namespace

std::string_view describe(Drop reason) noexcept {
    switch (reason) {
    case Drop::kHandshake: return "hết hạn bắt tay";
    case Drop::kIdle: return "im lặng quá hạn";
    case Drop::kRate: return "vượt số tin mỗi giây";
    case Drop::kFrame: return "khung vượt trần";
    case Drop::kProtocol: return "tin sai giao thức";
    case Drop::kSecure: return "bản ghi bảo mật sai";
    case Drop::kFull: return "đầy kết nối";
    case Drop::kPerIp: return "đầy kết nối của một địa chỉ";
    case Drop::kDenied: return "địa chỉ bị chặn";
    case Drop::kSlow: return "đọc quá chậm";
    case Drop::kForeign: return "tin không thuộc mức phiên";
    case Drop::kVersion: return "phiên bản client quá thấp hoặc quá mới";
    case Drop::kLogout: return "client đóng phiên";
    case Drop::kClosed: return "bên kia đóng kết nối";
    case Drop::kStop: return "gate dừng";
    case Drop::kCount: return "lý do không rõ";
    }
    return "lý do không rõ";
}

std::optional<Cidr> parse_cidr(std::string_view text) {
    const auto slash = text.rfind('/');
    if (slash == std::string_view::npos || slash == 0) return std::nullopt;
    const std::optional<unsigned> prefix = prefix_of(text.substr(slash + 1));
    if (!prefix) return std::nullopt;
    const std::string endpoint = std::string{text.substr(0, slash)} + ":1";
    const net::NetResult<net::Endpoint> parsed = net::parse_endpoint(endpoint, net::ZeroPort::kRefuse);
    if (!parsed) return std::nullopt;
    const std::uint32_t mask = mask_of(*prefix);
    return Cidr{.network = pack(parsed->address) & mask, .mask = mask};
}

Table::Table(Limits limits, std::vector<Cidr> allow, std::vector<Cidr> deny, const secure::Identity& identity)
    : state_(std::make_unique<Engine>()) {
    state_->limits = limits;
    state_->allow = std::move(allow);
    state_->deny = std::move(deny);
    state_->identity = &identity;
    state_->slots.resize(limits.max_connections);
    state_->free_slots.reserve(limits.max_connections);
    state_->closed.reserve(limits.max_connections);
    const std::size_t queue_room = limits.max_connections + 256;
    state_->pending.reserve(queue_room);
    state_->resume.reserve(queue_room);
    for (std::uint32_t index = 0; index < limits.max_connections; ++index) {
        state_->slots[index].scratch.reserve(kScratchBytes);
        const auto from_end = static_cast<std::uint32_t>(limits.max_connections - 1);
        state_->free_slots.push_back(from_end - index);
    }
    const std::size_t ip_slots = pow2_at_least(std::max<std::size_t>(limits.max_connections * 2, 2));
    state_->ips.resize(ip_slots);
}

Table::~Table() = default;

Table::Table(Table&&) noexcept = default;

Table& Table::operator=(Table&&) noexcept = default;

Admit Table::admit(net::Ipv4 address, std::int64_t now) {
    if (state_->free_slots.empty()) return Admit{.code = AdmitCode::kFull};
    if (!address_ok(*state_, address)) return Admit{.code = AdmitCode::kDenied};
    if (!gain_ip(*state_, address)) return Admit{.code = AdmitCode::kPerIp};
    const std::uint32_t index = state_->free_slots.back();
    state_->free_slots.pop_back();
    Slot& slot = state_->slots[index];
    slot.live = true;
    slot.greeted = false;
    slot.draining = false;
    slot.address = address;
    slot.born_ns = now;
    slot.seen_ns = now;
    slot.credit_ns = now;
    slot.credit = state_->limits.per_second * static_cast<std::int64_t>(kMilli);
    slot.frame_at = 0;
    slot.out_from = 0;
    slot.out_at = 0;
    slot.held_at = 0;
    slot.send_queued = false;
    slot.resume_queued = false;
    slot.handshake.emplace(*state_->identity);
    slot.pipe.reset();
    ++state_->live;
    return Admit{.code = AdmitCode::kOk, .handle = Handle{.index = index, .generation = slot.generation}};
}

void Table::receive(Handle handle, secure::ByteView bytes, std::int64_t now) {
    Slot* slot = live_slot(*state_, handle);
    if (slot == nullptr) return;
    if (bytes.empty() && slot->held_at == 0) return;
    if (!bytes.empty()) slot->seen_ns = now;
    if (slot->handshake) {
        finish_handshake(*state_, *slot, handle.index, bytes, now);
        return;
    }
    if (slot->pipe) feed_records(*state_, *slot, handle.index, bytes, now);
}

secure::ByteView Table::outgoing(Handle handle) const noexcept {
    const Slot* slot = nullptr;
    if (handle.index < state_->slots.size()) slot = &state_->slots[handle.index];
    if (slot == nullptr || !slot->live || slot->generation != handle.generation) return {};
    const std::span<const std::byte> queued{slot->outbox};
    const std::size_t count = slot->out_at - slot->out_from;
    return queued.subspan(slot->out_from, count);
}

void Table::mark_sent(Handle handle, std::size_t count) {
    Slot* slot = live_slot(*state_, handle);
    if (slot == nullptr) return;
    const std::size_t held = slot->out_at - slot->out_from;
    const std::size_t sent = std::min(count, held);
    slot->out_from += sent;
    if (slot->out_from == slot->out_at) {
        slot->out_from = 0;
        slot->out_at = 0;
        slot->send_queued = false;
    }
    if (slot->draining && slot->out_at == slot->out_from) release(*state_, *slot, handle.index, slot->drain_as);
}

namespace {

struct TickAt {
    std::uint32_t index = 0;
    std::int64_t now = 0;
};

void clock_slot(Engine& state, TickAt at) {
    Slot& slot = state.slots[at.index];
    if (!slot.live) return;
    const bool handshake_late = slot.handshake.has_value() && at.now - slot.born_ns >= state.limits.handshake_ns;
    if (handshake_late) release(state, slot, at.index, Drop::kHandshake);
    if (!slot.live || !slot.pipe.has_value() || slot.draining) return;
    const bool idle_late = at.now - slot.seen_ns >= state.limits.idle_ns;
    if (idle_late) send_goodbye(state, slot, at.index, protocol::DisconnectReason::kIdle, Drop::kIdle);
}

void release_live(Engine& state, std::uint32_t index) {
    if (!state.slots[index].live) return;
    release(state, state.slots[index], index, Drop::kStop);
}

} // namespace

void Table::advance(std::int64_t now) {
    for (std::uint32_t index = 0; index < state_->slots.size(); ++index) {
        clock_slot(*state_, TickAt{.index = index, .now = now});
    }
}

void Table::close_all() {
    for (std::uint32_t index = 0; index < state_->slots.size(); ++index) {
        release_live(*state_, index);
    }
}

std::size_t Table::take_closed(std::span<Handle> out) {
    const std::size_t count = std::min(out.size(), state_->closed.size());
    std::copy_n(state_->closed.begin(), count, out.begin());
    state_->closed.erase(state_->closed.begin(), state_->closed.begin() + static_cast<std::ptrdiff_t>(count));
    return count;
}

std::size_t Table::live() const noexcept {
    return state_->live;
}

std::uint64_t Table::drops(Drop reason) const noexcept {
    const auto index = static_cast<std::size_t>(reason);
    if (index >= state_->drops.size()) return 0;
    auto counter = state_->drops.begin();
    std::advance(counter, static_cast<std::ptrdiff_t>(index));
    return *counter;
}

bool Table::is_live(Handle handle) const noexcept {
    if (handle.index >= state_->slots.size()) return false;
    const Slot& slot = state_->slots[handle.index];
    return slot.live && slot.generation == handle.generation;
}

std::size_t Table::scratch_capacity(Handle handle) const noexcept {
    if (!is_live(handle)) return 0;
    return state_->slots[handle.index].scratch.capacity();
}

bool Table::listening() const noexcept {
    return !state_->free_slots.empty();
}

void Table::drop(Handle handle, Drop reason) {
    Slot* slot = live_slot(*state_, handle);
    if (slot == nullptr) return;
    release(*state_, *slot, handle.index, reason);
}

std::size_t Table::read_room(Handle handle) const noexcept {
    if (!is_live(handle)) return 0;
    const Slot& slot = state_->slots[handle.index];
    if (slot.held_at > slot.held.size()) return 0;
    return slot.held.size() - slot.held_at;
}

namespace {

std::size_t take_queue(std::vector<Handle>& queue, std::size_t& from, std::span<Handle> out) {
    const std::size_t have = queue.size() - from;
    const std::size_t count = std::min(out.size(), have);
    const auto begin = queue.begin() + static_cast<std::ptrdiff_t>(from);
    std::copy_n(begin, count, out.begin());
    from += count;
    if (from == queue.size()) {
        queue.clear();
        from = 0;
    }
    return count;
}

} // namespace

std::size_t Table::take_pending(std::span<Handle> out) {
    return take_queue(state_->pending, state_->pending_from, out);
}

std::size_t Table::take_resume(std::span<Handle> out) {
    return take_queue(state_->resume, state_->resume_from, out);
}

} // namespace game::gate

