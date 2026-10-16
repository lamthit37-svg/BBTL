/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/cast/cast.cpp
 *  PHÂN HỆ   : Client / Cast / Cast
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cast: áp tin thế giới lên danh sách thực thể và làm mượt chuyển động của
 *    chúng. Hợp đồng ở cast.hpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/cast/cast.hpp"

#include "client/cast/note.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <numbers>
#include <utility>
#include <variant>

namespace game::client::cast {
namespace {

// Một khung dài hơn thế này (cửa sổ bị kéo, máy treo) chỉ được tính bằng chừng này: thực thể không bay vọt qua cảnh.
constexpr float kLongestStep = 0.25F;
// Thực thể chạy kịp đích trong chừng này giây dù tốc độ khai báo thấp hơn: giữ độ trễ hiển thị ở mức vài khung.
constexpr float kCatchUp = 0.12F;
// Tốc độ đuổi tối đa là kBoost lần tốc độ khai báo cộng kBoostFloor mét mỗi giây (thực thể không khai tốc độ vẫn đuổi
// được): xa hơn mức đó trong tầm kSnapDistance thì nhìn như trượt nhanh, không như bay.
constexpr float kBoost = 4.0F;
constexpr float kBoostFloor = 2.0F;
// Xa hơn thế (mét) là dịch chuyển, không phải bước đi: đặt thẳng vào đích.
constexpr float kSnapDistance = 12.0F;
// Gần hơn thế (mét) coi là đã tới đích.
constexpr float kStill = 0.02F;
// Máy chủ còn báo đang đi mà thực thể tới đích: giữ dáng đi chừng này giây chờ gói kế thay vì chớp về dáng đứng.
constexpr float kWalkGrace = 0.15F;
// Tốc độ quay mặt, radian mỗi giây.
constexpr float kTurnRate = 12.0F;

[[nodiscard]] bool finite(float first, float second, float third) noexcept {
    return std::isfinite(first) && std::isfinite(second) && std::isfinite(third);
}

// Hiệu hai góc về (-π, π].
[[nodiscard]] float wrap(float angle) noexcept {
    constexpr float kTau = 2.0F * std::numbers::pi_v<float>;
    angle = std::fmod(angle, kTau);
    if (angle > std::numbers::pi_v<float>) angle -= kTau;
    if (angle <= -std::numbers::pi_v<float>) angle += kTau;
    return angle;
}

} // namespace

void Cast::apply(const Note& note) {
    std::visit([this](const auto& held) { on(held); }, note);
}

void Cast::clear() noexcept {
    actors_.clear();
    goals_.clear();
    index_.clear();
    scene_.reset();
    self_id_ = 0;
    self_hp_.reset();
}

const Actor* Cast::find(std::uint32_t id) const noexcept {
    const auto found = index_.find(id);
    return found == index_.end() ? nullptr : &actors_[found->second];
}

void Cast::on(const Arrive& note) {
    if (!finite(note.x, note.z, note.facing)) return;
    clear();
    scene_ = note.scene;
    self_id_ = note.self_id;
}

void Cast::on(const Spawn& note) {
    if (!finite(note.x, note.z, note.facing) || !std::isfinite(note.speed)) return;
    if (note.id == 0) return;
    if (note.id == self_id_) {
        self_hp_ = note.hp_percent;
        return;
    }
    Actor shown{.id = note.id,
        .kind = note.kind,
        .template_id = note.template_id,
        .name = note.name,
        .level = note.level,
        .x = note.x,
        .z = note.z,
        .facing = wrap(note.facing),
        .speed = std::max(note.speed, 0.0F),
        .hp_percent = note.hp_percent,
        .gender = note.gender,
        .face = note.face,
        .hair = note.hair,
        .school = note.school,
        .pose = note.pose};
    const Goal goal{.x = note.x, .z = note.z, .facing = shown.facing, .pose = note.pose};
    if (const auto found = index_.find(note.id); found != index_.end()) {
        actors_[found->second] = std::move(shown);
        goals_[found->second] = goal;
        return;
    }
    if (actors_.size() >= kMaxActors) {
        ++dropped_;
        return;
    }
    index_.emplace(note.id, actors_.size());
    actors_.push_back(std::move(shown));
    goals_.push_back(goal);
}

void Cast::on(const Vanish& note) {
    const auto found = index_.find(note.id);
    if (found != index_.end()) erase_at(found->second);
}

void Cast::on(const Moved& note) {
    if (!finite(note.x, note.z, note.facing)) return;
    const auto found = index_.find(note.id);
    if (found == index_.end()) return;
    Goal& goal = goals_[found->second];
    // So có dấu: tick vòng qua 2^32 vẫn xếp đúng thứ tự.
    if (goal.has_tick && static_cast<std::int32_t>(note.tick - goal.tick) < 0) return;
    goal.x = note.x;
    goal.z = note.z;
    goal.facing = wrap(note.facing);
    goal.pose = note.pose;
    goal.tick = note.tick;
    goal.has_tick = true;
}

void Cast::on(const Hurt& note) {
    if (note.id == self_id_) {
        self_hp_ = note.hp_percent;
        return;
    }
    const auto found = index_.find(note.id);
    if (found != index_.end()) actors_[found->second].hp_percent = note.hp_percent;
}

void Cast::on(const Flagged& note) {
    const auto found = index_.find(note.id);
    if (found != index_.end()) actors_[found->second].flags = note.flags;
}

// Chết là nằm tại chỗ: đặt cả đích lẫn dáng hiện tại, không chờ advance. Nơi vẽ phát clip chết rồi giữ khung cuối,
// hoặc lặp clip xác. Chính nhân vật không nằm trong danh sách; nơi vẽ tự giữ trạng thái chết của mình.
void Cast::on(const Died& note) {
    if (note.id == self_id_) self_hp_ = std::uint8_t{0};
    const auto found = index_.find(note.id);
    if (found == index_.end()) return;
    Actor& shown = actors_[found->second];
    Goal& goal = goals_[found->second];
    shown.hp_percent = 0;
    shown.pose = Pose::kDead;
    shown.flags = 0;
    goal.pose = Pose::kDead;
    goal.x = shown.x;
    goal.z = shown.z;
    goal.facing = shown.facing;
}

void Cast::advance(float seconds) {
    if (!(seconds > 0.0F)) return;
    seconds = std::min(seconds, kLongestStep);
    for (std::size_t index = 0; index < actors_.size(); ++index) step(actors_[index], goals_[index], seconds);
}

float Cast::chase(Actor& shown, const Goal& goal, float seconds) noexcept {
    const float delta_x = goal.x - shown.x;
    const float delta_z = goal.z - shown.z;
    const float distance = std::hypot(delta_x, delta_z);
    if (distance > kSnapDistance) {
        shown.x = goal.x;
        shown.z = goal.z;
    } else if (distance > 0.0F) {
        const float pace = std::max(shown.speed, std::min(distance / kCatchUp, (shown.speed * kBoost) + kBoostFloor));
        const float reach = pace * seconds;
        if (reach >= distance) {
            shown.x = goal.x;
            shown.z = goal.z;
        } else {
            shown.x += delta_x / distance * reach;
            shown.z += delta_z / distance * reach;
        }
    }
    return distance;
}

void Cast::step(Actor& shown, Goal& goal, float seconds) noexcept {
    if (goal.pose == Pose::kDead) {
        shown.x = goal.x;
        shown.z = goal.z;
        shown.facing = goal.facing;
        shown.pose = Pose::kDead;
        return;
    }
    const float distance = chase(shown, goal, seconds);
    if (distance > kStill) {
        goal.idle_for = 0.0F;
        shown.pose = Pose::kWalk;
    } else {
        goal.idle_for += seconds;
        shown.pose = goal.pose == Pose::kWalk && goal.idle_for < kWalkGrace ? Pose::kWalk : Pose::kIdle;
    }
    const float gap = wrap(goal.facing - shown.facing);
    const float turn = kTurnRate * seconds;
    shown.facing = wrap(std::abs(gap) <= turn ? goal.facing : shown.facing + std::copysign(turn, gap));
}

void Cast::erase_at(std::size_t index) {
    const std::size_t last = actors_.size() - 1;
    index_.erase(actors_[index].id);
    if (index != last) {
        actors_[index] = std::move(actors_[last]);
        goals_[index] = goals_[last];
        index_[actors_[index].id] = index;
    }
    actors_.pop_back();
    goals_.pop_back();
}

} // namespace game::client::cast
