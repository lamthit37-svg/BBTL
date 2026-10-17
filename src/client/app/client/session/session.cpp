/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/session/session.cpp
 *  PHÂN HỆ   : Client / Session / Session
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phiên mạng của client: luồng nền giữ link tới gate, máy trạng thái thuần
 *    và hàng đợi hai chiều có trần.
 *  - Hàng sự kiện đầy thì bỏ snapshot đi cũ đã có bản sau, giữ tin dừng chưa
 *    bị thay; vẫn đầy thì Lost kQueueFull.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/session/session.hpp"

#include "client/session/machine.hpp"
#include "core/thread.hpp"
#include "link/link.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <optional>
#include <span>
#include <stop_token>
#include <string>
#include <thread>
#include <utility>
#include <variant>
#include <vector>

namespace game::client::session {
namespace {

using Clock = std::chrono::steady_clock;

constexpr int kMaxResume = 4;
constexpr std::chrono::milliseconds kResumeBase{200};

// Hạn nối và bắt tay một cổng.
constexpr net::Milliseconds kConnect{4000};
// Hạn gửi một khung nhỏ.
constexpr net::Milliseconds kSend{3000};
// Mỗi lượt nhận chờ tối đa chừng này: cũng là độ trễ tối đa để luồng nền thấy một lệnh mới khi đang có link.
constexpr net::Milliseconds kSlice{20};
// Chu kỳ Ping lấy từ Welcome.heartbeat, kẹp vào khoảng này để máy chủ độc hại không bắt client gửi dồn hay im quá lâu.
constexpr std::chrono::milliseconds kMinBeat{250};
constexpr std::chrono::milliseconds kMaxBeat{5000};
// Hạn gửi Logout lúc đóng; chậm thì bỏ, máy chủ sẽ tự ngắt khách im.
constexpr net::Milliseconds kFarewell{200};
// Số bản dựng khai trong Hello. Gate chỉ kiểm phiên bản giao thức.
constexpr std::uint32_t kBuild = 1;
// Nền tảng khai trong Hello: máy chủ dùng nó để quyết định ai gặp ai (world.toml [platform]). Mọi máy tính để bàn là
// Windows (dự án chỉ có bản PC Windows); iOS là nền Apple duy nhất của dự án.
#if defined(__ANDROID__)
constexpr protocol::Platform kPlatform = protocol::Platform::kAndroid;
#elif defined(__APPLE__)
constexpr protocol::Platform kPlatform = protocol::Platform::kIos;
#else
constexpr protocol::Platform kPlatform = protocol::Platform::kWindows;
#endif
// Sau khi máy chủ kéo về (Position khi đang chơi) bỏ qua chỗ đứng gửi lên chừng này: luồng vẽ chưa kịp áp vị trí mới
// nên chỗ đứng nó báo vẫn là chỗ cũ, gửi đi chỉ bị kéo về lần nữa.
constexpr std::chrono::milliseconds kPullQuiet{120};
// Nhịp tick của client trong Move/Position (30 mỗi giây, cùng guard::Pace).
constexpr std::int64_t kTicksPerSecond = 30;
// Chỗ đứng chênh dưới chừng này (centimet) so với lần gửi trước là không đổi: không gửi lại.
constexpr float kStillCm = 1.0F;
// Đổi mét của game sang centimet của dây.
constexpr float kCmPerMeter = 100.0F;

// Xoá chữ nhạy cảm khỏi bộ nhớ trước khi giải phóng.
void forget(std::string& secret) noexcept {
    secure::wipe_bytes(std::as_writable_bytes(std::span{secret.data(), secret.size()}));
    secret.clear();
}

void forget(std::vector<std::byte>& bytes) noexcept {
    secure::wipe_bytes(bytes);
    bytes.clear();
}

[[nodiscard]] Fault fault_of(link::LinkError error) noexcept {
    switch (error) {
    case link::LinkError::kNetwork: return Fault::kUnreachable;
    case link::LinkError::kSecure: return Fault::kSecure;
    case link::LinkError::kProtocol: return Fault::kProtocol;
    case link::LinkError::kTimeout: return Fault::kTimeout;
    }
    return Fault::kUnreachable;
}

[[nodiscard]] Ask ask_of(const Command& command) {
    struct Pick {
        Ask operator()(const SignIn&) const noexcept { return Ask::kSignIn; }
        Ask operator()(const Create&) const noexcept { return Ask::kCreate; }
        Ask operator()(const Delete&) const noexcept { return Ask::kDelete; }
        Ask operator()(const Enter&) const noexcept { return Ask::kEnter; }
        Ask operator()(const Drop&) const noexcept { return Ask::kDrop; }
        Ask operator()(const Speak&) const noexcept { return Ask::kSpeak; }
    };
    return std::visit(Pick{}, command);
}

// Mất gói dừng hoặc chết cuối thì client không hội tụ và không biết thực thể đã chết.
// Chỉ bỏ snapshot đi khi đã có bản sau cùng id, hoặc một tin đi thuần khi hàng đầy.

[[nodiscard]] const protocol::GameServerMessage* message_of(const Event& event) noexcept {
    const World* world = std::get_if<World>(&event);
    if (world == nullptr) return nullptr;
    return &world->message;
}

[[nodiscard]] bool batch_has_id(const protocol::EntityPosBatch& batch, std::uint32_t id) noexcept {
    for (const protocol::PosEntry& place : batch.places)
        if (place.id == id) return true;
    return false;
}

[[nodiscard]] bool covers_pos(const protocol::GameServerMessage& message,
    std::uint32_t id) noexcept {
    const auto* pos = std::get_if<protocol::EntityPos>(&message);
    const bool same = pos != nullptr && pos->id == id;
    if (same) return true;
    const auto* batch = std::get_if<protocol::EntityPosBatch>(&message);
    if (batch == nullptr) return false;
    return batch_has_id(*batch, id);
}

[[nodiscard]] bool event_covers_pos(const Event& event, std::uint32_t id) noexcept {
    const protocol::GameServerMessage* message = message_of(event);
    if (message == nullptr) return false;
    return covers_pos(*message, id);
}

[[nodiscard]] bool later_pos(const std::vector<Event>& events, std::size_t at, std::uint32_t id,
    const Event& incoming) noexcept {
    for (std::size_t i = at + 1; i < events.size(); ++i)
        if (event_covers_pos(events[i], id)) return true;
    return event_covers_pos(incoming, id);
}

[[nodiscard]] bool covers_vitals(const protocol::GameServerMessage& message,
    std::uint32_t id) noexcept {
    const auto* vitals = std::get_if<protocol::EntityVitals>(&message);
    if (vitals == nullptr) return false;
    return vitals->id == id;
}

[[nodiscard]] bool event_covers_vitals(const Event& event, std::uint32_t id) noexcept {
    const protocol::GameServerMessage* message = message_of(event);
    if (message == nullptr) return false;
    return covers_vitals(*message, id);
}

[[nodiscard]] bool later_vitals(const std::vector<Event>& events, std::size_t at, std::uint32_t id,
    const Event& incoming) noexcept {
    for (std::size_t i = at + 1; i < events.size(); ++i)
        if (event_covers_vitals(events[i], id)) return true;
    return event_covers_vitals(incoming, id);
}

[[nodiscard]] bool batch_replaced(const protocol::EntityPosBatch& batch,
    const std::vector<Event>& events, std::size_t at, const Event& incoming) noexcept {
    if (batch.places.empty()) return false;
    for (const protocol::PosEntry& place : batch.places)
        if (!later_pos(events, at, place.id, incoming)) return false;
    return true;
}

[[nodiscard]] bool event_is_old(const Event& event, const std::vector<Event>& events,
    std::size_t at, const Event& incoming) noexcept {
    const protocol::GameServerMessage* message = message_of(event);
    if (message == nullptr) return false;
    const auto* pos = std::get_if<protocol::EntityPos>(message);
    if (pos != nullptr) return later_pos(events, at, pos->id, incoming);
    const auto* vitals = std::get_if<protocol::EntityVitals>(message);
    if (vitals != nullptr) return later_vitals(events, at, vitals->id, incoming);
    const auto* batch = std::get_if<protocol::EntityPosBatch>(message);
    if (batch == nullptr) return false;
    return batch_replaced(*batch, events, at, incoming);
}

std::size_t keep_fresh(std::vector<Event>& events, std::size_t at, std::size_t keep,
    const Event& incoming) {
    if (event_is_old(events[at], events, at, incoming)) return keep;
    if (keep != at) events[keep] = std::move(events[at]);
    return keep + 1;
}

void drop_old_snapshots(std::vector<Event>& events, const Event& incoming) {
    std::size_t keep = 0;
    for (std::size_t i = 0; i < events.size(); ++i)
        keep = keep_fresh(events, i, keep, incoming);
    events.resize(keep);
}

[[nodiscard]] bool walk_batch(const protocol::EntityPosBatch& batch) noexcept {
    if (batch.places.empty()) return false;
    for (const protocol::PosEntry& place : batch.places)
        if (place.state != protocol::EntityState::kWalk) return false;
    return true;
}

[[nodiscard]] bool pos_is_walk(const protocol::EntityPos& pos) noexcept {
    return pos.state == protocol::EntityState::kWalk;
}

[[nodiscard]] bool pure_walk(const Event& event) noexcept {
    const protocol::GameServerMessage* message = message_of(event);
    if (message == nullptr) return false;
    const auto* pos = std::get_if<protocol::EntityPos>(message);
    if (pos != nullptr) return pos_is_walk(*pos);
    const auto* batch = std::get_if<protocol::EntityPosBatch>(message);
    if (batch == nullptr) return false;
    return walk_batch(*batch);
}

[[nodiscard]] std::size_t oldest_walk(const std::vector<Event>& events) noexcept {
    for (std::size_t i = 0; i < events.size(); ++i)
        if (pure_walk(events[i])) return i;
    return events.size();
}

void shed_walk(std::vector<Event>& events) {
    if (events.size() < kEventCap) return;
    const std::size_t at = oldest_walk(events);
    if (at >= events.size()) return;
    const auto index = static_cast<std::ptrdiff_t>(at);
    events.erase(events.begin() + index);
}

void note_full(std::vector<Event>& events) {
    events.clear();
    Lost lost;
    lost.fault = Fault::kQueueFull;
    lost.phase = Phase::kLost;
    events.emplace_back(lost);
}

// Một khung đã giải mật mã, tách đầu khung. Đúng một khung và không thừa byte (Link giao đúng một bản ghi).
struct Framed {
    protocol::Frame frame;
    protocol::ByteView body;
};

[[nodiscard]] std::optional<Framed> split_frame(std::span<const std::byte> plain) noexcept {
    const protocol::ByteView bytes{plain.data(), plain.size()};
    const protocol::FrameResult head = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
    if (!head || !head->has_value()) return std::nullopt;
    const protocol::Frame frame = **head;
    if (bytes.size() != protocol::kHeaderBytes + frame.body_bytes) return std::nullopt;
    return Framed{.frame = frame, .body = bytes.subspan(protocol::kHeaderBytes, frame.body_bytes)};
}

// Vé trong Ticket là chữ hex ASCII, phần thừa của mảng là 0.
[[nodiscard]] std::string ticket_text(const protocol::Ticket& ticket) {
    std::string text;
    for (const std::byte letter : ticket.token) {
        if (letter == std::byte{0}) break;
        text.push_back(static_cast<char>(letter));
    }
    return text;
}

// Chỗ đứng luồng game báo (mét của game) và lúc báo: tick của Move tính theo lúc báo, không theo lúc gửi.
struct Footing {
    float x_m = 0.0F;
    float z_m = 0.0F;
    Clock::time_point reported{};
};

// Hai chỗ đứng chênh dưới kStillCm theo cả hai trục là cùng một chỗ.
[[nodiscard]] bool is_same_spot(const Footing& left, const Footing& right) noexcept {
    return std::abs((left.x_m - right.x_m) * kCmPerMeter) < kStillCm &&
           std::abs((left.z_m - right.z_m) * kCmPerMeter) < kStillCm;
}

// Hộp thư giữa luồng game và luồng nền. Khoá chỉ bảo vệ việc đẩy và lấy, không có I/O dưới khoá.
struct Mailbox {
    std::mutex guard;
    std::condition_variable_any wake;
    std::deque<Command> commands;
    std::vector<Event> events;
    // Chỗ đứng mới nhất luồng game báo và luồng nền chưa gửi; bản sau đè bản trước.
    std::optional<Footing> footing;
    std::atomic<std::uint8_t> phase{static_cast<std::uint8_t>(Phase::kIdle)};

