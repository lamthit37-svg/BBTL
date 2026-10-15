# BN · Bộ nhớ, cache và thiết kế hướng dữ liệu

> **Phạm vi:** bố cục, byte đệm, mảng liền vs container nút, chỉ số thay con trỏ, AoS/SoA/AoSoA,
> nóng/lạnh, dòng cache, căn lề, allocator (pmr, pool, sức chứa cố định), prefetch, trang lớn/TLB,
> NUMA, băng thông, Z-order, `__restrict`. **Đọc khi:** thiết kế struct sống mỗi tick; chọn container
> cho đường nóng; thấy `std::list`, `std::map`, `vector<unique_ptr<T>>`, `vector<bool>` trong code
> tick; cần căn lề SIMD/dòng cache; perf báo Memory Bound; viết arena hay pool.
> **Liên quan:** refs/09-hieu-nang.md (HN — đo, cấp phát, độ trễ đuôi), refs/11-simd-vi-kien-truc.md
> (SV — vector hoá, transpose), refs/12-dong-thoi.md (DT-10 — false sharing), refs/18-game-mmo.md
> (MMO — handle thế hệ, AOI), refs/04-so-huu-vong-doi.md (SH-07, SH-16), refs/17-kien-truc-module.md
> (KTR-13 — hệ thống hướng dữ liệu).

## Bảng tra bậc độ lớn (x86-64 hiện đại, tuỳ đời CPU — chỉ để ước lượng)

| Mức | Độ trễ nạp | Ghi chú |
|---|---|---|
| L1d | ~4–5 chu kỳ | 32–48 KiB mỗi lõi; dòng cache 64 B |
| L2 | ~12–16 chu kỳ | 256 KiB–2 MiB mỗi lõi |
| L3 | ~40–70 chu kỳ | dùng chung, vài đến vài chục MiB |
| DRAM | ~80–120 ns (hàng trăm chu kỳ) | xa hơn nữa nếu khác node NUMA |

Duyệt tuần tự được bộ prefetch phần cứng che; đuổi con trỏ (nút → nút) thì không, vì địa chỉ kế
tiếp chỉ biết sau khi lần nạp trước xong — các miss nối đuôi nhau.

## 1. Nền tảng [N]

### BN-01 [N] PHẢI — Dữ liệu duyệt mỗi tick nằm trong mảng giá trị liền và đặc; xoá bằng chép phần tử cuối vào chỗ trống

Thực thể, đạn, buff sống theo tick: `std::vector<T>` chứa giá trị, không lỗ. Không `std::list`/
`std::map`/`std::set`, không `vector<unique_ptr<T>>` (mỗi đối tượng một lần cấp lẻ) trên đường nóng.

- **Vì sao:** một dòng cache 64 B chứa nhiều phần tử, bộ prefetch đoán được, vòng lặp vector hoá
  được (SV-01). Container nút và mảng con trỏ: mỗi phần tử một lần đuổi con trỏ tới địa chỉ rải rác
  — miss nối đuôi, không chồng lấp — cộng một lần cấp phát mỗi phần tử (HN-03).
- **Kiểm:** review container trong code tick; perf `cache-misses`, top-down Memory Bound (HN-15).
- **Ngoại lệ:** xoá đổi chỗ phần tử, nên ai giữ chỉ số phải đi qua handle thế hệ (MMO); cần thứ tự
  ổn định thì đánh dấu chết và nén theo lô cuối tick.

```cpp
// ✓ Mảng giá trị đặc; xoá O(1) bằng chép phần tử cuối.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::sim {

// Mốc thời gian game (MMO-03; dự án: core/time.hpp). Hết hạn là mốc, không đếm ngược mỗi tick.
enum class Tick : std::uint64_t {};

struct Projectile {
    Tick expires{};
    float x = 0.0F;
    float y = 0.0F;
};

inline void swap_remove(std::vector<Projectile>& all, std::size_t index) noexcept {
    core::check(index < all.size(), "swap_remove: index phải nhỏ hơn số phần tử");
    // index là phần tử cuối thì tự chép chính nó: vô hại với kiểu này.
    all[index] = all.back();
    all.pop_back();
}

} // namespace game::sim
```

### BN-02 [N] PHẢI — Sắp thành viên theo căn lề giảm dần và khoá cỡ bằng `static_assert` cho struct nóng, struct mạng, struct lưu

