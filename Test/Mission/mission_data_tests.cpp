// Danh mục nhiệm vụ trên bảng THẬT do công cụ trích tĩnh sinh ra (dev/server/tables/server/mission_*.tsv): nạp được không, độ phủ
// là bao nhiêu, và mọi nhiệm vụ bảng chạy được có đi hết nhận → tiến độ → nộp trên chính dữ liệu đó không. Đây là chỗ bắt
// công cụ trích sinh bảng sai mà nạp vẫn qua. Bảng vắng (chưa chạy lua_extract.py) thì bỏ qua và nói rõ ở stdout.
#include "test.hpp"

#include <array>
#include <print>

#ifdef GAME_SERVER_TABLES
#include "bus/bus.hpp"
#include "dice/dice.hpp"
#include "mission/book.hpp"
#include "mission/catalog.hpp"
#include "mission/engine.hpp"
#include "ops/ops.hpp"
#include "support/mission_fakes.hpp"
#include "support/real_tables.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_set>
#include <utility>
#include <vector>
#endif

namespace game::test {
namespace {

#ifdef GAME_SERVER_TABLES

using mission::Catalog;
using mission::ObjectiveKind;
using mission::Quest;
using mission::Source;

struct RealTables {
    table::Tsv quests, objectives, rewards, prereqs, hooks, npcs, autos, groups, conditions, effects;
};

std::optional<RealTables> read_all() {
    RealTables all;
    const std::array<std::pair<table::Tsv*, const char*>, 10> files{{{&all.quests, "mission_quests"},
        {&all.objectives, "mission_objectives"}, {&all.rewards, "mission_rewards"}, {&all.prereqs, "mission_prereqs"},
        {&all.hooks, "mission_hooks"}, {&all.npcs, "mission_npcs"}, {&all.autos, "mission_auto"},
        {&all.groups, "mission_name_groups"}, {&all.conditions, "ops_conditions"}, {&all.effects, "ops_effects"}}};
    for (const auto& [target, name] : files) {
        auto table = read_server_table(name);
        if (!table) return std::nullopt;
        *target = std::move(*table);
    }
    return all;
}

std::optional<Catalog> load_catalog(const RealTables& all, Context& context) {
    auto program = ops::Program::load(all.conditions, all.effects);
    context.expect(program.has_value(), "ops::Program nạp bảng thật");
    if (!program) return std::nullopt;
    const mission::Tables tables{.quests = all.quests, .objectives = all.objectives, .rewards = all.rewards, .prereqs = all.prereqs,
        .hooks = all.hooks, .npcs = all.npcs, .autos = all.autos, .name_groups = all.groups};
    auto catalog = Catalog::load(std::move(*program), tables, {});
    context.expect(catalog.has_value(), "danh mục nhiệm vụ nạp bảng thật");
    if (!catalog) {
        std::print(stderr, "{}: {}\n", catalog.error().table, catalog.error().detail);
        return std::nullopt;
    }
    return std::move(*catalog);
}

// Lý do của script `(x<số>_Hàm)` chỉ khác số script: gộp thành một họ `(xN_Hàm)` để bản in ngắn lại.
std::string family_of(const std::string& reason) {
    std::string out;
    for (std::size_t at = 0; at < reason.size(); ++at) {
        out.push_back(reason[at]);
        if (reason[at] != 'x' || at == 0 || reason[at - 1] != '(') continue;
        std::size_t end = at + 1;
        while (end < reason.size() && reason[end] >= '0' && reason[end] <= '9') ++end;
        if (end > at + 1 && end < reason.size() && reason[end] == '_') {
            out.push_back('N');
            at = end - 1;
        }
    }
    return out;
}

void real_catalog_loads(Context& context) {
    const auto all = read_all();
    if (!all) {
        std::print("[bỏ qua] chưa có bảng mission_*.tsv: chạy TOOLS/server/lua_extract.py\n");
        return;
    }
    const auto catalog = load_catalog(*all, context);
    if (!catalog) return;
    const mission::Report& report = catalog->report();
    context.expect(report.quests == all->quests.rows.size() && report.quests > 1000, "đủ dòng nhiệm vụ");
    context.expect(report.runnable + report.unsupported + report.not_in_client + report.blocked == report.quests,
        "mọi nhiệm vụ rơi vào đúng một nhóm hỗ trợ");
    context.expect(report.runnable > 1000, "phần lớn nhiệm vụ chạy được");
    context.expect(report.blocked == 0, "không có nhiệm vụ nằm trên vòng tiền đề");
    std::print("[độ phủ] {} nhiệm vụ: chạy được {}, chưa hỗ trợ {}, ngoài client {}, bị chặn {}; {} có tiền đề ngoài danh mục\n",
        report.quests, report.runnable, report.unsupported, report.not_in_client, report.blocked, report.missing_prereq_quests);
    std::map<std::string, std::size_t> by_family;
    for (const auto& [reason, count] : report.reasons) by_family[family_of(reason)] += count;
    for (const auto& [reason, count] : by_family) std::print("[lý do] {:5}  {}\n", count, reason);
    // Mọi dòng không chạy được đều có lý do: không nhiệm vụ nào bị bỏ im.
    context.expect(std::ranges::all_of(catalog->quests(), [](const Quest& one) { return one.runnable() || !one.reason.empty(); }),
        "mỗi nhiệm vụ không chạy được mang lý do");
    // Mọi mã tham chiếu giữa các bảng đã được bộ nạp kiểm; còn lại là mã client: id nhiệm vụ ngoài 0..4095 không thể có.
    context.expect(std::ranges::all_of(catalog->quests(), [](const Quest& one) { return one.quest >= 0 && one.quest < mission::kQuestIdLimit; }),
        "id nhiệm vụ trong miền");
}

// Đưa một người chơi tới mức có thể nhận nhiệm vụ này: cấp đủ, tiền đề đã xong, vài điều kiện nhận hay gặp đã đạt.
void prepare(FakeCharacter& hero, const Quest& quest) {
    hero.level_value = std::max(quest.level, 1) + 1;
    for (const std::int32_t prereq : quest.prereqs) hero.book().mark_done(prereq);
    hero.bundle.wallet.normal = 1'000'000;
}

// Làm cho mọi mục tiêu của nhiệm vụ bảng đạt bằng các sự kiện thật; trả false nếu có mục tiêu không thể làm bằng sự kiện.
bool satisfy(mission::Engine& engine, FakeCharacter& hero, const Quest& quest, const ops::Calendar& calendar) {
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tham số a, b và mã tên của sự kiện khác vai, nơi gọi nêu tên (HP-07)
    const auto send = [&](bus::Kind kind, std::uint32_t a, std::uint32_t b, std::uint32_t name) {
        bus::Event event;
        event.kind = kind;
        event.hero = hero.id();
        event.a = a;
        event.b = b;
        event.name = name;
        static_cast<void>(engine.handle(hero, event, calendar));
    };
    for (const mission::Objective& one : quest.objectives) {
        switch (one.kind) {
            case ObjectiveKind::kTalk: send(bus::Kind::kTalk, static_cast<std::uint32_t>(one.target), 0, one.name); break;
            case ObjectiveKind::kKill:
                for (std::int32_t i = 0; i < one.count; ++i) send(bus::Kind::kKill, 0, 0, static_cast<std::uint32_t>(one.target));
                break;
            case ObjectiveKind::kLoot:
            case ObjectiveKind::kDeliver:
                hero.give(static_cast<std::uint32_t>(one.item), std::max(one.count, 1));
                send(bus::Kind::kItemChanged, static_cast<std::uint32_t>(one.item), 0, 0);
                break;
            case ObjectiveKind::kArea:
                send(bus::Kind::kEnterArea, static_cast<std::uint32_t>(std::max(one.scene, 0)), static_cast<std::uint32_t>(one.target), 0);
                break;
            case ObjectiveKind::kEscort:
            case ObjectiveKind::kProgress:
            case ObjectiveKind::kCollect: return false;
        }
    }
    return true;
}

struct Walk {
    std::size_t tried = 0;
    std::size_t completed = 0;
    std::map<std::string, std::size_t> stuck;  // lý do không đi hết, đếm theo bước
};

// Đi hết vòng đời của một nhiệm vụ bảng trên người chơi mới. Trả mô tả bước hỏng, rỗng nếu xong.
std::string run_quest(const Catalog& catalog, const Quest& quest, const ops::Calendar& calendar) {
    dice::Dice dice(2026);
    mission::Engine engine(catalog, dice);
    FakeCharacter hero;
    prepare(hero, quest);
    // Một số nhiệm vụ chỉ nhận được ở một môn phái (điều kiện sect_is): thử lần lượt các môn phái của client 2026.
    for (std::int32_t sect = 0; sect < 16 && engine.check_accept(hero, quest, calendar); ++sect) hero.sect_value = sect;
    auto accepted = engine.accept_script(hero, quest.script, calendar);
    if (!accepted) return std::string("nhận: ") + std::string(mission::describe(accepted.error().error));
    if (!satisfy(engine, hero, quest, calendar)) return "mục tiêu không làm được bằng sự kiện";
    if (!engine.ready(hero, quest, calendar)) return "đủ mục tiêu mà chưa sẵn sàng nộp";
    std::int32_t choice = -1;
    for (const mission::Reward& reward : quest.rewards) {
        if (reward.group == mission::RewardGroup::kChoice && reward.kind == mission::RewardKind::kItem) {
            choice = reward.ref;
            break;
        }
    }
    const auto done = engine.turn_in(hero, quest.quest, choice, calendar);
    if (!done) return std::string("nộp: ") + std::string(mission::describe(done.error().error));
    if (!hero.book().is_done(quest.quest) && quest.repeat == mission::Repeat::kOnce) return "nộp xong mà không đánh dấu đã xong";
    if (hero.book().find(quest.quest) != nullptr) return "nộp xong mà còn trong sổ";
    return {};
}

void every_table_quest_completes(Context& context) {
    const auto all = read_all();
    if (!all) return;
    auto catalog = load_catalog(*all, context);
    if (!catalog) return;
    ops::Calendar calendar;
    calendar.day = 100;
    calendar.unix_seconds = 1'700'000'000;
    Walk walk;
    std::map<std::string, std::vector<std::uint32_t>> examples;
    for (const Quest& quest : catalog->quests()) {
        if (!quest.runnable() || quest.source != Source::kTable) continue;
        ++walk.tried;
        const std::string problem = run_quest(*catalog, quest, calendar);
        if (problem.empty()) {
            ++walk.completed;
        } else {
            ++walk.stuck[problem];
            if (auto& list = examples[problem]; list.size() < 3) list.push_back(quest.script);
        }
    }
    std::print("[đi hết] nhiệm vụ bảng chạy được: {}, đi hết nhận-tiến độ-nộp: {}\n", walk.tried, walk.completed);
    for (const auto& [problem, count] : walk.stuck) {
        std::print("[kẹt] {:5}  {} (ví dụ script {})\n", count, problem, examples[problem].front());
    }
    context.expect(walk.tried > 900, "có nhiều nhiệm vụ bảng để đi");
    context.expect(walk.completed == walk.tried, "mọi nhiệm vụ bảng chạy được đều đi hết vòng đời trên dữ liệu thật");
}

// Mọi chuỗi next_script cực đại trong số nhiệm vụ bảng chạy được: nộp nhiệm vụ này mở nhiệm vụ kế. Đầu chuỗi là nhiệm vụ không
// ai trỏ tới; chuỗi dừng ở nhiệm vụ không chạy được (không bị tính) hoặc khi vòng lại.
std::vector<std::vector<const Quest*>> chains_of(const Catalog& catalog) {
    std::unordered_set<std::uint32_t> pointed;
    for (const Quest& quest : catalog.quests()) {
        if (quest.next_script != 0) pointed.insert(quest.next_script);
    }
    std::vector<std::vector<const Quest*>> out;
    for (const Quest& head : catalog.quests()) {
        if (pointed.contains(head.script) || !head.runnable() || head.source != Source::kTable) continue;
        std::vector<const Quest*> chain;
        const Quest* at = &head;
        std::unordered_set<std::uint32_t> seen;
        while (at != nullptr && at->runnable() && at->source == Source::kTable && seen.insert(at->script).second) {
            chain.push_back(at);
            at = at->next_script == 0 ? nullptr : catalog.by_script(at->next_script);
        }
        out.push_back(std::move(chain));
    }
    return out;
}

// Đi hết một chuỗi bằng MỘT người chơi: tiền đề trong chuỗi tự đến từ việc nộp nhiệm vụ trước, tiền đề ngoài chuỗi đánh dấu sẵn.
// Trả số nhiệm vụ đã nộp xong.
std::size_t walk_chain(const Catalog& catalog, const std::vector<const Quest*>& chain, Context& context) {
    dice::Dice dice(11);
    mission::Engine engine(catalog, dice);
    FakeCharacter hero;
    hero.level_value = 200;
    hero.bundle.wallet.normal = 1'000'000;
    ops::Calendar calendar;
    calendar.day = 100;
    calendar.unix_seconds = 1'700'000'000;
    for (const Quest* first : chain) {
        for (const std::int32_t prereq : first->prereqs) {
            const bool inside = std::ranges::any_of(chain, [prereq](const Quest* one) { return one->quest == prereq; });
            if (!inside) hero.book().mark_done(prereq);
        }
    }
    std::size_t finished = 0;
    for (const Quest* quest : chain) {
        for (std::int32_t sect = 0; sect < 16 && engine.check_accept(hero, *quest, calendar); ++sect) hero.sect_value = sect;
        const auto accepted = engine.accept_script(hero, quest->script, calendar);
        if (!accepted) {
            std::print(stderr, "chuỗi dừng ở script {} (nhiệm vụ {}): nhận: {}\n", quest->script, quest->quest,
                std::string(mission::describe(accepted.error().error)));
            break;
        }
        if (!satisfy(engine, hero, *quest, calendar) || !engine.ready(hero, *quest, calendar)) {
            std::print(stderr, "chuỗi dừng ở script {}: chưa sẵn sàng nộp\n", quest->script);
            break;
        }
        std::int32_t choice = -1;
        for (const mission::Reward& reward : quest->rewards) {
            if (reward.group == mission::RewardGroup::kChoice && reward.kind == mission::RewardKind::kItem) {
                choice = reward.ref;
                break;
            }
        }
        const auto done = engine.turn_in(hero, quest->quest, choice, calendar);
        if (!done) {
            std::print(stderr, "chuỗi dừng ở script {}: nộp: {}\n", quest->script, std::string(mission::describe(done.error().error)));
            break;
        }
        ++finished;
    }
    context.expect(finished != chain.size() || hero.book().active() == 0, "xong chuỗi thì sổ trống");
    return finished;
}

void longest_chain_end_to_end(Context& context) {
    const auto all = read_all();
    if (!all) return;
    auto catalog = load_catalog(*all, context);
    if (!catalog) return;
    const auto chains = chains_of(*catalog);
    const auto best = std::ranges::max_element(chains, {}, [](const auto& chain) { return chain.size(); });
    context.expect(best != chains.end() && best->size() >= 10, "có chuỗi next_script chạy được từ 10 nhiệm vụ trở lên");
    if (best == chains.end()) return;
    const std::size_t finished = walk_chain(*catalog, *best, context);
    std::print("[chuỗi] dài nhất {} nhiệm vụ (bắt đầu script {}, cấp {}), đi hết {}\n", best->size(), best->front()->script,
        best->front()->level, finished);
    context.expect(finished == best->size(), "đi hết chuỗi next_script dài nhất bằng một người chơi");
}

// Chuỗi cấp thấp nhất có từ 3 nhiệm vụ: nhiệm vụ tân thủ của client (1400..1424) không có trong dữ liệu máy chủ nào nên đây
// là chuỗi gần "người mới" nhất mà dữ liệu thật cho phép.
void lowest_chain_end_to_end(Context& context) {
    const auto all = read_all();
    if (!all) return;
    auto catalog = load_catalog(*all, context);
    if (!catalog) return;
    const auto chains = chains_of(*catalog);
    const std::vector<const Quest*>* lowest = nullptr;
    for (const auto& chain : chains) {
        if (chain.size() < 3) continue;
        if (lowest == nullptr || chain.front()->level < (*lowest).front()->level) lowest = &chain;
    }
    context.expect(lowest != nullptr, "có chuỗi từ 3 nhiệm vụ");
    if (lowest == nullptr) return;
    const std::size_t finished = walk_chain(*catalog, *lowest, context);
    std::print("[chuỗi] cấp thấp nhất {} nhiệm vụ (bắt đầu script {}, cấp {}), đi hết {}\n", lowest->size(),
        lowest->front()->script, lowest->front()->level, finished);
    context.expect(finished == lowest->size(), "đi hết chuỗi cấp thấp nhất");
}

constexpr std::array kCases{
    Case{.name = "real_catalog_loads", .body = real_catalog_loads},
    Case{.name = "every_table_quest_completes", .body = every_table_quest_completes},
    Case{.name = "longest_chain_end_to_end", .body = longest_chain_end_to_end},
    Case{.name = "lowest_chain_end_to_end", .body = lowest_chain_end_to_end},
};

#else

void tables_unavailable(Context&) {
    std::print("[bỏ qua] dựng không có dev/server/tables/server/mission_quests.tsv\n");
}

constexpr std::array kCases{Case{.name = "tables_unavailable", .body = tables_unavailable}};

#endif

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
