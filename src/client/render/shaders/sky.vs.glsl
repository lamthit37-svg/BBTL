// Cùng công thức và bố cục với sky.vs.slang. Binding do map_bindings: cbuffer SkyBlock ở 0, ảnh ở các
// unit 0..2. Push là một uvec4: x là ô của lệnh vẽ trong SkyBlock. Không có TL_ZERO_TO_ONE thì đổi z [0,1]
// về clip [-1,1] của GL cũ.
struct SkyDraw {
    mat4 mvp;
    vec4 world0;
    vec4 world1;
    vec4 world2;
    vec4 a;
    vec4 b;
    vec4 sun;
    vec4 light;
    vec4 rim;
    vec4 fog;
    vec4 control;
    vec4 ambient;
    vec4 misc;
};

layout(std140, binding = 0) uniform SkyBlock {
    SkyDraw draws[32];
} sky;

uniform highp uvec4 tl_push[1];

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;

layout(location = 0) out vec2 varying_uv0;
layout(location = 1) out vec2 varying_uv1;
layout(location = 2) out vec3 varying_normal;

const float kFarShare = 1.0 - 0.999999;

vec3 spin(SkyDraw draw, vec3 local) {
    return vec3(dot(draw.world0.xyz, local), dot(draw.world1.xyz, local), dot(draw.world2.xyz, local));
}

void finish(vec4 clip) {
    gl_Position = clip;
#ifndef TL_ZERO_TO_ONE
    gl_Position.z = gl_Position.z * 2.0 - gl_Position.w;
#endif
}

void dome(SkyDraw draw) {
    vec4 local = vec4(position, 1.0);
    vec4 unit = normalize(local);
    varying_uv0 = vec2(draw.a.x, clamp(1.0 - unit.y, 0.0, 1.0));
    vec4 raised = local;
    raised.y = raised.y + draw.a.y;
    vec4 clip = draw.mvp * raised;
    clip.z = clip.w * kFarShare;
    finish(clip);
    float horizon_vertex = 1.0 - abs(unit.y);
    float horizon_sun = 1.0 - abs(draw.sun.y);
    float forward = clamp(dot(unit.xyz, draw.sun.xyz), 0.0, 1.0);
    float mie_amount = pow(forward, draw.b.z);
    float sun_effect = draw.sun.y * unit.y * draw.b.y;
    float vertex_effect = horizon_vertex * horizon_sun * draw.b.x;
    float extra = clamp(forward * (vertex_effect + sun_effect) + draw.a.w, 0.0, 1.0);
    float mie = (mie_amount + extra) * draw.a.z;
    varying_uv1 = vec2(mie, mie);
    varying_normal = vec3(0.0);
}

void cloud(SkyDraw draw) {
    vec4 shifted = vec4(position, 1.0);
    shifted.y = shifted.y + draw.a.z;
    vec3 pointed = spin(draw, shifted.xyz);
    varying_normal = normalize(vec4(pointed, 1.0)).xyz;
    vec4 clip = draw.mvp * shifted;
    clip.z = clip.w * kFarShare;
    finish(clip);
    varying_uv0 = vec2(uv.x * draw.a.x, (uv.y * draw.a.y) + draw.b.x);
    varying_uv1 = uv;
}

void ring(SkyDraw draw) {
    vec4 lowered = vec4(position, 1.0);
    lowered.y = lowered.y - (draw.b.y * draw.a.z * 0.000001);
    varying_normal = normalize(spin(draw, lowered.xyz));
    vec4 clip = draw.mvp * lowered;
    clip.z = clip.w * kFarShare;
    finish(clip / abs(clip.w));
    float across = uv.x * draw.a.x;
    varying_uv0 = vec2(across, uv.y + draw.a.y);
    varying_uv1 = vec2(across, uv.y);
}

void body(SkyDraw draw) {
    vec4 clip = draw.mvp * vec4(position, 1.0);
    clip.z = 0.0;
    finish(clip);
    varying_uv0 = uv;
    varying_uv1 = vec2(0.0);
    varying_normal = vec3(0.0);
}

void main() {
    SkyDraw draw = sky.draws[tl_push[0].x];
    uint kind = uint(draw.misc.x);
    if (kind == 0u) {
        dome(draw);
    } else if (kind == 1u) {
        cloud(draw);
    } else if (kind == 2u) {
        ring(draw);
    } else {
        body(draw);
    }
}
