// Bảng nhiệm vụ (ui/panel/quest_log): bản port để lại đúng trạng thái cửa sổ mà QuestLog.lua của
// client 2026 để lại khi chạy trên LuaPlus.dll gốc (tests/golden/panel/quest_log_newcomer.tsv, sinh
// bằng TOOLS/port/lua_oracle.py với kịch bản TOOLS/port/oracle/quest_log_newcomer.lua), cùng các ca
// biên mà kịch bản không đi tới: loại 153, màu theo hiệu cấp, dịch tên, cảnh không tên.
#include "ui/panel/quest_log.hpp"

#include "core/check.hpp"
#include "gui/strings.hpp"
#include "panel_golden.hpp"
#include "quest/log.hpp"
#include "quest/outline.hpp"
#include "quest/track.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::panel::Call;
using ui::panel::QuestFacts;
using ui::panel::QuestLog;

constexpr std::string_view kGoldenFile = "quest_log_newcomer.tsv";
constexpr std::string_view kList = "QuestLog_Listbox";

// Dữ liệu của kịch bản trọng tài: 199 loại mang tên "Loại <số>", riêng loại 17, và đúng một nhiệm
// vụ nhận được. Tên đã là tiếng Việt như kịch bản, nên không cần bảng dịch.
struct World {
    std::vector<quest::OutlineRow> outline;
    std::vector<quest::KindRow> kinds;
    quest::Log log;
    quest::Tracking tracking;

    [[nodiscard]] QuestFacts facts() {
        QuestFacts facts;
        facts.log = &log;
        facts.outline = outline;
        facts.kinds = kinds;
        facts.tracking = &tracking;
        return facts;
    }
};

// Nhiệm vụ nhận được duy nhất của kịch bản: loại 17, cấp 1.
quest::OutlineRow offer_row() {
    quest::OutlineRow row;
    row.id = 1087;
    row.mission = 1682;
    row.kind = 17;
    row.level = 1;
    row.min_level = 1;
    row.max_level = 31;
    row.scene = 6;
    row.x = 187;
    row.z = 205;
    row.npc = "Sơn Dân Bị Thương";
    row.name = "Duyên Khởi Vô Lượng";
    row.scene_name = "Vô Lượng Sơn";
    return row;
}

World newcomer_world() {
    World world;
    for (std::int32_t kind = 1; kind <= 199; ++kind) {
        world.kinds.push_back(quest::KindRow{.id = kind, .name = std::format("Loại {}", kind)});
    }
    world.kinds.at(16).name = "Vô Lượng Sơn";
    world.outline.push_back(offer_row());
    return world;
}

// Các dòng trạng thái của bảng sau một bước.
std::vector<std::string> lines_of(const QuestLog& panel, std::vector<Call>& calls) {
    return panel_lines(panel.is_shown, panel.widgets, calls);
}

// Một bước của kịch bản trọng tài trên bản port.
using Step = void (*)(QuestLog&, const QuestFacts&, std::vector<Call>&);

void step_toggle(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls) {
    ui::panel::toggle_quest_log(panel, facts, calls);
}

void step_offers_tab(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls) {
    ui::panel::press_quest_log(panel, "QuestLog_AcceptMission", facts, calls);
}

void step_pick_mission(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& /*calls*/) {
    ui::panel::pick_quest_item(panel, 170001, facts);
}

void step_pick_kind(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& /*calls*/) {
    ui::panel::pick_quest_item(panel, 170000, facts);
}

void step_refuse(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls) {
    ui::panel::press_quest_log(panel, "QuestLog_Refuse", facts, calls);
}

void step_modes(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls) {
    ui::panel::press_quest_log(panel, "QuestLog_Mode1", facts, calls);
    ui::panel::press_quest_log(panel, "QuestLog_Mode2", facts, calls);
}

void step_empty_buttons(QuestLog& panel, const QuestFacts& facts, std::vector<Call>& calls) {
    ui::panel::press_quest_log(panel, "QuestLog_Stop", facts, calls);
    ui::panel::press_quest_log(panel, "QuestLog_Refuse", facts, calls);
    ui::panel::press_quest_log(panel, "QuestLog_Close", facts, calls);
}

