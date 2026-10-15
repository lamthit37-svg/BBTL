# Dữ liệu máy chủ: định dạng, nhà phát hành và nhà phát triển

Chủ dự án giao ngày 2026-10-15: chọn định dạng dữ liệu của máy chủ ("xem cách nào hoàn hảo nhất"), phân rõ
nhà phát hành (NPH: vận hành máy chủ, không có source) và nhà phát triển (NPT: có source, công cụ và dữ liệu
gốc); `dev/` chỉ chứa thứ dành cho NPH. Thứ tự ưu tiên chủ dự án nêu: bảo mật và an toàn trước, rồi tiện, nhanh,
hiệu năng. Thứ lộ ra cũng không sao (chữ thoại, bảng vật phẩm) thì không cần giấu; bảo mật dồn vào bí mật thật
và vào việc dữ liệu nào cũng không làm máy chủ chạy sai.

## 1. Ai sở hữu thư mục nào

`dev/server` (máy chủ thử) và `release/server` (bản chính thức) cùng hình. Một câu luật: **NPH chỉ sửa trong
`config/`**; mọi thứ khác là của NPT và bị thay nguyên khối ở lần nâng bản sau.

| Thư mục | Chủ | NPH sửa | Khi nâng bản |
|---|---|---|---|
| `bin/` | NPT | không | thay |
| `tables/`, `scenes/` | NPT (sinh từ dữ liệu gốc bằng công cụ ở `TOOLS/`) | không: sửa sẽ mất | thay |
| `sql/` | NPT (migration đánh số, tiến trình tự áp lúc khởi động) | không | thêm tệp mới |
| `pgsql/` | NPT (nhị phân PostgreSQL) | không | thay |
| `config/` | NPH: cấu hình tiến trình, luật chơi, giao diện client, bảng và chữ đè | có | không đụng |
| `data/` | sinh lúc chạy: database, khoá danh tính, nhật ký ghi | qua công cụ | không đụng |
| `log/` | sinh lúc chạy | không | không đụng |

`dev/client` chỉ có `bin/` (exe và gói shader) và `assets/`, đều của NPT. NPH không sửa client: thứ NPH cần đổi
trên màn hình người chơi do máy chủ gửi xuống (đã chốt 2026-10-14 với `client.toml` và tin `UiConfig`). Bản sao
lưu exe, exe thử nghiệm và gói shader cũ không nằm trong `dev/`.

## 2. Định dạng theo hình dữ liệu

| Hình dữ liệu | Định dạng | Ví dụ | Vì sao |
|---|---|---|---|
| Cài đặt có khoá đặt tên | TOML | `config/*.toml`, `config/rules/*.toml` | có kiểu, có chú thích; bộ đọc từ chối khoá lạ, thiếu khoá, sai kiểu, ngoài miền kèm số dòng |
| Bản ghi cùng hình | TSV UTF-8 | `tables/server/*.tsv`, `tables/shared/*.tsv` | bộ đọc có sẵn ở C++ và Python, mở được bằng bảng tính; bảng ≤ 1 MiB căn cột cho dễ đọc |
| Câu chữ | `.txt`: bảng hai cột `key`, `text` | `tables/server/dialogue.zh.txt` | đọc như văn bản, nhóm theo NPC; đuôi txt để mở bằng trình soạn chữ (Excel đổi bảng mã chữ Hán khi lưu) |
| Hình học đã nấu | nhị phân `.nav`, `.bin` | `scenes/<cảnh>/walk.nav` | khớp băm với tệp gốc |
| Tài khoản, nhân vật, tiền | PostgreSQL | `data/pg` | giao dịch, sao lưu, khôi phục tới thời điểm |
| Bí mật | TOML riêng và tệp khoá | `config/secrets.local.toml`, `data/gate/identity.key` | chỗ duy nhất cần giấu |

Không dùng JSON, YAML, XML, ini, và không có script chạy được trong dữ liệu (máy chủ không Lua, chốt 2026-10-06):
dữ liệu chỉ mô tả, không ra lệnh.

## 3. NPH đổi nội dung bằng tệp đè

NPH không sửa tệp của NPT mà đặt tệp đè trong `config/`:

- `config/text/dialogue.<ngôn ngữ>.txt`: cùng định dạng với `tables/server/dialogue.zh.txt`; chép dòng muốn đổi,
  giữ khoá, sửa chữ. Khoá trùng thì câu của `config` thắng; khoá mới thì thêm.
