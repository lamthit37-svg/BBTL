/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/support/fake_gate.hpp
 *  PHÂN HỆ   : Support / Fake Gate
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Máy chủ giả cho test của client: nghe hai cổng loopback (xác thực và
 *    game), bắt tay bảo mật thật, nói đúng khung và danh mục tin của protocol,
 *    và giữ tài khoản, vé, nhân vật trong bộ nhớ theo đúng trình tự gate thật
 *    (Hello, SignIn, Ticket; Hello, Login, CharacterList, CreateCharacter,
 *    EnterGame, SessionStart, UiConfig, Position, SceneEnter). Không phải bản
 *    sao của gate: không kiểm tốc độ đi, không zone.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chế độ Mode cho test chèn lỗi (rác, sai trình tự, im lặng, đóng đột ngột, tràn tin) vào đúng chỗ máy chủ thật có
// thể hỏng. Mọi cổng nghe 127.0.0.1 cổng 0 (bẫy mục 11 của AGENTS.md): hệ điều hành cấp, đọc lại bằng game()/auth().

#pragma once

#include "core/check.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <format>
#include <map>
#include <mutex>
#include <optional>
#include <span>
#include <stop_token>
#include <string>
#include <thread>
#include <utility>
#include <variant>
#include <vector>

namespace game::test {

// Một kết nối đã bắt tay, phía máy chủ: nhận một bản ghi (một khung) và gửi khung đã niêm.
class ServerLine {
public:
    // Chờ một kết nối tới listener, bắt tay. nullopt khi có yêu cầu dừng hoặc bắt tay hỏng.
    [[nodiscard]] static std::optional<ServerLine> accept(net::TcpListener& listener, const secure::Identity& identity,
        const std::stop_token& stop) {
        net::PollSet poll;
        if (!poll.add(listener.handle(), 1)) return std::nullopt;
        while (!stop.stop_requested()) {
            net::NetResult<std::optional<net::Accepted>> accepted = listener.accept();
            if (!accepted) return std::nullopt;
            if (accepted->has_value()) {
                ServerLine line{std::move((*accepted)->stream)};
                if (!line.shake(identity, stop)) return std::nullopt;
                return line;
            }
            net::PollEvents events;
            if (!poll.wait(std::chrono::milliseconds{50}, events)) return std::nullopt;
        }
        return std::nullopt;
    }

    // Bản ghi kế tiếp đã giải mã (đúng một khung). nullopt khi quá hạn hoặc kết nối đã đóng (is_closed).
    [[nodiscard]] std::optional<std::vector<std::byte>> receive(std::chrono::milliseconds wait) {
        if (!pipe_) {
            closed_ = true;
            return std::nullopt;
        }
        const auto until = std::chrono::steady_clock::now() + wait;
        net::PollSet poll;
        if (!poll.add(stream_.handle(), 1)) {
            closed_ = true;
            return std::nullopt;
        }
        std::array<std::byte, secure::kMaxPlainBytes> plain{};
        while (true) {
            const secure::OpenResult opened = pipe_->open_bytes(std::span{inbox_.data(), inbox_.size()}, plain);
            if (!opened) {
                closed_ = true;
                return std::nullopt;
            }
            if (opened->consumed > 0) inbox_.erase(inbox_.begin(), inbox_.begin() + static_cast<std::ptrdiff_t>(opened->consumed));
            if (opened->written > 0) {
                return std::vector<std::byte>(plain.begin(), plain.begin() + static_cast<std::ptrdiff_t>(opened->written));
            }
            if (opened->consumed > 0) continue;
            const auto left = std::chrono::duration_cast<std::chrono::milliseconds>(until - std::chrono::steady_clock::now());
            if (left.count() <= 0) return std::nullopt;
            std::array<std::byte, 2048> chunk{};
            const net::NetResult<std::size_t> got = stream_.receive(chunk);
            if (!got) {
                closed_ = true;
                return std::nullopt;
            }
            if (*got > 0) {
                inbox_.insert(inbox_.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(*got));
                continue;
            }
            net::PollEvents events;
            if (!poll.wait(std::min(left, std::chrono::milliseconds{50}), events)) {
                closed_ = true;
                return std::nullopt;
            }
        }
    }

