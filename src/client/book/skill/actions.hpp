// Hệ action của client 2026 (CActionSystem của Game.exe, đọc từ mã máy;
// docs/NHIEM-VU-VO-CONG-2026.md), phần mà sách võ công dùng. Mỗi kỹ năng, tâm pháp và kỹ năng sống
// trong sách có một action; ô nút của trang sách giữ id của action, script liệt kê action theo loại
// và PosIndex (EnumAction), đếm theo loại (GetActionNum), hỏi kỹ năng thuộc tâm pháp nào
// (GetOwnerXinfa) và đổi id action về id định nghĩa (LifeAbility:GetLifeAbility_Number). Id lấy từ
// một bộ đếm chung cho mọi loại, nên chỉ là tay cầm: thứ tự tạo quyết định nó.
// CActionSystem::Initial (0x140018750) tạo sẵn, trước mọi action của sách, bốn action thú cưng ở đầu
// trang phổ thông (xuất chiến, nghỉ, phụ thể, phục hồi; lần tạo thứ 17..20) và bốn action trận pháp
// của trang trận pháp (lớp CActionItem_ZhenFaSkill, bốn lần tạo cuối cùng).
// Khác gốc: chỉ có năm loại action trên, nhưng id giữ đúng như khi Initial tạo đủ 1020 action của
// nó (action đầu tiên của sách nhận id 1021); nhánh -8888 của GetOwnerXinfa (ba kỹ năng của vật
// phẩm ở ô trang bị 18) chưa port vì chưa có trang bị.
// Giá trị thuần, không I/O. Mọi hàm nhận book và tables đòi đúng sách và bộ bảng đã dùng khi dựng.
#pragma once

#include "skill/book.hpp"
#include "skill/tables.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>
#include <vector>