    void set_footing(Footing next) {
        const std::scoped_lock lock{guard};
        footing = next;
    }

    [[nodiscard]] std::optional<Footing> take_footing() {
        const std::scoped_lock lock{guard};
        return std::exchange(footing, std::nullopt);
    }

    [[nodiscard]] bool submit(Command command) {
        {
            const std::scoped_lock lock{guard};
            if (commands.size() >= kCommandCap) return false;
            commands.push_back(std::move(command));
        }
        wake.notify_one();
        return true;
    }

    [[nodiscard]] std::optional<Command> pop() {
        const std::scoped_lock lock{guard};
        if (commands.empty()) return std::nullopt;
        Command command = std::move(commands.front());
        commands.pop_front();
        return command;
    }

    // Chờ có lệnh hoặc có yêu cầu dừng.
    void wait_for_command(const std::stop_token& stop) {
        std::unique_lock lock{guard};
        static_cast<void>(wake.wait(lock, stop, [this] { return !commands.empty(); }));
    }

    // Chờ lệnh, dừng, hoặc tới hạn nối lại.
    void wait_until(const std::stop_token& stop, Clock::time_point until) {
        std::unique_lock lock{guard};
        static_cast<void>(wake.wait_until(lock, stop, until, [this] { return !commands.empty(); }));
    }

