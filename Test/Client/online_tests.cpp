/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Client/online_tests.cpp
 *  PHÂN HỆ   : Client / Online Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cầu nối giữa chuỗi đăng nhập và phiên mạng: bảng đổi (thuần) và cầu chạy
 *    thật với máy chủ giả trên loopback (Test/support/fake_gate.hpp), đúng
 *    đường mà viewer đi: OnlineAsk vào, OnlineReply ra.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/online/bridge.hpp"

#include "client/cast/note.hpp"

#include "client/session/gates.hpp"
#include "client/session/machine.hpp"
#include "client/session/session.hpp"
#include "core/check.hpp"
#include "guard/pace.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "support/fake_gate.hpp"
#include "test.hpp"
#include "ui/panel/online.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/talk.hpp"

#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <numbers>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <thread>
#include <utility>
#include <variant>
#include <vector>

namespace game::test {
namespace {

using namespace std::chrono_literals;
using client::online::Bridge;
using ui::panel::OnlineAsk;
using ui::panel::OnlineFault;
using ui::panel::OnlineReply;
using ui::panel::OnlineWork;

void fault_of_error_codes(Context& context) {
    using client::online::fault_of;
    using protocol::ErrorCode;
    context.expect(fault_of(ErrorCode::kBadCredentials) == OnlineFault::kBadLogin, "sai mật khẩu");
    context.expect(fault_of(ErrorCode::kNotAuthenticated) == OnlineFault::kBadLogin, "vé không hợp lệ cũng là đăng nhập hỏng");
    context.expect(fault_of(ErrorCode::kServerFull) == OnlineFault::kServerFull, "đầy máy chủ");
    context.expect(fault_of(ErrorCode::kBusy) == OnlineFault::kBusy, "bận");
    context.expect(fault_of(ErrorCode::kRateLimited) == OnlineFault::kBusy, "bị giới hạn tốc độ cũng là bận");
    context.expect(fault_of(ErrorCode::kMaintenance) == OnlineFault::kMaintenance, "bảo trì");
    context.expect(fault_of(ErrorCode::kNameTaken) == OnlineFault::kNameTaken, "trùng tên");
    context.expect(fault_of(ErrorCode::kNameInvalid) == OnlineFault::kNameInvalid, "tên sai");
    context.expect(fault_of(ErrorCode::kCharacterLimit) == OnlineFault::kRoleLimit, "đủ nhân vật");
    context.expect(fault_of(ErrorCode::kNoSuchCharacter) == OnlineFault::kNoRole, "nhân vật không có");
    context.expect(fault_of(ErrorCode::kMalformed) == OnlineFault::kProtocol, "tin sai dạng");
    context.expect(fault_of(ErrorCode::kCannotAttack) == OnlineFault::kOther, "mã không liên quan đăng nhập");
}

void fault_of_lost_reasons(Context& context) {
    using client::online::fault_of;
    using client::session::Fault;
    using client::session::Lost;
    using protocol::DisconnectReason;
    context.expect(fault_of(Lost{.fault = Fault::kUnreachable}) == OnlineFault::kUnreachable, "không nối được");
    context.expect(fault_of(Lost{.fault = Fault::kSecure}) == OnlineFault::kSecure, "bảo mật");
    context.expect(fault_of(Lost{.fault = Fault::kProtocol}) == OnlineFault::kProtocol, "giao thức");
    context.expect(fault_of(Lost{.fault = Fault::kTimeout}) == OnlineFault::kTimeout, "quá hạn");
    context.expect(fault_of(Lost{.fault = Fault::kQueueFull}) == OnlineFault::kOther, "tràn hàng đợi");
    context.expect(fault_of(Lost{.fault = Fault::kGoodbye}) == OnlineFault::kClosed, "Goodbye không lý do");
    context.expect(fault_of(Lost{.fault = Fault::kGoodbye, .reason = DisconnectReason::kLoginElsewhere}) == OnlineFault::kElsewhere,
        "đăng nhập nơi khác");
    context.expect(fault_of(Lost{.fault = Fault::kGoodbye, .reason = DisconnectReason::kServerFull}) == OnlineFault::kServerFull, "đầy");
    context.expect(fault_of(Lost{.fault = Fault::kGoodbye, .reason = DisconnectReason::kVersionMismatch}) == OnlineFault::kProtocol,
        "lệch phiên bản");
    context.expect(fault_of(Lost{.fault = Fault::kGoodbye, .reason = DisconnectReason::kKicked}) == OnlineFault::kClosed, "bị đuổi");
}

void role_of_keeps_server_facts(Context& context) {
    protocol::CharacterSummary character;
    character.id = 77;
    character.name = "Lam";
    character.level = 5;
    character.gender = protocol::Gender::kMale;
    character.face = 12;
    character.hair = 4;
    character.school = 9;
    character.scene = 2;
    const ui::panel::Role role = client::online::role_of(character);
    context.expect(role.id == 77 && role.name == "Lam" && role.level == 5, "id, tên, cấp");
    context.expect(role.sex == 1 && role.face == 12 && role.hair == 4 && role.sect == 9, "giới, mặt, tóc, môn phái");
    character.gender = protocol::Gender::kFemale;
    context.expect(client::online::role_of(character).sex == 0, "nữ là 0");
}

void reply_of_events(Context& context) {
    using client::session::Ask;
    using client::session::Entered;
    using client::session::Event;
    using client::session::Fault;
    using client::session::Lost;
    using client::session::Phase;
    using client::session::Rejected;
    using client::session::Roster;
    using client::session::World;
    const std::optional<OnlineReply> roster = client::online::reply_of(Event{Roster{.characters = {protocol::CharacterSummary{.id = 3, .name = "A"}}}});
    context.expect(roster && roster->kind == OnlineReply::Kind::kRoster && roster->roles.size() == 1 && roster->roles.front().id == 3, "Roster");

    const std::optional<OnlineReply> refused = client::online::reply_of(
        Event{Rejected{.ask = Ask::kCreate, .request = 0x0201, .code = protocol::ErrorCode::kNameTaken}});
    context.expect(refused && refused->kind == OnlineReply::Kind::kRefused && refused->fault == OnlineFault::kNameTaken, "Rejected");

    const std::optional<OnlineReply> lost = client::online::reply_of(Event{Lost{.fault = Fault::kTimeout, .phase = Phase::kSigningIn}});
    context.expect(lost && lost->kind == OnlineReply::Kind::kLost && lost->fault == OnlineFault::kTimeout, "Lost");

    protocol::CharacterSummary hero;
    hero.scene = 2;
    const std::optional<OnlineReply> entered = client::online::reply_of(
        Event{Entered{.character = hero, .position = protocol::Position{.x_cm = 1650.0F, .z_cm = 1690.0F, .tick = 0}}});
    context.expect(entered && entered->kind == OnlineReply::Kind::kEntered && entered->scene == 2 && entered->x_cm == 1650.0F &&
                       entered->z_cm == 1690.0F,
        "Entered mang cảnh và chỗ đứng");

    const std::optional<OnlineReply> square = client::online::reply_of(
        Event{World{.message = protocol::UiConfig{.avatar_frame = protocol::AvatarFrame::kSquare}}});
    context.expect(square && square->kind == OnlineReply::Kind::kStyle && square->style == ui::panel::FrameStyle::kSquare, "UiConfig vuông");
    const std::optional<OnlineReply> round = client::online::reply_of(
        Event{World{.message = protocol::UiConfig{.avatar_frame = protocol::AvatarFrame::kRound}}});
    context.expect(round && round->style == ui::panel::FrameStyle::kRound, "UiConfig tròn");
    context.expect(!client::online::reply_of(Event{World{.message = protocol::EntityPos{}}}), "tin thế giới chưa dùng thì không báo");
}

// ---------------------------------------------------------------------------------------------------------------
// Cầu chạy thật

[[nodiscard]] client::session::GateBook book_of(const FakeGate& fake) {
    client::session::GateBook book;
    book.gates.push_back(client::session::Gate{.area = "Vùng", .server = "Máy", .game = fake.game(), .auth = fake.auth(), .key = fake.key()});
    return book;
}

// Thu trả lời của cầu tới khi pred đúng với một trả lời hoặc quá hạn.
template <typename Pred>
[[nodiscard]] bool collect_until(Bridge& bridge, std::vector<OnlineReply>& seen, Pred pred, std::chrono::milliseconds limit = 5000ms) {
    const auto until = std::chrono::steady_clock::now() + limit;
    while (std::chrono::steady_clock::now() < until) {
        for (OnlineReply& reply : bridge.collect()) seen.push_back(std::move(reply));
        for (const OnlineReply& reply : seen) {
            if (pred(reply)) return true;
        }
        std::this_thread::sleep_for(2ms);
    }
    return false;
}

[[nodiscard]] bool is_kind(const OnlineReply& reply, OnlineReply::Kind kind) { return reply.kind == kind; }

void serve_one(Bridge& bridge, OnlineAsk ask) {
    std::array<OnlineAsk, 1> asks{std::move(ask)};
    bridge.serve(asks);
}

[[nodiscard]] OnlineAsk sign_in_ask(std::string password) {
    OnlineAsk ask;
    ask.work = OnlineWork::kSignIn;
    ask.server = ui::panel::ServerName{.area = "Vùng", .server = "Máy"};
    ask.account = "nguoi-choi";
    ask.password = std::move(password);
    return ask;
}

// Client PC nối máy chủ phải tự khởi động thư viện mạng (WSAStartup); thiếu thì mọi socket hỏng và màn đăng nhập báo
// "không nối được máy chủ" dù máy chủ đang chạy (đo 2026-10-16). Ca này chạy khi không còn máy chủ giả nào sống.
void bridge_starts_the_network(Context& context) {
    const Bridge bridge{client::session::GateBook{}};
    const net::NetResult<net::Endpoint> loopback = net::parse_endpoint("127.0.0.1:0", net::ZeroPort::kAllow);
    context.expect(loopback.has_value(), "địa chỉ loopback");
    if (!loopback) return;
    const net::NetResult<net::TcpListener> opened = net::TcpListener::open(*loopback);
    context.expect(opened.has_value(), "có Bridge thì mở được socket mà không ai khác khởi động thư viện mạng");
}

void bridge_lists_only_gated_servers(Context& context) {
    const FakeGate fake;
    Bridge bridge{book_of(fake)};
    const std::vector<ui::panel::ServerName> names = bridge.servers();
    context.expect(names.size() == 1 && names.front().area == "Vùng" && names.front().server == "Máy", "tên máy chủ có cổng thật");
    context.expect(bridge.phase() == client::session::Phase::kIdle, "phiên chưa dựng là kIdle");
    context.expect(bridge.collect().empty(), "chưa có gì để trả");
}

void bridge_unknown_server_is_refused_at_once(Context& context) {
    const FakeGate fake;
    Bridge bridge{book_of(fake)};
    OnlineAsk ask = sign_in_ask("bi-mat");
    ask.server.server = "Máy lạ";
    serve_one(bridge, std::move(ask));
    const std::vector<OnlineReply> replies = bridge.collect();
    context.expect(replies.size() == 1 && replies.front().kind == OnlineReply::Kind::kRefused &&
                       replies.front().fault == OnlineFault::kUnreachable,
        "máy chủ không có trong bảng cổng bị từ chối ngay");
    context.expect(bridge.phase() == client::session::Phase::kIdle, "không dựng phiên vì một yêu cầu vô nghĩa");
}

void bridge_wipes_the_password(Context& context) {
    const FakeGate fake;
    Bridge bridge{book_of(fake)};
    std::array<OnlineAsk, 1> asks{sign_in_ask("bi-mat")};
    bridge.serve(asks);
    context.expect(asks.front().password.empty(), "mật khẩu bị xoá sau khi chuyển cho phiên");
    std::vector<OnlineReply> seen;
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRoster); }), "vẫn đăng nhập được");
}

