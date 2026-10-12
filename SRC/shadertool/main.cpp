// thienlong_shader — dịch một danh sách shader thành các gói .f2s.
//   thienlong_shader build <danh sách> --out <thư mục> [--target dxil,spirv]
//       [--vulkan 1.3] [--debug] [--force] [--serial] [--dxc <dxcompiler.dll>]
//   thienlong_shader show <gói .f2s>
// build chỉ dịch lại gói đã cũ, song song trên mọi lõi (--serial để tắt). show in một gói.
// Mã thoát: 0 xong, 1 có shader dịch hỏng, 2 lỗi dùng hoặc lỗi đọc.
// Nguồn: Forge2 tools/shader/main.cpp@d7fcd76. Khác gốc: tên công cụ là thienlong_shader;
// console UTF-8 qua io::use_utf8_console và đối số qua hàm cục bộ (dự án không chép scan);
// enumerator mang tiền tố k; thân vòng lặp có nhánh tách hàm; CompilerConfig khai rồi gán.
#include "core/error.hpp"
#include "io/platform.hpp"
#include "jobs/jobs.hpp"
#include "shader/builder.hpp"
#include "shader/compiler.hpp"
#include "shader/manifest.hpp"
#include "shader/package.hpp"
#include "shader/reflection.hpp"
#include "shader/types.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <format>
#include <optional>
#include <print>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace {

namespace shader = game::shader;

using game::core::Error;
using Texts = std::span<const std::string_view>;

constexpr std::string_view kUsage = "cách dùng:\n"
                                    "  thienlong_shader build <danh sách> --out <thư mục> [--target dxil,spirv]\n"
                                    "      [--vulkan 1.3] [--debug] [--force] [--serial] [--dxc <dxcompiler.dll>]\n"
                                    "  thienlong_shader show <gói .f2s>";

// Tuỳ chọn nhận một giá trị ở đối số kế tiếp.
constexpr std::array<std::string_view, 4> kValued{"--out", "--target", "--vulkan", "--dxc"};

struct BuildArgs {
    std::string_view manifest;
    std::string_view dxc;
    shader::BuildOptions options;
    bool serial = false;
};

// Kết quả đang đọc đối số: sai một đối số thì các đối số sau không còn được nhận.
struct Walk {
    BuildArgs* parsed = nullptr;
    Texts args;
    bool ok = true;
};

struct TargetParse {
    std::vector<shader::Target>* targets = nullptr;
    bool ok = true;
};

// flag, rồi value.
struct FlagValue {
    std::string_view flag;
    std::string_view value;
};

[[nodiscard]] int fail(std::string_view message) {
    std::println(stderr, "thienlong_shader: {}", message);
    return 2;
}

[[nodiscard]] int fail_error(const Error& error) {
    const std::string message = std::format("{}", error);
    return fail(message);
}

[[nodiscard]] std::string_view argument_at(Texts args, std::size_t index) noexcept {
    if (index >= args.size()) return {};
    return args[index];
}

void take_target(TargetParse& parse, std::string_view part) {
    if (!parse.ok) return;
    const std::optional<shader::Target> target = shader::parse_target(part);
    parse.ok = target.has_value();
    if (!parse.ok) return;
    parse.targets->push_back(*target);
}

template <class Part>
void take_split(TargetParse& parse, Part part) {
    const std::string_view text(part.begin(), part.end());
    take_target(parse, text);
}

[[nodiscard]] bool set_targets(shader::BuildOptions& options, std::string_view list) {
    options.targets.clear();
    TargetParse parse;
    parse.targets = &options.targets;
    for (const auto part : std::views::split(list, ','))
        take_split(parse, part);
    return parse.ok && !options.targets.empty();
}

// "1.0" tới "1.3".
[[nodiscard]] bool set_vulkan(shader::BuildOptions& options, std::string_view version) {
    const bool shaped = version.size() == 3 && version.starts_with("1.");
    if (!shaped || version.back() < '0' || version.back() > '3') return false;
    options.vulkan_minor = static_cast<std::uint8_t>(version.back() - '0');
    return true;
}

[[nodiscard]] bool apply_value(BuildArgs& parsed, FlagValue item) {
    if (item.value.empty()) return false;
    if (item.flag == "--target") return set_targets(parsed.options, item.value);
    if (item.flag == "--vulkan") return set_vulkan(parsed.options, item.value);
    if (item.flag == "--out") parsed.options.output = item.value;
    if (item.flag == "--dxc") parsed.dxc = item.value;
    return true;
}

[[nodiscard]] bool apply_flag(BuildArgs& parsed, std::string_view flag) {
    if (flag == "--debug") parsed.options.debug = true;
    if (flag == "--force") parsed.options.force = true;
    if (flag == "--serial") parsed.serial = true;
    const bool known = flag == "--debug" || flag == "--force" || flag == "--serial";
    if (known || flag.starts_with("--")) return known;
    // Đối số không có "--" là đường dẫn danh sách, chỉ nhận một.
    if (!parsed.manifest.empty()) return false;
    parsed.manifest = flag;
    return true;
}

[[nodiscard]] bool take_argument(BuildArgs& parsed, const Walk& walk, std::size_t& index) {
    const std::string_view arg = argument_at(walk.args, index);
    const bool valued = std::ranges::contains(kValued, arg);
    if (valued) ++index;
    FlagValue item;
    item.flag = arg;
    item.value = argument_at(walk.args, index);
    if (valued) return apply_value(parsed, item);
    return apply_flag(parsed, arg);
}

