// Bảng tạo nhân vật (xem create_role.hpp). Tên hàm gốc của CreateRole.lua ghi ở từng hàm.
#include "ui/panel/create_role.hpp"

#include "gui/content.hpp"
#include "gui/scroll.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/role_cast.hpp"
#include "ui/panel/roles.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <iterator>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::panel {
namespace {

// g_iFaceCountInPage, g_MenpaiButtonNum, MaxEquipIndex và số ô g_FaceModel mà OnLoad điền -1.
constexpr std::int32_t kHeadsPerPage = 9;
constexpr std::int32_t kMenpaiCount = 15;
constexpr std::int32_t kMaxEquipIndex = 2;
constexpr std::size_t kFaceModelSlots = 21;
// g_FaceModel[i] = -1: ô chưa có kiểu mặt nào.
constexpr std::int32_t kNoFaceModel = -1;

constexpr char32_t kBackspace = U'\b';
constexpr char32_t kTab = U'\t';
constexpr char32_t kEnter = U'\r';
constexpr char32_t kHash = U'#';
constexpr char32_t kDelete = 0x7F;
constexpr char32_t kSurrogateFirst = 0xD800;
constexpr char32_t kSurrogateLast = 0xDFFF;
constexpr char32_t kLastBmp = 0xFFFF;

constexpr std::string_view kRoot = "CreateRole_Frame";
constexpr std::string_view kModel = "CreateRole_Model";
constexpr std::string_view kInfoFrame = "CreateRole_Info_Frame";
constexpr std::string_view kInfo2Frame = "CreateRole_Info2_Frame";
constexpr std::string_view kInfo3Frame = "CreateRole_Info3_Frame";
constexpr std::string_view kName = "CreateRole_Name";
constexpr std::string_view kRandomName = "CreateRole_RandomName";
constexpr std::string_view kInfo = "CreateRole_Info";
constexpr std::string_view kShowInfo = "Createshow_Info";
constexpr std::string_view kShowInfo2 = kCreateDetail;
constexpr std::string_view kShowInfoBack = "Createshow_Info_Back";
constexpr std::string_view kMenpaiIcon = "CreateRole_Info2_Frame_Back2";
constexpr std::string_view kGirl = "CreateRole_SelectSex_Girl";
constexpr std::string_view kBoy = "CreateRole_SelectSex_Boy";
constexpr std::string_view kPreviewMan = "CreateRole_Info2_Frame_Back4";
constexpr std::string_view kPreviewWoman = "CreateRole_Info2_Frame_Back5";
constexpr std::string_view kPageUp = "CreateRole_PageUp";
constexpr std::string_view kPageDown = "CreateRole_PageDown";
constexpr std::string_view kHairLeft = "CreateRole_SelectHair_TurnLeft1";
constexpr std::string_view kHairRight = "CreateRole_SelectHair_TurnRight1";
constexpr std::string_view kHairText = "CreateRole_SelectHair_Text2";
constexpr std::string_view kFaceLeft = "CreateRole_SelectFace_TurnLeft1";
constexpr std::string_view kFaceRight = "CreateRole_SelectFace_TurnRight1";
constexpr std::string_view kFaceText = "CreateRole_SelectFace_Text2";
constexpr std::string_view kClothLeft = "CreateRole_SelectClothin_TurnLeft1";
constexpr std::string_view kClothRight = "CreateRole_SelectClothin_TurnRight1";
constexpr std::string_view kClothText = "CreateRole_SelectClothing_Text2";
constexpr std::string_view kRandom = "CreateRole_Random";
constexpr std::string_view kAuthor = "CreateRole_Author";
constexpr std::string_view kBack = "CreateRole_Last";
constexpr std::string_view kTurnLeft = "CreateRole_Role2_Model_TurnLeft";
constexpr std::string_view kTurnRight = "CreateRole_Role2_Model_TurnRight";
constexpr std::string_view kZoomOut = "CreateRole_ModelZoomOut";
constexpr std::string_view kZoomIn = "CreateRole_ModelZoomIn";

constexpr std::string_view kWoman = "CreateRole_Woman";
constexpr std::string_view kMan = "CreateRole_Man";
// Chữ script viết thẳng: "女", "男", "请选择头像!".
constexpr std::string_view kFemaleText = "Nữ";
constexpr std::string_view kMaleText = "Nam";
constexpr std::string_view kPickPortrait = "Hãy chọn ảnh chân dung!";
constexpr std::string_view kNoPortrait = "#{DLXZ_090711_1}";
constexpr std::string_view kRandomTip = "#{JSCJYH_121224_02}";
constexpr std::string_view kRandomNameTip = "#{TCMZ_211027_2}";
constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";
constexpr std::string_view kClear = "0";
constexpr std::string_view kSolid = "1";

// g_FaceSel và g_FaceBorder: ảnh và nút chọn của chín ô chân dung.
constexpr std::array<std::string_view, kHeadsPerPage> kHeadImages = {
    "CreateRole_Select_HeadImage1", "CreateRole_Select_HeadImage2", "CreateRole_Select_HeadImage3",
    "CreateRole_Select_HeadImage4", "CreateRole_Select_HeadImage5", "CreateRole_Select_HeadImage6",
    "CreateRole_Select_HeadImage7", "CreateRole_Select_HeadImage8", "CreateRole_Select_HeadImage9",
};
constexpr std::array<std::string_view, kHeadsPerPage> kHeadButtons = {
    "CreateRole_Select_Head1", "CreateRole_Select_Head2", "CreateRole_Select_Head3",
    "CreateRole_Select_Head4", "CreateRole_Select_Head5", "CreateRole_Select_Head6",
    "CreateRole_Select_Head7", "CreateRole_Select_Head8", "CreateRole_Select_Head9",
};
// Các nút đánh dấu cùng cha (CheckMode 1: bật một nút thì các nút kia tắt).
constexpr std::array<std::string_view, 2> kSexButtons = {kGirl, kBoy};
constexpr std::array<std::string_view, 2> kPreviewButtons = {kPreviewMan, kPreviewWoman};

// g_MenpaiControl: ô 0 là nút thôi xem trước, ô 1..15 là mười lăm môn phái.
constexpr std::array<std::string_view, kMenpaiCount + 1> kMenpaiControl = {
    "CreateRole_MenpaiModel00", "CreateRole_MenpaiModel01", "CreateRole_MenpaiModel02", "CreateRole_MenpaiModel03",
    "CreateRole_MenpaiModel04", "CreateRole_MenpaiModel05", "CreateRole_MenpaiModel06", "CreateRole_MenpaiModel07",
    "CreateRole_MenpaiModel08", "CreateRole_MenpaiModel09", "CreateRole_MenpaiModel10", "CreateRole_MenpaiModel11",
    "CreateRole_MenpaiModel12", "CreateRole_MenpaiModel13", "CreateRole_MenpaiModel14", "CreateRole_MenpaiModel15",
};
// g_MenpaiNormalImageList và g_MenpaiDisableImageList, nhánh cổ điển (IsClassic của bản 2026 luôn
// trả 1).
constexpr std::array<std::string_view, kMenpaiCount + 1> kMenpaiNormal = {
    "set:CreateRole2 image:BtnCancel_Normal",      "set:MainFrameLuo03 image:Cs_Shaolin_Normal",
    "set:MainFrameLuo03 image:Cs_Mingjiao_Normal", "set:MainFrameLuo03 image:Cs_Gaibang_Normal",
    "set:MainFrameLuo05 image:Cs_Wudang_Normal",   "set:MainFrameLuo03 image:Cs_Emei_Normal",
    "set:MainFrameLuo05 image:Cs_Xingxiu_Normal",  "set:MainFrameLuo03 image:Cs_Tianlong_Normal",
    "set:MainFrameLuo04 image:Cs_Tianshan_Normal", "set:MainFrameLuo05 image:Cs_Xiaoyao_Normal",
    "set:MainFrameLuo03 image:Cs_Murong_Normal",   "set:MainFrameLuo05 image:Cs_Tangmen_Normal",
    "set:MainFrameLuo05 image:Cs_Guigu_Normal",    "set:MainFrameLuo05 image:Cs_Kunlun_Normal",
    "set:MainFrameLuo06 image:Cs_Congren_Normal",  "set:MainFrameLuo06 image:Cs_ERenGu_Normal",
};
constexpr std::array<std::string_view, kMenpaiCount + 1> kMenpaiDisable = {
    "set:CreateRole2 image:BtnCancel_Disable",     "set:MainFrameLuo03 image:Cs_Shaolin_Pushed",
    "set:MainFrameLuo03 image:Cs_Mingjiao_Pushed", "set:MainFrameLuo03 image:Cs_Gaibang_Pushed",
    "set:MainFrameLuo05 image:Cs_Wudang_Pushed",   "set:MainFrameLuo03 image:Cs_Emei_Pushed",
    "set:MainFrameLuo05 image:Cs_Xingxiu_Pushed",  "set:MainFrameLuo04 image:Cs_Tianlong_Pushed",
    "set:MainFrameLuo04 image:Cs_Tianshan_Pushed", "set:MainFrameLuo05 image:Cs_Xiaoyao_Pushed",
    "set:MainFrameLuo03 image:Cs_Murong_Pushed",   "set:MainFrameLuo05 image:Cs_Tangmen_Pushed",
    "set:MainFrameLuo05 image:Cs_Guigu_Pushed",    "set:MainFrameLuo05 image:Cs_Kunlun_Pushed",
    "set:MainFrameLuo06 image:Cs_Congren_Pushed",  "set:MainFrameLuo06 image:Cs_ERenGu_Pushed",
};
// g_MenpaiIntroduction: ô 0 là lời mời xem trước, ô 1..15 là lời giới thiệu ngắn của từng môn.
constexpr std::array<std::string_view, kMenpaiCount + 1> kMenpaiIntro = {
    "#{XZRW_XML_0}",     "#{XZRW_XML_1}",      "#{XZRW_XML_2}",      "#{XZRW_XML_3}",
    "#{XZRW_XML_4}",     "#{XZRW_XML_5}",      "#{XZRW_XML_6}",      "#{XZRW_XML_7}",
    "#{XZRW_XML_8}",     "#{XZRW_XML_9}",      "#{XZRW_XML_10}",     "#{XMPTM_130823_4}",
    "#{XMPGG_160615_34}", "#{THDBQ_190809_08}", "#{XMPHM_210604_06}", "#{XMPHM_210604_29}",
};
// g_Ex_MenpaiIntroduction và g_MenpaiBgImageControl của môn 0..14.
constexpr std::array<std::string_view, kMenpaiCount> kMenpaiDetail = {
    "#{JSCJYH_121224_04}", "#{JSCJYH_121224_06}", "#{JSCJYH_121224_05}", "#{JSCJYH_121224_07}", "#{JSCJYH_121224_09}",
    "#{JSCJYH_121224_11}", "#{JSCJYH_121224_08}", "#{JSCJYH_121224_12}", "#{JSCJYH_121224_10}", "#{JSCJYH_121224_13}",
    "#{XMPTM_130123_06}",  "#{XMPGG_160615_35}",  "#{THDBQ_190809_07}",  "#{XMPHM_210604_05}",  "#{XMPHM_210604_28}",
};
constexpr std::array<std::string_view, kMenpaiCount> kMenpaiIcons = {
    "set:CreateRole3 image:Icon_Shaolin",  "set:CreateRole4 image:Icon_Mingjiao", "set:CreateRole3 image:Icon_Gaibang",
    "set:CreateRole4 image:Icon_Wudang",   "set:CreateRole4 image:Icon_Emei",     "set:CreateRole3 image:Icon_Xingxiu",
    "set:CreateRole4 image:Icon_Tianlong", "set:CreateRole3 image:Icon_Tianshan", "set:CreateRole4 image:Icon_Xiaoyao",
    "set:CreateRole3 image:Icon_Murong",   "set:CreateRole5 image:Icon_Tangmen",  "set:CreateRole5 image:Icon_Guigu",
    "set:CreateRole5 image:Icon_Kunlun",   "set:CreateRole5 image:Icon_Hongming", "set:CreateRole5 image:Icon_ERenGu",
};
// g_Description[1..24]: dòng mô tả khi rê chuột; ô 0 không có trong script.
constexpr std::array<std::string_view, 25> kDescription = {
    "",
    "#{DLJM_XML_16}",    "#{DLJM_XML_17}",     "#{DLJM_XML_18}",     "#{DLJM_XML_19}",     "#{DLJM_XML_20}",
    "#{DLJM_XML_21}",    "#{DLJM_XML_22}",     "#{DLJM_XML_23}",     "#{DLJM_XML_24}",     "#{DLJM_XML_25}",
    "#{DLJM_XML_26}",    "#{DLJM_XML_27}",     "#{DLJM_XML_28}",     "#{DLJM_XML_29}",     "#{DLJM_XML_30}",
    "#{DLJM_XML_31}",    "#{DLJM_XML_32}",     "#{DLJM_XML_33}",     "#{DLJM_XML_34}",     "#{XMPTM_130823_3}",
    "#{XMPGG_160615_33}", "#{THDBQ_190809_09}", "#{XMPHM_210604_04}", "#{XMPHM_210604_27}",
};
// Số mà layout đưa cho CreateRole_MouseEnter: ô tên, hai nút giới, ô ảnh, nút tạo, nút quay lại;
// nút môn phái thứ n (00 là thôi xem trước) nhận 9 + n.
constexpr std::int32_t kNameTip = 1;
constexpr std::int32_t kSexTip = 4;
constexpr std::int32_t kHeadTip = 5;
constexpr std::int32_t kCreateTip = 7;
constexpr std::int32_t kBackTip = 8;
constexpr std::int32_t kMenpaiTipBase = 10;

const RoleCast& cast_of(const CreateFacts& facts) {
    static const RoleCast kNone;
    return facts.cast == nullptr ? kNone : *facts.cast;
}

// Bản dịch của một tên gốc theo khoá nguyên văn; chưa dịch thì chính tên gốc.
[[nodiscard]] std::string_view translated(const CreateFacts& facts, std::string_view name) noexcept {
    if (facts.words == nullptr) return name;
    return facts.words->find_literal(name).value_or(name);
}

// math.random(0, top) của script; top không âm.
[[nodiscard]] std::int32_t roll(const CreateFacts& facts, std::int32_t top) {
    if (!facts.roll) return 0;
    return std::clamp(facts.roll(top), 0, top);
}

void put(Widgets& widgets, std::string_view window, std::string_view name, std::string_view value) {
    widgets.set(gui::Override{.window = window, .name = name, .value = value});
}

void note(std::vector<Call>& calls, Ask ask, std::string text) {
    calls.push_back(Call{.ask = ask, .text = std::move(text)});
}

// Phần tử thứ index của một bảng hằng; rỗng khi index ngoài bảng.
template <std::size_t Count>
[[nodiscard]] std::string_view entry(const std::array<std::string_view, Count>& table, std::int32_t index) noexcept {
    if (index < 0 || std::cmp_greater_equal(index, Count)) return {};
    return *std::next(table.begin(), index);
}

// g_FaceModel[index]; ô chưa có (kể cả index ngoài dãy đang giữ) là kNoFaceModel.
// Khác gốc: script đọc ô ngoài bảng ra nil rồi dừng với lỗi tham số của GetFaceModelName; ở đây ô
// đó như một ô trống, tức "không có kiểu mặt".
[[nodiscard]] std::int32_t face_model(const CreateRole& panel, std::int32_t index) noexcept {
    if (index < 0 || std::cmp_greater_equal(index, panel.face_models.size())) return kNoFaceModel;
    return *std::next(panel.face_models.begin(), index);
}

[[nodiscard]] CastRow row_of(const CreateRole& panel, std::int32_t index) noexcept {
    return CastRow{.sex = panel.sex, .index = index};
}

// Thủ tục ShowModel của game (0x140640450), chạy cho cả hai giới. Người mẫu đang là hiện tại của
// một giới mà vẫn đúng là thứ cần hiện thì chỉ đổi ẩn hiện; khác thì bỏ, rồi chỉ giới game đang
// nhớ mới nhận người mẫu mới, và người mẫu vừa nhận quay mặt về hướng 0. Vì thế đổi giới rồi đổi
// lại với cùng bộ đồ thì người mẫu cũ còn nguyên hướng đang quay dở.
void settle_models(CreateGame& game, std::int32_t menpai) noexcept {
    const bool is_menpai = menpai >= 0 && menpai < kMenpaiCount;
    const std::int32_t wanted = is_menpai ? kMenpaiModel + menpai : game.outfit;
    if (!is_menpai && (game.outfit < 0 || game.outfit > 2)) return;
    for (std::size_t sex = 0; sex < game.shown.size(); ++sex) {
        std::int32_t& current = *std::next(game.shown.begin(), static_cast<std::ptrdiff_t>(sex));
        if (current == wanted) continue;
        current = kNoModel;
        if (std::cmp_not_equal(sex, game.sex)) continue;
        current = wanted;
        ++*std::next(game.turns_back.begin(), static_cast<std::ptrdiff_t>(sex));
    }
}

// GameProduceLogin:ShowModel(menpai) (0x140343300).
void show_model(CreateRole& panel, std::int32_t menpai, std::vector<Call>& calls) {
    panel.game.menpai = menpai;
    settle_models(panel.game, menpai);
    note(calls, Ask::kShowModel, std::to_string(menpai));
}

// GameProduceLogin:SetHairModelId(giới, chỉ số) (0x140342e10): chỉ số ngoài bảng thì game ghi id 0.
void set_hair_model(CreateRole& panel, const CreateFacts& facts, std::int32_t index, std::vector<Call>& calls) {
    const std::int32_t id = cast_of(facts).hair_id(row_of(panel, index));
    panel.game.hair = id;
    note(calls, Ask::kSetHairModelId, std::format("{}\t{}\t{}", panel.sex, index, id));
}

// GameProduceLogin:SetFaceModelId(giới, chỉ số) (0x140342c20).
void set_face_model(CreateRole& panel, const CreateFacts& facts, std::int32_t index, std::vector<Call>& calls) {
    const std::int32_t id = cast_of(facts).face_id(row_of(panel, index));
    panel.game.face = id;
    note(calls, Ask::kSetFaceModelId, std::format("{}\t{}\t{}", panel.sex, index, id));
}

// GameProduceLogin:ChangeNewRoleEquipSet(giới, chỉ số) (0x1403434b0, thủ tục ở 0x140641210): nhớ
// giới và chỉ số trước rồi mới tra dòng; tra được thì camera chạy về phía giới đó và thủ tục tự gọi
// ShowModel(-1).
void change_equip_set(CreateRole& panel, const CreateFacts& facts, std::int32_t index, std::vector<Call>& calls) {
    panel.game.sex = panel.sex;
    panel.game.outfit = index;
    const NewbieOutfit* outfit = cast_of(facts).outfit(index);
    if (outfit != nullptr) {
        ++panel.game.outfit_calls;
        settle_models(panel.game, kNoMenpai);
    }
    std::string text = std::format("{}\t{}", panel.sex, index);
    if (outfit != nullptr) text += std::format("\t{}", outfit->id);
    note(calls, Ask::kChangeNewRoleEquipSet, std::move(text));
}

// GameProduceLogin:SetFaceId(giới, chỉ số) (0x140342950): chỉ ghi khi dòng chọn được lúc tạo.
void set_portrait(CreateRole& panel, const CreateFacts& facts, std::int32_t index, std::vector<Call>& calls) {
    const std::optional<std::int32_t> id = cast_of(facts).portrait_id(row_of(panel, index));
    if (!id) return;
    panel.game.portrait = *id;
    note(calls, Ask::kSetFaceId, std::format("{}\t{}\t{}", panel.sex, index, *id));
}

// CreateRole_Info_Frame:GetAlpha() nhỏ hơn 1: khung tuỳ chọn đang mờ hẳn.
[[nodiscard]] bool is_info_clear(const Widgets& widgets) noexcept {
    return widgets.value(Key{.window = kInfoFrame, .name = "Alpha"}) == kClear;
}

// Đoạn mờ dần cuối CreateRole_BnClickMenpaiModel và CreateRole_BnClickMenpaiModelEx: thôi xem
// trước thì khung tuỳ chọn rõ lại, xem trước thì mờ hẳn; đã ở mức đó thì không gọi StartFade.
void fade_info(Widgets& widgets, std::int32_t menpai) {
    const bool is_clear = is_info_clear(widgets);
    if (menpai < 0 && is_clear) put(widgets, kInfoFrame, "Alpha", kSolid);
    if (menpai >= 0 && !is_clear) put(widgets, kInfoFrame, "Alpha", kClear);
}

// Vòng đầu của hai hàm xem trước: mọi nút môn phái mở khoá và về ảnh thường.
void reset_menpai_buttons(Widgets& widgets) {
    for (std::int32_t index = 0; index <= kMenpaiCount; ++index) {
        widgets.enable(entry(kMenpaiControl, index));
        put(widgets, entry(kMenpaiControl, index), "NormalImage", entry(kMenpaiNormal, index));
    }
}

// Phần chung của nhánh "thôi xem trước" ở hai hàm xem trước.
void show_customizer(CreateRole& panel) {
    Widgets& widgets = panel.widgets;
    put(widgets, kMenpaiControl[0], "NormalImage", kMenpaiDisable[0]);
    widgets.enable(kInfoFrame);
    widgets.hide(kMenpaiControl[0]);
    widgets.show(kName);
    widgets.set_text(kShowInfo, kMenpaiIntro[0]);
}

// Phần chung của nhánh "xem trước môn menpai" (0..14) ở hai hàm xem trước.
void show_menpai(CreateRole& panel, std::int32_t menpai) {
    Widgets& widgets = panel.widgets;
    widgets.enable(kMenpaiControl[0]);
    widgets.show(kMenpaiControl[0]);
    put(widgets, entry(kMenpaiControl, menpai + 1), "NormalImage", entry(kMenpaiDisable, menpai + 1));
    widgets.disable(kInfoFrame);
    widgets.hide(kName);
    widgets.set_text(kShowInfo, entry(kMenpaiIntro, menpai + 1));
    widgets.set_text(kShowInfo2, entry(kMenpaiDetail, menpai));
    panel.detail = DetailScroll{};
    put(widgets, kMenpaiIcon, "Image", entry(kMenpaiIcons, menpai));
}

// CreateRole_BnClickMenpaiModel(menpai): -1 là thôi xem trước, 0..14 là xem trước một môn phái.
void click_menpai(CreateRole& panel, std::int32_t menpai, std::vector<Call>& calls) {
    Widgets& widgets = panel.widgets;
    show_model(panel, kNoMenpai, calls);
    reset_menpai_buttons(widgets);
    if (menpai < 0) {
        show_customizer(panel);
        widgets.show(kInfo3Frame);
        widgets.set_text(kShowInfo2, "");
        widgets.hide(kInfo2Frame);
        panel.menpai = kNoMenpai;
        widgets.show(kInfoFrame);
    }
    if (menpai >= 0 && menpai < kMenpaiCount) {
        show_menpai(panel, menpai);
        widgets.hide(kInfo3Frame);
        widgets.show(kInfo2Frame);
        panel.menpai = menpai;
        widgets.check(panel.sex == kFemale ? kPreviewMan : kPreviewWoman, false);
        widgets.check_one(panel.sex == kFemale ? kPreviewWoman : kPreviewMan, kPreviewButtons);
    }
    show_model(panel, menpai, calls);
    fade_info(widgets, menpai);
}

// CreateRole_BnClickMenpaiModelEx(menpai): bản dùng sau khi đổi giới lúc đang xem trước; không dựng
// lại người mẫu trước và giấu hẳn khung tuỳ chọn.
void click_menpai_again(CreateRole& panel, std::int32_t menpai, std::vector<Call>& calls) {
    Widgets& widgets = panel.widgets;
    reset_menpai_buttons(widgets);
    if (menpai < 0) {
        show_customizer(panel);
        widgets.set_text(kShowInfo2, "");
        panel.menpai = kNoMenpai;
    }
    if (menpai >= 0 && menpai < kMenpaiCount) {
        show_menpai(panel, menpai);
        panel.menpai = menpai;
    }
    widgets.hide(kInfoFrame);
    show_model(panel, menpai, calls);
    fade_info(widgets, menpai);
}

// CreateRole_RestoreCharacter.
void restore_character(CreateRole& panel, std::vector<Call>& calls) {
    click_menpai(panel, kNoMenpai, calls);
    panel.widgets.show(kInfo3Frame);
}

// CreateRole_ClearImageData.
void clear_images(Widgets& widgets) {
    widgets.disable(kPageUp);
    widgets.disable(kPageDown);
    for (const std::string_view image : kHeadImages) put(widgets, image, "Image", "");
}

// CreateRole_RefreshCurShowFacePage: chín ô của trang đang xem, ô thừa để trống.
void refresh_page(CreateRole& panel, const CreateFacts& facts) {
    clear_images(panel.widgets);
    const std::int64_t start = std::int64_t{panel.page} * kHeadsPerPage;
    const std::int64_t stop = std::min<std::int64_t>(start + kHeadsPerPage, panel.portrait_count);
    for (std::int64_t index = start; index < stop; ++index) {
        const std::string_view image = cast_of(facts).portrait_image(row_of(panel, static_cast<std::int32_t>(index)));
        put(panel.widgets, entry(kHeadImages, static_cast<std::int32_t>(index - start)), "Image", image);
    }
}

// CreateRole_SetFacePageStatus: nút lật trang nào còn trang để lật thì mở khoá.
void set_page_status(CreateRole& panel) {
    Widgets& widgets = panel.widgets;
    if (panel.page - 1 < 0) widgets.disable(kPageUp);
    if (panel.page - 1 >= 0) widgets.enable(kPageUp);
    const bool is_last = (std::int64_t{panel.page} + 1) * kHeadsPerPage >= panel.portrait_count;
    if (is_last) widgets.disable(kPageDown);
    if (!is_last) widgets.enable(kPageDown);
}

// CreateRole_ShowRoleFace(giới).
void show_role_face(CreateRole& panel, const CreateFacts& facts) {
    clear_images(panel.widgets);
    panel.portrait_count = cast_of(facts).portrait_count(panel.sex);
    refresh_page(panel, facts);
    set_page_status(panel);
}

// CreateRole_BnClickFacePageUp.
void page_up(CreateRole& panel, const CreateFacts& facts) {
    if (panel.page <= 0) {
        panel.page = 0;
        return;
    }
    --panel.page;
    refresh_page(panel, facts);
    set_page_status(panel);
}

// CreateRole_BnClickFacePageDown.
void page_down(CreateRole& panel, const CreateFacts& facts) {
    if ((std::int64_t{panel.page} + 1) * kHeadsPerPage >= panel.portrait_count) return;
    ++panel.page;
    refresh_page(panel, facts);
    set_page_status(panel);
}

// CreateRole_GetFaceModel: vị trí của các kiểu mặt chọn được (choice 1 hay 3) của giới đang chọn,
// ghi lần lượt từ ô 0; ô sau đó giữ giá trị cũ. O(số dòng kiểu mặt của giới).
void collect_face_models(CreateRole& panel, const CreateFacts& facts) {
    const RoleCast& cast = cast_of(facts);
    const std::int32_t count = cast.face_count(panel.sex);
    std::size_t slot = 0;
    for (std::int32_t index = 0; index < count; ++index) {
        const std::int32_t choice = cast.face_choice(row_of(panel, index));
        if (choice != 3 && choice != 1) continue;
        if (slot == panel.face_models.size()) panel.face_models.push_back(kNoFaceModel);
        panel.face_models[slot] = index;
        ++slot;
    }
}

// CreateRole_SelHairModel(chỉ số).
void select_hair(CreateRole& panel, const CreateFacts& facts, std::int32_t index, std::vector<Call>& calls) {
    const std::string_view name = cast_of(facts).hair_name(row_of(panel, index));
    panel.widgets.set_text(kHairText, translated(facts, name));
    set_hair_model(panel, facts, index, calls);
}

// CreateRole_SelFaceModel(chỉ số trong dãy kiểu mặt của giới).
void select_face(CreateRole& panel, const CreateFacts& facts, std::int32_t index, std::vector<Call>& calls) {
    const std::string_view name = cast_of(facts).face_name(row_of(panel, index));
    panel.widgets.set_text(kFaceText, translated(facts, name));
    set_face_model(panel, facts, index, calls);
}

// CreateRole_SelEquipSet(chỉ số).
void select_outfit(CreateRole& panel, const CreateFacts& facts, std::int32_t index, std::vector<Call>& calls) {
    const std::string_view name = cast_of(facts).outfit_name(index);
    panel.widgets.set_text(kClothText, translated(facts, name));
    change_equip_set(panel, facts, index, calls);
}

// CreateRole_SelectGirl và CreateRole_SelectBoy (hai hàm chỉ khác giới, fake object, nút giới và
// một lần RefreshCurShowFacePage thừa ở bản nữ, không đổi kết quả).
void select_sex(CreateRole& panel, std::int32_t sex, const CreateFacts& facts, std::vector<Call>& calls) {
    Widgets& widgets = panel.widgets;
    put(widgets, kModel, "FakeObject", sex == kFemale ? kWoman : kMan);
    widgets.check_one(sex == kFemale ? kGirl : kBoy, kSexButtons);
    panel.sex = sex;
    panel.page = 0;
    show_role_face(panel, facts);
    panel.head = 0;
    set_page_status(panel);
    collect_face_models(panel, facts);
    panel.hair = 0;
    select_hair(panel, facts, panel.hair, calls);
    select_face(panel, facts, face_model(panel, 0), calls);
    panel.outfit = roll(facts, kMaxEquipIndex);
    select_outfit(panel, facts, panel.outfit, calls);
}

// CreateRole_SelectHair_GetMaxValidHairIndex: chỉ số lớn nhất dùng được của kiểu tóc.
[[nodiscard]] std::int32_t max_hair(const CreateRole& panel, const CreateFacts& facts) {
    const RoleCast& cast = cast_of(facts);
    const std::int32_t count = cast.hair_count(panel.sex);
    for (std::int32_t index = 0; index < count; ++index) {
        if (cast.hair_name(row_of(panel, index)).empty()) return index;
    }
    return count - 1;
}

// CreateRole_SelectFace_GetMaxValidFaceIndex. Script lấy số kiểu TÓC làm số kiểu mặt
// (GetHairModelCount), nên mũi tên và nút ngẫu nhiên chỉ tới được chừng ấy kiểu mặt đầu; giữ nguyên.
[[nodiscard]] std::int32_t max_face(const CreateRole& panel, const CreateFacts& facts) {
    const RoleCast& cast = cast_of(facts);
    const std::int32_t count = cast.hair_count(panel.sex);
    for (std::int32_t index = 0; index < count; ++index) {
        if (cast.face_name(row_of(panel, face_model(panel, index))).empty()) return index;
    }
    return count - 1;
}

// CreateRole_SelectClothin_GetMaxValidClothinIndex.
[[nodiscard]] std::int32_t max_outfit(const CreateFacts& facts) {
    const RoleCast& cast = cast_of(facts);
    const std::int32_t count = cast.outfit_count();
    for (std::int32_t index = 0; index < count; ++index) {
        if (cast.outfit_name(index).empty()) return index;
    }
    return count - 1;
}

// Chỉ số kế của một mũi tên: lùi từ đầu thì về cuối, tiến từ cuối thì về đầu.
[[nodiscard]] constexpr std::int32_t stepped(std::int32_t now, std::int32_t last, bool is_next) noexcept {
    if (is_next) return now >= last ? 0 : now + 1;
    return now <= 0 ? last : now - 1;
}

// CreateRole_SelectHair_TurnLeft1_Clicked và TurnRight1_Clicked.
void step_hair(CreateRole& panel, bool is_next, const CreateFacts& facts, std::vector<Call>& calls) {
    const std::int32_t wanted = stepped(panel.hair, max_hair(panel, facts), is_next);
    if (cast_of(facts).hair_name(row_of(panel, wanted)).empty()) return;
    restore_character(panel, calls);
    panel.hair = wanted;
    select_hair(panel, facts, panel.hair, calls);
}

// CreateRole_SelectFace_TurnLeft1_Clicked và TurnRight1_Clicked.
void step_face(CreateRole& panel, bool is_next, const CreateFacts& facts, std::vector<Call>& calls) {
    const std::int32_t wanted = stepped(panel.face, max_face(panel, facts), is_next);
    if (cast_of(facts).face_name(row_of(panel, face_model(panel, wanted))).empty()) return;
    panel.face = wanted;
    restore_character(panel, calls);
    select_face(panel, facts, face_model(panel, panel.face), calls);
}

// CreateRole_SelectClothin_TurnLeft1_Clicked và TurnRight1_Clicked.
void step_outfit(CreateRole& panel, bool is_next, const CreateFacts& facts, std::vector<Call>& calls) {
    const std::int32_t wanted = stepped(panel.outfit, max_outfit(facts), is_next);
    const std::string_view name = cast_of(facts).outfit_name(wanted);
    if (name.empty()) return;
    panel.outfit = wanted;
    restore_character(panel, calls);
    panel.widgets.set_text(kClothText, translated(facts, name));
    change_equip_set(panel, facts, panel.outfit, calls);
}

// CreateRole_Random_Clicked: tóc, mặt, bộ đồ ngẫu nhiên; ba lần math.random theo đúng thứ tự đó.
// Khác gốc: không có kiểu tóc nào thì math.random(0, -1) của script ném lỗi và hàm dừng; ở đây
// hàm thôi ngay từ đầu, cùng kết quả là không đổi gì.
void click_random(CreateRole& panel, const CreateFacts& facts, std::vector<Call>& calls) {
    const std::int32_t top_hair = max_hair(panel, facts);
    const std::int32_t top_face = max_face(panel, facts);
    if (top_hair < 0 || top_face < 0) return;
    const std::int32_t hair = roll(facts, top_hair);
    const std::int32_t face = roll(facts, top_face);
    const std::int32_t outfit = roll(facts, kMaxEquipIndex);
    restore_character(panel, calls);
    panel.outfit = outfit;
    panel.widgets.set_text(kClothText, translated(facts, cast_of(facts).outfit_name(outfit)));
    change_equip_set(panel, facts, panel.outfit, calls);
    panel.face = face;
    select_face(panel, facts, face_model(panel, panel.face), calls);
    panel.hair = hair;
    select_hair(panel, facts, panel.hair, calls);
}

// CreateRole_BnClickCreateRole: ô đang chọn của trang đang xem thành ảnh chân dung của nhân vật;
// ô đó không có ảnh thì game báo và không tạo.
void click_create(CreateRole& panel, const CreateFacts& facts, std::vector<Call>& calls) {
    if (panel.head < 0) {
        note(calls, Ask::kShowSystemInfo, std::string(kPickPortrait));
        return;
    }
    const std::int64_t chosen = (std::int64_t{panel.page} * kHeadsPerPage) + panel.head;
    const std::int32_t index = chosen >= panel.portrait_count ? -1 : static_cast<std::int32_t>(chosen);
    set_portrait(panel, facts, index, calls);
    if (cast_of(facts).portrait_image(row_of(panel, index)).empty()) {
        note(calls, Ask::kShowSystemInfo, std::string(kNoPortrait));
        return;
    }
    note(calls, Ask::kCreateRole, std::format("{}\t{}\t-1\t-1", create_name(panel), panel.sex));
}

// CreateRole_Preview_Man_Clicked và CreateRole_Preview_Woman_Clicked: đổi giới lúc đang xem trước
// một môn phái, rồi xem trước lại môn đó.
void click_preview_sex(CreateRole& panel, std::int32_t sex, const CreateFacts& facts, std::vector<Call>& calls) {
    panel.sex = sex;
    const std::int32_t menpai = panel.menpai;
    show_model(panel, kNoMenpai, calls);
    select_sex(panel, sex, facts, calls);
    if (menpai >= 0) click_menpai_again(panel, menpai, calls);
}

// LoginCreateRole_OnLoad: chữ và kiểu của hai nút giới, 21 ô kiểu mặt trống, dãy kiểu mặt của giới
// nữ và một lần math.random cho bộ đồ (mở bảng sẽ gieo lại).
void load(CreateRole& panel, const CreateFacts& facts) {
    Widgets& widgets = panel.widgets;
    widgets.set_text(kGirl, kFemaleText);
    widgets.set_text(kBoy, kMaleText);
    put(widgets, kGirl, "CheckMode", "1");
    put(widgets, kBoy, "CheckMode", "1");
    panel.face_models.assign(kFaceModelSlots, kNoFaceModel);
    collect_face_models(panel, facts);
    panel.outfit = roll(facts, kMaxEquipIndex);
    panel.is_loaded = true;
}

// Số n của cửa sổ "<prefix><n>" với n có đúng digits chữ số; nullopt khi không khớp.
[[nodiscard]] std::optional<std::int32_t> numbered(std::string_view window, std::string_view prefix, std::size_t digits) {
    if (!window.starts_with(prefix) || window.size() != prefix.size() + digits) return std::nullopt;
    std::int32_t number = 0;
    for (const char digit : window.substr(prefix.size())) {
        if (digit < '0' || digit > '9') return std::nullopt;
        number = (number * 10) + (digit - '0');
    }
    return number;
}

// Môn phái của nút CreateRole_MenpaiModelNN: 00 là kNoMenpai, 01..15 là 0..14.
[[nodiscard]] std::optional<std::int32_t> menpai_of(std::string_view window) {
    const std::optional<std::int32_t> number = numbered(window, "CreateRole_MenpaiModel", 2);
    if (!number || *number > kMenpaiCount) return std::nullopt;
    return *number - 1;
}

// Ô (0..8) của nút CreateRole_Select_HeadN.
[[nodiscard]] std::optional<std::int32_t> head_of(std::string_view window) {
    const std::optional<std::int32_t> number = numbered(window, "CreateRole_Select_Head", 1);
    if (!number || *number < 1) return std::nullopt;
    return *number - 1;
}

// Số mà layout đưa cho CreateRole_MouseEnter ở cửa sổ window; 0 khi cửa sổ không nối hàm đó.
[[nodiscard]] std::int32_t tip_number(std::string_view window) {
    if (const std::optional<std::int32_t> menpai = menpai_of(window)) return kMenpaiTipBase + *menpai;
    if (head_of(window)) return kHeadTip;
    if (window == kGirl || window == kBoy) return kSexTip;
    if (window == kName) return kNameTip;
    if (window == kAuthor) return kCreateTip;
    return window == kBack ? kBackTip : 0;
}

// Dòng mô tả mà MouseEnter của window đặt (CreateRole_MouseEnter, CreateRole_Random_MouseEnter,
// CreateRole_RandomName_MouseEnter); rỗng khi layout không nối MouseEnter cho cửa sổ đó.
[[nodiscard]] std::string_view tip_of(std::string_view window) {
    if (window == kRandom) return kRandomTip;
    if (window == kRandomName) return kRandomNameTip;
    return entry(kDescription, tip_number(window));
}

// Cửa sổ nằm trong khung tuỳ chọn CreateRole_Info_Frame (giới, tóc, mặt, bộ đồ, ô ảnh, lật trang,
// ngẫu nhiên, tạo, quay lại).
[[nodiscard]] bool is_in_customizer(std::string_view window) {
    constexpr std::array<std::string_view, 13> kOwn = {
        kGirl, kBoy, kHairLeft, kHairRight, kFaceLeft, kFaceRight, kClothLeft,
        kClothRight, kPageUp, kPageDown, kRandom, kAuthor, kBack,
    };
    return head_of(window).has_value() || std::ranges::contains(kOwn, window);
}

// Cửa sổ nằm trong khung xem trước CreateRole_Info2_Frame (hai nút giới của nó, nút thôi xem).
[[nodiscard]] bool is_in_preview(std::string_view window) {
    return window == kPreviewMan || window == kPreviewWoman || window == kMenpaiControl[0];
}

// CEGUI không đưa chuột cho cửa sổ khoá hay giấu, kể cả khi chính khung chứa nó khoá, giấu hay mờ
// hẳn.
[[nodiscard]] bool takes_mouse(const CreateRole& panel, std::string_view window) {
    const Widgets& widgets = panel.widgets;
    if (widgets.is_disabled(window) || widgets.is_hidden(window)) return false;
    const bool is_info_shut = widgets.is_disabled(kInfoFrame) || widgets.is_hidden(kInfoFrame) || is_info_clear(widgets);
    if (is_in_customizer(window) && is_info_shut) return false;
    return !is_in_preview(window) || !widgets.is_hidden(kInfo2Frame);
}

// MouseLButtonDown của bốn nút xoay và phóng (CreateRole_Modle_TurnLeft(1), TurnRight(1),
// ZoomOut(1), ZoomIn(1)).
void hold(CreateRole& panel, std::string_view window, std::vector<Call>& calls) {
    if (window == kTurnLeft || window == kTurnRight) {
        panel.held = window == kTurnLeft ? HeldButton::kTurnLeft : HeldButton::kTurnRight;
        panel.game.spin = window == kTurnLeft ? -1 : 1;
        note(calls, Ask::kModelRotBegin, std::to_string(panel.game.spin));
    }
    if (window == kZoomOut || window == kZoomIn) {
        panel.held = window == kZoomOut ? HeldButton::kZoomOut : HeldButton::kZoomIn;
        panel.game.zoom = window == kZoomOut ? -1 : 1;
        note(calls, Ask::kModelZoom, std::to_string(panel.game.zoom));
    }
}

// Clicked của các nút mũi tên, lật trang và ngẫu nhiên.
void click_picker(CreateRole& panel, std::string_view window, const CreateFacts& facts, std::vector<Call>& calls) {
    if (window == kHairLeft || window == kHairRight) step_hair(panel, window == kHairRight, facts, calls);
    if (window == kFaceLeft || window == kFaceRight) step_face(panel, window == kFaceRight, facts, calls);
    if (window == kClothLeft || window == kClothRight) step_outfit(panel, window == kClothRight, facts, calls);
    if (window == kPageUp) page_up(panel, facts);
    if (window == kPageDown) page_down(panel, facts);
    if (window == kRandom) click_random(panel, facts, calls);
}

// Clicked của các nút đánh dấu: CEGUI bật nút và tắt các nút cùng cha trước khi gọi hàm của script.
void click_check(CreateRole& panel, std::string_view window, const CreateFacts& facts, std::vector<Call>& calls) {
    if (const std::optional<std::int32_t> head = head_of(window)) {
        panel.widgets.check_one(entry(kHeadButtons, *head), kHeadButtons);
        panel.head = *head;
    }
    if (window == kGirl || window == kBoy) {
        panel.widgets.check_one(window == kGirl ? kGirl : kBoy, kSexButtons);
        select_sex(panel, window == kGirl ? kFemale : kMale, facts, calls);
    }
    if (window == kPreviewMan || window == kPreviewWoman) {
        panel.widgets.check_one(window == kPreviewMan ? kPreviewMan : kPreviewWoman, kPreviewButtons);
        click_preview_sex(panel, window == kPreviewMan ? kMale : kFemale, facts, calls);
    }
}

[[nodiscard]] bool starts_point(unsigned char byte) noexcept {
    return (byte & 0xC0U) != 0x80U;
}

[[nodiscard]] std::size_t code_points(std::string_view text) noexcept {
    return static_cast<std::size_t>(
        std::ranges::count_if(text, [](char byte) { return starts_point(static_cast<unsigned char>(byte)); }));
}

[[nodiscard]] bool is_name_char(char32_t code) noexcept {
    if (code < 0x20 || code == kHash || code == kDelete) return false;
    if (code >= kSurrogateFirst && code <= kSurrogateLast) return false;
    return code <= kLastBmp;
}

void pop_code_point(std::string& text) noexcept {
    while (!text.empty() && !starts_point(static_cast<unsigned char>(text.back()))) text.pop_back();
    if (!text.empty()) text.pop_back();
}

// Thêm một mã của mặt phẳng cơ bản (is_name_char đã lọc) dưới dạng UTF-8.
void append_utf8(std::string& text, char32_t code) {
    if (code < 0x80) {
        text.push_back(static_cast<char>(code));
        return;
    }
    if (code < 0x800) {
        text.push_back(static_cast<char>(0xC0U | (code >> 6U)));
        text.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
        return;
    }
    text.push_back(static_cast<char>(0xE0U | (code >> 12U)));
    text.push_back(static_cast<char>(0x80U | ((code >> 6U) & 0x3FU)));
    text.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
}

// Ô tên đang nhận phím: đang hiện và là ô nhập mặc định (DefaultEditBox của sự kiện mở bảng).
[[nodiscard]] bool takes_keys(const CreateRole& panel) noexcept {
    const Widgets& widgets = panel.widgets;
    const bool is_default = widgets.value(Key{.window = kName, .name = "DefaultEditBox"}) == kTrue;
    return panel.is_shown && is_default && !widgets.is_hidden(kName);
}

} // namespace