void bridge_walks_sign_in_create_enter(Context& context) {
    const FakeGate fake;
    Bridge bridge{book_of(fake)};
    std::vector<OnlineReply> seen;

    serve_one(bridge, sign_in_ask("bi-mat"));
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRoster); }), "danh sách sau đăng nhập");
    context.expect(!seen.empty() && seen.front().roles.empty(), "tài khoản mới chưa có nhân vật");

    seen.clear();
    OnlineAsk create;
    create.work = OnlineWork::kCreate;
    create.role.name = "Lam";
    create.role.sex = 1;
    create.role.face = 5;
    create.role.hair = 2;
    serve_one(bridge, std::move(create));
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRoster); }), "danh sách sau khi tạo");
    if (seen.empty() || seen.front().roles.size() != 1) {
        context.expect(false, "một nhân vật mới");
        return;
    }
    const ui::panel::Role made = seen.front().roles.front();
    context.expect(made.name == "Lam" && made.sex == 1 && made.face == 5 && made.hair == 2 && made.id != 0, "nhân vật mang đúng thông tin máy chủ giữ");

    seen.clear();
    OnlineAsk enter;
    enter.work = OnlineWork::kEnter;
    enter.role = made;
    serve_one(bridge, std::move(enter));
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kEntered); }), "Entered");
    bool is_style_first = false;
    for (const OnlineReply& reply : seen) {
        if (reply.kind == OnlineReply::Kind::kEntered) {
            context.expect(reply.scene == 2 && reply.x_cm == 16500.0F && reply.z_cm == 16900.0F, "cảnh và chỗ đứng do máy chủ đặt");
            break;
        }
        if (reply.kind == OnlineReply::Kind::kStyle && reply.style == ui::panel::FrameStyle::kSquare) is_style_first = true;
    }
    context.expect(is_style_first, "UiConfig (khung vuông) tới trước Entered");

    serve_one(bridge, OnlineAsk{.work = OnlineWork::kDrop});
    const auto until = std::chrono::steady_clock::now() + 2s;
    while (bridge.phase() != client::session::Phase::kIdle && std::chrono::steady_clock::now() < until) std::this_thread::sleep_for(2ms);
    context.expect(bridge.phase() == client::session::Phase::kIdle, "Drop trả phiên");
}

