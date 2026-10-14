// Bảng handler viết tay: khoá sắp tăng và không trùng, audit báo đủ từng loại vấn đề, và bảng đăng ký thật sạch với bảng hội thoại
// thật. Dữ liệu thử là thế giới nhỏ của talk_world.hpp (có điểm vào ok, unsupported và no_dialog).
#include "handlers/registry.hpp"
#include "mission/catalog.hpp"
#include "mission/engine.hpp"
#include "support/talk_data.hpp"
#include "support/talk_world.hpp"
#include "talk/handler.hpp"
#include "talk/script.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <optional>
#include <print>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#ifdef GAME_SERVER_TABLES
#include "ops/ops.hpp"
#include "support/real_tables.hpp"
#include "table/tsv.hpp"
#endif

namespace game::test {
namespace {

struct World {
    mission::Catalog catalog;
    talk::Script script;
};

World make_world() {
    TalkData data;
    talkw::fill(data);
    auto catalog = data.build();
    if (!catalog) {
        std::print(stderr, "danh mục thử không nạp được: {} {}\n", catalog.error().table, catalog.error().detail);
        std::abort();
    }
    auto script = data.build_script(*catalog);
    if (!script) {
        std::print(stderr, "chương trình thử không nạp được: {} {}\n", script.error().table, script.error().detail);
        std::abort();
    }
    return World{.catalog = std::move(*catalog), .script = std::move(*script)};
}

std::optional<mission::Failure> nothing(talk::HandlerContext&) { return std::nullopt; }

bool mentions(const std::vector<handlers::Problem>& problems, std::uint32_t script, std::int32_t num, std::string_view what) {
    return std::ranges::any_of(problems, [&](const handlers::Problem& problem) {
        return problem.script == script && problem.num == num && problem.what.find(what) != std::string::npos;
    });
}

void registry_is_sorted_and_unique(Context& context) {
    const auto specs = handlers::registry();
    for (std::size_t index = 1; index < specs.size(); ++index) {
        context.expect(std::pair{specs[index - 1].script, specs[index - 1].num} < std::pair{specs[index].script, specs[index].num},
            "khoá handler tăng ngặt");
    }
    for (const talk::HandlerSpec& spec : specs) {
        context.expect(spec.run != nullptr && !spec.reason.empty(), "handler có hàm chạy và dòng lý do");
    }
}

void audit_accepts_a_handler_for_an_unsupported_entry(Context& context) {
    const World world = make_world();
    const std::array specs{
        talk::HandlerSpec{.script = talkw::kNpcScript, .num = talkw::kHand, .run = nothing, .reason = "thử: điểm vào chưa trích được"},
        talk::HandlerSpec{.script = talkw::kNpcScript, .num = talkw::kHandRefused, .run = nothing, .reason = "thử: điểm vào không có hội thoại"},
    };
    context.expect(handlers::audit(specs, world.script).empty(), "handler thay điểm vào unsupported hoặc no_dialog là hợp lệ");
}

void audit_reports_every_kind_of_problem(Context& context) {
    const World world = make_world();
    const std::array specs{
        talk::HandlerSpec{.script = talkw::kNpcScript, .num = talkw::kHand, .run = nullptr, .reason = "thử"},
        talk::HandlerSpec{.script = talkw::kNpcScript, .num = talkw::kHand, .run = nothing, .reason = ""},
        talk::HandlerSpec{.script = talkw::kNpcScript, .num = 777, .run = nothing, .reason = "thử: điểm vào không có"},
        talk::HandlerSpec{.script = talkw::kNpcScript, .num = talkw::kPay, .run = nothing, .reason = "thử: đè điểm vào ok"},
    };
    const auto problems = handlers::audit(specs, world.script);
    context.expect(mentions(problems, talkw::kNpcScript, talkw::kHand, "thiếu hàm chạy"), "báo hàm chạy rỗng");
    context.expect(mentions(problems, talkw::kNpcScript, talkw::kHand, "thiếu dòng lý do"), "báo lý do rỗng");
    context.expect(mentions(problems, talkw::kNpcScript, talkw::kHand, "khoá trùng"), "báo khoá trùng");
    context.expect(mentions(problems, talkw::kNpcScript, 777, "không có trong chương trình"), "báo điểm vào không tồn tại");
    context.expect(mentions(problems, talkw::kNpcScript, talkw::kPay, "đè lên điểm vào đã trích được"), "báo đè điểm vào ok");
    context.expect(problems.size() == 5, "không báo thừa");
}

#ifdef GAME_SERVER_TABLES

// Bảng đăng ký thật sạch với bảng hội thoại thật: mỗi handler (nếu có) thay một điểm vào có thật mà bộ trích không dịch được.
void registry_is_clean_on_real_tables(Context& context) {
    const std::array<const char*, 6> names{"talk_blocks", "talk_entries", "talk_npc_roles", "talk_npc_events", "ops_conditions", "ops_effects"};
    std::array<table::Tsv, 6> tables;
    for (std::size_t index = 0; index < names.size(); ++index) {
        auto loaded = read_server_table(names.at(index));
        if (!loaded) {
            std::print("[bỏ qua] chưa có bảng {}: chạy TOOLS/server/lua_extract.py\n", names.at(index));
            return;
        }
        tables.at(index) = std::move(*loaded);
    }
    auto program = ops::Program::load(tables[4], tables[5]);
    context.expect(program.has_value(), "ops::Program nạp bảng thật");
    if (!program) return;
    auto script = talk::Script::load(*program, talk::Tables{.blocks = tables[0], .entries = tables[1], .roles = tables[2], .events = tables[3]});
    context.expect(script.has_value(), "chương trình hội thoại nạp bảng thật");
    if (!script) return;
    const auto problems = handlers::audit(handlers::registry(), *script);
    for (const handlers::Problem& problem : problems) {
        std::print(stderr, "handler {}:{}: {}\n", problem.script, problem.num, problem.what);
    }
    context.expect(problems.empty(), "bảng đăng ký sạch với bảng hội thoại thật");
    std::print("[handlers] {} handler đã đăng ký; {} điểm vào chưa trích được và {} không có hội thoại chờ hệ thống nối vào\n",
        handlers::registry().size(), script->report().unsupported, script->report().no_dialog);
}

#endif

constexpr std::array kCases{
    Case{.name = "registry_is_sorted_and_unique", .body = registry_is_sorted_and_unique},
    Case{.name = "audit_accepts_a_handler_for_an_unsupported_entry", .body = audit_accepts_a_handler_for_an_unsupported_entry},
    Case{.name = "audit_reports_every_kind_of_problem", .body = audit_reports_every_kind_of_problem},
#ifdef GAME_SERVER_TABLES
    Case{.name = "registry_is_clean_on_real_tables", .body = registry_is_clean_on_real_tables},
#endif
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
