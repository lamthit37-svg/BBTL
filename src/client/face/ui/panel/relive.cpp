/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/relive.cpp
 *  PHÂN HỆ   : Face / Ui / Panel / Relive
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Điền Relive lúc chết. Khác gốc: không có hồn xuất khiếu, cờ hồi sinh, thù
 *    địch hay đếm giờ của máy chủ, nên các ô đó bị giấu. Hai nút còn lại là
 *    hồi thành và hồi tại chỗ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/panel/relive.hpp"

#include "gui/sheet.hpp"

#include <array>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kTownButton = "Relive_Relive_Button";
constexpr std::string_view kHereButton = "Relive_Fool_Button";
// Chữ qua khoá i18n; "复活" của tiêu đề là INTERFACE_XML_274 của từ điển gốc.
constexpr std::string_view kTitle = "#gFF0FA0#{INTERFACE_XML_274}";
constexpr std::string_view kDead = "#{RELIVE_DEAD}";
constexpr std::string_view kHint = "\n#{RELIVE_HINT}";
constexpr std::string_view kLossExp = "\n#{RELIVE_LOSS_EXP} ";
constexpr std::string_view kLossMoney = "    #{RELIVE_LOSS_MONEY} ";
constexpr std::string_view kTownLabel = "#{RELIVE_TOWN}";
constexpr std::string_view kHereLabel = "#{RELIVE_HERE}";

constexpr std::array<std::string_view, 16> kHidden = {
    "Relive_Release_Button", "Relive_AddFoe_Button", "Relive_Rebirth_Button", "Relive_FHQ",
    "Relive_Frame2",         "Relive_Frame3",        "Relive_Close",          "Relive_Help",
    "Relive_Time_Text",      "Relive_Time_Text2",    "Relive_Time_Text3",     "Relive_Time_Text4",
    "Relive_Time_Text4_1",   "Relive_Time_Text5",    "Relive_Time_Text6",     "Relive_Time_Text7",
};

void append_loss(std::string& body, const DeathLoss& loss) {
    const std::string exp = std::to_string(loss.exp);
    const std::string money = std::to_string(loss.money);
    body.append(kLossExp);
    body.append(exp);
    body.append(kLossMoney);
    body.append(money);
}

void write_loss(Deck& deck, const std::optional<DeathLoss>& loss) {
    std::string& body = deck.compose(Key{.window = "Relive_Text1", .name = "Text"});
    body.assign(kDead);
    if (loss) append_loss(body, *loss);
    body.append(kHint);
}

} // namespace

void fill_relive(Deck& deck, bool is_dead, const std::optional<DeathLoss>& loss) {
    if (!is_dead) return;
    deck.show("BackGround_Frame");
    for (const std::string_view window : kHidden) deck.hide(window);
    deck.compose(Key{.window = "Relive_Text", .name = "Text"}).assign(kTitle);
    deck.hide("Relive_Text2_Bk");
    write_loss(deck, loss);
    deck.compose(Key{.window = kTownButton, .name = "Text"}).assign(kTownLabel);
    deck.compose(Key{.window = kHereButton, .name = "Text"}).assign(kHereLabel);
}

std::optional<talk::Place> relive_place(std::string_view window) noexcept {
    if (window == kTownButton) return talk::Place::kTown;
    if (window == kHereButton) return talk::Place::kHere;
    return std::nullopt;
}

} // namespace game::ui::panel