    // Niêm rồi gửi một khung đã mã hoá thô (plain là đúng bytes của khung, hoặc rác khi test cần).
    [[nodiscard]] bool send_raw(std::span<const std::byte> plain) {
        if (!pipe_) return false;
        std::array<std::byte, secure::kMaxRecordBytes> record{};
        const secure::SealResult wrote = pipe_->seal(plain, record);
        if (!wrote) return false;
        return send_all(std::span{record}.first(*wrote));
    }

    template <typename Message>
    [[nodiscard]] bool send(const Message& message) {
        std::vector<std::byte> frame;
        if (!protocol::encode(frame, message)) return false;
        return send_raw(frame);
    }

    [[nodiscard]] bool is_closed() const noexcept { return closed_; }

    // Đóng đột ngột (RST), như mạng đứt.
    void abort() noexcept {
        stream_.abort();
        closed_ = true;
    }

private:
    explicit ServerLine(net::TcpStream stream) : stream_(std::move(stream)) {}

    [[nodiscard]] bool shake(const secure::Identity& identity, const std::stop_token& stop) {
        std::vector<std::byte> hello;
        net::PollSet poll;
        if (!poll.add(stream_.handle(), 1)) return false;
        while (hello.size() < secure::kClientHelloBytes) {
            if (stop.stop_requested()) return false;
            std::array<std::byte, 64> chunk{};
            const net::NetResult<std::size_t> got = stream_.receive(chunk);
            if (!got) return false;
            if (*got > 0) {
                hello.insert(hello.end(), chunk.begin(), chunk.begin() + static_cast<std::ptrdiff_t>(*got));
                continue;
            }
            net::PollEvents events;
            if (!poll.wait(std::chrono::milliseconds{50}, events)) return false;
        }
        secure::ServerHandshake handshake(identity);
        const secure::AbsorbResult absorbed = handshake.absorb(std::span{hello.data(), secure::kClientHelloBytes});
        if (!absorbed || !handshake.is_done()) return false;
        if (!send_all(handshake.reply())) return false;
        pipe_.emplace(handshake.take_keys());
        return true;
    }

    [[nodiscard]] bool send_all(std::span<const std::byte> data) {
        net::PollSet poll;
        if (!poll.add(stream_.handle(), 1)) return false;
        std::size_t sent = 0;
        while (sent < data.size()) {
            const net::NetResult<std::size_t> step = stream_.send(data.subspan(sent));
            if (!step) {
                closed_ = true;
                return false;
            }
            if (*step > 0) {
                sent += *step;
                continue;
            }
            poll.want_write(1, true);
            net::PollEvents events;
            if (!poll.wait(std::chrono::milliseconds{1000}, events)) return false;
        }
        return true;
    }

    net::TcpStream stream_;
    std::optional<secure::RecordPipe> pipe_;
    std::vector<std::byte> inbox_;
    bool closed_ = false;
};

// Cách máy chủ giả đáp. Chỉ ảnh hưởng nhánh được nêu; mọi tin khác vẫn đáp như kNormal.
enum class Mode : std::uint8_t {
    kNormal,
    // Sau Login gửi một bản ghi hợp lệ nhưng nội dung không phải khung.
    kGarbage,
    // Sau Login gửi Position thay vì CharacterList.
    kOutOfOrder,
    // Nhận Login rồi im lặng.
    kMute,
    // Nhận Login rồi đóng đột ngột.
    kHangUp,
    // Sau EnterGame gửi Position rồi Goodbye(kKicked).
    kGoodbye,
    // Sau Position gửi 1500 EntityPos rồi Goodbye: tin có thể bỏ, tin quan trọng phải còn.
    kFloodDroppable,
    // Sau Position gửi 400 EntityAppear: hàng đợi sự kiện của client phải tràn.
    kFloodCritical,
    // Sau SceneEnter (self_id 100) gửi một quái hiện, đi, mất sinh lực rồi biến mất, như zone thật.
    kWorld,
    // Như kNormal, nhưng Move đầu tiên bị kéo về bằng Position tick 1000, như gate khi Pace từ chối bước.
    kPullBack,
};

class FakeGate {
public:
    FakeGate() {
        auth_listener_ = open_listener();
        game_listener_ = open_listener();
        auth_thread_ = std::jthread([this](const std::stop_token& stop) { serve(auth_listener_, stop, false); });
        game_thread_ = std::jthread([this](const std::stop_token& stop) { serve(game_listener_, stop, true); });
    }

