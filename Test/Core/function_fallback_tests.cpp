// Nhánh tự cài của MoveOnlyFunction. <version> có include guard: include trước, tắt macro,
// rồi include header thì lần <version> bên trong không định nghĩa lại macro.
// <functional> không đủ: function.hpp include <version> lần đầu và bật lại macro.
#include <version>

// NOLINTNEXTLINE(misc-include-cleaner): tidy không nhận <version> là header của macro (DD-08)
#undef __cpp_lib_move_only_function
#include "core/function.hpp"

#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <type_traits>
#include <utility>

namespace game::test {
namespace {

static_assert(core::MoveOnlyFunction<void()>::kIsFallback);
static_assert(core::MoveOnlyFunction<void() const>::kIsFallback);
static_assert(!std::is_copy_constructible_v<core::MoveOnlyFunction<void()>>);
static_assert(std::is_move_constructible_v<core::MoveOnlyFunction<void()>>);

void fallback_calls_lambda(Context& context) {
    int value = 0;
    core::MoveOnlyFunction<void(int)> call([&value](int step) { value += step; });
    context.expect(static_cast<bool>(call), "hàm đã dựng thì không rỗng");
    call(3);
    context.expect(value == 3, "lời gọi chạy lambda");
    core::MoveOnlyFunction<void(int)> moved(std::move(call));
    moved(4);
    context.expect(value == 7, "hàm đã chuyển vẫn chạy");
}

void fallback_bool_tracks_empty(Context& context) {
    const core::MoveOnlyFunction<void()> empty;
    context.expect(!empty, "mặc định là rỗng");
    core::MoveOnlyFunction<void()> filled([] {});
    context.expect(static_cast<bool>(filled), "dựng từ lambda thì có hàm");
    filled = nullptr;
    context.expect(!filled, "gán nullptr thành rỗng");
    const core::MoveOnlyFunction<void()> from_null(nullptr);
    context.expect(!from_null, "dựng từ nullptr là rỗng");
}

void fallback_const_calls(Context& context) {
    int value = 0;
    const core::MoveOnlyFunction<int() const> call([&value] { return ++value; });
    context.expect(static_cast<bool>(call), "chữ ký const của nhánh tự cài dựng được");
    context.expect(call() == 1, "lời gọi const chạy lambda");
}

constexpr std::array kCases{
    Case{.name = "fallback_calls_lambda", .body = &fallback_calls_lambda},
    Case{.name = "fallback_bool_tracks_empty", .body = &fallback_bool_tracks_empty},
    Case{.name = "fallback_const_calls", .body = &fallback_const_calls},
};

} // namespace
} // namespace game::test

int main() {
    const std::int32_t failures = game::test::run_all(game::test::kCases);
    game::core::check(failures == 0, "function_fallback_tests: mọi ca phải qua");
    return 0;
}
