/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Look/impact_tests.cpp
 *  PHÂN HỆ   : Look / Impact Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm đếm tham chiếu hiệu ứng và một bước bay của đạn. Sai thì hạt nhân đôi
 *    hoặc đạn nổ sai chỗ mà không có hình nào báo.
 *  - Nguồn: InsertImpact / RemoveImpact và CObject_Bullet::Tick (client 2008).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "look/bullet.hpp"
#include "look/impact.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using look::BulletFlight;
using look::BulletStep;
using look::FlightPoint;
using look::ImpactBook;
using look::ImpactCue;
using look::ImpactCueKind;
using look::ImpactSlot;
using look::Trail;

constexpr std::string_view kImpacts =
    "id\ttrigger_effect\ttrigger_sound\ttrigger_anchor\tcontinuous_effect\t"
    "continuous_sound\tcontinuous_anchor\tkept_after_death\tis_linear\tlinear_anchor\n"
    "1\tonce_a\tsnd_a\tfoot\tkeep_a\tcsnd\tbody\t1\t0\t\n"
    "2\tonce_b\t\tfoot\t\t\tbody\t0\t1\tline\n"
    "3\tonce_c\tsnd_c\tfoot\thold_c\t\tbody\t0\t0\t\n";

constexpr std::string_view kBullets =
    "id\ttrajectory\tspeed\tflight_effect\tflight_sound\texplosion_effect\t"
    "explosion_sound\thit_anchor\n"
    "1\t0\t5\tfly\tfs\tboom\tbs\tfoot\n"
    "2\t2\t0\t\t\tboom\t\tfoot\n"
    "3\t1\t5\tarc\t\tboom\t\tfoot\n"
    "4\t-1\t3\t\t\tboom\t\tfoot\n";

constexpr std::string_view kSkills = "skill\tbullet_id\tspawn_point\n10\t1\thand\n";

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) < 1e-4F;
}

[[nodiscard]] ImpactBook impact_book(Context& context, std::string_view text) {
    ImpactBook book;
    const look::ImpactRows rows = look::parse_impacts(text);
    const std::string why = rows ? std::string("bảng impacts") : rows.error();
    context.expect(rows.has_value(), why);
    if (rows) book.reset(*rows);
    return book;
}

[[nodiscard]] const ImpactCue* cue_of(std::span<const ImpactCue> cues, ImpactCueKind kind) {
    const auto found = std::ranges::find(cues, kind, &ImpactCue::kind);
    if (found == cues.end()) return nullptr;
    return &*found;
}

[[nodiscard]] const ImpactSlot* slot_of(const ImpactBook& book, std::uint32_t id) {
    const std::span<const ImpactSlot> slots = book.slots();
    const auto found = std::ranges::find(slots, id, &ImpactSlot::id);
    if (found == slots.end()) return nullptr;
    return &*found;
}

void first_enable_emits_once(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    const std::vector<ImpactCue> cues = book.enable(1, true);
    context.expect(cue_of(cues, ImpactCueKind::kOnce) != nullptr, "phát một lần");
    context.expect(cue_of(cues, ImpactCueKind::kSound) != nullptr, "có tiếng");
    context.expect(cue_of(cues, ImpactCueKind::kAttach) != nullptr, "gắn hạt giữ");
    const ImpactSlot* slot = slot_of(book, 1);
    context.expect(slot != nullptr && slot->refs == 1, "đếm một");
    context.expect(slot != nullptr && slot->continuous == "keep_a", "tên hạt giữ");
    context.expect(slot != nullptr && slot->kept_after_death, "dòng 1 giữ sau khi chết");
}

void second_enable_only_counts(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    static_cast<void>(book.enable(1, true));
    const std::vector<ImpactCue> again = book.enable(1, true);
    context.expect(again.empty(), "lần sau không phát thêm");
    const ImpactSlot* slot = slot_of(book, 1);
    context.expect(slot != nullptr && slot->refs == 2, "đếm hai");
}

