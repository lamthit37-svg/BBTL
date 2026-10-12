# KG · Kiểu và giá trị

> **Phạm vi:** const/constexpr/auto, khởi tạo và aggregate, kiểu số nguyên, chuyển đổi hẹp, ép kiểu
> và biểu diễn bit, enum, kiểu mạnh (ID, đơn vị, miền), so sánh mặc định, optional/variant, bố cục
> struct lưu/mạng. **Đọc khi:** khai báo biến/thành viên; chọn kiểu cho trường DB, gói tin, tiền,
> chỉ số; gặp `-Wconversion`; viết ép kiểu; thêm enum hay tham số `bool`; định nghĩa ID; viết struct
> gói tin/bản ghi replay; cần "không có giá trị", tập lệnh đóng, trạng thái phiên.
> **Liên quan:** refs/04-so-huu-vong-doi.md (SH-08, SH-14), refs/05-loi-hop-dong.md (LH),
> refs/06-ham-lop-api.md (API-01, API-08, API-09, API-11), refs/13-ub-on-dinh.md (UB),
> refs/18-game-mmo.md (MMO).

## 1. Nền tảng [N]

### KG-01 [N] PHẢI — Biến không gán lại là `const`, hằng là `constexpr`, `auto` chỉ khi kiểu đã hiện

Hằng ở phạm vi namespace trong header là `inline constexpr`. `auto` cho kiểu đã viết ở vế phải
(`std::make_unique<T>`, `static_cast<T>`), iterator, kết quả thuật toán, lambda; giá trị số học ghi
kiểu rõ; luôn viết `const auto&`, `auto*`.

- **Vì sao:** `const` cho người đọc biết giá trị không đổi, khỏi dò phép gán. Trong biểu thức hằng,
  UB (tràn có dấu, chia 0, ngoài biên) là lỗi biên dịch. `constexpr` ở namespace ngầm `const` nên
  liên kết nội bộ: mỗi TU một bản; `inline constexpr` là một thực thể. `auto gap = a.size() - b.size()`
  ẩn kiểu không dấu (âm thành ~1.8e19); `auto item = bag.at(i)` sao chép cả struct; proxy như
  `std::vector<bool>::reference` không phải `bool` và treo khi container chết.
- **Kiểm:** clang-tidy `misc-const-correctness`, `readability-qualified-auto`, `modernize-use-auto`.
- **Ngoại lệ:** biến sắp trả về hoặc `std::move` đi: `const` biến move thành copy (SH-08).

```cpp
// ✓ Hằng constexpr, trung gian const; auto cho kết quả thuật toán, phép trừ ghi kiểu rõ.
#include <algorithm>
#include <cstdint>
#include <span>

namespace game::combat {

inline constexpr std::int32_t kMinDamage = 1;

struct Monster {
    std::uint32_t id = 0;
    std::int32_t armor = 0;
};

// Sát thương lên con giáp dày nhất, không dưới kMinDamage; 0 khi không có mục tiêu.
[[nodiscard]] constexpr std::int32_t hit_tankiest(std::span<const Monster> targets, std::int32_t attack) noexcept {
    if (targets.empty()) return 0;
    const auto tankiest = std::ranges::max_element(targets, {}, &Monster::armor);
    const std::int32_t mitigated = attack - (tankiest->armor / 4);
    return std::max(mitigated, kMinDamage);
}

} // namespace game::combat
```

### KG-02 [N] PHẢI — Mọi biến, mọi thành viên khởi tạo tại chỗ; dữ liệu thuần là aggregate tạo bằng designated initializer

Thành viên kiểu vô hướng, enum, con trỏ và mảng của chúng có default member initializer; thành
viên kiểu lớp có constructor mặc định (`std::string`, `std::vector`, `std::span`) thì không viết `{}`
— clang-tidy `readability-redundant-member-init` báo thừa. Biến cục bộ có giá trị đầu. Struct không có bất biến giữa
các trường: thành viên public, không constructor, nơi tạo viết `{.field = …}`. Kiểu có bất biến dùng
constructor (API-08).

- **Vì sao:** thiếu initializer thì `Buff buff;` để mọi trường không xác định; đọc chúng là UB trong
  C++23 ([basic.indet]; C++26 đổi thành "erroneous behavior", P2795, vẫn là lỗi). Struct gửi đi có
  trường rác làm lộ ngăn xếp qua mạng và phá tất định replay. Default member initializer giữ
  aggregate (từ C++14) và sao chép tầm thường. `{9001, 60, …}` lệch nghĩa âm thầm khi chèn trường;
  designator sai thứ tự là ill-formed (C++ buộc theo thứ tự khai báo; GCC báo lỗi, Clang cảnh báo
  `-Wreorder-init-list`, thành lỗi dưới `-Werror`), trường bỏ qua lấy mặc định — đã đo: GCC 14,
  Clang 20 với `-Wextra` không cảnh báo trường bỏ qua CÓ default member initializer, đúng ý đồ
  (trường không có thì bị `-Wmissing-field-initializers` báo).
