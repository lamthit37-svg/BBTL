// Pixel shader của giao diện 2D: màu texture nhân màu đỉnh như CEGUI, rồi qua mặt nạ của lô theo
// công thức multi-texture của client 2026 (stage 1 của CEGUIOgreRenderer: màu
// BLEND_TEXTURE_ALPHA, alpha MODULATE): rgb = c.rgb * m.a + m.rgb * (1 - m.a), a = c.a * m.a. Lô
// không có mặt nạ gắn điểm ảnh trắng đục làm mặt nạ nên công thức trả nguyên màu c.
// Ảnh và mặt nạ là t0 và t1 (sampler s0 và s1) của register space 1 (F2_DXBC bỏ space), cùng quy
// ước với model.ps.slang.
#include "ui.inc.slang"

#ifndef F2_DXBC
Texture2D<float4> ui_map : register(t0, space1);
SamplerState ui_sampler : register(s0, space1);
Texture2D<float4> mask_map : register(t1, space1);
SamplerState mask_sampler : register(s1, space1);
#else
Texture2D<float4> ui_map : register(t0);
SamplerState ui_sampler : register(s0);
Texture2D<float4> mask_map : register(t1);
SamplerState mask_sampler : register(s1);
#endif

float4 main(Varying input) : SV_Target0 {
    const float4 colour = ui_map.Sample(ui_sampler, input.uv) * input.color;
    const float4 mask = mask_map.Sample(mask_sampler, input.mask_uv);
    return float4((colour.rgb * mask.a) + (mask.rgb * (1.0 - mask.a)), colour.a * mask.a);
}
