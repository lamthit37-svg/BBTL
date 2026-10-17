/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Cast/cast_tests.cpp
 *  PHÂN HỆ   : Cast / Cast Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm Cast: áp tin thế giới và chuyển động mượt của thực thể.
 *  - Các ca là điều máy chủ có thể làm sai mà client nhìn vào không thấy: gói
 *    cũ tới sau gói mới (kể cả vòng tick), số NaN, quá nhiều thực thể, tin về
 *    id đã biến mất, xoá giữa danh sách làm lệch chỉ số, khung hình dừng lâu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/cast/cast.hpp"
#include "client/cast/note.hpp"
#include "core/check.hpp"
#include "core/ground_point.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <limits>
#include <numbers>

namespace game::test {
namespace {

using client::cast::Actor;
using client::cast::Arrive;
using client::cast::Cast;
using client::cast::Hurt;
using client::cast::Kind;
using client::cast::Moved;
using client::cast::Pose;
using client::cast::Pulled;
using client::cast::Spawn;
using client::cast::Vanish;
using core::GroundPoint;

[[nodiscard]] bool near_value(float left, float right, float slack = 1e-3F) {
    return std::fabs(left - right) < slack;
}

[[nodiscard]] Spawn monster(std::uint32_t id, GroundPoint at, float speed = 3.0F) {
    Spawn spawn;
    spawn.id = id;
    spawn.kind = Kind::kMonster;
    spawn.template_id = 100 + id;
    spawn.x = at.x;
    spawn.z = at.z;
    spawn.speed = speed;
    return spawn;
}

// Cho thực thể đủ thời gian (nhiều khung nhỏ: advance kẹp mỗi khung) để tới đích.
void settle(Cast& cast) {
    for (int frame = 0; frame < 200; ++frame) cast.advance(0.05F);
}

void arrive_clears(Context& context) {
    Cast cast;
    cast.apply(Arrive{.scene = 2, .x = 1.0F, .z = 1.0F, .facing = 0.0F, .self_id = 9});
    cast.apply(monster(1, {.x = 5.0F, .z = 5.0F}));
    context.expect(cast.actors().size() == 1 && cast.scene() == 2 && cast.self_id() == 9, "vào cảnh rồi hiện một quái");
    cast.apply(Arrive{.scene = 7, .x = 0.0F, .z = 0.0F, .facing = 0.0F, .self_id = 4});
    context.expect(cast.actors().empty(), "đổi cảnh xoá thực thể cũ");
    context.expect(cast.scene() == 7 && cast.self_id() == 4, "cảnh và id mới");
}

void self_is_not_drawn(Context& context) {
    Cast cast;
    cast.apply(Arrive{.scene = 2, .x = 0.0F, .z = 0.0F, .facing = 0.0F, .self_id = 9});
    Spawn me = monster(9, {.x = 0.0F, .z = 0.0F});
    me.kind = Kind::kPlayer;
    me.hp_percent = 80;
    cast.apply(me);
    context.expect(cast.actors().empty(), "chính mình không nằm trong danh sách vẽ");
    context.expect(cast.self_hp() == 80, "nhưng sinh lực được nhớ");
    cast.apply(Hurt{.id = 9, .hp_percent = 35});
    context.expect(cast.self_hp() == 35, "EntityVitals của mình cập nhật sinh lực");
    cast.apply(Moved{.id = 9, .x = 3.0F, .z = 3.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kWalk});
    context.expect(cast.actors().empty(), "gói vị trí của mình không tạo thực thể");
}

void vanish_keeps_index(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    for (std::uint32_t id = 1; id <= 4; ++id) cast.apply(monster(id, {.x = static_cast<float>(id), .z = 0.0F}));
    cast.apply(Vanish{.id = 2});
    context.expect(cast.actors().size() == 3 && cast.find(2) == nullptr, "mất một");
    // Thực thể cuối được dời vào chỗ trống: id 4 vẫn phải tìm thấy đúng và nhận được gói của nó.
    const Actor* last = cast.find(4);
    context.expect(last != nullptr && near_value(last->x, 4.0F), "id cuối còn nguyên sau khi dời chỗ");
    cast.apply(Moved{.id = 4, .x = 9.0F, .z = 0.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kIdle});
    settle(cast);
    context.expect(cast.find(4) != nullptr && near_value(cast.find(4)->x, 9.0F), "gói vị trí đến đúng id 4");
    context.expect(cast.find(3) != nullptr && near_value(cast.find(3)->x, 3.0F), "id 3 không bị động");
    cast.apply(Vanish{.id = 99});
    cast.apply(Vanish{.id = 2});
    context.expect(cast.actors().size() == 3, "xoá id lạ hay xoá hai lần không làm gì");
}

void move_after_vanish_does_not_revive(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 1.0F, .z = 0.0F}));
    cast.apply(Moved{.id = 1, .x = 3.0F, .z = 0.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kWalk});
    cast.apply(Vanish{.id = 1});
    cast.apply(Moved{.id = 1, .x = 9.0F, .z = 0.0F, .facing = 0.0F, .tick = 2, .pose = Pose::kWalk});
    context.expect(cast.find(1) == nullptr, "vị trí tới sau khi biến mất không hồi sinh id cũ");
    cast.apply(monster(2, {.x = 2.0F, .z = 0.0F}));
    cast.apply(Moved{.id = 2, .x = 4.0F, .z = 0.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kWalk});
    settle(cast);
    context.expect(cast.find(1) == nullptr && cast.find(2) != nullptr, "id mới không nhận vị trí của id cũ");
    context.expect(near_value(cast.find(2)->x, 4.0F), "id mới nhận đúng vị trí của chính nó");
}