- **Kiểm:** clang-tidy `cppcoreguidelines-pro-type-member-init`, `cppcoreguidelines-init-variables`,
  `modernize-use-designated-initializers`; `-Wmaybe-uninitialized` (GCC, cần -O); MSan.

```cpp
// ✓ Lệnh sinh boss: mọi trường có mặc định, nơi tạo chỉ ghi trường khác mặc định.
#include <chrono>
#include <cstdint>

namespace game::world {

struct SpawnRequest {
    std::uint32_t template_id = 0;
    std::int32_t level = 1;
    float pos_x = 0.0F;
    float pos_y = 0.0F;
    std::chrono::seconds respawn{30};
};

[[nodiscard]] constexpr SpawnRequest boss_at(float pos_x, float pos_y) noexcept {
    return {.template_id = 9001, .level = 60, .pos_x = pos_x, .pos_y = pos_y};
}

} // namespace game::world
```

### KG-03 [N] PHẢI — Chọn kiểu số nguyên theo vai trò của giá trị

| Vai trò | Kiểu | Lý do |
|---|---|---|
| Trường lưu DB, gói tin, tệp | `std::int8_t` … `std::uint64_t` | cỡ là một phần của định dạng |
| Kích thước, số phần tử, chỉ số container | `std::size_t` | khớp `size()`, không trộn dấu |
| Hiệu hai chỉ số | `std::ptrdiff_t` | hiệu có thể âm |
| Tiền tệ, kinh nghiệm tích luỹ | `std::int64_t`, đơn vị nhỏ nhất | float mất chính xác trên 2^24 |
| Mặt nạ bit, hash | `std::uint32_t`, `std::uint64_t` | dịch bit, quấn tràn được định nghĩa |
| Đếm, tính toán thường | `int`, `std::int32_t` | tràn là UB nên UBSan bắt được |

CẤM `long` (32 bit trên Windows LLP64, 64 bit trên Linux LP64), `char` làm số (có dấu trên x86,
không dấu trên AArch64 Linux), float/double cho tiền.

- **Vì sao:** "không âm thì unsigned" là bẫy: `count - 1` với `count == 0` thành 4 tỉ và đi tiếp im
  lặng; số có dấu tràn là UB nên sanitizer báo được. Hai `std::int32_t` nhân rồi gán vào
  `std::int64_t` vẫn tràn ở 32 bit: mở rộng TRƯỚC khi nhân.
- **Kiểm:** `-Wconversion -Wsign-conversion`; clang-tidy `modernize-use-integer-sign-comparison`,
  `bugprone-implicit-widening-of-multiplication-result`, `bugprone-misplaced-widening-cast`,
  `bugprone-too-small-loop-variable`, `google-runtime-int` (bắt `long`, `short`).

```cpp
// ✓ Trường lưu cỡ cố định; tiền int64 đơn vị nhỏ nhất, mở rộng trước khi nhân.
#include <cstdint>

namespace game::inv {

struct ItemStack {
    std::uint32_t item_type = 0;
    // Khớp cột SMALLINT UNSIGNED.
    std::uint16_t count = 0;
    // Mặt nạ bit.
    std::uint16_t flags = 0;
};

inline constexpr std::int64_t kCopperPerGold = 10'000;

[[nodiscard]] constexpr std::int64_t to_copper(std::int32_t gold) noexcept {
    return std::int64_t{gold} * kCopperPerGold;
}

static_assert(to_copper(1'000'000) == 10'000'000'000);

} // namespace game::inv
```

### KG-04 [N] PHẢI — Chuyển đổi thu hẹp có kiểm: `core::narrow<T>` khi giá trị có thể ngoài miền

`static_cast` sang kiểu hẹp chỉ khi miền vừa được chứng minh; còn lại `narrow` (dừng sớm). Dữ liệu
từ client KHÔNG qua `narrow` — abort làm sập máy chủ: kiểm bằng `std::in_range` rồi trả lỗi
(refs/05-loi-hop-dong.md).

- **Vì sao:** `static_cast<std::uint16_t>(70'000)` cho 4'464 — số vật phẩm bị cắt âm thầm thành lỗi
  nhân bản đồ. Số thực sang số nguyên ngoài miền hay NaN là UB ([conv.fpint]), không phải "cắt".
  `std::in_range` không nhận `bool` và kiểu ký tự (ill-formed).
- **Kiểm:** `-Wconversion`; clang-tidy `bugprone-narrowing-conversions`; UBSan
  `-fsanitize=float-cast-overflow`.

```cpp
// ✓ narrow cho lỗi lập trình; in_range + optional cho dữ liệu không tin cậy.
#include "core/check.hpp"

#include <concepts>
#include <cstdint>
#include <optional>
#include <utility>

namespace game::core {

template <std::integral To, std::integral From>
[[nodiscard]] constexpr To narrow(From value) noexcept {
    check(std::in_range<To>(value), "narrow: giá trị ngoài miền kiểu đích");
    return static_cast<To>(value);
}

} // namespace game::core

namespace game::inv {

[[nodiscard]] constexpr std::optional<std::uint16_t> count_from_client(std::int64_t raw) noexcept {
    if (!std::in_range<std::uint16_t>(raw)) return std::nullopt;
    return static_cast<std::uint16_t>(raw);
}

static_assert(core::narrow<std::uint16_t>(65'535) == 65'535);
static_assert(!count_from_client(70'000).has_value());

} // namespace game::inv
```

