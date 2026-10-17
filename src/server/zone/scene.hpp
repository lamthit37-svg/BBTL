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

#include "dice/dice.hpp"
#include "ipc/relay.hpp"
#include "zone/aoi.hpp"
#include "zone/gates.hpp"
#include "zone/mind.hpp"
#include "zone/outbox.hpp"
#include "zone/rate.hpp"

#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
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
// Nhịp nền. Nhịp thật là Config::hz (20, 30 hoặc 40), chọn lúc tạo cảnh; EntityPos.tick đếm bước
// đó.
inline constexpr std::int64_t kTickHz = 20;
// Mốc 20 Hz của 150 ms không có bước mới (dài hơn khoảng Move của client) để không nhấp nháy
// Walk/Idle. Lúc chạy dùng rate_.idle_after.
inline constexpr std::uint32_t kIdleAfterTicks = 3;
// Mốc 20 Hz: quái một bước mỗi 2 tick, tức 10 bước mỗi giây. Lúc chạy dùng rate_.move_every.
inline constexpr std::uint32_t kMoveEvery = 2;
// Mốc 20 Hz của vị trí tuyệt đối: gần 10 Hz, xa 5 Hz. Lúc chạy dùng rate_. Cùng tick vẫn gửi bước
// mới nhất. Đòn và hiện/ẩn không đi đường này.
inline constexpr std::uint32_t kNearPosStride = 2;
inline constexpr std::uint32_t kFarPosStride = 4;
inline constexpr std::uint32_t kNeverSent = 0xFFFFFFFFU;
// Trần số con được nghĩ mỗi tick mỗi cảnh; con nào tới giờ mà hết lượt thì sang tick sau (vòng tròn, không bỏ đói).
inline constexpr std::size_t kThinkBudget = 512;
// Chạy nhanh gấp rưỡi đi bộ (Obj_Monster::GetMoveSpeed, MOVE_MODE_RUN).
inline constexpr std::uint32_t kRunPercent = 150;
// Coi là áp sát khi cách mục tiêu chừng này; hết hạn chờ Hold khi mục tiêu xa hơn chừng này cộng kHoldSlackCm.
inline constexpr float kMeleeCm = 150.0F;
inline constexpr float kHoldSlackCm = 100.0F;
// Số bước liền bị luật đi chặn thì bỏ cuộc (kMoveEvery tick một bước, nên chừng một giây).
inline constexpr std::uint8_t kStuckSteps = 10;
// Xác nằm lại 3 giây rồi mới biến mất (EntityDied đã báo từ lúc chết).
inline constexpr std::uint32_t kCorpseTicks = 3 * kTickHz;
// Quái dòng bảng không ghi thời gian hồi sinh (<= 0) hồi sau chừng này mili giây.
inline constexpr std::int32_t kDefaultRespawnMs = 30'000;

[[nodiscard]] constexpr std::uint32_t id_of(std::uint32_t index, std::uint16_t generation) noexcept {
    return (static_cast<std::uint32_t>(generation) << 16U) | (index + 1U);
}

// Điểm trên mặt phẳng ngang của cảnh, centimet.
struct Point {
    float x_cm = 0.0F;
    float z_cm = 0.0F;

    [[nodiscard]] constexpr float distance_squared(Point other) const noexcept {
        const float along = x_cm - other.x_cm;
        const float across = z_cm - other.z_cm;
        return (along * along) + (across * across);
    }
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
    // Mã script hội thoại của NPC (0 là không có) và cờ EntityFlags gửi cho client (bit 0: bấm vào để nói chuyện).
    std::uint32_t script = 0;
    std::uint8_t flags = 0;
    // GUID của dòng bảng cảnh (khoá của bảng nhiệm vụ theo NPC; không duy nhất, nhiều NPC dùng chung một GUID).
    std::uint32_t guid = 0;
    // Có giá trị thì thực thể tự đứng, đi, đuổi theo mind.hpp; chỗ sinh là x_cm, z_cm.
    std::optional<Temperament> nature;
    // Quái: âm là chết rồi thôi; từ 0 trở lên là hồi sinh sau chừng ấy mili giây kể từ lúc xác biến mất (0 lấy kDefaultRespawnMs).
    std::int32_t respawn_ms = -1;
};

