// Nội dung của các bảng mở từ thanh menu chính (ui/panel): bảng nhân vật ghi đúng lời gọi mà
// SelfEquip.lua bản 2026 thực hiện lúc mở, cho nhân vật mới lẫn nhân vật đã lên cấp; phép điền mẫu
// chuỗi %s0; và mọi tên cửa sổ bảng nêu đều có thật trong layout của client 2026.
#include "ui/panel/self_equip.hpp"

#include "core/check.hpp"
#include "gui/asset.hpp"
#include "gui/loader.hpp"
#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "hero/hero.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/wording.hpp"

#include <algorithm>
#include <array>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using ui::panel::Deck;
using ui::panel::Key;

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì ca đối chiếu layout thật tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

// Mẫu chuỗi của bảng nhân vật, cùng dạng với dòng của StrDictionary.
constexpr std::string_view kWords = "key\ttext\n"
                                    "CTPK_251016_1\t#cC8B88ECấp %s0\n"
                                    "PAIR\t%s1 trước %s0\n"
                                    "RATE\tcộng %s0%\n";

// Thẻ mở và thẻ khoá của nhân vật cấp 1; thẻ còn chờ một mốc ở cấp 90; và mọi mốc.
constexpr std::array<std::string_view, 4> kOpenAtFirst = {
    "SelfEquip_SelfEquip", "SelfEquip_Pet", "SelfEquip_Wuhun", "SelfEquip_OtherInfo"};
constexpr std::array<std::string_view, 4> kLockedAtFirst = {
    "SelfEquip_Infant", "SelfEquip_Xiulian", "SelfEquip_ShenDing", "SelfEquip_CangPin"};
constexpr std::array<std::string_view, 7> kGatedPages = {"SelfEquip_Infant", "SelfEquip_Miji", "SelfEquip_ZhenYuan",
    "SelfEquip_JingMai", "SelfEquip_WuYi", "SelfEquip_ShenQi", "SelfEquip_Armor"};
constexpr std::array kEveryMilestone = {hero::Milestone::kChild, hero::Milestone::kManual,
    hero::Milestone::kTrueEssence, hero::Milestone::kMeridian, hero::Milestone::kMartialIntent,
    hero::Milestone::kArtifact, hero::Milestone::kStarChart};

gui::StringBook book_of(std::string_view text) {
    const table::TsvResult table = table::parse_tsv(text);
    core::check(table.has_value(), "bảng chuỗi mẫu phải đọc được");
    return gui::StringBook::from_table(*table);
}

// Giá trị cuối cùng đặt cho một thuộc tính trong khung này; nullopt khi bảng không đặt.
std::optional<std::string_view> said(Deck& deck, const Key& key) {
    std::optional<std::string_view> value;
    for (const gui::Override& item : deck.overrides()) {
        const bool is_mine = item.window == key.window && item.name == key.name;
        value = is_mine ? std::optional(item.value) : value;
    }
    return value;
}

std::optional<std::string_view> text_of(Deck& deck, std::string_view window) {
    return said(deck, Key{.window = window, .name = "Text"});
}

bool is_hidden(const Deck& deck, std::string_view window) {
    return std::ranges::contains(deck.hidden(), window);
}

bool is_revealed(Deck& deck, std::string_view window) {
    return said(deck, Key{.window = window, .name = "Visible"}) == std::string_view{"True"};
}

bool is_off(Deck& deck, std::string_view window) {
    return said(deck, Key{.window = window, .name = "Disabled"}) == std::string_view{"True"};
}

bool is_on(Deck& deck, std::string_view window) {
    return said(deck, Key{.window = window, .name = "Disabled"}) == std::string_view{"False"};
}

void format_fills_slots(Context& context) {
    const gui::StringBook book = book_of(kWords);
    std::string level;
    const std::array<std::string_view, 1> one = {"12"};
    ui::panel::format_key(level, book, "#{CTPK_251016_1}", one);
    context.expect(level == "#cC8B88ECấp 12", "%s0 nhận đối số đầu");
    std::string pair;
    const std::array<std::string_view, 2> two = {"a", "b"};
    ui::panel::format_key(pair, book, "#{PAIR}", two);
    context.expect(pair == "b trước a", "chỗ điền theo số, không theo thứ tự xuất hiện");
    std::string rate;
    ui::panel::format_key(rate, book, "#{RATE}", one);
    context.expect(rate == "cộng 12%", "dấu % sau chỗ điền giữ nguyên");
    std::string lacking;
    ui::panel::format_key(lacking, book, "#{PAIR}", one);
    context.expect(lacking == " trước 12", "thiếu đối số thì chỗ điền để trống");
    std::string unknown = "cũ";
    ui::panel::format_key(unknown, book, "#{KHONG_CO}", one);
    context.expect(unknown == "cũ", "khoá lạ thì không ghi gì");
    ui::panel::format_key(unknown, book, "PAIR", two);
    context.expect(unknown == "cũ", "không viết dạng #{khoá} thì không ghi gì");
}

