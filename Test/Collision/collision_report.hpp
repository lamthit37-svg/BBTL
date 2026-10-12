// Báo cáo chung của các exe test collision (collision_tests, collision_alloc_tests): một dòng
// "<exe>: <chủ đề>: <lời>" ra stderr, đếm ca chờ hay bỏ qua và lỗi dữ liệu, rồi mã thoát: số vàng có chữ đầu dòng lạ
// thì 2 (L 15:17, không im lặng bỏ qua); có kỳ vọng hỏng thì 1 (luật L 14:34, hỏng thắng bỏ qua); không hỏng mà có ca
// chờ Model của C hay bỏ qua vì thiếu dữ liệu thì 77 (CMake đặt SKIP_RETURN_CODE 77 nên CTest báo Skipped); còn lại 0.
#pragma once

#include <cstdint>
#include <cstdio>
#include <string_view>

namespace game::test {

inline constexpr int kSkipReturnCode = 77;
inline constexpr int kDataErrorReturnCode = 2;

// Số ca chờ hay bỏ qua trong exe này; chỉ luồng chính ghi (các ca chạy tuần tự trong run_all).
[[nodiscard]] inline std::int32_t& skipped_cases() noexcept {
    static std::int32_t count = 0;
    return count;
}

// Số lỗi dữ liệu (chữ đầu dòng lạ trong số vàng); chỉ luồng chính ghi.
[[nodiscard]] inline std::int32_t& data_errors() noexcept {
    static std::int32_t count = 0;
    return count;
}

inline void say(std::string_view program, std::string_view subject, std::string_view what) noexcept {
    static_cast<void>(std::fwrite(program.data(), 1, program.size(), stderr));
    static_cast<void>(std::fputs(": ", stderr));
    static_cast<void>(std::fwrite(subject.data(), 1, subject.size(), stderr));
    static_cast<void>(std::fputs(": ", stderr));
    static_cast<void>(std::fwrite(what.data(), 1, what.size(), stderr));
    static_cast<void>(std::fputc('\n', stderr));
}

// Ca chờ hay bỏ qua: in lý do và đếm, để main trả 77 khi không có kỳ vọng nào hỏng.
inline void say_skipped(std::string_view program, std::string_view subject, std::string_view what) noexcept {
    ++skipped_cases();
    say(program, subject, what);
}

// Lỗi dữ liệu: in và đếm, để main trả 2.
inline void say_data_error(std::string_view program, std::string_view subject, std::string_view what) noexcept {
    ++data_errors();
    say(program, subject, what);
}

[[nodiscard]] inline int exit_code(std::int32_t failures) noexcept {
    if (data_errors() != 0) return kDataErrorReturnCode;
    if (failures != 0) return 1;
    return skipped_cases() != 0 ? kSkipReturnCode : 0;
}

} // namespace game::test
