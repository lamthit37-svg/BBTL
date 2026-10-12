# Bộ quy cách C++23 production cho Claude (game MMO, C++23 thuần)

356 quy tắc trong 21 tệp, ba cấp **Nền tảng → Nâng cao → Thần thoại**, 291 mẫu ✓ và 26 phản mẫu ✗.
Mọi mẫu ✓ đã biên dịch thật với GCC 14.2, GCC 15.2 và Clang 20.1 + libc++ 20 (`-std=c++23 -Werror`
+ bộ cảnh báo trong `config/`) và qua clang-tidy 20. Mẫu `[chạy]`/`[tsan]` được chạy thật dưới
ASan + UBSan / ThreadSanitizer.

**Bộ này không còn luật hình thức mã.** Ngày 2026-10-08 người dùng tạm gác hình thức để dồn sức cho
chất lượng thật: 14 quy tắc (định dạng, bảng đặt tên, bố cục header, dạng literal, thứ tự trong lớp,
độ lồng và hình dạng hàm, dạng câu comment) đã gỡ khỏi `refs/`, cùng hook đo hình dạng,
`check_shape.py`, các bước định dạng / độ lồng / hình dạng của `check.py` và `verify.py`, và mọi
check hình thức trong `config/.clang-tidy`. Quy tắc còn lại giữ nguyên mã nên dãy số có khoảng
trống. Bản trước khi gỡ nằm trong gói backup `AI-Setup-20261008-truoc-khi-bo-style.zip`.

**Chất lượng nâng lên mức cao nhất cùng ngày** (`refs/20`, mã CL): mọi mã đạt năm thuộc tính an
toàn, bền, tối ưu, hiện đại, thông minh, mỗi thuộc tính có bằng chứng. Cổng máy mạnh lên theo số đo
trên chính bộ mẫu này: bộ cảnh báo từ 29 lên 84 cờ, clang-tidy thêm 4 check và 9 tuỳ chọn chặt,
`check.py --run` chạy test bằng Clang (ASan + UBSan mở rộng + hardening STL MSVC) và bằng GCC (debug
mode của libstdc++ — trước đó GCC không chạy test nào trên Windows). Cờ đã thử mà loại, kèm số đo,
nằm ở CL-10.

Kiểm lại 2026-10-08 trên máy hiện tại (Windows 11) bằng `tools/verify.py --tidy`, sau cả hai thay
đổi: GCC 16.2 (MinGW-w64 UCRT, libstdc++), Clang 23.1 + STL MSVC 14.51, clang-tidy 23 — 291 mẫu ✓,
26 phản mẫu ✗, 0 lỗi. Mẫu `[chạy]` chạy bằng cả hai trình dịch theo CL-02; `[tsan]` không chạy và
4 mẫu `[linux]` (POSIX, ifunc, `std::stacktrace` của libstdc++) không biên dịch trên Windows. Chưa
kiểm bằng MSVC `cl`; phần Linux của các lượt chạy giữ nguyên như trước và chưa chạy lại.

## Cài cho Claude Code (toàn cục)

