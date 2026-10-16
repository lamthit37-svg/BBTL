// Cộng sáng: rgb đã nhân alpha ở đây, blend One + One ở pipeline. Đen không thêm gì.
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
    // mode.y: 0 giữ ảnh; 1 bỏ alpha của ảnh ("one one" không cho alpha tham gia); 2 khói, đen với alpha là độ sáng của
    // ảnh. Ảnh nén của điện thoại không sửa được ở CPU nên shader tự làm.
    const bool is_smoke = fx_push.mode.y > 1.5;
    const bool is_opaque = fx_push.mode.y > 0.5 && !is_smoke;
    const float lightness = max(texel.r, max(texel.g, texel.b));
    const float image_alpha = is_smoke ? lightness : (is_opaque ? 1.0 : texel.a);
    const float3 image_colour = is_smoke ? float3(0.0, 0.0, 0.0) : texel.rgb;
    const float3 straight = image_colour * input.color.rgb;
    const float coverage = image_alpha * input.color.a;
    // Cộng sáng giữ công thức cũ: rgb đã nhân alpha, alpha ra 1, blend One + One bỏ alpha.
    if (fx_push.mode.x < 0.5) return float4(straight * coverage, 1.0);
    return float4(straight, coverage);
}
