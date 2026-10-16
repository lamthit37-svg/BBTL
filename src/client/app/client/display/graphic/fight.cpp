/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/fight.cpp
 *  PHÂN HỆ   : Display / Graphic / Fight
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nối chiến đấu của chính người chơi giữa luồng vẽ và máy chủ: phím ô thao
 *    tác thành CastSkill, đánh tự động (đi tới mục tiêu rồi ra chiêu), động tác
 *    chỉ chạy khi máy chủ xác nhận, sinh lực và kỹ năng máy chủ báo vào hero,
 *    số sát thương bay trên đầu thực thể, bảng tên và thanh máu, tên tuyệt
 *    chiêu và lời nhắc hồi sinh.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Client không đoán kết quả (logic ở client/fight/combat.hpp): chiêu chỉ là ý định gửi lên, động tác và số bay chỉ có khi máy
// chủ nói. Cách hỏng đã tính trước (CL-03):
//   chiêu tới trong lúc nhân vật đang đi / nhảy / giữa đòn -> bỏ phím (như begin_strike chơi tại chỗ), không xếp hàng chờ.
//   đánh tự động mà mục tiêu chạy mất               -> tìm đường lại không sớm hơn kChaseRepath; quá kChasePatience thì thôi.
//   người chơi tự đi (phím, cần gạt) giữa lúc đuổi    -> thôi đánh tự động, mục tiêu vẫn được chọn.
//   kỹ năng đổi giữa chừng (SelfSkills tới sau)       -> dựng lại người chơi để nạp clip của kỹ năng mới.
//   đã chết                                          -> không đi, không ra chiêu; phím 1 và 2 là hồi sinh.
//   thực thể có số bay biến mất trước khi số hết hạn  -> bỏ số đó, không đặt chữ ở chỗ cũ.
//   chữ bay ra ngoài màn hình hay sau mắt             -> bỏ (project_point rỗng), không vẽ ngoài khung.
//   bảng tên: tên rỗng, quái chết, sau mắt, xa 25 mét -> không vẽ. Chiều cao mẫu khổng lồ kẹp 40 mét.

#include "client/display/graphic/state.hpp"

#include "client/cast/cast.hpp"
#include "client/cast/note.hpp"
#include "client/display/display.hpp"
#include "client/display/player.hpp"
#include "client/display/graphic/prelude.hpp"
#include "client/fight/combat.hpp"
#include "control/view_ray.hpp"
#include "core/clock.hpp"
#include "core/ground_point.hpp"
#include "hero/hero.hpp"
#include "motion/motion.hpp"
#include "nav/route.hpp"
#include "ogre/vec3.hpp"
#include "render/ui.hpp"
#include "ui/hud.hpp"
#include "ui/pace.hpp"
#include "ui/panel/talk.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <mutex>
#include <optional>
#include <ratio>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>

