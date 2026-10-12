# HN · Hiệu năng: đo, thuật toán, cấp phát, cờ biên dịch

> **Phạm vi:** đo và benchmark, độ phức tạp, cấp phát và sao chép trên đường nóng, gọi gián tiếp,
> log, ngân sách tick, `inline`, cờ hiệu năng (-O, -march, LTO, PGO, BOLT), thuộc tính gợi ý, asm/perf,
> giảm sức mạnh phép tính, độ trễ đuôi. **Đọc khi:** viết/sửa code chạy mỗi tick, mỗi thực thể, mỗi
> gói tin; review PR "tối ưu"; chọn cờ phát hành; tick vượt ngân sách, p99 tăng; định thêm
> `[[likely]]`, `always_inline`, `target_clones`; thấy `std::function`, `shared_ptr`, `virtual`, map
> khoá chuỗi trong vòng lặp tick.
> **Liên quan:** refs/10-bo-nho-cache-dod.md (BN), refs/11-simd-vi-kien-truc.md (SV),
> refs/15-kiem-thu.md (KT-13 — code harness benchmark), refs/14-build-toolchain.md (BD — cờ cảnh
> báo, hardening BD-09), refs/18-game-mmo.md (MMO — tick, cắt tải), refs/05-loi-hop-dong.md (LH-14 —
> đường lỗi lạnh), refs/00-hien-phap.md (HP-14 — đo trước khi tối ưu).

## 1. Nền tảng [N]

### HN-01 [N] PHẢI — Đo trước khi tối ưu; mọi thay đổi vì hiệu năng kèm số đo trước và sau

Không đổi code "cho nhanh" khi chưa có profile chỉ ra điểm nóng và benchmark tái lập được. PR tối
ưu kèm phiếu đo dưới đây.

- **Vì sao:** trực giác về hiệu năng hay sai: điểm nóng thật thường là cấp phát, cache miss, khoá,
  đoán sai nhánh. Tối ưu mù làm code khó đọc (HP-01, HP-14) mà không chắc nhanh hơn; thiếu số
  "trước" thì không bắt được hồi quy về sau.
- **Kiểm:** review trả lại PR thiếu phiếu đo; profile bằng `perf record -g`, VTune, AMD uProf.

```text
Phiếu đo (dán vào PR; tóm tắt vào comment cạnh code [T]; harness: KT-13):
  Việc:     aoi::rebuild_cells — unordered_map<CellKey, vector> → lưới phẳng + danh sách ô
  Máy:      <CPU, số lõi>, governor performance, ghim lõi (taskset -c 2), SMT bật/tắt
  Build:    <trình dịch + phiên bản> -O2 -march=x86-64-v2 -flto, RelWithDebInfo
  Dữ liệu:  replay <bản ghi>, <số thực thể>, <số tick>
  Kết quả:  trung vị <a> → <b>; p99 <c> → <d>; <số mẫu> mẫu, độ phân tán <e> %
```

### HN-02 [N] PHẢI — Chọn thuật toán và cấu trúc dữ liệu theo độ phức tạp trước mọi vi tối ưu

Khi n có thể vượt vài trăm (thực thể trong zone, người chơi trong AOI, vật phẩm trong kho), cấm
O(n²) và tra tuyến tính lặp lại trên đường nóng — như `std::ranges::contains(blocked, id)` cho mỗi
người nhận chat. Dùng: sắp một lần + tìm nhị phân, băm có `reserve`, chỉ mục theo ID.

- **Vì sao:** vi tối ưu cho hằng số 2–4 lần; đổi O(n·m) sang O(n log m) cho hàng chục, hàng trăm
  lần khi n lớn. Lỗi này lộ ra đúng lúc zone đông nhất (sự kiện, công thành).
- **Kiểm:** review mọi vòng lặp lồng và mọi `find`/`contains` nằm trong vòng lặp; benchmark ở tải
  đỉnh dự kiến × 2.

```cpp
// ✓ Danh sách chặn giữ đã sắp (bất biến của BlockList::add): mỗi người nhận O(log m).
#include <algorithm>
#include <cstdint>
#include <span>

namespace game::world {

// blocked phải đã sắp tăng dần.
[[nodiscard]] inline bool is_blocked(std::span<const std::uint32_t> blocked, std::uint32_t id) noexcept {
    return std::ranges::binary_search(blocked, id);
}

} // namespace game::world
```

### HN-03 [N] CẤM — Cấp phát heap mỗi tick hoặc mỗi gói tin trên đường nóng

Buffer tạm là thành viên, `clear()` (giữ capacity) mỗi lần dùng, `reserve` theo tải đỉnh lúc khởi
tạo. Trong vòng tick không trả vector/string mới (`std::vector<std::byte> build_snapshot()`), không
`make_unique`/`make_shared`, không `std::format` ra `std::string`.

- **Vì sao:** malloc/free nhanh trung bình (cỡ hàng chục ns) nhưng đuôi dài: tranh chấp arena giữa
  luồng, trim/`munmap` rồi page fault khi cấp lại, phân mảnh — p99 tick nhảy vọt (HN-18). Vài nghìn
  thực thể × vài lần cấp × 20–60 tick/s cộng thành phần đáng kể của ngân sách tick.
