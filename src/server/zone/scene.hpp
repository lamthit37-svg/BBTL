/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/scene.hpp
 *  PHÂN HỆ   : Server / Zone / Scene
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Một cảnh của zone: bảng thực thể (người, quái, NPC, vật rơi), lưới vùng
 *    nhìn và việc báo hiện/ẩn/di chuyển cho người chơi đang nhìn thấy. Thuần
 *    (không I/O, không đồng hồ thật, không ngẫu nhiên): cùng dãy gọi cho cùng
 *    kết quả Outbox, nên test chạy được không cần mạng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Quyền làm chủ vị trí người chơi nằm ở gate (guard::Pace); cảnh nhận vị trí gate đã chấp nhận (`moved`) và chỉ lo
// phần "ai thấy ai". Quái, NPC và vật rơi do mã của zone đặt qua spawn()/move_entity().

// Id thực thể 32 bit = thế hệ (16 bit cao) | chỉ số+1 (16 bit thấp): id 0 là "không có", và ô được cấp lại
// thì thế hệ đổi nên client không nhầm thực thể mới với thực thể cũ (MMO-04). Trần 65534 thực thể mỗi cảnh.
//
// Độ phức tạp: attach/detach/relocate O(thực thể trong cửa sổ vùng nhìn). Cảnh đông đặc thì trần
// player_max và kích thước ô là hai núm chỉnh.

#pragma once

#include "ipc/relay.hpp"
#include "zone/aoi.hpp"
#include "zone/outbox.hpp"

#include <cstddef>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace game::zone {

// Điểm (x, z) tính bằng centimet có đứng được không, theo lưới đi của cảnh. Rỗng là cảnh không có lưới: đi đâu cũng được.
using Walkable = std::function<bool(float x_cm, float z_cm)>;

// Tốc độ chạy cơ bản của người chơi, centimet mỗi giây: ngưỡng 4,65 m/s của guard::Pace.
inline constexpr std::uint16_t kPlayerSpeedCm = 465;
inline constexpr std::uint32_t kEntityMax = 0xFFFE;
// Nhịp mô phỏng của zone (zone.toml [tick] hz); EntityPos.tick đếm theo nhịp này.
inline constexpr std::int64_t kTickHz = 20;
// Số tick không có bước mới thì một thực thể đang đi được coi là đã dừng: lớn hơn khoảng cách hai Move liên tiếp của
// client (30 bước/giây, ngắn hơn một tick) để không nhấp nháy Walk/Idle giữa chừng.
inline constexpr std::uint32_t kIdleAfterTicks = 3;

[[nodiscard]] constexpr std::uint32_t id_of(std::uint32_t index, std::uint16_t generation) noexcept {
    return (static_cast<std::uint32_t>(generation) << 16U) | (index + 1U);
}

// Điểm trên mặt phẳng ngang của cảnh, centimet.
struct Point {
    float x_cm = 0.0F;
    float z_cm = 0.0F;
};

// Đổi sinh lực theo phần trăm của một thực thể.
struct HpChange {
    std::uint32_t id = 0;
    std::uint8_t percent = 100;
};

struct Delta {
    float x_cm = 0.0F;
    float z_cm = 0.0F;
};

// Hướng nhìn 0..65535 ứng với 0..2π, đo từ trục +X quay về phía +Z. Bước dưới 1 cm trả `keep`.
[[nodiscard]] std::uint16_t direction_of(Delta step, std::uint16_t keep) noexcept;

struct Spawn {
    protocol::EntityKind kind = protocol::EntityKind::kMonster;
    std::uint32_t template_id = 0;
    std::string name;
    std::uint16_t level = 1;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    std::uint16_t direction = 0;
    std::uint16_t speed_cm = 0;
    std::uint8_t hp_percent = 100;
};

class Scene {
public:
    struct Config {
        std::uint16_t id = 0;
        Grid::Spec grid{.cell_cm = 1000.0F, .radius = 2};
        std::size_t player_max = 4000;
        // Luật đi: bước từ chỗ đi được sang chỗ không đi được bị hoàn lại bằng kPlace (xem moved).
        Walkable walkable{};
    };

    struct Where {
        float x_cm = 0.0F;
        float z_cm = 0.0F;
        std::uint16_t direction = 0;
    };

    explicit Scene(Config config);

    // Người chơi vào cảnh. nullopt là nhận; có giá trị là lý do từ chối (kServerFull). Nhân vật đã đứng trong
    // cảnh qua phiên khác thì phiên cũ bị đóng (kLoginElsewhere) và rời trước.
    [[nodiscard]] std::optional<protocol::ErrorCode> attach(std::uint64_t session, const ipc::Attach& arrival,
        Outbox& out);
    // Vị trí gate đã chấp nhận. Phiên lạ thì bỏ. Có luật đi (Config::walkable) mà bước rơi vào chỗ không đi được từ
    // chỗ đi được thì không dời người chơi mà gửi kPlace về vị trí cũ; người đang đứng ngoài lưới (điểm lưu cũ, lưới
    // đổi) vẫn đi ra được, để không ai bị nhốt.
    void moved(std::uint64_t session, const ipc::Moved& step, Outbox& out);
    // Người chơi rời. Phiên lạ thì bỏ.
    void detach(std::uint64_t session, Outbox& out);

