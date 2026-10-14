# TAILIEU — tài liệu phân tích client gốc và suy ra cho máy chủ

Chủ dự án chốt ngày 2026-10-13: mọi tài liệu phân tích mã máy của client gốc (kể cả phần suy ra cho máy chủ) nằm ở
thư mục này. Tài liệu cũ ở `docs/` giữ nguyên chỗ (xem chỉ mục cuối).

## Nguồn và công cụ

- Client gốc: `F:\tl 2026\2026` (3.71, `Bin64\Game.exe`, `Render.dll`, `OgreMain.dll`, `CEGUIBase.dll`,
  `UI_CEGUI.dll`). Cây đã giải gói, tên gốc: `F:\tl 2026\_goc`. Chỉ đọc.
- Mọi thứ của Ghidra nằm trong một thư mục `Desktop\ghidra` (gom 2026-10-13): bản chạy
  `ghidra_12.1.4_PUBLIC\`, dự án `projects\TLBB` (đã phân tích đủ cả năm tệp trên, thêm `CEGUIFalagard.dll`),
  `scripts\` (`ExportProof.java`, `check_proof.py`, `run_ui.bat`, các tệp `keys-*.txt`: xuất bằng chứng của bốn DLL) và
  `export\` (kết quả `*.proof.txt` của lần xuất đó). Nhập lại Game.exe: `TOOLS\port\ghidra\import_game.bat` (khoảng 5 phút).
- Đọc hàm: `TOOLS\port\ghidra\decompile.bat <chương trình> <tệp ra> <khoá>...` với khoá `0xĐịaChỉ`, `s:chuỗi`,
  `x:0xĐịaChỉ`, `n:tên`, `l:tên`, `v:lớp`, `i:chuỗi`, `a:0xĐịaChỉ`, `e:0xĐịaChỉ` (giải thích ở đầu
  `TOOLS\port\ghidra\DecompileAt.java`). Dự án Ghidra bị khoá khi đang mở: chạy lần lượt.
- Địa chỉ của Ghidra và địa chỉ `.pdata` của `TOOLS\port\pe_refs.py` có thể khác nhau về ranh giới hàm (Ghidra gộp
  mảnh `.pdata` vào hàm mẹ). Địa chỉ giữa hàm không phải điểm vào: kiểm bằng `pe_refs.py func`.
- Script Lua gốc mã hoá: `python -B TOOLS/content/lua_plain.py "F:/tl 2026/_goc" build/lua-2026` (không vào git).

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

## Chỉ mục tài liệu cũ ở `docs/`

`docs/TAO-NHAN-VAT-2026.md` (màn tạo nhân vật), `docs/CAMERA-2026.md` (camera, màn đăng nhập),
`docs/GIAO-DIEN-2026.md` (widget CEGUI), `docs/DUONG-DI-2026.md`, `docs/VA-CHAM-2026.md`,
`docs/NHIEM-VU-VO-CONG-2026.md`, `docs/NGHI-NGO.md` (sổ nghi ngờ; mục 40 và 46 đã có kết luận ở
`DANG-NHAP-GOC.md`).
