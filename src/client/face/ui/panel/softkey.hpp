// Bàn phím ảo (SoftKeyBoard, layout SoftKeyBoard/SoftKeyBoard.layout.xml) của thủ tục đăng nhập:
// đang mở hay đóng, Shift, và ký tự đang nằm ở từng ô phím. Cửa sổ do SoftKeyBoard.lua gốc mở và
// đóng (OPEN_WINDOW, CLOSE_WINDOW, TOGGLE_WINDOW, nút đóng của layout), chạy trong host script;
// cờ đang mở ở đây theo cờ hiện của cửa sổ đó. Mọi việc còn lại nằm trong lớp FalagardSoftKeyBoard
// của CEGUIFalagard.dll. Bảng ở đây chỉ là trạng thái: ô nào bị nhấn do gui::Hub cho biết, ký tự
// gõ ra trả cho người gọi đưa vào ô nhập đang ngắm.
// Nguồn (CEGUIFalagard.dll bản 2026): initialise 0x18007df30 (bốn dải ký tự), ResetAllKey
// 0x18007d200 (mỗi nhóm ký tự xoay vòng từ một ô bắt đầu ngẫu nhiên), onMouseButtonUp 0x18007e0b0
// (phím ký tự gõ xong thì xoay vòng lại; Shift đổi hoa thường rồi xoay vòng lại; xoá lùi; Return
// chỉ bắn sự kiện ReturnPush, mà không tệp nào của client 2026 nghe sự kiện đó).
// Khác gốc: số ngẫu nhiên là xorshift32 của bảng thay cho rand(); phím ăn ngay lúc nhấn (bản gốc ăn
// lúc nhả trên chính phím đó); chưa kéo được cửa sổ bằng thanh tiêu đề; nút trợ giúp chưa làm gì.
#pragma once

#include "ui/panel/deck.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::ui::panel {

// Layout của bàn phím, đường dẫn tương đối với thư mục Interface.
inline constexpr std::string_view kSoftKeysLayout = "SoftKeyBoard/SoftKeyBoard.layout.xml";
// Cửa sổ chứa các phím (TLBB_SoftKeyWindow): gui::Hub đổi điểm chuột trên nó ra chỉ số ô phím.
inline constexpr std::string_view kSoftKeysWindow = "SoftKeyBoard_SoftKey";

// Ô bắt đầu của từng nhóm ký tự (nStart của ResetAllKey): ký tự thứ start của nhóm nằm ở ô đầu.
struct SoftKeyStarts {
    std::uint8_t numbers = 0;
    std::uint8_t letters = 0;
    std::uint8_t marks = 0;
};

struct SoftKeys {
    bool is_open = false;
    // m_bShiftDown: phím chữ đang là chữ hoa. Giữ nguyên qua các lần đóng mở, như bản gốc.
    bool is_shifted = false;
    SoftKeyStarts starts;
    // Trạng thái bộ sinh xorshift32 của các lần xoay vòng; luôn khác 0.
    std::uint32_t dice = 0x9E3779B9U;
};

// Cửa sổ vừa hiện (onShown): mở và xoay vòng lại các phím. salt là số bất kỳ của người gọi (đồng hồ
// khung) trộn vào bộ sinh để mỗi lần mở một khác.
void open_soft_keys(SoftKeys& keys, std::uint32_t salt) noexcept;
// Cửa sổ vừa ẩn: đóng, giữ Shift.
void close_soft_keys(SoftKeys& keys) noexcept;
// Cửa sổ window có phải mặt phím không: cửa sổ phím, hoặc một trong hai nhãn chữ nằm đè lên phím
// xoá lùi và Shift (layout để chúng nhận chuột).
[[nodiscard]] bool is_soft_key_face(std::string_view window) noexcept;
// Nhấn phím ở ô cell (thứ tự ô của gui/softkey.hpp). Phím ký tự trả ký tự của nó rồi xoay vòng lại
// các phím; xoá lùi trả '\b'; Shift đổi hoa thường rồi xoay vòng lại, Return và ô lạ không làm gì
// (ba trường hợp sau trả nullopt). Bàn phím đang đóng thì không làm gì.
[[nodiscard]] std::optional<char32_t> strike_soft_key(SoftKeys& keys, std::size_t cell) noexcept;
// Ghi chỉ thị của bàn phím cho khung này: đang mở thì kê gốc và đặt ký tự của từng ô (Override
// "Keys" của kSoftKeysWindow); đang đóng thì không ghi gì.
void paint_soft_keys(Deck& deck, const SoftKeys& keys);

} // namespace game::ui::panel
