/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/online/bridge.cpp
 *  PHÂN HỆ   : Client / Online / Bridge
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nối OnlineAsk và OnlineReply của panel với lệnh và sự kiện của phiên.
 *  - Dịch mã lỗi và ngắt kết nối của protocol sang OnlineFault; UiConfig đổi
 *    FrameStyle; bí mật của việc nhờ được xoá sau khi chuyển.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/online/bridge.hpp"

#include "client/cast/note.hpp"
#include "client/session/gates.hpp"
#include "client/session/machine.hpp"
#include "client/session/session.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "ui/panel/online.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/roles.hpp"

#include <cstddef>
#include <cstdint>
#include <numbers>
#include <optional>
#include <span>
#include <string>
#include <utility>
#include <variant>
#include <vector>

namespace game::client::online {
namespace {

using ui::panel::OnlineFault;
using ui::panel::OnlineReply;

[[nodiscard]] OnlineFault fault_of_goodbye(protocol::DisconnectReason reason) noexcept {
    switch (reason) {
    case protocol::DisconnectReason::kLoginElsewhere: return OnlineFault::kElsewhere;
    case protocol::DisconnectReason::kServerFull: return OnlineFault::kServerFull;
    case protocol::DisconnectReason::kProtocolViolation:
    case protocol::DisconnectReason::kVersionMismatch:
    case protocol::DisconnectReason::kContentMismatch: return OnlineFault::kProtocol;
    case protocol::DisconnectReason::kLoggedOut:
    case protocol::DisconnectReason::kIdle:
    case protocol::DisconnectReason::kKicked:
    case protocol::DisconnectReason::kShutdown: return OnlineFault::kClosed;
    }
    return OnlineFault::kClosed;
}

[[nodiscard]] OnlineReply plain(OnlineReply::Kind kind) {
    OnlineReply reply;
    reply.kind = kind;
    return reply;
}

[[nodiscard]] OnlineReply fault_reply(OnlineReply::Kind kind, OnlineFault fault) {
    OnlineReply reply = plain(kind);
    reply.fault = fault;
    return reply;
}

[[nodiscard]] OnlineReply roster_reply(const session::Roster& roster) {
    OnlineReply reply = plain(OnlineReply::Kind::kRoster);
    reply.roles.reserve(roster.characters.size());
    for (const protocol::CharacterSummary& character : roster.characters) reply.roles.push_back(role_of(character));
    return reply;
}

[[nodiscard]] OnlineReply entered_reply(const session::Entered& entered) {
    OnlineReply reply = plain(OnlineReply::Kind::kEntered);
    reply.scene = entered.character.scene;
    reply.x_cm = entered.position.x_cm;
    reply.z_cm = entered.position.z_cm;
    return reply;
}

[[nodiscard]] std::optional<OnlineReply> world_reply(const session::World& world) {
    const auto* config = std::get_if<protocol::UiConfig>(&world.message);
    if (config == nullptr) return std::nullopt;
    OnlineReply reply = plain(OnlineReply::Kind::kStyle);
    reply.style = config->avatar_frame == protocol::AvatarFrame::kSquare ? ui::panel::FrameStyle::kSquare
                                                                         : ui::panel::FrameStyle::kRound;
    return reply;
}

[[nodiscard]] std::optional<session::Command> command_of(const ui::panel::OnlineAsk& ask) {
    switch (ask.work) {
    case ui::panel::OnlineWork::kCreate: {
        session::Create made;
        made.name = ask.role.name;
        made.gender = ask.role.sex == 1 ? protocol::Gender::kMale : protocol::Gender::kFemale;
        made.face = ask.role.face;
        made.hair = ask.role.hair;
        return made;
    }
    case ui::panel::OnlineWork::kDelete: return session::Delete{.character = ask.role.id};
    case ui::panel::OnlineWork::kEnter: return session::Enter{.character = ask.role.id};
    case ui::panel::OnlineWork::kDrop: return session::Drop{};
    case ui::panel::OnlineWork::kSignIn: return std::nullopt;
    }
    return std::nullopt;
}

// Trần hàng chờ tin thế giới khi luồng game không lấy. Tin vị trí và sinh lực là trạng thái tức thời nên bỏ được; tin
// hiện, biến mất, vào cảnh và kéo về thì không.
constexpr std::size_t kNoteCap = 4096;

constexpr float kCmPerMeter = 100.0F;
constexpr float kDirectionSteps = 65536.0F;

[[nodiscard]] float meters(float centimeters) noexcept {
    return centimeters / kCmPerMeter;
}

// Hướng của dây: 0..65535 ứng với 0..2π, 0 là +X và tăng dần quay về +Z, tức vectơ (cos a, sin a) trên (x, z). Hướng của
// client là atan2(dx, dz) = π/2 - a.
[[nodiscard]] float facing_of(std::uint16_t direction) noexcept {
    const float angle = static_cast<float>(direction) * (2.0F * std::numbers::pi_v<float>) / kDirectionSteps;
    return (std::numbers::pi_v<float> / 2.0F) - angle;
}

[[nodiscard]] cast::Kind kind_of(protocol::EntityKind kind) noexcept {
    switch (kind) {
    case protocol::EntityKind::kPlayer: return cast::Kind::kPlayer;
    case protocol::EntityKind::kMonster: return cast::Kind::kMonster;
    case protocol::EntityKind::kNpc: return cast::Kind::kNpc;
    case protocol::EntityKind::kPet: return cast::Kind::kPet;
    case protocol::EntityKind::kDrop: return cast::Kind::kDrop;
    case protocol::EntityKind::kObject: return cast::Kind::kObject;
    }
    return cast::Kind::kObject;
}

[[nodiscard]] cast::Pose pose_of(protocol::EntityState state) noexcept {
    switch (state) {
    case protocol::EntityState::kIdle: return cast::Pose::kIdle;
    case protocol::EntityState::kWalk: return cast::Pose::kWalk;
    case protocol::EntityState::kDead: return cast::Pose::kDead;
    }
    return cast::Pose::kIdle;
}

[[nodiscard]] cast::Note spawn_note(const protocol::EntityAppear& shown) {
    cast::Spawn spawn;
    spawn.id = shown.id;
    spawn.kind = kind_of(shown.kind);
    spawn.template_id = shown.template_id;
    spawn.name = shown.name;
    spawn.level = shown.level;
    spawn.x = meters(shown.x_cm);
    spawn.z = meters(shown.z_cm);
    spawn.facing = facing_of(shown.direction);
    spawn.speed = meters(static_cast<float>(shown.speed_cm));
    spawn.hp_percent = shown.hp_percent;
    spawn.gender = shown.gender;
    spawn.face = shown.face;
    spawn.hair = shown.hair;
    spawn.school = shown.school;
    spawn.pose = pose_of(shown.state);
    return spawn;
}

struct NotePick {
    std::optional<cast::Note> operator()(const protocol::SceneEnter& entered) const {
        return cast::Arrive{.scene = entered.scene,
            .x = meters(entered.x_cm),
            .z = meters(entered.z_cm),
            .facing = facing_of(entered.direction),
            .self_id = entered.self_id};
    }
    std::optional<cast::Note> operator()(const protocol::EntityAppear& shown) const { return spawn_note(shown); }
    std::optional<cast::Note> operator()(const protocol::EntityDisappear& gone) const {
        return cast::Vanish{.id = gone.id};
    }
    std::optional<cast::Note> operator()(const protocol::EntityPos& moved) const {
        return cast::Moved{.id = moved.id,
            .x = meters(moved.x_cm),
            .z = meters(moved.z_cm),
            .facing = facing_of(moved.direction),
            .tick = moved.tick,
            .pose = pose_of(moved.state)};
    }
    std::optional<cast::Note> operator()(const protocol::EntityVitals& vitals) const {
        return cast::Hurt{.id = vitals.id, .hp_percent = vitals.hp_percent};
    }
    std::optional<cast::Note> operator()(const protocol::Position& spot) const {
        return cast::Pulled{.x = meters(spot.x_cm), .z = meters(spot.z_cm)};
    }
    template <typename Other>
    std::optional<cast::Note> operator()(const Other& /*message*/) const {
        return std::nullopt;
    }
};

// Xoá chữ nhạy cảm của việc nhờ sau khi đã chuyển đi.
void forget(std::string& secret) noexcept {
    secure::wipe_bytes(std::as_writable_bytes(std::span{secret.data(), secret.size()}));
    secret.clear();
}

} // namespace

OnlineFault fault_of(protocol::ErrorCode code) noexcept {
    switch (code) {
    case protocol::ErrorCode::kBadCredentials:
    case protocol::ErrorCode::kNotAuthenticated:
    case protocol::ErrorCode::kPasswordInvalid: return OnlineFault::kBadLogin;
    case protocol::ErrorCode::kServerFull: return OnlineFault::kServerFull;
    case protocol::ErrorCode::kBusy:
    case protocol::ErrorCode::kRateLimited: return OnlineFault::kBusy;
    case protocol::ErrorCode::kMaintenance: return OnlineFault::kMaintenance;
    case protocol::ErrorCode::kNameTaken: return OnlineFault::kNameTaken;
    case protocol::ErrorCode::kNameInvalid: return OnlineFault::kNameInvalid;
    case protocol::ErrorCode::kCharacterLimit: return OnlineFault::kRoleLimit;
    case protocol::ErrorCode::kNoSuchCharacter: return OnlineFault::kNoRole;
    case protocol::ErrorCode::kVersionMismatch:
    case protocol::ErrorCode::kMalformed:
    case protocol::ErrorCode::kOutOfOrder: return OnlineFault::kProtocol;
    default: return OnlineFault::kOther;
    }
}

OnlineFault fault_of(const session::Lost& lost) noexcept {
    switch (lost.fault) {
    case session::Fault::kUnreachable: return OnlineFault::kUnreachable;
    case session::Fault::kSecure: return OnlineFault::kSecure;
    case session::Fault::kProtocol: return OnlineFault::kProtocol;
    case session::Fault::kTimeout: return OnlineFault::kTimeout;
    case session::Fault::kQueueFull: return OnlineFault::kOther;
    case session::Fault::kGoodbye:
        return lost.reason ? fault_of_goodbye(*lost.reason) : OnlineFault::kClosed;
    }
    return OnlineFault::kOther;
}

ui::panel::Role role_of(const protocol::CharacterSummary& character) {
    ui::panel::Role role;
    role.id = character.id;
    role.name = character.name;
    role.sex = character.gender == protocol::Gender::kMale ? std::uint8_t{1} : std::uint8_t{0};
    role.face = character.face;
    role.hair = character.hair;
    role.level = character.level;
    role.sect = character.school;
    return role;
}

std::optional<OnlineReply> reply_of(const session::Event& event) {
    struct Pick {
        std::optional<OnlineReply> operator()(const session::Roster& roster) const { return roster_reply(roster); }
        std::optional<OnlineReply> operator()(const session::Rejected& rejected) const {
            return fault_reply(OnlineReply::Kind::kRefused, fault_of(rejected.code));
        }
        std::optional<OnlineReply> operator()(const session::Entered& entered) const { return entered_reply(entered); }
        std::optional<OnlineReply> operator()(const session::World& world) const { return world_reply(world); }
        std::optional<OnlineReply> operator()(const session::Lost& lost) const {
            return fault_reply(OnlineReply::Kind::kLost, fault_of(lost));
        }
    };
    return std::visit(Pick{}, event);
}

std::optional<cast::Note> note_of(const session::Event& event) {
    const auto* world = std::get_if<session::World>(&event);
    if (world == nullptr) return std::nullopt;
    return std::visit(NotePick{}, world->message);
}

Bridge::Bridge(session::GateBook book) : book_(std::move(book)) {}

Bridge::~Bridge() = default;

std::vector<ui::panel::ServerName> Bridge::servers() const {
    std::vector<ui::panel::ServerName> names;
    names.reserve(book_.gates.size());
    for (const session::Gate& gate : book_.gates) {
        names.push_back(ui::panel::ServerName{.area = gate.area, .server = gate.server});
    }
    return names;
}

session::Session& Bridge::line() {
    if (!session_) session_.emplace();
    return *session_;
}

void Bridge::refuse(OnlineFault fault) {
    immediate_.push_back(fault_reply(OnlineReply::Kind::kRefused, fault));
}

void Bridge::serve(std::span<ui::panel::OnlineAsk> asks) {
    for (ui::panel::OnlineAsk& ask : asks) {
        if (ask.work == ui::panel::OnlineWork::kSignIn) {
            const session::Gate* gate = session::find_gate(book_, ask.server.area, ask.server.server);
            if (gate == nullptr) {
                refuse(OnlineFault::kUnreachable);
            } else if (!line().submit(session::SignIn{.gate = *gate, .account = ask.account, .password = ask.password})) {
                refuse(OnlineFault::kBusy);
            }
            forget(ask.password);
            continue;
        }
        // Việc ngoài đăng nhập cần phiên đã dựng; trả phiên khi chưa có phiên thì không có gì để trả.
        if (!session_ && ask.work == ui::panel::OnlineWork::kDrop) continue;
        if (std::optional<session::Command> command = command_of(ask)) {
            if (!line().submit(std::move(*command))) refuse(OnlineFault::kBusy);
        }
    }
}

std::vector<OnlineReply> Bridge::collect() {
    std::vector<OnlineReply> replies = std::exchange(immediate_, {});
    if (!session_) return replies;
    for (const session::Event& event : session_->drain()) {
        std::optional<OnlineReply> reply = reply_of(event);
        if (reply) replies.push_back(std::move(*reply));
        std::optional<cast::Note> note = note_of(event);
        if (!note) continue;
        const bool is_state = std::holds_alternative<cast::Moved>(*note) || std::holds_alternative<cast::Hurt>(*note);
        if (is_state && notes_.size() >= kNoteCap) continue;
        notes_.push_back(std::move(*note));
    }
    return replies;
}

std::vector<cast::Note> Bridge::take_notes() {
    return std::exchange(notes_, {});
}

void Bridge::report(float x_m, float z_m) {
    if (session_) session_->report(x_m, z_m);
}

session::Phase Bridge::phase() const noexcept {
    return session_ ? session_->phase() : session::Phase::kIdle;
}

} // namespace game::client::online