void bridge_reports_refusal_and_loss(Context& context) {
    FakeGate fake;
    Bridge bridge{book_of(fake)};
    std::vector<OnlineReply> seen;
    serve_one(bridge, sign_in_ask("dung"));
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRoster); }), "đăng nhập");

    OnlineAsk create;
    create.work = OnlineWork::kCreate;
    create.role.name = "Lam";
    seen.clear();
    serve_one(bridge, create);
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRoster); }), "tạo lần một");
    seen.clear();
    serve_one(bridge, create);
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRefused); }), "tạo trùng tên bị từ chối");
    context.expect(!seen.empty() && seen.front().fault == OnlineFault::kNameTaken, "lý do là trùng tên");

    // Máy chủ đóng giữa chừng: lệnh kế tiếp vào phiên sống nhưng Goodbye báo mất.
    seen.clear();
    fake.set_mode(Mode::kGoodbye);
    OnlineAsk enter;
    enter.work = OnlineWork::kEnter;
    enter.role.id = 1;
    serve_one(bridge, std::move(enter));
    context.expect(collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kLost); }), "mất phiên được báo");
    for (const OnlineReply& reply : seen) {
        if (reply.kind == OnlineReply::Kind::kLost) context.expect(reply.fault == OnlineFault::kClosed, "bị đuổi là đóng kết nối");
    }
}


// ---------------------------------------------------------------------------------------------------------------
// Tin thế giới và Move

// Lấy tin thế giới của cầu trong khoảng thời gian span, giữ thứ tự; trả lời của chuỗi đăng nhập bỏ đi.
void pump_for(Bridge& bridge, std::vector<client::cast::Note>& notes, std::chrono::milliseconds span) {
    const auto until = std::chrono::steady_clock::now() + span;
    while (std::chrono::steady_clock::now() < until) {
        static_cast<void>(bridge.collect());
        for (client::cast::Note& note : bridge.take_notes()) notes.push_back(std::move(note));
        std::this_thread::sleep_for(2ms);
    }
}

// Đăng nhập, tạo một nhân vật rồi vào game trên máy chủ giả; false khi một bước không tới được.
[[nodiscard]] bool enter_fake_world(Bridge& bridge, std::vector<client::cast::Note>& notes) {
    std::vector<OnlineReply> seen;
    serve_one(bridge, sign_in_ask("bi-mat"));
    if (!collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRoster); })) return false;
    seen.clear();
    OnlineAsk create;
    create.work = OnlineWork::kCreate;
    create.role.name = "Lam";
    serve_one(bridge, std::move(create));
    if (!collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kRoster); })) return false;
    if (seen.empty() || seen.back().roles.empty()) return false;
    OnlineAsk enter;
    enter.work = OnlineWork::kEnter;
    enter.role = seen.back().roles.front();
    seen.clear();
    serve_one(bridge, std::move(enter));
    const bool is_in = collect_until(bridge, seen, [](const OnlineReply& reply) { return is_kind(reply, OnlineReply::Kind::kEntered); });
    for (client::cast::Note& note : bridge.take_notes()) notes.push_back(std::move(note));
    return is_in;
}

template <typename Note>
[[nodiscard]] const Note* find_note(const std::vector<client::cast::Note>& notes) {
    for (const client::cast::Note& note : notes) {
        if (const Note* held = std::get_if<Note>(&note)) return held;
    }
    return nullptr;
}

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) < 1e-3F;
}

void note_of_converts_units(Context& context) {
    using client::session::Event;
    using client::session::World;
    namespace cast = client::cast;
    constexpr float kHalfPi = std::numbers::pi_v<float> / 2.0F;

    protocol::EntityAppear shown;
    shown.id = 7;
    shown.kind = protocol::EntityKind::kNpc;
    shown.template_id = 55;
    shown.level = 3;
    shown.x_cm = 1650.0F;
    shown.z_cm = 1690.0F;
    shown.direction = 16384;
    shown.speed_cm = 420;
    shown.hp_percent = 80;
    shown.state = protocol::EntityState::kWalk;
    const auto appear = client::online::note_of(Event{World{.message = shown}});
    const auto* spawn = appear ? std::get_if<cast::Spawn>(&*appear) : nullptr;
    context.expect(spawn != nullptr, "EntityAppear thành Spawn");
    if (spawn != nullptr) {
        context.expect(spawn->kind == cast::Kind::kNpc && spawn->template_id == 55 && spawn->level == 3, "loại, mẫu, cấp");
        context.expect(near_value(spawn->x, 16.5F) && near_value(spawn->z, 16.9F), "centimet thành mét");
        context.expect(near_value(spawn->speed, 4.2F), "tốc độ centimet mỗi giây thành mét mỗi giây");
        context.expect(spawn->pose == cast::Pose::kWalk && spawn->hp_percent == 80, "trạng thái và sinh lực");
        context.expect(near_value(spawn->facing, 0.0F), "hướng dây π/2 (về +Z) là hướng client 0 (cũng +Z)");
    }

    protocol::EntityPos at_plus_x;
    at_plus_x.id = 1;
    at_plus_x.direction = 0;
    const auto plus_x = client::online::note_of(Event{World{.message = at_plus_x}});
    const auto* moved = plus_x ? std::get_if<cast::Moved>(&*plus_x) : nullptr;
    context.expect(moved != nullptr && near_value(moved->facing, kHalfPi), "hướng dây 0 (+X) là hướng client π/2");
    protocol::EntityPos at_minus_x;
    at_minus_x.id = 1;
    at_minus_x.direction = 32768;
    const auto minus_x = client::online::note_of(Event{World{.message = at_minus_x}});
    const auto* back = minus_x ? std::get_if<cast::Moved>(&*minus_x) : nullptr;
    context.expect(back != nullptr && near_value(back->facing, -kHalfPi), "hướng dây π (-X) là hướng client -π/2");

    const auto pulled = client::online::note_of(Event{World{.message = protocol::Position{.x_cm = 300.0F, .z_cm = 50.0F, .tick = 9}}});
    const auto* back_to = pulled ? std::get_if<cast::Pulled>(&*pulled) : nullptr;
    context.expect(back_to != nullptr && near_value(back_to->x, 3.0F) && near_value(back_to->z, 0.5F), "Position đang chơi là Pulled");

    protocol::EntityPosBatch batch;
    protocol::PosEntry first;
    first.id = 4;
    first.x_cm = 250.0F;
    first.z_cm = 50.0F;
    first.direction = 0;
    first.tick = 2;
    first.state = protocol::EntityState::kWalk;
    protocol::PosEntry second = first;
    second.id = 5;
    second.x_cm = 450.0F;
    second.tick = 3;
    second.state = protocol::EntityState::kIdle;
    batch.places.push_back(first);
    batch.places.push_back(second);
    std::vector<cast::Note> notes;
    const std::size_t added = client::online::append_positions(notes, batch, 8);
    context.expect(added == 2 && notes.size() == 2, "lô thành hai tin đi, đúng thứ tự");
    const auto* lead = std::get_if<cast::Moved>(&notes[0]);
    const auto* tail = std::get_if<cast::Moved>(&notes[1]);
    context.expect(lead != nullptr && lead->id == 4 && near_value(lead->x, 2.5F) && lead->pose == cast::Pose::kWalk, "mục đầu");
    context.expect(tail != nullptr && tail->id == 5 && near_value(tail->x, 4.5F) && tail->tick == 3, "mục sau");
    notes.clear();
    context.expect(client::online::append_positions(notes, batch, 0) == 0 && notes.empty(), "đầy trần thì không áp một phần");
    context.expect(!client::online::note_of(Event{World{.message = protocol::UiConfig{}}}), "UiConfig không phải tin thế giới");
    context.expect(!client::online::note_of(Event{client::session::Roster{}}), "Roster không phải tin thế giới");
}

