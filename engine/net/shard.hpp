#pragma once
// Hàng đợi giữa hai luồng và hàng lane trong một luồng.
// Seastar (smp_message_queue) đẩy con trỏ cấp phát, lô 16, rồi đánh thức bằng eventfd mỗi lô,
// sức chứa 128. Hàng ở đây giữ giá trị ngay trong ô, một store release cho cả lô, chỉ đánh thức
// khi bên nhận đã ngủ, sức chứa do bên gọi chọn và không cấp phát trên đường nóng.
// GameNetworkingSockets xếp lane bằng virtual time số thực rồi quét hết lane. Ở đây ưu tiên chặt
// (số nhỏ chạy trước) rồi deficit round-robin bằng số nguyên, con trỏ lane không quét lane rỗng.

#include "core/check.hpp"

#include <array>
#include <atomic>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <span>
#include <type_traits>
#include <utility>
#include <vector>

namespace game::net {

// alignas(64) cố ý nới struct để head và tail không dùng chung một cache line.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable: 4324)
#endif

inline constexpr std::size_t kLaneCount = 4;

struct LaneSpec {
    // Số nhỏ hơn được phục vụ hết trước số lớn hơn.
    std::uint16_t priority = 0;
    // Trong cùng priority, số phần tử lấy liên tiếp trước khi nhường lane khác.
    std::uint16_t weight = 1;
};

// Một luồng đẩy, một luồng lấy. Capacity là luỹ thừa của hai, tối đa 65536.
// try_push chỉ chuyển item khi còn chỗ; đầy thì để nguyên để bên gọi đẩy lại.
template <typename T, std::size_t Capacity>
class SpscMail {
    static_assert(Capacity >= 2 && Capacity <= 65536 && std::has_single_bit(Capacity), "sức chứa");

public:
    SpscMail() = default;
    SpscMail(const SpscMail&) = delete;
    SpscMail& operator=(const SpscMail&) = delete;
    SpscMail(SpscMail&&) = delete;
    SpscMail& operator=(SpscMail&&) = delete;

    [[nodiscard]] bool try_push(T& item) noexcept(std::is_nothrow_move_assignable_v<T>) {
        const std::uint32_t tail = producer_.tail.load(std::memory_order_relaxed);
        const std::uint32_t next = tail + 1;
        if (next - producer_.cached_head > Capacity) {
            producer_.cached_head = consumer_.head.load(std::memory_order_acquire);
            if (next - producer_.cached_head > Capacity) return false;
        }
        slots_[tail & kMask] = std::move(item);
        producer_.tail.store(next, std::memory_order_release);
        poke();
        return true;
    }

    [[nodiscard]] bool try_pop(T& out) noexcept(std::is_nothrow_move_assignable_v<T>) {
        const std::uint32_t head = consumer_.head.load(std::memory_order_relaxed);
        if (head == consumer_.cached_tail) {
            consumer_.cached_tail = producer_.tail.load(std::memory_order_acquire);
            if (head == consumer_.cached_tail) return false;
        }
        out = std::move(slots_[head & kMask]);
        consumer_.head.store(head + 1, std::memory_order_release);
        return true;
    }

    // Bên nhận. true khi chưa thấy phần tử mới.
    [[nodiscard]] bool empty() noexcept {
        const std::uint32_t head = consumer_.head.load(std::memory_order_relaxed);
        if (head != consumer_.cached_tail) return false;
        consumer_.cached_tail = producer_.tail.load(std::memory_order_acquire);
        return head == consumer_.cached_tail;
    }

    // Bên nhận ngủ tới khi có phần tử hoặc still_idle() thành false. Vẫn đúng nếu phần tử tới
    // trước lúc ngủ: vẫn kiểm lại sau khi gắn cờ ngủ.
    template <typename Pred>
    void park(Pred still_idle) {
        if (!still_idle()) return;
        parked_.store(1, std::memory_order_relaxed);
        std::atomic_thread_fence(std::memory_order_seq_cst);
        if (!still_idle()) {
            parked_.store(0, std::memory_order_relaxed);
            return;
        }
        parked_.wait(1, std::memory_order_relaxed);
        parked_.store(0, std::memory_order_relaxed);
    }

    // Bên đẩy, hoặc luồng tắt máy: đánh thức nếu bên nhận đang ngủ. Không syscall khi không ngủ.
    void wake() noexcept { poke(); }

private:
    static constexpr std::uint32_t kMask = static_cast<std::uint32_t>(Capacity - 1);
    static constexpr std::size_t kLine = 64;

