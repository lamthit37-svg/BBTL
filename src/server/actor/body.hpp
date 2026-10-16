/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/actor/body.hpp
 *  PHÂN HỆ   : Server / Actor / Body
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Thân thể chiến đấu và bản ghi bền của nhân vật.
 *  - Danh sách kỹ năng rỗng vẫn ghi phiên bản 1, đúng byte bản cũ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Thân thể chiến đấu (người, quái): bản ghi bền, chỉ số dẫn xuất, HP/MP/nộ khí, kinh nghiệm và lên cấp,
// hình phạt chết, hồi sinh. Lõi thuần: không mạng, không đồng hồ thật, không luồng; ngẫu nhiên đi vào
// qua dice::Dice do nơi gọi đưa; thời gian đi vào qua số mili giây trôi qua.
//
// Nguồn: GameServer 2008 Obj_Human_Attributes.cpp, Obj_Character_Attributes.cpp (công thức chỉ số),
// Obj_Human.cpp (lên cấp, hồi HP/MP, chết), Main/DiePenaltyManager.cpp, MenPai/*.cpp (nộ khí).
// Mọi công thức nguyên (Float2Int bằng actor::round_ratio). Khác gốc ghi tại chỗ bằng "Khác gốc:".

#pragma once

#include "actor/attr.hpp"
#include "actor/numeric.hpp"
#include "actor/rules.hpp"
#include "dice/dice.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::actor {

// Hằng của luật, nơi gọi ghi đè được từ rules/*.toml.
struct BodyLimits {
    std::int32_t move_speed = 4000;           // [human] default_move_speed
    std::int32_t base_max_rage = 1000;        // MAX_RAGE gốc
    std::int32_t max_rage_cap = 1500;
    std::int32_t base_max_strike = 6;         // MAX_STRIKE_POINT gốc
    std::int32_t max_strike_cap = 9;
    std::int32_t vision_range = 16;           // BASE_VISION_RANGE
    std::int32_t attack_speed_min = 25;
    std::int32_t attack_speed_max = 400;
    std::int32_t recover_interval_ms = 3000;  // RECOVER_INTERVAL: nhịp hồi HP/MP
    std::int32_t default_fluctuation = 8;     // [combat] default_fluctuation (quái)
    std::int32_t exp_factor_permille = 1000;  // [exp] factor_permille
    std::int32_t exp_cap_multiple = 4;        // kinh nghiệm tích tối đa = 4 lần mức lên cấp kế
};

// Các nguồn cộng chỉ số: trang bị, buff, tâm pháp. Cộng dồn được, gộp được.
struct Modifiers {
    EnumArray<Stat, std::int32_t, kStatCount> point;       // cộng thẳng
    EnumArray<Stat, std::int32_t, kStatCount> rate;        // % của giá trị gốc theo phái/quái
    EnumArray<Stat, std::int32_t, kStatCount> equip_base;  // điểm gốc của trang bị
    EnumArray<Stat, std::int32_t, kStatCount> equip_rate;  // % của điểm gốc trang bị
    EnumArray<AttrId, std::int32_t, kAttrIdCount> raw;     // tổng thô theo id thuộc tính vật phẩm
    std::int32_t rage_gain_percent = 0;                // RefixRageRegeneration: cộng % nộ khí nhận

    // Cộng một dòng thuộc tính vật phẩm. false khi id lạ (không đổi gì).
    bool add_item(const AttrEntry& entry) noexcept;
    void add_point(Stat stat, std::int32_t value) noexcept;
    void add_rate(Stat stat, std::int32_t value) noexcept;
    void merge(const Modifiers& other) noexcept;
};

// Trần kỹ năng võ đã học ghi vào bản ghi. Rỗng thì codec vẫn ghi phiên bản 1, đúng byte của bản
// không có danh sách.
inline constexpr std::size_t kMaxLearnedSkills = 64;

// Bản ghi bền của nhân vật. Mọi trường được kiểm miền khi giải mã (codec.hpp).
struct Record {
    std::uint8_t sect = 9;
    std::uint16_t level = 1;
    std::uint64_t exp = 0;
    std::array<std::int32_t, kPrimaryCount> points{}; // điểm cấp một đã cộng (str, spr, con, int, dex)
    std::int32_t remain_points = 0;                   // điểm tự do chưa cộng
    std::int32_t hp = 1;
    std::int32_t mp = 0;
    std::int32_t rage = 0;
    std::int32_t strike_points = 0;
    bool alive = true;
    std::vector<std::pair<std::uint32_t, std::uint16_t>>
        inner_arts; // (id, cấp), sắp theo id, không lặp
    std::vector<std::uint32_t>
        skills; // id skills.tsv đã học, tăng dần, không có 0. Rỗng thì bản ghi vẫn là phiên bản 1.

    friend bool operator==(const Record&, const Record&) noexcept = default;
};

// Số HP đổi và thân có vừa chết không.
struct HpChange {
    std::int32_t applied = 0; // thay đổi thật (dương hồi, âm mất), sau khi kẹp
    bool died = false;
};

