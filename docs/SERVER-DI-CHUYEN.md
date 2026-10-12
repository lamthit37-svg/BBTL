# Di chuyển: server làm chủ vị trí

## Nguyên tắc
- Vị trí nhân vật là của **server**. Client chỉ *xin* bước (`Move 0x0301`); server trả vị trí thật (`Position 0x8301`).
- Mọi `Move` đi qua `guard::Pace` (bọc bởi `gate::Motion`, `src/server/gate/motion.*`). Thời gian đo bằng
  **đồng hồ đơn điệu của gate** (`motion_tick(now_ns)`, 30 tick/giây); tick client chỉ là trần dưới, không mua thêm quãng đường.
- Mốc (anchor) chỉ do server đặt: khi vào game (`finish_enter`), và sau này khi hồi sinh / dịch chuyển hợp lệ
  (gọi `Motion::place`). Bước đầu của client không bao giờ thành mốc.

## Xử lý theo kết quả Pace
| Verdict | Gate làm gì |
|---|---|
| `kOk` | nhận, mốc dời theo bước |
| `kRejected` (NaN/vô cực, vượt tốc một lần, tick lùi) | gửi `Position` kéo về mốc + tick client của bước nhận gần nhất |
| `kSpeed` / `kTeleport` (vi phạm lặp lại) | `Goodbye kKicked`, đóng phiên (fail-closed) |
| chưa có mốc | `Reject(Move, kOutOfOrder)` |

`Move` sai độ dài / thừa byte: bộ giải mã từ chối → `Goodbye kProtocolViolation` như mọi tin khác.
`Move` vẫn tốn credit rate-limit như mọi tin.

## Mốc khi vào game và Resume
- `EnterGame`: store trả điểm vào của nhân vật trong trả lời `Op::kEnter` (thân: `scene` u16, `x_cm` i32, `z_cm` i32).
  Nguồn là cột `player.position_x/position_z` (mét, nhân vật mới lấy từ `rules/new_character.toml`), store đổi sang
  centimet nguyên bằng `round(x * 100)`. Gate đặt `Motion::place` đúng điểm đó rồi gửi `Position`.
- Fail-closed: hàng hỏng, toạ độ ngoài `±kSpotLimitCm` (100 km) hoặc thân sai cỡ thì không vào (`kBusy`), không
  bao giờ rơi về `(0,0)`. Phiếu standing của auth vẫn thân rỗng, không lẫn với trả lời enter.
- `Resume`: phiên rớt giữ mốc cuối server đã nhận (`Session.spot`); kết nối cũ còn sống thì lấy mốc của nó.
  Resume đặt lại đúng mốc đó (store chưa lưu vị trí giữa phiên). Không có mốc thì dùng điểm trong store.

## Còn thiếu
- Store chưa ghi vị trí khi rời game: đăng nhập lại (không Resume) về điểm lưu trong DB. `scene` đã về gate nhưng chưa dùng.
- Hook hồi sinh / dịch chuyển chưa tồn tại; khi thêm phải gọi `Motion::place` (không reset Pace ở chỗ nào khác).
- Client: gửi `Move` theo nhịp 30/giây, đếm tick từ `Position.tick`, khi nhận `Position` thì đặt lại vị trí và bộ đếm.
- Chưa kiểm va chạm/địa hình (navmesh) và trục Y.