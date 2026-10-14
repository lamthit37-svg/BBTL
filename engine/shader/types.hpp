// Kiểu chung của module shader: stage, đích dịch, shader model, tập stage. Module thay Forge
// Shading Language của _Ref (Tools/ForgeShadingLanguage, 2.200 dòng Python dịch một phương ngữ
// macro sang HLSL, GLSL, Metal rồi gọi dxc và glslangValidator): nguồn là Slang (cú pháp HLSL
// chạy được nguyên văn), Slang dịch ra DXIL, SPIR-V và DXBC. Stage của _Ref (VERT, FRAG, COMP, GEOM, TESC, TESE, GRAPH)
// cộng mesh và amplification của Wicked; ROOTSIG không có bản Forge2 vì root signature dựng từ phản chiếu. Tên ngắn của
// stage là tiền tố profile của DXC ("vs", "ps"), dùng luôn cho tên tệp nguồn: basic.vs.slang. Nguồn: Forge2
// src/shader/types.hpp@d7fcd76. Khác gốc: thêm đích kDxbc cho D3D11 và kGlsl cho GLES.
#pragma once

#include "core/error.hpp"

#include <compare>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>
#include <utility>

namespace game::shader {

using core::Error;
using core::ErrorCode;
using core::fail;
using core::ok;
using core::Result;
using core::Status;

enum class Stage : std::uint8_t {
    kVertex,
    kHull,
    kDomain,
    kGeometry,
    kPixel,
    kCompute,
    kMesh,
    kAmplification,
    // Thư viện nhiều hàm: ray tracing và work graph (GRAPH của _Ref).
    kLibrary,
};

inline constexpr std::size_t kStageCount = 9;

// Tiền tố profile của DXC: "vs", "hs", "ds", "gs", "ps", "cs", "ms", "as", "lib".
[[nodiscard]] std::string_view tag(Stage stage) noexcept;

// Ngược của tag; nullopt khi không phải tên stage.
[[nodiscard]] std::optional<Stage> parse_stage(std::string_view text) noexcept;

enum class Target : std::uint8_t {
    // Direct3D 12.
    kDxil,
    // Vulkan.
    kSpirV,
    kDxbc,
    // OpenGL / OpenGL ES: nguồn GLSL, phản chiếu chép từ bản SPIR-V cùng biến thể.
    kGlsl,
};

inline constexpr std::size_t kTargetCount = 4;

// "dxil", "spirv", "dxbc", "glsl".
[[nodiscard]] std::string_view name(Target target) noexcept;
[[nodiscard]] std::optional<Target> parse_target(std::string_view text) noexcept;

// Shader model của HLSL. Mặc định 6.5: mesh shader, ray query; 6.6 cho heap tài nguyên động, 6.8
// cho work graph.
struct ShaderModel {
    std::uint8_t major = 6;
    std::uint8_t minor = 5;

    [[nodiscard]] constexpr auto operator<=>(const ShaderModel&) const = default;
};

inline constexpr ShaderModel kOldestModel{.major = 6, .minor = 0};
inline constexpr ShaderModel kNewestModel{.major = 6, .minor = 8};

// "6.6" hay "6_6"; nullopt khi sai dạng hay ngoài [kOldestModel, kNewestModel].
[[nodiscard]] std::optional<ShaderModel> parse_model(std::string_view text) noexcept;

// Tập stage, một bit cho mỗi Stage.
class StageSet {
public:
    constexpr StageSet() noexcept = default;
    constexpr explicit StageSet(Stage stage) noexcept : bits_(bit(stage)) {}

    [[nodiscard]] constexpr bool has(Stage stage) const noexcept { return (bits_ & bit(stage)) != 0; }
    [[nodiscard]] constexpr bool empty() const noexcept { return bits_ == 0; }
    [[nodiscard]] constexpr std::uint16_t bits() const noexcept { return bits_; }
    constexpr void add(Stage stage) noexcept { bits_ |= bit(stage); }
    constexpr void add(StageSet other) noexcept { bits_ |= other.bits_; }

    // Dựng lại từ bits() đã lưu; bit ngoài kStageCount bị bỏ.
    [[nodiscard]] static constexpr StageSet from_bits(std::uint16_t bits) noexcept {
        StageSet set;
        set.bits_ = bits & kAllBits;
        return set;
    }

    [[nodiscard]] constexpr bool operator==(const StageSet&) const = default;

private:
    static constexpr std::uint16_t kAllBits = (std::uint16_t{1} << kStageCount) - 1U;

    [[nodiscard]] static constexpr std::uint16_t bit(Stage stage) noexcept {
        return static_cast<std::uint16_t>(std::uint16_t{1} << std::to_underlying(stage));
    }

    std::uint16_t bits_ = 0;
};

} // namespace game::shader
