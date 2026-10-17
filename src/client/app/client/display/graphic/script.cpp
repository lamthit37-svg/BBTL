/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/script.cpp
 *  PHÂN HỆ   : Display / Graphic / Script
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Chạy kịch bản E2E (--script) trên luồng vẽ: mỗi khung một bước, đầu
 *    draw_world, trước khi khung lấy input. Bấm và gõ đi vào hàng input của
 *    Display như SDL (qua absorb), không qua chuột hay bàn phím hệ điều hành;
 *    đi, nói chuyện, nhặt, ra chiêu gọi đúng hàm mà chuột và phím gọi.
 *  - Công cụ thử của dự án, client gốc không có. Mỗi bước in một dòng SCRIPT
 *    (TSV) cho TOOLS/run/e2e_client.py.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Cách hỏng đã tính trước:
//   cửa sổ / NPC / vật rơi chưa có    -> chờ kFindSeconds rồi bước hỏng (có thể chúng sắp tới).
//   bước quá hạn                      -> bước hỏng, kịch bản chạy tiếp; mã thoát khác 0 ở cuối.
//   đăng nhập tự động bị từ chối      -> wait play hỏng ngay, không chờ hết hạn.
//   máy chủ kéo người chơi về lúc đi  -> bước walk vẫn đạt, ghi số lần kéo.

#include "client/display/graphic/state.hpp"

#include "client/cast/cast.hpp"
#include "client/display/display.hpp"
#include "client/display/graphic/prelude.hpp"
#include "client/display/script.hpp"
#include "control/input.hpp"
#include "core/clock.hpp"
#include "core/ground_point.hpp"
#include "core/number.hpp"
#include "core/text.hpp"
#include "look/creature.hpp"
#include "nav/route.hpp"
#include "ui/hud.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/talk.hpp"

