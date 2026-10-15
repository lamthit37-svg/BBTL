# Hiến pháp C11/C++23 — luật của máy này

File này là luật chung cho mọi việc C và C++ trên máy này. Mục 0 đến IX là luật của máy, không đổi
theo dự án. Mục X là phần của dự án đang mở, điền lại mỗi khi mở dự án khác.

Số mục là địa chỉ: cổng kiểm `check_style.js` in số mục trong thông báo lỗi, còn checklist và các
skill trỏ tới số mục. Đổi số một mục thì sửa luôn mọi chỗ trỏ tới nó, trong cùng một lần sửa.

## Ba hạng luật — đọc trước mọi mục khác

1. **Tuyệt đối** — chữ *phải*, *cấm*, *không bao giờ*, và mọi luật không ghi hạng. Áp ở mọi quy mô
   việc. Không tự cấp ngoại lệ; gặp chỗ mà làm đúng luật sẽ ra kết quả sai thì dừng lại và hỏi.
2. **Theo quy mô** — luật tự ghi phạm vi "mã đi vào dự án": build và chạy (I.1), test trước
   (VII.6), sanitizer, checklist IX. Trong phạm vi đó chúng tuyệt đối như hạng 1. Câu hỏi lý
   thuyết, đoạn minh hoạ, việc thử nhanh thì được bỏ, nhưng bỏ có ý thức và nói ra phần nào đã bỏ.
3. **Mặc định** — chữ *mặc định*, *ưu tiên*, *nên*. Được chọn cách khác khi tình huống cụ thể làm
   cách mặc định tệ hơn. Khi đó nói lý do một câu trong câu trả lời, và thêm một dòng comment tại
   chỗ nếu lý do không tự hiện ra trong mã.

Hạng 2 là chỗ nghi thức khớp quy mô việc: câu hỏi năm dòng không trả lời bằng checklist chín mục,
còn mã đi vào dự án thì không được thiếu mục nào.

### Khi các nguồn mâu thuẫn

1. Yêu cầu tường minh của người dùng trong phiên thắng file này. Riêng I.2 thì không yêu cầu nào
   gỡ được: bỏ build theo yêu cầu thì vẫn phải nói là chưa build.
2. Sự kiện đã đo trên máy này thắng trí nhớ, ghi chú cũ và sách. Số đo bác ghi chú nào thì sửa ghi
   chú đó, kèm ngày đo.
3. `CLAUDE.md` và cổng kiểm của dự án đang mở thắng luật mặc định của máy ở phần chúng quy định
   (ví dụ Orion ở V.5). Chúng được thêm luật, đổi lệnh, đổi lựa chọn hạng 3; không được nới mục I.
4. Giữa các skill với nhau: VI.1.

Mỗi luật chỉ định nghĩa ở một chỗ. Chỗ khác trỏ tới bằng số mục, không chép lại.

---

## 0. Hình thức văn bản — căn cột, ngôn ngữ, comment

### 0.1 Cấm căn thẳng cột — mọi nơi, không ngoại lệ

Không bao giờ chèn dấu cách hay tab chỉ để ký tự ở các dòng khác nhau rơi vào cùng một cột. Luật
áp cho cả mã nguồn lẫn câu trả lời:

- Trong mã: comment cuối dòng, dấu `=`, tên biến trong khối khai báo, dấu `\` nối dòng của macro,
  giá trị enum, bảng vẽ tay trong comment.
- Trong câu trả lời và tài liệu: danh sách lựa chọn, mô tả option khi hỏi người dùng, cây thư mục,
  bảng ASCII tự kẻ. Bảng Markdown thì được dùng, mỗi ô một dấu cách hai bên, không đệm cho thẳng.
- Cách viết đúng: một dấu cách, hoặc xuống dòng, hoặc dấu `—` ngăn giữa tên và phần mô tả.

Vì sao: căn cột bắt sửa lại cả khối mỗi lần một dòng đổi độ dài, sinh diff rác che mất thay đổi
thật. Và `.clang-format` đặt `AlignTrailingComments: false` cùng mọi `AlignConsecutive*: false`,
nên lần chạy `clang-format` kế tiếp xoá sạch phần căn tay.

Cổng kiểm: V.5 cho mã nguồn; mắt người cho câu trả lời.

Ngoại lệ duy nhất: dữ liệu mà bản thân nó là bảng do chương trình in ra lúc chạy (dòng log, bảng
thống kê console). Đó là hành vi runtime, không phải hình thức mã nguồn.

### 0.2 Ngôn ngữ

Trả lời bằng **tiếng Việt**. Thuật ngữ kỹ thuật giữ nguyên tiếng Anh (pointer, undefined behavior,
linker, overload...), không dịch gượng ép.

Trong code — người dùng là người Việt, đây là yêu cầu thường trực:

- **Comment, chuỗi UI, thông báo, log, output console: tiếng Việt có dấu chuẩn.**
- **Định danh (biến, hàm, class, tên file): tiếng Anh, không dấu.** Định danh có dấu phá debugger
  và symbol name.
- File nguồn lưu UTF-8. Bắt buộc `/utf-8` khi biên dịch và `SetConsoleOutputCP(CP_UTF8)` khi in
  console, thiếu là ra ký tự rác. Chi tiết và cạm bẫy: skill `vn-text`.
- **Luôn chạy thật và nhìn output** trước khi nói là hiển thị đúng.

### 0.3 Comment — chỗ cần thì phải có; tiếng Việt; WHY

Mặc định là viết comment ở những phần cần, không để trống cho "sạch". Codebase sống hàng năm.
Người và agent mở lại file sau sáu tháng phải tìm được module, API và chỗ bất thường bằng grep,
không phải đọc hết file. Comment là một phần của chất lượng, cùng hạng với tên rõ và type đúng.

Comment nói **tại sao, hợp đồng, bất biến, ràng buộc**, không diễn lại điều mã đã nói. `// tăng i`
là rác. `// pak gốc ghi offset little-endian kể cả khi header nói ngược lại, nên không byteswap ở
đây` là comment thật.

**Phải có** — thiếu là thiếu chất lượng:

- **Đầu file:** vai trò module trong hệ thống, quyết định thiết kế đã chốt (kể cả chính sách lỗi,
  III.7), nguồn gốc định dạng hay thuật toán. Tối đa 15 dòng. Changelog, tác giả, ngày, liệt kê
  hàm — để git giữ.
- **API công khai trong `.hpp`:** đúng một chỗ, một câu tiếng Việt cạnh khai báo, nói ý định hoặc
  hợp đồng mà chữ ký chưa nói hết. Trong `.cpp` chỉ comment chi tiết cài đặt. Hai bản mô tả cho
  cùng một hàm chắc chắn sẽ lệch.
- **Mốc tìm trong file dài:** mỗi khối việc khác nhau (parse header, giải nén, ghi index...) một
  dòng `//` tiếng Việt để grep nhảy tới.
- **Chỗ code không tự nói:** tiền điều kiện, bất biến, mutex nào bảo vệ dữ liệu nào, lifetime của
  dữ liệu mượn, lý do một đoạn trông sai nhưng đúng (bẫy định dạng, workaround thư viện, thứ tự
  khởi tạo bắt buộc).

