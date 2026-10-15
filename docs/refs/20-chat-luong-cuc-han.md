# CL · Chất lượng cực hạn: năm thuộc tính, bằng chứng, cổng máy

> **Phạm vi:** mức chất lượng bắt buộc của mọi mã đi vào dự án từ 2026-10-08 (người dùng chốt: bỏ
> luật hình thức, nâng chất lượng thật lên cực hạn). Năm thuộc tính — an toàn, bền, tối ưu, hiện
> đại, thông minh — và bằng chứng của từng thuộc tính; cổng máy đã đo trên máy này; phân tích thất
> bại trước khi viết; test theo luật Test (không cặp từng file); độ phức tạp có trần; bảng idiom cũ → C++23; để máy
> chứng minh thay người; giữ thiết kế đơn giản; đường nóng do trình dịch chứng minh không cấp phát.
> **Đọc khi:** bắt đầu MỌI việc C++ (CL-01 tới CL-08); viết hàm chạy mỗi tick (CL-09); nâng cấp trình
> dịch hay clang-tidy (CL-10).
> **Liên quan:** HP-01, HP-10, HP-11 (ưu tiên, quy trình, báo cáo); UB-07, UB-08, UB-17 (sanitizer,
> hardening); KT-03, KT-07, KT-11, KT-14 (test); HN-01, HN-02, HN-03 (đo, độ phức tạp, cấp phát);
> RV-04 (báo cáo); BD-02, BD-05, BD-19 (cảnh báo, clang-tidy, công cụ lỗi).

## 1. Nền tảng [N]

### CL-01 [N] PHẢI — Mọi thay đổi đạt đủ năm thuộc tính an toàn, bền, tối ưu, hiện đại, thông minh; mỗi thuộc tính có bằng chứng trong báo cáo

Không còn "mã thường": mã sản phẩm, công cụ, test đều theo mức này, và quy tắc [C] áp cho mọi mã
trong phạm vi nó chạm tới, không chỉ thư viện dùng chung. Chất lượng là thuộc tính đo được của kết
quả, không phải số lớp bọc hay nghi thức (CL-08).

| Thuộc tính | Nghĩa là | Bằng chứng được tính | Không được tính |
|---|---|---|---|
| An toàn | không UB, không vượt biên, không treo, không tranh chấp dữ liệu — với MỌI đầu vào, kể cả đầu vào thù địch | cổng máy CL-02 xanh; ca biên chạy dưới sanitizer và hai thư viện chuẩn; fuzz cho hàm giải mã (KT-11) | "đã đọc lại", "trông đúng" |
| Bền | mọi cách thất bại đã liệt kê có đường xử lý; tài nguyên có trần; dừng giữa chừng không để lại trạng thái nửa vời | bảng phân tích thất bại (CL-03); test chỉ khi luật Test đòi, và khi có thì mã lỗi của hàm đó có ca đi tới (CL-04); trần và hạn chờ là hằng có tên (UB-13, UB-14, UB-15) | dựng test đối ứng cho mọi file, kể cả đồ hoạ |
| Tối ưu | đúng độ phức tạp; không cấp phát, sao chép, gọi gián tiếp thừa trên đường nóng; mọi câu "nhanh hơn" có số đo | độ phức tạp và trần ghi ở hợp đồng (CL-05); đường nóng qua CL-09; số đo trước và sau (HN-01), hoặc ghi rõ "không phải đường nóng" | "chắc nhanh hơn" |
| Hiện đại | tiện ích chuẩn C++23 trước, tự viết sau; không idiom cũ có thay thế an toàn hơn | cổng máy bắt phần lớn; phần còn lại theo bảng CL-06 | "mã cũ vẫn chạy" |
| Thông minh | điều gì máy chứng minh được thì máy chứng minh; thiết kế đơn giản nhất đủ bốn thuộc tính trên | kiểu, `static_assert`, `constexpr`, thuộc tính (CL-07); không trừu tượng thừa (CL-08) | comment đứng thay phép kiểm |

- **Vì sao:** "chất lượng cao" không kèm bằng chứng là lời hứa; người dùng quyết định dựa trên báo
  cáo (HP-11). Mỗi thuộc tính có một kiểu bằng chứng riêng vì chúng hỏng theo những cách khác nhau:
  mã qua mọi test vẫn có thể bậc hai theo số người chơi, mã nhanh vẫn có thể sập vì một gói dựng sẵn.