#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <format>
#include <limits>
#include <mutex>
#include <optional>
#include <print>
#include <ratio>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::client {
namespace {

// Giây chờ một cửa sổ, NPC hay vật rơi hiện ra trước khi bước hỏng.
constexpr double kFindSeconds = 5.0;
constexpr double kShotSeconds = 10.0;
constexpr double kWalkSeconds = 40.0;
constexpr double kTalkSeconds = 20.0;
// Giây chờ máy chủ đáp một việc đã gửi (chọn dòng, ra chiêu) trước khi bước hỏng.
constexpr double kReplySeconds = 5.0;
// Mét của game: tới đích khi còn cách chừng này (sai số của walk, in cả vào dòng SCRIPT).
constexpr float kArriveMeters = 1.5F;
// Giây nhân vật phải đứng yên và không bị kéo thêm thì chỗ đứng coi như máy chủ đã chốt: dài hơn
// nhịp Move và một lượt hồi đáp của gate.
constexpr double kSettleSeconds = 1.5;

namespace tk = ui::panel::talk;

std::string_view refusal_name(tk::Refusal why) noexcept {
    switch (why) {
    case tk::Refusal::kNoSession: return "NoSession";
    case tk::Refusal::kStaleSession: return "StaleSession";
    case tk::Refusal::kBadOption: return "BadOption";
    case tk::Refusal::kTooFar: return "TooFar";
    case tk::Refusal::kNoSuchEntity: return "NoSuchEntity";
    case tk::Refusal::kQuestUnavailable: return "QuestUnavailable";
    case tk::Refusal::kQuestLogFull: return "QuestLogFull";
    case tk::Refusal::kQuestState: return "QuestState";
    case tk::Refusal::kBagFull: return "BagFull";
    case tk::Refusal::kNotEnoughMoney: return "NotEnoughMoney";
    case tk::Refusal::kNotEnoughItems: return "NotEnoughItems";
    case tk::Refusal::kBadChoice: return "BadChoice";
    case tk::Refusal::kCannotAbandon: return "CannotAbandon";
    case tk::Refusal::kRateLimited: return "RateLimited";
    case tk::Refusal::kOther: return "Other";
    }
    return "?";
}

// Tin hộp thoại hay sổ nhiệm vụ: máy chủ đã đáp một việc của hộp thoại.
bool is_dialog_reply(const tk::Hear& note) noexcept {
    const bool is_dialog = std::holds_alternative<tk::Dialog>(note);
    const bool is_closed = std::holds_alternative<tk::Closed>(note);
    const bool is_book = std::holds_alternative<tk::Book>(note);
    const bool is_notice = std::holds_alternative<tk::Notice>(note);
    return is_dialog || is_closed || is_book || is_notice;
}

std::string_view decline_name(tk::Decline why) noexcept {
    switch (why) {
    case tk::Decline::kNotLearned: return "NotLearned";
    case tk::Decline::kCooldown: return "Cooldown";
    case tk::Decline::kNotEnoughMana: return "NotEnoughMana";
    case tk::Decline::kNotEnoughRage: return "NotEnoughRage";
    case tk::Decline::kBadTarget: return "BadTarget";
    case tk::Decline::kOutOfRange: return "OutOfRange";
    case tk::Decline::kCannotAttack: return "CannotAttack";
    case tk::Decline::kGone: return "Gone";
    case tk::Decline::kDead: return "Dead";
    case tk::Decline::kNotDead: return "NotDead";
    case tk::Decline::kNotYours: return "NotYours";
    case tk::Decline::kBusy: return "Busy";
    case tk::Decline::kOther: return "Other";
    }
    return "?";
}

[[nodiscard]] StepOutcome still_going() {
    return {};
}

[[nodiscard]] StepOutcome step_ok(const std::string& note) {
    return {.flow = StepFlow::kDone, .note = note};
}

[[nodiscard]] StepOutcome step_fail(const std::string& note) {
    return {.flow = StepFlow::kFailed, .note = note};
}

[[nodiscard]] float resolved(const Coord& coord, float base) noexcept {
    return coord.is_relative ? base + coord.value : coord.value;
}

[[nodiscard]] std::string coord_text(const Coord& coord) {
    if (coord.is_relative) return std::format("{:+g}", coord.value);
    return std::format("{:g}", coord.value);
}

// Chữ gõ có ký tự điều khiển (Enter, Tab) thì in dạng đọc được, để dòng SCRIPT không vỡ cột.
[[nodiscard]] std::string printable(std::string text) {
    for (char& letter : text) {
        if (static_cast<unsigned char>(letter) < 0x20U) letter = '?';
    }
    return text;
}

// Đối số của bước, như trong tệp kịch bản, cho dòng SCRIPT.
[[nodiscard]] std::string argument_of(const Step& step) {
    switch (step.kind) {
    case StepKind::kWait: return std::format("{:g}", step.amount);
    case StepKind::kWaitSeconds: return std::format("{:g}s", step.amount);
    case StepKind::kWaitPlay: return std::format("play {:g}", step.amount);
    case StepKind::kChoose:
    case StepKind::kCast: return std::format("{:g}", step.amount);
    case StepKind::kWalk: return std::format("{},{}", coord_text(step.x), coord_text(step.z));
    case StepKind::kType: return printable(step.text);
    case StepKind::kShot:
    case StepKind::kEvent:
    case StepKind::kClick:
    case StepKind::kTalk: return step.text;
    case StepKind::kPick:
    case StepKind::kQuit: return {};
    }
    return {};
}

[[nodiscard]] control::InputEvent typed_event(char32_t code) noexcept {
    control::InputEvent event;
    event.kind = control::InputKind::kText;
    event.text = code;
    return event;
}

[[nodiscard]] control::InputEvent button_event(control::InputKind kind, float across,
    float down) noexcept {
    control::InputEvent event;
    event.kind = kind;
    event.button = control::MouseButton::kLeft;
    event.x = across;
    event.y = down;
    return event;
}

// Tên hiện của thực thể: tên máy chủ gửi, không có thì tên mẫu trong bảng quái.
[[nodiscard]] std::string_view label_of(const cast::Actor& actor,
    const look::CreatureTables* tables) {
    if (!actor.name.empty()) return actor.name;
    if (tables == nullptr) return {};
    const look::CreatureTemplate* row = tables->find_template(actor.template_id);
    if (row == nullptr) return {};
    return row->name;
}

} // namespace

void Display::State::arm_script(const DisplayDesc& desc) {
    if (!desc.script) return;
    ScriptRun run;
    run.steps = *desc.script;
    run.shot_dir = desc.shot_dir;
    std::error_code error;
    if (!run.shot_dir.empty()) std::filesystem::create_directories(run.shot_dir, error);
    if (error) std::println(stderr, "Kịch bản: không tạo được thư mục ảnh: {}", error.message());
    script = std::move(run);
    std::println("Kịch bản: {} bước", script->steps.size());
    if (script->steps.empty()) end_script();
}

