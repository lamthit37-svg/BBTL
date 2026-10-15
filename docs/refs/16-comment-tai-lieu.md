# CM · Comment và tài liệu

> **Phạm vi:** nội dung của comment và tài liệu: comment đầu tệp, "Khác gốc", hợp đồng hàm và kiểu,
> tên gốc trong ngoặc, "vì sao", TODO, thông điệp check, docs/modules, ADR, số đo, cận sai số, khẳng
> định codegen. Quy tắc về dạng câu và cách trình bày comment đã gỡ ngày 2026-10-08; quy tắc còn lại
> giữ nguyên mã.
> **Đọc khi:** tạo tệp mới; port code từ _Ref; viết hoặc sửa comment hàm, lớp; viết TODO, thông
> điệp check; ghi quyết định kiến trúc; ghi số đo hay độ chính xác; review comment.
> **Liên quan:** HP-07, HP-08, HP-14, HP-17, HP-18; DD-08 (NOLINT); LH-* (check); KT-* (test vét
> cạn, benchmark); KTR-* (docs/, ADR).

## 1. Nền tảng [N]

### CM-01 [N] PHẢI — Mỗi tệp mở bằng comment đầu tệp: câu 1 nói tệp chứa gì và từ đâu; sau đó ranh giới, quy ước chung, nơi có tài liệu

Thứ tự: (1) câu 1: tệp là gì, các kiểu hoặc hàm chính, và nguồn gốc nếu port (`— <tên gốc> của
<tệp gốc> trong _Ref`); (2) ranh giới: không làm gì, việc gần kề nằm ở tệp nào; (3) quy ước chung
toàn tệp (mặt nạ, thứ tự tham số, làn không xác định); (4) `Ánh xạ tên ở docs/modules/<module>.md.`
nếu có; (5) code port: `Khác gốc:` (CM-02); code viết mới có chính sách: gạch đầu dòng tính chất
(như core/check.hpp: constexpr, noexcept, nhánh lỗi lạnh).

- **Vì sao:** câu đầu tệp là thứ Claude và người đọc thấy khi mở hay grep; ranh giới chặn việc
  thêm nhầm chức năng vào tệp (tính toán nặng vào kiểu lưu trữ, SIMD vào types.hpp).
- **Kiểm:** review; tệp mới thiếu comment đầu bị trả lại.

```cpp
// ✓ world/aoi_grid.hpp viết mới: câu 1, ranh giới, quy ước, tính chất.
// Lưới AOI đều của một zone: ô vuông cạnh 2^kCellShift đơn vị, mỗi ô giữ danh sách phẳng chỉ số
// thực thể. Chỉ lọc thô theo ô; lọc chính xác theo khoảng cách nằm ở world/visibility.hpp. Toạ độ
// ô là int32, ô âm hợp lệ. Ánh xạ tên ở docs/modules/world.md.
// - không cấp phát sau khi dựng: số thực thể tối đa của zone cố định từ cấu hình;
// - không an toàn luồng: chỉ luồng logic của zone gọi.
#pragma once

#include <cstdint>

namespace game::world {

inline constexpr std::int32_t kCellShift = 6;

// Ô chứa coord, làm tròn xuống: -1 thuộc ô -1, không phải ô 0.
[[nodiscard]] constexpr std::int32_t cell_of(std::int32_t coord) noexcept {
    return coord >> kCellShift;
}

} // namespace game::world
```

### CM-02 [N] PHẢI — Code port liệt kê `Khác gốc:`, mỗi gạch một khác biệt có chủ đích kèm lý do; lỗi của gốc nói rõ gốc sai thế nào

