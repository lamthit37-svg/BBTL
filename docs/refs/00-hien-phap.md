# HP · Hiến pháp: phương châm, ưu tiên, quy trình

> **Phạm vi:** luật gốc cho mọi code C++23 của dự án game MMO (máy chủ và client): cách đọc bộ quy
> cách, thứ tự ưu tiên, nguyên tắc nền, quy trình Claude làm một việc C++, phân xử mâu thuẫn,
> thuật ngữ. **Đọc khi:** bắt đầu bất kỳ việc C++ nào (đọc trước mọi tệp khác); hai quy tắc mâu
> thuẫn; định dùng kỹ thuật cấp [T]; định lệch một quy tắc PHẢI/CẤM; viết báo cáo cuối việc; không
> chắc nghĩa một thuật ngữ.
> **Liên quan:** refs/01-dinh-dang-dat-ten.md (DD-08), refs/05-loi-hop-dong.md
> (LH-*), refs/16-comment-tai-lieu.md (CM-02, CM-15), refs/19-review-checklist.md (RV-*), MAP.md.

## 0. Cách đọc bộ quy cách

#### Quy tắc và mức

Tiêu đề `MÃ-NN [cấp] MỨC — phát biểu`; thân: phát biểu chính xác, **Vì sao**, **Kiểm**, **Ngoại
lệ**, mẫu. Mã là địa chỉ để trích trong comment, NOLINT, review; tra bằng INDEX.md hoặc `grep`.

| Mức (nghĩa như RFC 2119) | Nghĩa | Được lệch khi |
|---|---|---|
| PHẢI / CẤM | bắt buộc làm / bắt buộc không làm | chỉ theo HP-12, comment tại chỗ ghi mã quy tắc và lý do |
| NÊN / KHÔNG NÊN | mặc định đúng cho gần như mọi trường hợp | có lý do cụ thể, ghi trong comment hoặc mô tả thay đổi |
| CÓ THỂ | được phép, tuỳ chọn | không cần lý do |

#### Cấp

- **[N] Nền tảng:** mọi dòng code — sản phẩm, test, công cụ, prototype — không ngoại lệ.
- **[C] Nâng cao:** thư viện dùng chung, API công khai, đường nóng, đa luồng, giao thức mạng, dữ liệu lưu.
- **[T] Thần thoại:** kiến thức cực hạn — chuẩn, ABI, codegen, cache, ulp, thứ tự bộ nhớ.

Từ 2026-10-08 mức mặc định là cao nhất (CL-01): không còn "mã thường", quy tắc [C] áp cho mọi mã
trong phạm vi nó chạm tới, và mỗi thay đổi có bằng chứng cho năm thuộc tính an toàn, bền, tối ưu,
hiện đại, thông minh.

[T] loại kỹ thuật (tối ưu cực hạn, lock-free, xấp xỉ số học) chỉ DÙNG khi đủ bốn điều kiện HP-17;
[T] loại phòng vệ (macro nền tảng, ODR, handler tín hiệu, bộ nhớ yếu) áp dụng ngay khi code chạm
tình huống đó. Cấp cao chỉ thêm yêu cầu, không miễn quy tắc cấp thấp.

#### Mẫu code

- `// ✓` — "code production thu nhỏ", chép vào dự án được. Mọi mẫu ✓ đã qua `tools/verify.py
  --tidy`: GCC 14.2, GCC 15.2, Clang 20.1 + libc++ 20, `-std=c++23 -Werror` + config/warnings-*.txt;
  clang-tidy 20 sạch. Kiểm lại 2026-10-08 trên Windows, sau khi gỡ các quy tắc hình thức: GCC 16.2
  MinGW, Clang 23.1 + STL MSVC, clang-tidy 23, 0 lỗi. Mẫu có
  `#pragma once` là một header, được biên dịch qua một .cpp chỉ include nó. "Máy kiểm" trong bộ này là
  máy đã chạy các phép đo đó (Linux x86-64); số đo hiệu năng từ nó chỉ là bậc độ lớn.
- `// ✗` — phản mẫu: biên dịch được, sai về thiết kế, UB hoặc hiệu năng. Thẻ `[không biên dịch]`:
  trình dịch từ chối thật (đã kiểm).
- Thẻ đầu mẫu: không thẻ = cả ba trình dịch; `[g14+g15]` chỉ libstdc++ (libc++ 20 chưa có
  generator, stacktrace, enumerate…); `[g15+c20]` GCC 14 chưa có (flat_map…); `[g15]`, `[c20]` một
  trình dịch; `[x86]` thêm `-march=x86-64-v3`; `[chạy]` / `[tsan]` chạy thật dưới ASan + UBSan /
  ThreadSanitizer, phải trả 0; `[linux]` cần Linux/ELF (POSIX, ifunc, stacktrace của libstdc++), trên
  Windows không biên dịch.
