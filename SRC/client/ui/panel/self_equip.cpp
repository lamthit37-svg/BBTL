#include "ui/panel/self_equip.hpp"

#include "gui/sheet.hpp"
#include "gui/strings.hpp"
#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/sect.hpp"
#include "ui/panel/wording.hpp"

#include <array>
#include <cstdint>
#include <format>
#include <iterator>
#include <optional>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

// Màu của script gốc: tên bảng, ba chỉ số máu khí nộ, hai số kinh nghiệm, phần tu luyện cộng thêm.
constexpr std::string_view kTitleTint = "#gFF0FA0";
constexpr std::string_view kGaugeTint = "#cFAFFA4";
constexpr std::string_view kExperienceTint = "#cC8B88E";
constexpr std::string_view kBonusMark = "#H+";
// Phòng thủ quá số này hiện dấu hỏi (script gốc: sửa cho bang chiến).
constexpr std::int32_t kShownDefenceTop = 999999;
constexpr std::string_view kHugeDefence = "??????";
constexpr std::string_view kRageLabel = "#{INTERFACE_XML_481}";
constexpr std::string_view kScoreLabel = "#{ZDPF_130115_01}";
constexpr std::string_view kLevelPattern = "#{CTPK_251016_1}";
// Ảnh mức cường hoá bộ thấp nhất (tổng cấp cường hoá dưới 360).
constexpr std::string_view kFirstEnchantImage = "set:UIIcons1 image:Equip_qianghua1";
// Cấp bị chặn lên tiếp cho tới khi xong nhiệm vụ mở rộng cấp, và các mốc cấp của script.
constexpr std::int32_t kHeldLevel = 119;
constexpr std::int32_t kShoulderLevel = 60;
constexpr std::int32_t kLockLevel = 30;

// Một chỉ số gốc: ô số, ô phần tu luyện, nút cộng và nút trừ điểm.
struct RootRow {
    std::int32_t hero::Roots::* value = nullptr;
    std::string_view shown;
    std::string_view bonus;
    std::string_view add;
    std::string_view take;
};

constexpr std::array<RootRow, 5> kRoots{{
    {.value = &hero::Roots::strength,
        .shown = "SelfEquip_Str",
        .bonus = "SelfEquip_Str_Plus",
        .add = "Equip_Addition_Button1",
        .take = "Equip_Decrease_Button1"},
    {.value = &hero::Roots::spirit,
        .shown = "SelfEquip_Nimbus",
        .bonus = "SelfEquip_Nimbus_Plus",
        .add = "Equip_Addition_Button2",
        .take = "Equip_Decrease_Button2"},
    {.value = &hero::Roots::constitution,
        .shown = "SelfEquip_PhysicalStrength",
        .bonus = "SelfEquip_PhysicalStrength_Plus",
        .add = "Equip_Addition_Button3",
        .take = "Equip_Decrease_Button3"},
    {.value = &hero::Roots::stability,
        .shown = "SelfEquip_Stability",
        .bonus = "SelfEquip_Stability_Plus",
        .add = "Equip_Addition_Button4",
        .take = "Equip_Decrease_Button4"},
    {.value = &hero::Roots::agility,
        .shown = "SelfEquip_Footwork",
        .bonus = "SelfEquip_Footwork_Plus",
        .add = "Equip_Addition_Button5",
        .take = "Equip_Decrease_Button5"},
}};

// Một chỉ số chiến đấu: ô số và ô phần tu luyện. Hai chỉ số phòng thủ hiện dấu hỏi khi quá trần;
// hai chỉ số hội tâm không có phần tu luyện.
struct CombatRow {
    std::int32_t hero::Combat::* value = nullptr;
    std::string_view shown;
    std::string_view bonus;
    bool is_capped = false;
    bool has_bonus = true;
};

