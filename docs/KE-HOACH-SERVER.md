# Kế hoạch máy chủ THIENLONG

Soạn và được chủ dự án duyệt ngày 2026-10-06. Phụ lục `docs/SERVER-TEP-CAU-HINH.md` liệt kê từng
tệp cấu hình và từng bảng máy chủ cần, tên gốc sang tên mới bằng tiếng Anh.

Trạng thái theo mã ngày 2026-10-09 (chi tiết và số đo ở mục 10): P0 và P1 đạt; P2 đạt đợt 1 và
đợt 2, đợt 3 có `secure`, mặt trước của `gate` và `metrics` (gói P2-2), còn thiếu `ipc` và việc
gate chuyển tiếp. Mã C++ của máy chủ gồm mười hai module (`config`, `content`, `linttool`,
`process`, `supervise`, `service`, `protocol`, `net`, `secure`, `gate`, `metrics`, `metrics/serve`)
và bảy `main`; năm exe `store`, `auth`, `billing`, `world`, `zone` mới mở cổng đọc số đo, in
`ready metrics=<cổng>` rồi chờ dừng. P3 trở đi chưa có dòng mã nào:
`SERVER/sql` trống, chưa có `store`, `ipc`, `link`, chưa có logic tài khoản, nhân vật hay cảnh.

Nhãn dùng trong tệp: **[đo]** là số đọc trực tiếp từ tệp trên đĩa hoặc kết quả đã chạy; **[suy]**
là suy luận từ thứ đã đo; **[đề xuất]** là chi tiết thiết kế nằm trong kế hoạch đã duyệt nhưng chưa
có mã hay số đo; **[chốt]** là điều chủ dự án nói rõ ngày 2026-10-06.

## 1. Quyết định

Chủ dự án nêu ngày 2026-10-08: máy chủ thiết kế cho cả Linux và Windows. Hệ quả cho mã và cho
việc kiểm:

- Mọi chỗ phụ thuộc hệ điều hành nằm sau một mặt phẳng chung, có đủ hai bản cài đặt, tệp
  `_win32.cpp` và tệp `_posix.cpp`; không gọi API của hệ điều hành ở nơi khác. Đã vậy ở `core`
  (luồng, handle, log, hệ thống), `process`, và `net` của đợt P2-DOT-2 (`WSAPoll` và `poll`).
  Đợt giao việc nào thêm mã phụ thuộc hệ điều hành thì đề bài phải đòi cả hai bản.
- Thực trạng ngày 2026-10-08 **[đo]**: bản POSIX mới qua kiểm cú pháp bằng trình dịch của NDK
  (hai ABI), CHƯA dựng và CHƯA chạy trên Linux lần nào. Máy phát triển có WSL nhưng chưa có
  distro; các preset `gcc-asan`, `clang-tsan`, `ci-gcc` cho Linux có sẵn mà chưa ai chạy.
- Còn phải làm để nói được "chạy trên Linux": cài một distro WSL (hoặc có máy Linux), dựng
  `tomlplusplus` và `libpq` cho triplet Linux, chạy trọn `ctest` và bộ kiểm đầu cuối của trình
  giám sát ở đó. Chưa có các bước này trong bảng mốc; thêm vào khi có môi trường Linux.

Chủ dự án chốt ngày 2026-10-06 **[chốt]**:

- Không Lua. Máy chủ và client không nhúng máy kịch bản.
- Tệp cấu hình là TOML. Bảng theo dòng vẫn là TSV.
- Cơ sở dữ liệu là PostgreSQL.
- Có máy chủ billing riêng.
- Tên tệp cấu hình và bảng viết bằng tiếng Anh, không pinyin.
- `SERVER/` nằm ngang `CLIENT/` và chứa trọn runtime của máy chủ: exe, cấu hình, bảng, cảnh, SQL, cả
  nhị phân và dữ liệu của PostgreSQL.
- Không có chế độ offline. Máy phát triển này là máy chủ thử online: client nối thẳng vào nó.
- Thêm hai phụ thuộc `tomlplusplus` và `libpq`.
- Bảng chỉ máy chủ giữ vào git. Bảng xuất từ client thì không: sinh lại bằng công cụ, như
  `CLIENT/data`.
- Làm nội dung bản 0859602 trước vì chỉ bản đó có đủ dữ liệu phía máy chủ, rồi mở lên 2026 theo
  từng hệ.
- Mọi cài đặt trong tệp cấu hình có chú thích tiếng Việt, không sót. Bố cục theo mẫu chủ dự án
  đưa: khung tiêu đề kẹp giữa hai dòng `#====` cho tệp và cho từng nhóm, cài đặt nằm sát nhau,
  chú thích ngang hàng, căn thẳng cột (mục 6).
- Từ `AGENTS.md`: mã là C++23, công cụ dữ liệu là Python; logic game port từ `G:\TLBB\Dev` kèm test;
  kiểu lỗi giữ `core::Result`, `core::Status`, `core::Error`.

Ranh giới của TOML:

- TOML cho cấu hình tiến trình và luật chơi có khoá đặt tên: có kiểu, có chú thích, có bảng lồng và
  mảng bảng. `[Server0]`, `[Server1]` của `ServerInfo.ini` thành `[[process]]`; khoá trùng và cú
  pháp sai bị từ chối thay vì đọc ra 0 như bộ đọc ini gốc.
- Không dùng TOML cho bảng theo dòng. Vật phẩm, kỹ năng, quái có hàng chục nghìn dòng: giữ TSV, đọc
  bằng `table::Tsv` đã có. Khoá đặt tên khác nhau thì TOML, bản ghi cùng hình thì TSV.
- Số thực trong luật chơi đổi sang số nguyên phần nghìn hoặc phần triệu (`DropParam=1.0` thành
  `drop_rate_permille = 1000`), để logic không phụ thuộc cách làm tròn số thực.
- Bộ đọc là `tomlplusplus` 3.4.0, gói trong module `config`; ngoài module chỉ thấy struct đã kiểm
  miền. Đã thử ở P0 **[đo]**: chế độ header-only với `TOML_EXCEPTIONS=0`, dịch khi tắt hẳn
  exception trên MSVC và Clang; cú pháp sai và khoá trùng trả lỗi kèm số dòng. Thư viện dịch sẵn của
  cổng vcpkg bật exception nên không link nó, chỉ lấy thư mục include.
- Khoá lạ là lỗi khởi động, không bỏ qua: gõ sai tên khoá là kiểu lỗi cấu hình hay gặp nhất.

Hệ quả của việc bỏ chế độ offline: kho bền chỉ có một backend là PostgreSQL, kèm một bản giả trong
bộ nhớ cho test. Lõi logic vẫn không được biết socket và database, nhưng lý do giờ chỉ còn là để
test chạy được mà không cần mạng hay database.

## 2. Thứ đã đọc và số đo

Mã nguồn máy chủ 2008 (`Desktop\New folder\tlbb_server`) **[đo]**:

- 338.953 dòng `.cpp` và `.h`: GameServer 193.252, Common 103.965, WorldServer 20.190, LoginServer
  11.866, BillingServer 5.873, ShareMemory 3.807.
- 435 mã gói: client và game 145 chiều lên, 194 chiều xuống; game và world 39 và 31; login 12; còn
  lại là nội bộ. Đầu gói là `PacketID_t + WORD + UINT`, thân là struct chép thẳng.
- Năm tiến trình: Login, World, Server, ShareMemory, Billing. Server chạy mỗi nhóm cảnh một luồng
  (`threadindex` của `SceneInfo.ini`), nhận kết nối bằng `select`.
- Chiến đấu lái bằng bảng: 52 tệp `SkillLogic`, 127 tệp `ImpactLogic`, 10 tệp `SpecialObjLogic`,
  chọn theo logic id ghi trong `SkillData_V1.txt` và `StandardImpact.txt`.
- Kịch bản: Lua 4.0 qua `FoxScriptEngine`, hàm C++ xuất cho Lua nằm ở 14 tệp `LuaFnTbl_*.h`.

Bản chạy 0859602 (`TLBB_0859602_Win10_11`) **[đo]**:

- `Server/Config` 113 tệp, `Public/Config` 91 tệp và 180 tệp trong ba thư mục con, `Public/Scene`
  3.251 tệp (244 `.scn`, 231 `.nav`), 4.248 tệp Lua, 269 tệp `.ai`, `Script.dat` 4.957 dòng.
- `tlbbdb.sql` 38 bảng; `t_char` có 12 cột text chứa khối dữ liệu mã hoá thành chữ. `web.sql` 15
  bảng của billing.
- Thứ tự khởi động trong `run.bat`: MariaDB, ShareMemory, Billing, World, Login, Server.
- Nhịp ghi xuống DB: `DATAInterval=900000` (15 phút) cho nhân vật, `SMUInterval=1200000` (20 phút)
  cho dữ liệu world.
- Năm exe đều bị đóng gói (section `XueWu0`, `XueWu1`): không đọc tĩnh được chuỗi hay tên lớp.

Client 2026 (`F:\tl 2026`) **[đo]**:

- `Config` 722 tệp, 718 là bảng DBC nhị phân; 83 bảng trùng tên với `Public/Config` của 0859602,
  574 bảng mới và 61 tệp biến thể theo loại máy chủ.
- `Script.dat` 16.553 dòng. `SkillTemplate_V1` 4.586 bản ghi (0859602: 835 dòng).
- Trong 2.047 tệp Lua giao diện, lời gọi lên máy chủ dùng 820 script id và 1.480 tên hàm khác
  nhau.
- Cảnh: 513 `.scene`, 469 `.region`, 435 `.wcollision`, 419 `.path`, 473 `.heightmap`.

Máy chủ M1 của TLBB Dev (`G:\TLBB\Dev`) **[đo]** từ `docs/SERVER.md`, `PROTOCOL.md`, `KIEN-TRUC.md`,
`LOGIC.md` và cây `src`:

- Bốn tiến trình: `tlbb_server` giám sát, `tlbb_gate`, `tlbb_authd`, `tlbb_worldd`. Tick 20 Hz.
- Protocol tự viết bản 5: TCP, khung 8 byte, ghi từng trường little-endian, SecureStream ở dưới.
- Kho bền `persist::Store` (tệp ghi nối, lô nguyên tử), bảng TSV, cấu hình `server.cfg` dạng
  `khoá = giá trị`. Đã quyết "không Lua" ngày 2026-10-03.
- Chưa có: lưới đi, quái đánh lại, máy chủ trên Linux, chống kết nối dồn dập theo IP.

Nguồn gốc còn trên đĩa mà bản kế hoạch ngày 2026-10-06 chưa tính **[đo]** ngày 2026-10-08, ở
`G:\TLBB\_ref` (chỉ đọc):

- `G:\TLBB\_ref\server` là cùng bộ mã 2008 với `Desktop\New folder\tlbb_server`: 2.070 tệp, lệch
  nhau bốn tệp sửa để dựng (`FileAPI.h` đổi tên, `hash_map` thành `unordered_map`).
