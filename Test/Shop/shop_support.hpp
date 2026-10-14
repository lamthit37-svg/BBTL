// Đồ phụ cho test của lõi cửa hàng: dựng bảng cửa hàng nhỏ trong bộ nhớ trên thế giới thử của item (Item/item_support.hpp). Số ở
// đây là số của TEST, đặt tường minh; số thật nằm ở bảng và được kiểm riêng bằng các ca đọc bảng thật.
#pragma once

#include "Item/item_support.hpp"

#include "item/inventory.hpp"
#include "item/price.hpp"
#include "item/types.hpp"
#include "shop/npc_shop.hpp"
#include "shop/tables.hpp"
#include "shop/trade.hpp"
#include "test.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <expected>
#include <string>
#include <utility>
#include <vector>

namespace game::test {

// Một mặt hàng trong bảng thử. Mã vật phẩm ghi số nguyên để thử cả mã lạ.
struct GoodsSpec {
    std::int64_t item = 0;
    std::string group = "1";
    std::string stock = "-1";
    std::string price = "100";
    std::string discount = "100";
};

struct ShopSpec {
    std::uint32_t id = 1;
    int repair_level = 40;
    int buy_level = 120;
    int repair_type = 1;
    int buy_kind = 9;
    std::string repair_cost = "1";
    std::string repair_rate = "1";
    int currency = 1;
    int can_buy_back = 1;
    std::string scale = "1";
    std::int64_t refresh_ms = 600000;
    int num = 50;
    int random = 0;
    std::string path{};
    std::vector<GoodsSpec> goods{};
};

inline constexpr std::size_t kTestBlocks = 8;  // số khối hàng của bảng thử (bảng thật: 200)

// shops.tsv thử: 14 cột đầu đúng tên, 15 cột chưa rõ nghĩa, rồi `blocks` khối sáu cột.
[[nodiscard]] inline std::string shops_table(const std::vector<ShopSpec>& shops, std::size_t blocks = kTestBlocks) {
    std::vector<std::string> head{"index", "repair_level", "buy_level", "repair_type", "buy_kind", "repair_cost",
        "repair_success_rate", "currency_kind", "can_buy_back", "scale", "time", "column_11", "is_random_shop",
        "random_shop_config_path"};
    for (std::size_t col = head.size(); col < 29; ++col) head.push_back("column_" + std::to_string(col));
    for (std::size_t block = 0; block < blocks; ++block) {
        for (const char* name : {"item", "pnum", "pmax", "price", "discount", "color"}) head.push_back(std::string(name) + "_" + std::to_string(block + 1));
    }
    std::string out = "# schema 1\n" + join(head) + "\n";
    for (const ShopSpec& shop : shops) {
        std::vector<std::string> row{std::to_string(shop.id), std::to_string(shop.repair_level), std::to_string(shop.buy_level),
            std::to_string(shop.repair_type), std::to_string(shop.buy_kind), shop.repair_cost, shop.repair_rate,
            std::to_string(shop.currency), std::to_string(shop.can_buy_back), shop.scale, std::to_string(shop.refresh_ms),
            std::to_string(shop.num), std::to_string(shop.random), shop.path};
        for (std::size_t col = row.size(); col < 29; ++col) row.emplace_back("0");
        for (std::size_t block = 0; block < blocks; ++block) {
            if (block < shop.goods.size()) {
                const GoodsSpec& goods = shop.goods.at(block);
                for (const std::string& cell : {std::to_string(goods.item), goods.group, goods.stock, goods.price, goods.discount, std::string{}}) {
                    row.push_back(cell);
                }
            } else {
                for (const char* cell : {"0", "0", "0", "0", "0", ""}) row.emplace_back(cell);
            }
        }
        out += join(row) + "\n";
    }
    return out;
}

struct PoolSpec {
    std::string key;
    std::int64_t item = 0;
    std::string count = "1";
    std::string per_unit = "1";
    std::string odds_a = "1";
    std::string odds_b{};
    std::string value = "1000";
    std::string rebate{};
    int declared = 1;
};

[[nodiscard]] inline std::string pool_table(const std::vector<PoolSpec>& entries) {
    std::string out = "# schema 1\nshop_key\tmerchandise_id\tid\tcount\tcount_per_unit\todds_1\todds_2\tvalue\trebate\twithin_declared_count\n";
    int index = 0;
    for (const PoolSpec& entry : entries) {
        out += join({entry.key, std::to_string(index++), std::to_string(entry.item), entry.count, entry.per_unit, entry.odds_a,
                   entry.odds_b, entry.value, entry.rebate, std::to_string(entry.declared)})
            + "\n";
    }
    return out;
}

// shop_scene_limits.tsv thử: mỗi dòng (mã cửa hàng, danh sách cảnh), rộng `width` cột cảnh, ô thừa là -1.
[[nodiscard]] inline std::string scenes_table(const std::vector<std::pair<std::uint32_t, std::vector<int>>>& rows, std::size_t width = 6) {
    std::vector<std::string> head{"index"};
    for (std::size_t i = 1; i <= width; ++i) head.push_back("scene_" + std::to_string(i));
    std::string out = "# schema 1\n" + join(head) + "\n";
    for (const auto& [shop, scenes] : rows) {
        std::vector<std::string> row{std::to_string(shop)};
        for (std::size_t i = 0; i < width; ++i) row.push_back(i < scenes.size() ? std::to_string(scenes.at(i)) : "-1");
        out += join(row) + "\n";
    }
    return out;
}

[[nodiscard]] inline std::string junk_table(const std::vector<std::pair<std::uint32_t, std::int64_t>>& rows) {
    std::string out = "# schema 1\ncolumn_0\tcolumn_1\tcolumn_2\tcolumn_3\n";
    int index = 0;
    for (const auto& [id, value] : rows) out += join({std::to_string(index++), std::to_string(id), "0", std::to_string(value)}) + "\n";
    return out;
}

// Chỉ lệnh nạp: thế giới item + bảng cửa hàng. Không sao chép hay dời được vì ShopTables, Factory giữ con trỏ vào World.
struct ShopBench {
    Bench base;
    shop::ShopTables tables;
    ids::Tick now{1000};

