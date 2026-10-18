/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Look/look_tests.cpp
 *  PHÂN HỆ   : Look / Look Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm giải ngoại hình người chơi: bộ mặc định của giới, mặt và tóc sai giới
 *    hay không có thì về mặc định, kiểu tóc không lưới, mũ và trang phục không
 *    có, thứ tự vẽ (tóc sau cùng), clip đứng và chạy, lỗi khi bảng thiếu thứ
 *    bắt buộc, và nạp bảng từ một thư mục qua hàm đọc tệp của bên gọi. Nguồn:
 *    TLBB Dev tests/look/look_test.cpp@e0d89a6.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: khung test của dự án; giới là Race; bỏ các ca vũ khí, NPC và chọn được lúc tạo nhân vật (chưa làm); tên
// tệp là tên gốc dưới Model/. Thêm các ca bảng đòn đánh (skill.hpp): bộ đọc năm bảng, mảng mốc, giải skill thành đòn
// theo giới và loại vũ khí.

#include "core/check.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "look/sect.hpp"
#include "look/skill.hpp"
#include "look/weapon.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <algorithm>
#include <limits>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <functional>
#include <iterator>
#include <map>
#include <string>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using look::Action;
using look::AnimRow;
using look::FaceRow;
using look::Figure;
using look::HairRow;
using look::Look;
using look::OutfitRow;
using look::PlayerBody;
using look::Race;
using look::Slot;
using look::Tables;
using look::Weapon;

// Id mặc định của một thân.
struct Defaults {
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint16_t clothes = 0;
};

[[nodiscard]] PlayerBody body_of(Race race, const Defaults& defaults) {
    const bool is_male = race == Race::kMale;
    const std::uint16_t face = defaults.face;
    const std::uint16_t hair = defaults.hair;
    const std::uint16_t clothes = defaults.clothes;
    PlayerBody body;
    body.race = race;
    body.name = is_male ? "male" : "female";
    body.template_name = is_male ? "男主角.obj" : "女主角.obj";
    body.skeleton = is_male ? "男主角.skeleton" : "女主角.skeleton";
    body.face = face;
    body.hair = hair;
    body.body = clothes;
    body.arm = 61;
    body.foot = is_male ? std::uint16_t{31} : std::uint16_t{43};
    body.anim_set = is_male ? 1415U : 819U;
    body.height = is_male ? 200.0F : 180.0F;
    return body;
}

[[nodiscard]] FaceRow face_of(std::uint16_t id, Race race, std::string mesh, bool is_creatable) {
    FaceRow face;
    face.id = id;
    face.race = race;
    face.mesh = std::move(mesh);
    face.is_creatable = is_creatable;
    return face;
}

// Tóc không phụ kiện; mesh rỗng là kiểu tóc không có lưới.
[[nodiscard]] HairRow hair_of(std::uint16_t id, Race race, std::string mesh) {
    HairRow hair;
    hair.id = id;
    hair.race = race;
    hair.mesh = std::move(mesh);
    return hair;
}

[[nodiscard]] OutfitRow outfit_of(std::uint16_t id, Race race, std::string mesh) {
    OutfitRow outfit;
    outfit.id = id;
    outfit.race = race;
    outfit.mesh = std::move(mesh);
    return outfit;
}

[[nodiscard]] AnimRow anim_of(std::uint32_t set, Action action, std::string file, std::string clip) {
    AnimRow anim;
    anim.set = set;
    anim.action = action;
    anim.anim = std::move(file);
    anim.clip = std::move(clip);
    return anim;
}

// Hai dòng thương (cầm thương có clip riêng cho đứng và chạy).
[[nodiscard]] AnimRow spear_row(Action action, std::string clip) {
    AnimRow row = anim_of(1415, action, "男长枪站立.skeleton", std::move(clip));
    row.weapon = Weapon::kSpear;
    return row;
}

// Bảng mẫu theo bộ nam và nữ tay không, thêm vài dòng cho các luật mặc định.
[[nodiscard]] Tables sample() {
    Tables tables;
    tables.bodies = {body_of(Race::kFemale, {.face = 1, .hair = 1, .clothes = 13}),
        body_of(Race::kMale, {.face = 100, .hair = 5, .clothes = 1})};
    tables.faces = {face_of(1, Race::kFemale, "f_face_01.mesh", true),
        face_of(2, Race::kFemale, "f_face_02.mesh", false), face_of(100, Race::kMale, "m_face_01.mesh", true),
        face_of(300, Race::kMale, "m_face_300.mesh", false)};
    HairRow pinned = hair_of(5, Race::kMale, "m_hair_05.mesh");
    pinned.accessory = "m_hair_05_pin.mesh";
    tables.hairs = {hair_of(1, Race::kFemale, "f_hair_01.mesh"), pinned, hair_of(66, Race::kMale, ""),
        hair_of(10019, Race::kMale, "m_hair_10019.mesh")};
    OutfitRow clothes = outfit_of(1, Race::kMale, "m_clothes.mesh");
    clothes.materials = {"m_clothes"};
    OutfitRow robe = outfit_of(200, Race::kMale, "m_robe.mesh");
    robe.materials = {"robe_top", "robe_belt"};
    tables.outfits = {clothes, robe, outfit_of(61, Race::kMale, "m_bracers.mesh"),
        outfit_of(31, Race::kMale, "m_boots.mesh"), outfit_of(7, Race::kMale, "m_hat.mesh"),
        outfit_of(13, Race::kFemale, "f_clothes.mesh"), outfit_of(61, Race::kFemale, "f_bracers.mesh"),
        outfit_of(43, Race::kFemale, "f_boots.mesh")};
    tables.anims = {anim_of(1415, Action::kIdle, "男空手站立.skeleton", "空手站立01"),
        anim_of(1415, Action::kIdleAlt, "男空手站立.skeleton", "空手休闲"),
        anim_of(1415, Action::kIdleAlt2, "男空手站立.skeleton", "空手站立01"),
        anim_of(1415, Action::kRun, "男主角.skeleton", "跑步"),
        anim_of(819, Action::kIdle, "女空手站立.skeleton", "空手站立01"),
        anim_of(819, Action::kRun, "女主角.skeleton", "跑步"), spear_row(Action::kIdle, "长枪站立01"),
        spear_row(Action::kRun, "长枪跑步")};
    return tables;
}

