// Hệ thống việc song song, thay ThreadSystem của _Ref (Utilities/Threading). Mỗi thợ một hàng
// Chase-Lev; luồng ngoài nộp vào hàng chung không khoá; luồng chờ chạy giúp rồi mới ngủ. Phần đã đo
// lấy từ VnS (src/core/jobs.*, job_queue.*). Forge2 thêm: nộp lô O(1) — run_batch và parallel_for
// là một bản ghi, các bản sao giành chỉ số theo khúc; thợ cộng dồn lượt hoàn tất của cùng một bộ
// đếm rồi xả một lần; wait_idle không tốn gì trên đường nóng; chờ có hạn; dừng drain, abandon,
// detach; nhiều hệ thống trên một luồng, huỷ từ luồng nào cũng được. Ánh xạ API _Ref và lỗi gốc đã
// sửa ở docs/modules/jobs.md; thứ tự bộ nhớ lập luận tại chỗ ở jobs.cpp và queue.cpp.
// Nguồn: Forge2 src/jobs/jobs.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; bỏ {} thừa của các
// thành viên mutex, exception_ptr, CpuSet, string_view; tham số body của constructor Batch đổi tên
// thành work (trùng tên thành viên); vòng chặt trong khối try của call_from tách thành call_each.
#pragma once

#include "core/thread.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <bit>
#include <chrono>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <exception>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>

namespace game::jobs {

namespace detail {
struct CounterAccess;
} // namespace detail

// Số job còn dở của một nhóm, tối đa 2^30 - 1. JobSystem::wait trả về khi nó về 0 và ném lại
// ngoại lệ đầu tiên của nhóm; dùng lại được sau đó. Huỷ khi còn job là lỗi lập trình. pending()
// trễ được: thợ cộng dồn lượt hoàn tất của cùng bộ đếm rồi mới trừ.
class JobCounter {
public:
    JobCounter() noexcept = default;
    JobCounter(const JobCounter&) = delete;
    JobCounter(JobCounter&&) = delete;
    JobCounter& operator=(const JobCounter&) = delete;
    JobCounter& operator=(JobCounter&&) = delete;
    ~JobCounter();

    [[nodiscard]] bool done() const noexcept { return (state_.load(std::memory_order_acquire) & kCount) == 0; }

    [[nodiscard]] std::uint32_t pending() const noexcept { return state_.load(std::memory_order_relaxed) & kCount; }

private:
    friend struct detail::CounterAccess;

    // Hai bit cao: có bên đang ngủ chờ bộ đếm này — luồng ngoài ngủ thẳng trên bộ đếm (kOutside),
    // thợ ngủ trên ô cờ của nó (kInside). Lần trừ đưa số job về 0 thấy bit nào thì đánh thức đúng
    // kiểu đó, không đánh thức cả hệ thống mỗi lần một nhóm xong.
    static constexpr std::uint32_t kOutside = std::uint32_t{1} << 31U;
    static constexpr std::uint32_t kInside = std::uint32_t{1} << 30U;
    static constexpr std::uint32_t kCount = kInside - 1U;