- `G:\TLBB\_ref\runtime\server-x86\Server` có bốn tệp chạy Linux của chính hãng CHƯA strip:
  `Server` (89.923.985 byte), `World`, `Login`, `ShareMemory`, ELF32 i386, dựng bằng GCC 3.4.6 tại
  `/home/build/v0-85-8130/`, còn nguyên `.symtab` và DWARF (`.debug_info` của `Server` 65,7 MB).
  `Server` có 20.157 hàm mang tên, ví dụ `Combat_Module::CombatCore_T::IsCriticalHit(int, int)`,
  `Scene::CalcZoneID(const WORLD_POS*)`. Đây là bản 0.85.8130, cùng dòng 0.85 với bản chạy
  0859602 (0.85.9602) mà năm exe Windows của nó bị đóng gói. `objdump` của MinGW trên máy này
  tháo được từng hàm kèm tên:
  `objdump -d -C --no-show-raw-insn --start-address=<địa chỉ> --stop-address=<địa chỉ> Server`,
  địa chỉ và cỡ hàm lấy bằng `readelf -s -W Server | grep <tên>`. Hàm ví dụ trên dài 49 byte: kẹp
  tỉ lệ chí mạng về 0 tới 9999 rồi so với số ngẫu nhiên.
- `G:\TLBB\_ref\runtime\server-x64` là một bản chạy Linux dựng tháng 11 năm 2024: `Server` ELF64 có
  `.symtab`, không có DWARF; `SqlScript\newtlbb.sql` 41 bảng, thêm `t_auction*`, `t_sect`,
  `t_xiulian`, `t_exterior_fashion`, `t_pet_bank` so với 38 bảng của 0859602. Số phiên bản chưa
  xác định.
- Hai cây đó mang theo trọn dữ liệu (`Public`, `Server\Config`), nên có ba bộ dữ liệu máy chủ chứ
  không phải một, và hình dạng bảng của chúng khác nhau (số cột, số dòng kể cả dòng đầu):

| Bảng | 0859602 | `server-x86` | `server-x64` | Client 2026 (`TOOLS/server/table_census.tsv`) |
|---|---|---|---|---|
| `SkillTemplate_V1` | 79 cột, 835 | 99 cột, 1.316 | 79 cột, 1.317 | 102 cột, 4.586 bản ghi |
| `SkillData_V1` | 48 cột, 7.729 | 48 cột, 9.702 | 48 cột, 11.963 | 54 cột, 20.667 bản ghi |
| `StandardImpact` | 76 cột, 9.906 | 76 cột, 14.503 | 81 cột, 15.614 | không có |
| `MonsterAttrExTable` | 70 cột, 9.569 | 280 cột, 15.207 | 71 cột, 11.947 | 73 cột, 28.969 bản ghi |
| `DropBoxContent` | 516 cột, 2.036 | 516 cột, 2.105 | 517 cột, 3.167 | không có |
| `AttrLevelUpTable` | 51 cột, 153 | 61 cột, 153 | 51 cột, 153 | không có |
| `SceneAttr` | 23 cột, 530 | 23 cột, 530 | 23 cột, 1.266 | 26 cột, 32.736 bản ghi |
| Script Lua, tệp `.scn` | 4.248, 244 | 4.654, 257 | 4.446, 260 | không có |

  Dữ liệu trong `server-x86` không cùng hình với bản 0859602 dù tệp chạy cùng dòng 0.85, nên
  không được coi hai cây là một phiên bản. `SERVER/tables` hiện chỉ nhập từ bản 0859602.

Hệ quả cho thiết kế:

- Ngữ nghĩa và công thức của bản 0.85 đối chiếu được bằng mã máy có tên hàm, không chỉ bằng mã
  2008: mỗi công thức port ghi cả tệp 2008 lẫn tên hàm đã tháo trong `server-x86\Server`, chỗ hai
  bên lệch thì bản 0.85.8130 thắng và ghi `Khác gốc:`.
- Trước khi nhập dữ liệu cho một hệ (kỹ năng, quái, rơi đồ), đo ba bộ dữ liệu với bảng của client
  2026 rồi mới chọn nguồn; cột `basis` của tệp cột ghi nguồn đã chọn.
- Bảng chỉ máy chủ giữ của bản 3.71 không có trên đĩa: `StandardImpact`, bảng rơi đồ, AI, điểm sinh
  quái, và thân của khoảng 11.600 script mới. "Đầy đủ như client 2026" là dựng lại nội dung, không
  phải port.
- 820 script id và 1.480 tên hàm là thước đo khối lượng, không phải giao diện phải giữ: giao diện
  THIENLONG viết lại bằng C++ (`ui/panel`), mỗi tính năng có tin mạng có kiểu.

## 3. Tiến trình

Bảy loại tiến trình **[đề xuất]**. Mỗi loại một exe; chế độ một máy do `thienlong_server` spawn
tất cả trên loopback.

| Exe | Vai trò | Nghe | Giữ bí mật | Database | Thay cho bản gốc |
|---|---|---|---|---|---|
| `thienlong_server` | giám sát: đọc `supervisor.toml`, spawn theo thứ tự, chờ dòng `ready`, khởi động lại có trần | cổng quản trị, loopback | không | không | `run.bat`, `xrun.sh` |
| `thienlong_gate` | cổng công khai duy nhất: bắt tay SecureStream, kiểm khung và trần, giới hạn tốc độ, lọc IP, chuyển tiếp | công khai | khoá danh tính | không | `ClientManager` của Server và Login |
| `thienlong_auth` | tài khoản, băm mật khẩu, vé đăng nhập, thẻ bảo mật, khoá tài khoản, giới hạn phiên | nội bộ | khoá ký vé | `auth` | Login (phần tài khoản), Billing (phần xác thực) |
| `thienlong_billing` | điểm nạp, đơn nạp, đổi điểm lấy ingot, quà và mã đổi, đối soát | nội bộ và webhook sau reverse proxy | bí mật của nhà cung cấp thanh toán | `billing` | Billing |
| `thienlong_world` | thứ toàn cục: danh sách và chọn nhân vật, tên, định tuyến người chơi tới cảnh, tổ đội, bang, bạn bè, thư, kênh chat, xếp hạng, lịch hoạt động | nội bộ | không | qua store | World, Login (phần nhân vật) |
| `thienlong_zone` (nhiều) | mô phỏng cảnh: mỗi cảnh một actor, tick 20 Hz; phó bản là cảnh sinh động | nội bộ | không | qua store | Server |
| `thienlong_store` | người ghi duy nhất của database game: nhận delta từ world và zone, ghi nhật ký, gom lô xuống PostgreSQL | nội bộ | mật khẩu DB game | `game` | ShareMemory, `DBThread` |

Thứ tự khởi động: PostgreSQL, store, auth, billing, world, zone, gate. Gate mở sau cùng để cổng công
khai chỉ nhận khách khi phía sau đã sẵn sàng. Dừng theo thứ tự ngược; zone và world đẩy hết delta
cho store rồi store ép đĩa mới thoát.

Vì sao có `thienlong_store` **[đề xuất]**: bản gốc dùng tiến trình ShareMemory để Server sập không
mất dữ liệu trong RAM, nhưng chỉ ghi DB 15 phút một lần. Bản mới giữ ý đó và bỏ khoảng trễ: zone gửi
delta cho store vài giây một lần; zone sập thì mất tối đa vài giây, store sập thì zone giữ delta và
gửi lại. Chỉ store có mật khẩu database game.

Vì sao auth tách khỏi billing: ở bản gốc Login hỏi Billing mới cho đăng nhập (`LBAskAuth`), nên
Billing chết là không ai vào được game. Bản mới để auth đứng một mình trên đường đăng nhập; billing
chết thì chỉ cửa hàng ingot đóng.

Cổng mặc định **[đề xuất]**: gate 7000 (game) và 7001 (xác thực); quản trị 7002; store 7010, auth
7011, billing 7012, world 7013, zone từ 7020; webhook billing 7080 trên loopback; PostgreSQL 5432.

### 3.1 Giao kèo giữa các tiến trình

Đã cài ở P2 đợt 1 (module `process`, `supervise`, `service`; test `process_tests`,
`supervise_tests`, `service_tests`, `server_boot`). Mọi tiến trình sau này giữ đúng giao kèo này.

- Dòng lệnh: `thienlong_server --config <thư mục cấu hình> [--no-postgres]`; tiến trình con
  `thienlong_<loại> --config <thư mục cấu hình> [--id <n>]`. Exe con nằm cùng thư mục với exe giám
  sát. Đối số lạ, thiếu `--config`, `--id` không phải số nguyên không âm: in cách dùng ra stderr,
  thoát 2.
- stdout chỉ cho máy đọc. Con in đúng một dòng sẵn sàng: từ `ready`, rồi các cặp `khoá=số` cách
  nhau đúng một dấu cách, mỗi cặp là một cổng con đang nghe thật (đọc lại từ hệ điều hành, vì cấu
  hình có thể khai cổng 0). Bốn khoá cổng: `game` và `auth` của gate, `ipc` của tiến trình có cổng
  nội bộ, `metrics` của cổng đọc số đo. Từ 2026-10-09 (P2-2) gate in `ready game=<cổng>
  auth=<cổng> metrics=<cổng>` và năm tiến trình kia in `ready metrics=<cổng>`; `ipc=` vào cùng
  `ipc` (P2-10). Bên đọc bỏ qua khoá nó không biết. Khoá cổng phải mang số 1..65535 và không lặp:
  dòng `ready` hỏng (`supervise::parse_ready`) là con hỏng, cụm dừng, thoát 1.
- Cổng `metrics` (module `metrics/serve`): mỗi tiến trình nghe `127.0.0.1` ở một cổng do hệ điều
  hành chọn (địa chỉ viết cứng trong mã, không có khoá cấu hình). Bên đọc nối vào và không gửi gì;
  tiến trình ghi một ảnh chụp văn bản (`metrics 1`, mỗi số một dòng `counter|gauge|phase ...`, rồi
  `end`) và đóng. Tối đa 4 bên chờ tới lượt, mỗi bên có 1 giây để nhận hết; bên thừa và bên quá
  hạn bị huỷ, đếm vào `metrics.reader.dropped`. Ảnh chụp dài tối đa 896.846 byte
  (`metrics::kSnapshotMaxBytes`); mọi bên đọc dùng `metrics::parse_snapshot`. Ngoài tiến trình đọc
  bằng `thienlong_metrics_snap capture --port <cổng> --out <tệp>` rồi `counter`, `gauge`, `phase`
  trên tệp đó (stdout là một số hoặc một dòng `khoá=số`; thoát 0, 1 lỗi lúc chạy, 2 dùng sai).
- Giám sát in `using postgres` hoặc `started postgres`, rồi `started <loại> <id>` cho từng con
  (`started gate` không có id), rồi một dòng `ready` mang mọi cổng các con đã báo, theo thứ tự khởi
  động: `ready <loại>[.<id>].<khoá>=<cổng> ...` (hôm nay `ready store.0.metrics=<cổng> ...
  gate.game=<cổng> gate.auth=<cổng> gate.metrics=<cổng>`; không con nào báo cổng thì `ready`
  trần). Một con chạy lại mà báo cổng khác
  trước thì giám sát in `ports <loại>[.<id>].<khoá>=<cổng> ...` cho riêng con đó. Lúc dừng in
  `stopped <loại> <id>` theo thứ tự ngược, cuối cùng `stopped postgres` nếu chính nó đã chạy
  PostgreSQL. Mọi câu cho người đọc ra stderr, tiếng Việt. Một dòng có trần 4 KiB: dòng của con dài
  hơn là lỗi của con đó; kế hoạch có nhiều tiến trình tới mức dòng `ready` của cụm có thể vượt trần
  (`supervise::ready_line_bound`) thì giám sát từ chối trước khi chạy tiến trình nào, thoát 2.
