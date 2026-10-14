// Test world: mở bảng SceneDefineEx, từ chối resid lạ và file cảnh thiếu. Không đụng GPU.
#include "client/world/world.hpp"
#include "core/check.hpp"
#include "nav/mesh.hpp"
#include "Nav/nav_sample.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <ios>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>

namespace game::test {
namespace {

constexpr std::string_view kTable = "251\thuoyangu\t128\t128\thuoyangu.Scene\t\t\t\n"
                                    "#9\tphu\t1\t1\tno.Scene\t\t\t\n";

void open_rejects_an_empty_table(Context& context) {
    const auto world = client::world::open_world("");
    context.expect(!world.has_value(), "bảng rỗng không mở được");
}

void enter_unknown_resid_is_rejected(Context& context) {
    auto world = client::world::open_world(kTable);
    context.expect(world.has_value(), "bảng một dòng dùng được");
    if (!world) return;
    const auto entered = client::world::enter(*world, 9, {});
    context.expect(!entered.has_value(), "dòng # không được chọn");
    if (entered) return;
    context.expect(entered.error() == client::world::EnterError::kUnknownScene, "resid lạ");
}

void enter_missing_scene_file_is_rejected(Context& context) {
    auto world = client::world::open_world(kTable);
    if (!world) {
        context.expect(false, "bảng mở được");
        return;
    }
    const auto entered = client::world::enter(*world, 251, "khong-co-thu-muc");
    context.expect(!entered.has_value(), "thiếu file .Scene thì không vào cảnh");
    if (entered) return;
    context.expect(entered.error() == client::world::EnterError::kMissingFile, "thiếu tệp");
}

constexpr std::string_view kSceneText = "<Scene name=\"a\"></Scene>\n";

struct SceneDir {
    std::filesystem::path root;
    explicit SceneDir(std::filesystem::path path) : root(std::move(path)) {
        std::filesystem::remove_all(root);
        std::filesystem::create_directories(root);
    }
    SceneDir(const SceneDir&) = delete;
    SceneDir& operator=(const SceneDir&) = delete;
    SceneDir(SceneDir&&) = delete;
    SceneDir& operator=(SceneDir&&) = delete;
    // NOLINTNEXTLINE(bugprone-exception-escape): remove_all(error_code) không ném
    ~SceneDir() noexcept {
        std::error_code ignored;
        std::filesystem::remove_all(root, ignored);
    }
};

[[nodiscard]] bool write_text(const std::filesystem::path& path, std::string_view text) {
    std::ofstream out(path, std::ios::binary);
    out.write(text.data(), static_cast<std::streamsize>(text.size()));
    return static_cast<bool>(out);
}

[[nodiscard]] bool write_scene(const std::filesystem::path& path) {
    return write_text(path, kSceneText);
}

[[nodiscard]] std::string rows_of(int count) {
    std::string text;
    for (int id = 1; id <= count; ++id) {
        text += std::to_string(id);
        text += "\tten\t1\t1\ts";
        text += std::to_string(id);
        text += ".Scene\n";
    }
    return text;
}

void write_scenes(const SceneDir& dir, int count, Context& context) {
    for (int id = 1; id <= count; ++id) {
        const std::string name = "s" + std::to_string(id) + ".Scene";
        context.expect(write_scene(dir.root / name), "ghi được file cảnh");
    }
}

void delete_scenes(const SceneDir& dir, int count) {
    for (int id = 1; id <= count; ++id) {
        const std::string name = "s" + std::to_string(id) + ".Scene";
        std::filesystem::remove(dir.root / name);
    }
}

[[nodiscard]] bool entered_id(client::world::World& world, int id, const SceneDir& dir) {
    const auto entered = client::world::enter(world, id, dir.root);
    return entered.has_value() && world.current && world.current->id == id;
}

void remembered_scene_survives_a_deleted_file(Context& context) {
    const int count = static_cast<int>(client::world::kRemembered) + 1;
    const SceneDir dir(std::filesystem::temp_directory_path() / "thienlong-world-cache");
    write_scenes(dir, count, context);
    auto world = client::world::open_world(rows_of(count));
    context.expect(world.has_value(), "bảng năm cảnh mở được");
    if (!world) return;
    for (int id = 1; id <= count; ++id) {
        context.expect(entered_id(*world, id, dir), "vào được cảnh vừa ghi");
    }
    delete_scenes(dir, count);
    const int oldest = count - static_cast<int>(client::world::kRemembered) + 1;
    context.expect(entered_id(*world, oldest, dir), "cảnh còn trong nhớ không cần file");
    const auto dropped = client::world::enter(*world, 1, dir.root);
    context.expect(!dropped.has_value(), "cảnh bị đẩy khỏi nhớ phải đọc lại đĩa");
    if (dropped) return;
    context.expect(dropped.error() == client::world::EnterError::kMissingFile, "file đã xoá");
}

void startup_file_without_a_number_is_empty(Context& context) {
    const auto resid = client::world::file_resid("khong-co-data");
    context.expect(!resid.has_value(), "không có startup.id thì không có resid");
}

constexpr std::array kCases{
    Case{.name = "open_rejects_an_empty_table", .body = &open_rejects_an_empty_table},
    Case{.name = "enter_unknown_resid_is_rejected", .body = &enter_unknown_resid_is_rejected},
    Case{.name = "enter_missing_scene_file_is_rejected",
        .body = &enter_missing_scene_file_is_rejected},
    Case{.name = "remembered_scene_survives_a_deleted_file",
        .body = &remembered_scene_survives_a_deleted_file},
    Case{.name = "startup_file_without_a_number_is_empty",
        .body = &startup_file_without_a_number_is_empty},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "world_tests: mọi ca phải qua");
    return 0;
}