- **Kiểm:** benchmark báo số lần cấp phát mỗi tick (đếm bằng `operator new` thay thế trong build
  benchmark; harness: KT-13), phải bằng 0 ở trạng thái ổn định; `heaptrack` khi điều tra.
- **Ngoại lệ:** khởi động, nạp zone, sự kiện hiếm ngoài vòng tick.

```cpp
// ✓ Buffer gói là thành viên: clear() giữ capacity, trạng thái ổn định không cấp phát.
#include <cstddef>
#include <span>
#include <vector>

namespace game::net {

class SnapshotWriter {
public:
    explicit SnapshotWriter(std::size_t peak_bytes) { bytes_.reserve(peak_bytes); }

    // Mở gói mới; view của bytes() hợp lệ tới lần begin() kế tiếp.
    void begin() noexcept { bytes_.clear(); }
    void append(std::span<const std::byte> part) { bytes_.insert(bytes_.end(), part.begin(), part.end()); }
    [[nodiscard]] std::span<const std::byte> bytes() const noexcept { return bytes_; }

private:
    std::vector<std::byte> bytes_;
};

} // namespace game::net
```

### HN-04 [N] CẤM — Sao chép ngầm đối tượng sở hữu heap hoặc `std::shared_ptr` trên đường nóng

Dạng hay gặp: `for (const auto player : players)` khi phần tử chứa string/vector; `auto x =
obj.name()` khi hàm trả `const&`; `return std::move(local);` (chặn NRVO); nhận `shared_ptr` theo giá
trị ở hàm chỉ dùng đối tượng trong lời gọi — chỉ nhận theo giá trị khi lưu lại, rồi `std::move` vào
chỗ lưu. Truyền tham số đầy đủ: API-01, SH-05, SH-08.

- **Vì sao:** mỗi bản sao `std::string` dài hơn bộ đệm nội bộ (15 ký tự libstdc++, 22 ký tự libc++
  — đã đo `capacity()` chuỗi rỗng) là malloc + memcpy + free. Mỗi bản sao/huỷ `shared_ptr` là một
  phép nguyên tử (`lock add`/`lock xadd` trên x86): cỡ hàng chục chu kỳ khi không tranh chấp, hàng
  trăm khi nhiều luồng cùng chạm vì dòng cache chạy qua lại giữa các lõi — chi phí rải rác, profile
  không hiện thành một hàm nóng.
- **Kiểm:** clang-tidy `performance-for-range-copy`, `-unnecessary-copy-initialization`,
  `-unnecessary-value-param`, `-move-const-arg`, `-no-automatic-move` (cùng nhóm `performance-`);
  GCC `-Wrange-loop-construct` (trong -Wall), `-Wpessimizing-move`, `-Wredundant-move`.

```cpp
// ✓ Thay cho `is_flagged(std::shared_ptr<Session>)`: hàm chỉ đọc nhận const Session&.
#include <algorithm>
#include <cstdint>
#include <memory>
#include <span>
#include <string>

namespace game::net {

struct Session {
    std::string account_name;
    std::int32_t violations = 0;
};

// Mọi phần tử của sessions khác null.
[[nodiscard]] inline auto count_flagged(std::span<const std::shared_ptr<Session>> sessions) noexcept {
    const auto is_flagged = [](const Session& one) { return one.violations > 3; };
    return std::ranges::count_if(sessions, [&](const auto& one) { return is_flagged(*one); });
}

} // namespace game::net
```

### HN-05 [N] KHÔNG NÊN — Gọi gián tiếp (`virtual`, `std::function`) cho từng phần tử trên đường nóng

Thay `vector<unique_ptr<Mover>>` + `virtual advance()` bằng mỗi kiểu cụ thể một mảng liền, một vòng
lặp thẳng. Hàm duyệt nhận callable qua template ràng buộc `std::invocable`; `std::function` (hay
`std::move_only_function`, libstdc++ — STD-20) chỉ cho callback lưu lâu dài. `std::function_ref` là
C++26. Tiêm phụ thuộc trên đường nóng bằng template: KTR-11.

- **Vì sao:** gọi gián tiếp chặn nội tuyến, nên chặn luôn vector hoá và lan truyền hằng; mỗi đối
  tượng đa hình là một lần đuổi con trỏ ra heap (BN-01); khi các kiểu xen kẽ, đích nhánh gián tiếp
  đổi liên tục, bộ dự đoán nhánh đoán sai — mỗi lần cỡ 15–20 chu kỳ trên x86 hiện đại. `std::function`
  còn cấp phát khi đối tượng bắt lớn hơn bộ đệm nội bộ (vài con trỏ, tuỳ thư viện).
- **Kiểm:** `perf stat -e branch-misses`; `perf annotate` thấy `call *` nóng trong vòng lặp.
- **Ngoại lệ:** vài chục đối tượng, không nóng; ranh giới plugin (API-16).

```cpp
// ✓ Mỗi loại một mảng liền, vòng lặp thẳng; hàm duyệt nhận callable qua template.
#include <chrono>
#include <concepts>
#include <functional>
#include <span>

namespace game::sim {

struct Monster {
    float x = 0.0F;
    float speed = 0.0F;
};

// speed tính theo đơn vị toạ độ mỗi giây.
inline void integrate(std::span<Monster> all, std::chrono::duration<float> dt) noexcept {
    for (Monster& one : all) {
        one.x += one.speed * dt.count();
    }
}

template <std::invocable<const Monster&> Visit>
void for_each_monster(std::span<const Monster> all, const Visit& visit) {
    for (const Monster& one : all) {
        std::invoke(visit, one);
    }
}

} // namespace game::sim
```

