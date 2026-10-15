# DT · Đồng thời: luồng, khoá, atomic, thứ tự bộ nhớ, lock-free

> **Phạm vi:** vòng đời luồng, khoá, biến điều kiện, atomic và thứ tự bộ nhớ, hàng đợi giữa luồng,
> false sharing, lock-free (ring SPSC, seqlock, free list có thẻ), thu hồi bộ nhớ đồng thời, TSan.
> **Đọc khi:** tạo luồng hay pool; chuyển dữ liệu giữa luồng IO, luồng zone, pool DB; viết hoặc
> review `std::atomic`, `memory_order`, `volatile`, `detach`, `sleep_for` để chờ; cấu hình nóng;
> TSan báo lỗi; tối ưu đường nóng nhiều luồng.
> **Liên quan:** refs/18-game-mmo.md (MMO: tick, chuyển giao mạng→game), refs/17-kien-truc-module.md
> (KTR: zone/shard, quan sát), refs/10-bo-nho-cache-dod.md (BN-08 `kCacheLine`),
> refs/13-ub-on-dinh.md (UB: sanitizer, áp lực ngược), refs/15-kiem-thu.md (KT: test đồng thời).

## 1. Nền tảng [N]

### DT-01 [N] PHẢI — Trạng thái khả biến thuộc đúng một luồng; luồng khác gửi thông điệp qua hộp thư

Trạng thái zone thuộc luồng zone, socket thuộc luồng IO. Luồng khác không gọi hàm sửa trạng thái
đó; chúng đẩy thông điệp (lệnh đã giải mã, kết quả DB) vào hộp thư của luồng sở hữu, luồng này rút
cả lô ở đầu tick. ✗ điển hình: luồng IO gọi `world.move(...)` dưới một `world_mutex` mà AI, chiến
đấu, AOI cũng phải lấy.

- **Vì sao:** chia sẻ trạng thái buộc mọi hệ thống lấy khoá: khoá chết, đảo ưu tiên, tick dao động.
  Hộp thư dồn toàn bộ đồng thời vào một lớp nhỏ test được dưới TSan; logic zone đơn luồng, tất
  định, không khoá.
- **Kiểm:** review: `std::mutex` ngoài lớp hàng đợi/dịch vụ dùng chung phải có lý do ghi bên cạnh.

```cpp
// ✓ Hộp thư MPSC có trần: luồng IO đẩy lệnh, luồng zone rút cả lô ở đầu tick.
#include <cstddef>
#include <mutex>
#include <utility>
#include <vector>

namespace game::conc {

// An toàn luồng: push từ mọi luồng; drain_into chỉ từ luồng sở hữu. Khoá chỉ bao push_back và
// swap; hai vector đổi vai nên khi capacity đã đủ thì không cấp phát.
template <class T>
class Mailbox {
public:
    explicit Mailbox(std::size_t capacity) noexcept : capacity_(capacity) {}

    // false: hộp thư đầy (áp lực ngược, DT-08); nơi gửi đếm rồi bỏ hoặc ngắt phiên.
    [[nodiscard]] bool push(T message) {
        const std::scoped_lock lock(mutex_);
        if (pending_.size() >= capacity_) return false;
        pending_.push_back(std::move(message));
        return true;
    }

    // Đầu ra tái dùng (ngoại lệ API-02): out bị xoá rồi nhận mọi thông điệp đang chờ, đúng thứ tự
    // đến; capacity cũ của out quay lại làm bộ đệm chờ.
    void drain_into(std::vector<T>& out) {
        out.clear();
        const std::scoped_lock lock(mutex_);
        pending_.swap(out);
    }

private:
    std::size_t capacity_ = 0;
    std::mutex mutex_;
    // Bảo vệ bởi mutex_.
    std::vector<T> pending_;
};

} // namespace game::conc
```

### DT-02 [N] CẤM — Tranh chấp dữ liệu: biến nhiều luồng chạm mà có luồng ghi phải là atomic hoặc cùng một mutex bảo vệ

Hai truy cập xung đột (cùng vị trí bộ nhớ, ít nhất một ghi) từ hai luồng, không có quan hệ
happens-before, không phải cả hai nguyên tử: UB của cả chương trình ([intro.races]). Không có "race
vô hại", kể cả `bool` hay `int` căn lề tự nhiên.

- **Vì sao:** trình dịch được giả định không có race: nó nâng phép đọc cờ ra khỏi vòng lặp (lặp vô
  hạn), xoá hẳn vòng chờ rỗng (vòng lặp không tác dụng phụ được giả định kết thúc), gộp hoặc bỏ phép
  ghi, xé giá trị 64 bit trên nền 32 bit. Lỗi chỉ hiện ở `-O2`, tải cao.
- **Kiểm:** TSan (DT-07); review mọi thành viên của kiểu dùng chung giữa luồng.

```cpp
// ✗ Cờ dừng là bool thường: -O2 (GCC 14, Clang 20) xoá hẳn vòng chờ — hàm trả ngay, không chờ gì.
struct Shutdown {
    bool requested = false;
};

inline void wait_for_shutdown(const Shutdown& shutdown) noexcept {
    while (!shutdown.requested) {
    }
}
```

```cpp
// ✓ Cờ nguyên tử với wait/notify: không race, không quay vòng đốt CPU.
#include <atomic>

namespace game::core {

class ShutdownSignal {
public:
    // release ghép với acquire trong wait(): mọi thứ ghi trước request() thấy được sau wait().
    void request() noexcept {
        requested_.store(true, std::memory_order_release);
        requested_.notify_all();
    }

    // Chặn ở OS (futex trên Linux) tới khi request(); trả ngay nếu đã request.
    void wait() const noexcept { requested_.wait(false, std::memory_order_acquire); }

private:
    std::atomic<bool> requested_{false};
};

} // namespace game::core
```

### DT-03 [N] PHẢI — Khoá bằng RAII, vùng khoá chỉ chạm bộ nhớ của lớp; không IO, log, callback hay tham chiếu thoát ra ngoài khoá

`std::scoped_lock` (mặc định) hoặc `std::unique_lock` (cho biến điều kiện); không `lock()`/`unlock()`
trần. Mutex là thành viên private cạnh dữ liệu, mỗi thành viên được bảo vệ ghi `// Bảo vệ bởi
mutex_.` ngay trên nó. Trong vùng khoá chỉ chép/swap dữ liệu; trả bản sao, không trả tham chiếu/con trỏ/view.

- **Vì sao:** `return` sớm giữa `lock`/`unlock` để mutex khoá mãi. IO dưới khoá (cỡ ms) tuần tự hoá
  mọi luồng chờ — tick trễ dây chuyền. Callback dưới khoá gọi ngược vào lớp (khoá lại `std::mutex`
  đang giữ là UB, thực tế treo) hoặc lấy khoá khác theo thứ tự ngược (DT-13). Tham chiếu thoát khoá
  là race dù mọi hàm đều "có khoá".
