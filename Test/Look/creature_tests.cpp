/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Look/creature_tests.cpp
 *  PHÂN HỆ   : Look / Creature Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm look/creature: bốn bảng quái và NPC thành hình để vẽ. Các ca là chỗ
 *    bảng sai mà nhìn không lộ: khoá trùng làm tra nhầm dòng, cột clip của NPC
 *    lẫn quái, mô hình không xương bị dựng thành avatar, tỉ lệ bị bỏ sót,
 *    material chồng lệch lưới.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "look/creature.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <initializer_list>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using look::CreatureAction;
using look::CreatureKind;
using look::CreatureTables;
using look::CreatureTexts;

// Một dòng bảng: các ô nối bằng tab.
[[nodiscard]] std::string row(std::initializer_list<std::string_view> cells) {
    std::string line;
    bool is_first = true;
    for (const std::string_view cell : cells) {
        if (!is_first) line.push_back('\t');
        is_first = false;
        line.append(cell);
    }
    line.push_back('\n');
    return line;
}

constexpr std::string_view kTemplateHead = "template\tname\tmodel\tplate_height\tring_size\tshadow_size\tscale\tkind\n";
constexpr std::string_view kModelHead = "model\tmeshes\tskeleton\tsx\tsy\tsz\theight\tmaterials\n";
constexpr std::string_view kClipHead = "model\tkind\taction\tanim\tclip\n";
constexpr std::string_view kMaterialHead = "material\ttexture\talpha\tcutoff\tdouble_sided\tunlit\n";

struct Fixture {
    std::string templates;
    std::string models;
    std::string clips;
    std::string materials;

    [[nodiscard]] CreatureTexts texts() const { return CreatureTexts{templates, models, clips, materials}; }
};

// Hai mô hình có xương (5 dùng chung cho NPC và quái, 7 chỉ NPC), một mô hình tĩnh (9), một mô hình có material chồng (11).
[[nodiscard]] Fixture good() {
    Fixture fixture;
    fixture.templates = std::string(kTemplateHead) + "# chú thích\n" +
                        row({"20", "NPC", "5", "-1", "100", "100", "1", "npc"}) +
                        row({"10", "Quái", "5", "2.5", "100", "100", "1.5", "monster"}) +
                        row({"30", "Tượng", "9", "-1", "100", "100", "1", "npc"}) +
                        row({"40", "Da", "11", "-1", "100", "100", "1", "npc"}) +
                        row({"50", "Mất mô hình", "77", "-1", "100", "100", "1", "npc"});
    fixture.models = std::string(kModelHead) + row({"5", "a.mesh|b.mesh", "a.skeleton", "1", "2", "1", "1.8", "|"}) +
                     row({"9", "t.mesh", "", "1", "1", "1", "0", ""}) +
                     row({"11", "x.mesh|y.mesh", "x.skeleton", "1", "1", "1", "0", "da1|"});
    fixture.clips = std::string(kClipHead) + row({"5", "monster", "run", "a.skeleton", "chay"}) +
                    row({"5", "npc", "idle", "a.skeleton", "dung"}) + row({"5", "monster", "idle", "a.skeleton", "dung-q"}) +
                    row({"5", "npc", "walk", "a.skeleton", "di"}) + row({"5", "monster", "death", "a.skeleton", "chet"}) +
                    row({"11", "npc", "default", "x.skeleton", "mac-dinh"});
    fixture.materials = std::string(kMaterialHead) + row({"da1", "Material/da1.png", "MASK", "0.5", "0", "0"}) +
                        row({"da2", "Material/da2.png", "OPAQUE", "", "1", "1"});
    return fixture;
}

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) < 1e-4F;
}

void lookups(Context& context) {
    const Fixture fixture = good();
    const auto tables = look::parse_creature_tables(fixture.texts());
    context.expect(tables.has_value(), "bảng đúng thì đọc được");
    if (!tables) return;
    context.expect(tables->templates.size() == 5 && tables->models.size() == 3, "số dòng");
    const look::CreatureTemplate* quai = tables->find_template(10);
    context.expect(quai != nullptr && quai->name == "Quái" && quai->kind == CreatureKind::kMonster, "tra theo khoá dù bảng không xếp");
    context.expect(quai != nullptr && near_value(quai->plate_height, 2.5F) && near_value(quai->scale, 1.5F), "ô số thực");
    context.expect(tables->find_template(11) == nullptr && tables->find_template(0) == nullptr, "khoá lạ không có");
    context.expect(tables->find_model(5) != nullptr && tables->find_model(6) == nullptr, "tra mô hình");
    const look::CreatureMaterial* da2 = tables->find_material("da2");
    context.expect(da2 != nullptr && da2->alpha == look::OverlayAlpha::kOpaque && da2->double_sided && da2->unlit, "material hai mặt không sáng");
    const look::CreatureMaterial* da1 = tables->find_material("da1");
    context.expect(da1 != nullptr && da1->alpha == look::OverlayAlpha::kMask && near_value(da1->cutoff, 0.5F), "material cắt alpha");
    context.expect(tables->find_clip(5, CreatureKind::kNpc, CreatureAction::kIdle) != nullptr, "clip npc");
    context.expect(tables->find_clip(5, CreatureKind::kNpc, CreatureAction::kRun) == nullptr, "npc không có chạy");
    context.expect(tables->find_clip(99, CreatureKind::kNpc, CreatureAction::kIdle) == nullptr, "mô hình lạ không có clip");
}