    ~FakeGate() {
        auth_thread_.request_stop();
        game_thread_.request_stop();
    }

    FakeGate(const FakeGate&) = delete;
    FakeGate& operator=(const FakeGate&) = delete;
    FakeGate(FakeGate&&) = delete;
    FakeGate& operator=(FakeGate&&) = delete;

    [[nodiscard]] net::Endpoint game() const { return endpoint_of(game_listener_); }
    [[nodiscard]] net::Endpoint auth() const { return endpoint_of(auth_listener_); }
    [[nodiscard]] secure::PublicKey key() const { return identity_.public_key(); }
    void set_mode(Mode mode) noexcept { mode_.store(mode, std::memory_order_relaxed); }
    // Số Ping và số Logout đã nhận, để test kiểm nhịp tim và lời chào tạm biệt.
    [[nodiscard]] int pings() const noexcept { return pings_.load(std::memory_order_relaxed); }
    [[nodiscard]] int logouts() const noexcept { return logouts_.load(std::memory_order_relaxed); }
    // Move đã nhận theo thứ tự, và nền tảng khai trong Hello gần nhất của cổng game (0 khi chưa có).
    [[nodiscard]] std::vector<protocol::Move> moves() {
        const std::scoped_lock lock{guard_};
        return moves_;
    }
    [[nodiscard]] std::uint8_t game_platform() {
        const std::scoped_lock lock{guard_};
        return game_platform_;
    }

private:
    static constexpr std::int32_t kScene = 2;
    static constexpr float kStartX = 16500.0F;
    static constexpr float kStartZ = 16900.0F;
    static constexpr std::uint32_t kSelfId = 100;
    static constexpr std::uint32_t kPulledTick = 1000;

    [[nodiscard]] static secure::Identity make_identity() {
        secure::Result<secure::Identity> made = secure::Identity::generate();
        core::check(made.has_value(), "FakeGate: tạo được khoá danh tính");
        return std::move(*made);
    }

    [[nodiscard]] static net::TcpListener open_listener() {
        net::NetResult<net::TcpListener> opened = net::TcpListener::open({.address = {127, 0, 0, 1}, .port = 0});
        core::check(opened.has_value(), "FakeGate: nghe được cổng loopback");
        return std::move(*opened);
    }

    [[nodiscard]] static net::Endpoint endpoint_of(const net::TcpListener& listener) {
        const net::NetResult<net::Endpoint> local = listener.local();
        core::check(local.has_value(), "FakeGate: đọc được cổng đã nghe");
        return *local;
    }

    void serve(net::TcpListener& listener, const std::stop_token& stop, bool is_game) {
        while (!stop.stop_requested()) {
            std::optional<ServerLine> line = ServerLine::accept(listener, identity_, stop);
            if (!line) continue;
            if (is_game) {
                serve_game(*line, stop);
            } else {
                serve_auth(*line, stop);
            }
        }
    }

    struct Parsed {
        protocol::Frame frame;
        protocol::ByteView body;
    };

