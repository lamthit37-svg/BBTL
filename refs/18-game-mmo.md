# MMO · Máy chủ game MMO: tick, thực thể, giao thức, AOI, kinh tế, tất định, chống gian lận

> **Phạm vi:** quy tắc riêng cho máy chủ MMO/MMORPG: máy chủ quyết định, vòng tick bước cố định,
> thời gian game, handle thực thể, khung gói và đọc gói, tiền tệ và giao dịch, sự kiện kinh tế, AOI,
> pha tick, snapshot delta, đệm input, chống gian lận, lưu DB, phiên, PRNG, tất định và replay, nén
> bit, cắt tải, chuyển thực thể giữa zone, chống nhân bản vật phẩm. **Đọc khi:** viết hoặc review
> bất kỳ hệ thống gameplay, handler gói tin, mã kinh tế (vàng, vật phẩm, giao dịch, thư, đấu giá),
> vòng tick, AOI/đồng bộ trạng thái, lưu nhân vật, chuyển zone; điều tra lệch replay, lag, nhân bản.
> **Liên quan:** refs/12-dong-thoi.md (DT-01 hộp thư, DT-08 mô hình luồng, DT-14 ring SPSC),
> refs/17-kien-truc-module.md (KTR-07 thời gian tiêm, KTR-09 phiên bản, KTR-16 zone, KTR-17 chuyển
> giao), refs/05-loi-hop-dong.md (LH-03 đầu vào client, LH-12 commit-or-rollback, LH-19 crash-only),
> refs/13-ub-on-dinh.md (UB-04 ranh giới tin cậy, UB-13 hàng gửi, UB-14 rate limit, UB-15 hạn chờ),
> refs/08 (STD-14, STD-15 bẫy tất định), refs/02 (PH-12 máy trạng thái phiên), refs/10 (BN-01, BN-10).

## 1. Nền tảng [N]

### MMO-01 [N] PHẢI — Máy chủ quyết định: client gửi ý định, không gửi kết quả; mọi trường được kiểm trước khi chạm trạng thái

Client gửi "dùng kỹ năng K lên mục tiêu T", "đi theo hướng D"; không bao giờ gửi sát thương, vị
trí đích tuỳ ý, số lượng vật phẩm nhận được. Máy chủ kiểm miền (id trong bảng), quyền, cooldown, tầm
(tính từ vị trí MÁY CHỦ), trạng thái mục tiêu; vi phạm trả lý do, đếm theo phiên, máy chủ chạy tiếp
(refs/05 LH-03).

- **Vì sao:** client nằm trong tay kẻ tấn công: mọi trường gói tin là đầu vào thù địch. Chỉ cần một
  handler tin trường `damage` hay `item_count` là đủ cho hack một phát chết boss hay in vàng.
- **Kiểm:** review mọi handler: trường nào đi thẳng vào trạng thái mà không qua kiểm? fuzz parser và
  handler (refs/15 KT).

```cpp
// ✓ Yêu cầu chỉ có id kỹ năng và id mục tiêu; máy chủ kiểm lần lượt rồi mới cho tính kết quả.
#include <array>
#include <cstdint>
#include <expected>
#include <span>

namespace game::core {

// Mốc: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

} // namespace game::core

namespace game::combat {

enum class [[nodiscard]] Reject : std::uint8_t {
    kUnknownSkill,
    kOnCooldown,
    kOutOfRange,
    kTargetDead,
};

struct SkillDef {
    std::int64_t range_cm = 0;
};
using CastResult = std::expected<SkillDef, Reject>;

inline constexpr std::array<SkillDef, 2> kSkills{{{.range_cm = 300}, {.range_cm = 2'500}}};

// Nguyên văn từ gói: chưa tin trường nào.
struct CastRequest {
    std::uint32_t skill = 0;
    std::uint32_t target = 0;
};

// Máy chủ tự tra, không lấy từ client; distance_sq_cm tính từ vị trí máy chủ.
struct CastContext {
    core::Tick now{};
    core::Tick ready_at{};
    std::int64_t distance_sq_cm = 0;
    bool target_alive = false;
};

[[nodiscard]] constexpr CastResult validate_cast(const CastRequest& request, const CastContext& context) noexcept {
    const std::span<const SkillDef> skills = kSkills;
    if (request.skill >= skills.size()) return std::unexpected(Reject::kUnknownSkill);
    const SkillDef& skill = skills[request.skill];
    if (context.now < context.ready_at) return std::unexpected(Reject::kOnCooldown);
    if (context.distance_sq_cm > skill.range_cm * skill.range_cm) return std::unexpected(Reject::kOutOfRange);
    if (!context.target_alive) return std::unexpected(Reject::kTargetDead);
    return skill;
}

static_assert(validate_cast({.skill = 7}, {}).error() == Reject::kUnknownSkill);

} // namespace game::combat
```

### MMO-02 [N] PHẢI — Mô phỏng chạy bước cố định với accumulator số nguyên; số bước bù mỗi vòng có trần, phần nợ vượt trần bị bỏ và đếm

- **Vì sao:** bước biến thiên (dt = thời gian thực của vòng trước) làm vật lý, cooldown, AI khác nhau
  theo tải máy — không tất định, không replay. Accumulator bằng `std::chrono::nanoseconds` (số
  nguyên) không trôi như cộng dồn số thực. Không có trần thì một lần khựng (swap, page fault, máy ảo
  bị tạm dừng, debugger) đòi chạy bù hàng trăm bước, mỗi bước lại làm trễ thêm — "vòng xoáy chết".
- **Kiểm:** `dropped_steps` là số liệu có cảnh báo; test với đồng hồ giả nhảy cóc (KTR-07).

```cpp
// ✓ 20 Hz, tối đa 4 bước bù mỗi vòng; nợ vượt trần bị bỏ và đếm để không rơi vào vòng xoáy chết.
#include <algorithm>
#include <chrono>
#include <cstdint>

namespace game::sim {

class TickClock {
public:
    static constexpr std::chrono::nanoseconds kStep = std::chrono::milliseconds{50};
    static constexpr std::int64_t kMaxCatchUpSteps = 4;

    explicit TickClock(std::chrono::steady_clock::time_point start) noexcept : last_(start) {}

    // Gọi một lần mỗi vòng ngoài; trả số bước mô phỏng phải chạy ngay bây giờ.
    [[nodiscard]] std::int64_t steps_due(std::chrono::steady_clock::time_point now) noexcept {
        debt_ += now - last_;
        last_ = now;
        const std::int64_t owed = debt_ / kStep;
        const std::int64_t run = std::min(owed, kMaxCatchUpSteps);
        dropped_steps_ += owed - run;
        // Giữ phần lẻ nhỏ hơn kStep cho vòng sau.
        debt_ -= owed * kStep;
        return run;
    }

    [[nodiscard]] std::int64_t dropped_steps() const noexcept { return dropped_steps_; }

private:
    std::chrono::steady_clock::time_point last_;
    std::chrono::nanoseconds debt_{0};
    std::int64_t dropped_steps_ = 0;
};

} // namespace game::sim
```

### MMO-03 [N] PHẢI — Thời gian game là số tick nguyên; thời lượng thiết kế (ms) đổi sang tick bằng làm tròn lên, một lần lúc nạp

Mốc thời gian: `enum class Tick : std::uint64_t {}`. Khoảng: `std::chrono::duration` với chu kỳ
tick (KG-09). Cả hai định nghĩa một lần ở `core/time.hpp` (`game::core`, có sẵn trong
templates/project): net, db, sim đều dùng (KTR-01); mẫu ngắn trong bộ này khai báo lại tại chỗ cho
tự đủ. Hồi chiêu, buff, hết hạn lưu MỐC hết hạn (`now + span`), không lưu "giây còn lại" kiểu số
thực, không đếm ngược mỗi tick (một lần ghi mỗi thực thể mỗi tick; so mốc chỉ đọc).

- **Vì sao:** đã đo (GCC 14, `float` IEEE): cộng 0,05 s mỗi tick vào `float` giây lệch 2,3 s sau
  1 giờ, 637 s (10,6 phút) sau 1 ngày; trong [2^19, 2^20) mỗi phép cộng làm tròn thành 0,0625 s nên
  giá trị chạm 2^20 sau 10,5 ngày thật, từ đó `t + 0.05F == t` — đồng hồ game đứng yên vĩnh viễn.
  `double` vẫn lệch ~0,32 s mỗi năm. Số tick nguyên chính xác tuyệt đối, so sánh rẻ, tuần tự hoá
  không mất mát. Làm tròn lên: cooldown 51 ms ở 20 Hz là 2 tick, không bao giờ ngắn hơn thiết kế.
- **Kiểm:** grep `float`/`double` trong tên có `time`, `cooldown`, `duration` ở gameplay.

```cpp
// ✗ Giây kiểu float cộng dồn: lệch 10,6 phút sau 1 ngày, đứng yên từ ngày thứ 11 (đã đo).
struct GameClock {
    float seconds = 0.0F;
};

inline void advance(GameClock& clock) noexcept {
    clock.seconds += 0.05F;
}
```

```cpp
// ✓ core/time.hpp: mốc là enum Tick, khoảng là chrono duration; ms → tick làm tròn lên (ceil).
#include "core/check.hpp"

#include <chrono>
#include <cstdint>
#include <ratio>
#include <utility>

namespace game::core {

// Mốc: số tick từ lúc zone khởi động.
enum class Tick : std::uint64_t {};

// Khoảng: số tick, chu kỳ 1/20 s (20 Hz).
using TickSpan = std::chrono::duration<std::int64_t, std::ratio<1, 20>>;

// Mốc cộng khoảng không âm. uint64 tick ở 20 Hz đủ hàng tỉ năm: không tràn trong thực tế.
[[nodiscard]] constexpr Tick operator+(Tick start, TickSpan span) noexcept {
    check(span.count() >= 0, "operator+: khoảng tick phải không âm");
    return Tick{std::to_underlying(start) + static_cast<std::uint64_t>(span.count())};
}

[[nodiscard]] constexpr TickSpan to_ticks(std::chrono::milliseconds design) noexcept {
    return std::chrono::ceil<TickSpan>(design);
}

static_assert(to_ticks(std::chrono::milliseconds{0}).count() == 0);
static_assert(to_ticks(std::chrono::milliseconds{50}).count() == 1);
static_assert(to_ticks(std::chrono::milliseconds{51}).count() == 2);

static_assert(Tick{100} + to_ticks(std::chrono::milliseconds{1'500}) == Tick{130});

} // namespace game::core
```

### MMO-04 [N] PHẢI — Thực thể được tham chiếu bằng handle thế hệ (chỉ số + thế hệ); con trỏ chỉ sống trong một tick

Mục tiêu của AI, chủ của đạn, thành viên nhóm, trong thông điệp liên luồng: lưu handle. Tra handle
trả con trỏ hoặc `nullptr` nếu thế hệ không khớp; con trỏ không giữ qua tick (refs/04 SH-04).

- **Vì sao:** thực thể chết và ô được tái dùng trong vài tick; con trỏ hay chỉ số trần cũ lúc đó trỏ
  vào quái vật KHÁC — AI đánh nhầm mục tiêu, buff dính nhầm người, hoặc use-after-free. Handle cũ
  thì tra ra `nullptr`, một câu bảo vệ là đủ. Thế hệ 32 bit quay vòng sau 2^32 lần tái dùng một ô:
  khi chạm trần, bỏ hẳn ô đó.
- **Kiểm:** review struct thành phần chứa `T*`/`T&` tới thực thể; ASan.