- Mẫu được lược cho gọn, code dự án thì không: mẫu tự đủ nên khai báo lại kiểu dùng chung tại chỗ
  (`Tick`, `TickSpan` — MMO-03), trong dự án chúng có một định nghĩa duy nhất (GN-19); id trần
  `std::uint32_t` khi id không phải trọng tâm của mẫu (dự án: kiểu mạnh, KG-08); test của hàm
  `constexpr` đôi khi vắng (dự án: GN-05); comment đầu tệp chỉ có ở mẫu header (dự án: CM-01).

#### Thứ bậc nguồn

1. Yêu cầu tường minh của người dùng trong phiên; nếu nó phá một PHẢI/CẤM thì nói rõ quy tắc
   nào, hệ quả gì, rồi mới làm.
2. Quy định dự án: CLAUDE.md dự án, "hiến pháp" dự án, docs/adr/, phong cách của tệp đang sửa.
3. Bộ quy cách này (refs/).
4. Thói quen chung của Claude.

## 1. Nền tảng [N]

### HP-01 [N] PHẢI — Ưu tiên theo thứ tự: Đúng > An toàn, ổn định > Rõ ràng > Hiệu năng > Ngắn gọn

Khi hai mục tiêu xung đột, mục đứng trước thắng. Hiệu năng chỉ thắng Rõ ràng khi số đo (HP-14)
chứng minh bản rõ ràng vượt ngân sách. Ngắn gọn không thắng mục nào.

- **Vì sao:** máy chủ MMO chạy hàng tháng trước dữ liệu thù địch: một lỗi số học hiếm thành vật
  phẩm nhân bản hay máy chủ sập. Chậm thì đo rồi sửa được; dữ liệu hỏng đã ghi vào DB thì không.
- **Kiểm:** review: thay đổi làm code khó đọc hơn vì hiệu năng phải kèm số đo (CM-15); UBSan bắt
  tràn có dấu.

```cpp
// ✓ Đúng trước ngắn: (low + high) / 2 tràn int32 (UB) với mảng lớn; std::midpoint thì không.
#include <cstdint>
#include <numeric>

namespace game::core {

// Điểm giữa cho tìm kiếm nhị phân; làm tròn về phía low.
[[nodiscard]] constexpr std::int32_t middle(std::int32_t low, std::int32_t high) noexcept {
    return std::midpoint(low, high);
}

static_assert(middle(2'147'483'000, 2'147'483'600) == 2'147'483'300);

} // namespace game::core
```

### HP-02 [N] CẤM — Undefined behavior dưới mọi hình thức; không có "UB vô hại"

Mọi biểu thức có hành vi xác định với MỌI đầu vào thoả hợp đồng của hàm. Đầu vào ngoài hợp đồng
thì `core::check`, trả lỗi, hoặc có hành vi xác định ghi trong comment. "Chạy đúng trên máy tôi"
không phải bằng chứng. Danh mục UB và cách sửa: refs/13-ub-on-dinh.md (UB-*).

- **Vì sao:** trình dịch được giả định UB không xảy ra và suy luận ngược: xoá phép kiểm null sau
  deref, xoá phép kiểm tràn sau phép cộng có dấu. Lỗi đổi theo mức -O, phiên bản trình dịch, quyết
  định nội tuyến: hiện ở bản release, không ở debug.
- **Kiểm:** mọi test chạy dưới ASan + UBSan; hàm constexpr có `static_assert` thì trình dịch từ
  chối UB lúc biên dịch; clang-tidy `bugprone-*`, `cppcoreguidelines-pro-*`.

```cpp
// ✓ hp - damage có thể tràn int32 (damage = INT32_MIN): tính trong int64 rồi kẹp.
#include "core/check.hpp"

#include <algorithm>
#include <cstdint>

namespace game::combat {

struct Vitals {
    std::int32_t hp = 0;
    std::int32_t hp_max = 0;
};

// Máu sau đòn, trong [0, hp_max]; damage âm là hồi máu. Xác định với mọi hp, damage int32.
[[nodiscard]] constexpr std::int32_t apply_damage(Vitals vitals, std::int32_t damage) noexcept {
    core::check(vitals.hp_max >= 0, "apply_damage: hp_max phải không âm");
    const std::int64_t next = std::int64_t{vitals.hp} - damage;
    return static_cast<std::int32_t>(std::clamp<std::int64_t>(next, 0, vitals.hp_max));
}

static_assert(apply_damage({.hp = 10, .hp_max = 100}, INT32_MIN) == 100);

} // namespace game::combat
```

### HP-03 [N] PHẢI — Trạng thái sai không biểu diễn được bằng kiểu

`enum class` thay bộ `bool` loại trừ nhau; kiểu mạnh cho ID và đơn vị; constructor/factory lập
bất biến; `std::optional`/`std::expected` thay giá trị canh (-1, 0, nullptr). Chi tiết: KG-*, API-*.

