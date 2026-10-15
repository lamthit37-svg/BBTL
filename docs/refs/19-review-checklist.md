# RV · Review và checklist giao code

> **Phạm vi:** bước cuối của mọi việc C++: tự review trước khi giao, review code người khác, báo
> cáo. **Đọc khi:** sắp giao code (HP-10 bước 5); được nhờ review một thay đổi; viết báo cáo cuối việc.
> **Liên quan:** HP-10, HP-11, HP-12 (quy trình, báo cáo, phân xử), mục "Kiểm nhanh" cuối mỗi tệp
> refs/, INDEX.md (tra mã quy tắc).

## 1. Nền tảng [N]

### RV-01 [N] PHẢI — Tự review theo checklist §4 trước khi giao, theo thứ tự từ cấp N lên

Đi hết §4.1 cho mọi thay đổi; thêm §4.2 khi chạm phạm vi [C]; thêm §4.3 khi có kỹ thuật [T]. Mỗi
dòng trả lời có/không; "không" thì sửa hoặc ghi vào báo cáo kèm mã quy tắc.

- **Vì sao:** lỗi rẻ nhất là lỗi bắt trước khi người dùng thấy. Thứ tự N → C → T vì lỗi cấp N (UB,
  lỗi bị nuốt) đắt nhất và hay gặp nhất.
- **Kiểm:** báo cáo cuối việc có mục "Đã kiểm" (HP-11).

### RV-02 [N] PHẢI — Máy kiểm trước, mắt người sau

Chạy công cụ trước khi đọc: biên dịch GCC + Clang với cảnh báo dự án (BD-02), clang-tidy, test
dưới ASan + UBSan (TSan nếu đa luồng). Review bằng mắt dành
cho thứ công cụ không thấy: hợp đồng, tên, thiết kế, tất định, bảo mật đầu vào.

- **Vì sao:** người đọc giỏi vẫn bỏ sót một `-Wsign-conversion`; công cụ không bao giờ thấy hợp đồng
  sai. Chia đúng việc thì cả hai đều hiệu quả.
- **Kiểm:** lệnh ở §5 đã chạy; kết quả dán vào báo cáo.

### RV-03 [N] PHẢI — Mỗi nhận xét review nêu mã quy tắc, vị trí, hệ quả và cách sửa

Dạng: `tệp:dòng — MÃ-NN — vấn đề — hệ quả cụ thể — sửa thế nào`. Xếp theo mức: UB/bảo mật/mất dữ
liệu → sai hành vi → hiệu năng có số đo. Không có quy tắc nào áp dụng thì nói rõ là ý kiến.

- **Vì sao:** nhận xét có mã thì kiểm lại được và không thành tranh luận khẩu vị; xếp theo mức để
  người sửa làm đúng thứ quan trọng trước.
- **Kiểm:** review không có dòng nào thiếu mã hoặc thiếu hệ quả.

```text
net/login.cpp:42 — HP-16 — core::check(len < payload.size()) trên byte từ client — một gói dựng
  sẵn làm sập cả zone (DoS) — trả std::unexpected(ReadError::kTruncated), đếm gói hỏng.
inv/trade.cpp:88 — MMO-07 — số vàng cộng bằng float — lệch dần sau nhiều giao dịch, hai bên không
  còn bảo toàn — đổi sang int64 đơn vị nhỏ nhất, kiểm trần trước khi cộng.
```

### RV-04 [N] PHẢI — Báo cáo cuối việc: Đã kiểm / Chưa kiểm / Giả định / Lệch quy tắc

Bốn mục, theo thứ tự. "Lệch quy tắc" liệt kê mọi chỗ cố ý phá PHẢI/CẤM kèm mã và lý do (HP-12).
Không có gì trong một mục thì ghi "không".

- **Vì sao:** người dùng quyết định dựa trên báo cáo; lệch quy tắc giấu trong code sẽ bị người sau
  "sửa lại cho đúng" và mất lý do ban đầu.
- **Kiểm:** HP-11.

```text
Đã kiểm: tools/check.py trên 6 tệp đã đổi sạch (g++ 14.2 / clang++ 20 -Werror + warnings-*.txt,
  clang-tidy); ctest dưới ASan+UBSan 52/52.
Chưa kiểm: MSVC (không có máy); benchmark (thay đổi không chạm đường nóng).
Giả định: gói Move ≤ 64 byte theo proto/move.hpp.
Lệch quy tắc: proto/reader.hpp:88 — NOLINT(bugprone-exception-escape), .at() trên chỉ số nội bộ là
  dừng sớm có chủ ý (LH-07).
```

## 2. Nâng cao [C]

### RV-05 [C] PHẢI — Thay đổi chạm ranh giới tin cậy, đa luồng hay dữ liệu lưu được review theo lăng kính riêng

