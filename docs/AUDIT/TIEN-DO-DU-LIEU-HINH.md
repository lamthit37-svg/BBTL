# Tiến độ nợ dữ liệu và hình (2026-10-13)

Người làm: executor dữ liệu/hình. Sao lưu mọi tệp trước khi sửa ở `build/backup-dulieu-20261013-175021/`.

## Phần 1. Nợ dữ liệu (5 test đỏ)

| Test | Trước | Sau | Cách |
|---|---|---|---|
| ui_create_tests | đỏ (thiếu số vàng) | xanh | trọng tài `lua_oracle.py` chạy CreateRole.lua trên `F:/tl 2026/2026/Bin64/LuaPlus.dll`, 2393 dòng (đúng số dòng tài liệu ghi) |
| ui_quest_tests | đỏ | xanh | trọng tài QuestLog.lua, 150 dòng. Bỏ 4 dòng dịch ở `TOOLS/port/oracle/words.vi.tsv` (任务所在地：, 任务发布人：, 任务等级：, 不可追踪) vì commit ae33f70 đã đưa bốn nhãn này của bản port về chữ Trung gốc |
| config_tests | đỏ (thiếu scenes/huoyangu/scene.toml) | xanh | `export_scene.py` từ `D:\TÀI LIỆU TLBB\TLBB_0859602_Win10_11\tlbb` vào `dev/server/scenes` |
| server_data_lint | đỏ (55 lỗi) | 0 lỗi khi chạy tay `thienlong_lint` | `import_legacy.py` sinh lại 56 bảng `tables/server` đã mất |
| gui_real_tests | đỏ, 11952 ô lệch | còn đỏ: 192 ô lệch ở 11 layout, và ca notes_are_known_gaps báo "ít tham chiếu hỏng" (từ 20 ghi chú trở lên) | golden `ui_rects.tsv` sinh lại; xem dưới |

Bằng chứng tất định:
- Cảnh: 244 cảnh, 1687 tệp đang có trong git sinh lại giống từng byte (so SHA256); 2110 tệp trong `DANH-SACH-MAT.tsv` (bản kê lúc mất 2026-10-09) khớp cỡ byte 2110/2110, gồm `huoyangu/scene.toml` 1990 B, `spawns.tsv` 7862 B, `walk.nav` 262148 B.
- Bảng chung: 635 tệp `tables/shared|variants` sinh lại giống từng byte bản đang có.
- quest_log_newcomer.tsv: 5126 B, đúng cỡ bản đã mất. create_role_newcomer.tsv: 119550 B, bản mất là 119580 B (lệch 30 B, chưa truy ra nguyên nhân).
- Thử làm hỏng: sửa một ô của quest golden, một dòng của create golden, `schema = 7` trong huoyangu/scene.toml thì test tương ứng đỏ (exit 0xC0000409); trả lại thì xanh.

Sửa công cụ:
- `import_legacy.py`: xuất lại giữ tên cột và ghi chú đã đặt ở `TOOLS/server/columns/server` (cùng chỉ số, cùng nhãn gốc). Lượt chạy `build_data.py` lúc 18:15 đã ghi đè 29 tệp cột thành `column_N` / "?" (đã khôi phục từ HEAD, bản bị ghi đè lưu ở `columns-sau-build_data/`). Test mới `test_reexport_keeps_curated_names_and_is_stable`: hai lượt xuất liên tiếp ra tệp cột giống từng byte; bỏ phần sửa thì test đỏ. Chạy thật hai lượt trên dữ liệu 0859602: SHA256 của mọi tệp cột giống nhau, 0 tệp cột đã theo dõi bị đổi.
- `column_terms.tsv`: `ZhuanDan_ID` của ZhuandanConfig.txt thành `gacha_id` (转蛋 = gacha theo bảng thuật ngữ; cùng khoá `gacha_machines.gacha_id`). known_missing giữ nguyên.
- `skill_objects.tsv` đổi tiêu đề cột 6 `effect_description` thành `effect_note`, theo tệp cột ở HEAD (trước đây HEAD tự mâu thuẫn); không mã nào tham chiếu tên này.
- AGENTS.md:268 và docs/TAO-NHAN-VAT-2026.md mục 6: đường dẫn `F:/tl 2026/Bin64` thành `F:/tl 2026/2026/Bin64`; trong tài liệu, `_raw` thành `_goc`, `CLIENT/data` thành `dev/client/assets`.

