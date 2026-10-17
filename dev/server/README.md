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
  `auth.toml` `[register] auto_register = true`); client PC gửi `Move` mỗi 50 ms và vẽ thực thể
  từ tin máy chủ.

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

`secrets.local.toml` và cả thư mục `data/` chỉ tài khoản chạy máy chủ đọc được (cùng SYSTEM và Administrators).
`init` đặt quyền đó; auth, store, billing và gate từ chối chạy khi tệp bí mật lỏng hơn, kèm một dòng nói tệp nào
(`docs/SERVER-DU-LIEU.md` mục 4). Chạy lại `init` thì giữ nguyên mật khẩu và khoá lại quyền.

Không xoá `data/pg`: đó là mọi tài khoản và nhân vật. Sao lưu bằng `pgsql/bin/pg_dump.exe` hoặc
`pg_basebackup.exe`.

## Chạy và dừng cụm

Chạy ở gốc dự án, sau khi dựng các target máy chủ (`thienlong_server`, `thienlong_store`,
`thienlong_auth`, `thienlong_billing`, `thienlong_world`, `thienlong_zone`, `thienlong_gate`,
`thienlong_lint`):

```
cmake --install build/msvc-release --component server --prefix dev
dev\server\bin\thienlong_gate.exe --gen-key dev\server\data\gate\identity.key
python -B TOOLS/server/local_cluster.py start
```

Lệnh đầu chép tám exe vào `bin/`. `--prefix dev` là bắt buộc: preset `msvc-release` mặc định cài vào
`release/`. Cài lại sau mỗi lần đổi mã hay đổi khoá cấu hình, và trước khi cài thì dừng cụm đang
chạy: exe cũ gặp khoá nó không biết thì từ chối cả tệp (đo 2026-10-08: bản cài ngày 07 dừng với
`gate.toml:32: khoá lạ idle_timeout_ms`, thoát 2), và exe cũ hơn `min_version` hay `allowed_builds`
của `gate.toml` bị gate từ chối.

Lệnh thứ hai chỉ chạy một lần: sinh khoá danh tính của gate và in khoá công khai (64 chữ số hex)
ra stdout; client ghim khoá công khai đó. Tệp đã có thì lệnh từ chối, không ghi đè. Thiếu tệp khoá
thì gate không in `ready` và thoát 2. Mất tệp này là mọi client đã phát phải cài lại.

Lệnh thứ ba chạy cụm ở nền, chỉ trên loopback: `local_cluster.py start` dựng `config.loopback` (bản
chép của `config/`, không vào git), chạy trình giám sát với bản chép đó rồi chờ dòng `ready ...
gate.game=7100 gate.auth=7101`; `status` và `stop` xem và dừng êm. Stdout của trình giám sát ở
`log/cluster_out.txt`, stderr (kèm stderr của mọi tiến trình con) ở `log/cluster_err.txt`; cả hai bị
cắt mỗi lần `start`. Sửa `config/` thì `start` lại để bản chép theo kịp. Chạy thẳng trình giám sát
(ở cửa sổ riêng, dừng bằng Ctrl+C) thì dùng `dev\server\bin\thienlong_server.exe --config
dev\server\config`.

Trình giám sát kiểm mọi tệp cấu hình (sai thì in từng lỗi `tệp:dòng: câu` rồi
thoát 2, không chạy gì), chạy PostgreSQL nếu cụm chưa chạy, rồi chạy store, auth, billing, world,
zone, gate theo `config/supervisor.toml`. Trên stdout là các dòng `started ...`, rồi `ready`. Dừng
bằng Ctrl+C trong cửa sổ đó: các tiến trình dừng ngược thứ tự, và PostgreSQL chỉ bị dừng nếu chính
trình giám sát đã chạy nó. Thêm `--no-postgres` để không đụng tới database. Một tiến trình con chết
thì được chạy lại, tối đa `[restart] max_per_hour` lần mỗi giờ.

`gate.toml` cho gate nghe `127.0.0.1:7100` (game) và `127.0.0.1:7101` (xác thực): cổng 7000 và 7001
trên máy này do cụm TLBB gốc giữ. Nghe loopback nên Windows không tạo rule tường lửa. Cho LAN nối
vào thì đổi hai dòng `[listen]` sang `0.0.0.0:<cổng>`; lần đầu một exe ở một đường dẫn mới nghe như
vậy, Windows tạo rule tường lửa cho đúng đường dẫn đó và có thể hiện hộp thoại hỏi. Thử mà không
muốn đụng cổng của cụm đang chạy thì chép `config/` ra một thư mục tạm, đổi hai dòng `[listen]`
thành `127.0.0.1:0` và trỏ `identity_key_file` tới một khoá tạm: gate nghe ở cổng do hệ điều hành
cấp và in cổng thật ở dòng `ready game=<cổng> auth=<cổng>`. Test của dự án (`service_tests`,
`server_boot`, `gate_loop_tests`), công cụ đo tải `thienlong_gate_load` và `boot_check.py` tự làm
đúng việc đó, nên không đụng cổng 7100, 7101 của cụm đang chạy.

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

