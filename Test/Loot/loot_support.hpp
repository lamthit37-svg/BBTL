// Đồ phụ cho test của lõi rơi đồ: dựng bảng rơi nhỏ trong bộ nhớ trên thế giới thử của item (Item/item_support.hpp). Số ở đây là
// số của TEST, đặt tường minh; số thật nằm ở bảng và được kiểm riêng bằng các ca đọc bảng thật.
#pragma once

#include "Item/item_support.hpp"

#include "item/factory.hpp"
#include "item/types.hpp"
#include "loot/roller.hpp"
#include "loot/tables.hpp"
#include "test.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <utility>
#include <vector>

namespace game::test {

// Một gói rơi: danh sách (mã vật phẩm, ô cấp). Ô cấp -1 là để trống.
struct PackSpec {
    std::uint32_t id = 0;
    std::int64_t value = 1000;
    std::int64_t broadcast = -1;
    int force_bind = 0;
    std::vector<std::pair<std::int64_t, int>> items;
};

struct MonsterSpec {
    std::uint32_t id = 0;
    std::int64_t value = 0;
    int type = 0;
    std::vector<std::int64_t> packs;
};

inline constexpr std::size_t kTestPairs = 12;  // số cặp (vật phẩm, cấp) mỗi gói trong bảng thử

[[nodiscard]] inline std::string packs_table(const std::vector<PackSpec>& packs) {
    std::vector<std::string> head{"id", "box_value", "column_2", "column_3"};
    for (std::size_t i = 1; i <= kTestPairs; ++i) {
        head.push_back("item_" + std::to_string(i) + "_id");
        head.push_back("level_" + std::to_string(i));
    }
    std::string out = "# schema 1\n" + join(head) + "\n";
    for (const PackSpec& pack : packs) {
        std::vector<std::string> row{std::to_string(pack.id), std::to_string(pack.value), std::to_string(pack.broadcast),
            std::to_string(pack.force_bind)};
        for (std::size_t i = 0; i < kTestPairs; ++i) {
            if (i < pack.items.size()) {
                row.push_back(std::to_string(pack.items.at(i).first));
                row.push_back(std::to_string(pack.items.at(i).second));
            } else {
                row.emplace_back("-1");
                row.emplace_back("-1");
            }
        }
        out += join(row) + "\n";
    }
    return out;
}

[[nodiscard]] inline std::string monsters_table(const std::vector<MonsterSpec>& monsters) {
    std::vector<std::string> head{"id", "mvalue", "drop_type"};
    for (std::size_t i = 1; i <= loot::kMaxPacksPerMonster; ++i) head.push_back("did_" + std::to_string(i));
    std::string out = "# schema 1\n" + join(head) + "\n";
    for (const MonsterSpec& monster : monsters) {
        std::vector<std::string> row{std::to_string(monster.id), std::to_string(monster.value), std::to_string(monster.type)};
        for (std::size_t i = 0; i < loot::kMaxPacksPerMonster; ++i) {
            row.push_back(i < monster.packs.size() ? std::to_string(monster.packs.at(i)) : "-1");
        }
        out += join(row) + "\n";
    }
    return out;
}

// Hệ số chênh cấp thử: 0 -> 1; -1 -> 0.5; +1 -> 0.25; -2 -> 2 (lớn hơn 1 để thử cả ca hệ số lớn).
inline const char* const kGapsTable = "# schema 1\nlevel_delta\trate\n-2\t2\n-1\t0.5\n0\t1\n1\t0.25\n";

inline constexpr std::uint32_t kTestMonster = 9001;

// Thế giới thử: catalog của item cộng bảng rơi. Không sao chép hay dời được vì Factory và LootTables giữ con trỏ/tham chiếu.
struct LootBench {
    World world = make_world();
    loot::LootTables tables;
    item::Factory factory{world.catalog, world.rolls};
    dice::Dice dice{11};
    item::SerialAllocator serials{1, 1'000'000'000};

    LootBench(const std::string& packs, const std::string& monsters, const std::string& gaps = kGapsTable,
        const std::string& rate_items = {}, const std::string& boxes = {})
        : tables(load(world, packs, monsters, gaps, rate_items, boxes)) {}
    LootBench(const LootBench&) = delete;
    LootBench& operator=(const LootBench&) = delete;
    LootBench(LootBench&&) = delete;
    LootBench& operator=(LootBench&&) = delete;
    ~LootBench() = default;

    [[nodiscard]] static loot::LootTables load(const World& world, const std::string& packs, const std::string& monsters,
        const std::string& gaps, const std::string& rate_items, const std::string& boxes) {
        auto loaded = loot::LootTables::load({.packs = packs, .monsters = monsters, .level_gaps = gaps, .rate_items = rate_items,
            .boxes = boxes}, world.catalog);
        if (!loaded) {
            std::fprintf(stderr, "LootBench: %s\n", loaded.error().c_str());
            std::abort();
        }
        return std::move(*loaded);
    }
};

[[nodiscard]] inline loot::Kill kill_of(std::uint32_t monster, std::uint16_t level, std::uint64_t now = 100) {
    return loot::Kill{.monster = ids::MonsterTemplateId{monster}, .level = level, .origin = item::Origin::kMonster, .now = ids::Tick{now}};
}

[[nodiscard]] inline loot::Claimant claimant_of(std::uint64_t who, std::uint16_t level = 10) {
    return loot::Claimant{.who = ids::CharacterId{who}, .level = level, .wallow_ppm = loot::kPpm, .quest_items = {}};
}

} // namespace game::test
