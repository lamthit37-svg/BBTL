// Thanh tiến trình (ui/panel/progress_bar): bản port để lại đúng trạng thái cửa sổ mà ProgressBar.lua của
// client 2026 để lại khi chạy trên LuaPlus.dll gốc (Test/golden/panel/progress_bar_flow.tsv, sinh bằng
// TOOLS/port/lua_oracle.py với kịch bản TOOLS/port/oracle/progress_bar_flow.lua), cùng phần mờ dần mà
// script không có (đọc từ mã máy) và các ca biên.
#include "ui/panel/progress_bar.hpp"

#include "core/check.hpp"
#include "gui/sheet.hpp"
#include "panel_golden.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <cstddef>
#include <format>
#include <initializer_list>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::panel::ProgressBar;

constexpr std::string_view kFlowFile = "progress_bar_flow.tsv";

// Bảng cùng kho arg<k> dùng chung mà bộ gửi sự kiện giữ giữa hai sự kiện.
struct Rig {
    ProgressBar panel;
    ui::panel::EventArgs args;

    void raise(std::string_view name, std::initializer_list<std::string_view> given = {}) {
        const std::vector<std::string_view> list(given);
        ui::panel::progress_bar_event(panel, args.raise(name, list));
    }
    [[nodiscard]] std::vector<std::string> lines() const {
        std::vector<ui::panel::Call> none;
        return panel_lines(panel.is_shown, panel.widgets, none);
    }
};

// Đúng thứ tự các bước của TOOLS/port/oracle/progress_bar_flow.lua.
using Step = void (*)(Rig&);

void step_show(Rig& rig) {
    rig.raise("PROGRESSBAR_SHOW", {"Đang luyện công"});
}
void step_width_quarter(Rig& rig) {
    rig.raise("PROGRESSBAR_WIDTH", {"0.25"});
}
void step_width_exponent(Rig& rig) {
    rig.raise("PROGRESSBAR_WIDTH", {" 1e-1 "});
}
void step_width_d_exponent(Rig& rig) {
    rig.raise("PROGRESSBAR_WIDTH", {"5d-1"});
}
void step_width_over(Rig& rig) {
    rig.raise("PROGRESSBAR_WIDTH", {"7"});
}
void step_hide(Rig& rig) {
    rig.raise("PROGRESSBAR_HIDE");
}
void step_show_again(Rig& rig) {
    rig.raise("PROGRESSBAR_SHOW", {"Lần hai"});
}
void step_break(Rig& rig) {
    rig.raise("PROGRESSBAR_BREAK");
}
void step_leave_world(Rig& rig) {
    rig.raise("PROGRESSBAR_SHOW", {"Lần ba"});
    rig.raise("PLAYER_LEAVE_WORLD");
}
void step_scene_transed(Rig& rig) {
    rig.raise("HIDE_ON_SCENE_TRANSED");
}
void step_close(Rig& rig) {
    ui::panel::progress_bar_close(rig.panel);
}

constexpr std::array<Step, 11> kScript = {step_show, step_width_quarter, step_width_exponent, step_width_d_exponent,
    step_width_over, step_hide, step_show_again, step_break, step_leave_world, step_scene_transed, step_close};

