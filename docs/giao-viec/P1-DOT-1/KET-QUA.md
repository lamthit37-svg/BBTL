# Kết quả P1 đợt 1

Subagent chạy được. A, B, C làm song song, R là phiên mới. Không commit.

## 1. Tiêu chí

| Mã | Kết quả | Lệnh và output |
|---|---|---|
| T1 | Đạt | `python -W error -m unittest discover -s TOOLS/server -p "test_*.py"`, không đặt hai biến môi trường. `Ran 117 tests in 0.321s`, `OK (skipped=6)`. Sáu test bỏ qua kèm lý do thiếu `THIENLONG_LEGACY_ROOT` hoặc `THIENLONG_RAW_ROOT`: `test_two_digests_match`, `test_real_tree_if_present`, `test_real_tables_roundtrip`, `test_real_tree`, `test_real_config_is_classified`, `test_every_source_file_once`. |
| T2 | Không đạt | Cùng lệnh, đã đặt hai biến. `Ran 117 tests in 72.545s`, `FAILED (failures=1)`. Không test nào bị bỏ qua. Fail: `test_two_digests_match`, `AssertionError: 1 != 0 : lần 1 thoát 1, tệp không gắn cảnh 45`. |
| T3 | Không đạt | `python -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"`. Thoát 1. Trước đó `table_census` in `tệp: 1877`, `chưa phân loại: 0`, `table: 635`, `bản ghi: 1198441`, `thời gian: 0.8 giây`. `export_tables` in `bảng đã ghi: 635`, `bản ghi: 994925`, `cột: 17247`, `cột có tên: 148`, `cột còn ?: 504`, `thời gian: 23.7 giây`. `import_legacy` in 69 dòng `bản ghi`, cộng lại 46210. `export_scene` in `cảnh: 244` rồi 45 dòng `không gắn được vào cảnh nào`. Không có dòng tổng kết `tables/server:` vì lệnh dừng tại bước cảnh. |
| T4 | Không đạt | Cùng lệnh thêm `--digest`, hai lần. Lần bọc PowerShell: thoát 1 và 1, 36,5 giây và 31,9 giây. Lần `subprocess` UTF-8: thoát 1, 45 lỗi gắn cảnh, không có dòng `sha256:`. |
| T5 | Đạt | Census `_raw/Config`: `tệp: 1877`, `chưa phân loại: 0`. Test `test_every_source_file_once` xanh trong T2, phủ `Server\Config`, `Public\Config`, `_raw\Config`. `Public\Scene`: các dòng `tệp nguồn` cộng lại 3251 (scn 244, nav 231, path 234, stall 73, object_region 28, monster 237, monster_by_level 1171, monster_group 153, monster_bare 2, monster_entrance 18, monster_level 2, area 233, patrol 229, growpoint 228, growpoint_setup 61, pet 63, platform 39, portal 2, bus 1, dropped 2). 45 tệp trong số đó không gắn được vào cảnh, đã có tên trong log, không phải tệp bỏ qua im lặng. |
| T6 | Đạt ở test của ba vai, lệnh cả cây thì cảnh không ghi nốt | Trong T2, `test_real_tables_roundtrip`, `test_real_tree` và `test_real_tree_if_present` xanh. R bước 4 đọc `SERVER/scenes/caoyuan/spawns.tsv` dòng 67 cột `level` là `-1`, nguồn `caoyuan_monster.ini`. 45 tệp không gắn cảnh làm cả lệnh xuất cảnh thoát 1. |
| T7 | Đạt | `python TOOLS/server/lint_config.py` thoát 0: `12 tệp sạch, 144 cài đặt đều có chú thích và thẳng cột`. Cùng công cụ trên 244 `SERVER/scenes/*/scene.toml` thoát 0: `244 tệp sạch, 4613 cài đặt đều có chú thích và thẳng cột`. |
| T8 | Đạt với phần đợt này | `git status --short`. Tệp đợt này nằm trong `TOOLS/server/`, `SERVER/tables/`, `SERVER/scenes/`, `docs/giao-viec/`. So với mốc bước 0, tập dirty của client đổi vì phiên kia vẫn sửa: thêm `SRC/gpu/gles/context_egl.cpp`, `TOOLS/content/collect_map.py`, `TOOLS/content/test_collect_map.py`, `docs/NGHI-NGO.md`, `tests/gpu_tests.cpp`. Một số tệp GLES có trong mốc thì không còn trong status. Đợt này không mở các tệp đó. Không `add`, không `commit`. |
| T9 | Đạt trong phạm vi không mở `Account.txt` | `rg Account.txt SERVER` không có dòng. `rg Account.txt docs/giao-viec` chỉ thấy tên tệp trong `DE-BAI.md`, `REVIEW.md`, `BAO-CAO-B.md` và `kiem/kiem_doc_lap.py`. Không có tệp mật khẩu trong `SERVER/tables` hay `SERVER/scenes`. |

