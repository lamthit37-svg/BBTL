/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Resource/ogre_mesh_tests.cpp
 *  PHÂN HỆ   : Resource / Ogre Mesh Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ đọc .mesh: một tam giác ba đỉnh, chỉ số hẹp, và lần nạp theo tên không
 *    gắn .glb.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "core/error.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "resource/lod.hpp"
#include "resource/ogre_mesh.hpp"
#include "resource/ogre_program.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>
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

// Hồi quy: đường đọc cache bỏ emissive nên thác đã có cache đứng im. Gói điện thoại chỉ mang cache,
// nên APK và iOS cũng đứng im.
void cached_load_keeps_scroll(Context& context) {
    const std::string root = "ogre_mesh_cache_scroll_out";
    static_cast<void>(fs::create_directories(root + "/Material"));
    static_cast<void>(fs::create_directories(root + "/Model"));
    const char* script = "material Thac\n{\ntechnique\n{\npass\n{\nlighting off\ntexture_unit\n{\n"
                         "texture khac.dds\nscroll_anim 0.25 0.3\n}\n}\n}\n}\n";
    const auto* bytes = reinterpret_cast<const std::byte*>(script);
    const core::Status written = fs::write_file(root + "/Material/all.material", std::span<const std::byte>(bytes, std::strlen(script)));
    context.expect(static_cast<bool>(written), "ghi material thác");
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
    const std::vector<std::byte> mesh = triangle_mesh("Thac");
    const core::Status stored = fs::write_file(root + "/Model/thac.mesh", mesh);
    context.expect(static_cast<bool>(texture) && static_cast<bool>(stored), "ghi dds và mesh thác");
    if (!texture || !stored) return;
    const auto first = resource::load_named_model("thac.mesh", root);
    const auto cached = resource::load_named_model("thac.mesh", root);
    context.expect(first.has_value() && cached.has_value(), "nạp thác hai lần");
    if (!first || !cached) return;
    context.expect(fs::is_file(root + "/cache/mesh/thac.mesh.tlms"), "lần đầu ghi cache");
    const resource::Material& fresh = first->materials[0];
    const resource::Material& material = cached->materials[0];
    context.expect(fresh.emissive.x == 0.25F && fresh.emissive.y == 0.3F, "lần đầu có tốc độ cuộn");
    context.expect(material.unlit, "cache giữ tắt đèn");
    context.expect(material.emissive.x == 0.25F && material.emissive.y == 0.3F, "cache giữ tốc độ cuộn");
    std::filesystem::remove_all(root);
}

