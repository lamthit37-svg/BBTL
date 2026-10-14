# Game.exe 2026 — bản trích phân tích đầy đủ

Bản trích toàn bộ phân tích tĩnh của `Game.exe` (client Thiên Long Bát Bộ 2026, bản dựng `Temp_Release_v3-71-9001`) để tra cứu
và dựng lại hành vi mà không cần mở Ghidra. Sinh bằng REA 6.4.0 trên Ghidra 12.1.4 ngày 2026-10-14; mọi tệp ở đây do
`TOOLS/port/rea/game_exe_dump.py` sinh ra, không sửa tay.

- Tệp phân tích: `Game.exe`, 18 614 816 byte, SHA-256 `3f8bb47de0bc0b233421ebd96957c23209ba1f7ee4924902de0511439ba1a9d6`, PE32+ x86-64,
  image base `0x140000000`, 9 đoạn (`.text` `0x140001000..0x140a3a800`).
- `F:\tl 2026\2026\Bin64` đã bị xoá (2026-10-09). Tệp còn nằm trong dự án Ghidra `C:\Users\myhea\Desktop\ghidra\projects\TLBB` (chương trình
  `Game.exe`, dấu thời gian PE 2026-09-29, VERSIONINFO `0, 85, 0, 0`) và đã xuất lại một bản ở `D:\rea\work\client\Game.exe` (không nằm trong
  repo). Xuất lại: `TOOLS\port\rea\export_original.cmd Game.exe <đích>`.
- Đo 2026-10-15: chương trình `Game.exe` của dự án Ghidra TLBB có SHA-256 trùng tệp này và đường nhập `F:/tl 2026/2026/Bin64/Game.exe`
  (`getExecutableSHA256`, `getExecutablePath`), nên đây đúng là tệp mà `TOOLS\port\ghidra\decompile.bat` đọc.
- **Mã và tài liệu của dự án trích địa chỉ của ít nhất hai bản dựng.** Bản thứ hai là `D:\XTLBB\Bin64\Game.exe` (3.71.9509, 18 583 584 byte,
  SHA-256 `62e0174f…`, dấu thời gian PE 2026-08-11). 9 địa chỉ (19 dòng) là đầu hàm của bản ấy, và mã của chúng nằm ở bản này với độ lệch
  +0x310 tới +0x1bf0. Khoảng 87 địa chỉ không hợp lệ ở cả hai bản (`docs/NGHI-NGO.md` mục 53). Tra hàm bằng tên script (`lua_api.tsv`), chuỗi
  assert, lớp (`classes.tsv`), đừng tra thẳng bằng địa chỉ trích trong mã.
- Hàm trong tệp gần như không có tên (bản phát hành đã strip): chỉ RTTI, chuỗi assert, tên import và vài tên Ghidra tự đặt. Mọi thứ dưới đây
  được suy ra từ những dấu vết đó.

## Các tệp

