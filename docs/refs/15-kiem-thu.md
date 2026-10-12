# KT · Kiểm thử

> **Phạm vi:** khung test thuần C++ của dự án; unit test, ca biên, test `constexpr`; tất định (seed,
> đồng hồ giả); test thuộc tính, golden, fuzz libFuzzer, stress TSan, death test; harness benchmark;
> test sai phân, replay, vét cạn, fuzz có cấu trúc, ma trận thư viện chuẩn, test vi phạm hợp đồng lúc
> biên dịch. **Đọc khi:** viết hay sửa bất kỳ hàm nào có logic; sửa một lỗi; viết parser gói tin;
> viết code đa luồng; tối ưu (cần benchmark) hay viết bản SIMD/ước lượng; cần tái hiện lệch trạng
> thái giữa máy chủ và replay; thêm `core::check`.
> **Liên quan:** refs/05-loi-hop-dong.md (LH-02, LH-03, LH-16), refs/13-ub-on-dinh.md (UB-04,
> UB-07, UB-16), refs/09-hieu-nang.md (HN-07 phương pháp benchmark), refs/12-dong-thoi.md (DT-07
> chính sách TSan), refs/14-build-toolchain.md (BD-*: preset, ctest), refs/18-game-mmo.md (MMO-*).

## 1. Nền tảng [N]

### KT-01 [N] PHẢI — Test là chương trình C++ thuần trên khung tối giản của dự án: bảng test `constexpr`, `expect` ghi `source_location`

Dự án không dùng thư viện ngoài, nên khung test là ~40 dòng dưới đây (đặt ở `tests/test.hpp`). Mỗi
module một binary test, đăng ký với CTest (BD-*). Test là hàm `void(Context&)`; mỗi tệp test xuất
một bảng `constexpr std::array<Case, N>`; `main` gom các bảng. `expect` ghi lỗi và chạy tiếp; vi
phạm hợp đồng (`core::check`) vẫn dừng ngay — đúng ý.

- **Vì sao:** bảng `constexpr` thay cho đăng ký bằng biến toàn cục có constructor: không phụ thuộc
  thứ tự khởi tạo tĩnh, và không bị linker bỏ — tệp đối tượng chỉ chứa biến tự đăng ký nằm trong thư
  viện tĩnh sẽ không được kéo vào nếu không ai tham chiếu nó. `source_location` cho file:dòng mà không
  cần macro. Không dừng ở kỳ vọng sai đầu tiên: một lần chạy CI thấy hết.
- **Kiểm:** CTest chạy mọi binary test trong mọi preset (KT-07); binary trả khác 0 khi có lỗi.

```cpp
// ✓ [chạy] Khung test tối giản: bảng test constexpr, expect ghi file:dòng, đếm lỗi thay vì dừng.
#include "core/check.hpp"

#include <array>
#include <cstdint>
#include <cstdio>
#include <span>
#include <string_view>

namespace game::test {

// Dùng lại alias của core/check.hpp thay vì khai lại: một khái niệm chỉ khai một chỗ.
using core::Message;
using core::Site;

class Context {
public:
    void expect(bool condition, Message what, Site where = Site::current()) noexcept {
        if (condition) return;
        ++failures_;
        // NOLINTNEXTLINE(google-runtime-int): %lu của fprintf đòi đúng unsigned long (KG-03).
        const auto line = static_cast<unsigned long>(where.line());
        // fprintf thay std::print (lệch STD-04): như check.hpp, không kéo <format> vào mọi test.
        // In "tệp:dòng: [tên ca] thông báo" theo từng mảnh, như check_failed của check.hpp.
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
        static_cast<void>(std::fprintf(stderr, "%s:%lu: [", where.file_name(), line));
        static_cast<void>(std::fwrite(current_.data(), 1, current_.size(), stderr));
        static_cast<void>(std::fputs("] ", stderr));
        static_cast<void>(std::fwrite(what.data(), 1, what.size(), stderr));
        static_cast<void>(std::fputc('\n', stderr));
    }
    void begin(std::string_view name) noexcept { current_ = name; }
    [[nodiscard]] std::int32_t failures() const noexcept { return failures_; }

private:
    std::string_view current_;
    std::int32_t failures_ = 0;
};

struct Case {
    std::string_view name;
    void (*body)(Context&) = nullptr;
};

[[nodiscard]] inline std::int32_t run_all(std::span<const Case> cases) noexcept {
    Context context;
    for (const Case& one : cases) {
        context.begin(one.name);
        one.body(context);
    }
    return context.failures();
}

// --- Một tệp test dùng khung ---
[[nodiscard]] constexpr std::int32_t after_damage(std::int32_t health, std::int32_t damage) noexcept {
    // damage không âm thì health - damage không tràn.
    core::check(damage >= 0, "after_damage: damage phải không âm");
    return health > damage ? health - damage : 0;
}

inline void damage_beyond_health_leaves_zero(Context& context) noexcept {
    context.expect(after_damage(10, 25) == 0, "kẹp về 0");
    context.expect(after_damage(10, 10) == 0, "đúng bằng máu");
    context.expect(after_damage(10, 9) == 1, "còn 1");
}

inline constexpr std::array kCombatCases{
    Case{.name = "damage_beyond_health_leaves_zero", .body = &damage_beyond_health_leaves_zero},
};

} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCombatCases) == 0, "có test thất bại");
    return 0;
}
```

### KT-02 [N] PHẢI — Logic là hàm thuần có unit test; mỗi test một hành vi, tên dạng `<chủ thể>_<tình huống>_<kết quả>`

Tách quyết định (thuần: vào → ra) khỏi tác dụng phụ (IO, DB, mạng, đồng hồ) để test không cần dựng
máy chủ. Tên test là câu đặc tả: `split_stack_whole_stack_is_rejected`, không `test_split_2`.

- **Vì sao:** test đỏ có tên tốt nói ngay hành vi nào hỏng, không cần mở code. Một hành vi mỗi test:
  test đỏ chỉ ra đúng một nguyên nhân. Hàm thuần test được với mọi đầu vào, kể cả ca biên mà dựng
  bằng máy chủ thật thì không với tới.
- **Kiểm:** review tên test; độ phủ nhánh (`--coverage`/`-fprofile-instr-generate`) cho module lõi.

```cpp
// ✓ [chạy] Lõi thuần nên test không cần máy chủ; mỗi test một hành vi, tên đọc như đặc tả.
#include "core/check.hpp"

#include <cstdint>
#include <optional>

namespace game::inv {

struct Stack {
    std::uint32_t item_id = 0;
    std::int32_t count = 0;
};

// Tách count vật phẩm thành chồng mới; chồng cũ phải còn ít nhất một.
[[nodiscard]] constexpr std::optional<Stack> split_stack(Stack& from, std::int32_t count) noexcept {
    if (count <= 0 || count >= from.count) return std::nullopt;
    from.count -= count;
    return Stack{.item_id = from.item_id, .count = count};
}

} // namespace game::inv

namespace game::test {

inline void split_stack_moves_requested_count() noexcept {
    inv::Stack potions{.item_id = 7, .count = 10};
    const auto moved = inv::split_stack(potions, 3);
    core::check(moved && moved->count == 3 && potions.count == 7, "tách 3 khỏi 10");
}

inline void split_stack_whole_stack_is_rejected() noexcept {
    inv::Stack potions{.item_id = 7, .count = 10};
    core::check(!inv::split_stack(potions, 10) && potions.count == 10, "cả chồng: từ chối, giữ nguyên");
}

} // namespace game::test

int main() {
    game::test::split_stack_moves_requested_count();
    game::test::split_stack_whole_stack_is_rejected();
    return 0;
}
```

