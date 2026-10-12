#pragma once
// Xương đã dựng để ra ma trận skin. Port từ OGRE 1.2.5 trong _ref: Skeleton::setBindingPose,
// Skeleton::_updateTransforms, Skeleton::_getBoneMatrices, Bone::setBindingPose,
// Bone::_getOffsetTransform, Node::_updateFromParent và Matrix4::makeTransform. Xương đánh số theo
// handle như mBoneList của OGRE, nên handle phải liền từ 0.
//
// Lệch có chủ đích so với OGRE: bảng xương của submesh trỏ handle không có trong skeleton thì ra ma
// trận đơn vị. OGRE tra ma trận không kiểm biên (UB); trên _ref có 660 bản ghi gán xương như vậy ở
// 7 mesh, ví dụ thân của Trương Hàm Chi dùng handle 28 tới 39 trên skeleton chỉ có 28 xương.
// Nguồn: TLBB Dev src/anim/rig.hpp@e0d89a6. Khác gốc: namespace game::anim, kiểu toán ở game::ogre;
// enumerator mang tiền tố k; Rig::create nhận SourceSkeleton của anim/asset.hpp.

#include "anim/asset.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <vector>

namespace game::anim {

// Vị trí, hướng và scale của một xương: so với cha khi là biến đổi cục bộ, so với gốc model khi là
// biến đổi derived.
struct Transform {
    ogre::Vec3 position;
    ogre::Quat orientation;
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
};

// Ma trận affine 3x4 theo hàng, đúng ba hàng đầu của Matrix4 OGRE: cột cuối là phần dịch.
using Affine = std::array<float, 12>;

inline constexpr Affine kIdentityAffine = {1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F};

enum class RigError : std::uint8_t { kEmpty, kBadHandle, kDuplicateHandle, kBadParent, kSecondParent, kCycle };

// Tên ngắn để chữ ký dựng rig nằm một dòng.
using RigResult = std::expected<class Rig, RigError>;

class Rig {
public:
    // Kiểm handle liền từ 0 không trùng, cạnh cha con trỏ xương có thật, mỗi xương tối đa một cha,
    // không có vòng; rồi lấy tư thế trong tệp làm bind pose như Skeleton::setBindingPose.
    [[nodiscard]] static RigResult create(const SourceSkeleton& skeleton);

    [[nodiscard]] std::size_t size() const { return initial_.size(); }

    // Biến đổi cục bộ của bind pose theo handle, tức trạng thái đầu của từng xương.
    [[nodiscard]] std::span<const Transform> initial() const { return initial_; }

    // Ma trận skin của từng xương từ tư thế cục bộ, một phần tử mỗi handle; tư thế sai số xương thì
    // trả dãy rỗng.
    [[nodiscard]] std::vector<Affine> skin(std::span<const Transform> local) const;

    // Ma trận skin CÙNG biến đổi derived của từng xương, đi cây MỘT lượt: đường vẽ cần cả hai khi
    // locator đặt theo xương, gọi skin() rồi derive() riêng là đi cây hai lần mỗi khung. Dãy do
    // người gọi giữ, nạp lại qua mỗi khung để không cấp phát. Tư thế sai số xương thì cả hai rỗng.
    void skin(std::span<const Transform> local, std::vector<Affine>& out_skin,
        std::vector<Transform>& out_derived) const;

    // Biến đổi derived của từng xương theo handle, tức vị trí, hướng, scale trong không gian mẫu mà
    // Bone::_getDerivedPosition, _getDerivedOrientation, _getDerivedScale trả sau khi skeleton tạo
    // dáng theo tư thế cục bộ local (bind_pose rồi apply của khung đang vẽ). Gọi với đúng tư thế đã
    // ra ma trận skin của khung, để locator đặt theo xương khớp lưới; tư thế sai số xương thì trả
    // dãy rỗng.
    [[nodiscard]] std::vector<Transform> derive(std::span<const Transform> local) const;

private:
    Rig() = default;

    std::vector<Transform> initial_;
    std::vector<std::int32_t> parent_; // -1 là xương gốc
    std::vector<std::uint16_t> order_; // cha đứng trước con
    std::vector<Transform> bind_inverse_;
};

// Node::_updateFromParent với mInheritOrientation và mInheritScale bật (mặc định của Node): biến
// đổi local của một nút so với cha đổi ra không gian mà cha parent đang ở. Xương ghép cây bằng nó;
// client đưa locator và mẫu con ra thế giới bằng nó. Quaternion không đơn vị giữ nguyên, không
// chuẩn hoá.
[[nodiscard]] Transform from_parent(const Transform& parent, const Transform& local);

// Ma trận cho bảng xương của một submesh, theo thứ tự bảng.
[[nodiscard]] std::vector<Affine> palette_matrices(std::span<const Affine> skin,
    std::span<const std::uint16_t> palette);

// Như trên, nhưng nạp vào dãy người gọi giữ: đường vẽ gọi mỗi khung cho mọi thành phần.
void palette_matrices(std::span<const Affine> skin, std::span<const std::uint16_t> palette, std::vector<Affine>& out);

// Skeleton mở rộng (docs/NGOAI-HINH.md của TLBB, mục Skeleton mở rộng): lưới bộ phận của client
// 2026 liên kết skeleton riêng gồm đủ xương chính theo tên (handle khác) cộng xương vải, tóc bay.
// Bộ phận vẽ bằng ma trận skin của skeleton chính: bảng xương của nó đổi handle riêng sang handle
// chính.

// Handle không có trong skeleton chính; palette_matrices cho nó ma trận đơn vị.
inline constexpr std::uint16_t kUnknownBone = 0xFFFF;

enum class RetargetError : std::uint8_t { kOrphan };

// Bảng handle của retarget, hay lỗi; tên ngắn để chữ ký nằm một dòng.
using RetargetResult = std::expected<std::vector<std::uint16_t>, RetargetError>;

// Bảng handle của own sang main, phần tử thứ h cho handle h của own: xương cùng tên lấy handle của
// main; xương thêm lấy handle của tổ tiên gần nhất có trong main, nên đi cứng theo nó ở tư thế
// nghỉ (DynamicBone chưa mô phỏng). Orphan khi xương thêm không có tổ tiên nào trong main.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): own, main khác vai (HP-07)
[[nodiscard]] RetargetResult retarget(const SourceSkeleton& own, const SourceSkeleton& main);

// Đổi một bảng xương (của submesh) theo map của retarget; handle ngoài map thành kUnknownBone.
void retarget_palette(std::span<std::uint16_t> palette, std::span<const std::uint16_t> map);

} // namespace game::anim
