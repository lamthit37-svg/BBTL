/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/player.hpp
 *  PHÂN HỆ   : Server / Play / Player
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Một người chơi đang ở trong zone, nhìn từ lõi nhiệm vụ: sổ nhiệm vụ, thân
 *    thể (cấp, kinh nghiệm, sinh lực), ví, túi, và ba cổng của sổ cái nối vào
 *    đúng những thứ đó. Dựng từ account::PlayRecord lúc vào cảnh và đóng gói
 *    lại bằng record() lúc ghi.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Cổng của sổ cái chỉ đổi trạng thái trong bộ nhớ; checkpoint/rollback chụp và trả lại cả thân thể, ví lẫn túi nên một giao dịch hỏng
// không để lại gì. Tiền thường và tiền khoá có chung trần theo cấp (item::Limits::gold_cap).

#pragma once

#include "account/play.hpp"
#include "actor/body.hpp"
#include "ids/ids.hpp"
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/hero.hpp"
#include "play/bag.hpp"
#include "play/world.hpp"

#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <string>

namespace game::play {

struct Identity {
    ids::CharacterId id;
    std::string name;
    // protocol::Gender: 1 nữ, 2 nam.
    std::uint8_t gender = 2;
    std::uint8_t sect = ids::kSectNone;
};

class Player final : public mission::Character {
public:
    // Khối thân thể/sổ/túi hỏng thì lỗi kèm lý do: không đoán, không dựng nhân vật nửa vời (người chơi vào lại được khi dữ liệu sửa).
    [[nodiscard]] static std::expected<std::unique_ptr<Player>, std::string> restore(const World& world, Identity who,
        const account::PlayRecord& saved);

    // Đóng gói trạng thái để ghi. nullopt chỉ khi một khối không đóng gói được (lỗi lập trình hay số ngoài miền).
    [[nodiscard]] std::optional<account::PlayRecord> record() const;

    // Số cấp vừa lên kể từ lần lấy trước (cổng kinh nghiệm cộng dồn); lấy xong thì về 0.
    [[nodiscard]] std::uint32_t take_levels_gained() noexcept;

    [[nodiscard]] const std::string& name() const noexcept { return who_.name; }
    [[nodiscard]] std::uint64_t exp() const noexcept { return live_->record().exp; }
    [[nodiscard]] std::uint64_t money() const noexcept { return money_; }
    [[nodiscard]] std::uint64_t bound() const noexcept { return bound_; }
    // Thân thể đang dùng: của chính người chơi, hoặc (khi đã bind) của Fighter trong đấu trường.
    [[nodiscard]] const actor::Body& body() const noexcept { return *live_; }
    [[nodiscard]] actor::Body& body() noexcept { return *live_; }
    // Đấu trường giữ thân thể chiến đấu của người chơi ở Fighter: bind trỏ mọi đọc/ghi sang đó (nơi gọi đã chép thân thể vào
    // Fighter; địa chỉ Fighter ổn định tới khi gỡ khỏi đấu trường). unbind chép thân thể về chỗ của Player rồi trỏ lại.
    void bind(actor::Body& live) noexcept { live_ = &live; }
    void unbind();
    [[nodiscard]] const Bag& bag() const noexcept { return bag_; }

    // mission::Character
    [[nodiscard]] ids::CharacterId id() const noexcept override { return who_.id; }
    [[nodiscard]] mission::Book& book() noexcept override { return book_; }
    [[nodiscard]] const mission::Book& book() const noexcept override { return book_; }
    [[nodiscard]] std::int32_t level() const noexcept override { return live_->level(); }
    [[nodiscard]] std::int32_t sect() const noexcept override { return live_->sect(); }
    // Script gốc: 0 nữ, 1 nam (GetSex); trên dây là 1 nữ, 2 nam.
    [[nodiscard]] std::int32_t gender() const noexcept override { return who_.gender == 1 ? 0 : 1; }
    [[nodiscard]] std::int32_t team_size() const noexcept override { return 1; }
    [[nodiscard]] bool team_leader() const noexcept override { return false; }
    [[nodiscard]] std::int32_t guild() const noexcept override { return -1; }
    [[nodiscard]] std::int32_t ability(std::int32_t skill) const noexcept override;
    [[nodiscard]] bool skill_known(std::int32_t skill) const noexcept override;
    [[nodiscard]] bool learn_skill(std::int32_t skill) noexcept override;
    [[nodiscard]] ledger::Ports ports() noexcept override { return ledger::Ports{.items = bag_, .wallet = wallet_, .exp = exp_}; }

private:
    class WalletPort final : public ledger::WalletPort {
    public:
        explicit WalletPort(Player& owner) noexcept : owner_(&owner) {}
        [[nodiscard]] std::int64_t balance(bool bound) const noexcept override;
        [[nodiscard]] std::int64_t room(bool bound) const noexcept override;
        bool take(std::int64_t amount, bool bound) noexcept override;
        bool give(std::int64_t amount, bool bound) noexcept override;
        void checkpoint() override;
        void rollback() noexcept override;

    private:
        Player* owner_;
        std::uint64_t money_ = 0;
        std::uint64_t bound_ = 0;
    };

    class ExpPort final : public ledger::ExpPort {
    public:
        explicit ExpPort(Player& owner) noexcept : owner_(&owner) {}
        bool give(std::int64_t amount) noexcept override;
        void checkpoint() override;
        void rollback() noexcept override;

    private:
        Player* owner_;
        std::optional<actor::Body> saved_;
        std::uint32_t levels_ = 0;
    };

    Player(const World& world, Identity who, actor::Body body);

public:
    Player(const Player&) = delete;
    Player& operator=(const Player&) = delete;
    Player(Player&&) = delete;
    Player& operator=(Player&&) = delete;
    ~Player() override = default;

private:

    const World* world_;
    Identity who_;
    actor::Body own_;
    actor::Body* live_ = &own_;
    std::uint64_t money_ = 0;
    std::uint64_t bound_ = 0;
    Bag bag_;
    mission::Book book_;
    WalletPort wallet_{*this};
    ExpPort exp_{*this};
    std::uint32_t levels_gained_ = 0;

    friend class WalletPort;
    friend class ExpPort;
};

} // namespace game::play