### KG-05 [N] CẤM — Ép kiểu cú pháp C, ép kiểu hàm `T(x)`, union punning; dùng ép kiểu có tên

Giá trị số: `static_cast`. Biểu diễn bit: `std::bit_cast`. Bộ đệm thô: `std::span<const std::byte>`,
số nhiều byte ghép bằng phép dịch. `reinterpret_cast` chỉ ở ranh giới API C/hệ điều hành, kèm NOLINT
có lý do, không bao giờ để xem một đối tượng như kiểu khác.

- **Vì sao:** `(Header*)bytes` thử lần lượt `const_cast`, `static_cast`, `reinterpret_cast`: bỏ
  `const`, vi phạm strict aliasing, có thể lệch căn lề — không lời nào; `T(x)` một đối số y hệt. Đọc
  thành viên union không hoạt động là UB (GCC chỉ hứa như phần mở rộng; biểu thức hằng từ chối).
  `std::bit_cast` constexpr và kiểm cỡ lúc biên dịch; `std::byte` không có phép số học. Đã đo:
  GCC 14, GCC 15, Clang 20 `-O2` gộp `load_f32_le` dưới đây thành đúng một lệnh `movss` (x86-64).
- **Kiểm:** `-Wold-style-cast` (không bắt `T(x)`); clang-tidy `cppcoreguidelines-pro-type-cstyle-cast`,
  `cppcoreguidelines-pro-type-reinterpret-cast`, `cppcoreguidelines-pro-type-union-access`.

```cpp
// ✓ float little-endian từ gói tin, độc lập endian máy; static_cast có tiền điều kiện được kiểm.
#include "core/check.hpp"

#include <bit>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::net {

[[nodiscard]] constexpr float load_f32_le(std::span<const std::byte, 4> raw) noexcept {
    const auto octet = [raw](std::size_t i) { return std::to_integer<std::uint32_t>(raw[i]); };
    const std::uint32_t bits = octet(0) | (octet(1) << 8U) | (octet(2) << 16U) | (octet(3) << 24U);
    return std::bit_cast<float>(bits);
}

// Tiền điều kiện: value trong [-2^31, 2^31). Hai cận đều biểu diễn đúng bằng float, nhưng int32
// không chứa 2^31 nên cận trên loại trừ; NaN trượt cả hai phép so. Số từ gói tin kiểm miền và trả
// lỗi trước khi gọi (UB-05), không để check dừng máy chủ.
[[nodiscard]] constexpr std::int32_t truncate_to_int(float value) noexcept {
    core::check(value >= -2147483648.0F && value < 2147483648.0F, "truncate_to_int: ngoài miền");
    return static_cast<std::int32_t>(value);
}

} // namespace game::net
```

### KG-06 [N] PHẢI — Enum là `enum class` có kiểu nền tường minh; lấy số bằng `std::to_underlying`

Kiểu nền nhỏ nhất đủ chứa. Số từ mạng/DB được kiểm miền TRƯỚC khi `static_cast` sang enum.

- **Vì sao:** enum không phạm vi chuyển ngầm sang `int` (`rarity * 2` biên dịch) và rải tên ra
  namespace. Kiểu nền ghi rõ giữ `sizeof` ổn định cho định dạng lưu và cho khai báo trước. Ép giá
  trị ngoài miền vào enum không phạm vi thiếu kiểu nền cố định là UB ([expr.static.cast]); `enum
  class` luôn có kiểu nền cố định nên giá trị hợp lệ nhưng không khớp enumerator nào — `switch` trượt
  mọi case. Vì vậy kiểm miền.
- **Kiểm:** `-Wswitch` (`-Wall`); clang-tidy `performance-enum-size` (đòi kiểu nhỏ nhất kể cả khi đã
  ghi `std::int32_t`; trường giao thức rộng hơn thì NOLINT kèm lý do).

```cpp
// ✓ Byte độ hiếm từ gói tin: ngoài miền là dữ liệu xấu, không phải lỗi lập trình.
#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>

namespace game::inv {

enum class Rarity : std::uint8_t { kCommon, kRare, kEpic, kLegendary };

inline constexpr std::size_t kRarityCount = std::to_underlying(Rarity::kLegendary) + 1U;

[[nodiscard]] constexpr std::optional<Rarity> rarity_from_wire(std::uint8_t raw) noexcept {
    if (raw >= kRarityCount) return std::nullopt;
    return static_cast<Rarity>(raw);
}

} // namespace game::inv
```

### KG-07 [N] CẤM — Tham số `bool` làm cờ hành vi; mỗi cờ là một `enum class`

