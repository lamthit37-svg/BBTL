// Đồ phụ cho test của lò rèn: dựng ba bảng công thức nhỏ trong bộ nhớ trên thế giới thử của item (Item/item_support.hpp). Mã vật
// phẩm của công thức thử mượn mẫu có sẵn của thế giới thử (ngọc, thuốc, thảo dược...): tên mẫu không có nghĩa gì với lò rèn, chỉ
// loại túi và cỡ chồng của chúng là thứ ca test dựa vào. Số thật nằm ở bảng và được kiểm riêng bằng ca đọc bảng thật.
#pragma once

#include "Item/item_support.hpp"

#include "forge/craft.hpp"
#include "forge/tables.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"
#include "test.hpp"

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

struct MeltSpec {
    std::int64_t input = 0;
    std::int64_t output = 0;
    std::int64_t need = 0;
    std::int64_t gold = 0;
    std::int64_t substitute = -1;
};

struct CarveSpec {
    std::int64_t input = 0;
    std::int64_t output = 0;
    std::int64_t need = 0;
    std::int64_t gold = 0;
};

struct AdvanceSpec {
    std::int64_t input = 0;
    std::int64_t output = 0;
    std::int64_t gold = 0;
    std::int64_t count = 1;
    std::int64_t first = -1;
    std::int64_t second = -1;
};

[[nodiscard]] inline std::string melting_table(const std::vector<MeltSpec>& rows) {
    std::string out = "# schema 1\ngem_id\tsmelted_gem_id\trequired_item_id\trequired_money\tsubstitute_item_id\n";
    for (const MeltSpec& r : rows) {
        out += join({std::to_string(r.input), std::to_string(r.output), std::to_string(r.need), std::to_string(r.gold),
                   std::to_string(r.substitute)})
            + "\n";
    }
    return out;
}

[[nodiscard]] inline std::string carving_table(const std::vector<CarveSpec>& rows) {
    std::string out = "# schema 1\ngem_id\tcarved_gem_id\trequired_item_id\trequired_money\n";
    for (const CarveSpec& r : rows) {
        out += join({std::to_string(r.input), std::to_string(r.output), std::to_string(r.need), std::to_string(r.gold)}) + "\n";
    }
    return out;
}

[[nodiscard]] inline std::string advances_table(const std::vector<AdvanceSpec>& rows) {
    std::string out = "# schema 1\nitem_id\tadvanced_item_id\tgold_cost\tmaterial_count\tmaterial_1_id\tmaterial_2_id\n";
    for (const AdvanceSpec& r : rows) {
        out += join({std::to_string(r.input), std::to_string(r.output), std::to_string(r.gold), std::to_string(r.count),
                   std::to_string(r.first), std::to_string(r.second)})
            + "\n";
    }
    return out;
}

// Nạp bảng thử trên danh mục của thế giới thử; trả lỗi nạp (rỗng nếu nạp được).
[[nodiscard]] inline std::string forge_load_error(const forge::ForgeSources& sources) {
    const Bench bench;
    const auto loaded = forge::ForgeTables::load(sources, bench.world.catalog);
    return loaded ? std::string{} : loaded.error();
}

// Thế giới thử + công thức thử. Không sao chép hay dời được vì ForgeTables và Factory giữ con trỏ vào World.
struct ForgeBench {
    Bench base;
    forge::ForgeTables tables;
    ids::Tick now{1000};

    explicit ForgeBench(const forge::ForgeSources& sources) : tables(load(base.world, sources)) {}
    ForgeBench(const ForgeBench&) = delete;
    ForgeBench& operator=(const ForgeBench&) = delete;
    ForgeBench(ForgeBench&&) = delete;
    ForgeBench& operator=(ForgeBench&&) = delete;
    ~ForgeBench() = default;

    [[nodiscard]] static forge::ForgeTables load(const World& world, const forge::ForgeSources& sources) {
        auto loaded = forge::ForgeTables::load(sources, world.catalog);
        if (!loaded) {
            std::fprintf(stderr, "ForgeBench: %s\n", loaded.error().c_str());
            std::abort();
        }
        return std::move(*loaded);
    }

    // Cho ví một khoản (đường nạp từ bản ghi, bỏ qua luật).
    void fund(Currency currency, std::int64_t amount) {
        if (!base.inventory.restore_balance(item::account_of(currency), amount)) std::abort();
    }
    [[nodiscard]] std::int64_t gold() const { return base.inventory.wallet().balance(Currency::kGold); }

    // Dựng kế hoạch chế biến trên một planner mới.
    [[nodiscard]] std::expected<forge::CraftReport, Error> plan(forge::Kind kind, SlotRef from, Planner& planner) {
        return forge::plan_craft(tables, kind, from, base.factory, base.dice, base.serials, now, planner);
    }

    // Chế biến một lượt rồi áp dụng; trả lỗi của bước nào hỏng đầu tiên.
    [[nodiscard]] std::expected<forge::CraftReport, Error> craft(forge::Kind kind, SlotRef from) {
        Planner planner = base.planner();
        auto report = plan(kind, from, planner);
        if (!report) return report;
        if (const auto applied = base.inventory.apply(std::move(planner).finish()); !applied) return std::unexpected(applied.error());
        return report;
    }
};

} // namespace game::test
