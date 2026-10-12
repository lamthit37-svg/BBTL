// Bộ hạn biên ở đầu ra của bộ trộn, thay cho việc cắt cụt ở +-1. Tổng nhiều tiếng vượt trần thì cả
// khung (hai kênh cùng hệ số) được kéo xuống vừa đủ, giữ nguyên dạng sóng; cắt cụt thì bẻ gãy
// từng đỉnh và sinh hài nghe rõ. Không trễ: hệ số hạ ngay tại mẫu vượt trần, giữ 20 ms rồi nhả
// dần, nên đỉnh nối đỉnh (mọi tần số trên 25 Hz) được ép bằng một hệ số không đổi. Tín hiệu chưa
// chạm trần đi qua nguyên vẹn từng bit.
#pragma once

#include "audio/limits.hpp"

#include <cstdint>
#include <span>

namespace game::audio {

class Limiter {
public:
    // Stereo xen kẽ, sửa tại chỗ.
    void process(std::span<float> interleaved_stereo) noexcept;

    // Hệ số đang áp: 1 là không ép.
    [[nodiscard]] float gain() const noexcept { return gain_; }

    // Hệ số nhỏ nhất từng áp từ lúc dựng.
    [[nodiscard]] float deepest() const noexcept { return deepest_; }

private:
    [[nodiscard]] float released(float wanted) const noexcept;
    void process_frame(std::span<float> frame) noexcept;

    float gain_ = 1.F;
    float deepest_ = 1.F;
    std::uint32_t hold_ = 0;
};

} // namespace game::audio
