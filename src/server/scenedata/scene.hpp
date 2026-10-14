#pragma once
// Nạp một cảnh máy chủ từ nội dung các tệp của thư mục dev/server/scenes/<tên>. Thuần: nhận chữ và byte đã
// đọc (SceneFiles), không đụng đĩa; disk.hpp có hàm đọc thư mục. Test dựng SceneFiles bằng tay nên chạy được
// không cần dữ liệu thật.
//
// Tên bảng: `<loại>.tsv` là bảng gốc, `<loại>.<nhãn>.tsv` là bảng theo nhãn (nhãn có thể chứa dấu chấm, ví dụ
// "level_100", "n1_level_40", "set__pingpan_1", "level_150.alt"). Loại có nhãn: spawns, areas, spawn_operates,
// spawn_operate_values. Loại chỉ có bảng gốc: spawn_levels, patrols, grow_points, grow_point_rules,
// platforms, wild_pets, portals, buses. Tên khác vào Scene::unread_files.
//
// Độ phức tạp: thời gian và bộ nhớ tuyến tính theo tổng cỡ nội dung đầu vào; mọi bảng có trần dòng (tables.hpp),
// số tệp trong SceneFiles có trần kMaxSceneTables.

#include "scenedata/types.hpp"

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::scenedata {

inline constexpr std::size_t kMaxSceneTables = 2048;
inline constexpr std::size_t kMaxTableName = 128;

struct NamedText {
    // Tên tệp thuần (không có đường dẫn), ví dụ "spawns.level_100.tsv".
    std::string name;
    std::string text;
};

struct SceneFiles {
    // Tên thư mục cảnh.
    std::string name;
    // scene.toml (bắt buộc).
    std::string manifest;
    // Mọi tệp .tsv của thư mục.
    std::vector<NamedText> tables;
    // walk.path (lưới tam giác của client 2026) và walk.nav (lưới ô của máy chủ 2008), nếu có.
    std::optional<std::string> walk_path;
    std::optional<std::string> walk_nav;
};

// Tên bảng tách thành loại và nhãn. nullopt khi không phải `<loại>[.<nhãn>].tsv` hợp lệ (loại và nhãn không
// rỗng, chỉ gồm a-z A-Z 0-9 _ . -).
struct TableName {
    std::string_view family;
    // Rỗng với bảng gốc.
    std::string_view label;
};
[[nodiscard]] std::optional<TableName> split_table_name(std::string_view name) noexcept;

// Nạp cả cảnh. Lỗi đầu tiên của bất kỳ bảng nào (hay của lưới đi, manifest) dừng việc nạp: không trả cảnh
// nửa vời. Tên tệp lặp, tên không hợp lệ, spawn_file của bảng operate trỏ tới bảng quái không có đều là lỗi.
[[nodiscard]] Loaded<Scene> parse_scene(const SceneFiles& files);

// Số liệu kiểm chéo của một cảnh đã nạp (không phải lỗi nạp; dùng để báo cáo chất lượng dữ liệu).
struct SceneAudit {
    // Tổng số quái ở bảng gốc và mọi bảng theo nhãn.
    std::size_t spawns = 0;
    // Số quái có vị trí đặt rõ (position_given).
    std::size_t spawns_placed = 0;
    // Trong số đã đặt: số quái đứng ngoài chỗ đi được của nguồn lưới đang dùng (Walk::walkable, level 0).
    // Bằng 0 khi cảnh không có lưới đi (xem has_walk).
    std::size_t spawns_off_walk = 0;
    bool has_walk = false;
    // Trong số đã đặt: số quái đứng ngoài lưới ô của máy chủ 2008 (walk.nav), bất kể nguồn đang dùng. Cảnh có cả
    // .path của client lẫn walk.nav cho thấy hai lưới lệch nhau bao nhiêu: bố cục map 2026 khác bản 0859602 thì
    // số này thấp còn spawns_off_walk cao. Bằng 0 khi cảnh không có walk.nav (xem has_legacy_grid).
    std::size_t spawns_off_legacy_grid = 0;
    bool has_legacy_grid = false;
    // Quái có patrol_id >= 0 mà cảnh không có tuyến tuần đó.
    std::size_t spawns_dangling_patrol = 0;
    // Điểm tuần đã đặt nằm ngoài chỗ đi được.
    std::size_t patrol_points_off_walk = 0;
};
[[nodiscard]] SceneAudit audit_scene(const Scene& scene) noexcept;

} // namespace game::scenedata