void bridge_delivers_world_notes(Context& context) {
    namespace cast = client::cast;
    FakeGate fake;
    fake.set_mode(Mode::kWorld);
    Bridge bridge{book_of(fake)};
    std::vector<cast::Note> notes;
    context.expect(enter_fake_world(bridge, notes), "vào game");
    pump_for(bridge, notes, 400ms);

    const auto* arrive = find_note<cast::Arrive>(notes);
    context.expect(arrive != nullptr && arrive->scene == 2 && arrive->self_id == 100, "SceneEnter mang cảnh và id của mình");
    context.expect(arrive != nullptr && near_value(arrive->x, 165.0F) && near_value(arrive->z, 169.0F), "chỗ đứng đầu");
    context.expect(find_note<cast::Pulled>(notes) == nullptr, "Position đầu của phiên không phải kéo về");
    const auto* spawn = find_note<cast::Spawn>(notes);
    context.expect(spawn != nullptr && spawn->id == 7 && spawn->template_id == 1234 && spawn->kind == cast::Kind::kMonster, "quái hiện");
    const auto* moved = find_note<cast::Moved>(notes);
    context.expect(moved != nullptr && moved->pose == cast::Pose::kWalk && moved->tick == 5 && near_value(moved->x, 171.0F), "quái đi");
    const auto* hurt = find_note<cast::Hurt>(notes);
    context.expect(hurt != nullptr && hurt->hp_percent == 50, "mất sinh lực");
    const auto* gone = find_note<cast::Vanish>(notes);
    context.expect(gone != nullptr && gone->id == 7, "quái biến mất");
    // Thứ tự của dây được giữ: hiện trước, biến mất sau.
    std::size_t at_spawn = notes.size();
    std::size_t at_vanish = 0;
    for (std::size_t at = 0; at < notes.size(); ++at) {
        if (std::holds_alternative<cast::Spawn>(notes[at])) at_spawn = at;
        if (std::holds_alternative<cast::Vanish>(notes[at])) at_vanish = at;
    }
    context.expect(at_spawn < at_vanish, "giữ thứ tự hiện rồi mất");
    context.expect(bridge.take_notes().empty(), "lấy rồi thì hết");
}

void report_sends_moves_at_a_steady_pace(Context& context) {
    FakeGate fake;
    Bridge bridge{book_of(fake)};
    std::vector<client::cast::Note> notes;
    context.expect(enter_fake_world(bridge, notes), "vào game");
    context.expect(fake.game_platform() == static_cast<std::uint8_t>(protocol::Platform::kWindows), "Hello khai nền tảng của bản dựng");
    // Qua khoảng im lặng sau khi máy chủ đặt chỗ đứng.
    pump_for(bridge, notes, 250ms);

    // Báo dồn dập trong 300 ms, mỗi lần một chỗ khác: nhịp 50 ms cho nhiều nhất bảy gói, gói cuối mang chỗ mới.
    const auto begin = std::chrono::steady_clock::now();
    float x_m = 165.0F;
    while (std::chrono::steady_clock::now() - begin < 300ms) {
        x_m += 0.01F;
        bridge.report(x_m, 169.0F);
        std::this_thread::sleep_for(2ms);
    }
    pump_for(bridge, notes, 150ms);
    const std::vector<protocol::Move> sent = fake.moves();
    context.expect(!sent.empty() && sent.size() <= 8, "nhịp gửi có trần, không mỗi lần báo một gói");
    if (sent.empty()) return;
    bool is_ordered = true;
    for (std::size_t at = 1; at < sent.size(); ++at) is_ordered = is_ordered && sent[at].tick >= sent[at - 1].tick;
    context.expect(is_ordered, "tick không lùi");
    context.expect(sent.front().tick > 0, "tick tính từ lúc máy chủ đặt chỗ đứng, không phải 0");
    context.expect(near_value(sent.back().z_cm, 16900.0F), "centimet");
    context.expect(sent.back().x_cm > sent.front().x_cm, "gói sau mang chỗ mới hơn");

    // Cùng một chỗ báo lại hay chỗ không hữu hạn thì không gửi thêm.
    const float last_x = x_m;
    pump_for(bridge, notes, 120ms);
    const std::size_t before = fake.moves().size();
    for (int again = 0; again < 40; ++again) {
        bridge.report(last_x, 169.0F);
        bridge.report(std::numeric_limits<float>::quiet_NaN(), 169.0F);
        std::this_thread::sleep_for(5ms);
    }
    pump_for(bridge, notes, 150ms);
    context.expect(fake.moves().size() <= before + 1, "chỗ cũ báo lại không sinh gói (chỉ chấp nhận gói đang chờ của lần báo trước)");
    const std::size_t after = fake.moves().size();
    bridge.report(std::numeric_limits<float>::infinity(), 169.0F);
    pump_for(bridge, notes, 150ms);
    context.expect(fake.moves().size() == after, "vô cực không đi ra dây");
}