```cpp
// ✓ Pool có handle thế hệ: huỷ làm tăng thế hệ, mọi handle cũ của ô đó tự hết hiệu lực.
#include <cstdint>
#include <vector>

namespace game::world {

struct EntityHandle {
    std::uint32_t index = 0;
    // 0 không bao giờ hợp lệ: handle mặc định là "không có".
    std::uint32_t generation = 0;
};

struct Monster {
    std::int32_t hp = 0;
};

// Chỉ luồng zone. Con trỏ từ find() chỉ dùng trong tick hiện tại.
class MonsterPool {
public:
    [[nodiscard]] EntityHandle spawn(const Monster& monster) {
        if (free_.empty()) return push_new(monster);
        const std::uint32_t index = free_.back();
        free_.pop_back();
        slots_[index].monster = monster;
        slots_[index].alive = true;
        return {.index = index, .generation = slots_[index].generation};
    }

    // Handle cũ hoặc đã huỷ: bỏ qua (thông điệp huỷ lặp là chuyện bình thường).
    void despawn(EntityHandle handle) {
        if (find(handle) == nullptr) return;
        Slot& slot = slots_[handle.index];
        slot.alive = false;
        ++slot.generation;
        // Thế hệ quay vòng 2^32: bỏ hẳn ô, không bao giờ tái dùng.
        if (slot.generation == 0) return;
        free_.push_back(handle.index);
    }

    [[nodiscard]] Monster* find(EntityHandle handle) noexcept {
        if (handle.index >= slots_.size()) return nullptr;
        Slot& slot = slots_[handle.index];
        if (!slot.alive || slot.generation != handle.generation) return nullptr;
        return &slot.monster;
    }

private:
    struct Slot {
        Monster monster;
        std::uint32_t generation = 1;
        bool alive = false;
    };

    [[nodiscard]] EntityHandle push_new(const Monster& monster) {
        slots_.push_back({.monster = monster, .generation = 1, .alive = true});
        return {.index = static_cast<std::uint32_t>(slots_.size() - 1), .generation = 1};
    }

    std::vector<Slot> slots_;
    std::vector<std::uint32_t> free_;
};

} // namespace game::world
```

### MMO-05 [N] PHẢI — Khung gói có tiền tố độ dài; độ dài được kiểm với trần TRƯỚC khi chờ thân hay cấp phát; khung hỏng là đóng phiên

Khung: `[độ dài thân u16 LE][opcode u16 LE][thân]`. Phiên bản giao thức đổi trong bắt tay, không
lặp lại ở mỗi gói (KTR-09). Bộ đệm nhận mỗi phiên có cỡ cố định ≥ `kHeaderBytes + kMaxBodyBytes`.
Trước cả khung: trần kết nối đồng thời mỗi IP và toàn máy, hạn hoàn tất bắt tay và đăng nhập (vd
10 s); phiên chưa xác thực có trần thân gói và tốc độ nhỏ hơn phiên trong thế giới.

- **Vì sao:** tin độ dài từ client để `resize` bộ đệm là DoS một gói (khai 4 GB). Trần cố định mỗi
  gói cũng là trần bộ nhớ mỗi phiên. Thân gói là view vào bộ đệm nhận: không chép, nhưng chết khi bộ
  đệm bị tiêu thụ (refs/04 SH-06). Kẻ gửi nhỏ giọt (khai độ dài lớn, gửi từng byte) bị chặn bằng hạn
  chờ đọc khung (UB-15). Không trần kết nối thì một máy mở hàng vạn socket chưa đăng nhập, mỗi cái
  giữ một bộ đệm nhận: hết bộ nhớ, hết descriptor trước khi rate limit theo phiên (UB-14) kịp chạy.
- **Kiểm:** fuzz `next_frame` với libFuzzer (KT-11); test ca 0 byte, 3 byte, đúng trần, trần + 1;
  test tải: mở kết nối vượt trần mỗi IP bị từ chối ngay khi accept.

```cpp
// ✓ Tách khung trên luồng TCP: kNeedMore đọc tiếp socket, kTooLarge đóng phiên và đếm.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::net {

inline constexpr std::size_t kHeaderBytes = 4;
inline constexpr std::size_t kMaxBodyBytes = 4'096;

enum class [[nodiscard]] FrameError : std::uint8_t { kNeedMore, kTooLarge };

struct Frame {
    std::uint16_t opcode = 0;
    // Sống tới khi bộ đệm nhận bị tiêu thụ.
    std::span<const std::byte> body;
};

[[nodiscard]] constexpr std::uint16_t load_le16(std::span<const std::byte, 2> bytes) noexcept {
    const auto low = std::to_integer<std::uint32_t>(bytes[0]);
    const auto high = std::to_integer<std::uint32_t>(bytes[1]);
    return static_cast<std::uint16_t>(low | (high << 8U));
}

[[nodiscard]] constexpr std::expected<Frame, FrameError> next_frame(std::span<const std::byte> buffer) noexcept {
    if (buffer.size() < kHeaderBytes) return std::unexpected(FrameError::kNeedMore);
    const std::size_t body_bytes = load_le16(buffer.first<2>());
    if (body_bytes > kMaxBodyBytes) return std::unexpected(FrameError::kTooLarge);
    if (buffer.size() < kHeaderBytes + body_bytes) return std::unexpected(FrameError::kNeedMore);
    return Frame{.opcode = load_le16(buffer.subspan<2, 2>()), .body = buffer.subspan(kHeaderBytes, body_bytes)};
}

} // namespace game::net
```

### MMO-06 [N] PHẢI — Thân gói đọc qua `Reader` trên `span<const std::byte>`: kiểm biên mỗi lần đọc, little-endian ghép từ byte, lỗi dính, chuỗi UTF-8 kiểm chặt, kiểm "đã đọc hết" ở cuối

CẤM `reinterpret_cast`/`memcpy` cả struct từ bộ đệm (aliasing, căn lề, vòng đời: refs/13 UB-03,
refs/04 SH-14; byte đệm, endian: refs/03 KG-17). Đổi thứ tự byte khi cần: refs/08 STD-07. Mảng và
chuỗi trong thân: số phần tử khai báo được kiểm với trần của loại gói VÀ với số byte còn lại
(`count > rest / cỡ_tối_thiểu` là lỗi) trước khi `reserve` hay lặp — không cấp phát, không lặp theo
con số client tự khai (UB-04).

Chuỗi (tên, chat, thư): kiểm trần byte TRƯỚC, rồi UTF-8 chặt theo Unicode Bảng 3-7 — từ chối dạng
dài thừa, surrogate, trên U+10FFFF, ký tự cụt (mẫu thứ hai); kết quả là bản sao sở hữu (mảng cố định
hoặc `std::string`), không là view vào bộ đệm nhận (SH-06). Ký tự điều khiển, ký tự định hướng
(U+202A–U+202E, U+2066–U+2069), ký tự vô hình là chính sách của tầng nội dung (chat, tên nhân vật),
không của bộ giải mã.

- **Vì sao:** lỗi "dính" (sticky): đọc quá cuối trả 0 và bật cờ, nên hàm parse viết thẳng một mạch,
  không `if` sau mỗi trường (code phẳng), chỉ một lần kiểm `finish()`. Thứ tự đọc an toàn vì
  braced-init-list đánh giá trái sang phải ([dcl.init.list]). Ghép byte bằng dịch bit chạy đúng trên
  mọi máy; đã xem asm: GCC 14 và Clang 20 ở `-O2` biên dịch phép ghép 4 byte LE thành một `mov`
  (BE: `mov` + `bswap`). Từ C++20, `uint32 → int32` là phép đổi modulo xác định.
- **Kiểm:** fuzz parser; test cụt từng byte (mọi tiền tố của gói hợp lệ phải trả `kTruncated`);
  chuỗi: test dạng dài thừa (C0 80), surrogate (ED A0 80), trên U+10FFFF (F4 90 80 80), cụt (E2 82).

```cpp
// ✗ Ép bộ đệm thành struct: gói cụt thì đọc quá cuối, lệch căn lề, vi phạm aliasing (UB), sai endian.
#include <cstddef>
#include <cstdint>
#include <span>

struct MoveInput {
    std::uint32_t sequence;
    std::int32_t dx_cm;
    std::int32_t dy_cm;
};

inline MoveInput parse_move(std::span<const std::byte> body) {
    return *reinterpret_cast<const MoveInput*>(body.data());
}
```

```cpp
// ✓ Reader lỗi dính: parse viết một mạch, kiểm một lần ở cuối.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::proto {

enum class [[nodiscard]] ParseError : std::uint8_t { kTruncated, kTrailingBytes };

class Reader {
public:
    explicit Reader(std::span<const std::byte> bytes) noexcept : rest_(bytes) {}

    [[nodiscard]] std::uint32_t u32() noexcept {
        const std::span<const std::byte> bytes = take(4);
        if (bytes.empty()) return 0;
        return widen(bytes[0]) | (widen(bytes[1]) << 8U) | (widen(bytes[2]) << 16U) | (widen(bytes[3]) << 24U);
    }

    // Bù hai: uint32 → int32 là phép đổi modulo, xác định từ C++20.
    [[nodiscard]] std::int32_t i32() noexcept { return static_cast<std::int32_t>(u32()); }

    [[nodiscard]] std::expected<void, ParseError> finish() const noexcept {
        if (failed_) return std::unexpected(ParseError::kTruncated);
        if (!rest_.empty()) return std::unexpected(ParseError::kTrailingBytes);
        return {};
    }

private:
    [[nodiscard]] static constexpr std::uint32_t widen(std::byte value) noexcept {
        return std::to_integer<std::uint32_t>(value);
    }

    [[nodiscard]] std::span<const std::byte> take(std::size_t count) noexcept {
        failed_ = failed_ || rest_.size() < count;
        if (failed_) return {};
        const std::span<const std::byte> taken = rest_.first(count);
        rest_ = rest_.subspan(count);
        return taken;
    }

    std::span<const std::byte> rest_;
    bool failed_ = false;
};

struct MoveInput {
    std::uint32_t sequence = 0;
    std::int32_t dx_cm = 0;
    std::int32_t dy_cm = 0;
};

// Cấu trúc đúng chưa đủ: miền giá trị (dx_cm, sequence) do MMO-13, MMO-14 kiểm tiếp.
// Braced-init-list đánh giá trái sang phải nên thứ tự đọc đúng thứ tự trên dây.
[[nodiscard]] inline std::expected<MoveInput, ParseError> parse_move(std::span<const std::byte> body) noexcept {
    Reader reader(body);
    const MoveInput input{.sequence = reader.u32(), .dx_cm = reader.i32(), .dy_cm = reader.i32()};
    const std::expected<void, ParseError> done = reader.finish();
    if (!done.has_value()) return std::unexpected(done.error());
    return input;
}

} // namespace game::proto
```