### KT-03 [N] PHẢI — Mỗi hàm có bảng ca biên viết thành dữ liệu; vòng lặp test chỉ gọi hàm kiểm một ca

| Miền | Ca bắt buộc |
|---|---|
| Số nguyên | 0, 1, -1, min, max, min+1, max-1, đúng ngưỡng và ngưỡng ±1 |
| Số thực | ±0, NaN, ±vô cùng, số không chuẩn nhỏ nhất, max, ngưỡng và số `float` liền kề |
| Kích thước, chỉ số | rỗng, 1 phần tử, đúng dung lượng, dung lượng + 1 |
| Chuỗi | rỗng, đúng độ dài tối đa, tối đa + 1, UTF-8 nhiều byte, có `'\0'` giữa chuỗi |
| Tick, thời gian | tick 0, đúng thời điểm hết hạn, trước một tick, sau một tick |

- **Vì sao:** lỗi nằm ở biên: `<` thay `<=`, NaN lọt qua, tràn ở max. Bảng dữ liệu thêm ca chỉ bằng
  một dòng, đọc như đặc tả.
- **Kiểm:** review: mỗi miền đầu vào của hàm có đủ dòng theo bảng trên.

```cpp
// ✓ [chạy] Bảng ca biên cho kiểm tốc độ chống gian lận: NaN, vô cùng, -0, số không chuẩn.
#include "core/check.hpp"

#include <array>
#include <limits>

namespace game::sim {

// Mét mỗi tick.
inline constexpr float kMaxStep = 0.5F;

// Bước di chuyển client gửi: không âm, không quá kMaxStep; NaN làm cả hai phép so sai.
[[nodiscard]] constexpr bool step_allowed(float step) noexcept {
    return step >= 0.0F && step <= kMaxStep;
}

} // namespace game::sim

namespace game::test {

struct StepCase {
    float step = 0.0F;
    bool allowed = false;
};

inline constexpr float kTiny = std::numeric_limits<float>::denorm_min();
inline constexpr std::array kStepCases{
    StepCase{.step = 0.0F, .allowed = true},
    StepCase{.step = -0.0F, .allowed = true},
    StepCase{.step = kTiny, .allowed = true},
    StepCase{.step = 0.5F, .allowed = true},
    StepCase{.step = 0.500'001F, .allowed = false},
    StepCase{.step = -kTiny, .allowed = false},
    StepCase{.step = std::numeric_limits<float>::quiet_NaN(), .allowed = false},
    StepCase{.step = std::numeric_limits<float>::infinity(), .allowed = false},
};

inline void check_step(const StepCase& one) noexcept {
    core::check(sim::step_allowed(one.step) == one.allowed, "step_allowed sai ở một ca biên");
}

} // namespace game::test

int main() {
    for (const auto& one : game::test::kStepCases) {
        game::test::check_step(one);
    }
    return 0;
}
```

### KT-04 [N] PHẢI — Hàm `constexpr` được test bằng `static_assert` trên bảng ca; hàm có `if consteval` test cả đường chạy

- **Vì sao:** test chạy mỗi lần biên dịch, không tốn gì lúc chạy, và UB ở ca biên là lỗi biên dịch
  (UB-16). Hàm có `if consteval` hay `std::is_constant_evaluated()` có hai đường khác nhau:
  `static_assert` chỉ thử đường hằng, nên vẫn cần test lúc chạy cho đường kia.
- **Kiểm:** mỗi hàm `constexpr` có khối `static_assert` cạnh nó hoặc trong tệp test.

```cpp
// ✓ Cỡ varint (LEB128) test lúc biên dịch bằng bảng: build đỏ khi sai một ca.
#include <algorithm>
#include <array>
#include <bit>
#include <cstdint>

namespace game::proto {

// Số byte LEB128 của một số 32 bit: 1..5.
[[nodiscard]] constexpr std::int32_t varint_size(std::uint32_t value) noexcept {
    const std::int32_t bits = 32 - std::countl_zero(value | 1U);
    return (bits + 6) / 7;
}

struct SizeCase {
    std::uint32_t value = 0;
    std::int32_t size = 0;
};

inline constexpr auto kSizeCases = std::to_array<SizeCase>({
    {.value = 0, .size = 1},
    {.value = 127, .size = 1},
    {.value = 128, .size = 2},
    {.value = 16'383, .size = 2},
    {.value = 16'384, .size = 3},
    {.value = 0xFFFF'FFFFU, .size = 5},
});

static_assert(std::ranges::all_of(kSizeCases, [](SizeCase one) { return varint_size(one.value) == one.size; }));

} // namespace game::proto
```

### KT-05 [N] PHẢI — Test tất định: thời gian và ngẫu nhiên là tham số; seed cố định, in ra khi đỏ

Code nhận tick hiện tại và bộ sinh ngẫu nhiên làm tham số (nguồn thời gian tiêm vào: KTR-*); test
truyền giá trị dựng sẵn. Cấm trong test: `std::random_device`, `system_clock`/`steady_clock::now()`
trong logic, thứ tự duyệt `unordered_*` (KT-19), địa chỉ con trỏ làm khoá sắp xếp.

- **Vì sao:** test không tất định đỏ ngẫu nhiên, người ta tắt nó, và lỗi thật trốn sau. Cùng seed,
  cùng tick thì cùng kết quả: test đỏ tái hiện được trên máy bất kỳ.
- **Kiểm:** chạy mỗi test hai lần liên tiếp trong CI, kết quả phải trùng; grep `random_device`,
  `::now()` trong `tests/`.

```cpp
// ✓ [chạy] Tick và PRNG là tham số: test dựng đúng biên hết hạn và chuỗi chí mạng lặp lại y hệt.
#include "core/check.hpp"

#include <cstdint>

namespace game::combat {

// splitmix64: nhỏ, tất định, giống nhau trên mọi nền tảng (MMO-*).
struct SplitMix64 {
    std::uint64_t state = 0;

    [[nodiscard]] std::uint64_t next() noexcept {
        state += 0x9E37'79B9'7F4A'7C15ULL;
        std::uint64_t mixed = (state ^ (state >> 30U)) * 0xBF58'476D'1CE4'E5B9ULL;
        mixed = (mixed ^ (mixed >> 27U)) * 0x94D0'49BB'1331'11EBULL;
        return mixed ^ (mixed >> 31U);
    }
};

// Mốc thời gian game: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

// Còn hiệu lực ở mọi tick trước expires; tới đúng expires là hết.
[[nodiscard]] constexpr bool buff_active(Tick expires, Tick now) noexcept {
    return now < expires;
}

// Chí mạng 1/8: ba bit cao bằng 0.
[[nodiscard]] inline bool roll_crit(SplitMix64& rng) noexcept {
    return (rng.next() >> 61U) == 0;
}

} // namespace game::combat

int main() {
    using game::combat::buff_active;
    using game::combat::Tick;
    constexpr Tick kExpires{600};
    game::core::check(buff_active(kExpires, Tick{599}) && !buff_active(kExpires, kExpires), "hết hạn đúng tick 600");
    // Seed của test: đổi seed là đổi kết quả mong đợi.
    game::combat::SplitMix64 rng{.state = 42};
    std::int32_t crits = 0;
    for (std::int32_t i = 0; i < 800; ++i) {
        crits += game::combat::roll_crit(rng) ? 1 : 0;
    }
    game::core::check(crits == 107, "chuỗi chí mạng của seed 42 đã đổi");
    return 0;
}
```

