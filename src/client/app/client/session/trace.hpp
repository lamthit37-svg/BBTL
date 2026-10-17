/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/session/trace.hpp
 *  PHÂN HỆ   : Client / Session / Trace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Vết mạng cho E2E: biến môi trường THIENLONG_NET_TRACE nêu tệp thì mỗi tin
 *    phiên gửi hay nhận ghi một dòng TSV (giờ_ms, gửi|nhận, tên, trường chính).
 *  - Tên tin lấy từ kiểu trong protocol/messages.hpp; mật khẩu và vé không bao
 *    giờ vào dòng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "protocol/messages.hpp"

#include <type_traits>

namespace game::client::session::trace {

// Bật khi biến môi trường THIENLONG_NET_TRACE nêu một tệp ghi được. Tắt thì mọi hàm dưới chỉ tốn
// một lần đọc cờ.
[[nodiscard]] bool is_on() noexcept;

// Ghi một dòng cho tin client vừa gửi xong / tin server vừa giải mã xong. Chỉ phiên mạng gọi.
void sent(const protocol::GameClientMessage& message);
void sent(const protocol::AuthClientMessage& message);
void received(const protocol::GameServerMessage& message);
void received(const protocol::AuthServerMessage& message);

// Gửi một tin riêng lẻ: chỉ khi đang bật mới chép nó vào variant. Tin có ở cả hai cổng (Hello)
// ghi như tin của cổng game.
template <typename Message>
void sent(const Message& message) {
    if (!is_on()) return;
    if constexpr (std::is_constructible_v<protocol::GameClientMessage, const Message&>) {
        const protocol::GameClientMessage held{message};
        sent(held);
    } else {
        const protocol::AuthClientMessage held{message};
        sent(held);
    }
}

} // namespace game::client::session::trace
