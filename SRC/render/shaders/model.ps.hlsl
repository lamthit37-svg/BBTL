// Pixel shader của model, theo Model_ps.hlsl của client 2026: màu texture nhân hệ số của chất liệu,
// cắt theo alpha, ghép với ánh sáng khuếch tán (nhân, hoặc cộng với chất liệu đổi màu), cộng
// specular Blinn của đèn chính một, rồi trộn sương theo độ sâu trong không gian camera.
// Mọi phép tính trên màu làm trong không gian gamma như bản gốc; đích vẽ là sRGB nên kết quả đổi
// về tuyến tính trước khi trả.
// Nguồn khung tệp: Forge2 src/render/shaders/model.ps.hlsl@d7fcd76. Khác gốc: F2_DXBC bỏ register
// space (ảnh và sampler vẫn là t0 và s0, đúng resource_register của space 1); công thức màu là của
// bản gốc thay một đèn Lambert.
#include "model.hlsli"

#ifndef F2_DXBC
Texture2D<float4> base_map : register(t0, space1);
SamplerState base_sampler : register(s0, space1);
#else
Texture2D<float4> base_map : register(t0);
SamplerState base_sampler : register(s0);
#endif

// Đường cong sRGB chính xác, hai chiều.
float3 to_gamma(float3 linear_color) {
    const float3 value = max(linear_color, float3(0.0, 0.0, 0.0));
    const float3 low = value * 12.92;
    const float3 high = (1.055 * pow(value, float3(1.0, 1.0, 1.0) / 2.4)) - 0.055;
    return lerp(high, low, step(value, float3(0.0031308, 0.0031308, 0.0031308)));
}

float3 to_linear(float3 gamma_color) {
    const float3 value = saturate(gamma_color);
    const float3 low = value / 12.92;
    const float3 high = pow((value + 0.055) / 1.055, float3(2.4, 2.4, 2.4));
    return lerp(high, low, step(value, float3(0.04045, 0.04045, 0.04045)));
}

// Phần màu còn lại sau sương (1 là không sương), như Fogging của ShaderLib/Fog.inc. Bản gốc cộng
// cả bốn số hạng nhân với fog_kind; ở đây chỉ tính số hạng của kiểu đang bật (kết quả như nhau vì
// đúng một ô của fog_kind bằng 1) để máy yếu không trả giá hai hàm exp cho sương thẳng.
float fog_share(float depth) {
    const float thick = depth * frame.fog_range.x;
    if (frame.fog_kind.w > 0.5) return saturate((frame.fog_range.z - depth) * frame.fog_range.w);
    if (frame.fog_kind.y > 0.5) return exp(-thick);
    if (frame.fog_kind.z > 0.5) return exp(-(thick * thick));
    return 1.0;
}

// Specular Blinn của đèn chính một (Calc_Specular_Std): không nhân theo hướng mặt, cơ số kẹp 0,01.
float3 gloss(float3 normal, float3 place) {
    const float3 toward_eye = normalize(frame.eye.xyz - place);
    const float3 half_way = normalize(toward_eye + frame.sun_toward[0].xyz);
    return pow(max(dot(normal, half_way), 0.01), draw.glow.a) * draw.specular.rgb;
}

float4 main(Varying input) : SV_Target0 {
    const float4 texel = base_map.Sample(base_sampler, input.uv);
    const bool has_tint = (draw.flags & kVertexColor) != 0u;
    const float4 tint = has_tint ? input.color : float4(1.0, 1.0, 1.0, 1.0);
    const float alpha = texel.a * draw.base_color.a * tint.a;
    if (alpha < draw.diffuse.a) {
        discard;
    }
    float3 color = to_gamma(texel.rgb) * draw.base_color.rgb * tint.rgb;
    if ((draw.flags & kUnlit) == 0u) {
        // Như bản gốc, mặt sau của chất liệu hai mặt dùng nguyên pháp tuyến của mặt trước.
        const float3 slope = input.normal;
        const float3 normal = slope * rsqrt(max(dot(slope, slope), 1.0e-12));
        const bool is_lit_here = (draw.flags & kPixelLit) != 0u;
        const float3 light = is_lit_here ? diffuse_light(normal, input.place, input.lamp) : input.light;
        const bool is_added = (draw.flags & kAddLight) != 0u;
        color = is_added ? color + light : color * light;
        if ((draw.flags & kSpecular) != 0u) color += gloss(normal, input.place);
    }
    if ((draw.flags & kNoFog) == 0u) {
        const float depth = dot(frame.depth_row, float4(input.place, 1.0));
        color = lerp(frame.fog_color.rgb, color, fog_share(depth));
    }
    return float4(to_linear(color), alpha);
}
