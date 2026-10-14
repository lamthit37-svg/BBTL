#pragma once
// Năm bảng đòn đánh và tuyệt chiêu của người chơi (Table/skill_*.tsv do TOOLS/content/export_skills.py sinh):
// skill_moves (skill sang các bước, mỗi bước một hành động cơ sở: SkillTemplate_V1 cột 18), skill_actions
// (hành động cơ sở sang tên kịch bản theo giới và loại vũ khí: ActionSet, ActionSetLine, ActionSetKV),
// skill_scripts (kịch bản của Effect/all.skill: animation, BreakTime, HitTime, ShakeTime), skill_events (khối
// con AnimEffect, Ribbon, Sound, SceneLight của kịch bản) và skill_clips (animation sang tệp .skeleton).
// Id giữ số của Config client 2026; tên kịch bản, điểm gắn, effect, âm thanh giữ đúng chữ của kho gốc.
// Hành động cơ sở là của action set CỦA NHÂN VẬT (cùng chuỗi tra với đứng, chạy ở appearance.hpp), nên loại
// vũ khí không có động tác riêng thì dùng dòng tay không, như resolve ở look.hpp.
// Nguồn: tra theo CObject_Character::SetCurrentSkill/ChangeAction và WXSkill của ref; khối kịch bản đọc
// bằng cùng máy trạng thái dòng với export_look.read_skills. Khác gốc: bảng TSV thay cho DBC/script đã nấu.

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

enum class EventKind : std::uint8_t { kAnimEffect, kRibbon, kSound, kSceneLight };

// m_nSkillActionType (ENUM_SKILL_ACTION_TYPE của ref): cách chọn bước của skill nhiều bước. kRandom: mỗi lần
// dùng chọn ngẫu nhiên một bước (rand() % số bước, như Start_MagicSend). kLinkedEx (1 2 2 2 3) và kLinked
// (1 2 3 1 2 3) là liên hoàn theo lệnh nối tiếp của máy chủ.
enum class ActionKind : std::uint8_t { kRandom, kLinkedEx, kLinked };

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
