// Chế biến ở lò rèn: trừ vật liệu và vàng đúng số, vật liệu thay thế, nguyên tử (lỗi không để lại gì), cờ khoá, cấp serial, và một ca
// bảo toàn trên chuỗi thao tác ngẫu nhiên đối chiếu với mô hình độc lập, rồi chạy mọi công thức của bảng thật.
#include "forge_support.hpp"

#include "forge/craft.hpp"
#include "forge/tables.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/types.hpp"
#include "test.hpp"

#include "dice/dice.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <expected>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using forge::Kind;

// Công thức thử (giá trị của TEST): nung ngọc -> nhẫn (thảo dược, hoặc thuốc thay), chạm bằng món nhiệm vụ -> kiếm, nâng cấp kiếm -> kiếm phái
// bằng hai thảo dược và hai thuốc. kQuestItem ở túi nhiệm vụ còn đầu ra ở túi đạo cụ nên túi đầy là chuyện có thể xảy ra.
struct Standard {
    std::string melting;
    std::string carving;
    std::string advances;
};

constexpr std::int64_t kMeltGold = 500;
constexpr std::int64_t kCarveGold = 200;
constexpr std::int64_t kAdvanceGold = 1000;

Standard standard() {
    return Standard{
        .melting = melting_table({
            MeltSpec{.input = kGem, .output = kWhiteRing, .need = kHerb, .gold = kMeltGold, .substitute = kPotion},
            MeltSpec{.input = kNoSell, .output = kCharm, .need = kHerb, .gold = 0},
        }),
        .carving = carving_table({CarveSpec{.input = kQuestItem, .output = kSword, .need = kHerb, .gold = kCarveGold}}),
        .advances = advances_table(
            {AdvanceSpec{.input = kSword, .output = kSectSword, .gold = kAdvanceGold, .count = 2, .first = kHerb, .second = kPotion}}),
    };
}

item::Plan plan_of(const Planner& planner) {
    Planner copy = planner;
    return std::move(copy).finish();
}

template <typename T>
bool refused(const std::expected<T, Error>& result, Error expected) {
    return !result.has_value() && result.error() == expected;
}

// Cất `count` cái vào túi đúng loại bằng Planner (đường thường), áp dụng ngay.
void give(ForgeBench& bench, std::uint32_t id, std::uint16_t count) {
    Planner planner = bench.base.planner();
    if (!planner.add(bench.base.make(id, count)).has_value() || !bench.base.commit(std::move(planner))) std::abort();
}

// ----- một lượt thành công ------------------------------------------------------------------------------------------------------

void melt_pays_and_produces(Context& context) {
    const Standard s = standard();
    ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
    const Instance gem = bench.base.make(kGem);
    bench.base.put(bag(0), gem);
    give(bench, kHerb, 3);
    bench.fund(Currency::kGold, 1000);
    const std::uint64_t serial_before = bench.base.serials.cursor();

    const auto report = bench.craft(Kind::kMelt, bag(0));
    context.expect(report.has_value(), "nung ngọc thành công");
    if (!report) return;
    context.expect(report->input == TemplateId{kGem} && report->produced.tmpl == TemplateId{kWhiteRing} && report->produced.count == 1
            && report->gold == kMeltGold && !report->used_substitute,
        "báo cáo: món vào, món ra, vàng, không dùng vật liệu thay");
    context.expect(bench.base.inventory.count_of(TemplateId{kGem}) == 0 && bench.base.inventory.count_of(TemplateId{kHerb}) == 2
            && bench.gold() == 1000 - kMeltGold && bench.base.inventory.count_of(TemplateId{kWhiteRing}) == 1,
        "bớt một ngọc, một thảo dược, 500 vàng; thêm một nhẫn");
    const Instance* held = bench.base.inventory.get(bag(0));
    context.expect(held != nullptr && *held == report->produced, "món ra nằm đúng ở ô vừa trống và khớp báo cáo");
    context.expect(report->produced.serial != gem.serial && bench.base.serials.cursor() == serial_before + 1, "đúng một serial mới cho món ra");
}

