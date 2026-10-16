// Cùng công thức với model.ps.slang. Ảnh và sampler dùng chung texture unit 0.
// TL_SOLID (gói model_solid.ps, thienlong_shader chèn #define lên đầu) bỏ nhánh cắt alpha.
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

layout(binding = 0) uniform sampler2D base_map;
// Mặt nạ t1 của Particle_2Tex (map_bindings xếp t1 sau t0 nên ở unit 1, sampler s1 dùng chung unit ấy).
layout(binding = 1) uniform sampler2D mask_map;

layout(location = 0) in vec3 varying_normal;
layout(location = 1) in vec2 varying_uv;
layout(location = 2) in vec4 varying_color;
layout(location = 3) in vec3 varying_place;
layout(location = 4) in vec3 varying_light;
layout(location = 5) flat in highp uint varying_lamp;
// Sương gộp từ đỉnh (xem fog_terms của model.vs.glsl): màu_cuối = màu * w + rgb.
layout(location = 6) in vec4 varying_fog;

layout(location = 0) out vec4 out_color;

// Khác bản HLSL: không có to_gamma và to_linear. Backend GL là thiết bị màu thô
// (gpu/gles/device.hpp): sampler trả đúng số đã mã hoá và đích nhận đúng số ghi ra, nên công thức
// gamma tính thẳng.

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
        float spread = clamp(size - (length(box.xy) * 3.0), 0.0, 1.0);
        spread *= clamp(size - (length(box.xz) * 3.0), 0.0, 1.0);
        spread *= clamp(size - (length(box.yz) * 3.0), 0.0, 1.0);
        gain *= 1.0 + (frame.fakes[index].color.rgb * spread);
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
    vec4 base_color = uintBitsToFloat(tl_push[3]);
    float alpha_cutoff = uintBitsToFloat(tl_push[5].w);
    vec4 texel = texture(base_map, varying_uv);
    // Particle_2Tex: ảnh t1 nhân rgb và alpha, cùng UV đã cuộn. Cờ kMaskTex (512) tắt thì mặt nạ là 1.
    bool has_mask = (flags & 512u) != 0u;
    vec4 mask = has_mask ? texture(mask_map, varying_uv) : vec4(1.0);
    vec4 tint = (flags & 256u) != 0u ? varying_color : vec4(1.0);
    float alpha = texel.a * mask.a * base_color.a * tint.a;
#ifndef TL_SOLID
    if (alpha < alpha_cutoff) discard;
#endif
    vec3 color = texel.rgb * mask.rgb * base_color.rgb * tint.rgb;
    // ColorX2 và ColorX4 kẹp sau khi nhân hệ số, chỉ với chất liệu có mặt nạ (như model.ps.slang).
    if (has_mask) color = clamp(color, 0.0, 1.0);
    if ((flags & 1u) == 0u) {
        vec3 facing = varying_normal * inversesqrt(max(dot(varying_normal, varying_normal), 1.0e-12));
        vec3 light = (flags & 8u) != 0u ? diffuse_light(facing, varying_place, varying_lamp) : varying_light;
        color = (flags & 128u) != 0u ? color + light : color * light;
        if ((flags & 64u) != 0u) color += gloss(facing, varying_place);
    }
    if ((flags & 1024u) != 0u) alpha = 1.0;
    vec3 shown = (color * varying_fog.w) + varying_fog.rgb;
    out_color = vec4(shown * fake_gain(varying_place), alpha);
}
