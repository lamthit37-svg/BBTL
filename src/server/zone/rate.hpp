/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/rate.hpp
 *  PHÂN HỆ   : Server / Zone / Rate
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nhịp mô phỏng cố định chọn lúc zone khởi động: chỉ 20, 30 hoặc 40. Mặc
 *    định 20 cho tới khi đo chứng minh nhịp cao hơn chịu được tải.
 *  - Hạn tick n là origin + floor(n * 1e9 / hz): đúng từng giây, lệch dưới 1
 *    ns. Bù tối đa 2 tick mỗi lần thức; trễ từ một giây thì đánh dấu quá tải,
 *    không bỏ tick và không từ chối người vào (tránh kẹt giữa hai cảnh).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "ids/ids.hpp"

#include <cstdint>
#include <limits>

namespace game::zone {

// Trần số tick chạy bù trong một lần thức. Phần nợ còn lại để lần sau, không nuốt.
inline constexpr int kCatchUpPerWake = 2;

// 25 Hz và 33 Hz không chia hết 10 Hz vị trí gần, nên không nhận.
[[nodiscard]] constexpr bool accepted_hz(std::int64_t hz) noexcept {
    return hz == 20 || hz == 30 || hz == 40;
}

// Chu kỳ theo thời gian mô phỏng, không phải "mỗi N tick" cố định của bản 20 Hz.
// Gần 10 Hz, xa 5 Hz, quái 10 bước mỗi giây, đứng yên sau 150 ms, xác 3 giây, ghi 60 giây.
struct Rate {
    std::int64_t hz = 20;
    std::uint32_t near_stride = 2;
    std::uint32_t far_stride = 4;
    std::uint32_t move_every = 2;
    std::uint32_t idle_after = 3;
    std::uint32_t corpse_ticks = 60;
    std::uint32_t autosave_ticks = 1200;
};

[[nodiscard]] constexpr Rate rate_of(std::int64_t hz) noexcept {
    const auto step = static_cast<std::uint32_t>(hz);
    const std::int64_t idle = ids::to_ticks(150, hz).count;
    Rate rate;
    rate.hz = hz;
    rate.near_stride = step / 10U;
    rate.far_stride = step / 5U;
    rate.move_every = step / 10U;
    rate.idle_after = static_cast<std::uint32_t>(idle);
    rate.corpse_ticks = step * 3U;
    rate.autosave_ticks = step * 60U;
    return rate;
}

// Hạn của tick `index`, nano giây kể từ gốc. Chia phần nguyên và phần dư để
// n * 1e9 không tràn uint64 trong khoảng vài trăm năm ở 40 Hz.
[[nodiscard]] constexpr std::int64_t tick_due_ns(std::uint64_t index, std::int64_t hz) noexcept {
    if (hz <= 0) return 0;
    const auto step = static_cast<std::uint64_t>(hz);
    const std::uint64_t whole = index / step;
    const std::uint64_t part = index % step;
    const std::uint64_t nanos = (whole * 1'000'000'000ULL) + ((part * 1'000'000'000ULL) / step);
    constexpr auto kMax = static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max());
    if (nanos > kMax) return std::numeric_limits<std::int64_t>::max();
    return static_cast<std::int64_t>(nanos);
}

// Số tick đã tới hạn tại now_ns (tick 0 tới hạn ở mốc 0). Đoán floor thấp hơn đúng tối đa một tick
// vì hai hạn cách nhau ít nhất 25 ms.
[[nodiscard]] constexpr std::uint64_t due_count(std::int64_t now_ns, std::int64_t hz) noexcept {
    if (now_ns < 0 || hz <= 0) return 0;
    const auto ns = static_cast<std::uint64_t>(now_ns);
    const auto step = static_cast<std::uint64_t>(hz);
    const std::uint64_t whole = ns / 1'000'000'000ULL;
    const std::uint64_t frac = ns % 1'000'000'000ULL;
    std::uint64_t n = (whole * step) + ((frac * step) / 1'000'000'000ULL);
    if (tick_due_ns(n + 1ULL, hz) <= now_ns) ++n;
    return n + 1ULL;
}

struct Pace {
    std::int64_t hz = 20;
    std::uint64_t done = 0;
    std::uint64_t debt = 0;
    std::uint64_t late_wakes = 0;
    bool overloaded = false;
};

struct Wake {
    int run = 0;
    bool entered_overload = false;
};

// Chạy tối đa kCatchUpPerWake tick. Quá tải khi nợ từ một giây; chỉ hết cờ khi nợ về 0.
[[nodiscard]] constexpr Wake take_wake(Pace& pace, std::int64_t now_ns) noexcept {
    const std::uint64_t due = due_count(now_ns, pace.hz);
    const std::uint64_t behind = due > pace.done ? due - pace.done : 0ULL;
    pace.debt = behind;
    if (behind > 1ULL) ++pace.late_wakes;
    const bool was = pace.overloaded;
    const auto second = static_cast<std::uint64_t>(pace.hz);
    if (behind >= second) pace.overloaded = true;
    constexpr auto kCap = static_cast<std::uint64_t>(kCatchUpPerWake);
    const std::uint64_t room = behind < kCap ? behind : kCap;
    pace.done += room;
    pace.debt = behind - room;
    if (pace.debt == 0ULL) pace.overloaded = false;
    Wake wake;
    wake.run = static_cast<int>(room);
    wake.entered_overload = pace.overloaded && !was;
    return wake;
}

static_assert(rate_of(20).near_stride == 2);
static_assert(rate_of(20).far_stride == 4);
static_assert(rate_of(20).move_every == 2);
static_assert(rate_of(20).idle_after == 3);
static_assert(rate_of(20).corpse_ticks == 60);
static_assert(rate_of(20).autosave_ticks == 1200);
static_assert(rate_of(30).near_stride == 3 && rate_of(30).far_stride == 6);
static_assert(rate_of(30).idle_after == 5);
static_assert(rate_of(40).near_stride == 4 && rate_of(40).far_stride == 8);
static_assert(rate_of(40).idle_after == 6);
static_assert(tick_due_ns(20, 20) == 1'000'000'000);
static_assert(tick_due_ns(30, 30) == 1'000'000'000);
static_assert(tick_due_ns(40, 40) == 1'000'000'000);
static_assert(due_count(0, 20) == 1);
static_assert(due_count(-1, 20) == 0);
constexpr std::int64_t kDueFiveAt30 = tick_due_ns(5, 30);
static_assert(due_count(kDueFiveAt30, 30) == 6);
static_assert(due_count(kDueFiveAt30 - 1, 30) == 5);

} // namespace game::zone
