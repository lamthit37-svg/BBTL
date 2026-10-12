// Camera của ảnh đầu 3D (look/head.hpp): đọc bảng theo mô hình và loại ô, số mặc định của bản gốc
// khi thiếu dòng, và phép đặt mắt, điểm nhìn của Render.dll 2026 (RVA 0x186D0) trên số liệu thật
// của nữ chính trong Character_3DHead.txt.
#include "core/check.hpp"
#include "look/head.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <vector>

namespace game::test {
namespace {

using look::HeadPose;
using look::HeadSight;

bool near_value(float value, float expect) {
    return std::fabs(value - expect) < 0.001F;
}

// Mắt = (0, (height + distance * pitch) * 100, distance * 100); điểm nhìn = (shift, height * 100,
// 0).
constexpr HeadPose kTilted{.turn = 0.0F, .height = 2.0F, .distance = 1.5F, .pitch = 0.5F, .shift = 3.0F};
constexpr HeadSight kSight = look::head_sight(kTilted);
static_assert(kSight.target[0] == 3.0F && kSight.target[1] == 200.0F && kSight.target[2] == 0.0F);
static_assert(kSight.eye[0] == 0.0F && kSight.eye[1] == 275.0F && kSight.eye[2] == 150.0F);

table::Tsv head_table() {
    table::Tsv table;
    table.header = {"model", "kind", "turn", "height", "distance", "pitch", "shift"};
    table.rows = {
        {"女主角.obj", "0", "-0.373", "1.6", "0.9", "0", "2"},
        {"女主角.obj", "1", "0.373", "1.6", "0.9", "0", "-2"},
        {"女主角.obj", "2", "0.373", "1.6", "0.9", "0", "-2"},
        {"男主角.obj", "0", "-0.373", "1.78", "0.85", "0", "2"},
        {"男主角.obj", "9", "0", "1", "1", "0", "0"},
        {"男主角.obj", "1", "x", "1", "1", "0", "0"},
    };
    return table;
}

void reads_rows_by_model_and_kind(Context& context) {
    const std::vector<look::HeadRow> rows = look::read_heads(head_table());
    context.expect(rows.size() == 4, "loại ngoài 0..3 và ô số hỏng bị bỏ");
    const HeadPose girl = look::find_head(rows, look::HeadKey{.model = "女主角.obj", .kind = 0});
    const bool is_girl = near_value(girl.turn, -0.373F) && near_value(girl.height, 1.6F) &&
        near_value(girl.distance, 0.9F) && girl.pitch == 0.0F && girl.shift == 2.0F;
    context.expect(is_girl, "nữ chính ở khung người chơi");
    const HeadPose mirrored = look::find_head(rows, look::HeadKey{.model = "女主角.obj", .kind = 1});
    context.expect(near_value(mirrored.turn, 0.373F) && mirrored.shift == -2.0F, "loại 1 quay ngược");
    const HeadPose man = look::find_head(rows, look::HeadKey{.model = "男主角.obj", .kind = 0});
    context.expect(near_value(man.height, 1.78F) && near_value(man.distance, 0.85F), "nam chính");
}

void missing_row_uses_original_defaults(Context& context) {
    const std::vector<look::HeadRow> rows = look::read_heads(head_table());
    const HeadPose lost = look::find_head(rows, look::HeadKey{.model = "khong_co.obj", .kind = 0});
    const bool is_default = lost.height == 0.3F && lost.distance == 1.2F && lost.pitch == 0.28F;
    context.expect(is_default && lost.turn == 0.0F && lost.shift == 0.0F, "số mặc định của bản gốc");
    table::Tsv bare;
    bare.header = {"model", "kind"};
    context.expect(look::read_heads(bare).empty(), "thiếu cột thì rỗng");
}

// Nữ chính ở ô mép trái (loại của khung đội): mặt quay sang phải màn hình (turn dương), mắt cách
// mặt 90 đơn vị ở độ cao 160, nhìn vào điểm lệch ngang -2 đơn vị nên hình dời sang phải.
void girl_sight(Context& context) {
    const std::vector<look::HeadRow> rows = look::read_heads(head_table());
    const look::HeadKey key{.model = "女主角.obj", .kind = look::kPartyHeadKind};
    const HeadPose girl = look::find_head(rows, key);
    context.expect(near_value(girl.turn, 0.373F), "mặt quay sang phải màn hình");
    const HeadSight sight = look::head_sight(girl);
    const bool is_eye = sight.eye[0] == 0.0F && near_value(sight.eye[1], 160.0F) && near_value(sight.eye[2], 90.0F);
    context.expect(is_eye, "mắt ở (0, 160, 90)");
    const bool is_target = sight.target[0] == -2.0F && near_value(sight.target[1], 160.0F) && sight.target[2] == 0.0F;
    context.expect(is_target, "điểm nhìn ở (-2, 160, 0)");
}

constexpr std::array kCases{
    Case{.name = "reads_rows_by_model_and_kind", .body = &reads_rows_by_model_and_kind},
    Case{.name = "missing_row_uses_original_defaults", .body = &missing_row_uses_original_defaults},
    Case{.name = "girl_sight", .body = &girl_sight},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "head_tests: mọi ca phải qua");
    return 0;
}
