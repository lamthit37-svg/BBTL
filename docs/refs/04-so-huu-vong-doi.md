# SH · Sở hữu và vòng đời

> **Phạm vi:** RAII, quyền sở hữu (unique_ptr, shared_ptr, weak_ptr, con trỏ trần), rule of zero/five,
> move và moved-from, view treo, vô hiệu hoá iterator, vòng đời tạm thời, callback bất đồng bộ, bộ
> nhớ thô (construct_at, launder, đối tượng từ byte), arena theo tick, khởi tạo tĩnh. **Đọc khi:**
> cấp phát hay giữ tài nguyên (bộ nhớ, socket, tệp, khoá, handle C); viết lớp có destructor; lưu con
> trỏ/tham chiếu/`string_view`/`span` vào thành viên hay qua tick; callback DB/mạng chạy sau; giữ
> tham chiếu vào vector rồi thêm phần tử; viết pool/arena; đọc struct từ bộ đệm gói tin; khai báo
> biến tĩnh.
> **Liên quan:** refs/03-kieu-gia-tri.md (KG-01, KG-17), refs/06-ham-lop-api.md (API-01, API-02,
> API-10), refs/10-bo-nho-cache-dod.md (BN), refs/12-dong-thoi.md (DT), refs/13-ub-on-dinh.md (UB),
> refs/18-game-mmo.md (MMO — handle thực thể).

## 1. Nền tảng [N]

### SH-01 [N] PHẢI — Mọi tài nguyên do một đối tượng RAII sở hữu; giải phóng nằm trong destructor

Bộ nhớ, khoá, socket, tệp, handle API C, slot trong pool: lấy trong constructor (hoặc factory), trả
trong destructor. Không cặp `lock()`/`unlock()`, `open`/`close` viết tay.

- **Vì sao:** cặp tay rò ở mọi đường ra bị quên: câu bảo vệ `return` sớm, `break`, ngoại lệ. Một
  `mutex_.lock()` đứng trước `if (queue_.empty()) return;` giữ khoá mãi mãi — luồng mạng kẹt, không
  log, không crash. Destructor chạy trên MỌI đường ra, kể cả khi unwinding.
- **Kiểm:** review; clang-tidy `bugprone-unused-raii` (guard tạm thời chết ngay); TSan.

```cpp
// ✓ Hộp thư luồng mạng → luồng game: scoped_lock nhả khoá ở mọi đường ra.
#include <cstdint>
#include <deque>
#include <mutex>
#include <optional>

namespace game::net {

class Inbox {
public:
    [[nodiscard]] std::optional<std::uint32_t> pop() {
        const std::scoped_lock lock(mutex_);
        if (queue_.empty()) return std::nullopt;
        const std::uint32_t front = queue_.front();
        queue_.pop_front();
        return front;
    }

private:
    std::mutex mutex_;
    std::deque<std::uint32_t> queue_;
};

} // namespace game::net
```

### SH-02 [N] PHẢI — Rule of zero: lớp có thành viên RAII không khai báo hàm đặc biệt nào

Không destructor, copy/move constructor hay gán tự viết khi các thành viên đã tự quản. Chỉ lớp bọc
trực tiếp một tài nguyên mới viết chúng (SH-09).

- **Vì sao:** khai báo destructor (kể cả `~Bag() {}` hay `= default`) chặn sinh move ngầm; copy vẫn
  được sinh (đã lỗi thời) nên `return std::move(bag);` SAO CHÉP cả vector — chậm và không ai thấy.
  Không khai báo gì thì copy/move/destructor đúng và `noexcept` theo thành viên.
- **Kiểm:** clang-tidy `cppcoreguidelines-special-member-functions`, `modernize-use-equals-default`;
  `static_assert(std::is_nothrow_move_constructible_v<T>)`.

```cpp
// ✓ Không khai báo hàm đặc biệt: move sinh ngầm, noexcept, chỉ chuyển con trỏ của string/vector.
#include <cstddef>
#include <cstdint>
#include <string>
#include <type_traits>
#include <vector>

namespace game::inv {

class Bag {
public:
    [[nodiscard]] std::size_t size() const noexcept { return items_.size(); }

private:
    std::string owner_;
    std::vector<std::uint32_t> items_;
};

static_assert(std::is_nothrow_move_constructible_v<Bag>);

} // namespace game::inv
```

### SH-03 [N] PHẢI — Sở hữu heap độc quyền là `std::unique_ptr` qua `std::make_unique`; CẤM `new`/`delete` trần

Heap chỉ khi cần: đối tượng lớn, đa hình, hay cần địa chỉ ổn định khi container chứa nó lớn lên.
Còn lại là giá trị (thành viên, `std::vector<T>`). Bộ đệm sắp ghi đè dùng
`std::make_unique_for_overwrite<std::byte[]>(n)` (C++20, không xoá 0).

