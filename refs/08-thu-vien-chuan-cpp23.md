# STD · Thư viện chuẩn và tính năng C++23

> **Phạm vi:** chọn container, chuỗi, thuật toán và ranges, `<format>`/`<print>`, `<chrono>`,
> `<charconv>`, `<bit>`, `span`, optional/expected ở mức thư viện, tiện ích chỉ có ở một thư viện,
> `<random>` và băm, tra cứu dị thể, formatter tự viết, bẫy ranges, callback, regex, `import std;`,
> BẢNG HỖ TRỢ ĐO THẬT trên GCC 14.2 / GCC 15.2 / Clang 20 + libc++ 20. **Đọc khi:** chọn container
> hay kiểu tham số chuỗi/dãy; định dạng log; đọc số từ văn bản; dùng tính năng C++23 mà không chắc
> thư viện nào có; cần kết quả tất định (random, hash, thứ tự duyệt); viết `std::formatter`; dùng
> views; lưu callback; viết `#if __cpp_lib_…`.
> **Liên quan:** refs/03-kieu-gia-tri.md (KG-11, KG-13), refs/04-so-huu-vong-doi.md (SH),
> refs/05-loi-hop-dong.md (LH), refs/07-generic-compile-time.md (GN-07, GN-12),
> refs/09-hieu-nang.md (HN), refs/12-dong-thoi.md (DT), refs/14-build-toolchain.md (BD),
> refs/18-game-mmo.md (MMO).

## 0. Bảng hỗ trợ (đo trên máy kiểm, `-std=c++23`)

Đo bằng macro trong `<version>` VÀ biên dịch thật (`-fsyntax-only`; mục có ghi "chạy" đã liên kết và
chạy). "có*" = dùng được nhưng macro tương ứng VẮNG (STD-16). Thẻ mẫu tương ứng ở cột cuối.

| Tính năng | GCC 14.2 | GCC 15.2 | Clang 20 + libc++ 20 | Thẻ / đường lui |
|---|---|---|---|---|
| `expected` (+ monadic), `optional` monadic, `to_underlying`, `byteswap`, `unreachable`, `forward_like`, `invoke_r`, `bind_back`, `out_ptr` | có | có | có | — |
| `string::contains`, `resize_and_overwrite`, `string_view` từ range, `substr() &&` | có | có | có | — |
| `format`, `print`/`println` cho số, chuỗi, chrono `{:%F}`, `std::thread::id` | có | có | có (thread::id: có*) | — |
| định dạng range/tuple, `{:?}` (`__cpp_lib_format_ranges`) | KHÔNG | có | có | `[g15+c20]`; GCC 14: tự lặp |
| `ranges::to`, `views::zip`, `chunk_by`, `repeat`, `as_rvalue`, `ranges::contains`, `contains_subrange`, `find_last(_if)`, `fold_left`, `fold_left_with_iter`, `range_adaptor_closure` | có | có | có (zip, fold_left: có*) | — |
| `views::enumerate`, `zip_transform`, `adjacent`, `pairwise`, `chunk`, `slide`, `stride`, `join_with`, `cartesian_product`, `as_const`; `ranges::iota`, `fold_left_first`, `fold_right` | có | có | KHÔNG | `[g14+g15]`; `zip(iota(0UZ), r)` (STD-10) |
| `ranges::starts_with`/`ends_with` | KHÔNG | KHÔNG | có | `std::ranges::mismatch`, hoặc `string_view::starts_with` |
| `ranges::shift_left/right`; erase dị thể `map.erase(string_view)` (P2077) | KHÔNG | KHÔNG | KHÔNG | `std::shift_left`; `erase(find(k))` |
| `insert_range`, `append_range`, constructor `std::from_range` | KHÔNG | có | có | `ranges::to`, `insert(end, b, e)` |
| `flat_map` | KHÔNG | có | có | `[g15+c20]`; vector đã sắp (STD-16) |
| `flat_set` | KHÔNG | có | KHÔNG | `[g15]`; vector đã sắp + `unique` |
| `mdspan` (+ `m[i, j]`) | KHÔNG | KHÔNG | có | `[c20]`; mảng phẳng + hàm chỉ số |
| `generator` | có | có | KHÔNG | `[g14+g15]`; trả `vector` hoặc bộ duyệt tay |
| `move_only_function` | có | có | KHÔNG | `[g14+g15]`; STD-20 |
| `stacktrace` (liên kết cần `-lstdc++exp`, chạy) | có | có | KHÔNG | `[g14+g15]`; STD-13 |
| `spanstream`, `osyncstream` | có | có | KHÔNG | `[g14+g15]`; `format_to` vào buffer |
| `<stdfloat>` `float16_t`, `bfloat16_t` | có | có | KHÔNG | `[g14+g15]`; `Half` tự viết (types.hpp) |
| `atomic<shared_ptr<T>>` (libstdc++: KHÔNG lock-free, 16 B, chạy) | có | có | KHÔNG | `[g14+g15]`; mutex + `shared_ptr` (DT) |
| chrono `zoned_time`/tzdb, `utc_clock`, `parse` | có | có | KHÔNG | `[g14+g15]`; giờ UTC số nguyên |
| `from_chars`/`to_chars` số thực (chạy) | có | có | có* | — |
| `to_chars`/`from_chars` số nguyên constexpr | có | có | có | — |
| `<cmath>` constexpr (`__cpp_lib_constexpr_cmath`) | KHÔNG† | KHÔNG† | KHÔNG | †GCC gấp hằng như phần mở rộng (GN-05) |
| `is_implicit_lifetime` | KHÔNG | KHÔNG | có | `[c20]` |
| `reference_constructs_from_temporary` | có | có | KHÔNG | `[g14+g15]` |
| `jthread`, `stop_token`, `latch`, `barrier`, `counting_semaphore`, atomic `wait/notify`, `atomic_ref`, `atomic<float>::fetch_add` | có | có | có | — |
| `hardware_destructive_interference_size` | 64 | 64 | 64 | x86-64; BN |
| `execution::par` | có (tuần tự nếu thiếu TBB) | có (như trên) | KHÔNG | thread pool tự viết (DT) |
| `import std;` (`__cpp_lib_modules`) | KHÔNG | có với `-fmodules` (macro chỉ khi có cờ) | có (macro 202207L), tự dựng `std.cppm` | STD-22, BD-14 |
| deducing this, `if consteval`, `static operator()`, `operator[]` nhiều chiều, `auto(x)`, `[[assume]]` | có | có | có | ngôn ngữ (GN, API) |
| `start_lifetime_as` (C++23, chưa thư viện nào cài) | KHÔNG | KHÔNG | KHÔNG | `memcpy`/`bit_cast` (SH-14, UB-03) |
| C++26: `add_sat`, `inplace_vector`, `function_ref`, `copyable_function`, `views::concat`, `submdspan`, `span::at`, `runtime_format` | KHÔNG | KHÔNG | KHÔNG | không dùng; xem đường lui ở file chủ đề |

