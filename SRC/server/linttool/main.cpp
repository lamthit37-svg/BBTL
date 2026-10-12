// thienlong_lint — đọc cây SERVER và báo bảng lệch hợp đồng hoặc lệch tham chiếu.
//   thienlong_lint --root <gốc SERVER> --refs <thư mục refs> [--report <tệp>]
// Mã thoát: 0 không lỗi, 1 dữ liệu có lỗi, 2 cách dùng. Đối số Windows lấy bằng CommandLineToArgvW.
#include "content/lint.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "io/file.hpp"
#include "io/platform.hpp"
#include "linttool/config_lint.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <ios>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

#if defined(_WIN32)
#include <processenv.h>
#include <shellapi.h>
#include <winbase.h>
#endif
#if defined(_MSC_VER)
#include <malloc.h>
#endif

namespace {

using game::content::Issue;
using Args = std::span<const std::string>;
using game::content::LintResult;
using game::content::LintSession;
using game::content::TextFile;
using Path = std::filesystem::path;
using PathList = std::vector<Path>;
constexpr std::size_t kShownPerFile = 20;

constexpr std::string_view kUsage =
    "cách dùng: thienlong_lint --root <gốc SERVER> --refs <thư mục refs> [--report <tệp>]\n"
    "Đọc mọi tsv dưới tables và scenes. Mỗi lỗi một dòng đường/dẫn:dòng: nội dung.\n";

struct Request {
    std::string root;
    std::string refs;
    std::string report;
    bool help = false;
    bool failed = false;
};

struct Loaded {
    std::string path;
    std::string text;
    bool failed = false;
};

#if defined(_WIN32)
struct WideCommand {
    wchar_t** list = nullptr;

