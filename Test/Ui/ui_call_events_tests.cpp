// Việc nhờ game của các bảng mà thực chất là đẩy sự kiện (ui/panel/call_events): đổi Call thành sự kiện để HUD xếp hàng
// gửi cho các bảng khác, và chuỗi gỡ gói hành động chat chạy qua hai thanh action nối nhau bằng chính các sự kiện đó.
#include "ui/panel/call_events.hpp"

#include "core/check.hpp"
#include "test.hpp"
#include "ui/panel/action_bar.hpp"
#include "ui/panel/action_bars.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using ui::panel::Ask;
using ui::panel::Call;
using ui::panel::PostedEvent;

// Trần số sự kiện của vòng thử, như kMaxPanelEvents của HUD.
constexpr std::size_t kHopLimit = 16;

[[nodiscard]] bool is_event(const std::optional<PostedEvent>& posted, std::string_view name,
    std::initializer_list<std::string_view> args) {
    if (!posted || posted->name != name || posted->args.size() != args.size()) return false;
    std::size_t at = 0;
    for (const std::string_view arg : args) {
        if (posted->args.at(at++) != arg) return false;
    }
    return true;
}

[[nodiscard]] std::optional<PostedEvent> event_for(Ask ask, std::string text) {
    return ui::panel::event_of(Call{.ask = ask, .text = std::move(text)});
}

void game_int_truncates_and_saturates(Context& context) {
    constexpr double kNan = std::numeric_limits<double>::quiet_NaN();
    constexpr double kInf = std::numeric_limits<double>::infinity();
    context.expect(ui::panel::game_int(2.9) == 2, "cắt phần thập phân về 0");
    context.expect(ui::panel::game_int(-2.9) == -2, "số âm cũng cắt về 0");
    context.expect(ui::panel::game_int(kNan) == 0, "NaN thành 0");
    context.expect(ui::panel::game_int(1.0e12) == std::numeric_limits<std::int32_t>::max(), "tràn trên ép về cận");
    context.expect(ui::panel::game_int(-1.0e12) == std::numeric_limits<std::int32_t>::min(), "tràn dưới ép về cận");
    context.expect(ui::panel::game_int(kInf) == std::numeric_limits<std::int32_t>::max(), "vô cực ép về cận");
}

void push_event_splits_arguments(Context& context) {
    context.expect(is_event(event_for(Ask::kPushEvent, "SWITCH_MENU_BUTTON\t1"), "SWITCH_MENU_BUTTON", {"1"}),
        "đối số sau tab");
    context.expect(is_event(event_for(Ask::kPushEvent, "HIDE_THIS_UI"), "HIDE_THIS_UI", {}), "không đối số");
    context.expect(is_event(event_for(Ask::kPushEvent, "A\tx\t\ty"), "A", {"x", "", "y"}), "đối số rỗng giữ nguyên");
    context.expect(!event_for(Ask::kPushEvent, "").has_value(), "tên rỗng không phải sự kiện");
    context.expect(!event_for(Ask::kDoAction, "SWITCH_MENU_BUTTON\t1").has_value(), "việc khác không đẩy sự kiện");
    context.expect(!event_for(Ask::kPushDebugMessage, "chữ").has_value(), "thông báo không đẩy sự kiện");
}

void uninstall_levels_map_to_events(Context& context) {
    constexpr std::array<std::string_view, 6> kNames = {"UNINSTALL_CHAT_ACTION_CONFIRM", "UNINSTALL_CHAT_ACTION_BAR",
        "UNINSTALL_CHAT_ACTION_BAR2", "UNINSTALL_CHAT_ACTION_BAR3", "UNINSTALL_CHAT_ACTION_BAR4",
        "GE_UNINSTALL_CHAT_ACTION_BAR5"};
    for (std::size_t level = 0; level < kNames.size(); ++level) {
        context.expect(is_event(event_for(Ask::kUninstallChatAction, "7\t" + std::to_string(level)), kNames.at(level), {"7"}),
            "cấp 0..5 đẩy sự kiện với ô gói làm đối số");
    }
    context.expect(!event_for(Ask::kUninstallChatAction, "7\t6").has_value(), "cấp 6 gửi gói tin, không đẩy sự kiện");
    context.expect(!event_for(Ask::kUninstallChatAction, "7\t7").has_value(), "cấp ngoài miền");
    context.expect(!event_for(Ask::kUninstallChatAction, "7\t-1").has_value(), "cấp âm");
    context.expect(!event_for(Ask::kUninstallChatAction, "chu\t1").has_value(), "ô gói không phải số");
    context.expect(!event_for(Ask::kUninstallChatAction, "7").has_value(), "thiếu cấp");
    context.expect(!event_for(Ask::kUninstallChatAction, "7\t1\t2").has_value(), "thừa trường");
}