## 1. Nền tảng [N]

### STD-01 [N] PHẢI — Container mặc định là `std::vector`; container khác chọn theo bảng và ghi lý do

#### Bảng chọn container

| Nhu cầu | Chọn | Ghi chú |
|---|---|---|
| dãy mặc định | `std::vector` (+ `reserve`) | liền mạch, duyệt nhanh nhất; `clear()` giữ capacity |
| cỡ cố định lúc biên dịch | `std::array` | không cấp phát, constexpr |
| tra theo khoá, nhiều phần tử, không cần thứ tự | `std::unordered_map` + `reserve` | thứ tự duyệt KHÔNG ổn định (STD-15) |
| map nhỏ đọc nhiều ghi ít, cần thứ tự | `std::flat_map` `[g15+c20]` / vector đã sắp + `lower_bound` | GCC 14 thiếu `flat_map` (STD-16) |
| cần thứ tự + chèn/xoá giữa nhiều + iterator ổn định | `std::map` | container nút: một cấp phát mỗi phần tử |
| FIFO giữa luồng | ring buffer (DT) | `std::deque` chỉ khi một luồng |
| tập cờ cố định | `std::bitset` hoặc số không dấu + `<bit>` | |

- **Vì sao:** vector liền mạch: prefetcher đoán được, mỗi dòng cache 64 B chứa nhiều phần tử; container
  nút (`list`, `map`, `unordered_map`) cấp phát mỗi phần tử và nhảy con trỏ — mỗi bước có thể là một lần
  trượt cache (BN). `reserve` theo sức chứa đã biết (số người chơi tối đa) bỏ được rehash/realloc giữa
  tick.
- **Kiểm:** review mọi `std::list`, `std::map`, `std::deque` phải có comment lý do.

```cpp
// ✓ Bảng phiên: unordered_map + reserve theo số người chơi tối đa của máy chủ.
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <unordered_map>

namespace game::net {

enum class SessionId : std::uint32_t {};

struct Session {
    std::uint32_t account = 0;
    // Hạn chờ mạng tính theo steady_clock (STD-05), không theo tick game.
    std::chrono::steady_clock::time_point last_seen;
};

class SessionTable {
public:
    explicit SessionTable(std::size_t max_players) { sessions_.reserve(max_players); }

    // Không có → nullptr. Con trỏ mất hiệu lực khi bảng thêm/xoá phần tử.
    [[nodiscard]] Session* find(SessionId id) noexcept {
        const auto it = sessions_.find(id);
        return it == sessions_.end() ? nullptr : &it->second;
    }

private:
    std::unordered_map<SessionId, Session> sessions_;
};

} // namespace game::net
```

### STD-02 [N] PHẢI — Tham số chuỗi chỉ đọc là `std::string_view`; giữ lại thì `std::string`; dùng `contains`/`starts_with`/`ends_with`

Nhận `std::string_view` theo giá trị; lưu thì chép vào `std::string`. API C cần chuỗi kết thúc NUL
nhận `const std::string&` (hoặc `std::string` sink) — `string_view::data()` KHÔNG bảo đảm NUL.

- **Vì sao:** `const std::string&` buộc người gọi dựng `std::string` từ literal hay buffer: cấp phát
  khi dài hơn SSO (đo: 15 ký tự libstdc++, 22 ký tự libc++). `string_view` là (con trỏ, độ dài), truyền
  trong thanh ghi. `contains` (C++23) thay `find(x) != npos` — hết bẫy so với `npos`. Vòng đời view: SH.
- **Kiểm:** clang-tidy `performance-unnecessary-value-param`, `readability-container-contains`;
  review `.data()` của `string_view` đưa vào hàm C.

```cpp
// ✓ Lệnh chat: string_view cho đầu vào chỉ đọc; starts_with/contains thay find() != npos.
#include <cstdint>
#include <string_view>

namespace game::chat {

enum class Channel : std::uint8_t { kSay, kWhisper, kGuild };

[[nodiscard]] constexpr Channel channel_of(std::string_view line) noexcept {
    if (line.starts_with("/w ")) return Channel::kWhisper;
    if (line.starts_with("/g ")) return Channel::kGuild;
    return Channel::kSay;
}

[[nodiscard]] constexpr bool has_link(std::string_view line) noexcept {
    return line.contains("://");
}

static_assert(channel_of("/w bob hi") == Channel::kWhisper && has_link("xem http://x"));

} // namespace game::chat
```

### STD-03 [N] NÊN — Thuật toán chuẩn (`std::ranges::…`, `std::erase_if`) thay vòng lặp tay khi có thuật toán đúng tên

`find_if`, `any_of`, `count_if`, `max_element` (có projection), `sort`, `partition`, `std::erase_if` cho
xoá theo điều kiện.

- **Vì sao:** tên thuật toán nói ý định; hết lỗi chỉ số biên; `std::erase_if` là một lượt O(n) thay
  `erase` trong vòng lặp O(n²) (và iterator mất hiệu lực). Projection (`&Threat::amount`) bỏ được lambda so
  sánh. Bản ranges kiểm concept và trả `std::ranges::dangling` khi gọi trên rvalue.
- **Kiểm:** clang-tidy `modernize-loop-convert`, `modernize-use-ranges`; review vòng lặp có `break` tìm
  kiếm.

```cpp
// ✓ Xoá mục chết bằng erase_if; tìm mục tiêu thù hận cao nhất bằng projection.
#include <algorithm>
#include <cstdint>
#include <span>
#include <vector>

namespace game::combat {

struct Threat {
    std::uint32_t entity = 0;
    std::int32_t amount = 0;
    bool alive = true;
};

// Xoá không cấp phát, Threat sao chép tầm thường: không ném.
inline void drop_dead(std::vector<Threat>& table) noexcept {
    std::erase_if(table, [](const Threat& one) { return !one.alive; });
}

// Bảng rỗng → nullptr.
[[nodiscard]] inline const Threat* top_threat(std::span<const Threat> table) noexcept {
    const auto it = std::ranges::max_element(table, {}, &Threat::amount);
    return it == table.end() ? nullptr : &*it;
}

} // namespace game::combat
```