// Nhân vật mới, cấp 1, chưa môn phái: số của Equip_OnUpdateShow và trạng thái nút.
void sheet_of_newcomer(Context& context) {
    const gui::StringBook book = book_of(kWords);
    const hero::Hero hero = hero::newcomer();
    Deck deck;
    ui::panel::fill_self_equip(deck, hero, book);
    context.expect(text_of(deck, "SelfEquip_PageHeader") == "#gFF0FA0#{GMGameInterface_Script_Talk_Info_R_Man}", "tên có màu");
    context.expect(text_of(deck, "SelfEquip_HP") == "#cFAFFA4585/585", "máu");
    context.expect(text_of(deck, "SelfEquip_MP") == "#cFAFFA4310/310", "khí");
    context.expect(text_of(deck, "SelfEquip_SP") == "#cFAFFA40/1000", "nộ");
    context.expect(text_of(deck, "SelfEquip_SP_Text") == "#{INTERFACE_XML_481}", "nhãn nộ");
    context.expect(text_of(deck, "SelfEquip_Exp2") == "#cC8B88E0", "kinh nghiệm đang có");
    context.expect(text_of(deck, "SelfEquip_Exp1") == "#cC8B88E90", "kinh nghiệm cần");
    context.expect(text_of(deck, "SelfEquip_Level") == "#cC8B88ECấp 1", "cấp theo mẫu của từ điển");
    context.expect(text_of(deck, "SelfEquip_Str") == "7", "sức mạnh");
    context.expect(text_of(deck, "SelfEquip_Footwork") == "2", "thân pháp");
    context.expect(text_of(deck, "SelfEquip_Potential") == "0", "điểm dư");
    context.expect(text_of(deck, "SelfEquip_Perporty1") == "56", "công ngoại");
    context.expect(text_of(deck, "SelfEquip_Perporty7") == "38", "chính xác");
    context.expect(text_of(deck, "SelfEquip_Perporty6") == "13", "né tránh");
    context.expect(text_of(deck, "SelfEquip_Perporty1_Plus") == "", "chưa tu luyện");
    context.expect(text_of(deck, "SelfEquip_Vigor") == "10/50", "hoạt lực");
    context.expect(text_of(deck, "SelfEquip_Energy") == "10/50", "tinh lực");
    context.expect(text_of(deck, "SelfEquip_MenPai") == "#{GMGameInterface_Script_DataPool_Info_WuMenPai}", "chưa môn phái");
    const auto score = text_of(deck, "SelfEquip_FightScore_Text");
    context.expect(score == "#{ZDPF_130115_01}0", "điểm trang bị nối sau nhãn");
    context.expect(is_off(deck, "Equip_Addition_Button1"), "hết điểm thì nút cộng khoá");
    context.expect(is_off(deck, "Equip_Decrease_Button5"), "nút trừ khoá lúc mở");
    context.expect(is_off(deck, "SelfEquip_Accept"), "chưa đổi gì thì nút đồng ý khoá");
    context.expect(is_off(deck, "SelfEquip_UpLevel"), "chưa đủ kinh nghiệm thì nút lên cấp khoá");
    context.expect(is_hidden(deck, "SelfEquip_UpLevel_Tip"), "không có lời nhắc lên cấp");
    context.expect(is_hidden(deck, "SelfEquip_Shoulder_Visual_Icon"), "dưới cấp 60");
}

// Ô trang bị trống: không mặt nạ nhắc, không hoạt ảnh chí tôn; chưa học đổi bảo thạch thì chỉ
// hiện nền của ô bảo thạch; khoá lên cấp chỉ hiện từ cấp 30.
void sheet_slots_of_newcomer(Context& context) {
    const gui::StringBook book = book_of(kWords);
    const hero::Hero hero = hero::newcomer();
    Deck deck;
    ui::panel::fill_self_equip(deck, hero, book);
    context.expect(is_hidden(deck, "SelfEquip_11_Mask"), "ô vũ khí trống không có mặt nạ");
    context.expect(is_hidden(deck, "SelfEquip_16_Mask"), "ô cuối cũng vậy");
    context.expect(is_hidden(deck, "SelfEquip_1_Animate"), "không hoạt ảnh chí tôn");
    context.expect(is_hidden(deck, "SelfEquip_BaoShiCheck_11green"), "nút bảo thạch xanh giấu");
    context.expect(is_hidden(deck, "SelfEquip_BaoShiCheck_16red"), "nút bảo thạch đỏ giấu");
    context.expect(is_revealed(deck, "SelfEquip_BaoShiCheckBK1"), "nền ô bảo thạch hiện");
    context.expect(is_hidden(deck, "SelfEquip_LevelUpLock"), "dưới cấp 30 không có khoá lên cấp");
    context.expect(is_hidden(deck, "SelfEquip_LevelUpLock_Open"), "cả nút mở khoá");
    context.expect(is_hidden(deck, "SelfEquip_BW_Match"), "chưa có hạng thí kiếm");
    const Key checked{.window = "SelfEquip_SelfEquip", .name = "Selected"};
    context.expect(said(deck, checked) == std::string_view{"True"}, "thẻ trang bị đang chọn");
}

