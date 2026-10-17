# Công cụ cấu hình máy chủ THIÊN LONG (cfgtool)

Công cụ đọc, kiểm, căn chỉnh và xuất các tệp cấu hình trong `dev/server/config` (và bản `release/` cùng kiểu)
đúng định dạng máy chủ cần. Lược đồ chép từ chính bộ đọc C++ ở `src/server/config/*.cpp`, và test đối chiếu
kết quả với `dev/server/bin/thienlong_lint.exe` (bộ đọc thật của máy chủ).

## Chạy

```powershell
cd D:\THIENLONG
python TOOLS\cfgtool\cfgtool.py gui                        # giao diện (PySide6, Fusion sáng)
python TOOLS\cfgtool\cfgtool.py gui release\server\config  # mở thư mục config khác
python TOOLS\cfgtool\cfgtool.py show dev\server\config\gate.toml
python TOOLS\cfgtool\cfgtool.py check dev\server\config
python TOOLS\cfgtool\cfgtool.py import C:\tam\gate.toml dev\server\config\gate.toml
python TOOLS\cfgtool\cfgtool.py export dev\server\config D:\xuat\config
python TOOLS\cfgtool\cfgtool.py roundtrip                  # tự kiểm: xuất lại cả bộ + chạy thienlong_lint
python TOOLS\cfgtool\test_cfgtool.py                       # bộ test đầy đủ
```

Không cần thư viện mới: Python 3.13 (tomllib có sẵn) và PySide6 đã cài. CLI chạy được không cần PySide6.

## Giao diện

- Cột trái: các tệp `.toml` của thư mục config và `rules/`. Tệp `*.local.toml` không bao giờ được liệt kê hay mở.
- Bảng giữa: mỗi khoá một dòng với **Nhóm, Khoá, Giá trị, Kiểu, Miền hợp lệ, Bắt buộc, Mặc định, Đơn vị,
  Chức năng, Cách đặt cho production, Gợi ý production**. Bấm đúp ô Giá trị để sửa (chuỗi phải có nháy kép,
  ví dụ `"info"`; mảng viết `[1, 2, 3]`). Sửa xong công cụ tự căn thẳng cột và kiểm lại ngay.
- Thẻ dưới: *Lỗi và việc đã làm* (lỗi theo dòng, câu y hệt máy chủ), *Chi tiết trường*, *Văn bản sẽ xuất (đúng byte)*.
- Thanh công cụ: Mở thư mục, Nhập tệp, Lưu vào tệp gốc, Xuất tệp, Xuất cả bộ, Căn chỉnh, Kiểm tra cả thư mục (F5),
  Kiểm bằng bộ đọc của máy chủ (F6: chạy thienlong_lint trên bản sẽ xuất, trong thư mục tạm).

## Nhập tệp làm gì

1. Giải mã: bỏ BOM, đổi UTF-16 sang UTF-8, đổi CRLF/CR sang LF. Tệp không phải UTF-8 thì báo lỗi, không đoán.
2. Dọn khoảng trắng cuối dòng, tab, dòng trống thừa.
3. Tệp đã có bố cục dự án: giữ nguyên chữ và chú thích, thêm chú thích tiếng Việt cho khoá nào còn thiếu,
   căn thẳng cột dấu `=` và `#` (đúng hàm `align_lines` của `TOOLS/server/config_style.py`), dòng dài quá
   110 cột thì đưa chú thích lên dòng trên.
4. Tệp chưa có bố cục (TOML trần): dựng lại cả tệp với khung tiêu đề, nhóm và khoá theo đúng thứ tự của bộ đọc.
5. Kiểm lại giá trị không đổi (so cây TOML trước và sau); đổi là dừng, không ghi.
6. Kiểm theo lược đồ: khoá lạ, nhóm lạ, thiếu khoá, sai kiểu, ngoài miền, mảng vượt trần, giá trị lặp,
   kiểm chéo cluster (id máy lặp, cặp kind/id lặp, máy không có) và supervisor (bước lặp, thiếu process trong cluster).

## Định dạng máy chủ cần (rút từ mã)

| Điều | Nguồn |
|---|---|
| TOML đọc bằng toml++ (không exception), tối đa 1 048 576 byte, độ sâu 8, mảng/bảng ≤ 256 phần tử, chuỗi ≤ 4096 byte, khoá ≤ 128 byte | `config/detail/parse.cpp`, `node.hpp` |
| Khoá gốc `schema = 1` bắt buộc ở mọi tệp | `Cursor::schema`, `kSchema` |
| Khoá không có trong danh sách là "khoá lạ"/"nhóm lạ"; thiếu khoá bắt buộc là lỗi; **không có giá trị mặc định** trừ các khoá ghi "tuỳ chọn" | `Cursor::only`, `Cursor::required` |
| Mọi số nguyên trong int32 (0 hoặc 1 tới 2 147 483 647 tuỳ khoá); số thực, ngày giờ là sai kiểu | `read.hpp` (`kCount`, `kAmount`) |
| IPv4 viết đủ 4 số, không số 0 đứng đầu; `"a.b.c.d:cổng"`; cổng 0 chỉ khi địa chỉ đúng `127.0.0.1` | `types.cpp` |
| UTF-8 không BOM, LF, một dòng trống giữa các nhóm, khung tiêu đề `#` + 50 dấu `=`, chú thích tiếng Việt cho mọi khoá, `=` và `#` thẳng cột, dòng ≤ 110 cột | `TOOLS/server/config_style.py`, `lint_config.py`, tệp hiện có |
| `*.local.toml` không bao giờ được mở bởi công cụ kiểm | `linttool/config_lint.cpp` |

## Bí mật

- `secrets.local.toml` (mật khẩu thật, do `setup_db.py init` sinh) và các tệp khoá (`data/ipc.key`,
  `token_file`, `identity_key_file`, `secret_file`) **không bao giờ** được công cụ mở, in, chép hay xuất.
  Công cụ chỉ kiểm đường dẫn là chuỗi hợp lệ.
- `secrets.example.toml`: giá trị mật khẩu hiển thị là `••••••` nếu có, và luôn xuất ra `""`.

## Bằng chứng kiểm

`python TOOLS\cfgtool\test_cfgtool.py`:
- 25/25 tệp của `dev/server/config` (12 tệp tiến trình + 13 tệp luật): export(import(x)) giống x từng byte;
  thienlong_lint chạy trên bản xuất: mã thoát 0, 0 lỗi.
- 23 phép làm hỏng (cổng sai, khoá lạ, thiếu nhóm, sai kiểu, mảng lặp, CIDR sai, cổng 0 ngoài loopback, vượt int32…):
  cfgtool báo **đúng cùng dòng, cùng câu** với thienlong_lint.
- Tệp lộn xộn (BOM, CRLF, tab, khoảng trắng lệch) nhập vào ra đúng từng byte bản chuẩn.
- TOML trần không chú thích được dựng lại đủ bố cục; qua cả `lint_config.py` và thienlong_lint.

## Mọi khoá cấu hình

Cột "Cách đặt cho production" là gợi ý vận hành; các số ghi "số tạm" trong tệp dev chưa có phép đo, hãy đo tải trước khi chốt.

### admin.toml