void disable_detaches_at_zero(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    static_cast<void>(book.enable(1, true));
    static_cast<void>(book.enable(1, true));
    const std::vector<ImpactCue> once = book.disable(1);
    context.expect(once.empty() && slot_of(book, 1)->refs == 1, "còn một thì chưa tháo");
    const std::vector<ImpactCue> gone = book.disable(1);
    context.expect(cue_of(gone, ImpactCueKind::kDetach) != nullptr, "hết đếm thì tháo");
    context.expect(slot_of(book, 1) == nullptr, "ô đã mất");
}

void unknown_id_still_slots(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    const std::vector<ImpactCue> cues = book.enable(9, true);
    const ImpactSlot* slot = slot_of(book, 9);
    context.expect(cues.empty(), "id lạ không có hạt");
    context.expect(slot != nullptr && slot->refs == 1, "vẫn có ô");
    context.expect(slot != nullptr && slot->kept_after_death, "không mô tả thì không bị drop_dead xoá");
    context.expect(!book.known(9) && book.known(1), "known chỉ đúng bảng");
}

void hidden_show_skips_the_burst(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    const std::vector<ImpactCue> cues = book.enable(1, false);
    context.expect(cue_of(cues, ImpactCueKind::kOnce) == nullptr, "không phô thì không nổ");
    context.expect(cue_of(cues, ImpactCueKind::kSound) == nullptr, "không phô thì không tiếng");
    context.expect(cue_of(cues, ImpactCueKind::kAttach) != nullptr, "hạt giữ vẫn gắn");
}

void empty_continuous_does_not_attach(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    const std::vector<ImpactCue> cues = book.enable(2, true);
    context.expect(cue_of(cues, ImpactCueKind::kOnce) != nullptr, "vẫn nổ một lần");
    context.expect(cue_of(cues, ImpactCueKind::kAttach) == nullptr, "không có hạt giữ");
    const ImpactSlot* slot = slot_of(book, 2);
    context.expect(slot != nullptr && slot->continuous.empty(), "ô không giữ tên hạt");
    context.expect(slot != nullptr && slot->is_linear && slot->linear_anchor == "line", "cờ tuyến được giữ");
}

void drop_dead_keeps_the_marked(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    static_cast<void>(book.enable(1, false));
    static_cast<void>(book.enable(3, false));
    const std::vector<ImpactCue> cues = book.drop_dead();
    context.expect(slot_of(book, 1) != nullptr, "dòng giữ thì còn");
    context.expect(slot_of(book, 3) == nullptr, "dòng không giữ thì mất");
    context.expect(cue_of(cues, ImpactCueKind::kDetach) != nullptr, "tháo hạt của dòng mất");
}

void clear_removes_every_slot(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    static_cast<void>(book.enable(1, false));
    static_cast<void>(book.enable(3, false));
    const std::vector<ImpactCue> cues = book.clear();
    context.expect(book.slots().empty(), "xoá hết");
    context.expect(cues.size() == 2, "tháo cả hai hạt giữ");
}

void duplicate_impact_is_an_error(Context& context) {
    const std::string text = std::string(kImpacts) + "1\tonce_a\t\tfoot\t\t\tbody\t1\t0\t\n";
    const look::ImpactRows rows = look::parse_impacts(text);
    context.expect(!rows && rows.error().find("trùng") != std::string::npos, "khoá trùng là lỗi");
}

void missing_impact_column_is_an_error(Context& context) {
    constexpr std::string_view text = "id\ttrigger_effect\n1\tonce_a\n";
    const look::ImpactRows rows = look::parse_impacts(text);
    context.expect(!rows && rows.error().find("thiếu cột") != std::string::npos, "thiếu cột là lỗi");
}

void full_book_refuses_a_new_id(Context& context) {
    ImpactBook book = impact_book(context, kImpacts);
    for (std::uint32_t id = 1; id <= look::kMaxImpacts; ++id)
        static_cast<void>(book.enable(id, false));
    const std::vector<ImpactCue> extra = book.enable(1000, true);
    context.expect(extra.empty() && book.slots().size() == look::kMaxImpacts, "đầy thì từ chối id mới");
    static_cast<void>(book.enable(1, true));
    const ImpactSlot* slot = slot_of(book, 1);
    context.expect(slot != nullptr && slot->refs == 2, "id đang có vẫn tăng đếm");
}

