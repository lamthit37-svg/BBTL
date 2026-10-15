# LH · Lỗi và hợp đồng

> **Phạm vi:** phân loại lỗi; kiểm hợp đồng bằng `core/check.hpp`; `std::expected` và mã lỗi;
> ngoại lệ, `noexcept`, terminate handler; đảm bảo mạnh (commit-or-rollback); đường lỗi lạnh, ABI
> của `expected`, contracts C++26. **Đọc khi:** viết hàm có thể thất bại; viết code chạm dữ liệu
> client (parser gói tin, lệnh chat); phân vân giữa `check`, `expected`, ngoại lệ; viết destructor,
> move, swap; thao tác nhiều bước phải nguyên tử (mua bán, đổi đồ); cài terminate handler.
> **Liên quan:** refs/13-ub-on-dinh.md (UB-04, UB-09, UB-16), refs/15-kiem-thu.md (KT-11, KT-14,
> KT-20), refs/02-code-phang.md (PH-07, PH-10), refs/03-kieu-gia-tri.md (KG-13), refs/09-hieu-nang.md
> (HN-13), refs/18-game-mmo.md (MMO-*).

## 1. Nền tảng [N]

### LH-01 [N] PHẢI — Xếp mỗi lỗi vào đúng một trong ba loại rồi mới chọn cơ chế xử lý

| Loại | Ví dụ | Cơ chế | Sau lỗi |
|---|---|---|---|
| Lỗi lập trình: vi phạm tiền/hậu điều kiện, bất biến mà code mình bảo đảm | chỉ số do mình tính vượt biên, handle đã giải phóng, số lượng âm trong kho | `core::check`, `core::fail` (LH-02) | dừng tiến trình, crash dump, sửa code |
| Lỗi môi trường dự kiến được | DB quá hạn, file cấu hình thiếu, socket đóng, zone đầy | `std::expected<T, E>` | nơi gọi chọn: thử lại, báo, lùi |
| Đầu vào không tin cậy (client, file người chơi tải lên) | gói sai độ dài, opcode lạ, số lượng âm, toạ độ NaN | `std::expected<T, E>` + bộ đếm (LH-03) | máy chủ sống; phiên bị bỏ gói, ngắt, cấm |

- **Vì sao:** `check` trên dữ liệu client: một gói tin làm rớt cả shard, lặp lại được mãi.
  `expected` cho lỗi lập trình: tiến trình chạy tiếp trên trạng thái hỏng — nhân bản vật phẩm, bản
  ghi bẩn trong DB. Ngoại lệ cho cả ba: đường lỗi không hiện trên chữ ký.
- **Kiểm:** review: mỗi `check` kiểm điều chính module bảo đảm; fuzz mọi hàm giải mã (KT-11).

```cpp
// ✓ Một hàm, hai loại lỗi: slot do client gửi → expected; bất biến của kho → check.
#include "core/check.hpp"

#include <cstdint>
#include <expected>
#include <span>

namespace game::inv {

enum class [[nodiscard]] UseError : std::uint8_t { kNoSuchSlot, kSlotEmpty };
using UseResult = std::expected<void, UseError>;

// slot đến từ gói tin: mọi giá trị 32 bit đều có thể xảy ra, kể cả cố ý.
[[nodiscard]] inline UseResult use_one(std::span<std::int32_t> counts, std::uint32_t slot) noexcept {
    if (slot >= counts.size()) return std::unexpected(UseError::kNoSuchSlot);
    std::int32_t& count = counts[slot];
    if (count == 0) return std::unexpected(UseError::kSlotEmpty);
    // Số âm chỉ có thể do code máy chủ ghi sai: lỗi lập trình, không phải lỗi của client.
    core::check(count > 0, "use_one: số lượng âm, kho hỏng");
    --count;
    return {};
}

} // namespace game::inv
```

### LH-02 [N] PHẢI — Kiểm hợp đồng bằng `core/check.hpp`; CẤM `assert` và macro kiểm tự chế

Mọi tiền điều kiện, hậu điều kiện, bất biến dùng bốn hàm của header chuẩn (nguyên văn
`tools/include/core/check.hpp` dưới đây). Tiền điều kiện ở đầu hàm, hậu điều kiện ngay trước
`return`; mỗi `check` một điều kiện logic; thông điệp dạng `tên_hàm: điều gì sai`.

- **Vì sao:** `assert` biến mất khi có `NDEBUG`, mà CMake định nghĩa `NDEBUG` cho Release và
  RelWithDebInfo: bản chạy thật không kiểm gì. `check` luôn bật, đường đúng chỉ tốn một phép so và
  một nhánh đoán đúng; phần in và abort nằm trong hàm `[[noreturn]]` riêng (LH-14).
  `source_location` làm tham số mặc định cho file:dòng của NƠI GỌI, không cần macro. `constexpr`:
  vi phạm lúc tính hằng thành lỗi biên dịch (LH-16). Đầu hàm cũng là chỗ của `pre(…)` C++26 (LH-17).
- **Kiểm:** `grep -rnE '<cassert>|[^_]assert\(' src/` rỗng; review thông điệp.