- **Kiểm:** grep `\.lock()`/`\.unlock()`; review vùng `scoped_lock`; Clang `-Wthread-safety` nếu dự
  án gắn annotation (libc++: `_LIBCPP_ENABLE_THREAD_SAFETY_ANNOTATIONS`); đếm chờ futex
  (`strace -f -c -e trace=futex`).

```cpp
// ✓ Chép danh sách dưới khoá (tái dùng scratch, không cấp phát); gửi ngoài khoá.
#include <concepts>
#include <cstdint>
#include <mutex>
#include <vector>

namespace game::chat {

// An toàn luồng.
class Channel {
public:
    // out là đầu ra tái dùng (API-02).
    void copy_members(std::vector<std::uint32_t>& out) const {
        const std::scoped_lock lock(mutex_);
        // gán chép giữ capacity của out
        out = members_;
    }

private:
    mutable std::mutex mutex_;
    // Bảo vệ bởi mutex_.
    std::vector<std::uint32_t> members_;
};

// send_one có thể chặn, ghi log, gọi lại Channel: đã ở ngoài khoá.
template <std::invocable<std::uint32_t> SendOne>
void broadcast(const Channel& channel, std::vector<std::uint32_t>& scratch, SendOne send_one) {
    channel.copy_members(scratch);
    for (const std::uint32_t session : scratch) {
        send_one(session);
    }
}

} // namespace game::chat
```

### DT-04 [N] PHẢI — Luồng là thành viên `std::jthread` khai báo cuối lớp, dừng bằng `stop_token`, chờ bằng biến điều kiện có vị từ; CẤM `detach()`, `std::thread` trần, `sleep_for` thăm dò

- **Vì sao:** `std::thread` còn joinable khi huỷ gọi `std::terminate`; luồng `detach` sống lâu hơn
  dữ liệu nó dùng (use-after-free lúc tắt máy chủ). `jthread` tự `request_stop()` + `join()`. Thành
  viên khởi tạo theo thứ tự khai báo, huỷ ngược lại: khai báo cuối thì luồng chạy khi mọi thành viên
  đã sẵn sàng và dừng trước khi chúng bị huỷ. `wait` không vị từ có thể thức giả — `front()` trên
  deque rỗng là UB. `condition_variable_any::wait(lock, stop_token, pred)` (C++20) thức ngay khi
  `request_stop()`; sau khi dừng nó trả `pred()`, nên worker dưới đây xả hết hàng rồi mới thoát.
- **Kiểm:** CI grep `\.detach()`, `std::thread\b`, `sleep_for` trong vòng chờ; TSan.

```cpp
// ✓ Worker DB: jthread khai báo cuối, chờ có vị từ + stop_token, notify ngoài khoá.
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <mutex>
#include <optional>
#include <stop_token>
#include <thread>

namespace game::db {

struct SaveJob {
    std::uint64_t character = 0;
    std::uint64_t version = 0;
};

// IO thật, định nghĩa ở .cpp; kết quả, kể cả lỗi, về zone qua hộp thư (LH-08).
void save(const SaveJob& job) noexcept;

// An toàn luồng.
class SaveWorker {
public:
    void push(const SaveJob& job) {
        {
            const std::scoped_lock lock(mutex_);
            jobs_.push_back(job);
        }
        // ngoài khoá: luồng vừa thức không va ngay vào khoá đang giữ
        ready_.notify_one();
    }

private:
    // nullopt: đã yêu cầu dừng và hàng rỗng.
    [[nodiscard]] std::optional<SaveJob> next(const std::stop_token& token) {
        std::unique_lock lock(mutex_);
        if (!ready_.wait(lock, token, [this] { return !jobs_.empty(); })) return std::nullopt;
        const SaveJob job = jobs_.front();
        jobs_.pop_front();
        return job;
    }

    void run(const std::stop_token& token) {
        for (std::optional<SaveJob> job = next(token); job.has_value(); job = next(token)) {
            save(*job);
        }
    }

    std::mutex mutex_;
    std::condition_variable_any ready_;
    // Bảo vệ bởi mutex_.
    std::deque<SaveJob> jobs_;
    // Khai báo cuối cùng; hàm vào luồng là noexcept (LH-08): ngoại lệ thoát ra là terminate.
    // NOLINTNEXTLINE(bugprone-exception-escape): dừng sớm có chủ ý ở đáy luồng (LH-08).
    std::jthread worker_{[this](const std::stop_token& token) noexcept { run(token); }};
};

} // namespace game::db
```

### DT-05 [N] PHẢI — Atomic chỉ cho một giá trị độc lập; đọc-rồi-ghi trên atomic là vòng CAS; bất biến nhiều biến dùng mutex

Cờ, bộ đếm, chỉ số: atomic. Bất biến giữa hai biến trở lên (hp và alive, số dư và nhật ký): cả nhóm
dưới một mutex, hoặc gói vào một word nguyên tử.

- **Vì sao:** mỗi thao tác atomic nguyên tử riêng lẻ; giữa `load` và `store` luồng khác chen vào —
  mất cập nhật. Hai atomic cập nhật lần lượt để lộ trạng thái nửa vời. TSan KHÔNG bắt lỗi này (mọi
  truy cập đều nguyên tử): chỉ review và lập luận bắt được (DT-19).
- **Kiểm:** review mẫu `if (x.load() …) x.store(…)` — ✗ điển hình: `if (online > peak.load())
  peak.store(online);` để hai luồng cùng qua phép so và đỉnh nhỏ hơn ghi đè đỉnh lớn hơn.

```cpp
// ✓ Vòng CAS. C++26 có fetch_max (P0493); C++23 và cả ba thư viện đã đo đều chưa có.
#include <atomic>
#include <cstdint>

namespace game::obs {

// relaxed: đỉnh là số liệu độc lập, không dùng để suy ra dữ liệu nào khác.
inline void record_online(std::atomic<std::int32_t>& peak, std::int32_t online) noexcept {
    std::int32_t seen = peak.load(std::memory_order_relaxed);
    // CAS thất bại nạp lại seen; dừng khi online không còn lớn hơn hoặc đã ghi được.
    while (seen < online && !peak.compare_exchange_weak(seen, online, std::memory_order_relaxed)) {
    }
}

} // namespace game::obs
```

### DT-06 [N] PHẢI — Mỗi kiểu dùng ở nhiều luồng ghi hợp đồng luồng; kiểu chỉ-luồng-sở-hữu tự kiểm luồng gọi ở bản debug

Comment đầu lớp ghi một trong ba: **an toàn luồng**; **chỉ luồng sở hữu** (kèm `ThreadOwner`);
**bất biến sau khởi tạo** (chỉ hàm const, chia sẻ bằng `shared_ptr<const T>`). Hàm `const` của mọi
kiểu phải gọi đồng thời được, như thư viện chuẩn hứa ([res.on.data.races]); cache `mutable` trong
hàm const phải đồng bộ.

- **Vì sao:** lỗi đồng thời phổ biến nhất là gọi kiểu đơn luồng từ sai luồng (callback DB chạm zone).
  Kiểm luồng gọi bắt nó ngay ở test, có stack, thay vì thành race hiếm ở production.
