// Lõi chung của bốn thanh action HUD: MainMenuBar_2, FunctionBarRight, FunctionBarRight_2 và MainMenuBar_4. Bốn
// script của client 2026 cùng một khuôn: một dãy ô action (id 31..40, 41..49, 61..69, 71..80 trong hệ thanh
// action), mỗi ô có hai cửa sổ nháy combo (cấp thấp "junior" và cấp cao "senior"), nhận CHANGE_BAR để đặt hay dọn ô,
// ACTION_UPDATE để nhắc nháy mới, FLASH_COMBOSKILL để bật tắt nháy, và hai sự kiện gỡ gói hành động chat đôi
// (UNINSTALL_CHAT_ACTION_BAR*, CLEAR_CHAT_ACTION_BAR) chuyền nối đuôi từ thanh này sang thanh kia rồi tới gói tin.
// File này chứa phần thân giống nhau của các nhánh đó; mỗi cửa sổ (main_menu_bar_4.hpp...) khai BarSpec của nó và
// xử lý nốt sự kiện riêng (mở thanh, cổng GM...). Bản dịch ghi vào Widgets đúng những lời gọi script làm; mỗi test
// cửa sổ so trạng thái đó với số vàng do script gốc chạy trên LuaPlus.dll (TOOLS/port/oracle/action_bar_api.lua là
// các hàm game mà script gọi).
// Đặc điểm của script mà bản port giữ:
//  - Script chạy trong Lua; chỗ nào gặp nil hay sai kiểu thì script dừng ngay với lỗi, phần đã làm trước đó vẫn còn.
//    Hàm ở đây dừng đúng chỗ ấy (return) chứ không bỏ cả sự kiện hay làm tiếp.
//  - arg<k> và eventTable do game đặt chung cho mọi cửa sổ và không xoá giữa các sự kiện (events.hpp): đối số một
//    sự kiện không nêu giữ giá trị của sự kiện trước.
//  - IsVisible() của một cửa sổ con là Window::isVisible(false) của CEGUI (UI_CEGUI 0x180028b60): nó hiện và mọi
//    cửa sổ cha hiện. Thanh ẩn thì ô con coi là ẩn; hai khung bọc trong layout script không đụng tới nên luôn hiện.
// Khác gốc:
//  - Hệ action (ActionSystem), hệ thú cưng, kho 11 ô gói hành động chat (DBC 0xfd và bảng mood của Talk) chưa có ở
//    client: BarFacts mang những thứ script hỏi. HUD chưa có nguồn thì đưa BarFacts rỗng; khi đó ô nhận id mà không có
//    icon, mọi thú cưng coi như không chiến đấu, và không có gói nào để gỡ.
//  - Việc script nhờ game (làm mới nút, xoá bản ghi ô, đẩy sự kiện gỡ gói, gói tin) chỉ ghi vào danh sách Call;
//    uninstall_chat_action_event cho biết sự kiện ứng với cấp UnInstall_RMB_ChatAction.
//  - SetNewFlash chỉ đánh dấu ô có action nháy; cờ nháy thật do action quyết định (setFlashEnable) khi có hệ action.
#pragma once

#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/events.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

// Khoảng id mà một dòng so sánh trong script xét: low < id < high, đầu mỗi bên đóng (<=) hay mở (<) tuỳ dòng.
struct IdRange {
    double low = 0.0;
    bool is_low_closed = false;
    double high = 0.0;
    bool is_high_closed = false;

    [[nodiscard]] constexpr bool contains(double id) const noexcept {
        const bool is_above = is_low_closed ? id >= low : id > low;
        const bool is_below = is_high_closed ? id <= high : id < high;
        return is_above && is_below;
    }
};

