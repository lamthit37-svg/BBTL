# Bảo mật đường truyền của gate

Thiết kế của lớp `secure` và mặt trước `thienlong_gate`. Viết trước mã; mã nay đã có ở
`SRC/secure` và `SRC/gate` (gộp vào `main` ở `21fe0ba`), và các cỡ ghi ở đây khớp hằng của
`SRC/secure/secure.hpp` (đối chiếu 2026-10-08: lời chào 42 byte, trả lời 96 byte, thân client
4096 byte). Nguồn đối chiếu là
`G:\TLBB\Dev\docs\BAO-MAT.md` và `src/secure` (chỉ đọc). Mật mã không tự viết: mọi phép lấy từ
libsodium 1.0.22 đã có trong `third_party/libsodium`.

Phần đầu viết cho bước chỉ có tin mức phiên. Đối chiếu mã ngày 2026-10-12: gate đã xử lý thêm tin
tài khoản và nhân vật (mục "Tài khoản qua gate" ở cuối tệp); vé, băm mật khẩu Argon2id và IPC tới
`auth`, `store` nằm ở `src/server/account`.

## Mô hình mối đe doạ

Chống được:

- Nghe lén trên đường truyền. Mọi byte sau bắt tay được mã hoá. Khoá phiên có bí mật tiến tới: lấy
  được khoá danh tính sau này không mở được lưu lượng đã ghi.
- Kẻ đứng giữa sửa, chèn, cắt, phát lại, đảo thứ tự, hoặc đóng giả máy chủ. Client ghim khoá công
  khai Ed25519. Không có đường hạ phiên bản.
- Client thù địch: bản ghi quá dài, byte rác, bắt tay dở, xả tin, đọc chậm. Sai thì ngắt đúng kết
  nối đó. Gate không dừng, không phình bộ nhớ, không ghi log theo nhịp của kẻ tấn công.

Ngoài mô hình: máy chủ bị chiếm quyền, client bị sửa, và nghẽn băng thông thuần.

## Bắt tay

Nhãn miền là tám byte ASCII `TLBBSEC1`. Phiên bản giao thức bảo mật là `1` (`u16` little-endian).
Chỉ đúng phiên bản này được nhận. Không thương lượng xuống phiên bản thấp hơn.

Client gửi 42 byte, độ dài cố định, chưa mã hoá:

- nhãn `TLBBSEC1`, 8 byte;
- phiên bản, `u16` little-endian;
- khoá công khai X25519 tạm, 32 byte.

Nhãn sai hoặc phiên bản khác 1: máy chủ không trả lời, luồng hỏng với lỗi giao thức. Không có bản
rõ dự phòng.

Máy chủ sinh khoá X25519 tạm bằng `crypto_kx_keypair` (ngẫu nhiên mỗi lần, không suy từ lời chào).
Rồi ký Ed25519 (`crypto_sign_detached`) bản ghi 74 byte:

- khoá tạm của client, 32 byte;
- khoá tạm của máy chủ, 32 byte;
- nhãn `TLBBSEC1`, 8 byte;
- phiên bản, `u16` little-endian.

Chữ ký phủ cả hai khoá tạm và phiên bản. Thiếu một trong hai khoá thì một lời đáp cũ dùng lại được
cho phiên khác. Đổi phiên bản trên đường truyền thì chữ ký không còn khớp.

Máy chủ trả 96 byte: khoá tạm của mình (32) rồi chữ ký (64).

Client kiểm chữ ký bằng khoá ghim (`crypto_sign_verify_detached`) trước khi suy khoá phiên. Sai thì
không có khoá nào được giao cho người gọi.

Khoá phiên lấy từ `crypto_kx_server_session_keys` và `crypto_kx_client_session_keys`. Mỗi chiều một
khoá 32 byte: khoá gửi của client là khoá nhận của máy chủ, và ngược lại. Hai lần bắt tay cùng một
lời chào vẫn ra hai khoá phiên khác nhau vì khoá tạm của máy chủ là ngẫu nhiên.

Khoá tạm bí mật bị `sodium_memzero` ngay sau khi suy khoá, kể cả khi suy khoá thất bại.

