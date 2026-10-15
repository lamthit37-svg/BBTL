# SV · SIMD, vi kiến trúc và số thực

> **Phạm vi:** vòng lặp vector hoá được, báo cáo vector hoá, so sánh số thực, NaN, float/double,
> `-ffast-math`, lớp bọc SIMD (math/vector.hpp, vector_int.hpp), mặt nạ, `loadu`, dispatch theo CPU,
> FMA, số không chuẩn, tổng bù, số thực tất định, ulp, ước lượng + Newton–Raphson, cmov/nhánh, nhiều
> bộ cộng dồn, cổng thực thi, AVX-512, gather. **Đọc khi:** viết/sửa vòng lặp số học nóng hoặc code
> intrinsic; so sánh float; nhận số thực từ client; chọn cờ số thực; code phải tất định (lockstep,
> replay); thấy `_mm_*`, `-ffast-math`, `rsqrt`, `== 0.0F`, `?:` trong vòng lặp nóng.
> **Liên quan:** refs/09-hieu-nang.md (HN — cờ, đo, asm), refs/10-bo-nho-cache-dod.md (BN — SoA, căn
> lề, `__restrict`), refs/13-ub-on-dinh.md (UB-05, UB-07), refs/15-kiem-thu.md (KT-15 sai phân,
> KT-16 replay, KT-17 vét cạn), refs/08-thu-vien-chuan-cpp23.md (STD-11, STD-14, STD-15),
> refs/18-game-mmo.md (MMO — tất định, fixed-point).

## 1. Nền tảng [N]

### SV-01 [N] PHẢI — Vòng lặp nóng viết ở dạng vector hoá được: dữ liệu liền, số lần lặp đếm được, không gọi hàm mờ, không thoát sớm theo dữ liệu, không alias mơ hồ

Thân vòng lặp là phép tính thẳng trên `span` liền (SoA — BN-06); điều kiện theo phần tử viết thành
chọn giá trị (`?:`, `std::min/max`), không `if (…) continue;`; hàm gọi trong thân nội tuyến được (giới
hạn tốc độ là mảng liền, không phải `speed_limit(i)` định nghĩa ở TU khác). Đã kiểm (x86-64): GCC 14
và 15 ở -O2 không vector hoá vòng lặp cần kiểm alias lúc chạy, GCC 14 còn bỏ cả vòng cần phần dư;
Clang 20 -O2 vector hoá cả hai; cần chắc chắn thì -O3 cho TU đó hoặc SIMD tường minh (SV-07). Cộng dồn `float` không
được vector hoá thật khi thiếu `-ffast-math` (SV-18).

- **Vì sao:** vector hoá cho 4–8 phần tử mỗi lệnh. Một `continue` theo dữ liệu, một lời gọi không
  nội tuyến, hay hai con trỏ có thể chồng lấn là đủ để trình dịch giữ vòng lặp vô hướng.
- **Kiểm:** báo cáo vector hoá (SV-02); asm (HN-15).

```cpp
// ✓ Thân thẳng, chọn bằng min, giới hạn là dữ liệu liền: Clang 20 -O2, GCC 14/15 -O3 vector hoá.
#include "core/check.hpp"

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <span>

namespace game::sim {

// Vận tốc và trần tốc độ của từng thực thể, tính theo đơn vị toạ độ mỗi giây; cả hai dài bằng pos.
struct Speeds {
    std::span<const float> vel;
    std::span<const float> limit;
};

inline void advance(std::span<float> pos, Speeds speeds, std::chrono::duration<float> dt) noexcept {
    const bool is_same_length = speeds.vel.size() == pos.size() && speeds.limit.size() == pos.size();
    core::check(is_same_length, "advance: vel, limit phải dài bằng pos");
    const float seconds = dt.count();
    for (std::size_t i = 0; i < pos.size(); ++i) {
        pos[i] += std::min(speeds.vel[i], speeds.limit[i]) * seconds;
    }
}

} // namespace game::sim
```

### SV-02 [N] PHẢI — Vòng lặp nóng có báo cáo vector hoá của cả GCC và Clang trong review

- **Vì sao:** vector hoá là quyết định ngầm của trình dịch, đổi theo phiên bản và cờ; báo cáo nói
  rõ lý do bỏ qua (alias, gọi hàm, kiểu dữ liệu, mô hình chi phí). Lưu ý: GCC báo "loop vectorized"
  cho cộng dồn `float` dạng "in-order reduction" — asm vẫn là chuỗi `addss` nối tiếp (đã kiểm
  GCC 14 -O3), nên báo cáo không thay được asm.
- **Kiểm:** các cờ dưới cho TU chứa vòng lặp nóng.

```bash
# GCC: đã vector hoá / bỏ qua kèm lý do.
g++ -std=c++23 -O3 -march=x86-64-v2 -fopt-info-vec-optimized -fopt-info-vec-missed -c move.cpp
# Clang: remark theo vòng lặp; -fsave-optimization-record ghi YAML cho công cụ.
clang++ -std=c++23 -O2 -Rpass=loop-vectorize -Rpass-missed=loop-vectorize \
    -Rpass-analysis=loop-vectorize -c move.cpp
```

### SV-03 [N] PHẢI — So sánh số thực bằng dung sai hợp với độ lớn; `==` chỉ cho giá trị được gán chính xác

Kết quả tính toán so bằng dung sai tuyệt đối gần 0 và tương đối khi lớn: `|a - b| <= max(abs_tol,
rel_tol * max(|a|, |b|))`. `==` chỉ cho giá trị gán thẳng (0, hằng, giá trị chép) và so bit khi
replay — types.hpp tách `==` chính xác khỏi `near`; gốc của nó so `==` bằng FLT_EPSILON tuyệt đối.

