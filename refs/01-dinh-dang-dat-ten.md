# DD · Định danh, include, namespace, macro

> **Phạm vi:** định danh dành riêng, include, namespace, NOLINT, mã hoá nguồn, macro, bẫy tên với
> macro nền tảng và ODR. Các quy tắc hình thức (định dạng, bảng đặt tên, bố cục header, literal, thứ
> tự trong lớp) đã gỡ ngày 2026-10-08; quy tắc còn lại giữ nguyên mã. **Đọc khi:** thêm include;
> viết NOLINT; include `<windows.h>` hay header nền tảng; định nghĩa macro; đặt ID bền.
> **Liên quan:** HP-12 (lệch quy tắc), BD-* (clang-tidy trong CI), KTR-* (một khái niệm một header,
> tầng phụ thuộc), KG-* (kiểu, enum).

## 1. Nền tảng [N]

### DD-02 [N] CẤM — Định danh dành riêng (`_Hoa`, `__`, `_` đầu tên ở phạm vi toàn cục) và khai báo thêm vào `namespace std`

CẤM tên bắt đầu bằng `_` + chữ hoa, tên chứa `__`, tên bắt đầu bằng `_` ở phạm vi toàn cục, và khai
báo thêm vào `namespace std` (trừ chuyên biệt hoá `std::hash`, `std::formatter` cho kiểu của dự án).

- **Vì sao:** dùng tên dành riêng là chương trình sai không cần chẩn đoán ([lex.name]), mở rộng `std`
  là UB ([namespace.std]): chạy tới khi libstdc++ mới định nghĩa `_Value`.
- **Kiểm:** clang-tidy `bugprone-reserved-identifier`, `cert-dcl58-cpp`.

### DD-05 [N] PHẢI — Include đủ thứ mình dùng, không dựa vào include bắc cầu; header tự đủ

Mỗi tệp include trực tiếp header của mọi tên nó dùng, không dựa vào include bắc cầu, không include
thứ không dùng. Header của dự án include bằng đường dẫn từ gốc include (`"core/check.hpp"`). Header
tự đủ: biên dịch một mình được.

- **Vì sao:** include bắc cầu vỡ khi thư viện chuẩn dọn header: từ GCC 13, nhiều header chuẩn thôi
  kéo theo `<cstdint>`, `<cstdio>`, code dùng `std::uint32_t` mà không include
  `<cstdint>` thôi biên dịch; libc++ cũng gỡ dần include bắc cầu qua từng bản.
- **Kiểm:** clang-tidy `misc-include-cleaner` (bỏ qua `*intrin.h` theo config); header tự đủ kiểm
  bằng một .cpp chỉ `#include` nó (KTR-03).

```cpp
// ✓ [x86] Dùng gì include nấy: check, atomic, size_t, _mm_pause đều có header của nó.
#include "core/check.hpp"

#include <atomic>
#include <cstddef>

#include <immintrin.h>

namespace game::conc {

// Chờ bận tối đa max_spins vòng tới khi flag bật; trả trạng thái cuối. PAUSE báo CPU đây là vòng
// chờ: giảm điện năng và tránh phạt vi phạm thứ tự bộ nhớ khi thoát vòng (tài liệu Intel).
[[nodiscard]] inline bool spin_until(const std::atomic<bool>& flag, std::size_t max_spins) noexcept {
    core::check(max_spins > 0, "spin_until: max_spins phải dương");
    for (std::size_t spin = 0; spin < max_spins && !flag.load(std::memory_order_acquire); ++spin) {
        _mm_pause();
    }
    return flag.load(std::memory_order_acquire);
}

} // namespace game::conc
```

### DD-06 [N] PHẢI — Namespace `game::<module>` theo bảng tầng, `detail` cho nội bộ; CẤM `using namespace` và namespace ẩn danh trong header

Mọi code nằm trong `game::<module>` theo bảng tầng KTR-01 (core, math, proto, net, db, world, sim,
app; module dùng chung config, obs, rng, conc, mem; mỗi luật chơi một namespace: combat, inv…; mã
test: `game::test`). Cài đặt nội bộ của header:
`namespace detail` lồng trong module. Header: CẤM `namespace {` và CẤM `using namespace`. .cpp: helper
nội bộ trong namespace ẩn danh (thay `static`); `using namespace` chỉ cho literal chuẩn
(`std::chrono_literals`) TRONG thân hàm — clang-tidy 20 `misc-include-cleaner` báo nhầm mọi literal
chrono (đã thử, cả libstdc++ và libc++), nên dùng literal phải kèm NOLINTNEXTLINE có lý do (DD-08).

