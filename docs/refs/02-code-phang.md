# PH · Bảng tra, switch, bất đồng bộ, máy trạng thái

> **Phạm vi:** ánh xạ giá trị bằng bảng, `switch` trên enum, đệ quy, lưới liền, chuỗi bất đồng bộ,
> bỏ nhánh theo số đo, máy trạng thái bằng bảng chuyển. Các quy tắc về độ lồng và hình dạng hàm đã
> gỡ ngày 2026-10-08; quy tắc còn lại giữ nguyên mã. **Đọc khi:** viết `switch` trên enum hay
> opcode; ánh xạ enum sang giá trị; duyệt cây từ dữ liệu ngoài; chuỗi callback DB; máy trạng thái.
> **Liên quan:** refs/05-loi-hop-dong.md (LH-*), refs/07-generic-compile-time.md (GN-*),
> refs/18-game-mmo.md (MMO-*), refs/04-so-huu-vong-doi.md (SH-*), refs/09-hieu-nang.md (HN-*).

## 1. Nền tảng [N]

### PH-06 [N] NÊN — Ánh xạ giá trị và khác biệt giữa các loại là bảng `constexpr`, không phải chuỗi if/switch hay tầng kế thừa

enum → giá trị: `constexpr std::array` chỉ số `std::to_underlying`; ngưỡng (rơi đồ): mảng tăng dần +
`std::ranges::upper_bound`; enum → trường: bảng con trỏ thành viên như `member(i)` (math/types.hpp);
loại quái khác nhau về số: một struct, mỗi loại một hằng — kế thừa tối đa một tầng (giao diện → `final`).

- **Vì sao:** ánh xạ là dữ liệu: khai báo một chỗ, mọi thao tác (buff, lưu DB, gửi gói) dùng chung;
  mỗi switch chép lại là một chỗ quên sửa. Kế thừa sâu là lồng dọc: đọc ba lớp để hiểu `Boss::damage`.
- **Kiểm:** `static_assert` cỡ bảng; `cppcoreguidelines-pro-bounds-constant-array-index`; `final`.

```cpp
// ✗ Mỗi thao tác trên chỉ số là một switch chép lại; thêm chỉ số phải sửa mọi switch.
#include <cstdint>
enum class Stat : std::uint8_t { kStrength, kAgility, kIntellect };
struct Stats { std::int32_t strength = 0; std::int32_t agility = 0; std::int32_t intellect = 0; };
inline void add_stat(Stats& stats, Stat which, std::int32_t delta) noexcept {
    switch (which) {
    case Stat::kStrength: stats.strength += delta; break;
    case Stat::kAgility: stats.agility += delta; break;
    case Stat::kIntellect: stats.intellect += delta; break;
    }
}
```

```cpp
// ✓ Bảng con trỏ thành viên: ánh xạ Stat → trường khai báo một lần, mọi thao tác dùng chung.
#include <array>
#include <cstdint>
#include <utility>

enum class Stat : std::uint8_t { kStrength, kAgility, kIntellect };

struct Stats {
    std::int32_t strength = 0;
    std::int32_t agility = 0;
    std::int32_t intellect = 0;
};

inline constexpr std::array<std::int32_t Stats::*, 3> kStatFields{&Stats::strength, &Stats::agility, &Stats::intellect};
static_assert(kStatFields.size() == std::to_underlying(Stat::kIntellect) + 1U);

// .at() chỉ ném khi Stat hỏng; trong hàm noexcept đó là dừng tiến trình (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
inline void add_stat(Stats& stats, Stat which, std::int32_t delta) noexcept {
    stats.*kStatFields.at(std::to_underlying(which)) += delta;
}
```

### PH-07 [N] PHẢI — `switch` trên enum không `default`; sau switch là `core::fail`; byte từ mạng kiểm miền trước khi ép kiểu

Mỗi enumerator có `case` riêng; byte từ mạng kiểm miền ở biên trước khi ép kiểu.

- **Vì sao:** `default` nuốt cả opcode lạ lẫn opcode mới quên viết case; không `default` thì `-Wswitch`
  (`-Wall` + `-Werror`) dừng biên dịch. Sau switch phủ đủ enum GCC vẫn báo `-Wreturn-type`, Clang thì
  không (đã thử): `core::fail` thoả cả hai và dừng sớm nếu enum hỏng.
- **Kiểm:** `-Wswitch`, `-Wimplicit-fallthrough`; `bugprone-switch-missing-default-case` bỏ qua enum.