    // false khi không còn chỗ: hàng bị xoá và chỉ còn Lost{kQueueFull}. Không trả true nếu vừa bỏ
    // tin mới.
    [[nodiscard]] bool push(Event event) {
        const std::scoped_lock lock{guard};
        if (events.size() >= kEventCap) drop_old_snapshots(events, event);
        if (events.size() >= kEventCap) shed_walk(events);
        const bool room = events.size() < kEventCap;
        if (room) events.push_back(std::move(event));
        if (room) return true;
        note_full(events);
        return false;
    }

    [[nodiscard]] std::vector<Event> drain() {
        const std::scoped_lock lock{guard};
        return std::exchange(events, {});
    }
};

// Luồng nền: sở hữu link và pha, chạy tới khi có yêu cầu dừng.
class Worker {
public:
    Worker(Mailbox& box, std::stop_token stop, Timing timing) : box_(&box), stop_(std::move(stop)), timing_(timing) {}

    void take_commands() {
        for (;;) {
            std::optional<Command> command = box_->pop();
            if (!command) return;
            Command held = std::move(*command);
            handle(held);
        }
    }

    void turn() {
        const bool due = !line_ && want_resume_ && Clock::now() >= resume_at_;
        if (due) try_resume();
        if (!line_ && want_resume_) box_->wait_until(stop_, resume_at_);
        if (!line_ && !want_resume_) box_->wait_for_command(stop_);
        take_commands();
        if (line_ && !stop_.stop_requested()) pump();
    }

