# GN · Generic và tính toán lúc biên dịch

> **Phạm vi:** template, concept và subsumption, `if constexpr`, nạp chồng thay chuyên biệt hoá,
> `constexpr`/`consteval`/`if consteval`, CTAD, pack và fold, NTTP kiểu lớp, deducing this trong code
> generic, chi phí biên dịch, ODR của template. **Đọc khi:** viết `template`, `concept`, `requires`,
> `auto` ở tham số; một hàm cho nhiều kiểu; bảng hay hash lúc biên dịch; lỗi "constraints not
> satisfied", "ambiguous", "not a constant expression"; build chậm vì header generic; thêm macro
> cấu hình làm đổi thân hàm inline.
> **Liên quan:** refs/03-kieu-gia-tri.md (KG-14, KG-18), refs/06-ham-lop-api.md (API),
> refs/08-thu-vien-chuan-cpp23.md (STD), refs/13-ub-on-dinh.md (UB), refs/14-build-toolchain.md (BD),
> refs/15-kiem-thu.md (KT).

"Đo" trong file này: GCC 14.2, GCC 15.2, Clang 20.1 + libc++ 20, `-std=c++23`, trên máy kiểm.

## 1. Nền tảng [N]

### GN-01 [N] PHẢI — Mọi tham số kiểu của template bị ràng buộc bằng concept; CẤM `enable_if`/SFINAE mới

Ràng buộc bằng concept chuẩn (`std::integral`, `std::invocable<F, A...>`, `std::ranges::input_range`…)
hoặc concept có tên của dự án; kiểu chỉ dùng một lần thì viết rút gọn `std::integral auto x`. Không
`std::enable_if`, `std::void_t`, `decltype(…, void())`. Chỉ viết template khi đã có ít nhất hai kiểu
dùng thật — một kiểu thì hàm/lớp thường (cài đặt nằm trong .cpp được, build nhanh hơn).

- **Vì sao:** gọi sai thì lỗi nằm ở chỗ gọi và nêu đúng concept không thoả; SFINAE chỉ báo "no
  matching function". Concept tham gia xếp hạng nạp chồng (GN-09); hai template chỉ khác đối số mặc
  định của `enable_if` là khai báo lại CÙNG một template — lỗi.
- **Kiểm:** clang-tidy `modernize-use-constraints` (bắt `enable_if`), `modernize-type-traits`.
- **Ngoại lệ:** template trong `detail` chỉ được gọi từ hàm đã ràng buộc (như `detail::map(…, Op op)`
  của soa.hpp) được để `class Op` trần.

```cpp
// ✓ Concept chuẩn trên tham số; static_assert chứng minh khởi tạo được (GN-05).
#include <concepts>
#include <cstdint>

namespace game::inv {

// Số vật phẩm nhận vào một ô: không vượt max_stack.
template <std::integral T>
[[nodiscard]] constexpr T clamp_stack(T requested, T max_stack) noexcept {
    return requested < max_stack ? requested : max_stack;
}

[[nodiscard]] constexpr bool is_empty_slot(std::unsigned_integral auto count) noexcept {
    return count == 0U;
}

static_assert(clamp_stack(std::uint16_t{250}, std::uint16_t{99}) == 99 && is_empty_slot(0U));

} // namespace game::inv
```

### GN-02 [N] PHẢI — Rẽ nhánh theo kiểu là một chuỗi `if constexpr` kết thúc bằng `static_assert(false, "…")`

Một chuỗi `if constexpr … else if constexpr …`, nhánh cuối `else { static_assert(false, "…");
}`. Từ 5 nhánh xử lý (không kể nhánh `static_assert` cuối) hoặc nhánh dài
thì chuyển sang nạp chồng (GN-03). Mọi
`static_assert` trong template có thông điệp nói vì sao và sửa thế nào (trình dịch đã in biểu thức).

- **Vì sao:** thiếu nhánh cuối thì kiểu mới rơi im lặng vào nhánh "còn lại" sai (vd. `else` viết cho
  float nhận luôn double và cắt nó thành float). `static_assert(false)` trong nhánh bị loại bỏ hợp lệ
  trong C++23 (P2593, chấp nhận như DR nên trình dịch nhận cả ở chế độ cũ hơn; đo: cả ba nhận) — bỏ
  mẹo `dependent_false<T>`.
- **Kiểm:** review nhánh cuối.

```cpp
// ✓ Trường gói tin → u64 cho varint; nhánh cuối chặn ai mở rộng concept mà quên thêm nhánh.
#include <bit>
#include <concepts>
#include <cstdint>

namespace game::proto {

template <class T>
concept WireScalar = std::integral<T> || std::same_as<T, float>;

template <WireScalar T>
[[nodiscard]] constexpr std::uint64_t encode_field(T value) noexcept {
    // bool trước: std::unsigned_integral<bool> cũng đúng.
    if constexpr (std::same_as<T, bool>) {
        return value ? 1U : 0U;
    } else if constexpr (std::unsigned_integral<T>) {
        return value;
    } else if constexpr (std::signed_integral<T>) {
        // zigzag: -1 → 1, 1 → 2; dịch phải số có dấu là dịch số học từ C++20.
        const auto wide = static_cast<std::int64_t>(value);
        return (static_cast<std::uint64_t>(wide) << 1U) ^ static_cast<std::uint64_t>(wide >> 63);
    } else if constexpr (std::same_as<T, float>) {
        return std::bit_cast<std::uint32_t>(value);
    } else {
        static_assert(false, "encode_field: WireScalar có kiểu chưa có nhánh — thêm nhánh");
    }
}

static_assert(encode_field(true) == 1U && encode_field(-1) == 1U && encode_field(1) == 2U);

} // namespace game::proto
```

### GN-03 [N] CẤM — Chuyên biệt hoá tường minh hàm template; tuỳ biến theo kiểu bằng nạp chồng

