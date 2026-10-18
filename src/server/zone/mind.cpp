/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/mind.cpp
 *  PHÂN HỆ   : Server / Zone / Mind
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Trí khôn của quái và NPC: Scene::think và các bước của nó. Hành vi và
 *    nguồn: zone/mind.hpp.
 *  - Mỗi con chạy khi tới wake. Con đang đi dậy 10 bước mỗi giây
 *    (rate_.move_every). Con đứng ngủ tới giờ quét hoặc lần lang thang kế.
 *    Tổng việc mỗi tick bị chặn bởi kThinkBudget.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/scene.hpp"

#include "dice/dice.hpp"
#include "protocol/messages.hpp"
#include "zone/aoi.hpp"
#include "zone/mind.hpp"
#include "zone/outbox.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <optional>

namespace game::zone {
namespace {

// Khoảng lấy mẫu khi kiểm một đoạn thẳng có đi được không: nhỏ hơn bề ngang thường của vật cản.
constexpr float kSampleCm = 100.0F;
// Số lần thử chọn điểm lang thang (MAX_RAND_TIMES của máy chủ 2008).
constexpr int kWanderTries = 10;
// Con không có việc nào hẹn giờ thì ngủ chừng này tick rồi dậy kiểm lại.
constexpr std::uint32_t kLongSleepTicks = 1U << 20U;

[[nodiscard]] std::uint32_t run_speed(std::uint32_t walk_cm) noexcept { return walk_cm * kRunPercent / 100U; }

} // namespace

void Scene::start_thinking(std::uint32_t index, const Temperament& nature) {
    const bool wanders = nature.walk_cm > 0 && nature.wander_ticks > 0 && nature.range_cm > 0;
    if (nature.scan_ticks == 0 && !wanders) return;
    const Entity& who = entities_[index];
    Mind& mind = minds_[index];
    mind = Mind{};
    mind.nature = nature;
    mind.home_x_cm = who.x_cm;
    mind.home_z_cm = who.z_cm;
    // Lệch pha ngẫu nhiên để cả cảnh không quét và đi cùng một tick.
    if (nature.scan_ticks > 0) mind.next_scan = tick_ + 1U + static_cast<std::uint32_t>(rng_.below(nature.scan_ticks));
    if (wanders) mind.next_wander = tick_ + 1U + static_cast<std::uint32_t>(rng_.below(nature.wander_ticks));
    mind.wake = tick_ + 1U;
    mind.slot = static_cast<std::uint32_t>(thinkers_.size());
    thinkers_.push_back(index);
}

void Scene::stop_thinking(std::uint32_t index) {
    Mind& mind = minds_[index];
    if (mind.slot == kNoSlot) return;
    const std::uint32_t last = thinkers_.back();
    thinkers_[mind.slot] = last;
    minds_[last].slot = mind.slot;
    thinkers_.pop_back();
    mind = Mind{};
}

void Scene::think(Outbox& out) {
    const std::size_t count = thinkers_.size();
    if (count == 0) return;
    std::size_t budget = kThinkBudget;
    std::size_t visited = 0;
    for (; visited < count && budget > 0; ++visited) {
        const std::uint32_t index = thinkers_[(think_cursor_ + visited) % count];
        if (tick_ < minds_[index].wake) continue;
        --budget;
        think_one(index, out);
    }
    // Hết lượt giữa chừng thì tick sau bắt đầu ngay chỗ dừng.
    think_cursor_ = (think_cursor_ + visited) % count;
}

void Scene::think_one(std::uint32_t index, Outbox& out) {
    switch (minds_[index].mode) {
    case Mode::kIdle:
    case Mode::kWander: think_idle(index, out); return;
    case Mode::kChase: think_chase(index, out); return;
    case Mode::kHold: think_hold(index); return;
    case Mode::kHome: think_home(index, out); return;
    }
}

bool Scene::passable(Point at) const { return !config_.walkable || config_.walkable(at.x_cm, at.z_cm); }

bool Scene::clear_line(Point from, Point to, float sample_cm) const {
    if (!config_.walkable) return true;
    const float length = std::sqrt(from.distance_squared(to));
    if (length <= 0.0F) return true;
    const int samples = static_cast<int>(std::ceil(length / sample_cm));
    for (int at = 1; at <= samples; ++at) {
        const float along = std::min(1.0F, static_cast<float>(at) * sample_cm / length);
        const Point point{.x_cm = from.x_cm + ((to.x_cm - from.x_cm) * along),
            .z_cm = from.z_cm + ((to.z_cm - from.z_cm) * along)};
        if (!passable(point)) return false;
    }
    return true;
}

Scene::Step Scene::step_toward(std::uint32_t index, Point goal, std::uint32_t speed_cm, Outbox& out) {
    const Entity& who = entities_[index];
    const float dx = goal.x_cm - who.x_cm;
    const float dz = goal.z_cm - who.z_cm;
    const float length = std::sqrt((dx * dx) + (dz * dz));
    const float every = static_cast<float>(rate_.move_every);
    const float steps = static_cast<float>(rate_.hz);
    const float stride = static_cast<float>(speed_cm) * every / steps;
    const bool arrives = length <= stride;
    const Point next = arrives ? goal
                               : Point{.x_cm = who.x_cm + (dx / length * stride), .z_cm = who.z_cm + (dz / length * stride)};
    if (passable(next)) {
        relocate(index, next, out);
        return arrives ? Step::kArrived : Step::kMoved;
    }
    // Bước chéo bị chặn: trượt dọc từng trục (đi sát tường thay vì đứng chết).
    for (const Point slide : {Point{.x_cm = next.x_cm, .z_cm = who.z_cm}, Point{.x_cm = who.x_cm, .z_cm = next.z_cm}}) {
        if (slide.distance_squared(who.spot()) < 1.0F || !passable(slide)) continue;
        relocate(index, slide, out);
        return Step::kMoved;
    }
    return Step::kBlocked;
}

std::optional<std::uint32_t> Scene::nearest_prey(std::uint32_t index) const {
    const Entity& who = entities_[index];
    const auto reach = static_cast<float>(minds_[index].nature.scan_cm);
    float best_squared = reach * reach;
    std::optional<std::uint32_t> best;
    grid_.for_each_in_window(who.cell, [&](std::uint32_t other) {
        const Entity& prey = entities_[other];
        if (!prey.live || prey.kind != protocol::EntityKind::kPlayer) return;
        const float squared = who.spot().distance_squared(prey.spot());
        // Bằng khoảng cách thì lấy chỉ số nhỏ: kết quả không phụ thuộc thứ tự duyệt của lưới.
        const bool nearer = squared < best_squared || (squared == best_squared && best && other < *best);
        if (nearer || (!best && squared <= best_squared)) {
            best_squared = squared;
            best = other;
        }
    });
    return best;
}

bool Scene::scan_for_prey(std::uint32_t index) {
    Mind& mind = minds_[index];
    if (mind.nature.scan_ticks == 0 || tick_ < mind.next_scan) return false;
    mind.next_scan = tick_ + mind.nature.scan_ticks;
    const std::optional<std::uint32_t> prey = nearest_prey(index);
    if (!prey) return false;
    Entity& who = entities_[index];
    mind.mode = Mode::kChase;
    mind.target = id_at(*prey);
    mind.origin_x_cm = who.x_cm;
    mind.origin_z_cm = who.z_cm;
    mind.stuck = 0;
    who.speed_cm = static_cast<std::uint16_t>(run_speed(mind.nature.walk_cm));
    return true;
}

void Scene::begin_wander(std::uint32_t index) {
    Mind& mind = minds_[index];
    const Temperament& nature = mind.nature;
    mind.next_wander = tick_ + nature.wander_ticks + static_cast<std::uint32_t>(rng_.below(nature.wander_ticks));
    const Entity& who = entities_[index];
    for (int attempt = 0; attempt < kWanderTries; ++attempt) {
        // Như ToRandMove của máy chủ 2008: rand() % range - rand() % range, nên dồn về gần chỗ sinh (phân phối tam giác).
        const auto offset = [&] {
            return static_cast<float>(rng_.below(nature.range_cm)) - static_cast<float>(rng_.below(nature.range_cm));
        };
        const Point target{.x_cm = mind.home_x_cm + offset(), .z_cm = mind.home_z_cm + offset()};
        const Point from{.x_cm = who.x_cm, .z_cm = who.z_cm};
        const bool is_open = passable(target) && clear_line(from, target, kSampleCm);
        if (!is_open) continue;
        mind.mode = Mode::kWander;
        mind.goal_x_cm = target.x_cm;
        mind.goal_z_cm = target.z_cm;
        mind.stuck = 0;
        return;
    }
}

void Scene::give_up(std::uint32_t index) {
    Mind& mind = minds_[index];
    mind.mode = Mode::kHome;
    mind.target = 0;
    mind.stuck = 0;
    entities_[index].speed_cm = static_cast<std::uint16_t>(run_speed(mind.nature.walk_cm));
}

void Scene::think_idle(std::uint32_t index, Outbox& out) {
    Mind& mind = minds_[index];
    // Đang đi lang thang vẫn quét (máy chủ 2008: đi ngẫu nhiên không rời trạng thái Idle).
    if (scan_for_prey(index)) {
        mind.wake = tick_ + 1U;
        return;
    }
    const bool wanders = mind.nature.wander_ticks > 0 && mind.nature.walk_cm > 0;
    if (mind.mode == Mode::kWander) {
        const Step result = step_toward(index, Point{.x_cm = mind.goal_x_cm, .z_cm = mind.goal_z_cm},
            mind.nature.walk_cm, out);
        if (result == Step::kMoved) {
            mind.wake = tick_ + rate_.move_every;
            return;
        }
        // Tới nơi, hay bị chặn: đứng lại.
        mind.mode = Mode::kIdle;
    } else if (wanders && tick_ >= mind.next_wander) {
        begin_wander(index);
        if (mind.mode == Mode::kWander) {
            mind.wake = tick_ + 1U;
            return;
        }
    }
    std::uint32_t next = tick_ + kLongSleepTicks;
    if (mind.nature.scan_ticks > 0) next = std::min(next, mind.next_scan);
    if (wanders) next = std::min(next, mind.next_wander);
    mind.wake = std::max(next, tick_ + 1U);
}

void Scene::think_chase(std::uint32_t index, Outbox& out) {
    Mind& mind = minds_[index];
    const Entity& who = entities_[index];
    const std::optional<std::uint32_t> prey = index_of(mind.target);
    const auto leash = static_cast<float>(mind.nature.return_cm);
    const bool too_far = mind.nature.return_cm > 0 &&
        who.spot().distance_squared(Point{.x_cm = mind.origin_x_cm, .z_cm = mind.origin_z_cm}) > leash * leash;
    if (!prey || entities_[*prey].kind != protocol::EntityKind::kPlayer || too_far) {
        give_up(index);
        mind.wake = tick_ + 1U;
        return;
    }
    const Entity& target = entities_[*prey];
    if (who.spot().distance_squared(target.spot()) <= kMeleeCm * kMeleeCm) {
        mind.mode = Mode::kHold;
        mind.wake = tick_ + 1U;
        return;
    }
    const Step result = step_toward(index, Point{.x_cm = target.x_cm, .z_cm = target.z_cm},
        run_speed(mind.nature.walk_cm), out);
    if (result == Step::kBlocked) {
        if (++mind.stuck >= kStuckSteps) give_up(index);
    } else {
        mind.stuck = 0;
    }
    mind.wake = tick_ + rate_.move_every;
}

void Scene::think_hold(std::uint32_t index) {
    Mind& mind = minds_[index];
    const Entity& who = entities_[index];
    const std::optional<std::uint32_t> prey = index_of(mind.target);
    if (!prey || entities_[*prey].kind != protocol::EntityKind::kPlayer) {
        give_up(index);
        mind.wake = tick_ + 1U;
        return;
    }
    const Entity& target = entities_[*prey];
    const float limit = kMeleeCm + kHoldSlackCm;
    if (who.spot().distance_squared(target.spot()) > limit * limit) mind.mode = Mode::kChase;
    mind.wake = tick_ + rate_.move_every;
}

void Scene::think_home(std::uint32_t index, Outbox& out) {
    Mind& mind = minds_[index];
    const Point home{.x_cm = mind.home_x_cm, .z_cm = mind.home_z_cm};
    const Step result = step_toward(index, home, run_speed(mind.nature.walk_cm), out);
    bool arrived = result == Step::kArrived;
    if (result == Step::kBlocked && ++mind.stuck >= kStuckSteps) {
        // Máy chủ 2008 (ToGoHome): Move hỏng thì DirectMoveTo, tức nhảy thẳng về.
        relocate(index, home, out);
        arrived = true;
    }
    if (result == Step::kMoved) mind.stuck = 0;
    if (!arrived) {
        mind.wake = tick_ + rate_.move_every;
        return;
    }
    mind.mode = Mode::kIdle;
    mind.stuck = 0;
    entities_[index].speed_cm = mind.nature.walk_cm;
    // Về nhà thì hồi đầy sinh lực (RecoverHP); quái chưa bị đánh nên thường đã đầy.
    VitalsChange full;
    full.id = id_at(index);
    full.hp_percent = 100;
    full.mp_percent = entities_[index].mp_percent;
    full.rage = entities_[index].rage;
    set_vitals(full, out);
    mind.wake = tick_ + 1U;
}

} // namespace game::zone