- **Vì sao:** tên module cho biết tầng (KTR-*). Namespace ẩn danh trong header tạo thực thể riêng
  cho mỗi TU: hàm inline dùng nó vi phạm ODR. `using namespace std;` trong header đổi kết quả tra
  tên trong code người khác (`abs`, `min`, `count` của std đè hàm cùng tên của dự án).
- **Kiểm:** clang-tidy `cert-dcl59-cpp`, `misc-use-anonymous-namespace`,
  `google-build-using-namespace`, `google-global-names-in-headers`; Clang `-Wheader-hygiene`.

```cpp
// ✓ Tệp .cpp: hằng nội bộ trong namespace ẩn danh; tên đầy đủ, không using namespace.
#include <chrono>
#include <cstdint>

namespace game::sim {

namespace {

constexpr std::chrono::milliseconds kTickPeriod{50};

} // namespace

// Khai báo thật nằm trong sim/clock.hpp; lặp lại ở đây để mẫu tự đủ.
[[nodiscard]] std::int64_t ticks_per_minute() noexcept;

std::int64_t ticks_per_minute() noexcept {
    return std::chrono::minutes{1} / kTickPeriod;
}

} // namespace game::sim
```

### DD-08 [N] PHẢI — NOLINT nêu tên check, lý do và mã quy tắc; vùng dùng NOLINTBEGIN/NOLINTEND

Vùng: `// NOLINTBEGIN(<check>): <lý do> (<MÃ-NN>)` … `// NOLINTEND(<check>)`. Một dòng:
`// NOLINTNEXTLINE(<check>)` trên dòng riêng, lý do ở dòng comment ngay trên nếu không vừa cùng
dòng — comment dài bị clang-format ngắt thì NOLINTNEXTLINE trỏ nhầm dòng. CẤM `// NOLINT` trần,
`NOLINT(*)`, NOLINT cuối dòng code. Phạm vi hẹp nhất có thể.

- **Vì sao:** NOLINT trần tắt mọi check trên dòng, kể cả check bắt lỗi thật thêm vào sau này. Tên
  check, lý do, mã quy tắc cho người review biết lệch có chủ đích (HP-12) và khi nào gỡ được.
- **Kiểm:** clang-tidy báo NOLINTBEGIN thiếu NOLINTEND (`clang-tidy-nolint`, đã thử); review:
  `grep -rnE 'NOLINT(NEXTLINE|BEGIN)?($|[^(A-Z])|NOLINT[A-Z]*\(\*\)'` phải rỗng.

```cpp
// ✓ Lệch một dòng: lý do và mã quy tắc ở dòng trên, tên check trong NOLINTNEXTLINE.
#include <cstddef>
#include <cstdio>

namespace game::mem {

// Gọi khi cấp phát thất bại, nên không được cấp phát thêm.
inline void report_out_of_memory(std::size_t bytes) noexcept {
    // fprintf thay std::print (lệch STD-04): in được số mà không cấp phát thêm.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
    static_cast<void>(std::fprintf(stderr, "out of memory: %zu bytes\n", bytes));
}

} // namespace game::mem
```

### DD-09 [N] PHẢI — Định danh ASCII; nguồn UTF-8 không BOM, dạng NFC; không ký tự điều khiển hai chiều

Định danh chỉ dùng ASCII. Comment và chuỗi tiếng Việt viết UTF-8 có dấu, dạng NFC (ký tự dựng
sẵn). Tệp UTF-8 không BOM; MSVC biên dịch với `/utf-8` (BD-*). CẤM ký tự điều khiển hai chiều
(U+202A–U+202E, U+2066–U+2069) và ký tự vô hình (U+200B–U+200F) trong nguồn.

- **Vì sao:** C++23 cho phép định danh Unicode và đòi dạng NFC, nhưng đo trên máy kiểm: GCC 14 chỉ
  CẢNH BÁO định danh NFD (`-Wnormalized`), Clang 20 không báo gì về NFC kể cả với `-Weverything`
  — `sát` dựng sẵn và `sát` tổ hợp (a + U+0301) là HAI biến trông y hệt. Ký tự hai chiều làm code
  hiển thị khác code được biên dịch (Trojan Source, CVE-2021-42574): GCC 14 mặc định chỉ cảnh báo
  ký tự không thành cặp (`-Wbidi-chars=unpaired`; cặp RLO…PDF lọt, đã thử), Clang 20 im lặng.
