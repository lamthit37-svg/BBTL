// Cùng công thức với fx.vs.slang. Push là 4 uvec4, mỗi cái một cột của view-projection.
uniform highp uvec4 tl_push[4];

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 color;

layout(location = 0) out vec2 varying_uv;
layout(location = 1) out vec4 varying_color;

void main() {
    mat4 view_proj = mat4(uintBitsToFloat(tl_push[0]), uintBitsToFloat(tl_push[1]),
        uintBitsToFloat(tl_push[2]), uintBitsToFloat(tl_push[3]));
    gl_Position = view_proj * vec4(position, 1.0);
#ifndef TL_ZERO_TO_ONE
    gl_Position.z = gl_Position.z * 2.0 - gl_Position.w;
#endif
    varying_uv = uv;
    varying_color = color;
}