    std::atomic<std::uint32_t> state_{0};
    // Hệ thống đã nhận job của bộ đếm, null khi chưa nộp hay đã chờ xong. Chờ qua hệ thống khác là
    // tự khoá (lần trừ về 0 chỉ gọi dậy thợ của hệ thống chạy job), nên wait kiểm và dừng có thông
    // báo. owner_mutex_ bọc lần nhận chủ và lần bỏ chủ: hai hệ thống cùng nộp vào bộ đếm rỗng, hoặc
    // rethrow xoá chủ đúng lúc hệ thống kia nhận, đều lọt nếu chỉ có store relaxed.
    std::atomic<const void*> owner_{nullptr};
    std::mutex owner_mutex_;
    std::atomic<bool> has_error_{false};
    // error_mutex_ bảo vệ error_ khi nhiều wait cùng đọc. has_error_ một mình không đủ: hai bên
    // cùng thấy true rồi cùng exchange là data race, bên thua rethrow nullptr và terminate.
    std::mutex error_mutex_;
    std::exception_ptr error_;
};

struct JobConfig {
    static constexpr std::uint32_t kAuto = ~0U;
    // Số luồng thợ. kAuto là cpu_count() - 1: luồng gọi chạy giúp khi chờ. 0 là chế độ không thợ
    // của _Ref: job chạy ngay trên luồng nộp, tất định, không tạo luồng nào. Không kẹp theo số CPU
    // như _Ref: pool chờ IO được phép đông hơn số lõi.
    std::uint32_t threads = kAuto;
    // Tên thợ là "<name> 1", "<name> 2"... ở cả log lẫn debugger.
    std::string name = "Jobs";
    // Rỗng thì không ghim. spread: thợ thứ i ghim riêng CPU thứ i của tập (tập rỗng là mọi CPU),
    // quay vòng khi thợ nhiều hơn CPU; không spread thì mọi thợ cùng ghim cả tập.
    core::CpuSet affinity;
    bool spread = false;
    core::ThreadPriority priority = core::ThreadPriority::kNormal;
    // Số thợ chờ có hạn 2 ms trước khi ngủ sâu: thức nhanh hơn, đổi lấy chút CPU lúc rỗi. Kẹp theo
    // số thợ.
    std::uint32_t warm = 1;
    // Sức chứa hàng của mỗi thợ và của vòng không khoá chung, làm tròn lên lũy thừa của 2.
    std::uint32_t queue_capacity = 4096;
    std::uint32_t shared_capacity = 1024;
};

// abandon: job còn trong hàng bị bỏ, bộ đếm của chúng hoàn tất với core::Error mã Cancelled.
// detach: không chờ thợ; thợ làm nốt (hoặc bỏ, nếu abandon) rồi tự thoát. Hai cờ của
// ThreadSystemExitDesc trong _Ref, kết hợp tự do như gốc. Thợ tách rời còn chạy khi main trả về thì
// CRT kết thúc chúng giữa chừng như mọi luồng khác.
struct StopOptions {
    bool abandon = false;
    bool detach = false;
};

struct JobInfo {
    // Số thợ đã cấu hình, số thợ đã vào vòng làm việc, số thợ chưa thoát.
    std::uint32_t threads = 0;
    std::uint32_t started = 0;
    std::uint32_t alive = 0;
    // Mượn: sống cùng hệ thống.
    std::string_view name;
};

namespace detail {

// Hai dòng 64 B: bộ nạp trước của Intel kéo dòng theo cặp (VnS core/types.hpp).
inline constexpr std::size_t kLine = 128;

// Đệm viết tường minh tới bội của kLine, nên trình biên dịch không phải tự chèn đệm và C4324 giữ
// bật cho cả dự án.
template <class T, std::size_t Pad>
struct PaddedStorage {
    T value{};
    std::array<std::byte, Pad> padding{};
};

template <class T>
struct PaddedStorage<T, 0> {
    T value{};
};

template <class T>
inline constexpr std::size_t kPadFor = (kLine - (sizeof(T) % kLine)) % kLine;

template <class T>
struct alignas(kLine) Padded : PaddedStorage<T, kPadFor<T>> {};

inline constexpr std::size_t kPayload = 48;

// kRun: chạy rồi huỷ callable. kDrop: chỉ huỷ — job bị bỏ khi dừng kiểu abandon hay khi nộp hỏng.
enum class Act : std::uint8_t { kRun, kDrop };

using Invoke = void (*)(const std::byte* payload, Act act);

// Vừa một dòng cache. Chép bằng byte là đủ: khi nằm trong hàng, job không sở hữu gì ngoài con trỏ
// tới hộp trên heap mà Run hay Drop trả lại đúng một lần.
struct Job {
    Invoke invoke = nullptr;
    JobCounter* counter = nullptr;
    alignas(8) std::array<std::byte, kPayload> payload{};
};

static_assert(sizeof(Job) == 64, "Job phải vừa 64 byte");
static_assert(std::is_trivially_copyable_v<Job>, "Job phải chép được bằng byte");

// Chỗ duy nhất chạm ruột JobCounter; cài đặt ở jobs.cpp.
struct CounterAccess {
    // owner: hệ thống nhận job. Một bộ đếm đang dở dùng cho hai hệ thống là lỗi lập trình.
    static void add(JobCounter& counter, std::uint32_t count, const void* owner) noexcept;
    // Bộ đếm đang dở thuộc hệ thống khác owner là lỗi lập trình: wait qua đó sẽ ngủ mãi.
    static void check_owner(const JobCounter& counter, const void* owner) noexcept;
    // Lần nộp đầu, hay lần nộp vào hệ thống khác khi bộ đếm đã xong: ghi chủ mới.
    static void adopt(JobCounter& counter, const void* current, const void* owner) noexcept;
    // Khoá đánh thức của bộ đếm: địa chỉ của nó, chỉ để so và làm khoá WakeByAddress.
    [[nodiscard]] static const void* key(const JobCounter& counter) noexcept;
    // Bên chờ mà lần trừ về 0 phải đánh thức.
    struct Waiters {
        bool outside = false;
        bool inside = false;
    };
    // Trừ count; lần trừ đưa bộ đếm về 0 thì trả các bên đang ngủ chờ để bên gọi đánh thức (khoá
    // lấy bằng key() trước khi gọi). Sau lần trừ về 0 không được chạm counter: bên chờ có thể huỷ
    // nó.
    [[nodiscard]] static Waiters release(JobCounter& counter, std::uint32_t count) noexcept;
    // Thợ báo sắp ngủ chờ bộ đếm. true khi nó đã về 0 (khỏi ngủ).
    [[nodiscard]] static bool mark_inside(JobCounter& counter) noexcept;
    // Luồng ngoài ngủ thẳng trên bộ đếm tới khi nó về 0 hoặc hết timeout; có thể thức sớm. true khi
    // đã về 0.
    [[nodiscard]] static bool park(JobCounter& counter, std::chrono::nanoseconds timeout) noexcept;
    // Giữ ngoại lệ đầu tiên của nhóm.
    static void capture(JobCounter& counter, const std::exception_ptr& error) noexcept;
    // Xoá chủ khi bộ đếm rỗng. Khoá thả trước khi ném, để catch nộp tiếp không tự khoá.
    static void clear_idle_owner(JobCounter& counter) noexcept;
    static void rethrow(JobCounter& counter);
};

template <class F>
inline constexpr bool kInline =
    sizeof(F) <= kPayload && alignof(F) <= 8 && std::is_trivially_copyable_v<F> && std::is_trivially_destructible_v<F>;

template <class T>
void pack(Job& job, T* pointer) noexcept {
    const auto bytes = std::bit_cast<std::array<std::byte, sizeof(T*)>>(pointer);
    std::memcpy(job.payload.data(), bytes.data(), bytes.size());
}

template <class T>
[[nodiscard]] T* unpack(const std::byte* payload) noexcept {
    std::array<std::byte, sizeof(T*)> bytes{};
    std::memcpy(bytes.data(), payload, bytes.size());
    return std::bit_cast<T*>(bytes);
}

template <class F>
void invoke_inline(const std::byte* payload, Act act) {
    if (act == Act::kDrop) return;
    std::array<std::byte, sizeof(F)> bytes{};
    std::memcpy(bytes.data(), payload, sizeof(F));
    F function = std::bit_cast<F>(bytes);
    function();
}

// unique_ptr huỷ callable kể cả khi nó ném.
template <class F>
void invoke_boxed(const std::byte* payload, Act act) {
    const std::unique_ptr<F> owner{unpack<F>(payload)};
    if (act == Act::kRun) (*owner)();
}

template <class F>
[[nodiscard]] Job make_job(F&& function, JobCounter* counter) {
    using Fn = std::remove_cvref_t<F>;
    Job job;
    job.counter = counter;
    if constexpr (kInline<Fn>) {
        const auto bytes = std::bit_cast<std::array<std::byte, sizeof(Fn)>>(function);
        std::memcpy(job.payload.data(), bytes.data(), bytes.size());
        job.invoke = &invoke_inline<Fn>;
        return job;
    } else {
        std::unique_ptr<Fn> owned = std::make_unique<Fn>(std::forward<F>(function));
        pack(job, owned.release());
        job.invoke = &invoke_boxed<Fn>;
        return job;
    }
}

struct Range {
    std::size_t begin = 0;
    std::size_t end = 0;
};

// Cách chia một lô: count chỉ số, khúc grain chỉ số, lanes bên giành song song. Gói thành struct để
// nơi dựng lô gọi tên từng trường, không đảo nhầm hai size_t.
struct Shape {
    std::size_t count = 0;
    std::size_t grain = 0;
    std::uint32_t lanes = 1;
};

// Bản ghi lô: mọi bản sao job của lô giành chung chỉ số qua next. grain 0 là khúc dẫn dắt (guided
// của OpenMP): khúc lớn lúc đầu, nhỏ dần về cuối, mỗi khúc cỡ phần còn lại chia (4 × lanes), không
// nhỏ hơn count chia (16 × lanes) (claim_guided). next nằm riêng hai dòng cache vì mọi bên giành
// đều ghi vào nó, phần còn lại chỉ đọc.
template <class Body>
struct Batch {
    // Khác gốc: tham số thứ hai của gốc tên body, trùng tên thành viên (-Wshadow).
    Batch(Shape shape, Body work) : count(shape.count), grain(shape.grain), lanes(shape.lanes), body(std::move(work)) {}