- **Vì sao:** `spawn_monster(id, true, false)` không đọc được ở nơi gọi, đảo hai cờ vẫn biên dịch,
  `bool` còn nhận ngầm con trỏ và số. Enum hai giá trị tự ghi nghĩa; đổi chỗ là lỗi biên dịch.
- **Kiểm:** review; clang-tidy `bugprone-easily-swappable-parameters` (tham số cùng kiểu liền nhau).
- **Ngoại lệ:** setter nhận đúng một giá trị là dữ liệu (`set_visible(bool visible)`).

```cpp
// ✓ Cờ là enum class trong struct lệnh: nơi gọi tự mô tả.
#include <cstdint>

namespace game::world {

enum class Tier : std::uint8_t { kNormal, kElite };
enum class Announce : std::uint8_t { kSilent, kNotifyNearby };

struct SpawnOrder {
    std::uint32_t template_id = 0;
    Tier tier = Tier::kNormal;
    Announce announce = Announce::kSilent;
};

[[nodiscard]] constexpr SpawnOrder ambush(std::uint32_t template_id) noexcept {
    return {.template_id = template_id, .tier = Tier::kElite, .announce = Announce::kSilent};
}

} // namespace game::world
```

### KG-08 [N] PHẢI — Mỗi loại ID là một kiểu riêng (`StrongId<Tag>`), không phải số nguyên trần

Số trần chỉ lộ qua `value()` ở ranh giới lưu/mạng. Constructor `explicit`, không chuyển ngầm về số,
không phép số học. Dạng enum không cần lớp: KG-16.

- **Vì sao:** `kick(std::uint64_t account, std::uint32_t avatar)` gọi đảo thành `kick(avatar, account)`
  chỉ bị `-Wconversion` bắt nhờ chiều 64 → 32 là thu hẹp; hai ID cùng `std::uint32_t` đổi chỗ thì
  không công cụ nào thấy ở nơi gọi. Một template với thẻ (kiểu chỉ khai báo) sinh kiểu khác nhau cho
  mỗi thẻ, chi phí chạy bằng 0.
- **Kiểm:** `static_assert(!std::is_convertible_v<…>)`; `bugprone-easily-swappable-parameters` im lặng
  khi tham số khác kiểu.

```cpp
// ✓ StrongId: một định nghĩa, vô số kiểu ID; làm khoá unordered_map được.
#include <compare>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <type_traits>

namespace game::core {

template <class Tag, class Rep = std::uint32_t>
class StrongId {
public:
    constexpr StrongId() noexcept = default;
    constexpr explicit StrongId(Rep value) noexcept : value_(value) {}

    [[nodiscard]] constexpr Rep value() const noexcept { return value_; }

    friend constexpr std::strong_ordering operator<=>(StrongId, StrongId) = default;

private:
    Rep value_{};
};

} // namespace game::core

// Được phép: [namespace.std].
template <class Tag, class Rep>
struct std::hash<game::core::StrongId<Tag, Rep>> {
    using Id = game::core::StrongId<Tag, Rep>;

    [[nodiscard]] static std::size_t operator()(Id id) noexcept { return std::hash<Rep>{}(id.value()); }
};

namespace game::world {

using EntityId = core::StrongId<struct EntityTag>;
using AccountId = core::StrongId<struct AccountTag, std::uint64_t>;

static_assert(!std::is_convertible_v<std::uint32_t, EntityId>);
static_assert(!std::is_convertible_v<EntityId, AccountId>);

} // namespace game::world
```

### KG-09 [N] PHẢI — Đại lượng có đơn vị mang đơn vị trong kiểu; thời gian là `std::chrono::duration`

Cấm `int timeout_ms`, `float cooldown`. Khoảng tính bằng tick là `duration` có `ratio` riêng; mốc
tick là `enum class Tick` (MMO-03); đổi đơn vị có mất mát ghi rõ `floor`/`ceil`/`round`.

- **Vì sao:** `duration` chỉ chuyển ngầm khi không mất mát (giây → ms được, ms → giây là lỗi biên
  dịch); cộng ms với tick tự quy về đơn vị chung. Sai đơn vị thành lỗi biên dịch, chi phí chạy bằng 0
  (`duration` chỉ chứa `rep`). Chọn đồng hồ: refs/08-thu-vien-chuan-cpp23.md.
- **Kiểm:** review; `-Wconversion` bắt `rep` hẹp.
- **Ngoại lệ:** trường của struct lưu/mạng (KG-17) và tham số API C giữ số trần cỡ cố định, tên mang
  hậu tố đơn vị (`x_cm`, `cooldown_ticks`); đổi sang `duration` ngay ở ranh giới đọc/ghi.