- **Vì sao:** `new` trần không nói ai giải phóng; mỗi đường ra cần một `delete` (SH-01).
  `unique_ptr` với deleter mặc định cỡ bằng một con trỏ, move là hai lệnh ghi — không tốn phí so với
  con trỏ trần. `make_unique` ghi kiểu một lần và không lộ `new`.
- **Kiểm:** clang-tidy `cppcoreguidelines-owning-memory`, `cppcoreguidelines-no-malloc`,
  `modernize-make-unique`; LeakSanitizer (đi kèm ASan).

```cpp
// ✓ Zone có địa chỉ ổn định (hệ khác giữ Zone&) dù vector chủ cấp phát lại.
#include <cstdint>
#include <memory>
#include <vector>

namespace game::world {

class Zone {
public:
    explicit Zone(std::uint32_t id) noexcept : id_(id) {}

    [[nodiscard]] std::uint32_t id() const noexcept { return id_; }

private:
    std::uint32_t id_ = 0;
};

class ZoneRegistry {
public:
    Zone& open(std::uint32_t id) { return *zones_.emplace_back(std::make_unique<Zone>(id)); }

private:
    std::vector<std::unique_ptr<Zone>> zones_;
};

} // namespace game::world
```

### SH-04 [N] PHẢI — Con trỏ và tham chiếu trần không bao giờ sở hữu; không giữ chúng qua tick

`T&` = không null, không sở hữu; `T*` = có thể null, không sở hữu. Hợp đồng ghi khi nào nó hết hiệu
lực. Thứ phải sống qua tick (mục tiêu aggro, người theo sau) giữ ID/handle, tra lại mỗi tick
(refs/18-game-mmo.md).

- **Vì sao:** `Entity*` giữ qua tick treo khi mảng thực thể cấp phát lại hoặc thực thể bị xoá — lỗi
  chỉ hiện dưới tải thật, khi số thực thể vượt capacity. ID tra lại thì trả "không còn" an toàn.
- **Kiểm:** review; ASan `heap-use-after-free`.

```cpp
// ✓ Con trỏ trả về hợp lệ tới lần thêm/xoá kế tiếp; mục tiêu aggro giữ ID.
#include <algorithm>
#include <cstdint>
#include <span>

namespace game::world {

struct Entity {
    std::uint32_t id = 0;
    std::int32_t hp = 0;
};

[[nodiscard]] constexpr Entity* find_entity(std::span<Entity> entities, std::uint32_t id) noexcept {
    const auto found = std::ranges::find(entities, id, &Entity::id);
    return found == entities.end() ? nullptr : &*found;
}

struct Aggro {
    // ID, không phải Entity*: mảng thực thể có thể đổi giữa hai tick.
    std::uint32_t target_id = 0;
};

} // namespace game::world
```

### SH-05 [N] PHẢI — `std::shared_ptr` chỉ khi sở hữu chung thật; hàm dùng nhận `const T&`; cache giữ `weak_ptr`

Sở hữu chung thật: nhiều bên độc lập, không biết trước ai xong cuối (asset dùng chung giữa zone, cấu
hình bất biến chia cho nhiều luồng) — dùng `shared_ptr<const T>`. Hàm chỉ dùng tạm nhận `const T&`.
Cache và bộ quan sát giữ `weak_ptr`, gọi `lock()` mỗi lần dùng, dọn mục hết hạn định kỳ.

- **Vì sao:** sao chép `shared_ptr` là một RMW nguyên tử (x86: `lock add`/`lock inc` khi chép,
  `lock xadd` khi huỷ — đã đọc asm GCC 14, Clang 20 `-O2`): vài chục chu kỳ khi không tranh chấp,
  hàng trăm khi dòng cache của control block chuyền giữa các lõi (SH-15). Vòng
  `shared_ptr` (A giữ B, B giữ A) không bao giờ được giải phóng; cache giữ `shared_ptr` giữ mọi thứ
  từng được tra. `lock()` nguyên tử, không race như `expired()` rồi `lock()`.
- **Kiểm:** clang-tidy `performance-unnecessary-value-param`; review; LeakSanitizer với test tải.

```cpp
// ✓ Navmesh do các zone cùng giữ; cache chỉ quan sát; đường nóng nhận const&.
#include <cstdint>
#include <memory>
#include <unordered_map>

namespace game::world {

struct NavMesh {
    std::uint32_t id = 0;
    std::uint32_t triangle_count = 0;
};

[[nodiscard]] constexpr bool is_walkable(const NavMesh& mesh) noexcept {
    return mesh.triangle_count > 0;
}

class NavMeshCache {
public:
    // nullptr khi không còn zone nào giữ mesh này.
    [[nodiscard]] std::shared_ptr<const NavMesh> find(std::uint32_t id) const noexcept {
        const auto found = entries_.find(id);
        if (found == entries_.end()) return nullptr;
        return found->second.lock();
    }

    void remember(const std::shared_ptr<const NavMesh>& mesh) { entries_.insert_or_assign(mesh->id, mesh); }

private:
    std::unordered_map<std::uint32_t, std::weak_ptr<const NavMesh>> entries_;
};

} // namespace game::world
```

