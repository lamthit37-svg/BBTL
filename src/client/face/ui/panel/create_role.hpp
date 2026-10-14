// Bảng tạo nhân vật (CreateRole/CreateRole.layout.xml): giới, chín ô ảnh chân dung mỗi trang, kiểu
// tóc, kiểu mặt, bộ đồ tân thủ, nút ngẫu nhiên, ô tên, xem trước môn phái, xoay và phóng người mẫu.
// Nguồn: Interface/CreateRole/CreateRole.lua của client 2026 (giải bằng TOOLS/content/lua_plain.py);
// mỗi hàm ở create_role.cpp là bản dịch một hàm của script, ghi vào Widgets đúng những lời gọi
// script làm, kể cả các thói quen lạ của nó (docs/TAO-NHAN-VAT-2026.md kể từng cái):
// - mũi tên và nút ngẫu nhiên của kiểu mặt chỉ đi qua số kiểu bằng số kiểu TÓC chọn được;
// - đổi giới không đặt lại dấu chọn của ô ảnh, trong khi ô sẽ dùng để tạo về ô đầu;
// - lật trang không dời ô đang chọn: tạo ở ô không có ảnh thì game báo "#{DLXZ_090711_1}".
// Test/Ui/ui_create_tests.cpp so trạng thái từng bước với trạng thái script gốc để lại khi chạy trên
// LuaPlus.dll của client 2026 với bảng thật (TOOLS/port/lua_oracle.py, Test/golden/panel/).
// Hàm của game mà script gọi (GameProduceLogin) là role_cast.hpp cho phần tra bảng và CreateGame
// cho phần game ghi nhớ; mỗi lời gọi còn để lại một Call để chuỗi đăng nhập làm tiếp và để test so.
// Khác gốc: chưa có máy chủ, nên GetIsForbidName luôn 0 (nút tên ngẫu nhiên luôn ẩn, sự kiện
// RESHOW_CREATE_PLAYERNAME không có) và không có môn phái bị khoá theo máy chủ
// (LoginCreateRole_DingZhiMenPai không làm gì); sự kiện GAMELOGIN_CANCEL_PREVIEW chưa có nơi phát;
// StartFade đổi độ trong ngay, không chạy nửa giây; Clicked chạy lúc nhấn chứ không lúc nhả; ô tên
// lọc ký tự ngay lúc gõ và nhận Enter như nút tạo.
#pragma once

#include "gui/scroll.hpp"
#include "gui/strings.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/widgets.hpp"

#include <array>
#include <cstdint>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

inline constexpr std::string_view kCreateLayout = "CreateRole/CreateRole.layout.xml";
// ShowModel(-1) và g_TempCurSel_MenPai = -1: không xem trước môn phái nào.
inline constexpr std::int32_t kNoMenpai = -1;
// g_iFaceIndexInPage = -1: chưa chọn ô ảnh nào (chỉ trước lần mở đầu tiên).
inline constexpr std::int32_t kNoHead = -1;
inline constexpr std::int32_t kNoModel = -1;
inline constexpr std::int32_t kMenpaiModel = 3;

// Điều bảng đọc của game khi xử lý một sự kiện. Con trỏ mượn phải sống tới hết lời gọi.
struct CreateFacts {
    // Bảng của màn tạo; nullptr thì mọi danh sách rỗng.
    const RoleCast* cast = nullptr;
    // Bản dịch tên kiểu mặt, kiểu tóc, bộ đồ theo khoá nguyên văn; nullptr hay chưa dịch thì hiện
    // tên gốc.
    const gui::StringBook* words = nullptr;
    // math.random(0, top) của script: một số trong [0, top], top không âm. Rỗng thì luôn 0; số
    // ngoài miền bị kẹp vào miền.
    std::function<std::int32_t(std::int32_t top)> roll;
};