    void run() {
        core::set_thread_name("net");
        while (!stop_.stop_requested())
            turn();
        farewell();
    }

private:
    void set_phase(Phase next) noexcept {
        phase_ = next;
        box_->phase.store(static_cast<std::uint8_t>(next), std::memory_order_relaxed);
    }

    void emit(Event event) {
        if (box_->push(std::move(event))) return;
        line_.reset();
        roster_.clear();
        set_phase(Phase::kLost);
    }

    void reject(Ask ask, std::uint16_t request, protocol::ErrorCode code) {
        emit(Rejected{.ask = ask, .request = request, .code = code});
    }

    [[nodiscard]] LinkBreak break_of(Fault fault) const noexcept {
        if (fault == Fault::kUnreachable) return LinkBreak::kDown;
        if (fault == Fault::kTimeout) return LinkBreak::kTimeout;
        return LinkBreak::kFatal;
    }

    void wipe_token() noexcept {
        secure::wipe_bytes(token_);
        have_token_ = false;
        token_sent_ = false;
    }

    void give_up() {
        want_resume_ = false;
        tries_ = 0;
        wipe_token();
        line_.reset();
        roster_.clear();
        set_phase(Phase::kLost);
        emit(Lost{.fault = broke_, .phase = broke_where_, .reason = broke_reason_});
    }

    [[nodiscard]] std::chrono::milliseconds resume_wait(int tries) const noexcept {
        int shift = tries - 1;
        if (shift < 0) shift = 0;
        if (shift > 3) shift = 3;
        return kResumeBase * (1 << shift);
    }

    void schedule_resume(Phase where, Fault fault,
        std::optional<protocol::DisconnectReason> reason) {
        if (!want_resume_) {
            broke_ = fault;
            broke_where_ = where;
            broke_reason_ = reason;
        }
        if (tries_ >= kMaxResume) {
            give_up();
            return;
        }
        ++tries_;
        want_resume_ = true;
        resume_at_ = Clock::now() + resume_wait(tries_);
        set_phase(Phase::kResuming);
    }

    // Mất phiên. Đứt socket lúc đang chơi thì hẹn Resume; hết lượt hoặc lỗi nặng thì báo Lost.
    void lose(Fault fault, std::optional<protocol::DisconnectReason> reason = std::nullopt) {
        const Phase where = phase_;
        line_.reset();
        const bool again = resume_again(token_sent_, break_of(fault), where, have_token_);
        if (again) {
            schedule_resume(where, fault, reason);
            return;
        }
        if (!want_resume_) {
            broke_ = fault;
            broke_where_ = where;
            broke_reason_ = reason;
        }
        give_up();
    }

