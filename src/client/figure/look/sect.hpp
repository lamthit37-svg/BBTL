#pragma once
// Người mẫu xem trước môn phái của màn tạo nhân vật. Bản 2026 dựng cho mỗi môn và mỗi giới một mẫu
// riêng (CharModelEx dòng 4950 + giới * 15 + môn, Game.exe 0x1406420d0): các lưới cố định của mẫu,
// xương riêng mang đúng hai animation là đứng và bài múa. ShowModel cho phát bài múa một lần lúc
// mẫu hiện (0x140640450); với mười hai môn đầu bài múa cũng là động tác nghỉ của bộ hành động, nên
// người mẫu thỉnh thoảng múa lại. Bảng Table/sect_models.tsv do TOOLS/content/export_look.py sinh.

#include "look/appearance.hpp"
#include "look/look.hpp"

#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>

namespace game::look {

inline constexpr std::uint8_t kSectCount = 15;

// Hình của một người mẫu môn phái: figure.idle là clip đứng (figure.run trỏ cùng clip, người mẫu
// không chạy), figure.idle_alt và idle_alt2 là bài múa. has_fidget sai thì bài múa chỉ phát lúc
// hiện, không làm động tác nghỉ.
struct SectFigure {
    Figure figure;
    bool has_fidget = false;
};

// Dòng (race, sect) của bảng có chữ là text; O(số dòng). Lỗi là câu tiếng Việt: bảng sai dạng, môn
// ngoài 0..14, không có dòng, hay dòng thiếu lưới.
[[nodiscard]] std::expected<SectFigure, std::string> sect_figure(std::string_view text, Race race,
    std::uint8_t sect);

// Đồ gắn khe của người mẫu (Table/sect_held.tsv do export_sect_held.py sinh): 鬼谷 cầm gậy bằng
// Slot của locator 武器特效点, không bằng lưới trong EntityList của mẫu. Môn không có dòng thì
// nullopt (không gắn gì); lỗi là câu tiếng Việt như sect_figure. Kết quả nối vào figure.held.
[[nodiscard]] std::expected<std::optional<Held>, std::string> sect_held(std::string_view text,
    Race race, std::uint8_t sect);

} // namespace game::look
