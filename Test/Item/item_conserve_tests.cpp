// Bảo toàn: 10.000 thao tác ngẫu nhiên (hạt giống cố định) lên túi, kho, trang bị và ví, gồm cả đầu vào thù địch.
// Một mô hình độc lập theo dõi tổng số lượng từng mẫu vật phẩm và từng tài khoản tiền; sau mỗi lô thao tác được áp
// dụng, trạng thái thật phải khớp mô hình và mọi bất biến (cỡ chồng, serial duy nhất, đúng túi, đúng điểm lắp, trần ví).
// Thao tác bị từ chối phải để lớp phủ của Planner NGUYÊN: kế hoạch trước và sau lệnh hỏng bằng nhau.
// Tiền: mô hình tự dự đoán thao tác tiền nào được chấp nhận (không hỏi bộ cài đặt).
#include "item_support.hpp"

#include "item/catalog.hpp"
#include "item/codec.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/types.hpp"
#include "test.hpp"

#include "dice/dice.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <limits>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

constexpr std::array<std::uint32_t, 11> kPool{kPotion, kUniqueRing, kHerb, kQuestItem, kSword, kSectSword, kWhiteRing, kCharm,
    kBlueRing, kPickBound, kNoSell};

struct Model {
    std::map<std::uint32_t, std::int64_t> items;
    std::array<std::int64_t, item::kAccountSlots> money{};

    friend bool operator==(const Model&, const Model&) = default;
};

// Một lượt chạy: trạng thái thật, mô hình đã chốt và mô hình đang dựng của lô hiện tại.
struct Run {
    Bench bench;
    dice::Dice rng{20261014};
    Model committed;
    Model pending;
    std::uint64_t ops = 0;
    std::uint64_t accepted = 0;
    std::uint64_t rejected = 0;
    std::array<std::uint64_t, 18> kind_total{};
    std::array<std::uint64_t, 18> kind_accepted{};
    std::vector<std::string> problems;

    Run() = default;
    Run(const Run&) = delete;
    Run& operator=(const Run&) = delete;
    Run(Run&&) = delete;
    Run& operator=(Run&&) = delete;
    ~Run() = default;

    void fail(std::string what) {
        if (problems.size() < 8) problems.push_back(std::move(what) + " (thao tác thứ " + std::to_string(ops) + ")");
    }
    std::uint64_t pick(std::uint64_t bound) { return rng.below(bound); }
};

item::Place any_place(Run& run, bool include_equip) {
    const std::uint64_t n = run.pick(include_equip ? 5 : 4);
    static constexpr std::array<item::Place, 5> kPlaces{item::Place::kBaseBag, item::Place::kMaterialBag, item::Place::kQuestBag,
        item::Place::kBank, item::Place::kEquip};
    return kPlaces.at(static_cast<std::size_t>(n));
}

// Ô ngẫu nhiên: phần lớn lần chọn ô đang có đồ (để thao tác được chấp nhận đủ nhiều), còn lại là ô bất kỳ, trống hay
// thù địch (ngoài miền, nơi chứa lạ).
item::SlotRef any_slot(Run& run, const item::Planner& p, bool include_equip = true) {
    if (run.pick(40) == 0) return {.place = static_cast<item::Place>(9), .index = static_cast<std::uint16_t>(run.pick(70000))};
    if (run.pick(10) < 6) {
        std::vector<item::SlotRef> held;
        for (std::size_t pl = 0; pl < item::kPlaceCount; ++pl) {
            const auto place = static_cast<item::Place>(pl);
            if (place == item::Place::kEquip && !include_equip) continue;
            for (std::uint16_t i = 0; i < run.bench.inventory.unlocked(place); ++i) {
                const item::SlotRef where{.place = place, .index = i};
                if (p.get(where) != nullptr) held.push_back(where);
            }
        }
        if (!held.empty()) return held.at(run.pick(held.size()));
    }
    const item::Place place = any_place(run, include_equip);
    if (run.pick(25) == 0) return {.place = place, .index = static_cast<std::uint16_t>(run.pick(70000))};
    const std::uint64_t span = place == item::Place::kEquip ? 26 : 24;
    return {.place = place, .index = static_cast<std::uint16_t>(run.pick(span))};
}