constexpr std::array<CombatRow, 8> kCombat{{
    {.value = &hero::Combat::attack_physical, .shown = "SelfEquip_Perporty1", .bonus = "SelfEquip_Perporty1_Plus"},
    {.value = &hero::Combat::defence_physical,
        .shown = "SelfEquip_Perporty3",
        .bonus = "SelfEquip_Perporty3_Plus",
        .is_capped = true},
    {.value = &hero::Combat::attack_magic, .shown = "SelfEquip_Perporty2", .bonus = "SelfEquip_Perporty2_Plus"},
    {.value = &hero::Combat::defence_magic,
        .shown = "SelfEquip_Perporty4",
        .bonus = "SelfEquip_Perporty4_Plus",
        .is_capped = true},
    {.value = &hero::Combat::miss, .shown = "SelfEquip_Perporty6", .bonus = "SelfEquip_Perporty6_Plus"},
    {.value = &hero::Combat::hit, .shown = "SelfEquip_Perporty7", .bonus = "SelfEquip_Perporty7_Plus"},
    {.value = &hero::Combat::critical_attack,
        .shown = "SelfEquip_Perporty8",
        .bonus = "SelfEquip_Perporty8_Plus",
        .has_bonus = false},
    {.value = &hero::Combat::critical_defence,
        .shown = "SelfEquip_Perporty9",
        .bonus = "SelfEquip_Perporty9_Plus",
        .has_bonus = false},
}};

// Mặt nạ nhắc của mười sáu ô trang bị (g_EquipMask) và hoạt ảnh chí tôn của mười hai ô
// (m_ZhiZunAnimate).
constexpr std::array<std::string_view, 16> kSlotMasks = {
    "SelfEquip_11_Mask",
    "SelfEquip_1_Mask",
    "SelfEquip_12_Mask",
    "SelfEquip_4_Mask",
    "SelfEquip_6_Mask",
    "SelfEquip_5_Mask",
    "SelfEquip_7_Mask",
    "SelfEquip_13_Mask",
    "SelfEquip_8_Mask",
    "SelfEquip_9_Mask",
    "SelfEquip_10_Mask",
    "SelfEquip_3_Mask",
    "SelfEquip_2_Mask",
    "SelfEquip_14_Mask",
    "SelfEquip_25_Mask",
    "SelfEquip_16_Mask",
};

constexpr std::array<std::string_view, 12> kSupremeGlows = {
    "SelfEquip_1_Animate",
    "SelfEquip_12_Animate",
    "SelfEquip_4_Animate",
    "SelfEquip_6_Animate",
    "SelfEquip_5_Animate",
    "SelfEquip_7_Animate",
    "SelfEquip_13_Animate",
    "SelfEquip_8_Animate",
    "SelfEquip_9_Animate",
    "SelfEquip_10_Animate",
    "SelfEquip_3_Animate",
    "SelfEquip_2_Animate",
};

// Ô bảo thạch của mười sáu vị trí (g_SelfEquip_Gem_Check_Buttons_*): nút xanh và nút đỏ,
// rồi nền hiện khi chưa học kỹ năng đổi bảo thạch.
constexpr std::array<std::string_view, 32> kGemButtons = {
    "SelfEquip_BaoShiCheck_11green",
    "SelfEquip_BaoShiCheck_11red",
    "SelfEquip_BaoShiCheck_03green",
    "SelfEquip_BaoShiCheck_03red",
    "SelfEquip_BaoShiCheck_07green",
    "SelfEquip_BaoShiCheck_07red",
    "SelfEquip_BaoShiCheck_08green",
    "SelfEquip_BaoShiCheck_08red",
    "SelfEquip_BaoShiCheck_09green",
    "SelfEquip_BaoShiCheck_09red",
    "SelfEquip_BaoShiCheck_10green",
    "SelfEquip_BaoShiCheck_10red",
    "SelfEquip_BaoShiCheck_12green",
    "SelfEquip_BaoShiCheck_12red",
    "SelfEquip_BaoShiCheck_01green",
    "SelfEquip_BaoShiCheck_01red",
    "SelfEquip_BaoShiCheck_02green",
    "SelfEquip_BaoShiCheck_02red",
    "SelfEquip_BaoShiCheck_04green",
    "SelfEquip_BaoShiCheck_04red",
    "SelfEquip_BaoShiCheck_05green",
    "SelfEquip_BaoShiCheck_05red",
    "SelfEquip_BaoShiCheck_06green",
    "SelfEquip_BaoShiCheck_06red",
    "SelfEquip_BaoShiCheck_13green",
    "SelfEquip_BaoShiCheck_13red",
    "SelfEquip_BaoShiCheck_14green",
    "SelfEquip_BaoShiCheck_14red",
    "SelfEquip_BaoShiCheck_15green",
    "SelfEquip_BaoShiCheck_15red",
    "SelfEquip_BaoShiCheck_16green",
    "SelfEquip_BaoShiCheck_16red",
};

