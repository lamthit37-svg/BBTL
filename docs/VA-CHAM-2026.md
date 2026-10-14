# Mặt công trình (`.WCollision`) theo client 2026

Độ cao mặt cầu, bậc thang, sàn đài dưới chân nhân vật, và tia chuột trúng các mặt đó. Gốc là lớp
`BuildingCollision` của `PathLib.dll`; module port là `SRC/collision` (namespace `game::collision`).

Phần đã có mã, đối chiếu ngày 2026-10-13: bộ đọc tệp (`building_file.*`), lưới sau nạp (`mesh.*`),
cây OPCODE (`opcode_tree.*`) và phép biến đổi đỉnh (`transform.hpp`), đều ở
`game::collision::detail`; ngoài `detail` có `LoadError`, `describe`, hai hằng mã bản và API của mục
"API port C chốt" (`Model`, `load`, `height`, `raycast`, `bounds`, `Hit`, `Aabb`; `model.cpp`). Client
nạp `<cảnh>.WCollision` (`world::attach_buildings`) và nâng chân nhân vật bằng `Model::height`
(`surface_y` ở `display/graphic/play.cpp`); `building_height_tests` xanh. Chưa có: tia chuột trúng mặt
công trình trong client, và chưa nhìn thử tay mặt cầu, bậc thang. Đoạn này ngày 2026-10-08 ghi
"CHƯA có dòng mã nào"; mã đã đi trước tài liệu (cây được ghép lại sau vụ mất 2026-10-09). Hai tệp
`Test/Collision/collision_tests.cpp` và `collision_alloc_tests.cpp` mà `CMakeLists.txt` còn nhắc không có trên đĩa
(nợ của vụ mất): bản đọc tệp chưa có test canh, `ctest` chỉ có `building_height_tests` cho module này.

Mọi địa chỉ là của bản trong `F:\tl 2026\Bin64` (`PathLib.dll` và `Render.dll` base `0x180000000`,
`Game.exe` base `0x140000000`). Tìm lại bằng `python TOOLS/port/pe_refs.py <tệp> func <địa chỉ>`;
hàm bị tách khúc thì gọi tiếp với địa chỉ kế. Quy ước gọi Win64: `rcx` là `this`, tham số số thực
đi theo vị trí (`xmm1`, `xmm3`...).

Trạng thái: B1 (đọc mã máy `PathLib.dll`) do C soạn ngày 2026-10-08. Mục "Luật dùng ở Game.exe" (T8)
nộp riêng trước 16:00. Mục trọng tài, số đo khớp, số đo tốc độ điền sau B2–B4 (phiên phụ dừng trước
khi tới B2–B4: ba mục ấy không có trong tệp này; số đo tốc độ phía DLL gốc nằm ở
`docs/giao-viec/DH-DOT-1/KET-QUA.md`).
Đính chính 2026-10-08 (C) theo bản rà `so-do/r-va-cham-2026.md` của R: V-1 tới V-9, C-4, C-5 và byte thừa
(mục 5 của bản rà).

## Nguồn

- `PathLib.dll` xuất hai hàm tạo đối tượng:
  - `getBuildingCollsion` (0x18002dd30): cấp 0x60 byte, gọi hàm dựng 0x180001f20, vtable
    0x180043b78, RTTI `.?AVBuildingCollsionImpl@PathLib@@`. Trong tài liệu này gọi là **lớp `get`**.
  - `newBuildingWalkGeometry` (0x18002ddf0, hàm tĩnh): cấp 0x50 byte, gọi hàm dựng 0x180005c70,
    vtable 0x180043cf8, RTTI `.?AVBuildingWalkGeometry@PathLib@@`. Gọi là **lớp `new`**.
  - Hai hàm dựng giống nhau: `+8` (con trỏ mô hình OPCODE) = 0, vector đỉnh `+0x10..+0x20` rỗng, gọi
    0x180005620, `+0x28` (mảng chỉ số) = 0, dựng `MeshInterface` ở `+0x30` (0x180036f40).
- Giao diện `BuildingCollision` (vtable 0x180043b50): dtor 0x180002400 rồi ba ô ảo thuần
  (0x18003fede).
- Phần tỉa ứng viên là thư viện **OPCODE 1.3** (Pierre Terdiman), nhận ra qua chuỗi
  `SkipPrimitiveTests not possible for RayCollider` và bố cục `Model`, `RayCollider`,
  `AABBQuantizedNoLeafTree` trùng mã nguồn công khai của bản 1.3.
- `Render.dll`: `CBuildingCollision` (vtable 0x1802c02c0) bọc lớp `get`: hàm 0x18001d750 cấp 0x18
  byte rồi gọi `getBuildingCollsion` (log `so-do/a-b1-render-*.log` của A). Lớp `new` không có ai
  trong `Render.dll` gọi tới; phía `Game.exe` kiểm trong T8.

