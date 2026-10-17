# G0-M: hạ tầng E2E phía máy chủ

Làn M (`thienlong-6a`), nền `bb8dd17e`. Gói là công cụ dev: không có tin mới, không đổi giao thức,
không có chữ nào mới hiện cho người chơi. H1 (hack tốc độ) rời G0 theo điều phối, xem cuối phiếu.

## Bằng chứng

- Cổng: `dev/server/config/gate.toml` `[listen]` là `127.0.0.1:7100` và `:7101` (7000/7001 do cụm TLBB
  gốc giữ). Còn ghi 7000/7001: `TOOLS/server/bot.cpp:19,76-77,712`, `dev/server/README.md:96-102,123-127`.
- Máy chủ gốc cũng ghi một dòng cho mỗi việc của người chơi (`CGCharMoveHandler.cpp:93`
  `g_pLog->FastSaveLog(... "ObjID=%d X=%f Y=%f")`, mã 2008): log kiểm theo việc là cách gốc, không phải tự chế.
- Móc có sẵn: `Host::handle` (`zone/host.cpp:297`), `Host::attach` (`:246`), `Gameplay::on` ×9
  (`play/gameplay.cpp:544-617`), `Battle::cast`, `drain`, `respawn`, `pick_up` (`play/battle.cpp`),
  `Scene::moved` (`zone/scene.cpp:276`, nhánh `blocked` đẩy `out.place`).
- Đã chạy: dựng `lane-server` 379 bước 0 cảnh báo, cài vào `dev/server/bin`, cụm lên
  `gate.game=7100 gate.auth=7101`, bot `--count 1 --seconds 8 --prefix e2em0` thoát 0
  (`build/e2e/G0/bot-smoke.txt`; đi vòng tròn bị kéo về 30 lần: nguyên nhân ở mục "Kéo về ở điểm sinh").
- Tiến trình máy chủ không dùng `core::Log`; tin ra `println` stderr, trình giám sát gom về
  `dev/server/log/cluster_err.txt` (`local_cluster.py` mở lại mỗi lần start).

## Làm

1. Dựng, cài, cụm 7100/7101: xong, đã báo `thienlong-14`.
2. Bot: cổng mặc định 7100/7101; thêm `--peers N`: đứng yên đủ `--seconds` giây rồi thoát 0 nếu thấy ít
   nhất N người chơi khác hiện ra (sidecar chạy song song với client thật); thêm `--walk <walk.path>` cho
   `--hunt`, `--talk`, `--fight` đi theo luật đi của client (`nav::Field::plan_move`): đứng trong vật cản
   thì bước ra chỗ đi được trước (người chơi bấm gần), đứng đúng từng điểm rẽ (điểm rẽ cách vật cản
   10 cm), hạn mỗi chặng theo độ dài, đứng yên khi client từ chối lệnh đi; cuối lộ trình thì dừng, không
   đâm thẳng tới đích nằm trong vật cản.
3. `dev/server/README.md`: bố cục cổng, cách cài (`--prefix dev`), `local_cluster.py`, khoá log kiểm.
4. Log kiểm: khoá `play_trace` (bool, mặc định false) ở `log.toml`; dev bật true. Zone ghi một dòng
   stderr: `zone: kiểm tick=<tick zone> việc=<tên> tk=<id tài khoản> nv=<id nhân vật> scene=<id>
   x=<cm> z=<cm> kq=<ok|mã lỗi> gt=<số của việc> ten="<tên nhân vật>"`; dòng `kéo` ghi toạ độ bước bị
   chặn và thêm ` về=<x>,<z>`.
   - Việc: vào, rời, đi (tối đa một dòng mỗi giây mỗi người), kéo (zone chặn bước đi), nói, chọn, nhận,
     trả, bỏ, chiêu, đánh (người ra đòn trúng), trúng (người bị trúng), hạ (người hạ quái), chết,
     hồi, nhặt. `kq` là `ok` hoặc mã `ErrorCode` bằng số khi bị từ chối; `gt` là sát thương, id NPC,
     id kỹ năng, mẫu quái... tuỳ việc (bảng ở `dev/server/README.md`).
   - Tắt thì không tốn gì: `Output::traced` false thì không ghi ghi chú và không định dạng gì.
   - Tài khoản chỉ là id số; không ghi mật khẩu hay vé.
5. `TOOLS/server/e2e_g0.py`: một lệnh chạy sáu kịch bản bot, ghi vào `build/e2e/G0/m/`, đối chiếu dòng kiểm
   mới của `cluster_err.txt` với việc mỗi kịch bản phải để lại, in việc chưa kiểm.

## Không làm

- Không log ở gate (kéo về do `guard::Pace`): chờ H1.
- Không thêm hay đổi tin, trường, `catalog/*.tsv`; không viết test logic mới. Test máy chủ có sẵn phải xanh.
- `chết` và `hồi` chỉ kiểm bằng đọc mã tới G4 (bot không tự chết được).