- **Kiểm:** clang-tidy `misc-misleading-bidirectional` (đã thử: bắt được trong comment),
  `misc-confusable-identifiers` (đã thử: không bắt cặp NFC/NFD); GCC `-Wbidi-chars=any`; trong CI
  chạy lệnh dưới.

```bash
# Ký tự hai chiều, vô hình, BOM (grep -P cần locale UTF-8).
LC_ALL=C.UTF-8 grep -rnP '[\x{202A}-\x{202E}\x{2066}-\x{2069}\x{200B}-\x{200F}\x{FEFF}]' src/
# Tệp không ở dạng NFC.
python3 -c 'import sys, unicodedata as u
for p in sys.argv[1:]:
    t = open(p, encoding="utf-8").read()
    if t != u.normalize("NFC", t): print(p)' $(git ls-files '*.hpp' '*.cpp')
```

### DD-10 [N] CẤM — Macro cho hằng hoặc hàm; macro cấu hình được đọc đúng một chỗ thành `constexpr bool`

Hằng → `inline constexpr`; hàm → `constexpr` hoặc template. Macro chỉ còn cho cấu hình build (tiền
tố `GAME_`) và phát hiện nền tảng (`_WIN32`, `__x86_64__` của trình dịch). Mỗi macro cấu hình đọc
ĐÚNG MỘT chỗ bằng `#if defined(GAME_X)`, đổi ngay thành `inline constexpr bool kX` (như
`kDebugChecks` của core/check.hpp); code rẽ nhánh bằng `if constexpr (kX)`, không rải `#if`.

- **Vì sao:** macro không phạm vi, không kiểu, đụng tên ở mọi nơi (DD-14). Nhánh `#if` đang tắt
  không được biên dịch nên mục dần; nhánh `if constexpr` ngoài template vẫn được kiểm cú pháp, tên,
  kiểu ở MỌI cấu hình — lý do `debug_check` không mục.
- **Kiểm:** clang-tidy `cppcoreguidelines-macro-usage`, `cppcoreguidelines-macro-to-enum`;
  `-Wundef` (cờ chung) báo `#if GAME_X` khi GAME_X chưa định nghĩa.

```cpp
// ✓ Macro đọc một lần thành constexpr bool; hằng là constexpr; rẽ nhánh bằng if constexpr.
#include "core/check.hpp"

#include <cstdint>

namespace game::world {

#if defined(GAME_PROFILE_AOI)
inline constexpr bool kProfileAoi = true;
#else
inline constexpr bool kProfileAoi = false;
#endif

inline constexpr std::int32_t kProfileOverhead = 500;

// radius trong 0..46340 để radius * radius không tràn int32.
[[nodiscard]] constexpr std::int32_t aoi_cost(std::int32_t radius) noexcept {
    core::check(radius >= 0 && radius <= 46'340, "aoi_cost: radius phải trong 0..46340");
    if constexpr (kProfileAoi) return (radius * radius) + kProfileOverhead;
    return radius * radius;
}

} // namespace game::world
```

## 2. Nâng cao [C]

### DD-12 [C] PHẢI — Hàm tự do đặt tên theo phép toán, nạp chồng theo kiểu; bản vô hướng gọi đủ `std::`

`dot(a, b)` cho Float3, Vector3, SoaFloat3 — không `vec3_dot`, `dot_soa`. Trong namespace có
`abs`, `min`, `max`, `sqrt`, `lerp` cho kiểu của dự án, bản vô hướng luôn gọi đủ `std::abs(x)`,
`std::sqrt(x)` (như `abs(Point2)` của vector.hpp gọi `std::abs(p.x)`).

- **Vì sao:** một tên cho một phép toán thì code generic gọi được cho mọi kiểu. Nhưng `abs` khai
  báo trong `game::math` CHE mọi `abs` ở phạm vi ngoài với lời gọi không đủ điều kiện từ bên trong:
  tra tên dừng ở phạm vi gần nhất có tên đó. Kết quả: lỗi biên dịch (mẫu ✗) — hoặc tệ hơn, đổi
  ngầm sang kiểu dự án nếu nó có constructor một tham số không `explicit` (vì thế mọi constructor
  một tham số của Vector3, Vector4i là `explicit`).
