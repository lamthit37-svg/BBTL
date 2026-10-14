#pragma once
// Bảng luật của thân thể, nạp một lần từ nội dung TSV rồi chỉ đọc: hệ số gốc và điểm thuộc tính mỗi cấp
// theo môn phái, bảng kinh nghiệm, hệ số suy giảm kinh nghiệm theo chênh cấp, hình phạt chết, luật sinh
// nộ khí theo môn phái, thuộc tính quái. Lõi thuần: nhận chuỗi, không mở tệp, không đồng hồ.
//
// Nguồn: GameServer Main/GameTable.cpp (InitBaseValueTable, InitAttrLevelupTable, InitExpAttTable),
// Main/DiePenaltyManager.cpp, MenPai/*.cpp (nộ khí), InitMonsterAttrExTable. Dữ liệu client 2026 thắng:
// bảng kinh nghiệm 150 cấp và thuộc tính quái lấy từ client.
//
// Môn phái 10..15 chỉ có ở client 2026; bảng hệ số và điểm mỗi cấp của bản gốc chỉ có 10 phái (0..9). Bảng
// sect_templates.tsv (cột basis = made_up) cho mỗi phái mới một phái mẫu để mượn hệ số: số tự đặt, chờ
// chủ dự án duyệt (docs/SERVER-COMBAT.md mục "Số tự đặt").

#include "actor/attr.hpp"
#include "actor/numeric.hpp"
#include "actor/sheet.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::actor {

inline constexpr std::size_t kSectSlots = 16;      // SectId 0..15 (9 là "không phái").
inline constexpr std::size_t kBaseTableSects = 10; // Bảng gốc chỉ có phái 0..9.
inline constexpr std::size_t kBaseInfoCount = 42;  // AINFOTYPE0..41 của BaseValueTable.ini bản dữ liệu hiện hành.
inline constexpr std::uint16_t kWashPointLevel = 60; // DEFAULT_WASHPOINT_LEVEL: từ cấp này điểm cấp-một là điểm tự cộng.

// Chỉ số cột của bảng hệ số gốc. Bố cục là của BaseValueTable.ini đi kèm dữ liệu (0859602, XJL7457), dài
// hơn enum ATTRIBUTEINFO_TYPE của mã 2008 (34 cột): thêm bộ ba hội tâm phòng (33..35), biên độ dao động ở
// 36 (mã 2008 đọc cột 33), tỉ lệ nộ khí (37..39), thế lực và đặc tính tấn công (40, 41). Dữ liệu thắng mã.
enum class BaseInfo : std::uint8_t {
    kBaseHp = 0, kConHp, kLevelHp,
    kBaseHpRestore, kConHpRestore, kLevelHpRestore,
    kBaseMp, kIntMp, kLevelMp,
    kBaseMpRestore, kIntMpRestore, kLevelMpRestore,
    kBaseAttackP, kStrAttackP, kLevelAttackP,
    kBaseAttackM, kSprAttackM, kLevelAttackM,
    kBaseDefenceP, kConDefenceP, kLevelDefenceP,
    kBaseDefenceM, kIntDefenceM, kLevelDefenceM,
    kBaseHit, kDexHit, kLevelHit,
    kBaseMiss, kDexMiss, kLevelMiss,
    kBaseCrit, kDexCrit, kLevelCrit,
    kBaseCritDefence, kDexCritDefence, kLevelCritDefence,
    kAttackFluctuation,   // dao động sát thương +/- phần trăm
    kRageWhenDamaged,     // nộ khí mỗi 1000 điểm sát thương nhận
    kRageWhenDealing,     // nộ khí mỗi 1000 điểm sát thương gây ra
    kRageRegen,           // nộ khí tự hồi mỗi nhịp hồi
    kCamp,                // thế lực mặc định của phái
    kAttackTrait,         // id đặc tính tấn công của phái
};

static_assert(static_cast<std::size_t>(BaseInfo::kAttackTrait) + 1 == kBaseInfoCount, "BaseInfo phải đủ kBaseInfoCount cột");

// Một hàng của bảng hệ số gốc: hệ số của một phái.
using BaseRow = EnumArray<BaseInfo, std::int32_t, kBaseInfoCount>;