Thành viên 8 byte trước, rồi 4, 2, 1; gom `bool`/cờ cuối struct. Struct nằm trong mảng lớn, gửi qua
mạng hay lưu DB có `static_assert(sizeof(T) == …)`: đổi bố cục phải là quyết định có ý thức.

- **Vì sao:** mỗi thành viên được đệm tới bội số căn lề của nó; `bool` xen giữa `double` làm struct
  to gần gấp đôi: ít phần tử mỗi dòng cache, nhiều băng thông hơn.
- **Kiểm:** `static_assert(sizeof …)`; `-Wpadded` (GCC/Clang, bật tạm khi review vì ồn); `pahole`.

```cpp
// ✗ bool xen giữa double: 40 B, trong đó 16 B đệm.
#include <cstdint>

namespace game::world {

struct EntityState {
    bool alive;
    double pos_x;
    bool visible;
    std::int32_t hp;
    double pos_y;
    std::uint16_t level;
};

static_assert(sizeof(EntityState) == 40);

} // namespace game::world
```

```cpp
// ✓ Cùng thành viên, sắp theo căn lề giảm dần: 24 B, không đệm giữa.
#include <cstdint>

namespace game::world {

struct EntityState {
    double pos_x = 0.0;
    double pos_y = 0.0;
    std::int32_t hp = 0;
    std::uint16_t level = 0;
    bool alive = false;
    bool visible = false;
};

static_assert(sizeof(EntityState) == 24, "EntityState đổi cỡ: xem lại bố cục và băng thông");

} // namespace game::world
```

### BN-03 [N] CẤM — `std::vector<bool>` trên đường nóng, khi cần tham chiếu hay `span`, hoặc khi nhiều luồng ghi

Cờ theo phần tử: `std::vector<std::uint8_t>` (hoặc enum 1 byte). Tập bit lớn cần đếm/giao nhanh (mặt
nạ AOI): mảng `std::uint64_t` + `std::popcount`, thao tác theo từ 64 bit.

- **Vì sao:** `vector<bool>` đóng gói bit: `operator[]` trả proxy (không có `bool&`, không `data()`,
  `auto x = v[i]` giữ proxy chứ không giữ giá trị), mỗi truy cập là dịch + mặt nạ, khó vector hoá.
  Chuẩn loại riêng `vector<bool>` khỏi bảo đảm "sửa hai phần tử khác nhau từ hai luồng không tranh
  chấp": hai cờ chung một từ nhớ là tranh chấp dữ liệu.
- **Kiểm:** grep `vector<bool>` trong code tick.

```cpp
// ✓ Một byte mỗi cờ: tham chiếu thật, span được, vòng lặp vector hoá được.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::world {

// visible[i] là 0 hoặc 1 cho thực thể i trong tầm nhìn của người chơi.
[[nodiscard]] inline std::size_t count_visible(std::span<const std::uint8_t> visible) noexcept {
    return static_cast<std::size_t>(std::ranges::count(visible, std::uint8_t{1}));
}

} // namespace game::world
```

### BN-04 [N] PHẢI — Lưới 2D là một mảng phẳng hàng-trước; duyệt từng hàng như một đoạn liền

Lưới AOI, bản đồ độ cao, lưới va chạm: một `std::vector<T>` cỡ `width * height`, ô `(col, row)` ở
`row * width + col`. Vòng lặp chạy theo hàng, phần trong là `span` liền của hàng. Không
`vector<vector<T>>`, không duyệt theo cột.

- **Vì sao:** duyệt theo cột nhảy bước `width * sizeof(T)` byte: mỗi phần tử một dòng cache mới, bước
  vượt 4 KiB thì trượt cả TLB. `vector<vector<T>>` thêm đuổi con trỏ và cấp phát mỗi hàng.
- **Kiểm:** review biểu thức chỉ số trong vòng lặp lưới; perf `cache-misses` trước/sau.

```cpp
// ✓ Xoá một hình chữ nhật ô: mỗi hàng là một đoạn liền, fill chạy trên bộ nhớ tuần tự.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::world {

struct CellRect {
    std::size_t first_col = 0;
    std::size_t cols = 0;
    std::size_t first_row = 0;
    std::size_t rows = 0;
};

// cells là lưới hàng-trước rộng width; rect đã được kẹp vào lưới.
inline void clear_rect(std::span<std::uint32_t> cells, std::size_t width, CellRect rect) noexcept {
    for (std::size_t row = rect.first_row; row < rect.first_row + rect.rows; ++row) {
        std::ranges::fill(cells.subspan((row * width) + rect.first_col, rect.cols), 0U);
    }
}

} // namespace game::world
```