### HN-06 [N] PHẢI — Log kiểm mức trước khi định dạng; nơi gọi không tự dựng chuỗi; cấm `std::endl`

Hàm log nhận `std::format_string<Args...>` + đối số, kiểm mức rồi mới định dạng vào buffer tái dùng.
Log debug/trace trong vòng tick, khi tắt ở production, chỉ tốn một phép so — cộng việc tính đối số,
vì đối số vẫn được tính trước lời gọi: chỉ truyền giá trị có sẵn. Xuống dòng bằng `'\n'`.

- **Vì sao:** `log(kDebug, std::format(...))` định dạng và cấp phát trước khi logger kịp biết mức đang
  tắt: trả đủ giá cho một dòng không bao giờ được ghi. `std::endl` là `'\n'` + `flush()`: mỗi dòng
  một lời gọi hệ thống `write` khi stream là file/pipe.
- **Kiểm:** clang-tidy `performance-avoid-endl`; review: `std::format`, `std::to_string`, nối chuỗi
  làm đối số của log là lỗi. Giao diện log: KTR-06; `format_to` vào buffer: STD-04.

```cpp
// ✓ Kiểm mức trước; định dạng vào line_ tái dùng (mỗi luồng một Logger, không chia sẻ).
#include <cstdint>
#include <cstdio>
#include <format>
#include <iterator>
#include <string>
#include <utility>

namespace game::core {

enum class LogLevel : std::uint8_t { kTrace, kDebug, kInfo, kWarn, kError };

class Logger {
public:
    explicit Logger(LogLevel min_level) noexcept : min_level_(min_level) {}

    template <class... Args>
    void write(LogLevel level, std::format_string<Args...> fmt, Args&&... args) {
        if (level < min_level_) return;
        line_.clear();
        std::format_to(std::back_inserter(line_), fmt, std::forward<Args>(args)...);
        line_.push_back('\n');
        // Ghi stderr lỗi thì không còn kênh nào để báo: bỏ kết quả có chủ ý.
        static_cast<void>(std::fwrite(line_.data(), 1, line_.size(), stderr));
    }

private:
    LogLevel min_level_;
    std::string line_;
};

} // namespace game::core
```

## 2. Nâng cao [C]

### HN-07 [C] PHẢI — Benchmark theo phương pháp: dữ liệu thật, khởi động, nhiều mẫu, trung vị + p99

(1) Dữ liệu có cỡ và phân bố như production (replay zone thật, không phải 100 phần tử nóng sẵn
trong L1); (2) vòng khởi động bỏ kết quả; (3) ≥ 20 mẫu, báo trung vị, p99, min — không một con số
trung bình; (4) ghim lõi, governor `performance`, ghi rõ turbo/SMT; (5) kết quả phải được "dùng"
để trình dịch không xoá phép tính; (6) A/B chạy xen kẽ trong cùng phiên máy. Code harness: KT-13.

- **Vì sao:** tần số CPU đổi theo nhiệt và tải, lõi bị luồng khác chiếm, lần chạy đầu trả page fault
  và cache lạnh; trung bình che đuôi, mà đuôi mới làm tick trễ. Kết quả không dùng thì trình dịch
  xoá cả phép tính và cho "0 ns". Máy ảo dùng chung (CI) nhiễu lớn: chỉ bắt hồi quy lớn.
- **Kiểm:** review phiếu đo (HN-01): trung vị, p99 (harness KT-13 trả hai số này), min, số mẫu.

```bash
# Máy đo Linux (cần quyền): tần số cố định, ghim lõi, đếm sự kiện phần cứng, lặp 10 lần.
sudo cpupower frequency-set -g performance
taskset -c 2 ./bench_aoi --warmup 5 --samples 30
perf stat -r 10 -e cycles,instructions,branch-misses,cache-misses -- taskset -c 2 ./bench_aoi
```

### HN-08 [C] PHẢI — Ngân sách tick chia cho từng pha, đo mỗi tick, theo dõi p99 và số lần vượt

Tick 20 Hz có 50 ms: đặt ngân sách cho từng pha (input, mô phỏng, AOI, snapshot, gửi), chừa ≥ 30 %
dự phòng; đo mỗi pha bằng `std::chrono::steady_clock`, đếm số lần vượt, xuất histogram ra giám
sát. Hành động khi vượt (cắt tải): MMO.

- **Vì sao:** "tick trung bình 12 ms" vô nghĩa khi p99 là 70 ms — người chơi cảm nhận đuôi (giật,
  kéo ngược vị trí). Đo theo pha chỉ ra pha nào ăn ngân sách khi zone đông. `steady_clock::now()`
  qua vDSO tốn cỡ vài chục ns: đo theo pha không đáng kể, đo theo thực thể thì không được.
- **Kiểm:** histogram theo pha trên dashboard (KTR-18); test tải bằng bot ở mức đỉnh × 2.

