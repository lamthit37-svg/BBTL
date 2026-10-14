#pragma once
// Cuộn đồ rơi khi quái chết và chia hộp cho những người có quyền.
//
// Nguồn: ItemBoxRuler::CreateItemFromMonsterDrop (cuộn từng gói của quái theo mvalue / box_value, hệ số chênh cấp, DropParam,
// hệ số chống nghiện; chọn đều một vật phẩm trong gói), MonsterDropRuler::CaculateBossDropRuler (BDR_BOSS: mỗi người chia tự
// cuộn một hộp; BDR_COMMON và quái không có dòng bảng: chọn đều một người nhận đồ, người khác chỉ nhận đồ nhiệm vụ), và
// ItemBoxManager::CreateMonsterDropItembox (hộp thu hồi sau DropBoxRecycle) của 2008.
//
// Khác gốc: (1) tử số/mẫu số là số nguyên phần triệu, không dùng double (chance.hpp); (2) người không được chọn ở BDR_COMMON
// không bị cuộn (2008 cuộn rồi vứt, tốn serial và số ngẫu nhiên mà kết quả cho từng người không đổi); (3) hộp tối đa 10 món:
// đồ nhiệm vụ đứng trước, đồ cuộn lấp phần còn lại (2008 ghi tràn mảng khi hơn 10 món); (4) vật phẩm rơi mang nguồn sinh đồ lấy
// từ ô cấp của gói (1..6), để trống thì lấy hạng của quái; (5) việc tìm người có quyền chia (sát thương tối thiểu, nhóm, tầm
// nhìn) là của zone: hàm nhận danh sách người đã lọc.

#include "item/factory.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"
#include "loot/box.hpp"
#include "loot/tables.hpp"
#include "loot/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <vector>

namespace game::loot {

inline constexpr std::uint32_t kMaxDropParamPpm = 100 * kPpm;  // DropParam lớn nhất chấp nhận: gấp 100 lần

struct LootConfig {
    // ConfigInfo.ini DropParam: hệ số rơi toàn cục theo phần triệu. Lớn hơn kMaxDropParamPpm bị kẹp.
    std::uint32_t drop_param_ppm = kPpm;
    // zone.toml [drops] box_recycle_ms đã đổi sang tick (ids::to_ticks). Dưới một tick bị nâng lên một tick.
    ids::TickSpan box_lifetime = ids::to_ticks(60'000, item::kTicksPerSecond);
};

// Một con quái chết.
struct Kill {
    ids::MonsterTemplateId monster;
    std::uint16_t level = 1;
    item::Origin origin = item::Origin::kMonster;  // hạng quái; chỉ dùng khi ô cấp của gói để trống
    ids::Tick now;
};

// Một người có quyền chia đồ (zone đã lọc theo sát thương, nhóm và tầm nhìn).
struct Claimant {
    ids::CharacterId who;
    std::uint16_t level = 1;
    std::uint32_t wallow_ppm = kPpm;                // hệ số chống nghiện; lớn hơn 1,0 bị kẹp về 1,0
    std::span<const item::TemplateId> quest_items;  // đồ nhiệm vụ quái này rơi cho người này (tối đa 5), luôn có mặt
};

struct Delivered {
    ids::CharacterId owner;
    DropBox box;
};

// Thông báo cho nơi gọi phát thanh: vật phẩm rơi từ một gói có loại phát thanh (DropNotify.txt).
struct Announcement {
    ids::CharacterId owner;
    std::int32_t broadcast = -1;
    item::TemplateId item;
    item::Serial serial;
};

struct KillOutcome {
    std::vector<Delivered> boxes;  // theo thứ tự người chia; người không có gì thì không có hộp
    std::vector<Announcement> announcements;
};

class Roller {
public:
    Roller(const LootTables& tables, const item::Factory& factory, const LootConfig& config = {}) noexcept;

    // Cuộn một lần quái chết. Lỗi: kBadCount (quá 18 người chia hay quá 5 đồ nhiệm vụ của một người), kUnknownTemplate (đồ
    // nhiệm vụ không có trong catalog), kSerialsExhausted. Có lỗi thì không trả hộp nào (serial và số ngẫu nhiên đã dùng bỏ
    // phí). Không người chia thì không có gì rơi, kể cả đồ nhiệm vụ.
    [[nodiscard]] std::expected<KillOutcome, item::Error> roll_kill(const Kill& kill, std::span<const Claimant> claimants,
        dice::Dice& dice, item::SerialAllocator& serials) const;

    // Tạo một món ngoài lần quái chết (rương, thưởng, phần thưởng rút thăm): theo nguồn sinh đồ cho trước, tuỳ chọn khoá ngay.
    [[nodiscard]] std::expected<item::Instance, item::Error> make(item::TemplateId tmpl, item::Origin origin,
        bool force_bind, ids::Tick now, dice::Dice& dice, item::SerialAllocator& serials) const;

    // Hộp trống với hạn của cấu hình, chủ rỗng nghĩa là ai cũng nhặt được.
    [[nodiscard]] DropBox new_box(std::optional<ids::CharacterId> owner, ids::Tick now) const noexcept;

    [[nodiscard]] const LootTables& tables() const noexcept { return *tables_; }
    [[nodiscard]] const LootConfig& config() const noexcept { return config_; }

private:
    [[nodiscard]] std::expected<void, item::Error> fill(DropBox& box, std::vector<Announcement>& announcements,
        const MonsterDrop& drop, const Kill& kill, const Claimant& claimant, dice::Dice& dice,
        item::SerialAllocator& serials) const;

    const LootTables* tables_;
    const item::Factory* factory_;
    LootConfig config_;
};

} // namespace game::loot