void Display::State::push_input(std::span<const control::InputEvent> events) {
    const std::scoped_lock<std::mutex> locked(steer_guard);
    queued.insert(queued.end(), events.begin(), events.end());
}

// Một bước mỗi khung: bước mới thì begin_step, bước đang chờ thì poll_step.
void Display::State::tick_script() {
    if (!script || script_over.load(std::memory_order_relaxed)) return;
    ScriptRun& run = *script;
    if (run.next >= run.steps.size()) return;
    const Step& step = run.steps.at(run.next);
    const StepOutcome result = run.is_begun ? poll_step(step) : begin_step(step);
    run.is_begun = true;
    if (result.flow == StepFlow::kPending) return;
    report_script_step(step, result);
    advance_script();
}

void Display::State::report_script_step(const Step& step, const StepOutcome& result) {
    const bool is_ok = result.flow == StepFlow::kDone;
    if (!is_ok) script_faults.fetch_add(1, std::memory_order_relaxed);
    const std::chrono::duration<double, std::milli> spent = core::Clock::now() - script->began;
    const std::string argument = argument_of(step);
    const char* verdict = is_ok ? "ok" : "fail";
    const std::size_t number = script->next + 1;
    const std::string_view verb = name_of(step.kind);
    const std::string lead = std::format("SCRIPT\t{}\t{}\t{}\t{}", number, verb, argument, verdict);
    const std::string tail = std::format("{:.0f}\t{}", spent.count(), result.note);
    std::println("{}\t{}", lead, tail);
    static_cast<void>(std::fflush(stdout));
}

void Display::State::advance_script() {
    ScriptRun& run = *script;
    ++run.next;
    run.is_begun = false;
    const bool is_last = run.next >= run.steps.size();
    if (is_last || run.is_quitting) end_script();
}

// total là số bước đã chạy: quit giữa chừng thì ít hơn số dòng của tệp.
void Display::State::end_script() {
    const std::size_t total = script->next;
    const std::uint32_t faults = script_faults.load(std::memory_order_relaxed);
    std::println("SCRIPT\tend\t{}\t{}", total, faults);
    static_cast<void>(std::fflush(stdout));
    script_over.store(true, std::memory_order_relaxed);
}

bool Display::State::is_script_late(double seconds) const {
    const std::chrono::duration<double> spent = core::Clock::now() - script->began;
    return spent.count() > seconds;
}

// Đối tượng của bước chưa có: chờ thêm, quá kFindSeconds thì hỏng.
StepOutcome Display::State::wait_for(std::string_view what) const {
    if (!is_script_late(kFindSeconds)) return still_going();
    const std::string note = std::format("không thấy {}", what);
    return step_fail(note);
}

StepOutcome Display::State::begin_step(const Step& step) {
    script->began = core::Clock::now();
    script->waited = 0;
    script->subject = 0;
    switch (step.kind) {
    case StepKind::kShot: return step_shot(step);
    case StepKind::kEvent: return step_event(step);
    case StepKind::kType: return step_type(step);
    case StepKind::kWalk: return step_walk(step);
    case StepKind::kChoose: return step_choose(step);
    case StepKind::kCast: return step_cast(step);
    case StepKind::kQuit: return step_quit();
    case StepKind::kWait:
    case StepKind::kWaitSeconds:
    case StepKind::kWaitPlay:
    case StepKind::kClick:
    case StepKind::kTalk:
    case StepKind::kPick: return poll_step(step);
    }
    return step_fail("bước lạ");
}

StepOutcome Display::State::poll_step(const Step& step) {
    switch (step.kind) {
    case StepKind::kWait: return step_wait(step);
    case StepKind::kWaitSeconds: return step_sleep(step);
    case StepKind::kWaitPlay: return step_wait_play(step);
    case StepKind::kShot: return poll_shot(step);
    case StepKind::kClick: return step_click(step);
    case StepKind::kWalk: return poll_walk();
    case StepKind::kTalk: return step_talk(step);
    case StepKind::kChoose: return poll_reply();
    case StepKind::kCast: return poll_cast();
    case StepKind::kPick: return step_pick();
    case StepKind::kEvent:
    case StepKind::kType:
    case StepKind::kQuit: return step_fail("bước này không có pha chờ");
    }
    return step_fail("bước lạ");
}

