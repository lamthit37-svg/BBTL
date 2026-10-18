/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/gate/table.hpp
 *  PHÂN HỆ   : Server / Gate / Table
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bảng kết nối cấp một lần. Đường xử lý một tin không cấp phát thêm. Đồng hồ
 *    là nano giây đơn điệu do bên gọi đưa, để test không phải ngủ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "ipc/link.hpp"
#include "net/net.hpp"
#include "secure/secure.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::metrics {
class Registry; // metrics/metrics.hpp:246; định nghĩa đầy đủ chỉ cần ở table.cpp
}

namespace game::account {
class Realm;
}

namespace game::gate {

inline constexpr std::int64_t kNsPerMs = 1'000'000;
inline constexpr std::int64_t kNsPerSecond = 1'000'000'000;
inline constexpr std::int64_t kTickNs = kNsPerSecond / 60;

struct TickPlan {
    std::int64_t deadline = 0;
    std::uint64_t missed = 0;
};

// Mốc tick kế sau một lượt bắt đầu lúc start. Lượt bị sự kiện đánh thức sớm (start < deadline) giữ
// nguyên mốc: cộng kTickNs mỗi lượt bất kể giờ thì mỗi sự kiện đẩy mốc xa thêm 1/60 giây, vài trăm
// kết nối tới dồn làm vòng chờ hàng giây không chạy tick.
[[nodiscard]] constexpr TickPlan next_tick(std::int64_t deadline, std::int64_t start) noexcept {
    TickPlan plan{.deadline = deadline, .missed = 0};
    if (start < deadline) return plan;
    plan.deadline += kTickNs;
    while (plan.deadline <= start) {
        plan.deadline += kTickNs;
        ++plan.missed;
    }
    return plan;
}
inline constexpr std::size_t kOutboxBytes = 1024;
inline constexpr std::size_t kScratchBytes = 256;
inline constexpr std::size_t kHeldBytes = secure::kMaxRecordBytes * 2;
inline constexpr std::size_t kMilli = 1000;

enum class Drop : std::uint8_t {
    kHandshake = 1,
    kIdle,
    kRate,
    kFrame,
    kProtocol,
    kSecure,
    kFull,
    kPerIp,
    kDenied,
    kSlow,
    kForeign,
    kVersion,
    // Bản dựng client không nằm trong danh sách cho phép.
    kBuild,
    kLogout,
    kClosed,
    kStop,
    // Lỗi phía gate (metrics::Counter::kGateDropLocal).
    kLocal,
    kCount,
};

[[nodiscard]] std::string_view describe(Drop reason) noexcept;

// Giao diện nhà phát hành đặt ở client.toml. Gate gửi nó cho client trong tin UiConfig sau SessionStart.
enum class AvatarFrame : std::uint8_t { kRound, kSquare };

struct Ui {
    AvatarFrame avatar_frame = AvatarFrame::kSquare;
};

struct Limits {
    std::size_t max_connections = 0;
    std::size_t per_ip = 0;
    std::int64_t handshake_ns = 0;
    std::int64_t idle_ns = 0;
    std::size_t frame_bytes = 0;
    std::int64_t per_second = 0;
    // Bình chứa riêng cho Move (gate.toml [limits] moves_per_second, move_burst): nạp
    // move_per_second Move mỗi giây, chứa tối đa move_burst Move. Các tin khác dùng bình
    // per_second.
    std::int64_t move_per_second = 25;
    std::int64_t move_burst = 320;
    std::uint16_t min_version = 1;
    // Rỗng (count = 0): mọi Hello.build đều được. Có phần tử: chỉ những số này.
    std::array<std::uint32_t, 32> allowed_builds{};
    std::uint8_t allowed_build_count = 0;
    // Trần per_ip đếm theo dải /per_ip_prefix (gate.toml [limits] per_ip_prefix).
    std::uint32_t per_ip_prefix = 32;
    // gate.toml [resume].
    std::int64_t resume_grace_ns = std::int64_t{30} * kNsPerSecond;
    bool resume_bind_ip = true;
};

struct Cidr {
    std::uint32_t network = 0;
    std::uint32_t mask = 0;
};

struct Handle {
    std::uint32_t index = 0;
    std::uint32_t generation = 0;