// Khi nào nộ khí tăng (các hàm MenPai_T::OnXxx của bản gốc).
enum class RageTrigger : std::uint8_t {
    kDamaged,       // Bị đánh, giá trị là sát thương nhận.
    kDealDamage,    // Đánh trúng, giá trị là sát thương gây ra.
    kStrikeSpent,   // Tiêu điểm liên kích.
    kHealDone,      // Chữa cho người khác, giá trị là HP đã hồi.
    kTrapTriggered, // Bẫy của mình phát nổ, giá trị luôn là 1.
};
inline constexpr std::size_t kRageTriggerCount = 5;
static_assert(static_cast<std::size_t>(RageTrigger::kTrapTriggered) + 1 == kRageTriggerCount);

// nộ khí cộng = value * multiplier / divisor (số nguyên, cắt xuống). multiplier = 0 là phái không sinh nộ
// khí theo sự kiện này. Hai sự kiện kDamaged và kDealDamage không đọc từ bảng luật mà từ cột 37/38 của
// bảng hệ số gốc (BaseInfo::kRageWhenDamaged/kRageWhenDealing, mỗi 1000 điểm sát thương).
struct RageRule {
    std::int32_t multiplier = 0;
    std::int32_t divisor = 1;
};

// Số tiền có thể là điểm tuyệt đối hoặc phần trăm của số đang có ("10%" trong DiePenalty.txt).
struct Amount {
    bool percent = false;
    std::int32_t value = 0;

    friend constexpr bool operator==(const Amount&, const Amount&) noexcept = default;
};

struct AmountRange {
    Amount min;
    Amount max;
};

// Một dòng DiePenalty.txt. Mọi khoảng rút ngẫu nhiên trong [min, max).
struct PenaltyRow {
    AmountRange money;
    AmountRange exp;
    AmountRange equip_durability;
    AmountRange item_drop;
    AmountRange equip_drop;
};

struct MonsterRow {
    std::uint32_t id = 0;
    std::int32_t level = 1;
    std::int32_t gender = 0;
    std::int32_t min_damage_ppm = 0;         // min_damage_percent nhân 1.000.000 (0,1 -> 100000).
    std::int32_t can_interact = 0;           // -1..2 như bảng (ý nghĩa do module quái/NPC đọc).
    bool boss = false;
    std::int32_t attack_phy = 0;
    std::int32_t defence_phy = 0;
    std::int32_t attack_magic = 0;
    std::int32_t defence_magic = 0;
    std::int32_t max_hp = 1;
    std::int32_t max_mp = 0;
    std::int32_t hp_restore = 0;
    std::int32_t mp_restore = 0;
    std::int32_t hit = 0;
    std::int32_t miss = 0;
    std::int32_t critical = 0;
    std::int32_t critical_defence = 0;
    std::int32_t move_speed = 0;
    std::int32_t walk_speed = 0;
    std::int32_t attack_speed = 0;
    std::array<std::int32_t, 4> attack_element{}; // lạnh, lửa, điện, độc
    std::array<std::int32_t, 4> resist_element{};
    std::array<std::int32_t, 4> resist_reduce{};
    std::int32_t instant_immunity_set = -1;  // id bộ miễn nhiễm trúng-một-lần (id_collections), -1 = không
    std::int32_t duration_immunity_set = -1; // id bộ miễn nhiễm kéo dài
    std::int32_t base_ai = 0;
    std::int32_t extended_ai = -1;
    std::int32_t camp = 0;
    std::int32_t base_exp = 0;
    std::int32_t attack_animation_ms = 0;
    std::int32_t attack_cooldown_ms = 0;
};

// Một tâm pháp (XinFa_V1.txt). Mỗi mốc là một cặp (cấp tâm pháp, giá trị nhân 1000).
struct InnerArtRow {
    std::uint32_t id = 0;
    std::uint8_t sect = 0;
    std::int32_t logic = 0;       // attribute_logic: 0 HP, 1 MP, 2 ngoại công, 3 nội công, 4 ngoại phòng, 5 nội phòng, 6 hit, 7 né, 8 hội tâm.
    std::int32_t learn_level = 0; // cấp nhân vật tối thiểu để học
    std::vector<std::pair<std::int32_t, std::int64_t>> steps;
};