```cpp
// ✓ tools/include/core/check.hpp, nguyên văn: header hợp đồng mọi mẫu khác include.
// Kiểm hợp đồng cho mọi module: check luôn bật, kể cả bản phát hành; debug_check chỉ chạy khi
// định nghĩa GAME_DEBUG_CHECKS; fail dừng vô điều kiện; assume hứa với trình dịch một điều đã
// chứng minh. Điều kiện sai thì in file:dòng rồi std::abort() — fail-fast: trạng thái hỏng không
// được đi tiếp thành UB, gói tin rác hay bản ghi bẩn trong cơ sở dữ liệu.
// - constexpr: vi phạm khi tính hằng biểu thức thành lỗi biên dịch (check_failed không constexpr);
// - noexcept, không cấp phát: gọi được trong hàm noexcept và trên đường nóng;
// - nhánh lỗi nằm trong hàm [[noreturn]] riêng, nơi gọi chỉ còn một phép so và một bước nhảy.
#pragma once

#include <cstdio>
#include <cstdlib>
#include <source_location>
#include <string_view>

namespace game::core {

#if defined(GAME_DEBUG_CHECKS)
inline constexpr bool kDebugChecks = true;
#else
inline constexpr bool kDebugChecks = false;
#endif

// Tên ngắn cho hai kiểu mọi hàm hợp đồng đều nhận. Site::current() lấy đúng nơi gọi.
using Message = std::string_view;
using Site = std::source_location;

namespace detail {

// fprintf thay std::print (lệch STD-04): header này có ở mọi TU, không kéo <format> theo.
[[noreturn]] inline void check_failed(Message message, Site where) noexcept {
    // NOLINTNEXTLINE(google-runtime-int): %lu của fprintf đòi đúng unsigned long (KG-03).
    const auto line = static_cast<unsigned long>(where.line());
    // Chuỗi định dạng giữ ASCII: clang-tidy ≤20 sập khi gặp UTF-8 trong định dạng printf (BD-19).
    // NOLINTNEXTLINE(modernize-use-std-print,cppcoreguidelines-pro-type-vararg)
    static_cast<void>(std::fprintf(stderr, "%s:%lu: ", where.file_name(), line));
    static_cast<void>(std::fputs("check thất bại: ", stderr));
    static_cast<void>(std::fwrite(message.data(), 1, message.size(), stderr));
    static_cast<void>(std::fputc('\n', stderr));
    std::abort();
}

} // namespace detail

// Tiền điều kiện, hậu điều kiện, bất biến rẻ (O(1)): luôn kiểm.
constexpr void check(bool condition, Message message, Site where = Site::current()) noexcept {
    if (condition) return;
    detail::check_failed(message, where);
}

// Điều kiện đắt (duyệt mảng, kiểm cấu trúc): predicate chỉ được gọi khi kDebugChecks, nhưng vẫn
// được biên dịch ở mọi cấu hình nên không mục theo thời gian.
template <class IsOk>
constexpr void debug_check(const IsOk& is_ok, Message text, Site where = Site::current()) noexcept {
    if constexpr (kDebugChecks) check(is_ok(), text, where);
}

// Nhánh không được phép tới (enum ngoài miền, trạng thái không tồn tại): dừng ở mọi cấu hình.
[[noreturn]] inline void fail(Message message, Site where = Site::current()) noexcept {
    detail::check_failed(message, where);
}

// Hứa với trình dịch rằng condition đúng để nó tối ưu theo; sai là UB ở bản phát hành. Chỉ dùng
// trên đường nóng đã đo, khi condition đã được chứng minh ở nơi khác (refs/11, SV-*).
constexpr void assume(bool condition) noexcept {
    if constexpr (kDebugChecks) check(condition, "assume sai");
    [[assume(condition)]];
}

} // namespace game::core
```

#### Chọn hàm kiểm

| Hàm | Dùng cho | Chi phí bản phát hành | Khi sai |
|---|---|---|---|
| `check(cond, msg)` | tiền/hậu điều kiện, bất biến O(1) | một phép so + nhánh | in file:dòng, `std::abort()` |
| `debug_check(pred, msg)` | điều kiện O(n): `[cells] { return std::ranges::is_sorted(cells); }`, tổng kho bảo toàn | 0; `pred` vẫn được biên dịch | như `check`, chỉ khi có `GAME_DEBUG_CHECKS` |
| `fail(msg)` | nhánh không được tới: sau `switch` enum (PH-07), trạng thái không tồn tại | 0 trên đường đúng | như `check` |
| `assume(cond)` | đường nóng đã đo, `cond` đã chứng minh ở nơi khác (SV-*) | 0, có thể nhanh hơn | debug: abort; phát hành: UB |

### LH-03 [N] CẤM — Để dữ liệu client làm dừng máy chủ: lỗi đầu vào là giá trị trả về, có đếm, xử lý theo phiên

Code giải mã gói tin, lệnh chat, tên nhân vật không gọi `check`, `fail`, `.value()`, `.at()` trên
điều kiện client điều khiển (`check(packet.size() >= 2, …)` là một gói 1 byte giết cả máy chủ). Trả
`std::unexpected(mã)`; tầng phiên đếm và áp chính sách theo ngưỡng của cả phiên (bỏ gói → ngắt →
cấm). Bộ đếm toàn cục theo mã lỗi lên dashboard.

- **Vì sao:** abort giết mọi phiên trên tiến trình; `.value()`/`.at()` ném, trong hàm `noexcept`
  thành `std::terminate` — vẫn là dừng. Đếm theo mã phân biệt client sai phiên bản (mọi phiên, một
  mã) với kẻ dò (một phiên, đủ loại mã).
- **Kiểm:** fuzz (KT-11): mọi đầu vào phải trả về, ASan/UBSan sạch; review mọi hàm nhận
  `std::span<const std::byte>` từ socket.

```cpp
// ✓ Lỗi đầu vào là giá trị; phiên đếm lỗi, vượt ngưỡng thì ngắt riêng phiên đó.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::proto {

enum class [[nodiscard]] DecodeError : std::uint8_t { kTooShort, kBadOpcode };

[[nodiscard]] inline std::expected<std::uint16_t, DecodeError> read_opcode(std::span<const std::byte> packet) noexcept {
    if (packet.size() < 2) return std::unexpected(DecodeError::kTooShort);
    const auto low = std::to_integer<std::uint32_t>(packet[0]);
    const auto high = std::to_integer<std::uint32_t>(packet[1]);
    return static_cast<std::uint16_t>(low | (high << 8U));
}

// Ngưỡng trên cả phiên, không trên từng gói: client tốt thỉnh thoảng cũng gửi gói hỏng.
[[nodiscard]] inline bool should_disconnect(std::uint32_t& session_errors) noexcept {
    constexpr std::uint32_t kLimit = 16;
    ++session_errors;
    return session_errors >= kLimit;
}

} // namespace game::proto
```

### LH-04 [N] PHẢI — Mã lỗi là `enum class [[nodiscard]]` kiểu nền `std::uint8_t`, kèm `to_string` trả tên ASCII cố định

