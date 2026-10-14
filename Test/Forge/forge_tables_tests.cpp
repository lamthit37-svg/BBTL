// Bảng công thức lò rèn: cách đọc ba bảng, dòng bị bỏ và cách đếm, lỗi bảng, tra cứu, và đối chiếu với bảng thật bằng một bộ tách độc lập.
#include "forge_support.hpp"

#include "forge/tables.hpp"
#include "item/types.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using forge::Kind;

bool has(const std::string& text, std::string_view needle) { return text.find(needle) != std::string::npos; }

TemplateId id_of(std::uint32_t value) { return TemplateId{value}; }

void reads_the_three_tables(Context& context) {
    const std::string melting = melting_table({
        MeltSpec{.input = kNoSell, .output = kCharm, .need = kHerb, .gold = 0},
        MeltSpec{.input = kGem, .output = kWhiteRing, .need = kHerb, .gold = 500, .substitute = kPotion},
    });
    const std::string carving = carving_table({CarveSpec{.input = kGem, .output = kSword, .need = kHerb, .gold = 200}});
    const std::string advances = advances_table({
        AdvanceSpec{.input = kSword, .output = kSectSword, .gold = 1000, .count = 2, .first = kHerb, .second = kPotion},
        AdvanceSpec{.input = kWhiteRing, .output = kCharm, .gold = 300, .count = 3, .first = kHerb},
    });
    const ForgeBench bench({.melting = melting, .carving = carving, .advances = advances});
    const forge::ForgeTables& tables = bench.tables;

    context.expect(tables.all(Kind::kMelt).size() == 2 && tables.all(Kind::kCarve).size() == 1 && tables.all(Kind::kAdvance).size() == 2,
        "đủ số công thức mỗi loại");
    const forge::Recipe* melt = tables.find(Kind::kMelt, id_of(kGem));
    context.expect(melt != nullptr && melt->output == id_of(kWhiteRing) && melt->gold == 500, "nung ngọc: đầu ra và vàng");
    if (melt != nullptr) {
        const auto needs = tables.needs(*melt);
        const auto alt = tables.alternative(*melt);
        context.expect(needs.size() == 1 && needs[0].item == id_of(kHerb) && needs[0].count == 1, "vật liệu chính một thảo dược");
        context.expect(alt.size() == 1 && alt[0].item == id_of(kPotion) && alt[0].count == 1, "vật liệu thay thế một thuốc");
    }
    const forge::Recipe* free_melt = tables.find(Kind::kMelt, id_of(kNoSell));
    context.expect(free_melt != nullptr && free_melt->gold == 0 && tables.alternative(*free_melt).empty(), "không vàng, không vật liệu thay thế");

    // Cùng một món đầu vào ở hai loại là hai công thức độc lập.
    const forge::Recipe* carve = tables.find(Kind::kCarve, id_of(kGem));
    context.expect(carve != nullptr && carve->output == id_of(kSword) && carve->gold == 200 && tables.alternative(*carve).empty(),
        "chạm ngọc cùng đầu vào khác đầu ra");
    context.expect(tables.find(Kind::kCarve, id_of(kNoSell)) == nullptr, "món không có công thức chạm");

    // material_count nhân cho MỖI vật liệu trong hai vật liệu.
    const forge::Recipe* two = tables.find(Kind::kAdvance, id_of(kSword));
    context.expect(two != nullptr && two->gold == 1000, "nâng cấp: vàng");
    if (two != nullptr) {
        const auto needs = tables.needs(*two);
        context.expect(needs.size() == 2 && needs[0].item == id_of(kHerb) && needs[0].count == 2 && needs[1].item == id_of(kPotion)
                && needs[1].count == 2,
            "hai vật liệu, mỗi vật liệu hai cái");
    }
    const forge::Recipe* one = tables.find(Kind::kAdvance, id_of(kWhiteRing));
    context.expect(one != nullptr && tables.needs(*one).size() == 1 && tables.needs(*one)[0].count == 3, "một vật liệu ba cái");

    // Mỗi loại xếp tăng theo mã đầu vào bất kể thứ tự dòng.
    for (const Kind kind : {Kind::kMelt, Kind::kCarve, Kind::kAdvance}) {
        const std::span<const forge::Recipe> all = tables.all(kind);
        context.expect(std::ranges::is_sorted(all, {}, &forge::Recipe::input), "xếp tăng theo mã đầu vào");
    }
    context.expect(tables.diagnostics().unknown_rows == 0 && tables.diagnostics().disabled_advances == 0, "không dòng nào bị bỏ");
}

