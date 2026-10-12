# API · Hàm, lớp và thiết kế API

> **Phạm vi:** truyền tham số và trả kết quả, số tham số, explicit, const, hàm tự do vs thành viên,
> nạp chồng và tham số mặc định, constructor và factory, toán tử, `= delete`, lớp đa hình, pimpl,
> deducing this, `static operator()`, `operator[]` nhiều chiều, CPO, ổn định ABI,
> `[[no_unique_address]]`, tiến hoá API. **Đọc khi:** viết chữ ký hàm hay lớp mới; thêm tham số; định
> nghĩa toán tử; viết hàm trả view; thiết kế lớp cơ sở/plugin; lớp có cặp getter const/không const;
> viết thư viện dùng chung giữa module; đổi API đã có người gọi.
> **Liên quan:** refs/03-kieu-gia-tri.md (KG-02, KG-07, KG-08, KG-10, KG-12),
> refs/04-so-huu-vong-doi.md (SH-06, SH-08, SH-17), refs/05-loi-hop-dong.md (LH),
> refs/07-generic-compile-time.md (GN), refs/17-kien-truc-module.md (KTR).

## 1. Nền tảng [N]

### API-01 [N] PHẢI — Truyền tham số theo bảng; không đoán

| Tham số | Cách truyền | Ví dụ |
|---|---|---|
| Rẻ: sao chép tầm thường và ≤ 16 B (số, enum, ID, `Float3`, `span`, `string_view`) | giá trị | `EntityId id`, `std::span<const Item> items` |
| Đắt, chỉ đọc | `const T&` | `const ZoneConfig& config` |
| Sink: hàm giữ một bản | giá trị, rồi `std::move` vào chỗ giữ | `std::string name` |
| Vào-ra: sửa đối tượng của nơi gọi | `T&` | `Inventory& bag` |
| Chuyển quyền sở hữu | `std::unique_ptr<T>` theo giá trị | `std::unique_ptr<Zone> zone` |
| Kiểu SIMD (bọc `__m128`) | `const T&` như code người dùng | `const Vector4i& a` |

- **Vì sao:** SysV x86-64 truyền struct sao chép tầm thường ≤ 16 B trong tối đa hai thanh ghi;
  `const T&` buộc đối tượng nằm trong bộ nhớ và trình dịch phải giả định nó đổi qua bí danh sau mỗi
  lần ghi qua con trỏ khác hay mỗi lời gọi hàm lạ — đọc lại từ bộ nhớ. MSVC x64 chỉ đưa cỡ 1, 2, 4, 8 B
  vào thanh ghi; cỡ khác và `__m128` (không `__vectorcall`) đi qua con trỏ tới bản sao của nơi gọi —
  lý do code SIMD người dùng nhận `const Vector4i&`. Sink theo giá trị: một copy cho lvalue, không
  copy cho rvalue; `const std::string&` rồi chép luôn tốn một copy.
- **Kiểm:** clang-tidy `performance-unnecessary-value-param`, `modernize-pass-by-value`,
  `cppcoreguidelines-rvalue-reference-param-not-moved`.

```cpp
// ✓ NPC: ID và vị trí theo giá trị, tên là sink, dãy chỉ đọc là span.
#include <cstdint>
#include <span>
#include <string>
#include <utility>

namespace game::world {

enum class NpcId : std::uint32_t {};

struct Vec3 {
    float x = 0.0F;
    float y = 0.0F;
    float z = 0.0F;
};

class Npc {
public:
    Npc(NpcId id, std::string name) noexcept : id_(id), name_(std::move(name)) {}

    void teleport(Vec3 where) noexcept { position_ = where; }

    [[nodiscard]] NpcId id() const noexcept { return id_; }
    [[nodiscard]] const std::string& name() const noexcept { return name_; }

private:
    NpcId id_{};
    std::string name_;
    Vec3 position_{};
};

[[nodiscard]] const Npc* find_npc(std::span<const Npc> npcs, NpcId id) noexcept;

} // namespace game::world
```

### API-02 [N] CẤM — Tham số ra; trả struct có tên, `std::optional` hoặc `std::expected`

- **Vì sao:** `bool parse(span, Move& out, std::string& error)` bắt nơi gọi khai báo biến chưa có giá
  trị thật (phá KG-01, KG-02), không nói `out` có bị ghi khi thất bại không, và mở bí danh giữa đầu
  vào và đầu ra. Trả giá trị không tốn copy (SH-08); `std::expected` có ở cả ba thư viện.
- **Kiểm:** review; clang-tidy `misc-const-correctness` lộ biến chỉ để hứng kết quả.
- **Ngoại lệ:** bộ đệm tái dùng trên đường nóng (`std::vector<EntityId>& out` được `clear()` rồi đổ
  vào, giữ capacity) — comment ghi "đầu ra tái dùng". API C.