    WideCommand() = default;
    WideCommand(const WideCommand&) = delete;
    WideCommand& operator=(const WideCommand&) = delete;
    WideCommand(WideCommand&&) = delete;
    WideCommand& operator=(WideCommand&&) = delete;
    ~WideCommand() {
        if (list != nullptr) LocalFree(static_cast<void*>(list));
    }
};
#endif

[[nodiscard]] int fail_usage(std::string_view message) {
    std::println(stderr, "thienlong_lint: {}", message);
    std::println(stderr, "{}", kUsage);
    return 2;
}

struct FlagValue {
    std::string_view flag;
    std::string_view value;
};

void apply_flag(Request& request, FlagValue pair) {
    if (request.failed) return;
    if (pair.flag == "--root")
        request.root = std::string(pair.value);
    else if (pair.flag == "--refs")
        request.refs = std::string(pair.value);
    else if (pair.flag == "--report")
        request.report = std::string(pair.value);
    else
        request.failed = true;
}

[[nodiscard]] bool take_one(Request& request, Args args, std::size_t& index) {
    if (request.failed || index >= args.size()) return false;
    const std::string_view flag = args[index];
    if (flag == "--help") {
        request.help = true;
        index += 1;
        return true;
    }
    if (!flag.starts_with("--") || index + 1 >= args.size()) {
        request.failed = true;
        return false;
    }
    const FlagValue pair{.flag = flag, .value = args[index + 1]};
    apply_flag(request, pair);
    index += 2;
    return !request.failed;
}

[[nodiscard]] bool take_arguments(Request& request, std::span<const std::string> args) {
    std::size_t index = 0;
    bool alive = true;
    while (index < args.size() && alive)
        alive = take_one(request, args, index);
    return alive && !request.failed;
}

[[nodiscard]] bool fields_ready(const Request& request) {
    return !request.root.empty() && !request.refs.empty();
}

void take_tsv(std::vector<Path>& files, const std::filesystem::directory_entry& entry) {
    std::error_code error;
    if (!entry.is_regular_file(error) || error) return;
    const std::string extension = entry.path().extension().string();
    if (!game::content::is_tsv_extension(extension)) return;
    files.push_back(entry.path());
}

[[nodiscard]] bool walk_tree(std::vector<Path>& files, const Path& folder) {
    std::error_code error;
    const auto options = std::filesystem::directory_options::skip_permission_denied;
    std::filesystem::recursive_directory_iterator cursor(folder, options, error);
    if (error) return false;
    const auto end = std::filesystem::recursive_directory_iterator{};
    while (cursor != end && !error) {
        take_tsv(files, *cursor);
        cursor.increment(error);
    }
    return !error;
}

[[nodiscard]] bool walk_dir(std::vector<Path>& files, const Path& folder) {
    std::error_code error;
    std::filesystem::directory_iterator cursor(folder, error);
    if (error) return false;
    const auto end = std::filesystem::directory_iterator{};
    while (cursor != end && !error) {
        take_tsv(files, *cursor);
        cursor.increment(error);
    }
    return !error;
}

enum class WalkDepth : std::uint8_t { kFlat, kTree };

enum class CollectStatus : std::uint8_t { kOk, kMissing, kPartial };

[[nodiscard]] CollectStatus collect_paths(PathList& files, const Path& folder, WalkDepth depth) {
    std::error_code error;
    if (!std::filesystem::is_directory(folder, error) || error) return CollectStatus::kMissing;
    bool walked = false;
    if (depth == WalkDepth::kTree) walked = walk_tree(files, folder);
    if (depth == WalkDepth::kFlat) walked = walk_dir(files, folder);
    if (!walked) return CollectStatus::kPartial;
    return CollectStatus::kOk;
}

[[nodiscard]] int report_collect(CollectStatus status, std::string_view name) {
    if (status == CollectStatus::kOk) return 0;
    if (status == CollectStatus::kMissing) {
        std::println("{}:1: thiếu thư mục {}", name, name);
        return 1;
    }
    std::println("{}:1: không duyệt hết thư mục {}", name, name);
    return 1;
}

struct NamedFile {
    std::string relative;
    Path absolute;
};

using NamedList = std::vector<NamedFile>;

void name_files(std::vector<NamedFile>& named, const std::vector<Path>& files, const Path& root) {
    for (const Path& file : files) {
        NamedFile item;
        const Path relative = file.lexically_relative(root);
        item.relative = game::io::utf8_of(relative);
        item.absolute = file;
        named.push_back(std::move(item));
    }
    std::ranges::sort(named, {}, &NamedFile::relative);
}

void load_one(Loaded& loaded, const Path& absolute) {
    game::io::TextResult text = game::io::read_text(absolute);
    if (!text) {
        loaded.failed = true;
        loaded.text = std::string(game::io::describe(text.error()));
        return;
    }
    loaded.text = std::move(*text);
}

void load_all(std::vector<Loaded>& loaded, const std::vector<NamedFile>& named) {
    for (const NamedFile& file : named) {
        Loaded item;
        item.path = file.relative;
        load_one(item, file.absolute);
        loaded.push_back(std::move(item));
    }
}

void append_one(std::vector<TextFile>& views, const Loaded& item) {
    if (item.failed) return;
    TextFile view;
    view.path = item.path;
    view.text = item.text;
    views.push_back(view);
}

void append_views(std::vector<TextFile>& views, const std::vector<Loaded>& loaded) {
    for (const Loaded& item : loaded)
        append_one(views, item);
}

void add_one_error(LintResult& result, const Loaded& item) {
    if (!item.failed) return;
    Issue issue;
    issue.path = item.path;
    issue.line = 1;
    issue.message = item.text;
    result.issues.push_back(std::move(issue));
    result.stats.files += 1;
    result.stats.errors += 1;
}

void add_read_errors(LintResult& result, const std::vector<Loaded>& loaded) {
    for (const Loaded& item : loaded)
        add_one_error(result, item);
}

[[nodiscard]] bool same_path(const Issue& issue, std::string_view path) {
    return issue.path == path;
}

void print_issue(const Issue& issue) {
    std::println("{}:{}: {}", issue.path, issue.line, issue.message);
}

void print_rest(std::string_view path, std::size_t count) {
    if (count <= kShownPerFile) return;
    const std::size_t rest = count - kShownPerFile;
    std::println("{}:1: còn {} lỗi", path, rest);
}

void show_one(std::size_t& shown, const Issue& issue) {
    if (shown >= kShownPerFile) return;
    print_issue(issue);
    shown += 1;
}

struct IssueCursor {
    std::span<const Issue> issues;
    std::size_t index = 0;
    std::size_t count = 0;
    std::size_t shown = 0;
};

void advance_issue(IssueCursor& cursor, std::string_view path) {
    if (cursor.index >= cursor.issues.size()) return;
    if (!same_path(cursor.issues[cursor.index], path)) return;
    show_one(cursor.shown, cursor.issues[cursor.index]);
    cursor.count += 1;
    cursor.index += 1;
}

void print_file_issues(std::span<const Issue> issues, std::size_t& index) {
    if (index >= issues.size()) return;
    const std::string path = issues[index].path;
    IssueCursor cursor;
    cursor.issues = issues;
    cursor.index = index;
    while (cursor.index < cursor.issues.size() && same_path(cursor.issues[cursor.index], path))
        advance_issue(cursor, path);
    index = cursor.index;
    print_rest(path, cursor.count);
}

[[nodiscard]] bool issue_less(const Issue& left, const Issue& right) {
    if (left.path != right.path) return left.path < right.path;
    if (left.line != right.line) return left.line < right.line;
    return left.message < right.message;
}

void print_issues(std::vector<Issue>& issues) {
    std::ranges::sort(issues, issue_less);
    std::size_t index = 0;
    while (index < issues.size())
        print_file_issues(issues, index);
}

void print_stats(const game::content::LintStats& stats) {
    std::println("tệp: {}", stats.files);
    std::println("bản ghi: {}", stats.records);
    std::println("ô: {}", stats.cells);
    std::println("dòng tham chiếu: {}", stats.ref_rows);
    std::println("lỗi: {}", stats.errors);
}

[[nodiscard]] bool write_report(const Path& path, std::string_view text) {
    std::ofstream out(path, std::ios::binary);
    if (!out) return false;
    out.write(text.data(), static_cast<std::streamsize>(text.size()));
    return out.good();
}

[[nodiscard]] bool write_requested_report(const Request& request, const LintResult& result) {
    if (request.report.empty()) return true;
    const std::string report = game::content::coverage_report(result.coverage);
    const Path report_path = game::io::path_from_utf8(request.report);
    return write_report(report_path, report);
}

struct Collected {
    std::vector<Path> tables;
    std::vector<Path> scenes;
    std::vector<Path> refs;
};

void feed_named(const LintSession& session, std::vector<Loaded>& failures, const NamedFile& file) {
    Loaded item;
    item.path = file.relative;
    load_one(item, file.absolute);
    if (item.failed) {
        failures.push_back(std::move(item));
        return;
    }
    const TextFile view{.path = item.path, .text = item.text};
    game::content::feed_lint_file(session, view);
    // CRT giữ trang của bảng vừa bỏ. Trả trang thì đỉnh bộ nhớ là một tệp, không phải cả cây.
#if defined(_MSC_VER)
    _heapmin();
#endif
}

void feed_all(const LintSession& session, std::vector<Loaded>& failures, const NamedList& named) {
    for (const NamedFile& file : named)
        feed_named(session, failures, file);
}

[[nodiscard]] int emit_result(const Request& request, LintResult& result) {
    const bool wrote = write_requested_report(request, result);
    print_issues(result.issues);
    print_stats(result.stats);
    if (!wrote) {
        std::println(stderr, "thienlong_lint: không ghi được báo cáo");
        return 1;
    }
    if (result.stats.errors != 0) return 1;
    return 0;
}

struct LintRoots {
    const Path* root = nullptr;
    const Path* refs = nullptr;
};

[[nodiscard]] int lint_tree(const Request& request, const LintRoots& roots, const Collected& bag) {
    std::vector<NamedFile> tables;
    std::vector<NamedFile> scenes;
    std::vector<NamedFile> ref_named;
    name_files(tables, bag.tables, *roots.root);
    name_files(scenes, bag.scenes, *roots.root);
    name_files(ref_named, bag.refs, *roots.refs);
    tables.insert(tables.end(), scenes.begin(), scenes.end());
    std::ranges::sort(tables, {}, &NamedFile::relative);
    std::vector<Loaded> ref_data;
    std::vector<TextFile> ref_views;
    load_all(ref_data, ref_named);
    append_views(ref_views, ref_data);
    LintSession session = game::content::open_lint(ref_views);
    std::vector<Loaded> failures;
    feed_all(session, failures, tables);
    LintResult result = game::content::finish_lint(std::move(session));
    add_read_errors(result, ref_data);
    add_read_errors(result, failures);
    game::linttool::append_config(*roots.root, result);
    return emit_result(request, result);
}

[[nodiscard]] int run_lint(const Request& request) {
    const Path root = game::io::path_from_utf8(request.root);
    const Path refs = game::io::path_from_utf8(request.refs);
    std::error_code error;
    if (!std::filesystem::is_directory(root, error) || error) return fail_usage("không thấy gốc SERVER");
    if (!std::filesystem::is_directory(refs, error) || error) return fail_usage("không thấy thư mục refs");
    Collected collected;
    const CollectStatus tables = collect_paths(collected.tables, root / "tables", WalkDepth::kTree);
    const CollectStatus scenes = collect_paths(collected.scenes, root / "scenes", WalkDepth::kTree);
    const CollectStatus ref_paths = collect_paths(collected.refs, refs, WalkDepth::kFlat);
    int status = report_collect(tables, "tables");
    const int scene_status = report_collect(scenes, "scenes");
    const int ref_status = report_collect(ref_paths, "refs");
    if (scene_status != 0) status = scene_status;
    if (ref_status != 0) status = ref_status;
    if (status != 0) return 1;
    const LintRoots roots{.root = &root, .refs = &refs};
    return lint_tree(request, roots, collected);
}

} // namespace