### SH-06 [N] CẤM — View (`std::string_view`, `std::span`) sống lâu hơn dữ liệu nó trỏ tới

View là tham số (nhận theo giá trị) và biến cục bộ ngắn. Làm thành viên hay giá trị trả về chỉ khi
hợp đồng ghi rõ chủ sở hữu và thời hạn (SH-17, API-10); lưu lâu thì sở hữu (`std::string`, `vector`).

- **Vì sao:** `Session{.player_name = first + " " + last}` với thành viên `string_view` trỏ vào chuỗi
  tạm đã huỷ ở cuối câu lệnh. Đã đo: Clang 20 bắt `std::string_view sv = std::string(…)` và
  `std::span<const int> s = make_vec()` (`-Wdangling-gsl`), trả `string_view` vào biến cục bộ
  (`-Wreturn-stack-address`); GCC 14/15 KHÔNG cảnh báo cả ba.
- **Kiểm:** Clang `-Wdangling-gsl`; clang-tidy `bugprone-dangling-handle`; ASan.

```cpp
// ✓ Lưu thì sở hữu; chỉ đọc trong lời gọi thì nhận view.
#include <string>
#include <string_view>

namespace game::net {

struct Session {
    std::string player_name;
};

[[nodiscard]] constexpr bool is_valid_name(std::string_view name) noexcept {
    return name.size() >= 3 && name.size() <= 16;
}

[[nodiscard]] inline Session make_session(std::string_view name) {
    return {.player_name = std::string(name)};
}

} // namespace game::net
```

### SH-07 [N] CẤM — Giữ tham chiếu, con trỏ, iterator vào container qua thao tác có thể vô hiệu hoá chúng

| Container | Thêm phần tử | Xoá phần tử |
|---|---|---|
| `vector`, `string`, `flat_map` | cấp phát lại: TẤT CẢ; không: từ vị trí chèn trở đi | từ vị trí xoá trở đi |
| `deque` | đầu/cuối: mọi iterator; tham chiếu/con trỏ CÒN; giữa: tất cả | đầu/cuối: phần tử bị xoá; giữa: tất cả |
| `unordered_map/set` | rehash: mọi iterator; tham chiếu/con trỏ CÒN | chỉ phần tử bị xoá |
| `map`, `set`, `list` | không gì | chỉ phần tử bị xoá |

- **Vì sao:** `const Member& leader = party.front(); party.push_back(joiner); leader.hp` chạy đúng hàng
  nghìn lần (còn capacity) rồi đọc bộ nhớ đã giải phóng ở lần cấp phát lại — lỗi phụ thuộc dữ liệu,
  không tái hiện ở máy dev. Giữ chỉ số, hoặc lấy lại tham chiếu sau thao tác.
- **Kiểm:** ASan; `_GLIBCXX_DEBUG` (libstdc++, bắt iterator vô hiệu); review.

```cpp
// ✓ Thêm trước, trả chỉ số; chỉ số không đổi khi vector cấp phát lại.
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::world {

struct Member {
    std::uint32_t id = 0;
    std::int32_t hp = 0;
};

[[nodiscard]] inline std::size_t join(std::vector<Member>& party, Member joiner) {
    party.push_back(joiner);
    return party.size() - 1;
}

} // namespace game::world
```

### SH-08 [N] PHẢI — Trả theo giá trị, không `return std::move(local)`; moved-from chỉ huỷ hoặc gán lại

Biến sắp trả không `const`. Cần trạng thái xác định sau khi lấy ruột: `std::exchange(x, {})`.

- **Vì sao:** prvalue được bỏ sao chép bắt buộc (C++17); biến cục bộ được NRVO hoặc move ngầm (C++23
  P2266: tên trả về là xvalue). `return std::move(local)` chặn NRVO; `const` local mất move ngầm:
  khi trình dịch không NRVO được thì thành copy. Thư viện chuẩn chỉ hứa moved-from "hợp lệ nhưng
  không xác định" ([lib.types.movedfrom]); có hứa rỗng: `unique_ptr`, `shared_ptr`. `std::string`
  sau move: libstdc++ 14 và libc++ 20 để rỗng (đã chạy), nhưng chuẩn không hứa (SSO cho phép giữ
  nội dung ngắn) — code dựa vào "sau move thì rỗng" dựa vào chi tiết cài đặt. Tham số ra: API-02.
- **Kiểm:** đã đo — `-Wpessimizing-move` (GCC, Clang; `-Wall`), `-Wredundant-move` (GCC `-Wextra`,
  Clang); trả `const` local thì KHÔNG trình dịch nào cảnh báo: clang-tidy
  `performance-no-automatic-move`; `bugprone-use-after-move`.