```cpp
// ✓ Gói tin di chuyển: kết quả hoặc lỗi có kiểu, không tham số ra.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::proto {

enum class [[nodiscard]] ParseError : std::uint8_t { kTooShort, kBadDirection };

struct MoveCommand {
    std::uint8_t direction = 0;
    std::uint8_t speed = 0;
};

[[nodiscard]] constexpr std::expected<MoveCommand, ParseError> parse_move(std::span<const std::byte> payload) noexcept {
    if (payload.size() < 2) return std::unexpected(ParseError::kTooShort);
    const auto direction = std::to_integer<std::uint8_t>(payload[0]);
    if (direction >= 8) return std::unexpected(ParseError::kBadDirection);
    return MoveCommand{.direction = direction, .speed = std::to_integer<std::uint8_t>(payload[1])};
}

} // namespace game::proto
```

### API-03 [N] PHẢI — Không hai tham số cùng kiểu dễ đổi chỗ liền nhau; nhóm tham số luôn đi cùng nhau gom thành struct

Nhóm tham số luôn đi cùng nhau gom thành struct tham số có giá trị mặc
định; nơi gọi dùng designated initializer (KG-02). Hai tham số liền cùng kiểu đổi bằng kiểu mạnh
(KG-08) hoặc struct.

- **Vì sao:** `apply_damage(target, source, 120, 30, true, false)` không đọc được và đổi chỗ không
  lỗi. Struct tham số đặt tên mọi giá trị ở nơi gọi; thêm trường mới không sửa nơi gọi cũ (API-18).
