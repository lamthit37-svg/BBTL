# KTR · Kiến trúc và module: tầng, phụ thuộc, cấu hình, log, triển khai

> **Phạm vi:** chia tầng và hướng phụ thuộc, thiết kế vật lý (header, `detail`, khai báo trước),
> trạng thái toàn cục, cấu hình và cờ tính năng, log, nguồn thời gian, tiêm phụ thuộc, lõi thuần,
> ECS/DOD, phiên bản hoá dữ liệu, modules C++20, kiểm tầng tự động, zone/shard, triển khai không
> dừng, quan sát. **Đọc khi:** tạo module hay thư mục mới; thêm `#include` sang module khác; muốn
> viết singleton, biến toàn cục, `static` khả biến; thêm hằng gameplay, cấu hình, cờ tính năng; đổi
> định dạng lưu hay giao thức; thiết kế dịch vụ liên zone; chuẩn bị triển khai; thêm log/metric.
> **Liên quan:** refs/06-ham-lop-api.md (API-12 pimpl, API-16 C ABI cho plugin),
> refs/12-dong-thoi.md (DT-01 hộp thư, DT-08 mô hình luồng, DT-12 cấu hình nóng),
> refs/18-game-mmo.md (MMO: tick, giao thức, chuyển zone), refs/14-build-toolchain.md (BD: CMake).

## 1. Nền tảng [N]

### KTR-01 [N] PHẢI — Tầng phụ thuộc một chiều: một module chỉ include module mà cột "Được dùng" của bảng tầng cho phép

| Tầng | Namespace | Chứa | Được dùng |
|---|---|---|---|
| core | `game::core` | check, log sink, id mạnh, `Tick`/`TickSpan` (MMO-03), cấu trúc dữ liệu chung | thư viện chuẩn |
| math | `game::math` | vectơ, fixed-point, hình học | core |
| proto | `game::proto` | kiểu thông điệp, tuần tự hoá, phiên bản giao thức | core, math |
| net, db | `game::net`, `game::db` | socket, khung gói, phiên kết nối; lưu trữ | core, proto |
| world, sim | `game::world`, `game::sim` | thực thể, AOI, tick, hệ thống | core, math, proto |
| gameplay | `game::combat`, `game::inv`… | luật chơi | world/sim và thấp hơn |
| app | `game::app` | `main`, nối dây, đọc cấu hình, vòng tick | mọi tầng |

Module dùng chung ở tầng core: `game::config` (cấu hình có kiểu), `game::obs` (log, số liệu,
histogram), `game::rng` (PRNG tất định), `game::conc` (hàng đợi, đồng bộ), `game::mem` (pool, arena).
Gameplay: một namespace mỗi luật chơi (`combat`, `inv`, `econ`, `trade`, `craft`, `loot`, `chat`,
`anticheat`, `account`…). `game::cluster` (định tuyến giữa zone) thuộc tầng app. Test và benchmark:
`game::test`, `game::bench`, chỉ trong target test. Client có tầng riêng (`game::anim`, `game::render`…)
cùng nguyên tắc một chiều, dựa trên core và math. Namespace mới ngoài bảng thì thêm vào bảng (và bảng
của KTR-15) trong cùng thay đổi.

world/sim và gameplay dùng **kiểu** của proto nhưng không dùng **IO** của net/db: chúng nhận thông
điệp đã giải mã và ghi sự kiện ra; app nối sự kiện với net/db.

Chia world/sim với gameplay: sim giữ cơ chế không biết luật — vòng tick, bảng pha (MMO-11), lưu trữ
thành phần, handle, AOI. Luật và dữ liệu luật — buff, hồi chiêu, sát thương, rơi đồ, giá — ở module
gameplay (`game::combat`, `game::loot`…), đăng ký hàm hệ thống của mình vào bảng pha. Mẫu ngắn trong
bộ này có khi đặt luật ở `game::sim` cho gọn; dự án theo câu này.

- **Vì sao:** phụ thuộc ngược làm mọi thứ biên dịch lại khi tầng trên đổi, kéo socket và DB vào test
  luật chơi, và mở đường cho phụ thuộc vòng. Hướng một chiều là điều kiện để test từng tầng riêng và
  tách tiến trình sau này (zone, gateway, dịch vụ).
- **Kiểm:** CMake mỗi tầng một target, include dir riêng (KTR-15); review mọi include khác module.

```text
app ─► gameplay ─► world/sim ─► proto ─► math ─► core
  └──► net, db ──────────────────► proto
```

### KTR-02 [N] CẤM — Phụ thuộc vòng giữa module; tầng dưới báo cho tầng trên bằng dữ liệu (sự kiện), không bằng lời gọi ngược

Cắt vòng theo thứ tự: (1) chuyển kiểu dùng chung xuống tầng thấp hơn; (2) tầng dưới ghi sự kiện
vào hộp ra, tầng trên đọc; (3) concept/tham số template (KTR-11). Không "lách" bằng khai báo trước
hay `void*`. ✗ điển hình: `combat.cpp` gọi `net::Server::broadcast()` để báo sát thương.

- **Vì sao:** vòng phụ thuộc biến hai module thành một khối không test riêng được; khai báo trước
  chỉ che vòng ở mức include, liên kết và thứ tự khởi tạo vẫn vướng. Sự kiện là dữ liệu: ghi lại,
  phát lại (replay), gửi qua mạng hay sang luồng khác đều được.
- **Kiểm:** script tầng (KTR-15) báo cạnh ngược; `misc-header-include-cycle` (clang-tidy) bắt vòng
  include trực tiếp.

```cpp
// ✓ combat không biết net: ghi sự kiện vào hộp ra; app biến sự kiện thành gói tin.
#include <algorithm>
#include <cstdint>
#include <limits>
#include <vector>

namespace game::proto {

enum class EntityId : std::uint32_t {};

struct DamageEvent {
    EntityId target{};
    std::int32_t amount = 0;
};

} // namespace game::proto

namespace game::combat {

struct Health {
    std::int32_t hp = 0;
};

// Chỉ trạng thái vào, sự kiện ra: không include net/, không callback. outbox là hộp ra của tick,
// tái dùng giữa các tick (ngoại lệ của API-02). Tính trong int64 rồi kẹp: không tràn với mọi int32.
inline void apply_hit(Health& health, const proto::DamageEvent& hit, std::vector<proto::DamageEvent>& outbox) {
    const std::int64_t left = std::int64_t{health.hp} - hit.amount;
    constexpr std::int64_t kMaxHp = std::numeric_limits<std::int32_t>::max();
    health.hp = static_cast<std::int32_t>(std::clamp<std::int64_t>(left, 0, kMaxHp));
    outbox.push_back(hit);
}

} // namespace game::combat
```

