#pragma once
// Bộ đọc client.toml: cấu hình giao diện của client do nhà phát hành đặt ở server. Gate đọc tệp này và
// gửi nó cho client trong tin UiConfig sau SessionStart; client không có tệp nào để người chơi sửa.

#include "config/issue.hpp"

#include <cstdint>
#include <string_view>

namespace game::config {

// Dạng khung chân dung của HUD: round là nền tròn với đầu 3D, square là chế độ classic của client 2026.
enum class AvatarFrame : std::uint8_t { kRound, kSquare };

struct ClientHud {
    AvatarFrame avatar_frame = AvatarFrame::kSquare;
};

struct Client {
    ClientHud hud;
};

[[nodiscard]] ReadResult<Client> read_client(std::string_view text);

} // namespace game::config
