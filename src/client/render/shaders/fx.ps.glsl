// Cùng công thức với fx.ps.slang. tl_push[4].x là hệ số ảnh thứ hai; 0 là không nhân ảnh ấy.
uniform highp uvec4 tl_push[5];

layout(binding = 0) uniform sampler2D fx_map;
layout(binding = 1) uniform sampler2D fx_cover;

layout(location = 0) in vec2 varying_uv;
layout(location = 1) in vec4 varying_color;
layout(location = 2) in vec2 varying_cover;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 texel = texture(fx_map, varying_uv);
    float cover_gain = uintBitsToFloat(tl_push[4].x);
    vec4 cover = texture(fx_cover, varying_cover);
    vec3 rgb = texel.rgb * varying_color.rgb;
    float alpha = texel.a * varying_color.a;
    if (cover_gain > 0.0) {
        rgb *= cover.rgb * cover_gain;
        alpha *= cover.a;
    }
    out_color.rgb = clamp(rgb, 0.0, 1.0);
    out_color.a = clamp(alpha, 0.0, 1.0);
}
