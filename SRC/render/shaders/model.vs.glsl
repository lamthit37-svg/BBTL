// Cùng bố cục và công thức với model.vs.hlsl. Binding do map_bindings: frame 0, draw 1, palette 0,
// worlds 1. Không có TL_ZERO_TO_ONE thì đổi z [0,1] về clip [-1,1] của GL cũ.
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
} frame;

struct Joint {
    vec4 row0;
    vec4 row1;
    vec4 row2;
};

layout(std430, binding = 0) readonly buffer Palette {
    Joint joints[];
} palette;

layout(std430, binding = 1) readonly buffer Worlds {
    mat4 column[];
} worlds;

// Khối hằng đẩy của từng lệnh vẽ, cùng bố cục 128 byte với Draw của model.hlsli: ba hàng của ma
// trận thế giới, base_color, glow, diffuse, specular, rồi joint_base, joint_count, flags, lamp. Là
// uniform thường để backend đặt bằng một lời gọi glUniform4uiv; uvec4 giữ nguyên bit, số thực lấy
// lại bằng uintBitsToFloat.
uniform highp uvec4 tl_push[8];

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 normal;
layout(location = 2) in vec2 uv;
layout(location = 3) in vec4 color;
layout(location = 4) in uvec4 joints;
layout(location = 5) in vec4 weights;

layout(location = 0) out vec3 varying_normal;
layout(location = 1) out vec2 varying_uv;
layout(location = 2) out vec4 varying_color;
layout(location = 3) out vec3 varying_place;
layout(location = 4) out vec3 varying_light;
// Chỉ số đèn điểm của vật thể (của lệnh vẽ, hoặc của bản sao instanced); cả tam giác một số.
layout(location = 5) flat out highp uint varying_lamp;

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

void main() {
    vec4 local = vec4(position, 1.0);
    vec3 bent = normal;
    float total = dot(weights, vec4(1.0));
    uint joint_base = tl_push[7].x;
    uint joint_count = tl_push[7].y;
    uint flags = tl_push[7].z;
    if (joint_count > 0u && total > 0.0) {
        vec4 row0 = vec4(0.0);
        vec4 row1 = vec4(0.0);
        vec4 row2 = vec4(0.0);
        for (uint slot = 0u; slot < 4u; slot = slot + 1u) {
            uint index = min(joints[slot], joint_count - 1u);
            Joint joint = palette.joints[joint_base + index];
            float weight = weights[slot];
            row0 += joint.row0 * weight;
            row1 += joint.row1 * weight;
            row2 += joint.row2 * weight;
        }
        vec3 moved = vec3(dot(row0, local), dot(row1, local), dot(row2, local));
        local = vec4(moved / total, 1.0);
        bent = vec3(dot(row0.xyz, normal), dot(row1.xyz, normal), dot(row2.xyz, normal));
    }
    vec4 world0 = uintBitsToFloat(tl_push[0]);
    vec4 world1 = uintBitsToFloat(tl_push[1]);
    vec4 world2 = uintBitsToFloat(tl_push[2]);
    vec3 place = vec3(dot(world0, local), dot(world1, local), dot(world2, local));
    vec3 turned = vec3(dot(world0.xyz, bent), dot(world1.xyz, bent), dot(world2.xyz, bent));
    uint lamp = tl_push[7].w;
    if ((flags & 2u) != 0u) {
        mat4 copy = worlds.column[joint_base + uint(gl_InstanceID)];
        place = (copy * local).xyz;
        turned = mat3(copy) * bent;
        // forward.cpp ghi chỉ số đèn của bản sao vào ô hàng cuối, cột đầu của ma trận (ô ấy của ma
        // trận affine là 0; hai phép trên chỉ dùng ba hàng đầu).
        lamp = uint(copy[0].w + 0.5);
    }
    vec3 facing = turned * inversesqrt(max(dot(turned, turned), 1.0e-12));
    gl_Position = frame.view_proj * vec4(place, 1.0);
#ifndef TL_ZERO_TO_ONE
    gl_Position.z = gl_Position.z * 2.0 - gl_Position.w;
#endif
    varying_normal = facing;
    varying_uv = uv;
    varying_color = color;
    varying_place = place;
    varying_light = (flags & 9u) == 0u ? diffuse_light(facing, place, lamp) : vec3(1.0);
    varying_lamp = lamp;
}
