// collision/opcode_tree.hpp — cây OPCODE 1.3 AABBQuantizedNoLeafTree mà Model::Build (0x180037330) của
// PathLib.dll dựng lúc nạp, vai C, B3. Theo so-do/b-b1-opcode-cay.md (mục 3 tới 6, 11) và công thức vòng sửa
// 0xFFFF trong so-do/b-fenghuang-bo.md mục 5:
// - AABBTree đủ (mLimit 1, mRules 0x22 = SPLATTER_POINTS | GEOM_CENTER): trục chia là trục phương sai tâm lớn
//   nhất, giá trị chia là trung bình đỉnh (sum / 3n, chia thật), phân hoạch hoán đổi không ổn định, chia hỏng
//   thì n >> 1; hộp mỗi nút là min/max đỉnh (bằng nhau lấy giá trị mới), tâm = (mn + mx) * 0.5, nửa cạnh =
//   (mx − mn) * 0.5.
// - Cây không lá: n − 1 nút trong, tiền thứ tự, con dương trước; lá mã hoá (tam giác << 1) | 1.
// - Lượng tử: tâm s16 = cvttss2si32(CQ * c), nửa cạnh u16 = cvttss2si64(EQ * e) (16 bit thấp), CQ = 32767 / CMax,
//   EQ = 32767 / EMax; rồi vòng sửa gFixQuantized giữ TRUNG THÀNH cả hành vi VƯỢT: tăng gói 16 bit, kiểm "bằng 0
//   thì 0xFFFF" sau MỌI vòng (nửa cạnh lượng tử 0 với tâm đúng cũng thành 0xFFFF). Không "sửa cho chặt hơn".
// Mọi phép f32 vô hướng, đúng nhóm như mã máy; biên dịch -ffp-contract=off (GCC, Clang) hay /fp:precise (MSVC).
#pragma once

#include "collision/building_file.hpp"
#include "collision/mesh.hpp"

#include <array>
#include <cstdint>
#include <expected>
#include <vector>

namespace game::collision::detail {

// Khác gốc (chống tệp hỏng): trần tổng số lượt tam giác mà các lần chia đi qua (tổng độ sâu lá). Phân hoạch
// gốc có thể suy biến thành O(n^2); trên cảnh thật tổng này dưới 2e7 (bianjing). Vượt trần thì không dựng.
inline constexpr std::uint64_t kMaxSplitWork = std::uint64_t{1} << 28U;

// Một nút của mNodes (AABBQuantizedNoLeafNode, 0x20 byte trong DLL). positive, negative: lá là
// (tam giác << 1) | 1 như DLL; nút trong là (chỉ số nút << 1), thay cho con trỏ của DLL.
struct QuantizedNode {
    std::array<std::int16_t, 3> center{};
    std::array<std::uint16_t, 3> extents{};
    std::uint32_t positive = 0;
    std::uint32_t negative = 0;
};

[[nodiscard]] constexpr bool is_leaf(std::uint32_t child) noexcept {
    return (child & 1U) != 0;
}
[[nodiscard]] constexpr std::uint32_t child_index(std::uint32_t child) noexcept {
    return child >> 1U;
}

enum class TreeShape : std::uint8_t {
    kInvalid, // MeshInterface::IsValid sai (NbTris hay NbVerts bằng 0): Build trả false, mọi truy vấn false
    kSingle, // NbTris == 1: OPC_SINGLE_NODE, không cấp phát cây
    kTree, // NbTris >= 2: nodes có NbTris − 1 nút
};

struct OpcodeTree {
    TreeShape shape = TreeShape::kInvalid;
    std::vector<QuantizedNode> nodes;
    Point3 center_coeff; // mCenterCoeff (Tree +0x18)
    Point3 extents_coeff; // mExtentsCoeff (Tree +0x24)
};

enum class [[nodiscard]] TreeError : std::uint8_t {
    kTooMuchWork, // vượt kMaxSplitWork (khác gốc)
};

// cvttss2si 32 và 64 bit: cắt về 0; NaN hay ngoài tầm cho số nguyên nhỏ nhất (0x80000000...), không UB.
[[nodiscard]] std::int32_t truncate_to_int32(float value) noexcept;
[[nodiscard]] std::int64_t truncate_to_int64(float value) noexcept;

// Vòng sửa gFixQuantized 0x18003d350..0x18003d3d4 trên một trục, viết đúng từng vòng như mã máy (tối đa 65536
// vòng): top = extent + center, bottom = center − extent; qe = f32(q) * extents_coeff; tăng gói khi
// top > qe + qc hay qc − qe > bottom; q == 0 sau vòng thì 0xFFFF và dừng; không tăng thì dừng.
[[nodiscard]] std::uint16_t fix_extent_reference(std::uint16_t quantized, float center, float extent,
    float dequantized_center, float extents_coeff) noexcept;

// Cùng kết quả với fix_extent_reference trên mọi đầu vào, nhưng tìm nhị phân điểm dừng khi extents_coeff >= 0
// (luôn đúng trừ NaN: 1 / EQ với EQ >= 0): điều kiện tăng đơn điệu theo q, nên không phải đi 65536 vòng mỗi trục
// (EMax = 0 với tâm lệch). extents_coeff âm hay NaN thì chạy đúng bản từng vòng.
[[nodiscard]] std::uint16_t fix_extent(std::uint16_t quantized, float center, float extent,
    float dequantized_center, float extents_coeff) noexcept;

// Model::Build trên NbTris tam giác đầu của lưới.
[[nodiscard]] std::expected<OpcodeTree, TreeError> build_tree(const Mesh& mesh);

} // namespace game::collision::detail
