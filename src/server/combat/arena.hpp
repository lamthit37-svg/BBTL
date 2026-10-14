#pragma once
// Đấu trường: nơi mọi người ra đòn/chịu đòn của một cảnh sống chung. Giữ sổ thực thể (Fighter), hàng đợi hiệu
// ứng chờ giao, hàng đợi sự kiện đầu ra; chạy bước 20 Hz; xử lý lệnh ra chiêu, hiệu ứng, chuỗi sát thương, buff,
// hồi chiêu, gom khí/dẫn, chết và hồi sinh. Lõi thuần: không mạng, không đồng hồ thật, không luồng; ngẫu nhiên là
// dice::Dice do nơi gọi đưa vào (một nguồn cho mỗi cảnh, rút theo thứ tự cố định để phát lại được).
//
// Thứ tự của một bước tick():
//   1. now += 1.
//   2. Mỗi thực thể theo thứ tự handle tăng: dọn buff đã tan, nhịp buff (từ cuối về đầu), nhịp gom/dẫn, hồi HP/MP.
//   3. Giao mọi hiệu ứng đến hạn theo (hạn, thứ tự gửi). Hiệu ứng giao ở bước t chỉ bắt đầu đếm giờ từ bước t+1,
//      nên buff 1000 ms tồn tại đúng 20 bước sau khi nhận.
// Lệnh (cast, send_effect...) chạy giữa hai bước: hiệu ứng không trễ vẫn qua hàng đợi và tới ở bước kế.
//
// Nguồn: GameServer 2008 Skills/Skill_Core.cpp, SkillLogic.cpp, Impact_Core.cpp, Obj_Character_Impact.cpp,
// Obj_Character_Event.cpp, Obj_Character_Skill.cpp, Action/*.cpp. Khác gốc ghi tại chỗ bằng "Khác gốc:".

#include "actor/body.hpp"
#include "combat/catalog.hpp"
#include "combat/damage.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <map>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::combat {

namespace detail {
class EffectLogic;
class SkillHandler;
} // namespace detail

// Kết quả một lệnh ra chiêu. kOk là đã nhận lệnh (chiêu tức thời đã chạy, gom/dẫn đã bắt đầu).
enum class CastOutcome : std::uint8_t {
    kOk,
    kNoCaster,
    kDead,
    kUnknownSkill,
    kNotLearned,
    kCooldown,
    kBusy,
    kNoWeapon,
    kForbidden,       // bị cờ điều khiển/biến hình/bộ lọc buff chặn
    kInvalidTarget,
    kTargetDead,
    kOutOfRange,
    kLackMana,
    kLackRage,
    kLackStrike,
    kLackHp,
    kConditionFailed,
    kUnsupported,     // logic kỹ năng chưa có mã
};

[[nodiscard]] std::string_view describe(CastOutcome outcome) noexcept;

enum class ArenaError : std::uint8_t {
    kDuplicate,  // handle đã có trong đấu trường
    kFull,       // đủ max_fighters
    kInvalid,    // handle rỗng
};

struct ArenaLimits {
    std::size_t max_fighters = 16384;
    std::size_t max_pending = kMaxPending;
    std::size_t max_events = kMaxEvents;
    std::int32_t range_tolerance_cm = 100;  // sai số tầm đánh chấp nhận, bù độ trễ di chuyển (số tự đặt)
};

// Lý lịch một lần gửi hiệu ứng (InitImpactFromData + RefixPowerByRate + RegisterImpactEvent).
struct EffectOrigin {
    ids::EntityHandle caster;
    std::uint32_t skill = 0;
    bool critical = false;
    bool computed = false;            // logic sát thương tính từ công thức chiến đấu (hiệu ứng nằm trong kỹ năng)
    std::int32_t power_percent = 0;   // cường hóa uy lực, phần trăm cộng thêm
    std::int32_t time_percent = 0;    // cường hóa thời gian hiệu ứng, phần trăm cộng thêm
    std::int32_t time_ms = 0;         // cường hóa thời gian hiệu ứng, mili giây cộng thêm
    std::int64_t delay_ticks = 0;
};