```cpp
// ✓ Lấy hết thư chờ: trả theo giá trị, để lại vector rỗng theo hợp đồng.
#include <string>
#include <utility>
#include <vector>

namespace game::net {

class Outbox {
public:
    void push(std::string message) { pending_.push_back(std::move(message)); }

    [[nodiscard]] std::vector<std::string> drain() noexcept { return std::exchange(pending_, {}); }

private:
    std::vector<std::string> pending_;
};

} // namespace game::net
```

## 2. Nâng cao [C]

### SH-09 [C] PHẢI — Lớp bọc tài nguyên viết đủ năm hàm đặc biệt; move `noexcept` để lại trạng thái rỗng

Copy `= delete` (hoặc sâu có chủ đích); move dùng `std::exchange` để nguồn thành rỗng; destructor và
`reset` chịu được trạng thái rỗng; tự gán `x = std::move(x)` không phá. Một lớp — một tài nguyên.

- **Vì sao:** thiếu một hàm là trình dịch sinh bản sao chép nông → đóng handle hai lần. Move không
  `noexcept` thì `std::vector` khi cấp phát lại dùng copy (`move_if_noexcept`), copy bị xoá thì mất
  đảm bảo mạnh. Lớp giữ hai tài nguyên trần: lấy cái thứ hai thất bại thì destructor không chạy, cái
  thứ nhất rò.
- **Kiểm:** clang-tidy `cppcoreguidelines-special-member-functions`,
  `performance-noexcept-move-constructor`, `bugprone-unhandled-self-assignment`.

```cpp
// ✓ Socket của API C: move-only, huỷ đóng đúng một lần, -1 là rỗng.
#include <type_traits>
#include <utility>

extern "C" int net_close(int handle) noexcept;

namespace game::net {

class UniqueSocket {
public:
    UniqueSocket() noexcept = default;
    explicit UniqueSocket(int handle) noexcept : handle_(handle) {}
    UniqueSocket(const UniqueSocket&) = delete;
    UniqueSocket& operator=(const UniqueSocket&) = delete;
    UniqueSocket(UniqueSocket&& other) noexcept : handle_(std::exchange(other.handle_, kNone)) {}
    UniqueSocket& operator=(UniqueSocket&& other) noexcept {
        reset(std::exchange(other.handle_, kNone));
        return *this;
    }
    ~UniqueSocket() { reset(kNone); }

    [[nodiscard]] int get() const noexcept { return handle_; }

    // Nhận handle mới, đóng handle cũ; tự gán: exchange trước nên old là kNone, không đóng gì.
    void reset(int handle) noexcept {
        const int old = std::exchange(handle_, handle);
        if (old == kNone) return;
        static_cast<void>(net_close(old));
    }

private:
    static constexpr int kNone = -1;
    int handle_ = kNone;
};

static_assert(std::is_nothrow_move_constructible_v<UniqueSocket>);
static_assert(std::is_nothrow_move_assignable_v<UniqueSocket>);

} // namespace game::net
```

### SH-10 [C] PHẢI — Con trỏ của API C: `unique_ptr` + deleter struct rỗng; con trỏ ra nhận bằng `std::out_ptr`

- **Vì sao:** deleter struct rỗng giữ `sizeof == sizeof(T*)` và gọi trực tiếp. Deleter con trỏ hàm
  (`decltype(&db_close)`) gấp đôi cỡ và có thể gọi gián tiếp; lấy địa chỉ hàm thư viện chuẩn
  (`&std::fclose`) còn là unspecified ([namespace.std]). Lambda trong `decltype` ở header: mỗi TU một
  kiểu closure — rủi ro ODR. `std::out_ptr` (C++23, có ở cả ba thư viện) thay cặp
  `T* raw; f(&raw); p.reset(raw);`.
- **Kiểm:** `static_assert(sizeof(…) == sizeof(T*))`; LeakSanitizer.

```cpp
// ✓ Kết nối DB qua API C kiểu `int db_open(const char*, DbConn**)`.
#include <memory>

extern "C" {
struct DbConn;
int db_open(const char* dsn, DbConn** out) noexcept;
void db_close(DbConn* conn) noexcept;
}

namespace game::db {

struct ConnCloser {
    void operator()(DbConn* conn) const noexcept { db_close(conn); }
};

using Connection = std::unique_ptr<DbConn, ConnCloser>;
static_assert(sizeof(Connection) == sizeof(DbConn*));

// Rỗng khi thất bại; tầng trên đổi thành std::expected kèm mã lỗi (refs/05-loi-hop-dong.md).
[[nodiscard]] inline Connection connect(const char* dsn) noexcept {
    Connection conn;
    if (db_open(dsn, std::out_ptr(conn)) != 0) return nullptr;
    return conn;
}

} // namespace game::db
```

### SH-11 [C] CẤM — Callback bất đồng bộ bắt `this`, tham chiếu hay con trỏ tới đối tượng có thể chết trước nó

