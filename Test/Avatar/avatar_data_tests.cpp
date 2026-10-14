// Kiểm trên dữ liệu thật của client (CLIENT/data): bảng ngoại hình xuất từ Config giải được bộ mặc
// định của cả hai giới, mọi lưới bộ phận có tệp GLB, Avatar nạp được skeleton chính cùng các clip,
// và Skinner ra ma trận skin hữu hạn cho thế đứng và thế chạy; mọi tổ hợp giới, kiểu tóc, kiểu mặt,
// bộ đồ tân thủ chọn được ở màn tạo nhân vật giải ra đúng lưới của nó (cả dòng cao mô của người
// mẫu) và lưới đó có tệp GLB. Chỉ đăng ký khi bản dựng biết thư mục dữ liệu (CMake đặt
// GAME_CLIENT_DATA) và dữ liệu đã được gom (TOOLS/content/export_look.py, export_config.py rồi
// collect_avatar.py).
#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "core/check.hpp"
#include "fs/disk.hpp"
#include "io/file.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/panel/role_cast.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

[[nodiscard]] std::expected<std::string, std::string> read_table(const std::string& path) {
    const auto text = io::read_text(io::path_from_utf8(path));
    if (!text) return std::unexpected(std::string(io::describe(text.error())));
    return *text;
}

[[nodiscard]] std::string table_folder() {
    return std::string(kClientData) + "/Table";
}

[[nodiscard]] bool has_mesh(const std::string& mesh) {
    return fs::is_file(std::string(kClientData) + "/Model/" + mesh + ".glb");
}

[[nodiscard]] bool is_finite_matrix(const math::Matrix4& matrix) {
    const auto finite = [&matrix](std::size_t col) {
        const math::Vector4& column = matrix[col];
        return std::isfinite(column.x()) && std::isfinite(column.y()) &&
            std::isfinite(column.z()) && std::isfinite(column.w());
    };
    return finite(0) && finite(1) && finite(2) && finite(3);
}

// Hình mặc định của một giới: id mặt, tóc theo bảng thân (id 0 của tóc là một kiểu tóc thật, nên
// Look{} không phải bộ mặc định).
[[nodiscard]] std::expected<look::Figure, look::LookError> default_figure(
    const look::Tables& tables, look::Race race) {
    const look::PlayerBody* body = look::find_body(tables.bodies, race);
    if (body == nullptr) return std::unexpected(look::LookError::kNoBody);
    look::Look wanted;
    wanted.face = body->face;
    wanted.hair = body->hair;
    return look::resolve(tables, race, wanted);
}

// Kiểm một hình mặc định: đủ bộ phận, mọi lưới có tệp GLB, clip đứng tay không.
void check_figure(Context& context, const look::Figure& figure) {
    context.expect(figure.parts.size() >= 5, "đủ áo, tay, giày, mặt, tóc");
    const auto missing = [](const look::Part& part) { return !has_mesh(part.mesh); };
    context.expect(!std::ranges::any_of(figure.parts, missing), "mọi lưới bộ phận có tệp GLB");
    context.expect(figure.idle.name == "空手站立01", "clip đứng tay không");
}

void default_figures_resolve(Context& context) {
    const auto tables = look::load_tables(table_folder(), read_table);
    context.expect(tables.has_value(), "nạp được năm bảng từ CLIENT/data/Table");
    if (!tables) return;
    const auto female = default_figure(*tables, look::Race::kFemale);
    const auto male = default_figure(*tables, look::Race::kMale);
    context.expect(female.has_value() && male.has_value(), "giải được bộ mặc định hai giới");
    if (female) check_figure(context, *female);
    if (male) check_figure(context, *male);
}