- Cổng 0 trong cấu hình nghĩa là hệ điều hành chọn cổng lúc nghe. Chỉ bên nghe trên đúng
  `127.0.0.1` được khai cổng 0 (`[listen]` của `gate.toml`, `listen` của `admin.toml`, `port` của
  `[[process]]`); địa chỉ khác và `[postgres] port` thì cổng 0 bị từ chối kèm số dòng. Test và công
  cụ luôn khai `127.0.0.1:0` rồi đọc cổng thật ở dòng `ready`; cấu hình chạy thật khai cổng cố định.
- Cấu hình: giám sát kiểm mọi tệp nó biết (của nó và của từng con) trước khi chạy bất cứ thứ gì;
  con kiểm `cluster.toml`, `log.toml`, tệp của chính nó, và việc `cluster.toml` có khối
  `[[process]]` đúng loại và số của nó. Lỗi in từng dòng `tệp:dòng: câu`, đủ mọi lỗi một lượt, thoát
  2. Không tiến trình nào của đợt này mở `secrets.local.toml`.
- Yêu cầu dừng là một trong hai: stdin đã hết (ống bị đóng, thiết bị rỗng `NUL` hay `/dev/null`,
  tệp thường, handle hỏng) hoặc tín hiệu của console (Ctrl+C, Ctrl+Break, đóng cửa sổ, đăng xuất,
  tắt máy; POSIX: SIGINT, SIGTERM, SIGHUP). stdin là console thì không bao giờ "hết": chỉ tín hiệu
  mới dừng. Tiến trình có stdin là ống thì bỏ qua Ctrl+C và Ctrl+Break: cha nó đóng ống theo đúng
  thứ tự, để Ctrl+C ở cửa sổ giám sát không làm cả cụm dừng cùng lúc.
- Dừng: giám sát đóng stdin của con cuối cùng, chờ nó thoát trong `[stop] timeout_seconds`, quá hạn
  thì buộc dừng và ghi lỗi, rồi tới con trước đó. Yêu cầu dừng tới lúc đang khởi động được nhớ: cụm
  lên cho xong, in `ready`, rồi mới dừng.
- Con chưa `ready` mà hết hạn hoặc chết: dừng các con đã chạy theo thứ tự ngược, thoát 1. Con chết
  sau `ready`: chạy lại, tối đa `[restart] max_per_hour` lần trong một giờ trượt cho mỗi tiến
  trình; quá trần thì dừng cả cụm, thoát 1.
- Mã thoát của giám sát: 0 khi dừng theo yêu cầu và mọi con thoát 0; 1 khi có lỗi lúc chạy; 2 khi
  dòng lệnh hoặc cấu hình sai.
- Giám sát chết bất ngờ: ống đóng theo nên con tự thoát; trên Windows các con còn nằm trong một
  job `KILL_ON_JOB_CLOSE` nên con treo cũng bị dọn. Đo ngày 2026-10-07: giết giám sát, sau 5 giây
  không còn tiến trình `thienlong_*`.
- PostgreSQL, khi `[postgres] managed = true` và không có `--no-postgres`: hỏi `pg_ctl status`;
  đang chạy thì dùng và lúc thoát không dừng; chưa chạy thì `pg_ctl start -w` với hạn
  `ready_timeout_seconds`, lúc thoát `pg_ctl stop -m fast -w`. `pg_ctl` chạy ngoài job, stdin là
  thiết bị rỗng, và chỉ thừa hưởng ba handle chuẩn: giám sát chết thì PostgreSQL vẫn sống và không
  giữ ống nào của giám sát. Giám sát không bao giờ gọi `initdb` hay `-m immediate`, không ghi gì
  dưới `SERVER/data`.

Bên trong `thienlong_zone`:

- Mỗi cảnh một luồng logic duy nhất, bước cố định (`core::Tick`), không khoá trong gameplay. Nhiều
  cảnh nhẹ dùng chung một luồng theo `scene_hosting.tsv`, như `threadindex` của bản gốc.
- Cảnh nói với cảnh khác, với world và với store chỉ qua hộp thư. Người chơi đổi cảnh là một giao
  dịch chuyển quyền sở hữu do world điều phối.
- Luồng mạng, luồng ghi log và luồng ipc tách khỏi luồng cảnh.

## 4. Billing

Thứ bản gốc làm **[đo]**:

- Mã 2008: `LBAskAuthHandler` trả `LOGINR_SUCCESS` cho mọi yêu cầu (đường hỏi máy chủ web bị
  comment). `UserDBManager` gọi stored procedure `WorldWX_User_*` và `WX_Shop_Add` (ghi một lượt
  mua: tiền và năm cặp vật phẩm) trên database `WXSJ`. Vòng lặp `select` ngủ 100 ms mỗi lượt.
- Bản 0859602, đọc từ `web.sql`, `BillingInfo.ini` và `config.yaml` của một bản billing khác (exe bị
  đóng gói): bảng `account` (tên, mật khẩu `char(32)`, câu hỏi bảo mật, `point`); `pay` (mã giao
  dịch, kênh, máy chủ, tài khoản, phí, trạng thái); `billing_point_order` (loại hàng, số lượng, điểm
  trừ, số dư trước và sau); `account_prize` và `billing_prize_order` (quà phát cho nhân vật);
  `billing_cdk_batch`, `billing_cdk_batch_reward`, `billing_cdk_card`, `billing_cdk_redeem_log`
  (mã đổi); `billing_mibao_card`, `_admin`, `_audit`, `_throttle` (thẻ bảo mật). Cấu hình: tự đăng
  ký, danh sách IP được gọi, trần kết nối, trần client mỗi máy, điểm tặng khi đăng ký.
- Phía game: `t_char.yuanbao`, `t_char.zengdian`, `t_charextra.buyyuanbao`, `t_charextra.moneyjz`;
  `ConfigInfo.ini` có `MaxDayCostYuanBao=120000`, `YuanBaoTicketMax=100000`, phí ký gửi; cột loại
  tiền của `ShopTable.txt` (1 vàng, 5 ingot, 6 điểm tặng, 8 giao tử).

Bản mới **[đề xuất]**:

| Việc | Cách làm |
|---|---|
| Số dư điểm nạp | Sổ `point_ledger` chỉ ghi thêm; số dư là tổng của sổ, có bảng `point_balance` làm bản nhớ đệm kiểm lại được. Không có lệnh nào sửa số dư mà không thêm dòng sổ. |
| Đơn nạp | `payment_order` do web hoặc nhà cung cấp tạo. Webhook xác nhận bằng chữ ký HMAC riêng từng nhà cung cấp. Khoá duy nhất `(provider, provider_trade_no)` nên gọi lại không cộng hai lần. |
| Đổi điểm lấy ingot | Hai pha. Billing trừ điểm ở trạng thái chờ và cấp `order_id`; world chuyển cho zone cộng ingot vào nhân vật trong cùng transaction với dòng `ledger_entry` mang `order_id`; zone báo xong thì billing chốt. Quá hạn thì việc đối soát hỏi lại game bằng `order_id`, không tự hoàn điểm khi chưa biết game đã cộng hay chưa. |
| Quà và mã đổi | `redeem_batch`, `redeem_reward`, `redeem_code` dùng một lần, `redeem_log`; `grant` là hàng chờ phát cho nhân vật, phát qua thư có đính kèm. Giới hạn số lần thử mỗi giờ theo tài khoản và IP. |
| Nhật ký tiêu ingot | Zone gửi mỗi lượt tiêu ingot về `spend_log` (không chặn gameplay) để đối soát ngày: ingot phát ra bằng ingot tiêu cộng ingot còn giữ. |
| Hạn mức | Trần tiêu ingot mỗi ngày, trần mỗi đơn, tài khoản bị đóng băng. |
| Quản trị | Cộng tay phải có lý do và tên người làm, ghi sổ kiểm. Tra cứu đơn. Hoàn tiền là một dòng sổ âm, không xoá dòng cũ. |
| Thử | Nhà cung cấp giả (`fake_provider`) gọi webhook; test chạy lại webhook, cắt mạng giữa hai pha, khởi động lại billing giữa chừng. |

Billing không giữ mật khẩu và không nằm trên đường đăng nhập. Chỉ world gọi được billing qua ipc;
webhook chỉ nghe loopback, đi ra ngoài qua reverse proxy có TLS.

Bốn loại tiền trong game do module `ledger` giữ, nằm ở database game: `coin` (vàng), `bound_coin`
(giao tử), `ingot` (từ billing), `bonus_point` (điểm tặng). Phiếu ingot là vật phẩm đúc từ ingot.

## 5. Module mã

Mỗi module là `SRC/<m>/`, một target `game_<m>`, một dòng trong `cmake/GameLayers.cmake`, một tệp
`tests/<m>_tests.cpp`. Cột "Nguồn" ghi nơi port hoặc nơi đọc ngữ nghĩa; mã 2008 chỉ để đọc.