namespace game::client {
namespace {

namespace tk = ui::panel::talk;

// Các đòn trúng của chiêu mình vừa ra tới cùng nhịp với SkillCast; tới muộn hơn chừng này thì không còn thuộc động tác vừa phát.
constexpr std::chrono::milliseconds kHitSlack{250};
// Đuổi mục tiêu: tìm đường lại không sớm hơn chừng này, hoặc khi mục tiêu đã dời quá kChaseDrift mét khỏi đích cũ; đuổi
// quá kChasePatience mà chưa tới tầm thì thôi.
constexpr std::chrono::milliseconds kChaseRepath{300};
constexpr float kChaseDrift = 1.0F;
constexpr std::chrono::seconds kChasePatience{20};

// Chữ bay: bắt đầu cao kFloatHead mét trên chân, bay thêm kFloatRise mét trong đời số, mờ dần từ kFadeFrom của đời số. Cỡ chữ
// là bội của phông 12 điểm ảnh của giao diện.
constexpr float kFloatHead = 2.1F;
constexpr float kFloatRise = 1.0F;
constexpr float kFadeFrom = 0.65F;
constexpr float kNormalScale = 2.0F;
constexpr float kCriticalScale = 3.0F;
// Các số cùng lúc trên một thực thể lệch nhau ba làn ngang để không đè lên nhau (điểm ảnh).
constexpr float kLaneWidth = 28.0F;
constexpr std::int64_t kLanes = 3;

// Màu ARGB.
constexpr std::uint32_t kHurtInk = 0xFFFF5050U;
constexpr std::uint32_t kDealInk = 0xFFFFE680U;
constexpr std::uint32_t kCritInk = 0xFFFFA020U;
constexpr std::uint32_t kHealInk = 0xFF6FE08CU;
constexpr std::uint32_t kPlainInk = 0xFFE0E0E0U;
constexpr std::uint32_t kShadowInk = 0xFF000000U;
constexpr std::uint32_t kAlphaMask = 0x00FFFFFFU;

constexpr std::string_view kMissText = "闪避";
constexpr std::string_view kImmuneText = "免疫";
constexpr std::string_view kDeadTitle = "您已经死亡";
constexpr std::string_view kDeadHint = "按 1 回城复活 | 按 2 原地复活";
// Lời nhắc hồi sinh nằm ở một phần ba chiều cao màn từ trên xuống.
constexpr float kDeadLine = 0.33F;

// Bảng tên trên đầu quái, NPC và trân thú. Hiện đủ trong 18 mét, mờ tới mất ở 25 mét: bình phương mét,
// cùng m_nMaxDistance 324 và m_nMaxDispearDistance 625 của UICreatureBoardSystem.cpp.
// Khác gốc: bảng 2008 chỉ có tên, danh hiệu, màu theo SystemColor của phe và AI (dây không có).
// Thanh máu đặc và một màu theo loại thực thể là để nhìn sinh lực khi dây chỉ mang phần trăm.
constexpr float kPlateNear = 18.0F;
constexpr float kPlateFar = 25.0F;
constexpr float kPlateNearSq = kPlateNear * kPlateNear;
constexpr float kPlateFarSq = kPlateFar * kPlateFar;
constexpr float kPlateNameScale = 1.35F;
constexpr float kPlateBarWidth = 56.0F;
constexpr float kPlateBarHeight = 6.0F;
constexpr float kPlateGap = 3.0F;
constexpr std::size_t kPlateNameCodes = 16;
constexpr std::uint32_t kMonsterInk = 0xFFFF4040U;
constexpr std::uint32_t kNpcInk = 0xFF40E060U;
constexpr std::uint32_t kPetInk = 0xFF60C0FFU;
constexpr std::uint32_t kBarTrack = 0xFF141010U;
constexpr std::uint32_t kBarFill = 0xFFE23A3AU;
// Tên tuyệt chiêu trên đầu người chơi. Khác gốc: client 2026 vẽ ảnh chữ của chiêu; ở đây là phông GBK12
// vì ảnh chữ ấy chưa nối. Hiện 2,2 giây, mờ 0,6 giây cuối, cao hơn điểm chữ bay 0,8 mét.
constexpr std::chrono::milliseconds kBannerLife{2200};
constexpr std::chrono::milliseconds kBannerFade{600};
constexpr float kBannerScale = 3.2F;
constexpr float kBannerLift = 0.8F;
constexpr std::size_t kBannerCodes = 24;
constexpr std::uint32_t kBannerInk = 0xFFFFE080U;

// Màu RGB kèm độ trong suốt 0..1 (kẹp), ra ARGB.
struct Fade {
    std::uint32_t colour = 0;
    float alpha = 1.0F;
};

[[nodiscard]] std::uint32_t with_alpha(const Fade& fade) noexcept {
    const float clamped = std::clamp(fade.alpha, 0.0F, 1.0F);
    const auto byte = static_cast<std::uint32_t>(std::lround(clamped * 255.0F));
    return (byte << 24U) | (fade.colour & kAlphaMask);
}

[[nodiscard]] std::string text_of(const fight::Float& shown) {
    switch (shown.kind) {
    case cast::Blow::kDamage: return shown.is_critical ? std::format("{}!", shown.value) : std::format("{}", shown.value);
    case cast::Blow::kHeal: return std::format("+{}", shown.value);
    case cast::Blow::kMiss: return std::string{kMissText};
    case cast::Blow::kImmune: return std::string{kImmuneText};
    }
    return {};
}

[[nodiscard]] std::uint32_t ink_of(const fight::Float& shown, bool is_self) noexcept {
    switch (shown.kind) {
    case cast::Blow::kDamage: return shown.is_critical ? kCritInk : (is_self ? kHurtInk : kDealInk);
    case cast::Blow::kHeal: return kHealInk;
    case cast::Blow::kMiss:
    case cast::Blow::kImmune: return kPlainInk;
    }
    return kPlainInk;
}

// Vị trí và cỡ của một dòng chữ: tâm ngang, mép trên (điểm ảnh của màn) và bội của phông.
struct Line {
    float centre = 0.0F;
    float top = 0.0F;
    float scale = 1.0F;
};

// Chữ có bóng, canh giữa theo Line. append_text không có cỡ nên co giãn các đỉnh quanh góc trái trên sau khi ghi; toạ độ chữ
// làm tròn về điểm ảnh nguyên để chữ không rung khi bay.
void put_line(const ui::BitmapFont& font, std::string_view text, const Line& line, std::uint32_t colour,
    std::vector<render::UiVertex>& out) {
    const float left = std::round(line.centre - (font.width_of(text) * line.scale * 0.5F));
    const float top = std::round(line.top);
    const auto write = [&](float pen_x, float pen_y, std::uint32_t ink) {
        const std::size_t begin = out.size();
        font.append_text(text, pen_x, pen_y, ink, out);
        for (render::UiVertex& vertex : std::span(out).subspan(begin)) {
            vertex.x = pen_x + ((vertex.x - pen_x) * line.scale);
            vertex.y = pen_y + ((vertex.y - pen_y) * line.scale);
        }
    };
    write(left + 1.0F, top + 1.0F, with_alpha({.colour = kShadowInk, .alpha = static_cast<float>(colour >> 24U) / 255.0F}));
    write(left, top, colour);
}

// Tiền tố UTF-8 đủ cap điểm mã, không cắt giữa một mã.
[[nodiscard]] std::string_view prefix_codes(std::string_view text, std::size_t cap) noexcept {
    std::size_t bytes = 0;
    std::size_t codes = 0;
    while (bytes < text.size() && codes < cap) {
        const auto lead = static_cast<unsigned char>(text[bytes]);
        std::size_t step = 1;
        if ((lead & 0x80U) == 0U) step = 1;
        else if ((lead & 0xE0U) == 0xC0U && bytes + 2 <= text.size()) step = 2;
        else if ((lead & 0xF0U) == 0xE0U && bytes + 3 <= text.size()) step = 3;
        else if ((lead & 0xF8U) == 0xF0U && bytes + 4 <= text.size()) step = 4;
        else break;
        bytes += step;
        ++codes;
    }
    return text.substr(0, bytes);
}

[[nodiscard]] float plate_alpha(float dx, float dz) noexcept {
    const float dist_sq = (dx * dx) + (dz * dz);
    if (!(dist_sq < kPlateFarSq)) return 0.0F;
    if (dist_sq <= kPlateNearSq) return 1.0F;
    return (kPlateFar - std::sqrt(dist_sq)) / (kPlateFar - kPlateNear);
}

[[nodiscard]] bool shows_plate(cast::Kind kind) noexcept {
    return kind == cast::Kind::kMonster || kind == cast::Kind::kNpc || kind == cast::Kind::kPet;
}

[[nodiscard]] std::uint32_t plate_rgb(cast::Kind kind) noexcept {
    if (kind == cast::Kind::kNpc) return kNpcInk;
    if (kind == cast::Kind::kPet) return kPetInk;
    return kMonsterInk;
}

[[nodiscard]] std::string_view creature_name(const cast::Actor& actor, const look::CreatureTables* tables) noexcept {
    if (!actor.name.empty()) return actor.name;
    if (tables == nullptr) return {};
    const look::CreatureTemplate* row = tables->find_template(actor.template_id);
    if (row == nullptr) return {};
    return row->name;
}

void put_solid(std::vector<render::UiVertex>& out, float left, float top, float right, float bottom,
    std::uint32_t colour) {
    out.push_back({.x = left, .y = top, .u = 0.0F, .v = 0.0F, .colour = colour});
    out.push_back({.x = right, .y = top, .u = 1.0F, .v = 0.0F, .colour = colour});
    out.push_back({.x = right, .y = bottom, .u = 1.0F, .v = 1.0F, .colour = colour});
    out.push_back({.x = left, .y = bottom, .u = 0.0F, .v = 1.0F, .colour = colour});
}

void push_extra(std::vector<render::UiVertex>& vertices, std::vector<render::UiBatch>& batches, std::size_t first,
    std::uint32_t texture) {
    if (vertices.size() < first) return;
    const std::size_t count = vertices.size() - first;
    if (count == 0 || count % 4 != 0) return;
    batches.push_back(render::UiBatch{.texture = texture,
        .first_quad = static_cast<std::uint32_t>(first / 4),
        .quad_count = static_cast<std::uint32_t>(count / 4)});
}

// Chỗ tên trên màn. name trỏ vào actor hoặc bảng mẫu, chỉ dùng trong khung đang vẽ.
struct PlateAt {
    float centre = 0.0F;
    float name_top = 0.0F;
    float alpha = 1.0F;
    std::uint8_t hp = 100;
    cast::Kind kind = cast::Kind::kMonster;
    std::string_view name;
};

[[nodiscard]] std::optional<PlateAt> plate_screen(const cast::Actor& actor, const look::CreatureTables* tables,
    const ogre::Vec3& spot, const core::GroundPoint& here, const control::Lens& lens, float width, float height,
    const ui::BitmapFont& font) {
    const std::string_view name = prefix_codes(creature_name(actor, tables), kPlateNameCodes);
    if (name.empty()) return std::nullopt;
    const float alpha = plate_alpha(actor.x - here.x, actor.z - here.z);
    if (!(alpha > 0.0F)) return std::nullopt;
    const std::optional<control::ScreenPoint> at = control::project_point(lens, spot);
    if (!at) return std::nullopt;
    const float name_h = static_cast<float>(font.pixel_size()) * kPlateNameScale;
    return PlateAt{.centre = at->x * width,
        .name_top = std::round((at->y * height) - name_h),
        .alpha = alpha,
        .hp = actor.hp_percent,
        .kind = actor.kind,
        .name = name};
}

void paint_bar(const PlateAt& plate, float name_h, std::vector<render::UiVertex>& out) {
    const float left = std::round(plate.centre - (kPlateBarWidth * 0.5F));
    const float top = plate.name_top + name_h + kPlateGap;
    const float bottom = top + kPlateBarHeight;
    put_solid(out, left, top, left + kPlateBarWidth, bottom, with_alpha({.colour = kBarTrack, .alpha = plate.alpha * 0.9F}));
    const auto percent = std::min<std::uint8_t>(plate.hp, 100);
    const float filled = (static_cast<float>(percent) / 100.0F) * kPlateBarWidth;
    if (filled < 1.0F) return;
    put_solid(out, left, top, left + filled, bottom, with_alpha({.colour = kBarFill, .alpha = plate.alpha}));
}

void paint_name(const PlateAt& plate, const ui::BitmapFont& font, std::vector<render::UiVertex>& out) {
    const std::uint32_t ink = with_alpha({.colour = plate_rgb(plate.kind), .alpha = plate.alpha});
    put_line(font, plate.name, Line{.centre = plate.centre, .top = plate.name_top, .scale = kPlateNameScale}, ink, out);
}

} // namespace

// ---- tin của máy chủ ----

bool Display::State::hear_fight(const tk::Hear& note) {
    if (const auto* vitals = std::get_if<tk::Vitals>(&note)) {
        apply_vitals(*vitals);
        return true;
    }
    if (const auto* skills = std::get_if<tk::Skills>(&note)) {
        apply_skills(*skills);
        return true;
    }
    if (const auto* cooldown = std::get_if<tk::Cooldown>(&note)) {
        combat.cool(*cooldown, frame_time);
        return true;
    }
    if (const auto* slain = std::get_if<tk::Slain>(&note)) {
        combat.slain(*slain);
        return true;
    }
    if (const auto* declined = std::get_if<tk::Declined>(&note)) {
        combat.declined(declined->why, frame_time);
        return true;
    }
    return false;
}

void Display::State::apply_vitals(const tk::Vitals& vitals) {
    vitals_seen = vitals;
    combat.vitals(vitals);
    show_fight();
}

void Display::State::apply_skills(const tk::Skills& skills) {
    combat.learn(skills, frame_time);
    show_fight();
}

// Sinh lực lên các thanh của hero. Kỹ năng thì ô thao tác k là kỹ năng học thứ k (không có kỹ năng nào thì chỉ còn đánh thường
// id 0); đổi danh sách mà người chơi đã dựng thì dựng lại để nạp clip của kỹ năng mới (PlayerActor chỉ nạp clip của desc.skills).
void Display::State::show_fight() {
    if (vitals_seen) {
        hero.health = hero::Gauge{.now = vitals_seen->hp, .top = vitals_seen->hp_max};
        hero.mana = hero::Gauge{.now = vitals_seen->mp, .top = vitals_seen->mp_max};
        hero.rage = hero::Gauge{.now = vitals_seen->rage, .top = vitals_seen->rage_max};
    }
    std::vector<std::uint32_t> ids = combat.learned();
    if (ids.empty()) ids.push_back(0);
    if (ids == hero.skills) return;
    hero.skills = std::move(ids);
    if (player) load_player();
}

// Ms còn lại của mười ô, cùng chỉ số với hero.skills. Kỹ năng không nằm trong danh sách đã học (đánh thường id 0) là đã hồi.
void Display::State::fill_bar_cooldown() {
    bar_left_ms.fill(0);
    const std::size_t count = std::min(hero.skills.size(), bar_left_ms.size());
    for (std::size_t slot = 0; slot < count; ++slot) note_bar_left(slot);
}

void Display::State::note_bar_left(std::size_t slot) {
    const std::uint32_t id = hero.skills.at(slot);
    if (id > UINT16_MAX) return;
    const auto left = combat.cooldown_left(static_cast<std::uint16_t>(id), frame_time);
    if (left.count() <= 0) return;
    const auto ms = static_cast<std::uint64_t>(left.count());
    constexpr auto kCap = static_cast<std::uint64_t>(std::numeric_limits<std::uint32_t>::max());
    bar_left_ms.at(slot) = static_cast<std::uint32_t>(std::min(ms, kCap));
}

// Chiêu và đòn trúng của thế giới. Cast đã áp tin vào danh sách thực thể trước khi tới đây.
void Display::State::note_fight(const cast::Note& note) {
    if (const auto* casting = std::get_if<cast::Casting>(&note)) {
        const bool is_other = casting->source != 0 && casting->source != people.self_id();
        if (is_other) {
            play_peer_cast(*casting);
            return;
        }
        if (casting->seq == 0 || !combat.confirm(casting->seq)) return;
        const std::chrono::milliseconds delay = play_confirmed(*casting);
        hit_window = HitWindow{.until = frame_time + kHitSlack, .delay = delay};
        return;
    }
    if (const auto* struck = std::get_if<cast::Struck>(&note)) {
        const bool is_mine = struck->source != 0 && struck->source == people.self_id() && hit_window &&
            frame_time <= hit_window->until;
        combat.strike(*struck, is_mine ? frame_time + hit_window->delay : frame_time);
        return;
    }
    if (const auto* died = std::get_if<cast::Died>(&note)) {
        combat.died(*died, people.self_id());
        return;
    }
    if (const auto* vanish = std::get_if<cast::Vanish>(&note)) {
        combat.vanished(vanish->id);
        return;
    }
    if (std::holds_alternative<cast::Arrive>(note)) {
        chase_leg.reset();
        hit_window.reset();
        combat.leave();
    }
}

// ---- việc người chơi làm ----

void Display::State::send_say(const tk::Say& say) {
    if (is_fight_demo()) {
        answer_fight_demo(say);
        return;
    }
    const std::scoped_lock<std::mutex> locked(talk_guard);
    if (talk_says.size() >= kMaxTalkNotes) talk_says.erase(talk_says.begin());
    talk_says.push_back(say);
}

// Phím ô thao tác: ra chiêu lên mục tiêu đang chọn (không có thì lên điểm đất dưới chuột, không có nữa thì chỗ đứng). Đang đi,
// nhảy hay giữa đòn chưa tới BreakTime thì bỏ phím, như chơi tại chỗ.
void Display::State::press_slot(std::uint32_t slot) {
    if (combat.is_dead()) {
        if (slot < 2) send_say(tk::Revive{.place = slot == 0 ? tk::Place::kTown : tk::Place::kHere});
        return;
    }
    const bool is_busy = is_player_running || jump.is_jumping || (player && player->is_locked(frame_time));
    if (is_busy || slot >= hero.skills.size() || ground == nullptr || !scale_ok(ground->file)) return;
    const std::uint32_t skill = hero.skills.at(slot);
    if (skill > UINT16_MAX) return;
    const core::GroundPoint here = game_of(ground->file, walk);
    fight::Aim aim{.target = 0, .x = here.x, .z = here.z};
    const std::optional<std::uint32_t> chosen = combat.target();
    const cast::Actor* target = chosen ? people.find(*chosen) : nullptr;
    const std::optional<core::GroundPoint> cursor = pick_at(pointer);
    if (target != nullptr) aim = fight::Aim{.target = target->id, .x = target->x, .z = target->z};
    if (target == nullptr && cursor) aim = fight::Aim{.target = 0, .x = cursor->x, .z = cursor->z};
    const std::optional<tk::Cast> asked = combat.cast(static_cast<std::uint16_t>(skill), frame_time, aim);
    if (asked) send_say(*asked);
}

// Máy chủ đã nhận chiêu của mình: quay mặt về chỗ nhắm rồi chọn bước bằng cùng accept_strike với chơi tại
// chỗ. Đang khoá thì không đụng chuỗi (lệnh bị bỏ, như phím lúc chưa tới BreakTime). Hoãn tới hết clip thì
// chưa có mốc trúng của bước mới.
void Display::State::play_peer_cast(const cast::Casting& casting) {
    const auto slot = peers.find(casting.source);
    if (slot == peers.end() || slot->second.is_broken) return;
    slot->second.pending_skill = casting.skill;
}

std::chrono::milliseconds Display::State::play_confirmed(const cast::Casting& casting) {
    constexpr std::chrono::milliseconds kNone{0};
    if (!player || ground == nullptr || !scale_ok(ground->file)) return kNone;
    const core::GroundPoint here = game_of(ground->file, walk);
    core::GroundPoint toward{.x = casting.x, .z = casting.z};
    if (const cast::Actor* target = casting.target != 0 ? people.find(casting.target) : nullptr) {
        toward = core::GroundPoint{.x = target->x, .z = target->z};
    }
    const bool is_apart = std::hypot(toward.x - here.x, toward.z - here.z) > 0.01F;
    if (is_apart) facing = motion::face_angle(here, toward);
    if (player->is_locked(frame_time)) return kNone;
    const std::optional<std::uint32_t> step = player->accept_strike(casting.skill, strike_dice(), frame_time);
    if (!step) {
        if (is_fight_demo() && casting.skill != 0) {
            std::println(stderr, "Đòn: skill {} không có clip phát được", casting.skill);
        }
        return kNone;
    }
    skill_banner.text.clear();
    if (casting.skill != 0 && hud != nullptr) {
        const std::string_view title = hud->skill_name(casting.skill);
        if (!title.empty()) {
            skill_banner.text.assign(prefix_codes(title, kBannerCodes));
            skill_banner.from = frame_time;
        }
    }
    const StrikeCall call{.skill = casting.skill, .step = *step};
    strike_begun = call;
    return player->hit_after(call);
}

// Một khung đánh tự động. Tới tầm thì đứng lại (bỏ lệnh đi) rồi ra chiêu mỗi khi hết bận; chưa tới thì đi tới mục tiêu, tìm
// đường lại theo nhịp thay vì mỗi khung.
void Display::State::pursue_target(core::Clock::time_point now, const Steering& keys) {
    if (!is_online_play || !combat.is_engaged()) return;
    // --skill chưa bấm, hoặc đang trong 2,5 s của clip: không đi và không ra đòn thường, kẻo đè tuyệt chiêu.
    const bool waits = auto_strike_from != 0 && skill_id && *skill_id > 0 && !ultimate_sent;
    if (waits || frame_time < auto_still_until) {
        order.reset();
        chase_leg.reset();
        return;
    }
    const bool is_steering = keys.has_walk && (keys.walk_forward != 0.0F || keys.walk_right != 0.0F);
    if (is_steering || tilt.has_value() || ground == nullptr || !scale_ok(ground->file)) {
        combat.disengage();
        chase_leg.reset();
        return;
    }
    const std::optional<std::uint32_t> chosen = combat.target();
    const cast::Actor* target = chosen ? people.find(*chosen) : nullptr;
    const core::GroundPoint here = game_of(ground->file, walk);
    std::optional<float> distance;
    if (target != nullptr) distance = std::hypot(target->x - here.x, target->z - here.z);
    const bool is_busy = is_player_running || jump.is_jumping || (player && player->is_locked(now));
    const fight::Pursuit step = combat.pursue(now, distance, is_busy);
    if (!step.is_approaching) {
        chase_leg.reset();
        order.reset();
        if (step.order) send_say(*step.order);
        return;
    }
    const core::GroundPoint goal{.x = target->x, .z = target->z};
    const core::Clock::time_point since = chase_leg ? chase_leg->since : now;
    if (now - since > kChasePatience) {
        combat.disengage();
        chase_leg.reset();
        order.reset();
        return;
    }
    const bool is_fresh = chase_leg && now - chase_leg->at < kChaseRepath &&
        std::hypot(goal.x - chase_leg->point.x, goal.z - chase_leg->point.z) < kChaseDrift;
    if (is_fresh) return;
    order_move(goal, nav::MoveMode::kFind);
    chase_leg = ChaseLeg{.point = goal, .at = now, .since = since};
}

// ---- chữ bay ----

std::optional<ogre::Vec3> Display::State::head_of(std::uint32_t id) const {
    if (id == 0 || !terrain || ground == nullptr || !scale_ok(ground->file)) return std::nullopt;
    ogre::Vec3 spot = foot();
    if (id != people.self_id()) {
        const cast::Actor* actor = people.find(id);
        if (actor == nullptr) return std::nullopt;
        spot = world_foot(*actor);
    }
    spot.y += kFloatHead * ground->file.scale.x;
    return spot;
}

// Số bay và lời nhắc hồi sinh nối vào cuối bảng đo: cùng một lô quad chữ (phông Hán của giao diện), vẽ trong lượt của HUD.
void Display::State::build_extras() {
    combat.expire(frame_time);
    if (!hud || procedure != Procedure::kPlay || !is_online_play || !has_lens || !terrain) return;
    if (ground == nullptr || !scale_ok(ground->file)) return;
    const ui::Hud::ExtraFont face = hud->extra_font();
    if (face.font == nullptr) return;
    const auto width = static_cast<float>(screen->width());
    const auto height = static_cast<float>(screen->height());
    const float unit = ground->file.scale.x;
    std::vector<render::UiVertex>& out = pace_board.vertices;
    const core::GroundPoint here = game_of(ground->file, walk);
    const float name_h = static_cast<float>(face.font->pixel_size()) * kPlateNameScale;
    const auto plate_of = [&](const cast::Actor& actor) -> std::optional<PlateAt> {
        if (!shows_plate(actor.kind) || actor.pose == cast::Pose::kDead) return std::nullopt;
        const auto slot = creatures.find(actor.id);
        if (slot == creatures.end()) return std::nullopt;
        ogre::Vec3 spot = world_foot(actor);
        spot.y += slot->second.actor.board_lift(ground->file.scale.y);
        return plate_screen(actor, creature_tables.get(), spot, here, lens, width, height, *face.font);
    };
    const std::size_t bars_at = out.size();
    for (const cast::Actor& actor : people.actors()) {
        const std::optional<PlateAt> plate = plate_of(actor);
        if (!plate) continue;
        paint_bar(*plate, name_h, out);
    }
    push_extra(out, pace_board.batches, bars_at, render::kUiWhite);
    const std::size_t first = out.size();
    const auto life_ms = static_cast<float>(fight::kFloatLife.count());
    for (const fight::Float& shown : combat.floats()) {
        if (frame_time < shown.due) continue;
        has_floated = true;
        const std::optional<ogre::Vec3> top = head_of(shown.target);
        if (!top) continue;
        const float age_ms = std::chrono::duration<float, std::milli>(frame_time - shown.due).count();
        const float progress = std::clamp(age_ms / life_ms, 0.0F, 1.0F);
        const ogre::Vec3 above{.x = top->x, .y = top->y + (kFloatRise * unit * progress), .z = top->z};
        const std::optional<control::ScreenPoint> at = control::project_point(lens, above);
        if (!at) continue;
        const std::int64_t lane = shown.due.time_since_epoch().count() % kLanes;
        const float scale = shown.is_critical ? kCriticalScale : kNormalScale;
        const float fade = progress < kFadeFrom ? 1.0F : (1.0F - progress) / (1.0F - kFadeFrom);
        const std::uint32_t ink = with_alpha({.colour = ink_of(shown, shown.target == people.self_id()), .alpha = fade});
        const float centre = (at->x * width) + (static_cast<float>(lane - 1) * kLaneWidth);
        const Line line{.centre = centre, .top = at->y * height, .scale = scale};
        put_line(*face.font, text_of(shown), line, ink, out);
    }
    if (combat.is_dead()) {
        const float step = static_cast<float>(face.font->pixel_size()) * kCriticalScale;
        put_line(*face.font, kDeadTitle, Line{.centre = width * 0.5F, .top = height * kDeadLine, .scale = kCriticalScale}, kHurtInk, out);
        put_line(*face.font, kDeadHint, Line{.centre = width * 0.5F, .top = (height * kDeadLine) + step + 6.0F, .scale = kNormalScale},
            0xFFFFFFFFU, out);
    }
    for (const cast::Actor& actor : people.actors()) {
        const std::optional<PlateAt> plate = plate_of(actor);
        if (!plate) continue;
        paint_name(*plate, *face.font, out);
    }
    if (!skill_banner.text.empty()) {
        const auto age = frame_time - skill_banner.from;
        const bool is_over = age >= kBannerLife;
        if (is_over) skill_banner.text.clear();
        const auto hold = kBannerLife - kBannerFade;
        float banner_alpha = 1.0F;
        if (!is_over && age > hold) {
            banner_alpha = static_cast<float>((kBannerLife - age).count()) / static_cast<float>(kBannerFade.count());
        }
        const std::optional<ogre::Vec3> crown = head_of(people.self_id());
        ogre::Vec3 above = crown ? *crown : ogre::Vec3{};
        above.y += kBannerLift * unit;
        const std::optional<control::ScreenPoint> banner_at = crown ? control::project_point(lens, above) : std::nullopt;
        if (!is_over && banner_at) {
            const std::uint32_t ink = with_alpha({.colour = kBannerInk, .alpha = banner_alpha});
            put_line(*face.font, skill_banner.text,
                Line{.centre = banner_at->x * width, .top = banner_at->y * height, .scale = kBannerScale}, ink, out);
        }
    }
    push_extra(out, pace_board.batches, first, face.texture);
}

} // namespace game::client