    Padded<std::atomic<std::size_t>> next{};
    std::size_t count;
    std::size_t grain;
    std::uint32_t lanes;
    // Số bản sao còn giữ bản ghi; chỉ bản ghi trên heap (run_batch) dùng.
    std::atomic<std::uint32_t> refs{0};
    Body body;
};

[[nodiscard]] std::optional<Range> claim_fixed(std::atomic<std::size_t>& next, std::size_t count,
    std::size_t grain) noexcept;
[[nodiscard]] std::optional<Range> claim_guided(std::atomic<std::size_t>& next, std::size_t count,
    std::uint32_t lanes) noexcept;

template <class Body>
[[nodiscard]] std::optional<Range> claim(Batch<Body>& batch) noexcept {
    if (batch.grain != 0) return claim_fixed(batch.next.value, batch.count, batch.grain);
    return claim_guided(batch.next.value, batch.count, batch.lanes);
}

// Gọi trong khối catch.
inline void keep_first(std::exception_ptr& first) noexcept {
    if (!first) first = std::current_exception();
}

template <class Body>
void run_range(const Body& body, Range range, std::exception_ptr& first) noexcept {
    try {
        body(range);
    } catch (...) {
        keep_first(first);
    }
}

// Chạy mọi khúc còn giành được; một khúc ném không làm mất các khúc sau. Ném lại ngoại lệ đầu tiên.
template <class Body>
void drain(Batch<Body>& batch) {
    std::exception_ptr first;
    for (std::optional<Range> range = claim(batch); range; range = claim(batch)) {
        run_range(batch.body, *range, first);
    }
    if (first) std::rethrow_exception(first);
}

// Chạy function từ index tới end trong một vòng chặt; ném thì giữ ngoại lệ đầu tiên và trả chỉ số
// kế tiếp để bên gọi chạy tiếp. Một khối try cho cả vòng thay vì mỗi chỉ số một khối: khối try
// trong thân vòng cản trình biên dịch tối ưu vòng (nộp lô 0,22–0,24 xuống 0,18–0,23 ns/task).
// Khác gốc: gốc viết vòng for (; index < end; ++index) function(index) ngay trong khối try của
// call_from; ở đây vòng đó là call_each, index đi qua tham chiếu để khối catch thấy chỉ số vừa ném.
template <class F>
void call_each(const F& function, std::size_t& index, std::size_t end) {
    for (; index < end; ++index) {
        function(index);
    }
}

template <class F>
[[nodiscard]] std::size_t call_from(const F& function, std::size_t index, std::size_t end,
    std::exception_ptr& first) noexcept {
    try {
        call_each(function, index, end);
    } catch (...) {
        keep_first(first);
        ++index;
    }
    return index;
}

// run_batch: function(i) cho từng chỉ số; một chỉ số ném không làm mất các chỉ số còn lại.
template <class F>
struct EachBody {
    F function;