    // Đặt một thực thể không phải người. nullopt khi cảnh hết chỗ.
    [[nodiscard]] std::optional<std::uint32_t> spawn(const Spawn& what, Outbox& out);
    void despawn(std::uint32_t id, Outbox& out);
    // Thực thể không phải người đi tới (x, z); id lạ thì bỏ.
    void move_entity(std::uint32_t id, Point to, Outbox& out);
    void set_hp_percent(HpChange change, Outbox& out);

    // Sang tick kế. Thực thể đã đi mà không có bước mới suốt kIdleAfterTicks tick thì được báo dừng (EntityPos kIdle).
    // O(số thực thể đang đi).
    void advance(Outbox& out);
    // Ghi điểm đứng của mọi người chơi đã đi kể từ lần ghi trước (định kỳ, để sập tiến trình không mất quá một chu kỳ).
    void autosave(Outbox& out);

    [[nodiscard]] std::uint16_t id() const noexcept { return config_.id; }
    [[nodiscard]] std::uint32_t tick() const noexcept { return tick_; }
    [[nodiscard]] std::size_t player_count() const noexcept { return players_.size(); }
    [[nodiscard]] std::size_t entity_count() const noexcept { return live_; }
    [[nodiscard]] bool has_session(std::uint64_t session) const noexcept { return players_.contains(session); }
    // Id thực thể của phiên; nullopt khi phiên không ở cảnh này.
    [[nodiscard]] std::optional<std::uint32_t> entity_of(std::uint64_t session) const noexcept;
    [[nodiscard]] std::optional<Where> where(std::uint32_t id) const noexcept;

private:
    struct Entity {
        bool live = false;
        std::uint16_t generation = 0;
        protocol::EntityKind kind = protocol::EntityKind::kMonster;
        std::uint32_t template_id = 0;
        std::string name;
        std::uint16_t level = 0;
        float x_cm = 0.0F;
        float z_cm = 0.0F;
        std::uint16_t direction = 0;
        std::uint16_t speed_cm = 0;
        std::uint8_t hp_percent = 100;
        std::uint8_t gender = 0;
        std::uint16_t face = 0;
        std::uint16_t hair = 0;
        std::uint8_t school = 0;
        protocol::EntityState state = protocol::EntityState::kIdle;
        // Tick của bước cuối; có nghĩa khi state là kWalk.
        std::uint32_t moved_at = 0;
        // Vị trí trong moving_ khi state là kWalk (kNotMoving nếu không).
        std::uint32_t moving_slot = kNotMoving;
        // Chỉ người chơi: ô gate và nhân vật.
        std::uint64_t session = 0;
        std::uint64_t character = 0;
        // Đã đi kể từ lần ghi điểm đứng cuối.
        bool dirty = false;
        Cell cell{};
    };

    static constexpr std::uint32_t kNotMoving = 0xFFFFFFFFU;

    [[nodiscard]] std::optional<std::uint32_t> allocate();
    void start_walking(std::uint32_t index);
    void stop_walking(std::uint32_t index);
    [[nodiscard]] std::uint32_t id_at(std::uint32_t index) const noexcept;
    [[nodiscard]] std::optional<std::uint32_t> index_of(std::uint32_t id) const noexcept;
    [[nodiscard]] protocol::EntityAppear appear_of(std::uint32_t index) const;
    // Đưa thực thể vừa cấp vào lưới và báo hiện cho những người đang nhìn quanh nó.
    void enter_grid(std::uint32_t index, Outbox& out);
    void relocate(std::uint32_t index, Point to, Outbox& out);
    [[nodiscard]] bool blocked(const Entity& who, const ipc::Moved& step) const;
    void save_spot(const Entity& who, Outbox& out) const;
    void remove(std::uint32_t index, Outbox& out);
    // Gửi `frame` cho mọi người chơi trong cửa sổ quanh `around`, trừ thực thể `skip`.
    void broadcast(Cell around, std::uint32_t skip, const std::vector<std::byte>& frame, Outbox& out) const;
    // Gửi cho người chơi `viewer` một EntityAppear của mọi thực thể trong cửa sổ quanh `around` (trừ chính nó).
    void show_neighbours(std::uint32_t viewer, Cell around, Outbox& out) const;

    Config config_;
    Grid grid_;
    std::uint32_t tick_ = 0;
    std::size_t live_ = 0;
    std::vector<Entity> entities_;
    std::vector<std::uint32_t> free_;
    // Chỉ số các thực thể đang ở trạng thái kWalk; thứ tự theo lần bắt đầu đi (xoá bằng chép phần tử cuối).
    std::vector<std::uint32_t> moving_;
    std::unordered_map<std::uint64_t, std::uint32_t> players_;
    std::unordered_map<std::uint64_t, std::uint32_t> by_character_;
};

} // namespace game::zone