```cpp
// ✓ Một lần now() mỗi pha; vượt ngân sách thì đếm, không log từng tick.
#include <algorithm>
#include <chrono>
#include <cstdint>

namespace game::sim {

struct PhaseBudget {
    std::chrono::nanoseconds limit{};
    std::chrono::nanoseconds worst{};
    std::uint64_t overruns = 0;
};

class TickClock {
public:
    using Clock = std::chrono::steady_clock;

    void begin_tick() noexcept { last_ = Clock::now(); }

    // Gọi ở cuối mỗi pha với ngân sách của pha đó.
    void end_phase(PhaseBudget& phase) noexcept {
        const Clock::time_point now = Clock::now();
        const auto spent = std::chrono::duration_cast<std::chrono::nanoseconds>(now - last_);
        phase.worst = std::max(phase.worst, spent);
        phase.overruns += spent > phase.limit ? 1U : 0U;
        last_ = now;
    }

private:
    Clock::time_point last_;
};

} // namespace game::sim
```

### HN-09 [C] KHÔNG NÊN — Tra cứu bằng chuỗi trên đường nóng; đổi chuỗi → chỉ số một lần lúc nạp

Tên mẫu vật phẩm, kỹ năng, buff đổi sang ID kiểu mạnh là chỉ số mảng lúc nạp dữ liệu hoặc lúc giải
mã gói; đường nóng tra `std::vector` theo chỉ số. `map`/`unordered_map` khoá chuỗi chỉ ở đường lạnh
(nạp dữ liệu, lệnh GM).

- **Vì sao:** tra `unordered_map<std::string, …>` = băm cả chuỗi + so chuỗi + ít nhất một lần đuổi
  con trỏ nút; `std::map` = log₂n lần so chuỗi, mỗi nút có thể trượt cache. Tra mảng theo chỉ số =
  một phép nạp. Chênh hàng chục lần mỗi lần tra, nhân với số đòn đánh mỗi tick.
- **Kiểm:** review: `std::string`/`std::string_view` làm khoá trong code tick.

```cpp
// ✓ Thay cho `skills.at(name)` mỗi đòn: SkillId là chỉ số, tra mảng.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::combat {

enum class SkillId : std::uint16_t {};

struct SkillDef {
    std::int32_t power = 0;
    std::int32_t mana_cost = 0;
};

class SkillTable {
public:
    // Id từ client đã được bộ giải mã kiểm (LH-03); tới đây mà ngoài bảng là lỗi lập trình.
    [[nodiscard]] const SkillDef& def(SkillId id) const noexcept {
        const auto index = static_cast<std::size_t>(id);
        core::check(index < defs_.size(), "SkillTable::def: id phải nằm trong bảng");
        return defs_[index];
    }

private:
    // Chỉ số là SkillId; nạp từ dữ liệu lúc khởi động.
    std::vector<SkillDef> defs_;
};

} // namespace game::combat
```

### HN-10 [C] NÊN — Chép giá trị bất biến vòng lặp ra biến `const` cục bộ khi trình dịch không chứng minh được nó bất biến

Thành viên đọc qua `this`, giá trị sau con trỏ/tham chiếu, kết quả hàm không nội tuyến: nếu vòng lặp
ghi qua con trỏ/tham chiếu cùng kiểu, trình dịch phải giả định alias và nạp lại mỗi vòng.

- **Vì sao:** đã kiểm asm (x86-64, -O2): mẫu ✗ — GCC 14 nạp lại `speed_`, `dt_` và nhân lại mỗi phần
  tử (`pos` có thể chính là `speed_`), Clang 20 chèn kiểm chồng lấn lúc chạy rồi mới vector hoá. Mẫu
  ✓ — GCC bỏ nạp lại, Clang vector hoá không cần kiểm. Strict aliasing không giúp: cùng kiểu `float`.
- **Kiểm:** đọc asm vòng lặp nóng (HN-15); báo cáo vector hoá (SV-02): GCC ở `-O3` in "loop versioned
  for vectorization because of possible aliasing"; ở `-O2` GCC không tạo bản kiểm alias nên không có
  dòng đó, chỉ thấy vòng lặp không được vector hoá (đã thử GCC 14/15).

```cpp
// ✗ Ghi qua float& nên speed_ và dt_ phải được nạp lại (hoặc kiểm chồng lấn) mỗi vòng.
#include <chrono>
#include <span>

namespace game::sim {

class Wind {
public:
    void push(std::span<float> positions) const noexcept {
        for (float& pos : positions) {
            pos += speed_ * dt_.count();
        }
    }

private:
    float speed_ = 1.0F;
    std::chrono::duration<float> dt_{0.05F};
};

} // namespace game::sim
```

```cpp
// ✓ Bất biến chép ra trước vòng lặp: không còn alias với dữ liệu được ghi.
#include <chrono>
#include <span>

namespace game::sim {

class Wind {
public:
    void push(std::span<float> positions) const noexcept {
        const float step = speed_ * dt_.count();
        for (float& pos : positions) {
            pos += step;
        }
    }

private:
    float speed_ = 1.0F;
    std::chrono::duration<float> dt_{0.05F};
};

} // namespace game::sim
```

### HN-11 [C] PHẢI — Hiểu đúng `inline`: quy tắc ODR, không phải lệnh nội tuyến

