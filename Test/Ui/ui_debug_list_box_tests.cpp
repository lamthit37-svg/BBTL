// Danh sách lời nhắn gỡ lỗi (ui/panel/debug_list_box): bản port để lại đúng trạng thái cửa sổ mà DebugListBox.lua của
// client 2026 để lại khi chạy trên LuaPlus.dll gốc (Test/golden/panel/debug_list_box_flow.tsv, sinh bằng
// TOOLS/port/lua_oracle.py với kịch bản TOOLS/port/oracle/debug_list_box_flow.lua), cùng nhịp tuổi thọ và mờ dần của
// FalagardInfoList (đọc từ mã máy) và các ca biên.
#include "ui/panel/debug_list_box.hpp"

#include "core/check.hpp"
#include "gui/sheet.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/data_pool.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <format>
#include <initializer_list>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::panel::DebugListBox;
using ui::panel::UiColour;

constexpr std::string_view kFlowFile = "debug_list_box_flow.tsv";
constexpr std::string_view kDefaultStyle = "#c00FFFF#e010101";

// Bảng cùng kho arg<k> dùng chung mà bộ gửi sự kiện giữ giữa hai sự kiện. GetUIColor(1000) của 3.71.9509 trả "-1".
struct Rig {
    DebugListBox panel;
    ui::panel::EventArgs args;

    void raise(std::string_view name, std::initializer_list<std::string_view> given = {}) {
        const std::vector<std::string_view> list(given);
        ui::panel::debug_list_box_event(panel, args.raise(name, list), ui::panel::kUiColourMissing);
    }
    void message(std::string_view text) { raise("NEW_DEBUGMESSAGE", {text}); }
    [[nodiscard]] std::vector<std::string> lines() const {
        std::vector<ui::panel::Call> none;
        return panel_lines(panel.is_shown, panel.widgets, none);
    }
    [[nodiscard]] std::vector<std::string> texts() const {
        std::vector<std::string> out;
        out.reserve(panel.lines.size());
        for (const ui::panel::InfoLine& line : panel.lines) out.push_back(line.text);
        return out;
    }
};

// Đúng thứ tự các bước của TOOLS/port/oracle/debug_list_box_flow.lua.
using Step = void (*)(Rig&);

void step_inited(Rig& rig) {
    rig.raise("APPLICATION_INITED");
}
void step_one(Rig& rig) {
    rig.message("Bạn chưa có bang hội");
}
void step_five(Rig& rig) {
    for (const std::string_view text : {"Dòng hai", "Dòng ba", "Dòng bốn", "Dòng năm"}) rig.message(text);
}
void step_seven(Rig& rig) {
    rig.message("Dòng sáu");
    rig.message("Dòng bảy");
}
void step_400_bytes(Rig& rig) {
    rig.message(std::string(400, 'a'));
}
void step_401_bytes(Rig& rig) {
    rig.message(std::string(401, 'b'));
}
void step_cut_two_byte(Rig& rig) {
    rig.message(std::string(399, 'c') + "ă");
}
void step_cut_three_byte(Rig& rig) {
    rig.message(std::string(399, 'd') + "ế");
}
void step_whole_two_byte(Rig& rig) {
    std::string text;
    for (int count = 0; count < 200; ++count) text += "đ";
    rig.message(text + "e");
}

constexpr std::array<Step, 10> kScript = {step_inited, step_one, step_five, step_seven, step_400_bytes, step_401_bytes,
    step_cut_two_byte, step_cut_three_byte, step_whole_two_byte, step_inited};

void port_matches_original_script(Context& context) {
    if (kPanelGolden.empty()) return;
    const std::vector<GoldenBlock> blocks = read_golden(kFlowFile);
    context.expect(blocks.size() == kScript.size() + 1, "số vàng có khối sự kiện và đủ các bước của kịch bản");
    if (blocks.size() != kScript.size() + 1) return;
    std::vector<std::string> events;
    events.reserve(ui::panel::kDebugListBoxEvents.size());
    for (const ui::panel::EventSub& one : ui::panel::kDebugListBoxEvents) {
        events.push_back(std::format("event\t{}\t{}", one.name, one.is_always ? "True" : "False"));
    }
    expect_block(context, blocks.front(), events);
    Rig rig;
    std::size_t index = 1;
    for (const Step step : kScript) {
        step(rig);
        expect_block(context, blocks.at(index++), rig.lines());
    }
}

// Khác gốc: script chỉ lùi một byte khi 400 byte đầu kết thúc giữa một ký tự (đúng với GBK hai byte), nên với "ế" (ba
// byte) nó giữ lại byte đầu của ký tự bị chẻ; bản này lùi tới đầu ký tự.
void cut_never_splits_a_character(Context& context) {
    Rig rig;
    rig.message(std::string(398, 'a') + "ế");
    context.expect(rig.texts() == std::vector<std::string>{std::string(kDefaultStyle) + std::string(398, 'a')},
        "ký tự ba byte bị cắt thì bỏ cả ký tự");
    Rig four;
    four.message(std::string(397, 'a') + "😀");
    context.expect(four.texts() == std::vector<std::string>{std::string(kDefaultStyle) + std::string(397, 'a')},
        "ký tự bốn byte bị cắt thì bỏ cả ký tự");
    Rig exact;
    exact.message(std::string(397, 'a') + "ế");
    context.expect(exact.texts() == std::vector<std::string>{std::string(kDefaultStyle) + std::string(397, 'a') + "ế"},
        "ký tự nằm trọn trong 400 byte thì giữ");
}