void open_create(CreateRole& panel, const CreateFacts& facts, std::vector<Call>& calls) {
    // Thủ tục tạo được vào trước khi script chạy sự kiện mở bảng (CGamePro_CharCreate::Init,
    // 0x1406413e0): camera đứng sẵn ở tư thế của giới mà thủ tục còn nhớ.
    ++panel.game.entries;
    panel.game.entry_sex = panel.game.sex;
    if (!panel.is_loaded) load(panel, facts);
    Widgets& widgets = panel.widgets;
    put(widgets, kName, "DefaultEditBox", kTrue);
    widgets.hide(kRandomName);
    panel.is_shown = true;
    widgets.set_text(kName, "");
    restore_character(panel, calls);
    select_sex(panel, kFemale, facts, calls);
    show_role_face(panel, facts);
    widgets.check_one(kHeadButtons[0], kHeadButtons);
}

void close_create(CreateRole& panel) {
    put(panel.widgets, kName, "DefaultEditBox", kFalse);
    panel.is_shown = false;
    panel.held = HeldButton::kNone;
    panel.game.spin = 0;
    panel.game.zoom = 0;
}

void press_create(CreateRole& panel, std::string_view window, const CreateFacts& facts, std::vector<Call>& calls) {
    if (!panel.is_shown || !takes_mouse(panel, window)) return;
    hold(panel, window, calls);
    if (const std::optional<std::int32_t> menpai = menpai_of(window)) click_menpai(panel, *menpai, calls);
    click_check(panel, window, facts, calls);
    click_picker(panel, window, facts, calls);
    if (window == kAuthor) click_create(panel, facts, calls);
    if (window == kBack) note(calls, Ask::kChangeToSelectRole, {});
}

