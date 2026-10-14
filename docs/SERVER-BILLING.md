# Billing (`thienlong_billing`)

Tiến trình giữ sổ điểm nạp, đơn nạp, việc đổi điểm lấy ingot, quà, mã đổi, hạn mức tiêu và sổ kiểm toán. Thiết
kế gốc ở `docs/KE-HOACH-SERVER.md` mục 4 và 7; tệp này ghi **cái đã làm**, hợp đồng của nó và những gì chưa
làm. Nguồn ngữ nghĩa theo thứ tự: client 2026 (`YuanbaoExchange.lua`: số dư hiển thị theo phần mười điểm, trần
500000 ingot mỗi lần đổi), rồi bản 2008 (`BillingServer`, `LoginServer`), rồi dữ liệu XJL7457 (cột loại tiền của
`ShopTable`). Bản 2008 không có máy trạng thái hai pha, đơn chỉ-thêm hay khoá lặp lại; các thứ đó là thiết kế mới.

## 1. Bố cục

| Thư mục | Vai trò |
|---|---|
| `src/server/billing/` | Lõi thuần: `types`, `error`, `limits`, `rules` (máy trạng thái và phép kiểm), `book` (giao diện sổ), `memory_book` (bản nhớ cho test), `checks`, `code` (mã đổi), `throttle` (bộ đếm tốc độ), `http` (bộ phân tích), `webhook`, `wire` và `rpc` (khung ipc). Chỉ link `core ids table secure`. |
| `src/server/billing/db/` | `PgBook`: cài `Book` trên PostgreSQL qua `store/pg` (libpq). |
| `src/server/billing/serve/` | Tiến trình: `setup` (đọc cấu hình), `serve` (vòng chính, luồng phụ), `webhook_server` (socket HTTP), `client` (phía gọi ipc cho world và test). |
| `dev/server/sql/billing/` | `001_ledger` … `005_spend`: 13 bảng, ràng buộc CHECK, trigger chặn sửa sổ. |
| `dev/server/tables/server/billing_limits.tsv` | Các trần số, mỗi số có cột `basis`. |
| `TOOLS/server/fake_provider.py` | Nhà cung cấp thanh toán giả. |

Hai bản cài `Book` (`MemoryBook`, `PgBook`) gọi **cùng** bộ hàm luật ở `rules.hpp` nên không lệch luật; chỗ khác
nhau chỉ là nơi lưu. Test chạy cùng một kịch bản trên cả hai (`Test/Billing/billing_scenarios.hpp`).

Chỉ world gọi billing, qua ipc loopback (khung của `account::rpc`, khoá `ipc.key`). Webhook chỉ nghe
`127.0.0.1`; nhà cung cấp đi vào qua reverse proxy có TLS. Billing không giữ mật khẩu và không nằm trên đường đăng nhập.

## 2. Sổ điểm

- Đơn vị là **phần mười điểm** (client 2026 hiển thị `UINT / 10`); mọi số tiền là số nguyên có kiểu (`Points`,
  `Ingot`), CHECK `>= 0` ở bảng số dư.
- `point_ledger` chỉ ghi thêm: trigger của database từ chối `UPDATE`, `DELETE`, `TRUNCATE`. Mỗi dòng có loại
  (`top_up`, `refund`, `exchange_hold`, `exchange_release`, `register_gift`, `redeem`, `admin`), `delta`, `ref_id`,
  lý do, người làm, thời điểm. Khoá duy nhất `(kind, ref_id)` khi `ref_id <> 0` là chốt chặn cuối của việc lặp lại.
- Số dư là tổng `delta`; `point_balance` chỉ là **bản nhớ đệm** kiểm lại được. Không hàm nào đổi số dư mà không thêm một dòng sổ.
- `ledger_check` (đối soát toàn sổ) kiểm hằng đẳng thức bảo toàn:
  `nạp + chỉnh tay/quà/mã = số dư còn + đã đổi + đang giữ + hoàn`, cộng việc dòng `exchange_hold`/`exchange_release`
  khớp bảng đơn đổi và mọi `point_balance` khớp tổng sổ của nó. Lệch thì in một dòng `SỔ ĐIỂM LỆCH` ra stderr và **không tự sửa**;
  `rebuild_balance` (ipc, có người làm) dựng lại bản nhớ đệm từ sổ và ghi một dòng kiểm toán.
