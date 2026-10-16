// Cùng công thức và bố cục với star.vs.slang. Binding do map_bindings: cbuffer SkyBlock ở 0. Push là
// một uvec4: x là ô của sao trong SkyBlock.
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
layout(location = 1) in vec2 corner;
layout(location = 2) in vec4 colour;

layout(location = 0) out vec2 varying_quad;
layout(location = 1) out vec4 varying_colour;

const vec2 kFlicker[8] = vec2[8](
    vec2(0.897907815, -0.347608525), vec2(0.550299290, 0.273586675),
    vec2(0.823885965, 0.098853070), vec2(0.922739035, -0.122108860),
    vec2(0.800630175, -0.088956800), vec2(0.711673375, 0.158864420),
    vec2(0.870537795, 0.085484560), vec2(0.956022355, -0.058114540));

float flicker_amount(vec3 at, float phase) {
    vec2 hash = fract(at.xy * 256.0);
    float index = fract(hash.x + ((hash.y + 1.0) * phase));
    index = index * 8.0;
    float part = fract(index);
    int slot = min(int(index), 7);
    return kFlicker[slot].x + (part * kFlicker[slot].y);
}

void main() {
    SkyDraw draw = sky.draws[tl_push[0].x];
    vec4 centre = draw.mvp * vec4(position, 1.0);
    float magnitude = 6.5 + (colour.w * (-1.44 - 6.5));
    float amount = flicker_amount(position, draw.a.w);
    float brightness = amount * pow(5.0, (-magnitude - 1.44) / 2.5);
    varying_colour = vec4(brightness * colour.xyz, brightness);
    varying_quad = corner;
    vec2 pixel = (vec2(corner.x, 1.0 - corner.y) - 0.5) * draw.a.xy;
    vec2 offset = pixel * 2.0 / max(draw.b.zw, vec2(1.0));
    vec4 clip = vec4(centre.xy + (offset * centre.w), 0.0, centre.w);
    if (centre.w <= 0.0) clip = vec4(0.0, 0.0, 2.0, 1.0);
    gl_Position = clip;
#ifndef TL_ZERO_TO_ONE
    gl_Position.z = gl_Position.z * 2.0 - gl_Position.w;
#endif
}
