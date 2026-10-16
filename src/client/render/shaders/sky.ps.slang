// Pixel shader của bầu trời, theo EnScene.hlsl của client 2026: En_sky_dome_p (vòm), En_cloudp (lớp
// mây), En_ringcloudp (mây vòng), En_sunandmoon_fp (trăng và mặt trời). Ảnh được nạp thô, không giải
// mã sRGB, và mọi phép màu làm trong không gian gamma như bản gốc; đích vẽ là sRGB nên kết quả đổi về
// tuyến tính trước khi trả (thiết bị màu thô thì giữ nguyên, misc.z = 1).
#include "sky.inc.slang"

#ifndef F2_DXBC
Texture2D<float4> sky_map0 : register(t0, space1);
Texture2D<float4> sky_map1 : register(t1, space1);
Texture2D<float4> sky_map2 : register(t2, space1);
SamplerState sky_sampler0 : register(s0, space1);
SamplerState sky_sampler1 : register(s1, space1);
SamplerState sky_sampler2 : register(s2, space1);
#else
Texture2D<float4> sky_map0 : register(t0);
Texture2D<float4> sky_map1 : register(t1);
Texture2D<float4> sky_map2 : register(t2);
SamplerState sky_sampler0 : register(s0);
SamplerState sky_sampler1 : register(s1);
SamplerState sky_sampler2 : register(s2);
#endif

// En_sky_dome_p: ảnh rayleigh ở t1 (và t2 khi cảnh khai textureEx), gradient mie ở t0.
float4 dome(Varying input, SkyDraw draw) {
    const float4 ray = sky_map1.Sample(sky_sampler1, input.uv0);
    const float4 ray_ex = sky_map2.Sample(sky_sampler2, input.uv0);
    const float4 mie = sky_map0.Sample(sky_sampler0, input.uv1);
    const float weight = draw.misc.y;
    float3 colour = (ray.rgb * ray.a * weight) + (ray_ex.rgb * ray_ex.a * (1.0 - weight));
    colour = (mie.rgb * colour) + colour;
    colour = colour * (draw.ambient.xyz * draw.ambient.w);
    return encode(draw, colour, 1.0);
}

// cloudLighting của EnScene.hlsl, rồi trộn sương. map là ảnh mây (alpha là mật độ).
float3 cloud_colour(Varying input, SkyDraw draw, float4 map) {
    const float4 fog_map = sky_map1.Sample(sky_sampler1, input.uv1);
    const float3 fog_amount = saturate(fog_map + float4(draw.control.x, draw.control.x, draw.control.x, draw.control.x)).xyz;
    const float light = saturate(dot(normalize(draw.sun.xyz), input.normal));
    const float blend = draw.control.z;
    const float3 diffuse = (map.rgb * draw.ambient.xyz * blend) + (map.rgb * (1.0 - blend));
    const float scattering = pow(light, draw.light.w + 0.00001);
    const float rim_detect = pow(1.0 - saturate(map.a - draw.rim.w), draw.rim.z + 0.00001);
    const float rim_scattering = pow(light, draw.rim.y + 0.00001);
    const float lit_rim = rim_detect * rim_scattering;
    float3 colour = diffuse + (draw.light.xyz * scattering * draw.sun.w) + (draw.light.xyz * lit_rim * draw.rim.x);
    colour = lerp(colour, draw.fog.xyz, fog_amount);
    return colour;
}

float4 cloud(Varying input, SkyDraw draw) {
    const float4 map = sky_map0.Sample(sky_sampler0, input.uv0);
    const float3 colour = cloud_colour(input, draw, map);
    return encode(draw, colour, map.a * draw.control.w);
}

float4 ring(Varying input, SkyDraw draw) {
    const float4 map = sky_map0.Sample(sky_sampler0, input.uv0);
    const float3 colour = cloud_colour(input, draw, map);
    const float edge = (-2.0 * abs(input.uv1.y - 0.5)) + 1.0;
    const float fade = min(edge / (draw.control.y + 0.00001), 1.0);
    return encode(draw, colour, map.a * fade * draw.control.w);
}

// En_sunandmoon_fp: màu ảnh, không thắp sáng.
float4 body(Varying input, SkyDraw draw) {
    const float4 map = sky_map0.Sample(sky_sampler0, input.uv0);
    return encode(draw, map.rgb, map.a);
}

float4 main(Varying input) : SV_Target0 {
    const SkyDraw draw = sky.draws[sky_push.slot.x];
    const uint kind = uint(draw.misc.x);
    if (kind == kSkyDome) return dome(input, draw);
    if (kind == kSkyCloud) return cloud(input, draw);
    if (kind == kSkyRing) return ring(input, draw);
    return body(input, draw);
}
