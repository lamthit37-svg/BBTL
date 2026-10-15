#include "ui/script/windows.hpp"

#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::script {
namespace {

constexpr auto kLastDemise = static_cast<std::int32_t>(Demise::kPopup);

// Đường dẫn dưới Interface/: không rỗng, không tuyệt đối, không đoạn "..", không gạch ngược (read_window đã đổi \ thành /).
[[nodiscard]] bool is_inside(std::string_view path) noexcept {
    if (path.empty() || path.front() == '/' || path.contains('\\') || path.contains(':')) return false;
    const auto is_up = [](const auto& part) { return std::string_view(part) == ".."; };
    return std::ranges::none_of(std::views::split(path, '/'), is_up);
}

// Một dòng của sổ; lỗi nằm trong reader.
[[nodiscard]] WindowDef read_window(table::RowReader& reader) {
    WindowDef window;
    window.id = reader.integer("id", 0, std::numeric_limits<std::int32_t>::max());
    window.name = reader.text("name");
    window.layout = reader.text("layout");
    window.script = reader.text("script");
    // Sổ gốc viết dấu \ ở khoảng 590 dòng (QuitRelative\QuitRelative.lua), hệ tệp của client gốc nhận cả hai dấu.
    std::ranges::replace(window.layout, '\\', '/');
    std::ranges::replace(window.script, '\\', '/');
    window.demise = static_cast<Demise>(reader.integer("demise", 0, kLastDemise));
    if (window.name.empty()) reader.reject("name", "tên cửa sổ rỗng");
    if (!is_inside(window.layout)) reader.reject("layout", "đường dẫn phải nằm dưới Interface/");
    if (!is_inside(window.script)) reader.reject("script", "đường dẫn phải nằm dưới Interface/");
    return window;
}

} // namespace

std::expected<std::vector<WindowDef>, std::string> parse_windows(std::string_view text) {
    auto table = table::parse_tsv(text);
    if (!table) return std::unexpected(std::move(table.error()));
    std::vector<WindowDef> windows;
    windows.reserve(table->rows.size());
    for (std::size_t index = 0; index < table->rows.size(); ++index) {
        table::RowReader reader(*table, index);
        WindowDef window = read_window(reader);
        if (reader.error()) return std::unexpected(*reader.error());
        windows.push_back(std::move(window));
    }
    std::vector<std::string_view> names;
    names.reserve(windows.size());
    for (const WindowDef& window : windows)
        names.emplace_back(window.name);
    std::ranges::sort(names);
    const auto repeat = std::ranges::adjacent_find(names);
    if (repeat != names.end()) return std::unexpected(std::format("windows.tsv: tên cửa sổ {} lặp", *repeat));
    return windows;
}

} // namespace game::ui::script