- **Kiểm:** review comment hợp đồng; chạy test với `GAME_DEBUG_CHECKS`.

```cpp
// ✓ Kiểu chỉ-luồng-sở-hữu: hàm công khai kiểm luồng gọi khi bật GAME_DEBUG_CHECKS.
#include "core/check.hpp"

#include <cstdint>
#include <thread>
#include <vector>

namespace game::world {

// Nhớ luồng tạo ra nó; rebind() khi giao quyền sở hữu có chủ đích (zone tạo ở luồng chính rồi
// giao cho luồng zone).
class ThreadOwner {
public:
    void rebind() noexcept { owner_ = std::this_thread::get_id(); }

    void check_owner() const noexcept {
        core::debug_check([this] { return owner_ == std::this_thread::get_id(); },
            "ThreadOwner::check_owner: phải gọi từ luồng sở hữu");
    }

private:
    std::thread::id owner_ = std::this_thread::get_id();
};

// Chỉ luồng sở hữu; luồng khác gửi lệnh qua hộp thư (DT-01).
class Zone {
public:
    void spawn(std::uint32_t template_id) {
        owner_.check_owner();
        entities_.push_back(template_id);
    }

private:
    ThreadOwner owner_;
    std::vector<std::uint32_t> entities_;
};

} // namespace game::world
```

### DT-07 [N] PHẢI — Code chạm nhiều luồng có test stress chạy dưới TSan trong CI; TSan sạch là điều kiện merge

Test ép giao thoa: 10⁴–10⁵ thao tác, hàng đợi dung lượng nhỏ để quay vòng và đầy liên tục, số luồng
≥ số lõi. TSan có preset riêng (không gộp được với ASan); không suppress khi chưa có lập luận ghi lại.

- **Vì sao:** race chỉ hiện ở một lịch chạy hiếm. TSan dựng happens-before theo mô hình bộ nhớ C++,
  không theo phần cứng, nên bắt được thiếu release/acquire ngay trên x86. Theo tài liệu TSan: chậm
  cỡ 5–15 lần, bộ nhớ 5–10 lần — chấp nhận được cho CI. Giới hạn của TSan: DT-19.
- **Kiểm:** job CI; mẫu `[tsan]` DT-14 là dạng test chuẩn.

```bash
cmake --preset clang-tsan && cmake --build --preset clang-tsan && ctest --preset clang-tsan
# Một tệp, cục bộ:
c++ -std=c++23 -O1 -g -fsanitize=thread -fno-omit-frame-pointer -pthread test_ring.cpp -o t
TSAN_OPTIONS="halt_on_error=1 second_deadlock_stack=1" ./t
```

## 2. Nâng cao [C]

### DT-08 [C] NÊN — Mô hình luồng máy chủ: một luồng mỗi zone, luồng IO riêng, pool DB; chỉ giao tiếp qua hàng đợi có giới hạn

Zone (hoặc nhóm zone) sở hữu trạng thái của nó trên một luồng và không bao giờ chờ IO hay DB đồng
bộ. Kết quả DB quay về bằng thông điệp vào hộp thư zone, không bằng callback chạy trên luồng DB.
Tổng luồng tính toán ≤ số lõi vật lý; mọi hàng đợi có dung lượng tối đa (áp lực ngược: refs/13 UB).

- **Vì sao:** zone đơn luồng thì logic không khoá và tất định (replay được: refs/18 MMO). Callback
  chạy trên luồng DB chạm zone là race kinh điển. Nhiều luồng hơn lõi gây chuyển ngữ cảnh làm vỡ
  ngân sách tick.
- **Kiểm:** sơ đồ luồng trong tài liệu kiến trúc (refs/17 KTR); `ThreadOwner` ở mọi kiểu của zone.

```text
socket ─► luồng IO (1–2): giải khung, kiểm cơ bản ─► SPSC/MPSC ─► hộp thư zone k
luồng zone k: rút hộp thư (có ngân sách) → hệ thống theo pha → gói ra ─► SPSC ─► luồng IO
                                                              └► job lưu ─► hàng DB (có giới hạn)
pool DB (M luồng): thực thi job ─► kết quả là thông điệp ─► hộp thư zone k
luồng log/metrics: nhận bản ghi qua hàng đợi; đầy thì bỏ và đếm, không bao giờ chặn zone
```

| Cạnh | Hàng đợi | Ghi chú |
|---|---|---|
| IO → zone | MPSC hộp thư, hoặc SPSC mỗi cặp (IO, zone) | SPSC lock-free khi đo thấy khoá tranh chấp (DT-14) |
| zone → IO | SPSC mỗi cặp | gói ra đã tuần tự hoá |
| zone → DB | MPMC có giới hạn | đầy: giữ cờ bẩn, thử lại tick sau |
| DB → zone | hộp thư zone | kết quả mang id yêu cầu |

### DT-09 [C] PHẢI — Thứ tự bộ nhớ mặc định `seq_cst`; hạ xuống theo bảng, và mỗi thao tác hạ cấp ghi tên thao tác ghép cặp

| Thứ tự | Dùng khi | Ví dụ |
|---|---|---|
| `seq_cst` (mặc định) | cần thứ tự toàn cục giữa ≥ 2 biến; mẫu "ghi biến mình rồi đọc biến kia" | DT-19 |
| `release` / `acquire` | công bố: ghi dữ liệu thường rồi bật cờ/chỉ số; bên kia đọc cờ rồi đọc dữ liệu | DT-14, DT-15 |
| `acq_rel` | RMW vừa nhận vừa công bố | `fetch_add` epoch (DT-17) |
| `relaxed` | giá trị độc lập; đọc lại chỉ số chính mình ghi | bộ đếm, DT-05 |
| `consume` | CẤM: không khuyến khích từ C++17 (P0371), trình dịch nâng thành `acquire` | — |

- **Vì sao:** release/acquire chỉ tạo synchronizes-with khi phép acquire đọc được giá trị do phép
  release (hoặc chuỗi RMW sau nó) ghi; thiếu một nửa cặp là race dù chạy đúng trên x86 (TSO: mọi
  load phần cứng đã là acquire) — lỗi lộ ra trên ARM hoặc khi trình dịch sắp xếp lại. Comment ghép
  cặp là bằng chứng review được. ✗ điển hình: ghi struct rồi `ready.store(true, relaxed)`.
- **Kiểm:** review: mỗi `memory_order_*` khác `seq_cst` có comment "(X) ghép với (Y)"; TSan.

