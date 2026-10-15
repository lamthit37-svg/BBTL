# dev/server — máy chủ thử

Đây là máy chủ của bản `dev`: cấu hình, bảng, cảnh, SQL, exe, PostgreSQL và dữ liệu của bản thử.
Không có mã nguồn. Mã ở `src/server/`. Bản chính thức cùng hình nằm ở `release/server`, database
riêng. Kế hoạch ở `docs/KE-HOACH-SERVER.md`, danh sách tệp ở `docs/SERVER-TEP-CAU-HINH.md`.

Trạng thái theo mã ngày 2026-10-14 (chi tiết ở mục 0 của `AGENTS.md`):

- Bảy exe đọc và kiểm cấu hình, khởi động theo thứ tự, in `ready`, dừng ngược thứ tự.
- Chỉ `thienlong_gate` mở cổng: nó nghe hai cổng của `gate.toml`, bắt tay bảo mật
  (`docs/SERVER-BAO-MAT.md`), giữ phiên đã bắt tay rồi gửi `SessionStart`, `UiConfig`
  (`client.toml` `[hud] avatar_frame`) và `Position`; sau đó mới xử lý ba tin mức
  phiên `Hello`, `Ping`, `Logout`; mọi tin khác bị ngắt.
- Đã có logic tài khoản/nhân vật dùng chung (`src/server/account/`: sổ, luật, vé,
  RPC loopback, bản SQL) và `serve_auth`/`serve_game` qua ipc; `zone` và `billing` chạy thật,
  `world` ngoài `ready` vẫn chờ lệnh dừng. Migration áp lúc khởi động bằng `store::migrate`
  (auth ở `authd`, game ở `store`, billing ở `billingd`); client PC đã nối đăng nhập, chọn nhân
  vật và vào game (xem "Client nối vào đâu").
- Chưa có tài khoản, nhân vật hay cảnh nào chạy sẵn (tài khoản tự tạo lúc đăng nhập vì
  `auth.toml` `[register] auto_register = true`); client chưa gửi `Move` và chưa vẽ thực thể.

## Bố cục

Nhà phát hành (vận hành máy chủ, không có source) chỉ sửa trong `config/`. Mọi thư mục khác là của
nhà phát triển, bị thay ở lần nâng bản sau: sửa ở đó là mất. Định dạng từng loại dữ liệu, tệp đè và
bảo mật ở `docs/SERVER-DU-LIEU.md`.

- `config/` — mười một tệp TOML của các tiến trình và tệp mẫu `secrets.example.toml`. Vào git,
  trừ `secrets.local.toml`.
- `config/rules/` — TOML luật chơi, công cụ của mốc P1 sinh từ tệp ini gốc. Vào git. Mới có 6
  trên 13 tệp của kế hoạch: `global`, `combat`, `character`, `new_character`, `monster`,
  `instances`.
- `tables/server/` — 105 bảng chỉ máy chủ giữ và tệp chữ thoại `dialogue.zh.txt` (2.507 câu viết
  thẳng trong script Lua gốc, nhóm theo NPC). Vào git.
- `tables/shared/` (574 bảng), `tables/variants/` (61 bảng, sáu bộ) — bảng xuất từ client. Git bỏ
  qua, sinh lại bằng công cụ.
- `scenes/<scene>/` — dữ liệu máy chủ của 244 cảnh: `scene.toml`, các bảng `.tsv` và lưới đi
  `walk.nav`. Tệp chữ vào git; `.nav` và `.bin` thì không.
- `sql/auth`, `sql/billing`, `sql/game` — migration của ba database. Vào git. Có 8 tệp: auth 2,
  billing 5, game 1 (`001_character.sql`); tiến trình sở hữu database áp chúng lúc khởi động.
- `bin/` — exe do `cmake --install` chép vào. Git bỏ qua.
- `pgsql/` — nhị phân PostgreSQL 18.6. Git bỏ qua, `setup_db.py fetch` tải lại được.
- `data/` — cụm PostgreSQL (`data/pg`), khoá danh tính của gate (`data/gate/identity.key`), nhật
  ký ghi. Git bỏ qua.
- `log/` — log. Git bỏ qua.

## Database

Chạy ở gốc dự án:

```
python TOOLS/server/setup_db.py fetch     tải PostgreSQL, kiểm SHA-256, giải nén vào dev/server/pgsql
python TOOLS/server/setup_db.py init      tạo cụm, sinh mật khẩu, tạo role và database
python TOOLS/server/setup_db.py start     chạy cụm
python TOOLS/server/setup_db.py status    xem phiên bản và các database
python TOOLS/server/setup_db.py stop      dừng cụm
```

Cụm nghe `127.0.0.1:5432`, không cài dịch vụ Windows, không cần quyền quản trị. Địa chỉ và đường dẫn
lấy từ `config/cluster.toml`. Ba database, mỗi cái một role riêng: `thienlong_auth`,
`thienlong_billing`, `thienlong_game_1` (role `thienlong_store`). Mật khẩu nằm ở
`config/secrets.local.toml`.

