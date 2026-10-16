// Vertex shader của sao: StarsVS của FixStar.hlsl. Mỗi sao là bốn đỉnh cùng vị trí và màu, khác góc.
#include "star.inc.slang"

struct StarVertex {
    float3 position : POSITION;
    float2 corner : TEXCOORD0;
    // (r, g, b, độ sáng ngẫu nhiên): ColAndMag của bản gốc.
    float4 colour : COLOR0;
};

// Bảng nhấp nháy của GetFlickerAmount: (giá trị, độ dốc) theo tám đoạn.
static const float2 kFlicker[8] = {
    float2(0.897907815, -0.347608525), float2(0.550299290, 0.273586675),
    float2(0.823885965, 0.098853070), float2(0.922739035, -0.122108860),
    float2(0.800630175, -0.088956800), float2(0.711673375, 0.158864420),
    float2(0.870537795, 0.085484560), float2(0.956022355, -0.058114540)};

float flicker_amount(float3 position, float phase) {
    const float2 hash = frac(position.xy * 256.0);
    float index = frac(hash.x + ((hash.y + 1.0) * phase));
    index = index * 8.0;
    const float part = frac(index);
    const int slot = min(int(index), 7);
    return kFlicker[slot].x + (part * kFlicker[slot].y);
}

StarVarying main(StarVertex vertex) {
    const SkyDraw draw = sky.draws[sky_push.slot.x];
    StarVarying output;
    const float4 centre = mul(draw.mvp, float4(vertex.position, 1.0));
    const float magnitude = 6.5 + (vertex.colour.w * (-1.44 - 6.5));
    const float amount = flicker_amount(vertex.position, draw.a.w);
    const float brightness = amount * pow(5.0, (-magnitude - 1.44) / 2.5);
    output.colour = float4(brightness * vertex.colour.xyz, brightness);
    output.quad = vertex.corner;
    // Bản gốc đặt z = w (mặt xa). Độ sâu đảo: mặt xa là z = 0. Tâm sau lưng camera thì đẩy ra ngoài
    // khối nhìn: cả bốn đỉnh trùng nhau nên hình chữ nhật suy biến và bị loại.
    const float2 pixel = (float2(vertex.corner.x, 1.0 - vertex.corner.y) - 0.5) * draw.a.xy;
    const float2 offset = pixel * 2.0 / max(draw.b.zw, float2(1.0, 1.0));
    float4 clip = float4(centre.xy + (offset * centre.w), 0.0, centre.w);
    if (centre.w <= 0.0) clip = float4(0.0, 0.0, 2.0, 1.0);
    output.clip = clip;
    return output;
}
