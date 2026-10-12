#include "client/options.hpp"

#include "client/viewer/client_size.hpp"
#include "core/number.hpp"
#include "io/file.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::client {
namespace {

// Một cặp "--khoá giá trị" trên dòng lệnh.
struct Argument {
    std::string_view key;
    std::string_view value;
};

// Số vòng lặp: số nguyên dương hệ mười chiếm trọn chuỗi; "12x", "0" và "-3" đều bị từ chối.
[[nodiscard]] std::optional<std::uint32_t> frame_count(std::string_view text) noexcept {
    const core::OptionalUnsigned parsed = core::parse_unsigned(text, 10);
    if (!parsed || parsed->length != text.size()) return std::nullopt;
    if (parsed->value == 0) return std::nullopt;
    return parsed->value;
}

[[nodiscard]] bool set_frames(Options& options, std::string_view text) noexcept {
    options.frames = frame_count(text);
    return options.frames.has_value();
}

// Một cạnh của cỡ vùng chơi: số nguyên hệ mười chiếm trọn đoạn, không quá kMaxClientSide.
[[nodiscard]] std::optional<std::uint32_t> side_of(std::string_view text) noexcept {
    const core::OptionalUnsigned parsed = core::parse_unsigned(text, 10);
    if (!parsed || parsed->length != text.size()) return std::nullopt;
    if (parsed->value > kMaxClientSide) return std::nullopt;
    return parsed->value;
}

// Cỡ vùng chơi "RỘNGxCAO" hay "RỘNG,CAO" (cách System.cfg ghi View_Resoution); mỗi cạnh không nhỏ
// hơn kMinClientSize, vì dưới đó cửa sổ ngoài của client 2026 bị nâng lên 800x600.
[[nodiscard]] std::optional<ClientSize> client_size_of(std::string_view text) noexcept {
    const std::size_t split = text.find_first_of("xX,");
    if (split == std::string_view::npos) return std::nullopt;
    const std::optional<std::uint32_t> width = side_of(text.substr(0, split));
    const std::optional<std::uint32_t> height = side_of(text.substr(split + 1));
    if (!width || !height) return std::nullopt;
    const bool is_wide = *width >= kMinClientSize.width;
    const bool is_tall = *height >= kMinClientSize.height;
    if (!is_wide || !is_tall) return std::nullopt;
    return ClientSize{.width = *width, .height = *height};
}

[[nodiscard]] bool set_size(Options& options, std::string_view text) noexcept {
    options.client_size = client_size_of(text);
    return options.client_size.has_value();
}

// resid: số nguyên không âm chiếm trọn chuỗi. 0 là Lạc Dương trong bảng gốc.
[[nodiscard]] bool set_scene_id(Options& options, std::string_view text) noexcept {
    const std::optional<int> resid = core::parse_whole_int(text);
    if (!resid) return false;
    options.scene_id = *resid;
    return true;
}

// Ghi một cặp khoá và giá trị vào options; false khi khoá lạ hoặc giá trị không hợp lệ.
[[nodiscard]] bool known_backend(std::string_view text) noexcept {
    return text == "vulkan" || text == "gles" || text == "d3d12" || text == "d3d11";
}

[[nodiscard]] bool set_backend(Options& options, std::string_view text) {
    if (!known_backend(text)) return false;
    options.backend = std::string(text);
    return true;
}

[[nodiscard]] bool set_option(Options& options, const Argument& argument) {
    if (argument.key == "--frames") return set_frames(options, argument.value);
    if (argument.key == "--scene-id") return set_scene_id(options, argument.value);
    if (argument.key == "--backend") return set_backend(options, argument.value);
    if (argument.key == "--size") return set_size(options, argument.value);
    if (argument.key == "--scene") options.scene_name = argument.value;
    if (argument.key == "--data") options.data_folder = io::path_from_utf8(argument.value);
    if (argument.key == "--shot") options.shot_path = io::path_from_utf8(argument.value);
    return argument.key == "--scene" || argument.key == "--data" || argument.key == "--shot";
}

// Cờ đơn, không kèm giá trị; false khi text không phải một cờ đơn.
[[nodiscard]] bool take_flag(Options& options, std::string_view text) noexcept {
    if (text == "--validate") options.validate = true;
    if (text == "--login") options.is_login = true;
    if (text == "--bare") options.is_bare = true;
    return text == "--validate" || text == "--login" || text == "--bare";
}

[[nodiscard]] bool take_argument(Options& options, Arguments arguments, std::size_t& index) {
    if (take_flag(options, arguments[index])) {
        ++index;
        return true;
    }
    if (index + 1 >= arguments.size()) return false;
    const Argument argument{.key = arguments[index], .value = arguments[index + 1]};
    const bool is_known = set_option(options, argument);
    index += 2;
    return is_known;
}

} // namespace

std::optional<Options> parse_options(Arguments arguments) {
    Options options;
    bool is_valid = true;
    std::size_t index = 0;
    while (index < arguments.size() && is_valid) {
        is_valid = take_argument(options, arguments, index);
    }
    if (!is_valid) return std::nullopt;
    return options;
}

SceneChoice choose_scene(std::string_view requested, SceneNames available) {
    if (!requested.empty()) return std::string(requested);
    if (available.size() != 1) return std::nullopt;
    return available.front();
}

} // namespace game::client
