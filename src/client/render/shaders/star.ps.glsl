// Cùng công thức với star.ps.slang. Backend GL là thiết bị màu thô: không đổi gamma.
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

layout(location = 0) in vec2 varying_quad;
layout(location = 1) in vec4 varying_colour;

layout(location = 0) out vec4 out_color;

void main() {
    SkyDraw draw = sky.draws[tl_push[0].x];
    float star_intensity = draw.b.x;
    float star_transparent = draw.b.y;
    vec2 from_centre = (3.5 * varying_quad) - (3.5 * vec2(0.5));
    float scale = exp(-dot(from_centre, from_centre));
    vec3 cool = varying_colour.xyz;
    vec3 hot = vec3(varying_colour.w);
    vec3 mixed = (cool * scale) + (5.0 * hot * pow(scale, 10.0));
    vec3 final_colour = clamp(star_intensity * mixed, 0.0, 1.0);
    float alpha = varying_colour.w * star_transparent;
    out_color = vec4(final_colour * alpha, alpha);
}