### BN-05 [N] PHẢI — Liên kết giữa dữ liệu nóng bằng chỉ số 32 bit, không bằng con trỏ 64 bit

Mục tiêu của thực thể, thành viên ô AOI, nút cây trong mảng: chỉ số 32 bit kiểu mạnh vào mảng chủ.
Con trỏ chỉ sống trong phạm vi một hàm.

- **Vì sao:** 4 B thay 8 B: gấp đôi số liên kết mỗi dòng cache. Chỉ số không treo khi `vector` của
  chủ tăng trưởng (con trỏ thì treo — SH-07), tuần tự hoá/gửi mạng/replay được nguyên trạng và giống
  nhau giữa các lần chạy (tất định).
- **Kiểm:** review struct nóng có thành viên `T*`; `static_assert(sizeof …)`.

```cpp
// ✓ Thành viên ô AOI là chỉ số 32 bit vào mảng thực thể của zone, không phải Entity*.
#include <cstdint>
#include <vector>

namespace game::world {

enum class EntityIndex : std::uint32_t {};

struct AoiCell {
    std::vector<EntityIndex> members;
};

static_assert(sizeof(EntityIndex) == 4);

} // namespace game::world
```

## 2. Nâng cao [C]

### BN-06 [C] NÊN — Chọn AoS, SoA hay AoSoA theo mẫu truy cập của hệ thống nóng nhất

Đọc vài trường của rất nhiều thực thể (di chuyển: vị trí + vận tốc) → SoA, mỗi trường một mảng. Truy
cập ngẫu nhiên trọn một thực thể (xử lý một gói tin) → AoS. SIMD trên bản ghi nhiều thành phần →
AoSoA khối 4/8 như `SoaFloat3` của math/soa.hpp: mỗi thành phần là một `Vector4` chứa 4 thực thể,
một lần nạp lấy cùng thành phần của cả bốn; `transpose4x4` đổi qua lại AoS ở ranh giới.

- **Vì sao:** với AoS, vòng lặp di chuyển nạp cả bản ghi (tên, kho…) để dùng 16 B. SoA đọc đúng byte
  cần, liền mạch, vector hoá thẳng (SV-01). Đổi AoS ↔ SoA trong vòng lặp nóng tốn shuffle (SV-19).
- **Kiểm:** đếm byte đọc/byte dùng của vòng lặp nóng; báo cáo vector hoá (SV-02).

```cpp
// ✓ SoA cho hệ thống di chuyển: vòng lặp chỉ chạm bốn mảng float cần dùng.
#include "core/check.hpp"

#include <chrono>
#include <cstddef>
#include <vector>

namespace game::sim {

// Bất biến: bốn mảng cùng độ dài — mọi chỗ thêm/xoá thực thể sửa cả bốn; vận tốc tính theo giây.
struct Motion {
    std::vector<float> pos_x;
    std::vector<float> pos_y;
    std::vector<float> vel_x;
    std::vector<float> vel_y;
};

inline void integrate(Motion& motion, std::chrono::duration<float> dt) noexcept {
    const std::size_t count = motion.pos_x.size();
    core::check(motion.pos_y.size() == count && motion.vel_x.size() == count && motion.vel_y.size() == count,
        "integrate: bốn mảng của Motion phải cùng độ dài");
    const float seconds = dt.count();
    for (std::size_t i = 0; i < count; ++i) {
        motion.pos_x[i] += motion.vel_x[i] * seconds;
        motion.pos_y[i] += motion.vel_y[i] * seconds;
    }
}

} // namespace game::sim
```

### BN-07 [C] PHẢI — Tách trường nóng (đọc mỗi tick) khỏi trường lạnh thành hai mảng song song cùng chỉ số

Nóng: vị trí, máu, trạng thái, mục tiêu. Lạnh: tên, guild, thống kê, dữ liệu chỉ dùng khi lưu DB.
`hot[i]` và `cold[i]` là cùng một thực thể; bản ghi nóng nhỏ (≤ 32–64 B), có `static_assert` cỡ.

- **Vì sao:** vài `std::string` (32 B mỗi cái với libstdc++) trong bản ghi nóng làm mỗi dòng cache
  chứa ít thực thể hơn hẳn; mọi hệ thống tick trả băng thông cho byte không dùng.
- **Kiểm:** `static_assert(sizeof(EntityHot) …)`; review mỗi lần thêm trường vào bản ghi nóng.

