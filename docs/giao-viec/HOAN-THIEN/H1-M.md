# H1-M: hack tốc độ (phương án B) và B19 (kiểm đoạn đi)

Làn M (`thienlong-6a`, từ 2026-10-18 chiều `bd` tiếp quản), nền `77d444a0`. Việc đệm của G0-M "Để dành cho H1", gói HO-SO mục
5.11 (M: "H1 cùng B19, kèm chế độ bot gửi Move nhanh để chứng minh bị kéo về"). Kiểm chéo do làn K (`c5`).

## Trạng thái (2026-10-18)

- **B19** (`Scene::blocked` kiểm cả đoạn đi): XONG. Dựng lại từ đầu trên cây tách, E2E xanh/đỏ/xanh lại trên cụm thật (mục
  "Đã chạy"); kiểm chéo của `c5` ĐẠT 2026-10-18 (ctest đầy đủ 192/192). Commit riêng.
- **H1 phương án A** (quỹ quãng đường nạp ở tốc độ trần): KHÔNG ĐẠT điểm 1 (kiểm chéo K: quỹ 2 s đóng phiên người chơi thật
  khi mạng đứng từ 2,4 s). Đã thử cỡ quỹ 2, 5, 10, 15 s: không cỡ nào thoả cả hai (mục "Phương án A đã bỏ"). Bỏ, lưu ở
  `D:\THIENLONG-luu-tru\h1-phuong-an-a\`.
- **H1 phương án B** (port ngữ nghĩa gốc: máy chủ làm chủ vị trí): điều phối `5f` chọn 2026-10-18. Làm sau G2-M, gói riêng
  (mục "Phương án B, đã chọn"). HEAD không xấu đi trong lúc chờ (Pace vẫn là bản cũ).

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

## Phương án B, đã chọn 2026-10-18

Port ngữ nghĩa gốc: máy chủ làm chủ vị trí, không đóng phiên vì tốc độ. Làm sau G2-M, gói riêng, kiểm chéo `c5`.

Thiết kế (mọi phần không có trong gốc ghi `// Khác gốc:`):

- `Pace::observe` thêm kết quả `kClamped`: Move vượt quỹ thì mốc chỉ dời tới chỗ quỹ cho phép, theo hướng về vị trí client; gate
  relay vị trí đã cắt (`Pace::anchor()`) thay vì vị trí client. Không phạt, không đóng phiên. Quỹ nhỏ bằng
  `DEF_SERVER_ADJUST_POS_WARP_DIST` = 500 cm, nạp ở 488 cm/s: đứng yên bao lâu rồi lao cũng chỉ nhảy tối đa 500 cm; chạy gấp
  1,5 hay 2 lần bị bóp ở 488 cm/s.
- Đứng mạng: không đóng. Sau gói dồn vị trí máy chủ trễ client `v·S − 500` cm và khép lại ở 488 cm/s khi client dừng (giống gốc:
  máy chủ đi theo đường đã nhận). Ước tính theo mô hình (chưa dựng): S = 3 s trễ 895 cm, S = 10 s trễ 4150 cm.
- Đồng bộ lại: client lệch khỏi mốc quá `465 cm/s × idle_timeout_ms` (người thật không thể lệch hơn vì kết nối đã đứt) thì gửi
  Position kéo về, không phạt. Số này không phải ngưỡng gian lận (hack đã bị bóp) mà chỉ là chỗ cắt lệch tích luỹ.
- Đường đi theo lưới đi được như `FindPath` của gốc: dùng kiểm đoạn của B19 cho tường. Chưa quyết: đuổi thẳng tới vị trí client
  (đơn giản, quanh góc có thể chạm tường và bị hoàn bước) hay giữ hàng đợi các điểm client đã khai (mỗi đoạn đã qua kiểm đoạn)
  rồi đi dọc chúng. Quyết khi đọc `Scene::moved` và đường relay; ghi vào mục này.
- Bỏ nợ vi phạm (`speed_debt_`, `teleport_debt_`) và `kSpeed`/`kTeleport` nếu không còn ai dùng; `kRejected` giữ cho tick lùi
  và số không hợp lệ.
- Test: `guard_tests` viết lại theo `kClamped` (chỉ các ca có hợp đồng mới); không thêm ca logic ngoài đó.

E2E và tiêu chí đạt:

- Mô phỏng đứng mạng 1 đến 12 s: không đóng phiên, mọi Move được nhận hoặc cắt; bảng ghi vào mục này.
- Đứng yên rồi dồn Move xa: mốc chỉ nhảy tối đa 500 cm.
- Chạy gấp 1,5 và 2 lần: vị trí máy chủ bị bóp ở 488 cm/s (đo bằng bot quan sát thứ hai thấy `EntityPos` của bot gian lận).
- `thienlong_bot --rush` không còn bị đá: thoát 0 khi bot quan sát thấy vị trí máy chủ của bot gian lận bị cắt; sửa `--rush` cho khớp
  (bản cũ lưu trong `D:\THIENLONG-luu-tru\h1-phuong-an-a\bot-rush-leap.patch`).
- Không phạt oan: `--count 4` đi vòng và đi thẳng như B19, `e2e_g0.py` 6/6.

### Tồn đọng

- Trần số mẫu của kiểm đoạn (kiểm chéo B19 của `c5`, không chặn): `Scene::clear_line` lấy số mẫu tỉ lệ độ dài đoạn đi (quãng chia
  20 cm), và gate Pace chỉ chuyển tiếp nước đi `kOk`, nên sau một lúc đứng lâu, client khai một đoạn dài vẫn bị xét hết các mẫu.
  Phương án B bóp quãng mỗi lần ở quỹ 500 cm nên tối đa 25 mẫu mỗi Move; ghi trần đó thành hằng khi làm B.
- B1 (khung zone lớn hơn một bản ghi mật 4104 byte bị bỏ): gói riêng sau G2-M. Đã đo: chưa có tin thật nào vượt (`NGHI-NGO.md`
  75).
