// Cuộn đồ rơi khi quái chết: xác suất từng gói theo công thức, chọn đều trong gói, chia hộp theo cách chia (thường / thủ lĩnh),
// trần 10 món, đồ nhiệm vụ, nguồn sinh đồ, tất định, và đầu vào xấu. Ca bảng thật so tần suất cuộn với xác suất tính độc lập
// từ tệp bảng.
#include "loot_support.hpp"

#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"
#include "loot/box.hpp"
#include "loot/roller.hpp"
#include "loot/tables.hpp"
#include "loot/types.hpp"
#include "test.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using loot::Claimant;
using loot::Kill;
using loot::KillOutcome;
using loot::Roller;

// |count - n p| trong 6 sigma (cộng 1 cho ca p rất nhỏ): xác suất lệch quá mức này dưới 2e-9.
bool near_binomial(double count, double trials, double p) {
    return std::fabs(count - trials * p) <= 6.0 * std::sqrt(trials * p * (1.0 - p)) + 1.0;
}

KillOutcome roll_ok(const Roller& roller, const Kill& kill, std::span<const Claimant> claimants, dice::Dice& dice,
    item::SerialAllocator& serials) {
    auto outcome = roller.roll_kill(kill, claimants, dice, serials);
    if (!outcome) {
        std::fprintf(stderr, "roll_kill: %s\n", std::string(item::describe(outcome.error())).c_str());
        std::abort();
    }
    return std::move(*outcome);
}

// Một gói một món kPotion, quái giá trị 50, gói giá trị 1000 -> p = 0,05 ở chênh cấp 0.
std::string one_pack_packs() { return packs_table({PackSpec{.id = 1, .value = 1000, .items = {{kPotion, -1}}}}); }

std::string one_pack_monster(int type) {
    return monsters_table({MonsterSpec{.id = kTestMonster, .value = 50, .type = type, .packs = {1}}});
}

// Gói chắc chắn rơi: giá trị gói bằng giá trị quái.
std::string sure_pack(std::uint32_t id, std::vector<std::pair<std::int64_t, int>> items, std::int64_t broadcast = -1, int bind = 0) {
    return packs_table({PackSpec{.id = id, .value = 50, .broadcast = broadcast, .force_bind = bind, .items = std::move(items)}});
}

// ----- xác suất của một gói ----------------------------------------------------------------------------------------------

struct GateCase {
    std::uint16_t monster_level;
    std::uint16_t player_level;
    std::uint32_t wallow_ppm;
    std::uint32_t param_ppm;
    double p;
    const char* name;
};

void gate_frequency(Context& context) {
    constexpr std::array cases{
        GateCase{10, 10, loot::kPpm, loot::kPpm, 0.05, "chênh 0"},
        GateCase{9, 10, loot::kPpm, loot::kPpm, 0.025, "quái thấp hơn một cấp: hệ số 0,5"},
        GateCase{8, 10, loot::kPpm, loot::kPpm, 0.10, "quái thấp hơn hai cấp: hệ số 2"},
        GateCase{11, 10, loot::kPpm, loot::kPpm, 0.0125, "quái cao hơn một cấp: hệ số 0,25"},
        GateCase{15, 10, loot::kPpm, loot::kPpm, 0.05, "chênh ngoài bảng: hệ số 1"},
        GateCase{10, 10, 500'000, loot::kPpm, 0.025, "chống nghiện 0,5"},
        GateCase{10, 10, 0, loot::kPpm, 0.0, "chống nghiện 0"},
        GateCase{10, 10, loot::kPpm, 3 * loot::kPpm, 0.15, "DropParam 3"},
        GateCase{8, 10, loot::kPpm, 3 * loot::kPpm, 0.30, "hệ số 2 x DropParam 3"},
        GateCase{8, 10, 500'000, 3 * loot::kPpm, 0.15, "hệ số 2 x DropParam 3 x chống nghiện 0,5"},
        GateCase{10, 10, 5 * loot::kPpm, loot::kPpm, 0.05, "chống nghiện lớn hơn 1 bị kẹp về 1"},
    };
    constexpr int kKills = 40'000;
    for (const GateCase& c : cases) {
        LootBench bench(one_pack_packs(), one_pack_monster(0));
        const Roller roller(bench.tables, bench.factory, loot::LootConfig{.drop_param_ppm = c.param_ppm});
        Claimant who = claimant_of(1, c.player_level);
        who.wallow_ppm = c.wallow_ppm;
        const std::array<Claimant, 1> claimants{who};
        int boxes = 0;
        for (int i = 0; i < kKills; ++i) {
            const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, c.monster_level), claimants, bench.dice, bench.serials);
            boxes += static_cast<int>(out.boxes.size());
        }
        context.expect(near_binomial(boxes, kKills, c.p), c.name);
    }
}

