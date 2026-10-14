#pragma once
// Khung trên kênh ipc giữa gate và zone. Gate là cửa duy nhất tới client: nó giữ phiên mã hoá, tốc độ và
// quyền làm chủ vị trí (guard::Pace); zone giữ thế giới. `session` của khung ipc là khoá của ô gate
// (chỉ số và thế hệ), nên zone gửi trả đúng người chơi mà không biết gì về socket.
//
// Gate → zone: kAttach (người chơi vào cảnh), kDetach (rời hay rớt), kMoved (vị trí gate đã chấp nhận).
// Zone → gate: kDown (đúng một khung protocol đã mã hoá, gate niêm phong và gửi cho client), kRefuse (zone
// không nhận người chơi này), kClose (zone đóng phiên, ví dụ nhân vật đã đứng trong cảnh).
//
// Thân mọi khung dùng cùng bộ đọc/ghi của protocol (little-endian, text có trần). Bộ giải mã không tin
// byte nào: thân thiếu, thừa hay sai miền đều là nullopt.

#include "ipc/link.hpp"
#include "protocol/messages.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <vector>

namespace game::ipc {

enum class Relay : std::uint16_t {
    kAttach = 0x0001,
    kDetach = 0x0002,
    kMoved = 0x0003,
    kDown = 0x0101,
    kRefuse = 0x0102,
    kClose = 0x0103,
};

[[nodiscard]] constexpr std::uint16_t value_of(Relay kind) noexcept { return static_cast<std::uint16_t>(kind); }

// Điểm vào cảnh do store giữ, cộng hồ sơ hiển thị. Gate điền từ account::EnterReply.
struct Attach {
    std::uint64_t character = 0;
    std::uint64_t account = 0;
    std::uint16_t scene = 0;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    std::uint16_t direction = 0;
    std::string name;
    std::uint16_t level = 0;
    std::uint8_t gender = 0;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint8_t school = 0;
    // Phiên bản giao thức client khai: zone chỉ biết để bỏ tin client không hiểu; 0 là chưa rõ.
    std::uint16_t client_version = 0;

    friend bool operator==(const Attach&, const Attach&) = default;
};

// Vị trí gate vừa chấp nhận. Hướng không đi theo: zone tự suy ra từ hai vị trí liên tiếp.
struct Moved {
    float x_cm = 0.0F;
    float z_cm = 0.0F;

    friend bool operator==(const Moved&, const Moved&) = default;
};

struct Refuse {
    protocol::ErrorCode code = protocol::ErrorCode::kBusy;

    friend bool operator==(const Refuse&, const Refuse&) = default;
};

struct Close {
    protocol::DisconnectReason reason = protocol::DisconnectReason::kKicked;

    friend bool operator==(const Close&, const Close&) = default;
};

[[nodiscard]] std::vector<std::byte> encode_body(const Attach& message);
[[nodiscard]] std::vector<std::byte> encode_body(const Moved& message);
[[nodiscard]] std::vector<std::byte> encode_body(const Refuse& message);
[[nodiscard]] std::vector<std::byte> encode_body(const Close& message);

[[nodiscard]] std::optional<Attach> decode_attach(std::span<const std::byte> body);
[[nodiscard]] std::optional<Moved> decode_moved(std::span<const std::byte> body);
[[nodiscard]] std::optional<Refuse> decode_refuse(std::span<const std::byte> body);
[[nodiscard]] std::optional<Close> decode_close(std::span<const std::byte> body);

// Một khung protocol đầy đủ (đầu 8 byte + thân) — thân của kDown. Kiểm cấu trúc, không kiểm nội dung.
[[nodiscard]] bool is_single_frame(std::span<const std::byte> bytes) noexcept;

} // namespace game::ipc
