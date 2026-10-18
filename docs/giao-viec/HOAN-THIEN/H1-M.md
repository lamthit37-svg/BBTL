# H1-M: hack tốc độ (phương án B) và B19 (kiểm đoạn đi)

Làn M (`thienlong-6a`, từ 2026-10-18 chiều `bd` tiếp quản), nền `77d444a0`. Việc đệm của G0-M "Để dành cho H1", gói HO-SO mục
5.11 (M: "H1 cùng B19, kèm chế độ bot gửi Move nhanh để chứng minh bị kéo về"). Kiểm chéo do làn K (`c5`).

## Trạng thái (2026-10-18)

- **B19** (`Scene::blocked` kiểm cả đoạn đi): XONG. Dựng lại từ đầu trên cây tách, E2E xanh/đỏ/xanh lại trên cụm thật (mục
  "Đã chạy"); kiểm chéo của `c5` ĐẠT 2026-10-18 (ctest đầy đủ 192/192). Commit riêng.
- **H1 phương án A** (quỹ quãng đường nạp ở tốc độ trần): KHÔNG ĐẠT điểm 1 (kiểm chéo K: quỹ 2 s đóng phiên người chơi thật
  khi mạng đứng từ 2,4 s). Đã thử cỡ quỹ 2, 5, 10, 15 s: không cỡ nào thoả cả hai (mục "Phương án A đã bỏ"). Bỏ, lưu ở
  `D:\THIENLONG-luu-tru\h1-phuong-an-a\`.
- **H1 phương án B** (port ngữ nghĩa gốc: máy chủ làm chủ vị trí): điều phối `5f` chọn 2026-10-18. ĐÃ LÀM trên cây tách
  `.worktrees/h1b` (mục "Phương án B, đã làm"), chờ kiểm chéo `c5` rồi commit.

## Bằng chứng gốc (mã máy chủ 2008, `D:\TÀI LIỆU TLBB\tlbb_server\Server\GameServer\Server`)

- `Packets/CGCharMoveHandler.cpp:70` đẩy đường client gửi vào `AI/AI_Human.cpp:502` `PushCommand_Move`, rồi
  `AI/AI_Character.cpp:152-201` `Move`: máy chủ tự `FindPath` từ VỊ TRÍ MÁY CHỦ qua lưới đi được tới từng nút client gửi, cắt ở
  nút đầu tiên không tới được (`OR_CUT_PATHROUTE`); đường mới thay đường cũ, không xếp hàng.
- `Obj/Obj_Character_Logic.cpp:449-544` `Obj_Logic_Move`: mỗi nhịp tiến `GetMoveSpeed() × GetLogicTime() / 1000` dọc đường;
  `GetLogicTime()` = `m_uNowTime - m_uLastTime` (`Obj/Obj.h:119`), không cắt trần. Vị trí máy chủ không bao giờ vượt tốc độ
  nhân thời gian. Không có bộ đếm vượt tốc, không đóng phiên vì tốc độ, không cửa sổ cho gói dồn: kẻ gian chỉ làm lệch màn
  hình của chính mình.
- `Packets/CGCharPositionWarpHandler.cpp:47-64`: client chỉ bắt máy chủ dời về vị trí client khi vị trí máy chủ client báo khớp
  thật (lệch ≤ 0,1) và hai vị trí lệch ≤ `DEF_SERVER_ADJUST_POS_WARP_DIST` = 5,0 (`Common/GameDefine.h:538`). Đơn vị là mét:
  tốc độ 4,65 tương ứng 465 cm/s (`Assert(fSpeed > 0.1 && fSpeed < 20.0)` ở `Obj_Character_Logic.cpp:472`). Lệch hơn thì máy
  chủ giữ vị trí của nó.
- Hạn im lặng duy nhất: `KickUserTime` = 300000 ms (`G:\XJL7457\Server\...\Config\ConfigInfo.ini:21`,
  `WorldServer/World/WorldData/User.cpp:388-433`).
- Hệ quả: gốc chịu đứng mạng tới 5 phút và hack tốc độ không có lời nào, vì không bao giờ tin vị trí client. Giao thức của ta
  tin vị trí client (`Move` mang x, z), nên chỉ có thể làm gần gốc bằng cách để máy chủ đi theo (Phương án B).
- B19 không có bản tương ứng để giữ toán tử (gốc dùng FindPath): ghi `// Khác gốc:` ở `Scene::blocked`.

