// Các bảng của sách võ công client 2026 mà client tự viết đọc lúc chạy: kỹ năng (Table/skills.tsv từ
// Config/SkillTemplate_V1.txt), số liệu theo bậc (skill_levels.tsv từ SkillData_V1.txt), tâm pháp
// (inner_arts.tsv từ XinFa_V1.txt), giá lên cấp tâm pháp (inner_art_learn_costs.tsv từ
// XinFaStudySpend_V1.txt), kỹ năng sống (life_skills.tsv từ Ability.txt), bảng lên cấp của kỹ năng
// sống (life_skill_levels.tsv gộp từ Config/AbilityLevelUp), số liệu trận pháp theo cấp
// (formation_levels.tsv từ ZhenFaStr.txt) và bảng tra icon (icons.tsv). Bảy bảng đầu do
// TOOLS/content/export_config.py xuất, bảng icon do TOOLS/content/export_icons.py.
// Nghĩa của từng cột và các hàm tra port từ mã máy Game.exe và UI_CEGUI.dll 2026, địa chỉ và mã giả
// ở docs/NHIEM-VU-VO-CONG-2026.md. Logic thuần, không I/O; số nguyên là 32 bit có dấu như mã gốc.
#pragma once

#include "table/tsv.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::skill {

// Ô của bảng gốc mang nghĩa "không có" (không tâm pháp, không dòng số liệu).
inline constexpr std::int32_t kNone = -1;
// Môn phái "chưa nhập môn" của máy chủ gốc.
inline constexpr std::int32_t kNoSect = 9;
// Số bậc số liệu của một kỹ năng: cột 48..78 của bảng gốc, bậc = cấp tâm pháp / 10.
inline constexpr std::size_t kDataTiers = 31;
// Số tâm pháp có giá trong bảng giá lên cấp: id 0..120.
inline constexpr std::size_t kCostArts = 121;
// Số trận pháp và số ô số liệu của một cấp trận pháp (cột 1..10 của ZhenFaStr).
inline constexpr std::size_t kFormations = 4;
inline constexpr std::size_t kFormationValues = 10;

// Một dòng SkillTemplate_V1. level_offset (cột 11) cộng vào cấp tâm pháp trước khi tính bậc số liệu;
// must_learn (cột 30) nhỏ hơn 1, hay column_101 bằng 2, thì nhân vật nào cũng coi như đã học.
struct SkillRow {
    std::int32_t id = 0;
    std::int32_t sect = kNone;
    // Cấp tâm pháp phải đạt (cột 4) của tâm pháp inner_art (cột 10).
    std::int32_t inner_art_level = 0;
    std::int32_t inner_art = kNone;
    std::int32_t level_offset = 0;
    std::int32_t user_class = 0;
    std::int32_t passivity = 0;
    std::int32_t must_learn = 0;
    std::int32_t column_101 = 0;
    // id dòng skill_levels theo bậc; kNone là không có.
    std::array<std::int32_t, kDataTiers> data{};
    std::string name;
    std::string icon;
    std::string explain;
};

// Một dòng SkillData_V1: chỉ giữ mô tả theo bậc (cột 2), thứ duy nhất sách võ công đọc.
struct LevelRow {
    std::int32_t id = 0;
    std::string description;
};

// Một dòng XinFa_V1. explain có đúng một "%d" (trần cấp, điền lúc hiện); need_level là cấp nhân vật
// phải đạt.
struct InnerArtRow {
    std::int32_t id = 0;
    std::int32_t sect = kNone;
    std::int32_t need_level = 0;
    std::string name;
    std::string explain;
    std::string icon;
};

// Tiền và kinh nghiệm để một tâm pháp lên một cấp.
struct LearnCost {
    std::int32_t money = 0;
    std::int32_t exp = 0;
};

// Một dòng XinFaStudySpend_V1: giá lên cấp level của từng tâm pháp, ô thứ k là tâm pháp id k.
struct LearnCostRow {
    std::int32_t level = 0;
    std::array<LearnCost, kCostArts> costs{};
};

// Một dòng Ability. popup: 1 là có giao diện chế tạo, 2 là khảm; consume là loại tiêu hao;
// level_table là tên bảng lên cấp.
struct LifeSkillRow {
    std::int32_t id = 0;
    std::int32_t max_level = 0;
    std::int32_t popup = 0;
    std::int32_t consume = 0;
    std::string name;
    std::string level_table;
    std::string icon;
    std::string explain;
};

// Một dòng của một bảng lên cấp kỹ năng sống: bảng table, cấp level, trần độ thuần thục nhân 100.
struct LifeLevelRow {
    std::string table;
    std::int32_t level = 0;
    std::int32_t limit_exp = 0;
};

// Một dòng ZhenFaStr: số liệu mà mô tả của bốn trận pháp điền ở một cấp, theo thứ tự cột của bảng
// gốc (trận 1: ô 0 và 1; trận 2: ô 2 và 3; trận 3: ô 4 và 5; trận 4: ô 6 tới 9).
struct FormationRow {
    std::int32_t level = 0;
    std::array<std::int32_t, kFormationValues> values{};
};

// Một icon và bộ ảnh chứa nó.
struct IconRow {
    std::string icon;
    std::string imageset;
};

using SkillRows = std::expected<std::vector<SkillRow>, std::string>;
using LevelRows = std::expected<std::vector<LevelRow>, std::string>;
using InnerArtRows = std::expected<std::vector<InnerArtRow>, std::string>;
using LearnCostRows = std::expected<std::vector<LearnCostRow>, std::string>;
using LifeSkillRows = std::expected<std::vector<LifeSkillRow>, std::string>;
using LifeLevelRows = std::expected<std::vector<LifeLevelRow>, std::string>;
using FormationRows = std::expected<std::vector<FormationRow>, std::string>;
using IconRows = std::expected<std::vector<IconRow>, std::string>;