## Bản ghi

Đứng dưới khung protocol. Không biết mã tin. Một bản ghi:

- độ dài phần thân, `u16` little-endian, từ 17 tới 4120;
- phần thân: bản mã ChaCha20-Poly1305 IETF (`crypto_aead_chacha20poly1305_ietf`) cộng 16 byte dấu.

Phần rõ của một bản ghi dài từ 1 tới 4104 byte. 4104 là một khung client lớn nhất: đầu khung 8 byte
cộng thân 4096 byte (`kClientBodyBytes`). Tin lớn hơn không xuất hiện ở bước này; máy chủ chỉ gửi
`Welcome`, `Pong`, `Reject`, `Goodbye`.

Hai byte độ dài là dữ liệu đi kèm (associated data). Nonce 12 byte không đi trên dây: bốn byte 0
rồi bộ đếm `u64` little-endian của chiều đó, bắt đầu từ 0, tăng một sau mỗi bản ghi mở hoặc niêm
thành công. Bộ đếm bằng `2^64 - 1` thì luồng hỏng với lỗi cạn, không quay vòng.

Độ dài được kiểm ngay khi đủ hai byte đầu, trước khi nhận phần thân vào vùng đệm. Vùng đệm nhận
đúng một bản ghi, cấp một lần lúc tạo. Độ dài dưới 17, trên 4120, hoặc làm vùng đệm tràn là lỗi
giao thức và không đọc thêm.

Dấu xác thực sai (bit lật, phát lại, đảo thứ tự, cắt cụt phần thân cho khớp độ dài giả) làm luồng
hỏng vĩnh viễn. Mọi lời gọi sau trả lại đúng lỗi đó. TCP giữ thứ tự nên không có cửa sổ chống phát
lại: bản ghi chỉ mở được bằng đúng bộ đếm kế tiếp.

Đóng kết nối khi còn mẩu dở của một bản ghi là cắt cụt. Gate đếm và ngắt, không ghép thành tin.

## So sánh và xoá

Mọi so sánh vật liệu khoá đi qua libsodium (`crypto_verify_64`, `crypto_sign_verify_detached`, phép
mở AEAD). Không dùng `memcmp` hay `==` trên byte bí mật.

`sodium_memzero` xoá khoá danh tính, khoá tạm, khoá phiên và vùng đệm bản ghi khi đối tượng huỷ,
khi bị chuyển đi, và khi bắt tay thất bại. Không khoá, không chữ ký, không bản rõ nào được ghi log.

## Khoá danh tính

Tệp đúng 64 byte, dạng bí mật Ed25519 của libsodium (hạt giống 32 byte rồi khoá công khai suy từ
nó). Không có đầu tệp. Nạp lại thì dựng cặp khoá từ hạt giống và so cả 64 byte bằng
`crypto_verify_64`. Sai cỡ hoặc lệch một bit là tệp hỏng: gate từ chối khởi động, không ghi đè.

Thiếu tệp cũng từ chối khởi động. Câu báo trên stderr, mã thoát 2, không in `ready`. Lệnh sinh khoá
là `thienlong_gate --gen-key <đường dẫn>`. Tệp đã có thì lệnh từ chối, không ghi đè. Lệnh in khoá
công khai dạng hex thường ra stdout (64 chữ số) và một câu tiếng Việt ra stderr. Không in nửa bí
mật. Đường dẫn mặc định trong `gate.toml` nằm dưới `SERVER/data/`, thư mục git bỏ qua.

## Khác bản Dev

- Dev tự viết SHA-256, HMAC và PBKDF2 cho mật khẩu. Bước này không băm mật khẩu. Mọi phép dùng ở
  đây là hàm libsodium. Không port mã băm tự viết.
- Dev tự sinh khoá danh tính khi tệp chưa có. Ở đây tệp thiếu là lỗi khởi động. Sinh khoá là một
  lệnh riêng, và không bao giờ ghi đè tệp đã có.
- Dev có cờ bản rõ (`--plain`). Gate không có đường bản rõ. Byte trước khi bắt tay xong không được
  hiểu là tin.
