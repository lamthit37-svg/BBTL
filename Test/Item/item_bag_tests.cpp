// Luật túi, trang bị, ví và giá: mỗi ca dựng trạng thái bằng bảng thử (item_support.hpp, số tự đặt tường minh) rồi đối
// chiếu từng ranh giới của luật. Thao tác bị từ chối phải để NGUYÊN trạng thái: đo bằng dấu vân tay mã hoá của
// Inventory và bằng việc Plan trước và sau lệnh hỏng bằng nhau.
#include "item_support.hpp"

#include "item/bonus.hpp"
#include "item/catalog.hpp"
#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/price.hpp"
#include "item/types.hpp"
#include "test.hpp"

#include "dice/dice.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <optional>
#include <utility>
#include <vector>

namespace game::test {
namespace {

const Actor kHero{.level = 100, .sect = 3, .sex = item::kAnySex};

// ----- ca thử ---------------------------------------------------------------------------------------------------

void stacking(Context& context) {
    Bench d;
    Planner r = d.planner();
    // Factory không tạo quá cỡ chồng, nên ghép 45 cái bằng cách sửa count của bản mẫu: đường nạp từ ngoài.
    Instance big = d.make(kPotion, 20);
    big.count = 45;
    context.expect(r.add(big).has_value(), "cất 45 tách ba chồng");
    const item::Instance* s0 = r.get(bag(0));
    const item::Instance* s1 = r.get(bag(1));
    const item::Instance* s2 = r.get(bag(2));
    context.expect(s0 != nullptr && s1 != nullptr && s2 != nullptr && s0->count == 20 && s1->count == 20 && s2->count == 5, "20 + 20 + 5");
    context.expect(s0 && s1 && s2 && s0->serial != s1->serial && s1->serial != s2->serial && s0->serial != s2->serial, "mỗi chồng một serial");
    Instance ten = d.make(kPotion, 10);
    context.expect(r.add(ten).has_value(), "cất thêm 10");
    context.expect(r.get(bag(2)) != nullptr && r.get(bag(2))->count == 15 && r.get(bag(3)) == nullptr, "lấp chồng dở trước, không mở ô mới");
    Instance many = d.make(kPotion, 20);
    many.count = 100;
    context.expect(r.add(many).has_value(), "cất 100");
    context.expect(r.get(bag(2))->count == 20 && r.get(bag(7)) != nullptr && r.get(bag(7))->count == 15 && r.get(bag(8)) == nullptr,
        "chồng dở đầy, rồi bốn chồng đầy và một chồng 15");
    context.expect(r.count_of(TemplateId{kPotion}) == 155 && r.free_slots(Place::kBaseBag) == 12, "155 cái trong 8 ô, còn 12 ô trống");
    context.expect(d.commit(std::move(r)), "áp dụng kế hoạch");
    context.expect(d.inventory.count_of(TemplateId{kPotion}) == 155, "Inventory đủ 155");
    context.expect(d.inventory.revision() == 1, "revision tăng một lần");
    // Chồng khác cờ khoá không gộp với chồng thường.
    Bench e;
    Instance plain = e.make(kPotion, 5);
    Instance locked = e.make(kPotion, 5);
    locked.bound = true;
    Planner t = e.planner();
    context.expect(t.add(plain).has_value() && t.add(locked).has_value(), "cất hai chồng khác cờ khoá");
    context.expect(t.get(bag(0)) != nullptr && t.get(bag(1)) != nullptr && t.get(bag(0))->count == 5 && t.get(bag(1))->count == 5, "không gộp khác cờ khoá");
}

void bag_full_is_atomic(Context& context) {
    Bench b;
    for (std::uint16_t i = 0; i < 19; ++i) b.put(bag(i), b.make(kPickBound));
    Instance potions = b.make(kPotion, 20);
    potions.count = 19;
    b.put(bag(19), potions);  // chồng thuốc 19/20 ở ô cuối: ô cuối cùng của 20 ô mở
    const auto before = fingerprint(b.inventory);
    Planner p = b.planner();
    Instance more = b.make(kPotion, 20);
    more.count = 25;  // cần 1 chỗ lấp + 1 ô mới nhưng không còn ô nào
    const Planner untouched = p;
    context.expect(is(p.add(more), Error::kBagFull), "25 thuốc không đủ chỗ");
    context.expect(p.get(bag(19)) != nullptr && p.get(bag(19))->count == 19, "không lấp một phần khi cả lệnh hỏng");
    context.expect(Planner(untouched).finish() == Planner(p).finish(), "lớp phủ không đổi sau lệnh hỏng");
    more.count = 1;
    context.expect(p.add(more).has_value() && p.get(bag(19))->count == 20, "một cái vừa lấp chồng");
    more.count = 1;
    context.expect(is(p.add(more), Error::kBagFull), "cái tiếp theo hết chỗ");
    context.expect(is(p.add(b.make(kSword)), Error::kBagFull), "trang bị cũng hết chỗ");
    context.expect(fingerprint(b.inventory) == before, "Inventory chưa từng bị đụng");
    context.expect(b.commit(std::move(p)), "áp dụng phần đã dựng được");
    context.expect(b.inventory.count_of(TemplateId{kPotion}) == 20, "kế hoạch chỉ có một cái được thêm");
}

void routing_and_limits(Context& context) {
    Bench b;
    Planner p = b.planner();
    context.expect(p.add(b.make(kHerb, 10)).has_value() && p.get(material(0)) != nullptr && p.get(bag(0)) == nullptr, "nguyên liệu vào túi nguyên liệu");
    context.expect(p.add(b.make(kQuestItem, 3)).has_value() && p.get(quest(0)) != nullptr, "vật nhiệm vụ vào túi nhiệm vụ");
    context.expect(is(p.add_to(Place::kBaseBag, b.make(kHerb, 1)), Error::kWrongPlace), "nguyên liệu không vào túi đạo cụ");
    context.expect(is(p.add_to(Place::kBank, b.make(kQuestItem, 1)), Error::kWrongPlace), "vật nhiệm vụ không vào kho");
    context.expect(is(p.add_to(Place::kEquip, b.make(kSword)), Error::kWrongPlace), "ô trang bị chỉ nhận qua equip");
    context.expect(p.add_to(Place::kBank, b.make(kHerb, 5)).has_value() && p.get(bank(0)) != nullptr, "nguyên liệu vào kho được");
    Instance bad = b.make(kSword);
    bad.count = 2;
    context.expect(is(p.add(bad), Error::kBadCount), "trang bị không chồng, số lượng 2");
    bad.count = 0;
    context.expect(is(p.add(bad), Error::kBadCount), "số lượng 0");
    Instance ghost = b.make(kSword);
    ghost.tmpl = TemplateId{999};
    context.expect(is(p.add(ghost), Error::kUnknownTemplate), "mẫu không có");
    context.expect(p.add(b.make(kUniqueRing)).has_value(), "đồ duy nhất cất lần đầu");
    context.expect(is(p.add(b.make(kUniqueRing)), Error::kUniqueOwned), "lần hai bị từ chối");
    context.expect(is(p.add_to(Place::kBank, b.make(kUniqueRing)), Error::kUniqueOwned), "kho cũng tính vào giới hạn sở hữu");
    context.expect(b.commit(std::move(p)), "áp dụng");
    // Đồ duy nhất đang nằm trong kho vẫn chặn cất thêm vào túi.
    Bench c;
    c.put(bank(3), c.make(kUniqueRing));
    Planner q = c.planner();
    context.expect(is(q.add(c.make(kUniqueRing)), Error::kUniqueOwned), "đồ duy nhất trong kho chặn cất vào túi");
}

void removal(Context& context) {
    Bench b;
    Instance a = b.make(kPotion, 20);
    a.count = 12;
    Instance c = b.make(kPotion, 20);
    c.count = 7;
    b.put(bag(0), a);
    b.put(bag(5), c);
    Planner p = b.planner();
    context.expect(is(p.remove_count(TemplateId{kPotion}, 20), Error::kNotEnoughItems), "đòi 20 chỉ có 19");
    context.expect(is(p.remove_count(TemplateId{kPotion}, 0), Error::kBadCount), "trừ 0");
    context.expect(p.remove_count(TemplateId{kPotion}, 15).has_value(), "trừ 15 qua hai chồng");
    context.expect(p.get(bag(0)) == nullptr && p.get(bag(5)) != nullptr && p.get(bag(5))->count == 4, "chồng đầu hết, chồng sau còn 4");
    context.expect(is(p.remove_at(bag(0), 1), Error::kSlotEmpty), "ô trống");
    context.expect(is(p.remove_at(bag(5), 5), Error::kBadCount), "bỏ 5 trên chồng 4");
    context.expect(is(p.remove_at(bag(5), 0), Error::kBadCount), "bỏ 0");
    context.expect(is(p.remove_at(bag(20), 1), Error::kNoSuchSlot), "ô 20 chưa mở");
    context.expect(is(p.remove_at(bag(60000), 1), Error::kNoSuchSlot), "chỉ số thù địch");
    context.expect(p.remove_at(bag(5), 1).has_value() && p.get(bag(5))->count == 3, "bỏ 1 trên chồng 4");
    context.expect(p.remove_at(bag(5), 3).has_value() && p.get(bag(5)) == nullptr, "bỏ hết chồng");
    // Ô khoá không bị trừ và không tính vào số có.
    Bench d;
    d.put(bag(0), a);
    context.expect(d.inventory.set_lock(bag(0), true).has_value(), "khoá ô 0");
    Planner q = d.planner();
    context.expect(is(q.remove_count(TemplateId{kPotion}, 1), Error::kNotEnoughItems), "ô khoá không tính");
    context.expect(is(q.remove_at(bag(0), 1), Error::kLocked), "không bỏ từ ô khoá");
}

void move_split_merge(Context& context) {
    Bench b;
    Instance a = b.make(kPotion, 20);
    a.count = 15;
    Instance c = b.make(kPotion, 20);
    c.count = 10;
    b.put(bag(0), a);
    b.put(bag(1), c);
    b.put(bag(2), b.make(kSword));
    b.put(material(0), b.make(kHerb, 5));
    Planner p = b.planner();
    // Gộp: 15 + 10 vào 20 -> chồng đích 20, phần thừa 5 ở lại ô nguồn.
    context.expect(p.move(bag(0), bag(1)).has_value(), "kéo thuốc lên thuốc");
    context.expect(p.get(bag(1))->count == 20 && p.get(bag(0)) != nullptr && p.get(bag(0))->count == 5, "đích đầy, thừa 5 ở nguồn");
    // Đổi chỗ khác loại; về ô trống thì dời.
    context.expect(p.move(bag(0), bag(2)).has_value() && p.get(bag(2))->tmpl == TemplateId{kPotion} && p.get(bag(0))->tmpl == TemplateId{kSword}, "đổi chỗ khác loại");
    context.expect(p.move(bag(0), bag(9)).has_value() && p.get(bag(0)) == nullptr && p.get(bag(9)) != nullptr, "dời sang ô trống");
    context.expect(is(p.move(bag(9), bag(9)), Error::kNoChange), "cùng ô");
    context.expect(is(p.move(bag(9), bag(40)), Error::kNoSuchSlot), "ô đích chưa mở");
    context.expect(is(p.move(bag(0), bag(1)), Error::kSlotEmpty), "nguồn trống");
    context.expect(is(p.move(bag(9), material(1)), Error::kWrongPlace), "trang bị sang túi nguyên liệu");
    context.expect(is(p.move(bag(9), worn(0)), Error::kWrongPlace), "kéo thẳng vào ô trang bị");
    context.expect(p.move(material(0), bank(0)).has_value() && p.get(bank(0)) != nullptr, "nguyên liệu vào kho");
    // Chia.
    context.expect(p.split(bag(1), bag(10), 7).has_value() && p.get(bag(1))->count == 13 && p.get(bag(10))->count == 7, "chia 7");
    context.expect(p.get(bag(1))->serial != p.get(bag(10))->serial, "chồng mới có serial mới");
    context.expect(is(p.split(bag(1), bag(10), 1), Error::kSlotOccupied), "ô đích có đồ");
    context.expect(is(p.split(bag(1), bag(11), 0), Error::kBadCount), "chia 0");
    context.expect(is(p.split(bag(1), bag(11), 13), Error::kBadCount), "chia hết chồng");
    context.expect(is(p.split(bag(9), bag(11), 1), Error::kNotStackable), "chia trang bị");
    context.expect(is(p.split(bag(15), bag(11), 1), Error::kSlotEmpty), "chia ô trống");
    // Gộp tường minh.
    context.expect(p.merge(bag(10), bag(1)).has_value() && p.get(bag(1))->count == 20 && p.get(bag(10)) == nullptr, "gộp 7 vào 13");
    context.expect(is(p.merge(bag(2), bag(9)), Error::kDifferentItems), "gộp thuốc vào kiếm");
    context.expect(is(p.merge(bag(9), bag(2)), Error::kNotStackable), "gộp kiếm vào thuốc");
    context.expect(is(p.merge(bag(2), bag(19)), Error::kSlotEmpty), "gộp vào ô trống");
    context.expect(is(p.merge(bag(2), bag(2)), Error::kNoChange), "gộp vào chính nó");
    context.expect(b.commit(std::move(p)), "áp dụng chuỗi thao tác");
    context.expect(b.inventory.count_of(TemplateId{kPotion}) == 25 && b.inventory.count_of(TemplateId{kSword}) == 1, "bảo toàn số lượng");
}

void sorting(Context& context) {
    Bench b;
    Instance p5 = b.make(kPotion, 20);
    p5.count = 5;
    Instance p12 = b.make(kPotion, 20);
    p12.count = 12;
    Instance p20 = b.make(kPotion, 20);
    b.put(bag(7), p5);
    b.put(bag(3), p12);
    b.put(bag(15), p20);
    b.put(bag(10), b.make(kSword));
    b.put(bag(4), b.make(kPickBound));
    const auto total = b.inventory.count_of(TemplateId{kPotion});
    Planner p = b.planner();
    context.expect(p.sort(Place::kBaseBag).has_value(), "dồn túi");
    // Lớp 1 (trang bị) trước lớp 3; trong lớp 3 theo mã mẫu tăng dần: 30000001 (thuốc) rồi 30000003 (khoá khi nhặt).
    context.expect(p.get(bag(0)) != nullptr && p.get(bag(0))->tmpl == TemplateId{kSword}, "trang bị đứng đầu");
    context.expect(p.get(bag(1)) != nullptr && p.get(bag(1))->count == 20 && p.get(bag(2)) != nullptr && p.get(bag(2))->count == 17, "thuốc gộp 20 + 17");
    context.expect(p.get(bag(3)) != nullptr && p.get(bag(3))->tmpl == TemplateId{kPickBound} && p.get(bag(4)) == nullptr, "không còn ô trống xen kẽ");
    context.expect(p.count_of(TemplateId{kPotion}) == total, "sắp xếp bảo toàn số lượng");
    context.expect(b.commit(std::move(p)), "áp dụng");
    Planner again = b.planner();
    context.expect(again.sort(Place::kBaseBag).has_value() && std::move(again).finish().empty(), "dồn lần hai không đổi gì (bất động)");
    context.expect(is(b.planner().sort(Place::kEquip), Error::kWrongPlace), "không dồn ô trang bị");
    context.expect(b.inventory.set_lock(bag(0), true).has_value(), "khoá ô 0");
    Planner locked = b.planner();
    context.expect(is(locked.sort(Place::kBaseBag), Error::kLocked), "có ô khoá thì không dồn");
}

void locks_block_everything(Context& context) {
    Bench b;
    b.put(bag(0), b.make(kSword));
    b.put(bag(1), b.make(kPotion, 10));
    context.expect(b.inventory.set_lock(bag(0), true).has_value() && b.inventory.set_lock(bag(1), true).has_value(), "khoá hai ô");
    Planner p = b.planner();
    context.expect(is(p.equip(bag(0), kHero), Error::kLocked), "mặc từ ô khoá");
    context.expect(is(p.move(bag(1), bag(5)), Error::kLocked), "kéo từ ô khoá");
    context.expect(is(p.move(bag(5), bag(1)), Error::kSlotEmpty) || is(p.move(bag(5), bag(1)), Error::kLocked), "kéo vào ô khoá");
    context.expect(is(p.split(bag(1), bag(5), 3), Error::kLocked), "chia từ ô khoá");
    context.expect(is(p.identify(bag(0)), Error::kLocked) || is(p.identify(bag(0)), Error::kNoChange), "giám định ô khoá");
    // Ô khoá trống bị bỏ qua khi tìm chỗ.
    Bench c;
    context.expect(c.inventory.set_lock(bag(0), true).has_value(), "khoá ô trống 0");
    Planner q = c.planner();
    context.expect(q.add(c.make(kSword)).has_value() && q.get(bag(0)) == nullptr && q.get(bag(1)) != nullptr, "bỏ qua ô khoá trống");
    context.expect(q.free_slots(Place::kBaseBag) == 18, "ô khoá không tính là trống");
    context.expect(is(c.inventory.set_lock(bag(500), true), Error::kNoSuchSlot), "khoá ô ngoài miền");
}

void equip_rules(Context& context) {
    Bench b;
    b.put(bag(0), b.make(kSword));  // cấp 10
    b.put(bag(1), b.make(kSectSword));  // cấp 20, phái 3
    Planner p = b.planner();
    context.expect(is(p.equip(bag(0), Actor{.level = 9, .sect = 3}), Error::kLevelTooLow), "cấp 9 mặc đồ cấp 10");
    context.expect(is(p.equip(bag(1), Actor{.level = 20, .sect = 4}), Error::kWrongSect), "sai môn phái");
    context.expect(is(p.equip(bag(2), kHero), Error::kSlotEmpty), "ô trống");
    context.expect(is(p.equip(bag(300), kHero), Error::kNoSuchSlot), "ô thù địch");
    context.expect(is(p.equip(worn(0), kHero), Error::kWrongPlace), "mặc từ ô trang bị");
    context.expect(p.equip(bag(0), Actor{.level = 10, .sect = 0}).has_value(), "cấp 10 mặc được");
    context.expect(p.get(bag(0)) == nullptr && p.get(worn(0)) != nullptr && p.get(worn(0))->bound, "kiếm vào ô 0 và khoá khi mặc");
    // Mặc đồ thứ hai vào cùng điểm lắp: đồ cũ về đúng ô nguồn.
    context.expect(p.equip(bag(1), kHero).has_value(), "mặc kiếm phái");
    context.expect(p.get(worn(0))->tmpl == TemplateId{kSectSword} && p.get(bag(1)) != nullptr && p.get(bag(1))->tmpl == TemplateId{kSword}, "đồ cũ về ô nguồn");
    // Không phải trang bị.
    b.put(bag(3), b.make(kPotion, 3));
    Planner q = b.planner();
    context.expect(is(q.equip(bag(3), kHero), Error::kNotEquipment), "thuốc không mặc được");
    // Tháo.
    context.expect(is(q.unequip(0), Error::kSlotEmpty), "tháo ô trống");
    context.expect(is(q.unequip(200), Error::kNoSuchSlot), "tháo ô thù địch");
    context.expect(q.equip(bag(0), kHero).has_value() && q.unequip(0).has_value() && q.get(worn(0)) == nullptr && q.get(bag(0)) != nullptr, "tháo về ô trống đầu tiên");
    // Túi đầy thì không tháo được và không mất đồ.
    Bench c;
    for (std::uint16_t i = 0; i < 20; ++i) c.put(bag(i), c.make(kPickBound));
    c.put(worn(0), c.make(kSword));
    const auto before = fingerprint(c.inventory);
    Planner full = c.planner();
    context.expect(is(full.unequip(0), Error::kBagFull) && full.get(worn(0)) != nullptr, "túi đầy không tháo được");
    context.expect(std::move(full).finish().empty() && fingerprint(c.inventory) == before, "không đổi gì");
}

void identify_and_pairs(Context& context) {
    Bench b;
    Instance blue = b.make(kBlueRing);
    context.expect(!blue.identified && blue.attr_count > 0, "nhẫn lam mới sinh chưa giám định");
    b.put(bag(0), blue);
    b.put(bag(1), b.make(kWhiteRing));
    b.put(bag(2), b.make(kWhiteRing));
    b.put(bag(3), b.make(kWhiteRing));
    b.put(bag(4), b.make(kCharm));
    b.put(bag(5), b.make(kCharm));
    Planner p = b.planner();
    context.expect(is(p.equip(bag(0), kHero), Error::kNotIdentified), "đồ lam chưa giám định");
    context.expect(p.identify(bag(0)).has_value() && p.get(bag(0))->identified, "giám định");
    context.expect(is(p.identify(bag(0)), Error::kNoChange), "giám định lần hai");
    context.expect(is(p.identify(bag(9)), Error::kSlotEmpty), "giám định ô trống");
    b.put(bag(6), b.make(kPotion, 2));
    Planner q = b.planner();
    context.expect(is(q.identify(bag(6)), Error::kNotEquipment), "giám định thuốc");
    // Nhẫn: ô 6 rồi ô 11 rồi đổi với ô 6.
    context.expect(p.equip(bag(1), kHero).has_value() && p.get(worn(6)) != nullptr, "nhẫn thứ nhất vào điểm 6");
    context.expect(p.equip(bag(2), kHero).has_value() && p.get(worn(11)) != nullptr, "nhẫn thứ hai vào điểm 11");
    const std::uint64_t serial_first = p.get(worn(6))->serial.value();
    context.expect(p.equip(bag(3), kHero).has_value() && p.get(worn(6)) != nullptr && p.get(worn(6))->serial.value() != serial_first, "nhẫn thứ ba thay ô 6");
    context.expect(p.get(bag(3)) != nullptr && p.get(bag(3))->serial.value() == serial_first, "nhẫn cũ về đúng ô nguồn");
    context.expect(p.equip(bag(4), kHero).has_value() && p.get(worn(12)) != nullptr, "bùa thứ nhất vào điểm 12");
    context.expect(p.equip(bag(5), kHero).has_value() && p.get(worn(13)) != nullptr, "bùa thứ hai vào điểm 13");
    context.expect(b.commit(std::move(p)), "áp dụng");
}

void wear_repair_and_bonus(Context& context) {
    Bench b;
    Instance sword = b.make(kSword);  // độ bền 100, nền 500/500
    b.put(worn(0), sword);
    b.put(worn(6), b.make(kWhiteRing));
    Planner p = b.planner();
    // Ngưỡng 3: bốn lần đánh thì mất một độ bền (wear 0->1->2->3 rồi lần thứ tư vượt ngưỡng).
    for (int i = 0; i < 3; ++i) context.expect(p.wear_weapon(3).has_value(), "hao mòn vũ khí");
    context.expect(p.get(worn(0))->wear == 3 && p.get(worn(0))->durability == 100, "ba lần: hao 3, độ bền còn nguyên");
    context.expect(p.wear_weapon(3).has_value() && p.get(worn(0))->wear == 0 && p.get(worn(0))->durability == 99, "lần thứ tư: mất 1 độ bền");
    context.expect(p.wear_armor(3).has_value() && p.get(worn(0))->wear == 0 && p.get(worn(6))->wear == 1, "giáp hao mà vũ khí không");
    // Độ bền về 0 thì không hao thêm và không cho thuộc tính.
    Instance dying = b.make(kSword);
    dying.durability = 1;
    dying.wear = 3;
    b.put(worn(0), dying);
    Planner q = b.planner();
    context.expect(q.wear_weapon(3).has_value() && q.get(worn(0))->durability == 0, "về 0");
    context.expect(q.wear_weapon(3).has_value() && q.get(worn(0))->durability == 0, "không âm");
    context.expect(b.commit(std::move(q)), "áp dụng");
    const auto bonuses = item::equipment_bonuses(b.inventory, b.world.catalog);
    context.expect(bonuses.empty(), "hết độ bền thì kiếm không cho nền");

    // Sửa: kiếm giá 1000, độ bền 40/100, hệ số cửa hàng 1000 -> (2*1000*60*1000 + 1000*100) / (2000*100) = 600.
    Instance worn_sword = b.make(kSword);
    worn_sword.durability = 40;
    b.put(bag(0), worn_sword);
    context.expect(b.inventory.wallet().balance(Currency::kGold) == 0, "ví trống");
    Planner poor = b.planner();
    context.expect(is(poor.repair(bag(0), 1000), Error::kInsufficientFunds), "không đủ tiền sửa");
    Planner rich = b.planner();
    context.expect(rich.earn(Currency::kGold, 1000).has_value() && rich.repair(bag(0), 1000).has_value(), "đủ tiền");
    context.expect(rich.get(bag(0))->durability == 100 && rich.balance(item::account_of(Currency::kGold)) == 400, "sửa đầy, trừ 600");
    context.expect(is(rich.repair(bag(0), 1000), Error::kNoChange), "đã đầy độ bền");
    Planner half = b.planner();
    context.expect(half.earn(Currency::kGold, 1000).has_value() && half.repair(bag(0), 500).has_value() && half.balance(item::account_of(Currency::kGold)) == 700, "phí cửa hàng 0,5: trừ 300");
    context.expect(is(half.repair(bag(9), 1000), Error::kSlotEmpty), "sửa ô trống");
    b.put(bag(2), b.make(kPotion, 2));
    context.expect(is(b.planner().repair(bag(2), 1000), Error::kNoDurability), "thuốc không sửa được");
    context.expect(is(b.planner().repair(bank(0), 1000), Error::kWrongPlace), "không sửa đồ trong kho");
}

void bonus_totals(Context& context) {
    Bench b;
    Instance sword = b.make(kSword);
    b.put(worn(0), sword);
    Instance ring = b.make(kBlueRing);
    ring.identified = true;
    ring.attr_count = 3;
    ring.attrs.at(0) = item::AttrValue{.id = item::AttrId{3}, .value = 7};
    ring.attrs.at(1) = item::AttrValue{.id = item::AttrId{3}, .value = 5};
    ring.attrs.at(2) = item::AttrValue{.id = item::AttrId{58}, .value = 20};
    ring.gem_slots = 1;
    ring.gems.at(0) = TemplateId{kGem};
    b.put(worn(6), ring);
    // Nhẫn thứ hai chưa giám định: thuộc tính ngẫu nhiên ẩn, nhưng phần cộng nền (id >= 58) vẫn tính.
    Instance hidden = b.make(kBlueRing);
    hidden.identified = false;
    hidden.attr_count = 2;
    hidden.attrs.at(0) = item::AttrValue{.id = item::AttrId{3}, .value = 1000};
    hidden.attrs.at(1) = item::AttrValue{.id = item::AttrId{58}, .value = 1};
    b.put(worn(11), hidden);
    const auto totals = item::equipment_bonuses(b.inventory, b.world.catalog);
    const auto find = [&totals](std::uint16_t id) {
        for (const item::AttrValue& v : totals) {
            if (v.id.value() == id) return v.value;
        }
        return 0;
    };
    context.expect(find(3) == 12, "hai dòng cùng thuộc tính 3 cộng thành 12; dòng ẩn không tính");
    context.expect(find(19) == 10, "đá quý +10 tấn công vật lý (id 19)");
    context.expect(find(58) == 500 + 200 + 20 + 200 + 1, "nền kiếm 500 + nền nhẫn 200 + tư chất 20 + nền nhẫn ẩn 200 + 1");
    context.expect(find(59) == 500 + 200 + 200, "nền phép: 500 + 200 + 200");
    for (std::size_t i = 1; i < totals.size(); ++i) context.expect(totals[i - 1].id.value() < totals[i].id.value(), "xếp tăng theo id");
}

void wallet_rules(Context& context) {
    Bench b;
    Planner p = b.planner();
    context.expect(p.earn(Currency::kGold, 100'000'000).has_value(), "đúng trần vàng cấp 1");
    context.expect(is(p.earn(Currency::kGold, 1), Error::kOverCap), "vượt trần một đồng");
    context.expect(is(p.earn(Currency::kIngot, std::numeric_limits<std::int64_t>::max()), Error::kOverCap), "số tiền thù địch không tràn");
    context.expect(is(p.earn(Currency::kIngot, 0), Error::kBadAmount) && is(p.earn(Currency::kIngot, -5), Error::kBadAmount), "số không và số âm");
    context.expect(is(p.spend(Currency::kIngot, 1), Error::kInsufficientFunds), "chưa có nguyên bảo");
    context.expect(is(p.spend(Currency::kGold, std::numeric_limits<std::int64_t>::min()), Error::kBadAmount), "số âm cực trị");
    context.expect(p.earn(Currency::kIngot, 2'000'000'000).has_value() && is(p.earn(Currency::kIngot, 1), Error::kOverCap), "nguyên bảo đúng trần");
    context.expect(is(p.earn(static_cast<Currency>(0), 1), Error::kUnknownCurrency), "mã tiền 0 không được lọt vào vàng kho");
    context.expect(is(p.spend(static_cast<Currency>(0), 1), Error::kUnknownCurrency), "mã tiền 0 không tiêu được");
    context.expect(is(p.earn(static_cast<Currency>(99), 1), Error::kUnknownCurrency), "mã tiền 99");
    // Gửi và rút vàng kho (trần 10 triệu).
    context.expect(p.deposit_gold(10'000'000).has_value() && p.balance(item::Account::kBankGold) == 10'000'000, "gửi đủ trần kho");
    context.expect(is(p.deposit_gold(1), Error::kOverCap), "kho đầy");
    context.expect(p.withdraw_gold(4'000'000).has_value() && p.balance(item::account_of(Currency::kGold)) == 94'000'000, "rút 4 triệu");
    context.expect(is(p.withdraw_gold(6'000'001), Error::kInsufficientFunds), "rút quá số gửi");
    // Rút khi ví đã đầy: ví là bên nhận nên kOverCap, kho giữ nguyên.
    Bench c;
    Planner q = c.planner();
    context.expect(q.earn(Currency::kGold, 100'000'000).has_value() && q.deposit_gold(500).has_value() && q.earn(Currency::kGold, 500).has_value(), "đầy ví sau khi gửi 500");
    context.expect(is(q.withdraw_gold(1), Error::kOverCap) && q.balance(item::Account::kBankGold) == 500, "rút khi ví đầy bị từ chối, kho không đổi");
    // Trần vàng theo cấp (bảng thật có 150 dòng; ở bàn thử dùng bảng dựng tay).
    item::Limits custom = item::Limits::defaults();
    custom.gold_cap_by_level = {1000, 2000, 3000};
    context.expect(custom.gold_cap(1) == 1000 && custom.gold_cap(3) == 3000 && custom.gold_cap(50) == 3000 && custom.gold_cap(0) == 1000, "trần theo cấp, ngoài bảng lấy dòng gần nhất");
    item::Inventory inv(custom);
    inv.set_level_cap(2);
    item::SerialAllocator ids(1, 100);
    Planner r(inv, b.world.catalog, ids);
    context.expect(r.earn(Currency::kGold, 2000).has_value() && is(r.earn(Currency::kGold, 1), Error::kOverCap), "đổi cấp 2: trần 2000");
    context.expect(inv.apply(std::move(r).finish()).has_value(), "áp dụng");
    inv.set_level_cap(1);
    Planner s(inv, b.world.catalog, ids);
    context.expect(is(s.earn(Currency::kGold, 1), Error::kOverCap), "hạ cấp không cắt số dư nhưng chặn tăng");
    context.expect(s.spend(Currency::kGold, 1500).has_value(), "vẫn tiêu được khi đang vượt trần");
}

void apply_contract(Context& context) {
    Bench b;
    b.put(bag(0), b.make(kSword));
    Planner p = b.planner();
    context.expect(p.move(bag(0), bag(5)).has_value() && p.earn(Currency::kGold, 50).has_value(), "dựng kế hoạch");
    item::Plan plan = std::move(p).finish();
    context.expect(plan.slots.size() == 2 && plan.balances.size() == 1 && plan.revision == 0, "hai ô và một số dư");
    context.expect(b.inventory.apply(plan).has_value(), "áp dụng lần một");
    context.expect(is(b.inventory.apply(plan), Error::kStalePlan), "áp dụng lần hai bị từ chối (revision cũ)");
    // Kế hoạch hỏng: từng kiểu, mỗi kiểu giữ nguyên trạng thái.
    const auto before = fingerprint(b.inventory);
    item::Plan base;
    base.revision = b.inventory.revision();
    item::Plan out_of_range = base;
    out_of_range.slots.push_back({.where = bag(200), .after = std::nullopt});
    context.expect(is(b.inventory.apply(out_of_range), Error::kBrokenPlan), "ô ngoài miền");
    item::Plan zero_count = base;
    Instance empty = b.make(kPotion, 1);
    empty.count = 0;
    zero_count.slots.push_back({.where = bag(1), .after = empty});
    context.expect(is(b.inventory.apply(zero_count), Error::kBrokenPlan), "số lượng 0");
    item::Plan twice = base;
    twice.slots.push_back({.where = bag(1), .after = std::nullopt});
    twice.slots.push_back({.where = bag(1), .after = std::nullopt});
    context.expect(is(b.inventory.apply(twice), Error::kBrokenPlan), "ô trùng");
    item::Plan wrong_balance = base;
    wrong_balance.balances.push_back({.account = item::account_of(Currency::kGold), .before = 7, .after = 8});
    context.expect(is(b.inventory.apply(wrong_balance), Error::kStalePlan), "số dư gốc không khớp");
    item::Plan negative = base;
    negative.balances.push_back({.account = item::account_of(Currency::kGold), .before = 50, .after = -1});
    context.expect(is(b.inventory.apply(negative), Error::kBrokenPlan), "số dư âm");
    item::Plan over = base;
    over.balances.push_back({.account = item::account_of(Currency::kGold), .before = 50, .after = 1'000'000'000});
    context.expect(is(b.inventory.apply(over), Error::kOverCap), "vượt trần");
    item::Plan two_accounts = base;
    two_accounts.balances.push_back({.account = item::account_of(Currency::kGold), .before = 50, .after = 60});
    two_accounts.balances.push_back({.account = item::account_of(Currency::kGold), .before = 50, .after = 70});
    context.expect(is(b.inventory.apply(two_accounts), Error::kBrokenPlan), "tài khoản trùng");
    item::Plan unknown_account = base;
    unknown_account.balances.push_back({.account = static_cast<item::Account>(200), .before = 0, .after = 1});
    context.expect(is(b.inventory.apply(unknown_account), Error::kBrokenPlan), "tài khoản lạ");
    context.expect(fingerprint(b.inventory) == before, "mọi kế hoạch hỏng không để lại gì");
    context.expect(b.inventory.apply(base).has_value(), "kế hoạch rỗng luôn qua");
    // Mở thêm ô.
    context.expect(b.inventory.unlock_slots(Place::kBaseBag, 40).has_value() && b.inventory.unlocked(Place::kBaseBag) == 60, "mở đủ 60 ô");
    context.expect(is(b.inventory.unlock_slots(Place::kBaseBag, 1), Error::kBadCount), "quá sức chứa");
    context.expect(is(b.inventory.unlock_slots(Place::kEquip, 1), Error::kWrongPlace), "ô trang bị cố định");
    context.expect(is(b.inventory.unlock_slots(Place::kBank, 0), Error::kBadCount), "mở 0 ô");
}

void price_values(Context& context) {
    const World w = make_world();
    const item::Template* sword = w.catalog.find(TemplateId{kSword});
    const item::Template* potion = w.catalog.find(TemplateId{kPotion});
    const item::Template* no_sell = w.catalog.find(TemplateId{kNoSell});
    const item::Template* blue = w.catalog.find(TemplateId{kBlueRing});
    if (sword == nullptr || potion == nullptr || no_sell == nullptr || blue == nullptr) {
        context.expect(false, "thiếu mẫu thử");
        return;
    }
    const item::PriceRules rules{.identified_sale_permille = 250, .unidentified_sale_permille = 100};
    Instance fresh;
    fresh.tmpl = sword->id;
    fresh.count = 1;
    fresh.identified = true;
    fresh.durability = 100;
    // Kiếm giá gốc 1000: 1000 * 250 / 1000 = 250; độ bền 50 -> 125; một lần sửa hỏng chia đôi -> 62.
    context.expect(item::sell_value(*sword, fresh, rules, 1000) == 250, "kiếm nguyên vẹn bán 250");
    Instance half = fresh;
    half.durability = 50;
    context.expect(item::sell_value(*sword, half, rules, 1000) == 125, "độ bền một nửa");
    half.repair_fails = 1;
    context.expect(item::sell_value(*sword, half, rules, 1000) == 62, "một lần sửa hỏng, làm tròn xuống");
    context.expect(item::sell_value(*sword, fresh, rules, 500) == 125, "tỉ lệ cửa hàng 0,5");
    Instance beyond = fresh;
    beyond.durability = 60000;  // dữ liệu hỏng không làm giá vượt giá gốc
    context.expect(item::sell_value(*sword, beyond, rules, 1000) == 250, "độ bền quá mức bị kẹp");
    // Thuốc: 100 * 10 cái * 250 / 1000 = 250.
    Instance stack;
    stack.tmpl = potion->id;
    stack.count = 10;
    stack.identified = true;
    context.expect(item::sell_value(*potion, stack, rules, 1000) == 250, "chồng 10 thuốc");
    const auto forbidden = item::sell_value(*no_sell, stack, rules, 1000);
    context.expect(!forbidden && forbidden.error() == Error::kForbidden, "đồ cấm bán");
    Instance unknown;
    unknown.tmpl = blue->id;
    unknown.count = 1;
    unknown.identified = false;
    unknown.durability = 100;
    context.expect(item::sell_value(*blue, unknown, rules, 1000) == 100, "đồ lam chưa giám định bán theo 100/1000");
    // Tràn: giá gốc rất lớn x số lượng lớn x tỉ lệ lớn phải báo kBadAmount, không tràn thầm.
    item::Template huge = *potion;
    huge.base_price = std::numeric_limits<std::int32_t>::max();
    Instance mass;
    mass.tmpl = potion->id;
    mass.count = 65535;
    mass.identified = true;
    const auto overflow = item::sell_value(huge, mass, rules, std::numeric_limits<std::uint32_t>::max());
    context.expect(!overflow && overflow.error() == Error::kBadAmount, "phép nhân tràn được báo lỗi");
    // Phí sửa.
    fresh.durability = 40;
    context.expect(item::repair_cost(*sword, fresh, 1000) == 600, "sửa 60% giá 1000 = 600");
    context.expect(item::repair_cost(*sword, fresh, 0) == 0, "cửa hàng sửa miễn phí");
    fresh.durability = 99;
    context.expect(item::repair_cost(*sword, fresh, 1000) == 10, "sửa 1 điểm = 10");
    fresh.durability = 100;
    context.expect(item::repair_cost(*sword, fresh, 1000) == 0, "đầy độ bền không tốn");
    context.expect(item::repair_cost(*potion, stack, 1000) == 0, "đồ không hao mòn");
    const item::Template* unbreakable = w.catalog.find(TemplateId{kCharm});
    context.expect(unbreakable != nullptr, "bùa có trong bảng");
}

constexpr std::array kCases{
    Case{"stacking", stacking},
    Case{"bag_full_is_atomic", bag_full_is_atomic},
    Case{"routing_and_limits", routing_and_limits},
    Case{"removal", removal},
    Case{"move_split_merge", move_split_merge},
    Case{"sorting", sorting},
    Case{"locks_block_everything", locks_block_everything},
    Case{"equip_rules", equip_rules},
    Case{"identify_and_pairs", identify_and_pairs},
    Case{"wear_repair_and_bonus", wear_repair_and_bonus},
    Case{"bonus_totals", bonus_totals},
    Case{"wallet_rules", wallet_rules},
    Case{"apply_contract", apply_contract},
    Case{"price_values", price_values},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