    [[nodiscard]] static std::optional<Parsed> parse(const std::vector<std::byte>& plain) {
        const protocol::ByteView bytes{plain.data(), plain.size()};
        const protocol::FrameResult head = protocol::peek_frame(bytes, protocol::kMaxBodyBytes);
        if (!head || !head->has_value()) return std::nullopt;
        const protocol::Frame frame = **head;
        if (bytes.size() != protocol::kHeaderBytes + frame.body_bytes) return std::nullopt;
        return Parsed{.frame = frame, .body = bytes.subspan(protocol::kHeaderBytes, frame.body_bytes)};
    }

    [[nodiscard]] static protocol::Welcome welcome() {
        protocol::Welcome made;
        made.version = protocol::kVersion;
        made.heartbeat = std::chrono::seconds{1};
        return made;
    }

    [[nodiscard]] std::string issue_ticket(const std::string& account) {
        const std::scoped_lock lock{guard_};
        std::string hex = std::format("{:016x}", ++ticket_counter_);
        tickets_.emplace(hex, account);
        return hex;
    }

    [[nodiscard]] static protocol::Ticket ticket_of(const std::string& hex) {
        protocol::Ticket ticket;
        for (std::size_t at = 0; at < hex.size() && at < ticket.token.size(); ++at) {
            ticket.token.at(at) = static_cast<std::byte>(hex[at]);
        }
        return ticket;
    }

    void serve_auth(ServerLine& line, const std::stop_token& stop) {
        while (!stop.stop_requested() && !line.is_closed()) {
            const std::optional<std::vector<std::byte>> plain = line.receive(std::chrono::milliseconds{100});
            if (!plain) continue;
            const std::optional<Parsed> split = parse(*plain);
            if (!split) return;
            const protocol::AuthClientResult decoded = protocol::decode_auth_client(split->frame, split->body);
            if (!decoded) return;
            if (std::holds_alternative<protocol::Hello>(*decoded)) {
                if (!line.send(welcome())) return;
            } else if (const auto* sign = std::get_if<protocol::SignIn>(&*decoded)) {
                if (!answer_sign_in(line, sign->account, sign->password)) return;
            } else if (const auto* create = std::get_if<protocol::CreateAccount>(&*decoded)) {
                if (!answer_sign_in(line, create->account, create->password)) return;
            }
        }
    }

    // Tài khoản chưa có thì tạo (auto_register); có mà sai mật khẩu thì Reject.
    [[nodiscard]] bool answer_sign_in(ServerLine& line, const std::string& account, const std::string& password) {
        bool is_known = false;
        bool is_match = false;
        {
            const std::scoped_lock lock{guard_};
            const auto found = passwords_.find(account);
            is_known = found != passwords_.end();
            is_match = is_known && found->second == password;
            if (!is_known) passwords_.emplace(account, password);
        }
        if (is_known && !is_match) {
            return line.send(protocol::Reject{.request = protocol::SignIn::kKind, .code = protocol::ErrorCode::kBadCredentials});
        }
        return line.send(ticket_of(issue_ticket(account)));
    }

    [[nodiscard]] protocol::CharacterList list_of(const std::string& account) {
        const std::scoped_lock lock{guard_};
        return protocol::CharacterList{.characters = roster_[account]};
    }

    void serve_game(ServerLine& line, const std::stop_token& stop) {
        std::string account;
        while (!stop.stop_requested() && !line.is_closed()) {
            const std::optional<std::vector<std::byte>> plain = line.receive(std::chrono::milliseconds{100});
            if (!plain) continue;
            const std::optional<Parsed> split = parse(*plain);
            if (!split) return;
            const protocol::GameClientResult decoded = protocol::decode_game_client(split->frame, split->body);
            if (!decoded) return;
            if (!answer_game(line, account, *decoded)) return;
        }
    }