- **Kiểm:** clang-tidy `bugprone-easily-swappable-parameters`.
- **Ngoại lệ:** thứ tự tham số là quy ước toán học hoặc hai tham số đối xứng: `min(a, b)`,
  `dot(a, b)`, `lerp(a, b, t)`, `clamp(v, low, high)`, `dist(a, b)` — như math/*.hpp. Check trên mặc
  định bỏ qua cặp tham số dùng chung trong một biểu thức (`SuppressParametersUsedTogether`).

```cpp
// ✓ Sự kiện sát thương: một struct, nơi gọi ghi tên từng giá trị.
#include <cstdint>

namespace game::combat {

enum class DamageKind : std::uint8_t { kPhysical, kMagic };

struct DamageEvent {
    std::uint32_t target = 0;
    std::uint32_t source = 0;
    std::int32_t amount = 0;
    DamageKind kind = DamageKind::kPhysical;
    bool critical = false;
};

[[nodiscard]] constexpr std::int32_t final_amount(DamageEvent event) noexcept {
    return event.critical ? event.amount * 2 : event.amount;
}

static_assert(final_amount({.target = 7, .source = 9, .amount = 50, .critical = true}) == 100);

} // namespace game::combat
```

### API-04 [N] PHẢI — Constructor một đối số và toán tử chuyển đổi là `explicit`

Trừ copy/move và chuyển đổi không mất mát có chủ đích (như `std::string` → `std::string_view`).
Constructor nhiều đối số không cần `explicit` (code người dùng: `Vector4i(x, y, z, w)` cho phép
`return {1, 0, 0, 0};`, còn `explicit Vector4i(std::int32_t scalar)`).

- **Vì sao:** `PacketBuffer(std::size_t capacity)` không explicit làm `send(42)` biên dịch: tạo gói
  rỗng dung lượng 42 rồi gửi. `operator bool` không explicit cho `buffer + 1` và `buffer == 3`.
- **Kiểm:** clang-tidy `cppcoreguidelines-explicit-constructor`.

```cpp
// ✓ send(42) là lỗi biên dịch; if (buffer) vẫn viết được.
#include <cstddef>
#include <vector>

namespace game::net {

class PacketBuffer {
public:
    explicit PacketBuffer(std::size_t capacity) { bytes_.reserve(capacity); }

    explicit operator bool() const noexcept { return !bytes_.empty(); }

private:
    std::vector<std::byte> bytes_;
};

void send(const PacketBuffer& buffer);

} // namespace game::net
```

### API-05 [N] PHẢI — Chữ ký nói hợp đồng: hàm chỉ đọc là `const` (đọc đồng thời an toàn), hàm trả giá trị là `[[nodiscard]]`, hàm không ném là `noexcept`

`mutable` chỉ cho mutex, bộ đếm nguyên tử, cache có đồng bộ bên trong. `[[nodiscard]]` trên mọi hàm
trả giá trị, kể cả hàm `constexpr` và toán tử tự do; trừ hàm trả `T&` để nối chuỗi (`set_x`,
`operator+=`) — như math/*.hpp. `noexcept` trên hàm không cấp phát và chỉ gọi hàm `noexcept`; hàm có
cấp phát thì không khai (LH-07); destructor, move, `swap` luôn `noexcept` (LH-06).

- **Vì sao:** `const` cho nơi gọi biết hàm không đổi đối tượng và dùng được trên `const T&`. Thư viện
  chuẩn giả định hàm `const` gọi từ nhiều luồng không tranh chấp dữ liệu ([res.on.data.races]): kiểu
  của bạn đặt vào container chuẩn cũng phải giữ hứa ấy — `mutable` không khoá là tranh chấp dữ liệu
  (UB) trong hàm "chỉ đọc". `normalize(v);` mà không gán là lỗi logic im lặng; `[[nodiscard]]` biến
  nó thành lỗi biên dịch dưới `-Werror`. `noexcept` cho nơi gọi (và `std::vector` khi dời phần tử)
  biết hàm không ném, và để `bugprone-exception-escape` kiểm lời hứa.
- **Kiểm:** clang-tidy `readability-make-member-function-const`, `modernize-use-nodiscard` (chỉ bắt
  hàm thành viên const), `bugprone-exception-escape`; `-Wunused-result` (GCC), `-Wunused-value`
  (Clang); TSan.

```cpp
// ✓ Đếm người chơi online: đọc const từ nhiều luồng, khoá là mutable.
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <unordered_set>

namespace game::net {

class Presence {
public:
    void add(std::uint64_t account) {
        const std::scoped_lock lock(mutex_);
        online_.insert(account);
    }

    [[nodiscard]] std::size_t online_count() const {
        const std::scoped_lock lock(mutex_);
        return online_.size();
    }

private:
    mutable std::mutex mutex_;
    std::unordered_set<std::uint64_t> online_;
};

} // namespace game::net
```

### API-06 [N] NÊN — Hàm không cần truy cập private là hàm tự do cùng namespace

Như code người dùng: `dot`, `length`, `min`, `less`, `load`, `store` là hàm tự do; lớp chỉ giữ thứ
cần bất biến hay biểu diễn ẩn (`simd()`, `set_x`).

- **Vì sao:** ít hàm chạm private thì ít chỗ có thể phá bất biến. Hàm tự do nạp chồng được cho nhiều
  kiểu (`min(Plain2, Plain2)`, `min(Vector4i, Vector4i)`), tìm qua ADL, đối xứng hai đối số và dùng
  được trong code generic `dot(a, b)` cho mọi kiểu.
- **Kiểm:** review.

```cpp
// ✓ Hộp bao AOI: dữ liệu thuần, phép hình học là hàm tự do, đối xứng hai đối số.
namespace game::world {

struct Aabb {
    float min_x = 0.0F;
    float min_y = 0.0F;
    float max_x = 0.0F;
    float max_y = 0.0F;
};

[[nodiscard]] constexpr bool intersects(Aabb first, Aabb second) noexcept {
    const bool overlaps_x = first.min_x <= second.max_x && second.min_x <= first.max_x;
    const bool overlaps_y = first.min_y <= second.max_y && second.min_y <= first.max_y;
    return overlaps_x && overlaps_y;
}

} // namespace game::world
```

### API-07 [N] PHẢI — Nạp chồng chỉ khi cùng ngữ nghĩa, không trộn `bool`/con trỏ/số với kiểu lớp; tham số mặc định chỉ ở cuối, CẤM trên hàm ảo

Khác nghĩa thì khác tên. Tham số mặc định chỉ cho giá trị hiển nhiên ở cuối (vd.
`all_true(mask, lanes = 4)` của vector_int.hpp), không cho cờ `bool` (KG-07).

- **Vì sao:** với `log_line(bool)` và `log_line(std::string_view)`, `log_line("disconnect")` gọi bản
  `bool`: con trỏ → bool là chuyển đổi chuẩn, thắng chuyển đổi do người dùng định nghĩa. Đã đo: GCC 14
  và Clang 20 đều chọn `bool`; Clang báo `-Wstring-conversion` (thuộc `-Wconversion`), GCC im lặng.
  Giá trị mặc định được chép vào từng nơi gọi lúc biên dịch: đổi nó mà không biên dịch lại mọi nơi gọi
  thì hai phiên bản cùng chạy. Với hàm ảo, mặc định lấy theo kiểu TĨNH: `base.attack()` và
  `derived.attack()` trên cùng đối tượng nhận hai giá trị khác nhau.
- **Kiểm:** Clang `-Wconversion`; review mọi bộ nạp chồng có `bool`; clang-tidy
  `google-default-arguments` bắt mặc định trên hàm ảo.

```cpp
// ✓ Hai ý nghĩa hai tên (không nạp chồng bool với số); mặc định hiển nhiên ở cuối.
#include <cstdint>
#include <string>
#include <string_view>

namespace game::core {

[[nodiscard]] inline std::string format_flag(std::string_view key, bool value) {
    return std::string(key) + (value ? "=on" : "=off");
}

[[nodiscard]] inline std::string format_count(std::string_view key, std::int64_t count, char separator = '=') {
    return std::string(key) + separator + std::to_string(count);
}

} // namespace game::core
```

## 2. Nâng cao [C]

### API-08 [C] PHẢI — Constructor lập bất biến; tạo có thể thất bại thì factory `static` trả `std::expected`

Không đối tượng "nửa hợp lệ" cần `init()`. Khi tham số đến từ dữ liệu (cấu hình, DB) và có thể sai:
constructor private nhận giá trị đã kiểm, `create()` public kiểm rồi trả `std::expected<T, E>`.

- **Vì sao:** `init()` riêng tạo trạng thái "đã dựng, chưa init" mà mọi hàm phải kiểm. Ném ngoại lệ từ
  constructor trái chính sách đường game (refs/05-loi-hop-dong.md). Factory giữ bất biến trong kiểu:
  có `RateLimiter` trong tay là có cấu hình hợp lệ.
- **Kiểm:** review; test cho từng nhánh lỗi của `create`.

```cpp
// ✓ Giới hạn tần suất lệnh chat: cấu hình sai bị từ chối trước khi có đối tượng.
#include <algorithm>
#include <cstdint>
#include <expected>

namespace game::net {

enum class [[nodiscard]] RateError : std::uint8_t { kZeroRefill, kSmallBurst };

struct RateConfig {
    std::int32_t refill_per_tick = 1;
    std::int32_t burst = 10;
};

class RateLimiter {
public:
    [[nodiscard]] static std::expected<RateLimiter, RateError> create(RateConfig config) noexcept {
        if (config.refill_per_tick <= 0) return std::unexpected(RateError::kZeroRefill);
        if (config.burst < config.refill_per_tick) return std::unexpected(RateError::kSmallBurst);
        return RateLimiter(config);
    }

    void refill() noexcept { tokens_ = std::min(tokens_ + config_.refill_per_tick, config_.burst); }

    [[nodiscard]] bool try_take() noexcept {
        if (tokens_ == 0) return false;
        --tokens_;
        return true;
    }

private:
    explicit RateLimiter(RateConfig config) noexcept : config_(config), tokens_(config.burst) {}

    RateConfig config_;
    std::int32_t tokens_ = 0;
};

} // namespace game::net
```

### API-09 [C] PHẢI — Toán tử là hidden friend, chỉ khi nghĩa hiển nhiên và đúng quy ước; phép so trả mặt nạ là hàm có tên

Quy ước: `==` trả `bool`, là quan hệ tương đương; `<` là thứ tự yếu nghiêm ngặt; có `+` thì có `+=`
(trả `T&`); không tác dụng phụ ngoài toán hạng trái của dạng gán. So từng làn trả mặt nạ và "mọi
thành phần nhỏ hơn" là hàm có tên (`less`, `equal`, `all_less` của người dùng).

- **Vì sao:** hidden friend chỉ thấy được qua ADL khi một đối số có kiểu lớp ấy: không làm phình tập
  ứng viên của mọi `operator+` khác trong namespace (biên dịch nhanh hơn, lỗi ngắn hơn) và không được
  chọn qua chuyển đổi ngầm từ kiểu lạ — cách types.hpp viết `operator+`, `operator==`. Người dùng đã
  ghi trong soa.hpp: gốc nạp chồng `operator<` trả mặt nạ, đọc như phép so thường nhưng `if (a == b)`
  không biên dịch; `all_less` không phải thứ tự yếu nghiêm ngặt nên làm khoá `std::map`/`std::sort`
  là sai âm thầm (KG-10).
- **Kiểm:** review; `static_assert(std::totally_ordered<T>)` khi định nghĩa `<`.

```cpp
// ✓ Tiền: cộng, trừ, so sánh là hidden friend; += trả Money&; không có phép nhân hai khoản tiền.
#include <compare>
#include <cstdint>

namespace game::inv {

class Money {
public:
    constexpr explicit Money(std::int64_t copper) noexcept : copper_(copper) {}

    [[nodiscard]] constexpr std::int64_t copper() const noexcept { return copper_; }

    constexpr Money& operator+=(Money other) noexcept {
        copper_ += other.copper_;
        return *this;
    }

    [[nodiscard]] friend constexpr Money operator+(Money left, Money right) noexcept { return left += right; }
    friend constexpr std::strong_ordering operator<=>(Money, Money) = default;

private:
    std::int64_t copper_ = 0;
};

static_assert(Money(5) + Money(7) == Money(12));

} // namespace game::inv
```

### API-10 [C] NÊN — `= delete` và ràng buộc chặn nạp chồng nguy hiểm: view trên rvalue, chuyển đổi mất mát

Hàm trả view/tham chiếu vào `*this`: bản `const&&` bị xoá để `make_msg().text()` là lỗi biên dịch.
Hàm chỉ nhận đúng một kiểu: ràng buộc `std::same_as<T> auto` (hoặc template `= delete` cho mọi kiểu
khác). C++26 có `= delete("lý do")`; C++23 ghi lý do bằng comment ngay trên dòng.

- **Vì sao:** chặn treo (SH-06) và chuyển đổi mất mát (`set_price(19.99)` thành 19 đồng) tại nơi gọi,
  lúc biên dịch. Đánh đổi: xoá `&&` cũng chặn dùng an toàn trong cùng biểu thức
  (`print(make_msg().text())`) — chỉ xoá khi kiểu thường được tạo tạm thời.
- **Kiểm:** concept trong test như `CanSetPrice` dưới, `static_assert` cả ca được và ca bị chặn.

```cpp
// ✓ text() trên tạm thời và set_price với kiểu khác std::int64_t là lỗi biên dịch.
#include <concepts>
#include <cstdint>
#include <string>
#include <string_view>
#include <utility>

namespace game::net {

class ChatMessage {
public:
    explicit ChatMessage(std::string text) noexcept : text_(std::move(text)) {}

    [[nodiscard]] std::string_view text() const& noexcept { return text_; }
    // View vào chuỗi của đối tượng sắp chết luôn treo.
    [[nodiscard]] std::string_view text() const&& = delete;

private:
    std::string text_;
};

class Listing {
public:
    void set_price(std::same_as<std::int64_t> auto copper) noexcept { copper_ = copper; }

private:
    std::int64_t copper_ = 0;
};

template <class T>
concept CanSetPrice = requires(Listing listing, T value) { listing.set_price(value); };
static_assert(CanSetPrice<std::int64_t> && !CanSetPrice<double> && !CanSetPrice<int>);

} // namespace game::net
```

### API-11 [C] PHẢI — Lớp đa hình: destructor public virtual (hoặc protected không virtual), `override`/`final`, chặn copy

- **Vì sao:** `delete` qua con trỏ lớp cơ sở thiếu destructor ảo là UB. Thiếu `override`, lệch một
  `const` là tạo hàm mới im lặng. `final` cho trình dịch khử ảo lời gọi qua kiểu cuối. Sao chép lớp đa
  hình cắt mất phần dẫn xuất (slicing). Tập kiểu đóng dùng variant thay cây kế thừa (KG-12).
- **Kiểm:** `-Wnon-virtual-dtor`, `-Wsuggest-override`, `-Woverloaded-virtual`; clang-tidy
  `cppcoreguidelines-virtual-class-destructor`, `modernize-use-override`, `cppcoreguidelines-slicing`.

```cpp
// ✓ Bộ lọc chat cắm được: giao diện thuần ảo không sao chép, lớp cụ thể final.
#include <cstddef>
#include <string_view>

namespace game::net {

class ChatFilter {
public:
    ChatFilter() noexcept = default;
    ChatFilter(const ChatFilter&) = delete;
    ChatFilter& operator=(const ChatFilter&) = delete;
    ChatFilter(ChatFilter&&) = delete;
    ChatFilter& operator=(ChatFilter&&) = delete;
    virtual ~ChatFilter() = default;

    [[nodiscard]] virtual bool allows(std::string_view text) const noexcept = 0;
};

class LengthFilter final : public ChatFilter {
public:
    [[nodiscard]] bool allows(std::string_view text) const noexcept override { return text.size() <= kMaxBytes; }

private:
    static constexpr std::size_t kMaxBytes = 256;
};

} // namespace game::net
```

### API-12 [C] CÓ THỂ — Pimpl cho lớp công khai có phụ thuộc nặng hoặc cần giữ ABI

`std::unique_ptr<Impl>`; destructor và move KHAI BÁO trong header, ĐỊNH NGHĨA `= default` trong .cpp
nơi `Impl` đầy đủ.

- **Vì sao:** header không kéo include của phần cài đặt (biên dịch lại ít hơn); thêm trường vào `Impl`
  không đổi `sizeof` lớp công khai (ABI). `unique_ptr<Impl>` cần `Impl` đầy đủ nơi destructor được
  sinh: để trình dịch sinh ngầm trong header là lỗi "sizeof kiểu chưa đầy đủ". Giá: một cấp phát, một
  bước gián tiếp mỗi truy cập — không dùng cho kiểu nhỏ trên đường nóng. Moved-from có `impl_` null:
  hợp đồng ghi chỉ được huỷ/gán lại (SH-08).
- **Kiểm:** header tự biên dịch được một mình (KTR-03).

```cpp
// ✓ Phần header và phần .cpp của WorldServer trong một khối.
#include <cstddef>
#include <cstdint>
#include <memory>
#include <type_traits>
#include <vector>

namespace game::world {

// ---- world_server.hpp
class WorldServer {
public:
    WorldServer();
    WorldServer(const WorldServer&) = delete;
    WorldServer& operator=(const WorldServer&) = delete;
    WorldServer(WorldServer&&) noexcept;
    WorldServer& operator=(WorldServer&&) noexcept;
    ~WorldServer();

    [[nodiscard]] std::size_t player_count() const noexcept;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

static_assert(std::is_nothrow_move_constructible_v<WorldServer>);

// ---- world_server.cpp
struct WorldServer::Impl {
    std::vector<std::uint64_t> players;
};

WorldServer::WorldServer() : impl_(std::make_unique<Impl>()) {}
WorldServer::WorldServer(WorldServer&&) noexcept = default;
WorldServer& WorldServer::operator=(WorldServer&&) noexcept = default;
WorldServer::~WorldServer() = default;

std::size_t WorldServer::player_count() const noexcept {
    return impl_->players.size();
}

} // namespace game::world
```

## 3. Thần thoại [T]

### API-13 [T] NÊN — Mixin dùng deducing this thay CRTP; getter cho mọi loại tham chiếu theo GN-15

Hàm của mixin nhận `this const Self& self` (hoặc `this Self&& self`) và gọi API công khai của kiểu
thật; lớp dùng mixin kế thừa một lớp thường, không phải `Base<Derived>`. Cơ chế, bẫy và getter
const/không const/rvalue: GN-15.

- **Vì sao:** CRTP truyền nhầm tham số (`class Boss : public HealthOps<Monster>`, chép từ lớp bên cạnh)
  vẫn biên dịch, và `static_cast<const Monster&>(*this)` trên một `Boss` là UB. Deducing this suy ra
  kiểu thật tại nơi gọi nên không còn tham số để nhầm; mixin là một kiểu duy nhất, không phải một
  template cho mỗi lớp. Mixin chỉ thấy API công khai của lớp dẫn xuất (không có quan hệ friend như
  CRTP hay dùng): hợp đồng giữa hai bên là API công khai. Bẫy: hàm có `this` tường minh không được
  `virtual`; `this Self self` (theo giá trị) là sao chép. Đã đo `__cpp_explicit_this_parameter ==
  202110L` trên GCC 14, 15, Clang 20.
- **Kiểm:** `static_assert` trên lớp dùng mixin; review: `static_cast<Derived` còn sót là CRTP cũ.

```cpp
// ✓ Mixin không CRTP: Self là kiểu thật của đối tượng gọi, không có tham số template để nhầm.
#include <cstdint>

namespace game::world {

struct Vitals {
    std::int32_t health = 0;
    std::int32_t health_max = 0;
};

// Cho mọi kiểu có vitals() công khai.
struct HealthOps {
    template <class Self>
    [[nodiscard]] constexpr bool is_full(this const Self& self) noexcept {
        return self.vitals().health >= self.vitals().health_max;
    }
};

class Monster : public HealthOps {
public:
    explicit constexpr Monster(Vitals vitals) noexcept : vitals_(vitals) {}

    [[nodiscard]] constexpr Vitals vitals() const noexcept { return vitals_; }

private:
    Vitals vitals_;
};

static_assert(Monster({.health = 50, .health_max = 50}).is_full());
static_assert(!Monster({.health = 49, .health_max = 50}).is_full());

} // namespace game::world
```

### API-14 [T] CÓ THỂ — `static operator()` cho đối tượng hàm không trạng thái; `operator[]` nhiều chiều cho lưới

- **Vì sao:** `static operator()` (P1169) bỏ tham số đối tượng ẩn: khi lời gọi không được nội tuyến
  (qua `std::function`, con trỏ hàm, ranh giới TU) không phải truyền `this` — bớt một thanh ghi.
  Lambda: `[](…) static {…}` (chỉ khi không bắt gì). `grid[col, row]` (P2128) thay `grid(col, row)` hay
  `grid[col][row]` trả proxy; trong C++20 dấu phẩy trong `[]` là toán tử phẩy (đã lỗi thời). Đã đo
  `__cpp_static_call_operator == 202207L`, `__cpp_multidimensional_subscript == 202211L` trên cả ba
  trình dịch.
- **Kiểm:** review; `-Wcomma` (Clang) bắt toán tử phẩy còn sót.

```cpp
// ✓ Bộ so sánh không trạng thái và lưới AOI chỉ số hai chiều.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::world {

struct Monster {
    std::uint32_t id = 0;
    std::int32_t hp = 0;
};

struct ByHp {
    [[nodiscard]] static constexpr bool operator()(Monster left, Monster right) noexcept { return left.hp < right.hp; }
};

class AoiGrid {
public:
    AoiGrid(std::size_t cols, std::size_t rows) : cols_(cols), counts_(cols * rows) {}

    [[nodiscard]] std::uint16_t& operator[](std::size_t col, std::size_t row) noexcept {
        core::check(col < cols_ && (row * cols_) + col < counts_.size(), "AoiGrid: ngoài lưới");
        return counts_[(row * cols_) + col];
    }

private:
    std::size_t cols_ = 0;
    std::vector<std::uint16_t> counts_;
};

} // namespace game::world
```

### API-15 [T] NÊN — Điểm tuỳ biến là đối tượng hàm (CPO/niebloid), không phải hàm tự do cộng `using std::swap`

`inline constexpr detail::XFn x{};` mà `operator()` có ràng buộc và điều phối theo thứ tự cố định:
thành viên `v.x()` → hàm tự do tìm qua ADL → lỗi biên dịch rõ.

- **Vì sao:** tên tìm thấy là một ĐỐI TƯỢNG nên ADL không áp cho lời gọi `encoded_size(v)`:
  không ai vô tình chiếm lời gọi bằng hàm cùng tên ở namespace khác, và không cần mẹo hai bước
  `using std::swap; swap(a, b);`. Đối tượng truyền thẳng vào thuật toán
  (`std::views::transform(proto::encoded_size)`); concept kiểm ở một chỗ cho thông báo lỗi ngắn. Đây
  là cách `std::ranges::begin`, `size` được định nghĩa.
- **Kiểm:** test `static_assert(std::invocable<…>)` cho từng nhánh và cho kiểu bị từ chối.

```cpp
// ✓ encoded_size: kiểu tự khai báo bằng thành viên hoặc bằng hàm tự do cùng namespace.
#include <concepts>
#include <cstddef>

namespace game::proto {
namespace detail {

// Yêu cầu noexcept để operator() dưới khai noexcept cứng mà không biến lỗi thành terminate (LH-06).
template <class T>
concept HasMemberSize = requires(const T& value) {
    { value.encoded_size() } noexcept -> std::convertible_to<std::size_t>;
};

template <class T>
concept HasAdlSize = requires(const T& value) {
    { encoded_size_of(value) } noexcept -> std::convertible_to<std::size_t>;
};

struct EncodedSizeFn {
    template <class T>
        requires HasMemberSize<T> || HasAdlSize<T>
    [[nodiscard]] static constexpr std::size_t operator()(const T& value) noexcept {
        if constexpr (HasMemberSize<T>) {
            return value.encoded_size();
        } else {
            return encoded_size_of(value);
        }
    }
};

} // namespace detail

// CPO là đối tượng đóng vai hàm (API-15).
inline constexpr detail::EncodedSizeFn encoded_size{};

struct Ping {
    [[nodiscard]] static constexpr std::size_t encoded_size() noexcept { return 4; }
};

static_assert(encoded_size(Ping{}) == 4 && !std::invocable<detail::EncodedSizeFn, int>);

} // namespace game::proto
```

### API-16 [T] PHẢI — Ranh giới ABI (plugin, SDK) là C ABI có `struct_size` và phiên bản; không lộ kiểu thư viện chuẩn

Thay đổi PHÁ ABI của lớp đã phát hành: thêm/bỏ/đổi thứ tự thành viên; thêm hàm ảo (đổi vtable); đổi
thân hàm inline (nơi gọi giữ bản cũ); đổi tham số mặc định; đổi kiểu nền enum; thêm/bỏ
`[[no_unique_address]]` (API-17). Qua ranh giới: chỉ kiểu cỡ cố định, con trỏ, struct C; không
`std::string`/`std::vector`/ngoại lệ.

- **Vì sao:** plugin biên dịch bằng trình dịch hay thư viện khác thấy bố cục khác: libstdc++, libc++ và
  MSVC có `std::string` khác hẳn nhau; ngay libstdc++ có hai ABI cho `std::string`
  (`_GLIBCXX_USE_CXX11_ABI`). Ngoại lệ không được vượt ranh giới: khung C thường không có thông tin
  unwind (terminate hoặc UB tuỳ nền tảng) — bắt hết ở phía C++ (LH-08). `struct_size` do
  bên tạo điền cho phép host mới đọc plugin cũ: chỉ đọc trường nằm trọn trong `struct_size`.
- **Kiểm:** `static_assert` bố cục; test nạp plugin build bằng trình dịch khác trong CI.

```cpp
// ✓ Bảng hàm plugin AI: chỉ thêm trường ở cuối, host kiểm struct_size trước khi đọc.
#include <cstddef>
#include <cstdint>
#include <type_traits>

extern "C" {

using GameTickFn = void (*)(std::uint64_t tick);

struct GamePluginApi {
    // Bên tạo tự điền cỡ của phiên bản nó biết.
    std::uint32_t struct_size = sizeof(GamePluginApi);
    std::uint32_t version = 1;
    GameTickFn on_tick = nullptr;
};

} // extern "C"

namespace game::app {

static_assert(std::is_standard_layout_v<GamePluginApi>);
static_assert(std::is_trivially_copyable_v<GamePluginApi>);
static_assert(offsetof(GamePluginApi, on_tick) == 8);

[[nodiscard]] constexpr bool has_on_tick(const GamePluginApi& api) noexcept {
    return api.struct_size >= offsetof(GamePluginApi, on_tick) + sizeof(GameTickFn);
}

} // namespace game::app
```

### API-17 [T] CÓ THỂ — Thành viên rỗng (policy, clock, deleter) dùng `[[no_unique_address]]` qua macro

- **Vì sao:** thành viên kiểu rỗng vẫn chiếm ít nhất 1 byte cộng đệm; `[[no_unique_address]]` cho nó
  chồng lên thành viên khác. MSVC chấp nhận thuộc tính chuẩn nhưng BỎ QUA (giữ ABI) — cần
  `[[msvc::no_unique_address]]`: thiếu macro thì cùng lớp khác `sizeof` giữa Linux và Windows. Thành
  viên ấy là subobject có thể chồng lấp: bảo đảm memcpy của kiểu sao chép tầm thường không áp cho nó
  ([basic.types.general]) — `memcpy` `sizeof(T)` byte vào nó có thể đè thành viên khác nằm trong
  phần đệm đuôi.
- **Kiểm:** `static_assert(sizeof(…))` trên mọi nền tảng CI.

```cpp
// ✓ Hồi chiêu với đồng hồ là tham số template: đồng hồ rỗng không tốn byte nào.
#include <cstdint>

#if defined(_MSC_VER)
#define GAME_NO_UNIQUE_ADDRESS [[msvc::no_unique_address]]
#else
#define GAME_NO_UNIQUE_ADDRESS [[no_unique_address]]
#endif

namespace game::sim {

// Mốc: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

// Rỗng: hàm thành viên không làm lớp có dữ liệu.
struct TickClock {
    [[nodiscard]] Tick now() const noexcept;
};

template <class Clock>
class Cooldown {
public:
    [[nodiscard]] bool ready() const noexcept { return clock_.now() >= ready_at_; }

private:
    GAME_NO_UNIQUE_ADDRESS Clock clock_;
    Tick ready_at_{};
};

static_assert(sizeof(Cooldown<TickClock>) == sizeof(Tick));

} // namespace game::sim
```

### API-18 [T] NÊN — Tiến hoá API không phá nơi gọi: trường mới có mặc định, `[[deprecated]]` một vòng trước khi xoá

Thêm khả năng: thêm trường có default member initializer vào struct tham số (nơi gọi designated init
không đổi). Đổi chữ ký: thêm hàm mới, đánh dấu hàm cũ `[[deprecated("dùng X")]]`, chuyển tiếp sang
hàm mới trong một vòng phát hành, rồi xoá. Không bao giờ đổi NGHĨA mà giữ nguyên tên.

- **Vì sao:** `-Werror` biến cảnh báo deprecated thành lỗi ở nơi gọi đã có: dùng
  `-Wno-error=deprecated-declarations` trong vòng chuyển tiếp để nơi gọi thấy mà build vẫn qua. Đổi
  nghĩa giữ tên (đơn vị ms → tick) không gây lỗi biên dịch nào — chỉ gây lỗi ở production.
- **Kiểm:** grep nơi gọi hàm deprecated trước khi xoá; changelog API.

```cpp
// ✓ v2 thêm trường guild_only có mặc định; hàm cũ chuyển tiếp sang bản mới.
#include <cstdint>

namespace game::world {

struct BroadcastParams {
    std::uint32_t zone = 0;
    // Thêm ở v2: nơi gọi cũ không đổi.
    bool guild_only = false;
};

void broadcast(BroadcastParams params);

[[deprecated("dùng broadcast(BroadcastParams); xoá ở bản 2.0")]] inline void broadcast_zone(std::uint32_t zone) {
    broadcast({.zone = zone});
}

} // namespace game::world
```

## Kiểm nhanh

- [ ] Mỗi tham số truyền đúng bảng: rẻ theo giá trị, đắt chỉ đọc `const&`, sink theo giá trị + move? (API-01)
- [ ] Không tham số ra; kết quả là struct/optional/expected? (API-02)
- [ ] Không hai tham số cùng kiểu dễ đổi chỗ liền nhau; nhóm tham số đi cùng nhau đã gom struct? (API-03)
- [ ] Constructor một đối số và `operator bool` là `explicit`? (API-04)
- [ ] Hàm không đổi trạng thái là `const`; `mutable` chỉ cho thứ có đồng bộ? (API-05)
- [ ] Không bộ nạp chồng trộn `bool`/con trỏ/số với kiểu lớp; không mặc định trên hàm ảo? (API-07)
- [ ] Constructor lập bất biến; tạo có thể sai qua `create()` trả `expected`? (API-08)
- [ ] Toán tử là hidden friend, đúng quy ước; so trả mặt nạ là hàm có tên? (API-09)
- [ ] Hàm trả view vào `*this` có bản `&&` bị xoá hoặc `GAME_LIFETIMEBOUND`? (API-10, SH-17)
- [ ] Lớp đa hình: destructor ảo, `override`/`final`, không sao chép? (API-11)
- [ ] Ranh giới plugin là C ABI có `struct_size`, không kiểu std? (API-16)