void release_create(CreateRole& panel, std::vector<Call>& calls) {
    const HeldButton held = panel.held;
    panel.held = HeldButton::kNone;
    if (held == HeldButton::kTurnLeft || held == HeldButton::kTurnRight) {
        panel.game.spin = 0;
        note(calls, Ask::kModelRotEnd, "0");
    }
    if (held == HeldButton::kZoomOut || held == HeldButton::kZoomIn) {
        panel.game.zoom = 0;
        note(calls, Ask::kModelZoom, "0");
    }
}

void roll_detail(CreateRole& panel, const DetailRoll& roll) noexcept {
    DetailScroll& detail = panel.detail;
    detail.position = gui::clamp_scroll(roll.span, detail.position);
    if (!gui::is_scrollable(roll.span)) {
        detail.rest = kDetailRest;
        return;
    }
    if (roll.notches != 0) {
        const float moved = gui::scroll_step(roll.span.page) * static_cast<float>(roll.notches);
        detail.position = gui::clamp_scroll(roll.span, detail.position - moved);
    }
    if (roll.notches != 0 || roll.is_hovered) {
        detail.rest = kDetailRest;
        return;
    }
    if (!(roll.seconds > 0.0F)) return;
    const float limit = gui::scroll_limit(roll.span);
    if (detail.rest > 0.0F) {
        detail.rest -= roll.seconds;
        if (detail.rest > 0.0F || detail.position < limit) return;
        // Hết nghỉ ở cuối chữ: về đầu và nghỉ lại.
        detail = DetailScroll{};
        return;
    }
    detail.position = gui::clamp_scroll(roll.span, detail.position + (kDetailSpeed * roll.seconds));
    if (detail.position >= limit) detail.rest = kDetailRest;
}

