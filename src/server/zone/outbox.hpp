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
 *    mục có `session` của ô gate nhận. Vị trí cùng một lượt được gom theo
 *    người nhận thành EntityPosBatch, chốt trước tin khác của cùng người.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "account/play.hpp"
#include "ipc/relay.hpp"
#include "protocol/messages.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::zone {

// Trần bản rõ của một lô vị trí. Hộp gửi của gate là 1024 byte và bản ghi secure thêm 18 byte,
// nên khung quá 1006 byte không bao giờ được niêm phong. 52 PosEntry (19 byte) cộng đầu khung
// và số đếm là 998 byte. gate_tests đối chiếu số này với kOutboxBytes.
inline constexpr std::size_t kPosFrameMax = 1006;
inline constexpr std::size_t kPosEntryBytes = 19;
inline constexpr std::size_t kPosBinReserve = 512;

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
        flush_session(session);
        Letter letter;
        letter.kind = ipc::Relay::kDown;
        letter.session = session;
        letter.body = std::move(frame);
        letters_.push_back(std::move(letter));
    }

    // Cùng một khung gửi cho nhiều người: mã hoá một lần (frame_of), chép theo số người nhận.
    // Vị trí đang gom của người này được chốt trước, để không áp dụng sau tin này.
    void down_frame(std::uint64_t session, const std::vector<std::byte>& frame) {
        if (frame.empty()) return;
        flush_session(session);
        Letter letter;
        letter.kind = ipc::Relay::kDown;
        letter.session = session;
        letter.body = frame;
        letters_.push_back(std::move(letter));
    }

    // 19 byte của một PosEntry, mã hoá một lần rồi chép cho từng người nhận.
    struct PosBlob {
        std::array<std::byte, kPosEntryBytes> bytes{};
    };

    [[nodiscard]] PosBlob blob(const protocol::EntityPos& pos);
    // Gom một vị trí đã mã hoá. Không chờ thêm tick; chốt khi có tin khác hoặc khi đọc thư.
    void stage_blob(std::uint64_t session, const PosBlob& blob);

    void refuse(std::uint64_t session, protocol::ErrorCode code) {
        flush_session(session);
        Letter letter;
        letter.kind = ipc::Relay::kRefuse;
        letter.session = session;
        letter.body = ipc::encode_body(ipc::Refuse{code});
        letters_.push_back(std::move(letter));
    }

    void close(std::uint64_t session, protocol::DisconnectReason reason) {
        flush_session(session);
        Letter letter;
        letter.kind = ipc::Relay::kClose;
        letter.session = session;
        letter.body = ipc::encode_body(ipc::Close{reason});
        letters_.push_back(std::move(letter));
    }

    // Buộc người chơi về (x, z): gate đặt mốc mới cho guard::Pace rồi gửi Position cho client.
    void place(std::uint64_t session, float x_cm, float z_cm) {
        flush_session(session);
        Letter letter;
        letter.kind = ipc::Relay::kPlace;
        letter.session = session;
        letter.body = ipc::encode_body(ipc::Place{.x_cm = x_cm, .z_cm = z_cm});
        letters_.push_back(std::move(letter));
    }

    void save(const Save& spot) { saves_.push_back(spot); }

    // Chốt mọi lô vị trí còn treo rồi trả thư. Gọi hai lần không nhân đôi lô.
    [[nodiscard]] const std::vector<Letter>& letters();
    [[nodiscard]] const std::vector<Save>& saves() const noexcept { return saves_; }
    [[nodiscard]] std::vector<Letter> take();
    // Bỏ `count` thư ở đầu hàng (đã đẩy lên kênh). Quá số thư đang có thì bỏ hết.
    void drop_front(std::size_t count);
    // Tổng byte thân của thư còn trong hàng, để so với trần hộp ipc.
    [[nodiscard]] std::size_t queued_bytes() const noexcept;
    [[nodiscard]] std::vector<Save> take_saves() noexcept { return std::exchange(saves_, {}); }
    [[nodiscard]] std::size_t failures() const noexcept { return failures_; }
    // Gameplay mã hoá tin riêng (play::Output); số tin hỏng của nó cộng vào cùng bộ đếm.
    void count_failures(std::size_t more) noexcept { failures_ += more; }
    // Bỏ thư chưa gửi, kể cả vị trí chưa chốt. Điểm đứng cần ghi thì không bị bỏ: lấy bằng
    // take_saves().
    void clear() noexcept;

private:
    struct PosBin {
        std::uint64_t session = 0;
        std::vector<std::byte> raw;
        bool used = false;
    };

    void flush_session(std::uint64_t session);
    void flush_all();
    void flush_bin(PosBin& bin);
    void emit_raw(std::uint64_t session, std::span<const std::byte> raw);
    void recycle_at(std::size_t at);
    void step_compact(std::size_t& at);
    void compact();
    [[nodiscard]] PosBin& bin_of(std::uint64_t session);
    [[nodiscard]] static std::size_t fit_count(std::size_t available) noexcept;

    std::vector<Letter> letters_;
    std::vector<Save> saves_;
    std::vector<PosBin> bins_;
    std::unordered_map<std::uint64_t, std::uint32_t> index_;
    // Bộ đệm byte của người nhận không còn trong lượt này. Giữ sức chứa.
    std::vector<std::vector<std::byte>> spare_;
    std::vector<std::byte> frame_buf_;
    std::size_t failures_ = 0;
};

} // namespace game::zone