Bản riêng cho một kiểu là hàm thường (hoặc template ràng buộc hẹp hơn) cùng tên, cùng namespace với
kiểu. Không `template <> R f<X>(…)`.

- **Vì sao:** chuyên biệt hoá không dự phân giải nạp chồng: trình dịch chọn template chính rồi mới xét
  chuyên biệt hoá của NÓ, nên thêm một nạp chồng template khác có thể làm chuyên biệt hoá bị bỏ qua. TU
  nào không thấy chuyên biệt hoá trước lần dùng đầu sẽ khởi tạo bản chính → hai định nghĩa khác nhau
  (ill-formed NDR). Hàm thường thắng template khi khớp như nhau và được ADL tìm thấy.
- **Kiểm:** review `template <>` đứng trước khai báo hàm.
- **Ngoại lệ:** điểm tuỳ biến của thư viện chuẩn là LỚP template: `std::formatter`, `std::hash` (STD-18).

```cpp
// ✓ Kích thước trên dây: bản chung bị ràng buộc + nạp chồng thường cho chuỗi.
#include <concepts>
#include <cstdint>
#include <string_view>

namespace game::proto {

template <class T>
concept FixedWire = std::integral<T> || std::floating_point<T>;

template <FixedWire T>
[[nodiscard]] constexpr std::uint32_t wire_size(T /*value*/) noexcept {
    return sizeof(T);
}

// Tiền tố độ dài 2 byte + nội dung. Hợp đồng: text.size() <= 65535, writer kiểm.
[[nodiscard]] constexpr std::uint32_t wire_size(std::string_view text) noexcept {
    return 2U + static_cast<std::uint32_t>(text.size());
}

static_assert(wire_size(std::uint16_t{7}) == 2U && wire_size("move") == 6U);

} // namespace game::proto
```

### GN-04 [N] PHẢI — Giá trị chỉ được phép tính lúc biên dịch dùng `consteval`; hàm dùng ở cả hai thời điểm là `constexpr`

Id thông điệp từ tên, hash chuỗi literal, kiểm literal (KG-14) → `consteval`. Hàm thuần mà code chạy
cũng gọi → `constexpr`.

- **Vì sao:** `constexpr` chỉ BẢO ĐẢM tính lúc biên dịch trong ngữ cảnh hằng (biến `constexpr`,
  `case`, đối số template). `const auto id = message_id(name);` được phép chạy lúc chạy — hash lại ở mỗi
  gói tin — và nếu `name` đến từ client thì id lấy từ dữ liệu không tin cậy. `consteval` buộc MỌI lời
  gọi tính lúc biên dịch; truyền chuỗi lúc chạy vào là lỗi biên dịch.
- **Kiểm:** review hàm hash/id; mẫu `[không biên dịch]` trong test (KT).

```cpp
// ✓ Id thông điệp = FNV-1a 32 bit của tên; không gọi được với chuỗi lúc chạy.
#include <cstdint>
#include <string_view>

namespace game::proto {

[[nodiscard]] consteval std::uint32_t message_id(std::string_view name) noexcept {
    // Hằng FNV-1a 32 bit: offset basis 2166136261, prime 16777619.
    std::uint32_t hash = 2'166'136'261U;
    for (const char letter : name) {
        hash = (hash ^ static_cast<std::uint8_t>(letter)) * 16'777'619U;
    }
    return hash;
}

enum class MessageId : std::uint32_t {
    kMove = message_id("move"),
    kAttack = message_id("attack"),
};

} // namespace game::proto
```

### GN-05 [N] PHẢI — Mỗi hàm `constexpr` được đánh giá hằng ít nhất một lần trong build: `static_assert` cạnh định nghĩa hoặc trong test

`static_assert` gọi hàm với đối số tiêu biểu ngay sau định nghĩa, hoặc trong bảng test của KT-04 (ưu
tiên khi có nhiều ca). Hàm không tính được lúc biên dịch thì bỏ `constexpr`, dùng `inline`. Mẫu ngắn
trong bộ này nhiều chỗ lược phần test; code dự án thì không lược.

- **Vì sao:** C++23 bỏ luật "hàm constexpr không bao giờ cho hằng biểu thức là ill-formed" (P2448,
  `__cpp_constexpr` ≥ 202207L; đo được 202211L): trình dịch im lặng, `constexpr` thành lời nói dối
  chỉ lộ khi ai đó dùng nó trong ngữ cảnh hằng. Bẫy hay gặp: phần `<cmath>` constexpr của C++23 (P0533) chưa thư viện
  nào trong ba cài đủ (`__cpp_lib_constexpr_cmath` vắng); GCC vẫn gấp hằng `std::abs(double)` (C++23)
  và cả `std::sqrt` (constexpr từ C++26, ở đây là phần mở rộng), libc++ 20 từ chối cả hai →
  `static_assert` qua trên GCC, gãy trên Clang. Vì vậy `length()` trong types.hpp là `inline`, còn
  `length_sq()` là `constexpr`.
- **Kiểm:** CI biên dịch cả GCC và Clang + libc++ (BD-12); Clang `-Winvalid-constexpr` (tắt mặc
  định ở C++23, có trong config/warnings-clang.txt) bắt ca lộ liễu như gọi `std::printf` trên mọi đường; GCC 14 không cảnh báo (đo).

```cpp
// ✓ Hằng biểu thức được chứng minh; hàm cần sqrt không giả vờ constexpr.
#include <cmath>

namespace game::math {

struct Float3 {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
};

[[nodiscard]] constexpr float length_sq(Float3 offset) noexcept {
    return (offset.x * offset.x) + (offset.y * offset.y) + (offset.z * offset.z);
}

[[nodiscard]] inline float length(Float3 offset) noexcept {
    return std::sqrt(length_sq(offset));
}

static_assert(length_sq({.x = 1.0F, .y = 2.0F, .z = 2.0F}) == 9.0F);

} // namespace game::math
```