## Ba ô vtable

| ô | lớp `get` | lớp `new` | chữ ký (không tính `this`) |
|---|---|---|---|
| 0 | 0x180002480 | 0x180005d60 | dtor |
| 1 | 0x180004580 | 0x180006080 | `u8 load(const void* data, u32 size)` |
| 2 | 0x180004380 | 0x180004380 (chung) | `u8 height(float x, float* y, float z)` |
| 3 | 0x180003170 | 0x180005f10 | `u8 ray(const float origin[3], const float dir[3], float out[3])` |
| 4 | 0x180004a00 | không có | bộ đọc mã 2, chỉ ô 1 của lớp `get` gọi (`call [vtable+0x20]`) |

## Ô 1 `load` — nạp tệp

Chữ ký: `u8 load(const void* data, u32 size)` (`rcx`=this, `rdx`=con trỏ dữ liệu, `r8d`=cỡ).
`Render.dll` ô 1 (0x18001d990) chỉ chuyển tiếp xuống ô 1 của lớp `get`.

Trình tự (0x180004580): giải phóng mô hình cũ `[this+8]` (dtor ảo qua `[model][0]`), xoá mảng chỉ số
cũ `[this+0x28]`, xoá vector đỉnh `[this+0x10..0x20]`, rồi đọc theo mã bản ở 4 byte đầu tệp:

- 4 byte đầu là **số mã bản**. Nhánh rẽ duy nhất là `cmp dword [rsi], 0xFF000002` ở 0x1800045e7: bằng
  0xFF000002 thì gọi ô phụ `[vtable+0x20]` (0x180004a00, bộ đọc **mã 2**); **mọi giá trị khác** (0xFF000001
  và cả mã lạ) đọc tại chỗ ở 0x180004580 theo **mã 1**. Không có nhánh nào khác.
- **Mã 1** (0x180004580): sau số mã bản là số ô lưới, rồi với mỗi ô là số tam giác và danh sách tam
  giác; đỉnh gộp vào một vector đỉnh phẳng ở `[this+0x10]`, chỉ số 32-bit vào `[this+0x28]`. Số đếm đọc
  từ tệp là **i32** (số ô ở 0x180004603, số tam giác ở 0x180004680), không bị cắt. Lưu ý khớp bit:
  `movzx ..., word` (**cắt còn u16**) chỉ có trên **biến tổng** của nhánh mã 1 (tổng số tam giác ở
  0x18000481b, tổng số đỉnh ở 0x18000483d, ghi vào `MeshInterface` `+0x30`/`+0x38`); tổng > 65535 sẽ bị
  cắt vòng. Port phải tái hiện đúng (đánh dấu `Khác gốc:` nếu ta muốn mở rộng). `CountOverflow` (xem API)
  chỉ áp cho Model của mã 1.