void kinds_do_not_mix(Context& context) {
    const Fixture fixture = good();
    const auto tables = look::parse_creature_tables(fixture.texts());
    if (!tables) {
        context.expect(false, "đọc bảng");
        return;
    }
    const look::CreatureClip* npc = tables->find_clip(5, CreatureKind::kNpc, CreatureAction::kIdle);
    const look::CreatureClip* monster = tables->find_clip(5, CreatureKind::kMonster, CreatureAction::kIdle);
    context.expect(npc != nullptr && monster != nullptr && npc->clip.name == "dung" && monster->clip.name == "dung-q",
        "cùng mô hình, hai loại, hai clip đứng khác nhau");
    const auto npc_figure = look::creature_figure(*tables, 20);
    const auto monster_figure = look::creature_figure(*tables, 10);
    context.expect(npc_figure && monster_figure && npc_figure->figure.idle.name == "dung" && monster_figure->figure.idle.name == "dung-q",
        "hình lấy clip theo loại của template");
}

void animated_figure(Context& context) {
    const Fixture fixture = good();
    const auto tables = look::parse_creature_tables(fixture.texts());
    if (!tables) {
        context.expect(false, "đọc bảng");
        return;
    }
    const auto npc = look::creature_figure(*tables, 20);
    context.expect(npc.has_value() && npc->is_animated, "NPC có xương và clip đứng");
    if (!npc) return;
    context.expect(npc->figure.parts.size() == 2 && npc->figure.parts.front().mesh == "a.mesh", "lưới theo thứ tự");
    context.expect(npc->figure.skeleton == "a.skeleton", "xương");
    context.expect(npc->walk && npc->walk->name == "di", "đi bộ");
    context.expect(npc->figure.run.name == "di", "không có chạy thì chạy là đi bộ");
    context.expect(!npc->figure.idle_alt && !npc->death, "hành động thiếu thì rỗng, không bịa");
    context.expect(near_value(npc->scale[0], 1.0F) && near_value(npc->scale[1], 2.0F) && near_value(npc->scale[2], 1.0F),
        "Scale của mẫu");
    context.expect(near_value(npc->height, 1.8F), "chiều cao mô hình");

    const auto monster = look::creature_figure(*tables, 10);
    context.expect(monster && monster->figure.run.name == "chay" && monster->death && monster->death->name == "chet", "quái chạy và chết");
    context.expect(monster && near_value(monster->scale[0], 1.5F) && near_value(monster->scale[1], 3.0F),
        "tỉ lệ của template nhân Scale của mẫu");
    context.expect(monster && near_value(monster->plate_height, 2.5F), "độ cao bảng tên");
}

void default_clip_and_overlay(Context& context) {
    const Fixture fixture = good();
    const auto tables = look::parse_creature_tables(fixture.texts());
    if (!tables) {
        context.expect(false, "đọc bảng");
        return;
    }
    const auto skin = look::creature_figure(*tables, 40);
    context.expect(skin && skin->is_animated && skin->figure.idle.name == "mac-dinh", "thiếu clip đứng thì dùng DefaultAnimation");
    context.expect(skin && skin->figure.run.name == "mac-dinh", "mô hình không di chuyển được thì chạy là chính clip đứng");
    context.expect(skin && skin->figure.parts.size() == 2, "hai lưới");
    if (!skin || skin->figure.parts.size() != 2) return;
    context.expect(skin->figure.parts[0].materials.size() == 1 && skin->figure.parts[0].materials[0] == "da1",
        "material chồng đi với lưới đầu");
    context.expect(skin->figure.parts[1].materials.empty(), "lưới sau dùng material của lưới");
}

void static_figure(Context& context) {
    const Fixture fixture = good();
    const auto tables = look::parse_creature_tables(fixture.texts());
    if (!tables) {
        context.expect(false, "đọc bảng");
        return;
    }
    const auto statue = look::creature_figure(*tables, 30);
    context.expect(statue && !statue->is_animated && statue->figure.parts.size() == 1, "mô hình tĩnh không dựng avatar");
}

