# Đối chất vai C

## Trả lời review

### R-C-01 NHẬN

Lời gọi trong `--[[ ... ]]` và trong chuỗi `print("...")` đang thành dòng thật. `hidden.nav` ra `how=literal`.

Đỏ, trước khi sửa:

```text
python -W error -m unittest TOOLS.server.test_scene_refs.SceneRefsTest.test_block_comment_and_string_are_not_calls
```

Exit code 1.

```text
AssertionError: 'hidden.nav' unexpectedly found in {'', 'shown.nav', 'hidden.nav'}
Ran 1 test in 0.002s
FAILED (failures=1)
```

Đã sửa `scene_refs.py`. Ngoặc dài `--[[`, `--[=[`, `[[` được nhận theo mức dấu `=`. Chú thích khối và chú thích `--` vẫn đếm, không thành dòng. Ruột chuỗi ngắn và chuỗi dài không thành dòng và không đếm. Đối số của lời gọi thật vẫn lấy từ dòng gốc, nên `"literal_monster.ini"` không bị xoá.

Fixture của R, `build/p1-r/pha/tlbb/Public/Data/Script/block.lua`:

```text
python -W error -c "import sys; sys.path.insert(0,'TOOLS/server'); import scene_refs; from pathlib import Path; root=Path('build/p1-r/pha/tlbb/Public/Data/Script'); calls, commented = scene_refs.collect_calls(root); print('chú thích đếm', commented); print('active', len([c for c in calls if not c.commented])); [print(c.line, c.kind, c.how, c.commented, c.resolved) for c in calls]"
```

Exit code 0.

```text
chú thích đếm 1
active 1
2 map unresolved True
5 monster constant False shown.nav
```

Dòng 2 là chú thích khối, không còn `how=literal`. Dòng 6 trong `print` không còn. Dòng 5 vẫn là hằng `shown.nav`.

`scene_load_refs.tsv` không đổi: 250 dòng mới bằng 250 dòng đang ghi, `commented` vẫn 5.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_scene_refs.py"
```

Đã đặt `THIENLONG_LEGACY_ROOT`. Exit code 0.

```text
Ran 6 tests in 11.242s
OK
```

`python TOOLS/server/lint_py.py TOOLS/server/scene_refs.py TOOLS/server/test_scene_refs.py` exit code 0, không in dòng.

## Xét chéo A

Đã đọc `align_columns.py`, `export_tables.py` và test của A. Đã chạy công cụ trên cây giả trong `build/p1c-xem-a/` và trên `ShopTable`. Không sửa mã A. 635 bảng `fate=table` có số dòng và số cột TSV bằng DBC. Không có BOM, CR, tên cột sai regex, tên trùng, hay ô đầu bắt đầu bằng `#`.

### X-CA-01 Dữ liệu tên cột mất im lặng khi hai id atoi ra cùng một số

- Chỗ: `TOOLS/server/export_tables.py:639` `_keyed_legacy`, gọi từ `_pair_rows` khi bố cục khác.
- `1` và `01` đều thành số 1. Hàm trả `None`. `_aligned_links` coi như không có dòng, `align` gắn mọi cột là `mới ở 2026`. Không có dòng lỗi, không có notice. `test_export_tables.py` không có ca id `01`.

Cây giả: DBC ba cột int, id 1..4, cột cuối 100, 200, 300, 400. Bảng chữ hai cột `ID`, `Value`, dòng `1/01/2/3/4`. Cột cuối DBC trùng `Value` nếu còn ghép được.

```text
python build/p1c_xem_a3.py
```

Exit code 0. Phần padded:

```text
=== padded id, different layout ===
exit 0
cột có tên: 0
columns ('column_0', 'column_1', 'column_2')
('0', '', 'column_0', 'int', 'mới ở 2026')
('1', '', 'column_1', 'int', 'mới ở 2026')
('2', '', 'column_2', 'int', 'mới ở 2026')
```

`build/p1c-xem-a/padded/column_alignment.tsv` một dòng dữ liệu: `Pet.txt	3	2	0	0	0	3	2	0:ID;1:Value`. stdout không có chữ `id` hay `01`.

76 bảng trong `column_alignment.tsv` hiện không có cặp id kiểu này (`python build/p1c_xem_a4.py` in `collisions 0`). Lỗi nằm ở công cụ, chưa làm mất tên của 76 bảng đó.