### STD-04 [N] PHẢI — Định dạng bằng `std::format`/`std::print`; đường nóng dùng `std::format_to` vào buffer tái dùng; CẤM `printf` và `iostream` trong code mới

- **Vì sao:** chuỗi định dạng của `std::format` được kiểm LÚC BIÊN DỊCH (sai số đối số hay kiểu là lỗi
  biên dịch); `printf("%d", int64)` là UB. `std::print` ghi thẳng ra `FILE*`, không qua locale như
  iostream. `std::format` trả `std::string` mới mỗi lần; trên đường nóng `format_to` vào `std::string`
  đã `clear()` (giữ capacity) không cấp phát khi buffer đủ lớn. Định dạng range (`{}` cho vector) cần
  `[g15+c20]` (bảng §0). Chi phí log, kiểm mức trước khi định dạng: HN.
- **Kiểm:** grep `printf`, `std::cout`, `std::endl`; ngoại lệ có chủ đích duy nhất là `core/check.hpp`
  (`fprintf` ASCII để không kéo `<format>` vào mọi TU; tidy `modernize-use-std-print` đã tắt vì tidy 20
  sập với chuỗi printf UTF-8 — BD-19).

```cpp
// ✓ Dòng log định dạng vào buffer tái dùng: không cấp phát khi buffer đã đủ lớn.
#include <cstdint>
#include <format>
#include <iterator>
#include <string>

namespace game::obs {

struct HitEvent {
    std::uint32_t attacker = 0;
    std::uint32_t target = 0;
    std::int64_t damage = 0;
};

// buffer là đầu ra tái dùng (API-02): clear() giữ capacity qua các lần gọi.
inline void format_hit(std::string& buffer, HitEvent hit) {
    buffer.clear();
    std::format_to(std::back_inserter(buffer), "hit {}->{} dmg={}", hit.attacker, hit.target, hit.damage);
}

} // namespace game::obs
```

### STD-05 [N] PHẢI — Đo khoảng thời gian và hạn chờ bằng `std::chrono::steady_clock`; `system_clock` chỉ cho mốc lịch; CẤM `high_resolution_clock`

- **Vì sao:** `system_clock` nhảy khi NTP chỉnh hay quản trị đổi giờ: timeout bắn sớm hoặc không bao giờ
  bắn. `steady_clock` đơn điệu. `high_resolution_clock` là bí danh khác nhau tuỳ thư viện (đo:
  `system_clock` ở libstdc++, `steady_clock` ở libc++) — code chạy đúng trên một máy, sai trên máy kia.
  Thời gian GAME tính bằng tick số nguyên (MMO), không đọc đồng hồ tường giữa tick; đơn vị trong kiểu:
  KG-09.
- **Kiểm:** grep `high_resolution_clock`, `system_clock::now()` ngoài module log/DB.

```cpp
// ✓ Hạn chờ truy vấn DB theo steady_clock; thời điểm "bây giờ" do nơi gọi truyền vào (test được).
#include <chrono>

namespace game::db {

using Clock = std::chrono::steady_clock;

struct PendingQuery {
    // Không cần {}: constructor mặc định của time_point đã cho epoch.
    Clock::time_point deadline;
};

[[nodiscard]] inline PendingQuery start_query(Clock::time_point now, std::chrono::milliseconds timeout) noexcept {
    return {.deadline = now + timeout};
}

[[nodiscard]] inline bool expired(PendingQuery query, Clock::time_point now) noexcept {
    return now >= query.deadline;
}

} // namespace game::db
```

### STD-06 [N] PHẢI — Đọc/ghi số dạng văn bản bằng `<charconv>`; kiểm `ec` VÀ đã tiêu thụ hết chuỗi; CẤM `atoi`/`stoi`/`strtol`/`sscanf`/`stringstream` trên dữ liệu ngoài

- **Vì sao:** `atoi` tràn là UB; `stoi` ném và phụ thuộc locale; `strtol`/`sscanf` theo locale và
  `errno`; `stringstream` cấp phát và theo locale. `from_chars`/`to_chars` không locale, không ngoại lệ,
  không cấp phát, round-trip chính xác số thực. Lưu ý: `from_chars` KHÔNG bỏ khoảng trắng đầu và KHÔNG
  nhận dấu `+`. Số thực chạy trên cả ba thư viện (đo, kể cả libc++ 20 dù thiếu macro `__cpp_lib_to_chars`).
- **Kiểm:** grep `atoi|stoi|stol|strto|sscanf|stringstream`.

```cpp
// ✓ Đọc số từ lệnh GM/tệp cấu hình: không locale, không ngoại lệ, phải tiêu thụ hết chuỗi.
#include <charconv>
#include <cstdint>
#include <memory>
#include <optional>
#include <string_view>
#include <system_error>

namespace game::config {

[[nodiscard]] inline std::optional<std::int32_t> parse_i32(std::string_view text) noexcept {
    const char* const first = std::to_address(text.begin());
    const char* const last = std::to_address(text.end());
    std::int32_t value = 0;
    const auto [stop, ec] = std::from_chars(first, last, value);
    if (ec != std::errc{} || stop != last) return std::nullopt;
    return value;
}

} // namespace game::config
```

### STD-07 [N] PHẢI — Thao tác bit bằng `<bit>` trên kiểu không dấu; đổi thứ tự byte bằng `std::byteswap` + `std::endian`

`std::popcount`, `countr_zero`, `countl_zero`, `bit_width`, `has_single_bit`, `bit_ceil`, `rotl`,
`byteswap`. Không `__builtin_ctz`, `__builtin_bswap32`, `htonl`/`ntohl`, mẹo dịch bit tay.

- **Vì sao:** các hàm `<bit>` chỉ nhận kiểu không dấu → `std::popcount(-1)` không biên dịch, bắt lỗi dấu.
  `__builtin_ctz(0)`/`__builtin_clz(0)` là UB, còn `std::countr_zero(0)` trả độ rộng — định nghĩa rõ.
  Tất cả constexpr và biên dịch thành một lệnh (POPCNT/TZCNT/BSWAP) khi `-march` cho phép (SV). `htonl`
  là API POSIX/WinSock và big-endian; giao thức game là little-endian (MMO).
