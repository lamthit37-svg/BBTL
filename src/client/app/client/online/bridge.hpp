// Cầu nối giữa giao diện đăng nhập và phiên mạng: nhận việc chuỗi đăng nhập nhờ (ui::panel::OnlineAsk) thành lệnh
// của client/session, và đổi sự kiện của phiên thành trả lời cho chuỗi (ui::panel::OnlineReply). Giữ bảng cổng máy
// chủ và phiên; phiên (một luồng) chỉ được dựng khi có lần đăng nhập đầu tiên, nên client không có máy chủ trực
// tuyến nào thì không tốn luồng.
// Gọi từ một luồng duy nhất (luồng cửa sổ): serve và collect không chặn, không I/O.
// Bản mới của dự án.
#pragma once

#include "client/session/gates.hpp"
#include "client/session/session.hpp"
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
    // Trả lời đã sẵn cho chuỗi đăng nhập, theo thứ tự.
    [[nodiscard]] std::vector<ui::panel::OnlineReply> collect();
    // Pha của phiên; kIdle khi phiên chưa dựng.
    [[nodiscard]] session::Phase phase() const noexcept;

private:
    session::Session& line();
    void refuse(ui::panel::OnlineFault fault);

    session::GateBook book_;
    std::optional<session::Session> session_;
    // Trả lời tạo ngay lúc serve (máy chủ không có trong bảng cổng, hàng đợi lệnh đầy).
    std::vector<ui::panel::OnlineReply> immediate_;
};

} // namespace game::client::online
