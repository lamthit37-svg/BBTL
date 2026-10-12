// Điều phối việc: ai lấy job nào, khi nào ngủ, khi nào thức, khi nào xong. Hàng ở queue.cpp.
//
// Lấy từ VnS (src/core/jobs.cpp): đánh thức là hàng rào Dekker — bên đẩy ghi job, hàng rào seq_cst,
// đọc số người ngủ; bên ngủ tăng số đó, hàng rào seq_cst, nhìn lại hàng; ít nhất một bên thấy bên
// kia. Job cuối không chạm bộ đếm sau lần trừ về 0. Thợ ấm chờ 2 ms. Thêm ở Forge2:
// - Chờ bộ đếm không đi qua epoch chung: lần trừ về 0 chỉ đánh thức bên chờ đúng bộ đếm đó. Thợ
//   chờ lồng nhau ngủ trên ô cờ của nó, và bên đẩy việc gọi nó dậy để giúp như gọi thợ ngủ sâu.
// - Thợ cộng dồn lượt hoàn tất của các job liên tiếp cùng bộ đếm, xả một lần khi đổi bộ đếm, khi
//   hết việc, khi vào wait. Xả trước mọi job khác bộ đếm, nên không job nào phải chờ một lượt trừ
//   còn giữ ở luồng đang chạy nó.
// - wait_idle quét hàng, rồi cờ busy của thợ và số luồng đang giúp, rồi quét hàng lần nữa, cách
//   nhau bằng hàng rào seq_cst. Thợ chỉ bật tắt cờ khi vào ra trạng thái rỗi, không phải mỗi job.
// - Dừng drain, abandon, detach. State sống bằng shared_ptr để thợ tách rời giữ được nó; hàm huỷ
//   của State bỏ mọi job còn sót với lỗi Cancelled.
// Nguồn: Forge2 src/jobs/jobs.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; check là bản của
// THIENLONG; std::lock_guard thành std::scoped_lock (một mutex, cùng nghĩa); tham số constructor
// trùng tên thành viên đổi tên (own_flags, thread_count); bỏ {} thừa của warm và error; tham số
// State&, Worker& của các hàm chỉ chạm atomic qua con trỏ thành const (notify_idle, wake_everyone,
// sleep_until_work, wait_warm, idle, mark_busy, rest, park_worker, rest_on, await_idle), biến cục
// bộ jobs của grab thêm const; lệnh return kèm lời gọi hàm void tách làm hai; hai hàm nhận tham số
// dễ đảo mang NOLINT kèm lý do; vòng lặp có nhánh trong thân đổi hình dạng, ghi tại
// chỗ, từng phép đọc, ghi atomic, memory order và thứ tự của chúng giữ nguyên: CounterAccess::add,
// steal_from (thêm steal_once), steal_any (thêm steal_unless_self), wake, spin_for_work (thêm
// work_or_yield), spin_on (thêm done_or_relax), nth_cpu, JobSystem::wait không hạn (thêm
// help_or_rest) và có hạn (thêm wait_step, Timed), wait_idle không hạn (thêm help_or_await) và có
// hạn (thêm await_idle_before).

#include "jobs/jobs.hpp"

#include "core/check.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "core/log.hpp"
#include "core/thread.hpp"
#include "jobs/queue.hpp"

#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__x86_64__)
#include <immintrin.h>
#endif

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <format>
#include <functional>
#include <limits>
#include <memory>
#include <mutex>
#include <optional>
#include <semaphore>
#include <span>
#include <stop_token>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace game::jobs {
namespace {

using detail::CounterAccess;
using detail::Job;
using detail::Steal;
using State = JobSystem::State;

constexpr auto kRelaxed = std::memory_order_relaxed;
constexpr auto kAcquire = std::memory_order_acquire;
constexpr auto kRelease = std::memory_order_release;
constexpr auto kAcqRel = std::memory_order_acq_rel;
constexpr auto kSeqCst = std::memory_order_seq_cst;

// Đủ cho CpuSet của core; nhiều hơn là cấu hình nhầm.
constexpr std::uint32_t kMaxThreads = 1024;
// Mỗi bản sao vượt con trỏ giành tối đa một khúc (grain ≤ count) ở lần giành hỏng cuối, có tối đa
// kMaxThreads + 1 bản sao: count dưới ngưỡng này thì next không tràn size_t.
constexpr std::size_t kMaxBatch = std::numeric_limits<std::size_t>::max() / (kMaxThreads + 2U);
// Số vòng thợ thử tìm việc trước khi ngủ. Việc hay tới thành loạt, ngủ rồi thức tốn cỡ chục micro
// giây; quay ngắn rẻ hơn.
constexpr int kSpinRounds = 32;
// Thua CAS nghĩa là hàng còn việc: thử lại cùng hàng bấy nhiêu lần trước khi sang hàng khác.
constexpr int kStealRetries = 4;
constexpr std::chrono::milliseconds kWarmInterval{2};
// Số job tối đa thợ giành từ hàng chung bằng một CAS; phần dư vào hàng của nó cho thợ khác trộm.
constexpr std::size_t kGrab = 8;
// Khúc dẫn dắt: phần còn lại chia cho kGuidedPieces × số bản sao, không nhỏ hơn count chia
// kGuidedFloor × số bản sao.
constexpr std::size_t kGuidedPieces = 4;
constexpr std::size_t kGuidedFloor = 16;
// Số lần pause bên chờ quay trên bộ đếm trước khi ngủ, cỡ vài micro giây: đủ cho nhóm vừa xong
// mà không phải trả một lần ngủ và một lần đánh thức của hệ điều hành.
constexpr int kWaitSpins = 256;
constexpr std::chrono::nanoseconds kForever = std::chrono::nanoseconds::max();

// sleepers: thợ ngủ sâu trên epoch. parked: thợ ngủ giữa một lần chờ lồng nhau, trên ô cờ của nó.
struct SleepGate {
    std::atomic<std::uint32_t> epoch{0};
    std::atomic<std::uint32_t> sleepers{0};
    std::atomic<std::uint32_t> warm_waiting{0};
    std::atomic<std::uint32_t> parked{0};
};

// Cổng chờ của wait_idle. Chờ bộ đếm thì không qua cổng chung (complete, park_worker).
struct WaitGate {
    std::atomic<std::uint32_t> epoch{0};
    std::atomic<std::uint32_t> waiters{0};
};

// Mỗi cổng một vùng cache riêng: bên đẩy đọc sleepers mỗi lần đẩy, còn bên ngủ và bên chờ ghi cổng
// của mình. Nằm trên heap: đặt Padded thẳng vào State thì MSVC chèn đệm ngầm và báo C4324.
struct Gates {
    detail::Padded<SleepGate> sleep;
    detail::Padded<WaitGate> idle;
    // Số luồng ngoài đang chạy giúp (wait, assist, chế độ không thợ); wait_idle đọc.
    detail::Padded<std::atomic<std::uint32_t>> helpers;
};

// Bên đẩy giành cờ waiting rồi mới release: release khi semaphore đang đầy là UB.
struct WarmSlot {
    std::atomic<bool> waiting{false};
    std::binary_semaphore signal{0};
};

// Cờ của một thợ, riêng hai dòng cache vì thợ ghi nó còn luồng khác chỉ thỉnh thoảng chạm.
// busy: false khi thợ đang quay tìm việc, đang ngủ, hoặc đã thoát; bật lại trước lần lấy việc kế;
// wait_idle đọc. parked: khoá của bộ đếm thợ đang ngủ chờ giữa một lần wait lồng nhau, null khi
// không ngủ. Lần trừ về 0 của bộ đếm đó, hoặc bên đẩy việc mới, đổi nó về null rồi đánh thức thợ
// trên chính ô này — ô sống cùng hệ thống, bộ đếm thì không; giá trị đổi nên không mất tín hiệu.
struct Flags {
    std::atomic<bool> busy{false};
    std::atomic<const void*> parked{nullptr};
};

using WorkerFlags = detail::Padded<Flags>;

struct Worker {
    // Khác gốc: tham số thứ hai của gốc tên flags, trùng tên thành viên (-Wshadow).
    Worker(std::uint32_t capacity, Flags& own_flags) : queue(capacity), flags(&own_flags) {}

