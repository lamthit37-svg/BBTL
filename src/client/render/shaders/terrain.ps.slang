// Pixel shader mặt đất lớp cọ (FairyTerrain của client 2026): mỗi điểm lấy cọ nền và cọ phủ của ô nó đứng
// trong, nhân lightmap, rồi qua cùng phần ánh sáng, sương của model (model_ps.inc.slang). Không nướng ảnh mặt
// đất trên CPU, và lọc bất đẳng hướng 16 lần trên chính ảnh cọ nên nét như cọ gốc ở mọi khoảng cách.
// Toạ độ ghép sẵn ở đỉnh, như bản gốc (mỗi ô có bốn đỉnh riêng, map/splat.hpp tính toạ độ atlas bốn góc):
//   uv       toạ độ atlas của cọ nền.
//   color.xy toạ độ atlas của cọ phủ; x âm là ô không có lớp phủ.
//   color.zw toạ độ lightmap, đã lật trục v vì hàng đầu ảnh là biên z lớn.
// Pixel shader vì thế chỉ còn hai lần lấy mẫu atlas và một lần lấy mẫu lightmap, không tra bảng nào: bản đầu tra
// ô và bảng pixmap theo từng điểm ảnh và chậm hơn một khoảng đáng kể (đo 2026-10-17 trên PowerVR GE8320).
// Hai ảnh đều là số thô như bản gốc, không giải mã sRGB:
//   t0 atlas: mọi ảnh cọ, màu đã nhân alpha, mỗi ảnh có viền đệm lặp mép.
//   t2 light: lightmap cả địa hình.
#define TL_TERRAIN 1
#include "model_ps.inc.slang"

#ifndef F2_DXBC
Texture2D<float4> atlas : register(t0, space1);
Texture2D<float4> light_map : register(t2, space1);
SamplerState atlas_sampler : register(s0, space1);
SamplerState light_sampler : register(s2, space1);
#else
Texture2D<float4> atlas : register(t0);
Texture2D<float4> light_map : register(t2);
SamplerState atlas_sampler : register(s0);
SamplerState light_sampler : register(s2);
#endif

float4 main(Varying input) : SV_Target0 {
    // Đạo hàm lấy trước nhánh: chúng chỉ đúng khi cả bốn điểm của cụm cùng đi qua. Cả cụm 2 x 2 thuộc một tam
    // giác nên điều kiện của nhánh phủ giống nhau trong cụm.
    const float2 cover_dx = ddx(input.color.xy);
    const float2 cover_dy = ddy(input.color.xy);
    // Không discard: shader có discard làm GPU tile (PowerVR) mất khử che khuất, mặt đất phủ cả màn hình nên tốn
    // gấp đôi (đo 2026-10-16 trên GE8320: khung 90 ms xuống 44 ms). Ô không có cọ nền (lỗ địa hình) không có
    // đỉnh nào (build_painted ở prelude.hpp), nên mọi điểm ở đây đều có cọ nền.
    const float4 under = atlas.Sample(atlas_sampler, input.uv);
    // Cọ nền luôn đục: màu thẳng, bỏ alpha.
    float3 color = (under.a > 0.0) ? (under.rgb / under.a) : float3(0.0, 0.0, 0.0);
    if (input.color.x >= 0.0) {
        const float4 over = atlas.SampleGrad(atlas_sampler, input.color.xy, cover_dx, cover_dy);
        // Cọ phủ đã nhân alpha: over + nền * (1 - alpha của nó).
        color = over.rgb + (color * (1.0 - over.a));
    }
    // Lightmap nhân thẳng trong không gian gamma.
    color *= light_map.Sample(light_sampler, input.color.zw).rgb;
    // Mặt đất luôn đục: alpha 1, nên ngưỡng cắt alpha không bao giờ cắt và không có nhánh discard.
    return finish_pixel(color * draw.base_color.rgb, draw.base_color.a, input);
}