void config_is_clamped(Context& context) {
    LootBench bench(one_pack_packs(), one_pack_monster(0));
    const Roller huge(bench.tables, bench.factory, loot::LootConfig{.drop_param_ppm = 4'000'000'000U});
    context.expect(huge.config().drop_param_ppm == loot::kMaxDropParamPpm, "DropParam bị kẹp ở trần");
    const Roller no_life(bench.tables, bench.factory, loot::LootConfig{.box_lifetime = ids::TickSpan{-50}});
    context.expect(no_life.config().box_lifetime.count == 1, "hạn hộp tối thiểu một tick");
    const Roller normal(bench.tables, bench.factory);
    context.expect(normal.config().box_lifetime.count == 60'000 / 50, "mặc định 60000 ms ở 20 tick/giây là 1200 tick");
    const loot::DropBox box = normal.new_box(ids::CharacterId{5}, ids::Tick{1000});
    context.expect(box.owner == ids::CharacterId{5} && box.expires_at == ids::Tick{2200} && box.empty() && !box.public_from.has_value(),
        "hộp mới: chủ, hạn = bây giờ + 1200 tick, trống");
    context.expect(!normal.new_box(std::nullopt, ids::Tick{0}).owner.has_value(), "hộp không chủ");
}

// ----- chọn trong gói ----------------------------------------------------------------------------------------------------

void pack_is_uniform(Context& context) {
    const std::array<std::int64_t, 4> ids{kPotion, kHerb, kQuestItem, kGem};
    LootBench bench(sure_pack(1, {{ids[0], -1}, {ids[1], -1}, {ids[2], -1}, {ids[3], -1}}),
        monsters_table({MonsterSpec{.id = kTestMonster, .value = 50, .type = 0, .packs = {1}}}));
    const Roller roller(bench.tables, bench.factory);
    const std::array<Claimant, 1> claimants{claimant_of(1)};
    std::map<std::uint32_t, int> seen;
    constexpr int kKills = 40'000;
    for (int i = 0; i < kKills; ++i) {
        const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), claimants, bench.dice, bench.serials);
        if (out.boxes.size() != 1 || out.boxes.front().box.item_count() != 1) {
            context.expect(false, "gói chắc chắn rơi đúng một món trong một hộp");
            return;
        }
        ++seen[out.boxes.front().box.item(0)->tmpl.value()];
    }
    for (const std::int64_t id : ids) {
        context.expect(near_binomial(seen[static_cast<std::uint32_t>(id)], kKills, 0.25), "bốn món đều nhau");
    }
}

// ----- chia hộp -----------------------------------------------------------------------------------------------------------

void boss_gives_everyone_a_box(Context& context) {
    LootBench bench(sure_pack(1, {{kPotion, -1}}), one_pack_monster(1));
    const Roller roller(bench.tables, bench.factory);
    const std::array<Claimant, 5> claimants{claimant_of(11), claimant_of(12), claimant_of(13), claimant_of(14), claimant_of(15)};
    const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), claimants, bench.dice, bench.serials);
    context.expect(out.boxes.size() == 5, "mỗi người một hộp");
    std::vector<std::uint64_t> serials;
    for (std::size_t i = 0; i < out.boxes.size(); ++i) {
        const loot::Delivered& d = out.boxes.at(i);
        context.expect(d.owner == claimants.at(i).who && d.box.owner == claimants.at(i).who, "hộp theo thứ tự người chia, chủ đúng");
        context.expect(d.box.item_count() == 1 && d.box.item(0)->tmpl == item::TemplateId{kPotion}, "mỗi hộp một món");
        serials.push_back(d.box.item(0)->serial.value());
    }
    std::ranges::sort(serials);
    context.expect(std::ranges::adjacent_find(serials) == serials.end(), "serial các món khác nhau");
    context.expect(out.boxes.front().box.expires_at == ids::Tick{100 + 1200}, "hạn hộp tính từ tick quái chết");
}

