# UB · UB và ổn định

> **Phạm vi:** danh mục UB thường gặp và cách sửa; chính sách sanitizer và hardening thư viện; kiểm
> đầu vào ở ranh giới tin cậy; số học an toàn tràn; UB, implementation-defined, unspecified; ổn
> định vận hành máy chủ (hàng đợi có chặn, giới hạn mỗi phiên, timeout, watchdog, idempotent); trap
> mode, constexpr dò UB, provenance, tín hiệu. **Đọc khi:** viết code đọc byte từ mạng hay file; số
> học trên số lượng, tiền, kích thước, chỉ số; ép số thực ↔ số nguyên; `reinterpret_cast`,
> `memcpy`; cấu hình sanitizer/hardening cho CI hay bản phát hành; thiết kế hàng đợi, giới hạn,
> timeout; điều tra crash "không thể xảy ra". 13 sở hữu CHÍNH SÁCH sanitizer/hardening; cách gắn vào
> build ở refs/14 (BD-*).
> **Liên quan:** refs/05-loi-hop-dong.md (LH-01, LH-03, LH-19), refs/04-so-huu-vong-doi.md (SH-*:
> treo, launder), refs/12-dong-thoi.md (DT-02, DT-09, DT-10, DT-18), refs/15-kiem-thu.md (KT-07,
> KT-11), refs/18-game-mmo.md (MMO-*).

## 0. Danh mục UB thường gặp

UB không có nghĩa "kết quả lạ": chuẩn không ràng buộc gì cho cả lần chạy gặp nó, kể cả các thao
tác TRƯỚC nó ([intro.abstract]/5), và trình dịch tối ưu với giả định nó không xảy ra (UB-19). Không
có "UB vô hại".

| UB | Ví dụ MMO | Sửa | Bắt bằng |
|---|---|---|---|
| Tràn số nguyên có dấu | `hp + heal`, `price * qty` | kiểu rộng, `__builtin_*_overflow` (UB-01, UB-10) | UBSan `signed-integer-overflow`, constexpr |
| Chia 0, `INT_MIN / -1`, `INT_MIN % -1` | chia vàng cho nhóm rỗng | kiểm mẫu (UB-01) | UBSan `integer-divide-by-zero`, `signed-integer-overflow` (`INT_MIN / -1`) |
| Dịch ≥ độ rộng hoặc số bit âm | `1U << flag` từ gói | kiểm `flag < 32` (UB-02) | UBSan `shift` |
| Số thực → nguyên ngoài miền, NaN | toạ độ client → ô lưới | kiểm hữu hạn và miền (UB-05) | Clang UBSan; GCC phải thêm `float-cast-overflow` |
| Ngoài biên mảng; con trỏ ra ngoài `[begin, end]` | đọc gói theo độ dài client khai | span + kiểm độ dài (UB-04, UB-20) | ASan, hardening (UB-08) |
| Đọc biến chưa khởi tạo | struct gói tin thiếu khởi tạo | khởi tạo mọi biến (UB-06, KG-02) | MSan (UB-17), `-Wmaybe-uninitialized` |
| Treo: use-after-free, view sống lâu hơn chủ | `string_view` vào chuỗi tạm | SH-* | ASan |
| Aliasing sai kiểu, lệch căn lề | `*reinterpret_cast<const uint32_t*>(p)` | `memcpy`, `bit_cast` (UB-03) | UBSan `alignment`; aliasing: không công cụ nào bắt chắc |
| `bool`, enum không cố định kiểu nền mang giá trị lạ | `memcpy` byte 2 vào `bool` | hàm kiểm miền (UB-09) | UBSan `bool`, `enum` |
| Tranh chấp dữ liệu | đọc HP ở luồng mạng | DT-02 | TSan |
| Sửa đối tượng `const` | `const_cast` rồi ghi | không `const_cast` để ghi | clang-tidy `cppcoreguidelines-pro-type-const-cast` |
| Chạy hết hàm trả giá trị mà không `return` | quên `return` sau `switch` | `core::fail` sau `switch` (PH-07) | `-Wreturn-type` (trong `-Wall`) |
| Vòng lặp vô hạn không tác dụng phụ | chờ bận trên biến thường | atomic + `wait` (DT-*) | review; C++26 bỏ UB cho vòng lặp tầm thường (P2809) |
| Vi phạm ODR | hai định nghĩa `inline` khác nhau | KTR-* | `-Wodr` với LTO (GCC), ASan `detect_odr_violation` |
| `std::unreachable()` tới được | sau `switch` trên enum từ dây | `core::fail` (LH-02) | UBSan `unreachable` |

## 1. Nền tảng [N]

### UB-01 [N] PHẢI — Số học số nguyên có dấu: chứng minh không tràn hoặc tính ở kiểu rộng hơn; phép chia loại cả mẫu 0 lẫn `INT_MIN / -1`

Cộng, trừ, nhân hai `int32_t` không thể tràn `int64_t`: tính ở `int64_t`, kẹp, rồi thu hẹp. `-x`,
`std::abs(x)` với `x == INT_MIN` cũng là tràn (types.hpp: đổi dấu qua số không dấu).

- **Vì sao:** tràn có dấu là UB ([expr.pre]/4), không quay vòng; trình dịch dựa vào đó bỏ kiểm
  (UB-19). Buff cộng dồn, sát thương nhân hệ số, vàng cộng thưởng là chỗ tràn thật ở MMO. Trên x86,
  `INT_MIN / -1` và chia 0 làm lệnh `idiv` ngắt → SIGFPE, tiến trình chết (đã đo, GCC 14 không
  sanitizer): nếu số chia đến từ client thì đó là nút tắt máy chủ.
- **Kiểm:** UBSan `signed-integer-overflow` trong mọi test (UB-07); `static_assert` ca biên cho hàm
  `constexpr` (UB-16).

```cpp
// ✓ Cộng trong int64 rồi kẹp; static_assert thử ngay ca biên lúc biên dịch.
#include "core/check.hpp"

#include <algorithm>
#include <cstdint>
#include <limits>

namespace game::combat {

struct Vitals {
    std::int32_t health = 0;
    std::int32_t health_max = 0;
};

// amount không âm (hồi máu); kết quả không vượt health_max.
[[nodiscard]] constexpr std::int32_t healed(Vitals vitals, std::int32_t amount) noexcept {
    const std::int64_t raised = std::int64_t{vitals.health} + amount;
    return static_cast<std::int32_t>(std::min<std::int64_t>(raised, vitals.health_max));
}

// members > 0 loại cả chia cho 0 lẫn INT_MIN / -1 (thương 2^31 không biểu diễn được).
[[nodiscard]] constexpr std::int32_t share(std::int32_t total, std::int32_t members) noexcept {
    core::check(members > 0, "share: members phải dương");
    return total / members;
}

inline constexpr std::int32_t kMax = std::numeric_limits<std::int32_t>::max();
static_assert(healed({.health = kMax, .health_max = 100}, kMax) == 100);
static_assert(share(std::numeric_limits<std::int32_t>::min(), 1) < 0);

} // namespace game::combat
```