### KTR-03 [N] PHẢI — Mỗi header tự đủ và nói về một khái niệm; CI biên dịch từng header thành một TU riêng

Include đủ thứ mình dùng: DD-05. Quy tắc ở đây là kiểm tự động: header
nào include thiếu (dựa vào include của TU gọi) thì CI đỏ.

- **Vì sao:** header không tự đủ biên dịch được hay không tuỳ thứ tự include ở nơi dùng; đổi thứ tự
  hay xoá một include ở chỗ khác làm vỡ module không liên quan. Một khái niệm một header giữ đồ thị
  include thưa: sửa một kiểu chỉ biên dịch lại nơi dùng nó.
- **Kiểm:** target `header_check` dưới đây; clang-tidy `misc-include-cleaner` (include thừa/thiếu).

```cmake
# Mỗi header công khai thành một .cpp chỉ gồm hai dòng include nó (kiểm luôn #pragma once).
file(GLOB_RECURSE game_headers CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/src/*.hpp)
foreach(header IN LISTS game_headers)
  file(RELATIVE_PATH relative "${PROJECT_SOURCE_DIR}" "${header}")
  string(MAKE_C_IDENTIFIER "${relative}" stem)
  set(unit "${PROJECT_BINARY_DIR}/header_check/${stem}.cpp")
  file(CONFIGURE OUTPUT "${unit}" CONTENT "#include \"${header}\"\n#include \"${header}\"\n")
  list(APPEND header_units "${unit}")
endforeach()
add_library(header_check OBJECT ${header_units})
# game_all_modules: target INTERFACE link mọi module (khung: templates/project/CMakeLists.txt).
target_link_libraries(header_check PRIVATE game_all_modules game::warnings)
```

### KTR-04 [N] CẤM — Singleton, biến toàn cục khả biến và `static` cục bộ khả biến; trạng thái thuộc một đối tượng ngữ cảnh truyền tường minh

`app` sở hữu các dịch vụ (log sink, đồng hồ, cấu hình, bộ cấp id) trong một struct ngữ cảnh mỗi
zone/tiến trình, truyền xuống bằng tham chiếu. Hằng `constexpr`/`constinit` không khả biến thì được.

- **Vì sao:** singleton là phụ thuộc ẩn (chữ ký hàm nói dối), dính thứ tự khởi tạo/huỷ tĩnh giữa các
  TU (refs/04 SH-18), là trạng thái chung giữa các zone (race, DT-02) và giữa các test (test chạy
  song song nhiễu nhau, không chạy được hai zone trong một tiến trình test).
- **Kiểm:** clang-tidy `cppcoreguidelines-avoid-non-const-global-variables`; grep `static .*instance()`.

```cpp
// ✗ Singleton: phụ thuộc ẩn, chung giữa mọi zone và mọi test.
#include <cstdint>

class IdRegistry {
public:
    static IdRegistry& instance() {
        static IdRegistry registry;
        return registry;
    }
    std::uint32_t next = 1;
};

inline std::uint32_t spawn_monster() {
    return IdRegistry::instance().next++;
}
```

```cpp
// ✓ Ngữ cảnh tường minh: app sở hữu dịch vụ của zone; test dựng ngữ cảnh riêng.
#include <cstdint>

namespace game::world {

// Số thứ tự lần sinh trong một zone (log, replay); tham chiếu thực thể vẫn là handle (MMO-04).
// 64 bit nên không quay vòng trong đời máy chủ, không bao giờ cấp trùng.
enum class SpawnSerial : std::uint64_t {};

// Mỗi zone một bộ cấp; hai zone (hay hai test) trong cùng tiến trình không đụng nhau.
class SerialAllocator {
public:
    [[nodiscard]] SpawnSerial allocate() noexcept { return SpawnSerial{next_++}; }

private:
    std::uint64_t next_ = 1;
};

struct ZoneServices {
    SerialAllocator serials;
    // Log sink, đồng hồ, cấu hình: thành viên ở đây, không phải biến toàn cục.
};

[[nodiscard]] inline SpawnSerial spawn_monster(ZoneServices& services) noexcept {
    return services.serials.allocate();
}

} // namespace game::world
```

### KTR-05 [N] PHẢI — Cấu hình và dữ liệu nội dung là dữ liệu: struct có mặc định có tên, kiểm hợp lệ một lần khi nạp, bất biến sau đó

Tick rate, bán kính tầm nhìn, cổng, giới hạn người chơi, bảng vật phẩm/kỹ năng đọc từ tệp vào struct;
`validate` trả `std::expected`; code gameplay chỉ nhận `const Config&` đã hợp lệ. Mỗi trường số có
cả cận dưới lẫn cận trên. Khoá lạ hay trùng trong tệp là lỗi nạp, không bị bỏ qua: gõ nhầm
`tick_hzz` không được âm thầm thành giá trị mặc định. Lỗi nạp lúc khởi động thì tiến trình không mở
cổng; lúc nạp lại nóng thì giữ bản cũ (KTR-10). Khoá chuỗi trong dữ liệu nội dung đổi thành chỉ số
một lần lúc nạp (refs/09 HN-09).

- **Vì sao:** hằng rải trong code thì đổi cân bằng game phải build lại và triển khai lại; kiểm hợp lệ
  rải rác thì có đường đi quên kiểm. Một điểm kiểm ở ranh giới nạp: phần còn lại tin dữ liệu.
- **Kiểm:** review: số gameplay mới trong `.cpp` (ngoài mặc định có tên) bị từ chối; test nạp mọi tệp
  cấu hình mẫu trong CI, kèm tệp có khoá lạ và giá trị ngoài miền phải bị từ chối.