// Điều thủ tục tạo nhân vật của game ghi nhớ (CGamePro_CharCreate của Game.exe): các hàm đặt của
// GameProduceLogin ghi vào đây; nơi vẽ người mẫu và nơi lưu nhân vật đọc ra.
struct CreateGame {
    // Giới và chỉ số bộ đồ tân thủ của người mẫu (ChangeNewRoleEquipSet).
    std::int32_t sex = kFemale;
    std::int32_t outfit = 0;
    // Id chân dung (SetFaceId), id kiểu mặt (SetFaceModelId), id kiểu tóc (SetHairModelId); 0 khi
    // chưa đặt hay chỉ số script đưa nằm ngoài bảng.
    std::int32_t portrait = 0;
    std::int32_t face = 0;
    std::int32_t hair = 0;
    // Môn phái đang xem trước (ShowModel).
    std::int32_t menpai = kNoMenpai;
    // Số vòng mỗi giây người mẫu đang quay (ModelRotBegin, ModelRotEnd) và hướng phóng (ModelZoom).
    std::int32_t spin = 0;
    std::int32_t zoom = 0;
    // Người mẫu đang là "hiện tại" của từng giới (hai ô +0x2e8 của thủ tục, chỉ số là giới):
    // kNoModel, 0..2 là bộ đồ tân thủ, kMenpaiModel + môn phái là người mẫu của môn đó.
    std::array<std::int32_t, 2> shown{kNoModel, kNoModel};
    // Số lần người mẫu của từng giới vừa thành hiện tại: mỗi lần như vậy game đặt hướng mặt về 0.
    std::array<std::uint32_t, 2> turns_back{};
    // Số lần thủ tục tạo được vào và giới nó đang nhớ lúc đó (camera vào màn theo giới này); số
    // lần ChangeNewRoleEquipSet (mỗi lần cho camera chạy về phía giới vừa đặt).
    std::uint32_t entries = 0;
    std::int32_t entry_sex = kFemale;
    std::uint32_t outfit_calls = 0;
};

// Nút xoay hay phóng người mẫu đang giữ chuột: nó nhận MouseButtonUp khi người chơi nhả.
enum class HeldButton : std::uint8_t { kNone, kTurnLeft, kTurnRight, kZoomOut, kZoomIn };

// Ô mô tả môn phái của khung xem trước (chữ dài của từng môn phái) và khung nền của nó. Ô này là
// khung cuộn chữ (gui::TextScroll): chữ dài hơn ô thì tự trôi lên, và lăn chuột trên khung thì cuộn.
inline constexpr std::string_view kCreateDetail = "Createshow_Info2";
inline constexpr std::string_view kCreateDetailFrame = "Createshow_Info2_Back";

// Nhịp của khung cuộn: đứng yên chừng này giây ở đầu, ở cuối và sau khi người chơi rời chuột, rồi
// trôi với tốc độ này (điểm ảnh mỗi giây; một dòng chữ cao chừng 19 điểm, tức chừng hai giây một
// dòng, kịp đọc theo).
inline constexpr float kDetailRest = 4.0F;
inline constexpr float kDetailSpeed = 10.0F;

// Chỗ cuộn của ô mô tả môn phái.
struct DetailScroll {
    // Khối chữ đã dời lên bao nhiêu điểm ảnh; luôn trong [0, gui::scroll_limit] của lần roll_detail
    // gần nhất.
    float position = 0.0F;
    // Giây còn đứng yên trước khi trôi tiếp.
    float rest = kDetailRest;
};

// Một khung của ô mô tả môn phái.
struct DetailRoll {
    // Cao khối chữ và cao ô theo lần dàn trang gần nhất; ô đang ẩn thì cả hai bằng 0.
    gui::ScrollSpan span;
    // Giây từ khung trước.
    float seconds = 0.0F;
    // Nấc lăn chuột của khung: dương là lăn lên (về đầu chữ). Chỉ đưa khi chuột nằm trên khung.
    std::int32_t notches = 0;
    // Chuột đang nằm trên khung: chữ đứng yên cho người chơi đọc.
    bool is_hovered = false;
};

