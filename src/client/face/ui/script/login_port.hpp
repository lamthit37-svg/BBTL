/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/script/login_port.hpp
 *  PHÂN HỆ   : Ui / Script / Login Port
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cổng giữa thủ tục đăng nhập (ui/panel/login_flow) và hàm
 *    GameProduceLogin:* của script giao diện (native_login.cpp). Thủ tục ghi
 *    vào đây mỗi khung điều script đọc được (danh sách nhân vật của bảng chọn,
 *    ô đang chọn); hàm native đọc, và chỉ nhờ thủ tục làm việc qua
 *    Context::push_call, không sửa trạng thái thủ tục. Thuần dữ liệu, không
 *    Lua; dựng được ở mọi nền tảng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Gốc: CGamePro_CharSel (Game.exe 0x14063a230 đếm, 0x14063a240 lấy bản ghi 0x1a4 byte theo ô);
// GetRoleInfo 0x1403416e0 đọc tên +0x0c, cấp +0x2c, môn phái +0x44, ảnh +0x48, giờ xoá +0x128, cấp
// PK +0x1a0 của bản ghi. Khác gốc: gốc giữ danh sách trong đối tượng CharSel còn ở đây là bản chép
// từng khung; giờ xoá và cấp PK luôn 0 (máy chủ không có, NGHI-NGO 73); trạng thái bán nhân vật
// luôn 0.

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>

namespace game::ui::script {

// Số ô nhân vật tối đa của bảng chọn (SelectRole.lua có ba ô; gốc kẹp ô ở 3).
inline constexpr std::size_t kLoginSlots = 3;

// Bảy giá trị mà GetRoleInfo(ô) đẩy ra, theo thứ tự đẩy.
struct LoginRole {
    std::string name;
    std::int32_t sect = 0;
    std::int32_t level = 0;
    std::int32_t delete_days = 0;
    std::string icon;
    std::int32_t sale_state = 0;
    std::int32_t pk_level = 0;
};

struct LoginPort {
    std::array<LoginRole, kLoginSlots> roles{};
    // Số nhân vật đang có (GetRoleCount), không quá kLoginSlots.
    std::int32_t count = 0;
    // Ô đang chọn (GetCurSelectRole; gốc CharSel +0x588).
    std::int32_t selected = 0;
    // Ô mà DelSelRole xoá: SetCurSelect đặt (gốc CharSel +0x0c), tách khỏi ô đang chọn.
    std::int32_t delete_slot = 0;
    // GetSelectedServerIsPKServer: máy chủ đã chọn có cờ PK (cột 1 của bảng trạng thái máy chủ).
    bool is_pk_server = false;
    // Đồng hồ khung (ms, quấn vòng 32 bit) của lần SendEnterGameMsg gần nhất. Gốc cất ở biến
    // "Login_TextValidate_LastTime" của đối tượng DAT_141040bf0 (Game.exe 0x14063a7f0); không
    // script nào đọc biến đó nên giữ riêng ở đây. Chưa có giá trị là chưa vào game lần nào: lần
    // đầu không bị coi là "vừa gọi" dù đồng hồ khung mới chạy dưới 2 giây (gốc dùng giờ máy).
    std::optional<std::uint32_t> last_enter_tick;
};

} // namespace game::ui::script