void common_gives_one_owner(Context& context) {
    LootBench bench(sure_pack(1, {{kPotion, -1}}), one_pack_monster(0));
    const Roller roller(bench.tables, bench.factory);
    const std::array<Claimant, 4> claimants{claimant_of(21), claimant_of(22), claimant_of(23), claimant_of(24)};
    std::map<std::uint64_t, int> wins;
    constexpr int kKills = 20'000;
    for (int i = 0; i < kKills; ++i) {
        const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), claimants, bench.dice, bench.serials);
        if (out.boxes.size() != 1) {
            context.expect(false, "quái thường: đúng một hộp mỗi lần chết");
            return;
        }
        ++wins[out.boxes.front().owner.value()];
    }
    for (const Claimant& c : claimants) context.expect(near_binomial(wins[c.who.value()], kKills, 0.25), "người nhận đồ được chọn đều");
}

void quest_items_for_everyone(Context& context) {
    LootBench bench(sure_pack(1, {{kPotion, -1}}), one_pack_monster(0));
    const Roller roller(bench.tables, bench.factory);
    const std::array<item::TemplateId, 2> quest_items{item::TemplateId{kQuestItem}, item::TemplateId{kHerb}};
    Claimant second = claimant_of(32);
    second.quest_items = quest_items;
    const std::array<Claimant, 3> claimants{claimant_of(31), second, claimant_of(33)};
    int second_wins = 0;
    constexpr int kKills = 6'000;
    for (int i = 0; i < kKills; ++i) {
        const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), claimants, bench.dice, bench.serials);
        const loot::Delivered* mine = nullptr;
        std::size_t others = 0;
        for (const loot::Delivered& d : out.boxes) {
            if (d.owner == second.who) {
                mine = &d;
            } else {
                ++others;
            }
        }
        if (mine == nullptr) {
            context.expect(false, "người có đồ nhiệm vụ luôn có hộp");
            return;
        }
        const bool won = mine->box.item_count() == 3;
        second_wins += won ? 1 : 0;
        // Đồ nhiệm vụ đứng trước, đồ cuộn sau; người khác có hộp thì hộp đó là phần thưởng của người được chọn.
        const bool order_ok = mine->box.item(0)->tmpl == item::TemplateId{kQuestItem} && mine->box.item(1)->tmpl == item::TemplateId{kHerb}
            && (!won || mine->box.item(2)->tmpl == item::TemplateId{kPotion});
        if (!order_ok || (won ? others != 0 : others != 1) || (!won && mine->box.item_count() != 2)) {
            context.expect(false, "đồ nhiệm vụ đi trước; mỗi lần chết đúng một người nhận đồ cuộn");
            return;
        }
    }
    context.expect(near_binomial(second_wins, kKills, 1.0 / 3.0), "người có đồ nhiệm vụ cũng được chọn nhận đồ cuộn với xác suất 1/3");
}