```cpp
// ✓ [chạy] Chuỗi từ client: UTF-8 chặt theo bảng dải byte dẫn (Unicode, Bảng 3-7), phẳng.
#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>

namespace game::proto {

namespace detail {

// Một dải byte dẫn, số byte của ký tự và miền byte thứ hai. Miền byte thứ hai loại dạng dài thừa
// (E0 80..9F, F0 80..8F), surrogate (ED A0..BF) và trên U+10FFFF (F4 90..BF); byte dẫn C0, C1,
// F5..FF và byte tiếp nối 80..BF không thuộc dải nào nên bị từ chối.
struct Utf8Lead {
    std::uint8_t lead_min = 0;
    std::uint8_t lead_max = 0;
    std::uint8_t size = 0;
    std::uint8_t second_min = 0;
    std::uint8_t second_max = 0;
};

inline constexpr std::array<Utf8Lead, 9> kUtf8Leads{{
    {.lead_min = 0x00, .lead_max = 0x7F, .size = 1, .second_min = 0x00, .second_max = 0x00},
    {.lead_min = 0xC2, .lead_max = 0xDF, .size = 2, .second_min = 0x80, .second_max = 0xBF},
    {.lead_min = 0xE0, .lead_max = 0xE0, .size = 3, .second_min = 0xA0, .second_max = 0xBF},
    {.lead_min = 0xE1, .lead_max = 0xEC, .size = 3, .second_min = 0x80, .second_max = 0xBF},
    {.lead_min = 0xED, .lead_max = 0xED, .size = 3, .second_min = 0x80, .second_max = 0x9F},
    {.lead_min = 0xEE, .lead_max = 0xEF, .size = 3, .second_min = 0x80, .second_max = 0xBF},
    {.lead_min = 0xF0, .lead_max = 0xF0, .size = 4, .second_min = 0x90, .second_max = 0xBF},
    {.lead_min = 0xF1, .lead_max = 0xF3, .size = 4, .second_min = 0x80, .second_max = 0xBF},
    {.lead_min = 0xF4, .lead_max = 0xF4, .size = 4, .second_min = 0x80, .second_max = 0x8F},
}};

[[nodiscard]] constexpr bool is_continuation(std::byte value) noexcept {
    return (value & std::byte{0xC0}) == std::byte{0x80};
}

// tail: đúng size - 1 byte sau byte dẫn.
[[nodiscard]] constexpr bool tail_matches(const Utf8Lead& rule, std::span<const std::byte> tail) noexcept {
    if (tail.empty()) return true;
    const auto second = std::to_integer<std::uint8_t>(tail.front());
    if (second < rule.second_min || second > rule.second_max) return false;
    return std::ranges::all_of(tail.subspan(1), &is_continuation);
}

// Phần còn lại sau một ký tự hợp lệ ở đầu rest (rest không rỗng); nullopt khi ký tự sai hay cụt.
[[nodiscard]] constexpr std::optional<std::span<const std::byte>> skip_char(std::span<const std::byte> rest) noexcept {
    core::check(!rest.empty(), "skip_char: rest phải không rỗng");
    const auto lead = std::to_integer<std::uint8_t>(rest.front());
    const auto covers = [lead](const Utf8Lead& one) { return lead >= one.lead_min && lead <= one.lead_max; };
    const Utf8Lead* const rule = std::to_address(std::ranges::find_if(kUtf8Leads, covers));
    if (rule == std::to_address(kUtf8Leads.end())) return std::nullopt;
    if (rule->size > rest.size()) return std::nullopt;
    if (!tail_matches(*rule, rest.subspan(1, rule->size - 1U))) return std::nullopt;
    return rest.subspan(rule->size);
}

} // namespace detail

// Toàn bộ bytes là UTF-8 hợp lệ; rỗng hợp lệ. Gọi SAU khi đã kiểm trần độ dài (UB-04).
[[nodiscard]] constexpr bool is_valid_utf8(std::span<const std::byte> bytes) noexcept {
    std::optional<std::span<const std::byte>> rest = bytes;
    while (rest.has_value() && !rest->empty()) {
        rest = detail::skip_char(*rest);
    }
    return rest.has_value();
}

template <std::uint8_t... Values>
inline constexpr std::array<std::byte, sizeof...(Values)> kBytes{std::byte{Values}...};

// "€" 3 byte, U+1F600 4 byte; rồi dạng dài thừa, surrogate, trên U+10FFFF, ký tự cụt.
static_assert(is_valid_utf8(kBytes<0xE2, 0x82, 0xAC>));
static_assert(is_valid_utf8(kBytes<0xF0, 0x9F, 0x98, 0x80>));
static_assert(!is_valid_utf8(kBytes<0xC0, 0x80>));
static_assert(!is_valid_utf8(kBytes<0xED, 0xA0, 0x80>));
static_assert(!is_valid_utf8(kBytes<0xF4, 0x90, 0x80, 0x80>));
static_assert(!is_valid_utf8(kBytes<0xE2, 0x82>));

} // namespace game::proto

int main() {
    std::array<std::byte, 3> bytes{};
    for (std::uint32_t lead = 0; lead < 256; ++lead) {
        bytes[0] = static_cast<std::byte>(lead);
        static_cast<void>(game::proto::is_valid_utf8(bytes));
    }
    return 0;
}
```

### MMO-07 [N] PHẢI — Tiền và số lượng là số nguyên 64 bit đơn vị nhỏ nhất, có trần kinh tế; CẤM số thực cho mọi giá trị kinh tế

Số dư nằm trong `[0, kMaxCopper]`; mọi phép cộng/trừ đi qua hàm trả `std::expected`. Thuế, phí
phần trăm: số nguyên với quy tắc làm tròn ghi rõ (thường làm tròn về phía nhà nước — người chơi
không "đẻ" ra được đồng lẻ). Chính sách kiểu số nguyên chung: refs/03 KG-03.

- **Vì sao:** `0.1 + 0.2 != 0.3`: số thực làm số dư lệch dần, và hai bên của giao dịch có thể thấy
  hai con số. Trần kinh tế làm phép kiểm tràn trở nên hiển nhiên: `amount > kMax - balance` không
  thể tràn vì `0 ≤ balance ≤ kMax`, kể cả khi `amount` là giá trị thù địch tới `INT64_MAX`. Trần
  số lượng mỗi loại vật phẩm cũng vậy: cộng vào túi mà không so với trần thì tràn được (UB).
- **Kiểm:** grep `float|double` trong `econ/`, `trade/`, `inv/`; test ca biên 0, trần, trần + 1, âm.

```cpp
// ✓ Số dư có bất biến [0, kMaxCopper]; mọi thay đổi qua deposit/withdraw.
#include <cstdint>
#include <expected>
#include <limits>

namespace game::econ {

enum class [[nodiscard]] MoneyError : std::uint8_t { kNegativeAmount, kOverCap, kInsufficient };

// 10^15 đồng: đủ cho mọi số dư; nhỏ hơn INT64_MAX (≈ 9,2 × 10^18) gần bốn bậc độ lớn.
inline constexpr std::int64_t kMaxCopper = 1'000'000'000'000'000;

struct Copper {
    // Bất biến: 0 ≤ value ≤ kMaxCopper; chỉ deposit/withdraw tạo giá trị mới.
    std::int64_t value = 0;
};

[[nodiscard]] constexpr std::expected<Copper, MoneyError> deposit(Copper balance, std::int64_t amount) noexcept {
    if (amount < 0) return std::unexpected(MoneyError::kNegativeAmount);
    if (amount > kMaxCopper - balance.value) return std::unexpected(MoneyError::kOverCap);
    return Copper{.value = balance.value + amount};
}

[[nodiscard]] constexpr std::expected<Copper, MoneyError> withdraw(Copper balance, std::int64_t amount) noexcept {
    if (amount < 0) return std::unexpected(MoneyError::kNegativeAmount);
    if (amount > balance.value) return std::unexpected(MoneyError::kInsufficient);
    return Copper{.value = balance.value - amount};
}

static_assert(!deposit({.value = kMaxCopper}, std::numeric_limits<std::int64_t>::max()).has_value());

} // namespace game::econ
```

### MMO-08 [N] PHẢI — Giao dịch, chế tạo, thư, đấu giá theo hai pha: kiểm hết trên trạng thái chỉ đọc tạo ra "kế hoạch", rồi áp dụng không thể thất bại

Kế hoạch là kiểu chỉ hàm kiểm tạo được (type-state, refs/03 KG-15); hàm áp dụng `noexcept`, không
nhánh lỗi, chỉ gọi được trên rvalue (`const&&`), sửa cả hai bên trong cùng một tick. Hàm kiểm tự
kiểm lại miền của đề nghị (số lượng > 0, giá ≥ 0) và mọi trần ở bên NHẬN, dù parser đã kiểm: đó là
chỗ cuối cùng trước khi áp dụng không thể lỗi. Đảm bảo mạnh nói chung: refs/05 LH-12.

- **Vì sao:** kiểm-và-sửa xen kẽ (trừ đồ người bán, rồi mới phát hiện người mua đầy túi) để lại
  trạng thái nửa vời: vật phẩm biến mất hoặc nhân đôi — nguồn nhân bản kinh điển. Kiểm `&seller ==
  &buyer`: tự giao dịch với chính mình làm hai tham chiếu trỏ cùng túi, phép cộng/trừ chồng lên nhau.
  Kế hoạch giữ lại rồi áp dụng lần hai (gói xác nhận lặp) là nhân bản: `apply` chỉ nhận rvalue nên
  nơi gọi phải viết `std::move(plan).apply(…)`, và clang-tidy 20 `bugprone-use-after-move` báo lần
  dùng thứ hai (đã thử).
- **Kiểm:** test mỗi lý do từ chối để trạng thái nguyên vẹn (so trước/sau); test tự giao dịch; test
  người mua sát trần tiền và trần số lượng.

```cpp
// ✓ Chỉ TradePlan::check tạo được kế hoạch; apply không thể thất bại và tiêu thụ kế hoạch.
#include "core/check.hpp"

#include <cstdint>
#include <expected>

namespace game::trade {

enum class [[nodiscard]] TradeError : std::uint8_t {
    kBadOffer,
    kSamePouch,
    kNoItems,
    kNoCopper,
    kBagFull,
    kItemCap,
    kCopperCap,
};

// Trần kinh tế (MMO-07) và trần số lượng một loại vật phẩm trong túi.
inline constexpr std::int64_t kMaxCopper = 1'000'000'000'000'000;
inline constexpr std::int64_t kMaxPotions = 9'999;

// Bất biến: copper trong [0, kMaxCopper], potions trong [0, kMaxPotions], free_slots ≥ 0.
struct Pouch {
    std::int64_t copper = 0;
    std::int64_t potions = 0;
    std::int32_t free_slots = 0;
};

// Từ client: check() kiểm lại miền.
struct Offer {
    std::int64_t potions = 0;
    std::int64_t price = 0;
};

class TradePlan {
public:
    using CheckResult = std::expected<TradePlan, TradeError>;

    [[nodiscard]] static CheckResult check(const Pouch& seller, const Pouch& buyer, Offer offer) noexcept {
        if (offer.potions <= 0 || offer.price < 0) return std::unexpected(TradeError::kBadOffer);
        if (&seller == &buyer) return std::unexpected(TradeError::kSamePouch);
        if (seller.potions < offer.potions) return std::unexpected(TradeError::kNoItems);
        if (buyer.copper < offer.price) return std::unexpected(TradeError::kNoCopper);
        if (buyer.free_slots < 1) return std::unexpected(TradeError::kBagFull);
        if (offer.potions > kMaxPotions - buyer.potions) return std::unexpected(TradeError::kItemCap);
        if (offer.price > kMaxCopper - seller.copper) return std::unexpected(TradeError::kCopperCap);
        return TradePlan(offer);
    }

    // Cùng hai túi đã đưa vào check(), trong cùng tick: std::move(plan).apply(seller, buyer).
    void apply(Pouch& seller, Pouch& buyer) const&& noexcept {
        core::debug_check([&] { return &seller != &buyer; }, "TradePlan: túi trùng");
        seller.potions -= offer_.potions;
        seller.copper += offer_.price;
        buyer.potions += offer_.potions;
        buyer.copper -= offer_.price;
        buyer.free_slots -= 1;
    }

private:
    explicit TradePlan(Offer offer) noexcept : offer_(offer) {}
    Offer offer_;
};

} // namespace game::trade
```

