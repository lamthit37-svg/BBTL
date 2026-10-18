# G2-K: HUD nhân vật, phần client — phiếu

Làn K (`thienlong-14`). Viết trước khi có mã G2 (2): chỗ nào là đo thì ghi số, chỗ nào là kế hoạch thì
ghi "kế hoạch". G2 (1) (tên, thanh máu, chữ bay dưới cửa sổ) là sửa lỗi, không cần phiếu.

## 1. Cửa sổ gốc và hiện trạng (đo 2026-10-18)

Nguồn: `src/client/script/windows.tsv`, script `Interface/<tên>/<tên>.lua`, địa chỉ ở
`docs/TAILIEU/GAME-EXE-2026/lua_api.tsv`. "Thiếu" là số lời gọi `Player:`, `Target:`, `DataPool:`, `Pet:`,
`Talk:`... mà script gọi nhưng không có tên đó trong `ui/script/*.cpp` (quét chữ, số gần đúng; bước 1 của
mục 6 đo lại bằng chạy thật).

| Cửa sổ (id) | Dòng Lua | Panel C++ | Thiếu | Hàm gốc chính (Game.exe) |
|---|---|---|---|---|
| PlayerFrame (42) | 1243 | player_frame | 9 | SelectMyselfAsTarget 0x140687ca4, ShowMySelfContexMenu 0x140687c98, IsRaidLeader 0x140398f40 |
| TargetFrame (43) | 1155 | target_frame | 36 | GetHPPercent 0x1402b8050, GetMPPercent 0x1402b80e0, GetRagePercent 0x1402b8200, GetFullName 0x140687a0c, IsTargetTeamMember 0x1402be820 |
| MainMenuBar (17) | 2180 | menubar, action_bar(s), desk, skill_bar | 33 | IsCanDoAction 0x1402e7d70, Get_RMB_ChatActionInfo 0x1402f2bf0 |
| MainMenuBar_2/3/4, FunctionBarRight(_2) | 102–312 | main_menu_bar_2/3/4, function_bar_right(_2) | 3–10 | Pet:GetIsFighting 0x140372ff0, Talk:EnumChatMood 0x14047e8a0 |
| MiniMap (36) | 1722 | minimap | 11 | GetPKMode 0x140387250, InTeamFollowMode 0x140385d90 |
| PlayerImpactFrame (72), TargetBuff (90) | 499, 100 | không có | 5, 2 | GetBuffIconNameByIndex 0x140687a34, GetBuffTimeTextByIndex 0x140687c68, GetBuffToolTipsByIndex 0x140687c50, DispelBuffByIndex 0x140687c5c, Target:GetAllBuffIconName 0x140687a44 |
| AutoAttack_Button (1716) | 229 | không có | 0 | — |
| ProgressBar (123) | 53 | progress_bar | 0 | đã chạy bằng script (`kScripted`) |

Nhiều hàm là "chuyển tiếp ô ảo" của đối tượng nhân vật (ô 7, 9, 69–71, 75, 76); bản dịch của Ghidra mất
lời gọi ảo, nên đọc vftable bằng REA trước khi viết, không đoán thân hàm.

## 2. Panel C++ hay script — giữ cái tốt hơn

Với mỗi cửa sổ đã có panel: chạy cả hai (`THIENLONG_UI_SCRIPT=<tên>`), so theo thứ tự đúng gốc, đủ, hiệu năng
Release, chất lượng mã; ghi bảng so vào phiếu này; chỉ xoá panel khi có bảng. Cửa sổ chưa có panel
(PlayerImpactFrame, TargetBuff, AutoAttack_Button) đi đường script.

## 3. Tin máy chủ cần (6a đọc trước khi viết mã)

- Đã có trong giao thức dự án: `SelfStats` (cấp, kinh nghiệm, tiền), `SelfVitals` (sinh lực, nội lực, nộ khí),
  `EntityVitals` (phần trăm của người khác).
- Chưa có: tin buff (không có chữ "buff" trong `messages.hpp`). Gốc: `GCCharBuff` 485, `GCCharImpactListUpdate`
  1353, `GCDetailImpactListUpdate` 168 (`packets.tsv`). Thuộc tính chi tiết gốc: `GCDetailAttrib` 687,
  hỏi bằng `CGAskDetailAttrib` 143. Chọn mục tiêu: `GCSelectTarget` 376, `CGSelectTargetOfObject` 403.
- Đề nghị 6a cho biết tin nào đã/sẽ có theo `HO-SO.md` G2/M; client chỉ vẽ cái máy chủ gửi.

## 4. Không làm (thiếu bằng chứng hoặc chờ gói khác)

- Khung đội và raid của TargetFrame (`TargetFrame_Update_*_Team/_Raid`, `IsRaidLeader`), thẻ đồ giám
  (`GetTujianBit`, `GetDirectory_TujianCard`), `GetHdSandBoxPercent`: cần hệ thống của gói khác.
- `Helper:GotoExchangeMoney`, `GotoRecUpdate`, `Bank:CheckIsInTServer`, `DataPool:Lua_SetMeiLiValue`,
  `Player:PVP_ShowMenu`, `Guild:AskGuildNameList`, `DataPool:GetAccVipLevel`: ghi `NGHI-NGO.md` kèm gói chặn.
- Hàm chưa đọc được thân bằng REA: không viết theo suy đoán, ghi NGHI-NGO.

## 5. Kịch bản E2E và tiêu chí đạt

`TOOLS/run/e2e/g2-hud.script` (`#! account fresh`, `expect-shots`, tài khoản `e2eg2k<số>`, ra ở `build/e2e/K-G2/`):
vào game; chụp HUD đủ cửa sổ; bấm một quái → TargetFrame đổi tên và thanh máu; mất máu → PlayerFrame đổi;
chụp thanh kỹ năng; chụp minimap.

**Đạt khi** (theo `HO-SO.md` G2): số trong ảnh HUD khớp log kiểm và PostgreSQL; chọn quái thì TargetFrame
đổi; thanh kỹ năng có đúng sáu chiêu DefaultChar `[0,1,21,22,34,35]`. Ảnh so được với layout gốc.

## 6. Thứ tự làm (kế hoạch)

1. Đo lại số "thiếu" bằng chạy thật (khảo sát host), ghi vào mục 1.
2. Buff: PlayerImpactFrame và TargetBuff bằng script, sau khi 6a có tin buff.
3. PlayerFrame, TargetFrame: viết native còn thiếu, so với panel, bảng so.
4. MainMenuBar và các thanh: native action/chat-action, so với panel.
5. MiniMap, AutoAttack_Button; chạy `g2-hud.script`; xin kiểm.