struct LevelUp {
    std::uint16_t levels_gained = 0;
    std::uint64_t exp_after = 0;
};

// Kết quả rút hình phạt chết. Số tiền/vật còn là Amount vì phần trăm của số đang có do nơi gọi áp.
struct PenaltyOutcome {
    Amount money;
    Amount exp;
    Amount equip_durability;
    Amount item_drop;
    Amount equip_drop;
};

enum class DieType : std::uint8_t { kDuel = 0, kMonster = 1, kPlayer = 2 };

// Id dòng death_penalties.tsv = scene_type*100 + pk_index*10 + die_type (DiePenaltyManager).
// pk_index: 0 khi cấp dưới 10, rồi 1..6 theo sát khí (<1, <20, <40, <60, <80, còn lại).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): cảnh, cấp, sát khí khác vai, nơi gọi nêu tên (HP-07)
[[nodiscard]] std::uint32_t penalty_id(std::uint32_t scene_type, std::uint16_t level, std::int32_t pk_value,
    DieType die_type) noexcept;

// Rút hình phạt: mỗi khoảng lấy ngẫu nhiên trong [min, max). Dòng không có trong bảng: nullopt.
[[nodiscard]] std::optional<PenaltyOutcome> roll_penalty(const Rules& rules, std::uint32_t id, dice::Dice& dice);

// Kinh nghiệm quái cho người: base_exp * hệ số chênh cấp * hệ số toàn cục, cắt xuống. `exp_refix` là phần
// trăm cộng của người (Stat::kExpRefix).
[[nodiscard]] std::uint64_t monster_exp(const Rules& rules, const BodyLimits& limits, std::uint16_t killer_level,
    const MonsterRow& monster, std::int32_t exp_refix) noexcept;

// HP/MP/nộ khí sau hồi sinh: phần trăm của mức tối đa hoặc điểm tuyệt đối (global.toml [revive]).
struct Revival {
    Amount hp;
    Amount mp;
    Amount rage;
};

class Body {
public:
    Body() = default;

    // Bản ghi nhân vật mới: cấp 1, điểm khởi đầu = hàng 0 + hàng 1 của bảng điểm mỗi cấp, đầy HP/MP.
    [[nodiscard]] static Record new_record(const Rules& rules, const BodyLimits& limits, std::uint8_t sect);
    // Thân người từ bản ghi đã kiểm. `rules` phải sống lâu hơn thân.
    [[nodiscard]] static Body human(const Rules& rules, const BodyLimits& limits, Record record);
    // Thân quái từ một dòng bảng quái (đầy HP/MP).
    [[nodiscard]] static Body monster(const Rules& rules, const BodyLimits& limits, const MonsterRow& row);

    [[nodiscard]] bool is_human() const noexcept { return human_; }
    [[nodiscard]] const Record& record() const noexcept { return record_; }
    [[nodiscard]] std::uint16_t level() const noexcept { return record_.level; }
    [[nodiscard]] std::uint8_t sect() const noexcept { return record_.sect; }
    [[nodiscard]] bool alive() const noexcept { return record_.alive; }
    [[nodiscard]] std::int32_t hp() const noexcept { return record_.hp; }
    [[nodiscard]] std::int32_t mp() const noexcept { return record_.mp; }
    [[nodiscard]] std::int32_t rage() const noexcept { return record_.rage; }
    [[nodiscard]] std::int32_t strike_points() const noexcept { return record_.strike_points; }
    [[nodiscard]] std::int32_t stat(Stat which) const noexcept { return stats_[which]; }
    // Tổng thô theo id thuộc tính vật phẩm của mọi nguồn (miễn nhiễm, phản đòn, hút máu...).
    [[nodiscard]] std::int32_t raw(AttrId id) const noexcept { return total_.raw[id]; }
    // % miễn ngoại/nội công, kẹp 0..100.
    [[nodiscard]] std::int32_t immunity_phy() const noexcept { return clamp32(raw(AttrId::kImmunityP), 0, 100); }
    [[nodiscard]] std::int32_t immunity_magic() const noexcept { return clamp32(raw(AttrId::kImmunityM), 0, 100); }
    // Biên độ dao động sát thương (phần trăm).
    [[nodiscard]] std::int32_t fluctuation() const noexcept { return fluctuation_; }
    [[nodiscard]] const MonsterRow* monster_row() const noexcept { return monster_ ? &*monster_ : nullptr; }
    [[nodiscard]] std::int32_t camp() const noexcept { return stat(Stat::kCamp); }
    void set_base_camp(std::int32_t camp) noexcept;

    // Nguồn cộng chỉ số. Đặt lại nguồn là tính lại chỉ số; HP/MP kẹp theo mức tối đa mới.
    void set_equipment(const Modifiers& modifiers) noexcept;
    void set_buffs(const Modifiers& modifiers) noexcept;
    [[nodiscard]] const Modifiers& equipment() const noexcept { return equip_; }
    [[nodiscard]] const Modifiers& buffs() const noexcept { return buff_; }