    [[nodiscard]] bool answer_login(ServerLine& line, std::string& account, const protocol::Login& login) {
        std::optional<std::string> owner;
        {
            const std::scoped_lock lock{guard_};
            const auto found = tickets_.find(login.ticket);
            if (found != tickets_.end() && found->second == login.account) owner = found->second;
        }
        if (!owner) {
            return line.send(protocol::Reject{.request = protocol::Login::kKind, .code = protocol::ErrorCode::kNotAuthenticated});
        }
        account = *owner;
        const Mode mode = mode_.load(std::memory_order_relaxed);
        if (mode == Mode::kGarbage) {
            const std::array<std::byte, 24> junk{};
            return line.send_raw(junk);
        }
        if (mode == Mode::kOutOfOrder) return line.send(protocol::Position{.x_cm = 1.0F, .z_cm = 1.0F, .tick = 0});
        if (mode == Mode::kMute) return true;
        if (mode == Mode::kHangUp) {
            line.abort();
            return false;
        }
        return line.send(list_of(account));
    }

    [[nodiscard]] bool answer_create(ServerLine& line, const std::string& account, const protocol::CreateCharacter& create) {
        {
            const std::scoped_lock lock{guard_};
            const bool is_taken = std::ranges::any_of(
                roster_, [&](const auto& entry) { return std::ranges::any_of(entry.second, [&](const auto& one) { return one.name == create.name; }); });
            if (is_taken) {
                const protocol::Reject refused{.request = protocol::CreateCharacter::kKind, .code = protocol::ErrorCode::kNameTaken};
                return line.send(refused);
            }
            protocol::CharacterSummary made;
            made.id = next_character_++;
            made.name = create.name;
            made.level = 1;
            made.gender = create.gender;
            made.face = create.face;
            made.hair = create.hair;
            made.school = 9;
            made.scene = static_cast<std::uint16_t>(kScene);
            roster_[account].push_back(std::move(made));
        }
        return line.send(list_of(account));
    }

    [[nodiscard]] bool answer_delete(ServerLine& line, const std::string& account, std::uint64_t id) {
        {
            const std::scoped_lock lock{guard_};
            std::vector<protocol::CharacterSummary>& mine = roster_[account];
            std::erase_if(mine, [&](const protocol::CharacterSummary& one) { return one.id == id; });
        }
        return line.send(list_of(account));
    }

    [[nodiscard]] bool answer_enter(ServerLine& line, const std::string& account, std::uint64_t id) {
        bool is_known = false;
        {
            const std::scoped_lock lock{guard_};
            const std::vector<protocol::CharacterSummary>& mine = roster_[account];
            is_known = std::ranges::any_of(mine, [&](const protocol::CharacterSummary& one) { return one.id == id; });
        }
        if (!is_known) {
            return line.send(protocol::Reject{.request = protocol::EnterGame::kKind, .code = protocol::ErrorCode::kNoSuchCharacter});
        }
        protocol::SessionStart session;
        session.token.fill(std::byte{0x5A});
        const bool opened = line.send(session) && line.send(protocol::UiConfig{.avatar_frame = protocol::AvatarFrame::kSquare}) &&
                            line.send(protocol::Position{.x_cm = kStartX, .z_cm = kStartZ, .tick = 0});
        if (!opened) return false;
        const Mode mode = mode_.load(std::memory_order_relaxed);
        if (mode == Mode::kFloodDroppable) {
            for (std::uint32_t at = 0; at < 1500; ++at) {
                if (!line.send(protocol::EntityPos{.id = at, .x_cm = 1.0F, .z_cm = 1.0F, .direction = 0, .tick = at})) return false;
            }
            return line.send(protocol::Goodbye{.reason = protocol::DisconnectReason::kKicked});
        }
        if (mode == Mode::kFloodCritical) {
            for (std::uint32_t at = 0; at < 400; ++at) {
                protocol::EntityAppear shown;
                shown.id = at;
                shown.name = "x";
                if (!line.send(shown)) return false;
            }
            return true;
        }
        if (mode == Mode::kGoodbye) return line.send(protocol::Goodbye{.reason = protocol::DisconnectReason::kKicked});
        const protocol::SceneEnter entered{.scene = static_cast<std::uint16_t>(kScene),
            .x_cm = kStartX,
            .z_cm = kStartZ,
            .direction = 0,
            .self_id = kSelfId};
        if (!line.send(entered)) return false;
        return mode == Mode::kWorld ? send_world(line) : true;
    }