    void try_resume() {
        if (!home_held_ || !have_token_) {
            give_up();
            return;
        }
        link::Link::HelloDesc desc = hello_for(home_game_, home_key_);
        link::LinkResult<link::Link> opened = link::Link::open(desc);
        if (!opened) {
            lose(fault_of(opened.error()));
            return;
        }
        std::vector<std::byte> frame;
        protocol::Resume message;
        message.token = token_;
        if (!protocol::encode(frame, message)) {
            lose(Fault::kProtocol);
            return;
        }
        const link::LinkResult<void> sent = opened->send_frame(frame, kSend);
        if (!sent) {
            lose(fault_of(sent.error()));
            return;
        }
        // Gate xoá phiên ngay khi nhận Resume. Gửi lại token này sẽ nhận kNoSession.
        token_sent_ = true;
        const Clock::time_point now = Clock::now();
        line_.emplace(std::move(*opened));
        heard_ = now;
        next_ping_ = now + beat_;
        arm_reply();
    }

    using Token = std::array<std::byte, protocol::kSessionStartTokenBytes>;

    void keep_token(const Token& token) noexcept {
        token_ = token;
        have_token_ = true;
        token_sent_ = false;
        tries_ = 0;
        want_resume_ = false;
    }

    void arm_reply() noexcept { reply_by_ = Clock::now() + timing_.reply; }

    [[nodiscard]] link::Link::HelloDesc hello_for(net::Endpoint peer, const secure::PublicKey& key) const {
        link::Link::HelloDesc desc;
        desc.peer = peer;
        desc.server = key;
        desc.build = kBuild;
        desc.platform = kPlatform;
        desc.timeout = kConnect;
        desc.stop = stop_;
        return desc;
    }

    void handle(Command& command) {
        const Ask ask = ask_of(command);
        if (!allows(phase_, ask)) {
            if (SignIn* request = std::get_if<SignIn>(&command)) forget(request->password);
            reject(ask, 0, protocol::ErrorCode::kOutOfOrder);
            return;
        }
        std::visit([this](auto& held) { perform(held); }, command);
    }

    void perform(SignIn& request) {
        want_resume_ = false;
        wipe_token();
        home_game_ = request.gate.game;
        home_key_ = request.gate.key;
        home_held_ = true;
        close_link();
        set_phase(begin(phase_, Ask::kSignIn));
        std::optional<std::string> ticket = obtain_ticket(request);
        forget(request.password);
        if (!ticket) return;
        open_game(request, *ticket);
        forget(*ticket);
    }

    void perform(Create& request) {
        protocol::CreateCharacter message;
        message.name = std::move(request.name);
        message.gender = request.gender;
        message.face = request.face;
        message.hair = request.hair;
        send_request(Ask::kCreate, message);
    }

    void perform(Delete& request) { send_request(Ask::kDelete, protocol::DeleteCharacter{.character = request.character}); }

    void perform(Enter& request) {
        const auto found = std::ranges::find(roster_, request.character, &protocol::CharacterSummary::id);
        if (found == roster_.end()) {
            reject(Ask::kEnter, protocol::EnterGame::kKind, protocol::ErrorCode::kNoSuchCharacter);
            return;
        }
        entering_ = *found;
        send_request(Ask::kEnter, protocol::EnterGame{.character = request.character});
    }

    void perform(Drop& /*request*/) {
        want_resume_ = false;
        wipe_token();
        farewell();
        close_link();
        set_phase(Phase::kIdle);
    }

    // Hộp thoại và sổ nhiệm vụ: gửi một khung rồi thôi, không chờ trả lời (máy chủ trả bằng tin thế giới hay Reject).
    void perform(Speak& request) {
        std::vector<std::byte> frame;
        const bool is_encoded = std::visit([&frame](const auto& message) { return protocol::encode(frame, message).has_value(); },
            request.speech);
        if (!is_encoded) {
            reject(Ask::kSpeak, 0, protocol::ErrorCode::kMalformed);
            return;
        }
        if (!line_) {
            reject(Ask::kSpeak, 0, protocol::ErrorCode::kOutOfOrder);
            return;
        }
        const link::LinkResult<void> sent = line_->send_frame(frame, kSend);
        if (!sent) lose(fault_of(sent.error()));
    }

    void close_link() {
        line_.reset();
        roster_.clear();
    }

    // Gửi nhẹ nhàng Logout để máy chủ không phải chờ hạn im lặng. Lỗi bị bỏ: link sắp đóng, không ai nghe.
    void farewell() {
        if (!line_) return;
        std::vector<std::byte> frame;
        if (!protocol::encode(frame, protocol::Logout{})) return;
        const link::LinkResult<void> sent = line_->send_frame(frame, kFarewell);
        static_cast<void>(sent);
    }