```cpp
// ✗ default nuốt cả opcode lạ lẫn opcode quên xử lý; byte thô ép thẳng sang enum.
#include <cstdint>
enum class Opcode : std::uint8_t { kMove, kChat };
enum class Handled : std::uint8_t { kOk, kRejected, kUnknown };
struct Ctx { bool muted = false; std::uint32_t chats = 0; };
Handled on_move(Ctx& ctx) noexcept;
inline Handled dispatch(Ctx& ctx, std::uint8_t raw) noexcept {
    switch (static_cast<Opcode>(raw)) {
    case Opcode::kMove: return on_move(ctx);
    case Opcode::kChat:
        if (ctx.muted) return Handled::kRejected;
        ++ctx.chats;
        return Handled::kOk;
    default: return Handled::kUnknown;
    }
}
```

```cpp
// ✓ Kiểm miền ở biên; không default; core::fail sau switch.
#include "core/check.hpp"

#include <cstdint>
#include <utility>

enum class Opcode : std::uint8_t { kMove, kChat };
enum class Handled : std::uint8_t { kOk, kRejected, kUnknown };

struct Ctx {
    bool muted = false;
    std::uint32_t chats = 0;
};

// Định nghĩa ở net/handlers.cpp.
[[nodiscard]] Handled on_move(Ctx& ctx) noexcept;

[[nodiscard]] inline Handled on_chat(Ctx& ctx) noexcept {
    if (ctx.muted) return Handled::kRejected;
    ++ctx.chats;
    return Handled::kOk;
}

[[nodiscard]] inline Handled dispatch(Ctx& ctx, Opcode opcode) noexcept {
    switch (opcode) {
    case Opcode::kMove: return on_move(ctx);
    case Opcode::kChat: return on_chat(ctx);
    }
    // Chỉ tới khi enum hỏng; GCC -Wreturn-type cũng cần dòng này.
    game::core::fail("dispatch: Opcode ngoài miền");
}

[[nodiscard]] inline Handled dispatch_raw(Ctx& ctx, std::uint8_t raw) noexcept {
    if (raw > std::to_underlying(Opcode::kChat)) return Handled::kUnknown;
    return dispatch(ctx, static_cast<Opcode>(raw));
}
```

### PH-08 [N] CẤM — `goto`, đệ quy

Thoát vòng lồng bằng `return`; cây (túi trong túi) duyệt bằng ngăn xếp tường minh có giới hạn.

- **Vì sao:** đệ quy trên dữ liệu từ client/DB để kẻ tấn công chọn độ sâu ngăn xếp: tràn ngăn xếp
  sập cả máy chủ.
- **Kiểm:** `misc-no-recursion`; `cppcoreguidelines-avoid-goto` bắt mọi `goto` TRỪ nhảy tiến thoát
  vòng lặp lồng (đã thử) — đúng ca hay gặp.

## 2. Nâng cao [C]

### PH-09 [C] PHẢI — Lưới 2D là một mảng liền; láng giềng là bảng offset trên lưới có viền rỗng

`std::vector<std::vector<T>>` thành một mảng liền chỉ số `row * stride + col`. Thêm viền 1 ô luôn rỗng
quanh lưới thì 9 ô láng giềng là 9 offset hằng, không cần kiểm biên.

- **Vì sao:** vector lồng là mỗi hàng một cấp phát, một lần gián tiếp (BN-*). Viền rỗng bỏ được
  phép kiểm biên bốn vế ở từng láng giềng: chín ô thành một vòng thẳng (AOI: MMO-*).
- **Kiểm:** review.

```cpp
// ✗ Lưới vector lồng: mỗi hàng một cấp phát; kiểm biên bốn vế cho từng láng giềng.
#include <cstdint>
#include <vector>
using Grid = std::vector<std::vector<std::uint32_t>>; // [row][col]: số thực thể trong ô, 256 × 256
inline std::uint32_t count_nearby(const Grid& grid, int col, int row) {
    std::uint32_t total = 0;
    for (int step_row = -1; step_row <= 1; ++step_row) {
        for (int step_col = -1; step_col <= 1; ++step_col) {
            if (row + step_row >= 0 && row + step_row < 256 && col + step_col >= 0 && col + step_col < 256) {
                total += grid[row + step_row][col + step_col];
            }
        }
    }
    return total;
}
```

