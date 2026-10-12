# Kết quả P1 đợt 2

A, B, C làm song song, R là phiên mới. Không commit. Bước tách hàm xong thì `treehash.py` trùng `moc/treehash.txt` từng dòng, rồi mới đổi đầu ra.

## 1. Tiêu chí

Lệnh chạy ở gốc dự án sau khi `build_data.py` đã gọi `import_rules.py` và `scene_refs.py`. `<tlbb>` là `C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`. `<_raw>` là `F:\tl 2026\_raw`. Log ở `build/p1-l/`.

| Mã | Kết quả | Lệnh và output |
|---|---|---|
| T1 | Đạt | `python -W error -m unittest discover -s TOOLS/server -p "test_*.py"`, không đặt hai biến. `Ran 173 tests in 0.394s`, `OK (skipped=8)`. Tám test bỏ qua vì thiếu `THIENLONG_LEGACY_ROOT` hoặc `THIENLONG_RAW_ROOT`: `test_two_digests_match`, `test_real_tree_if_present`, `test_real_tables_roundtrip`, `test_real_tree` của legacy, `test_real_tree` của rules, `test_real_scripts_if_present`, `test_real_config_is_classified`, `test_every_source_file_once`. |
| T2 | Đạt | Cùng lệnh, đã đặt hai biến. `Ran 173 tests in 450.710s`, `OK`. Không có dòng `skipped`. Output chỉ còn dòng của `unittest`. |
| T3 | Đạt | `python -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` thoát 0. `tables/server: 70 tệp, 46460 bản ghi`. `tables/shared: 574 tệp, 991160 bản ghi`. `tables/variants: 61 tệp, 3765 bản ghi`. `scenes: 3797 tệp, 54959 bản ghi`. `config/rules: 6 tệp, 0 bản ghi`. Luật: 131, tiến trình 26, bỏ 9, chưa rõ 412, lệch tiến trình 0. Lời gọi cảnh: 250, chú thích bỏ 5, how constant 48, format 50, literal 140, unresolved 12. |
| T4 | Đạt | Cùng lệnh thêm `--digest`, hai lần, đều thoát 0. Cùng một dòng `sha256: d3ffb5bf6599f34f341cc19d10f7136eb48c1b277cebdbb1ae6041a25cbadb62`. |
| T5 | Đạt | `python -W error TOOLS/server/lint_py.py` thoát 0, không in dòng. |
| T6 | Đạt | `python TOOLS/server/lint_config.py` thoát 0: `18 tệp sạch, 237 cài đặt`. 12 tệp tiến trình cộng 6 tệp luật. 244 `SERVER/scenes/*/scene.toml` thoát 0: `244 tệp sạch, 4623 cài đặt`. |
| T7 | Đạt | `treehash.py` trước và sau T2, năm dòng trùng nhau. Xem mục 2. |
| T8 | Đạt | `verify_p1.py` thoát 0. A: 635 bảng, 994925 bản ghi, 18636500 ô, lệch 0. B: 67 bảng, 41634 bản ghi, 92 tệp chữ, 22 tệp ini, lệch 0. C: 244 cảnh, 1577 bảng spawns, 40168 dòng, lệch 0, `walk.nav` khớp 244. D: 4730 tệp TSV, vấn đề 0. Hai dòng không phải ô lệch: `flight_maps.tsv` không phải bảng chữ có dòng kiểu; `item_segment_values.tsv` có 1 dòng ô thừa sau 65 cột kiểu. Khoá ini vắng để ô trống: 4546. |
| T9 | Đạt | `kiem/phu.py` thoát 0. Khoá nguồn 578, dòng luật 578, thiếu 0, thừa 0, trùng 0. Fate: rule 131, process_config 26, dropped 9, unknown 412. `Public/Scene` 3251 tệp, `scene_attach.tsv` 45 dòng (10 `scene_set`, 35 `client_only`), thiếu trên đĩa 0. `column_alignment.tsv` 76 dòng. `ops` 0, `vals` 0. |
| T10 | Đạt | `git status --short` 46 dòng, trùng `moc/git-status.txt`, thêm 0, bớt 0. Tệp đợt này nằm trong `?? TOOLS/server/`, `?? docs/giao-viec/`, `?? SERVER/`, cả ba đã có trong mốc. `phu.py` thấy chữ `Account.txt` hoặc `password` ở 6 tệp, toàn trong `docs/giao-viec/P1-DOT-2/`, không có trong `SERVER/tables` hay `SERVER/scenes`. Không mở `Account.txt`. |

## 2. SHA-256

`build_data.py --digest` hai lần:

`sha256: d3ffb5bf6599f34f341cc19d10f7136eb48c1b277cebdbb1ae6041a25cbadb62`

