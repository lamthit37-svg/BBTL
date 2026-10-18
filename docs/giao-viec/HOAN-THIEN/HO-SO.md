# Hồ sơ đợt hoàn thiện tính năng giao diện client và máy chủ (2026-10-18)

Người điều phối: phiên `thienlong-f7`, từ 2026-10-18 chiều là `thienlong-5f` (cùng memory; ba phiên làn mở lại, xem mục 4 và 9). Ba làn: `thienlong-14` (làn K, client), `thienlong-6a` (làn
M, máy chủ) và `thienlong-1e` (làn N, nội dung: chuỗi nhiệm vụ, phụ bản, boss, sự kiện; thêm ngày
2026-10-18). Commit nền: `c85f0491` trên `chuan-hoa`, đã push lên `origin`. Chỉ `thienlong-f7` sửa
tệp này; làn nào cần đổi thì nhắn điều phối.

Hồ sơ dựng từ bốn lượt rà chỉ đọc ngày 2026-10-18 (UI client so với gốc, máy chủ và giao thức, cầu
nối client và máy chủ, sổ audit và sổ nghi ngờ). Số liệu dưới đây là [đọc mã] trừ khi ghi khác.

## 0. Luật chủ dự án cho đợt này

Ba câu chủ dự án nói ngày 2026-10-18, thắng mọi thói quen cũ:

1. "Client gốc có cái gì thì source và client ta có cái đấy. Không tự chế ra thêm những thứ không
   có. Code hoàn thiện chất lượng cao và tôi chỉ nhận kết quả đó."
2. "Hạn chế tối đa việc viết test logic. Tự tổ chức test thực end-to-end, phân tích bằng công cụ có
   sẵn trên PC để dùng lại chính xác thuật toán gốc nhất."
3. "Tự test kiểm chứng đối chất nhau, hoàn thiện từng tính năng trọn vẹn một, tự commit khi đạt.
   Chất lượng production grade."

Hệ quả bắt buộc:

- Mỗi việc phải chỉ ra được bằng chứng gốc trước khi viết mã (mục 3). Không có bằng chứng thì không
  làm, và nói ra là không làm vì sao.
- Công cụ dev (cờ dòng lệnh, kịch bản E2E, log kiểm) được phép, nhưng không bao giờ hiện trong giao
  diện người chơi.
- Không viết ca test logic mới, trừ hai loại: trọng tài số vàng lấy từ client gốc hay mã máy, và test
  hồi quy cho lỗi vừa sửa (đỏ trước, xanh sau). Test có sẵn phải xanh, không nới kỳ vọng.
- Một tính năng chỉ được báo "xong" khi đã chạy thật end-to-end và làn kia xác nhận ĐẠT (mục 6).

Luật nền vẫn nguyên: `CLAUDE.md` (máy và dự án), `AGENTS.md` mục 0, sổ nhớ dự án (`MEMORY.md`). Đặc
biệt: không chiếm chuột (cấm `click_shot.py`, `probe_drag.py`), mọi lần chạy test hay exe kiểm thử
chạy nền, build 0 cảnh báo và đọc hết log (tìm `D9002`), `shape.js --diff .` sạch, khung đầu tệp qua
`py -X utf8 TOOLS/source_headers/source_headers.py --fix <tệp>`, chữ người chơi thấy là `zh` (bản dựng mặc định).

### 0.1 Luật chữ (chủ dự án chốt 2026-10-18)

Nguyên văn: "làm tới đâu triển khai i18n Anh Trung Việt ngay lập tức. và ngôn ngữ trong server dùng để
config hay các tsv trong sv chuyển hết về tiếng việt có dấu. những file models thì đổi hết toàn bộ sang
chuẩn pinyin cho cả assets và tsv quản lý. tới đâu làm tới đó ko mở rộng 1 lúc".

Chỉ áp cho phần đang chạm trong việc đang làm; không mở đợt đổi hàng loạt.

1. **i18n ba thứ tiếng.** Chữ người chơi thấy của tính năng vừa làm phải có đủ khoá ở
   `assets/i18n/zh.tsv`, `en.tsv`, `vi.tsv` trong cùng commit. Thuật ngữ theo `assets/i18n/glossary.tsv`
   (thuật ngữ mới thì thêm vào đó trước). Không chữ cứng trong mã. Kiểm: ảnh bản `zh` và một bản dịch.
2. **Máy chủ tiếng Việt có dấu.** Bảng TSV (`dev/server/tables/**`) hay tệp config (`dev/server/config/**`)
   nào đang chạm thì header cột, khoá, chú thích và nhãn chuyển sang tiếng Việt có dấu. Bộ đọc, công cụ
   sinh và test của bảng đó đổi trong cùng commit, để lượt xuất sau không đổi ngược. Một nguồn thuật ngữ:
   thêm cột `vi` ở `TOOLS/server/column_terms.tsv`. Chữ người chơi thấy (thoại, tên vật phẩm) không dịch
   tại chỗ mà đi qua i18n, giữ nguồn `zh` của gốc. Định danh trong mã C++ vẫn tiếng Anh; tên cột tiếng
   Việt là chuỗi UTF-8.
3. **Tên model sang pinyin.** Tệp model, khung xương, hoạt ảnh tên chữ Hán (31 900 trên 39 883 tệp ở
   `dev/client/assets/Model`, đo 2026-10-18) đổi theo quy ước:
   - Hanyu Pinyin không dấu thanh, chữ thường ASCII, ü viết `v`;
   - âm tiết của một cụm chữ Hán viết liền (巨树 → `jushu`), giữ nguyên phần ASCII, số, dấu ngăn có sẵn
     và đuôi tệp; cụm Hán dính liền chữ ASCII thì chèn `_`;
   - chữ đa âm theo từ điển cụm từ của `pypinyin` (ghim phiên bản), sửa tay ở bảng ghi đè;
   - trùng tên trong một thư mục thì thêm `_2`, `_3` theo thứ tự tên gốc.

   Một bảng ánh xạ duy nhất gốc → pinyin, giữ tên gốc để đối chiếu client gốc. Đổi ở công cụ chuyển đổi
   và ở mọi bảng, cảnh trỏ tới tệp đó, trong cùng commit. Ảnh trước và sau phải giống nhau. Làn K dựng công
   cụ và bảng ánh xạ ở lần đầu cần đổi (phiếu ngắn trước khi làm); chủ dự án chỉnh quy ước thì sửa ở đây.
4. **Giọng dịch và bản dịch không thống nhất.** Chủ dự án nói (2026-10-18): "Dịch theo chuẩn
   trong game kiểu như FPT ngày xưa nhé. đừng chỉ dịch là dịch ngang là xong", và "Tất cả những
   bản dịch ko thống nhất lưu lại txt. hoặc tra cứu TLBB việt nam, ko thấy thì lưu lại tôi dịch
   tay". Áp như sau:
   - Cùng một chữ `zh` mà `vi` hay `en` dịch khác nhau là "không thống nhất", kể cả khi chỉ khác
     chữ hoa.
   - Tra tên dùng trong Thiên Long Bát Bộ bản Việt Nam. Thấy thì dùng tên đó và ghi nguồn (URL hay
     tệp).
   - Không thấy thì không tự chọn: giữ giá trị đang có ở HEAD và ghi vào `docs/DICH-TAY.txt` để chủ
     dự án dịch tay.
   - Chủ dự án dịch xong thì đưa vào `glossary.tsv` rồi áp cho mọi khoá. `glossary.tsv` chỉ giữ tên
     đã có nguồn hoặc do chủ dự án chốt.

## 1. Hiện trạng

### Client

