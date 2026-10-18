/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/online.cpp
 *  PHÂN HỆ   : Ui / Panel / Online
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lời báo lỗi nối máy chủ (OnlineFault) thành thẻ #{...} của bảng chuỗi, để
 *    chữ hiện ra đi theo ngôn ngữ đang chọn.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/panel/online.hpp"

#include <string_view>

namespace game::ui::panel {

std::string_view online_text(OnlineFault fault) noexcept {
    switch (fault) {
    case OnlineFault::kUnreachable: return "#{ONLINE_UNREACHABLE}";
    case OnlineFault::kSecure: return "#{ONLINE_SECURE}";
    case OnlineFault::kProtocol: return "#{ONLINE_PROTOCOL}";
    case OnlineFault::kTimeout: return "#{ONLINE_TIMEOUT}";
    case OnlineFault::kBadLogin: return "#{ONLINE_BAD_LOGIN}";
    case OnlineFault::kServerFull: return "#{ONLINE_SERVER_FULL}";
    case OnlineFault::kBusy: return "#{ONLINE_BUSY}";
    case OnlineFault::kMaintenance: return "#{ONLINE_MAINTENANCE}";
    case OnlineFault::kNameTaken: return "#{Login_Create_Role_Name_Exist}";
    case OnlineFault::kNameInvalid: return "#{INVALID_CHARACTER_IN_NAME}";
    case OnlineFault::kRoleLimit: return "#{ROLE_LIST_FULL}";
    case OnlineFault::kNoRole: return "#{LCRetDeleteCharHandler_Info_Unknow_err}";
    case OnlineFault::kNoRoleToDelete: return "#{LCRetDeleteCharHandler_Info_No_Role_Del}";
    case OnlineFault::kRoleOnline: return "#{FWQYM_160120_147}";
    case OnlineFault::kInternal: return "#{LCRetDeleteCharHandler_Info_Err}";
    case OnlineFault::kDeleteTooSoon: return "#{LCRetDeleteCharHandler_1}";
    case OnlineFault::kElsewhere: return "#{ONLINE_ELSEWHERE}";
    case OnlineFault::kClosed: return "#{ONLINE_CLOSED}";
    case OnlineFault::kOther: return "#{ONLINE_FAILED}";
    }
    return "#{ONLINE_FAILED}";
}

} // namespace game::ui::panel
