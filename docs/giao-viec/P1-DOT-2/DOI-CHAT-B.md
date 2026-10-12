# Đối chất vai B

## Trả lời review

### R-B-01 NHẬN

Sửa ba `note_vi` trong `TOOLS/server/legacy_rules.tsv`, rồi ghi lại TOML.

- Dòng 176, `ExpPrenticeAddRate`: `Cộng kinh nghiệm sau khi nhận đồ đệ.`
- Dòng 573, `broadcount`: `Số lượng thông báo.`
- Dòng 575, `huodongcount`: `Số lượng hoạt động.`

Ba câu không còn "luân phiên", "theo giờ", "được khai báo". Chú thích trong `character.toml` và `global.toml` là đúng ba câu đó.

```text
python -W error TOOLS/server/import_rules.py "<THIENLONG_LEGACY_ROOT>" SERVER/config/rules
```

Thoát 0:

```text
luật: 131
tiến trình: 26
bỏ: 9
chưa rõ: 412
lệch tiến trình: 0
đã ghi: global.toml, combat.toml, monster.toml, character.toml, new_character.toml, instances.toml
```

```text
python -W error TOOLS/server/lint_config.py SERVER/config/rules/global.toml SERVER/config/rules/character.toml
```

`2 tệp sạch, 31 cài đặt đều có chú thích và thẳng cột`.

### R-B-02 NHẬN

`_foreign` trước đây trả mọi tệp không phải của `import_legacy.py`, kể cả tệp của `scene_refs.py`, rồi dừng trước `prepare_directory`. Giờ `_foreign` và `prepare_directory` cùng bỏ qua `KEEP_TABLE_TOOLS = ("scene_refs.py",)`. Chỉ thư mục bảng. Thư mục cột không giữ công cụ đó.

```text
python -W error TOOLS/server/lint_py.py TOOLS/server/import_legacy.py TOOLS/server/test_import_legacy.py
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
```

Lint thoát 0. Test, chưa đặt `THIENLONG_LEGACY_ROOT`: `Ran 23 tests in 0.031s`, `OK (skipped=1)`. Ca `test_keeps_scene_refs_table` ghi `scene_load_refs.tsv` của `scene_refs.py` vào thư mục xuất, rồi xuất tiếp: không có lỗi `tệp lạ`, byte tệp đó không đổi, `sample.tsv` vẫn được ghi.

`SERVER/tables/server/scene_load_refs.tsv` đã có sẵn `# tool: TOOLS/server/scene_refs.py`. Ba lần `build_data.py`, log ở `build/p1-b/doi-chat/`, không ghi vào `kiem/`:

```text
python -W error TOOLS/server/build_data.py --legacy "<THIENLONG_LEGACY_ROOT>" --raw "<THIENLONG_RAW_ROOT>"
python -W error TOOLS/server/build_data.py --legacy "<THIENLONG_LEGACY_ROOT>" --raw "<THIENLONG_RAW_ROOT>" --digest
python -W error TOOLS/server/build_data.py --legacy "<THIENLONG_LEGACY_ROOT>" --raw "<THIENLONG_RAW_ROOT>" --digest
```

Cả ba thoát 0. Không còn dòng `scene_load_refs.tsv:1: tệp lạ, không xoá`. Mỗi lần in bốn thư mục:

```text
tables/server: 70 tệp, 46460 bản ghi
tables/shared: 574 tệp, 991160 bản ghi
tables/variants: 61 tệp, 3765 bản ghi
scenes: 3797 tệp, 54959 bản ghi
```

Hai lần `--digest` in cùng một dòng:

```text
sha256: 600b710c540c50e5a081108e0ead72eda3bb360c5f6fdb7fdd4379d0909ce613
```

Sau ba lần chạy, dòng `# tool:` của `scene_load_refs.tsv` vẫn là `TOOLS/server/scene_refs.py`.

## Xét chéo C

Đã đọc `scene_refs.py`, `export_scene.py`, `scene_read.py`, `test_scene_refs.py`, `test_export_scene.py`. Chạy công cụ trên cây thật và trên cây giả trong `build/p1-b/`. Không sửa mã của C.

### X-BC-01 [CHẶN] Mẫu format qua biến cục bộ biến mất, tệp quái bị kể là không script nào trỏ

