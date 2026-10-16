/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/lod.hpp
 *  PHÂN HỆ   : Resource / Lod
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Mức chi tiết (LOD) cho lưới tĩnh. Mesh gốc của TLBB không có LOD: một cảnh
 *    đầy đủ vẽ ~1,3 triệu tam giác mỗi khung, phần lớn trên vật thể chỉ vài
 *    chục điểm ảnh. GPU tile-based của điện thoại (đo trên PowerVR GE8320) chết
 *    vì số tam giác, không phải vì điểm ảnh. build_lods giảm tam giác bằng
 *    meshoptimizer (quadric, có tính normal, uv, màu đỉnh) và chỉ sinh chỉ số:
 *    mọi mức dùng chung buffer đỉnh với mức 0.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "resource/model.hpp"

namespace game::resource {

// Điền Primitive::lods cho mọi primitive tam giác không morph (kể cả có skin: mức thô chỉ chọn lại chỉ số) đủ lớn. Không đụng GPU; gọi ở
// luồng nạp. Primitive nhỏ hoặc không giảm nổi thì lods để rỗng.
void build_lods(Model& model);

// Chia primitive tam giác thành khối vuông cạnh span (đơn vị thế giới, theo trục x và z) bằng cách sắp lại tam giác theo ô
// chứa trọng tâm của chúng, rồi điền Primitive::tiles. Đỉnh giữ nguyên; thứ tự tam giác trong cùng khối giữ như cũ. Bỏ qua
// (không đổi gì) khi span không dương, chỉ số ngoài đỉnh, hoặc số khối vượt trần.
void build_tiles(Primitive& primitive, float span);

} // namespace game::resource
