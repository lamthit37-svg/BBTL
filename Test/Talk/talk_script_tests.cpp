// Chương trình hội thoại: bảng đi vào máy chủ từ công cụ trích và từ tay người sửa, nên mọi ô sai phải thành lỗi nạp có dòng; và
// ngữ nghĩa của khối (call / ret / goto / branch / begin) quyết định hộp thoại hiện ra đúng hay lệch thầm. Ghim cả hai.
#include "dice/dice.hpp"
#include "ids/ids.hpp"
#include "mission/engine.hpp"
#include "ops/ops.hpp"
#include "support/mission_fakes.hpp"
#include "support/talk_data.hpp"
#include "support/talk_world.hpp"
#include "table/tsv.hpp"
#include "talk/script.hpp"
#include "talk/service.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <expected>
#include <print>
#include <utility>
#include <string>
#include <span>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using talk::LoadError;

constexpr std::string_view kBlockHeader = "block\tseq\tkind\tcond\ta\tb\tc\ttext\targs\n";
constexpr std::string_view kEntryHeader = "script\tnum\tblock\tstatus\treason\n";
constexpr std::string_view kRoleHeader = "script\tpath\tevents\n";
constexpr std::string_view kEventHeader = "script\tseq\tevent\n";

// Nạp thử bốn bảng viết tay trên chương trình điều kiện/hiệu ứng của thế giới thử.
std::expected<talk::Script, talk::LoadFailure> load(std::string_view blocks, std::string_view entries = "", std::string_view roles = "",
    std::string_view events = "") {
    TalkData data;
    talkw::fill(data);
    auto catalog = data.build();
    if (!catalog) std::abort();
    std::array<table::Tsv, 4> tables;
    const std::array<std::pair<std::string_view, std::string_view>, 4> sources{{{kBlockHeader, blocks}, {kEntryHeader, entries},
        {kRoleHeader, roles}, {kEventHeader, events}}};
    for (std::size_t i = 0; i < sources.size(); ++i) {
        auto parsed = table::parse_tsv(std::string(sources[i].first) + std::string(sources[i].second));
        if (!parsed) return std::unexpected(talk::LoadFailure{LoadError::kBadCell, "parse", parsed.error()});
        tables[i] = std::move(*parsed);
    }
    return talk::Script::load(catalog->program(), talk::Tables{tables[0], tables[1], tables[2], tables[3]});
}

bool refuses(const std::expected<talk::Script, talk::LoadFailure>& result, LoadError error, std::string_view table) {
    return !result.has_value() && result.error().error == error && result.error().table == table;
}

void well_formed_tables_load(Context& context) {
    const auto script = load("1\t0\tbegin\t-1\t0\t0\t0\t\t\n1\t1\ttext\t-1\t0\t0\t0\tlua.hello\tplayer,npc\n1\t2\toption\t-1\t7\t3\t4\tlua.pick\t\n"
                             "1\t3\tdispatch\t-1\t0\t0\t0\tlist\t\n2\t0\tbranch\t4\t1\t0\t0\t\t\n2\t1\teffects\t-1\t5\t0\t0\t\t\n",
        "7\t-1\t1\tok\t\n7\t3\t0\tunsupported\tAPI random\n9\t1\t0\tno_dialog\t\n", "7\tobj/a.lua\t1\n", "7\t0\t200100\n");
    context.expect(script.has_value(), "bảng đúng nạp được");
    if (!script) return;
    const std::span<const talk::Step> steps = script->block(1);
    context.expect(steps.size() == 4 && steps[1].text.id == ops::string_id("lua.hello") && steps[1].text.params.size() == 2 &&
                       steps[1].text.params[1].kind == ops::TextParam::Kind::kNpc,
        "dòng chữ: mã chuỗi + tham số");
    context.expect(steps[2].kind == talk::StepKind::kOption && steps[2].a == 7 && steps[2].b == 3 && steps[2].c == 4, "lựa chọn: script, biểu tượng, giá trị");
    context.expect(steps[3].dispatch == talk::DispatchKind::kList, "dispatch");
    context.expect(script->block(2).size() == 2 && script->block(2)[0].kind == talk::StepKind::kBranch && script->block(2)[0].cond == 4,
        "khối thứ hai");
    context.expect(script->block(3).empty() && script->block(0).empty() && script->block(0xFFFFFFFFU).empty(), "khối không có dòng là khối rỗng");
    context.expect(script->entry(7, -1) != nullptr && script->entry(7, -1)->block == 1 && script->entry(7, 3)->reason == "API random" &&
                       script->entry(9, 1)->status == talk::EntryStatus::kNoDialog && script->entry(8, 8) == nullptr,
        "điểm vào");
    context.expect(script->is_npc_script(7) && !script->is_npc_script(9), "script NPC");
    const talk::ScriptReport& report = script->report();
    context.expect(report.blocks == 2 && report.steps == 6 && report.entries == 3 && report.ok == 1 && report.unsupported == 1 &&
                       report.no_dialog == 1 && report.npc_scripts == 1 && report.reasons.size() == 1,
        "báo cáo đếm đủ");
}

