// Test chính của module collision (DE-BAI DH đợt 1, mục 4 và 5; vai A, Model của vai C). Các phần:
// - bộ đọc .WCollision (SRC/collision/building_file.hpp) trên byte tự dựng: bộ đệm rỗng và ngắn, mọi tiền tố của
//   tệp hợp lệ bị từ chối, đuôi thừa, bộ đệm lệch căn lề đọc ra đúng từng bit như bộ đệm thẳng, hàm truy cập trả
//   đúng giá trị đã ghi; describe có câu cho mọi giá trị LoadError;
// - số vàng (tests/collision_golden.hpp, định dạng so-do/b-dinh-dang-tsv.md): mọi collision_get_*.tsv; chưa có Model
//   vẫn phân tích TSV và so kết quả parse với "nạp" của DLL, có Model thì so từng bit height và raycast; ca nhiều
//   luồng so với bản một luồng; cách đọc chọn theo chữ đầu dòng dữ liệu đầu tiên, chữ lạ là lỗi dữ liệu (trả 2);
// - số vàng biến đổi V-2 (tests/collision_bien_doi.hpp, so-do/b-bien-doi.md): mọi tệp có dòng "bd", không cần tệp
//   đầu vào; so từng bit 3 toạ độ đỉnh của transform_vertex (SRC/collision/transform.hpp của C), lệch thì trả 1;
// - ca phụ: 435 tệp thật của _raw/Scene (CMake đặt GAME_COLLISION_SCENE) parse thành công và mọi số đếm trùng bảng
//   của scan (bộ đọc chuẩn T1 của B) trong GAME_COLLISION_COUNTS (docs/giao-viec/DH-DOT-1/so-do/b-t1-tep-2.tsv).
// - phép kiểm biên của bộ đọc có ca bắt (R3-10, so-do/a-r3-10-chung-minh.md): bộ đệm 1 GiB (K1, G1), khối 0 đỉnh 0
//   tam giác (K14), lỗi ở ô hay khối không phải cuối (K20).
// Ca chờ Model hay thiếu dữ liệu in lý do và làm main trả 77 (CTest báo Skipped); kỳ vọng hỏng thì trả 1; số vàng có
// chữ đầu dòng lạ, hay dòng của b-t1-tep-2.tsv thiếu cột, số hỏng, chỉ số khối lệch thì trả 2 (R3-8: không dừng exe
// bằng core::check hay .at() trên dữ liệu đọc từ tệp).
#include "collision/building_file.hpp"
#include "collision_bien_doi.hpp"
#include "collision_golden.hpp"
#include "collision_nap_goc.hpp"
#include "collision_report.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <ios>
#include <iterator>
#include <limits>
#include <memory>
#include <optional>
#include <ranges>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using collision::LoadError;
using collision::detail::BuildingFileView;
using collision::detail::parse_building_file;
using enum LoadError;
using Bytes = std::span<const std::byte>;

#ifdef GAME_COLLISION_SCENE
constexpr std::string_view kSceneDir = GAME_COLLISION_SCENE;
#else
constexpr std::string_view kSceneDir;
#endif
#ifdef GAME_COLLISION_COUNTS
constexpr std::string_view kCountsFile = GAME_COLLISION_COUNTS;
#else
constexpr std::string_view kCountsFile;
#endif

constexpr std::size_t kSceneFiles = 435;

constexpr std::string_view kProgram = "collision_tests";

// Một dòng "collision_tests: <chủ đề>: <lời>" ra stderr: kết quả ca, hay tên tệp thật sai.
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
void check_scene_row(Context& context, const Row& row) {
    const std::optional<std::string_view> name = row.cell("name");
    const bool complete = name && row.cell("status") && row.number_at("consumed") && row.number_at("version");
    if (complete) {
        check_scene_file(context, row, *name);
    } else {
        scene_data_error("real_files_match_scan", "dòng b-t1-tep-2.tsv thiếu cột hay có số hỏng");
    }
}

[[nodiscard]] std::size_t count_scene_files() {
    std::error_code error;
    std::size_t count = 0;
    for (const auto& entry : std::filesystem::directory_iterator(std::filesystem::path(kSceneDir), error)) {
        count += static_cast<std::size_t>(entry.path().extension() == ".WCollision");
    }
    return count;
}

// 435 tệp thật: mỗi dòng của TSV một tệp; thư mục cũng đúng 435 tệp .WCollision.
void real_files_match_scan(Context& context) {
    if (kSceneDir.empty() || kCountsFile.empty()) {
        say_skipped(kProgram, "real_files_match_scan", "bỏ qua, thiếu GAME_COLLISION_SCENE hay GAME_COLLISION_COUNTS");
        return;
    }
    std::ifstream stream{std::filesystem::path(kCountsFile)};
    std::vector<std::string> lines;
    for (std::string line; std::getline(stream, line);) {
        lines.push_back(std::move(line));
    }
    context.expect(lines.size() == kSceneFiles + 1, "TSV có tiêu đề và 435 dòng tệp");
    if (lines.empty()) return;
    const std::vector<std::string_view> header = fields(lines.front());
    std::size_t checked = 0;
    for (const std::string& line : std::span(lines).subspan(1)) {
        const std::vector<std::string_view> values = fields(line);
        check_scene_row(context, Row{.header = header, .values = values});
        ++checked;
    }
    const std::size_t present = count_scene_files();
    context.expect(present == kSceneFiles, "_raw/Scene có 435 tệp .WCollision");
    const std::string done = "đã kiểm " + std::to_string(checked) + " tệp thật với scan của B, thư mục có ";
    report("real_files_match_scan", done + std::to_string(present) + " tệp .WCollision");
}

constexpr std::array kCases{
    Case{.name = "short_buffers_are_rejected", .body = &short_buffers_are_rejected},
    Case{.name = "minimal_files_parse", .body = &minimal_files_parse},
    Case{.name = "misaligned_buffers_read_the_same", .body = &misaligned_buffers_read_the_same},
    Case{.name = "cell_accessors_read_the_file", .body = &cell_accessors_read_the_file},
    Case{.name = "block_accessors_read_the_file", .body = &block_accessors_read_the_file},
    Case{.name = "too_large_buffer_is_rejected", .body = &too_large_buffer_is_rejected},
    Case{.name = "boundary_checks_have_cases", .body = &boundary_checks_have_cases},
    Case{.name = "every_error_has_a_description", .body = &every_error_has_a_description},
    Case{.name = "golden_files_match", .body = &golden::golden_files_match},
    Case{.name = "transform_golden_match", .body = &golden::transform_golden_match},
    Case{.name = "threads_match_one_thread", .body = &golden::threads_match_one_thread},
    Case{.name = "real_files_match_scan", .body = &real_files_match_scan},
    Case{.name = "oracle_loads_match", .body = &collision::test::oracle_loads_match},
};

} // namespace
} // namespace game::test

int main() {
    return game::test::exit_code(game::test::run_all(game::test::kCases));
}

