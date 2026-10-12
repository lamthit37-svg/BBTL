#include "account/rpc.hpp"

#include "net/reactor.hpp"
#include "net/shard.hpp"
#include "process/process.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <thread>
#include <utility>

namespace game::account {
namespace {

constexpr std::uint32_t kPayloadMax = 8192;
constexpr std::uint64_t kTag = 1;
using Clock = std::chrono::steady_clock;

struct Out {
    std::vector<std::byte> bytes;

    void u8(std::uint8_t value) { bytes.push_back(std::byte{value}); }

    void u16(std::uint16_t value) {
        u8(static_cast<std::uint8_t>(value));
        u8(static_cast<std::uint8_t>(value >> 8U));
    }

    void u32(std::uint32_t value) {
        u16(static_cast<std::uint16_t>(value));
        u16(static_cast<std::uint16_t>(value >> 16U));
    }

    void u64(std::uint64_t value) {
        u32(static_cast<std::uint32_t>(value));
        u32(static_cast<std::uint32_t>(value >> 32U));
    }

    void text(std::string_view value) {
        u16(static_cast<std::uint16_t>(value.size()));
        if (value.empty()) return;
        const auto* data = reinterpret_cast<const std::byte*>(value.data());
        bytes.insert(bytes.end(), data, data + value.size());
    }
};

struct In {
    std::span<const std::byte> rest;
    bool ok = true;

    [[nodiscard]] std::uint8_t u8() {
        if (rest.size() < 1) {
            ok = false;
            return 0;
        }
        const auto value = static_cast<std::uint8_t>(rest.front());
        rest = rest.subspan(1);
        return value;
    }

    [[nodiscard]] std::uint16_t u16() {
        const auto low = static_cast<std::uint16_t>(u8());
        const auto high = static_cast<std::uint16_t>(u8()) << 8U;
        return static_cast<std::uint16_t>(low | high);
    }

    [[nodiscard]] std::uint32_t u32() {
        const auto low = static_cast<std::uint32_t>(u16());
        const auto high = static_cast<std::uint32_t>(u16()) << 16U;
        return low | high;
    }

    [[nodiscard]] std::uint64_t u64() {
        const auto low = static_cast<std::uint64_t>(u32());
        const auto high = static_cast<std::uint64_t>(u32()) << 32U;
        return low | high;
    }

    [[nodiscard]] std::string text(std::size_t max) {
        const std::uint16_t size = u16();
        if (!ok || size > max || rest.size() < size) {
            ok = false;
            return {};
        }
        if (size == 0) return {};
        std::string value(reinterpret_cast<const char*>(rest.data()), size);
        rest = rest.subspan(size);
        return value;
    }