// Cặp ô cho split / merge: bảy phần mười lần chọn cặp "có khả năng hợp lệ" (nguồn có chồng, đích trống hay cùng loại),
// còn lại hoàn toàn ngẫu nhiên để vẫn thử ca hỏng.
std::pair<item::SlotRef, item::SlotRef> smart_pair(Run& run, const item::Planner& p, bool want_empty_target) {
    std::vector<item::SlotRef> held;
    for (std::size_t pl = 0; pl < item::kPlaceCount - 1; ++pl) {
        const auto place = static_cast<item::Place>(pl);
        for (std::uint16_t i = 0; i < run.bench.inventory.unlocked(place); ++i) {
            const item::SlotRef where{.place = place, .index = i};
            const item::Instance* here = p.get(where);
            if (here != nullptr && (!want_empty_target || here->count > 1)) held.push_back(where);
        }
    }
    if (run.pick(10) < 7 && !held.empty()) {
        const item::SlotRef from = held.at(run.pick(held.size()));
        std::vector<item::SlotRef> targets;
        for (std::uint16_t i = 0; i < run.bench.inventory.unlocked(from.place); ++i) {
            const item::SlotRef to{.place = from.place, .index = i};
            const item::Instance* there = p.get(to);
            if (to == from) continue;
            if (want_empty_target ? there == nullptr : (there != nullptr && there->tmpl == p.get(from)->tmpl)) targets.push_back(to);
        }
        if (!targets.empty()) return {from, targets.at(run.pick(targets.size()))};
    }
    return {any_slot(run, p, false), any_slot(run, p, false)};
}

// Ô túi đạo cụ đang chứa trang bị (phần lớn lần), để equip được thử ở những ô có thể hợp lệ.
item::SlotRef smart_equip_source(Run& run, const item::Planner& p) {
    std::vector<item::SlotRef> gear;
    for (std::uint16_t i = 0; i < run.bench.inventory.unlocked(item::Place::kBaseBag); ++i) {
        const item::SlotRef where{.place = item::Place::kBaseBag, .index = i};
        const item::Instance* here = p.get(where);
        const item::Template* tmpl = here != nullptr ? run.bench.world.catalog.find(here->tmpl) : nullptr;
        if (tmpl != nullptr && tmpl->kind == item::Kind::kEquipment) gear.push_back(where);
    }
    if (run.pick(10) < 8 && !gear.empty()) return gear.at(run.pick(gear.size()));
    return any_slot(run, p, false);
}

std::uint8_t smart_point(Run& run, const item::Planner& p) {
    std::vector<std::uint8_t> worn;
    for (std::uint8_t i = 0; i < item::kEquipSlots; ++i) {
        if (p.get({.place = item::Place::kEquip, .index = i}) != nullptr) worn.push_back(i);
    }
    if (run.pick(10) < 7 && !worn.empty()) return worn.at(run.pick(worn.size()));
    return static_cast<std::uint8_t>(run.pick(30));
}

std::int64_t amount_choice(Run& run, std::int64_t free_room, std::int64_t have) {
    switch (run.pick(9)) {
    case 0: return 1;
    case 1: return static_cast<std::int64_t>(run.pick(1000)) + 1;
    case 2: return free_room;
    case 3: return free_room + 1;
    case 4: return have;
    case 5: return have + 1;
    case 6: return std::numeric_limits<std::int64_t>::max();
    case 7: return -static_cast<std::int64_t>(run.pick(50));
    default: return static_cast<std::int64_t>(run.pick(1'000'000)) + 1;
    }
}