void hover_create(CreateRole& panel, std::string_view window) {
    if (!panel.is_shown || panel.hovered == window) return;
    if (!tip_of(panel.hovered).empty()) panel.widgets.set_text(kInfo, "");
    panel.hovered = window;
    const std::string_view tip = tip_of(window);
    if (!tip.empty()) panel.widgets.set_text(kInfo, tip);
}

void type_create(CreateRole& panel, char32_t code, const CreateFacts& facts, std::vector<Call>& calls) {
    if (!takes_keys(panel) || code == kTab) return;
    if (code == kEnter) {
        click_create(panel, facts, calls);
        return;
    }
    std::string name(create_name(panel));
    if (code == kBackspace) pop_code_point(name);
    const bool is_added = code != kBackspace && is_name_char(code) && code_points(name) < kNameLimit;
    if (is_added) append_utf8(name, code);
    if (code == kBackspace || is_added) panel.widgets.set_text(kName, name);
}

std::vector<std::string_view> create_imagesets() {
    constexpr std::string_view kSetMark = "set:";
    std::vector<std::string_view> names;
    const auto take = [&names, kSetMark](std::span<const std::string_view> images) {
        for (const std::string_view image : images) {
            if (!image.starts_with(kSetMark)) continue;
            const std::string_view rest = image.substr(kSetMark.size());
            const std::string_view name = rest.substr(0, rest.find(' '));
            if (!name.empty() && !std::ranges::contains(names, name)) names.push_back(name);
        }
    };
    take(kMenpaiNormal);
    take(kMenpaiDisable);
    take(kMenpaiIcons);
    return names;
}