void hostile_block_tables_are_refused(Context& context) {
    const std::string b0 = "1\t0\tbegin\t-1\t0\t0\t0\t\t\n";
    context.expect(refuses(load("1\t0\tteleport\t-1\t0\t0\t0\t\t\n"), LoadError::kUnknownWord, "talk_blocks"), "loại bước lạ");
    context.expect(refuses(load(b0 + "1\t2\tbegin\t-1\t0\t0\t0\t\t\n"), LoadError::kBadOrder, "talk_blocks"), "seq nhảy cóc");
    context.expect(refuses(load("1\t1\tbegin\t-1\t0\t0\t0\t\t\n"), LoadError::kBadOrder, "talk_blocks"), "seq không bắt đầu từ 0");
    context.expect(refuses(load("2\t0\tbegin\t-1\t0\t0\t0\t\t\n1\t0\tbegin\t-1\t0\t0\t0\t\t\n"), LoadError::kBadOrder, "talk_blocks"), "khối lùi");
    context.expect(refuses(load("1\t0\tbranch\t99\t1\t0\t0\t\t\n"), LoadError::kBadReference, "talk_blocks"), "điều kiện không có");
    context.expect(refuses(load("1\t0\teffects\t-1\t99\t0\t0\t\t\n"), LoadError::kBadReference, "talk_blocks"), "bộ hiệu ứng không có");
    context.expect(refuses(load("1\t0\tbranch\t-1\t0\t0\t0\t\t\n"), LoadError::kBadReference, "talk_blocks"), "nhánh then phải là khối");
    context.expect(refuses(load("1\t0\tgoto\t-1\t0\t0\t0\t\t\n"), LoadError::kBadReference, "talk_blocks"), "goto khối 0");
    context.expect(refuses(load("1\t0\tcall\t-1\t33554432\t0\t0\t\t\n"), LoadError::kBadReference, "talk_blocks"), "call khối ngoài miền");
    context.expect(refuses(load("1\t0\tdispatch\t-1\t0\t0\t0\twindow\t\n"), LoadError::kUnknownWord, "talk_blocks"), "dispatch lạ");
    context.expect(refuses(load("1\t0\tbonus\t-1\t1\t0\t0\tgold\t\n"), LoadError::kUnknownWord, "talk_blocks"), "bonus lạ");
    context.expect(refuses(load("1\t0\ttext\t-1\t0\t0\t0\tlua.x\tbogus_metric\n"), LoadError::kUnknownWord, "talk_blocks"), "tham số chuỗi lạ");
    context.expect(refuses(load("x\t0\tbegin\t-1\t0\t0\t0\t\t\n"), LoadError::kBadCell, "talk_blocks"), "khối không phải số");
    context.expect(refuses(load("0\t0\tbegin\t-1\t0\t0\t0\t\t\n"), LoadError::kBadCell, "talk_blocks"), "khối 0 không hợp lệ");
    context.expect(refuses(load("1\t0\tbegin\t-1\t0\t0\t999999999999\t\t\n"), LoadError::kBadCell, "talk_blocks"), "số tràn");
    context.expect(refuses(load("1\t4096\tbegin\t-1\t0\t0\t0\t\t\n"), LoadError::kBadCell, "talk_blocks"), "seq ngoài miền");
    context.expect(refuses(load("1\t0\tbegin\t-2\t0\t0\t0\t\t\n"), LoadError::kBadCell, "talk_blocks"), "cond nhỏ hơn -1");
    context.expect(refuses(load("1\t0\tbegin\n"), LoadError::kBadCell, "parse"), "dòng thiếu ô");
}

