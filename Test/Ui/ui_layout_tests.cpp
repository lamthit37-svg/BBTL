/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Ui/ui_layout_tests.cpp
 *  PHÂN HỆ   : Ui / Ui Layout Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cỡ giao diện theo màn (ui/hud.hpp layout_scale): PC và máy tính bảng 160
 *    dpi giữ 1:1 như client 2026, màn mật độ cao phóng theo mật độ để giữ cỡ
 *    vật lý, màn nhỏ hơn khung ảo 800 x 640 điểm layout co cho vừa thay vì cắt
 *    bảng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/hud.hpp"

#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <cmath>

namespace game::test {
namespace {

[[nodiscard]] bool is_near(float value, float want) {
    return std::fabs(value - want) < 1e-5F;
}

void scale_keeps_pixels_on_desktop(Context& context) {
    context.expect(is_near(ui::layout_scale(1280.0F, 720.0F, 1.0F), 1.0F), "PC 1280x720 là 1:1");
    context.expect(is_near(ui::layout_scale(2560.0F, 1440.0F, 1.0F), 1.0F), "PC màn lớn vẫn 1:1 như bản gốc");
    context.expect(is_near(ui::layout_scale(1280.0F, 800.0F, 1.0F), 1.0F), "tablet 160 dpi là 1:1");
}

void scale_follows_density(Context& context) {
    context.expect(is_near(ui::layout_scale(2732.0F, 2048.0F, 2.0F), 2.0F), "iPad Pro mật độ 2 phóng gấp đôi");
    context.expect(is_near(ui::layout_scale(2560.0F, 1600.0F, 2.0F), 2.0F), "tablet 320 dpi phóng gấp đôi");
    context.expect(is_near(ui::layout_scale(2560.0F, 1440.0F, 2.0F), 2.0F), "khung đăng nhập iPad 2560x1440");
}

void scale_shrinks_small_screens(Context& context) {
    context.expect(is_near(ui::layout_scale(960.0F, 540.0F, 1.0F), 540.0F / 640.0F), "LDPlayer 960x540 co theo cao");
    context.expect(is_near(ui::layout_scale(2048.0F, 1152.0F, 2.0F), 1152.0F / 640.0F), "không đủ chỗ ở mật độ 2");
    context.expect(is_near(ui::layout_scale(2556.0F, 1179.0F, 3.0F), 1179.0F / 640.0F), "iPhone ngang co theo cao");
}

void scale_survives_bad_input(Context& context) {
    context.expect(is_near(ui::layout_scale(1280.0F, 720.0F, 0.0F), 1.0F), "mật độ 0 coi như 1");
    context.expect(is_near(ui::layout_scale(1280.0F, 720.0F, -2.0F), 1.0F), "mật độ âm coi như 1");
    context.expect(is_near(ui::layout_scale(0.0F, 0.0F, 2.0F), 2.0F), "màn rỗng giữ mật độ");
}

constexpr std::array kCases{
    Case{.name = "scale_keeps_pixels_on_desktop", .body = &scale_keeps_pixels_on_desktop},
    Case{.name = "scale_follows_density", .body = &scale_follows_density},
    Case{.name = "scale_shrinks_small_screens", .body = &scale_shrinks_small_screens},
    Case{.name = "scale_survives_bad_input", .body = &scale_survives_bad_input},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_layout_tests: mọi ca phải qua");
    return 0;
}