Gate nghe cổng 7100 (game) và 7101 (xác thực). Client PC đọc địa chỉ và khoá công khai của gate từ
`dev/client/assets/Table/gates.tsv` (không vào git): `python -B TOOLS/server/export_gates.py` ghi bảng từ
`gate.toml` và khoá danh tính của gate (cổng khai 0 thì công cụ từ chối: cổng 0 không ghim được; cụm thử có cổng thật 7100 và 7101 thì chạy được), rồi
chọn đúng máy chủ trong bảng chọn của màn đăng nhập (`--login`). Client trên máy này nối `127.0.0.1` cổng
7100 và 7101; máy khác trong LAN chỉ nối được sau khi `[listen]` đổi sang `0.0.0.0` và hai cổng đó mở
trong tường lửa Windows. Máy chủ trong bảng chọn mà không có dòng ở `gates.tsv` là máy chủ cục bộ,
client không mở socket. Database và các cổng nội bộ chỉ nghe loopback.

## Log kiểm theo việc người chơi

Khoá `play_trace` ở `config/log.toml` (mặc định `false`) bật cho zone ghi một dòng stderr mỗi khi
người chơi làm một việc; dev để `true`. Dòng nằm ở `log/cluster_err.txt` cùng stderr của các tiến
trình khác (lọc theo tiền tố `zone: kiểm`):

```
zone: kiểm tick=<tick zone> việc=<tên> tk=<id tài khoản> nv=<id nhân vật> scene=<id> x=<cm> z=<cm> kq=<kết quả> gt=<giá trị> ten="<tên nhân vật>"
```

Việc: `vào`, `rời`, `đi` (tối đa một dòng mỗi giây mỗi người), `kéo` (zone chặn bước đi, gate gửi
`Position` kéo về), `nói`, `chọn`, `nhận`, `trả`, `bỏ`, `chiêu`, `đánh` (người chơi ra đòn trúng),
`trúng` (người chơi bị trúng), `hạ` (người chơi hạ quái), `chết`, `hồi`, `nhặt`.

- `kq` là `ok`, hoặc mã `ErrorCode` bằng số khi zone từ chối việc đó.
- `gt` là con số của việc: id thực thể NPC (`nói`, `chọn`, `nhận`, `trả`), id nhiệm vụ (`bỏ`), id
  kỹ năng (`chiêu`), sát thương (`đánh`, `trúng`), mẫu quái (`hạ`), id thực thể kẻ ra đòn (`chết`),
  nơi hồi (`hồi`), mẫu vật phẩm (`nhặt`); các việc còn lại là 0.
- `kéo`: `x`, `z` là toạ độ bước bị chặn (nơi client báo), dòng có thêm ` về=<x>,<z>` là chỗ đứng
  zone buộc người chơi trở lại. Đối chiếu với ô đi được của `scenes/*.path`.
- Tài khoản chỉ là id số, không bao giờ có mật khẩu hay vé. Tên nhân vật bỏ dấu nháy và ký tự
  điều khiển. Khoá tắt thì zone không ghi ghi chú nào và không định dạng gì.

## Bot thử

`dev\server\bin\thienlong_bot.exe` (đích `thienlong_bot`, mã `TOOLS/server/bot.cpp`) là khách giả
nối cụm thật, mặc định cổng 7100 và 7101. Bot được cài cùng lượt với các exe của cụm, vì bot dựng
từ cây khác đời với gate thì bắt tay hỏng và mọi kịch bản E2E báo không lấy được vé. `--probe 1`
chỉ bắt tay rồi in `giao thức: bot v<N>, cụm v<M>` (thoát 1 nếu cụm từ chối); `e2e_g0.py` chạy nó
trước mỗi lượt và ghi hai số đó vào báo cáo. `--roster 1` không vào cảnh: hai tài khoản
`<prefix>r` và `<prefix>x` (đặt `--prefix` mới mỗi lần, nhân vật nằm lại trong database) đi qua
tạo và xoá nhân vật, in mã server trả cho từng bước (trần ba nhân vật, xoá id người khác, xoá
lại id đã xoá, xoá nhân vật đang chơi, xoá dồn dưới 500 ms, xoá khi hết nhân vật) và thoát 1
nếu một bước sai mã mong đợi. Ví dụ: `thienlong_bot --identity
dev\server\data\gate\identity.key --count 2 --seconds 8 --prefix e2em1`. `--peers N` cho một bot đứng
yên đủ `--seconds` giây rồi thoát 0 nếu thấy ít nhất N người chơi khác; đặt cạnh client thật trong
kịch bản E2E. `--walk dev\server\scenes\dali\walk.path` cho `--hunt`, `--talk`, `--fight` đi theo luật
đi của client (đường vòng vật cản; đứng trong vật cản thì bước ra trước, như người chơi bấm gần); không
có `--walk` thì đi thẳng. Các chế độ `--straight`, `--hunt`, `--talk`, `--fight` ghi ở đầu tệp nguồn.