### UB-02 [N] PHẢI — Số bit dịch nằm trong `[0, độ rộng)` của kiểu SAU thăng hạng; số học trên `uint8_t`/`uint16_t` là số học `int`

Từ C++20 số nguyên có dấu là bù hai: dịch trái số âm và dịch vào bit dấu đã có nghĩa (modulo 2^N).
Còn lại UB: số bit dịch âm hoặc ≥ độ rộng. Toán hạng hẹp hơn `int` được thăng hạng thành `int`
trước: `std::uint16_t a * b` là phép nhân `int`, 65535 × 65535 tràn `int` — UB dù không có số có
dấu nào trong mã nguồn.

- **Vì sao:** lệnh dịch của x86 lấy số bit dịch modulo 32 (64 với toán hạng 64 bit), nên
  `1U << 33` thực tế cho 2 thay vì 0: mặt nạ cờ sai mà không báo. Trình dịch được giả định số bit
  dịch hợp lệ và tối ưu theo đó.
- **Kiểm:** UBSan `shift`; `-Wshift-count-overflow` cho hằng; `-Wconversion` lộ thăng hạng ẩn.

```cpp
// ✓ Số bit dịch từ gói được kiểm; nhân uint16 sau khi đã nâng lên uint32.
#include <cstdint>
#include <optional>

namespace game::proto {

// bits là chỉ số cờ client gửi: ngoài 0..31 là lỗi đầu vào, không để thành UB.
[[nodiscard]] constexpr std::optional<std::uint32_t> flag_mask(std::uint32_t bits) noexcept {
    if (bits >= 32U) return std::nullopt;
    return 1U << bits;
}

// Nâng lên uint32 trước khi nhân: phép nhân không dấu 32 bit, 65535² vẫn vừa.
[[nodiscard]] constexpr std::uint32_t area(std::uint16_t width, std::uint16_t height) noexcept {
    return std::uint32_t{width} * std::uint32_t{height};
}

static_assert(!flag_mask(32) && flag_mask(31) == 0x8000'0000U);
static_assert(area(65'535, 65'535) == 4'294'836'225U);

} // namespace game::proto
```

### UB-03 [N] CẤM — `reinterpret_cast` vùng byte thành số hay struct để đọc; dùng `std::memcpy` vào đối tượng có sẵn hoặc `std::bit_cast`

`*reinterpret_cast<const std::uint32_t*>(buf + off)` gộp ba UB: vi phạm aliasing ([basic.lval]/11),
lệch căn lề khi `off` lẻ, và không có đối tượng `uint32_t` nào sống ở đó. `std::start_lifetime_as`
là C++23 nhưng chưa thư viện nào trong bộ kiểm có (GCC 14.2, 15.2, libc++ 20); dùng `memcpy`.

- **Vì sao:** dưới strict aliasing, trình dịch được coi phép ghi qua `uint32_t*` không đổi `std::byte`
  của buffer và sắp lại lệnh; lỗi chỉ hiện ở `-O2`. `memcpy` cỡ hằng không tốn gì: đã đo, `load_le`
  dưới đây ra đúng một lệnh `movl` ở `-O2` với GCC 14 và Clang 20.
- **Kiểm:** UBSan `alignment`; clang-tidy `cppcoreguidelines-pro-type-reinterpret-cast`; review
  (không công cụ nào bắt chắc aliasing).

```cpp
// ✓ memcpy vào biến cục bộ: không aliasing, không căn lề, không cần đối tượng có sẵn ở đó.
#include <bit>
#include <concepts>
#include <cstddef>
#include <cstring>
#include <span>

namespace game::proto {

// Dây là little-endian (MMO-*). Gọi sau khi đã kiểm độ dài (UB-04):
// load_le<std::uint32_t>(bytes.first<4>()).
template <std::integral T>
[[nodiscard]] inline T load_le(std::span<const std::byte, sizeof(T)> bytes) noexcept {
    T value{};
    std::memcpy(&value, bytes.data(), sizeof(T));
    if constexpr (std::endian::native == std::endian::big) return std::byteswap(value);
    return value;
}

} // namespace game::proto
```

### UB-04 [N] PHẢI — Ranh giới tin cậy: kiểm độ dài trước mọi lần đọc, viết dạng `need > size - pos`; mọi độ dài khai báo có trần

Dữ liệu từ socket chỉ đọc qua một `Reader` trên `std::span` giữ bất biến `pos <= size`. So sánh
dạng trừ: `count > size - pos` không bao giờ quay vòng; `pos + count > size` quay vòng khi `count`
do client khai gần 2^64 và lọt qua kiểm. Dạng con trỏ `cursor + count > end` còn tệ hơn: tạo con
trỏ quá `end` đã là UB ([expr.add]/4), trình dịch được bỏ phép so. Độ dài khai báo (tên, chat, số
phần tử) có trần nghiệp vụ trước khi cấp phát hay đọc. Giữ phần còn lại `rest_` rồi so
`count > rest_.size()` là cùng một dạng (không bao giờ cộng vào vị trí). `Reader` đầy đủ của dự án —
lỗi dính, little-endian, chuỗi UTF-8, kiểm đọc hết — là mẫu của MMO-06; mẫu dưới chỉ minh hoạ phép so.

- **Vì sao:** đây là chỗ máy chủ MMO bị khai thác nhiều nhất: đọc quá biên lộ bộ nhớ người chơi khác,
  độ dài 4 GB làm cấp phát khổng lồ (DoS). Một `Reader` duy nhất thì chỉ một chỗ phải đúng.
- **Kiểm:** fuzz mọi hàm giải mã (KT-11) dưới ASan + UBSan; review: không con trỏ thô, không
  `operator[]` trên dữ liệu thô ngoài `Reader`.

```cpp
// ✓ [chạy] Reader trên span: mọi lần đọc kiểm còn đủ byte; độ dài khai báo bị chặn trên.
#include "core/check.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>

namespace game::proto {

class Reader {
public:
    explicit Reader(std::span<const std::byte> data) noexcept : data_(data) {}

    // Bất biến pos_ <= data_.size(): phép trừ không quay vòng (pos_ + count thì có thể).
    [[nodiscard]] std::optional<std::span<const std::byte>> take(std::size_t count) noexcept {
        if (count > data_.size() - pos_) return std::nullopt;
        const auto out = data_.subspan(pos_, count);
        pos_ += count;
        return out;
    }

private:
    std::span<const std::byte> data_;
    std::size_t pos_ = 0;
};

// Tên nhân vật: tiền tố độ dài u16 little-endian, trần 32 byte bất kể client khai bao nhiêu.
[[nodiscard]] inline std::optional<std::span<const std::byte>> read_name(Reader& reader) noexcept {
    constexpr std::uint32_t kMaxName = 32;
    const auto prefix = reader.take(2);
    if (!prefix) return std::nullopt;
    const auto low = std::to_integer<std::uint32_t>(prefix->front());
    const auto high = std::to_integer<std::uint32_t>(prefix->back());
    const std::uint32_t length = low | (high << 8U);
    if (length > kMaxName) return std::nullopt;
    return reader.take(length);
}

} // namespace game::proto

int main() {
    // Khai 20 byte nhưng chỉ gửi 1: phải bị từ chối, không đọc quá biên.
    constexpr std::array kLying{std::byte{20}, std::byte{0}, std::byte{'a'}};
    game::proto::Reader reader{kLying};
    game::core::check(!game::proto::read_name(reader).has_value(), "phải từ chối gói nói dối");
    return 0;
}
```

