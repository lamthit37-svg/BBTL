# Gameplay máy chủ, đợt 1: đề bài chung cho mọi vai

Soạn 2026-10-14. Chủ dự án giao: "triển khai hoàn thành hết toàn bộ các phần của server, dựa source
gốc và bản 14 môn phái, liên kết sắp xếp bố trí dựng những phần còn thiếu sót. Mục đặt cao nhất và
đáng tin nhất chính là client 2026". `G:\XJL7457` là server 14 môn phái (bản private, đã sửa; xem
`docs/AUDIT/G-XJL7457.md` và `docs/AUDIT/evidence/xjl7457_config_coverage.md`).

Đề bài này là phần chung. Mỗi vai có thêm một đoạn riêng trong prompt giao việc. Đọc kỹ trước khi viết.

## 1. Thứ bậc nguồn (khi hai nguồn nói khác nhau, nguồn trên thắng)

1. **Client 2026** — nguồn đáng tin nhất. Cây đã giải: `F:\tl 2026\_goc` (`Config` 726 bảng DBC, `Interface`
   layout + script Lua của giao diện, `Scene`). Bảng đã xuất sang TSV: `dev/server/tables/shared/*.tsv`
   (id, cột, số dòng của client). Script Lua giao diện giải bằng `TOOLS/content/lua_plain.py` cho biết
   client HỎI máy chủ điều gì và hiển thị gì; đó là hợp đồng nhìn thấy được. Mã máy của client:
   `F:\tl 2026\2026\Bin64` (Ghidra/`pe_refs.py` khi cần). Id kỹ năng, vật phẩm, quái, nhiệm vụ, môn phái
   (0..15, không có 9) lấy từ client; máy chủ KHÔNG đặt id riêng.
2. **Máy chủ 14 môn phái `G:\XJL7457\Server\rootfs\home\tlbb`** — dữ liệu phía máy chủ mà client không có
   (`Public/Config`, `Server/Config`, `Public/Scene/*_monster.ini` ..., `Public/Data/Script` 5.494 tệp
   Lua, `AIScript`). Chỉ có binary Linux (không symbol, không source): chỉ ĐỌC dữ liệu và Lua, KHÔNG chạy
   exe, KHÔNG nối IP trong cấu hình của nó, KHÔNG chép nguyên văn script/binary vào repo (chỉ trích
   dữ liệu thành bảng/TSV của dự án). Nó đã bị sửa bởi nhà phát hành riêng (thư mục `XYJ_*`, `XiaoXiang_*`,
   `RuMeng`, `JiuFeng`... là phần thêm ngoài bản gốc): bỏ qua phần đó trừ khi client 2026 cũng có.
3. **Source máy chủ gốc 2008** `G:\TLBB\_ref\server\Server` (GameServer, WorldServer, LoginServer...) và
   `G:\TLBB\_ref\server\Common`: công thức và máy trạng thái. Chỗ lệch với hành vi client 2026 thì client
   thắng; ghi `Khác gốc:` đầu tệp port.
4. **TLBB Dev `G:\TLBB\Dev`** (`docs/LOGIC.md`, `NHIEM-VU.md`, `src/combat`, `src/server`, `src/walk`,
   `src/tables`): thiết kế đã duyệt cho ops/ledger/quest/dialogue, mã M1 nhỏ. Port nếu hợp, ghi nguồn.
5. Bản 0859602 đã nhập sẵn vào `dev/server/tables/server/*.tsv` và `dev/server/config/rules/*.toml`
   (xem `docs/SERVER-TEP-CAU-HINH.md`, `TOOLS/server/table_names.tsv`).

Môn phái: client 2026 có 15 phái (ID 0-8 và 10-15; 9 là "không phái"). Bản XJL7457 chỉ có 14 (không có
phái 15, `MenPaiAttackRefix.txt` chỉ 9 phái cũ). Chỗ máy chủ XJL7457 thiếu dữ liệu cho phái 10-15 thì
suy từ bảng client 2026 (kỹ năng, tâm pháp của chúng có đủ) và ghi rõ giá trị nào là số tự đặt cần chủ
dự án duyệt — không bịa lặng.

## 2. Luật dự án (đã nạp trong CLAUDE.md/AGENTS.md; nhắc những điều hay sai)