void errors(Context& context) {
    const Fixture fixture = good();
    const auto tables = look::parse_creature_tables(fixture.texts());
    if (!tables) {
        context.expect(false, "đọc bảng");
        return;
    }
    context.expect(!look::creature_figure(*tables, 999), "template lạ");
    context.expect(!look::creature_figure(*tables, 50), "template trỏ mô hình không có");

    Fixture bad = good();
    bad.templates += row({"20", "Trùng", "5", "-1", "100", "100", "1", "npc"});
    context.expect(!look::parse_creature_tables(bad.texts()), "template trùng khoá làm tra nhầm dòng");

    bad = good();
    bad.templates = std::string(kTemplateHead) + row({"1", "A", "5", "-1", "100", "100", "1", "thu"});
    context.expect(!look::parse_creature_tables(bad.texts()), "loại lạ");

    bad = good();
    bad.templates = std::string(kTemplateHead) + row({"1", "A", "5", "-1", "100", "100", "0", "npc"});
    context.expect(!look::parse_creature_tables(bad.texts()), "tỉ lệ phải dương");

    bad = good();
    bad.models = std::string(kModelHead) + row({"5", "a.mesh|b.mesh", "a.skeleton", "1", "1", "1", "0", "da1"});
    context.expect(!look::parse_creature_tables(bad.texts()), "số material khác số lưới");

    bad = good();
    bad.models += row({"5", "z.mesh", "", "1", "1", "1", "0", ""});
    context.expect(!look::parse_creature_tables(bad.texts()), "mô hình trùng khoá");

    bad = good();
    bad.clips += row({"5", "npc", "dance", "a.skeleton", "nhay"});
    context.expect(!look::parse_creature_tables(bad.texts()), "hành động lạ");

    bad = good();
    bad.clips += row({"5", "npc", "idle", "a.skeleton", "khac"});
    context.expect(!look::parse_creature_tables(bad.texts()), "clip trùng khoá");

    bad = good();
    bad.clips += row({"6", "npc", "idle", "", "khac"});
    context.expect(!look::parse_creature_tables(bad.texts()), "clip thiếu tệp");

    bad = good();
    bad.materials += row({"hong", "Material/h.png", "SANG", "", "0", "0"});
    context.expect(!look::parse_creature_tables(bad.texts()), "kiểu trộn alpha lạ");

    bad = good();
    bad.materials = "material\ttexture\n";
    context.expect(!look::parse_creature_tables(bad.texts()), "thiếu cột");

    Fixture empty;
    empty.templates = std::string(kTemplateHead);
    empty.models = std::string(kModelHead);
    empty.clips = std::string(kClipHead);
    empty.materials = std::string(kMaterialHead);
    const auto none = look::parse_creature_tables(empty.texts());
    context.expect(none && none->templates.empty() && !look::creature_figure(*none, 1), "bảng rỗng đọc được, tra thì lỗi");
}

void loads_from_a_folder(Context& context) {
    const Fixture fixture = good();
    const look::ReadFile read = [&](const std::string& path) -> std::expected<std::string, std::string> {
        if (path == "dir/creature_templates.tsv") return fixture.templates;
        if (path == "dir/creatures.tsv") return fixture.models;
        if (path == "dir/creature_clips.tsv") return fixture.clips;
        if (path == "dir/creature_materials.tsv") return fixture.materials;
        return std::unexpected("không có " + path);
    };
    context.expect(look::load_creature_tables("dir", read).has_value(), "đủ bốn tệp");
    const look::ReadFile missing = [&](const std::string& path) -> std::expected<std::string, std::string> {
        if (path == "dir/creature_clips.tsv") return std::unexpected("không có " + path);
        return read(path);
    };
    const auto lost = look::load_creature_tables("dir", missing);
    context.expect(!lost && lost.error().find("creature_clips.tsv") != std::string::npos, "thiếu tệp thì lỗi nêu tên tệp");
}

constexpr std::array kCases{
    Case{.name = "lookups", .body = &lookups},
    Case{.name = "kinds_do_not_mix", .body = &kinds_do_not_mix},
    Case{.name = "animated_figure", .body = &animated_figure},
    Case{.name = "default_clip_and_overlay", .body = &default_clip_and_overlay},
    Case{.name = "static_figure", .body = &static_figure},
    Case{.name = "errors", .body = &errors},
    Case{.name = "loads_from_a_folder", .body = &loads_from_a_folder},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "creature_tests: mọi ca phải qua");
    return 0;
}
