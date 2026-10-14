// Bảng kết nối của gate. Mọi số lấy từ byte nhận được đều kiểm trước khi dùng.
#include "gate/table.hpp"

#include "gate/motion.hpp"

#include "account/realm.hpp"
#include "net/net.hpp"
#include "net/shard.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <format>
#include <iterator>
#include <limits>
#include <memory>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <unordered_map>
#include <utility>
#include <variant>
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
    // Đang chờ thư ký trả lời một câu hỏi auth/store; câu hỏi kế bị từ chối kBusy.
    bool asking = false;
    // Đã vào nhân vật: giữ khoá phiên để Resume tìm lại sau khi rớt mạng.
    bool has_session = false;
    std::uint64_t session_key = 0;
    // Vị trí server làm chủ; chỉ có mốc sau khi vào game (docs/SERVER-DI-CHUYEN.md).
    Motion motion;
    // Resume đang chờ store: mốc cuối của phiên cũ (do server đặt/nhận), dùng thay điểm trong store.
    bool has_resume_spot = false;
    guard::Anchor resume_spot{};
    Drop drain_as = Drop::kLogout;
    Door door = Door::kGame;
    bool has_account = false;
    bool has_cap = false;
    std::uint64_t account_id = 0;
    std::array<std::byte, account::kCapBytes> cap{};
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
    while (size < value)
        size *= 2;
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

// Câu hỏi luồng tick gửi thư ký. secret là mật khẩu hoặc vé hex, xoá ngay sau khi dùng.
enum class AskKind : std::uint8_t {
    kCreateAccount,
    kSignIn,
    kLogin,
    kCreateCharacter,
    kDeleteCharacter,
    kEnter,
    kResume
};

struct Ask {
    Handle handle{};
    AskKind kind = AskKind::kLogin;
    std::string account;
    std::string secret;
    std::string ip;
    std::array<std::byte, account::kCapBytes> cap{};
    protocol::CreateCharacter create{};
    std::uint64_t character = 0;
};

struct Answer {
    Handle handle{};
    AskKind kind = AskKind::kLogin;
    std::uint64_t character = 0;
    account::TicketReply ticket{};
    account::RosterReply roster{};
    account::EnterReply enter{};
};

// Auth băm Argon2id trên một luồng database, nên hàng sâu hơn chỉ làm client chờ lâu hơn trước
// khi nhận kBusy.
constexpr std::size_t kAskRoom = 64;

// Phiên đã vào game. Gate chỉ giữ SHA-256 của token SessionStart; token dùng một lần và đổi mới
// sau mỗi Resume. Rớt mạng (idle, chậm, đóng) thì phiên chờ kResumeGraceNs; Logout hay vi phạm
// thì xoá ngay. Resume vẫn hỏi store enter, nên ban, cap hết hạn hay nhân vật đã xoá vẫn chặn.
// Gate khởi động lại là mất mọi phiên: client đăng nhập lại.
// Token gắn với IP đã vào game (limits.resume_bind_ip, mặc định bật): Resume từ IP khác là token bị
// lộ, phiên bị huỷ ngay (kể cả khi chủ còn nối) và client phải đăng nhập lại. Đổi mạng (Wi-Fi sang 4G)
// cũng phải đăng nhập lại: chấp nhận. Thời gian chờ là limits.resume_grace_ns (gate.toml [resume]).
constexpr std::size_t kSessionDigestBytes = 32;

struct Session {
    std::array<std::byte, kSessionDigestBytes> digest{};
    std::uint64_t account = 0;
    std::array<std::byte, account::kCapBytes> cap{};
    std::uint64_t character = 0;
    net::Ipv4 address{};
    bool owned = false;
    Handle owner{};
    std::int64_t expires_ns = 0;
    // Mốc cuối server nhận được lúc phiên rớt; store chưa lưu vị trí giữa phiên.
    bool has_spot = false;
    guard::Anchor spot{};
};

} // namespace