**Cấm:**

- Doxygen (`///`, `/**`, `@param`, `@return`). Dự án nội bộ, không sinh tài liệu; dùng `//` thường.
- `TODO` thiếu mô tả, hoặc có mô tả mà không có mục tương ứng trong `docs/NGHI-NGO.md` (X.6). Dạng
  hợp lệ duy nhất là `// TODO(mô tả ngắn):`. TODO mồ côi là nợ giấu.
- Code chết trong comment. Xoá đi, git nhớ hộ.
- Bảng ASCII kẻ tay trong comment (vi phạm 0.1). Mô tả định dạng nhị phân để trong `docs/`, comment
  chỉ trỏ tới file đó.
- Comment sai hoặc lỗi thời. Sửa code thì sửa comment trong cùng commit, hoặc xoá hẳn. Comment sai
  nguy hiểm hơn thiếu comment.

Diễn đạt được bằng type thì dùng type: `std::chrono::milliseconds timeout` mạnh hơn
`int timeout; // ms`. Khoảng trắng quanh comment do `clang-format` quyết định, không gõ tay.

---

## I. Điều khoản tối cao — chạy thật, không đoán

1. **Không bao giờ bàn giao code C/C++ chưa từng được biên dịch.** Phạm vi là mã đi vào dự án.
   Viết xong là build, build xong là chạy; chưa thấy output thật thì chưa được nói "xong", "đã
   sửa", "sẽ hoạt động". Đoạn vài dòng viết ra chỉ để minh hoạ trong câu trả lời thì không bắt
   buộc build, nhưng phải gọi đúng tên là đoạn minh hoạ chưa biên dịch. Để người đọc tưởng nó đã
   chạy là vi phạm I.2.
2. **Báo cáo trung thực.** Mỗi kết luận nói rõ nó ở trạng thái nào: đã kiểm (kèm output thật), chưa
   kiểm (kèm lý do), hay không kiểm được trên máy này (kèm lý do). Test đỏ thì nói đỏ và dán output.
   Không tô hồng, không dùng "về cơ bản là ổn" để che chỗ chưa kiểm. Không dùng "hoàn hảo", "100%
   an toàn", "không còn lỗi" khi bằng chứng không phủ hết phạm vi mà câu đó nói.
3. **Warning không phải gợi ý.** Trong C/C++, cảnh báo `/W4` thường là bug thật. Đặc biệt: `C4700`
   (biến chưa khởi tạo), `C4244` và `C4267` (mất dữ liệu), `C4018` (signed/unsigned), `D9002` (cờ
   sai bị bỏ qua âm thầm).
4. **Không đoán API.** Không nhớ chắc chữ ký hàm, tên target, tên port, hay mức hỗ trợ của một tính
   năng C++ thì tra hoặc build thử một file 10 dòng, không bịa. Bịa API là lỗi nặng hơn nói "tôi
   cần kiểm tra".
5. **Mọi code là production grade.** Không có chế độ "code nháp": vẫn `const` đúng chỗ, vẫn xử lý
   lỗi, vẫn RAII, vẫn build sạch warning. Cái được phép thay đổi theo quy mô là kiến trúc, không
   phải chất lượng. Chiều ngược lại cũng đúng: production grade không có nghĩa là thêm nghi thức.
   Đừng nhét `expected`, concept hay một lớp bọc vào hàm 20 dòng chỉ để khớp bảng III.2.
6. **Phép kiểm phải chứng minh được là nó đã chạy.** Exit code 0 không phải bằng chứng:
   `/std:c++23` exit 0 mà biên dịch ở C++14 (II.1), `cl /fsanitize=undefined` exit 0 mà không có
   sanitizer nào (II.2). Đọc hết output và tìm `D9002`. Dựng cấu hình sanitizer hay cổng kiểm mới
   thì cài thử một lỗi cố ý, thấy nó bị bắt, rồi gỡ ra.
7. **Đúng và an toàn đứng trên hiệu năng và kích thước**, ở mọi dự án và mọi hồ sơ tối ưu. Thứ tự
   phân xử chi tiết giữa các trục nằm ở skill `cpp23-standard`, không chép lại ở đây. Không đổi hợp
   đồng API, ABI hay định dạng dữ liệu đã ghi ra đĩa hoặc mạng, trừ khi đó chính là nhiệm vụ.

---

## II. Máy và toolchain — sự kiện đã đo

Mục này giữ các bẫy âm thầm: những chỗ lệnh vẫn exit 0 mà kết quả sai. Danh mục công cụ đầy đủ
(phiên bản, đường dẫn) ở `%USERPROFILE%\.claude\bin\TOOLCHAIN.md`, hook `SessionStart` tự nạp.
Đừng mò lại đường dẫn.

### II.1 Chuẩn ngôn ngữ và cờ nền

- **Chọn chuẩn C++23 theo cách gọi trình biên dịch, không trộn hai cách:**
  - Gọi `cl` trực tiếp (file lẻ, thử nhanh) → `/std:c++23preview`, cho `__cplusplus` = `202302`.
    `/std:c++23` KHÔNG tồn tại: `D9002`, exit code vẫn 0, rồi im lặng tụt về C++14 (`__cplusplus`
    = `201402`). Đây là cái bẫy tốn nhiều giờ nhất của toolchain này.
  - Qua CMake với `cxx_std_23` → CMake phát `-std:c++latest` nhưng **không tự thêm
    `/Zc:__cplusplus`**, nên `__cplusplus` bằng `199711`, đúng giá trị của C++98, và mọi thư viện
    dò tính năng bằng `#if __cplusplus >= ...` âm thầm chọn nhánh sai. Mọi target bắt buộc khai báo
    cờ nền tường minh qua `target_compile_options`; khi đó `__cplusplus` ra `202400`.
  - **Không thêm `/std:` vào `CMAKE_CXX_FLAGS`**: chồng cờ sinh cảnh báo `D9025`.
- **Cờ nền:** danh sách đầy đủ nằm trong module chất lượng CMake (X.1), không chép lại ở đây để
  khỏi lệch. Tối thiểu phải có `/W4`, `/utf-8` và `/Zc:__cplusplus`. Gọi `cl` trực tiếp thì tự gõ
  ba cờ đó cùng `/std:c++23preview`.
- `clang-format` chỉ có trên PATH sau `dev.bat`. Mọi lệnh build, và cổng kiểm V.5, chạy sau
  `dev.bat`.

### II.2 Sanitizer — đã đo ngày 2026-09-08, đừng đoán lại

| Sanitizer | Dùng được? | Cách gọi |
|---|---|---|
| ASan | có | `cl /fsanitize=address /Zi` — MSVC tự lo runtime DLL |
| UBSan | có, chỉ qua clang-cl | `clang-cl -fsanitize=undefined /Zi` — bắt UB kèm file:line |
| TSan | KHÔNG | clang-cl báo `unsupported option` cho target `x86_64-pc-windows-msvc` |
| MSan | KHÔNG | clang-cl không hỗ trợ target Windows |
| LSan | KHÔNG | clang-cl báo unsupported |
| sanitizer của gcc | chưa đo | bảng này từng ghi máy không có gcc, nhưng lần đo 2026-09-09 thấy gcc 16.2.0 của MSYS2 (VIII) |

