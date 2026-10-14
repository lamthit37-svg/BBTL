// Bảng rơi đồ: đọc số thập phân, tính xác suất bằng số nguyên, nạp và kiểm chéo bảng, rút thăm theo trọng số. Số kỳ vọng của
// ca bảng thật đến từ bộ tách TSV riêng của test (không dùng bộ nạp của module).
#include "loot_support.hpp"

#include "item/types.hpp"
#include "loot/chance.hpp"
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
#include <limits>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using loot::Ratio;

// ----- số thập phân và xác suất ----------------------------------------------------------------------------------------

void ppm_parsing(Context& context) {
    const auto ppm = [](const char* text, std::uint32_t max = 10 * loot::kPpm) { return loot::parse_ppm(text, max); };
    context.expect(ppm("0.05") == 50'000U, "0.05");
    context.expect(ppm("1") == 1'000'000U, "số nguyên");
    context.expect(ppm("0") == 0U, "không");
    context.expect(ppm("0.000001") == 1U, "phần triệu nhỏ nhất");
    context.expect(ppm("0.0000010") == 1U, "số 0 thừa sau phần triệu vẫn đúng");
    context.expect(ppm("2.5") == 2'500'000U, "2.5");
    context.expect(ppm("10") == 10'000'000U, "đúng trần");
    context.expect(ppm("0.999999") == 999'999U, "sáu chữ số");
    context.expect(ppm("0002.50") == 2'500'000U, "số 0 đệm đầu");
    context.expect(!ppm("0000000000000000000000000000011").has_value(), "đệm đầu dài không làm tràn rồi lọt qua trần");
    for (const char* bad : {"", ".", ".5", "1.", "-1", "+1", "1e3", "0x10", "1 ", " 1", "1.2.3", "abc", "1,5", "0.0000011",
             "10.000001", "11", "99999999999999999999999999", "1..5"}) {
        context.expect(!ppm(bad).has_value(), bad);
    }
    context.expect(!loot::parse_ppm("2", 1'000'000U).has_value(), "vượt trần của người gọi");
    context.expect(loot::parse_ppm("1", 1'000'000U) == 1'000'000U, "bằng trần của người gọi");
}

// Hai tỉ lệ bằng nhau khi nhân chéo bằng nhau (số nhỏ của test không tràn).
bool equal_ratio(const Ratio& a, std::uint64_t num, std::uint64_t den) {
    return a.num * den == num * a.den;
}

void ratio_arithmetic(Context& context) {
    constexpr std::uint32_t one = loot::kPpm;
    context.expect(equal_ratio(loot::drop_ratio({50, 1000, one, one, one}), 1, 20), "50/1000");
    context.expect(equal_ratio(loot::drop_ratio({50, 1000, 500'000, one, one}), 1, 40), "hệ số chênh cấp 0,5");
    context.expect(equal_ratio(loot::drop_ratio({50, 1000, one, 2 * one, one}), 1, 10), "DropParam 2");
    context.expect(equal_ratio(loot::drop_ratio({50, 1000, one, one, 500'000}), 1, 40), "chống nghiện 0,5");
    context.expect(equal_ratio(loot::drop_ratio({50, 1000, 500'000, 500'000, 500'000}), 1, 160), "ba hệ số cùng 0,5");
    context.expect(loot::drop_ratio({0, 1000, one, one, one}).num == 0, "quái giá trị 0 không rơi");
    context.expect(loot::drop_ratio({-5, 1000, one, one, one}).num == 0, "quái giá trị âm không rơi");
    context.expect(loot::drop_ratio({50, 0, one, one, one}).num == 0, "gói giá trị 0 không rơi (bảng thật đã bị từ chối)");
    context.expect(loot::drop_ratio({50, 1000, 0, one, one}).num == 0, "hệ số chênh cấp 0");
    context.expect(loot::drop_ratio({50, 1000, one, 0, one}).num == 0, "DropParam 0");
    context.expect(loot::drop_ratio({50, 1000, one, one, 0}).num == 0, "chống nghiện 0");
    const Ratio sure = loot::drop_ratio({1000, 1000, one, one, one});
    context.expect(sure.num >= sure.den, "giá trị bằng nhau là chắc chắn");
    const Ratio huge = loot::drop_ratio({std::numeric_limits<std::int32_t>::max(), 1, 10 * one, 100 * one, one});
    context.expect(huge.num >= huge.den && huge.den >= 1, "tỉ lệ khổng lồ vẫn là chắc chắn, không tràn");
    // Tỉ lệ lớn hơn 1 rồi nhân hệ số nhỏ hơn 1 phải ra đúng (không bị kẹp về 1 giữa chừng): 3 x 0,5 = 1,5.
    context.expect(equal_ratio(loot::drop_ratio({3000, 1000, 500'000, one, one}), 3, 2), "3 x 0,5 = 1,5 giữ nguyên");
    // 4 x 0,1 x 0,1 = 0,04 dù bước đầu lớn hơn 1.
    context.expect(equal_ratio(loot::drop_ratio({4000, 1000, 100'000, 100'000, one}), 1, 25), "4 x 0,1 x 0,1");
}

// So với tính bằng long double trên đầu vào ngẫu nhiên khắp miền: sai số tuyệt đối dưới 1e-9 khi xác suất dưới 1, và
// chắc chắn khi lớn hơn 1.
void ratio_fuzz(Context& context) {
    dice::Dice dice(2024);
    std::size_t below_one = 0;
    std::size_t above_one = 0;
    for (int i = 0; i < 60'000; ++i) {
        const auto monster = static_cast<std::int64_t>(dice.below(std::uint64_t{1} << (1 + dice.below(31))));
        const auto box = static_cast<std::int64_t>(1 + dice.below(std::uint64_t{1} << (1 + dice.below(30))));
        const auto gap = static_cast<std::uint32_t>(dice.below(10 * loot::kPpm + 1));
        const auto param = static_cast<std::uint32_t>(dice.below(std::uint64_t{loot::kMaxDropParamPpm} + 1));
        const auto wallow = static_cast<std::uint32_t>(dice.below(loot::kPpm + 1));
        const Ratio got = loot::drop_ratio({monster, box, gap, param, wallow});
        const long double exact = static_cast<long double>(monster) / static_cast<long double>(box)
            * (static_cast<long double>(gap) / loot::kPpm) * (static_cast<long double>(param) / loot::kPpm)
            * (static_cast<long double>(wallow) / loot::kPpm);
        const long double have = static_cast<long double>(got.num) / static_cast<long double>(got.den);
        if (exact >= 1.0L + 1e-9L) {
            ++above_one;
            if (got.num < got.den) {
                context.expect(false, "xác suất lớn hơn 1 phải chắc chắn");
                return;
            }
        } else if (exact < 1.0L - 1e-9L) {
            ++below_one;
            if (std::fabs(static_cast<double>(have - exact)) > 1e-9) {
                context.expect(false, "sai số tuyệt đối của xác suất vượt 1e-9");
                return;
            }
        }
        if (got.den == 0 || got.num >= (std::uint64_t{1} << 62) || got.den >= (std::uint64_t{1} << 62)) {
            context.expect(false, "tỉ lệ ra ngoài miền biểu diễn");
            return;
        }
    }
    context.expect(below_one > 10'000 && above_one > 10'000, "đầu vào phủ cả hai phía của 1");
}

void succeeds_frequency(Context& context) {
    dice::Dice dice(5);
    const Ratio quarter{.num = 1, .den = 4};
    int hits = 0;
    constexpr int kTrials = 100'000;
    for (int i = 0; i < kTrials; ++i) hits += loot::succeeds(quarter, dice) ? 1 : 0;
    // sigma = sqrt(n p q) = 137: 6 sigma = 822.
    context.expect(std::abs(hits - 25'000) < 822, "1/4 ra khoảng một phần tư");
    context.expect(loot::succeeds(Ratio{.num = 5, .den = 5}, dice), "num = den luôn đúng");
    context.expect(!loot::succeeds(Ratio{.num = 0, .den = 1}, dice), "num = 0 luôn sai");
    context.expect(!loot::succeeds(Ratio{.num = 0, .den = 0}, dice), "den hỏng không làm dừng chương trình");
}

// ----- nạp bảng tổng hợp -----------------------------------------------------------------------------------------------

struct Fixture {
    World world = make_world();
    std::string packs;
    std::string monsters;
    std::string gaps = kGapsTable;
    std::string rates;
    std::string boxes;

    [[nodiscard]] std::expected<loot::LootTables, std::string> load() const {
        return loot::LootTables::load({.packs = packs, .monsters = monsters, .level_gaps = gaps, .rate_items = rates, .boxes = boxes},
            world.catalog);
    }
};

Fixture good_fixture() {
    Fixture f;
    // Gói và quái xếp lộn xộn để thử việc sắp xếp. Gói 20 có một mục lạ (mã 99999999) và một mục tốt.
    f.packs = packs_table({
        PackSpec{.id = 30, .value = 500, .items = {{kPotion, -1}}},
        PackSpec{.id = 10, .value = 1000, .broadcast = 7, .force_bind = 1, .items = {{kSword, 3}, {kHerb, -1}}},
        PackSpec{.id = 20, .value = 100, .items = {{99'999'999, -1}, {kGem, -1}}},
        PackSpec{.id = 40, .value = 100, .items = {{99'999'998, -1}}},
        PackSpec{.id = 50, .value = 100, .items = {}},
    });
    f.monsters = monsters_table({
        MonsterSpec{.id = 700, .value = 40, .type = 1, .packs = {30, 10}},
        MonsterSpec{.id = 600, .value = 5, .type = 0, .packs = {20}},
    });
    return f;
}

void loader_accepts_and_sorts(Context& context) {
    const Fixture f = good_fixture();
    const auto loaded = f.load();
    context.expect(loaded.has_value(), "bảng hợp lệ nạp được");
    if (!loaded) return;
    const loot::LootTables& tables = *loaded;
    context.expect(tables.pack_count() == 5 && tables.monster_count() == 2, "số gói và số quái");

    const loot::MonsterDrop* boss = tables.monster(ids::MonsterTemplateId{700});
    context.expect(boss != nullptr && boss->value == 40 && boss->ruler == loot::Ruler::kBoss && boss->pack_count == 2, "quái 700");
    context.expect(boss != nullptr && boss->packs.at(0).value() == 30 && boss->packs.at(1).value() == 10, "thứ tự gói của quái giữ nguyên");
    const loot::MonsterDrop* plain = tables.monster(ids::MonsterTemplateId{600});
    context.expect(plain != nullptr && plain->ruler == loot::Ruler::kCommon, "quái 600 là loại thường");
    context.expect(tables.monster(ids::MonsterTemplateId{601}) == nullptr, "quái không có bảng");
    context.expect(tables.monster(ids::MonsterTemplateId{0}) == nullptr, "mã 0");

    const loot::Pack* ten = tables.pack(loot::PackId{10});
    context.expect(ten != nullptr && ten->value == 1000 && ten->broadcast == 7 && ten->force_bind && ten->count == 2, "gói 10");
    if (ten != nullptr) {
        const auto entries = tables.entries(*ten);
        context.expect(entries.size() == 2 && entries[0].item == item::TemplateId{kSword} && entries[0].origin == 3
                && entries[1].item == item::TemplateId{kHerb} && entries[1].origin == loot::kInheritOrigin,
            "mục của gói 10 theo thứ tự tệp, cấp 3 và để trống");
    }
    const loot::Pack* thirty = tables.pack(loot::PackId{30});
    context.expect(thirty != nullptr && thirty->broadcast == -1 && !thirty->force_bind, "gói 30 không phát thanh, không ép khoá");
    context.expect(tables.pack(loot::PackId{11}) == nullptr, "gói không có");
}

void loader_filters_unknown_items(Context& context) {
    const Fixture f = good_fixture();
    const auto loaded = f.load();
    if (!loaded) {
        context.expect(false, "bảng hợp lệ nạp được");
        return;
    }
    const loot::Diagnostics& diag = loaded->diagnostics();
    context.expect(diag.unknown_pack_items == 2, "hai mục lạ (một ở gói 20, một ở gói 40)");
    context.expect(diag.empty_packs == 2, "gói 40 (toàn mục lạ) và gói 50 (trống) không còn mục nào");
    context.expect(diag.samples.size() == 2 && diag.samples.front().find("99999999") != std::string::npos
            && diag.samples.front().find("drop_packages") != std::string::npos,
        "mẫu lỗi nêu bảng và mã");
    const loot::Pack* twenty = loaded->pack(loot::PackId{20});
    context.expect(twenty != nullptr && twenty->count == 1 && loaded->entries(*twenty).front().item == item::TemplateId{kGem},
        "gói 20 giữ mục tốt");
    // Pack lạ không làm entries() đọc ngoài kho.
    const loot::Pack forged{.id = loot::PackId{1}, .value = 1, .broadcast = -1, .force_bind = false, .begin = 1'000'000, .count = 5};
    context.expect(loaded->entries(forged).empty(), "Pack giả không đọc ngoài bảng");
    const loot::Pack overrun{.id = loot::PackId{1}, .value = 1, .broadcast = -1, .force_bind = false, .begin = 0, .count = 60'000};
    context.expect(loaded->entries(overrun).size() <= 8, "count giả bị cắt theo kho thật");
}

// Một bảng hỏng phải bị từ chối, câu lỗi nêu tên bảng.
void expect_rejected(Context& context, const Fixture& f, const char* table, const char* what) {
    const auto loaded = f.load();
    context.expect(!loaded.has_value() && loaded.error().find(table) != std::string::npos, what);
}

void loader_rejects_bad_tables(Context& context) {
    {
        Fixture f = good_fixture();
        f.packs = packs_table({PackSpec{.id = 10, .items = {{kPotion, -1}}}, PackSpec{.id = 10, .items = {{kHerb, -1}}}});
        f.monsters = monsters_table({});
        expect_rejected(context, f, "drop_packages", "gói trùng id");
    }
    {
        Fixture f = good_fixture();
        f.packs = packs_table({PackSpec{.id = 10, .items = {{kPotion, 7}}}});
        f.monsters = monsters_table({});
        expect_rejected(context, f, "drop_packages", "ô cấp 7 ngoài 0..6");
    }
    {
        Fixture f = good_fixture();
        f.packs = packs_table({PackSpec{.id = 10, .value = 0, .items = {{kPotion, -1}}}});
        f.monsters = monsters_table({});
        expect_rejected(context, f, "drop_packages", "giá trị gói 0 làm mẫu số");
    }
    {
        Fixture f = good_fixture();
        f.packs = packs_table({PackSpec{.id = 10, .items = {{kPotion, -1}, {-1, -1}, {kHerb, -1}}}});
        f.monsters = monsters_table({});
        expect_rejected(context, f, "drop_packages", "vật phẩm chen sau ô trống");
    }
    {
        Fixture f = good_fixture();
        f.packs = packs_table({PackSpec{.id = 10, .force_bind = 2, .items = {{kPotion, -1}}}});
        f.monsters = monsters_table({});
        expect_rejected(context, f, "drop_packages", "cờ ép khoá ngoài 0..1");
    }
    {
        Fixture f = good_fixture();
        f.packs = packs_table({PackSpec{.id = 10, .items = {{0, -1}}}});
        f.monsters = monsters_table({});
        expect_rejected(context, f, "drop_packages", "mã vật phẩm 0");
    }
    {
        Fixture f = good_fixture();
        f.packs.replace(f.packs.find("box_value"), 9, "box_valux");
        expect_rejected(context, f, "drop_packages", "tiêu đề cột lạ");
    }
    {
        Fixture f = good_fixture();
        f.packs = "# schema 1\nid\tbox_value\tcolumn_2\tcolumn_3\titem_1_id\n10\t100\t-1\t0\t-1\n";
        f.monsters = monsters_table({});
        expect_rejected(context, f, "drop_packages", "số cột lẻ không khớp bố cục");
    }
    {
        Fixture f = good_fixture();
        f.packs += "10\n";
        expect_rejected(context, f, "drop_packages", "dòng thiếu ô");
    }
    {
        Fixture f = good_fixture();
        f.monsters = monsters_table({MonsterSpec{.id = 5, .value = 1, .type = 0, .packs = {999}}});
        expect_rejected(context, f, "monster_drops", "quái trỏ gói không có");
    }
    {
        Fixture f = good_fixture();
        f.monsters = monsters_table({MonsterSpec{.id = 5, .value = 1, .type = 0, .packs = {10}},
            MonsterSpec{.id = 5, .value = 2, .type = 1, .packs = {20}}});
        expect_rejected(context, f, "monster_drops", "quái trùng id");
    }
    {
        Fixture f = good_fixture();
        f.monsters = monsters_table({MonsterSpec{.id = 5, .value = 1, .type = 2, .packs = {10}}});
        expect_rejected(context, f, "monster_drops", "drop_type ngoài 0..1");
    }
    {
        Fixture f = good_fixture();
        f.monsters = monsters_table({MonsterSpec{.id = 5, .value = 1, .type = 0, .packs = {10, -1, 20}}});
        expect_rejected(context, f, "monster_drops", "gói chen sau ô trống");
    }
    {
        Fixture f = good_fixture();
        f.monsters = monsters_table({MonsterSpec{.id = 5, .value = -1, .type = 0, .packs = {10}}});
        expect_rejected(context, f, "monster_drops", "mvalue âm");
    }
    {
        Fixture f = good_fixture();
        f.gaps = "# schema 1\nlevel_delta\trate\n0\tabc\n";
        expect_rejected(context, f, "drop_level_gap_factors", "hệ số không phải số");
    }
    {
        Fixture f = good_fixture();
        f.gaps = "# schema 1\nlevel_delta\trate\n0\t11\n";
        expect_rejected(context, f, "drop_level_gap_factors", "hệ số quá 10");
    }
    {
        Fixture f = good_fixture();
        f.gaps = "# schema 1\nlevel_delta\trate\n3\t1\n3\t0.5\n";
        expect_rejected(context, f, "drop_level_gap_factors", "chênh lệch cấp trùng");
    }
    {
        Fixture f = good_fixture();
        f.rates = "# schema 1\nitem_id\tname\tdrop_chance\tsends_message\n" + std::to_string(kPotion) + "\tx\t5\t2\n";
        expect_rejected(context, f, "item_drop_rates", "sends_message ngoài 0..1");
    }
    {
        Fixture f = good_fixture();
        const std::string head = "# schema 1\nbox_key\tindex\titem_id\trate\tnotice\n";
        f.boxes = head + "a\t0\t" + std::to_string(kPotion) + "\t5\t0\na\t0\t" + std::to_string(kHerb) + "\t5\t0\n";
        expect_rejected(context, f, "loot_box_entries", "hộp có hai dòng cùng index");
        f.boxes = head + "\t0\t" + std::to_string(kPotion) + "\t5\t0\n";
        expect_rejected(context, f, "loot_box_entries", "khoá hộp trống");
        f.boxes = head + "a\t0\t" + std::to_string(kPotion) + "\t-5\t0\n";
        expect_rejected(context, f, "loot_box_entries", "trọng số âm");
    }
    {
        Fixture f = good_fixture();
        f.packs.clear();
        expect_rejected(context, f, "drop_packages", "thiếu bảng gói");
    }
}

void gap_lookup(Context& context) {
    const Fixture f = good_fixture();
    const auto loaded = f.load();
    if (!loaded) {
        context.expect(false, "nạp được");
        return;
    }
    context.expect(loaded->gap_ppm(0) == 1'000'000, "chênh 0");
    context.expect(loaded->gap_ppm(-1) == 500'000, "chênh -1");
    context.expect(loaded->gap_ppm(1) == 250'000, "chênh +1");
    context.expect(loaded->gap_ppm(-2) == 2'000'000, "hệ số lớn hơn 1");
    context.expect(loaded->gap_ppm(2) == loot::kPpm && loaded->gap_ppm(-100) == loot::kPpm, "ngoài bảng giữ hệ số 1,0 như 2008");
    context.expect(loaded->gap_ppm(std::numeric_limits<std::int64_t>::min()) == loot::kPpm
            && loaded->gap_ppm(std::numeric_limits<std::int64_t>::max()) == loot::kPpm,
        "giá trị cực đoan");
}

// ----- rút thăm theo trọng số -------------------------------------------------------------------------------------------

void weighted_picks(Context& context) {
    Fixture f = good_fixture();
    const std::string head = "# schema 1\nbox_key\tindex\titem_id\trate\tnotice\treserve_1\treserve_2\treserve_3\n";
    // Hai hộp, dòng xen kẽ và index không theo thứ tự để thử việc nhóm; một dòng mã lạ bị bỏ.
    f.boxes = head + "b\t1\t" + std::to_string(kHerb) + "\t300\t0\t0\t0\t0\n"
        + "a\t0\t" + std::to_string(kPotion) + "\t5\t1\t0\t0\t0\n"
        + "b\t0\t" + std::to_string(kPotion) + "\t700\t1\t0\t0\t0\n"
        + "b\t2\t99999999\t5000\t0\t0\t0\t0\n";
    f.rates = "# schema 1\nitem_id\tname\tdrop_chance\tsends_message\treserved_1\n"
        + std::to_string(kPotion) + "\tpotion\t70\t1\t0\n" + std::to_string(kHerb) + "\therb\t30\t0\t0\n"
        + "99999999\tlạ\t900\t0\t0\n" + std::to_string(kGem) + "\tgem\t0\t1\t0\n";
    const auto loaded = f.load();
    if (!loaded) {
        context.expect(false, loaded.error());
        return;
    }
    context.expect(loaded->box_count() == 2 && loaded->has_box("a") && loaded->has_box("b") && !loaded->has_box("c")
            && !loaded->has_box("") && !loaded->has_box("ab"),
        "hai hộp");
    context.expect(loaded->diagnostics().unknown_box_items == 1 && loaded->diagnostics().unknown_rate_items == 1, "mục lạ được đếm");

    dice::Dice dice(77);
    context.expect(!loaded->pick_box("zzz", dice).has_value(), "hộp không có");
    for (int i = 0; i < 50; ++i) {
        const auto only = loaded->pick_box("a", dice);
        context.expect(only && only->item == item::TemplateId{kPotion} && only->announce, "hộp một mục luôn ra mục đó, giữ cờ báo tin");
    }
    constexpr int kTrials = 20'000;
    int potions = 0;
    for (int i = 0; i < kTrials; ++i) {
        const auto pick = loaded->pick_box("b", dice);
        if (!pick) {
            context.expect(false, "hộp b luôn ra mục");
            return;
        }
        if (pick->item == item::TemplateId{kPotion}) {
            ++potions;
            if (!pick->announce) {
                context.expect(false, "cờ báo tin đi theo dòng");
                return;
            }
        }
    }
    // 700/1000, sigma = 65: 6 sigma = 390.
    context.expect(std::abs(potions - 14'000) < 390, "trọng số 700:300");

    int rate_potions = 0;
    int rate_gems = 0;
    for (int i = 0; i < kTrials; ++i) {
        const auto pick = loaded->pick_rate_item(dice);
        if (!pick) {
            context.expect(false, "bảng xác suất luôn ra mục");
            return;
        }
        rate_potions += pick->item == item::TemplateId{kPotion} ? 1 : 0;
        rate_gems += pick->item == item::TemplateId{kGem} ? 1 : 0;
    }
    context.expect(std::abs(rate_potions - 14'000) < 390, "drop_chance 70:30");
    context.expect(rate_gems == 0, "trọng số 0 không bao giờ ra");

    Fixture empty = good_fixture();
    const auto none = empty.load();
    context.expect(none && !none->pick_rate_item(dice).has_value() && !none->pick_box("a", dice).has_value(), "không bảng thì không rút được");
}

// ----- bảng thật -------------------------------------------------------------------------------------------------------

#ifdef GAME_SERVER_TABLES

// Số kỳ vọng từ bộ tách riêng của test.
struct Expected {
    std::vector<std::vector<std::string>> packs, monsters, gaps, rates, boxes;
    std::set<std::int64_t> known;
};

std::set<std::int64_t> ids_of(const std::string& text, const std::string& column) {
    const auto rows = tsv_rows(text);
    std::set<std::int64_t> out;
    if (rows.empty()) return out;
    const auto col = static_cast<std::size_t>(std::ranges::find(rows.front(), column) - rows.front().begin());
    for (std::size_t i = 1; i < rows.size(); ++i) out.insert(std::stoll(rows.at(i).at(col)));
    return out;
}

void real_tables(Context& context) {
    const std::string root = GAME_SERVER_TABLES;
    const auto real = load_real(context);
    if (!real) return;
    Expected want;
    want.packs = tsv_rows(read_text(root + "/server/drop_packages.tsv"));
    want.monsters = tsv_rows(read_text(root + "/server/monster_drops.tsv"));
    want.gaps = tsv_rows(read_text(root + "/server/drop_level_gap_factors.tsv"));
    want.rates = tsv_rows(read_text(root + "/server/item_drop_rates.tsv"));
    want.boxes = tsv_rows(read_text(root + "/server/loot_box_entries.tsv"));
    for (const auto& [file, column] : {std::pair<const char*, const char*>{"/shared/items_common.tsv", "index"},
             {"/shared/equipment.tsv", "index_1"}, {"/shared/gems.tsv", "index"}, {"/shared/pet_equipment_base.tsv", "column_0"}}) {
        const auto ids = ids_of(read_text(root + file), column);
        want.known.insert(ids.begin(), ids.end());
    }

    const std::string packs_text = read_text(root + "/server/drop_packages.tsv");
    const std::string monsters_text = read_text(root + "/server/monster_drops.tsv");
    const std::string gaps_text = read_text(root + "/server/drop_level_gap_factors.tsv");
    const std::string rates_text = read_text(root + "/server/item_drop_rates.tsv");
    const std::string boxes_text = read_text(root + "/server/loot_box_entries.tsv");
    const auto loaded = loot::LootTables::load({.packs = packs_text, .monsters = monsters_text, .level_gaps = gaps_text,
        .rate_items = rates_text, .boxes = boxes_text}, real->catalog);
    context.expect(loaded.has_value(), "bảng rơi thật nạp được");
    if (!loaded) {
        std::fprintf(stderr, "%s\n", loaded.error().c_str());
        return;
    }
    context.expect(loaded->pack_count() == want.packs.size() - 1, "số gói bằng số dòng dữ liệu");
    context.expect(loaded->monster_count() == want.monsters.size() - 1, "số quái bằng số dòng dữ liệu");

    // Từng gói: mục còn lại đúng là mục của tệp có trong catalog, theo thứ tự tệp; ô cấp đúng.
    std::size_t unknown = 0;
    std::size_t empty = 0;
    std::size_t mismatched = 0;
    for (std::size_t r = 1; r < want.packs.size(); ++r) {
        const auto& row = want.packs.at(r);
        const loot::Pack* pack = loaded->pack(loot::PackId{static_cast<std::uint32_t>(std::stoul(row.at(0)))});
        if (pack == nullptr) {
            ++mismatched;
            continue;
        }
        std::vector<std::pair<std::int64_t, int>> expect;
        for (std::size_t col = 4; col + 1 < row.size(); col += 2) {
            const std::int64_t id = std::stoll(row.at(col));
            if (id == -1) break;
            if (want.known.contains(id)) {
                expect.emplace_back(id, std::stoi(row.at(col + 1)));
            } else {
                ++unknown;
            }
        }
        empty += expect.empty() ? 1U : 0U;
        const auto got = loaded->entries(*pack);
        bool same = got.size() == expect.size() && pack->value == std::stoll(row.at(1))
            && pack->broadcast == std::stoi(row.at(2)) && pack->force_bind == (row.at(3) == "1");
        for (std::size_t i = 0; same && i < got.size(); ++i) {
            same = static_cast<std::int64_t>(got[i].item.value()) == expect[i].first
                && static_cast<int>(got[i].origin) == expect[i].second;
        }
        mismatched += same ? 0 : 1;
    }
    context.expect(mismatched == 0, "mọi gói khớp bảng gốc");
    context.expect(loaded->diagnostics().unknown_pack_items == unknown, "số mục lạ bằng số đếm độc lập");
    context.expect(loaded->diagnostics().empty_packs == empty, "số gói rỗng bằng số đếm độc lập");
    context.expect(unknown < 200, "mục lạ ít (đo 76 trên 30501), không phải cả bảng");

    std::size_t bad_monsters = 0;
    for (std::size_t r = 1; r < want.monsters.size(); ++r) {
        const auto& row = want.monsters.at(r);
        const loot::MonsterDrop* drop = loaded->monster(ids::MonsterTemplateId{static_cast<std::uint32_t>(std::stoul(row.at(0)))});
        if (drop == nullptr || drop->value != std::stoll(row.at(1)) || static_cast<int>(drop->ruler) != std::stoi(row.at(2))) {
            ++bad_monsters;
            continue;
        }
        std::size_t n = 0;
        for (std::size_t col = 3; col < row.size() && row.at(col) != "-1"; ++col, ++n) {
            if (n >= drop->pack_count || drop->packs.at(n).value() != std::stoul(row.at(col))) {
                ++bad_monsters;
                break;
            }
        }
        if (n != drop->pack_count) ++bad_monsters;
    }
    context.expect(bad_monsters == 0, "mọi dòng quái khớp bảng gốc");

    std::size_t bad_gaps = 0;
    for (std::size_t r = 1; r < want.gaps.size(); ++r) {
        const auto& row = want.gaps.at(r);
        const auto want_ppm = static_cast<std::uint32_t>(std::llround(std::stod(row.at(1)) * 1'000'000.0));
        bad_gaps += loaded->gap_ppm(std::stoll(row.at(0))) == want_ppm ? 0U : 1U;
    }
    context.expect(bad_gaps == 0, "hệ số chênh cấp khớp bảng gốc");
    context.expect(loaded->gap_ppm(-200) == 50'000 && loaded->gap_ppm(0) == 1'000'000, "đầu bảng 0,05 và chênh 0 là 1");
    context.expect(loaded->gap_ppm(201) == loot::kPpm, "ngoài bảng là 1,0");

    // Hộp: số hộp bằng số khoá khác nhau; tần suất rút của một hộp gacha bằng rate / tổng.
    std::set<std::string> keys;
    for (std::size_t r = 1; r < want.boxes.size(); ++r) keys.insert(want.boxes.at(r).at(0));
    context.expect(loaded->box_count() == keys.size(), "số hộp bằng số khoá khác nhau");
    for (const std::string& key : keys) context.expect(loaded->has_box(key), "mọi khoá có hộp");

    std::map<std::int64_t, std::int64_t> rates;
    std::int64_t sum = 0;
    for (std::size_t r = 1; r < want.boxes.size(); ++r) {
        const auto& row = want.boxes.at(r);
        if (row.at(0) != "gacha_1" || !want.known.contains(std::stoll(row.at(2)))) continue;
        rates[std::stoll(row.at(2))] += std::stoll(row.at(3));
        sum += std::stoll(row.at(3));
    }
    context.expect(!rates.empty() && sum > 0, "gacha_1 có dòng");
    dice::Dice dice(31);
    constexpr int kTrials = 200'000;
    std::map<std::int64_t, int> seen;
    for (int i = 0; i < kTrials; ++i) {
        const auto pick = loaded->pick_box("gacha_1", dice);
        if (!pick) {
            context.expect(false, "gacha_1 luôn ra mục");
            return;
        }
        ++seen[static_cast<std::int64_t>(pick->item.value())];
    }
    for (const auto& [id, weight] : rates) {
        const double p = static_cast<double>(weight) / static_cast<double>(sum);
        const double mean = p * kTrials;
        const double sigma = std::sqrt(kTrials * p * (1.0 - p));
        context.expect(std::fabs(seen[id] - mean) < 6.0 * sigma + 1.0, "tần suất gacha_1 khớp rate / tổng");
    }

    std::int64_t rate_sum = 0;
    for (std::size_t r = 1; r < want.rates.size(); ++r) {
        if (want.known.contains(std::stoll(want.rates.at(r).at(0)))) rate_sum += std::stoll(want.rates.at(r).at(2));
    }
    std::map<std::int64_t, int> seen_rate;
    for (int i = 0; i < kTrials; ++i) {
        const auto pick = loaded->pick_rate_item(dice);
        if (!pick) {
            context.expect(false, "bảng xác suất vật phẩm luôn ra mục");
            return;
        }
        ++seen_rate[static_cast<std::int64_t>(pick->item.value())];
    }
    std::int64_t top_id = 0;
    std::int64_t top_weight = 0;
    for (std::size_t r = 1; r < want.rates.size(); ++r) {
        const std::int64_t id = std::stoll(want.rates.at(r).at(0));
        const std::int64_t w = std::stoll(want.rates.at(r).at(2));
        if (want.known.contains(id) && w > top_weight) {
            top_weight = w;
            top_id = id;
        }
    }
    const double p_top = static_cast<double>(top_weight) / static_cast<double>(rate_sum);
    context.expect(std::fabs(seen_rate[top_id] - p_top * kTrials) < 6.0 * std::sqrt(kTrials * p_top * (1.0 - p_top)) + 1.0,
        "tần suất mục nặng nhất của item_drop_rates");
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
    Case{"ppm_parsing", ppm_parsing},
    Case{"ratio_arithmetic", ratio_arithmetic},
    Case{"ratio_fuzz", ratio_fuzz},
    Case{"succeeds_frequency", succeeds_frequency},
    Case{"loader_accepts_and_sorts", loader_accepts_and_sorts},
    Case{"loader_filters_unknown_items", loader_filters_unknown_items},
    Case{"loader_rejects_bad_tables", loader_rejects_bad_tables},
    Case{"gap_lookup", gap_lookup},
    Case{"weighted_picks", weighted_picks},
    Case{"real_tables_cases", real_tables_cases},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