`<tlbb>` là `C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`. `<_raw>` là `F:\tl 2026\_raw`.

45 tệp không gắn cảnh: `_pingpan_40`, `_pingpan_55`, `_pingpan_70`, `_pingpan_85` mỗi cái một `*_monster.ini`; `chuangjian` và `xuanren` mỗi cái bảy tệp (`.nav`, `.path`, `_area.ini`, `_growpoint.txt`, `_monster.ini`, `_patrolpoint.ini`, `_StallInfo.stall`); `gongdishaolinmis`, `jishiemeimis`, `yamentianshanmis` mỗi cái `_area.ini` và `_monster.ini`; `登陆` bảy tệp; `选人` bảy tệp; `选人11` bảy tệp.

## 2. Tệp theo vai

L:

- `TOOLS/server/tsv_file.py`, `TOOLS/server/test_tsv_file.py`: ghi, đọc, dọn thư mục, `format_float32`, `owned_tool`, đọc `table_names.tsv`.
- `TOOLS/server/table_names.tsv`, `TOOLS/server/test_table_names.py`: một dòng cho mỗi tệp của ba cây, cộng `Script.dat` và `AIScript.dat` ở `tree=public_data`.
- `TOOLS/server/build_data.py`, `TOOLS/server/test_build_data.py`: gọi bốn công cụ, in tổng kết, in SHA-256 khi cả bốn thoát 0.

A:

- `TOOLS/server/table_census.py`, `TOOLS/server/export_tables.py`, hai tệp test, `TOOLS/server/table_census.tsv`.
- `TOOLS/server/columns/shared/`: 635 tệp cột, biến thể ở `columns/shared/variants/<khoá>/`.
- `SERVER/tables/shared/`: 574 tệp `.tsv`. `SERVER/tables/variants/`: 61 tệp `.tsv`.

B:

- `TOOLS/server/import_legacy.py`, `TOOLS/server/test_import_legacy.py`.
- `TOOLS/server/columns/server/` và `SERVER/tables/server/`: 69 tệp `.tsv` mỗi nơi.

C:

- `TOOLS/server/export_scene.py`, `TOOLS/server/scene_read.py`, `TOOLS/server/scene_classify.py`, `TOOLS/server/test_export_scene.py`.
- `TOOLS/server/columns/scenes/`: 12 tệp cột.
- `SERVER/scenes/`: 244 thư mục, 244 `scene.toml`, 244 `walk.nav`, tổng 3787 tệp.

R:

- `docs/giao-viec/P1-DOT-1/REVIEW.md`.
- `docs/giao-viec/P1-DOT-1/kiem/kiem_doc_lap.py`, `pha.py`, `phan_buoc4.py`.

Báo cáo: `BAO-CAO-A.md`, `BAO-CAO-B.md`, `BAO-CAO-C.md`, `DOI-CHAT-A.md`, `DOI-CHAT-B.md`, `DOI-CHAT-C.md`, `KET-QUA.md`.

## 3. Số đo gộp

Lấy từ stdout của lần `build_data.py` thoát 1, log `build/p1-l/build-utf8.log`.