| Tầng | Module | Vai trò | Nguồn |
|---|---|---|---|
| nền | `config` | TOML thành struct đã kiểm miền; khoá lạ là lỗi | mới |
| nền | `process` | chạy tiến trình con, ống stdin và stdout, chờ, buộc dừng; nơi duy nhất include header tiến trình của hệ điều hành | Dev `platform/process` |
| nền | `supervise` | máy trạng thái khởi động, chạy lại, dừng của trình giám sát; không đụng hệ điều hành | Dev `server/supervise.cpp` |
| nền | `service` | khung chung của một tiến trình máy chủ: nạp cấu hình, báo `ready`, chờ lệnh dừng | mới |
| nền | `net` | socket TCP không chặn, `poll`; nơi duy nhất include header mạng của hệ điều hành | Dev `platform`, `net` |
| nền | `secure` | SecureStream, bắt tay, vé; dùng libsodium đã có ở `third_party/libsodium` | Dev `secure` |
| nền | `store` | giao diện kho bền: nạp bản ghi, ghi lô nguyên tử; kèm bản giả trong bộ nhớ cho test | mới, ý từ Dev `persist` |
| nền | `store/pg` | backend PostgreSQL qua libpq | mới |
| nền | `dice` | PRNG của dự án, hạt giống từ cấu hình | Dev `dice` |
| nền | `ids` | id mạnh của nội dung, `Money` | Dev `ids` |
| nền | `metrics` | bộ đếm và thời gian từng hệ | Dev `LOGIC.md` |
| dây | `protocol` | tầng byte và danh mục tin; phần danh mục do công cụ sinh | Dev `protocol` |
| dây | `ipc` | khung nội bộ giữa các tiến trình | Dev `ipc` |
| dây | `link` | phía client: quay số, đăng ký, đăng nhập | Dev `link` |
| luật chung | `names` | luật tên nhân vật, client và máy chủ dùng chung | Dev `names` |
| luật chung | `content` | lược đồ và bộ đọc từng bảng, trên `table::Tsv` | Dev `tables` |
| luật chung | `combat` | công thức sát thương, trúng, chí mạng, phe | Dev `combat`; 2008 `Common/Combat`, `Obj_Character` |
| luật chung | `walk` | lưới đi, kiểm đường, tìm đường | Dev `walk`; 2008 `Scene/Map`, `PathFinder` |
| luật chung | `ops` | tập điều kiện và hiệu ứng đóng của nội dung | Dev ADR-001 |
| luật chung | `text` | id chuỗi, tham số có kiểu | Dev `CHUOI.md` |
| máy chủ | `zone` | cảnh, lưới AOI, handle thực thể, sinh và sinh lại quái, vùng sự kiện | Dev `server` (`world`, `aoi`, `npcs`, `patrol`); 2008 `Scene`, `Obj` |
| máy chủ | `actor` | thuộc tính, trạng thái, hồi phục của người, quái, trân thú | 2008 `Obj/Attributes`, `Obj_Human`, `Obj_Monster` |
| máy chủ | `skill` | kỹ năng, hiệu ứng, hồi chiêu, đạn, bẫy; logic id là enum | 2008 `Skills`, `ActionModule` |
| máy chủ | `ai` | AI của quái và trân thú; luật từ `monster_ai_rules.tsv` | 2008 `AI` |
| máy chủ | `item` | túi, trang bị, ngọc, cường hoá, chế tạo, rơi đồ | 2008 `Item` |
| máy chủ | `ledger` | giao dịch nguyên tử, idempotent, sổ kiểm | Dev `LOGIC.md` mục 8 |
| máy chủ | `quest` | máy trạng thái nhiệm vụ, sổ nhiệm vụ | Dev `NHIEM-VU.md`; 2008 `Mission` |
| máy chủ | `dialogue` | phiên hội thoại giữ ở máy chủ | Dev ADR-002 |
| máy chủ | `handlers` | việc một lần đăng ký theo id, mỗi handler một test | Dev `LOGIC.md` mục 9 |
| máy chủ | `pet` | trân thú: bắt, nuôi, kỹ năng, phối giống | 2008 `Obj_Pet`, `PetManager` |
| máy chủ | `social` | tổ đội, bang, thành, quan hệ, thư, chat | 2008 `World/WorldData`, `Team` |
| máy chủ | `trade` | giao dịch tay đôi, bày bán, cửa hàng người chơi, ký gửi | 2008 `Other` |
| máy chủ | `activity` | lịch hoạt động, phó bản, chiến trường | 2008 `Scene/CopySceneManager`, `SceneTimer` |
| máy chủ | `account` | logic tài khoản và vé | Dev `auth` |
| máy chủ | `billing` | logic billing của mục 4 | mới |
| máy chủ | `gm` | lệnh GM có quyền và sổ kiểm | Dev `GM.md` |
| chương trình | `gated`, `authd`, `billingd`, `worldd`, `zoned`, `stored`, `supervisor` | `main` của bảy exe; chỉ nối các tầng dưới | Dev `edge`, `authd`, `worldd`, `server` |
| chương trình | `admintool`, `bot`, `linttool`, `migrate` | công cụ C++; thư mục công cụ mang hậu tố `tool` như `sealtool`, `shadertool` đang có | Dev `admin`, `bot` |

Bảng trên là đích. Đối chiếu với `SRC/` ngày 2026-10-08:

- Đã có: `config`, `process`, `supervise`, `service`, `net`, `secure`, `protocol`, `content`,
  `linttool`, `metrics` (kèm module con `metrics/serve` là cổng đọc qua loopback; từ 2026-10-09),
  bảy thư mục `main` (`supervisor`, `stored`, `authd`, `billingd`, `worldd`, `zoned`,
  `gated`), và `gate` (bảng kết nối cùng vòng tick của `thienlong_gate`; bảng trên chưa có dòng
  riêng cho nó). `content` hiện là bộ kiểm bảng và tham chiếu chéo cho `thienlong_lint`, chưa có
  lược đồ và bộ đọc từng bảng.
- Chưa có: `store`, `store/pg`, `dice`, `ids`, `ipc`, `link`, `names`, `combat`,
  `walk`, `ops`, `text`, `zone`, `actor`, `ai`, `item`, `ledger`, `dialogue`, `handlers`, `pet`,
  `social`, `trade`, `activity`, `account`, `billing`, `gm`, `admintool`, `bot`, `migrate`.
- Trùng tên phải giải trước khi viết: `SRC/quest` và `SRC/skill` đã tồn tại và là module của
  CLIENT (bảng nhiệm vụ, sổ 20 ô, bảng và sách kỹ năng cho giao diện; tầng `core table`). Module
  `quest` và `skill` của máy chủ trong bảng trên chưa có và không được viết đè vào hai thư mục
  đó: phần luật cả hai bên cùng cần thì tách thành module luật chung, phần mô phỏng của máy chủ
  đặt tên khác; chốt tên khi tới mốc P5 và P7.
- `walk`: client đã có `SRC/nav`, bản port từng bit của `PathLib.dll` 2026 trên tệp `.path`
  (`docs/DUONG-DI-2026.md`), tầng `core nav` nên máy chủ dùng được. `SERVER/scenes/*/walk.nav`
  là lưới ô của bản 0859602. Hai nguồn cho hai tập cảnh khác nhau; chọn nguồn nào cho cảnh nào
  là quyết định mở của mốc P4.

Luật viết mã riêng cho máy chủ, thêm vào luật chung của dự án:

- Lõi (`zone` trở xuống) không include `net`, `store/pg`, không đọc đồng hồ thật; thời gian và byte
  đầu vào do bên gọi đưa. Nhờ vậy test của lõi chạy trên mọi preset mà không cần mạng hay database.
- Mọi byte từ client đi qua kiểm trần trước khi cấp phát; sai thì trả lỗi, đếm, không `check`.
- Tiền và số lượng vật phẩm là số nguyên có kiểu; không số thực.
- Mỗi hệ 2026 là bảng cộng op cộng một module, không phải tiến trình mới.
- Phần port ghi `Nguồn:` và `Khác gốc:` đầu tệp, như `docs/NGUON-TLBB.md` đang làm.

## 6. Cấu hình và dữ liệu

| Loại | Định dạng | Ở đâu |
|---|---|---|
| Cấu hình tiến trình | TOML, 11 tệp | `SERVER/config/` |
| Luật chơi dạng khoá | TOML, 13 tệp | `SERVER/config/rules/` |
| Bảng dùng chung với client | TSV UTF-8 | `SERVER/tables/shared/`, cùng nội dung với `CLIENT/data/Table` |
| Bảng chỉ máy chủ giữ | TSV UTF-8 | `SERVER/tables/server/` |
| Bảng thay theo loại máy chủ | TSV UTF-8 | `SERVER/tables/variants/<khoá>/`, chọn bằng `table_variant` của `cluster.toml` |
| Dữ liệu cảnh | TOML, TSV và lưới nhị phân đã nấu | `SERVER/scenes/<scene>/` |
| Migration của database | SQL đánh số | `SERVER/sql/<schema>/` |
| Dữ liệu người chơi | PostgreSQL | `SERVER/data/pg`, git bỏ qua |
| Nhị phân PostgreSQL | gói Windows x64 của EDB, tải bằng `setup_db.py` | `SERVER/pgsql`, git bỏ qua |
| Tin mạng | nhị phân tự định nghĩa | `docs/` và `SRC/protocol` |

Lúc chạy không có INI, XML, JSON, Lua. Bảng TSV chỉ nấu sang nhị phân khi đo thấy nạp chậm.

Bố cục tệp cấu hình **[chốt]**, theo mẫu chủ dự án đưa:

```toml
#==================================================
# TIÊU ĐỀ TỆP VIẾT IN HOA
#==================================================
# Vài dòng nói tệp này của ai, để làm gì.

#==================================================
# Tên nhóm cài đặt
#==================================================
[bảng]
khoá_ngắn = 1           # chú thích tiếng Việt ngang hàng
khoá_dài  = "giá trị"   # dấu = và dấu # thẳng cột trong nhóm
```

Mỗi nhóm (các khoá gốc, hoặc một bảng) mở đầu bằng một khung tiêu đề và cách nhóm trước một dòng
trống; các cài đặt trong nhóm nằm sát nhau; mỗi cài đặt có chú thích tiếng Việt ngang hàng, dài
quá thì đặt ngay dòng trên; dấu `=` và dấu `#` thẳng cột trong mọi nhóm cùng tên bảng của một
tệp; dòng không quá 110 cột. `python TOOLS/server/lint_config.py` kiểm các luật này: cài đặt
thiếu chú thích hay lệch cột là lỗi. Không ai căn tay: thêm `--fix` thì công cụ căn lại, chỉ đổi
dấu cách. Công cụ sinh TOML ở P1 ghi tệp bằng `config_style.render` nên ra đúng bố cục đó.

Lược đồ cài đặt, cho công cụ GUI sau này **[đề xuất, chờ duyệt]**: TOML vẫn là định dạng lưu trên
đĩa (có kiểu, có chú thích, so sánh được trong git, sửa tay được khi cần). Thứ làm công cụ GUI tốt
hơn không phải một định dạng khác mà là một lược đồ: mỗi cài đặt khai một lần gồm đường khoá, kiểu,
giá trị mặc định, miền hợp lệ, đơn vị, nhãn và lời giải thích tiếng Việt, khối chứa nó, cờ "số tạm"
và cờ "đổi phải khởi động lại". Từ lược đồ đó sinh ra bốn thứ: struct C++ và bộ kiểm miền của module
`config`, tệp TOML có đủ khung tiêu đề và chú thích, form của công cụ GUI, và bảng ở mục 3 của phụ
lục. Khi đó GUI ghi tệp trực tiếp mà không làm mất chú thích, và GUI với máy chủ kiểm cùng một luật.
Mười một tệp hiện có đã theo một hình dạng đều, có bộ kiểm giữ, nên lược đồ đầu tiên trích ra từ
chính chúng được bằng máy. Đề xuất làm ở P2, cùng lúc viết module `config`.

Danh sách đủ từng tệp, khoá chính của từng tệp TOML và tệp gốc tương ứng nằm ở phụ lục. Tóm tắt:

- Tiến trình: `cluster.toml`, `gate.toml`, `auth.toml`, `billing.toml`, `world.toml`, `zone.toml`,
  `store.toml`, `log.toml`, `admin.toml`, `supervisor.toml`, `secrets.local.toml`.
- Luật chơi: `global.toml`, `combat.toml`, `character.toml`, `new_character.toml`, `monster.toml`,
  `pet.toml`, `hidden_weapon.toml`, `pvp.toml`, `guild.toml`, `social.toml`, `economy.toml`,
  `fatigue.toml`, `instances.toml`.
- Bảng chỉ máy chủ giữ: 92 tệp của `Server/Config` thành khoảng 60 bảng (35 tệp `boxdroplist*`
  gộp một bảng).
- Bảng dùng chung: 91 tệp của `Public/Config`, cộng 574 bảng chỉ có ở client 2026, trong đó 109
  bảng chỉ client dùng.

Hình dạng thật: mười một tệp đã nằm ở `SERVER/config/`; tệp gốc là `cluster.toml`.

Một nguồn sự thật: máy chủ băm toàn bộ `tables/shared` thành một dấu nội dung và gửi lúc đăng nhập;
client lệch dấu thì bị ngắt với lý do rõ, không chơi tiếp với bảng khác bản.

## 7. Database PostgreSQL

