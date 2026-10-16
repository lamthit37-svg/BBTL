/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/frame_fit.hpp
 *  PHÂN HỆ   : Client / Display / Frame Fit
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Khung tham chiếu 1280x720 trên màn khác tỉ lệ hay khác mật độ. Cảnh 3D
 *    luôn vẽ trọn màn và camera giữ khung tham chiếu trong tầm nhìn
 *    (render::fitted_fov_y), nên không có dải đen.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chỉ bảng thiết kế cho đúng 1280x720 (màn đăng nhập: client gốc cố định vùng chơi 0x500 x 0x2d0 ở
// CGamePro_Login::Init) mới nằm trong khung đặt giữa màn (placed_frame), như Expand của Unity; fit_frame cùng ý
// Map/Xform.cpp của dự án 2027, khác ở chỗ phần ngoài khung là cảnh chứ không phải màu đen.

#pragma once

#include <cstdint>

namespace game::client {

// Khung tham chiếu của mọi màn: View_Resoution mặc định và vùng chơi cố định của màn đăng nhập client 2026
// (viewer/client_size.hpp). Camera luôn thấy trọn khung này (render::fitted_fov_y), và bảng chỉ thiết kế cho đúng
// khung này đặt trong placed_frame.
inline constexpr std::uint32_t kReferenceWidth = 1280;
inline constexpr std::uint32_t kReferenceHeight = 720;
inline constexpr float kReferenceAspect = static_cast<float>(kReferenceWidth) / static_cast<float>(kReferenceHeight);

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

// Khung tham chiếu kReferenceWidth x kReferenceHeight điểm giao diện đặt giữa màn, density điểm ảnh mỗi điểm giao diện
// (1 trên PC, dpi/160 trên Android, contentScaleFactor trên iOS): không lớn hơn khung nhân mật độ, thu nhỏ giữ tỉ lệ khi
// màn không đủ chỗ. Mật độ không dương coi như 1.
[[nodiscard]] constexpr FrameRect placed_frame(std::uint32_t pixels_w, std::uint32_t pixels_h, float density) noexcept {
    const FrameRect fitted = fit_frame(pixels_w, pixels_h, kReferenceWidth, kReferenceHeight);
    const float scale = density > 0.0F ? density : 1.0F;
    const auto cap_w = static_cast<std::uint32_t>(static_cast<float>(kReferenceWidth) * scale);
    const auto cap_h = static_cast<std::uint32_t>(static_cast<float>(kReferenceHeight) * scale);
    if (fitted.width <= cap_w || fitted.height <= cap_h) return fitted;
    return {.x = (pixels_w - cap_w) / 2, .y = (pixels_h - cap_h) / 2, .width = cap_w, .height = cap_h};
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
