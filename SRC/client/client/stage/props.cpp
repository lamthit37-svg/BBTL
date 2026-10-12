// Gom vật thể tĩnh của stage thành bảng nạp. Mesh trùng tên chỉ một dòng vì mỗi GLB chỉ đọc và
// tải lên GPU một lần; mỗi vật thể giữ chỉ số dòng đó và ma trận thế giới T * R * S của OGRE.
#include "client/stage/props.hpp"

#include "scene/transform.hpp"

#include <algorithm>
#include <cstddef>
#include <string>

namespace game::client {
namespace {

// Chỉ số mesh đã có, theo thứ tự gặp. Bằng meshes.size() khi chưa có. Một cảnh vài chục tên,
// quét thẳng rẻ hơn bảng băm.
[[nodiscard]] std::size_t find_mesh(const PropTable& table, const std::string& mesh) noexcept {
    const auto same_name = [&mesh](const std::string& one) { return one == mesh; };
    const auto found = std::ranges::find_if(table.meshes, same_name);
    return static_cast<std::size_t>(found - table.meshes.begin());
}

[[nodiscard]] std::size_t take_mesh(PropTable& table, const std::string& mesh) {
    const std::size_t found = find_mesh(table, mesh);
    if (found != table.meshes.size()) return found;
    table.meshes.push_back(mesh);
    return table.meshes.size() - 1;
}

} // namespace

PropTable table_of(const Stage& stage) {
    PropTable table;
    table.props.reserve(stage.props.size());
    for (const Prop& prop : stage.props) {
        PlacedProp placed;
        placed.mesh = take_mesh(table, prop.mesh);
        placed.world = scene::world_transform(prop.placement);
        table.props.push_back(placed);
    }
    return table;
}

} // namespace game::client
