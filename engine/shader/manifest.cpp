// Đọc danh sách shader: tên gói, stage, tệp nguồn và các biến thể.
// Tối đa 6 define permute, vì 2^6 tập con đúng bằng kMaxVariants.
// Tên gói không có dấu phân cách hay ".."; nháy kép giữ khoảng trắng và '#'.
#include "shader/manifest.hpp"

#include "core/error.hpp"
#include "fs/file.hpp"
#include "fs/path.hpp"
#include "fs/stream.hpp"
#include "shader/failure.hpp"
#include "shader/package.hpp"
#include "shader/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::shader {

namespace {

// Số define tối đa của một permute: 2^6 tập con là kMaxVariants.
constexpr std::size_t kMaxPermuted = 6;

using Tokens = std::vector<std::string>;

// Lỗi của một dòng, chi tiết dạng "dòng 12: tên gói lặp: sky.ps".
[[nodiscard]] core::Failure bad(std::uint32_t line, std::string_view why, std::string_view what) {
    return fail(ErrorCode::kInvalidArgument, "danh sách shader sai", "dòng {}: {}: {}", line, why, what);
}

[[nodiscard]] constexpr bool is_space(char c) noexcept {
    return c == ' ' || c == '\t' || c == '\r';
}

[[nodiscard]] constexpr bool is_letter(char c) noexcept {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

[[nodiscard]] constexpr bool is_digit(char c) noexcept {
    return c >= '0' && c <= '9';
}

[[nodiscard]] constexpr bool is_word(char c) noexcept {
    return is_letter(c) || is_digit(c);
}

[[nodiscard]] bool is_identifier(std::string_view text) noexcept {
    if (text.empty() || !is_letter(text.front())) return false;
    return std::ranges::all_of(text, is_word);
}

// "TÊN" hoặc "TÊN=GIÁ_TRỊ" với TÊN là định danh của C.
[[nodiscard]] bool is_define(std::string_view text) noexcept {
    return is_identifier(text.substr(0, text.find('=')));
}

// Tên gói thành tên tệp, nên không được chứa dấu phân cách hay "..".
[[nodiscard]] bool is_package_name(std::string_view text) noexcept {
    const auto allowed = [](char c) { return is_word(c) || c == '.' || c == '-'; };
    const bool clean = !text.empty() && std::ranges::all_of(text, allowed);
    return clean && text.front() != '.' && !text.contains("..");
}

// Mã thông báo kế tiếp của rest; nháy kép giữ khoảng trắng và '#'. open còn true sau khi hết dòng
// nghĩa là thiếu nháy đóng.
[[nodiscard]] std::string next_token(std::string_view& rest, bool& open) {
    std::string token;
    std::size_t used = 0;
    for (const char c : rest) {
        const bool ends = !open && (is_space(c) || c == '#');
        if (ends) break;
        ++used;
        if (c == '"') open = !open;
        if (c != '"') token += c;
    }
    rest.remove_prefix(used);
    return token;
}

// Tách một dòng thành mã thông báo; dòng trống và dòng chú thích cho danh sách rỗng.
[[nodiscard]] Result<Tokens> split(std::string_view line, std::uint32_t number) {
    Tokens tokens;
    std::string_view rest = line;
    bool open = false;
    while (true) {
        // Khác gốc: hiệu iterator có dấu, không âm vì nằm trong rest.
        const auto trimmed = std::ranges::find_if_not(rest, is_space);
        const auto offset = trimmed - rest.begin();
        const auto start = static_cast<std::size_t>(offset);
        rest.remove_prefix(start);
        if (rest.empty() || rest.front() == '#') break;
        tokens.push_back(next_token(rest, open));
    }
    if (open) return bad(number, "thiếu dấu nháy đóng", line);
    return tokens;
}

[[nodiscard]] std::vector<std::string> split_list(std::string_view text) {
    std::vector<std::string> items;
    for (const auto part : std::views::split(text, ',')) {
        items.emplace_back(std::string_view(part));
    }
    return items;
}

// Stage theo đuôi sau dấu chấm cuối: "sky.ps" ra Pixel.
[[nodiscard]] std::optional<Stage> stage_of(std::string_view text) noexcept {
    return parse_stage(fs::extension(text));
}

// Stage theo tên gói, không được thì theo nguồn bỏ đuôi cuối ("sky.ps.slang" xét "sky.ps").
[[nodiscard]] std::optional<Stage> guess_stage(const ShaderSpec& spec) noexcept {
    if (const auto named = stage_of(spec.name)) return named;
    const std::string_view file = fs::file_name(spec.source);
    return stage_of(file.substr(0, file.rfind('.')));
}

[[nodiscard]] bool has_variant(const ShaderSpec& spec, std::span<const std::string> defines) {
    const std::uint64_t key = variant_key(defines);
    const auto same = [&](const std::vector<std::string>& other) { return variant_key(other) == key; };
    return std::ranges::any_of(spec.variants, same);
}

[[nodiscard]] Status add_variant(ShaderSpec& spec, std::vector<std::string> defines, std::uint32_t line) {
    const bool valid = !defines.empty() && std::ranges::all_of(defines, is_define);
    if (!valid) return bad(line, "define của biến thể sai dạng", spec.name);
    if (has_variant(spec, defines)) return bad(line, "biến thể lặp", spec.name);
    if (spec.variants.size() >= kMaxVariants) {
        return bad(line, "quá 64 biến thể", spec.name);
    }
    spec.variants.push_back(std::move(defines));
    return ok();
}

// Tập con thứ mask của names: bit i bật thì lấy names[i].
[[nodiscard]] std::vector<std::string> subset(std::span<const std::string> names, std::size_t mask) {
    std::vector<std::string> picked;
    for (std::size_t index = 0; index < names.size(); ++index) {
        const bool chosen = ((mask >> index) & 1U) != 0;
        if (chosen) picked.push_back(names.subspan(index, 1).front());
    }
    return picked;
}

// permute=A,B thêm mọi tập con khác rỗng: A; B; A,B. Tập đã có (do variant= khai trước) được bỏ
// qua, không tính là lặp.
[[nodiscard]] Status add_permutations(ShaderSpec& spec, std::string_view list, std::uint32_t line) {
    const std::vector<std::string> names = split_list(list);
    if (names.size() > kMaxPermuted) {
        return bad(line, "permute nhận tối đa 6 define", spec.name);
    }
    const std::size_t count = std::size_t{1} << names.size();
    for (std::size_t mask = 1; mask < count; ++mask) {
        std::vector<std::string> picked = subset(names, mask);
        if (has_variant(spec, picked)) continue;
        if (Status added = add_variant(spec, std::move(picked), line); !added) return pass(added);
    }
    return ok();
}

// Một khoá=giá_trị sau tên và nguồn của lệnh shader.
[[nodiscard]] Status apply_option(ShaderSpec& spec, std::optional<Stage>& stage, std::string_view option,
    std::uint32_t line) {
    const std::size_t equals = option.find('=');
    if (equals == std::string_view::npos) return bad(line, "thiếu '='", option);
    const std::string_view key = option.substr(0, equals);
    const std::string_view value = option.substr(equals + 1);
    if (key == "variant") return add_variant(spec, split_list(value), line);
    if (key == "permute") return add_permutations(spec, value, line);
    if (key == "stage") stage = parse_stage(value);
    if (key == "stage" && stage) return ok();
    if (key == "model") spec.model = parse_model(value);
    if (key == "model" && spec.model) return ok();
    if (key == "entry" && is_identifier(value)) spec.entry = value;
    if (key == "entry" && is_identifier(value)) return ok();
    if (key == "define" && is_define(value)) spec.defines.emplace_back(value);
    if (key == "define" && is_define(value)) return ok();
    return bad(line, "khoá lạ hoặc giá trị sai", option);
}

[[nodiscard]] Status add_shader(Manifest& manifest, const Tokens& tokens, std::uint32_t line) {
    if (tokens.size() < 3) return bad(line, "shader cần tên và nguồn", "shader");
    ShaderSpec spec;
    spec.name = tokens.at(1);
    spec.source = fs::join(manifest.directory, tokens.at(2));
    spec.line = line;
    spec.variants.emplace_back();
    if (!is_package_name(spec.name)) return bad(line, "tên gói sai dạng", spec.name);
    if (manifest.find(spec.name) != nullptr) return bad(line, "tên gói lặp", spec.name);
    std::optional<Stage> stage = guess_stage(spec);
    for (const std::string& option : std::span(tokens).subspan(3)) {
        Status applied = apply_option(spec, stage, option, line);
        if (!applied) return pass(applied);
    }
    if (!stage) return bad(line, "không biết stage", spec.name);
    spec.stage = *stage;
    manifest.shaders.push_back(std::move(spec));
    return ok();
}

// Lệnh một tham số: include, define, model.
[[nodiscard]] Status apply_setting(Manifest& manifest, const Tokens& tokens, std::uint32_t line) {
    const std::string& verb = tokens.front();
    if (tokens.size() != 2) return bad(line, "lệnh cần đúng một tham số", verb);
    const std::string& value = tokens.back();
    if (verb == "include") {
        manifest.include_dirs.push_back(fs::join(manifest.directory, value));
        return ok();
    }
    if (verb == "define" && is_define(value)) {
        manifest.defines.push_back(value);
        return ok();
    }
    const std::optional<ShaderModel> model = parse_model(value);
    if (verb != "model" || !model) return bad(line, "lệnh lạ hoặc giá trị sai", verb);
    manifest.model = *model;
    return ok();
}

[[nodiscard]] Status apply_line(Manifest& manifest, std::string_view text, std::uint32_t line) {
    Result<Tokens> tokens = split(text, line);
    if (!tokens) return pass(tokens);
    if (tokens->empty()) return ok();
    if (tokens->front() == "shader") return add_shader(manifest, *tokens, line);
    return apply_setting(manifest, *tokens, line);
}

} // namespace

// Nội dung rồi thư mục gốc của đường dẫn tương đối: hai vai khác nhau, mọi chỗ gọi đều nêu rõ tên biến.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
Result<Manifest> Manifest::parse(std::string_view text, std::string_view directory) {
    Manifest manifest;
    manifest.directory = fs::normalize(directory);
    std::uint32_t line = 0;
    for (const auto part : std::views::split(text, '\n')) {
        ++line;
        Status applied = apply_line(manifest, std::string_view(part), line);
        if (!applied) return pass(applied);
    }
    return manifest;
}

Result<Manifest> Manifest::load(std::string_view path) {
    Result<fs::Bytes> file = fs::read_file(path);
    if (!file) return pass(file);
    const std::span<const std::byte> bytes = file->span();
    std::string text(bytes.size(), '\0');
    if (!bytes.empty()) std::memcpy(text.data(), bytes.data(), bytes.size());
    return parse(text, fs::parent(path));
}

const ShaderSpec* Manifest::find(std::string_view name) const noexcept {
    const auto found = std::ranges::find(shaders, name, &ShaderSpec::name);
    return found == shaders.end() ? nullptr : &*found;
}

} // namespace game::shader