### GN-06 [N] PHẢI — Forwarding reference (`T&&`, `auto&&` suy diễn) chỉ để chuyển tiếp: mỗi tham số `std::forward` đúng một lần

Hàm chỉ đọc nhận `const T&`; hàm "nuốt" một kiểu cụ thể nhận theo giá trị rồi `std::move` (API-01).
`T&&` suy diễn chỉ khi chuyển nguyên trạng tới nơi khác (emplace, factory).

- **Vì sao:** `T&&` với T suy diễn khớp cả lvalue (T thành `U&`); `std::move` trên nó lặng lẽ cướp
  đối tượng của người gọi: sau `outbox.push(packet)` biến `packet` của họ đã rỗng. `std::forward` hai
  lần trên cùng tham số là dùng sau move.
- **Kiểm:** clang-tidy `bugprone-move-forwarding-reference`, `cppcoreguidelines-missing-std-forward`,
  `bugprone-use-after-move`.

```cpp
// ✗ std::move trên forwarding reference: push(lvalue) làm rỗng biến của người gọi.
#include <utility>
#include <vector>

template <class T>
struct Outbox {
    std::vector<T> items;

    template <class U>
    void push(U&& item) {
        items.push_back(std::move(item));
    }
};
```

```cpp
// ✓ Chuyển tiếp đúng một lần; ràng buộc chặn kiểu không dựng được T.
#include <concepts>
#include <utility>
#include <vector>

namespace game::net {

template <class T>
class Outbox {
public:
    template <class... Args>
        requires std::constructible_from<T, Args...>
    T& emplace(Args&&... args) {
        return items_.emplace_back(std::forward<Args>(args)...);
    }

private:
    std::vector<T> items_;
};

} // namespace game::net
```

### GN-07 [N] PHẢI — Tham số callable gọi ngay là template ràng buộc (`std::invocable`, `std::predicate`), không `std::function`

Hàm nhận hàm để gọi NGAY (lọc, duyệt, so sánh): `std::predicate<const T&> auto pred` hoặc
`template <std::invocable<T&> F>`. Callback lưu lại để gọi sau: STD-13, STD-20.

- **Vì sao:** template thấy kiểu thật của lambda → nội tuyến được, không gọi gián tiếp. `std::function`
  xoá kiểu: gọi qua con trỏ và cấp phát heap khi capture vượt bộ đệm trong (đo: libstdc++ 16 byte,
  libc++ 24 byte) — trên đường nóng, mỗi lần dựng `std::function` từ lambda như vậy là một lần cấp phát.
- **Kiểm:** review `std::function` ở tham số; profiler (HN).

```cpp
// ✓ Đếm thực thể thoả điều kiện: vị từ là template, nội tuyến được.
#include <algorithm>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::world {

struct Entity {
    std::uint32_t id = 0;
    std::int32_t hp = 0;
};

template <std::predicate<const Entity&> Predicate>
[[nodiscard]] inline std::ptrdiff_t count_matching(std::span<const Entity> all, Predicate pred) {
    return std::ranges::count_if(all, pred);
}

} // namespace game::world
```

## 2. Nâng cao [C]

### GN-08 [C] PHẢI — Concept mô tả một vai trò có ngữ nghĩa, không một phép toán đơn lẻ

Concept đặt tên theo vai trò (`TickSystem`, `WireMessage`, `SoaVector`), gồm đủ yêu cầu cú pháp mà
thuật toán dùng, ràng buộc kiểu trả (`-> std::same_as<void>`), và comment nêu phần ngữ nghĩa trình dịch
không kiểm được (tất định, độ phức tạp, không cấp phát).

- **Vì sao:** concept chỉ kiểm cú pháp. Concept kiểu `Addable` khớp mọi thứ có `+`: `std::string` vào
  hàm cộng sát thương vẫn biên dịch, thành nối chuỗi. Concept theo vai trò buộc người viết kiểu nghĩ về
  hợp đồng; ràng buộc kiểu trả chặn proxy/kiểu "giống bool".
- **Kiểm:** mỗi concept có `static_assert` một kiểu thoả và một kiểu không thoả.

```cpp
// ✓ Hệ thống chạy mỗi tick: yêu cầu cú pháp + hợp đồng ngữ nghĩa ghi rõ.
#include <concepts>
#include <cstdint>

namespace game::sim {

enum class Phase : std::uint8_t { kInput, kSimulate, kReplicate };

// Mốc: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

struct World;

// update tất định (cùng World, cùng tick → cùng kết quả), không cấp phát, chỉ ghi thành phần của
// mình; kPhase quyết định thứ tự trong tick.
template <class T>
concept TickSystem = requires(T& system, World& world, Tick tick) {
    { T::kPhase } -> std::convertible_to<Phase>;
    { system.update(world, tick) } -> std::same_as<void>;
};

struct RegenSystem {
    static constexpr Phase kPhase = Phase::kSimulate;
    Tick last_tick{};

    void update(World& /*world*/, Tick tick) noexcept { last_tick = tick; }
};

static_assert(TickSystem<RegenSystem> && !TickSystem<int>);

} // namespace game::sim
```

### GN-09 [C] PHẢI — Concept hẹp viết qua concept rộng để subsumption chọn nạp chồng; không ghép trait rời

`concept Hẹp = Rộng<T> && điều_kiện_thêm;` — như `SignedComponent = Component<T> && …` của types.hpp.
Hai nạp chồng cùng tên thì ràng buộc của bản hẹp phải CHỨA nguyên concept của bản rộng.

- **Vì sao:** subsumption so các ràng buộc nguyên tử theo danh tính: cùng biểu thức tại CÙNG vị trí
  trong mã nguồn ([temp.constr.atomic]). `std::is_integral_v<T>` viết ở hai chỗ là hai nguyên tử khác
  nhau → gọi mơ hồ. Concept có tên chuẩn hoá về cùng nguyên tử nên bản hẹp thắng.