- **Vì sao:** mỗi tổ hợp vô nghĩa là một nhánh không ai test. Ba `bool` connected, authenticated,
  in_world sinh 8 tổ hợp mà chỉ 4 có nghĩa; `std::uint32_t` dùng chung cho AccountId và EntityId
  thì truyền nhầm vẫn biên dịch.
- **Kiểm:** review; `-Wswitch` (trong `-Wall`) báo `switch` trên enum class thiếu case.

```cpp
// ✓ Một enum class thay ba bool; AccountId là kiểu riêng, không đổi ngầm từ số.
#include <cstdint>

namespace game::net {

enum class AccountId : std::uint32_t {};

// Đi một chiều: kConnected → kAuthenticated → kInWorld; kClosed là trạng thái cuối.
enum class SessionState : std::uint8_t { kConnected, kAuthenticated, kInWorld, kClosed };

struct Session {
    AccountId account{};
    SessionState state = SessionState::kConnected;
};

} // namespace game::net
```

### HP-04 [N] PHẢI — Giá trị trước tham chiếu; mỗi tài nguyên có đúng một chủ tường minh

Mặc định lưu và trả theo giá trị. Con trỏ, tham chiếu trần, `std::span`, `std::string_view` chỉ
để mượn trong một lời gọi, không lưu lâu hơn chủ. Sở hữu động: `std::unique_ptr`;
`std::shared_ptr` chỉ khi sở hữu chung thật. Chi tiết: SH-*.

- **Vì sao:** treo là lỗi bộ nhớ khó tái hiện nhất: thành viên `std::string_view` trỏ vào bộ đệm
  nhận của socket chạy đúng cho tới khi bộ đệm được tái dùng. Giá trị không có vòng đời phải quản.
- **Kiểm:** ASan (`heap-use-after-free`, `stack-use-after-return`); GCC `-Wdangling-reference`;
  clang-tidy `bugprone-dangling-handle`, `cppcoreguidelines-owning-memory`.

```cpp
// ✓ Dòng chat sở hữu chuỗi của nó; string_view chỉ là tham số mượn trong lời gọi.
#include <string>
#include <string_view>

namespace game::world {

struct ChatLine {
    std::string text;
};

[[nodiscard]] inline ChatLine make_line(std::string_view received) {
    return {std::string(received)};
}

} // namespace game::world
```

### HP-05 [N] PHẢI — Lỗi lập trình dừng sớm; lỗi dự kiến trả `std::expected`; không nuốt lỗi

Lỗi lập trình (vi phạm hợp đồng do code của ta: chỉ số sai, enum ngoài miền) → `core::check` /
`core::fail` của `"core/check.hpp"`, dừng ngay. Lỗi dự kiến (DB chậm, tệp thiếu, kho thiếu đồ) →
`std::expected` với enum class lỗi. Byte từ client → HP-16. Không bỏ qua lỗi, không `catch (...)`
rỗng, không gộp hai loại vào một `false`. Chi tiết: LH-*.

- **Vì sao:** chạy tiếp khi bất biến đã vỡ biến một lỗi thành dữ liệu bẩn lan sang DB; dừng ngay
  để lại core dump đúng hiện trường. Ngược lại, abort vì lỗi dự kiến là tự làm sập máy chủ.
- **Kiểm:** `[[nodiscard]]` trên hàm trả `expected` (bỏ qua là lỗi với `-Werror`); clang-tidy
  `bugprone-unused-return-value`, `bugprone-empty-catch`.

```cpp
// ✓ check cho lỗi lập trình, expected cho lỗi dự kiến; nơi gọi không bỏ qua được.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <utility>

namespace game::inv {

enum class [[nodiscard]] TakeError : std::uint8_t { kNotEnough };
using TakeResult = std::expected<std::uint32_t, TakeError>;

// Chỉ số ô trong kho: kiểu riêng để nơi gọi không truyền lộn với số lượng (KG-16).
enum class Slot : std::size_t {};

// Bớt amount ở ô slot, trả số còn lại. slot do máy chủ tính: ngoài biên là lỗi lập trình.
// Thiếu số lượng là chuyện thường: trả lỗi cho nơi gọi.
[[nodiscard]] inline TakeResult take(std::span<std::uint32_t> counts, Slot slot, std::uint32_t amount) noexcept {
    const std::size_t index = std::to_underlying(slot);
    core::check(index < counts.size(), "take: slot phải nhỏ hơn số ô");
    std::uint32_t& count = counts[index];
    if (count < amount) return std::unexpected(TakeError::kNotEnough);
    count -= amount;
    return count;
}

} // namespace game::inv
```

### HP-07 [N] PHẢI — Comment nói hợp đồng và lý do; code port ghi "Khác gốc" và sửa UB của gốc

Comment trả lời điều code không tự nói: miền đầu vào, ca biên, độ chính xác, vì sao chọn cách
này — không kể lại code. Code port: comment đầu tệp nêu nguồn và `Khác gốc:` từng khác biệt kèm
lý do; UB và lỗi của gốc được sửa, không chép. Chi tiết: CM-01 tới CM-05.