void clear_pushes_event_for_next_bar(Context& context) {
    context.expect(is_event(event_for(Ask::kClearChatActionBar, "MainMenuBar_4\t2\t5\t6"), "CLEAR_CHAT_ACTION_BAR",
                       {"MainMenuBar_4", "2", "5", "6"}),
        "tên thanh giữ nguyên, ba số còn lại là số nguyên");
    context.expect(is_event(event_for(Ask::kClearChatActionBar, "MainMenuBar_4\t2\t5.9\t6"), "CLEAR_CHAT_ACTION_BAR",
                       {"MainMenuBar_4", "2", "5", "6"}),
        "số thực bị cắt như (int) của game");
    context.expect(!event_for(Ask::kClearChatActionBar, "MainMenuBar_4\t2\tchu\t6").has_value(), "đối số không phải số");
    context.expect(!event_for(Ask::kClearChatActionBar, "MainMenuBar_4\t2\t5").has_value(), "thiếu trường");
    context.expect(!event_for(Ask::kSetChatAction, "2\t5\t6").has_value(), "ghi vào kho không đẩy sự kiện");
}

// Giống vòng của HUD: sự kiện đầu vào các thanh, việc các thanh nhờ mà là sự kiện thì xếp cuối hàng đợi và tới các thanh
// sau khi sự kiện hiện tại xong. Trả mọi việc không phải sự kiện theo thứ tự phát sinh.
[[nodiscard]] std::vector<Call> drain(
    ui::panel::ActionBars& bars, const ui::panel::BarFacts& facts, std::vector<PostedEvent> first) {
    ui::panel::EventArgs args;
    ui::panel::EventQueue queue(first, kHopLimit);
    std::vector<Call> rest;
    while (const std::optional<PostedEvent> posted = queue.next()) {
        const std::vector<std::string_view> given = posted->arguments();
        const ui::panel::UiEvent event = args.raise(posted->name, given);
        std::vector<Call> calls;
        bars.raise(event, facts, calls);
        for (Call& call : calls) {
            if (std::optional<PostedEvent> next = ui::panel::event_of(call)) {
                queue.push(std::move(*next));
            } else {
                rest.push_back(std::move(call));
            }
        }
    }
    return rest;
}

// Mọi sự kiện mà queue còn trả, theo thứ tự.
[[nodiscard]] std::vector<PostedEvent> rest_of(ui::panel::EventQueue& queue) {
    std::vector<PostedEvent> events;
    while (std::optional<PostedEvent> next = queue.next())
        events.push_back(std::move(*next));
    return events;
}

[[nodiscard]] ui::panel::BarFacts chat_facts() {
    ui::panel::BarFacts facts;
    facts.chat.moods = {900, 901, 902, 903, 904, 905, 0, 907};
    facts.chat.packs.at(2) = ui::panel::ChatPack{.real_id = 7, .count = 3, .min_index = 5, .kind = 1};
    return facts;
}

[[nodiscard]] bool has_call(const std::vector<Call>& calls, Ask ask, std::string_view text) {
    for (const Call& call : calls) {
        if (call.ask == ask && call.text == text) return true;
    }
    return false;
}

// FunctionBarRight (cấp 4), FunctionBarRight_2 (cấp 5) rồi MainMenuBar_4 (cấp 6, gửi gói tin): các thanh nối nhau chỉ
// bằng sự kiện.
void uninstall_chain_runs_through_the_bars(Context& context) {
    ui::panel::ActionBars bars;
    const ui::panel::BarFacts facts = chat_facts();
    const std::vector<Call> rest =
        drain(bars, facts, {PostedEvent{.name = "UNINSTALL_CHAT_ACTION_BAR3", .args = {"2"}}});
    context.expect(has_call(rest, Ask::kUninstallChatAction, "2\t6"), "thanh cuối gửi gói tin xoá (cấp 6)");
    context.expect(!has_call(rest, Ask::kUninstallChatAction, "2\t4"), "cấp 4 đã thành sự kiện cho FunctionBarRight_2");
    context.expect(!has_call(rest, Ask::kUninstallChatAction, "2\t5"), "cấp 5 đã thành sự kiện cho MainMenuBar_4");
}

void uninstall_chain_can_start_at_the_second_bar(Context& context) {
    ui::panel::ActionBars bars;
    const ui::panel::BarFacts facts = chat_facts();
    const std::vector<Call> rest =
        drain(bars, facts, {PostedEvent{.name = "UNINSTALL_CHAT_ACTION_BAR4", .args = {"2"}}});
    context.expect(has_call(rest, Ask::kUninstallChatAction, "2\t6"), "thanh cuối gửi gói tin xoá (cấp 6)");
    context.expect(!has_call(rest, Ask::kUninstallChatAction, "2\t5"), "cấp 5 đã thành sự kiện cho MainMenuBar_4");
}