PostgreSQL 18.6 nằm trong `SERVER/pgsql` (gói nhị phân Windows x64 của EDB, 144 MB sau khi bỏ
pgAdmin), dữ liệu ở `SERVER/data/pg`, không cài dịch vụ Windows và không cần quyền quản trị
**[đo]**. Máy chủ nối bằng `libpq` 18.4 của vcpkg, bản tĩnh không OpenSSL; xác thực
SCRAM-SHA-256 chạy được **[đo]**. Cụm chỉ nghe 127.0.0.1. Một cụm, ba database, mỗi tiến trình
một role chỉ có quyền trên database của mình; role của store không nối được database của auth
**[đo]**:

| Database | Ai nối | Bảng | Từ bảng gốc |
|---|---|---|---|
| `thienlong_auth` | auth | `account`, `security_card`, `login_throttle`, `ban`, `operator`, `audit_event`, `schema_version` | `account` (bỏ cột `point`), `billing_mibao_card`, `billing_mibao_throttle`, `billing_mibao_admin`, `billing_mibao_audit` |
| `thienlong_billing` | billing | `point_ledger`, `point_balance`, `payment_order`, `exchange_order`, `grant`, `grant_order`, `redeem_batch`, `redeem_reward`, `redeem_code`, `redeem_log`, `spend_log`, `schema_version` | `account.point`, `pay`, `billing_point_order`, `account_prize`, `billing_prize_order`, `billing_cdk_batch`, `billing_cdk_batch_reward`, `billing_cdk_card`, `billing_cdk_redeem_log`, `billing_schema_version` |
| `thienlong_game_<world>` | store | xem dưới | `tlbbdb` |

Bảng của database game:

| Bảng mới | Từ bảng gốc | Ghi chú |
|---|---|---|
| `character` | `t_char`, `t_charextra` | chỉ cột cần tra: id, tài khoản, tên, cấp, môn phái, cảnh, bang, lần thoát cuối, đã xoá |
| `character_record` | 12 cột text của `t_char`; `t_ability`, `t_skill`, `t_xinfa`, `t_impact`, `t_mission`, `t_relation` | khoá `(character_id, kind)`; thân là bản ghi nhị phân có phiên bản do `store` mã hoá |
| `item` | `t_iteminfo` | mỗi món một dòng: serial, chủ, nơi chứa, ô, mẫu, số lượng, khoá, thân |
| `item_serial_block` | `t_itemkey`, `ItemSerial.ini` | cấp serial theo khối cho từng zone |
| `pet`, `pet_breeding` | `t_pet`, `t_petcreate` | |
| `mail` | `t_mail` | có đính kèm; đính kèm là dòng `item` đổi chủ |
| `guild`, `guild_member` | `t_guild`, `t_guild_new`, `t_guild_user` | |
| `guild_alliance`, `guild_alliance_member`, `guild_alliance_application` | `t_league`, `t_league_usr`, `t_league_apply` | |
| `city`, `city_building` | `t_city`, `t_city_new`, `t_city_info`, `t_city_building` | |
| `player_shop`, `player_shop_stall`, `player_shop_stall_item`, `player_shop_stall_pet`, `player_shop_buy_order` | `t_pshop`, `t_pshop_new`, `t_pshop_stall`, `t_pshop_stall_itm`, `t_pshop_stall_pet`, `t_pshop_stall_buy` | |
| `consignment_listing`, `consignment_item` | `t_cshop`, `t_cshopitem` | |
| `friend_finder_ad` | `t_findfriendad` | |
| `global_value` | `t_global`, `t_general_set`, `t_var` | |
| `gm_grant` | `GMList.ini` | |
| `ledger_entry` | mới | sổ kiểm chỉ ghi thêm của mọi lượt chuyển tiền và vật phẩm giữa hai chủ |
| `ranking_snapshot` | mới | |
| `schema_version` | `t_schema_version` | |

Bảng gốc không mang sang: `t_crc32` (ảnh chụp cả nhân vật để khôi phục; thay bằng tổng kiểm trong
từng bản ghi) và `t_xfallexp` (chưa đọc mã dùng nó).

Luật ghi:

- Chuyển giá trị giữa hai chủ (giao dịch, thư có đính kèm, ký gửi, bày bán, kho bang, ingot từ
  billing) là một transaction gồm các dòng đổi và một dòng `ledger_entry`. Kết quả chỉ có hiệu lực
  trong game sau khi transaction xong.
- Tiến độ thường (vị trí, kinh nghiệm, máu) đi theo delta định kỳ, và ép ghi khi rời cảnh, thoát
  game, lên cấp.
- Mọi yêu cầu đổi trạng thái từ client mang số `request` tăng dần; gặp lại số đã áp thì trả kết quả
  cũ, không áp lần hai.
- Tiền là `bigint`, có ràng buộc `CHECK (>= 0)`. Không cột số thực cho tiền hay số lượng.
- Bản ghi nhị phân viết từng trường little-endian, có số phiên bản; đọc bản cũ thì nâng trong mã,
  không sửa hàng loạt trong DB.
- Chỉ `store` nối database game. libpq gọi qua một lớp RAII mỏng, không dùng `libpqxx` (thư viện đó
  báo lỗi bằng exception).

Sao lưu: `pg_basebackup` cộng lưu WAL để khôi phục tới một thời điểm; `pg_dump` mỗi ngày cho
`auth` và `billing`. Diễn tập khôi phục là tiêu chí của mốc P12.

## 8. Protocol và bảo mật

Port bản 5 của Dev **[đề xuất]**, không dùng lại 435 gói của bản gốc:

- TCP, khung 8 byte, trần thân 64 KiB, trần 4 KiB cho tin từ client. Mọi số little-endian, ghi từng
  trường. Còn byte thừa hay thiếu byte là lỗi giải mã.
- Client chỉ gửi ý định. Không tin nào mang id script, tên hàm, số tiền hay id phần thưởng.
- Chữ nội dung đi bằng id chuỗi kèm tham số có kiểu; máy chủ không gửi văn bản nội dung.
- Mã tin chia nhóm theo tính năng ở byte cao. Bản đầy đủ sẽ có vài trăm tin, nên danh mục tin là
  một bảng mô tả, công cụ sinh mã encode và decode, byte mẫu và test fuzz từ bảng đó.
- SecureStream nằm dưới khung. Mật khẩu chỉ đi qua cổng xác thực; cổng game nhận vé.
- Mật mã lấy từ libsodium đã có trong kho. Dev tự viết PBKDF2 và SHA-256; khi port `secure` phải so
  từng phép với libsodium rồi chọn một, ghi `Khác gốc:`.
- Gate: trần kết nối mỗi IP, hạn bắt tay, trần tin mỗi giây, danh sách chặn. Đây là phần Dev ghi
  "chưa có".

## 9. Công cụ

Đã có trong kho, dùng lại: `TOOLS/content/dbc.py` (đọc DBC), `collect_map.py`, `collect_ui.py`,
`export_look.py`, `table::Tsv`, `check.py` của bộ cpp23.

Python mới ở `TOOLS/server/`:

| Công cụ | Việc |
|---|---|
| `table_census.py` (đã có) | kê số cột, số bản ghi, dãy kiểu và SHA-256 của 745 bảng DBC của client (718 ở gốc `Config`, 24 `AbilityLevelUp`, 3 `ActionSet`); chạy lại khi client đổi bản |
| `table_names.tsv` (đã có) | bảng tên gốc sang tên mới, lấy từ phụ lục; một nguồn cho mọi công cụ xuất |
| `export_tables.py` (đã có) | DBC của client 2026 thành TSV có tên cột tiếng Anh và dòng lược đồ |
| `import_legacy.py` (đã có) | ini và txt của bản 0859602 thành TSV theo phụ lục |
| `import_rules.py`, `legacy_rules.tsv` (đã có) | khoá luật chơi của các tệp ini thành TOML ở `SERVER/config/rules`; bảng soạn tay ghi số phận, tên mới, phép đổi và căn cứ của từng khoá |
| `align_columns.py`, `column_terms.tsv` (đã có) | căn cột bản 2026 với bản 0859602 bằng dữ liệu; bảng thuật ngữ soạn tay cho tên cột |
| `scene_refs.py`, `scene_attach.tsv` (đã có) | lời gọi `LuaFnSetSceneLoad_*` của script thành `scene_load_refs.tsv`; tệp cảnh không có `.scn` gắn vào cảnh nào |
| `build_data.py` (đã có) | một lệnh sinh lại mọi bảng, cảnh và tệp luật; `--digest` in SHA-256 của cây |
| `lint_py.py` (đã có) | cổng hình dạng mã Python của `TOOLS/server`: hàm tối đa 50 dòng, lồng tối đa 3 mức |
| `diff_tables.py` (đã có) | đo độ phủ: id nào có ở bảng client mà thiếu ở bảng máy chủ (kỹ năng thiếu hiệu ứng, quái thiếu bảng rơi) |
| `export_scene.py` (đã có) | tệp ini của cảnh thành `spawns.tsv`, `areas.tsv`, `patrols.tsv` và các bảng còn lại |
| `bake_nav.py` (chưa có) | nấu lưới đi từ `.nav` cũ hoặc từ `.region`, `.wcollision`, `.heightmap` của client; so hai nguồn ở cảnh có cả hai |
| `lua_extract.py` (chưa có) | đọc tĩnh Lua 4.0 theo mẫu cố định, ghi bảng hội thoại, nhiệm vụ, sự kiện; báo tỉ lệ script khớp mẫu và danh sách phải viết handler |
| `ai_convert.py` (chưa có) | 269 tệp `.ai` thành `monster_ai_rules.tsv` |
| `gen_protocol.py` (đã có) | bảng mô tả tin thành mã C++, byte mẫu, tài liệu |
| `fake_provider.py` (chưa có) | giả nhà cung cấp thanh toán để thử webhook |
| `setup_db.py` (đã có) | tải, kiểm SHA-256 và giải nén PostgreSQL vào `SERVER/pgsql`; initdb; sinh mật khẩu; tạo role và database; chạy, dừng, xem trạng thái cụm |
| `lint_config.py`, `config_style.py` (đã có) | kiểm cú pháp, hình thức và chú thích của mọi tệp TOML trong `SERVER/config` |

Có trong `TOOLS/server` mà bảng trên chưa kể (đo 2026-10-08): `table_refs.py` và ba tệp luật ở
`refs/` (55 dòng tham chiếu chéo), `lint_names.py`, `column_names.py`, `fuzz_protocol.py` và
`fuzz_secure.py` (libFuzzer cho bộ giải mã tin, bắt tay và bản ghi), `gate_load.cpp` (exe
`thienlong_gate_load`, đo tải gate; chỉ dựng trên Windows vì gọi thẳng Winsock và `psapi`).

Exe C++: `thienlong_lint` (kiểm TOML, bảng và tham chiếu chéo bằng chính bộ đọc của máy chủ; chạy
trong ctest và lúc world khởi động), `thienlong_migrate` (áp migration theo số, từ chối database
mới hơn mã), `thienlong_bot` (thử tải), `thienlong_admin` (quản trị và GM). Ngày 2026-10-08 mới có
`thienlong_lint` (chạy trong ctest dưới tên `server_data_lint`; world chưa gọi nó); ba exe còn lại
chưa có.