// Đếm Move mà guard::Pace của máy chủ không nhận. Đồng hồ máy chủ cho đi cùng tick client nên chỉ tick khai quyết định
// thời gian được tính cho mỗi bước.
[[nodiscard]] std::size_t refused_by_pace(std::span<const protocol::Move> sent, guard::Anchor start) {
    guard::Pace pace;
    pace.reset(start, 0, 0);
    std::size_t refused = 0;
    for (const protocol::Move& move : sent) {
        const guard::Step step{.x_cm = move.x_cm, .z_cm = move.z_cm, .tick = move.tick};
        if (pace.observe(step, move.tick) != guard::Verdict::kOk) ++refused;
    }
    return refused;
}

// Chạy đều ở tốc độ chạy với nhịp khung chừng 8 ms: không Move nào bị máy chủ kéo về. Hiệu tick giữa hai Move phải phủ
// đủ thời gian thật giữa hai chỗ đứng; làm tròn tick tuyệt đối thì hiệu hụt tới gần một tick (14 cm ở 4,2 m/s).
void running_moves_pass_the_pace(Context& context) {
    FakeGate fake;
    Bridge bridge{book_of(fake)};
    std::vector<client::cast::Note> notes;
    context.expect(enter_fake_world(bridge, notes), "vào game");
    pump_for(bridge, notes, 250ms);

    constexpr float kRunMetersPerSecond = 4.2F;
    constexpr float kRunSeconds = 1.5F;
    const auto begin = std::chrono::steady_clock::now();
    while (true) {
        const std::chrono::duration<float> ran = std::chrono::steady_clock::now() - begin;
        if (ran.count() > kRunSeconds) break;
        bridge.report(165.0F + (kRunMetersPerSecond * ran.count()), 169.0F);
        std::this_thread::sleep_for(8ms);
    }
    pump_for(bridge, notes, 150ms);
    const std::vector<protocol::Move> sent = fake.moves();
    context.expect(sent.size() >= 10, "đủ gói để đo");
    const std::size_t refused = refused_by_pace(sent, guard::Anchor{.x_cm = 16500.0F, .z_cm = 16900.0F});
    context.expect(refused == 0, "không Move nào bị guard::Pace từ chối khi chạy đều");
    if (refused != 0) std::println("  {} trên {} Move bị từ chối", refused, sent.size());
}

void pull_back_rebases_the_tick(Context& context) {
    namespace cast = client::cast;
    FakeGate fake;
    fake.set_mode(Mode::kPullBack);
    Bridge bridge{book_of(fake)};
    std::vector<cast::Note> notes;
    context.expect(enter_fake_world(bridge, notes), "vào game");
    pump_for(bridge, notes, 250ms);

    bridge.report(166.0F, 169.0F);
    pump_for(bridge, notes, 300ms);
    const auto* pulled = find_note<cast::Pulled>(notes);
    context.expect(pulled != nullptr && near_value(pulled->x, 165.0F) && near_value(pulled->z, 169.0F), "bị kéo về chỗ máy chủ giữ");
    context.expect(fake.moves().size() == 1, "mới gửi một Move");

    bridge.report(166.5F, 169.0F);
    pump_for(bridge, notes, 400ms);
    const std::vector<protocol::Move> sent = fake.moves();
    context.expect(sent.size() == 2, "sau khoảng im lặng, chỗ đứng mới đi ra dây");
    if (sent.size() == 2) context.expect(sent[1].tick >= 1000, "tick đếm tiếp từ tick máy chủ giao trong Position");
}

// Tin hội thoại v5 của máy chủ thành kiểu của giao diện: chữ giữ nguyên, enum đổi đúng, danh sách giữ thứ tự.
void hear_of_converts_dialogue(Context& context) {
    using client::session::Event;
    using client::session::World;
    namespace talk = ui::panel::talk;

    protocol::DialogOpen open;
    open.session = 42;
    open.npc = 7;
    open.mode = protocol::DialogMode::kMissionInfo;
    open.lines = {protocol::DialogLine{.text = "#R第一行#W"}, protocol::DialogLine{.text = "第二行"}};
    open.choices = {protocol::DialogChoice{.index = 4, .icon = 6, .text = "接受"}};
    open.marks = {protocol::DialogMark{.quest = 1201, .stage = protocol::MarkStage::kReady}};
    open.panel_quest = 1201;
    open.bonuses = {protocol::DialogBonus{.kind = protocol::BonusKind::kRadio, .a = 10100001, .b = 2, .c = 3}};
    const auto heard = client::online::hear_of(Event{World{.message = open}});
    const auto* dialog = heard ? std::get_if<talk::Dialog>(&*heard) : nullptr;
    context.expect(dialog != nullptr, "DialogOpen thành Dialog");
    if (dialog == nullptr) return;
    context.expect(dialog->session == 42 && dialog->npc == 7 && dialog->mode == talk::Mode::kMissionInfo, "phiên, NPC, chế độ");
    context.expect(dialog->lines.size() == 2 && dialog->lines[0] == "#R第一行#W", "dòng giữ nguyên chữ và thẻ màu");
    context.expect(dialog->choices.size() == 1 && dialog->choices[0].index == 4 && dialog->choices[0].icon == 6 &&
            dialog->choices[0].text == "接受",
        "lựa chọn");
    context.expect(dialog->marks.size() == 1 && dialog->marks[0].quest == 1201 && dialog->marks[0].stage == talk::Stage::kReady, "dấu");
    context.expect(dialog->panel_quest == 1201, "nhiệm vụ của bảng");
    context.expect(dialog->bonuses.size() == 1 && dialog->bonuses[0].kind == talk::BonusKind::kRadio &&
            dialog->bonuses[0].a == 10100001 && dialog->bonuses[0].b == 2 && dialog->bonuses[0].c == 3,
        "phần thưởng");

    const auto closed = client::online::hear_of(
        Event{World{.message = protocol::DialogClosed{.session = 42, .reason = protocol::DialogCloseReason::kFar}}});
    const auto* gone = closed ? std::get_if<talk::Closed>(&*closed) : nullptr;
    context.expect(gone != nullptr && gone->session == 42 && gone->reason == talk::Reason::kFar, "DialogClosed");
}