Callback DB/mạng/hẹn giờ mang dữ liệu theo giá trị (ID, kết quả); khi chạy thì tra lại đối tượng,
bỏ kết quả nếu nó đã đi. Chỉ bắt `this` của thứ có hợp đồng sống lâu hơn nguồn callback (ghi trong
comment). Đối tượng do `shared_ptr` quản: bắt `weak_from_this()`, không bắt `shared_from_this()`
(giữ phiên sống vô hạn).

- **Vì sao:** người chơi ngắt kết nối khi truy vấn DB đang chạy: `[this]` của `Session` treo, callback
  ghi vào heap đã giải phóng trên luồng game — crash ngẫu nhiên dưới tải. `[=]` bắt `this` ngầm (lỗi
  thời từ C++20). `shared_from_this()` trong constructor ném `std::bad_weak_ptr` (C++17).
- **Kiểm:** clang-tidy `cppcoreguidelines-misleading-capture-default-by-value`,
  `bugprone-incorrect-enable-shared-from-this`; ASan với test ngắt kết nối giữa chừng.

```cpp
// ✓ Kết quả mang account theo giá trị; phiên đã ngắt thì kết quả bị bỏ.
#include <cstdint>
#include <functional>
#include <unordered_map>

namespace game::net {

struct GoldResult {
    std::uint64_t account = 0;
    std::int64_t gold = 0;
};

// Hợp đồng: done chạy trên luồng game; mọi callback xong trước khi SessionTable bị huỷ.
void query_gold_async(std::uint64_t account, std::function<void(GoldResult)> done);

class SessionTable {
public:
    void refresh_gold(std::uint64_t account) {
        query_gold_async(account, [this](GoldResult result) { apply(result); });
    }

private:
    void apply(GoldResult result) noexcept {
        const auto found = gold_by_account_.find(result.account);
        if (found == gold_by_account_.end()) return;
        found->second = result.gold;
    }

    std::unordered_map<std::uint64_t, std::int64_t> gold_by_account_;
};

} // namespace game::net
```

### SH-12 [C] CẤM — Gắn tham chiếu/view vào kết quả hàm gọi trên tạm thời; range-for trên thành viên của tạm thời

Chỉ `const T&`/`T&&` gắn TRỰC TIẾP vào prvalue mới kéo dài vòng đời: `const auto& name =
make_session().name();` treo. Range-for `for (… : load_zone().entities())`: C++23 (P2718) kéo dài mọi
tạm thời trong biểu thức range, nhưng đã đo — GCC 14 CHƯA có (`__cpp_range_based_for == 201603`,
ASan `stack-use-after-scope`), GCC 15 và Clang 20 có (`202211`). Còn build bằng GCC 14 thì đặt tên
cho tạm thời.

- **Vì sao:** tạm thời chết ở cuối biểu thức đầy đủ; hàm trả tham chiếu vào nó không mang theo vòng
  đời. Đã đo: GCC 14/15 `-Wdangling-reference` bắt `make_session().name()`; Clang 20 chỉ bắt khi hàm
  có `lifetimebound` (SH-17); vòng range-for treo trên GCC 14 thì không ai cảnh báo.
- **Kiểm:** `-Wdangling-reference` (đã đo: GCC 14 bật trong `-Wall`, GCC 15 chuyển sang `-Wextra`);
  ASan; review mọi `for (… : f().g())`.

```cpp
// ✓ Tạm thời có tên: vòng đời rõ trên mọi trình dịch (`: load_zone().entities()` treo ở GCC 14).
#include <cstdint>
#include <vector>

namespace game::world {

struct Zone {
    std::vector<std::uint32_t> ids{1, 2, 3};

    [[nodiscard]] const std::vector<std::uint32_t>& entities() const noexcept { return ids; }
};

[[nodiscard]] Zone load_zone();

[[nodiscard]] inline std::uint32_t sum_ids() {
    const Zone zone = load_zone();
    std::uint32_t sum = 0;
    for (const std::uint32_t id : zone.entities()) {
        sum += id;
    }
    return sum;
}

} // namespace game::world
```

## 3. Thần thoại [T]

### SH-13 [T] NÊN — Bộ nhớ thô: `std::construct_at`/`std::destroy_at`; con trỏ tính lại từ byte qua `std::launder`

Chỉ khi `std::optional`/`std::variant`/container không dùng được (pool tự quản, đo đã chứng minh).
Giữ con trỏ do `construct_at` trả về, hoặc tính lại từ mảng byte rồi `std::launder`.

- **Vì sao:** `reinterpret_cast<T*>(storage_.data())` cho con trỏ trỏ vào MẢNG BYTE, không vào T sống
  ở đó (không pointer-interconvertible); truy cập qua nó là UB, trình dịch được giả định không có T.
  `std::launder` trả con trỏ tới T đang sống tại địa chỉ ấy (tiền điều kiện: T đang sống). Từ C++20,
  thành viên const/tham chiếu không còn chặn thay thế trong suốt ([basic.life]); vẫn cần launder khi
  đi từ byte hay khi kiểu khác. `std::construct_at` dùng được trong constexpr (C++20); placement new
  trong constexpr là C++26 (P2747).
