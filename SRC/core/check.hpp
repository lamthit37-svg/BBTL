// Kiểm hợp đồng cho mọi module: check luôn bật, kể cả bản phát hành; debug_check chỉ chạy khi
// định nghĩa GAME_DEBUG_CHECKS; fail dừng vô điều kiện; assume hứa với trình dịch một điều đã
// chứng minh. Điều kiện sai thì in file:dòng rồi std::abort() — fail-fast: trạng thái hỏng không
// được đi tiếp thành UB, gói tin rác hay bản ghi bẩn trong cơ sở dữ liệu.
// - constexpr: vi phạm khi tính hằng biểu thức thành lỗi biên dịch (check_failed không constexpr);
// - noexcept, không cấp phát: gọi được trong hàm noexcept và trên đường nóng;
// - nhánh lỗi nằm trong hàm [[noreturn]] riêng, nơi gọi chỉ còn một phép so và một bước nhảy.
#pragma once

#include <cstdio>
#include <cstdlib>
#include <source_location>
#include <string_view>

namespace game::core {

#if defined(GAME_DEBUG_CHECKS)
inline constexpr bool kDebugChecks = true;
#else
inline constexpr bool kDebugChecks = false;
#endif

namespace detail {

// fprintf thay std::print (lệch STD-04): header này có ở mọi TU, không kéo <format> theo.
[[noreturn]] inline void check_failed(std::string_view message, std::source_location where) noexcept {
    // Chuỗi định dạng giữ ASCII: clang-tidy ≤20 sập khi gặp UTF-8 trong định dạng printf (BD-19).
    // NOLINTNEXTLINE(modernize-use-std-print,cppcoreguidelines-pro-type-vararg)
    static_cast<void>(std::fprintf(stderr, "%s:%lu: ", where.file_name(), static_cast<unsigned long>(where.line())));
    static_cast<void>(std::fputs("check thất bại: ", stderr));
    static_cast<void>(std::fwrite(message.data(), 1, message.size(), stderr));
    static_cast<void>(std::fputc('\n', stderr));
    std::abort();
}

} // namespace detail

// Tiền điều kiện, hậu điều kiện, bất biến rẻ (O(1)): luôn kiểm.
constexpr void check(bool condition, std::string_view message,
    std::source_location where = std::source_location::current()) noexcept {
    if (condition) return;
    detail::check_failed(message, where);
}

// Điều kiện đắt (duyệt mảng, kiểm cấu trúc): predicate chỉ được gọi khi kDebugChecks, nhưng vẫn
// được biên dịch ở mọi cấu hình nên không mục theo thời gian.
template <class Predicate>
constexpr void debug_check(const Predicate& predicate, std::string_view message,
    std::source_location where = std::source_location::current()) noexcept {
    if constexpr (kDebugChecks) check(predicate(), message, where);
}

// Nhánh không được phép tới (enum ngoài miền, trạng thái không tồn tại): dừng ở mọi cấu hình.
[[noreturn]] inline void fail(std::string_view message,
    std::source_location where = std::source_location::current()) noexcept {
    detail::check_failed(message, where);
}

// Hứa với trình dịch rằng condition đúng để nó tối ưu theo; sai là UB ở bản phát hành. Chỉ dùng
// trên đường nóng đã đo, khi condition đã được chứng minh ở nơi khác (refs/11, SV-*).
constexpr void assume(bool condition) noexcept {
    if constexpr (kDebugChecks) check(condition, "assume sai");
    [[assume(condition)]];
}

} // namespace game::core