- **Vì sao:** mỗi phép toán làm tròn tới nửa ulp; hai cách tính tương đương về toán khác nhau vài ulp.
  Dung sai tuyệt đối cố định vô nghĩa với số lớn (ở 10⁶, khoảng cách hai float liền nhau là 0,0625)
  và quá lỏng gần 0. NaN làm mọi phép so sai — kể cả so với chính nó.
- **Kiểm:** clang-tidy không bắt `==` float; GCC/Clang `-Wfloat-equal` (bật cục bộ khi review).

```cpp
// ✓ Dung sai kết hợp; NaN cho false.
#include <algorithm>
#include <cmath>

namespace game::math {

struct Tolerance {
    float absolute = 1e-6F;
    float relative = 1e-5F;
};

[[nodiscard]] inline bool nearly_equal(float lhs, float rhs, Tolerance tol) noexcept {
    const float scale = std::max(std::abs(lhs), std::abs(rhs));
    return std::abs(lhs - rhs) <= std::max(tol.absolute, tol.relative * scale);
}

} // namespace game::math
```

### SV-04 [N] PHẢI — Số thực từ client hay từ dữ liệu ngoài được kiểm hữu hạn và trong miền trước khi vào mô phỏng; chuyển sang số nguyên chỉ sau khi kẹp

Viết điều kiện chấp nhận ở dạng dương `x >= lo && x <= hi` (NaN cho sai → bị loại), không viết dạng
loại trừ `x < lo || x > hi` (NaN cho sai → lọt qua). Chuyển float → int (chỉ số ô AOI) chỉ khi giá trị
đã hữu hạn và nằm trong miền của kiểu đích.

- **Vì sao:** một toạ độ NaN lọt vào làm hỏng lưới AOI, khoảng cách, va chạm của cả zone và lan qua
  snapshot tới mọi client. Chuyển float ngoài miền (kể cả NaN, vô cùng) sang số nguyên là UB
  ([conv.fpint], UB-05); x86 trả 0x80000000 nhưng trình dịch được giả định không xảy ra. Đã kiểm:
  UBSan của Clang 20 bắt ca này trong `-fsanitize=undefined`; GCC 14 thì KHÔNG — phải thêm
  `-fsanitize=float-cast-overflow` (UB-07).
- **Kiểm:** fuzz bộ giải mã gói (KT-11) với NaN, ±inf, số không chuẩn; UBSan như trên.

```cpp
// ✗ NaN làm cả hai phép so sai nên lọt qua; static_cast sau đó là UB.
#include <cstdint>

namespace game::net {

inline std::int32_t cell_of(float pos_x, float world_size) {
    if (pos_x < 0.0F || pos_x > world_size) return -1;
    return static_cast<std::int32_t>(pos_x / 64.0F);
}

} // namespace game::net
```

```cpp
// ✓ Điều kiện chấp nhận dạng dương: NaN và vô cùng bị loại trước khi chuyển kiểu.
#include <cstdint>
#include <optional>

namespace game::net {

inline constexpr float kCellSize = 64.0F;

// world_size hữu hạn, dương và nhỏ hơn 2^31 * kCellSize.
[[nodiscard]] inline std::optional<std::int32_t> cell_of(float pos_x, float world_size) noexcept {
    const bool inside = pos_x >= 0.0F && pos_x <= world_size;
    if (!inside) return std::nullopt;
    return static_cast<std::int32_t>(pos_x * (1.0F / kCellSize));
}

} // namespace game::net
```

### SV-05 [N] PHẢI — `float` cho dữ liệu mô phỏng khối lớn, hằng có hậu tố `F`; `double` hoặc toạ độ cục bộ khi độ lớn vượt độ chính xác cần

`float` có 24 bit định trị: khoảng cách hai giá trị liền nhau ở 16 384 là ~2 mm, ở 65 536 là ~8 mm.
Bước di chuyển nhỏ hơn nửa khoảng cách đó cộng vào toạ độ lớn bị nuốt mất. Toạ độ thế giới lớn:
lưu vị trí có thẩm quyền bằng `double` (hoặc fixed-point — SV-14) và tính SIMD theo `float` trong hệ
toạ độ cục bộ của zone/ô. Tiền tệ không bao giờ là số thực (MMO).

- **Vì sao:** `float` gấp đôi số làn SIMD và nửa băng thông so với `double`. Hằng thiếu `F` kéo cả
  biểu thức lên `double`: đã kiểm asm GCC 14/Clang 20, `x * 0.98` (x là float) thành `cvtss2sd` +
  `mulsd` + `cvtsd2ss` và kết quả khác `x * 0.98F`.
- **Kiểm:** `-Wdouble-promotion`, `-Wfloat-conversion` (trong -Wconversion) — đã có trong bộ cảnh
  báo dự án (BD-02).

```cpp
// ✓ Vị trí có thẩm quyền là double; vòng lặp SIMD làm việc trên float cục bộ quanh gốc zone.
namespace game::world {

struct ZoneFrame {
    double origin_x = 0.0;
    double origin_y = 0.0;
};

// Kết quả chính xác tới ~1 mm khi |world_x - origin_x| < 8 km.
[[nodiscard]] inline float to_local_x(const ZoneFrame& frame, double world_x) noexcept {
    return static_cast<float>(world_x - frame.origin_x);
}

} // namespace game::world
```

### SV-06 [N] CẤM — `-ffast-math`, `-Ofast` hay `-ffinite-math-only` ở cấp dự án hoặc TU có kiểm NaN

Cờ số thực của dự án: không fast-math; `-fno-math-errno` an toàn (HN-12); code tất định thêm
`-ffp-contract=off` (SV-11). Một hàm cần nới thì viết tay phép biến đổi (đổi thứ tự cộng, nhân nghịch
đảo) trong code, kèm số đo và test.