    detail::WorkQueue queue;
    Flags* flags;
    // Chỗ grab đổ job giành được từ hàng chung; chỉ chính thợ chạm. Dựng một lần thay vì một mảng
    // 512 B khởi tạo lại ở mỗi lần thợ tìm việc.
    std::array<Job, kGrab> grabbed{};
    // Có khi thợ là thợ ấm.
    std::unique_ptr<WarmSlot> warm;
};

// Luồng thợ biết hệ thống, ô của nó và lượt hoàn tất đang cộng dồn. constinit: không có bảo vệ
// khởi tạo lười trên đường nóng. seed 0 là chưa gieo (xorshift không rời được 0).
struct Member {
    State* state = nullptr;
    Worker* worker = nullptr;
    std::uint32_t index = 0;
    std::uint32_t seed = 0;
    JobCounter* held = nullptr;
    std::uint32_t done = 0;
};

// NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables): trạng thái của chính luồng.
constinit thread_local Member t_member;

// Hệ thống mà luồng ngoài đang chạy giúp (wait, assist, settle của stop, chế độ không thợ); null
// khi không giúp. Job chạy trên luồng đó mà gọi wait_idle hay stop là tự chờ mình, y như trên thợ.
// NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables): trạng thái của chính luồng.
constinit thread_local JobSystem::State* t_helping = nullptr;

} // namespace

struct JobSystem::State {
    // Khác gốc: tham số thứ hai của gốc tên threads, trùng tên thành viên (-Wshadow).
    State(const JobConfig& config, std::uint32_t thread_count);
    State(const State&) = delete;
    State(State&&) = delete;
    State& operator=(const State&) = delete;
    State& operator=(State&&) = delete;
    // Không còn luồng nào chạm hệ thống: bỏ job còn sót, báo ngoại lệ tách rời chưa ai nhận.
    ~State();

    std::string name;
    std::uint32_t threads;
    // Dựng một lần với đúng threads phần tử, không bao giờ đổi cỡ: Worker trỏ vào phần tử của nó.
    std::vector<WorkerFlags> flags;
    std::vector<std::unique_ptr<Worker>> workers;
    detail::SharedQueue shared;
    std::unique_ptr<Gates> gates = std::make_unique<Gates>();
    // closing: stop đã bắt đầu. halted: thợ thoát khi hết việc. abandoning: thợ thoát sau job đang
    // chạy, job còn lại bị bỏ. stopped: stop đã xong, nộp nữa là lỗi lập trình.
    std::atomic<bool> closing{false};
    std::atomic<bool> halted{false};
    std::atomic<bool> abandoning{false};
    std::atomic<bool> stopped{false};
    std::atomic<std::uint32_t> started{0};
    std::atomic<std::uint32_t> alive{0};
    // error_mutex bảo vệ error: ngoại lệ đầu tiên của job tách rời, chờ wait_idle ném.
    std::mutex error_mutex;
    std::exception_ptr error;
    std::vector<std::jthread> handles;
};

JobCounter::~JobCounter() {
    core::check(done(), "huỷ JobCounter khi còn job");
}

namespace detail {

// Đường thường chỉ là một lần đọc: bộ đếm đã mang đúng hệ thống. Bộ đếm đã xong với hệ thống khác
// mà chưa ai chờ thì đổi chủ được; còn dở thì là lỗi lập trình.
void CounterAccess::add(JobCounter& counter, std::uint32_t count, const void* owner) noexcept {
    // Cả lần nhận chủ lẫn lần cộng từ 0 nằm trong cùng một khoá. Khoá thả ra trước khi cộng thì
    // rethrow thấy bộ đếm vẫn rỗng, xoá chủ, rồi lần cộng để job đang chạy mà không có chủ.
    const std::scoped_lock lock(counter.owner_mutex_);
    const void* const current = counter.owner_.load(kRelaxed);
    if (current != owner) adopt(counter, current, owner);
    // Không fetch_add rồi mới check: vượt trần thì bit kInside bật và phần đếm về 0, done() nói
    // dối, wait huỷ bộ đếm trong khi job còn chạy, rồi check mới abort.
    // Khác gốc: gốc viết while (true) với thân kết thúc bằng if (compare_exchange_weak(...))
    // return. Kết quả CAS lên điều kiện lặp: vẫn một lần load trước vòng, mỗi vòng một CAS weak
    // relaxed, CAS hỏng thì seen nhận giá trị mới và vòng tính lại từ đó.
    std::uint32_t seen = counter.state_.load(kRelaxed);
    bool added = false;
    while (!added) {
        const std::uint32_t pending = seen & JobCounter::kCount;
        const std::uint64_t total = std::uint64_t{pending} + count;
        core::check(total <= JobCounter::kCount, "JobCounter vượt 2^30 - 1 job");
        const auto next_count = static_cast<std::uint32_t>(total);
        const std::uint32_t next = (seen & ~JobCounter::kCount) | next_count;
        added = counter.state_.compare_exchange_weak(seen, next, kRelaxed);
    }
}

// Chủ đang ghi rồi chủ mới, như thứ tự (expected, desired) của CAS (lệch API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void CounterAccess::adopt(JobCounter& counter, const void* current, const void* owner) noexcept {
    const bool busy = (counter.state_.load(kRelaxed) & JobCounter::kCount) != 0;
    const bool foreign = current != nullptr && busy;
    core::check(!foreign, "một JobCounter đang dở nhận job của hai hệ thống việc");
    counter.owner_.store(owner, kRelaxed);
}

void CounterAccess::check_owner(const JobCounter& counter, const void* owner) noexcept {
    const void* const current = counter.owner_.load(kRelaxed);
    const bool foreign = current != nullptr && current != owner && !counter.done();
    core::check(!foreign, "chờ JobCounter qua hệ thống việc khác hệ thống đã nhận job của nó");
}

const void* CounterAccess::key(const JobCounter& counter) noexcept {
    return &counter.state_;
}

// Bên chờ bật bit chờ bằng RMW trên cùng biến, nên thứ tự sửa của biến này quyết định: hoặc lần trừ
// về 0 thấy bit, hoặc bên chờ thấy 0 ngay ở lần bật bit và không ngủ. acq_rel: thợ ghi ô cờ trước
// khi bật bit, nên lần trừ thấy bit thì thấy cả ô cờ. Bên gọi chụp khoá trước lần trừ, vì sau đó bộ
// đếm có thể đã bị huỷ; khoá chỉ để so và làm khoá WakeByAddress, không bao giờ đọc qua nó.
CounterAccess::Waiters CounterAccess::release(JobCounter& counter, std::uint32_t count) noexcept {
    const std::uint32_t previous = counter.state_.fetch_sub(count, kAcqRel);
    const std::uint32_t pending = previous & JobCounter::kCount;
    core::check(pending >= count, "hoàn tất nhiều job hơn số đã nộp");
    if (pending != count) return {};
    return {.outside = (previous & JobCounter::kOutside) != 0, .inside = (previous & JobCounter::kInside) != 0};
}

bool CounterAccess::mark_inside(JobCounter& counter) noexcept {
    const std::uint32_t previous = counter.state_.fetch_or(JobCounter::kInside, kAcqRel);
    return (previous & JobCounter::kCount) == 0;
}