- **Vì sao:** một byte giữ `expected<T, E>` nhỏ, trả qua thanh ghi (LH-15). `[[nodiscard]]` mức
  kiểu: GCC 14/15, Clang 20 cảnh báo mọi lời gọi bỏ giá trị kiểu đó (KG-13). `switch` không
  `default` để `-Wswitch` báo khi thêm mã mới; `default` nuốt mã mới im lặng. Sau `switch` là
  `core::fail` (PH-07). Tên snake_case ASCII là khoá log và số liệu, không dịch; `string_view` tới
  literal nên không cấp phát. Enum đọc từ dây phải kiểm miền trước (UB-09), nếu không `fail` ở đây
  thành đường cho client làm sập máy chủ.
- **Kiểm:** `-Wswitch` với `-Werror`; review: không `default:` khi `switch` trên enum.

```cpp
// ✓ switch đủ mọi mã, không default; ngoài miền là lỗi lập trình.
#include "core/check.hpp"

#include <cstdint>
#include <string_view>

namespace game::proto {

enum class [[nodiscard]] DecodeError : std::uint8_t { kTooShort, kBadOpcode, kBadLength };

[[nodiscard]] constexpr std::string_view to_string(DecodeError error) noexcept {
    switch (error) {
    case DecodeError::kTooShort: return "too_short";
    case DecodeError::kBadOpcode: return "bad_opcode";
    case DecodeError::kBadLength: return "bad_length";
    }
    core::fail("to_string: DecodeError ngoài miền");
}

static_assert(to_string(DecodeError::kBadLength) == "bad_length");

} // namespace game::proto
```

### LH-05 [N] CẤM — Bỏ qua giá trị có thể mang lỗi; mọi hàm trả `std::expected` là `[[nodiscard]]`

Hàm trả `std::expected`, `std::optional` báo thất bại, mã lỗi, `std::errc`, `bool` thành công đều
có `[[nodiscard]]`. Bỏ có chủ ý kết quả hàm C mà nơi gọi không xử lý được (`fprintf` khi đang dừng
tiến trình, như check.hpp): `static_cast<void>(…)` kèm lý do. `std::expected`, `std::error_code`,
`std::errc` thì không bỏ được kể cả qua `static_cast<void>` — clang-tidy
`bugprone-unused-return-value` (`AllowCastToVoid` mặc định tắt) chặn: xử lý, chuyển lên, hoặc trong
test thì `expect` kết quả. Không `*r` hay `.value()` khi chưa kiểm `r`.

- **Vì sao:** chuẩn không đánh dấu `std::expected` là nodiscard. Đã đo trên GCC 14.2, GCC 15.2,
  Clang 20 + libc++ 20: bỏ kết quả của hàm trả `std::expected<int, E>` không có cảnh báo nào, kể cả
  khi `E` là enum `[[nodiscard]]`. Đó là lỗi "lưu nhân vật thất bại mà không ai biết". `*r` khi `r`
  mang lỗi là UB (hardening bắt, UB-08); `.value()` ném `bad_expected_access`.
- **Kiểm:** `-Wunused-result` với `-Werror`; clang-tidy `modernize-use-nodiscard`,
  `bugprone-unused-return-value`, `cert-err33-c` (hàm C như `fprintf`).

```cpp
// ✓ nodiscard ở khai báo; nơi gọi xử lý lỗi tường minh bằng câu bảo vệ.
#include <cstdint>
#include <expected>

namespace game::db {

enum class [[nodiscard]] SaveError : std::uint8_t { kTimeout, kConflict };

[[nodiscard]] std::expected<void, SaveError> save_character(std::uint64_t character_id) noexcept;
void retry_later(std::uint64_t character_id, SaveError error) noexcept;

inline void on_logout(std::uint64_t character_id) noexcept {
    const auto saved = save_character(character_id);
    if (saved) return;
    retry_later(character_id, saved.error());
}

} // namespace game::db
```

### LH-06 [N] PHẢI — Destructor, move và `swap` là `noexcept`; chốt bằng `static_assert` cạnh kiểu

- **Vì sao:** khi tăng dung lượng, `std::vector` chuyển phần tử bằng `std::move_if_noexcept`: move
  thiếu `noexcept` (mà copy được) thì vector CHÉP từng phần tử — cấp phát lại mọi chuỗi, mọi buffer
  con — để giữ đảm bảo mạnh. Destructor ném trong lúc unwind gọi `std::terminate`. `swap` không thể
  lỗi là nền của commit-or-rollback (LH-12). Rule of zero cho các hàm này `noexcept` tự động;
  `static_assert` giữ điều đó khi ai đó thêm thành viên hay viết tay move constructor. Template bọc
  `T` khai `noexcept` có điều kiện theo đúng thao tác nó gọi, vd.
  `noexcept(std::is_nothrow_move_constructible_v<T>)`: `noexcept` cứng với `T` có thể ném biến ngoại
  lệ thành `std::terminate`; thiếu thì vector chép thay vì move.
- **Kiểm:** clang-tidy `performance-noexcept-move-constructor`, `performance-noexcept-destructor`,
  `performance-noexcept-swap`, `bugprone-exception-escape`.

```cpp
// ✓ Rule of zero: move, swap, destructor ngầm định đều noexcept; static_assert canh giữ.
#include <cstddef>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>
#include <vector>

namespace game::net {

class Session {
public:
    explicit Session(std::string name) noexcept : name_(std::move(name)) {}

    [[nodiscard]] std::string_view name() const noexcept { return name_; }

private:
    std::string name_;
    std::vector<std::byte> pending_;
};

static_assert(std::is_nothrow_move_constructible_v<Session>);
static_assert(std::is_nothrow_move_assignable_v<Session>);
static_assert(std::is_nothrow_swappable_v<Session>);

} // namespace game::net
```

### LH-07 [N] CẤM — `throw` trong code game và mạng; ngoại lệ thư viện chỉ có một đích: dừng tiến trình