void clear_chain_ends_in_the_store(Context& context) {
    ui::panel::ActionBars bars;
    const ui::panel::BarFacts facts = chat_facts();
    const std::vector<Call> rest = drain(bars, facts,
        {PostedEvent{.name = "CLEAR_CHAT_ACTION_BAR", .args = {"FunctionBarRight", "2", "5", "6"}}});
    context.expect(has_call(rest, Ask::kSetChatAction, "2\t5\t6"), "thanh cuối ghi gói mới vào kho");
}

// Game.exe 0x140205430: sự kiện giống hệt một sự kiện đứng trước trong cùng khung thì bị bỏ, trừ NEW_DEBUGMESSAGE.
void queue_drops_repeated_events(Context& context) {
    const std::array first = {PostedEvent{.name = "A", .args = {"1"}}, PostedEvent{.name = "A", .args = {"1"}},
        PostedEvent{.name = "A", .args = {"2"}}, PostedEvent{.name = "B", .args = {"1"}},
        PostedEvent{.name = "A", .args = {"1"}}};
    ui::panel::EventQueue queue(first, kHopLimit);
    const std::vector<PostedEvent> got = rest_of(queue);
    context.expect(got.size() == 3, "ba sự kiện khác nhau còn lại");
    context.expect(got.size() == 3 && got.at(0) == first.at(0) && got.at(1) == first.at(2) && got.at(2) == first.at(3),
        "giữ lần xuất hiện đầu, theo thứ tự");
}

void queue_keeps_repeated_debug_messages(Context& context) {
    const std::array first = {PostedEvent{.name = "NEW_DEBUGMESSAGE", .args = {"x"}},
        PostedEvent{.name = "NEW_DEBUGMESSAGE", .args = {"x"}}};
    ui::panel::EventQueue queue(first, kHopLimit);
    context.expect(rest_of(queue).size() == 2, "thông báo giống nhau đều hiện");
}

// Sự kiện đẩy trong lúc xử lý tới sau mọi sự kiện đang chờ, trong cùng khung; sự kiện đã có thì bị bỏ như sự kiện lặp.
void queue_appends_pushed_events_at_the_end(Context& context) {
    const std::array first = {PostedEvent{.name = "A", .args = {}}, PostedEvent{.name = "B", .args = {}}};
    ui::panel::EventQueue queue(first, kHopLimit);
    const std::optional<PostedEvent> head = queue.next();
    context.expect(head && head->name == "A", "sự kiện đầu");
    queue.push(PostedEvent{.name = "C", .args = {}});
    queue.push(PostedEvent{.name = "B", .args = {}});
    const std::vector<PostedEvent> got = rest_of(queue);
    context.expect(got.size() == 2 && got.at(0).name == "B" && got.at(1).name == "C",
        "B đang chờ chạy trước C đẩy sau; B đẩy lần hai bị bỏ");
}

void queue_stops_at_the_limit(Context& context) {
    ui::panel::EventQueue queue({}, 4);
    for (std::size_t index = 0; index < 10; ++index)
        queue.push(PostedEvent{.name = "E", .args = {std::to_string(index)}});
    context.expect(rest_of(queue).size() == 4, "trần tính theo số nút đã duyệt");
    context.expect(!queue.next().has_value(), "chạm trần thì không trả thêm");
}

void unheard_event_makes_no_work(Context& context) {
    ui::panel::ActionBars bars;
    const ui::panel::BarFacts facts = chat_facts();
    const std::vector<Call> rest = drain(bars, facts, {PostedEvent{.name = "CHANGE_BAR", .args = {"other"}}});
    context.expect(rest.empty(), "sự kiện không ai nghe thì không sinh việc");
}

constexpr std::array kCases{
    Case{.name = "game_int_truncates_and_saturates", .body = &game_int_truncates_and_saturates},
    Case{.name = "push_event_splits_arguments", .body = &push_event_splits_arguments},
    Case{.name = "uninstall_levels_map_to_events", .body = &uninstall_levels_map_to_events},
    Case{.name = "clear_pushes_event_for_next_bar", .body = &clear_pushes_event_for_next_bar},
    Case{.name = "uninstall_chain_runs_through_the_bars", .body = &uninstall_chain_runs_through_the_bars},
    Case{.name = "uninstall_chain_can_start_at_the_second_bar", .body = &uninstall_chain_can_start_at_the_second_bar},
    Case{.name = "clear_chain_ends_in_the_store", .body = &clear_chain_ends_in_the_store},
    Case{.name = "queue_drops_repeated_events", .body = &queue_drops_repeated_events},
    Case{.name = "queue_keeps_repeated_debug_messages", .body = &queue_keeps_repeated_debug_messages},
    Case{.name = "queue_appends_pushed_events_at_the_end", .body = &queue_appends_pushed_events_at_the_end},
    Case{.name = "queue_stops_at_the_limit", .body = &queue_stops_at_the_limit},
    Case{.name = "unheard_event_makes_no_work", .body = &unheard_event_makes_no_work},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_call_events_tests: mọi ca phải qua");
    return 0;
}
