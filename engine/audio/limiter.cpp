// Xem limiter.hpp. Nhả theo hàm mũ với hằng thời gian 150 ms: sau khoảng nửa giây yên thì hệ số về
// lại đúng 1.
#include "audio/limiter.hpp"

#include "audio/limits.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::audio {
namespace {

constexpr std::uint32_t kHoldFrames = kSampleRate / 50;
// 1 - exp(-1 / (0,15 s * 48000)).
constexpr float kReleaseStep = 1.3888e-4F;
// Sát 1 thì về hẳn 1 (bước nhảy 0,009 dB): bước nhả nhỏ dần tới dưới độ phân giải của float ở
// quanh 0,9998 nên phép cộng không tự tới 1 được, mà tín hiệu sau đó phải nguyên vẹn.
constexpr float kNearUnity = 0.999F;

} // namespace

// Hệ số sau một mẫu nhả, không vượt mức mẫu hiện tại cho phép.
float Limiter::released(float wanted) const noexcept {
    const float risen = gain_ + ((1.F - gain_) * kReleaseStep);
    if (risen > kNearUnity) return wanted;
    return std::min(wanted, risen);
}

void Limiter::process_frame(std::span<float> frame) noexcept {
    const float peak = std::max(std::abs(frame[0]), std::abs(frame[1]));
    const float wanted = peak > kLimiterCeiling ? kLimiterCeiling / peak : 1.F;
    if (wanted <= gain_) {
        gain_ = wanted;
        hold_ = kHoldFrames;
    } else if (hold_ > 0) {
        hold_ -= 1;
    } else {
        gain_ = released(wanted);
    }
    if (gain_ >= 1.F) return;
    deepest_ = std::min(deepest_, gain_);
    frame[0] *= gain_;
    frame[1] *= gain_;
}

void Limiter::process(std::span<float> interleaved_stereo) noexcept {
    const std::size_t frames = interleaved_stereo.size() / 2;
    for (std::size_t frame = 0; frame < frames; ++frame) {
        process_frame(interleaved_stereo.subspan(frame * 2, 2));
    }
}

} // namespace game::audio