- **Mã 2** (0x180004a00). Nhánh này ghi các tổng bằng 64 bit (0x1800052d7, 0x1800052fa), không cắt u16.
  Bố cục (little-endian; bản đặt đọc ở 0x180004b50..0x180004b7f):
  - u16 số khối; mỗi khối: u16 số đỉnh, đỉnh 3 f32 (x, y, z cục bộ của khối), u16 số tam giác, tam giác
    3 u16 (chỉ số đỉnh trong khối);
  - **khung** 6 f32 = (gốc x, gốc y, gốc z, tỉ lệ x, tỉ lệ y, tỉ lệ z), **đọc từ tệp, riêng từng tệp**
    (con trỏ trả về từ 0x180003d80, chép ở 0x180004afd..0x180004b15, dùng ở 0x180004dd7..0x180004df3).
    Không có khung cố định: 310 tệp mã 2 thật có **47 khung khác nhau**, không khung nào là −3200000
    (ví dụ −9600: 79 tệp, −12800: 53, −16000: 29, −6400: 27, −3200: 23, −25600: 18,
    (−25600, 0, −30000): 16…); cả 47 khung đều tỉ lệ 100. Bộ đọc của A đọc khung từ tệp (`detail::Frame`);
  - u16 số bản đặt; mỗi bản đặt **42 byte** = tỉ lệ x, y, z + vị trí x, y, z + quaternion w, x, y, z
    (10 f32) + u16 chỉ số khối. **S lấy từ tỉ lệ của bản đặt**, T từ vị trí, R từ quaternion.

  Mỗi đỉnh v = (vx, vy, vz) của khối được biến đổi theo từng bản đặt. Thứ tự phép f32 phải giữ đúng từng
  bit (SSE vô hướng `mulss`/`addss`/`subss`/`divss`, không FMA, không phép gói; lệnh chi tiết ở
  `so-do/b-bien-doi-thu-tu.md`):
  1. Ma trận 4×4 **hàng-chính, véc-tơ cột**. Bộ nạp gọi 0x180001f80 (ở 0x180004b92) để dựng R 4×4: chép
     ma trận đơn vị từ 0x180053830, gọi 0x180011670 ở 0x180001fa3 (quaternion → 3×3), đặt 3×3 vào góc
     trên; bộ nạp không gọi thẳng 0x180011670. T = đơn vị + vị trí ở cột 3; S = đơn vị + tỉ lệ bản đặt ở
     đường chéo.
  2. **M = (T·R)·S dựng trước** khi nhân đỉnh (nhân ma trận 0x1800032a0, gọi ở 0x180004c3f rồi
     0x180004c56), mỗi ô `((A_i0·B_0j + A_i1·B_1j) + A_i2·B_2j) + A_i3·B_3j`.
  3. `w = ((m31·vy + m30·vx) + m32·vz) + m33`; **`r = 1.0 / w`** (`divss`, 0x180004d45);
     `p_i = (((m_i1·vy + m_i0·vx) + m_i2·vz) + m_i3) · r` (`mulss`). Không "chia cho w": chia một lần ra r
     rồi nhân. `p` chỉ là kết quả trung gian, chưa phải toạ độ game.
  4. **Toạ độ game** `g_i = (p_i − gốc_i) / tỉ lệ_i` (gốc, tỉ lệ của khung): `subss` rồi **`divss` thật**
     (0x180004ddc, 0x180004de7, 0x180004df3), không nhân nghịch đảo. `g` là toạ độ đổ vào vector đỉnh,
     cùng hệ với `height`/`ray`.
  5. `Khác Dev:` Dev (`G:\TLBB\Dev\tools\bake\walk_source.cpp:234-240`) xoay bằng `quat_rotate` (tích chéo)
     lên đỉnh đã nhân tỉ lệ, không qua M; so với gốc lệch bit 9,3% ca (q tổng quát, tỉ lệ không đều) / 2,0%
     (q quanh trục y, tỉ lệ đều), lệch lớn nhất 1,22e-4 đơn vị game (mỗi bộ 20 000 ca, bản rà của R mục 3).

  Ghi chú: với đầu vào hữu hạn, hàng 3 của M là (0, 0, 0, 1) nên w = 1, r = 1, nhân r không đổi bit. Inf hay
  NaN trong q hoặc tỉ lệ cho 0·Inf = NaN ở hàng 3 → w = NaN → cả ba toạ độ NaN (xem mục NaN/Inf). Kết quả
  cũng đổ vào cùng vector đỉnh + mảng chỉ số như mã 1. Ca biên của bản đặt: mục "Bản đặt: ca biên".

**"Nạp được" vs "từ chối" (T1 cần):** bản gốc **luôn trả 1**, không có đường từ chối. Không kiểm
`size`, không kiểm số hữu hạn, không kiểm tỉ lệ khung. Tệp 8 byte (mã 1, 0 ô) hay 32 byte (mã 2, 0
lượt) vẫn "nạp được" nhưng cho ra 0 tam giác. **Không giữ con trỏ vào bộ đệm** sau khi nạp: toàn bộ
đỉnh/chỉ số đã chép sang vùng của đối tượng, nên bộ đệm tệp có thể giải phóng ngay.

Sau khi đọc xong đỉnh/chỉ số, `load` gọi `Model::Build` (OPCODE) để dựng cây tỉa (xem dưới).

## Bố cục đối tượng sau nạp (lớp `get`, 0x60 byte)

| offset | nghĩa |
|---|---|
| +0x00 | con trỏ vtable (0x180043b78) |
| +0x08 | con trỏ `Model` OPCODE (0 khi chưa dựng / 0 tam giác) |
| +0x10..+0x20 | vector đỉnh phẳng (begin/end/cap), mỗi đỉnh 3 float |
| +0x28 | mảng chỉ số 32-bit (3 chỉ số mỗi tam giác) |
| +0x30 | `MeshInterface` (0x180036f40) trỏ vào hai mảng trên |
| +0x50 | khoảng cách trúng gần nhất của lượt ray hiện thời (`FLT_MAX` khi bắt đầu) |
| +0x54..+0x5c | điểm trúng (x, y, z) của lượt ray hiện thời |

`+0x50..+0x5c` là **trạng thái tạm của một lượt ray**, bị ghi đè mỗi lần gọi. Bản gốc không an toàn
đa luồng ở điểm này; port phải giữ trạng thái này **cục bộ trong hàm truy vấn**, không để trong đối
tượng bất biến.

## Ô 2 `height` — độ cao mặt dưới chân (dùng chung hai lớp, 0x180004380)

Chữ ký: `u8 height(float x, float* y, float z)` (`rcx`=this, `xmm1`=x, `r8`=con trỏ y, `xmm3`=z).

