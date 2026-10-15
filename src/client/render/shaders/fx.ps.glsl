// Cùng công thức với fx.ps.slang. tl_push[4].x là FxPush::mode.x: 0 thì cộng sáng (rgb đã nhân alpha, alpha ra 1,
// pipeline One + One), 1 thì màu thẳng với alpha thật (pipeline src_alpha) cho sương, bọt suối và khói. Thiếu nhánh
// thứ hai thì hạt trộn alpha ra quad đen đặc.
uniform highp uvec4 tl_push[5];

layout(binding = 0) uniform sampler2D fx_map;

layout(location = 0) in vec2 varying_uv;
layout(location = 1) in vec4 varying_color;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 texel = texture(fx_map, varying_uv);
    vec3 straight = texel.rgb * varying_color.rgb;
    float coverage = texel.a * varying_color.a;
    if (uintBitsToFloat(tl_push[4].x) < 0.5) {
        out_color = vec4(straight * coverage, 1.0);
        return;
    }
    out_color = vec4(straight, coverage);
}
