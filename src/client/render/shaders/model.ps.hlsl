// Pixel shader của model, theo Model_ps.hlsl của client 2026: màu texture nhân hệ số của chất liệu,
// cắt theo alpha, ghép với ánh sáng khuếch tán (nhân, hoặc cộng với chất liệu đổi màu), cộng
// specular Blinn của đèn chính một, rồi trộn sương theo độ sâu trong không gian camera.
// Mọi phép tính trên màu làm trong không gian gamma như bản gốc; đích vẽ là sRGB nên kết quả đổi
// về tuyến tính trước khi trả.
// Nguồn khung tệp: Forge2 src/render/shaders/model.ps.hlsl@d7fcd76. Khác gốc: F2_DXBC bỏ register
// space (ảnh và sampler vẫn là t0 và s0, mặt nạ là t1 và s1, đúng resource_register của space 1);
// công thức màu là của bản gốc thay một đèn Lambert.
#include "model_ps.hlsli"

#ifndef F2_DXBC
Texture2D<float4> base_map : register(t0, space1);
Texture2D<float4> mask_map : register(t1, space1);
SamplerState base_sampler : register(s0, space1);
SamplerState mask_sampler : register(s1, space1);
#else
Texture2D<float4> base_map : register(t0);
Texture2D<float4> mask_map : register(t1);
SamplerState base_sampler : register(s0);
SamplerState mask_sampler : register(s1);
#endif

float4 main(Varying input) : SV_Target0 {
    const float4 texel = base_map.Sample(base_sampler, input.uv);
    // Particle_2Tex: tex2 nhân rgb và alpha. Cả hai mẫu dùng UV đã cuộn ở vertex shader.
    // rgb nhân trong gamma như các phép màu khác của shader này. Cờ tắt thì mặt nạ là 1.
    float3 mask_rgb = float3(1.0, 1.0, 1.0);
    float mask_alpha = 1.0;
    const bool has_mask = (draw.flags & kMaskTex) != 0u;
    if (has_mask) {
        const float4 mask = mask_map.Sample(mask_sampler, input.uv);
        mask_rgb = to_gamma(mask.rgb);
        mask_alpha = mask.a;
    }
    const bool has_tint = (draw.flags & kVertexColor) != 0u;
    const float4 tint = has_tint ? input.color : float4(1.0, 1.0, 1.0, 1.0);
    const float alpha = texel.a * mask_alpha * draw.base_color.a * tint.a;
    if (alpha < draw.diffuse.a) {
        discard;
    }
    float3 color = to_gamma(texel.rgb) * mask_rgb * draw.base_color.rgb * tint.rgb;
    // ColorX2 và ColorX4 kẹp sau khi nhân hệ số. Chất liệu không mặt nạ giữ nguyên, không kẹp thêm.
    if (has_mask) color = saturate(color);
    return finish_pixel(color, alpha, input);
}
