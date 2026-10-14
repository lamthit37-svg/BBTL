// Cùng công thức với ui.ps.slang. Ảnh ở texture unit 0, mặt nạ ở unit 1 (mỗi ảnh dùng chung unit với
// sampler của nó).
layout(binding = 0) uniform sampler2D ui_map;
layout(binding = 1) uniform sampler2D mask_map;

layout(location = 0) in vec2 varying_uv;
layout(location = 1) in vec4 varying_color;
layout(location = 2) in vec2 varying_mask;

layout(location = 0) out vec4 out_color;

void main() {
    vec4 colour = texture(ui_map, varying_uv) * varying_color;
    vec4 mask = texture(mask_map, varying_mask);
    out_color = vec4((colour.rgb * mask.a) + (mask.rgb * (1.0 - mask.a)), colour.a * mask.a);
}
