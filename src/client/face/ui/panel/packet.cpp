/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/packet.cpp
 *  PHÂN HỆ   : Ui / Panel / Packet
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hòm đồ (xem packet.hpp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/panel/packet.hpp"

#include "gui/sheet.hpp"
#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/names.hpp"
#include "ui/panel/npc_talk.hpp"
#include "ui/panel/talk.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <limits>
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
constexpr std::array<BagSize, kBagTabs> kSizes = {
    {{.current = 20, .most = 60}, {.current = 20, .most = 60}, {.current = 20, .most = 20}}};

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

// Ô hiện trên lưới. occupied sai là ô trống. Chỉ số vượt lưới thẻ đạo cụ không vào đây.
struct Cell {
    bool occupied = false;
    std::uint32_t item = 0;
    std::uint16_t count = 0;
};

constexpr std::size_t kCellCount = kBagLines * kBagRow;

// Thẻ 0 nhận ảnh túi: ô trùng chỉ số thì dòng sau thắng. Thẻ 1 và 2 không có loại túi trên dây nên trống.
// Ô item 0, count 0, hoặc chỉ số ngoài phần đang hiện của thẻ đạo cụ bị bỏ (không phải lỗi).
std::array<Cell, kCellCount> cells_of(const Packet& packet) {
    std::array<Cell, kCellCount> cells{};
    if (packet.tab != 0) return cells;
    const std::size_t room = bag_lines(0) * kBagRow;
    for (const talk::BagSlot& held : packet.bag.slots) {
        if (held.item == 0 || held.count == 0) continue;
        if (held.slot >= room || held.slot >= cells.size()) continue;
        Cell& cell = cells.at(held.slot);
        cell.occupied = true;
        cell.item = held.item;
        cell.count = held.count;
    }
    return cells;
}

// setCornerChar giữ tối đa 3 ký tự của số chồng. count 0 và 1 không ghi (2008 xoá chữ góc).
std::string stack_label(std::uint16_t count) {
    if (count <= 1) return {};
    std::string text = std::format("{}", static_cast<unsigned>(count));
    if (text.size() <= 3) return text;
    return text.substr(0, 3);
}

std::string_view item_label(const ItemNames& items, std::uint32_t item) {
    const auto largest = static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max());
    if (item > largest) return {};
    return items.name(static_cast<std::int32_t>(item));
}

// Ô có đồ: Empty False, icon, không hình khoá. Ô trống quá sức chứa: hình khoá. Có đồ trong vùng khoá thì vẫn hiện đồ.
void paint_cell(Deck& deck, std::string_view window, const Cell& cell, bool is_locked, const ItemNames& items) {
    if (!cell.occupied) {
        put(deck, window, "Empty", kTrue);
        put(deck, window, "NormalImage", {});
        put(deck, window, "BackImage", is_locked ? kLockImage : std::string_view{});
        put(deck, window, "CornerBotRight", {});
        put(deck, window, "Tooltip", {});
        return;
    }
    const std::string image = items.face(cell.item);
    const std::string count = stack_label(cell.count);
    put(deck, window, "Empty", kFalse);
    put(deck, window, "NormalImage", image);
    put(deck, window, "BackImage", {});
    put(deck, window, "CornerBotRight", count);
    put(deck, window, "Tooltip", item_label(items, cell.item));
}

// Hàng quá số hàng hiện bị giấu. Ô quá số đang dùng được mà trống thì mang hình khoá.
void paint_slots(Deck& deck, const Packet& packet, const ItemNames& items) {
    const std::array<Cell, kCellCount> cells = cells_of(packet);
    const std::size_t lines = bag_lines(packet.tab);
    const BagSize size = bag_size(packet.tab);
    for (std::size_t line = 0; line < kBagLines; ++line) {
        if (line >= lines) {
            deck.hide(kLineNames.at(line));
            continue;
        }
        for (std::size_t row = 0; row < kBagRow; ++row) {
            const std::size_t index = (line * kBagRow) + row;
            const bool is_locked = index + 1 > size.current;
            paint_cell(deck, kSlotNames.at(index), cells.at(index), is_locked, items);
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

void paint_packet(Deck& deck, const Packet& packet, const ItemNames& items, const hero::Purse& purse) {
    paint_tabs(deck, packet);
    paint_slots(deck, packet, items);
    put(deck, kFrame, "AbsoluteHeight", std::format("{:.0f}", bag_frame_height(bag_lines(packet.tab))));
    paint_purse(deck, purse);
}

} // namespace game::ui::panel
