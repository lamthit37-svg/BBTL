#include "zone/aoi.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <cmath>

namespace game::zone {

Grid::Grid(Spec spec) : cell_cm_(spec.cell_cm), radius_(spec.radius) {
    core::check(spec.cell_cm > 0.0F && std::isfinite(spec.cell_cm), "cạnh ô vùng nhìn phải dương");
    core::check(spec.radius >= 0 && spec.radius <= 16, "bán kính vùng nhìn ngoài miền");
}

Cell Grid::cell_of(float x_cm, float z_cm) const noexcept {
    const auto clamp_axis = [](float value) {
        // NaN không thoả mọi so sánh: đưa về 0 để toạ độ hỏng không sinh chỉ số rác.
        if (std::isnan(value)) return 0.0F;
        return std::clamp(value, -kCoordLimitCm, kCoordLimitCm);
    };
    return Cell{.column = static_cast<std::int32_t>(std::floor(clamp_axis(x_cm) / cell_cm_)),
        .row = static_cast<std::int32_t>(std::floor(clamp_axis(z_cm) / cell_cm_))};
}

void Grid::insert(std::uint32_t entity, Cell cell) {
    cells_[key_of(cell)].push_back(entity);
    ++population_;
}

void Grid::erase(std::uint32_t entity, Cell cell) noexcept {
    const auto found = cells_.find(key_of(cell));
    if (found == cells_.end()) return;
    std::vector<std::uint32_t>& members = found->second;
    const auto member = std::ranges::find(members, entity);
    if (member == members.end()) return;
    // Giữ thứ tự vào ô: duyệt phải tất định (bỏ bằng erase, không hoán phần tử cuối). Ô nhỏ nên rẻ.
    members.erase(member);
    --population_;
    if (members.empty()) cells_.erase(found);
}

} // namespace game::zone