- **Kiểm:** biên dịch (lỗi "ambiguous"); review ràng buộc dạng `trait_v && …` trên nạp chồng.

```cpp
// ✗ [không biên dịch] Trait rời: hai nguyên tử khác nhau, gọi với int là mơ hồ.
#include <type_traits>

template <class T>
    requires std::is_integral_v<T>
int stat_bucket(T value) {
    return static_cast<int>(value);
}

template <class T>
    requires std::is_integral_v<T> && std::is_signed_v<T>
int stat_bucket(T value) {
    return value < 0 ? 0 : static_cast<int>(value);
}

int use_bucket() {
    return stat_bucket(-5);
}
```

```cpp
// ✓ Concept hẹp chứa concept rộng: bản có dấu được chọn cho int, bản chung cho unsigned.
#include <concepts>
#include <cstdint>

namespace game::combat {

template <class T>
concept Stat = std::same_as<T, std::int32_t> || std::same_as<T, std::uint32_t>;

template <class T>
concept SignedStat = Stat<T> && std::signed_integral<T>;

template <Stat T>
[[nodiscard]] constexpr std::uint32_t stat_bucket(T value) noexcept {
    return static_cast<std::uint32_t>(value) / 10U;
}

// Chỉ số âm (debuff quá tay) rơi vào ô 0.
template <SignedStat T>
[[nodiscard]] constexpr std::uint32_t stat_bucket(T value) noexcept {
    return value < 0 ? 0U : static_cast<std::uint32_t>(value) / 10U;
}

static_assert(stat_bucket(-5) == 0U && stat_bucket(25U) == 2U);

} // namespace game::combat
```

### GN-10 [C] NÊN — Chỉ dựa vào CTAD khi kiểu suy ra hiển nhiên; container dựng từ dãy ghi rõ kiểu

CTAD hợp với aggregate và kiểu bọc một giá trị (`std::array`, `std::pair`, `Timed{.tick, .payload}`).
Container dựng từ iterator, kích thước hay range: ghi kiểu tường minh hoặc `std::ranges::to`.

- **Vì sao:** `std::vector copy{ids.begin(), ids.end()}` suy ra `vector<iterator>` HAI phần tử (đo: cả
  ba) — biên dịch được, sai hoàn toàn. CTAD từ constructor kế thừa (P2582, C++23) có ở GCC 14/15 nhưng
  KHÔNG có ở Clang 20 (đo); CTAD cho aggregate (kể cả designated initializer) và alias template có ở cả ba.
- **Kiểm:** Clang `-Wctad-maybe-unsupported` (CTAD trên template không có deduction guide); review `{`
  sau tên container thiếu `<…>`.

```cpp
// ✓ Kiểu container ghi rõ qua ranges::to; aggregate dùng CTAD + designated initializer.
#include <cstdint>
#include <ranges>
#include <span>
#include <vector>

namespace game::world {

// Mốc: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

template <class Payload>
struct Timed {
    Tick tick{};
    Payload payload{};
};

struct Damage {
    std::int32_t amount = 0;
};

// Id <= 0 là ô trống trong bảng.
[[nodiscard]] inline std::vector<std::int32_t> valid_ids(std::span<const std::int32_t> ids) {
    const auto is_valid = [](std::int32_t id) { return id > 0; };
    return ids | std::views::filter(is_valid) | std::ranges::to<std::vector>();
}

inline constexpr Timed kFirstHit{.tick = Tick{5}, .payload = Damage{.amount = 3}};

} // namespace game::world
```

### GN-11 [C] PHẢI — Mở pack bằng fold expression hoặc `std::index_sequence`; không đệ quy template theo pack

Thao tác trên từng phần tử: `(f(xs), ...)`; gộp: `(sizeof(Ts) + ... + 0U)`; cần chỉ số: lambda
`[&]<std::size_t... I>(std::index_sequence<I...>) { (g(I, xs), ...); }(std::index_sequence_for<Ts...>{})`.

- **Vì sao:** đệ quy "đầu + phần còn lại" tạo N khởi tạo trung gian (N hàm, N ký hiệu trong object
  file), chạm giới hạn độ sâu (GCC mặc định 900 mức, đo; `-ftemplate-depth`) và chậm biên dịch. Fold là
  MỘT khởi tạo; fold dấu phẩy đánh giá trái sang phải (bảo đảm).
- **Kiểm:** review hàm variadic có nạp chồng "trường hợp cơ sở".

```cpp
// ✓ Ghi các trường vào gói tin bằng fold; tổng kích thước tính lúc biên dịch.
#include <array>
#include <bit>
#include <concepts>
#include <cstddef>
#include <vector>

namespace game::proto {

template <class T>
concept WireInt = std::unsigned_integral<T> && !std::same_as<T, bool>;

static_assert(std::endian::native == std::endian::little, "đích big-endian: thêm std::byteswap");

template <WireInt T>
void put(std::vector<std::byte>& out, T value) {
    const auto bytes = std::bit_cast<std::array<std::byte, sizeof(T)>>(value);
    out.insert(out.end(), bytes.begin(), bytes.end());
}

template <WireInt... Ts>
void put_all(std::vector<std::byte>& out, Ts... fields) {
    out.reserve(out.size() + (sizeof(Ts) + ... + 0U));
    (put(out, fields), ...);
}

} // namespace game::proto
```

### GN-12 [C] NÊN — Bảng tra sinh lúc biên dịch bằng hàm `constexpr` trả `std::array`, có `static_assert` điểm mẫu

Bảng (CRC, EXP theo cấp, hệ số theo độ hiếm) là `inline constexpr std::array` khởi tạo bằng hàm
constexpr; `static_assert` vài phần tử đã biết và một giá trị kiểm tổng thể.

