#pragma once
// Kiểu nền của lõi vật phẩm máy chủ: loại tiền, nơi chứa, thuộc tính trang bị, mã lỗi.
// Không có trạng thái và không đọc bảng; mọi module còn lại của item, loot, shop, forge dựa vào đây.
//
// Nguồn: id nơi chứa và loại tiền đọc từ Lua giao diện client 2026 (Packet.lua: ba túi đạo cụ,
// nguyên liệu, nhiệm vụ; Shop.lua và DressSuperToolTip.lua: CU_* = 1..12); điểm lắp trang bị từ
// SelfEquip.lua (HEQUIP_* = 0..18, 19 long văn) và cột equip_point của EquipBase.txt (0..23).
// Khác gốc: mã 2008 chỉ có một túi (MAX_BAG_SIZE) và bảy kiểu tiền ngầm trong Obj_Human; bản này tách
// ba túi như client 2026 và gom tiền vào một bảng số dư theo mã CU_* của client.

#include "ids/ids.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace game::item {

using TemplateId = ids::ItemTemplateId;
using Serial = ids::ItemSerial;

// ----- Loại tiền -------------------------------------------------------------------------------
// Số = CU_* của client 2026 (Shop.lua). Giá trị 13..16 có trong cột loại tiền của ShopTable.txt
// (14 và 16) nhưng client không đặt tên; giữ nguyên số, ví vẫn có ô để cửa hàng đó chạy được.
enum class Currency : std::uint8_t {
    kGold = 1,        // MONEY: tiền vàng
    kGoodBad = 2,     // điểm thiện ác
    kMoralPoint = 3,  // điểm sư đức
    kTicket = 4,      // tiền quan phiếu
    kIngot = 5,       // YUANBAO: nguyên bảo
    kBonusPoint = 6,  // ZENGDIAN: điểm tặng
    kSectPoint = 7,   // điểm cống hiến môn phái
    kBoundGold = 8,   // MONEY_JZ: giao tử (tiền khoá)
    kBoundIngot = 9,  // BIND_YUANBAO: nguyên bảo khoá
    kGiftToken = 10,  // GIFTTOKEN: phản quyển
    kVoucher = 11,    // LIJIN: lễ kim
    kHonour = 12,     // điểm vinh dự đại hội tỉ võ
};

inline constexpr std::size_t kCurrencySlots = 17;  // chỉ số 0 để trống, 1..16 theo mã client

[[nodiscard]] constexpr bool is_valid_currency(std::uint8_t raw) noexcept {
    return raw >= 1 && raw < kCurrencySlots;
}

// ----- Nơi chứa --------------------------------------------------------------------------------
enum class Place : std::uint8_t {
    kBaseBag = 0,      // túi đạo cụ ("base" của Packet.lua)
    kMaterialBag = 1,  // túi nguyên liệu ("material")
    kQuestBag = 2,     // túi nhiệm vụ ("quest")
    kEquip = 3,        // điểm lắp trang bị, chỉ số = HEQUIP_*
    kBank = 4,         // kho
};

inline constexpr std::size_t kPlaceCount = 5;
inline constexpr std::size_t kBagKinds = 3;  // ba túi đầu của Place

[[nodiscard]] constexpr bool is_bag(Place place) noexcept {
    return static_cast<std::uint8_t>(place) < kBagKinds;
}

[[nodiscard]] std::string_view describe(Place place) noexcept;

// Điểm lắp: chỉ số trong Place::kEquip. 11 là nhẫn thứ hai, 13 là bùa hộ thân thứ hai: trang bị của
// chúng khai equip_point 6 và 12, người chơi đặt vào ô thứ nhất hoặc ô thứ hai.
inline constexpr std::uint8_t kEquipWeapon = 0;
inline constexpr std::uint8_t kEquipRing = 6;
inline constexpr std::uint8_t kEquipRing2 = 11;
inline constexpr std::uint8_t kEquipCharm = 12;
inline constexpr std::uint8_t kEquipCharm2 = 13;
inline constexpr std::size_t kEquipSlots = 24;  // equip_point lớn nhất trong EquipBase.txt là 23

// Nhịp mô phỏng của máy chủ (KE-HOACH-SERVER mục 1): thời hạn của vật phẩm tính bằng tick.
inline constexpr std::int64_t kTicksPerSecond = 20;

// ----- Giới hạn cứng của một thể hiện ------------------------------------------------------------
inline constexpr std::size_t kMaxRolledAttrs = 10;  // trần số thuộc tính ngẫu nhiên một dòng bảng được khai (bảng thật: 9)
inline constexpr std::size_t kBaseAttrCount = 6;    // thuộc tính nền: id 58..63
inline constexpr std::size_t kMaxAttrs = 16;        // thuộc tính lưu trên một thể hiện: ngẫu nhiên + cộng tư chất cho thuộc tính nền
static_assert(kMaxRolledAttrs + kBaseAttrCount <= kMaxAttrs);
inline constexpr std::size_t kMaxGemSlots = 4;      // MAX_ITEM_GEM 2008 là 3; bảng client 2026 có trang bị 4 ô (cột 100)
inline constexpr std::uint16_t kMaxStack = 255;     // cột tile lớn nhất của CommonItem.txt

