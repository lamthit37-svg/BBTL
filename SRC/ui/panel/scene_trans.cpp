#include "ui/panel/scene_trans.hpp"

#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/wording.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kRoot = "SceneTrans_Frame";
constexpr std::string_view kTargetScene = "SceneTrans_TargetScene";
// Hai mẫu chữ của script, viết theo quy ước chỗ điền của wording.hpp: "前往" .. tên, và
// "前往" .. tên .. "[" .. phần trăm .. "]". Bảng chuỗi chưa có bản dịch thì dùng chính mẫu này.
constexpr std::string_view kGoto = "前往%s0";
constexpr std::string_view kGotoStep = "前往%s0[%s1]";

[[nodiscard]] std::string_view worded(const gui::StringBook& words, std::string_view pattern) noexcept {
    return words.find_literal(pattern).value_or(pattern);
}

} // namespace

void leave_world(SceneTrans& panel, std::string_view scene, const gui::StringBook& words) {
    panel.target.assign(scene);
    panel.text.clear();
    const std::array<std::string_view, 1> slots = {panel.target};
    format_pattern(panel.text, worded(words, kGoto), slots);
    panel.is_shown = true;
}

void scene_transing(SceneTrans& panel, std::int32_t percent, const gui::StringBook& words) {
    if (!panel.is_shown) return;
    const std::string step = std::to_string(percent);
    const std::array<std::string_view, 2> slots = {panel.target, step};
    panel.text.clear();
    format_pattern(panel.text, worded(words, kGotoStep), slots);
}

void scene_transed(SceneTrans& panel) noexcept {
    panel.is_shown = false;
}

void paint_scene_trans(Deck& deck, const SceneTrans& panel) {
    if (!panel.is_shown) return;
    deck.show(kRoot);
    deck.set(gui::Override{.window = kTargetScene, .name = "Text", .value = panel.text});
}

} // namespace game::ui::panel
