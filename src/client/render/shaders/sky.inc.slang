// Bầu trời EnScene của Render.dll (MaterialTemplates/EnScene.hlsl): vòm, lớp mây, lớp mây vòng, trăng
// và mặt trời dùng chung một cặp shader, chọn nhánh theo misc.x của lệnh vẽ. Bố cục SkyDraw phải khớp
// SkyDrawBlock ở display/sky_view.cpp (16 float4, 256 byte); mọi lệnh vẽ của khung nằm trong một cbuffer
// và lệnh chọn ô bằng push constant, nên khung vẽ cả bầu trời chỉ ghi một buffer.
// Ma trận theo quy ước vectơ cột của math: mul(M, v). mvp đã gộp nút cảnh, ma trận nhìn bỏ tịnh tiến
// và phép chiếu: nút của bầu trời luôn đặt tại camera nên chỉ hướng nhìn là quan trọng.
// Độ sâu đảo (gpu): bản gốc đặt z = w * 0,999999 (sát mặt xa, vòm mây) hoặc z = w (trăng, mặt trời);
// với độ sâu đảo thì z = w * (1 - 0,999999) và z = 0.
#ifndef TL_RENDER_SKY_HLSLI
#define TL_RENDER_SKY_HLSLI

#include "f2/shader.inc.slang"

static const uint kSkyDraws = 32u;

// Giá trị của misc.x.
static const uint kSkyDome = 0u;
static const uint kSkyCloud = 1u;
static const uint kSkyRing = 2u;
static const uint kSkyBody = 3u;

struct SkyDraw {
    float4x4 mvp;
    // Ba hàng của R * S (xyz), dùng để tính hướng của đỉnh trong không gian thế giới.
    float4 world0;
    float4 world1;
    float4 world2;
    // Vòm: (giờ / 24, hight, mieAmount, TURBIDITY). Mây: textureTile. Mây vòng: (TextureRepeat, vOffset,
    // parallax, 1).
    float4 a;
    // Vòm: (vertexHeightEffect, sunHeightEffect, power, 0). Mây: x là windSpeed. Mây vòng: y là độ cao camera.
    float4 b;
    // xyz: hướng tới mặt trời (vòm: SUN_POSITION, mây: dLight); w: scatteringStrength.
    float4 sun;
    // xyz: màu đèn chính một (lcolor); w: scatteringPower.
    float4 light;
    // rimStrength, rimPower, rimDetectPower, rimDetectWidth.
    float4 rim;
    // xyz: màu sương của môi trường.
    float4 fog;
    // Mây: (fog, cloudspeed, ambientBlend, alpha). Mây vòng: (fogblend, fadeRange, ambientBlend, alpha).
    float4 control;
    // xyz: ambient của môi trường (vòm: skyDomeAmbientColor); w: skyDomeAmbientColorStrength.
    float4 ambient;
    // x: loại lệnh; y: trọng số ảnh rayleigh của vòm; z: 1 khi thiết bị màu thô (không đổi gamma).
    float4 misc;
};

struct SkyBlock {
    SkyDraw draws[kSkyDraws];
};
#ifndef F2_DXBC
ConstantBuffer<SkyBlock> sky : register(b0, space0);
#else
cbuffer SkyCB : register(b0) { SkyBlock sky; }
#endif

// Đường cong sRGB chính xác, chiều gamma sang tuyến tính.
float3 to_linear(float3 gamma_color) {
    const float3 value = saturate(gamma_color);
    const float3 low = value / 12.92;
    const float3 high = pow((value + 0.055) / 1.055, float3(2.4, 2.4, 2.4));
    return lerp(high, low, step(value, float3(0.04045, 0.04045, 0.04045)));
}

float4 encode(SkyDraw draw, float3 gamma_color, float alpha) {
    if (draw.misc.z > 0.5) return float4(gamma_color, alpha);
    return float4(to_linear(gamma_color), alpha);
}

struct SkyPush {
    // x: ô của lệnh vẽ trong SkyBlock.
    uint4 slot;
};
F2_PUSH_CONSTANTS(SkyPush, sky_push);

struct Varying {
    float4 clip : SV_Position;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 normal : TEXCOORD2;
};

#endif