Dự án biên dịch có ngoại lệ (thư viện chuẩn cần), nhưng code dự án không ném và không bắt để chạy
tiếp. Hàm không cấp phát là `noexcept`. Hàm có cấp phát thì KHÔNG khai `noexcept` (nó thật sự có
thể ném `bad_alloc`, `length_error`; `bugprone-exception-escape` báo khai sai trên build libc++ —
libstdc++ ném từ hàm ngoài header nên check không thấy); ngoại lệ đi lên tới hàm vào luồng
`noexcept` (LH-08) hay `try` duy nhất ở `main` gọi `core::fail` — tức dừng, qua terminate handler
(LH-13) ra core dump. Với đầu vào ngoài, không gọi API ném: `std::stoi` → `std::from_chars`;
`std::vformat` với chuỗi định dạng lúc chạy → chuỗi định dạng hằng (kiểm lúc biên dịch);
`.at()`/`.value()` → kiểm rồi truy cập. Trường hợp có chủ ý duy nhất: `.at()` trên chỉ số mà chỉ
code sai mới vượt (enum đã kiểm miền ở biên, bảng `constexpr` đủ cỡ), đặt trong hàm `noexcept`, là
dừng sớm tương đương `check` — ném thành `std::terminate`, qua LH-13; ghi
`// NOLINTNEXTLINE(bugprone-exception-escape): <lý do>` như PH-06, PH-12.

- **Vì sao:** `std::stoi` với chuỗi client gõ ném `invalid_argument`; trong hàm `noexcept` đó là
  một lệnh chat làm sập máy chủ. Mỗi lần ném tốn cỡ micro giây (LH-18), kẻ tấn công chọn được tần
  suất. `bad_alloc` trên Linux hiếm khi tới (overcommit: OOM killer giết tiến trình trước); khi tới
  thì gần như không còn đường phục hồi sạch, nên dừng và khởi động lại (LH-19) rẻ và đúng hơn bắt.
- **Kiểm:** `grep -rn 'throw ' src/` rỗng; clang-tidy `bugprone-exception-escape`, `cert-err58-cpp`.
- **Ngoại lệ:** công cụ offline (đóng gói tài nguyên, chuyển đổi dữ liệu) được ném, bắt ở `main`.

```cpp
// ✓ from_chars: không ngoại lệ, không locale, không cấp phát; mọi lỗi là giá trị.
#include <charconv>
#include <cstdint>
#include <expected>
#include <memory>
#include <string_view>
#include <system_error>

namespace game::chat {

enum class [[nodiscard]] AmountError : std::uint8_t { kNotNumber, kOutOfRange, kTrailing };

[[nodiscard]] inline std::expected<std::int32_t, AmountError> parse_amount(std::string_view text) noexcept {
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    std::int32_t value = 0;
    const auto [stop, error] = std::from_chars(first, last, value);
    if (error == std::errc::invalid_argument) return std::unexpected(AmountError::kNotNumber);
    if (error == std::errc::result_out_of_range) return std::unexpected(AmountError::kOutOfRange);
    if (stop != last) return std::unexpected(AmountError::kTrailing);
    return value;
}

} // namespace game::chat
```

### LH-08 [N] PHẢI — Hàm vào luồng và callback trao cho thư viện C là `noexcept`; lỗi qua ranh giới đi dưới dạng giá trị

- **Vì sao:** ngoại lệ thoát khỏi hàm vào của `std::thread`/`std::jthread` gọi `std::terminate`
  ([thread.thread.constr]). Ngoại lệ xuyên qua khung của thư viện C không được định nghĩa: mã C
  thường không có bảng unwind (không biên dịch `-fexceptions`). Luồng khởi tạo không bắt được ngoại
  lệ của luồng con; lỗi đi về bằng `expected` qua hàng đợi (DT-01).
- **Kiểm:** clang-tidy `bugprone-exception-escape`; review: hàm truyền cho `std::jthread` và mọi
  hàm `extern "C"` là `noexcept`.
- **Ngoại lệ:** hàm vào luồng có cấp phát (vector, string) vẫn khai `noexcept`: `bad_alloc` thoát ra
  thành `std::terminate`, đúng đích "dừng tiến trình" của LH-07; ghi
  `// NOLINTNEXTLINE(bugprone-exception-escape)` kèm lý do (LH-07) như mọi chỗ lệch có chủ đích.

```cpp
// ✓ Luồng lưu DB: hàm vào noexcept; kết quả, kể cả lỗi, về luồng game qua hàng đợi.
#include <cstdint>
#include <expected>
#include <stop_token>

namespace game::db {

enum class [[nodiscard]] SaveError : std::uint8_t { kTimeout, kConflict };

// Cung cấp bởi module DB, đều noexcept: không gì ném qua ranh giới luồng.
[[nodiscard]] std::uint64_t next_request(const std::stop_token& stop) noexcept;
[[nodiscard]] std::expected<void, SaveError> execute(std::uint64_t request_id) noexcept;
void post_to_game(std::uint64_t request_id, std::expected<void, SaveError> outcome) noexcept;

// Chạy bằng std::jthread saver{run_saver}; jthread truyền stop_token của nó vào.
inline void run_saver(const std::stop_token& stop) noexcept {
    while (!stop.stop_requested()) {
        const std::uint64_t request_id = next_request(stop);
        post_to_game(request_id, execute(request_id));
    }
}

} // namespace game::db
```

## 2. Nâng cao [C]

### LH-09 [C] NÊN — Chuỗi bước có thể lỗi viết bằng `and_then`/`transform`/`transform_error` khi mỗi bước là hàm có tên

- **Vì sao:** một dòng đọc như đặc tả pipeline, lỗi tự lan mà không lồng (PH-10), mỗi bước test riêng
  được. `and_then` đòi bước sau trả `expected` cùng kiểu lỗi nên đổi tầng lỗi (giải mã → nghiệp vụ)
  bằng `transform_error` đúng một chỗ; `transform` cho bước không thể lỗi. Lambda trong chuỗi chỉ
  một biểu thức; cần biến trung gian thì dùng câu bảo vệ
  `if (!r) return std::unexpected(r.error());`. Cả ba trình dịch có (`__cpp_lib_expected` 202211L).
- **Kiểm:** review; PH-10.