**Bẫy chết người:** `cl` **nuốt im lặng** `/fsanitize=thread`, `/fsanitize=undefined`,
`/fsanitize=memory`: chỉ ra `D9002 ignoring unknown option`, exit code vẫn 0, chương trình build
xong mà KHÔNG có sanitizer nào. Muốn UBSan thì phải đổi hẳn trình biên dịch sang `clang-cl`.

**ASan với `/RTC1`:** `cl /fsanitize=address /RTC1` biên dịch sạch, exit 0 (đo 2026-09-08). Đó mới
là biên dịch được, chưa phải chạy đúng (I.6), và tài liệu Microsoft vẫn ghi `/RTC` không tương
thích với ASan, incremental linking và Edit-and-Continue cũng không được hỗ trợ. Build ASan tắt
`/RTC1` và dùng `/INCREMENTAL:NO`, cho tới khi có phép đo chứng minh ngược lại. Cấu hình Debug của
CMake bật sẵn cả hai: cờ biên dịch Debug có `/RTC1`, cờ link Debug có `/INCREMENTAL` (đọc trong
`Windows-MSVC.cmake` của CMake 3.28, chưa đối chiếu bản 4.4.3), nên phải gỡ tường minh.

Không có TSan → data race phải loại bằng thiết kế dễ đọc (III.4), `/analyze` và đọc code. Đừng hứa
"chạy TSan xem sao", và đừng ghi "đã kiểm race" khi mới chỉ đọc code.

### II.3 Quy ước chạy

- Dự án thật → **CMake 4.4.3 + Ninja 1.13.2**, luôn generator Ninja. Cả hai là bản độc lập thắng
  trên PATH (`C:\Program Files\CMake\bin` và WinGet Links), **không phải** bản đi kèm Build Tools.
  Ghi chú nào ghi 3.31.6 và 1.12.1 là cũ. Máy không có IDE nên generator Visual Studio gần như vô
  nghĩa ở đây.
- Thư viện ngoài → **vcpkg manifest mode**. `%VCPKG_ROOT%` = `...\18\BuildTools\VC\vcpkg` (bản
  2026-07-27), do `dev.bat` đặt sẵn. Bản độc lập ở `C:\vcpkg` cùng phiên bản nhưng là **clone
  nông**: lịch sử của nó không chứa commit `builtin-baseline` mà `vcpkg.json` ghim. Trỏ vào đó thì
  mọi gói đỏ với `failed to git show versions/baseline.json`, rồi CMake báo tiếp là không tìm thấy
  compiler lẫn Ninja, một thông báo không nói gì về nguyên nhân thật (đo 2026-09-09).
- **Một lần configure hỏng để lại cache hỏng.** Lần chạy sau dùng lại cache ấy và báo
  `unable to find a build program corresponding to "Ninja"` cộng `CMAKE_CXX_COMPILER not set`, kể
  cả khi nguyên nhân gốc đã sửa xong. Xoá hẳn thư mục build rồi configure lại, đừng đi sửa
  `dev.bat`.
- Chạy exe phải có `.\` phía trước, thiếu là "is not recognized" dù file nằm ngay đó.
- 12 core → luôn build và test song song; `dev.bat` đã đặt sẵn hai biến parallel.

Quy trình build của dự án đang mở ở X.3; quy trình chung ở skill `cpp-build`.

---

## III. Chuẩn ngôn ngữ — C++23 và C11 dùng cho đúng

**Mặc định C++23**; C thuần thì **C11**. Không tự ý hạ chuẩn.

### III.1 Nguồn sự thật về mức hỗ trợ

Trí nhớ về "MSVC có tính năng X chưa" không được coi là bằng chứng. Trước khi đưa một tính năng
C++23 vào dự án: kiểm bằng feature-test macro (`__cpp_lib_expected`, `__cpp_lib_print`,
`__cpp_lib_generator`, `__cpp_lib_flat_map`, `__cpp_lib_mdspan`...) hoặc build thử một file nhỏ.
Chưa xanh thì dùng phương án C++20 tương đương và nói rõ là đã fallback.

Đã kiểm thật trên MSVC 19.51 ngày 2026-09-09, dùng được ngay: `std::expected`, `std::print`,
`std::println`, `std::format`, `std::span`, `std::byteswap`, `std::generator`, `std::mdspan`,
`std::stacktrace`, `std::ranges::zip`, `std::flat_map`, `std::flat_set`, `std::start_lifetime_as`.

Ba cái cuối mới có từ toolset 14.51; ghi chú nào nói chúng không có là cũ. Lối chữa cháy cho chúng
(`std::vector<std::pair<K, V>>` đã sắp xếp thay `flat_map`, `std::memcpy` thay
`start_lifetime_as`) đang có trong mã thì không cần vội gỡ. Nhưng đừng viết mới theo lối đó rồi ghi
lý do là "máy không hỗ trợ".

**Bẫy khi dò: `__has_include` nói dối về `<flat_map>`.** Header nằm sẵn trong bộ STL nên
`__has_include(<flat_map>)` trả về `1` ngay cả khi đang biên dịch ở C++14, tức khi lỡ dùng
`/std:c++23`, trong khi `std::flat_map` không tồn tại. Luôn dò bằng feature-test macro.

### III.2 Idiom mặc định — cột phải là mặc định, lệch thì nói lý do

| Thay vì | Dùng |
|---|---|
| trả mã lỗi `int` rồi bỏ qua | `std::expected<T, E>`, `std::optional<T>`, hoặc exception (III.7) |
| `printf` hoặc `std::cout << ... << std::endl` | `std::println`, `std::print`, hoặc `std::format` |
| `const char* p, size_t n` | `std::span<T>`, `std::string_view` |
| `new` và `delete` trần | giá trị trực tiếp, `std::unique_ptr`, container chuẩn |
| SFINAE, `enable_if` | `concepts` kèm `requires` |
| viết tay 6 toán tử so sánh | `operator<=>` mặc định (`= default`) |
| vòng lặp index thủ công nhiều tầng | `<ranges>` và views, chỉ khi làm code rõ hơn |
| `#define` hằng số hoặc hàm nhỏ | `constexpr`, `consteval`, `inline constexpr` |
| `std::thread` kèm join/detach tay | `std::jthread` kèm `std::stop_token` |
| C-cast `(T)x` | `static_cast`, `const_cast`, `reinterpret_cast` có lý do |
| `enum` không định kiểu | `enum class` |

- Bảng là mặc định cho **code mới** (hạng 3), không phải nghĩa vụ refactor: code cũ đang chạy đúng
  không bị đem đi sửa chỉ để khớp bảng (VII.1). Trong tình huống cụ thể mà cột phải làm code khó
  đọc hơn thì chọn cột trái, kèm một câu lý do.
- Riêng `new`/`delete` trần và C-cast là hạng 1, vì cổng V.5 chặn cứng. Cần cấp phát thô cho
  allocator hay pool thì hỏi trước: cổng chưa có cơ chế miễn trừ.
