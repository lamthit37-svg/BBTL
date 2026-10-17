/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/item/factory.cpp
 *  PHÂN HỆ   : Server / Item / Factory
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tạo thể hiện vật phẩm: xem factory.hpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "item/factory.hpp"

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/roll.hpp"
#include "item/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <cstdint>
#include <expected>

namespace game::item {
namespace {

using Unexpected = std::unexpected<Error>;

constexpr std::uint8_t kBlueQuality = 2;  // EQUALITY_BLUE của 2008

// Số ô đá của đồ lam: cột MaxGem là TRẦN, số ô thật ngẫu nhiên (ItemCreateRuler::CreateBlueEquipAttrib, xác suất
// "viết cứng trong chương trình" theo chú thích gốc). Trả số ô trong [0, cap].
std::uint8_t roll_blue_gem_slots(std::uint8_t cap, dice::Dice& dice) noexcept {
    const std::uint64_t r = dice.below(1000);
    switch (cap) {
    case 0: return 0;
    case 1: return r >= 800 ? 1 : 0;
    case 2: return r >= 900 ? 2 : (r >= 600 ? 1 : 0);
    case 3: return r >= 960 ? 3 : (r >= 800 ? 2 : (r >= 400 ? 1 : 0));
    default: return cap; // bảng có 4 ô (9 món lam): không có xác suất gốc, giữ đủ ô
    }
}

[[nodiscard]] std::int64_t expiry_hz(std::int64_t requested) noexcept {
    if (requested > 0) return requested;
    return kTicksPerSecond;
}

} // namespace

std::expected<Serial, Error> SerialAllocator::next() noexcept {
    if (next_ >= last_) return Unexpected(Error::kSerialsExhausted);
    return Serial{next_++};
}

std::expected<Instance, Error> Factory::create(const CreateRequest& request, dice::Dice& dice,
    SerialAllocator& serials) const {
    const Template* tmpl = catalog_->find(request.tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (request.count == 0 || request.count > tmpl->stack_max) return Unexpected(Error::kBadCount);
    if (request.roll.forge_level > kMaxForgeLevel) return Unexpected(Error::kBadOrigin);

    Instance out;
    out.tmpl = tmpl->id;
    out.count = request.count;
    out.bound = request.picked && tmpl->rule.pick_bind;
    if (tmpl->duration_hours > 0) {
        const std::int64_t hz = expiry_hz(request.ticks_per_second);
        const std::int64_t hours_ms = std::int64_t{tmpl->duration_hours} * 3'600'000;
        const ids::TickSpan span = ids::to_ticks(hours_ms, hz);
        out.expires_at = ids::advance(request.now, span).value();
    }
    if (tmpl->kind == Kind::kEquipment) {
        const EquipSpec& spec = tmpl->equip;
        out.durability = spec.max_durability;
        out.gem_slots = tmpl->quality == kBlueQuality ? roll_blue_gem_slots(spec.gem_slots, dice) : spec.gem_slots;
        rolls_->roll(*tmpl, *catalog_, request.roll, dice, out);
        // Đồ lam có thuộc tính ngẫu nhiên phải giám định mới tính (2008: SetItemIdent(FALSE) khi có thuộc tính lam).
        out.identified = !(tmpl->quality == kBlueQuality && out.attr_count > 0);
    } else if (tmpl->kind == Kind::kPetEquipment) {
        out.durability = tmpl->equip.max_durability;
    }

    // Cấp serial cuối cùng: mọi lỗi kiểm tra đã qua, chỉ hết khối mới làm hỏng, và khi đó không để lại gì.
    const std::expected<Serial, Error> serial = serials.next();
    if (!serial) return Unexpected(serial.error());
    out.serial = *serial;
    return out;
}

} // namespace game::item