Dựng một tia: **gốc = (x, 10000, z)**, **hướng = (0, −1, 0)** (hằng `10000.0` ở 0x180043c18, `−1.0` ở
0x180043c1c), rồi gọi ô 3 `ray`. Trúng → `*y = out.y`, trả 1. Trượt → trả 0, **không ghi vào `*y`**.
Không có cấu trúc tỉa riêng; toàn bộ tỉa nằm trong ô 3.

## Ô 3 `ray` — tia trúng mặt (lớp `get`: 0x180003170)

Chữ ký: `u8 ray(const float origin[3], const float dir[3], float out[3])` (`rcx`=this, `rdx`=origin,
`r8`=dir, `r9`=out).

- Véc-tơ thứ hai là **hướng**, không chuẩn hoá, không phải điểm cuối.
- Nhận trúng khi `t ≥ +0` (loại `−0`), khoảng tối đa `FLT_MAX`, **không loại mặt sau** (no backface
  cull).
- `out` nhận **điểm trúng** (x, y, z), tính bằng toạ độ trọng tâm trong callback 0x180002d20:
  `out = (u·V1 + v·V2) + ((1 − u) − v)·V0`. Thứ tự phép cộng đúng như vậy, không gộp lại.
- **Trả false (trượt) thì `out` không bị ghi.**
- Trạng thái lượt chạy: khoảng gần nhất ở `[this+0x50]` khởi tạo `FLT_MAX`, điểm trúng ở
  `[this+0x54..+0x5c]` (xem bố cục trên).

## Tỉa ứng viên — OPCODE 1.3

`load` gọi `Model::Build` (0x180037330):
- **0 tam giác → không dựng cây** (`[this+8]` giữ 0); mọi truy vấn sau đó đều trượt. Đây là lý do tệp
  rỗng (8/32 byte) hợp lệ nhưng luôn trả 0 — hộp truy vấn khi đó **không còn ý nghĩa**.
- **1 tam giác → cờ `OPC_SINGLE_NODE`** (bit 4 ở `+8` của RayCollider), test thẳng tam giác đó.
- **≥2 tam giác → dựng cây** qua 0x18003bfb0 với tham số `0x22`, `0x101` (`AABBQuantizedNoLeafTree`).

`RayCollider` (ctor 0x1800374e0): `best = FLT_MAX` (`0x7f7fffff` ở `+0xb8`), cờ hợp lệ `+0xbc = 1`.
`InitQuery` 0x1800379e0 đặt `eps = 1e-6` (0x180044500). `Collide` 0x180037840 chọn 1 trong 4 nhánh
duyệt (quantized/no-leaf × có/không `FLT_MAX`), rồi nếu bit 4 ở `+8` bật thì chép điểm trúng từ `+0x60`
ra `out`.

Duyệt quantized-no-leaf (0x1800391e0): bung hộp lượng tử, xét **con dương trước con âm**, biên nới
`±1e-6` (`−1e-6` ở 0x180046cf4). Hàm phụ: trừ vector 0x180037730, cộng 0x180037770, tích chéo
0x1800377b0; kiểm hợp lệ (4 con trỏ khác null) 0x180036fd0; đếm tam giác suy biến/trùng chỉ số
0x180036f60.

## Thứ tự phép toán số thực (phải giữ nguyên)

- Test tia–tam giác là **Möller–Trumbore** (OPCODE gốc): `edge1 = V1 − V0`, `edge2 = V2 − V0`,
  `pvec = dir × edge2`, `det = edge1 · pvec`; không loại mặt sau nên dùng `det` có dấu. `u`, `v`, `t`
  theo đúng thứ tự nhân/chia của OPCODE 1.3, biên so sánh nới `±1e-6`.
- Điểm trúng ghép lại bằng trọng tâm (công thức ở phần ô 3), **không** tái dựng từ `origin + t·dir`.
- Port dịch với `-ffp-contract=off`, giữ nguyên thứ tự cộng/nhân từng biểu thức, không đổi `a*b+c`
  thành FMA, không đảo thứ tự tổng.

## API port C chốt (để A gắn test)