- `[[nodiscard]]` cho mọi hàm mà bỏ qua giá trị trả về là bug. `[[maybe_unused]]` thay cho
  `(void)x`.
- Tính được ở compile time thì tính ở compile time, nhưng không biến code thành trò template chỉ
  để khoe.
- `switch` trên `enum` phải phủ hết case, không `default` bắt bừa: `default` giết mất cảnh báo khi
  thêm enumerator mới.

### III.3 Tính năng phải cân nhắc, không dùng phản xạ

- **Modules và `import std;`** — chỉ khi dự án thật cần và **đã build xanh thật** trên máy này.
  CMake kèm MSVC còn nhiều ràng buộc; chưa chứng minh được thì dùng header, không bàn giao nửa vời.
- **Coroutine** — chỉ khi bài toán đúng là async hoặc generator. Không dùng cho vòng lặp thường.
- **`ranges` chuỗi dài** — một biểu thức pipe 6 tầng vi phạm mục V. Tách ra.
- **`shared_ptr`** — chỉ khi sở hữu **thật sự** chung. Mặc định là `unique_ptr` hoặc giá trị.
- **Template metaprogramming nặng, toán tử tự định nghĩa** — cần lý do đo được, không phải sở
  thích.

### III.4 Vòng đời, sở hữu và đồng thời — kỷ luật bắt buộc

- **Sở hữu phải rõ ở mức chữ ký hàm.** Nhìn signature phải biết ai giữ, ai mượn.
- `string_view`, `span`, reference và con trỏ thô là **mượn**: không lưu vào member, không trả về
  từ hàm nếu nguồn là temporary, không giữ quá vòng đời nguồn. Dangling ở đây là UB im lặng.
- **RAII cho mọi tài nguyên**: file, mutex, `HANDLE`, socket, bộ nhớ. Không có cặp acquire/release
  gọi tay.
- Rule of zero là mặc định. Phải viết destructor thì viết luôn cả 5, hoặc `= delete` cho rõ ý định.
- Sau `std::move`, đối tượng chỉ được huỷ, gán lại, hoặc gọi thao tác không có tiền điều kiện
  (`clear()`), trừ khi kiểu đó hứa rõ trạng thái sau move.
- Khởi tạo thất bại phải để lại trạng thái xác định. Mặc định: constructor ném, hoặc factory trả
  `std::expected`; không để lại đối tượng nửa sống.

**Đồng thời** — không có "chắc là an toàn":

- Mỗi mutex có comment ngay cạnh khai báo nói nó bảo vệ dữ liệu nào. Dữ liệu chung mà có thể đổi
  thì luôn đọc ghi dưới khoá đó, hoặc là `atomic`.
- Lấy nhiều khoá cùng lúc thì dùng một `std::scoped_lock` cho cả nhóm. Lấy lần lượt thì ghi một thứ
  tự khoá cố định ở một chỗ, và mọi nơi theo đúng thứ tự đó.
- `atomic` ghi rõ memory order, mặc định `seq_cst` cho tới khi đo được là nút cổ chai. Hạ xuống
  `acquire`/`release` hay `relaxed` thì comment cặp happens-before mà nó dựa vào.
- `volatile` không phải đồng bộ.
- Mọi luồng có chủ sở hữu và đường dừng: `std::jthread` kèm `std::stop_token`. Không `detach`.
- "Lock-free" là tuyên bố cần chứng minh, không phải hệ quả của việc dùng `atomic`.

### III.5 C thuần (C11)

- `restrict`, `_Static_assert` khi hợp lý. Không VLA. Không `gets`, `strcpy`, `sprintf`.
- Mọi `malloc` và `realloc` phải kiểm null; `realloc` không gán đè lên con trỏ cũ.
- `size_t` cho kích thước và index. Không trộn signed/unsigned trong so sánh.
- Không dịch trái số âm: trong C đó là UB.
- `goto cleanup` là hợp lệ và được khuyến khích trong C để thoát lỗi một đường.

### III.6 Chung

- `const` là mặc định. Khởi tạo tại chỗ khai báo. Phạm vi hẹp nhất có thể.
- Khởi tạo bằng `{}` để compiler chặn narrowing. Thu hẹp kiểu có chủ ý thì kiểm phạm vi trước rồi
  mới `static_cast`.
- Số học trên kích thước hay dữ liệu ngoài: kiểm tràn **trước** khi tính, không phải sau. Kiểm mẫu
  số bằng 0. Số bit dịch phải không âm và nhỏ hơn độ rộng của kiểu.
- Ưu tiên **thư viện chuẩn** hơn tự viết, và **đơn giản** hơn thông minh.
- Không `using namespace` trong header (cổng V.5 chặn). Không `using namespace std;` ở phạm vi file
  trong dự án thật.

### III.7 Lỗi và dữ liệu từ bên ngoài

- Mọi đường có thể thất bại có chính sách rõ, chọn theo ngữ nghĩa: `std::expected` cho lỗi mà
  người gọi xử lý ngay, `std::optional` cho "không có" mà không phải lỗi, exception cho lỗi phải
  vượt nhiều tầng. Chính sách của module ghi ở comment đầu file (0.3).
- Phân biệt bốn loại lỗi: phục hồi được (file không tồn tại), cấu hình, dữ liệu hỏng, vi phạm bất
  biến. Vi phạm bất biến là bug: assert hoặc dừng, không "phục hồi" rồi chạy tiếp.
- Cấm nuốt lỗi: `catch (...) {}` rỗng, bỏ qua `expected`, đổi lỗi thành giá trị mặc định mà không
  báo.
- Mỗi API nói được mức exception safety của nó (no-throw, strong, basic). `noexcept` chỉ đặt cho
  hàm thật sự không ném.
- Thông báo lỗi đủ ngữ cảnh để chẩn đoán (đường dẫn, offset, giá trị nhận được) và không chứa dữ
  liệu nhạy cảm (mật khẩu, token, nội dung riêng của người dùng).
- Dữ liệu từ file, mạng, dòng lệnh, biến môi trường là **không tin cậy**. Kiểm kích thước, độ dài,
  chỉ số và giới hạn cấp phát trước khi dùng. Một trường độ dài đọc từ file không bao giờ đi thẳng
  vào `resize` hay vào lời gọi cấp phát.
- Thao tác có thể dừng giữa chừng (ghi file, cập nhật nhiều cấu trúc) phải có đường rollback, hoặc
  ghi ra bản tạm rồi mới thay bản thật.
- Retry có giới hạn số lần. Timeout và huỷ được xử lý ở tầng sở hữu thao tác.

### III.8 Hiệu năng

- Không tối ưu khi chưa có mục tiêu đo được và chỗ nghẽn đã đo. Không đo ở Debug.
- Đo ở Release, trên dữ liệu đại diện, so với baseline, lặp đủ lần. Một lần đo đơn lẻ không phải
  kết luận.
- Thuật toán, cấu trúc dữ liệu và data locality trước micro-optimization.
- Bản tối ưu phải ra cùng kết quả với bản cũ trên cùng đầu vào, và câu trả lời có số trước/sau.
- Lợi ích của phương án phức tạp không đủ lớn thì giữ phương án đơn giản.
- Công cụ và quy trình đo: skill `cpp-perf`. Hồ sơ tối ưu và ngân sách của dự án: X.1.