```cpp
// ✓ Cấu hình zone: mặc định có tên, mỗi trường có miền, ràng buộc chéo kiểm một lần khi nạp.
#include <cstdint>
#include <expected>

namespace game::config {

enum class [[nodiscard]] ConfigError : std::uint8_t {
    kTickRateOutOfRange,
    kViewRadiusOutOfRange,
    kCellSmallerThanView,
    kPlayerSlotsOutOfRange,
};

struct ZoneConfig {
    std::int32_t tick_hz = 20;
    std::int32_t view_radius_m = 60;
    // Không nhỏ hơn view_radius_m thì truy vấn 3×3 ô là đủ (refs/18 MMO-10).
    std::int32_t aoi_cell_m = 64;
    std::int32_t max_players = 2'000;
};

// Chạy khi khởi động và mỗi lần nạp lại nóng; mặc định phải hợp lệ (static_assert dưới).
[[nodiscard]] constexpr std::expected<ZoneConfig, ConfigError> validate(const ZoneConfig& config) noexcept {
    const bool is_tick_valid = config.tick_hz >= 1 && config.tick_hz <= 128;
    const bool is_radius_valid = config.view_radius_m >= 1 && config.view_radius_m <= 1'000;
    const bool is_slots_valid = config.max_players >= 1 && config.max_players <= 20'000;
    if (!is_tick_valid) return std::unexpected(ConfigError::kTickRateOutOfRange);
    if (!is_radius_valid) return std::unexpected(ConfigError::kViewRadiusOutOfRange);
    if (config.aoi_cell_m < config.view_radius_m) return std::unexpected(ConfigError::kCellSmallerThanView);
    if (!is_slots_valid) return std::unexpected(ConfigError::kPlayerSlotsOutOfRange);
    return config;
}

static_assert(validate(ZoneConfig{}).has_value());
static_assert(!validate({.view_radius_m = 0}).has_value());

} // namespace game::config
```

### KTR-06 [N] PHẢI — Log đi qua một giao diện hẹp ở tầng core; thư viện không ghi thẳng ra stdout/stderr hay tệp

Giao diện: mức, `enabled(level)`, `write(level, line)`. `app` cài đích (tệp, hàng đợi sang luồng log,
bộ nhớ cho test). Kiểm mức trước khi định dạng: refs/09 HN-06. Log có cấu trúc và trace id: KTR-18.

- **Vì sao:** `printf` rải trong thư viện không chuyển hướng, không tắt, không lọc được, và ghi đĩa
  ngay trên luồng zone. Giao diện hẹp cho phép đích bất đồng bộ (luồng zone không bao giờ chặn vì log,
  DT-08) và test kiểm được nội dung log.
- **Kiểm:** grep `printf|std::cout|std::cerr|std::print\(` ngoài `app/` và `core/log`.

```cpp
// ✓ Giao diện log hẹp; chuỗi chỉ được dựng khi mức đang bật.
#include <cstdint>
#include <format>
#include <string_view>
#include <utility>

namespace game::core {

enum class LogLevel : std::uint8_t { kDebug, kInfo, kWarn, kError };

// Đích do app cài; write không chặn (đích thật đẩy vào hàng đợi sang luồng log).
class LogSink {
public:
    LogSink() = default;
    LogSink(const LogSink&) = delete;
    LogSink(LogSink&&) = delete;
    LogSink& operator=(const LogSink&) = delete;
    LogSink& operator=(LogSink&&) = delete;
    virtual ~LogSink() = default;

    [[nodiscard]] virtual bool enabled(LogLevel level) const noexcept = 0;
    virtual void write(LogLevel level, std::string_view line) noexcept = 0;
};

template <class... Args>
void log(LogSink& sink, LogLevel level, std::format_string<Args...> format, Args&&... args) {
    if (!sink.enabled(level)) return;
    sink.write(level, std::format(format, std::forward<Args>(args)...));
}

} // namespace game::core
```

### KTR-07 [N] PHẢI — Thời gian và ngẫu nhiên là đầu vào: logic nhận `now` (tick) làm tham số; chỉ vỏ đọc đồng hồ, một lần mỗi tick

Logic gameplay không gọi `steady_clock::now()`, `system_clock::now()` hay `std::random_device`.
Vòng tick đọc đồng hồ một lần, đổi ra tick (refs/18 MMO-02, MMO-03), truyền xuống; PRNG có seed
cũng truyền xuống (MMO-17). Chọn đồng hồ: refs/08 STD-05.

- **Vì sao:** đọc đồng hồ giữa tick làm hai hệ thống trong cùng tick thấy hai "bây giờ" khác nhau, và
  làm logic không tất định: không replay, không test được cooldown 30 phút mà không ngủ 30 phút.
  Thời gian là tham số thì test đặt bất kỳ thời điểm nào, kể cả lúc biên dịch.
- **Kiểm:** grep `::now()` ngoài vòng tick, log và đo hiệu năng; test dùng tick tự chọn.

```cpp
// ✓ Cooldown nhận now từ vòng tick; kiểm được ngay lúc biên dịch, không đồng hồ thật nào.
#include "core/check.hpp"

#include <chrono>
#include <cstdint>
#include <ratio>
#include <utility>

namespace game::core {

// Mốc và khoảng thời gian game, như core/time.hpp của MMO-03.
enum class Tick : std::uint64_t {};
using TickSpan = std::chrono::duration<std::int64_t, std::ratio<1, 20>>;

[[nodiscard]] constexpr Tick operator+(Tick start, TickSpan span) noexcept {
    check(span.count() >= 0, "operator+: khoảng tick phải không âm");
    return Tick{std::to_underlying(start) + static_cast<std::uint64_t>(span.count())};
}

} // namespace game::core

namespace game::combat {

struct Cooldown {
    core::Tick ready_at{};
};

[[nodiscard]] constexpr bool is_ready(const Cooldown& cooldown, core::Tick now) noexcept {
    return now >= cooldown.ready_at;
}

constexpr void start(Cooldown& cooldown, core::Tick now, core::TickSpan duration) noexcept {
    cooldown.ready_at = now + duration;
}

static_assert([] {
    Cooldown fireball;
    start(fireball, core::Tick{100}, core::TickSpan{30});
    return !is_ready(fireball, core::Tick{129}) && is_ready(fireball, core::Tick{130});
}());

} // namespace game::combat
```

## 2. Nâng cao [C]

### KTR-08 [C] PHẢI — Thiết kế vật lý: header công khai tối thiểu, chi tiết trong `detail` hoặc `.cpp`, khai báo trước kiểu chỉ dùng qua tham chiếu