[[nodiscard]] std::vector<Slot> slots_of(const Figure& figure) {
    std::vector<Slot> slots;
    slots.reserve(figure.parts.size());
    std::ranges::transform(figure.parts, std::back_inserter(slots), [](const look::Part& part) { return part.slot; });
    return slots;
}

// Lưới của bộ phận ở khe slot; rỗng khi không có khe đó.
[[nodiscard]] std::string mesh_at(const Figure& figure, Slot slot) {
    const auto found = std::ranges::find(figure.parts, slot, &look::Part::slot);
    return found == figure.parts.end() ? std::string() : found->mesh;
}

void default_male(Context& context) {
    Look wanted;
    wanted.face = 100;
    wanted.hair = 5;
    const auto figure = look::resolve(sample(), Race::kMale, wanted);
    context.expect(figure.has_value(), "giải được");
    if (!figure) return;
    context.expect(figure->skeleton == "男主角.skeleton" && figure->height == 200.0F, "thân nam");
    const std::vector<Slot> order{Slot::kBody, Slot::kArm, Slot::kFoot, Slot::kFace, Slot::kHair, Slot::kHairAccessory};
    context.expect(slots_of(*figure) == order, "đủ bộ phận, tóc vẽ sau cùng");
    context.expect(mesh_at(*figure, Slot::kBody) == "m_clothes.mesh", "áo mặc định");
    const std::vector<std::string> clothes_materials{"m_clothes"};
    context.expect(figure->parts.front().materials == clothes_materials, "material áo");
    context.expect(mesh_at(*figure, Slot::kFoot) == "m_boots.mesh", "giày mặc định");
    context.expect(mesh_at(*figure, Slot::kHairAccessory) == "m_hair_05_pin.mesh", "phụ kiện tóc");
    context.expect(figure->idle.anim == "男空手站立.skeleton", "tệp clip đứng");
    context.expect(figure->idle.name == "空手站立01" && figure->run.name == "跑步", "clip đứng và chạy");
    context.expect(figure->idle_alt.has_value(), "clip nghỉ phụ");
    const bool second = figure->idle_alt2 && figure->idle_alt2->name == "空手站立01";
    context.expect(second, "động tác nghỉ thứ hai (EX1) của nam là clip đứng");
    const auto female = look::resolve(sample(), Race::kFemale, Look{});
    context.expect(female && !female->idle_alt2, "không có dòng EX1 thì rỗng");
    Look wide_look;
    wide_look.face = 300;
    wide_look.hair = 10019;
    const auto wide = look::resolve(sample(), Race::kMale, wide_look);
    context.expect(wide && mesh_at(*wide, Slot::kFace) == "m_face_300.mesh", "mặt id quá u8");
    context.expect(wide && mesh_at(*wide, Slot::kHair) == "m_hair_10019.mesh", "tóc id quá u8");
}

void fallbacks(Context& context) {
    Look odd;
    odd.face = 1;
    odd.hair = 66;
    odd.cap = 7;
    odd.body = 200;
    odd.arm = 9999;
    const auto male = look::resolve(sample(), Race::kMale, odd);
    context.expect(male.has_value(), "giải được");
    if (!male) return;
    context.expect(mesh_at(*male, Slot::kFace) == "m_face_01.mesh", "mặt nữ trên thân nam về mặc định");
    context.expect(mesh_at(*male, Slot::kHair).empty(), "kiểu tóc trọc không có lưới");
    context.expect(mesh_at(*male, Slot::kCap) == "m_hat.mesh", "mũ có trong bảng");
    context.expect(mesh_at(*male, Slot::kBody) == "m_robe.mesh", "áo theo id hình");
    context.expect(mesh_at(*male, Slot::kArm) == "m_bracers.mesh", "tay không có id về mặc định");
    const std::vector<Slot> order{Slot::kBody, Slot::kArm, Slot::kFoot, Slot::kFace, Slot::kCap};
    context.expect(slots_of(*male) == order, "mũ trước tóc, tóc trọc không vẽ");
    Look hatless_look;
    hatless_look.face = 250;
    hatless_look.cap = 8;
    const auto hatless = look::resolve(sample(), Race::kMale, hatless_look);
    context.expect(hatless && mesh_at(*hatless, Slot::kCap).empty(), "mũ không có trong bảng");
    context.expect(hatless && mesh_at(*hatless, Slot::kFace) == "m_face_01.mesh", "mặt không có");
    Look girl_look;
    girl_look.face = 2;
    girl_look.hair = 1;
    const auto female = look::resolve(sample(), Race::kFemale, girl_look);
    context.expect(female && mesh_at(*female, Slot::kFace) == "f_face_02.mesh", "mặt đúng giới");
    context.expect(female && !female->idle_alt.has_value(), "không có clip nghỉ phụ");
    context.expect(female && female->skeleton == "女主角.skeleton", "thân nữ");
}

// Cầm thương thì clip đứng và chạy theo thương; hành động không có dòng cho thương (nghỉ phụ) dùng
// dòng tay không.
void weapon_kind_picks_clips(Context& context) {
    Look armed;
    armed.face = 100;
    armed.hair = 5;
    armed.weapon = Weapon::kSpear;
    const auto spear = look::resolve(sample(), Race::kMale, armed);
    context.expect(spear.has_value(), "giải được");
    if (!spear) return;
    context.expect(spear->idle.name == "长枪站立01" && spear->run.name == "长枪跑步", "clip thương");
    const bool rest = spear->idle_alt && spear->idle_alt->name == "空手休闲";
    context.expect(rest, "loại không có clip nghỉ phụ thì dùng của tay không");
}

// Bảng vũ khí