// So với đúng giá trị mà lần bật bit để lại: lần trừ nào xen vào sau đó làm park so lệch và trả về
// ngay. Đọc lại bằng một lần load riêng thì sai: lần trừ về 0 lọt giữa hai bước làm load thấy giá
// trị cuối cùng, park ngủ trên nó, mà lời đánh thức đã phát trước khi park kịp đăng ký — ngủ mãi
// (bắt được khi chạy nối các kịch bản của bench/jobs).
bool CounterAccess::park(JobCounter& counter, std::chrono::nanoseconds timeout) noexcept {
    const std::uint32_t seen = counter.state_.fetch_or(JobCounter::kOutside, kAcqRel) | JobCounter::kOutside;
    if ((seen & JobCounter::kCount) == 0) return true;
    [[maybe_unused]] const bool woke = core::park(counter.state_, seen, timeout);
    return counter.done();
}

// Người ghi đầu tiên giành cờ rồi mới ghi error_; wait đọc error_ sau khi thấy bộ đếm về 0 bằng
// acquire, mà mọi lần trừ đều release sau khi ghi, nên nó thấy.
void CounterAccess::capture(JobCounter& counter, const std::exception_ptr& error) noexcept {
    const std::scoped_lock lock(counter.error_mutex_);
    if (counter.has_error_.exchange(true, kAcqRel)) return;
    counter.error_ = error;
}

// Khoá thả trước khi ném: catch mà nộp tiếp vào cùng bộ đếm không được tự khoá trên owner_mutex_.
void CounterAccess::clear_idle_owner(JobCounter& counter) noexcept {
    const std::scoped_lock lock(counter.owner_mutex_);
    if ((counter.state_.load(kRelaxed) & JobCounter::kCount) == 0) {
        counter.owner_.store(nullptr, kRelaxed);
    }
}

// Cuối mỗi lần chờ: tắt bit chờ để vòng dùng lại sau của bộ đếm không đánh thức ai vô ích. Chỉ tắt
// khi bộ đếm vẫn rỗng, bằng một CAS: luồng khác đã nộp tiếp và đang ngủ chờ thì bit là của nó, xoá
// đi thì lần trừ về 0 sau không gọi nó dậy. Lúc bộ đếm rỗng không ai ngủ trên nó (lần trừ về 0 đã
// đánh thức hết, bên đến sau thấy 0 nên không ngủ), nên CAS thua thì để nguyên bit: tốn một lần
// đánh thức thừa, không mất lần nào.
void CounterAccess::rethrow(JobCounter& counter) {
    std::uint32_t seen = counter.state_.load(kRelaxed);
    const bool marked = seen != 0 && (seen & JobCounter::kCount) == 0;
    [[maybe_unused]] const bool cleared = marked && counter.state_.compare_exchange_strong(seen, 0, kRelaxed);
    clear_idle_owner(counter);
    const std::scoped_lock lock(counter.error_mutex_);
    if (!counter.has_error_.load(kAcquire)) return;
    const std::exception_ptr error = std::exchange(counter.error_, nullptr);
    counter.has_error_.store(false, kRelaxed);
    if (!error) return;
    std::rethrow_exception(error);
}

// relaxed: next chỉ chia chỉ số. Dữ liệu của lô tới tay bên giành qua hàng (release khi đẩy,
// acquire khi lấy); kết quả về tay bên chờ qua bộ đếm. next vượt count tối đa lanes × grain, mà
// grain ≤ count và count ≤ kMaxBatch (kiểm lúc nộp), nên không tràn.
std::optional<Range> claim_fixed(std::atomic<std::size_t>& next, std::size_t count, std::size_t grain) noexcept {
    const std::size_t begin = next.fetch_add(grain, kRelaxed);
    if (begin >= count) return std::nullopt;
    return Range{.begin = begin, .end = std::min(begin + grain, count)};
}

// Cỡ khúc tính từ lần đọc trước, rồi giành bằng một fetch_add: không vòng CAS nên không bao giờ
// thử lại khi mười mấy luồng cùng giành. Bên khác giành xen giữa thì khúc này hơi lớn hơn lý tưởng,
// không sai: khúc vẫn rời nhau và bị cắt ở count. Sàn count / (16 × lanes) giữ số lần giành cỡ trăm
// thay vì vài trăm (200 000 chỉ số, 11 làn: khoảng 105 thay vì 410) mà khúc cuối vẫn chỉ cỡ một
// phần mười sáu phần của mỗi làn.
// NOLINTBEGIN(bugprone-easily-swappable-parameters): số chỉ số rồi số làn như Shape (lệch API-03)
std::optional<Range> claim_guided(std::atomic<std::size_t>& next, std::size_t count, std::uint32_t lanes) noexcept {
    const std::size_t hands = std::max<std::size_t>(lanes, 1U);
    const std::size_t seen = next.load(kRelaxed);
    if (seen >= count) return std::nullopt;
    const std::size_t floor = std::max<std::size_t>(count / (kGuidedFloor * hands), 1U);
    const std::size_t size = std::max((count - seen) / (kGuidedPieces * hands), floor);
    const std::size_t begin = next.fetch_add(size, kRelaxed);
    if (begin >= count) return std::nullopt;
    return Range{.begin = begin, .end = std::min(begin + size, count)};
}
// NOLINTEND(bugprone-easily-swappable-parameters)

} // namespace detail