- **Vì sao:** không khởi tạo động lúc khởi động (không thứ tự khởi tạo static, không race), nằm trong
  `.rodata`, sai công thức là lỗi biên dịch. Ngân sách đo được: GCC dừng một vòng lặp hằng sau 262 144
  lần lặp (`-fconstexpr-loop-limit`); Clang dừng sau 1 048 576 bước (`-fconstexpr-steps`; vòng lặp
  đơn giản ~525 000 lần lặp). Bảng từ cỡ 10^5 phần tử: sinh bằng công cụ build hoặc nạp lúc khởi động.
- **Kiểm:** `static_assert` giá trị chuẩn (CRC-32 của "123456789" là `0xCBF43926`).

```cpp
// ✓ Bảng CRC-32 (đa thức phản xạ 0xEDB88320) sinh lúc biên dịch, kiểm bằng giá trị chuẩn.
#include <algorithm>
#include <array>
#include <cstdint>
#include <ranges>
#include <string_view>

namespace game::net {

[[nodiscard]] constexpr std::uint32_t crc_entry(std::uint32_t index) noexcept {
    std::uint32_t crc = index;
    for (int bit = 0; bit < 8; ++bit) {
        crc = (crc >> 1U) ^ (0xEDB8'8320U & (0U - (crc & 1U)));
    }
    return crc;
}

[[nodiscard]] constexpr std::array<std::uint32_t, 256> make_crc_table() noexcept {
    std::array<std::uint32_t, 256> table{};
    std::ranges::transform(std::views::iota(0U, 256U), table.begin(), crc_entry);
    return table;
}

inline constexpr std::array<std::uint32_t, 256> kCrcTable = make_crc_table();

[[nodiscard]] constexpr std::uint32_t crc32(std::string_view bytes) noexcept {
    std::uint32_t crc = 0xFFFF'FFFFU;
    for (const char letter : bytes) {
        const std::uint32_t slot = (crc ^ static_cast<std::uint8_t>(letter)) & 0xFFU;
        // slot < 256 nhờ & 0xFF: luôn nằm trong bảng (GN-12).
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
        crc = (crc >> 8U) ^ kCrcTable[slot];
    }
    return ~crc;
}

static_assert(kCrcTable[1] == 0x7707'3096U && crc32("123456789") == 0xCBF4'3926U);

} // namespace game::net
```

### GN-13 [C] PHẢI — Tham số phụ (dung sai, bước, hệ số) là `std::type_identity_t<T>` để T chỉ suy từ tham số chính

Hàm template có tham số "chính" quyết định `T`: mọi tham số còn lại mang kiểu `std::type_identity_t<T>`.

- **Vì sao:** mọi tham số dùng `T` đều tham gia suy diễn: `approach(speed, 10.0F, 0.5)` cho T = float
  từ hai tham số đầu và T = double từ tham số cuối → lỗi "deduced conflicting types". `type_identity_t`
  đưa tham số vào ngữ cảnh không suy diễn: T lấy từ tham số chính, đối số phụ chuyển đổi bình thường
  (`-Wconversion` vẫn canh). Đúng như `near(a, b, tolerance)` của types.hpp.
- **Kiểm:** biên dịch.

```cpp
// ✓ max_step không tham gia suy diễn; gọi với literal double vẫn được.
#include <concepts>
#include <type_traits>

namespace game::sim {

// Tiến current về target, mỗi lần không quá max_step (>= 0); chỉ đi lên.
template <std::floating_point T>
[[nodiscard]] constexpr T approach(T current, T target, std::type_identity_t<T> max_step) noexcept {
    return current + max_step < target ? current + max_step : target;
}

static_assert(approach(9.8F, 10.0F, 0.5) == 10.0F);

} // namespace game::sim
```

### GN-14 [C] NÊN — Tên và khoá cố định là NTTP kiểu lớp (`FixedString`); kiểm trùng id lúc biên dịch

Thông điệp, kênh log, khoá cấu hình biết lúc biên dịch: `Message<"move">` thay vì chuỗi lúc chạy. Id
tính bằng `consteval` (GN-04); danh sách mọi id được `static_assert` không trùng.

- **Vì sao:** gõ sai tên là lỗi biên dịch, id là hằng, không tra map lúc chạy. Hash 32 bit có thể va
  chạm: kiểm trùng lúc biên dịch biến va chạm thành lỗi build thay vì gói tin định tuyến nhầm. NTTP
  kiểu lớp chạy trên cả ba (Clang 20 báo `__cpp_nontype_template_args` 201411L mà vẫn nhận mẫu dưới —
  đừng dựa vào macro này).
- **Kiểm:** `static_assert(all_unique(...))` trong header đăng ký thông điệp.

```cpp
// ✓ FixedString làm NTTP; id thông điệp tính và kiểm trùng lúc biên dịch.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <string_view>

namespace game::proto {

template <std::size_t N>
struct FixedString {
    std::array<char, N + 1> chars{};

    // Literal chuỗi là mảng C; constructor ngầm định để viết Message<"move"> (lệch API-04, GN-14).
    // NOLINTNEXTLINE(*-avoid-c-arrays,*-explicit-constructor)
    consteval FixedString(const char (&text)[N + 1]) noexcept : chars(std::to_array(text)) {}
    [[nodiscard]] constexpr std::string_view view() const noexcept { return {chars.data(), N}; }
};

// Deduction guide nhận literal chuỗi, cùng lý do (GN-14).
template <std::size_t N>
// NOLINTNEXTLINE(*-avoid-c-arrays)
FixedString(const char (&)[N]) -> FixedString<N - 1>;

[[nodiscard]] consteval std::uint32_t fnv1a(std::string_view name) noexcept {
    std::uint32_t hash = 2'166'136'261U;
    for (const char letter : name) {
        hash = (hash ^ static_cast<std::uint8_t>(letter)) * 16'777'619U;
    }
    return hash;
}

template <FixedString Name>
struct Message {
    static constexpr std::uint32_t kId = fnv1a(Name.view());
};

template <std::size_t N>
[[nodiscard]] consteval bool all_unique(std::array<std::uint32_t, N> ids) {
    std::ranges::sort(ids);
    return std::ranges::adjacent_find(ids) == ids.end();
}

static_assert(all_unique(std::array{Message<"move">::kId, Message<"attack">::kId}),
    "trùng id thông điệp: đổi tên một thông điệp");

} // namespace game::proto
```

