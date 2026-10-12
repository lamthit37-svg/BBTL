// Bảng nạp của một stage: mỗi tên mesh chỉ một dòng vì mỗi mesh chỉ đọc tệp GLB và tải lên GPU một
// lần, còn 57 vật thể chia nhau kết quả ấy; mỗi vật thể giữ chỉ số mesh của mình và phép đặt đã
// tính thành ma trận thế giới [R * S | T] theo OGRE (double, của scene::world_transform). Tầng này
// không biết GPU: dựng được ở mọi cấu hình, kể cả bản không có chuỗi đồ hoạ.
#pragma once

#include "client/stage.hpp"
#include "scene/transform.hpp"

#include <cstddef>
#include <string>
#include <vector>

namespace game::client {

// Một vật thể đã gom: mesh nào (chỉ số trong PropTable::meshes) và ma trận thế giới nó đứng.
struct PlacedProp {
    std::size_t mesh = 0;
    scene::Transform world;
};

struct PropTable {
    // Tên mesh duy nhất theo thứ tự gặp đầu tiên; tệp GLB là Model/<tên>.glb dưới thư mục dữ liệu.
    std::vector<std::string> meshes;
    // Một mục cho mỗi vật thể của stage, đúng thứ tự trong tệp cảnh.
    std::vector<PlacedProp> props;
};

// Gom stage thành bảng nạp. Stage không có vật thể nào cho bảng rỗng.
[[nodiscard]] PropTable table_of(const Stage& stage);

} // namespace game::client