Không xoá `data/pg`: đó là mọi tài khoản và nhân vật. Sao lưu bằng `pgsql/bin/pg_dump.exe` hoặc
`pg_basebackup.exe`.

## Chạy và dừng cụm

Chạy ở gốc dự án, sau khi dựng preset `msvc-release`:

```
cmake --install build/msvc-debug --component server
dev\server\bin\thienlong_gate.exe --gen-key dev\server\data\gate\identity.key
dev\server\bin\thienlong_server.exe --config dev\server\config
```

Lệnh đầu chép tám exe vào `bin/`. Cài lại sau mỗi lần đổi mã hay đổi khoá cấu hình: exe cũ gặp
khoá nó không biết thì từ chối cả tệp (đo 2026-10-08: bản cài ngày 07 dừng với `gate.toml:32: khoá
lạ idle_timeout_ms`, thoát 2).

Lệnh thứ hai chỉ chạy một lần: sinh khoá danh tính của gate và in khoá công khai (64 chữ số hex)
ra stdout; client ghim khoá công khai đó. Tệp đã có thì lệnh từ chối, không ghi đè. Thiếu tệp khoá
thì gate không in `ready` và thoát 2. Mất tệp này là mọi client đã phát phải cài lại.

Lệnh thứ ba là trình giám sát: nó kiểm mọi tệp cấu hình (sai thì in từng lỗi `tệp:dòng: câu` rồi
thoát 2, không chạy gì), chạy PostgreSQL nếu cụm chưa chạy, rồi chạy store, auth, billing, world,
zone, gate theo `config/supervisor.toml`. Trên stdout là các dòng `started ...`, rồi `ready`. Dừng
bằng Ctrl+C trong cửa sổ đó: các tiến trình dừng ngược thứ tự, và PostgreSQL chỉ bị dừng nếu chính
trình giám sát đã chạy nó. Thêm `--no-postgres` để không đụng tới database. Một tiến trình con chết
thì được chạy lại, tối đa `[restart] max_per_hour` lần mỗi giờ.

`gate.toml` cho gate nghe `0.0.0.0` (mọi giao diện mạng). Lần đầu một exe ở một đường dẫn mới nghe
như vậy, Windows tạo rule tường lửa cho đúng đường dẫn đó và có thể hiện hộp thoại hỏi. Thử trên
chính máy này mà không muốn đụng tường lửa thì chép `config/` ra một thư mục tạm, đổi hai dòng
`[listen]` thành `127.0.0.1:0` và trỏ `identity_key_file` tới một khoá tạm: gate nghe ở cổng do hệ
điều hành cấp và in cổng thật ở dòng `ready game=<cổng> auth=<cổng>`. Test của dự án
(`service_tests`, `server_boot`, `gate_loop_tests`), công cụ đo tải `thienlong_gate_load` và
`boot_check.py` tự làm đúng việc đó, nên không đụng cổng 7000, 7001 của cụm đang chạy.

Kiểm bảng và cấu hình trước khi chạy: `dev\server\bin\thienlong_lint.exe --root dev\server --refs
TOOLS\server\refs`. Giao kèo giữa các tiến trình ghi ở mục 3.1 của `docs/KE-HOACH-SERVER.md`.

## Sửa cấu hình

Mỗi tệp trong `config/` mở đầu bằng khung tiêu đề in hoa kẹp giữa hai dòng `#====`. Mỗi nhóm cài
đặt có một khung tiêu đề riêng; các cài đặt trong nhóm nằm sát nhau, mỗi cài đặt một chú thích
tiếng Việt ngang hàng, dấu `=` và dấu `#` thẳng cột. Thêm hay sửa cài đặt thì không cần căn tay,
chạy lệnh dưới: nó căn cột lại rồi kiểm.

```
python TOOLS/server/lint_config.py --fix
```

Lệnh báo từng dòng sai: sai cú pháp TOML, cài đặt thiếu chú thích, nhóm thiếu khung tiêu đề, dòng
quá 110 cột. Bỏ `--fix` thì lệnh chỉ kiểm, không sửa tệp. Số có ghi "số tạm" là số chưa có phép đo.

## Client nối vào đâu

Gate nghe cổng 7000 (game) và 7001 (xác thực). Client PC đọc địa chỉ và khoá công khai của gate từ
`dev/client/assets/Table/gates.tsv` (không vào git): `python -B TOOLS/server/export_gates.py` ghi bảng từ
`gate.toml` và khoá danh tính của gate (cổng khai 0 thì công cụ từ chối: cổng 0 không ghim được; cụm thử có cổng thật 7000 và 7001 thì chạy được), rồi
chọn đúng máy chủ trong bảng chọn của màn đăng nhập (`--login`). Client trên máy này nối `127.0.0.1` cổng
7000 và 7001; máy khác trong LAN nối địa chỉ LAN của máy này, sau khi mở hai cổng đó trong tường lửa Windows.
Máy chủ trong bảng chọn mà không có dòng ở `gates.tsv` là máy chủ cục bộ, client không mở socket. Database
và các cổng nội bộ chỉ nghe loopback.
