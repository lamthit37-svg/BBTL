#include "client/props.hpp"

#include "client/stage.hpp"
#include "scene/transform.hpp"

#include <algorithm>
#include <cstddef>
#include <string>

namespace game::client {
namespace {

// Chỉ số của mesh đã có trong bảng, theo thứ tự gặp; npos khi chưa có. Số mesh duy nhất của một
// cảnh bằng vài chục nên quét thẳng là đủ; bảng băm chỉ thêm chi phí ở cỡ này.
[[nodiscard]] std::size_t find_mesh(const PropTable& table, const std::string& mesh) noexcept {
    const auto same_name = [&mesh](const std::string& one) { return one == mesh; };
    const auto found = std::ranges::find_if(table.meshes, same_name);
    return static_cast<std::size_t>(found - table.meshes.begin());
}

// Chỉ số của mesh trong bảng, thêm vào cuối khi chưa có.
[[nodiscard]] std::size_t take_mesh(PropTable& table, const std::string& mesh) {
    const std::size_t found = find_mesh(table, mesh);
    const bool is_new = found == table.meshes.size();
    if (is_new) table.meshes.push_back(mesh);
    return is_new ? table.meshes.size() - 1 : found;
}

} // namespace

PropTable table_of(const Stage& stage) {
    PropTable table;
    table.props.reserve(stage.props.size());
    for (const Prop& prop : stage.props) {
        PlacedProp& placed = table.props.emplace_back();
        placed.mesh = take_mesh(table, prop.mesh);
        placed.world = scene::world_transform(prop.placement);
    }
    return table;
}

} // namespace game::client
