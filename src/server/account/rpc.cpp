/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/account/rpc.cpp
 *  PHÂN HỆ   : Server / Account / Rpc
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Khung rpc một yêu cầu một kết nối giữa gate/zone và auth/store: mã hoá
 *    khung, đọc và dựng từng loại thân.
 *  - Thân tối đa theo khung protocol vì Op::kEnter và Op::kSave mang khối trạng
 *    thái chơi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "account/rpc.hpp"

#include "net/reactor.hpp"
#include "net/shard.hpp"
#include "process/process.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <expected>
#include <thread>
#include <utility>
#include <vector>

namespace game::account {
namespace {

// Trả lời Op::kEnter và Op::kSave mang khối trạng thái chơi (account/play.hpp) nên trần theo khung protocol, không còn 8 KiB.
constexpr std::uint32_t kPayloadMax = 80 * 1024;
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

    void blob(std::span<const std::byte> value) {
        u32(static_cast<std::uint32_t>(value.size()));
        bytes.insert(bytes.end(), value.begin(), value.end());
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

    // Khối có tiền tố độ dài u32, tối đa `max` byte; vượt trần hay thiếu byte thì ok = false và không cấp phát.
    [[nodiscard]] std::vector<std::byte> blob(std::size_t max) {
        const std::uint32_t size = u32();
        if (!ok || size > max || rest.size() < size) {
            ok = false;
            return {};
        }
        std::vector<std::byte> value(rest.begin(), rest.begin() + static_cast<std::ptrdiff_t>(size));
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

// Độ dài khung: bốn byte đầu, little-endian.
[[nodiscard]] std::uint32_t frame_size(std::span<const std::byte> head) noexcept {
    return std::to_integer<std::uint32_t>(head[0]) | (std::to_integer<std::uint32_t>(head[1]) << 8U) |
        (std::to_integer<std::uint32_t>(head[2]) << 16U) | (std::to_integer<std::uint32_t>(head[3]) << 24U);
}

[[nodiscard]] std::optional<Reply> read_reply(net::TcpStream& stream, net::PollSet& poll, Clock::time_point deadline,
    secure::ByteView key) {
    std::array<std::byte, 4> head{};
    if (!read_exact(stream, poll, head, deadline)) return std::nullopt;
    const std::uint32_t size = frame_size(head);
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

void write_summary(Out& out, const protocol::CharacterSummary& summary) {
    out.u64(summary.id);
    out.text(summary.name);
    out.u16(summary.level);
    out.u8(static_cast<std::uint8_t>(summary.gender));
    out.u16(summary.face);
    out.u16(summary.hair);
    out.u8(summary.school);
    out.u16(summary.scene);
    out.u16(summary.portrait);
    out.u16(summary.equip_set);
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
    summary.portrait = in.u16();
    summary.equip_set = in.u16();
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

Call standing_call(std::span<const std::byte, kCapBytes> cap) {
    Out out;
    out.bytes.insert(out.bytes.end(), cap.begin(), cap.end());
    return Call{.op = Op::kStanding, .body = std::move(out.bytes)};
}

Call character_call(std::span<const std::byte, kCapBytes> cap, std::string_view name,
    const Look& look) {
    Out out;
    out.bytes.insert(out.bytes.end(), cap.begin(), cap.end());
    out.text(name);
    out.u8(static_cast<std::uint8_t>(look.gender));
    out.u16(look.face);
    out.u16(look.hair);
    out.u16(look.portrait);
    out.u16(look.equip_set);
    return Call{.op = Op::kCreateCharacter, .body = std::move(out.bytes)};
}

Call id_call(Op op, std::span<const std::byte, kCapBytes> cap, std::uint64_t character) {
    Out out;
    out.bytes.insert(out.bytes.end(), cap.begin(), cap.end());
    out.u64(character);
    return Call{.op = op, .body = std::move(out.bytes)};
}

std::optional<Call> save_call(const SaveSpot& spot) {
    Out out;
    out.u64(spot.character);
    out.u16(spot.scene);
    out.u32(static_cast<std::uint32_t>(spot.x_cm));
    out.u32(static_cast<std::uint32_t>(spot.z_cm));
    out.u8(spot.play ? 1 : 0);
    if (spot.play) {
        const std::expected<std::vector<std::byte>, PlayError> packed = pack(*spot.play);
        if (!packed) return std::nullopt;
        out.blob(*packed);
    }
    return Call{.op = Op::kSave, .body = std::move(out.bytes)};
}

bool read_save_call(const Call& call, SaveSpot& spot) {
    In in{call.body};
    spot.character = in.u64();
    spot.scene = in.u16();
    spot.x_cm = static_cast<std::int32_t>(in.u32());
    spot.z_cm = static_cast<std::int32_t>(in.u32());
    const std::uint8_t has_play = in.u8();
    spot.play.reset();
    if (has_play == 1) {
        const std::vector<std::byte> packed = in.blob(kMaxPackedPlay);
        std::expected<PlayRecord, PlayError> record = unpack(packed);
        if (!in.ok || !record) return false;
        spot.play = std::move(*record);
    } else if (has_play != 0) {
        return false;
    }
    return in.ok && in.rest.empty() && spot_fits(spot.x_cm) && spot_fits(spot.z_cm);
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
    Look& look) {
    In in{call.body};
    const bool copied = in.copy_to(cap);
    name = in.text(protocol::kCreateCharacterNameBytes);
    look.gender = static_cast<protocol::Gender>(in.u8());
    look.face = in.u16();
    look.hair = in.u16();
    look.portrait = in.u16();
    look.equip_set = in.u16();
    const bool is_whole = copied && in.ok && in.rest.empty();
    return is_whole && protocol::is_valid(look.gender);
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
    for (const protocol::CharacterSummary& summary : result.characters)
        write_summary(out, summary);
    return ok_reply(std::move(out.bytes));
}

Reply reply_of(const EnterResult& result) {
    if (!result.ok) return error_reply(result.code);
    return ok_reply({});
}

Reply enter_reply_of(const EnterResult& result) {
    if (!result.ok) return error_reply(result.code);
    if (!spot_fits(result.x_cm) || !spot_fits(result.z_cm)) return error_reply(protocol::ErrorCode::kBusy);
    Out out;
    out.u16(result.scene);
    out.u32(static_cast<std::uint32_t>(result.x_cm));
    out.u32(static_cast<std::uint32_t>(result.z_cm));
    write_summary(out, result.summary);
    const std::expected<std::vector<std::byte>, PlayError> packed = pack(result.play);
    if (!packed) return error_reply(protocol::ErrorCode::kBusy);
    out.blob(*packed);
    return ok_reply(std::move(out.bytes));
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

EnterResult entered_from(const Reply& reply) {
    EnterResult result;
    if (reply.code != 0) {
        result.code = code_of(reply.code);
        return result;
    }
    In in{reply.body};
    const std::uint16_t scene = in.u16();
    const auto x_cm = static_cast<std::int32_t>(in.u32());
    const auto z_cm = static_cast<std::int32_t>(in.u32());
    protocol::CharacterSummary summary;
    const bool summary_ok = read_summary(in, summary);
    const std::vector<std::byte> packed = in.blob(kMaxPackedPlay);
    std::expected<PlayRecord, PlayError> play = unpack(packed);
    if (!in.ok || !summary_ok || !in.rest.empty() || !spot_fits(x_cm) || !spot_fits(z_cm) || !play) {
        result.code = protocol::ErrorCode::kBusy;
        return result;
    }
    result.play = std::move(*play);
    result.ok = true;
    result.scene = scene;
    result.x_cm = x_cm;
    result.z_cm = z_cm;
    result.summary = std::move(summary);
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
    const std::optional<std::vector<std::byte>> frame =
        seal_message(key, static_cast<std::uint16_t>(call.op), call.body);
    if (!frame || !write_all(*opened, poll, *frame, deadline)) {
        poll.remove(kTag);
        return std::nullopt;
    }
    std::optional<Reply> reply = read_reply(*opened, poll, deadline, key);
    poll.remove(kTag);
    return reply;
}

namespace {

// Mỗi kết nối là một máy trạng thái không chặn: đọc khung, chờ luồng database, ghi trả lời.
// Một kết nối chậm chỉ giữ một ô của nó; luồng nhận không bao giờ chờ trên một socket.
// Hạn 3 giây tính riêng cho phần đọc và phần ghi; thời gian database không tính.
constexpr std::size_t kConns = 64;
constexpr std::size_t kMailRoom = 64;
constexpr auto kIoLimit = std::chrono::seconds{3};
constexpr std::uint32_t kFrameMin = 24 + 16 + 2;
constexpr std::uint32_t kFrameMax = kFrameMin + kPayloadMax;
constexpr std::uint64_t kFirstConnTag = 2;
static_assert(kMailRoom >= kConns, "hàng done phải chứa đủ mọi kết nối đang chờ database");

enum class Phase : std::uint8_t { kFree, kReading, kWorking, kWriting };

struct Conn {
    Phase phase = Phase::kFree;
    std::uint32_t generation = 0;
    std::uint64_t tag = 0;
    net::TcpStream stream;
    std::vector<std::byte> in;
    std::vector<std::byte> out;
    std::size_t sent = 0;
    bool sending = false;
    Clock::time_point deadline{};
};

struct Work {
    std::uint64_t tag = 0;
    Call call;
};

struct Done {
    std::uint64_t tag = 0;
    Reply reply;
};

struct Shared {
    std::atomic<bool> stop{false};
    net::SpscMail<Work, kMailRoom> jobs{};
    net::SpscMail<Done, kMailRoom> done{};
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
        item.tag = work.tag;
        item.reply = shared.handler(shared.ctx, work.call);
        wipe_call(work.call);
        if (shared.stop.load(std::memory_order_acquire)) return;
        // Không đầy được: số việc đang bay không vượt kConns <= kMailRoom.
        while (!shared.done.try_push(item)) {
            if (shared.stop.load(std::memory_order_acquire)) return;
            std::this_thread::yield();
        }
        if (shared.reactor != nullptr) shared.reactor->wake();
    }
}

struct Server {
    net::Reactor& reactor;
    Shared& shared;
    secure::ByteView key;
    std::array<Conn, kConns> conns{};
    std::size_t open = 0;
};

[[nodiscard]] Conn* conn_of(Server& server, std::uint64_t tag) noexcept {
    const std::uint64_t low = tag & 0xFFFFFFFFULL;
    if (low < kFirstConnTag || low - kFirstConnTag >= kConns) return nullptr;
    Conn& conn = server.conns[low - kFirstConnTag];
    if (conn.phase == Phase::kFree || conn.tag != tag) return nullptr;
    return &conn;
}

void close_conn(Server& server, Conn& conn) {
    server.reactor.unwatch(conn.tag);
    conn.stream = net::TcpStream{};
    if (!conn.in.empty()) secure::wipe_bytes(conn.in);
    conn.in.clear();
    conn.out.clear();
    conn.sent = 0;
    conn.sending = false;
    conn.phase = Phase::kFree;
    --server.open;
}

void flush(Server& server, Conn& conn) {
    while (!conn.sending && conn.sent < conn.out.size()) {
        const std::span<const std::byte> rest = std::span<const std::byte>{conn.out}.subspan(conn.sent);
        const net::SendOutcome outcome = server.reactor.submit_send(conn.tag, rest);
        if (outcome.state == net::SendState::kReset) {
            close_conn(server, conn);
            return;
        }
        if (outcome.state == net::SendState::kPending) {
            conn.sending = true;
            return;
        }
        if (outcome.sent == 0) {
            close_conn(server, conn);
            return;
        }
        conn.sent += outcome.sent;
    }
    if (!conn.sending && conn.sent >= conn.out.size()) close_conn(server, conn);
}

void begin_reply(Server& server, Conn& conn, std::uint16_t code, std::span<const std::byte> body) {
    std::optional<std::vector<std::byte>> sealed = seal_message(server.key, code, body);
    if (!sealed) {
        close_conn(server, conn);
        return;
    }
    conn.out = std::move(*sealed);
    conn.sent = 0;
    conn.sending = false;
    conn.phase = Phase::kWriting;
    conn.deadline = Clock::now() + kIoLimit;
    flush(server, conn);
}

void take_frame(Server& server, Conn& conn) {
    if (conn.in.size() < 4) return;
    const std::uint32_t size = frame_size(conn.in);
    if (size < kFrameMin || size > kFrameMax) {
        close_conn(server, conn);
        return;
    }
    if (conn.in.size() < std::size_t{4} + size) return;
    // Một yêu cầu một kết nối: byte thừa sau khung là bên kia nói sai giao thức.
    if (conn.in.size() > std::size_t{4} + size) {
        close_conn(server, conn);
        return;
    }
    std::optional<std::vector<std::byte>> plain =
        secure::ipc_open(server.key, std::span<const std::byte>{conn.in}.subspan(4));
    secure::wipe_bytes(conn.in);
    conn.in.clear();
    if (!plain || plain->size() < 2) {
        close_conn(server, conn);
        return;
    }
    Work work;
    work.tag = conn.tag;
    const auto low = static_cast<unsigned>((*plain)[0]);
    const auto high = static_cast<unsigned>((*plain)[1]) << 8U;
    work.call.op = static_cast<Op>(static_cast<std::uint16_t>(low | high));
    work.call.body.assign(plain->begin() + 2, plain->end());
    secure::wipe_bytes(*plain);
    conn.phase = Phase::kWorking;
    if (server.shared.jobs.try_push(work)) return;
    wipe_call(work.call);
    begin_reply(server, conn, static_cast<std::uint16_t>(protocol::ErrorCode::kBusy), {});
}

void read_some(Server& server, Conn& conn) {
    std::array<std::byte, 4096> buffer{};
    const std::size_t room = std::size_t{4} + kFrameMax - conn.in.size();
    const std::size_t want = std::min(room + 1, buffer.size());
    const net::NetResult<std::size_t> got = conn.stream.receive(std::span<std::byte>{buffer}.first(want));
    if (!got) {
        close_conn(server, conn);
        return;
    }
    server.reactor.note_read(conn.tag, *got);
    if (*got == 0) return;
    if (*got > room) {
        close_conn(server, conn);
        return;
    }
    conn.in.insert(conn.in.end(), buffer.begin(), buffer.begin() + static_cast<std::ptrdiff_t>(*got));
    secure::wipe_bytes(buffer);
    take_frame(server, conn);
}

// Có kết nối mới mà đầy ô thì đuổi kết nối đang đọc lâu nhất: kết nối im không giữ được cổng ipc.
// Bên gọi thật gửi trọn khung ngay khi nối nên xong trong một lượt đọc. Ô đang chờ database
// hay đang ghi không bị đuổi.
[[nodiscard]] bool evict_reader(Server& server) {
    Conn* oldest = nullptr;
    for (Conn& conn : server.conns) {
        if (conn.phase != Phase::kReading) continue;
        if (oldest == nullptr || conn.deadline < oldest->deadline) oldest = &conn;
    }
    if (oldest == nullptr) return false;
    close_conn(server, *oldest);
    return true;
}

void accept_all(Server& server) {
    for (;;) {
        net::NetResult<std::optional<net::Accepted>> got = server.reactor.take_accept(kTag);
        if (!got || !got->has_value()) return;
        // Mọi ô đang chờ database hay đang ghi: đóng kết nối mới, bên gọi nhận lỗi và báo Busy.
        if (server.open >= kConns && !evict_reader(server)) continue;
        Conn* free = nullptr;
        std::size_t index = 0;
        for (; index < kConns; ++index) {
            if (server.conns[index].phase == Phase::kFree) {
                free = &server.conns[index];
                break;
            }
        }
        if (free == nullptr) return;
        ++free->generation;
        free->tag = (static_cast<std::uint64_t>(free->generation) << 32U) | (kFirstConnTag + index);
        free->stream = std::move((*got)->stream);
        if (!server.reactor.watch(free->stream.handle(), free->tag)) {
            free->stream = net::TcpStream{};
            continue;
        }
        free->phase = Phase::kReading;
        free->deadline = Clock::now() + kIoLimit;
        free->in.clear();
        ++server.open;
    }
}

void on_event(Server& server, const net::PollEvent& event) {
    Conn* conn = conn_of(server, event.tag);
    if (conn == nullptr) return;
    if (conn->phase == Phase::kWriting && (event.sent > 0 || event.writable)) {
        conn->sent += event.sent;
        conn->sending = false;
        flush(server, *conn);
        return;
    }
    if (event.failed) {
        if (conn->phase == Phase::kWorking) return;
        close_conn(server, *conn);
        return;
    }
    if (event.readable && conn->phase == Phase::kReading) read_some(server, *conn);
}

void drain_done(Server& server) {
    Done item;
    while (server.shared.done.try_pop(item)) {
        Conn* conn = conn_of(server, item.tag);
        if (conn == nullptr || conn->phase != Phase::kWorking) continue;
        begin_reply(server, *conn, item.reply.code, item.reply.body);
        if (!item.reply.body.empty()) secure::wipe_bytes(item.reply.body);
    }
}

void sweep(Server& server, Clock::time_point now) {
    for (Conn& conn : server.conns) {
        if (conn.phase != Phase::kReading && conn.phase != Phase::kWriting) continue;
        if (now >= conn.deadline) close_conn(server, conn);
    }
}

} // namespace

int serve_loop(net::TcpListener& listener, Handler handler, void* ctx, secure::ByteView key) {
    Shared shared;
    shared.handler = handler;
    shared.ctx = ctx;
    net::Reactor reactor;
    shared.reactor = &reactor;
    if (!reactor.watch_listener(listener, kTag)) return 1;
    Server server{.reactor = reactor, .shared = shared, .key = key};
    std::jthread db(db_main, std::ref(shared));
    [[maybe_unused]] const StopDb guard{.shared = &shared, .thread = &db};
    int code = 0;
    net::PollEvents events;
    while (!process::stop_requested()) {
        if (!reactor.wait(std::chrono::milliseconds{200}, events)) {
            code = 1;
            break;
        }
        for (const net::PollEvent& event : events) {
            if (event.tag != kTag) on_event(server, event);
        }
        drain_done(server);
        accept_all(server);
        sweep(server, Clock::now());
    }
    for (Conn& conn : server.conns) {
        if (conn.phase != Phase::kFree) close_conn(server, conn);
    }
    return code;
}

} // namespace game::account