namespace {

// Thành viên hệ thống

[[nodiscard]] std::uint32_t thread_seed() noexcept {
    const std::size_t mixed = std::hash<std::thread::id>{}(std::this_thread::get_id());
    return static_cast<std::uint32_t>(mixed) | 1U;
}

void bind(State& state, Worker& worker, std::uint32_t index) noexcept {
    t_member.state = &state;
    t_member.worker = &worker;
    t_member.index = index;
    t_member.seed = thread_seed();
}

void unbind() noexcept {
    t_member = Member{};
}

[[nodiscard]] Worker* member_of(const State& state) noexcept {
    if (t_member.state != &state) return nullptr;
    return t_member.worker;
}

// Chọn nạn nhân ngẫu nhiên: mọi kẻ trộm cùng bắt đầu từ ô kế bên thì cùng dồn vào một hàng. Luồng
// ngoài gieo hạt theo mã luồng ở lần đầu, kẻo mọi luồng ngoài đi cùng một dãy.
[[nodiscard]] std::uint32_t pick_victim(std::uint32_t count) noexcept {
    std::uint32_t bits = t_member.seed != 0 ? t_member.seed : thread_seed();
    bits ^= bits << 13U;
    bits ^= bits >> 17U;
    bits ^= bits << 5U;
    t_member.seed = bits;
    return static_cast<std::uint32_t>((std::uint64_t{bits} * count) >> 32U);
}

// Tìm việc

[[nodiscard]] bool queue_filled(const std::unique_ptr<Worker>& worker) noexcept {
    return !worker->queue.looks_empty();
}

[[nodiscard]] bool has_work(const State& state) noexcept {
    if (!state.shared.looks_empty()) return true;
    return std::ranges::any_of(state.workers, queue_filled);
}

// Khác gốc: thân vòng lặp của steal_from tách ra đây. Một lượt thử: hàng trông rỗng thì trả kEmpty
// mà không gọi steal (gốc return false ở đúng chỗ này), còn lại là kết quả của steal.
[[nodiscard]] Steal steal_once(detail::WorkQueue& queue, Job& out) noexcept {
    if (queue.looks_empty()) return Steal::kEmpty;
    return queue.steal(out);
}

// Trộm từ một hàng, thử lại khi thua. Bỏ qua hàng rỗng trước khi trả hàng rào của steal.
// Khác gốc: gốc viết for (attempt < kStealRetries) với hai câu if trong thân, câu sau là
// if (result != Steal::Lost) return result == Steal::Won. Điều kiện "còn thua" lên điều kiện lặp;
// mỗi lượt vẫn là một looks_empty rồi một steal, tối đa kStealRetries lượt.
[[nodiscard]] bool steal_from(detail::WorkQueue& queue, Job& out) noexcept {
    Steal result = Steal::kLost;
    for (int attempt = 0; attempt < kStealRetries && result == Steal::kLost; ++attempt) {
        result = steal_once(queue, out);
    }
    return result == Steal::kWon;
}

// Khác gốc: câu if (&victim != self && steal_from(victim.queue, out)) của steal_any tách ra đây.
[[nodiscard]] bool steal_unless_self(Worker& victim, const Worker* self, Job& out) noexcept {
    return &victim != self && steal_from(victim.queue, out);
}

// Khác gốc: gốc return true ngay trong thân vòng lặp khi trộm được và viết if (++index == count)
// index = 0. Ở đây kết quả lên điều kiện lặp; thứ tự nạn nhân và số hàng được thử giữ nguyên.
[[nodiscard]] bool steal_any(State& state, const Worker* self, Job& out) noexcept {
    const auto count = static_cast<std::uint32_t>(state.workers.size());
    if (count == 0) return false;
    std::uint32_t index = pick_victim(count);
    bool stolen = false;
    for (std::uint32_t step = 0; step < count && !stolen; ++step) {
        stolen = steal_unless_self(*state.workers.at(index), self, out);
        index = index + 1 == count ? 0 : index + 1;
    }
    return stolen;
}

// Hàng của thợ vừa rỗng (pop của nó vừa thất bại, mà chỉ nó đẩy vào), và số job giành không quá
// sức chứa, nên đẩy không thể hỏng.
void keep_rest(Worker& self, std::span<const Job> rest) noexcept {
    for (const Job& job : rest) {
        const bool kept = self.queue.push(job);
        core::check(kept, "hàng của thợ đầy ngay sau khi rỗng");
    }
}

void wake(State& state, std::uint32_t copies) noexcept;

// Thợ giành nhiều job bằng một CAS, chạy một, giữ phần còn lại trong hàng của mình cho thợ khác
// trộm. Luồng ngoài không có hàng nên lấy từng job. Phần giữ lại phải kèm lời đánh thức: thợ khác
// có thể đã nhìn hàng đúng lúc các ô vừa rời hàng chung mà chưa vào hàng này, thấy rỗng và ngủ;
// không ai gọi thì job nằm mãi trong hàng của thợ đang bị job đầu chặn (test "workers carry
// numbered names" treo ở 60 s khi thiếu lời này). wake đặt hàng rào Dekker sau lần đẩy cuối.
[[nodiscard]] bool grab(State& state, Worker* self, Job& out) {
    if (self == nullptr) return state.shared.pop(out);
    const std::span<Job> jobs = self->grabbed;
    const std::size_t limit = std::min(kGrab, self->queue.capacity());
    const std::size_t count = state.shared.pop_batch(jobs.first(limit));
    if (count == 0) return false;
    out = jobs.front();
    keep_rest(*self, jobs.subspan(1, count - 1));
    if (count > 1) wake(state, static_cast<std::uint32_t>(count - 1));
    return true;
}

[[nodiscard]] bool take(State& state, Worker* self, Job& out) {
    if (self != nullptr && self->queue.pop(out)) return true;
    if (grab(state, self, out)) return true;
    return steal_any(state, self, out);
}

// Hoàn tất

// Đánh thức thợ đang ngủ chờ đúng khoá này: CAS chỉ thành công với ô còn mang khoá, nên ô đã chuyển
// sang chờ bộ đếm khác không bị gọi nhầm.
void wake_if_parked(WorkerFlags& flags, const void* key) noexcept {
    const void* expected = key;
    if (!flags.value.parked.compare_exchange_strong(expected, nullptr, kAcqRel)) return;
    core::unpark_all(flags.value.parked);
}

// Thợ của hệ thống ngủ trên ô cờ mang khoá của bộ đếm; quét ô của mọi thợ, CAS chỉ trúng ô còn mang
// đúng khoá.
void wake_workers(State& state, const void* key) noexcept {
    for (WorkerFlags& flags : state.flags) {
        wake_if_parked(flags, key);
    }
}

// Luồng ngoài ngủ thẳng trên bộ đếm nên đánh thức theo địa chỉ của nó; thợ thì qua ô cờ. Bộ đếm mà
// chỉ thợ chờ (fork-join trên thợ) không tốn lần WakeByAddressAll nào cho địa chỉ của nó.
void complete(State& state, JobCounter& counter, std::uint32_t count) noexcept {
    const void* const key = CounterAccess::key(counter);
    const CounterAccess::Waiters waiters = CounterAccess::release(counter, count);
    if (waiters.outside) core::unpark_address(key, core::Wake::kAll);
    if (waiters.inside) wake_workers(state, key);
}

// Gọi trong khối catch: giữ ngoại lệ đầu tiên của job tách rời cho wait_idle.
void keep_error(State& state) noexcept {
    const std::scoped_lock lock(state.error_mutex);
    if (!state.error) state.error = std::current_exception();
}

// Khác gốc: gốc viết return CounterAccess::capture(...) trên một dòng.
void record_failure(State& state, JobCounter* counter) noexcept {
    if (counter != nullptr) {
        CounterAccess::capture(*counter, std::current_exception());
        return;
    }
    keep_error(state);
}

void invoke(State& state, const Job& job) noexcept {
    try {
        job.invoke(job.payload.data(), detail::Act::kRun);
    } catch (...) {
        record_failure(state, job.counter);
    }
}

void execute_now(State& state, const Job& job) noexcept {
    invoke(state, job);
    if (job.counter != nullptr) complete(state, *job.counter, 1);
}

// Xả lượt hoàn tất đang cộng dồn của luồng gọi, nếu nó là thợ.
void flush_held() noexcept {
    if (t_member.done == 0) return;
    complete(*t_member.state, *t_member.held, std::exchange(t_member.done, 0U));
    t_member.held = nullptr;
}

// Vòng thợ: cộng dồn lượt hoàn tất khi job cùng bộ đếm với job trước. Khác bộ đếm (kể cả job tách
// rời) thì xả trước khi chạy, để job đó có chờ bộ đếm cũ cũng không chờ chính luồng này.
void execute_held(State& state, const Job& job) noexcept {
    const bool same = job.counter != nullptr && job.counter == t_member.held;
    if (!same) flush_held();
    invoke(state, job);
    if (job.counter == nullptr) return;
    t_member.held = job.counter;
    ++t_member.done;
}

[[nodiscard]] std::exception_ptr cancelled() noexcept {
    return std::make_exception_ptr(core::Error{core::ErrorCode::kCancelled, "job bị bỏ khi dừng hệ thống việc"});
}

// Job không bao giờ chạy: trả hộp, hoàn tất bộ đếm với lỗi Cancelled.
void drop(State& state, const Job& job) noexcept {
    job.invoke(job.payload.data(), detail::Act::kDrop);
    if (job.counter == nullptr) return;
    CounterAccess::capture(*job.counter, cancelled());
    complete(state, *job.counter, 1);
}

[[nodiscard]] bool take_any(State& state, Job& out) {
    if (state.shared.pop(out)) return true;
    return steal_any(state, nullptr, out);
}

// Bỏ mọi job còn trong mọi hàng. Thợ còn chạy job dở vẫn đẩy thêm được: thợ tự dọn hàng mình khi
// thoát, hàm huỷ của State dọn lần cuối.
void sweep(State& state) {
    Job job;
    while (take_any(state, job)) {
        drop(state, job);
    }
}

void drop_own(State& state, Worker& self) {
    Job job;
    while (self.queue.pop(job)) {
        drop(state, job);
    }
    while (state.shared.pop(job)) {
        drop(state, job);
    }
}

// Rỗi

// Phía báo của khuôn Dekker với await_idle: trạng thái vừa đổi đứng trước hàng rào.
void notify_idle(const State& state) noexcept {
    std::atomic_thread_fence(kSeqCst);
    WaitGate& gate = state.gates->idle.value;
    if (gate.waiters.load(kRelaxed) == 0) return;
    gate.epoch.fetch_add(1, kSeqCst);
    core::unpark_all(gate.epoch);
}

[[nodiscard]] bool is_busy(const WorkerFlags& flags) noexcept {
    return flags.value.busy.load(kSeqCst);
}

// Hàng rỗng, không thợ nào bận, không luồng nào đang giúp, và hàng vẫn rỗng. Lần quét thứ hai bắt
// job do một thợ bận đẩy ra trước khi nó tắt cờ: thấy cờ đã tắt (acquire) là thấy job nó đẩy. Bên
// lấy việc bật cờ, hàng rào, rồi mới chạm hàng; nên hễ thấy job đã bị lấy là thấy cờ đã bật.
[[nodiscard]] bool idle_now(const State& state) noexcept {
    std::atomic_thread_fence(kSeqCst);
    if (has_work(state)) return false;
    std::atomic_thread_fence(kSeqCst);
    if (std::ranges::any_of(state.flags, is_busy)) return false;
    if (state.gates->helpers.value.load(kSeqCst) != 0) return false;
    std::atomic_thread_fence(kSeqCst);
    return !has_work(state);
}

// Luồng ngoài chạy giúp: đếm vào helpers trong suốt đời đối tượng.
class Helping {
public:
    Helping(State& state, bool active) noexcept : state_(active ? &state : nullptr), outer_(t_helping) {
        if (state_ == nullptr) return;
        t_helping = state_;
        state_->gates->helpers.value.fetch_add(1, kSeqCst);
        std::atomic_thread_fence(kSeqCst);
    }