// Một thao tác lên Planner `p`. Cập nhật mô hình đang dựng khi thao tác thành công. Trả true khi được chấp nhận.
bool one_op(Run& run, item::Planner& p) {
    ++run.ops;
    const item::Planner before = p;
    const Model model_before = run.pending;
    bool predicted_known = false;
    bool predicted_ok = false;
    item::Result result;
    const std::uint64_t kind = run.pick(18);
    ++run.kind_total.at(static_cast<std::size_t>(kind));
    switch (kind) {
    case 0:
    case 1:
    case 2: {
        const std::uint32_t id = kPool.at(run.pick(kPool.size()));
        const item::Template* tmpl = run.bench.world.catalog.find(item::TemplateId{id});
        auto count = static_cast<std::uint16_t>(1 + run.pick(tmpl->stack_max > 1 ? std::uint64_t{tmpl->stack_max} * 2 : 1));
        item::Instance fresh = run.bench.make(id, 1);
        fresh.count = count;
        result = run.pick(6) == 0 ? p.add_to(item::Place::kBank, fresh) : p.add(fresh);
        if (result) run.pending.items[id] += count;
        break;
    }
    case 3: {
        const std::uint32_t id = kPool.at(run.pick(kPool.size()));
        const auto count = static_cast<std::uint32_t>(run.pick(80));
        std::int64_t have = 0;
        for (const item::Place place : {item::Place::kBaseBag, item::Place::kMaterialBag, item::Place::kQuestBag}) {
            for (std::uint16_t i = 0; i < run.bench.inventory.unlocked(place); ++i) {
                const item::SlotRef where{.place = place, .index = i};
                const item::Instance* held = p.get(where);
                if (held != nullptr && held->tmpl.value() == id && !run.bench.inventory.locked(where)) have += held->count;
            }
        }
        predicted_known = true;
        predicted_ok = count > 0 && have >= static_cast<std::int64_t>(count);
        result = p.remove_count(item::TemplateId{id}, count);
        if (result) run.pending.items[id] -= count;
        break;
    }
    case 4: {
        const item::SlotRef where = any_slot(run, p);
        const item::Instance* held = p.get(where);
        const auto count = static_cast<std::uint16_t>(run.pick(30));
        const bool in_range = static_cast<std::size_t>(where.place) < item::kPlaceCount && where.index < run.bench.inventory.unlocked(where.place);
        predicted_known = true;
        predicted_ok = in_range && held != nullptr && !run.bench.inventory.locked(where) && count >= 1 && count <= held->count;
        const std::uint32_t id = held != nullptr ? held->tmpl.value() : 0;
        result = p.remove_at(where, count);
        if (result) run.pending.items[id] -= count;
        break;
    }
    case 5: result = p.move(any_slot(run, p, false), any_slot(run, p, false)); break;
    case 6: {
        const auto [from, to] = smart_pair(run, p, true);
        const item::Instance* held = p.get(from);
        const auto count = static_cast<std::uint16_t>(held != nullptr && held->count > 1 && run.pick(8) != 0 ? 1U + run.pick(held->count - 1U) : run.pick(25));
        result = p.split(from, to, count);
        break;
    }
    case 7: {
        const auto [from, to] = smart_pair(run, p, false);
        result = p.merge(from, to);
        break;
    }
    case 8: result = p.sort(any_place(run, true)); break;
    case 9: {
        // Phần lớn lần người mặc đủ cấp và đúng phái 3 (kiếm phái), còn lại ngẫu nhiên để thử các lỗi cấp và phái.
        const bool strong = run.pick(10) < 7;
        result = p.equip(smart_equip_source(run, p), item::Actor{.level = static_cast<std::uint16_t>(strong ? 30 : 1 + run.pick(30)),
            .sect = static_cast<std::uint8_t>(strong ? 3 : run.pick(6)), .sex = item::kAnySex});
        break;
    }
    case 10: result = p.unequip(smart_point(run, p)); break;
    case 11: result = p.identify(any_slot(run, p)); break;
    case 12: result = run.pick(2) == 0 ? p.wear_armor(static_cast<std::uint16_t>(1 + run.pick(5))) : p.wear_weapon(static_cast<std::uint16_t>(1 + run.pick(5))); break;
    case 13: {
        const std::int64_t gold_before = p.balance(item::account_of(item::Currency::kGold));
        result = p.repair(any_slot(run, p), static_cast<std::uint32_t>(run.pick(2000)));
        if (result) {
            const std::int64_t spent = gold_before - p.balance(item::account_of(item::Currency::kGold));
            if (spent < 0) run.fail("sửa đồ làm tiền tăng");
            run.pending.money.at(static_cast<std::size_t>(item::Currency::kGold)) -= spent;
        }
        break;
    }
    case 14:
    case 15: {
        const std::uint64_t raw = run.pick(20);
        const auto currency = static_cast<item::Currency>(raw <= 17 ? raw : 255);
        const bool valid = item::is_valid_currency(static_cast<std::uint8_t>(currency));
        const auto account = static_cast<std::size_t>(currency);
        const std::int64_t have = valid ? run.pending.money.at(account) : 0;
        const std::int64_t cap = valid ? run.bench.inventory.wallet().cap(item::account_of(currency)) : 0;
        const std::int64_t amount = amount_choice(run, cap - have, have);
        predicted_known = true;
        if (kind == 14) {
            predicted_ok = valid && amount > 0 && amount <= cap - have;
            result = p.earn(currency, amount);
            if (result) run.pending.money.at(account) += amount;
        } else {
            predicted_ok = valid && amount > 0 && amount <= have;
            result = p.spend(currency, amount);
            if (result) run.pending.money.at(account) -= amount;
        }
        break;
    }
    default: {
        constexpr auto kGoldIndex = static_cast<std::size_t>(item::Currency::kGold);
        const std::int64_t gold = run.pending.money.at(kGoldIndex);
        const std::int64_t bank = run.pending.money.at(0);
        const std::int64_t bank_cap = run.bench.inventory.wallet().cap(item::Account::kBankGold);
        const std::int64_t gold_cap = run.bench.inventory.wallet().cap(item::account_of(item::Currency::kGold));
        predicted_known = true;
        if (kind == 16) {
            const std::int64_t amount = amount_choice(run, bank_cap - bank, gold);
            predicted_ok = amount > 0 && amount <= gold && amount <= bank_cap - bank;
            result = p.deposit_gold(amount);
            if (result) {
                run.pending.money.at(kGoldIndex) -= amount;
                run.pending.money.at(0) += amount;
            }
        } else {
            const std::int64_t amount = amount_choice(run, gold_cap - gold, bank);
            predicted_ok = amount > 0 && amount <= bank && amount <= gold_cap - gold;
            result = p.withdraw_gold(amount);
            if (result) {
                run.pending.money.at(kGoldIndex) += amount;
                run.pending.money.at(0) -= amount;
            }
        }
        break;
    }
    }
    if (predicted_known && result.has_value() != predicted_ok) run.fail("mô hình dự đoán khác kết quả (loại " + std::to_string(kind) + ")");
    if (result) {
        ++run.kind_accepted.at(static_cast<std::size_t>(kind));
        return true;
    }
    // Thao tác hỏng: mô hình và lớp phủ không được đổi.
    if (run.pending != model_before) run.fail("thao tác hỏng làm đổi mô hình");
    if (!(item::Planner(before).finish() == item::Planner(p).finish())) {
        run.fail("thao tác hỏng làm đổi lớp phủ (loại " + std::to_string(kind) + ", lỗi " + std::string(item::describe(result.error())) + ")");
    }
    return false;
}

