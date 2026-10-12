// Chase-Lev theo Lê, Pop, Cohen, Zappa Nardelli 2013 ("Correct and Efficient Work-Stealing for Weak
// Memory Models") và vòng MPMC của Vyukov, lấy từ VnS src/core/job_queue.cpp (viết lại theo bài
// báo, đã qua 26 đột biến và bài đo cạnh No1, Platium, Wicked). Máy không có TSan (hiến pháp II.2),
// nên mỗi cạnh thứ tự bộ nhớ được lập luận tại chỗ nó đứng.
//
// Giữ từ VnS: ô hàng căn đúng một dòng cache; chủ hàng giữ bản sao top cũ để push không chạm dòng
// cache mà mọi kẻ trộm giành bằng CAS. Thêm ở Forge2: pop_batch của vòng chung kiểm liền nhiều ô đã
// sẵn rồi nhận cả dải bằng một CAS trên con trỏ đọc (claim_pop), thay vì một CAS mỗi job.
// Nguồn: Forge2 src/jobs/queue.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; cell_at bỏ phép ép
// sang std::size_t mà GCC báo thừa (kèm static_assert nền 64 bit); vòng for có break của
// ready_after thành vòng while mang điều kiện đó (ghi tại chỗ, từng phép đọc atomic giữ nguyên).

#include "jobs/queue.hpp"

#include "jobs/jobs.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <ranges>
#include <span>
#include <vector>