- **Kiểm:** báo cáo cuối việc (RV-04) có mục "Đã kiểm" đi qua đủ năm thuộc tính; thuộc tính không
  áp dụng cho thay đổi này thì ghi một câu vì sao.

### CL-02 [N] PHẢI — Mọi tệp C++ đã đổi qua cổng biên dịch và clang-tidy; test có sẵn hoặc test vừa viết thì chạy trên hai thư viện chuẩn

`check.py <tệp đã đổi>` cho mọi thay đổi. `check.py --run <test> --with <nguồn>` chỉ khi việc đã có
file test, hoặc vừa viết test theo luật Test trong `~/.claude/CLAUDE.md` (chốt 2026-10-11: logic
thuần sai thì hỏng thầm, sửa bug, hoặc người dùng yêu cầu). Không dựng file test đối ứng chỉ để có
`--run`. Code đồ hoạ không viết test logic để điền tầng chạy. Bốn tầng, đo 2026-10-08 trên GCC 16.2 MinGW,
Clang 23.1 + STL MSVC 14.51, clang-tidy 23.1; cột cuối là thứ bộ cổng trước ngày đó để lọt:

| Tầng | Thành phần | Bắt thêm |
|---|---|---|
| Biên dịch `-Werror` | 29 cờ chung, 23 cờ GCC, 32 cờ Clang trong `config/warnings-*.txt` | `0` làm con trỏ null; lớp có destructor mà vẫn chép ngầm; enum trộn kiểu; đối tượng tĩnh có constructor hay destructor (SH-18); `default` che thiếu `case` (PH-07); mã không tới được; `reinterpret_cast` UB; mức cao nhất của `-Warray-bounds`, `-Wstringop-overflow`, `-Wuse-after-free`; `-Wfunction-effects` (CL-09) |
| clang-tidy | 438 check, cảnh báo là lỗi | `using namespace` trong header; tham số mặc định trên hàm ảo; `long`, `short`; phép nhân tràn trước khi nới kiểu; hai tham số liền nhau chỉ khác `const` |
| Chạy bằng Clang | ASan + UBSan + `implicit-integer-truncation`, `local-bounds`, `float-divide-by-zero`, `nullability` + `_MSVC_STL_HARDENING=1` | `*optional` rỗng và thu hẹp ngầm đổi giá trị lúc chạy (cả hai trước đây thoát 0); chia số thực cho 0 |
| Chạy bằng GCC | debug mode của libstdc++ (`_GLIBCXX_DEBUG`), `-fstack-protector-strong`, `-ftrivial-auto-var-init=pattern` | iterator đã vô hiệu (SH-07; không debug mode thì thoát 0). Trước ngày này GCC không chạy test nào trên Windows |

- **Vì sao:** mỗi tầng bắt một loại lỗi mà tầng khác không thấy — đã đo từng loại bằng một tệp cố ý
  sai. ASan + UBSan không thấy `*optional` rỗng; không trình dịch nào thấy iterator treo sau
  `push_back`; hai thư viện chuẩn cho kết quả khác nhau ở mọi chỗ unspecified (KT-19).
- **Kiểm:** output của hai lệnh nằm trong báo cáo. Cổng đỏ thì sửa mã; chỉ tắt đúng một chẩn đoán
  khi chứng minh được nó báo nhầm, kèm phiên bản công cụ và ca tái hiện (BD-19).
- **Ngoại lệ:** Linux giữ ASan + UBSan gốc cho cả hai trình dịch; nhóm UBSan mở rộng chưa đo với
  libc++ (UB-17). TSan không có trên Windows.

```bash
python3 ~/.claude/cpp23/tools/check.py src/inv/stack.cpp src/inv/stack.hpp
python3 ~/.claude/cpp23/tools/check.py --run tests/inv_tests.cpp --with src/inv/stack.cpp
```

### CL-03 [N] PHẢI — Phân tích thất bại trước khi viết: với mỗi đầu vào, tài nguyên và bước, trả lời "hỏng thế nào" rồi mới viết mã