    [[nodiscard]] bool copy_to(std::span<std::byte> dest) {
        if (!ok || rest.size() < dest.size()) {
            ok = false;
            return false;
        }
        std::copy(rest.begin(), rest.begin() + static_cast<std::ptrdiff_t>(dest.size()), dest.begin());
        rest = rest.subspan(dest.size());
        return true;
    }
};

[[nodiscard]] std::vector<std::byte> frame_of(std::uint16_t code, std::span<const std::byte> body) {
    if (body.size() + 2 > kPayloadMax) return {};
    Out out;
    out.u32(static_cast<std::uint32_t>(body.size() + 2));
    out.u16(code);
    out.bytes.insert(out.bytes.end(), body.begin(), body.end());
    return std::move(out.bytes);
}

[[nodiscard]] std::chrono::milliseconds remaining(Clock::time_point deadline) {
    const auto left = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now());
    if (left.count() < 0) return std::chrono::milliseconds::zero();
    return left;
}

[[nodiscard]] bool wait_io(net::PollSet& poll, Clock::time_point deadline) {
    const std::chrono::milliseconds left = remaining(deadline);
    if (left.count() == 0) return false;
    net::PollEvents events;
    const net::NetResult<void> waited = poll.wait(left, events);
    if (!waited || events.empty() || events.front().failed) return false;
    return true;
}

[[nodiscard]] bool write_all(net::TcpStream& stream, net::PollSet& poll, std::span<const std::byte> data,
    Clock::time_point deadline) {
    std::size_t sent = 0;
    while (sent < data.size()) {
        const net::NetResult<std::size_t> wrote = stream.send(data.subspan(sent));
        if (!wrote) return false;
        sent += *wrote;
        if (sent == data.size()) return true;
        poll.want_write(kTag, true);
        if (!wait_io(poll, deadline)) return false;
    }
    return true;
}

[[nodiscard]] bool read_exact(net::TcpStream& stream, net::PollSet& poll, std::span<std::byte> dest,
    Clock::time_point deadline) {
    std::size_t got = 0;
    while (got < dest.size()) {
        const net::NetResult<std::size_t> read = stream.receive(dest.subspan(got));
        if (!read) return false;
        got += *read;
        if (got == dest.size()) return true;
        poll.want_write(kTag, false);
        if (!wait_io(poll, deadline)) return false;
    }
    return true;
}

[[nodiscard]] bool finish(net::TcpStream& stream, net::PollSet& poll, Clock::time_point deadline) {
    while (true) {
        const net::NetResult<bool> connected = stream.finish_connect();
        if (!connected) return false;
        if (*connected) return true;
        poll.want_write(kTag, true);
        if (!wait_io(poll, deadline)) return false;
    }
}

[[nodiscard]] std::optional<Reply> read_reply(net::TcpStream& stream, net::PollSet& poll, Clock::time_point deadline,
    secure::ByteView key) {
    std::array<std::byte, 4> head{};
    if (!read_exact(stream, poll, head, deadline)) return std::nullopt;
    const auto size = static_cast<std::uint32_t>(static_cast<unsigned>(head[0])) |
                      (static_cast<std::uint32_t>(static_cast<unsigned>(head[1])) << 8U) |
                      (static_cast<std::uint32_t>(static_cast<unsigned>(head[2])) << 16U) |
                      (static_cast<std::uint32_t>(static_cast<unsigned>(head[3])) << 24U);
    constexpr std::uint32_t kBoxMin = 24 + 16 + 2;
    constexpr std::uint32_t kBoxMax = kBoxMin + kPayloadMax;
    if (size < kBoxMin || size > kBoxMax) return std::nullopt;
    std::vector<std::byte> payload(size);
    if (!read_exact(stream, poll, payload, deadline)) return std::nullopt;
    const std::optional<std::vector<std::byte>> plain = secure::ipc_open(key, payload);
    if (!plain || plain->size() < 2) return std::nullopt;
    Reply reply;
    const auto low = static_cast<unsigned>((*plain)[0]);
    const auto high = static_cast<unsigned>((*plain)[1]) << 8U;
    reply.code = static_cast<std::uint16_t>(low | high);
    reply.body.assign(plain->begin() + 2, plain->end());
    return reply;
}

[[nodiscard]] std::optional<std::vector<std::byte>> seal_message(secure::ByteView key, std::uint16_t code,
    std::span<const std::byte> body) {
    if (body.size() > kPayloadMax) return std::nullopt;
    std::vector<std::byte> plain;
    plain.push_back(static_cast<std::byte>(code));
    plain.push_back(static_cast<std::byte>(code >> 8U));
    plain.insert(plain.end(), body.begin(), body.end());
    const std::optional<std::vector<std::byte>> boxed = secure::ipc_seal(key, plain);
    if (!boxed) return std::nullopt;
    Out wire;
    wire.u32(static_cast<std::uint32_t>(boxed->size()));
    wire.bytes.insert(wire.bytes.end(), boxed->begin(), boxed->end());
    return std::move(wire.bytes);
}

[[nodiscard]] bool read_call(net::TcpStream& stream, net::PollSet& poll, secure::ByteView key, Call& call) {
    const Clock::time_point deadline = Clock::now() + std::chrono::seconds{3};
    const std::optional<Reply> reply = read_reply(stream, poll, deadline, key);
    if (!reply) return false;
    call.op = static_cast<Op>(reply->code);
    call.body = std::move(reply->body);
    return true;
}

void write_summary(Out& out, const protocol::CharacterSummary& summary) {
    out.u64(summary.id);
    out.text(summary.name);
    out.u16(summary.level);
    out.u8(static_cast<std::uint8_t>(summary.gender));
    out.u16(summary.face);
    out.u16(summary.hair);
    out.u8(summary.school);
    out.u16(summary.scene);
}

[[nodiscard]] bool read_summary(In& in, protocol::CharacterSummary& summary) {
    summary.id = in.u64();
    summary.name = in.text(protocol::kCharacterSummaryNameBytes);
    summary.level = in.u16();
    const auto gender = static_cast<protocol::Gender>(in.u8());
    summary.face = in.u16();
    summary.hair = in.u16();
    summary.school = in.u8();
    summary.scene = in.u16();
    if (!in.ok || !protocol::is_valid(gender)) return false;
    summary.gender = gender;
    return true;
}

[[nodiscard]] protocol::ErrorCode code_of(std::uint16_t code) noexcept {
    const auto value = static_cast<protocol::ErrorCode>(code);
    if (!protocol::is_valid(value)) return protocol::ErrorCode::kBusy;
    return value;
}

[[nodiscard]] Reply ok_reply(std::vector<std::byte> body) {
    Reply reply;
    reply.body = std::move(body);
    return reply;
}

[[nodiscard]] Reply error_reply(protocol::ErrorCode code) {
    Reply reply;
    reply.code = static_cast<std::uint16_t>(code);
    return reply;
}

} // namespace

