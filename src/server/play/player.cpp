/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/player.cpp
 *  PHÂN HỆ   : Server / Play / Player
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt người chơi trong zone: dựng từ khối lưu, đóng gói lại, ví và kinh
 *    nghiệm nối vào sổ cái.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "play/player.hpp"

#include "account/play.hpp"
#include "actor/body.hpp"
#include "actor/codec.hpp"
#include "item/limits.hpp"
#include "item/types.hpp"
#include "mission/codec.hpp"
#include "play/bag.hpp"
#include "play/world.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace game::play {

namespace {

[[nodiscard]] std::uint64_t gold_cap(const World& world, std::uint16_t level) noexcept {
    return static_cast<std::uint64_t>(std::max<std::int64_t>(world.item_limits().gold_cap(level), 0));
}

} // namespace

Player::Player(const World& world, Identity who, actor::Body body)
    : world_(&world),
      who_(std::move(who)),
      body_(std::move(body)),
      bag_(&world.items(), world.item_limits().unlocked[static_cast<std::size_t>(item::Place::kBaseBag)]) {}

std::expected<std::unique_ptr<Player>, std::string> Player::restore(const World& world, Identity who,
    const account::PlayRecord& saved) {
    actor::Record record;
    if (saved.body.empty()) {
        // Nhân vật chưa từng vào game từ bản có khối thân thể: dựng mới, lấy cấp, kinh nghiệm, sinh lực từ các cột có sẵn.
        record = actor::Body::new_record(world.rules(), world.body_limits(), who.sect);
        record.level = std::clamp<std::uint16_t>(saved.level, 1, world.rules().max_level());
        record.exp = saved.exp;
        record.hp = std::max(saved.hp, 1);
        record.mp = saved.mp;
    } else {
        std::expected<actor::Record, actor::CodecError> decoded = actor::decode_record(saved.body, world.rules().max_level());
        if (!decoded) return std::unexpected("khối thân thể hỏng: " + std::string{actor::describe(decoded.error())});
        record = std::move(*decoded);
    }
    who.sect = record.sect;
    std::unique_ptr<Player> player{new Player(world, std::move(who), actor::Body::human(world.rules(), world.body_limits(), std::move(record)))};
    player->money_ = saved.money;
    player->bound_ = saved.bound;
    if (!saved.mission.empty()) {
        if (const auto done = mission::decode(saved.mission, player->book_); !done) return std::unexpected("khối sổ nhiệm vụ hỏng");
    }
    if (const auto done = player->bag_.restore(saved.bag); !done) return std::unexpected("khối túi hỏng");
    return player;
}

std::optional<account::PlayRecord> Player::record() const {
    account::PlayRecord out;
    out.level = body_.level();
    out.exp = body_.record().exp;
    out.money = money_;
    out.bound = bound_;
    out.hp = body_.hp();
    out.mp = body_.mp();
    if (const auto encoded = actor::encode_record(body_.record(), out.body); !encoded) return std::nullopt;
    std::expected<mission::Blob, mission::CodecError> book = mission::encode(book_);
    if (!book) return std::nullopt;
    out.mission = std::move(*book);
    out.bag = bag_.encode();
    if (out.bag.empty()) return std::nullopt;
    return out;
}

std::uint32_t Player::take_levels_gained() noexcept {
    const std::uint32_t gained = levels_gained_;
    levels_gained_ = 0;
    return gained;
}

// Kỹ năng sống và kỹ năng võ chưa nối: chưa ai có kỹ năng nào cho tới khi bước chiến đấu và kỹ năng sống vào (docs/SERVER-MISSION.md).
std::int32_t Player::ability(std::int32_t skill) const noexcept {
    static_cast<void>(skill);
    return 0;
}

bool Player::skill_known(std::int32_t skill) const noexcept {
    static_cast<void>(skill);
    return false;
}

// ---- ví ----

std::int64_t Player::WalletPort::balance(bool bound) const noexcept {
    return static_cast<std::int64_t>(bound ? owner_->bound_ : owner_->money_);
}

std::int64_t Player::WalletPort::room(bool bound) const noexcept {
    const std::uint64_t cap = gold_cap(*owner_->world_, owner_->body_.level());
    const std::uint64_t held = bound ? owner_->bound_ : owner_->money_;
    return held >= cap ? 0 : static_cast<std::int64_t>(cap - held);
}

bool Player::WalletPort::take(std::int64_t amount, bool bound) noexcept {
    std::uint64_t& held = bound ? owner_->bound_ : owner_->money_;
    if (amount < 0 || std::cmp_greater(amount, held)) return false;
    held -= static_cast<std::uint64_t>(amount);
    return true;
}

bool Player::WalletPort::give(std::int64_t amount, bool bound) noexcept {
    if (amount < 0 || amount > room(bound)) return false;
    (bound ? owner_->bound_ : owner_->money_) += static_cast<std::uint64_t>(amount);
    return true;
}

void Player::WalletPort::checkpoint() {
    money_ = owner_->money_;
    bound_ = owner_->bound_;
}

void Player::WalletPort::rollback() noexcept {
    owner_->money_ = money_;
    owner_->bound_ = bound_;
}

// ---- kinh nghiệm ----

bool Player::ExpPort::give(std::int64_t amount) noexcept {
    if (amount < 0) return false;
    const actor::LevelUp gained = owner_->body_.add_exp(static_cast<std::uint64_t>(amount));
    levels_ += gained.levels_gained;
    owner_->levels_gained_ += gained.levels_gained;
    return true;
}

void Player::ExpPort::checkpoint() {
    saved_ = owner_->body_;
    levels_ = 0;
}

// NOLINTNEXTLINE(bugprone-exception-escape): chép thân thể có thể ném bad_alloc; dự án không dùng ngoại lệ nên dừng tiến trình (LH-07)
void Player::ExpPort::rollback() noexcept {
    if (saved_) owner_->body_ = *saved_;
    owner_->levels_gained_ -= std::min(owner_->levels_gained_, levels_);
    levels_ = 0;
}

} // namespace game::play
