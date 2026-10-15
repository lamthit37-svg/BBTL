/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Avatar/creature_data_tests.cpp
 *  PHÂN HỆ   : Avatar / Creature Data Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Kiểm bốn bảng quái và NPC thật (dev/client/assets/Table/creature_*.tsv, do
 *    TOOLS/content/export_creatures.py sinh) với bộ đọc của client: mọi
 *    template giải ra hình, mọi lưới và ảnh material có tệp, và avatar nạp được
 *    xương cùng các clip của mọi mô hình có xương. Là phép thử bảng của công cụ
 *    khớp bộ đọc của client chứ không phải kiểm logic. Chỉ đăng ký khi bản dựng
 *    biết thư mục dữ liệu (CMake đặt GAME_CLIENT_DATA) và dữ liệu đã gom.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "avatar/avatar.hpp"
#include "core/check.hpp"
#include "fs/disk.hpp"
#include "io/file.hpp"
#include "look/creature.hpp"
#include "look/look.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <set>
#include <string>
#include <string_view>

namespace game::test {
namespace {

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

// Số vấn đề in ra tối đa mỗi ca, để một bảng hỏng không đổ cả ngàn dòng.
constexpr std::size_t kMostShown = 8;

[[nodiscard]] std::expected<std::string, std::string> read_table(const std::string& path) {
    const auto text = io::read_text(io::path_from_utf8(path));
    if (!text) return std::unexpected(std::string(io::describe(text.error())));
    return *text;
}

[[nodiscard]] bool has_mesh(const std::string& mesh) {
    const std::string direct = std::string(kClientData) + "/Model/" + mesh;
    return fs::is_file(direct) || fs::is_file(direct + ".glb");
}

[[nodiscard]] std::expected<look::CreatureTables, std::string> real_tables() {
    return look::load_creature_tables(std::string(kClientData) + "/Table", read_table);
}

void tables_load(Context& context) {
    const auto tables = real_tables();
    context.expect(tables.has_value(), tables ? "bảng thật đọc được" : tables.error());
    if (!tables) return;
    context.expect(!tables->templates.empty() && !tables->models.empty() && !tables->clips.empty(), "bảng không rỗng");
}

void every_template_has_a_figure(Context& context) {
    const auto tables = real_tables();
    if (!tables) return;
    std::size_t shown = 0;
    std::size_t built = 0;
    for (const look::CreatureTemplate& row : tables->templates) {
        if (row.model < 0) continue;
        const auto figure = look::creature_figure(*tables, row.id);
        if (figure) {
            ++built;
            continue;
        }
        if (shown++ < kMostShown) context.expect(false, figure.error());
    }
    context.expect(shown == 0 && built > 0, "mọi template có mô hình đều giải ra hình");
}

void meshes_and_skins_exist(Context& context) {
    const auto tables = real_tables();
    if (!tables) return;
    std::set<std::string> seen;
    std::size_t shown = 0;
    for (const look::CreatureTemplate& row : tables->templates) {
        if (row.model < 0) continue;
        const auto figure = look::creature_figure(*tables, row.id);
        if (!figure) continue;
        for (const look::Part& part : figure->figure.parts) {
            if (!seen.insert(part.mesh).second) continue;
            if (!has_mesh(part.mesh) && shown++ < kMostShown) context.expect(false, std::format("thiếu lưới {}", part.mesh));
            for (const std::string& name : part.materials) {
                const look::CreatureMaterial* skin = tables->find_material(name);
                if (skin == nullptr && shown++ < kMostShown) context.expect(false, std::format("thiếu material {}", name));
                if (skin == nullptr) continue;
                const bool is_there = fs::is_file(std::string(kClientData) + "/" + skin->texture);
                if (!is_there && shown++ < kMostShown) context.expect(false, std::format("thiếu ảnh {}", skin->texture));
            }
        }
    }
    context.expect(shown == 0, "mọi lưới và ảnh material có tệp");
}

void avatars_load(Context& context) {
    const auto tables = real_tables();
    if (!tables) return;
    std::set<std::int32_t> tried;
    std::size_t shown = 0;
    std::size_t loaded = 0;
    for (const look::CreatureTemplate& row : tables->templates) {
        if (row.model < 0 || !tried.insert(row.model).second) continue;
        const auto figure = look::creature_figure(*tables, row.id);
        if (!figure || !figure->is_animated) continue;
        const auto avatar = avatar::Avatar::load(figure->figure, std::string(kClientData));
        if (avatar) {
            ++loaded;
            continue;
        }
        if (shown++ < kMostShown) context.expect(false, std::format("mô hình {} ({}): {}", row.model, row.name, avatar.error()));
    }
    context.expect(shown == 0 && loaded > 0, "avatar nạp được xương và clip của mọi mô hình có xương");
}

constexpr std::array kCases{
    Case{.name = "tables_load", .body = &tables_load},
    Case{.name = "every_template_has_a_figure", .body = &every_template_has_a_figure},
    Case{.name = "meshes_and_skins_exist", .body = &meshes_and_skins_exist},
    Case{.name = "avatars_load", .body = &avatars_load},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(!game::test::kClientData.empty(), "creature_data_tests: thiếu GAME_CLIENT_DATA");
    game::core::check(game::test::run_all(game::test::kCases) == 0, "creature_data_tests: mọi ca phải qua");
    return 0;
}