constexpr std::array<std::string_view, 16> kGemBacks = {
    "SelfEquip_BaoShiCheckBK1",
    "SelfEquip_BaoShiCheckBK2",
    "SelfEquip_BaoShiCheckBK3",
    "SelfEquip_BaoShiCheckBK4",
    "SelfEquip_BaoShiCheckBK5",
    "SelfEquip_BaoShiCheckBK6",
    "SelfEquip_BaoShiCheckBK7",
    "SelfEquip_BaoShiCheckBK8",
    "SelfEquip_BaoShiCheckBK9",
    "SelfEquip_BaoShiCheckBK10",
    "SelfEquip_BaoShiCheckBK11",
    "SelfEquip_BaoShiCheckBK12",
    "SelfEquip_BaoShiCheckBK13",
    "SelfEquip_BaoShiCheckBK14",
    "SelfEquip_BaoShiCheckBK15",
    "SelfEquip_BaoShiCheckBK16",
};

// Một thẻ của dãy thẻ (g_SelfEquip_Page): nút, lớp che lúc khoá, chữ, và điều kiện mở của
// SelfEquip_IsPageEnable: cấp tối thiểu và các mốc phải đạt (dạng Milestones::bits, 0 là không
// cần mốc nào).
struct PageRow {
    std::string_view button;
    std::string_view veil;
    std::string_view text;
    std::int32_t level = 0;
    std::uint8_t needs = 0;
};

constexpr std::array<PageRow, 16> kPages{{
    {.button = "SelfEquip_SelfEquip", .veil = "SelfEquip_SelfEquip_tips", .text = "#{INTERFACE_XML_877}", .level = 0},
    {.button = "SelfEquip_Pet", .veil = "SelfEquip_Pet_tips", .text = "#{INTERFACE_XML_854}", .level = 0},
    {.button = "SelfEquip_Infant",
        .veil = "SelfEquip_Infant_tips",
        .text = "#{ZNJCS_130825_7}",
        .level = 50,
        .needs = hero::Milestones::of(hero::Milestone::kChild).bits},
    {.button = "SelfEquip_Wuhun", .veil = "SelfEquip_Wuhun_tips", .text = "#{WH_xml_XX(95)}", .level = 0},
    {.button = "SelfEquip_Xiulian", .veil = "SelfEquip_Xiulian_tips", .text = "#{XL_XML_35}", .level = 70},
    {.button = "SelfEquip_Miji",
        .veil = "SelfEquip_Miji_tips",
        .text = "#{WLMJ_130121_54}",
        .level = 75,
        .needs = hero::Milestones::of(hero::Milestone::kManual).bits},
    {.button = "SelfEquip_ZhenYuan",
        .veil = "SelfEquip_ZhenYuan_tips",
        .text = "#{ZYXT_120528_154}",
        .level = 80,
        .needs = hero::Milestones::of(hero::Milestone::kTrueEssence).bits},
    {.button = "SelfEquip_JingMai",
        .veil = "SelfEquip_JingMai_tips",
        .text = "#{MPJJ_XT_XML_01}",
        .level = 90,
        .needs = hero::Milestones::of(hero::Milestone::kMeridian).bits},
    {.button = "SelfEquip_ShenDing", .veil = "SelfEquip_ShenDing_tips", .text = "#{XLDL_140606_04}", .level = 15},
    {.button = "SelfEquip_JunXian", .veil = "SelfEquip_JunXian_tips", .text = "#{JXJW_140822_22}", .level = 85},
    {.button = "SelfEquip_BaoJian", .veil = "SelfEquip_BaoJian_tips", .text = "#{ZZZB_150811_113}", .level = 85},
    {.button = "SelfEquip_WuYi",
        .veil = "SelfEquip_WuYi_tips",
        .text = "#{WYXT_20170807_86}",
        .level = 85,
        .needs = hero::Milestones::of(hero::Milestone::kMartialIntent).bits},
    {.button = "SelfEquip_ShenQi",
        .veil = "SelfEquip_ShenQi_tips",
        .text = "#{JXSQ_170829_216}",
        .level = 0,
        .needs = hero::Milestones::of(hero::Milestone::kArtifact).bits},
    {.button = "SelfEquip_Armor",
        .veil = "SelfEquip_Armor_tips",
        .text = "#{NJBZ_220816_11}",
        .level = 85,
        .needs = hero::Milestones::of(hero::Milestone::kStarChart).bits},
    {.button = "SelfEquip_CangPin", .veil = "SelfEquip_CangPin_tips", .text = "#{CPSJ_260112_1}", .level = 30},
    {.button = "SelfEquip_OtherInfo", .veil = "SelfEquip_OtherInfo_tips", .text = "#{INTERFACE_XML_496}", .level = 0},
}};

