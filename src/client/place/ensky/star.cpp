/*==============================================================================
 *  THIENLONG  |  SAO CỦA BẦU TRỜI ENSCENE
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/place/ensky/star.cpp
 *  PHÂN HỆ   : Place / Ensky
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt star.hpp. Thứ tự phép tính và thứ tự lấy số ngẫu nhiên theo FUN_1802378f0 (vị trí:
 *    góc quay rồi góc nghiêng) và FUN_180237860 (màu: r, g, b, a).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon          TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ensky/star.hpp"

#include <cmath>
#include <cstddef>
#include <numbers>

namespace game::ensky {
namespace {

using Rgba = std::array<float, 4>;

constexpr float kPi = std::numbers::pi_v<float>;
constexpr float kTwoPi = 2.0F * kPi;
// Góc nghiêng chỉ phủ nửa trên bầu trời: [0, PI * 0,5] (DAT_1802bbd78).
constexpr float kHalfTurn = 0.5F;
constexpr float kHoursInDay = 24.0F;
// Hằng của độ hiện (0x1802388e0): nửa ngày, độ rộng vùng ban ngày và độ dốc.
constexpr double kDayCentre = 0.5;
constexpr double kDayHalfWidth = 0.3;
constexpr double kFadeSlope = 4.0;
// starfix: độ lệch cố định thay cho giờ, ra độ hiện 0,8.
constexpr double kFixedOffset = -0.5;
// Màu chỉ đổi khi lệch từ ngưỡng này (DAT_180304ec0).
constexpr double kColourStep = 0.05;
constexpr float kRadiusStep = 0.01F;
constexpr int kCountStep = 2;
constexpr float kByteMax = 255.0F;
// Bản gốc dùng rand(); cố định hạt để cùng một cảnh luôn ra cùng một bầu trời.
constexpr std::uint32_t kSeed = 0x2545F491U;

// xorshift32. unit() trả [0, 1] như Ogre::Math::UnitRandom.
class Random {
public:
    explicit Random(std::uint32_t seed) noexcept : state_(seed) {}

    [[nodiscard]] float unit() noexcept {
        state_ ^= state_ << 13U;
        state_ ^= state_ >> 17U;
        state_ ^= state_ << 5U;
        constexpr float kScale = 1.0F / 16777215.0F;
        return static_cast<float>(state_ >> 8U) * kScale;
    }

    // Ogre::Math::RangeRandom(low, high): low > high vẫn hợp lệ.
    [[nodiscard]] float range(float low, float high) noexcept {
        return ((high - low) * unit()) + low;
    }

private:
    std::uint32_t state_;
};

[[nodiscard]] float clamp_unit(float value) noexcept {
    if (value < 0.0F) return 0.0F;
    if (value > 1.0F) return 1.0F;
    return value;
}

[[nodiscard]] Rgba clamp_colour(const Rgba& colour) noexcept {
    return {
        clamp_unit(colour[0]), clamp_unit(colour[1]), clamp_unit(colour[2]), clamp_unit(colour[3])};
}

[[nodiscard]] bool differs(float current, float next) noexcept {
    const auto step = static_cast<double>(current - next);
    return step >= kColourStep || step <= -kColourStep;
}

// Điều kiện của FUN_180238200 và FUN_180238430: bốn kênh nối bằng VÀ, mỗi kênh phải lệch.
[[nodiscard]] bool all_differ(const Rgba& current, const Rgba& next) noexcept {
    const bool is_red = differs(current[0], next[0]);
    const bool is_green = differs(current[1], next[1]);
    const bool is_blue = differs(current[2], next[2]);
    const bool is_alpha = differs(current[3], next[3]);
    return is_red && is_green && is_blue && is_alpha;
}

// Bộ đệm đỉnh gốc là VET_COLOUR: Ogre cắt (không làm tròn) c * 255 xuống 8 bit.
[[nodiscard]] float quantise(float value) noexcept {
    const float scaled = clamp_unit(value) * kByteMax;
    return static_cast<float>(static_cast<std::uint8_t>(scaled)) / kByteMax;
}

[[nodiscard]] std::array<float, 3> direction_of(Random& random, float radius) noexcept {
    const float yaw = random.range(0.0F, kTwoPi);
    const float pitch = random.range(0.0F, kPi * kHalfTurn);
    const float sin_pitch = std::sin(pitch);
    const float east = sin_pitch * std::cos(yaw) * radius;
    const float up = std::cos(pitch) * radius;
    const float south = sin_pitch * std::sin(yaw) * radius;
    return {east, up, south};
}

[[nodiscard]] Rgba colour_of(Random& random, const Rgba& low, const Rgba& high) noexcept {
    const float red = random.range(low[0], high[0]);
    const float green = random.range(low[1], high[1]);
    const float blue = random.range(low[2], high[2]);
    const float magnitude = random.range(low[3], high[3]);
    return {quantise(red), quantise(green), quantise(blue), quantise(magnitude)};
}

} // namespace

void StarField::set_min_colour(const Rgba& next) noexcept {
    const Rgba clamped = clamp_colour(next);
    if (!all_differ(min_colour_, clamped)) return;
    min_colour_ = clamped;
}

void StarField::set_max_colour(const Rgba& next) noexcept {
    // Phép thử dùng bản đã kẹp, nhưng giá trị lưu là bản gốc chưa kẹp (0x180238200).
    const Rgba clamped = clamp_colour(next);
    if (!all_differ(max_colour_, clamped)) return;
    max_colour_ = next;
}

// 0x1802383d0: bỏ qua 0 và mức lệch không quá 2 so với số sao hiện có.
void StarField::set_count(std::uint16_t next) noexcept {
    if (next == 0) return;
    const int step = static_cast<int>(next) - static_cast<int>(count_);
    if (std::abs(step) <= kCountStep) return;
    count_ = next;
}

// 0x180238390: chỉ đổi khi lệch hơn 0,01.
void StarField::set_radius(float next) noexcept {
    if (!(std::fabs(radius_ - next) > kRadiusStep)) return;
    radius_ = next;
}

void StarField::apply(const Star& config) {
    is_enabled_ = config.is_enabled;
    if (!is_enabled_) return;
    set_min_colour(config.start_colour);
    size_ = config.size;
    intensity_ = config.intensity;
    speed_ = config.flicker_speed;
    set_count(static_cast<std::uint16_t>(config.count));
    set_radius(config.radius);
    set_max_colour(config.end_colour);
    is_fixed_ = config.is_fixed;
}

void StarField::set_hour(float hour) noexcept {
    const auto day = static_cast<double>(hour / kHoursInDay);
    const double offset = is_fixed_ ? kFixedOffset : day - kDayCentre;
    visibility_ = static_cast<float>((std::fabs(offset) - kDayHalfWidth) * kFadeSlope);
}

void StarField::advance(float seconds) noexcept {
    const float next = (speed_ * seconds) + phase_;
    const bool is_high = 1.0F <= next && speed_ > 0.0F;
    const bool is_low = next <= 0.0F && speed_ < 0.0F;
    phase_ = next;
    if (is_high || is_low) speed_ = speed_ * -1.0F;
}

std::vector<StarPoint> StarField::build() const {
    std::vector<StarPoint> points;
    if (count_ < 2) return points;
    points.reserve(static_cast<std::size_t>(count_) - 1U);
    Random random(kSeed);
    for (std::uint16_t index = 1; index < count_; ++index) {
        StarPoint point;
        point.position = direction_of(random, radius_);
        point.colour = colour_of(random, min_colour_, max_colour_);
        points.push_back(point);
    }
    return points;
}

} // namespace game::ensky