- Chỗ: `TOOLS/server/scene_refs.py:250` và `scene_refs.py:342`
- Bằng chứng: `python build/p1-b/xet_c7.py`

`bamboo_forest.lua:52` là `x050101_g_CopySceneMonsterIni = "zhulin_monster_%d.ini"`. Dòng 457 gán `local monsterINI = format(...)`, dòng 458 gọi `LuaFnSetSceneLoad_Monster`. Cùng kiểu ở `boundary_between_song_and_liao.lua` (`songliao_monster_%d.ini`) và `field_fastness.lua` (`yewai_monster_%d.ini`). `ecity_0602military.lua:426` nối bảng chuỗi `x600032_g_CopyNpc` thành `*_*.ini`.

Trên script thật, `_points_at` trả 0 cho `zhulin_monster_10.ini`, `songliao_monster_10.ini`, `tongrenxiang_1_monster_10.ini`. Dòng bamboo trong bảng là `unresolved`, `resolved` rỗng, `argument` chỉ là `monsterINI`. Cả ba họ tên nằm trong danh sách "không script nào trỏ" của báo cáo C. Test `test_resolves_literal_constant_format_and_skips_comment` chỉ đưa `format(...)` thẳng vào đối số, không có biến cục bộ.

Cây giả một tệp, cùng lệnh:

```text
monster unresolved  monsterINI
map unresolved  [[plain.nav]]
bamboo 458 unresolved  monsterINI
zhulin_monster_10.ini points 0
```

### X-BC-02 [SỬA] `--check` không kiểm tệp lạ ở đích

- Chỗ: `TOOLS/server/export_scene.py:1510`
- Bằng chứng: cùng lệnh, nửa sau.

Mục 6: `--check` kiểm hết và không ghi. Cây `demo` hợp lệ, `build/p1-b/xet-c-fix/out/demo/keep.txt` là tệp lạ. `export_scenes(..., check_only=True)` trả `ok True`, `errors []`. Cùng đầu vào không `--check` trả `ok False` và `keep.txt:1: tệp lạ, không xoá`. Tệp lạ không bị xoá. `test_check_writes_nothing` chỉ xem thư mục đích chưa tồn tại. `test_reject_foreign_destination` không gọi `--check`.

```text
check ok True errors []
write ok False errors ['build\\p1-b\\xet-c-fix\\out\\demo\\keep.txt:1: tệp lạ, không xoá']
keep exists True
```

### X-BC-03 [SỬA] Chuỗi `[[...]]` không thành literal, test không có ca này

- Chỗ: `TOOLS/server/scene_refs.py:342`
- Bằng chứng: cùng lệnh, dòng `map unresolved  [[plain.nav]]`.

Đề nói `resolved` là tên tệp khi đối số là chuỗi viết thẳng. `LuaFnSetSceneLoad_Map(sceneId, [[plain.nav]])` ra `how=unresolved`, `resolved` rỗng. `test_block_comment_and_string_are_not_calls` chỉ có `"..."` và `--[[`. Trên 4.248 tệp thật không thấy ngoặc dài cạnh lời gọi (`python build/p1-b/xet_c.py` in `dòng có ngoặc dài cạnh lời gọi 0`), nên bảng hiện tại chưa mất dòng này. Ca giả vẫn sai và test vẫn xanh.

Đã quét hợp đồng TSV của cảnh, không thấy lệch byte. `python build/p1-b/xet_c6.py`: `checked 3321 types 0 cr 0`. `python build/p1-b/xet_c.py`: 3.322 tệp, lỗi tên cột, BOM, CRLF, lệch số ô: 0. Guid `luoyang_monster.ini` 207 dòng và `gongdishaolinmis_monster.ini` 20 dòng khớp tsv (`python build/p1-b/xet_c5.py`).

## Trả lời xét chéo

### X-AB-01 NHẬN

Dòng trong section mà không trống, không phải chú thích, và không có dấu `=` thì báo lỗi. Dòng trống và dòng `;` / `#` vẫn bỏ qua.