- Đọc nhất quán (`ledger_check`, `day_report`, `balance`) chạy trong `REPEATABLE READ READ ONLY`; mọi ghi giữ
  `pg_advisory_xact_lock(7457001)` nên ghi đi lần lượt (xem mục 9 về đánh đổi).

## 3. Đơn nạp và webhook

Đơn nạp khoá duy nhất `(provider, trade_no)`. Máy trạng thái (`payment_step`):

| Đang có | Nhận | Kết quả |
|---|---|---|
| không có | `pending` / `paid` / `failed` | tạo đơn; `paid` cộng điểm |
| `pending` | `paid` | cộng điểm |
| `pending` | `failed` | đơn hỏng |
| `paid` | `pending` | bỏ qua (báo trễ) |
| `paid` | `refunded` | chỉ qua ipc `refund_payment` (dòng sổ âm) |
| `paid` | `failed` | 409 (mâu thuẫn) |
| `failed` | `paid` | 409 |
| `refunded` | `pending` / `paid` | bỏ qua |
| cùng trạng thái | | trùng lặp (200, không cộng lại) |

Gọi lại cùng `trade_no` mà khác nội dung (điểm, tài khoản…) là 409. Hoàn tiền là dòng sổ âm và đơn sang `refunded`;
người chơi đã tiêu điểm thì `kInsufficient`.

**Webhook** (`POST`, `application/x-www-form-urlencoded`, mỗi kết nối đúng một yêu cầu):

- Trường thân: `trade_no`, `account`, `points` (phần mười điểm), `amount` (đơn vị nhỏ nhất của tiền tệ, chỉ để lưu),
  `currency`, `status` (`pending|paid|failed`).
- Tiêu đề `X-Timestamp` (giây Unix) và `X-Signature` = hex thường của HMAC-SHA512 rút còn 32 byte (`secure::mac32`,
  libsodium) trên `"TLBBPAY1\n" + đường dẫn + "\n" + X-Timestamp + "\n" + thân nguyên văn`. Khoá 32 byte riêng từng
  nhà cung cấp, ghi 64 ký tự hex trong `secret_file`. Đường dẫn nằm trong thông điệp nên chữ ký nhà A vô dụng ở đường dẫn nhà B.
- Độ lệch `X-Timestamp` so với đồng hồ billing tối đa `webhook_max_skew_seconds`; bản chặn được chỉ phát lại trong cửa sổ đó, và
  phát lại trong cửa sổ vẫn vô hại vì khoá `(provider, trade_no)`.
- Mã trả: 200 (`ok`, `duplicate`, `ignored`), 400 (HTTP hỏng), 401 (sai chữ ký hoặc mốc thời gian; kẻ không có khoá chỉ thấy 401 hoặc 404),
  404 (đường dẫn lạ), 405, 408 (nói chậm), 409 (mâu thuẫn, trạng thái sai), 411, 413, 422 (thân form sai, số ngoài miền),
  431, 503 (database bận: nhà cung cấp gọi lại). Thứ tự từ chối của bộ phân tích: 405, 400, 411, 401 (thiếu chữ ký), 400
  (kiểu nội dung), 413.
- Bộ phân tích HTTP tự viết, nghiêm: không chunked, không `Expect`, không nối nhiều yêu cầu, đầu ≤ 4 KiB, thân ≤ 4 KiB, ≤ 32 tiêu đề, chỉ CRLF.
  Máy chủ: tối đa 64 kết nối, 5 giây để gửi đủ yêu cầu (408 rồi đóng), 2 giây nán lại sau khi trả lời (đóng ngay khi còn byte chưa đọc làm
  Windows gửi RST và có thể xoá trả lời khỏi bộ đệm của bên kia).
- Lý do HMAC-SHA512-256 thay vì HMAC-SHA256 thường gặp: lớp `secure` chỉ lộ `crypto_auth` của libsodium. Cổng thanh toán thật có định dạng chữ ký riêng
  thì thêm một hàm xác thực cho nhà đó; khung giữ nguyên.

## 4. Đổi điểm lấy ingot (hai pha)

