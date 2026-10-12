// Cổng đọc số đo qua loopback: bên đọc nối vào, tiến trình ghi một ảnh chụp văn bản (metrics.hpp)
// rồi đóng chiều gửi và đóng kết nối. Tiến trình không đọc byte nào từ bên đọc, nên phía này không
// có bộ giải mã đầu vào. Cổng chỉ nghe 127.0.0.1 (viết cứng, không có khoá cấu hình), số cổng do hệ
// điều hành chọn và được báo ở dòng `ready ... metrics=<cổng>`.
// Tách khỏi metrics để metrics không phụ thuộc net. Phục vụ trên một luồng riêng: vòng tick không
// bị chạm. Bên đọc là tiến trình cùng máy nhưng vẫn không tin được, nên mọi thứ có trần: số bên
// chờ, hạn gửi cho một bên, số kết nối nhận trong một vòng.
// Đặc tả: thienlong-specs/coder-server/metrics.md mục 7.1. kMaxReaders và kReaderTimeout là số tự
// đặt, không có nguồn.
#pragma once

#include "core/clock.hpp"
#include "core/function.hpp"
#include "metrics/metrics.hpp"
#include "net/net.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <thread>
#include <vector>

namespace game::metrics {

// Số bên đọc được chờ tới lượt (không kể bên đang được phục vụ). Bên tới khi hàng đã đầy bị huỷ.
inline constexpr std::size_t kMaxReaders = 4;
// Hạn gửi trọn ảnh chụp cho một bên; quá hạn thì bên đó bị huỷ.
inline constexpr std::chrono::milliseconds kReaderTimeout{1000};

// Hàng bên đọc: nhận kết nối, phục vụ từng bên một, huỷ bên quá hạn. Một luồng. Server chạy nó trên
// luồng riêng; test lái từng bước với thời điểm tự đưa nên không phải ngủ.
class Readers {
public:
    // Ghi văn bản cho bên đọc kế vào vùng cấp sẵn dài kSnapshotMaxBytes, trả số byte đã ghi.
    using Fill = core::MoveOnlyFunction<std::size_t(std::span<char>)>;

    // tally nhận bộ đếm metrics.reader.dropped và phải sống lâu hơn hàng. Cấp bộ đệm ảnh chụp một
    // lần ở đây; các bước sau không cấp phát.
    Readers(net::TcpListener listener, Registry& tally, Fill fill);

    // Một vòng: chờ sự kiện tối đa limit, nhận các kết nối đang chờ (bên thứ kMaxReaders + 1 trong
    // hàng bị huỷ và đếm), gửi tiếp cho bên đang phục vụ, huỷ và đếm bên quá hạn tính tới now, rồi
    // phục vụ bên kế. Lỗi của tập chờ trả về nguyên: bên gọi thôi phục vụ.
    [[nodiscard]] net::NetResult<void> step(net::Milliseconds limit, core::Clock::time_point now);

    // Số bên đang chờ tới lượt và có bên đang được phục vụ hay không.
    [[nodiscard]] std::size_t waiting() const noexcept { return waiting_count_; }
    [[nodiscard]] bool is_serving() const noexcept { return current_.has_value(); }

private:
    void accept_pending();
    [[nodiscard]] bool begin_next(core::Clock::time_point now);
    void send_more(core::Clock::time_point now);
    void drop_current() noexcept;

    net::TcpListener listener_;
    Registry* tally_;
    Fill fill_;
    net::PollSet poll_;
    net::PollEvents events_;
    std::vector<char> text_;
    std::array<net::TcpStream, kMaxReaders> waiting_;
    std::size_t waiting_from_ = 0;
    std::size_t waiting_count_ = 0;
    std::optional<net::TcpStream> current_;
    std::size_t size_ = 0;
    std::size_t sent_ = 0;
    core::Clock::time_point deadline_;
};

// Cổng đọc số đo của một tiến trình: mở 127.0.0.1 ở cổng do hệ điều hành chọn và phục vụ ảnh chụp
// của registry trên một luồng riêng tới khi bị huỷ. Huỷ là yêu cầu dừng rồi chờ luồng xong, trong
// khoảng một nhịp chờ của luồng (100 ms); bên đang được phục vụ lúc đó bị đóng.
class Server {
public:
    // registry phải sống lâu hơn Server: khai registry trước. Thư viện mạng của tiến trình
    // (net::Network) phải đã khởi động.
    [[nodiscard]] static net::NetResult<Server> start(Registry& registry);

    [[nodiscard]] std::uint16_t port() const noexcept { return port_; }

private:
    Server(std::uint16_t port, std::jthread thread) noexcept;

    std::uint16_t port_ = 0;
    std::jthread thread_;
};

} // namespace game::metrics