## B19: quyết định và công cụ

- Lỗi (`zone/scene.cpp` `Scene::blocked` trước sửa): chỉ tra điểm đến (cộng độ lệch 20 cm). Bước dài qua một bức tường dày vẫn
  rơi vào chỗ đi được ở bên kia.
- Sửa: `Scene::blocked` lấy mẫu dọc đoạn đi, cách nhau `kStepSampleCm` = 20 cm (bằng độ lệch của luật đi), bằng đúng hàm
  `walkable`. Tường dày hơn hai lần độ lệch không lọt giữa hai mẫu. Người đứng ở chỗ không đi được vẫn không bị kiểm gì (luật
  gốc, D4 của G1-M đã đưa điểm sinh ra khỏi vật cản). `Scene::clear_line` nhận bước mẫu: quái vẫn dùng 100 cm.
- Bot `thienlong_bot --leap 1 --walk <walk.path>`: đứng yên 2,2 giây (để giới hạn từng bước của `guard::Pace` đủ dài), gửi MỘT
  Move dài tới điểm đi được nằm sau tường, rồi một Move cùng khoảng cách tới điểm thông. Thoát 0 khi bước xuyên tường bị đặt lại
  (Position) còn bước tới điểm thông được nhận: đối chứng chứng minh việc đặt lại là do tường chứ không do giới hạn quãng.

### Đã chạy (2026-10-18, cây tách `build/lane-server` dựng lại từ đầu, `scratchpad/b19_final.ps1`)

- Dựng `lane-server` từ đầu: 0 cảnh báo (`build/lane-server-build-b19.log`). ctest máy chủ 14/15 xanh
  (`build/lane-server-ctest-b19b.log`; ca còn lại `server_boot_source_clean` chưa dựng lúc đó, dựng rồi chạy riêng: xanh,
  `build/lane-server-ctest-b19c.log`). `zone_tests` có thêm `walkable_blocks_step_through_wall` (đỏ chứng minh bằng E2E bên
  dưới, vì zone cũ không còn trong cây). `shape.js --diff .`: 0 vi phạm trên dòng đã đổi (`build/shape-b19.log`).
- E2E trên cụm thật, `thienlong_bot` trên Đại Lý (`build/e2e/B19/m/`). Bản đỏ dựng NGOÀI cây làm việc bằng lệnh Ninja của
  chính cụm (`Scene::blocked` quay về chỉ tra điểm đến, `red_zone_build.py`); `git diff` không dính dòng vá; trả zone về bản
  dựng và so SHA-256: trùng.

| Phép thử | Zone | Kết quả |
|---|---|---|
| `--leap 1` | mới | thoát 1: EnterGame bị từ chối mã 16 (`kBusy`), chưa vào cảnh (`leapgreen-out.txt`); xem `NGHI-NGO.md` 74 (4) |
| `--leap 1` | chỉ tra điểm đến | `leap 400 cm: tường lọt qua, thông bị đặt lại`, thoát 1 (`leapred-out.txt`) |
| `--leap 1` | mới, sau khi trả về | `leap 400 cm: tường bị đặt lại, thông được nhận`, thoát 0 (`leapgreen2-out.txt`) |

- Lần xanh đầu hỏng vì `kBusy` lúc cụm vừa khởi động, không phải vì B19; lần xanh thứ hai (cùng exe, SHA-256 trùng) đạt, và
  sáu bot chạy liên tiếp từ 2 s sau `start` đều vào được (`build/b19-busy.log`). Chưa tái hiện được lần hỏng đầu.