Trước khi viết hàm hay module có đầu vào từ ngoài, có tài nguyên, hoặc nhiều bước: đi hết bảng
dưới. Mỗi dòng kết thúc bằng một trong hai — một câu bảo vệ trong mã (test kèm theo chỉ khi luật
Test đòi, CL-04), hoặc "không thể xảy ra vì kiểu hay bất biến nào cấm" (CL-07). Không có lựa chọn
thứ ba là "chắc không ai làm thế".

| Hỏi | Ca phải xét |
|---|---|
| Giá trị | 0, 1, lớn nhất, âm, `INT_MIN`, NaN, ±∞, rỗng, trùng lặp, đã sắp và chưa sắp |
| Kích thước | rỗng, một phần tử, đúng trần, trần + 1, độ dài khai báo lớn hơn dữ liệu thật (UB-04) |
| Thứ tự, thời gian | đến hai lần, đến ngược thứ tự, đến sau khi đối tượng đã chết (MMO-04), tick 0, đúng tick hết hạn |
| Tài nguyên | hết bộ nhớ, hàng đợi đầy (UB-13), quá hạn chờ (UB-15), tệp hay DB lỗi giữa chừng |
| Nhiều bước | dừng sau bước k thì trạng thái còn nhất quán không (LH-12, MMO-08); chạy lại có an toàn không |
| Đồng thời | hai tác nhân cùng chạm một tài nguyên; ai là chủ (DT-01) |
| Kẻ tấn công | giá trị nào tốn CPU hay bộ nhớ nhiều nhất; gửi lặp nhanh nhất có thể (UB-14) |

- **Vì sao:** lỗi production gần như không nằm ở đường thành công; nó nằm ở ca chưa ai hỏi tới. Hỏi
  trước khi viết thì câu trả lời thành kiểu và câu bảo vệ; hỏi sau khi viết thì thành bản vá.
- **Kiểm:** bảng ca biên của test (KT-03) có một dòng cho mỗi ca đã quyết; thay đổi ở ranh giới tin
  cậy được review theo RV-05.

### CL-04 [N] NÊN — Khi một hàm logic đã có test: mỗi mã lỗi, câu bảo vệ và ca biên của hàm đó có một ca đi tới

Không bắt mỗi file nguồn một file test, và không viết test logic cho code đồ hoạ. Viết test chỉ theo
luật Test trong `~/.claude/CLAUDE.md` (chốt 2026-10-11). Khi test đó tồn tại: mỗi enumerator của enum
lỗi có ít nhất một dòng trong bảng test sinh ra đúng nó, và bảng tự kiểm điều đó lúc biên dịch khi
hàm là `constexpr`. Mỗi câu bảo vệ của hàm đó được đi qua cả hai phía. Dòng logic của hàm đã có test
mà chưa từng chạy thì thêm ca hoặc xoá dòng — không áp câu này cho file không thuộc diện phải test.

- **Vì sao:** mã xử lý lỗi là mã ít được chạy nhất và hỏng nhiều nhất; một nhánh lỗi chưa từng chạy
  là mã chưa từng được kiểm, kể cả kiểm rằng nó biên dịch ra đúng ý.
- **Kiểm:** bảng test dưới đây; độ phủ đo bằng `llvm-cov` (đã chạy được trên máy này với Clang 23
  nhắm MSVC), đọc cột số lần chạy bằng 0.

