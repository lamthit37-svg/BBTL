// Số học của thanh cuộn dọc và của danh sách có mục cao đều, dùng chung cho bộ dàn trang (vẽ) và
// kho trạng thái của các bảng (ui/panel/widgets, nơi giữ vị trí cuộn như Scrollbar của CEGUI giữ).
// Port từ mã máy CEGUIBase.dll và CEGUIFalagard.dll của client 2026 (docs/GIAO-DIEN-2026.md mục
// listbox và thanh cuộn); địa chỉ hàm gốc ghi ở từng hàm. Vị trí cuộn là điểm ảnh, không làm tròn.
// Thuần số học, không cấp phát; danh sách duyệt tuyến tính theo số mục như bản gốc.
#pragma once

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>

namespace game::gui {

// Cỡ tài liệu và cỡ trang của một thanh cuộn (Scrollbar::d_documentSize, d_pageSize).
struct ScrollSpan {
    float document = 0.0F;
    float page = 0.0F;
};

// Vị trí cuộn lớn nhất: max(document - page, 0).
[[nodiscard]] constexpr float scroll_limit(ScrollSpan span) noexcept {
    return std::max(span.document - span.page, 0.0F);
}

// Scrollbar::setScrollPosition (Base 0x1801037e0): kẹp vào [0, scroll_limit]; số không hữu hạn về 0.
[[nodiscard]] constexpr float clamp_scroll(ScrollSpan span, float wanted) noexcept {
    if (!(wanted > 0.0F)) return 0.0F;
    return std::min(wanted, scroll_limit(span));
}

// Bước của nút lên xuống và của một nấc bánh xe: max(1, page / 10), như configureScrollbars của
// Listbox (Base 0x1800d5e90) và FalagardComplexWindow (Fal 0x180073760).
[[nodiscard]] constexpr float scroll_step(float page) noexcept {
    return std::max(1.0F, page / 10.0F);
}

// Thanh cuộn hiện khi tài liệu dài hơn trang (so sánh chặt).
[[nodiscard]] constexpr bool is_scrollable(ScrollSpan span) noexcept {
    return span.document > span.page;
}

// Rãnh của thumb trong thanh cuộn: mép trên của ThumbTrackArea và quãng thumb chạy được (cao rãnh
// trừ cao thumb), cùng một hệ toạ độ.
struct ThumbTrack {
    float top = 0.0F;
    float slide = 0.0F;
};

// FalagardScrollbar::updateThumb (Fal 0x1800468c0): mép trên của thumb, đã làm tròn về điểm ảnh
// như PixelAligned (cắt về 0). Tài liệu vừa khít trang thì thumb đứng ở đầu rãnh.
[[nodiscard]] constexpr float thumb_top(ThumbTrack track, ScrollSpan span, float position) noexcept {
    constexpr float kTiny = 9.99999994e-09F;
    const float extent = span.document - span.page;
    const float magnitude = extent < 0.0F ? -extent : extent;
    const float raw = magnitude <= kTiny ? track.top : track.top + ((track.slide / extent) * position);
    // NOLINTNEXTLINE(bugprone-incorrect-roundings): (int)(x + 0.5f) của CEGUI, giữ đúng mã máy (HP-07).
    return static_cast<float>(static_cast<int>(raw + 0.5F));
}

// FalagardScrollbar::getValueFromThumb (Fal 0x1800465c0): vị trí cuộn ứng với mép trên top của
// thumb. Rãnh không có quãng chạy hay tài liệu vừa khít trang thì 0 (bản gốc chia cho 0).
[[nodiscard]] constexpr float scroll_from_thumb(ThumbTrack track, ScrollSpan span, float top) noexcept {
    const float extent = span.document - span.page;
    if (track.slide <= 0.0F || extent <= 0.0F) return 0.0F;
    return (top - track.top) / (track.slide / extent);
}

// Một danh sách có count mục cao đều row trong vùng cao page (ListboxTextItem một dòng: cao phông
// cộng LineSpace 3).
struct ListSpan {
    float page = 0.0F;
    float row = 0.0F;
    std::size_t count = 0;

    [[nodiscard]] constexpr ScrollSpan scroll() const noexcept {
        return ScrollSpan{.document = row * static_cast<float>(count), .page = page};
    }
};

// Listbox::getFirstVisibleItem (Base 0x1800d6420): chỉ số mục đầu tiên có mép dưới nằm dưới mép
// trên của vùng; -1 khi không có mục nào.
[[nodiscard]] constexpr std::int32_t first_visible(const ListSpan& list, float position) noexcept {
    float bottom = -position;
    for (std::size_t index = 0; index < list.count; ++index) {
        bottom += list.row;
        if (bottom > 0.0F) return static_cast<std::int32_t>(index);
    }
    return -1;
}

// Listbox::setFirstVisibleItem (Base 0x1800d7a80): vị trí cuộn đưa mục index lên mép trên của
// vùng, lùi lại khi đã ở trang cuối. nullopt khi bản gốc không đổi gì: index ngoài danh sách, hay
// tổng cao đúng bằng cao vùng.
[[nodiscard]] constexpr std::optional<float> scroll_for_first(const ListSpan& list, std::size_t index) noexcept {
    if (index >= list.count) return std::nullopt;
    float top = 0.0F;
    float total = 0.0F;
    for (std::size_t item = 0; item < list.count; ++item) {
        if (item < index) top += list.row;
        total += list.row;
    }
    if (total == list.page) return std::nullopt;
    if (list.page > total - top) top = total - list.page;
    return clamp_scroll(list.scroll(), top);
}

// Một điểm hỏi trong vùng mục: danh sách đang cuộn tới position, điểm cách mép trên của vùng down
// điểm ảnh.
struct ListProbe {
    float position = 0.0F;
    float down = 0.0F;
};

// Listbox::getItemAtPoint (Base 0x1800d64e0): chỉ số mục chứa điểm probe; nullopt khi điểm nằm trên
// mục đầu hay dưới mục cuối. Người gọi đã kiểm điểm nằm trong vùng.
[[nodiscard]] constexpr std::optional<std::size_t> item_at(const ListSpan& list, ListProbe probe) noexcept {
    float edge = -probe.position;
    if (probe.down < edge) return std::nullopt;
    for (std::size_t index = 0; index < list.count; ++index) {
        edge += list.row;
        if (edge > probe.down) return index;
    }
    return std::nullopt;
}

} // namespace game::gui
