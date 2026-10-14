#pragma once
// Bảng luật chiến đấu nạp một lần từ nội dung TSV rồi chỉ đọc: mẫu kỹ năng, dòng cấp kỹ năng, hiệu ứng (buff và
// tác động tức thời), tập id, ma trận phe, bảng logic kỹ năng và logic hiệu ứng. Lõi thuần: nhận chuỗi, không
// mở tệp, không đồng hồ.
//
// Nguồn: GameServer 2008 Common/Combat/DataRecords.cpp (bố cục SkillTemplate, SkillInstance, StandardImpact,
// IDCollection), Common/Combat/CampAndStand.cpp. Dữ liệu client 2026 thắng mã 2008 ở bố cục cột: bản
// skills.tsv/skill_levels.tsv là của client 2026 (102 và 54 cột), effects.tsv là StandardImpact 76 cột.
// Khác gốc: bố cục đọc theo chỉ số cột đã đối chiếu với dữ liệu thật (docs/SERVER-COMBAT.md mục "Bảng đọc").

#include "actor/sheet.hpp"
#include "combat/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace game::combat {

using actor::LoadError;
using actor::Loaded;

inline constexpr std::size_t kEffectParamCount = 16;  // StandardImpact: 16 ô tham số
inline constexpr std::size_t kSkillParamCount = 15;   // skill_levels.tsv: 15 cặp (mô tả, giá trị)
inline constexpr std::size_t kInnerArtSlots = 16;     // skill_id_at_inner_art_level_1..16
inline constexpr std::size_t kConditionTerms = 3;

// Số hàng tối đa mỗi bảng (chống bảng phình).
inline constexpr std::size_t kMaxSkillRows = 100'000;
inline constexpr std::size_t kMaxLevelRows = 500'000;
inline constexpr std::size_t kMaxEffectRows = 500'000;
inline constexpr std::size_t kMaxCollections = 50'000;
inline constexpr std::int32_t kInvalidId = -1;
inline constexpr std::int32_t kMaxLogicId = 4095;  // số logic kỹ năng/hiệu ứng lớn nhất (bảng tra của Arena là mảng phẳng)

// Loại điều kiện/tiêu hao (ConditionAndDeplete_Core.h). Số nguyên của dữ liệu 2026 có thêm vài loại mà mã
// 2008 không có (13, 15..21): logic điều kiện của bản gốc trả đúng cho loại lạ nên ở đây cũng vậy.
enum class TermKind : std::uint8_t {
    kUnitHaveBuff = 0,       // C_UNIT_MUST_HAVE_IMPACT: bản thân phải có buff trong tập a
    kUnitHpAtMost = 1,       // C_UNIT_HP_MUST_LESS_THAN_BY_RATE: HP không quá a% tối đa
    kTargetHaveBuff = 2,     // C_TARGET_MUST_HAVE_IMPACT
    kTargetLevelAtMost = 3,  // C_TARGET_LEVEL_MUST_LESS_THAN_BY_VALUE (mã 2008 không có thân hàm: luôn qua)
    kManaByValue = 4,        // CD_MANA_BY_VALUE
    kManaByRate = 5,         // CD_MANA_BY_RATE
    kRageByRate = 6,         // CD_RAGE_BY_RATE
    kStrikeBySegment = 7,    // CD_STRIKE_POINT_BY_SEGMENT
    kAllRage = 8,            // D_ALL_RAGE
    kCancelBuffs = 9,        // D_CANCEL_SPECIFIC_IMPACT
    kTargetIsSpouse = 10,    // C_TARGET_MUST_BE_MY_SPOUSE
    kHpByRate = 11,          // CD_HP_BY_RATE
    kHpAtLeast = 12,         // C_HP_BY_RATE
};

struct Term {
    std::int32_t kind = -1;
    std::int32_t first = -1;
    std::int32_t second = -1;

    friend constexpr bool operator==(const Term&, const Term&) noexcept = default;
};