// Đúng thứ tự các bước của TOOLS/port/oracle/quest_log_newcomer.lua.
constexpr std::array<Step, 9> kScript = {step_toggle, step_offers_tab, step_pick_mission, step_pick_kind,
    step_pick_kind, step_refuse, step_toggle, step_modes, step_empty_buttons};

void port_matches_original_script(Context& context) {
    if (kPanelGolden.empty()) return;
    const std::vector<GoldenBlock> blocks = read_golden(kGoldenFile);
    context.expect(blocks.size() == kScript.size(), "số vàng có đủ chín bước của kịch bản");
    if (blocks.size() != kScript.size()) return;
    World world = newcomer_world();
    const QuestFacts facts = world.facts();
    QuestLog panel;
    std::vector<Call> calls;
    for (std::size_t index = 0; index < kScript.size(); ++index) {
        kScript.at(index)(panel, facts, calls);
        expect_block(context, blocks.at(index), lines_of(panel, calls));
    }
}

bool has_line(std::span<const std::string> lines, std::string_view wanted) {
    return std::ranges::contains(lines, wanted);
}

// Mở thẻ nhận được với facts rồi trả các dòng trạng thái.
std::vector<std::string> offers_of(const QuestFacts& facts) {
    QuestLog panel;
    std::vector<Call> calls;
    ui::panel::toggle_quest_log(panel, facts, calls);
    ui::panel::press_quest_log(panel, "QuestLog_AcceptMission", facts, calls);
    return lines_of(panel, calls);
}

void tracking_state_is_saved(Context& context) {
    World world = newcomer_world();
    QuestLog panel;
    std::vector<Call> calls;
    ui::panel::toggle_quest_log(panel, world.facts(), calls);
    ui::panel::press_quest_log(panel, "QuestLog_Mode1", world.facts(), calls);
    context.expect(world.tracking.shows_missions == false, "tắt khung theo dõi nhiệm vụ được lưu");
    ui::panel::press_quest_log(panel, "QuestLog_Mode2", world.facts(), calls);
    context.expect(world.tracking.shows_campaigns == true, "bật khung theo dõi hoạt động được lưu");
    ui::panel::press_quest_log(panel, "QuestLog_Close", world.facts(), calls);
    ui::panel::toggle_quest_log(panel, world.facts(), calls);
    context.expect(!panel.widgets.is_checked("QuestLog_Mode1"), "mở lại thì ô nhiệm vụ theo trạng thái đã lưu");
    context.expect(panel.widgets.is_checked("QuestLog_Mode2"), "mở lại thì ô hoạt động theo trạng thái đã lưu");
}

void wanderer_kind_needs_flag(Context& context) {
    World world = newcomer_world();
    world.outline.push_back(offer_row());
    world.outline.back().kind = 153;
    world.outline.back().mission = 2000;
    QuestFacts facts = world.facts();
    std::vector<std::string> lines = offers_of(facts);
    context.expect(has_line(lines, "QuestLog_Listbox\tItems\t2"), "loại 153 bị bỏ khi không có cờ");
    facts.is_wanderer = true;
    lines = offers_of(facts);
    context.expect(has_line(lines, "QuestLog_Listbox\tItems\t4"), "có cờ thì loại 153 hiện");
    context.expect(has_line(lines, "QuestLog_Listbox\tItem3\t1530000\t\t#gFE7E82- Loại 153"), "dòng tên loại 153");
}

// Màu của mục theo hiệu cấp nhiệm vụ trừ cấp người chơi, ở từng mốc của script.
struct ColourCase {
    std::int32_t mission_level = 0;
    std::string_view colour;
};