Mỗi module là một thư mục `src/<m>/`: `x.hpp` đặt cạnh `x.cpp` cùng tên, include `"<m>/x.hpp"` từ
gốc `src/`; header nội bộ ở `src/<m>/detail/`, module khác không include (KTR-15 kiểm).
Kiểu chỉ xuất hiện qua tham chiếu/con trỏ trong chữ ký thì khai báo trước. Lớp có phụ thuộc nặng ở
ranh giới (driver DB, backend mạng): pimpl, xem refs/06 API-12. Ranh giới plugin/DLL: C ABI, xem
API-16.

- **Vì sao:** mỗi include trong header lan tới mọi TU dùng header đó: thời gian build và số TU biên
  dịch lại khi sửa tăng theo. Namespace và thư mục `detail` nói rõ cái gì là API, cái gì đổi được
  mà không báo ai.
- **Kiểm:** `-ftime-trace` (Clang) / ClangBuildAnalyzer cho header đắt; review header công khai mới.

```cpp
// ✓ Header công khai: khai báo trước Zone, một API, phần nội bộ trong detail.
#include "core/check.hpp"

#include <cstdint>

namespace game::world {
// Khai báo trước: không kéo zone.hpp và mọi thứ nó include vào TU gọi.
class Zone;
enum class EntityId : std::uint32_t {};
} // namespace game::world

namespace game::combat {

struct HitRequest {
    world::EntityId attacker{};
    world::EntityId target{};
};

struct HitResult {
    std::int32_t damage = 0;
    bool killed = false;
};

namespace detail {
// Nội bộ module combat, không ổn định. raw ≥ 0, armor ≥ 0; tính trong int64 nên không tràn, kết
// quả trong [0, raw].
[[nodiscard]] constexpr std::int32_t mitigate(std::int32_t raw, std::int32_t armor) noexcept {
    core::check(raw >= 0 && armor >= 0, "mitigate: raw và armor phải không âm");
    return static_cast<std::int32_t>(std::int64_t{raw} * 100 / (100 + std::int64_t{armor}));
}

static_assert(mitigate(100, 100) == 50 && mitigate(INT32_MAX, 0) == INT32_MAX);
} // namespace detail

// Định nghĩa ở combat/resolve.cpp, nơi Zone là kiểu đầy đủ.
[[nodiscard]] HitResult resolve_hit(world::Zone& zone, const HitRequest& request);

} // namespace game::combat
```

### KTR-09 [C] PHẢI — Mọi định dạng vượt ranh giới tiến trình hay thời gian mang số phiên bản; đọc bản cũ qua chuỗi nâng cấp từng bước

Giao thức (phiên bản trong bắt tay; máy chủ nhận dải `[min, hiện tại]`), bản ghi DB/blob, snapshot
chuyển giao, cấu hình. Nâng cấp là chuỗi hàm thuần v→v+1, mỗi hàm một test; phiên bản lạ (tương lai)
là lỗi, không đoán. Bản ghi đọc từ đĩa là dữ liệu không tin cậy (hỏng, sửa tay): mỗi bước kiểm miền
trước khi tính, trả lỗi chứ không tràn. Định dạng trên dây: refs/18 MMO-05, MMO-06.

- **Vì sao:** triển khai cuốn chiếu (rolling) nghĩa là luôn có hai phiên bản chạy cùng lúc; bản ghi
  lưu sống lâu hơn mọi phiên bản code. Chuỗi từng bước giữ mỗi bước nhỏ, test được; nhảy cóc vN→vM
  viết tay thì số tổ hợp tăng theo bình phương.
- **Kiểm:** test vàng: mỗi phiên bản cũ có một bản ghi mẫu trong repo, CI nâng cấp lên hiện tại và so.

```cpp
// ✓ Bản ghi có phiên bản; nâng cấp qua bảng hàm v→v+1; bản ghi hỏng là lỗi, không phải tràn số.
#include <array>
#include <cstdint>
#include <expected>
#include <span>

namespace game::db {

enum class [[nodiscard]] LoadError : std::uint8_t { kFromFuture, kCorrupt };

// Trần kinh tế (refs/18 MMO-07) và cấp tối đa: giá trị ngoài miền là bản ghi hỏng.
inline constexpr std::int64_t kMaxCopper = 1'000'000'000'000'000;
inline constexpr std::int32_t kMaxLevel = 200;

struct CharacterRecord {
    std::uint32_t version = 0;
    std::int64_t copper = 0;
    std::int32_t level = 1;
    // Có từ v2.
    std::int32_t skill_points = 0;
};

using Loaded = std::expected<CharacterRecord, LoadError>;

// v0 lưu theo bạc, một bạc = 100 đồng; kiểm miền trước để phép nhân không tràn.
[[nodiscard]] constexpr Loaded v0_to_v1(CharacterRecord record) noexcept {
    if (record.copper < 0 || record.copper > kMaxCopper / 100) return std::unexpected(LoadError::kCorrupt);
    record.copper *= 100;
    record.version = 1;
    return record;
}

// Bù điểm kỹ năng cho nhân vật tạo trước khi có kỹ năng.
[[nodiscard]] constexpr Loaded v1_to_v2(CharacterRecord record) noexcept {
    if (record.level < 1 || record.level > kMaxLevel) return std::unexpected(LoadError::kCorrupt);
    record.skill_points = record.level * 2;
    record.version = 2;
    return record;
}

using Upgrade = Loaded (*)(CharacterRecord) noexcept;
inline constexpr std::array<Upgrade, 2> kUpgrades{&v0_to_v1, &v1_to_v2};
inline constexpr std::uint32_t kCurrentVersion = kUpgrades.size();

// and_then bỏ qua các bước sau bước lỗi đầu tiên; thân vòng lặp không cần if.
[[nodiscard]] constexpr Loaded upgrade(CharacterRecord record) noexcept {
    if (record.version > kCurrentVersion) return std::unexpected(LoadError::kFromFuture);
    Loaded result = record;
    for (const Upgrade step : std::span(kUpgrades).subspan(record.version)) {
        result = result.and_then(step);
    }
    return result;
}

static_assert(upgrade({.copper = 7, .level = 3})->skill_points == 6);
static_assert(!upgrade({.copper = kMaxCopper}).has_value());

} // namespace game::db
```

### KTR-10 [C] NÊN — Cờ tính năng là cấu hình có kiểu; nạp lại nóng = dựng ảnh chụp mới, kiểm hợp lệ, đổi ở ranh giới tick, giữ bản cũ để lùi