- Client gốc có 1 975 cửa sổ (`src/client/script/windows.tsv`, xuất từ `InterfaceEx.txt`), mỗi cửa
  sổ một layout và một script Lua. `Game.exe` đăng ký 6 055 hàm cho Lua; script dùng 5 350 tên,
  2 896 tên sự kiện (`docs/giao-viec/LUA-GEN/TANG-B.md`, `API-TAN-SUAT.tsv`,
  `docs/TAILIEU/SU-KIEN-GAME.tsv`).
- Máy Lua là LuaPlus 5.0.1 gốc, khớp 2 060/2 060 đơn vị. Nhưng chỉ 2 cửa sổ chạy bằng script gốc
  (`kScripted` ở `src/client/face/ui/hud.cpp:160`: ProgressBar, DebugListBox).
- Khoảng 20 cửa sổ là panel C++ viết tay trong `src/client/face/ui/panel/` (đăng nhập, PlayerFrame,
  TargetFrame, MiniMap, MainMenuBar, Packet, SelfEquip, QuestLog, Quest...), mỗi tệp có danh sách
  "Khác gốc". Bảy cửa sổ đã chứng minh chạy được bằng script nhưng HUD vẫn dùng bản viết tay
  (`LUA-GEN/TANG-C.md` mục 3.1).
- Hàm game đã có khoảng 463 tên, khớp 439/5 350 tên script dùng. Thiếu lớn nhất: DataPool 1 007,
  hàm toàn cục 734, Pet 271, Player 183, PlayerPackage 154, Exterior 148, LifeAbility 120, Guild 100,
  Talk 86, GameProduceLogin 82, NpcShop 66, SystemSetup 48.
- Không có kho dữ liệu kiểu CDataPool, CObjectManager, CActionSystem (`Facts::pool` rỗng). Client
  không sinh sự kiện từ trạng thái game (`UNIT_*`, `PACKAGE_ITEM_CHANGED_EX`, `MONEY_CHANGE_EX`,
  `UI_COMMAND`).
- Khi không nối máy chủ, số nhân vật viết cứng ở `hero::newcomer()`
  (`src/client/figure/hero/hero.cpp:130-145`).

### Máy chủ và giao thức

- Giao thức v7, 52 tin (`src/shared/protocol/catalog/messages.tsv`, sinh bằng
  `TOOLS/server/gen_protocol.py`). Chưa có tin chat, trang bị, dùng vật phẩm, cửa hàng, giao dịch,
  đội, bạn, thư, bang, thú, ExecuteScript, UI_COMMAND.
- Đã chạy được: đăng ký và đăng nhập (PostgreSQL), tạo và chọn nhân vật, đi trong cảnh và qua cổng,
  hội thoại và nhiệm vụ (1 063/1 349 nhiệm vụ trích được), người đánh quái, rơi và nhặt đồ.
- Có lõi nhưng chưa ai gọi: `item::Inventory`, `shop`, `forge`, `social`, `billing` (vì `world` chỉ
  in `ready` rồi chờ). `handlers` rỗng.
- Lệnh từ hội thoại bị bỏ: `open_shop`, `teleport`, `ui_command`, `signpost`
  (`src/server/mission/detail/work.cpp:164-175`).
- Luật tự chế đang chạy (thay dần bằng luật gốc ở gói tương ứng):
  - `play/battle.cpp:195-214`: có mọi chiêu ở cấp 1. Gốc: `[skill] id=[0,1,21,22,34,35]` của
    DefaultChar.
  - `battle.cpp:124-129`: hồi tại chỗ 30%. Gốc: `SetPlayerDefaultReliveInfo` theo cảnh,
    `GodReliveTopLevel=20`.
  - `battle.cpp:613-616`: hồi "về thành" là về chỗ vào cảnh.
  - `battle.cpp:183-185`: người với người luôn là bạn.
  - `battle.cpp:224-225`: ai cũng cầm vũ khí loại 0.
  - `zone/scene.hpp:77-79`: xác 3 s, quái hồi 30 s. Gốc `ConfigInfo.ini`: 120000, 5000, 60000.
  - `guard/pace.cpp:9`: trần tốc cố định.
  - `zone/mind.cpp:247`: quái không ra đòn.
  - Không tệp `rules/*.toml` nào được đọc lúc chạy.

### Đường end-to-end

- Mã đủ cho tự đăng nhập: biến môi trường `THIENLONG_ACCOUNT` cùng `--login`
  (`viewer_win32.cpp:853-918`, `display/auto_login.hpp`). Nhưng chưa từng chạy với cụm thật (DU-AN
  C1).
- Exe máy chủ ở `dev/server/bin` dựng ngày 10-15 và 10-16 [tự kiểm], cũ hơn protocol v7 và khoá
  `allowed_builds` (`dev/server/config/gate.toml:41-42`): phải dựng và cài lại.
- Client chỉ chụp một ảnh mỗi lần chạy, `--ui-event` chỉ phát ở khung đầu, không có kịch bản thao
  tác nhiều bước. Máy chủ không ghi log theo việc của người chơi.
- Client nâng tần số quét màn hình (`RaisedRefresh`, `viewer_win32.cpp:807-851`) và gọi
  `SW_RESTORE` khi mở thu nhỏ (kích hoạt cửa sổ). Chạy nền mà không xử lý hai điểm này là làm phiền
  máy của chủ dự án.

### Lỗi mức cao chạm tính năng người chơi (sổ `SO_GHI_CHEP_REVIEW.md`, CONFIRMED, chưa sửa)

- H1: hack tốc độ 4–7 lần. `kJitterTicks` được cấp lại ở mỗi tin Move (`src/server/guard/pace.cpp:15,75-77`).
  Cộng với B19: luật đi chỉ kiểm điểm đến (`zone/scene.cpp:288-293`), nên đi xuyên được tường mỏng.
- H2: `luaopen_io` mở cả `os` cho script giao diện (`src/client/face/ui/script/host.cpp:833`),
  gồm `os.execute`, `os.remove`, `os.getenv`. Script gốc chỉ dùng `io.open` (7 chỗ), `os.time` (8),
  `os.date` (1) [tự kiểm bằng grep `dev/client/assets/Script`].
- B1: gate bỏ lặng khung lớn hơn 4 104 byte (`gate/table.cpp:600`), trong khi DialogOpen tối đa
  29 473 byte.

## 2. Kiến trúc đích

**Client.** Đường mặc định của một cửa sổ là layout gốc cộng script Lua gốc, không sửa script, chạy
trên LuaPlus 5.0.1 gốc. C++ cài các hàm mà `Game.exe` đăng ký cho Lua (tầng B), mỗi hàm theo ngữ nghĩa đọc từ mã máy
(địa chỉ ghi trong comment). Dữ liệu nằm trong kho mô phỏng CDataPool, CObjectManager, CActionSystem
của `Game.exe`, được ghi từ tin mạng. Sự kiện phát từ trạng thái giống `Game.exe` (tên trong
`SU-KIEN-GAME.tsv`).

**Cái nào tốt hơn thì giữ (chủ dự án chốt 2026-10-18).** Panel C++ viết tay điều khiển đúng cửa sổ
gốc nên không phải tính năng tự chế; nó chỉ là một cách làm khác. Cửa sổ nào đã có panel C++ thì so
nó với bản chạy script gốc theo bốn tiêu chí, xét đúng thứ tự:

1. Đúng gốc: hình và hành vi khớp layout gốc, số vàng, mã máy; ít chỗ "Khác gốc" hơn.
2. Đủ: phủ hết thao tác người chơi của cửa sổ gốc, dữ liệu lấy từ máy chủ.
3. Hiệu năng đo ở Release: thời gian mở cửa sổ, chi phí mỗi khung, phần đóng vào ngân sách nạp đầu
   450 ms.
4. Chất lượng mã: an toàn, dễ đọc, dễ đối chiếu với gốc.