### UB-05 [N] PHẢI — Đổi số thực sang số nguyên chỉ sau khi kiểm hữu hạn và trong miền đích

Giá trị thực ngoài miền kiểu nguyên đích (kể cả NaN, vô cùng) khi ép là UB ([conv.fpint]/1). Viết
điều kiện theo chiều "phải đúng" (`x >= lo && x < hi`): mọi phép so với NaN đều sai nên NaN rơi vào
nhánh từ chối; dạng `x < lo || x >= hi` để NaN lọt qua.

- **Vì sao:** toạ độ, góc, tốc độ từ client là `float` tuỳ ý. x86 (`cvttss2si`) trả `INT_MIN` cho
  giá trị ngoài miền: ô lưới âm, chỉ số mảng âm, đọc quá biên. Đã đo: `-fsanitize=undefined` của
  Clang 20 bắt lỗi này, của GCC 14/15 KHÔNG (phải thêm `-fsanitize=float-cast-overflow`, UB-07).
- **Kiểm:** UBSan (Clang; GCC cần cờ thêm); test ca biên NaN, ±vô cùng, 1e30, -0.0 (KT-03).

```cpp
// ✓ [chạy] Toạ độ client → ô lưới: NaN, vô cùng, ngoài bản đồ bị từ chối TRƯỚC khi ép kiểu.
#include "core/check.hpp"

#include <cstdint>
#include <limits>
#include <optional>

namespace game::world {

inline constexpr float kWorldSize = 16'384.0F;
inline constexpr float kCellSize = 32.0F;

[[nodiscard]] inline std::optional<std::int32_t> cell_of(float coord) noexcept {
    // NaN làm cả hai phép so sai nên rơi vào nhánh từ chối.
    const bool inside = coord >= 0.0F && coord < kWorldSize;
    if (!inside) return std::nullopt;
    return static_cast<std::int32_t>(coord / kCellSize);
}

} // namespace game::world

int main() {
    using game::world::cell_of;
    constexpr float kNan = std::numeric_limits<float>::quiet_NaN();
    constexpr float kInf = std::numeric_limits<float>::infinity();
    game::core::check(!cell_of(kNan) && !cell_of(kInf) && !cell_of(1e30F), "phải từ chối");
    game::core::check(cell_of(16'383.9F) == 511 && cell_of(-0.0F) == 0, "ô biên");
    return 0;
}
```

### UB-06 [N] CẤM — Đọc giá trị chưa khởi tạo; gói tin ghi từng trường, không `memcpy` cả struct có byte đệm

Mọi biến khởi tạo lúc khai báo (KG-02). Byte đệm của struct không bao giờ được khởi tạo một cách
đáng tin, nên `memcpy(&packet, &spawn, sizeof spawn)` gửi rác của ngăn xếp ra mạng. C++23: đọc
biến tự động chưa khởi tạo là UB; C++26 (P2795) đổi thành "erroneous behaviour" — giá trị do cài
đặt chọn, không còn UB; biến gắn `[[indeterminate]]` giữ hành vi cũ (đọc là UB). Lớp phòng thủ
C++23: `-ftrivial-auto-var-init=pattern` cho debug (rác dễ nhận), `=zero` cho phát hành (đã thử:
GCC 14 và Clang 20 nhận cả hai; cách gắn: BD-09) — không thay cho khởi tạo, và tắt ở bản MSan
(giá trị đã được ghi thì MSan không còn thấy đọc chưa khởi tạo).

- **Vì sao:** byte đệm chở mảnh khoá phiên, con trỏ (lộ ASLR), dữ liệu người chơi khác — rò thông
  tin kiểu Heartbleed. Đọc rác cho kết quả khác nhau giữa bản build: lệch replay, lỗi không tái hiện.
- **Kiểm:** `-Wuninitialized`, `-Wmaybe-uninitialized` (GCC, cần `-O1` trở lên); MSan (UB-17);
  KG-17 chốt bố cục struct mạng bằng `static_assert`.

```cpp
// ✓ Ghi từng trường vào buffer đã khởi tạo: byte đệm của struct không bao giờ rời máy chủ.
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace game::proto {

struct Spawn {
    // Theo sau kind là 3 byte đệm trong bộ nhớ.
    std::uint8_t kind = 0;
    std::uint32_t entity = 0;
};

static_assert(std::endian::native == std::endian::little, "dây little-endian, chép thẳng");

[[nodiscard]] inline std::array<std::byte, 5> encode(const Spawn& spawn) noexcept {
    std::array<std::byte, 5> out{};
    out[0] = std::byte{spawn.kind};
    std::memcpy(&out[1], &spawn.entity, sizeof spawn.entity);
    return out;
}

} // namespace game::proto
```

### UB-07 [N] PHẢI — Mọi test chạy dưới ASan + UBSan với `-fno-sanitize-recover=all`; TSan ở bản riêng; GCC thêm `float-cast-overflow`

| Sanitizer | Bắt | Chi phí (tài liệu LLVM) | Ghép được với |
|---|---|---|---|
| ASan | tràn biên heap/stack/global, use-after-free, use-after-return, double free, rò bộ nhớ (LSan) | chậm ~2× | UBSan |
| UBSan | tràn có dấu, dịch, chia 0, null, căn lề, `bool`/enum lạ, float → int (Clang) | nhỏ | ASan |
| TSan | tranh chấp dữ liệu (DT-02) | chậm 5–15×, bộ nhớ 5–10× | không ghép |
| MSan (chỉ Clang) | đọc chưa khởi tạo | chậm ~3× | không ghép; mọi mã phải instrument (UB-17) |

- **Vì sao:** UBSan mặc định chỉ in rồi chạy tiếp: CI xanh dù có UB; `-fno-sanitize-recover=all`
  biến mỗi phát hiện thành thoát mã khác 0. Đã đo GCC 14/15: `-fsanitize=undefined` không gồm
  `float-cast-overflow`, nên ép `1e30F` sang `int` trôi qua im lặng (Clang 20 bắt).
