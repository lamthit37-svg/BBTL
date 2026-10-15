// Màu mà FalagardSuperProgress nhân vào state Enabled của thanh (ColourRect ở cửa sổ + 0xadc, CEGUIFalagard.dll 2026).
// Hàm 0x18007a250 tính lại màu đó mỗi lần updateSelf (0x18007a760) thấy mức đang chạy chưa tới đích, theo mức vừa chạy:
// - EffectColorType "uninterrupted" (đặt cờ ở cửa sổ + 0xa78 về 0, hàm 0x180079770): nội suy giữa startcolor và endcolor
//   của UseUninterruptedEffectColor khi (int)(mức * 100) nằm trong [startpoint, endpoint], ngoài khoảng đó là defcolor;
// - mặc định (cờ 1, hàm tạo 0x180075fc0) và "effectlevel": một trong 11 màu của EffectColorLevel, chọn theo
//   clamp((int)(mức * 10), 0, 10). Hàm tạo đặt cả 11 màu và màu hiện hành thành trắng; EffectColorLevel index:N đặt
//   màu cho các chỉ số N..10 (setEffectColorLevel 0x18007a5b0).
// Khác gốc: một ColourRect có bốn góc mà quad của bộ vẽ chỉ mang một màu, nên mỗi ColourRect lấy trung bình bốn góc
// (mọi layout của khung nhân vật dùng bốn góc cùng màu); startpoint trùng endpoint thì hàm gốc chia cho 0 ra NaN, bản
// này lấy màu đầu; FlashPoint và FlashSetting (nháy khi mức qua mốc, hàm 0x180077f40) chưa port (docs/NGHI-NGO.md mục 18).
#pragma once

#include "gui/asset.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::gui::detail {

inline constexpr std::size_t kTintLevels = 11;
// Màu của ColourRect khi chưa ai đặt (colour() của CEGUI: đen, đục hẳn).
inline constexpr std::uint32_t kOpaqueBlack = 0xFF000000U;

struct BarTint {
    bool is_uninterrupted = false;
    std::array<std::uint32_t, kTintLevels> levels{};
    std::int32_t start_point = 0;
    std::int32_t end_point = 0;
    std::uint32_t start_colour = kOpaqueBlack;
    std::uint32_t end_colour = kOpaqueBlack;
    std::uint32_t default_colour = kOpaqueBlack;

    BarTint() { levels.fill(kWhiteArgb); }

    // Màu của thanh khi mức đang chạy là shown (0..1), như hàm 0x18007a250.
    [[nodiscard]] std::uint32_t at(float shown) const noexcept;
};

// Trung bình bốn góc của một ColourRect, từng kênh (xem Khác gốc ở đầu tệp).
[[nodiscard]] std::uint32_t mean_colour(const GuiColours& corners) noexcept;

// Một thuộc tính của cửa sổ; tên không thuộc bốn thuộc tính màu của SuperProgress thì bỏ qua, giá trị hỏng thì giữ
// nguyên như hàm gốc (sscanf không đọc được thì biến giữ nguyên).
void apply_tint_property(BarTint& tint, const GuiProperty& property);

// Mọi thuộc tính màu theo thứ tự áp: thuộc tính của look trước (PropertyInitialiser chạy lúc dựng cửa sổ), rồi thuộc
// tính của layout.
[[nodiscard]] BarTint read_bar_tint(std::span<const GuiProperty> from_look, std::span<const GuiProperty> from_layout);

} // namespace game::gui::detail
