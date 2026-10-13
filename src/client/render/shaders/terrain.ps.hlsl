// Pixel shader mặt đất lớp cọ (FairyTerrain của client 2026): mỗi điểm lấy cọ nền và cọ phủ của ô nó
// đứng trong, nhân lightmap, rồi qua cùng phần ánh sáng, sương của model (model_ps.hlsli). Thay ảnh mặt
// đất nướng sẵn trên CPU: không nướng, không ảnh 8192 x 8192, và lọc bất đẳng hướng 16 lần trên chính
// ảnh cọ nên nét như cọ gốc ở mọi khoảng cách.
// Bốn ảnh của chất liệu (resource::Splat), đều là số thô như bản gốc, không giải mã sRGB:
//   t0 atlas: mọi ảnh cọ, màu đã nhân alpha, mỗi ảnh có viền đệm lặp mép.
//   t1 cells: một texel mỗi ô. R = pixmap nền (8 bit thấp), G = pixmap phủ (8 bit thấp),
//     B = bit 0-1 pixmap nền cao, bit 2-3 pixmap phủ cao, bit 4 cờ đường chéo; A = orientation nền
//     (nibble thấp) và phủ (nibble cao).
//   t2 light: lightmap cả địa hình, hàng trên cùng là biên z lớn.
//   t3 table: hàng 0 là bốn góc theo (cờ đường chéo x 16 + orientation), mỗi byte một góc, nibble cao
//     là cạnh U, nibble thấp là cạnh V (0 trái, 1 trên, 2 phải, 3 dưới; bảng của Terrain::_getPixmapCorner).
//     Từ hàng 1, pixmap p chiếm bốn texel liền nhau từ vị trí 4p: hộp (trái, trên, phải, dưới) theo ảnh cọ,
//     rồi phép đổi (gốc x, gốc y, tỉ lệ x, tỉ lệ y) sang atlas; mỗi số 16 bit chia hai kênh (cao, thấp).
// uv của đỉnh là toạ độ thế giới chuẩn hoá trên cả địa hình, nên uv nhân số ô là toạ độ ô liên tục:
// đạo hàm của nó qua mép ô vẫn liền, nhờ đó mức mip không nhảy ở mép ô dù pixmap hai bên khác nhau.
#include "model_ps.hlsli"

#ifndef F2_DXBC
Texture2D<float4> atlas : register(t0, space1);
Texture2D<float4> cells : register(t1, space1);
Texture2D<float4> light_map : register(t2, space1);
Texture2D<float4> table : register(t3, space1);
SamplerState atlas_sampler : register(s0, space1);
SamplerState light_sampler : register(s2, space1);
#else
Texture2D<float4> atlas : register(t0);
Texture2D<float4> cells : register(t1);
Texture2D<float4> light_map : register(t2);
Texture2D<float4> table : register(t3);
SamplerState atlas_sampler : register(s0);
SamplerState light_sampler : register(s2);
#endif

// Số texel mỗi hàng của bảng tra; mã C++ (map/splat.cpp) ghi cùng số này.
static const uint kTableWidth = 1024u;
static const uint kFlipStride = 16u;

// Số 16 bit từ hai kênh 8 bit (cao, thấp) của texel UNORM, về [0, 1].
float word16(float high, float low) {
    return ((round(high * 255.0) * 256.0) + round(low * 255.0)) / 65535.0;
}