// Một dòng skill_levels.tsv: số liệu của một kỹ năng ở một cấp.
struct SkillLevel {
    std::uint32_t id = 0;
    std::int32_t logic = -1;
    std::int32_t cooldown_ms = 0;      // -1 hoặc 0: không hồi chiêu riêng
    std::int32_t charge_ms = 0;        // thời gian gom khí; <= 0 là tức thời
    std::int32_t channel_ms = 0;       // thời gian dẫn; <= 0 là không dẫn
    std::array<Term, kConditionTerms> terms{};
    std::int32_t target_level = -1;    // -1 không giới hạn cấp mục tiêu
    std::array<std::int32_t, kSkillParamCount> param{};
};

enum class SkillType : std::uint8_t { kCharge = 0, kChannel = 1, kInstant = 2, kPassive = 3 };

enum class SelectType : std::uint8_t { kNone = 0, kCharacter = 1, kPosition = 2, kDirection = 3, kSelf = 4, kHuman = 5 };

// ENUM_TARGET_LOGIC của bản gốc.
enum class TargetLogic : std::uint8_t {
    kSelf = 0,
    kPet = 1,
    kShadowGuard = 2,
    kMaster = 3,
    kAroundSelf = 4,
    kSpecificUnit = 5,
    kAroundUnit = 6,
    kAroundPosition = 7,
};

// Một dòng skills.tsv: mẫu kỹ năng (mọi cấp dùng chung).
struct SkillTemplate {
    std::uint32_t id = 0;
    std::int32_t sect = -1;
    std::int32_t skill_class = -1;           // inner_art_id: tâm pháp mà kỹ năng thuộc về
    bool must_use_weapon = false;
    bool disabled_by_control_1 = false;      // bị cờ CanAction1 chặn
    bool disabled_by_control_2 = false;      // bị cờ CanAction2 chặn
    bool disabled_by_transform = false;      // bị chặn khi đang cưỡi/biến hình (gốc: có MountID)
    SkillType type = SkillType::kInstant;
    std::int32_t cooldown_id = -1;
    std::int32_t target_state = -1;          // 0 mục tiêu phải sống, 1 phải là xác, khác: không xét
    std::int32_t user_class = 0;             // 0 người, 1 quái, 2 thú, 3 vật phẩm
    bool passive = false;
    SelectType select = SelectType::kNone;
    std::int32_t skill_group = -1;
    TargetLogic targeting = TargetLogic::kSelf;
    std::int32_t action_time_ms = 0;
    std::int32_t range_cm = 0;               // tầm xa nhất, centimet; <= 0: không xét tầm
    std::int32_t stand = 0;                  // friendliness: -1 địch, 0 trung lập, 1 thiện
    std::int32_t target_by_stand = -1;       // 0 mục tiêu là bạn, 1 là địch, -1 không xét
    std::int32_t target_by_kind = -1;        // -1 không xét, 0 người, 1 thú, 2 quái
    bool auto_shot = false;
    std::int32_t radius_cm = 0;
    std::int32_t max_targets = 0;            // <= 0: không giới hạn (kMaxScanTargets)
    bool interrupt_auto_shot = false;
    std::int32_t delay_ms = 0;               // trễ từ lúc ra chiêu tới lúc hiệu ứng tới đích
    std::int32_t charges_or_interval = 0;    // số lần phát (tức thời) hoặc chu kỳ dẫn (ms)
    std::int32_t accuracy = -1;              // -1: tính từ hit/miss; 100: luôn trúng
    std::int32_t disrupt_chance = 100;       // % bị làm gián đoạn khi nhận sát thương
    std::int32_t disrupt_time_permille = 0;  // lượng chậm gom khí khi bị gián đoạn, phần nghìn thời gian gom
    std::array<std::uint32_t, kInnerArtSlots> instance{};  // skill_id_at_inner_art_level_N (0 = không có)
};