void substitute_materials(Context& context) {
    const Standard s = standard();
    {
        ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
        bench.base.put(bag(0), bench.base.make(kGem));
        give(bench, kPotion, 2);
        bench.fund(Currency::kGold, kMeltGold);
        const auto report = bench.craft(Kind::kMelt, bag(0));
        context.expect(report && report->used_substitute, "hết thảo dược: dùng thuốc thay");
        context.expect(bench.base.inventory.count_of(TemplateId{kPotion}) == 1 && bench.base.inventory.count_of(TemplateId{kHerb}) == 0 && bench.gold() == 0,
            "chỉ bộ thay thế bị trừ");
    }
    {
        ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
        bench.base.put(bag(0), bench.base.make(kGem));
        give(bench, kPotion, 1);
        give(bench, kHerb, 1);
        bench.fund(Currency::kGold, kMeltGold);
        const auto report = bench.craft(Kind::kMelt, bag(0));
        context.expect(report && !report->used_substitute, "còn cả hai: dùng bộ chính");
        context.expect(bench.base.inventory.count_of(TemplateId{kPotion}) == 1 && bench.base.inventory.count_of(TemplateId{kHerb}) == 0,
            "bộ thay thế nguyên vẹn");
    }
    {
        // Công thức không có vật liệu thay: thiếu là thiếu.
        ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
        bench.base.put(bag(0), bench.base.make(kNoSell));
        give(bench, kPotion, 5);
        context.expect(refused(bench.craft(Kind::kMelt, bag(0)), Error::kNotEnoughItems), "công thức không có bộ thay: kNotEnoughItems");
    }
}

void exact_accounting_of_two_materials(Context& context) {
    const Standard s = standard();
    ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
    bench.base.put(bag(0), bench.base.make(kSword));
    give(bench, kHerb, 5);
    give(bench, kPotion, 7);
    bench.fund(Currency::kGold, 1500);
    const auto report = bench.craft(Kind::kAdvance, bag(0));
    context.expect(report && report->produced.tmpl == TemplateId{kSectSword} && report->gold == kAdvanceGold, "nâng cấp thành công");
    context.expect(bench.base.inventory.count_of(TemplateId{kHerb}) == 3 && bench.base.inventory.count_of(TemplateId{kPotion}) == 5
            && bench.gold() == 500 && bench.base.inventory.count_of(TemplateId{kSword}) == 0 && bench.base.inventory.count_of(TemplateId{kSectSword}) == 1,
        "mỗi vật liệu bớt đúng hai, vàng bớt 1000");
}

void bound_flag_carries(Context& context) {
    const Standard s = standard();
    for (const bool bound : {false, true}) {
        ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
        Instance gem = bench.base.make(kGem);
        gem.bound = bound;
        bench.base.put(bag(0), gem);
        give(bench, kHerb, 1);
        bench.fund(Currency::kGold, kMeltGold);
        const auto report = bench.craft(Kind::kMelt, bag(0));
        context.expect(report && report->produced.bound == bound, bound ? "món vào đã khoá thì món ra khoá" : "món vào chưa khoá thì món ra chưa khoá");
    }
}

void stack_input_loses_one(Context& context) {
    const Standard s = standard();
    ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
    bench.base.put(quest(0), bench.base.make(kQuestItem, 3));
    give(bench, kHerb, 3);
    bench.fund(Currency::kGold, 3 * kCarveGold);
    for (int round = 0; round < 3; ++round) {
        const auto report = bench.craft(Kind::kCarve, quest(0));
        context.expect(report && report->produced.tmpl == TemplateId{kSword}, "chạm một lượt");
        const Instance* left = bench.base.inventory.get(quest(0));
        context.expect(round == 2 ? left == nullptr : left != nullptr && left->count == 2 - round, "chồng nhiệm vụ bớt đúng một cái mỗi lượt");
    }
    context.expect(bench.base.inventory.count_of(TemplateId{kSword}) == 3 && bench.gold() == 0 && bench.base.inventory.count_of(TemplateId{kHerb}) == 0,
        "ba kiếm, hết vàng, hết thảo dược");
    context.expect(refused(bench.craft(Kind::kCarve, quest(0)), Error::kSlotEmpty), "ô đã trống");
}

// ----- lỗi không để lại gì ------------------------------------------------------------------------------------------------------

