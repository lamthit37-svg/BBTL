// Bản ghi nhị phân có phiên bản: vòng đi-về chính xác từng byte, mọi tiền tố bị cắt, mọi bit bị lật, và từng kiểu dữ
// liệu hỏng dựng tay. Quy tắc cốt lõi: giải mã thất bại thì Inventory đích giữ NGUYÊN (dấu vân tay bằng nhau), giải
// mã thành công thì kết quả luôn hợp lệ (mã hoá lại được và đọc lại ra đúng cùng trạng thái).
#include "item_support.hpp"

#include "item/catalog.hpp"
#include "item/codec.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"
#include "test.hpp"

#include "protocol/wire.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using item::Blob;

// ----- đồ phụ ---------------------------------------------------------------------------------------------------

// Kho đồ giàu đủ loại: chồng thường, nguyên liệu, nhiệm vụ, trang bị có thuộc tính, đá quý, hạn dùng, ô khoá-khi-mặc,
// cả ví nhiều loại tiền và kho. Dùng Bench::put (đường nạp) nên không phụ thuộc luật Planner.
void fill_rich(Bench& b) {
    b.put(bag(0), b.make(kPotion, 17));
    b.put(bag(4), b.make(kPickBound, 1, true));
    Instance blue = b.make(kBlueRing);
    blue.identified = true;
    blue.gem_slots = 2;
    blue.gems.at(0) = TemplateId{kGem};
    blue.gems.at(1) = TemplateId{0};  // ô đá trống
    blue.expires_at = 123456789;
    blue.enhance = 7;
    blue.wear = 321;
    blue.repair_fails = 2;
    b.put(bag(9), blue);
    b.put(material(2), b.make(kHerb, 250));
    b.put(quest(0), b.make(kQuestItem, 99));
    b.put(bank(5), b.make(kSword));
    b.put(bank(6), b.make(kUniqueRing));
    Instance worn_sword = b.make(kSword);
    worn_sword.bound = true;
    worn_sword.durability = 61;
    b.put(worn(0), worn_sword);
    Instance ring = b.make(kBlueRing);
    ring.identified = true;
    b.put(worn(11), ring);  // nhẫn ở ô thứ hai (điểm lắp 6, ô 11)
    b.put(worn(12), b.make(kCharm));
    if (!b.inventory.unlock_slots(Place::kBaseBag, 15).has_value()) std::abort();
    Planner p = b.planner();
    if (!p.earn(Currency::kGold, 98'765).has_value() || !p.earn(Currency::kIngot, 4321).has_value() ||
        !p.earn(Currency::kBoundGold, 5).has_value() || !p.earn(Currency::kGold, 1).has_value() || !p.deposit_gold(10'000).has_value()) {
        std::abort();
    }
    if (!b.commit(std::move(p))) std::abort();
}

struct Blobs {
    Blob bags, equipment, bank, wallet;
};

Blobs encode_all(const item::Inventory& inventory) {
    auto bags = item::encode_bags(inventory);
    auto equipment = item::encode_equipment(inventory);
    auto bank_blob = item::encode_bank(inventory);
    auto wallet = item::encode_wallet(inventory);
    if (!bags || !equipment || !bank_blob || !wallet) std::abort();
    return {std::move(*bags), std::move(*equipment), std::move(*bank_blob), std::move(*wallet)};
}

bool decode_all(const Blobs& blobs, const item::Catalog& catalog, item::Inventory& into) {
    return item::decode_bags(blobs.bags, catalog, into).has_value() && item::decode_equipment(blobs.equipment, catalog, into).has_value() &&
        item::decode_bank(blobs.bank, catalog, into).has_value() && item::decode_wallet(blobs.wallet, into).has_value();
}

// Dựng thân khung bằng Writer của protocol rồi đóng khung: dùng để tạo các bản ghi hỏng có chủ đích.
struct Raw {
    Blob bytes;
    protocol::Writer writer{bytes};

    Raw() = default;
    Raw(const Raw&) = delete;
    Raw& operator=(const Raw&) = delete;
    Raw(Raw&&) = delete;
    Raw& operator=(Raw&&) = delete;
    ~Raw() = default;
};

struct AttrEntry {
    std::uint16_t id = 0;
    std::int32_t value = 0;
};

struct AccountEntry {
    std::uint8_t account = 0;
    std::int64_t value = 0;
};

// Một vật phẩm đúng định dạng, mỗi tham số có thể bị phá. Mặc định là chồng 3 thuốc, serial 77.
struct ItemBytes {
    std::uint16_t slot = 0;
    std::uint64_t serial = 77;
    std::uint32_t tmpl = kPotion;
    std::uint16_t count = 3;
    std::uint8_t flags = 0;
    std::uint16_t durability = 0;
    std::uint16_t wear = 0;
    std::uint8_t gem_slots = 0;
    std::vector<std::uint32_t> gems;
    std::uint8_t attr_count = 0;
    std::vector<AttrEntry> attrs;
};

void write_item(protocol::Writer& w, const ItemBytes& it) {
    w.u16(it.slot);
    w.u64(it.serial);
    w.u32(it.tmpl);
    w.u16(it.count);
    w.u8(it.flags);
    w.u16(it.durability);
    w.u16(it.wear);
    w.u8(0);  // repair_fails
    w.u8(0);  // enhance
    w.u8(0);  // aptitude
    w.u8(it.gem_slots);
    for (const std::uint32_t g : it.gems) w.u32(g);
    w.u8(it.attr_count);
    for (const AttrEntry& attr : it.attrs) {
        w.u16(attr.id);
        w.i32(attr.value);
    }
    w.u64(0);  // expires_at
}

// Khối túi gồm ba nơi chứa; chỉ nơi đầu có vật phẩm.
Blob bag_blob(const std::vector<ItemBytes>& base_items, std::uint16_t version = item::kCodecVersion, std::uint8_t places = 3,
    std::uint16_t base_unlocked = 20, std::size_t declared = static_cast<std::size_t>(-1)) {
    Raw raw;
    raw.writer.u16(version);
    raw.writer.u8(places);
    raw.writer.u8(static_cast<std::uint8_t>(Place::kBaseBag));
    raw.writer.u16(base_unlocked);
    raw.writer.count(declared == static_cast<std::size_t>(-1) ? base_items.size() : declared, 1000);
    for (const ItemBytes& it : base_items) write_item(raw.writer, it);
    raw.writer.u8(static_cast<std::uint8_t>(Place::kMaterialBag));
    raw.writer.u16(20);
    raw.writer.count(0, 1000);
    raw.writer.u8(static_cast<std::uint8_t>(Place::kQuestBag));
    raw.writer.u16(60);
    raw.writer.count(0, 1000);
    if (!raw.writer.finish(item::kBlobBags)) std::abort();
    return std::move(raw.bytes);
}

bool bag_blob_rejected(Context& context, const Blob& blob, const World& w, const char* what) {
    item::Inventory inv(w.limits);
    const auto before = fingerprint(inv);
    const auto result = item::decode_bags(blob, w.catalog, inv);
    const bool ok = !result && result.error() == item::Error::kBadBlob && fingerprint(inv) == before;
    context.expect(ok, what);
    return ok;
}

// ----- ca thử ---------------------------------------------------------------------------------------------------

void roundtrip_is_exact(Context& context) {
    Bench b;
    fill_rich(b);
    const Blobs blobs = encode_all(b.inventory);
    item::Inventory fresh(b.world.limits);
    context.expect(decode_all(blobs, b.world.catalog, fresh), "giải mã đủ bốn khối");
    const Blobs again = encode_all(fresh);
    context.expect(again.bags == blobs.bags && again.equipment == blobs.equipment && again.bank == blobs.bank && again.wallet == blobs.wallet,
        "mã hoá lại ra đúng từng byte");
    // Đối chiếu nội dung, không chỉ byte: ô, số mở, số dư.
    context.expect(fresh.unlocked(Place::kBaseBag) == 35, "số ô mở của túi được giữ");
    const Instance* blue = fresh.get(bag(9));
    context.expect(blue != nullptr && blue->expires_at == 123456789 && blue->enhance == 7 && blue->wear == 321 && blue->repair_fails == 2,
        "trường lẻ của trang bị giữ nguyên");
    context.expect(blue != nullptr && blue->gem_slots == 2 && blue->gems.at(0) == TemplateId{kGem} && blue->gems.at(1) == TemplateId{0}, "ô đá");
    context.expect(fresh.get(worn(0)) != nullptr && fresh.get(worn(0))->durability == 61 && fresh.get(worn(0))->bound, "độ bền và khoá của đồ đang mặc");
    context.expect(fresh.get(worn(11)) != nullptr, "nhẫn ở ô thứ hai");
    context.expect(fresh.wallet().balance(Currency::kGold) == 98'765 + 1 - 10'000 && fresh.wallet().bank_gold() == 10'000 &&
            fresh.wallet().balance(Currency::kIngot) == 4321 && fresh.wallet().balance(Currency::kBoundGold) == 5,
        "ví");
    context.expect(fresh.count_of(TemplateId{kHerb}) == 250 && fresh.count_of(TemplateId{kQuestItem}) == 99, "túi nguyên liệu và nhiệm vụ");
    context.expect(contents(fresh) == contents(b.inventory), "nội dung hai Inventory giống nhau");
    // Kho trống cũng mã hoá được và đọc lại được.
    const item::Inventory empty(b.world.limits);
    const Blobs empties = encode_all(empty);
    item::Inventory target = b.inventory;
    context.expect(decode_all(empties, b.world.catalog, target) && contents(target) == contents(empty), "kho trống thay thế kho đầy");
}

void every_truncation_fails_cleanly(Context& context) {
    Bench b;
    fill_rich(b);
    const Blobs blobs = encode_all(b.inventory);
    // Đích có sẵn dữ liệu khác để chứng minh "giữ nguyên".
    Bench target;
    target.put(bag(1), target.make(kPotion, 4));
    Planner p = target.planner();
    if (!p.earn(Currency::kGold, 777).has_value() || !target.commit(std::move(p))) std::abort();
    const auto before = fingerprint(target.inventory);
    const std::array<std::pair<const Blob*, int>, 4> all{{{&blobs.bags, 0}, {&blobs.equipment, 1}, {&blobs.bank, 2}, {&blobs.wallet, 3}}};
    std::size_t tried = 0;
    for (const auto& [blob, which] : all) {
        for (std::size_t cut = 0; cut < blob->size(); ++cut) {
            const std::span<const std::byte> prefix(blob->data(), cut);
            const auto result = which == 0   ? item::decode_bags(prefix, b.world.catalog, target.inventory)
                : which == 1                 ? item::decode_equipment(prefix, b.world.catalog, target.inventory)
                : which == 2                 ? item::decode_bank(prefix, b.world.catalog, target.inventory)
                                             : item::decode_wallet(prefix, target.inventory);
            ++tried;
            if (result || result.error() != item::Error::kBadBlob || fingerprint(target.inventory) != before) {
                context.expect(false, "tiền tố bị cắt phải bị từ chối và không đổi gì");
                return;
            }
        }
        // Thêm một byte thừa cũng hỏng.
        Blob longer = *blob;
        longer.push_back(std::byte{0});
        const std::span<const std::byte> extra(longer);
        const auto result = which == 0   ? item::decode_bags(extra, b.world.catalog, target.inventory)
            : which == 1                 ? item::decode_equipment(extra, b.world.catalog, target.inventory)
            : which == 2                 ? item::decode_bank(extra, b.world.catalog, target.inventory)
                                         : item::decode_wallet(extra, target.inventory);
        context.expect(!result && fingerprint(target.inventory) == before, "byte thừa ở cuối");
    }
    context.expect(tried > 500, "đã thử hàng trăm độ dài cắt");
}

void every_bit_flip_is_safe(Context& context) {
    Bench b;
    fill_rich(b);
    const Blobs blobs = encode_all(b.inventory);
    Bench target;
    target.put(bag(1), target.make(kPotion, 4));
    const auto before = fingerprint(target.inventory);
    std::uint64_t accepted = 0;
    std::uint64_t rejected = 0;
    const std::array<std::pair<const Blob*, int>, 4> all{{{&blobs.bags, 0}, {&blobs.equipment, 1}, {&blobs.bank, 2}, {&blobs.wallet, 3}}};
    for (const auto& [blob, which] : all) {
        for (std::size_t byte = 0; byte < blob->size(); ++byte) {
            for (unsigned bit = 0; bit < 8; ++bit) {
                Blob mutated = *blob;
                mutated[byte] = static_cast<std::byte>(static_cast<unsigned>(mutated[byte]) ^ (1U << bit));
                item::Inventory into = target.inventory;
                const auto result = which == 0   ? item::decode_bags(mutated, b.world.catalog, into)
                    : which == 1                 ? item::decode_equipment(mutated, b.world.catalog, into)
                    : which == 2                 ? item::decode_bank(mutated, b.world.catalog, into)
                                                 : item::decode_wallet(mutated, into);
                if (!result) {
                    ++rejected;
                    if (result.error() != item::Error::kBadBlob || fingerprint(into) != before) {
                        context.expect(false, "bản ghi lật bit bị từ chối phải giữ nguyên Inventory");
                        return;
                    }
                    continue;
                }
                // Chấp nhận thì kết quả phải hợp lệ: mã hoá lại được, và đọc lại ra đúng cùng trạng thái.
                ++accepted;
                const Blobs re = encode_all(into);
                item::Inventory twin(b.world.limits);
                if (!decode_all(re, b.world.catalog, twin) || encode_all(twin).bags != re.bags || encode_all(twin).wallet != re.wallet) {
                    context.expect(false, "bản ghi được chấp nhận phải mã hoá-giải mã lại được");
                    return;
                }
            }
        }
    }
    context.expect(rejected > 0 && accepted > 0, "cả đường từ chối lẫn đường chấp nhận đều được chạy");
    context.expect(accepted + rejected > 4000, "đã thử hàng nghìn phép lật bit");
}

void hand_built_corruptions(Context& context) {
    const World w = make_world();
    const ItemBytes good;
    {
        item::Inventory inv(w.limits);
        context.expect(item::decode_bags(bag_blob({good}), w.catalog, inv).has_value() && inv.get(bag(0)) != nullptr, "khối mẫu hợp lệ nạp được");
    }
    ItemBytes bad = good;
    bad.serial = 0;
    bag_blob_rejected(context, bag_blob({bad}), w, "serial 0");
    bad = good;
    bad.tmpl = 4;
    bag_blob_rejected(context, bag_blob({bad}), w, "mẫu không có");
    bad = good;
    bad.count = 0;
    bag_blob_rejected(context, bag_blob({bad}), w, "số lượng 0");
    bad = good;
    bad.count = 21;
    bag_blob_rejected(context, bag_blob({bad}), w, "vượt cỡ chồng");
    bad = good;
    bad.flags = 4;
    bag_blob_rejected(context, bag_blob({bad}), w, "cờ lạ");
    bad = good;
    bad.durability = 1;
    bag_blob_rejected(context, bag_blob({bad}), w, "đồ thường có độ bền");
    bad = good;
    bad.wear = 5001;
    bag_blob_rejected(context, bag_blob({bad}), w, "hao mòn quá trần");
    bad = good;
    bad.gem_slots = 1;
    bad.gems = {0};
    bag_blob_rejected(context, bag_blob({bad}), w, "đồ thường có ô đá");
    bad = good;
    bad.attr_count = 1;
    bad.attrs = {{3, 5}};
    bag_blob_rejected(context, bag_blob({bad}), w, "đồ thường có thuộc tính");
    bad = good;
    bad.slot = 20;
    bag_blob_rejected(context, bag_blob({bad}), w, "ô 20 chưa mở");
    bad = good;
    bad.slot = 65535;
    bag_blob_rejected(context, bag_blob({bad}), w, "ô thù địch");
    ItemBytes other = good;
    other.slot = 1;
    bag_blob_rejected(context, bag_blob({good, other}), w, "hai vật phẩm trùng serial");
    other.serial = 78;
    other.slot = 0;
    bag_blob_rejected(context, bag_blob({good, other}), w, "hai vật phẩm cùng ô");
    // Trang bị sai chỗ và hỏng.
    ItemBytes sword = good;
    sword.tmpl = kSword;
    sword.count = 1;
    sword.durability = 100;
    {
        item::Inventory inv(w.limits);
        context.expect(item::decode_bags(bag_blob({sword}), w.catalog, inv).has_value(), "kiếm hợp lệ");
    }
    ItemBytes broken = sword;
    broken.durability = 101;
    bag_blob_rejected(context, bag_blob({broken}), w, "độ bền quá tối đa");
    broken = sword;
    broken.gem_slots = 5;
    broken.gems = {0, 0, 0, 0, 0};
    bag_blob_rejected(context, bag_blob({broken}), w, "năm ô đá");
    broken = sword;
    broken.gem_slots = 1;
    broken.gems = {kPotion};
    bag_blob_rejected(context, bag_blob({broken}), w, "ô đá chứa vật không phải đá");
    broken = sword;
    broken.gem_slots = 1;
    broken.gems = {999};
    bag_blob_rejected(context, bag_blob({broken}), w, "ô đá chứa mẫu không có");
    broken = sword;
    broken.attr_count = 17;
    for (std::uint16_t i = 0; i < 17; ++i) broken.attrs.push_back({.id = i, .value = 1});
    bag_blob_rejected(context, bag_blob({broken}), w, "17 thuộc tính");
    broken = sword;
    broken.attr_count = 1;
    broken.attrs = {{64, 1}};
    bag_blob_rejected(context, bag_blob({broken}), w, "thuộc tính 64");
    // Khung và đầu.
    bag_blob_rejected(context, bag_blob({good}, 2), w, "phiên bản 2");
    bag_blob_rejected(context, bag_blob({good}, 0), w, "phiên bản 0");
    bag_blob_rejected(context, bag_blob({good}, item::kCodecVersion, 2), w, "hai nơi chứa thay vì ba");
    bag_blob_rejected(context, bag_blob({good}, item::kCodecVersion, 3, 61), w, "mở 61 ô khi sức chứa 60");
    bag_blob_rejected(context, bag_blob({good}, item::kCodecVersion, 3, 20, 5), w, "khai 5 vật phẩm chỉ có 1");
    bag_blob_rejected(context, bag_blob({good}, item::kCodecVersion, 3, 20, 1000), w, "khai 1000 vật phẩm");
    bag_blob_rejected(context, bag_blob({good}, item::kCodecVersion, 3, 0), w, "mở 0 ô nhưng có vật phẩm");
    // Khối trang bị trong khối túi và ngược lại: sai loại khung.
    Bench b;
    fill_rich(b);
    const Blobs blobs = encode_all(b.inventory);
    item::Inventory inv(b.world.limits);
    const auto before = fingerprint(inv);
    context.expect(!item::decode_bags(blobs.bank, b.world.catalog, inv) && !item::decode_bank(blobs.bags, b.world.catalog, inv) &&
            !item::decode_equipment(blobs.wallet, b.world.catalog, inv) && !item::decode_wallet(blobs.equipment, inv),
        "sai loại khung");
    context.expect(fingerprint(inv) == before, "sai loại khung không đổi gì");
    context.expect(!item::decode_bags({}, b.world.catalog, inv), "khối rỗng");
}

void equipment_blob_places(Context& context) {
    const World w = make_world();
    const auto equip_blob = [](const ItemBytes& it) {
        Raw raw;
        raw.writer.u16(item::kCodecVersion);
        raw.writer.u8(1);
        raw.writer.u8(static_cast<std::uint8_t>(Place::kEquip));
        raw.writer.u16(static_cast<std::uint16_t>(item::kEquipSlots));
        raw.writer.count(1, 1000);
        write_item(raw.writer, it);
        if (!raw.writer.finish(item::kBlobEquipment)) std::abort();
        return std::move(raw.bytes);
    };
    const auto accepted = [&](const ItemBytes& it) {
        item::Inventory inv(w.limits);
        return item::decode_equipment(equip_blob(it), w.catalog, inv).has_value();
    };
    ItemBytes sword;
    sword.tmpl = kSword;
    sword.count = 1;
    sword.durability = 100;
    sword.slot = 0;
    context.expect(accepted(sword), "kiếm ở điểm 0");
    sword.slot = 1;
    context.expect(!accepted(sword), "kiếm không ở điểm 1");
    ItemBytes ring = sword;
    ring.tmpl = kWhiteRing;
    ring.slot = 6;
    context.expect(accepted(ring), "nhẫn ở điểm 6");
    ring.slot = 11;
    context.expect(accepted(ring), "nhẫn ở điểm 11 (ô thứ hai)");
    ring.slot = 13;
    context.expect(!accepted(ring), "nhẫn không ở ô bùa thứ hai");
    ItemBytes charm = sword;
    charm.tmpl = kCharm;
    charm.slot = 13;
    context.expect(accepted(charm), "bùa ở ô thứ hai");
    ItemBytes potion;
    potion.slot = 0;
    context.expect(!accepted(potion), "thuốc không mặc được");
    ItemBytes far = sword;
    far.slot = 24;
    context.expect(!accepted(far), "điểm lắp 24 ngoài miền");
}

void wallet_blob(Context& context) {
    const World w = make_world();
    const auto wallet_blob = [](std::uint16_t version, const std::vector<AccountEntry>& entries, std::size_t declared) {
        Raw raw;
        raw.writer.u16(version);
        raw.writer.count(declared, 17);
        for (const AccountEntry& entry : entries) {
            raw.writer.u8(entry.account);
            raw.writer.i64(entry.value);
        }
        if (!raw.writer.finish(item::kBlobWallet)) std::abort();
        return std::move(raw.bytes);
    };
    const auto rejected = [&](const Blob& blob, const char* what) {
        item::Inventory inv(w.limits);
        const auto before = fingerprint(inv);
        const auto result = item::decode_wallet(blob, inv);
        context.expect(!result && result.error() == item::Error::kBadBlob && fingerprint(inv) == before, what);
    };
    {
        item::Inventory inv(w.limits);
        context.expect(item::decode_wallet(wallet_blob(1, {{1, 500}, {5, 7}}, 2), inv).has_value() && inv.wallet().balance(Currency::kGold) == 500 &&
                inv.wallet().balance(Currency::kIngot) == 7,
            "ví hợp lệ");
    }
    rejected(wallet_blob(1, {{1, 500}, {1, 600}}, 2), "tài khoản trùng");
    rejected(wallet_blob(1, {{1, -5}}, 1), "số dư âm");
    rejected(wallet_blob(1, {{1, 0}}, 1), "số dư 0 không được ghi");
    rejected(wallet_blob(1, {{17, 5}}, 1), "tài khoản 17");
    rejected(wallet_blob(1, {{255, 5}}, 1), "tài khoản 255");
    rejected(wallet_blob(1, {{1, (std::int64_t{1} << 40) + 1}}, 1), "số dư vượt trần mã hoá");
    rejected(wallet_blob(1, {{1, 5}}, 2), "khai 2 chỉ có 1");
    rejected(wallet_blob(1, {{1, 5}, {2, 5}}, 1), "khai 1 có 2");
    rejected(wallet_blob(2, {}, 0), "phiên bản 2");
    {
        item::Inventory inv(w.limits);
        context.expect(item::decode_wallet(wallet_blob(1, {{0, 5}}, 1), inv).has_value() && inv.wallet().bank_gold() == 5, "tài khoản 0 là vàng kho");
    }
}

void cross_blob_serial_collision(Context& context) {
    Bench a;
    a.put(bag(0), a.make(kPotion, 3));
    Bench c;
    c.put(bank(0), c.make(kPotion, 3));  // cùng serial 1 vì mỗi Bench cấp từ 1
    const Blobs from_a = encode_all(a.inventory);
    const Blobs from_c = encode_all(c.inventory);
    item::Inventory inv(a.world.limits);
    context.expect(item::decode_bags(from_a.bags, a.world.catalog, inv).has_value(), "nạp túi");
    const auto before = fingerprint(inv);
    const auto result = item::decode_bank(from_c.bank, a.world.catalog, inv);
    context.expect(!result && result.error() == item::Error::kBadBlob, "serial trùng xuyên khối bị bắt");
    context.expect(fingerprint(inv) == before, "không đổi gì");
}

void decode_invalidates_plans(Context& context) {
    Bench b;
    b.put(bag(0), b.make(kSword));
    Planner p = b.planner();
    context.expect(p.move(bag(0), bag(1)).has_value(), "dựng kế hoạch");
    const item::Plan plan = std::move(p).finish();
    const Blobs blobs = encode_all(b.inventory);
    context.expect(decode_all(blobs, b.world.catalog, b.inventory), "nạp lại");
    context.expect(is(b.inventory.apply(plan), item::Error::kStalePlan), "kế hoạch dựng trước khi nạp lại không còn áp dụng được");
}

void real_catalog_roundtrip(Context& context) {
#ifdef GAME_SERVER_TABLES
    const std::string root = GAME_SERVER_TABLES;
    auto catalog = item::Catalog::load({.rules = read_text(root + "/shared/item_rules.tsv"), .common = read_text(root + "/shared/items_common.tsv"),
        .equipment = read_text(root + "/shared/equipment.tsv"), .gems = read_text(root + "/shared/gems.tsv"),
        .pet_equipment = read_text(root + "/shared/pet_equipment_base.tsv"), .extra_attributes = {}});
    context.expect(catalog.has_value(), "bảng thật nạp được");
    if (!catalog) return;
    const item::Limits limits = item::Limits::defaults();
    item::Inventory inv(limits);
    std::uint64_t serial = 1;
    std::size_t placed = 0;
    for (const item::Template& t : catalog->all()) {
        if (placed >= 20) break;
        if (t.kind != item::Kind::kEquipment || t.home != Place::kBaseBag) continue;
        Instance one;
        one.serial = item::Serial{serial++};
        one.tmpl = t.id;
        one.count = 1;
        one.identified = true;
        one.durability = t.equip.max_durability;
        one.gem_slots = t.equip.gem_slots;
        one.attr_count = 3;
        one.attrs.at(0) = item::AttrValue{.id = item::AttrId{static_cast<std::uint16_t>(placed % item::kRollableAttrs)}, .value = 1000 + static_cast<int>(placed)};
        one.attrs.at(1) = item::AttrValue{.id = item::AttrId{58}, .value = -5};
        one.attrs.at(2) = item::AttrValue{.id = item::AttrId{63}, .value = 2'000'000'000};
        if (!inv.restore(bag(static_cast<std::uint16_t>(placed)), one)) continue;
        ++placed;
    }
    const auto blob = item::encode_bags(inv);
    context.expect(blob.has_value(), "mã hoá túi thật");
    if (!blob) return;
    item::Inventory back(limits);
    context.expect(item::decode_bags(*blob, *catalog, back).has_value() && contents(back) == contents(inv), "túi thật vòng đi-về");
#else
    static_cast<void>(context);
#endif
}

constexpr std::array kCases{
    Case{"roundtrip_is_exact", roundtrip_is_exact},
    Case{"every_truncation_fails_cleanly", every_truncation_fails_cleanly},
    Case{"every_bit_flip_is_safe", every_bit_flip_is_safe},
    Case{"hand_built_corruptions", hand_built_corruptions},
    Case{"equipment_blob_places", equipment_blob_places},
    Case{"wallet_blob", wallet_blob},
    Case{"cross_blob_serial_collision", cross_blob_serial_collision},
    Case{"decode_invalidates_plans", decode_invalidates_plans},
    Case{"real_catalog_roundtrip", real_catalog_roundtrip},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