Chi phí: `ceil(ingot × 10 / ingot_per_point)` phần mười điểm (làm tròn lên để không bao giờ phát ingot mà thu thiếu điểm). Ví dụ
`ingot_per_point = 3`, 10 ingot → `ceil(100 / 3) = 34`. Trần mỗi lần 1 … 500000 ingot (`billing_limits.tsv`, nguồn client 2026).

1. `exchange_begin(account, character, request_id, ingot)`: giữ điểm (dòng sổ `exchange_hold`), tạo đơn `pending`, trả `order_id` và số dư.
   Gọi lại cùng `(account, request_id)` trả lại đúng đơn, không giữ thêm; khác nội dung là `kConflict`. Tài khoản đóng băng: `kFrozen`.
2. World chuyển cho zone cộng ingot (ngoài phạm vi billing).
3. `exchange_finish(order_id, done|cancelled)`: `done` chốt (`confirmed`); `cancelled` trả điểm (`exchange_release`, đơn `cancelled`).
   Báo lặp cùng kết quả trả lại như cũ; báo ngược với kết quả đã chốt là `kBadState`.
4. Quá `pending_timeout_seconds` mà chưa có tin: `exchange_sweep` đánh dấu `stale` (không đụng điểm). Billing **không tự hoàn** khi chưa biết game
   đã cộng ingot hay chưa; `exchange_open` liệt kê đơn `pending`/`stale` cũ nhất trước để world hỏi game bằng `order_id`, rồi `exchange_finish` với kết quả thật.

## 5. Quà, mã đổi, bộ đếm tốc độ

- Đợt (`create_batch`) có tên, thời hạn, giới hạn mỗi tài khoản, ≤ 16 phần thưởng; mã sinh bằng `mint_codes` (≤ 300 mã mỗi lần gọi, ≤ 5000 mã mỗi đợt).
  Mã 16 ký tự từ bảng 31 chữ (bỏ I L O 0 1), ≈ 79 bit; **database chỉ giữ SHA-256 của mã đã chuẩn hoá**.
- `redeem` thứ tự kiểm: băm, tồn tại, đóng băng, đợt bật, đã dùng, chưa tới/hết hạn, giới hạn mỗi tài khoản. Mã dùng một lần.
- Phần thưởng của đợt có `kind`: `0` là điểm nạp, cộng thẳng vào sổ điểm (dòng `redeem`, tổng các phần thưởng loại 0 phải qua `credit_step`: dương và không vượt `max_balance`);
  các loại còn lại (1 vàng, 5 ingot, 6 điểm tặng, 8 giao tử, 100 vật phẩm, số của cột loại tiền `ShopTable`) thành khoản quà `reward_grant` chờ phát.
- Khoản quà là hàng chờ phát cho nhân vật: `grant_claim` giữ một đơn phát, `grant_finish` chốt `done|cancelled` như đổi điểm (báo lặp trả như cũ, báo ngược là `kBadState`); `grant_add` cho GM thêm quà tay.
- Hai bộ token bucket (theo tài khoản: `attempts_per_hour`; theo IP: `redeem_ip_attempts_per_hour`), tính bằng tick (20/giây), tất định, tối đa
  `throttle_max_keys` khoá (đầy thì khoá mới bị từ chối: chặn kẻ đổi IP ăn bộ nhớ). **Nằm trong bộ nhớ: billing chạy lại thì đầy lại** (xem mục 9).

## 6. Hạn mức, quản trị, nhật ký

- `spend_record`: zone báo mỗi lượt tiêu ingot (khoá `event`, báo lặp chỉ ghi một lần, cùng event khác nội dung là `kConflict`); `spend_headroom` trả phần còn
  được tiêu trong ngày UTC của nhân vật (`daily_ingot_cap`, 0 là không trần); vượt thì 0, không âm.
- `admin_adjust` (cộng/trừ tay) cần `request_id` (khoá lặp lại), lý do và người làm; mỗi lần ≤ `max_admin_adjust`; không để âm hay vượt `max_balance`.
- `set_frozen`, `refund_payment`, `set_batch_enabled`, `rebuild_balance`, `grant_add` đều cần lý do/người làm và ghi `audit_event` hoặc dòng sổ.
- Chữ do người ngoài gửi (lý do, người làm, tên đợt) được **cắt khoảng trắng đầu cuối, bác byte điều khiển và bác chuỗi không phải UTF-8 đúng RFC 3629**
  ngay ở cửa (`kReasonRequired`); sổ lưu bản đã cắt. Lý do: PostgreSQL từ chối chuỗi hỏng bằng lỗi 22021 mà lỗi database thì bên gọi coi là `kBusy` rồi gọi lại mãi, và
  cột `reason` giới hạn 200 byte nên lưu bản chưa cắt có thể vi phạm CHECK.