- **Kiểm:** ASan + UBSan; test qua `static_assert` (constexpr bắt UB vòng đời).

```cpp
// ✓ Ô lưu của pool: không cấp phát, tối đa một T; như optional rút gọn.
#include <array>
#include <cstddef>
#include <memory>
#include <new>
#include <utility>

namespace game::mem {

template <class T>
class Slot {
public:
    Slot() noexcept = default;
    Slot(const Slot&) = delete;
    Slot& operator=(const Slot&) = delete;
    Slot(Slot&&) = delete;
    Slot& operator=(Slot&&) = delete;
    ~Slot() { reset(); }

    template <class... Args>
    T& emplace(Args&&... args) {
        reset();
        T& object = *std::construct_at(address(), std::forward<Args>(args)...);
        // Đặt cờ SAU construct_at: constructor ném thì ô vẫn rỗng.
        alive_ = true;
        return object;
    }

    void reset() noexcept {
        if (!alive_) return;
        alive_ = false;
        std::destroy_at(std::launder(address()));
    }

private:
    // Chỉ lấy địa chỉ ô; đọc đối tượng luôn qua std::launder (SH-13).
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    [[nodiscard]] T* address() noexcept { return reinterpret_cast<T*>(storage_.data()); }

    alignas(T) std::array<std::byte, sizeof(T)> storage_{};
    bool alive_ = false;
};

} // namespace game::mem
```

### SH-14 [T] PHẢI — Đối tượng từ bộ đệm byte: `std::memcpy` vào đối tượng cục bộ; CẤM `reinterpret_cast` con trỏ bộ đệm

`std::start_lifetime_as` (C++23, P2590) là cách chuẩn để "xem" byte như đối tượng tại chỗ, nhưng đã
đo: không có ở GCC 14, GCC 15, Clang 20 + libc++ 20 (không có `__cpp_lib_start_lifetime_as`). Đến khi
có: kiểm độ dài, `memcpy` vào biến cục bộ kiểu sao chép tầm thường (bố cục chốt theo KG-17).

- **Vì sao:** trong bộ đệm nhận không có đối tượng `WireHeader` nào: đọc qua
  `reinterpret_cast<const WireHeader*>` vi phạm strict aliasing; gói tin ở offset lẻ còn lệch căn lề
  (UB; bản vector hoá dùng lệnh nạp căn lề thì fault). Tạo đối tượng ngầm (P0593, C++20) chỉ xảy ra ở
  thao tác bắt đầu vòng đời mảng byte/`malloc`/`operator new`/`memcpy`, con trỏ ép từ byte vẫn cần
  `std::launder`, và không chữa căn lề. `memcpy` cỡ cố định biên dịch thành lệnh nạp thường ở `-O2`
  — không tốn phí.
- **Kiểm:** UBSan `alignment`; clang-tidy `cppcoreguidelines-pro-type-reinterpret-cast`; fuzz parser
  (refs/15-kiem-thu.md).

```cpp
// ✓ Header gói tin từ client: kiểm độ dài trước, memcpy vào biến cục bộ.
#include <bit>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <optional>
#include <span>
#include <type_traits>

namespace game::proto {

struct WireHeader {
    std::uint16_t length = 0;
    std::uint16_t opcode = 0;
    std::uint32_t sequence = 0;
};

static_assert(std::is_trivially_copyable_v<WireHeader> && sizeof(WireHeader) == 8);
static_assert(std::endian::native == std::endian::little, "memcpy nguyên khối giả định LE (KG-17)");

// Thiếu byte là gói xấu từ client, không phải lỗi lập trình.
[[nodiscard]] inline std::optional<WireHeader> read_header(std::span<const std::byte> packet) noexcept {
    if (packet.size() < sizeof(WireHeader)) return std::nullopt;
    WireHeader header;
    std::memcpy(&header, packet.data(), sizeof(WireHeader));
    return header;
}

} // namespace game::proto
```

### SH-15 [T] NÊN — Biết chi phí thật của `shared_ptr`: một hay hai khối, ai giữ khối nào, khi nào nguyên tử

| Điều | Sự thật (đã đọc mã libstdc++ 14, libc++ 20) |
|---|---|
| Cỡ | 2 con trỏ (đối tượng + control block) |
| `make_shared` | MỘT cấp phát: đối tượng nằm trong control block |
| `weak_ptr` còn sống | giữ control block; với `make_shared` là giữ cả `sizeof(T)` byte dù T đã huỷ |
| Sao chép | libstdc++: bỏ nguyên tử khi `__libc_single_threaded` (glibc ≥ 2.32) còn đúng — mất ngay khi tạo luồng thứ hai; libc++: luôn `__atomic_add_fetch` |
| Constructor bí danh | `shared_ptr<U>(owner, &owner->field)` trỏ vào thành viên, giữ cả chủ |