| Tệp | Nội dung | Số dòng |
|---|---|---|
| `overview.json` | số đếm, 9 đoạn, tóm tắt | |
| `functions.tsv` | mọi hàm: địa chỉ, loại (`internal`/`thunk`/`external`), tên, đích thunk, `end_hint` (địa chỉ hàm kế tiếp, gần đúng), `source_file` (suy ra), `vslot` (`Lớp#chỉ số` nếu là ô vtable), số hàm gọi tới, số hàm được gọi | 58 035 |
| `decompile.zip` | pseudo-code Ghidra của 57 195 trên 57 200 hàm nội bộ, 39 tệp `.c` theo khoảng địa chỉ, mỗi hàm một dòng đầu `// ==== <địa chỉ> <tên> [<tệp nguồn>] <vslot>` | 63,4 MB giải nén, 6,7 MB nén |
| `disasm/*.asm` | disassembly của 5 hàm mà decompiler bỏ cuộc (xem Giới hạn) | 5 tệp |
| `callgraph.tsv` | người gọi → các hàm được gọi trực tiếp (`EXTERNAL:0x..` là import, tra ở `imports.tsv`) | 43 785 hàng, 127 565 cạnh |
| `strings.tsv` | mọi chuỗi Ghidra định nghĩa: địa chỉ, các hàm tham chiếu (gần đúng, xem dưới), giá trị đã thoát `\\ \t \n \r` | 56 190 |
| `imports.tsv` | 835 import: địa chỉ giả `EXTERNAL:`, DLL, ký hiệu (`MSVCR110.DLL` 162, `KERNEL32.DLL` 138, `TENGINE.DLL` 122, `MSVCP110.DLL` 84, `USER32.DLL` 82, `LUAPLUS.DLL` 80, `WS2_32.DLL` 35, `ADVAPI32.DLL` 30, `FMOD64.DLL` 24...; đo lại 2026-10-14, bản trước ghi 135/48/36 là sai) | 835 |
| `names.tsv` | tên Ghidra có nghĩa (đã bỏ nhãn `LAB_`, `UNWIND_`, `switchD_`, `s_`, RTTI/vftable — lớp nằm ở `classes.tsv`) | 31 014 |
| `classes.tsv` | 4 549 lớp có vftable: địa chỉ, số ô, danh sách lớp cơ sở (từ RTTI, gồm gián tiếp, theo thứ tự `Class Hierarchy Descriptor`), địa chỉ từng ô ảo | 4 549 |
| `packets.tsv` | 1 367 gói tin `Packets::*`: **opcode** (`GetPacketID`), kích thước cố định, vftable, dạng `Read`, danh sách trường `offset:size`, hàm `Read`/`Execute`, tệp handler nếu suy ra được | 1 367 |
| `sources.tsv` | 261 đường dẫn nguồn gốc `...\Prj\GameCode\Client\Game\...` (từ chuỗi assert) kèm số hàm tham chiếu và hàm đầu/cuối | 261 |
| `data_files.tsv` | 692 tên tệp dữ liệu client đọc (598 bảng `.txt`, `.skill`, `.scene`...) kèm hàm tham chiếu | 692 |
| `lua_register.tsv` | 19 hàm gọi `LuaPlus::LuaObject::Register`, kèm định danh chuỗi chúng tham chiếu (5 908 định danh, phần lớn là tên hàm script; có lẫn tên như `__index`) | 19 |
| `lua_api.tsv` | MỖI hàm script Lua: bảng/đối tượng, tên, địa chỉ cài đặt (`impl`), loại cài đặt (hàm / rỗng / chuyển tiếp ô ảo), cách đăng ký, nhãn lỗi `LUA:Lớp::Hàm`, tệp nguồn, ghi chú đăng ký trùng; do bước `lua` dựng từ disassembly của hàm đăng ký lớn nhất và pseudo-code của 18 hàm còn lại | 6 055 |
| `lua_tables.tsv` | 120 bảng/đối tượng Lua, biến toàn cục script thấy, số hàm đăng ký | 120 |
| `SO-SANH.md`, `so-sanh/` | so Game.exe với client hiện tại: đã có / chưa có / sai, từng mục một (`SO-SANH.md` đọc được, `so-sanh/*.tsv` đủ từng hàng, `tong-hop.json` số tổng); do `TOOLS/port/rea/compare_client.py` sinh | |
| `resources.json` | tài nguyên PE (icon, con trỏ, version, manifest, chuỗi) | |

Định dạng chung: TSV UTF-8, dòng đầu là tên cột, địa chỉ viết `0x140...`.

## Đã đối chiếu

- Opcode `CGConnect` = 456 và `GCConnect` = 796, `CGConnect` 17 trường 140 byte, `GCConnect` 5 trường 18 byte: khớp với dump Ghidra thủ công cũ
  (`TAILIEU/ghidra/login_packets.txt`, `GOI-TIN-DANG-NHAP.md`). Không opcode nào trùng nhau trong 1 367 gói.
