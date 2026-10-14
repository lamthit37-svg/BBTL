// Bản ghi nhị phân của túi, trang bị, kho, ví: xem codec.hpp.
#include "item/codec.hpp"

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"

#include "protocol/wire.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::item {
namespace {

using Unexpected = std::unexpected<Error>;
using protocol::ByteView;
using protocol::Reader;
using protocol::Writer;

constexpr std::uint8_t kFlagBound = 1U;
constexpr std::uint8_t kFlagIdentified = 2U;
constexpr std::uint8_t kFlagMask = kFlagBound | kFlagIdentified;
constexpr std::uint16_t kMaxWear = 5000;       // gấp 10 lần ngưỡng hao mòn của ConfigInfo.ini
constexpr std::uint8_t kMaxEnhanceLevel = 99;  // chặn rác, không phải luật chơi (luật nằm ở forge)
constexpr std::int64_t kMaxBalance = std::int64_t{1} << 40;
constexpr std::size_t kMaxItemsPerPlace = 1000;  // trần thô của số vật phẩm một nơi chứa (lớn nhất thật: 100)

// ----- ghi -------------------------------------------------------------------------------------------

void write_instance(Writer& w, std::uint16_t slot, const Instance& item) {
    w.u16(slot);
    w.u64(item.serial.value());
    w.u32(item.tmpl.value());
    w.u16(item.count);
    w.u8(static_cast<std::uint8_t>((item.bound ? kFlagBound : 0U) | (item.identified ? kFlagIdentified : 0U)));
    w.u16(item.durability);
    w.u16(item.wear);
    w.u8(item.repair_fails);
    w.u8(item.enhance);
    w.u8(item.aptitude);
    w.u8(item.gem_slots);
    for (std::size_t g = 0; g < item.gem_slots && g < item.gems.size(); ++g) w.u32(item.gems.at(g).value());
    w.u8(item.attr_count);
    for (std::size_t a = 0; a < item.attr_count && a < item.attrs.size(); ++a) {
        w.u16(item.attrs.at(a).id.value());
        w.i32(item.attrs.at(a).value);
    }
    w.u64(item.expires_at);
}

std::expected<Blob, Error> encode_places(const Inventory& inventory, std::span<const Place> places,
    std::uint16_t kind) {
    Blob out;
    Writer w(out);
    w.u16(kCodecVersion);
    w.u8(static_cast<std::uint8_t>(places.size()));
    for (const Place place : places) {
        w.u8(static_cast<std::uint8_t>(place));
        w.u16(inventory.unlocked(place));
        const std::span<const std::optional<Instance>> view = inventory.view(place);
        const auto filled = static_cast<std::size_t>(
            std::ranges::count_if(view, [](const std::optional<Instance>& c) { return c.has_value(); }));
        w.count(filled, kMaxItemsPerPlace);
        for (std::size_t i = 0; i < view.size(); ++i) {
            const std::optional<Instance>& slot = view[i];
            if (slot) write_instance(w, static_cast<std::uint16_t>(i), *slot);
        }
    }
    if (!w.finish(kind)) return Unexpected(Error::kBadBlob);
    return out;
}

// ----- đọc -------------------------------------------------------------------------------------------

// Đọc một vật phẩm và kiểm với mẫu. false = khối hỏng (Reader hoặc giá trị sai).
bool read_instance(Reader& r, const Catalog& catalog, Instance& out) {
    out.serial = Serial{r.u64()};
    out.tmpl = TemplateId{r.u32()};
    out.count = r.u16();
    const std::uint8_t flags = r.u8();
    out.durability = r.u16();
    out.wear = r.u16();
    out.repair_fails = r.u8();
    out.enhance = r.u8();
    out.aptitude = r.u8();
    out.gem_slots = r.u8();
    if (!r.is_ok() || out.serial.value() == 0 || (flags & ~kFlagMask) != 0) return false;
    out.bound = (flags & kFlagBound) != 0;
    out.identified = (flags & kFlagIdentified) != 0;
    const Template* tmpl = catalog.find(out.tmpl);
    if (tmpl == nullptr || out.count == 0 || out.count > tmpl->stack_max) return false;
    const bool equipment = tmpl->kind == Kind::kEquipment;
    if (out.durability > (equipment ? tmpl->equip.max_durability : 0) || out.wear > kMaxWear
        || out.enhance > kMaxEnhanceLevel || out.gem_slots > kMaxGemSlots || (!equipment && out.gem_slots != 0)) {
        return false;
    }
    out.gems = {};
    for (std::size_t g = 0; g < out.gem_slots; ++g) {
        const TemplateId gem{r.u32()};
        if (gem.value() != 0) {
            const Template* gem_tmpl = catalog.find(gem);
            if (gem_tmpl == nullptr || gem_tmpl->kind != Kind::kGem) return false;
        }
        out.gems.at(g) = gem;
    }
    out.attr_count = r.u8();
    if (!r.is_ok() || out.attr_count > kMaxAttrs || (!equipment && out.attr_count != 0)) return false;
    out.attrs = {};
    for (std::size_t a = 0; a < out.attr_count; ++a) {
        const std::uint16_t id = r.u16();
        const std::int32_t value = r.i32();
        if (id >= kAttrCount) return false;
        out.attrs.at(a) = AttrValue{.id = AttrId{id}, .value = value};
    }
    out.expires_at = r.u64();
    return r.is_ok();
}

// Ô `slot` của `place` nhận món này được không (khớp luật Planner: túi theo home, kho trừ túi nhiệm vụ, trang bị
// theo điểm lắp hay ô thứ hai của nhẫn và bùa).
bool fits(const Template& tmpl, Place place, std::uint16_t slot) noexcept {
    if (is_bag(place)) return tmpl.home == place;
    if (place == Place::kBank) return tmpl.home != Place::kQuestBag;
    if (place != Place::kEquip || tmpl.kind != Kind::kEquipment) return false;
    const std::uint8_t point = tmpl.equip.point;
    return slot == point || (point == kEquipRing && slot == kEquipRing2) || (point == kEquipCharm && slot == kEquipCharm2);
}

// Giải khung và trả thân; kind sai hay còn byte thừa là hỏng.
std::optional<ByteView> open_frame(ByteView blob, std::uint16_t kind) {
    const protocol::FrameResult frame = protocol::peek_frame(blob, protocol::kMaxBodyBytes);
    if (!frame || !*frame || (*frame)->kind != kind) return std::nullopt;
    const std::size_t total = protocol::kHeaderBytes + (*frame)->body_bytes;
    if (total != blob.size()) return std::nullopt;
    return blob.subspan(protocol::kHeaderBytes, (*frame)->body_bytes);
}

bool read_place(Reader& r, const Catalog& catalog, Place expected, Inventory& staged) {
    const std::uint8_t raw = r.u8();
    const std::uint16_t unlocked = r.u16();
    const std::size_t count = r.count(kMaxItemsPerPlace);  // Reader còn chặn theo số byte còn lại
    if (!r.is_ok() || raw != static_cast<std::uint8_t>(expected)) return false;
    staged.clear(expected);
    if (expected != Place::kEquip && !staged.restore_unlocked(expected, unlocked)) return false;
    if (expected == Place::kEquip && unlocked != kEquipSlots) return false;
    if (count > unlocked) return false;
    std::vector<bool> seen(unlocked, false);
    for (std::size_t i = 0; i < count; ++i) {
        const std::uint16_t slot = r.u16();
        Instance item;
        if (!r.is_ok() || slot >= unlocked || seen[slot] || !read_instance(r, catalog, item)) return false;
        const Template* tmpl = catalog.find(item.tmpl);
        if (tmpl == nullptr || !fits(*tmpl, expected, slot)) return false;
        seen[slot] = true;
        if (!staged.restore(SlotRef{.place = expected, .index = slot}, item)) return false;
    }
    return true;
}

// Mọi serial trong kho trạng thái phải khác nhau.
bool serials_unique(const Inventory& inventory) {
    std::vector<std::uint64_t> serials;
    for (std::size_t p = 0; p < kPlaceCount; ++p) {
        for (const std::optional<Instance>& c : inventory.view(static_cast<Place>(p))) {
            if (c) serials.push_back(c->serial.value());
        }
    }
    std::ranges::sort(serials);
    return std::ranges::adjacent_find(serials) == serials.end();
}

std::expected<void, Error> decode_places(ByteView blob, std::uint16_t kind, std::span<const Place> places,
    const Catalog& catalog, Inventory& into) {
    const std::optional<ByteView> body = open_frame(blob, kind);
    if (!body) return Unexpected(Error::kBadBlob);
    Reader r(*body);
    const std::uint16_t version = r.u16();
    const std::uint8_t place_count = r.u8();
    if (!r.is_ok() || version != kCodecVersion || place_count != places.size()) return Unexpected(Error::kBadBlob);
    Inventory staged = into;
    for (const Place place : places) {
        if (!read_place(r, catalog, place, staged)) return Unexpected(Error::kBadBlob);
    }
    if (!r.finish() || !serials_unique(staged)) return Unexpected(Error::kBadBlob);
    into = std::move(staged);
    return {};
}

constexpr std::array<Place, kBagKinds> kBagPlaces{Place::kBaseBag, Place::kMaterialBag, Place::kQuestBag};
constexpr std::array<Place, 1> kEquipPlace{Place::kEquip};
constexpr std::array<Place, 1> kBankPlace{Place::kBank};

} // namespace

