// Luật đi của người chơi trên lưới đi của một cảnh: port CPath (CreateMovePath, GetPathDirect,
// IsPointInUnreachRegion) và phần chọn cách đi của CAI_MySelf trong Game.exe của client 2026
// (0x1406d9da0, 0x1406da140, 0x1406da6c0, 0x1406199b0). Nhấp chuột thì tìm đường vòng qua vật
// cản; không có đường (đích nằm trong tường, khác đảo) thì đi thẳng tới sát vật cản đầu tiên.
// Giữ chuột chạy theo con trỏ thì chỉ đi thẳng. Đang đứng trong vật cản thì chỉ được đi thẳng ra
// chỗ đi được, qua không quá một cạnh.
// Chưa port: trạng thái bay (đi thẳng, bỏ qua vật cản bay qua được), câu báo "không tới được" của
// giao diện. Bản gốc ghi log khi đường dài hơn 16 đoạn; ở đây đường dài bao nhiêu cũng đi hết.
#pragma once

#include "nav/finder.hpp"
#include "nav/mesh.hpp"

#include <cstdint>
#include <optional>

namespace game::nav {

// Cỡ cảnh theo đơn vị game, lấy từ bảng cảnh.
struct Area {
    float width = 0.0F;
    float depth = 0.0F;
};

// kFind: nhấp chuột, tìm đường. kStraight: giữ chuột chạy theo con trỏ, chỉ đi thẳng.
enum class MoveMode : std::uint8_t { kFind, kStraight };

struct MoveAsk {
    Segment walk;
    MoveMode mode = MoveMode::kFind;
};

// Lưới đi của một cảnh kèm cỡ cảnh: ngữ cảnh bất biến của mọi câu hỏi về đường đi trong cảnh.
class Field {
public:
    Field(Mesh mesh, Area area) noexcept;

    [[nodiscard]] const Mesh& mesh() const noexcept { return mesh_; }

    // CScene::IsValidPosition: toạ độ là số và nằm trong [0, cỡ cảnh], kể cả hai mép.
    [[nodiscard]] bool is_inside(Point point) const noexcept;

    // Ngoài cảnh, hoặc nằm trên một tam giác vật cản.
    [[nodiscard]] bool is_unreachable(Point point) const noexcept;

    // Chỗ dừng khi đi thẳng từ đầu tới cuối đoạn: chính điểm cuối khi không vướng, không thì lùi
    // 0,1 trước cạnh vật cản đầu tiên. Rỗng khi không đi: một đầu ngoài cảnh hay ngoài lưới tra,
    // quãng đi ngắn hơn căn 2, hay đang trong vật cản mà phải qua hơn một cạnh mới ra.
    [[nodiscard]] std::optional<Point> straight_stop(const Segment& walk) const;

    // Chỗ tới được của một bước ngắn theo phím đi hay cần gạt (bản gốc không có kiểu đi này):
    // điểm cuối khi không vướng, lùi 0,1 trước cạnh vật cản đầu tiên khi vướng, và chính điểm đầu
    // khi bước ra ngoài cảnh. Bước không bao giờ kết thúc trong vật cản; đang đứng trong vật cản
    // thì chỉ bước ra được.
    [[nodiscard]] Point step_reach(const Segment& walk) const;

    // Các điểm phải lần lượt đi tới, không kể chỗ đang đứng; rỗng khi lệnh đi bị từ chối.
    [[nodiscard]] Path plan_move(const MoveAsk& ask, Scratch& scratch) const;

private:
    [[nodiscard]] Point backed_off(const Segment& hit) const noexcept;
    [[nodiscard]] Path straight_path(const Segment& walk) const;

    Mesh mesh_;
    Area area_;
};

} // namespace game::nav
