# G2-M: HUD nhân vật, phần máy chủ — phiếu

Làn M (`bd`). Đọc chéo với `G2-K.md` (làn K: `c5`). Chỗ đã đọc từ gốc ghi tệp:dòng.

## Trạng thái (2026-10-18)

Mã xong, E2E trên cụm thật ĐẠT, chờ kiểm chéo của `c5` rồi commit. Một lần nâng giao thức v10 (`min_version` 10 trong
`dev/server/config/gate.toml`). Dựng và kiểm trên cây tách `.worktrees/g2m` (nền B19 `6af42661`), đưa vào cây chính khi
c5 ĐẠT.

| Phần | Mã | Kiểm |
|---|---|---|
| `SelfStats` 31 trường | `play/gameplay.cpp` `stats_of`, `zone/scene.cpp` | bot `--hud`, khớp PostgreSQL |
| `EntityVitals` + `mp_percent`, `rage` | `zone/scene.cpp` `set_vitals`, `play/battle.cpp` | `zone_tests`, bot `--hud` |
| `AskTarget` | `play/battle.cpp` `ask_target`, `gate/table.cpp` | bot `--hud` (mình, người khác, id lạ, 0) |
| `BuffList` | `play/battle.cpp` `buff_list`, `push_*_buffs` | bot `--hud` với chiêu 35 (buff thật) |
| `WorldTime` | `zone/host.cpp` `tell_period`, `zone/serve.cpp` | bot `--hud --seconds 160` thấy đổi canh |
| Sáu chiêu đầu | `play/battle.cpp` `kStartingSkills` | `play_tests`, bot `--hud`, `e2e_g0` kịch bản fight |

## 1. Bằng chứng gốc (đã đọc)

Mã 2008 ở `D:\TÀI LIỆU TLBB\tlbb_server\Server\GameServer\Server`, bố cục gói ở `...\Common\Packets`; id gói 2026 ở
`docs/TAILIEU/GAME-EXE-2026/packets.tsv`.

- Thuộc tính chi tiết của chính mình: `GCDetailAttrib` 687. Cờ bit chọn trường; gửi khi giá trị đổi so với bản sao lưu
  (`Obj/Obj_Human_AttrRefesh.cpp:356-1000` `SendMsg_RefeshAttrib`), và khi được hỏi (`:1006` `AskMsg_DetailAttrib`,
  `CGAskDetailAttribHandler.cpp:56-59`, chỉ với người cùng phe trong 10 đơn vị). Trường (`GCDetailAttrib.h:71-220`): cấp, kinh nghiệm, tiền, phái, sinh lực
  và nội lực (hiện tại, tối đa), tốc độ chạy, STR/SPR/CON/INT/DEX, điểm tự do, hồi HP, hồi MP, công và thủ ngoại, công và thủ
  nội, trúng, né, hội tâm, nộ khí, điểm liên kích, tốc độ đánh, công và kháng bốn hệ (băng, hỏa, điện, độc).
- Chọn mục tiêu: client hỏi `CGCharAskBaseAttrib` 1521 (một id) → `CGCharAskBaseAttribHandler.cpp:55` → người
  `Obj_Human_AttrRefesh.cpp:1404-1450`, quái `Obj_Monster_AttrRefesh.cpp:229-293`: trả `GCCharBaseAttrib` 587 (tên, cấp, % sinh
  lực, % nội lực, nộ khí, tốc độ, ...) rồi `GCCharImpactListUpdate` 1353 (danh sách buff của mục tiêu). Đổi trên người trong vùng
  nhìn thì gửi lại (`Obj_Monster_AttrRefesh.cpp:178-224`).
- Buff của chính mình: `GCDetailImpactListUpdate` 168 (chủ, số lượng, mỗi buff: người gửi, kỹ năng, buff, SN, thời gian còn
  lại; `GCDetailImpactListUpdate.cpp:41-58`) và từng buff một `GCDetailBuff` 2249 (`Obj/Obj_Character_Impact.cpp:895-935,
  981-1006`); người khác nhận `GCCharBuff` 485 (chủ, buff, bật/tắt, người gửi, SN).
