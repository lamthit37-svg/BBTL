#pragma once
// Nạp từng bảng cảnh từ nội dung TSV (thuần: không đọc đĩa). Mỗi hàm nhận tên tệp (chỉ để báo lỗi) và nội
// dung bảng, trả danh sách bản ghi theo đúng thứ tự dòng, hoặc LoadError đầu tiên kèm "<tệp>:<dòng>: cột
// <tên>: <lý do>".
//
// Đầu vào thù địch: nội dung quá kMaxTableBytes hay quá kMaxTableRows dòng bị từ chối TRƯỚC khi tách dòng;
// bảng quá kMaxColumns cột bị từ chối; số ngoài miền, số thực không hữu hạn, chữ không phải UTF-8 sạch
// hay quá dài đều là lỗi, không bao giờ làm dừng tiến trình. Độ phức tạp: O(dòng * cột^2) với cột <=
// kMaxColumns.

#include "scenedata/types.hpp"

#include <cstddef>
#include <string_view>
#include <vector>

namespace game::scenedata {

inline constexpr std::size_t kMaxTableBytes = std::size_t{64} * 1024 * 1024;
inline constexpr std::size_t kMaxTableRows = 200'000;
inline constexpr std::size_t kMaxColumns = 64;
inline constexpr std::size_t kMaxPatrols = 4096;
inline constexpr std::size_t kMaxPatrolPoints = 4096;
inline constexpr std::size_t kMaxSpeechPerPoint = 16;

// spawns*.tsv: quái và NPC. Bảng gốc và mọi bảng theo nhãn cùng cột.
[[nodiscard]] Loaded<std::vector<Spawn>> parse_spawns(std::string_view file, std::string_view text);
// areas*.tsv: vùng sự kiện. Số giữ nguyên; vùng có left > right hay top > bottom là vùng rỗng (xem Area).
[[nodiscard]] Loaded<std::vector<Area>> parse_areas(std::string_view file, std::string_view text);
// patrols.tsv: mỗi dòng một điểm; gom theo patrol_index (tăng dần), điểm theo point_index (tăng dần). Trùng
// (patrol_index, point_index), quá kMaxPatrols tuyến hay quá kMaxPatrolPoints điểm một tuyến là lỗi.
[[nodiscard]] Loaded<std::vector<Patrol>> parse_patrols(std::string_view file, std::string_view text);
[[nodiscard]] Loaded<std::vector<GrowPoint>> parse_grow_points(std::string_view file, std::string_view text);
// grow_point_rules.tsv. Cột chưa đặt tên của bảng: column_2 là 每次生成数量, column_3 là 生成函数,
// column_4 là 种子补充的间隔时间, column_5 là 补充时间随机增量.
[[nodiscard]] Loaded<std::vector<GrowRule>> parse_grow_rules(std::string_view file, std::string_view text);
[[nodiscard]] Loaded<std::vector<Platform>> parse_platforms(std::string_view file, std::string_view text);
[[nodiscard]] Loaded<std::vector<WildPet>> parse_wild_pets(std::string_view file, std::string_view text);
[[nodiscard]] Loaded<std::vector<Portal>> parse_portals(std::string_view file, std::string_view text);
[[nodiscard]] Loaded<std::vector<Bus>> parse_buses(std::string_view file, std::string_view text);
[[nodiscard]] Loaded<std::vector<SpawnLevel>> parse_spawn_levels(std::string_view file, std::string_view text);
// spawn_operates*.tsv và spawn_operate_values*.tsv. Cột spawn_file là tên tệp trong cùng thư mục: không
// được chứa dấu phân cách đường dẫn hay "..".
[[nodiscard]] Loaded<std::vector<SpawnOperate>> parse_spawn_operates(std::string_view file, std::string_view text);
[[nodiscard]] Loaded<std::vector<OperateValue>> parse_operate_values(std::string_view file, std::string_view text);

} // namespace game::scenedata