- **Vì sao:** ý định không nằm trong code. Khác biệt không ghi lại sẽ bị người sau "sửa cho giống
  gốc" và lỗi cũ quay về; comment kể lại code sai lệch dần mà không công cụ nào phát hiện.
- **Kiểm:** review theo CM-*.

```cpp
// ✓ Như math/types.hpp của người dùng: comment nói ca biên và vì sao, không kể lại phép tính.
#include <cstdint>

namespace game::math {

// 0 - value tính theo số không dấu: số nguyên nhỏ nhất quay về chính nó thay vì tràn (UB).
[[nodiscard]] constexpr std::int32_t negated(std::int32_t value) noexcept {
    return static_cast<std::int32_t>(0U - static_cast<std::uint32_t>(value));
}

} // namespace game::math
```

### HP-08 [N] CẤM — Code chết, code bị comment hoá, `#if 0`, TODO không chủ

Xoá code không còn được gọi; lịch sử nằm trong git, không nằm trong comment. Mỗi việc còn nợ là
`// TODO(<người>, #<issue>): <việc cụ thể>.` (CM-09).

- **Vì sao:** code chết vẫn phải đọc, biên dịch, cập nhật khi đổi API — và người đọc tưởng nó
  đang chạy. TODO không chủ không bao giờ được làm.
- **Kiểm:** `-Wunused-function`, `-Wunused-variable` (trong `-Wall`); clang-tidy
  `misc-unused-parameters`, `readability-avoid-unconditional-preprocessor-if` (bắt `#if 0`);
  `grep -rnE 'TODO[^(]|FIXME|XXX'`.

```cpp
// ✓ Một phiên bản duy nhất của công thức; việc còn nợ có chủ và issue.
#include "core/check.hpp"

#include <cstdint>

namespace game::sim {

// Máu hồi mỗi tick; level trong 1..200 nên không tràn int32.
[[nodiscard]] constexpr std::int32_t regen_per_tick(std::int32_t level) noexcept {
    core::check(level >= 1 && level <= 200, "regen_per_tick: level phải trong 1..200");
    // TODO(an, #412): đọc bảng hồi máu theo cấp từ cấu hình thay công thức tuyến tính.
    return (level * 2) + 10;
}

} // namespace game::sim
```

### HP-09 [N] CẤM — Đoán API, cờ trình dịch, tên check, số liệu

Không chắc một hàm, nạp chồng, cờ hay check có thật và chạy thế nào: tra cppreference hoặc chuẩn,
kiểm feature-test macro, biên dịch thử trên cả GCC và Clang; không kiểm được thì viết "chưa kiểm".
Contracts, reflection, `std::inplace_vector`, `std::saturate_cast` là C++26, không phải C++23.

- **Vì sao:** API "gần đúng" biên dịch trên thư viện này mà không trên thư viện kia
  (`std::views::enumerate` có ở libstdc++ 14, chưa có ở libc++ 20; `std::flat_map` chưa có ở GCC
  14); số liệu bịa dẫn tới tối ưu sai chỗ.
- **Kiểm:** các lệnh dưới, chạy trước khi dùng thứ chưa chắc.

```bash
# Hỏi trình dịch, không hỏi trí nhớ: thư viện chuẩn đang dùng có flat_map không?
printf '#include <version>\nstatic_assert(__cpp_lib_flat_map >= 202207L);\n' > /tmp/probe.cpp
g++ -std=c++23 -fsyntax-only /tmp/probe.cpp && echo "libstdc++: có"
clang++ -std=c++23 -stdlib=libc++ -fsyntax-only /tmp/probe.cpp && echo "libc++: có"
# Tên check clang-tidy có thật không.
clang-tidy --list-checks -checks='*' | grep -n 'bugprone-empty-catch'
```

### HP-10 [N] PHẢI — Quy trình mỗi việc C++: phân cấp, mở refs, viết, tự kiểm, biên dịch, báo cáo

Làm đủ bảy bước theo thứ tự; bước không làm được thì ghi vào báo cáo (HP-11).

- **Vì sao:** quy cách chỉ có tác dụng khi được mở đúng lúc; tự kiểm và biên dịch bắt phần lớn
  lỗi trước khi người dùng thấy.
- **Kiểm:** báo cáo cuối việc có mục "Đã kiểm" với lệnh cụ thể.