---

## IV. Bố cục và đặt tên

- **Header nằm CẠNH file nguồn.** `src/core.hpp` cạnh `src/core.cpp`. **Không tách `src/` với
  `include/`**: đã chốt, vì tách ra khó phát triển. Dự án lớn chia theo **module**
  (`src/render/`, `src/net/`), mỗi thư mục đủ cả `.hpp` lẫn `.cpp`. Ngoại lệ duy nhất: thư viện có
  `install(EXPORT)` cho người ngoài, phải hỏi trước.
- `#pragma once` ở đầu mọi header.

### IV.1 Tên — ngắn, đọc là hiểu

Định danh tiếng Anh, không dấu (0.2). Tên của API nền (Win32, STL, POSIX) giữ đúng chính tả của nền
đó. Một kiểu chữ cho cả máy:

- Hàm, biến, namespace, concept: `snake_case`. Concept theo lối thư viện chuẩn (`std::integral`).
- Type và enumerator: `PascalCase`.
- Hằng mới: `kPascalCase`. Macro: `SCREAMING_CASE` kèm tiền tố dự án (`ENGINE_ASSERT`). Dự án đã
  hô hằng bằng `SCREAMING_CASE` thì giữ, không trộn kiểu mới vào dự án đó.
- Tham số template: `T` khi chỉ có một kiểu và vai trò hiển nhiên, `PascalCase` cho phần còn lại.

Độ dài cùng hạng với tên rõ. API, type, hàm, file: một hoặc hai từ. Từ thứ ba chỉ khi bỏ đi thì
trùng tên khác hoặc mất miền. `parse_header`, `load_config`, `byte_count`, `NetClient`,
`net_client.cpp`. Cấm chuỗi mô tả (`get_the_current_user_display_name`), cấm dính chữ
(`netclient`, `parseconfig`), cấm hậu tố phiên bản (`impl_v2`, `data2`). Phạm vi vài dòng thì tên
ngắn là đúng: `i`, `n`, `it`, `ok`. Không kéo chỉ số vòng thành `current_element_index`.

Hàm là động từ, hoặc động từ kèm danh từ. Giá trị là danh từ. Bool đọc như câu hỏi: `is_ready`,
`has_header`. Danh từ đã đủ thì không gắn `get_` hay `set_`: `count()`, không `get_count()`. Viết
tắt chỉ khi từ đó đã là từ của C++ và POSIX: `id`, `url`, `utf8`, `json`, `min`, `max`, `io`. Cấm
viết tắt tự chế: `cnt`, `buf`, `cfg`, `tmp`, `msg`, `req`, `ptr`, `mgr`, `idx`. Không tiền tố
Hungarian (`m_`, `p_`, `g_`, `s_`). Hậu tố `_` cho member private chỉ khi cả dự án đã dùng. Code cũ
đang chạy đúng không đổi tên chỉ để khớp mục này (VII.1).

### IV.2 Module và phụ thuộc

- Mỗi module có trách nhiệm và hướng phụ thuộc xác định. Cấm phụ thuộc vòng. Dự án có cổng kiểm
  tầng (như `check_layers.py` của Orion) thì cổng đó là nguồn sự thật về tầng.
- Định dạng nhị phân, serialization, giao thức: hợp đồng ghi rõ phiên bản, kích thước từng trường,
  endian, căn lề và cách xử lý phiên bản lạ. Hợp đồng nằm trong `docs/`, comment trỏ tới (0.3).
- Mặc định không sửa mã third-party trong cây nguồn. Cần vá thì vá qua overlay port hoặc patch của
  vcpkg, để lần cập nhật sau không xoá mất.
- Thêm thư viện ngoài qua vcpkg manifest có baseline ghim (II.3, skill `cpp-deps`). Câu trả lời ghi
  lý do chọn và giấy phép của thư viện.

---

## V. Hình dạng code — phải PHẲNG

Luồng điều khiển phải phẳng: đường thực thi chính nằm thẳng ở lề ngoài cùng. Đây là luật trôi
nhanh nhất nếu không canh, nên nó có cổng kiểm tự động ở V.5 chứ không dựa vào mắt người.

### V.1 CẤM TUYỆT ĐỐI — tối đa MỘT cấp lồng

**Trong một hàm chỉ được phép đúng một cấp khối điều khiển.** Được `for (...) { ... }`. KHÔNG được
`for (...) { if (...) { ... } }`. Chạm cấp 2 là bắt buộc tách hàm, không phải thụt thêm lề.

Hình dạng bị cấm tuyệt đối, đúng nguyên văn dạng này:

```cpp
// SAI — bốn thứ sai cùng lúc, xem giải thích ngay dưới
{
    std::vector<std::jthread> threads;
    for (unsigned i = 0; i < workers; ++i) {
        threads.emplace_back([&] {
            for (...) {
                if (clip) ...;
            }
        });
    }
}
```

Bốn lỗi: khối phạm vi trần chỉ để giới hạn vòng đời; lambda viết thẳng trong vòng lặp; vòng lặp
lồng vòng lặp; thân lambda dài hơn một dòng. Cách viết đúng: đặt tên cho công việc của lambda thành
một hàm riêng, và gói vòng đời vào một lớp RAII hoặc một hàm, chứ không phải một cặp ngoặc nhọn
trần.

Không tính là một cấp: guard clause một dòng (`if (!p) continue;`, không mở khối), khối viết gọn
hết trong một dòng, và nhánh `else if` của cùng chuỗi điều kiện.

Tách hàm là đặt tên cho một việc thật. Chuyển phần lồng vào lambda, macro hay khối phạm vi chỉ để
cổng kiểm không nhìn thấy là né luật, nặng hơn vi phạm gốc.

### V.2 Luật viết từng dòng

- **Guard clause và early return trước.** Xử lý lỗi và trường hợp biên ở đầu hàm rồi `return` hoặc
  `continue` ngay. Không bọc thân hàm trong một `if` khổng lồ. Không `else` sau `return`.
- **Guard clause ngắn viết một dòng**, không tách ra hai: `if (!p) return -1;`,
  `if (n == 0) continue;`. Không bắt thêm ngoặc nhọn cho thân một câu lệnh.
- **Thân guard phải nằm gọn một dòng.** Không đủ chỗ thì rút ngắn thông điệp hoặc tách một hàm phụ
  có tên, không để nó tự xuống dòng rồi thụt sâu thêm.
- **Không lồng hàm gọi hàm nhiều tầng trong một biểu thức.** `f(g(h(x)))` phải tách thành biến
  trung gian có tên nói rõ nghĩa. Mỗi dòng làm một việc đọc được.
- Vòng lặp lồng vòng lặp → tách vòng trong thành hàm riêng có tên.
- `switch` hoặc bảng tra thay cho chuỗi `else if` dài. Máy trạng thái phức tạp → tách hàm theo từng
  trạng thái.
- Điều kiện phức hợp → đặt tên trước: `const bool is_ready = a && b && !c;` rồi mới
  `if (is_ready)`.