- **Vì sao:** fast-math gồm `-ffinite-math-only`: trình dịch coi NaN/vô cùng không tồn tại — đã kiểm,
  GCC 14 và Clang 20 biên dịch `std::isnan(x)` thành `return false`, xoá luôn phép kiểm đầu vào của
  SV-04. `-fassociative-math` đổi thứ tự cộng giữa các build (mất tất định) và xoá phần bù của tổng
  Kahan/Neumaier (đã kiểm GCC 14: các phép trừ bù biến mất — SV-13). GCC còn liên kết
  `crtfastmath.o` khi link với `-ffast-math`, bật FTZ/DAZ cho cả tiến trình.
- **Kiểm:** CI kiểm `compile_commands.json` không chứa các cờ trên.

```cmake
# Cờ số thực của dự án (cờ cảnh báo: BD; cờ hiệu năng: HN-12).
target_compile_options(game_core PRIVATE -fno-math-errno)
# Lõi mô phỏng tất định (lockstep/replay):
target_compile_options(game_sim PRIVATE -fno-math-errno -ffp-contract=off)
```

## 2. Nâng cao [C]

### SV-07 [C] PHẢI — Intrinsic chỉ nằm trong tầng SIMD (math/simd.hpp, math/vector*.hpp); kiểu bọc mới theo đúng phong cách vector.hpp/vector_int.hpp

Code gameplay dùng `Vector4`, `Vector4i`, `SoaFloat3`… không gọi `_mm_*`. Kiểu bọc mới (vd. 8 làn
AVX2): lớp giữ thanh ghi ở thành viên private `value_` khởi tạo 0; constructor từ thanh ghi là
`explicit`; truy cập thô qua `simd()`; phép toán là hàm tự do `inline`; phép so trả MẶT NẠ qua hàm có
tên (`less`, `equal`), không nạp chồng `operator<`; `static_assert` cỡ và căn lề. `std::simd` là
C++26; `<experimental/simd>` (Parallelism TS 2) đầy đủ ở libstdc++, còn libc++ 20 chỉ có một phần
và phải bật `-fexperimental-library` (đã thử: thiếu cờ thì không có namespace `std::experimental`).

- **Vì sao:** intrinsic rải rác khoá gameplay vào một ISA; một tầng bọc là chỗ duy nhất cần test sai
  phân (KT-15) và duy nhất phải đổi khi thêm AVX2/NEON. `operator<` trả mặt nạ đọc như phép so
  thường nhưng `if (a < b)` không biên dịch hoặc sai nghĩa (soa.hpp ghi lý do này; API-09).
- **Kiểm:** clang-tidy `portability-simd-intrinsics` đã tắt có lý do trong config — review bảo đảm
  intrinsic chỉ ở math/; `static_assert` trong mỗi kiểu bọc.

```cpp
// ✓ [x86] 8 làn AVX2 theo phong cách Vector4/Vector4i: explicit, simd(), hàm tự do, mặt nạ.
#include <immintrin.h>

namespace game::math {

class Float8 {
public:
    Float8() noexcept = default;
    explicit Float8(float scalar) noexcept : value_(_mm256_set1_ps(scalar)) {}
    explicit Float8(__m256 value) noexcept : value_(value) {}

    [[nodiscard]] __m256 simd() const noexcept { return value_; }

private:
    __m256 value_ = _mm256_setzero_ps();
};

// Làn "đúng" là toàn bit 1, làn "sai" là 0 — như Vector4i.
class Mask8 {
public:
    explicit Mask8(__m256 bits) noexcept : bits_(bits) {}

    [[nodiscard]] __m256 simd() const noexcept { return bits_; }

private:
    __m256 bits_;
};

static_assert(sizeof(Float8) == 32 && alignof(Float8) == 32);

// Làn có NaN cho sai.
[[nodiscard]] inline Mask8 less(const Float8& lhs, const Float8& rhs) noexcept {
    return Mask8(_mm256_cmp_ps(lhs.simd(), rhs.simd(), _CMP_LT_OQ));
}

} // namespace game::math
```

### SV-08 [C] PHẢI — Rẽ nhánh theo làn bằng mặt nạ toàn bit và chọn (and/andnot/or hoặc blend); hỏi "có làn nào" bằng `movemask`

Phép so SIMD cho mặt nạ: làn đúng toàn bit 1, làn sai 0 (`less`, `greater` của vector.hpp). Chọn
theo mặt nạ như `select_mask`; gom mặt nạ về số nguyên bằng `_mm_movemask_ps` (như `move_mask`,
`all_true` của vector_int.hpp) khi cần một quyết định vô hướng cho cả nhóm.

- **Vì sao:** không có nhánh theo làn trong SIMD; tính cả hai phía rồi chọn rẻ hơn tách vô hướng.
  `blendv` chỉ đọc bit dấu của làn, còn and/andnot/or đọc mọi bit: mặt nạ tự dựng (vd. từ `bool`)
  phải là toàn bit như `Vector4i::mask(bool)`. NaN: mọi phép so có thứ tự cho sai; `minps(a, b)` trả
  `b` khi một trong hai là NaN — thứ tự đối số quyết định NaN có lọt qua không (detail::lesser của
  types.hpp giữ đúng quy ước này).
- **Kiểm:** test sai phân với bản vô hướng, có NaN, ±0, ±inf trong đầu vào (KT-15).

```cpp
// ✓ [x86] Kẹp tốc độ 4 thực thể không nhánh; any_over gom mặt nạ thành một bool cho cả nhóm.
#include <xmmintrin.h>

namespace game::sim {

[[nodiscard]] inline __m128 clamp_speed(__m128 speed, __m128 max_speed) noexcept {
    // toàn bit 1 ở làn vượt
    const __m128 over = _mm_cmpgt_ps(speed, max_speed);
    return _mm_or_ps(_mm_and_ps(over, max_speed), _mm_andnot_ps(over, speed));
}

[[nodiscard]] inline bool any_over(__m128 speed, __m128 max_speed) noexcept {
    return _mm_movemask_ps(_mm_cmpgt_ps(speed, max_speed)) != 0;
}

} // namespace game::sim
```

