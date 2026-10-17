# G1-M: danh sách nhân vật, xoá nhân vật, mã kết quả

Làn M (`thienlong-6a`), nền `bba77680` (G0-M đã commit). Điều phối `thienlong-f7` đã duyệt D1, D2 và
nguyên tắc của D3, và chốt D4 (thay `thienlong-14`); 14 vẫn kiểm chéo kết quả và xác nhận từ mã máy từng trường
của D3. Thứ tự: commit G0-M khi 14 trả ĐẠT, rồi mới viết mã G1-M. Nơi K đọc kết quả:
`GameProduceLogin:GetRoleInfo`, `GetRoleCount`, `GetCurSelectRole`, các hộp thông báo của
`LCRetDeleteCharHandler`, `LCRetCreateCharHandler`, `LCRetCharListHandler`.

## Bằng chứng

- Gói gốc 2008 (`tlbb_server/Common/Packets/LCRetCharList.*`, `GameStruct.h:993` `DB_CHAR_BASE_INFO`): mỗi
  nhân vật mang `m_GUID, m_Sex, m_Name[30], m_Level, m_HairColor, m_FaceColor, m_HairModel, m_FaceModel,
  m_StartScene, m_Menpai, m_HeadID, m_Camp, m_EquipList`. Tối đa `DB_CHAR_NUMBER = 5`.
- Client 2026 (`SelectRole.lua:435-463`): `GetRoleInfo(i)` trả bảy giá trị `tên, môn phái, cấp, iDelTime,
  tên ảnh chân dung, iCYGSate, iPKLevel`. Người mẫu 3D dựng từ mặt, tóc, màu tóc/da và tới 19 ô trang bị
  nhìn thấy (`DANG-NHAP-GOC.md` mục 3, `0x14063b8f0`). Bố cục byte 420 của bản ghi chưa giải
  (`MAY-CHU-SUY-RA.md` mục 5): K đọc `0x140831780` và `0x14063b8f0` để chốt danh sách trường cuối.
- Luật xoá của máy chủ 2008, đọc từ `LoginServer/Login/Packets/CLAskDeleteCharHandler.cpp:19-95`,
  `WorldServer/World/Packets/LWAskDeleteCharHandler.cpp:9-35`, `WLRetDeleteCharHandler.cpp:24-183`:
  1. Phiên không ở `PS_LOGIN_NORMAL` thì bỏ lặng.
  2. GUID không thuộc tài khoản: `ASKDELETECHAR_NOT_OWNER` (5).
  3. Cách lần thao tác DB trước dưới `DB_OPERATION_TIME` = 500 ms (`GameDefine.h:528`): `OP_TIMES` (2).
  4. Hỏi World: nhân vật đang chơi thì `ONLINE` (7).
  5. Tài khoản không có nhân vật: `EMPTY` (3). Phiên chưa nhận danh sách: `OP_ERROR` (4).
  6. Xoá, nạp lại danh sách; số nhân vật không giảm thì `INTERNAL_ERROR` (6), giảm thì `SUCCESS` (0).
  7. Trả `LCRetDeleteChar(kết quả)` rồi `LCRetCharList` mới.
- Mã kết quả gốc (`ResultDefine.h:127-157`): xoá 0 SUCCESS, 1 SERVER_BUSY, 2 OP_TIMES, 3 EMPTY,
  4 OP_ERROR, 5 NOT_OWNER, 6 INTERNAL_ERROR, 7 ONLINE. Tạo 0..7: SUCCESS, SERVER_BUSY, OP_TIMES, FULL,
  SAME_NAME, OP_ERROR, INTERNAL_ERROR, INVALID_NAME. Danh sách 0..3: SUCCESS, OP_FAILS, SERVER_BUSY, OP_TIMES.
- Client 2026 xử lý đúng bộ mã đó (`login_packets.txt:3463-3640`, hàm `0x1408319c0`): xoá 1 `Server_Busy_Retry`,
  2 `LCRetDeleteCharHandler_1`, 3 `Info_No_Role_Del`, 4 `Info_Err_Produce`, 6 `Info_Err`, 7 `FWQYM_160120_147`,
  0 làm tươi danh sách, **5 và mọi mã lạ rơi vào `Info_Unknow_err`**. Tạo (`2540-3060`): 1 busy, 2, 3 `Role_Is_Full`,
  4, 5 `Err_Operate_Produce`, 6 `Info_Err`, còn lại `Info_Unknow_Err`.
