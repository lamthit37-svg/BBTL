// collision/transform.hpp — biến đổi đỉnh mã 2 (0xFF000002) của BuildingCollision.
// Thứ tự từng phép f32 bám đúng DLL gốc theo so-do/b-bien-doi-thu-tu.md:
// toàn bộ SSE vô hướng, mỗi phép một biến float, không FMA, không gộp biểu thức,
// chia thật (divss) ở hai chỗ (1/w và chia tỉ lệ khung). Cộng số hạng y trước x.
// Dùng chung kiểu của bộ đọc (Frame, Placement, Point3) trong building_file.hpp.
#ifndef GAME_COLLISION_TRANSFORM_HPP
#define GAME_COLLISION_TRANSFORM_HPP

#include <array>

#include "collision/building_file.hpp"

namespace game::collision::detail {

// Ma trận 4x4 hàng-chính, véc-tơ cột (giống bố cục DLL dựng ở 0x180001f80).
using Mat4 = std::array<std::array<float, 4>, 4>;

// Tích hai ma trận 4x4; mỗi ô ((a0*b0 + a1*b1) + a2*b2) + a3*b3, giữ cả số 0 và 1
// để dấu của 0 ra đúng như DLL. Mọi chỉ số đều là hằng biên dịch, không vòng lặp.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): (trái, phải) của phép nhân ma trận, đổi chỗ đổi kết quả.
[[nodiscard]] inline Mat4 mat_mul(const Mat4& lhs, const Mat4& rhs) noexcept {
    Mat4 out{};
    out[0][0] = (((lhs[0][0] * rhs[0][0]) + (lhs[0][1] * rhs[1][0])) + (lhs[0][2] * rhs[2][0])) + (lhs[0][3] * rhs[3][0]);
    out[0][1] = (((lhs[0][0] * rhs[0][1]) + (lhs[0][1] * rhs[1][1])) + (lhs[0][2] * rhs[2][1])) + (lhs[0][3] * rhs[3][1]);
    out[0][2] = (((lhs[0][0] * rhs[0][2]) + (lhs[0][1] * rhs[1][2])) + (lhs[0][2] * rhs[2][2])) + (lhs[0][3] * rhs[3][2]);
    out[0][3] = (((lhs[0][0] * rhs[0][3]) + (lhs[0][1] * rhs[1][3])) + (lhs[0][2] * rhs[2][3])) + (lhs[0][3] * rhs[3][3]);
    out[1][0] = (((lhs[1][0] * rhs[0][0]) + (lhs[1][1] * rhs[1][0])) + (lhs[1][2] * rhs[2][0])) + (lhs[1][3] * rhs[3][0]);
    out[1][1] = (((lhs[1][0] * rhs[0][1]) + (lhs[1][1] * rhs[1][1])) + (lhs[1][2] * rhs[2][1])) + (lhs[1][3] * rhs[3][1]);
    out[1][2] = (((lhs[1][0] * rhs[0][2]) + (lhs[1][1] * rhs[1][2])) + (lhs[1][2] * rhs[2][2])) + (lhs[1][3] * rhs[3][2]);
    out[1][3] = (((lhs[1][0] * rhs[0][3]) + (lhs[1][1] * rhs[1][3])) + (lhs[1][2] * rhs[2][3])) + (lhs[1][3] * rhs[3][3]);
    out[2][0] = (((lhs[2][0] * rhs[0][0]) + (lhs[2][1] * rhs[1][0])) + (lhs[2][2] * rhs[2][0])) + (lhs[2][3] * rhs[3][0]);
    out[2][1] = (((lhs[2][0] * rhs[0][1]) + (lhs[2][1] * rhs[1][1])) + (lhs[2][2] * rhs[2][1])) + (lhs[2][3] * rhs[3][1]);
    out[2][2] = (((lhs[2][0] * rhs[0][2]) + (lhs[2][1] * rhs[1][2])) + (lhs[2][2] * rhs[2][2])) + (lhs[2][3] * rhs[3][2]);
    out[2][3] = (((lhs[2][0] * rhs[0][3]) + (lhs[2][1] * rhs[1][3])) + (lhs[2][2] * rhs[2][3])) + (lhs[2][3] * rhs[3][3]);
    out[3][0] = (((lhs[3][0] * rhs[0][0]) + (lhs[3][1] * rhs[1][0])) + (lhs[3][2] * rhs[2][0])) + (lhs[3][3] * rhs[3][0]);
    out[3][1] = (((lhs[3][0] * rhs[0][1]) + (lhs[3][1] * rhs[1][1])) + (lhs[3][2] * rhs[2][1])) + (lhs[3][3] * rhs[3][1]);
    out[3][2] = (((lhs[3][0] * rhs[0][2]) + (lhs[3][1] * rhs[1][2])) + (lhs[3][2] * rhs[2][2])) + (lhs[3][3] * rhs[3][2]);
    out[3][3] = (((lhs[3][0] * rhs[0][3]) + (lhs[3][1] * rhs[1][3])) + (lhs[3][2] * rhs[2][3])) + (lhs[3][3] * rhs[3][3]);
    return out;
}

// Quaternion thô w,x,y,z -> ma trận quay 4x4 (không chuẩn hoá), 3x3 ở góc trên.
[[nodiscard]] inline Mat4 rotation_matrix(const std::array<float, 4>& quat) noexcept {
    const float quat_w = quat[0];
    const float quat_x = quat[1];
    const float quat_y = quat[2];
    const float quat_z = quat[3];
    const float two_x = quat_x * 2.0F;
    const float two_y = quat_y * 2.0F;
    const float two_z = quat_z * 2.0F;
    const float prod_xx = quat_x * two_x;
    const float prod_yy = quat_y * two_y;
    const float prod_zz = quat_z * two_z;
    const float prod_wx = quat_w * two_x;
    const float prod_wy = quat_w * two_y;
    const float prod_wz = quat_w * two_z;
    const float prod_xy = quat_x * two_y;
    const float prod_xz = quat_x * two_z;
    const float prod_yz = quat_y * two_z;
    const float r00 = 1.0F - (prod_zz + prod_yy);
    const float r01 = prod_xy - prod_wz;
    const float r02 = prod_xz + prod_wy;
    const float r10 = prod_xy + prod_wz;
    const float r11 = 1.0F - (prod_zz + prod_xx);
    const float r12 = prod_yz - prod_wx;
    const float r20 = prod_xz - prod_wy;
    const float r21 = prod_yz + prod_wx;
    const float r22 = 1.0F - (prod_yy + prod_xx);
    return Mat4{{
        {{r00, r01, r02, 0.0F}},
        {{r10, r11, r12, 0.0F}},
        {{r20, r21, r22, 0.0F}},
        {{0.0F, 0.0F, 0.0F, 1.0F}},
    }};
}

// Ma trận tịnh tiến 4x4: đơn vị + vị trí ở cột 3.
[[nodiscard]] inline Mat4 translation_matrix(const Point3& pos) noexcept {
    return Mat4{{
        {{1.0F, 0.0F, 0.0F, pos.x}},
        {{0.0F, 1.0F, 0.0F, pos.y}},
        {{0.0F, 0.0F, 1.0F, pos.z}},
        {{0.0F, 0.0F, 0.0F, 1.0F}},
    }};
}

// Ma trận tỉ lệ 4x4: tỉ lệ ở đường chéo.
[[nodiscard]] inline Mat4 scale_matrix(const Point3& scl) noexcept {
    return Mat4{{
        {{scl.x, 0.0F, 0.0F, 0.0F}},
        {{0.0F, scl.y, 0.0F, 0.0F}},
        {{0.0F, 0.0F, scl.z, 0.0F}},
        {{0.0F, 0.0F, 0.0F, 1.0F}},
    }};
}

// Nhân đỉnh với M, phối cảnh (r = 1/w) rồi đổi về toạ độ game theo khung.
// Cộng số hạng y TRƯỚC số hạng x; chia thật divss ở 1/w và ở tỉ lệ khung.
[[nodiscard]] inline Point3
project_vertex(const Mat4& mat, const Frame& frame, Point3 vtx) noexcept {
    const float vtx_x = vtx.x;
    const float vtx_y = vtx.y;
    const float vtx_z = vtx.z;
    const float per_w = (((mat[3][1] * vtx_y) + (mat[3][0] * vtx_x)) + (mat[3][2] * vtx_z)) + mat[3][3];
    const float inv_w = 1.0F / per_w;
    const float proj_x = ((((mat[0][1] * vtx_y) + (mat[0][0] * vtx_x)) + (mat[0][2] * vtx_z)) + mat[0][3]) * inv_w;
    const float proj_y = ((((mat[1][1] * vtx_y) + (mat[1][0] * vtx_x)) + (mat[1][2] * vtx_z)) + mat[1][3]) * inv_w;
    const float proj_z = ((((mat[2][1] * vtx_y) + (mat[2][0] * vtx_x)) + (mat[2][2] * vtx_z)) + mat[2][3]) * inv_w;
    const float out_x = (proj_x - frame.origin.x) / frame.scale.x;
    const float out_y = (proj_y - frame.origin.y) / frame.scale.y;
    const float out_z = (proj_z - frame.origin.z) / frame.scale.z;
    return Point3{.x = out_x, .y = out_y, .z = out_z};
}

// Biến đổi một đỉnh nguồn của một khối theo khung + lượt đặt mã 2, ra toạ độ game.
[[nodiscard]] inline Point3
transform_vertex(const Frame& frame, const Placement& placement, Point3 vtx) noexcept {
    const Mat4 mat_r = rotation_matrix(placement.rotation);
    const Mat4 mat_t = translation_matrix(placement.position);
    const Mat4 mat_s = scale_matrix(placement.scale);
    const Mat4 mat_tr = mat_mul(mat_t, mat_r);
    const Mat4 mat_m = mat_mul(mat_tr, mat_s);
    return project_vertex(mat_m, frame, vtx);
}

}  // namespace game::collision::detail

#endif  // GAME_COLLISION_TRANSFORM_HPP
