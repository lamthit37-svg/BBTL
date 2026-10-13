// Bảng cảnh của client 2026 (Config/SceneDefineEx.txt, dạng chữ phân tab, 25 cột mỗi dòng) cho các bảng
// bản đồ: cỡ cảnh, token ảnh minimap và chỗ đặt thành phố trên bản đồ thế giới.
// Nguồn: cột theo CSceneDefine của Game.exe 2026 (client/map/book.hpp đọc cùng bảng cho phần dựng cảnh);
// cột 11 đến 14 là toạ độ nút và nhãn thành phố trên ảnh bản đồ thế giới, cột 17 đến 21 là tên ảnh của
// nút (Sign, bộ ảnh, ảnh thường, bộ ảnh, ảnh khi trỏ).
// Khác gốc: chỉ đọc những cột mà các bảng bản đồ dùng; dòng thiếu cột hay số hỏng thì bỏ.
#pragma once

#include <cstddef>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::ui::panel {

struct SceneRow {
    int id = 0;
    // Tên gốc của cảnh (khoá bảng dịch scene/<tên>).
    std::string name;
    float width = 0.0F;
    float depth = 0.0F;
    // Token ảnh minimap (szSceneMap).
    std::string token;
    // Nút và nhãn trên bản đồ thế giới, điểm ảnh của ảnh 1024 x 768 hay ảnh lớn hơn (0, 0 là không hiện).
    int icon_x = 0;
    int icon_y = 0;
    int label_x = 0;
    int label_y = 0;
    // Loại nút thành phố ("Sign5"): khoá của CityImageNormal và CityImageHover trong layout LargeMap.
    std::string sign;
    // Ảnh của nút thành phố: bộ ảnh và ảnh khi thường, bộ ảnh và ảnh khi trỏ vào; rỗng khi không có.
    std::string icon_set;
    std::string icon_normal;
    std::string hover_set;
    std::string icon_hover;
    // Cột 24: bản đồ thế giới nào có cảnh này (0 là thế giới thường; InitWorldMap lọc theo số này).
    int world = 0;
};

class SceneTable {
public:
    // Đọc cả tệp; dòng hỏng bị bỏ. Tệp rỗng hay không có dòng nào đọc được thì bảng rỗng.
    [[nodiscard]] static SceneTable from_text(std::string_view text);

    // Dòng của cảnh có id đó; nullptr khi không có.
    [[nodiscard]] const SceneRow* find(int id) const noexcept;
    [[nodiscard]] std::span<const SceneRow> rows() const noexcept { return rows_; }
    [[nodiscard]] bool is_empty() const noexcept { return rows_.empty(); }

private:
    std::vector<SceneRow> rows_;
};

} // namespace game::ui::panel