```cpp
// ✓ Công bố một lần: (R) release ghép (A) acquire, ghi rõ trong comment.
#include "core/check.hpp"

#include <atomic>
#include <cstdint>
#include <optional>

namespace game::obs {

struct ZoneReport {
    std::uint32_t players = 0;
    std::uint32_t tick_p99_us = 0;
};

// An toàn luồng; publish đúng một lần (lần hai sẽ race với luồng đọc).
class ReportOnce {
public:
    void publish(const ZoneReport& report) noexcept {
        // Relaxed đủ: chỉ luồng ghi đọc cờ này ở đây để kiểm hợp đồng "công bố một lần"; không
        // ghép cặp với thao tác nào.
        core::check(!ready_.load(std::memory_order_relaxed), "ReportOnce::publish: chỉ gọi một lần");
        report_ = report;
        // (R): ghi report_ happens-before mọi (A) đọc được true.
        ready_.store(true, std::memory_order_release);
    }

    [[nodiscard]] std::optional<ZoneReport> try_get() const noexcept {
        // (A) ghép với (R)
        if (!ready_.load(std::memory_order_acquire)) return std::nullopt;
        return report_;
    }

private:
    ZoneReport report_;
    std::atomic<bool> ready_{false};
};

} // namespace game::obs
```

### DT-10 [C] PHẢI — Dữ liệu do các luồng khác nhau ghi nằm trên các dòng cache khác nhau

Atomic nóng, chỉ số hai phía của hàng đợi, bộ đếm theo luồng: mỗi thứ `alignas(kCacheLine)` riêng,
kèm `static_assert(sizeof …)`. Hằng `kCacheLine` do dự án định nghĩa, không dùng
`std::hardware_destructive_interference_size`: refs/10 BN-08. Dùng 128 thay 64 cho cặp biến nóng
nhất khi đo thấy lợi (prefetch cặp dòng kề của Intel).

- **Vì sao:** hai lõi ghi hai biến khác nhau trên cùng dòng cache làm dòng chuyền qua lại (false
  sharing): mỗi lần ghi tốn một lần chuyển dòng giữa hai lõi — hàng chục tới hàng trăm ns tuỳ
  khoảng cách lõi/socket — thay vì vài ns. Ô của một người ghi duy nhất còn bỏ được lệnh RMW có tiền
  tố `lock`: `load` + `store` relaxed thay `fetch_add`.
- **Kiểm:** `static_assert`; `perf c2c` chỉ ra dòng HITM (refs/10 BN).

```cpp
// ✓ Bộ đếm theo luồng: mỗi ô một dòng cache, mỗi luồng chỉ ghi ô của mình.
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace game::conc {

inline constexpr std::size_t kCacheLine = 64;

enum class ThreadSlot : std::uint32_t {};

struct alignas(kCacheLine) CounterCell {
    std::atomic<std::uint64_t> value{0};
};
static_assert(sizeof(CounterCell) == kCacheLine);

// An toàn luồng, với điều kiện ô `slot` chỉ do một luồng ghi.
template <std::size_t Threads>
class PerThreadCounter {
public:
    // Một người ghi mỗi ô: load + store relaxed, tránh RMW nguyên tử (`lock add` trên x86).
    void add(ThreadSlot slot, std::uint64_t amount) noexcept {
        // slot ngoài miền là lỗi lập trình: .at() trong hàm noexcept thành dừng tiến trình (LH-07).
        // NOLINTNEXTLINE(bugprone-exception-escape)
        std::atomic<std::uint64_t>& cell = cells_.at(std::to_underlying(slot)).value;
        cell.store(cell.load(std::memory_order_relaxed) + amount, std::memory_order_relaxed);
    }

    // Các ô đọc ở các thời điểm khác nhau: tổng là ước lượng, đủ cho giám sát.
    [[nodiscard]] std::uint64_t total() const noexcept {
        std::uint64_t sum = 0;
        for (const CounterCell& cell : cells_) {
            sum += cell.value.load(std::memory_order_relaxed);
        }
        return sum;
    }

private:
    std::array<CounterCell, Threads> cells_{};
};

} // namespace game::conc
```

### DT-11 [C] NÊN — Pha song song trong tick dùng `std::barrier` (lặp) hay `std::latch` (một lần), không tự ghép mutex + biến điều kiện

Mỗi pha: worker đọc bộ đệm hiện tại, ghi lát riêng của bộ đệm kế; hàm hoàn tất của barrier đổi hai
bộ đệm. `std::latch` cho việc một lần (chờ mọi zone nạp xong rồi mới mở cổng đăng nhập).

- **Vì sao:** chuẩn bảo đảm ([thread.barrier.class]): mọi `arrive` của một pha strongly happen
  before bước hoàn tất; bước hoàn tất strongly happens before các lời gọi được nó giải phóng trả về.
  Ghi của pha này thấy được ở pha sau mà không cần atomic nào. Hàm hoàn tất phải `noexcept`
  (chuẩn đòi `is_nothrow_invocable`).
- **Kiểm:** TSan; test so kết quả song song với bản một luồng (refs/15 KT).

```cpp
// ✓ Hàm hoàn tất của barrier đổi bộ đệm đôi đúng một lần mỗi pha.
#include <algorithm>
#include <barrier>
#include <cstddef>
#include <cstdint>
#include <span>
#include <utility>
#include <vector>

namespace game::sim {

struct Heat {
    // chỉ đọc trong pha
    std::vector<std::int32_t> current;
    // mỗi worker ghi lát riêng, không chồng nhau
    std::vector<std::int32_t> next;
};

struct SwapBuffers {
    Heat* heat = nullptr;
    void operator()() const noexcept { std::swap(heat->current, heat->next); }
};

// Lát [begin, begin + count); các worker giữ các lát rời nhau, nằm trong cả hai bộ đệm.
struct Slice {
    std::size_t begin = 0;
    std::size_t count = 0;
};

// Lát slice của next tính từ current.
inline void cool_slice(Heat& heat, Slice slice) noexcept {
    const auto from = std::span(heat.current).subspan(slice.begin, slice.count);
    const auto into = std::span(heat.next).subspan(slice.begin, slice.count);
    std::ranges::transform(from, into.begin(), [](std::int32_t value) { return value / 2; });
}

inline void run_phases(std::barrier<SwapBuffers>& sync, Heat& heat, Slice slice, std::int32_t phases) {
    for (std::int32_t phase = 0; phase < phases; ++phase) {
        cool_slice(heat, slice);
        sync.arrive_and_wait();
    }
}

} // namespace game::sim
```

### DT-12 [C] NÊN — Cấu hình nóng là ảnh chụp bất biến `shared_ptr<const T>` thay nguyên khối; zone đổi ảnh chụp ở ranh giới tick

Người đọc lấy một `shared_ptr<const Config>` và dùng suốt tick; người ghi dựng bản mới, kiểm hợp
lệ, rồi thay con trỏ. Tốt nhất: gửi bản mới vào hộp thư zone, zone đổi ở đầu tick (refs/17 KTR).

- **Vì sao:** sửa từng trường tại chỗ để luồng đọc thấy cấu hình nửa cũ nửa mới. Đã đo:
  `std::atomic<std::shared_ptr<T>>` có ở libstdc++ 14/15 nhưng `is_lock_free()` là `false` (khoá
  nội bộ); libc++ 20 KHÔNG có (`__cpp_lib_atomic_shared_ptr` chưa định nghĩa). Mã khả chuyển dùng
  mutex với vùng khoá chỉ là phép chép con trỏ. `std::shared_mutex` không rẻ hơn ở đây: khoá đọc
  vẫn là một RMW trên dòng cache chung.