Đỏ, trước khi sửa:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py" -k without_equals
FAIL: test_ini_line_without_equals
AssertionError: [] is not true
Ran 1 test in 0.003s
FAILED (failures=1)
```

Exit 1.

Sau khi sửa, cùng ca in lỗi và không ghi bảng:

```text
python -W error build/p1-b/xab_show.py
PvpRuler ['Server/Config/SceneInfo.ini:11: dòng không có dấu bằng', 'Server/Config/SceneInfo.ini:11: dòng không có dấu bằng'] summary [] file False
hole ['legacy_rules.tsv:5: index khuyết, cần 1'] summary [] toml False
```

Hai dòng lỗi vì `scenes` và `scene_hosting` cùng đọc một ini. `scenes.tsv` không được tạo.

Mười lăm `Public/Config/RandShop/*.ini` không có dòng dạng này. `python -W error build/p1-b/xab_shop.py` in `other 0` và `no_eq 0` cho cả 15 tệp. Test dữ liệu thật, đã đặt `THIENLONG_LEGACY_ROOT`:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
Ran 24 tests in 3.033s
OK
```

### X-AB-02 NHẬN

Token kiểu rỗng ở đuôi không còn thành cột `text`. Ô có chữ phía sau số token đã khai được đếm `ô sau kiểu bị bỏ`. Ô rỗng được đếm `ô thừa rỗng bỏ`.

Đỏ, trước khi sửa:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py" -k blank_type
FAIL: test_keep_value_under_blank_type
AssertionError: Tuples differ: ('int', 'int', 'text') != ('int', 'int')
Ran 1 test in 0.002s
FAILED (failures=1)
```

Exit 1.

Xuất lại vào `build/p1-b/xab-out`, rồi chép hai tệp lệch vào cây:

```text
python -W error build/p1-b/xab_diff.py
legacy errors []
item_segment_values.tsv: bản ghi 468, cột 65, tên thật 1, cột ? 64, ô thừa rỗng bỏ 29888, ô sau kiểu bị bỏ 64
bảng lệch ['item_segment_values.tsv']
cột lệch ['item_segment_values.tsv']
```

`TOOLS/server/columns/server/item_segment_values.tsv` dừng ở chỉ số 64, kiểu `int`. `SERVER/tables/server/item_segment_values.tsv` còn 65 cột, toàn `int`. `scene_load_refs.tsv` vẫn `# tool: TOOLS/server/scene_refs.py`.

`TOOLS/server/table_names.tsv` dòng `ItemSegValue.txt` vẫn ghi `129 cột`. Tệp đó của L, vòng này không sửa.

Sáu toml luật trùng từng byte với `SERVER/config/rules`. Cùng lệnh `xab_diff.py` in `lệch tiến trình: 0` và `trùng` cho `global.toml`, `combat.toml`, `character.toml`, `new_character.toml`, `monster.toml`, `instances.toml`.

### X-AB-03 NHẬN

`_ordered_indexes` sort rồi đòi mỗi chỉ số kế tiếp đúng bằng chỉ số trước cộng 1. Khoảng trống và chỉ số trùng bị từ chối, không ghi toml.

Đỏ, khi hàm còn nối mọi chỉ số:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_rules.py" -k index_gap
FAIL: test_index_gap_is_rejected
AssertionError: False is not true
Ran 1 test in 0.002s
FAILED (failures=1)
```

Exit 1.

Sau khi sửa, dòng `hole` của cùng lệnh `xab_show.py` ở trên là `legacy_rules.tsv:5: index khuyết, cần 1`, `toml False`. `id0` index 0 và `id2` index 2 không thành `id = [3, 9]`.

`HourPoint01`, `HourPoint02`, `HourPoint03` trong `legacy_rules.tsv` dòng 210–212 mang index 1, 2, 3. Ép dãy bắt đầu ở 0 thì lệnh xuất thật trả `legacy_rules.tsv:210: index khuyết, cần 0`. Ba chỉ số đó liền nhau nên được giữ. Sáu toml không đổi byte, như mục X-AB-02.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_rules.py"
Ran 6 tests in 0.015s
OK
```

Lệnh này chạy khi đã đặt `THIENLONG_LEGACY_ROOT`. Chưa đặt biến thì `Ran 6 tests in 0.008s`, `OK (skipped=1)`.

```text
python -W error TOOLS/server/lint_py.py TOOLS/server/import_legacy.py TOOLS/server/import_rules.py TOOLS/server/test_import_legacy.py TOOLS/server/test_import_rules.py
```

Thoát 0, không in dòng.
