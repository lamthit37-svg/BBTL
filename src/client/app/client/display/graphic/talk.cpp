/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/talk.cpp
 *  PHÂN HỆ   : Display / Graphic / Talk
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nối hội thoại NPC giữa luồng vẽ và giao diện: tin của phiên mạng vào HUD,
 *    việc người chơi nhờ ra hàng chờ, và chọn NPC dưới chuột (hover, nhấp thì
 *    đi tới rồi nói chuyện).
 *  - Chọn quái và vật rơi dưới chuột khi chơi nối máy chủ (nhấp quái thì đuổi
 *    và đánh, nhấp vật rơi thì đi tới nhặt).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Cách hỏng đã tính trước (CL-03):
//   NPC / vật rơi biến mất giữa lúc đi tới -> bỏ việc đi tới, không gửi Talk hay PickUp.
//   đường tới NPC bị chặn / không tới  -> hết kTalkPatience thì bỏ; người chơi nhấp chỗ khác hay bấm phím đi cũng bỏ.
//   NPC chưa có cờ bấm-được            -> không chọn được (máy chủ quyết định bằng EntityFlags, client không đoán).
//   vật rơi chưa có cờ nhặt-được        -> không chọn được, như NPC.
//   chuột trên giao diện               -> không chọn NPC (cú nhấp thuộc về giao diện).
//   hàng chờ việc người chơi nhờ đầy   -> bỏ việc cũ nhất (kMaxTalkNotes); người chơi chỉ nhờ vài việc mỗi giây.

#include "client/display/graphic/state.hpp"

#include "client/cast/cast.hpp"
#include "client/cast/note.hpp"
#include "client/display/display.hpp"
#include "client/display/graphic/prelude.hpp"
#include "control/ground.hpp"
#include "control/input.hpp"
#include "control/view_ray.hpp"
#include "core/clock.hpp"
#include "core/ground_point.hpp"
#include "look/creature.hpp"
#include "nav/route.hpp"
#include "ogre/vec3.hpp"
#include "ui/hud.hpp"
#include "ui/panel/talk.hpp"

#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <mutex>
#include <optional>
#include <utility>
#include <variant>
#include <vector>