// Những điều khác nhau giữa bốn script.
struct BarSpec {
    // Tên layout (không có "_Frame"): MainMenuBar_4. Cửa sổ gốc là <name>_Frame, ô action là <name>_Button_Action<k>.
    std::string_view name;
    // Chen giữa tên và số ô trong tên cửa sổ nháy: <name><flash_infix><k>_junior_Flash.
    std::string_view flash_infix;
    // id của ô thứ nhất trong hệ thanh action và số ô (UPBAR_2_BUTTONS[71..80]).
    std::int32_t first_id = 0;
    std::int32_t count = 0;
    // Dải id mà CHANGE_BAR đặt hay dọn ô.
    IdRange set_range;
    // Dải id mà ô được coi là có trên thanh để gỡ nháy, và dải của FLASH_COMBOSKILL.
    IdRange seen_range;
    // true: CHANGE_BAR main gọi Target:UpdateActionButton() trước mọi so sánh; false (FunctionBarRight_2): chỉ khi id
    // nằm trong set_range.
    bool is_refresh_always = true;
    // Sự kiện gỡ gói của thanh này và cấp mà nó đưa cho DataPool:UnInstall_RMB_ChatAction (cấp của thanh kế).
    std::string_view uninstall_event;
    std::int32_t uninstall_level = 0;
    // Thanh kế nhận Clear_ChatAction_Bar; rỗng thì thanh này là cuối chuỗi và gọi Set_RMB_ChatAction.
    std::string_view forward;
    // true: mỗi ô có cửa sổ hoạt ảnh <ô>_Mask mà <Tên>_PlayAnimate hiện và chạy (MainMenuBar_2).
    bool has_masks = false;
};

// Gói hành động chat cài ở một ô của kho (DataPool:Get_RMB_ChatActionInfo rồi Get_RMB_ChatActionRealID): ba cột
// của dòng DBC 0xfd ứng id gói và cột real id. Gói chưa cài là toàn số 0.
struct ChatPack {
    // Cột +4 của dòng; 0 là không có dòng hay gói chưa cài.
    std::int32_t real_id = 0;
    // Số hành động (cột +0x14) và chỉ số đầu trong danh sách mood của hệ action (cột +0x18).
    std::int32_t count = 0;
    std::int32_t min_index = 0;
    // Loại (cột +0x10); 2 là gói đôi, tra bằng Talk:EnumDoubleChatMood thay cho Talk:EnumChatMood.
    std::int32_t kind = 0;
};

inline constexpr std::size_t kChatPackSlots = 11;
inline constexpr std::int32_t kDoubleChatPack = 2;

// Kho gói hành động chat và hai danh sách mood của hệ action (id action của Talk:EnumChatMood(i):GetID() và
// Talk:EnumDoubleChatMood(i):GetID(); chỉ số ngoài danh sách là action rỗng, id 0).
struct ChatBook {
    std::array<ChatPack, kChatPackSlots> packs{};
    std::vector<std::int32_t> moods;
    std::vector<std::int32_t> double_moods;
};

// Hình học của một cửa sổ mà nhánh hướng dẫn tân thủ của MainMenuBar_2 hỏi. Khung dùng x, y là vị trí tuyệt đối
// (GetProperty "AbsoluteXPosition", "AbsoluteYPosition"); ô dùng x, y là độ lệch so với khung (this:GetChildOffset) và
// rộng, cao là AbsoluteWidth, AbsoluteHeight.
struct BarBox {
    double x = 0.0;
    double y = 0.0;
    double width = 0.0;
    double height = 0.0;
};

// Điều mà nhánh UI_COMMAND 20130527 của MainMenuBar_2 hỏi hệ hướng dẫn tân thủ, kho đồ và cửa sổ CEGUI. Nơi dùng tính
// trước khi phát sự kiện: put_* là hai giá trị PutItemToMainmenuBar2(Get_XParam_INT(0)) trả (nó đặt vật phẩm lên thanh,
// việc của kho đồ), owner là GetFreshManGuideOwner().
struct GuideFacts {
    std::int32_t put_is_show = 0;
    std::int32_t put_index = -1;
    BarBox frame;
    std::array<BarBox, 10> buttons{};
    std::string_view owner;
};

// Những điều của game mà script hỏi lúc xử lý sự kiện.
struct BarFacts {
    // Pet:IsPresent(n) và Pet:GetIsFighting(n) cùng đúng, n = 0..5.
    std::array<bool, 6> pet_is_fighting{};
    ChatBook chat;
    // Action mà hệ action biết (id và tên icon), để ô tìm icon cho id được đặt.
    std::span<const ActionFace> actions;
    // TLCJ:IsInTLCJScene() == 1.
    bool is_in_tlcj_scene = false;
    // DataPool:GetTrans(): trạng thái biến hình (1 là đang biến hình).
    std::int32_t transform = 0;
    // DataPool:LuaFnGetGMVisibleType() và ZBS:IsViewerWatching().
    std::int32_t gm_visible_type = 0;
    std::int32_t viewer_watching = 0;
    GuideFacts guide;
};

