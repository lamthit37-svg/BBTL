#pragma once
// Socket TCP không chặn và tập chờ của máy chủ. Header này không lộ kiểu nào của hệ điều hành;
// header mạng của hệ điều hành chỉ nằm trong socket_win32.cpp và socket_posix.cpp.
// Quyết định: mọi socket không chặn từ lúc tạo, lời gọi chặn duy nhất là PollSet::wait có hạn;
// chỉ IPv4, địa chỉ đọc bằng inet_pton, không phân giải tên; mọi luồng bật TCP_NODELAY; đóng êm
// là việc của bên gọi (gửi, shutdown_send, nhận tới kClosed).
// Nguồn: TLBB Dev src/platform/socket.hpp, socket.cpp, socket_win32.cpp, socket_posix.cpp.
// Khác gốc: namespace game::net, tên lỗi kCamelCase; Endpoint thay cặp chuỗi host và cổng;
// accept trả kèm Endpoint bên kia; chỉ có nối hai bước (bỏ connect chặn và getaddrinfo); thêm
// abort (RST), local, nodelay; bỏ hàm poll rời, chỉ giữ PollSet.

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::net {

enum class [[nodiscard]] NetError : std::uint8_t {
    kStartup = 1,
    kAddress,
    kSocket,
    kBind,
    kListen,
    kAccept,
    kConnect,
    // Bên kia đã đóng chiều gửi (FIN) và không còn byte nào để nhận.
    kClosed,
    // Kết nối đứt giữa chừng: RST, mạng rớt, gửi vào kết nối đã huỷ.
    kReset,
    kPoll,
};

template <typename T>
using NetResult = std::expected<T, NetError>;
using Milliseconds = std::chrono::milliseconds;
// Bốn byte của địa chỉ IPv4 theo thứ tự viết: "a.b.c.d" là {a, b, c, d}.
using Ipv4 = std::array<std::uint8_t, 4>;

// Câu tiếng Việt cho log.
[[nodiscard]] std::string_view describe(NetError error) noexcept;

struct Endpoint {
    Ipv4 address{};
    std::uint16_t port = 0;

    friend bool operator==(const Endpoint&, const Endpoint&) = default;
};

// Cổng 0 là "hệ điều hành tự chọn": chỉ có nghĩa với cổng nghe.
enum class ZeroPort : std::uint8_t {
    kRefuse,
    kAllow,
};

// Đọc "a.b.c.d:cổng" như gate.toml. Tên máy, IPv6, thiếu cổng, cổng quá 65535, cổng 0 khi
// kRefuse là kAddress.
[[nodiscard]] NetResult<Endpoint> parse_endpoint(std::string_view text, ZeroPort zero) noexcept;

// Handle socket của hệ điều hành, mờ với phần còn lại của dự án.
enum class SocketHandle : std::uintptr_t {};
// "Không giữ socket nào": trùng INVALID_SOCKET của Winsock, ép về int ra fd -1 của POSIX.
inline constexpr SocketHandle kNoSocket{~std::uintptr_t{0}};

// Khởi tạo thư viện mạng của tiến trình (WSAStartup; POSIX không làm gì). Phải sống lâu hơn mọi
// socket.
class Network {
public:
    [[nodiscard]] static NetResult<Network> start() noexcept;

    ~Network();
    Network(Network&& other) noexcept;
    Network& operator=(Network&& other) noexcept;
    Network(const Network&) = delete;
    Network& operator=(const Network&) = delete;

private:
    Network() = default;
    void stop() noexcept;

    bool active_ = false;
};

// Sở hữu một socket của hệ điều hành, đóng nó khi huỷ. Chỉ chuyển, không chép.
class Socket {
public:
    Socket() = default;
    explicit Socket(SocketHandle handle) noexcept : handle_(handle) {}
    ~Socket();
    Socket(Socket&& other) noexcept;
    Socket& operator=(Socket&& other) noexcept;
    Socket(const Socket&) = delete;
    Socket& operator=(const Socket&) = delete;

    [[nodiscard]] SocketHandle handle() const noexcept { return handle_; }
    [[nodiscard]] bool is_open() const noexcept { return handle_ != kNoSocket; }
    // Đóng sớm; gọi lại không sao.
    void close() noexcept;

private:
    SocketHandle handle_ = kNoSocket;
};

// Một luồng TCP không chặn.
class TcpStream {
public:
    TcpStream() = default;

    // Bước một của nối: luồng trả về đang nối. Khi PollSet báo ghi được hoặc lỗi, gọi
    // finish_connect. Bị từ chối ngay (cổng 0, địa chỉ không dùng được) là kConnect.
    [[nodiscard]] static NetResult<TcpStream> begin_connect(Endpoint target) noexcept;

    // Bước hai: true khi đã nối, false khi còn đang nối, kConnect khi nối hỏng, kReset khi bên kia
    // huỷ ngay sau khi nối. Đã nối hay chưa là theo SO_ERROR, không theo POLLHUP: byte và FIN tới
    // trước lần hỏi đầu vẫn nhận được qua receive. Khi lỗi, socket bị đóng ngay tại đây (cả qua
    // send, receive): bên gọi phải remove nhãn của nó khỏi PollSet trước lần wait sau, vì hệ điều
    // hành có thể cấp lại đúng handle đó cho socket mới.
    // Luồng đã nối luôn trả true. TCP_NODELAY đã bật từ lúc tạo socket.
    [[nodiscard]] NetResult<bool> finish_connect() noexcept;

    // Số byte đầu của data đã giao cho hệ điều hành; 0 khi phải chờ PollSet báo ghi được, khi
    // còn đang nối hoặc khi data rỗng. Luồng đã đóng là kReset.
    [[nodiscard]] NetResult<std::size_t> send(std::span<const std::byte> data) noexcept;

    // Số byte đã nhận vào sink; 0 khi chưa có byte, khi còn đang nối, hoặc khi sink rỗng (không
    // gọi recv). kClosed khi bên kia đã đóng chiều gửi và hết byte.
    [[nodiscard]] NetResult<std::size_t> receive(std::span<std::byte> sink) noexcept;

    // Đóng chiều gửi (FIN), vẫn nhận tiếp: bước giữa của đóng êm.
    void shutdown_send() noexcept;

    // Huỷ kết nối: bên kia nhận RST và thấy kReset; byte chưa gửi bị bỏ.
    void abort() noexcept;

    // Địa chỉ và cổng phía này; kSocket khi không đọc được.
    [[nodiscard]] NetResult<Endpoint> local() const noexcept;

    // TCP_NODELAY đang bật; false cả khi không đọc được.
    [[nodiscard]] bool nodelay() const noexcept;

    [[nodiscard]] SocketHandle handle() const noexcept { return socket_.handle(); }
    [[nodiscard]] bool is_open() const noexcept { return socket_.is_open(); }

private:
    friend class TcpListener;
    explicit TcpStream(Socket socket) noexcept;

    Socket socket_;
    bool connecting_ = false;
};

// Một kết nối vừa nhận, kèm địa chỉ và cổng của bên nối.
struct Accepted {
    TcpStream stream;
    Endpoint peer;
};

// Cổng nghe IPv4, không chặn. Windows không đặt SO_REUSEADDR (cờ đó cho hai socket nghe chung
// một cổng); POSIX đặt để khởi động lại được khi cổng còn kết nối TIME_WAIT.
class TcpListener {
public:
    TcpListener() = default;

    // Cổng 0 để hệ điều hành chọn; đọc lại bằng local.
    [[nodiscard]] static NetResult<TcpListener> open(Endpoint address) noexcept;

    [[nodiscard]] NetResult<Endpoint> local() const noexcept;

    // Một kết nối đang chờ; nullopt khi không có ai chờ. Luồng nhận được đã không chặn và bật
    // TCP_NODELAY.
    [[nodiscard]] NetResult<std::optional<Accepted>> accept() noexcept;

    [[nodiscard]] SocketHandle handle() const noexcept { return socket_.handle(); }

private:
    explicit TcpListener(Socket socket) noexcept;

    Socket socket_;
};

// Sự kiện của một socket sau PollSet::wait; tag là nhãn bên gọi đặt lúc add.
struct PollEvent {
    std::uint64_t tag = 0;
    // Có byte để nhận, có kết nối chờ accept, hoặc bên kia đã đóng.
    bool readable = false;
    // Ghi được; chỉ báo cho socket đang bật quan tâm ghi.
    bool writable = false;
    // Lỗi hay đứt kết nối; receive hoặc finish_connect cho biết lý do.
    bool failed = false;
};

using PollEvents = std::vector<PollEvent>;

// Tập socket chờ cùng lúc, giữ qua các vòng: mảng đưa cho hệ điều hành chỉ đổi khi thêm, bớt
// hay bật tắt quan tâm ghi. Mỗi socket một nhãn khác nhau. PollSet đã bị chuyển đi thì không
// dùng được nữa (vi phạm là lỗi lập trình).
class PollSet {
public:
    PollSet();
    ~PollSet();
    PollSet(PollSet&& other) noexcept;
    PollSet& operator=(PollSet&& other) noexcept;
    PollSet(const PollSet&) = delete;
    PollSet& operator=(const PollSet&) = delete;

    // Thêm socket chờ đọc, chưa chờ ghi. false khi nhãn đã có hoặc socket là kNoSocket. PollSet chỉ
    // giữ handle thô: socket bị đóng (abort, nối hỏng, huỷ luồng) thì remove nhãn trước lần wait
    // sau. Lỗi cấp phát để tập nguyên vẹn.
    [[nodiscard]] bool add(SocketHandle socket, std::uint64_t tag);
    // Bỏ socket mang nhãn; không có thì không làm gì.
    void remove(std::uint64_t tag) noexcept;
    // Bật khi còn byte chưa gửi hết hoặc đang nối, tắt khi xong; nhãn lạ thì không làm gì.
    void want_write(std::uint64_t tag, bool wanted) noexcept;
    [[nodiscard]] std::size_t size() const noexcept;
    // Chờ tới khi có sự kiện hoặc hết limit; events được xoá rồi điền đúng các socket có sự
    // kiện. Tập rỗng thì chờ hết limit rồi trả không sự kiện.
    [[nodiscard]] NetResult<void> wait(Milliseconds limit, PollEvents& events);

private:
    // Mảng pollfd của hệ điều hành, nhãn cùng chỉ số, chỉ số theo nhãn; định nghĩa ở tệp của
    // từng nền.
    struct Native;
    [[nodiscard]] Native& state() const noexcept;

    std::unique_ptr<Native> native_;
};

} // namespace game::net