- Giờ: `GCWorldTime` 349 mang một số 0 đến 11 (`WORLD_TIME`, `Common/GameDefine2.h:868-881`); máy chủ thế giới tăng một nấc
  mỗi `TimeChangeInterval` = 150000 ms bắt đầu từ nấc 0 (`WorldServer/World/WorldData/WorldTimeInfo.cpp:40-73`,
  `G:\XJL7457\Server\...\ConfigInfo.ini:24`), gửi khi vào cảnh (`CGEnvRequestHandler.cpp:42`). Khoá `period_change_ms`
  (`dev/server/config/zone.toml:55`) đã có nhưng chưa ai đọc.
- Kỹ năng ban đầu: `DefaultChar.ini` `[skill]` bản 0859602 (`D:\TÀI LIỆU TLBB\TLBB_0859602_Win10_11\tlbb\Server\Config`,
  dòng 29-36): sáu chiêu 0, 1, 21, 22, 34, 35, cấp 1. Bản XJL7457 cùng tệp ghi 19 chiêu và `level=15` (máy chủ tư nhân sửa):
  lấy bản 0859602 vì dữ liệu của dự án là 0859602 và nhân vật mới ở cấp 1.
- Thuộc tính ta tính được: `actor::Body::stat` đã port công thức `Obj_Human_Attributes.cpp` (40 chỉ số, `actor/attr.hpp`), nên
  không viết công thức mới.

## 2. Tin đổi và thêm (một lần nâng giao thức v10, `min_version` 10)

1. `SelfStats` thêm trường của `GCDetailAttrib` mà ta có nguồn: `sect`, `str`, `spr`, `con`, `int`, `dex`, `points_free`,
   `hp_regen`, `mp_regen`, `attack_phy`, `attack_magic`, `defence_phy`, `defence_magic`, `hit`, `miss`, `critical`,
   `strike_point`, `attack_speed`, `move_speed`, bốn công và bốn kháng hệ (27 trường mới). Gửi lại khi bất kỳ trường nào
   đổi (so cả khối, như `m_AttrBackUp`); không gom theo nhịp (chỉ số đổi hiếm), khác `SelfVitals` có gom 5 lần mỗi giây.
2. `EntityVitals` thêm `mp_percent` và `rage` (gốc đặt cùng `HPPercent` trong gói công khai, `Obj_Human_AttrRefesh.cpp:410-439`).
3. `AskTarget` (client gửi, một id) thay `CGCharAskBaseAttrib`; trả `EntityVitals` (đủ trường) và `BuffList` của mục tiêu. Máy chủ
   nhớ mục tiêu đã hỏi của mỗi người chơi, và gửi lại hai tin ấy khi chúng đổi. Khác gốc: gốc phát công khai cho mọi
   người trong vùng nhìn, ta chỉ gửi cho người đã chọn để khỏi bão tin.
4. `BuffList` (chủ, danh sách): bản của chính mình mang người gửi, kỹ năng, buff, SN, thời gian còn lại như
   `GCDetailImpactListUpdate`; bản của mục tiêu chỉ buff như `GCCharImpactListUpdate`. Gửi cả danh sách mỗi khi đổi, không
   từng buff một (Khác gốc: `GCDetailBuff` và `GCCharBuff` mang từng buff). Nguồn: `combat::Fighter::buffs`.
5. `WorldTime` (một số 0 đến 11) theo `GCWorldTime`: gửi sau `SceneEnter` và mỗi `period_change_ms`; nấc đếm từ lúc zone chạy
   (gốc đếm từ lúc máy chủ thế giới chạy, nên mỗi lần dựng lại cụm là nấc 0). Đóng `NGHI-NGO.md` 22 phần canh giờ.
6. Kỹ năng ban đầu: `battle.cpp` `starting_skills` bỏ "mọi chiêu của phái ở cấp 1", chỉ cho chiêu 0, 1, 21, 22, 34, 35 (cộng
   chiêu đã học đã lưu). Không đổi dây. Sáu id có trong `dev/server/tables/shared/skills.tsv`: 0 普通攻击 (đòn thường),
   1 捕兽, 21 召唤坐骑, 22 返回大理城, 34 新手轻功, 35 打坐; `starting_skills` bỏ chiêu nào thiếu mẫu hay dòng cấp 1, và bot
   `--hud` nhận đúng sáu (nên cả sáu đều có). Ca test dựa vào chiêu phái cấp 1 đã đổi sang đòn thường (`kFightSkill` = 0 trong
   `play_tests.cpp`); bot `--fight` ra chiêu ĐẦU danh sách, là đòn thường 0, không đổi. Chiêu 35 (打坐) sinh một buff thật
   (effect 35, còn 3 600 000 ms); chiêu 21 ra chiêu được nhưng không sinh buff trong bộ chiến đấu của ta.

