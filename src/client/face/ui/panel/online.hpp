// Cầu nối giữa chuỗi đăng nhập (đồng bộ, thuần, chạy ở luồng vẽ) và phần nối máy chủ (bất đồng bộ, luồng riêng):
// chuỗi đẩy OnlineAsk vào hàng chờ, phần nối lấy ra làm, rồi đưa OnlineReply về cho chuỗi. Kiểu ở đây không biết
// socket hay giao thức; chỉ có tên máy chủ, tài khoản, nhân vật và lý do thất bại cho người chơi.
// Máy chủ "trực tuyến" là máy chủ trong danh sách mà bảng cổng (client/session/gates.hpp) có dòng; máy chủ khác
// là máy chủ cục bộ, chuỗi giữ chế độ offline với sổ nhân vật ở tệp.
// Bản mới của dự án: client gốc nối máy chủ trong C++ của Game.exe, chuỗi Lua chỉ nhận kết quả qua sự kiện.
#pragma once

#include "ui/panel/player_frame.hpp"
#include "ui/panel/roles.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Tên một máy chủ của danh sách, đúng từng byte với LoginArea::name và LoginServer::name.
struct ServerName {
    std::string area;
    std::string server;

    friend bool operator==(const ServerName&, const ServerName&) = default;
};

// Trần số việc chờ lấy; chuỗi chỉ nhờ khi không còn việc nào đang chờ trả lời nên không bao giờ chạm trần.
inline constexpr std::size_t kAskCap = 8;

enum class OnlineWork : std::uint8_t { kSignIn, kCreate, kDelete, kEnter, kDrop };

struct OnlineAsk {
    OnlineWork work = OnlineWork::kDrop;
    // kSignIn: máy chủ đã chọn, tài khoản và mật khẩu. Người nhận xoá mật khẩu sau khi dùng.
    ServerName server{};
    std::string account{};
    std::string password{};
    // kCreate: tên, giới, mặt, tóc của nhân vật nháp. kDelete và kEnter: role.id.
    Role role{};
};

// Lý do một việc thất bại, hiện cho người chơi bằng online_text.
enum class OnlineFault : std::uint8_t {
    kUnreachable,
    kSecure,
    kProtocol,
    kTimeout,
    kBadLogin,
    kServerFull,
    kBusy,
    kMaintenance,
    kNameTaken,
    kNameInvalid,
    kRoleLimit,
    kNoRole,
    kElsewhere,
    kClosed,
    kOther,
};

// Câu hiện cho người chơi, chữ Trung như mọi chữ cứng của client (chủ dự án chốt 2026-10-13).
[[nodiscard]] std::string_view online_text(OnlineFault fault) noexcept;
// Câu "đang nối" hiện trong lúc chờ trả lời.
inline constexpr std::string_view kOnlineWaiting = "正在连接服务器…";

// Chân dung tạm cho nhân vật của máy chủ: CharacterSummary chưa mang chân dung nên dùng chân dung đầu của giới
// (id trong Table/portraits.tsv).
inline constexpr std::int32_t kFemalePortrait = 1;
inline constexpr std::int32_t kMalePortrait = 13;

struct OnlineReply {
    enum class Kind : std::uint8_t {
        // Danh sách nhân vật của tài khoản (sau đăng nhập, tạo, xoá).
        kRoster,
        // Máy chủ từ chối một việc; phiên còn dùng được.
        kRefused,
        // Mất phiên.
        kLost,
        // Máy chủ nhận EnterGame: chỗ đứng đầu tiên, cảnh theo resid của client.
        kEntered,
        // UiConfig: dạng khung chân dung do nhà phát hành đặt.
        kStyle,
    };

    Kind kind = Kind::kLost;
    std::vector<Role> roles;
    OnlineFault fault = OnlineFault::kOther;
    std::int32_t scene = 0;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    FrameStyle style = FrameStyle::kBuild;
};

} // namespace game::ui::panel
