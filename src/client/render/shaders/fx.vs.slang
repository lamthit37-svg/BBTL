#include "fx.inc.slang"

struct Vertex {
    float3 position : POSITION;
    float2 uv : TEXCOORD0;
    float4 color : COLOR0;
    float2 uv_cover : TEXCOORD1;
};

Varying main(Vertex vertex) {
    Varying output;
    output.clip = mul(fx_push.view_proj, float4(vertex.position, 1.0));
    output.uv = vertex.uv;
    output.uv_cover = vertex.uv_cover;
    output.color = vertex.color;
    return output;
}
