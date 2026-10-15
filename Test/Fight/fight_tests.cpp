/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Fight/fight_tests.cpp
 *  PHÂN HỆ   : Fight / Fight Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm Combat: chiêu chờ máy chủ xác nhận, hồi chiêu, đánh tự động, bị từ
 *    chối, chết và hồi sinh, số bay.
 *  - Các ca là điều làm client sai mà nhìn vào không thấy: gửi chiêu dồn khi
 *    chưa được xác nhận, số thứ tự về 0, gửi lại dồn dập sau khi bị từ chối,
 *    đánh tự động kẹt mãi khi mục tiêu hỏng, chết rồi vẫn ra chiêu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/cast/note.hpp"
#include "client/fight/combat.hpp"
#include "core/check.hpp"
#include "core/clock.hpp"
#include "test.hpp"
#include "ui/panel/talk.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <optional>
#include <vector>

namespace game::test {
namespace {

namespace tk = ui::panel::talk;
using client::cast::Blow;
using client::cast::Died;
using client::cast::Struck;
using client::fight::Aim;
using client::fight::Combat;
using client::fight::Time;
using std::chrono::milliseconds;

constexpr std::uint32_t kTarget = 77;
constexpr std::uint32_t kSelf = 5;

[[nodiscard]] Time start() {
    return core::Clock::now();
}

[[nodiscard]] tk::Skills skills(std::initializer_list<std::uint16_t> ids, std::uint32_t cooldown_ms = 0) {
    tk::Skills list;
    for (const std::uint16_t id : ids) list.learned.push_back(tk::Learned{.skill = id, .level = 1, .cooldown_ms = cooldown_ms});
    return list;
}

[[nodiscard]] Struck damage(std::int32_t value) {
    Struck blow;
    blow.target = kTarget;
    blow.kind = Blow::kDamage;
    blow.value = value;
    return blow;
}

void cast_waits_for_confirmation(Context& context) {
    Combat combat;
    const Time now = start();
    const std::optional<tk::Cast> first = combat.cast(281, now, Aim{.target = kTarget});
    if (!first) {
        context.expect(false, "chiêu đầu phải gửi được");
        return;
    }
    context.expect(first->skill == 281 && first->target == kTarget && first->seq != 0, "chiêu đầu có số thứ tự khác 0");
    context.expect(!combat.cast(281, now + milliseconds{10}, Aim{.target = kTarget}), "chưa được xác nhận thì không gửi chiêu thứ hai");
    context.expect(!combat.confirm(static_cast<std::uint16_t>(first->seq + 1U)), "xác nhận sai số thứ tự không tính");
    context.expect(!combat.confirm(0), "số 0 là chiêu của người khác, không bao giờ là của mình");
    context.expect(combat.confirm(first->seq), "xác nhận đúng số thứ tự");
    context.expect(!combat.confirm(first->seq), "mỗi chiêu xác nhận một lần");
    context.expect(combat.cast(281, now + milliseconds{20}, Aim{.target = kTarget}).has_value(), "xác nhận xong thì gửi được chiêu kế");
}

void lost_cast_expires(Context& context) {
    Combat combat;
    const Time now = start();
    static_cast<void>(combat.cast(281, now, Aim{}));
    context.expect(!combat.cast(281, now + milliseconds{1000}, Aim{}), "trong hạn chờ không gửi lại");
    context.expect(combat.cast(281, now + client::fight::kCastWait + milliseconds{1}, Aim{}).has_value(),
        "quá hạn chờ thì chiêu mất, gửi chiêu kế được");
}

void sequence_skips_zero(Context& context) {
    Combat combat;
    Time now = start();
    bool is_zero_seen = false;
    for (int round = 0; round < 70000; ++round) {
        const std::optional<tk::Cast> sent = combat.cast(1, now, Aim{});
        if (!sent) {
            context.expect(false, "chiêu bị từ chối không có lý do");
            return;
        }
        is_zero_seen = is_zero_seen || sent->seq == 0;
        static_cast<void>(combat.confirm(sent->seq));
        now += milliseconds{1};
    }
    context.expect(!is_zero_seen, "số thứ tự vòng qua 65535 nhảy qua 0");
}

void cooldown_blocks_cast(Context& context) {
    Combat combat;
    const Time now = start();
    combat.learn(skills({281, 282}, 1000), now);
    context.expect(!combat.cast(281, now, Aim{}), "hồi chiêu còn lại thì không ra chiêu");
    context.expect(combat.cooldown_left(281, now) == milliseconds{1000}, "hồi chiêu còn lại đúng số máy chủ gửi");
    context.expect(combat.cast(281, now + milliseconds{1001}, Aim{}).has_value(), "hết hồi chiêu thì ra được");
    static_cast<void>(combat.confirm(1));
    combat.cool(tk::Cooldown{.skill = 282, .ms = 3000}, now + milliseconds{1001});
    context.expect(!combat.cast(282, now + milliseconds{2000}, Aim{}), "hồi chiêu mới sau khi ra chiêu có hiệu lực");
    context.expect(combat.cast(0, now + milliseconds{2000}, Aim{}).has_value(), "kỹ năng không có trong danh sách (đánh thường) thì để máy chủ quyết");
}

void learn_is_hostile_safe(Context& context) {
    Combat combat;
    const Time now = start();
    tk::Skills list = skills({9, 9, 8});
    for (std::uint16_t id = 100; id < 400; ++id) list.learned.push_back(tk::Learned{.skill = id});
    combat.learn(list, now);
    const std::vector<std::uint32_t> ids = combat.learned();
    context.expect(ids.size() == client::fight::kMaxKnown, "danh sách kỹ năng bị chặn ở trần");
    context.expect(ids.at(0) == 9 && ids.at(1) == 8, "id lặp chỉ giữ bản đầu");
    context.expect(combat.basic() == 9, "đòn tự động là kỹ năng học đầu tiên");
    combat.learn(tk::Skills{}, now);
    context.expect(combat.basic() == 0, "chưa học gì thì đánh thường");
}

void engaged_pursuit(Context& context) {
    Combat combat;
    const Time now = start();
    combat.learn(skills({281}), now);
    combat.engage(kTarget);
    const client::fight::Pursuit far = combat.pursue(now, 9.0F, false);
    context.expect(far.is_approaching && !far.order, "xa thì đi tới, chưa ra chiêu");
    const client::fight::Pursuit busy = combat.pursue(now, 1.0F, true);
    context.expect(!busy.is_approaching && !busy.order, "đang trong đòn khác thì chờ");
    const client::fight::Pursuit near = combat.pursue(now, 1.0F, false);
    context.expect(!near.is_approaching && near.order && near.order->skill == 281 && near.order->target == kTarget,
        "đủ gần thì ra chiêu đầu tiên của danh sách lên mục tiêu");
    const client::fight::Pursuit waiting = combat.pursue(now + milliseconds{5}, 1.0F, false);
    context.expect(!waiting.order, "chiêu trước chưa xác nhận thì không dồn thêm");
}

void gone_target_stops_chase(Context& context) {
    Combat combat;
    const Time now = start();
    combat.engage(kTarget);
    const client::fight::Pursuit gone = combat.pursue(now, std::nullopt, false);
    context.expect(!gone.order && !combat.target() && !combat.is_engaged(), "mục tiêu không còn trong cảnh: bỏ cả mục tiêu lẫn đánh tự động");
    combat.engage(kTarget);
    const client::fight::Pursuit broken = combat.pursue(now, std::numeric_limits<float>::quiet_NaN(), false);
    context.expect(!broken.order && !combat.target(), "khoảng cách NaN cũng bỏ mục tiêu");
    combat.engage(kTarget);
    combat.vanished(kTarget);
    context.expect(!combat.target() && !combat.is_engaged(), "mục tiêu rời vùng nhìn thì bỏ");
    combat.engage(kTarget);
    combat.vanished(kTarget + 1);
    context.expect(combat.target() == kTarget && combat.is_engaged(), "thực thể khác rời đi thì không đụng mục tiêu");
}

void declined_changes_course(Context& context) {
    Combat combat;
    const Time now = start();
    combat.learn(skills({281}), now);
    combat.engage(kTarget);
    const client::fight::Pursuit sent = combat.pursue(now, 2.4F, false);
    context.expect(sent.order.has_value(), "ca mở đầu: ra chiêu ở 2,4 m");
    combat.declined(tk::Decline::kOutOfRange, now + milliseconds{50});
    context.expect(!combat.pursue(now + milliseconds{100}, 2.4F, false).order, "vừa bị từ chối thì chưa gửi lại ngay");
    const client::fight::Pursuit closer = combat.pursue(now + client::fight::kRetry + milliseconds{60}, 2.4F, false);
    context.expect(closer.is_approaching && !closer.order, "quá tầm thì tầm tiếp cận của client ngắn lại, đi tới gần hơn");
    combat.declined(tk::Decline::kBadTarget, now + milliseconds{400});
    context.expect(!combat.is_engaged(), "mục tiêu sai: dừng đánh tự động");
    combat.engage(kTarget);
    combat.declined(tk::Decline::kCooldown, now + milliseconds{500});
    context.expect(combat.is_engaged(), "hồi chiêu chưa xong: vẫn đánh tự động, chờ gửi lại");
    combat.declined(tk::Decline::kGone, now + milliseconds{600});
    context.expect(!combat.target() && !combat.is_engaged(), "mục tiêu đã mất: bỏ mục tiêu");
}

void death_and_revival(Context& context) {
    Combat combat;
    const Time now = start();
    combat.vitals(tk::Vitals{.hp = 100, .hp_max = 100});
    combat.engage(kTarget);
    combat.vitals(tk::Vitals{.hp = 0, .hp_max = 100});
    context.expect(combat.is_dead() && !combat.is_engaged(), "hết sinh lực: chết và thôi đánh");
    context.expect(!combat.cast(281, now, Aim{}), "đã chết thì không ra chiêu");
    combat.engage(kTarget);
    context.expect(!combat.is_engaged(), "đã chết thì không đánh tự động");
    combat.slain(tk::Slain{.exp_lost = 5, .money_lost = 6});
    context.expect(combat.loss() && combat.loss()->exp_lost == 5, "ghi nhận phần đã mất để dựng bảng hồi sinh");
    combat.vitals(tk::Vitals{.hp = 0, .hp_max = 0});
    context.expect(combat.is_dead(), "trần bằng 0 là chưa có chỉ số, không làm đổi trạng thái");
    combat.vitals(tk::Vitals{.hp = 50, .hp_max = 100});
    context.expect(!combat.is_dead() && !combat.loss(), "sinh lực dương trở lại là đã hồi sinh");
    combat.died(Died{.id = kSelf}, kSelf);
    context.expect(combat.is_dead(), "EntityDied của chính mình là chết");
    combat.vitals(tk::Vitals{.hp = 50, .hp_max = 100});
    combat.engage(kTarget);
    combat.died(Died{.id = kTarget, .killer = kSelf}, kSelf);
    context.expect(!combat.target() && !combat.is_engaged(), "mục tiêu chết thì bỏ mục tiêu");
}

void floats_are_bounded(Context& context) {
    Combat combat;
    const Time now = start();
    for (int round = 0; round < 200; ++round) combat.strike(damage(round), now + milliseconds{round});
    context.expect(combat.floats().size() == client::fight::kMaxFloats, "số bay bị chặn ở trần");
    context.expect(combat.floats().front().value == 200 - static_cast<int>(client::fight::kMaxFloats), "bỏ số cũ nhất trước");
    combat.expire(now + milliseconds{500});
    context.expect(combat.floats().size() == client::fight::kMaxFloats, "chưa hết hạn thì giữ");
    combat.expire(now + client::fight::kFloatLife + milliseconds{300});
    context.expect(combat.floats().empty(), "hết hạn thì bỏ hết");
    combat.strike(damage(1), now);
    combat.leave();
    context.expect(combat.floats().empty() && !combat.target(), "rời cảnh xoá số bay và mục tiêu");
}

constexpr std::array kCases{
    Case{.name = "cast_waits_for_confirmation", .body = &cast_waits_for_confirmation},
    Case{.name = "lost_cast_expires", .body = &lost_cast_expires},
    Case{.name = "sequence_skips_zero", .body = &sequence_skips_zero},
    Case{.name = "cooldown_blocks_cast", .body = &cooldown_blocks_cast},
    Case{.name = "learn_is_hostile_safe", .body = &learn_is_hostile_safe},
    Case{.name = "engaged_pursuit", .body = &engaged_pursuit},
    Case{.name = "gone_target_stops_chase", .body = &gone_target_stops_chase},
    Case{.name = "declined_changes_course", .body = &declined_changes_course},
    Case{.name = "death_and_revival", .body = &death_and_revival},
    Case{.name = "floats_are_bounded", .body = &floats_are_bounded},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "fight_tests: mọi ca phải qua");
    return 0;
}
