#pragma once
// Bốn bảng vũ khí (Table/*.tsv do TOOLS/content/export_weapons.py sinh): weapons (id hình vũ khí sang
// mẫu .obj của từng khe), weapon_items (vật phẩm khe 0 sang id hình và loại), objects (mẫu .obj sang
// các lưới .mesh và tỉ lệ), locators (điểm gắn theo xương của mẫu nhân vật và mẫu vũ khí). Id giữ số
// của Config client 2026; tên mẫu giữ đúng chữ của Model/all.obj.
// Loại vũ khí thuộc VẬT PHẨM, không thuộc hình: nhiều vật phẩm khác loại dùng chung một hình (hình
// 410 do vật phẩm đao, kiếm, quạt, vòng cùng dùng), nên clip theo loại của vật phẩm còn mẫu gắn tay
// theo hình, như CObject_Item_Equip::GetWeaponType và GetVisualID của ref.
// Hiệu ứng đồ (weapon_effects, gems): đá quý gắn vũ khí cho màu và chỉ số hiệu ứng, hiệu ứng là ô cột 29 + chỉ số - 1 của
// ItemVisualLocator của hình vũ khí (mã máy FUN_140604720, EquipItem_BodyLocator của 2026; SetRightWeaponEffect của ref).
// Nguồn: TLBB Dev src/tables/appearance.hpp@e0d89a6 (WeaponRow, WeaponHand) và tools/export/weapons.cpp.
// Khác gốc: thêm năm khe ngoài hai tay (võ hồn, chân, lưng, hai bên hông), loại tách khỏi hình, bảng
// locator và objects đọc từ TSV thay cho .tlobj đã nấu.

#include "look/appearance.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// Khe vũ khí của mẫu nhân vật, theo thứ tự cột của weapons.tsv. Mỗi khe là một Slot của một locator.
enum class Hold : std::uint8_t { kRight, kLeft, kSoul, kFoot, kBack, kWaist1, kWaist2 };
inline constexpr std::size_t kHoldCount = 7;

// Tên SlotCreate của khe trong Model/all.obj (RightWeaponObj, LeftWeaponObj, KFSObj, ...).
[[nodiscard]] std::string_view slot_name(Hold hold) noexcept;

struct WeaponRow {
    std::uint16_t id = 0;
    // Mẫu .obj theo Hold; rỗng là khe trống.
    std::array<std::string, kHoldCount> objects;
};

struct WeaponItemRow {
    std::uint32_t item = 0;
    // Id hình (khoá của weapons); -1 là vật phẩm không có hình.
    std::int32_t visual = -1;
    Weapon kind = Weapon::kNone;
};

struct ObjectRow {
    std::string name;
    // Tệp .mesh dưới Model/ theo thứ tự entity; không rỗng.
    std::vector<std::string> meshes;
    // Thuộc tính Scale của mẫu.
    std::array<float, 3> scale{1.0F, 1.0F, 1.0F};
};

// Locator như LogicModelManager::_parseSingleObject đọc: xương (rỗng là không theo xương), vị trí
// lệch, phép quay lệch dạng trục và góc radian (Quaternion::FromAngleAxis, trục không chuẩn hoá), cờ
// thứ tự áp lệch, và tên khe nó giữ (rỗng khi không giữ khe nào).
struct LocatorRow {
    std::string object;
    std::string name;
    std::string bone;
    std::array<float, 3> offset{};
    std::array<float, 3> axis{};
    float angle = 0.0F;
    bool is_translate_first = false;
    std::string slot;
};

// Số ô hiệu ứng của một hình vũ khí (ItemVisualLocator cột 29 tới 62).
inline constexpr std::size_t kEffectSlots = 34;

// Hiệu ứng đá quý của một hình vũ khí: tên effect theo chỉ số hiệu ứng 1 tới kEffectSlots (ô rỗng là không có), và cờ đá quý của
// ba khe sau (lưng, hông 1, hông 2; khe tay luôn nhận).
struct EffectRow {
    std::uint16_t visual = 0;
    bool has_back = false;
    bool has_waist1 = false;
    bool has_waist2 = false;
    std::vector<std::string> effects;
};

// Đá quý: màu RRGGBBAA dạng chuỗi hex (client gốc đọc %8X) và chỉ số hiệu ứng từ 1.
struct GemRow {
    std::uint32_t gem = 0;
    std::string colour;
    std::int32_t effect = 0;
};