- `config/tables/<tên>.tsv`: cùng tên và cùng cột với bảng của NPT; dòng có khoá (cột đầu) trùng thì thay cả dòng,
  khoá mới thì thêm. Chỉ bảng trong danh sách cho phép do NPT giữ mới được đè (cửa hàng, rơi đồ, thông báo, sự kiện
  theo giờ, quà tân thủ, từ cấm). Bảng logic (`ops_*`, `talk_*`, `effects`, `skill_levels`...) không được đè: chúng
  tham chiếu chéo nhau, đè một dòng làm hỏng bất biến mà công cụ của NPT đã kiểm.

Máy chủ đọc bảng của NPT rồi tệp đè lúc khởi động; tệp đè sai thì không khởi động, báo tệp và dòng.
`thienlong_lint` (exe trong `bin/`, NPH không cần Python) kiểm trước khi chạy.

Trạng thái 2026-10-15: luật trên đã chốt nhưng **chưa có bộ nạp tệp đè**, vì máy chủ chưa đọc bảng nào trong danh
sách cho phép (zone đọc `scene_ids`, `monsters`, `monster_ai_*`; billing đọc `billing_limits`) và chưa đọc chữ
thoại. Bộ nạp làm cùng lúc với tính năng đầu tiên đọc một bảng như vậy, kèm danh sách cho phép và lint cho
`config/tables`, `config/text`.

## 4. Bảo mật và an toàn

- Bí mật chỉ ở `config/secrets.local.toml`, khoá HMAC của nhà cung cấp thanh toán trong `config/`, và `data/` (khoá
  danh tính của gate, khoá ipc, cụm PostgreSQL): không vào git, không vào log. Mọi tệp bí mật phải **riêng**: Windows
  chỉ SYSTEM, Administrators và tài khoản chạy máy chủ (DACL không kế thừa), POSIX 0600 của chủ
  (`src/shared/secure/private_file.hpp`). Tiến trình đọc bí mật kiểm trước khi đọc và từ chối chạy nếu tệp lỏng hơn,
  không tự sửa quyền: auth, store, billing với `secrets.local.toml` (thoát 1), gate với khoá danh tính (thoát 2,
  `secure::Error::kExposed`), mọi tiến trình với `ipc.key`, billing với khoá nhà cung cấp. Gate `--gen-key` và tiến
  trình tạo `ipc.key` tạo tệp kèm quyền riêng ngay lúc tạo. `TOOLS/server/setup_db.py init` ghi `secrets.local.toml`
  qua tệp tạm đã khoá quyền rồi đổi tên, và khoá cả thư mục `data/` kèm kế thừa trước khi initdb ghi vào đó; chạy lại
  `init` trên cụm đã có thì giữ mật khẩu và khoá lại quyền.
- Đo 2026-10-15 trước khi sửa: trên máy chủ thử ở ổ D, `secrets.local.toml` và `data/gate/identity.key` mang quyền kế
  thừa của ổ (Authenticated Users được sửa, Users được đọc). Ngoài chủ máy còn hai tài khoản đang bật là
  `CodexSandboxOffline`, `CodexSandboxOnline` (sandbox của Codex CLI) đọc được hai tệp đó. Sau sửa, các tài khoản này
  không đọc được bí mật và `data/` nữa: phiên Codex chạy trong sandbox sẽ thấy test PostgreSQL tự bỏ qua và tiến trình
  máy chủ từ chối chạy.
- Mọi tệp khác là chữ thường, không mã hoá, không ký: NPH có quyền máy chủ nên chữ ký không chặn được ai, và chữ thoại
  hay bảng vật phẩm lộ ra không gây hại.
- Mọi tệp NPH sửa là đầu vào không tin: bộ đọc kiểm kiểu, miền, số cột, trần cỡ; không có gì trong dữ liệu được
  thực thi; sai thì dừng khởi động (fail-closed) thay vì chạy với giá trị đoán.
- Máy chủ làm chủ mọi luật; client chỉ hiện. Chữ máy chủ gửi xuống chỉ là chữ (không có lệnh).

## 5. Tốc độ

Đo 2026-10-15, `server_data_lint` (MSVC bản phát hành): đọc và kiểm 5.076 tệp, 1.361.426 bản ghi, 23.656.974 ô
trong 1,84 giây; mỗi tiến trình chỉ đọc phần nó cần. Chưa nấu bảng ra nhị phân: chỉ làm khi một ngân sách khởi
động có số đo bị vượt.

