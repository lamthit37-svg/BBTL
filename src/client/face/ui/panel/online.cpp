#include "ui/panel/online.hpp"

#include <string_view>

namespace game::ui::panel {

std::string_view online_text(OnlineFault fault) noexcept {
    switch (fault) {
    case OnlineFault::kUnreachable: return "无法连接服务器，请检查网络后重试。";
    case OnlineFault::kSecure: return "服务器身份验证失败，请更新客户端。";
    case OnlineFault::kProtocol: return "与服务器通信出错，请重新登录。";
    case OnlineFault::kTimeout: return "服务器没有响应，请稍后重试。";
    case OnlineFault::kBadLogin: return "账号或密码错误。";
    case OnlineFault::kServerFull: return "服务器人数已满，请稍后再试。";
    case OnlineFault::kBusy: return "服务器繁忙，请稍后再试。";
    case OnlineFault::kMaintenance: return "服务器正在维护。";
    case OnlineFault::kNameTaken: return "#{Login_Create_Role_Name_Exist}";
    case OnlineFault::kNameInvalid: return "#{INVALID_CHARACTER_IN_NAME}";
    case OnlineFault::kRoleLimit: return "#{ROLE_LIST_FULL}";
    case OnlineFault::kNoRole: return "#{LCRetDeleteCharHandler_Info_Unknow_err}";
    case OnlineFault::kNoRoleToDelete: return "#{LCRetDeleteCharHandler_Info_No_Role_Del}";
    case OnlineFault::kRoleOnline: return "#{FWQYM_160120_147}";
    case OnlineFault::kInternal: return "#{LCRetDeleteCharHandler_Info_Err}";
    case OnlineFault::kDeleteTooSoon: return "#{LCRetDeleteCharHandler_1}";
    case OnlineFault::kElsewhere: return "您的账号已在别处登录。";
    case OnlineFault::kClosed: return "与服务器的连接已断开。";
    case OnlineFault::kOther: return "操作失败，请重试。";
    }
    return "操作失败，请重试。";
}

} // namespace game::ui::panel