void skips_unknown_and_disabled(Context& context) {
    const std::uint32_t lost = kUnknownItem;
    const std::string melting = melting_table({
        MeltSpec{.input = lost, .output = kCharm, .need = kHerb, .gold = 1},
        MeltSpec{.input = kGem, .output = lost, .need = kHerb, .gold = 1},
        MeltSpec{.input = kNoSell, .output = kCharm, .need = lost, .gold = 1},
        MeltSpec{.input = kPickBound, .output = kCharm, .need = kHerb, .gold = 1, .substitute = lost},
        MeltSpec{.input = kUniqueRing, .output = kCharm, .need = kHerb, .gold = 1, .substitute = kPotion},
    });
    const std::string carving = carving_table({
        CarveSpec{.input = kGem, .output = kSword, .need = lost, .gold = 1},
        CarveSpec{.input = kGem, .output = kSword, .need = kHerb, .gold = 1},
    });
    // gold_cost -1 là dòng chưa mở: bị bỏ dù có hay không có mã lạ; mã lạ ở dòng mở được đếm riêng.
    const std::string advances = advances_table({
        AdvanceSpec{.input = kSword, .output = kSectSword, .gold = -1, .count = 0},
        AdvanceSpec{.input = kWhiteRing, .output = kCharm, .gold = -1, .count = 0, .first = lost},
        AdvanceSpec{.input = kCharm, .output = lost, .gold = 100, .count = 1, .first = kHerb},
        AdvanceSpec{.input = kPotion, .output = kCharm, .gold = 100, .count = 1, .first = lost},
        AdvanceSpec{.input = kHerb, .output = kCharm, .gold = 100, .count = 0, .first = kPotion, .second = kPotion},
        AdvanceSpec{.input = kQuestItem, .output = kCharm, .gold = 0, .count = 1},
    });
    const ForgeBench bench({.melting = melting, .carving = carving, .advances = advances});
    const forge::ForgeTables& tables = bench.tables;
    context.expect(tables.all(Kind::kMelt).size() == 1 && tables.find(Kind::kMelt, id_of(kUniqueRing)) != nullptr, "nung: chỉ dòng toàn mã quen còn lại");
    context.expect(tables.all(Kind::kCarve).size() == 1, "chạm: dòng có mã lạ bị bỏ");
    context.expect(tables.diagnostics().unknown_rows == 4 + 1 + 2, "đếm bốn dòng nung, một dòng chạm, hai dòng nâng cấp có mã lạ");
    context.expect(tables.diagnostics().disabled_advances == 2, "hai dòng gold_cost -1");
    context.expect(tables.find(Kind::kAdvance, id_of(kSword)) == nullptr && tables.find(Kind::kAdvance, id_of(kWhiteRing)) == nullptr,
        "dòng chưa mở không thành nâng cấp miễn phí");

    // material_count 0: không vật liệu dù có mã vật liệu, vẫn giữ vàng. Vàng 0 và không vật liệu là công thức miễn phí có chủ ý của bảng.
    const forge::Recipe* no_count = tables.find(Kind::kAdvance, id_of(kHerb));
    context.expect(no_count != nullptr && no_count->gold == 100 && tables.needs(*no_count).empty(), "material_count 0: không vật liệu");
    const forge::Recipe* bare = tables.find(Kind::kAdvance, id_of(kQuestItem));
    context.expect(bare != nullptr && bare->gold == 0 && tables.needs(*bare).empty(), "không vàng, không vật liệu");
    context.expect(tables.all(Kind::kAdvance).size() == 2, "nâng cấp: hai dòng sống sót");
}