    struct alignas(kLine) Producer {
        std::atomic<std::uint32_t> tail{0};
        std::uint32_t cached_head = 0;
    };
    struct alignas(kLine) Consumer {
        std::atomic<std::uint32_t> head{0};
        std::uint32_t cached_tail = 0;
    };

    // Fence trước lần đọc parked_ đầu tiên: ghi tail (hay cờ dừng của bên gọi) rồi đọc parked_ là
    // cặp ghi-đọc mà x86 cũng được đảo. Thiếu nó, bên nhận có thể gắn cờ ngủ, vẫn thấy hàng rỗng,
    // còn bên đẩy thấy parked_ == 0 nên không đánh thức: phần tử nằm trong hàng tới lần đẩy sau.
    void poke() noexcept {
        std::atomic_thread_fence(std::memory_order_seq_cst);
        if (parked_.load(std::memory_order_relaxed) == 0) return;
        parked_.store(0, std::memory_order_release);
        parked_.notify_one();
    }

    Producer producer_{};
    Consumer consumer_{};
    alignas(kLine) std::atomic<std::uint32_t> parked_{0};
    alignas(kLine) std::array<T, Capacity> slots_{};
};

// Hàng một luồng. reset trước khi push. Không an toàn đa luồng: gate gọi trên luồng tick.
template <typename T>
class LaneQueue {
public:
    LaneQueue() = default;

    void reset(std::span<const LaneSpec> specs) {
        core::check(specs.size() <= kLaneCount, "quá nhiều lane");
        used_ = specs.size();
        total_ = 0;
        cursor_ = 0;
        for (std::size_t index = 0; index < used_; ++index) {
            core::check(specs[index].weight > 0, "trọng số lane bằng 0");
            lanes_[index] = Lane{};
            lanes_[index].spec = specs[index];
        }
    }

    void reserve(std::size_t count) {
        for (std::size_t index = 0; index < used_; ++index) lanes_[index].items.reserve(count);
    }

    void push(std::size_t lane, T item) {
        core::check(lane < used_, "lane không có");
        Lane& slot = lanes_[lane];
        if (slot.from == slot.items.size()) {
            slot.items.clear();
            slot.from = 0;
        }
        slot.items.push_back(std::move(item));
        ++total_;
    }

    [[nodiscard]] std::size_t pop(std::span<T> out) {
        std::size_t filled = 0;
        while (filled < out.size() && total_ > 0) {
            const Pick pick = pick_hot();
            if (!pick.found) break;
            out[filled] = take(pick.index);
            ++filled;
        }
        return filled;
    }

    [[nodiscard]] std::size_t size() const noexcept { return total_; }

private:
    struct Lane {
        LaneSpec spec{};
        std::vector<T> items;
        std::size_t from = 0;
        std::uint32_t deficit = 0;
    };
    struct Pick {
        std::size_t index = 0;
        bool found = false;
    };

    [[nodiscard]] std::size_t live_at(std::size_t index) const noexcept {
        const Lane& lane = lanes_[index];
        return lane.items.size() - lane.from;
    }

    [[nodiscard]] Pick pick_hot() const noexcept {
        Pick pick;
        bool any = false;
        std::uint16_t best = 0;
        for (std::size_t index = 0; index < used_; ++index) {
            if (live_at(index) == 0) continue;
            const std::uint16_t priority = lanes_[index].spec.priority;
            if (any && priority >= best) continue;
            best = priority;
            any = true;
        }
        if (!any) return pick;
        for (std::size_t step = 0; step < used_; ++step) {
            const std::size_t index = (cursor_ + step) % used_;
            if (lanes_[index].spec.priority != best) continue;
            if (live_at(index) == 0) continue;
            pick.index = index;
            pick.found = true;
            return pick;
        }
        return pick;
    }

    [[nodiscard]] T take(std::size_t index) {
        Lane& lane = lanes_[index];
        if (lane.deficit == 0) lane.deficit = lane.spec.weight;
        T item = std::move(lane.items[lane.from]);
        ++lane.from;
        --total_;
        --lane.deficit;
        if (lane.from == lane.items.size()) {
            lane.items.clear();
            lane.from = 0;
            lane.deficit = 0;
        }
        const bool yield = lane.deficit == 0 || live_at(index) == 0;
        cursor_ = yield ? index + 1 : index;
        if (cursor_ >= used_) cursor_ = 0;
        return item;
    }

    std::array<Lane, kLaneCount> lanes_{};
    std::size_t used_ = 0;
    std::size_t total_ = 0;
    std::size_t cursor_ = 0;
};

#if defined(_MSC_VER)
#pragma warning(pop)
#endif

} // namespace game::net