// Dãy thẻ: nhân vật cấp 1 chỉ mở trang bị, trân thú, võ hồn, khác; thẻ khoá hiện lớp che.
void sheet_pages_of_newcomer(Context& context) {
    const gui::StringBook book = book_of(kWords);
    const hero::Hero hero = hero::newcomer();
    Deck deck;
    ui::panel::fill_self_equip(deck, hero, book);
    for (const std::string_view button : kOpenAtFirst)
        context.expect(is_on(deck, button), button);
    for (const std::string_view button : kLockedAtFirst)
        context.expect(is_off(deck, button), button);
    context.expect(is_hidden(deck, "SelfEquip_Pet_tips"), "thẻ mở không có lớp che");
    context.expect(is_revealed(deck, "SelfEquip_Xiulian_tips"), "thẻ khoá có lớp che");
    context.expect(text_of(deck, "SelfEquip_Pet") == "#{INTERFACE_XML_854}", "chữ của thẻ");
}

// Nhân vật cấp 90 đã xong các nhiệm vụ mở trang, có con: mọi thẻ mở.
void sheet_pages_open_with_progress(Context& context) {
    const gui::StringBook book = book_of(kWords);
    hero::Hero hero = hero::newcomer();
    hero.level = 90;
    Deck before;
    ui::panel::fill_self_equip(before, hero, book);
    context.expect(is_on(before, "SelfEquip_Xiulian"), "cấp 70 mở tu luyện");
    context.expect(is_on(before, "SelfEquip_JunXian"), "cấp 85 mở hiệp ấn");
    context.expect(is_off(before, "SelfEquip_Infant"), "chưa có con thì thẻ con vẫn khoá");
    context.expect(is_off(before, "SelfEquip_JingMai"), "chưa xong nhiệm vụ kinh mạch");
    context.expect(is_off(before, "SelfEquip_ShenQi"), "chưa xong nhiệm vụ thần khí");
    for (const hero::Milestone mark : kEveryMilestone)
        hero.milestones.add(mark);
    Deck after;
    ui::panel::fill_self_equip(after, hero, book);
    for (const std::string_view button : kGatedPages)
        context.expect(is_on(after, button), button);
    context.expect(is_hidden(after, "SelfEquip_JingMai_tips"), "thẻ mở thì bỏ lớp che");
    context.expect(is_revealed(after, "SelfEquip_Shoulder_Visual_Icon"), "từ cấp 60");
}

// Có điểm dư thì năm nút cộng mở; tu luyện hiện phần cộng; phòng thủ quá 999999 hiện dấu hỏi.
void sheet_points_and_bonus(Context& context) {
    const gui::StringBook book = book_of(kWords);
    hero::Hero hero = hero::newcomer();
    hero.spare_points = 3;
    hero.combat.defence_physical = 1000000;
    hero.combat.defence_magic = 999999;
    hero::Cultivation bonus;
    bonus.roots.strength = 4;
    bonus.combat.hit = 9;
    hero.cultivation = bonus;
    Deck deck;
    ui::panel::fill_self_equip(deck, hero, book);
    context.expect(text_of(deck, "SelfEquip_Potential") == "3", "điểm dư");
    context.expect(is_on(deck, "Equip_Addition_Button1"), "nút cộng đầu mở");
    context.expect(is_on(deck, "Equip_Addition_Button5"), "nút cộng cuối mở");
    context.expect(is_off(deck, "Equip_Decrease_Button1"), "nút trừ vẫn khoá");
    context.expect(text_of(deck, "SelfEquip_Perporty3") == "??????", "phòng ngoại quá trần");
    context.expect(text_of(deck, "SelfEquip_Perporty4") == "999999", "đúng trần thì vẫn hiện số");
    context.expect(text_of(deck, "SelfEquip_Str_Plus") == "#H+4", "tu luyện sức mạnh");
    context.expect(text_of(deck, "SelfEquip_Perporty7_Plus") == "#H+9", "tu luyện chính xác");
    context.expect(text_of(deck, "SelfEquip_Perporty8_Plus") == "", "hội tâm không có phần cộng");
}

