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

## Luật đi của zone (kiểm địa hình)
- Gate chỉ biết tốc độ (`guard::Pace`); zone giữ dữ liệu cảnh nên zone kiểm ô đi được. Mỗi `Moved` gate chuyển sang, `Scene::moved` tra
  luật đi của cảnh (`Scene::Config::walkable`, dựng từ lưới `.path` của client 2026 bằng `zone::walkable_of`, `src/server/zone/content.cpp`).
- Bước từ chỗ đi được sang chỗ không đi được thì zone không dời người chơi mà gửi `ipc::Relay::kPlace` (zone → gate, thân hai `f32`
  x, z cm) về vị trí cũ. Gate đặt mốc mới bằng `Motion::place` theo đồng hồ gate lúc nhận (không dùng `seen_ns` của ô: mốc thời gian cũ
  sẽ cho người chơi đứng yên lâu cộng dồn quãng đường được phép) rồi gửi `Position`. Client thật phải đặt lại vị trí và bộ đếm khi nhận
  `Position`; client không làm vậy thì bước kế bị `guard::Pace` coi là nhảy vọt và bị đá (đo bằng `thienlong_bot`, bot đầu tiên không đặt lại).
- Người chơi đứng sẵn ngoài lưới (điểm lưu cũ, lưới đổi) vào được và đi ra được: chỉ chặn bước từ trong ra ngoài, để không ai bị nhốt.
- Độ nới `kWalkSlackCm` = 20 cm: một điểm đi được khi nó hoặc điểm lệch 20 cm theo bốn hướng đi được. Client đi bằng cùng lưới nên đứng
  trong nó; độ nới chỉ để số thực làm tròn ở mép tam giác không đẩy người chơi ra ngoài (một bước tối đa là 15,5 cm).
- Cảnh không có lưới đi (`WalkSource::kNone`) hoặc không nạp được dữ liệu thì không có luật đi: đi đâu cũng được (thay vì chặn mọi bước).
- Giới hạn đã biết: chỉ kiểm điểm đến, không quét đoạn đường (bước ≤ 15,5 cm nên chỉ xuyên được tường mỏng hơn thế); chưa kiểm trục Y; bảng
  quái 2008 lệch bố cục map 2026 (Đại Lý 50/164 điểm đặt ngoài lưới, `docs/SERVER-SCENEDATA.md` mục 5) nên quái đặt ngoài lưới vẫn đứng đó.
- Kiểm: `walkable_*` và `host_*` trong `zone_tests`; đầu cuối trên cụm thật bằng `thienlong_bot --straight 1` (mỗi bot đi một hướng cho tới khi
  bị kéo về: Đại Lý, 8 bot, 20 giây cho 2.006 lần kéo về, không lần nào cách chỗ bot tưởng mình đứng quá 45 cm).

## Còn thiếu
- Hook hồi sinh / dịch chuyển cố ý chưa có người gọi: `kPlace` đã là đường đi (zone → gate → `Motion::place`), khi thêm chỉ cần
  `Outbox::place`. Không reset `Pace` ở chỗ nào khác.
- Client: gửi `Move` theo nhịp 30/giây, đếm tick từ `Position.tick`, khi nhận `Position` thì đặt lại vị trí và bộ đếm (client đã mở socket từ 2026-10-15 nhưng mới nhận `Position` đầu để đặt chỗ vào game; chưa gửi `Move`).
- Quét đoạn đường và trục Y (xem trên).