/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/detail_governor.hpp
 *  PHÂN HỆ   : Render / Detail Governor
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ chỉnh trần tam giác theo thời gian khung (Forward::set_triangle_cap).
 *    Điện thoại không có ngân sách cố định: GE8320 của tablet thử nghiệm chỉ
 *    kham ~300 nghìn tam giác ở 30 khung/giây, máy mới kham gấp nhiều lần.
 *    Khung chậm hơn đích thì hạ trần nhanh, khung còn dư thì nâng trần chậm hơn
 *    để chi tiết không dao động.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <algorithm>
#include <cstdint>

namespace game::render {

struct DetailConfig {
    std::uint32_t start_cap = 300'000;
    std::uint32_t floor_cap = 120'000;
    std::uint32_t ceiling_cap = 1'600'000;
    // Khung đích, ms (30 khung/giây).
    double target_ms = 1000.0 / 30.0;
    // Số khung mỗi lần cân nhắc.
    std::uint32_t window = 24;
    // Khung dài hơn mức này là nạp cảnh hay treo, không phải tải của cảnh vẽ: bỏ khỏi trung bình.
    double ignore_ms = 250.0;
};

class DetailGovernor {
public:
    explicit DetailGovernor(const DetailConfig& config) noexcept : config_(config), cap_(clamped(config.start_cap)) {}

    // Ghi một khung; trả true khi trần vừa đổi. Khung không hữu hạn hoặc quá ignore_ms bị bỏ.
    bool note_frame(double interval_ms) noexcept {
        const bool is_usable = interval_ms > 0.0 && interval_ms <= config_.ignore_ms;
        if (!is_usable) return false;
        sum_ms_ += interval_ms;
        if (++frames_ < config_.window) return false;
        const double average = sum_ms_ / static_cast<double>(frames_);
        sum_ms_ = 0.0;
        frames_ = 0;
        const std::uint32_t before = cap_;
        if (average > config_.target_ms * kSlowFactor) cap_ = clamped(scaled(cap_, kCutFactor));
        if (average < config_.target_ms * kFastFactor) cap_ = clamped(scaled(cap_, kRaiseFactor));
        return cap_ != before;
    }

    [[nodiscard]] std::uint32_t cap() const noexcept { return cap_; }

private:
    // Chậm hơn đích 12% thì hạ 15%; nhanh hơn đích 20% thì nâng 8%.
    static constexpr double kSlowFactor = 1.12;
    static constexpr double kFastFactor = 0.8;
    static constexpr double kCutFactor = 0.85;
    static constexpr double kRaiseFactor = 1.08;

    [[nodiscard]] static std::uint32_t scaled(std::uint32_t value, double factor) noexcept {
        return static_cast<std::uint32_t>(static_cast<double>(value) * factor);
    }
    [[nodiscard]] std::uint32_t clamped(std::uint32_t value) const noexcept {
        return std::clamp(value, config_.floor_cap, config_.ceiling_cap);
    }

    DetailConfig config_;
    std::uint32_t cap_;
    double sum_ms_ = 0.0;
    std::uint32_t frames_ = 0;
};

} // namespace game::render
