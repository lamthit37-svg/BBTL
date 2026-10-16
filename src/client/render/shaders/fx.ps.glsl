// Cùng công thức với fx.ps.slang: saturate(ảnh * đỉnh). Hệ số trộn nằm ở pipeline.
uniform highp uvec4 tl_push[5];

layout(binding = 0) uniform sampler2D fx_map;

layout(location = 0) in vec2 varying_uv;
layout(location = 1) in vec4 varying_color;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 texel = texture(fx_map, varying_uv);
    out_color.rgb = clamp(texel.rgb * varying_color.rgb, 0.0, 1.0);
    out_color.a = clamp(texel.a * varying_color.a, 0.0, 1.0);
}