- Bố cục vtable của gói tin (đo trên `CGAttack`, `GCNewPlayer`, `CGConnect`): ô 0 hàm huỷ, ô 1 `Read`, ô 2 `Write`, ô 3 `Execute`, ô 4 `GetPacketID`,
  ô 5 `GetPacketSize`.
- `Start_MagicSend` (`0x1405ee920`) nằm trong `Obj_Character_Logic.cpp` theo bản đồ nguồn; hàm nạp mọi bảng dữ liệu là `0x140091610` (`GMDataBase.cpp`,
  `CDataBaseSystem#15`), nó tham chiếu 566 trên 598 tên bảng `.txt` (`data_files.tsv`).
- Cây kế thừa: `CObject_PlayerMySelf` → `CObject_PlayerOther`, `CObject_PlayerNPC` → `CObject_Character` → `CObject_Dynamic` → `CObject_Map`, `CObject_Phy` →
  `CObject` → `tObject` → `tNode`.

## Tra cứu

- Hàm tại địa chỉ: mở `decompile.zip`, chọn tệp `.c` có khoảng địa chỉ (ghi trong tên tệp) chứa nó, rồi tìm dòng `// ==== 0x...` của hàm.
- Gói tin theo tên: `packets.tsv` (cột `packet_id`, `fields`); ai xử lý nó: cột `execute_fn`, rồi tìm hàm đó trong `decompile.zip`.
- Ai dùng chuỗi/bảng: `strings.tsv` cột `referrers` hoặc `data_files.tsv`. Ai gọi hàm: `callgraph.tsv` (lọc cột 2).
- Lớp và ô ảo: `classes.tsv`; ô ảo nào thuộc lớp nào: cột `vslot` của `functions.tsv`.

## Giới hạn (đọc trước khi tin một cột)

- Pseudo-code là đầu ra của decompiler, không phải nguồn biên dịch lại được: tên biến là `param_N`/`uVarN`, kiểu là `undefinedN`, offset trường là số.
  Tên lớp và tên trường chỉ có ở RTTI và chuỗi; cấu trúc dữ liệu (struct) chưa được dựng lại thành kiểu.
- 5 hàm lớn nhất (6 512 đến 34 259 lệnh) làm decompiler dừng sau 72 đến 296 giây (`execution_failure`): `0x140091610` (nạp mọi bảng),
  `0x1406557c0`, `0x140a10cd0`, `0x140a18c10`, `0x140a272b0`. Chỉ có disassembly ở `disasm/`.
- `source_file` chỉ suy ra cho 11 038 trên 57 200 hàm: khoảng địa chỉ từ hàm đầu đến hàm cuối có chuỗi assert của cùng tệp nguồn (không có khoảng chồng
  nhau). Hàm của tệp nguồn nằm ngoài khoảng đó, thư viện (CRT, STL, MFC) và mã không assert đều để trống. `sources.tsv` chỉ biết đúng các hàm có assert.
- Quan hệ chuỗi → hàm (`strings.tsv`) là "hàm có địa chỉ vào lớn nhất không vượt quá lệnh tham chiếu" (bisect); sai chỗ Ghidra để dữ liệu (bảng nhảy) xen
  giữa hai hàm. Đã so với phép của REA (`trace_feature` "GameCode", có hàm chứa chính xác theo thân hàm): trùng hoàn toàn trên 5 387 cặp (chuỗi, hàm);
  chưa so cho các chuỗi khác.
- `packets.tsv`: trường chỉ tính được cho gói có `Read` dạng `flat` (827) bằng cách đọc các lời gọi `f(param_2, param_1 + offset, size)`.
  `branching` (456) có điều kiện hoặc vòng lặp, `delegated` (22) chuyển cho hàm đọc của cấu trúc con, `empty` (58) không có trường, `unparsed` (4):
  với bốn dạng sau phải đọc pseudo-code. Kích thước biến đổi (`GetPacketSize` không phải hằng) để trống. Tệp handler suy ra được cho 81 gói
  (chỉ khi handler có chuỗi assert).
