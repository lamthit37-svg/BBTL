// Bộ đọc .mesh: một tam giác ba đỉnh, chỉ số hẹp, và lần nạp theo tên không gắn .glb.
#include "core/check.hpp"
#include "core/error.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "resource/ogre_mesh.hpp"
#include "test.hpp"

#include <array>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <string>
#include <vector>

namespace game::test {
namespace {

void put_u16(std::vector<std::byte>& out, std::uint16_t value) {
    const auto* bytes = reinterpret_cast<const std::byte*>(&value);
    out.insert(out.end(), bytes, bytes + 2);
}

void put_u32(std::vector<std::byte>& out, std::uint32_t value) {
    const auto* bytes = reinterpret_cast<const std::byte*>(&value);
    out.insert(out.end(), bytes, bytes + 4);
}

void put_f32(std::vector<std::byte>& out, float value) {
    const auto* bytes = reinterpret_cast<const std::byte*>(&value);
    out.insert(out.end(), bytes, bytes + 4);
}

void chunk(std::vector<std::byte>& out, std::uint16_t id) {
    put_u16(out, id);
    put_u32(out, 6);
}

void line(std::vector<std::byte>& out, std::string_view text) {
    out.insert(out.end(), reinterpret_cast<const std::byte*>(text.data()),
        reinterpret_cast<const std::byte*>(text.data()) + text.size());
    out.push_back(std::byte{'\n'});
}

std::vector<std::byte> triangle_mesh(std::string_view material = "tuong") {
    std::vector<std::byte> out;
    put_u16(out, 0x1000);
    line(out, "[MeshSerializer_v1.40]");
    chunk(out, 0x3000);
    out.push_back(std::byte{0});
    chunk(out, 0x5000);
    put_u32(out, 3);
    chunk(out, 0x5100);
    chunk(out, 0x5110);
    put_u16(out, 0);
    put_u16(out, 2);
    put_u16(out, 1);
    put_u16(out, 0);
    put_u16(out, 0);
    chunk(out, 0x5200);
    put_u16(out, 0);
    put_u16(out, 12);
    chunk(out, 0x5210);
    put_f32(out, 0.0F);
    put_f32(out, 0.0F);
    put_f32(out, 0.0F);
    put_f32(out, 1.0F);
    put_f32(out, 0.0F);
    put_f32(out, 0.0F);
    put_f32(out, 0.0F);
    put_f32(out, 2.0F);
    put_f32(out, 0.0F);
    chunk(out, 0x4000);
    line(out, material);
    out.push_back(std::byte{1});
    put_u32(out, 3);
    out.push_back(std::byte{0});
    put_u16(out, 0);
    put_u16(out, 1);
    put_u16(out, 2);
    return out;
}

void reads_triangle_positions(Context& context) {
    const std::vector<std::byte> file = triangle_mesh();
    const auto model = resource::load_ogre_mesh(file);
    context.expect(model.has_value(), "mesh tam giác phải đọc được");
    if (!model) return;
    context.expect(model->meshes.size() == 1, "một mesh");
    context.expect(model->meshes[0].primitives.size() == 1, "một submesh");
    const resource::Primitive& primitive = model->meshes[0].primitives[0];
    context.expect(primitive.vertices.size() == 3, "ba đỉnh");
    context.expect(primitive.indices.size() == 3, "ba chỉ số");
    context.expect(primitive.vertices[1].position.x == 1.0F, "đỉnh giữa giữ toạ độ");
    context.expect(primitive.vertices[2].position.y == 2.0F, "đỉnh cuối giữ toạ độ");
    context.expect(model->materials[0].name == "tuong", "tên material gốc");
}

void named_load_uses_mesh_suffix(Context& context) {
    const std::string root = "ogre_mesh_tests_out";
    const std::string file = "ogre_mesh_tests_out/Model/cong.mesh";
    static_cast<void>(fs::create_directories("ogre_mesh_tests_out/Model"));
    const std::vector<std::byte> bytes = triangle_mesh();
    const core::Status written = fs::write_file(file, bytes);
    context.expect(static_cast<bool>(written), "ghi mesh thử");
    if (!written) return;
    const auto model = resource::load_named_model("cong.mesh", root);
    context.expect(model.has_value(), "nạp theo tên .mesh");
    if (!model) return;
    context.expect(model->meshes[0].primitives[0].vertices[1].position.x == 1.0F, "cache trả cùng đỉnh");
    const auto again = resource::load_named_model("cong.mesh", root);
    context.expect(again.has_value(), "lần sau đọc cache");
    context.expect(fs::is_file("ogre_mesh_tests_out/cache/mesh/cong.mesh.tlms"), "cache theo tên gốc");
    std::filesystem::remove_all(root);
}

void reads_shipped_mesh_when_present(Context& context) {
#ifdef GAME_CLIENT_DATA
    const std::string root = GAME_CLIENT_DATA;
    const std::string name = "2022\u7a7a\u6a21\u578bcq.mesh";
    if (!fs::is_file(root + "/Model/" + name)) return;
    const auto model = resource::load_named_model(name, root);
    if (!model) {
        context.expect(false, model.error().message());
        return;
    }
    context.expect(!model->meshes.empty() && !model->meshes[0].primitives.empty(), "mesh thật có tam giác");
#else
    static_cast<void>(context);
#endif
}

void child_inherits_blend_and_cull(Context& context) {
    const std::string root = "ogre_mesh_look_out";
    static_cast<void>(fs::create_directories(root + "/Material"));
    const char* script = "material Cha\n{\ntechnique\n{\npass\n{\nscene_blend src_alpha one_minus_src_alpha\n"
                         "cull_hardware none\nlighting off\ntexture_unit\n{\ntexture goc.dds\n}\n}\n}\n}\n"
                         "material Con : Cha\n{\nset_texture_alias <baseTexture> khac.dds\n"
                         "scroll 1.5 -2\nscroll_anim 0.25 0.3\n}\n";
    const auto* bytes = reinterpret_cast<const std::byte*>(script);
    const core::Status written = fs::write_file(root + "/Material/all.material", std::span<const std::byte>(bytes, std::strlen(script)));
    context.expect(static_cast<bool>(written), "ghi material thử");
    if (!written) return;
    std::vector<std::byte> dds;
    put_u32(dds, 0x20534444U);
    put_u32(dds, 124);
    for (int index = 0; index < 30; ++index) put_u32(dds, 0);
    dds.resize(128 + 8);
    dds[12] = std::byte{4};
    dds[16] = std::byte{4};
    dds[80] = std::byte{4};
    dds[84] = std::byte{'D'};
    dds[85] = std::byte{'X'};
    dds[86] = std::byte{'T'};
    dds[87] = std::byte{'1'};
    const core::Status texture = fs::write_file(root + "/Material/khac.dds", dds);
    context.expect(static_cast<bool>(texture), "ghi dds thử");
    if (!texture) return;
    std::vector<std::byte> file = triangle_mesh("Con");
    const auto model = resource::load_ogre_mesh(file, root);
    context.expect(model.has_value(), "mesh đọc kèm material");
    if (!model) return;
    const resource::Material& material = model->materials[0];
    context.expect(material.alpha == resource::Alpha::kBlend, "con kế thừa trộn");
    context.expect(material.double_sided, "con kế thừa không cull");
    context.expect(material.unlit, "con kế thừa tắt đèn");
    context.expect(material.color.image.has_value(), "alias đè texture cha");
    if (!material.color.image) return;
    context.expect(model->images[*material.color.image].name == "khac.dds", "texture là bản alias");
    context.expect(material.emissive.x == 0.25F && material.emissive.y == 0.3F, "scroll_anim là tốc độ cuộn");
    context.expect(model->meshes[0].primitives[0].vertices[0].uv.x == 1.5F, "scroll tĩnh cộng vào UV");
    context.expect(model->meshes[0].primitives[0].vertices[0].uv.y == -2.0F, "scroll tĩnh theo V");
    std::filesystem::remove_all(root);
}

// Vũ khí và một số bộ đồ ghi <BaseTexture>, không phải <baseTexture>.
void capital_alias_is_the_diffuse_map(Context& context) {
    const std::string root = "ogre_mesh_base_out";
    static_cast<void>(fs::create_directories(root + "/Material"));
    const char* script = "material VuKhi : WeaponTemplateAlpha\n{\nset_texture_alias <BaseTexture> vu.dds\n}\n";
    const auto* bytes = reinterpret_cast<const std::byte*>(script);
    const core::Status written = fs::write_file(root + "/Material/all.material", std::span<const std::byte>(bytes, std::strlen(script)));
    context.expect(static_cast<bool>(written), "ghi material chữ hoa");
    if (!written) return;
    std::vector<std::byte> dds;
    put_u32(dds, 0x20534444U);
    put_u32(dds, 124);
    for (int index = 0; index < 30; ++index) put_u32(dds, 0);
    dds.resize(128 + 8);
    dds[12] = std::byte{4};
    dds[16] = std::byte{4};
    dds[80] = std::byte{4};
    dds[84] = std::byte{'D'};
    dds[85] = std::byte{'X'};
    dds[86] = std::byte{'T'};
    dds[87] = std::byte{'1'};
    const core::Status texture = fs::write_file(root + "/Material/vu.dds", dds);
    context.expect(static_cast<bool>(texture), "ghi dds vũ khí");
    if (!texture) return;
    std::vector<std::byte> file = triangle_mesh("VuKhi");
    const auto model = resource::load_ogre_mesh(file, root);
    context.expect(model.has_value(), "mesh đọc alias chữ hoa");
    if (!model) return;
    context.expect(model->materials[0].color.image.has_value(), "BaseTexture thành ảnh màu");
    std::filesystem::remove_all(root);
}

constexpr std::array kCases{
    Case{.name = "reads_triangle_positions", .body = &reads_triangle_positions},
    Case{.name = "named_load_uses_mesh_suffix", .body = &named_load_uses_mesh_suffix},
    Case{.name = "reads_shipped_mesh_when_present", .body = &reads_shipped_mesh_when_present},
    Case{.name = "child_inherits_blend_and_cull", .body = &child_inherits_blend_and_cull},
    Case{.name = "capital_alias_is_the_diffuse_map", .body = &capital_alias_is_the_diffuse_map},
};

} // namespace
} // namespace game::test

int main() {
    std::setvbuf(stderr, nullptr, _IONBF, 0);
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ogre_mesh_tests: mọi ca phải qua");
    return 0;
}
