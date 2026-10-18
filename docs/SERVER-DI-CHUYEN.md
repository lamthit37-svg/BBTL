# Di chuyển: server làm chủ vị trí

## Nguyên tắc
- Vị trí nhân vật là của **server**. Client chỉ *xin* bước (`Move 0x0301`); server trả vị trí thật (`Position 0x8301`) khi phải kéo về.
- Port ngữ nghĩa máy chủ 2008 (`Obj_Logic_Move`, `Obj_Character_Logic.cpp:449-544`): mỗi `Move` của client được xếp vào **đường đi**,
  máy chủ tự đi dọc đường đó với tốc độ của nó (`guard::Pace`, bọc bởi `gate::Motion`, `src/server/gate/motion.*`). Vị trí máy chủ
  không bao giờ lấy từ con số client khai nên không có hack tốc độ; không đóng phiên vì tốc độ (H1-B, chốt 2026-10-18).
- Thời gian đo bằng **đồng hồ đơn điệu của gate** (`motion_tick(now_ns)`, 30 tick/giây); tick client chỉ để phát hiện tick lùi, không
  mua thêm quãng đường.
- Mốc (anchor) chỉ do server đặt: khi vào game (`finish_enter`), hồi sinh / dịch chuyển hợp lệ và khi zone kéo về (`Motion::place`).
  Bước đầu của client không bao giờ thành mốc.

## Cách đi theo (guard::Pace)
- Quỹ quãng đường nạp ở `kRunCmPerSec × kSlack` = 465 × 1,05 = **488 cm/s**, trần `kBankCm` = **500 cm**
  (`DEF_SERVER_ADJUST_POS_WARP_DIST` của gốc, `Common/GameDefine.h:538`). Đứng yên bao lâu rồi lao xa cũng chỉ nhảy tối đa 500 cm, phần
  còn lại máy chủ đi dần ở 488 cm/s. Chạy gấp 1,5 hay 2 lần: vị trí máy chủ bị bóp ở 488 cm/s, màn hình client đi trước.
- `Move` hợp lệ **không dời mốc ngay**: nó thành điểm cuối của hàng đợi (`kNodes` = 512 bước). Mỗi lần gate gọi `Motion::chase`
  (ngay sau mỗi `Move`, và mỗi nhịp 60 Hz của vòng gate cho các ô còn đường chờ, `Engine::chasing`) Pace đi dọc hàng đợi tới hết quỹ.
  Client dừng gửi `Move` thì máy chủ vẫn đi nốt phần đã nhận rồi khép lại.
- Hàng đợi các chỗ client đã khai, không đuổi thẳng tới chỗ client: gate không có lưới đi (không `FindPath` như gốc), mà mỗi đoạn client
  đã đi qua nằm trên lưới đi của client. Đuổi thẳng từ vị trí đang trễ (có thể 9 m) cắt góc xuyên tường và bị zone hoàn bước; đi dọc đường
  client đã đi thì không.
- Zone luôn nhận đúng những gì máy chủ đã đi: mỗi lần `chase` báo `ipc::Moved` cho từng điểm đi qua (cách nhau tối thiểu `kTrailCm` = 20 cm,
  bằng bước lấy mẫu tường của B19), nên vị trí zone luôn bằng mốc của Pace và mỗi đoạn báo chỉ dài tối đa quỹ (≤ 25 mẫu tường).

## Xử lý theo kết quả Pace
| Verdict | Gate làm gì |
|---|---|
| `kOk` | xếp vào đường đi; gate gọi `chase` để máy chủ đi theo, báo zone |
| `kRejected` (NaN/vô cực, tick lùi) | gửi `Position` kéo về mốc + tick client của bước nhận gần nhất; bỏ đường chờ |
| `kResync` (client lệch quá `resync_cm`, hoặc đầy 512 bước) | như `kRejected`, không phạt |
| chưa có mốc | `Reject(Move, kOutOfOrder)` |

`resync_cm` = `kRunCmPerSec × idle_timeout` (6975 cm ở cấu hình dev, idle 15 giây): quãng một người thật chạy được trong một hạn idle, vì
đứng mạng lâu hơn thế thì phiên đã bị đóng vì không có tin. Không phải ngưỡng gian lận (tốc độ đã bị bóp), chỉ là chỗ cắt lệch tích luỹ.
Gấp 4 lần tốc độ chạy bị kéo về sau ~5,1 giây, gấp 2 lần sau ~15,8 giây, gấp 1,5 lần sau ~33 giây.