### KT-06 [N] CẤM — `sleep` trong test; tua đồng hồ giả, hoặc chờ sự kiện có hạn chót

Logic theo thời gian test bằng đồng hồ giả tua tới đúng biên. Test buộc phải có luồng chờ sự kiện
(`std::latch`, future, biến điều kiện có vị từ) với hạn chót rộng chỉ để test treo thì đỏ thay vì
treo CI (KT-12).

- **Vì sao:** `sleep_for(30s)` để thử ngắt phiên rảnh làm bộ test chậm 30 s; `sleep_for(100ms)` "cho luồng
  kia kịp chạy" đỏ ngẫu nhiên trên máy CI bận (dưới TSan còn chậm 5–15 lần) — test thất thường.
- **Kiểm:** grep `sleep_for`, `sleep_until`, `usleep` trong `tests/` phải rỗng.

```cpp
// ✓ [chạy] Phiên rảnh 30 s bị ngắt: test tua đồng hồ giả tới đúng biên, không ngủ giây nào.
#include "core/check.hpp"

#include <chrono>

namespace game::net {

// Hạn của phiên mạng đo bằng đồng hồ thật, không phải thời gian game (tick: MMO-03); now do vỏ
// truyền vào (KTR-07).
using Clock = std::chrono::steady_clock;
inline constexpr std::chrono::seconds kIdleTimeout{30};

[[nodiscard]] inline bool is_idle(Clock::time_point last_seen, Clock::time_point now) noexcept {
    return now - last_seen >= kIdleTimeout;
}

} // namespace game::net

int main() {
    using game::net::is_idle;
    // Mốc giả, không phải now().
    const game::net::Clock::time_point last_seen{};
    const auto almost = last_seen + game::net::kIdleTimeout - std::chrono::nanoseconds{1};
    game::core::check(!is_idle(last_seen, almost), "chưa đủ 30 s");
    game::core::check(is_idle(last_seen, last_seen + game::net::kIdleTimeout), "đúng 30 s");
    return 0;
}
```

### KT-07 [N] PHẢI — Mọi test chạy trong ma trận: GCC + libstdc++ và Clang + libc++, dưới ASan + UBSan; test có luồng thêm TSan

| Job CI | Trình dịch | Cờ | Chạy |
|---|---|---|---|
| gcc-asan | GCC 14 | ASan + UBSan + `float-cast-overflow` (UB-07) | mọi test |
| clang-asan | Clang 20 + libc++ | ASan + UBSan | mọi test |
| clang-tsan | Clang 20 | TSan | test có luồng (KT-12, DT-07) |
| gcc-release | GCC 14, `-O2` như bản phát hành | hardening (UB-08) | mọi test + test vét cạn (KT-17), benchmark (KT-13) |
| fuzz | Clang 20 | `-fsanitize=fuzzer,address,undefined` | mỗi harness 5 phút trên corpus (KT-11) |

- **Vì sao:** hai thư viện chuẩn khác nhau ở thứ unspecified (KT-19); sanitizer bắt UB mà test
  "xanh" vẫn mang. Test vét cạn dưới ASan chậm cả chục lần nên chạy ở job gcc-release.
- **Kiểm:** preset CMake cho từng job (BD-*); merge bị chặn khi job nào đỏ. Máy dev Windows:
  `check.py --run` chạy Clang + STL MSVC dưới sanitizer và GCC + libstdc++ ở debug mode (CL-02).

```bash
# Cục bộ trước khi đẩy: hai preset ASan của ma trận (BD-04, BD-12), rồi test có luồng dưới TSan.
cmake --preset gcc-asan && cmake --build --preset gcc-asan && ctest --preset gcc-asan
cmake --preset clang-asan && cmake --build --preset clang-asan && ctest --preset clang-asan
cmake --preset clang-tsan && cmake --build --preset clang-tsan && ctest --preset clang-tsan -L threads
```

### KT-08 [N] PHẢI — Mỗi lỗi sửa kèm test hồi quy dùng đúng đầu vào gây lỗi, tên theo hành vi, ghi mã sự cố

- **Vì sao:** lỗi đã xảy ra một lần là lỗi có đường tái phát; test với đúng byte đã làm sập (lấy từ
  fuzz, log, core dump) chặn nó vĩnh viễn. Mã sự cố nối test với bối cảnh.
- **Kiểm:** review: PR sửa lỗi phải thêm test đỏ trước bản sửa, xanh sau bản sửa.

```cpp
// ✓ [chạy] Gói đã làm sập máy chủ thành test vĩnh viễn, kèm mã sự cố.
#include "core/check.hpp"

#include <array>
#include <cstddef>
#include <optional>
#include <span>

namespace game::proto {

// Gói chat: [độ dài u8][thân].
[[nodiscard]] inline std::optional<std::span<const std::byte>> decode_chat(std::span<const std::byte> packet) noexcept {
    if (packet.empty()) return std::nullopt;
    const auto length = std::to_integer<std::size_t>(packet.front());
    if (length > packet.size() - 1) return std::nullopt;
    return packet.subspan(1, length);
}

} // namespace game::proto

namespace game::test {

// Sự cố #1423: khai 255 byte, gửi 2; bản cũ đọc quá biên (ASan: heap-buffer-overflow).
inline constexpr std::array kIssue1423{std::byte{0xFF}, std::byte{'h'}, std::byte{'i'}};

inline void decode_chat_length_beyond_packet_is_rejected_issue_1423() noexcept {
    core::check(!proto::decode_chat(kIssue1423), "độ dài khai vượt gói phải bị từ chối");
}

} // namespace game::test

int main() {
    game::test::decode_chat_length_beyond_packet_is_rejected_issue_1423();
    return 0;
}
```

## 2. Nâng cao [C]

### KT-09 [C] PHẢI — Bất biến kiểm bằng test thuộc tính: đầu vào sinh từ seed cố định, thuộc tính như round-trip `decode(encode(x)) == x`

Thuộc tính hay dùng: round-trip mã hoá; giao dịch thất bại thì trạng thái y nguyên (LH-12); tổng
vật phẩm bảo toàn; kết quả không phụ thuộc thứ tự đầu vào. Bộ sinh trộn ca biên (0, -1, max) với giá
trị ngẫu nhiên; khi đỏ in seed và số lần lặp để tái hiện.

