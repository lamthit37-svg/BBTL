// Pixel shader của model, theo Model_ps.hlsl của client 2026: màu texture nhân hệ số của chất liệu,
// cắt theo alpha, ghép với ánh sáng khuếch tán (nhân, hoặc cộng với chất liệu đổi màu), cộng
// specular Blinn của đèn chính một, rồi trộn sương theo độ sâu trong không gian camera. Chất liệu
// có FlowBlock thêm luồng sáng và viền sáng của Model_Flow_ps.hlsl (Calc_Flow, fmt_output).
// Mọi phép tính trên màu làm trong không gian gamma như bản gốc; đích vẽ là sRGB nên kết quả đổi
// về tuyến tính trước khi trả.
// Nguồn khung tệp: Forge2 src/render/shaders/model.ps.slang@d7fcd76. Khác gốc: F2_DXBC bỏ register
// space (ảnh và sampler vẫn là t0 và s0, mặt nạ là t1 và s1, đúng resource_register của space 1);
// công thức màu là của bản gốc thay một đèn Lambert.
#include "model_ps.inc.slang"

// Ảnh ctl, ảnh luồng (_Reflection) và ảnh viền là số thô (không giải mã sRGB) như bản gốc.
#ifndef F2_DXBC
Texture2D<float4> base_map : register(t0, space1);
Texture2D<float4> mask_map : register(t1, space1);
Texture2D<float4> ctl_map : register(t2, space1);
Texture2D<float4> flow_map : register(t3, space1);
Texture2D<float4> outline_map : register(t4, space1);
SamplerState base_sampler : register(s0, space1);
SamplerState mask_sampler : register(s1, space1);
SamplerState ctl_sampler : register(s2, space1);
SamplerState flow_sampler : register(s3, space1);
SamplerState outline_sampler : register(s4, space1);
#else
Texture2D<float4> base_map : register(t0);
Texture2D<float4> mask_map : register(t1);
Texture2D<float4> ctl_map : register(t2);
Texture2D<float4> flow_map : register(t3);
Texture2D<float4> outline_map : register(t4);
SamplerState base_sampler : register(s0);
SamplerState mask_sampler : register(s1);
SamplerState ctl_sampler : register(s2);
SamplerState flow_sampler : register(s3);
SamplerState outline_sampler : register(s4);
#endif

// Hệ số luồng (params.cCtlTex.r): FLOW_TEX_TYPE 0 lấy từ alpha ảnh nền, còn lại từ kênh r của ctl.
float flow_mask(float4 texel, float2 uv) {
    if ((flow_block.mode.x & kFlowAlpha) != 0u) return (texel.a * 255.0 - 5.0) / 255.0;
    return ctl_map.Sample(ctl_sampler, uv).r;
}

// Calc_Flow: ảnh luồng theo pháp tuyến đối tượng (hay UV), trôi theo time_0_x chu kỳ 100 giây.
float3 flow_light(float4 texel, Varying input) {
    const uint mode = flow_block.mode.x;
    if ((mode & kFlowOn) == 0u) return float3(0.0, 0.0, 0.0);
    const float3 slope = input.object_normal;
    const float2 by_normal = (slope * rsqrt(max(dot(slope, slope), 1.0e-12))).xy;
    const float2 base = (mode & kFlowByUv) != 0u ? input.uv : by_normal;
    const float seconds = fmod(frame.rules.y, 100.0);
    const float2 drift = seconds * flow_block.factor.zw * 0.1;
    const float2 uv = base * flow_block.factor.xy + drift;
    const float3 shine = flow_map.Sample(flow_sampler, uv).rgb;
    return shine * flow_mask(texel, input.uv);
}

// Màu viền nhân ảnh điều khiển viền (USE_OUTLINE_CTRL_TEX) khi chất liệu có ảnh ấy.
float3 rim_tint(Varying input) {
    const float3 tint = flow_block.outline_color.rgb;
    if ((flow_block.mode.x & kRimMap) == 0u) return tint;
    const float4 control = outline_map.Sample(outline_sampler, input.uv);
    return tint * control.rgb * control.a;
}

// fmt_output của Model_Flow_ps.hlsl: cộng viền theo |N·V| sau sương, alpha cũng cộng rồi kẹp.
// Khác gốc: cơ số 1 − |N·V| kẹp về [0, 1]; gốc để pow nhận cơ số âm khi pháp tuyến nội suy dài hơn
// 1 và ra NaN (fxc X3571, docs/NGHI-NGO.md mục 64f).
float4 rim_light(float3 color, float alpha, Varying input) {
    if ((flow_block.mode.x & kRimOn) == 0u) return float4(color, alpha);
    const float3 normal = pixel_normal(input);
    const float3 toward = frame.eye.xyz - input.place;
    const float3 view = toward * rsqrt(max(dot(toward, toward), 1.0e-12));
    const float facing = abs(dot(normal, view));
    const float2 power = flow_block.outline_pow.xy;
    const float exponent = power.x * pow(facing, power.y);
    const float strength = flow_block.outline_color.a * pow(saturate(1.0 - facing), exponent);
    const float3 rim = strength * rim_tint(input);
    return float4(color + rim, saturate(alpha + strength * alpha));
}

float4 main(Varying input) : SV_Target0 {
    const float4 texel = base_map.Sample(base_sampler, input.uv);
    // Particle_2Tex: tex2 nhân rgb và alpha. Cả hai mẫu dùng UV đã cuộn ở vertex shader.
    // rgb nhân trong gamma như các phép màu khác của shader này. Cờ tắt thì mặt nạ là 1.
    float3 mask_rgb = float3(1.0, 1.0, 1.0);
    float mask_alpha = 1.0;
    const bool has_mask = (draw.flags & kMaskTex) != 0u;
    if (has_mask) {
        const float4 mask = mask_map.Sample(mask_sampler, input.uv);
        mask_rgb = to_gamma(mask.rgb);
        mask_alpha = mask.a;
    }
    const bool has_tint = (draw.flags & kVertexColor) != 0u;
    const float4 tint = has_tint ? input.color : float4(1.0, 1.0, 1.0, 1.0);
    const float alpha = texel.a * mask_alpha * draw.base_color.a * tint.a;
#ifndef TL_SOLID
    if (alpha < draw.diffuse.a) {
        discard;
    }
#endif
    float3 color = to_gamma(texel.rgb) * mask_rgb * draw.base_color.rgb * tint.rgb;
    // ColorX2 và ColorX4 kẹp sau khi nhân hệ số. Chất liệu không mặt nạ giữ nguyên, không kẹp thêm.
    if (has_mask) color = saturate(color);
    // Thứ tự của Model_Flow_ps.hlsl: ánh sáng, luồng, sương, rồi viền trong fmt_output.
    const float3 lit = light_pixel(color, input) + flow_light(texel, input);
    const float3 fogged = fog_pixel(lit, input);
    const float4 rimmed = rim_light(fogged, alpha, input);
    return post_pixel(rimmed.rgb, rimmed.a, input);
}