```cpp
// ✓ Giải mã → đổi tầng lỗi → kiểm tốc độ: mỗi bước một hàm có tên, lỗi tự lan.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::sim {

enum class [[nodiscard]] DecodeError : std::uint8_t { kTooShort, kBadField };
enum class [[nodiscard]] MoveError : std::uint8_t { kMalformed, kTooFast };

struct Step {
    float dx = 0.0F;
    float dy = 0.0F;
};

[[nodiscard]] std::expected<Step, DecodeError> decode_step(std::span<const std::byte> body) noexcept;
[[nodiscard]] MoveError to_move_error(DecodeError error) noexcept;
[[nodiscard]] std::expected<Step, MoveError> check_speed(Step step) noexcept;

[[nodiscard]] inline std::expected<Step, MoveError> parse_step(std::span<const std::byte> body) noexcept {
    return decode_step(body).transform_error(to_move_error).and_then(check_speed);
}

} // namespace game::sim
```

### LH-10 [C] PHẢI — Lỗi có hai mặt: ngữ cảnh có cấu trúc cho log máy chủ, mã công khai thô cho client

Lỗi đi qua ranh giới module mang mã, id liên quan và `std::source_location` nơi phát sinh; không
dựng sẵn chuỗi. Client chỉ nhận enum công khai, ít giá trị, có phiên bản cùng giao thức (MMO-*).
Lỗi giải mã trên đường nóng giữ một byte (LH-15); ngữ cảnh dành cho đường lạnh (DB, đăng nhập).

- **Vì sao:** "timeout" trần không chẩn đoán được; chuỗi dựng sẵn cấp phát trên đường lỗi và không
  lọc theo `account_id` được. `source_location::current()` ở default member initializer cho vị trí
  của biểu thức khởi tạo aggregate (đã đo: GCC 14/15, Clang 20). Chi tiết nội bộ gửi cho client
  (câu SQL, check nào hỏng) là bản đồ cho kẻ tấn công; tách "không có tài khoản" với "sai mật khẩu"
  cho phép dò tài khoản tồn tại.
- **Kiểm:** review: kiểu gửi qua mạng chỉ chứa enum công khai; không `std::string` trong kiểu lỗi.

```cpp
// ✓ Một lỗi, hai mặt: đủ ngữ cảnh cho log; client chỉ nhận mã công khai thô.
#include "core/check.hpp"

#include <cstdint>
#include <source_location>

namespace game::net {

enum class [[nodiscard]] LoginError : std::uint8_t { kNoSuchAccount, kWrongPassword, kDbTimeout };
enum class [[nodiscard]] PublicLoginError : std::uint8_t { kInvalidCredentials, kRetryLater };

// Cho log có cấu trúc: LoginFailure{.code = …, .account_id = …} tự ghi vị trí tạo.
struct LoginFailure {
    LoginError code = LoginError::kDbTimeout;
    std::uint64_t account_id = 0;
    std::source_location where = std::source_location::current();
};

// Hai mã đầu gộp một: client không phân biệt được tài khoản có tồn tại hay không.
[[nodiscard]] constexpr PublicLoginError to_public(LoginError error) noexcept {
    switch (error) {
    case LoginError::kNoSuchAccount:
    case LoginError::kWrongPassword: return PublicLoginError::kInvalidCredentials;
    case LoginError::kDbTimeout: return PublicLoginError::kRetryLater;
    }
    core::fail("to_public: LoginError ngoài miền");
}

} // namespace game::net
```

### LH-11 [C] PHẢI — Lỗi hệ điều hành giữ dạng `std::error_code` tới nơi quyết định; so sánh với `std::errc`, không với số errno

- **Vì sao:** `std::error_code` mang cả giá trị lẫn category: cùng số 5 là `EIO` (lỗi vào/ra) theo
  errno của Linux nhưng là `ERROR_ACCESS_DENIED` theo mã lỗi Windows. `ec == std::errc::no_such_file_or_directory` so qua `error_condition`, đúng
  trên mọi nền tảng; `ec.value() == ENOENT` chỉ đúng trên POSIX. Nạp chồng nhận `std::error_code&`
  của `<filesystem>` báo lỗi OS qua `ec` thay vì ném; phần lớn là `noexcept` (`file_size`,
  `exists`…), nhưng hàm trả `path` hay duyệt cây (`absolute`, `canonical`, `create_directories`,
  `remove_all`…) vẫn có thể ném `bad_alloc` nên không `noexcept` — khớp LH-07.
- **Kiểm:** review: không so `ec.value()` với hằng; không gọi nạp chồng `<filesystem>` có ném.

```cpp
// ✓ Nạp file bản đồ: nạp chồng không ném của <filesystem>; lỗi giữ nguyên error_code.
#include <cstdint>
#include <expected>
#include <filesystem>
#include <system_error>

namespace game::world {

using SizeResult = std::expected<std::uintmax_t, std::error_code>;

[[nodiscard]] inline SizeResult map_file_size(const std::filesystem::path& file) noexcept {
    std::error_code ec;
    const std::uintmax_t size = std::filesystem::file_size(file, ec);
    if (ec) return std::unexpected(ec);
    return size;
}

// Thiếu file là lỗi cấu hình báo được rõ; lỗi khác giữ nguyên để ghi log.
[[nodiscard]] inline bool is_missing(const std::error_code& ec) noexcept {
    return ec == std::errc::no_such_file_or_directory;
}

} // namespace game::world
```

### LH-12 [C] PHẢI — Thao tác nhiều bước có đảm bảo mạnh: làm hết mọi việc có thể lỗi trước, rồi sửa trạng thái bằng các bước không thể lỗi

Ba mức: không lỗi (nothrow), mạnh (thất bại thì không gì đổi), cơ bản (thất bại thì bất biến còn,
giá trị có thể đổi). Giao dịch game (mua, bán, đổi đồ, chuyển vàng) PHẢI đạt mức mạnh. Pha 1: mọi
thứ có thể lỗi — kiểm, tìm chỗ trống, `reserve` — chưa sửa gì. Pha 2: gán, cộng trừ đã chứng minh
không tràn, `push_back` sau `reserve`, `swap` — không bước nào lỗi được.

- **Vì sao:** trừ vàng người mua rồi mới phát hiện ví người bán đầy là vàng bốc hơi; thêm vật phẩm
  rồi mới thất bại là nhân bản vật phẩm — loại lỗi kinh tế MMO đắt nhất. Hai pha làm đảm bảo mạnh
  hiển nhiên khi đọc, không cần rollback viết tay.
