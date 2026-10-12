// Đổi tần số lấy mẫu bằng bộ lọc sinc cửa sổ Kaiser đa pha: 96 hệ số cho mỗi mẫu ra khi nâng tần
// số, dải chắn sâu hơn 100 dB. Tệp của client gốc là 22,05 hoặc 44,1 kHz còn bộ trộn chạy 48 kHz;
// nội suy tuyến tính của miniaudio để ảnh phổ gập vào dải nghe (đo: sin 10 kHz ở 44,1 kHz ra kèm
// thành phần lạ -21 dB), nên việc đổi tần số làm ở đây. Tỉ số hai tần số là số hữu tỉ: vị trí đọc
// tính bằng số nguyên nên không trôi dù chạy bao lâu. Dùng ở ba chỗ: hiệu ứng lúc nạp (một lần),
// nhạc luồng (theo khối, ở luồng giải mã) và đầu ra khi thiết bị không chạy 48 kHz.
#pragma once

#include "audio/limits.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <vector>

namespace game::audio {

struct RateChange {
    std::uint32_t source_rate = kSampleRate;
    std::uint32_t target_rate = kSampleRate;
    std::uint32_t channels = 2;
};

// Một dòng âm thanh liên tục. Mẫu ra thứ n ứng với thời điểm n / target_rate của nguồn (bộ lọc
// đối xứng, độ trễ đã bù), nên nối vòng nhạc không lệch pha.
class Resampler {
public:
    explicit Resampler(RateChange change);

    // Số khung nguồn còn phải push thêm để pull được target_frames khung.
    [[nodiscard]] std::uint32_t needed(std::uint32_t target_frames) const noexcept;

    // Nạp khung nguồn xen kẽ theo kênh.
    void push(std::span<const float> interleaved);

    // Ghi tối đa interleaved.size() / channels khung; trả số khung đã ghi.
    [[nodiscard]] std::uint32_t pull(std::span<float> interleaved) noexcept;

    // Hết nguồn: nạp im lặng đủ để bộ lọc nhả nốt các khung cuối.
    void finish();

    // Về trạng thái vừa dựng, giữ bảng hệ số.
    void reset();

    // Đặt trước chỗ cho mỗi lần push tối đa frames khung: sau đó push và pull không cấp phát,
    // dùng được trong callback của thiết bị.
    void reserve(std::uint32_t frames);

private:
    [[nodiscard]] std::span<std::vector<float>> channels() noexcept;
    void build_table(double cutoff);
    [[nodiscard]] bool is_ready() const noexcept;
    [[nodiscard]] const float* current_row() noexcept;
    void write_frame(std::span<float> frame) noexcept;
    void step() noexcept;
    void compact() noexcept;

    std::vector<float> table_;
    std::vector<float> blended_;
    std::array<std::vector<float>, 2> held_;
    std::uint64_t base_ = 0;
    std::uint32_t remainder_ = 0;
    std::uint32_t source_ = kSampleRate;
    std::uint32_t target_ = kSampleRate;
    std::uint32_t channels_ = 2;
    std::uint32_t half_ = 0;
    std::uint32_t taps_ = 0;
    std::uint32_t phases_ = 1;
    bool is_exact_ = true;
};

// Đổi trọn một đoạn: số khung ra là frames * target / source làm tròn lên.
[[nodiscard]] std::vector<float> resample_all(std::span<const float> interleaved, RateChange change);

} // namespace game::audio