- **Kiểm:** grep `__builtin_(ctz|clz|popcount|bswap)`, `htonl|ntohl`.

```cpp
// ✓ Mặt nạ buff 64 bit và u32 trên dây little-endian.
#include <bit>
#include <cstdint>

namespace game::combat {

[[nodiscard]] constexpr int active_buffs(std::uint64_t mask) noexcept {
    return std::popcount(mask);
}

// Buff bật có chỉ số nhỏ nhất; mask == 0 → 64.
[[nodiscard]] constexpr int first_buff(std::uint64_t mask) noexcept {
    return std::countr_zero(mask);
}

[[nodiscard]] constexpr std::uint32_t to_wire(std::uint32_t value) noexcept {
    if constexpr (std::endian::native == std::endian::big) return std::byteswap(value);
    return value;
}

static_assert(active_buffs(0b1011U) == 3 && first_buff(0U) == 64 && to_wire(7U) == 7U);

} // namespace game::combat
```

### STD-08 [N] PHẢI — Dãy liền kề làm tham số là `std::span<const T>`/`std::span<T>`; bộ đệm thô là `std::span<const std::byte>`

Không cặp (con trỏ, độ dài), không `const std::vector<T>&` khi hàm không cần chính vector. Cắt bằng
`first`, `last`, `subspan` thay số học con trỏ.

- **Vì sao:** span 16 byte truyền trong thanh ghi; nhận vector, array, buffer socket như nhau; kích
  thước đi kèm con trỏ nên không lệch được. `subspan` thay `ptr + offset`. Hardening thư viện kiểm
  `operator[]` của span (chính sách: UB). `span::at` là C++26 (đo: chưa có ở `-std=c++23`).
- **Kiểm:** clang-tidy `cppcoreguidelines-pro-bounds-pointer-arithmetic`; review tham số `T*, size_t`.

```cpp
// ✓ Đọc u16 little-endian đầu gói tin: nhận mọi bộ đệm liền kề, kiểm độ dài trước khi đọc.
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>

namespace game::proto {

[[nodiscard]] inline std::optional<std::uint16_t> read_u16_le(std::span<const std::byte> bytes) noexcept {
    if (bytes.size() < 2) return std::nullopt;
    const auto low = std::to_integer<std::uint16_t>(bytes[0]);
    const auto high = std::to_integer<std::uint16_t>(bytes[1]);
    return static_cast<std::uint16_t>(low | (high << 8U));
}

} // namespace game::proto
```

### STD-09 [N] CẤM — `.value()` của `optional`/`expected` trên đường game và mạng; truy cập bằng `*`/`->` sau câu bảo vệ, `value_or`, hoặc monadic

- **Vì sao:** `.value()` ném `bad_optional_access`/`bad_expected_access` khi rỗng; trong hàm `noexcept`
  là `std::terminate` — một gói tin thiếu trường làm sập cả máy chủ. Câu bảo vệ làm luồng lỗi hiển
  nhiên và giữ code phẳng; `*opt` khi rỗng là UB nên chỉ đứng SAU câu bảo vệ. Chọn optional vs expected,
  monadic: KG-11, LH-09.
- **Kiểm:** grep `\.value()`; hardening thư viện (BD-09, chính sách ở UB) bắt `*` trên optional rỗng;
  clang-tidy `bugprone-unchecked-optional-access` chỉ hiểu câu bảo vệ là nhánh — `if (!found) return
  …;` hoặc `if (!found) core::fail(…);` — không hiểu `core::check(found.has_value(), …)` (lời gọi hàm).

```cpp
// ✓ Giá mua: câu bảo vệ trước, rồi mới dùng ->.
#include <cstdint>
#include <expected>
#include <optional>

namespace game::inv {

enum class [[nodiscard]] TradeError : std::uint8_t { kUnknownItem, kBadCount };
enum class ItemId : std::uint32_t {};

struct ItemDef {
    std::int64_t price = 0;
};

[[nodiscard]] std::optional<ItemDef> find_item(ItemId item) noexcept;

[[nodiscard]] inline std::expected<std::int64_t, TradeError> buy_cost(ItemId item, std::int32_t count) noexcept {
    if (count <= 0 || count > 999) return std::unexpected(TradeError::kBadCount);
    const std::optional<ItemDef> def = find_item(item);
    if (!def) return std::unexpected(TradeError::kUnknownItem);
    // Bảng vật phẩm kiểm lúc nạp 0 <= price <= 10^12, count <= 999: tích < 10^15, không tràn
    // (UB-01). Thừa số không có cận như vậy thì nhân qua checked_mul (UB-10).
    return def->price * count;
}

} // namespace game::inv
```

## 2. Nâng cao [C]

### STD-10 [C] NÊN — Pipeline views + `std::ranges::to` thay vòng lặp gom; chỉ dùng view có ở cả hai thư viện, hoặc gắn thẻ

Lọc, ánh xạ, gom vào container: `r | views::filter | views::transform | ranges::to<std::vector>()`.
Trước khi dùng một view, tra bảng §0: `views::enumerate`, `chunk`, `stride`, `adjacent`, `join_with`…
KHÔNG có ở libc++ 20. Chỉ số + phần tử khả chuyển: `views::zip(views::iota(0UZ), r)` (đo: chạy cả ba).

- **Vì sao:** pipeline nói ý định, không biến tạm, `ranges::to` cấp phát một lần khi range có kích
  thước. Code dùng `enumerate` biên dịch trên máy dev GCC rồi gãy ở CI Clang/libc++ — hoặc gắn thẻ
  `[g14+g15]` và có đường lui, hoặc dùng tổ hợp khả chuyển. Bẫy view: STD-19.
- **Kiểm:** CI biên dịch cả libstdc++ và libc++ (BD-12).

```cpp
// ✓ Số thứ tự các điểm sinh của một loại quái: zip(iota, span) thay views::enumerate.
#include <cstddef>
#include <cstdint>
#include <ranges>
#include <span>
#include <vector>

namespace game::world {

struct Spawn {
    std::uint32_t monster = 0;
    std::int32_t x = 0;
};

[[nodiscard]] inline std::vector<std::size_t> spawn_slots(std::span<const Spawn> spawns, std::uint32_t monster) {
    const auto monsters = spawns | std::views::transform(&Spawn::monster);
    const auto matches = [monster](const auto& row) { return std::get<1>(row) == monster; };
    const auto slot = [](const auto& row) { return std::get<0>(row); };
    const auto numbered = std::views::zip(std::views::iota(0UZ), monsters);
    return numbered | std::views::filter(matches) | std::views::transform(slot) | std::ranges::to<std::vector>();
}

} // namespace game::world
```

