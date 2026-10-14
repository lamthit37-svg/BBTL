#pragma once
// Lưới đi của một cảnh: chọn nguồn theo scene.toml rồi nạp. Nguồn và thứ bậc (đề bài chung đợt gameplay):
// .path của client 2026 thắng, walk.nav của máy chủ 2008 chỉ khi cảnh không có .path. TOOLS/server/scene_walk.py
// ghi khối "Nguồn lưới đi" (walk_source, walk_path, walk_nav) vào scene.toml; cảnh chưa qua công cụ đó thì
// nguồn được suy ra từ tệp có mặt.
//
// Khác gốc: PathFinder::IsCanGo của mã 2008 ép toạ độ sang WORD nên toạ độ ngoài 0..65535 ô quấn vòng; ở đây
// ngoài lưới là không đi được. walk.nav thật nhỏ hơn 8192 x 8192 ô, kLegacyGridCells chặn tệp lớn hơn.

#include "scenedata/types.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::scenedata {

inline constexpr std::size_t kMaxManifestBytes = std::size_t{1} << 20;
inline constexpr std::size_t kMaxManifestLines = 4096;
// 4096 * 4096 ô: 16 MiB trạng thái. Cảnh lớn nhất của dữ liệu thật là 640 x 640.
inline constexpr std::size_t kLegacyGridCells = std::size_t{4096} * 4096;

// Phần của scene.toml mà bộ nạp dùng. Khoá khác bị bỏ qua (lint_config.py lo phần còn lại).
struct Manifest {
    // Khoá walk_source; nullopt khi cảnh chưa qua scene_walk.py.
    std::optional<std::string> walk_source;
    // grid_width / grid_height của walk.nav, ghi bởi export_scene.py.
    std::optional<std::uint32_t> grid_width;
    std::optional<std::uint32_t> grid_height;
};

// scene.toml: các dòng `khoá = giá trị` (chuỗi trong nháy kép không có dấu gạch ngược, hoặc số nguyên), chú
// thích `#` sau giá trị hoặc cả dòng. schema phải bằng 1. Dòng lạ, khoá lặp, quá kMaxManifestBytes /
// kMaxManifestLines là lỗi.
[[nodiscard]] Loaded<Manifest> parse_manifest(std::string_view text);

// walk.nav: hai u16 little-endian (rộng, cao) rồi rộng * cao ô, mỗi ô bốn byte. Cỡ tệp phải khớp đúng, rộng
// và cao phải khác 0, số ô không quá kLegacyGridCells.
[[nodiscard]] Loaded<LegacyGrid> parse_legacy_grid(std::string_view bytes);

// Chọn nguồn và nạp. path_bytes / nav_bytes là nội dung walk.path / walk.nav nếu tệp có mặt. Cả hai tệp có
// mặt thì cả hai được nạp và kiểm (tệp dự phòng hỏng vẫn là lỗi dữ liệu). Nguồn khai trong manifest mà thiếu
// tệp tương ứng, grid_width / grid_height lệch với walk.nav, hay walk_source lạ đều là lỗi.
[[nodiscard]] Loaded<Walk> build_walk(const Manifest& manifest, std::optional<std::string_view> path_bytes,
    std::optional<std::string_view> nav_bytes);

} // namespace game::scenedata