- Dev gắn phiên bản vào nhãn `TLBBSEC1` mà không có trường phiên bản riêng. Ở đây lời chào và bản
  ghi được ký đều mang `u16` phiên bản, và mọi giá trị khác 1 bị từ chối trước khi sinh khoá.
- Dev tách tin lớn thành nhiều bản ghi 16 KiB. Trần bản ghi ở đây là một khung client lớn nhất
  (4104 byte rõ), vì gate chưa gửi tin lớn.
- Vé, bằng chứng giữ khoá và cổng xác thực của Dev chưa làm. Chúng thuộc bước tài khoản.

## Mặt trước của gate

Một luồng tick. Vòng tick 60 Hz. Mỗi tick chờ I/O tới hạn tick kế (`net::Reactor::wait`: cổng hoàn
thành trên Windows, poll trên POSIX), rồi mới đọc, giải mã, chạy đồng hồ và đẩy hộp gửi. Mọi sự
kiện reactor trả về đều được xử lý trong tick đó: reactor đã xoá cờ đọc và số byte gửi xong khi
trả sự kiện, bỏ một sự kiện là socket ấy không được đăng đọc lại. Hết hạn mà phần việc chưa xong thì tick đó tính là trễ.

Đồng hồ là một hàm tiêm được, trả nano giây đơn điệu. Test đẩy đồng hồ bằng tay, không ngủ. Bản chạy
thật đọc `steady_clock`.

Bảng kết nối cấp một lần theo `max_connections`. Mỗi ô có vùng đệm cố định (hai bản ghi nhận, một
khung đang ghép, hộp gửi 1024 byte) và số thế hệ. Tay nắm là chỉ số cộng thế hệ. Ô trống bị tái sử
dụng thì thế hệ tăng, tay nắm cũ không đụng được ô mới. Sau khi bảng đã cấp, đường xử lý một tin
không gọi cấp phát: khung ghi vào vector đã `reserve` từ lúc tạo bảng, hộp gửi là mảng cố định.
Ngân sách bản ghi mỗi lần đọc có thể dừng khi còn bản ghi đã đủ byte; phần đó ở lại vùng nhận và
được mở ở tick sau, không chờ thêm byte từ socket.

Đầy bảng thì gỡ socket nghe khỏi tập chờ, không gọi `accept`, không sập. Có ô trống thì nghe lại.
Vượt trần mỗi IP, dải `deny`, hoặc không thuộc `allow` khi `allow` không rỗng: `accept` rồi huỷ
ngay (RST), không giữ ô. `deny` xét trước `allow`.

`trusted_proxies` khác rỗng thì gate từ chối khởi động. Chưa có giao thức proxy; nhận một địa chỉ
client do bên kia tự khai sẽ là giả mạo IP. Danh sách rỗng là cấu hình đang dùng.

Hạn bắt tay (`handshake_timeout_ms`) tính từ lúc nhận kết nối. Hạn im lặng (`idle_timeout_ms`, khoá
mới trong `gate.toml`) tính từ byte nhận cuối sau khi bắt tay xong. Cả hai do đồng hồ của tick xét
trên mọi ô sống.

Giới hạn tốc độ là thùng token, đơn vị một phần nghìn tin, nạp lại mỗi tick theo
`messages_per_second`, trần bằng một giây tin. Hết token thì ngắt. `client_frame_bytes` là trần thân
khung; giá trị trên 4096 bị từ chối lúc khởi động vì protocol không nhận thân client lớn hơn thế.
`Hello.version` phải nằm trong `[min_version, protocol::kVersion]`.

Tin đầu sau bắt tay phải là `Hello`. Cổng game nhận thêm `Ping` (đáp `Pong`), `Logout` (đáp
`Goodbye` rồi đóng), `Login`, `Resume`, `CreateCharacter`, `DeleteCharacter`, `EnterGame`; cổng
auth nhận `Hello`, `CreateAccount`, `SignIn`. Mã tin không thuộc cổng bị ngắt theo mã tin, không
giải mã thân (thân có thể là mật khẩu). Hộp gửi đầy
vì bên kia đọc chậm thì ngắt kết nối đó.