// Dữ liệu thô của Rules; bộ nạp điền, Rules chỉ đọc. Để public vì chỉ là túi dữ liệu.
// NOLINTNEXTLINE(bugprone-exception-escape): giả dương, hàm dựng mặc định của vector và unordered_map (HP-07)
struct RulesData {
    std::array<BaseRow, kBaseTableSects> base;
    // growth[(level * kBaseTableSects + sect) * kPrimaryCount + primary], level 0..growth_levels-1.
    std::vector<std::int16_t> growth;
    std::uint16_t growth_levels = 0;
    std::array<std::uint8_t, kSectSlots> template_of{};
    std::vector<std::uint64_t> exp_need;      // exp_need[level - 1]
    std::int32_t gap_first = 0;               // chênh cấp của phần tử đầu
    std::vector<std::uint32_t> gap_ppm;
    std::array<EnumArray<RageTrigger, RageRule, kRageTriggerCount>, kSectSlots> rage;
    std::unordered_map<std::uint32_t, PenaltyRow> penalties;
    std::vector<MonsterRow> monsters;         // sắp theo id tăng dần, không lặp
    std::vector<InnerArtRow> inner_arts;      // sắp theo id tăng dần, không lặp
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương, di chuyển RulesData (HP-07)
class Rules {
public:
    explicit Rules(RulesData data) : d_(std::move(data)) {}

    // Hệ số gốc của phái (đã đổi phái mới sang phái mẫu). Phái ngoài 0..15 dùng phái 9.
    [[nodiscard]] const BaseRow& base(std::uint8_t sect) const noexcept;
    // Điểm cấp-một tăng khi lên cấp `level` (hàng `level` của bảng; hàng 0 là điểm khởi đầu). 0 khi ngoài bảng.
    [[nodiscard]] std::int32_t growth(std::uint8_t sect, std::uint16_t level, std::size_t primary) const noexcept;
    // Phái mẫu mà phái `sect` mượn bảng (chính nó nếu có bảng riêng).
    [[nodiscard]] std::uint8_t template_of(std::uint8_t sect) const noexcept;

    [[nodiscard]] std::uint16_t max_level() const noexcept { return static_cast<std::uint16_t>(d_.exp_need.size()); }
    // Kinh nghiệm cần để lên từ `level` lên `level+1`; 0 khi level ngoài 1..max_level.
    [[nodiscard]] std::uint64_t exp_need(std::uint16_t level) const noexcept;
    // Hệ số (phần triệu) nhân kinh nghiệm quái theo (cấp quái - cấp người), kẹp vào hai đầu bảng.
    [[nodiscard]] std::uint32_t exp_gap_ppm(std::int32_t level_delta) const noexcept;

    [[nodiscard]] RageRule rage(std::uint8_t sect, RageTrigger trigger) const noexcept;

    [[nodiscard]] const PenaltyRow* penalty(std::uint32_t id) const noexcept;
    [[nodiscard]] const MonsterRow* monster(std::uint32_t id) const noexcept;
    [[nodiscard]] const InnerArtRow* inner_art(std::uint32_t id) const noexcept;

    [[nodiscard]] std::size_t monster_count() const noexcept { return d_.monsters.size(); }
    [[nodiscard]] std::size_t penalty_count() const noexcept { return d_.penalties.size(); }
    [[nodiscard]] std::size_t inner_art_count() const noexcept { return d_.inner_arts.size(); }
    [[nodiscard]] const RulesData& data() const noexcept { return d_; }

private:
    RulesData d_;
};

// Nội dung TSV của từng bảng. Mọi trường đều bắt buộc trừ monsters và inner_arts (rỗng nghĩa là không
// nạp, dùng cho test nhỏ).
struct RulesText {
    std::string_view sect_base_values;     // server/sect_base_values.tsv
    std::string_view sect_growth;          // server/sect_attribute_growth.tsv
    std::string_view sect_templates;       // server/sect_templates.tsv
    std::string_view sect_rage_rules;      // server/sect_rage_rules.tsv
    std::string_view player_exp_levels;    // shared/player_exp_levels.tsv
    std::string_view exp_level_gap;        // server/exp_level_gap_factors.tsv
    std::string_view death_penalties;      // server/death_penalties.tsv
    std::string_view monsters;             // shared/monsters.tsv
    std::string_view inner_arts;           // shared/inner_arts.tsv
};

// Trần chống bảng phình: số hàng tối đa mỗi bảng.
inline constexpr std::size_t kMaxMonsterRows = 200'000;
inline constexpr std::size_t kMaxLevelRows = 1000;

[[nodiscard]] Loaded<Rules> load_rules(const RulesText& text);

// "10%" -> {true, 10}; "250" -> {false, 250}; rỗng/sai -> nullopt.
[[nodiscard]] std::optional<Amount> parse_amount(std::string_view text) noexcept;

} // namespace game::actor