constexpr std::array<ColourCase, 9> kColours = {{
    {.mission_level = 8, .colour = "FFB9B9B9"},
    {.mission_level = 9, .colour = "FF0A9605"},
    {.mission_level = 14, .colour = "FF0A9605"},
    {.mission_level = 15, .colour = "FFD9F80A"},
    {.mission_level = 20, .colour = "FFD9F80A"},
    {.mission_level = 25, .colour = "FFD9F80A"},
    {.mission_level = 26, .colour = "FFF8A10A"},
    {.mission_level = 30, .colour = "FFF8A10A"},
    {.mission_level = 31, .colour = "FFFA0A0A"},
}};

void colour_follows_level_gap(Context& context) {
    for (const ColourCase& item : kColours) {
        World world = newcomer_world();
        world.outline.front().level = item.mission_level;
        QuestFacts facts = world.facts();
        facts.seeker.level = 20;
        const std::vector<std::string> lines = offers_of(facts);
        const std::string wanted = std::format(
            "QuestLog_Listbox\tItem2\t170001\t{}\t    {} Duyên Khởi Vô Lượng", item.colour, item.mission_level);
        context.expect(has_line(lines, wanted), wanted);
    }
}

void level_any_shows_own_level(Context& context) {
    World world = newcomer_world();
    world.outline.front().level = quest::kAny;
    QuestFacts facts = world.facts();
    facts.seeker.level = 7;
    const std::vector<std::string> lines = offers_of(facts);
    const bool is_own = has_line(lines, "QuestLog_Listbox\tItem2\t170001\tFFD9F80A\t    7 Duyên Khởi Vô Lượng");
    context.expect(is_own, "cấp -1 của bảng hiện cấp người chơi, màu vàng");
}

gui::StringBook book_of(std::string_view text) {
    const table::TsvResult table = table::parse_tsv(text);
    core::check(table.has_value(), "bảng chuỗi mẫu phải đọc được");
    return gui::StringBook::from_table(*table);
}

void names_are_translated(Context& context) {
    World world = newcomer_world();
    world.kinds.at(16).name = "无量山";
    world.outline.front().name = "缘起无量";
    world.outline.front().npc = "受伤的山民";
    world.outline.front().scene_name = "无量山";
    const gui::StringBook words = book_of("key\ttext\n=无量山\tVô Lượng Sơn\n=缘起无量\tDuyên Khởi\n=受伤的山民\tSơn Dân\n");
    const gui::StringBook scenes = book_of("key\ttext\n无量山\tNúi Vô Lượng\n");
    QuestFacts facts = world.facts();
    facts.words = &words;
    facts.scenes = &scenes;
    QuestLog panel;
    std::vector<Call> calls;
    ui::panel::toggle_quest_log(panel, facts, calls);
    ui::panel::press_quest_log(panel, "QuestLog_AcceptMission", facts, calls);
    ui::panel::pick_quest_item(panel, 170001, facts);
    const std::vector<std::string> lines = lines_of(panel, calls);
    context.expect(has_line(lines, "QuestLog_Listbox\tItem1\t170000\t\t#gFE7E82- Vô Lượng Sơn"), "tên loại đã dịch");
    context.expect(has_line(lines, "QuestLog_Listbox\tItem2\t170001\tFFD9F80A\t    1 Duyên Khởi"), "tên nhiệm vụ đã dịch");
    context.expect(has_line(lines, "QuestLog_Desc\tElement1\ttext\t#YDuyên Khởi#W"), "tên trong ô mô tả");
    const std::string_view place = "QuestLog_Desc\tElement2\ttext\tNơi nhận: Núi Vô Lượng  #{_INFOAIM187,205,6,Sơn Dân}";
    context.expect(has_line(lines, place), "tên cảnh lấy ở bảng tên cảnh, NPC đã dịch trong liên kết");
    context.expect(has_line(lines, "QuestLog_Desc\tElement3\ttext\tNgười giao: Sơn Dân"), "người giao đã dịch");
}