### MMO-09 [N] PHẢI — Mọi thay đổi kinh tế ghi một sự kiện append-only: id giao dịch, nhân vật, luồng tiền, delta và số dư sau

Rơi đồ, mua/bán NPC, giao dịch, thư, phí chế tạo, GM cấp: mỗi lần một bản ghi cỡ cố định, gửi sang
luồng log kinh tế (DT-01) trước khi trả kết quả cho client. Hai bên của một giao dịch cùng `txn_id`.

- **Vì sao:** khi nhân bản xảy ra, câu hỏi đầu tiên là "vàng này từ đâu ra": không có nhật ký thì
  không trả lời được, không rollback chính xác được. Chuỗi `balance_after` cho phép máy kiểm phát
  hiện ngay mắt xích sai (sự kiện thiếu hoặc sửa số dư không qua kinh tế). Bản ghi 64 byte, không
  đệm ngầm (refs/03 KG-17): ghi nhị phân thẳng, đọc lại ổn định qua các phiên bản.
- **Kiểm:** job audit hằng giờ chạy `chains` trên nhật ký; test mỗi luồng tiền phát đúng một sự kiện.

```cpp
// ✓ Sự kiện kinh tế 64 byte, đủ để audit và dựng lại số dư.
#include <array>
#include <cstddef>
#include <cstdint>
#include <type_traits>

namespace game::core {

// Mốc: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

} // namespace game::core

namespace game::econ {

// Trần kinh tế (MMO-07).
inline constexpr std::int64_t kMaxCopper = 1'000'000'000'000'000;

enum class Flow : std::uint8_t { kLoot, kVendorSell, kVendorBuy, kTrade, kMail, kCraftFee, kGmGrant };

struct EconomyEvent {
    // Duy nhất toàn cục; hai bên giao dịch cùng id.
    std::uint64_t txn_id = 0;
    std::uint64_t account = 0;
    std::uint64_t character = 0;
    core::Tick tick{};
    std::int64_t delta_copper = 0;
    std::int64_t balance_after = 0;
    // 0: chỉ tiền.
    std::uint32_t item_template = 0;
    std::int32_t item_delta = 0;
    Flow flow = Flow::kLoot;
    // Đệm tường minh, luôn 0.
    std::array<std::byte, 7> reserved{};
};
static_assert(sizeof(EconomyEvent) == 64 && std::is_trivially_copyable_v<EconomyEvent>);

[[nodiscard]] constexpr bool in_cap(std::int64_t balance) noexcept {
    return balance >= 0 && balance <= kMaxCopper;
}

// Hai sự kiện liên tiếp của cùng nhân vật phải nối được: sai là thiếu sự kiện hoặc sửa lén. Nhật ký
// đọc từ đĩa có thể hỏng: số dư ngoài trần là "không nối", và trong trần thì phép trừ không tràn.
[[nodiscard]] constexpr bool chains(const EconomyEvent& previous, const EconomyEvent& next) noexcept {
    if (previous.character != next.character) return false;
    if (!in_cap(previous.balance_after) || !in_cap(next.balance_after)) return false;
    return next.balance_after - previous.balance_after == next.delta_copper;
}

inline constexpr EconomyEvent kPrevious{.character = 1, .balance_after = 100};
inline constexpr EconomyEvent kNext{.character = 1, .delta_copper = -30, .balance_after = 70};
static_assert(chains(kPrevious, kNext));

} // namespace game::econ
```

## 2. Nâng cao [C]

### MMO-10 [C] NÊN — AOI bằng lưới đều, cạnh ô ≥ bán kính nhìn, dựng lại mỗi tick bằng sắp xếp đếm vào hai mảng phẳng; truy vấn 3×3 ô

Không `vector<vector<id>>` mỗi ô, không cập nhật tăng dần khi thực thể đổi ô: mỗi tick đếm số thực
thể mỗi ô, cộng dồn, rải id vào một mảng (dạng CSR). Láng giềng 3×3 bằng bảng/công thức offset
(refs/02 PH-09); thứ tự ô theo Morton khi đo thấy lợi (refs/10 BN-16).

- **Vì sao:** dựng lại O(thực thể + ô), hai mảng liền, không cấp phát khi đủ capacity, không có ca
  "quên gỡ khỏi ô cũ". Với cỡ vài nghìn thực thể mỗi zone, chi phí dựng lại thường nhỏ so với ngân
  sách tick — xác nhận bằng benchmark trước khi chọn cập nhật tăng dần. Duyệt ngược khi rải nên id
  trong mỗi ô tăng dần: kết quả truy vấn tất định (replay, MMO-19).
- **Kiểm:** test so với truy vấn vét cạn O(n²) trên dữ liệu ngẫu nhiên có seed; benchmark theo số
  thực thể.

```cpp
// ✓ Lưới AOI dạng CSR: bounds_ (số ô + 1) và members_ (id theo ô); dựng lại mỗi tick.
#include "core/check.hpp"

#include <algorithm>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <numeric>
#include <span>
#include <vector>

namespace game::world {

// Bất biến của mọi CellPos đưa vào rebuild: đã kẹp vào [0, side) từ vị trí máy chủ.
struct CellPos {
    std::int32_t x = 0;
    std::int32_t y = 0;
};

class AoiGrid {
public:
    // side ô mỗi cạnh, trong [1, 4096]: bounds_ tối đa 2^24 + 1 phần tử.
    explicit AoiGrid(std::int32_t side) : side_(side), bounds_(cell_count(side) + 1) {}

    // cells[i] là ô của thực thể i. Sau đó ô k = members_[bounds_[k], bounds_[k + 1]).
    void rebuild(std::span<const CellPos> cells) {
        core::check(cells.size() < std::numeric_limits<std::uint32_t>::max(), "rebuild: quá nhiều");
        std::ranges::fill(bounds_, 0U);
        for (const CellPos cell : cells) {
            ++bounds_[key(cell)];
        }
        // Mỗi bounds_[k] thành vị trí cuối của ô k.
        std::inclusive_scan(bounds_.begin(), bounds_.end(), bounds_.begin());
        members_.resize(cells.size());
        for (auto entity = static_cast<std::uint32_t>(cells.size()); entity > 0; --entity) {
            // Lùi về đầu ô; duyệt ngược nên id trong mỗi ô tăng dần.
            const std::uint32_t slot = --bounds_[key(cells[entity - 1])];
            members_[slot] = entity - 1;
        }
    }

    [[nodiscard]] bool contains(CellPos cell) const noexcept {
        return cell.x >= 0 && cell.y >= 0 && cell.x < side_ && cell.y < side_;
    }

    [[nodiscard]] std::span<const std::uint32_t> members(CellPos cell) const noexcept {
        const std::size_t begin = bounds_[key(cell)];
        return std::span(members_).subspan(begin, bounds_[key(cell) + 1] - begin);
    }

private:
    [[nodiscard]] static std::size_t cell_count(std::int32_t side) noexcept {
        core::check(side >= 1 && side <= 4'096, "AoiGrid: side ngoài [1, 4096]");
        return static_cast<std::size_t>(side) * static_cast<std::size_t>(side);
    }

    // Ô ngoài lưới ở đây là ghi ngoài biên bounds_: lỗi lập trình, dừng ở bản debug.
    [[nodiscard]] std::size_t key(CellPos cell) const noexcept {
        core::debug_check([&] { return contains(cell); }, "AoiGrid: ô ngoài lưới");
        const auto row = static_cast<std::size_t>(cell.y);
        const auto column = static_cast<std::size_t>(cell.x);
        return (row * static_cast<std::size_t>(side_)) + column;
    }

    std::int32_t side_ = 0;
    std::vector<std::uint32_t> bounds_;
    std::vector<std::uint32_t> members_;
};

template <std::invocable<std::uint32_t> Visit>
void visit_cell(const AoiGrid& grid, CellPos cell, Visit& visit) {
    if (!grid.contains(cell)) return;
    for (const std::uint32_t entity : grid.members(cell)) {
        visit(entity);
    }
}

// Mọi thực thể trong 3×3 ô quanh center; i = 0..8 ánh xạ sang offset (i % 3 - 1, i / 3 - 1).
template <std::invocable<std::uint32_t> Visit>
void for_each_near(const AoiGrid& grid, CellPos center, Visit visit) {
    for (std::int32_t i = 0; i < 9; ++i) {
        visit_cell(grid, {.x = center.x + (i % 3) - 1, .y = center.y + (i / 3) - 1}, visit);
    }
}

} // namespace game::world
```

### MMO-11 [C] PHẢI — Thứ tự pha trong tick cố định và là dữ liệu: một bảng `constexpr` các pha, đo thời lượng từng pha

Thứ tự chuẩn: input → AI → di chuyển → chiến đấu → hết hạn hiệu ứng → AOI → snapshot/gửi → xếp
lưu. Không đăng ký hệ thống lúc chạy theo thứ tự khởi tạo tĩnh. Ngân sách từng pha: refs/09 HN-08.

- **Vì sao:** thứ tự là ngữ nghĩa: chiến đấu trước di chuyển thì tầm đánh tính trên vị trí cũ; AOI sau
  snapshot thì gửi thiếu thực thể vừa vào tầm. Thứ tự phụ thuộc thứ tự đăng ký thì đổi khi thêm tệp
  `.cpp` — lỗi không ai sửa code liên quan. Bảng một chỗ: đọc là thấy, review được.
- **Kiểm:** test tick mẫu với nhật ký pha; dashboard thời lượng mỗi pha (KTR-18).

```cpp
// ✓ Bảng pha constexpr; vòng tick (vỏ) đo từng pha. Hệ thống định nghĩa ở .cpp của chúng.
#include <array>
#include <chrono>
#include <ranges>
#include <span>
#include <string_view>

namespace game::sim {

struct World;
using PhaseFn = void (*)(World&) noexcept;

struct Phase {
    std::string_view name;
    PhaseFn run = nullptr;
};

void apply_inputs(World& world) noexcept;
void run_ai(World& world) noexcept;
void move_entities(World& world) noexcept;
void resolve_combat(World& world) noexcept;
void expire_effects(World& world) noexcept;
void update_interest(World& world) noexcept;
void send_snapshots(World& world) noexcept;
void queue_saves(World& world) noexcept;

inline constexpr std::array<Phase, 8> kTickPhases{{{.name = "input", .run = &apply_inputs},
    {.name = "ai", .run = &run_ai}, {.name = "move", .run = &move_entities}, {.name = "combat", .run = &resolve_combat},
    {.name = "effects", .run = &expire_effects}, {.name = "interest", .run = &update_interest},
    {.name = "snapshot", .run = &send_snapshots}, {.name = "save", .run = &queue_saves}}};

using PhaseTimes = std::span<std::chrono::nanoseconds, kTickPhases.size()>;

inline void run_tick(World& world, PhaseTimes spent) noexcept {
    for (auto&& [phase, total] : std::views::zip(kTickPhases, spent)) {
        const auto start = std::chrono::steady_clock::now();
        phase.run(world);
        total += std::chrono::steady_clock::now() - start;
    }
}

} // namespace game::sim
```

### MMO-12 [C] NÊN — Snapshot gửi delta so với baseline mà client đã xác nhận (ack), kèm mặt nạ trường đổi; baseline quá cũ thì gửi đầy đủ