#if defined(_WIN32)
namespace {

[[nodiscard]] std::vector<std::string> command_arguments() {
    int count = 0;
    WideCommand command;
    command.list = CommandLineToArgvW(GetCommandLineW(), &count);
    if (command.list == nullptr || count < 1) return {};
    const auto size = static_cast<std::size_t>(count);
    const std::span<wchar_t*> args(command.list, size);
    std::vector<std::string> texts;
    for (std::size_t index = 1; index < args.size(); ++index) {
        const std::filesystem::path path(args[index]);
        texts.push_back(game::io::utf8_of(path));
    }
    return texts;
}

} // namespace
#else
namespace {

[[nodiscard]] std::vector<std::string> command_arguments(int argc, const char* const* argv) {
    std::vector<std::string> texts;
    for (int index = 1; index < argc; ++index)
        texts.push_back(argv[index]);
    return texts;
}

} // namespace
#endif

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
int main(const int argc, const char* const* const argv) {
    game::io::use_utf8_console();
#if defined(_WIN32)
    static_cast<void>(argc);
    static_cast<void>(argv);
    const std::vector<std::string> args = command_arguments();
#else
    const std::vector<std::string> args = command_arguments(argc, argv);
#endif
    Request request;
    if (!take_arguments(request, args)) return fail_usage("đối số không hợp lệ");
    if (request.help) {
        std::println("{}", kUsage);
        return 0;
    }
    if (!fields_ready(request)) return fail_usage("cần --root và --refs");
    return run_lint(request);
}