```cpp
// ✓ Hồi chiêu: ms từ dữ liệu thiết kế làm tròn LÊN thành tick; mốc là Tick, khoảng là duration.
#include "core/check.hpp"

#include <chrono>
#include <cstdint>
#include <ratio>
#include <utility>

namespace game::sim {

// Mốc: số tick từ lúc zone khởi động (MMO-03); uint64 không tràn trong tuổi thọ máy chủ.
enum class Tick : std::uint64_t {};

// Khoảng: 1 tick = 50 ms (20 Hz).
using TickSpan = std::chrono::duration<std::int64_t, std::ratio<1, 20>>;

// ceil: hồi chiêu 120 ms chờ đủ 3 tick, không bị làm tròn xuống 2.
[[nodiscard]] constexpr Tick ready_at(Tick now, std::chrono::milliseconds cooldown) noexcept {
    core::check(cooldown.count() >= 0, "ready_at: cooldown phải không âm");
    const auto wait = std::chrono::ceil<TickSpan>(cooldown);
    return Tick{std::to_underlying(now) + static_cast<std::uint64_t>(wait.count())};
}

static_assert(ready_at(Tick{10}, std::chrono::milliseconds{120}) == Tick{13});

} // namespace game::sim
```

### KG-10 [N] PHẢI — So sánh dùng `= default` cho `==`/`<=>`; khoá sắp xếp phải có thứ tự toàn phần

- **Vì sao:** `==` viết tay quên trường mới. `= default` so từng thành viên theo thứ tự khai báo
  (không memcmp: đúng với byte đệm và float). Thành viên float cho `<=>` kiểu `std::partial_ordering`;
  NaN làm comparator vi phạm strict weak ordering — với `std::sort`, `std::map` đó là UB (libstdc++
  có thể đọc ra ngoài mảng). "Mọi thành phần nhỏ hơn" không phải thứ tự: hàm có tên như `all_less`
  của types.hpp (API-09).
- **Kiểm:** review; test sắp xếp với dữ liệu có NaN chạy dưới ASan.

```cpp
// ✓ Khoá ô túi đồ chỉ gồm số nguyên: <=> mặc định cho thứ tự từ điển (bag rồi slot).
#include <compare>
#include <cstdint>

namespace game::inv {

struct SlotKey {
    std::uint8_t bag = 0;
    std::uint8_t slot = 0;

    friend constexpr std::strong_ordering operator<=>(const SlotKey&, const SlotKey&) = default;
};

static_assert(SlotKey{.bag = 1, .slot = 0} > SlotKey{.bag = 0, .slot = 9});

} // namespace game::inv
```

## 2. Nâng cao [C]

### KG-11 [C] PHẢI — "Có thể không có" là `std::optional<T>`; giá trị canh chỉ trong định dạng lưu

Canh (0, −1, `UINT32_MAX`) chỉ khi schema DB/giao thức quy định; khi đó đặt tên hằng và đổi sang
`optional` ngay ở ranh giới đọc/ghi.

- **Vì sao:** −1 trong `std::uint32_t` là 4294967295 — trùng ID thật khi bảng lớn; quên kiểm canh thì
  dùng nó như giá trị thật. `optional` buộc nơi gọi xử lý vắng mặt. Đánh đổi:
  `sizeof(std::optional<std::uint32_t>) == 8`; mảng lớn trên đường nóng thì canh bên trong kiểu mạnh
  rẻ hơn — quyết theo số đo (refs/10-bo-nho-cache-dod.md).
- **Kiểm:** clang-tidy `bugprone-unchecked-optional-access` (`*opt` không kiểm là UB).

```cpp
// ✓ guild_id = 0 nghĩa là "không bang" theo schema; trong code là optional.
#include <cstdint>
#include <optional>

namespace game::db {

inline constexpr std::uint32_t kNoGuildInDb = 0;

[[nodiscard]] constexpr std::optional<std::uint32_t> guild_from_db(std::uint32_t raw) noexcept {
    if (raw == kNoGuildInDb) return std::nullopt;
    return raw;
}

[[nodiscard]] constexpr std::uint32_t guild_to_db(std::optional<std::uint32_t> guild) noexcept {
    return guild.value_or(kNoGuildInDb);
}

} // namespace game::db
```

### KG-12 [C] NÊN — Tập kiểu đóng là `std::variant` + `std::visit`; hàm từng kiểu mang tên khác hàm tổng

Tập mở (plugin, script) mới dùng `virtual` (API-11). Không enum + union tay.

- **Vì sao:** enum + union tay: quên cập nhật nhãn là đọc nhầm thành viên (UB). Cây `virtual` cho tập
  đóng tốn một cấp phát và một lời gọi gián tiếp mỗi lệnh; `variant` nằm trên ngăn xếp, sao chép tầm
  thường khi mọi kiểu đều vậy, thiếu nạp chồng là lỗi biên dịch. Bẫy: nếu hàm từng kiểu trùng tên hàm
  nhận variant, kiểu thiếu nạp chồng chuyển ngầm sang variant và gọi lại chính nó — đệ quy vô hạn.
- **Kiểm:** clang-tidy `bugprone-tagged-union-member-count` (union tay còn sót).