    void operator()(Range range) const {
        std::exception_ptr first;
        for (std::size_t i = range.begin; i < range.end;) {
            i = call_from(function, i, range.end, first);
        }
        if (first) std::rethrow_exception(first);
    }
};

// parallel_for: function(begin, end) trên đối tượng của người gọi, không chép.
template <class F>
struct SpanBody {
    const F* function = nullptr;

    void operator()(Range range) const { (*function)(range.begin, range.end); }
};

// Bản sao giữ một tham chiếu tới bản ghi trên heap; bản sao cuối giải phóng nó.
template <class Body>
class Lease {
public:
    explicit Lease(Batch<Body>* batch) noexcept : batch_(batch) {}
    Lease(const Lease&) = delete;
    Lease(Lease&&) = delete;
    Lease& operator=(const Lease&) = delete;
    Lease& operator=(Lease&&) = delete;

    // acq_rel: bên giải phóng thấy mọi truy cập của các bản sao khác đã xong.
    ~Lease() {
        if (batch_->refs.fetch_sub(1, std::memory_order_acq_rel) != 1) return;
        const std::unique_ptr<Batch<Body>> owner{batch_};
    }

    [[nodiscard]] Batch<Body>& batch() const noexcept { return *batch_; }

private:
    Batch<Body>* batch_;
};

template <class Body>
void invoke_owned(const std::byte* payload, Act act) {
    const Lease<Body> lease{unpack<Batch<Body>>(payload)};
    if (act == Act::kRun) drain(lease.batch());
}

// Bản ghi trên stack của parallel_for: người gọi chờ mọi bản sao xong rồi mới rời hàm.
template <class Body>
void invoke_borrowed(const std::byte* payload, Act act) {
    if (act == Act::kRun) drain(*unpack<Batch<Body>>(payload));
}

} // namespace detail

class JobSystem {
public:
    explicit JobSystem(const JobConfig& config = {});
    JobSystem(const JobSystem&) = delete;
    JobSystem(JobSystem&&) = delete;
    JobSystem& operator=(const JobSystem&) = delete;
    JobSystem& operator=(JobSystem&&) = delete;
    // stop() mặc định nếu chưa dừng: chạy hết mọi job còn lại, kể cả job sinh thêm lúc đang dừng.
    ~JobSystem();