## 3. Không làm

- `GCSelectTarget` 376 và `CGSelectTargetOfObject` 403: mã 2008 không có chỗ xử lý nào (`grep SelectTarget` trong `GameServer`
  trống); chọn mục tiêu của gốc là `CGCharAskBaseAttrib`. Nếu K chứng minh TargetFrame cần mục tiêu của mục tiêu thì hỏi lại.
- Trường `GCDetailAttrib` ta không có nguồn: bang, `DataID`, ảnh chân dung, `ModelID`, `MountID`, thú đi theo, cờ khoá đi, cờ
  hành động, phe, RMB, RMB kho, tinh lực. Ghi `NGHI-NGO.md` kèm gói chặn (bang G9, trang bị và thú cưỡi G5, thương thành).
- Khung đội và raid của TargetFrame: chờ G9 như K.
- Buff có mô tả riêng ở client (`GetBuffToolTipsByIndex`): bảng chữ nằm ở client, máy chủ chỉ gửi id buff.

## 4. Trả lời G2-K (mục 3)

- K cần `SelfStats`, `SelfVitals`, `EntityVitals`: đủ, thêm trường như mục 2. Tin buff: có, là `BuffList` ở trên.
- Hỏi K: (a) `PlayerImpactFrame` và `TargetBuff` dùng thời gian còn lại của buff theo mili giây hay nấc? Ta gửi mili giây còn lại
  tại lúc gửi; client tự đếm xuống. (b) Khi `MAIN_TARGET_CHANGED` thì client gửi `AskTarget`; K chốt chỗ gửi. (c) Cần xác nhận
  hàm `Player:GetData` của script đọc đúng tên các trường mục 2, và trường nào script đọc mà ta chưa có.

## 4b. Bảng và config sẽ chạm (luật chữ HO-SO mục 0.1: đồng bộ, tiếng Việt có dấu, một nguồn thuật ngữ)

- `dev/server/tables/**`: không chạm. Kỹ năng ban đầu là sáu số `0, 1, 21, 22, 34, 35` từ `DefaultChar.ini`, thành hằng có tên
  `kStartingSkills` trong `battle.cpp` kèm comment nguồn thay vì dựng một bảng mới cho sáu số.
- `dev/server/config/**`: chỉ đổi giá trị `min_version` của `gate.toml` (9 thành 10; comment sẵn là tiếng Việt). Zone bắt đầu
  ĐỌC khoá `period_change_ms` của `zone.toml` (đã có bộ đọc `src/server/config/zone.cpp:97`); không thêm khoá mới.
- `src/shared/protocol/catalog/*.tsv` (`messages`, `fields`, `enums`; thêm `AskTarget`, `BuffList`, `WorldTime`, trường mới của
  `SelfStats` và `EntityVitals`): điều phối `5f` chốt 2026-10-18 là KHÔNG thuộc phần đổi header của luật chữ, vì đó là lược đồ
  giao thức đưa vào bộ sinh mã, dùng chung client và máy chủ; header và cột `name` là định danh, giữ tiếng Anh như định danh C++.
  Dòng mới thêm theo cột hiện có; cột chữ tự do (`note`, `summary`) viết tiếng Việt có dấu. Không lập gói riêng. Khoá catalog
  (`KHOÁ`/`MỞ`) trong lúc thêm vì làn K đọc cùng bảng.
- Chữ người chơi thấy từ máy chủ: G2-M không thêm chữ nào (chỉ số, id buff, id chiêu); tên buff và chiêu hiển thị ở client.
- `TOOLS/server/column_terms.tsv`: thuật ngữ mới của gói (tên trường `strike_point`, `hp_regen`, `mp_regen`, `points_free`...) thêm
  vào cột `vi` khi cột ấy có; đặt tên trường theo thuật ngữ đã có trước, thiếu thì thêm vào nguồn đó rồi mới dùng.

## 5. E2E và tiêu chí đạt

- Bot `--hud 1`: vào cảnh; nhận `SelfStats` đủ trường và so với `Body::stat` của nhân vật trong PostgreSQL (cấp, kinh nghiệm,
  điểm tự do); `SelfSkills` đúng sáu chiêu; `WorldTime`; hỏi một quái rồi nhận `EntityVitals` và `BuffList`; đánh quái thì
  `SelfVitals` đổi.