void failures_leave_nothing(Context& context) {
    const Standard s = standard();
    ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
    bench.base.put(bag(0), bench.base.make(kGem));
    bench.base.put(bag(2), bench.base.make(kSword));
    const auto untouched = fingerprint(bench.base.inventory);
    const std::uint64_t serial_before = bench.base.serials.cursor();

    // Mỗi giai đoạn dùng MỘT planner chung cho mọi lỗi: lỗi nào cũng phải để nó nguyên.
    const auto refuse = [&](Planner& planner, Kind kind, SlotRef from, Error error, const char* what) {
        context.expect(refused(bench.plan(kind, from, planner), error), what);
        context.expect(plan_of(planner).empty(), "planner không đổi sau lỗi");
    };

    // Giai đoạn A: không vật liệu, không vàng.
    Planner a = bench.base.planner();
    refuse(a, Kind::kMelt, bag(2), Error::kNoSuchEntry, "kiếm không có công thức nung");
    refuse(a, Kind::kCarve, bag(0), Error::kNoSuchEntry, "ngọc không có công thức chạm");
    refuse(a, Kind::kMelt, worn(0), Error::kWrongPlace, "ô trang bị");
    refuse(a, Kind::kMelt, bank(0), Error::kWrongPlace, "kho");
    refuse(a, Kind::kMelt, bag(9), Error::kSlotEmpty, "ô trống");
    refuse(a, Kind::kMelt, bag(500), Error::kNoSuchSlot, "ô ngoài miền");
    refuse(a, Kind::kMelt, bag(0), Error::kNotEnoughItems, "không thảo dược, không thuốc");
    context.expect(bench.base.serials.cursor() == serial_before, "lỗi trước khi sinh món không tốn serial");
    context.expect(fingerprint(bench.base.inventory) == untouched, "Inventory không đổi: Planner không bao giờ ghi vào nó");

    // Giai đoạn B: có hai thảo dược, thiếu 1 vàng.
    give(bench, kHerb, 2);
    const std::uint64_t serial_stocked = bench.base.serials.cursor();  // sau khi nạp vật liệu (nạp cũng cấp serial)
    bench.fund(Currency::kGold, kMeltGold - 1);
    Planner b = bench.base.planner();
    refuse(b, Kind::kMelt, bag(0), Error::kInsufficientFunds, "thiếu 1 vàng");
    refuse(b, Kind::kAdvance, bag(2), Error::kNotEnoughItems, "nâng cấp: đủ thảo dược mà không có thuốc");
    context.expect(bench.base.serials.cursor() == serial_stocked, "thiếu vàng hay vật liệu chưa sinh món nên không tốn serial");

    // Giai đoạn C: đủ vàng; vật liệu hay món vào nằm trong ô khoá thì không dùng được.
    bench.fund(Currency::kGold, 5000);
    Planner c = bench.base.planner();
    if (!bench.base.inventory.set_lock(material(0), true)) std::abort();
    refuse(c, Kind::kMelt, bag(0), Error::kNotEnoughItems, "thảo dược trong ô khoá không tính");
    if (!bench.base.inventory.set_lock(material(0), false)) std::abort();
    if (!bench.base.inventory.set_lock(bag(0), true)) std::abort();
    refuse(c, Kind::kMelt, bag(0), Error::kLocked, "món vào trong ô khoá");
    if (!bench.base.inventory.set_lock(bag(0), false)) std::abort();

    // Sau cả loạt lỗi, chính planner đã nhận lỗi vẫn dựng được lượt thành công.
    const auto report = bench.plan(Kind::kMelt, bag(0), c);
    context.expect(report.has_value() && bench.base.inventory.apply(std::move(c).finish()).has_value(), "đủ vật liệu và vàng thì thành công trên planner đã từng lỗi");
    context.expect(bench.base.inventory.count_of(TemplateId{kHerb}) == 1 && bench.gold() == 5000 - kMeltGold, "chỉ lượt thành công mới trừ");
}

void bag_full_is_atomic(Context& context) {
    const Standard s = standard();
    ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
    bench.base.put(quest(0), bench.base.make(kQuestItem));
    for (std::uint16_t slot = 0; slot < 20; ++slot) bench.base.put(bag(slot), bench.base.make(kPickBound));
    give(bench, kHerb, 1);
    bench.fund(Currency::kGold, 1000);
    const auto before = fingerprint(bench.base.inventory);
    const std::uint64_t serial_before = bench.base.serials.cursor();
    Planner planner = bench.base.planner();
    context.expect(refused(bench.plan(Kind::kCarve, quest(0), planner), Error::kBagFull), "kiếm không có chỗ vào túi đạo cụ");
    context.expect(plan_of(planner).empty(), "túi đầy: không trừ vật liệu, vàng hay món vào");
    context.expect(fingerprint(bench.base.inventory) == before, "Inventory không đổi");
    context.expect(bench.base.serials.cursor() == serial_before + 1, "serial của món sinh dở bị bỏ phí (hợp đồng ghi ở craft.hpp)");

    // Dọn một ô thì thành công ngay.
    Planner clear = bench.base.planner();
    if (!clear.remove_at(bag(7), 1).has_value() || !bench.base.commit(std::move(clear))) std::abort();
    context.expect(bench.craft(Kind::kCarve, quest(0)).has_value() && bench.base.inventory.get(bag(7)) != nullptr, "có chỗ thì chạm được vào đúng ô trống");
}