// Sổ nhiệm vụ: mảng "đã xong" 512 byte thành 128 từ little-endian, bit id % 32 của từ id / 32.
void hear_of_decodes_the_quest_book(Context& context) {
    using client::session::Event;
    using client::session::World;
    namespace talk = ui::panel::talk;

    protocol::QuestBook book;
    book.slots = {protocol::QuestSlot{.quest = 1201, .script = 5001, .flags = 3, .params = {1, 2, 3}}};
    // Nhiệm vụ 37 -> từ 1, bit 5; nhiệm vụ 4095 -> từ 127, bit 31; nhiệm vụ 0 -> từ 0, bit 0.
    const auto set_done = [&book](std::size_t quest) {
        const std::size_t word = quest / 32;
        const std::size_t bit = quest % 32;
        const std::size_t byte = (word * 4) + (bit / 8);
        book.done.at(byte) = static_cast<std::byte>(std::to_integer<unsigned>(book.done.at(byte)) | (1U << (bit % 8)));
    };
    set_done(0);
    set_done(37);
    set_done(4095);
    const auto heard = client::online::hear_of(Event{World{.message = book}});
    const auto* made = heard ? std::get_if<talk::Book>(&*heard) : nullptr;
    context.expect(made != nullptr, "QuestBook thành Book");
    if (made == nullptr) return;
    context.expect(made->slots.size() == 1 && made->slots[0].quest == 1201 && made->slots[0].script == 5001 &&
            made->slots[0].flags == 3 && made->slots[0].params == std::vector<std::uint32_t>({1, 2, 3}),
        "ô nhiệm vụ giữ tham số");
    context.expect(made->done[0] == 1U, "nhiệm vụ 0 là bit 0 của từ 0");
    context.expect(made->done[1] == (1U << 5), "nhiệm vụ 37 là bit 5 của từ 1");
    context.expect(made->done[127] == (1U << 31), "nhiệm vụ 4095 là bit 31 của từ 127");
    context.expect(made->done[2] == 0U && made->done[126] == 0U, "các từ khác trống");
}

void hear_of_stats_notices_and_refusals(Context& context) {
    using client::session::Event;
    using client::session::World;
    namespace talk = ui::panel::talk;

    const auto stats = client::online::hear_of(Event{World{.message = protocol::SelfStats{.level = 7, .exp = 900, .money = 12345, .bound_money = 6}}});
    const auto* mine = stats ? std::get_if<talk::Stats>(&*stats) : nullptr;
    context.expect(mine != nullptr && mine->level == 7 && mine->exp == 900 && mine->money == 12345 && mine->bound_money == 6, "SelfStats");

    protocol::QuestNotice notice;
    notice.kind = protocol::QuestNoticeKind::kRewardMoney;
    notice.quest = 1201;
    notice.text = "得到银两";
    notice.value = 500;
    notice.ref = 1;
    const auto noted = client::online::hear_of(Event{World{.message = notice}});
    const auto* line = noted ? std::get_if<talk::Notice>(&*noted) : nullptr;
    context.expect(line != nullptr && line->kind == talk::NoticeKind::kRewardMoney && line->quest == 1201 && line->value == 500 &&
            line->ref == 1 && line->text == "得到银两",
        "QuestNotice");

    const auto refused = client::online::hear_of(Event{World{.message = protocol::Reject{
        .request = protocol::QuestAccept::kKind, .code = protocol::ErrorCode::kQuestLogFull}}});
    const auto* no = refused ? std::get_if<talk::Refused>(&*refused) : nullptr;
    context.expect(no != nullptr && no->why == talk::Refusal::kQuestLogFull, "Reject của việc nhận nhiệm vụ");
    const auto elsewhere = client::online::hear_of(Event{World{.message = protocol::Reject{
        .request = protocol::Move::kKind, .code = protocol::ErrorCode::kMoveBlocked}}});
    context.expect(!elsewhere, "Reject của việc ngoài hộp thoại không thuộc nhóm này");
    const auto unrelated = client::online::hear_of(Event{World{.message = protocol::EntityVitals{.id = 1, .hp_percent = 3}}});
    context.expect(!unrelated, "tin thế giới khác không phải tin hội thoại");

    protocol::SelfBag bag;
    bag.slots.push_back(protocol::BagSlot{.slot = 4, .item = 0, .count = 3, .bound = false});
    bag.slots.push_back(protocol::BagSlot{.slot = 5, .item = 101, .count = 0, .bound = true});
    bag.slots.push_back(protocol::BagSlot{.slot = 2, .item = 10100001, .count = 12, .bound = true});
    bag.slots.push_back(protocol::BagSlot{.slot = 80, .item = 7, .count = 1, .bound = false});
    const auto heard_bag = client::online::hear_of(Event{World{.message = bag}});
    const auto* held = heard_bag ? std::get_if<talk::Bag>(&*heard_bag) : nullptr;
    context.expect(held != nullptr && held->slots.size() == 2, "SelfBag bỏ ô trống");
    if (held == nullptr || held->slots.size() != 2) return;
    context.expect(held->slots[0].slot == 2 && held->slots[0].item == 10100001 && held->slots[0].count == 12 &&
            held->slots[0].bound,
        "ô có đồ giữ chỉ số, mẫu, số chồng và cờ khoá");
    context.expect(held->slots[1].slot == 80 && held->slots[1].item == 7 && held->slots[1].count == 1 && !held->slots[1].bound,
        "ô ngoài lưới vẫn giữ trong ảnh, phần vẽ mới bỏ");
    protocol::SelfBag huge;
    for (std::uint16_t index = 0; index < 300; ++index) {
        huge.slots.push_back(protocol::BagSlot{.slot = index, .item = 1, .count = 1, .bound = false});
    }
    const auto heard_huge = client::online::hear_of(Event{World{.message = huge}});
    const auto* capped = heard_huge ? std::get_if<talk::Bag>(&*heard_huge) : nullptr;
    context.expect(capped != nullptr && capped->slots.size() == talk::kBagSlots, "ảnh túi cắt ở 256 ô");
}

void speech_of_maps_every_request(Context& context) {
    namespace talk = ui::panel::talk;
    using client::online::speech_of;

    const auto said = speech_of(talk::Talk{.npc = 9});
    const auto* hello = std::get_if<protocol::Talk>(&said);
    context.expect(hello != nullptr && hello->npc == 9, "Talk");
    const auto chose = speech_of(talk::Choose{.session = 8, .index = 3});
    const auto* choice = std::get_if<protocol::DialogChoose>(&chose);
    context.expect(choice != nullptr && choice->session == 8 && choice->index == 3, "DialogChoose");
    const auto accepted = speech_of(talk::Accept{.session = 8, .quest = 1201});
    const auto* accept = std::get_if<protocol::QuestAccept>(&accepted);
    context.expect(accept != nullptr && accept->session == 8 && accept->quest == 1201, "QuestAccept");
    const auto turned = speech_of(talk::TurnIn{.session = 8, .quest = 1201, .reward = 10100002});
    const auto* turn = std::get_if<protocol::QuestTurnIn>(&turned);
    context.expect(turn != nullptr && turn->session == 8 && turn->quest == 1201 && turn->reward == 10100002, "QuestTurnIn");
    const auto dropped = speech_of(talk::Abandon{.quest = 1201});
    const auto* abandon = std::get_if<protocol::QuestAbandon>(&dropped);
    context.expect(abandon != nullptr && abandon->quest == 1201, "QuestAbandon");
    const auto ended = speech_of(talk::Close{.session = 8});
    const auto* close = std::get_if<protocol::DialogClose>(&ended);
    context.expect(close != nullptr && close->session == 8, "DialogClose");
}