void notify_create(CreateRole& panel, std::string_view text) {
    panel.widgets.set_text(kInfo, text);
}

std::string_view create_name(const CreateRole& panel) noexcept {
    return panel.widgets.value(Key{.window = kName, .name = "Text"}).value_or(std::string_view{});
}

void paint_create(Deck& deck, const CreateRole& panel) {
    if (!panel.is_shown) return;
    deck.show(kRoot);
    panel.widgets.paint(deck);
    deck.set(gui::Override{.window = kName, .name = "Caret", .value = takes_keys(panel) ? kTrue : kFalse});
    // Khác gốc: bản gốc luôn hiện khung chữ góc dưới trái (lời mời xem trước, hay câu đối của môn
    // phái đang xem viết lại bằng chữ thường kèm dòng sở trường, và dòng nhắc cấp 10). Khung cao 123
    // điểm neo vào đáy còn danh sách môn phái dài 600 điểm tính từ y 46, nên ở vùng vẽ thấp hơn 769
    // điểm (mặc định 1280 x 720) nó đè lên nút môn phái cuối danh sách. Câu đối đã có ở ảnh của khung
    // giới thiệu, dòng sở trường và dòng cấp 10 đã có trong ô mô tả; chủ dự án yêu cầu tắt hẳn khung
    // này (2026-10-09). Bảng vẫn đặt chữ cho nó như script gốc, chỉ là không vẽ.
    deck.hide(kShowInfoBack);
    // Vị trí cuộn tới phần trăm điểm ảnh, để chữ trôi mượt; lúc chữ đứng yên giá trị không đổi nên
    // trang không dàn lại.
    std::string& scroll = deck.compose(Key{.window = kCreateDetail, .name = gui::kScrollProperty});
    std::format_to(std::back_inserter(scroll), "{:.2f}", panel.detail.position);
}

} // namespace game::ui::panel