namespace game::skill {

// Loại action. Số loại của bảng tên trong Game.exe (0x140ed88d0): "skill" 1, "life" 2, "xinfa" 7,
// "zhenfaskill" 102; action thú cưng không có tên loại.
enum class ActionKind : std::uint8_t { kSkill, kLifeSkill, kInnerArt, kPet, kFormation };

// Bốn action thú cưng theo thứ tự ô 1..4 của trang phổ thông.
enum class PetAction : std::uint8_t { kFight, kRelax, kPossess, kRestore };

inline constexpr std::size_t kPetActions = 4;

// Bốn kỹ năng trận pháp mà Initial tạo action, theo thứ tự ô 1..4 của trang trận pháp.
inline constexpr std::array<std::int32_t, 4> kFormationSkills = {3229, 3250, 3251, 3252};

// Một action: id của nó và id định nghĩa (id kỹ năng, tâm pháp, kỹ năng sống; với action thú cưng
// là số thứ tự của PetAction; với action trận pháp là id kỹ năng).
struct Action {
    std::int32_t id = 0;
    ActionKind kind = ActionKind::kSkill;
    std::int32_t define = kNone;
};

// Id mà CActionSystem::Initial cấp: action thú cưng đầu tiên, action trận pháp đầu tiên, và id kế
// tiếp sau Initial. Hai số sau tính từ số dòng năm bảng mà Initial duyệt (XingZhen, XingZhen_Skill,
// CangPin, Toy, PetNeiDan của client 2026); id chỉ là tay cầm, không nơi nào so nó với hằng.
inline constexpr std::int32_t kFirstPetAction = 17;
inline constexpr std::int32_t kFirstFormationAction = 1017;
inline constexpr std::int32_t kFirstBookAction = 1021;

// Mọi action đang có, xếp tăng theo id như m_mapAllAction, và bộ đếm id (0x140ed8218). Giá trị mặc
// định là trạng thái ngay sau CActionSystem::Initial: bốn action thú cưng và bốn action trận pháp.
// Chỉ ba hàm sync ghi vào; số action không vượt tổng số dòng của ba bảng cộng tám.
struct Actions {
    std::vector<Action> all = {
        Action{.id = kFirstPetAction, .kind = ActionKind::kPet, .define = 0},
        Action{.id = kFirstPetAction + 1, .kind = ActionKind::kPet, .define = 1},
        Action{.id = kFirstPetAction + 2, .kind = ActionKind::kPet, .define = 2},
        Action{.id = kFirstPetAction + 3, .kind = ActionKind::kPet, .define = 3},
        Action{.id = kFirstFormationAction, .kind = ActionKind::kFormation, .define = kFormationSkills[0]},
        Action{.id = kFirstFormationAction + 1, .kind = ActionKind::kFormation, .define = kFormationSkills[1]},
        Action{.id = kFirstFormationAction + 2, .kind = ActionKind::kFormation, .define = kFormationSkills[2]},
        Action{.id = kFirstFormationAction + 3, .kind = ActionKind::kFormation, .define = kFormationSkills[3]},
    };
    std::int32_t next_id = kFirstBookAction;
};

// Dựng lại action của một loại sau khi sách đổi, như UserSkill_Update (0x14001bc50),
// SkillClass_Update (0x14001d6a0) và UserLifeAbility_Update (0x14001c770): gỡ action mà dữ liệu
// không còn (kỹ năng không cần học thì luôn còn), rồi tạo action cho từng mục chưa có, theo id của
// mục tăng dần. Mã gốc gọi SkillClass_Update và UserLifeAbility_Update sau mỗi lần đặt một tâm pháp
// hay kỹ năng sống, và UserSkill_Update một lần sau cả gói danh sách kỹ năng.
void sync_skill_actions(Actions& actions, const Book& book, const Tables& tables);
void sync_inner_art_actions(Actions& actions, const Book& book);
void sync_life_actions(Actions& actions, const Book& book);

// GetActionNum(loại) (0x140017280): số action của loại đó, không xét PosIndex.
[[nodiscard]] std::size_t action_count(const Actions& actions, ActionKind kind) noexcept;

// Một lần hỏi EnumAction(index, loại).
struct ActionAsk {
    ActionKind kind = ActionKind::kSkill;
    std::int32_t index = 0;
};

// EnumAction (0x140017360): action đầu tiên theo id tăng dần có đúng loại và PosIndex bằng
// ask.index; PosIndex là của mục trong sách (kỹ năng không cần học, hay mục không còn, là -1), riêng
// action trận pháp lấy id kỹ năng của nó làm PosIndex (0x14006d020).
// nullptr là action rỗng của mã gốc (GetID() bằng 0). O(số action x log số mục).
// Khác gốc: action trận pháp mà bảng kỹ năng không có dòng thì PosIndex là -1; mã gốc khi đó không
// đặt id kỹ năng cho action và giá trị bộ dựng để lại chưa đọc.
[[nodiscard]] const Action* enum_action(const Actions& actions, const Book& book, const Tables& tables,
    const ActionAsk& ask) noexcept;

// Action mang id (CActionSystem::GetAction, 0x140017160); nullptr khi không có.
[[nodiscard]] const Action* action_by_id(const Actions& actions, std::int32_t id) noexcept;

// Một trong bốn action thú cưng (Pet:GetPetFightAction 0x140379af0 và ba hàm cùng khuôn); nullptr
// khi danh sách không còn nó (mã gốc trả action rỗng).
[[nodiscard]] const Action* pet_action(const Actions& actions, PetAction which) noexcept;

// GetDefineID (0x140013690): id định nghĩa khi mục còn trong sách, không thì -1. Action thú cưng
// thuộc lớp gốc nên là -1; action trận pháp trả id kỹ năng khi bảng kỹ năng có dòng đó
// (0x14006cff0), dù nhân vật có kỹ năng hay không.
[[nodiscard]] std::int32_t define_id(const Action& action, const Book& book, const Tables& tables) noexcept;

// LifeAbility:GetLifeAbility_Number(id action) (0x140346dc0): id định nghĩa của action mang id đó;
// nullopt khi không có action hay id định nghĩa là -1 (script nhận nil).
[[nodiscard]] std::optional<std::int32_t> defined_by(const Actions& actions, const Book& book, const Tables& tables,
    std::int32_t action_id) noexcept;

// Hai giá trị đặc biệt của GetOwnerXinfa.
inline constexpr std::int32_t kNotOwned = -1;
inline constexpr std::int32_t kNoOwnerArt = -9999;

// GetOwnerXinfa (0x1400136d0): id action của tâm pháp mà kỹ năng của action thuộc về. kNotOwned khi
// action không phải kỹ năng, kỹ năng không còn, hay user_class của nó khác 0; kNoOwnerArt khi kỹ
// năng không có tâm pháp hoặc nhân vật chưa có action của tâm pháp ấy (điều kiện để trang phổ thông
// nhận kỹ năng).
[[nodiscard]] std::int32_t owner_inner_art(const Actions& actions, const Book& book, const Tables& tables,
    const Action& action) noexcept;

// Tên icon trần của một action (chuỗi ở CActionItem+0x30): ô icon của dòng định nghĩa (action trận
// pháp: dòng kỹ năng), hay icon cố định của action thú cưng; rỗng khi bảng không có dòng. Tên đầy
// đủ: icon_full_name.
[[nodiscard]] std::string_view action_icon(const Action& action, const Tables& tables) noexcept;

// Icon và khoá từ điển của tên bốn action thú cưng, theo thứ tự PetAction (0x14006476f và các lệnh
// cùng khuôn trong Initial).
struct PetFace {
    std::string_view icon;
    std::string_view name_key;
};

inline constexpr std::array<PetFace, kPetActions> kPetFaces = {{
    {.icon = "PetSkill2_1", .name_key = "Action_Pet_Fight"},
    {.icon = "PetSkill2_2", .name_key = "Action_Pet_Relex"},
    {.icon = "FightSkillXinShou_11", .name_key = "ZSHT_BC_1008_10"},
    {.icon = "FightSkillXinShou_12", .name_key = "ZSHT_BC_1008_11"},
}};

// IsLMSJSecond (0x14023fdf0: id 821..826), IsJYJYSecond (0x14023fe80: 827..834) và IsWJQFSecond
// (0x14023ff10: 4465, 4466) gộp lại: id là bản thứ hai của một kỹ năng. Script luôn hỏi cả ba cùng
// lúc và không liệt kê bản thứ hai ở trang nào.
[[nodiscard]] constexpr bool is_second_form(std::int32_t id) noexcept {
    constexpr std::int32_t kFirstPaired = 821;
    constexpr std::int32_t kLastPaired = 834;
    constexpr std::int32_t kFirstWjqf = 4465;
    constexpr std::int32_t kLastWjqf = 4466;
    if (id >= kFirstPaired && id <= kLastPaired) return true;
    return id >= kFirstWjqf && id <= kLastWjqf;
}

} // namespace game::skill