`Move` sai độ dài / thừa byte: bộ giải mã từ chối → `Goodbye kProtocolViolation` như mọi tin.

## Hạn tin nhắn của Move
Bình chứa chung (`messages_per_second` = 60 tin) làm đóng phiên người chơi thật khi mạng đứng quá ~3 giây rồi xả dồn các `Move` đã giữ
(client gửi 20 Move/giây): đo trên cụm trước sửa, log gate "vượt số tin mỗi giây". Nay `Move` có bình riêng (`gate.toml [limits]`
`moves_per_second` = 25, `move_burst` = 320; thiếu khoá thì dùng mặc định đó): chứa trọn hạn idle (15 giây × 20 Move = 300) đứng mạng rồi
xả dồn, nạp chỉ hơn nhịp client thật chút ít nên xả Move liên tục (60 mỗi giây) vẫn bị ngắt (`Drop::kRate`) sau chừng 9 giây. Ràng buộc:
`move_burst` ≥ nhịp Move của client × `idle_timeout_ms` / 1000, để mạng đứng chưa tới hạn idle không bị bình tin ngắt. Mọi tin khác giữ bình
60 tin như cũ. Hạn idle 15 giây (chốt 2026-10-18) khác gốc: gốc kick sau `KickUserTime` 300000 ms, gate không có bộ đệm không đáy nên giữ ngắn.
Khác gốc: gốc không đóng phiên vì nhịp tin; `Player::ProcessCommand` (`Player/Player.cpp:162`, `EXE_COUNT_PER_TICK` = 12) xử lý tối đa 12 tin
mỗi nhịp cho một người và giữ phần dư trong bộ đệm đầu vào 64 MB, chỉ `KickUserTime` 5 phút im lặng. Gate không có bộ đệm không đáy nên
vẫn ngắt khi xả liên tục.

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
  sẽ cho người chơi đứng yên lâu cộng dồn quãng đường được phép) rồi gửi `Position`; đường chờ cũ bị bỏ. Client thật phải đặt lại vị trí và
  bộ đếm khi nhận `Position`; client không làm vậy thì đường nó khai tiếp bị coi là nhảy vọt (đo bằng `thienlong_bot`, bot đầu tiên không đặt lại).
- Người chơi đứng sẵn ngoài lưới (điểm lưu cũ, lưới đổi) vào được và đi ra được: chỉ chặn bước từ trong ra ngoài, để không ai bị nhốt.
- Độ nới `kWalkSlackCm` = 20 cm: một điểm đi được khi nó hoặc điểm lệch 20 cm theo bốn hướng đi được. Client đi bằng cùng lưới nên đứng
  trong nó; độ nới chỉ để số thực làm tròn ở mép tam giác không đẩy người chơi ra ngoài (một bước tối đa là 15,5 cm).
- B19: `Scene::blocked` lấy mẫu dọc đoạn đi, cách nhau `kStepSampleCm` = 20 cm, nên tường dày hơn 40 cm không lọt giữa hai mẫu.
- Cảnh không có lưới đi (`WalkSource::kNone`) hoặc không nạp được dữ liệu thì không có luật đi: đi đâu cũng được (thay vì chặn mọi bước).
- Giới hạn đã biết: chưa kiểm trục Y; bảng quái 2008 lệch bố cục map 2026 (Đại Lý 50/164 điểm đặt ngoài lưới, `docs/SERVER-SCENEDATA.md` mục 5) nên
  quái đặt ngoài lưới vẫn đứng đó.
- Kiểm: `walkable_*` và `host_*` trong `zone_tests`; `guard_tests`, `gate_motion_tests`; đầu cuối trên cụm thật bằng `thienlong_bot`
  (`--straight`, `--leap`, `--rush`, `--stall`, `--jump`, bot quan sát `--peers --cap`), số liệu ở `docs/giao-viec/HOAN-THIEN/H1-M.md`.

## Còn thiếu
- Hook hồi sinh / dịch chuyển cố ý chưa có người gọi: `kPlace` đã là đường đi (zone → gate → `Motion::place`), khi thêm chỉ cần
  `Outbox::place`. Không reset `Pace` ở chỗ nào khác.
- Tốc độ máy chủ cố định 488 cm/s, chưa theo `Stat::kMoveSpeed`, ngựa hay buff tốc độ (`docs/NGHI-NGO.md` 81, 87).
- Quét trục Y (xem trên).
