/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/online/bridge.hpp
 *  PHÂN HỆ   : Client / Online / Bridge
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cầu nối giữa giao diện đăng nhập và phiên mạng: nhận việc chuỗi đăng nhập
 *    nhờ (ui::panel::OnlineAsk) thành lệnh của client/session, và đổi sự kiện
 *    của phiên thành trả lời cho chuỗi (ui::panel::OnlineReply). Giữ bảng cổng
 *    máy chủ và phiên; phiên (một luồng) chỉ được dựng khi có lần đăng nhập đầu
 *    tiên, nên client không có máy chủ trực tuyến nào thì không tốn luồng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Gọi từ một luồng duy nhất (luồng cửa sổ): serve và collect không chặn, không I/O. Bản mới của dự án.

#pragma once

#include "client/cast/note.hpp"
#include "ui/panel/talk.hpp"
#include "client/session/gates.hpp"
#include "client/session/session.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "ui/panel/online.hpp"

#include <optional>
#include <span>
#include <vector>

namespace game::client::online {

// Lý do cho người chơi từ mã lỗi máy chủ, từ lý do mất phiên và từ lý do máy chủ đóng.
[[nodiscard]] ui::panel::OnlineFault fault_of(protocol::ErrorCode code) noexcept;
[[nodiscard]] ui::panel::OnlineFault fault_of(const session::Lost& lost) noexcept;

// Nhân vật của máy chủ thành nhân vật của sổ chọn. Chân dung và ảnh do chuỗi đăng nhập gán; bộ đồ để mặc định của giới
// (CharacterSummary chưa mang trang phục).
[[nodiscard]] ui::panel::Role role_of(const protocol::CharacterSummary& character);

// Một sự kiện của phiên thành trả lời cho chuỗi đăng nhập; không có khi sự kiện không cần chuỗi biết (tin thế giới
// mà client chưa dùng).
[[nodiscard]] std::optional<ui::panel::OnlineReply> reply_of(const session::Event& event);

// Một sự kiện của phiên thành tin thế giới cho nơi vẽ (vào cảnh, thực thể hiện, đi, biến mất, sinh lực, bị kéo về); không có
// khi sự kiện không phải tin thế giới. Đổi đơn vị ở đây: centimet của dây thành mét của game, hướng 0..65535 (0 là +X,
// quay về +Z) thành góc của client (atan2(dx, dz)).
[[nodiscard]] std::optional<cast::Note> note_of(const session::Event& event);

using Notes = std::vector<cast::Note>;
using PosBatch = protocol::EntityPosBatch;

// Đổ từng vị trí của một lô đã giải mã xong, theo thứ tự. Đầy cap thì dừng.
[[nodiscard]] std::size_t append_positions(Notes& notes, const PosBatch& batch, std::size_t cap);

// Một sự kiện của phiên thành tin hội thoại, sổ nhiệm vụ hay chỉ số bản thân; không có khi sự kiện không thuộc nhóm đó. Tin
// Reject của việc ngoài hộp thoại (mã tin ngoài 0x0601..0x0606) không phải của nhóm này. Chữ giữ nguyên như máy chủ dựng.
[[nodiscard]] std::optional<ui::panel::talk::Hear> hear_of(const session::Event& event);

// Việc người chơi nhờ thành lệnh gửi lên máy chủ.
[[nodiscard]] session::Speech speech_of(const ui::panel::talk::Say& say);

class Bridge {
public:
    explicit Bridge(session::GateBook book);
    ~Bridge();
    Bridge(const Bridge&) = delete;
    Bridge& operator=(const Bridge&) = delete;
    Bridge(Bridge&&) = delete;
    Bridge& operator=(Bridge&&) = delete;

    // Tên các máy chủ có cổng thật, để Display đánh dấu trong danh sách chọn máy chủ.
    [[nodiscard]] std::vector<ui::panel::ServerName> servers() const;
    // Làm các việc chuỗi đăng nhập nhờ, theo thứ tự. Mật khẩu trong asks bị xoá sau khi chuyển cho phiên.
    void serve(std::span<ui::panel::OnlineAsk> asks);
    // Trả lời đã sẵn cho chuỗi đăng nhập, theo thứ tự. Cũng gom tin thế giới của cùng các sự kiện vào hàng chờ của take_notes.
    [[nodiscard]] std::vector<ui::panel::OnlineReply> collect();
    // Tin thế giới đã gom ở các lần collect, theo thứ tự; lấy rồi thì hết.
    [[nodiscard]] std::vector<cast::Note> take_notes();
    // Chuyển việc hộp thoại và sổ nhiệm vụ cho phiên, theo thứ tự. Không có phiên hay hàng đợi lệnh đầy thì bỏ (người chơi
    // bấm lại được): đây là thao tác tức thời, không có gì để báo lỗi cho chuỗi đăng nhập.
    void speak(std::span<const ui::panel::talk::Say> says);
    // Tin hội thoại đã gom ở các lần collect, theo thứ tự; lấy rồi thì hết.
    [[nodiscard]] std::vector<ui::panel::talk::Hear> take_heard();
    // Chỗ đứng hiện tại của nhân vật, mét của game: phiên gửi Move khi đã vào game. Không có phiên thì bỏ.
    void report(float x_m, float z_m);
    // Pha của phiên; kIdle khi phiên chưa dựng.
    [[nodiscard]] session::Phase phase() const noexcept;

private:
    session::Session& line();
    void refuse(ui::panel::OnlineFault fault);

    // Thư viện mạng của tiến trình (WSAStartup trên Windows). Khai đầu tiên: huỷ sau cùng, sau phiên và mọi socket của
    // nó. Thiếu nó thì mọi socket hỏng và đăng nhập báo "không nối được máy chủ" dù máy chủ đang chạy (đo 2026-10-16).
    net::NetResult<net::Network> network_;
    session::GateBook book_;
    std::optional<session::Session> session_;
    // Trả lời tạo ngay lúc serve (máy chủ không có trong bảng cổng, hàng đợi lệnh đầy).
    std::vector<ui::panel::OnlineReply> immediate_;
    std::vector<cast::Note> notes_;
    std::vector<ui::panel::talk::Hear> heard_;
};

} // namespace game::client::online