- `day_report(ngày UTC)`: điểm nạp/hoàn/đổi, ingot phát/tiêu, số sự kiện tiêu, đơn còn mở, kèm kết quả bảo toàn. Chạy lúc khởi động (cho ngày hôm qua) và lúc sang ngày UTC; in một dòng ra stderr.

## 7. ipc

Khung của `account::rpc` (XChaCha20-Poly1305, một yêu cầu một kết nối, khung ≤ 8 KiB). Khoá là `<config>/../data/ipc.key` chung của cụm (billing tạo nếu chưa có, như store và auth); tệp phải riêng của tài khoản chạy máy chủ, lỏng hơn thì billing từ chối chạy (`account::ipc_key_private`). `Op` của billing
một byte; khung của account mang hai byte nên giá trị > 255 là `kMalformed`.

`balance 1`, `ensure_account 2`, `set_frozen 3`, `quote 4`, `exchange_begin 5`, `exchange_finish 6`, `exchange_open 7`, `find_exchange 8`, `exchange_sweep 9`, `redeem 10`,
`grant_list 11`, `grant_claim 12`, `grant_finish 13`, `grant_open 14`, `grant_add 15`, `admin_adjust 16`, `refund_payment 17`, `find_payment 18`, `create_batch 19`,
`set_batch_enabled 20`, `mint_codes 21`, `spend_record 22`, `spend_headroom 23`, `ledger_check 24`, `rebuild_balance 25`, `day_report 26`, `ledger_tail 27` (≤ 20 dòng).

Mã lỗi: `kMalformed 1`, `kRateLimited 12`, `kBusy 16` (hai mã sau trùng `protocol::ErrorCode`, có `static_assert`), `kBadAmount 101`, `kInsufficient 102`, `kFrozen 103`, `kNotFound 104`,
`kConflict 105`, `kBadState 106`, `kBadCode 107`, `kCodeUsed 108`, `kCodeNotYet 109`, `kCodeExpired 110`, `kCodeDisabled 111`, `kLimitReached 112`, `kReasonRequired 113`,
`kTooMany 114`, `kBadSignature 120`, `kStaleTimestamp 121`, `kUnknownProvider 122`.

**Hợp đồng gọi lại.** Lỗi database, hàng việc đầy, ngắt kết nối hay hết hạn đều là `kBusy` và bên gọi **không biết** thao tác đã chạy hay chưa (COMMIT có thể đã xong khi
mạng đứt). Mọi thao tác ghi đều có khoá lặp lại (`request_id`, `trade_no`, `order_id`, `event`), nên gọi lại cùng khoá là cách chuẩn để biết kết quả. `billing::Client::call` không ném và
không chờ quá hạn; mọi lỗi vận chuyển thành `Reply{kBusy}`.

## 8. Tiến trình

- Một luồng database (của `account::serve_loop`, tối đa 64 kết nối) xử lý ipc với `PgBook` thứ nhất. Một luồng phụ với `PgBook` thứ hai chạy webhook và việc định kỳ:
  quét đơn quá hạn mỗi `reconcile_interval_seconds`; `ledger_check` lúc khởi động, mỗi `ledger_check_interval_seconds` và lúc sang ngày UTC; báo cáo ngày. Hai kết nối ghi tuần tự nhờ khoá cố vấn.
- In `ready ipc=<cổng>` khi đã áp migration, nối database và mở mọi cổng nghe. Cổng webhook **phải cố định** trong `billing.toml` vì trình giám sát chỉ nhận các khoá cổng `ipc`, `game`, `auth`, `metrics`
  (test xin cổng trống rồi ghi vào cấu hình tạm). Không có `secrets.local.toml` thì in `ready` và chờ dừng (cụm thử không cần PostgreSQL vẫn lên).