    // Chạy function() song song. Ngoại lệ đi theo counter, wait ném lại.
    template <class F>
        requires std::invocable<std::remove_cvref_t<F>&>
    void run(JobCounter& counter, F&& function) {
        publish(detail::make_job(std::forward<F>(function), &counter), 1);
    }

    // Không ai chờ. Ngoại lệ được giữ lại cho wait_idle ném.
    template <class F>
        requires std::invocable<std::remove_cvref_t<F>&>
    void run_detached(F&& function) {
        publish(detail::make_job(std::forward<F>(function), nullptr), 1);
    }

    // function(i) cho i trong [0, count), trả về ngay — threadSystemAddTasks của _Ref. Cả lô là một
    // bản ghi; tối đa số thợ bản sao vào hàng, không phải count job. function được gọi đồng thời từ
    // nhiều luồng nên phải gọi được qua const.
    template <class F>
        requires std::invocable<const std::remove_cvref_t<F>&, std::size_t>
    void run_batch(JobCounter& counter, std::size_t count, F&& function) {
        share_owned(&counter, count, detail::EachBody<std::remove_cvref_t<F>>{std::forward<F>(function)});
    }

    template <class F>
        requires std::invocable<const std::remove_cvref_t<F>&, std::size_t>
    void run_batch_detached(std::size_t count, F&& function) {
        share_owned(nullptr, count, detail::EachBody<std::remove_cvref_t<F>>{std::forward<F>(function)});
    }

    // function(begin, end) trên các khúc phủ [0, count), chờ xong mới trả về; luồng gọi chạy một
    // phần. grain 0 là khúc dẫn dắt; khác 0 là khúc cố định grain phần tử. function không bị chép
    // và được gọi đồng thời.
    template <class F>
        requires std::invocable<const F&, std::size_t, std::size_t>
    void parallel_for(std::size_t count, std::size_t grain, const F& function);

    // Chạy giúp job trong lúc chờ, hết việc thì ngủ. Ném lại ngoại lệ đầu tiên của nhóm. Chờ qua
    // đúng hệ thống đã nhận job của bộ đếm; hệ thống khác là lỗi lập trình (check), không phải
    // treo.
    void wait(JobCounter& counter);
    // Không chạy giúp, để không lỡ hạn vì một job dài. false khi hết hạn; hạn làm tròn theo nhịp
    // hẹn giờ của Windows (15,6 ms mặc định).
    [[nodiscard]] bool wait(JobCounter& counter, std::chrono::nanoseconds timeout);

    // Chờ tới khi không còn job nào trong hàng hay đang chạy, kể cả job chạy qua assist và luồng
    // đang chờ bộ đếm. Ném lại ngoại lệ đầu tiên của job tách rời. Gọi từ trong job của chính hệ
    // thống (trên thợ hay trên luồng ngoài đang chạy giúp) là lỗi lập trình. Bản có hạn không chạy
    // giúp, hạn làm tròn như wait có hạn. Luồng khác nộp song song thì rỗi chỉ có nghĩa tại một
    // thời điểm trong lúc gọi.
    void wait_idle();
    [[nodiscard]] bool wait_idle(std::chrono::nanoseconds timeout);
    [[nodiscard]] bool is_idle() const noexcept;

