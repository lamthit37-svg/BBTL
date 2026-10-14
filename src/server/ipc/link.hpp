#pragma once
// Kênh nội bộ bền giữa hai tiến trình máy chủ (gate ↔ zone, gate ↔ world, zone ↔ world), chỉ trên
// loopback. Khác account::rpc (một yêu cầu một kết nối): ở đây một kết nối sống lâu, hai chiều, mang
// nhiều khung xen kẽ; mỗi khung gắn một `session` để bên nhận biết nó thuộc người chơi nào.
//
// Trên dây: u32 độ dài (little-endian) rồi hộp kín. Hộp kín = secure::ipc_seal(khoá cụm, kind u16,
// session u64, thân). Khung không mở được (sai khoá, bị sửa) hay sai cỡ làm kênh hỏng hẳn và bên gọi
// phải đóng. Kênh không chống phát lại: nó chỉ nằm trên loopback và dựa vào TCP; khoá cụm là thứ ngăn
// tiến trình lạ chen vào.
//
// Không chặn và không luồng: bên gọi chờ socket bằng PollSet/Reactor của mình rồi gọi pump(). Mọi hàng
// có trần (UB-13): hàng gửi vượt trần thì send từ chối, bên nhận chậm không làm phình bộ nhớ.

#include "net/net.hpp"
#include "secure/secure.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace game::ipc {

inline constexpr std::size_t kKeyBytes = 32;
// Thân một khung. Một thông điệp lớn hơn (danh sách dài) phải do bên gọi tách.
inline constexpr std::size_t kBodyMax = std::size_t{16} * 1024;
// Byte chờ gửi tối đa; vượt thì send trả false.
inline constexpr std::size_t kOutboxMax = std::size_t{8} << 20U;
// Khung đã giải mã chờ bên gọi lấy; đầy thì pump ngừng đọc socket (TCP tự kìm bên gửi).
inline constexpr std::size_t kInboxMax = 4096;

struct Frame {
    std::uint16_t kind = 0;
    std::uint64_t session = 0;
    std::vector<std::byte> body;
};

enum class LinkState : std::uint8_t {
    kUp,
    // Bên kia đóng êm và hết byte.
    kClosed,
    // Lỗi mạng, khung hỏng hay sai khoá: phải đóng.
    kBroken,
};

class Link {
public:
    // key đúng kKeyBytes byte; sai cỡ là lỗi lập trình. Bản sao khoá bị xoá khi huỷ.
    Link(net::TcpStream stream, secure::ByteView key);
    ~Link();
    Link(Link&& other) noexcept;
    Link& operator=(Link&& other) noexcept;
    Link(const Link&) = delete;
    Link& operator=(const Link&) = delete;

    // Nối tới endpoint và chờ tối đa limit. nullopt khi nối hỏng hay quá hạn.
    [[nodiscard]] static std::optional<Link> connect(net::Endpoint target, secure::ByteView key,
        net::Milliseconds limit);

    // Xếp một khung vào hàng gửi. false khi thân quá kBodyMax, hàng gửi sẽ vượt kOutboxMax, hay kênh đã hỏng.
    [[nodiscard]] bool send(std::uint16_t kind, std::uint64_t session, std::span<const std::byte> body);

    // Đẩy byte chờ gửi, đọc byte có sẵn, tách và mở khung. Không chặn. Gọi sau mỗi lần PollSet báo sự kiện
    // và mỗi tick của bên gọi.
    [[nodiscard]] LinkState pump();

    // Khung đã tới, theo đúng thứ tự gửi.
    [[nodiscard]] std::optional<Frame> next();

    // Còn byte chờ gửi: bên gọi bật quan tâm ghi của PollSet.
    [[nodiscard]] bool wants_write() const noexcept { return sent_ < outbox_.size(); }
    [[nodiscard]] net::SocketHandle handle() const noexcept { return stream_.handle(); }
    [[nodiscard]] bool is_open() const noexcept { return stream_.is_open() && state_ == LinkState::kUp; }
    [[nodiscard]] std::size_t queued_frames() const noexcept { return inbox_.size() - inbox_from_; }

private:
    [[nodiscard]] LinkState write_out();
    [[nodiscard]] LinkState read_in();
    [[nodiscard]] bool split_frames();
    void wipe() noexcept;

    net::TcpStream stream_;
    std::array<std::byte, kKeyBytes> key_{};
    std::vector<std::byte> outbox_;
    std::size_t sent_ = 0;
    std::vector<std::byte> raw_;
    // Khung đã giải mã, đọc dần từ inbox_from_. Vector thay vì deque: chuyển Link phải noexcept thật (deque của MSVC
    // cấp phát khi chuyển).
    std::vector<Frame> inbox_;
    std::size_t inbox_from_ = 0;
    LinkState state_ = LinkState::kUp;
};

} // namespace game::ipc