    // Một quái id 7 hiện ở (170 m, 170 m) hướng +Z, đi tới (171 m, 170 m), mất nửa sinh lực rồi biến mất.
    [[nodiscard]] static bool send_world(ServerLine& line) {
        protocol::EntityAppear shown;
        shown.id = 7;
        shown.kind = protocol::EntityKind::kMonster;
        shown.template_id = 1234;
        shown.level = 9;
        shown.x_cm = 17000.0F;
        shown.z_cm = 17000.0F;
        shown.direction = 16384;
        shown.speed_cm = 300;
        shown.hp_percent = 100;
        shown.state = protocol::EntityState::kIdle;
        const protocol::EntityPos moved{.id = 7, .x_cm = 17100.0F, .z_cm = 17000.0F, .direction = 0, .tick = 5,
            .state = protocol::EntityState::kWalk};
        return line.send(shown) && line.send(moved) && line.send(protocol::EntityVitals{.id = 7, .hp_percent = 50}) &&
               line.send(protocol::EntityDisappear{.id = 7});
    }

    [[nodiscard]] bool answer_move(ServerLine& line, const protocol::Move& move) {
        bool is_first = false;
        {
            const std::scoped_lock lock{guard_};
            is_first = moves_.empty();
            moves_.push_back(move);
        }
        const bool pulls = is_first && mode_.load(std::memory_order_relaxed) == Mode::kPullBack;
        return !pulls || line.send(protocol::Position{.x_cm = kStartX, .z_cm = kStartZ, .tick = kPulledTick});
    }

    [[nodiscard]] bool answer_game(ServerLine& line, std::string& account, const protocol::GameClientMessage& message) {
        if (const auto* hello = std::get_if<protocol::Hello>(&message)) {
            {
                const std::scoped_lock lock{guard_};
                game_platform_ = static_cast<std::uint8_t>(hello->platform);
            }
            return line.send(welcome());
        }
        if (const auto* move = std::get_if<protocol::Move>(&message)) return answer_move(line, *move);
        if (const auto* login = std::get_if<protocol::Login>(&message)) return answer_login(line, account, *login);
        if (const auto* create = std::get_if<protocol::CreateCharacter>(&message)) return answer_create(line, account, *create);
        if (const auto* removed = std::get_if<protocol::DeleteCharacter>(&message)) return answer_delete(line, account, removed->character);
        if (const auto* enter = std::get_if<protocol::EnterGame>(&message)) return answer_enter(line, account, enter->character);
        if (const auto* ping = std::get_if<protocol::Ping>(&message)) {
            ++pings_;
            return line.send(protocol::Pong{.client_time = ping->client_time, .server_time = std::chrono::milliseconds{1}});
        }
        if (std::holds_alternative<protocol::Logout>(message)) {
            ++logouts_;
            static_cast<void>(line.send(protocol::Goodbye{.reason = protocol::DisconnectReason::kLoggedOut}));
            return false;
        }
        return true;
    }

    secure::Identity identity_ = make_identity();
    net::TcpListener auth_listener_;
    net::TcpListener game_listener_;
    std::atomic<Mode> mode_{Mode::kNormal};
    std::atomic<int> pings_{0};
    std::atomic<int> logouts_{0};
    std::mutex guard_;
    std::map<std::string, std::string> passwords_;
    std::map<std::string, std::string> tickets_;
    std::map<std::string, std::vector<protocol::CharacterSummary>> roster_;
    std::vector<protocol::Move> moves_;
    std::uint8_t game_platform_ = 0;
    std::uint64_t ticket_counter_ = 0;
    std::uint64_t next_character_ = 1;
    // Khai cuối: huỷ luồng (yêu cầu dừng rồi chờ) trước khi huỷ các thành viên mà luồng dùng.
    std::jthread auth_thread_;
    std::jthread game_thread_;
};

} // namespace game::test