- Không phạt oan: `thienlong_bot --count 4 --seconds 8` đi vòng tròn 4 khách, thoát 0, 0 lần kéo về, 0 lệch;
  `--straight 1 --count 4` đi thẳng vào tường, thoát 0, 444 lần kéo về do tường, 0 lệch (`walk-out.txt`, `straight-out.txt`).
  `e2e_g0.py` 6/6 ĐẠT (`e2e_g0-out.txt`, kịch bản `talk` thoát 1 "chưa nhận được nhiệm vụ nào", `e2e_g0.py` vẫn chấm ĐẠT theo bảng kỳ vọng của nó).

### Chưa kiểm

- B19 trên cảnh `legacy_nav` (lưới ô): E2E chỉ chạy trên Đại Lý (lưới `.path`). `NGHI-NGO.md` 74.
- Client giật khung vài trăm ms phát một Move dài quanh góc lồi: có thể cắt qua mép tường và bị hoàn bước. `NGHI-NGO.md` 74.

## Phương án A đã bỏ (quỹ quãng đường)

`guard::Pace` có quỹ nạp ở `465 × 1,05 / 30` cm mỗi tick máy chủ, cỡ quỹ nhận từ ngoài; bước vượt quỹ bị từ chối, lặp lại thì
đóng phiên. Mô phỏng (client 4,65 m/s, Move 50 ms, như K): cỡ quỹ vừa là thời gian đứng mạng chịu được vừa là cú lao hợp lệ
tối đa của kẻ gian.

| Cỡ quỹ | Đứng mạng bị đóng từ | Lao tối đa sau khi đứng yên | Gấp 1,5 lần bị đóng ở | Gấp 2 lần bị đóng ở |
|---|---|---|---|---|
| HEAD (không quỹ) | không bao giờ | không giới hạn | không bị bắt trong 60 s | không bị bắt trong 60 s |
| 2 s | 2,4 s | 977 cm | 4,70 s | 2,30 s |
| 5 s | 6 s | 2441 cm | 11,7 s | 5,6 s |
| 10 s | 12 s | 4883 cm | 23,35 s | 11,15 s |
| 15 s | trên 12 s (chưa đo 15) | 7324 cm | 35 s | 16,65 s |

Gấp 4 lần: đóng ở 0,15 s với mọi cỡ. Điều phối bác vì không có số trong gốc, quỹ lớn mở cú lao 49 m, quỹ nhỏ phạt oan. Bản vá,
mô phỏng và README: `D:\THIENLONG-luu-tru\h1-phuong-an-a\`.

## Phương án B, đã làm (2026-10-18, cây tách `.worktrees/h1b`)

Port ngữ nghĩa gốc: máy chủ làm chủ vị trí, không đóng phiên vì tốc độ. Mọi phần không có trong gốc ghi `// Khác gốc:`.

### Thiết kế

- `guard::Pace` (`src/server/guard/pace.*`): `Move` hợp lệ chỉ xếp một nút vào hàng đợi đường đi của ô (`kNodes` = 512). `advance` mỗi tick
  máy chủ (30 Hz) đi dọc hàng đợi bằng quỹ quãng đường: nạp 465 × 1,05 cm/s (16,275 cm mỗi tick), trần `kBankCm` = 500 cm
  (`DEF_SERVER_ADJUST_POS_WARP_DIST`). Mốc chỉ do Pace dời; không bao giờ lấy từ con số client khai. Kết quả: `kOk`, `kRejected`
  (tick lùi, NaN, vô cực), `kResync` (hàng đợi dài hơn `resync_cm` hoặc đầy), `kNoAnchor`. Đã bỏ `kSpeed`, `kTeleport` và nợ vi phạm.
- `gate::Motion` + `gate/table.cpp`: gọi `chase` ngay sau mỗi `Move` và mỗi nhịp của vòng gate cho các ô còn đường chờ
  (`Engine::chasing`), để client dừng gửi thì máy chủ vẫn đi nốt phần đã nhận. Mỗi điểm đi qua (cách nhau tối thiểu 20 cm, tối đa
  27 điểm một lần) báo `ipc::Moved` cho zone; kiểm đoạn B19 của zone giữ nguyên.