`inline` (và hàm định nghĩa trong thân lớp, `constexpr`, template) cho phép định nghĩa có mặt ở
nhiều TU. Nội tuyến hay không do trình dịch quyết theo mô hình chi phí, và chỉ khi thấy thân hàm.
Hàm nhỏ, nóng, gọi từ TU khác: định nghĩa trong header, hoặc bật LTO (HN-12).

- **Vì sao:** hàm định nghĩa trong `.cpp` không được nội tuyến vào TU khác nếu không có LTO, dù khai
  báo có `inline` (khai `inline` mà không định nghĩa trong TU dùng nó là ill-formed; GCC/Clang chỉ
  cảnh báo "used but never defined"/`-Wundefined-inline`). Lời gọi không nội tuyến trong vòng lặp
  chặn vector hoá (SV-01).
- **Kiểm:** GCC `-fopt-info-inline-missed`, Clang `-Rpass-missed=inline`; tìm `call` trong asm.

```cpp
// ✓ Trong world/cell.hpp: hàm nhỏ, nóng, mọi TU thấy thân nên nội tuyến được.
#include <cstdint>

namespace game::world {

// Lưới 1024 × 1024 ô: col, row trong [0, 1024), nơi gọi đã kẹp.
[[nodiscard]] constexpr std::uint32_t cell_index(std::uint32_t col, std::uint32_t row) noexcept {
    return (row << 10U) | col;
}

} // namespace game::world
```

### HN-12 [C] PHẢI — Cờ hiệu năng bản phát hành theo bảng; cờ ngoài bảng chỉ khi có số đo

| Cờ | Dùng khi | Ghi chú (đã kiểm GCC 14/15, Clang 20, x86-64) |
|---|---|---|
| `-O2` | mặc định phát hành | GCC -O2 dùng mô hình chi phí `very-cheap`: không vector hoá vòng lặp cần kiểm alias lúc chạy; GCC 14 còn bỏ vòng lặp cần phần dư (số lần lặp không biết trước), GCC 15 thì không. Clang -O2 vector hoá cả hai (SV-01) |
| `-O3` | TU/hàm nóng đã đo | GCC vector hoá đầy đủ, nội tuyến mạnh hơn; code to hơn — đo cả i-cache |
| `-march=x86-64-v2` | baseline phân phối | SSE4.2, POPCNT; vector_int.hpp cần SSE4.1 (`PMINSD`) và SSSE3 (`PABSD`) |
| `-march=x86-64-v3` | máy chủ có phần cứng bảo đảm | AVX2, FMA, BMI2; FMA đổi kết quả số thực (SV-11) |
| `-march=native` | CẤM cho phát hành | binary chỉ chạy trên CPU cùng đời với máy build |
| `-flto=auto` (GCC), `-flto=thin` (Clang) | phát hành | nội tuyến xuyên TU; CMake `INTERPROCEDURAL_OPTIMIZATION` |
| `-fno-semantic-interposition` | `.so` biên dịch `-fPIC` (GCC) | cho phép nội tuyến hàm toàn cục trong cùng `.so` |
| `-fno-math-errno` | nên bật | `std::sqrt(float)` thành một `sqrtss`, bỏ nhánh + lời gọi `sqrtf` cho đối số âm; giá trị trả về không đổi |
| PGO, BOLT | máy chủ, có tải mẫu | HN-17 |
| `-ffast-math`, `-Ofast` | CẤM toàn cục | SV-06 |

- **Vì sao:** -O2 là điểm cân bằng được kiểm nhiều nhất; khác biệt -O2/-O3 chủ yếu ở vector hoá và
  nội tuyến, chỉ đáng đổi ở chỗ đo thấy lợi. Baseline `-march` quyết định tập lệnh: sai baseline là
  SIGILL trên máy cũ. LTO là cách duy nhất để hàm nhỏ trong `.cpp` nội tuyến sang TU khác.
- **Kiểm:** `g++ -Q --help=optimizers -O2` liệt kê tối ưu đang bật; CI kiểm `compile_commands.json`.

```cmake
# Cờ hiệu năng bản phát hành (cờ cảnh báo, hardening: BD).
include(CheckIPOSupported)
check_ipo_supported(RESULT game_ipo_ok OUTPUT game_ipo_log)
# Cả hai cấu hình tối ưu cùng cờ hiệu năng, nên số đo ở RelWithDebInfo (CI, profiler) khớp bản phát hành.
set_target_properties(game_server PROPERTIES
    INTERPROCEDURAL_OPTIMIZATION_RELEASE ${game_ipo_ok}
    INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO ${game_ipo_ok})
# Genex chứa nhiều cờ: ngoặc kép + dấu ';' — dấu cách sẽ tách genex thành đối số hỏng.
# CMake Release mặc định có sẵn -O3 -DNDEBUG; cờ target đứng sau nên -O2 ở đây thắng (đã thử).
target_compile_options(game_server PRIVATE
    "$<$<CONFIG:Release,RelWithDebInfo>:-O2;-march=x86-64-v2;-fno-math-errno>")
```

## 3. Thần thoại [T]

