// Pixel shader của sao: StarsPS của FixStar.hlsl. Cộng màu vào ảnh (scene_blend src_alpha one): kết
// quả nhân sẵn với độ trong rồi cộng một một, để phép cộng gần với bản gốc làm trong không gian gamma.
#include "star.inc.slang"

float4 main(StarVarying input) : SV_Target0 {
    const SkyDraw draw = sky.draws[sky_push.slot.x];
    const float star_intensity = draw.b.x;
    const float star_transparent = draw.b.y;
    // 3,5 là hệ số chỉnh của bản gốc: suy giảm mũ từ tâm sprite.
    const float2 from_centre = (3.5 * input.quad) - (3.5 * float2(0.5, 0.5));
    const float scale = exp(-dot(from_centre, from_centre));
    const float3 cool = input.colour.xyz;
    const float3 hot = float3(input.colour.w, input.colour.w, input.colour.w);
    const float3 mixed = (cool * scale) + (5.0 * hot * pow(scale, 10.0));
    const float3 final_colour = saturate(star_intensity * mixed);
    const float alpha = input.colour.w * star_transparent;
    return encode(draw, final_colour * alpha, alpha);
}