### SV-09 [C] PHẢI — Nạp/lưu kiểu lưu trữ và buffer bằng `loadu`/`storeu`; không ép con trỏ thành `__m128*`

Float4, mảng `float`, vùng của buffer gói tin không bảo đảm căn 16: `_mm_loadu_ps`/`_mm_storeu_ps`,
như `load(Float4)`/`store(Vector4)` của vector.hpp. `_mm_load_ps` chỉ cho dữ liệu có kiểu căn lề
(`alignas` — BN-08).

- **Vì sao:** `*reinterpret_cast<const __m128*>(p)` sinh `movaps`, lỗi bảo vệ (SIGSEGV) khi `p` không
  căn 16, và là UB về căn lề ngay cả khi tình cờ chạy. Từ Nehalem/Bulldozer, `movups` trên địa chỉ đã
  căn tốn như `movaps`; phạt chỉ khi vắt qua dòng cache (nặng hơn khi vắt qua trang).
- **Kiểm:** clang-tidy `cppcoreguidelines-pro-type-reinterpret-cast`; `-Wcast-align`; UBSan
  `alignment` (có trong `-fsanitize=undefined`).

```cpp
// ✓ [x86] Nạp không giả định căn lề, như load(Float4) của vector.hpp.
#include <span>

#include <xmmintrin.h>

namespace game::math {

[[nodiscard]] inline __m128 load4(std::span<const float, 4> source) noexcept {
    return _mm_loadu_ps(source.data());
}

inline void store4(__m128 value, std::span<float, 4> target) noexcept {
    _mm_storeu_ps(target.data(), value);
}

} // namespace game::math
```

### SV-10 [C] PHẢI — Bản phân phối có baseline x86-64-v2; đường AVX2/FMA viết trong hàm `[[gnu::target]]` và chọn một lần lúc khởi động bằng `__builtin_cpu_supports`

Baseline v2 (SSE4.2, POPCNT — vector_int.hpp cần SSE4.1). Đường nhanh: hàm
`[[gnu::target("avx2,fma")]]` trong cùng TU, con trỏ hàm chọn một lần lúc khởi động. Không biên dịch một TU riêng bằng `-mavx2` rồi
include header có hàm `inline` dùng chung. `__builtin_cpu_supports` gọi trước constructor tĩnh (vd.
trong resolver ifunc) cần `__builtin_cpu_init()` trước. Dispatch tự động bằng `target_clones`: HN-14.

- **Vì sao:** hàm `inline` (template, hàm header, cả `Vector4::operator+`) biên dịch trong TU `-mavx2`
  mang mã AVX2; trình liên kết giữ MỘT bản cho cả chương trình (ODR) — có thể là bản AVX2, và máy
  không AVX2 chết SIGILL ở chỗ không liên quan. `target` giới hạn mã AVX2 trong đúng hàm đó.
- **Kiểm:** CI chạy test trên máy/giả lập không AVX2 (Intel SDE); `objdump -d` tìm thanh ghi `ymm`
  ngoài hàm đã đánh dấu.

```cpp
// ✓ Biên dịch ở baseline; mã AVX2 chỉ nằm trong scale_avx2.
#include <cstddef>
#include <span>

#include <immintrin.h>

namespace game::sim {

using ScaleFn = void (*)(std::span<float>, float) noexcept;

inline void scale_base(std::span<float> values, float factor) noexcept {
    for (float& value : values) {
        value *= factor;
    }
}

[[gnu::target("avx2,fma")]] inline void scale_avx2(std::span<float> values, float factor) noexcept {
    const __m256 times = _mm256_set1_ps(factor);
    const std::size_t blocks = values.size() / 8;
    for (std::size_t block = 0; block < blocks; ++block) {
        const std::span<float> chunk = values.subspan(block * 8, 8);
        _mm256_storeu_ps(chunk.data(), _mm256_mul_ps(_mm256_loadu_ps(chunk.data()), times));
    }
    scale_base(values.subspan(blocks * 8), factor);
}

// Gọi một lần lúc khởi động hệ thống, cất con trỏ.
[[nodiscard]] inline ScaleFn pick_scale() noexcept {
    if (__builtin_cpu_supports("avx2") && __builtin_cpu_supports("fma")) return scale_avx2;
    return scale_base;
}

} // namespace game::sim
```

### SV-11 [C] PHẢI — Hợp nhất nhân-cộng (FMA) là quyết định trong code (`std::fma`), không phải của cờ; code tất định build với `-ffp-contract=off`

Đã kiểm với `-march=x86-64-v3`: GCC 14 mặc định `-ffp-contract=fast` (cả khi `-std=c++23`) hợp nhất
`a * b + c` thành `vfmadd` kể cả khi tích nằm ở câu lệnh trước; Clang 20 mặc định `on`, chỉ hợp
nhất trong cùng một biểu thức. `-ffp-contract=off` tắt cả hai. Muốn FMA thì gọi `std::fma`: luôn làm
tròn một lần đúng chuẩn — có FMA phần cứng thành `vfmadd`, không có (v2) thì gọi `fmaf` mềm (đã kiểm),
kết quả giống hệt nhau.

- **Vì sao:** FMA làm tròn một lần thay vì hai: kết quả khác bit so với nhân rồi cộng. Cùng mã nguồn
  build v2 và v3, hay GCC và Clang, hay trước/sau khi LTO/PGO đổi nội tuyến (HN-17), cho kết quả
  khác nhau → replay lệch, hash trạng thái lockstep lệch.
- **Kiểm:** test replay so hash giữa build v2 và v3 (KT-16); CI kiểm cờ `-ffp-contract=off` cho lõi
  tất định.

