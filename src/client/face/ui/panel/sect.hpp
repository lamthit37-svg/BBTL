// Tên mười sáu môn phái theo số MENPAI của client 2026 (0..15). Mỗi số là một khoá
// StrDictionary (DataPool_Info, XQ_MP, hoặc khoá riêng của môn thêm sau). Chữ hiện ra
// lấy từ bảng dịch, không viết thẳng ở đây. Số 9 là chưa nhập môn.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <string_view>

namespace game::ui::panel {

inline constexpr std::array<std::string_view, 16> kSectNames = {
    "#{GMGameInterface_Script_DataPool_Info_ShaoLin}",
    "#{GMGameInterface_Script_DataPool_Info_Mingjiao}",
    "#{GMGameInterface_Script_DataPool_Info_GaiBang}",
    "#{GMGameInterface_Script_DataPool_Info_WuDang}",
    "#{GMGameInterface_Script_DataPool_Info_EMei}",
    "#{GMGameInterface_Script_DataPool_Info_XingXiu}",
    "#{GMGameInterface_Script_DataPool_Info_DaLi}",
    "#{GMGameInterface_Script_DataPool_Info_TianShan}",
    "#{GMGameInterface_Script_DataPool_Info_XiaoYao}",
    "#{GMGameInterface_Script_DataPool_Info_WuMenPai}",
    "#{GMGameInterface_Script_DataPool_Info_GuSu}",
    "#{XQ_MP_13}",
    "#{XQ_MP_14}",
    "#{XQ_MP_15}",
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