Máy chủ giữ vòng N snapshot gần nhất mỗi client theo số thứ tự; client ack số thứ tự đã nhận;
delta tính so với bản ack mới nhất. Ack cũ hơn vòng giữ: gửi đầy đủ. Ack là đầu vào client: ack lớn
hơn số đã gửi hoặc nhỏ hơn ack trước thì bỏ, không tra vòng bằng nó. Thực thể mới vào tầm (không có
trong baseline) gửi đầy đủ; rời tầm gửi lệnh xoá cho tới khi được ack. Thực thể không đổi trường
nào: không gửi byte nào.

- **Vì sao:** phần lớn trường của phần lớn thực thể không đổi giữa hai tick; delta theo bản ĐÃ ACK
  (không theo bản đã gửi) chịu được mất gói UDP mà không cần gửi lại. Bảng con trỏ thành viên (như
  `member(i)` của math/types.hpp) giữ hàm so phẳng và tự mở rộng khi thêm trường.
- **Kiểm:** test round-trip: áp delta lên baseline phải ra đúng trạng thái mới, với mọi mặt nạ;
  test ack tương lai, ack lùi, ack ngoài vòng giữ.

```cpp
// ✓ Mặt nạ trường đổi qua bảng con trỏ thành viên; mặt nạ 0 = không gửi thực thể này.
#include <array>
#include <cstdint>

namespace game::proto {

struct NetEntity {
    std::int32_t x_cm = 0;
    std::int32_t y_cm = 0;
    std::int32_t hp = 0;
    std::int32_t animation = 0;
};

inline constexpr std::array<std::int32_t NetEntity::*, 4> kNetFields{
    &NetEntity::x_cm, &NetEntity::y_cm, &NetEntity::hp, &NetEntity::animation};

// Bit i bật khi trường kNetFields[i] khác baseline.
[[nodiscard]] constexpr std::uint32_t changed_mask(const NetEntity& baseline, const NetEntity& now) noexcept {
    std::uint32_t mask = 0;
    std::uint32_t bit = 1;
    for (const auto field : kNetFields) {
        mask |= (baseline.*field != now.*field) ? bit : 0U;
        bit <<= 1U;
    }
    return mask;
}

static_assert(changed_mask({}, {}) == 0);
static_assert(changed_mask({}, {.hp = 5}) == 0b0100U);

} // namespace game::proto
```

### MMO-13 [C] PHẢI — Input mỗi phiên đi qua cổng: số thứ tự trong cửa sổ, bỏ trùng và cũ, trần số input mỗi tick

Input mang số thứ tự tăng dần. Máy chủ nhận `last < seq ≤ last + kSequenceWindow`; vượt trần mỗi
tick thì giữ trong bộ đệm có giới hạn cho tick sau (jitter buffer), đầy thì bỏ và đếm. Bù trễ cho
kiểm trúng: lưu lịch sử vị trí vài tick (vòng), tua lại theo RTT do MÁY CHỦ đo, có trần (vd 200 ms);
không theo dấu thời gian client tự khai. Cổng thuộc nhân vật, không thuộc kết nối: kết nối lại
(MMO-16) tiếp tục `last` cũ, không đặt về 0 — nếu không, input đã áp dụng mà gửi lại sau khi nối lại
sẽ được nhận lần hai (phát lại gói).

- **Vì sao:** gửi dồn nhiều input một tick là tăng tốc (speed hack) dù mỗi input đều hợp lệ; gửi lại
  input cũ là nhân hành động (dùng kỹ năng hai lần). Tua lại theo thời gian client khai thì client
  tự chọn quá khứ có lợi cho mình.
- **Kiểm:** test lặp, đảo thứ tự, nhảy cửa sổ, dồn nhiều input một tick, gửi lại input cũ sau khi
  kết nối lại.

```cpp
// ✓ Cổng input: số thứ tự trong cửa sổ, tối đa kMaxInputsPerTick input được nhận mỗi tick.
#include <cstdint>

namespace game::sim {

enum class InputVerdict : std::uint8_t { kAccept, kStale, kTooFarAhead, kDeferred };

// Chỉ luồng zone. Số thứ tự 32 bit ở 20 input/giây đủ ~6,8 năm mỗi nhân vật.
class InputGate {
public:
    static constexpr std::uint32_t kSequenceWindow = 64;
    static constexpr std::int32_t kMaxInputsPerTick = 3;

    void on_tick() noexcept { accepted_this_tick_ = 0; }

    [[nodiscard]] InputVerdict admit(std::uint32_t sequence) noexcept {
        // Trùng hoặc cũ: bỏ.
        if (sequence <= last_) return InputVerdict::kStale;
        if (sequence - last_ > kSequenceWindow) return InputVerdict::kTooFarAhead;
        // Vượt trần tick này: nơi gọi giữ trong bộ đệm có giới hạn cho tick sau.
        if (accepted_this_tick_ >= kMaxInputsPerTick) return InputVerdict::kDeferred;
        last_ = sequence;
        ++accepted_this_tick_;
        return InputVerdict::kAccept;
    }

private:
    std::uint32_t last_ = 0;
    std::int32_t accepted_this_tick_ = 0;
};

} // namespace game::sim
```

### MMO-14 [C] PHẢI — Chống gian lận ở máy chủ: kiểm tốc độ, cooldown, tầm, tầm nhìn bằng số nguyên; vi phạm thì sửa về trạng thái máy chủ và cộng điểm nghi ngờ, không kick ngay

Khi giao thức cho client gửi vị trí (di chuyển dự đoán ở client), vị trí đó là một đề nghị cần kiểm
(MMO-01). Vị trí đơn vị cm trong `int32`, kiểm miền thế giới TRƯỚC khi tính; bình phương khoảng cách
trong `int64`, không `sqrt`. Điểm nghi ngờ có suy giảm theo thời gian; vượt ngưỡng trong cửa sổ mới
xử lý (đánh dấu, báo GM, kick).

- **Vì sao:** lag thật tạo vi phạm nhỏ hợp lệ (gói đến dồn); kick ở vi phạm đầu tiên là phạt người
  mạng kém. Kéo về vị trí máy chủ (rubber-band) vô hiệu hoá gian lận ngay mà không cần chắc chắn.
  Kiểm miền trước khi bình phương: hiệu hai `int32` tuỳ ý tới ~2^32, bình phương tràn `int64` (UB);
  giới hạn |toạ độ| ≤ 2^29 cm (≈ 5 368 km) thì tổng hai bình phương ≤ 2^61.
- **Kiểm:** test ca biên miền; replay log người chơi thật để đo tỉ lệ dương tính giả.

```cpp
// ✓ Kiểm tốc độ: miền trước, rồi so bình phương trong int64 — không tràn, không sqrt.
#include "core/check.hpp"

#include <cstdint>

namespace game::anticheat {

inline constexpr std::int32_t kWorldLimitCm = 1 << 29;
inline constexpr std::int64_t kMaxStepCm = std::int64_t{1} << 30;

struct PositionCm {
    std::int32_t x = 0;
    std::int32_t y = 0;
};

// previous: vị trí máy chủ đã chấp nhận; claimed: vị trí client gửi.
struct MoveClaim {
    PositionCm previous{};
    PositionCm claimed{};
};

enum class MoveVerdict : std::uint8_t { kOk, kOutOfWorld, kTooFast };

// Trong miền thế giới thì hiệu hai toạ độ đủ nhỏ để tổng bình phương không tràn int64.
[[nodiscard]] constexpr bool in_world(std::int32_t coord_cm) noexcept {
    return coord_cm > -kWorldLimitCm && coord_cm < kWorldLimitCm;
}

// allowed_cm: quãng tối đa trong khoảng tick đã trôi (gồm dung sai), do máy chủ tính, trong [0, kMaxStepCm].
[[nodiscard]] constexpr MoveVerdict check_move(MoveClaim move, std::int64_t allowed_cm) noexcept {
    core::check(allowed_cm >= 0 && allowed_cm <= kMaxStepCm, "check_move: allowed_cm ngoài miền");
    if (!in_world(move.claimed.x) || !in_world(move.claimed.y)) return MoveVerdict::kOutOfWorld;
    const std::int64_t delta_x = std::int64_t{move.claimed.x} - move.previous.x;
    const std::int64_t delta_y = std::int64_t{move.claimed.y} - move.previous.y;
    if ((delta_x * delta_x) + (delta_y * delta_y) > allowed_cm * allowed_cm) return MoveVerdict::kTooFast;
    return MoveVerdict::kOk;
}

static_assert(check_move({.claimed = {.x = 300, .y = 400}}, 500) == MoveVerdict::kOk);
static_assert(check_move({.claimed = {.x = 300, .y = 401}}, 500) == MoveVerdict::kTooFast);

} // namespace game::anticheat
```

### MMO-15 [C] PHẢI — Lưu DB bất đồng bộ kiểu write-behind với số phiên bản: luồng zone không chờ DB; ghi có điều kiện để thử lại an toàn

Zone đánh dấu bẩn và tăng `version` (nạp từ DB rồi tăng tiếp, không bao giờ đặt lại); định kỳ gửi
job `(nhân vật, epoch, version, blob)` sang pool DB (DT-08). Khi nạp nhân vật, zone nhận quyền ghi
bằng cách tăng `owner_epoch` ở DB (fencing token); mỗi lần ghi kiểm cả epoch lẫn version. Ack mang
version, ack muộn không làm lùi `saved_version`. Đăng xuất, chuyển zone: lưu ngay. Giao dịch giữa
người chơi: một transaction DB cho cả hai bên (MMO-21). Tắt có kế hoạch (bảo trì, SIGTERM qua
UB-21): đóng cổng đăng nhập, lưu mọi nhân vật bẩn, chờ ack có hạn chót, rồi thoát — đường này chỉ
để nhanh, đường đúng là phục hồi sau sập (LH-19).

- **Vì sao:** chờ DB trong tick là để độ trễ đĩa/mạng của DB thành lag của cả zone. Có version thì
  job thử lại sau timeout, job đến trễ, job lặp đều vô hại (idempotent) — không bao giờ ghi đè dữ
  liệu mới bằng dữ liệu cũ. Version một mình chưa đủ: zone A sập khi đang giữ version 105 trong bộ
  nhớ, zone B nạp lại từ DB (version 100) và lưu 101..104; job 105 của A đến muộn sẽ thắng và ghi đè
  bằng trạng thái cũ. Epoch làm mọi job của chủ cũ vô hiệu. Sập zone chỉ mất phần sau lần lưu cuối.
- **Kiểm:** test đảo thứ tự ack; test sập giữa chừng rồi nạp lại; test job của chủ cũ đến sau khi
  chủ mới đã ghi.

```text
-- Nạp (cú pháp PostgreSQL): nhận quyền ghi; chủ cũ, nếu còn sống, mất quyền từ đây.
UPDATE characters SET owner_epoch = owner_epoch + 1 WHERE id = ?
  RETURNING owner_epoch, version, blob;
-- Lưu: chỉ chủ hiện tại, chỉ bản mới hơn; job lặp, job cũ, job của chủ cũ không đổi dòng nào.
UPDATE characters SET blob = ?, version = ? WHERE id = ? AND owner_epoch = ? AND version < ?;
```