```cpp
// ✓ Hợp nhất có chủ đích, giống nhau trên mọi máy; phần còn lại build với -ffp-contract=off.
#include <cmath>

namespace game::math {

// origin + weight * (target - origin), làm tròn một lần ở bước nhân-cộng.
[[nodiscard]] inline float lerp_fused(float origin, float target, float weight) noexcept {
    return std::fma(weight, target - origin, origin);
}

} // namespace game::math
```

### SV-12 [C] PHẢI — Không để giá trị trôi vào vùng số không chuẩn trên đường nóng: kẹp về 0, hoặc bật FTZ/DAZ có chủ đích cho luồng mô phỏng

Giá trị tắt dần (vận tốc, ngưỡng aggro, hiệu ứng mờ) kẹp về 0 dưới một ngưỡng nghiệp vụ. FTZ (bit 15)
và DAZ (bit 6) của MXCSR đặt ở đầu hàm luồng mô phỏng nếu chọn cách đó — MXCSR là của từng luồng, và
mọi máy tham gia tất định phải cùng thiết lập (SV-14).

- **Vì sao:** trên nhiều x86, phép toán nhận hoặc sinh số không chuẩn đi qua vi mã hỗ trợ, chậm cỡ
  hàng chục đến hàng trăm chu kỳ. Đã tính: `v *= 0.98F` mỗi tick từ 1,0 thành số không chuẩn sau
  4 324 tick (≈ 3,6 phút ở 20 Hz) rồi KHÔNG BAO GIỜ về 0 — kẹt ở 25 × 2⁻¹⁴⁹ ≈ 3,5e-44 vì `0,98 × v`
  làm tròn lại về chính `v`: mọi NPC đứng yên nhân trên số không chuẩn mãi mãi.
- **Kiểm:** test đơn vị: chạy `damp` 10 000 lần phải ra 0; `std::fpclassify(v) != FP_SUBNORMAL`.

```cpp
// ✓ [x86] Kẹp về 0 dưới ngưỡng; tuỳ chọn FTZ/DAZ cho luồng mô phỏng.
#include <cmath>
#include <cstdint>

#include <xmmintrin.h>

namespace game::sim {

// m/s: dưới mức này coi là đứng yên
inline constexpr float kRestSpeed = 1e-4F;

[[nodiscard]] inline float damp(float speed) noexcept {
    const float next = speed * 0.98F;
    return std::abs(next) < kRestSpeed ? 0.0F : next;
}

// Gọi đầu hàm của luồng mô phỏng; đổi kết quả số học nên phải giống nhau trên mọi máy lockstep.
inline void enable_flush_to_zero() noexcept {
    constexpr std::uint32_t kFlushToZero = 0x8000U;
    constexpr std::uint32_t kDenormalsAreZero = 0x0040U;
    _mm_setcsr(_mm_getcsr() | kFlushToZero | kDenormalsAreZero);
}

} // namespace game::sim
```

### SV-13 [C] NÊN — Tổng dài của nhiều số hạng nhỏ dùng tổng bù Neumaier (hoặc `double` + thứ tự cố định)

Quãng đường cộng dồn mỗi tick để chống hack tốc độ, thống kê sát thương cả trận, tích phân năng
lượng: tổng thô mất dần số hạng nhỏ khi tổng lớn. Neumaier (Kahan cải tiến) giữ phần bị làm tròn
trong một biến bù.

- **Vì sao:** cộng 0,05 m mỗi tick vào tổng `float` cỡ 10⁵ m thì bước bị làm tròn mạnh (khoảng cách
  float ở đó là ~8 mm) — sai số tích luỹ thành báo động giả hoặc bỏ sót gian lận. Phần bù chỉ sống
  được khi trình dịch không đổi thứ tự phép cộng: `-ffast-math` xoá nó (SV-06).
- **Kiểm:** test với chuỗi có tổng biết trước (1e8 lần 0,05); so với tổng `long double`/bản chính xác.

```cpp
// ✓ Tổng Neumaier: bù phần bị mất của số hạng nhỏ hơn ở mỗi bước.
#include <cmath>

namespace game::math {

class CompensatedSum {
public:
    void add(double value) noexcept {
        const double total = sum_ + value;
        const bool sum_bigger = std::abs(sum_) >= std::abs(value);
        compensation_ += sum_bigger ? (sum_ - total) + value : (value - total) + sum_;
        sum_ = total;
    }

    [[nodiscard]] double value() const noexcept { return sum_ + compensation_; }

private:
    double sum_ = 0.0;
    double compensation_ = 0.0;
};

} // namespace game::math
```

## 3. Thần thoại [T]

### SV-14 [T] PHẢI — Mô phỏng lockstep/replay tất định giữa các máy: fixed-point hoặc kiểm soát trọn chuỗi số thực

Lựa chọn an toàn nhất: trạng thái có thẩm quyền bằng fixed-point số nguyên. Nếu giữ số thực: cùng
binary hoặc cùng trình dịch + cờ; `-ffp-contract=off`, không fast-math; SSE2+, không `long double`
(x87 — mặc định ở 32 bit, và là `long double` của x86-64); cùng MXCSR (làm tròn, FTZ/DAZ — SV-12);
không `sin`/`cos`/`exp`/`pow` của libm (khác giữa glibc, MSVC CRT, các phiên bản — tự viết đa thức
với thứ tự tính cố định); không `rcp`/`rsqrt` ước lượng (SV-16); không `std::reduce`/thuật toán
song song (STD-11); không duyệt `unordered_*` (STD-15); phân phối `<random>` tự viết (STD-14).
Nguyên tắc chung: HP-15.

