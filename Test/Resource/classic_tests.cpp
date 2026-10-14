// Test của resource/classic: đọc lại chất liệu OGRE mà bộ chuyển GLB ghi vào extras.ogre. Chuỗi
// mẫu chép từ GLB thật của cảnh huoyangu (站佛像2, 自然石柱, 书阁灯, 岩浆瀑布), rút bớt phần không
// đọc; thêm các ca JSON hỏng để chắc bộ quét dừng đúng chỗ.
#include "core/check.hpp"
#include "math/types.hpp"
#include "classic/classic.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <optional>
#include <string_view>

namespace game::test {
namespace {

using classic::Classic;
using classic::Lit;
using classic::TexOp;

[[nodiscard]] bool near_value(float left, float right) noexcept {
    return std::fabs(left - right) < 1.0e-6F;
}

[[nodiscard]] bool is_grey(const math::Float3& colour, float level) noexcept {
    return near_value(colour.x, level) && near_value(colour.y, level) && near_value(colour.z, level);
}

// Chất liệu không khai gì ngoài texture: mọi trường giữ mặc định của Ogre::Pass.
void plain_pass_keeps_ogre_defaults(Context& context) {
    const std::string_view extras =
        R"({"ogre": {"defined": true, "script": "material 站佛像2\n{\n\ttechnique\n\t{\n\t}\n}",)"
        R"( "parents": [], "pass_count": 1, "settings": {}, "has_program": false}})";
    const std::optional<Classic> classic = classic::read_classic(extras);
    context.expect(classic.has_value(), "có khoá ogre thì có chất liệu");
    if (!classic) return;
    context.expect(is_grey(classic->ambient, 1.0F), "ambient mặc định trắng");
    const bool is_white = near_value(classic->diffuse.x, 1.0F) && near_value(classic->diffuse.w, 1.0F);
    context.expect(is_white, "diffuse mặc định trắng, alpha 1");
    context.expect(is_grey(classic->specular, 0.0F), "specular mặc định đen");
    context.expect(is_grey(classic->emissive, 0.0F), "emissive mặc định đen");
    context.expect(classic->shininess == 0.0F, "shininess mặc định 0");
    context.expect(classic->combine == TexOp::kModulate, "texture nhân ánh sáng");
    context.expect(classic->lit == Lit::kVertex, "chiếu sáng ở đỉnh");
    context.expect(classic->has_fog, "theo sương của cảnh");
    context.expect(!classic->tracks_vertex, "không theo màu đỉnh");
}

// 自然石柱: specular năm số (r g b a shininess) và emissive bốn số (r g b a).
void reads_specular_and_emissive(Context& context) {
    const std::string_view extras =
        R"({"ogre": {"parents": [], "settings": {"specular": "0.588235 0.588235 0.588235 1 12.8",)"
        R"( "emissive": "0.15 0.15 0.15 1"}}})";
    const std::optional<Classic> classic = classic::read_classic(extras);
    context.expect(classic.has_value(), "đọc được");
    if (!classic) return;
    context.expect(is_grey(classic->specular, 0.588235F), "specular lấy ba số đầu");
    context.expect(near_value(classic->shininess, 12.8F), "shininess là số cuối của năm số");
    context.expect(is_grey(classic->emissive, 0.15F), "emissive lấy ba số đầu");
}

// Dạng bốn số của Ogre: r g b shininess, không có alpha.
void four_number_specular_ends_with_shininess(Context& context) {
    const std::string_view extras = R"({"ogre": {"settings": {"specular": "1 0.5 0.25 50"}}})";
    const std::optional<Classic> classic = classic::read_classic(extras);
    context.expect(classic.has_value(), "đọc được");
    if (!classic) return;
    const bool is_colour = near_value(classic->specular.x, 1.0F) && near_value(classic->specular.y, 0.5F) &&
        near_value(classic->specular.z, 0.25F);
    context.expect(is_colour, "ba số đầu là màu");
    context.expect(near_value(classic->shininess, 50.0F), "số thứ tư là shininess");
}

void reads_lighting_and_fog(Context& context) {
    const std::string_view pixel = R"({"ogre": {"settings": {"lighting": "on pslit"}}})";
    const std::string_view off = R"({"ogre": {"settings": {"lighting": "off", "fog_override": "true none"}}})";
    const std::string_view own_fog = R"({"ogre": {"settings": {"fog_override": "true linear 1 1 1 0 10 100"}}})";
    const std::optional<Classic> lit = classic::read_classic(pixel);
    const std::optional<Classic> dark = classic::read_classic(off);
    const std::optional<Classic> custom = classic::read_classic(own_fog);
    context.expect(lit && lit->lit == Lit::kPixel, "on pslit là chiếu sáng từng điểm ảnh");
    context.expect(dark && dark->lit == Lit::kOff, "lighting off");
    context.expect(dark && !dark->has_fog, "fog_override true none tắt sương");
    context.expect(custom && custom->has_fog, "sương riêng của pass chưa đọc: giữ sương cảnh");
}

void reads_colours_and_vertex_tracking(Context& context) {
    const std::string_view extras =
        R"({"ogre": {"settings": {"ambient": "0.5 0.25 0.125 1", "diffuse": "1 1 1 0.8"}}})";
    const std::string_view tracked = R"({"ogre": {"settings": {"diffuse": "vertexcolour"}}})";
    const std::optional<Classic> classic = classic::read_classic(extras);
    const std::optional<Classic> vertex = classic::read_classic(tracked);
    context.expect(classic.has_value() && vertex.has_value(), "đọc được");
    if (!classic || !vertex) return;
    const bool is_ambient = near_value(classic->ambient.x, 0.5F) && near_value(classic->ambient.y, 0.25F) &&
        near_value(classic->ambient.z, 0.125F);
    context.expect(is_ambient, "ambient ba số");
    context.expect(near_value(classic->diffuse.w, 0.8F), "alpha của diffuse là số thứ tư");
    context.expect(vertex->tracks_vertex, "diffuse vertexcolour");
    context.expect(near_value(vertex->diffuse.x, 1.0F), "vertexcolour không đổi màu chất liệu");
}

// 岩浆瀑布 kế thừa Mtl_Character_ColorX2; tóc đổi màu kế thừa họ ColourChangable.
void parents_choose_the_texture_op(Context& context) {
    const std::string_view twice = R"({"ogre": {"parents": ["Mtl_Character_ColorX2"], "settings": {}}})";
    const std::string_view four = R"({"ogre": {"settings": {}, "parents": ["Mtl_Model_TwoTex_Tex1_ColorX4"]}})";
    const std::string_view added = R"({"ogre": {"parents": ["AlphaBlend/ColourChangable/AlphaTemplate"]}})";
    const std::string_view second = R"({"ogre": {"parents": ["Mtl_Model_TwoTex_Tex2_ColorX4"]}})";
    const std::optional<Classic> lava = classic::read_classic(twice);
    const std::optional<Classic> bright = classic::read_classic(four);
    const std::optional<Classic> hair = classic::read_classic(added);
    const std::optional<Classic> other = classic::read_classic(second);
    context.expect(lava && lava->combine == TexOp::kModulate2, "ColorX2 nhân 2");
    context.expect(bright && bright->combine == TexOp::kModulate4, "Tex1_ColorX4 nhân 4");
    context.expect(hair && hair->combine == TexOp::kAdd, "ColourChangable cộng");
    context.expect(other && other->combine == TexOp::kModulate, "ColorX4 của texture thứ hai không tính");
}

// Bản chép script nằm trước settings và chứa ngoặc nhọn, dấu nháy thoát, chữ Hán: phải nhảy qua
// trọn chuỗi chứ không đếm ngoặc bên trong.
void skips_strings_with_braces_and_quotes(Context& context) {
    const std::string_view extras = R"({"other": {"deep": [1, {"x": "}"}]}, "ogre": {"script": "pass \"a\" {\n}}}",)"
                                    R"( "textures": [{"alias": "", "texture": "敦煌/jpg_彩绘.dds"}],)"
                                    R"( "settings": {"emissive": "0.2 0.2 0.2 1"}}})";
    const std::optional<Classic> classic = classic::read_classic(extras);
    context.expect(classic.has_value(), "đọc được dù có ngoặc trong chuỗi");
    if (!classic) return;
    context.expect(is_grey(classic->emissive, 0.2F), "emissive nằm sau các chuỗi rắc rối");
}