[[nodiscard]] BulletFlight flight_of(Trail trail, float speed, float arc, FlightPoint from,
    FlightPoint to) {
    return look::begin_flight(trail, speed, arc, from, to);
}

void line_moves_without_hitting(Context& context) {
    const FlightPoint from{};
    const FlightPoint to{.x = 10.0F};
    const BulletFlight flight = flight_of(Trail::kLine, 5.0F, 0.0F, from, to);
    const BulletStep step = look::step_bullet(flight, to, 1.0F);
    context.expect(near_value(step.at.x, 5.0F) && !step.hit, "đi 5 mét chưa trúng");
}

void short_gap_hits(Context& context) {
    const FlightPoint from{.x = 9.0F};
    const FlightPoint to{.x = 10.0F};
    const BulletFlight flight = flight_of(Trail::kLine, 5.0F, 0.0F, from, to);
    const BulletStep step = look::step_bullet(flight, to, 1.0F);
    context.expect(step.hit && near_value(step.at.x, 10.0F), "còn 1 mét thì trúng đích");
}

void none_hits_on_the_next_step(Context& context) {
    const FlightPoint from{};
    const FlightPoint to{.x = 10.0F, .y = 2.0F};
    const BulletFlight flight = flight_of(Trail::kNone, 5.0F, 0.0F, from, to);
    context.expect(near_value(flight.at.x, 10.0F) && near_value(flight.at.y, 2.0F), "không bay thì đã ở đích");
    const BulletStep step = look::step_bullet(flight, to, 1.0F);
    context.expect(step.hit, "khung sau báo trúng");
}

void flat_arc_matches_the_line(Context& context) {
    const FlightPoint from{};
    const FlightPoint to{.x = 10.0F};
    const BulletFlight line = flight_of(Trail::kLine, 5.0F, 0.0F, from, to);
    const BulletFlight arc = flight_of(Trail::kArc, 5.0F, 0.0F, from, to);
    const BulletStep line_step = look::step_bullet(line, to, 1.0F);
    const BulletStep arc_step = look::step_bullet(arc, to, 1.0F);
    context.expect(near_value(line_step.at.y, arc_step.at.y), "cung cao 0 cùng độ cao đường thẳng");
}

void arc_peaks_at_midpoint(Context& context) {
    const FlightPoint from{};
    const FlightPoint to{.x = 10.0F};
    const BulletFlight flight = flight_of(Trail::kArc, 5.0F, 4.0F, from, to);
    const BulletStep step = look::step_bullet(flight, to, 1.0F);
    context.expect(near_value(step.at.x, 5.0F) && near_value(step.at.y, 4.0F), "giữa đoạn nâng đúng 4");
    context.expect(!step.hit, "chưa tới đích");
}

void zero_span_is_finite(Context& context) {
    const FlightPoint from{};
    const BulletFlight flight = flight_of(Trail::kArc, 5.0F, 4.0F, from, from);
    const BulletStep step = look::step_bullet(flight, from, 1.0F);
    context.expect(step.hit && std::isfinite(step.at.y), "đoạn dài 0 không ra NaN");
    context.expect(near_value(step.at.y, 0.0F), "không chia cho 0 nên không nâng");
}

void zero_speed_stays(Context& context) {
    const FlightPoint from{};
    const FlightPoint to{.x = 10.0F};
    const BulletFlight flight = flight_of(Trail::kLine, 0.0F, 0.0F, from, to);
    const BulletStep step = look::step_bullet(flight, to, 1.0F);
    context.expect(!step.hit && near_value(step.at.x, 0.0F), "tốc độ 0 đứng yên");
}

void negative_seconds_stay(Context& context) {
    const FlightPoint from{};
    const FlightPoint to{.x = 10.0F};
    const BulletFlight flight = flight_of(Trail::kLine, 5.0F, 0.0F, from, to);
    const BulletStep step = look::step_bullet(flight, to, -1.0F);
    context.expect(!step.hit && near_value(step.at.x, 0.0F), "giây âm không lùi");
}

