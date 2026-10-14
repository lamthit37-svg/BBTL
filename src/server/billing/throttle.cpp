#include "billing/throttle.hpp"

#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace game::billing {
namespace {

// 3600 giây x 20 tick/giây.
constexpr std::uint64_t kTicksPerHour = 72000;

// Số lượt hồi được sau `elapsed` tick; kẹp để phép cộng với tokens không tràn.
[[nodiscard]] std::uint64_t refilled(std::uint64_t elapsed, std::uint64_t refill_ticks) noexcept {
    return elapsed / refill_ticks;
}

} // namespace

TokenBuckets::TokenBuckets(BucketRate rate)
    : capacity_(rate.per_hour <= 0 ? 0U
                                   : static_cast<std::uint32_t>(std::min<std::int64_t>(
                                         rate.per_hour, std::numeric_limits<std::uint32_t>::max()))),
      max_keys_(std::max<std::size_t>(rate.max_keys, 1)) {
    if (capacity_ > 0) refill_ticks_ = std::max<std::uint64_t>((kTicksPerHour + capacity_ - 1) / capacity_, 1);
}

bool TokenBuckets::take(std::uint64_t key, ids::Tick now) {
    if (capacity_ == 0) return false;
    const auto found = state_.find(key);
    if (found == state_.end()) {
        if (state_.size() >= max_keys_) sweep_full(now);
        if (state_.size() >= max_keys_) return false;
        state_.emplace(key, State{.tokens = capacity_ - 1, .last = now});
        return true;
    }
    State& state = found->second;
    const ids::Tick base = now < state.last ? state.last : now;
    if (state.tokens < capacity_) {
        const std::uint64_t gained = refilled(base.value() - state.last.value(), refill_ticks_);
        if (gained > 0) {
            const std::uint64_t room = capacity_ - state.tokens;
            if (gained >= room) {
                state.tokens = capacity_;
                state.last = base;
            } else {
                state.tokens += static_cast<std::uint32_t>(gained);
                state.last = ids::Tick{state.last.value() + (gained * refill_ticks_)};
            }
        }
    } else {
        state.last = base;
    }
    if (state.tokens == 0) return false;
    // Từ bộ đầy mà tiêu một lượt thì đồng hồ hồi bắt đầu tại lúc tiêu.
    if (state.tokens == capacity_) state.last = base;
    --state.tokens;
    return true;
}

void TokenBuckets::sweep_full(ids::Tick now) {
    std::erase_if(state_, [&](const auto& entry) {
        const State& state = entry.second;
        if (now < state.last) return false;
        const std::uint64_t gained = refilled(now.value() - state.last.value(), refill_ticks_);
        return gained >= capacity_ - state.tokens;
    });
}

} // namespace game::billing