- **Kiểm:** preset CI (cách gắn: BD-08); job kiểm thử của ma trận CI (KT-07).

```bash
# Mọi bản test: ASan + UBSan, dừng ở lỗi đầu tiên, giữ frame pointer cho stacktrace.
SAN="-O1 -g -fno-omit-frame-pointer -fsanitize=address,undefined -fno-sanitize-recover=all"
SAN_GCC="$SAN -fsanitize=float-cast-overflow"    # GCC: không có trong undefined
TSAN="-O1 -g -fno-omit-frame-pointer -fsanitize=thread"    # bản riêng cho test có luồng
export ASAN_OPTIONS=abort_on_error=1:detect_leaks=1:detect_stack_use_after_return=1:strict_string_checks=1
export UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1
# Windows, Clang + STL MSVC 14.51 (đo 2026-10-08, CL-02): thêm bốn nhóm bắt lỗi không phải UB, kèm
# hardening. implicit-integer-sign-change không bật: báo nhầm bên trong xcharconv_ryu.h của STL MSVC.
SAN_WIN="-O1 -g -fno-omit-frame-pointer -fno-sanitize-recover=all -D_MSVC_STL_HARDENING=1 \
  -fsanitize=address,undefined,implicit-integer-truncation,local-bounds,float-divide-by-zero,nullability"
```

### UB-08 [N] PHẢI — Bật hardening thư viện chuẩn ở mọi bản build: mức đầy đủ cho debug và test, mức nhanh cho máy chủ phát hành

Hardening biến vi phạm tiền điều kiện của thư viện (`operator[]` quá biên, `front()` trên vector
rỗng, `*opt` khi rỗng, `*exp` khi mang lỗi) từ UB thành dừng. Đã đo với mẫu đọc quá biên: không
hardening thì đọc rác, thoát 0; `_GLIBCXX_ASSERTIONS` (GCC 14) abort kèm dòng chẩn đoán; libc++ 20
`FAST`/`EXTENSIVE` dừng bằng trap (SIGILL, không thông điệp), `DEBUG` abort kèm thông điệp. STL MSVC
14.51 (đo 2026-10-08): `_MSVC_STL_HARDENING=1` dừng bằng bẫy, mã thoát 0xC000001D, không thông điệp;
`*optional` rỗng thoát 0 dưới ASan + UBSan và chỉ dừng khi bật hardening.

- **Vì sao:** lỗi biên trong code dùng thư viện chuẩn thành crash có ngăn xếp tại chỗ, thay vì
  hỏng dữ liệu lặng lẽ rồi sập ở chỗ khác. `_GLIBCXX_ASSERTIONS` không đổi ABI; `_GLIBCXX_DEBUG` đổi
  bố cục container nên mọi TU và thư viện phải cùng cờ — không dùng trong bản phát hành. Bản test
  một chương trình thì dùng được: `check.py --run` chạy GCC với `_GLIBCXX_DEBUG`, bắt cả iterator đã
  vô hiệu (CL-02).
- **Kiểm:** cờ có trong preset (BD-*); một test cố ý đọc quá biên phải dừng (KT-14).

```bash
# libstdc++ (GCC): debug, test và cả máy chủ phát hành — chi phí nhỏ, đo trên ngân sách tick (HN-08).
-D_GLIBCXX_ASSERTIONS
# libc++ 20: debug và test (thông điệp); máy chủ phát hành (trap, rẻ hơn).
-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG
-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST
# STL MSVC (cl và Clang nhắm MSVC): mọi bản build.
-D_MSVC_STL_HARDENING=1
```

### UB-09 [N] PHẢI — Giải mã `enum`, `bool`, chỉ số từ dây qua hàm kiểm miền; không `static_cast` hay `memcpy` thẳng

`bool` chỉ có hai biểu diễn hợp lệ: `memcpy` byte 2 vào `bool` là UB (UBSan `bool`). Enum không cố
định kiểu nền nhận giá trị ngoài miền là UB ([expr.static.cast]/10). `enum class : std::uint8_t`
nhận mọi giá trị `uint8_t` mà không UB, nhưng `switch` không `default` rồi `core::fail` (LH-04) thì
một byte lạ thành abort do client gây ra (LH-03).

- **Vì sao:** sau khi kiểm miền ở ranh giới, mọi code phía trong được tin enum hợp lệ và giữ `switch`
  đầy đủ không `default`. Kiểm rải rác ở phía trong thì sẽ có chỗ quên.
- **Kiểm:** grep `static_cast<.*Kind>` trong `proto/`; UBSan `bool`, `enum`; fuzz (KT-11).

```cpp
// ✓ Byte từ dây → enum/bool qua hàm kiểm miền; giá trị lạ là lỗi đầu vào, không phải UB.
#include <cstdint>
#include <optional>
#include <utility>

namespace game::proto {

enum class ItemKind : std::uint8_t { kWeapon, kArmor, kPotion, kCount };

[[nodiscard]] constexpr std::optional<ItemKind> to_item_kind(std::uint8_t raw) noexcept {
    if (raw >= std::to_underlying(ItemKind::kCount)) return std::nullopt;
    return static_cast<ItemKind>(raw);
}

[[nodiscard]] constexpr std::optional<bool> to_flag(std::uint8_t raw) noexcept {
    if (raw > 1) return std::nullopt;
    return raw == 1;
}

static_assert(!to_item_kind(3) && to_item_kind(2) == ItemKind::kPotion);
static_assert(!to_flag(2) && *to_flag(1) && !*to_flag(0));

} // namespace game::proto
```

## 2. Nâng cao [C]

### UB-10 [C] PHẢI — Số học tiền tệ và kích thước dùng `__builtin_*_overflow` bọc trong hàm `checked_*`; `std::add_sat`/`std::mul_sat` là C++26

`__builtin_add_overflow`, `__builtin_sub_overflow`, `__builtin_mul_overflow` (GCC, Clang) tính như
số nguyên vô hạn rồi báo kết quả có vừa kiểu đích không; nhận kiểu khác nhau; dùng được trong
`constexpr` (đã thử ở cả ba trình dịch). MSVC không có: bọc trong một hàm để thay bằng kiểm chia
trước ở đó. C++26 có `std::add_sat`…(bão hoà, không báo lỗi); C++23 thì chưa.

- **Vì sao:** `giá × số lượng` tràn `int64_t` là lỗi khai thác kinh tế kinh điển: tổng thành âm
  hoặc nhỏ, người mua nhận hàng gần như miễn phí. Ở đây tràn là lỗi đầu vào phải từ chối, không
  phải UB, cũng không phải giá trị bão hoà.
- **Kiểm:** review: mọi phép nhân trên số lượng/giá đi qua `checked_*`; `static_assert` ca biên.
- **Ngoại lệ:** cộng/trừ trên giá trị đã có trần chứng minh được (số dư trong `[0, kMaxCopper]`,
  MMO-07) kiểm bằng so với trần ở dạng không thể tràn (`amount > kMax - balance`), như UB-01 cho phép.