// Việc hộp thoại bị phiên từ chối (chưa vào game) không được trôi sang chuỗi đăng nhập như một lỗi đăng nhập.
void reply_of_ignores_refused_speech(Context& context) {
    using client::session::Ask;
    using client::session::Event;
    using client::session::Rejected;
    const auto reply = client::online::reply_of(
        Event{Rejected{.ask = Ask::kSpeak, .request = 0, .code = protocol::ErrorCode::kOutOfOrder}});
    context.expect(!reply, "Rejected của kSpeak không thành trả lời cho chuỗi đăng nhập");
    const auto other = client::online::reply_of(
        Event{Rejected{.ask = Ask::kEnter, .request = 0, .code = protocol::ErrorCode::kOutOfOrder}});
    context.expect(other.has_value(), "Rejected của việc đăng nhập vẫn là trả lời");
}

void note_of_flags(Context& context) {
    using client::session::Event;
    using client::session::World;
    namespace cast = client::cast;
    const auto note = client::online::note_of(Event{World{.message = protocol::EntityFlags{.id = 7, .flags = 1}}});
    const auto* flagged = note ? std::get_if<cast::Flagged>(&*note) : nullptr;
    context.expect(flagged != nullptr && flagged->id == 7 && flagged->flags == cast::kFlagTalk, "EntityFlags thành Flagged");
}

// Protocol v6: chiêu, đòn trúng và cái chết đổi sang mét của game và kiểu của cast; chữ "centimet" của dây không được lọt ra.
void note_of_fight(Context& context) {
    using client::session::Event;
    using client::session::World;
    namespace cast = client::cast;

    protocol::SkillCast started;
    started.seq = 3;
    started.source = 11;
    started.skill = 281;
    started.target = 21;
    started.x_cm = 1250.0F;
    started.z_cm = -300.0F;
    started.level = 4;
    const auto casting = client::online::note_of(Event{World{.message = started}});
    const auto* cast_note = casting ? std::get_if<cast::Casting>(&*casting) : nullptr;
    context.expect(cast_note != nullptr && cast_note->source == 11 && cast_note->skill == 281 && cast_note->target == 21 &&
            cast_note->seq == 3 && cast_note->level == 4 && std::fabs(cast_note->x - 12.5F) < 1e-4F &&
            std::fabs(cast_note->z + 3.0F) < 1e-4F,
        "SkillCast: id, số thứ tự, cấp và điểm nhắm centimet thành mét");

    const auto ended = client::online::note_of(Event{World{.message = protocol::SkillCastEnd{.source = 11, .skill = 281, .interrupted = true}}});
    const auto* end_note = ended ? std::get_if<cast::CastEnded>(&*ended) : nullptr;
    context.expect(end_note != nullptr && end_note->source == 11 && end_note->skill == 281 && end_note->is_interrupted, "SkillCastEnd");

    const std::array<std::pair<protocol::CombatKind, cast::Blow>, 4> kinds{{
        {protocol::CombatKind::kDamage, cast::Blow::kDamage},
        {protocol::CombatKind::kHeal, cast::Blow::kHeal},
        {protocol::CombatKind::kMiss, cast::Blow::kMiss},
        {protocol::CombatKind::kImmune, cast::Blow::kImmune},
    }};
    for (const auto& [wire, expected] : kinds) {
        protocol::CombatEvent event;
        event.source = 11;
        event.target = 21;
        event.skill = 281;
        event.kind = wire;
        event.value = 345;
        event.flags = 1;
        const auto blow = client::online::note_of(Event{World{.message = event}});
        const auto* struck = blow ? std::get_if<cast::Struck>(&*blow) : nullptr;
        context.expect(struck != nullptr && struck->kind == expected && struck->value == 345 && struck->is_critical &&
                struck->source == 11 && struck->target == 21,
            "CombatEvent giữ loại, giá trị và cờ hội tâm");
    }
    protocol::CombatEvent plain;
    plain.flags = 2;
    const auto quiet = client::online::note_of(Event{World{.message = plain}});
    const auto* quiet_blow = quiet ? std::get_if<cast::Struck>(&*quiet) : nullptr;
    context.expect(quiet_blow != nullptr && !quiet_blow->is_critical, "chỉ bit 0 là hội tâm");

    const auto died = client::online::note_of(Event{World{.message = protocol::EntityDied{.id = 21, .killer = 11}}});
    const auto* gone = died ? std::get_if<cast::Died>(&*died) : nullptr;
    context.expect(gone != nullptr && gone->id == 21 && gone->killer == 11, "EntityDied");
}