Cờ là `enum class` + bitset trong ảnh chụp cấu hình, không phải `#ifdef` hay chuỗi tra lúc chạy.
Đường nạp lại: đọc tệp → parse → `validate` (KTR-05) → ảnh chụp bất biến → gửi vào hộp thư zone →
zone đổi ở đầu tick (cơ chế: refs/12 DT-12). Thứ không đổi nóng được (tick rate, cổng, số luồng,
bố cục bộ nhớ) bị từ chối khi nạp lại, không áp nửa vời.

- **Vì sao:** bật/tắt tính năng hỏng (đấu giá lỗi nhân bản vàng) phải mất vài giây, không phải một
  lần build và triển khai. Đổi ở ranh giới tick giữ tick tất định: mọi hệ thống trong một tick thấy
  cùng một cấu hình.
- **Kiểm:** test: nạp cấu hình hỏng thì giữ nguyên bản cũ và báo lỗi; mỗi cờ có test cả hai trạng thái.

```cpp
// ✓ Cờ tính năng có kiểu; chỉ số ngoài miền (kể cả kCount) bị chặn trước operator[] của bitset.
#include "core/check.hpp"

#include <bitset>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace game::config {

enum class Feature : std::uint8_t { kAuctionHouse, kCrossZoneChat, kNewLootTable, kCount };

class FeatureSet {
public:
    [[nodiscard]] bool enabled(Feature feature) const noexcept { return bits_[index(feature)]; }

    // Setter một giá trị dữ liệu: ngoại lệ của KG-07.
    FeatureSet& set_enabled(Feature feature, bool enable) noexcept {
        bits_[index(feature)] = enable;
        return *this;
    }

private:
    static constexpr std::size_t kCount = std::to_underlying(Feature::kCount);

    // bitset::operator[] không kiểm biên: chỉ số ≥ kCount là UB, không phải ngoại lệ.
    [[nodiscard]] static constexpr std::size_t index(Feature feature) noexcept {
        const std::size_t value = std::to_underlying(feature);
        core::check(value < kCount, "FeatureSet: Feature ngoài miền");
        return value;
    }

    std::bitset<kCount> bits_;
};

} // namespace game::config
```

### KTR-11 [C] NÊN — Tiêm phụ thuộc: tham số template ràng buộc concept trên đường nóng; constructor nhận giao diện ảo ở đường lạnh và ranh giới

Đường nóng (mỗi thực thể, mỗi gói): concept, không gọi ảo, trình dịch nội tuyến được. Đường lạnh
(lưu DB, gửi mail, dịch vụ ngoài): lớp nhận `Interface&` hoặc `unique_ptr<Interface>` qua constructor
(lớp đa hình: refs/06 API-11). Bản giả cho test thay ở đúng chỗ đó. ✗ điển hình:
`ItemDatabase::instance().max_stack(item)` giữa luật chơi.

- **Vì sao:** phụ thuộc lộ trong chữ ký thì test thay được và người đọc thấy được; gọi ảo mỗi thực thể
  chặn nội tuyến và vector hoá (refs/09 HN-05), còn ở đường lạnh chi phí đó không đáng kể.
- **Kiểm:** mỗi lớp/hàm logic có test dùng bản giả; review `instance()`/biến toàn cục (KTR-04).

```cpp
// ✓ Danh mục vật phẩm tiêm qua concept; test dùng bản giả hằng số.
#include "core/check.hpp"

#include <concepts>
#include <cstdint>

namespace game::inv {

enum class ItemId : std::uint32_t {};

template <class Catalog>
concept ItemCatalog = requires(const Catalog& catalog, ItemId item) {
    { catalog.max_stack(item) } noexcept -> std::same_as<std::int32_t>;
};

// Số ô túi cần cho count vật phẩm; count ≥ 0. Chia rồi cộng phần dư: (count + stack - 1) / stack
// tràn int32 khi count gần INT32_MAX.
template <ItemCatalog Catalog>
[[nodiscard]] constexpr std::int32_t slots_needed(const Catalog& catalog, ItemId item, std::int32_t count) noexcept {
    const std::int32_t stack = catalog.max_stack(item);
    core::check(stack > 0 && count >= 0, "slots_needed: stack > 0, count ≥ 0");
    const std::int32_t partial = (count % stack == 0) ? 0 : 1;
    return (count / stack) + partial;
}

struct FixedCatalog {
    std::int32_t stack = 20;
    [[nodiscard]] constexpr std::int32_t max_stack(ItemId /*item*/) const noexcept { return stack; }
};

static_assert(ItemCatalog<FixedCatalog>);
static_assert(slots_needed(FixedCatalog{}, ItemId{7}, 41) == 3);
static_assert(slots_needed(FixedCatalog{}, ItemId{7}, INT32_MAX) == 107'374'183);

} // namespace game::inv
```

### KTR-12 [C] NÊN — Lõi thuần, vỏ mệnh lệnh: luật chơi là hàm (trạng thái, yêu cầu) → kết quả hoặc lỗi; IO, log, lưu, gửi nằm ở vỏ quanh tick

- **Vì sao:** hàm thuần test bằng giá trị (không mock), chạy được lúc biên dịch, replay được, và an
  toàn để gọi lại (thử lại sau lỗi DB không nhân đôi tác dụng). Vỏ mỏng là nơi duy nhất có thứ tự tác
  dụng phụ cần review: kiểm → áp dụng → ghi sự kiện kinh tế → lưu → gửi (refs/18 MMO).
- **Kiểm:** hàm luật chơi `constexpr` hoặc ít nhất không nhận tham số IO; có `static_assert`/unit test.

