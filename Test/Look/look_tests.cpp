// Kiểm giải ngoại hình người chơi: bộ mặc định của giới, mặt và tóc sai giới hay không có thì về
// mặc định, kiểu tóc không lưới, mũ và trang phục không có, thứ tự vẽ (tóc sau cùng), clip đứng và
// chạy, lỗi khi bảng thiếu thứ bắt buộc, và nạp bảng từ một thư mục qua hàm đọc tệp của bên gọi.
// Nguồn: TLBB Dev tests/look/look_test.cpp@e0d89a6. Khác gốc: khung test của dự án; giới là Race;
// bỏ các ca vũ khí, NPC và chọn được lúc tạo nhân vật (chưa làm); tên tệp là tên gốc dưới Model/.
#include "core/check.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
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

void tsv_rules(Context& context) {
    const auto table = table::parse_tsv("# chú thích\r\na\tb\r\n\r\n1\t2\r\n3\t\r\n");
    context.expect(table.has_value() && table->rows.size() == 2, "bỏ chú thích và dòng trống, bỏ \\r");
    context.expect(table && table->rows[1][1].empty(), "ô cuối rỗng vẫn là một ô");
    context.expect(table && table->lines[0] == 4, "số dòng của bản ghi đầu theo tệp");
    context.expect(!table::parse_tsv("a\tb\n1\n").has_value(), "thiếu ô là lỗi");
    context.expect(!table::parse_tsv("# chỉ chú thích\n").has_value(), "không có dòng tên cột");
}

constexpr std::array kCases{
    Case{.name = "default_male", .body = &default_male},
    Case{.name = "fallbacks", .body = &fallbacks},
    Case{.name = "weapon_kind_picks_clips", .body = &weapon_kind_picks_clips},
    Case{.name = "missing_rows", .body = &missing_rows},
    Case{.name = "load_folder", .body = &load_folder},
    Case{.name = "load_failures", .body = &load_failures},
    Case{.name = "tsv_rules", .body = &tsv_rules},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "look_tests: mọi ca phải qua");
    return 0;
}
