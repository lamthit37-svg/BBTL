// Cùng công thức với fx.ps.slang. tl_push[4].x là FxPush::mode.x: 0 thì cộng sáng (rgb đã nhân alpha, alpha ra 1,
// pipeline One + One), 1 thì màu thẳng với alpha thật (pipeline src_alpha) cho sương, bọt suối và khói. Thiếu nhánh
// thứ hai thì hạt trộn alpha ra quad đen đặc. tl_push[4].y là mode.y: 0 giữ ảnh, 1 bỏ alpha của ảnh, 2 khói (đen, alpha là
// độ sáng của ảnh).
uniform highp uvec4 tl_push[5];

layout(binding = 0) uniform sampler2D fx_map;

layout(location = 0) in vec2 varying_uv;
layout(location = 1) in vec4 varying_color;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 texel = texture(fx_map, varying_uv);
    float use_of_image = uintBitsToFloat(tl_push[4].y);
    bool is_smoke = use_of_image > 1.5;
    bool is_opaque = use_of_image > 0.5 && !is_smoke;
    float lightness = max(texel.r, max(texel.g, texel.b));
    float image_alpha = is_smoke ? lightness : (is_opaque ? 1.0 : texel.a);
    vec3 image_colour = is_smoke ? vec3(0.0) : texel.rgb;
    vec3 straight = image_colour * varying_color.rgb;
    float coverage = image_alpha * varying_color.a;
    if (uintBitsToFloat(tl_push[4].x) < 0.5) {
        out_color = vec4(straight * coverage, 1.0);
        return;
    }
    out_color = vec4(straight, coverage);
}