void empty_sources(Context& context) {
    const ForgeBench bench(forge::ForgeSources{});
    for (const Kind kind : {Kind::kMelt, Kind::kCarve, Kind::kAdvance}) {
        context.expect(bench.tables.all(kind).empty() && bench.tables.find(kind, id_of(kGem)) == nullptr, "không nguồn thì không công thức");
    }
}

void bad_tables(Context& context) {
    const std::string melt_head = "# schema 1\ngem_id\tsmelted_gem_id\trequired_item_id\trequired_money\tsubstitute_item_id\n";
    const auto melt_row = [&melt_head](std::string_view cells) { return melt_head + std::string(cells) + "\n"; };
    const std::string good = std::to_string(kGem) + "\t" + std::to_string(kWhiteRing) + "\t" + std::to_string(kHerb) + "\t10\t-1";
    context.expect(forge_load_error({.melting = melt_row(good)}).empty(), "bảng mẫu nạp được");

    const std::string no_column = forge_load_error({.melting = "# schema 1\ngem_id\tsmelted_gem_id\trequired_item_id\trequired_money\n1\t2\t3\t4\n"});
    context.expect(has(no_column, "gem_melting") && has(no_column, "substitute_item_id"), "thiếu cột: nêu bảng và cột");
    context.expect(has(forge_load_error({.carving = "# schema 1\ngem_id\tcarved_gem_id\trequired_item_id\n1\t2\t3\n"}), "gem_carving"), "chạm: thiếu cột");
    context.expect(has(forge_load_error({.advances = "# schema 1\nitem_id\tadvanced_item_id\n1\t2\n"}), "super_weapon_advances"), "nâng cấp: thiếu cột");

    const std::string dup = melt_row(good + "\n" + good);
    const std::string dup_error = forge_load_error({.melting = dup});
    context.expect(has(dup_error, "gem_melting") && has(dup_error, std::to_string(kGem)), "đầu vào trùng: nêu bảng và mã");
    context.expect(!forge_load_error({.carving = carving_table({CarveSpec{.input = kGem, .output = kSword, .need = kHerb},
                        CarveSpec{.input = kGem, .output = kCharm, .need = kHerb}})})
                        .empty(),
        "chạm: đầu vào trùng");
    context.expect(!forge_load_error({.advances = advances_table({AdvanceSpec{.input = kSword, .output = kCharm, .gold = 1, .count = 0},
                        AdvanceSpec{.input = kSword, .output = kCharm, .gold = 2, .count = 0}})})
                        .empty(),
        "nâng cấp: đầu vào trùng");

    // Số ngoài miền, chữ lạ, dòng thiếu ô: mỗi thứ là một lỗi chứ không là giá trị mặc định.
    const std::string base = std::to_string(kGem) + "\t" + std::to_string(kWhiteRing) + "\t" + std::to_string(kHerb);
    context.expect(!forge_load_error({.melting = melt_row(base + "\t-5\t-1")}).empty(), "vàng nung âm");
    context.expect(!forge_load_error({.melting = melt_row(base + "\t2147483648\t-1")}).empty(), "vàng nung vượt int32");
    context.expect(!forge_load_error({.melting = melt_row(base + "\tmười\t-1")}).empty(), "vàng là chữ");
    context.expect(!forge_load_error({.melting = melt_row(base + "\t10")}).empty(), "thiếu ô cuối dòng");
    context.expect(!forge_load_error({.melting = melt_row("0\t" + std::to_string(kWhiteRing) + "\t" + std::to_string(kHerb) + "\t1\t-1")}).empty(),
        "mã đầu vào 0");
    context.expect(!forge_load_error({.advances = advances_table({AdvanceSpec{.input = kSword, .output = kCharm, .gold = -2}})}).empty(),
        "gold_cost -2 không phải dấu hiệu chưa mở");
    context.expect(!forge_load_error({.advances = advances_table({AdvanceSpec{.input = kSword, .output = kCharm, .gold = 1, .count = 101}})}).empty(),
        "material_count quá trần");
    context.expect(!forge_load_error({.advances = advances_table({AdvanceSpec{.input = kSword, .output = kCharm, .gold = 1, .count = -1}})}).empty(),
        "material_count âm");
}

