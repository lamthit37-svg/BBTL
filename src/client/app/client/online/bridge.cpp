#include "client/online/bridge.hpp"

#include "client/session/gates.hpp"
#include "client/session/machine.hpp"
#include "client/session/session.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "ui/panel/online.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/roles.hpp"

#include <cstdint>
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
    }
    return replies;
}

session::Phase Bridge::phase() const noexcept {
    return session_ ? session_->phase() : session::Phase::kIdle;
}

} // namespace game::client::online