StepOutcome Display::State::step_wait(const Step& step) {
    ++script->waited;
    if (static_cast<double>(script->waited) < step.amount) return still_going();
    const std::string note = std::format("{} khung", script->waited);
    return step_ok(note);
}

StepOutcome Display::State::step_sleep(const Step& step) const {
    if (!is_script_late(step.amount)) return still_going();
    return step_ok("hết giờ chờ");
}

// Vào game qua máy chủ xong: màn chơi, đã nhận chỗ đứng, cảnh nạp xong và mặt đất sẵn.
StepOutcome Display::State::step_wait_play(const Step& step) {
    if (is_auto_login_stopped) return step_fail("đăng nhập tự động bị từ chối hay mất phiên");
    const bool is_entered = procedure == Procedure::kPlay && is_online_play;
    const bool is_settled = terrain.has_value() && !arrival.has_value();
    const bool is_placed = people.scene().has_value();
    const bool is_ready = is_entered && is_settled && is_placed;
    const std::chrono::duration<double> spent = core::Clock::now() - script->began;
    if (is_ready) return step_ok(std::format("sau {:.1f} s", spent.count()));
    if (is_script_late(step.amount)) return step_fail("quá hạn chờ vào game");
    return still_going();
}

StepOutcome Display::State::step_shot(const Step& step) {
    script->shots_mark = shots_done;
    const std::string file = step.text + ".png";
    script_shot = script->shot_dir / file;
    return still_going();
}

StepOutcome Display::State::poll_shot(const Step& step) {
    if (shots_done > script->shots_mark && is_shot_ok) return step_ok(step.text + ".png");
    if (shots_done > script->shots_mark) return step_fail("không ghi được ảnh");
    if (is_script_late(kShotSeconds)) return step_fail("quá hạn chờ ảnh");
    return still_going();
}

StepOutcome Display::State::step_event(const Step& step) {
    std::optional<ui::panel::PostedEvent> event = ui::panel::PostedEvent::parse(step.text);
    if (!event) return step_fail("sự kiện sai dạng");
    script_events.push_back(std::move(*event));
    return step_ok(step.text);
}

// Bấm vào tâm cửa sổ: di chuột, nhấn, nhả cùng đi vào hàng input. Nhấn và nhả cùng nút trong một
// khung thì absorb dời lần nhả sang khung sau, như cú bấm ngắn của người thật.
void Display::State::click_at(const gui::Pointer& spot) {
    const FrameRect frame = frame_rect();
    const auto screen_width = static_cast<float>(screen->width());
    const auto screen_height = static_cast<float>(screen->height());
    const float left = static_cast<float>(frame.x) + spot.x;
    const float top = static_cast<float>(frame.y) + spot.y;
    const float across = left / screen_width;
    const float down = top / screen_height;
    const control::InputEvent move = button_event(control::InputKind::kMove, across, down);
    const control::InputEvent press = button_event(control::InputKind::kPress, across, down);
    const control::InputEvent release = button_event(control::InputKind::kRelease, across, down);
    const std::array<control::InputEvent, 3> events{move, press, release};
    push_input(events);
}

StepOutcome Display::State::step_click(const Step& step) {
    if (!hud) return step_fail("chưa có giao diện");
    const std::optional<gui::Pointer> spot = hud->window_spot(step.text);
    if (!spot) return wait_for(step.text);
    click_at(*spot);
    return step_ok(std::format("tại {:.0f},{:.0f}", spot->x, spot->y));
}

StepOutcome Display::State::step_type(const Step& step) {
    std::vector<control::InputEvent> events;
    std::string_view rest = step.text;
    while (!rest.empty()) {
        const core::Utf8Step one = core::utf8_step(rest);
        rest.remove_prefix(one.length);
        const control::InputEvent event = typed_event(one.code);
        events.push_back(event);
    }
    push_input(events);
    return step_ok(std::format("{} ký tự", events.size()));
}

