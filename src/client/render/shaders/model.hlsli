// Phần chung của vertex shader và pixel shader vẽ model: hằng của khung hình, hằng của lệnh vẽ, dữ
// liệu đi từ đỉnh sang điểm ảnh và công thức ánh sáng. Bố cục byte của Frame và Draw phải khớp
// FrameBlock và DrawBlock ở render/forward.cpp. Ma trận theo quy ước vectơ cột của math: mul(M, v).
// Công thức ánh sáng và sương port từ shader của client 2026 (MaterialTemplates): Model_vs.hlsl,
// Model_ps.hlsl, ShaderLib/CalcLight.inc, ShaderLib/Fog.inc và FairyTerrain.hlsl. Bản gốc tính
// thẳng trên số của texture và ghi ra đích không sRGB, tức là tính trong không gian gamma; ở đây
// texture và đích là sRGB nên màu được đổi về gamma trước khi tính và đổi lại trước khi ghi.
// Nguồn khung tệp: Forge2 src/render/shaders/model.hlsli@d7fcd76. Khác gốc: F2_DXBC dùng cbuffer
// b0 vì fxc không có ConstantBuffer và không có register space; Frame và Draw mang ánh sáng của
// bản gốc thay một đèn Lambert.
#ifndef F2_RENDER_MODEL_HLSLI
#define F2_RENDER_MODEL_HLSLI

#include "f2/shader.hlsli"

// Số ô đèn điểm một khung mang theo. Ô cuối là đèn tắt: lệnh vẽ không có đèn điểm trỏ vào đó, nên
// Draw::lamp luôn là chỉ số hợp lệ (đọc mảng ngoài biên làm PowerVR huỷ cả khung).
static const uint kLamps = 32u;
static const uint kDarkLamp = kLamps - 1u;

struct Lamp {
    // xyz: vị trí trong thế giới; w: tầm.
    float4 place;
    // rgb: màu đã nhân cường độ; a: số mũ suy giảm.
    float4 color;
};

struct Frame {
    float4x4 view_proj;
    // Tích vô hướng với (vị trí thế giới, 1) cho độ sâu trong không gian camera.
    float4 depth_row;
    // xyz: mắt camera trong thế giới.
    float4 eye;
    // xyz: hướng TỚI hai đèn chính, đã chuẩn hoá.
    float4 sun_toward[2];
    // rgb đã nhân cường độ: [0], [1] cho vật thể của cảnh; [2], [3] cho nhân vật.
    float4 sun_color[4];
    // Đúng một ô bằng 1: không sương, exp, exp2, thẳng (fog_type của bản gốc).
    float4 fog_kind;
    // Mật độ, đầu, cuối, 1 / (cuối - đầu).
    float4 fog_range;
    float4 fog_color;
    // x: 1 khi ánh sáng được phép vượt 1 (ColorGreaterOne của bản gốc), 0 thì kẹp.
    float4 rules;
    Lamp lamps[kLamps];
};
#ifndef F2_DXBC
ConstantBuffer<Frame> frame : register(b0, space0);
#else
cbuffer FrameCB : register(b0) { Frame frame; }
#endif

struct Draw {
    // Ba hàng đầu của ma trận thế giới (hàng cuối luôn là 0, 0, 0, 1).
    float4 world0;
    float4 world1;
    float4 world2;
    // rgb: hệ số nhân màu texture (màu nền và hệ số 2, 4 của chất liệu); a: hệ số alpha.
    float4 base_color;
    // rgb: ambient của cảnh nhân ambient chất liệu, cộng emissive; a: shininess.
    float4 glow;
    // rgb: diffuse của chất liệu; a: điểm ảnh có alpha dưới ngưỡng này bị bỏ, 0 là không cắt.
    float4 diffuse;
    // rgb: specular của chất liệu nhân specular của đèn chính một.
    float4 specular;
    // Khớp đầu tiên của skin trong bảng khớp, và số khớp của skin; 0 khớp là lưới không skin.
    uint joint_base;
    uint joint_count;
    uint flags;
    // Chỉ số đèn điểm trong Frame::lamps; kDarkLamp khi không có. Lệnh kInstanced không dùng ô
    // này: mỗi bản sao mang chỉ số đèn của riêng nó trong buffer worlds.
    uint lamp;
};
F2_PUSH_CONSTANTS(Draw, draw);