Mọi độ dài, bộ đếm, mã tin và phiên bản lấy từ byte nhận được đều kiểm trước khi cấp phát hay lặp.
Sai thì ngắt đúng kết nối, tăng bộ đếm, và ghi một dòng stderr nếu còn hạn log (vài dòng mỗi giây).
Dòng log chỉ có địa chỉ IP và tên lý do. Dữ liệu client không đi vào `check`, `assert` hay `.at()`.

Dừng theo giao kèo mục 3.1: stdin hết hoặc tín hiệu console. Gate ngừng nhận, đóng mọi kết nối, thoát
0. `ready` chỉ in sau khi khoá đã nạp và cả hai cổng đã nghe.

`listen.game` và `listen.auth` đều mở.

## Tài khoản qua gate

Đối chiếu mã ngày 2026-10-12 (`src/server/gate/table.cpp`, `src/server/account`).

- Luồng tick không gọi IPC. Tin tài khoản và nhân vật thành một câu hỏi gửi qua `SpscMail` cho
  một luồng thư ký do `Table::set_realm` mở; thư ký gọi `Realm` (TCP tới `127.0.0.1`, bản ghi
  XChaCha20-Poly1305 bằng `ipc.key`), trả lời quay về qua hàng thứ hai và được `Table::collect`
  gửi cho client ở tick sau. Trước ngày này gate gọi `Realm` ngay trong tick, chờ tới 8 giây cho
  mỗi `SignIn` hay `CreateAccount` (Argon2id ở auth), nên một client chưa đăng nhập đóng băng
  được mọi kết nối.
- Mỗi ô có tối đa một câu hỏi đang bay; câu kế được trả `Reject` mã `kBusy`. Hàng thư ký đầy
  (64) thì client nhận `kBusy` ngay, không câu nào bị nuốt. Trả lời về khi ô đã đóng hay đã cấp
  cho kết nối khác thì bị bỏ theo số thế hệ của tay nắm. Mật khẩu, vé và vé năng lực được xoá ở
  cả hai luồng sau khi dùng.
- Dừng: bảng đặt cờ dừng, đánh thức thư ký và chờ nó xong câu đang hỏi (tối đa 8 giây, hạn của
  `Realm`).
- `Resume`: gate giữ SHA-256 của token `SessionStart` (so hằng thời gian), tài khoản, vé năng
  lực và nhân vật. Kết nối rớt vì idle/chậm/đóng thì phiên được giữ 60 giây (`kResumeGraceNs`);
  `Logout` xoá phiên. Token dùng một lần, mỗi lần nối lại cấp token mới; chủ cũ còn sống bị đá bằng
  `Goodbye kLoginElsewhere`. Nối lại đi qua `EnterGame` của store nên cấm/vé/nhân vật được xét lại.
  Lỗi: `kNoSession`, `kSessionExpired`, `kOutOfOrder` (kết nối đã có tài khoản), `kBusy`. Bảng phiên
  tối đa `max(64, 2*max_connections)`.
- Vé năng lực HMAC 8 giờ (`kCapTtlSeconds`) vẫn còn, nhưng store hỏi auth `kStanding` (bảng `ban` +
  `disabled_at`, tham số bind) trước mỗi list/create/delete/enter, kết quả nhớ tối đa 5 giây
  (`StandingCache`, 4096 mục, không nhớ lỗi `kBusy`), auth không trả lời trong 2 giây thì từ chối.
  Cấm có hiệu lực trong ≤5 giây (đo: 5,3 giây). Lúc đổi vé (`redeem`) auth xét cả `disabled_at`
  lẫn bảng `ban`.
- `serve_loop` của auth/store không chặn: tối đa 64 kết nối, mỗi kết nối một khung, hạn đọc 3 giây
  và ghi 3 giây (không tính thời gian DB), hàng việc đầy trả `kBusy`, đầy chỗ thì đuổi kết nối đang
  đọc lâu nhất. Listener Windows đặt `SO_EXCLUSIVEADDRUSE`.
- `guard::Pace` chưa nối vào đường nhận tin: chưa có tin di chuyển và chưa có zone.