namespace game::client {
namespace {

// Mét của game giữa người chơi và NPC mà từ đó Talk được gửi. Máy chủ nhận Talk trong 8,0 m (a6, talk::Options::range, đo 2D);
// client đi tới gần hơn nhiều để còn dư cho sai số vị trí.
constexpr float kTalkReach = 2.5F;
// Đi tới NPC lâu hơn thế mà chưa tới thì bỏ.
constexpr std::chrono::seconds kTalkPatience{20};
// Hộp để thử tia quanh chân NPC và quái, theo mét của game: nửa rộng và cao. Vật rơi nhỏ hơn nhiều.
constexpr float kPickRadius = 0.7F;
constexpr float kPickHeight = 2.4F;
constexpr float kDropRadius = 0.5F;
constexpr float kDropHeight = 0.6F;
// Mét của game giữa người chơi và vật rơi mà từ đó PickUp được gửi. Máy chủ nhận trong 3,0 m (battle.cpp kPickRangeCm).
constexpr float kPickReach = 1.5F;

} // namespace

void Display::State::pump_talk() {
    if (!hud) return;
    std::vector<ui::panel::talk::Hear> heard;
    {
        const std::scoped_lock<std::mutex> locked(talk_guard);
        heard = std::exchange(talk_heard, {});
    }
    for (const ui::panel::talk::Hear& note : heard) {
        watch_script(note);
        // Sinh lực, kỹ năng, hồi chiêu và lời từ chối chiêu thuộc chiến đấu, không phải giao diện.
        if (hear_fight(note)) continue;
        // Chỉ số của nhân vật nằm ở hero của Display, không ở HUD.
        if (const auto* stats = std::get_if<ui::panel::talk::Stats>(&note)) {
            apply_stats(*stats);
            continue;
        }
        hud->deliver_talk(note);
    }
    talk_title.clear();
    const std::optional<std::uint32_t> npc = hud->talking_with();
    if (!npc || !creature_tables) return;
    const cast::Actor* actor = people.find(*npc);
    if (actor == nullptr) return;
    if (const look::CreatureTemplate* known = creature_tables->find_template(actor->template_id)) talk_title = known->name;
}

void Display::State::drain_says() {
    if (!hud) return;
    const std::vector<ui::panel::talk::Say> says = hud->take_says();
    if (says.empty()) return;
    if (!talk_demo.empty()) {
        for (const ui::panel::talk::Say& said : says) answer_demo(said);
        return;
    }
    const std::scoped_lock<std::mutex> locked(talk_guard);
    for (const ui::panel::talk::Say& say : says) {
        if (talk_says.size() >= kMaxTalkNotes) talk_says.erase(talk_says.begin());
        talk_says.push_back(say);
    }
}

// Thực thể gần mắt nhất mà tia từ điểm màn hình xuyên vào hộp quanh chân; nullptr khi không có.
const cast::Actor* Display::State::pick_actor(control::ScreenPoint point, bool (*wanted)(const cast::Actor&)) const {
    if (!terrain || !has_lens || ground == nullptr || !scale_ok(ground->file)) return nullptr;
    if (view_size.width == 0 || view_size.height == 0) return nullptr;
    const std::optional<std::uint16_t> online_scene = people.scene();
    if (!online_scene || std::cmp_not_equal(walk.scene_id, *online_scene)) return nullptr;
    const control::Ray ray = control::screen_ray(lens, point);
    const float unit = ground->file.scale.x;
    const cast::Actor* nearest = nullptr;
    float best = std::numeric_limits<float>::infinity();
    for (const cast::Actor& actor : people.actors()) {
        if (!wanted(actor)) continue;
        const bool is_drop = actor.kind == cast::Kind::kDrop;
        const ogre::Vec3 foot = world_foot(actor);
        const float half = (is_drop ? kDropRadius : kPickRadius) * unit;
        const float tall = (is_drop ? kDropHeight : kPickHeight) * unit;
        const ogre::Vec3 low{.x = foot.x - half, .y = foot.y, .z = foot.z - half};
        const ogre::Vec3 high{.x = foot.x + half, .y = foot.y + tall, .z = foot.z + half};
        const std::optional<float> reach = control::ray_box_distance(ray, low, high);
        if (reach && *reach < best) {
            best = *reach;
            nearest = &actor;
        }
    }
    return nearest;
}

const cast::Actor* Display::State::talkable_at(control::ScreenPoint point) const {
    const auto is_talkable = [](const cast::Actor& actor) {
        return actor.kind == cast::Kind::kNpc && (actor.flags & cast::kFlagTalk) != 0 && actor.pose != cast::Pose::kDead;
    };
    return pick_actor(point, is_talkable);
}

void Display::State::pick_npc(bool is_over_hud) {
    const cast::Actor* hit = is_over_hud ? nullptr : talkable_at(pointer);
    hovered_npc = hit != nullptr ? std::optional<std::uint32_t>{hit->id} : std::nullopt;
    constexpr auto kLeft = static_cast<std::size_t>(control::MouseButton::kLeft);
    const bool is_press = is_button_down.at(kLeft) && has_button_changed.at(kLeft);
    if (hit == nullptr || !is_press || !hud) return;
    is_npc_press = true;
    start_talk(*hit);
}

// Đường chung của nhấp chuột lên NPC và bước talk của kịch bản: đủ gần thì nói ngay, không thì đi
// tới nó rồi nói (walk_to_talk).
void Display::State::start_talk(const cast::Actor& npc) {
    const bool is_ready = hud && ground != nullptr && scale_ok(ground->file);
    if (!is_ready) return;
    const core::GroundPoint here = game_of(ground->file, walk);
    const core::GroundPoint spot{.x = npc.x, .z = npc.z};
    if (std::hypot(spot.x - here.x, spot.z - here.z) <= kTalkReach) {
        order.reset();
        talk_goal.reset();
        const ui::panel::talk::Talk said{.npc = npc.id};
        hud->say(said);
        return;
    }
    talk_goal = TalkGoal{.npc = npc.id, .until = frame_time + kTalkPatience};
    order_move(spot, nav::MoveMode::kFind);
}

// Như start_talk cho vật rơi: đủ gần thì gửi PickUp, không thì đi tới rồi gửi.
void Display::State::start_pick(const cast::Actor& drop) {
    if (ground == nullptr || !scale_ok(ground->file)) return;
    const core::GroundPoint here = game_of(ground->file, walk);
    const core::GroundPoint spot{.x = drop.x, .z = drop.z};
    if (std::hypot(spot.x - here.x, spot.z - here.z) <= kPickReach) {
        order.reset();
        const ui::panel::talk::PickUp said{.drop = drop.id};
        send_say(said);
        return;
    }
    talk_goal = TalkGoal{.npc = drop.id, .until = frame_time + kTalkPatience, .is_pickup = true};
    order_move(spot, nav::MoveMode::kFind);
}

const cast::Actor* Display::State::foe_at(control::ScreenPoint point) const {
    const auto is_foe = [](const cast::Actor& actor) {
        const bool is_monster = actor.kind == cast::Kind::kMonster && actor.pose != cast::Pose::kDead;
        const bool is_loot = actor.kind == cast::Kind::kDrop && (actor.flags & cast::kFlagPick) != 0;
        return is_monster || is_loot;
    };
    return pick_actor(point, is_foe);
}

// Quái hay vật rơi dưới chuột. Nhấp quái là chọn và đuổi đánh (đánh tự động cho tới khi người chơi tự đi); nhấp vật rơi là
// đi tới nhặt, như nhấp NPC để nói chuyện. Chỉ khi đã vào game qua máy chủ: chơi tại chỗ không có quái để đánh.
void Display::State::pick_foe(bool is_over_hud) {
    hovered_foe.reset();
    if (!is_online_play || is_over_hud || hovered_npc || !hud) return;
    const cast::Actor* hit = foe_at(pointer);
    if (hit == nullptr) return;
    hovered_foe = hit->id;
    constexpr auto kLeft = static_cast<std::size_t>(control::MouseButton::kLeft);
    const bool is_press = is_button_down.at(kLeft) && has_button_changed.at(kLeft);
    if (!is_press) return;
    is_npc_press = true;
    talk_goal.reset();
    if (hit->kind != cast::Kind::kDrop) {
        combat.engage(hit->id);
        return;
    }
    start_pick(*hit);
}

void Display::State::walk_to_talk(const Steering& keys, core::Clock::time_point now) {
    if (!talk_goal) return;
    const bool is_steering = keys.has_walk && (keys.walk_forward != 0.0F || keys.walk_right != 0.0F);
    const cast::Actor* actor = people.find(talk_goal->npc);
    const bool is_lost = actor == nullptr || ground == nullptr || !scale_ok(ground->file) || !hud;
    if (is_lost || is_steering || tilt.has_value() || now > talk_goal->until) {
        talk_goal.reset();
        return;
    }
    const core::GroundPoint here = game_of(ground->file, walk);
    const TalkGoal goal = *talk_goal;
    const float reach = goal.is_pickup ? kPickReach : kTalkReach;
    if (std::hypot(actor->x - here.x, actor->z - here.z) > reach) return;
    order.reset();
    talk_goal.reset();
    if (goal.is_pickup) send_say(ui::panel::talk::PickUp{.drop = goal.npc});
    if (!goal.is_pickup) hud->say(ui::panel::talk::Talk{.npc = goal.npc});
}

} // namespace game::client