Giữ bản thắng. Hai bản ngang nhau thì giữ bản đang chạy, không đổi cho có. Bảng so (số đo, ảnh,
danh sách khác gốc của từng bản) ghi trong phiếu gói; không xoá panel C++ nào khi chưa có bảng so
chứng minh bản script tốt hơn. Panel C++ được giữ vẫn phải lấy số từ máy chủ và đóng hoặc giải thích
từng mục "Khác gốc" của nó. Cửa sổ chưa có bản chạy được nào thì mặc định đi đường script, vì đó là
đường ngắn nhất tới đúng hành vi gốc; chỉ viết C++ khi đo được là tốt hơn theo bốn tiêu chí trên.

**Máy chủ.** Luật lấy từ cấu hình và Lua gốc (XJL7457) cùng mã 2008, giữ toán tử và thứ tự; chỗ lệch
ghi `// Khác gốc:`. Giao thức của ta giữ lớp bảo mật riêng (X25519, Ed25519), nhưng mỗi tin mới phải
mang đúng các trường của gói gốc tương ứng (`docs/TAILIEU/GAME-EXE-2026/packets.tsv`, 1 367 gói,
công cụ `TOOLS/port/ghidra/packet_fields.py`). Không thêm trường gốc không có. Thêm tin thì sửa
`catalog/*.tsv` rồi chạy `gen_protocol.py`, không sửa tay tệp sinh, và thêm đích fuzz cho bộ giải mã
mới.

## 3. Bằng chứng gốc: nguồn và công cụ

| Loại | Nơi | Cách dùng |
|---|---|---|
| Cửa sổ, layout, script giao diện gốc | `dev/client/assets/Interface/**`, `dev/client/assets/Script/Interface/**`, `src/client/script/windows.tsv` | Đọc thẳng; script không được sửa |
| Hàm `Game.exe` cho Lua, lớp dữ liệu | `docs/TAILIEU/GAME-EXE-2026/` (`functions.tsv`, `decompile.zip`, `lua_api.tsv`), `docs/giao-viec/LUA-GEN/*` | `py -X utf8 -I TOOLS/port/rea/show_func.py 0x…` |
| Mã máy DLL và exe gốc | `G:\XTLBB\Bin64` (Game.exe, UI_CEGUI.dll, Render.dll, LuaPlus.dll...) | REA: `TOOLS/port/rea/start_server.cmd`, rồi `rea_bulk.mjs` (cần `.snap` có sẵn ở `D:/rea/work/snap`); dự án Ghidra `C:\dev\ghidra\projects\TLBB.gpr` |
| Gói tin gốc | `docs/TAILIEU/GAME-EXE-2026/packets.tsv` | `TOOLS/port/ghidra/packet_fields.py` |
| Máy Lua gốc | `G:\XTLBB\Bin64\LuaPlus.dll` | `TOOLS/port/lua_oracle.py G:\XTLBB\Bin64 …` (tài liệu cũ ghi nhầm `D:\XTLBB`) |
| Script và cấu hình máy chủ gốc | `G:\XJL7457\Server\rootfs\home\tlbb\Public\Data\Script` (5 495 tệp Lua), `...\Server\Config\*.ini` (ConfigInfo, DefaultChar, DiePenalty, PvpRuler...) | Đọc; trích dẫn tệp và dòng |
| Mã máy chủ 2008 | `D:\TÀI LIỆU TLBB\tlbb_server\Server` (1 146 tệp `.cpp`) | Đọc; port giữ toán tử |
| Log client gốc | `G:\XTLBB\Bin64\LogDirectory\*.log` | Đối chiếu thứ tự sự kiện, giá trị |

Không dùng được: `G:\TLBB\_ref` (đã mất), `F:\tl 2026\2026\Bin64` (không còn), các `.bat` Ghidra trỏ
`Desktop\ghidra` (đã mất). Client gốc nối máy chủ thật ở `42.119.219.227`, không nối được cụm của ta
và đăng nhập phải bấm chuột, nên không chạy song song làm trọng tài tự động được.

## 4. Ba làn và quyền sở hữu tệp

| Làn | Phiên | Phần việc | Tệp được sửa |
|---|---|---|---|
| K | `thienlong-c5` (phiên `thienlong-14` mở lại, còn ngữ cảnh) | Client: hoàn thiện cửa sổ (script gốc, hoặc panel C++ nếu tốt hơn theo mục 2), hàm game tầng B, kho dữ liệu, sự kiện, công cụ E2E phía client | `src/client/**`, `engine/**`, `Test/` các thư mục của client và engine, `TOOLS/run/**`, `TOOLS/port/**`, `TOOLS/content/**`, `dev/client/**`, `assets/**` (trừ `assets/logo.png`), `android/**`, `apple/**` |
| M | `thienlong-bd` (trước là `thienlong-6a`) | Máy chủ và giao thức: tin mới, nối module, luật gốc, log kiểm, bot | `src/server/**` trừ phần của N, `src/shared/**` trừ catalog giao thức, `Test/` các thư mục của máy chủ và shared trừ phần của N, `TOOLS/server/**` trừ phần của N, `dev/server/**` (phần git theo dõi) trừ bảng nội dung, `cmake/server/**`, `docs/SERVER-*.md` trừ `SERVER-MISSION.md`, `docs/KE-HOACH-SERVER.md` |
| N | `thienlong-43` (thay `thienlong-1e` đã đóng) | Nội dung: NPC, hội thoại, chuỗi nhiệm vụ, phụ bản, boss, sự kiện, cả phần máy chủ lẫn cửa sổ client của nội dung | `src/server/mission/**`, `src/server/talk/**`, `src/server/ops/**`, module nội dung mới (phụ bản, sự kiện, boss) dưới `src/server/`, `Test/Mission`, `Test/Talk`, `Test/Ops`, `Test/Quest`, `TOOLS/server/lua_*.py`, `dialogue_*.py`, `newquest.py`, `quest_chains.py` và test của chúng, bảng nhiệm vụ, thoại và nội dung trong `dev/server/tables/**`, `docs/SERVER-MISSION.md`, `docs/NHIEM-VU-NGUON.md`; client: `src/client/face/ui/panel/npc_talk.*`, `quest_log.*` và tệp mới cho cửa sổ và hàm game của nội dung |
| Chung | cả ba | Theo luật khoá bên dưới | `CMakeLists.txt`, `cmake/*.cmake`, catalog giao thức `src/shared/protocol/catalog/*.tsv` cùng tệp sinh và `docs/PROTOCOL-TIN.md` (M và N), `docs/DU-AN.md`, `docs/TIEN-DO.md`, `docs/NGHI-NGO.md`, `docs/BAY-DA-BIET.md`, `AGENTS.md` |

Làn N cần móc vào tệp của làn khác (ví dụ `src/server/play/**`, `src/server/zone/**` cho phụ bản,
bảng đăng ký hàm game của host Lua ở client) thì dùng đúng luật khoá như tệp chung, và chủ tệp được
hỏi trước. Giữ cây luôn dựng được: không để tệp ở trạng thái không biên dịch quá một bước làm, vì ba
làn dựng chung một cây nguồn.

Không ai sửa `CLAUDE.md`, `.clang-format`, `CMakePresets.json`, `CMakeUserPresets.json`, tệp này,
`assets/logo.png` (tệp của chủ dự án, không commit) và `.worktrees/ride-check` (worktree của điều
phối; trong đó `dev/server/tables/shared` là junction trỏ vào dữ liệu thật, xoá đệ quy là mất bảng).

**Khoá tệp chung.**

1. `git diff --quiet -- <tệp>` phải sạch. Không sạch nghĩa là làn kia đang sửa: nhắn họ, chờ.
2. Nhắn hai làn kia và điều phối: `KHOÁ <tệp> (<gói>)`.
3. Sửa, dựng, rồi commit tệp đó cùng việc của mình trong cùng đợt làm.
4. Nhắn `MỞ <tệp>`.