Mã này trùng mã R in ở bước 4. Gắn `import_rules.py` và `scene_refs.py` vào lệnh không đổi byte của `tables` và `scenes`: luật TOML không nằm trong mã băm, `scene_load_refs.tsv` ghi lại cùng byte.

Năm dòng `treehash.py` trước T2, sau T2, và sau T4:

```text
SERVER/tables/shared: 574 tệp, 91885649 byte, ec8f90ea675fb6f4
SERVER/tables/variants: 61 tệp, 2024362 byte, 03024419321c7627
SERVER/tables/server: 70 tệp, 8660785 byte, f666efecc8577cf0
SERVER/scenes: 3797 tệp, 149647004 byte, 7b13dc5b68556b0e
TOOLS/server/columns: 716 tệp, 1179128 byte, fbf28991cf95a421
```

Mốc đầu đợt ở `moc/treehash.txt` khác năm dòng này. Khác vì đợt này đổi tên cột, thêm cột `within_declared_count`, thêm `scene_load_refs.tsv` và tệp `set_`.

## 3. Bảng nợ

| Mã | Trạng thái | Chứng |
|---|---|---|
| C-01 | Đã trả | `export_scene` trong T3 thoát 0. 3251 tệp cảnh đã phân loại. 45 dòng `scene_attach.tsv`: 10 `scene_set` đã xuất (`spawns.set` 7, `areas.set` 3), 35 `client_only` không xuất. Đề ghi sơ bộ 7 và 38. C đo lại 10 và 35: thêm hai tệp `yamentianshanmis` do hằng script, và năm cảnh đăng nhập là 35 tệp không phải 38. |
| C-02 | Đã trả | `build_data.py` có `--dest`, mặc định vẫn `SERVER/`. `test_two_digests_match` ghi `build/p1-l-build/digest`. T7: năm băm không đổi sau T2. |
| C-03 | Đã trả | T5 thoát 0 trên mọi `TOOLS/server/*.py`. Trước khi tách, cổng báo đúng 13 hàm ở mục 2 của đề. Sau tách, `treehash` trùng mốc. |
| C-04 | Đã trả | `phu.py`: `scenes within=1 723 within=0 200`, `scene_hosting.tsv` 923 dòng `{'1': 723, '0': 200}`, `rolling_announcements.tsv` 10 dòng toàn 0, `scheduled_events.tsv` 30 dòng toàn 0, `random_shop_goods.tsv` 458 dòng `{'1': 457, '0': 1}`. Cột cấm không còn. Ba khoá `[info]` nằm trong `global.toml`. |
| C-05 | Đã trả | `phu.py`: `ops` 0, `vals` 0. T6: 244 `scene.toml` sạch. |
| C-06 | Đã trả | T1 và T2 chỉ in dòng của `unittest`. |
| C-07 | Đã trả | `tsv_file.owned_tool` và `table_census.coverage` là hàm công khai. `export_tables.py` và `import_legacy.py` gọi hai tên đó, không gọi tên `_`. |
| C-08 | Đã trả | R bước 4 chạy lại T1 tới T10, kể cả lệnh sinh cả cây, rồi mới ghi mục Phán quyết. T7 đo trước và sau T2. |

## 4. Tệp theo vai

L:

- `TOOLS/server/lint_py.py`, `test_lint_py.py`: cổng G1 tới G6.
- `TOOLS/server/build_data.py`, `test_build_data.py`: `--dest`, rồi gọi thêm `import_rules` và `scene_refs`.
- `TOOLS/server/tsv_file.py`: `owned_tool` có kiểu, `prepare_directory(..., keep_tools=)`, owner `C` cho `public_data/Script`.
- `TOOLS/server/table_names.tsv`: dòng `scene_load_refs.tsv`.
- `TOOLS/server/table_census.py`: hàm `coverage`.

A: `align_columns.py`, `column_terms.tsv`, `column_alignment.tsv`, `export_tables.py` và test, tệp cột `columns/shared` và `columns/shared/variants`.

B: `import_rules.py`, `legacy_rules.tsv`, `import_legacy.py` và test, sáu toml trong `SERVER/config/rules/`, năm bảng C-04.

C: `scene_refs.py`, `scene_attach.tsv`, `export_scene.py`, `scene_load_refs.tsv`, tệp `set_`, đổi tên `spawn_operates.` và `spawn_operate_values.`.

R: `REVIEW.md`, script trong `kiem/`.

Báo cáo: `BAO-CAO-A.md`, `BAO-CAO-B.md`, `BAO-CAO-C.md`, `DOI-CHAT-A.md`, `DOI-CHAT-B.md`, `DOI-CHAT-C.md`, `KET-QUA.md`.

## 5. Số đo