1. Chép cả thư mục `cpp23/` vào `~/.claude/cpp23/` (Windows: `%USERPROFILE%\.claude\cpp23\`).
2. Thêm đúng một dòng vào `~/.claude/CLAUDE.md` (tạo tệp nếu chưa có):

   ```text
   @~/.claude/cpp23/MAP.md
   ```

Chỉ `MAP.md` (~135 dòng, ~17 KB) được nạp vào mọi phiên: luật sắt luôn bật, quy trình 7 bước,
"công thức" việc gì → mã quy tắc nào, và công cụ. Claude đọc đúng từng quy tắc nhờ cột **Dòng** và
**Dài** trong `INDEX.md` (`Read(refs/<tệp>, offset=Dòng, limit=Dài)`), chỉ đọc trọn một tệp `refs/`
khi nó là chủ đề chính của việc lớn. Đừng import `refs/` vào CLAUDE.md: sẽ tốn hàng trăm nghìn
token mỗi phiên.

Quy định riêng của dự án (CLAUDE.md trong repo, "hiến pháp" dự án) luôn thắng bộ này.

## Dùng trong dự án

- Kiểm code bằng một lệnh — GCC + Clang `-Werror` với bộ cảnh báo, clang-tidy; header được biên dịch
  như một TU riêng:

  ```bash
  python3 ~/.claude/cpp23/tools/check.py src/net/session.cpp src/net/session.hpp
  python3 ~/.claude/cpp23/tools/check.py --run tests/net_tests.cpp --with src/net/session.cpp
  python3 ~/.claude/cpp23/tools/check.py --tsan tests/conc_tests.cpp
  ```

  Chạy ở gốc repo; `src/`, `tests/` tự thành thư mục include. Trình dịch lấy
  từ `CPP23_G14`, `CPP23_G15`, `CPP23_C20` (vd `CPP23_C20="clang++ -stdlib=libc++"`), không đặt thì
  dùng `g++`/`clang++` trong PATH (Windows: GCC 16 MinGW và Clang 23 + STL MSVC); dòng đầu in phiên
  bản từng công cụ và cảnh báo khi thấp hơn GCC 16 / Clang 23. Windows: `--run` chạy Clang dưới
  sanitizer + hardening và GCC với debug mode của libstdc++ (CL-02), `--tsan` bỏ qua. Lặp nhanh: `--no-tidy --only gcc`; `-j N` kiểm
  N tệp song song.
- `templates/project/`: khung repo mới — CMake ≥ 3.28, bố cục `x.hpp` cạnh `x.cpp` trong
  `src/<m>/` (KTR-08), test `layers` kiểm tầng (KTR-15), `header_check` (KTR-03), preset Debug/ASan/TSan/CI cứng hoá, khung
  test thuần C++, `core/check.hpp`, `core/time.hpp` (Tick), `core/clock.hpp`, `core/narrow.hpp`,
  `core/strong_id.hpp`. Đã build và chạy test qua 5 preset trên Linux, 3 preset trên Windows (xem
  README trong đó).
- `config/.clang-format`: hiệu chỉnh trên 4 tệp `math/*.hpp` của bạn ở trần 100 cột — clang-format 20
  và 23 tái tạo đúng từng byte (clang-format 18 chỉ khác một chỗ `T S::* m`). Từ 2026-10-08 trần là
  120 cột kèm hai điểm phạt chặn kiểu bẻ vô lý (sau `(`, sau kiểu trả); lý do và số đo ở đầu tệp.
  Từ 2026-10-08 tệp này chỉ còn là cấu hình để trình soạn định dạng khi lưu: không quy tắc, hook hay
  bước kiểm nào dùng nó.
- `config/.clang-tidy`: types.hpp và vector_int.hpp của bạn sạch với cấu hình này khi phân tích
  bằng libstdc++; với libc++ còn một cảnh báo `bugprone-exception-escape` ở `kMembers.at(i)`
  trong hàm `noexcept` (cách xử lý: LH-07, DD-08). Đã hiệu chỉnh lại cho clang-tidy 23: các check mới
  trái quy ước của bộ được tắt kèm lý do ngay trong tệp (BD-19). Từ 2026-10-08 không còn check hình
  thức: nhóm readability chỉ bật 13 check bắt lỗi thật hoặc sai hợp đồng; mọi tuỳ chọn về đặt tên, cỡ
  hàm, độ lồng, số tham số, độ phức tạp đã gỡ.
- `config/warnings-common.txt`, `warnings-gcc.txt`, `warnings-clang.txt`: cờ cảnh báo, CMake đọc
  thẳng từ tệp (BD-02).
- `tools/include/core/check.hpp`: header hợp đồng chuẩn mà mọi mẫu dùng (LH-02).

## Cấu trúc

```text
cpp23/
  MAP.md          bản đồ — import vào ~/.claude/CLAUDE.md
  INDEX.md        mọi quy tắc một dòng: mã, cấp, mức, tiêu đề, Dòng, Dài (sinh tự động)
  README.md       tệp này
  refs/           00 hiến pháp · 01 định danh, include, macro · 02 bảng tra, switch, máy trạng thái · 03 kiểu, giá trị ·
                  04 sở hữu, vòng đời · 05 lỗi, hợp đồng · 06 hàm, lớp, API · 07 generic, compile time ·
                  08 thư viện chuẩn C++23 · 09 hiệu năng · 10 bộ nhớ, cache, DOD ·
                  11 SIMD, vi kiến trúc, số thực · 12 đồng thời · 13 UB, ổn định · 14 build, toolchain ·
                  15 kiểm thử · 16 comment, tài liệu · 17 kiến trúc module · 18 game MMO · 19 review ·
                  20 chất lượng cực hạn
  config/         .clang-format, .clang-tidy, warnings-*.txt
  tools/          check.py (kiểm code dự án), verify.py (kiểm bộ tài liệu), include/core/check.hpp
  templates/      project/ — khung CMake + test đã build
```

## Kiểm lại bộ tài liệu

`tools/verify.py` kiểm cấu trúc tài liệu, tham chiếu chéo giữa các mã quy tắc, và biên dịch, chạy
clang-tidy cho mọi mẫu.

```bash
python3 tools/verify.py --lint-only          # cấu trúc + tham chiếu, không cần trình dịch
python3 tools/verify.py --index              # sinh lại INDEX.md sau khi sửa refs/
python3 tools/verify.py --tidy               # đầy đủ; Windows: g++ và clang++ trong PATH
CPP23_G14=g++-14 CPP23_G15=g++-15 CPP23_C20="clang++ -stdlib=libc++" \
python3 tools/verify.py --tidy               # Linux, đủ ba trình dịch
```

Biến `CPP23_*` trỏ tới trình dịch trên máy bạn. Mặc định: Windows dùng `g++`, `clang++`,
`clang-format`, `clang-tidy` trong PATH; Linux dùng đường dẫn xpack của máy kiểm gốc.