void hostile_entry_tables_are_refused(Context& context) {
    const std::string blocks = "1\t0\tbegin\t-1\t0\t0\t0\t\t\n";
    context.expect(refuses(load(blocks, "7\t-1\t1\tok\t\n7\t-1\t1\tok\t\n"), LoadError::kDuplicateEntry, "talk_entries"), "điểm vào trùng");
    context.expect(refuses(load(blocks, "7\t-1\t1\tmaybe\t\n"), LoadError::kUnknownWord, "talk_entries"), "trạng thái lạ");
    context.expect(refuses(load(blocks, "7\t-1\t0\tok\t\n"), LoadError::kBadReference, "talk_entries"), "ok mà không có khối");
    context.expect(refuses(load(blocks, "7\t-3000000000\t1\tok\t\n"), LoadError::kBadCell, "talk_entries"), "num ngoài int32");
    context.expect(load(blocks, "7\t-9\t1\tok\t\n").has_value(), "num âm hợp lệ (script thật có GetNumText âm)");
    context.expect(refuses(load(blocks, "-1\t-1\t1\tok\t\n"), LoadError::kBadCell, "talk_entries"), "script âm");
    context.expect(refuses(load(blocks, "", "7\tobj/a.lua\t1\n7\tobj/b.lua\t1\n"), LoadError::kBadReference, "talk_npc_roles"), "script NPC trùng");
    context.expect(refuses(load(blocks, "", "7\t\t1\n"), LoadError::kBadReference, "talk_npc_roles"), "NPC không có đường dẫn");
    context.expect(refuses(load(blocks, "", "7\tobj/a.lua\t1\n", "8\t0\t5\n"), LoadError::kBadReference, "talk_npc_events"), "sự kiện của script NPC không có");
    context.expect(refuses(load(blocks, "", "7\tobj/a.lua\t1\n", "7\tx\t5\n"), LoadError::kBadCell, "talk_npc_events"), "seq sự kiện hỏng");
    const auto unsupported = load(blocks, "7\t-1\t0\tunsupported\t\n");
    context.expect(unsupported.has_value() && unsupported->entry(7, -1)->reason.find("không rõ") != std::string::npos,
        "điểm vào chưa trích được mà không ghi lý do thì vẫn có lý do");
}

// Dữ liệu cho các ca ngữ nghĩa: NPC script 8000 với khối call / ret / goto / branch / begin.
constexpr std::uint32_t kSemanticsScript = 8000;

struct Semantics {
    Semantics() : catalog(make_catalog()), script(make_script(catalog)), dice(1), engine(catalog, dice),
                  service(script, engine, {}, talk::Options{}) {
        hero.level_value = 5;
        npc = talk::NpcRef{static_cast<std::uint32_t>(talkw::kNpcGuid), 3, ops::name_id("老人"), kSemanticsScript};
    }

    static TalkData data() {
        TalkData built;
        talkw::fill(built);
        built.npc_script(kSemanticsScript);
        // Gốc: A, gọi khối 2 (B rồi ret, phần sau ret không hiện), quay lại hiện C.
        built.begin(30).text(30, "lua.A").call(30, 31).text(30, "lua.C").dispatch(30, "list");
        built.text(31, "lua.B").ret(31).text(31, "lua.NEVER");
        built.entry(kSemanticsScript, -1, 30);
        // ret trong nhánh inline thoát cả điểm vào: cấp >= 10 hiện A, T rồi dừng; cấp thấp hiện A, E, Z.
        built.begin(32).text(32, "lua.A").branch(32, talkw::kCondVeteran, 33, 34).text(32, "lua.Z").dispatch(32, "list");
        built.text(33, "lua.T").ret(33);
        built.text(34, "lua.E");
        built.entry(kSemanticsScript, 1, 32);
        // goto là nhảy cuối: phần còn lại của luồng nằm trong khối đích.
        built.begin(35).text(35, "lua.A").branch(35, talkw::kCondVeteran, 36, 37);
        built.text(36, "lua.T").jump(36, 38);
        built.text(37, "lua.E").jump(37, 38);
        built.text(38, "lua.JOINED").dispatch(38, "box");
        built.entry(kSemanticsScript, 2, 35);
        // begin xoá những gì đã dựng; dispatch cuối thắng.
        built.begin(39).text(39, "lua.old").option(39, kSemanticsScript, 1, 5, "lua.oldopt").dispatch(39, "tips").begin(39);
        built.text(39, "lua.new").dispatch(39, "continue");
        built.entry(kSemanticsScript, 3, 39);
        // Điểm vào được tới từ lựa chọn của gốc.
        built.option(30, kSemanticsScript, 1, 1, "lua.go1").option(30, kSemanticsScript, 1, 2, "lua.go2").option(30, kSemanticsScript, 1, 3, "lua.go3");
        return built;
    }

    static mission::Catalog make_catalog() {
        auto built = data().build();
        if (!built) std::abort();
        return std::move(*built);
    }

