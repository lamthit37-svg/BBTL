# Cách chép một tệp từ Forge2 và đưa nó qua cổng

Lưu ý ngày 2026-10-08: `check.py` của bộ cpp23 không còn bước hình thức nào (clang-format, độ lồng,
hình dạng) và không còn tham số `--fix`; nó chỉ biên dịch bằng GCC và Clang với `-Werror` rồi chạy
clang-tidy. Các bước dưới đây nhắc `check.py --fix`, độ lồng, tên từ ba ký tự hay trần cột là mô
tả cổng lúc tài liệu được viết: bỏ qua phần hình thức, giữ phần biên dịch, clang-tidy và so với
gốc. Định dạng nếu cần thì gọi thẳng `clang-format -i <tệp>`.

Tài liệu làm việc cho người (hoặc agent) chép mã từ Forge2 (CHỈ ĐỌC, commit d7fcd76; từ 2026-10-08
nằm ở `D:\TÀI LIỆU LÀM VIỆC\code\engine\Forge2`, trước đó `D:\The-Forge\Forge2`)
sang THIENLONG. Đọc cùng `AGENTS.md` (mục 0, 5, 7, 11) và mục "Quy ước chung của mọi tệp chép" của
`docs/NGUON-FORGE2.md`. Tệp mẫu đã qua cổng: `SRC/core/log.cpp`, `SRC/window/monitor.cpp`,
`SRC/gpu/layout.cpp`, `SRC/shader/reflection.cpp`.

## Quy trình cho mỗi tệp (từng tệp một, theo chuỗi `#include`)

Chạy mọi lệnh ở gốc dự án.

1. Đọc TRỌN tệp gốc trong Forge2.
2. `python TOOLS/port/forge2_port.py copy src/<module>/<tệp> SRC/<module>/<tệp>` — đổi namespace
   `forge2` thành `game`, thêm tiền tố `k` cho enumerator, không ghi đè tệp đã có. Enum được ghi nhớ
   sau làm tệp cũ lỗi tên: `python TOOLS/port/forge2_port.py apply SRC/<...>`. Công cụ không xử lý
   enumerator viết trần sau `using enum` và có thể sửa nhầm chữ trong comment: soát tay.
3. `python ~/.claude/cpp23/tools/check.py --fix SRC/<module>/<tệp>` (clang-format, độ lồng ≤ 1, GCC
   và Clang `-Werror`, clang-tidy); sửa tới khi dòng cuối là `1 tệp, 0 lỗi.`. Hỏi include thiếu,
   thừa: `python TOOLS/port/forge2_port.py includes SRC/<module>/<tệp>`.
4. Thêm ở cuối khối comment đầu tệp: `// Nguồn: Forge2 src/<module>/<tệp>@d7fcd76. Khác gốc: <liệt
   kê ngắn, hoặc "không">.` rồi chạy lại check (clang-format tự ngắt dòng dài).

Tệp include header của thư viện ngoài (Vulkan SDK, gói vcpkg) thì truyền thư mục include dạng
`-isystem` qua biến môi trường; dùng `-I` thì clang-tidy soi cả header ngoài và báo lỗi trong đó:

```
INC="C:/VulkanSDK/1.4.363.0/Include"      # hoặc "F:/tl 2026/THIENLONG/vcpkg_installed/x64-windows-static-md/include"
CPP23_G14="g++ -isystem $INC" CPP23_G15="g++ -isystem $INC" CPP23_C20="clang++ -isystem $INC" \
CPP23_TIDY_ARGS="-isystem $INC" python ~/.claude/cpp23/tools/check.py --fix SRC/<...>
```

`check.py` dịch từng tệp ĐỨNG RIÊNG, không có cờ của CMake: macro mà Forge2 khai ở CMake phải nằm
trong mã nguồn (Win32: `#include "core/win32.hpp" // IWYU pragma: keep`, rồi header con).

## Cách sửa cho qua cổng

- GIỮ NGUYÊN hành vi: công thức, toán tử và thứ tự của chúng không đổi. Không "cải tiến", không
  viết lại thuật toán. Chỗ đổi hình dạng ghi `// Khác gốc: ...` ngay tại chỗ.
- `if` nằm trong thân vòng lặp bị cấm (kể cả câu bảo vệ): tách thân vòng lặp thành hàm một lượt
  nhận tham chiếu, đưa điều kiện dừng lên điều kiện lặp, hoặc đổi `if (c) x = v;` thành
  `x = c ? v : x;`. Lambda nhiều dòng trong vòng lặp và lớp cục bộ trong thân hàm: đưa ra ngoài.
