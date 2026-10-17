/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/bound.hpp
 *  PHÂN HỆ   : Render / Bound
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hộp bao chính xác để bỏ lệnh vẽ ngoài khung nhìn: hộp của primitive qua
 *    ma trận affine bất kỳ, và hộp của lưới skin ở tư thế của khung dựng từ
 *    hộp theo khớp. Thuần CPU, kiểm được không cần GPU.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Vì sao hộp theo khớp bao trọn lưới skin: model.vs đưa đỉnh v có tổng trọng số t > 0 tới
// Σ (w_k / t) · M_k v, một tổ hợp lồi của các điểm M_k v. Mỗi M_k v nằm trong ảnh của hộp khớp k
// qua M_k (v thuộc hộp đó vì w_k > 0), nên đỉnh nằm trong bao lồi của các ảnh ấy, tức trong hộp hợp
// của chúng. Đỉnh có t = 0 đứng yên ở v. Trọng số âm phá tính lồi: lưới như vậy không có hộp.
#pragma once

#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "render/camera.hpp"
#include "resource/model.hpp"

#include <cstdint>
#include <optional>
#include <span>
#include <vector>

namespace game::render {

// Hộp bao đỉnh của một lưới có skin trong không gian bind của lưới, chia theo khớp của skin.
struct SkinBox {
    // Hộp khớp j chứa mọi đỉnh có trọng số dương ở khớp j (chỉ số khớp đã kẹp như model.vs).
    std::vector<math::Aabb> joints;
    // Đỉnh mà shader để yên (tổng trọng số không dương): ở không gian instance, không qua khớp nào.
    math::Aabb still;
    // Sai khi lưới có trọng số âm hay số không hữu hạn: không có hộp nào bảo đảm, luôn vẽ.
    bool is_bounded = false;
};

// Hộp rỗng (min > max ở một trục) không chứa điểm nào.
[[nodiscard]] bool is_empty(const math::Aabb& box) noexcept;

// Hộp nhỏ nhất chứa vị trí của mọi đỉnh; rỗng khi không có đỉnh.
[[nodiscard]] math::Aabb box_of(std::span<const resource::Vertex> vertices) noexcept;

// Hộp theo trục chứa ảnh của box qua ba hàng đầu của matrix (như shader đọc ma trận affine).
[[nodiscard]] math::Aabb moved_box(const math::Aabb& box, const math::Matrix4& matrix) noexcept;

// Hộp theo khớp của mọi đỉnh trong parts, với skin có joint_count khớp (khác 0).
[[nodiscard]] SkinBox skin_box(std::span<const resource::Primitive> parts,
    std::uint32_t joint_count);

// Hộp của lưới skin khi khớp j đứng ở joints[j], trong không gian instance. Rỗng khi bound không
// bảo đảm được hay số khớp lệch: nơi gọi coi như còn thấy.
[[nodiscard]] std::optional<math::Aabb> posed_box(const SkinBox& bound,
    std::span<const math::Matrix4> joints) noexcept;

// Hộp còn chạm khung nhìn hay không: chỉ loại khi nằm hẳn ngoài một mặt. Hộp rỗng không thấy.
[[nodiscard]] bool box_seen(const Frustum& frustum, const math::Aabb& box) noexcept;

} // namespace game::render
