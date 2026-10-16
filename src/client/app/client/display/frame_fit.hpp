// Khung cố định của một thủ tục đặt vào màn hình khác tỉ lệ: lấy trọn một cạnh, canh giữa, dư ra hai dải
// đen. Máy tính bảng Android 16:10 mở màn đăng nhập trong khung 1280x720 như cửa sổ PC của client gốc
// (CGamePro_Login::Init cố định vùng chơi 0x500 x 0x2d0), nên cảnh nền, camera và giao diện dựng đúng tỉ
// lệ 16:9 thay vì kéo dãn sang 16:10. Cùng ý fit_frame của dự án 2027 (Map/Xform.cpp).
#pragma once

#include <cstdint>

namespace game::client {

// Hình chữ nhật trong màn hình, điểm ảnh, gốc ở góc trên trái.
struct FrameRect {
    std::uint32_t x = 0;
    std::uint32_t y = 0;
    std::uint32_t width = 0;
    std::uint32_t height = 0;

    friend constexpr bool operator==(const FrameRect&, const FrameRect&) = default;
};

// Khung có tỉ lệ design_w:design_h lớn nhất nằm trọn trong màn pixels_w x pixels_h, canh giữa. Tỉ lệ đã
// khớp, hoặc một cạnh bằng 0, thì trả trọn màn. Cỡ lẻ làm tròn xuống điểm ảnh.
[[nodiscard]] constexpr FrameRect fit_frame(std::uint32_t pixels_w, std::uint32_t pixels_h, std::uint32_t design_w,
    std::uint32_t design_h) noexcept {
    const FrameRect whole{.x = 0, .y = 0, .width = pixels_w, .height = pixels_h};
    if (pixels_w == 0 || pixels_h == 0 || design_w == 0 || design_h == 0) return whole;
    // So tỉ lệ bằng nhân chéo trên số nguyên 64 bit: không chia số thực nên 1280x720 trên 1280x720 khớp đúng.
    const std::uint64_t have = std::uint64_t{pixels_w} * design_h;
    const std::uint64_t want = std::uint64_t{design_w} * pixels_h;
    if (have == want) return whole;
    // Màn rộng hơn khung: lấy trọn chiều cao, dải đen hai bên. Chiều rộng tính ra không vượt pixels_w vì have > want.
    if (have > want) {
        const auto width = static_cast<std::uint32_t>(std::uint64_t{pixels_h} * design_w / design_h);
        return {.x = (pixels_w - width) / 2, .y = 0, .width = width, .height = pixels_h};
    }
    // Màn cao hơn khung: lấy trọn chiều rộng, dải đen trên dưới. Chiều cao tính ra không vượt pixels_h vì have < want.
    const auto height = static_cast<std::uint32_t>(std::uint64_t{pixels_w} * design_h / design_w);
    return {.x = 0, .y = (pixels_h - height) / 2, .width = pixels_w, .height = height};
}

// Một trục của khung: gốc và độ dài, điểm ảnh.
struct FrameSpan {
    std::uint32_t origin = 0;
    std::uint32_t length = 0;
};

// Toạ độ chuẩn hoá theo cả màn (0..1 trên một trục) đổi sang chuẩn hoá theo khung trên cùng trục; pixels là
// độ dài cả màn. Chạm ngoài khung thì ra ngoài [0, 1].
[[nodiscard]] constexpr float unit_in_frame(float unit, std::uint32_t pixels, FrameSpan span) noexcept {
    if (span.length == 0) return unit;
    const float pixel = unit * static_cast<float>(pixels);
    return (pixel - static_cast<float>(span.origin)) / static_cast<float>(span.length);
}

} // namespace game::client
