/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/loot/roller.cpp
 *  PHÂN HỆ   : Server / Loot / Roller
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cuộn đồ rơi khi quái chết: xem roller.hpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "loot/roller.hpp"

#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"
#include "loot/box.hpp"
#include "loot/chance.hpp"
#include "loot/tables.hpp"
#include "loot/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <optional>
#include <span>
#include <vector>

namespace game::loot {
namespace {

using Unexpected = std::unexpected<item::Error>;

constexpr std::int8_t kMaxOriginValue = static_cast<std::int8_t>(item::Origin::kDailyBoss);

} // namespace

Roller::Roller(const LootTables& tables, const item::Factory& factory, const LootConfig& config) noexcept
    : tables_(&tables), factory_(&factory), config_(config) {
    config_.drop_param_ppm = std::min(config.drop_param_ppm, kMaxDropParamPpm);
    config_.box_lifetime.count = std::max<std::int64_t>(config.box_lifetime.count, 1);
}

std::expected<item::Instance, item::Error> Roller::make(item::TemplateId tmpl, item::Origin origin, bool force_bind,
    ids::Tick now, dice::Dice& dice, item::SerialAllocator& serials) const {
    item::CreateRequest request{.tmpl = tmpl,
        .count = 1,
        .picked = false,
        .now = now,
        .roll = item::RollContext{.origin = origin}};
    request.ticks_per_second = config_.ticks_per_second;
    std::expected<item::Instance, item::Error> made = factory_->create(request, dice, serials);
    if (made && force_bind) made->bound = true;
    return made;
}

DropBox Roller::new_box(std::optional<ids::CharacterId> owner, ids::Tick now) const noexcept {
    DropBox box;
    box.owner = owner;
    box.expires_at = ids::advance(now, config_.box_lifetime);
    return box;
}

std::expected<void, item::Error> Roller::fill(DropBox& box, std::vector<Announcement>& announcements,
    const MonsterDrop& drop, const Kill& kill, const Claimant& claimant, dice::Dice& dice,
    item::SerialAllocator& serials) const {
    const std::int64_t delta = std::int64_t{kill.level} - std::int64_t{claimant.level};
    const std::uint32_t gap = tables_->gap_ppm(delta);
    const std::uint32_t wallow = std::min(claimant.wallow_ppm, kPpm);
    for (std::size_t slot = 0; slot < drop.pack_count; ++slot) {
        if (box.item_count() >= kBoxCapacity) break;
        const Pack* pack = tables_->pack(drop.packs.at(slot));
        if (pack == nullptr) continue;
        const Ratio ratio = drop_ratio(DropFactors{.monster_value = drop.value,
            .box_value = pack->value,
            .gap_ppm = gap,
            .param_ppm = config_.drop_param_ppm,
            .wallow_ppm = wallow});
        if (!succeeds(ratio, dice)) continue;
        const std::span<const PackEntry> entries = tables_->entries(*pack);
        if (entries.empty()) continue;
        const PackEntry& chosen = *std::next(entries.begin(), static_cast<std::ptrdiff_t>(dice.below(entries.size())));
        const bool inherit = chosen.origin < 0 || chosen.origin > kMaxOriginValue;
        const item::Origin origin = inherit ? kill.origin : static_cast<item::Origin>(chosen.origin);
        const std::expected<item::Instance, item::Error> made =
            make(chosen.item, origin, pack->force_bind, kill.now, dice, serials);
        if (!made) return Unexpected(made.error());
        if (!box.put(*made)) break;
        if (pack->broadcast >= 0) {
            announcements.push_back(Announcement{
                .owner = claimant.who, .broadcast = pack->broadcast, .item = made->tmpl, .serial = made->serial});
        }
    }
    return {};
}

std::expected<KillOutcome, item::Error> Roller::roll_kill(const Kill& kill, std::span<const Claimant> claimants,
    dice::Dice& dice, item::SerialAllocator& serials) const {
    if (claimants.size() > kMaxClaimants) return Unexpected(item::Error::kBadCount);
    for (const Claimant& claimant : claimants) {
        if (claimant.quest_items.size() > kMaxQuestDrops) return Unexpected(item::Error::kBadCount);
    }
    KillOutcome outcome;
    if (claimants.empty()) return outcome;

    // Quái không có dòng bảng đi theo nhánh BDR_COMMON (GetMonsterDropRuler trả BDR_UNKNOW, khác BDR_BOSS) nhưng không có
    // gói nào để cuộn: chỉ đồ nhiệm vụ rơi.
    const MonsterDrop* drop = tables_->monster(kill.monster);
    const Ruler ruler = drop != nullptr ? drop->ruler : Ruler::kCommon;
    const std::size_t lucky = ruler == Ruler::kCommon ? dice.below(claimants.size()) : claimants.size();

    for (std::size_t index = 0; index < claimants.size(); ++index) {
        const Claimant& claimant = *std::next(claimants.begin(), static_cast<std::ptrdiff_t>(index));
        const bool rolls = drop != nullptr && (ruler == Ruler::kBoss || index == lucky);
        if (!rolls && claimant.quest_items.empty()) continue;
        DropBox box = new_box(claimant.who, kill.now);
        for (const item::TemplateId quest : claimant.quest_items) {
            const std::expected<item::Instance, item::Error> made =
                make(quest, item::Origin::kMonster, false, kill.now, dice, serials);
            if (!made) return Unexpected(made.error());
            if (!box.put(*made)) break;
        }
        if (rolls) {
            if (const auto filled = fill(box, outcome.announcements, *drop, kill, claimant, dice, serials); !filled) {
                return Unexpected(filled.error());
            }
        }
        if (!box.empty()) outcome.boxes.push_back(Delivered{.owner = claimant.who, .box = box});
    }
    return outcome;
}

} // namespace game::loot