- **Vì sao:** người viết test chỉ nghĩ ra ca mình đã nghĩ tới; 10 000 ca sinh ngẫu nhiên tìm ra tổ
  hợp lạ (dấu âm ở trường 16 bit, bit cao) với chi phí vài ms.
- **Kiểm:** mỗi cặp encode/decode có test round-trip; mỗi thao tác giao dịch có test "thất bại thì
  không đổi".

```cpp
// ✓ [chạy] Round-trip 10 000 lệnh di chuyển ngẫu nhiên từ seed cố định.
#include "core/check.hpp"

#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <type_traits>

namespace game::proto {

struct Move {
    std::uint32_t entity = 0;
    std::int16_t dx = 0;
    std::int16_t dy = 0;
    friend constexpr bool operator==(const Move&, const Move&) = default;
};

static_assert(std::has_unique_object_representations_v<Move> && sizeof(Move) == 8);
static_assert(std::endian::native == std::endian::little, "dây little-endian, chép thẳng");

using Wire = std::array<std::byte, 8>;

[[nodiscard]] inline Wire encode(const Move& move) noexcept {
    Wire out{};
    std::memcpy(out.data(), &move.entity, 4);
    std::memcpy(&out[4], &move.dx, 2);
    std::memcpy(&out[6], &move.dy, 2);
    return out;
}

[[nodiscard]] inline Move decode(const Wire& wire) noexcept {
    Move move{};
    std::memcpy(&move.entity, wire.data(), 4);
    std::memcpy(&move.dx, &wire[4], 2);
    std::memcpy(&move.dy, &wire[6], 2);
    return move;
}

} // namespace game::proto

int main() {
    // Seed cố định; thông điệp lỗi nêu nó để tái hiện.
    std::uint64_t state = 0x5EED;
    for (std::int32_t i = 0; i < 10'000; ++i) {
        state = (state * 6'364'136'223'846'793'005ULL) + 1'442'695'040'888'963'407ULL;
        // Cả 8 byte của Move đều lấy từ trạng thái PRNG.
        const auto move = std::bit_cast<game::proto::Move>(state);
        game::core::check(game::proto::decode(game::proto::encode(move)) == move, "round-trip, seed 0x5EED");
    }
    return 0;
}
```

### KT-10 [C] PHẢI — Mỗi loại gói tin có golden test: byte mong đợi viết tay trong test

- **Vì sao:** round-trip (KT-09) chỉ chứng minh encode và decode khớp NHAU: cả hai cùng sai (đảo
  endian, đổi thứ tự trường) vẫn xanh, nhưng client cũ thì vỡ. Golden chốt định dạng dây; đổi định
  dạng phải sửa golden và tăng phiên bản giao thức có chủ ý (MMO-*).
- **Kiểm:** mỗi opcode có ít nhất một golden; review: diff golden đi cùng thay đổi phiên bản.

```cpp
// ✓ [chạy] Golden: Move{42, -1, 3} phải ra đúng 8 byte này trên dây, mọi trình dịch, mọi máy.
#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace game::proto {

struct Move {
    std::uint32_t entity = 0;
    std::int16_t dx = 0;
    std::int16_t dy = 0;
};

static_assert(std::endian::native == std::endian::little, "dây little-endian, chép thẳng");

[[nodiscard]] inline std::array<std::byte, 8> encode(const Move& move) noexcept {
    std::array<std::byte, 8> out{};
    std::memcpy(out.data(), &move.entity, 4);
    std::memcpy(&out[4], &move.dx, 2);
    std::memcpy(&out[6], &move.dy, 2);
    return out;
}

} // namespace game::proto

int main() {
    constexpr auto kGolden = std::to_array<std::uint8_t>({0x2A, 0, 0, 0, 0xFF, 0xFF, 0x03, 0});
    const auto wire = game::proto::encode({.entity = 42, .dx = -1, .dy = 3});
    const auto to_uint8 = [](std::byte one) { return std::to_integer<std::uint8_t>(one); };
    const bool same = std::ranges::equal(wire, kGolden, {}, to_uint8);
    game::core::check(same, "định dạng dây của Move đã đổi");
    return 0;
}
```

### KT-11 [C] PHẢI — Mọi hàm giải mã dữ liệu không tin cậy có harness libFuzzer; corpus hạt giống chạy lại như test thường

Harness gọi hàm giải mã với mọi chuỗi byte; ngoài ASan/UBSan, thêm oracle rẻ (thân nằm trong gói,
encode lại ra đúng byte cũ). Không có `GAME_FUZZ` thì `main` chạy lại corpus hạt giống và các đầu
vào từng làm sập (KT-08), nên harness cũng là test hồi quy dưới `[chạy]`.

- **Vì sao:** parser gói tin là bề mặt tấn công chính (UB-04, LH-03); fuzz có hướng theo độ phủ tìm
  ra đọc quá biên, tràn, abort do client gây ra trong vài phút — thứ review bỏ sót. Đã thử trên máy
  kiểm: Clang 20 `-fsanitize=fuzzer,address`, corpus rỗng, tìm ra lỗi cài sau ba byte `MMO` đúng thứ
  tự trong dưới một giây.
- **Kiểm:** job fuzz (KT-07); corpus lưu trong repo, gộp định kỳ bằng `-merge=1`.

```bash
clang++ -std=c++23 -g -O1 -fsanitize=fuzzer,address,undefined -DGAME_FUZZ \
    -Isrc tests/fuzz/chat_fuzz.cpp -o chat_fuzz
./chat_fuzz corpus/chat -max_total_time=300 -max_len=512 -dict=tests/fuzz/chat.dict
```

```cpp
// ✓ [chạy] Harness libFuzzer cho parser chat; không có GAME_FUZZ thì main chạy lại hạt giống.
#include "core/check.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>

namespace game::proto {

// Gói chat: [độ dài u8][thân].
[[nodiscard]] inline std::optional<std::span<const std::byte>> decode_chat(std::span<const std::byte> packet) noexcept {
    if (packet.empty()) return std::nullopt;
    const auto length = std::to_integer<std::size_t>(packet.front());
    if (length > packet.size() - 1) return std::nullopt;
    return packet.subspan(1, length);
}

} // namespace game::proto

// Tên do libFuzzer quy định (KT-11).
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) noexcept;

// Mọi đầu vào phải trả về; oracle: thân giải mã luôn ngắn hơn cả gói. noexcept: hàm extern "C"
// không cấp phát (LH-08).
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) noexcept {
    const auto body = game::proto::decode_chat(std::as_bytes(std::span{data, size}));
    game::core::check(!body || body->size() < size, "thân dài hơn gói");
    return 0;
}

#if !defined(GAME_FUZZ)
int main() {
    constexpr std::array<std::uint8_t, 4> kHello{3, 'h', 'i', '!'};
    constexpr std::array<std::uint8_t, 2> kLying{200, 'x'};
    static_cast<void>(LLVMFuzzerTestOneInput(kHello.data(), kHello.size()));
    static_cast<void>(LLVMFuzzerTestOneInput(kLying.data(), kLying.size()));
    return 0;
}
#endif
```