Đã có trên máy sau P0: PostgreSQL 18.6 trong `SERVER/pgsql`, gồm `psql`, `pg_dump`,
`pg_basebackup`; hai gói `tomlplusplus` và `libpq` đã dựng cho `x64-windows-static-md` và nằm
trong bộ đệm nhị phân của vcpkg. Còn thiếu: một distro WSL hoặc một máy Linux để chạy
`clang-tsan` và để dựng, chạy bản POSIX của máy chủ. Máy chủ thử chạy trên Windows, nhưng đích
của máy chủ là cả Linux lẫn Windows (mục 1), nên thiếu Linux là thiếu một nửa phần kiểm.

## 10. Các bước triển khai

Mỗi mốc chỉ bắt đầu khi mốc trước đạt tiêu chí. Mỗi tính năng: test đỏ trước, build 0 cảnh báo,
`check.py` xanh, chạy thật rồi mới ghi `docs/TIEN-DO.md`. Lệnh kiểm chung của mọi mốc:

```
cmake --workflow --preset clang-asan
cmake --workflow --preset gcc-debug
cmd /c "call %USERPROFILE%\.claude\skills\cpp-build\dev.bat && cmake --workflow --preset msvc-release"
```

Mã đa luồng từ P4: chạy thêm `cmake --preset clang-tsan`, `cmake --build --preset clang-tsan`,
`ctest --preset clang-tsan` trên Linux khi có máy (preset có, nhưng không có workflow preset tên
đó); chưa
có thì báo cáo ghi rõ "chưa kiểm TSan".

| Mốc | Việc | Xong khi |
|---|---|---|
| P0 Chuẩn bị | Chốt các điểm còn mở. Thêm `tomlplusplus`, `libpq`, PostgreSQL. Build thử hai tệp: đọc một TOML không exception, nối libpq và chạy truy vấn. Dựng cây `SERVER/`. Ghi các quyết định vào mục 0 của `AGENTS.md`. | Hai tệp thử build và chạy trên MSVC và Clang; quyết định đã vào `AGENTS.md`. **Đạt ngày 2026-10-06** (kết quả ở mục 13). |
| P1 Dữ liệu | Viết sáu công cụ đầu của mục 9. Giải các tên còn dấu `?` trong phụ lục bằng cách đọc bảng và Lua giao diện dùng nó. Xuất `SERVER/tables` và `SERVER/scenes` cho bản 0859602. Viết `thienlong_lint` cho các bảng đã có lược đồ. | Một lệnh sinh lại toàn bộ cây dữ liệu; lint 0 lỗi; `diff_tables.py` in số id thiếu của từng bảng; lưới đi của 10 cảnh đầu khớp `.nav` gốc từng ô. **Đạt ngày 2026-10-07**; nợ mang sang ghi dưới bảng. |
| P2 Nền | Đọc trọn `SERVER.md`, `PROTOCOL.md`, `BAO-MAT.md`, `KHO-BEN.md`, `LOGIC.md`, `NHIEM-VU.md` của Dev. Thêm `tomlplusplus` và `libpq` vào `vcpkg.json`, chỉ cho nền tảng dựng máy chủ. `config`, `net`, `secure`, `protocol` và `gen_protocol.py`, `ipc`, `metrics`, `supervisor`. Test byte mẫu và fuzz cho mọi bộ giải mã. | Bảy exe rỗng khởi động theo thứ tự, in `ready`, dừng êm; `cmake --install` chép chúng vào `SERVER/bin`; fuzz một triệu vòng không lỗi dưới ASan và UBSan; cấu hình sai khoá bị từ chối kèm số dòng. **Đợt 1 và đợt 2 đạt (2026-10-07, 2026-10-08). Đợt 3 dở: có `secure` và mặt trước `gate`, chưa có `ipc`, `metrics`** (ghi dưới bảng). |
| P3 Tài khoản và nhân vật | Schema `auth` và `game`, `thienlong_migrate`, `store` (backend PostgreSQL và bản giả trong bộ nhớ cho test), `stored`, `authd`, `gated`, phần tạo và chọn nhân vật của `worldd`, `link` phía client. | Client thật đăng ký, đăng nhập, tạo nhân vật, thoát, vào lại thấy nhân vật; rút nguồn `stored` giữa lúc ghi rồi mở lại không mất bản ghi đã xác nhận; bot đăng nhập 1.000 tài khoản. |
| P4 Cảnh | `walk`, `zone` (nạp cảnh, AOI, di chuyển do máy chủ quyết, sinh NPC, đổi cảnh), nhiều cảnh trên nhiều luồng, client hiện người chơi khác. | Hai client thấy nhau đi ở cùng cảnh và đổi cảnh; không đi xuyên vật cản; 400 bot một cảnh, đo tick trung bình và p99 so với ngân sách 50 ms; TSan sạch. |
| P5 Chiến đấu | `actor`, `combat`, `skill`, `ai`: thuộc tính, kỹ năng và hiệu ứng theo logic id, hồi chiêu, quái đánh lại, chết và hồi sinh, kinh nghiệm, rơi đồ. Port logic id theo thứ tự số kỹ năng dùng nó. | Chín môn phái gốc đánh quái ở ba cảnh; mỗi logic id có test với số liệu lấy từ công thức gốc; bảng `diff_tables.py` cho biết bao nhiêu phần trăm kỹ năng của bảng đã chạy được. |
| P6 Vật phẩm và kinh tế | `item`, `ledger`, cửa hàng NPC, giao dịch tay đôi, thư, bày bán, ký gửi. | Test bảo toàn: tổng tiền và tổng vật phẩm trước và sau mười nghìn giao dịch ngẫu nhiên bằng nhau, kể cả khi cắt kết nối và khởi động lại zone giữa chừng. |
| P7 Nhiệm vụ | `lua_extract.py`, `ops`, `text`, `quest`, `dialogue`, `handlers`, lịch hoạt động. | Tỉ lệ script khớp mẫu có số; chuỗi nhiệm vụ tân thủ chạy từ đầu tới cuối trên client thật; mỗi handler một test. |
| P8 Xã hội | `social`: tổ đội, kênh chat và lọc chữ, bạn bè, bang, thành, xếp hạng. | Hai trăm bot lập đội, lập bang, chat; lọc chữ chặn đúng bộ ca thử; không tin nào của client làm world dừng. |
| P9 Billing | Schema `billing`, `billing`, `billingd`, webhook, `fake_provider.py`, cửa hàng ingot, mã đổi. | Đủ các ca thử của mục 4; đối soát ngày khớp sau một nghìn đơn có chèn lỗi. |
| P10 Trân thú và nghề | `pet`, kỹ năng sống, thú cưỡi, ám khí. | Bắt, nuôi, phối giống, học kỹ năng chạy theo bảng xác suất gốc; test phân phối với hạt giống cố định. |
| P11 Hệ của 2026 | Mỗi hệ một lát: bảng, op, module, tin mạng, giao diện. Thứ tự theo phụ thuộc và theo dữ liệu có được: tâm pháp và tu luyện, điêu văn, long văn, võ hồn, chân nguyên, tinh trận, thần khí, rồi tới hoạt động và cửa hàng. | Mỗi hệ có tài liệu ghi phần nào lấy từ bảng client, phần nào là số tự đặt; chủ dự án duyệt số tự đặt. |
| P12 Vận hành | Chạy bền 72 giờ trên máy chủ thử này, diễn tập sao lưu và khôi phục, số đo và cảnh báo, gói triển khai; chạy TSan trên Linux khi có máy. | Khôi phục tới một thời điểm cho trước thành công; chạy bền không rò bộ nhớ; có sổ tay vận hành. |

P9 không phụ thuộc P7 và P8, làm song song được sau P6. Mốc P11 không có điểm kết thúc cố định.

P1 làm theo đợt, mỗi đợt một đề bài ở `docs/giao-viec/` do Grok Build viết mã và Claude kiểm lại.
Đợt 1 (2026-10-07) đã có `table_names.tsv`, `table_census.py`, `export_tables.py`,
`import_legacy.py`, `export_scene.py`, `build_data.py`: 635 bảng client, 69 bảng máy chủ, 244 cảnh,
không ô nào lệch nguồn.

Đợt 2 (2026-10-07) đạt tiêu chí "một lệnh sinh lại toàn bộ cây dữ liệu": `build_data.py` thoát 0,
hai lần chạy cùng một mã SHA-256. Thêm `import_rules.py` với bảng soạn tay `legacy_rules.tsv` (578
khoá; sáu trên mười ba tệp luật đã sinh), `align_columns.py` (căn cột 76 cặp bảng đổi bố cục bằng
dữ liệu), `scene_refs.py` (250 lời gọi nạp tệp cảnh của script), `lint_py.py` (cổng hình dạng mã
Python). 45 tệp cảnh không có `.scn` đã gắn xong: 10 tệp do script nạp, 35 tệp chỉ client dùng.

Đợt 3 (2026-10-07) đạt ba tiêu chí còn lại, nên **P1 đạt ngày 2026-10-07**. `thienlong_lint` (module
`content`, exe ở `SRC/linttool`) đọc 4.015 tệp TSV, 22.019.096 ô bằng `game::table::parse_tsv`, 0
lỗi, 2,2 giây. `diff_tables.py` in hiệu id của 106 cặp bảng và độ phủ của 55 dòng tham chiếu ở
`TOOLS/server/refs/`; phần đếm tham chiếu có ba bản cài đặt độc lập (Python, C++, script kiểm của
Claude) ra cùng kết quả. Lưới đi của 244 cảnh trùng băm với `.nav` gốc. Tên cột: bảng máy chủ
1.889 trên 2.172 cột đã có tên; bảng client có bản đối chiếu còn 141 cột có nhãn chưa đặt tên.

Nợ của P1 mang sang, không chặn P2: hai bảng tên cột dịch lệch nhau ở 48 nhãn (đang sửa ở P2 đợt
1); bảy tệp luật còn lại (trân thú, ám khí, PvP, bang, xã hội, kinh tế, chống nghiện); bảng tham
chiếu mới có 21 quan hệ, cần thêm vật phẩm, cửa hàng, hiệu ứng trước P5; 91 tên bảng còn `?` và
14.516 cột không nhãn của bảng chỉ có ở bản 2026 (việc của P11); lưới đi của cảnh chỉ có ở client
2026.

P2 chia ba đợt vì dự án tham chiếu Dev không có sẵn mọi thứ kế hoạch tưởng (khảo sát 2026-10-07:
Dev chỉ có bốn tiến trình, cấu hình `key = value` viết tay, không có `metrics`, không có công cụ
sinh mã giao thức, không PostgreSQL). Đợt 1 (`docs/giao-viec/P2-DOT-1/DE-BAI.md`): `config` đọc
TOML thành struct, `process` và `supervise` (port phần chạy tiến trình con của Dev), `service` và
bảy exe rỗng, luật cài vào `SERVER/bin`, `thienlong_lint` kiểm TOML. Đợt 2: `net`, `protocol`,
`gen_protocol.py`, fuzz. Đợt 3: `secure`, `ipc`, `metrics`. `libpq` chỉ thêm khi làm `store` ở P3.

