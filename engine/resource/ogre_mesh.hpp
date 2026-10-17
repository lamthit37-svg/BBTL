/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/ogre_mesh.hpp
 *  PHÂN HỆ   : Resource / Ogre Mesh
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc .mesh OGRE thành Model. Đường material chồng không ghi cache .tlms
 *    của lưới gốc, vì khoá cache chỉ là đường tệp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/error.hpp"
#include "resource/model.hpp"

#include <span>
#include <string>
#include <string_view>

namespace game::resource {

// `bytes` là cả tệp .mesh. Hình học và chỉ số giữ nguyên đơn vị, không đổi thứ tự.
[[nodiscard]] core::Result<Model> load_ogre_mesh(std::span<const std::byte> bytes, std::string_view data_root = {},
    TextureTier tier = TextureTier::kBc);

// Mức chi tiết mà cache .tlms mang sẵn: kKeep trả chúng kèm Model::has_lods, kDrop bỏ.
enum class LodUse : std::uint8_t { kDrop, kKeep };

// `name` là tên trong cảnh hoặc bảng, ví dụ "大理/大理城门.mesh". Có đuôi thì mở đúng tệp đó.
// Không đuôi thì ưu tiên .mesh đang có, rồi .glb. Không bịa một danh sách tên. Cache .mesh ghi
// kèm mức chi tiết của build_lods để máy chạy khỏi giản lược; .glb không có cache nên không mang.
[[nodiscard]] core::Result<Model> load_named_model(std::string_view name,
    std::string_view data_root, TextureTier tier = TextureTier::kBc, LodUse lods = LodUse::kDrop);

// Đổi tên material từng submesh rồi tra all.material. Ô rỗng giữ tên trong lưới.
// Không ghi cache .tlms: khoá cache là đường mesh, bản chồng sẽ làm hỏng bản gốc.
[[nodiscard]] core::Result<Model> load_mesh_painted(std::string_view name,
    std::string_view data_root, std::span<const std::string> materials,
    TextureTier tier = TextureTier::kBc);

} // namespace game::resource