```cpp
// ✓ Bản ghi nóng 16 B; phần lạnh ở mảng song song, cùng chỉ số.
#include <cstdint>
#include <string>

namespace game::world {

struct EntityHot {
    float pos_x = 0.0F;
    float pos_y = 0.0F;
    std::int32_t hp = 0;
    std::uint32_t target = 0;
};

struct EntityCold {
    std::string name;
    std::string guild;
    std::uint64_t kills = 0;
};

static_assert(sizeof(EntityHot) == 16, "bản ghi nóng phình: tách trường mới sang EntityCold?");

} // namespace game::world
```

### BN-08 [C] PHẢI — Căn lề bằng `alignas` trên kiểu với hằng dự án `kCacheLine = 64`; không dùng `std::hardware_destructive_interference_size` trong header hay struct thuộc ABI

Khối SIMD (16 B SSE, 32 B AVX), dữ liệu mỗi luồng ghi riêng: `struct alignas(N) …` + `static_assert`.
`std::vector<T>` với `alignof(T) > alignof(std::max_align_t)` tự dùng `operator new(size,
std::align_val_t)` (C++17) — không cần tự căn bằng số học con trỏ. Dữ liệu lưu/mạng không căn: `loadu`
(SV-09). False sharing chi tiết: DT-10. Một số thư viện chọn 128 B trên x86 vì bộ prefetch dòng kề của
Intel kéo cặp dòng — đổi hằng thì đo.

- **Vì sao:** `malloc` chỉ bảo đảm `alignof(std::max_align_t)` (16 trên x86-64 Linux). Giá trị
  `std::hardware_destructive_interference_size` đổi theo `-mtune`/phiên bản: dùng trong header thì
  hai TU biên dịch khác cờ thấy hai bố cục — vi phạm ODR âm thầm. Đã kiểm: GCC 14/15 cảnh báo
  `-Winterference-size` khi nó được dùng trong header được include (không cảnh báo ở file chính),
  Clang 20 im lặng; cả ba thư viện cho 64 trên x86-64.
- **Kiểm:** `static_assert(sizeof/alignof …)`; `-Winterference-size` (GCC, mặc định bật);
  `-Wcast-align`. Nghi false sharing: `perf c2c record -- ./bench` rồi `perf c2c report --stdio`, xem
  cột HITM (nạp trúng dòng đang Modified ở cache lõi khác) và offset từng trường.

```cpp
// ✓ Hằng cố định của dự án; mỗi luồng IO ghi bộ đếm trên dòng cache riêng.
#include <atomic>
#include <cstddef>
#include <cstdint>

namespace game::net {

inline constexpr std::size_t kCacheLine = 64;

struct alignas(kCacheLine) IoCounters {
    std::atomic<std::uint64_t> packets{0};
    std::atomic<std::uint64_t> bytes{0};
};

static_assert(sizeof(IoCounters) == kCacheLine && alignof(IoCounters) == kCacheLine);

} // namespace game::net
```

### BN-09 [C] NÊN — Dữ liệu tạm sống trong một tick dùng arena `std::pmr::monotonic_buffer_resource`, reset cuối tick

Arena cấp phát bằng cách tăng con trỏ, không giải phóng lẻ; `release()` trả về buffer ban đầu (đã
kiểm libstdc++ 14 và libc++ 20: địa chỉ cấp lại trùng nhau qua các tick). Upstream
`std::pmr::null_memory_resource()`: vượt ngân sách là `bad_alloc` (coi là chết — LH-07) thay vì lặng
lẽ rơi về heap. Cấp phát nhỏ, giải phóng lẻ, một luồng: `std::pmr::unsynchronized_pool_resource`. Vòng
đời con trỏ vào arena: SH-16.

- **Vì sao:** cấp trong arena là vài lệnh, không khoá, không phân mảnh; reset O(1). Bẫy: mọi
  `std::pmr::vector` dùng arena phải bị huỷ trước `release()` (sau đó con trỏ của chúng treo); move
  giữa hai container khác resource là chép phần tử, không chuyển con trỏ.
- **Kiểm:** ASan trong build test; đếm byte đỉnh mỗi tick để chỉnh cỡ arena.