// Một mục tiêu bị trúng trong một lượt phát kỹ năng.
struct Hit {
    ids::EntityHandle unit;
    bool critical = false;
    Relation relation = Relation::kEnemy;
};

// Bản ghi bền của riêng chiến đấu: sổ kỹ năng, hồi chiêu còn lại, buff mang theo. Thời gian lưu dạng số bước còn lại.
struct SavedCooldown {
    std::int32_t id = 0;
    std::uint32_t remaining_ticks = 0;

    friend constexpr bool operator==(const SavedCooldown&, const SavedCooldown&) noexcept = default;
};

struct SavedBuff {
    std::uint32_t effect = 0;
    std::uint32_t skill = 0;
    std::uint64_t caster_character = 0;
    bool by_player = false;
    bool critical = false;
    std::int64_t continuance = 0;
    std::int64_t elapsed = 0;
    std::int32_t refix = 0;
    std::array<std::int32_t, kBuffSlots> slot{};

    friend constexpr bool operator==(const SavedBuff&, const SavedBuff&) noexcept = default;
};

struct CombatRecord {
    std::vector<SkillEntry> skills;
    std::vector<SavedCooldown> cooldowns;
    std::vector<SavedBuff> buffs;

    friend bool operator==(const CombatRecord&, const CombatRecord&) noexcept = default;
};

using RelationPolicy = std::function<Relation(const Fighter& from, const Fighter& to)>;
// Hai người có phải vợ chồng không (điều kiện kỹ năng "đối tượng là phối ngẫu"); module xã hội cắm vào. Chưa cắm: false.
using SpousePolicy = std::function<bool(const Fighter& from, const Fighter& to)>;

class Arena {
public:
    Arena(const Catalog& catalog, dice::Dice& dice, ArenaLimits limits = {});
    ~Arena();
    Arena(const Arena&) = delete;
    Arena& operator=(const Arena&) = delete;
    Arena(Arena&&) = delete;
    Arena& operator=(Arena&&) = delete;