std::expected<Blob, Error> encode_bags(const Inventory& inventory) {
    return encode_places(inventory, kBagPlaces, kBlobBags);
}

std::expected<Blob, Error> encode_equipment(const Inventory& inventory) {
    return encode_places(inventory, kEquipPlace, kBlobEquipment);
}

std::expected<Blob, Error> encode_bank(const Inventory& inventory) {
    return encode_places(inventory, kBankPlace, kBlobBank);
}

std::expected<Blob, Error> encode_wallet(const Inventory& inventory) {
    Blob out;
    Writer w(out);
    w.u16(kCodecVersion);
    std::size_t nonzero = 0;
    for (std::size_t a = 0; a < kAccountSlots; ++a) {
        if (inventory.wallet().balance(static_cast<Account>(a)) != 0) ++nonzero;
    }
    w.count(nonzero, kAccountSlots);
    for (std::size_t a = 0; a < kAccountSlots; ++a) {
        const std::int64_t value = inventory.wallet().balance(static_cast<Account>(a));
        if (value == 0) continue;
        w.u8(static_cast<std::uint8_t>(a));
        w.i64(value);
    }
    if (!w.finish(kBlobWallet)) return Unexpected(Error::kBadBlob);
    return out;
}

std::expected<void, Error> decode_bags(ByteView blob, const Catalog& catalog, Inventory& into) {
    return decode_places(blob, kBlobBags, kBagPlaces, catalog, into);
}