struct Engine {
    Limits limits;
    std::vector<Cidr> allow;
    std::vector<Cidr> deny;
    const secure::Identity* identity = nullptr;
    std::vector<Slot> slots;
    // Mốc sớm nhất một ô có thể tới hạn bắt tay hoặc idle, xếp liền nhau để advance() chỉ quét 8 byte
    // mỗi ô thay vì chạm vào Slot (hàng chục KB, nhiều lần trượt cache mỗi ô). Mốc chỉ được sớm hơn
    // hạn thật: seen_ns chỉ tiến, nên mốc cũ luôn sớm hơn hoặc bằng; tới mốc thì kiểm thật rồi tính lại.
    std::vector<std::int64_t> due;
    std::vector<std::uint32_t> free_slots;
    std::vector<Handle> closed;
    // Lane 0: bắt tay, ưu tiên chặt. Lane 1: gói nhỏ. Lane 2: gói lớn, trọng số 1 so với 4.
    net::LaneQueue<Handle> pending;
    std::vector<Handle> resume;
    std::size_t resume_from = 0;
    std::vector<IpSlot> ips;
    std::array<std::uint64_t, static_cast<std::size_t>(Drop::kCount)> drops{};
    std::int64_t log_credit = 5 * static_cast<std::int64_t>(kMilli);
    std::int64_t log_ns = 0;
    std::size_t live = 0;
    std::optional<account::Realm> realm;
    // Khoá là 8 byte đầu của digest; so khớp cả 32 byte bằng phép so thời gian hằng.
    std::unordered_map<std::uint64_t, Session> sessions;
    // Luồng tick đẩy asks và lấy answers; luồng thư ký làm ngược lại. Mỗi hàng đúng một bên đẩy.
    net::SpscMail<Ask, kAskRoom> asks;
    net::SpscMail<Answer, kAskRoom> answers;
    std::atomic<bool> clerk_stop{false};
    std::jthread clerk;