    Helping(const Helping&) = delete;
    Helping(Helping&&) = delete;
    Helping& operator=(const Helping&) = delete;
    Helping& operator=(Helping&&) = delete;

    ~Helping() {
        if (state_ == nullptr) return;
        t_helping = outer_;
        state_->gates->helpers.value.fetch_sub(1, kSeqCst);
        notify_idle(*state_);
    }

private:
    State* state_;
    // Hệ thống luồng này đang giúp trước đó (job của hệ thống này chờ hệ thống kia).
    State* outer_;
};

// Luồng gọi đang ở trong một job của hệ thống: là thợ của nó, hoặc là luồng ngoài đang chạy giúp
// nó.
[[nodiscard]] bool inside_job(const State& state) noexcept {
    return member_of(state) != nullptr || t_helping == &state;
}

[[nodiscard]] bool run_one(State& state, Worker* self) {
    Job job;
    if (!take(state, self, job)) return false;
    execute_now(state, job);
    return true;
}

// Chờ có hạn chỉ chạy job đang nằm trong hàng của chính thợ. take() còn cướp hàng thợ khác: job đó
// dài hơn hạn thì lần chờ không bao giờ trả về.
[[nodiscard]] bool run_local(State& state, Worker& self) {
    Job job;
    if (!self.queue.pop(job)) return false;
    execute_now(state, job);
    return true;
}

// Một job cho luồng ngoài, đếm là luồng giúp trong lúc lấy và chạy.
[[nodiscard]] bool help_once(State& state) {
    const Helping helping{state, true};
    return run_one(state, nullptr);
}

// Đánh thức

[[nodiscard]] bool claim_warm(WarmSlot& warm) noexcept {
    if (!warm.waiting.exchange(false, kSeqCst)) return false;
    warm.signal.release();
    return true;
}

[[nodiscard]] bool claim_if_warm(const std::unique_ptr<Worker>& worker) noexcept {
    return worker->warm != nullptr && claim_warm(*worker->warm);
}

[[nodiscard]] bool wake_warm(State& state) noexcept {
    if (state.gates->sleep.value.warm_waiting.load(kRelaxed) == 0) return false;
    return std::ranges::any_of(state.workers, claim_if_warm);
}

// Hàng rào đứng sau khi job đã vào hàng. Thợ ấm được đánh thức trước vì thức nhanh hơn. false khi
// không còn ai để đánh thức.
[[nodiscard]] bool wake_sleeper(SleepGate& gate) noexcept {
    gate.epoch.fetch_add(1, kSeqCst);
    core::unpark_one(gate.epoch);
    return true;
}

// Gọi dậy một thợ đang ngủ giữa lần chờ lồng nhau để nó giúp việc mới; nó tự kiểm lại bộ đếm.
[[nodiscard]] bool poke(WorkerFlags& flags) noexcept {
    if (flags.value.parked.exchange(nullptr, kAcqRel) == nullptr) return false;
    core::unpark_all(flags.value.parked);
    return true;
}

// Thợ ấm được đánh thức trước vì thức nhanh hơn, rồi thợ ngủ sâu, rồi thợ đang ngủ giữa lần chờ.
// false khi không còn ai để đánh thức. Hàng rào Dekker do wake đặt một lần sau khi mọi bản sao đã
// vào hàng; mỗi lần gọi ở đây không rào lại (fork-join trả một hàng rào mỗi lần nộp, như VnS).
[[nodiscard]] bool wake_one(State& state) noexcept {
    if (wake_warm(state)) return true;
    SleepGate& gate = state.gates->sleep.value;
    if (gate.sleepers.load(kRelaxed) != 0) return wake_sleeper(gate);
    if (gate.parked.load(kRelaxed) == 0) return false;
    return std::ranges::any_of(state.flags, poke);
}

void wake_everyone(const State& state) noexcept {
    SleepGate& gate = state.gates->sleep.value;
    gate.epoch.fetch_add(1, kSeqCst);
    core::unpark_all(gate.epoch);
    for (const std::unique_ptr<Worker>& worker : state.workers) {
        [[maybe_unused]] const bool claimed = claim_if_warm(worker);
    }
}

// Mỗi bản sao một lần đánh thức, dừng sớm khi không còn ai ngủ: lô hai bản sao không đánh thức cả
// pool như wakeAll của _Ref. Lô có ít nhất ngần ấy bản sao như số thợ ngủ sâu thì đánh thức tất cả
// bằng một lần WakeByAddressAll: chuỗi WakeByAddressSingle nối nhau giữ luồng nộp lại cả chục micro
// giây trước khi nó kịp tự giúp, và thợ thức so le.
void wake(State& state, std::uint32_t copies) noexcept {
    std::atomic_thread_fence(kSeqCst);
    const std::uint32_t sleepers = state.gates->sleep.value.sleepers.load(kRelaxed);
    const bool covers = copies > 1 && sleepers > 1 && copies >= sleepers;
    // Khác gốc: gốc viết return wake_everyone(state) trên một dòng.
    if (covers) {
        wake_everyone(state);
        return;
    }
    // Khác gốc: gốc viết for (i < copies) với thân if (!wake_one(state)) return. Kết quả của
    // wake_one lên điều kiện lặp: vẫn mỗi bản sao một lần gọi, dừng ở lần đầu trả false.
    bool woke = true;
    for (std::uint32_t i = 0; i < copies && woke; ++i) {
        woke = wake_one(state);
    }
}

// Ngủ

// Kết quả của park không cần: mọi bên gọi kiểm lại điều kiện sau khi thức (park có thể thức giả).
void park_until(const std::atomic<std::uint32_t>& value, std::uint32_t old, std::chrono::nanoseconds timeout) noexcept {
    [[maybe_unused]] const bool woke = core::park(value, old, timeout);
}

// Phía bên ngủ của khuôn Dekker. Epoch đọc trước khi tăng số người ngủ: bên đẩy đổi epoch giữa hai
// bước đó thì park trả về ngay.
void sleep_until_work(const State& state) {
    SleepGate& gate = state.gates->sleep.value;
    const std::uint32_t epoch = gate.epoch.load(kSeqCst);
    gate.sleepers.fetch_add(1, kSeqCst);
    std::atomic_thread_fence(kSeqCst);
    if (!has_work(state) && !state.halted.load(kSeqCst)) park_until(gate.epoch, epoch, kForever);
    gate.sleepers.fetch_sub(1, kRelaxed);
}

// Thợ ấm: chờ có hạn trên semaphore riêng. Bên đẩy đã giành cờ mà mình chưa nhận tín hiệu (hết giờ
// đúng lúc) thì phải nhận nốt, để semaphore về 0. Trả false chỉ khi hết giờ mà không có việc: lần
// thức đó không đáng quay.
[[nodiscard]] bool wait_warm(const State& state, WarmSlot& warm) {
    SleepGate& gate = state.gates->sleep.value;
    warm.waiting.store(true, kSeqCst);
    gate.warm_waiting.fetch_add(1, kSeqCst);
    std::atomic_thread_fence(kSeqCst);
    const bool is_idle = !has_work(state) && !state.halted.load(kSeqCst);
    const bool signalled = is_idle && warm.signal.try_acquire_for(kWarmInterval);
    const bool claimed = !warm.waiting.exchange(false, kSeqCst);
    if (claimed && !signalled) warm.signal.acquire();
    gate.warm_waiting.fetch_sub(1, kRelaxed);
    if (!is_idle) return true;
    return claimed;
}

// Khác gốc: thân vòng lặp của spin_for_work tách ra đây. Một vòng quay: có việc thì true, không
// thì nhường lượt rồi false.
[[nodiscard]] bool work_or_yield(const State& state) noexcept {
    if (has_work(state)) return true;
    std::this_thread::yield();
    return false;
}

// Khác gốc: gốc viết for (round < kSpinRounds) với thân if (has_work(state)) return true; rồi
// yield. Kết quả lên điều kiện lặp: vẫn mỗi vòng một has_work, không thấy việc thì một yield.
[[nodiscard]] bool spin_for_work(const State& state) noexcept {
    bool found = false;
    for (int round = 0; round < kSpinRounds && !found; ++round) {
        found = work_or_yield(state);
    }
    return found;
}

// pause nhường đơn vị thực thi cho luồng SMT cùng lõi. Nền không có lệnh đó thì yield.
void relax() noexcept {
#if defined(_M_X64) || defined(__x86_64__)
    _mm_pause();
#else
    std::this_thread::yield();
#endif
}

// Khác gốc: thân vòng lặp của spin_on tách ra đây. Một vòng quay: bộ đếm xong thì true, chưa thì
// pause rồi false.
[[nodiscard]] bool done_or_relax(const JobCounter& counter) noexcept {
    if (counter.done()) return true;
    relax();
    return false;
}

// Bên chờ quay ngắn chỉ trên dòng cache của bộ đếm, không quét hàng của ai: quét hàng trong vòng
// quay giành dòng cache với thợ đang làm việc thật. true khi bộ đếm đã xong.
// Khác gốc: gốc viết for (round < kWaitSpins) với thân if (counter.done()) return true; rồi
// relax(). Kết quả lên điều kiện lặp: vẫn mỗi vòng một done() (acquire), chưa xong thì một pause.
[[nodiscard]] bool spin_on(const JobCounter& counter) noexcept {
    bool finished = false;
    for (int round = 0; round < kWaitSpins && !finished; ++round) {
        finished = done_or_relax(counter);
    }
    return finished;
}

// Quay ngắn trước khi ngủ khi is_hot: vòng trước vừa chạy job hoặc vừa được đánh thức bằng tín
// hiệu. Thức vì hết giờ thì không quay, kẻo thợ ấm giữ một nhân nóng mãi. Trả is_hot cho vòng sau.
[[nodiscard]] bool idle(const State& state, WarmSlot* warm, bool is_hot) {
    if (is_hot && spin_for_work(state)) return true;
    if (warm != nullptr) return wait_warm(state, *warm);
    sleep_until_work(state);
    return true;
}

// Bật cờ busy rồi hàng rào, trước khi chạm hàng (lý lẽ ở idle_now).
void mark_busy(const Worker& self) noexcept {
    self.flags->busy.store(true, kRelaxed);
    std::atomic_thread_fence(kSeqCst);
}

[[nodiscard]] bool rest(const State& state, const Worker& self, bool is_hot) {
    self.flags->busy.store(false, kSeqCst);
    notify_idle(state);
    const bool hot = idle(state, self.warm.get(), is_hot);
    mark_busy(self);
    return hot;
}

// Chờ

void park_slot(const std::atomic<const void*>& slot, const void* key) noexcept {
    [[maybe_unused]] const bool woke = core::park(slot, key, kForever);
}

// Thợ chờ lồng nhau: ghi khoá bộ đếm vào ô cờ, đếm vào parked, bật bit chờ của bộ đếm, hàng rào,
// nhìn lại hàng, rồi ngủ trên ô cờ. Dekker với bên đẩy việc (wake_one đọc parked sau hàng rào của
// nó) và với lần trừ về 0 (thấy bit chờ thì thấy ô cờ, xem CounterAccess::release). Ai gọi dậy cũng
// đổi ô về null, nên đổi trước khi thợ kịp ngủ thì park so lệch và trả về ngay.
void park_worker(const State& state, const Worker& self, JobCounter& counter) {
    SleepGate& gate = state.gates->sleep.value;
    std::atomic<const void*>& parked = self.flags->parked;
    const void* const key = CounterAccess::key(counter);
    parked.store(key, kSeqCst);
    gate.parked.fetch_add(1, kSeqCst);
    const bool finished = CounterAccess::mark_inside(counter);
    std::atomic_thread_fence(kSeqCst);
    if (!finished && !has_work(state)) park_slot(parked, key);
    parked.store(nullptr, kRelaxed);
    gate.parked.fetch_sub(1, kRelaxed);
}

// Luồng không phải thợ của hệ thống ngủ thẳng trên bộ đếm: không ai gọi nó dậy để giúp việc mới.
// Khác gốc: gốc viết return park_worker(...) trên một dòng.
void rest_on(const State& state, const Worker* self, JobCounter& counter) {
    if (self != nullptr) {
        park_worker(state, *self, counter);
        return;
    }
    [[maybe_unused]] const bool done = CounterAccess::park(counter, kForever);
}

// Phía bên chờ của khuôn Dekker với notify_idle: waiters tăng, hàng rào, đọc epoch, kiểm lại, rồi
// mới ngủ. helping: luồng gọi chạy giúp được, nên có việc trong hàng cũng là lý do để không ngủ.
void await_idle(const State& state, bool helping, std::chrono::nanoseconds timeout) {
    WaitGate& gate = state.gates->idle.value;
    gate.waiters.fetch_add(1, kSeqCst);
    std::atomic_thread_fence(kSeqCst);
    const std::uint32_t epoch = gate.epoch.load(kSeqCst);
    const bool ready = idle_now(state) || (helping && has_work(state));
    if (!ready) park_until(gate.epoch, epoch, timeout);
    gate.waiters.fetch_sub(1, kRelaxed);
}

// Hạn tuyệt đối; hạn quá lớn thì bão hoà thay vì tràn.
[[nodiscard]] core::Clock::time_point deadline_after(std::chrono::nanoseconds timeout) noexcept {
    const core::Clock::time_point now = core::Clock::now();
    if (timeout >= core::Clock::time_point::max() - now) return core::Clock::time_point::max();
    return now + timeout;
}

[[nodiscard]] std::chrono::nanoseconds left_until(core::Clock::time_point deadline) noexcept {
    if (deadline == core::Clock::time_point::max()) return kForever;
    return deadline - core::Clock::now();
}

[[nodiscard]] std::exception_ptr take_error(State& state) {
    const std::scoped_lock lock(state.error_mutex);
    return std::exchange(state.error, nullptr);
}

void rethrow_error(State& state) {
    const std::exception_ptr error = take_error(state);
    if (error) std::rethrow_exception(error);
}

// Vòng đời thợ

[[nodiscard]] bool step(State& state, Worker& self, bool& is_hot) {
    if (state.abandoning.load(kRelaxed)) return false;
    Job job;
    if (take(state, &self, job)) {
        execute_held(state, job);
        is_hot = true;
        return true;
    }
    flush_held();
    if (state.halted.load(kSeqCst)) return false;
    is_hot = rest(state, self, is_hot);
    return true;
}

void leave(State& state, Worker& self) {
    flush_held();
    if (state.abandoning.load(kSeqCst)) drop_own(state, self);
    unbind();
    self.flags->busy.store(false, kSeqCst);
    state.alive.fetch_sub(1, kRelease);
    notify_idle(state);
}

void work(State& state, std::uint32_t index) {
    Worker& self = *state.workers.at(index);
    bind(state, self, index);
    state.started.fetch_add(1, kRelaxed);
    state.alive.fetch_add(1, kRelaxed);
    mark_busy(self);
    bool is_hot = false;
    while (step(state, self, is_hot)) {
    }
    leave(state, self);
}

// Thân luồng thợ giữ một tham chiếu tới State: thợ tách rời (stop detach) sống lâu hơn JobSystem.
struct WorkerBody {
    std::shared_ptr<State> state;
    std::uint32_t index = 0;