### HN-13 [T] CÓ THỂ — `[[likely]]`/`[[unlikely]]` và `[[gnu::cold/noinline/hot/flatten/always_inline]]` khi số đo chỉ ra vấn đề bố cục hoặc nội tuyến cụ thể

`[[likely]]`/`[[unlikely]]` chỉ đổi cách xếp khối (đường rơi thẳng, khối lạnh ra cuối hàm,
if-conversion); trình dịch không phát gợi ý cho bộ dự đoán — bộ dự đoán động tự học. `cold`: hàm vào
`.text.unlikely`, nhánh tới nó coi là hiếm. `noinline`: giữ đường hiếm, lớn ở ngoài để hàm nóng nhỏ.
`hot`: gom vào `.text.hot`. `flatten`: nội tuyến mọi lời gọi bên trong. `always_inline`: ép, GCC báo
lỗi khi không làm được. Có PGO (HN-17) thì tốt hơn gợi ý tay. Đường lỗi lạnh: LH-14.

- **Vì sao:** mô hình chi phí của trình dịch không biết tần suất thật; khi profile cho thấy hàm nóng
  không được nội tuyến vì kéo theo đường hiếm, tách đường hiếm là sửa đúng gốc. Gợi ý sai, hoặc ép
  nội tuyến tràn lan, làm phình code, tăng áp lực i-cache — chậm hơn, và sai dần khi dữ liệu đổi.
- **Kiểm:** đo trước/sau, ghi vào comment; `perf annotate`. GCC 14/15 và Clang 20 nhận cả các thuộc
  tính `gnu::` trên (đã biên dịch thử); MSVC bỏ qua kèm cảnh báo.

```cpp
// ✓ Đường từ chối hiếm (profile replay xác nhận) tách thành hàm lạnh: hàm nóng chỉ còn một phép so.
#include <cstdint>

namespace game::net {

struct MoveSample {
    std::uint32_t session_id = 0;
    float speed = 0.0F;
    float max_speed = 0.0F;
};

[[gnu::cold, gnu::noinline]] inline void note_rejected(std::uint64_t& rejected, const MoveSample& sample) noexcept {
    ++rejected;
    // log chi tiết, lưu bằng chứng gian lận (đường lạnh)
    static_cast<void>(sample);
}

// NaN cũng bị từ chối: mọi phép so với NaN là sai.
[[nodiscard]] inline bool accept_speed(std::uint64_t& rejected, const MoveSample& sample) noexcept {
    if (sample.speed <= sample.max_speed) [[likely]] {
        return true;
    }
    note_rejected(rejected, sample);
    return false;
}

} // namespace game::net
```

### HN-14 [T] CÓ THỂ — `[[gnu::target_clones]]` cho hàm lá nóng tự vector hoá khi binary chạy trên nhiều đời CPU

Trình dịch sinh mỗi tập lệnh một bản cùng một hàm chọn (resolver); trình nạp động chọn một lần qua
ifunc (ELF + glibc). Đặt trên hàm làm trọn một vòng lặp, không trên hàm nhỏ gọi từng phần tử: lời
gọi đi qua PLT/GOT, không nội tuyến được. Windows/MSVC không có ifunc: dispatch tay (SV-10).

- **Vì sao:** binary baseline x86-64-v2 vẫn dùng AVX2/FMA ở vòng lặp nóng nhất mà không phải duy trì
  đường SIMD viết tay. Đã biên dịch thử: GCC 14/15 và Clang 20 nhận
  `target_clones("arch=x86-64-v3", "default")`, sinh hai bản + resolver. Nhưng bản v3 chỉ có lợi khi
  vòng lặp thật sự được vector hoá: với mẫu dưới, GCC 14 `-O2` không sinh lệnh `ymm` nào (vòng lặp cần
  phần dư, HN-12), GCC 15 `-O2`, GCC 14 `-O3` và Clang 20 `-O2` thì có — đọc asm bản v3 trước khi tin.
- **Kiểm:** `nm -C` thấy `[clone .arch_x86_64_v3]`, `[clone .default]` (GCC; Clang đặt hậu tố
  `.arch_x86-64-v3.0`, `.default.1`) cùng một ký hiệu kiểu `i` (ifunc). Resolver đọc CPUID qua
  runtime của trình dịch: test bản mặc định trên máy không AVX2 hoặc dưới Intel SDE.

```cpp
// ✓ [linux] Một định nghĩa, hai bản máy: v3 (AVX2, FMA) và mặc định; ifunc chọn lúc nạp.
#include <span>

namespace game::sim {

void scale_all(std::span<float> values, float factor) noexcept;

[[gnu::target_clones("arch=x86-64-v3", "default")]] void scale_all(std::span<float> values, float factor) noexcept {
    for (float& value : values) {
        value *= factor;
    }
}

} // namespace game::sim
```

### HN-15 [T] PHẢI — Khẳng định về codegen và vi kiến trúc dựa trên asm và bộ đếm phần cứng, không suy đoán

"Đã vector hoá", "ở đây là cmov", "nút thắt là bộ nhớ" chỉ được viết vào comment/PR sau khi xem asm
thật (sau LTO nếu có) và đếm sự kiện. Phân tích top-down (TMA) chia chu kỳ thành Retiring / Bad
Speculation / Frontend Bound / Backend Bound (Memory, Core): Memory → BN; Bad Speculation → nhánh
(SV-17); Frontend → cỡ code, PGO/BOLT; Core → chuỗi phụ thuộc, cổng thực thi (SV-18, SV-19).