// Bốn bảng vũ khí rút gọn: hình 410 do vật phẩm đao (loại blade) và vật phẩm quạt (loại fan) dùng chung,
// hình 593 hai tay, hình 700 có mẫu thiếu trong objects.
[[nodiscard]] look::WeaponTables weapon_sample() {
    const auto read = [](const char* text) { return table::parse_tsv(text); };
    const auto weapons = read("id\tright\tleft\tkfs\tfoot\tback\twaist1\twaist2\n"
                              "410\t大刀.obj\t\t\t\t\t\t\n593\t双短.obj\t双短.obj\t\t\t\t\t\n700\t无此.obj\t\t\t\t\t\t\n");
    const auto items = read("item\tvisual\tclass\n10100000\t410\tblade\n10104000\t410\tfan\n"
                            "10103000\t593\tdual_short\n10106000\t-1\tnone\n");
    const auto objects = read("object\tmeshes\tsx\tsy\tsz\n大刀.obj\t大刀.mesh|刀鞘.mesh\t1\t1\t1\n"
                              "双短.obj\t双短.mesh\t0.9\t0.8\t0.9\n");
    const auto locators = read("object\tlocator\tbone\tx\ty\tz\tqx\tqy\tqz\tqw\ttranslate_first\tslot\n"
                               "女主角.obj\t右武器绑定点\tBone08_mirror01\t0.2\t0.3\t-1\t0\t0\t1\t-1.5\t0\tRightWeaponObj\n"
                               "女主角.obj\t左武器绑定点\tBone08\t0.2\t0.3\t1\t0.7\t0.7\t0\t-3.1\t1\tLeftWeaponObj\n"
                               "女主角.obj\t前置特效点\t\t0\t0\t150\t1\t0\t0\t0\t0\t\n");
    look::WeaponTables tables;
    tables.weapons = *look::read_weapons(*weapons);
    tables.items = *look::read_weapon_items(*items);
    tables.objects = *look::read_objects(*objects);
    tables.locators = *look::read_locators(*locators);
    return tables;
}

// Loại vũ khí là của vật phẩm, hình của vật phẩm là của hình: cùng hình 410, hai vật phẩm cho hai loại
// clip khác nhau nhưng cùng một mẫu gắn tay.
void weapon_kind_belongs_to_item(Context& context) {
    const look::WeaponTables tables = weapon_sample();
    Look blade;
    context.expect(look::equip_weapon(blade, tables, 10100000), "vật phẩm đao có trong bảng");
    Look fan;
    context.expect(look::equip_weapon(fan, tables, 10104000), "vật phẩm quạt có trong bảng");
    context.expect(blade.weapon == Weapon::kBlade && fan.weapon == Weapon::kFan, "loại theo vật phẩm");
    context.expect(blade.weapon_visual == 410 && fan.weapon_visual == 410, "hình dùng chung");
    Look bare = blade;
    context.expect(look::equip_weapon(bare, tables, 10106000), "vật phẩm không hình vẫn có dòng");
    context.expect(bare.weapon == Weapon::kNone && bare.weapon_visual == 0, "không hình thì 0, không phải -1");
    Look keep = blade;
    context.expect(!look::equip_weapon(keep, tables, 99999999), "vật phẩm lạ bị từ chối");
    context.expect(keep.weapon == Weapon::kBlade && keep.weapon_visual == 410, "bị từ chối thì look không đổi");
}

// Mỗi khe có mẫu và locator thì thành một Held theo thứ tự Hold; thiếu mẫu hay locator thì khe trống.
void held_follows_slots(Context& context) {
    Tables tables = sample();
    tables.weapons = weapon_sample();
    Look worn;
    worn.face = 1;
    worn.hair = 1;
    worn.weapon_visual = 593;
    const auto dual = look::resolve(tables, Race::kFemale, worn);
    context.expect(dual.has_value(), "giải được");
    if (!dual) return;
    context.expect(dual->held.size() == 2, "hai tay có mẫu, các khe khác trống");
    const bool order = dual->held.size() == 2 && dual->held[0].hold == look::Hold::kRight &&
        dual->held[1].hold == look::Hold::kLeft;
    context.expect(order, "phải trước trái");
    const look::Held& left = dual->held.back();
    context.expect(left.object == "双短.obj" && left.meshes == std::vector<std::string>{"双短.mesh"}, "mẫu và lưới");
    context.expect(left.scale[0] == 0.9F && left.scale[1] == 0.8F, "tỉ lệ của mẫu");
    context.expect(left.locator.bone == "Bone08" && left.locator.is_translate_first, "locator của khe trái");
    context.expect(left.locator.slot == "LeftWeaponObj", "tên khe");
    worn.weapon_visual = 410;
    const auto blade = look::resolve(tables, Race::kFemale, worn);
    context.expect(blade && blade->held.size() == 1 && blade->held.front().meshes.size() == 2, "một tay, hai lưới");
    worn.weapon_visual = 700;
    const auto lost = look::resolve(tables, Race::kFemale, worn);
    context.expect(lost && lost->held.empty(), "mẫu không có trong objects thì tay trống");
    worn.weapon_visual = 12345;
    const auto unknown = look::resolve(tables, Race::kFemale, worn);
    context.expect(unknown && unknown->held.empty(), "hình không có trong bảng thì tay trống");
    const auto male = look::resolve(tables, Race::kMale, Look{.weapon_visual = 410});
    context.expect(male && male->held.empty(), "mẫu nam không có locator trong bảng mẫu: khe trống");
    worn.weapon_visual = 0;
    const auto bare = look::resolve(tables, Race::kFemale, worn);
    context.expect(bare && bare->held.empty(), "hình 0 là tay không");
}