Call account_call(Op op, std::string_view name, std::string_view password, std::string_view ip) {
    Out out;
    out.text(name);
    out.text(password);
    out.text(ip);
    return Call{.op = op, .body = std::move(out.bytes)};
}

Call redeem_call(std::string_view ticket_hex) {
    Out out;
    out.text(ticket_hex);
    return Call{.op = Op::kRedeem, .body = std::move(out.bytes)};
}

Call list_call(std::span<const std::byte, kCapBytes> cap) {
    Out out;
    out.bytes.insert(out.bytes.end(), cap.begin(), cap.end());
    return Call{.op = Op::kList, .body = std::move(out.bytes)};
}

Call character_call(std::span<const std::byte, kCapBytes> cap, std::string_view name, protocol::Gender gender,
    std::uint16_t face, std::uint16_t hair) {
    Out out;
    out.bytes.insert(out.bytes.end(), cap.begin(), cap.end());
    out.text(name);
    out.u8(static_cast<std::uint8_t>(gender));
    out.u16(face);
    out.u16(hair);
    return Call{.op = Op::kCreateCharacter, .body = std::move(out.bytes)};
}

Call id_call(Op op, std::span<const std::byte, kCapBytes> cap, std::uint64_t character) {
    Out out;
    out.bytes.insert(out.bytes.end(), cap.begin(), cap.end());
    out.u64(character);
    return Call{.op = op, .body = std::move(out.bytes)};
}

bool read_account_call(const Call& call, std::string& name, std::string& password, std::string& ip) {
    In in{call.body};
    name = in.text(protocol::kCreateAccountAccountBytes);
    password = in.text(protocol::kCreateAccountPasswordBytes);
    ip = in.text(64);
    return in.ok && in.rest.empty();
}

bool read_text_call(const Call& call, std::string& text) {
    In in{call.body};
    text = in.text(protocol::kLoginTicketBytes);
    return in.ok && in.rest.empty();
}

bool read_list_call(const Call& call, std::array<std::byte, kCapBytes>& cap) {
    In in{call.body};
    const bool copied = in.copy_to(cap);
    return copied && in.ok && in.rest.empty();
}

bool read_character_call(const Call& call, std::array<std::byte, kCapBytes>& cap, std::string& name,
    protocol::Gender& gender, std::uint16_t& face, std::uint16_t& hair) {
    In in{call.body};
    const bool copied = in.copy_to(cap);
    name = in.text(protocol::kCreateCharacterNameBytes);
    gender = static_cast<protocol::Gender>(in.u8());
    face = in.u16();
    hair = in.u16();
    return copied && in.ok && in.rest.empty() && protocol::is_valid(gender);
}

bool read_id_call(const Call& call, std::array<std::byte, kCapBytes>& cap, std::uint64_t& character) {
    In in{call.body};
    const bool copied = in.copy_to(cap);
    character = in.u64();
    return copied && in.ok && in.rest.empty();
}

Reply reply_of(const TicketResult& result) {
    if (!result.ok) return error_reply(result.code);
    Out out;
    out.text(result.hex);
    return ok_reply(std::move(out.bytes));
}

Reply reply_of(const RedeemResult& result) {
    if (!result.ok) return error_reply(result.code);
    Out out;
    out.u64(result.account);
    out.text(result.name);
    out.bytes.insert(out.bytes.end(), result.cap.begin(), result.cap.end());
    return ok_reply(std::move(out.bytes));
}

