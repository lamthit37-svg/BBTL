// Truy vấn trên lưới đi, port PathFinderImpl của PathLib.dll (client 2026): tam giác chứa điểm,
// chỗ một đoạn thẳng cắt cạnh ràng buộc, và đường đi giữa hai điểm. Mọi phép tính là số thực 32
// bit theo đúng thứ tự phép toán của bản gốc; module dựng với -ffp-contract=off để trình dịch
// không gộp nhân với cộng. Đã so với chính PathLib.dll trên các truy vấn ngẫu nhiên: kết quả
// trùng từng bit (số đo và các ca bản gốc phụ thuộc rác trên ngăn xếp ở docs/DUONG-DI-2026.md).
// Phần đã đọc trọn mã máy: định vị, giao điểm, duyệt ô, A*, né góc, tỉa điểm. Phần kéo căng
// đường (0x1800288d0, hai chuỗi trái phải) viết theo thuật toán phễu chuẩn và kiểm bằng phép so
// trên. Vùng cấm động (cửa, rào do máy chủ bật) chưa có: client này chưa nối máy chủ.
#pragma once

#include "nav/mesh.hpp"

#include <cstdint>
#include <optional>
#include <vector>

namespace game::nav {

struct Segment {
    Point start;
    Point end;
};

enum class Ground : std::uint8_t { kOpen, kObstacle };

// Tam giác loại ground chứa điểm (kể cả điểm nằm trên cạnh, dung sai 1e-6 của bản gốc). Rỗng khi
// điểm ngoài lưới tra hoặc không tam giác loại đó nào của ô chứa điểm.
[[nodiscard]] std::optional<std::uint32_t> locate(const Mesh& mesh, Point point, Ground ground) noexcept;

// Chỗ đoạn thẳng cắt một cạnh ràng buộc. flags là cờ của tam giác vật cản bên kia cạnh.
struct Crossing {
    float distance_squared = 0.0F;
    std::uint8_t flags = 0;
    Point at;
};

// Mọi chỗ cắt, gần start trước; hai chỗ cùng khoảng cách chỉ giữ chỗ gặp trước. Rỗng (nullopt)
// khi một đầu của đoạn nằm ngoài lưới tra.
[[nodiscard]] std::optional<std::vector<Crossing>> crossings(const Mesh& mesh, const Segment& segment);

// Hai đầu nằm trong lưới tra và đoạn không cắt cạnh ràng buộc nào.
[[nodiscard]] bool sees(const Mesh& mesh, const Segment& segment);

using Path = std::vector<Point>;

// Bộ nhớ làm việc của find_path, giữ lại giữa các lần gọi để không cấp phát lại theo số tam
// giác. Một Scratch dùng được cho mọi lưới.
struct Scratch {
    std::vector<std::uint32_t> parent;
    std::vector<float> walked;
    std::vector<float> ahead;
    std::vector<std::uint8_t> state;
    std::vector<Point> entry;
    std::vector<std::uint32_t> heap;
    std::vector<std::uint32_t> trail;
};

// Đường từ start tới end: điểm đầu, các điểm rẽ (cách đỉnh vật cản 0,1 theo phân giác ngoài),
// điểm cuối. Rỗng khi một đầu không nằm trên tam giác đi được, hai đầu khác đảo, hoặc hai đầu
// trùng nhau trong cùng một tam giác.
[[nodiscard]] std::optional<Path> find_path(const Mesh& mesh, const Segment& segment, Scratch& scratch);

} // namespace game::nav
