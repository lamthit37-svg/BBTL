// Hòm đồ (xem packet.hpp).
#include "ui/panel/packet.hpp"

#include "gui/sheet.hpp"
#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/names.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <string>
#include <string_view>

namespace game::ui::panel {
namespace {

constexpr std::string_view kFrame = "Packet_Frame";
constexpr std::string_view kTrue = "True";
constexpr std::string_view kFalse = "False";
// Hình ô khoá (set:CommonFrame38 image:ActionLock, kBagLockImageset) của ô chưa dùng được.
constexpr std::string_view kLockImage = "set:CommonFrame38 image:ActionLock";

// Tên ba thẻ theo thứ tự PACKAGE_TAB: Packet_Material, Packet_Stall, Packet_Mission.
constexpr std::array<std::string_view, kBagTabs> kTabs = {"Packet_Material", "Packet_Stall", "Packet_Mission"};

constexpr auto kLineNames = numbered<kBagLines>({.prefix = "Packet_Space_Line", .suffix = ""});
constexpr auto kSlotNames =
    grid<kBagLines, kBagRow>({.prefix = "Packet_Space_Line", .infix = "_Row", .suffix = "_button"});

// Số mặc định của script khi chưa có máy chủ (Packet_OnUpdateShow: CurrNum, MaxNum).
constexpr std::array<BagSize, kBagTabs> kSizes = {{{.current = 20, .most = 60}, {.current = 20, .most = 60},
    {.current = 20, .most = 20}}};

// Hai chiều của nhánh IsClassic trong Packet_UpdateBagLine: cao một hàng và phần cố định.
constexpr float kLineHeight = 35.0F;
constexpr float kFrameRest = 278.0F;

void put(Deck& deck, std::string_view window, std::string_view name, std::string_view value) {
    deck.set(gui::Override{.window = window, .name = name, .value = value});
}

void paint_tabs(Deck& deck, const Packet& packet) {
    for (std::size_t index = 0; index < kTabs.size(); ++index) {
        put(deck, kTabs.at(index), "Selected", index == packet.tab ? kTrue : kFalse);
    }
}

// Hàng quá số hàng hiện bị giấu; ô quá số đang dùng được mang hình khoá, ô còn lại bỏ hình nền
// (SetProperty "BackImage" rỗng).
void paint_slots(Deck& deck, const Packet& packet) {
    const std::size_t lines = bag_lines(packet.tab);
    const BagSize size = bag_size(packet.tab);
    for (std::size_t line = 0; line < kBagLines; ++line) {
        if (line >= lines) {
            deck.hide(kLineNames.at(line));
            continue;
        }
        for (std::size_t row = 0; row < kBagRow; ++row) {
            const std::size_t number = (line * kBagRow) + row + 1;
            put(deck, kSlotNames.at(number - 1), "BackImage", number > size.current ? kLockImage : std::string_view{});
        }
    }
}

// Tiền, nguyên bảo, điểm. Chữ "元宝：" và "赠点：" viết thẳng trong script gốc, không qua bảng chuỗi.
void paint_purse(Deck& deck, const hero::Purse& purse) {
    put(deck, "Packet_Money", "MoneyNumber", std::to_string(purse.money));
    put(deck, "Packet_Jiaozi", "MoneyNumber", std::to_string(purse.money_voucher));
    put(deck, "Packet_YuanBao2", "Text", std::format("元宝：{}", purse.yuanbao));
    put(deck, "Packet_BangdingYuanbao", "Text", std::format("#{{BDYB_090714_01}}{}", purse.bind_yuanbao));
    put(deck, "Packet_Fanquan", "Text", std::format("#{{YBFQ_XML_1}}{}", purse.gift_token));
    put(deck, "Packet_YuanBao", "Text", std::format("赠点：{}", purse.bonus_point));
    put(deck, "Packet_Tongbao", "Text", std::format("#{{LJSD_120508_01}}{}", purse.cash_gift));
}

} // namespace

BagSize bag_size(std::uint8_t tab) noexcept {
    return kSizes.at(std::min<std::size_t>(tab, kBagTabs - 1));
}

std::size_t bag_lines(std::uint8_t tab) noexcept {
    const std::uint32_t most = bag_size(tab).most;
    const auto row = static_cast<std::uint32_t>(kBagRow);
    return std::min<std::size_t>((most + row - 1) / row, kBagLines);
}

float bag_frame_height(std::size_t lines) noexcept {
    return (static_cast<float>(lines) * kLineHeight) + kFrameRest;
}

void press_packet(Packet& packet, std::string_view window) noexcept {
    const auto found = std::ranges::find(kTabs, window);
    if (found == kTabs.end()) return;
    packet.tab = static_cast<std::uint8_t>(found - kTabs.begin());
}

void paint_packet(Deck& deck, const Packet& packet, const hero::Purse& purse) {
    paint_tabs(deck, packet);
    paint_slots(deck, packet);
    put(deck, kFrame, "AbsoluteHeight", std::format("{:.0f}", bag_frame_height(bag_lines(packet.tab))));
    paint_purse(deck, purse);
}

} // namespace game::ui::panel