Reply reply_of(const ListResult& result) {
    if (!result.ok) return error_reply(result.code);
    Out out;
    out.u16(static_cast<std::uint16_t>(result.characters.size()));
    for (const protocol::CharacterSummary& summary : result.characters) write_summary(out, summary);
    return ok_reply(std::move(out.bytes));
}

Reply reply_of(const EnterResult& result) {
    if (!result.ok) return error_reply(result.code);
    return ok_reply({});
}

TicketResult ticket_from(const Reply& reply) {
    TicketResult result;
    if (reply.code != 0) {
        result.code = code_of(reply.code);
        return result;
    }
    In in{reply.body};
    result.hex = in.text(kTicketHex);
    if (!in.ok || !in.rest.empty() || result.hex.size() != kTicketHex) {
        result.code = protocol::ErrorCode::kBusy;
        return result;
    }
    result.ok = true;
    return result;
}

RedeemResult redeem_from(const Reply& reply) {
    RedeemResult result;
    if (reply.code != 0) {
        result.code = code_of(reply.code);
        return result;
    }
    In in{reply.body};
    result.account = in.u64();
    result.name = in.text(protocol::kLoginAccountBytes);
    const bool copied = in.copy_to(result.cap);
    if (!in.ok || !copied || !in.rest.empty()) {
        result.code = protocol::ErrorCode::kBusy;
        return result;
    }
    result.ok = true;
    return result;
}

ListResult list_from(const Reply& reply) {
    ListResult result;
    if (reply.code != 0) {
        result.code = code_of(reply.code);
        return result;
    }
    In in{reply.body};
    const std::uint16_t count = in.u16();
    if (!in.ok || count > protocol::kCharacterListCharactersCount) return result;
    for (std::uint16_t index = 0; index < count; ++index) {
        protocol::CharacterSummary summary;
        if (!read_summary(in, summary)) return result;
        result.characters.push_back(std::move(summary));
    }
    if (!in.ok || !in.rest.empty()) return result;
    result.ok = true;
    return result;
}

EnterResult enter_from(const Reply& reply) {
    EnterResult result;
    if (reply.code != 0) {
        result.code = code_of(reply.code);
        return result;
    }
    if (!reply.body.empty()) return result;
    result.ok = true;
    return result;
}

std::optional<Reply> exchange(const net::Endpoint& endpoint, const Call& call, std::chrono::milliseconds timeout,
    secure::ByteView key) {
    net::NetResult<net::TcpStream> opened = net::TcpStream::begin_connect(endpoint);
    if (!opened) return std::nullopt;
    net::PollSet poll;
    if (!poll.add(opened->handle(), kTag)) return std::nullopt;
    const Clock::time_point deadline = Clock::now() + timeout;
    if (!finish(*opened, poll, deadline)) {
        poll.remove(kTag);
        return std::nullopt;
    }
    const std::optional<std::vector<std::byte>> frame = seal_message(key, static_cast<std::uint16_t>(call.op), call.body);
    if (!frame || !write_all(*opened, poll, *frame, deadline)) {
        poll.remove(kTag);
        return std::nullopt;
    }
    std::optional<Reply> reply = read_reply(*opened, poll, deadline, key);
    poll.remove(kTag);
    return reply;
}

constexpr std::size_t kFlight = 8;

struct Live {
    std::uint64_t id = 0;
    net::TcpStream stream;
    bool used = false;
};

struct Work {
    std::uint64_t id = 0;
    Call call;
};

struct Done {
    std::uint64_t id = 0;
    Reply reply;
};

struct Shared {
    std::atomic<bool> stop{false};
    net::SpscMail<Work, 16> jobs{};
    net::SpscMail<Done, 16> done{};
    net::Reactor* reactor = nullptr;
    Handler handler = nullptr;
    void* ctx = nullptr;
};

struct StopDb {
    Shared* shared = nullptr;
    std::jthread* thread = nullptr;

    ~StopDb() {
        if (shared == nullptr) return;
        shared->stop.store(true, std::memory_order_seq_cst);
        shared->jobs.wake();
        if (shared->reactor != nullptr) shared->reactor->wake();
        if (thread != nullptr && thread->joinable()) thread->join();
    }
};

