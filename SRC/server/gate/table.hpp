#pragma once
// Bảng kết nối cấp một lần. Đường xử lý một tin không cấp phát thêm.
// Đồng hồ là nano giây đơn điệu do bên gọi đưa, để test không phải ngủ.

#include "net/net.hpp"
#include "secure/secure.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::gate {

inline constexpr std::int64_t kNsPerMs = 1'000'000;
inline constexpr std::int64_t kNsPerSecond = 1'000'000'000;
inline constexpr std::int64_t kTickNs = kNsPerSecond / 60;
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
    kLogout,
    kClosed,
    kStop,
    kCount,
};

[[nodiscard]] std::string_view describe(Drop reason) noexcept;

struct Limits {
    std::size_t max_connections = 0;
    std::size_t per_ip = 0;
    std::int64_t handshake_ns = 0;
    std::int64_t idle_ns = 0;
    std::size_t frame_bytes = 0;
    std::int64_t per_second = 0;
    std::uint16_t min_version = 1;
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

enum class AdmitCode : std::uint8_t { kOk, kFull, kDenied, kPerIp };

struct Admit {
    AdmitCode code = AdmitCode::kFull;
    Handle handle{};
};

struct Engine;

// identity phải sống lâu hơn bảng. allow rỗng là mọi địa chỉ không bị deny.
class Table {
public:
    Table(Limits limits, std::vector<Cidr> allow, std::vector<Cidr> deny, const secure::Identity& identity);
    ~Table();
    Table(const Table&) = delete;
    Table& operator=(const Table&) = delete;
    Table(Table&&) noexcept;
    Table& operator=(Table&&) noexcept;

    [[nodiscard]] Admit admit(net::Ipv4 address, std::int64_t now);
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
