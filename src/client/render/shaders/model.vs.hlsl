// Vertex shader của model: skinning bốn khớp mỗi đỉnh, đưa đỉnh và pháp tuyến ra thế giới, chiếu ra
// clip space, và tính ánh sáng khuếch tán ở đỉnh như Model_vs.hlsl của client 2026 (chất liệu tính
// ánh sáng ở điểm ảnh thì để pixel shader tính). Thứ tự trường của Vertex là location của thuộc
// tính đỉnh (kAttributes ở render/forward.cpp).
// Nguồn khung tệp: Forge2 src/render/shaders/model.vs.hlsl@d7fcd76. Khác gốc: F2_DXBC gắn palette
// ở t8 và worlds ở t9 (space 2 slot 0 và 1 cộng kSpace2ResourceBase), fxc không có register space;
// ma trận thế giới của lệnh vẽ đi bằng ba hàng; thêm vị trí thế giới và ánh sáng ở đỉnh.
#include "model.hlsli"

// Một khớp của bảng: ba hàng đầu của ma trận skin (hàng cuối luôn là 0, 0, 0, 1). Ghi từng hàng
// thay cho float4x4 để bố cục không phụ thuộc cách xếp ma trận của buffer có cấu trúc.
struct Joint {
    float4 row0;
    float4 row1;
    float4 row2;
};
#ifndef F2_DXBC
StructuredBuffer<Joint> palette : register(t0, space2);
StructuredBuffer<float4x4> worlds : register(t1, space2);
#else
StructuredBuffer<Joint> palette : register(t8);
StructuredBuffer<float4x4> worlds : register(t9);
#endif

struct Vertex {
    float3 position : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
    uint4 joints : BLENDINDICES0;
    float4 weights : BLENDWEIGHT0;
};

// Tổ hợp theo trọng số của bốn khớp. Chỉ số khớp kẹp vào skin: khớp có trọng số 0 trong tệp được
// phép mang chỉ số bất kỳ, và đọc ra ngoài buffer là hành vi không xác định của GPU.
Joint blend_joints(Vertex vertex) {
    Joint mixed;
    mixed.row0 = float4(0.0, 0.0, 0.0, 0.0);
    mixed.row1 = float4(0.0, 0.0, 0.0, 0.0);
    mixed.row2 = float4(0.0, 0.0, 0.0, 0.0);
    for (uint slot = 0u; slot < 4u; ++slot) {
        const uint index = min(vertex.joints[slot], draw.joint_count - 1u);
        const Joint joint = palette[draw.joint_base + index];
        const float weight = vertex.weights[slot];
        mixed.row0 += joint.row0 * weight;
        mixed.row1 += joint.row1 * weight;
        mixed.row2 += joint.row2 * weight;
    }
    return mixed;
}

// Điểm hoặc hướng (w là 1 hoặc 0) qua ma trận thế giới của lệnh vẽ hay của bản sao instanced.
float3 to_world(float4 local, uint instance_id) {
    if ((draw.flags & kInstanced) != 0u) return mul(worlds[draw.joint_base + instance_id], local).xyz;
    return float3(dot(draw.world0, local), dot(draw.world1, local), dot(draw.world2, local));
}

// Đèn điểm của vật thể: của lệnh vẽ, hoặc của bản sao instanced. forward.cpp ghi chỉ số đèn của
// bản sao vào ô hàng cuối, cột đầu của ma trận thế giới của nó (ô ấy của ma trận affine là 0, và
// to_world chỉ lấy xyz). Đọc bằng chính phép mul(M, v) mà to_world dùng, nên không phụ thuộc cách
// buffer có cấu trúc xếp ma trận.
uint lamp_of(uint instance_id) {
    if ((draw.flags & kInstanced) == 0u) return draw.lamp;
    const float4 first_axis = float4(1.0, 0.0, 0.0, 0.0);
    return uint(mul(worlds[draw.joint_base + instance_id], first_axis).w + 0.5);
}

Varying main(Vertex vertex, uint instance_id : SV_InstanceID) {
    float4 local = float4(vertex.position, 1.0);
    float3 normal = vertex.normal;
    const float total = dot(vertex.weights, float4(1.0, 1.0, 1.0, 1.0));
    // Đỉnh không có trọng số nào đứng yên ở vị trí gốc, như lưới không skin.
    if (draw.joint_count > 0u && total > 0.0) {
        const Joint skin = blend_joints(vertex);
        const float3 moved = float3(dot(skin.row0, local), dot(skin.row1, local), dot(skin.row2, local));
        local = float4(moved / total, 1.0);
        normal = float3(dot(skin.row0.xyz, normal), dot(skin.row1.xyz, normal), dot(skin.row2.xyz, normal));
    }
    const float3 place = to_world(local, instance_id);
    const float3 turned = to_world(float4(normal, 0.0), instance_id);
    // Pháp tuyến dài 0 (lưới không khai) giữ nguyên là 0: ánh sáng chỉ còn phần nền.
    const float3 facing = turned * rsqrt(max(dot(turned, turned), 1.0e-12));
    const bool is_lit_here = (draw.flags & (kUnlit | kPixelLit)) == 0u;
    const uint lamp = lamp_of(instance_id);
    Varying output;
    output.clip = mul(frame.view_proj, float4(place, 1.0));
    output.normal = facing;
    output.uv = vertex.uv;
    output.color = vertex.color;
    output.place = place;
    output.light = is_lit_here ? diffuse_light(facing, place, lamp) : float3(1.0, 1.0, 1.0);
    output.lamp = lamp;
    return output;
}