```cpp
namespace game::collision {

// Giá trị thật ở SRC/collision/building_file.hpp (bộ đọc của A), theo thứ tự bộ đọc gặp. Mọi giá trị
// đều là Khác gốc: bản gốc luôn trả 1, không kiểm size, số thực hay chỉ số.
enum class [[nodiscard]] LoadError : std::uint8_t {
  kTooLarge,                 // tệp từ 1 GiB trở lên
  kTruncatedVersion,         // chưa đủ 4 byte mã bản
  kTruncatedCellCount, kCellsBeyondEnd, kTruncatedCell,
  kTrianglesBeyondEnd,       // mã 1: thiếu byte so với số đã khai
  kNonfiniteTriangle,        // mã 1: toạ độ tam giác NaN/vô cực (gốc vẫn dùng)
  kTruncatedBlockCount, kBlocksBeyondEnd, kTruncatedVertexCount, kVerticesBeyondEnd,
  kNonfiniteVertex,          // mã 2: toạ độ đỉnh NaN/vô cực (gốc vẫn dùng)
  kTruncatedFaceCount, kFacesBeyondEnd,
  kVertexOutOfBlock,         // mã 2: chỉ số đỉnh không nhỏ hơn số đỉnh của khối
  kTruncatedFrame,
  kNonfiniteFrame,           // mã 2: gốc/tỉ lệ khung NaN/vô cực (gốc vẫn dùng)
  kZeroFrameScale,           // mã 2: một tỉ lệ khung = 0 (gốc chia cho 0); âm, subnormal vẫn nhận
  kTruncatedPlacementCount, kPlacementsBeyondEnd,
  kNonfinitePlacement,       // mã 2: tỉ lệ/vị trí/quaternion bản đặt NaN/vô cực (gốc vẫn dùng)
  kBlockOutOfRange,          // mã 2: bản đặt trỏ khối không có
};
// Không có TrailingBytes: byte thừa sau phần đã khai bị bỏ qua như gốc (nạp được).
// CountOverflow (mã 1, tổng > 65535) và kiểm sau biến đổi (mục NaN/Inf) là việc của Model, chưa có
// giá trị trong building_file.hpp.

struct Hit { float x, y, z; };
struct Aabb { float min[3]; float max[3]; };  // tệp rỗng: min = +inf, max = -inf

class Model {                       // bất biến, tạo xong là chỉ đọc
 public:
  // Độ cao mặt dưới tại (x, z): bắn tia từ (x, 10000, z) hướng (0,-1,0).
  [[nodiscard]] std::optional<float>
  height(float x, float z) const noexcept;

  // Tia trúng gần nhất; direction là HƯỚNG, không chuẩn hoá; không loại mặt sau.
  [[nodiscard]] std::optional<Hit>
  raycast(std::span<const float, 3> origin,
          std::span<const float, 3> direction) const noexcept;

  [[nodiscard]] Aabb bounds() const noexcept;  // hộp bao mọi đỉnh đã biến đổi (toạ độ game), để sinh điểm thử (H1)
};

[[nodiscard]] std::expected<Model, LoadError>
load(std::span<const std::byte> data) noexcept;   // nạp hai pha; tệp bị từ chối cấp 0 byte

}  // namespace game::collision
```

- **Chữ ký hàm nạp:** `load(std::span<const std::byte>)` → `std::expected<Model, LoadError>`, `noexcept`.
- **Hai truy vấn (đều `const noexcept`):** `height(float x, float z) -> optional<float>` và
  `raycast(span<const float,3> origin, span<const float,3> direction) -> optional<Hit>`. Trượt trả
  `nullopt` (tương ứng gốc trả 0 và không ghi ra).
- **Hộp bao (H1):** `bounds() -> Aabb`, tính trên **mọi đỉnh trong vector đỉnh sau biến đổi** (toạ độ game,
  cùng hệ với `height`/`raycast`; mã 1 là đỉnh đọc thẳng từ tệp), **gồm cả điểm suy biến** của bản đặt tỉ
  lệ 0 (giữ như gốc, mục "Bản đặt: ca biên"); tệp rỗng trả hộp đảo (`min = +inf`, `max = -inf`) để A biết
  không có điểm nào hợp lệ.
- **Hằng N của H2 = 3.** Một lần nạp thành công cấp phát đúng 3 lần: mảng đỉnh, mảng chỉ số, cây
  OPCODE — mỗi mảng cấp một lần với kích cỡ chính xác (nhờ nạp hai pha), nên tệp nhỏ tự vẽ và tệp lớn
  nhất (`fenghuang` mã 1, `bianjing` mã 2) ra **cùng con số 3**. Truy vấn (H1) cấp phát **0**.

## Sáu ca G3 còn chờ (C chốt kỳ vọng)

