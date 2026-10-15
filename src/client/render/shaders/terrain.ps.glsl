// Cùng công thức với terrain.ps.slang (mặt đất lớp cọ); xem chú thích đầu tệp ấy về bốn ảnh. Texture unit theo
// map_bindings: t0 atlas = 0, t1 ô = 1, t2 lightmap = 2, t3 bảng tra = 3; sampler s0 dùng unit 0, s2 dùng unit 2.
// Ô và bảng tra chỉ đọc bằng texelFetch nên không có sampler (backend nhả sampler khỏi unit của chúng).
precision highp sampler2D;

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

// Khối hằng đẩy của từng lệnh vẽ, cùng bố cục 128 byte với Draw của model.inc.slang (xem model.vs.glsl).
uniform highp uvec4 tl_push[8];

layout(binding = 0) uniform sampler2D atlas;
layout(binding = 1) uniform sampler2D cells;
layout(binding = 2) uniform sampler2D light_map;
layout(binding = 3) uniform sampler2D table;

layout(location = 0) in vec3 varying_normal;
layout(location = 1) in vec2 varying_uv;
layout(location = 2) in vec4 varying_color;
layout(location = 3) in vec3 varying_place;
layout(location = 4) in vec3 varying_light;
layout(location = 5) flat in highp uint varying_lamp;

layout(location = 0) out vec4 out_color;

const uint kTableWidth = 1024u;
const uint kFlipStride = 16u;

float fog_share(float depth) {
    float thick = depth * frame.fog_range.x;
    if (frame.fog_kind.w > 0.5) return clamp((frame.fog_range.z - depth) * frame.fog_range.w, 0.0, 1.0);
    if (frame.fog_kind.y > 0.5) return exp(-thick);
    if (frame.fog_kind.z > 0.5) return exp(-(thick * thick));
    return 1.0;
}

// HeightFog_ps.hlsl, như height_fog của model_ps.inc.slang.
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

float word16(float high, float low) {
    return ((round(high * 255.0) * 256.0) + round(low * 255.0)) / 65535.0;
}

vec4 layer_sample(uint pixmap, uint turn, uint flip, vec2 along, vec2 cell_dx, vec2 cell_dy) {
    uint first = pixmap * 4u;
    ivec2 at = ivec2(int(first % kTableWidth), 1 + int(first / kTableWidth));
    vec4 box_a = texelFetch(table, at, 0);
    vec4 box_b = texelFetch(table, ivec2(at.x + 1, at.y), 0);
    vec4 move_a = texelFetch(table, ivec2(at.x + 2, at.y), 0);
    vec4 move_b = texelFetch(table, ivec2(at.x + 3, at.y), 0);
    vec4 edges = vec4(word16(box_a.r, box_a.g), word16(box_a.b, box_a.a), word16(box_b.r, box_b.g),
        word16(box_b.b, box_b.a));
    vec4 into_atlas = vec4(word16(move_a.r, move_a.g), word16(move_a.b, move_a.a), word16(move_b.r, move_b.g),
        word16(move_b.b, move_b.a));
    vec4 raw_corner = texelFetch(table, ivec2(int(flip * kFlipStride + turn), 0), 0) * 255.0;
    uvec4 corner = uvec4(raw_corner + 0.5);
    vec2 left_top = vec2(edges[corner.x >> 4u], edges[corner.x & 15u]);
    vec2 right_top = vec2(edges[corner.y >> 4u], edges[corner.y & 15u]);
    vec2 left_bottom = vec2(edges[corner.z >> 4u], edges[corner.z & 15u]);
    vec2 right_bottom = vec2(edges[corner.w >> 4u], edges[corner.w & 15u]);
    vec2 uv = mix(mix(left_top, right_top, along.x), mix(left_bottom, right_bottom, along.x), along.y);
    vec2 by_x = mix(right_top - left_top, right_bottom - left_bottom, along.y);
    vec2 by_z = mix(left_bottom - left_top, right_bottom - right_top, along.x);
    vec2 slope_x = ((by_x * cell_dx.x) + (by_z * cell_dx.y)) * into_atlas.zw;
    vec2 slope_y = ((by_x * cell_dy.x) + (by_z * cell_dy.y)) * into_atlas.zw;
    return textureGrad(atlas, into_atlas.xy + (uv * into_atlas.zw), slope_x, slope_y);
}

void main() {
    uint flags = tl_push[7].z;
    ivec2 size = textureSize(cells, 0);
    vec2 grid = vec2(size);
    vec2 place = varying_uv * grid;
    vec2 cell_dx = dFdx(place);
    vec2 cell_dy = dFdy(place);
    vec2 cell = clamp(floor(place), vec2(0.0), grid - vec2(1.0));
    vec2 along = place - cell;
    uvec4 ground = uvec4((texelFetch(cells, ivec2(cell), 0) * 255.0) + 0.5);
    uint base_id = ground.r | ((ground.b & 3u) << 8u);
    uint cover_id = ground.g | (((ground.b >> 2u) & 3u) << 8u);
    uint flip = (ground.b >> 4u) & 1u;
    if (base_id == 0u) discard;
    vec4 under = layer_sample(base_id, ground.a & 15u, flip, along, cell_dx, cell_dy);
    vec3 color = (under.a > 0.0) ? (under.rgb / under.a) : vec3(0.0);
    if (cover_id != 0u) {
        vec4 over = layer_sample(cover_id, ground.a >> 4u, flip, along, cell_dx, cell_dy);
        color = over.rgb + (color * (1.0 - over.a));
    }
    vec2 light_at = vec2(place.x / grid.x, 1.0 - (place.y / grid.y));
    vec2 light_dx = vec2(cell_dx.x / grid.x, -cell_dx.y / grid.y);
    vec2 light_dy = vec2(cell_dy.x / grid.x, -cell_dy.y / grid.y);
    color *= textureGrad(light_map, light_at, light_dx, light_dy).rgb;
    vec4 base_color = uintBitsToFloat(tl_push[3]);
    float alpha_cutoff = uintBitsToFloat(tl_push[5].w);
    vec4 tint = (flags & 256u) != 0u ? varying_color : vec4(1.0);
    float alpha = base_color.a * tint.a;
    if (alpha < alpha_cutoff) discard;
    color *= base_color.rgb * tint.rgb;
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
    // kOpaqueAlpha (1024), như finish_pixel của model_ps.inc.slang.
    if ((flags & 1024u) != 0u) alpha = 1.0;
    out_color = vec4(height_fog(color, varying_place), alpha);
}