    // ----- Thực thể -----
    // Nhận quyền sở hữu `fighter`; lỗi thì `fighter` giữ nguyên (chỉ bị di chuyển khi thêm thành công).
    [[nodiscard]] std::expected<void, ArenaError> add(Fighter&& fighter);
    bool remove(ids::EntityHandle handle);
    [[nodiscard]] Fighter* find(ids::EntityHandle handle) noexcept;
    [[nodiscard]] const Fighter* find(ids::EntityHandle handle) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return fighters_.size(); }
    // Mọi handle theo thứ tự tăng (cho công cụ và test).
    [[nodiscard]] std::vector<ids::EntityHandle> handles() const;

    // ----- Thời gian -----
    [[nodiscard]] ids::Tick now() const noexcept { return now_; }
    void tick();

    // ----- Lệnh -----
    // Ra chiêu `skill` cấp `level` của `caster` về phía `target`. Cấp 0 là cấp đã học (kỹ năng chung luôn cấp 1);
    // cấp cao hơn cấp đã học bị từ chối. Chiêu tức thời chạy ngay trong lời gọi; gom/dẫn bắt đầu và chạy tiếp ở tick().
    CastOutcome cast(ids::EntityHandle caster, std::uint32_t skill, std::uint8_t level, const Target& target);
    // Người chơi huỷ gom khí/dẫn. false khi không có gì để huỷ.
    bool cancel_cast(ids::EntityHandle caster);
    // Ngắt hành động đang chạy (bị choáng, chết, bị buff dẫn tan...). false khi đang rảnh.
    bool interrupt(ids::EntityHandle unit);
    // Giết ngay (GM, đòn tức tử của script). false khi đã chết hay không có.
    bool kill(ids::EntityHandle unit, ids::EntityHandle killer);
    // Hồi sinh với HP/MP/nộ khí theo Amount.
    bool revive(ids::EntityHandle unit, const actor::Revival& revival);
    // Nhận lời hồi sinh do kỹ năng/buff đề nghị (Fighter::relive). false khi không có đề nghị hay chưa chết.
    bool accept_relive(ids::EntityHandle unit);
    // Thêm kỹ năng vào sổ (thay cấp nếu đã có). false khi sổ đầy.
    bool learn(ids::EntityHandle unit, std::uint32_t skill, std::uint8_t level);
    // Tính lại phần cộng từ kỹ năng bị động và buff (sau khi đổi sổ kỹ năng hay trang bị).
    void refresh(ids::EntityHandle unit);

    // ----- Hiệu ứng -----
    // Xếp hàng gửi hiệu ứng `effect` tới `target`. false khi hàng đợi đầy hoặc không có thực thể.
    bool send_effect(ids::EntityHandle target, std::uint32_t effect, const EffectOrigin& origin);
    // Gỡ buff của tập `collection` có cấp không quá `level`, tối đa `count` buff (count <= 0: không giới hạn).
    std::int32_t dispel_collection(Fighter& unit, std::int32_t collection, std::int32_t level, std::int32_t count);
    // Hủy mọi buff của tập `collection` mà hủy được.
    void cancel_collection(Fighter& unit, std::int32_t collection);

    // ----- Quan sát -----
    [[nodiscard]] std::span<const Event> events() const noexcept { return events_; }
    void clear_events() noexcept { events_.clear(); }
    [[nodiscard]] std::uint64_t dropped_events() const noexcept { return dropped_events_; }
    [[nodiscard]] std::size_t pending_count() const noexcept { return pending_.size(); }

    // ----- Chính sách quan hệ bạn/địch -----
    // Mặc định theo ma trận phe của bảng. Zone đặt chính sách riêng để gài luật PK/tổ đội/bang.
    void set_relation_policy(RelationPolicy policy) { relation_policy_ = std::move(policy); }
    [[nodiscard]] Relation relation(const Fighter& from, const Fighter& to) const;
    [[nodiscard]] bool is_friend(const Fighter& from, const Fighter& to) const { return relation(from, to) == Relation::kFriend; }
    void set_spouse_policy(SpousePolicy policy) { spouse_policy_ = std::move(policy); }

    // ----- Lưu trữ -----
    [[nodiscard]] CombatRecord snapshot(const Fighter& unit) const;
    // Khôi phục sổ kỹ năng, hồi chiêu, buff vào `unit` (đè lên cái đang có). Dòng hiệu ứng không còn trong bảng bị bỏ.
    // `offline_ticks` là thời gian đã trôi lúc ngoại tuyến; chỉ buff có cờ tính giờ ngoại tuyến bị cộng vào đồng hồ.
    void restore(Fighter& unit, const CombatRecord& record, std::int64_t offline_ticks = 0);

    // ----- Dành cho handler logic (effects.cpp, skills.cpp) và zone -----
    [[nodiscard]] const Catalog& catalog() const noexcept { return *catalog_; }
    [[nodiscard]] const ArenaLimits& limits() const noexcept { return limits_; }
    // Rand100 của bản gốc: đều trong [0, 100).
    [[nodiscard]] std::int32_t roll100() noexcept { return static_cast<std::int32_t>(dice_->below(100)); }
    // Số nguyên đều trong [0, bound); bound 0 cho 0.
    [[nodiscard]] std::uint32_t roll_below(std::uint32_t bound) noexcept { return static_cast<std::uint32_t>(dice_->below(bound)); }
    // Phát một lượt của kỹ năng `skill` thay cho `unit` (kỹ năng "mượn", vd. hoá khí thức của Mộ Dung): dùng cấp cao nhất có
    // dữ liệu, bỏ qua sổ kỹ năng, hồi chiêu, tiêu hao và khoá hành động; không kiểm tầm. Kỹ năng bị động, kỹ năng chưa có mã và
    // lời gọi lồng nhau (kỹ năng mượn mà lại mượn tiếp) bị từ chối. false khi không phát được.
    bool cast_borrowed(Fighter& unit, std::uint32_t skill, const Target& target);
    void emit(EventKind kind, ids::EntityHandle actor, ids::EntityHandle target, std::uint32_t id = 0, std::int32_t value = 0,
        std::int32_t extra = 0, Position where = {});

    // Đổi HP (HealthIncrement): delta âm là mất; chết thì chạy chuỗi chết. Trả HP thật đổi.
    actor::HpChange change_hp(Fighter& unit, ids::EntityHandle source, std::int64_t delta, bool critical = false);
    std::int32_t change_mp(Fighter& unit, ids::EntityHandle source, std::int64_t delta);
    std::int32_t change_rage(Fighter& unit, ids::EntityHandle source, std::int64_t delta);
    std::int32_t change_strike(Fighter& unit, ids::EntityHandle source, std::int64_t delta);

    // Chuỗi sát thương nhiều kênh (Obj_Character::OnDamages): hook theo kênh, cộng, tối thiểu 1, hook tổng, hook
    // của người đánh, trừ HP. `fixed` là phần sát thương thẳng cộng sau cùng.
    void damage_channels(Fighter& unit, ids::EntityHandle attacker, ChannelDamage amounts, std::int32_t fixed, bool critical,
        std::uint32_t skill);
    // Chuỗi sát thương một số (Obj_Character::OnDamage).
    void damage_flat(Fighter& unit, ids::EntityHandle attacker, std::int32_t amount, bool critical, std::uint32_t skill);

    // Dựng bản đầu vào công thức từ chỉ số hiện tại của hai bên.
    [[nodiscard]] AttackerView attacker_view(const Fighter& unit) const;
    [[nodiscard]] DefenderView defender_view(const Fighter& unit) const;

    // Tách mọi buff thuộc tập/điều kiện; trả số buff đã gỡ. `matcher` nhận buff và dòng hiệu ứng.
    using BuffMatcher = std::function<bool(const Buff&, const Effect&)>;
    std::int32_t dispel_where(Fighter& unit, const BuffMatcher& matcher, std::int32_t count, bool require_dispellable);

    [[nodiscard]] bool buff_in_collection(const Buff& buff, std::int32_t collection) const;
    [[nodiscard]] bool skill_in_collection(std::uint32_t skill, std::int32_t collection) const;
    [[nodiscard]] const Buff* first_buff_in_collection(const Fighter& unit, std::int32_t collection) const;
    // Gỡ một buff (đánh dấu tan, chạy hook).
    void fade_out(Fighter& unit, Buff& buff);
    // Đặt thời gian hồi chiêu của nhóm `id` còn `ticks` bước kể từ bây giờ (0 là xoá).
    void set_cooldown(Fighter& unit, std::int32_t id, std::int64_t ticks);
    [[nodiscard]] std::int64_t cooldown_remaining(const Fighter& unit, std::int32_t id) const noexcept;
    void clear_cooldown(Fighter& unit, std::int32_t id);

    // Hồi sinh có kiểm tra trạng thái chết.
    bool revive_fighter(Fighter& unit, const actor::Revival& revival, ids::EntityHandle source);
    // Hồi máu qua chuỗi hồi phục (hook người nhận, người hồi, nộ khí người hồi). Người đã chết không nhận.
    void heal(Fighter& unit, ids::EntityHandle healer, std::int32_t amount, std::uint32_t skill);
    // Tính lại chỉ số và cờ dẫn xuất từ buff (gọi khi buff đổi tham số của chính nó).
    void recompute(Fighter& unit);
    // Mã xử lý của một logic hiệu ứng (nullptr khi logic chưa có mã).
    [[nodiscard]] const detail::EffectLogic* effect_handler(std::int32_t logic) const noexcept;

    // Mọi thực thể trong bán kính quanh một điểm và thoả `accept`, gần trước (đồng khoảng cách: handle nhỏ trước),
    // tối đa `max_count` (0 là trần kMaxScanTargets). Quét tuyến tính toàn đấu trường: zone chia đấu trường theo cảnh.
    [[nodiscard]] std::vector<ids::EntityHandle> units_around(Position centre, std::int32_t radius_cm, std::size_t max_count,
        const std::function<bool(const Fighter&)>& accept) const;