| ca | mã | gốc làm gì | kỳ vọng port |
|---|---|---|---|
| ô có toạ độ âm | 1 | nhận; ô keyed theo (x,z) âm là bình thường (bản đồ trải qua vùng âm) | **nạp được**, cấp phát bình thường (N=3) |
| lưới đặc theo hộp bao | 1 | nhận; nhiều ô dày là hợp lệ | **nạp được**, cấp phát N=3 |
| đuôi thừa mã 1 | 1 | nhận, bỏ qua đuôi (không kiểm `size`) | **nạp được**, bỏ qua đuôi như gốc (đã bỏ `TrailingBytes`; thật: 0 ca) |
| đuôi thừa mã 2 | 2 | nhận, bỏ qua đuôi | **nạp được**, bỏ qua đuôi như gốc (đã bỏ `TrailingBytes`; thật: 0 ca) |
| tỉ lệ khung = 0 | 2 | chia cho 0 → toạ độ `Inf` | **từ chối** `kZeroFrameScale` (Khác gốc; chỉ từ chối đúng = 0, tỉ lệ âm và subnormal vẫn nhận; Khác Dev: Dev từ chối ≤ 0; thật: 0 ca, cả 47 khung tỉ lệ 100) |
| quaternion toàn 0 | 2 | quat→ma trận **không chuẩn hoá, không ngưỡng** (0x180011670, qua 0x180001f80) → ma trận đơn vị, hữu hạn | **nạp được** (coi là không xoay), cấp phát N=3; q không đơn vị khác: mục "Bản đặt: ca biên" |

Ca "tỉ lệ khung = 0" là ca duy nhất trong bảng bị từ chối, dựa trên luật an toàn + nạp hai pha; đánh dấu
`Khác gốc:` trong mã (`building_file.cpp:240`, `fpclassify == FP_ZERO`) và không ảnh hưởng số vàng vì dữ
liệu thật không có ca nào (T1 của B). Hai ca đuôi thừa nạp được như gốc (`building_file.cpp:354-355`;
oracle `so-do/b-goc-byte-thua.log`; L chốt G3-30, G3-64).

## Trả lời sáu câu của B — cho lớp `get` (mã 1)

1. **Kiểu ô 1–3:** ô 1 `u8 load(const void* data, u32 size)`; ô 2 `u8 height(float x, float* y,
   float z)`; ô 3 `u8 ray(const float origin[3], const float dir[3], float out[3])`. Tất cả trả `u8`
   (0/1).
2. **Ô 1 (nạp):** `data` trỏ vào đầu tệp; **có** truyền `size` nhưng gốc **không dùng** (không kiểm).
   **Không giữ con trỏ** vào bộ đệm sau nạp (đỉnh/chỉ số đã chép sang vùng đối tượng). "Nạp được" =
   luôn (gốc luôn trả 1); không có giá trị "từ chối" nào ở gốc — port tự thêm theo enum trên.
3. **Ô 2:** độ cao mặt dưới tại (x, z); vào `x`, `z` + con trỏ `y`; ra ghi vào `*y`; **không trúng** →
   trả 0, `*y` giữ nguyên.
4. **Ô 3:** véc-tơ thứ hai là **hướng** (không chuẩn hoá); ba số ra là **điểm trúng** (x,y,z); **trả
   false thì `out` không bị ghi**.
5. **Lớp nào đọc mã nào:** lớp `get` đọc **cả mã 1 và mã 2** (mã 2 qua ô phụ 0x180004a00). Lớp `new`
   không đọc tệp 0xFF000002 — nó nhận danh sách tam giác đã biến đổi sẵn. **Client dùng lớp `get`**
   (qua `Render.dll` `CBuildingCollision`). Sau mỗi lần dùng **phải gọi `destroyBuildingCollision`**
   (lớp `new`: `destroyBuildingWalkGeometry`).
6. **Đơn vị & khung:** mã 1 toạ độ là **đơn vị thế giới trực tiếp**, ô lưới rộng **1 đơn vị** xếp theo
   (x, z) (một tam giác ghi vào mọi ô nó chạm, nên lặp). Mã 2 toạ độ qua biến đổi (xem dưới); `frame`
   là (gốc x, gốc y, gốc z, tỉ lệ x, tỉ lệ y, tỉ lệ z), **đọc từ từng tệp**, không cố định (310 tệp thật có
   47 khung khác nhau, không khung nào là −3200000; xem ô 1, mã 2). Hộp truy vấn cho tệp rỗng **không có
   ý nghĩa** (0 tam giác → không dựng cây → mọi truy vấn
   trượt); dùng `bounds()` đảo thay cho đoán.

## Hai câu thêm của L

- **Ai đổi tệp ra tam giác, thứ tự biến đổi nào:** chính hàm `load` làm, trong lớp `get`. Mã 1
  (0x180004580) đọc tam giác **trực tiếp**, không biến đổi. Mã 2 (0x180004a00) với mỗi lượt đặt khối:
  dựng trước `M = (T · R) · S` (S là tỉ lệ bản đặt), rồi mỗi đỉnh `r = 1.0 / w` (`divss`),
  `p_i = (((m_i1·vy + m_i0·vx) + m_i2·vz) + m_i3) · r`, rồi toạ độ game `(p_i − frame_i) / frame_{i+3}`
  bằng `divss` thật; đủ năm điểm thứ tự f32 ở ô 1, mã 2. Quay R từ quaternion (0x180001f80 bọc 0x180011670,
  **không chuẩn hoá, không ngưỡng**: q không đơn vị cho ma trận méo, xem "Bản đặt: ca biên"), nhân ma trận
  0x1800032a0. Cả hai mã đổ vào cùng một vector đỉnh phẳng + mảng chỉ số 32-bit, rồi `Model::Build` dựng
  cây OPCODE.