```cpp
// ✓ Chế tạo: hàm thuần trả kết quả hoặc lỗi; vỏ mới là nơi trừ đồ, ghi log, lưu.
#include <cstdint>
#include <expected>

namespace game::craft {

enum class [[nodiscard]] CraftError : std::uint8_t {
    kLevelTooLow,
    kMissingMaterial,
    kNotEnoughCopper,
};

// Đã qua validate lúc nạp (KTR-05): mọi trường không âm.
struct Recipe {
    std::int32_t min_level = 0;
    std::int32_t material_count = 0;
    std::int64_t fee_copper = 0;
};

struct Crafter {
    std::int32_t level = 0;
    std::int32_t material_owned = 0;
    std::int64_t copper = 0;
};

[[nodiscard]] constexpr std::expected<Crafter, CraftError> craft(const Recipe& recipe, Crafter crafter) noexcept {
    if (crafter.level < recipe.min_level) return std::unexpected(CraftError::kLevelTooLow);
    if (crafter.material_owned < recipe.material_count) return std::unexpected(CraftError::kMissingMaterial);
    if (crafter.copper < recipe.fee_copper) return std::unexpected(CraftError::kNotEnoughCopper);
    crafter.material_owned -= recipe.material_count;
    crafter.copper -= recipe.fee_copper;
    return crafter;
}

inline constexpr Recipe kSwordRecipe{.min_level = 5, .material_count = 3, .fee_copper = 50};
inline constexpr Crafter kSmith{.level = 5, .material_owned = 3, .copper = 60};
static_assert(craft(kSwordRecipe, kSmith)->copper == 10);

} // namespace game::craft
```

### KTR-13 [C] NÊN — Hệ thống chạy trên nhiều thực thể mỗi tick theo hướng dữ liệu (mảng thành phần + hàm hệ thống); OOP cho đối tượng ít, sống lâu, đa hình thật

DOD: di chuyển, buff, AOI, hồi máu — thành phần là mảng liền theo chỉ số thực thể, hệ thống là hàm
tự do trên `span` (bố cục: refs/10 BN-06, BN-07). OOP: phiên, kết nối DB, dịch vụ, máy trạng thái
AI phức tạp — vài trăm đối tượng, gọi ảo không đáng kể.

- **Vì sao:** cây kế thừa `Entity → Character → Player` với `update()` ảo mỗi tick là một gọi gián
  tiếp và một lần nhảy bộ nhớ mỗi thực thể; với hàng nghìn thực thể đó là phần lớn ngân sách tick.
  Mảng thành phần duyệt tuyến tính, prefetch tốt, vector hoá được, và chia lát cho nhiều luồng dễ.
- **Kiểm:** profiler: thời gian mỗi hệ thống / số thực thể; review lớp có `virtual` gọi trong vòng tick.

```cpp
// ✓ Hệ thống di chuyển trên các mảng thành phần cùng chỉ số; không virtual mỗi thực thể.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::sim {

// Bất biến: mọi mảng cùng cỡ; chỉ số i là cùng một thực thể. Toạ độ trong miền thế giới
// (|x|, |y| ≤ 2^29 cm) và |vận tốc| ≤ 2^20 cm mỗi tick, kiểm khi ghi (MMO-14): cộng không tràn.
struct Movers {
    std::vector<std::int32_t> x;
    std::vector<std::int32_t> y;
    std::vector<std::int32_t> velocity_x;
    std::vector<std::int32_t> velocity_y;
};

inline void integrate(Movers& movers) noexcept {
    const std::size_t count = movers.x.size();
    core::check(movers.y.size() == count && movers.velocity_x.size() == count && movers.velocity_y.size() == count,
        "Movers: các mảng thành phần lệch cỡ");
    for (std::size_t i = 0; i < count; ++i) {
        movers.x[i] += movers.velocity_x[i];
        movers.y[i] += movers.velocity_y[i];
    }
}

} // namespace game::sim
```

## 3. Thần thoại [T]

### KTR-14 [T] CÓ THỂ — Modules C++20: một module mỗi tầng, partition giao diện cho API, đơn vị cài đặt cho chi tiết; chỉ khi cả chuỗi công cụ đã ổn

Đã đo trên máy kiểm: module có partition biên dịch và chạy được với Clang 20 (`--precompile`), GCC
15 (`-fmodules`), GCC 14 (`-fmodules-ts`). Clang 20 cảnh báo
`-Wimport-implementation-partition-unit-in-interface-unit` khi giao diện chính `import` một
partition cài đặt: chi tiết chỉ import từ đơn vị cài đặt. Partition giao diện nào cũng phải được giao
diện chính `export import` ([module.unit]); thứ nội bộ trong đó thì đừng `export`. Header chuẩn vào
global module fragment (`module;` + `#include`) của TỪNG tệp dùng nó: `import` không mang theo
include của tệp bên kia (Clang 20 báo `missing '#include <cstdint>'`). `import std;` chưa dùng được
đồng đều: refs/08 STD-22. Cấu hình CMake (`FILE_SET CXX_MODULES`): refs/14 BD-14.

- **Vì sao:** module cắt chi phí parse header lặp lại và cách ly macro, nhưng đổi cách build, cách
  phân phối, công cụ (clang-tidy, IDE) — chỉ đáng khi mọi trình dịch mục tiêu và build system đã hỗ
  trợ ổn. Ranh giới module trùng ranh giới tầng (KTR-01) thì việc chuyển đổi là cơ học.
- **Kiểm:** CI build bằng cả ba trình dịch; không để header và module cùng định nghĩa một thực thể.

```cpp
// ✓ [đoạn] Bố cục module game.world (bốn tệp), đã build và chạy với Clang 20, GCC 14, GCC 15.
// --- world-entity.cppm: partition giao diện, được export import ở giao diện chính.
module;
#include <cstdint>
export module game.world:entity;
export namespace game::world {
struct EntityId {
    std::uint32_t value = 0;
};
} // namespace game::world

// --- world.cppm: giao diện chính, chỉ chứa API; tự include <cstdint> dù :entity đã include.
module;
#include <cstdint>
export module game.world;
export import :entity;
export namespace game::world {
[[nodiscard]] std::uint32_t bucket_of(EntityId id) noexcept;
} // namespace game::world

// --- world-detail.cppm: partition cài đặt, không export; chỉ đơn vị cài đặt import nó.
module;
#include <cstdint>
module game.world:detail;
namespace game::world::detail {
inline constexpr std::uint32_t kBuckets = 64;
} // namespace game::world::detail

// --- world.cpp: đơn vị cài đặt.
module;
#include <cstdint>
module game.world;
import :detail;
namespace game::world {
std::uint32_t bucket_of(EntityId id) noexcept {
    return id.value % detail::kBuckets;
}
} // namespace game::world
```

### KTR-15 [T] PHẢI — Bảng tầng là dữ liệu và được máy kiểm: mỗi module một target, test `layers` quét include ngược tầng theo bảng