- **Kiểm:** review: sau dòng sửa trạng thái đầu tiên không còn `return std::unexpected`; test thuộc
  tính "thất bại thì trạng thái y nguyên" (KT-09).

```cpp
// ✓ Pha 1 kiểm mọi điều kiện, tìm ô trống; pha 2 chỉ gồm bước không thể lỗi.
#include <algorithm>
#include <array>
#include <cstdint>
#include <expected>
#include <span>

namespace game::inv {

enum class [[nodiscard]] TradeError : std::uint8_t {
    kBadPrice,
    kNotEnoughGold,
    kWalletFull,
    kBagFull,
};

inline constexpr std::int64_t kGoldCap = 1'000'000'000'000;

struct Owner {
    // Bất biến: 0 <= gold <= kGoldCap.
    std::int64_t gold = 0;
    // Id vật phẩm theo ô; 0 là ô trống.
    std::array<std::uint32_t, 40> slots{};
};

struct Offer {
    std::uint32_t item_id = 0;
    std::int64_t price = 0;
};

// Đọc như câu: buyer mua offer từ seller.
[[nodiscard]] inline std::expected<void, TradeError> buy(Owner& buyer, Offer offer, Owner& seller) noexcept {
    if (offer.price <= 0 || offer.price > kGoldCap) return std::unexpected(TradeError::kBadPrice);
    if (buyer.gold < offer.price) return std::unexpected(TradeError::kNotEnoughGold);
    if (seller.gold > kGoldCap - offer.price) return std::unexpected(TradeError::kWalletFull);
    const std::span<std::uint32_t> slots{buyer.slots};
    const auto free_slot = std::ranges::find(slots, 0U);
    if (free_slot == slots.end()) return std::unexpected(TradeError::kBagFull);
    // Pha 2: từ đây không còn đường lỗi.
    buyer.gold -= offer.price;
    seller.gold += offer.price;
    *free_slot = offer.item_id;
    return {};
}

} // namespace game::inv
```

### LH-13 [C] PHẢI — Cài terminate handler in stacktrace rồi `std::abort()`; bật core dump

Cài một lần đầu `main`, trước khi tạo luồng. Handler chặn vào lại, in stacktrace ra stderr, gọi
`std::abort()` để có core dump. `std::stacktrace` chỉ có ở libstdc++ và phải liên kết `-lstdc++exp`
(đã đo trên GCC 14.2 và 15.2: thiếu thì lỗi liên kết); libc++ 20 chưa có `<stacktrace>`.

- **Vì sao:** terminate mặc định của libstdc++ in kiểu ngoại lệ rồi abort, không có ngăn xếp; core
  dump cần file và symbol mới đọc được. Stacktrace trong log dịch vụ là thứ có đầu tiên khi máy chủ
  sập lúc 3 giờ sáng. Chặn vào lại vì handler `noexcept` mà cấp phát thất bại sẽ gọi lại
  `std::terminate`.
- **Kiểm:** test tích hợp: tiến trình con gọi `std::terminate()`, stderr phải có khung `main`.

```cpp
// ✓ [g14+g15] [linux] Terminate handler: vào một lần, in stacktrace, abort để có core dump.
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <exception>
#include <stacktrace>
#include <string>

namespace game::app {

[[noreturn]] inline void on_terminate() noexcept {
    // Handler không nhận được ngữ cảnh nên cờ phải là static: lệch KTR-04 có chủ đích.
    static std::atomic_flag entered;
    if (entered.test_and_set()) std::abort();
    // Cấp phát có thể thất bại khi chết vì hết bộ nhớ; lần vào lại đi thẳng tới abort.
    const std::string trace = std::to_string(std::stacktrace::current());
    static_cast<void>(std::fputs(trace.c_str(), stderr));
    std::abort();
}

inline void install_terminate_handler() noexcept {
    std::set_terminate(&on_terminate);
}

} // namespace game::app
```

## 3. Thần thoại [T]

### LH-14 [T] NÊN — Dựng lỗi trong hàm lạnh riêng `[[gnu::cold]] [[gnu::noinline]]` khi đường lỗi làm phình hàm nóng

Chỉ khi profiler chỉ ra hàm nóng (giải mã gói, bước tick) không được nội tuyến hoặc tốn dòng i-cache
vì phần dựng lỗi (đếm, ngữ cảnh, log). Hàm `[[noreturn]]` đã tự được coi là lạnh. Thuộc tính bố cục
nói chung: HN-13.

- **Vì sao:** GCC và Clang dự đoán nhánh dẫn tới lời gọi hàm `cold` hoặc `[[noreturn]]` là không
  xảy ra, xếp nó ra cuối, đặt thân hàm lạnh vào `.text.unlikely`. Đã đo (`-O2 -S`): GCC 14 còn tách
  khối gọi lỗi thành `read_opcode.cold` trong `.text.unlikely`; Clang 20 dồn chúng về cuối hàm. Đường
  đúng còn lại ngắn, nội tuyến được, dòng cache chứa toàn lệnh hữu ích; `noinline` giữ phần lạnh
  không bị kéo ngược vào. `check_failed` của check.hpp dùng đúng kỹ thuật này.
- **Kiểm:** asm trước/sau (HN-15); benchmark giải mã trên corpus thật (HN-07); số đo ghi trong comment.

```cpp
// ✓ Đường đúng chỉ còn so và nhảy; đếm lỗi và dựng unexpected nằm trong hàm lạnh.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::proto {

enum class [[nodiscard]] DecodeError : std::uint8_t { kTooShort, kBadOpcode };
using OpcodeResult = std::expected<std::uint8_t, DecodeError>;

// Bộ đếm lỗi giải mã của một phiên; reject là đường lạnh duy nhất ghi vào nó.
struct DecodeErrors {
    std::uint32_t count = 0;

    [[nodiscard]] [[gnu::cold]] [[gnu::noinline]] std::unexpected<DecodeError> reject(DecodeError error) noexcept {
        ++count;
        return std::unexpected(error);
    }
};

[[nodiscard]] inline OpcodeResult read_opcode(std::span<const std::byte> packet, DecodeErrors& errors) noexcept {
    if (packet.empty()) return errors.reject(DecodeError::kTooShort);
    const auto opcode = std::to_integer<std::uint8_t>(packet.front());
    if (opcode >= 64) return errors.reject(DecodeError::kBadOpcode);
    return opcode;
}

} // namespace game::proto
```