    Engine() = default;
    Engine(const Engine&) = delete;
    Engine& operator=(const Engine&) = delete;
    Engine(Engine&&) = delete;
    Engine& operator=(Engine&&) = delete;
    ~Engine();
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

// Khoá đếm per_ip: địa chỉ cắt về dải /per_ip_prefix, để nhiều IP trong một dải chung một trần.
[[nodiscard]] std::uint32_t ip_key(const Engine& state, net::Ipv4 address) noexcept {
    const std::uint32_t prefix = std::clamp<std::uint32_t>(state.limits.per_ip_prefix, 1, 32);
    const std::uint32_t mask = prefix >= 32 ? 0xFFFFFFFFU : ~(0xFFFFFFFFU >> prefix);
    return pack(address) & mask;
}

[[nodiscard]] bool gain_ip(Engine& state, net::Ipv4 address) noexcept {
    IpSlot* slot = find_ip(state, ip_key(state, address));
    if (slot == nullptr) return false;
    if (slot->state == kIpLive && slot->count >= state.limits.per_ip) return false;
    if (slot->state != kIpLive) {
        slot->state = kIpLive;
        slot->address = ip_key(state, address);
        slot->count = 0;
    }
    ++slot->count;
    return true;
}

void lose_ip(Engine& state, net::Ipv4 address) noexcept {
    IpSlot* slot = find_ip(state, ip_key(state, address));
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

void release_session(Engine& state, Slot& slot, Drop reason);

void release(Engine& state, Slot& slot, std::uint32_t index, Drop reason) {
    if (!slot.live) return;
    const Handle handle{.index = index, .generation = slot.generation};
    release_session(state, slot, reason);
    log_drop(state, reason, slot.address, slot.seen_ns);
    lose_ip(state, slot.address);
    slot.live = false;
    slot.greeted = false;
    slot.has_account = false;
    slot.has_cap = false;
    slot.account_id = 0;
    slot.cap = {};
    slot.motion.clear();
    slot.has_resume_spot = false;
    slot.resume_spot = {};
    slot.door = Door::kGame;
    slot.draining = false;
    slot.handshake.reset();
    slot.pipe.reset();
    slot.frame_at = 0;
    slot.out_from = 0;
    slot.out_at = 0;
    slot.held_at = 0;
    slot.send_queued = false;
    slot.resume_queued = false;
    slot.asking = false;
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

constexpr std::size_t kLoginLane = 0;
constexpr std::size_t kControlLane = 1;
constexpr std::size_t kBulkLane = 2;
constexpr std::size_t kControlBytes = 64;

// Bắt tay đi trước. Trong phiên, gói ngắn (điều khiển) được bốn suất rồi mới tới gói dài.
[[nodiscard]] std::size_t send_lane(const Slot& slot) noexcept {
    if (!slot.pipe) return kLoginLane;
    const std::size_t held = slot.out_at - slot.out_from;
    if (held <= kControlBytes) return kControlLane;
    return kBulkLane;
}

void note_out(Engine& state, Slot& slot, std::uint32_t index) {
    if (slot.out_at == slot.out_from || slot.send_queued) return;
    const Handle handle{.index = index, .generation = slot.generation};
    state.pending.push(send_lane(slot), handle);
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

void forget(std::string& secret) {
    secure::wipe_bytes(std::as_writable_bytes(std::span{secret.data(), secret.size()}));
    secret.clear();
}

[[nodiscard]] std::string ip_text(net::Ipv4 address) {
    return std::format("{}.{}.{}.{}", address[0], address[1], address[2], address[3]);
}

void send_reject(Engine& state, Slot& slot, std::uint32_t index, std::uint16_t request, protocol::ErrorCode code) {
    slot.scratch.clear();
    protocol::Reject message;
    message.request = request;
    message.code = code;
    const bool encoded = protocol::encode(slot.scratch, message).has_value();
    if (!encoded || !seal_to(state, slot, index, slot.scratch)) release(state, slot, index, Drop::kSlow);
}

void send_position(Engine& state, Slot& slot, std::uint32_t index, const protocol::Position& position) {
    slot.scratch.clear();
    const bool encoded = protocol::encode(slot.scratch, position).has_value();
    if (!encoded || !seal_to(state, slot, index, slot.scratch)) release(state, slot, index, Drop::kSlow);
}

void send_roster(Engine& state, Slot& slot, std::uint32_t index, const account::RosterReply& roster) {
    if (!roster.ok) {
        send_reject(state, slot, index, protocol::Login::kKind, roster.code);
        return;
    }
    slot.scratch.clear();
    protocol::CharacterList message;
    message.characters = roster.characters;
    const bool encoded = protocol::encode(slot.scratch, message).has_value();
    if (!encoded || !seal_to(state, slot, index, slot.scratch)) release(state, slot, index, Drop::kSlow);
}

void wipe_ask(Ask& ask) noexcept {
    forget(ask.secret);
    secure::wipe_bytes(ask.cap);
}

void wipe_answer(Answer& answer) noexcept {
    secure::wipe_bytes(answer.ticket.token);
    secure::wipe_bytes(answer.roster.cap);
}

// Gửi câu hỏi cho thư ký. Hàng đầy thì client nhận kBusy ngay, không có câu hỏi nào bị nuốt.
void post_ask(Engine& state, Slot& slot, std::uint32_t index, Ask& ask, std::uint16_t request) {
    ask.handle = Handle{.index = index, .generation = slot.generation};
    if (state.asks.try_push(ask)) {
        slot.asking = true;
        return;
    }
    wipe_ask(ask);
    send_reject(state, slot, index, request, protocol::ErrorCode::kBusy);
}

[[nodiscard]] bool may_ask(Engine& state, Slot& slot, std::uint32_t index, std::uint16_t request) {
    if (!slot.asking) return true;
    send_reject(state, slot, index, request, protocol::ErrorCode::kBusy);
    return false;
}

void on_login(Engine& state, Slot& slot, std::uint32_t index, protocol::Login& login) {
    if (!slot.greeted) {
        send_goodbye(state, slot, index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    if (!state.realm.has_value()) {
        forget(login.ticket);
        send_reject(state, slot, index, protocol::Login::kKind, protocol::ErrorCode::kBusy);
        return;
    }
    if (!may_ask(state, slot, index, protocol::Login::kKind)) {
        forget(login.ticket);
        return;
    }
    Ask ask;
    ask.kind = AskKind::kLogin;
    ask.account = login.account;
    ask.secret = login.ticket;
    forget(login.ticket);
    post_ask(state, slot, index, ask, protocol::Login::kKind);
}

void on_create_character(Engine& state, Slot& slot, std::uint32_t index, const protocol::CreateCharacter& request) {
    if (!slot.greeted) {
        send_goodbye(state, slot, index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    if (!slot.has_cap || !state.realm.has_value()) {
        send_reject(state, slot, index, protocol::CreateCharacter::kKind, protocol::ErrorCode::kNotAuthenticated);
        return;
    }
    if (!may_ask(state, slot, index, protocol::CreateCharacter::kKind)) return;
    Ask ask;
    ask.kind = AskKind::kCreateCharacter;
    ask.cap = slot.cap;
    ask.create = request;
    post_ask(state, slot, index, ask, protocol::CreateCharacter::kKind);
}

void on_delete_character(Engine& state, Slot& slot, std::uint32_t index, const protocol::DeleteCharacter& request) {
    if (!slot.greeted || !slot.has_cap || !state.realm.has_value()) {
        send_reject(state, slot, index, protocol::DeleteCharacter::kKind, protocol::ErrorCode::kNotAuthenticated);
        return;
    }
    if (!may_ask(state, slot, index, protocol::DeleteCharacter::kKind)) return;
    Ask ask;
    ask.kind = AskKind::kDeleteCharacter;
    ask.cap = slot.cap;
    ask.character = request.character;
    post_ask(state, slot, index, ask, protocol::DeleteCharacter::kKind);
}

void on_enter(Engine& state, Slot& slot, std::uint32_t index, const protocol::EnterGame& request) {
    if (!slot.greeted || !slot.has_cap || !state.realm.has_value()) {
        send_reject(state, slot, index, protocol::EnterGame::kKind, protocol::ErrorCode::kNotAuthenticated);
        return;
    }
    if (!may_ask(state, slot, index, protocol::EnterGame::kKind)) return;
    Ask ask;
    ask.kind = AskKind::kEnter;
    ask.cap = slot.cap;
    ask.character = request.character;
    post_ask(state, slot, index, ask, protocol::EnterGame::kKind);
}

void finish_login(Engine& state, Slot& slot, std::uint32_t index, const account::RosterReply& roster) {
    if (!roster.ok) {
        send_reject(state, slot, index, protocol::Login::kKind, roster.code);
        return;
    }
    slot.has_account = roster.has_cap;
    slot.has_cap = roster.has_cap;
    slot.account_id = roster.account;
    slot.cap = roster.cap;
    send_roster(state, slot, index, roster);
}

void finish_roster(Engine& state, Slot& slot, std::uint32_t index, std::uint16_t request,
    const account::RosterReply& roster) {
    if (!roster.ok) {
        send_reject(state, slot, index, request, roster.code);
        return;
    }
    send_roster(state, slot, index, roster);
}

[[nodiscard]] std::uint64_t key_of(const std::array<std::byte, kSessionDigestBytes>& digest) noexcept {
    std::uint64_t key = 0;
    for (std::size_t at = 0; at < sizeof(key); ++at) {
        key |= static_cast<std::uint64_t>(static_cast<unsigned>(digest[at])) << (8U * at);
    }
    return key;
}

[[nodiscard]] bool same_digest(const std::array<std::byte, kSessionDigestBytes>& left,
    const std::array<std::byte, kSessionDigestBytes>& right) noexcept {
    unsigned diff = 0;
    for (std::size_t at = 0; at < kSessionDigestBytes; ++at) {
        diff |= static_cast<unsigned>(left[at] ^ right[at]);
    }
    return diff == 0;
}

void erase_session(Engine& state, std::unordered_map<std::uint64_t, Session>::iterator found) {
    secure::wipe_bytes(found->second.cap);
    secure::wipe_bytes(found->second.digest);
    state.sessions.erase(found);
}

void forget_session(Engine& state, Slot& slot) {
    if (!slot.has_session) return;
    const auto found = state.sessions.find(slot.session_key);
    if (found != state.sessions.end()) erase_session(state, found);
    slot.has_session = false;
    slot.session_key = 0;
}

[[nodiscard]] bool parks_on(Drop reason) noexcept {
    return reason == Drop::kIdle || reason == Drop::kSlow || reason == Drop::kClosed;
}

void release_session(Engine& state, Slot& slot, Drop reason) {
    if (!slot.has_session) return;
    const auto found = state.sessions.find(slot.session_key);
    if (found == state.sessions.end() || !parks_on(reason)) {
        forget_session(state, slot);
        return;
    }
    found->second.owned = false;
    found->second.owner = {};
    if (slot.motion.placed()) {
        found->second.has_spot = true;
        found->second.spot = slot.motion.anchor();
    }
    found->second.expires_ns = slot.seen_ns + state.limits.resume_grace_ns;
    slot.has_session = false;
    slot.session_key = 0;
}

[[nodiscard]] std::size_t session_room(const Engine& state) noexcept {
    return std::max<std::size_t>(64, state.limits.max_connections * 2);
}

void prune_sessions(Engine& state, std::int64_t now) {
    for (auto row = state.sessions.begin(); row != state.sessions.end();) {
        const bool stale = !row->second.owned && now >= row->second.expires_ns;
        if (!stale) {
            ++row;
            continue;
        }
        secure::wipe_bytes(row->second.cap);
        row = state.sessions.erase(row);
    }
}

// Cấp token mới và nhớ digest. Không nhớ được (đầy, trùng khoá) thì token vẫn gửi nhưng Resume
// sẽ nhận kNoSession: client chỉ mất khả năng nối lại, không mất phiên đang chạy.
[[nodiscard]] bool open_session(Engine& state, Slot& slot, std::uint32_t index, std::uint64_t character,
    std::span<std::byte, protocol::kSessionStartTokenBytes> token) {
    forget_session(state, slot);
    if (!secure::fill_random(token)) return false;
    Session session;
    if (!secure::sha256(token, session.digest)) return false;
    const std::uint64_t key = key_of(session.digest);
    if (state.sessions.size() >= session_room(state)) prune_sessions(state, slot.seen_ns);
    if (state.sessions.size() >= session_room(state) || state.sessions.contains(key)) return true;
    session.account = slot.account_id;
    session.cap = slot.cap;
    session.character = character;
    session.address = slot.address;
    session.owned = true;
    session.owner = Handle{.index = index, .generation = slot.generation};
    state.sessions.emplace(key, session);
    secure::wipe_bytes(session.cap);
    slot.has_session = true;
    slot.session_key = key;
    return true;
}

void on_resume(Engine& state, Slot& slot, std::uint32_t index, const protocol::Resume& request, std::int64_t now) {
    if (!slot.greeted) {
        send_goodbye(state, slot, index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    if (slot.has_account) {
        send_reject(state, slot, index, protocol::Resume::kKind, protocol::ErrorCode::kOutOfOrder);
        return;
    }
    if (!state.realm.has_value()) {
        send_reject(state, slot, index, protocol::Resume::kKind, protocol::ErrorCode::kBusy);
        return;
    }
    if (!may_ask(state, slot, index, protocol::Resume::kKind)) return;
    std::array<std::byte, kSessionDigestBytes> digest{};
    if (!secure::sha256(request.token, digest)) {
        send_reject(state, slot, index, protocol::Resume::kKind, protocol::ErrorCode::kBusy);
        return;
    }
    const auto found = state.sessions.find(key_of(digest));
    if (found == state.sessions.end() || !same_digest(found->second.digest, digest)) {
        send_reject(state, slot, index, protocol::Resume::kKind, protocol::ErrorCode::kNoSession);
        return;
    }
    if (!found->second.owned && now >= found->second.expires_ns) {
        erase_session(state, found);
        send_reject(state, slot, index, protocol::Resume::kKind, protocol::ErrorCode::kSessionExpired);
        return;
    }
    if (state.limits.resume_bind_ip && found->second.address != slot.address) {
        // Token đúng nhưng từ IP khác: coi như lộ. Huỷ phiên để kẻ lấy token không thử lại được; chủ
        // đang nối vẫn chơi tiếp nhưng mất quyền Resume. Trả cùng mã như token lạ, không lộ gì thêm.
        if (found->second.owned) {
            Slot* owner = live_slot(state, found->second.owner);
            if (owner != nullptr) {
                owner->has_session = false;
                owner->session_key = 0;
            }
        }
        erase_session(state, found);
        send_reject(state, slot, index, protocol::Resume::kKind, protocol::ErrorCode::kNoSession);
        return;
    }
    Ask ask;
    ask.kind = AskKind::kResume;
    ask.cap = found->second.cap;
    ask.character = found->second.character;
    post_ask(state, slot, index, ask, protocol::Resume::kKind);
    if (!slot.asking) return;
    // Câu hỏi đã đi: token cũ hết giá trị dù store trả lời thế nào. Kết nối cũ còn sống thì bị đẩy ra.
    slot.has_resume_spot = found->second.has_spot;
    slot.resume_spot = found->second.spot;
    if (found->second.owned) {
        const Handle owner = found->second.owner;
        Slot* old = live_slot(state, owner);
        if (old != nullptr) {
            if (old->motion.placed()) {
                slot.has_resume_spot = true;
                slot.resume_spot = old->motion.anchor();
            }
            old->has_session = false;
            old->session_key = 0;
            send_goodbye(state, *old, owner.index, protocol::DisconnectReason::kLoginElsewhere, Drop::kLogout);
        }
    }
    slot.has_account = true;
    slot.has_cap = true;
    slot.account_id = found->second.account;
    slot.cap = found->second.cap;
    erase_session(state, found);
}

// Mốc đầu do server đặt: Resume giữ mốc cuối của phiên cũ; còn lại lấy điểm store giữ cho nhân vật.
// Client không bao giờ chọn mốc (docs/SERVER-DI-CHUYEN.md).
[[nodiscard]] guard::Anchor entry_anchor(const account::EnterReply& entered, bool resumed,
    guard::Anchor kept) noexcept {
    if (resumed) return kept;
    return guard::Anchor{.x_cm = entered.x_cm, .z_cm = entered.z_cm};
}

void finish_enter(Engine& state, Slot& slot, std::uint32_t index, std::uint16_t request, std::uint64_t character,
    const account::EnterReply& entered) {
    const bool resumed_spot = request == protocol::Resume::kKind && slot.has_resume_spot;
    const guard::Anchor resume_spot = slot.resume_spot;
    slot.has_resume_spot = false;
    slot.resume_spot = {};
    if (!entered.ok) {
        if (request == protocol::Resume::kKind) {
            forget_session(state, slot);
            slot.has_account = false;
            slot.has_cap = false;
            slot.account_id = 0;
            secure::wipe_bytes(slot.cap);
        }
        send_reject(state, slot, index, request, entered.code);
        return;
    }
    slot.scratch.clear();
    protocol::SessionStart session;
    const bool opened = open_session(state, slot, index, character, session.token);
    const bool sent =
        opened && protocol::encode(slot.scratch, session).has_value() && seal_to(state, slot, index, slot.scratch);
    secure::wipe_bytes(session.token);
    if (!sent) {
        release(state, slot, index, Drop::kSlow);
        return;
    }
    send_position(state, slot, index,
        slot.motion.place(entry_anchor(entered, resumed_spot, resume_spot), slot.seen_ns));
}

// Mọi Move đi qua guard::Pace với đồng hồ của gate. Không nhận thì kéo về mốc; lặp lại thì đóng phiên.
void on_move(Engine& state, Slot& slot, std::uint32_t index, const protocol::Move& move, std::int64_t now) {
    const MotionOutcome outcome = slot.motion.judge(move, now);
    switch (outcome.act) {
    case MotionAct::kAccept: return;
    case MotionAct::kCorrect: send_position(state, slot, index, outcome.position); return;
    case MotionAct::kKick:
        send_goodbye(state, slot, index, protocol::DisconnectReason::kKicked, Drop::kProtocol);
        return;
    case MotionAct::kOutOfOrder:
        send_reject(state, slot, index, protocol::Move::kKind, protocol::ErrorCode::kOutOfOrder);
        return;
    }
}

void send_ticket(Engine& state, Slot& slot, std::uint32_t index, std::uint16_t request,
    const account::TicketReply& ticket) {
    if (!ticket.ok) {
        send_reject(state, slot, index, request, ticket.code);
        return;
    }
    slot.scratch.clear();
    protocol::Ticket message;
    message.token = ticket.token;
    const bool encoded = protocol::encode(slot.scratch, message).has_value();
    if (!encoded || !seal_to(state, slot, index, slot.scratch)) release(state, slot, index, Drop::kSlow);
}

// Mật khẩu chuyển vào câu hỏi rồi xoá bản trong tin; thư ký xoá bản của nó sau khi hỏi auth.
void ask_password(Engine& state, Slot& slot, std::uint32_t index, AskKind kind, std::uint16_t request,
    std::string_view name, std::string& password) {
    if (!slot.greeted) {
        forget(password);
        send_goodbye(state, slot, index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    if (!state.realm.has_value()) {
        forget(password);
        send_reject(state, slot, index, request, protocol::ErrorCode::kBusy);
        return;
    }
    if (!may_ask(state, slot, index, request)) {
        forget(password);
        return;
    }
    Ask ask;
    ask.kind = kind;
    ask.account = std::string{name};
    ask.secret = password;
    ask.ip = ip_text(slot.address);
    forget(password);
    post_ask(state, slot, index, ask, request);
}

void on_create_account(Engine& state, Slot& slot, std::uint32_t index, protocol::CreateAccount& request) {
    ask_password(state, slot, index, AskKind::kCreateAccount, protocol::CreateAccount::kKind, request.account,
        request.password);
}

void on_sign_in(Engine& state, Slot& slot, std::uint32_t index, protocol::SignIn& request) {
    ask_password(state, slot, index, AskKind::kSignIn, protocol::SignIn::kKind, request.account, request.password);
}

void finish(Engine& state, Slot& slot, std::uint32_t index, const Answer& answer) {
    switch (answer.kind) {
    case AskKind::kCreateAccount:
        send_ticket(state, slot, index, protocol::CreateAccount::kKind, answer.ticket);
        return;
    case AskKind::kSignIn: send_ticket(state, slot, index, protocol::SignIn::kKind, answer.ticket); return;
    case AskKind::kLogin: finish_login(state, slot, index, answer.roster); return;
    case AskKind::kCreateCharacter:
        finish_roster(state, slot, index, protocol::CreateCharacter::kKind, answer.roster);
        return;
    case AskKind::kDeleteCharacter:
        finish_roster(state, slot, index, protocol::DeleteCharacter::kKind, answer.roster);
        return;
    case AskKind::kEnter:
        finish_enter(state, slot, index, protocol::EnterGame::kKind, answer.character, answer.enter);
        return;
    case AskKind::kResume:
        finish_enter(state, slot, index, protocol::Resume::kKind, answer.character, answer.enter);
        return;
    }
}

[[nodiscard]] Answer run_ask(const account::Realm& realm, const Ask& ask) {
    Answer answer;
    answer.handle = ask.handle;
    answer.kind = ask.kind;
    answer.character = ask.character;
    switch (ask.kind) {
    case AskKind::kCreateAccount: answer.ticket = realm.create_account(ask.account, ask.secret, ask.ip); break;
    case AskKind::kSignIn: answer.ticket = realm.sign_in(ask.account, ask.secret, ask.ip); break;
    case AskKind::kLogin: answer.roster = realm.login(ask.account, ask.secret); break;
    case AskKind::kCreateCharacter: answer.roster = realm.create_character(ask.cap, ask.create); break;
    case AskKind::kDeleteCharacter: answer.roster = realm.remove_character(ask.cap, ask.character); break;
    case AskKind::kEnter:
    case AskKind::kResume: answer.enter = realm.enter(ask.cap, ask.character); break;
    }
    return answer;
}

// Luồng thư ký: một câu hỏi một lần, theo thứ tự. Dừng thì bỏ trả lời chưa gửi được (ô sắp đóng).
void clerk_main(Engine& state) {
    const account::Realm& realm = *state.realm;
    for (;;) {
        Ask ask;
        if (!state.asks.try_pop(ask)) {
            if (state.clerk_stop.load(std::memory_order_acquire)) return;
            state.asks.park([&] { return state.asks.empty() && !state.clerk_stop.load(std::memory_order_acquire); });
            continue;
        }
        Answer answer = run_ask(realm, ask);
        wipe_ask(ask);
        while (!state.answers.try_push(answer)) {
            if (state.clerk_stop.load(std::memory_order_acquire)) {
                wipe_answer(answer);
                return;
            }
            std::this_thread::yield();
        }
    }
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

void dispatch_auth(SlotNow in, protocol::Frame frame, secure::ByteView body) {
    const bool is_hello = frame.kind == protocol::Hello::kKind;
    const bool is_create = frame.kind == protocol::CreateAccount::kKind;
    const bool is_sign = frame.kind == protocol::SignIn::kKind;
    if (!is_hello && !is_create && !is_sign) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kProtocolViolation, Drop::kForeign);
        return;
    }
    protocol::AuthClientResult decoded = protocol::decode_auth_client(frame, body);
    if (!decoded) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    if (const auto* hello = std::get_if<protocol::Hello>(&*decoded)) {
        on_hello(in.state, in.slot, in.index, *hello, in.now);
    }
    if (auto* create = std::get_if<protocol::CreateAccount>(&*decoded)) {
        on_create_account(in.state, in.slot, in.index, *create);
    }
    if (auto* sign = std::get_if<protocol::SignIn>(&*decoded)) on_sign_in(in.state, in.slot, in.index, *sign);
}

void dispatch_game(SlotNow in, protocol::Frame frame, secure::ByteView body) {
    const bool is_hello = frame.kind == protocol::Hello::kKind;
    const bool is_ping = frame.kind == protocol::Ping::kKind;
    const bool is_logout = frame.kind == protocol::Logout::kKind;
    const bool is_login = frame.kind == protocol::Login::kKind;
    const bool is_resume = frame.kind == protocol::Resume::kKind;
    const bool is_create = frame.kind == protocol::CreateCharacter::kKind;
    const bool is_remove = frame.kind == protocol::DeleteCharacter::kKind;
    const bool is_enter = frame.kind == protocol::EnterGame::kKind;
    const bool is_move = frame.kind == protocol::Move::kKind;
    const bool known =
        is_hello || is_ping || is_logout || is_login || is_resume || is_create || is_remove || is_enter || is_move;
    if (!known) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kProtocolViolation, Drop::kForeign);
        return;
    }
    protocol::GameClientResult decoded = protocol::decode_game_client(frame, body);
    if (!decoded) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kProtocolViolation, Drop::kProtocol);
        return;
    }
    if (const auto* hello = std::get_if<protocol::Hello>(&*decoded)) {
        on_hello(in.state, in.slot, in.index, *hello, in.now);
    }
    if (auto* login = std::get_if<protocol::Login>(&*decoded)) on_login(in.state, in.slot, in.index, *login);
    if (const auto* resume = std::get_if<protocol::Resume>(&*decoded)) {
        on_resume(in.state, in.slot, in.index, *resume, in.now);
    }
    if (const auto* ping = std::get_if<protocol::Ping>(&*decoded)) on_ping(in.state, in.slot, in.index, *ping, in.now);
    if (std::get_if<protocol::Logout>(&*decoded) != nullptr) on_logout(in.state, in.slot, in.index);
    if (const auto* create = std::get_if<protocol::CreateCharacter>(&*decoded)) {
        on_create_character(in.state, in.slot, in.index, *create);
    }
    if (const auto* remove = std::get_if<protocol::DeleteCharacter>(&*decoded)) {
        on_delete_character(in.state, in.slot, in.index, *remove);
    }
    if (const auto* enter = std::get_if<protocol::EnterGame>(&*decoded)) on_enter(in.state, in.slot, in.index, *enter);
    if (const auto* move = std::get_if<protocol::Move>(&*decoded)) on_move(in.state, in.slot, in.index, *move, in.now);
}

void dispatch(SlotNow in, protocol::Frame frame, secure::ByteView body) {
    if (!spend(in.slot, in.state.limits, in.now)) {
        send_goodbye(in.state, in.slot, in.index, protocol::DisconnectReason::kKicked, Drop::kRate);
        return;
    }
    if (in.slot.door == Door::kAuth) dispatch_auth(in, frame, body);
    if (in.slot.door != Door::kAuth) dispatch_game(in, frame, body);
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

Engine::~Engine() {
    clerk_stop.store(true, std::memory_order_seq_cst);
    asks.wake();
    if (clerk.joinable()) clerk.join();
    Ask left;
    while (asks.try_pop(left))
        wipe_ask(left);
    Answer done;
    while (answers.try_pop(done))
        wipe_answer(done);
}

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
    state_->due.assign(limits.max_connections, std::numeric_limits<std::int64_t>::max());
    state_->free_slots.reserve(limits.max_connections);
    state_->closed.reserve(limits.max_connections);
    const std::size_t queue_room = limits.max_connections + 256;
    constexpr std::array<net::LaneSpec, 3> kSendLanes{{
        {.priority = 0, .weight = 1},
        {.priority = 1, .weight = 4},
        {.priority = 1, .weight = 1},
    }};
    state_->pending.reset(kSendLanes);
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
    return admit(address, now, Door::kGame);
}

void Table::set_realm(const account::Realm& realm) {
    if (state_->realm.has_value()) return;
    state_->realm.emplace(realm);
    Engine* const engine = state_.get();
    state_->clerk = std::jthread([engine] { clerk_main(*engine); });
}

void Table::collect() {
    Answer answer;
    while (state_->answers.try_pop(answer)) {
        Slot* slot = live_slot(*state_, answer.handle);
        if (slot != nullptr) {
            slot->asking = false;
            finish(*state_, *slot, answer.handle.index, answer);
        }
        wipe_answer(answer);
    }
}

Admit Table::admit(net::Ipv4 address, std::int64_t now, Door door) {
    if (state_->free_slots.empty()) return Admit{.code = AdmitCode::kFull};
    if (!address_ok(*state_, address)) return Admit{.code = AdmitCode::kDenied};
    if (!gain_ip(*state_, address)) return Admit{.code = AdmitCode::kPerIp};
    const std::uint32_t index = state_->free_slots.back();
    state_->free_slots.pop_back();
    Slot& slot = state_->slots[index];
    slot.live = true;
    slot.greeted = false;
    slot.door = door;
    slot.has_account = false;
    slot.has_cap = false;
    slot.account_id = 0;
    slot.cap = {};
    slot.motion.clear();
    slot.has_resume_spot = false;
    slot.resume_spot = {};
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
    slot.asking = false;
    slot.handshake.emplace(*state_->identity);
    slot.pipe.reset();
    state_->due[index] = now;
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

// Mốc kế: hạn idle tính từ seen_ns hiện tại, và hạn bắt tay nếu còn bắt tay. Luôn tính cả hạn idle
// (kể cả khi đang bắt tay): bắt tay xong thì seen_ns chỉ tiến, nên mốc này không bao giờ trễ hơn hạn thật.
[[nodiscard]] std::int64_t next_due(const Engine& state, const Slot& slot) noexcept {
    if (!slot.live) return std::numeric_limits<std::int64_t>::max();
    std::int64_t due = slot.seen_ns + state.limits.idle_ns;
    if (slot.handshake.has_value()) due = std::min(due, slot.born_ns + state.limits.handshake_ns);
    return due;
}

void clock_slot(Engine& state, TickAt at) {
    Slot& slot = state.slots[at.index];
    if (slot.live) {
        const bool handshake_late = slot.handshake.has_value() && at.now - slot.born_ns >= state.limits.handshake_ns;
        if (handshake_late) release(state, slot, at.index, Drop::kHandshake);
    }
    if (slot.live && slot.pipe.has_value() && !slot.draining) {
        const bool idle_late = at.now - slot.seen_ns >= state.limits.idle_ns;
        if (idle_late) send_goodbye(state, slot, at.index, protocol::DisconnectReason::kIdle, Drop::kIdle);
    }
    // Đã gửi goodbye (draining) thì không còn hạn đồng hồ nào; vẫn tính mốc idle để kiểm lại, rẻ.
    state.due[at.index] = next_due(state, slot);
}

void release_live(Engine& state, std::uint32_t index) {
    if (!state.slots[index].live) return;
    release(state, state.slots[index], index, Drop::kStop);
}

} // namespace

void Table::advance(std::int64_t now) {
    const std::span<const std::int64_t> due{state_->due};
    for (std::uint32_t index = 0; index < due.size(); ++index) {
        if (now < due[index]) continue;
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
    return state_->pending.pop(out);
}

std::size_t Table::take_resume(std::span<Handle> out) {
    return take_queue(state_->resume, state_->resume_from, out);
}

} // namespace game::gate