```cpp
// ✓ Giá × số lượng từ client: tràn int64 là lỗi đầu vào, không thành vàng âm.
#include <cstdint>
#include <limits>
#include <optional>

namespace game::inv {

// Kết quả số học đã kiểm: nullopt khi tràn int64 hoặc đầu vào ngoài miền.
using Checked = std::optional<std::int64_t>;

[[nodiscard]] constexpr Checked checked_mul(std::int64_t lhs, std::int64_t rhs) noexcept {
    std::int64_t product = 0;
    if (__builtin_mul_overflow(lhs, rhs, &product)) return std::nullopt;
    return product;
}

[[nodiscard]] constexpr Checked total_price(std::int64_t unit_price, std::int32_t quantity) noexcept {
    if (unit_price < 0 || quantity <= 0) return std::nullopt;
    return checked_mul(unit_price, quantity);
}

static_assert(!total_price(std::numeric_limits<std::int64_t>::max() / 2, 3));
static_assert(total_price(1'000, 99) == 99'000);

} // namespace game::inv
```

### UB-11 [C] PHẢI — Phân biệt UB, implementation-defined, unspecified; code tất định không dựa vào hai loại sau

| Loại | Nghĩa | Ví dụ | Chính sách |
|---|---|---|---|
| UB | không ràng buộc gì | tràn có dấu, quá biên | cấm (bảng mục 0) |
| Implementation-defined | cài đặt chọn và ghi tài liệu | `sizeof(long)` (8 Linux, 4 Windows), `char` có dấu hay không | kiểu cỡ cố định; `static_assert` giả định |
| Unspecified | cài đặt chọn, không cần ghi, có thể đổi mỗi lần | thứ tự đánh giá đối số hàm, thứ tự duyệt `unordered_map` | không phụ thuộc |
| Erroneous (C++26) | đọc biến chưa khởi tạo: giá trị sai nhưng không UB | `int x; return x;` | vẫn cấm (UB-06) |

- **Vì sao:** đã đo `make_cell(cursor.next(), cursor.next())`: GCC 14/15 gọi `next()` bên phải
  trước, Clang 20 bên trái trước — cùng gói tin ra toạ độ đảo ngược giữa hai bản build. Danh sách
  khởi tạo trong ngoặc nhọn được đánh giá trái sang phải ([dcl.init.list]/4), hoặc tách câu lệnh.
- **Kiểm:** review: không có hai đối số cùng gọi hàm có tác dụng phụ; ma trận GCC + Clang (KT-19).

```cpp
// ✓ Đọc tuần tự bằng câu lệnh riêng: thứ tự là thứ tự dòng, như nhau trên mọi trình dịch.
#include <cstdint>

namespace game::proto {

struct Cursor {
    std::int32_t pos = 0;
    [[nodiscard]] std::int32_t next() noexcept { return ++pos; }
};

struct Cell {
    std::int32_t column = 0;
    std::int32_t row = 0;
};

[[nodiscard]] inline Cell read_cell(Cursor& cursor) noexcept {
    const std::int32_t column = cursor.next();
    const std::int32_t row = cursor.next();
    return Cell{.column = column, .row = row};
}

} // namespace game::proto
```

### UB-12 [C] CẤM — Dùng `-fwrapv`, `-fno-strict-aliasing`, `-fno-delete-null-pointer-checks` làm "cách sửa" UB

- **Vì sao:** cờ biến code thành một phương ngữ: header đem sang dự án khác, hay sang MSVC, lại UB.
  Logic vẫn sai (HP quay vòng thành số âm vẫn là lỗi game). Mất tối ưu: biến đếm `int` trong vòng
  lặp không còn được mở rộng thành 64 bit dựa trên giả định không tràn. Tệ nhất, cờ che lỗi khỏi
  công cụ — đã đo: với `-fwrapv`, GCC 14 không báo tràn kể cả khi bật tường minh
  `-fsanitize=signed-integer-overflow`; Clang 20 bỏ `signed-integer-overflow` khỏi nhóm `undefined`.
- **Kiểm:** grep cờ trong CMake; review cấu hình build (BD-*).
- **Ngoại lệ:** target riêng của mã bên thứ ba đã biết cần cờ, không lan sang target của dự án.

```diff
# ✗ → ✓ Bỏ cờ "chữa" UB; sửa code: kiểu rộng hoặc __builtin_*_overflow (UB-01, UB-10),
#   đọc byte bằng memcpy (UB-03), kiểm null trước khi dereference (UB-19).
-target_compile_options(game_core PRIVATE -fwrapv -fno-strict-aliasing)
+target_link_libraries(game_core PRIVATE game::warnings)
```

### UB-13 [C] PHẢI — Hàng đợi gửi mỗi phiên có trần byte; đầy thì ngắt phiên chậm, không tăng vô hạn

Mọi hàng đợi trong máy chủ có trần (DT-08). Phía gửi mỗi phiên: trần theo byte; vượt trần nghĩa là
client không đọc kịp (mạng chậm, hay cố ý không đọc) → ngắt phiên đó. Phía nhận: hàng đợi mạng →
game đầy thì ngừng đọc socket (TCP tự đẩy ngược về client) hoặc ngắt phiên gửi dồn.

- **Vì sao:** không trần thì một client cố ý không đọc làm máy chủ giữ mọi snapshot gửi cho nó: bộ
  nhớ tăng tới khi OOM killer giết cả zone. Trần đổi lỗi của một phiên thành hậu quả của chính phiên đó.
- **Kiểm:** test: phiên không đọc, đẩy tới trần → `push` trả `false`; số liệu độ dài hàng đợi p99.

```cpp
// ✓ Hàng đợi gửi của một phiên: chặn theo byte; false nghĩa là phải ngắt phiên này.
#include <cstddef>
#include <deque>
#include <utility>
#include <vector>

namespace game::net {

// Chỉ luồng mạng sở hữu phiên chạm vào (DT-01).
class Outbox {
public:
    // Không noexcept: std::deque của MSVC cấp phát ngay khi dựng (đo: clang-tidy 23 + STL MSVC).
    explicit Outbox(std::size_t byte_limit) : byte_limit_(byte_limit) {}

    // Không noexcept: push_back có thể ném bad_alloc, lên tới hàm vào luồng thì dừng (LH-07).
    [[nodiscard]] bool push(std::vector<std::byte> packet) {
        if (packet.size() > byte_limit_ - queued_bytes_) return false;
        queued_bytes_ += packet.size();
        packets_.push_back(std::move(packet));
        return true;
    }

private:
    std::deque<std::vector<std::byte>> packets_;
    std::size_t byte_limit_ = 0;
    // Bất biến: queued_bytes_ <= byte_limit_.
    std::size_t queued_bytes_ = 0;
};

} // namespace game::net
```