- Client 2026: 1877 tệp, 635 bảng xuất, 994925 bản ghi, 17247 cột, 148 cột có tên, 504 cột còn `?`, 33 cột chữ toàn số.
- Máy chủ: 69 bảng, 46210 bản ghi. Biến đổi theo `BAO-CAO-B.md` mục 3, đo từ stdout lệnh xuất của B trước vòng sửa sau: int khác nguyên văn 6259, dòng `#` bỏ 70, ô đầu rỗng bỏ 14, ô thừa rỗng bỏ 59, cắt chú thích ini 3124, `\` thành `/` 4307, cắt mô tả AI 269. Sau X-AB-01, stdout có thêm `dòng script bỏ 649` (R chạy lại `--check`).
- Cảnh: 3251 tệp đã phân loại, 244 cảnh ghi ra, 45 tệp không gắn. `walk.nav` trên đĩa lúc kết thúc: 244 tệp. `luoyang/walk.nav` R đo 1638404 byte.

## 4. Finding

| Mã | Mức | Chỗ | Một câu | Phán quyết |
|---|---|---|---|---|
| R-A-01 | CHẶN | `export_tables.py` | Một bảng lỗi vẫn ghi bảng khác và xoá bảng cũ | ĐÃ SỬA |
| R-A-02 | GHI | `export_tables.py` | `--check` in số bảng đã ghi bằng 0 | ĐÃ SỬA |
| R-C-01 | CHẶN | `caoyuan/spawns.tsv` | Cột `level` bị tệp level ghi đè, mất `-1` | ĐÃ SỬA |
| R-C-02 | SỬA | `export_scene.py` | Tệp không gắn cảnh vẫn thoát 0 | ĐÃ SỬA |
| R-C-03 | SỬA | `export_scene.py` | Ô int không chuẩn chưa đếm hết | ĐÃ SỬA |
| R-L-01 | SỬA | `tsv_file.py` | `format_float32` ném `OverflowError` ở float32 hữu hạn lớn nhất | ĐÃ SỬA |
| R-L-02 | GHI | `table_names.tsv` | Thiếu hai tệp `Public/Data` | ĐÃ SỬA |
| X-AB-01 | | `import_legacy.py` | `Script.dat` bỏ dòng chú thích mà không đếm | ĐÃ SỬA |
| X-AB-02 | | `import_legacy.py` | Cột `STRING` toàn số thập phân không được liệt kê | ĐÃ SỬA |
| X-AB-03 | | `import_legacy.py` | Kiểu trống xen giữa làm hỏng cả bảng | ĐÃ SỬA |
| X-CA-01 | | `export_tables.py` | Dòng id rỗng của bản đối chiếu bị bỏ không đếm | ĐÃ SỬA |
| X-CA-02 | | `export_tables.py` | Ô float `1e308` làm sập bằng `OverflowError` | ĐÃ SỬA |
| X-CA-03 | | `export_tables.py` | Id `1.0` không ghép được dù `atoi` ra 1 | ĐÃ SỬA |
| X-BC-01 | | `export_scene.py` | Lỗi tab không kèm tên cột | ĐÃ SỬA |
| X-BC-02 | | `export_scene.py` | Lượt lỗi vẫn ghi `spawns.tsv` | ĐÃ SỬA |
| X-BC-03 | | tệp cột `spawns.tsv` | Note nói `monster_level` ghi đè `level`; `PATROLPOINTNUM` chưa vào `int_places` | ĐÃ SỬA |

Lệnh R chạy lại nằm ở mục `Phán quyết` trong `REVIEW.md`.

## 5. Tranh chấp và còn mở

Không có `TRANH CHẤP`. Không có `CÒN MỞ`. Mười sáu finding đều `ĐÃ SỬA`.

## 6. Chưa kiểm, giả định, lệch

Chưa kiểm:

- Chưa chạy `game::table::parse_tsv` trên bảng đã sinh. A đọc lại bằng `tsv_file.read_table`.
- Chưa chạy exe máy chủ 2008. Exe bản chạy bị đóng gói.
- Chưa có SHA-256 của cả cây vì T3 thoát 1 trước `--digest`.
- Bước 5 không chạy lại `kiem/kiem_doc_lap.py`. R đã chạy các ca trong `phan_buoc4.py` và `pha.py` ở bước 4.

Giả định:

- 45 tệp không gắn cảnh là dữ liệu gốc không có `.scn` cha, không phải sót bộ lọc. Thoát 1 là đúng câu "không bỏ qua" của đề bài, và vì thế T3, T4 không đạt.
- Cột `key` trong `table_names.tsv` là giá trị khoá (`default`, `gacha_1`, `workshop_60`, `level_cap`). Cột thêm `key_field` ghi `box_key`, `shop_key` hoặc `variant`.
- `tree=public_data` chỉ có hai tệp `.dat`. Lua và `.ai` để đợt sau.

Lệch:

- Thêm `key_field` và giá trị tree `public_data`. Đề bài liệt kê ba giá trị tree. Hai tệp `.dat` là bảng của đợt này nên không để ngoài hợp đồng.
- Thêm `owned_tool()` vì A và B cần hỏi chủ tệp trước khi xoá. `_owned_tool` vẫn còn.
- C ghi thêm `spawn_operates.tsv`, `spawn_operate_values.tsv`, `ops.*.tsv`, `vals.*.tsv`, `spawn_levels.tsv`, `spawns.n<số>_level_<cấp>.tsv`, `spawns.level_<cấp>.alt.tsv`. Đề bài không có các tên này. Lý do nằm ở `BAO-CAO-C.md` mục 6.
- `build_data.py` dừng ngay khi một công cụ thoát khác 0, nên không in SHA-256 của cây dở.

## 7. Tài liệu cần sửa

Không sửa tài liệu trong đợt này. Bằng chứng từ lệnh và từ báo cáo của vai viết:

- `docs/KE-HOACH-SERVER.md` mục 9 nói census 718 bảng. Census in `bảng: 745` tệp `.txt`: 718 ở gốc `Config`, cộng 24 `AbilityLevelUp` và 3 `ActionSet`.
- Phụ lục mục 5 nói `SceneInfo.ini` có 924 cảnh. B đếm 923 section `scene0` tới `scene922`, `scenenumber=723`.
- Phụ lục nói `StandardImpact.txt` 9906 dòng. B: 2 dòng đầu + 44 dòng `#` + 9860 bản ghi.
- Phụ lục `Questions.txt` 3705, bản ghi xuất 3703. `StringTable.txt` 314, bản ghi 312. `DropBoxContent.txt` 2036 gói, bản ghi 2034.
- Phụ lục mục 7 cộng các hàng ra 3269 vì 18 tệp `PCity_monster_<lối vào>.ini` nằm ở cả hàng 1344 và hàng riêng. Đĩa `Public\Scene` là 3251. 1344 = 1171 + 153 + 2 + 18.
- Đề bài nói mọi tệp chữ 0859602 là CRLF. B đo `MountFlightMaps.txt` là LF, 0 byte CR.
- `MonsterAITable.ini`: mã 2008 `AIPARAM_NUMBER` là 9, tệp có `AIPARAM0` tới `AIPARAM10`. Phụ lục nói 11 tham số. B xuất đủ 11 và ghi cột mã không đọc.
- `ItemSegValue.txt` phía server: phụ lục nói 129 cột. Dòng kiểu có 65 `INT` và 64 ô kiểu rỗng. B giữ 129 cột, 64 cột cuối là `text`.

## 8. Đề nghị đợt 2

- Chốt 45 tệp không có `.scn`: bỏ, hay thành cảnh `scene_file = 0`. Chốt xong thì T3 và T4 mới thoát 0 và có SHA-256.
- Các việc đề bài để đợt 2: mười ba TOML luật chơi, `diff_tables.py`, `thienlong_lint`, `bake_nav.py`, giải tên còn `?`, `lua_extract.py`, `ai_convert.py`.
- Đọc bảng đã sinh bằng `parse_tsv` của C++ trước khi máy chủ nạp.
