// Kiểm avatar::Ambient trên dữ liệu thật của cảnh đăng nhập erengu_DL: quạ bay có đường đi của nút
// Dummy02 (8 giây lặp) và clip vỗ cánh, quạ đậu có frame đứng yên nhưng xương vẫn chuyển động,
// frame thiếu nút hay tệp thiếu thì báo lỗi. Chỉ đăng ký khi bản dựng biết thư mục dữ liệu (CMake
// đặt GAME_CLIENT_DATA); dữ liệu chưa gom (TOOLS/content/collect_map.py) thì các ca tự bỏ qua.
#include "avatar/ambient.hpp"
#include "core/check.hpp"
#include "io/file.hpp"
#include "math/matrix.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <filesystem>
#include <string>
#include <string_view>

namespace game::test {
namespace {

#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr float kTolerance = 1e-3F;

[[nodiscard]] std::filesystem::path model_path(std::string_view name) {
    const std::filesystem::path root = io::path_from_utf8(std::string(kClientData));
    return root / "Model" / io::path_from_utf8(std::string(name));
}

[[nodiscard]] avatar::AmbientFiles flying_files(std::string_view node) {
    avatar::AmbientFiles files;
    files.frame = model_path("从刃/从刃_乌鸦_飞姿.frame.glb");
    files.skeleton = model_path("从刃_乌鸦_飞姿.skeleton.glb");
    files.node = std::string(node);
    return files;
}

[[nodiscard]] avatar::AmbientFiles standing_files() {
    avatar::AmbientFiles files;
    files.frame = model_path("从刃/从刃_乌鸦_站姿.frame.glb");
    files.skeleton = model_path("从刃_乌鸦_站姿.skeleton.glb");
    files.node = "Bip01";
    return files;
}

[[nodiscard]] bool has_data() {
    std::error_code ignored;
    return std::filesystem::is_regular_file(flying_files("Dummy02").frame, ignored);
}

[[nodiscard]] bool is_finite_matrix(const math::Matrix4& matrix) {
    const auto finite = [&matrix](std::size_t col) {
        const math::Vector4& column = matrix[col];
        return std::isfinite(column.x()) && std::isfinite(column.y()) &&
            std::isfinite(column.z()) && std::isfinite(column.w());
    };
    return finite(0) && finite(1) && finite(2) && finite(3);
}

[[nodiscard]] bool same_matrix(const math::Matrix4& left, const math::Matrix4& right) {
    for (std::size_t col = 0; col < 4; ++col)
        for (std::size_t row = 0; row < 4; ++row)
            if (std::fabs(left.at(col, row) - right.at(col, row)) > kTolerance) return false;
    return true;
}

void flying_crow_follows_its_path(Context& context) {
    if (!has_data()) return;
    auto crow = avatar::Ambient::load(flying_files("Dummy02"));
    context.expect(crow.has_value(), "nạp được quạ bay");
    if (!crow) return;
    context.expect(crow->update(0.0F).has_value(), "dựng được giây 0");
    const math::Matrix4 begin = crow->attach();
    const std::size_t joints = crow->joints().size();
    context.expect(joints == 30, "30 xương như skin của lưới");
    context.expect(std::ranges::all_of(crow->joints(), is_finite_matrix), "ma trận skin hữu hạn");
    context.expect(crow->update(2.0F).has_value(), "dựng được giây 2");
    context.expect(is_finite_matrix(crow->attach()), "ma trận gắn hữu hạn");
    context.expect(!same_matrix(begin, crow->attach()), "nút Dummy02 đi theo đường bay");
    context.expect(crow->update(8.0F).has_value(), "dựng được giây 8");
    context.expect(same_matrix(begin, crow->attach()), "hết 8 giây đường bay lặp về đầu");
    context.expect(crow->joints().size() == joints, "số xương không đổi");
}

void standing_crow_flaps_in_place(Context& context) {
    if (!has_data()) return;
    auto crow = avatar::Ambient::load(standing_files());
    context.expect(crow.has_value(), "nạp được quạ đậu");
    if (!crow) return;
    context.expect(crow->update(0.0F).has_value(), "dựng được giây 0");
    const math::Matrix4 begin = crow->attach();
    const std::array<math::Matrix4, 1> first{crow->joints().front()};
    context.expect(crow->update(1.0F).has_value(), "dựng được giây 1");
    context.expect(same_matrix(begin, crow->attach()), "frame đứng yên không dời nút");
    context.expect(std::ranges::all_of(crow->joints(), is_finite_matrix), "ma trận skin hữu hạn");
    const bool is_moving = !std::ranges::all_of(crow->joints(), [&first](const math::Matrix4& m) {
        return same_matrix(m, first.front());
    });
    context.expect(is_moving, "xương có chuyển động");
}

void missing_node_or_file_is_an_error(Context& context) {
    if (!has_data()) return;
    const auto no_node = avatar::Ambient::load(flying_files("KhongCoNut"));
    context.expect(!no_node.has_value(), "frame không có nút thì lỗi");
    avatar::AmbientFiles gone = flying_files("Dummy02");
    gone.skeleton = model_path("khong_co_tep.skeleton.glb");
    context.expect(!avatar::Ambient::load(gone).has_value(), "thiếu skeleton thì lỗi");
}

constexpr std::array kCases{
    Case{.name = "flying_crow_follows_its_path", .body = &flying_crow_follows_its_path},
    Case{.name = "standing_crow_flaps_in_place", .body = &standing_crow_flaps_in_place},
    Case{.name = "missing_node_or_file_is_an_error", .body = &missing_node_or_file_is_an_error},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ambient_tests: mọi ca phải qua");
    return 0;
}