Đợt 1 đạt ngày 2026-10-07. Grok Build làm phần lớn rồi hết hạn mức giữa chừng (ba vai phụ dừng vì
HTTP 402, không có vòng review); Claude làm nốt và kiểm lại toàn bộ. Kết quả: bảy exe khởi động
theo thứ tự, in `ready`, dừng ngược thứ tự; với PostgreSQL thật là 15 dòng, thoát 0, 0,5 giây tới
`ready` (1,5 giây ở lần PostgreSQL phải tự phục hồi). Tám test (`config_tests`, `process_tests`, `supervise_tests`, `service_tests`,
`content_tests`, `layers`, `server_boot`, `server_data_lint`) xanh ở `gcc-debug`, `clang-asan`,
`msvc-release`; `check.py` 86 tệp 0 lỗi. `thienlong_lint` đọc bảng theo từng bản ghi thay vì dựng
cả bảng: 4.276 tệp (4.015 TSV, 261 TOML), 0 lỗi, 1,4 đến 1,9 giây, đỉnh bộ nhớ 41 MiB (trước
146,4 MiB, trần 120 MiB). Mọi số nguyên của cấu hình bị chặn ở int32. Giao kèo tiến trình ghi ở
mục 3.1; script kiểm đầu cuối ở `docs/giao-viec/P2-DOT-1/kiem-claude/`. Bản POSIX của `process`
mới qua kiểm cú pháp bằng trình dịch NDK, chưa chạy lần nào.

Đợt 2 đạt ngày 2026-10-08 (`docs/giao-viec/P2-DOT-2/`). Đội Grok viết `protocol` (tầng byte, kênh,
19 tin của ba nhóm phiên, nhân vật, xác thực sinh từ bảng), `net` và hai tầng fuzz trong một
worktree riêng, có vòng review và đối chất chéo. Claude kiểm lại trên cây đã dời lên `main`: ba
preset 0 cảnh báo (`gcc-debug` 46/46, `clang-asan` 52/52, `msvc-release` 52/52), libFuzzer năm đích
mỗi đích một triệu vòng dưới ASan và UBSan không lỗi, và bộ dò có răng (bỏ một phép kiểm biên thì
bốn đích giải mã sập trong 0,2 giây). Tiêu chí fuzz của P2 đạt với đợt này; phần còn lại của P2 là
đợt 3. Lúc đó bảy exe chưa mở cổng (gate mở cổng ở đợt 3, đoạn dưới). Bản POSIX của `net` mới
qua kiểm cú pháp. Chi tiết và phần còn mở ở
`docs/TIEN-DO.md`.

Đợt 3, phần đầu (2026-10-08, nhánh `gate-front`, gộp vào `main` ở `21fe0ba`; làm theo một prompt
trực tiếp, không có thư mục `docs/giao-viec`). Có `secure` (bắt tay X25519 tạm cộng chữ ký
Ed25519 ghim sẵn, bản ghi ChaCha20-Poly1305 IETF có bộ đếm, mọi phép là libsodium 1.0.22 ở
`third_party/libsodium`; thiết kế ở `docs/SERVER-BAO-MAT.md`) và mặt trước `gate` (một luồng, tick
60 Hz, bảng kết nối cấp một lần, trần mỗi IP, hạn bắt tay, hạn im lặng, thùng token, lọc CIDR;
sau bắt tay chỉ nhận `Hello`, `Ping`, `Logout`). `thienlong_gate --gen-key <tệp>` sinh khoá danh
tính. Hai cổng `listen.game` và `listen.auth` cùng mở và hiện xử lý y như nhau.

Claude đo lại ngày 2026-10-08 trên `main` ở `501743a`, trong hai cây dựng riêng chỉ gồm phần máy
chủ (cây dùng chung đang có phiên khác dựng): Clang 23 ASan và UBSan 263 bước 0 cảnh báo, MSVC
bản phát hành 267 bước 0 cảnh báo; mười ba test (`content`, `config`, `process`, `supervise`,
bốn test `protocol`, `net`, `wire_loop`, `secure` 26 ca, `gate` 13 ca, `gate_loop` 1 ca) xanh ở
cả hai; `check.py` trên 10 tệp của `gate` và `secure` 0 lỗi; bản cài `SERVER/bin` chạy trọn cụm
trên loopback in đủ 13 dòng, thoát 0. `service_tests` và `server_boot` không chạy ở hai cây riêng
(chúng nghe `0.0.0.0:7000`, mỗi đường dẫn exe mới là một rule tường lửa mới); hai test đó xanh ở
`gcc-debug` trong log của phiên khác lúc 21:57. Sau đó dựng nốt mọi target test của cả dự án ở hai
cây ấy: 0 cảnh báo, 75 test qua ở mỗi cây (mục "Khảo sát theo mã" của `docs/TIEN-DO.md`). Đo bằng
`Get-NetFirewallApplicationFilter` sau các lượt chạy: test và exe chỉ nghe `127.0.0.1` không làm
Windows thêm rule tường lửa nào. Đo tải bằng `thienlong_gate_load` bản MSVC, loopback:

| Kịch bản | Bắt tay | Tick p99 | Tick trễ | Bộ nhớ gate |
|---|---|---|---|---|
| 2.000 khách tốt, 400 thù địch, 10 giây | 2.000 trong 0,48 giây (4.183 mỗi giây) | 12,4 ms | 0 | 51,6 MiB lúc đầu, thêm 649 byte mỗi khách |
| 10.000 khách tốt, 2.000 thù địch, 20 giây (mặc định của công cụ) | chỉ 3.908 trong 20 giây | 121 ms | 1.088 | 219,1 MiB lúc đầu |

Hạn một tick là 16,7 ms: gate giữ được trần đang cấu hình (`max_connections = 2000`) nhưng không
giữ được kịch bản mặc định của chính công cụ đo; pha đọc (`pump_us`) lên tới 112 ms. Mỗi ô kết nối
chiếm khoảng 18 KiB cấp sẵn.

Còn thiếu để P2 đạt, theo mã ngày 2026-10-08:

- `ipc` chưa có; năm tiến trình phía sau chưa mở cổng `[[process]]`; gate chưa chuyển tiếp, chưa
  phân biệt cổng xác thực với cổng game, chưa có vé.
- Bộ đếm lý do ngắt, ĐÃ SỬA ngày 2026-10-09 (gói P2-2): trước đó nó chỉ nằm trong bộ nhớ
  (`Table::drops`), ba lý do từ chối lúc nhận (đầy, đầy theo địa chỉ, địa chỉ bị chặn) không được
  đếm, và `thienlong_gate_load` đếm qua dòng log bị giới hạn năm dòng mỗi giây nên đếm thiếu (100
  khách xả tin in 0, 500 khách in 5). Nay mọi lý do ngắt là một bộ đếm `gate.drop.*` của module
  `metrics`, đọc qua cổng `metrics` (mục 3.1): `gate_loop_tests` cho 100 rồi thêm 500 khách xả
  tin, bộ đếm `gate.drop.rate` ra đúng 100 rồi 600. `thienlong_gate_load` vẫn đọc log; chuyển nó
  sang cổng metrics là gói P2-5.
- Hạn tick trôi, ĐÃ SỬA ngày 2026-10-09 (ca xả tin trên bắt được): vòng nào của gate cũng cộng
  một nhịp 16,7 ms vào hạn tick, kể cả vòng thức sớm vì có I/O. Một đợt I/O dồn dập đẩy hạn ra
  xa (đo: 2.790 vòng trong chưa đầy hai giây, hạn lệch khoảng 44 giây), nên khi I/O ngừng gate
  ngủ trọn khoảng đó: không chạy hạn bắt tay, hạn im lặng, không thấy yêu cầu dừng. Nay hạn chỉ
  dời khi vòng bắt đầu ở hoặc sau hạn. Số nền của mục này đo TRƯỚC khi sửa lỗi đó.
- `Welcome.heartbeat` ghi cứng 1 giây (`SRC/gate/table.cpp`), không lấy từ cấu hình.
- Không có ngân sách cho việc bắt tay trong một tick: mỗi lời chào 42 byte buộc gate sinh khoá,
  ký và suy khoá. Nghi đây là lý do tick vỡ ở kịch bản 10.000; chưa đo tách từng pha.
- Nợ (a), ĐÃ TRẢ ngày 2026-10-09 (gói P2-1): `service_tests`, `server_boot` từng chạy cụm với
  `SERVER/config` thật (gate nghe mọi địa chỉ ở hai cổng cố định), `gate_loop_tests` và công cụ đo
  tải từng dùng bốn cổng cố định khác. Nay cả bốn, cùng mười phần của `boot_check.py`, chạy trên
  bản chép cấu hình trong cây dựng: gate khai `127.0.0.1:0`, mọi `[[process]]` khai cổng 0, khoá
  danh tính tạm sinh tại đó (`tests/support/loopback_config.hpp`). Giao kèo mục 3.1 mở rộng: gate
  báo cổng thật ở dòng `ready game=<cổng> auth=<cổng>`, giám sát báo lại ở dòng `ready` của cụm,
  và cấu hình nhận cổng 0 chỉ cho bên nghe trên `127.0.0.1`. Không còn bước xin cổng trước rồi
  trả lại, nên không còn khe tranh cổng. `metrics=` ở dòng `ready` đã có từ P2-2. Còn chờ gói
  khác: `ipc=` và việc giám sát điền cổng đã học vào khối khởi động của bên nối (P2-10).
- Bốn điểm mở của đợt 2 còn nguyên: M1 (POSIX, RST sau FIN), N6 (bộ giải mã sinh ra không đối
  chiếu `body.size()` với `frame.body_bytes`), N10 (`fuzz_protocol.py` chưa có `--source`,
  `--out`), N12 (`optional:optional` được nhận).
- Bản POSIX của `process`, `net` vẫn chưa dựng và chưa chạy trên Linux; `gate_load.cpp` chỉ có bản
  Windows và bỏ qua đối số lạ (`--help` chạy luôn kịch bản mặc định).

Fuzz chạy lại ngày 2026-10-08 trên cây sau khi gộp: năm đích của `fuzz_protocol.py` và hai đích
của `fuzz_secure.py`, mỗi đích một triệu vòng dưới ASan và UBSan, đều thoát 0; `fuzz_secure.py
--teeth` bắt được bản bỏ kiểm biên. Tiêu chí fuzz của P2 vì thế còn giữ với mã hiện có; module mới
(`ipc`, vé, bản ghi của `store`) phải thêm đích của mình.

Gameplay đợt 1 (2026-10-14; nhật ký và số đo ở `docs/TIEN-DO.md`, mục "Máy chủ: gameplay đợt 1"). Bảy commit trên
`main`, từ `ce1f194d` tới `9f6d8267`, mỗi commit kiểm trong worktree sạch trước khi đẩy:

- `ipc` đã có (kênh bền niêm phong bằng khoá cụm, khung relay gate ↔ zone): mục "Còn thiếu để P2 đạt" ở trên về `ipc`
  và việc gate chưa chuyển tiếp là của ngày 2026-10-08, nay không còn đúng. `metrics` vẫn như cũ.
- P4 đạt một phần: `zone` thật (tick 20 Hz, AOI, cảnh tạo lười, quái/NPC đặt từ dữ liệu cảnh), nhiều khách thấy nhau
  trên cụm thật, luật đi do zone giữ (lưới `.path` của client 2026, hoàn bước bằng `Relay::kPlace`). Chưa đạt: đổi cảnh,
  400 bot một cảnh với p99 so ngân sách 50 ms, TSan, client hiện người chơi khác (client đã có module nối máy chủ từ 2026-10-15 nhưng chưa gửi `Move` và chưa vẽ thực thể).