// Trạng thái của bảng: cửa sổ đang giữ gì và các biến của script.
struct CreateRole {
    Widgets widgets;
    // this:IsVisible().
    bool is_shown = false;
    // LoginCreateRole_OnLoad đã chạy (client gốc chạy nó lúc nạp giao diện; ở đây là trước sự kiện
    // đầu tiên).
    bool is_loaded = false;
    // iCurSelSex.
    std::int32_t sex = kFemale;
    // g_iFaceIndexInPage, g_FacePageCount, g_iCurFaceCount.
    std::int32_t head = kNoHead;
    std::int32_t page = 0;
    std::int32_t portrait_count = 0;
    // g_iCurSelHairIndex, g_iCurSelectFace, g_iCurSelEquipSetIndex.
    std::int32_t hair = 0;
    std::int32_t face = 0;
    std::int32_t outfit = 0;
    // g_FaceModel: vị trí trong dãy kiểu mặt của giới của từng kiểu chọn được; script điền -1 cho
    // 21 ô đầu lúc nạp và không xoá khi đổi giới.
    std::vector<std::int32_t> face_models;
    // g_TempCurSel_MenPai.
    std::int32_t menpai = kNoMenpai;
    HeldButton held = HeldButton::kNone;
    // Cửa sổ đang nằm dưới chuột; rỗng khi không có.
    std::string hovered;
    CreateGame game;
    // Về đầu mỗi lần ô mô tả nhận chữ của một môn phái.
    DetailScroll detail;
};

// Sự kiện GAMELOGIN_OPEN_CREATE_CHARACTOR: hiện bảng, tên trống, giới nữ, trang đầu, ô ảnh đầu,
// tóc và mặt đầu, bộ đồ tân thủ ngẫu nhiên.
void open_create(CreateRole& panel, const CreateFacts& facts, std::vector<Call>& calls);
// Sự kiện GAMELOGIN_CLOSE_CREATE_CHARACTOR: giấu bảng.
void close_create(CreateRole& panel);

// Người chơi nhấn trái lên cửa sổ window: chạy hàm mà layout nối vào Clicked hay MouseLButtonDown
// của nó. Bảng đang ẩn, cửa sổ lạ, cửa sổ đang khoá hay nằm trong khung đang giấu thì không làm gì.
void press_create(CreateRole& panel, std::string_view window, const CreateFacts& facts, std::vector<Call>& calls);
// Người chơi nhả nút trái: nút xoay hay phóng đang giữ nhận MouseButtonUp.
void release_create(CreateRole& panel, std::vector<Call>& calls);
// Một khung của khung cuộn ô mô tả môn phái. Chữ vừa ô thì nằm yên ở đầu. Chữ dài hơn ô: nghỉ
// kDetailRest giây, trôi lên với kDetailSpeed tới hết chữ, nghỉ, về đầu rồi lặp lại; chuột nằm trên
// khung thì đứng yên, mỗi nấc lăn dời một bước gui::scroll_step. Không cấp phát.
// Khác gốc: bản 2026 không có phần này (xem gui::TextScroll).
void roll_detail(CreateRole& panel, const DetailRoll& roll) noexcept;
// Cửa sổ đang nằm dưới chuột (rỗng khi không có): đổi cửa sổ thì cửa sổ cũ nhận MouseLeave, cửa
// sổ mới nhận MouseEnter (dòng mô tả CreateRole_Info).
void hover_create(CreateRole& panel, std::string_view window);
// Một ký tự cho ô tên: Unicode trong trần 12 mã của layout, xoá lùi bỏ một mã, Enter như nút tạo.
// Ô tên đang giấu (đang xem trước môn phái) thì không nhận.
void type_create(CreateRole& panel, char32_t code, const CreateFacts& facts, std::vector<Call>& calls);

// Bộ ảnh mà bảng gán lúc chạy (nút môn phái, ảnh tên môn phái của khung giới thiệu). Script gốc
// đặt chúng bằng SetProperty nên layout không nhắc tới hết: nơi dựng giao diện phải nạp trọn các
// bộ này trước khi dàn trang. Mỗi bộ một lần, theo thứ tự gặp.
[[nodiscard]] std::vector<std::string_view> create_imagesets();
// Lời nhắn của game (GameLoginShowSystemInfo, tên không dùng được) hiện ở dòng mô tả
// CreateRole_Info cho tới lần rê chuột kế.
// Khác gốc: client gốc mở hộp thông báo của thủ tục đăng nhập; bảng đó chưa port.
void notify_create(CreateRole& panel, std::string_view text);

// CreateRole_Name:GetText(). Chuỗi sống tới lần sự kiện kế của bảng.
[[nodiscard]] std::string_view create_name(const CreateRole& panel) noexcept;

// Chép trạng thái của bảng sang deck khi bảng đang hiện.
void paint_create(Deck& deck, const CreateRole& panel);

} // namespace game::ui::panel