    // HP: delta âm là mất. Thân chết (đã chết rồi) không đổi gì. HP về 0 thì chết.
    HpChange change_hp(std::int64_t delta) noexcept;
    // MP kẹp 0..tối đa; trả thay đổi thật.
    std::int32_t change_mp(std::int64_t delta) noexcept;
    // Nộ khí theo luật phái: value * multiplier / divisor, nhân (100 + rage_gain_percent)/100, kẹp 0..tối đa.
    // Trả lượng thật cộng vào.
    std::int32_t gain_rage(RageTrigger trigger, std::int64_t value) noexcept;
    std::int32_t change_rage(std::int64_t delta) noexcept;
    // Tiêu điểm liên kích: false khi không đủ (không đổi gì); đủ thì trừ và sinh nộ khí theo luật phái.
    bool spend_strike(std::int32_t points) noexcept;
    void gain_strike(std::int32_t points) noexcept;
    // Đổi điểm liên kích do hiệu ứng (StrikePointIncrement): kẹp 0..tối đa, không sinh nộ khí. Trả thay đổi thật.
    std::int32_t change_strike(std::int64_t delta) noexcept;

    // Hồi HP/MP theo nhịp RECOVER_INTERVAL: cộng dồn mili giây, mỗi 3000 ms một nhịp (bản gốc: elapsed > 0
    // thì trừ 3000 và đếm một nhịp). Thân chết không hồi. Trả số nhịp đã chạy.
    std::int32_t advance(std::int64_t elapsed_ms) noexcept;

    // Chết: HP 0, nộ khí 0, hết điểm liên kích. Trả false khi đã chết.
    bool kill() noexcept;
    // Hồi sinh với HP/MP/nộ khí theo Amount (phần trăm của mức tối đa). HP tối thiểu 1.
    bool revive(const Revival& revival) noexcept;
    // Trừ kinh nghiệm theo hình phạt (phần trăm của kinh nghiệm đang có). Trả lượng đã trừ.
    std::uint64_t lose_exp(Amount amount) noexcept;

    // Cộng kinh nghiệm, lên nhiều cấp một lượt nếu đủ. Kinh nghiệm dư kẹp ở exp_cap_multiple lần mức lên
    // cấp kế. Khác gốc: bản 2008 chỉ lên một cấp mỗi lần gọi; ở đây lên liền tới khi hết kinh nghiệm.
    LevelUp add_exp(std::uint64_t amount) noexcept;
    // Cộng điểm tự do vào chỉ số cấp một `primary` (0..4). false khi hết điểm hay chỉ số lạ.
    bool spend_point(std::size_t primary, std::int32_t amount) noexcept;
    // Đổi môn phái: tính lại điểm như thể lên mọi cấp bằng bảng của phái mới (cấp dưới 60 vào điểm cấp một,
    // từ 60 vào điểm tự do). Suy luận từ ChangeMenpaiPoints; điểm đã cộng tay mất.
    bool change_sect(std::uint8_t sect) noexcept;
    // Đã học mã kỹ năng võ này chưa. Quái và thân chưa dựng luôn false.
    [[nodiscard]] bool skill_known(std::uint32_t id) const noexcept;
    // Học kỹ năng võ. true khi đã có hoặc vừa thêm. false khi không phải người, mã 0, hoặc đầy
    // kMaxLearnedSkills.
    bool learn_skill(std::uint32_t id) noexcept;
    // Tẩy điểm: trả mọi điểm cấp một đã cộng ngoài bảng về điểm tự do không; ở đây là tính lại như change_sect
    // cho cùng phái.
    bool wash_points() noexcept;
    // Đặt cấp tâm pháp; false khi cấp 0 hay tâm pháp không có trong bảng. Cấp 0 gỡ tâm pháp.
    bool set_inner_art(std::uint32_t id, std::uint16_t level);

private:
    void rebuild_inner() noexcept;
    void recalc() noexcept;
    void clamp_resources() noexcept;
    void rebuild_points(std::uint8_t sect) noexcept;
    void apply_growth(std::uint16_t level) noexcept;
    struct Base;
    [[nodiscard]] std::int32_t derived(BaseInfo first, std::int32_t attribute) const noexcept;
    [[nodiscard]] Base human_base(const std::array<std::int32_t, kPrimaryCount>& primary) const noexcept;
    [[nodiscard]] Base monster_base(const MonsterRow& row) const noexcept;

    const Rules* rules_ = nullptr;
    BodyLimits limits_{};
    bool human_ = false; // thân mặc định (chưa có Rules) không có người lẫn quái
    Record record_{};
    std::optional<MonsterRow> monster_;
    Modifiers equip_{};
    Modifiers buff_{};
    Modifiers inner_{};
    Modifiers total_{};
    EnumArray<Stat, std::int32_t, kStatCount> stats_;
    std::int32_t base_camp_ = 0;
    std::int32_t fluctuation_ = 0;
    std::int64_t regen_elapsed_ms_ = 0;
};

} // namespace game::actor