Ranh giới tin cậy (gói tin, tệp cấu hình, DB): đọc như kẻ tấn công — độ dài, tràn số, cấp phát
theo số client gửi, enum ngoài miền (UB-04, UB-09, UB-10, MMO-05, MMO-06). Đa luồng: ai sở hữu từng
biến, cặp release/acquire nào (DT-*). Dữ liệu lưu/mạng: phiên bản, bố cục, tương thích ngược
(KG-17, KTR-09).

- **Vì sao:** ba vùng này là nơi lỗi không lộ trong test thường mà lộ ở production, với hậu quả
  không đảo ngược được: máy chủ sập, vật phẩm nhân bản, save hỏng.
- **Kiểm:** fuzz (KT-11), TSan (DT-07), golden test (KT-10) có mặt cho thay đổi tương ứng.

### RV-06 [C] PHẢI — Thay đổi vì hiệu năng chỉ được nhận khi có phiếu đo

Phiếu đo gồm máy, trình dịch + cờ, dữ liệu, trung vị và p99 trước → sau (HN-01, HN-07, CM-15).
Không có phiếu thì giữ bản đơn giản hơn.

- **Vì sao:** tối ưu không đo thường không có lợi, và luôn tốn độ rõ ràng (HP-01, HP-14).
- **Kiểm:** review tìm phiếu đo trong PR và comment cạnh code.

## 3. Thần thoại [T]

### RV-07 [T] PHẢI — Mã [T] được review bởi người không viết nó, đối chiếu lập luận chứ không chỉ chạy test

Người review đọc lập luận trong comment (HP-18) và tự kiểm từng bước: cặp synchronizes-with, cận
sai số, điều kiện của `core::assume`, vòng đời đối tượng. Có bản tham chiếu và test so sánh
(HP-17). Một bước không tự kiểm được thì trả lại.

- **Vì sao:** lỗi thứ tự bộ nhớ hay lỗi 1 ulp có thể không bao giờ hiện trong test trên x86; chỉ
  lập luận đúng mới chặn được.
- **Kiểm:** biên bản review ghi đã kiểm bước nào.

## 4. Checklist

#### 4.1 Mọi thay đổi [N]

- [ ] Năm thuộc tính an toàn, bền, tối ưu, hiện đại, thông minh đều có bằng chứng trong báo cáo; cổng máy đủ bốn tầng đã chạy, kể cả `--run` (CL-01, CL-02).
- [ ] Đã phân tích thất bại trước khi viết; mỗi mã lỗi, câu bảo vệ, ca biên có test đi tới (CL-03, CL-04).
- [ ] Vòng lặp theo dữ liệu ghi độ phức tạp và trần; không idiom cũ trong bảng CL-06; mỗi bất biến ở bậc cao nhất dùng được; không trừu tượng thừa (CL-05, CL-07, CL-08).
- [ ] Biên dịch sạch GCC + Clang với `-Werror` và warnings-*.txt; clang-tidy sạch (BD-02, BD-05).
- [ ] Không UB với mọi đầu vào thoả hợp đồng: tràn có dấu, dịch bit, chia, biên mảng, aliasing, đọc chưa khởi tạo, float → int (HP-02, UB-01..06); treo (SH-06, SH-07).
- [ ] Lỗi đúng loại: check/fail cho lỗi lập trình, expected cho lỗi dự kiến, không nuốt lỗi (HP-05, LH-01..05).
- [ ] Không `throw`; destructor, move, swap `noexcept`; hàm cấp phát không `noexcept`; hàm vào luồng và callback `extern "C"` là `noexcept` (LH-06..08).
- [ ] Byte từ client không đi vào check, assert, abort, `.at()`; enum, `bool`, chỉ số từ dây qua hàm kiểm miền (HP-16, LH-03, UB-04, UB-09, MMO-01).
- [ ] Mọi biến khởi tạo; `const` mặc định; kiểu mạnh cho ID và đơn vị; không tham số `bool` cờ (KG-01..09).
- [ ] Sở hữu tường minh; không view/con trỏ sống lâu hơn chủ; không giữ tham chiếu qua thao tác vô hiệu hoá (SH-01..08).
- [ ] Tham số theo bảng, không tham số ra, `[[nodiscard]]`, `explicit`, `const` (API-01..07).
- [ ] Template ràng buộc concept; hàm `constexpr` có `static_assert` (GN-01..07).
- [ ] Không `printf`/`iostream`, `high_resolution_clock`, `atoi`/`stoi`; không `.value()` trên đường game/mạng (STD-04..06, STD-09).
- [ ] Include đủ, không `using namespace` trong header, không định danh dành riêng; NOLINT nêu check + lý do + mã; không macro hằng/hàm (DD-02, DD-05, DD-06, DD-08, DD-10).
- [ ] Include đúng tầng, không singleton/biến toàn cục khả biến; thời gian và ngẫu nhiên là tham số (KTR-01..07).
- [ ] Code game: bước tick cố định, thời gian là tick nguyên (`Tick`), thực thể qua handle thế hệ (MMO-02..04).
- [ ] Số thực: so bằng dung sai, số từ ngoài kiểm hữu hạn trước khi dùng, không `-ffast-math` (SV-03..06).
- [ ] Comment nói hợp đồng và vì sao; code port có "Khác gốc"; không code chết, TODO vô chủ (CM-01..10, HP-08).
- [ ] Có test cho hành vi mới, chạy dưới ASan + UBSan; hardening thư viện bật (KT-01..08, UB-07, UB-08).

