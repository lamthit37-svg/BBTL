#pragma once
// Máy chủ HTTP của webhook thanh toán: một luồng, socket không chặn, mỗi kết nối đúng MỘT yêu cầu rồi đóng.
// Phần "hiểu" HTTP và chữ ký nằm ở http.hpp và webhook.hpp (thuần, có test); ở đây chỉ là đường vận chuyển:
// gom byte, chống kẻ nói chậm, chống ăn bộ nhớ, gửi trả lời.
//
// Trần tài nguyên: tối đa max_connections kết nối cùng lúc (kết nối thứ N+1 bị đóng ngay), mỗi kết nối giữ tối
// đa http::kRequestMost byte đầu vào và có hạn request_budget để gửi xong cả yêu cầu (kẻ mở kết nối rồi im
// lặng bị đóng). Trả lời nhỏ hơn 1 KiB. Sau khi gửi trả lời, kết nối nán lại tối đa linger_budget để bên kia kịp
// nhận (đóng ngay khi còn byte chưa đọc làm Windows gửi RST và có thể xoá trả lời khỏi bộ đệm của bên kia).
//
// Một PgBook dùng trong đúng một luồng: sổ đưa vào đây chỉ được luồng gọi pump() dùng. Webhook chạy việc
// ghi sổ ngay trong pump(), nên một thao tác sổ chậm làm cả vòng chậm; đủ cho nhà cung cấp gọi vài lần một
// giây, và nhà cung cấp tự gọi lại khi không nhận được 200.

#include "billing/book.hpp"
#include "billing/http.hpp"
#include "billing/webhook.hpp"
#include "net/net.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::billing {

struct WebhookServerOptions {
    std::size_t max_connections = 64;
    std::chrono::milliseconds request_budget{5000};
    std::chrono::milliseconds linger_budget{2000};
};

class WebhookServer {
public:
    // `hooks` và `book` phải sống lâu hơn máy chủ. `network` của listener do bên gọi giữ.
    WebhookServer(net::TcpListener listener, const Webhooks& hooks, Book& book, WebhookServerOptions options);

    // Chờ tối đa `wait` rồi xử lý mọi sự kiện đã tới và dọn kết nối quá hạn. false khi tập chờ hỏng không
    // phục hồi được; bên gọi nên dừng tiến trình.
    [[nodiscard]] bool pump(std::chrono::milliseconds wait);

    // Số kết nối đang mở (cho test và log).
    [[nodiscard]] std::size_t open_connections() const noexcept { return open_; }

private:
    using Clock = std::chrono::steady_clock;

    enum class Phase : std::uint8_t { kFree, kReading, kSending, kLinger };

    struct Conn {
        net::TcpStream stream;
        Phase phase = Phase::kFree;
        std::string in;
        std::string out;
        std::size_t sent = 0;
        Clock::time_point deadline;
    };

    void accept_all(Clock::time_point now);
    void on_event(const net::PollEvent& event, Clock::time_point now);
    void read_request(std::size_t index, Clock::time_point now);
    void answer(std::size_t index, http::Status status, std::string_view body, Clock::time_point now);
    void flush(std::size_t index, Clock::time_point now);
    void linger(std::size_t index);
    void drop(std::size_t index);
    void sweep(Clock::time_point now);

    net::TcpListener listener_;
    const Webhooks* hooks_;
    Book* book_;
    WebhookServerOptions options_;
    net::PollSet poll_;
    net::PollEvents events_;
    std::vector<Conn> conns_;
    std::size_t open_ = 0;
    bool ready_ = false;
};

} // namespace game::billing