// Avatar của một giới nạp được, Skinner ra đủ 56 ma trận hữu hạn cho thế đứng, thế chạy và thế nhảy.
void check_avatar(Context& context, const look::Tables& tables, look::Race race) {
    const auto figure = default_figure(tables, race);
    context.expect(figure.has_value(), "giải được bộ mặc định");
    if (!figure) return;
    const auto avatar = avatar::Avatar::load(*figure, io::path_from_utf8(kClientData));
    context.expect(avatar.has_value(), "nạp được skeleton chính và các clip");
    if (!avatar) return;
    const avatar::ClipLengths lengths = avatar->lengths();
    context.expect(lengths.idle > 1.0F && lengths.run > 0.2F, "clip có độ dài");
    avatar::Skinner skinner;
    const avatar::Playing standing{.stance = avatar::Stance::kIdle, .time = 0.0F};
    context.expect(skinner.update(*avatar, standing).has_value(), "dựng được thế đứng");
    context.expect(skinner.joints().size() == 56, "56 ma trận theo handle xương");
    context.expect(std::ranges::all_of(skinner.joints(), is_finite_matrix), "ma trận skin hữu hạn");
    const avatar::Playing running{.stance = avatar::Stance::kRun, .time = lengths.run * 0.5F};
    context.expect(skinner.update(*avatar, running).has_value(), "dựng được thế chạy");
    context.expect(std::ranges::all_of(skinner.joints(), is_finite_matrix), "thế chạy hữu hạn");
    // Hành động 9 và 12 của ActionSet (跑跳a, 跑跳b) có ở cả hai giới.
    context.expect(lengths.jump_stand.value_or(0.0F) > 0.2F, "có clip nhảy đứng");
    context.expect(lengths.jump_run.value_or(0.0F) > 0.2F, "có clip nhảy chạy");
    const avatar::Playing jumping{.stance = avatar::Stance::kJumpRun, .time = lengths.jump_run.value_or(0.0F) * 0.5F};
    context.expect(skinner.update(*avatar, jumping).has_value(), "dựng được thế nhảy");
    context.expect(std::ranges::all_of(skinner.joints(), is_finite_matrix), "thế nhảy hữu hạn");
}

void avatar_poses(Context& context) {
    const auto tables = look::load_tables(table_folder(), read_table);
    if (!tables) return;
    check_avatar(context, *tables, look::Race::kFemale);
    check_avatar(context, *tables, look::Race::kMale);
}

[[nodiscard]] std::optional<table::Tsv> read_tsv(std::string_view name) {
    const auto text = io::read_text(io::path_from_utf8(table_folder() + "/" + std::string(name)));
    if (!text) return std::nullopt;
    table::TsvResult table = table::parse_tsv(*text);
    if (!table) return std::nullopt;
    return std::move(*table);
}

// Lưới của bộ phận slot trong một hình; rỗng khi hình không có bộ phận đó.
[[nodiscard]] std::string_view mesh_of(const look::Figure& figure, look::Slot slot) {
    const auto found = std::ranges::find(figure.parts, slot, &look::Part::slot);
    return found == figure.parts.end() ? std::string_view{} : std::string_view(found->mesh);
}

// Một bộ ngoại hình của màn tạo trên giới race giải ra đúng lưới của từng id (không rơi về bộ mặc
// định) và mọi lưới có tệp GLB.
void check_creation_look(Context& context, const look::Tables& tables, look::Race race, const look::Look& worn) {
    const std::string what = std::format("giới {} mặt {} tóc {} áo {} tay {} giày {}", static_cast<int>(race), worn.face,
        worn.hair, worn.body, worn.arm, worn.foot);
    const auto figure = look::resolve(tables, race, worn);
    context.expect(figure.has_value(), what + ": giải được");
    if (!figure) return;
    const look::FaceRow* face = look::find_face(tables.faces, worn.face, race);
    const look::HairRow* hair = look::find_hair(tables.hairs, worn.hair, race);
    const look::OutfitRow* body = look::find_outfit(tables.outfits, worn.body, race);
    const look::OutfitRow* arm = look::find_outfit(tables.outfits, worn.arm, race);
    const look::OutfitRow* foot = look::find_outfit(tables.outfits, worn.foot, race);
    const bool has_rows = face != nullptr && hair != nullptr && body != nullptr && arm != nullptr && foot != nullptr;
    context.expect(has_rows, what + ": bảng ngoại hình có đủ năm dòng");
    if (!has_rows) return;
    const bool is_head = mesh_of(*figure, look::Slot::kFace) == face->mesh && mesh_of(*figure, look::Slot::kHair) == hair->mesh;
    const bool is_dress = mesh_of(*figure, look::Slot::kBody) == body->mesh &&
        mesh_of(*figure, look::Slot::kArm) == arm->mesh && mesh_of(*figure, look::Slot::kFoot) == foot->mesh;
    context.expect(is_head && is_dress, what + ": hình dùng đúng lưới của từng id");
    const auto missing = [](const look::Part& part) { return !has_mesh(part.mesh); };
    context.expect(!std::ranges::any_of(figure->parts, missing), what + ": mọi lưới có tệp GLB");
}