- Quyết định chưa chốt ở bản thảo (đuổi thẳng hay hàng đợi): chọn hàng đợi. Gate không có lưới đi như `FindPath` của gốc, mà mọi
  đoạn client đã đi nằm trên lưới đi của client; đi dọc đường đó thì không cắt góc qua tường, đuổi thẳng từ chỗ trễ vài mét thì có.
- Hằng số nằm trong mã, không vào `rules/*.toml`: gốc không có cấu hình tương ứng (`DEF_SERVER_ADJUST_POS_WARP_DIST` là `#define`),
  `default_move_speed` chưa xác lập đơn vị (`NGHI-NGO.md` 81). `resync_cm` suy từ `idle_timeout_ms`: 465 × 15 s = 6975 cm.
- Bình chứa tin của `Move` riêng (khác gốc, `NGHI-NGO.md` 89): `gate.toml [limits] moves_per_second` = 25, `move_burst` = 320, thiếu khoá
  thì dùng hai số đó. Lý do: bình chung 60 tin đóng phiên người chơi thật khi mạng đứng quá ~3 giây rồi xả dồn Move (đo trên cụm HEAD,
  log "vượt số tin mỗi giây"). Gốc không đóng phiên vì nhịp tin (`Player::ProcessCommand`, `EXE_COUNT_PER_TICK` = 12, bộ đệm đầu vào
  64 MB), nhưng gate không có bộ đệm không đáy nên vẫn ngắt khi xả liên tục. Ràng buộc (điều phối chốt): `move_burst` ≥ nhịp Move của
  client × `idle_timeout_ms` / 1000, để mạng đứng chưa tới hạn idle không bị bình tin ngắt.
- `idle_timeout_ms` nâng 10000 → 15000 (điều phối chốt 2026-10-18): đủ cho mạng đứng 10 giây có dư mà socket chết vẫn được giải phóng
  nhanh. Khác gốc: gốc kick sau `KickUserTime` 300000 ms (`Player.cpp`), gate không có bộ đệm không đáy nên giữ ngắn.
- Triển khai: `gate.toml` có hai khoá mới nên `thienlong_server` (giám sát), `thienlong_gate` và `thienlong_lint` phải dựng lại cùng lượt; giám sát
  cũ từ chối "khoá lạ moves_per_second" và cụm không khởi động (đo 2026-10-18, `build/e2e/H1B/`).
- Test giữ ở ca có hợp đồng: `guard_tests` 12 ca, `gate_motion_tests` 10 ca, `config_tests` thêm `gate_move_bucket_is_bounded`; `online_tests.cpp`
  của làn K chỉ đổi chỗ gọi Pace (`run_pace`).

### Mô phỏng (mã Pace thật, client chạy 4,65 m/s, Move 50 ms, chase 30 Hz)

Đứng mạng S giây (client chạy 3 s trước, đi tiếp S + 3 s, rồi dừng):

| S (s) | Kéo về | Từ chối | Lệch tối đa (cm) | Nhảy lúc dồn gói (cm) | Khép sau khi client dừng (s) |
|---|---|---|---|---|---|
| 1 | 0 | 0 | 480 | 488 | 0 |
| 3 | 0 | 0 | 1410 | 500 | 1,73 |
| 5 | 0 | 0 | 2340 | 500 | 3,63 |
| 8 | 0 | 0 | 3728 | 500 | 6,47 |
| 10 | 0 | 0 | 4658 | 500 | 8,42 |
| 12 | 0 | 0 | 5588 | 500 | 10,32 |
| 14 | 0 | 0 | 6518 | 500 | 12,22 |
| 14,5 | 0 | 0 | 6750 | 500 | 12,68 |
| 15 | 1 | 0 | 6983 | 0 | không (kéo về) |