```cpp
// ✓ Trạng thái lưu của một nhân vật: chỉ luồng zone đọc/ghi, không IO.
#include <algorithm>
#include <cstdint>
#include <utility>

namespace game::sim {

// Mốc: số tick từ lúc zone khởi động (MMO-03).
enum class Tick : std::uint64_t {};

struct PersistState {
    // Nạp từ DB rồi tăng mỗi lần đổi trạng thái cần lưu.
    std::uint64_t version = 0;
    // Bản mới nhất DB đã xác nhận.
    std::uint64_t saved_version = 0;
    // Lần gửi job gần nhất: job đang bay thì không gửi lại trước một chu kỳ.
    Tick last_sent{};
};

constexpr void mark_dirty(PersistState& state) noexcept {
    ++state.version;
}

[[nodiscard]] constexpr bool due_for_save(const PersistState& state, Tick now, std::uint64_t interval_ticks) noexcept {
    const std::uint64_t waited_ticks = std::to_underlying(now) - std::to_underlying(state.last_sent);
    return state.version != state.saved_version && waited_ticks >= interval_ticks;
}

// Vỏ gọi ngay khi đẩy job (nhân vật, epoch, version, blob) sang pool DB.
constexpr void on_sent(PersistState& state, Tick now) noexcept {
    state.last_sent = now;
}

// Ack đến không theo thứ tự: chỉ tiến, không lùi.
constexpr void on_saved(PersistState& state, std::uint64_t acked_version) noexcept {
    state.saved_version = std::max(state.saved_version, acked_version);
}

static_assert([] {
    PersistState state{.version = 7, .saved_version = 7};
    mark_dirty(state);
    const bool due = due_for_save(state, Tick{600}, 600);
    on_sent(state, Tick{600});
    const bool resent = due_for_save(state, Tick{601}, 600);
    on_saved(state, 8);
    on_saved(state, 6);
    return due && !resent && state.saved_version == 8;
}());

} // namespace game::sim
```

### MMO-16 [C] PHẢI — Opcode được phép phụ thuộc trạng thái phiên; kiểm trước khi giải mã thân gói

Bảng "trạng thái → mặt nạ opcode" là hàm `constexpr` phẳng; opcode ngoài miền hay không hợp trạng
thái thì từ chối và đếm, không giải mã thân. Bảng chuyển trạng thái phiên: refs/02 PH-12. Vòng đời
phiên cũng nằm trong bảng đó. Mất kết nối khác đăng xuất: nhân vật ở lại thế giới một thời hạn
(chống thoát giữa trận); kết nối lại trong hạn bằng token nối lại do máy chủ cấp (dùng một lần, gắn
tài khoản và nhân vật) thì gắn vào đúng nhân vật đó và giữ cổng input (MMO-13). Hết hạn hay đăng
xuất: lưu ngay (MMO-15) rồi gỡ. Đăng nhập lần nữa cùng tài khoản: đá phiên cũ, lưu và gỡ xong mới
nạp — không bao giờ có hai bản của một nhân vật trong bộ nhớ.

- **Vì sao:** handler `Move` chạy khi phiên chưa đăng nhập, hay `SelectCharacter` khi đang trong
  thế giới, là lớp lỗi nhân bản/crash phổ biến (nhân vật được nạp hai lần). Kiểm ở cửa vào giữ mọi
  handler phía sau khỏi phải tự kiểm trạng thái.
- **Kiểm:** test vét cạn mọi cặp (trạng thái, opcode) so với bảng mong đợi; fuzz; test đăng nhập
  trùng và kết nối lại giữa lúc đang lưu.

```cpp
// ✓ Mặt nạ opcode theo trạng thái: switch phẳng, enum không default, sau switch là fail.
#include "core/check.hpp"

#include <cstdint>
#include <utility>

namespace game::net {

enum class SessionState : std::uint8_t { kHandshake, kAuthenticating, kCharacterSelect, kInWorld };
enum class Opcode : std::uint8_t { kHello, kLogin, kSelect, kMove, kCast, kChat, kLogout, kCount };

// Mặt nạ 64 bit: thêm opcode thứ 65 phải đổi cách lưu mặt nạ, không được dịch quá độ rộng (UB).
static_assert(std::to_underlying(Opcode::kCount) <= 64);

[[nodiscard]] constexpr std::uint64_t bit(Opcode opcode) noexcept {
    return std::uint64_t{1} << std::to_underlying(opcode);
}

[[nodiscard]] constexpr std::uint64_t allowed(SessionState state) noexcept {
    switch (state) {
    case SessionState::kHandshake: return bit(Opcode::kHello);
    case SessionState::kAuthenticating: return bit(Opcode::kLogin);
    case SessionState::kCharacterSelect: return bit(Opcode::kSelect) | bit(Opcode::kLogout);
    case SessionState::kInWorld:
        return bit(Opcode::kMove) | bit(Opcode::kCast) | bit(Opcode::kChat) | bit(Opcode::kLogout);
    }
    core::fail("SessionState ngoài miền");
}

// raw_opcode đến từ client: ngoài miền thì false, không bao giờ dừng tiến trình.
[[nodiscard]] constexpr bool is_allowed(SessionState state, std::uint16_t raw_opcode) noexcept {
    if (raw_opcode >= std::to_underlying(Opcode::kCount)) return false;
    return ((allowed(state) >> raw_opcode) & 1U) != 0;
}

static_assert(!is_allowed(SessionState::kHandshake, std::to_underlying(Opcode::kMove)));
static_assert(is_allowed(SessionState::kInWorld, std::to_underlying(Opcode::kMove)));

} // namespace game::net
```

### MMO-17 [C] PHẢI — Ngẫu nhiên gameplay dùng PRNG tự viết (xoshiro256** gieo bằng splitmix64) và phân phối tự viết; mỗi hệ thống một luồng ngẫu nhiên có seed ghi log

"Luồng ngẫu nhiên" ở đây là dòng số (stream), không phải thread. Rơi đồ, chí mạng, AI, sinh quái:
mỗi thứ một engine, seed suy từ seed của zone và id hệ thống, ghi vào log để replay. Không dùng
`std::uniform_int_distribution` và họ hàng (khác nhau giữa libstdc++, libc++, MSVC: refs/08 STD-14).
xoshiro không phải PRNG mật mã: không gửi seed hay trạng thái cho client, không dùng nó cho token
phiên, token nối lại, mã xác nhận — những thứ đó lấy từ nguồn ngẫu nhiên mật mã của hệ điều hành.

- **Vì sao:** cùng seed phải cho cùng dãy trên mọi máy, mọi trình dịch — replay, test vàng, điều tra
  khiếu nại "rơi đồ sai". Engine riêng mỗi hệ thống: thêm một lần gieo ở AI không làm lệch dãy rơi đồ.
  `x % n` thiên lệch khi n không chia hết 2^32; phép nhân rồi loại phần lệch (D. Lemire, 2019) đều
  tuyệt đối. Bản dưới luôn tính một phép chia; bản "nearly divisionless" bỏ được phép chia ở đa số
  lần gọi nhưng cần thêm một nhánh lồng.
- **Kiểm:** `static_assert` giá trị chuẩn của splitmix64 (seed 0 → `0xE220A8397B1DCDAF`) và giá trị
  vàng của xoshiro256** (khớp bản cài đặt Python độc lập với cùng seed); test phân bố χ² cho `below`;
  clang-tidy `cert-msc50-cpp` bắt `rand()` — bỏ qua gợi ý "dùng `<random>`" của nó (STD-14).

```cpp
// ✓ xoshiro256** (Blackman, Vigna) + splitmix64; giá trị vàng chốt thuật toán lúc biên dịch.
#include "core/check.hpp"

#include <array>
#include <bit>
#include <cstdint>

namespace game::rng {

// splitmix64 (Vigna): chỉ dùng để gieo; mọi seed, kể cả 0, cho trạng thái xoshiro khác 0.
class SplitMix64 {
public:
    explicit constexpr SplitMix64(std::uint64_t seed) noexcept : state_(seed) {}

    [[nodiscard]] constexpr std::uint64_t next() noexcept {
        state_ += 0x9E37'79B9'7F4A'7C15U;
        std::uint64_t mixed = state_;
        mixed = (mixed ^ (mixed >> 30U)) * 0xBF58'476D'1CE4'E5B9U;
        mixed = (mixed ^ (mixed >> 27U)) * 0x94D0'49BB'1331'11EBU;
        return mixed ^ (mixed >> 31U);
    }

private:
    std::uint64_t state_;
};

class Xoshiro256 {
public:
    explicit constexpr Xoshiro256(std::uint64_t seed) noexcept : Xoshiro256(SplitMix64(seed)) {}

    [[nodiscard]] constexpr std::uint64_t next() noexcept {
        const std::uint64_t result = std::rotl(state_[1] * 5, 7) * 9;
        const std::uint64_t shifted = state_[1] << 17U;
        state_[2] ^= state_[0];
        state_[3] ^= state_[1];
        state_[1] ^= state_[2];
        state_[0] ^= state_[3];
        state_[2] ^= shifted;
        state_[3] = std::rotl(state_[3], 45);
        return result;
    }

    // Đều trong [0, bound), bound ≥ 1.
    [[nodiscard]] constexpr std::uint32_t below(std::uint32_t bound) noexcept {
        core::check(bound != 0, "below: bound phải ≥ 1");
        // 2^32 mod bound
        const std::uint32_t threshold = (0U - bound) % bound;
        std::uint64_t product = (next() >> 32U) * bound;
        while (static_cast<std::uint32_t>(product) < threshold) {
            product = (next() >> 32U) * bound;
        }
        return static_cast<std::uint32_t>(product >> 32U);
    }

private:
    // Braced-init-list đánh giá trái sang phải: state_[0] là đầu ra thứ nhất của splitmix64.
    explicit constexpr Xoshiro256(SplitMix64 mixer) noexcept
        : state_{mixer.next(), mixer.next(), mixer.next(), mixer.next()} {}

    std::array<std::uint64_t, 4> state_;
};

static_assert(SplitMix64(0).next() == 0xE220'A839'7B1D'CDAFU);
static_assert(Xoshiro256(1).next() == 0xB3F2'AF6D'0FC7'10C5U);

} // namespace game::rng
```

## 3. Thần thoại [T]

### MMO-18 [T] PHẢI — Mô phỏng phải tất định (lockstep, replay, kiểm chéo) thì dùng số học điểm cố định và loại mọi nguồn bất định đã biết

Nguồn bất định phải loại: số thực (cờ FP, FMA, hàm siêu việt libm — chính sách ở refs/11 SV);
duyệt `unordered_*` và `std::hash` (refs/08 STD-15); phân phối `<random>` (STD-14); sắp xếp theo
địa chỉ con trỏ; đọc đồng hồ trong logic (KTR-07); rút gọn song song phụ thuộc thứ tự luồng; đọc
bộ nhớ chưa khởi tạo/đệm. Replay = seed + dòng input có tick; chạy lại phải ra cùng hash (MMO-19).

- **Vì sao:** một bit lệch ở tick 1 000 lan thành vị trí khác hẳn ở tick 10 000; lỗi tất định chỉ
  tìm được khi mọi nguồn đã bị loại từ thiết kế. Q16.16 trên `int32`: cộng/trừ/nhân/chia nguyên,
  giống nhau từng bit trên mọi máy. Từ C++20 `>>` trên số âm là dịch số học (làm tròn về −∞) và
  chuyển đổi thu hẹp là modulo — đều xác định; còn `/` làm tròn về 0: hai quy tắc làm tròn khác nhau
  nhưng đều tất định, ghi rõ trong comment.
- **Kiểm:** replay test trong CI (refs/15 KT-16): log input thật, chạy lại trên GCC và Clang, so hash.

