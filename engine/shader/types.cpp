// Tên ngắn của stage và đích dịch, cùng chiều ngược từ chuỗi về enum.
// Shader model chỉ nhận đúng ba ký tự, dấu chấm hoặc gạch dưới ở giữa.
// Ngoài khoảng kOldestModel đến kNewestModel thì parse trả nullopt.
// Nguồn: Forge2 src/shader/types.cpp@d7fcd76. Khác gốc: tham số một chữ c thành unit; vòng for của
// parse_stage thành while (ghi tại chỗ).
#include "shader/types.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::shader {

namespace {

[[nodiscard]] constexpr bool is_digit(char unit) noexcept {
    return unit >= '0' && unit <= '9';
}

[[nodiscard]] constexpr std::uint8_t digit(char unit) noexcept {
    return static_cast<std::uint8_t>(unit - '0');
}

} // namespace

std::string_view tag(Stage stage) noexcept {
    switch (stage) {
    case Stage::kVertex: return "vs";
    case Stage::kHull: return "hs";
    case Stage::kDomain: return "ds";
    case Stage::kGeometry: return "gs";
    case Stage::kPixel: return "ps";
    case Stage::kCompute: return "cs";
    case Stage::kMesh: return "ms";
    case Stage::kAmplification: return "as";
    case Stage::kLibrary: return "lib";
    }
    return {};
}

std::optional<Stage> parse_stage(std::string_view text) noexcept {
    // Khác gốc: gốc là vòng for có câu if (tag trùng) return stage trong thân.
    std::size_t index = 0;
    while (index < kStageCount && tag(static_cast<Stage>(index)) != text) {
        ++index;
    }
    if (index == kStageCount) return std::nullopt;
    return static_cast<Stage>(index);
}

std::string_view name(Target target) noexcept {
    switch (target) {
    case Target::kDxil: return "dxil";
    case Target::kSpirV: return "spirv";
    case Target::kDxbc: return "dxbc";
    case Target::kGlsl: return "glsl";
    }
    return {};
}

std::optional<Target> parse_target(std::string_view text) noexcept {
    if (text == "dxil") return Target::kDxil;
    if (text == "spirv") return Target::kSpirV;
    if (text == "dxbc") return Target::kDxbc;
    if (text == "glsl") return Target::kGlsl;
    return std::nullopt;
}

std::optional<ShaderModel> parse_model(std::string_view text) noexcept {
    if (text.size() != 3) return std::nullopt;
    const char major = text.front();
    const char separator = text.at(1);
    const char minor = text.back();
    const bool shaped = is_digit(major) && is_digit(minor) && (separator == '.' || separator == '_');
    if (!shaped) return std::nullopt;
    const ShaderModel model{.major = digit(major), .minor = digit(minor)};
    const bool known = model >= kOldestModel && model <= kNewestModel;
    if (!known) return std::nullopt;
    return model;
}

} // namespace game::shader