    void operator()([[maybe_unused]] const std::stop_token& token) const { work(*state, index); }
};

// Cấu hình

[[nodiscard]] std::uint32_t resolve_threads(std::uint32_t requested) noexcept {
    if (requested == JobConfig::kAuto) return std::min(core::cpu_count() - 1U, kMaxThreads);
    core::check(requested <= kMaxThreads, "JobConfig::threads vượt 1024");
    return requested;
}

[[nodiscard]] core::CpuSet every_cpu() {
    core::CpuSet cpus;
    const std::size_t count = std::min<std::size_t>(core::cpu_count(), cpus.size());
    for (std::size_t i = 0; i < count; ++i) {
        cpus.set(i);
    }
    return cpus;
}

// CPU thứ n (đếm từ 0) trong tập không rỗng.
// Khác gốc: gốc viết for (i < cpus.size()) với thân if (!cpus.test(i)) continue; rồi
// if (seen++ == n) return i; hết tập thì trả 0. Điều kiện dừng lên điều kiện lặp; seen vẫn là số
// CPU được chọn đứng trước index.
[[nodiscard]] std::size_t nth_cpu(const core::CpuSet& cpus, std::size_t n) noexcept {
    std::size_t seen = 0;
    std::size_t index = 0;
    while (index < cpus.size() && (!cpus.test(index) || seen != n)) {
        seen += cpus.test(index) ? 1U : 0U;
        ++index;
    }
    return index < cpus.size() ? index : 0;
}

[[nodiscard]] core::CpuSet affinity_for(const JobConfig& config, std::uint32_t index) {
    if (!config.spread) return config.affinity;
    const core::CpuSet pool = config.affinity.any() ? config.affinity : every_cpu();
    core::CpuSet single;
    single.set(nth_cpu(pool, index % pool.count()));
    return single;
}

[[nodiscard]] core::ThreadConfig thread_config(const JobConfig& config, std::uint32_t index) {
    return core::ThreadConfig{
        .name = std::format("{} {}", config.name, index + 1),
        .affinity = affinity_for(config, index),
        .priority = config.priority,
    };
}

// Dừng

void halt(State& state) noexcept {
    state.halted.store(true, kSeqCst);
    wake_everyone(state);
}

void spawn(const std::shared_ptr<State>& state, const JobConfig& config) {
    state->handles.reserve(state->threads);
    for (std::uint32_t index = 0; index < state->threads; ++index) {
        WorkerBody body{.state = state, .index = index};
        state->handles.push_back(core::start_thread(thread_config(config, index), std::move(body)));
    }
}

// Tạo thợ hỏng giữa chừng thì dừng và nối những thợ đã tạo rồi ném tiếp; không thợ nào bị bỏ lại
// ngủ mãi như threadSystemInit của _Ref.
void launch(const std::shared_ptr<State>& state, const JobConfig& config) {
    try {
        spawn(state, config);
    } catch (...) {
        halt(*state);
        state->handles.clear();
        throw;
    }
}

// Nộp

// Chế độ không thợ: chạy ngay trên luồng nộp như dummy của _Ref, tính là luồng giúp.
void run_inline(State& state, const Job& job, std::uint32_t copies) {
    const Helping helping{state, true};
    for (std::uint32_t i = 0; i < copies; ++i) {
        execute_now(state, job);
    }
}

// Thợ của hệ thống đẩy vào hàng của mình (việc vừa sinh còn nóng trong cache); hàng đầy hay luồng
// ngoài thì vào hàng chung.
void enqueue(State& state, Worker* self, const Job& job) {
    if (self != nullptr && self->queue.push(job)) return;
    state.shared.push(job);
}

// placed đếm số bản sao đã vào hàng, để bên gọi biết phải hoàn lại bao nhiêu nếu hàng chung ném.
void place(State& state, Worker* self, const Job& job, std::uint32_t copies, std::uint32_t& placed) {
    for (; placed < copies; ++placed) {
        enqueue(state, self, job);
    }
}

// Bản sao chưa vào hàng: trả hộp hay tham chiếu lô, trừ khỏi bộ đếm. Không ghi lỗi vào bộ đếm vì
// ngoại lệ đi thẳng về người nộp.
void refund(State& state, const Job& job, std::uint32_t count) noexcept {
    for (std::uint32_t i = 0; i < count; ++i) {
        job.invoke(job.payload.data(), detail::Act::kDrop);
    }
    if (job.counter != nullptr && count != 0) complete(state, *job.counter, count);
}

// Thợ làm nốt (hoặc bỏ, nếu abandon) rồi tự thoát; mỗi thợ giữ một tham chiếu tới State nên State
// sống tới khi thợ cuối thoát. jthread phải tách trước khi State có thể bị huỷ trên chính một luồng
// thợ: huỷ jthread còn nối được từ chính luồng đó là tự chờ mình.
void detach_workers(State& state) {
    for (std::jthread& handle : state.handles) {
        handle.detach();
    }
    state.stopped.store(true, kRelease);
}

// Chạy trên luồng gọi tới điểm bất động: job sinh job thì vòng sau gặp. Tính là luồng giúp.
void settle(State& state) {
    const Helping helping{state, true};
    Job job;
    while (take_any(state, job)) {
        execute_now(state, job);
    }
}

void report_error(State& state) noexcept {
    try {
        rethrow_error(state);
    } catch (const core::Error& error) {
        core::error("Job tách rời hỏng mà không ai nhận: {}", error.message());
    } catch (const std::exception& error) {
        core::error("Job tách rời ném ngoại lệ mà không ai nhận: {}", error.what());
    } catch (...) {
        core::error("Job tách rời ném ngoại lệ không rõ kiểu mà không ai nhận");
    }
}

// Một lượt của các vòng chờ

// Khác gốc: thân vòng while (!counter.done()) của JobSystem::wait không hạn tách ra đây; gốc viết
// if (run_one(state, self) || spin_on(counter)) continue; rồi rest_on(state, self, counter).
void help_or_rest(State& state, Worker* self, JobCounter& counter) {
    if (run_one(state, self) || spin_on(counter)) return;
    rest_on(state, self, counter);
}

// Kết quả một lượt của wait có hạn: kAgain là kiểm lại bộ đếm (continue của gốc, hay park thức mà
// bộ đếm chưa xong), kExpired là hết hạn (return false của gốc), kDone là park thấy bộ đếm đã xong
// (break của gốc).
enum class Timed : std::uint8_t {
    kAgain,
    kExpired,
    kDone,
};

using Deadline = core::Clock::time_point;

// Khác gốc: thân vòng while (!counter.done()) của JobSystem::wait có hạn tách ra đây, bốn câu if
// theo đúng thứ tự của gốc.
[[nodiscard]] Timed wait_step(State& state, Worker* self, JobCounter& counter, Deadline deadline) {
    // Chỉ hàng của chính thợ. Cướp hàng người khác, hoặc luồng ngoài lấy job đang đứng ở cửa, thì
    // hạn hết mà job kia chưa trả — lần chờ không bao giờ hết giờ.
    if (self != nullptr && run_local(state, *self)) return Timed::kAgain;
    const std::chrono::nanoseconds left = left_until(deadline);
    if (left <= std::chrono::nanoseconds::zero()) return Timed::kExpired;
    if (self != nullptr && spin_on(counter)) return Timed::kAgain;
    return CounterAccess::park(counter, left) ? Timed::kDone : Timed::kAgain;
}

// Khác gốc: thân vòng while (!idle_now(state)) của wait_idle không hạn tách ra đây; gốc viết
// if (help_once(state)) continue; rồi await_idle(state, true, kForever).
void help_or_await(State& state) {
    if (help_once(state)) return;
    await_idle(state, true, kForever);
}

// Khác gốc: thân vòng while (!idle_now(state)) của wait_idle có hạn tách ra đây. false khi hết hạn
// (return false của gốc), true sau một lần await_idle.
[[nodiscard]] bool await_idle_before(const State& state, Deadline deadline) {
    const std::chrono::nanoseconds left = left_until(deadline);
    if (left <= std::chrono::nanoseconds::zero()) return false;
    await_idle(state, false, left);
    return true;
}

} // namespace