- **Vì sao:** IEEE 754 bắt buộc làm tròn đúng cho các phép cơ bản (+ − × ÷ √, fma, chuyển đổi), còn
  hàm siêu việt chỉ là khuyến nghị; mọi thứ còn lại (hàm của libm, hợp nhất, thứ tự cộng, xử lý số
  không chuẩn) là chỗ hai máy lệch nhau một ulp — và lockstep khuếch đại một ulp thành lệch trạng
  thái. Số nguyên thì C++20 đã cố định bù hai và dịch phải số học cho số có dấu: kết quả giống nhau
  trên mọi trình dịch.
- **Kiểm:** replay test so hash trạng thái giữa GCC/Clang, v2/v3, Linux/Windows (KT-16).

```cpp
// ✓ Q16.16: nhân qua 64 bit, dịch phải số học (C++20 định nghĩa) — tất định trên mọi trình dịch.
#include <cstdint>

namespace game::sim {

struct Fixed {
    // giá trị = raw / 65536
    std::int32_t raw = 0;
};

// Làm tròn về âm vô cùng; tích vượt miền Q16.16 thì quấn (chuyển đổi modulo, C++20).
[[nodiscard]] constexpr Fixed mul(Fixed lhs, Fixed rhs) noexcept {
    const std::int64_t wide = std::int64_t{lhs.raw} * std::int64_t{rhs.raw};
    return Fixed{static_cast<std::int32_t>(wide >> 16)};
}

// 3 × 0,5 = 1,5
static_assert(mul(Fixed{3 << 16}, Fixed{1 << 15}).raw == 3 << 15);
// −3 × 0,5 = −1,5
static_assert(mul(Fixed{-(3 << 16)}, Fixed{1 << 15}).raw == -(3 << 15));

} // namespace game::sim
```

### SV-15 [T] NÊN — Kiểm sai số đúng nghĩa bằng khoảng cách ulp khi so bản SIMD/ước lượng với bản chính xác

Ánh xạ mẫu bit float sang số nguyên đơn điệu (âm lật thứ tự), hiệu hai số nguyên là số giá trị float
nằm giữa. ±0 cách nhau 0 ulp; đầu vào NaN bị loại trước. Dùng trong test sai phân (KT-15): "rsqrt_nr
lệch ≤ N ulp so với `1 / std::sqrt`".

- **Vì sao:** dung sai tương đối không tách được "lệch 1 ulp do làm tròn" với "sai thuật toán" ở mọi
  độ lớn, và hỏng ở vùng số không chuẩn; ulp là đơn vị tự nhiên của sai số làm tròn.
- **Kiểm:** `static_assert` các ca biên; test vét cạn trên một miền (KT-17).

```cpp
// ✓ Khoảng cách ulp giữa hai float không NaN; static_assert ca biên.
#include <bit>
#include <cstdint>

namespace game::math {

// Thứ tự số nguyên đơn điệu theo giá trị float; -0 và +0 cùng là 0.
[[nodiscard]] constexpr std::int64_t ordered_bits(float value) noexcept {
    const std::int64_t bits = std::bit_cast<std::int32_t>(value);
    return bits < 0 ? std::int64_t{-2'147'483'648} - bits : bits;
}

// Tiền điều kiện: lhs, rhs không phải NaN.
[[nodiscard]] constexpr std::uint64_t ulp_distance(float lhs, float rhs) noexcept {
    const std::int64_t diff = ordered_bits(lhs) - ordered_bits(rhs);
    return static_cast<std::uint64_t>(diff < 0 ? -diff : diff);
}

static_assert(ulp_distance(0.0F, -0.0F) == 0);
static_assert(ulp_distance(1.0F, std::bit_cast<float>(0x3F80'0001U)) == 1);
// qua số không chuẩn nhỏ nhất hai phía
static_assert(ulp_distance(-1e-45F, 1e-45F) == 2);

} // namespace game::math
```

### SV-16 [T] CÓ THỂ — Ước lượng `rcp`/`rsqrt` + một bước Newton–Raphson khi số đo cho thấy bộ chia/căn là nút thắt, và code không cần tất định

`RSQRTPS` cho 1/√x với sai số tương đối ≤ 1,5 × 2⁻¹² (12 bit); một bước Newton–Raphson
`y₁ = y₀ · (1,5 − 0,5 · x · y₀²)` nâng lên cỡ vài ulp — như `simd::rsqrt_nr` mà
`rsqrt_estimate` của vector.hpp gọi. Bản thô (`rsqrt_rough`, `recip_estimate`) chỉ
cho thứ hiển thị. Ca biên (đã chạy): x = 0 cho NaN (0 · ∞), x < 0 cho NaN, x = +∞ cho NaN (∞ · 0)
thay vì 0, x không chuẩn cho −∞ vì RSQRTPS coi nó là 0.

- **Vì sao:** trên lõi hiện đại `sqrtps`/`divps` đã nhanh về độ trễ; lợi ích của ước lượng nằm ở
  thông lượng khi vòng lặp bị giới hạn bởi bộ chia — phải đo. Kết quả `RCPPS`/`RSQRTPS` khác nhau giữa
  Intel và AMD (bảng tra khác nhau), nên CẤM trong code tất định (SV-14). vector.hpp đã đưa ước lượng
  ra khỏi `normalize`/`recip` mặc định (mục "Khác gốc"): mặc định phải chính xác.
- **Kiểm:** test sai phân bằng ulp (SV-15) với `1 / std::sqrt`; test riêng x = 0, số không chuẩn, ∞.

```cpp
// ✓ [x86] rsqrt 12 bit + một bước Newton–Raphson (rsqrt_nr); x = 0, âm, +∞ cho NaN.
#include <xmmintrin.h>

namespace game::math {

[[nodiscard]] inline __m128 rsqrt_nr(__m128 value) noexcept {
    const __m128 estimate = _mm_rsqrt_ps(value);
    const __m128 half_value = _mm_mul_ps(_mm_set1_ps(0.5F), value);
    const __m128 square = _mm_mul_ps(estimate, estimate);
    const __m128 correction = _mm_sub_ps(_mm_set1_ps(1.5F), _mm_mul_ps(half_value, square));
    return _mm_mul_ps(estimate, correction);
}

} // namespace game::math
```