// Dữ liệu thật: pubu5 khai "scroll_anim 0 0.3" trong Material/all.material; đọc hai lần để lần hai
// đi qua cache. Bỏ qua khi máy không có dữ liệu client (như reads_shipped_mesh_when_present).
void shipped_waterfall_scrolls(Context& context) {
#ifdef GAME_CLIENT_DATA
    const std::string root = GAME_CLIENT_DATA;
    const std::string name = "水瀑布/pubu5.mesh";
    if (!fs::is_file(root + "/Model/" + name)) return;
    const auto first = resource::load_named_model(name, root);
    const auto cached = resource::load_named_model(name, root);
    context.expect(first.has_value() && cached.has_value(), "nạp thác thật hai lần");
    if (!first || !cached) return;
    const resource::Material& fresh = first->materials[0];
    const resource::Material& material = cached->materials[0];
    context.expect(fresh.emissive.y == 0.3F, "thác thật có tốc độ cuộn V");
    context.expect(material.unlit && material.emissive.y == 0.3F, "thác thật qua cache vẫn cuộn");
#else
    static_cast<void>(context);
#endif
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

// all.material của client gốc có 1313 dòng set_texture_alias kết thúc bằng khoảng trắng (tóc nhân vật nữ,
// đo 2026-10-13): phần sau dấu cách cuối là chuỗi rỗng nên chất liệu từng mất ảnh. Dòng scene_blend cũng
// có đuôi trắng và phải vẫn đọc ra "replace" là đặc.
void trailing_spaces_keep_the_texture(Context& context) {
    const std::string root = "ogre_mesh_trail_out";
    static_cast<void>(fs::create_directories(root + "/Material"));
    const char* script = "material Toc : Mau\r\n{\r\n    set_texture_alias <baseTexture> toc.dds    \r\n"
                         "scene_blend replace \t \r\n}\r\n";
    const auto* bytes = reinterpret_cast<const std::byte*>(script);
    const core::Status written = fs::write_file(root + "/Material/all.material", std::span<const std::byte>(bytes, std::strlen(script)));
    context.expect(static_cast<bool>(written), "ghi material có đuôi trắng");
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
    const core::Status texture = fs::write_file(root + "/Material/toc.dds", dds);
    context.expect(static_cast<bool>(texture), "ghi dds tóc");
    if (!texture) return;
    std::vector<std::byte> file = triangle_mesh("Toc");
    const auto model = resource::load_ogre_mesh(file, root);
    context.expect(model.has_value(), "mesh đọc material có đuôi trắng");
    if (!model) return;
    context.expect(model->materials[0].color.image.has_value(), "ảnh không mất vì đuôi trắng");
    context.expect(model->materials[0].alpha == resource::Alpha::kOpaque, "scene_blend replace có đuôi trắng là đặc");
    std::filesystem::remove_all(root);
}

// Lưới side x side đỉnh gợn sóng (đủ tam giác để build_lods sinh mức thô), chỉ số 16 bit.
std::vector<std::byte> grid_mesh(std::uint16_t side) {
    const std::uint32_t vertex_count = std::uint32_t{side} * side;
    const std::uint32_t cells = std::uint32_t{side - 1U} * (side - 1U);
    std::vector<std::byte> out;
    put_u16(out, 0x1000);
    line(out, "[MeshSerializer_v1.40]");
    chunk(out, 0x3000);
    out.push_back(std::byte{0});
    chunk(out, 0x5000);
    put_u32(out, vertex_count);
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
    for (std::uint32_t index = 0; index < vertex_count; ++index) {
        const auto across = static_cast<float>(index % side);
        const auto along = static_cast<float>(index / side);
        put_f32(out, across);
        put_f32(out, std::sin(across * 0.7F) * std::cos(along * 0.5F));
        put_f32(out, along);
    }
    chunk(out, 0x4000);
    line(out, "luoi");
    out.push_back(std::byte{1});
    put_u32(out, cells * 6);
    out.push_back(std::byte{0});
    for (std::uint32_t cell = 0; cell < cells; ++cell) {
        const auto corner = static_cast<std::uint16_t>((cell / (side - 1U)) * side + (cell % (side - 1U)));
        const auto right = static_cast<std::uint16_t>(corner + 1U);
        const auto below = static_cast<std::uint16_t>(corner + side);
        const auto diagonal = static_cast<std::uint16_t>(below + 1U);
        for (const std::uint16_t vertex : {corner, below, right, right, below, diagonal}) put_u16(out, vertex);
    }
    return out;
}

// Bộ mã chỉ số của meshoptimizer chỉ giữ nguyên tới phép xoay vòng ba đỉnh trong một tam giác (giữ
// chiều quấn): so tam giác sau khi xoay đỉnh nhỏ nhất lên đầu.
std::vector<std::uint32_t> canonical(const std::vector<std::uint32_t>& indices) {
    std::vector<std::uint32_t> out = indices;
    for (std::size_t corner = 0; corner + 2 < out.size(); corner += 3) {
        const auto first = out.begin() + static_cast<std::ptrdiff_t>(corner);
        std::rotate(first, std::min_element(first, first + 3), first + 3);
    }
    return out;
}

bool same_levels(const std::vector<std::vector<std::uint32_t>>& left,
    const std::vector<std::vector<std::uint32_t>>& right) {
    if (left.size() != right.size()) return false;
    for (std::size_t level = 0; level < left.size(); ++level) {
        if (canonical(left[level]) != canonical(right[level])) return false;
    }
    return true;
}

// Cache bản 2 mang mức chi tiết: lần nạp từ cache với LodUse::kKeep trả đúng các mức build_lods
// dựng từ mesh gốc (máy chạy khỏi giản lược lại), còn lần nạp mặc định không có mức nào.
void cache_carries_lods(Context& context) {
    const std::string root = "ogre_mesh_lod_out";
    static_cast<void>(fs::create_directories(root + "/Model"));
    const std::vector<std::byte> bytes = grid_mesh(24);
    const core::Status written = fs::write_file(root + "/Model/luoi.mesh", bytes);
    context.expect(static_cast<bool>(written), "ghi lưới thử");
    if (!written) return;
    auto expected = resource::load_ogre_mesh(bytes, root);
    context.expect(expected.has_value(), "lưới gốc đọc được");
    if (!expected) return;
    resource::build_lods(*expected);
    const auto& wanted = expected->meshes[0].primitives[0].lods;
    context.expect(!wanted.empty(), "lưới đủ lớn để có mức thô");
    constexpr auto kKeep = resource::LodUse::kKeep;
    const auto first = resource::load_named_model("luoi.mesh", root, resource::TextureTier::kBc, kKeep);
    const auto cached = resource::load_named_model("luoi.mesh", root, resource::TextureTier::kBc, kKeep);
    const auto plain = resource::load_named_model("luoi.mesh", root);
    context.expect(first.has_value() && cached.has_value() && plain.has_value(), "nạp lưới ba lần");
    if (!first || !cached || !plain) return;
    context.expect(first->has_lods && first->meshes[0].primitives[0].lods == wanted, "lần đầu có mức");
    const bool keeps = same_levels(cached->meshes[0].primitives[0].lods, wanted);
    context.expect(cached->has_lods && keeps, "cache giữ mức");
    context.expect(!plain->has_lods && plain->meshes[0].primitives[0].lods.empty(), "mặc định bỏ mức");
    std::filesystem::remove_all(root);
}

std::vector<std::byte> tiny_dxt1() {
    std::vector<std::byte> dds;
    put_u32(dds, 0x20534444U);
    put_u32(dds, 124);
    for (int index = 0; index < 30; ++index)
        put_u32(dds, 0);
    dds.resize(128 + 8);
    dds[12] = std::byte{4};
    dds[16] = std::byte{4};
    dds[80] = std::byte{4};
    dds[84] = std::byte{'D'};
    dds[85] = std::byte{'X'};
    dds[86] = std::byte{'T'};
    dds[87] = std::byte{'1'};
    return dds;
}

bool length_matches(const std::vector<std::byte>& bytes, std::size_t found, std::size_t size) {
    if (found < 4 || found == std::string_view::npos) return false;
    std::uint32_t length = 0;
    std::memcpy(&length, bytes.data() + found - 4, 4);
    return length == size;
}

// Đổi đúng ô tên ảnh (u32 độ dài + byte), không đụng hình học nén.
bool patch_name(std::vector<std::byte>& bytes, std::string_view from, std::string_view to) {
    if (from.size() != to.size() || from.empty()) return false;
    const auto* text = reinterpret_cast<const char*>(bytes.data());
    const std::string_view view(text, bytes.size());
    const std::size_t found = view.find(from);
    if (!length_matches(bytes, found, from.size())) return false;
    std::memcpy(bytes.data() + found, to.data(), to.size());
    return true;
}

void expect_add_sheet(Context& context, const resource::Model& model) {
    const resource::Material& material = model.materials[0];
    context.expect(material.alpha == resource::Alpha::kAdd, "tấm cộng sáng");
    context.expect(material.unlit, "tấm cộng sáng không đèn để cuộn UV");
    context.expect(material.suppress_fog, "fog_override tắt sương");
    context.expect(material.base_color.x == 4.0F, "ColorX4 nhân bốn");
    context.expect(material.base_color.w == 1.0F, "alpha của hệ số là 1");
    context.expect(material.emissive.x == 0.6F, "scroll_anim là tốc độ cuộn");
    context.expect(material.color.image.has_value(), "có ảnh phát sáng");
    if (!material.color.image) return;
    context.expect(model.images[*material.color.image].name == "mau.dds", "ảnh màu là scrollTex");
    context.expect(material.surface.image.has_value(), "có ảnh mặt nạ");
    if (!material.surface.image) return;
    context.expect(model.images[*material.surface.image].name == "mat.dds", "mặt nạ là baseTexture");
}

// Mẫu TwoTex_Tex2_ColorX4 không có thân. scene_blend add lấy scrollTex làm màu và baseTexture làm
// mặt nạ. Cache lưu tên ảnh màu; sửa ô đó vẫn phải lấy lại scrollTex từ script.
void additive_sheet_uses_scroll_and_mask(Context& context) {
    const std::string root = "ogre_mesh_add_out";
    static_cast<void>(fs::create_directories(root + "/Material"));
    static_cast<void>(fs::create_directories(root + "/Model"));
    const char* script = "material Tam : Mtl_Model_TwoTex_Tex2_ColorX4\n"
                         "{\nset_texture_alias <baseTexture> mat.dds\n"
                         "set_texture_alias <scrollTex> mau.dds\n"
                         "fog_override true none\nscene_blend add\nscroll_anim 0.6 0\n}\n"
                         "material Mot\n{\nscene_blend one one\n}\n";
    const auto* bytes = reinterpret_cast<const std::byte*>(script);
    const auto script_bytes = std::span<const std::byte>(bytes, std::strlen(script));
    const core::Status written = fs::write_file(root + "/Material/all.material", script_bytes);
    context.expect(static_cast<bool>(written), "ghi material cộng sáng");
    if (!written) return;
    const std::vector<std::byte> dds = tiny_dxt1();
    const core::Status glow = fs::write_file(root + "/Material/mau.dds", dds);
    const core::Status mask = fs::write_file(root + "/Material/mat.dds", dds);
    const std::vector<std::byte> mesh = triangle_mesh("Tam");
    const core::Status stored = fs::write_file(root + "/Model/tam.mesh", mesh);
    const bool files = static_cast<bool>(glow) && static_cast<bool>(mask) && static_cast<bool>(stored);
    context.expect(files, "ghi ảnh và mesh");
    if (!files) return;
    const std::vector<std::byte> factors = triangle_mesh("Mot");
    const auto plain = resource::load_ogre_mesh(factors, root);
    context.expect(plain.has_value(), "one one đọc được");
    if (!plain) return;
    context.expect(plain->materials[0].alpha == resource::Alpha::kAdd, "one one là cộng sáng");
    context.expect(plain->materials[0].unlit, "one one không đèn");
    context.expect(plain->materials[0].base_color.x == 1.0F, "không có ColorX4 thì hệ số 1");
    const auto first = resource::load_named_model("tam.mesh", root);
    context.expect(first.has_value(), "nạp tấm lần đầu");
    if (!first) return;
    expect_add_sheet(context, *first);
    const std::string cache = root + "/cache/mesh/tam.mesh.tlms";
    auto cached_bytes = fs::read_file(cache);
    context.expect(static_cast<bool>(cached_bytes), "đọc cache tấm");
    if (!cached_bytes) return;
    std::vector<std::byte> patched(cached_bytes->span().begin(), cached_bytes->span().end());
    const bool renamed = patch_name(patched, "mau.dds", "mat.dds");
    context.expect(renamed, "đổi tên ảnh trong cache");
    if (!renamed) return;
    const core::Status rewritten = fs::write_file(cache, patched);
    context.expect(static_cast<bool>(rewritten), "ghi cache đã sửa");
    if (!rewritten) return;
    const auto again = resource::load_named_model("tam.mesh", root);
    context.expect(again.has_value(), "nạp tấm từ cache");
    if (!again) return;
    expect_add_sheet(context, *again);
    std::filesystem::remove_all(root);
}

// Tấm "特效片暗" của thú cưỡi: scene_blend zero one_minus_src_colour làm tối nền theo màu ảnh. Đọc
// như tấm cộng sáng (scrollTex là màu, baseTexture là mặt nạ, không đèn, ColorX4) nhưng alpha là
// kDarken để Forward chọn pipeline làm tối; trước đây rơi vào kBlend và ra mảng đen trắng đặc.
void dark_sheet_reads_as_darken(Context& context) {
    const std::string root = "ogre_mesh_dark_out";
    static_cast<void>(fs::create_directories(root + "/Material"));
    const char* script = "material Toi : Mtl_Model_TwoTex_Tex2_ColorX4\n"
                         "{\nset_texture_alias <baseTexture> mat.dds\n"
                         "set_texture_alias <scrollTex> mau.dds\n"
                         "fog_override true none\nscene_blend zero one_minus_src_colour\n"
                         "scroll_anim 0.7 0\n}\n"
                         "material Mo\n{\nscene_blend colour_blend\n}\n";
    const auto* bytes = reinterpret_cast<const std::byte*>(script);
    const auto script_bytes = std::span<const std::byte>(bytes, std::strlen(script));
    const core::Status written = fs::write_file(root + "/Material/all.material", script_bytes);
    context.expect(static_cast<bool>(written), "ghi material làm tối");
    if (!written) return;
    const std::vector<std::byte> dds = tiny_dxt1();
    const core::Status glow = fs::write_file(root + "/Material/mau.dds", dds);
    const core::Status mask = fs::write_file(root + "/Material/mat.dds", dds);
    const bool files = static_cast<bool>(glow) && static_cast<bool>(mask);
    context.expect(files, "ghi ảnh");
    if (!files) return;
    const std::vector<std::byte> dark = triangle_mesh("Toi");
    const auto model = resource::load_ogre_mesh(dark, root);
    context.expect(model.has_value(), "tấm làm tối đọc được");
    if (!model) return;
    const resource::Material& material = model->materials[0];
    context.expect(material.alpha == resource::Alpha::kDarken, "zero one_minus_src_colour là làm tối");
    context.expect(material.unlit, "tấm làm tối không đèn để cuộn UV");
    context.expect(material.suppress_fog, "fog_override tắt sương");
    context.expect(material.base_color.x == 4.0F, "ColorX4 nhân bốn");
    context.expect(material.emissive.x == 0.7F, "scroll_anim là tốc độ cuộn");
    context.expect(material.surface.image.has_value(), "có ảnh mặt nạ");
    const std::vector<std::byte> other = triangle_mesh("Mo");
    const auto blended = resource::load_ogre_mesh(other, root);
    context.expect(blended.has_value(), "colour_blend đọc được");
    if (!blended) return;
    context.expect(blended->materials[0].alpha == resource::Alpha::kBlend, "hệ số khác vẫn trộn alpha");
    std::filesystem::remove_all(root);
}

// all.material giữ tên GBK. Bảng thú chồng tên UTF-8 lên cùng lưới. Tra chỉ theo byte gốc thì
// trượt, scene_blend và ảnh không áp, con đổi màu thành trắng.
void painted_utf8_finds_gbk_material(Context& context) {
    const std::string root = "ogre_mesh_gbk_out";
    static_cast<void>(fs::create_directories(root + "/Material"));
    static_cast<void>(fs::create_directories(root + "/Model"));
    const unsigned char gbk_ice[] = {0xB1, 0xF9};
    std::string script = "material ";
    script.append(reinterpret_cast<const char*>(gbk_ice), sizeof(gbk_ice));
    script += "\n{\nset_texture_alias <baseTexture> vang.dds\n}\n";
    const auto* raw = reinterpret_cast<const std::byte*>(script.data());
    const auto script_bytes = std::span<const std::byte>(raw, script.size());
    const core::Status written = fs::write_file(root + "/Material/all.material", script_bytes);
    context.expect(static_cast<bool>(written), "ghi material GBK");
    if (!written) return;
    const std::vector<std::byte> dds = tiny_dxt1();
    const core::Status image = fs::write_file(root + "/Material/vang.dds", dds);
    const std::vector<std::byte> mesh = triangle_mesh("Goc");
    const core::Status stored = fs::write_file(root + "/Model/son.mesh", mesh);
    const bool files = static_cast<bool>(image) && static_cast<bool>(stored);
    context.expect(files, "ghi ảnh và mesh");
    if (!files) return;
    const std::vector<std::string> names{"\u51B0"};
    const auto painted = resource::load_mesh_painted("son.mesh", root, names);
    context.expect(painted.has_value(), "nạp material chồng UTF-8");
    if (!painted) return;
    const bool has_image = painted->materials[0].color.image.has_value();
    context.expect(has_image, "UTF-8 khớp khoá GBK");
    if (!has_image) return;
    const auto slot = *painted->materials[0].color.image;
    context.expect(painted->images[slot].name == "vang.dds", "ảnh của tên GBK");
    const std::string raw_name(reinterpret_cast<const char*>(gbk_ice), sizeof(gbk_ice));
    const std::vector<std::byte> direct = triangle_mesh(raw_name);
    const auto from_mesh = resource::load_ogre_mesh(direct, root);
    context.expect(from_mesh.has_value(), "tên GBK trong lưới vẫn khớp");
    if (!from_mesh) return;
    context.expect(from_mesh->materials[0].color.image.has_value(), "lưới GBK có ảnh");
    std::filesystem::remove_all(root);
}

constexpr std::string_view kProgramHeader =
    "material\tprogram\tflow\tflow_light_type\tflow_tex_type\toutline\toutline_ctrl\tdissolve\t"
    "blend\tdepth_write\talpha_ref\tcull\tdepth_pass\tdepth_ref\temissive\tdiffuse\tflow_factor\t"
    "outline_pow\toutline_color\tbase\tctl\treflection\toutline_ctrl_texture\n";

// Mtl_OutlineCtrl_FlowLight: luồng theo alpha ảnh nền, viền có ảnh điều khiển, pass ghi depth.
constexpr std::string_view kRimRow =
    "bo\tModel_OutlineCtrl_FlowLight_PS\t1\t0\t0\t1\t1\t0\talpha_blend\toff\tgreater 220\tnone\t"
    "1\tgreater 180\t\t\t0.5 0.5 1 2\t3 0.5\t1 0.8 0 1.5\tbo.dds\t\tluong.dds\tvien.dds\n";

// Character_FlowLight (FLOW_TEX_TYPE 2): hệ số luồng ở kênh r của ctl, pass đục có cắt alpha.
constexpr std::string_view kFlowRow =
    "kiem\tCharacter_FlowLight\t1\t0\t2\t0\t0\t0\t\t\tgreater 128\t\t0\t\t\t\t2.0 2.0 0 5\t\t\t"
    "kiem.dds\tkiem_ctl.dds\tkiem_luong.dds\t\n";

[[nodiscard]] bool is_near(float left, float right) {
    return std::abs(left - right) < 1.0e-6F;
}

void expect_rim_row(Context& context, const resource::ProgramLook& look) {
    const resource::Flow& flow = look.flow;
    context.expect(flow.has_flow && !flow.flows_by_uv, "luồng theo pháp tuyến");
    context.expect(flow.mask_in_alpha, "FLOW_TEX_TYPE 0 lấy alpha ảnh nền");
    context.expect(flow.has_outline && flow.uses_outline_map, "viền có ảnh điều khiển");
    context.expect(look.alpha == resource::Alpha::kBlend, "alpha_blend là trộn");
    context.expect(is_near(look.cutoff, 220.5F / 255.0F), "greater 220 của pass màu");
    context.expect(look.double_sided == std::optional<bool>{true}, "cull none là hai mặt");
    const bool has_prepass = look.depth_prepass.has_value();
    context.expect(has_prepass, "có pass ghi depth");
    if (has_prepass) context.expect(is_near(*look.depth_prepass, 180.5F / 255.0F), "greater 180");
    const bool factor = is_near(flow.factor.x, 0.5F) && is_near(flow.factor.w, 2.0F);
    context.expect(factor, "flowFactor đủ bốn số");
    const bool power = is_near(flow.outline_pow.x, 3.0F) && is_near(flow.outline_pow.y, 0.5F);
    context.expect(power, "outlinePow");
    context.expect(is_near(flow.outline_color.w, 1.5F), "cường độ viền giữ trên 1");
    context.expect(look.ctl.empty() && look.flow_map == "luong.dds", "ảnh luồng, không ctl");
    context.expect(look.outline_map == "vien.dds", "ảnh viền");
}

void expect_flow_row(Context& context, const resource::ProgramLook& look) {
    const resource::Flow& flow = look.flow;
    context.expect(flow.has_flow && !flow.mask_in_alpha, "FLOW_TEX_TYPE 2 lấy kênh r của ctl");
    context.expect(!flow.has_outline, "không viền");
    context.expect(look.alpha == resource::Alpha::kMask, "đục có cắt là mặt nạ");
    context.expect(is_near(look.cutoff, 128.5F / 255.0F), "greater 128");
    context.expect(!look.double_sided && !look.depth_prepass, "không khai cull, không pass depth");
    context.expect(look.ctl == "kiem_ctl.dds", "ảnh ctl");
}

void programs_read_flow_and_rim(Context& context) {
    std::string text(kProgramHeader);
    text += kRimRow;
    text += kFlowRow;
    const auto table = resource::parse_programs(text);
    context.expect(table.has_value(), "bảng hai dòng đọc được");
    if (!table) return;
    context.expect(table->size() == 2, "hai chất liệu");
    const auto rim = table->find("bo");
    const auto flow = table->find("kiem");
    const bool found = rim != table->end() && flow != table->end();
    context.expect(found, "tra theo tên chất liệu");
    if (!found) return;
    expect_rim_row(context, rim->second);
    expect_flow_row(context, flow->second);
}

// Bảng lệch công cụ là lỗi cả bảng, không đoán cột.
void programs_reject_bad_table(Context& context) {
    std::string renamed(kProgramHeader);
    renamed.replace(renamed.find("ctl\t"), 3, "xyz");
    context.expect(!resource::parse_programs(renamed).has_value(), "tiêu đề lạ");
    std::string short_row(kProgramHeader);
    short_row += "bo\tModel_Outline_PS\t0\n";
    context.expect(!resource::parse_programs(short_row).has_value(), "thiếu cột");
    std::string bad_number(kProgramHeader);
    bad_number += kFlowRow;
    bad_number.replace(bad_number.find("2.0 2.0"), 7, "2.0 x.0");
    context.expect(!resource::parse_programs(bad_number).has_value(), "số hỏng");
    context.expect(!resource::parse_programs("").has_value(), "bảng rỗng");
}

void rejection_cutoff_rounds_like_ogre(Context& context) {
    const auto greater = resource::rejection_cutoff("greater 128");
    const auto equal = resource::rejection_cutoff("greater_equal 128");
    context.expect(greater && is_near(*greater, 128.5F / 255.0F), "greater N là N + 0,5");
    context.expect(equal && is_near(*equal, 127.5F / 255.0F), "greater_equal N là N - 0,5");
    context.expect(!resource::rejection_cutoff("less 5"), "hàm khác thì không đoán");
    context.expect(!resource::rejection_cutoff("greater"), "thiếu số");
}

// Bảng thật của công cụ (export_material_programs.py) phải đọc trọn.
void shipped_programs_parse(Context& context) {
#ifdef GAME_CLIENT_DATA
    const std::string path = std::string(GAME_CLIENT_DATA) + "/Material/programs.tsv";
    if (!fs::is_file(path)) return;
    const auto bytes = fs::read_file(path);
    context.expect(bytes.has_value(), "đọc programs.tsv");
    if (!bytes) return;
    const std::span<const std::byte> raw = bytes->span();
    const std::string text(reinterpret_cast<const char*>(raw.data()), raw.size());
    const auto table = resource::parse_programs(text);
    if (!table) {
        context.expect(false, table.error().message());
        return;
    }
    context.expect(table->size() > 3000, "đủ chất liệu luồng và viền");
#else
    static_cast<void>(context);
#endif
}

constexpr std::array kCases{
    Case{.name = "reads_triangle_positions", .body = &reads_triangle_positions},
    Case{.name = "cache_carries_lods", .body = &cache_carries_lods},
    Case{.name = "named_load_uses_mesh_suffix", .body = &named_load_uses_mesh_suffix},
    Case{.name = "reads_shipped_mesh_when_present", .body = &reads_shipped_mesh_when_present},
    Case{.name = "child_inherits_blend_and_cull", .body = &child_inherits_blend_and_cull},
    Case{.name = "cached_load_keeps_scroll", .body = &cached_load_keeps_scroll},
    Case{.name = "shipped_waterfall_scrolls", .body = &shipped_waterfall_scrolls},
    Case{.name = "capital_alias_is_the_diffuse_map", .body = &capital_alias_is_the_diffuse_map},
    Case{.name = "trailing_spaces_keep_the_texture", .body = &trailing_spaces_keep_the_texture},
    Case{.name = "additive_sheet_uses_scroll_and_mask", .body = &additive_sheet_uses_scroll_and_mask},
    Case{.name = "dark_sheet_reads_as_darken", .body = &dark_sheet_reads_as_darken},
    Case{.name = "painted_utf8_finds_gbk_material", .body = &painted_utf8_finds_gbk_material},
    Case{.name = "programs_read_flow_and_rim", .body = &programs_read_flow_and_rim},
    Case{.name = "programs_reject_bad_table", .body = &programs_reject_bad_table},
    Case{.name = "rejection_cutoff_rounds_like_ogre", .body = &rejection_cutoff_rounds_like_ogre},
    Case{.name = "shipped_programs_parse", .body = &shipped_programs_parse},
};

} // namespace
} // namespace game::test

int main() {
    std::setvbuf(stderr, nullptr, _IONBF, 0);
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ogre_mesh_tests: mọi ca phải qua");
    return 0;
}
