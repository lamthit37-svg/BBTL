/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/session/session.hpp
 *  PHÂN HỆ   : Client / Session / Session
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Phiên mạng của client: một luồng nền sở hữu link::Link (cổng xác thực lấy
 *    vé, rồi cổng game), nhận việc từ luồng game qua hàng đợi lệnh và trả sự
 *    kiện qua hàng đợi sự kiện. Luồng game không bao giờ chờ mạng: submit và
 *    drain chỉ giữ một khoá trong vài lệnh đẩy hay lấy, không I/O dưới khoá.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Cách hỏng đã tính trước (CL-03):
//   mạng đứt giữa chừng           -> Lost{kUnreachable} và đóng link; lệnh kế tiếp là SignIn hay Drop.
//   máy chủ gửi rác, khung hỏng   -> Lost{kProtocol} (record hỏng thì kSecure).
//   tin lạ hay sai trình tự       -> machine.hpp trả kViolation, Lost{kProtocol}.
//   máy chủ im                    -> mỗi lần chờ trả lời có hạn Timing::reply; im quá Timing::silence thì Lost{kTimeout}.
//   luồng game không rút sự kiện  -> hàng đợi có trần kEventCap: tin Entity* bỏ trước, nếu vẫn đầy thì Lost{kQueueFull}.
//   hàng đợi lệnh đầy             -> submit trả false.
//   thoát giữa lúc bắt tay        -> Link::open nhận stop_token nên huỷ trong khoảng 50 ms; hàm huỷ chờ luồng.
//   mật khẩu                      -> chỉ nằm trong lệnh SignIn và khung gửi đi; cả hai bị xoá ngay sau khi gửi.
// Bản mới của dự án.

#pragma once

#include "protocol/messages.hpp"
#include "client/session/gates.hpp"
#include "client/session/machine.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace game::client::session {

// Lệnh của luồng game.
struct SignIn {
    Gate gate;
    std::string account;
    std::string password;
};

struct Create {
    std::string name;
    protocol::Gender gender = protocol::Gender::kFemale;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
};

struct Delete {
    std::uint64_t character = 0;
};

struct Enter {
    std::uint64_t character = 0;
};

// Trả phiên: đóng link, về kIdle.
struct Drop {};

using Command = std::variant<SignIn, Create, Delete, Enter, Drop>;

// Vì sao một phiên mất.
enum class Fault : std::uint8_t {
    // Không nối được, hoặc đứt giữa chừng.
    kUnreachable,
    // Bắt tay hỏng (khoá không khớp khoá ghim) hoặc bản ghi hỏng.
    kSecure,
    // Khung hỏng, tin lạ hay sai trình tự.
    kProtocol,
    // Quá hạn chờ trả lời hoặc máy chủ im quá lâu.
    kTimeout,
    // Máy chủ báo Goodbye.
    kGoodbye,
    // Luồng game không rút sự kiện kịp.
    kQueueFull,
};

// Sự kiện cho luồng game.
// Danh sách nhân vật mới (sau SignIn, Create, Delete).
struct Roster {
    std::vector<protocol::CharacterSummary> characters;
};

// Máy chủ từ chối việc `ask` (request là mã tin bị từ chối, 0 khi từ chối ở phía client). Phiên vẫn dùng được.
struct Rejected {
    Ask ask = Ask::kDrop;
    std::uint16_t request = 0;
    protocol::ErrorCode code = protocol::ErrorCode::kMalformed;
};

// Máy chủ đã nhận EnterGame: nhân vật và chỗ đứng đầu tiên (Position đầu của phiên).
struct Entered {
    protocol::CharacterSummary character;
    protocol::Position position;
};

// Tin thế giới hay phần mở đầu phiên (UiConfig, SceneEnter, EntityAppear, Position kéo về...).
struct World {
    protocol::GameServerMessage message;
};

// Phiên hỏng hay bị đóng; `phase` là pha lúc đó. reason chỉ có khi fault là kGoodbye.
struct Lost {
    Fault fault = Fault::kUnreachable;
    Phase phase = Phase::kIdle;
    std::optional<protocol::DisconnectReason> reason{};
};

using Event = std::variant<Roster, Rejected, Entered, World, Lost>;

// Trần hàng đợi lệnh và hàng đợi sự kiện.
inline constexpr std::size_t kCommandCap = 16;
inline constexpr std::size_t kEventCap = 256;

// Nhịp tối thiểu giữa hai Move. Máy chủ đo bước theo đồng hồ của nó (guard::Pace) nên nhịp chỉ quyết định độ mịn của
// chuyển động người khác thấy và số gói gửi đi: 20 gói mỗi giây.
inline constexpr std::chrono::milliseconds kMoveEvery{50};

// Hạn chờ của phiên; mặc định là số chạy thật. Tách ra để test đo đường quá hạn mà không chờ cả chục giây.
struct Timing {
    // Hạn chờ máy chủ đáp một việc (đăng nhập có băm Argon2 phía máy chủ nên không để quá ngắn).
    std::chrono::milliseconds reply{10000};
    // Có link mà máy chủ im quá chừng này (kể cả Pong) thì coi như mất; gate ngắt khách im sau 10 giây.
    std::chrono::milliseconds silence{10000};
};

class Session {
public:
    // Chạy luồng nền ngay; chưa nối gì tới khi có SignIn.
    explicit Session(Timing timing = {});
    // Yêu cầu dừng, huỷ việc nối đang dở, chờ luồng thoát.
    ~Session();
    Session(const Session&) = delete;
    Session& operator=(const Session&) = delete;
    Session(Session&&) = delete;
    Session& operator=(Session&&) = delete;

    // Đẩy một lệnh; false khi hàng đợi lệnh đầy (kCommandCap). Không chặn. Lệnh không hợp pha bị luồng nền
    // từ chối bằng Rejected{kOutOfOrder}.
    [[nodiscard]] bool submit(Command command);
    // Lấy hết sự kiện đang chờ, theo thứ tự. Không chặn.
    [[nodiscard]] std::vector<Event> drain();
    // Pha hiện tại của luồng nền.
    [[nodiscard]] Phase phase() const noexcept;
    // Chỗ đứng hiện tại của nhân vật, mét của game (cùng đơn vị với cảnh; máy chủ dùng centimet). Ghi đè bản chưa gửi,
    // không xếp hàng: luồng nền chỉ gửi Move cho bản mới nhất, không quá một lần mỗi kMoveEvery, và chỉ khi đã vào game
    // và chỗ đứng khác lần gửi trước. Không chặn, an toàn mọi luồng.
    void report(float x_m, float z_m);

private:
    struct Shared;
    std::unique_ptr<Shared> shared_;
};

} // namespace game::client::session