```text
1. Phân cấp: việc chạm phạm vi [C] nào (API công khai, đường nóng, đa luồng, giao thức mạng,
   dữ liệu lưu)? Có định dùng kỹ thuật [T] (→ HP-17)?
2. Tra theo MAP.md: công thức theo loại việc cho sẵn mã quy tắc; đọc đúng quy tắc qua INDEX.md
   (cột Dòng, Dài). Đọc trọn một tệp chỉ khi nó là chủ đề CHÍNH của một việc lớn.
3. Đọc code xung quanh: phong cách tệp đang sửa đi trước thói quen (thứ bậc nguồn, mục 0).
4. Phân tích thất bại trước (CL-03), rồi viết: hợp đồng trong comment (CM-03), không UB (HP-02),
   lỗi đúng loại (HP-05). Test theo luật Test trong `~/.claude/CLAUDE.md`, không cặp từng file (CL-04).
5. Tự kiểm theo refs/19-review-checklist.md và mục "Kiểm nhanh" của các tệp đã mở.
6. Qua cổng biên dịch và clang-tidy (CL-02). Test có sẵn hoặc vừa viết thì chạy trên hai thư viện
   chuẩn; TSan nếu đa luồng và đã có test.
7. Báo cáo theo HP-11, có bằng chứng cho đủ năm thuộc tính (CL-01).
```

```bash
# Bước 6 cho các tệp đã đổi (lệnh đầy đủ và bản thủ công: refs/19 §5).
python3 ~/.claude/cpp23/tools/check.py src/net/session.cpp src/net/session.hpp
python3 ~/.claude/cpp23/tools/check.py --run tests/net_tests.cpp --with src/net/session.cpp
```

### HP-11 [N] CẤM — Tuyên bố "đã biên dịch", "đã test", "nhanh hơn" khi chưa chạy thật

Báo cáo cuối việc tách bốn mục theo RV-04: **Đã kiểm** (lệnh và kết quả), **Chưa kiểm** (vì
sao), **Giả định**, **Lệch quy tắc** (mã và lý do, HP-12). Số đo kèm điều kiện (HP-14); không đo
thì viết "chưa đo".

- **Vì sao:** người dùng quyết định dựa trên báo cáo; một lần "chắc là chạy" sai làm mất niềm tin
  vào mọi báo cáo sau.
- **Kiểm:** review báo cáo: mọi khẳng định "đã…" có lệnh tương ứng.

```text
Đã kiểm:
  - g++ 14.2 và clang++ 20, -std=c++23 -Werror + config/warnings-*.txt: sạch.
  - ctest dưới ASan + UBSan: 48/48 qua.
Chưa kiểm: MSVC (máy không có); TSan (thay đổi không chạm code đa luồng).
Giả định: MoveRequest tối đa 64 byte (theo proto/move.hpp), chưa đối chiếu với code client.
Lệch quy tắc: không.
```

### HP-12 [N] PHẢI — Phân xử mâu thuẫn theo thứ tự cố định và ghi lý do tại chỗ lệch

1. Thứ bậc nguồn (mục 0). 2. Trong bộ này: quy tắc cụ thể thắng quy tắc chung. 3. Cùng độ cụ thể:
theo thứ tự ưu tiên HP-01. 4. [T] không miễn [N]: kỹ thuật cực hạn vẫn không UB, vẫn xử lý lỗi
đúng loại. 5. Mọi chỗ lệch một PHẢI/CẤM có comment tại chỗ nêu mã quy tắc và lý do (CM-10);
NOLINT nêu tên check (DD-08).

- **Vì sao:** không có luật phân xử thì mỗi mâu thuẫn là một quyết định tuỳ hứng; code trôi khỏi
  quy cách mà không ai biết trôi từ đâu.
- **Kiểm:** review: mỗi NOLINT, `core::assume` có mã quy tắc và lý do.

```text
Mâu thuẫn                                         Phân xử
Kỹ thuật [T] cần reinterpret_cast để đọc float     [T] không miễn [N]: std::bit_cast hoặc memcpy;
từ bộ đệm byte                                    không có cách hợp lệ thì bỏ kỹ thuật.
```

## 2. Nâng cao [C]

### HP-13 [C] PHẢI — Không tốn phí cho thứ không dùng

Cơ chế động (virtual, `std::function`, `std::shared_ptr`, cấp phát heap, khoá, ngoại lệ trên
đường nóng) chỉ dùng khi bài toán thật sự cần tính động đó. Mặc định tĩnh: template + concept,
giá trị, `std::unique_ptr`, `std::span`. Chi phí cụ thể: HN-*.

- **Vì sao:** `std::function` xoá kiểu: mỗi lần gọi là lời gọi gián tiếp, thường không nội tuyến
  được, và có thể cấp phát khi đối tượng gọi lớn hơn bộ đệm nhỏ bên trong (cỡ tuỳ thư viện) — trả
  cho tính linh hoạt không ai dùng, trên hàng chục nghìn thực thể mỗi tick.
- **Kiểm:** review; perf khi nghi ngờ (HN-*).

```cpp
// ✓ Hành vi biết lúc biên dịch: template + concept thay std::function, nội tuyến được.
#include <concepts>
#include <span>

namespace game::world {

struct Unit {
    float hp = 0.0F;
};

template <std::invocable<Unit&> Visit>
void for_each_unit(std::span<Unit> units, Visit visit) {
    for (Unit& unit : units) {
        visit(unit);
    }
}

} // namespace game::world
```