### STD-11 [C] PHẢI — Gộp bằng `std::ranges::fold_left`, không `std::accumulate`; CẤM `std::reduce` khi cần tất định số thực

- **Vì sao:** kiểu bộ cộng dồn của `accumulate` là kiểu của giá trị đầu: `accumulate(w.begin(),
  w.end(), 0)` trên `float` cắt về `int` ở MỖI bước, im lặng. `fold_left` lấy kiểu theo kết quả phép
  toán (đo: `fold_left(floats, 0, plus{})` trả `float` trên cả ba). `fold_left` gộp trái sang phải cố
  định; `std::reduce` được phép nhóm lại tuỳ ý → tổng số thực khác nhau giữa thư viện, và giữa các lần
  chạy khi có execution policy song song — sai cho replay và lockstep (MMO). `fold_left_first`, `fold_right` thiếu ở libc++ 20.
- **Kiểm:** grep `std::accumulate`, `std::reduce`.

```cpp
// ✓ Tổng trọng số bảng rơi đồ: kiểu theo phép cộng, thứ tự trái → phải cố định.
#include <algorithm>
#include <functional>
#include <span>

namespace game::loot {

[[nodiscard]] inline float total_weight(std::span<const float> weights) noexcept {
    return std::ranges::fold_left(weights, 0.0F, std::plus<>{});
}

} // namespace game::loot
```

### STD-12 [C] NÊN — Ghi thẳng vào `std::string` bằng `resize_and_overwrite`, giữ đúng hợp đồng của `op`

Khi dựng chuỗi đã biết độ dài tối đa (hex, base64, mã hoá gói tin vào chuỗi): một lần
`resize_and_overwrite(n, op)` thay `resize(n)` (khởi tạo 0 rồi ghi đè).

- **Vì sao:** bỏ một lượt ghi 0 vô ích trên chuỗi lớn. Hợp đồng của `op(char* p, size_t n)`: chỉ ghi qua
  `p`, không quá `n` ký tự, trả độ dài thật `r <= n`, mọi ký tự trong `[p, p + r)` đã được ghi; KHÔNG
  ném (ném là UB) và không chạm vào chính chuỗi. Sai bất kỳ điều nào là UB.
- **Kiểm:** ASan/UBSan trong test (UB); review: `op` là lambda gọi một hàm `noexcept`.

```cpp
// ✓ Hex của mã phiên: ghi thẳng vào bộ nhớ chuỗi; op noexcept, trả đúng số ký tự đã ghi.
#include "core/check.hpp"

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

namespace game::net {

inline void write_hex(std::span<const std::byte> bytes, std::span<char> out) noexcept {
    core::check(out.size() >= bytes.size() * 2, "write_hex: out phải đủ 2 ký tự mỗi byte");
    constexpr std::string_view kDigits = "0123456789abcdef";
    for (std::size_t i = 0; i < bytes.size(); ++i) {
        const auto value = std::to_integer<unsigned>(bytes[i]);
        out[2 * i] = kDigits[value >> 4U];
        out[(2 * i) + 1] = kDigits[value & 0xFU];
    }
}

[[nodiscard]] inline std::string to_hex(std::span<const std::byte> bytes) {
    std::string text;
    text.resize_and_overwrite(bytes.size() * 2, [bytes](char* buffer, std::size_t size) noexcept {
        write_hex(bytes, std::span<char>(buffer, size));
        return size;
    });
    return text;
}

} // namespace game::net
```

### STD-13 [C] PHẢI — Tiện ích chỉ libstdc++ có (bảng §0) đi kèm đường lui hoặc thẻ; `std::stacktrace` cần `-lstdc++exp`

`generator`, `move_only_function`, `stacktrace`, `spanstream`, `float16_t`, `atomic<shared_ptr>`,
chrono múi giờ: dùng trong code chỉ build bằng GCC thì gắn thẻ `[g14+g15]`; code chung thì
`#if defined(__cpp_lib_…)` + đường lui (STD-16).

- **Vì sao:** dự án build cả GCC và Clang/libc++ (BD-12): một `#include <generator>` làm gãy cả CI
  Clang. `std::stacktrace` biên dịch được nhưng LIÊN KẾT lỗi (`undefined reference to
  std::stacktrace_entry::_Info::_M_populate`) nếu thiếu `-lstdc++exp` trên cả GCC 14 và 15 (đo).
  `atomic<shared_ptr>` của libstdc++ không lock-free (đo `is_lock_free() == false`): dùng nó cho cấu hình
  nóng là có khoá ẩn (DT).
- **Kiểm:** CI ma trận hai thư viện; CMake gắn `-lstdc++exp` có điều kiện (BD).

```cpp
// ✓ [g14+g15] [linux] In stacktrace khi dừng sớm; build Clang/libc++ bỏ hẳn tệp này.
#include <cstdio>
#include <stacktrace>
#include <string>

namespace game::core {

// Gọi trong terminate handler; cấp phát được vì tiến trình sắp dừng.
inline void dump_stacktrace(std::FILE* out) {
    const std::string text = std::to_string(std::stacktrace::current());
    static_cast<void>(std::fputs(text.c_str(), out));
}

} // namespace game::core
```

### STD-14 [C] CẤM — Dùng phân phối của `<random>` (và `std::shuffle`, `std::sample`) khi kết quả phải giống nhau giữa nền tảng

Engine chuẩn (`std::mt19937`…) là tất định theo chuẩn; phân phối (`uniform_int_distribution`,
`uniform_real_distribution`, `normal_distribution`…) và `std::shuffle` thì KHÔNG — mỗi thư viện một
thuật toán. Kết quả cần tái lập (rơi đồ được replay, lockstep, test có seed): tự ánh xạ khoảng từ
đầu ra thô của engine. PRNG của game (xoshiro, splitmix): MMO.

