// Khung test tối giản thuần C++ của dự án (refs/15 KT-01): mỗi tệp test xuất một bảng constexpr các
// Case; main gom bảng và gọi run_all. expect ghi file:dòng rồi chạy tiếp; vi phạm hợp đồng
// (core::check) vẫn dừng ngay. Không biến toàn cục tự đăng ký: không phụ thuộc thứ tự khởi tạo
// tĩnh.
#pragma once

#include <cstdint>
#include <cstdio>
#include <source_location>
#include <span>
#include <string_view>

namespace game::test {

class Context {
public:
    void expect(bool condition, std::string_view what,
        std::source_location where = std::source_location::current()) noexcept {
        if (condition) return;
        ++failures_;
        // fprintf thay std::print (lệch STD-04): như check.hpp, không kéo <format> vào mọi test.
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
        static_cast<void>(std::fprintf(stderr, "%s:%lu: [%.*s] %.*s\n", where.file_name(),
            static_cast<unsigned long>(where.line()), static_cast<int>(current_.size()), current_.data(),
            static_cast<int>(what.size()), what.data()));
    }
    void begin(std::string_view name) noexcept { current_ = name; }
    [[nodiscard]] std::int32_t failures() const noexcept { return failures_; }

private:
    std::string_view current_;
    std::int32_t failures_ = 0;
};

struct Case {
    std::string_view name;
    void (*body)(Context&) = nullptr;
};

// Số kỳ vọng sai trên mọi ca; main trả khác 0 khi kết quả khác 0.
[[nodiscard]] inline std::int32_t run_all(std::span<const Case> cases) noexcept {
    Context context;
    for (const Case& one : cases) {
        context.begin(one.name);
        one.body(context);
    }
    return context.failures();
}

} // namespace game::test
