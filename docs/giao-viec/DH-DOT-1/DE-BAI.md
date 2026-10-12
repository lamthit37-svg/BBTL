# Đề bài DH đợt 1: mặt đi được của công trình (`.WCollision`) theo client 2026

Soạn ngày 2026-10-08 bởi Claude (phiên client của THIENLONG) cho một phiên AI viết mã làm song
song. Người kiểm cuối là Claude; người duyệt là chủ dự án. Bản này thay bản soạn buổi sáng cùng
ngày: module `nav` đã vào `main`, worktree đã ngang `main`, và chủ dự án thêm một yêu cầu: mã phải
ở mức production và tối ưu tới cùng, cả hai chứng minh bằng số đo chứ không bằng lời.

## 1. Việc này là gì

Client THIENLONG hiện chỉ biết độ cao địa hình: nhân vật lún qua mặt cầu, bậc thang, sàn đài, và
nhấp chuột lên các mặt đó thì trúng địa hình bên dưới. Client gốc 2026 lấy các mặt này từ tệp
`<cảnh>.WCollision`, qua lớp `BuildingCollision` của `PathLib.dll`.

Nửa kia của chính DLL đó (lưới đi `.path`) đã port xong thành module `nav`, nằm sẵn trong cây của
bạn, và là bài mẫu cho cách làm: nạp `PathLib.dll` gốc bằng Python `ctypes`, hỏi nó truy vấn ngẫu
nhiên, so từng bit với bản port. Việc của bạn là làm đúng như vậy cho `BuildingCollision`, rồi đưa
bản port tới mức nhanh nhất mà vẫn trùng từng bit: **cùng tệp, cùng câu hỏi, bản port C++ trả lời
trùng từng bit với DLL gốc, và không chậm hơn nó.**

Vì sao đòi cả nhanh lẫn chắc: client sẽ gọi các truy vấn này trên đường nóng (độ cao dưới chân
nhân vật, tia của chuột, hộp của camera; tần suất chính xác là thứ bạn đọc ra ở `Game.exe`), và
tệp `.WCollision` là dữ liệu ngoài, một tệp hỏng không được làm client sập. Module chỉ dựa `core`
để cả client lẫn máy chủ dùng được.

Sản phẩm: một module C++, công cụ trọng tài, test kèm số vàng, bộ fuzz, exe đo, một tài liệu, một
báo cáo có số đo. Bạn KHÔNG nối module vào client (camera, nhân vật, chuột): Claude nối sau khi
nghiệm thu.

Nơi làm việc: worktree `F:\tl 2026\THIENLONG\build\dh-dot-1`, nhánh `dh-dot-1`, đang ngang `main`
ở commit `30172db`, cây sạch. Mọi đường dẫn tương đối dưới đây tính từ gốc worktree đó. Mở phiên
tại thư mục đó. Tệp `docs/giao-viec/DH-DOT-1/DE-BAI.md` trong worktree là bản cũ: không đọc theo
nó, không sửa nó; đề bài là văn bản này (bản lưu ở
`F:\tl 2026\THIENLONG\docs\giao-viec\DH-DOT-1\DE-BAI.md` của cây chính).

Đọc trước khi viết mã, theo thứ tự: văn bản này; `AGENTS.md` trọn mục 2 tới mục 11;
`~/.claude/cpp23/MAP.md` (15 luật sắt, quy trình 7 bước); bài mẫu `docs/DUONG-DI-2026.md`,
`SRC/nav/`, `tests/nav_tests.cpp`, `TOOLS/port/pathlib_oracle.py`; `G:\TLBB\Dev\docs\VA-CHAM.md`
(chỉ đọc).

## 2. Thứ tự ưu tiên và nghĩa của "tối ưu tới cùng"

Khi hai mục tiêu va nhau thì theo thứ tự này (HP-01 của bộ quy cách): trùng từng bit với bản gốc,
rồi an toàn với dữ liệu hỏng, rồi rõ ràng, rồi nhanh, rồi ngắn. Một tối ưu làm lệch một bit so với
DLL gốc là một lỗi, không phải một đánh đổi.

"Tối ưu tới cùng" ở đề bài này là năm điều đo được, mỗi điều là một tiêu chí ở mục 7:

- Truy vấn không cấp phát bộ nhớ, không khoá, không gọi hàm ảo hay `std::function` cho từng phần
  tử (HN-03, HN-05).
- Dữ liệu sau khi nạp là vài mảng phẳng, liền, chỉ số 32 bit; số lần cấp phát của một lần nạp là
  một hằng số không phụ thuộc cỡ tệp (BN-01, BN-04, BN-05).
- Không chậm hơn DLL gốc, đo trên cùng bộ truy vấn.
- Leo thang tối ưu của mục 6 cho tới khi nấc kế tiếp cho lợi nằm trong nhiễu đo; mỗi nấc giữ lại
  có phiếu đo trước và sau (HP-14, RV-06), nấc không có lợi thì gỡ khỏi mã.
- Kỹ thuật [T] (SIMD, mẹo bit, cách tỉa ứng viên khác bản gốc) chỉ dùng khi đủ bốn điều kiện của
  HP-17: số đo, test sai phân, comment bất biến kèm lập luận, bản tham chiếu còn giữ.

