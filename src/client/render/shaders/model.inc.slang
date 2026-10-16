// Phần chung của vertex shader và pixel shader vẽ model: hằng của khung hình, hằng của lệnh vẽ, dữ
// liệu đi từ đỉnh sang điểm ảnh và công thức ánh sáng. Bố cục byte của Frame và Draw phải khớp
// FrameBlock và DrawBlock ở render/forward.cpp. Ma trận theo quy ước vectơ cột của math: mul(M, v).
// Công thức ánh sáng và sương port từ shader của client 2026 (MaterialTemplates): Model_vs.hlsl,
// Model_ps.hlsl, ShaderLib/CalcLight.inc, ShaderLib/Fog.inc và FairyTerrain.hlsl. Bản gốc tính
// thẳng trên số của texture và ghi ra đích không sRGB, tức là tính trong không gian gamma; ở đây
// texture và đích là sRGB nên màu được đổi về gamma trước khi tính và đổi lại trước khi ghi.
// Nguồn khung tệp: Forge2 src/render/shaders/model.inc.slang@d7fcd76. Khác gốc: F2_DXBC dùng cbuffer
// b0 vì fxc không có ConstantBuffer và không có register space; Frame và Draw mang ánh sáng của
// bản gốc thay một đèn Lambert.
#ifndef F2_RENDER_MODEL_HLSLI
#define F2_RENDER_MODEL_HLSLI

#include "f2/shader.inc.slang"

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

// Số đèn giả một khung mang theo (kFakeSlots ở forward.hpp).
static const uint kFakes = 24u;

// Đèn giả FakeLight (Model_FakePointLight_ps.hlsl).
struct FakeLight {
    // Ba hàng đổi vị trí thế giới (w = 1) sang toạ độ hộp đơn vị, đã nhân 0,01 như shader gốc.
    float4 row0;
    float4 row1;
    float4 row2;
    // rgb: diffuse nhân cường độ; w: size (lightParams.w).
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
    // y: giây, để cuộn UV của thác.
    float4 rules;
    Lamp lamps[kLamps];
    // HeightFog_ps: density, height, falloff, pow.
    float4 hfog;
    // density, falloff, start. w luôn 0, như FUN_1801c1440.
    float4 dfog;
    // rgb màu sương; a > 0 thì áp sương chiều cao.
    float4 hfog_color;
    // rgb màu tán xạ; w là InscatteringFactor.
    float4 hfog_scatter;
    // x: số đèn giả đang dùng trong fakes.
    float4 fake_count;
    FakeLight fakes[kFakes];
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
// Ảnh t1 nhân lên ảnh t0, đúng Particle_2Tex của hạt mesh.
static const uint kMaskTex = 512u;
// Chất liệu không trộn alpha: pixel shader trả alpha 1 sau phép cắt (forward.cpp đặt cờ).
static const uint kOpaqueAlpha = 1024u;

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

// Pha riêng của đèn giả, suy từ chỗ đặt (cột dịch của ma trận hộp) nên không đổi khi đèn đổi ô.
float fake_phase(FakeLight fake) {
    const float3 seed = float3(fake.row0.w, fake.row1.w, fake.row2.w);
    return frac(sin(dot(seed, float3(12.9898, 78.233, 37.719))) * 43758.5453) * 6.2831853;
}

// Lửa phơ phất. Khác gốc (2026-10-16, chủ dự án yêu cầu): hộp FakeLight của bản gốc đứng yên, ở đây vùng sáng
// lay ngang, gợn theo vị trí và kéo dài lên phía trên như ngọn lửa, cường độ chập chờn bằng ba sóng lệch tần.
// Đèn lớn (ánh trăng, scale trên 8) lay nhẹ hơn đèn nhỏ (lửa). Trả về toạ độ hộp đã uốn; flicker nhân vào cường độ.
float3 fake_flow(FakeLight fake, float3 box, float3 place, out float flicker) {
    const float time = frame.rules.y;
    const float phase = fake_phase(fake);
    const float scale = 0.01 / max(length(fake.row0.xyz), 1.0e-6);
    const float weight = 1.0 - (0.45 * saturate((scale - 8.0) / 14.0));
    const float beat = (0.18 * sin((time * 9.0) + phase)) + (0.12 * sin((time * 17.3) + (phase * 2.3)));
    const float gust = (0.08 * sin((time * 4.1) + (phase * 0.7))) + (0.06 * sin((time * 27.0) + (phase * 3.1)));
    flicker = 1.0 + (weight * (beat + gust));
    const float3 sway = float3(sin((time * 1.9) + phase), sin((time * 2.7) + (phase * 1.3)),
        sin((time * 2.2) + (phase * 0.7)));
    const float3 ripple = float3(sin(dot(place, float3(0.021, 0.027, 0.014)) + (time * 3.1) + phase),
        sin(dot(place, float3(-0.017, 0.019, 0.026)) + (time * 2.6) + (phase * 1.7)),
        sin(dot(place, float3(0.024, -0.015, 0.022)) - (time * 2.9) + (phase * 0.6)));
    float3 flow = box + (weight * ((0.09 * sway) + (0.045 * ripple)));
    // +y của thế giới trong toạ độ hộp: nửa trên của lửa vươn xa hơn, nửa dưới ngắn lại.
    const float3 raised = float3(fake.row0.y, fake.row1.y, fake.row2.y);
    const float3 up = raised / max(length(raised), 1.0e-6);
    const float lift = dot(flow, up);
    const float stretch = lift > 0.0 ? 0.55 : -0.25;
    return flow - (up * lift * stretch * weight);
}

// Hệ số nhân màu của mọi đèn giả tại một điểm: dst * (1 + src) của scene_blend dest_colour one (Mtl_FakePointLight),
// với src là công thức của Model_FakePointLight_ps.hlsl. Điểm ngoài hộp thì đèn bị bỏ (clip của bản gốc).
float3 fake_gain(float3 place) {
    float3 gain = float3(1.0, 1.0, 1.0);
    const uint count = min(uint(frame.fake_count.x), kFakes);
    const float4 point = float4(place, 1.0);
    for (uint index = 0u; index < count; ++index) {
        const FakeLight fake = frame.fakes[index];
        const float3 box = float3(dot(fake.row0, point), dot(fake.row1, point), dot(fake.row2, point));
        const float3 reach = abs(box);
        if (max(reach.x, max(reach.y, reach.z)) > 0.5) continue;
        float flicker = 1.0;
        const float3 flow = fake_flow(fake, box, place, flicker);
        float spread = saturate(fake.color.w - (length(flow.xy) * 3.0));
        spread *= saturate(fake.color.w - (length(flow.xz) * 3.0));
        spread *= saturate(fake.color.w - (length(flow.yz) * 3.0));
        gain *= 1.0 + (fake.color.rgb * (spread * flicker));
    }
    return gain;
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
