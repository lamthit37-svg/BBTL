// Bảng con trỏ gốc: Interface/cursor/cursors.tsv và ảnh RGBA8 .ttex. Ô không có ảnh để trống,
// cửa sổ dùng mũi tên hệ thống.
#pragma once

#include "control/cursor_rules.hpp"
#include "window/cursor.hpp"

#include <array>
#include <filesystem>
#include <optional>

namespace game::client {

struct GameCursors {
    std::array<std::optional<window::Cursor>, control::kCursorKinds> pictures{};
};

// Thiếu bảng thì trả bảng rỗng và in một dòng; không làm hỏng game.
[[nodiscard]] GameCursors load_game_cursors(const std::filesystem::path& data_root);

} // namespace game::client