    template <typename Message>
    void send_request(Ask ask, const Message& message) {
        std::vector<std::byte> frame;
        if (!protocol::encode(frame, message)) {
            reject(ask, Message::kKind, protocol::ErrorCode::kMalformed);
            return;
        }
        if (!line_) {
            reject(ask, Message::kKind, protocol::ErrorCode::kOutOfOrder);
            return;
        }
        const link::LinkResult<void> sent = line_->send_frame(frame, kSend);
        if (!sent) {
            lose(fault_of(sent.error()));
            return;
        }
        pending_ = ask;
        set_phase(begin(phase_, ask));
        arm_reply();
    }

    // Cổng xác thực: SignIn lấy vé. Báo Rejected hay Lost và trả rỗng khi không lấy được.
    [[nodiscard]] std::optional<std::string> obtain_ticket(const SignIn& request) {
        link::LinkResult<link::Link> opened = link::Link::open(hello_for(request.gate.auth, request.gate.key));
        if (!opened) {
            lose(fault_of(opened.error()));
            return std::nullopt;
        }
        std::vector<std::byte> frame;
        const protocol::SignIn message{.account = request.account, .password = request.password};
        if (!protocol::encode(frame, message)) {
            forget(frame);
            reject(Ask::kSignIn, protocol::SignIn::kKind, protocol::ErrorCode::kMalformed);
            set_phase(Phase::kIdle);
            return std::nullopt;
        }
        const link::LinkResult<void> sent = opened->send_frame(frame, kSend);
        forget(frame);
        if (!sent) {
            lose(fault_of(sent.error()));
            return std::nullopt;
        }
        return await_ticket(*opened);
    }

