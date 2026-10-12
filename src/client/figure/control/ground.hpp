#pragma once
// Mặt đất của một cảnh theo client gốc: đổi toạ độ game (ô lưới) sang thế giới và ngược lại, độ cao
// tại một điểm, và điểm đầu tiên một tia chạm mặt đất. Port ngữ nghĩa từ ref:
// - WXCore/Core/TerrainData.cpp: getHeightAt, getIntersects, _intersectGrid, getBoundBox;
// - CRenderSystem::Axis_Trans: thế giới = position + game * scale, game = (thế giới - position) /
//   scale;
// - OgreMath.cpp: giao tia với hộp và tia với tam giác.
// Toán tử và thứ tự giữ như bản gốc. fast_int và fast_ifloor (mẹo bit của ieee.h) thành std::trunc
// và std::floor, cùng kết quả trong miền toạ độ của map.
// Gốc là vị trí thế giới của đỉnh (0, 0) và hướng đường chéo mỗi ô là cờ lật của ô (.GridInfo),
// cùng gốc và cùng đường chéo với lưới vẽ, nên độ cao nội suy nằm đúng trên tam giác được vẽ. Lệch
// có chủ đích so với ref: tia có thành phần không hữu hạn thì không chạm, thay cho assert của bản
// gốc trong vòng duyệt ô. Nguồn: TLBB Dev src/control/ground.hpp và ground.cpp@e0d89a6. Khác gốc:
// namespace game::control, kiểu toán ở game::ogre; Ground dựng từ GroundShape của dự án thay cho dữ
// liệu đã nấu của TLBB; chưa có mặt công trình (WalkMap); vòng xét bốn ô quanh đỉnh của
// touches_sphere tách thành camera_boxes (cổng cấm if trong vòng lặp), cùng phép tính.

#include "core/ground_point.hpp"
#include "ogre/vec3.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <vector>

namespace game::control {

// Tia trong toạ độ thế giới; direction không cần là vector đơn vị.
struct Ray {
    ogre::Vec3 origin;
    ogre::Vec3 direction;
};

// Hình dạng mặt đất: gốc và tỉ lệ thế giới, số ô, độ cao thô của từng đỉnh (hàng theo z, mỗi hàng
// x_size + 1 đỉnh) và cờ lật đường chéo của từng ô (hàng theo z, x_size ô; rỗng là mọi ô không
// lật).
struct GroundShape {
    ogre::Vec3 position;
    ogre::Vec3 scale{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    int x_size = 0;
    int z_size = 0;
    std::vector<float> heights;
    std::vector<bool> flipped;
};

// Ô hay đỉnh của lưới: cột theo x, hàng theo z.
struct GridCell {
    int column = 0;
    int row = 0;
};

// Kết quả thử quả cầu mắt camera với các ô quanh nó.
enum class EyeProbe : std::uint8_t { kClear, kTouching, kNoPatch };

class Ground {
public:
    // Hộp trục thẳng trong toạ độ thế giới.
    struct Box {
        ogre::Vec3 low;
        ogre::Vec3 high;
    };

    // Ô lật chia đường chéo nối (x, z) với (x + 1, z + 1); mặc định đường chéo nối (x + 1, z) với
    // (x, z + 1). nullopt khi kích thước bằng 0, tỉ lệ không dương, lưới độ cao không đủ một đỉnh
    // mỗi góc ô, hay flipped không rỗng mà không đúng x_size * z_size ô.
    [[nodiscard]] static std::optional<Ground> create(GroundShape shape);

    // Thế giới từ toạ độ game: x, z theo Axis_Trans, độ cao là độ cao địa hình ở đó.
    [[nodiscard]] ogre::Vec3 to_world(core::GroundPoint point) const;
    [[nodiscard]] core::GroundPoint to_game(ogre::Vec3 world) const;

    // Độ cao thế giới tại (x, z) thế giới, nội suy trên một trong hai tam giác của ô; ngoài map thì
    // độ cao ở mép gần nhất.
    [[nodiscard]] float height_at(float world_x, float world_z) const;

    // Điểm đầu tiên tia chạm mặt trên của địa hình; chỉ tính tia đi xuống mặt, như mặc định
    // positiveSide của getIntersects.
    [[nodiscard]] std::optional<ogre::Vec3> intersect(Ray ray) const;

    // Hệ số đổi một đơn vị game sang thế giới theo trục đứng; camera dùng cho khoảng cách.
    [[nodiscard]] float vertical_scale() const noexcept { return scale_.y; }
    // Căn bậc hai tỉ lệ x nhân z, mBaseScale của WXSystem.cpp: thước cho mặt gần và xa của camera.
    [[nodiscard]] float base_scale() const noexcept;

    // Mắt camera (quả cầu tâm center) so với địa hình, như _IsValidEye của Camera_Scene.cpp: xét
    // các ô quanh đỉnh lưới gần nhất, mỗi ô là hộp từ âm vô cùng tới góc cao nhất của ô. Tâm ngoài
    // map, hay quanh đỉnh không có đúng 2 hoặc 4 ô (góc map), là kNoPatch như _GetInterPatch trả
    // FALSE: chỗ gọi tự quyết coi đó là trống hay vướng.
    [[nodiscard]] EyeProbe probe_sphere(ogre::Vec3 center, float radius) const;
    // Quả cầu chạm một ô; không lấy được ô thì coi như không chạm.
    [[nodiscard]] bool touches_sphere(ogre::Vec3 center, float radius) const;

private:
    Ground() = default;

    [[nodiscard]] float raw_height(GridCell vertex) const;
    [[nodiscard]] ogre::Vec3 corner(int column, int row) const;
    [[nodiscard]] bool is_valid_grid(int column, int row) const;
    [[nodiscard]] bool is_flipped(GridCell cell) const;
    [[nodiscard]] std::optional<Box> camera_box(int column, int row) const;
    [[nodiscard]] std::vector<Box> camera_boxes(GridCell junction) const;
    [[nodiscard]] std::optional<ogre::Vec3> intersect_vertical(Ray ray) const;
    [[nodiscard]] std::optional<float> intersect_grid(Ray ray, int column, int row) const;
    [[nodiscard]] std::optional<float> intersect_step(Ray ray, int row, int lane, bool along_z) const;
    [[nodiscard]] std::optional<struct March> plan_march(Ray ray, ogre::Vec3 start, ogre::Vec3 end) const;
    [[nodiscard]] std::optional<float> walk_grids(Ray ray, ogre::Vec3 start, ogre::Vec3 end) const;

    ogre::Vec3 position_;
    ogre::Vec3 scale_{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    ogre::Vec3 inverse_scale_{.x = 1.0F, .y = 1.0F, .z = 1.0F};
    int x_size_ = 0;
    int z_size_ = 0;
    // Hộp bao của cả địa hình trong thế giới, như getBoundBox.
    ogre::Vec3 box_min_;
    ogre::Vec3 box_max_;
    std::vector<float> heights_;
    // Cờ lật của từng ô, chỉ số z * x_size + x; rỗng là mọi ô không lật.
    std::vector<bool> flipped_;
};

} // namespace game::control