- P9 có mã đủ lớp: sổ điểm chỉ-thêm, webhook ký HMAC, đổi điểm hai pha, mã đổi, tiến trình `thienlong_billing`, nhà cung
  cấp giả; `docs/SERVER-BILLING.md`. Chưa nối world (world còn là bản `ready` rồi chờ), nên hai pha mới chạy tới ranh
  giới ipc của billing; chưa đo tiêu chí "đối soát ngày khớp sau một nghìn đơn có chèn lỗi".
- P5 tới P8 (2026-10-15): lõi thuần của bốn mảng đã có và đã commit từng phase — chiến đấu (`actor`, `combat`, `797c914c`), vật phẩm
  và kinh tế (`item`, `loot`, `shop`, `forge`, `28327b34`; chưa có module nào cho giao dịch tay đôi, bày bán, ký gửi), nhiệm vụ (`ops`, `bus`,
  `ledger`, `mission`, `talk`, `handlers`, `9e0cc4d0`), xã hội (`social`, `824748e7`; có cả thư và chat lọc chữ). Cả bốn mới là thư viện
  có test: chưa nối zone, world, gate hay store, chưa có tin mạng. Tiêu chí "xong" của từng mốc (chín môn đánh quái ở ba cảnh, mười nghìn
  giao dịch bảo toàn qua khởi động lại zone, chuỗi tân thủ chạy trên client thật, hai trăm bot lập đội) chưa đạt. Chi tiết, số đo và
  phần chưa làm ở `docs/TIEN-DO.md` mục "gameplay đợt 2" và `docs/SERVER-{COMBAT,ITEM,MISSION,SOCIAL}.md`.

## 11. Vận hành

Máy chủ thử là chính máy phát triển này **[chốt]**. Mọi thứ của runtime nằm trong `SERVER/`; xem
`SERVER/README.md`.

Dựng lần đầu. Hai bước đầu đã chạy ngày 2026-10-06; các bước sau chờ mốc ghi trong ngoặc:

1. `python TOOLS/server/setup_db.py fetch`: tải PostgreSQL 18.6, kiểm SHA-256, giải nén vào
   `SERVER/pgsql`.
2. `python TOOLS/server/setup_db.py init`: initdb vào `SERVER/data/pg`, sinh
   `SERVER/config/secrets.local.toml`, tạo ba role và ba database.
3. Sinh dữ liệu: `python TOOLS/server/build_data.py --legacy <tlbb> --raw <_raw>` (đã chạy được từ
   đợt 2 của P1; gọi kê bảng, xuất bảng client, nhập bảng và luật của bản 0859602, xuất cảnh, quét
   lời gọi nạp cảnh); `bake_nav.py` khi có; rồi `thienlong_lint` (P1).
4. `cmake --install build/msvc-release --component server --prefix SERVER`: chép tám exe máy chủ
   vào `SERVER/bin` (có từ P2 đợt 1). Lệnh cài không có `--component server` chỉ cài client. Một
   lần duy nhất sau đó: `SERVER\bin\thienlong_gate.exe --gen-key SERVER\data\gate\identity.key`
   (có từ P2 đợt 3; thiếu tệp khoá thì gate thoát 2 và cả cụm không lên).
5. `thienlong_migrate` cho từng database (P3).
6. `SERVER\bin\thienlong_server.exe --config SERVER\config`: chạy cụm theo `supervisor.toml`, tự
   chạy PostgreSQL nếu nó chưa chạy (có từ P2 đợt 1). Dừng bằng Ctrl+C ở cửa sổ đó. Chỉ cần
   database: `python TOOLS/server/setup_db.py start` và `stop`.

Client nối từ đâu:

- Client trên chính máy này: `127.0.0.1`, cổng 7000 và 7001.
- Máy khác trong LAN, như máy tính bảng: địa chỉ LAN của máy này. Phải mở cổng 7000 và 7001 trong
  tường lửa Windows; việc đó cần quyền quản trị và làm khi gate chạy được (P2). Android nối qua cáp
  thì dùng `adb reverse` như bản Dev.
- Database và mọi cổng ipc chỉ nghe loopback.

Sao lưu: `pg_basebackup` cộng lưu WAL để khôi phục tới một thời điểm; `pg_dump` mỗi ngày cho
`thienlong_auth` và `thienlong_billing`. Công cụ nằm sẵn trong `SERVER/pgsql/bin`.

Nâng cấp: dừng gate, chờ zone và world đẩy hết delta, dừng theo thứ tự ngược, sao lưu, chạy
migration, khởi động lại. Đổi bảng dùng chung thì dấu nội dung đổi và client cũ bị ngắt: phát client
trước khi mở gate.

Không xoá ba thứ: `SERVER/data/pg` (mọi tài khoản và nhân vật), khoá danh tính của gate (mất là mọi
client đã phát phải cài lại) và khoá ký vé.

## 12. Rủi ro

| Rủi ro | Mức | Cách giảm |
|---|---|---|
| Không có dữ liệu máy chủ của bản 3.71 | cao | làm bản 0859602 trước; `diff_tables.py` đo phần thiếu; hai bộ dữ liệu `server-x86` và `server-x64` (mục 2) chưa được đo với bảng client 2026, đo trước khi nhập dữ liệu cho từng hệ; số tự đặt phải được chủ dự án duyệt và ghi nguồn |
| Khối lượng nội dung: 16.553 script, 574 bảng mới | cao | nội dung là bảng và op; công cụ trích trước, viết tay sau; mỗi hệ một lát |
| Tên bảng 2026 đoán sai nghĩa | vừa | 91 tên bảng còn dấu `?` trong phụ lục; chốt ở P1 bằng cách đọc bảng và Lua dùng nó |
| Nhân bản vật phẩm và tiền | cao | `ledger`, transaction, `request` idempotent, test bảo toàn ở P6 |
| Cổng vcpkg của `libpq` và `tomlplusplus` có bẫy khi link | thấp | đã đo ở P0 và ghi vào mục 11 của `AGENTS.md`: thêm `ws2_32`; không link thư viện `tomlplusplus` dịch sẵn |
| Đa luồng không có TSan trên Windows, mà máy chủ thử là máy Windows này | vừa | lõi một luồng mỗi cảnh, nói với nhau qua hộp thư; chạy TSan trên Linux khi có máy, chưa có thì ghi rõ chưa kiểm |
| Mã mật mã tự viết của Dev | vừa | dùng libsodium đã có; so từng phép khi port |
| Exe 0859602 bị đóng gói nên không đối chiếu được hành vi billing và máy chủ bản đó bằng đọc tĩnh | thấp | ngữ nghĩa lấy từ mã 2008 và từ schema; từ 2026-10-08 đối chiếu thêm bằng bản Linux 0.85.8130 chưa strip ở `G:\TLBB\_ref\runtime\server-x86\Server` (mục 2), tháo hàm theo tên; chỗ nghi ghi `docs/NGHI-NGO.md` |

## 13. Đã kiểm, chưa kiểm, giả định

Đã kiểm bằng máy:

- Mọi tệp của `Server/Config` (113), `Public/Config` (91 và hai thư mục con dạng bảng) và mọi bảng
  của client 2026 (718) đều có một dòng trong phụ lục: script kiểm thoát 0.
- Số đo ở mục 2 đọc từ tệp bằng lệnh trong phiên 2026-10-06.
- P0, ngày 2026-10-06, trên máy này:
  - `python TOOLS/server/setup_db.py fetch`, `init`, `status`, `stop`, `start`: PostgreSQL 18.6 chạy
    ở 127.0.0.1:5432 với ba database `thienlong_auth`, `thienlong_billing`, `thienlong_game_1`; chạy
    `init` lần hai giữ nguyên dữ liệu và mật khẩu.
  - Phép thử `tomlplusplus` (dựng bằng MSVC 19.51 và Clang 23.1, exception tắt): đọc đúng
    `SERVER/config/cluster.toml`; tệp có khoá trùng báo lỗi ở dòng 4; tệp không tồn tại báo lỗi.
  - Phép thử `libpq` 18.4 (tĩnh, không OpenSSL, cả hai trình dịch): role `thienlong_store` nối
    `thienlong_game_1` bằng SCRAM-SHA-256 và chạy truy vấn có tham số ra 42; sai mật khẩu bị từ
    chối; cùng role nối `thienlong_auth` bị từ chối vì không có quyền CONNECT.
  - `python TOOLS/server/lint_config.py`: 12 tệp sạch, 144 cài đặt đều có chú thích và thẳng cột;
    tám ca đột biến (xoá chú thích, tiêu đề tệp chữ thường, xoá khung tiêu đề của nhóm, chú thích
    tiếng Anh, thiếu dòng trống giữa hai nhóm, dòng quá 110 cột, sai cú pháp, lệch cột) đều bị
    bắt; `--fix` trả tệp lệch cột về đúng từng byte.

Chưa kiểm:

- Hai phép thử trên dựng trong thư mục tạm. Ngày 2026-10-08 `vcpkg.json` đã có `tomlplusplus`
  (module `config` dùng), chưa có `libpq` (thêm khi viết `store/pg` ở P3).
- Ngày 2026-10-08 `thienlong_gate` đã nghe cổng 7000 và 7001; chưa thử nối từ LAN, chưa mở tường
  lửa cho bản cài ở `SERVER/bin`, và client chưa có mã nối.
- Mã `secure` của Dev đã đọc khi port (`docs/SERVER-BAO-MAT.md` mục "Khác bản Dev").
  `G:\TLBB\_ref` và phần sau của `SERVER.md`, `LOGIC.md`, `NHIEM-VU.md` chưa có ghi nhận nào là đã
  đọc trọn.
- Mã mạng trong `Game.exe` của client 2026: không đọc, vì client THIENLONG không cần tương thích.
- Định dạng nhị phân của `.path`, `.stall`, `.ObjRegion`, `.Fly`, `.mfm`, `.mft`, `.cpf`.
- Chưa có số đo tải nào cho thiết kế bảy tiến trình; con số 400 người và 3,1 ms của Dev đo trước khi
  Dev tách bốn tiến trình. Ngày 2026-10-08 mới có số đo của riêng gate, chưa có tiến trình nào
  đứng sau nó (mục 10).
- TSan: máy này không chạy được.

Giả định:

- Client THIENLONG không cần nói protocol của client gốc.
- Tên tiếng Anh trong phụ lục là đề xuất; 91 tên bảng của client 2026 còn dấu `?`.
- Các số ghi "số tạm" trong `SERVER/config` chưa có phép đo.

Lệch quy định dự án:

- Port từ Dev nhưng đổi ba chỗ: cấu hình từ `server.cfg` sang TOML, kho bền từ `persist::Store` sang
  PostgreSQL, mật mã từ mã tự viết sang libsodium. Cả ba ghi `Khác gốc:` khi viết mã.
- Tệp TOML của `SERVER/config` dùng chú thích cuối dòng, căn thẳng cột bằng dấu cách và có khung
  tiêu đề bằng dấu `=`, trái hai luật chung "không comment cuối dòng" và "không căn thẳng cột":
  chủ dự án đưa mẫu bố cục và yêu cầu căn cột ngày 2026-10-06; hai luật chỉ nới cho các tệp đó,
  và việc căn do công cụ làm.