void scene_without_name_drops_place_line(Context& context) {
    World world = newcomer_world();
    world.outline.front().scene_name.clear();
    QuestLog panel;
    std::vector<Call> calls;
    ui::panel::toggle_quest_log(panel, world.facts(), calls);
    ui::panel::press_quest_log(panel, "QuestLog_AcceptMission", world.facts(), calls);
    ui::panel::pick_quest_item(panel, 170001, world.facts());
    const std::vector<std::string> lines = lines_of(panel, calls);
    context.expect(has_line(lines, "QuestLog_Desc\tElements\t3"), "cảnh không tên thì chỉ còn ba dòng");
    context.expect(has_line(lines, "QuestLog_Desc\tElement2\ttext\tNgười giao: Sơn Dân Bị Thương"), "dòng hai là người giao");
}

void stray_picks_only_clear_description(Context& context) {
    World world = newcomer_world();
    QuestLog panel;
    std::vector<Call> calls;
    ui::panel::toggle_quest_log(panel, world.facts(), calls);
    ui::panel::press_quest_log(panel, "QuestLog_AcceptMission", world.facts(), calls);
    ui::panel::pick_quest_item(panel, 170001, world.facts());
    for (const std::int32_t id : {-1, 0, 170002, 2010000, 2000000000}) {
        ui::panel::pick_quest_item(panel, id, world.facts());
        const std::vector<std::string> lines = lines_of(panel, calls);
        context.expect(has_line(lines, "QuestLog_Desc\tElements\t0"), "id lạ chỉ xoá ô mô tả");
        context.expect(has_line(lines, "QuestLog_Listbox\tItems\t2"), "danh sách giữ nguyên");
    }
}

void buttons_ask_the_game(Context& context) {
    World world = newcomer_world();
    QuestLog panel;
    std::vector<Call> calls;
    ui::panel::press_quest_log(panel, "QuestLog_huodongricheng", world.facts(), calls);
    ui::panel::press_quest_log(panel, "QuestLog_Help", world.facts(), calls);
    ui::panel::press_quest_log(panel, "QuestLog_Icon", world.facts(), calls);
    context.expect(calls.size() == 2, "hai nút nhờ game, cửa sổ lạ không làm gì");
    if (calls.size() != 2) return;
    context.expect(calls[0].ask == ui::panel::Ask::kOpenCampaignList, "nút lịch hoạt động");
    context.expect(calls[1].ask == ui::panel::Ask::kGotoHelper && calls[1].text == "*QuestLog", "nút trợ giúp");
}

void paint_only_when_shown(Context& context) {
    World world = newcomer_world();
    QuestLog panel;
    std::vector<Call> calls;
    ui::panel::Deck deck;
    ui::panel::paint_quest_log(deck, panel);
    context.expect(deck.overrides().empty(), "bảng chưa mở thì không ghi gì");
    ui::panel::toggle_quest_log(panel, world.facts(), calls);
    ui::panel::paint_quest_log(deck, panel);
    context.expect(!deck.overrides().empty(), "bảng đang mở thì chép trạng thái sang deck");
    const QuestFacts bare;
    QuestLog lonely;
    ui::panel::toggle_quest_log(lonely, bare, calls);
    ui::panel::press_quest_log(lonely, "QuestLog_AcceptMission", bare, calls);
    ui::panel::press_quest_log(lonely, "QuestLog_Mode1", bare, calls);
    context.expect(lonely.widgets.selected_item(kList) == ui::panel::kNoItem, "không có dữ liệu thì danh sách rỗng");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "tracking_state_is_saved", .body = &tracking_state_is_saved},
    Case{.name = "wanderer_kind_needs_flag", .body = &wanderer_kind_needs_flag},
    Case{.name = "colour_follows_level_gap", .body = &colour_follows_level_gap},
    Case{.name = "level_any_shows_own_level", .body = &level_any_shows_own_level},
    Case{.name = "names_are_translated", .body = &names_are_translated},
    Case{.name = "scene_without_name_drops_place_line", .body = &scene_without_name_drops_place_line},
    Case{.name = "stray_picks_only_clear_description", .body = &stray_picks_only_clear_description},
    Case{.name = "buttons_ask_the_game", .body = &buttons_ask_the_game},
    Case{.name = "paint_only_when_shown", .body = &paint_only_when_shown},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_quest_tests: mọi ca phải qua");
    return 0;
}
