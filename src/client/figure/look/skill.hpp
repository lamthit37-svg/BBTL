/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/skill.hpp
 *  PHÂN HỆ   : Figure / Look / Skill
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Năm bảng đòn đánh và tuyệt chiêu của người chơi (Table/skill_*.tsv do
 *    TOOLS/content/export_skills.py sinh): skill_moves (skill sang các bước,
 *    mỗi bước một hành động cơ sở: SkillTemplate_V1 cột 18), skill_actions
 *    (hành động cơ sở sang tên kịch bản theo giới và loại vũ khí: ActionSet,
 *    ActionSetLine, ActionSetKV), skill_scripts (kịch bản của Effect/all.skill:
 *    animation, BreakTime, HitTime, ShakeTime), skill_events (khối con
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// AnimEffect, Ribbon, Sound, SceneLight của kịch bản) và skill_clips (animation sang tệp .skeleton). Id giữ số của
// Config client 2026; tên kịch bản, điểm gắn, effect, âm thanh giữ đúng chữ của kho gốc. Hành động cơ sở là của
// action set CỦA NHÂN VẬT (cùng chuỗi tra với đứng, chạy ở appearance.hpp), nên loại vũ khí không có động tác riêng
// thì dùng dòng tay không, như resolve ở look.hpp. Nguồn: tra theo CObject_Character::SetCurrentSkill/ChangeAction và
// WXSkill của ref; khối kịch bản đọc bằng cùng máy trạng thái dòng với export_look.read_skills. Khác gốc: bảng TSV
// thay cho DBC/script đã nấu.

#pragma once

#include "look/appearance.hpp"
#include "look/look.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// kShake không có trong bảng: mốc ShakeTime của kịch bản, nơi vẽ rung camera. Bốn giá trị đầu là khối con.
enum class EventKind : std::uint8_t { kAnimEffect, kRibbon, kSound, kSceneLight, kShake };

// m_nSkillActionType (ENUM_SKILL_ACTION_TYPE của ref): cách chọn bước của skill nhiều bước. kRandom là
// NONE (rand() % số bước). kLinkedEx là CONCATENATION_EX, kLinked là CONCATENATION. Chú thích gốc ghi
// (1,2,2,2,2,3) và (1,2,3,1,2,3); toán tử trong Start_MagicSend không phát đúng chuỗi đó (xem accept_chain).
enum class ActionKind : std::uint8_t { kRandom, kLinkedEx, kLinked };

// Trần số bước một skill. Start_MagicSend giữ m_nActionCount kiểu INT; skill của client nằm dưới trần này.
// Quá trần thì không phát: không để chỉ số bước tràn khi cộng.
inline constexpr std::int32_t kMaxChainSteps = 64;

// Trạng thái CHARACTER_LOGIC_SKILL_SEND cho một người. index là m_nActionIndex thô, không phải ô trong
// danh sách sau GetRandAnim (index 1 với một bước thì ô phát là 0).
struct Chain {
    std::uint32_t skill = 0;
    ActionKind kind = ActionKind::kRandom;
    std::int32_t index = 0;
    std::int32_t count = 0;
    bool in_send = false;
    bool do_next = false;
};

// Một lần Start_MagicSend hoặc FreshAnimation đã chọn ô trong danh sách bước. plays sai thì chưa phát
// (m_bDoNextAction_Concatenation): clip đang chạy tiếp, hết clip thì finish_chain.
struct ChainPick {
    bool plays = false;
    std::uint32_t slot = 0;
};

// GetRandAnim: index <= 0 lấy phần tử 0, không thì index % số bước. count > 0.
[[nodiscard]] constexpr std::uint32_t chain_slot(std::int32_t index, std::int32_t count) noexcept {
    if (count <= 0 || index <= 0) return 0;
    return static_cast<std::uint32_t>(index % count);
}

// Start_MagicSend, nhánh chọn bước. roll chỉ dùng cho kRandom (giá trị rand() của nơi gọi). anim_ended là
// IsAnimationEnd() lúc nhận lệnh: liên hoàn cùng skill mà clip chưa hết thì hoãn và tăng chỉ số một lần;
// clip đã hết thì phát ngay sau đúng một lần tăng. Khác gốc: count <= 0 hoặc quá kMaxChainSteps thì không
// đụng trạng thái (gốc với count 0 vẫn vào SKILL_SEND rồi GetRandAnim trả 0); roll do nơi gọi đưa vào thay
// rand() toàn cục; không giữ SKILL_SEND thêm 500 ms sau hết clip vì lệnh xử lý ngay trong khung nhấn.
[[nodiscard]] constexpr ChainPick accept_chain(Chain& chain, std::uint32_t skill, ActionKind kind, std::int32_t count,
    std::uint32_t roll, bool anim_ended) noexcept {
    if (count <= 0 || count > kMaxChainSteps) return {};
    const bool was_same = chain.in_send && chain.skill == skill;
    chain.skill = skill;
    chain.kind = kind;
    chain.do_next = false;
    chain.count = count;
    bool play = true;
    if (kind == ActionKind::kLinked) {
        if (was_same) {
            ++chain.index;
            if (chain.index >= count) chain.index = 0;
            play = false;
        } else {
            chain.index = 0;
        }
    } else if (kind == ActionKind::kLinkedEx) {
        if (was_same) {
            ++chain.index;
            if (chain.index >= count - 1) chain.index = 1;
            play = false;
        } else {
            chain.index = 0;
        }
    } else {
        chain.index = static_cast<std::int32_t>(roll % static_cast<std::uint32_t>(count));
    }
    chain.in_send = true;
    if (!play && !anim_ended) {
        chain.do_next = true;
        return {};
    }
    return ChainPick{.plays = true, .slot = chain_slot(chain.index, count)};
}

// FreshAnimation khi đang SKILL_SEND và cờ nối bật: tăng chỉ số lần nữa rồi phát. Không có cờ thì không
// đụng chỉ số. Kể cả kRandom nếu cờ lỡ bật (gốc vẫn ChangeAction, không tăng).
[[nodiscard]] constexpr ChainPick finish_chain(Chain& chain) noexcept {
    if (!chain.do_next || chain.count <= 0) return {};
    chain.do_next = false;
    if (chain.kind == ActionKind::kLinked) {
        ++chain.index;
        if (chain.index >= chain.count) chain.index = 0;
    } else if (chain.kind == ActionKind::kLinkedEx) {
        ++chain.index;
        if (chain.index >= chain.count - 1) chain.index = 1;
    }
    return ChainPick{.plays = true, .slot = chain_slot(chain.index, chain.count)};
}

// Hết đòn hoặc bị đi ngắt: không còn SKILL_SEND. Chỉ số cũ không dùng cho lần sau vì lần sau không phải
// cùng phiên.
constexpr void stop_chain(Chain& chain) noexcept {
    chain.in_send = false;
    chain.do_next = false;
}

// LogicModel::_handleSkillHitTime / BreakTime / ShakeTime: mốc trong [0, 1] vừa đi qua (before, after).
// Clip không lặp thì after >= before. Nhánh after < before là clip vừa quay vòng.
[[nodiscard]] constexpr bool moment_due(float mark, float before, float after) noexcept {
    if (!(mark >= 0.0F) || mark > 1.0F) return false;
    const bool forward = after >= before && mark >= before && mark < after;
    const bool wrapped = after < before && (mark >= before || mark < after);
    return forward || wrapped;
}

// Liên hoàn 3 bước, lệnh tới khi clip chưa hết: phát 0 rồi 2 (tăng một lần lúc nhận, một lần lúc hết clip).
[[nodiscard]] constexpr bool chain_skips_middle() noexcept {
    Chain chain;
    const ChainPick first = accept_chain(chain, 7, ActionKind::kLinked, 3, 0, true);
    const ChainPick held = accept_chain(chain, 7, ActionKind::kLinked, 3, 0, false);
    const ChainPick done = finish_chain(chain);
    return first.plays && first.slot == 0 && !held.plays && chain.do_next == false && done.plays && done.slot == 2;
}

[[nodiscard]] constexpr bool random_picks_remainder() noexcept {
    Chain chain;
    const ChainPick pick = accept_chain(chain, 1, ActionKind::kRandom, 3, 5, false);
    Chain empty;
    const ChainPick none = accept_chain(empty, 1, ActionKind::kRandom, 0, 1, false);
    return pick.plays && pick.slot == 2 && !none.plays && !empty.in_send;
}

static_assert(chain_skips_middle());
static_assert(random_picks_remainder());
static_assert(moment_due(0.5F, 0.2F, 0.8F) && !moment_due(0.8F, 0.2F, 0.8F));
static_assert(!moment_due(-1.0F, 0.0F, 1.0F));

struct MoveRow {
    std::uint32_t skill = 0;
    std::string name;
    std::uint32_t step = 0;
    // Hành động cơ sở (khoá của ActionSet), không phải id của CharActionSet.
    std::uint32_t action = 0;
    ActionKind kind = ActionKind::kRandom;
    // m_nSendTime (ms): thời gian phát đòn; clip dài hơn thì chạy nhanh lên cho vừa (Start_MagicSend, 2026).
    std::uint32_t send_ms = 0;
};

struct ActionRow {
    Race race = Race::kFemale;
    std::uint32_t action = 0;
    Weapon weapon = Weapon::kNone;
    // Tên kịch bản của all.skill, hay chính tên animation khi tên không phải kịch bản.
    std::string script;
};

struct ScriptRow {
    std::string name;
    std::string animation;
    // Mảng mốc như mBreakTimeArray, mHitTimeArray, mShakeTimeArray của WXSkill (ô là các số cách nhau bằng dấu
    // cách): nhiều đòn trúng trong một clip có nhiều mốc. Mỗi mốc là PHẦN của độ dài clip (0..1: LogicModel::execute
    // so TimePosition / getLength). Mốc âm (-1: không có) và ô rỗng cho mảng rỗng.
    std::vector<float> break_times;
    std::vector<float> hit_times;
    std::vector<float> shake_times;
};

// Khối con của kịch bản. rotation theo thứ tự w x y z như OffsetRotation của all.skill.
struct EventRow {
    std::string script;
    std::uint32_t order = 0;
    EventKind kind = EventKind::kAnimEffect;
    // AttachTime: phần của độ dài clip (0..1), như các mốc của kịch bản.
    float time = 0.0F;
    // AttachPoint: tên xương hay tên locator của mẫu nhân vật; rỗng khi khối không gắn đâu (âm thanh).
    std::string point;
    // EffectTemplateName, Material hay SoundName.
    std::string name;
    std::array<float, 3> offset{};
    std::array<float, 4> rotation{1.0F, 0.0F, 0.0F, 0.0F};
    bool is_attached = false;
    // Phần còn lại của khối dạng khoá=giá trị cách nhau bằng "|" (Ribbon: PointCount, LifeTime, ...).
    std::string props;
};

struct SkillClipRow {
    Race race = Race::kFemale;
    std::string animation;
    // Tệp .skeleton dưới Model/ chứa clip, và tên clip trong tệp.
    std::string anim;
    std::string clip;
};

// Cả năm bảng; rỗng là chưa có đòn nào. Mỗi dãy xếp theo khoá của bộ đọc nên tra nhị phân.
struct SkillTables {
    std::vector<MoveRow> moves;
    std::vector<ActionRow> actions;
    std::vector<ScriptRow> scripts;
    std::vector<EventRow> events;
    std::vector<SkillClipRow> clips;
};

// Cột: skill, name, step, action, kind (0..2), send_ms. Khoá (skill, step).
[[nodiscard]] Rows<MoveRow> read_moves(const table::Tsv& table);
// Cột: race (0, 1), action, weapon (none, spear, blade, dual_short, short, fan, ring), script. Khoá (race, action, weapon).
[[nodiscard]] Rows<ActionRow> read_actions(const table::Tsv& table);
// Cột: script, animation, break_time, hit_time, shake_time, repeat. Khoá script.
[[nodiscard]] Rows<ScriptRow> read_scripts(const table::Tsv& table);
// Cột: script, order, kind, time, point, name, px, py, pz, rw, rx, ry, rz, attach, props. Khoá (script, order).
[[nodiscard]] Rows<EventRow> read_events(const table::Tsv& table);
// Cột: race, animation, anim, clip. Khoá (race, animation).
[[nodiscard]] Rows<SkillClipRow> read_skill_clips(const table::Tsv& table);

// Một bước của một skill đã giải cho một người chơi: hành động, kịch bản, clip, mốc thời gian và các khối con
// theo thứ tự trong kịch bản.
struct StrikeEvent {
    EventKind kind = EventKind::kAnimEffect;
    float time = 0.0F;
    std::string point;
    std::string name;
    std::array<float, 3> offset{};
    std::array<float, 4> rotation{1.0F, 0.0F, 0.0F, 0.0F};
    bool is_attached = false;
    std::string props;
};

struct Strike {
    std::uint32_t skill = 0;
    std::uint32_t step = 0;
    std::uint32_t action = 0;
    ActionKind kind = ActionKind::kRandom;
    std::uint32_t send_ms = 0;
    std::string script;
    Clip clip;
    std::vector<float> break_times;
    std::vector<float> hit_times;
    std::vector<float> shake_times;
    std::vector<StrikeEvent> events;
};

// Số bước của skill trong bảng; 0 khi skill không có.
[[nodiscard]] std::size_t step_count(std::span<const MoveRow> moves, std::uint32_t skill);

// Các bước của skill đã giải cho giới race cầm weapon, theo thứ tự bước. Bước nào thiếu hành động, kịch
// bản hay clip của giới này thì bỏ (Strike::step giữ số bước gốc). O(số bước · log n + số khối con).
[[nodiscard]] std::vector<Strike> strikes_of(const SkillTables& tables, Race race, Weapon weapon, std::uint32_t skill);

// Năm bảng trong folder: skill_moves.tsv, skill_actions.tsv, skill_scripts.tsv, skill_events.tsv,
// skill_clips.tsv, theo thứ tự đó, dừng ở bảng hỏng đầu tiên. Tách khỏi load_tables vì chỉ người chơi
// có skill mới cần chúng (ngân sách nạp đầu).
[[nodiscard]] std::expected<SkillTables, std::string> load_skill_tables(std::string_view folder, const ReadFile& read);

} // namespace game::look
