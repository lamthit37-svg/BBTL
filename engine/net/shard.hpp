/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/net/shard.hpp
 *  PHÂN HỆ   : Net / Shard
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Chuyển việc giữa các luồng máy chủ không khoá, không cấp phát trên đường
 *    nóng: giá trị nằm ngay trong ô, một store release cho cả lô, chỉ đánh thức
 *    khi bên nhận đã ngủ (Seastar đẩy con trỏ cấp phát, lô 16, eventfd mỗi lô).
 *  - Xếp lượt lane trong một luồng: ưu tiên chặt (số nhỏ trước) rồi deficit
 *    round-robin số nguyên, không quét lane rỗng (GNS dùng virtual time số
 *    thực, quét hết lane).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

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

// Head, tail và cờ ngủ mỗi cái một cache line. Đệm ghi tường minh để alignas không nới thêm.
inline constexpr std::size_t kCacheLine = 64;
inline constexpr std::size_t kLaneCount = 4;

// Ô của SpscMail. Đệm cuối chỉ khi mảng chưa kín một cache line: mảng rỗng cấm (C4200).
template <typename T, std::size_t Capacity, bool NeedPad>
struct SpscSlots;

template <typename T, std::size_t Capacity>
struct alignas(kCacheLine) SpscSlots<T, Capacity, false> {
    [[nodiscard]] T& operator[](std::uint32_t index) noexcept { return items_[index]; }

    std::array<T, Capacity> items_{};
};

template <typename T, std::size_t Capacity>
struct alignas(kCacheLine) SpscSlots<T, Capacity, true> {
    static constexpr std::size_t kPad = kCacheLine - (sizeof(std::array<T, Capacity>) % kCacheLine);
    [[nodiscard]] T& operator[](std::uint32_t index) noexcept { return items_[index]; }

    std::array<T, Capacity> items_{};
    unsigned char pad_[kPad]{};
};

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
        parked_.flag.store(1, std::memory_order_relaxed);
        std::atomic_thread_fence(std::memory_order_seq_cst);
        if (!still_idle()) {
            parked_.flag.store(0, std::memory_order_relaxed);
            return;
        }
        parked_.flag.wait(1, std::memory_order_relaxed);
        parked_.flag.store(0, std::memory_order_relaxed);
    }

    // Bên đẩy, hoặc luồng tắt máy: đánh thức nếu bên nhận đang ngủ. Không syscall khi không ngủ.
    void wake() noexcept { poke(); }

private:
    // Fence trước lần đọc parked_ đầu tiên: ghi tail (hay cờ dừng của bên gọi) rồi đọc parked_ là
    // cặp ghi-đọc mà x86 cũng được đảo. Thiếu nó, bên nhận có thể gắn cờ ngủ, vẫn thấy hàng rỗng,
    // còn bên đẩy thấy parked_ == 0 nên không đánh thức: phần tử nằm trong hàng tới lần đẩy sau.
    void poke() noexcept {
        std::atomic_thread_fence(std::memory_order_seq_cst);
        if (parked_.flag.load(std::memory_order_relaxed) == 0) return;
        parked_.flag.store(0, std::memory_order_release);
        parked_.flag.notify_one();
    }

    static constexpr std::uint32_t kMask = static_cast<std::uint32_t>(Capacity - 1);
    static constexpr std::size_t kLine = kCacheLine;

    using Counter = std::atomic<std::uint32_t>;

    struct alignas(kLine) Producer {
        Counter tail{0};
        std::uint32_t cached_head = 0;
        static constexpr std::size_t kPad = kLine - sizeof(Counter) - sizeof(std::uint32_t);
        unsigned char pad_[kPad]{};
    };
    struct alignas(kLine) Consumer {
        Counter head{0};
        std::uint32_t cached_tail = 0;
        static constexpr std::size_t kPad = kLine - sizeof(Counter) - sizeof(std::uint32_t);
        unsigned char pad_[kPad]{};
    };
    struct alignas(kLine) Parked {
        std::atomic<std::uint32_t> flag{0};
        static constexpr std::size_t kPad = kLine - sizeof(std::atomic<std::uint32_t>);
        unsigned char pad_[kPad]{};
    };

    static constexpr bool kPadSlots = sizeof(std::array<T, Capacity>) % kLine != 0;
    using Slots = SpscSlots<T, Capacity, kPadSlots>;

    static_assert(sizeof(Producer) == kLine && alignof(Producer) == kLine);
    static_assert(sizeof(Consumer) == kLine && alignof(Consumer) == kLine);
    static_assert(sizeof(Parked) == kLine && alignof(Parked) == kLine);
    static_assert(sizeof(Slots) % kLine == 0);
    static_assert(alignof(Slots) >= kLine);

    Producer producer_{};
    Consumer consumer_{};
    Parked parked_{};
    Slots slots_{};
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
        for (std::size_t index = 0; index < used_; ++index)
            lanes_[index].items.reserve(count);
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
    struct Hot {
        std::size_t index = 0;
        std::size_t step = 0;
        std::uint16_t priority = 0;
        bool found = false;
    };

    [[nodiscard]] std::size_t live_at(std::size_t index) const noexcept {
        const Lane& lane = lanes_[index];
        return lane.items.size() - lane.from;
    }

    void consider(std::size_t step, Hot& hot) const noexcept {
        std::size_t index = cursor_ + step;
        if (index >= used_) index -= used_;
        if (live_at(index) == 0) return;
        const std::uint16_t priority = lanes_[index].spec.priority;
        if (hot.found && priority > hot.priority) return;
        if (hot.found && priority == hot.priority && step >= hot.step) return;
        hot.index = index;
        hot.step = step;
        hot.priority = priority;
        hot.found = true;
    }

    [[nodiscard]] Pick pick_hot() const noexcept {
        Hot hot;
        for (std::size_t step = 0; step < used_; ++step)
            consider(step, hot);
        Pick pick;
        pick.index = hot.index;
        pick.found = hot.found;
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

} // namespace game::net