- **Vì sao:** đo với cùng `std::mt19937(12345)`: `uniform_int_distribution(1, 100)` cho `93 90 32 14 19
  4` (libstdc++) và `99 30 2 37 42 35` (libc++); `normal_distribution` cho cùng cặp số nhưng ĐẢO thứ tự;
  `std::shuffle` 8 phần tử với `mt19937(7)` cho `27641530` và `75360142`. Engine thì khớp (chuẩn còn quy
  định lần gọi thứ 10000 của `mt19937` mặc định là 4123659995 — đo khớp cả hai). Bẫy kèm: `f(eng(),
  eng())` — thứ tự đánh giá đối số là unspecified (UB-11; trong phép đo trên: GCC phải→trái, Clang trái→phải).
- **Kiểm:** grep `_distribution|std::shuffle|std::sample` trong module tất định; test replay so hash
  trạng thái trên hai thư viện (KT).

```cpp
// ✓ Số nguyên đều trong [0, bound) từ đầu ra thô: cùng kết quả trên mọi thư viện.
#include "core/check.hpp"

#include <cstdint>
#include <random>

namespace game::rng {

// Cho code dùng engine chuẩn (test có seed, công cụ); gameplay dùng PRNG của MMO-17. Nhân-dịch
// (Lemire, không loại bỏ): lệch tương đối tối đa ~bound / 2^32 — chấp nhận được khi bound <= 10^4.
[[nodiscard]] inline std::uint32_t uniform_below(std::mt19937& engine, std::uint32_t bound) noexcept {
    core::check(bound > 0, "uniform_below: bound phải dương");
    // mt19937 trả giá trị < 2^32 dù kiểu là uint_fast32_t: tích dưới đây không tràn 64 bit.
    const std::uint64_t raw = engine();
    return static_cast<std::uint32_t>((raw * bound) >> 32U);
}

} // namespace game::rng
```

### STD-15 [C] CẤM — Dựa vào thứ tự duyệt `unordered_*` hay giá trị `std::hash` cho dữ liệu lưu, gửi mạng, băm trạng thái hoặc logic tất định

- **Vì sao:** `std::hash` là định nghĩa của thư viện (đo: `hash<string>("sword")` khác nhau giữa libstdc++
  và libc++; `hash<int>(42) == 42` ở cả hai — hàm đồng nhất, dễ va chạm có chủ đích). Thứ tự duyệt
  phụ thuộc hash, số bucket, lịch sử chèn: cùng tập `{5, 1, 9, 3, 7, 100, 42}` duyệt ra hai thứ tự khác
  nhau trên hai thư viện (đo). Hệ quả: hash trạng thái replay lệch, gói tin snapshot khác byte, test
  "golden" gãy khi đổi trình dịch. Khoá do client chọn vào `unordered_map` với hash đồng nhất: DoS băm
  (UB/MMO).
- **Kiểm:** review mọi vòng duyệt `unordered_*` ghi ra ngoài; KT golden test trên hai thư viện.

```cpp
// ✓ Ghi trạng thái túi đồ để băm/lưu: sắp theo khoá trước, không duyệt unordered_map trực tiếp.
#include <algorithm>
#include <cstdint>
#include <ranges>
#include <unordered_map>
#include <utility>
#include <vector>

namespace game::inv {

using Counts = std::unordered_map<std::uint32_t, std::int32_t>;
using Row = std::pair<std::uint32_t, std::int32_t>;

[[nodiscard]] inline std::vector<Row> sorted_rows(const Counts& counts) {
    auto rows = counts | std::ranges::to<std::vector<Row>>();
    std::ranges::sort(rows);
    return rows;
}

} // namespace game::inv
```

## 3. Thần thoại [T]

### STD-16 [T] PHẢI — Chọn theo feature-test macro trong `<version>` + đường lui; biết các chỗ macro VẮNG mà tính năng CÓ

`#include <version>` rồi `#if defined(__cpp_lib_x) && __cpp_lib_x >= <giá trị>`; nhánh `#else` là
đường lui thật, không `#error`. Không suy ra từ phiên bản trình dịch (`__GNUC__`, `__clang_major__`):
Clang có thể đi với libstdc++.

- **Vì sao:** macro là cam kết của thư viện về MỘT mức đề xuất. Nhưng thư viện có thể cài phần lớn mà
  chưa định nghĩa macro vì thiếu một mảnh. Đo trên libc++ 20: `views::zip` có, `__cpp_lib_ranges_zip`
  vắng (thiếu `adjacent`); `fold_left` có, `__cpp_lib_ranges_fold` vắng (thiếu `fold_right`);
  `from_chars` số thực chạy đúng, `__cpp_lib_to_chars` vắng; formatter `thread::id` có,
  `__cpp_lib_formatters` vắng. Ngược lại GCC 15 chỉ định nghĩa `__cpp_lib_modules` khi có `-fmodules`.
  Clang 20 định nghĩa sẵn vài macro NGÔN NGỮ C++26 trong `-std=c++23` (`__cpp_pack_indexing`…) dù dùng
  là cảnh báo `-Wc++26-extensions`. Vậy: macro có → dùng; macro vắng → đường lui, trừ khi đã đo như trên.
- **Kiểm:** CI hai thư viện; mỗi `#if __cpp_lib` có test ở cả hai nhánh.

```cpp
// ✓ Bảng giá NPC: flat_map khi thư viện có (GCC 15, libc++ 20), map khi không (GCC 14).
#include <cstdint>
#include <optional>
#include <version>

#if defined(__cpp_lib_flat_map) && __cpp_lib_flat_map >= 202207L
#include <flat_map>
namespace game::shop {
using PriceTable = std::flat_map<std::uint32_t, std::int64_t>;
} // namespace game::shop
#else
#include <map>
namespace game::shop {
using PriceTable = std::map<std::uint32_t, std::int64_t>;
} // namespace game::shop
#endif

namespace game::shop {

[[nodiscard]] inline std::optional<std::int64_t> price_of(const PriceTable& table, std::uint32_t item_id) noexcept {
    const auto it = table.find(item_id);
    if (it == table.end()) return std::nullopt;
    return it->second;
}

} // namespace game::shop
```

### STD-17 [T] NÊN — Map khoá chuỗi tra bằng `string_view` không cấp phát: hash trong suốt + `std::equal_to<>`

`unordered_map<std::string, V, TextHash, std::equal_to<>>` với `TextHash::is_transparent`;
`map<std::string, V, std::less<>>`. Xoá: `erase(find(key))` — erase dị thể (P2077, C++23) chưa thư viện
nào có (đo).

