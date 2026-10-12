// Test Model của module collision (vai C, B3 của DH đợt 1): lưới sau nạp (SRC/collision/mesh.hpp) và cây OPCODE
// (SRC/collision/opcode_tree.hpp), dựng trên parse_building_file của A.
// - byte tự dựng: gộp đỉnh và bộ ba của mã 1 đúng thứ tự set, đỉnh giữ f32 lần gặp đầu; tam giác suy biến được
//   giữ; NbTris, NbVerts cắt 16 bit kiểu gói (65 536 -> 0, 65 537 -> 1); mã 2 không gộp, đỉnh bit-exact với
//   transform_vertex, tỉ lệ lượt đặt 0 vẫn giữ tam giác; trần cấp phát của tệp hỏng;
// - phép bit khoá đỉnh, cvttss2si không UB, vòng sửa 0xFFFF (cả hành vi VƯỢT/gói) và bản tìm nhị phân trùng bản
//   từng vòng; cây 0, 1, 2 tam giác;
// - chốt cây với số vàng của B (so-do/b-cay-dinh-dang.md): xihu_Valentine, fenghuang trùng TỪNG DÒNG; bianjing
//   trùng sha256 toàn văn chuẩn (#sha256_day_du) và 4000 dòng giữ của tệp ngắn. Thiếu tệp vào thì trả 77.
#include "collision/building_file.hpp"
#include "collision/mesh.hpp"
#include "collision/opcode_tree.hpp"
#include "collision/transform.hpp"
#include "collision_report.hpp"
#include "collision_sha256.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <ios>
#include <iterator>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using collision::detail::build_mesh;
using collision::detail::build_tree;
using collision::detail::Mesh;
using collision::detail::OpcodeTree;
using collision::detail::parse_building_file;
using collision::detail::Point3;
using collision::detail::TreeShape;
using Corners = std::array<std::uint32_t, 3>;

constexpr std::string_view kProgram = "collision_model_tests";

#ifdef GAME_COLLISION_SCENE
constexpr std::string_view kSceneDir = GAME_COLLISION_SCENE;
#else
constexpr std::string_view kSceneDir;
#endif
#ifdef GAME_COLLISION_GOLDEN
constexpr std::string_view kGoldenDir = GAME_COLLISION_GOLDEN;
#else
constexpr std::string_view kGoldenDir;
#endif
#ifdef GAME_COLLISION_VANG
constexpr std::string_view kVangDir = GAME_COLLISION_VANG;
#else
constexpr std::string_view kVangDir;
#endif

// ------------------------------------------------------------------ dựng byte tệp
class FileBytes {
public:
    void u16(std::uint16_t value) { bytes(value, 2); }
    void u32(std::uint32_t value) { bytes(value, 4); }
    void i32(std::int32_t value) { u32(std::bit_cast<std::uint32_t>(value)); }