void wipe_call(Call& call) noexcept {
    if (call.body.empty()) return;
    secure::wipe_bytes(call.body);
    call.body.clear();
}

void db_main(Shared& shared) {
    for (;;) {
        Work work;
        if (!shared.jobs.try_pop(work)) {
            if (shared.stop.load(std::memory_order_acquire)) return;
            shared.jobs.park([&] { return shared.jobs.empty() && !shared.stop.load(std::memory_order_acquire); });
            continue;
        }
        Done item;
        item.id = work.id;
        item.reply = shared.handler(shared.ctx, work.call);
        wipe_call(work.call);
        if (shared.stop.load(std::memory_order_acquire)) return;
        while (!shared.done.try_push(item)) {
            if (shared.stop.load(std::memory_order_acquire)) return;
            std::this_thread::yield();
        }
        if (shared.reactor != nullptr) shared.reactor->wake();
    }
}

[[nodiscard]] std::size_t flying(const std::array<Live, kFlight>& lives) noexcept {
    std::size_t count = 0;
    for (const Live& live : lives) {
        if (live.used) ++count;
    }
    return count;
}

[[nodiscard]] Live* find_live(std::array<Live, kFlight>& lives, std::uint64_t id) noexcept {
    for (Live& live : lives) {
        if (live.used && live.id == id) return &live;
    }
    return nullptr;
}

[[nodiscard]] Live* free_live(std::array<Live, kFlight>& lives) noexcept {
    for (Live& live : lives) {
        if (!live.used) return &live;
    }
    return nullptr;
}

void release_live(Live& live) {
    live.stream = net::TcpStream{};
    live.used = false;
    live.id = 0;
}

void drain_done(Shared& shared, std::array<Live, kFlight>& lives, secure::ByteView key) {
    Done item;
    while (shared.done.try_pop(item)) {
        Live* live = find_live(lives, item.id);
        if (live == nullptr) continue;
        const std::optional<std::vector<std::byte>> frame = seal_message(key, item.reply.code, item.reply.body);
        if (frame) {
            net::PollSet poll;
            if (poll.add(live->stream.handle(), kTag)) {
                const Clock::time_point deadline = Clock::now() + std::chrono::seconds{3};
                static_cast<void>(write_all(live->stream, poll, *frame, deadline));
                poll.remove(kTag);
            }
        }
        release_live(*live);
    }
}

[[nodiscard]] bool take_job(net::Reactor& reactor, Shared& shared, std::array<Live, kFlight>& lives,
    std::uint64_t& next_id, secure::ByteView key) {
    if (flying(lives) >= kFlight) return false;
    net::NetResult<std::optional<net::Accepted>> got = reactor.take_accept(kTag);
    if (!got || !got->has_value()) return false;
    Live* live = free_live(lives);
    if (live == nullptr) return false;
    live->stream = std::move((*got)->stream);
    live->used = true;
    ++next_id;
    live->id = next_id;
    net::PollSet poll;
    Call call;
    const bool read = poll.add(live->stream.handle(), kTag) && read_call(live->stream, poll, key, call);
    poll.remove(kTag);
    if (!read) {
        release_live(*live);
        return true;
    }
    Work work;
    work.id = live->id;
    work.call = std::move(call);
    if (shared.jobs.try_push(work)) return true;
    wipe_call(work.call);
    release_live(*live);
    return true;
}

int serve_loop(net::TcpListener& listener, Handler handler, void* ctx, secure::ByteView key) {
    Shared shared;
    shared.handler = handler;
    shared.ctx = ctx;
    net::Reactor reactor;
    shared.reactor = &reactor;
    if (!reactor.watch_listener(listener, kTag)) return 1;
    std::array<Live, kFlight> lives{};
    std::uint64_t next_id = 0;
    std::jthread db(db_main, std::ref(shared));
    [[maybe_unused]] const StopDb guard{.shared = &shared, .thread = &db};
    int code = 0;
    while (!process::stop_requested()) {
        drain_done(shared, lives, key);
        net::PollEvents events;
        if (!reactor.wait(std::chrono::milliseconds{200}, events)) {
            code = 1;
            break;
        }
        drain_done(shared, lives, key);
        while (take_job(reactor, shared, lives, next_id, key)) {
        }
    }
    return code;
}

} // namespace game::account
