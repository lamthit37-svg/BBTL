// Sách kỹ năng của người chơi như client 2026 giữ trong SDATA_PLAYER_MYSELF (Game.exe, đọc từ mã
// máy; docs/NHIEM-VU-VO-CONG-2026.md): ba std::map theo id, tâm pháp (m_pData+0x6480), kỹ năng
// (+0x6490) và kỹ năng sống (+0x64a0). Mỗi mục nhớ PosIndex là số mục của map ngay trước lúc chèn,
// tức thứ tự lần đầu máy chủ đưa id đó vào; trang sách xếp ô theo số đó chứ không theo id.
// Máy chủ ghi sách bằng gói tin; chưa có máy chủ thì dùng sách của nhân vật mới (newcomer_book).
// Các hàm đọc là điều Player:GetSkillInfo, GetXinfaInfo, GetAbilityInfo trả cho script:
// - GetSkillInfo (0x140389a50) trên SkillView của find_skill: "name", "iconname", "explain",
//   "passivity" là ô name, icon, explain, passivity của row; "learn" là is_learned; "skillnIndex"
//   là pos_index; "skilldata" là skill_data_text; "isequirement" là meets_requirement.
// - GetXinfaInfo (0x140389fc0) trên OwnedInnerArt của find_inner_art và dòng inner_art_row: "name",
//   "iconname", "needlevel" là ô của dòng; "level" là level; "explain" là fill_cap của ô explain với
//   inner_art_cap.
// - GetAbilityInfo (0x140389590) trên OwnedLifeSkill của find_life_skill và dòng life_skill_row:
//   "level", "skillexp", "zhuanjing" là level, exp, mastery; "name", "maxlevel", "iconname",
//   "explain", "popup", "consume" là ô của dòng.
// Khác gốc: không giữ dòng SkillDeplete của từng kỹ năng (m_pDeplete) và id kỹ năng khinh công đang
// dùng (CCharacterData+0x1c): các hàm của sách võ công không đọc chúng.
// Giá trị thuần, không I/O. Mọi hàm nhận tables đòi đúng bộ bảng đã dùng khi ghi sách.
#pragma once

#include "skill/tables.hpp"

#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::skill {

// Một kỹ năng trong sách (SCLIENT_SKILL).
struct OwnedSkill {
    std::int32_t id = 0;
    std::int32_t pos_index = 0;
    bool is_learned = false;
};

// Một tâm pháp trong sách (SCLIENT_SKILLCLASS).
struct OwnedInnerArt {
    std::int32_t id = 0;
    std::int32_t pos_index = 0;
    std::int32_t level = 0;
    bool is_learned = false;
};

// Một kỹ năng sống trong sách (SCLIENT_LIFEABILITY): cấp, độ thuần thục (đã chia 100) và điểm
// chuyên tinh.
struct OwnedLifeSkill {
    std::int32_t id = 0;
    std::int32_t pos_index = 0;
    std::int32_t level = 0;
    std::int32_t exp = 0;
    std::int32_t mastery = 0;
};

// Ba danh sách xếp tăng theo id như ba map của mã gốc; chỉ các hàm dưới đây ghi vào. Số mục của mỗi
// danh sách không vượt số dòng của bảng tương ứng (id không có dòng thì không vào sách).
struct Book {
    std::vector<OwnedSkill> skills;
    std::vector<OwnedInnerArt> inner_arts;
    std::vector<OwnedLifeSkill> life_skills;
};

// Đặt cấp của tâm pháp art.id, như CCharacterData::Set_SkillClass (0x140191320): tâm pháp mới thì
// thêm vào với PosIndex kế tiếp, bảng không có dòng thì bỏ qua; đã học khi cấp lớn hơn 0.
void set_inner_art(Book& book, const Tables& tables, const AtLevel& art);

// Một kỹ năng máy chủ báo và cờ đã học của nó.
struct SkillMark {
    std::int32_t id = 0;
    bool is_learned = false;
};

// Đặt một kỹ năng cho nhân vật của môn phái sect, như CCharacterData::Set_Skill (0x140193f30): kỹ
// năng mới thì thêm vào với PosIndex kế tiếp; bảng không có dòng, hay kỹ năng có tâm pháp mà thuộc
// môn phái khác, thì bỏ qua. Kỹ năng đã có chỉ đổi cờ đã học.
void set_skill(Book& book, const Tables& tables, std::int32_t sect, const SkillMark& mark);

// Thay cả danh sách kỹ năng bằng ids, như bộ xử lý gói danh sách kỹ năng (0x14058d920): xoá sạch
// rồi đặt từng id theo thứ tự trong gói với cờ đã học, nên PosIndex là vị trí trong gói (không tính
// id bị bỏ).
void replace_skills(Book& book, const Tables& tables, std::int32_t sect, std::span<const std::int32_t> ids);