## 6. Chữ thoại

`tables/server/dialogue.zh.txt` thay `mission_strings.tsv` từ 2026-10-15: 2.507 câu viết thẳng trong script Lua gốc
(lời NPC, lựa chọn, chuỗi nhiệm vụ), 1.181 nhóm theo script NPC hoặc nhiệm vụ, 203 KB (bảng cũ 822 KB vì cột chữ
bị đệm tới câu dài nhất). `TOOLS/server/lua_extract.py` sinh tệp; định dạng, bộ đọc và bộ kiểm ở
`TOOLS/server/dialogue_text.py` (`python -X utf8 TOOLS/server/dialogue_text.py check [tệp]`). Mã chuỗi gửi qua dây
là `ops::string_id(khoá)`; khoá là mã định danh nên sửa chữ không đổi khoá. Đoạn thoại dài nằm ở khoá StrDictionary
của client (`#{BSQZ_...}`), không ở tệp này.

`thienlong_lint` đọc tệp `.txt` dưới `tables/` như bảng; dòng nhóm `## <chủ> <nhãn>` chỉ hợp lệ ở tệp `.txt`
(`content::RecordReader`), ở `.tsv` vẫn là lỗi.

Chưa có: máy chủ chưa nạp tệp này; client chưa có chữ của các khoá `lua.*` (`assets/i18n/zh.tsv` không có khoá nào
như vậy), nên lời NPC viết thẳng trong Lua chưa hiện được ở client. Cách đưa chữ xuống client (theo tin mạng hay theo
gói chữ tải lúc vào game) quyết khi làm hộp thoại NPC phía client.

### Bản tiếng Việt

`tables/server/dialogue.vi.txt` là bản dịch của cả 2.507 câu (cùng khoá, cùng 1.181 nhóm, cùng thứ tự với bản zh). Sáu bảng
chuỗi hệ thống có bảng anh em `<bảng>.vi.tsv` cùng cột, chỉ cột chữ đổi sang tiếng Việt: `server_strings` (312 câu),
`notices_on_login`, `notices_by_weekday`, `notices_by_date`, `rolling_announcements`, `npc_chat_lines` (79 câu). Chủ dự án giao
ngày 2026-10-15: tiếng Việt có dấu chuẩn, văn phong võ hiệp cổ điển đúng chất Thiên Long Bát Bộ bản FPT. Quy ước đã dùng: dấu thanh
kiểu cũ như `assets/i18n/vi.tsv` (hoà, thuỷ, tuỳ), tên theo `assets/i18n/glossary.tsv` và theo tên mà client đang hiển thị (item,
kỹ năng, nội công, cảnh), NPC xưng "ngươi/các hạ", chuỗi hệ thống xưng "bạn", cặp câu hai giới giữ song song (`Thiếu hiệp {0}` và
`Cô nương {0}`), tên nhiệm vụ viết hoa từng âm tiết, môn phái viết "Thiếu Lâm phái".

Cổng: `python -X utf8 TOOLS/server/dialogue_i18n.py check <zh> <vi>` (thẻ màu, `#{...}`, chỗ điền `%s %d {0} $N`, dấu cách đầu và
cuối, chữ Hán sót, NFC; thứ tự chỗ điền không được đảo vì máy chủ điền lần lượt), `terms` (thuật ngữ của glossary, chỉ cảnh báo),
`build <ngôn ngữ> <tệp phần>...` và `tables <ngôn ngữ> <tệp phần>...` (gộp phần dịch rồi ghi, kiểm trước, có lỗi thì không ghi).
Bản vi là nguồn của chữ Việt: sửa chữ thì sửa thẳng tệp (dòng `# tool:` chỉ để công cụ nhận tệp của nó). Khi `lua_extract.py` sinh
lại bản zh, `test_dialogue_i18n.py` đỏ cho tới khi bản vi có đủ khoá mới.

Chưa có: máy chủ chưa chọn ngôn ngữ lúc chạy, vì chưa nạp tệp chữ nào (mục 3). Bộ nạp làm cùng lượt với tính năng đầu tiên đọc
chữ thoại: đọc `dialogue.<ngôn ngữ>.txt`, rồi tệp đè `config/text/dialogue.<ngôn ngữ>.txt`.