// Tám bộ đọc. Lỗi là câu của bộ đọc bảng (thiếu cột, ô không phải số nguyên). Các dòng trả về xếp
// tăng dần theo khoá (id hay cấp; bảng lên cấp theo tên bảng rồi cấp; icon theo byte của tên),
// khoá lặp thì giữ dòng gặp trước như bảng DBC của client gốc. Riêng bảng giá giữ thứ tự của tệp:
// mã gốc quét nó từ dòng đầu. O(số dòng x số cột đọc x số cột của bảng); bảng lớn nhất là
// skill_levels, 20667 dòng.
[[nodiscard]] SkillRows read_skills(const table::Tsv& table);
[[nodiscard]] LevelRows read_skill_levels(const table::Tsv& table);
[[nodiscard]] InnerArtRows read_inner_arts(const table::Tsv& table);
[[nodiscard]] LearnCostRows read_learn_costs(const table::Tsv& table);
[[nodiscard]] LifeSkillRows read_life_skills(const table::Tsv& table);
[[nodiscard]] LifeLevelRows read_life_levels(const table::Tsv& table);
[[nodiscard]] FormationRows read_formation_levels(const table::Tsv& table);
[[nodiscard]] IconRows read_icons(const table::Tsv& table);

// Các bảng đã đọc. Hàm tra đòi mỗi bảng đúng thứ tự mà bộ đọc trả về.
struct Tables {
    std::vector<SkillRow> skills;
    std::vector<LevelRow> levels;
    std::vector<InnerArtRow> inner_arts;
    std::vector<LearnCostRow> learn_costs;
    std::vector<LifeSkillRow> life_skills;
    std::vector<LifeLevelRow> life_levels;
    std::vector<FormationRow> formations;
    std::vector<IconRow> icons;
};

// Một tâm pháp hay một kỹ năng sống ở một cấp: đối số của các hàm tra theo cấp.
struct AtLevel {
    std::int32_t id = 0;
    std::int32_t level = 0;
};

// Dòng mang id (Search_Index_EQU của bảng gốc); nullptr khi bảng không có. O(log số dòng).
[[nodiscard]] const SkillRow* skill_row(const Tables& tables, std::int32_t id) noexcept;
[[nodiscard]] const LevelRow* level_row(const Tables& tables, std::int32_t id) noexcept;
[[nodiscard]] const InnerArtRow* inner_art_row(const Tables& tables, std::int32_t id) noexcept;
[[nodiscard]] const LifeSkillRow* life_skill_row(const Tables& tables, std::int32_t id) noexcept;
// Dòng số liệu trận pháp của cấp level; nullptr khi bảng không có cấp đó.
[[nodiscard]] const FormationRow* formation_row(const Tables& tables, std::int32_t level) noexcept;

// Các số mà mô tả của trận pháp thứ formation (0..3) điền, theo thứ tự chỗ điền %s0, %s1..., như
// Player:GetStrZhenfaSkill (0x14039a3a0) lấy từ một dòng ZhenFaStr; rỗng khi formation ngoài 0..3.
[[nodiscard]] std::span<const std::int32_t> formation_values(const FormationRow& row, std::size_t formation) noexcept;

// Giá để tâm pháp ask.id lên cấp ask.level, như GetUplevelXinfaSpendMoney (0x140233d00) và
// GetUplevelXinfaSpendExp (0x140233f60): dòng đầu tiên của bảng có cấp đó. nullopt khi không có
// dòng nào (script nhận -1). O(số dòng của bảng giá), 302 dòng.
// Khác gốc: id ngoài 0..120 cũng là nullopt; mã gốc không kiểm và đọc tràn khỏi bản ghi.
[[nodiscard]] std::optional<LearnCost> learn_cost(const Tables& tables, const AtLevel& ask) noexcept;

// Trần độ thuần thục của kỹ năng sống ask.id ở cấp ask.level, như
// LifeAbility:GetLifeAbility_LimitExp (0x14034d6a0): ô limit_exp của bảng lên cấp chia 100 (chia có
// dấu). Không có kỹ năng, không có bảng lên cấp hay bảng không có cấp đó thì -1.
[[nodiscard]] std::int32_t life_limit_exp(const Tables& tables, const AtLevel& ask) noexcept;

// Tên đầy đủ của một icon, như CUIIconsManager::GetIconFullName của UI_CEGUI.dll (0x18001c6b0):
// "set:<bộ ảnh> image:<icon>"; icon không có trong bảng thì đúng chuỗi "set:X image:X" của mã gốc.
// Khác gốc: không cắt ở 260 byte (tên dài nhất của bảng ngắn hơn nhiều).
[[nodiscard]] std::string icon_full_name(std::span<const IconRow> icons, std::string_view icon);

// Mô tả của một tâm pháp với trần cấp cap điền vào chỗ "%d" đầu tiên, như _snprintf của
// Player:GetXinfaInfo(id, "explain") (0x14038a333).
// Khác gốc: chỉ điền "%d" đầu tiên, mọi ký tự khác giữ nguyên (cả 120 dòng của bảng có đúng một
// "%d" và không có "%" nào khác); không cắt ở 1024 byte (dòng dài nhất 249 byte).
[[nodiscard]] std::string fill_cap(std::string_view explain, std::int32_t cap);

} // namespace game::skill