- Hiện trạng của ta: `GameDb::remove_character` (`account/sql.cpp:713`) đánh dấu `deleted_at` theo
  `id` và `account_id`; không kiểm nhân vật đang chơi, không giới hạn nhịp, không phân biệt "không phải của
  tôi" với "không có nhân vật". `CharacterSummary` (`messages.hpp:246`) chỉ có `id, name, level, gender, face,
  hair, school, scene`. Danh sách trả qua `Reject.code` từ `ErrorCode` (`enums.tsv` 1..40), không có mã
  ứng với `EMPTY`, `ONLINE`, `INTERNAL_ERROR`.

## Bốn quyết định (D1 đến D3 đã duyệt, D4 điều phối chốt)

- **D1 — xoá ngay hay xoá trễ (đã duyệt: xoá ngay).** Script 2026 có nhánh `iDelTime > 0` (huỷ xoá) nhưng toàn bộ nhánh chờ
  3 đến 14 ngày rồi xác nhận ở NPC Lạc Dương (268,46) hay Đại Lý (80,136) đã bị comment (`SelectRole.lua:355-371`),
  và máy chủ 2008 xoá ngay. Đề xuất: xoá ngay, `iDelTime` luôn 0, không làm `CLCancelDelChar`. Làm xoá trễ phải
  có NPC xác nhận và luật "không bang, không hôn nhân, không mở tiệm, không kết bái, không sư đồ" mà ta chưa có
  hệ thống nào kiểm; ngoài phạm vi G1. Bằng chứng phủ định (điều phối kiểm cấu hình XJL7457):
  `ConfigInfo.ini:175` `DeleteDelayTime=72` thuộc nhóm `[MinorPassword]` (cưỡng gỡ mật khẩu cấp hai), không phải
  xoá nhân vật; cấu hình đó không có khoá trễ xoá nhân vật nào.
- **D2 — mã từ chối (đã duyệt).** `enums.tsv` là catalog chung của M và N: nhắn KHOÁ cho `thienlong-1e` và
  `thienlong-14` trước khi sửa, báo MỞ sau khi commit. Đề xuất ánh xạ một-một vào bộ mã gốc, K đổi `ErrorCode` về mã gốc rồi gọi đúng hộp:
  SERVER_BUSY→`kBusy`, OP_TIMES→`kRateLimited`, OP_ERROR→`kOutOfOrder`, NOT_OWNER→`kNoSuchCharacter` (client gốc
  cũng hiện "lỗi lạ"), FULL→`kCharacterLimit`, SAME_NAME→`kNameTaken`, INVALID_NAME→`kNameInvalid` (đều có sẵn);
  thêm đúng ba mã mới cuối `enums.tsv`: 41 `NoCharacterToDelete` (EMPTY), 42 `CharacterOnline` (ONLINE),
  43 `Internal` (INTERNAL_ERROR). Danh sách: OP_FAILS→`kBusy`, OP_TIMES→`kRateLimited`. Sửa catalog thì
  `protocol_catalog_tests` và `protocol_tests` phải xanh.
- **D3 — trường của danh sách (đã duyệt nguyên tắc: chỉ thêm trường 14 xác nhận từ mã máy `0x140831780`,
  `0x14063b8f0`).** `equip[19]` trả rỗng tới G5 (chưa có trang bị): ghi vào `NGHI-NGO.md`. Đề xuất: giữ `id, name, level, gender, face, hair, school`; bỏ `scene` khỏi
  bảng chọn nếu K xác nhận script không dùng (chỉ cần khi vào game); thêm các trường có bằng chứng trong
  `GetRoleInfo` và dựng người mẫu: `portrait` (id đầu `m_HeadID`, K đổi sang tên ảnh), `hair_color`,
  `camp`, `pk_level`, `sale_state`, `delete_days` (luôn 0 theo D1), `equip[19]` (id mẫu trang bị nhìn thấy), cùng
  `last_selected` ở `CharacterList`. Chỉ thêm trường nào 14 xác nhận từ mã máy; trường nào ta không có dữ
  liệu (`sale_state`, `pk_level`) trả giá trị gốc mặc định (0), ghi vào `NGHI-NGO.md`. Cột mới ở PostgreSQL phải
  vào `sql/game/` có tệp migration; không sửa `001_character.sql` đã áp.
  - Xác nhận của 14 từ mã máy (bản ghi 420 byte `0x1a4` ở `CharSel+0x3c+i*0x1a4`, hàm `0x14063a240`, gói đọc tối
    đa 5 bản ghi ở `0x140831780`, trần 3 bản ghi hiển thị; độ lệch trong bản ghi bằng độ lệch trong gói): ĐÃ
    XÁC NHẬN `0x0c` tên (≤32 byte), `0x2c` cấp, `0x44` môn phái (cũng là khoá kiểm trang bị theo môn phái),
    `0x48` mã ảnh chân dung (bảng FaceImage cột 1 là tên ảnh), `0x128` `iDelTime` (luôn 0 theo D1), `0x1a0`
    `iPKLevel` (0). Người mẫu (`0x14063b8f0`): `u16[19]` trang bị nhìn thấy ở `0xa0..0xc5` (ô 16 thêm dword ở
    `0x11c`, id vật phẩm ở `0x94` để xét bộ theo môn phái), `0x188` ngoại hình vũ khí (u16, >0 thì thay ô 0),
    hai màu RGB 24 bit ở `0x190` và `0x194`, hai u16 mẫu ở `0x18a` và `0x18c`; năm int ở `0x08`, `0x30`, `0x38`,
    `0x3c`, `0x50` là tham số `CharacterData` chưa gọi được tên (14 đang đọc setter, sẽ gửi tên chốt trước khi
    sửa `messages.tsv`); thú cưng `0x130` (<11) và `0x134`. `iCYGSate` (giá trị Lua thứ sáu) không nằm trong bản ghi
    (mảng toàn cục theo ô), nên không có `sale_state`. Không thấy `camp` ở `CharSel` hay Lua: bỏ `camp` khỏi
    `CharacterSummary`. Danh sách trường cuối của `CharacterSummary`: `id, name, level, school, portrait,
    delete_days, pk_level, equip[19], hair_color, face_color, face_model, hair_model, weapon_look` (+ `gender`,
    `face`, `hair` đang có nếu 14 xác nhận chúng là các tham số trên); chốt khi 14 gửi tên của năm int.
  - Phép tạo (đề nghị của 14): luồng gốc hỏi `CLCheckAllowCreateChar` → `LCRetCheckAllowCreateChar` (u32) trước khi
    mở bảng tạo, để hiện `Role_Is_Full` đúng lúc. Ta không thêm tin hỏi riêng: `CharacterList` mang cờ `can_create`
    do máy chủ quyết (số nhân vật dưới `DB_CHAR_NUMBER` = 5 và phiên đang ở trạng thái cho tạo), K đọc cờ đó khi bấm
    "tạo". Giữ catalog nhỏ; nếu 14 thấy cần tin riêng cho giống gốc thì nói trước khi viết mã.
  - Chốt cuối D3 (14 gửi 2026-10-18, đọc thêm `0x1400b7f80` và `docs/TAO-NHAN-VAT-2026.md`): `0x08` giới (RaceID, assert
    gốc `nRaceID < 2`) là `gender` đang có; `0x38` hair_model (setter `0x140171df0`, id + 10000) ánh xạ vào `hair`; `0x3c`
    face_model (`0x1401725b0`, id + 10000) vào `face`; dây giữ id chưa cộng 10000, client cộng. `0x30` hair_color
    (setter `0x1401722e0`, chỉ có vị trí và kiểu làm chứng) và `0x50` (setter `0x1401738c0`, ghi `+0x968` rồi gọi hàm ảo
    `0x7e0`, cập nhật ảnh chân dung của dữ liệu nhân vật) KHÔNG lên dây: màn tạo 2026 không có ô chọn màu tóc
    (`CreateRole.lua` không có SetHairColor; đổi màu tóc là chức năng trong game sau này, `Change_MyHairColor`).
  - Ảnh chân dung PHẢI lên dây, không suy từ `face` (bằng chứng 14): (a) `docs/TAO-NHAN-VAT-2026.md` dòng 22 "Ảnh chân
    dung không gắn với kiểu mặt" và bảng dòng 17 (chín ô `CreateRole_Select_Head1..9`, `SetFaceId` lúc bấm tạo; bản
    port cũ suy ảnh từ kiểu mặt đã sai, sửa 2026-10-09); (b) `Game.exe` `0x1403435b0` (SetFaceId) ghi ô `+0x1b4` của
    đối tượng tạo (`FUN_140641a50` → `FUN_14063ed20`/`ed50`), khác ô `+0x1a4` của SetFaceModelId (`FUN_140641ab0`);
    (c) gói tạo `0x140641270` gửi cả hai ô (`+0x1a4` kiểu mặt, `+0x1b4` ảnh chân dung, `+0x1ac` tóc, `+0x1b0` giới,
    `+0x1b8` id bộ đồ); (d) bản ghi danh sách `0x48` là ảnh chân dung (`GetRoleInfo` `0x1403416e0` tra FaceImage theo
    `+0x48`), khác `0x3c` kiểu mặt. Bộ đồ tân thủ (`ChangeNewRoleEquipSet`, ô `+0x1b8` của gói tạo) cũng đi theo: server
    chỉ kiểm thuộc bảng và lưu, client đổi ra áo, giày, bao tay cho người mẫu màn chọn tới khi G5 có trang bị thật.
  - Danh sách trường CUỐI trên dây (v9): `CharacterSummary` = `id, name, level, gender, face, hair, school, scene` (đã có)
    cộng `portrait u16` và `equip_set u16`; `CreateCharacter` = `name, gender, face, hair` cộng `portrait`, `equip_set`;
    `CharacterList` cộng `can_create bool`. Không lên dây: `delete_days` và `pk_level` (luôn 0, client đặt cứng),
    `equip[19]` (rỗng tới G5), màu mặt/dye/mẫu, `hair_color`, `0x50`, `camp`, `sale_state` (xem `NGHI-NGO.md` 73).
    Hợp lệ phía server: ảnh chân dung thuộc đúng giới (15 id mỗi giới, `portraits.tsv` choice 1 hay 3), bộ đồ 0..2
    (`newbie_outfits.tsv`); cả hai là tập đóng trong `account/rules.cpp` (chưa có khoá `store.toml`).

- **D4 — điểm xuất phát nhân vật mới (điều phối chốt, ưu tiên cao: chặn mọi kịch bản nói chuyện với NPC).**
  Quy tắc chốt: nhân vật mới vào cảnh 2. Nếu (165,169) nằm trong vùng đi được liền với ô của 赵天师 (160,159)
  trên lưới `.path` 2026 thì giữ; không thì lấy điểm đi được gần (165,169) nhất (Euclid, hoà thì x rồi z) trong vùng
  liền với ô của 赵天师.
  - Bằng chứng nơi xuất hiện (điều phối, 1e, 14): gốc không ghi toạ độ spawn. `Config/startup.id` chỉ có "2"
    (cảnh Đại Lý); `ScenePosDefineEx.txt` nhị phân chưa mở; log client gốc `G:\XTLBB\Bin64\LogDirectory` không có
    dòng vào cảnh. 赵天师 ở (160,159) cảnh 2 (nhiệm vụ 1400 `MisDesc` (160,158); chuỗi `XSRW_100111_1`
    "看见在不远处的赵天师(160,159,2)"; XJL7457 `dali_monster.ini` guid 4736980); XJL7457 `scene.lua:752`
    `OnScenePlayerFirstLogin`. `DefaultChar.ini` của XJL7457 (cảnh 0, (186,324), cấp 15) là cấu hình mod: loại.
    (165,169) là số của bản 2008 (`rules/new_character.toml` `[profile]` và `[start_position]`, chép cứng ở
    `account/starter.hpp` `kScene`, `kPositionX`, `kPositionZ`).
  - Đo (công cụ tạm ở scratchpad, không vào dự án; dùng `nav::locate`, `nav::find_path`, `nav::crossings` trên
    `dev/server/scenes/dali/walk.path`, đúng tệp zone và client dùng):
    1. (165,169) là tam giác VẬT CẢN, không phải vùng bị bao kín và không phải lỗi nạp lưới: (164,169) đi
       được, từ đó `find_path` có đường tới cả bốn NPC 赵天师 (2 điểm), 都大爽 (158,164) (2), 孙八爷 (172,7;
       146,5) (4), 洪大贵 (183,141) (4), và tới quái ở (258,124) (11). Lời "vùng bao kín" trong `G0-K.md` của 14 đã
       sửa theo số đo này. Đoạn thẳng (165,169)→赵天师 cắt một cạnh ràng buộc, nên luật `plan_move` của client cho
       đi ra từ trong vật cản; →孙八爷 và →洪大贵 cắt ba cạnh nên bị từ chối cho tới khi bước ra chỗ đi được.
    2. Điểm đi được gần (165,169) nhất liền với 赵天师, quét lưới 1 cm: (165,00; 169,51), cách 0,51 m, nhưng chỉ
       cách một cạnh vật cản 0,9 cm (z 169,50 còn là vật cản). Quá mong manh: client và zone tính float lệch
       chút là rơi lại vào vật cản. Điều phối chốt thêm điều kiện cách mọi cạnh ràng buộc ít nhất 20 cm, đúng độ
       lệch `Scene::blocked` dùng (`kWalkSlackCm`).
    3. Với điều kiện đó (quét 1 cm trong bán kính 6 m, thứ tự xét: khoảng cách Euclid tăng dần rồi x rồi z, tính
       khoảng cách tới cả 11.665 cạnh ràng buộc của lưới): **(165,00; 169,71)**, cách điểm sinh cũ 0,71 m, cách
       cạnh gần nhất 0,209 m. Từ đó có đường tới 赵天师 (3 điểm), 都大爽 (3), 孙八爷 (8), 洪大贵 (9), quái ở (258,124)
       (10). Gốc không có bán kính va chạm thân nhân vật: `tlbb_server` (AI, Map, Obj) chỉ có bán kính quét địch
       (`AI_Monster.cpp:266-272,650-654`) và khoảng tương tác (`AI_Human.cpp:356-358`), còn `CanGo` và `FindPath`
       là truy vấn điểm; số gốc duy nhất là điểm rẽ của PathLib cách đỉnh vật cản 0,1 m (`nav/route.cpp:20`
       `kBackOff`), nhỏ hơn 20 cm, nên 20 cm của điều phối được giữ.
    4. Cách nhân với 100 an toàn: `169,71 × 100,0 = 16971,0` đúng trong số thực 64 bit (đo bằng `py`), nên
       `static_cast<int32_t>` ở `book.cpp:232-233` không cắt hụt; `sql.cpp` lưu mét và đọc `round(x * 100)`.
  - Làm: đổi `kPositionZ` ở `account/starter.hpp` và `profile.position_z`, `start_position.position_z` của cảnh 2 ở
    `new_character.toml` thành 169,71, kèm comment `Khác gốc:` nêu lý do, cách tính và bằng chứng (nhiệm vụ 1400
    初涉江湖, chuỗi `XSRW_100111_1`, `dali_monster.ini` 赵天师 (160,159)); cảnh 71 và 72 của `[start_position]` chưa có
    lưới trong `dev/server/scenes/`, giữ 165,169 và ghi `NGHI-NGO.md`. `new_character.toml` sinh từ
    `DefaultChar.ini` qua `TOOLS/server/import_rules.py`: kiểm lượt nhập sau có ghi đè 169 không và thêm ghi đè điểm
    xuất phát ở đó nếu có. Điều phối đã duyệt quy tắc và số đo (cho phép sửa `new_character.toml`).
  - Đạt khi: bot mới vào game đi tới 赵天师 không bị kéo về, log kiểm có dòng `đi` tới gần (160,159); và
    `TOOLS/run/e2e/g0-talk.script` của K đạt từ nhân vật mới.
  - Kết quả D4 (2026-10-18, commit riêng trước phần còn lại của G1-M):
    - Sửa: `starter::kPositionZ` = 169.71 và `rules/new_character.toml` (`profile.position_z`, phần tử đầu của
      `start_position.position_z`) kèm `Khác gốc:`; `TOOLS/server/import_rules.py` có bảng `DEVIATIONS` để lượt nhập
      lại từ `DefaultChar.ini` không đưa 169.0 trở lại (test hồi quy `test_deviation_survives_reimport`: đỏ trước với
      `position_z = 169.0`, xanh sau); `Test/Server/account_tests.cpp:151` đổi kỳ vọng 16900 thành 16971 (số vàng của
      điểm sinh, giữ so sánh bằng; ca đỏ đúng một kỳ vọng khi đổi `starter.hpp` mà chưa đổi số này, xanh sau). Mục
      `NGHI-NGO.md` 72 ghi cảnh 71 và 72 chưa có lưới.
    - Đã chạy: dựng server 0 cảnh báo, ctest `account_tests`, `play_tests`, `zone_tests`, `gate_*`, `server_boot`
      xanh (`build/lane-server-ctest5.log`, `ctest6.log`); `test_import_rules.py` 10 ca xanh, 1 ca bỏ qua (cần
      `THIENLONG_LEGACY_ROOT`); `lint_config.py` sạch trên `new_character.toml`. Cài server và khởi động lại cụm
      lúc 06:00. E2E `e2e_g0.py --tag h1` (`build/e2e/G0/m/report-h1.txt`, `zone-kiem-h1.txt`): cả sáu bot vào ở
      `x=16500 z=16971`; số lần `kéo` pair 0, peers 0, walker 0, talk 0, fight 0 (trước: 59, 0, 30, 0, 0), straight
      190 (kịch bản cố ý đi thẳng vào tường); bot talk đi tới sát 赵天师, dòng `đi` cuối ở (161,08; 160,19).
    - Kiểm chéo (thienlong-14, ĐẠT): `g0-talk.script` với tài khoản mới đạt 6/6 bước, log kiểm có `vào x=16500
      z=16971`, ba dòng `đi` tới (161,75; 162,40), `nói` ở (160,80; 159,26) với 赵天师, không dòng `kéo`; `g0.script`
      đạt 8/8, hai bước đi dọc `kéo về 0 lần`, Move đầu `z_cm=16978` (điểm sinh cộng bước đầu).
    - Chưa kiểm: cảnh 71 và 72 (chưa có lưới).

## Làm (sau khi D1 đến D4 được duyệt)

1. Xoá theo bảy bước trên: kiểm sở hữu bằng danh sách tài khoản (phân biệt NOT_OWNER và EMPTY), nhịp 500 ms
   mỗi tài khoản ở gate, kiểm đang chơi ở gate (bảng phiên có nhân vật) rồi mới hỏi store, kiểm số nhân vật
   giảm. Trả danh sách mới khi thành công, `Reject` kèm mã D2 khi không.
2. `CharacterSummary` và `CharacterList` mang các trường D3; `account/sql.cpp` đọc và ghi chúng; tạo nhân
   vật điền giá trị khởi đầu như bản ghi gốc (`DefaultChar`).
3. Mã từ chối của tạo nhân vật và của danh sách theo D2.
4. Log kiểm: gate không ghi (G0-M), nên tạo và xoá không có dòng `zone: kiểm`. Bằng chứng E2E của gói này là
   mã bot in cho từng bước, dòng `zone: kiểm việc=vào` sau khi chọn nhân vật và hàng PostgreSQL.

## Không làm

- Không làm xoá trễ, `CLCancelDelChar`, tin hỏi riêng `CLCheckAllowCreateChar` (thay bằng cờ `can_create` trong `CharacterList`, xem D3; K quyết định có cần cờ `can_create` không,
  mục 4.4 của `MAY-CHU-SUY-RA.md`).
- Không đổi bố cục byte của đường dây gốc: đường dây ta là catalog riêng (bắt tay libsodium); chỉ đồng bộ
  nội dung và mã kết quả.
- Không viết test logic mới ngoài hai ca: hồi quy xoá nhân vật đang chơi (đỏ trước, xanh sau) và phân biệt
  NOT_OWNER với EMPTY. Test có sẵn của `account`, `gate`, `protocol` giữ xanh.

## Kịch bản và tiêu chí đạt

1. Bot mới `--roster` (đăng nhập, tạo hai nhân vật, xoá một, xoá lại cùng id, xoá id của tài khoản khác, xoá khi
   nhân vật còn đang chơi qua phiên thứ hai, xoá liên tiếp dưới 500 ms) in từng kết quả kèm mã.
   Đạt khi mã khớp bảng D2: thành công 0, lần xoá lại `kNoSuchCharacter`, tài khoản khác `kNoSuchCharacter`,
   đang chơi `kCharacterOnline`, hết nhân vật `kNoCharacterToDelete`, dồn nhịp `kRateLimited`.
2. Client của K đi bằng chuột: gõ tài khoản, chọn máy chủ, tạo, xoá rồi tạo lại, vào game; ảnh từng màn so
   layout gốc; mỗi hộp lỗi hiện đúng khoá chữ của bảng trên.
3. PostgreSQL: `deleted_at` được đặt đúng một dòng; các cột mới có giá trị đúng sau khi tạo và nạp lại.

## Kết quả D1 đến D3 (2026-10-18)

### Đã sửa

- Xoá nhân vật theo bảy bước gốc. `account/rules.*`: `RemoveStep` và `remove_step` dùng chung cho `MemoryBook` và
  `GameDb`, hết nhân vật là `kNoCharacterToDelete`, còn nhưng không có id này là `kNoSuchCharacter`. `GameDb::remove_character`
  chạy trong một giao dịch với khoá tài khoản chung với tạo nhân vật, đếm trước và sau, `affected == 1` và số giảm một,
  nếu không là `kInternal`. Gate (`gate/table.cpp`): nhịp 500 ms mỗi tài khoản (`kDeleteGapNs`, lần bị từ chối không làm
  mới mốc) trả `kRateLimited`; nhân vật còn trong phiên (đang chơi hay rớt mạng chờ Resume, chỉ so phiên của chính tài
  khoản nên không lộ nhân vật của ai) trả `kCharacterOnline`.
- Catalog v9 (`enums.tsv`, `fields.tsv`, `messages.tsv`, tệp sinh, `protocol_samples.hpp`, `PROTOCOL-TIN.md`): ErrorCode
  41 `NoCharacterToDelete`, 42 `CharacterOnline`, 43 `Internal`; `CreateCharacter` và `CharacterSummary` thêm `portrait u16`
  và `equip_set u16`; `CharacterList` thêm `can_create bool` (gate tính: dưới `kCharacterCap` = 3 nhân vật). Lý do nâng
  `min_version` lên 9 (`gate.toml`): `CharacterSummary` và `CreateCharacter` đổi bố cục và ErrorCode có giá trị mới, client
  v8 giải mã hỏng (`kBadEnum`, sai độ dài).
- Dữ liệu: migration `dev/server/sql/game/003_look.sql` (cột `portrait`, `equip_set`, nhân vật cũ nhận ảnh đầu bảng của
  giới: nữ 49, nam 52), `GameDb::create_character` nhận `Look` (mặt, tóc, ảnh chân dung, bộ đồ) và kiểm tập đóng của
  `LookPolicy` (ảnh chân dung đúng giới, bộ đồ 0..2); `rpc`, `realm`, `serve`, `book` đổi theo.
- Gate ghi một dòng khi bỏ khung zone lớn hơn `kMaxPlainBytes` (B1, việc sửa riêng làm sau): `gate: bỏ khung zone 0x<kind>
  (<n> byte), lần <k>`, ghi ở lần 1, 2, 4, 8...
- Công cụ và test: bot `--roster 1`; `Test/Server/account_tests.cpp` thêm `remove_tells_empty_from_not_owner` và các ca
  ảnh chân dung, bộ đồ trong `look_rejects_unlisted`; `config_tests` đổi kỳ vọng `min_version` 7 thành 9 (số vàng của
  `gate.toml`, giữ so sánh bằng); `fake_gate.hpp` và `gate_attack.cpp` mang `portrait`, `equip_set`, `can_create`.

### Đã chạy

- Dựng `lane-server` 0 cảnh báo, không `D9002` (`build/lane-server-build9.log`, `build10.log`). ctest 14/14 xanh
  (`build/lane-server-ctest9.log`): `config_tests`, `service_tests`, `server_boot`, `server_boot_source_clean`,
  `protocol_tests`, `account_tests`, `protocol_catalog_tests`, `play_tests`, `zone_tests`, `gate_tests`,
  `gate_motion_tests`, `gate_loop_tests`, `protocol_catalog_fresh`, `server_config_lint`.
- Hồi quy NOT_OWNER và EMPTY: đỏ trước, xanh sau. Với `remove_code(kEmpty)` vá tạm về `kNoSuchCharacter` (hành vi cũ)
  `account_tests` báo đúng một kỳ vọng sai: `account_tests.cpp:435: [remove_tells_empty_from_not_owner] hết nhân vật là
  EMPTY` (`build/lane-server-red-run.log`); khôi phục thì 14/14 xanh.
- Hồi quy xoá nhân vật đang chơi: đỏ trước, xanh sau, bằng bot `--roster 1` trên cụm thật. Gate thử đỏ dựng NGOÀI cây
  làm việc (`red_gate_build.py` ở scratchpad: biên dịch bản sao `table.cpp` có `is_online` luôn false bằng lệnh Ninja, link
  riêng; cây làm việc và `git diff` không dính dòng vá). Kết quả đỏ (`build/e2e/G1/m/roster-red-out.txt`), 2 bước sai:
  `SAI xoá nhân vật đang chơi: thành công, mong mã 42` (nhân vật đang chơi bị xoá được) và bước sau nó lệch theo
  (`SAI xoá nhân vật cuối sau khi đăng xuất: Reject mã 41`, vì nhân vật đã mất). Gate đúng trả về (SHA-256 của
  `dev/server/bin/thienlong_gate.exe` trùng bản trước khi thử) cho kết quả xanh (`roster-green2-out.txt`):
  `đúng xoá nhân vật đang chơi: Reject mã 42, mong mã 42`, `roster: 0 bước sai`.
- E2E `thienlong_bot --roster 1` trên cụm v9 (`build/e2e/G1/m/roster-g1-out.txt`), 14/14 bước đúng: tạo ba nhân vật
  (`can_create` true, true, false); xoá id của tài khoản khác mã 10 (`kNoSuchCharacter`); xoá nhân vật của mình, còn hai và
  `can_create` true; xoá lại id đã xoá mã 10; vào game rồi kết nối thứ hai xoá nhân vật đang chơi mã 42 (`kCharacterOnline`);
  đăng xuất rồi xoá được; xoá dồn dưới 500 ms mã 12 (`kRateLimited`); xoá khi hết nhân vật mã 41 (`kNoCharacterToDelete`).
- PostgreSQL (`pg_check.py`, chỉ đọc): `schema_version` 1, 2, 3; hai cột mới có; mọi nhân vật còn sống (400, kể cả
  dòng cũ được điền lại) mang ảnh chân dung đầu bảng của giới (nữ 198 dòng với 49, nam 202 dòng với 52); lượt `--roster` để lại ba nhân vật `deleted_at` đã đặt và một nhân
  vật của tài khoản kia còn nguyên.
- Cụm v9 chạy từ 06:39, `thienlong_bot --probe 1`: `giao thức: bot v9, cụm v9`.

### Chưa kiểm

- Client v9 (K): màn tạo gửi `portrait` và `equip_set`, hộp lỗi theo mã 41 đến 43, đọc `can_create`, người mẫu màn chọn
  mặc đúng bộ đồ. Client dựng từ HEAD (v8) bị từ chối bắt tay cho tới khi K đổi.
- Xoá dồn từ hai kết nối khác nhau của cùng tài khoản (mốc nhịp theo tài khoản nên phải chặn, chưa có bước E2E riêng).
- Đồng hồ nhịp ở tải cao: `delete_marks` giới hạn 4096 tài khoản trong cửa sổ 500 ms, chưa đo bằng `gate_attack`.
- Không làm (đã nêu ở `Không làm`): xoá trễ, `CLCancelDelChar`, nhịp 500 ms cho tạo nhân vật (gốc có, ta chưa).

### Tồn đọng

- B1 (khung zone lớn hơn 4104 byte bị bỏ im) mới có dòng log, chưa sửa nguyên nhân: gói riêng sau G1-M.
- `NGHI-NGO.md` 73: các trường gốc chưa có trên dây (`delete_days`, `pk_level`, `equip[19]`, màu tóc và màu mặt, trường `0x50`).