- **Vì sao:** codegen đổi theo trình dịch, phiên bản và cờ. Đã kiểm trong bộ này: GCC 14 -O2 không
  vector hoá vòng lặp mà Clang 20 -O2 vector hoá (HN-12); Clang 20 đổi `?:` thành nhánh trong tìm
  kiếm nhị phân còn GCC 14 giữ `cmov` (SV-17). `llvm-mca` mô phỏng thông lượng một khối lặp đã nằm
  trong L1 — không mô hình cache miss hay đoán sai nhánh.
- **Kiểm:** các lệnh dưới; kết luận ghi kèm trình dịch, cờ, CPU.

```bash
# Asm một TU, cú pháp Intel, bỏ nhiễu CFI, giải tên:
g++ -std=c++23 -O2 -march=x86-64-v2 -S -masm=intel -fno-asynchronous-unwind-tables -o - aoi.cpp | c++filt
# Asm thật của binary (sau LTO):
objdump -d --no-show-raw-insn -M intel -C build/game_server | less
# Thông lượng khối lặp (đánh dấu # LLVM-MCA-BEGIN / # LLVM-MCA-END trong file .s):
llvm-mca -mcpu=znver3 -timeline -bottleneck-analysis loop.s
# Top-down (tên nhóm tuỳ CPU và phiên bản perf: xem `perf list metricgroup`):
perf stat -M TopdownL1 -- taskset -c 2 ./bench_aoi
perf record -g -- ./bench_aoi && perf annotate --stdio -s game::world::rebuild_cells
```

### HN-16 [T] NÊN — Giảm sức mạnh phép tính: số chia hằng hoặc luỹ thừa 2 không dấu; số chia lúc chạy thì tính trước

Đã kiểm asm (GCC 14, Clang 20, -O2): `x / 48U` thành `imul` + `shr`, có dấu thêm 2–3 lệnh sửa dấu;
`x / size` với `size` lúc chạy là `div`. `x % 16U` thành `and`; `x % 16` có dấu thành 5–6 lệnh vì
chia nguyên làm tròn về 0 nên phần dư mang dấu số bị chia. Cạnh ô lưới, cỡ vòng đệm: luỹ thừa 2
không dấu, lưu số mũ. Số thực: `x / cell` (`divss`) → `x * inv_cell` tính trước.

- **Vì sao:** chia nguyên phần cứng có độ trễ cỡ chục đến vài chục chu kỳ tuỳ đời CPU, thông lượng
  thấp hơn nhân nhiều lần, và SIMD không có lệnh chia nguyên. Nhân nghịch đảo số thực có thể lệch
  1 ulp so với chia: ô biên có thể khác — chấp nhận được khi MỌI chỗ tính ô dùng cùng một hàm.
- **Kiểm:** asm (HN-15): không còn `div`/`idiv`/`divss` trong vòng lặp nóng.

```cpp
// ✓ Thay cho `(pos_y / cell_size) * width + pos_x / cell_size` (hai div): cạnh ô, bề rộng là 2^k.
#include "core/check.hpp"

#include <cstdint>

namespace game::world {

// Cạnh ô là 2^cell_shift đơn vị toạ độ; lưới rộng 2^width_shift ô.
struct GridShape {
    std::uint32_t cell_shift = 0;
    std::uint32_t width_shift = 0;
};

class Grid {
public:
    explicit Grid(GridShape shape) noexcept : cell_shift_(shape.cell_shift), width_shift_(shape.width_shift) {
        // Viết dạng không tràn: cell_shift + width_shift có thể quấn với cấu hình hỏng.
        const bool fits_in_32_bits = cell_shift_ < 32U && width_shift_ < 32U - cell_shift_;
        core::check(fits_in_32_bits, "Grid: cell_shift + width_shift phải nhỏ hơn 32");
    }

    // (pos >> cell_shift) < 2^width_shift: nơi gọi đã kẹp toạ độ vào thế giới.
    [[nodiscard]] std::uint32_t cell_of(std::uint32_t pos_x, std::uint32_t pos_y) const noexcept {
        return ((pos_y >> cell_shift_) << width_shift_) | (pos_x >> cell_shift_);
    }

private:
    std::uint32_t cell_shift_;
    std::uint32_t width_shift_;
};

} // namespace game::world
```

### HN-17 [T] CÓ THỂ — PGO rồi BOLT cho binary máy chủ, huấn luyện bằng replay tải thật

PGO: build đo → chạy replay đại diện (zone đông, đủ loại gói) → build dùng hồ sơ. BOLT: sắp lại hàm
và khối của binary đã liên kết theo profile perf (cần LBR hoặc tương đương). Code đổi nhiều thì
huấn luyện lại; tải huấn luyện lệch làm chậm đường không được huấn luyện.

- **Vì sao:** PGO cho trình dịch xác suất nhánh và tần suất gọi thật: bố cục khối, quyết định nội
  tuyến, tách nóng/lạnh — lợi rõ với code máy chủ nhiều nhánh (phải tự đo). BOLT sửa bố cục
  i-cache/iTLB cho binary lớn bị Frontend Bound (HN-15). PGO/LTO đổi quyết định nội tuyến, nên với
  `-ffp-contract=fast` (mặc định GCC) chỗ hợp nhất FMA có thể đổi theo → code tất định phải dùng
  `-ffp-contract=off` (SV-11).
