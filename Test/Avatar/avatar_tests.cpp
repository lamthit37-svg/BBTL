// Kiểm chọn clip của người chơi theo ref (Obj_Character_Logic.cpp): đi là clip chạy lặp, đứng là
// clip đứng phát một lần rồi chọn lại, động tác nghỉ chỉ sau khoảng CalcIdleRandInterval, công
// thức khoảng giữ đúng toán tử của ref; và hướng mặt xoay dần: mới thấy thì lấy thẳng hướng
// logic, sau kTurnTime quay được 1 − 1/e phần góc, đi theo cung ngắn nhất qua ±π, không phụ thuộc
// tốc độ khung, và bỏ đối tượng đã rời vùng nhìn. Nhảy theo Jump và NotifyPhyEvent của ref (gait.hpp); đòn đánh
// phát một lần ở tốc độ của kế hoạch, khoá lệnh khác tới BreakTime (Start_MagicSend).
// Nguồn: TLBB Dev tests/client_app/gait_test.cpp và turning_test.cpp@e0d89a6. Khác gốc: khung test
// của dự án (Context::expect); core::Clock; id đối tượng là số nguyên không dấu.
#include "anim/asset.hpp"
#include "anim/rig.hpp"
#include "avatar/gait.hpp"
#include "avatar/locator.hpp"
#include "avatar/turning.hpp"
#include "core/check.hpp"
#include "core/clock.hpp"
#include "look/weapon.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <limits>
#include <numbers>
#include <optional>
#include <string>

namespace game::test {
namespace {

using namespace std::chrono_literals;
using avatar::ClipLengths;
using avatar::Gait;
using avatar::Playing;
using avatar::Stance;
using core::Clock;

constexpr float kHalfPi = std::numbers::pi_v<float> / 2.0F;

[[nodiscard]] Clock::time_point start() {
    return Clock::time_point{} + 1000s;
}

[[nodiscard]] Clock::time_point at(float seconds) {
    const auto offset = std::chrono::duration_cast<Clock::duration>(std::chrono::duration<float>{seconds});
    return start() + offset;
}

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) < 1e-3F;
}

[[nodiscard]] ClipLengths lengths_with_alt() {
    ClipLengths lengths;
    lengths.idle = 2.0F;
    lengths.idle_alt = 3.0F;
    lengths.run = 1.0F;
    return lengths;
}

// interval × (64 − rand() % 16) / 64 ép về số nguyên mili giây như (UINT) của ref.
void interval_formula(Context& context) {
    context.expect(avatar::idle_interval(0, avatar::kIdleInterval) == 10000ms, "rand % 16 = 0");
    context.expect(avatar::idle_interval(15, avatar::kIdleInterval) == 7656ms, "7 656,25 còn 7 656");
    context.expect(avatar::idle_interval(16, avatar::kIdleInterval) == 10000ms, "dư theo 16");
    context.expect(avatar::idle_interval(37, avatar::kIdleInterval) == 9218ms, "10 000 × 59 / 64");
    context.expect(avatar::idle_interval(15, 60000ms) == 45937ms, "mẫu 60 giây: 45 937,5");
    context.expect(avatar::idle_interval(3, 0ms) == 0ms, "khoảng 0 của mẫu");
}

void standing_plays_idle_once(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_alt();
    const Playing first = gait.update(at(0.0F), false, lengths);
    context.expect(first.stance == Stance::kIdle && near_value(first.time, 0.0F), "đứng: clip đứng");
    const Playing middle = gait.update(at(0.5F), false, lengths);
    context.expect(middle.stance == Stance::kIdle && near_value(middle.time, 0.5F), "giữa clip");
    const Playing again = gait.update(at(2.25F), false, lengths);
    const bool restarted = again.stance == Stance::kIdle && near_value(again.time, 0.0F);
    context.expect(restarted, "hết clip đứng mà chưa tới khoảng nghỉ: phát lại từ đầu");
}

void moving_runs_looped(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_alt();
    static_cast<void>(gait.update(at(0.0F), false, lengths));
    const Playing begin = gait.update(at(1.0F), true, lengths);
    context.expect(begin.stance == Stance::kRun && near_value(begin.time, 0.0F), "bắt đầu chạy");
    const Playing looped = gait.update(at(2.5F), true, lengths);
    context.expect(looped.stance == Stance::kRun && near_value(looped.time, 0.5F), "lặp 1 giây");
    const Playing stopped = gait.update(at(3.0F), false, lengths);
    context.expect(stopped.stance == Stance::kIdle && near_value(stopped.time, 0.0F), "dừng");
}