### GN-15 [C] NÊN — Deducing this thay các bản const/không const/rvalue của cùng hàm thành viên; không `this auto self`

`template <class Self> auto&& f(this Self&& self)` + `std::forward_like<Self>(self.member_)` thay 2–4
nạp chồng chép tay. Mixin thay CRTP: API-13.

- **Vì sao:** một thân thay bốn, không lệch nhau khi sửa. Bẫy: `this auto self` nhận THEO GIÁ TRỊ —
  mỗi lời gọi chép cả đối tượng (túi đồ vài KB); `Self` có thể là lớp dẫn xuất nên `self.slots_` có thể
  bị thành viên trùng tên của lớp con che; hàm thành template → ở header, không `virtual` được.
  `std::forward_like` có trên cả ba thư viện (đo).
- **Kiểm:** review `this auto ` thiếu `&` (tidy `performance-unnecessary-value-param` không bắt). tidy
  20 `cppcoreguidelines-missing-std-forward` báo nhầm khi chỉ `forward_like` thành viên → NOLINT có lý do.

```cpp
// ✓ Một hàm truy cập cho mọi kiểu tham chiếu của đối tượng; kiểm biên luôn bật.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

namespace game::inv {

struct ItemStack {
    std::uint32_t item_id = 0;
    std::uint16_t count = 0;
};

class Bag {
public:
    template <class Self>
    // clang-tidy 20 báo nhầm khi chỉ chuyển tiếp bằng forward_like (BD-19).
    // NOLINTNEXTLINE(cppcoreguidelines-missing-std-forward)
    [[nodiscard]] auto&& slot(this Self&& self, std::size_t index) noexcept {
        core::check(index < self.slots_.size(), "Bag::slot: chỉ số ngoài túi");
        return std::forward_like<Self>(self.slots_[index]);
    }

private:
    std::vector<ItemStack> slots_;
};

} // namespace game::inv
```

## 3. Thần thoại [T]

### GN-16 [T] PHẢI — Đo thời gian biên dịch trước khi thêm tầng generic; template nặng dùng ở nhiều TU thì `extern template` cho thành viên định nghĩa NGOÀI lớp

Một template lớn khởi tạo ở 50 TU là 50 lần phân tích và sinh mã, rồi linker vứt 49 bản. Quy trình:
đo (Clang `-ftime-trace`; GCC `-ftime-report` — GCC 14 KHÔNG có `-ftime-trace`, đo) → tìm template
tốn nhất → (1) tách phần không phụ thuộc `T` ra hàm thường trong .cpp; (2) thành viên nặng định nghĩa
ngoài lớp, không `inline`; (3) header khai `extern template class X<A>;`, đúng một .cpp có
`template class X<A>;`.

- **Vì sao:** `extern template` KHÔNG chặn khởi tạo hàm inline, hàm có kiểu trả suy diễn, biến
  constexpr ([temp.explicit]): thân viết trong lớp là inline ngầm, vẫn bị khởi tạo ở mọi TU để nội
  tuyến. Lợi ích chỉ đến từ thành viên ngoài lớp. Không đo thì dễ thêm `extern template` mà build không
  nhanh hơn giây nào.
- **Kiểm:** `-ftime-trace` (JSON mỗi TU, mở bằng Perfetto) trước/sau; `.ninja_log` (BD-15).

```cpp
// ✓ Header: rebuild_index nặng định nghĩa ngoài lớp; mọi TU dùng bản khởi tạo ở pool.cpp.
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::world {

struct Monster {
    std::uint32_t id = 0;
};

template <class T>
class Pool {
public:
    [[nodiscard]] std::size_t size() const noexcept { return items_.size(); }
    void rebuild_index();

private:
    std::vector<T> items_;
    std::vector<std::uint32_t> index_;
};

template <class T>
void Pool<T>::rebuild_index() {
    index_.assign(items_.size(), 0U);
}

// pool.cpp có đúng một dòng: template class Pool<Monster>;
extern template class Pool<Monster>;

} // namespace game::world
```

### GN-17 [T] PHẢI — Template số học được `static_assert` tại ca biên với MỌI kiểu trong concept: đánh giá hằng là máy dò UB

Với mỗi kiểu concept cho phép, gọi hàm ở ca biên (min, max, 0, −1, trung gian lớn nhất) trong
`static_assert`. UB trong đánh giá hằng là lỗi biên dịch, nên tràn nằm im lúc chạy lộ ra ngay. Chính
sách UB đầy đủ: refs/13-ub-on-dinh.md (UB-16).

- **Vì sao:** test runtime với giá trị "bình thường" không chạm tràn; sanitizer chỉ thấy đường đã chạy.
  Đánh giá hằng bắt hầu hết UB lõi ngôn ngữ trên mọi trình dịch mà không cần chạy (bảng đo dưới).
  Giới hạn: không thấy tranh chấp dữ liệu, aliasing, UB thư viện ngoài phần được kiểm.
- **Kiểm:** CI biên dịch cả GCC và Clang (BD-12); KT cho test sai phân lúc chạy.

#### Bảng: UB trong `static_assert` (đo)