void weapon_table_rules(Context& context) {
    const look::WeaponTables tables = weapon_sample();
    context.expect(look::find_weapon(tables.weapons, 593) != nullptr, "tra hình");
    context.expect(look::find_weapon(tables.weapons, 594) == nullptr, "hình lạ");
    context.expect(look::find_object(tables.objects, "双短.obj") != nullptr, "tra mẫu");
    context.expect(look::find_slot_locator(tables.locators, "女主角.obj", "RightWeaponObj") != nullptr, "tra khe");
    context.expect(look::find_slot_locator(tables.locators, "女主角.obj", "") == nullptr, "khe rỗng không khớp locator trơn");
    context.expect(look::find_slot_locator(tables.locators, "男主角.obj", "RightWeaponObj") == nullptr, "mẫu khác");
    const auto repeated = table::parse_tsv("id\tright\tleft\tkfs\tfoot\tback\twaist1\twaist2\n5\ta\t\t\t\t\t\t\n5\tb\t\t\t\t\t\t\n");
    context.expect(!look::read_weapons(*repeated).has_value(), "khoá trùng là lỗi");
    const auto nan_cell = table::parse_tsv("object\tlocator\tbone\tx\ty\tz\tqx\tqy\tqz\tqw\ttranslate_first\tslot\n"
                                          "a.obj\tp\t\t0\t0\t0\t1\t0\t0\t1.#QNAN\t0\t\n");
    const auto nan = look::read_locators(*nan_cell);
    context.expect(!nan && nan.error().contains("qw"), "số không hữu hạn bị từ chối, nêu cột");
    const auto no_mesh = table::parse_tsv("object\tmeshes\tsx\tsy\tsz\na.obj\t\t1\t1\t1\n");
    context.expect(!look::read_objects(*no_mesh).has_value(), "mẫu không lưới là lỗi");
    const auto bad_class = table::parse_tsv("item\tvisual\tclass\n1\t2\tsword\n");
    context.expect(!look::read_weapon_items(*bad_class).has_value(), "tên loại lạ là lỗi");
}

// Hiệu ứng đồ (đá quý gắn vũ khí): chọn ô hiệu ứng theo chỉ số, màu RRGGBBAA, khe nhận.

// Hình 410: ô 1 là 火焰, ô 2 là 冰霜, ô 3 rỗng, ô còn lại rỗng; cờ lưng và hông 1 bật, hông 2 tắt.
// Đá 50902003 màu trắng đủ, chỉ số 1; 50902004 alpha một nửa, chỉ số 2; 50902005 chỉ số 3 (ô rỗng); 50902006 chỉ số 99
// (quá 34); 50902007 màu có chữ số 1 ở vị trí thứ hai; 50902008 màu 0; 50902009 màu trắng chỉ số 0.
[[nodiscard]] look::WeaponTables gear_sample() {
    look::WeaponTables tables = weapon_sample();
    std::string cells = "火焰;冰霜";
    for (std::size_t cell = 2; cell < look::kEffectSlots; ++cell) cells += ';';
    const auto effects = table::parse_tsv("visual\tback\twaist1\twaist2\teffects\n410\t1\t1\t0\t" + cells + "\n");
    const auto gems = table::parse_tsv("gem\tcolour\teffect\n50902003\tFFFFFFFF\t1\n50902004\tFFFFFF80\t2\n"
                                       "50902005\tFFFFFFFF\t3\n50902006\tFFFFFFFF\t99\n50902007\tF1FFFFFF\t1\n"
                                       "50902008\t00000000\t1\n50902009\tFFFFFFFF\t0\n");
    tables.effects = *look::read_weapon_effects(*effects);
    tables.gems = *look::read_gems(*gems);
    return tables;
}

void gem_effect_rules(Context& context) {
    const look::WeaponTables tables = gear_sample();
    const look::EffectRow* row = look::find_effects(tables.effects, 410);
    context.expect(row != nullptr && row->effects.size() == look::kEffectSlots, "hình 410 có đủ 34 ô");
    if (row == nullptr) return;
    const look::GemRow* fire = look::find_gem(tables.gems, 50902003);
    const look::GemRow* frost = look::find_gem(tables.gems, 50902004);
    context.expect(fire != nullptr && frost != nullptr, "tra đá quý");
    if (fire == nullptr || frost == nullptr) return;
    const auto lit = look::gem_effect(*row, *fire, look::Hold::kRight);
    context.expect(lit && lit->name == "火焰" && lit->colour == 0xFFFFFFFFU, "chỉ số 1 là ô đầu, màu đọc RRGGBBAA");
    const auto dim = look::gem_effect(*row, *frost, look::Hold::kLeft);
    context.expect(dim && dim->name == "冰霜" && dim->colour == 0xFFFFFF80U, "chỉ số 2 là ô thứ hai, alpha nằm ở byte cuối");
    context.expect(look::gem_effect(*row, *fire, look::Hold::kBack).has_value(), "cờ lưng bật thì khe lưng nhận");
    context.expect(look::gem_effect(*row, *fire, look::Hold::kWaist1).has_value(), "cờ hông 1 bật thì khe hông 1 nhận");
    context.expect(!look::gem_effect(*row, *fire, look::Hold::kWaist2).has_value(), "cờ hông 2 tắt thì khe hông 2 không nhận");
    context.expect(!look::gem_effect(*row, *fire, look::Hold::kSoul).has_value(), "võ hồn không nhận");
    context.expect(!look::gem_effect(*row, *fire, look::Hold::kFoot).has_value(), "chân không nhận");
    const auto none = [&](std::uint32_t gem) {
        const look::GemRow* found = look::find_gem(tables.gems, gem);
        return found != nullptr && !look::gem_effect(*row, *found, look::Hold::kRight).has_value();
    };
    context.expect(none(50902005), "ô rỗng thì không có hiệu ứng");
    context.expect(none(50902006), "chỉ số quá 34 thì không có hiệu ứng (khác mã máy: nó đọc ngoài hàng)");
    context.expect(none(50902007), "ký tự thứ hai của màu là '1' thì bỏ (điều kiện của mã máy)");
    context.expect(none(50902008), "màu 0 là xoá hiệu ứng");
    context.expect(none(50902009), "chỉ số 0 không hợp lệ");
    context.expect(look::find_gem(tables.gems, 1) == nullptr && look::find_effects(tables.effects, 7) == nullptr, "khoá lạ");
}