- **Kiểm:** biên dịch; review lời gọi không đủ điều kiện trong namespace math.

```cpp
// ✗ [không biên dịch] abs của dự án che std::abs: trong namespace, abs(float) không thấy bản chuẩn.
#include <cmath>

namespace game::math {

struct Float2 {
    float x = 0.0F;
    float y = 0.0F;
};

inline Float2 abs(Float2 value) { return {std::abs(value.x), std::abs(value.y)}; }

inline float manhattan(Float2 from, Float2 to) { return abs(to.x - from.x) + abs(to.y - from.y); }

} // namespace game::math
```

```cpp
// ✓ Một tên cho một phép toán; bản vô hướng gọi đủ std::abs.
#include <cmath>

namespace game::math {

struct Float2 {
    float x = 0.0F;
    float y = 0.0F;
};

[[nodiscard]] inline Float2 abs(Float2 value) noexcept {
    return {.x = std::abs(value.x), .y = std::abs(value.y)};
}

[[nodiscard]] inline float manhattan(Float2 origin, Float2 target) noexcept {
    const Float2 delta = abs(Float2{.x = target.x - origin.x, .y = target.y - origin.y});
    return delta.x + delta.y;
}

} // namespace game::math
```

## 3. Thần thoại [T]

### DD-14 [T] PHẢI — Cách ly header nền tảng định nghĩa macro trùng tên thường

`<windows.h>` định nghĩa macro `min`, `max` (trừ khi có `NOMINMAX`), `near`, `far` (rỗng), `small`
(`char`), `interface`, `ERROR`, `DELETE`, `IN`, `OUT`, `OPTIONAL`, và đổi tên hàm theo bản A/W
(`GetMessage` thành `GetMessageW`); X11 định nghĩa `None`, `Bool`, `Status`, `Success`. Chỉ .cpp
nền tảng include chúng: `NOMINMAX`, `WIN32_LEAN_AND_MEAN` định nghĩa trước, `#undef near` và
`#undef far` ngay sau; không bao giờ trong header.

- **Vì sao:** `near()` của math/types.hpp là nạn nhân thật. Header include SAU `<windows.h>`: khai
  báo thành `bool (Float2 a, …)`, lỗi khó hiểu ở tệp xa (mẫu ✗). Include TRƯỚC: khai báo đúng, nhưng
  lời gọi `near(a, b, tol)` phía sau thành biểu thức phẩy `(a, b, tol)` — biên dịch được, chỉ cảnh
  báo (GCC `-Wunused-value`; Clang thêm `-Wcomma`, `-Wfloat-conversion` với cờ của bộ — đã thử),
  trả `tol` đổi sang `bool`. Macro hàm `min(a, b)` phá
  `std::min(a, b)`. Lỗi chỉ hiện trên một nền tảng, ở tệp include muộn.
- **Kiểm:** CI có bản Windows (BD-*); `grep -rn 'windows.h' --include='*.hpp'` rỗng. Header buộc
  phải chịu được macro hàm thì viết `(std::min)(a, b)`.

```cpp
// ✗ [không biên dịch] Mô phỏng <windows.h>: `#define near` rỗng phá khai báo near của dự án.
#define near

namespace game::math {

[[nodiscard]] constexpr bool near(float value, float target, float tolerance) noexcept {
    return value - target <= tolerance && target - value <= tolerance;
}

} // namespace game::math
```

```cpp
// ✓ <windows.h> chỉ trong .cpp nền tảng: NOMINMAX, WIN32_LEAN_AND_MEAN trước; gỡ near, far sau.
#if defined(_WIN32)
#define NOMINMAX
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef near
#undef far
#endif

namespace game::core {

// Khai báo thật nằm trong core/console.hpp; lặp lại ở đây để mẫu tự đủ.
void enable_utf8_console() noexcept;

// Console Windows mặc định dùng code page OEM: log tiếng Việt UTF-8 thành rác nếu không đổi.
void enable_utf8_console() noexcept {
#if defined(_WIN32)
    static_cast<void>(SetConsoleOutputCP(CP_UTF8));
#endif
}

} // namespace game::core
```

### DD-15 [T] CẤM — Hai định nghĩa khác nhau cho cùng một tên ở hai TU: helper chép sang header khác, bố cục kiểu theo macro

Mỗi tên trong `detail` (và mọi hàm inline, template, kiểu trong header) định nghĩa ở ĐÚNG MỘT
header; header khác cần thì include, không chép. Helper của một .cpp nằm trong namespace ẩn danh
(DD-06). Macro cấu hình KHÔNG đổi bố cục kiểu (`#if` quanh thành viên dữ liệu) hay thân hàm inline
trong header, trừ khi nó đặt cho cả chương trình: `GAME_DEBUG_CHECKS` gắn cho mọi TU qua target
INTERFACE `game::options` (BD-03), không bao giờ `#define` trong một .cpp — `debug_check` đọc
`kDebugChecks`.