// Bất biến của trạng thái thật + khớp mô hình. Trả lỗi đầu tiên hoặc rỗng.
std::string check_state(Run& run) {
    const item::Inventory& inv = run.bench.inventory;
    const item::Catalog& catalog = run.bench.world.catalog;
    std::map<std::uint32_t, std::int64_t> totals;
    std::vector<std::uint64_t> serials;
    for (std::size_t p = 0; p < item::kPlaceCount; ++p) {
        const auto place = static_cast<item::Place>(p);
        std::uint16_t index = 0;
        for (const std::optional<item::Instance>& cell : inv.view(place)) {
            const std::uint16_t here = index++;
            if (!cell) continue;
            const item::Template* tmpl = catalog.find(cell->tmpl);
            if (tmpl == nullptr) return "mẫu không có trong danh mục";
            if (cell->count == 0 || cell->count > tmpl->stack_max) return "cỡ chồng ngoài miền";
            if (tmpl->kind == item::Kind::kEquipment && cell->durability > tmpl->equip.max_durability) return "độ bền vượt tối đa";
            if (item::is_bag(place) && tmpl->home != place) return "đồ nằm sai túi";
            if (place == item::Place::kBank && tmpl->home == item::Place::kQuestBag) return "đồ nhiệm vụ trong kho";
            if (place == item::Place::kEquip) {
                const bool fits = here == tmpl->equip.point || (tmpl->equip.point == item::kEquipRing && here == item::kEquipRing2) ||
                    (tmpl->equip.point == item::kEquipCharm && here == item::kEquipCharm2);
                if (tmpl->kind != item::Kind::kEquipment || !fits) return "đồ mặc sai điểm lắp";
            }
            totals[cell->tmpl.value()] += cell->count;
            serials.push_back(cell->serial.value());
        }
    }
    std::ranges::sort(serials);
    if (std::ranges::adjacent_find(serials) != serials.end()) return "serial trùng";
    for (const auto& [id, count] : totals) {
        const auto it = run.committed.items.find(id);
        if (count != (it == run.committed.items.end() ? 0 : it->second)) return "tổng số lượng mẫu " + std::to_string(id) + " lệch mô hình";
    }
    for (const auto& [id, count] : run.committed.items) {
        if (count != 0 && !totals.contains(id)) return "mẫu " + std::to_string(id) + " biến mất";
        if (count < 0) return "mô hình âm";
    }
    for (std::size_t a = 0; a < item::kAccountSlots; ++a) {
        const std::int64_t balance = inv.wallet().balance(static_cast<item::Account>(a));
        if (balance != run.committed.money.at(a)) return "số dư tài khoản " + std::to_string(a) + " lệch mô hình";
        if (balance < 0) return "số dư âm";
    }
    if (totals.contains(kUniqueRing) && totals[kUniqueRing] > 1) return "đồ duy nhất có nhiều hơn một";
    return {};
}