namespace game::jobs::detail {
namespace {

constexpr auto kRelaxed = std::memory_order_relaxed;
constexpr auto kAcquire = std::memory_order_acquire;
constexpr auto kRelease = std::memory_order_release;
constexpr auto kSeqCst = std::memory_order_seq_cst;

constexpr std::size_t kCellSize = 64;
constexpr std::size_t kJobWords = sizeof(Job) / sizeof(std::uint64_t);
constexpr std::uint32_t kMinCapacity = 2;
constexpr std::uint32_t kMaxCapacity = std::uint32_t{1} << 31;

static_assert(kJobWords * sizeof(std::uint64_t) == sizeof(Job), "Job phải là số nguyên từ 64 bit");
static_assert(sizeof(Job) == kCellSize, "một job đúng một dòng cache");

using Words = std::array<std::uint64_t, kJobWords>;

// bit_ceil của uint32_t không biểu diễn được kết quả lớn hơn 2^31: kẹp trước khi gọi.
[[nodiscard]] std::size_t round_capacity(std::uint32_t requested) noexcept {
    const std::uint32_t least = std::max(requested, kMinCapacity);
    return std::bit_ceil(std::min(least, kMaxCapacity));
}

} // namespace

// Ô là tám atomic 64 bit relaxed: kẻ trộm đọc ô trong lúc chủ ghi đè là đọc rách chứ không phải
// data race, và CAS thất bại vứt bản rách đó.
struct alignas(kCellSize) WorkQueue::Cell {
    std::array<std::atomic<std::uint64_t>, kJobWords> words;
};

// Đáy và bản sao đỉnh cũ chung một dòng: chỉ chủ hàng ghi chúng.
struct WorkQueue::Bottom {
    std::atomic<std::int64_t> cursor{0};
    std::int64_t known_top = 0;
};

struct WorkQueue::Ends {
    Padded<std::atomic<std::int64_t>> top;
    Padded<Bottom> bottom;
};

WorkQueue::WorkQueue(std::uint32_t capacity)
    : ends_(std::make_unique<Ends>()), cells_(round_capacity(capacity)), mask_(round_capacity(capacity) - 1U) {}

WorkQueue::~WorkQueue() = default;

// Con trỏ đáy lùi trước khi biết hàng có rỗng không, nên cursor có thể âm. Ép về không dấu để mặt
// nạ quay vòng đúng.
// Khác gốc: gốc ép tiếp kết quả sang std::size_t. Trên nền 64 bit hai kiểu cùng độ rộng (GCC báo
// -Wuseless-cast), nên bỏ phép ép đó và chặn nền 32 bit ngay tại đây.
WorkQueue::Cell& WorkQueue::cell_at(std::int64_t cursor) noexcept {
    static_assert(sizeof(std::size_t) == sizeof(std::uint64_t), "hàng việc cần nền 64 bit");
    const auto index = static_cast<std::uint64_t>(cursor) & mask_;
    return cells_.at(index);
}

void WorkQueue::write(Cell& cell, const Job& job) noexcept {
    static_assert(sizeof(Cell) == kCellSize, "một ô đúng một dòng cache");
    const auto words = std::bit_cast<Words>(job);
    for (auto [target, word] : std::views::zip(cell.words, words)) {
        target.store(word, kRelaxed);
    }
}

Job WorkQueue::read(const Cell& cell) noexcept {
    Words words{};
    for (auto [word, source] : std::views::zip(words, cell.words)) {
        word = source.load(kRelaxed);
    }
    return std::bit_cast<Job>(words);
}

// Còn chỗ khi đáy chưa vượt đỉnh quá mask. Bản sao đỉnh cũ không bao giờ lớn hơn đỉnh thật, nên
// kết quả "còn chỗ" từ nó luôn đúng.
bool WorkQueue::has_room(std::int64_t end) noexcept {
    Bottom& bottom = ends_->bottom.value;
    const auto limit = static_cast<std::int64_t>(mask_);
    if (end - bottom.known_top <= limit) return true;
    // acquire ghép với CAS của kẻ trộm: nó đã đọc xong ô đó trước khi đỉnh nhích, nên ghi đè an
    // toàn.
    bottom.known_top = ends_->top.value.load(kAcquire);
    return end - bottom.known_top <= limit;
}

bool WorkQueue::push(const Job& job) noexcept {
    Bottom& bottom = ends_->bottom.value;
    const std::int64_t end = bottom.cursor.load(kRelaxed);
    if (!has_room(end)) return false;
    write(cell_at(end), job);
    // release: kẻ trộm nào thấy đáy mới bằng phép đọc acquire thì thấy cả tám từ vừa ghi.
    std::atomic_thread_fence(kRelease);
    bottom.cursor.store(end + 1, kRelaxed);
    return true;
}

bool WorkQueue::give_back(std::int64_t end) noexcept {
    ends_->bottom.value.cursor.store(end + 1, kRelaxed);
    return false;
}

// Chỉ còn đúng một phần tử: chủ và kẻ trộm tranh nhau, CAS trên đỉnh quyết định ai được.
bool WorkQueue::settle_last(std::int64_t last) noexcept {
    std::int64_t expected = last;
    const bool won = ends_->top.value.compare_exchange_strong(expected, last + 1, kSeqCst, kRelaxed);
    ends_->bottom.value.cursor.store(last + 1, kRelaxed);
    return won;
}

bool WorkQueue::pop(Job& out) noexcept {
    Bottom& bottom = ends_->bottom.value;
    const std::int64_t end = bottom.cursor.load(kRelaxed) - 1;
    bottom.cursor.store(end, kRelaxed);
    // seq_cst bắt buộc: phép đọc đỉnh bên dưới không được dời lên trước phép ghi đáy bên trên.
    // Thiếu nó thì chủ và kẻ trộm cùng lấy được phần tử cuối. Ghép với hàng rào trong steal.
    std::atomic_thread_fence(kSeqCst);
    const std::int64_t top = ends_->top.value.load(kRelaxed);
    if (top > end) return give_back(end);
    out = read(cell_at(end));
    if (top != end) return true;
    return settle_last(top);
}

Steal WorkQueue::steal(Job& out) noexcept {
    std::int64_t top = ends_->top.value.load(kAcquire);
    std::atomic_thread_fence(kSeqCst);
    const std::int64_t end = ends_->bottom.value.cursor.load(kAcquire);
    if (top >= end) return Steal::kEmpty;
    // Đọc trước khi CAS. Ô này không bị ghi đè trong lúc đó: push từ chối khi đáy đã hơn đỉnh đúng
    // một vòng, nên ô của top chỉ được tái dùng sau khi đỉnh nhích, mà đỉnh chỉ nhích bằng chính
    // CAS dưới đây. CAS hỏng thì bản đọc bị bỏ.
    const Job candidate = read(cell_at(top));
    const bool won = ends_->top.value.compare_exchange_strong(top, top + 1, kSeqCst, kRelaxed);
    if (!won) return Steal::kLost;
    out = candidate;
    return Steal::kWon;
}

bool WorkQueue::looks_empty() const noexcept {
    const std::int64_t top = ends_->top.value.load(kAcquire);
    return ends_->bottom.value.cursor.load(kAcquire) <= top;
}

// Ô của vòng không khoá. turn bằng chỉ số của ô khi nó chờ bên đẩy; bên đẩy ghi job rồi đặt turn
// bằng chỉ số cộng một để báo bên lấy; bên lấy đọc xong thì đặt turn bằng chỉ số cộng cả vòng.
// Nhờ vậy job (không atomic) chỉ được chạm bởi đúng một bên tại mỗi thời điểm, và release trên turn
// ghép với acquire của bên kia.
struct alignas(kCellSize) SharedQueue::Slot {
    std::atomic<std::uint64_t> turn{0};
    // Đệm tường minh: turn một dòng cache, job một dòng, MSVC không phải chèn đệm ngầm (C4324).
    std::array<std::byte, kCellSize - sizeof(std::atomic<std::uint64_t>)> padding{};
    Job job;
};

struct SharedQueue::Ring {
    Padded<std::atomic<std::uint64_t>> push;
    Padded<std::atomic<std::uint64_t>> pop;
};

SharedQueue::SharedQueue(std::uint32_t capacity)
    : ring_(std::make_unique<Ring>()), slots_(round_capacity(capacity)), mask_(slots_.size() - 1U) {
    static_assert(sizeof(Slot) == 2 * kCellSize, "turn một dòng cache, job một dòng");
    for (std::size_t i = 0; i < slots_.size(); ++i) {
        slots_.at(i).turn.store(i, kRelaxed);
    }
}

SharedQueue::~SharedQueue() = default;

// Một lần thử nhận ô ở position. Retry: ô đã có người nhận hoặc tranh CAS thua, position đã được
// cập nhật để thử lại. Blocked: vòng đầy.
SharedQueue::Claim SharedQueue::claim_push(std::uint64_t& position) noexcept {
    std::atomic<std::uint64_t>& cursor = ring_->push.value;
    const std::uint64_t turn = slots_.at(position & mask_).turn.load(kAcquire);
    const auto gap = static_cast<std::int64_t>(turn - position);
    if (gap < 0) return Claim::kBlocked;
    if (gap > 0) {
        position = cursor.load(kRelaxed);
        return Claim::kRetry;
    }
    if (cursor.compare_exchange_weak(position, position + 1, kRelaxed, kRelaxed)) {
        return Claim::kWon;
    }
    return Claim::kRetry;
}

// Số ô liền sau position (không tính nó) đã sẵn cho bên lấy, tối đa limit - 1. acquire trên turn
// ghép với release của bên đẩy, nên job của các ô đó đọc được ngay sau CAS. Ô đã sẵn không thể mất
// trạng thái trước CAS: chỉ bên lấy nhận được nó, mà muốn nhận phải đẩy con trỏ đọc qua nó.
// Vị trí rồi trần số ô, cùng thứ tự với claim_pop là nơi gọi duy nhất (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
std::size_t SharedQueue::ready_after(std::uint64_t position, std::size_t limit) noexcept {
    // Khác gốc: gốc viết for (next = position + 1; count + 1 < limit; ++next, ++count) với thân là
    // if (turn.load(kAcquire) != next + 1) break. Điều kiện dừng đó lên điều kiện lặp: mỗi vòng
    // vẫn kiểm count + 1 < limit trước rồi mới đọc turn của ô next đúng một lần bằng acquire.
    std::size_t count = 0;
    std::uint64_t next = position + 1;
    while (count + 1 < limit && slots_.at(next & mask_).turn.load(kAcquire) == next + 1) {
        ++next;
        ++count;
    }
    return count;
}

// Như claim_push, nhìn từ bên lấy: ô sẵn sàng khi turn bằng chỉ số cộng một. Won thì count ô liền
// từ position thuộc về bên gọi. Blocked: vòng rỗng.
SharedQueue::Claim SharedQueue::claim_pop(std::uint64_t& position, std::size_t limit, std::size_t& count) noexcept {
    std::atomic<std::uint64_t>& cursor = ring_->pop.value;
    const std::uint64_t turn = slots_.at(position & mask_).turn.load(kAcquire);
    const auto gap = static_cast<std::int64_t>(turn - (position + 1U));
    if (gap < 0) return Claim::kBlocked;
    if (gap > 0) {
        position = cursor.load(kRelaxed);
        return Claim::kRetry;
    }
    count = 1 + ready_after(position, limit);
    if (cursor.compare_exchange_weak(position, position + count, kRelaxed, kRelaxed)) {
        return Claim::kWon;
    }
    return Claim::kRetry;
}

bool SharedQueue::ring_push(const Job& job) noexcept {
    std::uint64_t position = ring_->push.value.load(kRelaxed);
    Claim claim = claim_push(position);
    while (claim == Claim::kRetry) {
        claim = claim_push(position);
    }
    if (claim != Claim::kWon) return false;
    Slot& slot = slots_.at(position & mask_);
    slot.job = job;
    slot.turn.store(position + 1U, kRelease);
    return true;
}

std::size_t SharedQueue::ring_pop(std::span<Job> out) noexcept {
    std::uint64_t position = ring_->pop.value.load(kRelaxed);
    std::size_t count = 0;
    Claim claim = claim_pop(position, out.size(), count);
    while (claim == Claim::kRetry) {
        claim = claim_pop(position, out.size(), count);
    }
    if (claim != Claim::kWon) return 0;
    for (Job& target : out.first(count)) {
        Slot& slot = slots_.at(position & mask_);
        target = slot.job;
        slot.turn.store(position + mask_ + 1U, kRelease);
        ++position;
    }
    return count;
}

// Bắt đầu 64 ô rồi gấp đôi; phần tràn hiếm khi cần hơn. Dựng bản mới trước rồi mới đổi, nên hết bộ
// nhớ thì hàng còn nguyên.
void SharedQueue::grow() {
    const std::size_t next = std::max<std::size_t>(spill_.size() * 2U, 64U);
    std::vector<Job> bigger(next);
    const std::size_t mask = spill_.size() - 1U;
    for (std::size_t i = 0; i < count_; ++i) {
        bigger.at(i) = spill_.at((head_ + i) & mask);
    }
    spill_.swap(bigger);
    head_ = 0;
}

void SharedQueue::spill(const Job& job) {
    const std::scoped_lock lock(mutex_);
    if (count_ == spill_.size()) grow();
    spill_.at((head_ + count_) & (spill_.size() - 1U)) = job;
    ++count_;
    spilled_.store(count_, kRelease);
}

std::size_t SharedQueue::unspill(std::span<Job> out) {
    if (spilled_.load(kAcquire) == 0) return 0;
    const std::scoped_lock lock(mutex_);
    const std::size_t taken = std::min(count_, out.size());
    for (Job& target : out.first(taken)) {
        target = spill_.at(head_);
        head_ = (head_ + 1U) & (spill_.size() - 1U);
    }
    count_ -= taken;
    spilled_.store(count_, kRelease);
    return taken;
}

void SharedQueue::push(const Job& job) {
    if (ring_push(job)) return;
    spill(job);
}

bool SharedQueue::pop(Job& out) {
    return pop_batch(std::span(&out, 1)) == 1;
}

std::size_t SharedQueue::pop_batch(std::span<Job> out) {
    if (out.empty()) return 0;
    const std::size_t spilled = unspill(out);
    if (spilled != 0) return spilled;
    return ring_pop(out);
}

bool SharedQueue::looks_empty() const noexcept {
    if (spilled_.load(kAcquire) != 0) return false;
    return ring_->pop.value.load(kAcquire) == ring_->push.value.load(kAcquire);
}

} // namespace game::jobs::detail
