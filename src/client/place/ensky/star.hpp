/*==============================================================================
 *  THIENLONG  |  SAO CỦA BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/star.hpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Trạng thái và dữ liệu sinh của đám sao EnStar (FixedStar) của Render.dll: setter có
 *    ngưỡng, độ hiện theo giờ, nhấp nháy qua lại, vị trí và màu từng sao. Không dính GPU.
 *  - Setter giữ nguyên điều kiện của mã máy, kể cả chỗ lạ: màu chỉ đổi khi CẢ BỐN kênh lệch
 *    từ 0,05 (0x180238200, 0x180238430), nên EndColour (1,1,1,1) không thay được màu cực đại
 *    mặc định (0,1,1,1) và sao ra tông xanh lục.
 *  - Nguồn: Render.dll 2026 (EnStar 0x1802385b0, FixedStar 0x180237590, dựng đỉnh
 *    0x180237ae0, áp cấu hình EnSky 0x1801ea040, nhấp nháy 0x1801d4020).
 *    Khác gốc: hạt giống ngẫu nhiên cố định (bản gốc dùng rand()).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "ensky/scene.hpp"

#include <array>
#include <cstdint>
#include <vector>

namespace game::ensky {

// Mặc định của hàm dựng EnStar trước khi EnSky áp cấu hình.
inline constexpr std::uint16_t kStarCount = 2000;
inline constexpr float kStarRadius = 10000.0F;
inline constexpr float kStarSize = 10.0F;
inline constexpr float kStarIntensity = 1.0F;
inline constexpr float kStarFlickerSpeed = 0.2F;

// Một sao. position nằm trong không gian nút en_star (đặt tại camera, hướng đơn vị).
// colour là (r, g, b, độ sáng ngẫu nhiên) đã lượng tử 8 bit như bộ đệm đỉnh gốc.
struct StarPoint {
    std::array<float, 3> position{};
    std::array<float, 4> colour{};
};

class StarField {
public:
    // Áp cấu hình theo thứ tự của EnSky::applyStar. Enable tắt thì chỉ ẩn, không đổi gì khác.
    void apply(const Star& config);
    // Độ hiện theo giờ (0x1802388e0): (|giờ / 24 - 0,5| - 0,3) * 4, hoặc 0,8 khi starfix.
    void set_hour(float hour) noexcept;
    // Nhấp nháy qua lại giữa 0 và 1 theo tốc độ FlickerSpeed (0x1801d4020).
    void advance(float seconds) noexcept;

    [[nodiscard]] bool is_enabled() const noexcept { return is_enabled_; }
    // Vẽ khi bật và độ hiện dương (0x180238100 bỏ qua khi không dương).
    [[nodiscard]] bool is_shown() const noexcept { return is_enabled_ && visibility_ > 0.0F; }
    [[nodiscard]] float size() const noexcept { return size_; }
    [[nodiscard]] float intensity() const noexcept { return intensity_; }
    [[nodiscard]] float flicker() const noexcept { return phase_; }
    [[nodiscard]] float visibility() const noexcept { return visibility_; }
    [[nodiscard]] std::uint16_t count() const noexcept { return count_; }
    [[nodiscard]] float radius() const noexcept { return radius_; }
    [[nodiscard]] const std::array<float, 4>& min_colour() const noexcept { return min_colour_; }
    [[nodiscard]] const std::array<float, 4>& max_colour() const noexcept { return max_colour_; }

    // Các sao hiện có. Sao đầu tiên của bản gốc nằm ở gốc toạ độ (sinh lúc bán kính còn 0) và
    // không bao giờ lên màn hình nên bị bỏ: count() - 1 sao.
    [[nodiscard]] std::vector<StarPoint> build() const;

private:
    void set_min_colour(const std::array<float, 4>& next) noexcept;
    void set_max_colour(const std::array<float, 4>& next) noexcept;
    void set_count(std::uint16_t next) noexcept;
    void set_radius(float next) noexcept;

    bool is_enabled_ = false;
    bool is_fixed_ = false;
    std::uint16_t count_ = kStarCount;
    float radius_ = kStarRadius;
    float size_ = kStarSize;
    float intensity_ = kStarIntensity;
    float speed_ = kStarFlickerSpeed;
    // Màu nhỏ nhất đã được EnStar đặt (0,5 mỗi kênh); màu lớn nhất còn ở giá trị dựng sẵn.
    std::array<float, 4> min_colour_{0.5F, 0.5F, 0.5F, 0.5F};
    std::array<float, 4> max_colour_{0.0F, 1.0F, 1.0F, 1.0F};
    // 0x1e8: pha nhấp nháy. 0x234 khởi tạo 1.
    float phase_ = 0.0F;
    float visibility_ = 1.0F;
};

} // namespace game::ensky