```cpp
// ✓ Arena theo tick: storage chạm sẵn một lần (vector value-init), vượt ngân sách thì bad_alloc.
#include <cstddef>
#include <memory_resource>
#include <vector>

namespace game::sim {

class TickArena {
public:
    explicit TickArena(std::size_t bytes)
        : storage_(bytes), arena_(storage_.data(), storage_.size(), std::pmr::null_memory_resource()) {}

    [[nodiscard]] std::pmr::memory_resource* resource() noexcept { return &arena_; }

    // Gọi cuối tick, sau khi mọi container dùng arena đã bị huỷ.
    void reset() noexcept { arena_.release(); }

private:
    // khai báo trước arena_: khởi tạo trước, huỷ sau
    std::vector<std::byte> storage_;
    std::pmr::monotonic_buffer_resource arena_;
};

} // namespace game::sim
```

### BN-10 [C] NÊN — Pool cỡ cố định với danh sách tự do nhúng trong slot, liên kết bằng chỉ số

Slot chứa đối tượng và chỉ số slot tự do kế tiếp; `acquire`/`release` O(1), không cấp phát, không
khoá (một luồng sở hữu pool). Giải phóng hai lần và handle cũ: handle thế hệ (MMO).

- **Vì sao:** slot nằm liền trong một mảng (BN-01), dung lượng cố định nên không cấp phát trong tick;
  chỉ số 32 bit (BN-05) giữ danh sách tự do đúng khi tuần tự hoá trạng thái để replay.
- **Kiểm:** test acquire hết rồi release hết; ASan/UBSan.

```cpp
// ✓ Danh sách tự do bằng chỉ số; chỉ số bằng capacity nghĩa là "không còn slot".
#include "core/check.hpp"

#include <cstdint>
#include <optional>
#include <vector>

namespace game::sim {

struct ProjectileSlot {
    float x = 0.0F;
    float y = 0.0F;
    std::uint32_t next_free = 0;
};

class ProjectilePool {
public:
    explicit ProjectilePool(std::uint32_t capacity) : slots_(capacity) {
        for (std::uint32_t i = 0; i < capacity; ++i) {
            slots_[i].next_free = i + 1;
        }
    }

    [[nodiscard]] std::optional<std::uint32_t> acquire() noexcept {
        if (head_ >= slots_.size()) return std::nullopt;
        const std::uint32_t slot = head_;
        head_ = slots_[slot].next_free;
        return slot;
    }

    void release(std::uint32_t slot) noexcept {
        core::check(slot < slots_.size(), "ProjectilePool::release: slot phải thuộc pool");
        slots_[slot].next_free = head_;
        head_ = slot;
    }

private:
    std::vector<ProjectileSlot> slots_;
    std::uint32_t head_ = 0;
};

} // namespace game::sim
```

### BN-11 [C] NÊN — Tập nhỏ có trần đã biết dùng sức chứa cố định trong đối tượng, không heap

Buff trên nhân vật (≤ 16), mục tiêu của một đòn AoE (≤ 32): `std::array<T, N>` + bộ đếm, `push` trả
`bool` khi đầy. Chỉ số lúc chạy đi qua `std::span` trên mảng (`const std::span<T> slots(items_);
slots[i]`): hardening thư viện kiểm biên (UB-08), `cppcoreguidelines-pro-bounds-constant-array-index`
không báo; không `.at()` (ném) trong hàm `noexcept`. `std::string` ngắn có bộ đệm nội bộ: 15 ký tự (libstdc++), 22 (libc++) — đã đo; dài
hơn thì cấp phát. C++26 có `std::inplace_vector`; C++23 tự viết như dưới.

- **Vì sao:** dữ liệu nằm trong bản ghi chủ: không cấp phát, không đuổi con trỏ, chép/lưu nguyên khối.
  Trần là luật game: vượt trần là quyết định nghiệp vụ ở nơi gọi.
- **Kiểm:** `static_assert(sizeof …)`; test đầy/tràn.

```cpp
// ✓ Tối đa 16 buff trong bản ghi nhân vật; đầy thì nơi gọi quyết (thay yếu nhất hay từ chối).
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::combat {

enum class BuffId : std::uint16_t {};
// Mốc thời gian game: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

struct Buff {
    Tick expires{};
    BuffId id{};
    std::uint16_t stacks = 0;
};

class BuffList {
public:
    static constexpr std::size_t kCapacity = 16;

    [[nodiscard]] bool push(Buff buff) noexcept {
        if (count_ == kCapacity) return false;
        // không viết std::span(items_)[i]: đó là khai báo mảng
        const std::span<Buff> slots(items_);
        slots[count_] = buff;
        ++count_;
        return true;
    }

    [[nodiscard]] std::span<const Buff> items() const noexcept { return std::span(items_).first(count_); }

private:
    std::array<Buff, kCapacity> items_{};
    std::size_t count_ = 0;
};

} // namespace game::combat
```