    [[nodiscard]] std::optional<std::string> await_ticket(link::Link& auth) {
        const Clock::time_point until = Clock::now() + timing_.reply;
        while (!stop_.stop_requested()) {
            link::LinkResult<std::vector<std::byte>> got = auth.receive_frame(kSlice);
            if (!got && got.error() == link::LinkError::kTimeout) {
                if (Clock::now() < until) continue;
                lose(Fault::kTimeout);
                return std::nullopt;
            }
            if (!got) {
                lose(fault_of(got.error()));
                return std::nullopt;
            }
            return take_ticket(*got);
        }
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> take_ticket(std::span<const std::byte> plain) {
        const std::optional<Framed> split = split_frame(plain);
        if (!split) {
            lose(Fault::kProtocol);
            return std::nullopt;
        }
        protocol::AuthServerResult decoded = protocol::decode_auth_server(split->frame, split->body);
        if (!decoded) {
            lose(Fault::kProtocol);
            return std::nullopt;
        }
        if (const auto* ticket = std::get_if<protocol::Ticket>(&*decoded)) return ticket_text(*ticket);
        if (const auto* refused = std::get_if<protocol::Reject>(&*decoded)) {
            reject(Ask::kSignIn, refused->request, refused->code);
            set_phase(Phase::kIdle);
            return std::nullopt;
        }
        if (const auto* bye = std::get_if<protocol::Goodbye>(&*decoded)) {
            lose(Fault::kGoodbye, bye->reason);
            return std::nullopt;
        }
        lose(Fault::kProtocol);
        return std::nullopt;
    }

    // Cổng game: Login bằng vé. Máy chủ đáp CharacterList (pump xử lý) hoặc Reject.
    void open_game(const SignIn& request, const std::string& ticket) {
        link::LinkResult<link::Link> opened = link::Link::open(hello_for(request.gate.game, request.gate.key));
        if (!opened) {
            lose(fault_of(opened.error()));
            return;
        }
        std::vector<std::byte> frame;
        const protocol::Login message{.account = request.account, .ticket = ticket};
        if (!protocol::encode(frame, message)) {
            forget(frame);
            reject(Ask::kSignIn, protocol::Login::kKind, protocol::ErrorCode::kMalformed);
            set_phase(Phase::kIdle);
            return;
        }
        const link::LinkResult<void> sent = opened->send_frame(frame, kSend);
        forget(frame);
        if (!sent) {
            lose(fault_of(sent.error()));
            return;
        }
        const Clock::time_point now = Clock::now();
        const auto beat = std::chrono::duration_cast<std::chrono::milliseconds>(opened->welcome().heartbeat);
        beat_ = std::clamp(beat, kMinBeat, kMaxBeat);
        line_.emplace(std::move(*opened));
        pending_ = Ask::kSignIn;
        heard_ = now;
        next_ping_ = now + beat_;
        arm_reply();
    }

    void pump() {
        if (!line_) return;
        link::LinkResult<std::vector<std::byte>> got = line_->receive_frame(kSlice);
        const Clock::time_point now = Clock::now();
        if (got) {
            heard_ = now;
            on_frame(*got);
        } else if (got.error() != link::LinkError::kTimeout) {
            lose(fault_of(got.error()));
        }
        if (line_) check_deadlines(now);
        if (line_) ping_if_due(now);
        if (line_) move_if_due(now);
    }

    [[nodiscard]] bool is_waiting() const noexcept {
        const bool signing = phase_ == Phase::kSigningIn || phase_ == Phase::kEditing;
        return signing || phase_ == Phase::kEntering || phase_ == Phase::kResuming;
    }

    void check_deadlines(Clock::time_point now) {
        if (is_waiting() && now > reply_by_) lose(Fault::kTimeout);
        if (line_ && !is_waiting() && now - heard_ > timing_.silence) lose(Fault::kTimeout);
    }

    void ping_if_due(Clock::time_point now) {
        if (!line_ || now < next_ping_) return;
        next_ping_ = now + beat_;
        // client_time đi trên dây là u32; giữ trong 31 bit để không bao giờ ngoài miền.
        constexpr std::int64_t kMask = 0x7FFFFFFF;
        const std::int64_t since = std::chrono::duration_cast<std::chrono::milliseconds>(now - epoch_).count();
        std::vector<std::byte> frame;
        const protocol::Ping ping{.client_time = std::chrono::milliseconds{since & kMask}};
        if (!protocol::encode(frame, ping)) return;
        const link::LinkResult<void> sent = line_->send_frame(frame, kSend);
        if (!sent) lose(fault_of(sent.error()));
    }

    // Tick client (30 mỗi giây) của chỗ đứng báo lúc reported: tick gốc cộng thời gian từ gốc, làm tròn lên.
    // Gốc là Move gửi gần nhất nên hiệu tick giữa hai Move không ít hơn thời gian thật giữa hai chỗ đứng; làm
    // tròn tick tuyệt đối thì hiệu hụt tới gần một tick và guard::Pace kéo về khi đang chạy. Khai dư không
    // mua thêm quãng: máy chủ cắt theo đồng hồ của nó (G2 trong guard/pace.hpp).
    [[nodiscard]] std::uint32_t client_tick(Clock::time_point reported) const noexcept {
        constexpr std::int64_t kMicros = 1'000'000;
        const std::int64_t elapsed = std::chrono::duration_cast<std::chrono::microseconds>(reported - tick_at_).count();
        const std::int64_t ticks = ((std::max<std::int64_t>(elapsed, 0) * kTicksPerSecond) + kMicros - 1) / kMicros;
        return static_cast<std::uint32_t>(static_cast<std::uint64_t>(tick_base_) + static_cast<std::uint64_t>(ticks));
    }

    // Máy chủ đặt chỗ đứng (vào game, kéo về, dịch chuyển): đổi gốc tick, bỏ chỗ đứng cũ chưa gửi.
    void on_placed(const protocol::Position& spot, Clock::time_point now) {
        tick_base_ = spot.tick;
        tick_at_ = now;
        static_cast<void>(box_->take_footing());
        sent_ = Footing{.x_m = spot.x_cm / kCmPerMeter, .z_m = spot.z_cm / kCmPerMeter};
        quiet_until_ = now + kPullQuiet;
    }

    // Gửi Move cho chỗ đứng mới nhất khi đã vào game, đủ nhịp và chỗ đứng đã đổi. Chỗ đứng không hữu hạn bị bỏ.
    void move_if_due(Clock::time_point now) {
        if (!line_ || phase_ != Phase::kInGame || now < next_move_ || now < quiet_until_) return;
        const std::optional<Footing> latest = box_->take_footing();
        if (!latest) return;
        const float x_cm = latest->x_m * kCmPerMeter;
        const float z_cm = latest->z_m * kCmPerMeter;
        if (!std::isfinite(x_cm) || !std::isfinite(z_cm)) return;
        if (sent_ && is_same_spot(*sent_, *latest)) return;
        std::vector<std::byte> frame;
        const protocol::Move move{.x_cm = x_cm, .z_cm = z_cm, .tick = client_tick(latest->reported)};
        if (!protocol::encode(frame, move)) return;
        const link::LinkResult<void> sent = line_->send_frame(frame, kSend);
        if (!sent) {
            lose(fault_of(sent.error()));
            return;
        }
        sent_ = *latest;
        tick_base_ = move.tick;
        tick_at_ = latest->reported;
        next_move_ = now + kMoveEvery;
    }

    void on_frame(std::span<const std::byte> plain) {
        const std::optional<Framed> split = split_frame(plain);
        if (!split) {
            lose(Fault::kProtocol);
            return;
        }
        protocol::GameServerResult decoded = protocol::decode_game_server(split->frame, split->body);
        if (!decoded) {
            lose(Fault::kProtocol);
            return;
        }
        const Phase before = phase_;
        const Step step = on_server(before, *decoded);
        if (step.outcome == Outcome::kQuiet) {
            set_phase(step.next);
        } else if (step.outcome == Outcome::kDeliver) {
            set_phase(step.next);
            deliver(before, std::move(*decoded));
        } else if (step.outcome == Outcome::kRejected) {
            answer_reject(before, step, std::get<protocol::Reject>(*decoded));
        } else if (step.outcome == Outcome::kClosed) {
            lose(Fault::kGoodbye, std::get<protocol::Goodbye>(*decoded).reason);
        } else {
            lose(Fault::kProtocol);
        }
    }

    void deliver(Phase before, protocol::GameServerMessage message) {
        if (auto* list = std::get_if<protocol::CharacterList>(&message)) {
            roster_ = list->characters;
            emit(Roster{.characters = std::move(list->characters)});
            return;
        }
        const auto* started = std::get_if<protocol::SessionStart>(&message);
        if (started != nullptr) keep_token(started->token);
        const auto* spot = std::get_if<protocol::Position>(&message);
        if (spot != nullptr) on_placed(*spot, Clock::now());
        if (spot != nullptr && before == Phase::kEntering) {
            emit(Entered{.character = entering_, .position = *spot});
            return;
        }
        emit(World{.message = std::move(message)});
    }

    void answer_reject(Phase before, const Step& step, const protocol::Reject& refused) {
        if (before == Phase::kInGame) {
            emit(World{.message = refused});
            return;
        }
        set_phase(step.next);
        if (step.next == Phase::kIdle || step.next == Phase::kLost) {
            want_resume_ = false;
            wipe_token();
            close_link();
        }
        reject(pending_, refused.request, refused.code);
    }

    Mailbox* box_;
    std::stop_token stop_;
    Timing timing_;
    std::optional<link::Link> line_;
    Phase phase_ = Phase::kIdle;
    std::vector<protocol::CharacterSummary> roster_;
    protocol::CharacterSummary entering_;
    Ask pending_ = Ask::kDrop;
    std::chrono::milliseconds beat_{1000};
    Clock::time_point epoch_ = Clock::now();
    Clock::time_point heard_ = epoch_;
    Clock::time_point next_ping_ = epoch_;
    Clock::time_point reply_by_ = epoch_;
    // Gốc tick của Move: tick của Move gửi gần nhất và lúc báo chỗ đứng đó, hoặc tick của Position và lúc nhận.
    std::uint32_t tick_base_ = 0;
    Clock::time_point tick_at_ = epoch_;
    // Chỗ đứng đã gửi hay máy chủ đã giao gần nhất; so để không gửi lại chỗ cũ.
    std::optional<Footing> sent_;
    Clock::time_point next_move_ = epoch_;
    Clock::time_point quiet_until_ = epoch_;
    net::Endpoint home_game_{};
    secure::PublicKey home_key_{};
    bool home_held_ = false;
    Token token_{};
    bool have_token_ = false;
    bool token_sent_ = false;
    bool want_resume_ = false;
    int tries_ = 0;
    Clock::time_point resume_at_ = epoch_;
    Fault broke_ = Fault::kUnreachable;
    Phase broke_where_ = Phase::kIdle;
    std::optional<protocol::DisconnectReason> broke_reason_{};
};

} // namespace

struct Session::Shared {
    Mailbox box;
    // Khai sau hộp thư: huỷ luồng (yêu cầu dừng rồi chờ) xảy ra trước khi hộp thư bị huỷ.
    std::jthread thread;
};

Session::Session(Timing timing) : shared_(std::make_unique<Shared>()) {
    Mailbox& box = shared_->box;
    shared_->thread = std::jthread([&box, timing](std::stop_token stop) { Worker{box, std::move(stop), timing}.run(); });
}

Session::~Session() = default;

bool Session::submit(Command command) {
    return shared_->box.submit(std::move(command));
}

std::vector<Event> Session::drain() {
    return shared_->box.drain();
}

void Session::report(float x_m, float z_m) {
    shared_->box.set_footing(Footing{.x_m = x_m, .z_m = z_m, .reported = Clock::now()});
}

Phase Session::phase() const noexcept {
    return static_cast<Phase>(shared_->box.phase.load(std::memory_order_relaxed));
}

} // namespace game::client::session