| UB | GCC 14 | GCC 15 | Clang 20 |
|---|---|---|---|
| tràn số có dấu, `INT_MIN / -1`, `std::abs(INT_MIN)` | bắt | bắt | bắt |
| dịch ≥ độ rộng (`1 << 33`, `u32 << 32U`) | bắt | bắt | bắt |
| ngoài biên mảng C, `std::array`, `std::vector` | bắt | bắt | bắt |
| đọc chưa khởi tạo, dùng sau `delete`, iterator mất hiệu lực sau `push_back` | bắt | bắt | bắt |
| float → int ngoài miền (`int(1e30F)`) | bắt | bắt | bắt |
| tạo con trỏ vượt `end + 1` (không đọc) | bỏ lọt | bỏ lọt | bắt |
| `-1 << 1` (KHÔNG còn là UB từ C++20) | nhận | nhận | nhận |

```cpp
// ✓ Phần trăm sát thương: trung gian 64 bit; static_assert ở biên cho từng kiểu của concept.
#include <algorithm>
#include <concepts>
#include <cstdint>
#include <limits>

namespace game::combat {

template <class T>
concept DamageInt = std::same_as<T, std::int32_t> || std::same_as<T, std::int16_t>;

// base * percent / 100, cắt về miền của T. percent trong [0, 1000].
template <DamageInt T>
[[nodiscard]] constexpr T scale_damage(T base, std::int32_t percent) noexcept {
    constexpr std::int64_t kTop = std::numeric_limits<T>::max();
    constexpr std::int64_t kBottom = std::numeric_limits<T>::min();
    const std::int64_t wide = static_cast<std::int64_t>(base) * percent / 100;
    return static_cast<T>(std::clamp(wide, kBottom, kTop));
}

template <DamageInt T>
[[nodiscard]] consteval bool scale_edges_ok() {
    constexpr T kMax = std::numeric_limits<T>::max();
    constexpr T kMin = std::numeric_limits<T>::min();
    return scale_damage(kMax, 1000) == kMax && scale_damage(kMin, 1000) == kMin && scale_damage(T{-1}, 50) == T{0};
}

static_assert(scale_edges_ok<std::int32_t>() && scale_edges_ok<std::int16_t>());

} // namespace game::combat
```

### GN-18 [T] PHẢI — Tính toán trên kiểu bằng giá trị (mảng constexpr + thuật toán), không đệ quy N mức; pack indexing là C++26

Tìm chỉ số của kiểu trong pack, đếm, kiểm trùng: dựng `std::array<bool, sizeof...(Ts)>` từ pack rồi
dùng `std::ranges::find`/`count`. Lấy kiểu thứ I: `std::tuple_element_t<I, std::tuple<Ts...>>`.

- **Vì sao:** metaprogramming đệ quy kiểu C++11 (`IndexOf<T, Head, Tail...>`) tạo O(N) khởi tạo lớp cho
  MỖI truy vấn, O(N²) cho cả bảng, và lỗi sâu N tầng. Mở pack thành mảng là một khởi tạo; thuật toán
  chạy trong bộ đánh giá hằng, rẻ. Cả ba trình dịch có builtin `__type_pack_element` (đo
  `__has_builtin`) cho thư viện cài `tuple_element` không đệ quy. Pack indexing `Ts...[I]` là C++26: GCC
  14 từ chối; GCC 15 và Clang 20 nhận trong `-std=c++23` kèm `-Wc++26-extensions`, thành lỗi dưới
  `-Werror -Wpedantic` (đo) — đừng dùng.
- **Kiểm:** review template lớp có tham số `Head, Tail...`.

```cpp
// ✓ Chỉ số thành phần ECS trong danh sách kiểu: mảng bool + find, kiểm vắng/lặp lúc biên dịch.
#include <algorithm>
#include <array>
#include <concepts>
#include <cstddef>

namespace game::world {

template <class T, class... Ts>
inline constexpr std::size_t kIndexOf = [] {
    constexpr std::array<bool, sizeof...(Ts)> kMatches{std::same_as<T, Ts>...};
    static_assert(std::ranges::count(kMatches, true) == 1, "kIndexOf: T vắng hoặc lặp trong Ts");
    return static_cast<std::size_t>(std::ranges::find(kMatches, true) - kMatches.begin());
}();

struct Position {};
struct Velocity {};
struct Health {};

static_assert(kIndexOf<Health, Position, Velocity, Health> == 2);

} // namespace game::world
```

### GN-19 [T] PHẢI — Giữ ODR cho template và hàm inline: macro cấu hình đồng nhất trên mọi TU, không thực thể liên kết nội bộ trong header

(1) Macro làm đổi thân hàm inline/template (`GAME_DEBUG_CHECKS`, `_GLIBCXX_ASSERTIONS`, `NDEBUG`) đặt ở
mức target cho CẢ chương trình (BD-03), không `#define` trong .cpp trước include. (2) Header không chứa
namespace ẩn danh hay hàm/biến `static` mà hàm inline/template gọi tới; hằng dùng chung là `inline
constexpr`, hàm phụ vào `detail`.

- **Vì sao:** hàm inline và template được định nghĩa ở nhiều TU nhưng mọi định nghĩa phải giống hệt từng
  token và trỏ tới cùng thực thể ([basic.def.odr]); sai là ill-formed NDR. Linker giữ MỘT bản COMDAT
  tuỳ ý: TU A có `GAME_DEBUG_CHECKS`, TU B không → `debug_check` bật ở chỗ này, tắt ở chỗ kia tuỳ thứ tự
  link. Hàm trong namespace ẩn danh là thực thể KHÁC ở mỗi TU, nên hàm inline gọi nó vi phạm ODR dù văn
  bản giống nhau.
- **Kiểm:** GCC `-Wodr` (cần `-flto`; so kiểu/vtable giữa TU), GCC `-Wsubobject-linkage` (lớp trong
  header có thành viên kiểu nội bộ); ASan `detect_odr_violation` (chỉ biến toàn cục).

