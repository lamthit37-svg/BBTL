// Truy cập phần tử mảng cố định bằng chỉ số lúc chạy. std::array::operator[] với chỉ số không hằng bị
// cppcoreguidelines-pro-bounds-constant-array-index cấm, còn .at() ném ngoại lệ trong hàm noexcept; std::span::operator[]
// không bị cả hai: chỉ số ngoài miền là lỗi lập trình mà hardening của thư viện chuẩn dừng chương trình (chỉ số của module
// này luôn đã kiểm biên hay suy ra từ enum).
#pragma once

#include <array>
#include <cstddef>
#include <span>

namespace game::lua {

template <class T, std::size_t N>
[[nodiscard]] constexpr T& element(std::array<T, N>& items, std::size_t index) noexcept {
    return std::span<T, N>(items)[index];
}

template <class T, std::size_t N>
[[nodiscard]] constexpr const T& element(const std::array<T, N>& items, std::size_t index) noexcept {
    return std::span<const T, N>(items)[index];
}

} // namespace game::lua