Với `TIEN-DO.md` và `NGHI-NGO.md`, chỉ thêm mục mới ở cuối, không sửa mục của làn kia.
`DU-AN.md` do điều phối cập nhật khi một gói đạt.

**Cây dựng riêng, không chạy hai Ninja trên một cây.**

- K dùng `build/msvc-release`, cài client vào `dev/client/bin`.
- M dùng preset `lane-server` (khai trong `CMakeUserPresets.json`, cây `build/lane-server`, cài vào
  `dev`).
  - Lần đầu: `cmake --preset lane-server`.
  - Dựng phần máy chủ: `cmake --build --preset lane-server --target thienlong_server
    thienlong_store thienlong_auth thienlong_billing thienlong_world thienlong_zone thienlong_gate
    thienlong_lint thienlong_bot`, cộng các target test máy chủ cần chạy.
  - Cài: `cmake --install build/lane-server --component server --prefix dev`.
- Khi M đổi `src/shared/**`, client cũng phải dựng được. Trước khi commit, M dựng thêm
  `thienlong_client` trong `build/lane-server`. Nếu hỏng vì mã đang sửa dở của K, nhắn K, không sửa
  hộ.
- N dùng preset `lane-content` (cây `build/lane-content`, cài vào `dev`), dựng cả máy chủ lẫn client
  vì làn N chạm cả hai. Lần đầu `cmake --preset lane-content`. N không cài client vào
  `dev/client/bin` (của K); muốn chạy client của mình thì chạy thẳng từ `build/lane-content` với
  `--data dev/client/assets`, hoặc nhờ K cài sau khi phần client của N đã commit.
- Mọi lệnh dựng qua `cmd /c "call %USERPROFILE%\.claude\skills\cpp-build\dev.bat && …"`, chạy nền.

**Cụm máy chủ dùng chung.** Cụm ở `dev/server` (cổng 7100 game, 7101 auth, PostgreSQL 5432) do M
dựng và quản. N cài bản máy chủ của mình vào đó khi cần kiểm nội dung.

- Ai cài lại hay khởi động lại cụm thì nhắn hai làn kia trước, chờ họ không đang chạy E2E.
- Tài khoản thử tách theo làn: `e2ek<gói><số>` cho K, `e2em<gói><số>` cho M, `e2en<gói><số>` cho N.
- `auto_register = true` ở dev nên tên mới tự tạo tài khoản.

## 5. Gói tính năng

Làm đúng thứ tự. Gói G có phần K và phần M chạy song song (trừ G3, làn N làm cả gói). Gói chỉ trọn
khi mọi phần đạt và đã commit. Làn nào xong phần mình trước thì kiểm chéo phần của làn kia, rồi lấy
việc đệm ở mục 5.11. Không nhảy sang gói sau khi gói trước chưa trọn, trừ việc đệm. Làn N đi chuỗi
gói riêng N0–N6 (mục 5.12), song song với chuỗi G.

Trước khi viết mã cho một gói, mỗi làn viết phiếu `docs/giao-viec/HOAN-THIEN/G<n>-K.md` hoặc
`G<n>-M.md`, tối đa một trang. Phiếu gồm:

- cửa sổ gốc, hàm `Game.exe`, gói tin gốc, tệp cấu hình hay Lua máy chủ gốc mà gói dựa vào, mỗi thứ
  có đường dẫn hoặc địa chỉ;
- danh sách thứ KHÔNG làm vì không có bằng chứng;
- kịch bản E2E và tiêu chí đạt.

Làn kia đọc phiếu và trả lời trong một lượt, để bắt ngay việc tự chế.

### G0 — Hạ tầng E2E tối thiểu để kiểm tính năng

Chủ dự án nhắc ngày 2026-10-18: tập trung hoàn thiện giao diện và tính năng. G0 chỉ dựng đúng phần
cần để chứng minh tính năng bằng chạy thật, làm gọn rồi sang G1 ngay. Gói này đóng DU-AN C1.

**M:**
- Dựng `lane-server`, cài máy chủ vào `dev`, chạy cụm bằng `python -B TOOLS/server/local_cluster.py
  start` ở nền, chờ dòng `ready` có 7100 và 7101.
- Bot mặc định nối 7100/7101 theo `gate.toml`, thay cho 7000/7001 (`TOOLS/server/bot.cpp:19,76-77,712`).
- Sửa `dev/server/README.md` còn ghi 7000/7001 và `0.0.0.0`.
- Zone ghi một dòng kiểm cho mỗi việc của người chơi (vào cảnh, bị kéo về, Talk, chọn, nhận và trả
  nhiệm vụ, tung chiêu, trúng đòn, chết, hồi sinh, nhặt). Dòng ghi tài khoản, nhân vật, tick, toạ độ
  và kết quả. Bật bằng một khoá trong `log.toml`; tắt thì không tốn gì.

**K:**
- `TOOLS/run/e2e_client.py`, điều phối một lần chạy:
  - mở client bằng `Popen` với `STARTUPINFO` `SW_SHOWNOACTIVATE`, `cwd=dev/client/bin`,
    `THIENLONG_ACCOUNT`;
  - gom stdout, ảnh, log mạng;
  - xét đạt hay hỏng theo kỳ vọng ghi trong tệp kịch bản;
  - bọc trong `TOOLS/run/desk_watch.py` để chứng minh không đụng màn hình người dùng.
- Client nhận `--script <tệp>`. Các bước: `wait N`, `shot tên`, `event TÊN|…`, `click <tên cửa
  sổ>`, `type <chữ>`, `walk x,z`, `talk <npc>`, `choose i`, `cast ô`, `pick`, `quit`. `click` và
  `type` đi vào GUI bên trong, không qua chuột hay bàn phím hệ điều hành. Mỗi bước in một dòng máy
  đọc được; chụp được nhiều ảnh trong một lần chạy. Móc có sẵn: `hud->say`, `order_move`,
  `combat.engage`, `press_slot`, `posted_events`.
- Khi chạy bằng `--script`: không nâng tần số quét, không kích hoạt cửa sổ.
- Biến môi trường `THIENLONG_NET_TRACE=<tệp>`: mỗi tin gửi hay nhận ghi một dòng (hướng, tên tin,
  trường chính).

**Đạt khi** một lệnh `e2e_client.py` chạy trọn:
- tài khoản mới tự đăng nhập, tạo nhân vật, vào Đại Lý, đi hai bước, chụp hai ảnh, thoát mã 0;
- log mạng có SignIn, CreateCharacter, EnterGame, Move;
- log kiểm của zone có dòng vào cảnh và đi;
- bot quan sát thấy thực thể của client;
- `desk_watch` không báo đổi tiêu điểm hay chuột.

### G1 — Đăng nhập tới vào game

Cửa sổ: LoginLogOn, LoginSelectServer, SoftKeyBoard, LoginSelectRole, LoginCreateRole, SceneTrans,
cùng hộp thông báo lỗi mà luồng gốc mở. Agreement, FangChenMi*, SafeCenter_*, Pswprotect chỉ làm nếu
luồng gốc mở chúng với máy chủ loại này (ghi bằng chứng trong phiếu).

**K:**
- Cài `GameProduceLogin:*` và các hàm DataPool mà script đăng nhập gọi, theo mã máy (địa chỉ trong
  comment).
- Với `logon`, `select_server`, `softkey`, `select_role`, `create_role`, `scene_trans` viết tay:
  dựng bản script, so theo bốn tiêu chí ở mục 2, giữ bản tốt hơn.
- Ô nhập theo widget gốc: NGHI-NGO 40 (e)(f)(h)(i)(j).

**M:**
- `CharacterList` mang đủ trường của gói danh sách nhân vật gốc mà LoginSelectRole hiển thị.
- Xoá nhân vật theo luật gốc.
- Mã từ chối khớp mã kết quả của gói gốc, để script hiện đúng câu.