### UB-14 [C] PHẢI — Mỗi phiên có giới hạn tốc độ theo tick (token bucket số nguyên) và ngân sách tài nguyên

Mỗi loại yêu cầu tốn kém (chat, di chuyển, giao dịch, truy vấn DB) có một bucket; mỗi phiên có trần:
cỡ gói, số thao tác DB đang chờ, độ dài chat, số đối tượng đăng ký AOI. Tính bằng tick và số nguyên
(MMO-03), không đồng hồ thật, không `float`. Bucket theo tick chạy trên luồng zone ở đầu tick; luồng
IO chỉ chặn ở mức kết nối và byte (MMO-05).

- **Vì sao:** không giới hạn thì một client tự động hoá gửi 10 000 lệnh mỗi giây chiếm cả ngân sách
  tick (HN-08) — DoS từ bên trong phiên hợp lệ. Số nguyên + tick: tất định, test được không cần chờ
  (KT-05), replay ra đúng kết quả.
- **Kiểm:** test thuộc tính: không chuỗi tick nào cho tiêu quá `capacity + refill × số tick`.

```cpp
// ✓ Token bucket theo tick, số nguyên: tất định, không tràn, test ngay lúc biên dịch.
#include "core/check.hpp"

#include <algorithm>
#include <cstdint>
#include <utility>

namespace game::sim {

// Mốc: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

struct TokenBucket {
    // capacity và refill_per_tick là cấu hình, mỗi giá trị trong 1..2^31.
    std::int64_t capacity = 0;
    std::int64_t refill_per_tick = 0;
    std::int64_t tokens = 0;
    Tick last{};
};

// Kẹp số tick trôi ở capacity (refill >= 1 thì sau chừng ấy tick bucket đã đầy): tích <= 2^62.
[[nodiscard]] constexpr bool try_spend(TokenBucket& bucket, Tick now, std::int64_t cost) noexcept {
    core::check(now >= bucket.last && cost >= 0, "try_spend: now không lùi và cost >= 0");
    const std::uint64_t passed = std::to_underlying(now) - std::to_underlying(bucket.last);
    const auto limit = static_cast<std::uint64_t>(bucket.capacity);
    const auto elapsed = static_cast<std::int64_t>(std::min(passed, limit));
    bucket.tokens = std::min(bucket.capacity, bucket.tokens + (elapsed * bucket.refill_per_tick));
    bucket.last = now;
    if (bucket.tokens < cost) return false;
    bucket.tokens -= cost;
    return true;
}

static_assert([] {
    TokenBucket bucket{.capacity = 3, .refill_per_tick = 1, .tokens = 3, .last = Tick{0}};
    const bool burst = try_spend(bucket, Tick{0}, 3);
    const bool drained = !try_spend(bucket, Tick{0}, 1);
    const bool refilled = try_spend(bucket, Tick{2}, 2);
    return burst && drained && refilled;
}());

} // namespace game::sim
```

### UB-15 [C] PHẢI — Mọi chờ đợi có thời hạn; tick có watchdog; chỉ thử lại thao tác idempotent mang id yêu cầu

Mọi IO (socket, DB, HTTP nội bộ) có deadline; không `wait()` không hạn. Luồng game ghi nhịp mỗi tick;
luồng giám sát thấy nhịp ngừng quá ngưỡng thì `core::fail` → core dump chụp ngăn xếp mọi luồng (gdb
`thread apply all bt`) → khởi động lại (LH-19). Thao tác DB thử lại được chỉ khi idempotent: mang id
yêu cầu duy nhất, DB bỏ qua id đã áp dụng (khoá duy nhất trên id).

- **Vì sao:** tick treo (khoá chết, vòng lặp vô hạn) làm zone đứng mà tiến trình vẫn "sống" — giám
  sát tiến trình không thấy. Thử lại thao tác không idempotent sau timeout (gói trả lời bị mất, không
  phải lệnh) là nhân đôi giao dịch, nhân bản vật phẩm.
- **Kiểm:** test watchdog bằng đồng hồ giả (KT-05); review: mọi lời gọi chờ có tham số deadline;
  mọi bảng giao dịch có ràng buộc duy nhất trên id yêu cầu.

```cpp
// ✓ Watchdog: luồng game ghi nhịp mỗi tick; luồng giám sát hỏi stalled() định kỳ.
#include <atomic>
#include <chrono>

namespace game::app {

class Watchdog {
public:
    using Clock = std::chrono::steady_clock;

    explicit Watchdog(Clock::time_point start) noexcept : last_beat_(start.time_since_epoch().count()) {}

    // relaxed đủ: chỉ cần chính con số nguyên tử, không công bố dữ liệu nào khác kèm nó.
    void beat(Clock::time_point now) noexcept {
        last_beat_.store(now.time_since_epoch().count(), std::memory_order_relaxed);
    }

    [[nodiscard]] bool stalled(Clock::time_point now, Clock::duration limit) const noexcept {
        const Clock::duration last{last_beat_.load(std::memory_order_relaxed)};
        return now.time_since_epoch() - last > limit;
    }

private:
    std::atomic<Clock::rep> last_beat_;
};

static_assert(std::atomic<Watchdog::Clock::rep>::is_always_lock_free);

} // namespace game::app
```

## 3. Thần thoại [T]

### UB-16 [T] NÊN — Dùng đánh giá hằng làm máy dò UB: hàm thuần `constexpr` thử ca biên bằng `static_assert`

Khi tính hằng, trình dịch BẮT BUỘC từ chối biểu thức gặp UB của ngôn ngữ lõi ([expr.const]/5): tràn
có dấu, dịch sai, chia 0, con trỏ ra ngoài mảng, đọc chưa khởi tạo, dùng đối tượng hết vòng đời.
Không bắt buộc với UB của thư viện chuẩn, và không phủ được tranh chấp dữ liệu hay ngoại lệ đường
chạy. Bổ sung, không thay sanitizer.

- **Vì sao:** sanitizer chỉ thấy đường đã chạy; `static_assert` trên `INT_MIN`, `INT_MAX`, `0`, `-1`
  là bằng chứng mỗi lần build, không tốn gì lúc chạy. Cùng cơ chế với LH-16 và KT-04.
- **Kiểm:** mẫu ✗ dưới đây bị cả ba trình dịch từ chối; mỗi hàm thuần số học có khối `static_assert`.

```cpp
// ✗ [không biên dịch] Tính hằng gặp tràn có dấu: trình dịch buộc phải từ chối.
#include <cstdint>
#include <limits>

namespace game::combat {

constexpr std::int32_t heal_raw(std::int32_t health, std::int32_t amount) noexcept {
    return health + amount;
}

static_assert(heal_raw(std::numeric_limits<std::int32_t>::max(), 1) > 0);

} // namespace game::combat
```

