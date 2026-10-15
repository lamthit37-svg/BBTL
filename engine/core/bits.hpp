/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/bits.hpp
 *  PHÂN HỆ   : Core / Bits
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Căn lề, số nguyên little/big-endian trên vùng byte, zigzag. Nguồn:
 *    core/bits của No1 và transport/wire của Forge2 (hai bản đọc/ghi little-
 *    endian y hệt nhau), gộp một chỗ để mọi module dùng chung. Phép bit đơn
 *    giản đã có trong STL (<bit>: has_single_bit, bit_ceil, popcount,
 *    countl_zero) thì dùng thẳng, không bọc lại. Mọi vi phạm tiền điều kiện
 *    dừng ở mọi cấu hình: ghi ngoài vùng byte hay căn lề không phải luỹ thừa
 *    hai là lỗi bộ nhớ chứ không phải lỗi dữ liệu.
 *  - Nguồn: Forge2 src/core/bits.hpp@d7fcd76. Khác gốc: check là bản của
 *    THIENLONG, không định dạng, nên thông điệp của mọi check trong tệp không
 *    kèm số (căn lề, giá trị, cỡ vùng, chỉ số).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/check.hpp"

#include <bit>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <span>
#include <type_traits>

namespace game::core {

// Khác gốc: check của THIENLONG không định dạng. Mọi check trong tệp này giữ nguyên điều kiện,
// thông điệp bỏ phần số mà gốc chèn vào (căn lề, giá trị, cỡ vùng, chỉ số).

// NOLINTBEGIN(bugprone-easily-swappable-parameters): giá trị rồi căn lề như mọi align (lệch API-03)

// Bội của alignment (luỹ thừa hai) nhỏ nhất không dưới value. Tràn kiểu dừng chương trình; No1 cộng
// im lặng quanh vòng.
template <std::unsigned_integral T>
[[nodiscard]] constexpr T align_up(T value, T alignment) noexcept {
    check(std::has_single_bit(alignment), "align_up: căn lề không phải luỹ thừa của hai");
    const T mask = static_cast<T>(alignment - 1);
    check(value <= static_cast<T>(~T{0} - mask), "align_up: căn lên thì tràn kiểu");
    return static_cast<T>(static_cast<T>(value + mask) & static_cast<T>(~mask));
}

// Bội của alignment (luỹ thừa hai) lớn nhất không vượt value.
template <std::unsigned_integral T>
[[nodiscard]] constexpr T align_down(T value, T alignment) noexcept {
    check(std::has_single_bit(alignment), "align_down: căn lề không phải luỹ thừa của hai");
    return static_cast<T>(value & static_cast<T>(~static_cast<T>(alignment - 1)));
}

// NOLINTEND(bugprone-easily-swappable-parameters)

// Địa chỉ có chia hết cho alignment (luỹ thừa hai) không.
[[nodiscard]] inline bool is_aligned(const void* pointer, std::size_t alignment) noexcept {
    check(std::has_single_bit(alignment), "is_aligned: căn lề không phải luỹ thừa của hai");
    return (std::bit_cast<std::uintptr_t>(pointer) & (alignment - 1)) == 0;
}

// Số byte phải cộng vào địa chỉ để tới biên alignment kế tiếp; 0 nếu đã nằm trên biên.
[[nodiscard]] inline std::size_t padding_for(const void* pointer, std::size_t alignment) noexcept {
    check(std::has_single_bit(alignment), "padding_for: căn lề không phải luỹ thừa của hai");
    const auto address = std::bit_cast<std::uintptr_t>(pointer);
    return (std::size_t{0} - address) & (alignment - 1);
}

// Định dạng trên dây và trong tệp của Forge2 là little-endian; x64 và arm64 đều little-endian nên
// đường phổ biến không tốn lệnh nào.
template <std::integral T>
[[nodiscard]] constexpr T to_little_endian(T value) noexcept {
    return std::endian::native == std::endian::little ? value : std::byteswap(value);
}

template <std::integral T>
[[nodiscard]] constexpr T to_big_endian(T value) noexcept {
    return std::endian::native == std::endian::big ? value : std::byteswap(value);
}

template <std::integral T>
[[nodiscard]] T read_little_endian(std::span<const std::byte> bytes) noexcept {
    check(bytes.size() >= sizeof(T), "đọc số nguyên từ vùng byte quá ngắn");
    T raw{};
    std::memcpy(&raw, bytes.data(), sizeof(T));
    return to_little_endian(raw);
}

template <std::integral T>
void write_little_endian(std::span<std::byte> bytes, T value) noexcept {
    check(bytes.size() >= sizeof(T), "ghi số nguyên vào vùng byte quá ngắn");
    const T raw = to_little_endian(value);
    std::memcpy(bytes.data(), &raw, sizeof(T));
}

template <std::integral T>
[[nodiscard]] T read_big_endian(std::span<const std::byte> bytes) noexcept {
    check(bytes.size() >= sizeof(T), "đọc số nguyên từ vùng byte quá ngắn");
    T raw{};
    std::memcpy(&raw, bytes.data(), sizeof(T));
    return to_big_endian(raw);
}

template <std::integral T>
void write_big_endian(std::span<std::byte> bytes, T value) noexcept {
    check(bytes.size() >= sizeof(T), "ghi số nguyên vào vùng byte quá ngắn");
    const T raw = to_big_endian(value);
    std::memcpy(bytes.data(), &raw, sizeof(T));
}

// Zigzag: số âm nhỏ thành số dương nhỏ, để varint của -1 tốn một byte chứ không mười.
[[nodiscard]] constexpr std::uint64_t zigzag(std::int64_t value) noexcept {
    return (static_cast<std::uint64_t>(value) << 1) ^ static_cast<std::uint64_t>(value >> 63);
}

[[nodiscard]] constexpr std::int64_t unzigzag(std::uint64_t value) noexcept {
    return static_cast<std::int64_t>((value >> 1) ^ (std::uint64_t{0} - (value & 1)));
}

// Phần tử thứ index của một vùng nhìn, có kiểm biên ở mọi cấu hình: chỉ số sai là lỗi lập trình và
// dừng tiến trình có báo cáo. std::span::at là C++26, mà preset ubsan dịch đúng C++23.
template <class T, std::size_t Extent>
[[nodiscard]] constexpr T& at(std::span<T, Extent> view, std::size_t index) noexcept {
    check(index < view.size(), "chỉ số ngoài vùng nhìn");
    // Đã kiểm ở dòng trên.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
    return view[index];
}

// Mặt nạ count bit thấp; count từ 64 trở lên là toàn bộ.
[[nodiscard]] constexpr std::uint64_t low_mask(std::uint32_t count) noexcept {
    return count >= 64 ? ~std::uint64_t{0} : (std::uint64_t{1} << count) - 1;
}

} // namespace game::core
