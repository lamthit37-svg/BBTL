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

## Còn thiếu
- Gate chưa có dữ liệu điểm sinh của nhân vật: tạm đặt mốc `(0,0)` khi vào game. Cần store trả toạ độ trong
  `EnterReply` (hoặc zone server cấp) rồi truyền vào `Motion::place`.
- Hook hồi sinh / dịch chuyển chưa tồn tại; khi thêm phải gọi `Motion::place` (không reset Pace ở chỗ nào khác).
- Client: gửi `Move` theo nhịp 30/giây, đếm tick từ `Position.tick`, khi nhận `Position` thì đặt lại vị trí và bộ đếm.
- Chưa kiểm va chạm/địa hình (navmesh) và trục Y.