- **Vì sao:** máy chủ MMO đa luồng nên mọi sao chép là nguyên tử. Cache `weak_ptr` (SH-05) trên đối
  tượng `sizeof` lớn tạo bằng `make_shared` giữ cả khối nhớ tới khi `weak_ptr` cuối biến mất: tạo qua
  `unique_ptr` rồi chuyển sang `shared_ptr` để có hai khối. Đối tượng chỉ sống trên luồng game mà sao
  chép trên đường nóng đo được: đếm xâm nhập không nguyên tử hoặc handle + arena, kèm số đo.
- **Kiểm:** profiler (lệnh `lock` nóng); heap profiler cho khối bị `weak_ptr` giữ.

```cpp
// ✓ Ô địa hình 128 KB nội tuyến: hai khối để weak_ptr trong cache chỉ giữ control block.
#include <array>
#include <cstdint>
#include <memory>

namespace game::world {

using Heights = std::array<std::int16_t, 256UZ * 256UZ>;

struct HeightTile {
    Heights heights{};
};

using SharedTile = std::shared_ptr<const HeightTile>;

[[nodiscard]] inline SharedTile share_tile() {
    return std::make_unique<const HeightTile>();
}

// Con trỏ bí danh: trỏ vào mảng, chia vòng đời với cả ô.
[[nodiscard]] inline std::shared_ptr<const Heights> share_heights(const SharedTile& tile) noexcept {
    return {tile, &tile->heights};
}

} // namespace game::world
```

### SH-16 [T] CÓ THỂ — Dữ liệu nháp của một tick sống trong arena; mọi con trỏ vào đó chết cuối tick

`std::pmr::monotonic_buffer_resource` trên bộ đệm tái dùng; container nháp là `std::pmr::…`; cuối
tick huỷ mọi container nháp RỒI `release()`. Không lưu gì từ arena sang tick sau (allocator:
refs/10-bo-nho-cache-dod.md).

- **Vì sao:** cấp phát thành cộng con trỏ, không khoá, không phân mảnh; vòng đời cả tick gói vào một
  lệnh. Bẫy: (1) container chứa phần tử có destructor không tầm thường (`pmr::string`) huỷ sau
  `release()` đọc bộ nhớ đã thu hồi; (2) ASan KHÔNG thấy dùng-sau-release vì bộ đệm vẫn thuộc đối
  tượng — build debug cho arena dùng `std::pmr::new_delete_resource()` (ASan thấy) hoặc
  `ASAN_POISON_MEMORY_REGION`; (3) thành viên khởi tạo theo thứ tự khai báo: bộ đệm đứng trước
  resource.
- **Kiểm:** ASan với build arena-qua-heap; đối tượng chủ (256 KB) đặt trên heap, không trên ngăn xếp.

```cpp
// ✓ Arena 256 KB cho danh sách AOI trong tick; vượt ngân sách thì xin thêm từ heap.
#include <array>
#include <cstddef>
#include <cstdint>
#include <memory_resource>
#include <vector>

namespace game::sim {

class TickScratch {
public:
    // Kết quả cấp phát từ arena: phải bị huỷ trước end_tick().
    [[nodiscard]] std::pmr::vector<std::uint32_t> make_id_list() { return std::pmr::vector<std::uint32_t>(&arena_); }

    void end_tick() noexcept { arena_.release(); }

private:
    // Khai báo TRƯỚC arena_: thành viên khởi tạo theo thứ tự khai báo.
    std::array<std::byte, 256UZ * 1024UZ> buffer_{};
    std::pmr::monotonic_buffer_resource arena_{buffer_.data(), buffer_.size()};
};

} // namespace game::sim
```

### SH-17 [T] NÊN — Hàm trả tham chiếu/view vào đối số gắn `GAME_LIFETIMEBOUND`; biết công cụ nào bắt gì

`[[clang::lifetimebound]]` trên tham số, hoặc sau danh sách tham số cho `*this`, cho Clang bắt nơi gọi
truyền tạm thời. GCC báo `-Wattributes` với thuộc tính lạ nên bọc macro. `[[gnu::no_dangling]]`
(GCC 14+) tắt dương tính giả của `-Wdangling-reference`; `[[clang::lifetime_capture_by(X)]]`
(Clang 20) cho hàm cất tham chiếu vào X.

| Tình huống (đã đo) | GCC 14, 15 | Clang 20 |
|---|---|---|
| `const T& r = pick(T{}, …)` trả lại tham số | `-Wdangling-reference` | chỉ khi có lifetimebound |
| `const auto& r = make().member()` | `-Wdangling-reference` | chỉ khi `*this` lifetimebound |
| `string_view`/`span` từ `string`/`vector` tạm | không | `-Wdangling-gsl` |
| `const auto& m = std::max(1, 2)` | `-Wdangling-reference` | `-Wdangling` |
| trả `string_view` vào biến cục bộ | không | `-Wreturn-stack-address` |