void lookup_any_row_order(Context& context) {
    // Xếp ngược để sắp xếp sau nạp có việc làm; tra cứu phải đúng cho mọi dòng và trượt cho mọi mã lạ.
    const std::array<std::uint32_t, 5> inputs{kGem, kPickBound, kNoSell, kUniqueRing, kQuestItem};
    std::vector<MeltSpec> rows;
    for (std::size_t i = inputs.size(); i-- > 0;) {
        rows.push_back(MeltSpec{.input = inputs[i], .output = kCharm, .need = kHerb, .gold = static_cast<std::int64_t>(100 * (i + 1))});
    }
    const ForgeBench bench({.melting = melting_table(rows)});
    for (std::size_t i = 0; i < inputs.size(); ++i) {
        const forge::Recipe* found = bench.tables.find(Kind::kMelt, id_of(inputs[i]));
        context.expect(found != nullptr && found->gold == static_cast<std::int64_t>(100 * (i + 1)), "mỗi mã tra ra đúng dòng của nó");
    }
    context.expect(bench.tables.find(Kind::kMelt, id_of(kPotion)) == nullptr && bench.tables.find(Kind::kMelt, id_of(0)) == nullptr, "mã không có thì nullptr");
}

#ifdef GAME_SERVER_TABLES
// Đối chiếu từng dòng bảng thật với công thức đã nạp, bằng bộ tách TSV của test. Mã lạ (ngoài catalog) và dòng chưa mở bị bỏ theo đúng
// luật tables.hpp; mọi dòng còn lại phải có công thức khớp từng ô.
struct RealCheck {
    Context& context;
    const RealWorld& real;
    const forge::ForgeTables& tables;
    std::size_t unknown = 0;
    std::size_t disabled = 0;

    [[nodiscard]] bool known(const std::string& cell) const {
        const long value = std::stol(cell);
        return value <= 0 || real.catalog.find(TemplateId{static_cast<std::uint32_t>(value)}) != nullptr;
    }
    [[nodiscard]] static std::uint32_t code(const std::string& cell) { return static_cast<std::uint32_t>(std::stoul(cell)); }

    // Cột 0 đầu vào, 1 đầu ra, 2 vàng/vật liệu tuỳ bảng; `ids` là các cột mã phải quen (ô <= 0 là không có).
    std::size_t run(Kind kind, const std::vector<std::vector<std::string>>& raw, std::size_t gold_col, const std::vector<std::size_t>& ids) {
        std::size_t expected = 0;
        for (std::size_t r = 1; r < raw.size(); ++r) {
            const std::vector<std::string>& row = raw[r];
            if (kind == Kind::kAdvance && std::stol(row[gold_col]) < 0) {
                ++disabled;
                continue;
            }
            bool all_known = true;
            for (const std::size_t col : ids) all_known = all_known && known(row[col]);
            if (!all_known) {
                ++unknown;
                continue;
            }
            ++expected;
            const forge::Recipe* recipe = tables.find(kind, TemplateId{code(row[0])});
            context.expect(recipe != nullptr, "dòng bảng thật có công thức");
            if (recipe == nullptr) continue;
            context.expect(recipe->output.value() == code(row[1]) && recipe->gold == std::stol(row[gold_col]), "đầu ra và vàng khớp");
            const auto needs = tables.needs(*recipe);
            const auto alt = tables.alternative(*recipe);
            if (kind == Kind::kAdvance) {
                const long count = std::stol(row[3]);
                std::vector<std::uint32_t> want;
                for (const std::size_t col : {std::size_t{4}, std::size_t{5}}) {
                    if (count > 0 && std::stol(row[col]) > 0) want.push_back(code(row[col]));
                }
                context.expect(needs.size() == want.size() && alt.empty(), "số vật liệu nâng cấp khớp");
                for (std::size_t i = 0; i < std::min(needs.size(), want.size()); ++i) {
                    context.expect(needs[i].item.value() == want[i] && needs[i].count == count, "vật liệu và số lượng nâng cấp khớp");
                }
            } else {
                context.expect(needs.size() == 1 && needs[0].item.value() == code(row[2]) && needs[0].count == 1, "vật liệu chính khớp");
                const bool has_alt = kind == Kind::kMelt && std::stol(row[4]) > 0;
                context.expect(alt.size() == (has_alt ? 1U : 0U) && (!has_alt || alt[0].item.value() == code(row[4])), "vật liệu thay thế khớp");
            }
        }
        context.expect(tables.all(kind).size() == expected, "số công thức bằng số dòng còn lại");
        return expected;
    }
};