### SV-17 [T] NÊN — Nhánh phụ thuộc dữ liệu khó đoán thì dùng chọn không nhánh (cmov/mặt nạ), và kiểm asm vì trình dịch có thể đổi ngược

Nhánh đoán đúng (một chiều áp đảo) rẻ hơn cmov: cmov biến điều kiện thành phụ thuộc dữ liệu trên
chuỗi tới hạn. Nhánh ~50/50 theo dữ liệu (tìm kiếm nhị phân, so khoảng cách AOI với ngưỡng) thì đoán
sai ~một nửa, mỗi lần mất cỡ 15–20 chu kỳ: dùng chọn không nhánh. Đã kiểm asm -O2: GCC 14/15 giữ
`cmov` cho tìm kiếm nhị phân viết bằng `?:`; Clang 20 đổi nó thành nhánh (pass
`x86-cmov-conversion`), kể cả khi viết `base += (a[i] < key) * half`; chỉ `__builtin_unpredictable`
(Clang; GCC 14/15 không có) giữ `cmov` — mẫu dưới cho `cmov` ở cả ba; bọc thành `__builtin_unpredictable(…) != 0` là mất gợi ý.
`__builtin_expect_with_probability(c, 1, 0.5)` cũng không giữ.

- **Vì sao:** "không nhánh" ở mã nguồn không bảo đảm không nhánh ở asm, và ngược lại; chỉ asm và
  `perf stat -e branch-misses` trên dữ liệu thật trả lời được. Giữ bản có nhánh làm chuẩn trong test.
- **Kiểm:** asm (HN-15); benchmark với dữ liệu ngẫu nhiên và dữ liệu đã sắp.

```cpp
// ✓ lower_bound không nhánh; __builtin_unpredictable giữ cmov trên Clang, GCC tự giữ.
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::world {

[[nodiscard]] inline std::size_t lower_index(std::span<const std::int32_t> sorted, std::int32_t key) noexcept {
    if (sorted.empty()) return 0;
    std::size_t base = 0;
    std::size_t length = sorted.size();
    while (length > 1) {
        const std::size_t half = length / 2;
#if __has_builtin(__builtin_unpredictable)
        // Kết quả dùng thẳng làm điều kiện của `?:`: so `!= 0` thì Clang mất gợi ý (SV-17).
        // NOLINTNEXTLINE(readability-implicit-bool-conversion)
        base = __builtin_unpredictable(sorted[base + half] < key) ? base + half : base;
#else
        base = sorted[base + half] < key ? base + half : base;
#endif
        length -= half;
    }
    return base + (sorted[base] < key ? 1U : 0U);
}

} // namespace game::world
```

### SV-18 [T] PHẢI — Phép cộng dồn số thực nóng dùng nhiều bộ cộng dồn độc lập (SIMD tường minh), thứ tự cố định

Một biến tổng là một chuỗi phụ thuộc: mỗi phép cộng chờ phép trước (độ trễ cỡ 3–4 chu kỳ) trong khi
lõi phát được hai phép cộng mỗi chu kỳ — cần ~8 phép đang bay. Thiếu fast-math, trình dịch không
được đổi thứ tự cộng `float` nên tự nó không tách được (đã kiểm: GCC 14 -O3, Clang 20 -O3 giữ chuỗi
`addss`; tổng `int` thì vector hoá bình thường). Viết tay 4–8 bộ cộng dồn × 8 làn (mẫu dưới dùng 4:
một nửa đỉnh khi dữ liệu nằm trong L1; dữ liệu lớn hơn thường chạm băng thông trước — đo); thứ tự
gộp cố định nên kết quả vẫn tất định (nhưng khác tổng tuần tự — đổi thì cập nhật golden test).

- **Vì sao:** cùng số phép cộng, nhanh hơn nhiều lần chỉ nhờ phá chuỗi phụ thuộc; không cần
  `-ffast-math` (SV-06).
- **Kiểm:** benchmark; test so với tổng `double` trong dung sai (SV-03).

```cpp
// ✓ [x86] 4 bộ cộng dồn AVX2 (32 làn đang bay); gộp theo thứ tự cố định; phần dư cộng tuần tự.
#include <algorithm>
#include <array>
#include <cstddef>
#include <functional>
#include <span>

#include <immintrin.h>

namespace game::math {

[[nodiscard]] inline float sum_fast(std::span<const float> values) noexcept {
    // Bốn biến riêng: std::array<__m256, 4> bị GCC cảnh báo -Wignored-attributes (mất căn lề).
    __m256 acc0 = _mm256_setzero_ps();
    __m256 acc1 = _mm256_setzero_ps();
    __m256 acc2 = _mm256_setzero_ps();
    __m256 acc3 = _mm256_setzero_ps();
    const std::size_t blocks = values.size() / 32;
    for (std::size_t block = 0; block < blocks; ++block) {
        const std::span<const float> chunk = values.subspan(block * 32, 32);
        acc0 = _mm256_add_ps(acc0, _mm256_loadu_ps(chunk.data()));
        acc1 = _mm256_add_ps(acc1, _mm256_loadu_ps(chunk.subspan(8).data()));
        acc2 = _mm256_add_ps(acc2, _mm256_loadu_ps(chunk.subspan(16).data()));
        acc3 = _mm256_add_ps(acc3, _mm256_loadu_ps(chunk.subspan(24).data()));
    }
    const __m256 total = _mm256_add_ps(_mm256_add_ps(acc0, acc1), _mm256_add_ps(acc2, acc3));
    std::array<float, 8> lanes{};
    _mm256_storeu_ps(lanes.data(), total);
    const float head = std::ranges::fold_left(lanes, 0.0F, std::plus<>{});
    return std::ranges::fold_left(values.subspan(blocks * 32), head, std::plus<>{});
}

} // namespace game::math
```

