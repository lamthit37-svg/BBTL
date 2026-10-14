// Phần chung của vertex shader và pixel shader của giao diện 2D: hằng của lệnh vẽ và dữ liệu đi từ
// đỉnh sang điểm ảnh. Bố cục byte của Screen phải khớp ScreenBlock ở render/ui.cpp.
// Toạ độ đỉnh tính bằng điểm ảnh của vùng vẽ, gốc trái trên, y xuống như CEGUI của client gốc.
#ifndef F2_RENDER_UI_HLSLI
#define F2_RENDER_UI_HLSLI

#include "f2/shader.inc.slang"

struct Screen {
    // Rộng và cao của vùng vẽ, điểm ảnh; z là 1 khi ảnh của lô chứa màu đã nhân alpha (ảnh Canvas có
    // nền trong suốt), 0 khi là ảnh thẳng; w để đủ 16 byte.
    float4 size;
    // Ô màn hình (trái, trên, rộng, cao theo điểm ảnh) mà texture mặt nạ của lô phủ kín.
    float4 mask;
};
F2_PUSH_CONSTANTS(Screen, screen);

struct Varying {
    float4 clip : SV_Position;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
    float2 mask_uv : TEXCOORD1;
    nointerpolation float premultiplied : TEXCOORD2;
};

#endif