**Đạt khi** kịch bản không dùng `THIENLONG_ACCOUNT` gõ tài khoản qua `type`, bấm qua `click`, chọn
máy chủ, tạo, xoá rồi tạo lại nhân vật, vào game. Ảnh từng màn so được với layout gốc, log mạng và
log kiểm khớp từng bước.

### G2 — HUD nhân vật

Cửa sổ: PlayerFrame, TargetFrame, MainMenuBar, MainMenuBar_2/3/4, FunctionBarRight,
FunctionBarRight_2, MiniMap, PlayerImpactFrame, TargetBuff, AutoAttack_Button, ProgressBar.

**K:**
- Kho dữ liệu kiểu CDataPool, CObjectManager, CActionSystem: trường và hành vi theo mã máy.
- Hàm `Player:*`, `Target:*`, `DataPool:*`, EnumAction và ActionItem mà các cửa sổ trên gọi.
- Sự kiện `UNIT_*`, `MAIN_TARGET_CHANGED` phát từ tin mạng.
- Cửa sổ đã có panel C++ (`action_bar`, `desk`, `skill_bar`, `player_frame`, `minimap`, TargetFrame):
  so với bản script theo mục 2, giữ bản tốt hơn. Cửa sổ chưa có bản chạy được thì đi đường script.
- Ở chế độ online, không dùng `hero::newcomer()`.

**M:**
- `SelfStats` mang đủ thuộc tính của gói chi tiết thuộc tính gốc, tính bằng công thức gốc.
- Kỹ năng ban đầu theo DefaultChar `[0,1,21,22,34,35]`.
- Giờ máy chủ cho đồng hồ minimap (NGHI-NGO 22).
- Danh sách buff theo gói gốc, nếu gói đó có trong `packets.tsv`.

**Đạt khi** ảnh HUD sau khi vào game mang số của máy chủ (khớp log kiểm và PostgreSQL). Chọn một
quái thì TargetFrame đổi. Thanh kỹ năng có đúng các chiêu DefaultChar.

### G3 — NPC, hội thoại, nhiệm vụ, lệnh giao diện từ máy chủ (làn N làm cả gói)

Cửa sổ: NewNpcChat, Quest, MissionReply, QuestLog, MissionTrack, ScrollInfo. Gói này thuộc làn N
từ 2026-10-18; K và M chỉ kiểm chéo (K phần client, M phần máy chủ).

**N, phía client:**
- Hàm `Talk:*` và các hàm nhiệm vụ mà các cửa sổ trên gọi.
- `Send_XSCRIPT` gửi tin thật.
- Nhận `UI_COMMAND` và mở cửa sổ do máy chủ yêu cầu.
- `npc_talk` và `quest_log` viết tay: so với bản script theo mục 2, giữ bản tốt hơn. Các cửa sổ
  còn lại đi đường script.

**N, phía máy chủ:**
- Tin ExecuteScript theo gói CGExecuteScript (opcode 2219) và tin lệnh giao diện theo gói gốc.
- Xử lý lệnh `teleport`, `ui_command`, `signpost` ở `play` (tệp của M, theo luật khoá).
- Sửa B1: khung lớn bị bỏ lặng (`gate/table.cpp`, tệp của M, theo luật khoá).
- Chuỗi tân thủ: 1400–1408, 1413 và 1424 đi hết. Các bước cần hệ thống của gói khác (1414, 1415 trân
  thú; 1417 G5; 1419 N6; 1421 G7; 1423 thiếu vật phẩm trong mọi bảng; kéo theo 1412, 1416, 1418, 1420,
  1422) ghi `NGHI-NGO.md` kèm gói chặn, làm khi gói đó đạt (điều phối sửa theo `N1.md`, 2026-10-18).

**Đạt khi** kịch bản đi trọn chuỗi tân thủ đầu tiên: nói chuyện, nhận, theo dõi, trả nhiệm vụ, nhận
thưởng, dịch chuyển qua NPC. Mỗi bước có ảnh và dòng kiểm.

### G4 — Chiến đấu, chết, hồi sinh

**M:**
- Quái ra đòn (`zone/mind.cpp`) theo AI gốc.
- Xác và hồi quái theo `ConfigInfo.ini`.
- Hồi sinh theo `SetPlayerDefaultReliveInfo` từng cảnh và điểm hồi sinh của cảnh.

**K:**
- Cửa sổ Relive bằng script.
- Số bay, câu báo `Declined` theo gốc.
- Động tác chết (DU-AN C11).

**Đạt khi** nhân vật đánh quái, bị đánh, chết, hiện Relive, hồi sinh đúng điểm. Log kiểm ghi đủ.

### G5 — Túi và trang bị

**M:**
- `item::Inventory` thay `play::Bag`.
- Tin dùng, xếp, tách, vứt, khoá, mặc, cởi theo gói gốc.
- Thuộc tính vật phẩm lưu và nạp lại.
- `EntityAppear` mang ngoại hình trang bị.
- Sửa B9.
- Vũ khí thật thay "loại 0".

**K:**
- Packet, SelfEquip, SelfData, SplitItem, LootPacket, SuperTooltip. `packet` và `self_equip` đã có
  panel C++: so theo mục 2, giữ bản tốt hơn; còn lại đi đường script.
- `PlayerPackage:*`, ActionItem cho vật phẩm, `PACKAGE_ITEM_CHANGED_EX`.

**Đạt khi** nhặt, xem túi, mặc đồ (mô hình đổi), xem tooltip, thoát vào lại, đồ còn nguyên.

### G6 — Cửa hàng NPC và tiền

**M:** lệnh `open_shop` (91 dòng), nối `shop`, mua, bán, mua lại theo gói gốc.

**K:** NpcShop/Shop, InputMoney bằng script, `MONEY_CHANGE_EX`.

**Đạt khi** mua và bán qua NPC; tiền và túi khớp PostgreSQL.

### G7 — Nhập phái, học kỹ năng, điểm tiềm năng

**M:** thao tác nhập phái, học kỹ năng ở NPC, cộng điểm, theo Lua gốc.

**K:** các cửa sổ *SkillStudy, sách kỹ năng (ActionSkill, CommonSkill...), phần điểm của SelfData.

**Đạt khi** đủ chuỗi nhập phái, học một chiêu, chiêu lên thanh kỹ năng, cộng điểm.

### G8 — Chat

**M:** tin chat theo gói gốc, kênh theo gốc. Kênh vượt cảnh cần `world` nhận việc định tuyến (B14).

**K:** ChatFrame và các cửa sổ chat con bằng script.

**Đạt khi** hai client (hoặc client và bot) chat qua lại ở từng kênh có trong gốc.

### G9 — Tổ đội, hảo hữu, thư

**M:** nối `social` qua `world`; thay 30 số tự đặt của `social_limits.tsv` bằng số gốc hoặc ghi rõ
không có.

**K:** TeamFrame, PartyFrame, Friend, Mail bằng script.

**Đạt khi** mời vào đội, PartyFrame hiện đồng đội, kết bạn, gửi và nhận thư giữa hai nhân vật.

### 5.10 Sau G9

Thứ tự dự kiến: giao dịch và bày bán, bang hội, trân thú, cưỡi và ngoại hình, cường hoá và khảm,
thương thành ingot (billing qua `world`), PvP, hoạt động, kỹ năng sống, phó bản. Điều phối lập phiếu
khi tới.

### 5.11 Việc đệm, khi chờ làn kia