```cpp
// ✓ [chạy] Mỗi mã lỗi và mỗi biên một dòng trong bảng; thêm mã lỗi mà quên test là lỗi biên dịch.
#include "core/check.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <expected>
#include <utility>

namespace game::inv {

enum class [[nodiscard]] SplitError : std::uint8_t { kZeroAmount, kNotEnough, kTargetFull };

inline constexpr std::uint32_t kMaxStack = 999;

struct SplitRequest {
    std::uint32_t source = 0;
    std::uint32_t target = 0;
    std::uint32_t amount = 0;
};

struct Split {
    std::uint32_t source_left = 0;
    std::uint32_t target_total = 0;

    friend constexpr bool operator==(Split, Split) = default;
};

using SplitResult = std::expected<Split, SplitError>;

// Tách amount vật phẩm từ chồng nguồn sang chồng đích. Hàm toàn phần: mọi bộ ba uint32 đều cho kết
// quả xác định, không phép trừ hay cộng nào tràn vì mỗi phép đứng sau câu bảo vệ của nó.
[[nodiscard]] constexpr SplitResult split_stack(SplitRequest request) noexcept {
    if (request.amount == 0) return std::unexpected(SplitError::kZeroAmount);
    if (request.amount > request.source) return std::unexpected(SplitError::kNotEnough);
    const bool target_full = request.target >= kMaxStack || request.amount > kMaxStack - request.target;
    if (target_full) return std::unexpected(SplitError::kTargetFull);
    return Split{.source_left = request.source - request.amount, .target_total = request.target + request.amount};
}

struct Case {
    SplitRequest request;
    SplitResult expected;
};

// Mỗi câu bảo vệ: một dòng ngay ngoài biên, một dòng ngay trong biên.
inline constexpr auto kCases = std::to_array<Case>({
    {.request = {.source = 10, .target = 0, .amount = 0}, .expected = std::unexpected(SplitError::kZeroAmount)},
    {.request = {.source = 10, .target = 0, .amount = 11}, .expected = std::unexpected(SplitError::kNotEnough)},
    {.request = {.source = 10, .target = 990, .amount = 10}, .expected = std::unexpected(SplitError::kTargetFull)},
    {.request = {.source = 10, .target = 999, .amount = 1}, .expected = std::unexpected(SplitError::kTargetFull)},
    {.request = {.source = 5, .target = 4'000'000'000U, .amount = 1}, .expected = std::unexpected(SplitError::kTargetFull)},
    {.request = {.source = 10, .target = 989, .amount = 10}, .expected = Split{.source_left = 0, .target_total = 999}},
    {.request = {.source = 1, .target = 0, .amount = 1}, .expected = Split{.source_left = 0, .target_total = 1}},
});

[[nodiscard]] constexpr bool passes(const Case& one) noexcept {
    return split_stack(one.request) == one.expected;
}

[[nodiscard]] constexpr bool is_tested(SplitError error) noexcept {
    return std::ranges::any_of(kCases, [error](const Case& one) { return one.expected == std::unexpected(error); });
}

inline constexpr std::array kAllErrors{SplitError::kZeroAmount, SplitError::kNotEnough, SplitError::kTargetFull};

static_assert(kAllErrors.size() == std::to_underlying(SplitError::kTargetFull) + 1U, "kAllErrors phải liệt kê đủ enum");
static_assert(std::ranges::all_of(kAllErrors, is_tested), "mỗi mã lỗi phải có một dòng trong kCases");
static_assert(std::ranges::all_of(kCases, passes));

} // namespace game::inv

int main() {
    for (const game::inv::Case& one : game::inv::kCases) {
        game::core::check(game::inv::passes(one), "split_stack: ca trong bảng phải cho đúng kết quả");
    }
    return 0;
}
```

```bash
# Độ phủ của một test: dòng có số lần chạy 0 là dòng chưa ai kiểm.
clang++ -std=c++23 -O0 -g -fprofile-instr-generate -fcoverage-mapping -Isrc tests/inv_tests.cpp src/inv/stack.cpp -o cover.exe
LLVM_PROFILE_FILE=cover.profraw ./cover.exe
llvm-profdata merge -sparse cover.profraw -o cover.profdata
llvm-cov show ./cover.exe -instr-profile=cover.profdata src/inv/stack.cpp
```

### CL-05 [N] PHẢI — Ghi độ phức tạp và trần đầu vào ở hợp đồng của mọi vòng lặp theo dữ liệu; CẤM thuật toán trên tuyến tính khi kích thước do bên ngoài quyết định

Comment hợp đồng (CM-03) của hàm có vòng lặp theo dữ liệu nêu O(…) theo biến nào và trần của biến
đó là hằng có tên nào. Bậc hai ngầm phải có trần chứng minh được hoặc đổi thuật toán: `find` trong
vòng lặp, `erase` giữa `vector` trong vòng lặp, vòng lồng trên cùng một dãy, nối chuỗi trong vòng
lặp, sắp xếp lại sau mỗi lần chèn. Cách đổi: sắp một lần rồi quét hai con trỏ, bảng tra theo khoá
(STD-01), gom rồi xoá một lượt (`std::erase_if`), lưới (MMO-10).

