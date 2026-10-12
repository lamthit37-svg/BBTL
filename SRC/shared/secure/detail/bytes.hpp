#pragma once
// Đọc và ghi u16 little-endian trên vùng đệm của chính mình. Không đụng byte của client
// trước khi bên gọi đã kiểm đủ hai byte.

#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <span>

namespace game::secure::detail {

[[nodiscard]] inline std::uint16_t read_u16(std::span<const std::byte> bytes) noexcept {
    core::check(bytes.size() >= 2, "thiếu byte để đọc u16");
    const auto low = static_cast<unsigned>(bytes[0]);
    const auto high = static_cast<unsigned>(bytes[1]);
    return static_cast<std::uint16_t>(low | (high << 8U));
}

inline void write_u16(std::span<std::byte> bytes, std::uint16_t value) noexcept {
    core::check(bytes.size() >= 2, "thiếu chỗ để ghi u16");
    bytes[0] = static_cast<std::byte>(value & 0xffU);
    bytes[1] = static_cast<std::byte>(value >> 8U);
}

} // namespace game::secure::detail