Bảng tầng (KTR-01) nằm trong `cmake/GameLayers.cmake`: mỗi module một dòng liệt kê module được
include. Test ctest `layers` quét `#include "x/` trong mọi `src/<m>/**/*.hpp|cpp` và đỏ khi: module
include tầng không có trong dòng của nó; include `<khác>/detail/` của module khác; thư mục module chưa
có dòng trong bảng. Mỗi module vẫn là một target chỉ link module tầng dưới.

- **Vì sao:** header đặt cạnh `.cpp` (KTR-08) nên mọi module chung gốc include `src/`; trình dịch không
  còn chặn include ngược tầng, test này thay chỗ đó. Quy tắc tầng chỉ nằm trong tài liệu thì mục dần
  qua từng PR; máy kiểm thì vi phạm đỏ ngay ở CI, kèm tên cạnh sai và tệp.
- **Kiểm:** `ctest --preset <preset> -R layers` ở mọi PR (nằm sẵn trong `ctest` của mọi preset).

```cmake
# cmake/GameLayers.cmake — kiểm tầng (KTR-01, KTR-15).
# Chạy bằng ctest: cmake -DGAME_SOURCE_DIR=<gốc> -P <tệp này>.
# Bảng tầng là dữ liệu: module → module được include.
# Module mới PHẢI thêm một dòng.
set(game_layer_core "core")
set(game_layer_app "core app")

set(src "${GAME_SOURCE_DIR}/src")
file(GLOB modules LIST_DIRECTORIES true RELATIVE "${src}" "${src}/*")
set(include_re "^[ \t]*#[ \t]*include[ \t]*\"[a-z0-9_]+/")

# In cạnh sai; SEND_ERROR → mã thoát 1.
function(game_layer_violation module source text)
    file(RELATIVE_PATH where "${GAME_SOURCE_DIR}" "${source}")
    message(SEND_ERROR "tầng: ${module} → ${text} (${where})")
endfunction()

# Kiểm một dòng #include của tệp thuộc module.
function(game_check_include module source line)
    string(REGEX MATCH "\"([a-z0-9_]+)/([^\"]*)\"" _ "${line}")
    set(used "${CMAKE_MATCH_1}")
    set(path "${CMAKE_MATCH_2}")
    if(NOT used IN_LIST game_layer_${module})
        game_layer_violation(${module} "${source}" "${used}")
    elseif(NOT used STREQUAL module AND path MATCHES "^detail/")
        game_layer_violation(${module} "${source}" "${used}/detail")
    endif()
endfunction()

# Quét .hpp/.cpp của module.
function(game_check_module module)
    file(GLOB_RECURSE sources "${src}/${module}/*.hpp" "${src}/${module}/*.cpp")
    foreach(source IN LISTS sources)
        file(STRINGS "${source}" lines REGEX "${include_re}")
        foreach(line IN LISTS lines)
            game_check_include(${module} "${source}" "${line}")
        endforeach()
    endforeach()
endfunction()

foreach(module IN LISTS modules)
    if(NOT IS_DIRECTORY "${src}/${module}")
        continue()
    endif()
    if(NOT DEFINED game_layer_${module})
        message(SEND_ERROR "tầng: module ${module} chưa có trong bảng")
        continue()
    endif()
    separate_arguments(game_layer_${module})
    game_check_module(${module})
endforeach()
```
### KTR-16 [T] NÊN — Zone là đơn vị sở hữu và triển khai; giao tiếp liên zone và với dịch vụ toàn cục chỉ bằng thông điệp có id, định tuyến qua bảng

Zone sở hữu trạng thái trên một luồng (DT-08); nhiều zone mỗi tiến trình, nhiều tiến trình mỗi
shard. Dịch vụ toàn cục (bang hội, đấu giá, thư, bạn bè) là tiến trình riêng với DB riêng. Mọi tương
tác chéo là thông điệp mang `request_id`; trả lời mang lại id. Bên nhận nhớ kết quả theo id: id lặp
thì gửi lại đúng kết quả đã lưu, không làm lại và không im lặng bỏ (trả lời đầu có thể đã mất, bên
gửi sẽ thử lại mãi). Bảng id đã xử lý có hạn theo thời gian; thao tác kinh tế lưu id trong cùng
transaction DB (refs/18 MMO-21). Thế giới liền mạch: thực thể gần biên có bản sao chỉ đọc (ghost) ở
zone kề, cập nhật bằng thông điệp.

- **Vì sao:** gọi đồng bộ sang zone khác buộc khoá hai zone hoặc chờ mạng trong tick; thông điệp giữ
  mỗi zone đơn luồng, chịu được zone kia chậm hay chết, và chuyển được zone sang máy khác chỉ bằng
  sửa bảng định tuyến. Id yêu cầu cho phép thử lại an toàn (idempotent).
- **Kiểm:** không có con trỏ/tham chiếu sang trạng thái zone khác; mọi thông điệp có test lặp, trùng
  và mất trả lời (bên gửi thử lại phải nhận đúng kết quả cũ).

```cpp
// ✓ Bảng định tuyến zone → nút: chuyển zone sang máy khác chỉ đổi bảng, code gửi không đổi.
#include <cstddef>
#include <cstdint>
#include <optional>
#include <utility>
#include <vector>

namespace game::cluster {

enum class ZoneId : std::uint16_t {};
enum class NodeId : std::uint16_t {};
enum class RequestId : std::uint64_t {};

struct Envelope {
    ZoneId target{};
    // Trả lời mang lại id này; id đã xử lý thì gửi lại kết quả đã lưu.
    RequestId request{};
    std::uint16_t opcode = 0;
    std::vector<std::byte> payload;
};

class ZoneRouter {
public:
    explicit ZoneRouter(std::vector<NodeId> node_of_zone) noexcept : node_of_zone_(std::move(node_of_zone)) {}

    // nullopt: id ngoài bảng (zone không tồn tại, hoặc bảng này cũ hơn bên gửi) — giữ thông điệp
    // để gửi lại khi có bảng mới, không đoán nút.
    [[nodiscard]] std::optional<NodeId> route(ZoneId zone) const noexcept {
        const std::size_t index = std::to_underlying(zone);
        if (index >= node_of_zone_.size()) return std::nullopt;
        return node_of_zone_[index];
    }

private:
    std::vector<NodeId> node_of_zone_;
};

} // namespace game::cluster
```