## 3. Thần thoại [T]

### BN-12 [T] CÓ THỂ — Prefetch mềm cho truy cập gián tiếp theo danh sách chỉ số, khoảng cách chọn bằng đo

`__builtin_prefetch(addr, 0, 3)` (GCC/Clang) cho phần tử sẽ dùng sau `kDistance` vòng khi duyệt
`health[ids[i]]` với `ids` rải rác (thành viên ô AOI). Không prefetch duyệt tuần tự: bộ prefetch phần
cứng đã làm, lệnh thừa chỉ tốn cổng nạp.

- **Vì sao:** với truy cập gián tiếp, địa chỉ tương lai đọc được rẻ (`ids[i + d]` liền), nên phát yêu
  cầu sớm để nhiều miss chồng lấp. Quá ngắn: dữ liệu chưa về; quá dài: bị đẩy khỏi cache trước khi
  dùng. Lệnh prefetch không gây lỗi trang, nhưng đọc `ids[i + d]` ngoài mảng là UB — phải kẹp.
- **Kiểm:** benchmark với dữ liệu vượt L2/L3 ở vài khoảng cách; bản không prefetch làm chuẩn trong
  test sai phân; ghi số đo vào comment.

```cpp
// ✓ Kẹp chỉ số nhìn trước; mọi id < health.size() (bộ dựng ô AOI bảo đảm).
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::world {

// chọn bằng đo, ghi máy + cỡ dữ liệu
inline constexpr std::size_t kPrefetchDistance = 8;

// Id thành viên một ô AOI, rải rác trong mảng thành phần; bộ dựng ô bảo đảm mọi id hợp lệ.
using CellMembers = std::span<const std::uint32_t>;

[[nodiscard]] inline std::int64_t total_hp(std::span<const std::int32_t> health, CellMembers ids) noexcept {
    std::int64_t total = 0;
    const std::size_t count = ids.size();
    for (std::size_t i = 0; i < count; ++i) {
        const std::size_t ahead = std::min(i + kPrefetchDistance, count - 1);
        __builtin_prefetch(&health[ids[ahead]], 0, 3);
        total += health[ids[i]];
    }
    return total;
}

} // namespace game::world
```

### BN-13 [T] CÓ THỂ — Trang lớn (THP qua `madvise`) cho vùng nhớ lớn, nóng, truy cập ngẫu nhiên

TLB cấp hai có cỡ một đến vài nghìn mục: với trang 4 KiB phủ vài MiB; trang 2 MiB phủ gấp 512 lần.
Vùng lớn (bảng thực thể, lưới AOI, arena) căn 2 MiB, `madvise(MADV_HUGEPAGE)` TRƯỚC lần chạm đầu, rồi
chạm trước (HN-18). Hệ thống đặt `/sys/kernel/mm/transparent_hugepage/enabled` là `madvise`; theo dõi
`defrag` vì gom trang đồng bộ gây khựng.

- **Vì sao:** truy cập ngẫu nhiên trên vài trăm MiB với trang 4 KiB trượt TLB liên tục: mỗi lần là
  một lần duyệt bảng trang (thêm vài lần nạp) chồng lên cache miss. Không đổi ngữ nghĩa: `madvise`
  thất bại thì vẫn chạy với trang 4 KiB.
- **Kiểm:** `perf stat -e dTLB-load-misses,dTLB-loads` trước/sau; `AnonHugePages` trong
  `/proc/<pid>/smaps_rollup`.

```cpp
// ✓ [linux] Xin THP cho vùng đã căn 2 MiB, trước khi chạm.
#include "core/check.hpp"

#include <bit>
#include <cstddef>
#include <cstdint>
#include <span>

#include <sys/mman.h>

namespace game::mem {

inline constexpr std::size_t kHugePageSize = std::size_t{2} << 20U;

// region căn 2 MiB (vd. operator new với std::align_val_t{kHugePageSize}) và CHƯA bị chạm.
[[nodiscard]] inline bool advise_huge(std::span<std::byte> region) noexcept {
    const auto address = std::bit_cast<std::uintptr_t>(region.data());
    core::check(address % kHugePageSize == 0, "advise_huge: region phải căn 2 MiB");
    return madvise(region.data(), region.size(), MADV_HUGEPAGE) == 0;
}

} // namespace game::mem
```

### BN-14 [T] PHẢI — Máy chủ nhiều socket: luồng zone ghim vào một node NUMA và tự dựng, tự chạm dữ liệu của zone