void unlisted_monster_drops_only_quest_items(Context& context) {
    LootBench bench(sure_pack(1, {{kPotion, -1}}), one_pack_monster(1));
    const Roller roller(bench.tables, bench.factory);
    const std::array<item::TemplateId, 1> quest_items{item::TemplateId{kQuestItem}};
    Claimant holder = claimant_of(41);
    holder.quest_items = quest_items;
    const std::array<Claimant, 2> claimants{holder, claimant_of(42)};
    for (int i = 0; i < 50; ++i) {
        const KillOutcome out = roll_ok(roller, kill_of(kTestMonster + 1, 10), claimants, bench.dice, bench.serials);
        if (out.boxes.size() != 1 || out.boxes.front().owner != holder.who || out.boxes.front().box.item_count() != 1
            || out.boxes.front().box.item(0)->tmpl != item::TemplateId{kQuestItem}) {
            context.expect(false, "quái không có bảng chỉ rơi đồ nhiệm vụ cho người có");
            return;
        }
    }
    context.expect(true, "quái không có bảng");
}

void no_claimants_no_drops(Context& context) {
    LootBench bench(sure_pack(1, {{kPotion, -1}}), one_pack_monster(1));
    const Roller roller(bench.tables, bench.factory);
    const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), {}, bench.dice, bench.serials);
    context.expect(out.boxes.empty() && out.announcements.empty(), "không người chia thì không rơi gì");
    context.expect(bench.serials.cursor() == 1, "không tốn serial");
}

// ----- trần hộp ------------------------------------------------------------------------------------------------------------

void box_capacity(Context& context) {
    std::vector<PackSpec> packs;
    std::vector<std::int64_t> ids;
    for (std::uint32_t id = 1; id <= 15; ++id) {
        packs.push_back(PackSpec{.id = id, .value = 50, .items = {{kPotion, -1}}});
        ids.push_back(id);
    }
    LootBench bench(packs_table(packs), monsters_table({MonsterSpec{.id = kTestMonster, .value = 50, .type = 1, .packs = ids}}));
    const Roller roller(bench.tables, bench.factory);
    const KillOutcome plain = roll_ok(roller, kill_of(kTestMonster, 10), std::array<Claimant, 1>{claimant_of(51)}, bench.dice, bench.serials);
    context.expect(plain.boxes.size() == 1 && plain.boxes.front().box.item_count() == loot::kBoxCapacity,
        "15 gói chắc chắn rơi nhưng hộp chỉ chứa 10");
    // Dừng ngay khi đầy: không tốn serial cho món thứ 11 trở đi.
    context.expect(bench.serials.cursor() == 1 + loot::kBoxCapacity, "không tạo món thừa");

    const std::array<item::TemplateId, loot::kMaxQuestDrops> quest_items{item::TemplateId{kQuestItem}, item::TemplateId{kQuestItem},
        item::TemplateId{kQuestItem}, item::TemplateId{kQuestItem}, item::TemplateId{kQuestItem}};
    Claimant holder = claimant_of(52);
    holder.quest_items = quest_items;
    const KillOutcome mixed = roll_ok(roller, kill_of(kTestMonster, 10), std::array<Claimant, 1>{holder}, bench.dice, bench.serials);
    context.expect(mixed.boxes.size() == 1 && mixed.boxes.front().box.item_count() == loot::kBoxCapacity, "hộp đầy 10");
    int quest_count = 0;
    for (std::size_t i = 0; i < loot::kBoxCapacity; ++i) {
        quest_count += mixed.boxes.front().box.item(i)->tmpl == item::TemplateId{kQuestItem} ? 1 : 0;
    }
    context.expect(quest_count == 5 && mixed.boxes.front().box.item(0)->tmpl == item::TemplateId{kQuestItem}
            && mixed.boxes.front().box.item(4)->tmpl == item::TemplateId{kQuestItem},
        "5 đồ nhiệm vụ đứng trước, đồ cuộn lấp 5 ô còn lại");
}

// ----- nguồn sinh đồ -------------------------------------------------------------------------------------------------------

