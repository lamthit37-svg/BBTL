# Bản đồ quy cách C++23 (game MMO, C++23 thuần)

Áp dụng cho mọi việc C++: viết, sửa, review, giải thích, thiết kế. Bộ đầy đủ ở `~/.claude/cpp23/`
(Windows: `%USERPROFILE%\.claude\cpp23\`): `refs/` (356 quy tắc, mã `XX-NN`), `INDEX.md` (mỗi quy tắc
một dòng kèm Dòng, Dài), `tools/`, `config/`, `templates/`. Tệp này luôn trong ngữ cảnh; phần còn lại
chỉ đọc khi việc cần. **Thứ bậc:** yêu cầu tường minh của người dùng > quy định dự án (CLAUDE.md dự
án, phong cách tệp đang sửa) > bộ này > thói quen chung. Phá một PHẢI/CẤM thì nói rõ mã và lý do.

**Hình thức mã không thuộc bộ này** (người dùng tạm gác từ 2026-10-08): không còn quy tắc, hook hay
bước kiểm nào về định dạng, độ dài dòng, độ lồng, cỡ hàm, số tham số, quy ước đặt tên, dạng comment.
Viết theo phong cách của tệp đang sửa; không sửa mã chỉ để đổi hình thức, không báo hình thức là lỗi.
Mã quy tắc trong `refs/` có khoảng trống ở chỗ các quy tắc ấy từng đứng; mã còn lại giữ nguyên số.

## Luật sắt (luôn bật)

1. Ưu tiên: Đúng > An toàn, ổn định > Rõ ràng > Hiệu năng > Ngắn gọn; hiệu năng chỉ thắng khi có số đo (HP-01, HP-14).
2. Không UB dưới mọi hình thức: tràn có dấu, dịch bit, biên mảng, treo, aliasing. Số từ dây ghép từ byte little-endian (MMO-06); đối tượng từ bộ đệm byte qua `memcpy`/`std::bit_cast`, không `reinterpret_cast` (HP-02, UB-03).
3. Lỗi lập trình → `core::check`/`core::fail` (`"core/check.hpp"`, dừng sớm); lỗi dự kiến → `std::expected` + `enum class [[nodiscard]]` lỗi; không nuốt lỗi; không `throw` (HP-05, LH-01..05, LH-07).
4. Điều kiện client điều khiển được không bao giờ đi vào check/assert/abort/`.at()`/`narrow`: kiểm biên và trần TRƯỚC khi cấp phát hay lặp theo số client khai, trả lỗi, bỏ gói, đếm; `check` chỉ cho bất biến đã thiết lập sau bước kiểm đó (HP-16, LH-03, UB-04, MMO-06).
5. Trạng thái sai không biểu diễn được: `enum class` có kiểu nền, kiểu mạnh cho ID (`core::StrongId`) và đơn vị, không tham số `bool` cờ; "không có" là `std::optional`, không phải giá trị canh -1/0/nullptr (HP-03, KG-06..11).
6. Giá trị trước tham chiếu; `unique_ptr` mặc định; view/con trỏ trần không sống lâu hơn chủ, không giữ qua tick — thực thể qua handle thế hệ (HP-04, SH-*, MMO-04).
7. Tất định: logic game không phụ thuộc thứ tự `unordered_*`, `std::hash`, địa chỉ, đồng hồ thật, phân phối `<random>`, `-ffast-math`; code tất định build `-ffp-contract=off`, FMA chỉ qua `std::fma`. Thời gian: mốc `core::Tick`, khoảng `core::TickSpan`, ms thiết kế → tick bằng `core::to_ticks` (làm tròn lên) lúc nạp (HP-15, STD-14, STD-15, SV-11, MMO-03, MMO-17).
8. Include đủ thứ mình dùng, header tự đủ; không `using namespace` hay namespace ẩn danh trong header; namespace `game::<module>` theo bảng tầng; không định danh dành riêng (`_Hoa`, `__`) (DD-02, DD-05, DD-06, KTR-01).
9. Chữ ký nói hợp đồng: `[[nodiscard]]` mọi hàm trả giá trị (trừ trả `T&` để nối chuỗi); `const` cho hàm chỉ đọc; `noexcept` khi không cấp phát và không ném, hàm cấp phát thì không khai; constructor một đối số `explicit`; `constexpr` khi được và được đánh giá hằng ít nhất một lần (`static_assert`/test); hàm tự do định nghĩa trong header là `inline` hoặc `constexpr` (API-04, API-05, LH-06, LH-07, GN-05, HN-11).
10. Comment tiếng Việt nói hợp đồng, ca biên, vì sao — không kể lại code; code port ghi `Khác gốc:`; NOLINT nêu check + lý do + mã quy tắc (HP-07, CM-*, DD-08).
11. Không đoán API, cờ, tên check, số liệu; C++26 (contracts, reflection, inplace_vector, saturate_cast, std::simd, hazard_pointer, rcu) không phải C++23; tính năng không khả chuyển đi qua feature-test macro (HP-09, STD-16).
12. Không tuyên bố "đã biên dịch / đã test / nhanh hơn" khi chưa chạy thật; số đo kèm điều kiện (HP-11, HP-14, RV-04).
13. Kỹ thuật [T] chỉ khi đủ: số đo, test so với bản tham chiếu, comment bất biến kèm lập luận, bản tham chiếu còn giữ (HP-17, HP-18).

## Chất lượng cực hạn (luôn bật — người dùng chốt 2026-10-08, refs/20)

Không còn "mã thường": mọi mã đi vào dự án đạt đủ năm thuộc tính, mỗi thuộc tính có bằng chứng trong
báo cáo; "đã đọc lại, trông đúng" không phải bằng chứng (CL-01).

- **An toàn:** không UB, vượt biên, treo, tranh chấp với MỌI đầu vào, kể cả đầu vào thù địch. Bằng chứng: cổng máy bốn tầng xanh (CL-02) — 84 cờ cảnh báo `-Werror` trên GCC và Clang, 438 check clang-tidy, test chạy bằng Clang (ASan + UBSan mở rộng + hardening STL) và bằng GCC (debug mode của libstdc++).
- **Bền:** trước khi viết, trả lời "hỏng thế nào" cho mọi giá trị, kích thước, thứ tự, tài nguyên, bước, tác nhân đồng thời, kẻ tấn công (CL-03); mỗi mã lỗi, câu bảo vệ, ca biên có test đi tới — đường lỗi chưa từng chạy là mã chưa xong (CL-04); hàng đợi có trần, chờ có hạn (UB-13..15); nhiều bước thì kiểm hết rồi mới sửa trạng thái (LH-12).
- **Tối ưu:** ghi độ phức tạp và trần đầu vào ở hợp đồng; không thuật toán trên tuyến tính khi kích thước do bên ngoài quyết định (CL-05, HN-02); đường nóng không cấp phát, không sao chép ngầm, không gọi gián tiếp từng phần tử (HN-03..05), hàm chạy mỗi tick khai `GAME_NONALLOCATING` để Clang chứng minh (CL-09); "nhanh hơn" phải có số đo trước và sau (HN-01).
- **Hiện đại:** tiện ích chuẩn C++23 trước, tự viết sau; cấm idiom cũ có thay thế an toàn hơn — bảng CL-06 (`std::expected`, `std::span`, `std::print`, `<charconv>`, ranges, concept, `constexpr`, `std::jthread`, kiểu cỡ cố định thay `long`).
- **Thông minh:** điều gì máy chứng minh được thì để máy chứng minh — kiểu > `static_assert`/`consteval` > thuộc tính > `core::check` > test > comment, đặt mỗi bất biến ở bậc cao nhất dùng được (CL-07); thiết kế đơn giản nhất đủ bốn thuộc tính trên: mỗi trừu tượng, tham số, tuỳ chọn có nơi dùng thật ngay trong thay đổi này (CL-08).

Cổng đỏ thì sửa mã, không tắt cờ, không nới test; chỉ tắt đúng một chẩn đoán đã chứng minh là báo
nhầm, kèm phiên bản công cụ và ca tái hiện (BD-19). Nâng công cụ thì đo lại cổng (CL-10).

## Quy trình mỗi việc (HP-10)

1. Phân cấp: việc chạm [C] (API công khai, đường nóng, đa luồng, giao thức, dữ liệu lưu)? định dùng [T]?
2. Tra: hợp mọi hàng "Công thức" mà việc chạm; đọc hết cột "Đọc trước", cột "Thêm" khi gặp đúng tình huống.
3. Đọc code xung quanh: phong cách tệp đang sửa đi trước thói quen.
4. Phân tích thất bại trước (CL-03), rồi viết theo luật sắt; hợp đồng hàm trong comment (CM-03); test cho mọi đường lỗi (CL-04).
5. Tự kiểm: checklist refs/19 §4 và "Kiểm nhanh" của các tệp refs đã mở (`grep '^## [A-Z]' INDEX.md`: mỗi tệp một dòng kèm Dòng/Dài của Kiểm nhanh).
6. Kiểm bằng máy, chạy ở gốc repo: `python3 ~/.claude/cpp23/tools/check.py <các tệp đã đổi>` —
   GCC + Clang `-Werror` + bộ cảnh báo, clang-tidy; tự thêm `src/`, `tests/` làm thư mục include
   (`-I` cho chỗ khác). Lặp nhanh: `--no-tidy --only gcc`. Mọi thay đổi có hành vi: tệp test có
   `main` chạy bằng `--run --with src/<m>/x.cpp` (Windows: Clang + sanitizer + hardening, GCC +
   libstdc++ debug mode; CL-02), thêm `--tsan` nếu đa luồng. Dự án CMake:
   `cmake --preset gcc-asan && cmake --build --preset gcc-asan && ctest --preset gcc-asan`.
7. Báo cáo bốn mục: Đã kiểm (lệnh + kết quả, đi qua đủ năm thuộc tính của CL-01) / Chưa kiểm (vì sao) / Giả định / Lệch quy tắc (RV-04).

## Cách tra (rẻ nhất trước)

- Mã → dòng INDEX: `grep '^[|] MMO-06 ' ~/.claude/cpp23/INDEX.md` (`[|]` đúng cả với grep -E và
  ripgrep; `'^[|] MMO-0[1-4] '` cho một dải). Tiền tố mã → tệp: bảng "Tệp" dưới.
- Đọc một quy tắc: `Read(<HOME>/.claude/cpp23/refs/<tệp>, offset=Dòng, limit=Dài)` — đường dẫn tuyệt
  đối. Dải liền A..B một lần: offset = Dòng(A), limit = Dòng(B) + Dài(B) − Dòng(A).
- Theo từ khoá: tiêu đề tiếng Việt — `grep -n -i '<từ khoá>' INDEX.md` rồi mới `grep` trong `refs/`.
  Gợi ý: queue → "hàng đợi", "hộp thư"; buff/cooldown → "hồi chiêu", "tick"; packet → "gói";
  allocation → "cấp phát"; lifetime → "vòng đời", "treo"; ownership → "sở hữu"; error → "lỗi".
- Bảng tra lớn (hỗ trợ thư viện GCC/Clang, danh mục UB, checklist, lệnh kiểm, thuật ngữ): mục
  "Mục không phải quy tắc" đầu INDEX.md, có Dòng/Dài.
- Đọc trọn một tệp refs (11–80 KB) chỉ khi nó là chủ đề CHÍNH của việc lớn và chưa đọc trong phiên.
- Mẫu ✓ chép được, nhưng tự đủ nên khai lại `Tick`, id trần…: trong dự án dùng header `core/` (dưới).

## Công thức theo loại việc

| Việc | Đọc trước | Thêm khi chạm |
|---|---|---|
| MỌI việc C++ | CL-01..04 | CL-05..08; hàm chạy mỗi tick: CL-09; nâng công cụ: CL-10 |
| Giải mã gói tin, dữ liệu client, chat | MMO-05, MMO-06, UB-04, LH-03 | MMO-01, MMO-16, UB-03, UB-09, LH-04, SV-04 (số thực), STD-21 (lọc chat), MMO-13 + UB-14 (spam), KT-10, KT-11 |
| Hệ thống gameplay chạy theo tick | MMO-01, MMO-03, MMO-04, KTR-12, BN-01 | MMO-02, MMO-11, KTR-07, KTR-13, KG-08, KG-09, HN-03, HN-05, SH-07, STD-15, KT-02..05 |
| Có thời hạn: buff, hồi chiêu, hết hạn | MMO-03, KG-09, KTR-05, KTR-01 (luật ở gameplay, cơ chế ở sim) | BN-11 (tập nhỏ có trần mỗi thực thể), BN-01 (xoá bằng chép phần tử cuối), KTR-13, SH-07, STD-03 (`erase_if`), KT-05 |
| AOI, snapshot, nén trạng thái gửi đi | MMO-10, MMO-12 | MMO-20, BN-04, BN-16, UB-13, KT-09, KT-10 |
| Cổng input, rate limit, chống gian lận | MMO-13, MMO-14, UB-14 | UB-13, MMO-22, SV-04 |
| Kinh tế, giao dịch, túi đồ, chống nhân bản | MMO-07, MMO-08, MMO-21, LH-12 | MMO-01, MMO-04 (đối tác rời giữa chừng), MMO-09, UB-10, KT-09 (bảo toàn vật phẩm, tiền) |
| Phiên, kết nối lại, lưu DB, chuyển zone | MMO-15, MMO-16, MMO-23 | KTR-09, KTR-16, KTR-17, UB-15, LH-19 |
| Hàng đợi giữa luồng, mutex, atomic | DT-01, DT-02, DT-07, DT-08 | DT-03..06, DT-09, DT-10, DT-13, MMO-22, KT-12; lock-free [T]: HP-17, DT-14, DT-19, RV-07; seqlock/CAS/thu hồi: DT-15..17 |
| Tối ưu đường nóng | HN-01, HN-03, BN-01, BN-06, SV-01 | HN-02, HN-04, HN-05, HN-07..10, HN-15, HN-18, BN-05, BN-07, BN-15, SV-02, SV-05, SV-06, SV-11, KT-13, CM-15, CM-17, RV-06 |
| SIMD, số thực, tất định số học | SV-03, SV-07, SV-11, SV-15 | SV-04..06, SV-08..10, SV-12..18, KT-15, CM-16, CM-17 |
| Ngẫu nhiên, replay, tất định | HP-15, MMO-17, STD-14, STD-15 | MMO-18, MMO-19, SV-11, SV-14, KT-16 |
| API, lớp, thư viện dùng chung | API-01..05, LH-05, LH-06 | API-06..12, GN-01..07, CM-03, CM-11 |
| Sở hữu, vòng đời, callback | SH-01..07 | SH-08..12, SH-16, BN-09, UB-20 |
| Template, concept, constexpr | GN-01, GN-02, GN-04, GN-05 | GN-06..15, KT-04, KT-20 |
| Module, cấu hình, log, số liệu quan sát | KTR-01..06 | KTR-08, KTR-10, KTR-11, KTR-15, KTR-18, HN-06 |
| Viết test, fuzz, benchmark | KT-01..05 | KT-06..08; KT-09..14 theo loại |
| Build, CMake, CI, dự án mới | BD-01..05 | BD-06..12; khung dựng sẵn `templates/project/` |
| Port mã cũ (thư viện tham chiếu `_Ref`, mã C) | HP-07, CM-02, UB-01..06 | CM-01, CM-03, CM-05, CM-13, API-02 (tham số ra kiểu C), DD-12, KG-05, SV-03, SV-11, SV-12, SV-15, KT-15, KT-17, CM-16 |
| Review code | RV-01..05, checklist refs/19 §4 | hàng "Đọc trước" của mọi lĩnh vực diff chạm; RV-06, RV-07 |
| Comment, tài liệu module, ADR — khi đó là trọng tâm việc | CM-01..04 | CM-05, CM-08..14, DD-08 |

## Tệp

| Tệp | Chủ đề |
|---|---|
| `refs/00-hien-phap.md` (HP) | ưu tiên, cách đọc bộ quy cách, quy trình, phân xử, thuật ngữ |
| `refs/01-dinh-dang-dat-ten.md` (DD) | định danh dành riêng, include, namespace, NOLINT, mã hoá nguồn, macro, ODR |
| `refs/02-code-phang.md` (PH) | bảng tra, `switch` trên enum, đệ quy, chuỗi bất đồng bộ, máy trạng thái |
| `refs/03-kieu-gia-tri.md` (KG) | số nguyên, ép kiểu, enum, ID mạnh, đơn vị, optional/variant, struct mạng |
| `refs/04-so-huu-vong-doi.md` (SH) | RAII, unique/shared_ptr, view treo, move, callback bắt `this`, launder |
| `refs/05-loi-hop-dong.md` (LH) | lỗi, `expected`, ngoại lệ, `noexcept`, `core::check`, crash-only |
| `refs/06-ham-lop-api.md` (API) | tham số, chữ ký, lớp, toán tử, pimpl, ABI, deducing this |
| `refs/07-generic-compile-time.md` (GN) | concept, constexpr/consteval, bảng lúc biên dịch, ODR, thời gian build |
| `refs/08-thu-vien-chuan-cpp23.md` (STD) | container, ranges, format, chrono, charconv, random; bảng hỗ trợ GCC/Clang |
| `refs/09-hieu-nang.md` (HN) | đo, ngân sách tick, cấp phát, cờ hiệu năng, PGO/BOLT, đuôi p99 |
| `refs/10-bo-nho-cache-dod.md` (BN) | bố cục dữ liệu, AoS/SoA, cache, căn lề, pool, arena, NUMA |
| `refs/11-simd-vi-kien-truc.md` (SV) | SIMD, vector hoá, IEEE 754, FMA, denormal, không nhánh |
| `refs/12-dong-thoi.md` (DT) | luồng, khoá, atomic, memory order, SPSC, seqlock, ABA, QSBR |
| `refs/13-ub-on-dinh.md` (UB) | danh mục UB, sanitizer, hardening, số học an toàn, rate limit, watchdog |
| `refs/14-build-toolchain.md` (BD) | CMake, preset, cảnh báo, clang-tidy, CI, cứng hoá, modules |
| `refs/15-kiem-thu.md` (KT) | khung test, property, golden, fuzz, stress, benchmark, replay |
| `refs/16-comment-tai-lieu.md` (CM) | nội dung comment, "Khác gốc", tài liệu module, ADR, số đo |
| `refs/17-kien-truc-module.md` (KTR) | tầng, namespace, cấu hình, log, DI, zone/shard, triển khai không dừng |
| `refs/18-game-mmo.md` (MMO) | tick, handle, gói tin, UTF-8, AOI, snapshot, kinh tế, phiên, PRNG, chuyển zone |
| `refs/19-review-checklist.md` (RV) | review, checklist giao code, lệnh kiểm |
| `refs/20-chat-luong-cuc-han.md` (CL) | năm thuộc tính và bằng chứng, cổng máy đã đo, phân tích thất bại, test đường lỗi, idiom cũ → C++23 |

## Công cụ và header có sẵn

- `tools/check.py` — kiểm code dự án bằng một lệnh (bước 6). Trình dịch: `CPP23_G14`, `CPP23_G15`,
  `CPP23_C20` hoặc g++/clang++ trong PATH (Windows: GCC 16 MinGW, Clang 23 + STL MSVC; `--run` chạy
  cả hai theo CL-02, không có TSan).
- `templates/project/` — khung repo mới (CMake ≥ 3.28, 5 preset đã build và chạy test, `header_check`,
  khung test thuần C++). Bố cục: `x.hpp` cạnh `x.cpp` trong `src/<m>/` (include `"<m>/x.hpp"`), nội bộ
  `src/<m>/detail/`, test `tests/`; tầng kiểm bằng test `layers` (KTR-08, KTR-15). Header core có sẵn: `core/check.hpp` (cũng ở
  `tools/include/`), `core/time.hpp` (`Tick`, `TickSpan`, `to_ticks`), `core/clock.hpp` (`TickClock`),
  `core/narrow.hpp`, `core/strong_id.hpp`. Kiểu khác lấy từ mẫu của quy tắc, một bản trong module theo
  KTR-01: `Reader` (MMO-06), hộp thư (DT-01), PRNG (MMO-17), rate limit (UB-14); khung test có sẵn ở `tests/test.hpp` (KT-01).
- `config/` — `.clang-tidy`, `warnings-*.txt` (CMake đọc thẳng, BD-02); `.clang-format` chỉ còn là cấu
  hình định dạng cho trình soạn, không cổng nào kiểm.