    // Chạy một job đang chờ trên luồng gọi; false khi hàng rỗng. Không bao giờ chặn — threadSystem
    // Assist của _Ref chặn khi hàng rỗng.
    bool assist();
    // Chạy giúp tới khi hàng rỗng.
    void assist_all();

    // Dừng một lần, từ một luồng; lần sau không làm gì. Drain: luồng gọi chạy giúp tới khi hàng
    // rỗng, dừng thợ, rồi chạy nốt job sinh thêm. Nộp từ luồng ngoài sau khi dừng là lỗi lập trình
    // (check); nộp song song với stop là vi phạm hợp đồng mà check không bắt kịp. Thợ tách rời vẫn
    // nộp được job con. Gọi từ trong job của chính hệ thống là lỗi lập trình.
    void stop(StopOptions options = {});

    [[nodiscard]] std::uint32_t thread_count() const noexcept { return threads_; }
    [[nodiscard]] JobInfo info() const noexcept;
    // Chỉ số của luồng gọi trong [0, thread_count()) nếu nó là thợ của hệ thống này. Luồng ngoài,
    // assist và chế độ không thợ không có chỉ số — _Ref trộn 0 với UINT64_MAX cho hai trường hợp
    // đó.
    [[nodiscard]] std::optional<std::uint32_t> worker_index() const noexcept;
    // Đúng từ lúc stop bắt đầu. Job dài nên hỏi để tự kết thúc sớm.
    [[nodiscard]] bool is_stopping() const noexcept;

    struct State;

private:
    // Gắn copies bản sao của job vào bộ đếm của nó và đưa vào hàng. Ném thì các bản sao chưa vào
    // hàng đã được Drop và trừ khỏi bộ đếm.
    void publish(const detail::Job& job, std::uint32_t copies);
    // Như publish nhưng không ném: lỗi ghi vào bộ đếm của job.
    void share(const detail::Job& job, std::uint32_t copies) noexcept;
    // Số bản sao của một lô: một cho mỗi tay giành được khúc, không hơn số khúc. Kiểm count không
    // làm tràn con trỏ giành (detail::claim_fixed).
    [[nodiscard]] std::uint32_t lanes_for(std::size_t count, std::size_t chunks, bool caller_helps) const noexcept;

    template <class Body>
    void share_owned(JobCounter* counter, std::size_t count, Body body);

    std::shared_ptr<State> state_;
    std::uint32_t threads_ = 0;
};

template <class Body>
void JobSystem::share_owned(JobCounter* counter, std::size_t count, Body body) {
    if (count == 0) return;
    const std::uint32_t lanes = lanes_for(count, count, false);
    const detail::Shape shape{.count = count, .grain = 0, .lanes = lanes};
    auto batch = std::make_unique<detail::Batch<Body>>(shape, std::move(body));
    batch->refs.store(lanes, std::memory_order_relaxed);
    detail::Job job;
    job.counter = counter;
    job.invoke = &detail::invoke_owned<Body>;
    detail::pack(job, batch.release());
    publish(job, lanes);
}

template <class F>
    requires std::invocable<const F&, std::size_t, std::size_t>
void JobSystem::parallel_for(std::size_t count, std::size_t grain, const F& function) {
    if (count == 0) return;
    using Body = detail::SpanBody<F>;
    const std::size_t width = std::min(grain, count);
    const std::size_t chunks = width == 0 ? count : ((count - 1) / width) + 1;
    const std::uint32_t lanes = lanes_for(count, chunks, true);
    const detail::Shape shape{.count = count, .grain = width, .lanes = lanes};
    detail::Batch<Body> batch{shape, Body{&function}};
    JobCounter counter;
    detail::Job job;
    job.counter = &counter;
    job.invoke = &detail::invoke_borrowed<Body>;
    detail::pack(job, &batch);
    share(job, lanes - 1);
    try {
        detail::drain(batch);
    } catch (...) {
        detail::CounterAccess::capture(counter, std::current_exception());
    }
    wait(counter);
}

} // namespace game::jobs