// ----- bảo toàn trên chuỗi thao tác ngẫu nhiên ---------------------------------------------------------------------------------------

struct ModelNeed {
    std::uint32_t item = 0;
    std::int64_t count = 0;
};

struct ModelRecipe {
    Kind kind = Kind::kMelt;
    std::uint32_t input = 0;
    std::uint32_t output = 0;
    std::vector<ModelNeed> needs{};
    std::vector<ModelNeed> alt{};
    std::int64_t gold = 0;
};

// Luật của `standard()` viết lại bằng tay, độc lập với bộ nạp bảng.
std::vector<ModelRecipe> model_recipes() {
    return std::vector<ModelRecipe>{
        ModelRecipe{.kind = Kind::kMelt, .input = kGem, .output = kWhiteRing, .needs = {{kHerb, 1}}, .alt = {{kPotion, 1}}, .gold = kMeltGold},
        ModelRecipe{.kind = Kind::kMelt, .input = kNoSell, .output = kCharm, .needs = {{kHerb, 1}}, .alt = {}, .gold = 0},
        ModelRecipe{.kind = Kind::kCarve, .input = kQuestItem, .output = kSword, .needs = {{kHerb, 1}}, .alt = {}, .gold = kCarveGold},
        ModelRecipe{.kind = Kind::kAdvance, .input = kSword, .output = kSectSword, .needs = {{kHerb, 2}, {kPotion, 2}}, .alt = {}, .gold = kAdvanceGold},
    };
}

constexpr std::array kTracked{kGem, kNoSell, kQuestItem, kSword, kHerb, kPotion, kWhiteRing, kCharm, kSectSword};
constexpr std::array kOutputs{kWhiteRing, kCharm, kSectSword};

// Ô đầu tiên giữ mẫu `id` trong ba túi.
std::optional<SlotRef> find_slot(const item::Inventory& inventory, std::uint32_t id) {
    for (const Place place : {Place::kBaseBag, Place::kMaterialBag, Place::kQuestBag}) {
        const auto cells = inventory.view(place);
        for (std::uint16_t index = 0; index < inventory.unlocked(place) && index < cells.size(); ++index) {
            if (cells[index] && cells[index]->tmpl == TemplateId{id}) return SlotRef{.place = place, .index = index};
        }
    }
    return std::nullopt;
}

bool has_all(const std::map<std::uint32_t, std::int64_t>& items, const std::vector<ModelNeed>& needs) {
    if (needs.empty()) return false;
    for (const ModelNeed& need : needs) {
        const auto found = items.find(need.item);
        if (found == items.end() || found->second < need.count) return false;
    }
    return true;
}

