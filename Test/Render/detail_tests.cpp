/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Render/detail_tests.cpp
 *  PHÂN HỆ   : Render / Detail Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ chỉnh trần tam giác: hạ khi khung chậm, nâng khi khung dư, kẹp trong
 *    [floor, ceiling], bỏ khung nạp cảnh và số xấu.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "render/detail_governor.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <limits>

namespace game::test {
namespace {

constexpr render::DetailConfig kConfig{.start_cap = 300'000, .floor_cap = 120'000, .ceiling_cap = 1'600'000};

struct Burst {
    double interval_ms = 0.0;
    std::uint32_t frames = 0;
};

void feed(render::DetailGovernor& governor, Burst burst) {
    for (std::uint32_t frame = 0; frame < burst.frames; ++frame) {
        static_cast<void>(governor.note_frame(burst.interval_ms));
    }
}

void slow_frames_lower_the_cap(Context& context) {
    render::DetailGovernor governor(kConfig);
    feed(governor, {.interval_ms = 60.0, .frames = kConfig.window});
    context.expect(governor.cap() == 255'000, "một cửa sổ chậm hạ 15%");
    feed(governor, {.interval_ms = 60.0, .frames = kConfig.window * 40});
    context.expect(governor.cap() == kConfig.floor_cap, "hạ mãi vẫn không dưới sàn");
}

void fast_frames_raise_the_cap(Context& context) {
    render::DetailGovernor governor(kConfig);
    feed(governor, {.interval_ms = 16.7, .frames = kConfig.window});
    context.expect(governor.cap() == 324'000, "một cửa sổ dư nâng 8%");
    feed(governor, {.interval_ms = 16.7, .frames = kConfig.window * 200});
    context.expect(governor.cap() == kConfig.ceiling_cap, "nâng mãi vẫn không quá trần");
}

void on_target_frames_keep_the_cap(Context& context) {
    render::DetailGovernor governor(kConfig);
    feed(governor, {.interval_ms = kConfig.target_ms, .frames = kConfig.window * 10});
    context.expect(governor.cap() == kConfig.start_cap, "đúng nhịp đích thì giữ nguyên");
}

void loading_and_bad_frames_are_ignored(Context& context) {
    render::DetailGovernor governor(kConfig);
    feed(governor, {.interval_ms = 20'000.0, .frames = kConfig.window * 3});
    feed(governor, {.interval_ms = 0.0, .frames = kConfig.window * 3});
    feed(governor, {.interval_ms = -5.0, .frames = kConfig.window * 3});
    feed(governor, {.interval_ms = std::numeric_limits<double>::quiet_NaN(), .frames = kConfig.window * 3});
    feed(governor, {.interval_ms = std::numeric_limits<double>::infinity(), .frames = kConfig.window * 3});
    context.expect(governor.cap() == kConfig.start_cap, "khung nạp cảnh và số xấu không làm đổi trần");
}

void start_cap_is_clamped(Context& context) {
    const render::DetailGovernor low(render::DetailConfig{.start_cap = 1, .floor_cap = 120'000, .ceiling_cap = 1'600'000});
    const render::DetailGovernor high(
        render::DetailConfig{.start_cap = 900'000'000, .floor_cap = 120'000, .ceiling_cap = 1'600'000});
    context.expect(low.cap() == 120'000, "trần khởi đầu kẹp lên sàn");
    context.expect(high.cap() == 1'600'000, "trần khởi đầu kẹp xuống trần");
}

constexpr std::array kCases{
    Case{.name = "slow_frames_lower_the_cap", .body = &slow_frames_lower_the_cap},
    Case{.name = "fast_frames_raise_the_cap", .body = &fast_frames_raise_the_cap},
    Case{.name = "on_target_frames_keep_the_cap", .body = &on_target_frames_keep_the_cap},
    Case{.name = "loading_and_bad_frames_are_ignored", .body = &loading_and_bad_frames_are_ignored},
    Case{.name = "start_cap_is_clamped", .body = &start_cap_is_clamped},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "detail_tests: mọi ca phải qua");
    return 0;
}
