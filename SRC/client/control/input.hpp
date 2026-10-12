#pragma once
// Thao tác người chơi mà cửa sổ nhận, tách khỏi hệ cửa sổ để control và chương trình không phải
// biết Win32 hay Android. Vị trí con trỏ chuẩn hoá về [0, 1] theo khung cửa sổ, gốc ở góc trái
// trên; độ dời của lần kéo tính bằng điểm (point) của cửa sổ, đúng đơn vị mà client gốc chia cho
// 300 khi xoay. Chạm (Android) tới đây qua TouchGestures (touch.hpp): một ngón như chuột trái, hai
// ngón thành kéo phải và nấc lăn, ngón chạm góc trái dưới thành cần gạt ảo (Stick, StickEnd).
// Nguồn: TLBB Dev src/render/input.hpp@e0d89a6. Khác gốc: namespace game::control; bỏ Key và trường
// của nó (dự án chưa có phím tắt); Text mang một ký tự thay cho một chuỗi; enumerator theo
// kCamelCase.

#include <cstdint>

namespace game::control {

// Cancel: thao tác chuột trái đang dở bị bỏ, nhả mà không phải một lần bấm (touch.hpp). Stick: cần
// gạt ảo đang giữ, mỗi lần ngón của cần chạm hay dời; StickEnd: nhả cần. Text: một ký tự gõ từ bàn
// phím cho ô nhập của giao diện, kể cả xoá lùi (8), Tab (9) và Enter (13).
enum class InputKind : std::uint8_t { kPress, kRelease, kMove, kWheel, kCancel, kStick, kStickEnd, kText };

enum class MouseButton : std::uint8_t { kLeft, kRight, kMiddle, kOther };

struct InputEvent {
    InputKind kind = InputKind::kMove;
    // Nút của Press và Release.
    MouseButton button = MouseButton::kLeft;
    // Vị trí con trỏ của Press, Release, Move; tâm đế cần của Stick.
    float x = 0.0F;
    float y = 0.0F;
    // Độ dời của Move, điểm; độ gạt của Stick, độ dài từ 0 tới 1.
    float dx = 0.0F;
    float dy = 0.0F;
    // Số nấc của Wheel, dương là lăn ra phía trước.
    float wheel = 0.0F;
    // Ký tự của Text: một đơn vị mã như hệ cửa sổ đưa (WM_CHAR là UTF-16).
    char32_t text = 0;
};

} // namespace game::control
