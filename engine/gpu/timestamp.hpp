/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/gpu/timestamp.hpp
 *  PHÂN HỆ   : Gpu / Timestamp
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Số học dấu thời gian của GPU, không phụ thuộc API — rhi/timestamp.hpp của
 *    Platium. Bộ đếm của một hàng đợi có thể hẹp hơn 64 bit (Vulkan báo
 *    timestampValidBits theo từng queue family), các bit cao khi ấy là rác chứ
 *    không phải 0, và bộ đếm quay vòng. _Ref đọc thẳng giá trị thô rồi nhân với
 *    chu kỳ, đúng trên máy có 64 bit và ra một khoảng hàng nghìn năm trên máy
 *    có 32 bit. Tách khỏi backend để phép thử gọi thẳng: trên máy phát triển
 *    mọi hàng đợi đều cho 64 bit nên nhánh che không bao giờ chạy qua GPU thật.
 *  - Nguồn: Forge2 src/gpu/timestamp.hpp@d7fcd76. Khác gốc: không.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <cstdint>

namespace game::gpu {

// Giữ valid_bits bit thấp của raw. 64 bit thì không che: dịch trái 64 trên kiểu 64 bit là hành vi
// không xác định.
[[nodiscard]] constexpr std::uint64_t mask_timestamp(std::uint64_t raw, std::uint32_t valid_bits) noexcept {
    if (valid_bits == 0) return 0;
    if (valid_bits >= 64) return raw;
    return raw & ((std::uint64_t{1} << valid_bits) - 1);
}

// Khoảng cách từ first tới second tính bằng nhịp của bộ đếm, đúng cả khi bộ đếm vừa quay vòng:
// phép trừ chạy trong số học modulo 2^valid_bits.
[[nodiscard]] constexpr std::uint64_t timestamp_ticks(std::uint64_t first, std::uint64_t second,
    std::uint32_t valid_bits) noexcept {
    const std::uint64_t begin = mask_timestamp(first, valid_bits);
    const std::uint64_t end = mask_timestamp(second, valid_bits);
    return mask_timestamp(end - begin, valid_bits);
}

// Khoảng cách có dấu từ first tới second: âm khi second đứng trước first. Đúng khi hai mốc cách
// nhau dưới nửa vòng của bộ đếm; dùng để so các mốc đọc cùng một lượt mà không cần biết thứ tự.
[[nodiscard]] constexpr std::int64_t timestamp_offset(std::uint64_t first, std::uint64_t second,
    std::uint32_t valid_bits) noexcept {
    const std::uint64_t forward = timestamp_ticks(first, second, valid_bits);
    // Đảo hai mốc cố ý: đây là chiều ngược lại của phép đo phía trên.
    // NOLINTNEXTLINE(readability-suspicious-call-argument)
    const std::uint64_t backward = timestamp_ticks(second, first, valid_bits);
    if (forward <= backward) return static_cast<std::int64_t>(forward);
    return -static_cast<std::int64_t>(backward);
}

// Nhịp sang nano giây; period_ns là số nano giây mỗi nhịp.
[[nodiscard]] constexpr double ticks_to_ns(std::uint64_t ticks, double period_ns) noexcept {
    return static_cast<double>(ticks) * period_ns;
}

} // namespace game::gpu