### KT-12 [C] PHẢI — Test đồng thời là stress test: các luồng xuất phát cùng lúc qua `std::latch`, kiểm bất biến bảo toàn, chạy dưới TSan

Chính sách (mọi code nhiều luồng có stress test dưới TSan) ở DT-07; đây là khuôn test. Luồng xuất
phát cùng lúc để tối đa đan xen; luồng chính tiêu thụ đồng thời; cuối cùng kiểm bất biến tổng (không
mất, không thừa thông điệp). Số lần lặp vừa đủ để TSan thấy đan xen (TSan chậm 5–15×).

- **Vì sao:** test tuần tự không bao giờ chạy hai thao tác cùng lúc; TSan chỉ thấy tranh chấp trên
  đường đã chạy song song thật. Kiểm tổng bắt lỗi logic mà TSan không coi là tranh chấp dữ liệu (mất cập nhật
  dưới khoá sai phạm vi).
- **Kiểm:** job clang-tsan (KT-07); chạy lặp (`ctest --repeat until-fail:20`) khi nghi test thất thường.

```cpp
// ✓ [tsan] Stress hộp thư mạng → game: 3 luồng ghi cùng lúc, luồng chính rút; tổng phải khớp.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <exception>
#include <functional>
#include <latch>
#include <mutex>
#include <thread>
#include <utility>
#include <vector>

namespace game::net {

class Mailbox {
public:
    void post(std::uint32_t value) {
        const std::scoped_lock lock{mutex_};
        items_.push_back(value);
    }
    [[nodiscard]] std::vector<std::uint32_t> drain() {
        const std::scoped_lock lock{mutex_};
        return std::exchange(items_, {});
    }

private:
    std::mutex mutex_;
    std::vector<std::uint32_t> items_;
};

} // namespace game::net

namespace game::test {

inline constexpr std::size_t kProducers = 3;
inline constexpr std::uint32_t kPerProducer = 2'000;

// Hàm vào luồng nên noexcept (LH-08): bad_alloc từ post thành std::terminate có chủ ý (LH-07).
// NOLINTNEXTLINE(bugprone-exception-escape)
inline void produce(net::Mailbox& box, std::latch& start) noexcept {
    // Mọi luồng xuất phát cùng lúc: tối đa đan xen.
    start.arrive_and_wait();
    for (std::uint32_t i = 0; i < kPerProducer; ++i) {
        box.post(i);
    }
}

inline void mailbox_keeps_every_message_under_contention() {
    net::Mailbox box;
    std::latch start{kProducers + 1};
    std::vector<std::jthread> producers;
    producers.reserve(kProducers);
    for (std::size_t i = 0; i < kProducers; ++i) {
        producers.emplace_back(produce, std::ref(box), std::ref(start));
    }
    start.arrive_and_wait();
    std::size_t received = 0;
    while (received < kProducers * kPerProducer) {
        received += box.drain().size();
    }
    core::check(received == kProducers * kPerProducer && box.drain().empty(), "mất/thừa thư");
}

} // namespace game::test

int main() {
    try {
        game::test::mailbox_keeps_every_message_under_contention();
    } catch (const std::exception& error) {
        // Tạo luồng thất bại: dừng, không nuốt (LH-07).
        game::core::fail(error.what());
    }
    return 0;
}
```

### KT-13 [C] PHẢI — Benchmark dùng harness thuần C++ của dự án: khởi động, nhiều mẫu theo lô, trung vị và p99, chặn loại bỏ mã chết

Phương pháp (dữ liệu thật, tần số CPU, ghim lõi, so trước/sau) ở HN-07; đây là code. Mỗi mẫu đo
một lô lời gọi vì một lời gọi ngắn hơn độ phân giải đồng hồ; báo trung vị và p99, không trung bình.
Kết quả mỗi lời gọi đi qua `keep` để trình dịch không xoá phép tính.

- **Vì sao:** benchmark ngây thơ đo vòng lặp rỗng: trình dịch thấy kết quả không dùng thì xoá cả
  phép tính, cho số đẹp mà vô nghĩa. Trung bình bị vài mẫu ngắt quãng của OS kéo lệch; p99 mới là
  thứ làm vỡ ngân sách tick (HN-08).
- **Kiểm:** benchmark chạy ở job gcc-release (KT-07), không dưới sanitizer; số đo ghi vào PR (HN-01).

```cpp
// ✓ [chạy] Harness benchmark: khởi động, mẫu theo lô, trung vị và p99, keep chặn xoá mã chết.
#include "core/check.hpp"

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <vector>

namespace game::bench {

// GCC/Clang: buộc trình dịch coi value đã được đọc, không sinh lệnh nào. MSVC x64 không có asm
// nội tuyến: cần cách khác (chưa kiểm trên MSVC).
template <class T>
inline void keep(const T& value) noexcept {
    asm volatile("" : : "r,m"(value) : "memory");
}

template <class Body>
void run_batch(Body& body, std::int64_t batch) {
    for (std::int64_t i = 0; i < batch; ++i) {
        keep(body());
    }
}

struct Plan {
    std::size_t samples = 101;
    // Số lời gọi mỗi mẫu: một lời gọi ngắn hơn độ phân giải đồng hồ.
    std::int64_t batch = 1'000;
};

struct Result {
    std::chrono::nanoseconds median{};
    std::chrono::nanoseconds p99{};
};

template <class Body>
[[nodiscard]] Result measure(Body body, Plan plan) {
    using Clock = std::chrono::steady_clock;
    core::check(plan.samples > 0 && plan.batch > 0, "measure: samples và batch phải dương");
    std::vector<std::chrono::nanoseconds> per_call(plan.samples);
    // Khởi động: cache, bộ dự đoán nhánh, trang bộ nhớ.
    run_batch(body, plan.batch);
    for (auto& slot : per_call) {
        const auto start = Clock::now();
        run_batch(body, plan.batch);
        slot = (Clock::now() - start) / plan.batch;
    }
    std::ranges::sort(per_call);
    return {.median = per_call[plan.samples / 2], .p99 = per_call[plan.samples * 99 / 100]};
}

inline void lcg_step() {
    std::uint32_t seed = 1;
    const auto step = [&seed] {
        seed = (seed * 1'664'525U) + 1'013'904'223U;
        return seed;
    };
    const Result result = measure(step, {.samples = 101, .batch = 1'000});
    core::check(result.median <= result.p99, "trung vị phải không vượt p99");
}

} // namespace game::bench

int main() {
    try {
        game::bench::lcg_step();
    } catch (const std::exception& error) {
        game::core::fail(error.what());
    }
    return 0;
}
```

### KT-14 [C] PHẢI — Mỗi `check` bảo vệ an ninh hay dữ liệu có death test: tiến trình con phải dừng với đúng thông điệp

Hợp đồng `constexpr` test lúc biên dịch được (KT-20); còn lại chạy tiến trình con. Đã đo với CTest
3.28: tiến trình chết vì tín hiệu (abort) bị báo "Subprocess aborted" là THẤT BẠI kể cả khi đặt
`WILL_FAIL` hay `PASS_REGULAR_EXPRESSION`. Bọc qua `sh` để tín hiệu thành mã thoát (134), rồi so
thông điệp `check thất bại: …`.