### HP-14 [C] PHẢI — Đo trước khi tối ưu; ghi số đo kèm điều kiện tái lập

Thay đổi vì hiệu năng làm code phức tạp hơn phải có: profile chỉ ra điểm nóng TRƯỚC khi sửa,
benchmark trước và sau, và ghi máy (CPU), trình dịch + cờ, cỡ dữ liệu, trung vị trước → sau.
Định dạng comment: CM-15. Phương pháp: HN-*; harness: KT-*. Không có số đo thì giữ bản đơn giản.

- **Vì sao:** trực giác về điểm nóng thường sai. Tối ưu không đo thì không biết có lợi không, và
  không biết lúc nào lợi ích biến mất (đổi trình dịch, CPU, cỡ dữ liệu).
- **Kiểm:** review: tối ưu không kèm số đo bị trả về bản đơn giản.

```text
1. Profile (perf) trên tải thật hoặc replay: hàm nóng chiếm bao nhiêu % tick?
2. Benchmark tái lập điểm nóng, đo bản hiện tại (trung vị, p99). 3. Sửa, chạy test (HP-17).
4. Đo lại cùng máy, cờ, dữ liệu; lợi ích dưới nhiễu đo thì bỏ. 5. Ghi số đo (CM-15).
```

### HP-15 [C] PHẢI — Tất định mặc định: cùng đầu vào cho cùng kết quả trên mọi máy và trình dịch

Logic game (mô phỏng, chiến đấu, rơi đồ, AI) không phụ thuộc: thứ tự duyệt `unordered_*`, địa
chỉ con trỏ, đồng hồ thật (đọc ở biên, truyền vào dưới dạng tick), PRNG không seed, phân phối của
`<random>`, cờ số thực (`-ffast-math`, co FMA). Chi tiết: MMO-*, STD-*, SV-*.

- **Vì sao:** tất định là điều kiện để tái hiện lỗi từ replay, test hồi quy bằng hash trạng thái,
  và lockstep. Bẫy hay gặp: `std::mt19937` được chuẩn quy định từng bit, `uniform_int_distribution`
  thì không — cùng seed, libstdc++ và libc++ rơi đồ khác nhau.
- **Kiểm:** test replay (KT-*): chạy hai lần, bản GCC và bản Clang, so hash trạng thái.

```cpp
// ✓ Ánh xạ tự viết trên bit thô của engine thay uniform_int_distribution: như nhau mọi nơi.
#include "core/check.hpp"

#include <cstdint>

namespace game::sim {

// Chỉ số trong [0, table_size). random_bits: một lần gọi engine tất định của hệ thống rơi đồ
// (MMO-17). 32 bit cao nhân table_size rồi lấy 32 bit cao (Lemire): không chia; xác suất mỗi ô
// lệch khỏi 1 / table_size dưới 2^-32, chấp nhận cho rơi đồ.
[[nodiscard]] constexpr std::uint32_t roll_loot(std::uint64_t random_bits, std::uint32_t table_size) noexcept {
    core::check(table_size > 0, "roll_loot: table_size phải dương");
    const std::uint64_t wide = (random_bits >> 32U) * table_size;
    return static_cast<std::uint32_t>(wide >> 32U);
}

static_assert(roll_loot(0, 10) == 0 && roll_loot(~std::uint64_t{0}, 10) == 9);

} // namespace game::sim
```

### HP-16 [C] CẤM — Dừng máy chủ vì dữ liệu client: kiểm mọi trường, trả lỗi, máy chủ chạy tiếp

Mọi byte từ client đi qua lớp đọc có kiểm biên, trả `std::expected`; `core::check`, `assert`,
`std::abort`, `.at()` KHÔNG dùng để từ chối dữ liệu client. Dữ liệu sai → bỏ gói hoặc ngắt phiên,
tăng bộ đếm. Máy chủ quyết định mọi kết quả (MMO-*).

- **Vì sao:** `check` dừng cả tiến trình: `core::check(length < payload.size(), …)` với length
  đọc từ gói tin biến một gói dựng sẵn thành nút tắt máy chủ của hàng nghìn người chơi (DoS). Vi
  phạm hợp đồng là lỗi của ta; dữ liệu sai là chuyện thường của mạng.
- **Kiểm:** fuzz mọi parser gói tin (KT-*, libFuzzer); review: `check(` trong net/ và proto/ chỉ
  kiểm bất biến nội bộ, không kiểm byte nhận được.

