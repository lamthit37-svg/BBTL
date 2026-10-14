// Cùng công thức với fx.ps.slang. Cộng sáng: rgb đã nhân alpha.
layout(binding = 0) uniform sampler2D fx_map;

layout(location = 0) in vec2 varying_uv;
layout(location = 1) in vec4 varying_color;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 texel = texture(fx_map, varying_uv);
    vec3 rgb = texel.rgb * varying_color.rgb * varying_color.a * texel.a;
    out_color = vec4(rgb, 1.0);
}