StepOutcome Display::State::step_walk(const Step& step) {
    const bool is_ready = terrain.has_value() && ground != nullptr && scale_ok(ground->file);
    if (!is_ready) return step_fail("chưa có mặt đất để đi");
    const core::GroundPoint here = game_of(ground->file, walk);
    script->goal = core::GroundPoint{.x = resolved(step.x, here.x), .z = resolved(step.z, here.z)};
    script->pulls_mark = pulls;
    script->pulls_seen = pulls;
    script->calm = core::Clock::now();
    order.reset();
    order_move(script->goal, nav::MoveMode::kFind);
    if (!order) return step_fail("không tìm được đường tới đích");
    return still_going();
}

// Xong khi nhân vật đã đứng yên kSettleSeconds mà không bị kéo thêm (chỗ đứng đã được máy chủ chốt)
// và chỗ đó cách đích không quá kArriveMeters. Bị kéo về mà cuối cùng vẫn tới đích thì đạt; không
// tới thì hỏng dù do máy chủ kéo hay do đường. Dòng SCRIPT ghi toạ độ cuối và số lần bị kéo.
StepOutcome Display::State::poll_walk() {
    ScriptRun& run = *script;
    const bool is_moving = order.has_value();
    if (is_moving && is_script_late(kWalkSeconds)) return step_fail("quá hạn khi đi");
    const bool is_dragged = pulls != run.pulls_seen;
    if (is_moving || is_dragged) run.calm = core::Clock::now();
    run.pulls_seen = pulls;
    const std::chrono::duration<double> quiet = core::Clock::now() - run.calm;
    if (is_moving || quiet.count() < kSettleSeconds) return still_going();
    const core::GroundPoint here = game_of(ground->file, walk);
    const float apart = std::hypot(run.goal.x - here.x, run.goal.z - here.z);
    const std::uint32_t pulled = pulls - run.pulls_mark;
    const std::string spot = std::format("({:.1f},{:.1f})", here.x, here.z);
    const std::string gap = std::format("cách đích {:.2f} m (sai số {:g} m)", apart, kArriveMeters);
    const std::string text = std::format("{} {}, kéo về {} lần", spot, gap, pulled);
    if (apart <= kArriveMeters) return step_ok("tới nơi " + text);
    return step_fail("không tới đích: " + text);
}

// NPC theo id hay theo tên (chứa chuỗi đã cho).
const cast::Actor* Display::State::find_npc(std::string_view who) const {
    const std::optional<int> id = core::parse_whole_int(who);
    const cast::Actor* byid = id ? people.find(static_cast<std::uint32_t>(*id)) : nullptr;
    if (byid != nullptr) return byid->kind == cast::Kind::kNpc ? byid : nullptr;
    const look::CreatureTables* tables = creature_tables.get();
    for (const cast::Actor& actor : people.actors()) {
        if (actor.kind != cast::Kind::kNpc) continue;
        if (label_of(actor, tables).contains(who)) return &actor;
    }
    return nullptr;
}

StepOutcome Display::State::step_talk(const Step& step) {
    ScriptRun& run = *script;
    if (run.subject != 0) return poll_talk();
    const cast::Actor* npc = find_npc(step.text);
    if (npc == nullptr) return wait_for(step.text);
    run.subject = npc->id;
    mark_hearing();
    start_talk(*npc);
    return poll_talk();
}

StepOutcome Display::State::poll_talk() {
    const std::uint32_t npc = script->subject;
    const std::optional<std::uint32_t> open = hud ? hud->talking_with() : std::nullopt;
    if (open && *open == npc) return step_ok(std::format("hộp thoại mở với NPC {}", npc));
    if (const std::optional<std::string> why = refused_since()) return step_fail(*why);
    if (people.find(npc) == nullptr) return step_fail("NPC biến mất");
    if (is_script_late(kTalkSeconds)) return step_fail("quá hạn chờ hộp thoại");
    return still_going();
}

// Gửi lựa chọn rồi chờ máy chủ đáp (poll_reply): đạt khi có tin hộp thoại mới, hỏng khi bị từ chối.
StepOutcome Display::State::step_choose(const Step& step) {
    if (!hud) return step_fail("chưa có giao diện");
    const auto position = static_cast<std::size_t>(step.amount) - 1U;
    const core::Clock::duration since = frame_time - started;
    const auto clock = std::chrono::duration_cast<std::chrono::milliseconds>(since);
    mark_hearing();
    const bool is_chosen = hud->choose_option(position, clock);
    if (!is_chosen) return step_fail("không có hộp thoại hay lựa chọn này");
    return still_going();
}