// Một kỹ năng sống máy chủ báo: exp là độ thuần thục thô của gói (nhân 100); level, exp, mastery âm
// là "giữ nguyên" khi kỹ năng đã có.
struct LifeMark {
    std::int32_t id = 0;
    std::int32_t level = 0;
    std::int32_t exp = 0;
    std::int32_t mastery = 0;
};

// Đặt một kỹ năng sống, như CCharacterData::Set_LifeAbility (0x140194d10): exp dương chia 100;
// kỹ năng mới nhận PosIndex kế tiếp, exp và mastery âm thành 0; kỹ năng đã có chỉ đổi số không âm.
// Khác gốc: bảng không có dòng id thì bỏ qua; mã gốc dừng ở assert.
void set_life_skill(Book& book, const Tables& tables, const LifeMark& mark);

// Sách của nhân vật mới theo Config/DefaultChar.ini của máy chủ gốc: kỹ năng 0, 1, 21, 22, 34, 35
// theo đúng thứ tự đó, kỹ năng sống 1, 26, 38, 50, 51 cấp 1 chưa có độ thuần thục, không tâm pháp,
// chưa nhập môn. Thứ tự máy chủ gửi chưa đo được (docs/NGHI-NGO.md).
[[nodiscard]] Book newcomer_book(const Tables& tables);

// Một kỹ năng dưới mắt script: dòng của bảng (không bao giờ nullptr), PosIndex và cờ đã học.
struct SkillView {
    const SkillRow* row = nullptr;
    std::int32_t pos_index = kNone;
    bool is_learned = false;
};

// Kỹ năng id của nhân vật, như CCharacterData::Get_Skill (0x140193c20): kỹ năng không cần học trước
// (must_learn nhỏ hơn 1 hay column_101 bằng 2) thì nhân vật nào cũng có, đã học, PosIndex -1, dù
// sách có nó hay không; kỹ năng khác thì tra sách. nullopt khi không có.
[[nodiscard]] std::optional<SkillView> find_skill(const Book& book, const Tables& tables, std::int32_t id) noexcept;

// Get_SkillClass (0x1401910d0) và Get_LifeAbility (0x140194ac0): chỉ tra sách; nullptr khi không có.
[[nodiscard]] const OwnedInnerArt* find_inner_art(const Book& book, std::int32_t id) noexcept;
[[nodiscard]] const OwnedLifeSkill* find_life_skill(const Book& book, std::int32_t id) noexcept;

// Dòng số liệu của kỹ năng row ở bậc tâm pháp hiện tại, như hàm 0x1401ec780 ("skilldata"): bậc là
// (cấp tâm pháp + level_offset) / 10 % 31 (chia và lấy dư có dấu), không có tâm pháp thì bậc 0; trả
// mô tả của dòng skill_levels mà bậc đó trỏ, không có dòng thì mô tả của kỹ năng. Chuỗi mượn tables.
// Khác gốc: bậc âm (cấp tâm pháp âm) trả mô tả của kỹ năng; mã gốc đọc cột đứng trước cột data_0.
[[nodiscard]] std::string_view skill_data_text(const Book& book, const Tables& tables, const SkillRow& row) noexcept;

// Tâm pháp của kỹ năng row đã đủ cấp chưa ("isequirement"): có tâm pháp đó trong sách và cấp của nó
// không dưới inner_art_level.
[[nodiscard]] bool meets_requirement(const Book& book, const SkillRow& row) noexcept;

// Người học dưới mắt GetXinfaInfo: cấp nhân vật và cờ Is2606S của CDataPool (máy chủ nhẹ).
struct Learner {
    std::int32_t level = 1;
    bool is_light = false;
};

// Trần cấp điền vào mô tả của một tâm pháp (0x14038a2dc..0x14038a30c): 119, nhân vật trên cấp 119
// thì 129; riêng tâm pháp thứ tám (PosIndex 7) là 250 hay 300, và 119 ở máy chủ nhẹ.
[[nodiscard]] constexpr std::int32_t inner_art_cap(const OwnedInnerArt& art, const Learner& who) noexcept {
    constexpr std::int32_t kSeniorLevel = 119;
    constexpr std::int32_t kEighthSlot = 7;
    const bool is_senior = who.level > kSeniorLevel;
    if (art.pos_index != kEighthSlot) return is_senior ? 129 : 119;
    if (who.is_light) return 119;
    return is_senior ? 300 : 250;
}

} // namespace game::skill
