/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/outbox.hpp
 *  PHÂN HỆ   : Server / Zone / Outbox
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thư gửi đi của một lượt xử lý zone: mỗi mục là một khung ipc gửi về gate.
 *    Scene không biết socket; nó chỉ ghi vào Outbox rồi host đẩy lên kênh. Mọi
 *    mục có `session` của ô gate nhận.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "account/play.hpp"
#include "ipc/relay.hpp"
#include "protocol/messages.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>
#include <vector>

namespace game::zone {

// Điểm đứng cần ghi vào store. Toạ độ centimet nguyên (cùng đơn vị với dây).
struct Save {
    std::uint64_t character = 0;
    std::uint16_t scene = 0;
    std::int32_t x_cm = 0;
    std::int32_t z_cm = 0;
    // Có thì ghi kèm trạng thái chơi (nhân vật có gì đó đổi); vắng thì chỉ ghi điểm đứng.
    std::optional<account::PlayRecord> play;

    friend bool operator==(const Save&, const Save&) = default;
};

struct Letter {
    ipc::Relay kind = ipc::Relay::kDown;
    std::uint64_t session = 0;
    std::vector<std::byte> body;
};

class Outbox {
public:
    // Mã hoá một tin server thành khung protocol. Mã hoá hỏng (trường quá trần) thì đếm vào failures() và
    // trả rỗng: scene luôn điền trường trong trần, nên đây là lỗi lập trình lộ ra bằng số.
    template <typename Message>
    [[nodiscard]] std::vector<std::byte> frame_of(const Message& message) {
        std::vector<std::byte> frame;
        if (!protocol::encode(frame, message)) {
            ++failures_;
            return {};
        }
        return frame;
    }

    template <typename Message>
    void down(std::uint64_t session, const Message& message) {
        std::vector<std::byte> frame = frame_of(message);
        if (frame.empty()) return;
        letters_.push_back(Letter{.kind = ipc::Relay::kDown, .session = session, .body = std::move(frame)});
    }

    // Cùng một khung gửi cho nhiều người: mã hoá một lần (frame_of), chép theo số người nhận.
    void down_frame(std::uint64_t session, const std::vector<std::byte>& frame) {
        if (frame.empty()) return;
        letters_.push_back(Letter{.kind = ipc::Relay::kDown, .session = session, .body = frame});
    }

    void refuse(std::uint64_t session, protocol::ErrorCode code) {
        letters_.push_back(
            Letter{.kind = ipc::Relay::kRefuse, .session = session, .body = ipc::encode_body(ipc::Refuse{code})});
    }

    void close(std::uint64_t session, protocol::DisconnectReason reason) {
        letters_.push_back(
            Letter{.kind = ipc::Relay::kClose, .session = session, .body = ipc::encode_body(ipc::Close{reason})});
    }

    // Buộc người chơi về (x, z): gate đặt mốc mới cho guard::Pace rồi gửi Position cho client.
    void place(std::uint64_t session, float x_cm, float z_cm) {
        letters_.push_back(Letter{.kind = ipc::Relay::kPlace,
            .session = session,
            .body = ipc::encode_body(ipc::Place{.x_cm = x_cm, .z_cm = z_cm})});
    }

    void save(const Save& spot) { saves_.push_back(spot); }

    [[nodiscard]] const std::vector<Letter>& letters() const noexcept { return letters_; }
    [[nodiscard]] const std::vector<Save>& saves() const noexcept { return saves_; }
    [[nodiscard]] std::vector<Letter> take() noexcept { return std::exchange(letters_, {}); }
    [[nodiscard]] std::vector<Save> take_saves() noexcept { return std::exchange(saves_, {}); }
    [[nodiscard]] std::size_t failures() const noexcept { return failures_; }
    // Bỏ thư chưa gửi. Điểm đứng cần ghi thì không bao giờ bị bỏ ở đây: lấy bằng take_saves().
    void clear() noexcept { letters_.clear(); }

private:
    std::vector<Letter> letters_;
    std::vector<Save> saves_;
    std::size_t failures_ = 0;
};

} // namespace game::zone
