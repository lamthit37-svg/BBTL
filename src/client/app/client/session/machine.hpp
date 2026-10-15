/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/session/machine.hpp
 *  PHÂN HỆ   : Client / Session / Machine
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Máy trạng thái thuần của phiên mạng client: pha hiện tại, việc nào được
 *    nhờ ở pha nào, và tin của máy chủ ở pha nào thì làm gì. Không socket,
 *    không luồng, không đồng hồ: luồng mạng (session.cpp) hỏi nó trước mỗi bước
 *    nên mọi chuyển pha nằm ở một chỗ và kiểm được bằng bảng ca.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Trình tự hợp lệ (bot.cpp và gate/table.cpp là phía kia): kSigningIn gửi SignIn qua cổng xác thực lấy vé rồi Login
// qua cổng game; máy chủ đáp CharacterList (kChoosing). Từ kChoosing: CreateCharacter hoặc DeleteCharacter (kEditing,
// máy chủ đáp CharacterList mới hay Reject), hoặc EnterGame (kEntering, máy chủ đáp SessionStart, UiConfig, Position
// rồi các tin thế giới). Goodbye ở mọi pha là kLost. Bản mới của dự án.

#pragma once

#include "protocol/messages.hpp"

#include <cstdint>

namespace game::client::session {

enum class Phase : std::uint8_t {
    // Chưa nối gì, hoặc đã trả phiên.
    kIdle,
    // Đang nối và bắt tay cổng xác thực rồi cổng game; chưa có danh sách nhân vật.
    kSigningIn,
    // Có danh sách nhân vật, chờ người chơi chọn việc.
    kChoosing,
    // Đã gửi tạo hay xoá nhân vật, chờ danh sách mới.
    kEditing,
    // Đã gửi EnterGame, chờ Position.
    kEntering,
    // Đã vào game: nhận tin thế giới.
    kInGame,
    // Kết nối hỏng hay bị máy chủ đóng; chờ Drop để về kIdle.
    kLost,
};

// Việc người chơi nhờ phiên làm.
enum class Ask : std::uint8_t { kSignIn, kCreate, kDelete, kEnter, kDrop, kSpeak };

// Việc ask có được nhận ở pha phase không. kSignIn nhận ở kIdle và kLost (nối lại sau khi hỏng không cần Drop),
// kDrop nhận ở mọi pha, kSpeak chỉ nhận ở kInGame.
[[nodiscard]] bool allows(Phase phase, Ask ask) noexcept;

// Pha ngay sau khi nhận ask ở pha phase (đã qua allows).
[[nodiscard]] Phase begin(Phase phase, Ask ask) noexcept;

// Việc phải làm với một tin của máy chủ.
enum class Outcome : std::uint8_t {
    // Bỏ qua, không báo (Pong).
    kQuiet,
    // Chuyển cho game thread như một sự kiện.
    kDeliver,
    // Máy chủ từ chối việc đang chờ; báo cho game thread, pha về nơi nhận lại việc.
    kRejected,
    // Máy chủ báo đóng; pha kLost.
    kClosed,
    // Tin sai trình tự hay không thuộc pha: vi phạm giao thức, pha kLost.
    kViolation,
};

struct Step {
    Phase next = Phase::kLost;
    Outcome outcome = Outcome::kViolation;

    friend bool operator==(const Step&, const Step&) = default;
};

// Tin message của máy chủ đến ở pha phase.
[[nodiscard]] Step on_server(Phase phase, const protocol::GameServerMessage& message);

} // namespace game::client::session