Nó không có nghĩa là: thêm SIMD hay bộ cấp phát riêng khi chưa có số đo chỉ ra điểm nóng; đổi thứ
tự phép tính số thực cho gọn; bỏ một phép kiểm biên của bộ đọc; viết mã khó đọc hơn mà không có
phiếu đo biện minh. Không dùng kỹ thuật [T] nào mà vẫn đạt mọi tiêu chí là kết quả tốt.

## 3. Điều Claude đã đo (2026-10-08)

**Dữ liệu.** `F:\tl 2026\_raw\Scene` có 435 tệp `.WCollision`, tổng 75.847.042 byte; cùng 435 tệp
nằm ở `F:\tl 2026\THIENLONG\CLIENT\data\Scene` của cây chính. Theo u32 mở đầu:

- `0xFF000001`: 125 tệp. 41 tệp dài đúng 8 byte (u32 thứ hai bằng 0), trong đó có
  `huoyangu.WCollision`: cảnh thử quen dùng của dự án không có mặt công trình nào. Lớn nhất là
  `fenghuang.WCollision`, 9.523.328 byte, cũng là tệp lớn nhất của cả kho. Ba tệp nhỏ nhất dài hơn
  8 byte: `lingxingfeng` 5.864, `erhai` 10.520, `hanxieling` 10.820.
- `0xFF000002`: 310 tệp, không tệp nào 8 byte. Lớn nhất là `bianjing.WCollision`, 531.404 byte. Ba
  tệp nhỏ nhất đều 32 byte: `MonthPVP_Xiuxi`, `SJTX_GameArea`, `Songliao_Xiuxi`.
- Tệp ở giữa dãy cỡ: `xihu_Valentine.WCollision`, 23.444 byte, mã `0xFF000002`.

