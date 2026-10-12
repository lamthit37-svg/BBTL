// Phép biến đổi đặt một vật thể của cảnh vào thế giới, tính từ scene::Placement đúng như client
// gốc: tỉ lệ trước, quay sau, dời cuối (ma trận T * R * S với vectơ cột), hệ tay phải, Y hướng lên.
// Nguồn port: OGRE 1.2.5 của client 2008 (G:\TLBB\_ref, OgreMain/src) — Matrix4::makeTransform,
// Quaternion::ToRotationMatrix, Node::setOrientation. Giữ nguyên các điểm sau của bản gốc:
// - ma trận quay tính thẳng từ quaternion đọc trong tệp, KHÔNG chuẩn hoá (setOrientation chỉ gán);
// - công thức và thứ tự phép tính của ToRotationMatrix.
// Khác gốc: gốc tính bằng float (Real); ở đây tính bằng double trên chính các số float đã đọc, để
// hộp bao thế giới so được với phép tính độc lập ở mức 0,001 đơn vị khi toạ độ lên tới hàng chục
// nghìn (float chỉ còn bước 0,001 quanh 8192). Ma trận gửi cho GPU là bản này làm tròn về float.
#pragma once

#include "scene/placement.hpp"

#include <array>

namespace game::scene {

struct Point {
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
};

// Hộp bao theo trục; low không lớn hơn high ở cả ba trục.
struct Box {
    Point low;
    Point high;
};

// Ba hàng đầu của ma trận 4x4 [R * S | T]; rows[i][j] là hàng i, cột j, cột 3 là phép dời. Hàng
// thứ tư luôn là 0 0 0 1 nên không lưu.
struct Transform {
    std::array<std::array<double, 4>, 3> rows{};
};

// Phép biến đổi của một phép đặt.
[[nodiscard]] Transform world_transform(const Placement& placement) noexcept;

// Điểm sau khi biến đổi.
[[nodiscard]] Point apply(const Transform& transform, const Point& point) noexcept;

// Hộp bao theo trục của tám góc hộp local sau khi biến đổi.
[[nodiscard]] Box world_box(const Transform& transform, const Box& local) noexcept;

} // namespace game::scene