```cpp
// ✓ Không core::check(length < payload.size(), …): dữ liệu sai trả lỗi, tầng phiên bỏ gói và đếm.
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>

namespace game::proto {

enum class [[nodiscard]] ReadError : std::uint8_t { kTruncated, kNameTooLong };
using NameResult = std::expected<std::span<const std::byte>, ReadError>;

inline constexpr std::size_t kMaxNameBytes = 32;

// Tên: 1 byte độ dài rồi length byte UTF-8 (nội dung chưa kiểm). payload đến thẳng từ client.
[[nodiscard]] inline NameResult read_name(std::span<const std::byte> payload) noexcept {
    if (payload.empty()) return std::unexpected(ReadError::kTruncated);
    const auto length = std::to_integer<std::size_t>(payload.front());
    if (length > kMaxNameBytes) return std::unexpected(ReadError::kNameTooLong);
    if (length >= payload.size()) return std::unexpected(ReadError::kTruncated);
    return payload.subspan(1, length);
}

} // namespace game::proto
```

## 3. Thần thoại [T]

### HP-17 [T] PHẢI — Kỹ thuật [T] chỉ dùng khi đủ bốn điều kiện: số đo, test bảo vệ, comment bất biến, bản tham chiếu

1. **Số đo:** profile chỉ ra điểm nóng; benchmark cho lợi ích vượt nhiễu đo trên phần cứng đích
   (HP-14), ghi trong comment (CM-15).
2. **Test bảo vệ:** so với bản tham chiếu — vét cạn khi miền nhỏ (2^32 giá trị vẫn khả thi), có
   seed + ca biên khi miền lớn; ASan + UBSan, TSan nếu đa luồng, fuzz nếu nhận dữ liệu ngoài.
3. **Comment bất biến:** điều kiện để kỹ thuật đúng (miền, căn lề, thứ tự bộ nhớ, giả định phần
   cứng), lập luận (HP-18), và điều kiện phải xét lại.
4. **Bản tham chiếu:** bản đơn giản cùng hợp đồng, sống cạnh bản nhanh (trong `detail` hoặc test):
   nó định nghĩa hành vi và là đường lui khi bản nhanh hết đúng hoặc hết nhanh.

Thiếu một điều kiện thì dùng bản [N]/[C].

- **Vì sao:** kỹ thuật cực hạn đúng trong điều kiện hẹp và sai lặng lẽ khi điều kiện đổi. Bốn món
  biến "tin tôi đi" thành điều kiểm được, và giữ đường lui rẻ: xoá bản nhanh, giữ bản tham chiếu.
- **Kiểm:** review: tìm bản tham chiếu và test so sánh; thiếu thì từ chối.

```cpp
// ✓ [T] Ô lưới AOI bằng dịch phải số học; kèm bản tham chiếu, test so sánh trên [-4096, 4096).
#include <algorithm>
#include <cstdint>
#include <ranges>

namespace game::world {

// Ô vuông 64 đơn vị (2^6).
inline constexpr std::int32_t kCellShift = 6;

// Bản tham chiếu: chia làm tròn xuống, đúng cả với toạ độ âm (phép / làm tròn về 0).
[[nodiscard]] constexpr std::int32_t cell_of_reference(std::int32_t coord) noexcept {
    const std::int32_t size = std::int32_t{1} << kCellShift;
    const std::int32_t quotient = coord / size;
    const bool below = coord % size != 0 && coord < 0;
    return below ? quotient - 1 : quotient;
}

// Ô chứa coord, đúng với mọi int32: từ C++20, E1 >> E2 với E1 âm là E1 / 2^E2 làm tròn xuống
// ([expr.shift]) — một lệnh SAR thay phép chia và bước sửa dấu. Đúng chừng nào cạnh ô là luỹ
// thừa của 2. Đo: <CPU>, <trình dịch, cờ>, <số thực thể>: <trước> → <sau> (CM-15).
[[nodiscard]] constexpr std::int32_t cell_of(std::int32_t coord) noexcept {
    return coord >> kCellShift;
}

// Test bảo vệ: bản nhanh khớp bản tham chiếu tại coord.
[[nodiscard]] constexpr bool matches_reference(std::int32_t coord) noexcept {
    return cell_of(coord) == cell_of_reference(coord);
}

static_assert(std::ranges::all_of(std::views::iota(-4096, 4096), matches_reference));

} // namespace game::world
```

### HP-18 [T] PHẢI — Mã [T] kèm lập luận đúng theo chuẩn hoặc tài liệu phần cứng, không chỉ theo thử nghiệm

Comment của mã [T] ghi lập luận kiểm lại được:

- thao tác nguyên tử khác `seq_cst`: cặp release → acquire nào tạo synchronizes-with, công bố dữ liệu nào,
  chuỗi happens-before ([intro.races], [atomics.order]);
- xấp xỉ số thực: cận sai số (ulp, bit, sai số tương đối) và nguồn của cận — như "sai số tương
  đối độ dài tới 1,5 * 2^-12" của normalize_estimate (cận của RSQRTPS trong tài liệu Intel);
- vòng đời và aliasing: đối tượng nào sống ở đâu ([basic.life]), vì sao không vi phạm strict
  aliasing ([basic.lval]); `core::assume`: điều kiện được chứng minh ở đâu.