#### 4.2 Phạm vi [C]

- [ ] Hàm chạy mỗi tick mang `GAME_NONALLOCATING` và build Clang sạch `-Wfunction-effects` (CL-09).
- [ ] API công khai: bất biến lập trong constructor, factory trả expected, toán tử hidden friend (API-08..12).
- [ ] Đường nóng: không cấp phát mỗi tick, không gọi gián tiếp từng phần tử, log kiểm mức trước khi định dạng, dữ liệu liền (HN-03..06, BN-01..05).
- [ ] Đa luồng: mỗi trạng thái một chủ, hàng đợi có trần, memory order có lý do, TSan sạch (DT-01..13).
- [ ] Giao thức/dữ liệu lưu: kiểm biên trước khi đọc, endian tường minh, phiên bản, golden test, fuzz (MMO-05, MMO-06, KTR-09, KT-10, KT-11).
- [ ] Tất định: không duyệt `unordered_*`, không phân phối `<random>`, không đọc đồng hồ trong logic, FMA chỉ qua `std::fma` (HP-15, STD-14, STD-15, KTR-07, SV-11).
- [ ] Kinh tế: số nguyên 64 bit, trần, hai pha, sự kiện append-only (MMO-07..09).

#### 4.3 Kỹ thuật [T]

- [ ] Đủ bốn điều kiện: số đo, test bảo vệ so với bản tham chiếu, comment bất biến, bản tham chiếu còn giữ (HP-17).
- [ ] Lập luận theo chuẩn hoặc tài liệu phần cứng, review bởi người khác (HP-18, RV-07).
- [ ] Khẳng định về mã máy nêu trình dịch, cờ, cách kiểm (CM-17, HN-15).

## 5. Lệnh kiểm một thay đổi

```bash
Q=~/.claude/cpp23
# Một lệnh cho mọi tệp đã đổi: biên dịch -O2 -Werror trên mọi trình dịch tìm được (header qua một
# TU riêng: tự đủ), clang-tidy. --run: tệp có main chạy trên mọi trình dịch — Linux: ASan + UBSan
# (+ float-cast-overflow cho GCC); Windows: Clang với ASan + UBSan mở rộng + hardening STL MSVC, GCC
# với debug mode của libstdc++ (CL-02). --tsan: thêm ThreadSanitizer.
python3 $Q/tools/check.py src/net/session.cpp src/net/session.hpp
python3 $Q/tools/check.py --run --tsan tests/net_tests.cpp --with src/net/session.cpp
# Dự án CMake: ma trận preset (BD-04, BD-12).
cmake --preset gcc-asan && cmake --build --preset gcc-asan && ctest --preset gcc-asan --output-on-failure
# Bản thủ công khi không có Python, một tệp. -I$Q/tools/include chỉ khi dự án chưa có
# core/check.hpp riêng; thêm -stdlib=libc++ cho clang++ nếu máy có libc++ (BD-12).
W="$Q/config/warnings-common.txt"
I="-I$Q/tools/include -Isrc -Itests"
g++ -std=c++23 -O2 -Werror $(cat $W $Q/config/warnings-gcc.txt) $I -c src/net/session.cpp -o /dev/null
clang++ -std=c++23 -O2 -Werror $(cat $W $Q/config/warnings-clang.txt) $I -c src/net/session.cpp -o /dev/null
clang-tidy --config-file=$Q/config/.clang-tidy src/net/session.cpp -- -std=c++23 $I
g++ -std=c++23 -O1 -g -fsanitize=address,undefined,float-cast-overflow -fno-sanitize-recover=all \
    -D_GLIBCXX_ASSERTIONS $I tests/net_tests.cpp src/net/session.cpp -o /tmp/net_tests && /tmp/net_tests
```

## Kiểm nhanh

- [ ] Đã đi hết §4.1, và §4.2/§4.3 khi chạm phạm vi tương ứng? (RV-01)
- [ ] Công cụ chạy trước, kết quả có trong báo cáo? (RV-02)
- [ ] Mỗi nhận xét có mã quy tắc, hệ quả, cách sửa? (RV-03)
- [ ] Báo cáo đủ bốn mục, mọi chỗ lệch quy tắc được liệt kê? (RV-04)
- [ ] Thay đổi ở ranh giới tin cậy, đa luồng, dữ liệu lưu có fuzz/TSan/golden test? (RV-05)
- [ ] Tối ưu có phiếu đo; mã [T] có người thứ hai kiểm lập luận? (RV-06, RV-07)