- Không lồng toán tử ba ngôi.
- Một hàm làm **một việc**, đọc hết được trong một màn hình. Tên hàm là động từ mô tả đúng việc đó.

### V.3 Ba hình dạng đã tái phạm — cấm viết lại

1. **Lồng khởi tạo trong lời gọi hàm.**
   `fresh.push_back(IndexEntry{.key = ..., .location = FileLocation{...}})` sinh hai bậc thụt. Đặt
   tên cho giá trị trước rồi mới gọi.
2. **Lồng `std::format` trong tham số.** `checked_count(a, b, std::format("...", x, y))` cũng vậy.
   Tính nhãn ra một biến `label` trước.
3. **Guard clause tràn dòng.** Đã nói ở V.2; đây là chỗ nó tái phạm nhiều nhất, vì thông điệp lỗi
   tiếng Việt dài. Rút ngắn thông điệp, đừng nới lề.

Cách chữa một vi phạm **luôn** là đặt tên cho phần trung gian, rút ngắn thông điệp, hoặc tách hàm.
Không bao giờ là nới `ColumnLimit` hay sửa `.clang-format`.

### V.4 `.clang-format` — bất biến, cấm sửa

**Không sửa file `.clang-format` vì bất cứ lý do gì.** Ba giá trị dưới đây đã đo bằng số lần vi
phạm thật; đổi là code lập tức trôi thành bậc thang.

- `AlignAfterOpenBracket: DontAlign`. **Không dùng `AlwaysBreak`.** Cả hai đều bỏ căn cột, nhưng
  `AlwaysBreak` bắt xuống dòng ngay sau dấu `(` rồi mới thụt, nên một guard clause dài biến thành
  ba bậc: `if` ở cột 4, `return fail(` ở cột 8, tham số ở cột 12. `DontAlign` giữ tham số đầu ngay
  sau dấu ngoặc và chỉ thụt một bậc cho phần tràn. Đã đo: riêng giá trị này cắt số chuỗi ba bậc từ
  102 xuống 40.
- `ColumnLimit: 100`. Thông điệp lỗi tiếng Việt phải viết ngắn để `return fail(...)` không tràn.
- `SeparateDefinitionBlocks: Leave`. `Always` chèn một dòng trống giữa **mọi** định nghĩa, kể cả
  accessor một dòng trong lớp, làm header giãn gấp đôi chiều dọc.

`AlignTrailingComments` và mọi `AlignConsecutive*` giữ nguyên `false`: chúng là thứ thi hành mục
0.1 ở mức công cụ.

### V.5 Cổng kiểm — chạy TỰ ĐỘNG trước mỗi lần build

Cổng mặc định của máy:

```
node %USERPROFILE%\.claude\bin\check_style.js <thư-mục-nguồn>
```

Cổng viết bằng Node.js (lý do ở VIII); đừng viết lại bằng Python. Mã thoát đã đo: **1 khi có vi
phạm, 0 khi sạch**, nên gắn vào CMake là chặn được thật. Cách gắn ở X.3.

**Cổng phải chạy SAU `dev.bat`.** Phép kiểm thứ nhất gọi `clang-format`, thứ chỉ vào PATH sau
`dev.bat` (II.1). Gọi thẳng từ PowerShell thì cổng đỏ với `'clang-format' is not recognized` (đo
2026-09-09); đó là lỗi môi trường, không phải mã bẩn.

**Dự án được phép mang cổng riêng, và khi đó cổng riêng thắng.** Mở một dự án thì đọc `CLAUDE.md`
của nó trước khi cho rằng cổng nằm ở `~/.claude/bin`. Ví dụ Orion (`D:\EngineGAME`): cổng là
`python tools/check_style.py`, gắn vào CMake qua target `orion_check_style` mà `engine_core` phụ
thuộc, và chạy **năm** phép kiểm chứ không phải bốn — thêm `check_layers.py` (include đi sai tầng)
và `check_tracked.py` (tệp nguồn bị `.gitignore` nuốt).

Bốn nhóm phép kiểm của cổng mặc định, bắt bốn thứ khác nhau và không thay thế được cho nhau:

1. **Định dạng** — `clang-format --dry-run -Werror`, khớp `.clang-format` từng ký tự. Dự án chưa
   có `.clang-format` thì cổng tự dùng bản chính thức ở
   `%USERPROFILE%\.claude\bin\clang-format.template`, không im lặng rơi về style LLVM mặc định.
2. **Cấp lồng** — cấp lồng thứ hai (cả dạng có ngoặc lẫn `for (...) for (...) x;`) và khối phạm vi
   trần.
3. **Bậc thang** — do dòng nối tiếp, phát biểu theo **mức thụt lề**:
   - R1: một câu lệnh dùng tối đa HAI mức thụt lề khác nhau.
   - R2: nếu có hai mức thì mức sâu phải đúng bằng mức đầu cộng 4.
4. **Luật hiến pháp mà `clang-format` không biết** — mỗi luật trỏ về mục ban hành nó:
   - Doxygen `///`, `/**`, `@param`, `@return` — mục 0.3
   - comment đầu file quá 15 dòng — mục 0.3
   - `TODO` thiếu mô tả, hoặc có mô tả nhưng thiếu mục trong `docs/NGHI-NGO.md` — mục 0.3
   - `new` hoặc `delete` trần — mục III.2
   - C-cast sang kiểu nguyên thuỷ — mục III.2
   - `using namespace` trong header — mục III.6
   - header thiếu `#pragma once` — mục IV

Đếm theo mức là điều quan trọng ở phép kiểm 3. Một lời gọi trải năm dòng mà mọi tham số cùng một
mức thì đọc vẫn phẳng; một câu lệnh ba dòng ở ba mức thì đúng là bậc thang. Cùng lý do đó, thân
`enum` và thân lambda không bị báo nhầm. Ghi chú nào nói "bậc thang phải nhìn bằng mắt" là cũ.

**Cổng kiểm không phải trình phân tích cú pháp C++.** Giới hạn đã biết ghi ở cuối
`check_style.js`. Gặp báo sai thì sửa bộ quét hoặc tách đoạn code đó ra, **không bao giờ** nới
`.clang-format` (V.4).

---

## VI. Skills — dùng đúng lúc, không dùng cho có

Bảng dưới là **định tuyến**, không phải thủ tục bắt buộc. Nạp skill khi thật sự cần thứ nó giữ:
lệnh chính xác, đường dẫn, con số đã đo, luật ngôn ngữ. Câu trả lời được ngay bằng file này cộng
`TOOLCHAIN.md` thì không nạp; nạp cho có chỉ đốt context và làm chậm việc.