- **Vì sao:** vi phạm ODR không cần chẩn đoán. Đã thử: hai TU định nghĩa `detail::lesser` khác
  thân — trình liên kết im lặng giữ một bản (ký hiệu weak); chỗ không nội tuyến gọi bản đó, chỗ
  nội tuyến dùng bản của TU mình: kết quả đổi theo mức tối ưu. GCC `-flto -Wodr` bắt KIỂU khác bố
  cục cùng tên (đã thử), không bắt thân hàm inline khác nhau.
- **Kiểm:** GCC `-flto -Wodr` trong một cấu hình CI; review `#if` trong header.

```cpp
// ✓ Bố cục như nhau ở mọi cấu hình: không `#if` quanh thành viên, cỡ khoá bằng static_assert.
#include <cstdint>

namespace game::world {

struct Entity {
    std::uint32_t id = 0;
    std::uint32_t generation = 0;
    float hp = 0.0F;
};

static_assert(sizeof(Entity) == 12);

} // namespace game::world
```

### DD-16 [T] CẤM — Dùng tên định danh làm dữ liệu bền: `typeid().name()`, `source_location::function_name()`, `#x`

ID trên dây, trong DB, replay, khoá cache là hằng viết tay (`static constexpr std::uint32_t
kPersistentId = 0x0003'0001U;` hoặc chuỗi tường minh `"combat.damage"`), không sinh từ tên C++.
Đổi tên định danh không được đổi một byte dữ liệu.

- **Vì sao:** `typeid(T).name()` do trình dịch quyết: GCC, Clang trả tên mangled Itanium
  (`N4game6combat6DamageE`), MSVC trả `struct game::combat::Damage`; `function_name()`,
  `__PRETTY_FUNCTION__` khác định dạng giữa trình dịch và phiên bản; `#x` đổi khi đổi tên; băm bằng
  `std::hash` thêm một lớp không ổn định. Máy chủ (GCC) và công cụ (MSVC) sẽ có hai bộ ID, và dữ
  liệu lưu vỡ sau một lần refactor.
- **Kiểm:** review: `grep -rnE 'typeid\(.*\)\.name|function_name\(\)'` ngoài log, chẩn đoán.
- **Ngoại lệ:** log và thông điệp cho người đọc (như `check_failed` in `file_name()`).

```cpp
// ✓ ID bền là hằng viết tay trong kiểu, buộc bằng concept; đổi tên kiểu không đổi dữ liệu.
#include <concepts>
#include <cstdint>

namespace game::sim {

template <class T>
concept Persistent = requires {
    { T::kPersistentId } -> std::convertible_to<std::uint32_t>;
};

struct Damage {
    // ID trên dây và trong DB: không bao giờ đổi, không tái dùng sau khi xoá kiểu.
    static constexpr std::uint32_t kPersistentId = 0x0003'0001U;
    std::int32_t amount = 0;
};

static_assert(Persistent<Damage>);

} // namespace game::sim
```

## Kiểm nhanh

- [ ] Không định danh dành riêng (`_Hoa`, `__`), không khai báo thêm vào `namespace std`? (DD-02)
- [ ] Include đủ và không thừa, header tự đủ? (DD-05)
- [ ] Không `using namespace`, không namespace ẩn danh trong header? (DD-06)
- [ ] Mọi NOLINT có tên check, lý do, mã quy tắc? (DD-08)
- [ ] Định danh ASCII, nguồn UTF-8 NFC, không ký tự hai chiều? (DD-09)
- [ ] Không macro hằng/hàm; macro cấu hình đọc một chỗ thành `constexpr bool`? (DD-10)
- [ ] `<windows.h>` chỉ ở .cpp nền tảng; macro không đổi bố cục kiểu trong header? (DD-14, DD-15)
- [ ] Không ID bền nào sinh từ `typeid`, `function_name()`, `#x`? (DD-16)