// Một ô "hiện có/tối đa": cửa sổ, màu chữ đứng trước (hoạt lực và tinh lực không tô) và trường
// của nhân vật.
struct GaugeRow {
    std::string_view shown;
    std::string_view tint;
    hero::Gauge hero::Hero::* value;
};

constexpr std::array<GaugeRow, 5> kGauges{{
    {.shown = "SelfEquip_HP", .tint = kGaugeTint, .value = &hero::Hero::health},
    {.shown = "SelfEquip_MP", .tint = kGaugeTint, .value = &hero::Hero::mana},
    {.shown = "SelfEquip_SP", .tint = kGaugeTint, .value = &hero::Hero::rage},
    {.shown = "SelfEquip_Vigor", .tint = "", .value = &hero::Hero::vigor},
    {.shown = "SelfEquip_Energy", .tint = "", .value = &hero::Hero::energy},
}};

// Chấm đỏ nhắc việc và dấu hạng mà lúc mở script giấu khi không có gì để nhắc.
constexpr std::array<std::string_view, 9> kQuietMarks = {
    "SelfEquip_UpLevel_Tip",
    "SelfEquip_PKLevel_Image",
    "SelfEquip_SectTitle_tips",
    "SelfEquip_Yirong_Icontips",
    "SelfEquip_Pretty_tips",
    "SelfEquip_WuYi_Buttontips",
    "SelfEquip_OtherInfo_ButtonTips",
    "SelfEquip_CangPin_Buttontips",
    "SelfEquip_BW_Match",
};

void put(Deck& deck, std::string_view window, std::string_view text) {
    deck.set(gui::Override{.window = window, .name = "Text", .value = text});
}

void put_number(Deck& deck, std::string_view window, std::int64_t number) {
    std::string& text = deck.compose(Key{.window = window, .name = "Text"});
    std::format_to(std::back_inserter(text), "{}", number);
}

// "now/top" sau màu của ô, như tostring(n).."/"..tostring(max) của script.
void fill_gauge(Deck& deck, const hero::Hero& hero, const GaugeRow& row) {
    const hero::Gauge gauge = hero.*(row.value);
    std::string& text = deck.compose(Key{.window = row.shown, .name = "Text"});
    std::format_to(std::back_inserter(text), "{}{}/{}", row.tint, gauge.now, gauge.top);
}

// Enable và Disable của script.
void switch_on(Deck& deck, std::string_view window, bool is_enabled) {
    const std::string_view value = is_enabled ? "False" : "True";
    deck.set(gui::Override{.window = window, .name = "Disabled", .value = value});
}

// Show và Hide của script.
void show_if(Deck& deck, std::string_view window, bool is_shown) {
    if (is_shown) {
        deck.reveal(window);
        return;
    }
    deck.hide(window);
}