gui_real_tests:
- Bảy hoạt ảnh layout gốc nhắc tới mà dữ liệu gốc không khai (CoolDownEnd2, ChatSignMini_MPMJ_1, HZJYR_Luck, HZJYR_Success, ShuangDan_Huoguo_Counting_Light, BaoJian1, XinShouNew_SheJiaoDaRen_RewardFrame_Flash). Lệnh làm bằng chứng (PowerShell):
  `(Get-FileHash 'F:\tl 2026\_goc\Interface\Schema\wowanimate.xml').Hash -eq (Get-FileHash dev\client\assets\Interface\Schema\wowanimate.xml).Hash` ra True;
  `gci 'F:\tl 2026\_goc\Interface' -Recurse -Include *.xml | Select-String -SimpleMatch 'Animate Name="<tên>"'` ra 0 kết quả cho cả bảy tên (Minimap_arrow ra 1).
  Test vẫn bắt mọi hoạt ảnh thiếu khác.
- Golden chỉ gồm 2035 layout PC có bản gốc. 36 layout `phone/` do dự án tự dựng có cửa sổ trùng tên cửa sổ PC, mà test tra ô theo tên cửa sổ; nhánh `phone/` thêm vào ui_rects.py trước đó (golden 390060 dòng) đã gỡ. Golden bây giờ có 378216 dòng (45 MB). Bản mất có 13034 dòng vì lúc đó mới gom ít layout. Test chỉ nạp layout PC khi so golden, và ghi mọi dòng lệch (cỡ màn hình, layout, cửa sổ) vào `build/msvc-release/gui_real_misses.tsv`.

Chưa đạt / chưa làm:
- 37 bảng `tables/server` mới sinh khác cỡ bản đã mất, vì tệp tên cột của chúng mất trong vụ 2026-10-09 nên có cột `column_N`. Chưa phục hồi tên.
- `TOOLS/server/lint_names` (cổng của build_data.py) báo lỗi ở column_terms.tsv. Lỗi này có từ trước và làm build_data.py thoát mã 1.
- `export_tables.py` (bảng chung) cũng ghi đè tệp cột ở `columns/shared` như import_legacy (3 tệp, đã khôi phục). Chưa sửa.
- `lua_oracle.read_words` bỏ mọi dòng bắt đầu bằng `#`, nên các mục dịch như `#Y任务目标：#W` bị lờ đi. Chưa sửa.
- release\server chưa có scenes\huoyangu.
- `DiskSource::read` âm thầm dùng `phone/X` khi thiếu bản PC: chưa ghi log.
- Phần 2 (hình) và phần 3 (APK): chưa bắt đầu.
## gui_real_tests sau khi sửa (18:50)
192 ô lệch, chi tiết ở `build/msvc-release/gui_real_misses.tsv`: ContexMenu 48, BieYePersonnelManage 40, Chengzhan_TopList 32, BaZheTianXia_Pop 24, Chengzhan_BangHui_TopList 16, ZM_Boss_Dps 8, NewBangHui_Auction 8, test 4, ZBS_TeamInfo 4, NoDiffMatch_TeamInfo 4, PetAgname 4. Cả 11 layout đã gom giống từng byte bản gốc (so SHA256), nên chỗ lệch nằm giữa module gui C++ và bộ mô phỏng độc lập ui_rects.py: đây là chỗ khác ngữ nghĩa thật, chưa sửa. Ví dụ BieYe `_Text_3`: golden rộng 64, Hub 65; BaZheTianXia_Pop: Hub lệch x 8 điểm ảnh. Bản golden cũ (13034 dòng) chưa phủ các layout này.

Commit: c893cce (import_legacy giữ tên cột), ea38b3a (trọng tài quest_log, tài liệu). Golden và dữ liệu sinh ra (Test/golden, dev/server/scenes, 56 bảng tables/server mới) chưa commit, vì chưa được theo dõi và tái tạo được bằng lệnh ở trên.