    ShopBench(const std::string& shops, const std::string& pool = {}, const std::string& scenes = {}, const std::string& junk = {})
        : tables(load(base.world, shops, pool, scenes, junk)) {}
    ShopBench(const ShopBench&) = delete;
    ShopBench& operator=(const ShopBench&) = delete;
    ShopBench(ShopBench&&) = delete;
    ShopBench& operator=(ShopBench&&) = delete;
    ~ShopBench() = default;

    [[nodiscard]] static shop::ShopTables load(const World& world, const std::string& shops, const std::string& pool,
        const std::string& scenes, const std::string& junk) {
        auto loaded = shop::ShopTables::load({.shops = shops, .scene_limits = scenes, .random_goods = pool, .junk_recycle = junk}, world.catalog);
        if (!loaded) {
            std::fprintf(stderr, "ShopBench: %s\n", loaded.error().c_str());
            std::abort();
        }
        return std::move(*loaded);
    }

    // Mở cửa hàng ở cảnh bất kỳ (bảng thử không giới hạn cảnh trừ khi ca tự dựng).
    [[nodiscard]] shop::NpcShop open(std::uint32_t id, std::uint16_t scene = 1) {
        auto opened = shop::NpcShop::open(tables, shop::ShopId{id}, ids::SceneId{scene}, now, base.dice);
        if (!opened) std::abort();
        return std::move(*opened);
    }

    // Cho ví một khoản (đường nạp từ bản ghi, bỏ qua luật).
    void fund(Currency currency, std::int64_t amount) {
        if (!base.inventory.restore_balance(item::account_of(currency), amount)) std::abort();
    }
    [[nodiscard]] std::int64_t money(Currency currency = Currency::kGold) const { return base.inventory.wallet().balance(currency); }

    // Mua một lượt rồi áp dụng và trừ tồn; trả lỗi của bước nào hỏng đầu tiên.
    [[nodiscard]] Result buy(shop::NpcShop& store, std::size_t line, std::uint16_t groups = 1) {
        Planner planner = base.planner();
        const auto ticket = shop::plan_buy(store, {.line = line, .groups = groups}, base.factory, base.dice, base.serials, now, planner);
        if (!ticket) return std::unexpected(ticket.error());
        if (const auto applied = base.inventory.apply(std::move(planner).finish()); !applied) return std::unexpected(applied.error());
        return store.commit(*ticket);
    }
};

} // namespace game::test