- **Vì sao:** test, TSan, UBSan chỉ thấy những gì đã chạy. Lỗi thứ tự bộ nhớ có thể không bao giờ
  hiện trên x86 (TSO) rồi hiện trên ARM; xấp xỉ lệch 1 ulp chỉ lộ sau hàng tỉ phép tính. Lập luận
  viết ra thì review được; "chạy qua test" thì không.
- **Kiểm:** review lập luận; TSan cho mã đa luồng; test vét cạn hoặc theo cận cho xấp xỉ (CM-16).

```cpp
// ✓ [tsan] Công bố một giá trị: comment nêu đúng cặp release/acquire và dữ liệu được công bố.
#include "core/check.hpp"

#include <atomic>
#include <cstdint>
#include <thread>

namespace game::conc {

// Một luồng ghi, một luồng đọc, công bố đúng một lần. publish ghi tick_rate rồi store(release)
// ready; consume wait(acquire) tới khi đọc được true. Lần load acquire đó đọc giá trị do store
// release ghi nên store synchronizes-with load ([atomics.order]); ghi tick_rate trước store vì
// thế happens-before đọc tick_rate sau wait ([intro.races]). tick_rate không cần là atomic.
struct Publication {
    std::int32_t tick_rate = 0;
    std::atomic<bool> ready{false};
};

inline void publish(Publication& slot, std::int32_t tick_rate) noexcept {
    slot.tick_rate = tick_rate;
    slot.ready.store(true, std::memory_order_release);
    slot.ready.notify_one();
}

[[nodiscard]] inline std::int32_t consume(const Publication& slot) noexcept {
    slot.ready.wait(false, std::memory_order_acquire);
    return slot.tick_rate;
}

} // namespace game::conc

int main() {
    game::conc::Publication slot;
    const std::jthread writer([&slot] { game::conc::publish(slot, 30); });
    game::core::check(game::conc::consume(slot) == 30, "consume: thấy giá trị cũ");
    return 0;
}
```

## Kiểm nhanh

- [ ] Đã xác định cấp của việc và mở đúng refs theo MAP.md? (HP-10)
- [ ] Có biểu thức nào UB với một đầu vào thoả hợp đồng (tràn có dấu, dịch bit, treo)? (HP-02)
- [ ] Còn trạng thái vô nghĩa biểu diễn được, hay view sống lâu hơn chủ? (HP-03, HP-04)
- [ ] Lỗi lập trình dừng bằng check, lỗi dự kiến trả expected, không chỗ nào nuốt lỗi? (HP-05)
- [ ] Comment nói hợp đồng và vì sao, code port có "Khác gốc"; không code chết, TODO vô chủ? (HP-07, HP-08)
- [ ] Mọi API, cờ, tên check chưa chắc đã được tra hoặc biên dịch thử? (HP-09)
- [ ] Không byte nào từ client đi vào check, assert hay abort? (HP-16)
- [ ] Mọi tối ưu có số đo; mọi kỹ thuật [T] đủ bốn điều kiện và có lập luận? (HP-14, HP-17, HP-18)
- [ ] Báo cáo tách Đã kiểm / Chưa kiểm / Giả định, không khẳng định điều chưa chạy? (HP-11)

## Thuật ngữ

Dùng thống nhất trong refs/, comment, báo cáo; định danh code vẫn tiếng Anh. Giữ nguyên tiếng
Anh: tick, handle, heap, mutex, aggregate, view, range, template, concept, benchmark, profiler, sanitizer.

| Tiếng Việt | Tiếng Anh | Tiếng Việt | Tiếng Anh |
|---|---|---|---|
| làn | lane | mặt nạ | mask |
| căn lề | alignment | dòng cache | cache line |
| đường nóng / lạnh | hot path / cold path | nhánh / đoán sai nhánh | branch / mispredict |
| quyền sở hữu | ownership | vòng đời | lifetime |
| treo | dangling | UB | undefined behavior |
| bất biến | invariant | hợp đồng | contract |
| tiền điều kiện | precondition | hậu điều kiện | postcondition |
| cấp phát | allocation | ngăn xếp / heap | stack / heap |
| luồng | thread | khoá / mutex | lock / mutex |
| tranh chấp dữ liệu | data race | nguyên tử | atomic |
| thứ tự bộ nhớ | memory order | thông lượng / độ trễ | throughput / latency |
| fuzz | fuzzing | thực thể | entity |
| gói tin | packet | phiên | session |
| máy chủ quyết định | server-authoritative | tất định | deterministic |
| không tốn phí | zero-cost | sao chép tầm thường | trivially copyable |
| nạp chồng | overload | nội tuyến | inline |
| vector hoá | vectorize | vô hướng | scalar |
| ước lượng | estimate | dừng sớm (fail-fast) | fail-fast |
| số không chuẩn | denormal, subnormal | phần định trị / số mũ | mantissa / exponent |
| giá trị canh | sentinel value | câu bảo vệ | guard clause |
| độ lồng điều khiển | control nesting depth | ulp | unit in the last place |