void chases_goal(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 0.0F, .z = 0.0F}, 3.0F));
    cast.apply(Moved{.id = 1, .x = 0.0F, .z = 6.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kWalk});
    cast.advance(0.1F);
    const Actor* actor = cast.find(1);
    context.expect(actor != nullptr && actor->pose == Pose::kWalk, "đang đi");
    context.expect(actor != nullptr && actor->z > 0.2F && actor->z < 6.0F, "đã dời nhưng chưa tới đích");
    for (int frame = 0; frame < 100; ++frame) cast.advance(0.05F);
    actor = cast.find(1);
    context.expect(actor != nullptr && near_value(actor->z, 6.0F) && actor->pose == Pose::kIdle, "tới đích thì đứng");
}

void walk_grace(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 2.0F, .z = 2.0F}));
    cast.apply(Moved{.id = 1, .x = 2.0F, .z = 2.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kWalk});
    cast.advance(0.016F);
    context.expect(cast.find(1)->pose == Pose::kWalk, "máy chủ báo đi, vừa tới đích: giữ dáng đi chờ gói kế");
    for (int frame = 0; frame < 20; ++frame) cast.advance(0.016F);
    context.expect(cast.find(1)->pose == Pose::kIdle, "hết thời gian chờ thì về dáng đứng");
}

void snaps_far(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 0.0F, .z = 0.0F}));
    cast.apply(Moved{.id = 1, .x = 80.0F, .z = 0.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kIdle});
    cast.advance(0.016F);
    context.expect(near_value(cast.find(1)->x, 80.0F), "dịch chuyển xa thì đặt thẳng vào đích");
}

void long_stall(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 0.0F, .z = 0.0F}, 4.0F));
    cast.apply(Moved{.id = 1, .x = 10.0F, .z = 0.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kWalk});
    cast.advance(60.0F);
    const float x = cast.find(1)->x;
    context.expect(x > 0.0F && x < 10.0F, "một khung dài một phút không làm thực thể vọt tới đích");
    cast.advance(0.0F);
    cast.advance(-1.0F);
    cast.advance(std::numeric_limits<float>::quiet_NaN());
    context.expect(near_value(cast.find(1)->x, x), "dt không dương hay NaN thì đứng yên");
}

void stale_ticks(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 0.0F, .z = 0.0F}));
    cast.apply(Moved{.id = 1, .x = 5.0F, .z = 0.0F, .facing = 0.0F, .tick = 100, .pose = Pose::kIdle});
    cast.apply(Moved{.id = 1, .x = 1.0F, .z = 0.0F, .facing = 0.0F, .tick = 99, .pose = Pose::kIdle});
    settle(cast);
    context.expect(near_value(cast.find(1)->x, 5.0F), "gói tick 99 tới sau tick 100 bị bỏ");
    // Vòng 2^32: tick 3 sau 0xFFFFFFFE là gói mới hơn.
    cast.apply(monster(2, {.x = 0.0F, .z = 0.0F}));
    cast.apply(Moved{.id = 2, .x = 7.0F, .z = 0.0F, .facing = 0.0F, .tick = 0xFFFFFFFEU, .pose = Pose::kIdle});
    cast.apply(Moved{.id = 2, .x = 8.0F, .z = 0.0F, .facing = 0.0F, .tick = 3, .pose = Pose::kIdle});
    settle(cast);
    context.expect(near_value(cast.find(2)->x, 8.0F), "tick vòng qua 2^32 vẫn là gói mới");
}