```cpp
// ✓ Thêm kiểu vào Command mà thiếu cost_of tương ứng là lỗi biên dịch.
#include <cstdint>
#include <variant>

namespace game::sim {

struct Move {
    float dx = 0.0F;
    float dy = 0.0F;
};

struct CastSkill {
    std::uint16_t skill_id = 0;
};

using Command = std::variant<Move, CastSkill>;

[[nodiscard]] constexpr std::int32_t cost_of(Move /*move*/) noexcept {
    return 1;
}

[[nodiscard]] constexpr std::int32_t cost_of(CastSkill cast) noexcept {
    return cast.skill_id >= 1000 ? 3 : 2;
}

[[nodiscard]] constexpr std::int32_t action_cost(const Command& command) {
    return std::visit([](const auto& one) { return cost_of(one); }, command);
}

} // namespace game::sim
```

### KG-13 [C] NÊN — Kiểu mà bỏ qua là sai thì gắn `[[nodiscard("lý do")]]` ở mức kiểu

Áp cho struct/enum kết quả (vé, trạng thái, mã lỗi). Guard RAII có tác dụng phụ: gắn
`[[nodiscard]]` lên constructor (C++20) để bắt `ScopedTimer{"tick"};` bị huỷ ngay cuối câu lệnh.

- **Vì sao:** thuộc tính trên kiểu bảo vệ mọi hàm trả kiểu ấy, kể cả hàm viết sau và quên
  `[[nodiscard]]`. Guard tạm thời không tên đo được 0 ns, hoặc nhả khoá ngay.
- **Kiểm:** đã đo — GCC báo `-Wunused-result`, Clang báo `-Wunused-value` (cả hai mặc định bật);
  clang-tidy `bugprone-unused-raii`, `bugprone-unused-return-value`.

```cpp
// ✓ Kết quả xếp hàng ghi DB không được bỏ qua ở bất kỳ nơi gọi nào.
#include <cstdint>

namespace game::db {

enum class [[nodiscard("hàng đợi ghi đầy thì phải báo người chơi")]] SaveStatus : std::uint8_t {
    kQueued,
    kRejectedFull,
};

[[nodiscard]] constexpr SaveStatus enqueue_save(std::uint32_t pending) noexcept {
    return pending < 4096 ? SaveStatus::kQueued : SaveStatus::kRejectedFull;
}

} // namespace game::db
```

## 3. Thần thoại [T]

### KG-14 [T] NÊN — Kiểu có miền: constructor `consteval` cho hằng, factory kiểm cho giá trị chạy

Hằng trong code (opcode, id bảng thiết kế) qua constructor `consteval` có `core::check`: sai miền là
lỗi BIÊN DỊCH. Giá trị mạng qua `from_wire` trả `optional`. Constructor không kiểm che bằng thẻ
private.

- **Vì sao:** `core::check` constexpr nhưng nhánh lỗi gọi hàm không constexpr, nên trong hàm
  `consteval` điều kiện sai làm biểu thức hết là hằng → trình dịch từ chối (mẫu ✗ dưới: cả ba trình
  dịch từ chối, đã kiểm). Đã đo `__cpp_consteval == 202211L` (P2564: consteval leo thang qua hàm
  constexpr) trên GCC 14, GCC 15, Clang 20. Không macro, không chi phí chạy.
- **Kiểm:** mẫu `[không biên dịch]` trong test (refs/15-kiem-thu.md); review constructor public.

```cpp
// ✓ Opcode 12 bit: hằng kiểm lúc biên dịch, giá trị mạng kiểm lúc chạy.
#include "core/check.hpp"

#include <cstdint>
#include <optional>

namespace game::proto {

class Opcode {
public:
    // 4 bit cao của trường opcode dành cho cờ nén/mã hoá.
    static constexpr std::uint16_t kMax = 0x0FFF;

    consteval explicit Opcode(std::uint16_t value) noexcept : value_(value) {
        core::check(value <= kMax, "Opcode: vượt 12 bit");
    }

    [[nodiscard]] static constexpr std::optional<Opcode> from_wire(std::uint16_t raw) noexcept {
        if (raw > kMax) return std::nullopt;
        return Opcode(Unchecked{}, raw);
    }

    [[nodiscard]] constexpr std::uint16_t value() const noexcept { return value_; }

private:
    struct Unchecked {};
    constexpr Opcode(Unchecked /*tag*/, std::uint16_t value) noexcept : value_(value) {}

    std::uint16_t value_ = 0;
};

inline constexpr Opcode kMoveRequest{0x0101};

} // namespace game::proto
```

```cpp
// ✗ [không biên dịch] 0x2000 vượt 12 bit: bị từ chối khi biên dịch, không đợi tới lúc chạy.
#include "core/check.hpp"

#include <cstdint>

struct Opcode {
    consteval explicit Opcode(std::uint16_t value) : value_(value) {
        game::core::check(value <= 0x0FFF, "Opcode: vượt 12 bit");
    }
    std::uint16_t value_;
};

inline constexpr Opcode kBad{0x2000};
```

### KG-15 [T] CÓ THỂ — Type-state: trạng thái nằm trong kiểu, chuyển trạng thái tiêu thụ đối tượng cũ