- **Vì sao:** `check` không ai thử có thể đã bị ai đó xoá, sai điều kiện, hay nằm sau nhánh không tới
  được; death test chứng minh bảo vệ còn đó. So thông điệp để chắc dừng đúng ở `check` đó, không phải
  crash khác.
- **Kiểm:** mỗi `check` chặn dữ liệu hỏng vào DB, hay chặn vượt quyền, có một death test.

```cmake
# ✓ Death test: binary chạy một ca theo argv[1]; sh biến abort thành mã thoát để CTest so output.
add_executable(inv_death tests/inv_death.cpp)
add_test(NAME split_stack_negative_count_aborts
    COMMAND sh -c "! \"$0\" split_negative" $<TARGET_FILE:inv_death>)
set_tests_properties(split_stack_negative_count_aborts PROPERTIES
    PASS_REGULAR_EXPRESSION "check thất bại: split_stack")
```

## 3. Thần thoại [T]

### KT-15 [T] PHẢI — Bản SIMD hay ước lượng có test sai phân với bản tham chiếu, ngưỡng sai số là số đo và tài liệu, không phải đoán

Mỗi `*_estimate`, `*_rough`, bản SIMD (SV-*) so với bản vô hướng chính xác trên tập đầu vào vét cạn
được hoặc đại diện có lý do. Ngưỡng lấy từ tài liệu lệnh (RSQRTPS: |sai số tương đối| ≤ 1.5 × 2^-12,
Intel SDM) hoặc từ số đo ghi trong comment kèm máy và trình dịch.

- **Vì sao:** đã đo trên máy kiểm (Xeon 2.1 GHz): RSQRTSS sai tối đa 1.336 × 2^-12 trên [1, 4); thêm
  một bước Newton-Raphson còn 2.28 × 2^-23. Kết quả RSQRTPS khác nhau giữa Intel và AMD (cùng giới
  hạn), nên test phải kiểm GIỚI HẠN, không kiểm giá trị. Lệnh tra bảng theo phần định trị và bit thấp
  của số mũ, nên `rsqrt(4x) = rsqrt(x)/2` đúng tuyệt đối (đã đo, 0 ca lệch): vét cạn 2^24 số trong
  [1, 4) phủ mọi số chuẩn — và test tự kiểm giả định đó.
- **Kiểm:** mỗi hàm ước lượng có test sai phân; ngưỡng có comment nguồn gốc.

```cpp
// ✓ [x86][chạy] Sai phân: RSQRTSS + một bước Newton so với 1/sqrt double, vét cạn [1, 4).
#include "core/check.hpp"

#include <algorithm>
#include <bit>
#include <cmath>
#include <cstdint>

#include <immintrin.h>

namespace game::test {

// Dạng vô hướng của simd::rsqrt_nr (vector.hpp): ước lượng 12 bit cộng một bước Newton.
[[nodiscard]] inline float rsqrt_estimate(float input) noexcept {
    const float guess = _mm_cvtss_f32(_mm_rsqrt_ss(_mm_set_ss(input)));
    return guess * (1.5F - (0.5F * input * guess * guess));
}

[[nodiscard]] inline double relative_error(float input) noexcept {
    const double exact = 1.0 / std::sqrt(static_cast<double>(input));
    return std::abs(static_cast<double>(rsqrt_estimate(input)) - exact) / exact;
}

// Một số: kiểm bất biến tỉ lệ 4^k làm phép vét cạn [1, 4) đủ cho mọi số chuẩn, trả sai số.
[[nodiscard]] inline double check_one(std::uint32_t bits) noexcept {
    const auto input = std::bit_cast<float>(bits);
    core::check(rsqrt_estimate(input * 4.0F) == rsqrt_estimate(input) * 0.5F, "mất tỉ lệ 4^k");
    return relative_error(input);
}

} // namespace game::test

int main() {
    double worst = 0.0;
    for (std::uint32_t bits = 0x3F80'0000U; bits < 0x4080'0000U; ++bits) {
        worst = std::max(worst, game::test::check_one(bits));
    }
    // Đo 2,28 * 2^-23 (Xeon, GCC 14 -O2); giới hạn 3 * 2^-23 chừa chỗ cho CPU khác.
    game::core::check(worst <= 0x1.8p-22, "rsqrt_estimate vượt 3 * 2^-23");
    return 0;
}
```

### KT-16 [T] NÊN — Replay test: ghi input theo tick, chạy lại từ cùng trạng thái đầu, so hash trạng thái từng tick và chỉ ra tick lệch đầu tiên

Máy chủ ghi (trạng thái đầu, input mỗi tick, hash trạng thái mỗi tick); test chạy lại mô phỏng và so
hash. Lệch ở tick N thì chỉ cần soi những gì chạy ở tick N. Điều kiện: mô phỏng tất định (MMO-*:
số nguyên hoặc fixed-point, không duyệt `unordered_*`, PRNG tự viết có seed, không đồng hồ thật).

- **Vì sao:** lỗi mô phỏng MMO thường chỉ hiện sau hàng nghìn tick với input thật; replay biến báo cáo
  "nhân vật bị kẹt tường" thành test tái hiện chính xác. Hash từng tick biến "sai ở đâu đó" thành
  "sai ở tick 4127".
- **Kiểm:** mỗi bản sửa mô phỏng chạy lại thư viện replay; hash lệch là đỏ.

```cpp
// ✓ [chạy] Replay: chạy lại cùng input, so hash từng tick, tìm tick lệch đầu tiên.
#include "core/check.hpp"

#include <algorithm>
#include <cstdint>
#include <exception>
#include <span>
#include <vector>

namespace game::sim {

struct Input {
    // Chỉ số thực thể 0..3.
    std::uint8_t entity = 0;
    std::int8_t dx = 0;
};

// Bước tick tất định: chỉ số nguyên, không đồng hồ, không unordered. positions không rỗng.
inline void step(std::vector<std::int32_t>& positions, Input input) noexcept {
    positions[input.entity % positions.size()] += input.dx;
}

// Biến thể FNV-1a: xor từng giá trị 32 bit (bản chuẩn xor từng byte), theo thứ tự cố định.
[[nodiscard]] inline std::uint64_t state_hash(std::span<const std::int32_t> positions) noexcept {
    std::uint64_t hash = 0xCBF2'9CE4'8422'2325ULL;
    for (const std::int32_t value : positions) {
        hash = (hash ^ static_cast<std::uint32_t>(value)) * 0x0000'0100'0000'01B3ULL;
    }
    return hash;
}

[[nodiscard]] inline std::vector<std::uint64_t> replay(std::span<const Input> inputs) {
    std::vector<std::int32_t> positions(4);
    std::vector<std::uint64_t> hashes;
    hashes.reserve(inputs.size());
    for (const Input input : inputs) {
        step(positions, input);
        hashes.push_back(state_hash(positions));
    }
    return hashes;
}

inline void replay_reproduces_recorded_hashes() {
    const std::vector<Input> inputs{{.entity = 1, .dx = 5}, {.entity = 3, .dx = -2}};
    // Ở máy chủ, recorded đọc từ tệp ghi của trận đấu.
    const auto recorded = replay(inputs);
    const auto again = replay(inputs);
    // Tick lệch đầu tiên; recorded.end() nghĩa là khớp hết.
    const auto diverged = std::ranges::mismatch(recorded, again).in1;
    core::check(diverged == recorded.end(), "replay lệch hash");
}

} // namespace game::sim

int main() {
    try {
        game::sim::replay_reproduces_recorded_hashes();
    } catch (const std::exception& error) {
        game::core::fail(error.what());
    }
    return 0;
}
```