Phần mô tả kết thúc bằng `Khác gốc:`, rồi mỗi mục một khác biệt kèm lý do hoặc điều gốc làm. Liệt
kê khác biệt về hành vi và giao diện: sửa UB hay sai của gốc (nói chính xác: "dịch bit quá 31 (UB) khi số mũ
dưới -31"), đổi mặc định ("mặc định là vectơ 0, gốc để rác"), đổi quy ước tham số, đổi chữ ký,
gộp hay bỏ hàm, đổi thuật toán. Không liệt kê đổi định dạng hay tên biến cục bộ.

- **Vì sao:** người sau so với gốc sẽ "sửa cho giống" mọi chỗ khác không lý do — và đưa UB của gốc
  trở lại. Khác gốc là hợp đồng giữa bản port và gốc; "sửa vài lỗi" thì không kiểm được.
- **Kiểm:** review: mỗi khác biệt hành vi với gốc có một gạch; mỗi gạch có lý do.

```cpp
// ✓ sim/xoshiro.hpp: port có "Khác gốc", tên gốc trong ngoặc, hợp đồng từng hàm.
// PRNG 32 bit xoshiro128** cho hiệu ứng phía client cần tái lập (hạt, rung camera): Xoshiro128
// gieo bằng splitmix64 — xoshiro128starstar.c (Blackman, Vigna) và splitmix64.c (Vigna) trong
// _Ref. Không dùng cho mật mã; ngẫu nhiên gameplay máy chủ dùng Xoshiro256 (MMO-17). Khác gốc:
// - trạng thái là thành viên của Xoshiro128 thay mảng toàn cục s[4]: mỗi hiệu ứng một luồng số
//   riêng, tái lập được từ seed (replay, HP-15);
// - chỉ khởi tạo qua seed 64 bit trải bằng splitmix64; gốc để nơi gọi tự nạp s, mà trạng thái
//   toàn 0 thì kẹt ở 0 mãi (hai đầu ra liên tiếp của splitmix64 không thể cùng là 0);
// - thêm next_unit: float đều trên [0, 1);
// - bỏ jump, long_jump: mỗi luồng số tự có seed riêng, không cần chia một chuỗi số.
#pragma once

#include <array>
#include <bit>
#include <cstdint>

namespace game::sim {

namespace detail {

// Đầu ra thứ index của splitmix64 bắt đầu từ seed: cộng hằng Weyl index lần rồi trộn bit (next).
[[nodiscard]] constexpr std::uint64_t splitmix64(std::uint64_t seed, std::uint64_t index) noexcept {
    std::uint64_t mixed = seed + (index * 0x9E37'79B9'7F4A'7C15U);
    mixed = (mixed ^ (mixed >> 30U)) * 0xBF58'476D'1CE4'E5B9U;
    mixed = (mixed ^ (mixed >> 27U)) * 0x94D0'49BB'1331'11EBU;
    return mixed ^ (mixed >> 31U);
}

} // namespace detail

class Xoshiro128 {
public:
    explicit constexpr Xoshiro128(std::uint64_t seed) noexcept {
        const std::uint64_t low = detail::splitmix64(seed, 1);
        const std::uint64_t high = detail::splitmix64(seed, 2);
        state_[0] = static_cast<std::uint32_t>(low);
        state_[1] = static_cast<std::uint32_t>(low >> 32U);
        state_[2] = static_cast<std::uint32_t>(high);
        state_[3] = static_cast<std::uint32_t>(high >> 32U);
    }

    // 32 bit kế tiếp; chu kỳ 2^128 - 1 (next).
    [[nodiscard]] constexpr std::uint32_t next() noexcept {
        const std::uint32_t result = std::rotl(state_[1] * 5U, 7) * 9U;
        const std::uint32_t shifted = state_[1] << 9U;
        state_[2] ^= state_[0];
        state_[3] ^= state_[1];
        state_[1] ^= state_[2];
        state_[0] ^= state_[3];
        state_[2] ^= shifted;
        state_[3] = std::rotl(state_[3], 11);
        return result;
    }

    // Đều trên [0, 1), bước 2^-24 (24 bit cao của next); không bao giờ trả 1.
    [[nodiscard]] constexpr float next_unit() noexcept { return static_cast<float>(next() >> 8U) * 0x1.0p-24F; }

private:
    std::array<std::uint32_t, 4> state_{};
};

// Giá trị vàng chốt thuật toán: splitmix64.c gốc với x = 0, và một bản cài đặt độc lập.
static_assert(detail::splitmix64(0, 1) == 0xE220'A839'7B1D'CDAFU);
static_assert(Xoshiro128(0).next() == 0xDEC9'045DU);

} // namespace game::sim
```

### CM-03 [N] PHẢI — Comment hàm nói hợp đồng: tiền điều kiện, miền, ca biên, độ chính xác, thứ tự phép tính

Một đến ba câu, ngay trên khai báo, trả lời những gì chữ ký không nói: tiền điều kiện và hậu quả
khi vi phạm (check hay UB); ca biên đã xét — 0, âm, rỗng, NaN, ±∞, -0, số không chuẩn, INT_MIN,
tràn, quay vòng; làm tròn và độ chính xác; thứ tự phép tính khi nó đổi kết quả số thực; tác dụng
phụ không hiển nhiên.

- **Vì sao:** hợp đồng không ghi lại thì mỗi nơi gọi tự đoán, và hai nơi đoán khác nhau. Ca biên
  ghi ra là ca biên đã nghĩ tới; ca biên không ghi thường là chưa ai nghĩ tới.
- **Kiểm:** review: hàm công khai có tham số số học mà thiếu miền hay ca biên bị trả lại.

```cpp
// ✓ Miền, hậu quả vi phạm, cách làm tròn, ca biên — không câu nào kể lại phép tính.
#include "core/check.hpp"

#include <cstdint>

namespace game::combat {

// Sát thương sau kháng. resist_percent ngoài 0..100 là lỗi lập trình (check). Chia làm tròn về 0:
// đòn 1 sát thương gặp kháng 1 % thành 0; damage âm (hồi máu) giữ dấu. Không tràn với mọi int32.
[[nodiscard]] constexpr std::int32_t after_resist(std::int32_t damage, std::int32_t resist_percent) noexcept {
    core::check(resist_percent >= 0 && resist_percent <= 100, "after_resist: resist_percent phải trong 0..100");
    return static_cast<std::int32_t>(std::int64_t{damage} * (100 - resist_percent) / 100);
}

} // namespace game::combat
```

### CM-04 [N] CẤM — Comment kể lại code, comment hiển nhiên

Hàm mà tên và kiểu đã nói hết (`operator+`, `dot`, `length`, getter) không comment — phần lớn hàm
trong vector.hpp không có comment. Không viết "Trả về x", "Duyệt các phần tử", "Constructor".

- **Vì sao:** comment kể lại code sai lệch dần khi code đổi mà không trình dịch nào kiểm, và làm
  loãng những comment quan trọng.
- **Kiểm:** review.

```cpp
// ✗ Comment kể lại code; ca biên thật (amount âm) không ai nói.
#include <cstdint>

namespace game::inv {

// Hàm thêm vàng.
inline std::int64_t add_gold(std::int64_t gold, std::int64_t amount) {
    return gold + amount; // cộng amount vào gold
}

} // namespace game::inv
```

```cpp
// ✓ Không comment cho điều tên đã nói; comment còn lại là ca biên.
#include "core/check.hpp"

#include <cstdint>

namespace game::inv {

// amount âm là trừ vàng; số dư không xuống dưới 0 (giao dịch thiếu vàng bị từ chối trước đó).
// gold, amount không vượt trần kinh tế (MMO-07) nên phép cộng không tràn.
[[nodiscard]] constexpr std::int64_t add_gold(std::int64_t gold, std::int64_t amount) noexcept {
    core::check(amount >= -gold, "add_gold: số dư phải không âm sau giao dịch");
    return gold + amount;
}

} // namespace game::inv
```

### CM-05 [N] PHẢI — Port: tên gốc trong ngoặc ở cuối comment, gộp gọn cho cả nhóm

`(HAdd2, 3, 4)`, `(absPerElem, copySignPerElem)`, `(CmpEq..CmpGe)`, `(v3ToF3, f3Tov3... của gốc)`.
Phần trước ngoặc là giải thích; ngoặc chỉ để tìm. Hàm không có tương ứng ở gốc thì không ngoặc.
Hàm cùng tên với gốc nhưng khác nghĩa ghi rõ: "gốc gọi recipPerElem nhưng trả ước lượng".

- **Vì sao:** issue cũ, tài liệu gốc, người quen thư viện gốc đều tìm theo tên gốc; `grep HAdd`
  ra ngay hàm mới. Bảng ánh xạ đầy đủ nằm ở docs/modules (CM-13).
- **Kiểm:** review: mọi hàm port có tương ứng ở gốc mang tên gốc.

```cpp
// ✓ Một comment, tên gốc gộp gọn cho cả nhóm; thứ tự phép tính ghi rõ vì đổi kết quả float.
#include <array>

namespace game::math {

using Lanes = std::array<float, 4>;

// Cộng dồn vào làn x, từ trái sang: x + y, rồi (x + y) + z; ba làn còn lại giữ nguyên (HAdd2, 3).
[[nodiscard]] constexpr Lanes hadd_xy(Lanes lanes) noexcept {
    lanes[0] = lanes[0] + lanes[1];
    return lanes;
}

[[nodiscard]] constexpr Lanes hadd_xyz(Lanes lanes) noexcept {
    lanes[0] = (lanes[0] + lanes[1]) + lanes[2];
    return lanes;
}

} // namespace game::math
```

### CM-08 [N] PHẢI — `static_assert` thay comment khi điều kiện kiểm được lúc biên dịch

Cỡ, căn lề, tính sao chép tầm thường, giá trị ví dụ của hàm constexpr: viết `static_assert` (như
`static_assert(sizeof(Vector4i) == 16 && alignof(Vector4i) == 16);` của người dùng). Comment chỉ
còn nói VÌ SAO cần điều kiện đó.

- **Vì sao:** comment "16 byte" sai lặng lẽ khi thêm một thành viên; `static_assert` dừng build
  đúng lúc đó, ở mọi trình dịch.
- **Kiểm:** review: comment nói về cỡ, căn lề, giá trị hằng mà không có `static_assert` đi kèm.

```cpp
// ✓ Điều kiện bố cục bằng static_assert; comment chỉ nói vì sao cần.
#include <bit>
#include <cstdint>
#include <type_traits>

namespace game::proto {

struct PacketHeader {
    std::uint16_t length = 0;
    std::uint16_t opcode = 0;
    std::uint32_t sequence = 0;
};

// Chép thẳng vào bộ đệm gửi bằng memcpy: phải sao chép tầm thường, không có byte đệm, và máy
// little-endian như trên dây (MMO-06), để byte gửi đi không đổi theo trình dịch hay máy.
static_assert(std::is_trivially_copyable_v<PacketHeader>);
static_assert(sizeof(PacketHeader) == 8);
static_assert(std::endian::native == std::endian::little);

} // namespace game::proto
```

### CM-09 [N] PHẢI — TODO có chủ và đường theo dõi: `// TODO(<người>, #<issue>): <việc cụ thể>.`

Không tạo được issue thì ghi tháng hết hạn: `TODO(an, 2026-12): …`. CẤM `TODO` trần, `FIXME`, `XXX`,
`HACK`. Lỗi đã biết mà chưa sửa: mở issue, TODO trỏ issue, nói điều kiện xảy ra — không viết "chỗ
này sai".

- **Vì sao:** TODO không chủ không ai làm và không ai dám xoá; issue cho nó chỗ để bàn, ưu tiên và
  đóng.
- **Kiểm:** `grep -rnE '\b(FIXME|XXX|HACK)\b|TODO[^(]' src/` rỗng (clang-tidy `google-readability-todo`
  có nhưng không bật trong config).

```cpp
// ✓ TODO có chủ, có issue, nói việc cụ thể và điều kiện của lỗi đã biết.
#include <cstdint>

namespace game::sim {

// Số lượt quay rơi đồ mỗi lần giết; level trong 1..200.
[[nodiscard]] constexpr std::int32_t loot_rolls(std::int32_t level) noexcept {
    // TODO(an, #518): đọc từ bảng cấu hình; công thức này cho 0 lượt khi level < 10 (#517).
    return level / 10;
}

} // namespace game::sim
```

### CM-10 [N] PHẢI — Lựa chọn không hiển nhiên và mọi chỗ lệch quy tắc có comment "vì sao" ngay tại chỗ

Trước bước không hiển nhiên trong thân hàm: một comment nói ý của bước ("// Số không chuẩn: đưa
bit cao nhất của phần định trị về vị trí bit ẩn." trong to_float). Trước lựa chọn có phương án
hiển nhiên hơn: vì sao không chọn nó ("// fprintf thay std::print: header này có mặt ở mọi TU,
không kéo <format> theo."). Chỗ lệch một PHẢI/CẤM: `<cái lệch>: <vì sao an toàn> (<MÃ-NN>)`
(HP-12); NOLINT theo DD-08.

- **Vì sao:** người sau thấy cách "lạ" sẽ đổi về cách "thường" — và mang lỗi mà cách lạ đã tránh
  quay lại. Một câu "vì sao" rẻ hơn một lần sửa sai.
- **Kiểm:** review: mỗi chỗ code khác cách hiển nhiên có câu "vì sao".

```cpp
// ✓ Lý do lựa chọn ghi ngay trước lựa chọn; mã quy tắc trỏ tới lý do sâu hơn.
#include <algorithm>
#include <cstdint>
#include <span>
#include <vector>

namespace game::world {

// Id thực thể trong tầm nhìn, tăng dần.
[[nodiscard]] inline std::vector<std::uint32_t> visible_ids(std::span<const std::uint32_t> ids) {
    std::vector<std::uint32_t> sorted(ids.begin(), ids.end());
    // Sắp theo id thay vì giữ thứ tự ô lưới: thứ tự ô đổi khi thực thể đổi ô, mà gói AOI phải tất
    // định để client so delta với snapshot trước (HP-15).
    std::ranges::sort(sorted);
    return sorted;
}

} // namespace game::world
```

## 2. Nâng cao [C]

### CM-11 [C] PHẢI — API dùng chung ghi thêm: bất biến của lớp, an toàn luồng, cấp phát, vòng đời của view

Comment lớp: lớp là gì, bất biến ("size() không vượt capacity()"), quy ước ("cột trước: v' = M *
v", "làn w không xác định"), giá trị mặc định ("mặc định là phép đồng nhất"), an toàn luồng (luồng
nào được gọi). Comment hàm: có cấp phát không, giữ tham số `span`/`string_view` bao lâu, view trả
ra hết hạn khi nào, độ phức tạp nếu không O(1).

- **Vì sao:** an toàn luồng và vòng đời không thấy được trong chữ ký; nơi gọi đoán sai là tranh
  chấp dữ liệu hay view treo — hai lỗi khó tái hiện nhất (DT-*, SH-*).
- **Kiểm:** review: mọi lớp trong thư viện dùng chung có câu về an toàn luồng.

```cpp
// ✓ Bất biến, an toàn luồng, cấp phát, vòng đời view: những gì chữ ký không nói.
#include <algorithm>
#include <cstddef>
#include <span>
#include <vector>

namespace game::net {

// Bộ đệm gửi của một phiên: ghép gói tin rồi gửi một lần mỗi tick. Bất biến: size() không vượt
// capacity(), không cấp phát lại sau khi dựng. Không an toàn luồng: chỉ luồng mạng của phiên gọi.
class SendBuffer {
public:
    // Cấp phát một lần capacity byte.
    explicit SendBuffer(std::size_t capacity) : bytes_(capacity) {}

    [[nodiscard]] std::size_t size() const noexcept { return size_; }
    [[nodiscard]] std::size_t capacity() const noexcept { return bytes_.size(); }

    // Chép payload vào cuối, không giữ span. Không đủ chỗ: trả false, không đổi gì.
    [[nodiscard]] bool append(std::span<const std::byte> payload) noexcept {
        if (payload.size() > capacity() - size_) return false;
        std::ranges::copy(payload, bytes_.begin() + static_cast<std::ptrdiff_t>(size_));
        size_ += payload.size();
        return true;
    }

    // Phần đã ghép; hết hạn ở lần append kế tiếp hoặc khi SendBuffer bị huỷ.
    [[nodiscard]] std::span<const std::byte> filled() const noexcept { return std::span(bytes_).first(size_); }

private:
    std::vector<std::byte> bytes_;
    std::size_t size_ = 0;
};

} // namespace game::net
```

### CM-12 [C] PHẢI — Thông điệp check là tài liệu: `"<hàm>: <điều kiện phải đúng>"`

Tên hàm (hoặc `Lớp::hàm`) để grep, rồi điều kiện ở dạng PHẢI ĐÚNG, tiếng Việt, không lặp biểu
thức C++: `"all_true: lanes phải trong 1..4"`, không `"bad lanes"` hay `"lanes >= 1 && lanes <= 4"`.
Thông điệp trả về client là mã lỗi, không bao giờ là văn bản nội bộ (LH-10).

- **Vì sao:** core/check.hpp in file:dòng và thông điệp rồi abort: dòng log đó là tất cả những gì
  người trực đêm có. "bad lanes" không nói giá trị đúng là gì; biểu thức C++ đã có ở file:dòng.
- **Kiểm:** review; `grep -rn 'check(' src/ | grep -v ': '` tìm thông điệp thiếu tên hàm.

```cpp
// ✓ Thông điệp: tên hàm, rồi điều kiện phải đúng bằng lời.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <span>

namespace game::inv {

[[nodiscard]] inline std::uint32_t item_at(std::span<const std::uint32_t> slots, std::size_t index) noexcept {
    core::check(index < slots.size(), "item_at: index phải nhỏ hơn số ô của kho");
    return slots[index];
}

} // namespace game::inv
```

### CM-13 [C] PHẢI — Mỗi module có docs/modules/<module>.md: mục đích, kiểu chính, quy ước, bảng ánh xạ tên gốc

Trang module (tối đa vài trăm dòng): mục đích và ranh giới; kiểu chính, một dòng mỗi kiểu; quy ước
chung (đơn vị, hệ toạ độ, mặt nạ, thứ tự tham số); bảng ánh xạ tên gốc → tên mới cho code port,
cột ghi chú khi nghĩa đổi; liên kết ADR. Comment đầu tệp trỏ tới nó (CM-01).

- **Vì sao:** ánh xạ đầy đủ quá dài cho comment, mà người quen gốc cần nó; quy ước toàn module
  viết một lần thay vì lặp ở mọi tệp.
- **Kiểm:** review: thêm hay đổi tên hàm port thì cập nhật bảng trong cùng thay đổi.

```text
# Module math

Toán học trò chơi: kiểu lưu trữ (types.hpp), vectơ SIMD (vector.hpp, vector_int.hpp), SoA (soa.hpp).
Quy ước: tay phải, cột trước (v' = M * v); mặt nạ làn là toàn bit 1 / toàn 0; lerp(a, b, t), t cuối.

| Gốc (ModifiedSonyMath)  | Mới                      | Ghi chú                                 |
|-------------------------|--------------------------|-----------------------------------------|
| recipPerElem            | recip_estimate           | gốc trả ước lượng 12 bit dù tên là recip |
| normalizeApprox         | normalize_estimate       |                                         |
| HAdd2, HAdd3, HAdd4     | hadd_xy, hadd_xyz, hadd_xyzw |                                     |
| CmpEq..CmpGe            | equal..greater_equal     | trả Vector4i, không nạp chồng toán tử   |
```

### CM-14 [C] PHẢI — Quyết định kiến trúc ghi ADR ngắn: docs/adr/NNNN-<tên>.md

Một trang: Bối cảnh (vấn đề, ràng buộc, số đo nếu có), Quyết định, Hệ quả (được gì, mất gì, khi
nào xét lại), Phương án đã loại và vì sao. Trạng thái: đề xuất / chấp nhận / thay bởi ADR-NNNN.
Code chịu ảnh hưởng trỏ về bằng mã: `(ADR-0007)`. ADR đã chấp nhận không sửa nội dung, chỉ thay
bằng ADR mới.

- **Vì sao:** "vì sao mỗi zone một luồng" là câu hỏi sẽ được hỏi lại mỗi năm; không có ADR thì mỗi
  lần là một cuộc tranh luận lại từ đầu, hoặc một lần đảo ngược mà không biết đã loại phương án đó
  vì đâu.
- **Kiểm:** review: thay đổi kiến trúc (luồng, tầng, giao thức, định dạng lưu) kèm ADR.

```text
# ADR-0007: Logic mỗi zone chạy trên đúng một luồng
Trạng thái: chấp nhận (2026-09).
Bối cảnh: tick 20 Hz, 2000 thực thể mỗi zone; khoá theo thực thể làm tick p99 vượt ngân sách
và sinh deadlock khi hai thực thể tương tác qua ranh giới khoá.
Quyết định: mọi trạng thái của zone thuộc một luồng; luồng mạng gửi vào qua hàng đợi MPSC (DT-*).
Hệ quả: logic không khoá, tất định, replay được; một zone tối đa dùng một lõi — zone quá tải
thì chia zone, không thêm luồng. Xét lại khi một zone cần hơn một lõi.
Đã loại: khoá theo thực thể (deadlock, không tất định); actor mỗi thực thể (chi phí hàng đợi).
```

## 3. Thần thoại [T]

### CM-15 [T] PHẢI — Comment tối ưu ghi số đo đủ để tái lập và điều kiện xét lại

Mẫu dưới, đặt ngay trên mã đã tối ưu (HP-14, HP-17). Thiếu trường nào thì người sau không lặp lại
được phép đo, và không biết khi nào phải đo lại. Số liệu trong comment là số đo thật; chưa đo thì
viết "chưa đo", không ước đoán.

- **Vì sao:** lợi ích của tối ưu phụ thuộc CPU, trình dịch, cờ, cỡ dữ liệu; đổi một trong bốn là
  số cũ hết giá trị. Điều kiện xét lại biến tối ưu thành thứ có hạn dùng thay vì nợ vĩnh viễn.
- **Kiểm:** review: comment [T] có đủ trường; benchmark được nêu tên tồn tại và chạy được.

```text
// <Kỹ thuật> thay <bản tham chiếu> (<tên bản tham chiếu>, test so sánh: <tên test>).
// Đo: <CPU>, <trình dịch + phiên bản>, <cờ>, <cỡ dữ liệu>; trung vị <N> lần, p99:
//     <trước> → <sau> (<benchmark: tệp/hàm>, <tháng năm>).
// Xét lại khi: đổi CPU đích hoặc trình dịch; bản tham chiếu đuổi kịp; <điều kiện riêng>.
```

### CM-16 [T] PHẢI — Khẳng định độ chính xác hay "đúng với mọi đầu vào" nêu cách đã chứng minh

Mỗi khẳng định ("đúng với mọi float", "sai số tương đối tới 1,5 * 2^-12", "không tràn") nêu nguồn
của nó: vét cạn (miền nào, test nào), cận lý thuyết (lập luận ngắn hoặc tài liệu: "cận của RSQRTPS
trong tài liệu Intel"), hay chỉ test mẫu (bao nhiêu, seed nào). Lập luận cho phép vét cạn trên tập
nhỏ hơn miền (chỉ các biên) thì ghi cả lập luận đó. Điều kiện của khẳng định (IEEE 754, không
`-ffast-math`) ghi bằng `static_assert` nếu được.

- **Vì sao:** "đúng với mọi float" của to_half đáng tin vì miền 2^32 vét cạn được; khẳng định không
  nguồn là chưa ai kiểm, và người sau không biết phải kiểm lại gì khi đổi code.
- **Kiểm:** review: khẳng định độ chính xác có nguồn; test được nêu tên chạy trong CI.

```cpp
// ✓ [chạy] "Đúng với mọi uint32" kèm lập luận, điều kiện bằng static_assert, test vét cạn các biên.
#include "core/check.hpp"

#include <cmath>
#include <cstdint>
#include <limits>

namespace game::math {

static_assert(std::numeric_limits<double>::is_iec559, "isqrt cần sqrt làm tròn đúng của IEEE 754");

// Căn bậc hai làm tròn xuống, đúng với MỌI uint32 (điều kiện: không -ffast-math). double biểu
// diễn đúng value; sqrt làm tròn đúng và đơn điệu nên chỉ có thể sai ở biên (k+1)^2 - 1. Ở đó sqrt
// thật cách k + 1 hơn 1 / (2(k + 1)) ≥ 2^-17, xa hơn nửa ulp của k + 1 (≤ 2^-37): không làm tròn
// lên được. Test: mọi biên k^2 và (k+1)^2 - 1 (main bên dưới); vét cạn 2^32 cũng đã chạy.
[[nodiscard]] inline std::uint32_t isqrt(std::uint32_t value) noexcept {
    return static_cast<std::uint32_t>(std::sqrt(static_cast<double>(value)));
}

inline void check_bounds(std::uint32_t root) noexcept {
    const std::uint64_t next = std::uint64_t{root} + 1;
    const auto first = static_cast<std::uint32_t>(std::uint64_t{root} * root);
    const auto last = static_cast<std::uint32_t>((next * next) - 1);
    core::check(isqrt(first) == root && isqrt(last) == root, "isqrt: phải đúng ở hai biên của k");
}

} // namespace game::math

int main() {
    for (std::uint32_t root = 0; root <= 65'535U; ++root) {
        game::math::check_bounds(root);
    }
    return 0;
}
```

### CM-17 [T] PHẢI — Khẳng định về mã máy ("không rẽ nhánh", "một lệnh X", "vector hoá") nêu trình dịch, cờ đã kiểm và cách kiểm lại

Comment như "không rẽ nhánh" của `select` trong vector.hpp là khẳng định về codegen: ghi trình
dịch, phiên bản, cờ đã đọc asm, và lệnh kiểm lại. Khẳng định chỉ đúng cho bản không nội tuyến; sau
nội tuyến trình dịch có thể chọn khác — điều gì phải giữ ở mọi chỗ gọi thì cần test hiệu năng,
không cần comment.

- **Vì sao:** trình dịch đổi lựa chọn CMOV hay nhánh, vector hoá hay không, theo phiên bản và cờ;
  khẳng định không kèm điều kiện sẽ sai lặng lẽ sau một lần nâng cấp trình dịch.
- **Kiểm:** lệnh dưới (đã chạy cho mẫu ✓: GCC 14.2, GCC 15.2, Clang 20, `-O2` và
  `-O2 -march=x86-64-v3`, x86-64: mỗi trình dịch hai CMOV, không lệnh nhảy).

```cpp
// ✓ Câu bảo vệ không phải nhánh trong mã máy: khẳng định codegen kèm trình dịch và cờ đã kiểm.
#include <cstdint>

namespace game::combat {

// Kẹp máu vào [0, hp_max]; hp_max không âm. Không rẽ nhánh: GCC 14.2, 15.2 và Clang 20 với -O2
// (x86-64, cả -march=x86-64-v3) sinh hai CMOV, không lệnh nhảy — đọc asm bản không nội tuyến.
[[nodiscard]] constexpr std::int32_t clamp_hp(std::int32_t hp_value, std::int32_t hp_max) noexcept {
    if (hp_value < 0) return 0;
    if (hp_value > hp_max) return hp_max;
    return hp_value;
}

} // namespace game::combat
```

```bash
# Đếm lệnh nhảy, CMOV của bản không nội tuyến (combat/clamp.cpp định nghĩa một bản không inline).
g++ -std=c++23 -O2 -S -o - combat/clamp.cpp | grep -cE '^\s+j[a-z]+\s'
g++ -std=c++23 -O2 -S -o - combat/clamp.cpp | grep -cE '^\s+cmov'
```

## Kiểm nhanh

- [ ] Tệp mở bằng câu nói tệp là gì, từ đâu, ranh giới; code port có `Khác gốc:` đủ lý do? (CM-01, CM-02)
- [ ] Hàm có tham số số học ghi miền, ca biên, làm tròn, độ chính xác? (CM-03)
- [ ] Không comment kể lại code? (CM-04)
- [ ] Hàm port mang tên gốc trong ngoặc? (CM-05)
- [ ] Điều kiện kiểm được lúc biên dịch đã thành `static_assert`? (CM-08)
- [ ] Mọi TODO có người và issue; không FIXME, XXX? (CM-09)
- [ ] Mỗi lựa chọn không hiển nhiên, mỗi chỗ lệch quy tắc có câu "vì sao"? (CM-10)
- [ ] Lớp dùng chung nói bất biến, an toàn luồng, cấp phát, vòng đời view? (CM-11)
- [ ] Thông điệp check dạng `"hàm: điều kiện phải đúng"`? (CM-12)
- [ ] Số đo, cận sai số, khẳng định codegen có điều kiện và nguồn? (CM-15, CM-16, CM-17)
