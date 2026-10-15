// Thư viện toán (lmathlib.c của Lua 5.0.1) với bộ tên và kết quả của LuaPlus.dll trong client 2026.
//
// Port từ lmathlib.c. Khác gốc:
// - math.random / math.randomseed dùng rand / srand của MSVCR110 (LCG 214013, 2531011, lấy 15 bit giữa), vì dãy số của
//   client 2026 là dãy đó; hạt nằm trong State thay vì toàn cục của tiến trình. Phép `u - l + 1` và phép cộng cuối của gốc
//   là int tràn thì quấn vòng (đo trên DLL: random(-2147483647, 2147483647) ra -2147483648); ở đây quấn bằng số không dấu
//   để không dính UB.
// - NaN do hàm toán sinh ra từ đối số không phải NaN luôn là NaN âm ("-1.#IND", đo trên DLL cho asin(2), sqrt(-1), log(-1),
//   fmod(1, 0)...), không phụ thuộc thư viện toán của máy dựng; NaN đầu vào đi qua nguyên vẹn (kể cả dấu), trừ abs.
// - frexp của số vô hạn trả (NaN âm, -1), của NaN trả (chính NaN, -1) và của ±0 trả (+0, 0), như MSVCR110 (đo trên DLL).
// - sin, cos, tan, asin, acos, atan, atan2, exp, log, log10, pow lấy từ thư viện toán của máy dựng: chữ số thứ 17 của vài kết
//   quả lệch DLL một ulp (đo: sin(-2.5), cos(1), tan(-2.5)); chuỗi tostring (14 chữ số) không đổi.
#include "lua/lib.hpp"
#include "lua/number.hpp"
#include "lua/state.hpp"
#include "lua/vm.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <numbers>