- Client của K (`g2-hud.script`): ảnh HUD mang số của máy chủ; chọn quái thì TargetFrame đổi.
- Theo `HO-SO.md` G2: số trong ảnh khớp log kiểm và PostgreSQL; thanh kỹ năng đúng sáu chiêu `[0,1,21,22,34,35]`.
- Không viết ca test logic mới, trừ hồi quy cho lỗi tìm thấy khi làm.

## 6. Đã chạy (2026-10-18)

Dựng trên cây tách (`.worktrees/g2m`, `build/lane-server`): 0 cảnh báo (`build-fin.log` trong cây tách, 66 bước). ctest máy chủ
15/15 xanh (config, service, server_boot, server_boot_source_clean, protocol, guard, account, protocol_catalog, play, zone,
gate, gate_motion, gate_loop, protocol_catalog_fresh, server_config_lint). Giao thức dùng chung dịch bằng clang với năm cờ
của bản Android (`-Wmissing-prototypes -Wmissing-designated-field-initializers -Wshadow -Wsign-conversion
-Wshorten-64-to-32`, `src/shared/protocol/messages.cpp` và `wire.cpp`): 0 cảnh báo. `shape.js --diff .` 0 vi phạm,
`source_headers.py` đúng khung.

E2E trên cụm thật (cụm v9 dừng, cài v10 và `min_version` 10, chạy, trả v9: SHA-256 exe trùng bản sao lưu, `gate.toml` sạch).
Bằng chứng ở `build/e2e/G2M/m/` và `build/e2e/G2M/m2/` (`scratchpad/g2m_e2e.ps1`, `g2m_hud2.ps1`):

| Phép thử | Kết quả |
|---|---|
| `--hud 1` bốn khách | mọi dòng "đạt": SelfStats đủ, sáu chiêu, WorldTime, BuffList khi vào cảnh, AskTarget (mình, người khác, id lạ bị `kNoSuchEntity` mã 21, 0 bỏ chọn) |
| số so PostgreSQL (`pg.txt`) | cấp 1, kinh nghiệm 0, phái 9, STR 7, SPR 6, CON 5, INT 5, DEX 2, điểm tự do 0: khớp bot |
| `--hud 1 --seconds 160` | "WorldTime đổi canh sau một chu kỳ" đạt cả bốn khách |
| `--hud 1` ca chiêu 35 (`m2/hud-out.txt`) | buff của mình: effect 35, SN 1, còn 3 600 000 ms, người gây là mình, chiêu 35. Lần chạy này bản AskTarget chính mình còn là bản rút gọn: đó chính là lỗi c5 tìm (bên dưới) |
| lỗi c5 (kiểm chéo): chọn mình rồi ngồi, hai BuffList cùng id, bản rút gọn đè bản đủ | sửa `push_target_buffs` (nhánh `asked == entity`, chỉ trả bản đủ khi được hỏi). Đỏ rồi xanh cùng bot (`m3/`): zone trước sửa `chọn mình rồi ngồi ... — SAI`, còn 0 ms (`hudred-out.txt`); zone sửa đạt, còn 3 600 000 ms (`hudgreen-out.txt`) |
| `--leap 1`, `walk`, `straight` | giống bản B19 (đặt lại đúng, không phạt oan) |
| `e2e_g0.py` | 6/6, "KẾT LUẬN: ĐẠT", chạy lại trên bản đã sửa (`m3/e2e_g0-out.txt`; kịch bản fight đánh quái được với sáu chiêu đầu) |

## 7. Tồn đọng

`NGHI-NGO.md` (ghi khi commit): đơn vị `move_speed` và trần 465 cm/s, trường chưa có nguồn, `WorldTime` đếm từ lúc zone chạy,
các chỗ lệch gốc của BuffList và AskTarget, xoá nhân vật chờ ngày. Chưa kiểm: `EntityVitals.mp_percent` và `rage` với giá
trị khác 0 trên cụm thật (nhân vật mới đủ nội lực, không có quái ở Đại Lý); `zone_tests` chỉ kiểm hp. `respawn()` đặt lại
nội lực và nộ khí của cảnh sau `raise()` (ghi chú 2 của c5) mới có `play_tests` hồi sinh xanh, chưa chạy trên cụm vì không
kịch bản nào hồi sinh. Đây là kiểm một đoạn của G2: ảnh HUD của K còn cần chạy trên cụm v10.
