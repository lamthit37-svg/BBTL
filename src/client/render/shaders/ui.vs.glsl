// Cùng công thức với ui.vs.slang. Khối push là mảng uvec4 tl_push: phần tử 0 chứa rộng và cao của
// vùng vẽ, phần tử 1 là ô mặt nạ của lô (số thực giữ nguyên bit). Không có TL_ZERO_TO_ONE thì đổi z
// [0,1] về clip [-1,1] của GL cũ.
uniform highp uvec4 tl_push[2];

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in uint color;

layout(location = 0) out vec2 varying_uv;
layout(location = 1) out vec4 varying_color;
layout(location = 2) out vec2 varying_mask;

void main() {
    vec2 size = uintBitsToFloat(tl_push[0]).xy;
    vec4 mask = uintBitsToFloat(tl_push[1]);
    vec2 unit = position / size;
    gl_Position = vec4((unit.x * 2.0) - 1.0, 1.0 - (unit.y * 2.0), 0.5, 1.0);
#ifndef TL_ZERO_TO_ONE
    gl_Position.z = gl_Position.z * 2.0 - gl_Position.w;
#endif
    varying_uv = uv;
    vec3 rgb = vec3(float((color >> 16u) & 255u), float((color >> 8u) & 255u),
                   float(color & 255u)) / 255.0;
    float alpha = float((color >> 24u) & 255u) / 255.0;
    varying_color = vec4(pow(rgb, vec3(2.2)), alpha);
    varying_mask = (position - mask.xy) / mask.zw;
}