### X-CA-02 Hợp đồng mục 6: thiếu đối số không phải thoát 1, dòng lỗi không theo tệp:dòng

- Chỗ: `TOOLS/server/export_tables.py:1211` `_parser`.
- Mục 6 đề đợt 1: thoát 0 khi sạch, 1 khi có lỗi; mỗi lỗi một dòng `tệp:dòng: nội dung`; `--help` tiếng Việt. `test_export_tables.py` không gọi lệnh không tham số.

```text
python -W error TOOLS/server/export_tables.py
```

Exit code 2. stderr:

```text
export_tables.py: error: the following arguments are required: raw_root, legacy_root, tables_root
```

`--help` exit 0 nhưng còn tiếng Anh: `usage:`, `positional arguments:`, `options:`, `show this help message and exit`.

### X-CA-03 Test không bắt cột gần hằng lấy tên cột nhiều giá trị khi chỉ khớp 7%

- Chỗ: `TOOLS/server/align_columns.py:338` `_varied_low_match` và `TOOLS/server/columns/shared/shops.tsv:276`.
- Hàm chỉ từ chối khi cả hai bên có từ 3 giá trị. Cột 2026 có 2 giá trị vẫn nhận tên cột gốc có 10 giá trị. `test_constant_between_anchors_is_interpolated` chỉ dùng hai cột hằng giống nhau. `test_varied_column_between_anchors_stays_new` chỉ dùng 4 giá trị mỗi bên.

```text
python build/p1c_xem_a5.py
```

Exit code 0. Dòng liên quan:

```text
270 left 2 right 10 legacy 283 PID(商品编号44)
```

`shops.tsv` dòng chỉ số 270:

```text
270	PID(商品编号44)	column_270	int	nội suy: cột gốc 283, khớp 7.0% (12/172 id); ? chưa có tên tiếng Anh
```

Cùng kiểu: id bảng chữ `abc` bị `_atoi` thành 0, note vẫn ghi khớp 100% (4/4). `test_export_tables.py` không có chuỗi `abc`.

```text
=== junk id atoi 0, same layout ===
exit 0
Pet.txt:1: đối chiếu 1 id không phải số nguyên thuần
('0', 'ID', 'id', 'int', 'khớp 100.0% (4/4 id)')
```

Ô legacy là `abc`, không phải `0`.

## Trả lời xét chéo

### X-BC-01 NHẬN

`local monsterINI = format(hằng, ...)` rồi gọi bằng `monsterINI` ra `unresolved`. Bảng chuỗi `tên[chỉ số] .. "_" .. ...` mất tên từng phần, mẫu còn `*_*.ini`, `_points_at` ra 0.

Đỏ, trước khi sửa:

```text
python -W error -m unittest TOOLS.server.test_scene_refs.SceneRefsTest.test_format_local_long_string_and_name_table
```

Exit code 1.

```text
AssertionError: ('map', 'literal', 'plain.nav') not found in {('monster', 'unresolved', ''), ('monster', 'format', '*_*.ini'), ('map', 'unresolved', '')}
Ran 1 test in 0.002s
FAILED (failures=1)
```

Đã sửa `scene_refs.py`. Biến gán một lần từ `format`/`string.format` của một hằng chuỗi giữ mẫu đó, `how=format`. Bảng chỉ toàn chuỗi literal, khi lấy `tên[biểu thức]`, dùng mọi phần tử. Nối `..` ghép các vế, nhiều mẫu cách nhau bằng `|`. Hai lần gán khác giá trị thì bỏ tên đó. Quá 64 vế thì `unresolved`.

Xanh:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_scene_refs.py"
```

Đã đặt `THIENLONG_LEGACY_ROOT`. Exit code 0.

```text
Ran 7 tests in 22.328s
OK
```

Đúng lệnh của B, `python build/p1-b/xet_c7.py`, exit code 0. Phần lời gọi:

```text
monster format zhulin_monster_%d.ini monsterINI cmt False
map literal plain.nav [[plain.nav]] cmt False
zhulin_monster_10.ini points 1
songliao_monster_10.ini points 1
tongrenxiang_1_monster_10.ini points 1
bamboo 458 format zhulin_monster_%d.ini monsterINI
```

Ghi lại `SERVER/tables/server/scene_load_refs.tsv`. Thư mục vẫn 70 tệp.

```text
python -W error TOOLS/server/scene_refs.py "C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb" SERVER/tables/server
```

Exit code 0.

```text
lời gọi: 250
chú thích bỏ qua: 5
how:
  constant 48
  format 50
  literal 140
  unresolved 12
