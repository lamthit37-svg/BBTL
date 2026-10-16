// Hạt: đỉnh đã ở thế giới, push constant là view-projection cột. Khớp FxPush ở fx_view.cpp.
#ifndef F2_RENDER_FX_HLSLI
#define F2_RENDER_FX_HLSLI

#include "f2/shader.inc.slang"

struct FxPush {
    float4x4 view_proj;
    // x: hệ số ảnh thứ hai (BLEND_OP_1). 0 là không có ảnh ấy.
    float4 mode;
};
F2_PUSH_CONSTANTS(FxPush, fx_push);

struct Varying {
    float4 clip : SV_Position;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
    float2 uv_cover : TEXCOORD1;
};

#endif
