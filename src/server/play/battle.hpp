/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/battle.hpp
 *  PHÂN HỆ   : Server / Play / Battle
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Chiến đấu của một cảnh: một combat::Arena giữ người chơi (thân thể dùng
 *    chung với play::Player) và quái (dựng lười khi bị nhắm), nhận CastSkill,
 *    Respawn, PickUp, chạy đúng nhịp zone đã chọn và dịch sự kiện thành tin
 *    cho client: SkillCast, CombatEvent, EntityDied, SelfVitals, DeathNotice,
 *    SelfSkills, SkillCooldown. Quái chết thì chia kinh nghiệm, cuộn đồ rơi,
 *    đặt vật rơi vào cảnh; người chết chịu phạt chết rồi chờ hồi sinh.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Mọi con số (sát thương, kinh nghiệm, đồ rơi, phạt chết) do máy chủ tính; client chỉ nói "ra chiêu này lên mục tiêu kia". Toạ độ,
// id kỹ năng và id mục tiêu từ client không bao giờ vào check/assert/.at(): kiểm biên rồi trả Reject có mã. Quái chưa đánh lại
// (đợt sau); xác, hồi sinh quái và hạn vật rơi do Surroundings (cảnh) làm theo lời gọi của Battle.
//
// Cảnh là chủ vị trí: trước mỗi lần ra chiêu, Battle chép chỗ đứng của người và quái quanh người ra chiêu từ Surroundings vào
// Fighter (đấu trường quét tuyến tính nên số quái trong đấu trường là số quái từng bị nhắm tới, có trần ArenaLimits::max_fighters
// và được dọn khi đứng yên đủ lâu).

#pragma once

#include "combat/arena.hpp"
#include "dice/dice.hpp"
#include "ids/ids.hpp"
#include "item/factory.hpp"
#include "loot/roller.hpp"
#include "play/player.hpp"
#include "play/stage.hpp"
#include "play/world.hpp"
#include "protocol/messages.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace game::play {

// Quái do người chơi hạ: sổ nhiệm vụ cần biết để tính tiến độ.
struct Slain {
    std::uint64_t session = 0;
    std::uint32_t monster = 0;
    std::uint16_t level = 0;
    // Tên quái trên cảnh: nhiệm vụ giết theo nhóm tên so mã tên này.
    std::string name;
};

// Vật phẩm vừa vào túi người chơi (nhặt): nhiệm vụ thu thập cần biết.
struct Picked {
    std::uint64_t session = 0;
    std::uint32_t item = 0;
};

// Điều Gameplay phải làm tiếp sau một lời gọi của Battle.
struct Report {
    std::vector<Slain> slain;
    std::vector<Picked> picked;
    // Phiên có trạng thái chơi đổi (kinh nghiệm, cấp, túi, sinh lực): đồng bộ và ghi.
    std::vector<std::uint64_t> changed;
};

// Mọi thứ một lời gọi của Battle chạm vào ngoài chính nó.
struct Env {
    Surroundings* stage = nullptr;
    Output* out = nullptr;
    Report* report = nullptr;
};

// Người chơi ngồi vào đấu trường.
struct Seat {
    std::uint64_t session = 0;
    // Id thực thể của người chơi trong cảnh.
    std::uint32_t entity = 0;
    Player* player = nullptr;
    std::int32_t x_cm = 0;
    std::int32_t z_cm = 0;
};

class Battle {
public:
    Battle(const World& world, std::uint16_t scene, std::uint64_t seed, std::int64_t hz);
    ~Battle();
    Battle(const Battle&) = delete;
    Battle& operator=(const Battle&) = delete;
    Battle(Battle&&) = delete;
    Battle& operator=(Battle&&) = delete;

    // Người chơi vào đấu trường: dựng Fighter từ thân thể của Player (rồi Player dùng thân thể ở Fighter), cấp kỹ năng khởi đầu, gửi
    // SelfSkills và SelfVitals. false khi đấu trường đầy hay đã có. Người lưu lúc đang chết được dựng dậy.
    [[nodiscard]] bool join(const Seat& seat, const Env& env);
    // Người chơi rời: thân thể trả về cho Player, Fighter bị gỡ. Phiên lạ thì bỏ.
    void leave(std::uint64_t session);

    void cast(std::uint64_t session, const protocol::CastSkill& message, const Env& env);
    void respawn(std::uint64_t session, const protocol::Respawn& message, const Env& env);
    void pick_up(std::uint64_t session, const protocol::PickUp& message, const Env& env);
    // Người chơi chọn mục tiêu (CGCharAskBaseAttrib 1521): đáp EntityVitals và BuffList của mục
    // tiêu, rồi gửi lại BuffList mỗi khi nó đổi cho tới khi chọn mục tiêu khác. Mục tiêu phải đang
    // trong vùng nhìn; id 0 là bỏ chọn.
    void ask_target(std::uint64_t session, const protocol::AskTarget& message, const Env& env);
    // Một bước của nhịp zone: đấu trường chạy một tick, vật rơi hết hạn bị gỡ, sinh lực đổi thì
    // báo.
    void step(const Env& env);