Linux đặt trang vật lý ở node của luồng GHI lần đầu (first-touch). Luồng chính dựng mọi zone rồi
giao cho worker là đặt cả thế giới vào một node. Dựng dữ liệu zone bên trong hàm của luồng zone, sau
khi luồng đã được ghim CPU (hoặc chạy tiến trình bằng `numactl --cpunodebind=N --membind=N`).

- **Vì sao:** truy cập bộ nhớ node khác đi qua liên kết giữa socket: độ trễ cao hơn rõ rệt và tranh
  băng thông liên kết. Lỗi không hiện trên máy dev một socket, chỉ lộ ở máy chủ thật.
- **Kiểm:** `numactl --hardware`; `numastat -p <pid>` xem trang theo node.

```cpp
// ✓ Dữ liệu zone được dựng bên trong luồng zone: first-touch đặt trang ở node của luồng này.
#include <cstddef>
#include <cstdint>
#include <span>
#include <stop_token>
#include <vector>

namespace game::world {

void tick_zone(std::span<std::int32_t> health) noexcept;

inline void run_zone(const std::stop_token& stop, std::size_t entities) {
    // value-init GHI mọi trang ngay trên luồng này
    std::vector<std::int32_t> health(entities, 0);
    while (!stop.stop_requested()) {
        tick_zone(health);
    }
}

} // namespace game::world
```

### BN-15 [T] NÊN — Vòng lặp nhiều dữ liệu, ít phép tính là bound băng thông: giảm byte mỗi thực thể trước khi tối ưu phép tính

Tính byte đọc + ghi mỗi phần tử × số phần tử × tần số tick, so với băng thông một lõi (cỡ chục GB/s
từ DRAM) khi dữ liệu vượt L3. Bound băng thông thì SIMD rộng hơn không giúp; giảm byte: tách
nóng/lạnh (BN-07), lượng tử hoá toạ độ trong pha lọc AOI, chỉ số 32 bit (BN-05), `float` thay
`double`, cờ 1 byte.

- **Vì sao:** cường độ số học thấp (vài phép cộng mỗi 16–64 B) nghĩa là lõi chờ bộ nhớ; cùng thuật
  toán trên dữ liệu nhỏ hơn một nửa chạy nhanh gần gấp đôi, còn tăng làn SIMD thì không đổi gì.
- **Kiểm:** top-down Memory Bound (HN-15); GB/s đạt được so với băng thông máy.

```cpp
// ✓ Pha lọc AOI đọc 8 B mỗi thực thể: chỉ số + toạ độ cục bộ lượng tử 1/8 m (int16).
#include <cmath>
#include <cstdint>

namespace game::world {

struct CellEntry {
    std::uint32_t entity = 0;
    // đơn vị 1/8 m tính từ góc ô
    std::int16_t local_x = 0;
    std::int16_t local_y = 0;
};

static_assert(sizeof(CellEntry) == 8);

// offset trong [0, 4095] m từ góc ô: làm tròn 8 * offset ≤ 32760 nên vừa int16.
[[nodiscard]] inline std::int16_t quantize_eighth(float offset) noexcept {
    return static_cast<std::int16_t>(std::lround(offset * 8.0F));
}

} // namespace game::world
```

### BN-16 [T] CÓ THỂ — Thứ tự Morton (Z-order) cho ô lưới khi truy vấn vùng lân cận chiếm ưu thế

Đánh số ô bằng xen bit của `col` và `row`: ô gần nhau trong 2D phần lớn gần nhau trong bộ nhớ, nên
truy vấn quanh người chơi chạm ít dòng cache/trang hơn thứ tự hàng-trước. Tính bằng mặt nạ "magic
bits" (khả chuyển, constexpr). `_pdep_u32` (BMI2) nhanh trên Intel từ Haswell và AMD từ Zen 3, nhưng
Zen 1/Zen 2 thực thi bằng microcode, chậm hàng chục đến hàng trăm chu kỳ tuỳ mặt nạ.

- **Vì sao:** với hàng-trước, ô ngay phía trên cách `width * sizeof(cell)` byte; truy vấn 3×3 ô chạm
  ba vùng xa nhau. Z-order giữ lân cận 2D thành lân cận 1D ở mọi cấp phóng to.
- **Kiểm:** `static_assert` giá trị đã biết; test vét cạn round-trip với bản giải mã; đo trước/sau.