void held_carries_gem_effect(Context& context) {
    Tables tables = sample();
    tables.weapons = gear_sample();
    Look worn;
    worn.face = 1;
    worn.hair = 1;
    worn.weapon_visual = 410;
    const auto plain = look::resolve(tables, Race::kFemale, worn);
    context.expect(plain && plain->held.size() == 1 && plain->held.front().effect.empty(), "không đá thì không hiệu ứng");
    worn.weapon_gem = 50902003;
    const auto lit = look::resolve(tables, Race::kFemale, worn);
    const bool carried = lit && lit->held.size() == 1 && lit->held.front().effect == "火焰" &&
        lit->held.front().effect_colour == 0xFFFFFFFFU;
    context.expect(carried, "đá có hiệu ứng thì khe tay mang tên effect và màu");
    worn.weapon_gem = 50902005;
    const auto empty_cell = look::resolve(tables, Race::kFemale, worn);
    context.expect(empty_cell && empty_cell->held.front().effect.empty(), "đá trỏ ô rỗng thì không hiệu ứng");
    worn.weapon_gem = 12345;
    const auto unknown = look::resolve(tables, Race::kFemale, worn);
    context.expect(unknown && unknown->held.size() == 1 && unknown->held.front().effect.empty(), "đá lạ thì không hiệu ứng");
    worn.weapon_gem = 50902003;
    worn.weapon_visual = 593;
    const auto no_row = look::resolve(tables, Race::kFemale, worn);
    context.expect(no_row && no_row->held.size() == 2 && no_row->held.front().effect.empty(), "hình không có hàng hiệu ứng thì thôi");
}

void gem_tables_reject_bad_rows(Context& context) {
    const auto bad_flag = table::parse_tsv("visual\tback\twaist1\twaist2\teffects\n410\t2\t0\t0\ta\n");
    context.expect(!look::read_weapon_effects(*bad_flag).has_value(), "cờ khác 0, 1 là lỗi");
    const auto short_cells = table::parse_tsv("visual\tback\twaist1\twaist2\teffects\n410\t0\t0\t0\ta;b\n");
    context.expect(!look::read_weapon_effects(*short_cells).has_value(), "thiếu ô hiệu ứng là lỗi");
    const auto twice = table::parse_tsv("gem\tcolour\teffect\n1\tFFFFFFFF\t1\n1\tFFFFFFFF\t2\n");
    context.expect(!look::read_gems(*twice).has_value(), "khoá đá trùng là lỗi");
}

// Đòn đánh và tuyệt chiêu (skill.hpp): năm bảng thành Strike cho một giới và loại vũ khí.

[[nodiscard]] look::SkillTables skill_sample() {
    look::SkillTables tables;
    const auto moves = table::parse_tsv(
        "skill\tname\tstep\taction\tkind\tsend_ms\n"
        "7\t劈\t0\t100\t0\t800\n"
        "7\t劈\t1\t101\t0\t800\n"
        "7\t劈\t2\t999\t0\t800\n"
        "8\t连\t0\t100\t2\t0\n");
    const auto actions = table::parse_tsv(
        "race\taction\tweapon\tscript\n"
        "0\t100\tnone\tbare_100\n"
        "0\t100\tblade\tblade_100\n"
        "0\t101\tnone\tbare_101\n"
        "0\t999\tnone\tno_clip\n"
        "1\t100\tnone\tman_100\n");
    const auto scripts = table::parse_tsv(
        "script\tanimation\tbreak_time\thit_time\tshake_time\trepeat\n"
        "bare_100\t空手一\t0.5 1\t0.25\t-1\tfalse\n"
        "bare_101\t空手二\t\t\t\tfalse\n"
        "blade_100\t刀一\t0.4\t0.3 0.6\t0.3\tfalse\n"
        "no_clip\t没有\t1\t0.5\t-1\tfalse\n"
        "man_100\t男一\t1\t0.5\t-1\tfalse\n");
    const auto events = table::parse_tsv(
        "script\torder\tkind\ttime\tpoint\tname\tpx\tpy\tpz\trw\trx\try\trz\tattach\tprops\n"
        "blade_100\t0\tAnimEffect\t0.5\t脚下光圈点\tfx_a\t1\t2\t3\t1\t0\t0\t0\ttrue\tDefaultShow=false\n"
        "blade_100\t1\tSound\t0\t\tSkills\\a.wav\t\t\t\t\t\t\t\t\t\n"
        "bare_100\t0\tRibbon\t0.2\tRightHand\tmat_r\t0\t0\t0\t1\t0\t0\t0\tfalse\tPointCount=8\n");
    const auto clips = table::parse_tsv(
        "race\tanimation\tanim\tclip\n"
        "0\t空手一\t0_女空手.skeleton\t空手一\n"
        "0\t空手二\t0_女空手.skeleton\t空手二\n"
        "0\t刀一\t0_女大刀.skeleton\t刀一\n"
        "1\t男一\t0_男空手.skeleton\t男一\n");
    if (moves && actions && scripts && events && clips) {
        tables.moves = look::read_moves(*moves).value_or(std::vector<look::MoveRow>{});
        tables.actions = look::read_actions(*actions).value_or(std::vector<look::ActionRow>{});
        tables.scripts = look::read_scripts(*scripts).value_or(std::vector<look::ScriptRow>{});
        tables.events = look::read_events(*events).value_or(std::vector<look::EventRow>{});
        tables.clips = look::read_skill_clips(*clips).value_or(std::vector<look::SkillClipRow>{});
    }
    return tables;
}

void skill_tables_read(Context& context) {
    const look::SkillTables tables = skill_sample();
    context.expect(tables.moves.size() == 4 && tables.actions.size() == 5 && tables.scripts.size() == 5, "đọc đủ dòng");
    context.expect(tables.events.size() == 3 && tables.clips.size() == 4, "đọc đủ khối con và clip");
    const auto script = std::ranges::find(tables.scripts, "blade_100", &look::ScriptRow::name);
    const bool has_script = script != tables.scripts.end();
    context.expect(has_script && script->hit_times.size() == 2 && script->hit_times.at(1) == 0.6F, "mảng mốc tách theo dấu cách");
    const auto bare = std::ranges::find(tables.scripts, "bare_100", &look::ScriptRow::name);
    const bool has_bare = bare != tables.scripts.end();
    context.expect(has_bare && bare->shake_times.empty(), "mốc -1 là không có");
    const auto empty = std::ranges::find(tables.scripts, "bare_101", &look::ScriptRow::name);
    const bool has_empty = empty != tables.scripts.end();
    context.expect(has_empty && empty->break_times.empty() && empty->hit_times.empty(), "ô rỗng là mảng rỗng");
    context.expect(look::step_count(tables.moves, 7) == 3 && look::step_count(tables.moves, 99) == 0, "số bước của skill");
    const auto bad_time = table::parse_tsv("script\tanimation\tbreak_time\thit_time\tshake_time\trepeat\na\tb\t0.5 x\t\t\tfalse\n");
    const auto refused = look::read_scripts(*bad_time);
    context.expect(!refused && refused.error().contains("break_time"), "mốc không phải số bị từ chối, nêu cột");
    const auto bad_kind = table::parse_tsv("script\torder\tkind\ttime\tpoint\tname\tpx\tpy\tpz\trw\trx\try\trz\tattach\tprops\n"
                                          "a\t0\tFlame\t0\t\tx\t\t\t\t\t\t\t\tfalse\t\n");
    context.expect(!look::read_events(*bad_kind).has_value(), "loại khối lạ là lỗi");
    const auto bad_weapon = table::parse_tsv("race\taction\tweapon\tscript\n0\t1\tsword\tx\n");
    context.expect(!look::read_actions(*bad_weapon).has_value(), "tên loại vũ khí lạ là lỗi");
    const auto repeated = table::parse_tsv("skill\tname\tstep\taction\tkind\tsend_ms\n1\ta\t0\t1\t0\t0\n1\ta\t0\t2\t0\t0\n");
    context.expect(!look::read_moves(*repeated).has_value(), "khoá (skill, bước) trùng là lỗi");
}