**Bố cục tệp đã có người tháo.** `G:\TLBB\Dev\docs\VA-CHAM.md` mô tả cả hai bản: `0xFF000001` là
lưới ô chứa tam giác (theo mã nguồn `CBuildingCollisionMng` của client cũ), `0xFF000002` là các
khối lưới kèm bản đặt (tỉ lệ, vị trí, quaternion), suy từ dữ liệu và khớp từng byte trên 310 tệp.
Mã đọc của Dev: `G:\TLBB\Dev\tools\bake\walk_source.*`; mã truy vấn: `G:\TLBB\Dev\src\walk\`. Đó
là điểm xuất phát, không phải chuẩn: chuẩn là mã máy của `PathLib.dll` 2026. Chỗ Dev khác mã máy
thì theo mã máy và ghi `Khác Dev:`.

**DLL gốc** (`F:\tl 2026\Bin64`, chỉ đọc; base `0x180000000`):

- `PathLib.dll` xuất `?getBuildingCollsion@PathLibRoot@PathLib@@QEAAPEAVBuildingCollision@2@XZ`
  (0x18002dd30: cấp 0x60 byte rồi gọi hàm dựng 0x180001f20, không dùng `this`) và
  `?newBuildingWalkGeometry@PathLibRoot@PathLib@@SAPEAVBuildingCollision@2@XZ` (0x18002ddf0: cấp
  0x50 byte, hàm dựng 0x180005c70). Hai lớp cài đặt khác nhau cho cùng một giao diện; lớp nào đọc
  bản tệp nào, client 2026 dùng lớp nào ở đâu là việc bạn phải xác định.
- Giao diện trừu tượng `BuildingCollision@PathLib` (vtable 0x180043b50) có đúng bốn ô: destructor
  và ba hàm ảo thuần. Tức mỗi lớp cài đặt có ba hàm công khai sau destructor.
- `Render.dll` bọc nó bằng `CBuildingCollision` (vtable 0x1802c02c0): ô 1 (0x18001d990) gọi ô 1 của
  đối tượng bên trong với `rdx = [rdx + 8]` (nạp dữ liệu); ô 2 (0x18001d7e0) gọi thẳng ô 2; ô 3
  (0x18001d680) nhận hai con trỏ tới ba `float`, một con trỏ ra ba `float`, trả `bool`, gọi ô 3
  (bắn tia). Nghĩa chính xác của ô 2 và ô 3 chưa đọc.
- `Render.dll` và `PathLib.dll` nạp được bằng `ctypes.CDLL` sau `os.add_dll_directory(Bin64)`.

**Bài mẫu đã nằm trong cây.** `TOOLS/port/pathlib_oracle.py` (gọi hàm xuất để lấy đối tượng, đọc
con trỏ vtable, gọi hàm ảo theo số ô bằng `ctypes.CFUNCTYPE`, ghi số thực bằng 8 chữ số hex của
mẫu bit), `TOOLS/port/make_path_mesh.py` (tệp tự vẽ), `tests/nav_tests.cpp` cùng
`tests/golden/nav_*.tsv` (so từng bit, có nhúng tệp), `docs/DUONG-DI-2026.md` (hình dạng của tài
liệu), và dòng `target_compile_options(game_nav ... -ffp-contract=off ...)` trong `CMakeLists.txt`.
Bài học của lần đó: với lưới tự vẽ không giống dữ liệu thật, `PathLib.dll` đọc ngăn xếp chưa khởi
tạo và 29 trên 400 câu trả lời của nó không tái hiện được; tệp tự vẽ phải giống tệp thật.

**Công cụ soi mã máy**: `python TOOLS/port/pe_refs.py <tệp PE> <lệnh> <đối số>`, lệnh `func <địa
chỉ hex>` (tháo một hàm), `rtti <Tên@Namespace>` (vtable và các ô), `text`, `refs`, `calls`,
`vcalls`, `floats`, `imports`, `uses`, `imm`, `jump`. Hàm lớn của MSVC bị tách thành nhiều khúc
trong `.pdata`: `func` dừng ở cuối khúc thì gọi tiếp với địa chỉ kế.

**Cổng kiểm.** `python ~/.claude/cpp23/tools/check.py <tệp>` dùng cấu hình toàn cục (trần 120 cột)
và có bước "hình dạng": mỗi chữ ký và mỗi câu lệnh trong thân hàm nằm trọn một dòng; câu quá dài
thì rút gọn thiết kế, không bẻ dòng; vòng lặp nào cũng có ngoặc nhọn. `.clang-format` của worktree
nay cũng là bản 120 cột. Kết quả của `check.py` là chuẩn.

**Bốn cách làm Claude đã chạy thử trên máy này**, dùng lại, đừng dò lại:

- Đếm cấp phát: thay `operator new` và `operator delete` toàn cục trong riêng một exe test, đếm
  trong lúc gọi mã cần soi. Một tệp thử 40 dòng (duyệt `std::vector` phải đếm 0, một `push_back`
  phải đếm 1) ra đúng `0` rồi `1` ở GCC 16 `-O2`, MSVC `/O2 /MD`, và Clang 23 với đúng cờ của preset
  `clang-asan` (`-D_DLL -D_MT -Xclang --dependent-lib=msvcrt -fsanitize=address,undefined`). Kiểu
  căn lề riêng (`alignas` lớn hơn 16) đi qua bản `operator new` có `std::align_val_t`: thay cả bản
  đó nếu mã của bạn dùng.
- libFuzzer với ASan và UBSan: lệnh, hai macro `_DISABLE_*_ANNOTATION` và bẫy "harness phải dùng
  kết quả" ở mục 11 của `AGENTS.md`; mẫu chạy được là `TOOLS/server/fuzz_protocol.py` và
  `tests/fuzz/`.
- Exe đo: khung `tests/bench/bench.hpp` (đồng hồ đơn điệu, phân vị); `protocol_bench` và
  `net_bench` khai trong `CMakeLists.txt` bằng `add_executable`, dựng cùng mọi target, không đăng
  ký vào ctest.
- Kiểm cú pháp cho arm64 và Linux bằng trình dịch NDK:
  `"%LOCALAPPDATA%\Android\Sdk\ndk\30.0.16248370\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android29-clang++.cmd"
  -std=c++23 -fsyntax-only -Wall -Wextra -Werror -I SRC <tệp>` và cùng lệnh với
  `x86_64-linux-android29-clang++.cmd`.

Cổng Python `python -B -W error TOOLS/server/lint_py.py <tệp...>` nhận tệp ở thư mục bất kỳ. Hai
tệp mẫu `pathlib_oracle.py` và `make_path_mesh.py` KHÔNG qua cổng này (31 và 33 lỗi: thiếu kiểu
của tham số, một hàm 52 dòng, một hàm lồng 4 mức); `fuzz_protocol.py` thì sạch. Mượn cách làm của
hai tệp mẫu, đừng mượn hình dạng mã của chúng.

## 4. Thiết kế đã chốt

- Module mới `SRC/collision/`, namespace `game::collision`, tầng `"core collision"` (chỉ include
  `core`; điểm trên mặt đất là `core::GroundPoint` ở `core/ground_point.hpp`). Tệp:
  `SRC/collision/building.hpp`, `building.cpp`; tách tệp phụ khi một tệp quá 500 dòng. Module dựng
  cho mọi nền tảng như `nav` (không nằm trong khối chỉ dành cho máy dựng), không include header
  nào của hệ điều hành.
- Bộ đọc nhận `std::span<const std::byte>` (cả tệp), trả `std::expected<..., enum class lỗi>`. Tệp
  là dữ liệu ngoài: mọi số đếm và chỉ số kiểm với số byte còn lại TRƯỚC khi cấp phát hay lặp; số
  không hữu hạn là lỗi hoặc bị bỏ đúng như bản gốc bỏ (ghi rõ); không `core::check`, `assert`,
  `.at()` trên dữ liệu tệp; số ghép từng byte little-endian, không `reinterpret_cast`, không
  `memcpy` cả struct. Chép cả một mảng `float` bằng `memcpy` trên máy little-endian thì được (luật
  sắt 2), khi có phiếu đo cho thấy lợi và nhánh ghép từng byte vẫn còn cho máy khác.
- Nạp hai pha: pha một đi hết tệp, kiểm mọi số đếm và tính cỡ chính xác của từng mảng; pha hai mới
  cấp phát đúng cỡ đó và điền. Tệp bị từ chối thì chưa cấp phát byte nào. Mỗi đường hỏng trả đúng
  một giá trị lỗi nói được hỏng ở đâu; không trả đối tượng rỗng hay giá trị mặc định thay cho lỗi.
- Tệp 8 byte là tệp hợp lệ không có mặt nào: nạp được, mọi truy vấn trả "không trúng".
- Đối tượng sau khi nạp là bất biến và sở hữu dữ liệu đã giải mã, không giữ view vào bộ đệm tệp.
  Mọi truy vấn là hàm `const noexcept`, nhận giá trị, trả giá trị (`std::optional` cho "không
  trúng"), không tham số ra, không tham số `bool`. Không `mutable`, không bộ nhớ đệm, không biến
  tĩnh ghi được: nhiều luồng gọi cùng lúc trên một đối tượng là an toàn mà không cần khoá.
- Bố cục dữ liệu: mảng giá trị phẳng và liền; lưới 2D là một mảng hàng-trước; ô hay khối trỏ tới
  một đoạn `[đầu, cuối)` trong mảng chỉ số chung, chỉ số 32 bit. Không `std::vector` lồng
  `std::vector`, không `std::map`, `std::unordered_map`, không con trỏ sở hữu cho từng phần tử.
  Trường truy vấn nào cũng đọc đặt liền nhau, tách khỏi trường chỉ đọc lúc nạp (BN-07).
- Truy vấn: port đủ ba hàm công khai của bản gốc (nạp và hai truy vấn), cho lớp cài đặt mà client
  2026 thật sự dùng; lớp còn lại nếu client không gọi tới thì ghi bằng chứng (ai nhập hàm xuất đó,
  ai gọi) và không port. Tên và chữ ký C++ do bạn đặt theo nghĩa đọc từ mã máy; chú thích đầu tệp
  ghi địa chỉ gốc của từng phần.
- Số thực 32 bit, giữ nguyên thứ tự phép toán của mã máy. Target `game_collision` dựng với
  `-ffp-contract=off` ở GCC và Clang, y như dòng của `game_nav`. Tính trước một giá trị lúc nạp chỉ
  được khi đó đúng là dãy phép toán mà bản gốc làm lúc truy vấn, trên cùng đầu vào.
- Chỗ bản gốc có hành vi không xác định (đọc quá mảng, đọc biến chưa khởi tạo): bản port không
  chép hành vi đó. Định nghĩa một kết quả, ghi `Khác gốc:` kèm địa chỉ, và đếm số truy vấn của
  trọng tài rơi vào chỗ ấy.
- Bản tham chiếu: bản port thẳng đầu tiên trùng từng bit (bước B3). Nếu bản cuối khác nó ở thứ tự
  duyệt, cách tỉa ứng viên hay có SIMD, thì bản port thẳng ở lại trong `tests/` làm tham chiếu, và
  có test sai phân so từng bit trên truy vấn ngẫu nhiên có hạt giống. Bản cuối chính là bản port
  thẳng thì không cần hai bản.
- SIMD, nếu phiếu đo đòi tới: chỉ qua tầng `math` (`math/simd.hpp`, SV-07), khi đó dòng tầng thành
  `"core math collision"`; mọi phép tính trên từng làn phải là đúng phép vô hướng của bản gốc.
- Công cụ Python ở `TOOLS/port/`: `building_oracle.py` (nạp `PathLib.dll`, đưa một tệp
  `.WCollision`, hỏi N truy vấn ngẫu nhiên mỗi loại với hạt giống cố định, ghi tệp số vàng TSV; có
  `--embed` ghi kèm tệp dạng hex cho tệp nhỏ), `make_building_file.py` (sinh một tệp `.WCollision`
  nhỏ tự vẽ cho mỗi bản tệp mà bản gốc đọc được, hình dạng giống tệp thật), `fuzz_building.py`
  (dựng và chạy harness libFuzzer theo mẫu `fuzz_protocol.py`, thư mục dựng `build/dh-fuzz/`).
- Test, mỗi tệp một exe đăng ký bằng `game_test`:
  `tests/collision_tests.cpp` (bộ đọc trên byte tự dựng; so từng bit với số vàng của tệp tự vẽ có
  nhúng tệp; so với số vàng của `lingxingfeng` và `xihu_Valentine` khi có
  `CLIENT/data/Scene/<cảnh>.WCollision`, macro `GAME_CLIENT_DATA` như `nav_tests`, không có thì tự
  bỏ qua; ca nhiều luồng; test sai phân nếu có bản tham chiếu),
  `tests/collision_alloc_tests.cpp` (đếm cấp phát, exe riêng vì nó thay `operator new`),
  `tests/collision_fuzz_tests.cpp` (fuzz tầng một: bộ đột biến tất định như
  `tests/protocol_fuzz_tests.cpp`). Số vàng ở `tests/golden/collision_*.tsv`; macro đường dẫn
  khai trong CMake như `GAME_NAV_GOLDEN` của `nav_tests`.
- Harness libFuzzer ở `tests/fuzz/fuzz_building*.cpp`: nạp byte đầu vào; nạp được thì chạy truy vấn
  sinh từ chính các byte đó và dồn kết quả vào một tổng kiểm ghi ra biến `volatile`.
- Exe đo `tests/bench/collision_bench.cpp` (khai bằng ba dòng như `protocol_bench`, trong một khối
  `if(NOT CMAKE_CROSSCOMPILING)`): nhận một tệp `.WCollision` và một tệp số vàng, dùng chính các
  truy vấn trong tệp số vàng; in một dòng TSV mỗi lượt: thời gian nạp, trung vị và p99 mỗi truy vấn
  theo từng loại, số lần và số byte cấp phát của lần nạp. Mỗi mẫu đo một lô truy vấn, vì một truy
  vấn ngắn hơn độ phân giải đồng hồ (KT-13). Có chế độ `--verify` đếm số dòng lệch với tệp số
  vàng, để so trên cảnh không có số vàng trong git. Exe đo gọi module qua hàm công khai, không
  chép thân hàm vào mình.
- Số đo của DLL gốc: `docs/giao-viec/DH-DOT-1/so-do/dll_bench.cpp`, một tệp vật chứng không vào
  CMake và không qua `check.py`: nạp `PathLib.dll` bằng `LoadLibraryW` theo đường dẫn nhận từ dòng
  lệnh, chạy cùng tệp số vàng với cùng vòng đo, in cùng định dạng. Lệnh dựng nó ghi vào log.
- Để chạy phần cảnh thật trong worktree, chép các tệp `.WCollision` cần dùng vào
  `CLIENT/data/Scene/` của worktree (thư mục đó git bỏ qua).
- Phía `Game.exe` (`F:\tl 2026\Bin64\Game.exe`, base `0x140000000`): tìm các chỗ gọi tới
  `CBuildingCollision` và ghi lại luật dùng: độ cao nhân vật lấy mặt công trình khi nào (client cũ:
  khi nó không thấp hơn địa hình), tia của chuột và của camera có đi qua nó không, ngưỡng nào, mỗi
  khung gọi mấy lần. Chỉ ghi vào tài liệu kèm địa chỉ; không viết mã nối.
- Tài liệu `docs/VA-CHAM-2026.md`: bố cục hai bản tệp, thuật toán từng truy vấn kèm địa chỉ, độ
  phức tạp mỗi truy vấn, bố cục dữ liệu sau nạp và vì sao, luật dùng ở `Game.exe`, lệnh chạy trọng
  tài, số đo khớp, số đo tốc độ, chỗ khác Dev, chỗ khác gốc, phần chưa làm.

## 5. Ranh giới

- Chỉ ghi trong `F:\tl 2026\THIENLONG\build\dh-dot-1`. Chỉ đọc: cây chính `F:\tl 2026\THIENLONG`,
  `F:\tl 2026\_raw`, `F:\tl 2026\Bin64`, `G:\TLBB\Dev`. Không chạy `Game.exe`, không chạy client,
  không mở cửa sổ nào.
- Được tạo mới: `SRC/collision/**`; `tests/collision_tests.cpp`, `tests/collision_alloc_tests.cpp`,
  `tests/collision_fuzz_tests.cpp` và header phụ `tests/collision_*.hpp`;
  `tests/golden/collision_*.tsv`; `tests/bench/collision_bench.cpp`; `tests/fuzz/fuzz_building*.cpp`;
  `TOOLS/port/building_oracle.py`, `make_building_file.py`, `fuzz_building.py`;
  `docs/VA-CHAM-2026.md`; và mọi thứ dưới `docs/giao-viec/DH-DOT-1/` trừ `DE-BAI.md`.
- Được sửa bằng cách chỉ thêm dòng: `CMakeLists.txt` (module, dòng `-ffp-contract=off`, ba
  `game_test` kèm macro đường dẫn, exe đo), `cmake/GameLayers.cmake` (một dòng
  `game_layer_collision`). Không sửa tệp
  có sẵn nào khác, kể cả `.clang-format`, `.clang-tidy`, `AGENTS.md`, mọi module và test có sẵn.
  Việc đòi sửa một tệp ngoài danh sách này: dừng việc đó lại, ghi vào báo cáo, làm phần còn lại.
- Git chỉ dùng lệnh đọc. Không commit, không đổi nhánh, không `stash`, `reset`, `checkout`,
  `restore`, `clean`, `worktree`. Claude commit sau khi kiểm.
- Không mở, không in, không chép `SERVER/config/secrets.local.toml` và `Server\Config\Account.txt`.
- Máy có thể đang có phiên khác dựng mã. Lệnh nặng là: dựng trọn một preset, `check.py` có
  clang-tidy trên hơn năm tệp, libFuzzer, mọi phép đo. Mỗi lúc chỉ chạy một lệnh nặng. clang-tidy
  báo `LLVM ERROR: out of memory` là máy cạn bộ nhớ, không phải lỗi mã: chạy lại một mình.
- Thứ sinh ra khi dựng và đo nằm dưới `build/` của worktree; script tạm cũng vậy. Công cụ Bash của
  agent làm hỏng heredoc Python có `\` hoặc dấu `'` lẻ: viết script ra tệp rồi chạy tệp.
- Không thêm thư viện ngoài. Không `NOLINT` thiếu tên check, lý do và mã quy tắc.
- Đề bài không nói tới một tình huống: chọn phương án giữ trùng từng bit và an toàn với dữ liệu
  hỏng, ghi vào mục Giả định của báo cáo, làm tiếp.

## 6. Các bước

Lệnh chạy ở gốc worktree. Preset MSVC chạy trong `dev.bat`
(`cmd /c "call %USERPROFILE%\.claude\skills\cpp-build\dev.bat && cmake --preset msvc-release && ..."`);
`ctest --preset clang-asan` chạy ngoài `dev.bat` (trong `dev.bat` nó nhặt nhầm DLL ASan của MSVC).

- **B0, số nền.** Trước khi viết dòng mã nào: cấu hình, dựng `all` và `header_check`, chạy `ctest`
  ở `msvc-release`, rồi `gcc-debug`, rồi `clang-asan`. Cấu hình `msvc-release` trước: nó cài gói
  vcpkg vào `vcpkg_installed/` của worktree, hai preset kia lấy header ở đó (mục 0 của
  `AGENTS.md`). Ghi log và số test của từng preset; đó là số nền của tiêu chí T4. (Cây chính, có
  `CLIENT/data`, hôm nay là 59, 50, 59; worktree không có dữ liệu nên sẽ ít hơn. Ba cây dựng của
  cây chính chiếm 2,6 GB, 0,9 GB và 1,6 GB; ổ F còn 160 GB.) Cây hỏng từ đầu thì dừng và báo,
  không sửa.
- **B1, đọc mã máy.** Hai lớp cài đặt, lớp nào đọc bản tệp nào, client dùng lớp nào; nghĩa của ba
  ô vtable; cấu trúc tỉa ứng viên của bản gốc; thứ tự phép tính. Ghi dần vào tài liệu kèm địa chỉ.
- **B2, trọng tài và điều tra dữ liệu.** `building_oracle.py`, `make_building_file.py`; tiêu chí T1
  trên cả 435 tệp.
- **B3, bản port thẳng.** Test đỏ trước (giữ log), rồi bộ đọc, rồi ba hàm, tới khi trùng từng bit
  (T2, T3). Bản này là bản tham chiếu và là dòng đầu của bảng phiếu đo.
- **B4, đo.** `collision_bench` và `dll_bench.cpp`; đo DLL gốc và bản port thẳng trên ba cảnh của
  H3. Từ đây mới biết điểm nóng ở đâu.
- **B5, leo thang tối ưu**, đúng thứ tự, nấc trên chưa hết mới xuống nấc dưới: (1) thuật toán và
  cấu trúc tỉa ứng viên (HN-02); (2) bố cục dữ liệu; (3) bỏ cấp phát, sao chép, gọi gián tiếp; (4)
  vi tối ưu vô hướng: thứ tự nhánh, thoát sớm, tính trước lúc nạp; (5) kỹ thuật [T]. Mỗi nấc: đo
  trước, sửa, chạy lại số vàng, đo sau cùng điều kiện, ghi phiếu đo. Hai khoảng [nhỏ nhất, lớn
  nhất] của năm lượt trước và sau chồng nhau thì nấc đó không có lợi: gỡ khỏi mã, vẫn ghi vào bảng
  là đã thử. Dừng leo khi một nấc không cho lợi ở cả ba cảnh.
- **B6, mức production.** Fuzz hai tầng, bộ dò có răng, đột biến, ca nhiều luồng, đếm cấp phát,
  bảng lỗi, kiểm cú pháp NDK (các tiêu chí G và H1, H2).
- **B7, cổng và báo cáo.** `check.py` đủ bộ trên mọi tệp C++ mới, ba preset, tài liệu, `KET-QUA.md`.

## 7. Tiêu chí đạt

Đúng với bản gốc:

| Mã | Phép kiểm | Đạt khi |
|---|---|---|
| T1 | bộ đọc C++ (qua `collision_bench` hoặc một bản Python cùng thuật toán) chạy trên cả 435 tệp của `_raw` | số byte đọc bằng đúng cỡ tệp ở mọi tệp bản gốc nạp được; bảng đếm theo mã bản khớp 125 và 310; tệp bị từ chối liệt kê kèm lý do và kèm kết quả nạp của DLL gốc trên chính tệp đó |
| T2 | trọng tài trên ít nhất 20 cảnh: `fenghuang`, `bianjing`, `xihu_Valentine`, sáu tệp nhỏ nhất dài hơn 8 byte nêu ở mục 3, ít nhất một tệp 8 byte, còn lại tự chọn cho đủ hai mã bản; mỗi cảnh ít nhất 2.000 truy vấn mỗi loại; so bằng `collision_bench --verify` | 0 dòng lệch, trừ các truy vấn rơi vào hành vi không xác định của bản gốc: mỗi nhóm lệch có giải thích từ mã máy kèm địa chỉ và số ca |
| T3 | `collision_tests` | xanh ở `gcc-debug`, `clang-asan`, `msvc-release`; có log của lượt đỏ trước khi viết mã |
| T4 | ba preset: cấu hình, dựng `all` và `header_check`, `ctest --preset <p>` | 0 cảnh báo; số test cũ bằng số nền của B0; ba test mới xanh; `layers` xanh |
| T5 | `python ~/.claude/cpp23/tools/check.py` trên mọi tệp C++ mới, kể cả test, exe đo, harness | 0 lỗi ở mọi bước (định dạng, độ lồng, hình dạng, GCC, Clang, clang-tidy) |
| T6 | `python -B -W error TOOLS/server/lint_py.py` trên ba tệp Python mới | thoát 0 |
| T7 | `git status --short`, `git diff --numstat` | tệp mới chỉ ở chỗ mục 5 cho phép; hai tệp CMake chỉ thêm dòng |
| T8 | `docs/VA-CHAM-2026.md` | mỗi hàm gốc đã port có địa chỉ; mỗi luật dùng ở `Game.exe` có địa chỉ chỗ gọi; phần chưa đọc ghi là chưa đọc |

Mức production:

| Mã | Phép kiểm | Đạt khi |
|---|---|---|
| G1 | bảng lỗi: mỗi giá trị của enum lỗi ứng với tên ca test sinh ra nó | không giá trị nào thiếu ca; không giá trị nào không đường mã nào trả về |
| G2 | cắt cụt: với mỗi tệp tự vẽ, thử mọi độ dài tiền tố từ 0 tới cỡ tệp trừ 1 | mọi tiền tố bị từ chối bằng một giá trị lỗi, trừ tiền tố tự nó là một tệp trọn vẹn (liệt kê); báo tổng số ca |
| G3 | tệp thù địch: phần đầu khai số đếm `0xFFFFFFFF`, chỉ số âm hoặc vượt mảng, số không hữu hạn, mã bản lạ (các ca này nằm ở `collision_alloc_tests`) | bị từ chối; bộ đếm cấp phát đọc 0 cho cả lần nạp đó |
| G4 | `collision_fuzz_tests`, 200.000 vòng mỗi đích (ở `clang-asan` được hạ số vòng cho dưới 60 giây, ghi số thật) | xanh ở ba preset; không sập, không treo; tệp nạp được thì truy vấn không sập |
| G5 | `python -B TOOLS/port/fuzz_building.py --runs 1000000 --seed 20261008`, ASan và UBSan | mỗi đích `Done 1000000 runs`, thoát 0, không tệp `crash-*`, `timeout-*`, `oom-*` |
| G6 | bộ dò có răng: trên một bản chép của `SRC/collision` đặt trong `build/`, bỏ một phép kiểm biên của bộ đọc rồi chạy G5 trên bản chép | thoát khác 0 trong một triệu vòng; dán dòng `ERROR` của ASan |
| G7 | đột biến: ít nhất một cái cho mỗi hàm của đường truy vấn và một cái cho mỗi phép kiểm biên của bộ đọc (đổi một phép so, một dấu, một chỉ số, bỏ một phép kiểm) | mỗi đột biến làm ít nhất một test đỏ; cái nào sống thì thêm ca bắt nó, hoặc chứng minh nó tương đương; ghi diff và output |
| G8 | ca nhiều luồng trong `collision_tests`: 8 luồng cùng truy vấn một đối tượng | mọi câu trả lời trùng từng bit với lượt một luồng; xanh ở `clang-asan`; báo cáo ghi rõ "chưa kiểm TSan" |
| G9 | lệnh `grep` ghi ngay dưới bảng này, chạy trên `SRC/collision` | 0 dòng (cùng lệnh trên `SRC/nav` hôm nay ra 0 dòng) |
| G10 | `grep -rn NOLINT` trên mọi tệp mới | mỗi dòng có tên check, lý do, mã quy tắc; báo cáo liệt kê đủ |
| G11 | hai lệnh NDK của mục 3 (thêm `-ffp-contract=off`) trên mọi `.cpp` của `SRC/collision` | cả hai thoát 0 |
| G12 | `wc -l` mọi tệp viết tay của đợt | không tệp `.cpp`, `.hpp`, `.py` nào quá 500 dòng |

Lệnh của G9 (để ngoài bảng vì dấu `|` của biểu thức):

```
grep -rnE "\bmutable\b|\bconst_cast\b|\breinterpret_cast\b|\bthrow\b|\bcatch\b|\bmalloc\b|\bvolatile\b|\bvirtual\b|std::function|\bmutex\b|std::(unordered_)?map\b|vector<\s*std::vector" SRC/collision
```

Hiệu năng. Đo ở `msvc-release`, ba cảnh `fenghuang` (9.523.328 byte), `bianjing` (531.404 byte),
`xihu_Valentine` (23.444 byte), bộ truy vấn là tệp số vàng 2.000 truy vấn mỗi loại của T2:

| Mã | Phép kiểm | Đạt khi |
|---|---|---|
| H1 | `collision_alloc_tests`: sau khi nạp, 10.000 truy vấn mỗi loại | bộ đếm cấp phát đọc 0; xanh ở ba preset |
| H2 | số lần cấp phát của một lần nạp thành công, đếm trong `collision_alloc_tests` và in ở `collision_bench` | không quá một hằng N khai trong test; với mỗi mã bản, tệp tự vẽ nhỏ và tệp lớn nhất của mã bản đó (`fenghuang`, `bianjing`) ra cùng một con số |
| H3 | `collision_bench` so với `dll_bench`, cùng cảnh, cùng tệp số vàng, năm lượt mỗi bên | với từng cảnh và từng loại truy vấn, trung vị và p99 mỗi truy vấn của bản port không lớn hơn của DLL gốc; hai khoảng [nhỏ nhất, lớn nhất] của năm lượt chồng nhau thì tính là ngang; thời gian nạp so theo cùng luật |
| H4 | bảng phiếu đo của B5 | mỗi nấc giữ lại có số trước và sau (trung vị, p99, nhỏ nhất, lớn nhất của năm lượt) kèm hai tệp log; sau nấc cuối T2 và T3 chạy lại vẫn 0 dòng lệch; nấc không có lợi đã gỡ khỏi mã |
| H5 | mỗi chỗ dùng kỹ thuật [T] | đủ bốn món của HP-17: phiếu đo, test sai phân trùng từng bit với bản tham chiếu, comment bất biến kèm lập luận và số đo (HP-18, CM-15), bản tham chiếu còn trong `tests/`; không dùng [T] nào thì ghi "không dùng" và tính là đạt |
| H6 | bộ nhớ sau nạp của ba cảnh: tổng byte đang giữ, tỉ số với cỡ tệp, và bảng từng mảng (tên, số phần tử, byte mỗi phần tử, truy vấn nào đọc nó) | không dữ liệu nào lưu hai lần; mọi chỉ số là 32 bit |

Số đo chỉ báo, không có ngưỡng: số tam giác, số ô hay số khối lớn nhất của kho; số truy vấn đã so
và số ca lệch theo từng loại; vòng mỗi giây của từng đích libFuzzer; thời gian chạy của ba test
mới ở từng preset; số dòng của từng tệp viết tay.

Luật đo: chỉ đo khi không có lệnh nặng nào khác; dòng đầu của log là giờ bắt đầu và câu "không có
bản dựng nào khác đang chạy"; mỗi phép ít nhất năm lượt, báo trung vị, nhỏ nhất, lớn nhất; lượt lớn
nhất quá 1,5 lần lượt nhỏ nhất thì đo lại và giữ cả log cũ. Số Claude đo lại lệch quá 30% trung vị
của bạn thì báo cáo bị trả.

Tiêu chí không đạt thì ghi không đạt kèm output và điều bạn đã thử. Không sửa kỳ vọng của test,
không hạ ngưỡng, không bỏ lượt đo xấu. Một báo cáo nói thẳng "H3 không đạt ở tia trên `fenghuang`,
chậm hơn 12%, điểm nóng ở hàm X" có giá trị hơn một bảng toàn chữ đạt mà Claude đo lại không ra.

## 8. Báo cáo

`docs/giao-viec/DH-DOT-1/KET-QUA.md`, mở đầu bằng ba bảng, không có câu dẫn:

1. Bảng tiêu chí, đủ mọi mã T, G, H: `mã`, `đạt hay không`, `lệnh đã chạy`, `dòng output quyết
   định`, `tệp log`.
2. Bảng số đo: `đại lượng`, `lệnh`, `số lượt`, `trung vị`, `nhỏ nhất`, `lớn nhất`, `tệp log`; kèm
   một dòng điều kiện đo: commit (`git rev-parse HEAD`), preset và cờ, tên CPU, có hay không có bản
   dựng khác chạy cùng lúc.
3. Bảng phiếu đo: `nấc`, `thay đổi` (một câu), `cảnh`, `loại truy vấn`, `trước`, `sau`, `giữ hay
   gỡ`, `hai tệp log`. Dòng đầu là DLL gốc, dòng hai là bản port thẳng.

Rồi bốn mục Đã kiểm, Chưa kiểm, Giả định, Lệch quy tắc, và một mục "Chỗ tôi không chắc": những
điểm đọc từ mã máy mà bạn còn ngờ, mỗi điểm kèm địa chỉ và thứ cần để kết luận.

Log gốc ở `docs/giao-viec/DH-DOT-1/so-do/`. Không số nào trong báo cáo mà không có log chứa đúng
số đó; số làm tròn thì ghi cả số gốc; "nhanh", "ổn", "không đáng kể" không phải là kết quả. Thứ
chưa đo ghi "chưa đo" kèm lý do, không ước lượng.

Công cụ của bạn có vai phụ thì nên cho một vai đọc lại toàn bộ mã và chạy lại các tiêu chí trước
khi viết `KET-QUA.md`, kết quả ghi `REVIEW.md` cùng thư mục; không có thì tự đọc lại diff một lượt.

## 9. Ngoài phạm vi

Nối vào `client/world`, `client/display`, `control`; lưới đi `.path` và tìm đường (đã có ở
`SRC/nav`, không sửa); vùng cấm động do máy chủ bật; hộp chặn camera; `.region`; sửa hai tệp mẫu ở
`TOOLS/port`. Thấy vấn đề ngoài phạm vi thì ghi vào báo cáo, không tự sửa.