(`resync_cm` = 6975 cm cho idle 15 giây; bản idle 10 giây cho cùng cột nhưng kéo về từ S = 10.) Đứng yên S giây rồi một Move xa 3000 cm:
nhảy 49 cm (S = 0,1), 488 cm (S = 1), 500 cm (S từ 5 tới 120). Client chạy gấp F lần trong 60 s:

| F | Tốc độ máy chủ tối đa, cửa sổ 1 s (cm/s) | Kéo về lần đầu (s) | Số lần kéo về |
|---|---|---|---|
| 1,00 | 464,5 | không | 0 |
| 1,05 | 487,7 | không | 0 |
| 1,20 | 487,7 | không | 0 |
| 1,50 | 487,7 | 33,22 | 1 |
| 2,00 | 487,7 | 15,80 | 3 |
| 4,00 | 487,7 | 5,12 | 11 |

### E2E trên cụm thật (`build/e2e/H1B/`; `red` = HEAD v10; `final` = bản H1-B chốt: `idle_timeout_ms` 15000, `move_burst` 320)

Cặp bot: bot gian lận (`thienlong_bot`) và bot quan sát (`--peers 1`) đọc `EntityPos` của nó. Kết luận lấy từ dòng in ra của bot, vì
`Start-Process -PassThru` không trả mã thoát trên máy này. Cụm chạy `thienlong_gate`, `thienlong_server`, `thienlong_lint`, `thienlong_bot` dựng
từ cây tách, `gate.toml` của cây tách; `final/gate-ngat.txt` là các lý do gate ngắt kết nối trong cả đợt.

| Ca | HEAD v10 (đỏ) | H1-B chốt (xanh, `final/`) |
|---|---|---|
| `--stall 1`, `3`, `5`, `9` | `5`, `9` bị đóng phiên (bình 60 tin) | còn phiên, 0 lần kéo về, chỗ máy chủ cuối trùng chỗ client khai; quan sát 1 s: 700 / 712 / 495 / 494 cm/s |
| `--stall 10`, `12`, `14` | không đo | còn phiên, 0 lần kéo về, chỗ máy chủ cuối trùng chỗ client khai; quan sát 495 / 495 / 503 cm/s (14 s xả 280 Move, dưới 320) |
| `--stall 16` | không đo | bị đóng phiên bởi `idle_timeout_ms` = 15000 (log "im lặng quá hạn"), không do Pace hay bình tin |
| `--flood 60` (thật 58 Move/s) | không đo | bị đóng ở 9,7 s, log "vượt số tin mỗi giây" (320 / (58 - 25) = 9,7 s) |
| `--rush 150`, `200` | 150: máy chủ đi 592 cm/s, không bóp; 200: bị đóng phiên | còn phiên, máy chủ đi 502 và 495 cm/s (trần 560), 0 lần kéo về |
| `--rush 400` | bị đóng phiên | còn phiên, máy chủ 494 cm/s, kéo về 9 lần (nguyên nhân chưa tách: hết hạn `resync_cm` hay zone kéo về do tường); chỗ máy chủ cuối (16416, 16882) cách chỗ client khai (16557, 17211) |
| `--jump 8` (đứng 8 s rồi một Move 1500 cm) | bước nhảy 1499 cm một lần | bước lớn nhất 499 cm rồi đi dần tới đúng chỗ khai (15926, 18357) (`final2/`, chạy lại sau khi dữ liệu cảnh trở về) |
| `--leap 1 --walk` (B19) | không đo | "tường bị đặt lại, thông được nhận", 1 lần kéo về (`final2/`) |

- Quan sát 700 và 712 cm/s ở `--stall 1`, `3` cao hơn trần đi đều vì cửa sổ 1 giây chứa phần xả quỹ 500 cm; giới hạn lý thuyết của một cửa sổ là
  quỹ 500 cm cộng 488 cm/s. Chưa tách được vì sao các ca 5 giây trở lên không lặp lại (giả thuyết: cú xả rơi giữa hai cửa sổ). Bước lớn nhất giữa
  hai mẫu `EntityPos` là 306 cm (`--stall 1`) và 48 cm (các ca còn lại).