// Màu (đã nhân alpha) của một lớp tại điểm along trong ô, lọc theo đạo hàm của toạ độ ô.
float4 layer_sample(uint pixmap, uint turn, uint flip, float2 along, float2 cell_dx, float2 cell_dy) {
    const uint first = pixmap * 4u;
    const int2 at = int2(int(first % kTableWidth), 1 + int(first / kTableWidth));
    const float4 box_a = table.Load(int3(at.x, at.y, 0));
    const float4 box_b = table.Load(int3(at.x + 1, at.y, 0));
    const float4 move_a = table.Load(int3(at.x + 2, at.y, 0));
    const float4 move_b = table.Load(int3(at.x + 3, at.y, 0));
    const float4 edges = float4(word16(box_a.r, box_a.g), word16(box_a.b, box_a.a), word16(box_b.r, box_b.g),
        word16(box_b.b, box_b.a));
    const float4 into_atlas = float4(word16(move_a.r, move_a.g), word16(move_a.b, move_a.a),
        word16(move_b.r, move_b.g), word16(move_b.b, move_b.a));
    const float4 raw_corner = table.Load(int3(int(flip * kFlipStride + turn), 0, 0)) * 255.0;
    const uint4 corner = uint4(raw_corner + 0.5);
    const float2 left_top = float2(edges[corner.x >> 4u], edges[corner.x & 15u]);
    const float2 right_top = float2(edges[corner.y >> 4u], edges[corner.y & 15u]);
    const float2 left_bottom = float2(edges[corner.z >> 4u], edges[corner.z & 15u]);
    const float2 right_bottom = float2(edges[corner.w >> 4u], edges[corner.w & 15u]);
    const float2 uv = lerp(lerp(left_top, right_top, along.x), lerp(left_bottom, right_bottom, along.x), along.y);
    // Đạo hàm của uv theo toạ độ trong ô, rồi theo màn hình qua đạo hàm của toạ độ ô.
    const float2 by_x = lerp(right_top - left_top, right_bottom - left_bottom, along.y);
    const float2 by_z = lerp(left_bottom - left_top, right_bottom - right_top, along.x);
    const float2 slope_x = ((by_x * cell_dx.x) + (by_z * cell_dx.y)) * into_atlas.zw;
    const float2 slope_y = ((by_x * cell_dy.x) + (by_z * cell_dy.y)) * into_atlas.zw;
    return atlas.SampleGrad(atlas_sampler, into_atlas.xy + (uv * into_atlas.zw), slope_x, slope_y);
}

float4 main(Varying input) : SV_Target0 {
    uint columns = 0u;
    uint rows = 0u;
    cells.GetDimensions(columns, rows);
    const float2 grid = float2(float(columns), float(rows));
    const float2 place = input.uv * grid;
    // Đạo hàm lấy trước mọi nhánh: chúng chỉ đúng khi cả bốn điểm của cụm cùng đi qua.
    const float2 cell_dx = ddx(place);
    const float2 cell_dy = ddy(place);
    const float2 cell = clamp(floor(place), float2(0.0, 0.0), grid - float2(1.0, 1.0));
    const float2 along = place - cell;
    const uint4 ground = uint4((cells.Load(int3(int(cell.x), int(cell.y), 0)) * 255.0) + 0.5);
    const uint base_id = ground.r | ((ground.b & 3u) << 8u);
    const uint cover_id = ground.g | (((ground.b >> 2u) & 3u) << 8u);
    const uint flip = (ground.b >> 4u) & 1u;
    // Ô không có cọ nền là lỗ của địa hình.
    if (base_id == 0u) discard;
    const float4 under = layer_sample(base_id, ground.a & 15u, flip, along, cell_dx, cell_dy);
    // Cọ nền luôn đục: màu thẳng, bỏ alpha.
    float3 color = (under.a > 0.0) ? (under.rgb / under.a) : float3(0.0, 0.0, 0.0);
    if (cover_id != 0u) {
        const float4 over = layer_sample(cover_id, ground.a >> 4u, flip, along, cell_dx, cell_dy);
        // Cọ phủ đã nhân alpha: over + nền * (1 - alpha của nó).
        color = over.rgb + (color * (1.0 - over.a));
    }
    // Lightmap nhân thẳng trong không gian gamma; trục z lật vì hàng đầu ảnh là biên z lớn. Lấy mẫu theo đạo
    // hàm đã tính trước: sau discard ở trên đạo hàm ngầm của cụm bốn điểm không còn đáng tin.
    const float2 light_at = float2(place.x / grid.x, 1.0 - (place.y / grid.y));
    const float2 light_dx = float2(cell_dx.x / grid.x, -cell_dx.y / grid.y);
    const float2 light_dy = float2(cell_dy.x / grid.x, -cell_dy.y / grid.y);
    color *= light_map.SampleGrad(light_sampler, light_at, light_dx, light_dy).rgb;
    const bool has_tint = (draw.flags & kVertexColor) != 0u;
    const float4 tint = has_tint ? input.color : float4(1.0, 1.0, 1.0, 1.0);
    const float alpha = draw.base_color.a * tint.a;
    if (alpha < draw.diffuse.a) discard;
    return finish_pixel(color * draw.base_color.rgb * tint.rgb, alpha, input);
}
