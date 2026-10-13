// Phần điểm ảnh dùng chung của model.ps và terrain.ps: đổi gamma, sương, specular và bước hoàn tất (ánh
// sáng khuếch tán, sương, đổi về tuyến tính) sau khi mỗi shader đã tính xong màu gamma và alpha của
// riêng nó. Tách ra để hai shader không lệch công thức ánh sáng và sương của nhau.
// Công thức theo Model_ps.hlsl của client 2026; xem chú thích đầu model.ps.hlsl.
#ifndef TL_RENDER_MODEL_PS_HLSLI
#define TL_RENDER_MODEL_PS_HLSLI

#include "model.hlsli"

// Đường cong sRGB chính xác, hai chiều.
float3 to_gamma(float3 linear_color) {
    const float3 value = max(linear_color, float3(0.0, 0.0, 0.0));
    const float3 low = value * 12.92;
    const float3 high = (1.055 * pow(value, float3(1.0, 1.0, 1.0) / 2.4)) - 0.055;
    return lerp(high, low, step(value, float3(0.0031308, 0.0031308, 0.0031308)));
}

float3 to_linear(float3 gamma_color) {
    const float3 value = saturate(gamma_color);
    const float3 low = value / 12.92;
    const float3 high = pow((value + 0.055) / 1.055, float3(2.4, 2.4, 2.4));
    return lerp(high, low, step(value, float3(0.04045, 0.04045, 0.04045)));
}

// Phần màu còn lại sau sương (1 là không sương), như Fogging của ShaderLib/Fog.inc. Bản gốc cộng
// cả bốn số hạng nhân với fog_kind; ở đây chỉ tính số hạng của kiểu đang bật (kết quả như nhau vì
// đúng một ô của fog_kind bằng 1) để máy yếu không trả giá hai hàm exp cho sương thẳng.
float fog_share(float depth) {
    const float thick = depth * frame.fog_range.x;
    if (frame.fog_kind.w > 0.5) return saturate((frame.fog_range.z - depth) * frame.fog_range.w);
    if (frame.fog_kind.y > 0.5) return exp(-thick);
    if (frame.fog_kind.z > 0.5) return exp(-(thick * thick));
    return 1.0;
}

// HeightFog_ps.hlsl: sương theo cao độ và theo khoảng cách, rồi tán xạ hướng đèn.
// CameraToReceiver = place - mắt. Hướng đèn trong shader gốc là hướng tia đi, tức -sun_toward.
float3 height_fog(float3 color, float3 place) {
    if (frame.hfog_color.a < 0.5) return color;
    const float3 to_point = place - frame.eye.xyz;
    const float ray_length = sqrt(max(dot(to_point, to_point), 1.0e-12));
    const float above = max(0.0, place.y - frame.hfog.y);
    // fxc từ chối pow khi không chứng minh được cơ số không âm. density * exp của bản gốc không âm
    // khi mật độ không âm; max giữ đúng kết quả đó.
    float by_height = frame.hfog.x * exp((-frame.hfog.z / 1000.0) * above);
    by_height = pow(max(by_height, 0.0), frame.hfog.w);
    const float span = max(0.0, ray_length - frame.dfog.z);
    const float by_depth = 1.0 - (frame.dfog.x * exp((-frame.dfog.y / 1000.0) * span));
    const float facing = saturate(dot(to_point / ray_length, frame.sun_toward[0].xyz));
    const float scattered = pow(facing, frame.hfog_scatter.w);
    const float3 tint = saturate(lerp(frame.hfog_color.rgb, frame.hfog_scatter.rgb, scattered));
    return lerp(color, tint, by_height * by_depth);
}

// Specular Blinn của đèn chính một (Calc_Specular_Std): không nhân theo hướng mặt, cơ số kẹp 0,01.
float3 gloss(float3 normal, float3 place) {
    const float3 toward_eye = normalize(frame.eye.xyz - place);
    const float3 half_way = normalize(toward_eye + frame.sun_toward[0].xyz);
    return pow(max(dot(normal, half_way), 0.01), draw.glow.a) * draw.specular.rgb;
}

// Màu gamma và alpha đã có: ghép ánh sáng khuếch tán (nhân, hoặc cộng với chất liệu đổi màu), cộng
// specular, trộn sương, đổi về tuyến tính cho đích sRGB.
float4 finish_pixel(float3 gamma_color, float alpha, Varying input) {
    float3 color = gamma_color;
    if ((draw.flags & kUnlit) == 0u) {
        // Như bản gốc, mặt sau của chất liệu hai mặt dùng nguyên pháp tuyến của mặt trước.
        const float3 slope = input.normal;
        const float3 normal = slope * rsqrt(max(dot(slope, slope), 1.0e-12));
        const bool is_lit_here = (draw.flags & kPixelLit) != 0u;
        const float3 light = is_lit_here ? diffuse_light(normal, input.place, input.lamp) : input.light;
        const bool is_added = (draw.flags & kAddLight) != 0u;
        color = is_added ? color + light : color * light;
        if ((draw.flags & kSpecular) != 0u) color += gloss(normal, input.place);
    }
    if ((draw.flags & kNoFog) == 0u) {
        const float depth = dot(frame.depth_row, float4(input.place, 1.0));
        color = lerp(frame.fog_color.rgb, color, fog_share(depth));
    }
    color = height_fog(color, input.place);
    return float4(to_linear(color), alpha);
}

#endif