void hostile_numbers(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    constexpr float kNan = std::numeric_limits<float>::quiet_NaN();
    constexpr float kInf = std::numeric_limits<float>::infinity();
    cast.apply(monster(1, {.x = kNan, .z = 0.0F}));
    cast.apply(monster(2, {.x = 0.0F, .z = kInf}));
    context.expect(cast.actors().empty(), "Spawn có NaN hay vô cực bị bỏ");
    cast.apply(monster(3, {.x = 1.0F, .z = 1.0F}));
    cast.apply(Moved{.id = 3, .x = kNan, .z = 0.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kWalk});
    cast.apply(Moved{.id = 3, .x = 0.0F, .z = 0.0F, .facing = kInf, .tick = 2, .pose = Pose::kWalk});
    cast.advance(1.0F);
    context.expect(near_value(cast.find(3)->x, 1.0F) && near_value(cast.find(3)->z, 1.0F), "Moved hỏng không dời");
    Spawn bad = monster(4, {.x = 0.0F, .z = 0.0F}, kNan);
    cast.apply(bad);
    context.expect(cast.find(4) == nullptr, "tốc độ NaN bị bỏ");
    cast.apply(monster(0, {.x = 0.0F, .z = 0.0F}));
    context.expect(cast.find(0) == nullptr, "id 0 không hợp lệ");
    cast.apply(Moved{.id = 77, .x = 1.0F, .z = 1.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kIdle});
    cast.apply(Hurt{.id = 77, .hp_percent = 3});
    context.expect(cast.actors().size() == 1, "tin về id chưa từng hiện bị bỏ");
}

void caps_actors(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    for (std::uint32_t id = 1; id <= client::cast::kMaxActors + 10; ++id) cast.apply(monster(id, {.x = 0.0F, .z = 0.0F}));
    context.expect(cast.actors().size() == client::cast::kMaxActors, "chạm trần thì dừng nhận");
    context.expect(cast.dropped() == 10, "đếm số Spawn bị bỏ");
    cast.apply(monster(1, {.x = 4.0F, .z = 4.0F}));
    context.expect(cast.actors().size() == client::cast::kMaxActors && near_value(cast.find(1)->x, 4.0F),
        "Spawn lại id có sẵn vẫn được dù đầy");
}

void dead_stays(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 0.0F, .z = 0.0F}));
    cast.apply(Moved{.id = 1, .x = 2.0F, .z = 0.0F, .facing = 0.0F, .tick = 1, .pose = Pose::kDead});
    cast.advance(0.016F);
    context.expect(cast.find(1)->pose == Pose::kDead && near_value(cast.find(1)->x, 2.0F), "chết thì nằm ở chỗ chết");
    Spawn corpse = monster(2, {.x = 3.0F, .z = 3.0F});
    corpse.pose = Pose::kDead;
    corpse.hp_percent = 0;
    cast.apply(corpse);
    cast.advance(0.016F);
    context.expect(cast.find(2)->pose == Pose::kDead && cast.find(2)->hp_percent == 0, "xác hiện sẵn");
}

void turns_the_short_way(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    Spawn spawn = monster(1, {.x = 0.0F, .z = 0.0F});
    spawn.facing = 3.0F;
    cast.apply(spawn);
    cast.apply(Moved{.id = 1, .x = 0.0F, .z = 0.0F, .facing = -3.0F, .tick = 1, .pose = Pose::kIdle});
    cast.advance(0.01F);
    // Từ 3 rad sang -3 rad đi qua π (khoảng cách 0,28 rad), không quay ngược cả vòng.
    context.expect(cast.find(1)->facing > 3.0F || cast.find(1)->facing < -3.0F, "quay theo đường ngắn qua π");
    for (int frame = 0; frame < 10; ++frame) cast.advance(0.05F);
    context.expect(near_value(cast.find(1)->facing, -3.0F), "tới đúng hướng đích");
    context.expect(std::fabs(cast.find(1)->facing) <= std::numbers::pi_v<float>, "hướng luôn trong (-π, π]");
}

void pulled_is_not_cast_business(Context& context) {
    Cast cast;
    cast.apply(Arrive{});
    cast.apply(monster(1, {.x = 1.0F, .z = 1.0F}));
    cast.apply(Pulled{.x = 50.0F, .z = 50.0F});
    context.expect(cast.actors().size() == 1 && near_value(cast.find(1)->x, 1.0F), "Pulled không đụng thực thể nào");
}

constexpr std::array kCases{
    Case{.name = "arrive_clears", .body = &arrive_clears},
    Case{.name = "self_is_not_drawn", .body = &self_is_not_drawn},
    Case{.name = "vanish_keeps_index", .body = &vanish_keeps_index},
    Case{.name = "move_after_vanish_does_not_revive", .body = &move_after_vanish_does_not_revive},
    Case{.name = "chases_goal", .body = &chases_goal},
    Case{.name = "walk_grace", .body = &walk_grace},
    Case{.name = "snaps_far", .body = &snaps_far},
    Case{.name = "long_stall", .body = &long_stall},
    Case{.name = "stale_ticks", .body = &stale_ticks},
    Case{.name = "hostile_numbers", .body = &hostile_numbers},
    Case{.name = "caps_actors", .body = &caps_actors},
    Case{.name = "dead_stays", .body = &dead_stays},
    Case{.name = "turns_the_short_way", .body = &turns_the_short_way},
    Case{.name = "pulled_is_not_cast_business", .body = &pulled_is_not_cast_business},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "cast_tests: mọi ca phải qua");
    return 0;
}