// Một thực thể nhìn từ bên ngoài cảnh (chiến đấu cần biết loại, mẫu, cấp, chỗ đứng và sống hay chết).
struct Info {
    protocol::EntityKind kind = protocol::EntityKind::kMonster;
    std::uint32_t template_id = 0;
    std::uint16_t level = 0;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    std::uint8_t hp_percent = 100;
    protocol::EntityState state = protocol::EntityState::kIdle;
    // Phiên của người chơi; 0 với thực thể khác.
    std::uint64_t session = 0;
    // Chỉ `info(id)` điền tên; for_each_near để trống cho nhẹ.
    std::string name;
};

class Scene {
public:
    struct Config {
        std::uint16_t id = 0;
        Grid::Spec grid{.cell_cm = 1000.0F, .radius = 2};
        std::size_t player_max = 4000;
        // Luật đi: bước từ chỗ đi được sang chỗ không đi được bị hoàn lại bằng kPlace (xem moved).
        Walkable walkable{};
        // Vùng sự kiện của cảnh, mét. Rỗng là cảnh không có cổng.
        std::vector<AreaRect> areas;
        // 20, 30 hoặc 40. Mặc định 20 cho tới khi đo chứng minh nhịp cao hơn.
        std::int64_t hz = kTickHz;
    };

    // Hồ sơ hiển thị của người chơi đang đứng, đủ để dựng lại Attach khi đổi cảnh. Không gồm khối chơi.
    struct PlayerCard {
        std::uint64_t character = 0;
        std::string name;
        std::uint16_t level = 0;
        std::uint8_t gender = 0;
        std::uint16_t face = 0;
        std::uint16_t hair = 0;
        std::uint8_t school = 0;
        std::uint16_t direction = 0;
        protocol::EntityState state = protocol::EntityState::kIdle;
        float x_cm = 0.0F;
        float z_cm = 0.0F;
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
    // Thực thể chết: nằm lại (state kDead, sinh lực 0), quái ngừng nghĩ; xác quái biến mất sau kCorpseTicks rồi quái có
    // respawn_ms hồi sinh ở chỗ đặt. EntityDied do nơi gọi phát (cảnh không biết ai hạ gục). Id lạ hay đã chết thì bỏ.
    void kill(std::uint32_t id);
    // Người chơi hồi sinh tại `at` với sinh lực `hp_percent`; báo EntityPos và EntityVitals cho người quanh. Id không phải người
    // đã chết thì bỏ.
    void revive(std::uint32_t id, Point at, std::uint8_t hp_percent, Outbox& out);
    // Cấp mới của thực thể (người chơi lên cấp); người sau này thấy nó hiện ra với cấp này.
    void set_level(std::uint32_t id, std::uint16_t level);
    [[nodiscard]] std::optional<Info> info(std::uint32_t id) const;
    // Duyệt mọi thực thể trong cửa sổ vùng nhìn quanh `id` (gồm chính nó và xác chưa biến mất: Info::state là kDead).
    // O(thực thể trong cửa sổ).
    void for_each_near(std::uint32_t id, const std::function<void(std::uint32_t, const Info&)>& visit) const;
    // Gửi `frame` cho mọi người chơi trong cửa sổ vùng nhìn quanh `id`; `include_self` là gồm cả chính nó nếu là người chơi.
    void tell_near(std::uint32_t id, const std::vector<std::byte>& frame, bool include_self, Outbox& out) const;

    // Sang tick kế: chạy trí khôn của quái tới giờ (tối đa kThinkBudget con), rồi báo dừng (EntityPos kIdle) cho
    // thực thể đã đi mà không có bước mới suốt kIdleAfterTicks tick. O(số quái tới giờ + số thực thể đang đi).
    void advance(Outbox& out);
    // Ghi điểm đứng của mọi người chơi đã đi kể từ lần ghi trước (định kỳ, để sập tiến trình không mất quá một chu kỳ).
    void autosave(Outbox& out);