| Tình huống | Skill |
|---|---|
| **Viết code C++23 mới, thiết kế type hay API, chốt idiom, phân xử giữa hai phương án** | **`cpp23-standard`** |
| Build, compile, chạy, lỗi toolchain | `cpp-build` |
| Tạo dự án mới, scaffold | `cpp-new-project` |
| Thêm thư viện, vcpkg, `find_package` | `cpp-deps` |
| Crash, sai kết quả, rò rỉ, nghi UB | `cpp-debug` |
| Viết và chạy test, ctest | `cpp-test` |
| Chậm, tối ưu, benchmark | `cpp-perf` |
| Viết code mới, refactor, chọn idiom | `cpp-modern` |
| Soát lỗi, audit, trước khi commit | `cpp-review` |
| Bất kỳ mã C2xxx, C4xxx, LNK, STL4xxx nào | `msvc-errors` |
| Win32, cửa sổ, `HANDLE`, DLL, Unicode | `win32-native` |
| Tiếng Việt có dấu trong comment, UI, log, console; chữ ra ký tự rác | `vn-text` |
| Lý thuyết C++ sâu: object model, move và elision, template và concepts, exception safety, ABI, memory model, coroutine, module | `cpp23-mastery` kèm `references/` |
| Lý thuyết C sâu: UB catalog, provenance, alignment, allocator, ABI và wire format, signal safety | `c-mastery` kèm `references/` |
| Tự kiểm chứng lại thay đổi vừa làm | `check-work` |
| Review khi người dùng yêu cầu | agent `cpp-reviewer`; không spawn cho đủ lễ (VII.9) |

### VI.1 Phân vai giữa ba nhóm — không được nhầm

- `cpp23-standard` là **LUẬT**: bốn trục ổn định, chất lượng, tốc độ, kích thước; thứ tự phân xử
  khi chúng xung đột; bảng chi phí đã đo. Trả lời "phải chọn cái nào". Không được đặt hiệu năng
  hay kích thước lên trên tính đúng và an toàn (I.7).
- Nhóm `cpp-*` (đã chạy thật trên máy này) là **VẬN HÀNH**: lệnh chính xác, đường dẫn, cờ MSVC,
  quy trình. Trả lời "gõ cái gì".
- Nhóm `*-mastery` là **NGỮ NGHĨA**: vì sao code sai, luật ngôn ngữ, mức nghiêm trọng. Trả lời
  "vì sao".

**Khi hai bên mâu thuẫn: sự kiện về MÁY NÀY luôn thắng.** Bộ `*-mastery` viết cho toolchain đa nền
tảng. Trên máy này `rr`, `valgrind`, `epoll` không có; `gcc` và `gdb` chỉ có qua MSYS2 và không
thuộc cổng C++ (VIII); `clang-cl` có nhưng chỉ dùng cho UBSan (II.2). Quy đổi: `-Wall -Wextra`
thành `/W4`; `-fsanitize=address` thành `/fsanitize=address`; "chạy gdb" thành mục tương ứng trong
`cpp-debug` (ASan, `/analyze`, log). Lấy phần *lý lẽ*, bỏ phần *lệnh*.

### VI.2 Về CONSTITUTION.md của `cpp23-mastery` và `c-mastery`

Hai file đó tự tuyên bố "MANDATORY audit mỗi lần đụng C/C++". Trên máy này lời đó không còn hiệu
lực. Chúng là sách tra ngữ nghĩa, không phải vòng review thứ hai. Nạp khi đang tra một lỗi ngôn
ngữ (dangling, ABI, memory model). Sau khi code thì đọc lại file (VII.9), không chạy audit chồng.

---

## VII. Cách làm việc

1. **Không phình phạm vi.** Làm đúng thứ được yêu cầu. Thấy vấn đề khác thì *nói*, đừng tự sửa lan
   man.
2. **Không cấu trúc doanh nghiệp cho bài tập nhỏ.** File 50 dòng không cần abstract factory. Không
   dựng interface cho một implementation duy nhất. Quy mô giải pháp phải khớp quy mô bài toán,
   nhưng chất lượng thì không hạ (I.5).
3. **Sửa nguyên nhân, không dán băng dính lên triệu chứng.** Thêm `if (p != nullptr)` mà không trả
   lời được *vì sao* `p` null là chưa sửa xong.
4. **Không tự ý xoá hay ghi đè** file người dùng, không `git clean -xfd`, không commit hay push khi
   chưa được yêu cầu. Nhìn vào file trước khi ghi đè. Thao tác không đảo ngược được (xoá dữ liệu,
   đổi cấu hình quan trọng, phát hành) chỉ làm khi được yêu cầu.
5. Việc chạy lâu (vcpkg build lần đầu, LTCG) → **báo trước**, chạy nền, đừng huỷ giữa chừng rồi bảo
   là hỏng.
6. Feature mới hoặc sửa bug → viết test **trước**, xác nhận **đỏ**, rồi viết code, rồi xác nhận
   **xanh**. Chi tiết ở skill `cpp-test`.
7. Giải thích ngắn gọn *tại sao*, không thuyết giảng lại kiến thức người dùng đã có.
8. **Nghi thức khớp quy mô việc** — xem "Ba hạng luật" ở đầu file. Hỏi lại chỉ khi hai cách hiểu
   dẫn tới hai kết quả khác hẳn nhau; còn lại thì chọn phương án hợp lý, nói rõ giả định, và làm.
9. **Đọc lại file vừa sửa, một lượt.** Sau khi code, đọc nhanh đúng các file vừa chạm: tên (IV.1),
   toán tử, đường thoát lỗi, comment còn khớp mã không. Đó là một lượt đọc. Không mở review thứ hai
   và không spawn `cpp-reviewer` cho đủ lễ. Review đầy đủ chỉ khi người dùng yêu cầu (VII.12).
10. **Fork và port.** Trước khi viết, đọc mã tham chiếu ở source gốc của đoạn đang chuyển. Giữ
    nguyên toán tử tính toán (`+`, `-`, `*`, `/`, `%`, dịch bit, so sánh), thứ tự của chúng và kiểu
    dữ liệu. Cải tiến (đổi thuật toán, gộp phép, đổi kiểu) chỉ sau khi cùng đầu vào đã ra cùng kết
    quả với toán tử gốc.
11. **Đọc trước khi sửa.** Đọc implementation, hợp đồng, call site và phụ thuộc trực tiếp của chỗ
    sắp sửa. Nói được nguyên nhân gốc trước khi chọn cách sửa. Thay đổi chạm ABI, định dạng dữ
    liệu, đồng thời hay hiệu năng thì nói ra ảnh hưởng đó trước khi làm.
12. **Khi người dùng yêu cầu review.** Correctness, UB, memory safety, data race, security và rò rỉ
    tài nguyên trước thẩm mỹ. Mỗi phát hiện ghi vị trí, điều kiện kích hoạt, hậu quả và bằng
    chứng, và nói rõ là đã xác nhận, có căn cứ, hay mới là giả thuyết. Một nguyên nhân gốc là một
    phát hiện. Không báo lỗi chỉ vì khác sở thích khi không chỉ ra được tác hại. Quy trình: skill
    `cpp-review`, agent `cpp-reviewer`.

---

## VIII. Môi trường

- Shell chính: **PowerShell 5.1**. Không có `&&`, `||`, ternary; dùng `;` và `if ($?) {}`. Không
  có `head`, `tail`, `which`, `touch`.
- Lệnh build đi qua `cmd /c "call dev.bat && ..."` vì cmd có `&&`.
- File tạm để trong thư mục scratchpad của phiên, **không** rải vào `C:\Users\myhea`.
- **Có sẵn, đo lại ngày 2026-09-09:** git 2.55, Node.js 24.20, VS Code, Git Bash, PowerShell 5.1,
  Python 3.13.15, MSYS2 (gcc 16.2.0, g++, gdb 17.2, `mingw32-make`), Go 1.27.1.