private:
    struct Resolved {
        const Effect* effect = nullptr;
        const LogicSpec* spec = nullptr;
        const detail::EffectLogic* logic = nullptr;

        [[nodiscard]] explicit operator bool() const noexcept { return logic != nullptr; }
    };

    struct Pending {
        ids::EntityHandle receiver;
        Buff impact;
    };

    struct PendingKey {
        std::uint64_t due = 0;
        std::uint64_t seq = 0;

        friend constexpr auto operator<=>(const PendingKey&, const PendingKey&) noexcept = default;
    };

    // Số thứ tự buff quấn về 1 khi chạm trần này (buff nằm trong danh sách <= 20 mục nên không bao giờ trùng).
    static constexpr std::int32_t kMaxSn = 0x3FFF'FFFF;

    // ---- tra cứu ----
    [[nodiscard]] Resolved resolve(const Buff& buff) const noexcept;
    [[nodiscard]] const detail::SkillHandler* skill_handler(std::int32_t logic) const noexcept;
    // Duyệt buff đang sống có hook, theo thứ tự danh sách; buff mồ côi (hiệu ứng mất khỏi bảng) bị gỡ.
    template <typename Fn>
    void for_each_buff(Fighter& unit, const Fn& fn);

    // ---- nhịp ----
    void heartbeat(Fighter& unit);
    void buff_heartbeat(Fighter& unit);
    void cleanup_faded(Fighter& unit);
    void action_heartbeat(Fighter& unit);
    void deliver_due();
    void deliver(const Pending& pending);
    [[nodiscard]] bool support_still_on(const Fighter& unit, const Buff& buff) const noexcept;

    // ---- buff ----
    void register_impact(Fighter& unit, const Buff& impact);
    bool replace_mutex(Fighter& unit, Buff impact);
    void replace_last_good(Fighter& unit, Buff impact);
    void add_new(Fighter& unit, Buff impact);
    void replace_slot(Fighter& unit, Buff& dest, Buff src);
    void activate_impact(Fighter& unit, Buff& buff);
    [[nodiscard]] static std::int32_t next_sn(Fighter& unit) noexcept;
    [[nodiscard]] std::optional<MissKind> filtrate(Fighter& unit, const Buff& incoming);
    void refix_by_sender(Fighter& sender, Buff& impact, const Effect& effect);

    // ---- sổ kỹ năng ----
    void refresh_unit(Fighter& unit);

    // ---- sát thương, chết ----
    void deal(Fighter& unit, ids::EntityHandle attacker, std::int32_t damage, bool critical, std::uint32_t skill);
    void handle_death(Fighter& unit, ids::EntityHandle killer);

    // ---- hook ----
    void run_on_damages(Fighter& unit, Fighter* attacker, ChannelDamage& amounts, std::uint32_t skill);
    void run_on_damage(Fighter& unit, Fighter* attacker, std::int32_t& damage, std::uint32_t skill);
    void run_on_damage_target(Fighter& unit, Fighter& target, std::int32_t& damage, std::uint32_t skill);
    void run_on_die(Fighter& unit);
    void run_on_be_hit(Fighter& unit, Fighter& attacker);
    void run_on_hit_target(Fighter& unit, Fighter& target);
    void run_on_critical(Fighter& attacker, Fighter& target);
    void run_on_heal_target(Fighter& healer, Fighter& target, std::int32_t& healed);
    void run_on_be_heal(Fighter& target, Fighter& healer, std::int32_t& healed);
    void run_on_action_started(Fighter& unit);
    void run_on_use_skill(Fighter& unit, CastInfo& info);
    void run_refix_skill(Fighter& unit, CastInfo& info);

    // ---- kiểm tra trước khi ra chiêu ----
    [[nodiscard]] CastInfo instance(const SkillTemplate& tmpl, const SkillLevel& level, std::uint8_t level_number) const;
    [[nodiscard]] CastOutcome check_terms(const Fighter& unit, const CastInfo& info, const Target& target) const;
    [[nodiscard]] CastOutcome check_target(const Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target,
        bool for_tick) const;
    [[nodiscard]] bool can_use_in_status(const Fighter& unit, const SkillTemplate& tmpl) const;
    [[nodiscard]] bool skill_known(const Fighter& unit, const SkillTemplate& tmpl, std::uint8_t level) const noexcept;
    [[nodiscard]] bool cooldown_ready(const Fighter& unit, const SkillTemplate& tmpl) const noexcept;
    [[nodiscard]] bool busy(const Fighter& unit) const noexcept;
    [[nodiscard]] bool filtered_out(const Fighter& unit, const SkillTemplate& tmpl) const;
    [[nodiscard]] bool visible_to(const Fighter& viewer, const Fighter& subject) const noexcept;
    [[nodiscard]] bool out_of_range(const Fighter& unit, const SkillTemplate& tmpl, Position where) const noexcept;
    [[nodiscard]] bool wanted_target(const Fighter& unit, const Fighter& other, const SkillTemplate& tmpl) const;

    // ---- phát chiêu ----
    [[nodiscard]] bool deplete(Fighter& unit, CastInfo& info);
    [[nodiscard]] std::vector<ids::EntityHandle> collect_targets(Fighter& unit, const SkillTemplate& tmpl, const Target& target);
    void scan(const Fighter& unit, const SkillTemplate& tmpl, Position centre, std::vector<ids::EntityHandle>& out) const;
    [[nodiscard]] bool hit_roll(Fighter& unit, const Fighter& other, const CastInfo& info);
    [[nodiscard]] bool critical_roll(Fighter& unit, const Fighter& other, const CastInfo& info);
    CastOutcome begin_instant(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target);
    CastOutcome begin_charge(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target);
    CastOutcome begin_channel(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target);
    // Chiêu tức thời hoặc gom xong: (kiểm lại nếu `recheck`), tiêu hao, khoá hành động, hồi chiêu, rồi phát. false khi bị từ chối.
    bool run_activation(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target, bool recheck);
    // Một lượt phát: chọn mục tiêu, lăn trúng/né rồi hội tâm, chuyển cho handler. `delay_ticks` là trễ hiệu ứng tới đích.
    void activate(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info, const Target& target, bool tick,
        std::int64_t delay_ticks);
    void apply_cooldown(Fighter& unit, const SkillTemplate& tmpl, const CastInfo& info);
    void start_action(Fighter& unit, ActionState::Phase phase, const CastInfo& info, const Target& target, std::int64_t duration,
        std::int64_t interval);
    void finish_action(Fighter& unit);
    bool interrupt_action(Fighter& unit);
    void disturb_action(Fighter& unit);
    void register_threat(Fighter& unit, Fighter& other, const SkillTemplate& tmpl);

    const Catalog* catalog_;
    dice::Dice* dice_;
    ArenaLimits limits_;
    ids::Tick now_;
    std::map<ids::EntityHandle, Fighter> fighters_;
    std::map<PendingKey, Pending> pending_;
    std::uint64_t pending_seq_ = 0;
    std::vector<Event> events_;
    std::uint64_t dropped_events_ = 0;
    RelationPolicy relation_policy_;
    SpousePolicy spouse_policy_;
    std::vector<const detail::EffectLogic*> effect_table_;   // logic id -> mã xử lý
    std::vector<const detail::SkillHandler*> skill_table_;
    std::int32_t borrow_depth_ = 0;  // độ sâu lồng của cast_borrowed; tối đa 1
};

} // namespace game::combat