```cpp
// ✗ Header: hàm inline gọi hàm trong namespace ẩn danh — mỗi TU một hàm khác nhau.
#include <cstdint>

namespace {
std::uint32_t clamp_mtu(std::uint32_t size) {
    return size < 1200U ? size : 1200U;
}
} // namespace

inline std::uint32_t payload_budget(std::uint32_t mtu) {
    return clamp_mtu(mtu) - 28U;
}
```

```cpp
// ✓ Header: hằng inline constexpr và hàm detail có liên kết ngoài — một thực thể cho mọi TU.
#include "core/check.hpp"

#include <algorithm>
#include <cstdint>

namespace game::net {

inline constexpr std::uint32_t kMaxMtu = 1200U;
// Header IPv4 20 byte + UDP 8 byte.
inline constexpr std::uint32_t kUdpIpOverhead = 28U;

namespace detail {

[[nodiscard]] constexpr std::uint32_t clamp_mtu(std::uint32_t size) noexcept {
    return std::min(size, kMaxMtu);
}

} // namespace detail

[[nodiscard]] constexpr std::uint32_t payload_budget(std::uint32_t mtu) noexcept {
    core::check(mtu >= kUdpIpOverhead, "payload_budget: mtu phải >= kUdpIpOverhead");
    return detail::clamp_mtu(mtu) - kUdpIpOverhead;
}

} // namespace game::net
```

### GN-20 [T] PHẢI — `if consteval` khi bản lúc biên dịch và bản lúc chạy khác nhau; hai nhánh cho cùng kết quả từng bit và cả hai được test

`if consteval { bản tham chiếu constexpr } return bản intrinsic;`. CẤM `std::is_constant_evaluated()`
trong `if constexpr`. Hai nhánh phải tương đương từng bit — test lúc chạy so với giá trị `static_assert`
đã chứng minh.

- **Vì sao:** `if constexpr (std::is_constant_evaluated())` là ngữ cảnh hằng nên luôn `true`: nhánh
  runtime không bao giờ chạy (đo: GCC `-Wtautological-compare`, Clang `-Wconstant-evaluated` cảnh báo).
  `if consteval` còn cho gọi hàm `consteval` trong nhánh hằng. Nếu hai nhánh khác nhau (rsqrt ước lượng
  12 bit lúc chạy, sqrt chính xác lúc biên dịch) thì cùng biểu thức cho hai kết quả tuỳ ngữ cảnh:
  `static_assert` qua mà máy chủ tính khác — lỗi tất định không ai tìm ra.
- **Kiểm:** mẫu `[chạy]` so hai đường; KT test sai phân.

```cpp
// ✓ [x86] [chạy] CRC-32C: bản tham chiếu từng bit lúc biên dịch, lệnh CRC32 (SSE4.2) lúc chạy.
#include "core/check.hpp"

#include <array>
#include <cstdint>
#include <span>

#include <nmmintrin.h>

namespace game::net {

// Đa thức Castagnoli phản xạ 0x82F63B78, một byte.
[[nodiscard]] constexpr std::uint32_t crc32c_reference(std::uint32_t crc, std::uint8_t byte) noexcept {
    crc ^= byte;
    for (int bit = 0; bit < 8; ++bit) {
        crc = (crc >> 1U) ^ (0x82F6'3B78U & (0U - (crc & 1U)));
    }
    return crc;
}

[[nodiscard]] constexpr std::uint32_t crc32c_step(std::uint32_t crc, std::uint8_t byte) noexcept {
    if consteval {
        return crc32c_reference(crc, byte);
    }
    return _mm_crc32_u8(crc, byte);
}

[[nodiscard]] constexpr std::uint32_t crc32c(std::span<const std::uint8_t> bytes) noexcept {
    std::uint32_t crc = 0xFFFF'FFFFU;
    for (const std::uint8_t byte : bytes) {
        crc = crc32c_step(crc, byte);
    }
    return ~crc;
}

inline constexpr std::array<std::uint8_t, 4> kCheckInput{'a', 'b', 'c', 'd'};

} // namespace game::net

int main() {
    constexpr std::uint32_t kAtCompileTime = game::net::crc32c(game::net::kCheckInput);
    const std::uint32_t at_run_time = game::net::crc32c(game::net::kCheckInput);
    game::core::check(kAtCompileTime == at_run_time, "crc32c: hai nhánh lệch nhau");
    return 0;
}
```

## Kiểm nhanh

- [ ] Mọi tham số template có concept, không `enable_if`/`void_t` mới; template có ≥ 2 kiểu dùng thật? (GN-01)
- [ ] Rẽ theo kiểu là chuỗi `if constexpr`, nhánh cuối `static_assert(false, "…")`? (GN-02)
- [ ] Không chuyên biệt hoá tường minh hàm; tuỳ biến bằng nạp chồng? (GN-03)
- [ ] Hash/id từ literal là `consteval`; mỗi hàm `constexpr` có `static_assert` qua được cả libc++? (GN-04, GN-05)
- [ ] `T&&` suy diễn đi với đúng một `std::forward`, không `std::move`? (GN-06)
- [ ] Callable gọi ngay là template ràng buộc, không `std::function`? (GN-07)
- [ ] Concept hẹp viết qua concept rộng; không ghép trait rời trên nạp chồng? (GN-08, GN-09)
- [ ] Container dựng từ iterator/range ghi rõ kiểu, không CTAD với `{}`? (GN-10)
- [ ] Pack mở bằng fold/index_sequence/mảng giá trị, không đệ quy `Head, Tail...`? (GN-11, GN-18)
- [ ] Template số học có `static_assert` ở biên cho từng kiểu của concept? (GN-17)
- [ ] Macro cấu hình đặt ở mức target cho cả chương trình; header không có namespace ẩn danh? (GN-19)
- [ ] `if consteval` có hai nhánh cho cùng kết quả, test so cả hai? (GN-20)