Bộ đọc: `config::read_admin (admin.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| (gốc) | `listen` | "a.b.c.d:cổng" (cổng 0 chỉ với 127.0.0.1) | bắt buộc | Địa chỉ và cổng của cổng quản trị. | Production: chỉ nghe 127.0.0.1 để phải ngồi ở máy chủ mới nối được. Không mở ra mạng. `"127.0.0.1:7002"` |
| (gốc) | `token_file` | chuỗi; 1 – 512 byte, không ký tự điều khiển | bắt buộc | Tệp mã bí mật mà công cụ quản trị phải trình khi nối (đường dẫn tương đối tính từ thư mục config). | Đặt ngoài thư mục web, quyền đọc chỉ cho tài khoản chạy dịch vụ. Công cụ không bao giờ mở hay in tệp này. `"../data/admin/token"` |
| [[operator]] | `name` | chuỗi; 1 – 64 byte, không ký tự điều khiển | tuỳ chọn | Tên người vận hành. | Tên ngắn, không dấu cách thừa. `"admin"` |
| [[operator]] | `level` | số nguyên; 0 – 2147483647 | tuỳ chọn | Cấp quyền của người vận hành. | Cấp thấp nhất đủ dùng. `1` |

### auth.toml

Bộ đọc: `config::read_auth (auth.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [database] | `name` | tên định danh (chữ cái đầu, rồi chữ, số, _ hoặc -; tối đa 63) | bắt buộc | Tên database PostgreSQL mà tiến trình nối tới. | Giữ đúng tên do setup_db.py tạo; đổi tên phải đổi cả database thật. `"thienlong_auth"` |
| [database] | `user` | tên định danh (chữ cái đầu, rồi chữ, số, _ hoặc -; tối đa 63) | bắt buộc | Role PostgreSQL dùng để nối; chỉ có quyền trên database này. | Mỗi dịch vụ một role riêng, không dùng role postgres. Mật khẩu nằm ở secrets.local.toml. `"thienlong_auth"` |
| [database] | `pool` | số nguyên; 1 – 2147483647 | bắt buộc | Số kết nối giữ sẵn tới database. | Bắt đầu 2–8; tăng khi đo thấy hàng chờ truy vấn. Tổng pool mọi tiến trình phải nhỏ hơn max_connections của PostgreSQL. `4` |
| [register] | `auto_register` | true/false | bắt buộc | true: đăng nhập bằng tên chưa có thì tạo luôn tài khoản. | Production: false, để đăng ký đi qua trang đăng ký có kiểm soát; true chỉ cho máy thử. `false` |
| [register] | `gift_points` | số nguyên; 0 – 2147483647 | bắt buộc | Số điểm nạp tặng cho tài khoản mới. | 0 trừ khi có chương trình khuyến mãi. `0` |
| [password] | `ops_limit` | số nguyên; 1 – 2147483647 | bắt buộc | Số lượt tính của một lần băm Argon2id. | Tối thiểu 2 (INTERACTIVE). Tăng lên 3 nếu máy dư CPU; đo thời gian đăng nhập < 0,5 giây. `3` |
| [password] | `mem_limit_kib` | số nguyên; 1 – 2147483647; đơn vị KiB | bắt buộc | Bộ nhớ của một lần băm Argon2id. | Tối thiểu 65536 (64 MiB). Nhân với số đăng nhập đồng thời để chắc đủ RAM. `65536` |
| [ticket] | `ttl_seconds` | số nguyên; 0 – 2147483647; đơn vị giây | bắt buộc | Vé đăng nhập hết hạn sau bao nhiêu giây. | 60–300. Ngắn hơn thì vé lộ ít nguy hiểm hơn. `120` |
| [login] | `relogin_limit` | true/false | bắt buộc | true: cùng một IP phải cách 20 giây mới được đăng nhập lại. | Production: true để chặn dò mật khẩu nhanh. `true` |
| [login] | `relogin_block` | true/false | bắt buộc | true: đang online mà có đăng nhập từ IP khác thì đá phiên cũ và chặn. | Bật nếu muốn chống chia sẻ tài khoản; cân nhắc người chơi đổi mạng 4G/Wi-Fi. `false` |
| [login] | `relogin_block_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Thời gian chặn của relogin_block. | 600000 (10 phút). `600000` |
| [login] | `queue_turn_size` | số nguyên; 1 – 2147483647 | bắt buộc | Số người trong hàng chờ được vào mỗi lượt khi máy chủ đầy. | 50–200 tuỳ sức zone. `100` |
| [login] | `max_sessions_per_device` | số nguyên; 1 – 2147483647 | bắt buộc | Số phiên cùng lúc cho một máy client. | Production: 2–5 để hạn chế treo nhiều nick; bản thử để 30. `3` |
| [captcha] | `on_create` | true/false | bắt buộc | true: hỏi mã xác minh khi tạo nhân vật. | Bật khi bị tạo nick hàng loạt. `false` |
| [captcha] | `on_enter` | true/false | bắt buộc | true: hỏi mã xác minh khi vào game. | Bật khi bị bot. `false` |
| [security_card] | `enabled` | true/false | bắt buộc | true: tài khoản có gắn thẻ phải trả lời ô thẻ khi đăng nhập. | Tuỳ chính sách. `false` |

### billing.toml

Bộ đọc: `config::read_billing (billing.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [database] | `name` | tên định danh (chữ cái đầu, rồi chữ, số, _ hoặc -; tối đa 63) | bắt buộc | Tên database PostgreSQL mà tiến trình nối tới. | Giữ đúng tên do setup_db.py tạo; đổi tên phải đổi cả database thật. `"thienlong_billing"` |
| [database] | `user` | tên định danh (chữ cái đầu, rồi chữ, số, _ hoặc -; tối đa 63) | bắt buộc | Role PostgreSQL dùng để nối; chỉ có quyền trên database này. | Mỗi dịch vụ một role riêng, không dùng role postgres. Mật khẩu nằm ở secrets.local.toml. `"thienlong_billing"` |
| [database] | `pool` | số nguyên; 1 – 2147483647 | bắt buộc | Số kết nối giữ sẵn tới database. | Bắt đầu 2–8; tăng khi đo thấy hàng chờ truy vấn. Tổng pool mọi tiến trình phải nhỏ hơn max_connections của PostgreSQL. `2` |
| [access] | `allow` | mảng địa chỉ IPv4 | bắt buộc | Địa chỉ được gọi billing; địa chỉ khác bị từ chối. | Chỉ IP của máy chạy world. Một máy: ["127.0.0.1"]. `["127.0.0.1"]` |
| [limits] | `max_clients` | số nguyên; 1 – 2147483647 | bắt buộc | Số kết nối cùng lúc tới billing. | Vài chục là đủ; chỉ world nối. `64` |
| [points] | `ingot_per_point` | số nguyên; 1 – 2147483647 | bắt buộc | Một điểm nạp đổi được bao nhiêu ingot. | Theo tỉ giá kinh doanh đã chốt. `1` |
| [points] | `register_gift` | số nguyên; 0 – 2147483647 | bắt buộc | Số điểm nạp tặng khi tài khoản được tạo. | 0 trừ khi có khuyến mãi. `0` |
| [spend] | `daily_ingot_cap` | số nguyên; 0 – 2147483647 | bắt buộc | Số ingot tối đa một nhân vật được tiêu mỗi ngày. | Chặn thiệt hại khi tài khoản bị chiếm. `120000` |
| [orders] | `pending_timeout_seconds` | số nguyên; 0 – 2147483647; đơn vị giây | bắt buộc | Đơn chờ game xác nhận quá số giây này thì sang đối soát. | 300–900. `600` |
| [orders] | `reconcile_interval_seconds` | số nguyên; 0 – 2147483647; đơn vị giây | bắt buộc | Chu kỳ đối soát các đơn còn chờ. | 30–120. `60` |
| [redeem] | `attempts_per_hour` | số nguyên; 0 – 2147483647 | bắt buộc | Số lần nhập mã tối đa mỗi giờ cho một tài khoản. | 5–10 để chống dò mã. `5` |
| [webhook] | `port` | số nguyên; 0 – 65535 | bắt buộc | Cổng HTTP của webhook, chỉ nghe 127.0.0.1 sau reverse proxy có TLS. | Cổng cố định 1024–65535; 0 (hệ điều hành chọn) chỉ dùng cho test. Chỉ nghe khi có [[provider]] bật. `7014` |
| [[provider]] | `key` | chuỗi; 1 – 64 byte, không ký tự điều khiển | tuỳ chọn | Mã nhà cung cấp. | Tên ngắn, duy nhất. `"momo"` |
| [[provider]] | `webhook_path` | chuỗi; 1 – 512 byte, không ký tự điều khiển | tuỳ chọn | Đường dẫn HTTP nhà cung cấp gọi vào. | Khó đoán, ví dụ có chuỗi ngẫu nhiên. `"/pay/momo"` |
| [[provider]] | `secret_file` | chuỗi; 1 – 512 byte, không ký tự điều khiển | tuỳ chọn | Tệp chứa khoá ký của nhà cung cấp. | Ngoài git, quyền đọc hạn chế. Công cụ không mở tệp này. `"../data/billing/momo.key"` |
| [[provider]] | `enabled` | true/false | tuỳ chọn | Bật nhà cung cấp này. | Chỉ bật khi đã thử webhook ở môi trường test. `true` |

### client.toml

Bộ đọc: `config::read_client (client.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [hud] | `avatar_frame` | một trong tập giá trị; round | square | bắt buộc | Dạng khung chân dung của HUD: square là classic (nền vuông, ảnh 2D), round là nền tròn đầu 3D. | Chọn theo bản client phát hành. `"square"` |

### cluster.toml

Bộ đọc: `config::read_cluster (cluster.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [world] | `id` | số nguyên; 1 – 2147483647 | bắt buộc | Số của thế giới, từ 1; database game mang tên thienlong_game_<id>. | Mỗi máy chủ (server) một id riêng, không dùng lại. Phải khớp store.toml [database] name. `1` |
| [world] | `zone_group` | số nguyên; 0 – 2147483647 | bắt buộc | Nhóm máy chủ; các thế giới cùng nhóm chung một danh sách chọn máy chủ. | Theo quy hoạch cụm. `0` |
| [world] | `name` | chuỗi; 1 – 64 byte, không ký tự điều khiển | bắt buộc | Tên cụm trong log và công cụ quản trị; không gửi cho client. | Tên dễ nhận ra, ví dụ "tlbb-s1". `"tlbb-s1"` |
| [world] | `table_variant` | chuỗi; 0 – 64 byte, không ký tự điều khiển | bắt buộc | Bộ bảng thay thế theo loại máy chủ; rỗng là dùng bảng gốc. | Thường để rỗng. `""` |
| [postgres] | `host` | địa chỉ IPv4 a.b.c.d | bắt buộc | Địa chỉ cụm PostgreSQL nghe. | Production: 127.0.0.1 hoặc IP mạng nội bộ; không mở ra Internet. `"127.0.0.1"` |
| [postgres] | `port` | cổng 1–65535; 1 – 65535 | bắt buộc | Cổng TCP của cụm. | 5432 hoặc cổng nội bộ tuỳ chọn. `5432` |
| [postgres] | `bin_dir` | chuỗi; 1 – 512 byte, không ký tự điều khiển | bắt buộc | Thư mục chứa postgres.exe, pg_ctl.exe, psql.exe. | Đường dẫn tới bản PostgreSQL đi kèm. `"../pgsql/bin"` |
| [postgres] | `data_dir` | chuỗi; 1 – 512 byte, không ký tự điều khiển | bắt buộc | Thư mục dữ liệu; xoá là mất mọi tài khoản và nhân vật. | Ổ riêng, có sao lưu định kỳ. `"../data/pg"` |
| [postgres] | `log_file` | chuỗi; 1 – 512 byte, không ký tự điều khiển | bắt buộc | Tệp log của tiến trình postgres. | Thư mục log có xoay vòng. `"../log/postgres.log"` |
| [[machine]] | `id` | số nguyên; 0 – 2147483647 | bắt buộc | Số của máy; khoá machine của [[process]] trỏ tới số này. | 0, 1, 2…; không lặp. `0` |
| [[process]] | `kind` | một trong tập giá trị; store | auth | billing | world | zone | bắt buộc | Loại tiến trình. | Cần đủ store, auth, billing, world và ít nhất một zone. `"zone"` |
| [[process]] | `id` | số nguyên; 0 – 2147483647 | bắt buộc | Số thứ tự trong cùng loại, từ 0. | Cặp (kind, id) không lặp. `0` |
| [[process]] | `machine` | số nguyên; 0 – 2147483647 | bắt buộc | Máy chạy tiến trình, theo id của [[machine]]. | Phải có trong danh sách [[machine]]. `0` |
| [[process]] | `host` | địa chỉ IPv4 a.b.c.d | bắt buộc | Địa chỉ mà cổng ipc nghe. | 127.0.0.1 khi một máy; IP LAN nội bộ khi nhiều máy. Không IP công khai. `"127.0.0.1"` |
| [[process]] | `port` | cổng 1–65535 (0 chỉ khi host là 127.0.0.1); 1 – 65535 (0 khi host = 127.0.0.1) | bắt buộc | Cổng ipc nội bộ. | Cổng cố định không trùng; 0 chỉ khi host là 127.0.0.1 (test). `7020` |

### gate.toml

Bộ đọc: `config::read_gate (gate.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| (gốc) | `identity_key_file` | chuỗi; 1 – 512 byte, không ký tự điều khiển | bắt buộc | Khoá danh tính của máy chủ; mất là client phải cài lại. | Sao lưu an toàn, không đưa vào git. Công cụ không mở tệp này. `"../data/gate/identity.key"` |
| (gốc) | `trusted_proxies` | mảng địa chỉ IPv4 | bắt buộc | Proxy được tin để đọc IP thật của client; rỗng là không có. | Chỉ điền IP proxy/LB của mình; điền sai là cho kẻ gian giả IP. `[]` |
| [listen] | `game` | "a.b.c.d:cổng" (cổng 0 chỉ với 127.0.0.1) | bắt buộc | Cổng chơi game: client đã có vé nối vào đây. | "0.0.0.0:7000" hoặc IP công khai cụ thể. `"0.0.0.0:7000"` |
| [listen] | `auth` | "a.b.c.d:cổng" (cổng 0 chỉ với 127.0.0.1) | bắt buộc | Cổng xác thực: đăng ký, đăng nhập lấy vé. | "0.0.0.0:7001". `"0.0.0.0:7001"` |
| [limits] | `max_connections` | số nguyên; 1 – 2147483647 | bắt buộc | Tổng số kết nối client cùng lúc. | ≈ 1,2 × số người online dự kiến. `5000` |
| [limits] | `per_ip_connections` | số nguyên; 1 – 2147483647 | bắt buộc | Số kết nối cùng lúc từ một địa chỉ IP (hoặc một dải, xem per_ip_prefix). | 4–8 với /32; tăng nếu nhiều người chung NAT. `8` |
| [limits] | `handshake_timeout_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Hạn xong bắt tay bảo mật; quá hạn thì ngắt. | 3000–5000. `5000` |
| [limits] | `idle_timeout_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Hạn im lặng sau bắt tay; quá hạn thì ngắt. | 10000–30000. `15000` |
| [limits] | `client_frame_bytes` | số nguyên; 1 – 2147483647; đơn vị byte | bắt buộc | Số byte tối đa của thân một tin từ client. | Giữ 4096 trừ khi protocol đổi. `4096` |
| [limits] | `messages_per_second` | số nguyên; 1 – 2147483647 | bắt buộc | Số tin tối đa mỗi giây của một client; vượt thì ngắt. | 40–60. `60` |
| [limits] | `per_ip_prefix` | số nguyên; 16 – 32 | tuỳ chọn (mặc định 32) | Gom trần per_ip_connections theo dải /N (32 = từng IP, 24 = cả dải /24). | 32 mặc định; 24 khi bị tấn công từ cả dải. `32` |
| [client] | `min_version` | số nguyên; 1 – 2147483647 | bắt buộc | Phiên bản protocol thấp nhất được vào; thấp hơn bị từ chối. | Nâng khi phát hành client bắt buộc cập nhật. `1` |
| [ip_filter] | `allow` | mảng dải CIDR IPv4 "a.b.c.d/n" | bắt buộc | Dải được nối; rỗng là mọi địa chỉ đều được nối. | Thường rỗng; dùng khi chỉ mở cho LAN/khu vực. `[]` |
| [ip_filter] | `deny` | mảng dải CIDR IPv4 "a.b.c.d/n" | bắt buộc | Dải bị từ chối; xét trước allow. | Thêm dải đang tấn công. `[]` |
| [resume] | `bind_to_ip` | true/false | tuỳ chọn (mặc định true) | true: Resume từ IP khác IP đã vào game thì huỷ phiên (token coi như lộ). | true; tắt chỉ khi người chơi di động hay đổi mạng. `true` |
| [resume] | `grace_ms` | số nguyên; 0 – 300000; đơn vị mili giây | tuỳ chọn (mặc định 30000) | Phiên rớt mạng chờ Resume bao lâu; 0 là tắt Resume. | 15000–30000. `30000` |

### log.toml

Bộ đọc: `config::read_log (log.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| (gốc) | `audit` | true/false | bắt buộc | true: ghi thêm log thống kê và kiểm toán. | Production: true. `true` |
| (gốc) | `play_trace` | true/false | tuỳ chọn (mặc định false) | true: zone ghi một dòng kiểm cho mỗi việc của người chơi (dev/server/README.md). | Production: false; dev: true. `false` |
| [file] | `dir` | chuỗi; 1 – 512 byte, không ký tự điều khiển | bắt buộc | Thư mục chứa tệp log; mỗi tiến trình một tệp. | Ổ có đủ chỗ, có dọn định kỳ. `"../log"` |
| [file] | `rotate_mb` | số nguyên; 1 – 2147483647; đơn vị MB | bắt buộc | Tệp log lớn quá số MB này thì mở tệp mới. | 64–256. `128` |
| [level] | `default` | một trong tập giá trị; error | warn | info | debug | bắt buộc | Mức log mặc định: error, warn, info, debug (ít tới nhiều). | Production: info; debug chỉ khi điều tra lỗi. `"info"` |

### secrets.example.toml

Bộ đọc: `config::read_secrets (secrets.cpp)`. Tệp mẫu: mật khẩu luôn xuất ra rỗng.

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [database.postgres] | `password` | chuỗi; 0 – 256 byte, không ký tự điều khiển | bắt buộc | Mật khẩu của role postgres. **Bí mật: không bao giờ hiển thị/xuất giá trị.** | Không ghi mật khẩu thật vào tệp mẫu. Tệp thật secrets.local.toml do setup_db.py sinh và không bao giờ được mở bởi công cụ. `""` |
| [database.thienlong_auth] | `password` | chuỗi; 0 – 256 byte, không ký tự điều khiển | bắt buộc | Mật khẩu của role thienlong_auth. **Bí mật: không bao giờ hiển thị/xuất giá trị.** | Không ghi mật khẩu thật vào tệp mẫu. Tệp thật secrets.local.toml do setup_db.py sinh và không bao giờ được mở bởi công cụ. `""` |
| [database.thienlong_billing] | `password` | chuỗi; 0 – 256 byte, không ký tự điều khiển | bắt buộc | Mật khẩu của role thienlong_billing. **Bí mật: không bao giờ hiển thị/xuất giá trị.** | Không ghi mật khẩu thật vào tệp mẫu. Tệp thật secrets.local.toml do setup_db.py sinh và không bao giờ được mở bởi công cụ. `""` |
| [database.thienlong_store] | `password` | chuỗi; 0 – 256 byte, không ký tự điều khiển | bắt buộc | Mật khẩu của role thienlong_store. **Bí mật: không bao giờ hiển thị/xuất giá trị.** | Không ghi mật khẩu thật vào tệp mẫu. Tệp thật secrets.local.toml do setup_db.py sinh và không bao giờ được mở bởi công cụ. `""` |

### store.toml

Bộ đọc: `config::read_store (store.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [database] | `name` | tên định danh (chữ cái đầu, rồi chữ, số, _ hoặc -; tối đa 63) | bắt buộc | Tên database PostgreSQL mà tiến trình nối tới. | Giữ đúng tên do setup_db.py tạo; đổi tên phải đổi cả database thật. `"thienlong_game_1"` |
| [database] | `user` | tên định danh (chữ cái đầu, rồi chữ, số, _ hoặc -; tối đa 63) | bắt buộc | Role PostgreSQL dùng để nối; chỉ có quyền trên database này. | Mỗi dịch vụ một role riêng, không dùng role postgres. Mật khẩu nằm ở secrets.local.toml. `"thienlong_store"` |
| [database] | `pool` | số nguyên; 1 – 2147483647 | bắt buộc | Số kết nối giữ sẵn tới database. | Bắt đầu 2–8; tăng khi đo thấy hàng chờ truy vấn. Tổng pool mọi tiến trình phải nhỏ hơn max_connections của PostgreSQL. `4` |
| [flush] | `character_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Thay đổi thường của nhân vật (vị trí, kinh nghiệm) nằm trong bộ nhớ tối đa bao lâu. | 10000–30000; nhỏ hơn thì sập mất ít hơn nhưng ghi đĩa nhiều hơn. `15000` |
| [flush] | `world_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Thay đổi của dữ liệu world (bang, thư, xếp hạng) nằm trong bộ nhớ tối đa bao lâu. | 30000–60000. `30000` |
| [journal] | `dir` | chuỗi; 1 – 512 byte, không ký tự điều khiển | bắt buộc | Thư mục chứa nhật ký ghi trước (chống mất dữ liệu khi sập). | Ổ SSD, cùng máy với store, có sao lưu. `"../data/store/journal"` |
| [security] | `standing_cache_ms` | số nguyên; 0 – 10000; đơn vị mili giây | tuỳ chọn (mặc định 1000) | Store nhớ câu trả lời "còn được chơi" của auth chừng này; là cửa sổ tối đa sau khi ban. | 1000; 0 là mỗi lệnh đều hỏi auth. `1000` |
| [security] | `name_reserve_days` | số nguyên; 0 – 3650; đơn vị ngày | tuỳ chọn (mặc định 30) | Tên nhân vật xoá mềm giữ chỗ cho chủ cũ chừng này ngày. | 7–30. `30` |
| [security] | `female_faces` | mảng số nguyên, không lặp; phần tử 0 – 65534; 1 – 256 phần tử | tuỳ chọn (mặc định [1, 2, 3, 4, 5, 14]) | Id mặt nữ tạo được (creatable = 1 trong faces.tsv). | Khớp bảng client. `[1, 2, 3, 4, 5, 14]` |
| [security] | `male_faces` | mảng số nguyên, không lặp; phần tử 0 – 65534; 1 – 256 phần tử | tuỳ chọn (mặc định [100, 101, 102, 103, 104, 113]) | Id mặt nam tạo được. | Khớp bảng client. `[100, 101, 102, 103, 104, 113]` |
| [security] | `female_hairs` | mảng số nguyên, không lặp; phần tử 0 – 65534; 1 – 256 phần tử | tuỳ chọn (mặc định [1, 17, 19]) | Id tóc nữ tạo được (creatable = 1 trong hairs.tsv). | Khớp bảng client. `[1, 17, 19]` |
| [security] | `male_hairs` | mảng số nguyên, không lặp; phần tử 0 – 65534; 1 – 256 phần tử | tuỳ chọn (mặc định [5, 12, 14]) | Id tóc nam tạo được. | Khớp bảng client. `[5, 12, 14]` |

### supervisor.toml

Bộ đọc: `config::read_supervisor (supervisor.cpp) + config::check_startup (startup.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [postgres] | `managed` | true/false | bắt buộc | true: trình giám sát tự chạy và dừng cụm PostgreSQL. | true khi PostgreSQL cùng máy; false khi dùng cụm riêng. `true` |
| [postgres] | `ready_timeout_seconds` | số nguyên; 0 – 2147483647; đơn vị giây | bắt buộc | Chờ cụm sẵn sàng tối đa bao nhiêu giây. | 60–120. `90` |
| [restart] | `max_per_hour` | số nguyên; 0 – 2147483647 | bắt buộc | Số lần chạy lại tối đa mỗi giờ cho một tiến trình. | 3–5; vượt thì dừng hẳn để người vận hành xem. `3` |
| [stop] | `timeout_seconds` | số nguyên; 0 – 2147483647; đơn vị giây | bắt buộc | Chờ một tiến trình tự thoát tối đa bao nhiêu giây rồi mới buộc dừng. | ≥ 30 để store kịp ép dữ liệu xuống đĩa. `60` |
| [[start]] | `process` | một trong tập giá trị; store | auth | billing | world | zone | gate | bắt buộc | Tiến trình chạy ở bước này. | Thứ tự chuẩn: store, auth, billing, world, zone, gate; không lặp. `"store"` |
| [[start]] | `ready_timeout_seconds` | số nguyên; 0 – 2147483647; đơn vị giây | bắt buộc | Chờ sẵn sàng tối đa bao nhiêu giây. | 60 (store/gate) tới 240 (zone). `60` |

### world.toml

Bộ đọc: `config::read_world (world.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [capacity] | `online_users` | số nguyên; 1 – 2147483647 | bắt buộc | Số người chơi online cùng lúc. | ≥ max_connections của gate. `5000` |
| [capacity] | `mail_users` | số nguyên; 1 – 2147483647 | bắt buộc | Số người chơi có thư đang giữ trong bộ nhớ. | ≈ 10 × online. `52000` |
| [capacity] | `offline_cache` | số nguyên; 1 – 2147483647 | bắt buộc | Số người đã thoát còn giữ thông tin trong bộ nhớ. | ≈ 10 × online. `50000` |
| [capacity] | `speakers` | số nguyên; 1 – 2147483647 | bắt buộc | Số tin loa thế giới giữ trong hàng chờ phát. | 128. `128` |
| [capacity] | `pet_friend_ads` | số nguyên; 1 – 2147483647 | bắt buộc | Số tin tìm bạn cho trân thú giữ cùng lúc. | 1024. `1024` |
| [player_count_report] | `hours` | mảng giờ 0–23, không lặp, tối đa 24; 0 – 23; tối đa 24 phần tử | bắt buộc | Các giờ trong ngày ghi log số người ở từng cảnh. | Giờ cao điểm, ví dụ [13, 15, 21]. `[13, 15, 21]` |
| [notice] | `join_guild` | true/false | bắt buộc | true: báo lên kênh hệ thống khi có người vào bang. | Tuỳ ý. `false` |
| [platform] | `pc_meets_mobile` | true/false | bắt buộc | true: người PC nhìn thấy người điện thoại. | Theo chính sách phát hành (chung hay tách máy chủ PC/mobile). `true` |

### zone.toml

Bộ đọc: `config::read_zone (zone.cpp)`. 

| Nhóm | Khoá | Kiểu / miền | Bắt buộc | Chức năng | Cách đặt cho production (gợi ý) |
|---|---|---|---|---|---|
| (gốc) | `schema` | số nguyên, đúng bằng 1; 1 – 1 | bắt buộc | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu. | Luôn để 1. Không sửa. `1` |
| [tick] | `hz` | số nguyên; 1 – 2147483647 | bắt buộc | Số bước mô phỏng mỗi giây; 20 là mỗi bước 50 mili giây. | 20; không đổi nếu chưa đo. `20` |
| [aoi] | `cell_size` | số nguyên; 1 – 2147483647 | bắt buộc | Cạnh một ô vùng nhìn, tính bằng đơn vị cảnh. | 10. `10` |
| [capacity] | `monsters` | số nguyên; 1 – 2147483647 | bắt buộc | Quái và NPC tối đa. | ≥ tổng spawn của mọi cảnh. `49000` |
| [capacity] | `pets` | số nguyên; 1 – 2147483647 | bắt buộc | Trân thú đang được gọi ra tối đa. | ≈ 0,7 × online. `3000` |
| [capacity] | `special_objects` | số nguyên; 1 – 2147483647 | bắt buộc | Bẫy và vùng hiệu ứng. | 1024. `1024` |
| [capacity] | `platforms` | số nguyên; 1 – 2147483647 | bắt buộc | Bàn chế tác của kỹ năng sống. | 1024. `1024` |
| [capacity] | `buses` | số nguyên; 1 – 2147483647 | bắt buộc | Xe chở khách. | 1024. `1024` |
| [capacity] | `player_shops` | số nguyên; 1 – 2147483647 | bắt buộc | Cửa hàng do người chơi mở. | 256. `256` |
| [capacity] | `scene_timers` | số nguyên; 1 – 2147483647 | bắt buộc | Bộ hẹn giờ của cảnh. | 64. `64` |
| [capacity] | `human_timers` | số nguyên; 1 – 2147483647 | bắt buộc | Bộ hẹn giờ mỗi người chơi được dùng. | 3. `3` |
| [session] | `linger_after_disconnect_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Nhân vật ở lại cảnh bao lâu sau khi rớt mạng. | 20000 (≥ grace_ms của gate là tốt). `30000` |
| [session] | `linger_hidden_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Ở lại thêm bao lâu sau khi đã bị ẩn khỏi cảnh. | 20000. `20000` |
| [session] | `kick_idle_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Client không phản hồi quá lâu thì bị đá. | 300000 (5 phút). `300000` |
| [world_clock] | `period_change_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Một canh giờ trong game dài bao nhiêu mili giây thật. | 150000. `150000` |
| [drops] | `box_recycle_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Gói đồ không ai nhặt biến mất sau bao lâu. | 60000. `60000` |
| [audit] | `packet_stats_ms` | số nguyên; 0 – 2147483647; đơn vị mili giây | bắt buộc | Chu kỳ ghi thống kê tin mạng; 0 là không thống kê. | 0 hoặc 60000 khi theo dõi tải. `0` |

## Tệp luật (config/rules/*.toml)

Bộ đọc: `config::read_loose` (loose.cpp) qua thienlong_lint: chỉ kiểm cú pháp TOML và `schema = 1`; khoá khác chưa có struct C++ nên không bị coi là lạ. Giá trị do mã zone/world chép vào hằng số (xem chú thích trong src/server/social/limits.hpp, item/price.hpp, account/starter.hpp). Chức năng dưới đây lấy từ chú thích trong chính tệp; "Đơn vị chưa xác lập" nghĩa là mã gốc chưa rõ đơn vị: giữ nguyên giá trị nếu chưa đo.

### rules/character.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| human | `can_get_exp_range` | `60` | số nguyên | Phạm vi nhận kinh nghiệm. Đơn vị chưa xác lập. |
| human | `out_ghost_time_ms` | `300000` | số nguyên | Thời gian ở dạng hồn; mã đưa vào bộ hẹn giờ. |
| human | `default_move_speed` | `4000` | số nguyên | Tốc độ đi mặc định, mã chia cho 1000. Đơn vị chưa xác lập. |
| human | `default_attack_speed` | `2000` | số nguyên | Chỉ được nạp, không chỗ nào đọc. Đơn vị chưa xác lập. |
| human | `vigor_recover_interval_ms` | `300000` | số nguyên | Nhịp hồi hoạt lực và tinh lực, mili giây. |
| human | `max_level` | `120` | số nguyên | Cấp tối đa theo kinh nghiệm; cấp thật bằng giá trị trừ 1. |
| human | `pk_value_refresh_seconds` | `3600` | số nguyên | Nhịp giảm sát khí, giây. |
| human | `pilfer_lock_time` | `1000` | số nguyên | Khoá an toàn, gốc ghi (毫少). Đơn vị chưa xác lập. |
| human | `inner_art_max_level` | `120` | số nguyên | Cấp tối đa của tâm pháp. |
| human | `level_up_captcha_min` | `0` | số nguyên | Cấp nhỏ nhất phải xác minh hình khi lên cấp. |
| human | `level_up_captcha_max` | `0` | số nguyên | Cấp lớn nhất phải xác minh hình khi lên cấp. |
| human | `min_level_ingot_voucher` | `30` | số nguyên | Cấp nhỏ nhất để nhận ingot voucher. |
| exp | `factor_permille` | `1000` | số nguyên | Hệ số kinh nghiệm toàn cục. |
| exp | `spouse_permille` | `40` | số nguyên | Cộng thêm khi trong đội có vợ hoặc chồng. |
| exp | `brother_permille` | `20` | số nguyên | Cộng thêm khi trong đội có huynh đệ. |
| exp | `master_in_team_permille` | `200` | số nguyên | Cộng thêm khi sư phụ có trong đội. |
| exp | `master_absent_permille` | `100` | số nguyên | Cộng thêm khi có sư phụ nhưng không trong đội. |
| exp | `prentice_permille` | `50` | số nguyên | Cộng kinh nghiệm sau khi nhận đồ đệ. |
| exp | `hidden_weapon_absorb_permille` | `10` | số nguyên | Tỉ lệ ám khí hút kinh nghiệm. |
| life_skill | `assistant_demand_param` | `[1514, 19000, 200, 37100]` | mảng | Bốn tham số giảm tiêu hao kỹ năng phụ, theo thứ tự. |

### rules/combat.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| damage | `pk_modifier` | `100` | số nguyên | Chú thích gốc nói sát thương khi PK giảm một nửa. Đơn vị chưa xác lập. |
| damage | `default_fluctuation` | `8` | số nguyên | Dao động sát thương mặc định. |
| hit | `h0` | `10` | số nguyên | Tham số H0 của công thức trúng đích. |
| critical | `c0` | `100` | số nguyên | Tham số C0 của công thức chí mạng. |
| critical | `c1` | `10` | số nguyên | Tham số C1 của công thức chí mạng. |
| critical | `c2` | `25` | số nguyên | Tham số C2 của công thức chí mạng. |
| limit | `raw_attribute` | `10000000000` | số nguyên | Trần điểm thuộc tính chiến đấu gốc. |
| limit | `item_attribute` | `32767` | số nguyên | Trần trị tuyệt đối của một dòng thuộc tính vật phẩm. |
| limit | `single_settlement` | `2147483647` | số nguyên | Trần lượng kết toán một lần, máu hoặc nội lực. |
| limit | `critical_display` | `9999` | số nguyên | Trần điểm chí mạng hiển thị, không phải phần trăm. |
| limit | `hit_formula` | `100000` | số nguyên | Trần điểm trúng và né trước khi vào công thức. |
| limit | `resistance` | `4096` | số nguyên | Trần điểm kháng bốn hệ và giảm kháng. |
| limit | `effective_resistance` | `100` | số nguyên | Trần kháng hiệu dụng; mỗi điểm giảm một phần trăm. |

### rules/economy.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| player_shop | `hourly_fee` | `0` | số nguyên | Tiền trừ thêm mỗi giờ của cửa hàng. |
| price | `identified_sale_permille` | `250` | số nguyên | Hệ số giá bán đồ thường và đồ đã giám định. |
| price | `unidentified_sale_permille` | `100` | số nguyên | Hệ số giá bán đồ lam chưa giám định. |
| price | `new_server_permille` | `1000` | số nguyên | Hệ số giá hoạt động máy chủ mới. |
| voucher | `ingot_cap` | `100000` | số nguyên | Trần ingot trong một phiếu quan. |
| voucher | `enabled` | `true` | true/false | Bật đổi phiếu ingot. |
| exchange | `min_level` | `14` | số nguyên | Cấp thấp nhất phải nhập mã khi giao dịch. |
| exchange | `max_level` | `25` | số nguyên | Cấp cao nhất phải nhập mã khi giao dịch. |
| consignment | `return_minutes` | `360` | số nguyên | Số phút không bán được thì trả lại. |
| consignment | `ingot_fee_percent` | `2` | số nguyên | Phí ký gửi ingot, phần trăm. |
| consignment | `coin_fee_percent` | `2` | số nguyên | Phí ký gửi tiền vàng, phần trăm. |
| consignment | `ingot_option` | `[50, 200, 500]` | mảng | Mệnh giá ingot đưa ra khi ký gửi. |
| consignment | `coin_option` | `[100000, 500000, 1500000]` | mảng | Mệnh giá tiền vàng đưa ra khi ký gửi. |
| consignment | `close_ingot` | `false` | true/false | Đóng chức năng ký gửi ingot. |
| consignment | `close_coin` | `false` | true/false | Đóng chức năng ký gửi tiền vàng. |
| card | `activate_588` | `false` | true/false | Kích hoạt thẳng thẻ 588. |
| card | `activate_666` | `false` | true/false | Kích hoạt thẳng thẻ 666. |
| closure | `breed` | `[7040400, 7040400]` | mảng | Mốc đóng rồi mở phối giống, dạng năm tháng ngày giờ. |
| closure | `found_guild` | `[0, 0]` | mảng | Mốc đóng rồi mở lập bang, dạng năm tháng ngày giờ. |
| closure | `found_city` | `[0, 0]` | mảng | Mốc đóng rồi mở lập thành, dạng năm tháng ngày giờ. |
| closure | `player_shop` | `[0, 0]` | mảng | Mốc đóng rồi mở cửa hàng, dạng năm tháng ngày giờ. |
| closure | `consignment` | `[0, 0]` | mảng | Mốc đóng rồi mở ký gửi, dạng năm tháng ngày giờ. |
| closure | `voucher_exchange` | `[0, 0]` | mảng | Mốc đóng rồi mở đổi phiếu, dạng năm tháng ngày giờ. |
| closure | `voucher_use` | `[0, 0]` | mảng | Mốc đóng rồi mở dùng phiếu, dạng năm tháng ngày giờ. |

### rules/fatigue.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| fatigue | `enabled` | `true` | true/false | Bật trạng thái mệt. |
| fatigue | `mild_seconds` | `10800` | số nguyên | Số giây online thì vào mệt nhẹ. |
| fatigue | `severe_seconds` | `18000` | số nguyên | Số giây online thì vào mệt nặng. |
| captcha | `enabled` | `false` | true/false | Bật câu hỏi chống treo máy. |

### rules/global.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| drop | `drop_factor_permille` | `1000` | số nguyên | Hệ số sửa tỉ lệ rơi đồ toàn cục. |
| durability | `equipment_damage_point` | `500` | số nguyên | Điểm trừ độ bền trang bị. |
| respawn | `respawn_factor_permille` | `1000` | số nguyên | Hệ số thời gian quái xuất hiện lại. |
| revive | `max_level` | `20` | số nguyên | Cấp tối đa được hồi sinh tại chỗ. |
| pet_guard | `auto_remove_bad` | `true` | true/false | Bật thì tự gỡ trân thú lỗi. |
| language | `language` | `1` | số nguyên | Mã ngôn ngữ: 0 Anh, 1 Trung giản thể, 2 Trung phồn thể, 3 Hàn, 4 Việt. |
| rolling_notice | `declared_count` | `0` | số nguyên | Số lượng thông báo. |
| rolling_notice | `interval` | `300000` | số nguyên | Khoảng cách giữa hai lần phát. Đơn vị chưa xác lập. |
| scheduled_event | `declared_count` | `0` | số nguyên | Số lượng hoạt động. |

### rules/guild.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| guild | `initial_member_cap` | `60` | số nguyên | Trần thành viên lúc mới lập bang. |
| guild | `city_cost` | `10000000` | số nguyên | Tiền lập thành. |
| guild | `message_cost` | `1000` | số nguyên | Phí một lời nhắn bang. |
| guild | `battle_time` | `120` | số nguyên | Thời lượng tuyên chiến bang. |
| guild | `leave_buff` | `false` | true/false | Bật hiệu ứng khi rời bang. |
| guild | `trade_guard` | `true` | true/false | Bật chống gian lận chạy thương. |
| guild | `fix_county_level` | `true` | true/false | Sửa cấp nha môn lúc nạp bang. |
| county_office | `max_user` | `[70, 80, 90, 100, 110]` | mảng | Trần dân số nha môn, cấp 1 đến 5. |
| county_office | `standard_money` | `[1666667, 3333333, 6666667, 13333333, 26666667]` | mảng | Quỹ chuẩn của nha môn, cấp 1 đến 5. |
| county_office | `max_money` | `[10000000, 20000000, 40000000, 60000000, 80000000]` | mảng | Trần quỹ nha môn, cấp 1 đến 5. |
| county_office | `max_trader` | `[8, 9, 10, 11, 12]` | mảng | Trần thương nhân nha môn, cấp 1 đến 5. |
| bank | `delta_money` | `[833333, 1666667, 3333333, 6666667, 13333333]` | mảng | Lệch quỹ tiền trang theo cấp nha môn. |
| guest_wing | `max_user` | `[30, 50, 80, 120, 150]` | mảng | Trần dân số sương phòng, cấp 1 đến 5. |
| prosperity | `cap` | `999` | số nguyên | Trần phồn vinh của bang. |
| prosperity | `expand_permille` | `400` | số nguyên | Trọng số phồn vinh của mở rộng. |
| prosperity | `agriculture_permille` | `1600` | số nguyên | Trọng số phồn vinh của nông nghiệp. |
| prosperity | `commerce_permille` | `1600` | số nguyên | Trọng số phồn vinh của thương mại. |
| prosperity | `defence_permille` | `800` | số nguyên | Trọng số phồn vinh của phòng thủ. |
| prosperity | `industry_permille` | `1600` | số nguyên | Trọng số phồn vinh của công nghiệp. |
| prosperity | `technology_permille` | `800` | số nguyên | Trọng số phồn vinh của kỹ thuật. |
| prosperity | `ticket_decay` | `136` | số nguyên | Độ giảm thương phiếu của bang mới. |
| league | `max_count` | `255` | số nguyên | Trần số liên minh một thế giới xin được. |
| league | `rejoin_hours` | `72` | số nguyên | Số giờ sau khi rời liên minh mới xin lại. |
| league | `create_cost` | `1000000` | số nguyên | Tiền lập liên minh. |

### rules/hidden_weapon.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| quality | `default_grow_rate` | `[874, 100, 20, 5, 1]` | mảng | Năm bậc tăng trưởng hạng mặc định, mẫu số 1000. |
| quality | `low_grow_rate` | `[738, 200, 50, 10, 2]` | mảng | Năm bậc tăng trưởng hạng thấp, mẫu số 1000. |
| quality | `high_grow_rate` | `[0, 875, 100, 20, 5]` | mảng | Năm bậc tăng trưởng hạng cao, mẫu số 1000. |

### rules/instances.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| instance | `group_count` | `2` | số nguyên | Số nhóm phó bản trong hệ thống. |
| instance | `id` | `[0, 1]` | mảng | Số hiệu phó bản. |
| instance | `max_scene_count` | `[56, 56]` | mảng | Số cảnh tối đa của nhóm phó bản. |

### rules/monster.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| monster | `default_position_range` | `10` | số nguyên | Phạm vi sinh lại mặc định. |
| monster | `body_time_ms` | `5000` | số nguyên | Thời gian giữ xác quái thường, mili giây. |
| monster | `boss_body_time_ms` | `60000` | số nguyên | Thời gian giữ xác quái cao cấp, mili giây. |
| monster | `change_target_odds` | `20` | số nguyên | Xác suất đổi mục tiêu tấn công. |
| monster | `attack_assistant_odds` | `16` | số nguyên | Xác suất đánh kẻ hỗ trợ. |
| monster | `change_target_cooldown_seconds` | `3` | số nguyên | Hồi đổi mục tiêu, giây. |
| monster | `max_level` | `200` | số nguyên | Cấp tối đa của quái. |
| income | `reduced_income_count` | `30000` | số nguyên | Số quái thì thu nhập bị giảm. |
| income | `no_income_count` | `60000` | số nguyên | Số quái thì thu nhập về không. |
| income | `reduced_income_permille` | `500` | số nguyên | Phần thu nhập còn lại khi bị giảm. |

### rules/new_character.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| profile | `name` | `"天龙八部"` | chuỗi | Tên nhân vật mới. |
| profile | `scene` | `2` | số nguyên | Cảnh bắt đầu. |
| profile | `position_x` | `165.0` | số thực | Hoành độ lúc vào game. |
| profile | `position_z` | `169.0` | số thực | Tung độ lúc vào game. |
| profile | `sex` | `0` | số nguyên | Giới tính. |
| profile | `hp` | `999` | số nguyên | Máu ban đầu. |
| profile | `mp` | `999` | số nguyên | Nội lực ban đầu. |
| profile | `level` | `1` | số nguyên | Cấp ban đầu. |
| profile | `exp` | `0` | số nguyên | Kinh nghiệm ban đầu. |
| profile | `camp` | `0` | số nguyên | Giá trị camp. |
| profile | `sect` | `9` | số nguyên | Môn phái ban đầu. |
| profile | `money` | `0` | số nguyên | Tiền ban đầu. |
| profile | `actual_age` | `18` | số nguyên | Tuổi thật, dùng cho chống nghiện. |
| profile | `motto` | `"这家伙很懒，什么都没留下！"` | chuỗi | Câu chữ mặc định của nhân vật mới. |
| vigor | `vigor` | `10` | số nguyên | Hoạt lực ban đầu. |
| vigor | `max_vigor` | `50` | số nguyên | Hoạt lực tối đa. |
| vigor | `regenerate` | `0` | số nguyên | Tốc độ hồi hoạt lực. |
| energy | `energy` | `10` | số nguyên | Tinh lực ban đầu. |
| energy | `max_energy` | `50` | số nguyên | Tinh lực tối đa. |
| energy | `regenerate` | `0` | số nguyên | Tốc độ hồi tinh lực. |
| attribute | `strength` | `7` | số nguyên | Điểm thuộc tính ban đầu: sức mạnh. basis Common/GameDefine_Attr.h:10. |
| attribute | `spirit` | `6` | số nguyên | Điểm thuộc tính ban đầu: linh khí. basis Common/GameDefine_Attr.h:11. |
| attribute | `constitution` | `5` | số nguyên | Điểm thuộc tính ban đầu: thể chất. basis Common/GameDefine_Attr.h:12. |
| attribute | `intellect` | `5` | số nguyên | Điểm thuộc tính ban đầu: định lực. basis Common/GameDefine_Attr.h:13. |
| attribute | `dexterity` | `2` | số nguyên | Điểm thuộc tính ban đầu: thân pháp. basis Common/GameDefine_Attr.h:14. |
| skill | `count` | `6` | số nguyên | Số kỹ năng được dùng. |
| skill | `id` | `[0, 1, 21, 22, 34, 35]` | mảng | Id kỹ năng ban đầu. |
| inner_art | `count` | `0` | số nguyên | Số tâm pháp ban đầu. |
| life_skill | `count` | `5` | số nguyên | Số kỹ năng sống ban đầu. |
| life_skill | `id` | `[1, 26, 38, 50, 51]` | mảng | Id kỹ năng sống ban đầu. |
| life_skill | `level` | `[1, 1, 1, 1, 1]` | mảng | Cấp kỹ năng sống ban đầu. |
| life_skill | `exp` | `[0, 0, 0, 0, 0]` | mảng | Kinh nghiệm kỹ năng sống ban đầu. |
| recipe | `count` | `4` | số nguyên | Số công thức đã học. |
| recipe | `id` | `[398, 558, 559, 560]` | mảng | Id công thức ban đầu. |
| setting | `count` | `6` | số nguyên | Số thiết lập ban đầu. |
| setting | `index` | `[2, 8, 9, 10, 11, 1]` | mảng | Chỉ số thiết lập. |
| setting | `type` | `[1, 1, 1, 2, 1, 0]` | mảng | Loại thiết lập. |
| setting | `data` | `[0, 22, 35, 1, 1, 4]` | mảng | Giá trị thiết lập. |
| start_position | `scene_count` | `3` | số nguyên | Giá trị scenecount. |
| start_position | `scene` | `[2, 71, 72]` | mảng | Id cảnh của một điểm xuất phát. |
| start_position | `position_x` | `[165.0, 165.0, 165.0]` | mảng | Hoành độ của một điểm xuất phát. |
| start_position | `position_z` | `[169.0, 169.0, 169.0]` | mảng | Tung độ của một điểm xuất phát. |

### rules/pet.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| life | `happiness_interval_ms` | `600000` | số nguyên | Nhịp giảm vui vẻ một điểm, mili giây. |
| life | `life_interval_ms` | `600000` | số nguyên | Nhịp giảm tuổi thọ một lần, mili giây. |
| life | `life_loss_step` | `7` | số nguyên | Điểm tuổi thọ mất mỗi nhịp. |
| life | `summon_happiness` | `60` | số nguyên | Vui vẻ tối thiểu để gọi ra. |
| friend_ad | `duration_ms` | `1800000` | số nguyên | Thời gian một tin tìm bạn, mili giây. |
| friend_ad | `min_level` | `30` | số nguyên | Cấp tối thiểu để đăng tin tìm bạn. |
| friend_ad | `min_happiness` | `100` | số nguyên | Vui vẻ tối thiểu để đăng tin tìm bạn. |
| friend_ad | `min_life` | `3000` | số nguyên | Tuổi thọ tối thiểu để đăng tin tìm bạn. |
| level | `max_level` | `125` | số nguyên | Cấp tối đa trân thú lên bằng kinh nghiệm. |
| death | `life_loss_permille` | `400` | số nguyên | Hệ số tuổi thọ mất khi quái giết. |
| birth | `baby_rate_permille` | `30` | số nguyên | Xác suất ra thú non, mẫu số 1000. |
| birth | `mutant_rate_permille` | `7` | số nguyên | Xác suất ra thú đột biến, mẫu số 1000. |
| wild_level | `take_level_weight` | `60` | số nguyên | Trọng số giữ đúng cấp mang của thú dại. |
| wild_level | `level_delta` | `[10, 5, 5]` | mảng | Trọng số lệch cấp của thú dại, lệch 1 đến 3. |
| growth | `other_grow_rate` | `[887, 100, 10, 2, 1]` | mảng | Năm bậc tăng trưởng mặc định, mẫu số 1000. |
| growth | `wild_grow_rate` | `[832, 100, 50, 13, 5]` | mảng | Năm bậc tăng trưởng thú dại trưởng thành, mẫu số 1000. |
| growth | `paid_grow_rate` | `[0, 598, 359, 36, 7]` | mảng | Năm bậc tăng trưởng thú trả phí thường, mẫu số 1000. |
| growth | `show_grow_rate` | `[0, 0, 906, 75, 19]` | mảng | Năm bậc tăng trưởng thú trả phí khoe, mẫu số 1000. |
| bone | `span_begin` | `[700, 800, 900, 1000, 1100]` | mảng | Đầu dải cốt cách, năm mức. |
| bone | `span_end` | `[800, 900, 1000, 1100, 1200]` | mảng | Cuối dải cốt cách, năm mức. |
| bone | `span_weight` | `[10, 25, 35, 25, 5]` | mảng | Trọng số năm dải cốt cách, tổng 100. |
| mutant_level | `extra_weight` | `[19255, 27068, 18668, 12874, 8878, 6123, 4222, 2912]` | mảng | Trọng số, cấp 1 đến 8, mẫu 100000. |
| aptitude_range | `span` | `50` | số nguyên | Biên độ tư chất lúc sinh. |
| speed | `move_permille` | `3500` | số nguyên | Tốc độ đi, chú thích ghi mẫu số 1000. |
| speed | `attack_permille` | `2000` | số nguyên | Tốc độ đánh, chú thích ghi mẫu số 1000. |
| ai | `magic_rate` | `[15, 75, 30, 40]` | mảng | Tỉ lệ phép của bốn kiểu AI. |
| base | `hp` | `44` | số nguyên | Máu gốc. |
| base | `physical_attack` | `50` | số nguyên | Vật công gốc. |
| base | `magic_attack` | `50` | số nguyên | Phép công gốc. |
| base | `physical_defence` | `12` | số nguyên | Vật phòng gốc. |
| base | `magic_defence` | `12` | số nguyên | Phép phòng gốc. |
| base | `hit` | `16` | số nguyên | Độ trúng gốc. |
| base | `dodge` | `5` | số nguyên | Độ né gốc. Bản gốc ghi Miss. |
| base | `critical_attack` | `6` | số nguyên | Chí mạng tấn công gốc. |
| base | `critical_defence` | `6` | số nguyên | Chí mạng phòng thủ gốc. |
| factor | `constitution_hp_permille` | `18000` | số nguyên | Hệ số thể chất lên máu, mã chia 1000. |
| factor | `strength_physical_attack_permille` | `11000` | số nguyên | Hệ số sức mạnh lên vật công, mã chia 1000. |
| factor | `spirit_magic_attack_permille` | `11000` | số nguyên | Hệ số linh khí lên phép công, mã chia 1000. |
| factor | `constitution_physical_defence_permille` | `10800` | số nguyên | Hệ số thể chất lên vật phòng, mã chia 1000. |
| factor | `intellect_magic_defence_permille` | `10800` | số nguyên | Hệ số định lực lên phép phòng, mã chia 1000. |
| factor | `dexterity_dodge_permille` | `863` | số nguyên | Hệ số thân pháp lên né, mã chia 1000. |
| factor | `dexterity_hit_permille` | `2600` | số nguyên | Hệ số thân pháp lên trúng, mã chia 1000. |
| factor | `dexterity_critical_attack_permille` | `20` | số nguyên | Hệ số thân pháp lên chí mạng tấn công, phần nghìn. |
| factor | `dexterity_critical_defence_permille` | `20` | số nguyên | Hệ số thân pháp lên chí mạng phòng thủ, phần nghìn. |
| level_factor | `hp_permille` | `60000` | số nguyên | Hệ số cấp lên máu, mã chia 1000. |
| level_factor | `physical_attack_permille` | `29000` | số nguyên | Hệ số cấp lên vật công, mã chia 1000. |
| level_factor | `magic_attack_permille` | `29000` | số nguyên | Hệ số cấp lên phép công, mã chia 1000. |
| level_factor | `physical_defence_permille` | `28800` | số nguyên | Hệ số cấp lên vật phòng, mã chia 1000. |
| level_factor | `magic_defence_permille` | `28800` | số nguyên | Hệ số cấp lên phép phòng, mã chia 1000. |
| level_factor | `dodge_permille` | `2600` | số nguyên | Hệ số cấp lên né, mã chia 1000. |
| level_factor | `hit_permille` | `7800` | số nguyên | Hệ số cấp lên trúng, mã chia 1000. |
| level_factor | `critical_attack_permille` | `60` | số nguyên | Hệ số cấp lên chí mạng tấn công, phần nghìn. |
| level_factor | `critical_defence_permille` | `60` | số nguyên | Hệ số cấp lên chí mạng phòng thủ, phần nghìn. |
| carry | `count_at_level_1` | `2` | số nguyên | Số thú mang được ở cấp 1. |
| carry | `extra_slot_levels` | `20` | số nguyên | Số cấp để thêm một chỗ mang thú. |
| study | `cost_take_level_5` | `1000` | số nguyên | Tiền học kỹ năng khi cấp mang là 5. |
| study | `cost_take_level_15` | `3000` | số nguyên | Tiền học kỹ năng khi cấp mang là 15. |
| study | `cost_take_level_25` | `5000` | số nguyên | Tiền học kỹ năng khi cấp mang là 25. |
| study | `cost_take_level_35` | `7000` | số nguyên | Tiền học kỹ năng khi cấp mang là 35. |
| study | `cost_take_level_45` | `9000` | số nguyên | Tiền học kỹ năng khi cấp mang là 45. |
| study | `cost_take_level_55` | `11000` | số nguyên | Tiền học kỹ năng khi cấp mang là 55. |
| study | `cost_take_level_65` | `13000` | số nguyên | Tiền học kỹ năng khi cấp mang là 65. |
| study | `cost_take_level_75` | `15000` | số nguyên | Tiền học kỹ năng khi cấp mang là 75. |
| study | `cost_take_level_85` | `17000` | số nguyên | Tiền học kỹ năng khi cấp mang là 85. |
| study | `cost_take_level_95` | `19000` | số nguyên | Tiền học kỹ năng khi cấp mang là 95. |
| study | `cost_take_level_105` | `21000` | số nguyên | Tiền học kỹ năng khi cấp mang là 105. |
| study | `extend_manual_cost` | `990000` | số nguyên | Tiền mở thêm kỹ năng điều khiển tay. |
| bone_level | `weight` | `[168, 153, 138, 123, 108, 92, 77, 62, 47, 32]` | mảng | Xác suất cốt cách theo cấp 1 đến 10, mẫu số 1000. |
| savvy | `aptitude_bonus_permille` | `[10, 15, 21, 30, 80, 110, 145, 235, 300, 393]` | mảng | Cộng tư chất, mẫu số 1000. |
| savvy | `max_level_bonus` | `[1, 1, 2, 2, 3, 3, 4, 4, 5, 5]` | mảng | Cấp trần thêm. |
| compound | `success_permille` | `[1000, 850, 750, 600, 200, 310, 310, 30, 70, 60]` | mảng | Tỉ lệ thành. |
| compound | `fail_level_loss` | `[0, 1, 1, 2, 0, 1, 2, 0, 1, 0]` | mảng | Cấp bị tụt. |
| compound | `cost` | `[10000, 11000, 12100, 13310, 14641, 16105, 17716, 19487, 21436, 23579]` | mảng | Phí từng mức. |
| bone_pill | `success_permille` | `[1000, 850, 750, 600, 200, 310, 310, 30, 70, 100]` | mảng | Tỉ lệ thành. |
| bone_pill | `cost` | `[100, 110, 121, 133, 146, 161, 177, 194, 214, 235]` | mảng | Phí từng mức. |
| rejuvenation | `wild_hold_permille` | `200` | số nguyên | Xác suất thú dại giữ tư chất khi hoàn đồng, mẫu số 1000. |
| rejuvenation | `baby_hold_permille` | `0` | số nguyên | Xác suất thú non giữ tư chất khi hoàn đồng, mẫu số 1000. |
| aptitude | `normal_weight` | `[500, 250, 125, 63, 31, 16, 8, 4, 2, 1]` | mảng | Xác suất thú thường, mẫu số 1000. |
| aptitude | `paid_weight` | `[0, 0, 272, 340, 204, 68, 48, 34, 27, 7]` | mảng | Xác suất thú trả phí, mẫu số 1000. |
| aptitude | `show_weight` | `[0, 0, 0, 0, 615, 220, 88, 44, 22, 11]` | mảng | Xác suất thú khoe, mẫu số 1000. |
| aptitude_factor | `normal_permille` | `[1000, 1035, 1070, 1107, 1145, 1185, 1226, 1268, 1312, 1357, 1404]` | mảng | Hệ số thú thường. |
| aptitude_factor | `paid_permille` | `[1000, 1035, 1070, 1107, 1145, 1185, 1226, 1268, 1312, 1357, 1404]` | mảng | Hệ số thú trả phí. |
| aptitude_factor | `show_permille` | `[1000, 1035, 1070, 1107, 1145, 1185, 1226, 1268, 1312, 1357, 1404]` | mảng | Hệ số thú khoe. |
| aptitude_formula | `factor_a_permille` | `1010` | số nguyên | Hệ số A của bậc tư chất. |
| aptitude_formula | `factor_b_permille` | `-20` | số nguyên | Hệ số B của bậc tư chất. |
| skill_slot | `manual_count` | `2` | số nguyên | Số kỹ năng điều khiển tay được mở. |
| skill_slot | `auto_count` | `5` | số nguyên | Số kỹ năng tự động được mở. |

### rules/pvp.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| morality | `minimum` | `0` | số nguyên | Điểm thiện ác nhỏ nhất. |
| morality | `maximum` | `1000000` | số nguyên | Điểm thiện ác lớn nhất. |
| morality | `min_level` | `20` | số nguyên | Cấp tối thiểu để nhận điểm thiện ác. |
| morality | `ally_min_level` | `10` | số nguyên | Cấp đồng đội thấp nhất còn tính. |
| morality | `ally_max_level` | `40` | số nguyên | Cấp đồng đội cao nhất còn tính. |
| morality | `ally_level_gap` | `8` | số nguyên | Chênh cấp tối thiểu của đồng đội. |
| morality | `radius` | `15` | số nguyên | Bán kính nhận điểm thiện ác. |
| morality | `apprentice_bonus` | `3` | số nguyên | Điểm thêm cho mỗi đồ đệ hợp lệ. |
| morality | `death_penalty` | `100` | số nguyên | Điểm mất khi đồng đội chết. |
| story | `minimum` | `0` | số nguyên | Điểm cốt truyện nhỏ nhất. |
| story | `maximum` | `9999` | số nguyên | Điểm cốt truyện lớn nhất. |
| duel | `duration_seconds` | `600` | số nguyên | Thời lượng một trận thách đấu, giây. |
| duel | `min_level` | `10` | số nguyên | Cấp tối thiểu để thách đấu. |
| duel | `vigor_cost` | `100` | số nguyên | Hoạt lực cần để thách đấu. |
| warfare | `personal_duration` | `600` | số nguyên | Thời lượng tuyên chiến cá nhân. |
| pk | `hostile_warning` | `30` | số nguyên | Thời gian cảnh báo người chơi thù địch. |
| fight_back | `legal_duration` | `600` | số nguyên | Thời lượng phản kích hợp lệ. |

### rules/social.toml

| Nhóm | Khoá | Giá trị dev | Kiểu | Chức năng |
|---|---|---|---|---|
| (gốc) | `schema` | `1` | số nguyên | Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu |
| team | `follow_metres` | `10` | số nguyên | Tầm theo đội còn hiệu lực, mét. |
| team | `drop_seconds` | `30` | số nguyên | Quá tầm bao lâu thì rời theo đội, giây. |
| relation | `password_intimacy` | `500` | số nguyên | Độ thân thiết phải có mật khẩu cấp hai. |
| relation | `presence_intimacy` | `0` | số nguyên | Độ thân thiết thì báo lên xuống tuyến. |
| relation | `exp_per_point` | `1` | số nguyên | Kinh nghiệm để tăng một điểm thân thiết. |
| secondary_password | `delete_delay_hours` | `72` | số nguyên | Số giờ rồi bấm lại mới xoá mật khẩu. |
| secondary_password | `change_cost` | `20` | số nguyên | Hoạt lực để đổi mật khẩu. |
| secondary_password | `force_clear_cost` | `50` | số nguyên | Hoạt lực để buộc xoá mật khẩu. |
| secondary_password | `max_errors_per_day` | `5` | số nguyên | Số lần nhập sai tối đa mỗi ngày. |
| secondary_password | `unlock_hours` | `24` | số nguyên | Số giờ đến khi mở khoá có hiệu lực. |
