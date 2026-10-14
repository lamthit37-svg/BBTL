#pragma once
// Lưới vùng nhìn của một cảnh. Cảnh chia thành ô vuông cạnh `cell_cm`; một thực thể thấy mọi thực thể
// trong cửa sổ (2r+1)x(2r+1) ô quanh ô của nó. Bản gốc: ZONE_SIZE 10 mét, MAX_REFESH_OBJ_ZONE_RADIUS 2,
// tức cửa sổ 5x5 ô (Common/GameDefine.h; Scene::ScanObj, ScanObj_Sub).
//
// Khi một thực thể đổi ô, chỉ phần cửa sổ mới (đi vào) và phần cửa sổ cũ (đi ra) cần báo hiện/ẩn; phần
// giao của hai cửa sổ chỉ nhận tin vị trí. Lưới không biết kiểu thực thể: nó giữ chỉ số u32 do bảng
// thực thể cấp. Thứ tự duyệt cố định (hàng rồi cột, trong ô theo thứ tự vào) nên kết quả tất định.
//
// Độ phức tạp: thêm/bớt O(số thực thể trong ô); duyệt một cửa sổ O((2r+1)^2 + số thực thể thấy được).

#include <cstddef>
#include <cstdint>
#include <unordered_map>
#include <vector>

namespace game::zone {

struct Cell {
    std::int32_t column = 0;
    std::int32_t row = 0;

    friend constexpr bool operator==(Cell, Cell) noexcept = default;
};

class Grid {
public:
    struct Spec {
        float cell_cm = 1000.0F;
        std::int32_t radius = 2;
    };

    // cell_cm > 0 và radius trong [0, 16]; sai là lỗi lập trình.
    explicit Grid(Spec spec);

    // Ô chứa toạ độ. Toạ độ ngoài ±kCoordLimitCm (hay NaN) bị kẹp: không bao giờ tràn int32.
    [[nodiscard]] Cell cell_of(float x_cm, float z_cm) const noexcept;

    [[nodiscard]] std::int32_t radius() const noexcept { return radius_; }

    void insert(std::uint32_t entity, Cell cell);
    // Bỏ thực thể khỏi ô; ô không có nó thì không làm gì.
    void erase(std::uint32_t entity, Cell cell) noexcept;

    // Gọi visit(entity) cho mọi thực thể trong cửa sổ quanh `centre`.
    template <typename Visit>
    void for_each_in_window(Cell centre, const Visit& visit) const {
        const std::int32_t side = (2 * radius_) + 1;
        for (std::int32_t index = 0; index < side * side; ++index) {
            for_each_in_cell(window_cell(centre, index, side), visit);
        }
    }

    // Thực thể thuộc cửa sổ của `after` mà không thuộc cửa sổ của `before` (phần mới thấy).
    template <typename Visit>
    void for_each_entered(Cell before, Cell after, const Visit& visit) const {
        for_each_difference(Pair{.inside = after, .outside = before}, visit);
    }

    // Thực thể thuộc cửa sổ của `before` mà không thuộc cửa sổ của `after` (phần vừa khuất).
    template <typename Visit>
    void for_each_left(Cell before, Cell after, const Visit& visit) const {
        for_each_difference(Pair{.inside = before, .outside = after}, visit);
    }

    [[nodiscard]] bool sees(Cell viewer, Cell target) const noexcept {
        return distance(viewer.column, target.column) <= radius_ && distance(viewer.row, target.row) <= radius_;
    }

    [[nodiscard]] std::size_t population() const noexcept { return population_; }

    // Cạnh lớn nhất của thế giới tính từ gốc, centimet (100 km, như trần điểm vào game).
    static constexpr float kCoordLimitCm = 10'000'000.0F;

private:
    struct Pair {
        Cell inside;
        Cell outside;
    };

    // Phần của cửa sổ `inside` không nằm trong cửa sổ `outside`.
    template <typename Visit>
    void for_each_difference(Pair pair, const Visit& visit) const {
        const std::int32_t side = (2 * radius_) + 1;
        for (std::int32_t index = 0; index < side * side; ++index) {
            const Cell here = window_cell(pair.inside, index, side);
            if (!sees(pair.outside, here)) for_each_in_cell(here, visit);
        }
    }

    template <typename Visit>
    void for_each_in_cell(Cell cell, const Visit& visit) const {
        const auto found = cells_.find(key_of(cell));
        if (found == cells_.end()) return;
        for (const std::uint32_t entity : found->second) {
            visit(entity);
        }
    }

    // Ô thứ `index` của cửa sổ cạnh `side` quanh `centre`, hàng rồi cột.
    [[nodiscard]] Cell window_cell(Cell centre, std::int32_t index, std::int32_t side) const noexcept {
        return Cell{.column = centre.column - radius_ + (index % side), .row = centre.row - radius_ + (index / side)};
    }

    [[nodiscard]] static std::int32_t distance(std::int32_t left, std::int32_t right) noexcept {
        const std::int64_t span = static_cast<std::int64_t>(left) - right;
        return static_cast<std::int32_t>(span < 0 ? -span : span);
    }

    [[nodiscard]] static std::uint64_t key_of(Cell cell) noexcept {
        return (static_cast<std::uint64_t>(static_cast<std::uint32_t>(cell.row)) << 32U) |
            static_cast<std::uint32_t>(cell.column);
    }

    float cell_cm_;
    std::int32_t radius_;
    std::size_t population_ = 0;
    std::unordered_map<std::uint64_t, std::vector<std::uint32_t>> cells_;
};

} // namespace game::zone