// Hiệu ứng (StandardImpact): buff kéo dài hoặc tác động tức thời.
struct Effect {
    std::uint32_t id = 0;
    std::int32_t logic = -1;
    bool over_timed = false;
    std::int32_t impact_id = -1;
    std::int32_t mutex_id = -1;
    std::int32_t level = 0;
    std::int32_t stand = 0;                  // -1 địch, 0 trung lập, 1 thiện
    bool keep_on_corpse = false;
    bool dispellable = false;
    bool cancellable = false;
    bool needs_channel = false;
    bool ignore_filter = false;
    bool fade_on_damage = false;
    bool fade_on_action = false;
    bool fade_on_offline = false;
    bool timing_offline = false;
    std::int32_t continuance_ms = 0;         // -1 vô hạn
    std::int32_t interval_ms = 0;
    bool mutex_by_caster = false;
    std::array<std::int32_t, kEffectParamCount> param{};
};

// Loại tập id (IDCollection_T::TYPE_*). Dữ liệu 2026 thêm 6..10; 7..10 là tập id buff.
enum class CollectionKind : std::uint8_t {
    kBuff = 0,
    kMutex = 1,
    kLogic = 2,
    kSkill = 3,
    kSkillLogic = 4,
    kDirect = 5,
    kTrap = 6,
    kBuffAlt7 = 7,
    kBuffAlt8 = 8,
    kBuffAlt9 = 9,
    kBuffAlt10 = 10,
};

struct Collection {
    std::int32_t id = 0;
    std::int32_t kind = 0;
    std::vector<std::int32_t> ids;

    [[nodiscard]] bool contains(std::int32_t value) const noexcept;
    [[nodiscard]] bool is_buff_kind() const noexcept;
};

// Độ trung thực của một logic: full khi hành vi có từ mã nguồn hoặc nghĩa tham số không mơ hồ; core khi chỉ
// phần chính được làm; event khi lõi chỉ phát sự kiện cho module ngoài.
enum class Fidelity : std::uint8_t { kFull, kCore, kEvent };

// Một vai tham số của logic kỹ năng: tham số `param` là id hiệu ứng gửi cho ai và khi nào.
enum class RoleKind : std::uint8_t {
    kTarget,        // mọi mục tiêu bị trúng
    kSelf,          // người ra chiêu, một lần mỗi lượt phát
    kTargetTick,    // như kTarget nhưng ở nhịp dẫn
    kSelfTick,
    kFriend,        // mọi mục tiêu bị trúng là bạn
    kEnemy,         // mọi mục tiêu bị trúng là địch
    kRank,          // mục tiêu thứ `arg` trong danh sách trúng (0 là đầu tiên)
    kRest,          // mọi mục tiêu từ thứ 1
    kFriendRank,    // bạn thứ `arg` trong danh sách trúng
    kEnemyRank,     // địch thứ `arg` trong danh sách trúng
    kFriendRest,    // mọi bạn từ thứ 1
    kEnemyRest,     // mọi địch từ thứ 1
    kSelfMale,      // người ra chiêu là nam
    kSelfFemale,
    kCombo,         // đoạn liên kích `arg` (0..3)
    kTrap,          // đặt bẫy có id dữ liệu = tham số (sự kiện kSpawn)
    kTrapTick,
    kSummon,
    kTotem,
    kDispelSelf,    // gỡ buff thuộc tập id = tham số khỏi người ra chiêu
    kCutCooldown,   // giảm hồi chiêu của nhóm id = tham số, lượng ms ở tham số `aux`
    kSub,           // chỉ ở logic hiệu ứng: tham số là id một hiệu ứng khác mà hiệu ứng này gọi tới
};

struct Role {
    RoleKind kind = RoleKind::kTarget;
    std::uint8_t arg = 0;
    std::int8_t param = 0;       // chỉ số tham số chứa id hiệu ứng (hoặc id dữ liệu)
    std::int8_t chance = -1;     // chỉ số tham số chứa xác suất phần trăm, -1: luôn
    std::int8_t repeat = -1;     // chỉ số tham số chứa số lần lặp, -1: một lần
    std::int8_t aux = -1;        // chỉ số tham số phụ (kCutCooldown: lượng ms), -1: không có

    friend constexpr bool operator==(const Role&, const Role&) noexcept = default;
};