```cpp
// ✓ Một mảng liền có viền rỗng: 9 láng giềng là 9 offset hằng, một vòng thẳng.
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>

// 256 ô mỗi hàng cộng hai cột viền luôn bằng 0.
inline constexpr std::ptrdiff_t kStride = 258;
inline constexpr std::array<std::ptrdiff_t, 9> kNeighbors{
    -kStride - 1, -kStride, -kStride + 1, -1, 0, 1, kStride - 1, kStride, kStride + 1};

// counts: 258 × 258 ô, viền bằng 0; ô (col, row) ở cell = (row + 1) * kStride + col + 1.
[[nodiscard]] inline std::uint32_t count_nearby(std::span<const std::uint32_t> counts, std::ptrdiff_t cell) noexcept {
    std::uint32_t total = 0;
    for (const std::ptrdiff_t offset : kNeighbors) {
        total += counts[static_cast<std::size_t>(cell + offset)];
    }
    return total;
}
```

### PH-10 [C] PHẢI — Chuỗi bất đồng bộ: mỗi bước một hàm có tên, callback chỉ chuyển tiếp

Chuỗi DB → DB → game thành dãy hàm bước (`on_account`…); lambda gửi API bất đồng bộ chỉ gọi bước kế.

- **Vì sao:** callback trong callback lồng một tầng mỗi bước, mỗi tầng chụp thêm trạng thái — nơi sinh
  tham chiếu treo (SH-*). Hàm bước có tên test được bằng cách gọi thẳng với kết quả giả.
- **Kiểm:** review: callback không chụp gì ngoài thứ bước kế cần.

```cpp
// ✗ Callback trong callback: mỗi bước DB thêm một tầng.
#include <cstdint>
#include <functional>
struct Db { void load_account(std::uint32_t id, std::function<void(bool)> done); void load_hero(std::uint32_t id, std::function<void(bool)> done); };
struct Login { std::uint32_t account = 0; std::uint32_t hero = 0; bool ready = false; };
inline void start_login(Db& database, Login& login) {
    database.load_account(login.account, [&database, &login](bool found) {
        if (!found) return;
        database.load_hero(login.hero, [&login](bool loaded) { login.ready = loaded; });
    });
}
```

```cpp
// ✓ Mỗi bước một hàm có tên; lambda chỉ chuyển tiếp sang bước kế.
#include <cstdint>
#include <functional>

// done chạy trên luồng game ở tick sau (DT-*).
struct Db {
    void load_account(std::uint32_t id, std::function<void(bool)> done);
    void load_hero(std::uint32_t id, std::function<void(bool)> done);
};

// Nằm trong bảng phiên tới bước cuối; ngắt kết nối thì huỷ yêu cầu trước (SH-11).
struct Login {
    std::uint32_t account = 0;
    std::uint32_t hero = 0;
    bool ready = false;
};

inline void on_account(Db& database, Login& login, bool found) {
    if (!found) return;
    database.load_hero(login.hero, [&login](bool loaded) { login.ready = loaded; });
}

inline void start_login(Db& database, Login& login) {
    database.load_account(login.account, [&database, &login](bool found) { on_account(database, login, found); });
}
```

## 3. Thần thoại [T]

### PH-11 [T] CÓ THỂ — Bỏ nhánh phụ thuộc dữ liệu (cộng bool, mặt nạ, min/max) khi profiler cho thấy đoán sai nhánh

Chỉ khi `perf` đo `branch-misses` cao ở đúng vòng có điều kiện khó đoán (đúng quanh 50 %). Kỹ thuật:
ghi vô điều kiện, tiến vị trí ghi bằng bool; chọn bằng mặt nạ như `select_mask` (math/vector_int.hpp).
Bản có nhánh giữ làm chuẩn cho test sai phân có seed (KT-*); comment ghi số đo.

- **Vì sao:** đoán sai nhánh tốn cỡ 15–20 chu kỳ trên x86 hiện đại; lọc AOI theo bán kính trúng ngẫu
  nhiên. Mẫu ✓ (GCC 14.2, Clang 20.1 `-O2`, đã đọc asm): thân vòng chỉ còn `cmp` + `setcc` + `add`,
  nhánh duy nhất là nhánh lặp. Trình dịch tự làm vậy cho `std::min` (`cmov`), không khi có `push_back`.
- **Kiểm:** `perf stat -e branch-misses`; đọc asm; test sai phân với bản tham chiếu.

```cpp
// ✗ Nhánh theo dữ liệu, tỉ lệ trúng ngẫu nhiên nên đoán sai liên tục.
#include <cstdint>
#include <span>
#include <vector>
inline void gather_in_range(std::span<const std::int64_t> dist_sq, std::int64_t radius_sq, std::vector<std::uint32_t>& out) {
    for (std::uint32_t i = 0; i < dist_sq.size(); ++i) {
        if (dist_sq[i] <= radius_sq) {
            out.push_back(i);
        }
    }
}
```