## Kịch bản và tiêu chí đạt

1. `local_cluster.py start`, chờ `ready ... gate.game=7100 gate.auth=7101`.
2. `thienlong_bot ... --count 2 --seconds 8 --prefix e2em1`: thoát 0, mỗi bot thấy bot kia.
3. `thienlong_bot ... --count 1 --seconds 40 --peers 1 --prefix e2em2` chạy song song với client của 14: thoát 0
   khi thấy client.
4. `cluster_err.txt` có `việc=vào`, `đi`, `kéo` (`--straight 1`), và với `--talk`, `--fight`: `nói`, `nhận`, `chiêu`,
   `đánh`, `hạ`, `nhặt`; đặt `play_trace = false` thì không dòng nào.
5. Log để ở `build/e2e/G0/`.

Lệnh: `py -X utf8 TOOLS/server/e2e_g0.py --tag <chuỗi mới>` (cụm đang chạy, `play_trace = true`); kết quả ở
`build/e2e/G0/m/` (`report.txt`, `<kịch bản>-out.txt`, `<kịch bản>-err.txt`; `build/e2e/G0/` còn lại là của K).

## Kết quả (chạy 2026-10-18, tag 9, `build/e2e/G0/m/report.txt`)

- Cả sáu kịch bản ĐẠT: pair, peers và walker thoát 0 (đôi thấy nhau, đứng xem thấy 1 người, đi vòng); straight thoát 0 và
  có dòng `kéo`; fight thoát 0, giết 9 quái, kinh nghiệm +240, có `chiêu`, `đánh`, `hạ`; talk mở hộp thoại với
  赵天师 (NPC 140) rồi thoát 1, đúng như ghi nhận: chưa nhận được nhiệm vụ nào (`bảng nhận=0`).
- Dòng `việc=` mỗi nhân vật nằm ở `build/e2e/G0/m/zone-kiem-tom-tat.txt`, dòng thô ở `zone-kiem.txt`. Có
  `vào`, `rời`, `đi`, `kéo`, `nói`, `chọn`, `chiêu`, `đánh`, `hạ`; `kq` khác `ok` cũng có: `chọn kq=21` (2 lần) và
  `chiêu kq=31` (81 lần ở lượt này), tức đường ghi mã từ chối chạy thật.
- Tắt `play_trace`: đặt `false`, khởi động lại cụm, bot e2em61 vào, đi vòng 8 giây, rời, thoát 0; stderr của cụm
  33 dòng và 0 dòng `zone: kiểm` (`build/e2e/G0/trace-off-*.txt`); bật lại `true`, cụm lên.
- Pair, walker, straight có `kéo về` (59, 30, 132): các bot đi vòng tròn hay thẳng không biết vật cản, bước từ chỗ
  đi được vào vật cản quanh điểm sinh (xem "Kéo về ở điểm sinh"). talk và fight dùng `--walk`: 0 lần kéo.
- Chưa kiểm: `nhận` và `trả`, `bỏ` (赵天师 chưa giao nhiệm vụ nào: chọn 1 và 2 của hộp thoại gốc bị zone từ chối
  mã 21, chọn 3 ok nhưng không ra bảng nhận; việc của N1), `nhặt` (9 quái chết mà không thấy vật rơi nào), `trúng`
  (không quái nào đánh trúng người), `chết` và `hồi` (bot không tự chết được). Các việc này mới kiểm bằng đọc mã.
- Bot fight ra chiêu ngoài tầm: luật đi client cho bot tới sát 150 cm quanh quái, xa hơn tầm kỹ năng, nên server trả mã
  31 (81 lần ở tag 9). Kiểm chéo của 14 (tag 14x1) chạy lại thấy fight quá 300 giây rồi bị kill (151 chiêu mã 31, 9 `ok`):
  `fight()` không dừng khi bị từ chối liên tiếp và bỏ qua `--seconds`, nên ĐẠT hay HỎNG tuỳ may. Sửa trong bot (server
  không đổi): `Seen::out_of_range` đếm mã 31 liên tiếp, tầm đứng co từ 150 xuống tối thiểu 20 cm (một nửa sau mỗi hai lần
  bị từ chối), sau 8 lần liên tiếp thì bỏ quái đó (`unreachable`); `--seconds` là tổng giờ săn, `e2e_g0.py` đặt 120.
  Chạy lại hai lượt liên tiếp (tag g1, g2, `build/e2e/G0/m/report-g1.txt`, `report-g2.txt`): cả sáu kịch bản ĐẠT ở cả hai
  lượt, fight thoát 0, giết 11 quái, kinh nghiệm +300, mã 31 chỉ còn 4 và 5 lần ở stderr (zone: 9 dòng `chiêu kq=31`
  trên 34 chiêu của hai lượt), chạy 99 đến 109 giây.
