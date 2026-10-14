#pragma once
// Tạo thể hiện vật phẩm mới: cấp serial, đặt độ bền, ô đá, thuộc tính ngẫu nhiên và hạn dùng theo mẫu.
//
// Nguồn: ItemManager::CreateNewItem/_CreateEquipFromTable và ItemCreateRuler của 2008 (CreateCommonEquipAttrib,
// CreateBlueEquipAttrib: độ bền = tối đa, số ô đá của đồ lam ngẫu nhiên theo cột MaxGem, giám định lại khi có
// thuộc tính lam). Khác gốc: thuộc tính ngẫu nhiên đi qua RollTables (roll.hpp) vì bảng gộp của client 2026 dùng
// ItemSeg thay ItemQuality/ItemValue; đồ nào ngoài đồ lam đều lấy số ô đá thẳng từ bảng, 2008 cũng làm vậy với đồ
// trắng và lục.

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstdint>
#include <expected>

namespace game::item {

// Cấp serial duy nhất. Serial là khối [first, last): world cấp khối cho mỗi zone (ItemSerial.ini của 2008) để hai
// zone không cấp trùng; hết khối là lỗi, không quay vòng.
class SerialAllocator {
public:
    SerialAllocator(std::uint64_t first, std::uint64_t last) noexcept : next_(first), last_(last) {}

    [[nodiscard]] std::expected<Serial, Error> next() noexcept;
    [[nodiscard]] std::uint64_t cursor() const noexcept { return next_; }
    [[nodiscard]] std::uint64_t remaining() const noexcept { return next_ < last_ ? last_ - next_ : 0; }

private:
    std::uint64_t next_;
    std::uint64_t last_;
};

struct CreateRequest {
    TemplateId tmpl;
    std::uint16_t count = 1;
    bool picked = false;  // nhặt từ đất: đồ có cờ khoá-khi-nhặt thì khoá ngay
    ids::Tick now{};      // mốc tính hạn dùng
    RollContext roll{};   // nguồn món đồ (quái, rương, rèn...): chọn cột ItemSegQuality của trang bị
};

class Factory {
public:
    Factory(const Catalog& catalog, const RollTables& rolls) noexcept : catalog_(&catalog), rolls_(&rolls) {}

    // Lỗi: kUnknownTemplate, kBadCount (0 hay quá cỡ chồng), kBadOrigin (cấp rèn > 8), kSerialsExhausted. Đồ chồng được có count bất kỳ trong
    // [1, stack_max]; trang bị luôn count 1.
    [[nodiscard]] std::expected<Instance, Error> create(const CreateRequest& request, dice::Dice& dice,
        SerialAllocator& serials) const;

    [[nodiscard]] const Catalog& catalog() const noexcept { return *catalog_; }

private:
    const Catalog* catalog_;
    const RollTables* rolls_;
};

} // namespace game::item