void hear_of_fight(Context& context) {
    using client::session::Event;
    using client::session::World;
    namespace talk = ui::panel::talk;

    const auto vitals = client::online::hear_of(Event{World{.message = protocol::SelfVitals{
        .hp = 90, .hp_max = 100, .mp = 30, .mp_max = 60, .rage = 5, .rage_max = 100}}});
    const auto* mine = vitals ? std::get_if<talk::Vitals>(&*vitals) : nullptr;
    context.expect(mine != nullptr && mine->hp == 90 && mine->hp_max == 100 && mine->mp == 30 && mine->mp_max == 60 &&
            mine->rage == 5 && mine->rage_max == 100,
        "SelfVitals");

    protocol::SelfSkills list;
    list.skills.push_back(protocol::SkillEntry{.skill = 281, .level = 1, .cooldown_ms = 0});
    list.skills.push_back(protocol::SkillEntry{.skill = 282, .level = 2, .cooldown_ms = 1500});
    const auto learned = client::online::hear_of(Event{World{.message = list}});
    const auto* skills = learned ? std::get_if<talk::Skills>(&*learned) : nullptr;
    context.expect(skills != nullptr && skills->learned.size() == 2 && skills->learned[1].skill == 282 && skills->learned[1].level == 2 &&
            skills->learned[1].cooldown_ms == 1500,
        "SelfSkills giữ thứ tự, cấp và hồi chiêu còn lại");

    const auto cooled = client::online::hear_of(Event{World{.message = protocol::SkillCooldown{.skill = 281, .ms = 2400}}});
    const auto* cooldown = cooled ? std::get_if<talk::Cooldown>(&*cooled) : nullptr;
    context.expect(cooldown != nullptr && cooldown->skill == 281 && cooldown->ms == 2400, "SkillCooldown");

    const auto lost = client::online::hear_of(Event{World{.message = protocol::DeathNotice{.exp_lost = 70, .money_lost = 8}}});
    const auto* slain = lost ? std::get_if<talk::Slain>(&*lost) : nullptr;
    context.expect(slain != nullptr && slain->exp_lost == 70 && slain->money_lost == 8, "DeathNotice");

    const std::array<std::pair<protocol::ErrorCode, talk::Decline>, 12> codes{{
        {protocol::ErrorCode::kNotLearned, talk::Decline::kNotLearned},
        {protocol::ErrorCode::kCooldown, talk::Decline::kCooldown},
        {protocol::ErrorCode::kNotEnoughMana, talk::Decline::kNotEnoughMana},
        {protocol::ErrorCode::kNotEnoughRage, talk::Decline::kNotEnoughRage},
        {protocol::ErrorCode::kBadTarget, talk::Decline::kBadTarget},
        {protocol::ErrorCode::kOutOfRange, talk::Decline::kOutOfRange},
        {protocol::ErrorCode::kCannotAttack, talk::Decline::kCannotAttack},
        {protocol::ErrorCode::kNoSuchEntity, talk::Decline::kGone},
        {protocol::ErrorCode::kDead, talk::Decline::kDead},
        {protocol::ErrorCode::kNotDead, talk::Decline::kNotDead},
        {protocol::ErrorCode::kNotYours, talk::Decline::kNotYours},
        {protocol::ErrorCode::kBusy, talk::Decline::kBusy},
    }};
    for (const auto& [wire, expected] : codes) {
        const auto refused = client::online::hear_of(Event{World{.message = protocol::Reject{
            .request = protocol::CastSkill::kKind, .code = wire}}});
        const auto* declined = refused ? std::get_if<talk::Declined>(&*refused) : nullptr;
        context.expect(declined != nullptr && declined->why == expected, "Reject của CastSkill thành Declined theo mã lỗi");
    }
    for (const std::uint16_t request : {protocol::Respawn::kKind, protocol::PickUp::kKind}) {
        const auto refused = client::online::hear_of(Event{World{.message = protocol::Reject{
            .request = request, .code = protocol::ErrorCode::kNotDead}}});
        context.expect(refused && std::holds_alternative<talk::Declined>(*refused), "Reject của hồi sinh và nhặt đồ cũng là Declined");
    }
    const auto other = client::online::hear_of(Event{World{.message = protocol::Reject{
        .request = protocol::CastSkill::kKind, .code = protocol::ErrorCode::kMalformed}}});
    const auto* odd = other ? std::get_if<talk::Declined>(&*other) : nullptr;
    context.expect(odd != nullptr && odd->why == talk::Decline::kOther, "mã lỗi lạ thành kOther, không thành Refused của hộp thoại");
    const auto talk_refusal = client::online::hear_of(Event{World{.message = protocol::Reject{
        .request = protocol::Talk::kKind, .code = protocol::ErrorCode::kDead}}});
    context.expect(talk_refusal && std::holds_alternative<talk::Refused>(*talk_refusal), "Reject của hộp thoại vẫn là Refused");
}

void speech_of_fight(Context& context) {
    namespace talk = ui::panel::talk;
    using client::online::speech_of;

    const auto cast = speech_of(talk::Cast{.seq = 9, .skill = 281, .target = 21, .x = 12.5F, .z = -3.0F});
    const auto* send = std::get_if<protocol::CastSkill>(&cast);
    context.expect(send != nullptr && send->seq == 9 && send->skill == 281 && send->target == 21 &&
            std::fabs(send->x_cm - 1250.0F) < 1e-3F && std::fabs(send->z_cm + 300.0F) < 1e-3F,
        "CastSkill: mét của game thành centimet của dây");
    const auto town = speech_of(talk::Revive{.place = talk::Place::kTown});
    const auto here = speech_of(talk::Revive{.place = talk::Place::kHere});
    const auto* town_send = std::get_if<protocol::Respawn>(&town);
    const auto* here_send = std::get_if<protocol::Respawn>(&here);
    context.expect(town_send != nullptr && town_send->place == protocol::RespawnPlace::kTown && here_send != nullptr &&
            here_send->place == protocol::RespawnPlace::kHere,
        "Respawn giữ nơi hồi sinh");
    const auto pick = speech_of(talk::PickUp{.drop = 4001});
    const auto* pick_send = std::get_if<protocol::PickUp>(&pick);
    context.expect(pick_send != nullptr && pick_send->drop == 4001, "PickUp");
}

constexpr std::array kCases{
    Case{.name = "note_of_fight", .body = &note_of_fight},
    Case{.name = "hear_of_fight", .body = &hear_of_fight},
    Case{.name = "speech_of_fight", .body = &speech_of_fight},
    Case{.name = "fault_of_error_codes", .body = &fault_of_error_codes},
    Case{.name = "fault_of_lost_reasons", .body = &fault_of_lost_reasons},
    Case{.name = "role_of_keeps_server_facts", .body = &role_of_keeps_server_facts},
    Case{.name = "reply_of_events", .body = &reply_of_events},
    Case{.name = "bridge_lists_only_gated_servers", .body = &bridge_lists_only_gated_servers},
    Case{.name = "bridge_unknown_server_is_refused_at_once", .body = &bridge_unknown_server_is_refused_at_once},
    Case{.name = "bridge_wipes_the_password", .body = &bridge_wipes_the_password},
    Case{.name = "bridge_walks_sign_in_create_enter", .body = &bridge_walks_sign_in_create_enter},
    Case{.name = "bridge_reports_refusal_and_loss", .body = &bridge_reports_refusal_and_loss},
    Case{.name = "note_of_converts_units", .body = &note_of_converts_units},
    Case{.name = "bridge_delivers_world_notes", .body = &bridge_delivers_world_notes},
    Case{.name = "report_sends_moves_at_a_steady_pace", .body = &report_sends_moves_at_a_steady_pace},
    Case{.name = "running_moves_pass_the_pace", .body = &running_moves_pass_the_pace},
    Case{.name = "pull_back_rebases_the_tick", .body = &pull_back_rebases_the_tick},
    Case{.name = "hear_of_converts_dialogue", .body = &hear_of_converts_dialogue},
    Case{.name = "hear_of_decodes_the_quest_book", .body = &hear_of_decodes_the_quest_book},
    Case{.name = "hear_of_stats_notices_and_refusals", .body = &hear_of_stats_notices_and_refusals},
    Case{.name = "speech_of_maps_every_request", .body = &speech_of_maps_every_request},
    Case{.name = "reply_of_ignores_refused_speech", .body = &reply_of_ignores_refused_speech},
    Case{.name = "note_of_flags", .body = &note_of_flags},
    Case{.name = "bridge_starts_the_network", .body = &bridge_starts_the_network},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "online_tests: mọi ca phải qua");
    return 0;
}