- Phát hiện khi chạy: lỗi của chính bot (hạn cố định 20 giây mỗi điểm rẽ ngắn hơn đoạn 61 m, bot bỏ giữa đường và đâm
  vào vật cản; đứng lệch điểm rẽ 12 cm đã vào vật cản vì điểm rẽ cách vật cản 10 cm), đã sửa và chạy lại.

## Kéo về ở điểm sinh (soi gốc theo yêu cầu của điều phối)

Dòng `việc=kéo` ghi toạ độ bước bị chặn (x, z) và chỗ buộc về (`về=`). Lượt bot thử đầu, 2.710 dòng:

- Đi vòng tròn (e2em01, e2em03: 30 lần mỗi khách): chặn ở (16420..16426, 16913..16925), về (16416,16916).
- Đi thẳng (e2em04: 130 lần; e2em06: 2.490 lần): chặn ở (17364,16482) và (17360,16900), cách điểm sinh khoảng 8,6 m
  về phía đông.

Đối chiếu ô `.path` bằng `nav::locate` trên `dev/server/scenes/dali/walk.path` (công cụ đo tạm, không vào dự án):

1. Mọi toạ độ bị chặn nằm trong tam giác vật cản của `dali_new_320.path`; chỗ bị kéo về nằm trong 20 cm
   (`kWalkSlackCm`) quanh một tam giác đi được. Không có lần kéo nào trên ô đi được.
2. Trục đúng: 89 trên 89 điểm đến Đại Lý và 86 trên 86 cổng ra khỏi Đại Lý trong `scene_positions_extended.tsv`
   đều nằm trên tam giác đi được.
3. Điểm sinh (165,169) nằm trên tam giác vật cản, cách chỗ đi được khoảng 1 m về phía tây (164,169 đi được).
   Điểm sinh đến từ `DefaultChar.ini` bản 0859602 (`new_character.toml`), không phải từ bảng 2026. Bot vòng tròn
   bước từ chỗ đi được ở phía tây trở vào vùng vật cản nên bị chặn.
4. Luật gốc cho đúng kết quả này: `AI_Character.cpp:152-201` đứng ở chỗ không đi được thì không kiểm đường
   (tin client); đứng ở chỗ đi được thì `FindPath` từng nút, nút đầu không đi được thì `OR_ERROR`;
   `CGCharMoveHandler.cpp:73-82` gặp lỗi thì `Teleport(&posCur)` kéo về. `Scene::blocked` (`zone/scene.cpp:288`)
   làm đúng hai nhánh đó. Khác gốc: gốc kiểm cả đoạn thẳng qua cạnh ràng buộc (`bLine`), zone kiểm điểm cuối
   cộng độ lệch 20 cm.
5. Client thật không bị kéo: client của 14 (e2ek0a1) đi từ điểm sinh, log kiểm chỉ có `việc=đi`. Luật
   `nav::Field::plan_move` của client cho đi thẳng ra khỏi vật cản qua không quá một cạnh (`nav/route.hpp`).

Kết luận: không phải lỗi luật của zone, bot cũ đi thẳng không biết vật cản. Bot nay có `--walk <walk.path>`:
`--hunt`, `--talk`, `--fight` đi theo `nav::Field::plan_move`, đúng luật client. Điểm xuất phát (165,169) là số
của bản 2008 nằm trong vật cản, không phải vùng bao kín ((164,169) đi được và liền với mọi NPC): điều phối đã chốt
D4 của G1-M, nhân vật mới vào (165,00; 169,71).

## Để dành cho H1 (việc đệm)

Gốc tự đi theo đường client gửi: `Obj_Logic_Move` (`Obj_Character_Logic.cpp:449-544`) tiến
`tốc_độ × thời_gian_logic_máy_chủ` mỗi nhịp, không bù theo tin. `GetMoveSpeed` (`Obj_Human_Attributes.cpp:529`)
là `DefaultMoveSpeed/1000` nhân theo mode (2800 ở `Config.h:119`, 5000 ở `ConfigInfo.ini` của XJL7457). Lỗi nằm ở
`pace.cpp:75-77`: `kJitterTicks` cấp lại mỗi tin. Hướng sửa: đồng hồ đi riêng, tín dụng
`(tick_máy_chủ − đồng_hồ_đi) + kJitterTicks`, chỉ tăng đồng hồ đi theo thời gian đã dùng.

B19, cùng việc đệm với H1 (HO-SO mục 5.11): `Scene::blocked` (`zone/scene.cpp:288`) chỉ kiểm điểm cuối của mỗi bước
(cộng độ lệch 20 cm `kWalkSlackCm`), không kiểm đoạn thẳng cắt cạnh ràng buộc như bản gốc (`AI_Character.cpp:152-201`,
`bLine`). Một client gian bước qua được tường mỏng hơn một bước (đọc mã, chưa dựng ca thử). Ngoài ra người đang đứng ở chỗ
không đi được thì không bị kiểm gì (đúng luật gốc): D4 của G1-M đưa điểm sinh ra khỏi vật cản nên bước đầu hết được
tự do.
