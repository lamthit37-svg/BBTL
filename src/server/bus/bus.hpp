#pragma once
// Hàng đợi sự kiện gameplay theo tick: nơi phát (zone, vật phẩm, lên cấp) bỏ sự kiện vào, vòng tick của máy chủ xả một lượt
// rồi chuyển cho mission. Mục đích là làm kết quả KHÔNG phụ thuộc thứ tự các hệ phát sự kiện trong cùng tick: lượt xả sắp
// theo loại sự kiện cố định (khai báo ở Kind), trong cùng loại giữ thứ tự phát (ổn định), nên chạy lại cùng đầu vào ra cùng
// kết quả. Sự kiện phát trong lúc đang xử lý một lượt thuộc lượt kế, không bao giờ làm lượt hiện tại dài thêm (chặn đệ quy).
//
// Hàng đợi có trần: đầy thì từ chối và đếm (dropped), không cấp phát vô hạn khi có kẻ spam sự kiện.

#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

namespace game::bus {

// Thứ tự khai báo là thứ tự xả: lên cấp trước (mở nhiệm vụ mới), rồi nói chuyện, giết quái, vào vùng, đổi vật phẩm.
enum class Kind : std::uint8_t {
    kLevelUp,      // a = cấp mới, c = cấp cũ
    kTalk,         // a = guid NPC, b = cảnh, name = mã tên NPC
    kKill,         // a = mẫu quái, b = cảnh, name = mã tên quái
    kEnterArea,    // a = cảnh, b = vùng
    kItemChanged,  // a = mẫu vật phẩm, c = số lượng mới trong túi
};

inline constexpr std::size_t kKindCount = 5;

struct Event {
    Kind kind = Kind::kKill;
    ids::CharacterId hero;  // người nhận sự kiện (người giết, người vào vùng...)
    std::uint32_t a = 0;
    std::uint32_t b = 0;
    std::uint32_t name = 0;
    std::int32_t c = 0;

    friend bool operator==(const Event&, const Event&) noexcept = default;
};

class Bus {
public:
    explicit Bus(std::size_t capacity);

    // false khi hàng đợi đầy hoặc loại sự kiện ngoài tập; sự kiện bị bỏ được đếm trong dropped().
    [[nodiscard]] bool publish(const Event& event);

    // Lấy toàn bộ sự kiện đang chờ theo thứ tự xả. Vùng trả về hợp lệ tới lần take() kế tiếp; sự kiện publish() trong lúc
    // duyệt vùng này nằm ở lượt sau.
    [[nodiscard]] std::span<const Event> take();

    [[nodiscard]] std::size_t pending() const noexcept { return pending_.size(); }
    [[nodiscard]] std::size_t capacity() const noexcept { return capacity_; }
    [[nodiscard]] std::uint64_t dropped() const noexcept { return dropped_; }

private:
    std::size_t capacity_;
    std::uint64_t dropped_ = 0;
    std::vector<Event> pending_;
    std::vector<Event> batch_;
};

}  // namespace game::bus