void strikes_resolve(Context& context) {
    const look::SkillTables tables = skill_sample();
    const std::vector<look::Strike> bare = look::strikes_of(tables, Race::kFemale, Weapon::kNone, 7);
    context.expect(bare.size() == 2, "bước thiếu clip (action 999) bị bỏ, hai bước còn lại");
    const bool is_ordered = bare.size() == 2 && bare.at(0).step == 0 && bare.at(1).step == 1;
    context.expect(is_ordered, "giữ số bước gốc, theo thứ tự");
    context.expect(bare.at(0).clip.anim == "0_女空手.skeleton" && bare.at(0).clip.name == "空手一", "clip của tay không");
    context.expect(bare.at(0).send_ms == 800 && bare.at(0).kind == look::ActionKind::kRandom, "thời gian phát và kiểu bước");
    context.expect(bare.at(0).break_times.size() == 2 && bare.at(0).break_times.at(0) == 0.5F, "mốc ngắt");
    context.expect(bare.at(0).events.size() == 1 && bare.at(0).events.at(0).kind == look::EventKind::kRibbon, "khối con của kịch bản");
    const std::vector<look::Strike> blade = look::strikes_of(tables, Race::kFemale, Weapon::kBlade, 7);
    const bool is_blade_first = !blade.empty() && blade.at(0).script == "blade_100";
    context.expect(blade.size() == 2 && is_blade_first, "loại vũ khí có động tác riêng thì dùng nó");
    context.expect(blade.size() == 2 && blade.at(1).script == "bare_101", "không có dòng riêng thì dùng dòng tay không");
    const bool has_events = !blade.empty() && blade.at(0).events.size() == 2;
    context.expect(has_events && blade.at(0).events.at(0).is_attached && blade.at(0).events.at(0).offset.at(2) == 3.0F, "khối con mang điểm gắn và lệch");
    context.expect(has_events && blade.at(0).events.at(1).kind == look::EventKind::kSound, "âm thanh đứng sau theo thứ tự");
    const std::vector<look::Strike> man = look::strikes_of(tables, Race::kMale, Weapon::kNone, 7);
    context.expect(man.size() == 1 && man.at(0).step == 0, "giới nam chỉ có bước 0");
    context.expect(look::strikes_of(tables, Race::kFemale, Weapon::kNone, 99).empty(), "skill lạ thì không có đòn");
    const std::vector<look::Strike> linked = look::strikes_of(tables, Race::kFemale, Weapon::kNone, 8);
    context.expect(linked.size() == 1 && linked.at(0).kind == look::ActionKind::kLinked, "kiểu liên hoàn giữ nguyên");
}

// Start_MagicSend + FreshAnimation. Chuỗi phát là ô GetRandAnim, không phải chú thích (1,2,3) của enum.
void chain_picks(Context& context) {
    context.expect(look::chain_skips_middle() && look::random_picks_remainder(), "liên hoàn bỏ bước giữa, ngẫu nhiên lấy dư");
    look::Chain chain;
    const look::ChainPick ended = look::accept_chain(chain, 4, look::ActionKind::kLinked, 3, 0, true);
    const look::ChainPick again = look::accept_chain(chain, 4, look::ActionKind::kLinked, 3, 0, true);
    context.expect(ended.plays && ended.slot == 0 && again.plays && again.slot == 1, "clip đã hết: tăng một lần rồi phát");
    const look::ChainPick wrapped = look::accept_chain(chain, 4, look::ActionKind::kLinked, 3, 0, true);
    const look::ChainPick back = look::accept_chain(chain, 4, look::ActionKind::kLinked, 3, 0, true);
    context.expect(wrapped.slot == 2 && back.plays && back.slot == 0, "CONCATENATION quay về 0");
    look::Chain ex;
    static_cast<void>(look::accept_chain(ex, 5, look::ActionKind::kLinkedEx, 3, 0, true));
    const look::ChainPick second = look::accept_chain(ex, 5, look::ActionKind::kLinkedEx, 3, 0, true);
    const look::ChainPick third = look::accept_chain(ex, 5, look::ActionKind::kLinkedEx, 3, 0, true);
    context.expect(second.slot == 1 && third.slot == 1, "CONCATENATION_EX kẹt ở bước 1, không phát bước cuối");
    look::Chain one;
    static_cast<void>(look::accept_chain(one, 6, look::ActionKind::kLinkedEx, 1, 0, true));
    const look::ChainPick only = look::accept_chain(one, 6, look::ActionKind::kLinkedEx, 1, 0, true);
    context.expect(only.plays && only.slot == 0, "một bước: index thô 1 vẫn phát ô 0");
    look::Chain other;
    static_cast<void>(look::accept_chain(other, 1, look::ActionKind::kLinked, 3, 0, true));
    const look::ChainPick fresh = look::accept_chain(other, 2, look::ActionKind::kLinked, 4, 0, false);
    context.expect(fresh.plays && fresh.slot == 0, "đổi skill thì về bước 0");
    look::Chain idle;
    context.expect(!look::finish_chain(idle).plays, "hết clip khi không có lệnh nối thì không phát");
    look::Chain wide;
    context.expect(!look::accept_chain(wide, 1, look::ActionKind::kRandom, 65, 1, false).plays, "quá trần bước thì bỏ");
    context.expect(look::moment_due(0.95F, 0.9F, 0.1F) && !look::moment_due(0.5F, 0.9F, 0.1F), "mốc lúc clip quay vòng");
    context.expect(!look::moment_due(std::numeric_limits<float>::quiet_NaN(), 0.0F, 1.0F), "mốc NaN không bắn");
}

