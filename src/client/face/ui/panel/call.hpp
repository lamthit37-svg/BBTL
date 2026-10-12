// Việc một bảng nhờ game làm khi xử lý sự kiện, thay các hàm toàn cục mà script gốc gọi
// (PushEvent, PushDebugMessage, OpenWindow, CloseWindow...). Bảng ghi lần lượt vào một danh sách;
// HUD đọc danh sách sau mỗi sự kiện và làm việc nào nó làm được. Tên in ra bằng name_of trùng tên
// hàm Lua, để test so từng dòng với dòng "!call" của TOOLS/port/lua_oracle.py.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>

namespace game::ui::panel {

enum class Ask : std::uint8_t {
    // PushEvent(tên sự kiện[, đối số]).
    kPushEvent,
    // PushDebugMessage(chữ): một dòng nhắc trên màn hình.
    kPushDebugMessage,
    // OpenWindow(tên) và CloseWindow(tên).
    kOpenWindow,
    kCloseWindow,
    // Nút action:DoAction(): dùng action đang nằm trong ô.
    kDoAction,
    // OpenTodayCampaignList(): mở bảng lịch hoạt động.
    kOpenCampaignList,
    // Helper:GotoHelper(mục): mở trợ giúp ở một mục.
    kGotoHelper,
    // Các hàm GameProduceLogin mà bảng tạo nhân vật gọi (docs/TAO-NHAN-VAT-2026.md). Chữ là các đối
    // số, kèm id mà game ghi nhận khi hàm tra bảng: SetFaceId(giới, chỉ số, id chân dung),
    // SetFaceModelId và SetHairModelId(giới, chỉ số, id; id 0 khi chỉ số ngoài bảng),
    // ChangeNewRoleEquipSet(giới, chỉ số[, id bộ đồ]), ShowModel(môn phái, -1 là thôi xem trước),
    // ModelRotBegin và ModelRotEnd(số vòng mỗi giây), ModelZoom(hướng phóng).
    kSetFaceId,
    kSetFaceModelId,
    kSetHairModelId,
    kChangeNewRoleEquipSet,
    kShowModel,
    kModelRotBegin,
    kModelRotEnd,
    kModelZoom,
    // CreateRole(tên, giới, chỉ số họ, chỉ số tên): xin tạo nhân vật.
    kCreateRole,
    // ChangeToSelectRoleDlgFromCreateRole(): về bảng chọn nhân vật.
    kChangeToSelectRole,
    // GameLoginShowSystemInfo(chữ): hộp thông báo của thủ tục đăng nhập.
    kShowSystemInfo,
};

struct Call {
    Ask ask = Ask::kPushEvent;
    // Các đối số của lời gọi, cách nhau bằng tab.
    std::string text;
};

[[nodiscard]] constexpr std::string_view name_of(Ask ask) noexcept {
    switch (ask) {
    case Ask::kPushEvent: return "PushEvent";
    case Ask::kPushDebugMessage: return "PushDebugMessage";
    case Ask::kOpenWindow: return "OpenWindow";
    case Ask::kCloseWindow: return "CloseWindow";
    case Ask::kDoAction: return "DoAction";
    case Ask::kOpenCampaignList: return "OpenTodayCampaignList";
    case Ask::kGotoHelper: return "GotoHelper";
    case Ask::kSetFaceId: return "SetFaceId";
    case Ask::kSetFaceModelId: return "SetFaceModelId";
    case Ask::kSetHairModelId: return "SetHairModelId";
    case Ask::kChangeNewRoleEquipSet: return "ChangeNewRoleEquipSet";
    case Ask::kShowModel: return "ShowModel";
    case Ask::kModelRotBegin: return "ModelRotBegin";
    case Ask::kModelRotEnd: return "ModelRotEnd";
    case Ask::kModelZoom: return "ModelZoom";
    case Ask::kCreateRole: return "CreateRole";
    case Ask::kChangeToSelectRole: return "ChangeToSelectRoleDlgFromCreateRole";
    case Ask::kShowSystemInfo: return "GameLoginShowSystemInfo";
    }
    return {};
}

} // namespace game::ui::panel