### KT-17 [T] NÊN — Hàm trên miền nhỏ test vét cạn: mọi 2^16 giá trị `Half`, và mọi 2^32 `float` cho hàm then chốt

Miền ≤ 2^32 thì vét cạn khả thi: không còn "ca chưa nghĩ tới". Bản tham chiếu độc lập: lệnh F16C
(`_cvtsh_ss`, `_cvtss_sh`) hoặc `std::float16_t` (chỉ libstdc++, KG-18; Clang không định nghĩa
`__STDCPP_FLOAT16_T__`, nên test dùng nó nằm sau guard và clang-tidy — chạy bằng Clang — bỏ qua
nhánh đó). Đã đo trên máy kiểm:
`to_float` của types.hpp khớp `std::float16_t` ở cả 65 536 giá trị (0.5 ms ở `-O2`, 0.8 ms dưới
ASan + UBSan); `to_half(to_float(h)) == h` với mọi `h` không NaN; `to_half` khớp `_cvtss_sh` (làm
tròn về số chẵn) ở cả 2^32 `float` không NaN trong 9.4 s (GCC 14, `-O2 -march=x86-64-v3`, một
luồng, Xeon 2.1 GHz).

- **Vì sao:** sai sót trong chuyển đổi số thực nằm ở vài chục giá trị (số không chuẩn, tràn sang số
  mũ kế, NaN) mà test chọn tay hầu như luôn bỏ sót. Vét cạn là bằng chứng, không phải mẫu thử.
- **Kiểm:** vét cạn 2^16 chạy cùng unit test; vét cạn 2^32 ở job gcc-release (KT-07), không dưới
  sanitizer.

```cpp
// ✓ [x86][chạy] Vét cạn 2^16: to_float của types.hpp so với lệnh F16C VCVTPH2PS.
#include "core/check.hpp"

#include <bit>
#include <cmath>
#include <cstdint>

#include <immintrin.h>

namespace game::math {

struct Half {
    std::uint16_t bits = 0;
};

// Như types.hpp: chuẩn, không chuẩn, vô cùng, NaN.
[[nodiscard]] constexpr float to_float(Half half) noexcept {
    const std::uint32_t sign = (half.bits & 0x8000U) << 16U;
    const std::uint32_t exponent = (half.bits >> 10U) & 0x1FU;
    const std::uint32_t mantissa = half.bits & 0x03FFU;
    const std::uint32_t payload = sign | (mantissa << 13U);
    if (exponent == 31) return std::bit_cast<float>(payload | 0x7F80'0000U);
    if (exponent != 0) return std::bit_cast<float>(payload | ((exponent + 112U) << 23U));
    if (mantissa == 0) return std::bit_cast<float>(sign);
    const auto shift = static_cast<std::uint32_t>(std::countl_zero(mantissa)) - 21U;
    const std::uint32_t fraction = (mantissa << shift) & 0x03FFU;
    return std::bit_cast<float>(sign | ((113U - shift) << 23U) | (fraction << 13U));
}

} // namespace game::math

namespace game::test {

// Cùng mẫu bit, hoặc cùng là NaN (phần cứng làm quiet NaN tín hiệu; types.hpp giữ nguyên bit).
inline void same_as_hardware(std::uint16_t bits) noexcept {
    const float mine = math::to_float(math::Half{bits});
    const float oracle = _cvtsh_ss(bits);
    const bool same = std::bit_cast<std::uint32_t>(mine) == std::bit_cast<std::uint32_t>(oracle);
    core::check(same || (std::isnan(mine) && std::isnan(oracle)), "to_float lệch VCVTPH2PS");
}

} // namespace game::test

int main() {
    for (std::uint32_t bits = 0; bits <= 0xFFFFU; ++bits) {
        game::test::same_as_hardware(static_cast<std::uint16_t>(bits));
    }
    return 0;
}
```

### KT-18 [T] NÊN — Fuzz có cấu trúc: harness tự dựng phần khung (độ dài, checksum) hoặc đọc byte thành chuỗi thao tác so với mô hình tham chiếu

Đột biến byte ngẫu nhiên gần như luôn làm hỏng checksum, nên fuzzer kẹt ở lớp khung và không bao giờ
tới phần thân. Hai cách: (1) fuzzer sinh THÂN, harness bọc độ dài và checksum đúng; (2) với hệ có
trạng thái (kho đồ, hàng đợi), mỗi byte là một thao tác, sau mỗi thao tác so với mô hình đơn giản
(`std::deque`, `std::map`) — mọi chuỗi byte đều hợp lệ nên fuzzer khám phá trạng thái thay vì vấp ở
bộ giải mã. libFuzzer còn cho `LLVMFuzzerCustomMutator` khi cấu trúc phức tạp hơn.

- **Vì sao:** độ phủ là thứ fuzz cần; lớp kiểm vỏ chặn mọi đầu vào thì giờ fuzz tốn vô ích, và lỗi
  thật ở phần thân không bao giờ được chạm.
- **Kiểm:** báo cáo độ phủ của job fuzz (`-print_coverage=1` hay `llvm-cov`) phải chạm phần thân.

```cpp
// ✓ [chạy] Fuzzer sinh thân; harness bọc độ dài và checksum đúng để mọi đầu vào qua lớp khung.
#include "core/check.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <span>
#include <vector>

namespace game::proto {

[[nodiscard]] constexpr std::uint8_t checksum(std::span<const std::byte> body) noexcept {
    std::uint32_t sum = 0;
    for (const std::byte one : body) {
        sum += std::to_integer<std::uint32_t>(one);
    }
    return static_cast<std::uint8_t>(sum);
}

// Gói: [độ dài thân u8][thân][checksum u8]. Thân hợp lệ thì giải mã tiếp (ở đây: chấp nhận).
[[nodiscard]] inline bool accept(std::span<const std::byte> packet) noexcept {
    if (packet.size() < 2) return false;
    const auto length = std::to_integer<std::size_t>(packet.front());
    if (length != packet.size() - 2) return false;
    return std::to_integer<std::uint8_t>(packet.back()) == checksum(packet.subspan(1, length));
}

} // namespace game::proto

// Tên do libFuzzer quy định (KT-18).
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size);

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    if (size > 255) return 0;
    const auto body = std::as_bytes(std::span{data, size});
    std::vector<std::byte> packet{static_cast<std::byte>(size)};
    packet.insert(packet.end(), body.begin(), body.end());
    packet.push_back(std::byte{game::proto::checksum(body)});
    game::core::check(game::proto::accept(packet), "khung đúng phải được nhận");
    return 0;
}

#if !defined(GAME_FUZZ)
int main() {
    constexpr std::array<std::uint8_t, 3> kSeed{1, 2, 3};
    try {
        static_cast<void>(LLVMFuzzerTestOneInput(kSeed.data(), kSeed.size()));
    } catch (const std::exception& error) {
        game::core::fail(error.what());
    }
    return 0;
}
#endif
```