- **Kiểm:** TSan với một luồng đổi cấu hình liên tục khi luồng khác đọc.

```cpp
// ✓ Ô ảnh chụp khả chuyển (libstdc++ và libc++): khoá chỉ bao phép chép/đổi shared_ptr.
#include <memory>
#include <mutex>
#include <utility>

namespace game::config {

// An toàn luồng. Bản cũ bị huỷ ngoài khoá, ở luồng nhả tham chiếu cuối cùng.
template <class T>
class SnapshotCell {
public:
    explicit SnapshotCell(std::shared_ptr<const T> initial) : current_(std::move(initial)) {}

    [[nodiscard]] std::shared_ptr<const T> load() const {
        const std::scoped_lock lock(mutex_);
        return current_;
    }

    // next nhận bản cũ qua swap; tham số bị huỷ sau khi lock đã nhả.
    void store(std::shared_ptr<const T> next) {
        const std::scoped_lock lock(mutex_);
        current_.swap(next);
    }

private:
    mutable std::mutex mutex_;
    // Bảo vệ bởi mutex_.
    std::shared_ptr<const T> current_;
};

} // namespace game::config
```

### DT-13 [C] PHẢI — Lấy nhiều mutex cùng lúc bằng một `std::scoped_lock(a, b)`; khoá lấy lần lượt phải theo thứ bậc ghi trong tài liệu

- **Vì sao:** hai giao dịch ngược chiều (A→B và B→A), mỗi bên giữ một khoá chờ khoá kia: khoá chết
  ABBA. `scoped_lock` nhiều đối số dùng thuật toán tránh khoá chết của `std::lock`. Khi buộc phải lấy
  lần lượt (qua lời gọi hàm), mỗi mutex có cấp và chỉ lấy mutex cấp thấp hơn mutex đang giữ. Khoá
  cùng một `std::mutex` hai lần là UB — chặn hai đối số trùng nhau trước khi khoá.
- **Kiểm:** TSan báo lock-order-inversion cả khi lần chạy đó không khoá chết; review cấp khoá.

```cpp
// ✓ Kho bang hội: một scoped_lock cho cả hai; chặn tự chuyển cho chính mình.
#include <cstdint>
#include <mutex>

namespace game::econ {

struct Vault {
    std::mutex mutex;
    // Bảo vệ bởi mutex.
    std::int64_t copper = 0;
};

// amount > 0; số dư không âm (kiểm tràn tiền tệ: refs/18 MMO).
[[nodiscard]] inline bool transfer(Vault& source, Vault& target, std::int64_t amount) {
    if (&source == &target || amount <= 0) return false;
    const std::scoped_lock lock(source.mutex, target.mutex);
    if (source.copper < amount) return false;
    source.copper -= amount;
    target.copper += amount;
    return true;
}

} // namespace game::econ
```

## 3. Thần thoại [T]

### DT-14 [T] CÓ THỂ — Ring buffer SPSC lock-free: chỉ số 64 bit đơn điệu, release/acquire ghép cặp, bản sao chỉ số phía kia, mỗi phía một dòng cache

Chỉ khi đo thấy hộp thư có khoá (DT-01) là nút thắt. Đúng một producer, một consumer (`ThreadOwner`
ở mỗi phía, DT-06); dung lượng luỹ thừa 2; `T` sao chép tầm thường.

- **Vì sao:** mỗi thao tác một load relaxed chỉ số của mình và một store release; chỉ số phía kia
  chỉ đọc lại khi bản sao báo đầy/rỗng, nên ở trạng thái ổn định hai lõi gần như không chạm dòng
  cache của nhau. Chứng minh, theo nhãn trong code:
  - (P) ghi ô rồi store-release `tail_`. (C2) load-acquire `tail_` đọc được giá trị ≥ tail + 1 thì
    synchronizes-with store đã ghi giá trị đó, store này đứng sau lần ghi ô trong cùng luồng: ghi ô
    happens-before đọc ô — không race, thấy đúng giá trị.
  - (C) đọc ô rồi store-release `head_`; (P2) load-acquire `head_` ghép với (C): đọc ô cũ
    happens-before lần ghi đè ô đó. Thiếu cặp này là race ghi-sau-đọc (TSan báo).
  - Mỗi chỉ số một người ghi nên tự đọc lại bằng relaxed là đủ (coherence). Chỉ số 64 bit không
    tràn trong đời máy chủ, `tail - head` luôn là số phần tử: không cần ô canh.
  - Chỉ số đã mask luôn < Capacity: dùng `operator[]` kèm NOLINT có lý do. (`at()` cũng bị
    GCC 14/Clang 20 xoá kiểm ở `-O2` — đã xem asm — nhưng `at()` có thể ném trong hàm `noexcept`.)
- **Kiểm:** mẫu `[tsan]` dưới là test bảo vệ: FIFO tuyệt đối, dung lượng 256 quay vòng ~400 lần;
  benchmark so với `Mailbox` trước khi thay.

```cpp
// ✓ [tsan] Ring SPSC lock-free: luồng IO đẩy, luồng zone rút; kiểm FIFO dưới ThreadSanitizer.
#include "core/check.hpp"

#include <array>
#include <atomic>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <thread>
#include <type_traits>

namespace game::conc {

inline constexpr std::size_t kCacheLine = 64;

// Một producer, một consumer. Ô = chỉ số & (Capacity - 1); đầy khi tail - head == Capacity.
// NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index): chỉ số đã mask (DT-14).
template <class T, std::size_t Capacity>
    requires std::is_trivially_copyable_v<T> && (std::has_single_bit(Capacity))
class SpscRing {
public:
    // Chỉ luồng producer.
    [[nodiscard]] bool try_push(const T& value) noexcept {
        // chỉ ta ghi tail_
        const std::uint64_t tail = tail_.load(std::memory_order_relaxed);
        if (full(tail)) return false;
        slots_[tail & kMask] = value;
        // (P)
        tail_.store(tail + 1, std::memory_order_release);
        return true;
    }

    // Chỉ luồng consumer.
    [[nodiscard]] std::optional<T> try_pop() noexcept {
        // chỉ ta ghi head_
        const std::uint64_t head = head_.load(std::memory_order_relaxed);
        if (empty(head)) return std::nullopt;
        const std::optional<T> value = slots_[head & kMask];
        // (C)
        head_.store(head + 1, std::memory_order_release);
        return value;
    }

private:
    static constexpr std::uint64_t kMask = Capacity - 1;

    [[nodiscard]] bool full(std::uint64_t tail) noexcept {
        if (tail - head_cache_ < Capacity) return false;
        // (P2) ghép với (C)
        head_cache_ = head_.load(std::memory_order_acquire);
        return tail - head_cache_ == Capacity;
    }

    [[nodiscard]] bool empty(std::uint64_t head) noexcept {
        if (head != tail_cache_) return false;
        // (C2) ghép với (P)
        tail_cache_ = tail_.load(std::memory_order_acquire);
        return head == tail_cache_;
    }

    // Dòng 1: producer ghi. Dòng 2: consumer ghi. Từ dòng 3: các ô.
    alignas(kCacheLine) std::atomic<std::uint64_t> tail_{0};
    // riêng producer
    std::uint64_t head_cache_ = 0;
    alignas(kCacheLine) std::atomic<std::uint64_t> head_{0};
    // riêng consumer
    std::uint64_t tail_cache_ = 0;
    alignas(kCacheLine) std::array<T, Capacity> slots_{};
};
// NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)

} // namespace game::conc

namespace {

using Ring = game::conc::SpscRing<std::uint64_t, 256>;
constexpr std::uint64_t kMessages = 100'000;

// Đầy là áp lực ngược bình thường: nhường CPU rồi thử lại.
void push_blocking(Ring& ring, std::uint64_t value) noexcept {
    while (!ring.try_push(value)) {
        std::this_thread::yield();
    }
}

[[nodiscard]] std::uint64_t pop_blocking(Ring& ring) noexcept {
    std::optional<std::uint64_t> value = ring.try_pop();
    while (!value.has_value()) {
        std::this_thread::yield();
        value = ring.try_pop();
    }
    return *value;
}

void produce(Ring& ring) noexcept {
    for (std::uint64_t i = 1; i <= kMessages; ++i) {
        push_blocking(ring, i);
    }
}

} // namespace

int main() {
    Ring ring;
    const std::jthread producer([&ring] noexcept { produce(ring); });
    // FIFO tuyệt đối: phần tử thứ i phải là i (mất, lặp, đảo thứ tự đều bị bắt).
    for (std::uint64_t i = 1; i <= kMessages; ++i) {
        game::core::check(pop_blocking(ring) == i, "SPSC mất, lặp hoặc đảo thứ tự");
    }
    return 0;
}
```