// Số lần một nhẫn lam có thuộc tính 0..5 mang giá trị đoạn 108 (1080+) trong `samples` lần rơi.
int high_segment_hits(Context& context, int cell, item::Origin kill_origin, int samples) {
    LootBench bench(sure_pack(1, {{kBlueRing, cell}}), one_pack_monster(1));
    const Roller roller(bench.tables, bench.factory);
    int hits = 0;
    for (int i = 0; i < samples; ++i) {
        Kill kill = kill_of(kTestMonster, 10);
        kill.origin = kill_origin;
        const KillOutcome out = roll_ok(roller, kill, std::array<Claimant, 1>{claimant_of(61)}, bench.dice, bench.serials);
        if (out.boxes.size() != 1 || out.boxes.front().box.item(0) == nullptr) {
            context.expect(false, "gói chắc chắn rơi nhẫn lam");
            return -1;
        }
        const item::Instance& ring = *out.boxes.front().box.item(0);
        for (std::uint8_t k = 0; k < ring.attr_count; ++k) {
            const item::AttrValue& attr = ring.attrs.at(k);
            if (attr.id.value() < 6 && attr.value >= 1080) ++hits;
        }
    }
    return hits;
}

void origin_mapping(Context& context) {
    // Bảng ItemSeg thử: nguồn 0 (quái thường) chọn lệch đoạn 0 hay 8 đều nhau, mọi nguồn khác luôn lệch 0.
    constexpr int kSamples = 400;
    context.expect(high_segment_hits(context, -1, item::Origin::kMonster, kSamples) > 100, "ô cấp trống, quái thường: có đoạn cao");
    context.expect(high_segment_hits(context, -1, item::Origin::kLeader, kSamples) == 0, "ô cấp trống, quái thủ lĩnh: không đoạn cao");
    context.expect(high_segment_hits(context, 3, item::Origin::kMonster, kSamples) == 0, "ô cấp 3 (rương) thắng hạng quái thường");
    context.expect(high_segment_hits(context, 0, item::Origin::kDailyBoss, kSamples) > 100, "ô cấp 0 là quái thường dù quái là boss");
}

// ----- ép khoá và thông báo ------------------------------------------------------------------------------------------------

void bind_and_announcements(Context& context) {
    {
        LootBench bench(sure_pack(1, {{kPotion, -1}}, 7, 1), one_pack_monster(1));
        const Roller roller(bench.tables, bench.factory);
        const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), std::array<Claimant, 2>{claimant_of(71), claimant_of(72)},
            bench.dice, bench.serials);
        context.expect(out.boxes.size() == 2 && out.announcements.size() == 2, "hai hộp, hai thông báo");
        for (std::size_t i = 0; i < out.boxes.size(); ++i) {
            const item::Instance& made = *out.boxes.at(i).box.item(0);
            context.expect(made.bound, "gói ép khoá: đồ khoá ngay lúc rơi");
            const loot::Announcement& note = out.announcements.at(i);
            context.expect(note.owner == out.boxes.at(i).owner && note.broadcast == 7 && note.item == made.tmpl && note.serial == made.serial,
                "thông báo mang chủ, loại phát thanh, mã và serial của món");
        }
    }
    {
        LootBench bench(sure_pack(1, {{kPotion, -1}}), one_pack_monster(1));
        const Roller roller(bench.tables, bench.factory);
        const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), std::array<Claimant, 1>{claimant_of(73)}, bench.dice, bench.serials);
        context.expect(out.boxes.size() == 1 && out.announcements.empty() && !out.boxes.front().box.item(0)->bound,
            "gói thường: không thông báo, không ép khoá");
    }
}

// ----- tất định và đầu vào xấu -----------------------------------------------------------------------------------------------