void real_tables(Context& context) {
    const std::optional<RealWorld> real = load_real(context);
    if (!real) return;
    const std::string root = GAME_SERVER_TABLES;
    const std::string melting = read_text(root + "/shared/gem_melting.tsv");
    const std::string carving = read_text(root + "/shared/gem_carving.tsv");
    const std::string advances = read_text(root + "/server/super_weapon_advances.tsv");
    const auto loaded = forge::ForgeTables::load({.melting = melting, .carving = carving, .advances = advances}, real->catalog);
    context.expect(loaded.has_value(), "bảng thật nạp được");
    if (!loaded) {
        std::fprintf(stderr, "%s\n", loaded.error().c_str());
        return;
    }
    const auto melt_raw = tsv_rows(melting);
    const auto carve_raw = tsv_rows(carving);
    const auto advance_raw = tsv_rows(advances);
    RealCheck check{.context = context, .real = *real, .tables = *loaded};
    const std::size_t melts = check.run(Kind::kMelt, melt_raw, 3, {0, 1, 2, 4});
    const std::size_t carves = check.run(Kind::kCarve, carve_raw, 3, {0, 1, 2});
    const std::size_t advs = check.run(Kind::kAdvance, advance_raw, 2, {0, 1, 4, 5});
    context.expect(loaded->diagnostics().unknown_rows == check.unknown && loaded->diagnostics().disabled_advances == check.disabled,
        "số dòng bỏ khớp bộ đếm độc lập");
    // Số đo ngày 2026-10-14, ghi lại để đổi bảng là biết: 64 dòng nung, 128 dòng chạm, 438 dòng nâng cấp trong đó 126 chưa mở.
    context.expect(melt_raw.size() - 1 == 64 && carve_raw.size() - 1 == 128 && advance_raw.size() - 1 == 438 && check.disabled == 126,
        "số dòng của bảng thật như đã đo");
    context.expect(melts == 64 && carves == 128 && advs == 312 && check.unknown == 0, "mọi dòng mở được của bảng thật đều có mã quen: 64 + 128 + 312 công thức");
    context.expect(melts + carves + advs + check.unknown + check.disabled == 64 + 128 + 438, "mỗi dòng hoặc thành công thức hoặc bị đếm");

    // Mỗi mã đầu vào chỉ xuất hiện một lần trong mỗi bảng (kiểm bằng so sánh kề nhau, không bằng bộ nạp).
    for (const Kind kind : {Kind::kMelt, Kind::kCarve, Kind::kAdvance}) {
        const std::span<const forge::Recipe> all = loaded->all(kind);
        context.expect(std::ranges::adjacent_find(all, [](const forge::Recipe& a, const forge::Recipe& b) { return a.input == b.input; }) == all.end(),
            "không đầu vào nào lặp");
    }
}
#endif

constexpr std::array kCases{
    Case{"reads_the_three_tables", reads_the_three_tables},
    Case{"skips_unknown_and_disabled", skips_unknown_and_disabled},
    Case{"empty_sources", empty_sources},
    Case{"bad_tables", bad_tables},
    Case{"lookup_any_row_order", lookup_any_row_order},
#ifdef GAME_SERVER_TABLES
    Case{"real_tables", real_tables},
#endif
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
