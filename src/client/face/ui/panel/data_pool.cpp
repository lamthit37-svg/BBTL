#include "ui/panel/data_pool.hpp"

#include "core/text.hpp"

#include <algorithm>
#include <string_view>

namespace game::ui::panel {
namespace {

// Ký tự điều khiển mà hàm gốc coi là sai: mọi byte dưới 0x20 trừ tab, xuống dòng, về đầu dòng (mặt nạ 0xffffd9ff).
[[nodiscard]] bool is_forbidden_control(char byte) noexcept {
    const auto code = static_cast<unsigned char>(byte);
    return code < 0x20U && code != '\t' && code != '\n' && code != '\r';
}

} // namespace

bool check_string_code(std::string_view text) noexcept {
    return !std::ranges::any_of(text, is_forbidden_control) && core::is_valid_utf8(text);
}

} // namespace game::ui::panel