- Dừng êm khi stdin đóng (như trình giám sát); luồng phụ hỏng tập chờ socket thì `quick_exit(3)` để trình giám sát chạy lại.
- Mất kết nối database: `PgBook` tự nối lại ở lần gọi sau (đếm `reconnects()`); câu lỗi không chứa mật khẩu.

## 9. Cấu hình

`billing.toml`: `[database] name user pool`, `[access] allow` (phải chứa `127.0.0.1`), `[limits] max_clients`, `[points] ingot_per_point register_gift`, `[spend] daily_ingot_cap`,
`[orders] pending_timeout_seconds reconcile_interval_seconds`, `[redeem] attempts_per_hour`, `[webhook] port` (127.0.0.1; chỉ nghe khi có ít nhất một nhà cung cấp bật), và mỗi nhà cung cấp một khối
`[[provider]] key webhook_path secret_file enabled` (`secret_file` tính từ thư mục cấu hình, nội dung 64 ký tự hex). Mật khẩu role `thienlong_billing` ở `secrets.local.toml`. Khoá ipc ở `ipc.key` cạnh cấu hình.

Bảng `billing_limits.tsv` (11 số; `basis`: `client_2026` là đo từ script client, `made_up` là **số tự đặt chờ chủ dự án duyệt**):

| Khoá | Giá trị | Nguồn |
|---|---|---|
| `min_ingot_per_order`, `max_ingot_per_order` | 1, 500000 | `client_2026` (`YuanbaoExchange.lua`) |
| `webhook_max_skew_seconds` | 300 | `made_up` |
| `max_points_per_topup` | 10.000.000 phần mười (1.000.000 điểm) | `made_up` |
| `max_admin_adjust` | 100.000 phần mười (10.000 điểm) | `made_up` |
| `max_balance` | 2.000.000.000 phần mười | `made_up` |
| `redeem_ip_attempts_per_hour` | 60 | `made_up` |
| `max_codes_per_batch` | 5000 | `made_up` |
| `max_grant_quantity` | 1.000.000 | `made_up` |
| `throttle_max_keys` | 65536 | `made_up` |
| `ledger_check_interval_seconds` | 21600 | `made_up` |

Các số `[orders]`, `[redeem]`, `[points]` trong `billing.toml` là "số tạm" của tệp cấu hình có sẵn (tỉ giá `ingot_per_point = 1`, `register_gift = 0` chưa chốt). Trần tài nguyên đặt trong mã:
webhook 64 kết nối, 5 giây, nán 2 giây, 4 KiB đầu và thân; 300 mã mỗi lần mint; 20 dòng sổ mỗi lần `ledger_tail`; 1000 mã mỗi lần thêm; ≤ 16 phần thưởng mỗi đợt; 64 sự kiện tiêu mỗi lần báo.

## 10. Mô hình lỗi

| Cách hỏng | Xử lý | Chứng cứ |
|---|---|---|
| Nhà cung cấp gọi lại / giả mạo / phát lại | khoá `(provider, trade_no)`, chữ ký, độ lệch thời gian, nội dung khác là 409 | `webhook_flow`, `serve_webhook`, `serve_storm_with_crashes` |
| Mạng đứt giữa hai pha đổi | đơn `pending`/`stale` còn nguyên, gọi lại pha một nhận lại đúng đơn | `pg_restart_mid_flow`, `serve_exchange_phases` |
| Billing bị giết giữa chừng | giao dịch hoặc xong hẳn hoặc không; gọi lại bằng khoá cũ | `serve_exchange_phases`, `serve_storm_with_crashes` (3 lần giết) |
| Backend database bị giết | `kBusy`, lần gọi sau nối lại, sổ vẫn cân | `pg_reconnect`, `pg_fault_injection` |
| Hai kết nối tranh nhau | khoá cố vấn; không deadlock, không âm số dư | `pg_two_writers` |
| Bản nhớ đệm lệch | `ledger_check` phát hiện, `rebuild_balance` dựng lại | `memory_admin_spend_audit`, `pg_admin_spend_audit` |
| Chữ/byte thù địch | bộ phân tích HTTP nghiêm, UTF-8 đúng, CHECK ở database | `http_fuzz`, `rpc_hostile`, `text_fields`, `pg_schema_rules` |
| Kẻ nói chậm, kết nối dồn | 408, trần 64 kết nối, nhận tối đa 32 kết nối mỗi vòng | `serve_webhook` |