- **Render ô 1 (0x18001d990):** là forwarder mỏng — `rcx = [rcx+8]` (lấy đối tượng `get` bên trong),
  rồi `jmp [vtable+8]` (ô 1 `load`). `rdx` (con trỏ dữ liệu) và `r8` (size) **truyền nguyên**, không
  phải `[rdx+8]`.

## NaN/Inf

Gốc **không bỏ** số không hữu hạn: ô 1 không kiểm số thực, mã 2 chia thẳng (tỉ lệ khung 0 → `Inf`) và
giữ NaN/Inf đi tiếp vào cây OPCODE.

Port (C chốt 14:13, đã cài ở bộ đọc của A): **từ chối ngay ở đầu vào** mọi số thực không hữu hạn trong
tệp, đánh dấu `Khác gốc:`: `kNonfiniteTriangle` (mã 1), `kNonfiniteVertex`, `kNonfiniteFrame`,
`kNonfinitePlacement` (mã 2), cùng `kZeroFrameScale` (`building_file.cpp` dòng 176, 206, 236, 240, 262 ở
bản sha `a32976db…`). Dữ liệu thật 0 ca nên số vàng không đổi.

Lỗ còn lại: đầu vào **hữu hạn nhưng lớn** qua được bộ đọc rồi ra NaN/Inf **sau** biến đổi, ví dụ q cỡ 1e20
(x2·x = Inf, rồi 0·Inf = NaN ở hàng 3 của M → w = NaN → cả ba toạ độ NaN) hay tỉ lệ bản đặt lớn. Bản gốc
**giữ** NaN/Inf đó. Port xử ở Model / `transform.hpp`; bước kiểm số không hữu hạn sau biến đổi chưa cài,
chưa có giá trị `LoadError` tương ứng. (Đối chiếu 2026-10-08: `transform.hpp` không còn là stub, nó cài đủ
`transform_vertex` và `build_mesh` đang dùng nó; thứ còn thiếu chỉ là bước kiểm nói trên.)

## Bản đặt: ca biên (mã 2)

Bộ đọc của A nhận nguyên bit mọi bản đặt hữu hạn (`building_file.cpp:244-247`): quaternion không chuẩn
hoá, **không có ngưỡng nào**; tỉ lệ bản đặt 0, âm hay subnormal cũng nhận. Model phải tái hiện như gốc.

- **Quaternion không đơn vị.** 0x180011670 dùng q thô. Với q = s·q̂ (q̂ đơn vị), ma trận ra
  (1 − s²)I + s²R̂, **không trực giao**: hình bị méo. Ca thật: 8 bản đặt có |n² − 1| > 1e-4
  (n² = w² + x² + y² + z²):
  - congren, congren_simple, congrensg, congrensg_simple, congrentx, congrentx_simple: q = (0,5; 0;
    0,810399; 0), n² = 0,906747, khối 221 tam giác; mặt xz co còn 0,8689, trục y giữ nguyên.
    **congrentx (trong bộ T2) là chốt kiểm**: nếu chuẩn hoá q thì ở bản đặt #63, đỉnh 0 lệch
    (−0,296; 0; +0,963) đơn vị game;
  - luofucheng #1: n² = 1,031035; sulingyuan #27: n² = 0,999817.

  Phân bố |n² − 1| trên 42 429 bản đặt: 11 611 ca ≤ 1e-12, phần lớn ở 1e-7..1e-5, 1 ca ~1e-4
  (sulingyuan), 7 ca ~1e-2 (6 tệp congren và luofucheng).
- **Tỉ lệ bản đặt (0, 0, 0).** FengYun_lingyunku_fb #581, khối 22 (379 tam giác): cả 379 tam giác suy
  biến về một điểm. **Giữ như gốc** (không bỏ): các tam giác này vẫn vào vector đỉnh, cây OPCODE (thứ tự
  duyệt, đếm suy biến 0x180036f60) và `bounds()`.
- **Tỉ lệ âm:** 0 ca thật. Lật chiều tam giác; tia vẫn trúng vì không loại mặt sau. Nhận như gốc.
- **Tỉ lệ không đều:** 5 611 bản đặt. S áp trước R (M = (T·R)·S) nên không xiên.

## Lớp `new` (mã 2 qua danh sách tam giác sẵn) — gộp từ B

> Chép từ `so-do/b-b1-lop-new.md` khi B nộp: hàm dựng 0x180005c70, ô 0 0x180005d60, ô 1 0x180006080,
> ô 3 0x180005f10 (ô 2 dùng chung 0x180004380). Lớp này bọc OPCODE 1.3, nhận tam giác đã biến đổi
> sẵn, không đọc tệp 0xFF000002, không có ai phía client gọi.

