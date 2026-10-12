// Tên loại con trỏ và luật chọn con trỏ của khung. Nguồn luật ở cursor_rules.hpp.
// Khác gốc: cursor_name dùng at thay cho []; chỉ số hỏng ném thay vì đọc vượt mảng.
#include "control/cursor_rules.hpp"

#include <algorithm>
#include <cstdint>
#include <optional>
#include <string_view>
#include <utility>

namespace game::control {
namespace {

// FillMouseCommand_Left rồi switch trên lệnh: NPC không đánh được thì con trỏ nói chuyện; quái ra
// con trỏ tấn công; người chơi khác, mình và thú của mình không có lệnh, nên con trỏ thường.
CursorKind world_cursor(HoverKind kind) {
    switch (kind) {
    case HoverKind::kNpc: return CursorKind::kSpeak;
    case HoverKind::kMonster: return CursorKind::kAttack;
    case HoverKind::kOtherPlayer:
    case HoverKind::kMyself:
    case HoverKind::kPet: return CursorKind::kNormal;
    }
    return CursorKind::kNormal;
}

// Trên giao diện chỉ chế độ sửa và giám định có con trỏ riêng; hai chế độ đó chưa có.
CursorKind command_cursor(const CursorState& state) {
    if (state.over_ui || !state.hover) return CursorKind::kNormal;
    return world_cursor(*state.hover);
}

} // namespace

std::string_view cursor_name(CursorKind kind) {
    return kCursorNames.at(std::to_underlying(kind));
}

std::optional<CursorKind> cursor_named(std::string_view name) {
    const auto found = std::ranges::find(kCursorNames, name);
    if (found == kCursorNames.end()) return std::nullopt;
    const auto index = static_cast<std::uint8_t>(found - kCursorNames.begin());
    return static_cast<CursorKind>(index);
}

std::optional<CursorKind> choose_cursor(const CursorState& state) {
    if (state.camera_held) return std::nullopt;
    if (state.auto_run) return CursorKind::kAutoRun;
    const CursorKind kind = command_cursor(state);
    const bool is_pressed = kind == CursorKind::kNormal && state.primary_down;
    return is_pressed ? CursorKind::kNormalDown : kind;
}

} // namespace game::control