void bad_trajectory_is_rejected(Context& context) {
    constexpr std::string_view text =
        "id\ttrajectory\tspeed\tflight_effect\tflight_sound\texplosion_effect\t"
        "explosion_sound\thit_anchor\n1\t3\t1\t\t\t\t\tfoot\n";
    const look::BulletRows rows = look::parse_bullets(text);
    context.expect(!rows, "quỹ đạo 3 bị từ chối");
}

void negative_speed_is_rejected(Context& context) {
    constexpr std::string_view text =
        "id\ttrajectory\tspeed\tflight_effect\tflight_sound\texplosion_effect\t"
        "explosion_sound\thit_anchor\n1\t0\t-1\t\t\t\t\tfoot\n";
    const look::BulletRows rows = look::parse_bullets(text);
    context.expect(!rows, "tốc độ âm bị từ chối");
}

void books_find_rows(Context& context) {
    const look::BulletRows bullets = look::parse_bullets(kBullets);
    const std::string bullet_why = bullets ? std::string("bảng đạn") : bullets.error();
    context.expect(bullets.has_value(), bullet_why);
    look::BulletBook book;
    if (bullets) book.reset(*bullets);
    context.expect(book.find(1) != nullptr && book.find(1)->trail == Trail::kLine, "đạn 1 thẳng");
    context.expect(book.find(2) != nullptr && book.find(2)->trail == Trail::kNone, "đạn 2 không bay");
    context.expect(book.find(4) != nullptr && book.find(4)->trail == Trail::kNone, "mã -1 là không bay");
    context.expect(book.find(9) == nullptr, "id lạ không có dòng");
    const look::SkillRows skills = look::parse_skill_bullets(kSkills);
    const std::string skill_why = skills ? std::string("bảng skill") : skills.error();
    context.expect(skills.has_value(), skill_why);
    look::SkillBulletBook skills_book;
    if (skills) skills_book.reset(*skills);
    context.expect(skills_book.find(10) != nullptr && skills_book.find(10)->bullet == 1, "skill 10 bắn đạn 1");
    context.expect(skills_book.find(0) == nullptr, "skill không có dòng là không bắn");
}

constexpr std::array kCases{
    Case{.name = "first_enable_emits_once", .body = &first_enable_emits_once},
    Case{.name = "second_enable_only_counts", .body = &second_enable_only_counts},
    Case{.name = "disable_detaches_at_zero", .body = &disable_detaches_at_zero},
    Case{.name = "unknown_id_still_slots", .body = &unknown_id_still_slots},
    Case{.name = "hidden_show_skips_the_burst", .body = &hidden_show_skips_the_burst},
    Case{.name = "empty_continuous_does_not_attach", .body = &empty_continuous_does_not_attach},
    Case{.name = "drop_dead_keeps_the_marked", .body = &drop_dead_keeps_the_marked},
    Case{.name = "clear_removes_every_slot", .body = &clear_removes_every_slot},
    Case{.name = "duplicate_impact_is_an_error", .body = &duplicate_impact_is_an_error},
    Case{.name = "missing_impact_column_is_an_error", .body = &missing_impact_column_is_an_error},
    Case{.name = "full_book_refuses_a_new_id", .body = &full_book_refuses_a_new_id},
    Case{.name = "line_moves_without_hitting", .body = &line_moves_without_hitting},
    Case{.name = "short_gap_hits", .body = &short_gap_hits},
    Case{.name = "none_hits_on_the_next_step", .body = &none_hits_on_the_next_step},
    Case{.name = "flat_arc_matches_the_line", .body = &flat_arc_matches_the_line},
    Case{.name = "arc_peaks_at_midpoint", .body = &arc_peaks_at_midpoint},
    Case{.name = "zero_span_is_finite", .body = &zero_span_is_finite},
    Case{.name = "zero_speed_stays", .body = &zero_speed_stays},
    Case{.name = "negative_seconds_stay", .body = &negative_seconds_stay},
    Case{.name = "bad_trajectory_is_rejected", .body = &bad_trajectory_is_rejected},
    Case{.name = "negative_speed_is_rejected", .body = &negative_speed_is_rejected},
    Case{.name = "books_find_rows", .body = &books_find_rows},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "impact_tests: mọi ca phải qua");
    return 0;
}