// Bit của Draw::flags. kInstanced: joint_count bằng 0 và joint_base là chỉ số ma trận đầu trong
// buffer worlds (model.vs), cộng SV_InstanceID; ô hàng cuối, cột đầu của ma trận ấy là chỉ số đèn
// điểm của bản sao (forward.cpp append_copies). Không bật cùng lúc với skin.
static const uint kUnlit = 1u;
static const uint kInstanced = 2u;
// Nhân vật: nhận màu đèn riêng của nhân vật thay màu đèn của cảnh.
static const uint kActor = 4u;
// Ánh sáng tính ở từng điểm ảnh thay vì ở đỉnh.
static const uint kPixelLit = 8u;
static const uint kNoFog = 16u;
// Địa hình (FairyTerrain.hlsl): không kẹp từng đèn, chỉ kẹp tổng.
static const uint kRawSum = 32u;
static const uint kSpecular = 64u;
// Texture cộng ánh sáng thay vì nhân (BLEND_OP_0 = 3 của bản gốc).
static const uint kAddLight = 128u;
static const uint kVertexColor = 256u;

struct Varying {
    float4 clip : SV_Position;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
    float3 place : TEXCOORD1;
    float3 light : TEXCOORD2;
    // Chỉ số đèn điểm của vật thể (Draw::lamp, hoặc của bản sao instanced); cả tam giác một số.
    nointerpolation uint lamp : TEXCOORD3;
};

// Đèn điểm thứ which của khung: suy giảm (1 - d / tầm) mũ số mũ, như CalcLight.inc của bản gốc.
float3 lamp_light(float3 normal, float3 place, uint which) {
    const uint index = min(which, kDarkLamp);
    if (index == kDarkLamp) return float3(0.0, 0.0, 0.0);
    const Lamp lamp = frame.lamps[index];
    const float3 reach = lamp.place.xyz - place;
    const float span = max(length(reach), 0.0001);
    const float fade = pow(saturate(1.0 - (span / lamp.place.w)), lamp.color.a);
    return fade * max(dot(normal, reach / span), 0.0) * lamp.color.rgb;
}

// Ánh sáng khuếch tán của một điểm: hai đèn chính, đèn điểm thứ which, ánh sáng nền. Model tính ở
// đỉnh kẹp từng đèn; model tính ở điểm ảnh không kẹp đèn chính một; địa hình không kẹp đèn nào.
float3 diffuse_light(float3 normal, float3 place, uint which) {
    const uint first = (draw.flags & kActor) != 0u ? 2u : 0u;
    const float facing_one = max(dot(normal, frame.sun_toward[0].xyz), 0.0);
    const float facing_two = max(dot(normal, frame.sun_toward[1].xyz), 0.0);
    float3 one = facing_one * frame.sun_color[first].rgb;
    float3 two = facing_two * frame.sun_color[first + 1u].rgb;
    float3 three = lamp_light(normal, place, which);
    const bool is_raw = (draw.flags & kRawSum) != 0u;
    const bool is_first_raw = is_raw || (draw.flags & kPixelLit) != 0u;
    if (!is_first_raw) one = saturate(one);
    if (!is_raw) two = saturate(two);
    if (!is_raw) three = saturate(three);
    const float3 lit = ((one + two + three) * draw.diffuse.rgb) + draw.glow.rgb;
    return lerp(saturate(lit), lit, frame.rules.x);
}

#endif