- **Kiểm:** benchmark replay trước/sau; CI giữ hồ sơ theo phiên bản; GCC `-Wmissing-profile`.

```bash
# GCC: đo (đa luồng → bộ đếm nguyên tử), chạy replay, dùng hồ sơ.
g++ ... -O2 -fprofile-generate -fprofile-update=atomic -o game_server_instr
./game_server_instr --replay captures/zone3-peak.bin
g++ ... -O2 -fprofile-use -fprofile-partial-training -o game_server
# Clang (IR PGO): -fprofile-generate → gộp .profraw → -fprofile-use=game.profdata
llvm-profdata merge -output=game.profdata *.profraw
# BOLT: binary liên kết với -Wl,--emit-relocs; profile có LBR.
perf record -e cycles:u -j any,u -o perf.data -- ./game_server --replay captures/zone3-peak.bin
perf2bolt -p perf.data -o perf.fdata ./game_server
llvm-bolt ./game_server -o game_server.bolt -data=perf.fdata -reorder-blocks=ext-tsp \
    -reorder-functions=hfsort -split-functions -split-all-cold -split-eh -dyno-stats
```

### HN-18 [T] PHẢI — Đuôi p99.9 của tick: đưa page fault và cấp phát lớn ra khỏi vòng tick

Lúc khởi tạo zone: cấp mọi buffer theo tải đỉnh rồi chạm trước từng trang (với `std::vector`:
`resize` tới tải đỉnh rồi `clear()` — capacity và trang đã chạm còn nguyên; ghi vào phần chỉ
`reserve` mà chưa có phần tử là UB); máy chủ chuyên dụng
khoá bộ nhớ (`mlockall(MCL_CURRENT | MCL_FUTURE)`, cần `CAP_IPC_LOCK` hoặc `RLIMIT_MEMLOCK` đủ);
chỉnh `GLIBC_TUNABLES` (`glibc.malloc.mmap_threshold`, `glibc.malloc.trim_threshold`) để khối lớn
không bị trả về hệ điều hành rồi fault lại. Trang lớn và TLB: BN-13.

- **Vì sao:** `reserve` chỉ giữ địa chỉ ảo; trang thật được cấp ở lần ghi đầu (page fault, cỡ micro
  giây mỗi trang) — rơi vào tick zone đông lên. glibc phục vụ khối lớn bằng `mmap`, `free` trả bằng
  `munmap`: lần sau fault lại. Swap làm một tick mất hàng chục ms. Trung bình không thấy; p99.9 thấy.
- **Kiểm:** `perf stat -e page-faults,major-faults -p <pid>` lúc tải ổn định phải gần 0; dashboard
  tick có p99.9 và max.

```cpp
// ✓ Chạm trước mọi trang của vùng nhớ zone lúc khởi tạo: page fault xảy ra ở đây, không ở tick.
#include <cstddef>
#include <span>

namespace game::mem {

inline constexpr std::size_t kPageSize = 4096;

// Phải GHI: trang ẩn danh chỉ được đọc sẽ ánh xạ tới trang 0 dùng chung, ghi lần đầu vẫn fault.
// region căn theo trang (bước kPageSize chỉ chạm hết mọi trang khi đầu vùng là đầu trang) và chưa
// chứa dữ liệu: byte đầu mỗi trang bị ghi đè bằng 0.
inline void prefault(std::span<std::byte> region) noexcept {
    for (std::size_t offset = 0; offset < region.size(); offset += kPageSize) {
        region[offset] = std::byte{0};
    }
}

} // namespace game::mem
```

## Kiểm nhanh

- [ ] Thay đổi vì hiệu năng có phiếu đo trước/sau (máy, cờ, dữ liệu, trung vị, p99)? (HN-01, HN-07)
- [ ] Không có O(n²) hay `find` lặp trong vòng lặp tick với n có thể lớn? (HN-02)
- [ ] Trạng thái ổn định của tick cấp phát 0 lần; buffer tạm là thành viên + `clear()`? (HN-03)
- [ ] Không chép ngầm string/vector/`shared_ptr`, không gọi ảo/`std::function` từng phần tử? (HN-04, HN-05)
- [ ] Log kiểm mức trước khi định dạng, không `std::endl`; mỗi pha tick có ngân sách được đo? (HN-06, HN-08)
- [ ] Đường nóng tra mảng theo ID, không tra map khoá chuỗi? (HN-09)
- [ ] Cờ phát hành đúng bảng: -O2, baseline x86-64-v2, LTO, không `-march=native`/`-ffast-math`? (HN-12)
- [ ] Mọi khẳng định "đã vector hoá"/"là cmov"/"bound bộ nhớ" có asm hoặc perf kèm theo? (HN-15)
- [ ] Không còn `div` trong vòng lặp nóng khi số chia có thể là luỹ thừa 2 hoặc tính trước? (HN-16)
- [ ] Buffer của zone được chạm trước; page fault ở trạng thái ổn định gần 0? (HN-18)
