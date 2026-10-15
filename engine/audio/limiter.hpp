/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/audio/limiter.hpp
 *  PHÂN HỆ   : Audio / Limiter
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ hạn biên ở đầu ra bộ trộn thay cho cắt cụt ở +-1: cả khung (hai kênh
 *    cùng hệ số) kéo xuống vừa đủ, giữ dạng sóng, không sinh hài.
 *  - Không trễ: hạ ngay tại mẫu vượt trần, giữ 20 ms rồi nhả dần; tín hiệu chưa
 *    chạm trần đi qua nguyên vẹn từng bit.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

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