## 11. Kiểm chứng

```
cmake --build build\<cây> --target billing_tests billing_db_tests billing_serve_tests
billing_tests.exe        # 22 ca, thuần, không cần database
billing_db_tests.exe     # 10 ca, PgBook trên PostgreSQL thật (schema riêng mỗi ca); tự bỏ qua nếu không có secrets.local.toml
billing_serve_tests.exe  # 6 ca, chạy thienlong_billing.exe thật trên database tạm; tự bỏ qua nếu không có mật khẩu role postgres
python -B -m unittest discover -s TOOLS/server -p "test_fake_provider.py"
```

Test dùng số vàng tính tay (ví dụ `ceil(10 × 10 / 3) = 34`, chữ ký HMAC khớp bản Python độc lập). Bảo toàn điểm được đối soát bằng SQL viết riêng, không dùng chính `ledger_check` đang thử.

`TOOLS/server/fake_provider.py`: `keygen`, `send` (một đơn, có `--tamper`), `storm` (đợt đơn tất định theo hạt giống: gọi lại, báo chờ rồi trả, báo trễ, mâu thuẫn, chữ ký sai, mốc cũ, đường dẫn lạ, đứt giữa yêu cầu; in số điểm billing phải cộng).

## 12. Chưa làm, giới hạn, giả định

- **Tệp khoá HMAC của nhà cung cấp không bị kiểm quyền truy cập** (billing đọc được là đủ), khác `ipc.key` vốn bị `account::ipc_key_private` từ chối khi lỏng. Đây là khe hở an ninh lớn nhất còn lại: lộ khoá thì kẻ gian ký được webhook cộng điểm. Chưa làm vì `ipc_key_private` thuộc module `account` (không thuộc phạm vi đợt này), câu lỗi của nó viết cứng "ipc.key", và tệp test trên Windows thừa hưởng ACL của thư mục dựng nên cần đặt quyền riêng cho tệp tạm. Việc sửa: tổng quát hoá hàm đó thành `file_private(path, tên, error)` rồi gọi trong `providers_of` (`billing/serve/setup.cpp`). Trước đó: đặt thư mục cấu hình thuộc riêng tài khoản chạy máy chủ.
- `[limits] max_clients` **không có hiệu lực**: khung vận chuyển dùng chung với account cố định 64 kết nối. `[access] allow` chỉ được kiểm là có `127.0.0.1`; ipc chỉ nghe địa chỉ loopback trong `cluster.toml`.
- Bộ đếm tốc độ nhập mã nằm trong bộ nhớ: billing chạy lại thì mọi tài khoản và IP có lại đủ lượt.
- `ledger_check` quét cả sổ (độ phức tạp O(số dòng sổ)); ổn khi sổ cỡ trăm nghìn dòng, chưa đo ở cỡ hàng chục triệu. Khi cần: đối soát gia tăng theo mốc `id`.
- Chữ ký webhook là khung chung (HMAC-SHA512-256); chưa có bộ chuyển cho định dạng chữ ký riêng của một cổng thanh toán cụ thể (VNPay, MoMo, …). HTTP trần trên loopback, TLS do reverse proxy.
- Billing **không xác thực GM**: ai có `ipc.key` (chỉ world) thì gọi được thao tác quản trị, tên người làm do bên gọi khai. Việc xác thực GM thuộc world.
- Ghi tuần tự bằng một khoá cố vấn toàn cục: đủ cho vài trăm ghi mỗi giây (chưa đo thông lượng); tách theo tài khoản là việc sau khi có số đo.
- Báo cáo ngày và cảnh báo lệch sổ chỉ ra stderr; chưa có chỉ số cho `metrics`.
- Phía gọi (world) chưa nối billing; `billing::Client` đã có và đã dùng trong test.
- Chưa chạy: debug mode của libstdc++ cho `billing_tests` (cần dựng libsodium bằng GCC; preset `gcc-debug` không cấu hình được trên máy này vì SDL3), TSan (Windows không có).
- Giả định: đồng hồ billing đúng (độ lệch webhook, ngày UTC của báo cáo và hạn mức); nhà cung cấp gửi `points` đã quy đổi sang phần mười điểm; một cụm PostgreSQL có database `thienlong_billing` do role cùng tên sở hữu.