// Mọi kiểu tóc và kiểu mặt chọn được của giới sex với một bộ đồ: bản thường (nhân vật vào game) và
// bản cao mô (người mẫu của màn tạo).
void check_creation_sex(Context& context, const look::Tables& tables, const ui::panel::RoleCast& cast, std::int32_t sex) {
    const look::Race race = sex == ui::panel::kFemale ? look::Race::kFemale : look::Race::kMale;
    std::size_t looks = 0;
    for (std::int32_t outfit_index = 0; outfit_index < cast.outfit_count(); ++outfit_index) {
        const ui::panel::NewbieOutfit* outfit = cast.outfit(outfit_index);
        if (outfit == nullptr) continue;
        for (std::int32_t hair = 0; hair < cast.hair_count(sex); ++hair) {
            for (std::int32_t face = 0; face < cast.face_count(sex); ++face) {
                const ui::panel::CastRow face_row{.sex = sex, .index = face};
                const std::int32_t choice = cast.face_choice(face_row);
                if (choice != 1 && choice != 3) continue;
                const ui::panel::ModelLook plain{
                    .sex = sex, .face = cast.face_id(face_row), .hair = cast.hair_id(ui::panel::CastRow{.sex = sex, .index = hair})};
                const ui::panel::ModelLook model = cast.model_look(plain);
                look::Look worn;
                worn.body = outfit->body;
                worn.arm = outfit->arm;
                worn.foot = outfit->foot;
                worn.face = static_cast<std::uint16_t>(plain.face);
                worn.hair = static_cast<std::uint16_t>(plain.hair);
                check_creation_look(context, tables, race, worn);
                worn.face = static_cast<std::uint16_t>(model.face);
                worn.hair = static_cast<std::uint16_t>(model.hair);
                check_creation_look(context, tables, race, worn);
                ++looks;
            }
        }
    }
    // Ba bộ đồ, ba kiểu tóc, sáu kiểu mặt của client 2026.
    context.expect(looks == 54, std::format("giới {}: đủ 54 tổ hợp của màn tạo, đếm được {}", sex, looks));
}

void creation_figures_resolve(Context& context) {
    const auto tables = look::load_tables(table_folder(), read_table);
    const std::optional<table::Tsv> portraits = read_tsv("portraits.tsv");
    const std::optional<table::Tsv> faces = read_tsv("faces.tsv");
    const std::optional<table::Tsv> hairs = read_tsv("hairs.tsv");
    const std::optional<table::Tsv> outfits = read_tsv("newbie_outfits.tsv");
    const bool is_read = tables.has_value() && portraits && faces && hairs && outfits;
    context.expect(is_read, "nạp được bảng ngoại hình và bốn bảng của màn tạo");
    if (!is_read) return;
    ui::panel::CastTables given;
    given.portraits = &*portraits;
    given.faces = &*faces;
    given.hairs = &*hairs;
    given.outfits = &*outfits;
    const ui::panel::RoleCast cast = ui::panel::RoleCast::from_tables(given);
    check_creation_sex(context, *tables, cast, ui::panel::kFemale);
    check_creation_sex(context, *tables, cast, ui::panel::kMale);
}

constexpr std::array kCases{
    Case{.name = "default_figures_resolve", .body = &default_figures_resolve},
    Case{.name = "avatar_poses", .body = &avatar_poses},
    Case{.name = "creation_figures_resolve", .body = &creation_figures_resolve},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(
        game::test::run_all(game::test::kCases) == 0, "avatar_data_tests: mọi ca phải qua");
    return 0;
}