### KTR-17 [T] NÊN — Triển khai không dừng: gateway giữ kết nối, zone chuyển giao trạng thái đã phiên bản hoá ở ranh giới tick, luôn có đường lùi

Tách kết nối client (gateway) khỏi logic (zone): đổi tiến trình zone không rớt kết nối. Zone viết theo
kiểu crash-only (refs/05 LH-19), nên "chuyển giao" và "khôi phục sau sập" là cùng một đường code.

- **Vì sao:** bảo trì định kỳ vài giờ là mất người chơi; khởi động lại zone mà kết nối rớt là mất phiên
  và trạng thái chưa lưu. Snapshot có phiên bản (KTR-09) + hash trạng thái (refs/18 MMO-19) cho phép zone
  mới chứng minh nó đã nhận đúng trước khi zone cũ buông.
- **Kiểm:** diễn tập trong staging mỗi bản phát hành: chuyển giao dưới tải giả lập, đo thời gian đóng
  băng, so hash trạng thái trước/sau.

```text
1. Khởi động zone mới (bản N+1) cạnh zone cũ (bản N); N+1 đọc được snapshot của N (KTR-09).
2. Zone cũ: ngừng nhận người chơi mới; ở ranh giới tick T đóng băng, ghi snapshot(T) + hash(T).
3. Zone mới: nạp snapshot, nâng cấp, tính lại hash; khác hash(T) → huỷ, zone cũ chạy tiếp (lùi).
4. Zone mới nhận epoch sở hữu mới ở DB (refs/18 MMO-15): job lưu còn bay của zone cũ mang epoch
   cũ nên bị từ chối, không ghi đè trạng thái mới; version tiếp nối từ snapshot.
5. Gateway chuyển ánh xạ phiên → zone mới; gói đến trong lúc chuyển được đệm theo số thứ tự.
6. Zone mới chạy từ tick T + 1; zone cũ thoát khi gateway xác nhận. Đóng băng: vài tick, không phải phút.
```

### KTR-18 [T] PHẢI — Quan sát được: số liệu theo luồng gộp định kỳ, histogram log-tuyến tính cho độ trễ, log có cấu trúc mang trace id của phiên/giao dịch

Mỗi luồng ghi bộ đếm và histogram của riêng nó (không atomic, không chia sẻ), luồng metrics gộp qua
hàng đợi (DT-01). Log là cặp khoá=giá trị (hoặc JSON một dòng) có `trace_id` sinh khi phiên đăng nhập
hoặc giao dịch bắt đầu, đi theo mọi thông điệp liên quan qua zone, dịch vụ, DB. Đo mỗi tick: thời
lượng từng pha (refs/09 HN-08), p50/p99/max theo cửa sổ.

- **Vì sao:** trung bình che đuôi: tick p99 vượt ngân sách mới là lag người chơi thấy. Histogram
  log-tuyến tính ghi O(1), cỡ cố định, gộp bằng phép cộng, sai số tương đối có chặn. Trace id nối một
  sự cố (mất đồ khi giao dịch) qua mọi tiến trình mà không cần đoán thời điểm.
- **Kiểm:** `static_assert` ca biên của hàm chia ô; dashboard tick p99 có cảnh báo; mỗi log giao dịch
  có trace id.

```cpp
// ✓ Histogram log-tuyến tính: ghi O(1), 8 ô con mỗi quãng luỹ thừa 2, sai số tương đối ≤ 12,5 %.
#include <algorithm>
#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace game::obs {

// Chỉ luồng sở hữu ghi; luồng metrics nhận bản chép để gộp (cộng từng ô).
class LatencyHistogram {
public:
    static constexpr std::uint32_t kSubBits = 3;
    static constexpr std::size_t kBuckets = 496;

    // 0..15 chính xác; từ 16 trở lên ô rộng 2^shift với shift = bit_width - 4.
    [[nodiscard]] static constexpr std::uint64_t bucket_of(std::uint64_t micros) noexcept {
        const auto width = static_cast<std::uint32_t>(std::bit_width(micros));
        const std::uint32_t shift = std::max(width, kSubBits + 1) - (kSubBits + 1);
        return (std::uint64_t{shift} << kSubBits) + (micros >> shift);
    }

    void record(std::uint64_t micros) noexcept {
        // Luôn < kBuckets: bucket_of đơn điệu, static_assert dưới chốt giá trị lớn nhất (KTR-18).
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
        ++counts_[bucket_of(micros)];
    }

private:
    std::array<std::uint64_t, kBuckets> counts_{};
};

static_assert(LatencyHistogram::bucket_of(15) == 15 && LatencyHistogram::bucket_of(16) == 16);
static_assert(LatencyHistogram::bucket_of(31) == 23 && LatencyHistogram::bucket_of(32) == 24);
static_assert(LatencyHistogram::bucket_of(std::numeric_limits<std::uint64_t>::max()) == LatencyHistogram::kBuckets - 1);

} // namespace game::obs
```

## Kiểm nhanh

- [ ] Include mới đi đúng chiều tầng, không tạo vòng; tầng dưới báo lên bằng sự kiện? (KTR-01, KTR-02, KTR-15)
- [ ] Header mới tự đủ, một khái niệm, có trong `header_check`? (KTR-03)
- [ ] Không singleton, không biến toàn cục hay `static` khả biến; dịch vụ đi qua ngữ cảnh? (KTR-04)
- [ ] Số gameplay mới nằm trong cấu hình có mặc định có tên và được `validate`? (KTR-05, KTR-10)
- [ ] Thư viện log qua `LogSink`, không `printf`/`cout`? (KTR-06)
- [ ] Logic nhận `now`/PRNG làm tham số, không gọi `::now()`? (KTR-07)
- [ ] Định dạng lưu/giao thức đổi thì tăng phiên bản, thêm bước nâng cấp và bản ghi mẫu? (KTR-09)
- [ ] Phụ thuộc đường nóng qua concept, đường lạnh qua giao diện; có bản giả cho test? (KTR-11)
- [ ] Luật chơi là hàm thuần; tác dụng phụ chỉ ở vỏ? (KTR-12)
- [ ] Hệ thống mỗi tick chạy trên mảng thành phần, không `virtual` mỗi thực thể? (KTR-13)
- [ ] Tương tác liên zone chỉ bằng thông điệp có `request_id`? (KTR-16)
- [ ] Đường mới có số liệu theo luồng, histogram độ trễ, log có trace id? (KTR-18)