### DT-15 [T] CÓ THỂ — Seqlock đúng mô hình bộ nhớ: dữ liệu là các word nguyên tử, ghi release và đọc acquire

Một writer (luồng zone), nhiều reader không bao giờ chặn writer: vị trí cuối của người chơi cho luồng
giám sát, bảng xếp hạng. Seqlock "kinh điển" chép struct thường giữa hai lần đọc `seq` là tranh chấp
dữ liệu — UB dù bản đọc hỏng bị bỏ đi.

- **Vì sao:** (1) Reader đọc được một word của lần ghi W đang dở: word-acquire đồng bộ với
  word-release của W; store `seq` lẻ của W đứng trước nó trong cùng luồng nên happens-before phép đọc
  `after`; theo write-read coherence `after` ≠ `before` — bản đọc bị bỏ. (2) `before` đọc `seq` chẵn
  cuối của W0 (release): mọi word của W0 happens-before các phép đọc word, không đọc được giá trị cũ
  hơn. (3) `after` relaxed vẫn đúng: acquire của các word chặn nó vượt lên trước. Trên x86
  load-acquire/store-release là `mov` thường — không tốn thêm. Trên ARM mỗi word tốn LDAR/STLR;
  biến thể fence (H. Boehm, "Can Seqlocks Get Along with Programming Language Memory Models?", 2012)
  rẻ hơn ở đó nhưng TSan không kiểm được fence (DT-19).
- **Kiểm:** test hai luồng: mọi bản đọc thành công nhất quán (ghi ba trường cùng giá trị), không
  lùi — chạy trên ARM64; TSan ở đây không chứng minh thêm gì vì mọi truy cập đều nguyên tử (DT-19).

```cpp
// ✓ Seqlock một writer: luồng zone công bố vị trí, luồng khác đọc không chặn.
#include <array>
#include <atomic>
#include <bit>
#include <cstdint>
#include <optional>

namespace game::world {

// Mốc thời gian game: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

// 16 byte, không byte đệm: bit_cast sang hai word không mang bit bất định.
struct PositionSample {
    std::int32_t x = 0;
    std::int32_t y = 0;
    Tick tick{};
};

class PositionSeqlock {
public:
    using Words = std::array<std::uint64_t, 2>;

    // Chỉ một luồng ghi: seq lẻ → các word (release) → seq chẵn (release).
    void write(const PositionSample& sample) noexcept {
        const std::uint64_t seq = seq_.load(std::memory_order_relaxed);
        seq_.store(seq + 1, std::memory_order_relaxed);
        const auto words = std::bit_cast<Words>(sample);
        words_[0].store(words[0], std::memory_order_release);
        words_[1].store(words[1], std::memory_order_release);
        seq_.store(seq + 2, std::memory_order_release);
    }

    // nullopt: đang ghi dở, gọi lại.
    [[nodiscard]] std::optional<PositionSample> try_read() const noexcept {
        const std::uint64_t before = seq_.load(std::memory_order_acquire);
        const Words words{words_[0].load(std::memory_order_acquire), words_[1].load(std::memory_order_acquire)};
        const std::uint64_t after = seq_.load(std::memory_order_relaxed);
        if (before != after || (before & 1U) != 0) return std::nullopt;
        return std::bit_cast<PositionSample>(words);
    }

private:
    std::atomic<std::uint64_t> seq_{0};
    std::array<std::atomic<std::uint64_t>, 2> words_{};
};
static_assert(sizeof(PositionSample) == sizeof(PositionSeqlock::Words));

} // namespace game::world
```

### DT-16 [T] PHẢI — CAS trên chỉ số hay con trỏ phải chặn ABA bằng thẻ đóng gói cùng chỉ số trong một word 64 bit

Free list chỉ số (pool thực thể, pool buffer gói tin): `head = (thẻ 32 bit << 32) | chỉ số`, mỗi CAS
thành công tăng thẻ. Không dựa vào CAS 128 bit.

- **Vì sao:** luồng T đọc head = i, next(i) = j rồi bị trì hoãn; luồng khác pop i, pop j, push i;
  CAS của T vẫn thấy head = i và đặt j (đang được dùng) làm đỉnh — hỏng danh sách. Có thẻ thì head
  đã là (i, t + 3): CAS thất bại. Đã đo: `std::atomic<16 byte>::is_always_lock_free` là `false` ở
  GCC 14/15 và Clang 20 (không `-mcx16`; đi qua libatomic). `next_` phải là atomic: luồng chậm có
  thể đọc next(i) đúng lúc luồng khác ghi nó — giá trị cũ chỉ làm CAS thất bại. Load head và
  CAS-thất-bại của pop phải acquire để next(i) đọc ra là giá trị người push i ghi trước CAS release
  của họ (mọi ghi vào head đều là RMW nên chuỗi release không đứt). Thẻ quay vòng sau 2^32 CAS trong
  lúc một luồng bị trì hoãn: chấp nhận, ghi rõ.
- **Kiểm:** test `[tsan]` dạng DT-14: hai luồng pop/push 2×20 000 vòng, cuối cùng đủ mọi ô, không trùng.