- **Vì sao:** treo là UB im lặng; mỗi trình dịch thấy một phần: CI build bằng cả hai (refs/14) cộng
  annotation phủ gần hết các ca thường gặp, không tốn phí chạy.
- **Kiểm:** Clang `-Wdangling` (mặc định bật); GCC `-Wdangling-reference` (`-Wall` ở GCC 14, `-Wextra`
  ở GCC 15).

```cpp
// ✓ View vào bộ đệm gói tin: Clang báo `auto view = make_packet().payload();` (đã đo).
#include <cstddef>
#include <span>
#include <vector>

#if __has_cpp_attribute(clang::lifetimebound)
#define GAME_LIFETIMEBOUND [[clang::lifetimebound]]
#else
#define GAME_LIFETIMEBOUND
#endif

namespace game::net {

class Packet {
public:
    [[nodiscard]] std::span<const std::byte> payload() const noexcept GAME_LIFETIMEBOUND { return bytes_; }

private:
    std::vector<std::byte> bytes_;
};

} // namespace game::net
```

### SH-18 [T] PHẢI — Dữ liệu tĩnh khởi tạo lúc biên dịch (`constexpr`/`constinit`); không đối tượng tĩnh có destructor

- **Vì sao:** khởi tạo động của biến toàn cục giữa các TU không có thứ tự ("static initialization
  order fiasco"); huỷ ở `exit` chạy ngược thứ tự dựng, nên luồng còn chạy hay destructor tĩnh khác
  dùng nó là use-after-free lúc tắt máy chủ. `constinit` báo lỗi biên dịch nếu khởi tạo không phải
  hằng. Đã đo (GCC 14, Clang 20, `-O2`): đọc `extern thread_local` từ TU khác phải kiểm và gọi hàm
  khởi tạo TLS `_ZTH…` mỗi lần; khai `constinit` thì chỉ còn nạp offset TLS rồi nạp `%fs:` thẳng,
  không kiểm, không gọi hàm (tệp thực thi; trong `.so` build `-fPIC` cả hai còn gọi
  `__tls_get_addr`, `constinit` chỉ bỏ phần kiểm và `_ZTH…`). Static cục bộ hàm khởi tạo an toàn luồng nhưng mỗi lời gọi đọc cờ
  guard, lần đầu khoá (`__cxa_guard_acquire`).
- **Kiểm:** clang-tidy `cert-err58-cpp`, `bugprone-dynamic-static-initializers`,
  `cppcoreguidelines-avoid-non-const-global-variables`; Clang `-Wglobal-constructors`,
  `-Wexit-time-destructors`.

```cpp
// ✓ Bảng kỹ năng là hằng biểu thức; bộ đếm theo luồng constinit, không khởi tạo động.
#include <array>
#include <cstdint>
#include <string_view>

namespace game::combat {

struct SkillInfo {
    std::uint16_t id = 0;
    std::string_view name;
    std::int32_t base_damage = 0;
};

inline constexpr std::array kSkills{
    SkillInfo{.id = 1, .name = "slash", .base_damage = 40},
    SkillInfo{.id = 2, .name = "fireball", .base_damage = 75},
};

// Bộ đếm riêng từng luồng, luồng metrics gộp định kỳ (KTR-18): lệch KTR-04 có chủ đích.
// NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables): xem dòng trên (KTR-04).
inline constinit thread_local std::uint64_t t_skills_cast = 0;

} // namespace game::combat
```

## Kiểm nhanh

- [ ] Mọi tài nguyên (khoá, socket, handle C, bộ nhớ) có chủ RAII; không cặp lock/unlock tay? (SH-01)
- [ ] Lớp không bọc trực tiếp tài nguyên không khai báo hàm đặc biệt nào? (SH-02)
- [ ] Không `new`/`delete`/`malloc` trần; heap độc quyền là `make_unique`? (SH-03)
- [ ] Không con trỏ/tham chiếu trần giữ qua tick; thứ sống lâu giữ ID/handle? (SH-04)
- [ ] Mỗi `shared_ptr` có lý do sở hữu chung thật; đường nóng nhận `const T&`; cache giữ `weak_ptr`? (SH-05)
- [ ] Không thành viên/giá trị trả `string_view`/`span` thiếu hợp đồng thời hạn? (SH-06, SH-17)
- [ ] Không giữ tham chiếu/iterator vào container qua thêm/xoá? (SH-07)
- [ ] Không `return std::move(local)`, không trả `const` local, không đọc moved-from? (SH-08)
- [ ] Lớp bọc tài nguyên đủ năm hàm, move `noexcept`, tự gán an toàn? (SH-09)
- [ ] Callback bất đồng bộ không bắt `this`/tham chiếu của thứ có thể chết trước? (SH-11)
- [ ] Không range-for/tham chiếu trên thành viên của tạm thời (GCC 14 còn treo)? (SH-12)
- [ ] Không `reinterpret_cast` bộ đệm byte thành struct; memcpy sau khi kiểm độ dài? (SH-14)