// Giây đầu tiên thấy động tác nghỉ EX0 khi đứng yên 60 giây với hạt giống seed.
// Giây của bước step nếu lúc đó đang phát động tác nghỉ EX0.
[[nodiscard]] std::optional<float> alt_at(Gait& gait, const ClipLengths& lengths, int step) {
    const float seconds = static_cast<float>(step) * 0.1F;
    const Playing playing = gait.update(at(seconds), false, lengths);
    if (playing.stance != Stance::kIdleAlt) return std::nullopt;
    return seconds;
}

[[nodiscard]] std::optional<float> first_alt(std::uint32_t seed) {
    Gait gait{seed, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_alt();
    std::optional<float> found;
    for (int step = 0; step <= 600 && !found; ++step) {
        found = alt_at(gait, lengths, step);
    }
    return found;
}

// ShowModel: bài múa phát ngay. Môn không fidget thì hết bài đứng yên, không múa lại.
void demo_once(Context& context) {
    avatar::Gait gait{1, avatar::kIdleInterval};
    gait.set_fidget(false);
    gait.cue(avatar::Stance::kIdleAlt);
    const ClipLengths lengths = lengths_with_alt();
    const Playing opened = gait.update(at(0.0F), false, lengths);
    const bool started = opened.stance == Stance::kIdleAlt && opened.time == 0.0F;
    context.expect(started, "hiện mẫu thì múa ngay");
    const Playing rested = gait.update(at(30.0F), false, lengths);
    context.expect(rested.stance == Stance::kIdle, "hết bài thì đứng, không múa lại");
}

void idle_alt_after_interval(Context& context) {
    int seen = 0;
    bool too_early = false;
    for (std::uint32_t seed = 1; seed <= 64; ++seed) {
        const std::optional<float> alt = first_alt(seed);
        seen += alt.has_value() ? 1 : 0;
        too_early = too_early || (alt && *alt < 7.656F);
    }
    context.expect(!too_early, "động tác nghỉ không tới trước 7,656 giây đứng yên");
    context.expect(seen > 0, "đứng đủ lâu thì có động tác nghỉ");
}

// Động tác nghỉ đã thấy trong 60 giây đứng yên, và lúc sớm nhất.
struct Rests {
    bool has_first = false;
    bool has_second = false;
    std::optional<float> earliest;
};

void note(Rests& rests, Stance stance, float seconds) {
    const bool first = stance == Stance::kIdleAlt;
    const bool second = stance == Stance::kIdleAlt2;
    const bool is_new = (first || second) && !rests.earliest;
    rests.has_first = rests.has_first || first;
    rests.has_second = rests.has_second || second;
    if (is_new) rests.earliest = seconds;
}

[[nodiscard]] Rests rests_of(std::uint32_t seed, const ClipLengths& lengths, std::chrono::milliseconds interval) {
    Gait gait{seed, interval};
    Rests rests;
    for (int step = 0; step <= 600; ++step) {
        const float seconds = static_cast<float>(step) * 0.1F;
        note(rests, gait.update(at(seconds), false, lengths).stance, seconds);
    }
    return rests;
}

[[nodiscard]] bool is_before(const Rests& rests, float seconds) {
    return rests.earliest && *rests.earliest < seconds;
}

// FreshAnimation: rand() % 2 + N_IDLE_EX0, nên cả hai động tác nghỉ đều ra; mẫu thiếu clip EX1 thì
// phát clip đứng; khoảng là của đối tượng, 60 giây thì không có động tác nghỉ trước 45,9 giây.
void both_rests(Context& context) {
    ClipLengths full = lengths_with_alt();
    full.idle_alt2 = 2.5F;
    const ClipLengths lone = lengths_with_alt();
    bool has_first = false;
    bool has_second = false;
    bool has_lone_second = false;
    bool is_slow_early = false;
    for (std::uint32_t seed = 1; seed <= 64; ++seed) {
        const Rests rests = rests_of(seed, full, avatar::kIdleInterval);
        const Rests lonely = rests_of(seed, lone, avatar::kIdleInterval);
        const Rests slow = rests_of(seed, full, 60000ms);
        has_first = has_first || rests.has_first;
        has_second = has_second || rests.has_second;
        has_lone_second = has_lone_second || lonely.has_second;
        is_slow_early = is_slow_early || is_before(slow, 45.937F);
    }
    context.expect(has_first && has_second, "rand() % 2 chọn cả EX0 lẫn EX1");
    context.expect(!has_lone_second, "không có clip EX1 thì phát clip đứng");
    context.expect(!is_slow_early, "khoảng 60 giây của mẫu: không nghỉ trước 45,9 giây");
}

void first_sight(Context& context) {
    avatar::Turning turning;
    context.expect(near_value(turning.face(1, 1.25F, start()), 1.25F), "mới thấy lấy thẳng hướng");
    context.expect(turning.size() == 1, "nhớ một đối tượng");
}

void eases_in(Context& context) {
    avatar::Turning turning;
    static_cast<void>(turning.face(1, 0.0F, start()));
    const float angle = turning.face(1, kHalfPi, start() + 35ms);
    context.expect(near_value(angle, kHalfPi * (1.0F - std::exp(-1.0F))), "sau 35 ms 1 - 1/e góc");
    context.expect(near_value(turning.face(1, kHalfPi, start() + 1s), kHalfPi), "về đúng đích");
}

// Từ 3,0 tới -3,0: cung ngắn qua π dài 0,28 radian, không phải cung dài 6 radian qua 0.
void shortest_arc(Context& context) {
    avatar::Turning turning;
    static_cast<void>(turning.face(1, 3.0F, start()));
    const float angle = turning.face(1, -3.0F, start() + 20ms);
    context.expect(std::fabs(angle) > 3.0F, "đi qua π, không quay về phía 0");
    context.expect(near_value(turning.face(1, -3.0F, start() + 2s), -3.0F), "tới đích bên kia π");
}

void frame_rate(Context& context) {
    avatar::Turning coarse;
    avatar::Turning fine;
    static_cast<void>(coarse.face(1, 0.0F, start()));
    static_cast<void>(fine.face(1, 0.0F, start()));
    const float one = coarse.face(1, 1.0F, start() + 40ms);
    static_cast<void>(fine.face(1, 1.0F, start() + 20ms));
    const float two = fine.face(1, 1.0F, start() + 40ms);
    context.expect(near_value(one, two), "hai khung 20 ms bằng một khung 40 ms");
}

void drops_unseen(Context& context) {
    avatar::Turning turning;
    static_cast<void>(turning.face(1, 0.0F, start()));
    static_cast<void>(turning.face(2, 0.0F, start()));
    turning.drop_unseen();
    context.expect(turning.size() == 2, "cả hai vừa được vẽ thì giữ");
    static_cast<void>(turning.face(1, 0.0F, start() + 16ms));
    turning.drop_unseen();
    context.expect(turning.size() == 1, "đối tượng không còn được vẽ thì bỏ");
    context.expect(near_value(turning.face(2, 2.0F, start() + 32ms), 2.0F), "quay lại như mới thấy");
}

[[nodiscard]] ClipLengths lengths_with_jump() {
    ClipLengths lengths = lengths_with_alt();
    lengths.jump_stand = 0.8F;
    lengths.jump_run = 0.6F;
    return lengths;
}

// Jump của ref: clip nhảy phát một lần từ đầu; hết clip mà chưa chạm đất thì FreshAnimation theo logic
// (đang chạy thì chạy lại từ đầu); chạm đất thì FreshAnimation một lần nữa.
void jump_while_running(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_jump();
    static_cast<void>(gait.update(at(0.0F), true, lengths));
    gait.jump(at(0.5F), Stance::kJumpRun, lengths);
    const Playing flying = gait.update(at(0.7F), true, lengths);
    context.expect(flying.stance == Stance::kJumpRun && near_value(flying.time, 0.2F), "đang nhảy: clip nhảy");
    const Playing ended = gait.update(at(1.2F), true, lengths);
    context.expect(ended.stance == Stance::kRun && near_value(ended.time, 0.0F), "hết clip nhảy: chạy từ đầu");
    gait.land(at(1.5F), lengths);
    const Playing landed = gait.update(at(1.5F), true, lengths);
    context.expect(landed.stance == Stance::kRun && near_value(landed.time, 0.0F), "chạm đất: chạy lại từ đầu");
    context.expect(!gait.is_jumping(), "chạm đất thì hết nhảy");
}

// Start_Idle và Start_Move lúc cờ nhảy bật giữ clip nhảy; chạm đất lúc đã dừng thì về clip đứng.
void jump_keeps_clip_until_land(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_jump();
    static_cast<void>(gait.update(at(0.0F), true, lengths));
    gait.jump(at(0.1F), Stance::kJumpStand, lengths);
    const Playing stopped = gait.update(at(0.3F), false, lengths);
    context.expect(stopped.stance == Stance::kJumpStand && near_value(stopped.time, 0.2F), "dừng giữa nhảy: giữ clip");
    const Playing moved = gait.update(at(0.4F), true, lengths);
    context.expect(moved.stance == Stance::kJumpStand, "đi tiếp giữa nhảy: giữ clip");
    static_cast<void>(gait.update(at(0.5F), false, lengths));
    gait.land(at(0.6F), lengths);
    const Playing landed = gait.update(at(0.6F), false, lengths);
    context.expect(landed.stance == Stance::kIdle && near_value(landed.time, 0.0F), "chạm đất lúc đứng: clip đứng");
}

// Hành động không có clip: ChangeAction của gốc bỏ qua, clip đang phát giữ nguyên, cờ nhảy vẫn bật.
void jump_without_clip(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_alt();
    static_cast<void>(gait.update(at(0.0F), true, lengths));
    gait.jump(at(0.25F), Stance::kJumpRun, lengths);
    const Playing playing = gait.update(at(0.5F), true, lengths);
    context.expect(playing.stance == Stance::kRun && near_value(playing.time, 0.5F), "không clip: chạy tiếp");
    context.expect(gait.is_jumping(), "cờ nhảy vẫn bật");
    gait.jump(at(0.5F), Stance::kIdle, lengths);
    gait.land(at(0.6F), lengths);
    gait.land(at(0.7F), lengths);
    const Playing landed = gait.update(at(0.7F), true, lengths);
    context.expect(landed.stance == Stance::kRun && near_value(landed.time, 0.1F), "chạm đất hai lần chỉ tính một");
}

// Đòn đánh (Start_MagicSend): clip phát một lần từ đầu ở tốc độ plan.rate, hết clip thì FreshAnimation về đứng; lệnh khác
// chỉ ngắt được từ mốc BreakTime.
[[nodiscard]] avatar::StrikePlan plan_of(float length, float rate, std::optional<float> break_at) {
    return avatar::StrikePlan{.index = 3, .length = length, .rate = rate, .break_at = break_at};
}

void strike_plays_once(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_alt();
    static_cast<void>(gait.update(at(0.0F), false, lengths));
    gait.strike(at(0.5F), plan_of(1.0F, 2.0F, std::nullopt));
    const Playing mid = gait.update(at(0.75F), false, lengths);
    context.expect(mid.stance == Stance::kStrike && mid.strike == 3, "đang đánh: clip đòn, đúng chỉ số");
    context.expect(near_value(mid.time, 0.5F), "tốc độ 2: 0,25 s thật là 0,5 s trong clip");
    const Playing ended = gait.update(at(1.1F), false, lengths);
    context.expect(ended.stance == Stance::kIdle && near_value(ended.time, 0.0F), "hết clip: về đứng từ đầu");
    context.expect(!gait.is_locked(at(1.1F)), "hết clip hết khoá");
}

void strike_locks_until_break(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_alt();
    static_cast<void>(gait.update(at(0.0F), false, lengths));
    context.expect(!gait.is_locked(at(0.0F)), "chưa đánh thì không khoá");
    gait.strike(at(1.0F), plan_of(1.0F, 1.0F, 0.5F));
    context.expect(gait.is_locked(at(1.4F)), "trước BreakTime: khoá");
    context.expect(!gait.is_locked(at(1.6F)), "sau BreakTime: nhận lệnh mới");
    Gait unbroken{1, avatar::kIdleInterval};
    static_cast<void>(unbroken.update(at(0.0F), false, lengths));
    unbroken.strike(at(1.0F), plan_of(1.0F, 1.0F, std::nullopt));
    context.expect(unbroken.is_locked(at(1.9F)), "không có mốc: khoá tới hết clip");
    context.expect(!unbroken.is_locked(at(2.1F)), "hết clip thì mở");
}

void strike_refused(Context& context) {
    const ClipLengths lengths = lengths_with_jump();
    Gait flying{1, avatar::kIdleInterval};
    static_cast<void>(flying.update(at(0.0F), false, lengths));
    flying.jump(at(0.1F), Stance::kJumpStand, lengths);
    flying.strike(at(0.2F), plan_of(1.0F, 1.0F, std::nullopt));
    context.expect(flying.update(at(0.3F), false, lengths).stance == Stance::kJumpStand, "đang nhảy: không ra đòn");
    Gait empty{1, avatar::kIdleInterval};
    static_cast<void>(empty.update(at(0.0F), false, lengths));
    empty.strike(at(0.1F), plan_of(0.0F, 1.0F, std::nullopt));
    context.expect(empty.update(at(0.2F), false, lengths).stance == Stance::kIdle, "clip dài 0: không ra đòn");
    empty.strike(at(0.1F), plan_of(1.0F, 0.0F, std::nullopt));
    context.expect(empty.update(at(0.2F), false, lengths).stance == Stance::kIdle, "tốc độ 0: không ra đòn");
    empty.strike(at(0.1F), plan_of(1.0F, std::numeric_limits<float>::quiet_NaN(), std::nullopt));
    context.expect(!empty.is_locked(at(0.2F)), "tốc độ NaN: không ra đòn");
}

// Đang đánh mà người chơi đi (gốc chờ BreakTime ở lớp lệnh; ở đây lớp trên đã chặn) thì clip chạy thay clip đòn.
void strike_yields_to_run(Context& context) {
    Gait gait{1, avatar::kIdleInterval};
    const ClipLengths lengths = lengths_with_alt();
    static_cast<void>(gait.update(at(0.0F), false, lengths));
    gait.strike(at(0.1F), plan_of(1.0F, 1.0F, 0.2F));
    const Playing moved = gait.update(at(0.5F), true, lengths);
    context.expect(moved.stance == Stance::kRun, "đi giữa đòn: clip chạy");
}

// Locator

[[nodiscard]] anim::Transform bone_at(float across, float angle) {
    const ogre::Vec3 upward{.x = 0.0F, .y = 0.0F, .z = 1.0F};
    return anim::Transform{.position = ogre::Vec3{.x = across, .y = 0.0F, .z = 0.0F},
        .orientation = ogre::quat_from_angle_axis(angle, upward)};
}

[[nodiscard]] look::LocatorRow row_of(const std::string& bone, bool is_translate_first) {
    look::LocatorRow row;
    row.object = "女主角.obj";
    row.name = "p";
    row.bone = bone;
    row.offset = {1.0F, 0.0F, 0.0F};
    row.axis = {0.0F, 0.0F, 1.0F};
    row.angle = kHalfPi;
    row.is_translate_first = is_translate_first;
    return row;
}

[[nodiscard]] anim::SourceSkeleton skeleton_of(const std::string& name) {
    anim::SourceSkeleton skeleton;
    skeleton.bones.push_back(anim::Bone{.name = "gốc", .handle = 0, .position = {}, .orientation = {}, .scale = {.x = 1.0F, .y = 1.0F, .z = 1.0F}});
    skeleton.bones.push_back(anim::Bone{.name = name, .handle = 1, .position = {}, .orientation = {}, .scale = {.x = 1.0F, .y = 1.0F, .z = 1.0F}});
    return skeleton;
}

// _updateLocatorPos: translate_first dịch theo hướng của xương (p = P + Q·offset), không thì dịch theo hướng đã
// quay thêm rotation (p = P + (Q ⊗ R)·offset); hướng luôn là Q ⊗ R.
void locator_orders(Context& context) {
    const anim::SourceSkeleton skeleton = skeleton_of("Bone08");
    const std::array<anim::Transform, 2> bones{anim::Transform{}, bone_at(10.0F, kHalfPi)};
    const avatar::Locator first = avatar::make_locator(row_of("Bone08", true), skeleton);
    const avatar::Locator after = avatar::make_locator(row_of("Bone08", false), skeleton);
    context.expect(first.bone == 1 && after.bone == 1, "tên xương thành handle");
    const anim::Transform near_first = avatar::locator_pose(first, bones);
    context.expect(near_value(near_first.position.x, 10.0F) && near_value(near_first.position.y, 1.0F), "translate_first");
    const anim::Transform near_after = avatar::locator_pose(after, bones);
    context.expect(near_value(near_after.position.x, 9.0F) && near_value(near_after.position.y, 0.0F), "dịch theo hướng đã quay");
    const bool same_turn = near_value(near_first.orientation.z, near_after.orientation.z) &&
        near_value(near_first.orientation.w, near_after.orientation.w) && near_value(near_first.orientation.z, 1.0F);
    context.expect(same_turn, "hướng là Q nhân R, hai thứ tự như nhau");
}

// Không xương (tên rỗng, tên không có, handle ngoài tư thế) thì nút giữ trạng thái lúc tạo; trục không chuẩn
// hoá thì quaternion không đơn vị, đúng Quaternion::FromAngleAxis.
void locator_without_bone(Context& context) {
    const anim::SourceSkeleton skeleton = skeleton_of("Bone08");
    const std::array<anim::Transform, 2> bones{anim::Transform{}, bone_at(10.0F, kHalfPi)};
    look::LocatorRow row = row_of("", true);
    row.axis = {0.0F, 0.0F, 2.0F};
    const avatar::Locator plain = avatar::make_locator(row, skeleton);
    context.expect(!plain.bone.has_value(), "tên rỗng không theo xương");
    const anim::Transform pose = avatar::locator_pose(plain, bones);
    context.expect(near_value(pose.position.x, 1.0F) && near_value(pose.position.y, 0.0F), "vị trí là offset");
    context.expect(near_value(pose.orientation.z, 2.0F * std::sin(kHalfPi / 2.0F)), "trục 2 cho quaternion không đơn vị");
    const avatar::Locator lost = avatar::make_locator(row_of("Bone99", true), skeleton);
    context.expect(!lost.bone.has_value(), "xương không có thì bỏ qua như ref");
    avatar::Locator far = avatar::make_locator(row_of("Bone08", true), skeleton);
    far.bone = 7;
    const anim::Transform outside = avatar::locator_pose(far, bones);
    context.expect(near_value(outside.position.x, 1.0F), "handle ngoài tư thế giữ trạng thái lúc tạo");
}

// Mẫu con trong khe mang scale riêng của mẫu, vị trí và hướng của nút locator.
void slot_carries_scale(Context& context) {
    const anim::SourceSkeleton skeleton = skeleton_of("Bone08");
    const std::array<anim::Transform, 2> bones{anim::Transform{}, bone_at(10.0F, kHalfPi)};
    const avatar::Locator locator = avatar::make_locator(row_of("Bone08", true), skeleton);
    const ogre::Vec3 scale{.x = 0.9F, .y = 0.8F, .z = 0.9F};
    const anim::Transform slot = avatar::slot_pose(locator, bones, scale);
    context.expect(near_value(slot.position.x, 10.0F) && near_value(slot.position.y, 1.0F), "vị trí của nút locator");
    context.expect(slot.scale == scale, "scale của mẫu con");
}

constexpr std::array kCases{
    Case{.name = "interval_formula", .body = &interval_formula},
    Case{.name = "standing_plays_idle_once", .body = &standing_plays_idle_once},
    Case{.name = "moving_runs_looped", .body = &moving_runs_looped},
    Case{.name = "idle_alt_after_interval", .body = &idle_alt_after_interval},
    Case{.name = "demo_once", .body = &demo_once},
    Case{.name = "jump_while_running", .body = &jump_while_running},
    Case{.name = "jump_keeps_clip_until_land", .body = &jump_keeps_clip_until_land},
    Case{.name = "jump_without_clip", .body = &jump_without_clip},
    Case{.name = "strike_plays_once", .body = &strike_plays_once},
    Case{.name = "strike_locks_until_break", .body = &strike_locks_until_break},
    Case{.name = "strike_refused", .body = &strike_refused},
    Case{.name = "strike_yields_to_run", .body = &strike_yields_to_run},
    Case{.name = "both_rests", .body = &both_rests},
    Case{.name = "first_sight", .body = &first_sight},
    Case{.name = "eases_in", .body = &eases_in},
    Case{.name = "shortest_arc", .body = &shortest_arc},
    Case{.name = "frame_rate", .body = &frame_rate},
    Case{.name = "drops_unseen", .body = &drops_unseen},
    Case{.name = "locator_orders", .body = &locator_orders},
    Case{.name = "locator_without_bone", .body = &locator_without_bone},
    Case{.name = "slot_carries_scale", .body = &slot_carries_scale},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "avatar_tests: mọi ca phải qua");
    return 0;
}
