// Vòng đệm khung stereo float cho đúng một luồng ghi và một luồng đọc, không khoá. Luồng giải mã
// nhạc ghi, bộ trộn (callback thiết bị) đọc. Chép theo đoạn liền, không theo từng khung: bộ trộn
// trả giá hai lần chép cho một khối dù thiết bị xin bao nhiêu khung.
#pragma once

#include "core/check.hpp"

#include <algorithm>
#include <atomic>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

namespace game::audio {

class FrameRing {
public:
    // frames là luỹ thừa của hai.
    explicit FrameRing(std::uint32_t frames) : samples_(static_cast<std::size_t>(frames) * 2), mask_(frames - 1) {
        core::check(std::has_single_bit(frames), "sức chứa vòng đệm phải là luỹ thừa của hai");
    }

    [[nodiscard]] std::uint32_t readable() const noexcept {
        const std::uint32_t write = write_.load(std::memory_order_acquire);
        return write - read_.load(std::memory_order_acquire);
    }

    [[nodiscard]] std::uint32_t writable() const noexcept {
        const std::uint32_t read = read_.load(std::memory_order_acquire);
        return (mask_ + 1) - (write_.load(std::memory_order_acquire) - read);
    }

    // Chỉ luồng ghi gọi. Ghi tối đa số khung còn chỗ; trả số khung đã ghi.
    std::uint32_t write(std::span<const float> interleaved) noexcept {
        const auto offered = static_cast<std::uint32_t>(interleaved.size() / 2);
        const std::uint32_t count = std::min(offered, writable());
        const std::uint32_t start = write_.load(std::memory_order_relaxed);
        const std::uint32_t slot = start & mask_;
        const std::uint32_t first = std::min(count, (mask_ + 1) - slot);
        const std::span<float> all(samples_);
        std::ranges::copy(interleaved.first(std::size_t{first} * 2), all.subspan(std::size_t{slot} * 2).begin());
        const std::span<const float> rest = interleaved.subspan(std::size_t{first} * 2, std::size_t{count - first} * 2);
        std::ranges::copy(rest, all.begin());
        write_.store(start + count, std::memory_order_release);
        return count;
    }

    // Chỉ luồng đọc gọi. Đọc tối đa số khung đang có; trả số khung đã đọc.
    std::uint32_t read(std::span<float> interleaved) noexcept {
        const auto wanted = static_cast<std::uint32_t>(interleaved.size() / 2);
        const std::uint32_t count = std::min(wanted, readable());
        const std::uint32_t start = read_.load(std::memory_order_relaxed);
        const std::uint32_t slot = start & mask_;
        const std::uint32_t first = std::min(count, (mask_ + 1) - slot);
        const std::span<const float> all(samples_);
        std::ranges::copy(all.subspan(std::size_t{slot} * 2, std::size_t{first} * 2), interleaved.begin());
        const std::span<const float> rest = all.first(std::size_t{count - first} * 2);
        std::ranges::copy(rest, interleaved.subspan(std::size_t{first} * 2).begin());
        read_.store(start + count, std::memory_order_release);
        return count;
    }

    // Chỉ gọi khi cả hai luồng đều không chạm vòng đệm (bàn nhạc đã dừng).
    void clear() noexcept {
        write_.store(0, std::memory_order_release);
        read_.store(0, std::memory_order_release);
    }

private:
    std::vector<float> samples_;
    std::uint32_t mask_ = 0;
    std::atomic<std::uint32_t> write_{0};
    std::atomic<std::uint32_t> read_{0};
};

} // namespace game::audio