void port_matches_original_script(Context& context) {
    if (kPanelGolden.empty()) return;
    const std::vector<GoldenBlock> blocks = read_golden(kFlowFile);
    context.expect(blocks.size() == kScript.size() + 1, "số vàng có khối sự kiện và đủ các bước của kịch bản");
    if (blocks.size() != kScript.size() + 1) return;
    std::vector<std::string> events;
    events.reserve(ui::panel::kProgressBarEvents.size());
    for (const ui::panel::EventSub& one : ui::panel::kProgressBarEvents) {
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

// Giá trị không phải số, hay chưa có arg0, thì thanh giữ nguyên (script gốc ném lỗi ở phép nhân).
void bad_width_changes_nothing(Context& context) {
    Rig fresh;
    fresh.raise("PROGRESSBAR_WIDTH");
    context.expect(!fresh.panel.widgets.progress("ProgressBar_Progress").has_value(), "arg0 còn nil thì bỏ qua");
    Rig rig;
    rig.raise("PROGRESSBAR_SHOW", {"x"});
    const std::vector<std::string> before = rig.lines();
    for (const std::string_view text : {"", "abc", "0x1", "1e", "nan", "inf"}) {
        rig.raise("PROGRESSBAR_WIDTH", {text});
    }
    context.expect(rig.lines() == before, "arg0 không phải số thì không đổi gì");
    context.expect(!rig.panel.widgets.progress("ProgressBar_Progress").has_value(), "chưa có mức nào");
}

// Mức thanh được kẹp vào 0..1; mẫu bằng 0 không làm mức hỏng.
void progress_is_clamped(Context& context) {
    ProgressBar panel;
    const auto level_after = [&panel](std::string_view text) {
        ui::panel::progress_bar_set_width(panel, text);
        return panel.widgets.progress("ProgressBar_Progress");
    };
    context.expect(level_after("0.5") == std::optional<float>(0.5F), "0,5 giữ nguyên");
    context.expect(level_after("7") == std::optional<float>(1.0F), "lớn hơn 1 thành 1");
    context.expect(level_after("-3") == std::optional<float>(0.0F), "nhỏ hơn 0 thành 0");
    context.expect(level_after("1e999") == std::optional<float>(1.0F), "vô cực thành 1");
    context.expect(level_after("-1e999") == std::optional<float>(0.0F), "âm vô cực thành 0");
    panel.widgets.set_progress("ProgressBar_Progress", 0.0, 0.0);
    context.expect(panel.widgets.progress("ProgressBar_Progress") == std::optional<float>(0.0F), "0 trên 0 thành 0");
    panel.widgets.set_progress("ProgressBar_Progress", 3.0, 0.0);
    context.expect(panel.widgets.progress("ProgressBar_Progress") == std::optional<float>(1.0F), "dương trên 0 thành 1");
    panel.widgets.set_progress("ProgressBar_Progress", 3.0, -0.0);
    context.expect(panel.widgets.progress("ProgressBar_Progress") == std::optional<float>(0.0F), "dương trên -0 thành 0");
}

// FalagardSuperProgress::updateSelf: mờ dần hai giây rồi giấu; SHOW hiện lại; thanh không mờ thì không đổi.
void fade_follows_super_progress(Context& context) {
    Rig rig;
    ProgressBar& panel = rig.panel;
    ui::panel::progress_bar_fade(panel, 5.0F);
    context.expect(!panel.is_shown && !panel.is_fading, "chưa mờ dần thì nhịp không làm gì");
    rig.raise("PROGRESSBAR_SHOW", {"x"});
    ui::panel::progress_bar_fade(panel, 5.0F);
    context.expect(panel.is_shown, "thanh đang hiện bình thường không mờ");
    rig.raise("PROGRESSBAR_BREAK");
    context.expect(panel.is_fading && panel.fade_total == 2.0F && panel.fade_left == 2.0F, "ngắt mở mờ dần hai giây");
    ui::panel::progress_bar_fade(panel, 1.0F);
    context.expect(panel.is_shown && panel.fade_left == 1.0F, "giữa chừng vẫn hiện");
    ui::panel::progress_bar_fade(panel, 1.0F);
    context.expect(panel.is_shown && panel.fade_left == 0.0F, "còn đúng 0 thì chưa giấu (so sánh nhỏ hơn)");
    ui::panel::progress_bar_fade(panel, 0.5F);
    context.expect(!panel.is_shown && panel.widgets.is_hidden("ProgressBar_Progress"), "hết thời gian thì giấu");
    ui::panel::progress_bar_fade(panel, 0.5F);
    context.expect(!panel.is_shown, "đã giấu thì nhịp sau không làm gì");
    rig.raise("PROGRESSBAR_SHOW", {"y"});
    context.expect(panel.is_shown && !panel.is_fading && !panel.widgets.is_hidden("ProgressBar_Progress"), "SHOW hiện lại");
}

// arg0 là kho dùng chung và không bị xoá giữa hai sự kiện: SHOW không kèm đối số lấy arg0 của sự kiện trước;
// chưa sự kiện nào đặt arg0 thì giữ chữ cũ của thanh.
void show_without_text_uses_shared_arg0(Context& context) {
    Rig rig;
    rig.raise("PROGRESSBAR_SHOW");
    context.expect(!rig.panel.widgets.value({.window = "ProgressBar_Progress", .name = "Text"}).has_value(),
        "arg0 còn nil thì không đặt chữ");
    rig.raise("PROGRESSBAR_WIDTH", {"0.5"});
    rig.raise("PROGRESSBAR_SHOW");
    context.expect(rig.panel.widgets.value({.window = "ProgressBar_Progress", .name = "Text"}) == "0.5",
        "arg0 của sự kiện trước là chữ của thanh");
}

// Sự kiện đăng ký cờ false chỉ tới khi bảng đang hiện.
void delivery_follows_subscription(Context& context) {
    const std::span<const ui::panel::EventSub> subs = ui::panel::kProgressBarEvents;
    context.expect(ui::panel::is_delivered(subs, "PROGRESSBAR_SHOW", false), "SHOW nhận cả lúc ẩn");
    context.expect(!ui::panel::is_delivered(subs, "PROGRESSBAR_WIDTH", false), "WIDTH không nhận lúc ẩn");
    context.expect(ui::panel::is_delivered(subs, "PROGRESSBAR_WIDTH", true), "WIDTH nhận lúc hiện");
    context.expect(!ui::panel::is_delivered(subs, "CHAT_MESSAGE", true), "sự kiện chưa đăng ký không tới");
}

void paint_only_when_shown(Context& context) {
    Rig rig;
    ui::panel::Deck deck;
    ui::panel::paint_progress_bar(deck, rig.panel);
    context.expect(deck.roots().empty() && deck.overrides().empty(), "bảng chưa hiện thì không ghi gì");
    rig.raise("PROGRESSBAR_SHOW", {"x"});
    ui::panel::progress_bar_set_width(rig.panel, "0.5");
    ui::panel::paint_progress_bar(deck, rig.panel);
    context.expect(deck.is_shown("ProgressBar_Progress"), "bảng đang hiện thì kê gốc");
    context.expect(deck.bars().size() == 1 && deck.bars().front().amount == 0.5F, "mức thanh sang deck");
    bool has_text = false;
    for (const gui::Override& said : deck.overrides()) {
        has_text = has_text || (said.name == "Text" && said.value == "x");
    }
    context.expect(has_text, "chữ sang deck");
}

constexpr std::array kCases{
    Case{.name = "port_matches_original_script", .body = &port_matches_original_script},
    Case{.name = "bad_width_changes_nothing", .body = &bad_width_changes_nothing},
    Case{.name = "progress_is_clamped", .body = &progress_is_clamped},
    Case{.name = "fade_follows_super_progress", .body = &fade_follows_super_progress},
    Case{.name = "show_without_text_uses_shared_arg0", .body = &show_without_text_uses_shared_arg0},
    Case{.name = "delivery_follows_subscription", .body = &delivery_follows_subscription},
    Case{.name = "paint_only_when_shown", .body = &paint_only_when_shown},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_progress_bar_tests: mọi ca phải qua");
    return 0;
}
