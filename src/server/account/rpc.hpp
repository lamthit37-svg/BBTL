/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/account/rpc.hpp
 *  PHÂN HỆ   : Server / Account / Rpc
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Một yêu cầu, một kết nối, chỉ trên loopback. Gate đóng vai client; auth và
 *    store là server. Mã 0 là thành công. Mã khác là protocol::ErrorCode. Thân
 *    tối đa 8 KiB.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "account/book.hpp"
#include "account/cap.hpp"
#include "account/sql.hpp"
#include "net/net.hpp"
#include "secure/secure.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::account {

// Hai byte trên dây (rpc.cpp). Kiểu nền giữ u16: hẹp hơn thì mã 257 ép thành 1 (kCreateAccount) lúc đọc.
enum class Op : std::uint16_t { // NOLINT(performance-enum-size): kiểu nền khớp trường u16 của khung ipc
    kCreateAccount = 1,
    kSignIn = 2,
    kRedeem = 3,
    kList = 4,
    kCreateCharacter = 5,
    kDeleteCharacter = 6,
    kEnter = 7,
    // Store hỏi auth: tài khoản trong cap còn được chơi không (khoá, ban sau khi đăng nhập).
    kStanding = 8,
    // Zone ghi điểm đứng của nhân vật khi họ rời cảnh hay định kỳ. Không mang cap: zone là bên tin cậy (khoá cụm).
    kSave = 9,
};


struct Call {
    Op op = Op::kList;
    std::vector<std::byte> body;
};

struct Reply {
    std::uint16_t code = 0;
    std::vector<std::byte> body;
};

[[nodiscard]] Call account_call(Op op, std::string_view name, std::string_view password, std::string_view ip);
[[nodiscard]] Call redeem_call(std::string_view ticket_hex);
[[nodiscard]] Call list_call(std::span<const std::byte, kCapBytes> cap);
[[nodiscard]] Call character_call(std::span<const std::byte, kCapBytes> cap, std::string_view name,
    protocol::Gender gender, std::uint16_t face, std::uint16_t hair);
[[nodiscard]] Call standing_call(std::span<const std::byte, kCapBytes> cap);
[[nodiscard]] Call id_call(Op op, std::span<const std::byte, kCapBytes> cap, std::uint64_t character);
// nullopt khi trạng thái chơi đi kèm không đóng gói được (số ngoài miền, khối quá trần): gọi lại cũng vậy, nên không có Call.
[[nodiscard]] std::optional<Call> save_call(const SaveSpot& spot);

[[nodiscard]] bool read_account_call(const Call& call, std::string& name, std::string& password, std::string& ip);
[[nodiscard]] bool read_text_call(const Call& call, std::string& text);
[[nodiscard]] bool read_list_call(const Call& call, std::array<std::byte, kCapBytes>& cap);
[[nodiscard]] bool read_character_call(const Call& call, std::array<std::byte, kCapBytes>& cap, std::string& name,
    protocol::Gender& gender, std::uint16_t& face, std::uint16_t& hair);
[[nodiscard]] bool read_id_call(const Call& call, std::array<std::byte, kCapBytes>& cap, std::uint64_t& character);
// Thân sai cỡ hoặc toạ độ ngoài trần thì false.
[[nodiscard]] bool read_save_call(const Call& call, SaveSpot& spot);

[[nodiscard]] Reply reply_of(const TicketResult& result);
[[nodiscard]] Reply reply_of(const RedeemResult& result);
[[nodiscard]] Reply reply_of(const ListResult& result);
[[nodiscard]] Reply reply_of(const EnterResult& result);
// Trả lời Op::kEnter: như reply_of nhưng thân mang scene (u16), x_cm, z_cm (i32).
[[nodiscard]] Reply enter_reply_of(const EnterResult& result);

[[nodiscard]] TicketResult ticket_from(const Reply& reply);
[[nodiscard]] RedeemResult redeem_from(const Reply& reply);
[[nodiscard]] ListResult list_from(const Reply& reply);
[[nodiscard]] EnterResult enter_from(const Reply& reply);
// Đọc trả lời Op::kEnter. Thân sai cỡ hoặc toạ độ ngoài kSpotLimitCm thì không vào (kBusy).
[[nodiscard]] EnterResult entered_from(const Reply& reply);

[[nodiscard]] std::optional<Reply> exchange(const net::Endpoint& endpoint, const Call& call,
    std::chrono::milliseconds timeout, secure::ByteView key);

using Handler = Reply (*)(void* ctx, const Call& call);

// Chạy tới khi process::stop_requested. 0 khi dừng theo yêu cầu, 1 khi poll hỏng.
// key là khoá ipc 32 byte. Khung không mở được thì bỏ kết nối, không trả lời. Không chặn:
// tối đa 64 kết nối cùng lúc, mỗi kết nối 3 giây để gửi khung và 3 giây để nhận trả lời.
// Hàng database đầy thì trả Busy.
[[nodiscard]] int serve_loop(net::TcpListener& listener, Handler handler, void* ctx, secure::ByteView key);

} // namespace game::account