StepOutcome Display::State::poll_reply() {
    if (const std::optional<std::string> why = refused_since()) return step_fail(*why);
    const std::uint32_t got = script_replies - script->replies_mark;
    if (got != 0) return step_ok(std::format("máy chủ đáp {} tin hộp thoại", got));
    if (is_script_late(kReplySeconds)) return step_fail("máy chủ không đáp lựa chọn");
    return still_going();
}

// Bấm ô kỹ năng rồi chờ máy chủ xác nhận chiêu (poll_cast); client không gửi (đang bận, thiếu mục
// tiêu) cũng hiện ra là hỏng sau kReplySeconds.
StepOutcome Display::State::step_cast(const Step& step) {
    const auto slot = static_cast<std::uint32_t>(step.amount) - 1U;
    if (slot >= hero.skills.size()) return step_fail("ô kỹ năng trống");
    mark_hearing();
    press_slot(slot);
    return still_going();
}

StepOutcome Display::State::poll_cast() {
    if (const std::optional<std::string> why = refused_since()) return step_fail(*why);
    if (script_casts != script->casts_mark) return step_ok("máy chủ xác nhận chiêu");
    if (is_script_late(kReplySeconds)) return step_fail("máy chủ không xác nhận chiêu");
    return still_going();
}

// Vật rơi nhặt được gần người chơi nhất.
const cast::Actor* Display::State::find_drop() const {
    if (ground == nullptr || !scale_ok(ground->file)) return nullptr;
    const core::GroundPoint here = game_of(ground->file, walk);
    const cast::Actor* nearest = nullptr;
    float best = std::numeric_limits<float>::infinity();
    for (const cast::Actor& actor : people.actors()) {
        if (actor.kind != cast::Kind::kDrop) continue;
        if ((actor.flags & cast::kFlagPick) == 0) continue;
        const float apart = std::hypot(actor.x - here.x, actor.z - here.z);
        if (apart >= best) continue;
        best = apart;
        nearest = &actor;
    }
    return nearest;
}

StepOutcome Display::State::step_pick() {
    ScriptRun& run = *script;
    if (run.subject != 0) return poll_pick();
    const cast::Actor* drop = find_drop();
    if (drop == nullptr) return wait_for("vật rơi nhặt được");
    run.subject = drop->id;
    mark_hearing();
    start_pick(*drop);
    return poll_pick();
}

// Đạt khi PickUp đã gửi (hết việc đi tới) và máy chủ đã nhận: vật rơi biến khỏi cảnh. Bị từ chối,
// hay quá hạn khi đi hoặc chờ nhận, thì hỏng.
StepOutcome Display::State::poll_pick() {
    if (const std::optional<std::string> why = refused_since()) return step_fail(*why);
    const bool is_sent = !talk_goal.has_value();
    if (is_sent && people.find(script->subject) == nullptr) return step_ok("vật rơi đã được nhặt");
    if (!is_script_late(kTalkSeconds)) return still_going();
    if (is_sent) return step_fail("máy chủ không nhận việc nhặt");
    return step_fail("quá hạn đi tới vật rơi");
}

StepOutcome Display::State::step_quit() {
    script->is_quitting = true;
    return step_ok("thoát");
}

// ---- tin máy chủ đáp ----

void Display::State::watch_script(const tk::Hear& note) {
    if (const auto* refused = std::get_if<tk::Refused>(&note)) {
        ++script_refusals;
        script_refusal = refusal_name(refused->why);
        return;
    }
    if (const auto* declined = std::get_if<tk::Declined>(&note)) {
        ++script_refusals;
        script_refusal = decline_name(declined->why);
        return;
    }
    if (is_dialog_reply(note)) ++script_replies;
}

void Display::State::mark_hearing() {
    script->replies_mark = script_replies;
    script->casts_mark = script_casts;
    script->refusals_mark = script_refusals;
}

std::optional<std::string> Display::State::refused_since() const {
    if (script_refusals == script->refusals_mark) return std::nullopt;
    return std::format("máy chủ từ chối: {}", script_refusal);
}

} // namespace game::client