```

Bảy dòng đổi. `bamboo_forest.lua:458` là `zhulin_monster_%d.ini`. `boundary_between_song_and_liao.lua:459` là `songliao_monster_%d.ini`. `field_fastness.lua:461` là `yewai_monster_%d.ini`. `ecity_0602military.lua:426` là chín mẫu `*_1_monster_*.ini` nối bằng `|`. Cùng cơ chế: `emidautumn_fight.lua:194` là `bianguan_*_monster_*.ini`; dòng 395 và 425 là bảng nav và bảng area. 12 dòng `unresolved` còn lại là truy cập trường (`MenpaiInfo`, `FuBen_Data`, `fubenData`, `FubenTbl`).

Đối chiếu 1.344 tệp sau khi sửa, cùng hàm `compare_level_files`: trỏ 1123, không trỏ 221, có trỏ nhưng không suy được Map 180, lệch 80. Ba họ `zhulin_monster_`, `songliao_monster_`, `yewai_monster_` hết trong danh sách không trỏ, lệch 0. 180 tệp `*_1_monster_*` của military được trỏ; Map của script đó là bảng chín nav, `how=format`, nên không suy một cảnh. Lệch thêm 60 tệp `bianguan_2/3/4_monster_*.ini`: Map trong script là hằng `bianguan_1.nav`, thư mục theo tên là `bianguan_2`, `bianguan_3`, `bianguan_4`. 20 tệp `murenxiang_monster_*.ini` lệch `xingxiu` như báo cáo cũ. Không chuyển tệp. Số ở mục 3 của `BAO-CAO-C.md` (format 44, unresolved 18, không trỏ 541, lệch 20) là số trước vòng này.

### X-BC-02 NHẬN

`--check` trả về trước `_write_scenes`, nên `keep.txt` trong thư mục cảnh không thành lỗi.

Đỏ, trước khi sửa:

```text
python -W error -m unittest TOOLS.server.test_export_scene.ExportSceneTest.test_check_rejects_foreign_without_deleting
```

Exit code 1.

```text
AssertionError: True is not false
Ran 1 test in 0.007s
FAILED (failures=1)
```

Đã sửa `export_scene.py`. `--check` đọc thư mục đích và thư mục cột đã có, theo cùng quy tắc tệp của công cụ và `walk.nav`. Tệp lạ thì `ok` sai, dòng lỗi có `tệp lạ, không xoá`. Không tạo thư mục, không xoá, không ghi. Thư mục chưa có thì qua, như `test_check_writes_nothing`.

Xanh:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_scene.py"
```

Đã đặt `THIENLONG_LEGACY_ROOT`. Exit code 0.

```text
Ran 22 tests in 3.856s
OK
```

Test so byte cả thư mục đích và thư mục cột trước và sau `--check`. Cùng lệnh của B:

```text
check ok False errors ['build\\p1-b\\xet-c-fix\\out\\demo\\keep.txt:1: tệp lạ, không xoá']
write ok False errors ['build\\p1-b\\xet-c-fix\\out\\demo\\keep.txt:1: tệp lạ, không xoá']
keep exists True
```

### X-BC-03 NHẬN

`LuaFnSetSceneLoad_Map(sceneId, [[plain.nav]])` ra `how=unresolved`. Cùng test đỏ của X-BC-01: tập kết quả có `('map', 'unresolved', '')`, không có `('map', 'literal', 'plain.nav')`.

Đối số là chuỗi dài `[[...]]` hoặc `[=[...]=]` thì `how=literal`, `resolved` là ruột chuỗi. Ca `[[plain.nav]]` nằm trong test xanh của X-BC-01 và trong `xet_c7.py` (`map literal plain.nav`).

Ca `[=[plain.nav]=]`, một tệp trong `build/p1-c-refs/long-eq` (đã xoá sau khi chạy):

```text
map literal plain.nav False
```

`python TOOLS/server/lint_py.py TOOLS/server/scene_refs.py TOOLS/server/test_scene_refs.py TOOLS/server/export_scene.py TOOLS/server/test_export_scene.py` exit code 0, không in dòng.