// Trạng thái của một thanh: các cửa sổ con script đã đụng tới, cờ hiện của chính nó (this:IsVisible()) và tên
// các cửa sổ, dựng từ spec bằng make_action_bar. spec phải sống lâu hơn thanh (là hằng của cửa sổ).
struct ActionBar {
    const BarSpec* spec = nullptr;
    Widgets widgets;
    bool is_shown = false;
    std::string root;
    std::vector<std::string> buttons;
    std::vector<std::string> juniors;
    std::vector<std::string> seniors;
    // Cửa sổ hoạt ảnh <ô>_Mask của từng ô (chỉ khi spec.has_masks).
    std::vector<std::string> masks;
    // g_IsShowDrawing của MainMenuBar_2: lớp hướng dẫn đang mở quanh một ô của thanh.
    bool is_drawing = false;
};

// Dựng thanh: đặt tên cửa sổ theo spec và ghi nhận hai dãy cửa sổ nháy là Visible=False của layout.
[[nodiscard]] ActionBar make_action_bar(const BarSpec& spec);

// Các sự kiện chung của nhóm: CHANGE_BAR, ACTION_UPDATE, FLASH_COMBOSKILL, HIDE_THIS_UI, sự kiện gỡ gói của thanh
// (spec.uninstall_event) và CLEAR_CHAT_ACTION_BAR. true là sự kiện thuộc nhóm và đã xử lý; false thì cửa sổ tự xử lý.
[[nodiscard]] bool on_bar_event(ActionBar& bar, const UiEvent& event, const BarFacts& facts, std::vector<Call>& calls);

// <Tên>_Clicked(id) của ô có id trong hệ thanh action (nhấn trái hay phải): can_do là DataPool:IsCanDoAction() lúc
// nhấn. id ngoài dải của thanh không ứng ô nào.
void press_bar_button(const ActionBar& bar, std::int32_t id, bool can_do, std::vector<Call>& calls);

// id (trong hệ thanh action) của ô action mang tên cửa sổ window; nullopt khi window không phải ô của thanh.
[[nodiscard]] std::optional<std::int32_t> bar_button_id(const ActionBar& bar, std::string_view window) noexcept;

// Chép trạng thái của thanh sang deck: hiện cửa sổ gốc khi this:IsVisible(), rồi các cửa sổ con.
void paint_action_bar(Deck& deck, const ActionBar& bar);

// DataPool:UnInstall_RMB_ChatAction(ô gói, cấp) (Game.exe 0x1402f30d0): cấp 0..5 đẩy một sự kiện của game (tên
// ghi trong bảng đăng ký sự kiện UI của Game.exe: 0x325..0x328, 0x38c, 0x38d) với đối số là ô gói; cấp 6 không đẩy sự
// kiện mà gửi gói tin CGRemoveRMBChatAction. nullopt cho cấp 6 và cấp ngoài 0..6.
[[nodiscard]] constexpr std::optional<std::string_view> uninstall_chat_action_event(std::int32_t level) noexcept {
    switch (level) {
    case 0: return "UNINSTALL_CHAT_ACTION_CONFIRM";
    case 1: return "UNINSTALL_CHAT_ACTION_BAR";
    case 2: return "UNINSTALL_CHAT_ACTION_BAR2";
    case 3: return "UNINSTALL_CHAT_ACTION_BAR3";
    case 4: return "UNINSTALL_CHAT_ACTION_BAR4";
    case 5: return "GE_UNINSTALL_CHAT_ACTION_BAR5";
    default: return std::nullopt;
    }
}

// Cấp mà DataPool:UnInstall_RMB_ChatAction gửi gói tin xoá thay vì đẩy sự kiện.
inline constexpr std::int32_t kUninstallByPacket = 6;

} // namespace game::ui::panel