void deterministic(Context& context) {
    const auto run = [](std::uint64_t seed) {
        LootBench bench(sure_pack(1, {{kPotion, -1}, {kBlueRing, -1}, {kHerb, -1}}), one_pack_monster(1));
        const Roller roller(bench.tables, bench.factory);
        dice::Dice dice(seed);
        item::SerialAllocator serials(1, 1'000'000);
        std::vector<item::Instance> items;
        for (int i = 0; i < 200; ++i) {
            const KillOutcome out = roll_ok(roller, kill_of(kTestMonster, 10), std::array<Claimant, 2>{claimant_of(81), claimant_of(82)},
                dice, serials);
            for (const loot::Delivered& d : out.boxes) {
                for (const auto& slot : d.box.slots) {
                    if (slot) items.push_back(*slot);
                }
            }
        }
        return items;
    };
    const auto first = run(99);
    context.expect(!first.empty() && first == run(99), "cùng hạt giống cho đúng cùng kết quả, kể cả thuộc tính ngẫu nhiên");
    context.expect(first != run(100), "hạt giống khác cho kết quả khác");
}

void bad_requests(Context& context) {
    LootBench bench(sure_pack(1, {{kPotion, -1}}), one_pack_monster(1));
    const Roller roller(bench.tables, bench.factory);
    const std::vector<Claimant> many(loot::kMaxClaimants + 1, claimant_of(1));
    auto too_many = roller.roll_kill(kill_of(kTestMonster, 10), many, bench.dice, bench.serials);
    context.expect(!too_many && too_many.error() == item::Error::kBadCount, "quá 18 người chia");
    const std::vector<Claimant> exactly(loot::kMaxClaimants, claimant_of(1));
    context.expect(roller.roll_kill(kill_of(kTestMonster, 10), exactly, bench.dice, bench.serials).has_value(), "đúng 18 người vẫn được");

    std::vector<item::TemplateId> six(loot::kMaxQuestDrops + 1, item::TemplateId{kQuestItem});
    Claimant greedy = claimant_of(2);
    greedy.quest_items = six;
    auto too_many_quest = roller.roll_kill(kill_of(kTestMonster, 10), std::array<Claimant, 1>{greedy}, bench.dice, bench.serials);
    context.expect(!too_many_quest && too_many_quest.error() == item::Error::kBadCount, "quá 5 đồ nhiệm vụ");

    const std::array<item::TemplateId, 1> ghost{item::TemplateId{12'345'678}};
    Claimant haunted = claimant_of(3);
    haunted.quest_items = ghost;
    auto unknown = roller.roll_kill(kill_of(kTestMonster, 10), std::array<Claimant, 1>{haunted}, bench.dice, bench.serials);
    context.expect(!unknown && unknown.error() == item::Error::kUnknownTemplate, "đồ nhiệm vụ không có trong catalog");

    // Hết serial giữa chừng: lỗi, không trả hộp nào.
    item::SerialAllocator tiny(1, 2);
    auto exhausted = roller.roll_kill(kill_of(kTestMonster, 10), std::array<Claimant, 2>{claimant_of(4), claimant_of(5)}, bench.dice, tiny);
    context.expect(!exhausted && exhausted.error() == item::Error::kSerialsExhausted, "hết serial");

    // Cực đoan của số: cấp lớn nhất, hệ số cực đại, không làm hỏng gì.
    Claimant extreme = claimant_of(6, 65'535);
    extreme.wallow_ppm = 0xFFFF'FFFFU;
    const std::array<Claimant, 1> arr{extreme};
    for (const std::uint16_t level : {std::uint16_t{0}, std::uint16_t{1}, std::uint16_t{65'535}}) {
        context.expect(roller.roll_kill(kill_of(kTestMonster, level), arr, bench.dice, bench.serials).has_value(), "cấp cực đoan");
    }
}

void make_one(Context& context) {
    LootBench bench(one_pack_packs(), one_pack_monster(0));
    const Roller roller(bench.tables, bench.factory);
    const auto bound = roller.make(item::TemplateId{kPotion}, item::Origin::kChest, true, ids::Tick{5}, bench.dice, bench.serials);
    context.expect(bound && bound->bound && bound->count == 1, "make ép khoá");
    const auto loose = roller.make(item::TemplateId{kPotion}, item::Origin::kChest, false, ids::Tick{5}, bench.dice, bench.serials);
    context.expect(loose && !loose->bound && loose->serial != bound->serial, "make không ép khoá, serial mới");
    const auto bad = roller.make(item::TemplateId{1}, item::Origin::kChest, false, ids::Tick{5}, bench.dice, bench.serials);
    context.expect(!bad && bad.error() == item::Error::kUnknownTemplate, "make với mã không có");
}

// ----- bảng thật -------------------------------------------------------------------------------------------------------------

#ifdef GAME_SERVER_TABLES

// Xác suất mỗi gói của một quái, tính độc lập bằng double từ các dòng tệp.
struct RealExpect {
    double mean_items = 0;      // kỳ vọng số món mỗi lần cuộn cho một người
    double variance_items = 0;  // phương sai của số món (các gói độc lập)
};

void real_tables(Context& context) {
    const std::string root = GAME_SERVER_TABLES;
    const auto real = load_real(context);
    if (!real) return;
    const std::string packs_text = read_text(root + "/server/drop_packages.tsv");
    const std::string monsters_text = read_text(root + "/server/monster_drops.tsv");
    const std::string gaps_text = read_text(root + "/server/drop_level_gap_factors.tsv");
    auto loaded = loot::LootTables::load({.packs = packs_text, .monsters = monsters_text, .level_gaps = gaps_text}, real->catalog);
    if (!loaded) {
        context.expect(false, loaded.error());
        return;
    }
    const item::Factory factory(real->catalog, real->rolls);

    // Mọi mục của mọi gói tạo được với đúng nguồn sinh đồ của ô cấp (trang bị lam đi qua bảng ItemSeg thật).
    {
        dice::Dice dice(5);
        item::SerialAllocator serials(1, 10'000'000);
        const Roller roller(*loaded, factory);
        std::size_t created = 0;
        std::size_t failed = 0;
        for (const auto& row : tsv_rows(packs_text)) {
            if (row.empty() || row.front() == "id") continue;
            const loot::Pack* pack = loaded->pack(loot::PackId{static_cast<std::uint32_t>(std::stoul(row.front()))});
            if (pack == nullptr) {
                ++failed;
                continue;
            }
            for (const loot::PackEntry& entry : loaded->entries(*pack)) {
                const item::Origin origin = entry.origin < 0 ? item::Origin::kMonster : static_cast<item::Origin>(entry.origin);
                const auto made = roller.make(entry.item, origin, pack->force_bind, ids::Tick{1}, dice, serials);
                ++created;
                failed += made.has_value() ? 0U : 1U;
            }
        }
        context.expect(created > 25'000 && failed == 0, "mọi mục của mọi gói tạo được vật phẩm");
    }

    // Tần suất cuộn: chọn một quái thường và một quái thủ lĩnh có kỳ vọng vừa phải, chênh cấp cho hệ số khác 1.
    const auto gaps = tsv_rows(gaps_text);
    int delta = 0;
    double gap = 1.0;
    for (std::size_t r = 1; r < gaps.size(); ++r) {
        if (std::stod(gaps.at(r).at(1)) == 0.5) {
            delta = std::stoi(gaps.at(r).at(0));
            gap = 0.5;
            break;
        }
    }
    context.expect(gap == 0.5, "bảng thật có chênh cấp với hệ số 0,5");
    const auto pack_rows = tsv_rows(packs_text);
    std::map<std::uint32_t, std::pair<std::int64_t, bool>> pack_info;  // id -> (giá trị, còn mục dùng được)
    for (std::size_t r = 1; r < pack_rows.size(); ++r) {
        const auto id = static_cast<std::uint32_t>(std::stoul(pack_rows.at(r).at(0)));
        const loot::Pack* pack = loaded->pack(loot::PackId{id});
        pack_info[id] = {std::stoll(pack_rows.at(r).at(1)), pack != nullptr && pack->count > 0};
    }
    std::map<int, std::uint32_t> chosen;  // drop_type -> mã quái
    for (const auto& row : tsv_rows(monsters_text)) {
        if (row.empty() || row.front() == "id") continue;
        double mean = 0;
        for (std::size_t col = 3; col < row.size() && row.at(col) != "-1"; ++col) {
            const auto& [value, usable] = pack_info.at(static_cast<std::uint32_t>(std::stoul(row.at(col))));
            mean += usable ? std::min(1.0, static_cast<double>(std::stoll(row.at(1))) / static_cast<double>(value) * gap) : 0.0;
        }
        const int type = std::stoi(row.at(2));
        if (mean > 0.4 && mean < 1.5 && !chosen.contains(type)) chosen[type] = static_cast<std::uint32_t>(std::stoul(row.front()));
    }
    context.expect(chosen.size() == 2, "tìm được một quái thường và một thủ lĩnh để đo");

    for (const auto& [type, monster] : chosen) {
        const loot::MonsterDrop* drop = loaded->monster(ids::MonsterTemplateId{monster});
        if (drop == nullptr) {
            context.expect(false, "quái đã chọn có trong bảng");
            continue;
        }
        RealExpect want;
        for (std::size_t i = 0; i < drop->pack_count; ++i) {
            const loot::Pack* pack = loaded->pack(drop->packs.at(i));
            if (pack == nullptr || pack->count == 0) continue;
            const double p = std::min(1.0, static_cast<double>(drop->value) / static_cast<double>(pack->value) * gap);
            want.mean_items += p;
            want.variance_items += p * (1.0 - p);
        }
        const Roller roller(*loaded, factory);
        dice::Dice dice(1000 + static_cast<std::uint64_t>(type));
        item::SerialAllocator serials(1, 100'000'000);
        constexpr int kKills = 60'000;
        // Người chơi cấp 200, quái cấp 200 + delta nên chênh cấp đúng bằng `delta` (cấp quái không âm khi |delta| <= 200).
        const auto monster_level = static_cast<std::uint16_t>(200 + delta);
        double items = 0;
        for (int i = 0; i < kKills; ++i) {
            const KillOutcome out = roll_ok(roller, kill_of(monster, monster_level), std::array<Claimant, 1>{claimant_of(1, 200)}, dice, serials);
            for (const loot::Delivered& d : out.boxes) items += static_cast<double>(d.box.item_count());
        }
        const double sigma = std::sqrt(want.variance_items * kKills);
        context.expect(std::fabs(items - want.mean_items * kKills) <= 6.0 * sigma + 1.0,
            type == 0 ? "quái thường: số món trung bình khớp công thức" : "quái thủ lĩnh: số món trung bình khớp công thức");
    }
}
#endif

void real_tables_cases(Context& context) {
#ifdef GAME_SERVER_TABLES
    real_tables(context);
#else
    static_cast<void>(context);
#endif
}

constexpr std::array kCases{
    Case{"gate_frequency", gate_frequency},
    Case{"config_is_clamped", config_is_clamped},
    Case{"pack_is_uniform", pack_is_uniform},
    Case{"boss_gives_everyone_a_box", boss_gives_everyone_a_box},
    Case{"common_gives_one_owner", common_gives_one_owner},
    Case{"quest_items_for_everyone", quest_items_for_everyone},
    Case{"unlisted_monster_drops_only_quest_items", unlisted_monster_drops_only_quest_items},
    Case{"no_claimants_no_drops", no_claimants_no_drops},
    Case{"box_capacity", box_capacity},
    Case{"origin_mapping", origin_mapping},
    Case{"bind_and_announcements", bind_and_announcements},
    Case{"deterministic", deterministic},
    Case{"bad_requests", bad_requests},
    Case{"make_one", make_one},
    Case{"real_tables_cases", real_tables_cases},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