```cpp
// ✓ Xen bit 16 + 16 → 32 bằng magic bits; static_assert chốt giá trị.
#include <cstdint>

namespace game::world {

// Trải 16 bit thấp của value ra các vị trí bit chẵn.
[[nodiscard]] constexpr std::uint32_t spread_bits(std::uint32_t value) noexcept {
    value &= 0x0000'FFFFU;
    value = (value | (value << 8U)) & 0x00FF'00FFU;
    value = (value | (value << 4U)) & 0x0F0F'0F0FU;
    value = (value | (value << 2U)) & 0x3333'3333U;
    return (value | (value << 1U)) & 0x5555'5555U;
}

[[nodiscard]] constexpr std::uint32_t morton_cell(std::uint32_t col, std::uint32_t row) noexcept {
    return spread_bits(col) | (spread_bits(row) << 1U);
}

static_assert(morton_cell(0, 0) == 0 && morton_cell(1, 0) == 1 && morton_cell(0, 1) == 2);
static_assert(morton_cell(3, 3) == 15 && morton_cell(0xFFFF, 0xFFFF) == 0xFFFF'FFFFU);

} // namespace game::world
```

### BN-17 [T] CÓ THỂ — `__restrict` (không chuẩn) cho hàm lá nóng có hợp đồng "không chồng lấn" đã kiểm

GCC, Clang, MSVC đều nhận `__restrict` trên tham số con trỏ: hứa rằng trong thân hàm, vùng nhớ truy
cập qua con trỏ đó không bị truy cập qua con trỏ khác. Chỉ ở hàm lá nhỏ; nơi gọi giữ span, kiểm biên
và không chồng lấn; test sai phân với bản không `__restrict`.

- **Vì sao:** đã kiểm: cùng vòng lặp `positions[i] += velocities[i] * dt`, GCC 14 -O3 báo bản không
  restrict "loop versioned for vectorization because of possible aliasing" (kiểm chồng lấn + hai bản
  vòng lặp), bản restrict vector hoá thẳng; ở -O2, GCC 15 vector hoá bản restrict, GCC 14 thì không
  (HN-12). Hứa sai là UB: trình dịch dùng giá trị cũ, kết quả sai âm thầm.
- **Kiểm:** test sai phân; `debug_check` không chồng lấn ở nơi gọi.

```cpp
// ✓ Hàm lá nhận con trỏ restrict; nơi gọi (span) bảo đảm biên và không chồng lấn.
#include <chrono>
#include <cstddef>

namespace game::sim {

// Bước thời gian của tick, chung cho mọi trục; integrate là hàm lá, gọi một lần cho mỗi trục.
struct TimeStep {
    std::chrono::duration<float> dt{};

    // NOLINTBEGIN(cppcoreguidelines-pro-bounds-pointer-arithmetic): hàm lá __restrict (BN-17).
    void integrate(float* __restrict positions, const float* __restrict velocities, std::size_t count) const noexcept {
        const float seconds = dt.count();
        for (std::size_t i = 0; i < count; ++i) {
            positions[i] += velocities[i] * seconds;
        }
    }
    // NOLINTEND(cppcoreguidelines-pro-bounds-pointer-arithmetic)
};

} // namespace game::sim
```

## Kiểm nhanh

- [ ] Dữ liệu tick là `vector` giá trị liền, đặc; không list/map/`vector<unique_ptr>`? (BN-01)
- [ ] Struct nóng/mạng/lưu đã sắp thành viên, có `static_assert(sizeof)`, tách trường lạnh? (BN-02, BN-07)
- [ ] Không `vector<bool>` trên đường nóng hay khi nhiều luồng ghi? (BN-03)
- [ ] Lưới 2D phẳng, duyệt theo hàng; liên kết bằng chỉ số 32 bit, không con trỏ? (BN-04, BN-05)
- [ ] Bố cục AoS/SoA/AoSoA theo vòng lặp nóng nhất; căn lề bằng `alignas` + `kCacheLine`? (BN-06, BN-08)
- [ ] Dữ liệu tạm theo tick ở arena; container pmr huỷ trước `release()`? (BN-09)
- [ ] Pool dùng danh sách tự do chỉ số; tập nhỏ có trần dùng sức chứa cố định? (BN-10, BN-11)
- [ ] Prefetch, trang lớn, Z-order, `__restrict` có số đo và test sai phân đi kèm? (BN-12, BN-13, BN-16, BN-17)
- [ ] Máy nhiều socket: dữ liệu zone được dựng trên luồng zone đã ghim? (BN-14)
