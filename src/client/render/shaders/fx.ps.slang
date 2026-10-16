// Màu hạt: saturate(ảnh * đỉnh). Gain đã nằm trong đỉnh. Alpha của mốc opacity có thể lớn hơn 1,
// nên kẹp sau phép nhân, đúng fmt_output của Particle_ps. Hệ số trộn nằm ở pipeline, không ở đây.
#include "fx.inc.slang"

#ifndef F2_DXBC
Texture2D<float4> fx_map : register(t0, space1);
SamplerState fx_sampler : register(s0, space1);
#else
Texture2D<float4> fx_map : register(t0);
SamplerState fx_sampler : register(s0);
#endif

float4 main(Varying input) : SV_Target0 {
    const float4 texel = fx_map.Sample(fx_sampler, input.uv);
    const float3 rgb = saturate(texel.rgb * input.color.rgb);
    const float alpha = saturate(texel.a * input.color.a);
    return float4(rgb, alpha);
}
