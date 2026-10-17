/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/session/machine.cpp
 *  PHÂN HỆ   : Client / Session / Machine
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Máy trạng thái thuần của phiên mạng: bảng chuyển pha theo tin của máy chủ
 *    và việc người chơi nhờ.
 *  - Không I/O; luồng phiên gọi để biết việc nào được phép ở pha nào.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/session/machine.hpp"
#include "protocol/messages.hpp"

#include <cstdint>
#include <type_traits>
#include <variant>

namespace game::client::session {
namespace {

// Tin của máy chủ gom theo vai trò trong trình tự, để bảng chuyển pha ngắn.
enum class Kind : std::uint8_t {
    kGoodbye,
    kReject,
    kPong,
    kRoster,
    // SessionStart, ContentKey, ContentStamp, UiConfig: phần mở đầu phiên sau EnterGame.
    kOpening,
    kPosition,
    // SceneEnter, EntityAppear, EntityDisappear, EntityPos, EntityPosBatch, EntityVitals.
    kWorld,
    // Welcome: chỉ hợp lệ một lần lúc bắt tay, lúc đó Link đã nhận.
    kStray,
};

template <typename Message>
[[nodiscard]] constexpr Kind kind_of() noexcept {
    using T = std::remove_cvref_t<Message>;
    if constexpr (std::is_same_v<T, protocol::Goodbye>) {
        return Kind::kGoodbye;
    } else if constexpr (std::is_same_v<T, protocol::Reject>) {
        return Kind::kReject;
    } else if constexpr (std::is_same_v<T, protocol::Pong>) {
        return Kind::kPong;
    } else if constexpr (std::is_same_v<T, protocol::CharacterList>) {
        return Kind::kRoster;
    } else if constexpr (std::is_same_v<T, protocol::SessionStart> || std::is_same_v<T, protocol::ContentKey> ||
                         std::is_same_v<T, protocol::ContentStamp> || std::is_same_v<T, protocol::UiConfig>) {
        return Kind::kOpening;
    } else if constexpr (std::is_same_v<T, protocol::Position>) {
        return Kind::kPosition;
    } else if constexpr (std::is_same_v<T, protocol::Welcome>) {
        return Kind::kStray;
    } else {
        return Kind::kWorld;
    }
}

[[nodiscard]] Kind classify(const protocol::GameServerMessage& message) {
    return std::visit([](const auto& held) { return kind_of<decltype(held)>(); }, message);
}

constexpr Step kViolation{.next = Phase::kLost, .outcome = Outcome::kViolation};

[[nodiscard]] constexpr Step stay(Phase phase, Outcome outcome) noexcept {
    return Step{.next = phase, .outcome = outcome};
}

[[nodiscard]] Step signing_in(Kind kind) noexcept {
    if (kind == Kind::kRoster) return stay(Phase::kChoosing, Outcome::kDeliver);
    if (kind == Kind::kReject) return stay(Phase::kIdle, Outcome::kRejected);
    if (kind == Kind::kPong) return stay(Phase::kSigningIn, Outcome::kQuiet);
    return kViolation;
}

[[nodiscard]] Step choosing(Kind kind) noexcept {
    if (kind == Kind::kRoster) return stay(Phase::kChoosing, Outcome::kDeliver);
    if (kind == Kind::kReject) return stay(Phase::kChoosing, Outcome::kRejected);
    if (kind == Kind::kPong) return stay(Phase::kChoosing, Outcome::kQuiet);
    return kViolation;
}

[[nodiscard]] Step editing(Kind kind) noexcept {
    if (kind == Kind::kRoster) return stay(Phase::kChoosing, Outcome::kDeliver);
    if (kind == Kind::kReject) return stay(Phase::kChoosing, Outcome::kRejected);
    if (kind == Kind::kPong) return stay(Phase::kEditing, Outcome::kQuiet);
    return kViolation;
}

[[nodiscard]] Step entering(Kind kind) noexcept {
    if (kind == Kind::kOpening || kind == Kind::kWorld) return stay(Phase::kEntering, Outcome::kDeliver);
    if (kind == Kind::kPosition) return stay(Phase::kInGame, Outcome::kDeliver);
    if (kind == Kind::kReject) return stay(Phase::kChoosing, Outcome::kRejected);
    if (kind == Kind::kPong) return stay(Phase::kEntering, Outcome::kQuiet);
    return kViolation;
}

[[nodiscard]] Step resuming(Kind kind) noexcept {
    const bool keep = kind == Kind::kOpening || kind == Kind::kWorld;
    if (keep) return stay(Phase::kResuming, Outcome::kDeliver);
    if (kind == Kind::kPosition) return stay(Phase::kInGame, Outcome::kDeliver);
    if (kind == Kind::kReject) return stay(Phase::kLost, Outcome::kRejected);
    if (kind == Kind::kPong) return stay(Phase::kResuming, Outcome::kQuiet);
    return kViolation;
}

[[nodiscard]] Step in_game(Kind kind) noexcept {
    if (kind == Kind::kOpening || kind == Kind::kWorld || kind == Kind::kPosition) {
        return stay(Phase::kInGame, Outcome::kDeliver);
    }
    if (kind == Kind::kReject) return stay(Phase::kInGame, Outcome::kRejected);
    if (kind == Kind::kPong) return stay(Phase::kInGame, Outcome::kQuiet);
    return kViolation;
}

} // namespace

bool can_resume(LinkBreak kind, Phase phase, bool have_token) noexcept {
    if (!have_token || kind == LinkBreak::kFatal) return false;
    return phase == Phase::kInGame || phase == Phase::kEntering || phase == Phase::kResuming;
}

bool resume_again(bool token_sent, LinkBreak kind, Phase phase, bool have_token) noexcept {
    if (token_sent) return false;
    return can_resume(kind, phase, have_token);
}

bool allows(Phase phase, Ask ask) noexcept {
    switch (ask) {
    case Ask::kSignIn:
        return phase == Phase::kIdle || phase == Phase::kLost || phase == Phase::kResuming;
    case Ask::kCreate:
    case Ask::kDelete:
    case Ask::kEnter: return phase == Phase::kChoosing;
    case Ask::kDrop: return true;
    case Ask::kSpeak: return phase == Phase::kInGame;
    }
    return false;
}

Phase begin(Phase phase, Ask ask) noexcept {
    switch (ask) {
    case Ask::kSignIn: return Phase::kSigningIn;
    case Ask::kCreate:
    case Ask::kDelete: return Phase::kEditing;
    case Ask::kEnter: return Phase::kEntering;
    case Ask::kDrop: return Phase::kIdle;
    case Ask::kSpeak: return phase;
    }
    return phase;
}

Step on_server(Phase phase, const protocol::GameServerMessage& message) {
    const Kind kind = classify(message);
    if (kind == Kind::kGoodbye) return stay(Phase::kLost, Outcome::kClosed);
    switch (phase) {
    case Phase::kIdle: return kViolation;
    case Phase::kSigningIn: return signing_in(kind);
    case Phase::kChoosing: return choosing(kind);
    case Phase::kEditing: return editing(kind);
    case Phase::kEntering: return entering(kind);
    case Phase::kInGame: return in_game(kind);
    case Phase::kResuming: return resuming(kind);
    case Phase::kLost: return stay(Phase::kLost, Outcome::kQuiet);
    }
    return kViolation;
}

} // namespace game::client::session
