/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/render/shaders/origin/compat.slang
 *  PHÂN HỆ   : Shaders / Origin / Compat
 *  CHUẨN     : Slang
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lớp tương thích D3D9 của bộ shader gốc (MaterialTemplates) cho Slang:
 *    TOOLS/port/hlsl_origin.py đặt nó trước mỗi nguồn đã chuyển. Mỗi định nghĩa
 *    giữ nghĩa mà fxc gán cho cú pháp ấy ở shader model 5, chế độ tương thích
 *    ngược mà client gốc dùng. Bản fxc của các macro sampler nằm trong
 *    TOOLS/port/hlsl_oracle.py.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

// Cảnh báo về hành vi mà bản gốc dựa vào và fxc làm đúng như vậy, tắt cho các tệp sau (pragma có
// tác dụng tới hết đơn vị dịch): 15205 macro chưa định nghĩa trong #if là 0; 39019 biến toàn cục
// không static là tham số uniform; 30081 đổi kiểu ngầm (float sang int, vectơ sang vô hướng).
#pragma warning(disable: 15205)
#pragma warning(disable: 39019)
#pragma warning(disable: 30081)

// half của shader model 4 trở lên là float 32 bit.
#define half float
#define half2 float2
#define half3 float3
#define half4 float4
#define half3x3 float3x3
#define half4x4 float4x4

// Giá trị sampler truyền qua hàm như bản gốc; Slang chuyên biệt hoá hàm theo tài nguyên cụ thể.
struct OriginSampler2D {
    Texture2D<float4> texture;
    SamplerState sampler;
};

struct OriginSamplerCube {
    TextureCube<float4> texture;
    SamplerState sampler;
};

typedef OriginSampler2D sampler2D;
typedef OriginSamplerCube samplerCUBE;

// Ô sN của D3D9 là đơn vị ảnh thứ N của vật liệu (texture_unit của pass). hlsl_origin.py viết lại
// "sampler2D X : register(sN);" thành ORIGIN_SAMPLER2D(X, N); kèm "#define X ORIGIN_USE2D(X)";
// ảnh đặt ở tN và sampler ở sN để engine gắn đơn vị N vào cùng một số. (fxc dồn ảnh vào các ô t
// theo thứ tự dùng; đó là chi tiết của bản dịch gốc, không phải hợp đồng của vật liệu.)
#define ORIGIN_SAMPLER2D(name, slot) \
    Texture2D<float4> name##_texture : register(t##slot); \
    SamplerState name##_sampler : register(s##slot)
#define ORIGIN_SAMPLERCUBE(name, slot) \
    TextureCube<float4> name##_texture : register(t##slot); \
    SamplerState name##_sampler : register(s##slot)
#define ORIGIN_USE2D(name) OriginSampler2D(name##_texture, name##_sampler)
#define ORIGIN_USECUBE(name) OriginSamplerCube(name##_texture, name##_sampler)

// Mảng sampler (skyTexture[BLEND_TEXTURE_NUM] của SkySphereLayer): count đơn vị liền nhau từ ô
// slot; chỗ dùng X[i] được viết lại thành ORIGIN_INDEX2D(X, i).
#define ORIGIN_SAMPLER2D_ARRAY(name, slot, count) \
    Texture2D<float4> name##_texture[count] : register(t##slot); \
    SamplerState name##_sampler[count] : register(s##slot)
#define ORIGIN_INDEX2D(name, index) OriginSampler2D(name##_texture[index], name##_sampler[index])

float4 tex2D(OriginSampler2D s, float2 uv) {
    return s.texture.Sample(s.sampler, uv);
}

// tex2Dlod lấy mức mip ở thành phần w.
float4 tex2Dlod(OriginSampler2D s, float4 uv) {
    return s.texture.SampleLevel(s.sampler, uv.xy, uv.w);
}

float4 texCUBE(OriginSamplerCube s, float3 direction) {
    return s.texture.Sample(s.sampler, direction);
}