```cpp
// ✓ Free list chỉ số lock-free: thẻ 32 bit cùng chỉ số trong một atomic 64 bit chặn ABA.
#include <array>
#include <atomic>
#include <cstdint>
#include <optional>

namespace game::mem {

// Ngăn xếp Treiber trên chỉ số [0, Capacity); kNone = Capacity là rỗng. An toàn luồng.
// NOLINTBEGIN(cppcoreguidelines-pro-bounds-constant-array-index): chỉ số < Capacity (DT-16).
template <std::uint32_t Capacity>
class IndexFreeList {
public:
    IndexFreeList() noexcept {
        for (std::uint32_t i = 0; i < Capacity; ++i) {
            // ô cuối trỏ kNone
            next_[i].store(i + 1, std::memory_order_relaxed);
        }
    }

    [[nodiscard]] std::optional<std::uint32_t> pop() noexcept {
        std::uint64_t seen = head_.load(std::memory_order_acquire);
        while (index_of(seen) != kNone && !try_unlink(seen)) {
        }
        if (index_of(seen) == kNone) return std::nullopt;
        return index_of(seen);
    }

    // index < Capacity và đang do nơi gọi giữ (đã pop, chưa push lại).
    void push(std::uint32_t index) noexcept {
        std::uint64_t seen = head_.load(std::memory_order_relaxed);
        next_[index].store(index_of(seen), std::memory_order_relaxed);
        while (!try_link(index, seen)) {
            next_[index].store(index_of(seen), std::memory_order_relaxed);
        }
    }

private:
    static constexpr std::uint32_t kNone = Capacity;

    [[nodiscard]] static constexpr std::uint64_t pack(std::uint32_t index, std::uint32_t tag) noexcept {
        return (std::uint64_t{tag} << 32U) | index;
    }
    [[nodiscard]] static constexpr std::uint32_t index_of(std::uint64_t head) noexcept {
        return static_cast<std::uint32_t>(head);
    }
    [[nodiscard]] static constexpr std::uint32_t tag_of(std::uint64_t head) noexcept {
        return static_cast<std::uint32_t>(head >> 32U);
    }
    [[nodiscard]] std::uint64_t successor(std::uint64_t head) const noexcept {
        return pack(next_[index_of(head)].load(std::memory_order_relaxed), tag_of(head) + 1U);
    }
    // Một lần CAS gỡ đỉnh seen (seen không rỗng); thất bại thì seen nhận đỉnh hiện tại, đọc acquire.
    [[nodiscard]] bool try_unlink(std::uint64_t& seen) noexcept {
        const std::uint64_t unlinked = successor(seen);
        return head_.compare_exchange_weak(seen, unlinked, std::memory_order_acquire);
    }
    // Một lần CAS đặt index lên trên đỉnh seen; thất bại thì seen nhận đỉnh hiện tại.
    // release: next_[index] và dữ liệu ô happens-before người pop thấy head mới.
    [[nodiscard]] bool try_link(std::uint32_t index, std::uint64_t& seen) noexcept {
        const std::uint64_t linked = pack(index, tag_of(seen) + 1U);
        return head_.compare_exchange_weak(seen, linked, std::memory_order_release, std::memory_order_relaxed);
    }

    std::atomic<std::uint64_t> head_{pack(0, 0)};
    std::array<std::atomic<std::uint32_t>, Capacity> next_{};
};
// NOLINTEND(cppcoreguidelines-pro-bounds-constant-array-index)

} // namespace game::mem
```

### DT-17 [T] NÊN — Thu hồi bộ nhớ cho người đọc không khoá: QSBR theo ranh giới tick (`std::rcu`, `std::hazard_pointer` là C++26)

Đối tượng vừa gỡ khỏi chỗ công bố chưa được huỷ ngay: reader khác có thể đang giữ con trỏ. C++26
thêm `std::rcu` (P2545) và `std::hazard_pointer` (P2530); C++23 và cả ba thư viện đã đo đều chưa có
(`__cpp_lib_rcu`, `__cpp_lib_hazard_pointer` không định nghĩa). Máy chủ game có sẵn trạng thái tĩnh:
cuối mỗi tick luồng zone không giữ con trỏ nào — dùng QSBR (một dạng epoch-based reclamation).

- **Vì sao:** (1) Reader báo `seen = epoch` (release) ở cuối tick. Writer công bố bản mới
  (release), `fetch_add` epoch (acq_rel) thành e, gắn e cho bản cũ. (2) Reader có `seen ≥ e` đã đọc
  epoch ≥ e bằng acquire, nên phép công bố happens-before mọi `read()` sau đó: không còn thấy bản cũ.
  (3) Mọi lần reader dùng bản cũ đứng trước store `seen` (release); writer đọc `seen` bằng acquire rồi
  mới huỷ: dùng happens-before huỷ. Tập reader cố định, đăng ký trước lần thay đầu tiên, không có
  trạng thái "offline": thêm offline thì phép vào/ra phải `seq_cst` vì đó là mẫu ghi-rồi-đọc (DT-19).
- **Kiểm:** test TSan đổi bản liên tục khi reader đọc; ASan bắt use-after-free nếu lập luận sai.

```cpp
// ✓ QSBR: bản cũ chỉ bị huỷ khi mọi reader đã qua một ranh giới tick sau lúc nó bị gỡ.
#include <algorithm>
#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <ranges>
#include <utility>
#include <vector>

namespace game::conc {

inline constexpr std::size_t kCacheLine = 64;

struct alignas(kCacheLine) ReaderEpoch {
    std::atomic<std::uint64_t> seen{0};
};

template <class T, std::size_t Readers>
    requires(Readers > 0)
class QsbrCell {
public:
    explicit QsbrCell(std::unique_ptr<const T> initial) : owned_(std::move(initial)), published_(owned_.get()) {}

    // Reader: con trỏ hợp lệ tới lần quiescent() kế của chính reader đó.
    [[nodiscard]] const T* read() const noexcept { return published_.load(std::memory_order_acquire); }

    // Reader, cuối tick, không còn giữ con trỏ nào.
    void quiescent(std::size_t reader) noexcept {
        const std::uint64_t epoch = epoch_.load(std::memory_order_acquire);
        // reader ngoài miền là lỗi lập trình: .at() trong hàm noexcept thành dừng (LH-07).
        // NOLINTNEXTLINE(bugprone-exception-escape)
        slots_.at(reader).seen.store(epoch, std::memory_order_release);
    }

    // Chỉ luồng writer.
    void replace(std::unique_ptr<const T> next) {
        published_.store(next.get(), std::memory_order_release);
        const std::uint64_t epoch = epoch_.fetch_add(1, std::memory_order_acq_rel) + 1;
        retired_.push_back({.epoch = epoch, .object = std::exchange(owned_, std::move(next))});
        const std::uint64_t safe = oldest_seen();
        std::erase_if(retired_, [safe](const Retired& item) { return item.epoch <= safe; });
    }

private:
    struct Retired {
        std::uint64_t epoch = 0;
        std::unique_ptr<const T> object;
    };

    // acquire ghép với release của quiescent(): mọi lần đọc bản cũ happens-before lần huỷ.
    [[nodiscard]] std::uint64_t oldest_seen() const noexcept {
        const auto seen_of = [](const ReaderEpoch& slot) { return slot.seen.load(std::memory_order_acquire); };
        return std::ranges::min(slots_ | std::views::transform(seen_of));
    }

    // riêng writer
    std::unique_ptr<const T> owned_;
    // không sở hữu; reader đọc
    std::atomic<const T*> published_;
    std::atomic<std::uint64_t> epoch_{0};
    std::array<ReaderEpoch, Readers> slots_{};
    // riêng writer
    std::vector<Retired> retired_;
};

} // namespace game::conc
```