- **Vì sao:** thuật toán bậc hai chạy ổn với 50 thực thể lúc test và thành đòn từ chối dịch vụ với
  5000 thực thể hay một gói khai 65535 phần tử. Trần không ghi ra thì không ai kiểm nó còn đúng.
- **Kiểm:** review hợp đồng; benchmark ở đúng trần (HN-07) cho hàm trên đường nóng; test ở trần và
  trần + 1 (CL-03).

### CL-06 [N] CẤM — Idiom cũ khi C++23 có thay thế chuẩn an toàn hơn

Cột cuối là thứ bắt nó trong cổng CL-02; "review" nghĩa là chưa có máy bắt.

| Cũ | Thay bằng | Quy tắc | Máy bắt |
|---|---|---|---|
| `(T)x`, `T(x)` | `static_cast`, `std::bit_cast`, `core::narrow` | KG-04, KG-05 | `-Wold-style-cast` |
| `NULL`, `0` làm con trỏ | `nullptr` | — | `-Wzero-as-null-pointer-constant` |
| `new`, `delete`, `malloc` | `std::make_unique`, container | SH-03 | `cppcoreguidelines-owning-memory`, `cppcoreguidelines-no-malloc` |
| mảng C, con trỏ kèm độ dài | `std::array`, `std::span` | STD-08 | `cppcoreguidelines-avoid-c-arrays`, `cppcoreguidelines-pro-bounds-pointer-arithmetic` |
| `printf`, `iostream`, `std::endl` | `std::print`, `std::format` | STD-04, HN-06 | `modernize-use-std-print`, `performance-avoid-endl` |
| `atoi`, `strtol`, `stoi`, `sscanf` | `std::from_chars`, kiểm `ec` và đã đọc hết | STD-06 | `cert-err34-c` |
| `long`, `unsigned long`, `short` | kiểu cỡ cố định theo vai trò | KG-03 | `google-runtime-int` |
| `typedef`, `enable_if` | `using`, concept | GN-01 | `modernize-use-using`, `modernize-use-constraints` |
| tham số ra; mã lỗi `int` hay `bool` | trả struct, `std::optional`, `std::expected` | API-02, HP-05 | review |
| `union` để đọc kiểu khác, `reinterpret_cast` | `std::variant`, `std::bit_cast`, `std::memcpy` | KG-05, UB-03 | `-Wundefined-reinterpret-cast`, `cppcoreguidelines-pro-type-reinterpret-cast`, `cppcoreguidelines-pro-type-union-access` |
| `std::bind`; `std::function` cho tham số gọi ngay | lambda; template ràng buộc `std::invocable` | GN-07 | `modernize-avoid-bind` |
| vòng lặp tay để tìm, đếm, xoá | `std::ranges::…`, `std::erase_if` | STD-03 | review |
| `enum` trần, hằng bằng macro | `enum class` có kiểu nền, `constexpr` | KG-06, DD-10 | `-Wenum-conversion`, `cppcoreguidelines-macro-usage` |
| `std::thread` + `detach`; `lock()`/`unlock()` tay | `std::jthread`; `std::scoped_lock` | DT-03, DT-04 | review |
| `volatile` để đồng bộ; toán tử trên atomic | `std::atomic` với `load`/`store`/`fetch_*` gọi tường minh | DT-05, DT-18 | `-Wvolatile`, `-Watomic-implicit-seq-cst` |
| `rand()`; phân phối `<random>` cho gameplay | PRNG và phân phối tự viết | MMO-17, STD-14 | `cert-msc50-cpp` |
| biến tĩnh có constructor hay destructor | `constexpr`, `constinit` | SH-18 | `-Wglobal-constructors`, `-Wexit-time-destructors` |
| constructor một đối số không `explicit` | `explicit` | API-04 | `cppcoreguidelines-explicit-constructor` |
| `.value()`, `assert` | `*`/`->` sau câu bảo vệ; `core::check` | STD-09, LH-02 | review |

