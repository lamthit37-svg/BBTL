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
    // Target:UpdateActionButton(): đối tượng đang chọn làm mới các ô action (Game.exe 0x140687a74).
    kUpdateActionButton,
    // DataPool:UnInstall_RMB_ChatAction_BarItem(vị trí): xoá bản ghi ô của thanh action ở vị trí (cùng số với
    // DragName của ô, Game.exe 0x1402f3270). Chữ: vị trí.
    kUninstallChatActionBarItem,
    // DataPool:UnInstall_RMB_ChatAction(ô gói, cấp): gỡ gói hành động chat; cấp 0..5 đẩy sự kiện gỡ cho thanh kế,
    // cấp 6 gửi gói tin xoá (Game.exe 0x1402f30d0). Chữ: ô gói, cấp.
    kUninstallChatAction,
    // DataPool:Set_RMB_ChatAction(ô gói, id, dữ liệu): ghi gói hành động chat mới vào ô (Game.exe 0x1402f3440).
    kSetChatAction,
    // DataPool:Clear_ChatAction_Bar(thanh, ô gói, id, dữ liệu): đẩy CLEAR_CHAT_ACTION_BAR cho thanh kế
    // (Game.exe 0x1402f32d0). Chữ: thanh, ô gói, id, dữ liệu.
    kClearChatActionBar,
    // OpenFreshManGuideNew(loại, x, y, rộng, cao, kiểu, hướng, chủ): mở lớp hướng dẫn tân thủ quanh một ô (Game.exe
    // 0x1402649e0). Chữ: tám đối số.
    kOpenFreshManGuide,
    // CloseFreshManGuide(): đóng lớp hướng dẫn tân thủ (Game.exe 0x140262120).
    kCloseFreshManGuide,
    // this:CareObject(id, cờ) của một cửa sổ: cờ khác 0 nhờ hệ đối tượng theo dõi khoảng cách tới đối tượng id, xa quá thì
    // đóng cửa sổ (UI_CEGUI.dll 3.71.9509 0x180077870; cờ 0 thì gốc không làm gì nên không ghi). Chữ: id, tên cửa sổ.
    kCareObject,
    // Cửa sổ mô hình (MeshWindow) nhờ hệ mô hình của Game.exe; chữ là các đối số cách nhau tab (UI_CEGUI.dll 3.71.9509):
    // RotateBegin(đối tượng, tốc độ) và RotateEnd(đối tượng) quay FakeObject (0x180033090, 0x180033250); RotateBeginEx(tên, tốc độ)
    // và RotateEndEx(cửa sổ) quay mô hình của hệ cửa sổ (0x1800331c0, 0x180033330); AttachWindowEx(cửa sổ, tên, rộng, cao),
    // DetachWindowEx(cửa sổ), RestPositonEx(cửa sổ) (0x180022ac0, 0x180024e60, 0x180033060); SetCameraEx(cửa sổ, x, y, z, w)
    // (0x180036d70); ChangeCameraDistanceEx(cửa sổ, tên, hướng, mức) (0x1800230d0). Tốc độ đã nhân 0,5 như bản gốc.
    kMeshRotateBegin,
    kMeshRotateEnd,
    kMeshRotateBeginEx,
    kMeshRotateEndEx,
    kMeshAttach,
    kMeshDetach,
    kMeshRestPosition,
    kMeshSetCamera,
    kMeshZoom,
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
    case Ask::kUpdateActionButton: return "UpdateActionButton";
    case Ask::kUninstallChatActionBarItem: return "UnInstall_RMB_ChatAction_BarItem";
    case Ask::kUninstallChatAction: return "UnInstall_RMB_ChatAction";
    case Ask::kSetChatAction: return "Set_RMB_ChatAction";
    case Ask::kClearChatActionBar: return "Clear_ChatAction_Bar";
    case Ask::kOpenFreshManGuide: return "OpenFreshManGuideNew";
    case Ask::kCloseFreshManGuide: return "CloseFreshManGuide";
    case Ask::kCareObject: return "CareObject";
    case Ask::kMeshRotateBegin: return "RotateBegin";
    case Ask::kMeshRotateEnd: return "RotateEnd";
    case Ask::kMeshRotateBeginEx: return "RotateBeginEx";
    case Ask::kMeshRotateEndEx: return "RotateEndEx";
    case Ask::kMeshAttach: return "AttachWindowEx";
    case Ask::kMeshDetach: return "DetachWindowEx";
    case Ask::kMeshRestPosition: return "RestPositonEx";
    case Ask::kMeshSetCamera: return "SetCameraEx";
    case Ask::kMeshZoom: return "ChangeCameraDistanceEx";
    }
    return {};
}

} // namespace game::ui::panel