- Gọi skill `cpp23` và đọc `~/.claude/cpp23/MAP.md` TRƯỚC khi viết C++. C++23, 0 cảnh báo (MSVC `/W4`+ bộ
  cờ của `game::warnings`; GCC/Clang `-Werror` qua `check.py`), không `throw`, không UB, hostile input.
- Logic game tất định: không `<random>`, không đồng hồ thật, không thứ tự `unordered_*` ảnh hưởng kết quả.
  Ngẫu nhiên: `dice::Dice` (`src/server/dice`) do bên gọi đưa vào. Thời gian: `ids::Tick`/`TickSpan`
  (`src/shared/ids/ids.hpp`), 20 tick/giây, đổi mili giây bằng `ids::to_ticks`. Id: `ids::*Id`. Tiền và số
  lượng là số nguyên có kiểu, không số thực. Xác suất: số nguyên phần nghìn/phần triệu.
- Lõi (thư viện bạn viết) KHÔNG include `net`, `store`, đọc đồng hồ thật hay đĩa ngoài hàm nạp bảng:
  nạp bảng đưa vào bằng `std::string_view` nội dung TSV hoặc `table::Tsv`; test chạy được không cần mạng,
  database, hay thư mục dữ liệu (ca đọc bảng thật tự bỏ qua khi thiếu `dev/server/tables`, như test hiện có).
- Dữ liệu từ client/tệp/mạng không bao giờ vào `check`/`assert`/`.at()`: kiểm biên rồi trả lỗi
  (`std::expected` + `enum class` lỗi). Hàng đợi có trần, vòng lặp có trần theo số liệu do bên ngoài quyết định.
- Mỗi trạng thái bền (nhân vật, túi, nhiệm vụ...) phải có `encode`/`decode` nhị phân little-endian CÓ SỐ PHIÊN
  BẢN, bộ giải mã chống đầu vào thù địch (độ dài, số phần tử, chặn cấp phát theo số client/tệp khai), và test
  vòng đi-về + test byte cắt cụt/bậy. `store` sẽ lưu các khối này nguyên văn (mục 7 `KE-HOACH-SERVER.md`).
- Test: theo luật `Test` của CLAUDE.md — viết cho logic thuần mà sai thì hỏng thầm (công thức, máy trạng
  thái, bộ giải mã, bảng xác suất), hồi quy khi sửa bug. Không dựng test cho mỗi file. Test nằm ở
  `Test/<Domain>/<tên>_tests.cpp`, dùng `Test/test.hpp` (xem `Test/Dice/dice_tests.cpp` làm mẫu), đỏ trước xanh sau
  cho logic có công thức gốc. Số vàng từ công thức gốc: tính độc lập (Python hoặc tay từ mã 2008), ghi
  nguồn trong comment, KHÔNG sinh từ chính mã C++ đang thử.
- Định danh tiếng Anh không dấu; comment, log, thông báo tiếng Việt có dấu, nói TẠI SAO. Port ghi
  `Nguồn:` và `Khác gốc:` đầu tệp.
- Không phình phạm vi: không thêm tính năng ngoài vai; nhưng KHÔNG cắt phạm vi vai: làm trọn.
- Không commit, không push, không đụng `git`. Không sửa mã client (`src/client`, `engine`), mã gate/account/
  protocol/service, `CMakeLists.txt` gốc, tệp sinh của protocol. Không xoá tệp của người khác.

## 3. Bố cục và cách gắn module

- Module = thư mục `src/server/<m>/` (hoặc `src/shared/<m>/` nếu client cũng cần), `x.hpp` cạnh `x.cpp`,
  include `"<m>/x.hpp"`, header nội bộ ở `detail/`. Tên module KHÔNG trùng module client hiện có
  (`quest`, `skill`, `hero`, `look`... là của client; dùng `mission`, `ability`, `actor`... cho máy chủ).
