// K6: mọi tệp TOML của cây máy chủ đọc được và đúng lược đồ. Mười một tệp tiến trình trong config/
// đi qua bộ đọc có struct của module config; config/rules/*.toml và scenes/*/scene.toml mới có
// phép kiểm chung (đọc được, schema = 1). Tệp *.local.toml không bao giờ được mở: đó là tệp bí mật.
// Thư mục thiếu hoặc duyệt dở là lỗi, không phải "không có gì để kiểm".
#include "linttool/config_lint.hpp"

#include "config/admin.hpp"
#include "config/auth.hpp"
#include "config/billing.hpp"
#include "config/client.hpp"
#include "config/cluster.hpp"
#include "config/gate.hpp"
#include "config/issue.hpp"
#include "config/log.hpp"
#include "config/loose.hpp"
#include "config/secrets.hpp"
#include "config/store.hpp"
#include "config/supervisor.hpp"
#include "config/world.hpp"
#include "config/zone.hpp"
#include "content/lint.hpp"
#include "io/file.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::linttool {
namespace {

using Path = std::filesystem::path;
using Paths = std::vector<Path>;
using Result = content::LintResult;
using Checker = config::IssueList (*)(std::string_view);

template <auto Reader>
[[nodiscard]] config::IssueList issues_of(std::string_view text) {
    auto result = Reader(text);
    if (result) return {};
    return std::move(result.error());
}

struct NamedChecker {
    std::string_view name;
    Checker check = nullptr;
};

// Tệp có struct, chỉ tính khi nằm ngay trong config/.
constexpr std::array<NamedChecker, 12> kProcessFiles{{
    {.name = "admin.toml", .check = &issues_of<&config::read_admin>},
    {.name = "auth.toml", .check = &issues_of<&config::read_auth>},
    {.name = "billing.toml", .check = &issues_of<&config::read_billing>},
    {.name = "client.toml", .check = &issues_of<&config::read_client>},
    {.name = "cluster.toml", .check = &issues_of<&config::read_cluster>},
    {.name = "gate.toml", .check = &issues_of<&config::read_gate>},
    {.name = "log.toml", .check = &issues_of<&config::read_log>},
    {.name = "secrets.example.toml", .check = &issues_of<&config::read_secrets>},
    {.name = "store.toml", .check = &issues_of<&config::read_store>},
    {.name = "supervisor.toml", .check = &issues_of<&config::read_supervisor>},
    {.name = "world.toml", .check = &issues_of<&config::read_world>},
    {.name = "zone.toml", .check = &issues_of<&config::read_zone>},
}};

constexpr Checker kLooseCheck = &issues_of<&config::read_loose>;

enum class Schema : std::uint8_t { kProcess, kLoose };

[[nodiscard]] Checker checker_of(std::string_view name, Schema schema) {
    const auto found = std::ranges::find(kProcessFiles, name, &NamedChecker::name);
    const bool is_typed = schema == Schema::kProcess && found != kProcessFiles.end();
    return is_typed ? found->check : kLooseCheck;
}

void add_issue(Result& result, std::string_view path, std::size_t line, std::string message) {
    content::Issue issue;
    issue.path = std::string(path);
    issue.line = line;
    issue.message = std::move(message);
    result.issues.push_back(std::move(issue));
    result.stats.errors += 1;
}

// Một tệp TOML: path trên đĩa, shown là tên in trong lỗi.
struct TomlFile {
    Path path;
    std::string shown;
};

void check_file(Result& result, const TomlFile& file, Checker check) {
    result.stats.files += 1;
    const io::TextResult text = io::read_text(file.path);
    if (!text) {
        add_issue(result, file.shown, 1, std::string(io::describe(text.error())));
        return;
    }
    for (const config::Issue& issue : check(*text)) {
        add_issue(result, file.shown, issue.line, issue.message);
    }
}

// Các mục của một thư mục, xếp theo tên; rỗng khi thư mục không có hoặc duyệt không hết.
[[nodiscard]] std::optional<Paths> list_folder(const Path& folder) {
    std::error_code error;
    Paths entries;
    std::filesystem::directory_iterator cursor{folder, error};
    while (!error && cursor != std::filesystem::directory_iterator{}) {
        entries.push_back(cursor->path());
        cursor.increment(error);
    }
    if (error) return std::nullopt;
    std::ranges::sort(entries);
    return entries;
}

[[nodiscard]] bool is_checked_toml(const Path& entry) {
    std::error_code error;
    if (!std::filesystem::is_regular_file(entry, error)) return false;
    const std::string name = io::utf8_of(entry.filename());
    return name.ends_with(".toml") && !name.ends_with(".local.toml");
}

// Một thư mục chứa thẳng các tệp TOML; shown là tên in trong lỗi, có dấu / cuối.
struct Folder {
    Path path;
    std::string_view shown;
    Schema schema = Schema::kLoose;
};

void check_entry(Result& result, const Folder& folder, const Path& entry) {
    if (!is_checked_toml(entry)) return;
    const std::string name = io::utf8_of(entry.filename());
    const TomlFile file{.path = entry, .shown = std::string(folder.shown) + name};
    check_file(result, file, checker_of(name, folder.schema));
}

void check_folder(Result& result, const Folder& folder) {
    const std::optional<Paths> entries = list_folder(folder.path);
    if (!entries) {
        add_issue(result, folder.shown, 1, "thiếu thư mục hoặc không duyệt hết");
        return;
    }
    for (const Path& entry : *entries) {
        check_entry(result, folder, entry);
    }
}

// Thư mục cảnh không có scene.toml thì bỏ qua: tệp đó do công cụ sinh, luật có mặt thuộc bên sinh.
void check_scene(Result& result, const Path& scene) {
    const Path toml = scene / "scene.toml";
    std::error_code error;
    if (!std::filesystem::is_regular_file(toml, error)) return;
    const std::string shown = "scenes/" + io::utf8_of(scene.filename()) + "/scene.toml";
    check_file(result, TomlFile{.path = toml, .shown = shown}, kLooseCheck);
}

void check_scenes(Result& result, const Path& scenes) {
    const std::optional<Paths> entries = list_folder(scenes);
    if (!entries) {
        add_issue(result, "scenes/", 1, "thiếu thư mục hoặc không duyệt hết");
        return;
    }
    for (const Path& scene : *entries) {
        check_scene(result, scene);
    }
}

} // namespace

void append_config(const Path& root, Result& result) {
    const Path config = root / "config";
    check_folder(result, Folder{.path = config, .shown = "config/", .schema = Schema::kProcess});
    check_folder(result, Folder{.path = config / "rules", .shown = "config/rules/"});
    check_scenes(result, root / "scenes");
}

} // namespace game::linttool