- `return ham_void();` trong hàm `void`: tách thành lời gọi rồi `return;` trong ngoặc nhọn.
- Khởi tạo aggregate ghi tên thành viên (`{.x = a, .y = b}`); không lồng khởi tạo trong tham số:
  đặt biến cục bộ trước.
- Tên biến, tham số dưới 3 ký tự (trừ `i j k n id it ok ec dt`) phải đổi; khai báo và định nghĩa
  trùng tên tham số. Hằng `static const` và hằng toàn cục dạng `kTên`.
- Thành viên có `{}` mà clang-tidy báo `readability-redundant-member-init`: bỏ `{}`. Hệ quả đã đo:
  designated initializer bỏ sót trường đó bị `-Wmissing-field-initializers`; nơi dùng khi ấy khai
  biến rồi gán trường.
- GCC `-Wuseless-cast`: bỏ phép ép thừa, kèm `static_assert` nền 64 bit (mẫu ở `core/log.cpp`).
- NOLINT chỉ khi không sửa được mà không đổi thiết kế, đúng dạng: dòng comment nêu LÝ DO và MÃ QUY
  TẮC (ví dụ `(lệch API-03)`, `(LH-07)`, `(lệch KTR-04)`, `(lệch KG-06)`, `(lệch PH-01)`) ngay trên
  `// NOLINTNEXTLINE(<tên-check>)`; vùng dài dùng `NOLINTBEGIN`/`NOLINTEND`. Cấm NOLINT trần, cấm
  tắt cảnh báo, cấm sửa `.clang-tidy`, `.clang-format`, `config/`.
  - `bugprone-exception-escape` trên hàm `noexcept` chủ ý của gốc: NOLINT kèm lý do (LH-07).
  - `bugprone-easily-swappable-parameters`: NOLINT kèm lý do khi thứ tự tham số là quy ước tự nhiên.
  - `readability-identifier-length` trong mã toán (a, b, t, v, m, q): NOLINT vùng kèm lý do.
- Comment và chuỗi thông báo tiếng Việt có dấu; định danh tiếng Anh; dòng ≤ 120 cột; không căn cột.
- Kiểu lỗi `core::Result`, `core::Status`, `core::Error` giữ nguyên.
- Chức năng dự án đã có thì dùng bản của dự án, ghi `Khác gốc:`: `core/check.hpp` (chỉ `check`,
  `debug_check`, `fail`, `assume`; không chép `core/check.cpp`), `io` (`read_text`,
  `path_from_utf8`, `utf8_of`, `use_utf8_console`, `executable_directory`).
- Tệp không dịch được bằng GCC MinGW vì lý do ĐO ĐƯỢC: ghi chính xác thông báo lỗi, kiểm tệp đó
  bằng `--only clang`, không vá bừa.

## Khi nhiều phiên chép song song

- Mỗi phiên chỉ sửa tệp trong danh sách của mình. Cần một tệp mà phiên khác phụ trách: nếu chưa có
  thì làm tệp khác trước rồi chờ (kiểm lại mỗi vài phút); nếu công cụ báo `ĐÃ CÓ` thì KHÔNG sửa
  nó, chờ tới khi `check.py --no-tidy <tệp đó>` sạch rồi dùng.
- Không chạy `cmake` (dùng chung cây build), không sửa `CMakeLists.txt`, `cmake/`, `AGENTS.md`,
  `docs/`, không commit: phiên điều phối làm các việc đó.
- Bẫy công cụ: heredoc Python trong công cụ Bash nuốt `\\` và hỏng khi có dấu `'` lẻ. Sửa tệp
  bằng công cụ sửa tệp, không vá bằng heredoc.
- Hai lần sửa cùng một lỗi không ăn thì dừng thử bừa, tìm nguyên nhân gốc; bế tắc thì dừng tệp đó
  và báo cáo điều đã biết.

## Báo cáo của mỗi phiên chép

1. Tệp đã xong (đích ← nguồn), mỗi tệp một dòng kèm "Khác gốc" như ghi ở đầu tệp.
2. Tệp chưa xong hoặc bị chặn, kèm lỗi cụ thể còn lại.
3. Tệp Forge2 đã chép thêm ngoài danh sách, hoặc quyết định không chép và thay bằng gì.
4. Dòng tổng kết của lần chạy cuối `check.py` trên mọi tệp của phiên (kèm lệnh đầy đủ nếu có biến
   môi trường).
5. Thư viện, cờ liên kết, macro cần cho CMake; module dự án mà các tệp này include.
6. Điều nghi ngờ đáng ghi sổ, mỗi mục một câu.