- **Vì sao:** mỗi dòng bên trái là một lớp lỗi đã có tên: thu hẹp im lặng, rò bộ nhớ, tràn bộ đệm,
  kiểu đổi cỡ theo nền tảng (`long` 32 bit trên Windows, 64 bit trên Linux), thứ tự khởi tạo tĩnh.
  Thay thế chuẩn chuyển lỗi đó về lúc biên dịch hoặc biến nó thành dừng có thông điệp.
- **Kiểm:** cổng CL-02; các dòng "review" theo checklist refs/19 §4.

### CL-07 [N] PHẢI — Điều gì máy chứng minh được thì để máy chứng minh: đặt mỗi bất biến ở bậc cao nhất dùng được

Sáu bậc, từ mạnh tới yếu. Bất biến đặt thấp hơn bậc cao nhất dùng được là một khiếm khuyết.

1. Kiểu làm trạng thái sai không viết ra được: `enum class`, ID mạnh, đơn vị trong kiểu, type-state
   (HP-03, KG-08, KG-09, KG-14, KG-15).
2. Kiểm lúc biên dịch: concept, `static_assert`, `consteval`, bảng `constexpr` tự kiểm (GN-05,
   GN-17, LH-16, CM-08, UB-16).
3. Chữ ký và thuộc tính để trình dịch kiểm nơi gọi: `[[nodiscard]]`, `explicit`, `noexcept`,
   `GAME_LIFETIMEBOUND` (SH-17), `GAME_NONALLOCATING` (CL-09).
4. Kiểm lúc chạy luôn bật: `core::check`, hardening thư viện chuẩn (LH-02, UB-08).
5. Test: bảng ca biên, thuộc tính, fuzz, sai phân (KT-03, KT-09, KT-11, KT-15).
6. Comment hợp đồng (CM-03) — chỉ cho phần năm bậc trên không nói được.

- **Vì sao:** bậc 1 và 2 không thể bị quên, bị tắt hay bị bỏ lọt trong review; bậc 6 đúng tới lần
  sửa đầu tiên. Mỗi bậc đi xuống là một lớp lỗi được phép tồn tại lâu hơn trước khi bị phát hiện.
- **Kiểm:** review: comment nói về miền, cỡ, thứ tự, "không bao giờ null", "luôn dương" mà không có
  kiểu hay `static_assert` đi kèm thì đẩy lên bậc trên.

### CL-08 [N] PHẢI — Thiết kế đơn giản nhất đủ năm thuộc tính: mỗi lớp trừu tượng, tham số và tuỳ chọn có nơi dùng thật ngay trong thay đổi này

Cực hạn về chất lượng không phải cực hạn về số tầng. Interface, tham số template, struct tham số,
lớp bọc, cờ cấu hình chỉ được thêm khi đã có nơi dùng thứ hai hoặc một test cần chỗ cắm ngay trong
thay đổi này; không có thì xoá. Hàm nhỏ nội bộ không thể thất bại thì không khoác `std::expected`,
concept hay lớp bọc cho đủ lễ. Xoá mã là cách sửa được ưu tiên trước thêm mã.

- **Vì sao:** mỗi tầng thừa là thêm chỗ cho lỗi ẩn, thêm thời gian biên dịch (GN-16), thêm thứ phải
  test, và che đường đi của dữ liệu. Mã không tồn tại là mã duy nhất chắc chắn không có lỗi (HP-13).
- **Kiểm:** review: mỗi kiểu, tham số, tuỳ chọn mới trả lời được "ai dùng, ở dòng nào"; không trả
  lời được thì xoá.

## 2. Nâng cao [C]

### CL-09 [C] PHẢI — Hàm chạy mỗi tick trên đường nóng khai `GAME_NONALLOCATING` để Clang chứng minh nó không cấp phát; luồng không được chờ khai `GAME_NONBLOCKING`