void fill_identity(Deck& deck, const hero::Hero& hero, const gui::StringBook& strings) {
    std::string& title = deck.compose(Key{.window = "SelfEquip_PageHeader", .name = "Text"});
    title.append(kTitleTint).append(hero.name);
    const std::string level = std::format("{}", hero.level);
    const std::array<std::string_view, 1> slots = {level};
    std::string& shown = deck.compose(Key{.window = "SelfEquip_Level", .name = "Text"});
    format_key(shown, strings, kLevelPattern, slots);
    put(deck, "SelfEquip_MenPai", sect_name(static_cast<std::uint8_t>(hero.sect)));
    std::string& score = deck.compose(Key{.window = "SelfEquip_FightScore_Text", .name = "Text"});
    std::format_to(std::back_inserter(score), "{}{}", kScoreLabel, hero.battle_score);
}

void fill_gauges(Deck& deck, const hero::Hero& hero) {
    for (const GaugeRow& row : kGauges)
        fill_gauge(deck, hero, row);
    put(deck, "SelfEquip_SP_Text", kRageLabel);
    std::string& owned = deck.compose(Key{.window = "SelfEquip_Exp2", .name = "Text"});
    std::format_to(std::back_inserter(owned), "{}{}", kExperienceTint, hero.experience.now);
    std::string& needed = deck.compose(Key{.window = "SelfEquip_Exp1", .name = "Text"});
    std::format_to(std::back_inserter(needed), "{}{}", kExperienceTint, hero.experience.top);
}

// Phần tu luyện cộng thêm của một chỉ số: "#H+n", hoặc để trống khi không có.
void put_bonus(Deck& deck, std::string_view window, std::optional<std::int32_t> bonus) {
    std::string& text = deck.compose(Key{.window = window, .name = "Text"});
    if (bonus) std::format_to(std::back_inserter(text), "{}{}", kBonusMark, *bonus);
}

void fill_root(Deck& deck, const hero::Hero& hero, const RootRow& row) {
    put_number(deck, row.shown, hero.roots.*(row.value));
    const auto grown = [&row](const hero::Cultivation& bonus) { return bonus.roots.*(row.value); };
    put_bonus(deck, row.bonus, hero.cultivation.transform(grown));
    switch_on(deck, row.add, hero.spare_points > 0);
    switch_on(deck, row.take, false);
}

// Năm chỉ số gốc và điểm dư. Lúc mở chưa phân điểm nào nên nút trừ và nút đồng ý đều khoá.
void fill_roots(Deck& deck, const hero::Hero& hero) {
    for (const RootRow& row : kRoots)
        fill_root(deck, hero, row);
    put_number(deck, "SelfEquip_Potential", hero.spare_points);
    switch_on(deck, "SelfEquip_Accept", false);
}

void fill_combat_row(Deck& deck, const hero::Hero& hero, const CombatRow& row) {
    const std::int32_t value = hero.combat.*(row.value);
    const bool is_huge = row.is_capped && value > kShownDefenceTop;
    if (is_huge) put(deck, row.shown, kHugeDefence);
    if (!is_huge) put_number(deck, row.shown, value);
    const auto grown = [&row](const hero::Cultivation& bonus) { return bonus.combat.*(row.value); };
    const std::optional<std::int32_t> bonus = hero.cultivation.transform(grown);
    put_bonus(deck, row.bonus, row.has_bonus ? bonus : std::nullopt);
}

void fill_combat(Deck& deck, const hero::Hero& hero) {
    for (const CombatRow& row : kCombat)
        fill_combat_row(deck, hero, row);
}

// SelfEquip_LevelupButtonShow, nhánh máy chủ thường: đủ kinh nghiệm và dưới trần cấp thì nút mở;
// cấp 119 bị giữ lại; chạm trần thì khoá.
void fill_level_button(Deck& deck, const hero::Hero& hero) {
    const bool is_below_cap = hero.level < hero.level_cap;
    const bool is_offered = hero::can_level_up(hero) && is_below_cap && hero.level != kHeldLevel;
    switch_on(deck, "SelfEquip_UpLevel", is_offered);
}