- **Python là 3.13, gọi bằng `py`; `python` trần là bản cũ 3.11.9.** Hai bản không dùng chung
  site-packages, nên `pip install X` rồi `py script.py` là `ModuleNotFoundError`; cài gói bằng
  `py -m pip`. CMake `FindPython3` tự nhặt đúng 3.13.15.
- **Không có trên cổng C++:** Visual Studio IDE, Docker, Rust/cargo, Perl, Ruby, `make` dưới đúng
  tên đó (chỉ `mingw32-make` của MSYS2). 7-Zip và JDK Temurin 25 có trên máy (`TOOLCHAIN.md`) nhưng
  không đi qua `dev.bat` và không dùng cho C++. gcc và gdb của MSYS2 cũng vậy.
- **WSL2 chạy được từ 2026-09-24** (bản MSI 2.7.13); ghi chú nào nói `wsl.exe` hỏng với
  `REGDB_E_CLASSNOTREG` là cũ. Trạng thái, cách sửa và công tắc hypervisor cho LDPlayer ở
  `TOOLCHAIN.md` mục WSL.
- **Script công cụ của máy viết bằng Node.js**, không phải vì thiếu Python mà vì `node` có trên
  PATH ngay từ đầu phiên.

---

## IX. Checklist bàn giao — chưa đủ thì chưa được nói "xong"

Checklist này là hạng 2: áp cho **mã đi vào dự án**. Mục nào không dính tới việc vừa làm thì bỏ
qua, bỏ có ý thức và nói ra ở mục 8, chứ không diễn lại cho đủ lệ. Đổi một hằng số thì không cần
ASan; sửa một comment thì không cần dựng test. Hai mục không bao giờ bỏ được là 3 và 8.

1. Build với cờ nền ở II.1 → **0 warning**, không chỉ 0 error.
2. Cổng kiểm ở V.5 xanh (dự án đã gắn vào CMake thì tự chạy cùng build, xem X.3; chưa gắn thì chạy
   tay).
3. Đã chạy thật, **đã dán output thật** vào câu trả lời.
4. Test chạy qua. Feature mới hoặc sửa bug: test mới đã **đỏ trước, xanh sau**.
5. Code đụng bộ nhớ hoặc con trỏ → ASan ở Debug (X.5). Nghi UB số học hay lifetime → UBSan qua
   `clang-cl` (X.5). `cl /fsanitize=undefined` không tính là đã kiểm.
6. Có tiếng Việt trong output → đã nhìn tận mắt console hiển thị đúng dấu.
7. Không còn `new` hay `delete` trần, không còn cấp lồng thứ hai, tên khớp IV.1. Comment khớp 0.3:
   có ở chỗ cần, nói *tại sao* chứ không diễn lại *cái gì*.
8. Đã nói rõ phần nào **chưa** kiểm và vì sao.
9. Đã đọc lại nhanh các file vừa sửa (VII.9). Fork hoặc port: đã đọc mã gốc và giữ toán tử
   (VII.10).

**Báo cáo cuối** cho mã đi vào dự án có bốn phần; phần nào trống thì ghi "không có":

- **Đã làm** — thay đổi thật và phạm vi của nó.
- **Đã kiểm** — phép kiểm đã chạy, kèm output thật.
- **Chưa kiểm** — phần chưa chạy, vì sao, và rủi ro còn lại.
- **Tồn đọng** — vấn đề còn lại liên quan trực tiếp tới nhiệm vụ.

---

## X. Phần riêng của dự án đang mở — KHUÔN, điền khi mở dự án

Mục 0 đến IX là luật của **máy**, không đổi. Mục X là luật của **dự án**, thay mỗi khi mở dự án
khác. Ô nào chưa điền thì dùng mặc định ghi ngay tại ô đó.

### X.1 Danh tính dự án

Workspace hiện tại là Desktop (`C:\Users\myhea\Desktop`), không phải repo C++. Khi **mở một dự án
C++**, điền các dòng dưới trong `CLAUDE.md` của repo đó, đừng để trống:

- Tên dự án — *chưa điền (workspace = Desktop)*
- Thư mục gốc — *chưa điền*
- Hồ sơ tối ưu theo `cpp23-standard` mục 0.1 — `app` cho tới khi có tuyên bố khác
- Ngân sách kích thước — *không có*; có thì ghi bằng số, ví dụ "DLL ≤ 300 KB"
- Module chất lượng CMake — `%USERPROFILE%\.claude\bin\cmake-quality.cmake`
- Reviewer — agent `cpp-reviewer` (`~/.claude/agents/cpp-reviewer.md`)

### X.2 Bố cục

Theo IV: header nằm **cạnh** file nguồn, không tách `src/` với `include/`. Dự án lớn chia theo
module (`src/render/`, `src/net/`), mỗi thư mục đủ cả `.hpp` lẫn `.cpp`.

### X.3 Build và cổng kiểm

Dự án chưa điền thì dùng mặc định này, chạy từ thư mục gốc dự án:

```
cmd /c "call dev.bat && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug && cmake --build build"
```

Gắn cổng V.5 thành target chạy trước khi biên dịch, đỏ là build dừng. Thay `app` bằng từng target
biên dịch của dự án:

```cmake
# Cổng kiểm V.5: chạy trước khi biên dịch app, đỏ là build dừng.
file(TO_CMAKE_PATH "$ENV{USERPROFILE}" user_home)
add_custom_target(check_style
    COMMAND node "${user_home}/.claude/bin/check_style.js" "${PROJECT_SOURCE_DIR}/src"
    VERBATIM)
add_dependencies(app check_style)
```

Đoạn này đã chạy thử với CMake 3.28 và Ninja 1.11 trên Linux, với một cổng giả: cổng đỏ thì không
file nào được biên dịch, kể cả khi build `-j 12`. Chưa chạy trên Windows.

- Lệnh build của dự án — *chưa điền*
- Lệnh cổng kiểm của dự án — *chưa điền*; mặc định là V.5

### X.4 Test

- Khung test — *chưa điền*
- Lệnh test — *chưa điền*; mặc định `ctest --test-dir build --output-on-failure`, sau `dev.bat`
- Quy trình test trước: VII.6 và skill `cpp-test`.

### X.5 Sanitizer

- Build ASan — *chưa điền*; mặc định là một thư mục build riêng, Debug, theo II.2 (`/RTC1` tắt,
  `/INCREMENTAL:NO`) và skill `cpp-debug`.
- Build UBSan — *chưa điền*; mặc định là một thư mục build riêng dùng `clang-cl` (II.2).

### X.6 Sổ nghi ngờ — `docs/NGHI-NGO.md`

Mọi `// TODO(mô tả ngắn):` trong mã phải có một mục tương ứng ở đây, nếu không nó là nợ giấu
(0.3). Mỗi mục ghi: chỗ nghi ngờ, vì sao chưa chắc, và cần gì để kết luận.

Chưa có file này thì tạo khi có TODO đầu tiên, đừng tạo rỗng sẵn.
