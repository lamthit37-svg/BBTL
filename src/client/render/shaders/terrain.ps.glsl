// Cùng công thức với terrain.ps.slang (mặt đất lớp cọ); xem chú thích đầu tệp ấy về hai ảnh và toạ độ ghép sẵn
// ở đỉnh. Texture unit theo map_bindings: t0 atlas = 0, t2 lightmap = 2; sampler s0 dùng unit 0, s2 dùng unit 2.
precision highp sampler2D;

struct FakeLight {
    vec4 row0;
    vec4 row1;
    vec4 row2;
    vec4 color;
};

struct Lamp {
    vec4 place;
    vec4 color;
};

layout(std140, binding = 0) uniform FrameBlock {
    mat4 view_proj;
    vec4 depth_row;
    vec4 eye;
    vec4 sun_toward[2];
    vec4 sun_color[4];
    vec4 fog_kind;
    vec4 fog_range;
    vec4 fog_color;
    vec4 rules;
    Lamp lamps[32];
    vec4 hfog;
    vec4 dfog;
    vec4 hfog_color;
    vec4 hfog_scatter;
    vec4 fake_count;
    FakeLight fakes[24];
} frame;

// Khối hằng đẩy của từng lệnh vẽ, cùng bố cục 128 byte với Draw của model.inc.slang (xem model.vs.glsl).
uniform highp uvec4 tl_push[8];

layout(binding = 0) uniform sampler2D atlas;
layout(binding = 2) uniform sampler2D light_map;

layout(location = 0) in vec3 varying_normal;
layout(location = 1) in vec2 varying_uv;
layout(location = 2) in vec4 varying_color;
layout(location = 3) in vec3 varying_place;
layout(location = 4) in vec3 varying_light;
layout(location = 5) flat in highp uint varying_lamp;
// Sương gộp từ đỉnh (xem fog_terms của model.vs.glsl): màu_cuối = màu * w + rgb.
layout(location = 6) in vec4 varying_fog;

layout(location = 0) out vec4 out_color;

vec3 lamp_light(vec3 facing, vec3 place, uint which) {
    // Ô 31 là đèn tắt; kẹp để không bao giờ đọc mảng ngoài biên.
    uint index = min(which, 31u);
    if (index == 31u) return vec3(0.0);
    vec3 reach = frame.lamps[index].place.xyz - place;
    float span = max(length(reach), 0.0001);
    float inside = clamp(1.0 - (span / frame.lamps[index].place.w), 0.0, 1.0);
    float fade = pow(inside, frame.lamps[index].color.a);
    return fade * max(dot(facing, reach / span), 0.0) * frame.lamps[index].color.rgb;
}

vec3 diffuse_light(vec3 facing, vec3 place, uint which) {
    uint flags = tl_push[7].z;
    uint first = (flags & 4u) != 0u ? 2u : 0u;
    vec3 one = max(dot(facing, frame.sun_toward[0].xyz), 0.0) * frame.sun_color[first].rgb;
    vec3 two = max(dot(facing, frame.sun_toward[1].xyz), 0.0) * frame.sun_color[first + 1u].rgb;
    vec3 three = lamp_light(facing, place, which);
    bool is_raw = (flags & 32u) != 0u;
    bool is_first_raw = is_raw || (flags & 8u) != 0u;
    if (!is_first_raw) one = clamp(one, 0.0, 1.0);
    if (!is_raw) two = clamp(two, 0.0, 1.0);
    if (!is_raw) three = clamp(three, 0.0, 1.0);
    vec3 lit = ((one + two + three) * uintBitsToFloat(tl_push[5]).rgb) + uintBitsToFloat(tl_push[4]).rgb;
    return mix(clamp(lit, 0.0, 1.0), lit, frame.rules.x);
}

// Pha riêng, lửa phơ phất và chập chờn: xem fake_flow của model.inc.slang.
float fake_phase(FakeLight fake) {
    vec3 seed = vec3(fake.row0.w, fake.row1.w, fake.row2.w);
    return fract(sin(dot(seed, vec3(12.9898, 78.233, 37.719))) * 43758.5453) * 6.2831853;
}

