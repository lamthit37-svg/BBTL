// Phiên mạng của client: bảng cổng, máy trạng thái (thuần) và luồng nền chạy thật với máy chủ giả trên loopback
// (Test/support/fake_gate.hpp). Máy chủ giả thay cụm máy chủ thật vì cụm thật cần PostgreSQL mới cho đăng ký tài khoản.
// Chờ hàng đợi sự kiện bằng thăm dò ngắn; mọi lần chờ có hạn.
#include "client/session/gates.hpp"
#include "client/session/machine.hpp"
#include "client/session/session.hpp"

#include "core/check.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "support/fake_gate.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <variant>
#include <vector>

namespace game::test {
namespace {

using namespace std::chrono_literals;
using client::session::Ask;
using client::session::Event;
using client::session::Fault;
using client::session::Gate;
using client::session::Phase;
using client::session::Session;

// ---------------------------------------------------------------------------------------------------------------
// Phiên chạy thật với máy chủ giả

[[nodiscard]] Gate gate_of(const FakeGate& fake) {
    return Gate{.area = "Vùng", .server = "Máy", .game = fake.game(), .auth = fake.auth(), .key = fake.key()};
}

// Gom sự kiện tới khi một sự kiện thoả pred hoặc quá hạn. Sự kiện đã gom nằm trong seen (theo thứ tự).
template <typename Pred>
[[nodiscard]] bool await(Session& line, std::vector<Event>& seen, Pred pred, std::chrono::milliseconds limit = 5000ms) {
    const auto until = std::chrono::steady_clock::now() + limit;
    while (std::chrono::steady_clock::now() < until) {
        for (Event& event : line.drain()) seen.push_back(std::move(event));
        for (const Event& event : seen) {
            if (pred(event)) return true;
        }
        std::this_thread::sleep_for(2ms);
    }
    return false;
}

template <typename Pred>
[[nodiscard]] bool awaits_phase(const Session& line, Pred pred, std::chrono::milliseconds limit = 5000ms) {
    const auto until = std::chrono::steady_clock::now() + limit;
    while (std::chrono::steady_clock::now() < until) {
        if (pred(line.phase())) return true;
        std::this_thread::sleep_for(2ms);
    }
    return false;
}

[[nodiscard]] bool is_roster(const Event& event) { return std::holds_alternative<client::session::Roster>(event); }
[[nodiscard]] bool is_lost(const Event& event) { return std::holds_alternative<client::session::Lost>(event); }
[[nodiscard]] bool is_rejected(const Event& event) { return std::holds_alternative<client::session::Rejected>(event); }
[[nodiscard]] bool is_entered(const Event& event) { return std::holds_alternative<client::session::Entered>(event); }

[[nodiscard]] const client::session::Lost* lost_in(const std::vector<Event>& seen) {
    for (const Event& event : seen) {
        if (const auto* lost = std::get_if<client::session::Lost>(&event)) return lost;
    }
    return nullptr;
}

[[nodiscard]] const client::session::Roster* roster_in(const std::vector<Event>& seen) {
    const client::session::Roster* last = nullptr;
    for (const Event& event : seen) {
        if (const auto* roster = std::get_if<client::session::Roster>(&event)) last = roster;
    }
    return last;
}

// SignIn rồi chờ danh sách nhân vật đầu tiên.
[[nodiscard]] bool sign_in(Session& line, std::vector<Event>& seen, const FakeGate& fake, std::string password = "mat-khau") {
    const bool queued = line.submit(client::session::SignIn{.gate = gate_of(fake), .account = "nguoi-choi", .password = std::move(password)});
    return queued && await(line, seen, is_roster);
}

void session_full_path_reaches_position(Context& context) {
    const FakeGate fake;
    Session line;
    std::vector<Event> seen;
    context.expect(line.phase() == Phase::kIdle, "mới dựng là kIdle");
    context.expect(sign_in(line, seen, fake), "đăng nhập nhận danh sách nhân vật");
    context.expect(line.phase() == Phase::kChoosing, "sau danh sách là kChoosing");
    const client::session::Roster* none = roster_in(seen);
    context.expect(none != nullptr && none->characters.empty(), "tài khoản mới chưa có nhân vật");

    seen.clear();
    context.expect(line.submit(client::session::Create{.name = "Lam", .gender = protocol::Gender::kMale, .face = 7, .hair = 3}), "xếp được lệnh tạo");
    context.expect(await(line, seen, is_roster), "tạo xong có danh sách mới");
    const client::session::Roster* one = roster_in(seen);
    context.expect(one != nullptr && one->characters.size() == 1, "một nhân vật");
    if (one == nullptr || one->characters.size() != 1) return;
    // Bản sao: seen.clear() ngay dưới huỷ danh sách mà `one` trỏ vào.
    const protocol::CharacterSummary made = one->characters.front();
    context.expect(made.name == "Lam" && made.gender == protocol::Gender::kMale && made.face == 7 && made.hair == 3,
        "nhân vật mang đúng tên, giới, mặt, tóc");
    context.expect(made.id != 0, "máy chủ cấp id");

    seen.clear();
    context.expect(line.submit(client::session::Enter{.character = made.id}), "xếp được lệnh vào game");
    context.expect(await(line, seen, is_entered), "vào game nhận Position đầu");
    const client::session::Entered* entered = nullptr;
    for (const Event& event : seen) {
        if (const auto* got = std::get_if<client::session::Entered>(&event)) entered = got;
    }
    context.expect(entered != nullptr, "có sự kiện Entered");
    if (entered != nullptr) {
        context.expect(entered->character.id == made.id && entered->character.name == "Lam", "Entered mang nhân vật đã chọn");
        context.expect(entered->position.x_cm == 16500.0F && entered->position.z_cm == 16900.0F, "chỗ đứng đầu tiên do máy chủ đặt");
    }
    bool is_square = false;
    bool is_session_start = false;
    for (const Event& event : seen) {
        const auto* world = std::get_if<client::session::World>(&event);
        if (world == nullptr) continue;
        if (const auto* config = std::get_if<protocol::UiConfig>(&world->message)) is_square = config->avatar_frame == protocol::AvatarFrame::kSquare;
        if (std::holds_alternative<protocol::SessionStart>(world->message)) is_session_start = true;
    }
    context.expect(is_session_start, "SessionStart tới trước Position");
    context.expect(is_square, "UiConfig tới và khung vuông");
    context.expect(awaits_phase(line, [](Phase phase) { return phase == Phase::kInGame; }), "pha kInGame");

    // Nhịp tim: Welcome.heartbeat 1 giây; máy chủ phải thấy Ping, và client không bị cắt vì im.
    const auto until = std::chrono::steady_clock::now() + 4s;
    while (fake.pings() < 1 && std::chrono::steady_clock::now() < until) std::this_thread::sleep_for(5ms);
    context.expect(fake.pings() >= 1, "client gửi Ping theo nhịp tim");
    context.expect(line.phase() == Phase::kInGame, "còn trong game sau một nhịp tim");

    context.expect(line.submit(client::session::Drop{}), "xếp được lệnh trả phiên");
    context.expect(awaits_phase(line, [](Phase phase) { return phase == Phase::kIdle; }), "trả phiên về kIdle");
    const auto bye_until = std::chrono::steady_clock::now() + 2s;
    while (fake.logouts() < 1 && std::chrono::steady_clock::now() < bye_until) std::this_thread::sleep_for(5ms);
    context.expect(fake.logouts() == 1, "trả phiên có gửi Logout cho máy chủ");
}

void session_wrong_password_is_rejected(Context& context) {
    const FakeGate fake;
    Session line;
    std::vector<Event> seen;
    context.expect(sign_in(line, seen, fake, "dung"), "lần đầu đăng ký và vào được");
    context.expect(line.submit(client::session::Drop{}), "trả phiên");
    context.expect(awaits_phase(line, [](Phase phase) { return phase == Phase::kIdle; }), "về kIdle");
    seen.clear();
    context.expect(line.submit(client::session::SignIn{.gate = gate_of(fake), .account = "nguoi-choi", .password = "sai"}), "xếp lệnh");
    context.expect(await(line, seen, is_rejected), "sai mật khẩu bị từ chối");
    for (const Event& event : seen) {
        if (const auto* refused = std::get_if<client::session::Rejected>(&event)) {
            context.expect(refused->ask == Ask::kSignIn && refused->code == protocol::ErrorCode::kBadCredentials, "đúng việc và đúng mã");
        }
    }
    context.expect(awaits_phase(line, [](Phase phase) { return phase == Phase::kIdle; }), "bị từ chối thì về kIdle");
    context.expect(lost_in(seen) == nullptr, "từ chối không phải mất phiên");
}

void session_refuses_out_of_order_commands(Context& context) {
    const FakeGate fake;
    Session line;
    std::vector<Event> seen;
    context.expect(line.submit(client::session::Create{.name = "Lam"}), "xếp lệnh");
    context.expect(await(line, seen, is_rejected), "tạo khi chưa đăng nhập bị từ chối");
    const auto* refused = std::get_if<client::session::Rejected>(&seen.front());
    context.expect(refused != nullptr && refused->ask == Ask::kCreate && refused->code == protocol::ErrorCode::kOutOfOrder, "kOutOfOrder cho Create");
    context.expect(line.phase() == Phase::kIdle, "pha không đổi");

    seen.clear();
    context.expect(sign_in(line, seen, fake), "đăng nhập");
    seen.clear();
    context.expect(line.submit(client::session::SignIn{.gate = gate_of(fake), .account = "nguoi-choi", .password = "x"}), "xếp lệnh");
    context.expect(await(line, seen, is_rejected), "đăng nhập lần hai khi đã có phiên bị từ chối");
    context.expect(line.phase() == Phase::kChoosing, "phiên cũ còn nguyên");
}

void session_name_taken_keeps_choosing(Context& context) {
    const FakeGate fake;
    Session line;
    std::vector<Event> seen;
    context.expect(sign_in(line, seen, fake), "đăng nhập");
    seen.clear();
    context.expect(line.submit(client::session::Create{.name = "Lam"}), "tạo lần một");
    context.expect(await(line, seen, is_roster), "có nhân vật");
    seen.clear();
    context.expect(line.submit(client::session::Create{.name = "Lam"}), "tạo lần hai cùng tên");
    context.expect(await(line, seen, is_rejected), "trùng tên bị từ chối");
    const auto* refused = seen.empty() ? nullptr : std::get_if<client::session::Rejected>(&seen.front());
    context.expect(refused != nullptr && refused->ask == Ask::kCreate && refused->code == protocol::ErrorCode::kNameTaken, "kNameTaken cho Create");
    context.expect(awaits_phase(line, [](Phase phase) { return phase == Phase::kChoosing; }), "về kChoosing, phiên còn dùng được");

    const client::session::Roster* before = nullptr;
    seen.clear();
    context.expect(line.submit(client::session::Delete{.character = 1}), "xoá nhân vật");
    context.expect(await(line, seen, is_roster), "xoá xong có danh sách mới");
    before = roster_in(seen);
    context.expect(before != nullptr && before->characters.empty(), "danh sách rỗng sau khi xoá");
}

void session_enter_unknown_character_is_local_refusal(Context& context) {
    const FakeGate fake;
    Session line;
    std::vector<Event> seen;
    context.expect(sign_in(line, seen, fake), "đăng nhập");
    seen.clear();
    context.expect(line.submit(client::session::Enter{.character = 4242}), "xếp lệnh");
    context.expect(await(line, seen, is_rejected), "nhân vật không có trong danh sách bị từ chối ngay");
    const auto* refused = seen.empty() ? nullptr : std::get_if<client::session::Rejected>(&seen.front());
    context.expect(refused != nullptr && refused->ask == Ask::kEnter && refused->code == protocol::ErrorCode::kNoSuchCharacter, "kNoSuchCharacter");
    context.expect(line.phase() == Phase::kChoosing, "vẫn ở bảng chọn");
}

// Cho mỗi chế độ lỗi của máy chủ: đăng nhập, rồi chờ Lost.
[[nodiscard]] std::optional<client::session::Lost> lost_by(Mode mode, Fault expected_fault, Context& context,
    std::chrono::milliseconds reply = 10000ms) {
    FakeGate fake;
    fake.set_mode(mode);
    Session line{client::session::Timing{.reply = reply, .silence = 10000ms}};
    std::vector<Event> seen;
    const bool queued = line.submit(client::session::SignIn{.gate = gate_of(fake), .account = "nguoi-choi", .password = "x"});
    context.expect(queued, "xếp lệnh");
    const bool got = await(line, seen, is_lost);
    context.expect(got, "nhận được Lost");
    const client::session::Lost* lost = lost_in(seen);
    if (lost == nullptr) return std::nullopt;
    context.expect(lost->fault == expected_fault, "đúng lý do mất phiên");
    context.expect(awaits_phase(line, [](Phase phase) { return phase == Phase::kLost; }), "pha kLost");
    return *lost;
}

void session_garbage_record_is_protocol_fault(Context& context) {
    const std::optional<client::session::Lost> lost = lost_by(Mode::kGarbage, Fault::kProtocol, context);
    context.expect(lost.has_value() && lost->phase == Phase::kSigningIn, "mất ở pha đăng nhập");
}

void session_out_of_order_message_is_protocol_fault(Context& context) {
    const std::optional<client::session::Lost> lost = lost_by(Mode::kOutOfOrder, Fault::kProtocol, context);
    context.expect(lost.has_value() && lost->phase == Phase::kSigningIn, "Position thay CharacterList là sai trình tự");
}

void session_mute_server_times_out(Context& context) {
    const auto start = std::chrono::steady_clock::now();
    const std::optional<client::session::Lost> lost = lost_by(Mode::kMute, Fault::kTimeout, context, 400ms);
    const auto took = std::chrono::steady_clock::now() - start;
    context.expect(lost.has_value() && lost->phase == Phase::kSigningIn, "mất ở pha đăng nhập");
    context.expect(took < 4s, "hạn chờ được tôn trọng, không chờ cả hạn mặc định");
}

void session_hang_up_is_unreachable(Context& context) {
    const std::optional<client::session::Lost> lost = lost_by(Mode::kHangUp, Fault::kUnreachable, context);
    context.expect(lost.has_value() && lost->phase == Phase::kSigningIn, "mất ở pha đăng nhập");
}

void session_wrong_pinned_key_is_secure_fault(Context& context) {
    const FakeGate fake;
    Gate gate = gate_of(fake);
    gate.key.bytes.at(0) ^= std::byte{0xFF};
    Session line;
    std::vector<Event> seen;
    context.expect(line.submit(client::session::SignIn{.gate = std::move(gate), .account = "a", .password = "b"}), "xếp lệnh");
    context.expect(await(line, seen, is_lost), "nhận được Lost");
    const client::session::Lost* lost = lost_in(seen);
    context.expect(lost != nullptr && lost->fault == Fault::kSecure, "khoá ghim không khớp là kSecure");
    context.expect(roster_in(seen) == nullptr, "không có nhân vật nào lọt qua");
}

void session_nobody_listening_is_unreachable(Context& context) {
    Gate gate;
    {
        const FakeGate fake;
        gate = gate_of(fake);
    }
    Session line;
    std::vector<Event> seen;
    context.expect(line.submit(client::session::SignIn{.gate = gate, .account = "a", .password = "b"}), "xếp lệnh");
    context.expect(await(line, seen, is_lost), "nhận được Lost");
    const client::session::Lost* lost = lost_in(seen);
    context.expect(lost != nullptr && lost->fault == Fault::kUnreachable, "không ai nghe là kUnreachable");
}

// Vào game xong rồi máy chủ làm gì đó; trả về mọi sự kiện cho tới Lost hoặc hết hạn. Không rút sự kiện khi máy chủ còn
// đang gửi (hàng đợi sự kiện chỉ chịu được kEventCap), nên chờ pha kLost trước rồi mới rút.
struct Aftermath {
    std::vector<Event> seen;
    bool is_lost_phase = false;
};

[[nodiscard]] Aftermath enter_then(Mode mode, Context& context) {
    FakeGate fake;
    Session line;
    Aftermath result;
    context.expect(sign_in(line, result.seen, fake), "đăng nhập");
    result.seen.clear();
    context.expect(line.submit(client::session::Create{.name = "Lam"}), "tạo");
    context.expect(await(line, result.seen, is_roster), "có nhân vật");
    const client::session::Roster* roster = roster_in(result.seen);
    if (roster == nullptr || roster->characters.empty()) return result;
    const std::uint64_t id = roster->characters.front().id;
    result.seen.clear();
    fake.set_mode(mode);
    context.expect(line.submit(client::session::Enter{.character = id}), "vào game");
    result.is_lost_phase = awaits_phase(line, [](Phase phase) { return phase == Phase::kLost; });
    for (Event& event : line.drain()) result.seen.push_back(std::move(event));
    return result;
}

void session_goodbye_in_game_closes_with_reason(Context& context) {
    const Aftermath after = enter_then(Mode::kGoodbye, context);
    context.expect(after.is_lost_phase, "pha kLost");
    bool is_entered_first = false;
    for (const Event& event : after.seen) {
        if (is_entered(event)) is_entered_first = true;
        if (is_lost(event)) break;
    }
    context.expect(is_entered_first, "Entered tới trước Lost");
    const client::session::Lost* lost = lost_in(after.seen);
    context.expect(lost != nullptr && lost->fault == Fault::kGoodbye && lost->phase == Phase::kInGame, "Goodbye trong game");
    context.expect(lost != nullptr && lost->reason == protocol::DisconnectReason::kKicked, "mang lý do của máy chủ");
}

void session_entity_flood_is_dropped_not_fatal(Context& context) {
    const Aftermath after = enter_then(Mode::kFloodDroppable, context);
    context.expect(after.is_lost_phase, "pha kLost vì Goodbye cuối");
    const client::session::Lost* lost = lost_in(after.seen);
    context.expect(lost != nullptr && lost->fault == Fault::kGoodbye, "kết thúc bằng Goodbye, không phải tràn hàng đợi");
    std::size_t positions = 0;
    bool is_entered_seen = false;
    for (const Event& event : after.seen) {
        if (is_entered(event)) is_entered_seen = true;
        const auto* world = std::get_if<client::session::World>(&event);
        if (world != nullptr && std::holds_alternative<protocol::EntityPos>(world->message)) ++positions;
    }
    context.expect(is_entered_seen, "tin quan trọng (Entered) còn nguyên");
    context.expect(positions < 1500, "tin vị trí thừa đã bị bỏ");
    context.expect(after.seen.size() <= client::session::kEventCap, "hàng đợi không vượt trần");
}

void session_critical_flood_ends_with_queue_full(Context& context) {
    const Aftermath after = enter_then(Mode::kFloodCritical, context);
    context.expect(after.is_lost_phase, "tràn hàng đợi thì phiên mất");
    context.expect(after.seen.size() == 1, "hàng đợi bị xoá, chỉ còn một sự kiện");
    const client::session::Lost* lost = lost_in(after.seen);
    context.expect(lost != nullptr && lost->fault == Fault::kQueueFull, "Lost{kQueueFull}");
}

void session_signs_in_again_after_loss(Context& context) {
    FakeGate fake;
    fake.set_mode(Mode::kHangUp);
    Session line;
    std::vector<Event> seen;
    context.expect(line.submit(client::session::SignIn{.gate = gate_of(fake), .account = "nguoi-choi", .password = "x"}), "xếp lệnh");
    context.expect(await(line, seen, is_lost), "mất phiên");
    context.expect(awaits_phase(line, [](Phase phase) { return phase == Phase::kLost; }), "kLost");
    fake.set_mode(Mode::kNormal);
    seen.clear();
    context.expect(sign_in(line, seen, fake, "x"), "đăng nhập lại ngay từ kLost, không cần Drop");
    context.expect(line.phase() == Phase::kChoosing, "kChoosing");
}

// Cổng nghe mà không ai nhận: TCP nối được nhưng không có Welcome, đúng cảnh "đang bắt tay".
void session_destruction_cancels_handshake(Context& context) {
    net::NetResult<net::TcpListener> mute = net::TcpListener::open({.address = {127, 0, 0, 1}, .port = 0});
    context.expect(mute.has_value(), "mở được cổng câm");
    if (!mute) return;
    const net::NetResult<net::Endpoint> where = mute->local();
    context.expect(where.has_value(), "đọc được cổng");
    if (!where) return;
    const secure::Result<secure::Identity> identity = secure::Identity::generate();
    context.expect(identity.has_value(), "tạo khoá");
    if (!identity) return;
    const auto start = std::chrono::steady_clock::now();
    {
        Session line;
        context.expect(line.submit(client::session::SignIn{
            .gate = Gate{.area = "a", .server = "s", .game = *where, .auth = *where, .key = identity->public_key()},
            .account = "a", .password = "b"}), "xếp lệnh");
        std::this_thread::sleep_for(150ms);
        context.expect(line.phase() == Phase::kSigningIn, "đang chờ bắt tay");
    }
    const auto took = std::chrono::steady_clock::now() - start;
    context.expect(took < 2s, "huỷ phiên giữa lúc bắt tay trả về nhanh, không chờ hạn nối 4 giây");
}

void session_command_queue_has_a_cap(Context& context) {
    net::NetResult<net::TcpListener> mute = net::TcpListener::open({.address = {127, 0, 0, 1}, .port = 0});
    context.expect(mute.has_value(), "mở được cổng câm");
    if (!mute) return;
    const net::NetResult<net::Endpoint> where = mute->local();
    if (!where) return;
    const secure::Result<secure::Identity> identity = secure::Identity::generate();
    if (!identity) return;
    Session line;
    // Lệnh đầu giữ luồng nền trong lúc bắt tay với cổng câm; mọi lệnh sau xếp hàng.
    context.expect(line.submit(client::session::SignIn{
        .gate = Gate{.area = "a", .server = "s", .game = *where, .auth = *where, .key = identity->public_key()},
        .account = "a", .password = "b"}), "lệnh giữ luồng");
    std::this_thread::sleep_for(100ms);
    std::size_t accepted = 0;
    for (std::size_t at = 0; at < client::session::kCommandCap + 8; ++at) {
        if (line.submit(client::session::Drop{})) ++accepted;
    }
    context.expect(accepted == client::session::kCommandCap, "hàng đợi lệnh nhận đúng kCommandCap lệnh rồi từ chối");
}

constexpr std::array kCases{
    Case{.name = "session_full_path_reaches_position", .body = &session_full_path_reaches_position},
    Case{.name = "session_wrong_password_is_rejected", .body = &session_wrong_password_is_rejected},
    Case{.name = "session_refuses_out_of_order_commands", .body = &session_refuses_out_of_order_commands},
    Case{.name = "session_name_taken_keeps_choosing", .body = &session_name_taken_keeps_choosing},
    Case{.name = "session_enter_unknown_character_is_local_refusal", .body = &session_enter_unknown_character_is_local_refusal},
    Case{.name = "session_garbage_record_is_protocol_fault", .body = &session_garbage_record_is_protocol_fault},
    Case{.name = "session_out_of_order_message_is_protocol_fault", .body = &session_out_of_order_message_is_protocol_fault},
    Case{.name = "session_mute_server_times_out", .body = &session_mute_server_times_out},
    Case{.name = "session_hang_up_is_unreachable", .body = &session_hang_up_is_unreachable},
    Case{.name = "session_wrong_pinned_key_is_secure_fault", .body = &session_wrong_pinned_key_is_secure_fault},
    Case{.name = "session_nobody_listening_is_unreachable", .body = &session_nobody_listening_is_unreachable},
    Case{.name = "session_goodbye_in_game_closes_with_reason", .body = &session_goodbye_in_game_closes_with_reason},
    Case{.name = "session_entity_flood_is_dropped_not_fatal", .body = &session_entity_flood_is_dropped_not_fatal},
    Case{.name = "session_critical_flood_ends_with_queue_full", .body = &session_critical_flood_ends_with_queue_full},
    Case{.name = "session_signs_in_again_after_loss", .body = &session_signs_in_again_after_loss},
    Case{.name = "session_destruction_cancels_handshake", .body = &session_destruction_cancels_handshake},
    Case{.name = "session_command_queue_has_a_cap", .body = &session_command_queue_has_a_cap},
};

} // namespace
} // namespace game::test

int main() {
    const auto network = game::net::Network::start();
    game::core::check(network.has_value(), "session_tests: khởi động được thư viện mạng");
    game::core::check(game::test::run_all(game::test::kCases) == 0, "session_tests: mọi ca phải qua");
    return 0;
}
