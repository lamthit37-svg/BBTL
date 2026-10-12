// Tên mười sáu môn phái theo số MENPAI của client 2026 (0..15). Mười ba số đầu là chữ viết
// thẳng trong script chọn nhân vật và bảng nhân vật; ba số cuối là khoá từ điển vì script gốc
// không viết thẳng. Số 9 là chưa nhập môn: nhân vật mới tạo luôn mang số này.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::array<std::string_view, 16> kSectNames = {
    "Thiếu Lâm",
    "Minh Giáo",
    "Cái Bang",
    "Võ Đang",
    "Nga Mi",
    "Tinh Túc",
    "Thiên Long",
    "Thiên Sơn",
    "Tiêu Dao",
    "Vô Phái",
    "Mộ Dung",
    "Đường Môn",
    "Quỷ Cốc",
    "#{THDXG_190705_03}",
    "#{XMPHM_210604_01}",
    "#{GMGameInterface_Script_DataPool_Info_ERenGu}",
};

// Tên môn phái sect; rỗng khi số nằm ngoài 0..15.
[[nodiscard]] constexpr std::string_view sect_name(std::uint8_t sect) noexcept {
    if (sect >= kSectNames.size()) return {};
    const auto index = static_cast<std::ptrdiff_t>(sect);
    return *std::next(kSectNames.begin(), index);
}

} // namespace game::ui::panel
