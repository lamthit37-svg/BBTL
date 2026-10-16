// Sao của bầu trời EnScene, theo FixStar.hlsl của client 2026 (StarsVS, StarsPS). Dùng chung cbuffer
// SkyBlock với sky.inc.slang: một ô riêng của SkyBlock mang ma trận và hai vectơ tham số của sao.
// Ô sao: mvp; a = StarSize (cỡ x, cỡ y, 0, nhấp nháy); b = (StarIntensity, StarTransparent, rộng, cao của
// khung theo điểm ảnh); misc.z = 1 khi thiết bị màu thô.
// Bản gốc vẽ điểm sprite (point_sprites on); D3D12 và Vulkan không có kích thước điểm nên đỉnh nhân bốn
// thành hình chữ nhật cỡ StarSize.xy điểm ảnh quanh tâm sao.
#ifndef TL_RENDER_STAR_HLSLI
#define TL_RENDER_STAR_HLSLI

#include "sky.inc.slang"

struct StarVarying {
    float4 clip : SV_Position;
    // QuadPos của bản gốc: 0..1 trên sprite.
    float2 quad : TEXCOORD0;
    // (màu * độ sáng, độ sáng).
    float4 colour : COLOR0;
};

#endif
