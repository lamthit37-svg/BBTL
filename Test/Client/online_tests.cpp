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
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "support/fake_gate.hpp"
#include "test.hpp"
#include "ui/panel/online.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/roles.hpp"

#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <numbers>
#include <optional>
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

constexpr std::array kCases{
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
    Case{.name = "pull_back_rebases_the_tick", .body = &pull_back_rebases_the_tick},
};

} // namespace
} // namespace game::test

int main() {
    const auto network = game::net::Network::start();
    game::core::check(network.has_value(), "online_tests: khởi động được thư viện mạng");
    game::core::check(game::test::run_all(game::test::kCases) == 0, "online_tests: mọi ca phải qua");
    return 0;
}