    [[nodiscard]] std::uint16_t id() const noexcept { return config_.id; }
    [[nodiscard]] std::uint32_t tick() const noexcept { return tick_; }
    // Còn chỗ cho một người chơi nữa (trần người và trần thực thể).
    [[nodiscard]] bool can_admit() const noexcept;
    // Vùng chứa điểm centimet; rỗng khi không vùng nào chứa.
    [[nodiscard]] AreaStand standing(float x_cm, float z_cm) const noexcept;
    // Hồ sơ người chơi; nullopt khi phiên không ở cảnh.
    [[nodiscard]] std::optional<PlayerCard> player_card(std::uint64_t session) const;
    // Ghi điểm đứng hiện tại của phiên (đổi cảnh xong, để sập không còn ở cảnh cũ).
    void keep_spot(std::uint64_t session, Outbox& out) const;
    [[nodiscard]] std::size_t player_count() const noexcept { return players_.size(); }
    [[nodiscard]] std::size_t entity_count() const noexcept { return live_; }
    [[nodiscard]] bool has_session(std::uint64_t session) const noexcept { return players_.contains(session); }
    // Id thực thể của phiên; nullopt khi phiên không ở cảnh này.
    [[nodiscard]] std::optional<std::uint32_t> entity_of(std::uint64_t session) const noexcept;
    [[nodiscard]] std::optional<Where> where(std::uint32_t id) const noexcept;
    // NPC nói chuyện được (kind kNpc, có script, cờ bit 0) theo id thực thể; nullopt khi id lạ hay không phải NPC như thế.
    struct Npc {
        std::uint32_t guid = 0;
        std::uint32_t script = 0;
        std::string name;
        Where at;
    };
    [[nodiscard]] std::optional<Npc> npc(std::uint32_t id) const;

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
        std::uint32_t script = 0;
        std::uint8_t flags = 0;
        std::uint32_t guid = 0;
        std::uint8_t gender = 0;
        std::uint16_t face = 0;
        std::uint16_t hair = 0;
        std::uint8_t school = 0;
        protocol::EntityState state = protocol::EntityState::kIdle;
        // Tick của bước cuối; có nghĩa khi state là kWalk.
        std::uint32_t moved_at = 0;
        // Tick lần gửi vị trí gần nhất cho vành gần và vành xa. kNeverSent là chưa gửi.
        std::uint32_t near_pos_tick = kNeverSent;
        std::uint32_t far_pos_tick = kNeverSent;
        // Vị trí trong moving_ khi state là kWalk (kNotMoving nếu không).
        std::uint32_t moving_slot = kNotMoving;
        [[nodiscard]] Point spot() const noexcept { return Point{.x_cm = x_cm, .z_cm = z_cm}; }
        // Chỉ người chơi: ô gate và nhân vật.
        std::uint64_t session = 0;
        std::uint64_t character = 0;
        // Đã đi kể từ lần ghi điểm đứng cuối.
        bool dirty = false;
        Cell cell{};
    };

    static constexpr std::uint32_t kNotMoving = 0xFFFFFFFFU;

    static constexpr std::uint32_t kNoSlot = 0xFFFFFFFFU;
    enum class Step : std::uint8_t { kMoved, kArrived, kBlocked };

    // --- trí khôn của quái (zone/mind.cpp) ---
    void start_thinking(std::uint32_t index, const Temperament& nature);
    void stop_thinking(std::uint32_t index);
    void think(Outbox& out);
    void think_one(std::uint32_t index, Outbox& out);
    void think_idle(std::uint32_t index, Outbox& out);
    void think_chase(std::uint32_t index, Outbox& out);
    void think_hold(std::uint32_t index);
    void think_home(std::uint32_t index, Outbox& out);
    // Quét người trong tầm; vào trạng thái đuổi nếu thấy. true khi bắt đầu đuổi.
    [[nodiscard]] bool scan_for_prey(std::uint32_t index);
    // Người chơi gần nhất trong tầm quét của con `index`; nullopt khi không có ai.
    [[nodiscard]] std::optional<std::uint32_t> nearest_prey(std::uint32_t index) const;
    void begin_wander(std::uint32_t index);
    void give_up(std::uint32_t index);
    [[nodiscard]] bool passable(Point at) const;
    // Đoạn thẳng from→to đi được: mọi điểm cách nhau chừng kSampleCm đều đi được.
    [[nodiscard]] bool clear_line(Point from, Point to) const;
    // Một bước kMoveEvery tick về phía goal với tốc độ speed_cm; trượt dọc trục khi bước chéo bị chặn.
    [[nodiscard]] Step step_toward(std::uint32_t index, Point goal, std::uint32_t speed_cm, Outbox& out);

