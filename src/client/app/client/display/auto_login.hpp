/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/auto_login.hpp
 *  PHÂN HỆ   : Client / Display / Auto Login
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đăng nhập tự động, chỉ để kiểm thử client thật với cụm máy chủ thật mà
 *    không bấm chuột: PC đặt biến môi trường THIENLONG_ACCOUNT, Android đặt
 *    thuộc tính debug.thienlong.account. Đi đúng chuỗi việc giao diện đăng nhập
 *    gửi (SignIn, Create khi tài khoản chưa có nhân vật, Enter nhân vật đầu),
 *    nên Bridge và máy chủ không phân biệt được với người bấm. Không có công
 *    tắc nào thì không chạy; bản phát hành không đặt công tắc.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Bị từ chối hay mất phiên thì dừng hẳn, không thử lại: lỗi phải hiện ra ở log, không bị vòng lặp che.

#pragma once

#include "ui/panel/online.hpp"
#include "ui/panel/roles.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::client {

struct AutoLogin {
    enum class Step : std::uint8_t { kSignIn, kRoster, kEnter, kPlay, kStopped };
    // Tên tài khoản; cũng là tên nhân vật được tạo.
    std::string account;
    Step step = Step::kSignIn;
};

// Mật khẩu của tài khoản thử: máy chủ đòi dài ít nhất 6 byte và khác tên tài khoản (server/account/rules.cpp).
[[nodiscard]] inline std::string auto_password(std::string_view account) {
    return std::string(account) + "-thu";
}

// Việc đầu tiên gửi máy chủ; sau đó chờ danh sách nhân vật.
[[nodiscard]] inline ui::panel::OnlineAsk auto_sign_in(AutoLogin& login, const ui::panel::ServerName& server) {
    login.step = AutoLogin::Step::kRoster;
    ui::panel::OnlineAsk ask;
    ask.work = ui::panel::OnlineWork::kSignIn;
    ask.server = server;
    ask.account = login.account;
    ask.password = auto_password(login.account);
    return ask;
}

// Ảnh chân dung nam đầu tiên mà máy chủ nhận lúc tạo (portraits.tsv, choice 3); bộ đồ tân thủ 0.
inline constexpr std::int32_t kAutoPortrait = 52;

// Nhân vật thử: nam, mặt 100, tóc 5, chân dung 52, bộ đồ 0 như thienlong_bot (bộ mặt, tóc, chân
// dung và bộ đồ máy chủ nhận); tên là tên tài khoản.
[[nodiscard]] inline ui::panel::Role auto_role(std::string_view account) {
    ui::panel::Role role;
    role.name = std::string(account);
    role.sex = 1;
    role.face = 100;
    role.hair = 5;
    role.portrait = kAutoPortrait;
    role.outfit = 0;
    return role;
}

// Việc kế tiếp sau một trả lời của máy chủ; rỗng khi không phải gửi gì. kEntered đưa sang kPlay: người gọi bấm "vào
// game" thay người chơi. Danh sách nhân vật chỉ được dùng ở bước kRoster, nên danh sách lặp lại không gửi Enter lần hai.
[[nodiscard]] inline std::optional<ui::panel::OnlineAsk> auto_next(AutoLogin& login,
    const ui::panel::OnlineReply& reply) {
    using Kind = ui::panel::OnlineReply::Kind;
    if (login.step == AutoLogin::Step::kStopped) return std::nullopt;
    if (reply.kind == Kind::kRefused || reply.kind == Kind::kLost) {
        login.step = AutoLogin::Step::kStopped;
        return std::nullopt;
    }
    if (reply.kind == Kind::kEntered) {
        login.step = AutoLogin::Step::kPlay;
        return std::nullopt;
    }
    if (reply.kind != Kind::kRoster || login.step != AutoLogin::Step::kRoster) return std::nullopt;
    ui::panel::OnlineAsk ask;
    if (reply.roles.empty()) {
        ask.work = ui::panel::OnlineWork::kCreate;
        ask.role = auto_role(login.account);
        return ask;
    }
    login.step = AutoLogin::Step::kEnter;
    ask.work = ui::panel::OnlineWork::kEnter;
    ask.role = reply.roles.front();
    return ask;
}

} // namespace game::client