- **K:**
  - Cửa sổ cài đặt (SystemSetup, GameSetup, ViewSetup, SoundSetup);
  - phím, bánh xe, nhấn đúp vào host (`LUA-GEN/HOST.md:45-50`);
  - MessageBox_Self/Other, ContexMenu;
  - mở host ở luồng chuẩn bị cho đỡ 469–522 ms nạp đầu;
  - chạy lại `ui_script_survey` và ghi số;
  - H2: giữ `io.open`, `os.time`, `os.date` mà script gốc dùng, đặt `nil` các hàm còn lại của `io`
    và `os`, ghi `// Khác gốc:` (LuaState::Init của gốc mở đủ `io` và `os`). Kiểm: Agreement vẫn
    chạy và chụp được.
  - Nút duyệt thú cưỡi ("Thú trước", "Thú sau", "Chưa cưỡi 0/N" ở `face.cpp` `paint_ride_switch`)
    là công cụ dev, client gốc không có: chỉ vẽ và nhận click khi mở bằng `--mount`; không xoá mã
    (f7 chốt 2026-10-18, giao cùng G1-K phần 2).
- **M:**
  - H1 (hack tốc độ) cùng B19 (quét đoạn đi): port kiểm di chuyển của mã 2008, giữ toán tử, kèm
    chế độ bot gửi Move nhanh gấp 4 lần để chứng minh bị kéo về;
  - B21 (nhiệm vụ thiếu dòng);
  - đọc `rules/*.toml` lúc chạy thay cho số viết cứng;
  - `box_recycle_ms`.

### 5.12 Gói nội dung của làn N

Bằng chứng gốc chính: script máy chủ XJL7457 (`G:\XJL7457\Server\rootfs\home\tlbb\Public\Data\Script`,
trong đó `event/` có 1 700 tệp chia theo mảng: `fuben`, `bossgroup`, `huodong`, `festival`, `juqing`,
`shimen`, `xunhuan`, `caoyun`, `quiz`, `challenge`, các phụ bản `piaomiaofeng`, `sijuezhuang`,
`yanziwu`, `langhuanfudi`...), cấu hình `...\Server\Config\CopyScene.ini`, `SceneInfo.ini`,
`MonsterDropBoxs.txt`, script và bảng của client 2026 (`src/client/script/Config/event/**`), mã
2008. Máy chủ của ta không chạy Lua (quyết định đã chốt): script gốc được trích tĩnh bằng
`TOOLS/server/lua_*.py` thành bảng, `mission`, `talk`, `ops` chạy các bảng ấy. Hoàn thiện nội dung là
mở rộng bộ trích và bộ chạy cho từng mẫu script gốc, không viết tay nội dung.

- **N0 — Kiểm kê nội dung gốc (không viết mã).**
  - Sản phẩm: `docs/giao-viec/HOAN-THIEN/NOI-DUNG.tsv` kèm một trang tóm tắt `N0.md`.
  - Mỗi dòng TSV là một chuỗi nhiệm vụ, phụ bản, boss hay sự kiện, với các cột: tên gốc, loại, cấp
    vào, NPC vào, điều kiện (đội, giờ, vật phẩm), tệp bằng chứng, mẫu script dùng, trạng thái ở ta
    (chạy được, trích được nhưng thiếu bộ chạy, chưa trích), cửa sổ client liên quan, phụ thuộc gói
    khác (G4 chiến đấu, G5 túi, G9 đội...).
  - Kèm danh sách mẫu script mà bộ trích chưa hiểu, xếp theo số dòng nội dung bị chặn: 1 330/3 916
    điểm vào hội thoại chưa trích, 286 nhiệm vụ không chạy, 827/1 617 id nhiệm vụ của client không
    có dòng.
  - Đề xuất thứ tự theo đường lên cấp của người chơi.
  - Điều phối duyệt N0 rồi mới chốt thứ tự N2–N6.
- **N1 — G3** (mục 5): NPC, hội thoại, nhiệm vụ, ExecuteScript, UI_COMMAND, chuỗi tân thủ. Bắt đầu
  sau khi G0 có cụm chạy và `--script`.
- **N2 — Chuỗi nhiệm vụ chính theo cấp:** cốt truyện và nhiệm vụ vùng theo thứ tự lên cấp, tới mức
  N0 chỉ ra.
- **N3 — Nhiệm vụ lặp:** sư môn, nhiệm vụ vòng, vận tiêu, nhiệm vụ hằng ngày, theo luật gốc (số
  vòng, thưởng, giới hạn mỗi ngày theo giờ máy chủ).
- **N4 — Phụ bản:** hạ tầng cảnh bản sao theo `CopyScene.ini` (tạo theo người hay theo đội, giờ,
  ra vào, thưởng; móc vào `zone` theo luật khoá), rồi một phụ bản đi được trọn từ vào tới thưởng,
  rồi các phụ bản còn lại. Phụ bản cần đội thì phụ thuộc G9: làm phụ bản đi một mình trước, tới lúc
  cần đội thì nhắn điều phối để kéo G9 lên.
- **N5 — Boss:** nhóm boss (`bossgroup`, `BossCreatLingPai.lua`), lịch xuất hiện, chiêu và AI riêng,
  thời gian xác `DefaultBossBodyTime`, rơi đồ. Cần G4 (quái ra đòn) đạt trước.
- **N6 — Sự kiện:** lịch hoạt động theo giờ máy chủ (`huodong`, `festival`, `quiz`, `challenge`...),
  thông báo toàn máy chủ, thưởng.

**Quyết định sau N0 (điều phối chốt 2026-10-18, đọc `N0.md` và `NOI-DUNG.tsv`).**

1. Nhiệm vụ 1400 初涉江湖 cấp tự động ở lần đăng nhập đầu sau khi tạo nhân vật, trả tại 赵天师. Bằng
   chứng: danh bạ 2026 ghi giver −1, mục tiêu là "đã tìm thấy 赵天师"; cơ chế cấp lúc đăng nhập đầu là
   `scene.lua:805` (XJL7457 cấp 718/210238 của bản 2008). Ghi `Khác gốc:` vì id lấy theo 2026.
2. Id nhiệm vụ chưa có dòng máy chủ (804/1 616): không dựng từ MisDesc, vì MisDesc thiếu mục tiêu và
   thưởng, dựng ra là tự chế. Trước khi kết luận "chờ nguồn", làn N phải đối chiếu các id ấy với bảng
   nhiệm vụ dữ liệu của XJL7457: `Public\Config\Mission_Delivery.txt` 768 dòng, `Mission_LootItem.txt`
   304, `Mission_KillMonster.txt` 215, `Mission_EnterArea.txt` 63, `Mission_NpcDefault.txt` 20,
   `Mission_Husong.txt` 8, cùng các `Mission*_HashTable.txt`. Làm thêm như vậy với bảng nhiệm vụ của
   client 2026 nếu có. Id nào có mục tiêu và thưởng ở các nguồn đó thì vào N2.
3. Hoạt động chỉ có ở client 2026 (43) và chỉ có logic ở add-on mod (17): hoãn, ghi trong
   `NOI-DUNG.tsv`. Add-on mod (2018–2023) không phải bằng chứng gốc, không dùng làm tham chiếu luật
   hay số. Đơn vị Lua gốc bị mod chạm thì lấy phần `chinh_thuc`, phần mod ghi rõ. Khi Lua lệch dữ
   liệu client 2026 ở thứ client hiển thị (cấp vào, giờ mở trong lịch hoạt động) thì lấy số của
   client 2026 và ghi `Khác gốc:` nêu cả hai nguồn. Ví dụ: 燕子坞 75 và 60, 少室山 80 và 60.
4. Lỗi trong Lua gốc: giữ hành vi người chơi quan sát được. Chỉ sửa chỗ mà ở bản gốc gây lỗi lúc chạy
   làm tính năng hỏng (biến chưa khai báo, hằng bị chú thích mà vẫn dùng, bảng thiếu môn phái), sửa ít
   nhất có thể, ghi `// Khác gốc:` kèm tệp:dòng Lua. Logic lạ mà vẫn chạy được (như điều kiện đảo) thì
   port y nguyên và ghi vào `NGHI-NGO.md`.