- Gắn vào CMake bằng HAI tệp riêng của bạn (không sửa `CMakeLists.txt` gốc):
  - `cmake/server/<m>.modules.cmake`: `game_module(<m> src/server/<m>/a.cpp ...)` + `target_link_libraries`
    (mẫu: `cmake/server/dice.modules.cmake`). Module chỉ link tầng dưới.
  - `cmake/server/<m>.tests.cmake`: `game_test(<tên> game_<m> ...)` (mẫu: `dice.tests.cmake`); test là
    `Test/<Domain>/<tên>_tests.cpp`.
  - Thêm MỘT dòng `set(game_layer_<m> "core ... <m>")` vào `cmake/GameLayers.cmake` (module chỉ được
    include các module liệt kê ở đây) và tên module vào `game_server_names` (`CMakeLists.txt` dòng ~131)
    hoặc `game_shared_names`: hai chỗ này là chung, sửa bằng Edit một dòng, đọc lại ngay trước khi sửa vì có vai khác
    cùng sửa. Nếu hết cách thì ghi vào báo cáo để người điều phối thêm.
- Tầng dưới có sẵn: `core` (error, log, text, number, check...), `table` (`Tsv`, `RowReader`), `ids`, `dice`,
  `config`, `nav`, `collision`, `protocol`. Module của bạn có thể dựa vào module khác của đợt này chỉ khi đề
  bài vai nói rõ.

## 4. Dựng và kiểm (mỗi vai một cây dựng RIÊNG, không dùng `build/msvc-release`)

```
TOOLS\server\with_dev.bat cmake --preset msvc-release -B build\ag-<vai> -DVCPKG_MANIFEST_INSTALL=OFF
TOOLS\server\with_dev.bat cmake --build build\ag-<vai> --target <tên>_tests
build\ag-<vai>\<tên>_tests.exe
python ~/.claude/cpp23/tools/check.py <các tệp đã đổi>     (GCC + Clang -Werror + clang-tidy)
```
Gọi bằng công cụ PowerShell (Git Bash làm hỏng `cmd /c`). Cấu hình lại khi thêm tệp cmake. Chạy lâu thì chạy nền.
Xong việc: xoá `build\ag-<vai>`. Chạy việc nặng tuần tự (máy 64 GB vẫn hết bộ nhớ khi chạy song song nhiều clang-tidy).
Đo `check.py` trên tệp của bạn; lỗi của tệp người khác không phải việc của bạn.

## 5. Dữ liệu

- Bảng đã nhập: `dev/server/tables/{shared,server,client}`, cảnh: `dev/server/scenes/<tên>`, luật khoá:
  `dev/server/config/rules/*.toml`. Cột chưa đặt tên còn dạng `column_N`; hãy đối chiếu bằng dữ liệu, bảng gốc
  2008 (loader trong `GameServer` đọc theo thứ tự cột) và Lua client để gán nghĩa, rồi ghi nghĩa vào comment
  của bộ đọc.
- Thiếu bảng/dòng so với client 2026 hoặc XJL7457: viết công cụ nhập Python `TOOLS/server/import_<m>.py`
  (đọc nguồn chỉ-đọc, ghi TSV vào `dev/server/tables/server/` theo định dạng của các tệp hiện có: dòng
  `# schema 1`, `# source:`, `# tool:`, `# types:`, rồi tên cột) kèm `test_import_<m>.py`. Không sửa
  `table_names.tsv`, `build_data.py` (người điều phối nối sau). `python TOOLS/server/lint_py.py` phải xanh
  (hàm ≤ 50 dòng, lồng ≤ 3). Chạy `thienlong_lint` (target có sẵn) để bảng của bạn qua bộ kiểm chung.
- Số tự đặt (không có trong nguồn nào) phải đứng ở MỘT bảng/TOML riêng có cột `basis` = `made_up`, không rải
  trong mã, để chủ dự án duyệt.

## 6. Báo cáo cuối (bắt buộc, ngắn, trung thực)

Kết quả (Hoàn thành/Một phần/Bị chặn) / Đã làm (module, hàm công khai chính, bảng đọc, số dòng dữ liệu phủ) /
Kiểm chứng (lệnh + kết quả thật: build 0 cảnh báo, test đạt, `check.py`) / Chưa làm và vì sao / Số tự đặt /
Khác gốc. Kèm tệp tài liệu `docs/SERVER-<VAI>.md` (API công khai, luồng dùng, bảng đọc, giới hạn) — người
điều phối nối module vào `zone`/`world` dựa vào tệp này, nên nó phải đủ để dùng mà không đọc mã.