- **Vì sao:** không trong suốt thì `find(name_view)` phải dựng `std::string` tạm: cấp phát mỗi lần tra
  khi tên dài hơn SSO (15/22 ký tự). Hash phải cho CÙNG giá trị với `string` và `string_view` cùng nội
  dung — dùng `std::hash<std::string_view>` cho cả hai. `static operator()` (C++23, đo có ở cả ba) bỏ con
  trỏ `this` thừa.
- **Kiểm:** profiler cấp phát (HN); review map khoá `std::string` được tra bằng `string_view`.

```cpp
// ✓ Bảng lệnh GM tra bằng string_view, không dựng std::string tạm.
#include <cstddef>
#include <cstdint>
#include <functional>
#include <string>
#include <string_view>
#include <unordered_map>

namespace game::gm {

struct TextHash {
    // Tên do chuẩn quy định (STD-17).
    using is_transparent = void;
    [[nodiscard]] static std::size_t operator()(std::string_view text) noexcept {
        return std::hash<std::string_view>{}(text);
    }
};

using CommandLevels = std::unordered_map<std::string, std::uint8_t, TextHash, std::equal_to<>>;

// Lệnh không có → cấp 0 (không ai dùng được).
[[nodiscard]] inline std::uint8_t required_level(const CommandLevels& table, std::string_view name) noexcept {
    const auto it = table.find(name);
    return it == table.end() ? std::uint8_t{0} : it->second;
}

} // namespace game::gm
```

### STD-18 [T] NÊN — Kiểu game in được bằng `std::formatter` tự viết: kế thừa formatter của kiểu nền, `format` là template theo context và `const`

Chuyên biệt hoá `std::formatter<T>` (lớp — GN-03 cho phép) kế thừa `std::formatter<Nền>` để nhận lại
toàn bộ đặc tả (`{:>8}`, `{:x}`); `template <class FormatContext> auto format(T, FormatContext&) const`.

- **Vì sao:** kế thừa thì `parse` của kiểu nền kiểm đặc tả LÚC BIÊN DỊCH, khỏi viết parser. Bẫy đo được
  trên cả ba thư viện: `format` nhận cụ thể `std::format_context&` vẫn chạy với `std::format`,
  `format_to`, nhưng `std::formattable<T, char>` SAI (concept thử với một context khác) và
  `std::format("{}", std::vector<T>{})` KHÔNG biên dịch (định dạng range dùng context riêng). Bản template
  thoả cả hai. Thiếu `const` ở `format` cũng làm `formattable` sai. Không viết `operator<<` cho log:
  iostream bị cấm (STD-04).
- **Kiểm:** `static_assert(std::formattable<T, char>)` cạnh mỗi formatter.

```cpp
// ✗ Context cụ thể: std::format chạy, nhưng formattable sai và không in được vector<EntityId>.
#include <cstdint>
#include <format>
#include <utility>

enum class EntityId : std::uint32_t {};

template <>
struct std::formatter<EntityId> : std::formatter<std::uint32_t> {
    auto format(EntityId id, std::format_context& ctx) const {
        return std::formatter<std::uint32_t>::format(std::to_underlying(id), ctx);
    }
};
```

```cpp
// ✓ EntityId in như số nền, nhận mọi đặc tả số; thoả std::formattable.
#include <cstdint>
#include <format>
#include <utility>

namespace game::world {

enum class EntityId : std::uint32_t {};

} // namespace game::world

template <>
struct std::formatter<game::world::EntityId> : std::formatter<std::uint32_t> {
    template <class FormatContext>
    [[nodiscard]] auto format(game::world::EntityId id, FormatContext& ctx) const {
        return std::formatter<std::uint32_t>::format(std::to_underlying(id), ctx);
    }
};

static_assert(std::formattable<game::world::EntityId, char>);
```

### STD-19 [T] CẤM — Sửa phần tử qua `views::filter` làm vị từ thành sai; trả view tham chiếu dữ liệu cục bộ; duyệt lại view lười sau khi nguồn đổi

- **Vì sao:** chuẩn cho phép sửa phần tử qua `filter_view` nhưng là UB nếu giá trị mới KHÔNG còn thoả vị
  từ ([range.filter.iterator]) — "hồi sinh mọi đơn vị chết" qua filter `hp <= 0` là UB, dù thường chạy.
  `filter_view` và `drop_while_view` cache `begin()` ở lần duyệt đầu: duyệt lại sau khi nguồn đổi dùng
  cache cũ; vì cache nên chúng không duyệt được qua `const&`. View lười giữ tham chiếu tới nguồn: trả
  `vec | views::filter(…)` với `vec` cục bộ là treo (SH). `views::transform` gọi lại hàm ở MỖI lần
  dereference — sau nó là `filter` thì hàm chạy hai lần cho mỗi phần tử qua lọc.
- **Kiểm:** review mọi `for (… : … | views::filter)` có gán; ASan cho view treo.

```cpp
// ✗ UB: gán hp = 1 làm phần tử hết thoả vị từ của filter đang duyệt.
#include <cstdint>
#include <ranges>
#include <vector>

struct Unit {
    std::int32_t hp = 0;
};

inline void revive_all(std::vector<Unit>& units) {
    for (Unit& unit : units | std::views::filter([](const Unit& one) { return one.hp <= 0; })) {
        unit.hp = 1;
    }
}
```

```cpp
// ✓ Ghi thì duyệt cả dãy, điều kiện trong hàm một phần tử; filter chỉ để ĐỌC.
#include <algorithm>
#include <cstdint>
#include <span>

namespace game::sim {

struct Unit {
    std::int32_t hp = 0;
};

inline void revive_one(Unit& unit) noexcept {
    if (unit.hp > 0) return;
    unit.hp = 1;
}

inline void revive_all(std::span<Unit> units) noexcept {
    std::ranges::for_each(units, revive_one);
}

} // namespace game::sim
```

### STD-20 [T] PHẢI — Callback LƯU LẠI dùng `std::move_only_function` khi có, `std::function` khi không; biết bộ đệm trong; `function_ref` là C++26

Gọi ngay → template (GN-07). Lưu để gọi sau (hoàn tất truy vấn DB, hẹn giờ) → `move_only_function`
(nhận lambda giữ `unique_ptr`, có `const`/`noexcept` trong chữ ký). libc++ 20 thiếu → `std::function`
+ trạng thái move-only bọc trong `shared_ptr`.