5. Lỗi bộ trích `lua_units.py:read_script_dat` (giữ chú thích `;` nên 147 mục `Script.dat` mất) sửa
   ở đầu N1, kèm test hồi quy (đỏ trước, xanh sau).
6. Thứ tự: theo bảng mục 5 của `N0.md`. N4 gồm cả hạ tầng cảnh bản sao ở `zone`, theo luật khoá với
   M. N5 bắt đầu khi G4 đạt (quái ra đòn).

Mỗi gói N có phiếu `N<n>.md` như gói G. Tiêu chí đạt chung: kịch bản E2E đi trọn nội dung từ NPC vào
tới thưởng (client thật cho phần có giao diện, bot cho phần lặp nhiều), mỗi bước có ảnh, dòng log
mạng và dòng kiểm của máy chủ; số thưởng, giờ, giới hạn trùng script gốc (trích dòng). Kiểm chéo:
M kiểm phần máy chủ, K kiểm phần client.

### 5.13 Gói I1 — đồng bộ i18n (làn N, giao 2026-10-18)

Theo mục 0.1, chủ dự án yêu cầu "làm đồng bộ và chuẩn xác tuyệt đối". Hiện trạng do điều phối đo
2026-10-18:

- `zh` và `en` có cùng 120 604 khoá, không trùng, không rỗng. `vi` có 120 643 khoá, thừa 39 khoá không có
  ở zh/en (ví dụ `BHKF_150323_198`, `DLJM_XML_46`).
- Chữ Hán trong `en` và `vi`: con số 16 mục ghi lúc giao là sai. 43 đo lại và điều phối tái hiện
  được: 0 giá trị giống `zh`, 0 giá trị còn chữ Hán ngoài thẻ `#{...}`. Có 164 giá trị chỉ còn chữ
  Hán bên trong thẻ `#{...}`; đó là dữ liệu dẫn đường tới NPC, giữ nguyên.
- 39 khoá thừa của `vi` đều có trong `StrDictionary` gốc và được `SelectServer.lua` cùng
  `select_server.cpp` dùng, nên không có khoá mồ côi.
- Mã client có 117 chuỗi chữ Hán viết cứng (literal ngoài comment) ở 19 tệp: `npc_talk.cpp` 27,
  `maps.cpp` 22, `servers.cpp` 17, `online.cpp` 12… Lúc giao ghi 104 vì đếm theo dòng.
- Thoại máy chủ có `dialogue.zh.txt` 3703 dòng và `dialogue.vi.txt` 3699 dòng, chưa có `dialogue.en.txt`.

Việc:

1. Cổng kiểm chạy trong ctest, đỏ khi:
   - ba bộ khoá lệch nhau;
   - en hay vi còn chữ Hán ngoài thẻ `#{...}`;
   - khoá mà mã, layout hay script dùng bị thiếu;
   - ba bản thoại máy chủ lệch khoá;
   - chuỗi Hán hiển thị viết cứng trong `src/client`, với danh sách nền chỉ được co lại.
   Luật "khoá dùng mà thiếu" có danh sách nền chỉ được co lại cho layout (306 khoá) và script Lua
   gốc (15 575 khoá): dịch một lúc 16 nghìn khoá là trái mục 0.1. Khoá mã C++ dùng (72) không vào
   danh sách nền mà sửa hết trong I1, vì đó là mã của ta.
   Thêm luật (f): cùng chữ `zh` mà bản dịch khác nhau. Danh sách nền chỉ được co lại, sinh từ
   số đo 2026-10-18: `vi` có 269 nhóm (202 nhóm chữ ngắn tới 8 ký tự), `en` có 80 nhóm.
2. Sửa chỗ lệch hiện có:
   - thêm 39 khoá vào `zh` (chữ gốc) và `en` (dịch theo glossary);
   - tạo `dialogue.en.txt`;
   - bù 4 dòng lệch của vi;
   - lập `docs/DICH-TAY.txt` theo mục 0.1 điểm 4. Mỗi nhóm không thống nhất là một dòng, xếp theo
     số khoá giảm dần, các cột tách bằng tab: chữ `zh`, ngôn ngữ, các bản đang dùng kèm số khoá,
     khoá ví dụ, kết quả tra bản Việt Nam (nguồn, hoặc "không thấy"), và cột trống cho chủ dự án.
     Nhóm tra thấy nguồn thì áp luôn rồi gỡ khỏi danh sách nền (f).
3. Chuỗi cứng trong các tệp đợt này đã chạm chuyển sang khoá i18n.

Kiểm: cổng xanh (cài lỗi cố ý thấy đỏ), ctest đủ, ảnh bản `zh` và một bản dịch. Kiểm chéo: K.

## 6. Quy trình một gói và kiểm chéo

1. Phiếu (mục 5), làn kia duyệt.
2. Viết mã. Đọc mã xung quanh và bằng chứng gốc trước; port giữ toán tử và thứ tự.
3. Tự kiểm của người làm:
   - dựng 0 cảnh báo, đọc hết log;
   - `ctest` của cây mình xanh (chạy nền);
   - `node ~/.claude/bin/shape.js --diff .` sạch trên dòng mình viết;
   - `TOOLS/source_headers/source_headers.py --fix` cho tệp đã chạm (tệp lạ cần `--describe`);
   - cài bản mới (K: `dev/client/bin`, giữ đúng một `.bak-<ngày>-<nhãn>`; M: `dev/server`);
   - chạy kịch bản E2E của gói.
4. Nhắn làn kia và điều phối `XIN KIỂM G<n>-<K|M>`, kèm:
   - danh sách tệp đã đổi;
   - lệnh E2E;
   - đường dẫn ảnh và log (để trong `build/e2e/G<n>/`);
   - các bằng chứng gốc đã dùng.
5. Người kiểm (làn kia):
   - tự chạy lại kịch bản E2E trên cây hiện tại;
   - mở đúng địa chỉ mã máy hay dòng Lua được trích để xác nhận mã làm đúng như vậy;
   - soát thứ tự chế;
   - soát luật mã (sở hữu, lỗi, dữ liệu từ mạng là thù địch, phẳng, tên);
   - trả `G<n>-<K|M> ĐẠT` hoặc `KHÔNG ĐẠT` với danh sách cụ thể (tệp:dòng, bằng chứng).
   
   Hai vòng không thống nhất thì nhắn điều phối phân xử.
6. Commit sau khi ĐẠT:
   - một tính năng một commit, chỉ đường dẫn của mình;
   - tệp mới thì `git add -- <tệp mới>` cùng lệnh `git commit -F <tệp thông điệp> -- <mọi đường dẫn>`
     trong một lệnh Bash;
   - kiểm `git show --stat HEAD`;
   - thông điệp tiếng Việt, dòng đầu `G<n> <K|M>: <việc>`, thân nêu bằng chứng gốc, kết quả E2E,
     dòng `Kiểm chéo: <phiên> ĐẠT`;
   - M commit phần giao thức và máy chủ trước; K commit phần client dựa trên đó sau, để mỗi commit
     tự dựng được;
   - ngay sau commit, nhắn điều phối một dòng `COMMIT <hash> <gói>, kiểm chéo <phiên> ĐẠT`.
7. Điều phối chạy lại E2E của gói trên HEAD, cập nhật `DU-AN.md` và tệp này, rồi push. Không làn nào
   tự push. Trước khi push, điều phối đọc `git log origin/chuan-hoa..HEAD` ở một lệnh riêng; commit
   nào trong đó chưa kiểm trên HEAD thì kiểm xong mới push (hai lần 2026-10-18 lượt push hồ sơ kéo
   theo commit của làn chưa kiểm: `8030927b`, `81bb6785`, cả hai kiểm bù đạt).