### SV-19 [T] PHẢI — Kiểm áp lực cổng thực thi trước khi tối ưu vi kiến trúc: shuffle ra khỏi vòng lặp nóng, không bật AVX-512 khi chưa đo tần số

Shuffle (`unpck`, `shufps`, `perm`) chạy ở ít cổng hơn phép cộng/nhân — trên nhiều đời Intel
(Skylake…) phần lớn chỉ ở một cổng, 1 lệnh/chu kỳ; đời mới và AMD Zen có nhiều đơn vị hơn. Đổi AoS ↔
SoA (`transpose4x4` của soa.hpp: 8 shuffle cho 4 vectơ) làm ở ranh giới, một lần, không trong vòng
lặp tick (BN-06). AVX-512 nặng trên Skylake-SP/Cascade Lake hạ xung cả lõi trong một khoảng thời gian,
làm chậm cả code vô hướng chạy cùng lõi (luồng mạng); đời sau giảm nhiều, Zen 4 không hạ — đo trên
đúng máy chủ; GCC/Clang có `-mprefer-vector-width=256`. Trộn lệnh VEX với SSE cũ (thư viện ngoài
biên dịch không VEX) cần `vzeroupper` — trình dịch tự chèn ở biên hàm dùng `ymm`.

- **Vì sao:** vòng lặp SIMD thường bị giới hạn bởi một cổng shuffle hay bộ chia, không phải số lệnh;
  `llvm-mca` chỉ ra cổng nghẽn. Hạ xung AVX-512 là chi phí ngoài vòng lặp, benchmark vi mô không thấy.
- **Kiểm:** các lệnh dưới; bảng độ trễ/cổng ở uops.info; benchmark đầu-cuối (tick) trên máy thật.

```bash
# Áp lực cổng của khối lặp (đánh dấu # LLVM-MCA-BEGIN/END trong .s); so hai đời CPU:
llvm-mca -mcpu=skylake -resource-pressure -bottleneck-analysis aoi_loop.s
llvm-mca -mcpu=znver4 -resource-pressure aoi_loop.s
# Tần số thực khi chạy tải (tuỳ quyền; turbostat thuộc linux-tools):
sudo turbostat --quiet --show Core,Bzy_MHz --interval 1 -- ./zone_server --replay peak.bin
```

### SV-20 [T] NÊN — Thay gather/scatter bằng sắp lại dữ liệu cho liền mạch; sắp theo khoá toàn phần để giữ tất định

`_mm256_i32gather_ps` tiện nhưng chậm trên nhiều đời CPU (vi mã trên AMD trước Zen 4; trên Intel
Skylake–Tiger Lake, bản vá vi mã Downfall/GDS 2023 làm gather chậm đi rõ rệt); scatter chỉ có từ
AVX-512 và có xung đột chỉ số. Tốt hơn: định kỳ sắp mảng thực thể theo ô AOI để thành viên một ô nằm
liền, vòng lặp SIMD đọc tuần tự. Khoá sắp phải là thứ tự toàn phần (ô, rồi id): `std::ranges::sort`
không ổn định, khoá trùng cho thứ tự khác nhau giữa libstdc++/libc++ → mất tất định.

- **Vì sao:** gather 8 làn là 8 lần nạp rải rác cộng phí vi mã; dữ liệu liền là một lần nạp. Sắp lại
  đổi chỉ số thực thể: ai giữ chỉ số phải qua handle (MMO).
- **Kiểm:** benchmark trước/sau với phân bố người chơi thật (cụm đông); replay so hash giữa hai thư
  viện chuẩn.

```cpp
// ✓ Sắp theo (ô, id): thứ tự toàn phần nên giống nhau trên mọi thư viện chuẩn.
#include <algorithm>
#include <cstdint>
#include <span>
#include <tuple>

namespace game::world {

struct Mover {
    std::uint32_t cell = 0;
    std::uint32_t id = 0;
    float pos_x = 0.0F;
    float pos_y = 0.0F;
};

inline void sort_by_cell(std::span<Mover> movers) noexcept {
    const auto cell_then_id = [](const Mover& mover) { return std::tie(mover.cell, mover.id); };
    std::ranges::sort(movers, {}, cell_then_id);
}

} // namespace game::world
```

## Kiểm nhanh

- [ ] Vòng lặp nóng có báo cáo vector hoá GCC + Clang, thân không `continue`/lời gọi mờ? (SV-01, SV-02)
- [ ] So float bằng dung sai; NaN từ client bị loại bằng điều kiện dương trước khi đổi sang int? (SV-03, SV-04)
- [ ] Hằng float có hậu tố `F`; toạ độ lớn không cộng bước nhỏ vào `float`? (SV-05)
- [ ] Không `-ffast-math`/`-Ofast`; lõi tất định có `-ffp-contract=off`? (SV-06, SV-11)
- [ ] Intrinsic chỉ ở tầng math/; kiểu bọc mới đúng phong cách, so sánh trả mặt nạ? (SV-07, SV-08)
- [ ] Nạp kiểu lưu trữ bằng `loadu`; không ép `__m128*`? (SV-09)
- [ ] Mã AVX2 chỉ trong hàm `[[gnu::target]]`, chọn lúc khởi động; baseline x86-64-v2? (SV-10)
- [ ] Giá trị tắt dần được kẹp về 0, không trôi vào số không chuẩn? (SV-12)
- [ ] Code lockstep: fixed-point hoặc không libm siêu việt, không rsqrt/rcp ước lượng, không `std::reduce`? (SV-14, SV-16)
- [ ] Khẳng định "không nhánh"/"đã vector hoá" có asm; cộng dồn nóng dùng nhiều bộ cộng dồn? (SV-17, SV-18)