- **Vì sao:** `std::function` đòi callable SAO CHÉP được — lambda giữ `unique_ptr<Row>` không vào được.
  Bộ đệm trong đo được: `std::function` 32 B, capture ≤ 16 B không cấp phát (libstdc++); 48 B, ≤ 24 B
  (libc++); `move_only_function` 40 B, ≤ 24 B (libstdc++). Capture vượt ngưỡng → một lần cấp phát mỗi
  lần tạo callback. `std::function_ref` (không sở hữu, không cấp phát) là C++26 — C++23 dùng tham số
  template.
- **Kiểm:** `static_assert(sizeof(capture) <= 16)` cho callback trên đường nóng; profiler cấp phát.

```cpp
// ✓ Kiểu callback hoàn tất truy vấn: move_only_function nếu có, đường lui std::function.
#include <cstdint>
#include <functional>

namespace game::db {

struct LoadResult {
    std::uint64_t character_id = 0;
    bool found = false;
};

// <functional> định nghĩa sẵn macro này (cùng <version>), nên không cần include thêm.
#if defined(__cpp_lib_move_only_function) && __cpp_lib_move_only_function >= 202110L
using OnLoaded = std::move_only_function<void(const LoadResult&)>;
#else
// libc++ 20: callable phải sao chép được — trạng thái move-only bọc trong shared_ptr.
using OnLoaded = std::function<void(const LoadResult&)>;
#endif

} // namespace game::db
```

### STD-21 [T] CẤM — `std::regex` trên đường nóng và trên mọi đầu vào từ client

Kiểm dạng chuỗi (tên nhân vật, lệnh chat) bằng `string_view` + `<algorithm>` + `<charconv>`; cần
ngôn ngữ phức tạp hơn thì parser tay tuyến tính có giới hạn độ dài.

- **Vì sao:** cài đặt của libstdc++ đệ quy theo độ dài đầu vào: `regex_match` với `(a|b)*` trên chuỗi
  30 000 ký tự SẬP (segfault, ngăn xếp 8 MiB — đo); libc++ chịu được trên mẫu này nhưng vẫn quay lui hàm
  mũ với mẫu xấu. Một tin chat dài là đủ để hạ máy chủ. Ngoài ra regex dựng chậm (cấp phát) và theo
  locale. `std::isalnum` cũng theo locale và là UB với `char` âm — so khoảng ký tự tường minh.
- **Kiểm:** grep `<regex>` ngoài công cụ offline; fuzz parser đầu vào (KT).

```cpp
// ✓ Tên nhân vật [A-Za-z0-9_]{3,16}: tuyến tính, constexpr, không cấp phát, không locale.
#include <algorithm>
#include <string_view>

namespace game::account {

[[nodiscard]] constexpr bool is_name_char(char letter) noexcept {
    const bool lower = letter >= 'a' && letter <= 'z';
    const bool upper = letter >= 'A' && letter <= 'Z';
    const bool digit = letter >= '0' && letter <= '9';
    return lower || upper || digit || letter == '_';
}

[[nodiscard]] constexpr bool is_valid_name(std::string_view name) noexcept {
    if (name.size() < 3 || name.size() > 16) return false;
    return std::ranges::all_of(name, is_name_char);
}

static_assert(is_valid_name("Hero_01") && !is_valid_name("ab") && !is_valid_name("bad name"));

} // namespace game::account
```

### STD-22 [T] KHÔNG NÊN — `import std;` trong code production C++23 lúc này; giữ `#include`, theo dõi thực trạng

- **Vì sao:** đo: GCC 14 không có; GCC 15 có nhưng phải bật `-fmodules` (vẫn ghi "experimental") và tự
  dựng `bits/std.cc`; Clang 20 + libc++ có macro `__cpp_lib_modules` 202207L nhưng phải tự dựng
  `std.cppm`. CMake cần ≥ 3.30 và tính năng còn thử nghiệm (BD-14); máy kiểm có CMake 3.28. Mỗi trình
  dịch một định dạng BMI, không dùng chung được. Lợi ích (biên dịch nhanh) chưa đáng rủi ro build;
  module của CHÍNH dự án thì xem BD-14, KTR.
- **Kiểm:** thử định kỳ bằng lệnh dưới (đã chạy được trên máy kiểm).

```bash
# GCC 15: dựng module std rồi dùng (đo ~5 s cho std.cc).
g++-15 -std=c++23 -fmodules -fsearch-include-path -c bits/std.cc -o std.o
g++-15 -std=c++23 -fmodules main.cpp std.o -o main
# Clang 20 + libc++: tiền biên dịch std.cppm (đường dẫn của bản cài libc++).
clang++-20 -std=c++23 -stdlib=libc++ -Wno-reserved-module-identifier --precompile \
    -o std.pcm /usr/share/libc++/v1/std.cppm
clang++-20 -std=c++23 -stdlib=libc++ -fmodule-file=std=std.pcm main.cpp std.pcm -o main
```

## Kiểm nhanh

- [ ] Container không phải vector/array có comment lý do theo bảng? (STD-01)
- [ ] Tham số chuỗi chỉ đọc là `string_view`; không `.data()` của view vào API C? (STD-02)
- [ ] Không `printf`/`iostream`/`std::endl`; đường nóng `format_to` vào buffer tái dùng? (STD-04)
- [ ] Hạn chờ dùng `steady_clock`; không `high_resolution_clock`? (STD-05)
- [ ] Số từ văn bản đọc bằng `from_chars`, kiểm `ec` và `ptr == end`? (STD-06)
- [ ] Không `.value()` trên đường game/mạng? (STD-09)
- [ ] Mọi view/tiện ích dùng có ở cả libstdc++ và libc++, hoặc gắn thẻ + đường lui? (STD-10, STD-13, §0)
- [ ] Không `accumulate`/`reduce` cho tổng số thực cần tất định? (STD-11)
- [ ] Module tất định không dùng phân phối `<random>`, `shuffle`, thứ tự `unordered_*`, `std::hash`? (STD-14, STD-15)
- [ ] `#if __cpp_lib_…` có đường lui thật, test cả hai nhánh? (STD-16)
- [ ] Không sửa phần tử qua `filter` làm vị từ sai; không trả view của dữ liệu cục bộ? (STD-19)
- [ ] Không `std::regex` với đầu vào client? (STD-21)