    [[nodiscard]] std::optional<Info> info_at(std::uint32_t index, bool with_name) const;
    // Xác hết hạn thì dọn, quái tới giờ hồi sinh thì đặt lại (gọi mỗi tick).
    void tidy_corpses(Outbox& out);
    [[nodiscard]] std::optional<std::uint32_t> allocate();
    void start_walking(std::uint32_t index);
    void stop_walking(std::uint32_t index);
    [[nodiscard]] std::uint32_t id_at(std::uint32_t index) const noexcept;
    [[nodiscard]] std::optional<std::uint32_t> index_of(std::uint32_t id) const noexcept;
    [[nodiscard]] protocol::EntityAppear appear_of(std::uint32_t index) const;
    // Khung EntityFlags của thực thể; rỗng khi cờ bằng 0 (client mặc định cờ 0 nên không cần gửi).
    [[nodiscard]] std::vector<std::byte> flags_frame(std::uint32_t index, Outbox& out) const;
    // Gửi cho người chơi `session` EntityAppear của thực thể, kèm EntityFlags khi có.
    void show_to(std::uint64_t session, std::uint32_t index, Outbox& out) const;
    // Đưa thực thể vừa cấp vào lưới và báo hiện cho những người đang nhìn quanh nó.
    void enter_grid(std::uint32_t index, Outbox& out);
    void relocate(std::uint32_t index, Point to, Outbox& out);
    [[nodiscard]] bool blocked(const Entity& who, const ipc::Moved& step) const;
    void save_spot(const Entity& who, Outbox& out) const;
    void remove(std::uint32_t index, Outbox& out);
    // Gửi `frame` cho mọi người chơi trong cửa sổ quanh `around`, trừ thực thể `skip`.
    void broadcast(Cell around, std::uint32_t skip, const std::vector<std::byte>& frame,
        Outbox& out) const;
    // Gom một vị trí (không giảm nhịp) cho mọi người chơi trong cửa sổ, trừ `skip`.
    void broadcast_pos(Cell around, std::uint32_t skip, const protocol::EntityPos& pos,
        Outbox& out) const;
    struct PosGate {
        bool near_ok = false;
        bool far_ok = false;
        bool sent_near = false;
        bool sent_far = false;
    };

    // Vị trí: gần mỗi rate_.near_stride tick, vành ngoài mỗi rate_.far_stride.
    void fan_position(std::uint32_t index, Cell around, const protocol::EntityPos& pos,
        Outbox& out);
    void give_position(PosGate& gate, std::uint32_t self, std::uint32_t other, Cell at,
        const Outbox::PosBlob& blob, Outbox& out);
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
    // Trí khôn song song với entities_ (cùng chỉ số); thinkers_ là chỉ số các con đang chạy, think_cursor_ là chỗ
    // bắt đầu vòng của tick kế để mọi con đều tới lượt khi quá trần kThinkBudget.
    std::vector<Mind> minds_;
    std::vector<std::uint32_t> thinkers_;
    std::size_t think_cursor_ = 0;
    // Chu kỳ của nhịp đã chọn. Hằng kNearPosStride... chỉ là mốc 20 Hz cho test.
    Rate rate_{};
    dice::Dice rng_;
    // Nơi sinh của quái có thể hồi sinh, theo chỉ số ô; xác chờ biến mất (tick -> id); quái chờ hồi sinh (tick -> chỗ đặt).
    std::unordered_map<std::uint32_t, Spawn> homes_;
    std::multimap<std::uint32_t, std::uint32_t> corpses_;
    std::multimap<std::uint32_t, Spawn> respawns_;
    std::unordered_map<std::uint64_t, std::uint32_t> players_;
    std::unordered_map<std::uint64_t, std::uint32_t> by_character_;
};

} // namespace game::zone
