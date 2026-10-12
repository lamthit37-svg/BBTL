// Xem resample.hpp. Mỗi hàng của bảng là bộ hệ số cho một pha lẻ của vị trí đọc; hàng được chuẩn
// hoá tổng bằng 1 để mức một chiều không gợn theo pha. Khi mẫu số của tỉ số tần số không quá
// kMaxPhases thì mỗi pha có đúng một hàng; tỉ số lạ hơn thì trộn hai hàng kề nhau.
#include "audio/resample.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <numbers>
#include <numeric>
#include <span>
#include <vector>

// Bảng hệ số và mẫu đang giữ là mảng động; chỉ số đã được is_ready và build_table giữ trong
// biên. NOLINTBEGIN(cppcoreguidelines-pro-bounds-pointer-arithmetic)

namespace game::audio {
namespace {

// Số lần sinc đổi dấu mỗi bên khi nâng tần số: 96 hệ số cho một mẫu ra.
constexpr std::uint32_t kZeroCrossings = 48;
// Điểm -6 dB đặt ở 0,955 lần Nyquist để cả dải chuyển nằm dưới Nyquist: ảnh phổ không lọt ra.
constexpr double kBandwidth = 0.955;
// Kaiser beta 10,5 cho dải chắn khoảng -104 dB.
constexpr double kKaiserBeta = 10.5;
constexpr std::uint32_t kMaxPhases = 1024;
constexpr int kBesselTerms = 48;

// I0 của Bessel bằng chuỗi luỹ thừa; 48 số hạng thừa cho đối số tới beta.
[[nodiscard]] double bessel_i0(double value) noexcept {
    const double quarter = value * value * 0.25;
    double term = 1.0;
    double sum = 1.0;
    for (int step = 1; step < kBesselTerms; ++step) {
        const auto count = static_cast<double>(step);
        term *= quarter / (count * count);
        sum += term;
    }
    return sum;
}

[[nodiscard]] double sinc(double value) noexcept {
    if (std::abs(value) < 1.0e-9) return 1.0;
    const double turn = std::numbers::pi * value;
    return std::sin(turn) / turn;
}

// Hình bộ lọc theo đơn vị mẫu nguồn: cutoff là phần của Nyquist nguồn, half là nửa bề rộng cửa sổ.
struct Shape {
    double cutoff = 1.0;
    double half = 1.0;
    double window_peak = 1.0;
};

[[nodiscard]] double kernel(double offset, const Shape& shape) noexcept {
    const double place = offset / shape.half;
    const double inside = 1.0 - (place * place);
    if (inside <= 0.0) return 0.0;
    const double window = bessel_i0(kKaiserBeta * std::sqrt(inside)) / shape.window_peak;
    return shape.cutoff * sinc(shape.cutoff * offset) * window;
}

// Hệ số thứ tap của hàng nhân với mẫu nguồn cách vị trí đọc (tap + 1 - half - fraction) mẫu.
void fill_row(std::span<float> row, double fraction, const Shape& shape) noexcept {
    double sum = 0.0;
    for (std::size_t tap = 0; tap < row.size(); ++tap) {
        const double offset = (static_cast<double>(tap) + 1.0) - shape.half - fraction;
        const double value = kernel(offset, shape);
        row[tap] = static_cast<float>(value);
        sum += value;
    }
    const auto scale = static_cast<float>(1.0 / sum);
    for (float& value : row) {
        value *= scale;
    }
}

// Bốn tổng riêng để phép cộng không nối thành một chuỗi phụ thuộc dài cả hàng. taps chia hết cho 4.
[[nodiscard]] float dot(const float* row, const float* samples, std::uint32_t taps) noexcept {
    std::array<float, 4> sums{};
    for (std::uint32_t tap = 0; tap < taps; tap += 4) {
        sums[0] += row[tap] * samples[tap];
        sums[1] += row[tap + 1] * samples[tap + 1];
        sums[2] += row[tap + 2] * samples[tap + 2];
        sums[3] += row[tap + 3] * samples[tap + 3];
    }
    return (sums[0] + sums[1]) + (sums[2] + sums[3]);
}

// Một kênh của khối xen kẽ: mẫu đầu, số khung, bước giữa hai mẫu cùng kênh.
struct Strided {
    const float* first = nullptr;
    std::size_t frames = 0;
    std::size_t stride = 1;
};

void append_channel(std::vector<float>& held, Strided channel) {
    const std::size_t before = held.size();
    held.resize(before + channel.frames);
    for (std::size_t frame = 0; frame < channel.frames; ++frame) {
        held[before + frame] = channel.first[frame * channel.stride];
    }
}

// Hạ tần số thì bộ lọc rộng ra theo tỉ số. Làm tròn lên số chẵn để số hệ số chia hết cho 4.
[[nodiscard]] std::uint32_t half_width(RateChange change) noexcept {
    const double ratio = static_cast<double>(change.target_rate) / static_cast<double>(change.source_rate);
    const double narrow = std::min(1.0, ratio);
    const double wide = std::ceil(static_cast<double>(kZeroCrossings) / narrow);
    const auto whole = static_cast<std::uint32_t>(wide);
    return whole + (whole % 2);
}

} // namespace

Resampler::Resampler(RateChange change)
    : source_(change.source_rate),
      target_(change.target_rate),
      channels_(change.channels),
      half_(half_width(change)),
      taps_(half_ * 2) {
    core::check(source_ > 0 && target_ > 0, "tần số lấy mẫu phải dương");
    core::check(channels_ == 1 || channels_ == 2, "bộ đổi tần số chỉ nhận một hoặc hai kênh");
    const std::uint32_t exact = target_ / std::gcd(source_, target_);
    is_exact_ = exact <= kMaxPhases;
    phases_ = is_exact_ ? exact : kMaxPhases;
    const double ratio = static_cast<double>(target_) / static_cast<double>(source_);
    build_table(std::min(1.0, ratio) * kBandwidth);
    blended_.assign(taps_, 0.F);
    reset();
}

std::span<std::vector<float>> Resampler::channels() noexcept {
    return std::span(held_).first(channels_);
}

void Resampler::build_table(double cutoff) {
    const Shape shape{
        .cutoff = cutoff,
        .half = static_cast<double>(half_),
        .window_peak = bessel_i0(kKaiserBeta),
    };
    const std::size_t rows = static_cast<std::size_t>(phases_) + 1;
    table_.assign(rows * taps_, 0.F);
    const std::span<float> all(table_);
    for (std::size_t phase = 0; phase < rows; ++phase) {
        const double fraction = static_cast<double>(phase) / static_cast<double>(phases_);
        fill_row(all.subspan(phase * taps_, taps_), fraction, shape);
    }
}

void Resampler::reset() {
    // half_ - 1 mẫu im lặng đứng trước mẫu nguồn đầu tiên: mẫu ra 0 rơi đúng vào mẫu nguồn 0.
    for (std::vector<float>& channel : held_) {
        channel.assign(half_ - 1, 0.F);
    }
    base_ = 0;
    remainder_ = 0;
}

void Resampler::reserve(std::uint32_t frames) {
    // Phần còn giữ sau một lần pull không quá hai bề rộng bộ lọc.
    const std::size_t room = (static_cast<std::size_t>(taps_) * 2) + frames;
    for (std::vector<float>& held : channels()) {
        held.reserve(room);
    }
}

std::uint32_t Resampler::needed(std::uint32_t target_frames) const noexcept {
    if (target_frames == 0) return 0;
    const std::uint64_t steps = static_cast<std::uint64_t>(target_frames) - 1;
    const std::uint64_t travel = remainder_ + (steps * source_);
    const std::uint64_t last_base = base_ + (travel / target_);
    const std::uint64_t required = last_base + taps_;
    const std::uint64_t held = held_.front().size();
    if (required <= held) return 0;
    return static_cast<std::uint32_t>(required - held);
}

void Resampler::push(std::span<const float> interleaved) {
    const std::size_t frames = interleaved.size() / channels_;
    const std::span<std::vector<float>> held = channels();
    for (std::uint32_t channel = 0; channel < channels_; ++channel) {
        const float* first = interleaved.data() + channel;
        append_channel(held[channel], Strided{.first = first, .frames = frames, .stride = channels_});
    }
}

bool Resampler::is_ready() const noexcept {
    return base_ + taps_ <= held_.front().size();
}

const float* Resampler::current_row() noexcept {
    const std::uint64_t scaled = static_cast<std::uint64_t>(remainder_) * phases_;
    const auto phase = static_cast<std::uint32_t>(scaled / target_);
    const float* row = table_.data() + (static_cast<std::size_t>(phase) * taps_);
    if (is_exact_) return row;
    const auto part = static_cast<float>(scaled % target_) / static_cast<float>(target_);
    const float* next = row + taps_;
    for (std::uint32_t tap = 0; tap < taps_; ++tap) {
        blended_[tap] = row[tap] + ((next[tap] - row[tap]) * part);
    }
    return blended_.data();
}

void Resampler::write_frame(std::span<float> frame) noexcept {
    const float* row = current_row();
    const std::span<std::vector<float>> held = channels();
    for (std::uint32_t channel = 0; channel < channels_; ++channel) {
        frame[channel] = dot(row, held[channel].data() + base_, taps_);
    }
}

void Resampler::step() noexcept {
    const std::uint64_t moved = static_cast<std::uint64_t>(remainder_) + source_;
    base_ += moved / target_;
    remainder_ = static_cast<std::uint32_t>(moved % target_);
}

void Resampler::compact() noexcept {
    const std::uint64_t held_frames = held_.front().size();
    const auto dropped = static_cast<std::ptrdiff_t>(std::min(base_, held_frames));
    if (dropped == 0) return;
    for (std::vector<float>& held : channels()) {
        held.erase(held.begin(), held.begin() + dropped);
    }
    base_ -= static_cast<std::uint64_t>(dropped);
}

std::uint32_t Resampler::pull(std::span<float> interleaved) noexcept {
    const auto wanted = static_cast<std::uint32_t>(interleaved.size() / channels_);
    std::uint32_t made = 0;
    while (made < wanted && is_ready()) {
        const std::size_t offset = static_cast<std::size_t>(made) * channels_;
        write_frame(interleaved.subspan(offset, channels_));
        step();
        made += 1;
    }
    compact();
    return made;
}

void Resampler::finish() {
    for (std::vector<float>& held : channels()) {
        held.insert(held.end(), half_, 0.F);
    }
}

std::vector<float> resample_all(std::span<const float> interleaved, RateChange change) {
    Resampler resampler(change);
    const std::uint64_t frames = interleaved.size() / change.channels;
    const std::uint64_t scaled = (frames * change.target_rate) + change.source_rate - 1;
    const std::uint64_t total = scaled / change.source_rate;
    resampler.push(interleaved);
    resampler.finish();
    std::vector<float> made(static_cast<std::size_t>(total) * change.channels);
    const std::uint32_t written = resampler.pull(made);
    made.resize(static_cast<std::size_t>(written) * change.channels);
    return made;
}

// NOLINTEND(cppcoreguidelines-pro-bounds-pointer-arithmetic)

} // namespace game::audio