void missing_rows(Context& context) {
    Tables no_male = sample();
    no_male.bodies.pop_back();
    const auto body = look::resolve(no_male, Race::kMale, Look{});
    context.expect(!body && body.error() == look::LookError::kNoBody, "không có thân của giới");
    Tables no_face = sample();
    std::erase_if(no_face.faces, [](const FaceRow& row) { return row.id == 100; });
    Look wanted;
    wanted.face = 1;
    const auto face = look::resolve(no_face, Race::kMale, wanted);
    context.expect(!face && face.error() == look::LookError::kNoDefaultFace, "không có mặt mặc định");
    Tables no_boots = sample();
    std::erase_if(no_boots.outfits, [](const OutfitRow& row) { return row.id == 31; });
    const auto boots = look::resolve(no_boots, Race::kMale, Look{});
    context.expect(!boots && boots.error() == look::LookError::kNoDefaultOutfit, "không có giày mặc định");
    Tables no_run = sample();
    std::erase_if(no_run.anims, [](const AnimRow& row) { return row.action == Action::kRun; });
    const auto run = look::resolve(no_run, Race::kFemale, Look{});
    context.expect(!run && run.error() == look::LookError::kNoRun, "không có clip chạy");
    context.expect(!look::describe(look::LookError::kNoRun).empty(), "có câu mô tả lỗi");
}

// Nạp từ thư mục

// Thư mục bảng giả trong bộ nhớ: đường dẫn đầy đủ tới nội dung tệp.
using Files = std::map<std::string, std::string, std::less<>>;

[[nodiscard]] std::expected<std::string, std::string> text_of(const Files& files, const std::string& path) {
    const auto found = files.find(path);
    if (found == files.end()) return std::unexpected(std::format("không có {}", path));
    return found->second;
}

[[nodiscard]] look::ReadFile reader_of(const Files& files) {
    return [&files](const std::string& path) { return text_of(files, path); };
}

// Mỗi bảng bắt buộc một dòng, đủ để mọi bộ đọc nhận.
[[nodiscard]] Files sample_folder() {
    Files folder;
    folder["bang/player_bodies.tsv"] =
        "# bảng "
        "mẫu\nrace\tname\ttemplate\tskeleton\tface\thair\tbody\tarm\tfoot\tanim_set\theight\n"
        "0\tfemale\t女主角.obj\t女主角.skeleton\t1\t1\t13\t61\t43\t819\t180\n";
    folder["bang/faces.tsv"] = "id\trace\tmesh\tcreatable\n1\t0\tf_face.mesh\t1\n";
    folder["bang/hairs.tsv"] = "id\trace\tmesh\taccessory\tcreatable\n1\t0\tf_hair.mesh\t\t1\n";
    folder["bang/outfits.tsv"] = "id\trace\tmesh\tmaterials\n13\t0\tf_body.mesh\t\n";
    folder["bang/anim_sets.tsv"] =
        "set\taction\tweapon\tanim\tclip\n819\tidle\tnone\t女空手站立.skeleton\t空手站立01\n";
    return folder;
}

void load_folder(Context& context) {
    const Files folder = sample_folder();
    const auto loaded = look::load_tables("bang", reader_of(folder));
    context.expect(loaded.has_value(), "đủ năm bảng thì nạp được");
    const bool has_rows = loaded && loaded->bodies.size() == 1 && loaded->anims.size() == 1;
    context.expect(has_rows && loaded->bodies.front().skeleton == "女主角.skeleton", "dòng từng bảng");
    context.expect(look::load_tables("bang/", reader_of(folder)).has_value(), "thư mục có sẵn dấu / ở cuối");
}

void load_failures(Context& context) {
    Files no_hair = sample_folder();
    no_hair.erase("bang/hairs.tsv");
    const auto missing = look::load_tables("bang", reader_of(no_hair));
    context.expect(!missing && missing.error().contains("bang/hairs.tsv"), "thiếu tệp thì lỗi có đường dẫn");
    Files bad_face = sample_folder();
    bad_face["bang/faces.tsv"] = "id\trace\tmesh\tcreatable\n1\t0\tf.mesh\t2\n";
    const auto broken = look::load_tables("bang", reader_of(bad_face));
    const bool names_cell =
        !broken && broken.error().contains("bang/faces.tsv") && broken.error().contains("creatable");
    context.expect(names_cell, "bảng sai thì lỗi có tệp và cột");
    bad_face.erase("bang/anim_sets.tsv");
    const auto first = look::load_tables("bang", reader_of(bad_face));
    context.expect(!first && first.error().contains("faces.tsv"), "báo bảng hỏng đầu tiên");
    Files bad_action = sample_folder();
    bad_action["bang/anim_sets.tsv"] = "set\taction\tweapon\tanim\tclip\n819\tfly\tnone\ta.skeleton\tx\n";
    const auto action = look::load_tables("bang", reader_of(bad_action));
    context.expect(!action && action.error().contains("action"), "tên hành động lạ là lỗi");
}

