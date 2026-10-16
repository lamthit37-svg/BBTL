// Vertex shader của bầu trời, theo EnScene.hlsl của client 2026: En_sky_dome_v (vòm), En_cloudv (lớp
// mây), En_ringcloudv (mây vòng), En_sunandmoon_vp (trăng và mặt trời). Mỗi nhánh giữ đúng thứ tự phép
// tính của bản gốc, kể cả những chỗ lạ: normalize của vòm và mây lấy vectơ bốn chiều (w = 1), mây vòng
// chia clip cho |w| nên w không đổi và UV nội suy thẳng trong không gian màn hình.
#include "sky.inc.slang"

struct Vertex {
    float3 position : POSITION;
    float2 uv : TEXCOORD0;
};

// Độ sâu đảo của z = w * 0,999999 (bản gốc, độ sâu thường).
static const float kFarShare = 1.0 - 0.999999;

float3 spin(SkyDraw draw, float3 local) {
    return float3(dot(draw.world0.xyz, local), dot(draw.world1.xyz, local), dot(draw.world2.xyz, local));
}

Varying empty_varying() {
    Varying output;
    output.clip = float4(0.0, 0.0, 0.0, 1.0);
    output.uv0 = float2(0.0, 0.0);
    output.uv1 = float2(0.0, 0.0);
    output.normal = float3(0.0, 0.0, 0.0);
    return output;
}

Varying dome(Vertex vertex, SkyDraw draw) {
    Varying output = empty_varying();
    const float4 local = float4(vertex.position, 1.0);
    const float4 unit = normalize(local);
    output.uv0 = float2(draw.a.x, saturate(1.0 - unit.y));
    float4 raised = local;
    raised.y = raised.y + draw.a.y;
    float4 clip = mul(draw.mvp, raised);
    clip.z = clip.w * kFarShare;
    output.clip = clip;
    const float horizon_vertex = 1.0 - abs(unit.y);
    const float horizon_sun = 1.0 - abs(draw.sun.y);
    const float forward = saturate(dot(unit.xyz, draw.sun.xyz));
    const float mie_amount = pow(forward, draw.b.z);
    const float sun_effect = draw.sun.y * unit.y * draw.b.y;
    const float vertex_effect = horizon_vertex * horizon_sun * draw.b.x;
    const float extra = saturate(forward * (vertex_effect + sun_effect) + draw.a.w);
    const float mie = (mie_amount + extra) * draw.a.z;
    output.uv1 = float2(mie, mie);
    return output;
}

Varying cloud(Vertex vertex, SkyDraw draw) {
    Varying output = empty_varying();
    float4 shifted = float4(vertex.position, 1.0);
    shifted.y = shifted.y + draw.a.z;
    const float3 pointed = spin(draw, shifted.xyz);
    output.normal = normalize(float4(pointed, 1.0)).xyz;
    float4 clip = mul(draw.mvp, shifted);
    clip.z = clip.w * kFarShare;
    output.clip = clip;
    output.uv0 = float2(vertex.uv.x * draw.a.x, (vertex.uv.y * draw.a.y) + draw.b.x);
    output.uv1 = vertex.uv;
    return output;
}

Varying ring(Vertex vertex, SkyDraw draw) {
    Varying output = empty_varying();
    float4 lowered = float4(vertex.position, 1.0);
    lowered.y = lowered.y - (draw.b.y * draw.a.z * 0.000001);
    output.normal = normalize(spin(draw, lowered.xyz));
    float4 clip = mul(draw.mvp, lowered);
    clip.z = clip.w * kFarShare;
    output.clip = clip / abs(clip.w);
    const float across = vertex.uv.x * draw.a.x;
    output.uv0 = float2(across, vertex.uv.y + draw.a.y);
    output.uv1 = float2(across, vertex.uv.y);
    return output;
}

Varying body(Vertex vertex, SkyDraw draw) {
    Varying output = empty_varying();
    float4 clip = mul(draw.mvp, float4(vertex.position, 1.0));
    clip.z = 0.0;
    output.clip = clip;
    output.uv0 = vertex.uv;
    return output;
}

Varying main(Vertex vertex) {
    const SkyDraw draw = sky.draws[sky_push.slot.x];
    const uint kind = uint(draw.misc.x);
    if (kind == kSkyDome) return dome(vertex, draw);
    if (kind == kSkyCloud) return cloud(vertex, draw);
    if (kind == kSkyRing) return ring(vertex, draw);
    return body(vertex, draw);
}