Clang kiểm thuộc tính kiểu `[[clang::nonallocating]]` và `[[clang::nonblocking]]` khi bật
`-Wfunction-effects` (có trong `config/warnings-clang.txt`): hàm mang thuộc tính chỉ được gọi hàm
cũng mang thuộc tính, hoặc hàm mà trình dịch suy ra được từ thân của nó. Đo 2026-10-08, Clang 23.1
với STL MSVC 14.51: vòng lặp trên `std::span`, `std::min`, `std::ranges::sort`, `core::check`,
`std::optional`, `std::expected`, `subspan` (kể cả khi bật hardening) đi qua không cảnh báo;
`std::vector::push_back` bị báo ở hàm `nonallocating`; khoá `std::mutex` bị báo ở hàm
`nonblocking`. GCC 16 không biết thuộc tính này và cảnh báo `-Wattributes`, nên đi qua macro.

- **Vì sao:** HN-03 cấm cấp phát mỗi tick nhưng trước đây chỉ review bắt; một `push_back` thêm vào
  sau sáu tháng làm tick thỉnh thoảng trễ (HN-18) mà không test nào đỏ. Thuộc tính biến quy tắc
  thành lỗi biên dịch ở đúng dòng vi phạm, kèm chuỗi lời gọi dẫn tới chỗ cấp phát.
- **Kiểm:** build Clang của cổng CL-02. Macro định nghĩa một chỗ ở tầng core (KTR-01).

```cpp
// ✗ push_back có thể cấp phát lại giữa tick: Clang báo -Wfunction-effects ở đúng dòng đó.
#include <cstdint>
#include <span>
#include <vector>

#if __has_cpp_attribute(clang::nonallocating)
#define GAME_NONALLOCATING [[clang::nonallocating]]
#else
#define GAME_NONALLOCATING
#endif

namespace game::sim {

inline void collect_low(std::span<const std::int32_t> hp, std::vector<std::int32_t>& out) noexcept GAME_NONALLOCATING {
    for (const std::int32_t one : hp) {
        if (one < 10) out.push_back(one);
    }
}

} // namespace game::sim
```

```cpp
// ✓ Nơi gọi cấp sẵn chỗ ghi; hàm đường nóng chỉ ghi vào đó, và trình dịch chứng minh nó không cấp phát.
#include "core/check.hpp"

#include <cstddef>
#include <cstdint>
#include <span>

#if __has_cpp_attribute(clang::nonallocating)
#define GAME_NONALLOCATING [[clang::nonallocating]]
#else
#define GAME_NONALLOCATING
#endif

namespace game::sim {

// Chép vào out mọi giá trị máu dưới 10 và trả số phần tử đã ghi; O(n), n là số thực thể của zone.
// out phải dài ít nhất bằng hp: nơi gọi cấp một lần lúc dựng zone và tái dùng qua các tick.
[[nodiscard]] inline std::size_t collect_low(std::span<const std::int32_t> hp, std::span<std::int32_t> out) noexcept GAME_NONALLOCATING {
    core::check(out.size() >= hp.size(), "collect_low: out phải dài ít nhất bằng hp");
    std::size_t count = 0;
    for (const std::int32_t one : hp) {
        out[count] = one;
        count += static_cast<std::size_t>(one < 10);
    }
    return count;
}

} // namespace game::sim
```

## 3. Thần thoại [T]

### CL-10 [T] PHẢI — Nâng cấp trình dịch hay clang-tidy thì đo lại cổng: thử mọi chẩn đoán mới trên bộ mẫu, giữ cái sạch, ghi cái loại kèm số đo

Mỗi bản công cụ mới: liệt kê chẩn đoán còn tắt, bật thử tất cả trên mọi mẫu ✓ của `refs/` (không
`-Werror`, đếm theo tên cờ), rồi quyết từng cái. Cờ không báo gì trên mẫu và bắt một lớp lỗi thật
thì vào `config/`; cờ báo trên mã đúng thì ghi vào bảng dưới kèm số đo để lần sau không thử lại
mù. `-Weverything` chỉ dùng để ĐO, không bao giờ nằm trong cấu hình.

