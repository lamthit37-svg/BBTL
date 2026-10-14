// Hội thoại trên bảng THẬT do công cụ trích tĩnh sinh ra (talk_*.tsv): nạp được không, độ phủ bao nhiêu, và mọi script NPC có hộp thoại
// gốc mở được, mọi lựa chọn của nó chạy được mà không treo, không tràn trần bước, không bị sổ cái từ chối vì lỗi dữ liệu. Đây là chỗ bắt
// công cụ trích sinh khối sai mà nạp vẫn qua. Bảng vắng (chưa chạy lua_extract.py) thì bỏ qua và nói rõ ở stdout.
#include "support/real_tables.hpp"
#include "test.hpp"

#include <array>

#ifdef GAME_SERVER_TABLES

#include "dice/dice.hpp"
#include "ids/ids.hpp"
#include "mission/catalog.hpp"
#include "mission/engine.hpp"
#include "ops/ops.hpp"
#include "support/mission_fakes.hpp"
#include "support/talk_data.hpp"
#include "table/tsv.hpp"
#include "talk/script.hpp"
#include "talk/service.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <print>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#endif

namespace game::test {
namespace {

#ifdef GAME_SERVER_TABLES

struct Loaded {
    table::Tsv blocks, entries, roles, events, quests, objectives, rewards, prereqs, hooks, npcs, autos, groups, conditions, effects;
};

std::optional<Loaded> read_all() {
    Loaded all;
    const std::array<std::pair<table::Tsv*, const char*>, 14> files{{{&all.blocks, "talk_blocks"}, {&all.entries, "talk_entries"},
        {&all.roles, "talk_npc_roles"}, {&all.events, "talk_npc_events"}, {&all.quests, "mission_quests"},
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

// Danh mục + chương trình hội thoại thật. Catalog giữ ops::Program mà Script đã kiểm tham chiếu.
struct World {
    std::optional<mission::Catalog> catalog;
    std::optional<talk::Script> script;
};

World load_world(const Loaded& all, Context& context) {
    World world;
    auto program = ops::Program::load(all.conditions, all.effects);
    context.expect(program.has_value(), "ops::Program nạp bảng thật");
    if (!program) return world;
    const mission::Tables tables{all.quests, all.objectives, all.rewards, all.prereqs, all.hooks, all.npcs, all.autos, all.groups};
    auto catalog = mission::Catalog::load(std::move(*program), tables, {});
    context.expect(catalog.has_value(), "danh mục nhiệm vụ nạp bảng thật");
    if (!catalog) return world;
    world.catalog = std::move(*catalog);
    auto script = talk::Script::load(world.catalog->program(), talk::Tables{all.blocks, all.entries, all.roles, all.events});
    context.expect(script.has_value(), "chương trình hội thoại nạp bảng thật");
    if (!script) {
        std::print(stderr, "{}: {}\n", script.error().table, script.error().detail);
        return world;
    }
    world.script = std::move(*script);
    return world;
}

void real_script_loads(Context& context) {
    const auto all = read_all();
    if (!all) {
        std::print("[bỏ qua] chưa có bảng talk_*.tsv: chạy TOOLS/server/lua_extract.py\n");
        return;
    }
    const World world = load_world(*all, context);
    if (!world.script) return;
    const talk::ScriptReport& report = world.script->report();
    context.expect(report.entries == all->entries.rows.size() && report.ok + report.no_dialog + report.unsupported == report.entries,
        "mọi điểm vào rơi vào đúng một nhóm");
    context.expect(report.ok > 2000 && report.npc_scripts > 1000, "phần lớn điểm vào trích được");
    std::print("[độ phủ] {} khối, {} bước, {} điểm vào: trích được {}, không có hội thoại {}, chưa trích được {}; {} script NPC\n",
        report.blocks, report.steps, report.entries, report.ok, report.no_dialog, report.unsupported, report.npc_scripts);
    for (const auto& [reason, count] : report.reasons) {
        if (count >= 8) std::print("[lý do] {:5}  {}\n", count, reason);
    }
    // Mỗi điểm vào chưa trích được đều mang lý do: không bị bỏ im.
    std::size_t blank = 0;
    for (const auto& row : all->entries.rows) {
        if (row[3] == "unsupported" && row[4].empty()) ++blank;
    }
    context.expect(blank == 0, "điểm vào chưa trích được đều có lý do ở bảng");
}

// Mỗi script NPC mở được hộp thoại gốc và mọi lựa chọn của nó chạy mà không treo. Mỗi lần thử dùng nhân vật mới để lựa chọn
// này không đổi trạng thái của lựa chọn kia.
void every_npc_script_walks(Context& context) {
    const auto all = read_all();
    if (!all) return;
    const World world = load_world(*all, context);
    if (!world.script) return;
    dice::Dice dice(3);
    mission::Engine engine(*world.catalog, dice);
    talk::Service service(*world.script, engine, {}, talk::Options{});
    FakeTalkWorld place;
    ops::Calendar calendar;
    calendar.day = 100;
    calendar.hour = 12;
    calendar.unix_seconds = 1'700'000'000;
    std::map<std::string, std::size_t> outcomes;
    std::size_t opened = 0;
    std::size_t options_run = 0;
    const std::array<std::int32_t, 3> levels{1, 40, 120};
    const auto fresh_hero = [](std::int32_t level) {
        auto hero = std::make_unique<FakeCharacter>();
        hero->level_value = level;
        hero->bundle.wallet.normal = 100'000'000;
        hero->bundle.items.capacity = 200;
        return hero;
    };
    for (const auto& row : all->roles.rows) {
        const auto script_id = static_cast<std::uint32_t>(std::stoul(row[0]));
        const talk::NpcRef npc{9000, 3, 0, script_id};
        for (const std::int32_t level : levels) {
            auto hero = fresh_hero(level);
            const talk::Result root = service.talk(*hero, npc, place, ids::Tick{1}, calendar);
            if (!root) {
                ++outcomes[std::string("mở: ") + std::string(talk::describe(root.error().error))];
                continue;
            }
            ++opened;
            const std::size_t count = root->view.choices.size();
            for (std::uint32_t index = 0; index < count; ++index) {
                auto chooser = fresh_hero(level);
                const talk::Result again = service.talk(*chooser, npc, place, ids::Tick{1}, calendar);
                if (!again) continue;
                const talk::Result chosen = service.choose(*chooser, again->session, index, place, ids::Tick{1}, calendar);
                ++options_run;
                if (chosen) {
                    ++outcomes["chọn: chạy được"];
                } else {
                    ++outcomes[std::string("chọn: ") + std::string(talk::describe(chosen.error().error))];
                }
                service.close(chooser->id());
            }
            service.close(hero->id());
        }
    }
    std::print("[đi hết] {} script NPC x {} cấp: mở được {} hộp thoại gốc, chạy {} lựa chọn\n", all->roles.rows.size(), levels.size(),
        opened, options_run);
    for (const auto& [what, count] : outcomes) std::print("[kết quả] {:6}  {}\n", count, what);
    context.expect(opened > 1000, "hầu hết script NPC mở được hộp thoại gốc");
    context.expect(!outcomes.contains("mở: hội thoại vượt trần bước") && !outcomes.contains("chọn: hội thoại vượt trần bước"),
        "không hộp thoại nào vượt trần bước");
    context.expect(!outcomes.contains("chọn: lựa chọn đã đổi"), "lựa chọn không tự đổi khi chưa có gì đổi trạng thái");
    context.expect(!outcomes.contains("chọn: nhiệm vụ hay sổ cái từ chối"),
        "với nhân vật đủ tiền và túi rộng, không bước effects nào bị sổ cái từ chối vì lỗi dữ liệu");
}

// Script nhiệm vụ có hộp thoại bảng (mission_info/continue/demand): chỉ ra nhiệm vụ nào trong danh mục để client biết nhận/nộp cái nào.
void mission_panels_name_their_quests(Context& context) {
    const auto all = read_all();
    if (!all) return;
    const World world = load_world(*all, context);
    if (!world.script) return;
    std::size_t panels = 0;
    std::size_t known = 0;
    std::size_t unknown = 0;
    for (const auto& row : all->entries.rows) {
        if (row[3] != "ok" || row[1] != "-1") continue;
        const auto script_id = static_cast<std::uint32_t>(std::stoul(row[0]));
        std::vector<std::uint32_t> pending{static_cast<std::uint32_t>(std::stoul(row[2]))};
        std::set<std::uint32_t> seen;
        bool has_panel = false;
        while (!pending.empty()) {
            const std::uint32_t block = pending.back();
            pending.pop_back();
            if (!seen.insert(block).second) continue;
            for (const talk::Step& step : world.script->block(block)) {
                has_panel = has_panel || (step.kind == talk::StepKind::kDispatch && step.dispatch != talk::DispatchKind::kList &&
                                             step.dispatch != talk::DispatchKind::kBox);
                const bool nested = step.kind == talk::StepKind::kBranch || step.kind == talk::StepKind::kGoto || step.kind == talk::StepKind::kCall;
                if (nested && step.a > 0) pending.push_back(static_cast<std::uint32_t>(step.a));
                if (step.kind == talk::StepKind::kBranch && step.b > 0) pending.push_back(static_cast<std::uint32_t>(step.b));
            }
        }
        if (!has_panel) continue;
        ++panels;
        if (world.catalog->by_script(script_id) != nullptr) {
            ++known;
        } else {
            ++unknown;
        }
    }
    std::print("[bảng nhiệm vụ] {} điểm vào gốc có bảng: {} thuộc danh mục nhiệm vụ, {} không (script phụ trợ)\n", panels, known, unknown);
    context.expect(known > 100, "phần lớn bảng nhiệm vụ gắn được với nhiệm vụ trong danh mục");
}

// NPC có mẫu "nhiệm vụ vòng" của 14 môn phái (script 1022, A Bích): menu hiện nhiệm vụ riêng của NPC khi đã xong nhiệm vụ kích hoạt (15)
// và đang không giữ nhiệm vụ vòng (id 101) của chính NPC này. Kiểm trên bảng thật cả ba trạng thái và đường lỗi Lua của sự kiện
// 200099 (tên NPC lạ thì hàm sự kiện bị ngắt, hộp thoại vẫn mở).
std::optional<std::uint32_t> script_of_ring_quest(const Loaded& all, std::string_view name) {
    const auto quest_column = table::column_of(all.quests, "quest");
    const auto name_column = table::column_of(all.quests, "name");
    const auto script_column = table::column_of(all.quests, "script");
    const auto status_column = table::column_of(all.quests, "status");
    if (!quest_column || !name_column || !script_column || !status_column) return std::nullopt;
    for (const auto& row : all.quests.rows) {
        if (row[*quest_column] == "101" && row[*name_column] == name && row[*status_column] == "ok") {
            return static_cast<std::uint32_t>(std::stoul(row[*script_column]));
        }
    }
    return std::nullopt;
}

bool has_text(const talk::View& view, std::uint32_t text_id) {
    return std::ranges::any_of(view.choices, [&](const talk::Choice& choice) { return choice.text.id == text_id; });
}

void ring_quest_npc_menu(Context& context) {
    const auto all = read_all();
    const auto strings = read_server_table("mission_strings");
    if (!all || !strings) return;
    const World world = load_world(*all, context);
    if (!world.script) return;
    const auto text_column = table::column_of(*strings, "text");
    const auto id_column = table::column_of(*strings, "id");
    const auto owner_column = table::column_of(*strings, "owner");
    if (!text_column || !id_column || !owner_column) return context.expect(false, "bảng chuỗi thiếu cột");
    std::optional<std::uint32_t> menu_text;
    for (const auto& row : strings->rows) {
        if (row[*text_column] == "阿碧任务" && row[*owner_column].starts_with("1022:")) {
            menu_text = static_cast<std::uint32_t>(std::stoul(row[*id_column]));
        }
    }
    const auto own = script_of_ring_quest(*all, "阿碧任务");
    const auto other = script_of_ring_quest(*all, "阿朱任务");
    if (!menu_text || !own || !other) return context.expect(false, "bảng thật có nhiệm vụ vòng của A Bích và A Châu");
    dice::Dice dice(3);
    mission::Engine engine(*world.catalog, dice);
    talk::Service service(*world.script, engine, {}, talk::Options{});
    FakeTalkWorld place;
    ops::Calendar calendar;
    calendar.day = 100;
    const auto menu_for = [&](std::string_view npc_name, auto&& prepare) {
        FakeCharacter hero;
        hero.level_value = 60;
        hero.bundle.items.capacity = 60;
        prepare(hero);
        const talk::NpcRef npc{9001, 3, ops::name_id(npc_name), 1022};
        const talk::Result root = service.talk(hero, npc, place, ids::Tick{1}, calendar);
        context.expect(root.has_value(), "hộp thoại gốc của NPC mở được");
        return root.has_value() && has_text(root->view, *menu_text);
    };
    context.expect(!menu_for("阿碧", [](FakeCharacter&) {}), "chưa xong nhiệm vụ kích hoạt: không có menu");
    context.expect(menu_for("阿碧", [](FakeCharacter& hero) { hero.book().mark_done(15); }), "xong kích hoạt, không giữ nhiệm vụ vòng: có menu");
    context.expect(!menu_for("阿碧", [&](FakeCharacter& hero) {
        hero.book().mark_done(15);
        context.expect(hero.book().add(101, static_cast<std::int32_t>(*own), 0) != nullptr, "nhận được nhiệm vụ vòng của A Bích");
    }), "đang giữ nhiệm vụ vòng của chính NPC: không hiện lại");
    context.expect(menu_for("阿碧", [&](FakeCharacter& hero) {
        hero.book().mark_done(15);
        context.expect(hero.book().add(101, static_cast<std::int32_t>(*other), 0) != nullptr, "nhận được nhiệm vụ vòng của A Châu");
    }), "đang giữ nhiệm vụ vòng của NPC khác: vẫn có menu của NPC này");
    // Tên NPC không có trong bảng sự kiện 200099: Lua gốc lỗi ở đó; hộp thoại vẫn mở và phần còn lại vẫn chạy.
    context.expect(menu_for("无名氏", [](FakeCharacter& hero) { hero.book().mark_done(15); }),
        "tên NPC lạ: hàm sự kiện lỗi bị ngắt nhưng menu riêng vẫn hiện");
}

constexpr std::array kCases{
    Case{.name = "real_script_loads", .body = real_script_loads},
    Case{.name = "every_npc_script_walks", .body = every_npc_script_walks},
    Case{.name = "mission_panels_name_their_quests", .body = mission_panels_name_their_quests},
    Case{.name = "ring_quest_npc_menu", .body = ring_quest_npc_menu},
};

#else

void tables_unavailable(Context& context) {
    static_cast<void>(context);
    std::print("[bỏ qua] dựng không có dev/server/tables/server/talk_blocks.tsv\n");
}

constexpr std::array kCases{Case{.name = "tables_unavailable", .body = tables_unavailable}};

#endif

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