JobSystem::State::State(const JobConfig& config, std::uint32_t thread_count)
    : name(config.name), threads(thread_count), flags(thread_count), shared(config.shared_capacity) {
    workers.reserve(threads);
    for (std::uint32_t i = 0; i < threads; ++i) {
        workers.push_back(std::make_unique<Worker>(config.queue_capacity, flags.at(i).value));
    }
    const std::uint32_t warm = std::min(config.warm, threads);
    for (std::uint32_t i = 0; i < warm; ++i) {
        workers.at(i)->warm = std::make_unique<WarmSlot>();
    }
}

JobSystem::State::~State() {
    sweep(*this);
    report_error(*this);
}

JobSystem::JobSystem(const JobConfig& config)
    : state_(std::make_shared<State>(config, resolve_threads(config.threads))), threads_(state_->threads) {
    launch(state_, config);
}

JobSystem::~JobSystem() {
    stop();
}

// Sau stop chỉ thợ tách rời còn nộp được (job của nó sinh job con); luồng ngoài nộp là lỗi.
void JobSystem::publish(const Job& job, std::uint32_t copies) {
    State& state = *state_;
    Worker* const self = member_of(state);
    const bool is_open = self != nullptr || !state.stopped.load(kRelaxed);
    core::check(is_open, "nộp job sau khi hệ thống việc đã dừng");
    if (job.counter != nullptr) CounterAccess::add(*job.counter, copies, &state);
    // Khác gốc: gốc viết return run_inline(state, job, copies) trên một dòng.
    if (threads_ == 0) {
        run_inline(state, job, copies);
        return;
    }
    std::uint32_t placed = 0;
    try {
        place(state, self, job, copies, placed);
    } catch (...) {
        wake(state, placed);
        refund(state, job, copies - placed);
        throw;
    }
    wake(state, copies);
}