// Script gọi Show rồi lỗi ở string.len khi arg0 còn nil: bảng hiện, danh sách không đổi.
void nil_message_only_shows(Context& context) {
    DebugListBox panel;
    ui::panel::debug_list_box_update(panel, std::nullopt, ui::panel::kUiColourMissing);
    context.expect(panel.is_shown && panel.lines.empty(), "arg0 nil thì chỉ hiện bảng");
    Rig rig;
    rig.raise("NEW_DEBUGMESSAGE");
    context.expect(rig.panel.is_shown && rig.panel.lines.empty(), "sự kiện không kèm đối số cũng vậy");
    rig.raise("NEW_DEBUGMESSAGE", {"x"});
    rig.raise("NEW_DEBUGMESSAGE");
    context.expect(rig.texts() == std::vector<std::string>{std::string(kDefaultStyle) + "x", std::string(kDefaultStyle) + "x"},
        "arg0 là kho dùng chung nên sự kiện sau lấy lại chữ của sự kiện trước");
}

// Màu từ GetUIColor dùng nguyên văn; "-1" ở phía nào thì phía đó theo mặc định.
void colours_follow_the_script(Context& context) {
    DebugListBox panel;
    ui::panel::debug_list_box_update(panel, "a", UiColour{.font = "FF0000", .extent = "00FF00"});
    ui::panel::debug_list_box_update(panel, "b", UiColour{.font = "-1", .extent = "123456"});
    ui::panel::debug_list_box_update(panel, "c", UiColour{.font = "ABCDEF", .extent = "-1"});
    const std::vector<std::string> wanted = {"#cFF0000#e00FF00a", "#c00FFFF#e123456b", "#cABCDEF#e010101c"};
    context.expect(panel.lines.size() == wanted.size(), "ba lời nhắn");
    for (std::size_t index = 0; index < wanted.size() && index < panel.lines.size(); ++index) {
        context.expect(panel.lines[index].text == wanted[index], "màu của lời nhắn thứ " + std::to_string(index + 1));
    }
}

[[nodiscard]] bool near(float left, float right) noexcept {
    return std::abs(left - right) < 1e-4F;
}

// FalagardInfoList::updateSelf: trừ tuổi thọ; âm thì giảm độ trong FadeSpeed/255 mỗi giây; độ trong âm thì bỏ mục, và
// mục kế dồn vào chỗ vừa bỏ bị bỏ qua tới nhịp sau.
void ticks_follow_info_list(Context& context) {
    Rig rig;
    rig.message("một");
    rig.message("hai");
    ui::panel::debug_list_box_tick(rig.panel, 5.0F);
    context.expect(rig.panel.lines.size() == 2 && rig.panel.lines[0].life_ms == 0 && rig.panel.lines[1].life_ms == 0,
        "hết đúng 5 giây thì tuổi thọ 0 và chưa mờ");
    context.expect(near(rig.panel.lines[0].alpha, 1.0F), "tuổi thọ 0 chưa giảm độ trong");
    ui::panel::debug_list_box_tick(rig.panel, 0.5F);
    context.expect(rig.panel.lines[0].life_ms == -500 && near(rig.panel.lines[0].alpha, 1.0F - 128.0F * 0.5F / 255.0F),
        "âm tuổi thọ thì mờ theo FadeSpeed");
    ui::panel::debug_list_box_tick(rig.panel, 2.0F);
    context.expect(rig.panel.lines.size() == 1 && rig.panel.lines[0].text.ends_with("hai"),
        "mục đầu hết độ trong thì bỏ");
    context.expect(rig.panel.lines[0].life_ms == -500, "mục dồn lên bị bỏ qua ở nhịp đó");
    context.expect(rig.panel.widgets.item_id(ui::panel::kDebugListBoxList, 0).has_value() &&
                       !rig.panel.widgets.item_id(ui::panel::kDebugListBoxList, 1).has_value(),
        "danh sách của Widgets theo kịp");
    ui::panel::debug_list_box_tick(rig.panel, 2.0F);
    context.expect(rig.panel.lines.empty(), "nhịp sau bỏ nốt");
    context.expect(rig.panel.is_shown, "danh sách rỗng bảng vẫn hiện (script không giấu)");
    ui::panel::debug_list_box_tick(rig.panel, 1.0F);
    ui::panel::debug_list_box_tick(rig.panel, -1.0F);
    context.expect(rig.panel.lines.empty(), "nhịp lên danh sách rỗng hay thời gian âm không làm gì");
}