// SelfEquip_LevelupLock_Update: từ cấp 30 tới dưới trần cấp mới có khoá lên cấp.
void fill_level_lock(Deck& deck, const hero::Hero& hero) {
    const bool has_lock = hero.level >= kLockLevel && hero.level < hero.level_cap;
    const bool is_held = has_lock && hero.level_lock != hero::LevelLock::kOpen;
    show_if(deck, "SelfEquip_LevelUpLock", is_held);
    show_if(deck, "SelfEquip_LevelUpLock_SuoLian", is_held);
    show_if(deck, "SelfEquip_LevelUpLock_Open", has_lock && !is_held);
    const bool is_opening = has_lock && hero.level_lock == hero::LevelLock::kOpening;
    show_if(deck, "SelfEquip_LevelUpLock_Opening", is_opening);
}

// Equip_RefreshEquip với mọi ô trống: không mặt nạ nhắc, không hoạt ảnh chí tôn, ô bảo thạch chỉ
// còn nền, ảnh cường hoá bộ ở mức thấp nhất.
void fill_slots(Deck& deck) {
    for (const std::string_view mask : kSlotMasks)
        deck.hide(mask);
    for (const std::string_view glow : kSupremeGlows)
        deck.hide(glow);
    for (const std::string_view button : kGemButtons)
        deck.hide(button);
    for (const std::string_view back : kGemBacks)
        deck.reveal(back);
    const std::string_view effect = "SelfEquip_Effect";
    deck.set(gui::Override{.window = effect, .name = "Image", .value = kFirstEnchantImage});
}

// Các dấu quanh bảng: chấm đỏ giấu, hạng thí kiếm giấu, biểu tượng của máy chủ thường hiện, nút
// phù hiệu vai từ cấp 60.
void fill_marks(Deck& deck, const hero::Hero& hero) {
    for (const std::string_view mark : kQuietMarks)
        deck.hide(mark);
    deck.hide("SelfEquip_BW_Match1");
    deck.reveal("SelfEquip_SectTitle");
    deck.reveal("SelfEquip_ZhiZun_Icon");
    deck.reveal("SelfEquip_ShenDing_Icon");
    deck.reveal("SelfEquip_25");
    show_if(deck, "SelfEquip_Shoulder_Visual_Icon", hero.level >= kShoulderLevel);
}

[[nodiscard]] bool is_page_open(const hero::Hero& hero, const PageRow& row) noexcept {
    const hero::Milestones needs{.bits = row.needs};
    return hero.level >= row.level && hero.milestones.covers(needs);
}

void fill_page(Deck& deck, const hero::Hero& hero, const PageRow& row) {
    const bool is_open = is_page_open(hero, row);
    deck.reveal(row.button);
    put(deck, row.button, row.text);
    switch_on(deck, row.button, is_open);
    show_if(deck, row.veil, !is_open);
}

// SelfEquip_ShowPage trên máy chủ thường (mọi thẻ đều có mặt), rồi thẻ trang bị là thẻ đang chọn
// như nhánh OPEN_EQUIP đặt.
void fill_pages(Deck& deck, const hero::Hero& hero) {
    for (const PageRow& row : kPages)
        fill_page(deck, hero, row);
    deck.set(gui::Override{.window = "SelfEquip_SelfEquip", .name = "Selected", .value = "True"});
    deck.set(gui::Override{.window = "SelfEquip_Pet", .name = "Selected", .value = "False"});
}

} // namespace

void fill_self_equip(Deck& deck, const hero::Hero& hero, const gui::StringBook& strings) {
    fill_identity(deck, hero, strings);
    fill_gauges(deck, hero);
    fill_roots(deck, hero);
    fill_combat(deck, hero);
    fill_level_button(deck, hero);
    fill_level_lock(deck, hero);
    fill_slots(deck);
    fill_marks(deck, hero);
    fill_pages(deck, hero);
}

} // namespace game::ui::panel
