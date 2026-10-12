// Cộng sáng: rgb đã nhân alpha ở đây, blend One + One ở pipeline. Đen không thêm gì.
#include "fx.hlsli"

#ifndef F2_DXBC
Texture2D<float4> fx_map : register(t0, space1);
SamplerState fx_sampler : register(s0, space1);
#else
Texture2D<float4> fx_map : register(t0);
SamplerState fx_sampler : register(s0);
#endif

float4 main(Varying input) : SV_Target0 {
    const float4 texel = fx_map.Sample(fx_sampler, input.uv);
    const float3 straight = texel.rgb * input.color.rgb;
    const float coverage = texel.a * input.color.a;
    // Cộng sáng giữ công thức cũ: rgb đã nhân alpha, alpha ra 1, blend One + One bỏ alpha.
    if (fx_push.mode.x < 0.5) return float4(straight * coverage, 1.0);
    return float4(straight, coverage);
}
