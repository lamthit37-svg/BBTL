# TAILIEU — tài liệu phân tích client gốc và suy ra cho máy chủ

Chủ dự án chốt ngày 2026-10-13: mọi tài liệu phân tích mã máy của client gốc (kể cả phần suy ra cho máy chủ) nằm ở
thư mục này. Tài liệu cũ ở `docs/` giữ nguyên chỗ (xem chỉ mục cuối).

## Nguồn và công cụ

- Client gốc: `F:\tl 2026\2026` (3.71, `Bin64\Game.exe`, `Render.dll`, `OgreMain.dll`, `CEGUIBase.dll`,
  `UI_CEGUI.dll`). Cây đã giải gói, tên gốc: `F:\tl 2026\_goc`. Chỉ đọc. Đo 2026-10-15: thư mục `F:\tl 2026\2026` không còn. `Game.exe`
  của nó (dựng 2026-09-29) còn trong dự án Ghidra và ở `D:\rea\work\client\Game.exe`. Cây client đầy đủ còn trên đĩa là `D:\XTLBB` (`Bin`,
  `Bin64`, `Data`, tệp `(version)` ghi 3.71.9509), nhưng là bản dựng 2026-08-11, khác `Game.exe` đã trích (`GAME-EXE-2026/README.md`).
- `LuaPlus.dll` của client (`D:\XTLBB\Bin64`, đo 2026-10-15): lõi Lua 5.0.1 (chuỗi `$Lua: Lua 5.0.1 Copyright (C) 1994-2003 Tecgraf,
  PUC-Rio $`; xuất `lua_getgcthreshold`, `lua_getn`, `lua_dostring`, không có `lua_gc`), số là `double` (`?GetNumber@LuaObject@LuaPlus@@QEBANXZ`),
  thêm kiểu chuỗi rộng của LuaPlus (`lua_pushwstring`, `lua_towstring`, `lua_iswstring`). 497 hàm xuất, 144 hàm C API thuần.
- Mọi thứ của Ghidra nằm trong một thư mục `Desktop\ghidra` (gom 2026-10-13): bản chạy
  `ghidra_12.1.4_PUBLIC\`, dự án `projects\TLBB` (đã phân tích đủ cả năm tệp trên, thêm `CEGUIFalagard.dll`),
  `scripts\` (`ExportProof.java`, `check_proof.py`, `run_ui.bat`, các tệp `keys-*.txt`: xuất bằng chứng của bốn DLL) và
  `export\` (kết quả `*.proof.txt` của lần xuất đó). Nhập lại Game.exe: `TOOLS\port\ghidra\import_game.bat` (khoảng 5 phút).
- Đọc hàm: `TOOLS\port\ghidra\decompile.bat <chương trình> <tệp ra> <khoá>...` với khoá `0xĐịaChỉ`, `s:chuỗi`,
  `x:0xĐịaChỉ`, `n:tên`, `l:tên`, `v:lớp`, `i:chuỗi`, `a:0xĐịaChỉ`, `e:0xĐịaChỉ` (giải thích ở đầu
  `TOOLS\port\ghidra\DecompileAt.java`). Dự án Ghidra bị khoá khi đang mở: chạy lần lượt.
- Địa chỉ của Ghidra và địa chỉ `.pdata` của `TOOLS\port\pe_refs.py` có thể khác nhau về ranh giới hàm (Ghidra gộp
  mảnh `.pdata` vào hàm mẹ). Địa chỉ giữa hàm không phải điểm vào: kiểm bằng `pe_refs.py func`.
- Script Lua gốc mã hoá: `python -B TOOLS/content/lua_plain.py "F:/tl 2026/_goc" build/lua-2026` (không vào git; bản đọc UTF-8 của Interface).
  Đủ 3 173 script (Interface và Config), UTF-8, tách từ gói của client `D:\XTLBB`: `src/client/script/` (`NGUON.txt`; lệnh
  `TOOLS/content/unpack_scripts.py --utf8`; byte GBK gốc: chạy không có `--utf8`).

## Tệp

| Tệp | Nội dung |
|---|---|
| `DANG-NHAP-GOC.md` | Máy trạng thái thủ tục Login → CharSel → CharCreate → ChangeScene → Enter → Main, đo từ mã máy; việc đã nối vào client và việc còn thiếu |
| `MAY-CHU-SUY-RA.md` | Suy ra cho máy chủ: chuỗi gói tin đăng nhập gốc, mã kết quả, dữ liệu mỗi bước cần, đối chiếu với protocol của dự án |
| `GOI-TIN-DANG-NHAP.md` | Trường của từng gói tin đăng nhập (sinh bằng `TOOLS\port\ghidra\packet_fields.py`) |
| `TOC-DO-NAP-SO-VOI-TLBB.md` | Tốc độ nạp cảnh Đại Lý cùng giao diện: THIENLONG so với client G:\TLBB, cách đo, số từng lượt, ảnh bằng chứng (`anh/`), đường nạp mới và đo trước sau |
| `MAN-CHOI-GIAO-DIEN-2026.md` | Giao diện màn chơi: con trỏ trong exe, bản đồ lớn và bản đồ thế giới (FalagardSceneMap, FalagardWorldMap), hòm đồ và ô tiền, xoay người mẫu, phông có dấu Việt, nướng mặt đất, thư viện hiệu ứng |
| `SU-KIEN-GAME.tsv` | Bảng id sự kiện giao diện (651 dòng): `PushEvent(id)` trong Game.exe ↔ tên mà script Lua đăng ký |
| `ghidra\*.txt` | Bản decompile thô làm bằng chứng (đọc kèm địa chỉ trong các tài liệu) |
| `GAME-EXE-2026\` | Bản trích phân tích đầy đủ của `Game.exe` (REA + Ghidra, 2026-10-14): pseudo-code 57 195 hàm, đồ thị gọi, chuỗi kèm hàm tham chiếu, 4 549 lớp RTTI với cây kế thừa và vtable, bảng opcode và trường của 1 367 gói tin, bản đồ 261 tệp nguồn gốc, 598 bảng dữ liệu, 6 055 hàm script Lua với hàm cài đặt; `SO-SANH.md` ở đó so từng mục với client hiện tại (đã có / chưa có / sai, đủ từng hàng ở `so-sanh\*.tsv`); `README.md` ở đó ghi cột, giới hạn và lệnh chạy lại (`TOOLS\port\rea\`) |

## Chỉ mục tài liệu cũ ở `docs/`

`docs/TAO-NHAN-VAT-2026.md` (màn tạo nhân vật), `docs/CAMERA-2026.md` (camera, màn đăng nhập),
`docs/GIAO-DIEN-2026.md` (widget CEGUI), `docs/DUONG-DI-2026.md`, `docs/VA-CHAM-2026.md`,
`docs/NGHI-NGO.md` (sổ nghi ngờ; mục 40 và 46 đã có kết luận ở
`DANG-NHAP-GOC.md`). Riêng `docs/NHIEM-VU-VO-CONG-2026.md` đang VẮNG sau vụ mất
cây 2026-10-09 (bản cũ ở `docs/KHOI-PHUC-2026-10-09/chua-du/docs/`); code
`src/client/book/*`, `Test/Quest`, `Test/Skill`, `TOOLS/port/oracle/*` vẫn trỏ tới
tên đó nên chưa đổi đường dẫn.