// Thời gian âm, vô hạn hay quá lớn không làm tuổi thọ tràn số.
void tick_survives_extreme_time(Context& context) {
    Rig rig;
    rig.message("x");
    ui::panel::debug_list_box_tick(rig.panel, -3.0F);
    context.expect(rig.panel.lines.size() == 1 && rig.panel.lines[0].life_ms == 5000, "thời gian âm tính là 0");
    ui::panel::debug_list_box_tick(rig.panel, std::numeric_limits<float>::quiet_NaN());
    context.expect(rig.panel.lines.size() == 1 && rig.panel.lines[0].life_ms == 5000, "NaN tính là 0");
    ui::panel::debug_list_box_tick(rig.panel, 4.0F);
    ui::panel::debug_list_box_tick(rig.panel, 1e30F);
    context.expect(rig.panel.lines.empty(), "thời gian cực lớn hết tuổi thọ và độ trong mà không tràn số");
    rig.message("y");
    ui::panel::debug_list_box_tick(rig.panel, std::numeric_limits<float>::infinity());
    context.expect(rig.panel.lines.empty(), "vô hạn cũng vậy");
}

// Sự kiện đăng ký cờ true tới cả lúc bảng đang ẩn.
void delivery_follows_subscription(Context& context) {
    const std::span<const ui::panel::EventSub> subs = ui::panel::kDebugListBoxEvents;
    context.expect(ui::panel::is_delivered(subs, "APPLICATION_INITED", false), "APPLICATION_INITED nhận cả lúc ẩn");
    context.expect(ui::panel::is_delivered(subs, "NEW_DEBUGMESSAGE", false), "NEW_DEBUGMESSAGE nhận cả lúc ẩn");
    context.expect(!ui::panel::is_delivered(subs, "PROGRESSBAR_SHOW", true), "sự kiện chưa đăng ký không tới");
    Rig rig;
    rig.raise("PROGRESSBAR_SHOW", {"x"});
    context.expect(!rig.panel.is_shown && rig.panel.lines.empty(), "sự kiện lạ không đổi gì");
}

void paint_only_when_shown(Context& context) {
    Rig rig;
    ui::panel::Deck deck;
    ui::panel::paint_debug_list_box(deck, rig.panel);
    context.expect(deck.roots().empty() && deck.overrides().empty(), "bảng chưa hiện thì không ghi gì");
    rig.raise("APPLICATION_INITED");
    ui::panel::paint_debug_list_box(deck, rig.panel);
    context.expect(deck.is_shown(ui::panel::kDebugListBoxRoot), "bảng đang hiện thì kê gốc");
    rig.message("A");
    rig.message("B");
    ui::panel::Deck second;
    ui::panel::paint_debug_list_box(second, rig.panel);
    const std::string wanted = std::format("{0}A\n{0}B", kDefaultStyle);
    bool has_text = false;
    for (const gui::Override& said : second.overrides()) {
        has_text = has_text || (said.window == ui::panel::kDebugListBoxList && said.name == "Text" && said.value == wanted);
    }
    context.expect(has_text, "các mục thành một khối chữ, mỗi mục một dòng");
}

// Check_StringCode: ký tự điều khiển ngoài tab, xuống dòng, về đầu dòng, hay dãy UTF-8 sai thì false.
void check_string_code_cases(Context& context) {
    using ui::panel::check_string_code;
    context.expect(check_string_code(""), "rỗng hợp lệ");
    context.expect(check_string_code("abc xyz"), "ASCII hợp lệ");
    context.expect(check_string_code("a\tb\nc\rd"), "tab, xuống dòng, về đầu dòng được phép");
    context.expect(!check_string_code(std::string_view("a\x01" "b", 3)), "ký tự điều khiển 0x01 bị từ chối");
    context.expect(!check_string_code(std::string_view("a\0b", 3)), "byte 0 bị từ chối");
    context.expect(check_string_code("Bạn chưa có bang hội"), "tiếng Việt hợp lệ");
    context.expect(check_string_code("ế😀"), "ký tự ba và bốn byte hợp lệ");
    context.expect(!check_string_code(std::string_view("ế").substr(0, 2)), "ký tự ba byte bị cắt dở");
    context.expect(!check_string_code(std::string_view("ă").substr(0, 1)), "ký tự hai byte bị cắt dở");
    context.expect(!check_string_code("\xFF"), "byte 0xFF không phải UTF-8");
    context.expect(!check_string_code("\x80"), "byte đuôi đứng một mình");
    context.expect(!check_string_code("\xC0\x80"), "dãy dài hơn mức tối thiểu bị từ chối");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "cut_never_splits_a_character", .body = &cut_never_splits_a_character},
    Case{.name = "nil_message_only_shows", .body = &nil_message_only_shows},
    Case{.name = "colours_follow_the_script", .body = &colours_follow_the_script},
    Case{.name = "ticks_follow_info_list", .body = &ticks_follow_info_list},
    Case{.name = "tick_survives_extreme_time", .body = &tick_survives_extreme_time},
    Case{.name = "delivery_follows_subscription", .body = &delivery_follows_subscription},
    Case{.name = "paint_only_when_shown", .body = &paint_only_when_shown},
    Case{.name = "check_string_code_cases", .body = &check_string_code_cases},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_debug_list_box_tests: mọi ca phải qua");
    return 0;
}
