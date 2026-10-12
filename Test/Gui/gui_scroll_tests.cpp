// Số học của thanh cuộn và danh sách (gui/scroll.hpp), đối chiếu các ví dụ số tính từ mã máy
// CEGUIBase.dll và CEGUIFalagard.dll 2026 (docs/GIAO-DIEN-2026.md: QuestLog_Listbox ở 1280x720).
#include "gui/scroll.hpp"

#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <limits>
#include <optional>

namespace game::test {
namespace {

using gui::ListProbe;
using gui::ListSpan;
using gui::ScrollSpan;
using gui::ThumbTrack;

// Vùng mục của QuestLog_Listbox cao 376; mục cao 19 với phông cỡ 14, 17 với phông cỡ 12.
constexpr float kPage = 376.0F;
constexpr float kRow = 19.0F;

static_assert(gui::scroll_limit(ScrollSpan{.document = 600.0F, .page = 376.0F}) == 224.0F);
static_assert(gui::scroll_limit(ScrollSpan{.document = 100.0F, .page = 376.0F}) == 0.0F);
static_assert(gui::scroll_step(376.0F) == 37.6F);
static_assert(gui::scroll_step(4.0F) == 1.0F);
static_assert(!gui::is_scrollable(ScrollSpan{.document = 376.0F, .page = 376.0F}));
static_assert(gui::is_scrollable(ScrollSpan{.document = 380.0F, .page = 376.0F}));

void clamp_keeps_position_in_range(Context& context) {
    const ScrollSpan span{.document = 391.0F, .page = 376.0F};
    context.expect(gui::clamp_scroll(span, -5.0F) == 0.0F, "số âm về 0");
    context.expect(gui::clamp_scroll(span, 7.5F) == 7.5F, "trong khoảng thì giữ, không làm tròn");
    context.expect(gui::clamp_scroll(span, 37.6F) == 15.0F, "một nấc bánh xe của 23 mục cỡ 12 kẹp về 15");
    const float nan = std::numeric_limits<float>::quiet_NaN();
    context.expect(gui::clamp_scroll(span, nan) == 0.0F, "số không hữu hạn về 0");
    const ScrollSpan fitting{.document = 100.0F, .page = 376.0F};
    context.expect(gui::clamp_scroll(fitting, 50.0F) == 0.0F, "tài liệu ngắn hơn trang thì luôn 0");
}

// Thanh cuộn của QuestLog_Listbox: rãnh từ 15 tới 365, thumb cao 18, tài liệu 600 trên trang 376.
void thumb_follows_position(Context& context) {
    const ThumbTrack track{.top = 15.0F, .slide = 332.0F};
    const ScrollSpan span{.document = 600.0F, .page = 376.0F};
    context.expect(gui::thumb_top(track, span, 0.0F) == 15.0F, "đầu rãnh");
    context.expect(gui::thumb_top(track, span, 224.0F) == 347.0F, "cuối rãnh");
    context.expect(gui::thumb_top(track, span, 100.0F) == 163.0F, "giữa rãnh: 163,214 cắt về 163");
    const ScrollSpan fitting{.document = 376.0F, .page = 376.0F};
    context.expect(gui::thumb_top(track, fitting, 0.0F) == 15.0F, "tài liệu vừa khít trang: đầu rãnh");
}

void thumb_gives_position_back(Context& context) {
    const ThumbTrack track{.top = 15.0F, .slide = 332.0F};
    const ScrollSpan span{.document = 600.0F, .page = 376.0F};
    context.expect(gui::scroll_from_thumb(track, span, 15.0F) == 0.0F, "thumb ở đầu rãnh");
    // 332 / (332 / 224) bằng số thực 32 bit không ra đúng 224; bản gốc để setScrollPosition kẹp.
    const float last = gui::scroll_from_thumb(track, span, 347.0F);
    context.expect(last > 223.999F && last < 224.001F, "thumb ở cuối rãnh: 224 trong sai số số thực");
    context.expect(gui::clamp_scroll(span, last + 0.001F) == 224.0F, "kẹp lại thì đúng cuối tài liệu");
    const ScrollSpan fitting{.document = 376.0F, .page = 376.0F};
    context.expect(gui::scroll_from_thumb(track, fitting, 100.0F) == 0.0F, "không có gì để cuộn");
    const ThumbTrack stuck{.top = 15.0F, .slide = 0.0F};
    context.expect(gui::scroll_from_thumb(stuck, span, 100.0F) == 0.0F, "rãnh không có quãng chạy");
}

void first_visible_counts_partly_shown_item(Context& context) {
    const ListSpan list{.page = kPage, .row = kRow, .count = 30};
    context.expect(gui::first_visible(list, 0.0F) == 0, "chưa cuộn");
    context.expect(gui::first_visible(list, 18.5F) == 0, "mục 0 còn thấy nửa điểm ảnh");
    context.expect(gui::first_visible(list, 19.0F) == 1, "mép dưới mục 0 chạm mép trên vùng: mục 1");
    context.expect(gui::first_visible(list, 37.6F) == 1, "một nấc bánh xe");
    const ListSpan empty{.page = kPage, .row = kRow, .count = 0};
    context.expect(gui::first_visible(empty, 0.0F) == -1, "danh sách rỗng");
}

void first_item_request_stops_at_last_page(Context& context) {
    const ListSpan list{.page = kPage, .row = kRow, .count = 30};
    context.expect(gui::scroll_for_first(list, 2) == 38.0F, "mục 2 lên mép trên");
    context.expect(gui::scroll_for_first(list, 29) == 194.0F, "mục cuối: lùi về trang cuối (570 - 376)");
    context.expect(!gui::scroll_for_first(list, 30), "chỉ số ngoài danh sách thì không đổi");
    const ListSpan fitting{.page = kPage, .row = kRow, .count = 5};
    context.expect(gui::scroll_for_first(fitting, 3) == 0.0F, "danh sách ngắn hơn vùng: kẹp về 0");
    const ListSpan exact{.page = 380.0F, .row = kRow, .count = 20};
    context.expect(!gui::scroll_for_first(exact, 3), "tổng cao đúng bằng cao vùng thì không đổi");
}

void point_finds_item(Context& context) {
    const ListSpan small{.page = kPage, .row = 17.0F, .count = 3};
    const auto at = [&small](float position, float down) {
        return gui::item_at(small, ListProbe{.position = position, .down = down});
    };
    context.expect(at(0.0F, 22.0F) == std::size_t{1}, "y cục bộ 25 của listbox (vùng từ 3) là mục 1");
    context.expect(at(0.0F, 16.9F) == std::size_t{0}, "ngay trên mép dưới mục 0");
    context.expect(at(0.0F, 17.0F) == std::size_t{1}, "mép dưới mục 0 thuộc mục 1");
    context.expect(!at(0.0F, 51.0F), "dưới mục cuối là chỗ trống");
    context.expect(at(15.0F, 0.0F) == std::size_t{0}, "đang cuộn 15: mép trên vùng còn là mục 0");
    context.expect(at(17.0F, 0.0F) == std::size_t{1}, "đang cuộn 17: mép trên vùng là mục 1");
    context.expect(!at(-5.0F, 2.0F), "điểm nằm trên mục đầu");
}

constexpr std::array<Case, 6> kCases = {{
    {.name = "clamp_keeps_position_in_range", .body = clamp_keeps_position_in_range},
    {.name = "thumb_follows_position", .body = thumb_follows_position},
    {.name = "thumb_gives_position_back", .body = thumb_gives_position_back},
    {.name = "first_visible_counts_partly_shown_item", .body = first_visible_counts_partly_shown_item},
    {.name = "first_item_request_stops_at_last_page", .body = first_item_request_stops_at_last_page},
    {.name = "point_finds_item", .body = point_finds_item},
}};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "gui_scroll_tests: mọi ca phải qua");
    return 0;
}
