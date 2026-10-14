#pragma once
// Phía gọi billing qua ipc: world, công cụ quản trị và test dùng chung một lớp. Khung vận chuyển là khung của
// account (XChaCha20-Poly1305 bằng khoá ipc, một yêu cầu một kết nối); thân là billing::Request/Reply.
//
// call() không bao giờ ném và không chờ quá hạn. Mọi lỗi vận chuyển (nối hỏng, hết hạn, khung hỏng) thành
// Reply mang mã kBusy: bên gọi KHÔNG biết thao tác đã chạy hay chưa, đúng như mạng đứt giữa chừng. Mọi thao tác
// ghi của billing đều có khoá lặp lại (request_id, trade_no, order_id), nên gọi lại với cùng khoá là cách
// chuẩn để biết kết quả (hợp đồng mục 4.5 của docs/KE-HOACH-SERVER.md).

#include "account/ipc_key.hpp"
#include "billing/rpc.hpp"
#include "net/net.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <optional>

namespace game::billing {

class Client {
public:
    Client(net::Endpoint endpoint, const std::array<std::byte, account::kIpcKeyBytes>& key);
    ~Client();
    Client(const Client&) = delete;
    Client& operator=(const Client&) = delete;
    Client(Client&&) = delete;
    Client& operator=(Client&&) = delete;

    [[nodiscard]] Reply call(const Request& request,
        std::chrono::milliseconds timeout = std::chrono::seconds{3}) const;

private:
    // Không khởi động được lớp mạng thì call() trả kBusy.
    std::optional<net::Network> network_;
    net::Endpoint endpoint_;
    std::array<std::byte, account::kIpcKeyBytes> key_{};
};

} // namespace game::billing