### LH-15 [T] NÊN — `std::expected` trên đường nóng ≤ 16 byte, copy/move constructor và destructor tầm thường, để trả qua thanh ghi

- **Vì sao:** ABI x86-64 System V trả kiểu ≤ 16 byte qua RAX:RDX khi copy/move constructor và
  destructor tầm thường (Itanium C++ ABI: "non-trivial for the purposes of calls"); ngược lại nơi gọi
  cấp chỗ trên ngăn xếp và truyền con trỏ ẩn. Đã đo trên GCC 14/15, Clang 20: với `T`, `E` tầm
  thường, `expected` có copy/move constructor và destructor tầm thường nhưng KHÔNG sao chép tầm thường
  (gán không tầm thường) — vẫn đi thanh ghi. `expected<uint32_t, E8>` 8 B → RAX; `expected<uint64_t,
  E8>` 16 B → RAX:RDX; `expected<uint64_t, std::string>` 40 B (libstdc++) / 32 B (libc++) → qua bộ
  nhớ, thêm lời gọi destructor. Windows x64 chặt hơn: chỉ kiểu 1, 2, 4, 8 byte không có constructor,
  destructor hay phép gán do người dùng viết mới trả qua RAX, nên `expected` luôn trả qua bộ nhớ
  (theo tài liệu ABI x64 của Microsoft; chưa kiểm trên MSVC).
- **Kiểm:** `static_assert` cạnh kiểu kết quả như dưới; asm (`-O2 -S`) của hàm nóng.

```cpp
// ✓ Kết quả giải mã: static_assert giữ cỡ và tính tầm thường quyết định ABI trả về.
#include <cstdint>
#include <expected>
#include <type_traits>

namespace game::proto {

enum class [[nodiscard]] DecodeError : std::uint8_t { kTooShort, kBadOpcode };

struct Header {
    std::uint16_t opcode = 0;
    std::uint16_t length = 0;
    std::uint32_t sequence = 0;
};

using HeaderResult = std::expected<Header, DecodeError>;

static_assert(sizeof(HeaderResult) <= 16, "quá 16 B: trả qua bộ nhớ");
static_assert(std::is_trivially_copy_constructible_v<HeaderResult>);
static_assert(std::is_trivially_move_constructible_v<HeaderResult>);
static_assert(std::is_trivially_destructible_v<HeaderResult>);

} // namespace game::proto
```

### LH-16 [T] PHẢI — Bảng dữ liệu dựng lúc biên dịch kiểm bất biến bằng `core::check`: vi phạm thành lỗi biên dịch

- **Vì sao:** `check` là `constexpr`, nhánh lỗi gọi `check_failed` không `constexpr`; tính hằng mà
  điều kiện sai thì biểu thức không còn là hằng, trình dịch từ chối; chuỗi chẩn đoán dẫn tới đúng
  dòng `check`, thông điệp nằm trong đó (ký tự có dấu bị escape). Bảng skill, opcode, chuyển trạng thái sai thì không build được, thay vì sai
  lúc chạy. Cùng cơ chế với dò UB lúc biên dịch (UB-16) và test vi phạm hợp đồng (KT-20).
- **Kiểm:** kết quả hàm dựng bảng gán vào biến `constexpr` hoặc hàm là `consteval`; mẫu ✗ dưới đây
  bị cả ba trình dịch từ chối.

```cpp
// ✗ [không biên dịch] Hồi chiêu 0 vi phạm bất biến: trình dịch từ chối cả bảng.
#include "core/check.hpp"

#include <array>
#include <cstdint>

namespace game::combat {

struct Skill {
    std::uint16_t id = 0;
    std::uint32_t cooldown_ms = 0;
};

consteval std::array<Skill, 1> checked(std::array<Skill, 1> table) {
    game::core::check(table[0].cooldown_ms > 0, "checked: hồi chiêu phải > 0");
    return table;
}

constexpr auto kSkills = checked({{{.id = 1, .cooldown_ms = 0}}});

} // namespace game::combat
```

```cpp
// ✓ Bảng skill kiểm khi biên dịch: id tăng ngặt, hồi chiêu dương.
#include "core/check.hpp"

#include <array>
#include <cstddef>
#include <cstdint>

namespace game::combat {

struct Skill {
    std::uint16_t id = 0;
    std::uint32_t cooldown_ms = 0;
};

template <std::size_t N>
[[nodiscard]] consteval std::array<Skill, N> checked(std::array<Skill, N> table) {
    for (std::size_t i = 0; i < N; ++i) {
        core::check(table.at(i).cooldown_ms > 0, "checked: hồi chiêu phải > 0");
        core::check(i == 0 || table.at(i - 1).id < table.at(i).id, "checked: id phải tăng ngặt");
    }
    return table;
}

inline constexpr auto kSkills = checked(std::to_array<Skill>({
    {.id = 1, .cooldown_ms = 1500},
    {.id = 2, .cooldown_ms = 8000},
}));

} // namespace game::combat
```

### LH-17 [T] NÊN — Viết kiểm hợp đồng để chuyển sang contracts C++26 (P2900) được máy móc

C++26 có `pre(…)`, `post(r: …)`, `contract_assert(…)`, ngữ nghĩa kiểm chọn lúc build và handler vi
phạm thay được; C++23 không có, và GCC 14.2, 15.2, Clang 20 chưa hỗ trợ cú pháp này. C++23 viết
`core::check` theo ba luật: tiền điều kiện ở đầu hàm, hậu điều kiện trước `return` (LH-02); vị từ
không tác dụng phụ (không `++`, IO, cấp phát, gọi hàm sửa trạng thái); chỉ cho lỗi lập trình, không
cho đầu vào client (LH-03).

- **Vì sao:** P2900 cho phép vị từ hợp đồng được đánh giá không lần nào (ngữ nghĩa ignore) hoặc lặp
  lại; vị từ như `check(pop_one(queue), …)` thì hành vi đổi theo cờ build. Bản build bỏ qua hợp đồng
  không được mở lỗ an ninh, nên kiểm đầu vào client luôn là code thường trả `expected`.