// Nút lên cấp: đủ kinh nghiệm và dưới trần thì mở, riêng cấp 119 bị chặn; khoá lên cấp có ba
// trạng thái từ cấp 30.
void sheet_level_button_and_lock(Context& context) {
    const gui::StringBook book = book_of(kWords);
    hero::Hero hero = hero::newcomer();
    hero.experience.now = hero.experience.top;
    Deck ready;
    ui::panel::fill_self_equip(ready, hero, book);
    context.expect(is_on(ready, "SelfEquip_UpLevel"), "đủ kinh nghiệm thì nút lên cấp mở");
    hero.level = 119;
    Deck held;
    ui::panel::fill_self_equip(held, hero, book);
    context.expect(is_off(held, "SelfEquip_UpLevel"), "cấp 119 bị chặn");
    hero.level = 129;
    Deck capped;
    ui::panel::fill_self_equip(capped, hero, book);
    context.expect(is_off(capped, "SelfEquip_UpLevel"), "chạm trần cấp thì khoá");
    hero.level = 40;
    Deck open;
    ui::panel::fill_self_equip(open, hero, book);
    context.expect(is_revealed(open, "SelfEquip_LevelUpLock_Open"), "chưa khoá: hiện nút khoá");
    context.expect(is_hidden(open, "SelfEquip_LevelUpLock"), "chưa khoá: giấu nút mở");
    hero.level_lock = hero::LevelLock::kLocked;
    Deck locked;
    ui::panel::fill_self_equip(locked, hero, book);
    context.expect(is_revealed(locked, "SelfEquip_LevelUpLock"), "đang khoá: hiện nút mở");
    context.expect(is_revealed(locked, "SelfEquip_LevelUpLock_SuoLian"), "đang khoá: xích");
    context.expect(is_hidden(locked, "SelfEquip_LevelUpLock_Opening"), "chưa chờ mở");
    hero.level_lock = hero::LevelLock::kOpening;
    Deck opening;
    ui::panel::fill_self_equip(opening, hero, book);
    context.expect(is_revealed(opening, "SelfEquip_LevelUpLock_Opening"), "đang chờ mở");
}

bool has_window(const gui::GuiAsset& asset, std::string_view name) {
    const auto is_named = [name](const gui::GuiWindow& window) { return window.name == name; };
    return std::ranges::any_of(asset.windows, is_named);
}

// Mọi cửa sổ bảng nhân vật nêu (đặt thuộc tính hay giấu) phải có thật trong layout của kho: gõ sai
// một tên thì chỉ thị đó mất mà không báo gì.
void sheet_names_exist(Context& context) {
    if (kClientData.empty()) return;
    const std::filesystem::path root = std::filesystem::path(kClientData) / "Interface";
    const gui::DiskSource files(root);
    gui::GuiSources sources;
    sources.files = &files;
    auto loader = gui::GuiLoader::open(sources);
    context.expect(loader.has_value(), "mở được giao diện của kho");
    if (!loader) return;
    const auto added = loader->add_layout("SelfEquip/SelfEquip.layout.xml");
    context.expect(added.has_value(), "nạp được layout bảng nhân vật");
    const gui::GuiAsset& asset = loader->asset();
    const gui::StringBook book = book_of(kWords);
    hero::Hero hero = hero::newcomer();
    hero.level = 40;
    hero.cultivation = hero::Cultivation{};
    Deck deck;
    ui::panel::fill_self_equip(deck, hero, book);
    context.expect(deck.overrides().size() > 100, "bảng đặt hơn một trăm thuộc tính");
    for (const gui::Override& item : deck.overrides())
        context.expect(has_window(asset, item.window), item.window);
    for (const std::string_view window : deck.hidden())
        context.expect(has_window(asset, window), window);
}

constexpr std::array kCases{
    Case{.name = "format_fills_slots", .body = &format_fills_slots},
    Case{.name = "sheet_of_newcomer", .body = &sheet_of_newcomer},
    Case{.name = "sheet_slots_of_newcomer", .body = &sheet_slots_of_newcomer},
    Case{.name = "sheet_pages_of_newcomer", .body = &sheet_pages_of_newcomer},
    Case{.name = "sheet_pages_open_with_progress", .body = &sheet_pages_open_with_progress},
    Case{.name = "sheet_points_and_bonus", .body = &sheet_points_and_bonus},
    Case{.name = "sheet_level_button_and_lock", .body = &sheet_level_button_and_lock},
    Case{.name = "sheet_names_exist", .body = &sheet_names_exist},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_board_tests: mọi ca phải qua");
    return 0;
}
