// Đọc .mesh OGRE (serializer 1.30 và 1.40) thành Model. Không gắn đuôi .glb.
// Lần đầu nấu đỉnh và chỉ số bằng meshoptimizer vào cache/mesh, lần sau chỉ giải cache.
#pragma once

#include "core/error.hpp"
#include "resource/model.hpp"

#include <span>
#include <string_view>

namespace game::resource {

// `bytes` là cả tệp .mesh. Hình học và chỉ số giữ nguyên đơn vị, không đổi thứ tự.
[[nodiscard]] core::Result<Model> load_ogre_mesh(std::span<const std::byte> bytes, std::string_view data_root = {},
    TextureTier tier = TextureTier::kBc);

// `name` là tên trong cảnh hoặc bảng, ví dụ "大理/大理城门.mesh". Có đuôi thì mở đúng tệp đó.
// Không đuôi thì ưu tiên .mesh đang có, rồi .glb. Không bịa một danh sách tên.
[[nodiscard]] core::Result<Model> load_named_model(std::string_view name, std::string_view data_root,
    TextureTier tier = TextureTier::kBc);

} // namespace game::resource