void conservation_fuzz(Context& context) {
    const Standard s = standard();
    ForgeBench bench({.melting = s.melting, .carving = s.carving, .advances = s.advances});
    dice::Dice rng(20261014);
    const std::vector<ModelRecipe> recipes = model_recipes();
    std::map<std::uint32_t, std::int64_t> items;
    for (const std::uint32_t id : kTracked) items[id] = 0;
    std::int64_t gold = 0;
    std::size_t done = 0;
    std::size_t lacking_items = 0;
    std::size_t lacking_gold = 0;
    std::size_t used_alt = 0;

    const auto balanced = [&]() {
        for (const std::uint32_t id : kTracked) {
            if (std::cmp_not_equal(bench.base.inventory.count_of(TemplateId{id}), items[id])) return false;
        }
        return bench.gold() == gold;
    };

    for (int step = 0; step < 4000; ++step) {
        const std::uint64_t pick = rng.below(10);
        if (pick < 4) {
            // Người chơi kiếm thêm đồ hoặc vàng từ nguồn ngoài lò rèn.
            if (rng.below(3) == 0) {
                const auto amount = static_cast<std::int64_t>(1 + rng.below(700));
                Planner planner = bench.base.planner();
                if (planner.earn(Currency::kGold, amount).has_value() && bench.base.commit(std::move(planner))) gold += amount;
            } else {
                const std::uint32_t id = kTracked.at(rng.below(kTracked.size() - kOutputs.size()));
                const bool stacks = id == kHerb || id == kPotion || id == kQuestItem;  // ngọc, đồ không bán và kiếm không chồng được
                const auto count = static_cast<std::uint16_t>(stacks ? 1 + rng.below(4) : 1);
                Planner planner = bench.base.planner();
                if (planner.add(bench.base.make(id, count)).has_value() && bench.base.commit(std::move(planner))) items[id] += count;
            }
        } else if (pick == 4) {
            // Dọn đồ ra: không để túi đạo cụ đầy che mất các ca khác.
            for (const std::uint32_t id : kOutputs) {
                if (items[id] == 0) continue;
                Planner planner = bench.base.planner();
                if (planner.remove_count(TemplateId{id}, static_cast<std::uint32_t>(items[id])).has_value() && bench.base.commit(std::move(planner))) items[id] = 0;
            }
        } else {
            const ModelRecipe& recipe = recipes.at(rng.below(recipes.size()));
            const std::optional<SlotRef> from = find_slot(bench.base.inventory, recipe.input);
            if (!from) {
                if (items[recipe.input] != 0) context.expect(false, "mô hình có món mà kho không thấy ở ô mở");
                continue;
            }
            const auto before = fingerprint(bench.base.inventory);
            const bool primary = has_all(items, recipe.needs);
            const bool alternative = !primary && has_all(items, recipe.alt);
            Planner planner = bench.base.planner();
            const auto report = bench.plan(recipe.kind, *from, planner);
            if (report) {
                context.expect((primary || alternative) && gold >= recipe.gold, "chỉ thành công khi mô hình nói đủ vật liệu và vàng");
                context.expect(report->used_substitute == alternative && report->gold == recipe.gold && report->produced.tmpl == TemplateId{recipe.output},
                    "báo cáo khớp mô hình");
                if (!bench.base.inventory.apply(std::move(planner).finish()).has_value()) {
                    context.expect(false, "kế hoạch của planner phải áp dụng được");
                    return;
                }
                const std::vector<ModelNeed>& spent = primary ? recipe.needs : recipe.alt;
                --items[recipe.input];
                for (const ModelNeed& need : spent) items[need.item] -= need.count;
                ++items[recipe.output];
                gold -= recipe.gold;
                ++done;
                if (alternative) ++used_alt;
            } else {
                const Error error = report.error();
                if (!primary && !alternative) {
                    context.expect(error == Error::kNotEnoughItems, "thiếu vật liệu thì kNotEnoughItems");
                    ++lacking_items;
                } else if (gold < recipe.gold) {
                    context.expect(error == Error::kInsufficientFunds, "thiếu vàng thì kInsufficientFunds");
                    ++lacking_gold;
                } else {
                    context.expect(error == Error::kBagFull, "đủ cả mà vẫn hỏng thì chỉ có thể là hết chỗ");
                }
                context.expect(plan_of(planner).empty() && fingerprint(bench.base.inventory) == before, "lỗi không để lại gì");
            }
        }
        if (!balanced()) {
            context.expect(false, "số lượng và vàng khớp mô hình");
            return;
        }
    }
    context.expect(done > 300 && lacking_items > 50 && lacking_gold > 20 && used_alt > 20,
        "chuỗi đủ đa dạng: nhiều lượt thành công, thiếu vật liệu, thiếu vàng, và dùng bộ thay thế");
}