void missing_or_broken_json_has_no_material(Context& context) {
    const std::array<std::string_view, 7> texts{
        "",
        "{}",
        R"({"blender": {"ogre": 1}})",
        R"({"ogre": 3})",
        R"({"ogre")",
        R"({"ogre": )",
        R"(["ogre", {}])",
    };
    for (const std::string_view text : texts) {
        context.expect(!classic::read_classic(text).has_value(), "không có chất liệu");
    }
}

// Cắt cụt giữa chừng: phần đọc được trước chỗ cắt vẫn giữ, phần sau là mặc định, không đọc ra
// ngoài chuỗi (ca này chạy dưới ASan).
void truncated_settings_keep_what_was_read(Context& context) {
    const std::string_view whole = R"({"ogre": {"settings": {"emissive": "0.4 0.4 0.4", "specular": "1 1 1 30"}}})";
    for (std::size_t length = 0; length < whole.size(); ++length) {
        static_cast<void>(classic::read_classic(whole.substr(0, length)));
    }
    const std::string_view cut = R"({"ogre": {"settings": {"emissive": "0.4 0.4 0.4", "spec)";
    const std::optional<Classic> classic = classic::read_classic(cut);
    context.expect(classic.has_value(), "phần đầu còn nguyên");
    if (!classic) return;
    context.expect(is_grey(classic->emissive, 0.4F), "emissive đã đọc trước chỗ cắt");
    context.expect(classic->shininess == 0.0F, "specular bị cắt giữ mặc định");
}

constexpr std::array kCases{
    Case{.name = "plain_pass_keeps_ogre_defaults", .body = &plain_pass_keeps_ogre_defaults},
    Case{.name = "reads_specular_and_emissive", .body = &reads_specular_and_emissive},
    Case{.name = "four_number_specular_ends_with_shininess", .body = &four_number_specular_ends_with_shininess},
    Case{.name = "reads_lighting_and_fog", .body = &reads_lighting_and_fog},
    Case{.name = "reads_colours_and_vertex_tracking", .body = &reads_colours_and_vertex_tracking},
    Case{.name = "parents_choose_the_texture_op", .body = &parents_choose_the_texture_op},
    Case{.name = "skips_strings_with_braces_and_quotes", .body = &skips_strings_with_braces_and_quotes},
    Case{.name = "missing_or_broken_json_has_no_material", .body = &missing_or_broken_json_has_no_material},
    Case{.name = "truncated_settings_keep_what_was_read", .body = &truncated_settings_keep_what_was_read},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "classic_tests: mọi ca phải qua");
    return 0;
}