```cpp
// ✓ Q16.16 tất định: phép nhân/chia qua int64, tràn và chia 0 bị check chặn.
#include "core/check.hpp"

#include <cstdint>
#include <limits>

namespace game::math {

struct Fixed {
    // Giá trị = raw / 65536, miền [-32768, 32768).
    std::int32_t raw = 0;

    [[nodiscard]] static constexpr Fixed from_int(std::int32_t value) noexcept {
        core::check(value >= -32'768 && value < 32'768, "Fixed: ngoài miền Q16.16");
        return {.raw = value * 65'536};
    }

    [[nodiscard]] friend constexpr bool operator==(Fixed, Fixed) = default;

    [[nodiscard]] friend constexpr Fixed operator+(Fixed lhs, Fixed rhs) noexcept {
        return narrow(std::int64_t{lhs.raw} + rhs.raw);
    }
    // Dịch phải số học: làm tròn về −∞.
    [[nodiscard]] friend constexpr Fixed operator*(Fixed lhs, Fixed rhs) noexcept {
        return narrow((std::int64_t{lhs.raw} * rhs.raw) >> 16U);
    }
    // Chia nguyên: làm tròn về 0.
    [[nodiscard]] friend constexpr Fixed operator/(Fixed lhs, Fixed rhs) noexcept {
        core::check(rhs.raw != 0, "Fixed: chia cho 0");
        return narrow((std::int64_t{lhs.raw} * 65'536) / rhs.raw);
    }

private:
    [[nodiscard]] static constexpr Fixed narrow(std::int64_t wide) noexcept {
        constexpr std::int64_t kLow = std::numeric_limits<std::int32_t>::min();
        constexpr std::int64_t kHigh = std::numeric_limits<std::int32_t>::max();
        core::check(wide >= kLow && wide <= kHigh, "Fixed: tràn");
        return {.raw = static_cast<std::int32_t>(wide)};
    }
};

static_assert(Fixed::from_int(3) * Fixed::from_int(-2) == Fixed::from_int(-6));
static_assert((Fixed{.raw = -1} * Fixed::from_int(1)).raw == -1);
// 3,5
static_assert((Fixed::from_int(7) / Fixed::from_int(2)).raw == 229'376);

} // namespace game::math
```

### MMO-19 [T] NÊN — Băm trạng thái mô phỏng định kỳ, theo thứ tự id, nạp từng trường bằng byte tường minh; so giữa máy chủ, replay và bản chuyển giao

Mỗi N tick (vd 20) băm các thành phần tất định theo thứ tự id; lệch thì dump trạng thái tick đó hai
phía và chia đôi khoảng tick bằng replay để tìm tick đầu tiên lệch. Dùng cho replay test, chuyển giao
zone (KTR-17), kiểm client lockstep.

- **Vì sao:** băm bộ nhớ thô của struct là băm cả byte đệm (rác) và phụ thuộc endian, bố cục —
  hash khác nhau dù trạng thái giống. Nạp từng trường bằng giá trị có thứ tự byte cố định thì hash là
  hàm của trạng thái logic. FNV-1a 64 đủ cho phát hiện lệch (không phải chống giả mạo).
- **Kiểm:** `static_assert` vector chuẩn FNV-1a; test: đổi một trường một bit thì hash đổi.

```cpp
// ✓ FNV-1a 64 trên giá trị trường (little-endian logic), không trên byte bộ nhớ của struct.
#include <cstdint>
#include <span>

namespace game::sim {

class StateHash {
public:
    constexpr StateHash& add_byte(std::uint8_t byte) noexcept {
        hash_ = (hash_ ^ byte) * 0x0000'0100'0000'01B3U;
        return *this;
    }

    constexpr StateHash& add(std::uint32_t value) noexcept {
        add_byte(static_cast<std::uint8_t>(value));
        add_byte(static_cast<std::uint8_t>(value >> 8U));
        add_byte(static_cast<std::uint8_t>(value >> 16U));
        add_byte(static_cast<std::uint8_t>(value >> 24U));
        return *this;
    }

    // Số có dấu băm theo biểu diễn bù hai: int32 → uint32 là phép đổi modulo, xác định từ C++20.
    constexpr StateHash& add(std::int32_t value) noexcept { return add(static_cast<std::uint32_t>(value)); }

    [[nodiscard]] constexpr std::uint64_t value() const noexcept { return hash_; }

private:
    std::uint64_t hash_ = 0xCBF2'9CE4'8422'2325U;
};

static_assert(StateHash{}.add_byte('a').value() == 0xAF63'DC4C'8601'EC8CU);

struct EntityState {
    std::uint32_t id = 0;
    // Fixed::raw (MMO-18).
    std::int32_t x_raw = 0;
    std::int32_t y_raw = 0;
    std::int32_t hp = 0;
};

// entities phải theo thứ tự id tăng dần (mảng thành phần giữ thứ tự đó).
[[nodiscard]] constexpr std::uint64_t hash_entities(std::span<const EntityState> entities) noexcept {
    StateHash hash;
    for (const EntityState& entity : entities) {
        hash.add(entity.id).add(entity.x_raw).add(entity.y_raw).add(entity.hp);
    }
    return hash.value();
}

} // namespace game::sim
```

### MMO-20 [T] CÓ THỂ — Nén trạng thái gửi đi bằng bit-packing, zigzag + varint cho số có dấu nhỏ, và lượng tử hoá theo miền

Toạ độ gửi tương đối với ô AOI: ô 64 m ở độ phân giải 1 cm cần 13 bit (6 400 < 2^13) thay vì 32;
hướng nhìn 8 bit (1,4°); máu theo phần trăm 7 bit khi client chỉ vẽ thanh máu. Delta có dấu nhỏ:
zigzag rồi varint. Mọi lượng tử hoá ghi sai số tối đa trong comment.

- **Vì sao:** băng thông ra là chi phí vận hành lớn và trần số người chơi mỗi zone; mỗi bit mỗi
  thực thể mỗi tick nhân với (người xem × thực thể × 20 Hz). Zigzag đưa số âm nhỏ thành số dương
  nhỏ (−1 → 1) để varint ngắn; mọi phép dịch làm trên `uint32_t` nên không phụ thuộc dịch số có dấu.
  Bộ ghi bit (gom bit vào thanh ghi 64 bit, xả từng byte) phải chặn số bit ≤ 32 ở hợp đồng: dịch
  bằng độ rộng kiểu (`value >> 32` trên `uint32_t`) là UB. Bộ ĐỌC là chỗ nguy hiểm: varint `uint32`
  tối đa 5 byte, byte thứ năm chỉ mang 4 bit; đọc tới khi gặp byte kết thúc mà không trần thì dịch
  35 bit (UB) và vòng lặp chạy theo dữ liệu client.
- **Kiểm:** `static_assert` ca biên (cụt, 5 byte tràn, đúng trần); test round-trip ngẫu nhiên có
  seed cho mọi bộ mã; fuzz bộ đọc (KT-11).

```cpp
// ✓ Zigzag (đúng cả INT32_MIN) + varint LEB128: delta có dấu nhỏ thành 1–2 byte.
#include <cstddef>
#include <cstdint>
#include <limits>
#include <vector>

namespace game::proto {

// Bit dấu lan ra 32 bit bằng 0 - sign trên số không dấu.
[[nodiscard]] constexpr std::uint32_t zigzag(std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    return (bits << 1U) ^ (0U - (bits >> 31U));
}

[[nodiscard]] constexpr std::int32_t unzigzag(std::uint32_t value) noexcept {
    return static_cast<std::int32_t>((value >> 1U) ^ (0U - (value & 1U)));
}

inline constexpr std::int32_t kMinInt = std::numeric_limits<std::int32_t>::min();
static_assert(zigzag(0) == 0 && zigzag(-1) == 1 && zigzag(1) == 2);
static_assert(zigzag(kMinInt) == 0xFFFF'FFFFU && unzigzag(zigzag(kMinInt)) == kMinInt);

// 7 bit mỗi byte, bit cao = còn byte sau; uint32 dùng 1–5 byte. Ghi nối vào gói đang dựng.
constexpr void put_varint(std::vector<std::byte>& packet, std::uint32_t value) {
    while (value >= 0x80U) {
        packet.push_back(static_cast<std::byte>((value & 0x7FU) | 0x80U));
        value >>= 7U;
    }
    packet.push_back(static_cast<std::byte>(value));
}

// zigzag(150) = 300 → AC 02: đúng vector ví dụ trong tài liệu protobuf.
static_assert([] {
    std::vector<std::byte> packet;
    put_varint(packet, zigzag(150));
    return packet.size() == 2 && packet[0] == std::byte{0xAC} && packet[1] == std::byte{0x02};
}());

} // namespace game::proto
```

```cpp
// ✓ Đọc varint từ client: tìm byte kết thúc trong 5 byte đầu rồi mới giải mã; cụt, tràn là lỗi.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>

namespace game::proto {

inline constexpr std::size_t kMaxVarintBytes = 5;

struct Varint {
    std::uint32_t value = 0;
    // Số byte đã dùng, trong [1, kMaxVarintBytes].
    std::size_t length = 0;
};

[[nodiscard]] constexpr bool is_last_byte(std::byte byte) noexcept {
    return (byte & std::byte{0x80}) == std::byte{0};
}

// nullopt: cụt, dài quá 5 byte, hoặc byte thứ năm vượt 4 bit (giá trị ≥ 2^32). Vòng giải mã chạy
// theo length ≤ 5 đã kiểm, mọi phép dịch ≤ 28 bit. Không từ chối mã dài thừa (80 00 cho 0).
[[nodiscard]] constexpr std::optional<Varint> take_varint(std::span<const std::byte> bytes) noexcept {
    const std::span<const std::byte> head = bytes.first(std::min(bytes.size(), kMaxVarintBytes));
    const auto last = std::ranges::find_if(head, is_last_byte);
    if (last == head.end()) return std::nullopt;
    const auto length = static_cast<std::size_t>(last - head.begin()) + 1;
    const bool overflow = length == kMaxVarintBytes && std::to_integer<std::uint32_t>(*last) > 0x0FU;
    if (overflow) return std::nullopt;
    std::uint32_t value = 0;
    for (std::size_t i = 0; i < length; ++i) {
        value |= (std::to_integer<std::uint32_t>(head[i]) & 0x7FU) << (7U * i);
    }
    return Varint{.value = value, .length = length};
}

inline constexpr std::array<std::byte, 5> kMaxU32{
    std::byte{0xFF}, std::byte{0xFF}, std::byte{0xFF}, std::byte{0xFF}, std::byte{0x0F}};
inline constexpr std::array<std::byte, 5> kTooBig{
    std::byte{0xFF}, std::byte{0xFF}, std::byte{0xFF}, std::byte{0xFF}, std::byte{0x10}};
static_assert(take_varint(kMaxU32)->value == 0xFFFF'FFFFU);
static_assert(!take_varint(kTooBig).has_value());
static_assert(!take_varint(std::span(kMaxU32).first(4)).has_value());

} // namespace game::proto
```

### MMO-21 [T] PHẢI — Chống nhân bản vật phẩm: uid duy nhất toàn cục cho vật phẩm giá trị, id giao dịch cho mọi lần chuyển, DB áp dụng idempotent trong một transaction

Vật phẩm không xếp chồng (trang bị, hiếm) có `ItemUid = (nút 16 bit << 48) | dãy 48 bit`; nút xin DB
một khối dãy bền trước khi dùng. Số nút cũng do DB cấp (thuê có hạn), không lấy từ tệp cấu hình chép
tay: hai tiến trình cùng số nút là cấp trùng uid. Mọi chuyển giao (giao dịch, thư, đấu giá, chuyển zone) mang
`txn_id`; DB ghi `applied_txn(txn_id PRIMARY KEY)` cùng transaction với thay đổi vật phẩm của CẢ
HAI bên. Audit định kỳ: uid xuất hiện ở hai chủ.

