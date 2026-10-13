// Trạng thái nhân vật (hero): phần đầy của chỉ số theo đúng phép chia của script gốc, và nhân vật
// mới theo cấu hình của máy chủ gốc.
#include "hero/hero.hpp"

#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using hero::fill_of;
using hero::Gauge;

static_assert(fill_of(Gauge{.now = 50, .top = 100}) == 0.5F);
static_assert(fill_of(Gauge{.now = 0, .top = 100}) == 0.0F);
static_assert(fill_of(Gauge{.now = 300, .top = 100}) == 1.0F, "vượt trần thì đầy");
static_assert(fill_of(Gauge{.now = -5, .top = 100}) == 0.0F, "số âm thì rỗng");
// PlayerFrame.lua: trần 0 thì chia cho 1, nên còn máu là thanh đầy.
static_assert(fill_of(Gauge{.now = 7, .top = 0}) == 1.0F);
static_assert(fill_of(Gauge{.now = 0, .top = 0}) == 0.0F);

void fill_keeps_precision(Context& context) {
    // Kinh nghiệm cấp 150 của client 2026 gần 2^31: phép chia phải đi qua double.
    const Gauge late{.now = 1707414659, .top = 1707414660};
    context.expect(fill_of(late) <= 1.0F, "không vượt 1");
    const Gauge third{.now = 195, .top = 585};
    context.expect(fill_of(third) == static_cast<float>(195.0 / 585.0), "195/585");
}

void newcomer_matches_server(Context& context) {
    const hero::Hero hero = hero::newcomer();
    context.expect(hero.level == 1, "cấp 1");
    context.expect(!hero.name.empty(), "có tên");
    context.expect(hero.health.now == 585 && hero.health.top == 585, "máu 585/585");
    context.expect(hero.mana.now == 310 && hero.mana.top == 310, "khí 310/310");
    context.expect(hero.rage.now == 0 && hero.rage.top == 1000, "nộ 0/1000");
    context.expect(hero.experience.now == 0 && hero.experience.top == 90, "kinh nghiệm 0/90");
    context.expect(hero.strike_points == 0 && !hero.is_leader, "chưa liên kích, không đội");
    context.expect(hero.portrait == hero::PortraitId{1}, "chân dung nữ đầu tiên");
}

// Chỉ số của bảng nhân vật: DefaultChar.ini và hệ số [MENPAI9] của BaseValueTable.ini, làm tròn
// nửa lên như Float2Int của máy chủ gốc.
void newcomer_sheet_matches_server(Context& context) {
    const hero::Hero hero = hero::newcomer();
    const hero::Roots roots{.strength = 7, .spirit = 6, .constitution = 5, .stability = 5, .agility = 2};
    context.expect(hero.sect == hero::Sect::kNone, "chưa môn phái");
    context.expect(hero.roots == roots && hero.spare_points == 0, "năm chỉ số gốc, 0 điểm dư");
    hero::Combat combat;
    combat.attack_physical = 56;
    combat.attack_magic = 51;
    combat.defence_physical = 46;
    combat.defence_magic = 46;
    combat.hit = 38;
    combat.miss = 13;
    combat.critical_attack = 1;
    combat.critical_defence = 1;
    context.expect(hero.combat == combat, "tám chỉ số chiến đấu");
    context.expect(hero.vigor.now == 10 && hero.vigor.top == 50, "hoạt lực 10/50");
    context.expect(hero.energy.now == 10 && hero.energy.top == 50, "tinh lực 10/50");
    context.expect(!hero.cultivation && hero.milestones.bits == 0, "chưa tu luyện, chưa mốc nào");
    context.expect(!hero::can_level_up(hero), "0/90 thì chưa lên cấp được");
}

void level_up_needs_full_experience(Context& context) {
    hero::Hero hero = hero::newcomer();
    hero.experience.now = hero.experience.top;
    context.expect(hero::can_level_up(hero), "đủ kinh nghiệm thì lên được");
    hero::Milestones marks;
    marks.add(hero::Milestone::kMeridian);
    context.expect(marks.has(hero::Milestone::kMeridian), "mốc vừa thêm");
    context.expect(!marks.has(hero::Milestone::kChild), "mốc khác không dính");
    const hero::Milestones child = hero::Milestones::of(hero::Milestone::kChild);
    context.expect(marks.covers(hero::Milestones{}), "tập rỗng thì luôn đủ");
    context.expect(!marks.covers(child), "thiếu mốc thì chưa đủ");
    marks.add(hero::Milestone::kChild);
    context.expect(marks.covers(child), "thêm mốc rồi thì đủ");
}

// Bảng DBC hai cột dựng tay theo đúng bố cục của Config/PlayerExpLevel.txt.
std::string exp_dbc(std::uint32_t second_level, std::string_view texts, std::uint32_t second_offset) {
    std::string bytes;
    const auto put = [&bytes](std::uint32_t value) {
        for (int shift = 0; shift < 32; shift += 8) bytes.push_back(static_cast<char>((value >> shift) & 0xFFU));
    };
    put(0xDDBBCC00U);
    put(2);
    put(2);
    put(static_cast<std::uint32_t>(texts.size()));
    put(0);
    put(2);
    put(1);
    put(0);
    put(second_level);
    put(second_offset);
    bytes.append(texts);
    return bytes;
}

void exp_table_reads_client_layout(Context& context) {
    using namespace std::string_view_literals;
    const std::string good = exp_dbc(2, "90\0"
                                        "1707414660\0"sv, 3);
    const auto table = hero::read_exp_table(good);
    context.expect(table.has_value(), "bảng đúng thì đọc được");
    if (!table) return;
    context.expect(table->size() == 2, "hai cấp");
    context.expect(hero::exp_need(*table, 1) == 90, "cấp 1 cần 90 như client 2026");
    context.expect(hero::exp_need(*table, 2) == 1707414660, "số vượt int32 vẫn đúng");
    context.expect(!hero::exp_need(*table, 0) && !hero::exp_need(*table, 3), "ngoài bảng thì không có");
    context.expect(!hero::read_exp_table(exp_dbc(3, "90\0"
                                                    "5\0"sv, 3)), "cấp nhảy thì từ chối");
    context.expect(!hero::read_exp_table(exp_dbc(2, "90\0"
                                                    "x\0"sv, 3)), "chữ không phải số thì từ chối");
    context.expect(!hero::read_exp_table(exp_dbc(2, "90\0"
                                                    "5\0"sv, 99)), "chuỗi ngoài khối thì từ chối");
    context.expect(!hero::read_exp_table(good.substr(0, good.size() - 4)), "tệp cụt thì từ chối");
    context.expect(!hero::read_exp_table(""), "tệp rỗng thì từ chối");
}

constexpr std::array kCases{
    Case{.name = "exp_table_reads_client_layout", .body = &exp_table_reads_client_layout},
    Case{.name = "fill_keeps_precision", .body = &fill_keeps_precision},
    Case{.name = "newcomer_matches_server", .body = &newcomer_matches_server},
    Case{.name = "newcomer_sheet_matches_server", .body = &newcomer_sheet_matches_server},
    Case{.name = "level_up_needs_full_experience", .body = &level_up_needs_full_experience},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "hero_tests: mọi ca phải qua");
    return 0;
}
