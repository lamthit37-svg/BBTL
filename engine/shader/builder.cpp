/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/shader/builder.cpp
 *  PHÂN HỆ   : Shader / Builder
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Dựng gói shader và quyết định gói trên đĩa còn dùng được hay phải dịch
 *    lại. Tăng kBuildVersion khi cờ dịch hoặc định dạng gói đổi thì mọi gói cũ
 *    hết hạn. Đường trong gói tương đối với thư mục danh sách, không mang đường
 *    máy dựng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "shader/builder.hpp"

#include "fs/codec.hpp"
#include "fs/disk.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "jobs/jobs.hpp"
#include "shader/failure.hpp"
#include "shader/wire.hpp"

#include <algorithm>
#include <format>
#include <optional>
#include <span>
#include <utility>

namespace game::shader {

namespace {

// Tăng khi cờ dịch, định dạng gói hay định dạng phản chiếu đổi: mọi gói cũ thành "đã cũ".
constexpr std::uint32_t kBuildVersion = 2;

[[nodiscard]] std::optional<std::uint64_t> file_hash(std::string_view path) {
    const Result<fs::Bytes> file = fs::read_file(path);
    if (!file) return std::nullopt;
    return fs::checksum(file->span());
}

// Mọi thứ quyết định kết quả dịch ngoài nội dung tệp nguồn.
[[nodiscard]] std::uint64_t options_hash(const Compiler& compiler, const Manifest& manifest, const ShaderSpec& spec,
    const BuildOptions& options) {
    Writer out;
    out.put(kBuildVersion);
    out.put_text(compiler.version());
    out.put_flag(options.debug);
    out.put(options.vulkan_minor);
    out.put(static_cast<std::uint32_t>(options.targets.size()));
    for (const Target target : options.targets) {
        out.put(std::to_underlying(target));
    }
    const ShaderModel model = spec.model.value_or(manifest.model);
    out.put(std::to_underlying(spec.stage));
    out.put(model.major);
    out.put(model.minor);
    out.put_text(spec.entry);
    out.put_flag(spec.row_major);
    out.put(std::to_underlying(manifest.locations));
    out.put_text(variant_text(manifest.defines));
    out.put_text(variant_text(spec.defines));
    for (const std::vector<std::string>& variant : spec.variants) {
        out.put_text(variant_text(variant));
    }
    for (const std::string& directory : manifest.include_dirs) {
        out.put_text(directory);
    }
    return fs::checksum(out.bytes());
}

// Đường dẫn ghi vào gói: tương đối so với thư mục của danh sách khi tệp nằm trong đó, để gói không
// mang đường dẫn của máy dựng.
[[nodiscard]] std::string stored_path(std::string_view directory, std::string_view path) {
    const bool inside = path.size() > directory.size() + 1 && path.starts_with(directory) &&
        fs::is_separator(path.at(directory.size()));
    if (!inside) return std::string(path);
    return std::string(path.substr(directory.size() + 1));
}

void append(std::vector<std::string>& all, const std::vector<std::string>& more) {
    for (const std::string& item : more) {
        const bool known = std::ranges::find(all, item) != all.end();
        if (!known) all.push_back(item);
    }
}

// Một lượt dựng gói: bốn con trỏ mượn tham số của pack() và chỉ sống trong lời gọi ấy.
struct Work {
    const Compiler* compiler = nullptr;
    const Manifest* manifest = nullptr;
    const ShaderSpec* spec = nullptr;
    const BuildOptions* options = nullptr;
    PackageSource source{};
    std::vector<std::string> files{};
    std::string messages{};
};

[[nodiscard]] Status compile_variant(Work& work, const std::vector<std::string>& variant, Target target) {
    CompileOptions compile;
    compile.stage = work.spec->stage;
    compile.target = target;
    compile.entry = work.spec->entry;
    compile.model = work.spec->model.value_or(work.manifest->model);
    compile.defines = work.manifest->defines;
    compile.defines.append_range(work.spec->defines);
    compile.defines.append_range(variant);
    compile.include_dirs = work.manifest->include_dirs;
    compile.debug = work.options->debug;
    compile.row_major = work.spec->row_major;
    compile.locations = work.manifest->locations;
    compile.vulkan_minor = work.options->vulkan_minor;
    Result<Compiled> compiled = work.compiler->compile(work.spec->source, compile);
    if (!compiled) return pass(compiled);
    append(work.files, compiled->dependencies);
    work.messages += compiled->messages;
    work.source.variants.push_back({.target = target,
        .defines = variant,
        .code = std::move(compiled->code),
        .reflection = std::move(compiled->reflection)});
    return ok();
}

[[nodiscard]] std::string glsl_path(std::string_view hlsl) {
    const std::size_t dot = hlsl.rfind('.');
    if (dot == std::string_view::npos) return std::string(hlsl);
    std::string path(hlsl.substr(0, dot));
    path += ".glsl";
    return path;
}

// "#define TÊN GIÁ_TRỊ" cho mỗi define dạng TÊN hoặc TÊN=GIÁ_TRỊ. GLSL không có cờ -D: backend GL chèn #version
// lên trước code của gói, nên các dòng này đứng ngay sau #version như GLSL đòi.
[[nodiscard]] std::string glsl_defines(const Work& work, const std::vector<std::string>& variant) {
    std::string text;
    const auto add = [&text](const std::string& define) {
        const std::size_t equals = define.find('=');
        text += "#define ";
        text += equals == std::string::npos ? define : define.substr(0, equals) + " " + define.substr(equals + 1);
        text += '\n';
    };
    std::ranges::for_each(work.manifest->defines, add);
    std::ranges::for_each(work.spec->defines, add);
    std::ranges::for_each(variant, add);
    return text;
}

[[nodiscard]] Status attach_glsl(Work& work, const std::vector<std::string>& variant) {
    const PackageVariant* spirv = nullptr;
    for (const PackageVariant& item : work.source.variants) {
        if (item.target == Target::kSpirV && item.defines == variant) spirv = &item;
    }
    if (spirv == nullptr) {
        return fail(ErrorCode::kInvalidArgument, "GLSL cần bản spirv cùng biến thể để lấy phản chiếu");
    }
    const std::string path = glsl_path(work.spec->source);
    const Result<fs::Bytes> file = fs::read_file(path);
    if (!file) return fail(ErrorCode::kNotFound, "thiếu nguồn GLSL cạnh HLSL", path);
    PackageVariant glsl;
    glsl.target = Target::kGlsl;
    glsl.defines = variant;
    glsl.reflection = spirv->reflection;
    const std::string defines = glsl_defines(work, variant);
    const std::span head = std::as_bytes(std::span(defines));
    glsl.code.assign(head.begin(), head.end());
    glsl.code.insert(glsl.code.end(), file->span().begin(), file->span().end());
    work.files.push_back(path);
    work.source.variants.push_back(std::move(glsl));
    return ok();
}

[[nodiscard]] Status compile_targets(Work& work, const std::vector<std::string>& variant) {
    for (const Target target : work.options->targets) {
        if (target == Target::kGlsl) {
            Status attached = attach_glsl(work, variant);
            if (!attached) return pass(attached);
            continue;
        }
        Status compiled = compile_variant(work, variant, target);
        if (!compiled) return pass(compiled);
    }
    return ok();
}

[[nodiscard]] Status add_dependencies(Work& work) {
    for (const std::string& file : work.files) {
        const std::optional<std::uint64_t> hash = file_hash(file);
        if (!hash) return fail(ErrorCode::kIo, "không đọc lại được tệp nguồn shader", file);
        const std::string stored = stored_path(work.manifest->directory, file);
        work.source.dependencies.push_back({.path = stored, .hash = *hash});
    }
    return ok();
}

[[nodiscard]] bool unchanged(std::string_view directory, const Dependency& dependency) {
    return file_hash(fs::join(directory, dependency.path)) == dependency.hash;
}

[[nodiscard]] BuildResult failed(std::string_view name, const Error& error) {
    return {.name = std::string(name), .outcome = Outcome::kFailed, .messages = std::format("{}", error)};
}

void build_range(const Compiler& compiler, const Manifest& manifest, const BuildOptions& options,
    std::span<BuildResult> results, std::size_t begin) {
    for (std::size_t index = 0; index < results.size(); ++index) {
        const ShaderSpec& spec = manifest.shaders.at(begin + index);
        results.subspan(index, 1).front() = build_shader(compiler, manifest, spec, options);
    }
}

} // namespace

std::size_t BuildReport::count(Outcome outcome) const noexcept {
    const auto matches = [&](const BuildResult& result) { return result.outcome == outcome; };
    return static_cast<std::size_t>(std::ranges::count_if(results, matches));
}

Result<Packed> pack(const Compiler& compiler, const Manifest& manifest, const ShaderSpec& spec,
    const BuildOptions& options) {
    Work work{.compiler = &compiler, .manifest = &manifest, .spec = &spec, .options = &options};
    work.source.name = spec.name;
    work.source.stage = spec.stage;
    work.source.debug = options.debug;
    work.source.options_hash = options_hash(compiler, manifest, spec, options);
    for (const std::vector<std::string>& variant : spec.variants) {
        if (Status compiled = compile_targets(work, variant); !compiled) return pass(compiled);
    }
    if (Status added = add_dependencies(work); !added) return pass(added);
    Result<std::vector<std::byte>> bytes = write_package(work.source);
    if (!bytes) return pass(bytes);
    return Packed{.bytes = std::move(*bytes), .messages = std::move(work.messages)};
}

bool is_fresh(const Compiler& compiler, const Manifest& manifest, const ShaderSpec& spec, const BuildOptions& options) {
    const Result<Package> package = Package::load(package_path(options.output, spec.name));
    if (!package) return false;
    const std::uint64_t wanted = options_hash(compiler, manifest, spec, options);
    if (package->options_hash() != wanted) return false;
    const auto same = [&](const Dependency& dependency) { return unchanged(manifest.directory, dependency); };
    return std::ranges::all_of(package->dependencies(), same);
}

BuildResult build_shader(const Compiler& compiler, const Manifest& manifest, const ShaderSpec& spec,
    const BuildOptions& options) {
    const bool skip = !options.force && is_fresh(compiler, manifest, spec, options);
    // Khác gốc: Clang đòi đủ trường khi khởi tạo có tên.
    if (skip) return {.name = spec.name, .outcome = Outcome::kFresh, .messages = {}};
    Result<Packed> packed = pack(compiler, manifest, spec, options);
    if (!packed) return failed(spec.name, packed.error());
    const std::string path = package_path(options.output, spec.name);
    const Status written = fs::write_file_atomic(path, packed->bytes);
    if (!written) return failed(spec.name, written.error());
    return {.name = spec.name, .outcome = Outcome::kBuilt, .messages = std::move(packed->messages)};
}

BuildReport build(const Compiler& compiler, const Manifest& manifest, const BuildOptions& options,
    jobs::JobSystem* jobs) {
    BuildReport report;
    report.results.resize(manifest.shaders.size());
    const Status made = fs::create_directories(options.output);
    for (std::size_t index = 0; !made && index < manifest.shaders.size(); ++index) {
        report.results.at(index) = failed(manifest.shaders.at(index).name, made.error());
    }
    if (!made) return report;
    const std::span<BuildResult> results = report.results;
    const auto run = [&](std::size_t begin, std::size_t end) {
        build_range(compiler, manifest, options, results.subspan(begin, end - begin), begin);
    };
    if (jobs == nullptr) run(0, results.size());
    // Khúc một shader: thời gian dịch mỗi shader chênh nhau nhiều, khúc lớn làm lệch tải.
    if (jobs != nullptr) jobs->parallel_for(results.size(), 1, run);
    return report;
}

} // namespace game::shader
