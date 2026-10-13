// Cùng công thức với model.ps.hlsl. Ảnh và sampler dùng chung texture unit 0.
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
} frame;

// Khối hằng đẩy của từng lệnh vẽ, cùng bố cục 128 byte với Draw của model.hlsli (xem model.vs.glsl).
uniform highp uvec4 tl_push[8];

layout(binding = 0) uniform sampler2D base_map;

layout(location = 0) in vec3 varying_normal;
layout(location = 1) in vec2 varying_uv;
layout(location = 2) in vec4 varying_color;
layout(location = 3) in vec3 varying_place;
layout(location = 4) in vec3 varying_light;
layout(location = 5) flat in highp uint varying_lamp;

layout(location = 0) out vec4 out_color;

// Khác bản HLSL: không có to_gamma và to_linear. Backend GL là thiết bị màu thô
// (gpu/gles/device.hpp): sampler trả đúng số đã mã hoá và đích nhận đúng số ghi ra, nên công thức
// gamma tính thẳng.

float fog_share(float depth) {
    float thick = depth * frame.fog_range.x;
    if (frame.fog_kind.w > 0.5) return clamp((frame.fog_range.z - depth) * frame.fog_range.w, 0.0, 1.0);
    if (frame.fog_kind.y > 0.5) return exp(-thick);
    if (frame.fog_kind.z > 0.5) return exp(-(thick * thick));
    return 1.0;
}

// HeightFog_ps.hlsl, như height_fog của model_ps.hlsli.
vec3 height_fog(vec3 color, vec3 place) {
    if (frame.hfog_color.a < 0.5) return color;
    vec3 to_point = place - frame.eye.xyz;
    float ray_length = sqrt(max(dot(to_point, to_point), 1.0e-12));
    float above = max(0.0, place.y - frame.hfog.y);
    float by_height = frame.hfog.x * exp((-frame.hfog.z / 1000.0) * above);
    by_height = pow(max(by_height, 0.0), frame.hfog.w);
    float span = max(0.0, ray_length - frame.dfog.z);
    float by_depth = 1.0 - (frame.dfog.x * exp((-frame.dfog.y / 1000.0) * span));
    float facing = clamp(dot(to_point / ray_length, frame.sun_toward[0].xyz), 0.0, 1.0);
    float scattered = pow(facing, frame.hfog_scatter.w);
    vec3 tint = clamp(mix(frame.hfog_color.rgb, frame.hfog_scatter.rgb, scattered), 0.0, 1.0);
    return mix(color, tint, by_height * by_depth);
}

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
    vec4 tint = (flags & 256u) != 0u ? varying_color : vec4(1.0);
    float alpha = texel.a * base_color.a * tint.a;
    if (alpha < alpha_cutoff) discard;
    vec3 color = texel.rgb * base_color.rgb * tint.rgb;
    if ((flags & 1u) == 0u) {
        vec3 facing = varying_normal * inversesqrt(max(dot(varying_normal, varying_normal), 1.0e-12));
        vec3 light = (flags & 8u) != 0u ? diffuse_light(facing, varying_place, varying_lamp) : varying_light;
        color = (flags & 128u) != 0u ? color + light : color * light;
        if ((flags & 64u) != 0u) color += gloss(facing, varying_place);
    }
    if ((flags & 16u) == 0u) {
        float depth = dot(frame.depth_row, vec4(varying_place, 1.0));
        color = mix(frame.fog_color.rgb, color, fog_share(depth));
    }
    out_color = vec4(height_fog(color, varying_place), alpha);
}
