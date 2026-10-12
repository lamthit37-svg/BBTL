// Bàn phím ảo của client 2026 (Falagard/SoftKeyWindow, lớp FalagardSoftKeyBoard của
// CEGUIFalagard.dll): lưới 15 cột, 5 hàng gồm 75 ô phím. Tệp này nêu thứ tự các ô theo nhóm phím,
// để bảng của ui biết ô được nhấn là phím gì và đưa ký tự của từng ô cho bộ vẽ. Vị trí từng ô, ảnh
// nền và chữ là việc của bộ vẽ (gui/softkey.cpp).
// Ký tự của 68 ô đầu do người gọi đưa bằng Override "Keys" trên cửa sổ bàn phím: một ký tự ASCII
// cho mỗi ô, theo đúng thứ tự ô; bản gốc xoay vòng ký tự ngẫu nhiên trong từng nhóm nên bộ vẽ
// không tự biết. Ô không có ký tự (chuỗi ngắn hơn) thì chỉ vẽ nền phím.
// Nguồn: resetAllPosition (0x18007eb80), setKeyPosition (0x180080d90) và initialise (0x18007df30)
// của CEGUIFalagard.dll bản 2026; tên hàm theo CEGUIFalagardEx/FalagardSoftKeyBoard.cpp của mã 2008.
#pragma once

#include <cstddef>

namespace game::gui {

// Một dải ô liền nhau trong thứ tự ô của bàn phím ảo.
struct SoftKeySpan {
    std::size_t first = 0;
    std::size_t count = 0;
};

// Thứ tự ô: 10 phím số, 26 phím chữ, 32 phím dấu, rồi các ô của ba phím lớn (xoá lùi và Shift mỗi
// phím hai ô, Return ba ô). Trong một nhóm, ô xếp theo thứ tự resetAllPosition thêm vào.
inline constexpr SoftKeySpan kSoftNumbers{.first = 0, .count = 10};
inline constexpr SoftKeySpan kSoftLetters{.first = 10, .count = 26};
inline constexpr SoftKeySpan kSoftMarks{.first = 36, .count = 32};
inline constexpr SoftKeySpan kSoftBack{.first = 68, .count = 2};
inline constexpr SoftKeySpan kSoftShift{.first = 70, .count = 2};
inline constexpr SoftKeySpan kSoftReturn{.first = 72, .count = 3};

// Số ô mang ký tự (ba nhóm đầu) và tổng số ô.
inline constexpr std::size_t kSoftCharCells = 68;
inline constexpr std::size_t kSoftCells = 75;

// Ô cell có nằm trong dải span không.
[[nodiscard]] constexpr bool holds(SoftKeySpan span, std::size_t cell) noexcept {
    return cell >= span.first && cell - span.first < span.count;
}

static_assert(kSoftMarks.first + kSoftMarks.count == kSoftCharCells);
static_assert(kSoftReturn.first + kSoftReturn.count == kSoftCells);
static_assert(holds(kSoftLetters, 35) && !holds(kSoftLetters, 36) && !holds(kSoftLetters, 9));

} // namespace game::gui
