# Làn B: dữ liệu cửa sổ cần từ máy chủ

Làn B (kỹ năng, chiến đấu, thanh hành động, khung nhân vật/mục tiêu) không sửa `src/shared/protocol/**` hay `src/server/**`. Hàm game đọc
`ui::script::Facts` (`src/client/face/ui/script/context.hpp`); dưới đây là trường còn chờ phía mạng ghi, kèm nguồn trong Game.exe 2026
(bản 9001, decompile ở `docs/TAILIEU/GAME-EXE-2026/decompile.zip`). Chưa có nguồn thì hàm trả giá trị hàm dựng của gốc.

| Trường Facts | Kiểu | Hàm game đọc | Nguồn trong mã máy gốc |
|---|---|---|---|
| `pool` offset `0x6b6988` | int32 | `BattleAssist:AskIsNeiGuaOpen` | Máy chủ ghi `n % 10 + 1` (vùng 0x1400d1120). Khi cờ còn 0 gốc gửi gói `CGZdZdRequest` (vtable `Packets::CGZdZdRequest`, trường loại = 0xc, 0x1403cfa40) để hỏi; protocol của dự án chưa có gói này. |
| `pool` offset `0x649e10`, `0x649e80` | int32 | `MaritialSys:GetLastDayMonsterTip` | Hai trường do gói xử lý ở 0x140505bb0 vùng (dòng 27591..27645 của tệp decompile 140505bb0-14057f950.c) ghi; `0x649e80` lấy `+0xb8` của gói khi đang 0. |
| `pool` offset `0x5c0318`, `0x5c031c` | int32 | `DataPool:GetZMSectUsePlanIndex` | `0x5c0318` = `+0x60` của gói xử lý ở 0x140505bb0 vùng (dòng 24821); `0x5c031c` chỉ script ghi (0x1402d99e0 vùng, dòng 25530). |
| `pool` offset `0x5f9b18` | int32 | `DataPool:GetCurrentFreshManGuideItemValue` | Setter 0x140105d10 (chỉ ghi khi giá trị >= 0). |
| `combat.self_impacts` | tập id int32, trần 256 | `XRZPVP:IsInBattleSceneAndTransfer` | Map hiệu ứng ở `CObject_Character + 0x180` của nhân vật người chơi (tra bằng 0x1405dfc60); máy chủ gửi danh sách impact (gói buff/impact của nhân vật). |
| `combat.action_counts[mã loại]` | int32 theo mã 0..203 | `GetActionNum` | Số `CActionItem` trong map hành động của CActionSystem theo loại (0x140017190); kỹ năng (mã 1), kỹ năng sống (2), tâm pháp (7)... do client dựng từ danh sách kỹ năng máy chủ gửi. |

Chưa làm (cần đối tượng đang chọn ở client): `XRZPVP:IsInBattleSceneAndTransfer_TargetID` (0x1403ade30) luôn 0.
