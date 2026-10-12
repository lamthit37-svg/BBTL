// Chất liệu kiểu OGRE của client gốc: màu ambient, diffuse, specular, emissive, kiểu chiếu sáng và
// sương của pass đầu, đúng như script .material ghi. Bộ chuyển GLB chép các dòng ấy vào
// extras.ogre của từng chất liệu (settings là cặp "từ khoá": "phần còn lại của dòng", parents là
// các template mà chất liệu kế thừa); tệp này chỉ đọc lại, không tự suy ra gì.
// Mặc định là mặc định của Ogre::Pass: ambient và diffuse trắng, specular và emissive đen,
// shininess 0, có chiếu sáng, theo sương của cảnh.
// Phép ghép texture với ánh sáng lấy từ tên template: BLEND_OP_0 mà Character.program của client
// 2026 khai cho chương trình pixel của template đó (ColorX2 là 1, ColorX4 là 2, họ
// ColourChangable là 3; Diffuse.inc và CalcLight.inc đọc số này).
// Chưa đọc: scene_blend, alpha_rejection, cull (bộ chuyển đã đưa vào trường chuẩn của glTF),
// texture thứ hai của họ TwoTex, tham số của các shader LSScene và PBR.
#pragma once

#include "math/types.hpp"

#include <cstdint>
#include <optional>
#include <string_view>

namespace game::classic {

// kOff: "lighting off". kVertex: tính ở đỉnh (Model_vs.hlsl). kPixel: "lighting on pslit".
// kTerrain: FairyTerrain, tính ở điểm ảnh và cộng đèn không kẹp từng đèn (shade đặt kRawSum).
enum class Lit : std::uint8_t { kOff, kVertex, kPixel, kTerrain };

// BLEND_OP_0 của shader gốc: texture nhân ánh sáng (kModulate), texture nhân 2 hoặc nhân 4 rồi
// nhân ánh sáng, hay texture cộng ánh sáng (kAdd, tóc đổi màu).
enum class TexOp : std::uint8_t { kModulate, kModulate2, kModulate4, kAdd };

struct Classic {
    math::Float3 ambient{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    math::Float4 diffuse{.x = 1.0F, .y = 1.0F, .z = 1.0F, .w = 1.0F};
    math::Float3 specular{};
    float shininess = 0.0F;
    math::Float3 emissive{};
    TexOp combine = TexOp::kModulate;
    Lit lit = Lit::kVertex;
    // Sai khi pass khai "fog_override true" không kèm kiểu sương: pass ấy không nhận sương.
    bool has_fog = true;
    // "ambient vertexcolour" hoặc "diffuse vertexcolour": màu đỉnh thay màu chất liệu.
    bool tracks_vertex = false;
};

// Chất liệu OGRE ghi trong JSON extras của một chất liệu glTF; không có khi extras không mang
// khoá "ogre" hoặc JSON hỏng.
[[nodiscard]] std::optional<Classic> read_classic(std::string_view extras);

} // namespace game::classic