void skill_load_failures(Context& context) {
    Files folder;
    folder["bang/skill_moves.tsv"] = "skill\tname\tstep\taction\tkind\tsend_ms\n1\ta\t0\t1\t0\t0\n";
    folder["bang/skill_actions.tsv"] = "race\taction\tweapon\tscript\n0\t1\tnone\ts\n";
    folder["bang/skill_scripts.tsv"] = "script\tanimation\tbreak_time\thit_time\tshake_time\trepeat\ns\ta\t1\t0.5\t-1\tfalse\n";
    folder["bang/skill_events.tsv"] = "script\torder\tkind\ttime\tpoint\tname\tpx\tpy\tpz\trw\trx\try\trz\tattach\tprops\n";
    folder["bang/skill_clips.tsv"] = "race\tanimation\tanim\tclip\n0\ta\tx.skeleton\ta\n";
    const auto loaded = look::load_skill_tables("bang", reader_of(folder));
    context.expect(loaded && loaded->moves.size() == 1 && loaded->clips.size() == 1, "đủ năm bảng thì nạp được");
    folder.erase("bang/skill_events.tsv");
    const auto missing = look::load_skill_tables("bang", reader_of(folder));
    context.expect(!missing && missing.error().contains("skill_events.tsv"), "thiếu tệp thì lỗi có đường dẫn");
}

void tsv_rules(Context& context) {
    const auto table = table::parse_tsv("# chú thích\r\na\tb\r\n\r\n1\t2\r\n3\t\r\n");
    context.expect(table.has_value() && table->rows.size() == 2, "bỏ chú thích và dòng trống, bỏ \\r");
    context.expect(table && table->rows[1][1].empty(), "ô cuối rỗng vẫn là một ô");
    context.expect(table && table->lines[0] == 4, "số dòng của bản ghi đầu theo tệp");
    context.expect(!table::parse_tsv("a\tb\n1\n").has_value(), "thiếu ô là lỗi");
    context.expect(!table::parse_tsv("# chỉ chú thích\n").has_value(), "không có dòng tên cột");
}

// Hồi quy: 鬼谷 (môn 11) cầm gậy bằng Slot của locator 武器特效点, không có lưới gậy trong EntityList của
// sect_models, nên người mẫu màn tạo nhân vật đứng tay không. sect_held trả khe để nối vào figure.held.
void sect_held_rows(Context& context) {
    constexpr std::string_view table =
        "# chú thích\n"
        "race\tsect\tobject\tmeshes\tbone\tx\ty\tz\tqx\tqy\tqz\tqw\ttranslate_first\n"
        "0\t11\tgay.obj\tgay.mesh|dau.mesh\tBone_wuqi\t2.5\t-0.5\t-0.25\t-1\t0.5\t0.25\t-1.5\t1\n"
        "1\t11\tgay.obj\tgay.mesh\tBip01_Prop1\t0\t0\t13.5\t-0.5\t-0.5\t-0.5\t-2\t0\n";
    const auto female = look::sect_held(table, Race::kFemale, 11);
    context.expect(female && female->has_value(), "nữ 11 có khe");
    if (!female || !*female) return;
    const look::Held& staff = **female;
    context.expect(staff.object == "gay.obj" && staff.meshes.size() == 2, "mẫu và hai lưới");
    context.expect(staff.locator.bone == "Bone_wuqi" && staff.locator.is_translate_first, "xương và cờ áp lệch");
    context.expect(staff.locator.offset[0] == 2.5F && staff.locator.offset[2] == -0.25F, "vị trí lệch");
    context.expect(staff.locator.axis[0] == -1.0F && staff.locator.angle == -1.5F, "trục và góc radian");
    context.expect(staff.scale[0] == 1.0F && staff.hold == look::Hold::kRight, "tỉ lệ 1, khe phải");
    const auto male = look::sect_held(table, Race::kMale, 11);
    context.expect(male && male->has_value(), "nam 11 có khe");
    if (!male || !*male) return;
    context.expect((*male)->locator.bone == "Bip01_Prop1" && !(*male)->locator.is_translate_first, "nam theo xương khác");
    context.expect((*male)->locator.offset[2] == 13.5F && (*male)->meshes.size() == 1, "nam: lệch và một lưới");
    const auto bare = look::sect_held(table, Race::kFemale, 5);
    context.expect(bare && !bare->has_value(), "môn không có dòng thì không gắn gì");
    context.expect(!look::sect_held(table, Race::kFemale, look::kSectCount), "môn ngoài 0..14 là lỗi");
    const std::string_view no_mesh = "race\tsect\tobject\tmeshes\tbone\tx\ty\tz\tqx\tqy\tqz\tqw\ttranslate_first\n"
                                     "0\t11\tgay.obj\t\tBone_wuqi\t0\t0\t0\t1\t0\t0\t0\t1\n";
    context.expect(!look::sect_held(no_mesh, Race::kFemale, 11), "dòng không có lưới là lỗi");
    const std::string_view bad_cell = "race\tsect\tobject\tmeshes\tbone\tx\ty\tz\tqx\tqy\tqz\tqw\ttranslate_first\n"
                                      "0\t11\tgay.obj\tgay.mesh\tBone_wuqi\tabc\t0\t0\t1\t0\t0\t0\t1\n";
    context.expect(!look::sect_held(bad_cell, Race::kFemale, 11), "ô số hỏng là lỗi");
}

constexpr std::array kCases{
    Case{.name = "default_male", .body = &default_male},
    Case{.name = "fallbacks", .body = &fallbacks},
    Case{.name = "weapon_kind_picks_clips", .body = &weapon_kind_picks_clips},
    Case{.name = "weapon_kind_belongs_to_item", .body = &weapon_kind_belongs_to_item},
    Case{.name = "held_follows_slots", .body = &held_follows_slots},
    Case{.name = "sect_held_rows", .body = &sect_held_rows},
    Case{.name = "weapon_table_rules", .body = &weapon_table_rules},
    Case{.name = "gem_effect_rules", .body = &gem_effect_rules},
    Case{.name = "held_carries_gem_effect", .body = &held_carries_gem_effect},
    Case{.name = "gem_tables_reject_bad_rows", .body = &gem_tables_reject_bad_rows},
    Case{.name = "skill_tables_read", .body = &skill_tables_read},
    Case{.name = "strikes_resolve", .body = &strikes_resolve},
    Case{.name = "chain_picks", .body = &chain_picks},
    Case{.name = "missing_rows", .body = &missing_rows},
    Case{.name = "load_folder", .body = &load_folder},
    Case{.name = "load_failures", .body = &load_failures},
    Case{.name = "skill_load_failures", .body = &skill_load_failures},
    Case{.name = "tsv_rules", .body = &tsv_rules},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "look_tests: mọi ca phải qua");
    return 0;
}