#ifdef GAME_SERVER_TABLES
// Chạy MỌI công thức của bảng thật trên danh mục thật: cho đúng món vào, vật liệu và vàng, chế biến, rồi kiểm không còn thừa gì.
void real_recipes_all_craft(Context& context) {
    const std::optional<RealWorld> real = load_real(context);
    if (!real) return;
    const std::string root = GAME_SERVER_TABLES;
    const std::string melting = read_text(root + "/shared/gem_melting.tsv");
    const std::string carving = read_text(root + "/shared/gem_carving.tsv");
    const std::string advances = read_text(root + "/server/super_weapon_advances.tsv");
    const auto loaded = forge::ForgeTables::load({.melting = melting, .carving = carving, .advances = advances}, real->catalog);
    context.expect(loaded.has_value(), "bảng thật nạp được");
    if (!loaded) return;

    const item::Limits limits = item::Limits::defaults();
    const item::Factory factory(real->catalog, real->rolls);
    dice::Dice rng(7);
    item::SerialAllocator serials(1, 1'000'000'000);
    std::size_t crafted = 0;
    std::size_t via_substitute = 0;
    for (const Kind kind : {Kind::kMelt, Kind::kCarve, Kind::kAdvance}) {
        for (const forge::Recipe& recipe : loaded->all(kind)) {
            // Mỗi công thức một kho trống; nung ngọc có bộ thay thì thử cả hai đường.
            const bool has_alt = recipe.alt_count > 0;
            for (int path = 0; path < (has_alt ? 2 : 1); ++path) {
                item::Inventory inventory(limits);
                const auto set = path == 0 ? loaded->needs(recipe) : loaded->alternative(recipe);
                Planner stock(inventory, real->catalog, serials);
                const auto input = factory.create({.tmpl = recipe.input, .count = 1, .picked = false, .now = ids::Tick{}, .roll = {}}, rng, serials);
                bool ready = input.has_value() && stock.add(*input).has_value();
                for (const forge::Material& material : set) {
                    const auto made = factory.create({.tmpl = material.item, .count = material.count, .picked = false, .now = ids::Tick{}, .roll = {}}, rng, serials);
                    ready = ready && made.has_value() && stock.add(*made).has_value();
                }
                if (recipe.gold > 0) ready = ready && stock.earn(Currency::kGold, recipe.gold).has_value();
                ready = ready && inventory.apply(std::move(stock).finish()).has_value();
                context.expect(ready, "dựng được kho đủ món vào, vật liệu và vàng");
                if (!ready) continue;
                const std::optional<SlotRef> from = find_slot(inventory, recipe.input.value());
                context.expect(from.has_value(), "món vào nằm trong một túi");
                if (!from) continue;

                Planner planner(inventory, real->catalog, serials);
                const auto report = forge::plan_craft(*loaded, kind, *from, factory, rng, serials, ids::Tick{}, planner);
                context.expect(report.has_value(), "công thức thật chế biến được");
                if (!report) continue;
                context.expect(inventory.apply(std::move(planner).finish()).has_value(), "kế hoạch áp dụng được");
                context.expect(report->produced.tmpl == recipe.output && report->gold == recipe.gold && report->used_substitute == (path == 1),
                    "báo cáo khớp công thức");
                context.expect(inventory.count_of(recipe.output) >= 1, "có món ra");
                context.expect(recipe.input == recipe.output || inventory.count_of(recipe.input) == 0, "món vào đã hết");
                for (const forge::Material& material : set) {
                    context.expect(material.item == recipe.output || material.item == recipe.input || inventory.count_of(material.item) == 0,
                        "vật liệu đã hết, không thừa không thiếu");
                }
                context.expect(inventory.wallet().balance(Currency::kGold) == 0, "vàng đã trừ đúng số");
                ++crafted;
                if (path == 1) ++via_substitute;
            }
        }
    }
    context.expect(crafted == loaded->all(Kind::kMelt).size() + loaded->all(Kind::kCarve).size() + loaded->all(Kind::kAdvance).size() + via_substitute,
        "chế biến đủ mọi công thức, kèm đường thay thế");
    context.expect(via_substitute > 0, "bảng thật có công thức nung dùng vật liệu thay thế");
}
#endif

constexpr std::array kCases{
    Case{"melt_pays_and_produces", melt_pays_and_produces},
    Case{"substitute_materials", substitute_materials},
    Case{"exact_accounting_of_two_materials", exact_accounting_of_two_materials},
    Case{"bound_flag_carries", bound_flag_carries},
    Case{"stack_input_loses_one", stack_input_loses_one},
    Case{"failures_leave_nothing", failures_leave_nothing},
    Case{"bag_full_is_atomic", bag_full_is_atomic},
    Case{"conservation_fuzz", conservation_fuzz},
#ifdef GAME_SERVER_TABLES
    Case{"real_recipes_all_craft", real_recipes_all_craft},
#endif
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