std::expected<void, Error> decode_equipment(ByteView blob, const Catalog& catalog, Inventory& into) {
    return decode_places(blob, kBlobEquipment, kEquipPlace, catalog, into);
}

std::expected<void, Error> decode_bank(ByteView blob, const Catalog& catalog, Inventory& into) {
    return decode_places(blob, kBlobBank, kBankPlace, catalog, into);
}

std::expected<void, Error> decode_wallet(ByteView blob, Inventory& into) {
    const std::optional<ByteView> body = open_frame(blob, kBlobWallet);
    if (!body) return Unexpected(Error::kBadBlob);
    Reader r(*body);
    const std::uint16_t version = r.u16();
    const std::size_t count = r.count(kAccountSlots);
    if (!r.is_ok() || version != kCodecVersion) return Unexpected(Error::kBadBlob);
    Inventory staged = into;
    for (std::size_t a = 0; a < kAccountSlots; ++a) {
        static_cast<void>(staged.restore_balance(static_cast<Account>(a), 0));
    }
    std::array<bool, kAccountSlots> seen{};
    for (std::size_t i = 0; i < count; ++i) {
        const std::uint8_t account = r.u8();
        const std::int64_t value = r.i64();
        if (!r.is_ok() || account >= kAccountSlots || seen.at(account) || value <= 0 || value > kMaxBalance) {
            return Unexpected(Error::kBadBlob);
        }
        seen.at(account) = true;
        if (!staged.restore_balance(static_cast<Account>(account), value)) return Unexpected(Error::kBadBlob);
    }
    if (!r.finish()) return Unexpected(Error::kBadBlob);
    into = std::move(staged);
    return {};
}

} // namespace game::item