// ----- Thuộc tính cộng ---------------------------------------------------------------------------
// Id thuộc tính nội bộ của module item. 0..53 trùng ITEM_ATTRIBUTE của 2008 (IATTRIBUTE_POINT_MAXHP
// ... IATTRIBUTE_SKILL_RATE); 54..57 là bốn "giảm kháng" chỉ có từ bản 2012 trở đi; 58..63 là sáu
// thuộc tính nền của trang bị. Thứ tự này là thứ tự cột 30..87 rồi 24..29 của EquipBase.txt và
// cột 11..68 của GemInfo.txt (cùng vị trí, tên khác chút). Module actor ghép bằng tên: attr_name().
using AttrId = ids::StrongId<struct AttrTag, std::uint16_t>;

inline constexpr std::size_t kAttrCount = 64;
inline constexpr std::size_t kRollableAttrs = 58;  // id 0..57: có thể cộng ngẫu nhiên và gắn đá
inline constexpr std::uint16_t kAttrBasePhysicalAttack = 58;
inline constexpr std::uint16_t kAttrBaseMagicAttack = 59;
inline constexpr std::uint16_t kAttrBasePhysicalDefence = 60;
inline constexpr std::uint16_t kAttrBaseMagicDefence = 61;
inline constexpr std::uint16_t kAttrBaseHit = 62;
inline constexpr std::uint16_t kAttrBaseMiss = 63;

struct AttrValue {
    AttrId id;
    std::int32_t value = 0;

    friend constexpr bool operator==(const AttrValue&, const AttrValue&) noexcept = default;
};

// Tên tiếng Anh không dấu của thuộc tính theo cột EquipBase.txt; rỗng khi id ngoài miền.
[[nodiscard]] std::string_view attr_name(AttrId id) noexcept;
[[nodiscard]] std::array<std::string_view, kAttrCount> attr_names() noexcept;

// ----- Lỗi ---------------------------------------------------------------------------------------
enum class [[nodiscard]] Error : std::uint8_t {
    kUnknownTemplate = 1,  // id vật phẩm không có trong catalog
    kBadCount,             // số lượng 0 hoặc vượt ngưỡng
    kNoSuchSlot,           // chỉ số ô ngoài nơi chứa
    kSlotEmpty,            // ô nguồn trống
    kSlotOccupied,         // ô đích đã có đồ mà thao tác không cho đè
    kLocked,               // ô đang bị khoá (giao dịch, cửa hàng)
    kBagFull,              // hết ô trống
    kStackFull,            // chồng đã đầy
    kNotStackable,         // vật phẩm không chồng được
    kDifferentItems,       // hai ô khác loại không gộp được
    kWrongPlace,           // vật phẩm không được để ở nơi chứa này
    kNotEquipment,         // không phải trang bị
    kWrongEquipSlot,       // điểm lắp không khớp trang bị
    kLevelTooLow,          // chưa đủ cấp
    kWrongSect,            // sai môn phái
    kWrongSex,             // sai giới tính
    kNotIdentified,        // đồ lam chưa giám định
    kForbidden,            // ItemRule cấm (vứt, bán, giao dịch, dùng)
    kUniqueOwned,          // đã đạt giới hạn sở hữu (max_owned)
    kInsufficientFunds,    // không đủ tiền
    kOverCap,              // vượt trần ví
    kNotEnoughItems,       // không đủ số lượng vật phẩm để trừ
    kStalePlan,            // kế hoạch dựng trên trạng thái cũ
    kBrokenPlan,           // kế hoạch có thay đổi ngoài miền (lỗi của nơi dựng)
    kBadAmount,            // số tiền âm hoặc quá lớn
    kUnknownCurrency,      // mã tiền ngoài 1..16
    kNoDurability,         // vật phẩm không có độ bền
    kRepairFailed,         // quá số lần sửa cho phép
    kSerialsExhausted,     // hết khối serial được cấp
    kBadData,              // dữ liệu bảng hỏng
    kBadBlob,              // bản ghi nhị phân hỏng
    kNoChange,             // thao tác không đổi gì (đã giám định, đã đầy độ bền, hai ô trùng nhau)
    kBadOrigin,            // nguồn sinh đồ ngoài miền (cấp nguyên liệu rèn > 8)
    kNotOwner,             // hộp rơi của người khác, chưa tới lúc ai cũng nhặt được (loot)
    kBoxExpired,           // hộp rơi đã hết hạn (loot)
    kNoSuchEntry,          // chỉ số ô trong hộp rơi hay dòng hàng ngoài miền hoặc đã trống (loot, shop)
    kSoldOut,              // hàng đã hết lượt bán (shop)
    kShopRefuses,          // cửa hàng không nhận món này: cấp hoặc loại ngoài phạm vi thu mua và sửa (shop)
    kWrongScene,           // cửa hàng không mở được ở cảnh này (shop)
};

[[nodiscard]] std::string_view describe(Error error) noexcept;

}  // namespace game::item
