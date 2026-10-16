// Hạt: đỉnh đã ở thế giới, push constant là view-projection cột. Khớp FxPush ở fx_view.cpp.
#ifndef F2_RENDER_FX_HLSLI
#define F2_RENDER_FX_HLSLI

#include "f2/shader.inc.slang"

struct FxPush {
    float4x4 view_proj;
    // Giữ trong khối push cho khớp FxGpuPush. Công thức màu không đọc trường này.
    float4 mode;
};
F2_PUSH_CONSTANTS(FxPush, fx_push);

struct Varying {
    float4 clip : SV_Position;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
};

#endif