namespace game::lua {
namespace {

constexpr double kQuietNaN = std::numeric_limits<double>::quiet_NaN();

// Kết quả NaN của một hàm toán: NaN của đầu vào thắng, không thì NaN âm.
[[nodiscard]] double settle(double result, double first) noexcept {
    if (!std::isnan(result)) return result;
    return std::isnan(first) ? first : -kQuietNaN;
}

[[nodiscard]] double settle(double result, double first, double second) noexcept {
    if (!std::isnan(result)) return result;
    if (std::isnan(first)) return first;
    return std::isnan(second) ? second : -kQuietNaN;
}

// Hàm một đối số số thực cho một số thực (abs, sin, cos, ...).
template <auto Operation>
Results unary(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const double x = in.number(0);
    if (in.failed()) return {};
    return {Value::number(settle(Operation(x), x))};
}

// Hàm hai đối số số thực cho một số thực (atan2, mod, pow).
template <auto Operation>
Results binary(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const double x = in.number(0);
    const double y = in.number(1);
    if (in.failed()) return {};
    return {Value::number(settle(Operation(x, y), x, y))};
}

// fabs xoá cả dấu của NaN (đo: abs(-nan) ra NaN dương), nên không đi qua settle.
Results math_abs(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const double x = in.number(0);
    if (in.failed()) return {};
    return {Value::number(std::fabs(x))};
}

Results math_frexp(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const double x = in.number(0);
    if (in.failed()) return {};
    if (x == 0.0) return {Value::number(0.0), Value::number(0.0)}; // MSVCR110 trả +0 kể cả cho -0 (đo trên DLL).
    if (!std::isfinite(x)) return {Value::number(std::isnan(x) ? x : -kQuietNaN), Value::number(-1.0)};
    int exponent = 0;
    const double mantissa = std::frexp(x, &exponent);
    return {Value::number(mantissa), Value::number(static_cast<double>(exponent))};
}

Results math_ldexp(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const double x = in.number(0);
    const std::int32_t exponent = in.integer(1);
    if (in.failed()) return {};
    return {Value::number(settle(std::ldexp(x, exponent), x))};
}

Results math_min(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    double best = in.number(0);
    for (std::size_t i = 1; i < args.size() && !in.failed(); ++i) {
        const double candidate = in.number(i);
        if (candidate < best) best = candidate;
    }
    if (in.failed()) return {};
    return {Value::number(best)};
}

Results math_max(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    double best = in.number(0);
    for (std::size_t i = 1; i < args.size() && !in.failed(); ++i) {
        const double candidate = in.number(i);
        if (candidate > best) best = candidate;
    }
    if (in.failed()) return {};
    return {Value::number(best)};
}

// rand() của MSVCR110: hạt nhân 214013 cộng 2531011, lấy bit 16..30.
constexpr std::uint32_t kRandMultiplier = 214013U;
constexpr std::uint32_t kRandIncrement = 2531011U;
constexpr std::uint32_t kRandMask = 0x7FFFU;
constexpr std::uint32_t kRandMax = 32767U;

[[nodiscard]] std::uint32_t next_rand(State& state) noexcept {
    std::uint32_t& seed = state.random_seed();
    seed = seed * kRandMultiplier + kRandIncrement;
    return (seed >> 16U) & kRandMask;
}

// u - l + 1 của int C, quấn vòng khi tràn (xem đầu tệp).
[[nodiscard]] std::int32_t wrapping_span(std::int32_t low, std::int32_t high) noexcept {
    return wrapping_add(static_cast<std::int32_t>(static_cast<std::uint32_t>(high) - static_cast<std::uint32_t>(low)), 1);
}

Results math_random(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    // Lấy số ngẫu nhiên TRƯỚC khi kiểm đối số, như gốc: lời gọi lỗi vẫn làm dãy tiến lên một bước.
    const double r = static_cast<double>(next_rand(state) % kRandMax) / static_cast<double>(kRandMax);
    switch (args.size()) {
    case 0: return {Value::number(r)};
    case 1: {
        const std::int32_t upper = in.integer(0);
        if (in.failed()) return {};
        if (upper < 1) {
            in.argument_error(0, "interval is empty");
            return {};
        }
        return {Value::number(static_cast<double>(wrapping_add(truncate_to_int32(std::floor(r * upper)), 1)))};
    }
    case 2: {
        const std::int32_t lower = in.integer(0);
        const std::int32_t upper = in.integer(1);
        if (in.failed()) return {};
        if (lower > upper) {
            in.argument_error(1, "interval is empty");
            return {};
        }
        const double picked = std::floor(r * wrapping_span(lower, upper));
        return {Value::number(static_cast<double>(wrapping_add(truncate_to_int32(picked), lower)))};
    }
    default: state.native_error("wrong number of arguments"); return {};
    }
}

Results math_randomseed(State& state, const Function& self, Args args) {
    Arguments in(state, self, args);
    const std::int32_t seed = in.integer(0);
    if (in.failed()) return {};
    state.random_seed() = static_cast<std::uint32_t>(seed);
    return {};
}

// RADIANS_PER_DEGREE của lmathlib.c: deg chia cho nó (không nhân với 180/pi: hai cách lệch nhau một ulp, DLL chia).
constexpr double kRadiansPerDegree = std::numbers::pi / 180.0;

// Thứ tự của mảng này là thứ tự luaL_openlib chèn vào bảng, nên quyết định thứ tự pairs(math).
constexpr std::array<Proto, 24> kMathFunctions = {{
    {.body = &math_abs, .name = "abs"},
    {.body = &unary<[](double x) noexcept { return std::sin(x); }>, .name = "sin"},
    {.body = &unary<[](double x) noexcept { return std::cos(x); }>, .name = "cos"},
    {.body = &unary<[](double x) noexcept { return std::tan(x); }>, .name = "tan"},
    {.body = &unary<[](double x) noexcept { return std::asin(x); }>, .name = "asin"},
    {.body = &unary<[](double x) noexcept { return std::acos(x); }>, .name = "acos"},
    {.body = &unary<[](double x) noexcept { return std::atan(x); }>, .name = "atan"},
    {.body = &binary<[](double y, double x) noexcept { return std::atan2(y, x); }>, .name = "atan2"},
    {.body = &unary<[](double x) noexcept { return std::ceil(x); }>, .name = "ceil"},
    {.body = &unary<[](double x) noexcept { return std::floor(x); }>, .name = "floor"},
    {.body = &binary<[](double x, double y) noexcept { return std::fmod(x, y); }>, .name = "mod"},
    {.body = &math_frexp, .name = "frexp"},
    {.body = &math_ldexp, .name = "ldexp"},
    {.body = &unary<[](double x) noexcept { return std::sqrt(x); }>, .name = "sqrt"},
    {.body = &math_min, .name = "min"},
    {.body = &math_max, .name = "max"},
    {.body = &unary<[](double x) noexcept { return std::log(x); }>, .name = "log"},
    {.body = &unary<[](double x) noexcept { return std::log10(x); }>, .name = "log10"},
    {.body = &unary<[](double x) noexcept { return std::exp(x); }>, .name = "exp"},
    {.body = &unary<[](double x) noexcept { return x / kRadiansPerDegree; }>, .name = "deg"},
    {.body = &binary<[](double x, double y) noexcept { return std::pow(x, y); }>, .name = "pow"},
    {.body = &unary<[](double x) noexcept { return x * kRadiansPerDegree; }>, .name = "rad"},
    {.body = &math_random, .name = "random"},
    {.body = &math_randomseed, .name = "randomseed"},
}};

// Bản của `math.pow` đăng ký thành `__pow` toàn cục: một đối tượng hàm riêng (đo: `__pow == math.pow` là false).
constexpr Proto kGlobalPow = {
    .body = &binary<[](double x, double y) noexcept { return std::pow(x, y); }>, .name = "__pow"};

} // namespace

void open_math(State& state) {
    Table* const library = open_library(state, "math", kMathFunctions);
    if (library == nullptr || state.failed()) return;
    const Value pi_name = state.make_string("pi");
    if (state.failed()) return;
    const Table::Slot slot = library->set_slot(pi_name);
    if (slot.fault != Table::Fault::kNone || slot.value == nullptr) {
        state.runtime_error("open_math: khoá pi bị từ chối");
        return;
    }
    *slot.value = Value::number(std::numbers::pi);
    state.set_global("__pow", state.make_native(kGlobalPow));
}

} // namespace game::lua