### DT-18 [T] CẤM — `volatile` để đồng bộ; chờ bận chỉ khi đo thấy chờ rất ngắn, luôn có `pause` và giới hạn trước khi nhường OS

- **Vì sao:** `volatile` không nguyên tử, không tạo thứ tự với truy cập thường, không tạo
  happens-before: vẫn là tranh chấp dữ liệu. Spin không `pause` chiếm tài nguyên của luồng anh em
  trên cùng lõi (SMT) và chịu phạt xoá pipeline (memory-order machine clear) khi thoát vòng. Độ trễ
  `pause` khác nhau nhiều giữa các thế hệ CPU (Intel tăng lên cỡ trăm chu kỳ từ Skylake) nên số vòng
  phải đo trên máy đích. ✗ điển hình: `volatile bool ready` bảo vệ một `payload` thường.
- **Kiểm:** grep `volatile` (chỉ hợp lệ cho MMIO, `setjmp`, tín hiệu: refs/13 UB); review mọi vòng spin.

```cpp
// ✓ [x86] Spin có giới hạn với _mm_pause, rồi atomic::wait (futex): không bao giờ quay vô hạn.
#include <atomic>
#include <cstdint>

#include <immintrin.h>

namespace game::conc {

// Số vòng lấy từ đo đạc trên máy đích; quá ngưỡng đó chờ OS rẻ hơn.
inline constexpr std::int32_t kSpinLimit = 64;

// Trả khi word khác old; acquire ghép với store-release (+ notify) của luồng ghi.
inline void wait_until_changed(const std::atomic<std::uint32_t>& word, std::uint32_t old) noexcept {
    for (std::int32_t spin = 0; spin < kSpinLimit && word.load(std::memory_order_acquire) == old; ++spin) {
        _mm_pause();
    }
    // trả ngay nếu đã đổi
    word.wait(old, std::memory_order_acquire);
}

} // namespace game::conc
```

### DT-19 [T] PHẢI — Lập luận happens-before thành văn cho mọi thứ tự yếu hơn `seq_cst`; biết chỗ TSan mù

TSan chỉ thấy race trên truy cập **không nguyên tử** trong **lịch chạy thật**. Nó mù với: (1) lỗi
thứ tự giữa các atomic với nhau; (2) sắp xếp lại của phần cứng — nó không mô phỏng store buffer;
(3) `std::atomic_thread_fence` độc lập — đã đo: GCC 14/15 cảnh báo `-Wtsan` ("not supported with
-fsanitize=thread", thành lỗi dưới `-Werror`), Clang 20 TSan báo dương tính giả với mẫu fence
release/acquire đúng. Nên: đặt thứ tự lên chính thao tác atomic thay vì fence; mẫu "mỗi bên ghi
biến mình rồi đọc biến kia" (Dekker, store buffering) dùng `seq_cst` cho cả bốn thao tác.

- **Vì sao:** release/acquire không cấm "store rồi load biến khác" đổi chỗ (StoreLoad); x86 làm
  đúng điều đó qua store buffer. Chỉ `seq_cst` đặt các thao tác vào một thứ tự toàn cục S: một trong
  hai store đứng trước load của bên kia trong S, nên ít nhất một bên thấy bên kia. Trên x86 store
  `seq_cst` là `xchg` (hoặc `mov` + `mfence`), load `seq_cst` vẫn là `mov`.
- **Kiểm:** review lập luận (S, synchronizes-with, coherence) trong comment; stress test trên ARM64
  khi có; TSan vẫn chạy cho phần truy cập thường. ✗ điển hình: cùng lớp dưới đây nhưng store
  `release`, load `acquire` — cả hai load được phép đọc `false`: dùng và thu hồi cùng lúc.

```cpp
// ✓ Cả bốn thao tác seq_cst: thứ tự toàn cục S cấm kết cục "cả hai cùng thắng".
#include <atomic>

namespace game::conc {

// Một luồng dùng, một luồng thu hồi. try_retire() trả true thì try_use() sau đó thấy retiring_:
// load in_use_ đọc false nên đứng trước store in_use_ trong S, mà store retiring_ đứng trước nó.
class UseOrRetire {
public:
    [[nodiscard]] bool try_use() noexcept {
        in_use_.store(true, std::memory_order_seq_cst);
        if (!retiring_.load(std::memory_order_seq_cst)) return true;
        // rút lui; bên thu hồi thử lại sau
        in_use_.store(false, std::memory_order_release);
        return false;
    }

    [[nodiscard]] bool try_retire() noexcept {
        retiring_.store(true, std::memory_order_seq_cst);
        return !in_use_.load(std::memory_order_seq_cst);
    }

    // release: mọi lần dùng tài nguyên happens-before bên thu hồi đọc được false.
    void finish_use() noexcept { in_use_.store(false, std::memory_order_release); }

private:
    std::atomic<bool> in_use_{false};
    std::atomic<bool> retiring_{false};
};

} // namespace game::conc
```

## Kiểm nhanh

- [ ] Mỗi dữ liệu khả biến có đúng một luồng sở hữu; luồng khác chỉ gửi thông điệp? (DT-01, DT-08)
- [ ] Mọi biến chia sẻ có ghi là atomic hoặc dưới cùng một mutex; không `volatile`? (DT-02, DT-18)
- [ ] Khoá RAII; vùng khoá không IO/log/callback; không tham chiếu thoát khoá? (DT-03)
- [ ] Luồng là `jthread` khai báo cuối lớp; chờ có vị từ + `stop_token`; không `detach`? (DT-04)
- [ ] Đọc-rồi-ghi trên atomic là CAS; bất biến nhiều biến dưới mutex? (DT-05)
- [ ] Lớp dùng ở nhiều luồng ghi hợp đồng luồng; kiểu chỉ-luồng-sở-hữu có `ThreadOwner`? (DT-06)
- [ ] Mỗi `memory_order` khác `seq_cst` có comment ghép cặp; không `consume`, không fence trần? (DT-09, DT-19)
- [ ] Atomic nóng của các luồng khác nhau ở dòng cache khác nhau, có `static_assert`? (DT-10)
- [ ] Nhiều mutex lấy bằng một `scoped_lock`, chặn hai đối số trùng? (DT-13)
- [ ] Lock-free có thẻ chống ABA, có chiến lược thu hồi, có test `[tsan]`? (DT-14–DT-17)
- [ ] Code đa luồng có test stress dưới TSan trong CI? (DT-07)