Mỗi trạng thái quan trọng (phiên chờ xác thực / đã xác thực) là một kiểu; thao tác chỉ có trên kiểu
hợp lệ. Hàm chuyển có ref-qualifier `&&`, chuyển tài nguyên sang kiểu mới và là đường duy nhất tạo
kiểu mới.

- **Vì sao:** "lệnh game trước khi xác thực" không còn là `if (state != kAuthed)` phải nhớ ở mọi
  handler mà là lỗi biên dịch. C++ không có kiểu affine như Rust: `&&` buộc nơi gọi viết
  `std::move(pending)`, và `bugprone-use-after-move` bắt mọi lần dùng tên cũ sau đó — phần "tiêu
  thụ" kiểm được trong CI. Hợp với vài trạng thái ít đổi; nhiều trạng thái dùng enum + bảng
  (refs/02-code-phang.md).
- **Kiểm:** clang-tidy `bugprone-use-after-move`.

```cpp
// ✓ Chỉ PendingSession::authenticate tạo được AuthedSession; tên đăng nhập được chuyển, không chép.
#include <cstdint>
#include <optional>
#include <string>
#include <utility>

namespace game::net {

class AuthedSession {
public:
    [[nodiscard]] const std::string& login() const noexcept { return login_; }

private:
    friend class PendingSession;
    explicit AuthedSession(std::string login) noexcept : login_(std::move(login)) {}

    std::string login_;
};

class PendingSession {
public:
    PendingSession(std::string login, std::uint32_t expected) noexcept
        : login_(std::move(login)), expected_(expected) {}

    [[nodiscard]] std::optional<AuthedSession> authenticate(std::uint32_t answer) && noexcept {
        if (answer != expected_) return std::nullopt;
        return AuthedSession(std::move(login_));
    }

private:
    std::string login_;
    std::uint32_t expected_ = 0;
};

} // namespace game::net
```

### KG-16 [T] CÓ THỂ — Số nguyên mạnh không bất biến là `enum class Id : std::uint32_t {}`

Tạo bằng `Id{n}`, lấy số bằng `std::to_underlying`. Dùng khi không cần hàm thành viên hay miền (cần
thì KG-08, KG-14).

- **Vì sao:** (1) `Id{n}` hợp lệ từ C++17 (P0138), là list-init nên thu hẹp bị từ chối (`Id{-1}` lỗi);
  `Id x = 5;` lỗi. (2) `==`, `<` có sẵn giữa cùng kiểu; `id + 1` lỗi. (3) `std::hash` có sẵn cho mọi
  enum: làm khoá unordered không viết gì. (4) Kiểu vô hướng: sao chép tầm thường, implicit-lifetime,
  làm NTTP được, `std::atomic<Id>` lock-free. (5) ABI: giá trị trả về vô hướng luôn nằm trong thanh
  ghi; trên MSVC x64, struct có constructor do người dùng viết (hay thành viên private) bị trả qua con
  trỏ ẩn thay vì RAX (quy tắc kiểu POD của ABI, theo tài liệu "x64 calling convention") — enum không
  bao giờ bị.
- **Kiểm:** `static_assert` cỡ và `std::is_trivially_copyable_v`.

```cpp
// ✓ ZoneId 2 byte: khoá unordered_set không cần hash viết tay, làm tham số template được.
#include <cstdint>
#include <type_traits>
#include <unordered_set>
#include <utility>

namespace game::world {

enum class ZoneId : std::uint16_t {};

inline constexpr ZoneId kCapital{1};

[[nodiscard]] constexpr ZoneId next_zone(ZoneId zone) noexcept {
    return ZoneId{static_cast<std::uint16_t>(std::to_underlying(zone) + 1U)};
}

template <ZoneId Zone>
// NOLINTNEXTLINE(modernize-avoid-c-style-cast): clang-tidy 23 báo nhầm phép so NTTP (BD-19).
inline constexpr bool kIsCapital = Zone == kCapital;

[[nodiscard]] inline bool visited(const std::unordered_set<ZoneId>& seen, ZoneId zone) {
    return seen.contains(zone);
}

static_assert(sizeof(ZoneId) == 2 && std::is_trivially_copyable_v<ZoneId>);
static_assert(kCapital < next_zone(kCapital) && kIsCapital<ZoneId{1}>);

} // namespace game::world
```

### KG-17 [T] PHẢI — Struct lưu/mạng chốt bố cục bằng `static_assert`; không bit-field, không đệm ngầm

Bản ghi đọc/ghi nguyên khối (replay, snapshot): sao chép tầm thường, standard layout,
`std::has_unique_object_representations_v`, `sizeof`/`offsetof` cố định, endian chốt. Đệm cần thiết
là trường `reserved` tường minh, luôn 0.

- **Vì sao:** byte đệm có giá trị không xác định: hash snapshot lệch giữa hai lần chạy cùng trạng
  thái, và lộ bộ nhớ. Bit-field có bố cục do triển khai định; MSVC mở đơn vị cấp phát mới khi cỡ kiểu
  khai báo của bit-field đổi, GCC/Clang SysV thì không — cùng struct khác `sizeof`. Float có hai
  biểu diễn cho cùng giá trị (+0/−0) nên trait trên trả false: lưu toạ độ fixed-point. Aggregate như dưới là implicit-lifetime;
  cách lấy đối tượng từ byte: SH-14. `std::is_implicit_lifetime` (C++23) đã đo chỉ có ở libc++ 20.