```cpp
// ✓ Zigzag (varint có dấu) thử mọi ca biên lúc biên dịch: còn UB là không build được.
#include <cstdint>
#include <limits>

namespace game::proto {

// Số có trị tuyệt đối nhỏ thành mã nhỏ: 0→0, -1→1, 1→2, -2→3. Toàn bộ trên số không dấu.
[[nodiscard]] constexpr std::uint32_t zigzag(std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    return (bits << 1U) ^ (0U - (bits >> 31U));
}

[[nodiscard]] constexpr std::int32_t unzigzag(std::uint32_t code) noexcept {
    return static_cast<std::int32_t>((code >> 1U) ^ (0U - (code & 1U)));
}

inline constexpr std::int32_t kMin = std::numeric_limits<std::int32_t>::min();
inline constexpr std::int32_t kMax = std::numeric_limits<std::int32_t>::max();
static_assert(zigzag(0) == 0 && zigzag(-1) == 1 && zigzag(1) == 2 && zigzag(kMin) == 0xFFFF'FFFFU);
static_assert(unzigzag(zigzag(kMin)) == kMin && unzigzag(zigzag(kMax)) == kMax);

} // namespace game::proto
```

### UB-17 [T] NÊN — Một bản CI Clang thêm UBSan mở rộng (`implicit-conversion`, `local-bounds`) và một bản MSan khi mọi mã được instrument

`implicit-conversion` bắt thu hẹp và đổi dấu ngầm làm đổi giá trị (không phải UB nhưng là lỗi:
`uint32_t` 301 → `uint8_t` 45). Nhóm `integer` thêm `unsigned-integer-overflow` — KHÔNG phải UB, và
hash, PRNG cố ý quay vòng, nên bật thì phải có danh sách loại trừ; `[[clang::no_sanitize]]` làm GCC
cảnh báo thuộc tính lạ (đã thử: lỗi dưới `-Werror`). MSan chỉ có ở Clang, không ghép với ASan, và
cần MỌI mã kể cả libc++ biên dịch với `-fsanitize=memory`, nếu không báo sai hàng loạt. Windows
với STL MSVC 14.51 (đo 2026-10-08): `implicit-integer-sign-change` báo nhầm trong `xcharconv_ryu.h`,
nên `check.py --run` chỉ bật `implicit-integer-truncation` cùng `local-bounds`,
`float-divide-by-zero`, `nullability` — và bật cho mọi lần chạy test, không chỉ một job CI (CL-02).

- **Vì sao:** lỗi thu hẹp ngầm (số lượng 300 thành 44 trong gói `uint8_t`) không phải UB nên UBSan
  thường bỏ qua, `-Wconversion` chỉ thấy ở chỗ không có ép tường minh.
- **Kiểm:** job CI riêng; nhóm bung ra đo bằng `clang++ -fsanitize=… -### -x c++ /dev/null`.

```bash
# Clang 20 (đo bằng -###): implicit-conversion = implicit-unsigned-integer-truncation,
#   implicit-signed-integer-truncation, implicit-integer-sign-change, implicit-bitfield-conversion.
clang++ -fsanitize=address,undefined,implicit-conversion,local-bounds -fno-sanitize-recover=all …
# Bật cả unsigned-integer-overflow (nhóm integer) thì loại trừ hàm cố ý quay vòng:
#   ci/ubsan-ignore.txt chứa dòng   fun:*fnv1a*
clang++ -fsanitize=integer -fsanitize-ignorelist=ci/ubsan-ignore.txt …
# MSan: một mình; libc++ cũng phải là bản build với -fsanitize=memory.
clang++ -fsanitize=memory -fsanitize-memory-track-origins=2 -fno-omit-frame-pointer …
```

### UB-18 [T] CÓ THỂ — Máy chủ phát hành giữ một tập UBSan rẻ ở chế độ trap

Chọn kiểm rẻ và đáng giá nhất (biên mảng, dịch, chia 0, tràn có dấu), cho dừng bằng lệnh trap không
cần runtime. Kết hợp hardening `FAST` (UB-08) và crash-only (LH-19): trap → core dump → khởi động
lại, thay vì chạy tiếp trên bộ nhớ hỏng. Đo chi phí trên ngân sách tick (HN-08) trước khi bật.

- **Vì sao:** đã đo: GCC 14 và Clang 20 với `-fsanitize-trap=all` sinh `ud2` (thoát do SIGILL, mã
  132), không liên kết thư viện sanitizer nào. Clang `-fsanitize-minimal-runtime` in một dòng
  (`ubsan: add-overflow by 0x…`) — đủ để biết loại lỗi mà không kéo runtime đầy đủ — nhưng mặc định
  in rồi CHẠY TIẾP (đo: mã thoát 0); phải thêm `-fno-sanitize-recover=all` thì mới abort (mã 134).
- **Kiểm:** `ldd` binary không có `libubsan`; test chủ ý tràn trong bản phát hành phải dừng mã 132.

```bash
# Bản phát hành máy chủ: kiểm rẻ, gặp lỗi là trap (SIGILL) → core dump → giám sát khởi động lại.
-fsanitize=bounds,shift,integer-divide-by-zero,signed-integer-overflow -fsanitize-trap=all
# Clang: thêm một dòng chẩn đoán, runtime tối giản; thiếu -fno-sanitize-recover thì in rồi chạy tiếp.
-fsanitize=bounds,shift,integer-divide-by-zero,signed-integer-overflow -fsanitize-minimal-runtime \
    -fno-sanitize-recover=all
```

### UB-19 [T] PHẢI — Biết trình dịch khai thác UB: kiểm tràn đặt sau phép tràn và kiểm null đặt sau dereference đều bị xoá

Trình dịch suy luận ngược từ UB: đã có `offset + length` (`int`) thì tổng không tràn, nên
`offset + length < offset` tương đương `length < 0`; đã đọc `player->level` thì `player` khác null,
nên `if (player == nullptr)` là chết. Đã đo `-O2`: GCC 14 và Clang 20 đều biến kiểm tràn của mẫu ✗
thành `length < 0` (GCC: `test`/`js`; Clang: `test`/`setns`) và xoá hẳn kiểm null — `level_of`
còn đúng một lệnh `mov`.

- **Vì sao:** "thêm kiểm cho chắc" sau khi UB đã xảy ra không bảo vệ gì; thậm chí được biên dịch thành
  phép thử khác. Với `offset = INT_MAX - 1`, `length = 10`: kiểm qua, phép cộng thành số âm `<= size`,
  hàm trả "vừa" — đọc quá biên.
- **Kiểm:** UBSan; asm (HN-15); quy tắc: kiểm TRƯỚC phép tính bằng dạng không thể tràn (UB-04).

```cpp
// ✗ Kiểm tràn SAU phép tràn, kiểm null SAU dereference: -O2 biến dạng hoặc xoá cả hai.
#include <cstdint>

namespace game::proto {

struct Player {
    std::int32_t level = 0;
};

inline bool fits(std::int32_t offset, std::int32_t length, std::int32_t size) noexcept {
    if (offset + length < offset) return false;
    return offset + length <= size;
}

inline std::int32_t level_of(const Player* player) noexcept {
    const std::int32_t level = player->level;
    if (player == nullptr) return 0;
    return level;
}

} // namespace game::proto
```