Căn cột, sau khi sửa R-A-01, `kiem/phu.py`: 76 cặp, cột 2026 là 4517, cột 0859602 là 3157, neo 945, nội suy 779, đổi kiểu 173, mới ở 2026 là 2620, mất 1260. `column_terms.tsv` 270 dòng: glossary 1, code 70, direct 199. Bảng tổng từng bảng ưu tiên ở `BAO-CAO-A.md` mục 3 là số trước lần sửa nội suy. `PlayerExpLevel.txt` cùng bố cục, không có dòng trong 76 cặp.

Luật: 578 khoá, fate như T9. Hai khoá `unknown` không mang lý do `chưa làm ở đợt 2`: `TimeSetting.SMUKickUserTime`, `CacheLogTime.LogInCacheTime`. 410 khoá còn lại mang lý do đó. Bảy tệp chưa sinh: `pet.toml`, `hidden_weapon.toml`, `pvp.toml`, `guild.toml`, `social.toml`, `economy.toml`, `fatigue.toml`. Lệch giá trị ini với mười một tệp TOML tiến trình: 0.

Cảnh: 250 lời gọi, how như T3. Đối chiếu 1344 tệp sau X-BC-01, lời của C trong `DOI-CHAT-C.md`: trỏ 1123, không trỏ 221, có trỏ nhưng không suy được Map 180, lệch 80. Bước 5 không chạy lại hàm đối chiếu đó. Không chuyển tệp.

## 6. Finding

Phán quyết của R trên mã cuối, trong `REVIEW.md`:

| Mã | Phán quyết |
|---|---|
| R-A-01 | ĐÃ SỬA |
| R-A-02 | ĐÃ SỬA |
| R-B-01 | ĐÃ SỬA |
| R-B-02 | ĐÃ SỬA |
| R-C-01 | ĐÃ SỬA |
| X-AB-01 | ĐÃ SỬA |
| X-AB-02 | ĐÃ SỬA |
| X-AB-03 | ĐÃ SỬA |
| X-BC-01 | ĐÃ SỬA |
| X-BC-02 | ĐÃ SỬA |
| X-BC-03 | ĐÃ SỬA |
| X-CA-01 | ĐÃ SỬA |
| X-CA-02 | ĐÃ SỬA |
| X-CA-03 | BÁC ĐÚNG |

## 7. Tranh chấp và còn mở

Không có `TRANH CHẤP`. Không có `CÒN MỞ`.

X-CA-03: cột 270 của `shops.tsv` vẫn nội suy `PID(商品编号44)`, khớp 12/172. Phía 2026 có 2 giá trị khác nhau, dưới ngưỡng 3. Đề cho nội suy khi cột nằm giữa hai neo và không đủ điều kiện tự làm neo. R bác đúng.

## 8. Chưa kiểm, giả định, lệch

Chưa kiểm:

- Chưa chạy lại `compare_level_files` của C. Số 1123, 221, 180, 80 lấy từ `DOI-CHAT-C.md`.
- Chưa chạy `game::table::parse_tsv` trên bảng đã sinh. T8 đọc TSV bằng bộ đọc riêng của `verify_p1.py`.
- Chưa chạy exe máy chủ 2008.
- Mẫu ngữ nghĩa 30 dòng thuật ngữ và 40 dòng luật là của R ở bước 2, không lấy mẫu lại ở bước 5.

Giả định:

- 10 và 35 là phân loại đúng của 45 tệp, không phải 7 và 38 trong câu đo sơ bộ của đề.
- Owner `C` và `keep_tools` là cách để hai công cụ cùng ghi `SERVER/tables/server` mà không xoá tệp của nhau.
- Mã SHA-256 không gồm `SERVER/config/rules`. Sáu toml luật vẫn được lệnh sinh lại.

Lệch:

- Đề nói 7 tệp script và 38 tệp client. Đĩa đo 10 và 35. Lý do ở mục 3.
- `BAO-CAO-A.md` còn số căn cột trước R-A-01. Số sau sửa là mục 5.
- T3 in thêm dòng `config/rules`. Đề đợt 1 chỉ liệt kê bốn thư mục bảng và cảnh.
- Bảy tệp luật chưa sinh. Khoá của chúng là `unknown`, không xuất.

## 9. Ngoài phạm vi

Không sửa. Để đợt sau, đúng đề mục 9: tên cột máy chủ còn `?`, 91 tên bảng còn `?`, `diff_tables.py`, `thienlong_lint`, mã C++, `ai_convert.py`, `lua_extract.py`, nấu lưới, `.path`, `.stall`, `.ObjRegion`, dịch nội dung bảng, chuyển tệp cảnh giữa các thư mục. 80 tệp lệch cảnh nằm trong danh sách đó, chưa chuyển.
