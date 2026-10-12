// Test luật ảnh ngoài của resource: URI được phép rời thư mục của GLB khi còn trong thư mục gốc
// dữ liệu, và bị từ chối khi thoát khỏi gốc đó. Hai chiều. Không đụng GPU.
#include "core/check.hpp"
#include "core/error.hpp"
#include "core/text.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "resource/model.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <filesystem>
#include <format>
#include <span>
#include <string>
#include <string_view>
#include <system_error>

namespace game::test {
namespace {

using resource::ImageScope;

[[nodiscard]] ImageScope scope_of(std::string_view directory, std::string_view root) noexcept {
    ImageScope scope;
    scope.directory = directory;
    scope.root = root;
    return scope;
}

[[nodiscard]] bool is_unsupported(const core::Result<std::string>& result) {
    return !result && result.error().code() == core::ErrorCode::kUnsupported;
}

// PNG 1x1, kênh màu, một điểm đỏ. Dùng để chứng minh bộ nạp giải được ảnh ngoài.
constexpr std::array<std::uint8_t, 69> kDotPng{
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x02,
    0x00,
    0x00,
    0x00,
    0x90,
    0x77,
    0x53,
    0xDE,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0xF8,
    0xCF,
    0xC0,
    0x00,
    0x00,
    0x03,
    0x01,
    0x01,
    0x00,
    0xC9,
    0xFE,
    0x92,
    0xEF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
};

struct Fixture {
    std::string scratch;
    std::string data;
    std::string gltf;
};

struct ImageFile {
    std::string_view uri;
    std::string_view path;
};

void remove_tree(std::string_view root) {
    const std::filesystem::path native(core::widen(root));
    std::error_code error;
    std::filesystem::remove_all(native, error);
}

// uri và path nằm trong ImageFile: hai string_view cạnh nhau bị coi là dễ đảo.
[[nodiscard]] bool make_fixture(Context& context, Fixture& fixture, ImageFile image) {
    remove_tree(fixture.scratch);
    const std::string model_dir = fs::join(fixture.data, "Model/nhom");
    const bool made =
        fs::create_directories(model_dir).has_value() && fs::create_directories(fs::parent(image.path)).has_value();
    context.expect(made, "tạo được cây thư mục");
    if (!made) return false;
    fixture.gltf = fs::join(model_dir, "a.gltf");
    const std::string json =
        std::format("{{\"asset\":{{\"version\":\"2.0\"}},\"images\":[{{\"uri\":\"{}\"}}]}}\n", image.uri);
    const auto text = std::as_bytes(std::span(json.data(), json.size()));
    const auto pixels = std::as_bytes(std::span(kDotPng));
    const bool wrote = fs::write_file(fixture.gltf, text).has_value() && fs::write_file(image.path, pixels).has_value();
    context.expect(wrote, "ghi được gltf và png");
    return wrote;
}

// GLB thật nằm ở data/Model/<nhóm>/, URI ảnh là ../../Material/... nên vẫn trong data.
void image_inside_data_root_is_allowed(Context& context) {
    const ImageScope scope = scope_of("data/Model/nhom", "data");
    const auto path = resource::image_path("../../Material/x.dds.png", scope);
    context.expect(path.has_value(), "ảnh trong Material vẫn nằm trong data");
    if (!path) return;
    context.expect(*path == "data/Material/x.dds.png", "đường dẫn đã giải ..");
    const auto encoded = resource::image_path("../../Material/%E6%95%A6%E7%85%8C/a.png", scope);
    context.expect(encoded.has_value(), "URI mã hoá vẫn trong data");
    if (!encoded) return;
    context.expect(*encoded == "data/Material/敦煌/a.png", "giải mã phần trăm rồi mới xét trần");
}

void image_escaping_data_root_is_refused(Context& context) {
    const ImageScope scope = scope_of("data/Model/nhom", "data");
    const auto climbed = resource::image_path("../../../ngoai.png", scope);
    context.expect(is_unsupported(climbed), "thoát khỏi data");
    const auto encoded = resource::image_path("%2E%2E/%2E%2E/%2E%2E/ngoai.png", scope);
    context.expect(is_unsupported(encoded), "thoát sau khi giải mã phần trăm");
    const auto sibling = resource::image_path("../../../database/x.png", scope);
    context.expect(is_unsupported(sibling), "tiền tố data không phải là thư mục data");
    const auto absolute = resource::image_path("/tuyet/doi.png", scope);
    context.expect(is_unsupported(absolute), "URI tuyệt đối");
    const auto drive = resource::image_path("C:anh.png", scope);
    context.expect(is_unsupported(drive), "URI có dấu hai chấm");
}

void image_without_root_stays_in_glb_folder(Context& context) {
    const ImageScope scope = scope_of("data/Model/nhom", "");
    const auto beside = resource::image_path("ke.png", scope);
    context.expect(beside.has_value(), "ảnh cùng thư mục GLB");
    if (!beside) return;
    context.expect(*beside == "data/Model/nhom/ke.png", "đường dẫn cạnh GLB");
    const auto parent = resource::image_path("../../Material/x.png", scope);
    context.expect(is_unsupported(parent), "không có root thì ../ bị cấm như Forge2");
}

void loader_allows_image_inside_data(Context& context) {
    Fixture fixture;
    fixture.scratch = "resource_tests_in";
    fixture.data = "resource_tests_in/data";
    const std::string image = fs::join(fixture.data, "Material/dot.png");
    ImageFile file;
    file.uri = "../../Material/dot.png";
    file.path = image;
    const bool ready = make_fixture(context, fixture, file);
    if (!ready) return;
    const auto model = resource::load_glb_file(fixture.gltf, fixture.data);
    context.expect(model.has_value(), "ảnh ../../Material nằm trong data thì nạp được");
    const bool decoded = model && model->images.size() == 1 && model->images[0].width == 1;
    context.expect(decoded, "png 1x1 ngoài GLB được giải");
    remove_tree(fixture.scratch);
}

void loader_refuses_image_outside_data(Context& context) {
    Fixture fixture;
    fixture.scratch = "resource_tests_out";
    fixture.data = "resource_tests_out/data";
    const std::string image = fs::join(fixture.scratch, "ngoai.png");
    ImageFile file;
    file.uri = "../../../ngoai.png";
    file.path = image;
    const bool ready = make_fixture(context, fixture, file);
    if (!ready) return;
    const auto model = resource::load_glb_file(fixture.gltf, fixture.data);
    const bool refused = !model && model.error().code() == core::ErrorCode::kUnsupported;
    context.expect(refused, "ảnh ngoài data bị từ chối dù tệp có thật");
    remove_tree(fixture.scratch);
}

constexpr std::array kCases{
    Case{.name = "image_inside_data_root_is_allowed", .body = &image_inside_data_root_is_allowed},
    Case{.name = "image_escaping_data_root_is_refused", .body = &image_escaping_data_root_is_refused},
    Case{.name = "image_without_root_stays_in_glb_folder", .body = &image_without_root_stays_in_glb_folder},
    Case{.name = "loader_allows_image_inside_data", .body = &loader_allows_image_inside_data},
    Case{.name = "loader_refuses_image_outside_data", .body = &loader_refuses_image_outside_data},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "resource_tests: mọi ca phải qua");
    return 0;
}