```cpp
// ✓ Kiểm trước khi tính, bằng phép trừ không thể tràn; con trỏ có thể null thì kiểm trước khi đọc.
#include <cstdint>

namespace game::proto {

struct Player {
    std::int32_t level = 0;
};

[[nodiscard]] constexpr bool fits(std::uint32_t offset, std::uint32_t length, std::uint32_t size) noexcept {
    return offset <= size && length <= size - offset;
}

[[nodiscard]] inline std::int32_t level_of(const Player* player) noexcept {
    if (player == nullptr) return 0;
    return player->level;
}

static_assert(!fits(0xFFFF'FFF0U, 0x20U, 0xFFFF'FFFFU) && fits(4, 4, 8));

} // namespace game::proto
```

### UB-20 [T] PHẢI — Con trỏ chỉ đi trong `[begin, end]` của đúng một mảng; thứ tự giữa con trỏ khác mảng dùng `std::less`

Tạo con trỏ ngoài `[begin, end]` là UB kể cả không dereference ([expr.add]/4) — vậy kiểm biên phải
làm trên độ dài (UB-04). So sánh `<`, `>=` giữa con trỏ không cùng mảng cho kết quả unspecified
([expr.rel]); `std::less<T*>` đảm bảo thứ tự toàn phần nhất quán ([comparisons.general]).
Đổi con trỏ sang `std::uintptr_t` rồi về NGUYÊN giá trị thì được bảo đảm
([expr.reinterpret.cast]/5), nhưng ánh xạ là implementation-defined; con trỏ dựng từ số nguyên đã
qua tính toán ("đoán ra") thì theo mô hình provenance mà GCC/Clang dùng khi tối ưu, trình dịch được
coi nó không trỏ vào đối tượng nào nó biết.

- **Vì sao:** câu hỏi "con trỏ này có thuộc arena của ta không" (allocator, pool theo tick) là chỗ
  hay viết `p >= begin && p < end` với `p` lạ: trình dịch được gập phép so, và trên nền tảng có bộ
  nhớ phân đoạn thì sai thật.
- **Kiểm:** UBSan `pointer-overflow`; review mọi phép cộng con trỏ (clang-tidy
  `cppcoreguidelines-pro-bounds-pointer-arithmetic`).

```cpp
// ✓ Arena hỏi "con trỏ này có phải của ta": std::less cho thứ tự toàn phần, không cộng con trỏ.
#include <cstddef>
#include <functional>
#include <memory>
#include <span>

namespace game::mem {

[[nodiscard]] inline bool owns(std::span<const std::byte> arena, const std::byte* ptr) noexcept {
    // Thứ tự toàn phần, đúng cả với con trỏ khác mảng.
    const std::less<> before;
    const std::byte* const first = std::to_address(arena.begin());
    const std::byte* const last = std::to_address(arena.end());
    return !before(ptr, first) && before(ptr, last);
}

} // namespace game::mem
```

### UB-21 [T] PHẢI — Handler tín hiệu chỉ ghi một `std::atomic` không khoá; mọi việc khác làm ở vòng tick

Trong handler chỉ được thao tác "signal-safe" ([support.signal]): atomic không khoá, cộng hàm
async-signal-safe của POSIX. Không cấp phát, không `printf`, không log, không mutex. `volatile
std::sig_atomic_t` cũng hợp lệ nhưng `volatile` không đồng bộ giữa luồng (DT-18), nên dùng
`std::atomic<bool>` có `is_always_lock_free`. POSIX: `sigaction` cho kiểm soát cờ (`SA_RESTART`);
`std::signal` là phần thuần chuẩn.

- **Vì sao:** tín hiệu ngắt luồng ở bất kỳ lệnh nào, kể cả giữa `malloc` đang giữ khoá: handler gọi
  `malloc` là khoá chết; gọi `printf` là hỏng buffer. Vòng tick đọc cờ rồi tắt êm có thứ tự.
- **Kiểm:** clang-tidy `bugprone-signal-handler` (bí danh `cert-msc54-cpp`); review handler.

```cpp
// ✓ [chạy] SIGTERM: handler chỉ ghi một atomic không khoá; vòng tick đọc cờ và tự dừng.
#include "core/check.hpp"

#include <atomic>
#include <csignal>

namespace game::app {

// Biến toàn cục khả biến (lệch KTR-04): handler tín hiệu chỉ chạm được nó (UB-21).
// NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables)
inline std::atomic<bool> stop_requested{false};
static_assert(std::atomic<bool>::is_always_lock_free, "handler cần atomic không khoá");

extern "C" inline void on_sigterm(int /*signal*/) noexcept {
    stop_requested.store(true, std::memory_order_relaxed);
}

inline void install_signal_handlers() noexcept {
    static_cast<void>(std::signal(SIGTERM, &on_sigterm));
}

} // namespace game::app

int main() {
    game::app::install_signal_handlers();
    static_cast<void>(std::raise(SIGTERM));
    game::core::check(game::app::stop_requested.load(), "handler phải đã chạy");
    return 0;
}
```

## Kiểm nhanh

- [ ] Mọi phép cộng/nhân trên máu, vàng, số lượng tính ở kiểu rộng hoặc qua `checked_*`? (UB-01, UB-10)
- [ ] Số bit dịch, phép nhân `uint16_t` đã tính tới thăng hạng `int`? (UB-02)
- [ ] Không `reinterpret_cast` nào đọc buffer; mọi lần đọc dây qua `Reader` kiểm `count > size - pos`? (UB-03, UB-04)
- [ ] Mọi ép `float` → nguyên có kiểm hữu hạn và miền, điều kiện viết theo chiều "phải đúng"? (UB-05)
- [ ] Gói tin ghi từng trường, không `memcpy` struct có đệm? (UB-06)
- [ ] Test chạy ASan + UBSan `-fno-sanitize-recover=all` (GCC thêm `float-cast-overflow`), TSan riêng? (UB-07)
- [ ] Hardening thư viện bật ở mọi bản build? (UB-08, UB-18)
- [ ] Enum, `bool` từ dây đi qua hàm kiểm miền? (UB-09)
- [ ] Không `-fwrapv`/`-fno-strict-aliasing` để "chữa"? (UB-12)
- [ ] Mỗi phiên có trần hàng đợi, token bucket, ngân sách; mọi chờ có deadline, tick có watchdog? (UB-13, UB-14, UB-15)
- [ ] Mọi kiểm biên và kiểm null đứng TRƯỚC phép tính có thể UB? (UB-19, UB-20)
- [ ] Handler tín hiệu chỉ ghi atomic không khoá? (UB-21)