- **Kiểm:** các `static_assert` dưới; test golden từng byte (refs/15-kiem-thu.md).

```cpp
// ✓ Bản ghi vị trí trong tệp replay: 16 byte, little-endian; đổi bố cục là đổi phiên bản tệp.
#include <bit>
#include <cstddef>
#include <cstdint>
#include <type_traits>

namespace game::proto {

struct PositionRecord {
    std::uint32_t entity = 0;
    std::uint32_t tick = 0;
    std::int32_t x_cm = 0;
    std::int16_t z_cm = 0;
    // Bit 0 đang bay, bit 1 đã chết: đọc ghi bằng mặt nạ, không bit-field.
    std::uint8_t flags = 0;
    // Đệm tường minh, luôn 0.
    std::uint8_t reserved = 0;
};

static_assert(std::is_trivially_copyable_v<PositionRecord>);
static_assert(std::is_standard_layout_v<PositionRecord>);
static_assert(std::has_unique_object_representations_v<PositionRecord>);
static_assert(sizeof(PositionRecord) == 16 && offsetof(PositionRecord, z_cm) == 12);
static_assert(std::endian::native == std::endian::little, "memcpy nguyên khối giả định LE");

} // namespace game::proto
```

### KG-18 [T] CÓ THỂ — `std::float16_t` chỉ để LƯU, sau guard `__STDCPP_FLOAT16_T__`; tính ở `float`

- **Vì sao:** nửa băng thông cho dữ liệu chịu sai số (trọng số hoạt hình). Đã đo: `std::float16_t`
  chỉ có với GCC (14, 15); libc++ 20 không có `<stdfloat>`, và Clang 20 không định nghĩa
  `__STDCPP_FLOAT16_T__` kể cả khi dùng libstdc++ — không guard thì clangd/clang-tidy báo lỗi trên mã
  GCC hợp lệ. Code khả chuyển dùng `Half` của types.hpp. GCC báo `-Wnarrowing` khi chuyển ngầm
  `float → std::float16_t` (P1467: kiểu hạng thấp hơn). Codegen GCC 14: `-march=x86-64-v2` mỗi
  chuyển đổi là lời gọi libgcc `__truncsfhf2`/`__extendhfsf2`; `x86-64-v3` (F16C) là một lệnh
  `vcvtps2ph`/`vcvtph2ps`. Phép toán trên float16_t được tính ở float rồi làm tròn, còn với
  AVX512-FP16 là lệnh half thật: chuỗi phép tính không tất định giữa bản build.
- **Kiểm:** `-Wnarrowing` (GCC); test vét cạn round-trip 2^16 giá trị (refs/15-kiem-thu.md).

```cpp
// ✓ [g14+g15] Trọng số lưu half; mọi phép tính đổi sang float tường minh.
#if defined(__STDCPP_FLOAT16_T__)
#include <stdfloat>

namespace game::anim {

struct PackedWeight {
    std::float16_t value = 0.0F16;
};

[[nodiscard]] inline PackedWeight pack(float weight) noexcept {
    return {.value = static_cast<std::float16_t>(weight)};
}

[[nodiscard]] inline float scaled(PackedWeight weight, float factor) noexcept {
    return static_cast<float>(weight.value) * factor;
}

} // namespace game::anim
#endif
```

## Kiểm nhanh

- [ ] Biến không gán lại là `const`, hằng `constexpr`, `auto` chỉ khi kiểu đã hiện ở vế phải? (KG-01)
- [ ] Mọi thành viên có default member initializer; aggregate tạo bằng designated initializer? (KG-02)
- [ ] Kiểu số khớp vai trò: cỡ cố định cho dữ liệu lưu, `size_t` cho chỉ số, int64 cho tiền, không `long`? (KG-03)
- [ ] Mọi chuyển đổi hẹp đã chứng minh miền, qua `narrow`, hoặc qua `std::in_range` với dữ liệu client? (KG-04)
- [ ] Không còn `(T)x`, `T(x)`, union punning, `reinterpret_cast` đọc đối tượng? (KG-05)
- [ ] Enum là `enum class` có kiểu nền; số từ mạng kiểm miền trước `static_cast`? (KG-06)
- [ ] Không tham số `bool` làm cờ hành vi? (KG-07)
- [ ] Mỗi loại ID, mỗi đại lượng có đơn vị là kiểu riêng? (KG-08, KG-09, KG-16)
- [ ] So sánh dùng `= default`; không khoá sắp xếp chứa float? (KG-10)
- [ ] Vắng mặt là `optional`; canh chỉ trong schema và đổi ở ranh giới? (KG-11)
- [ ] Struct lưu/mạng có đủ `static_assert` bố cục, không bit-field, không float? (KG-17)
