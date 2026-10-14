#include "ui/panel/call_events.hpp"

#include "ui/panel/action_bar.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/lua_value.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

constexpr double kInt32Min = static_cast<double>(std::numeric_limits<std::int32_t>::min());
constexpr double kInt32Max = static_cast<double>(std::numeric_limits<std::int32_t>::max());
constexpr std::string_view kClearEvent = "CLEAR_CHAT_ACTION_BAR";
// Sự kiện id 0x85: Tick không bỏ nút lặp của nó (hai dòng thông báo giống nhau đều hiện).
constexpr std::string_view kNeverRepeated = "NEW_DEBUGMESSAGE";

// Các phần của text cách nhau bằng tab (Call::text).
[[nodiscard]] std::vector<std::string_view> fields_of(std::string_view text) {
    std::vector<std::string_view> fields;
    std::size_t start = 0;
    while (true) {
        const std::size_t stop = text.find('\t', start);
        if (stop == std::string_view::npos) break;
        fields.push_back(text.substr(start, stop - start));
        start = stop + 1;
    }
    fields.push_back(text.substr(start));
    return fields;
}

// Số trong text đã ghi ra bằng số của Lua; dùng như số nguyên của game. nullopt khi không phải số.
[[nodiscard]] std::optional<std::int32_t> int_field(std::string_view text) {
    const std::optional<double> value = lua_tonumber(text);
    if (!value) return std::nullopt;
    return game_int(*value);
}

[[nodiscard]] std::optional<PostedEvent> uninstall_event(const std::vector<std::string_view>& fields) {
    if (fields.size() != 2) return std::nullopt;
    const std::optional<std::int32_t> pack = int_field(fields[0]);
    const std::optional<std::int32_t> level = int_field(fields[1]);
    if (!pack || !level) return std::nullopt;
    const std::optional<std::string_view> name = uninstall_chat_action_event(*level);
    if (!name) return std::nullopt;
    return PostedEvent{.name = std::string(*name), .args = {std::format("{}", *pack)}};
}

[[nodiscard]] std::optional<PostedEvent> clear_event(const std::vector<std::string_view>& fields) {
    constexpr std::size_t kFields = 4;
    if (fields.size() != kFields) return std::nullopt;
    PostedEvent posted{.name = std::string(kClearEvent), .args = {std::string(fields[0])}};
    for (std::size_t at = 1; at < kFields; ++at) {
        const std::optional<std::int32_t> number = int_field(fields[at]);
        if (!number) return std::nullopt;
        posted.args.push_back(std::format("{}", *number));
    }
    return posted;
}

[[nodiscard]] std::optional<PostedEvent> pushed_event(const std::vector<std::string_view>& fields) {
    if (fields.front().empty()) return std::nullopt;
    PostedEvent posted{.name = std::string(fields.front()), .args = {}};
    for (std::size_t at = 1; at < fields.size(); ++at)
        posted.args.emplace_back(fields[at]);
    return posted;
}

// Một nút trước nó trong hàng đợi cùng sự kiện và cùng mọi đối số (0x140207180).
[[nodiscard]] bool is_repeat(std::span<const PostedEvent> earlier, const PostedEvent& event) {
    if (event.name == kNeverRepeated) return false;
    return std::ranges::any_of(earlier, [&event](const PostedEvent& other) { return other == event; });
}

} // namespace

std::int32_t game_int(double value) noexcept {
    if (std::isnan(value)) return 0;
    return static_cast<std::int32_t>(std::clamp(std::trunc(value), kInt32Min, kInt32Max));
}

std::optional<PostedEvent> event_of(const Call& call) {
    const std::vector<std::string_view> fields = fields_of(call.text);
    switch (call.ask) {
    case Ask::kPushEvent: return pushed_event(fields);
    case Ask::kUninstallChatAction: return uninstall_event(fields);
    case Ask::kClearChatActionBar: return clear_event(fields);
    default: return std::nullopt;
    }
}

EventQueue::EventQueue(std::span<const PostedEvent> first, std::size_t limit)
    : events_(first.begin(), first.end()), limit_(limit) {}

std::optional<PostedEvent> EventQueue::next() {
    while (at_ < events_.size() && at_ < limit_) {
        const std::size_t index = at_++;
        const std::span<const PostedEvent> earlier(events_.data(), index);
        if (!is_repeat(earlier, events_.at(index))) return events_.at(index);
    }
    return std::nullopt;
}

void EventQueue::push(PostedEvent event) {
    events_.push_back(std::move(event));
}

} // namespace game::ui::panel