vec3 fake_flow(FakeLight fake, vec3 box, vec3 place, out float flicker) {
    float time = frame.rules.y;
    float phase = fake_phase(fake);
    float scale = 0.01 / max(length(fake.row0.xyz), 1.0e-6);
    float weight = 1.0 - (0.45 * clamp((scale - 8.0) / 14.0, 0.0, 1.0));
    float beat = (0.18 * sin((time * 9.0) + phase)) + (0.12 * sin((time * 17.3) + (phase * 2.3)));
    float gust = (0.08 * sin((time * 4.1) + (phase * 0.7))) + (0.06 * sin((time * 27.0) + (phase * 3.1)));
    flicker = 1.0 + (weight * (beat + gust));
    vec3 sway = vec3(sin((time * 1.9) + phase), sin((time * 2.7) + (phase * 1.3)),
        sin((time * 2.2) + (phase * 0.7)));
    vec3 ripple = vec3(sin(dot(place, vec3(0.021, 0.027, 0.014)) + (time * 3.1) + phase),
        sin(dot(place, vec3(-0.017, 0.019, 0.026)) + (time * 2.6) + (phase * 1.7)),
        sin(dot(place, vec3(0.024, -0.015, 0.022)) - (time * 2.9) + (phase * 0.6)));
    vec3 flow = box + (weight * ((0.09 * sway) + (0.045 * ripple)));
    vec3 raised = vec3(fake.row0.y, fake.row1.y, fake.row2.y);
    vec3 up = raised / max(length(raised), 1.0e-6);
    float lift = dot(flow, up);
    float stretch = lift > 0.0 ? 0.55 : -0.25;
    return flow - (up * lift * stretch * weight);
}

// Hệ số nhân màu của mọi đèn giả (xem fake_gain của model.inc.slang).
vec3 fake_gain(vec3 place) {
    vec3 gain = vec3(1.0);
    uint count = min(uint(frame.fake_count.x), 24u);
    vec4 point = vec4(place, 1.0);
    for (uint index = 0u; index < count; ++index) {
        vec3 box = vec3(dot(frame.fakes[index].row0, point), dot(frame.fakes[index].row1, point),
            dot(frame.fakes[index].row2, point));
        vec3 reach = abs(box);
        if (max(reach.x, max(reach.y, reach.z)) > 0.5) continue;
        float size = frame.fakes[index].color.w;
        float flicker = 1.0;
        vec3 flow = fake_flow(frame.fakes[index], box, place, flicker);
        float spread = clamp(size - (length(flow.xy) * 3.0), 0.0, 1.0);
        spread *= clamp(size - (length(flow.xz) * 3.0), 0.0, 1.0);
        spread *= clamp(size - (length(flow.yz) * 3.0), 0.0, 1.0);
        gain *= 1.0 + (frame.fakes[index].color.rgb * (spread * flicker));
    }
    return gain;
}

vec3 gloss(vec3 facing, vec3 place) {
    vec3 toward_eye = normalize(frame.eye.xyz - place);
    vec3 half_way = normalize(toward_eye + frame.sun_toward[0].xyz);
    float shininess = uintBitsToFloat(tl_push[4].w);
    return pow(max(dot(facing, half_way), 0.01), shininess) * uintBitsToFloat(tl_push[6]).rgb;
}

void main() {
    uint flags = tl_push[7].z;
    // Đạo hàm lấy trước nhánh: cả cụm 2 x 2 thuộc một tam giác nên điều kiện của nhánh phủ giống nhau trong cụm.
    vec2 cover_dx = dFdx(varying_color.xy);
    vec2 cover_dy = dFdy(varying_color.xy);
    // Không discard (xem terrain.ps.slang): lỗ địa hình không có đỉnh nào.
    vec4 under = texture(atlas, varying_uv);
    vec3 color = (under.a > 0.0) ? (under.rgb / under.a) : vec3(0.0);
    if (varying_color.x >= 0.0) {
        vec4 over = textureGrad(atlas, varying_color.xy, cover_dx, cover_dy);
        color = over.rgb + (color * (1.0 - over.a));
    }
    color *= texture(light_map, varying_color.zw).rgb;
    vec4 base_color = uintBitsToFloat(tl_push[3]);
    float alpha = base_color.a;
    color *= base_color.rgb;
    if ((flags & 1u) == 0u) {
        vec3 facing = varying_normal * inversesqrt(max(dot(varying_normal, varying_normal), 1.0e-12));
        vec3 light = (flags & 8u) != 0u ? diffuse_light(facing, varying_place, varying_lamp) : varying_light;
        color = (flags & 128u) != 0u ? color + light : color * light;
        if ((flags & 64u) != 0u) color += gloss(facing, varying_place);
    }
    // kOpaqueAlpha (1024), như finish_pixel của model_ps.inc.slang.
    if ((flags & 1024u) != 0u) alpha = 1.0;
    vec3 shown = (color * varying_fog.w) + varying_fog.rgb;
    out_color = vec4(shown * fake_gain(varying_place), alpha);
}
