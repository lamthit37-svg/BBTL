// Vertex shader của giao diện 2D: đổi điểm ảnh sang clip space, giải màu ARGB đóng gói trong một
// uint. Màu đỉnh là màu sRGB như CEGUI viết, nên đổi sang tuyến tính (x^2,2) để nhân với texture
// sRGB đã được phần cứng giải mã; đích vẽ là sRGB nên kết quả mã hoá lại về đúng giá trị gốc.
// Toạ độ mặt nạ là vị trí của đỉnh trong ô mặt nạ của lô, như bộ UV thứ hai mà renderer của client
// 2026 tính cho quad nằm trong cửa sổ có MaskImage (CEGUIOgreRenderer.dll RVA 0xB910).
// Thứ tự trường của Vertex là location của thuộc tính đỉnh (kAttributes ở render/ui.cpp).
#include "ui.inc.slang"

struct Vertex {
    float2 position : POSITION;
    float2 uv : TEXCOORD0;
    uint color : COLOR0;
};

Varying main(Vertex vertex) {
    Varying output;
    const float2 unit = vertex.position / screen.size.xy;
    output.clip = float4((unit.x * 2.0) - 1.0, 1.0 - (unit.y * 2.0), 0.5, 1.0);
    output.uv = vertex.uv;
    const float3 rgb = float3(float((vertex.color >> 16u) & 255u), float((vertex.color >> 8u) & 255u),
                           float(vertex.color & 255u)) / 255.0;
    const float alpha = float((vertex.color >> 24u) & 255u) / 255.0;
    // Thiết bị màu thô (screen.size.w = 1): texture và đích đều là số gamma, màu đỉnh không đổi.
    const bool is_raw = screen.size.w > 0.5;
    output.color = float4(is_raw ? rgb : pow(rgb, float3(2.2, 2.2, 2.2)), alpha);
    output.mask_uv = (vertex.position - screen.mask.xy) / screen.mask.zw;
    output.premultiplied = screen.size.z;
    return output;
}