8. Cây vcpkg: từ 2026-10-18 mỗi dự án có cây riêng, `C:\dev\third_party\installed\thienlong`. Chủ
   máy chốt việc tách vì cây chung bị dự án khác gỡ gói ba lần trong một ngày. Toolchain chung tự đặt
   cây theo `name` trong `vcpkg.json`, và cài theo manifest lại được bật. Mỗi cây build cũ phải
   configure lại một lần với `--fresh`; không có bước đó, cache còn trỏ vào cây chung cũ.

## 7. Lệnh kiểm thực E2E

Mọi lệnh dưới chạy nền (`run_in_background`), chờ thông báo, không ngủ chờ.

```
python -B TOOLS/server/local_cluster.py start — còn status, stop; log ở dev/server/log/cluster_*.txt
build\lane-server\thienlong_bot.exe --identity dev\server\data\gate\identity.key --game 7100 --auth 7101 --count 1 --seconds 8
cmd /c "set THIENLONG_ACCOUNT=e2ek0a1&& cd /d dev\client\bin && thienlong_client.exe --login --frames 4000 --shot ..\..\..\build\e2e\G0\vao.png"
python -B TOOLS/run/desk_watch.py <lệnh> [đối số]... — mã thoát là mã của lệnh
```

- `--shot` phải đi cùng `--frames` (từ 30 trở lên), nếu không client không thoát.
- Ảnh đọc ngược từ swapchain, nên cửa sổ bị che vẫn chụp đúng.
- So ảnh với nhau thì thêm `--bare`.
- Kiểm bảng máy chủ: `thienlong_lint --root dev\server --refs TOOLS\server\refs`.

## 8. Bẫy đã biết

- Worktree sạch thiếu `dev/server/tables/shared` (bị ignore). Test đọc bảng thật khi đó đỏ hoặc bỏ
  ca lặng lẽ. Làm việc ở cây chính.
- `msvc-release` mặc định cài vào `release/`; cài vào `dev` phải có `--prefix dev`.
- Exe máy chủ cũ sẽ bị gate từ chối (`min_version = 7`, `allowed_builds`).
- `G:\XTLBB` là client gốc. Tài liệu nào ghi `D:\XTLBB` hay `F:\tl 2026\2026` là cũ.
- `.bat` Ghidra cũ trỏ `Desktop\ghidra` đã mất; dùng `C:\dev\ghidra\ghidra_12.1.4_PUBLIC` và REA.
- `open_binary` của REA cần `snapshot_path` đã tồn tại.
- Thông báo lỗi tiếng Việt dài làm guard tràn dòng; rút ngắn, đừng bẻ dòng.
- Gói `.f2s` đổi khi sửa `compiler.cpp` hay `reconcile.cpp`: tăng `kPipeline`. Exe client phải đi
  cùng `shaders/` của cùng bản dựng.
- `layers` (ctest) là cổng tầng: client không thấy server, `display` không đọc `table`. Đỏ thì sửa
  chỗ đặt mã, không sửa bảng tầng để lách.

## 9. Trạng thái gói

| Gói | K | M | Ghi chú |
|---|---|---|---|
| G0 | đạt (`9adc2de5`, `d08b9b6e`) | đạt (`bba77680`) | Điều phối chạy lại trên HEAD 2026-10-18: bot 6/6 đạt; client tạo nhân vật, vào game, đi, bot quan sát thấy. Đã push |
| G1 | đang làm; phần 1 đạt (`a9ab3e1a`: SceneTrans chạy script gốc, sửa Move đầu); phần 2 đạt (`8030927b`: host chạy ở màn đăng nhập, SoftKeyBoard chạy script gốc); `41f14873` nút duyệt thú chỉ với `--mount`; phần 3a đạt (`4762aaac`: client giao thức v9, nền script SelectRole); còn SelectRole chạy script | đạt (`81bb6785` D4 điểm sinh; `77be2269` D1–D3 xoá nhân vật bảy bước, v9 chân dung và bộ đồ) | Điều phối kiểm chuỗi trên HEAD `4762aaac`: `--roster` 14/14 mã đúng bảng D2; client v9 tạo nhân vật tài khoản mới và vào game; bot 6/6 (v9) |
| G2 | đang làm; phần 1 đạt (`020df092`: tên, thanh máu, chữ bay vẽ dưới cửa sổ) | chưa | Điều phối kiểm `020df092`: ảnh 任务日志 mở che tên 赵天师, 都大爽 |
| G3 | — | — | Làn N làm cả gói (N1) |
| G4 | chưa | chưa | |
| G5 | chưa | chưa | |
| G6 | chưa | chưa | |
| G7 | chưa | chưa | |
| G8 | chưa | chưa | |
| G9 | chưa | chưa | |
| B19, H1 | — | B19 đạt (`6af42661`: `Scene::blocked` kiểm cả đoạn đi); H1-B chưa | Điều phối kiểm B19 trên HEAD `8692e3e1`: bot `--leap 1` 4/4 bị đặt lại, `e2e_g0` đạt |

### Dừng và mở lại 2026-10-18

Chủ dự án dừng ba làn để máy nghỉ, đóng phiên trước khi các làn kịp ghi bàn giao. Ổ D đầy (499 MB), nên cây build
thừa (`msvc-release-dev*`, `msvc-release-r1`, `laneA`, `android-zc`, `android-pace`, `lane-*`, `i18n-vi`, `build` trong
hai worktree) chuyển sang `E:\THIENLONG-build-cu` (không xoá). `main` fast-forward tới `chuan-hoa` `77d444a0` và push.
Việc dở chưa kiểm của ba làn chụp ở nhánh `luu-tam/2026-10-18-viec-do` (`9c8da77a`, đã push); cây làm việc giữ nguyên:

- K: SelectRole chạy script (`native_login.cpp`, `login_port.hpp`, khối đăng ký, `hud.cpp`, `bridge` kiểm phạm vi
  portrait, `ui_flow_tests` bớt ba ca); E2E SelectRole chưa chạy.
- M: H1 quỹ quãng đường KHÔNG ĐẠT điểm 1 (kiểm chéo 14: quỹ 2 s đóng phiên khi mạng đứng từ 2,4 s rồi dồn gói, Pace
  cũ không đóng ở 1–10 s, quỹ 5 s chịu khoảng 3 s; mô phỏng ở `D:\THIENLONG-luu-tru\kiem-cheo\2026-10-18-h1\`); B19 ổn.
- N: `quest/misdesc` và `quest_misdesc_tests`; các sửa clang-tidy sau lần dựng cuối chưa dựng lại.

`CMakeLists.txt` trong cây chứa hunk của K (native_login) lẫn N (quest/misdesc): mỗi làn chỉ đưa hunk của mình vào index.

| Gói N | Trạng thái | Ghi chú |
|---|---|---|
| N0 | đạt | Điều phối duyệt 2026-10-18; quyết định ở mục 5.12 |
| N1 (G3) | đang làm; phần 1 đạt (`1381feef`: cấp 1400 lần vào đầu, menu 赵天师 hết mục chết, hết `}` thừa, giao thức v8) | Điều phối kiểm trên HEAD: bot 6/6, `n1-tanthu` A 12/12. Phần 2 đạt (`2a03a240`: dòng nhiệm vụ dùng biểu tượng QuestButtonImage). Phần 3 đạt (`5b5610fc`, `3badaae4`: 10 hàm DataPool sổ nhiệm vụ, QuestLog script mở không sập). Phần 2a đạt (`8692e3e1`: bộ đọc MisDesc, đối chiếu Game.exe; ánh xạ hai bảng hàm còn chờ đọc mảng con trỏ, NGHI-NGO 76). Còn: bước 2b khoảng 35 hàm DataPool, QuestLog còn trống, MissionTrack |
| N2 | chưa | |
| N3 | chưa | |
| N4 | chưa | Phụ bản cần đội phụ thuộc G9 |
| N5 | chưa | Cần G4 |
| N6 | chưa | |