    static talk::Script make_script(const mission::Catalog& catalog) {
        auto built = data().build_script(catalog);
        if (!built) {
            std::print(stderr, "{}: {}\n", built.error().table, built.error().detail);
            std::abort();
        }
        return std::move(*built);
    }

    std::vector<std::uint32_t> lines_of(const talk::View& view) const {
        std::vector<std::uint32_t> out;
        for (const talk::Line& line : view.lines) out.push_back(line.text.id);
        return out;
    }

    // Mở NPC rồi chọn lựa chọn thứ `which` (1..3) tới điểm vào which của script.
    talk::Result enter(int which) {
        const talk::Result opened = service.talk(hero, npc, place, ids::Tick{1}, calendar);
        if (!opened) return opened;
        for (const talk::Choice& choice : opened->view.choices) {
            if (choice.text.id == talkw::id(which == 1 ? "lua.go1" : which == 2 ? "lua.go2" : "lua.go3")) {
                return service.choose(hero, opened->session, choice.index, place, ids::Tick{1}, calendar);
            }
        }
        return opened;
    }

    mission::Catalog catalog;
    talk::Script script;
    dice::Dice dice;
    mission::Engine engine;
    talk::Service service;
    FakeCharacter hero;
    ops::Calendar calendar;
    FakeTalkWorld place;
    talk::NpcRef npc;
};

void call_and_ret_return_to_the_caller(Context& context) {
    Semantics s;
    const talk::Result opened = s.service.talk(s.hero, s.npc, s.place, ids::Tick{1}, s.calendar);
    context.expect(opened.has_value(), "mở được");
    if (!opened) return;
    const std::vector<std::uint32_t> expected{talkw::id("lua.A"), talkw::id("lua.B"), talkw::id("lua.C")};
    context.expect(s.lines_of(opened->view) == expected, "A, B (trong call), C; phần sau ret của call không hiện");
}

void ret_in_an_inline_branch_leaves_the_entry(Context& context) {
    Semantics low;
    const talk::Result below = low.enter(1);
    context.expect(below.has_value() && low.lines_of(below->view) ==
                       std::vector<std::uint32_t>{talkw::id("lua.A"), talkw::id("lua.E"), talkw::id("lua.Z")},
        "cấp thấp: A, E rồi Z");
    Semantics high;
    high.hero.level_value = 12;
    const talk::Result above = high.enter(1);
    context.expect(above.has_value() && high.lines_of(above->view) == std::vector<std::uint32_t>{talkw::id("lua.A"), talkw::id("lua.T")},
        "cấp cao: A, T rồi ret thoát cả điểm vào, không có Z");
}

void goto_continues_in_the_target(Context& context) {
    for (const std::int32_t level : {5, 12}) {
        Semantics s;
        s.hero.level_value = level;
        const talk::Result joined = s.enter(2);
        context.expect(joined.has_value(), "chạy được");
        if (!joined) continue;
        const std::vector<std::uint32_t> expected{talkw::id("lua.A"), talkw::id(level >= 10 ? "lua.T" : "lua.E"), talkw::id("lua.JOINED")};
        context.expect(s.lines_of(joined->view) == expected, "hai nhánh nhập lại ở khối đích");
        context.expect(joined->view.mode == talk::Mode::kBox, "dispatch ở khối đích");
    }
}

void begin_clears_and_last_dispatch_wins(Context& context) {
    Semantics s;
    const talk::Result result = s.enter(3);
    context.expect(result.has_value(), "chạy được");
    if (!result) return;
    context.expect(s.lines_of(result->view) == std::vector<std::uint32_t>{talkw::id("lua.new")} && result->view.choices.empty(),
        "begin bỏ chữ và lựa chọn đã dựng");
    context.expect(result->view.mode == talk::Mode::kContinue, "dispatch cuối thắng");
}

constexpr std::array kCases{
    Case{.name = "well_formed_tables_load", .body = well_formed_tables_load},
    Case{.name = "hostile_block_tables_are_refused", .body = hostile_block_tables_are_refused},
    Case{.name = "hostile_entry_tables_are_refused", .body = hostile_entry_tables_are_refused},
    Case{.name = "call_and_ret_return_to_the_caller", .body = call_and_ret_return_to_the_caller},
    Case{.name = "ret_in_an_inline_branch_leaves_the_entry", .body = ret_in_an_inline_branch_leaves_the_entry},
    Case{.name = "goto_continues_in_the_target", .body = goto_continues_in_the_target},
    Case{.name = "begin_clears_and_last_dispatch_wins", .body = begin_clears_and_last_dispatch_wins},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