    friend bool operator==(const Handle&, const Handle&) = default;
};

enum class Door : std::uint8_t { kGame, kAuth };

enum class AdmitCode : std::uint8_t { kOk, kFull, kDenied, kPerIp };

struct Admit {
    AdmitCode code = AdmitCode::kFull;
    Handle handle{};
};

struct Engine;

// Phần bảng mượn từ tiến trình: khoá danh tính và kho số đo. Cả hai phải sống lâu hơn bảng. Dùng
// reference_wrapper thay cho thành viên tham chiếu để Backing còn gán và chép được; không thể rỗng.
struct Backing {
    std::reference_wrapper<const secure::Identity> identity;
    std::reference_wrapper<metrics::Registry> registry;
};

// identity phải sống lâu hơn bảng. allow rỗng là mọi địa chỉ không bị deny.
class Table {
public:
    Table(Limits limits, std::vector<Cidr> allow, std::vector<Cidr> deny, const secure::Identity& identity);
    // Như trên, và ghi bộ đếm/mức đo của gate vào backing.registry.
    Table(Limits limits, std::vector<Cidr> allow, std::vector<Cidr> deny, Backing backing);
    ~Table();
    Table(const Table&) = delete;
    Table& operator=(const Table&) = delete;
    Table(Table&&) noexcept;
    Table& operator=(Table&&) noexcept;

    [[nodiscard]] Admit admit(net::Ipv4 address, std::int64_t now);
    [[nodiscard]] Admit admit(net::Ipv4 address, std::int64_t now, Door door);
    // Chép realm vào bảng và mở một luồng thư ký hỏi auth/store. Luồng tick không chờ IPC: mỗi ô có
    // tối đa một câu hỏi đang bay, hàng đầy thì trả kBusy. Gọi một lần; lần sau bị bỏ qua.
    void set_realm(const account::Realm& realm);
    // Đặt giao diện gửi cho client sau SessionStart. Gọi trước khi nhận kết nối; không gọi thì dạng vuông.
    void set_ui(Ui ui) noexcept;
    // Nối gate với zone qua kênh ipc bền (docs/KE-HOACH-SERVER.md). Sau lời gọi này, người chơi vào game
    // được Attach vào zone, Move được chấp nhận thì zone biết, và khung zone gửi về được chuyển cho client.
    // Chưa nối được kênh thì EnterGame/Resume trả kBusy. Không gọi thì gate chạy như trước (không có thế giới).
    void set_zone(net::Endpoint where, std::span<const std::byte, ipc::kKeyBytes> key);
    // Nối lại kênh khi cần (mỗi giây một lần), bơm byte, chuyển khung zone cho client. Gọi mỗi tick.
    void pump_zone(std::int64_t now);
    [[nodiscard]] bool zone_linked() const noexcept;
    // Lấy các trả lời thư ký đã xong và gửi cho client. Gọi mỗi tick trên luồng tick.
    void collect();
    void receive(Handle handle, secure::ByteView bytes, std::int64_t now);
    [[nodiscard]] secure::ByteView outgoing(Handle handle) const noexcept;
    void mark_sent(Handle handle, std::size_t count);
    // Hạn bắt tay, hạn im lặng, nạp lại token. Ô chết được lấy bằng take_closed.
    void advance(std::int64_t now);
    void close_all();
    [[nodiscard]] std::size_t take_closed(std::span<Handle> out);

    [[nodiscard]] std::size_t live() const noexcept;
    [[nodiscard]] std::uint64_t drops(Drop reason) const noexcept;
    [[nodiscard]] bool is_live(Handle handle) const noexcept;
    [[nodiscard]] std::size_t scratch_capacity(Handle handle) const noexcept;
    [[nodiscard]] bool listening() const noexcept;
    // Ngắt một kết nối còn sống và đếm lý do. Tay nắm cũ thì không làm gì.
    void drop(Handle handle, Drop reason);
    // Số byte nhận thêm mà vùng đệm còn chỗ. 0 khi tay nắm không còn sống.
    [[nodiscard]] std::size_t read_room(Handle handle) const noexcept;
    // Ô vừa có byte cần gửi. Bên gọi đẩy rồi mới lấy tiếp.
    [[nodiscard]] std::size_t take_pending(std::span<Handle> out);
    // Ô còn bản ghi đã đủ byte nhưng chưa mở vì hết ngân sách tick trước.
    [[nodiscard]] std::size_t take_resume(std::span<Handle> out);

private:
    std::unique_ptr<Engine> state_;
};

// "a.b.c.d/n". Sai cú pháp là nullopt; bộ đọc cấu hình đã từ chối các dạng ấy.
[[nodiscard]] std::optional<Cidr> parse_cidr(std::string_view text);

} // namespace game::gate