## Luật dùng ở Game.exe và Render.dll (T8)

### Game.exe: không dùng trực tiếp

Quét `Game.exe` (base 0x140000000): **0 tham chiếu** `getBuildingCollsion`, `PathLib`, hay
`CBuildingCollision`. Chuỗi `"Render.dll"` chỉ xuất hiện một lần trong thông báo lỗi phiên bản engine
(0x140c271d0); `"Collision"` chỉ nằm trong `"jiayuanjichu.FCollision"` (không liên quan). Bảng nhập
của `Game.exe` chỉ có `tEngine.dll`, `LuaPlus.dll`, `fmod64.dll` và các DLL hệ thống — **không nhập
`Render.dll`**. Kết luận: `Game.exe` không gọi mặt công trình; toàn bộ điều khiển collision ở tầng
engine (`tEngine.dll`) qua `Render.dll`. Không có ràng buộc dùng nào từ mã `Game.exe` cho port.

### Render.dll: `CBuildingCollision` (cầu nối engine ↔ PathLib)

RTTI `.?AVCBuildingCollision@@` (và `.?AVTBuildingCollision@@`), vtable 0x1802c02c0, đối tượng 0x18
byte: `[+0]` vtable, `[+8]` đối tượng PathLib lớp `get` (từ `getBuildingCollsion`), `[+0x10]` ngữ cảnh
engine. Bốn ô khớp ô lớp `get`:

| ô | địa chỉ | làm gì |
|---|---|---|
| 0 dtor | 0x18001d040 | nếu `[+0x10]` khác null, gọi dọn dẹp engine với `[+8]`; xoá `[+8]`, `[+0x10]` |
| 1 load | 0x18001d990 | `this = [this+8]`; tail-jmp inner ô 1 (load); `rdx`(data)/`r8`(size) nguyên |
| 2 height | 0x18001d7e0 | `this = [this+8]`; tail-jmp inner ô 2 (height) |
| 3 ray | 0x18001d680 | đóng gói `origin` (`rdx`) và `dir` (`r8`) vào mảng cục bộ, `r9` = out, gọi inner ô 3 (ray) tại `[vtable+0x18]` |

- **Tạo:** 0x18001d750 — cấp 0x18 byte (`operator new` 0x18003d200), đặt vtable, `[+0x10]` = ngữ cảnh,
  rồi gọi `getBuildingCollsion` (import từ `PathLib`, `rcx = [ctx+8]` = `PathLibRoot`), lưu vào `[+8]`.
- **Không ai gọi 0x18001d750 trực tiếp.** Con trỏ ctor nằm trong bảng mô tả lớp ở `.rdata` VA
  0x1802c0300 (create = 0x18001d750, kèm 0x18001d820 / 0x18001d890 và chuỗi tên). Engine tạo thể hiện
  qua bảng này.
- **`DllInit` 0x18001d9d0** (1 trong 3 hàm xuất của `Render.dll`: `DllInit`, `DllMagicCode`,
  `DllRelease`): lưu đối tượng engine vào global, đăng ký hai descriptor, rồi gọi `[registrar+0x80]`
  (`edx = 3`, `r8d = 0x132b6cb`) để đăng ký lớp. Đây là nơi `CBuildingCollision` gắn vào engine.

### Hợp đồng dùng (cho port)

Thứ tự: tạo (qua factory → `getBuildingCollsion`) → `load(data, size)` **một lần** → nhiều
`height` / `ray` → huỷ (`destroyBuildingCollision`). Ba truy vấn khớp y hệt lớp PathLib đã tả trên;
port chỉ cần đúng hợp đồng ba truy vấn, không có luật dùng riêng nào phát sinh ở tầng client.

Các **điểm gọi truy vấn thực** nằm trong `tEngine.dll` (lúc viết ghi là không có trên máy; đo
2026-10-08: `F:\tl 2026\Bin64\tEngine.dll` có, 175.616 byte; `Game.exe` chỉ nhập nó).
Nếu L cần địa chỉ từng điểm gọi phía engine, C kéo `tEngine.dll` về đọc tiếp; với port, hợp đồng trên
là đủ.

## Chưa kiểm

- **Điểm gọi truy vấn thật phía client** nằm trong `tEngine.dll` (`Game.exe` chỉ nhập DLL này, không
  nhập `Render.dll`). Lúc viết ghi máy không có `tEngine.dll`; tệp có ở `Bin64` (đo 2026-10-08) nhưng
  địa chỉ từng điểm gọi vẫn chưa ai đọc. Theo L chốt
  14:19, T8 dừng ở mức hợp đồng của `Render.dll`.