// Dòng trong skill_logics.tsv / effect_logics.tsv.
struct LogicSpec {
    std::int32_t logic = -1;
    std::string handler;
    std::vector<Role> roles;
    Fidelity fidelity = Fidelity::kCore;
    std::string note;
};

// Nội dung TSV của từng bảng; bảng bắt buộc đều phải có.
struct CatalogText {
    std::string_view skills;            // shared/skills.tsv
    std::string_view skill_levels;      // shared/skill_levels.tsv
    std::string_view effects;           // server/effects.tsv
    std::string_view id_collections;    // shared/id_collections.tsv
    std::string_view camp_relations;    // server/camp_relations.tsv
    std::string_view skill_logics;      // server/skill_logics.tsv
    std::string_view effect_logics;     // server/effect_logics.tsv
};

class Catalog {
public:
    Catalog() = default;

    [[nodiscard]] const SkillTemplate* skill(std::uint32_t id) const noexcept;
    [[nodiscard]] const SkillLevel* level(std::uint32_t instance_id) const noexcept;
    // Dòng cấp của kỹ năng `skill_id` ở cấp `level` (1..16); nullptr khi không có.
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): id kỹ năng và cấp khác vai, nơi gọi đặt tên (HP-07)
    [[nodiscard]] const SkillLevel* level_of(std::uint32_t skill_id, std::uint8_t level) const noexcept;
    [[nodiscard]] const Effect* effect(std::uint32_t id) const noexcept;
    [[nodiscard]] const Collection* collection(std::int32_t id) const noexcept;
    [[nodiscard]] const LogicSpec* skill_logic(std::int32_t logic) const noexcept;
    [[nodiscard]] const LogicSpec* effect_logic(std::int32_t logic) const noexcept;

    // Bạn hay địch theo ma trận phe của bản gốc (CalcRelationType): ô khác 0 là bạn; phe lạ là bạn.
    [[nodiscard]] Relation camp_relation(std::int32_t from_camp, std::int32_t to_camp) const noexcept;

    [[nodiscard]] std::size_t skill_count() const noexcept { return skills_.size(); }
    [[nodiscard]] std::size_t level_count() const noexcept { return levels_.size(); }
    [[nodiscard]] std::size_t effect_count() const noexcept { return effects_.size(); }

    // Mọi mẫu kỹ năng, sắp theo id: cho công cụ và test.
    [[nodiscard]] std::span<const SkillTemplate> skills() const noexcept { return skills_; }
    // Mọi dòng bảng logic, sắp theo số logic.
    [[nodiscard]] std::span<const LogicSpec> skill_logics() const noexcept { return skill_logics_; }
    [[nodiscard]] std::span<const LogicSpec> effect_logics() const noexcept { return effect_logics_; }

private:
    friend Loaded<Catalog> load_catalog(const CatalogText& text);

    std::vector<SkillTemplate> skills_;                          // sắp theo id
    std::vector<SkillLevel> levels_;                             // sắp theo id
    std::vector<Effect> effects_;                                // sắp theo id
    std::vector<Collection> collections_;                        // sắp theo id
    std::vector<LogicSpec> skill_logics_;                        // sắp theo logic
    std::vector<LogicSpec> effect_logics_;
    std::vector<std::vector<std::uint8_t>> camp_friend_;         // camp_friend_[a][b] != 0: a coi b là bạn
};

[[nodiscard]] Loaded<Catalog> load_catalog(const CatalogText& text);

// Tên handler logic kỹ năng/hiệu ứng mà mã C++ có. Bảng logic nêu tên lạ thì nạp lỗi.
[[nodiscard]] bool known_skill_handler(std::string_view name) noexcept;
[[nodiscard]] bool known_effect_handler(std::string_view name);  // dựng sổ lần đầu, có thể ném bad_alloc

// "0:target;1:self@2;3:rank1*4;5:cut_cooldown+6" -> danh sách vai. nullopt khi sai cú pháp.
[[nodiscard]] std::optional<std::vector<Role>> parse_roles(std::string_view text);

} // namespace game::combat