### KT-19 [T] PHẢI — Test không dựa vào thứ unspecified; ma trận libstdc++ + libc++ là thứ bắt lỗi này

Thứ khác nhau giữa thư viện: thứ tự duyệt `unordered_*`, thứ tự các phần tử bằng nhau sau
`std::sort` (không ổn định), kết quả `<random>` distribution, chuỗi `what()` của ngoại lệ, giá trị
`std::hash`. Test so tập hợp thì sắp trước khi so; so thứ tự thì sắp với khoá toàn phần.

- **Vì sao:** đã đo: chèn cùng 12 id vào `unordered_set<uint32_t>`, libstdc++ (GCC 14/15) duyệt
  `2 7 77 1000 64 …`, libc++ 20 duyệt `1000 2 64 18 …`. Test viết trên một máy xanh, sang máy kia đỏ
  — hoặc tệ hơn, logic game (thứ tự gửi AOI, ai nhận vật phẩm trước) khác nhau giữa bản build.
- **Kiểm:** ma trận KT-07; review: không `==` trên vector dựng từ duyệt `unordered_*` mà chưa sắp.

```cpp
// ✓ [chạy] Người chơi trong một ô AOI lấy từ unordered_map: sắp trước khi so với kỳ vọng.
#include "core/check.hpp"

#include <algorithm>
#include <cstdint>
#include <exception>
#include <ranges>
#include <unordered_map>
#include <vector>

namespace game::world {

// Ô AOI hiện tại của từng người chơi, khoá là id người chơi.
using CellByPlayer = std::unordered_map<std::uint32_t, std::int32_t>;

[[nodiscard]] inline std::vector<std::uint32_t> players_in(const CellByPlayer& cell_of, std::int32_t cell) {
    const auto is_in_cell = [cell](const auto& entry) { return entry.second == cell; };
    auto ids = cell_of | std::views::filter(is_in_cell) | std::views::keys | std::ranges::to<std::vector>();
    // Thứ tự duyệt unordered_map là unspecified.
    std::ranges::sort(ids);
    return ids;
}

inline void players_in_returns_sorted_ids() {
    const CellByPlayer cell_of{{9, 7}, {3, 7}, {5, 2}, {12, 7}, {1000, 7}};
    const auto ids = players_in(cell_of, 7);
    core::check(ids == std::vector<std::uint32_t>{3, 9, 12, 1000}, "sai tập người chơi");
}

} // namespace game::world

int main() {
    try {
        game::world::players_in_returns_sorted_ids();
    } catch (const std::exception& error) {
        game::core::fail(error.what());
    }
    return 0;
}
```

### KT-20 [T] NÊN — Hợp đồng `constexpr` có test vi phạm lúc biên dịch: `requires` trên đối số mẫu hằng biến "tính hằng thất bại" thành `false`

Trong một template, `requires { typename std::integral_constant<T, f(V)>; }` là `false` khi tính
hằng `f(V)` thất bại (vì `core::check` sai), thay vì lỗi biên dịch. Đó là death test không cần tiến
trình con: `static_assert` rằng giá trị xấu BỊ từ chối, giá trị biên tốt được nhận. Đã đo: GCC 14.2,
GCC 15.2, Clang 20 đều coi đây là thất bại thay thế (đo với `requires` nằm trong biến mẫu
`constexpr bool`); dạng `concept` của mẫu dưới đo 2026-10-08 trên GCC 16.2 và Clang 23.1.

- **Vì sao:** `check` trong hàm `constexpr` (LH-16) chỉ có giá trị nếu nó thật sự chặn; test này
  chứng minh mỗi lần build, kể cả biên (0 bị chặn, 1 được nhận), không tốn gì lúc chạy. Phải nằm
  trong template: ngoài template, biểu thức không hợp lệ trong `requires` làm chương trình
  ill-formed (lỗi biên dịch) chứ không cho `false` ([expr.prim.req]).
- **Kiểm:** mỗi hàm `constexpr` có `check` tiền điều kiện có cặp `static_assert` biên trong/ngoài.

```cpp
// ✓ Death test lúc biên dịch: level ngoài 1..100 phải bị check chặn khi tính hằng.
#include "core/check.hpp"

#include <cstdint>
#include <type_traits>

namespace game::world {

[[nodiscard]] constexpr std::int32_t level_cap(std::int32_t level) noexcept {
    core::check(level >= 1 && level <= 100, "level_cap: level phải trong 1..100");
    return level * 10;
}

} // namespace game::world

namespace game::test {

// Thoả khi level_cap(Level) tính hằng được, tức check không chặn Level.
template <std::int32_t Level>
concept LevelCapAccepts = requires { typename std::integral_constant<std::int32_t, world::level_cap(Level)>; };

static_assert(!LevelCapAccepts<0> && !LevelCapAccepts<101>);
static_assert(LevelCapAccepts<1> && LevelCapAccepts<100>);

} // namespace game::test
```

## Kiểm nhanh

- [ ] Test dùng khung dự án (bảng `constexpr`, `expect` có `source_location`), không thư viện ngoài? (KT-01)
- [ ] Logic tách thành hàm thuần; tên test `<chủ thể>_<tình huống>_<kết quả>`, một hành vi mỗi test? (KT-02)
- [ ] Có bảng ca biên đủ miền (0, min, max, NaN, ±vô cùng, rỗng, đầy + 1)? (KT-03)
- [ ] Hàm `constexpr` có `static_assert` trên bảng ca; vi phạm hợp đồng test lúc biên dịch? (KT-04, KT-20)
- [ ] Không `random_device`, `now()`, `sleep_for` trong test; seed in ra khi đỏ? (KT-05, KT-06)
- [ ] Test chạy trong ma trận GCC/libstdc++ + Clang/libc++ dưới ASan + UBSan, TSan cho luồng? (KT-07, KT-19)
- [ ] Bản sửa lỗi có test hồi quy với đúng đầu vào gây lỗi? (KT-08)
- [ ] Mỗi encode/decode có round-trip và golden? (KT-09, KT-10)
- [ ] Mỗi parser dữ liệu không tin cậy có harness libFuzzer, harness vượt được lớp khung? (KT-11, KT-18)
- [ ] Code nhiều luồng có stress test xuất phát bằng `latch`, kiểm bất biến tổng? (KT-12)
- [ ] Benchmark dùng harness (khởi động, lô, trung vị, p99, `keep`)? (KT-13)
- [ ] Bản SIMD/ước lượng có test sai phân với ngưỡng có nguồn; miền nhỏ thì vét cạn? (KT-15, KT-17)