- **Vì sao:** nhân bản kinh điển đến từ ranh giới giữa bộ nhớ và DB: giao dịch xong, bên A được lưu,
  zone sập trước khi B được lưu → khôi phục B bản cũ còn đồ. Một transaction cho hai bên + bảng txn
  đã áp dụng làm thử lại an toàn và loại ca nửa vời. Uid theo khối: không hỏi DB mỗi lần tạo đồ; sập
  giữa khối thì mất số, không bao giờ trùng số.
- **Kiểm:** ràng buộc `UNIQUE(item_uid)` ở DB; test sập ở mọi bước của giao dịch (fault injection);
  job audit.

```cpp
// ✓ Cấp uid từ khối dãy đã được DB đặt trước bền: duy nhất toàn cục, không round-trip DB mỗi lần.
#include "core/check.hpp"

#include <cstdint>
#include <optional>

namespace game::inv {

enum class ItemUid : std::uint64_t {};

struct UidBlock {
    // [begin, end) ⊂ [0, 2^48), DB đã ghi bền là đã cấp cho nút này.
    std::uint64_t begin = 0;
    std::uint64_t end = 0;
};

// Chỉ luồng zone. Xin khối mới bất đồng bộ khi remaining() xuống dưới ngưỡng (vd 10 %).
class UidAllocator {
public:
    UidAllocator(std::uint16_t node, UidBlock block) noexcept : node_(node), next_(block.begin), end_(block.end) {
        core::check(block.begin <= block.end && block.end <= (std::uint64_t{1} << 48U), "UidAllocator: khối sai");
    }

    // nullopt: hết khối — từ chối tạo đồ tick này, không bao giờ tự sinh số ngoài khối.
    [[nodiscard]] std::optional<ItemUid> next() noexcept {
        if (next_ == end_) return std::nullopt;
        const std::uint64_t sequence = next_++;
        return ItemUid{(std::uint64_t{node_} << 48U) | sequence};
    }

    [[nodiscard]] std::uint64_t remaining() const noexcept { return end_ - next_; }

private:
    std::uint16_t node_ = 0;
    std::uint64_t next_ = 0;
    std::uint64_t end_ = 0;
};

} // namespace game::inv
```

### MMO-22 [T] PHẢI — Ngân sách tick: rút hộp thư có hạn mức, cắt tải theo mức có trễ khi p95 tick vượt ngưỡng; không bao giờ cắt input, chiến đấu, kinh tế

Mỗi tick rút tối đa K thông điệp mỗi phiên (phần dư để tick sau, hộp thư có trần — DT-01, DT-14);
hàng gửi mỗi phiên có trần byte (UB-13). Đo tick: refs/09 HN-08, HN-18. Khi p95 vượt ngưỡng: giãn
tần số snapshot của thực thể xa, giãn AI của quái không có người chơi gần; xuống mức khi p95 dưới
ngưỡng thấp hơn.

- **Vì sao:** tick vượt ngân sách thì mọi người chơi trong zone cùng lag; giảm chất lượng ở chỗ ít
  thấy (thực thể xa, quái không ai nhìn) giữ tick đều. Hai ngưỡng (trễ) chặn dao động lên-xuống mỗi
  tick. Input, chiến đấu, kinh tế bị cắt là sai luật chơi, không phải giảm chất lượng.
- **Kiểm:** test tải giả lập; số liệu mức cắt tải theo thời gian; test bảng: mọi mức có ngưỡng
  xuống < ngưỡng lên.

```cpp
// ✓ Mức cắt tải là bảng; chuyển mức theo p95 với hai ngưỡng (trễ) để không dao động.
#include "core/check.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::sim {

struct ShedLevel {
    // p95 vượt ngưỡng: lên mức kế.
    std::chrono::microseconds raise_above{};
    // p95 dưới ngưỡng: về mức trước.
    std::chrono::microseconds lower_below{};
    // Thực thể xa: gửi mỗi N tick.
    std::int32_t far_snapshot_every_ticks = 1;
    // Quái không có người chơi gần: AI mỗi N tick.
    std::int32_t idle_ai_every_ticks = 1;
};

// Ngân sách tick 50 ms.
inline constexpr std::array<ShedLevel, 3> kShedLevels{{
    {.raise_above = std::chrono::milliseconds{35},
        .lower_below = {},
        .far_snapshot_every_ticks = 1,
        .idle_ai_every_ticks = 1},
    {.raise_above = std::chrono::milliseconds{42},
        .lower_below = std::chrono::milliseconds{28},
        .far_snapshot_every_ticks = 2,
        .idle_ai_every_ticks = 4},
    {.raise_above = std::chrono::microseconds::max(),
        .lower_below = std::chrono::milliseconds{34},
        .far_snapshot_every_ticks = 4,
        .idle_ai_every_ticks = 10},
}};

// Mức cuối có raise_above = max, mức 0 có lower_below = 0 nên kết quả không ra khỏi bảng.
[[nodiscard]] constexpr std::size_t next_level(std::size_t level, std::chrono::microseconds tick_p95) noexcept {
    core::check(level < kShedLevels.size(), "next_level: level ngoài bảng");
    const ShedLevel& current = std::span(kShedLevels)[level];
    if (tick_p95 > current.raise_above) return level + 1;
    if (tick_p95 < current.lower_below) return level - 1;
    return level;
}

static_assert(next_level(0, std::chrono::milliseconds{40}) == 1);
static_assert(next_level(1, std::chrono::milliseconds{30}) == 1);
static_assert(next_level(1, std::chrono::milliseconds{20}) == 0);

} // namespace game::sim
```

### MMO-23 [T] PHẢI — Chuyển thực thể giữa zone bằng hai pha có id chuyển giao: tại mọi thời điểm đúng một zone làm chủ, mọi thông điệp lặp đều vô hại

Zone nguồn là bên quyết định, ghi bản ghi chuyển giao bền; zone đích chỉ "mở băng" thực thể khi nhận
Commit. Điểm quyết định là lúc ghi bền COMMITTED, trước mọi tác dụng khác. Đích không bao giờ tự xoá
bản đóng băng vì hết hạn: nó hỏi nguồn kết cục của T (nguồn trả theo bản ghi bền). Quyền ghi DB của
E đi theo chủ: đích nhận epoch mới khi mở băng (MMO-15). Định tuyến giữa zone: KTR-16.

- **Vì sao:** chuyển zone là chỗ nhân bản nhân vật/vật phẩm và mất nhân vật kinh điển: thông điệp mất,
  lặp, đến trễ, hoặc một bên sập giữa chừng. Một bên quyết định + bản ghi bền + id chuyển giao biến
  mọi bước thành thử lại được: Offer lặp được trả lời lại, không tạo thực thể lần hai; Commit cho id
  không biết thì bỏ. Đích tự xoá khi hết hạn thì một Commit bị mất (nguồn đã xoá E) làm mất nhân vật.
- **Kiểm:** test fault injection: mất/lặp/đảo từng thông điệp, sập từng bên ở từng bước; bất biến
  "đúng một bản đang hoạt động" kiểm sau mỗi kịch bản.

```text
Nguồn A (quyết định)                                   Đích B
1. Đóng băng E (bỏ input); ghi bền transfer T = PENDING(E, A→B)
2. ──────────── Offer(T, snapshot E, version) ─────────────►
3.                                                     T chưa thấy: ghi bền (T, snapshot),
                                                       tạo E ĐÓNG BĂNG; T đã thấy: không tạo lại
4. ◄─────────── Accept(T) ──────────────────────────────────
5. Ghi bền T = COMMITTED (điểm quyết định); xoá E ── Commit(T) ──►
6.                                                     Mở băng E; gateway chuyển phiên sang B
7. ◄─────────── CommitAck(T) ─────── A gửi lại Commit tới khi nhận ack; B trả ack cho Commit lặp
Hết hạn chờ ở 2–4: A ghi T = ABORTED, mở băng E tại A, gửi Abort(T); B xoá bản đóng băng.
B giữ bản đóng băng quá hạn: hỏi A "T thế nào?"; A trả COMMITTED/ABORTED theo bản ghi bền.
A sập: khởi động lại đọc T; PENDING → gửi lại Offer hoặc huỷ; COMMITTED → gửi lại Commit.
```

```cpp
// ✓ Phía đích: Offer lặp cùng id được trả lời lại, không tạo thực thể lần hai.
#include <cstdint>
#include <unordered_map>
#include <utility>

namespace game::cluster {

enum class TransferId : std::uint64_t {};
enum class TransferStage : std::uint8_t { kFrozen, kActive };

// Chỉ luồng zone đích; dựng lại từ bản ghi bền (T, snapshot) khi khởi động, nên B sập sau Accept
// vẫn còn E. Mục bị dọn sau Commit/Abort cộng một thời hạn (thông điệp trễ đến muộn).
class TransferInbox {
public:
    // true: lần đầu thấy id — tạo thực thể ĐÓNG BĂNG; false: lặp — chỉ gửi lại Accept.
    [[nodiscard]] bool on_offer(TransferId id) {
        return stages_.try_emplace(std::to_underlying(id), TransferStage::kFrozen).second;
    }

    // true: mở băng ngay bây giờ; false: id không biết hoặc đã mở — chỉ gửi lại CommitAck.
    [[nodiscard]] bool on_commit(TransferId id) noexcept {
        const auto found = stages_.find(std::to_underlying(id));
        if (found == stages_.end() || found->second == TransferStage::kActive) return false;
        found->second = TransferStage::kActive;
        return true;
    }

private:
    std::unordered_map<std::uint64_t, TransferStage> stages_;
};

} // namespace game::cluster
```

## Kiểm nhanh

- [ ] Handler chỉ nhận ý định; mọi trường được kiểm miền, quyền, cooldown, tầm từ vị trí máy chủ? (MMO-01, MMO-14)
- [ ] Mô phỏng bước cố định, accumulator nguyên, có trần bù; thời gian game là tick nguyên? (MMO-02, MMO-03)
- [ ] Tham chiếu thực thể qua tick là handle thế hệ, không con trỏ? (MMO-04)
- [ ] Độ dài khung, số phần tử, varint từ client có trần trước khi đọc, lặp hay cấp phát; parse qua `Reader` có `finish()`; không `memcpy` struct từ dây? (MMO-05, MMO-06, MMO-20)
- [ ] Tiền là `int64` đơn vị nhỏ nhất có trần, không số thực; giao dịch kiểm hết rồi mới áp dụng? (MMO-07, MMO-08)
- [ ] Mỗi thay đổi kinh tế có sự kiện append-only với `txn_id` và `balance_after`? (MMO-09)
- [ ] Pha tick là bảng cố định; AOI dựng lại theo lưới, kết quả tất định? (MMO-10, MMO-11)
- [ ] Input có số thứ tự, cửa sổ, trần mỗi tick, nối tiếp qua kết nối lại; opcode kiểm theo trạng thái phiên; không bao giờ nạp một nhân vật hai lần? (MMO-13, MMO-16)
- [ ] Lưu DB write-behind có version và epoch chủ, ghi có điều kiện; giao dịch hai bên trong một transaction? (MMO-15, MMO-21)
- [ ] Ngẫu nhiên qua PRNG và phân phối tự viết, mỗi hệ thống một engine có seed ghi log? (MMO-17)
- [ ] Mô phỏng cần tất định dùng điểm cố định, có hash trạng thái và replay test? (MMO-18, MMO-19)
- [ ] Chuyển zone hai pha có id; mọi thông điệp lặp vô hại? (MMO-23)