void JobSystem::share(const Job& job, std::uint32_t copies) noexcept {
    try {
        publish(job, copies);
    } catch (...) {
        CounterAccess::capture(*job.counter, std::current_exception());
    }
}

// NOLINTBEGIN(bugprone-easily-swappable-parameters): số chỉ số rồi số khúc (lệch API-03)
std::uint32_t JobSystem::lanes_for(std::size_t count, std::size_t chunks, bool caller_helps) const noexcept {
    core::check(count <= kMaxBatch, "lô quá lớn: con trỏ giành chỉ số sẽ tràn");
    const std::size_t extra = caller_helps ? 1U : 0U;
    const std::size_t hands = std::max<std::size_t>(std::size_t{threads_} + extra, 1U);
    return static_cast<std::uint32_t>(std::clamp<std::size_t>(chunks, 1U, hands));
}
// NOLINTEND(bugprone-easily-swappable-parameters)

// Luồng gọi là thợ (của hệ thống này hay hệ thống khác) thì xả lượt hoàn tất đang giữ trước khi
// chờ, để không ai phải đợi nó. Hết việc để giúp thì quay ngắn trên bộ đếm, rồi ngủ (rest_on).
void JobSystem::wait(JobCounter& counter) {
    State& state = *state_;
    CounterAccess::check_owner(counter, &state);
    Worker* const self = member_of(state);
    flush_held();
    const Helping helping{state, self == nullptr};
    while (!counter.done()) {
        help_or_rest(state, self, counter);
    }
    CounterAccess::rethrow(counter);
}

bool JobSystem::wait(JobCounter& counter, std::chrono::nanoseconds timeout) {
    State& state = *state_;
    CounterAccess::check_owner(counter, &state);
    Worker* const self = member_of(state);
    flush_held();
    const core::Clock::time_point deadline = deadline_after(timeout);
    // Khác gốc: gốc viết while (!counter.done()) với continue, return false và break trong thân.
    // Kết quả mỗi lượt (wait_step) lên điều kiện lặp: done() vẫn được đọc trước mỗi lượt, và không
    // được đọc lại sau lượt đã hết hạn hay đã thấy xong, như return và break của gốc.
    Timed outcome = Timed::kAgain;
    while (outcome == Timed::kAgain && !counter.done()) {
        outcome = wait_step(state, self, counter, deadline);
    }
    if (outcome == Timed::kExpired) return false;
    CounterAccess::rethrow(counter);
    return true;
}

void JobSystem::wait_idle() {
    State& state = *state_;
    core::check(!inside_job(state), "wait_idle gọi từ trong job của chính hệ thống");
    while (!idle_now(state)) {
        help_or_await(state);
    }
    rethrow_error(state);
}

bool JobSystem::wait_idle(std::chrono::nanoseconds timeout) {
    State& state = *state_;
    core::check(!inside_job(state), "wait_idle gọi từ trong job của chính hệ thống");
    const core::Clock::time_point deadline = deadline_after(timeout);
    // Khác gốc: gốc return false ngay trong thân vòng while (!idle_now(state)) khi hết hạn. Kết
    // quả mỗi lượt lên điều kiện lặp: idle_now vẫn chạy trước mỗi lượt và không chạy lại sau lượt
    // đã hết hạn.
    bool in_time = true;
    while (in_time && !idle_now(state)) {
        in_time = await_idle_before(state, deadline);
    }
    if (!in_time) return false;
    rethrow_error(state);
    return true;
}

bool JobSystem::is_idle() const noexcept {
    return idle_now(*state_);
}

bool JobSystem::assist() {
    State& state = *state_;
    Worker* const self = member_of(state);
    const Helping helping{state, self == nullptr};
    return run_one(state, self);
}

void JobSystem::assist_all() {
    while (assist()) {
    }
}

void JobSystem::stop(StopOptions options) {
    if (!state_ || state_->stopped.load(kAcquire)) return;
    State& state = *state_;
    core::check(!inside_job(state), "stop gọi từ trong job của chính hệ thống");
    state.closing.store(true, kSeqCst);
    if (options.abandon) state.abandoning.store(true, kSeqCst);
    const bool drains = !options.abandon && !options.detach;
    if (drains) settle(state);
    halt(state);
    if (options.abandon) sweep(state);
    // Khác gốc: gốc viết return detach_workers(state) trên một dòng.
    if (options.detach) {
        detach_workers(state);
        return;
    }
    state.handles.clear();
    if (options.abandon) sweep(state);
    if (!options.abandon) settle(state);
    state.stopped.store(true, kRelease);
}

JobInfo JobSystem::info() const noexcept {
    const State& state = *state_;
    return JobInfo{
        .threads = state.threads,
        .started = state.started.load(kRelaxed),
        .alive = state.alive.load(kRelaxed),
        .name = state.name,
    };
}

std::optional<std::uint32_t> JobSystem::worker_index() const noexcept {
    if (member_of(*state_) == nullptr) return std::nullopt;
    return t_member.index;
}

bool JobSystem::is_stopping() const noexcept {
    return state_->closing.load(kAcquire);
}

} // namespace game::jobs