// Hiệu ứng một khe nhận: tên effect (gắn vào locator 武器特效点 của mẫu vũ khí) và màu RRGGBBAA nhân vào hạt.
struct SlotEffect {
    std::string name;
    std::uint32_t colour = 0;
};

// Cả sáu bảng; rỗng là mọi người chơi tay không. Mỗi dãy xếp theo khoá của bộ đọc nên tra nhị phân.
struct WeaponTables {
    std::vector<WeaponRow> weapons;
    std::vector<WeaponItemRow> items;
    std::vector<ObjectRow> objects;
    std::vector<LocatorRow> locators;
    // Hiệu ứng đồ; rỗng là không đồ nào có hiệu ứng.
    std::vector<EffectRow> effects;
    std::vector<GemRow> gems;
};

// Cột: id (1..65535) rồi bảy khe theo Hold (right, left, kfs, foot, back, waist1, waist2; được rỗng).
// Khoá id.
[[nodiscard]] Rows<WeaponRow> read_weapons(const table::Tsv& table);

// Cột: item (0..2^32-1), visual (-1..65535), class (none, spear, blade, dual_short, short, fan, ring).
// Khoá item.
[[nodiscard]] Rows<WeaponItemRow> read_weapon_items(const table::Tsv& table);

// Cột: object, meshes (tên cách nhau bằng "|", không rỗng), sx, sy, sz (dương). Khoá object.
[[nodiscard]] Rows<ObjectRow> read_objects(const table::Tsv& table);

// Cột: object, locator, bone, x, y, z, qx, qy, qz, qw, translate_first (0, 1), slot. Khoá (object, locator).
[[nodiscard]] Rows<LocatorRow> read_locators(const table::Tsv& table);

// Cột: visual (1..65535), back, waist1, waist2 (0, 1), effects (đúng kEffectSlots ô cách nhau bằng ";"). Khoá visual.
[[nodiscard]] Rows<EffectRow> read_weapon_effects(const table::Tsv& table);

// Cột: gem (0..2^32-1), colour (chuỗi), effect (số nguyên). Khoá gem.
[[nodiscard]] Rows<GemRow> read_gems(const table::Tsv& table);

// Hiệu ứng mà đá quý đem lại cho khe hold của hình có hàng row, theo mã máy FUN_140604720: khe tay luôn nhận, khe lưng và
// hông khi cờ của hình bật, võ hồn và chân không nhận. Màu phải bắt đầu khác '-' và ký tự thứ hai khác '1' (đúng điều kiện
// của mã máy), đọc %8X thành giá trị khác 0 (màu 0 là xoá hiệu ứng ở SetRightWeaponEffect của ref); chỉ số hiệu ứng nằm
// trong 1..kEffectSlots và ô tên không rỗng. Khác gốc: chỉ số quá kEffectSlots thì không có hiệu ứng (mã máy đọc ngoài hàng).
[[nodiscard]] std::optional<SlotEffect> gem_effect(const EffectRow& row, const GemRow& gem, Hold hold);

// Tra theo khoá, O(log n); nullptr khi không có. Con trỏ mượn vào rows.
[[nodiscard]] const EffectRow* find_effects(std::span<const EffectRow> rows, std::uint16_t visual);
[[nodiscard]] const GemRow* find_gem(std::span<const GemRow> rows, std::uint32_t gem);
[[nodiscard]] const WeaponRow* find_weapon(std::span<const WeaponRow> rows, std::uint16_t id);
[[nodiscard]] const WeaponItemRow* find_weapon_item(std::span<const WeaponItemRow> rows, std::uint32_t item);
[[nodiscard]] const ObjectRow* find_object(std::span<const ObjectRow> rows, std::string_view name);
// Locator của mẫu object giữ khe slot (slot rỗng thì nullptr); nullptr khi mẫu không có khe đó.
// O(log n + số locator của mẫu).
// Locator tên name của mẫu object; nullptr khi không có. O(log n).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): object, name khác vai (HP-07)
[[nodiscard]] const LocatorRow* find_locator(std::span<const LocatorRow> rows, std::string_view object,
    std::string_view name);
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): object, slot khác vai (HP-07)
[[nodiscard]] const LocatorRow* find_slot_locator(std::span<const LocatorRow> rows, std::string_view object,
    std::string_view slot);

} // namespace game::look
