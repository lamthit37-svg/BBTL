// Màu hạt: saturate(ảnh * đỉnh). Gain đã nằm trong đỉnh. Alpha của mốc opacity có thể lớn hơn 1,
// nên kẹp sau phép nhân, đúng fmt_output của Particle_ps. Hệ số trộn nằm ở pipeline, không ở đây.
#include "fx.inc.slang"

#ifndef F2_DXBC
Texture2D<float4> fx_map : register(t0, space1);
Texture2D<float4> fx_cover : register(t1, space1);
SamplerState fx_sampler : register(s0, space1);
SamplerState fx_cover_sampler : register(s1, space1);
#else
Texture2D<float4> fx_map : register(t0);
Texture2D<float4> fx_cover : register(t1);
SamplerState fx_sampler : register(s0);
SamplerState fx_cover_sampler : register(s1);
#endif

float4 cover_colour(float4 texel, float4 vertex, float2 uv_cover) {
    const float4 cover = fx_cover.Sample(fx_cover_sampler, uv_cover);
    const float3 rgb = texel.rgb * vertex.rgb * cover.rgb * fx_push.mode.x;
    const float alpha = texel.a * vertex.a * cover.a;
    return float4(saturate(rgb), saturate(alpha));
}

float4 main(Varying input) : SV_Target0 {
    const float4 texel = fx_map.Sample(fx_sampler, input.uv);
    if (fx_push.mode.x > 0.0) return cover_colour(texel, input.color, input.uv_cover);
    const float3 rgb = saturate(texel.rgb * input.color.rgb);
    const float alpha = saturate(texel.a * input.color.a);
    return float4(rgb, alpha);
}