- Cả đợt `final`: log cụm chỉ có đúng một dòng "im lặng quá hạn" (ca `stall16`) và một dòng "vượt số tin mỗi giây" (ca `flood60`).
- `--flood` lần đầu (`green/flood60-*`, bot cũ) không hợp lệ: bot chỉ gửi ~32 Move/s (timer 15 ms của Windows), thấp hơn nhịp nạp 25 Move/s cộng
  sức chứa nên chưa tới hạn. Sửa bot gửi theo đợt rồi chạy lại (`green2/`: 53 Move/s thật, 250 / (53 - 25) = 8,9 s khớp 8,7 s đo được).
- Lượt chạy đầu với `gate.toml` mới hỏng vì cụm không khởi động: `thienlong_server` (v10) từ chối hai khoá mới (`green3/` toàn `lỗi=1`). Dựng và cài lại
  `thienlong_server`, `thienlong_lint` cùng `thienlong_gate` rồi chạy lại (`final/`).
- Không phạt oan (`final2/`): `--count 4 --seconds 8` 4 khách vào, thấy đủ nhau, 0 lần kéo về, 0 lệch; `--straight 1 --count 4` 675 lần kéo về do tường,
  0 lệch; `e2e_g0.py` 6/6 ĐẠT (`talk` thoát 1 "chưa nhận được nhiệm vụ nào", như mốc B19, `e2e_g0.py` vẫn chấm ĐẠT theo bảng kỳ vọng của nó).
- Lượt chốt đầu (`final/`) chạy `--jump`, `--leap` và `e2e_g0.py` đúng lúc `dev/server/scenes`, `dev/server/tables`, `dev/server/sql` của cây chính bị xoá
  khỏi cây làm việc (4759 tệp ` D`, thư mục sửa lúc 12:50, không do H1-B; `5f` khôi phục bằng `git checkout --`): bot báo "không đọc được lưới
  đi ... walk.path", `talk` và `fight` hỏng. Ba phép đó đã chạy lại (`final2/`) sau khi dữ liệu trở về và đều đạt. `final/` giữ làm bằng chứng của lượt hỏng.

### Chưa kiểm và tồn đọng

- Mạng đứng thật của client K (không giả bằng bot): chưa đo; hai số 25 và 320 suy từ nhịp 20 Move/s và hạn idle (`NGHI-NGO.md` 89).
- Đứng mạng từ 15 s vẫn đóng phiên bởi `idle_timeout_ms`; muốn chịu lâu hơn thì đổi `gate.toml` (và `move_burst` theo ràng buộc), đánh đổi là hạn ngồi
  không của kẻ giữ kết nối.
- Vị trí máy chủ trễ client khi client còn chạy sau đứng mạng (`NGHI-NGO.md` 88); tốc độ cố định 488 cm/s, chưa theo ngựa hay buff (`NGHI-NGO.md` 87).
- Giới hạn hàng đợi bước (`NGHI-NGO.md` 90).
- Trần số mẫu của kiểm đoạn (kiểm chéo B19 của `c5`): nay tối đa 27 điểm mỗi lần `chase` nên mỗi `Moved` chỉ chứa quãng của quỹ, tối đa 25 mẫu tường.
- `TOOLS/cfgtool/test_cfgtool.py` đỏ hai ca (`test_validator_matches_server_on_mutations`, `test_set_value_keeps_comment_and_alignment`) cả trên cây chính
  chưa sửa: cfgtool chưa biết khoá `allowed_builds` của `[client]` (có từ trước H1-B). Ngoài phạm vi.
- B1 (khung zone lớn hơn một bản ghi mật 4104 byte bị bỏ): gói riêng sau H1-B. Đã đo: chưa có tin thật nào vượt (`NGHI-NGO.md` 75).