void take_at(Walk& walk, std::size_t& index) {
    if (!walk.ok) return;
    walk.ok = take_argument(*walk.parsed, walk, index);
}

[[nodiscard]] std::optional<BuildArgs> parse_build(Texts args) {
    BuildArgs parsed;
    Walk walk;
    walk.parsed = &parsed;
    walk.args = args;
    for (std::size_t index = 0; index < args.size(); ++index)
        take_at(walk, index);
    if (!walk.ok) return std::nullopt;
    const bool complete = !parsed.manifest.empty() && !parsed.options.output.empty();
    if (!complete) return std::nullopt;
    return parsed;
}

[[nodiscard]] std::string_view label(shader::Outcome outcome) noexcept {
    switch (outcome) {
    case shader::Outcome::kBuilt: return "dịch";
    case shader::Outcome::kFresh: return "còn mới";
    case shader::Outcome::kFailed: return "HỎNG";
    }
    return {};
}

void print_one(const shader::BuildResult& result) {
    std::println("[{}] {}", label(result.outcome), result.name);
    if (!result.messages.empty()) std::println("{}", result.messages);
}

void print_counts(const shader::BuildReport& report) {
    const std::size_t built = report.count(shader::Outcome::kBuilt);
    const std::size_t fresh = report.count(shader::Outcome::kFresh);
    const std::size_t failed = report.count(shader::Outcome::kFailed);
    std::println("thienlong_shader: {} dịch, {} còn mới, {} hỏng.", built, fresh, failed);
}

void print_report(const shader::BuildReport& report) {
    for (const shader::BuildResult& result : report.results)
        print_one(result);
    print_counts(report);
}

[[nodiscard]] int run_build(Texts args) {
    const std::optional<BuildArgs> parsed = parse_build(args);
    if (!parsed) return fail(kUsage);
    const auto manifest = shader::Manifest::load(parsed->manifest);
    if (!manifest) {
        const Error& error = manifest.error();
        return fail_error(error);
    }
    shader::CompilerConfig config;
    config.library = std::string(parsed->dxc);
    const auto compiler = shader::Compiler::create(config);
    if (!compiler) {
        const Error& error = compiler.error();
        return fail_error(error);
    }
    std::println("thienlong_shader: DXC {} ({})", compiler->version(), compiler->library());
    std::optional<game::jobs::JobSystem> jobs;
    if (!parsed->serial) jobs.emplace();
    game::jobs::JobSystem* workers = jobs ? &*jobs : nullptr;
    const shader::BuildOptions& options = parsed->options;
    const shader::BuildReport report = shader::build(*compiler, *manifest, options, workers);
    print_report(report);
    return report.succeeded() ? 0 : 1;
}

void print_variant(const shader::Variant& variant) {
    // Hai nhánh cùng là string_view: để một nhánh là literal thì kiểu chung thành std::string tạm
    // và view trỏ vào chuỗi đã huỷ.
    constexpr std::string_view kDefault = "(mặc định)";
    const std::string_view defines = variant.defines.empty() ? kDefault : variant.defines;
    std::println("{} {} — {} byte, mã {:016x}, phản chiếu {:016x}", shader::name(variant.target), defines,
        variant.code.size(), variant.code_hash, variant.reflection_hash);
    std::print("{}", shader::describe(variant.reflection));
}

void print_dependency(const shader::Dependency& dependency) {
    std::println("phụ thuộc {} {:016x}", dependency.path, dependency.hash);
}

[[nodiscard]] int run_show(Texts args) {
    if (args.size() != 1) return fail(kUsage);
    const auto package = shader::Package::load(args.front());
    if (!package) {
        const Error& error = package.error();
        return fail_error(error);
    }
    const char* mode = package->debug() ? "debug" : "release";
    std::println("gói {} — stage {}, {}, tuỳ chọn {:016x}", package->name(), shader::tag(package->stage()), mode,
        package->options_hash());
    for (const shader::Dependency& dependency : package->dependencies()) {
        print_dependency(dependency);
    }
    for (const shader::Variant& variant : package->variants())
        print_variant(variant);
    return 0;
}

[[nodiscard]] int run(Texts args) {
    if (args.empty()) return fail(kUsage);
    const std::string_view verb = args.front();
    if (verb == "build") return run_build(args.subspan(1));
    if (verb == "show") return run_show(args.subspan(1));
    return fail(kUsage);
}

[[nodiscard]] std::vector<std::string_view> arguments_of(std::span<char*> argv) {
    std::vector<std::string_view> result;
    if (argv.empty()) return result;
    for (const char* text : argv.subspan(1))
        result.emplace_back(text);
    return result;
}

[[nodiscard]] int guarded(int argc, char** argv) {
    const std::span<char*> all(argv, static_cast<std::size_t>(argc));
    const std::vector<std::string_view> args = arguments_of(all);
    return run(args);
}

} // namespace

int main(int argc, char** argv) {
    game::io::use_utf8_console();
    try {
        return guarded(argc, argv);
    } catch (const std::exception& error) {
        // fputs không ném: std::println trong catch lại có thể ném ra khỏi main.
        static_cast<void>(std::fputs("thienlong_shader: lỗi không lường trước: ", stderr));
        static_cast<void>(std::fputs(error.what(), stderr));
        static_cast<void>(std::fputc('\n', stderr));
        return 2;
    } catch (...) {
        static_cast<void>(std::fputs("thienlong_shader: lỗi không lường trước\n", stderr));
        return 2;
    }
}