```cpp
// ✓ Nén chỉ số không nhánh: ghi vô điều kiện, tiến vị trí ghi bằng bool.
#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

// Chỉ số thực thể trong mảng thành phần; bộ đệm do nơi gọi giữ và tái dùng qua các tick.
using EntityIndices = std::vector<std::uint32_t>;

// Nối vào out mọi i có dist_sq[i] <= radius_sq, như bản có nhánh. Ghi số đo tại đây.
inline void gather_in_range(std::span<const std::int64_t> dist_sq, std::int64_t radius_sq, EntityIndices& out) {
    std::size_t count = out.size();
    // Đủ chỗ cả khi mọi thực thể trúng.
    out.resize(count + dist_sq.size());
    for (std::uint32_t i = 0; i < dist_sq.size(); ++i) {
        out[count] = i;
        count += static_cast<std::size_t>(dist_sq[i] <= radius_sq);
    }
    out.resize(count);
}
```

### PH-12 [T] NÊN — Máy trạng thái phiên là bảng chuyển `constexpr` + hàm `step` tra bảng; bất biến kiểm bằng `static_assert`

Hàng = trạng thái, cột = sự kiện, mọi ô ghi tường minh (sai thứ tự → `kClosed`); bất biến là `static_assert`.

- **Vì sao:** switch(trạng thái) chứa if(sự kiện) giấu các cặp bỏ qua sau `break`. Bảng
  buộc quyết định từng ô, kiểm lúc biên dịch; bảng 16 B; `step` là một phép tra có kiểm biên, không
  chuỗi so sánh.
- **Kiểm:** `static_assert` trên bảng; test duyệt đủ trạng thái × sự kiện (KT-*).

```cpp
// ✗ switch(trạng thái) chứa if(sự kiện): các cặp bị bỏ qua giấu sau break.
#include <cstdint>
enum class State : std::uint8_t { kAuth, kLobby, kWorld, kClosed };
enum class Event : std::uint8_t { kLoginOk, kEnterWorld, kLeaveWorld, kDisconnect };
inline State step(State state, Event event) noexcept {
    switch (state) {
    case State::kAuth: if (event == Event::kLoginOk) return State::kLobby; break;
    case State::kLobby: if (event == Event::kEnterWorld) return State::kWorld; break;
    case State::kWorld: if (event == Event::kLeaveWorld) return State::kLobby; break;
    case State::kClosed: break;
    }
    return State::kClosed;
}
```

```cpp
// ✓ Bảng chuyển constexpr: mọi cặp (trạng thái, sự kiện) quyết định tường minh.
#include <algorithm>
#include <array>
#include <cstdint>
#include <utility>

enum class State : std::uint8_t { kAuth, kLobby, kWorld, kClosed };
enum class Event : std::uint8_t { kLoginOk, kEnterWorld, kLeaveWorld, kDisconnect };
// Một cột cho mỗi Event, theo thứ tự khai báo.
using Row = std::array<State, 4>;

// Hàng theo thứ tự State: kAuth, kLobby, kWorld, kClosed.
inline constexpr std::array<Row, 4> kTransitions = {{
    {State::kLobby, State::kClosed, State::kClosed, State::kClosed},
    {State::kClosed, State::kWorld, State::kClosed, State::kClosed},
    {State::kClosed, State::kClosed, State::kLobby, State::kClosed},
    {State::kClosed, State::kClosed, State::kClosed, State::kClosed},
}};
// kClosed là trạng thái cuối: mọi sự kiện giữ nguyên kClosed.
static_assert(std::ranges::count(kTransitions.back(), State::kClosed) == 4);

// .at() chỉ ném khi enum hỏng; trong hàm noexcept đó là dừng tiến trình (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
[[nodiscard]] constexpr State step(State state, Event event) noexcept {
    return kTransitions.at(std::to_underlying(state)).at(std::to_underlying(event));
}
```

## Kiểm nhanh

- [ ] Ánh xạ giá trị là bảng `constexpr` có `static_assert` cỡ; kế thừa ≤ 1 tầng? (PH-06)
- [ ] `switch` trên enum không `default`, `core::fail` sau switch, byte từ mạng kiểm miền trước? (PH-07)
- [ ] Không `goto`, không đệ quy; chuỗi bất đồng bộ mỗi bước một hàm có tên? (PH-08, PH-10)
- [ ] Bản không nhánh có số đo trong comment và bản tham chiếu trong test? (PH-11)