void random_operations(Context& context) {
    Run run;
    std::uint64_t batches = 0;
    while (run.ops < 10000 && run.problems.empty()) {
        // Đôi khi khoá/mở một ô túi giữa hai lô; ô khoá phải không đổi qua mọi kế hoạch.
        if (run.pick(20) == 0) {
            const item::SlotRef where{.place = item::Place::kBaseBag, .index = static_cast<std::uint16_t>(run.pick(20))};
            if (!run.bench.inventory.set_lock(where, !run.bench.inventory.locked(where))) run.fail("khoá ô");
        }
        item::Planner planner = run.bench.planner();
        run.pending = run.committed;
        const std::uint64_t batch = 1 + run.pick(5);
        for (std::uint64_t i = 0; i < batch; ++i) {
            if (one_op(run, planner)) {
                ++run.accepted;
            } else {
                ++run.rejected;
            }
        }
        std::vector<std::pair<item::SlotRef, std::optional<item::Instance>>> locked_before;
        for (std::uint16_t i = 0; i < run.bench.inventory.unlocked(item::Place::kBaseBag); ++i) {
            const item::SlotRef where{.place = item::Place::kBaseBag, .index = i};
            if (!run.bench.inventory.locked(where)) continue;
            const item::Instance* held = run.bench.inventory.get(where);
            locked_before.emplace_back(where, held != nullptr ? std::optional<item::Instance>(*held) : std::nullopt);
        }
        const item::Plan plan = std::move(planner).finish();
        const auto applied = run.bench.inventory.apply(plan);
        if (!applied) {
            run.fail(std::string("kế hoạch do Planner dựng không áp dụng được: ") + std::string(item::describe(applied.error())));
            break;
        }
        run.committed = run.pending;
        ++batches;
        for (const auto& [where, expected] : locked_before) {
            const item::Instance* now = run.bench.inventory.get(where);
            if (expected.has_value() != (now != nullptr) || (now != nullptr && !(*now == *expected))) run.fail("ô khoá bị đổi");
        }
        if (const std::string bad = check_state(run); !bad.empty()) run.fail(bad);
        // Thỉnh thoảng đi-về qua bản ghi nhị phân giữa chừng: nội dung không đổi, kế hoạch cũ hết hiệu lực.
        if (batches % 50 == 0) {
            const auto before = contents(run.bench.inventory);
            item::Inventory copy(run.bench.world.limits);
            const bool good = item::decode_bags(*item::encode_bags(run.bench.inventory), run.bench.world.catalog, copy) &&
                item::decode_equipment(*item::encode_equipment(run.bench.inventory), run.bench.world.catalog, copy) &&
                item::decode_bank(*item::encode_bank(run.bench.inventory), run.bench.world.catalog, copy) &&
                item::decode_wallet(*item::encode_wallet(run.bench.inventory), copy);
            if (!good || contents(copy) != before) run.fail("đi-về bản ghi làm đổi nội dung");
        }
    }
    for (const std::string& problem : run.problems) {
        std::fprintf(stderr, "item_conserve: %s\n", problem.c_str());
        context.expect(false, "vi phạm bảo toàn");
    }
    context.expect(run.problems.empty(), "10.000 thao tác không vi phạm bất biến nào");
    context.expect(run.ops >= 10000, "đủ 10.000 thao tác");
    // Cả hai nhánh phải được chạy với số lượng đáng kể, nếu không phép thử là vô nghĩa.
    context.expect(run.accepted > 2000 && run.rejected > 2000, "đủ cả thao tác được chấp nhận lẫn bị từ chối");
    for (std::size_t k = 0; k < run.kind_total.size(); ++k) {
        std::fprintf(stdout, "[item_conserve] loại %zu: %llu thử, %llu chấp nhận\n", k, static_cast<unsigned long long>(run.kind_total.at(k)),
            static_cast<unsigned long long>(run.kind_accepted.at(k)));
        context.expect(run.kind_accepted.at(k) >= 10, "mỗi loại thao tác được chấp nhận ít nhất 10 lần");
    }
    std::fprintf(stdout, "[item_conserve] %llu thao tác: %llu chấp nhận, %llu từ chối, %llu lô\n", static_cast<unsigned long long>(run.ops),
        static_cast<unsigned long long>(run.accepted), static_cast<unsigned long long>(run.rejected), static_cast<unsigned long long>(batches));
}

constexpr std::array kCases{
    Case{"random_operations", random_operations},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