| Ứng viên (đo 2026-10-08, 284 mẫu) | Kết quả | Quyết định |
|---|---|---|
| GCC `-Wfloat-equal` | 3 chỗ, đều là so chính xác có chủ ý (SV-03) | loại |
| GCC `-Wnrvo` | 4 chỗ, hàm trả hai đối tượng khác nhau theo nhánh | loại |
| GCC `-Wnoexcept` | 3 chỗ, đều nằm trong header libstdc++ | loại |
| GCC `-Wunused-macros` | 1 chỗ: `NOMINMAX` đặt trước `<windows.h>` (DD-14) | loại |
| GCC `-fanalyzer` | 11,5 giây cả bộ; 1 báo nhầm "chưa khởi tạo" đi xuyên `std::vector` | loại |
| Clang `-Wunsafe-buffer-usage` | 2 chỗ (BN-17), cộng 237 chỗ ở `std::memcpy`, `std::fprintf` đúng quy cách | loại: `cppcoreguidelines-pro-bounds-pointer-arithmetic` đã cấm cùng thứ |
| Clang `-Wlifetime-safety-*` | 20 chỗ gợi ý và "later invalidated" trên mã đúng | loại; SH-17 vẫn áp bằng tay |
| Clang `-Wctad-maybe-unsupported` | 13 chỗ ở 8 mẫu, CTAD hiển nhiên (GN-10) | loại |
| Clang `-Wswitch-default` | 4 chỗ, trái PH-07 | loại |
| Clang `-Wnonportable-system-include-path` | đòi `<Windows.h>`; MinGW cần chữ thường | loại |
| UBSan `implicit-integer-sign-change` | báo nhầm trong `xcharconv_ryu.h` của STL MSVC 14.51 | loại |
| clang-tidy `misc-const-correctness.WarnPointersAsValues` | 2 chỗ, đều là tham số con trỏ | loại |
| 29 cờ mới cho GCC và 38 cho Clang (12 cờ chung), 4 check google, 9 tuỳ chọn chặt của clang-tidy | 0 chỗ, sau khi thêm NOLINT có lý do ở 2 mẫu | nhận (CL-02) |

- **Vì sao:** trình dịch mỗi năm thêm hàng chục chẩn đoán; không đo thì hoặc bỏ lỡ cái bắt lỗi thật,
  hoặc bật cái báo nhầm rồi cả đội học cách lờ cảnh báo. Số đo ghi lại để quyết định không phải làm
  lại từ trí nhớ (HP-09).
- **Kiểm:** `tools/verify.py --tidy` 0 lỗi sau mỗi lần đổi `config/`; bảng trên được cập nhật trong
  cùng thay đổi.

```bash
# GCC: cảnh báo còn tắt với bộ hiện tại (chạy ở gốc bộ quy cách).
g++ -x c++ -std=c++23 -O2 $(cat config/warnings-common.txt config/warnings-gcc.txt) -Q --help=warnings -fsyntax-only - < /dev/null | grep disabled
# Clang: mọi chẩn đoán trên một tệp, chỉ để đo.
clang++ -std=c++23 -Weverything -Wno-c++98-compat -Wno-pre-c++23-compat -Wno-padded -fsyntax-only tệp.cpp
```

## Kiểm nhanh

- [ ] Báo cáo có bằng chứng cho đủ năm thuộc tính, hoặc một câu vì sao thuộc tính đó không áp dụng? (CL-01)
- [ ] `check.py` đã chạy trên mọi tệp đã đổi; `check.py --run` đã chạy nếu việc có file test? (CL-02)
- [ ] Bảng "hỏng thế nào" đã đi hết trước khi viết; mỗi dòng thành câu bảo vệ hoặc bị kiểu cấm? (CL-03)
- [ ] Hàm đã có test thì mỗi mã lỗi và câu bảo vệ của hàm đó có ca đi tới? File không thuộc diện test thì không dựng test đối ứng? (CL-04)
- [ ] Vòng lặp theo dữ liệu ghi độ phức tạp và trần; không bậc hai ngầm trên dữ liệu từ ngoài? (CL-05)
- [ ] Không idiom cũ nào trong bảng; các dòng "review" đã tự soát? (CL-06)
- [ ] Mỗi bất biến nằm ở bậc cao nhất dùng được, comment không đứng thay kiểu hay `static_assert`? (CL-07)
- [ ] Mỗi trừu tượng, tham số, tuỳ chọn mới có nơi dùng thật ngay trong thay đổi này? (CL-08)
- [ ] Hàm đường nóng mang `GAME_NONALLOCATING`, build Clang sạch? (CL-09)
- [ ] Đổi phiên bản công cụ thì đã đo lại cổng và cập nhật bảng? (CL-10)
