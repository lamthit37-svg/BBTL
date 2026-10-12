#include "ui/panel/player_frame.hpp"

#include "gui/sheet.hpp"
#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <format>
#include <iterator>
#include <span>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

// Màu vàng của tên và cấp trong script gốc.
constexpr std::string_view kGold = "#cDED784";
// FlashPoint của script gốc: máu trên một phần năm thì không cảnh báo.
constexpr double kFlashPoint = 1.0 / 5.0;

constexpr Key kNameText{.window = "PlayerFrame_Name", .name = "Text"};
constexpr Key kLevelText{.window = "PlayerFrame_Level", .name = "Text"};
constexpr Key kFlashSize{.window = "PlayerFrame_HP_Flash", .name = "Size"};

constexpr std::array<std::string_view, hero::kStrikeSlots> kStrikes = {
    "PlayerFrame_DoubleHit1",
    "PlayerFrame_DoubleHit2",
    "PlayerFrame_DoubleHit3",
    "PlayerFrame_DoubleHit4",
    "PlayerFrame_DoubleHit5",
    "PlayerFrame_DoubleHit6",
    "PlayerFrame_DoubleHit7",
    "PlayerFrame_DoubleHit8",
    "PlayerFrame_DoubleHit9",
};

// Chỉ có ở layout 2026: thanh máu thứ hai, thanh và các hàng điểm riêng của môn phái mới nằm
// chồng lên thanh nộ và hàng liên kích, cùng dấu trạng thái PK. Nhân vật chưa thuộc môn phái nào
// trong số đó và không ở trạng thái PK.
constexpr std::array<std::string_view, 6> kLaterParts = {
    "PlayerFrame_HPHDSandBoxHPBK",
    "PlayerFrame_GQ",
    "PlayerFrame_DaoYi",
    "PlayerFrame_XingLingDian",
    "PlayerFrame_ERenSoulHit",
    "PlayerFrame_PVPPK",
};

void fill_bars(Deck& deck, const hero::Hero& hero) {
    deck.bar("PlayerFrame_HP", hero::fill_of(hero.health));
    deck.bar("PlayerFrame_MP", hero::fill_of(hero.mana));
    deck.bar("PlayerFrame_SP", hero::fill_of(hero.rage));
}

// Phép so của script gốc: HP / MAXHP > FlashPoint là máu đủ, trần 0 thì chia cho 1.
bool is_health_low(hero::Gauge health) noexcept {
    const double top = health.top == 0 ? 1.0 : static_cast<double>(health.top);
    return !(static_cast<double>(health.now) / top > kFlashPoint);
}

// Máu thấp: hiện lớp đỏ trên chân dung và cho cửa sổ nháy phủ đúng phần máu còn lại. Cửa sổ nháy
// là con của thanh máu nên cỡ viết theo tỉ lệ của thanh, không cần biết thanh rộng bao nhiêu.
void fill_warning(Deck& deck, hero::Gauge health) {
    if (!is_health_low(health)) {
        deck.hide("PlayerFrame_Mask");
        deck.hide("PlayerFrame_HP_Flash");
        return;
    }
    std::string& size = deck.compose(kFlashSize);
    std::format_to(std::back_inserter(size), "w:{} h:1", hero::fill_of(health));
}

void fill_identity(Deck& deck, const hero::Hero& hero) {
    std::string& name = deck.compose(kNameText);
    name.append(kGold).append(hero.name);
    std::string& level = deck.compose(kLevelText);
    std::format_to(std::back_inserter(level), "{}{}", kGold, hero.level);
    if (!hero.is_leader) deck.hide("PlayerFrame_Captain");
}

// Ô liên kích thứ i hiện khi i không vượt số điểm đang có.
void fill_strikes(Deck& deck, std::size_t points) {
    const std::size_t lit = std::min(points, kStrikes.size());
    for (const std::string_view slot : std::span(kStrikes).subspan(lit))
        deck.hide(slot);
}

// Chân dung gán vào PlayerFrame_Head_3D. Cha PlayerFrame_Head_Parent mang RoundEnabled và
// MaskImage HeadRoundRegion, nên quad của con bị mặt nạ tròn che. Khác gốc: chưa dựng đầu 3D,
// ảnh 2D của bảng chân dung thế chỗ texture mà FakeObj_Show gán vào mesh window. Ô phẳng
// Head_2D và vòng TypeFrame_2D giữ ẩn như layout.
void fill_portrait(Deck& deck, const Face& face) {
    const bool has_model = !face.model.empty();
    if (!has_model && face.image.empty()) return;
    const gui::Override shown{.window = "PlayerFrame_Head_3D",
        .name = has_model ? "FakeObject" : "Image",
        .value = has_model ? face.model : face.image};
    deck.set(shown);
}

} // namespace

void fill_player(Deck& deck, const hero::Hero& hero, const Face& face) {
    fill_bars(deck, hero);
    fill_portrait(deck, face);
    fill_warning(deck, hero.health);
    fill_identity(deck, hero);
    fill_strikes(deck, hero.strike_points);
    for (const std::string_view part : kLaterParts)
        deck.hide(part);
}

} // namespace game::ui::panel
