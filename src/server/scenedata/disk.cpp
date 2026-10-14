#include "scenedata/disk.hpp"

#include "io/file.hpp"
#include "scenedata/ai_rules.hpp"
#include "scenedata/scene.hpp"
#include "scenedata/types.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <variant>

namespace game::scenedata {
namespace {

constexpr std::string_view kManifestName = "scene.toml";
constexpr std::string_view kPathName = "walk.path";
constexpr std::string_view kNavName = "walk.nav";
constexpr std::string_view kTableSuffix = ".tsv";

[[nodiscard]] std::unexpected<LoadError> fail(const std::filesystem::path& where, std::string_view what) {
    return std::unexpected(LoadError{io::utf8_of(where) + ": " + std::string(what)});
}

[[nodiscard]] Loaded<std::string> read_file(const std::filesystem::path& path) {
    io::TextResult text = io::read_text(path);
    if (!text) return fail(path, io::describe(text.error()));
    return std::move(*text);
}

// Mục nhận vào SceneFiles theo tên.
enum class Kind : std::uint8_t { kIgnored, kManifest, kPath, kNav, kTable };

[[nodiscard]] Kind kind_of(std::string_view name) noexcept {
    if (name == kManifestName) return Kind::kManifest;
    if (name == kPathName) return Kind::kPath;
    if (name == kNavName) return Kind::kNav;
    return name.ends_with(kTableSuffix) ? Kind::kTable : Kind::kIgnored;
}

[[nodiscard]] Loaded<std::monostate> take(SceneFiles& files, Kind kind, const std::string& name,
    const std::filesystem::path& path) {
    Loaded<std::string> text = read_file(path);
    if (!text) return std::unexpected(std::move(text.error()));
    switch (kind) {
    case Kind::kManifest: files.manifest = std::move(*text); break;
    case Kind::kPath: files.walk_path = std::move(*text); break;
    case Kind::kNav: files.walk_nav = std::move(*text); break;
    case Kind::kTable: files.tables.push_back(NamedText{.name = name, .text = std::move(*text)}); break;
    case Kind::kIgnored: break;
    }
    return std::monostate{};
}

} // namespace

Loaded<SceneFiles> read_scene_files(const std::filesystem::path& directory) {
    std::error_code error;
    std::filesystem::directory_iterator entries(directory, error);
    if (error) return fail(directory, "không mở được thư mục");
    SceneFiles files;
    files.name = io::utf8_of(directory.filename().empty() ? directory.parent_path().filename() : directory.filename());
    bool has_manifest = false;
    std::size_t visited = 0;
    for (; entries != std::filesystem::directory_iterator{}; entries.increment(error)) {
        if (error) return fail(directory, "không duyệt được thư mục");
        if (++visited > kMaxDirectoryEntries) return fail(directory, "thư mục quá nhiều mục");
        // symlink_status: không đi theo liên kết tượng trưng ra ngoài thư mục cảnh.
        const std::filesystem::file_status status = entries->symlink_status(error);
        if (error || !std::filesystem::is_regular_file(status)) continue;
        const std::string name = io::utf8_of(entries->path().filename());
        const Kind kind = kind_of(name);
        if (kind == Kind::kIgnored) continue;
        has_manifest = has_manifest || kind == Kind::kManifest;
        if (Loaded<std::monostate> taken = take(files, kind, name, entries->path()); !taken) {
            return std::unexpected(std::move(taken.error()));
        }
    }
    if (error) return fail(directory, "không duyệt được thư mục");
    if (!has_manifest) return fail(directory, "thiếu scene.toml");
    return files;
}

Loaded<Scene> load_scene(const std::filesystem::path& directory) {
    Loaded<SceneFiles> files = read_scene_files(directory);
    if (!files) return std::unexpected(std::move(files.error()));
    return parse_scene(*files);
}

Loaded<AiRuleTable> load_ai_rules(const std::filesystem::path& tables_directory) {
    Loaded<std::string> rules = read_file(tables_directory / "monster_ai_rules.tsv");
    if (!rules) return std::unexpected(std::move(rules.error()));
    Loaded<std::string> listed = read_file(tables_directory / "monster_ai_rule_files.tsv");
    if (!listed) return std::unexpected(std::move(listed.error()));
    return parse_ai_rules({.rules = *rules, .files = *listed});
}

} // namespace game::scenedata