    [[nodiscard]] std::size_t member_count() const noexcept { return members_.size(); }
    [[nodiscard]] std::size_t drop_count() const noexcept { return drops_.size(); }
    [[nodiscard]] std::size_t fighter_count() const noexcept { return arena_.size(); }

private:
    struct Member {
        Player* player = nullptr;
        std::uint32_t entity = 0;
        // Chỗ người chơi xuất hiện ở cảnh này: "về thành" đưa họ về đây.
        std::int32_t home_x_cm = 0;
        std::int32_t home_z_cm = 0;
        // Điều đã gửi cho họ, để chỉ gửi khi đổi.
        std::int32_t sent_hp = -1;
        std::int32_t sent_mp = -1;
        std::int32_t sent_rage = -1;
        std::int32_t sent_hp_max = -1;
        std::int32_t sent_mp_max = -1;
        std::int32_t sent_rage_max = -1;
        std::uint64_t vitals_tick = 0;
        Surroundings::Vitals sent_view;
        // Danh sách buff đã gửi (của mình, của mục tiêu đang chọn) và id mục tiêu đang chọn (0 là
        // không chọn): gửi lại khi tập buff đổi; thời gian còn lại tự đếm ở client nên không tính
        // là đổi.
        std::vector<protocol::BuffEntry> sent_buffs;
        std::vector<protocol::BuffEntry> sent_target_buffs;
        std::uint32_t asked = 0;
    };

    // Vật rơi chờ nhặt: món đã cuộn, chủ nhặt và hạn.
    struct Loose {
        item::TemplateId tmpl;
        std::uint16_t count = 1;
        bool bound = false;
        std::optional<ids::CharacterId> owner;
        ids::Tick expires_at;
        std::optional<ids::Tick> public_from;
    };

    [[nodiscard]] static ids::EntityHandle handle_of(std::uint32_t entity) noexcept {
        return ids::EntityHandle{.index = entity, .generation = 1};
    }
    [[nodiscard]] Surroundings::Place place_of(std::uint32_t entity) const noexcept {
        return Surroundings::Place{.scene = scene_, .entity = entity};
    }

    [[nodiscard]] std::vector<combat::SkillEntry> starting_skills(const Player& player) const;
    // Chép chỗ đứng của mọi người và quái quanh `entity` vào Fighter; dựng lười Fighter cho quái trong tầm `reach_cm` quanh nó.
    void sync_positions(const Env& env, std::uint32_t entity, std::int32_t reach_cm);
    [[nodiscard]] bool ensure_monster(const Surroundings::Unit& unit);
    // Dịch sự kiện của đấu trường thành tin, chia thưởng khi có ai chết, rồi dọn hàng đợi. `from_cast`: hồi sinh lực trong lúc ra
    // chiêu là hồi của chiêu (hiện số bay); ngoài ra là hồi tự nhiên (không hiện).
    void drain(const Env& env, bool from_cast);
    // Log kiểm: đòn trúng của người chơi (ra đòn hay bị trúng).
    void note_hit(Output& out, const combat::Event& event) const;
    void on_monster_death(const combat::Event& event, const Env& env);
    void on_player_death(const combat::Event& event, const Env& env);
    void reward(Member& killer, std::uint64_t session, const combat::Fighter& monster, const Surroundings::Unit& unit,
        const Env& env);
    void scatter_loot(const Member& killer, const Surroundings::Unit& unit, const Env& env);
    void push_vitals(std::uint64_t session, Member& who, const Env& env, bool force);
    void send_skills(std::uint64_t session, const Member& who, const Env& env);
    // Danh sách buff của một Fighter. `detailed`: bản của chính mình (người gây, kỹ năng, thời gian
    // còn lại); không thì chỉ dòng hiệu ứng và số thứ tự, như gốc gửi cho người khác.
    [[nodiscard]] std::vector<protocol::BuffEntry> buff_list(const combat::Fighter& fighter,
        bool detailed) const;
    // Gửi BuffList của mình và của mục tiêu đang chọn khi tập buff đổi (`force` gửi dù không đổi).
    void push_buffs(std::uint64_t session, Member& who, const Env& env, bool force);
    void push_own_buffs(std::uint64_t session, Member& who, const Env& env, bool force);
    void push_target_buffs(std::uint64_t session, Member& who, const Env& env, bool force);
    void prune();

    const World* world_;
    std::uint16_t scene_;
    dice::Dice dice_;
    combat::Arena arena_;
    item::SerialAllocator serials_;
    loot::Roller roller_;
    std::unordered_map<std::uint64_t, Member> members_;
    std::unordered_map<std::uint32_t, std::uint64_t> by_entity_;
    std::unordered_map<std::uint32_t, Loose> drops_;
    // Kỹ năng người/quái đang ra gần nhất, để gắn vào CombatEvent (sự kiện sát thương của đấu trường không mang id kỹ năng).
    std::unordered_map<std::uint32_t, std::uint16_t> last_skill_;
    // Quái đã bị chạm tới ở tick nào, để dọn Fighter không còn dính líu.
    std::unordered_map<std::uint32_t, std::uint64_t> touched_;
    // Đồng hồ của Battle: đếm mọi bước, kể cả khi cảnh vắng (vật rơi vẫn hết hạn); đấu trường chỉ
    // chạy khi có người.
    std::uint64_t tick_ = 0;
    std::int64_t hz_ = 20;
    // SelfVitals tối đa 5 Hz; dọn quái đứng yên mỗi 60 giây. Constructor gán theo hz.
    std::uint64_t vitals_gap_ = 4;
    std::uint64_t prune_every_ = 1200;
    std::uint64_t prune_idle_ = 1200;
};

} // namespace game::play