- `classes.tsv`: bảng vtable đọc tối đa 128 ô; 7 lớp đúng 128 ô có thể bị cắt. Chỉ lớp có vftable. `bases` là danh sách phẳng theo RTTI, không phân biệt trực tiếp hay gián tiếp.
- Chuỗi tiếng Trung (GBK) hầu như không được Ghidra giải mã: chỉ 1 chuỗi có chữ Hán. Đọc chuỗi GBK từ byte thô nếu cần.
- Chỉ có `Game.exe`. `TENGINE.DLL` (engine, 122 import) không còn trên đĩa. `Render.dll`, `UI_CEGUI.dll`, `CEGUIBase.dll`, `CEGUIFalagard.dll`, `OgreMain.dll` còn trong
  dự án Ghidra TLBB (chưa trích ra đây). `PathLib.dll` đã phân tích riêng ở `docs/DUONG-DI-2026.md`.
- Không có dữ liệu thời gian chạy (bảng `.txt` thật, gói tin thật): đây là phân tích tĩnh.

## Chạy lại từ đầu

Cần: REA đã build (`D:\rea`, tag `rea-agents-6.4.0`, addon Windows copy từ gói npm), Ghidra 12.1.4, JDK 21, `D:\rea\work\client\Game.exe`.

```
rem 1. Giữ một phiên REA (nạp nguội ~308 giây, đặt REA_GHIDRA_STARTUP_TIMEOUT_MS >= 1800000)
powershell Start-Process cmd.exe -ArgumentList '/c','TOOLS\port\rea\start_server.cmd' -WindowStyle Hidden
rem 2. Mở tệp, xuất danh sách đầy đủ (list_procedures/list_names/list_strings vượt trần stdio 10 MB nên lấy qua bundle)
node TOOLS\port\rea\rea_bulk.mjs TOOLS\port\rea\plans\plan_a.json
rem    (lệnh list_* báo lỗi "resource_constraint" là bình thường: kết quả vẫn được giữ và nằm trong bundle)
rem 3. Sinh các plan (vào <work>\plans), chạy, rồi dựng bảng
python -X utf8 -I TOOLS\port\rea\game_exe_dump.py core
node TOOLS\port\rea\rea_bulk.mjs <work>\plans\plan_vt.json
python -X utf8 -I TOOLS\port\rea\game_exe_dump.py hier   & node ... plan_hb.json
python -X utf8 -I TOOLS\port\rea\game_exe_dump.py hier2  & node ... plan_hc.json
node ... plan_callees_0..3.json plan_xrefs_0..3.json plan_dec_0..5.json TOOLS\port\rea\plans\plan_res.json
python -X utf8 -I TOOLS\port\rea\game_exe_dump.py assemble   (mã 3: chạy plan_dec_retry.json / plan_disasm.json rồi assemble lại)
python -X utf8 -I TOOLS\port\rea\game_exe_dump.py lua        (offline: lua_api.tsv, lua_tables.tsv từ tệp đã ghi + Game.exe để đọc chuỗi ngắn và mã hàm nhỏ)
python -X utf8 -I TOOLS\port\rea\compare_client.py           (offline: so-sanh/ và SO-SANH.md; cần capstone và D:\rea\work\client\Game.exe cho phép kiểm ranh giới lệnh)
```

`plan_a.json` gồm `open_binary` (`provider_id` `ghidra`, `snapshot_path`), `binary_overview`, `list_procedures`, `list_names`, `list_strings`, `list_segments` và
`export_evidence_bundle` ra `<work>\bundle_full.json` (~164 MB, xoá sau khi chạy `core`). Đo ngày 2026-10-14: nạp nguội 308 giây; `procedure_callees` và
`xrefs` ~1,5 ms mỗi việc (57 200 và 56 190 việc); decompile 57 195 hàm mất ~27 phút (phần lớn ở vài trăm hàm lớn), thêm ~14 phút cho 5 hàm bị bỏ cuộc.
`rea_server.mjs` và `rea_bulk.mjs` dùng `REA_ROOT` (mặc định `D:/rea`) và `REA_WORK` (mặc định `D:/rea/work`).