- **Kiểm:** review: đối số của `check` chỉ đọc; `bugprone-assert-side-effect` chỉ biết macro
  `assert`, không thay được review.

```cpp
// ✓ Vị từ chỉ đọc, đứng đầu hàm: lên C++26 đổi thành pre(!events.empty()).
#include "core/check.hpp"

#include <cstdint>
#include <deque>

namespace game::sim {

[[nodiscard]] inline std::uint32_t consume(std::deque<std::uint32_t>& events) noexcept {
    core::check(!events.empty(), "consume: hàng đợi rỗng");
    const std::uint32_t front = events.front();
    events.pop_front();
    return front;
}

} // namespace game::sim
```

### LH-18 [T] KHÔNG NÊN — Dùng ngoại lệ ở nơi tần suất lỗi do bên ngoài quyết định; biết mô hình chi phí

"Không tốn phí" (zero-cost: bảng unwind, Itanium ABI): đường không ném không chạy thêm lệnh nào, nhưng lời gọi có
thể ném hạn chế một số tối ưu, và landing pad, `.eh_frame`, `.gcc_except_table` làm to binary. Một
lần ném: cấp phát đối tượng ngoại lệ (`__cxa_allocate_exception`), unwind hai pha (tìm handler rồi
dọn), mỗi khung tra FDE và diễn giải CFI — chi phí tăng theo độ sâu ngăn xếp. Đo trên máy kiểm (VM
Xeon 2.1 GHz, `-O2`): ném và bắt qua 1 khung ~2 µs (GCC 14 + libstdc++), ~4 µs (Clang 20 + libc++);
qua 50 khung ~22 µs và ~43 µs; trả `std::expected` qua 50 khung 70–100 ns.

- **Vì sao:** với lỗi do client quyết định, kẻ tấn công chọn tần suất: 100 000 gói hỏng mỗi giây ×
  vài µs là cả một lõi đốt trong unwinder. Unwinder trên toolchain cũ (trước glibc 2.35 và libgcc của
  GCC 12) tra bảng qua `dl_iterate_phdr` có khoá toàn cục, nên ném song song bị tuần tự hoá.
- **Kiểm:** `static_assert(noexcept(…))` trên hàm giải mã như dưới; `bugprone-exception-escape`.

```cpp
// ✓ Chính sách khoá vào kiểu: hàm giải mã phải noexcept, đổi chữ ký là lỗi biên dịch.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::proto {

enum class [[nodiscard]] DecodeError : std::uint8_t { kTooShort };

[[nodiscard]] inline std::expected<std::uint8_t, DecodeError> read_kind(std::span<const std::byte> packet) noexcept {
    if (packet.empty()) return std::unexpected(DecodeError::kTooShort);
    return std::to_integer<std::uint8_t>(packet.front());
}

static_assert(noexcept(read_kind(std::span<const std::byte>{})), "giải mã không được ném");

} // namespace game::proto
```

### LH-19 [T] NÊN — Tiến trình zone theo kiểu crash-only: dừng bất kỳ lúc nào không mất dữ liệu đã xác nhận; giám sát tự khởi động lại

Hệ quả của dừng sớm (fail-fast): `check` làm tiến trình dừng, nên khởi động lại phải là đường bình thường, đã
test, nhanh. Điều đã báo "thành công" cho người chơi phải nằm trong DB (hoặc nhật ký ghi trước) trước
khi báo; mọi thao tác ghi idempotent theo id yêu cầu (UB-15, MMO-*); khởi động = phục hồi. Tắt êm
(graceful shutdown) chỉ để nhanh hơn, không để đúng.

- **Vì sao:** "Crash-only software" (Candea, Fox — HotOS 2003): hệ chỉ có một đường dừng và một
  đường khởi động thì cả hai được chạy thường xuyên nên đáng tin; đường tắt êm hiếm chạy thì hỏng
  đúng lúc cần. Dừng sớm chặn trạng thái hỏng ở lỗi đầu tiên, trước khi nó vào DB.
- **Kiểm:** test hỗn loạn trên staging: `kill -9` tiến trình zone giữa giao dịch, rồi kiểm không mất
  và không nhân bản vật phẩm; cảnh báo khi số lần khởi động lại tăng (vòng sập là sự cố riêng).

```ini
# ✓ Đơn vị systemd cho tiến trình zone: tự khởi động lại, chặn vòng sập, giữ core dump.
[Unit]
Description=Zone server %i
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
ExecStart=/opt/game/bin/zone --zone=%i
Restart=on-failure
RestartSec=2
LimitCORE=infinity
TimeoutStopSec=30
```

## Kiểm nhanh

- [ ] Mỗi lỗi đã xếp loại: lỗi lập trình, môi trường, hay đầu vào client? (LH-01)
- [ ] Hợp đồng dùng `core::check`/`debug_check`/`fail`, không `assert`, thông điệp `hàm: điều sai`? (LH-02)
- [ ] Không `check`, `.value()`, `.at()` nào trên dữ liệu client; lỗi giải mã có đếm theo phiên? (LH-03)
- [ ] Mã lỗi là `enum class [[nodiscard]] : std::uint8_t`, `switch` không `default`? (LH-04)
- [ ] Mọi hàm trả `expected`/mã lỗi có `[[nodiscard]]`; không `*r` trước khi kiểm? (LH-05)
- [ ] Destructor, move, swap `noexcept`, có `static_assert` cạnh kiểu? (LH-06)
- [ ] Không `throw`, không `std::stoi`, chuỗi định dạng đều là hằng? (LH-07)
- [ ] Hàm vào luồng và callback C là `noexcept`? (LH-08)
- [ ] Client chỉ nhận mã công khai; chi tiết ở log có cấu trúc? (LH-10)
- [ ] Giao dịch kiểm và cấp phát hết trước dòng sửa trạng thái đầu tiên? (LH-12)
- [ ] Terminate handler đã cài, core dump bật, giám sát khởi động lại có giới hạn? (LH-13, LH-19)
- [ ] Bảng `constexpr` có `check` bất biến; vị từ `check` không tác dụng phụ? (LH-16, LH-17)
