# Đối chất vai B

## Trả lời review

### R-B-01 NHẬN

`_clientres` là định danh ASCII. M1 bỏ đoạn rỗng trước `_` rồi ra `clientres`, trùng cột `clientres` đã có. Luật lặp đánh số mọi lần, từ 1, không đổ về `column_<n>`.

`_scene_layout` không còn gắn sẵn `column_9`. Nhãn đi qua `english_name`, rồi `number_repeated`. Hai cột thành `clientres_1` và `clientres_2`. `note` của `_clientres` là `luật: M1`, không còn `?`. Cột tổng hợp `scene_id` và `within_declared_count` giữ nguyên.

Đã sửa cùng tên ở `TOOLS/server/columns/server/scenes.tsv` và chỉ dòng tên cột của `SERVER/tables/server/scenes.tsv`. Ô dữ liệu không đổi. Dòng đầu vẫn là `0	0	洛阳	luoyang.scn	0	0	0	8122400	9030100	242	1`.

`random_shop_goods.tsv` dòng `odds` vẫn là `odds_lower` và `note` còn `?`. Tên đó không phải `column_<n>`, ngoài đòi hỏi của finding này.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py" -k test_scene_pvp_column_uses_rules
```

```text
Ran 1 test in 0.000s
OK
```

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
```

Chưa đặt `THIENLONG_LEGACY_ROOT`: `Ran 26 tests in 0.042s`, `OK (skipped=1)`. Ca bỏ qua là `test_real_tree`.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py" -k test_real_tree
```

Đã đặt `THIENLONG_LEGACY_ROOT` trỏ tới cây 0859602. Xuất vào `build/p1-b/unit/real_tree` rồi xoá. `Ran 1 test in 3.543s`, `OK`.

```text
python -W error TOOLS/server/lint_py.py TOOLS/server/import_legacy.py TOOLS/server/test_import_legacy.py
```

Thoát 0, không in dòng.

```text
python -B -c "import sys; sys.path.insert(0, r'docs/giao-viec/P1-DOT-3/kiem'); import thieu; thieu.scan_machine_names()"
```

```text
M1/M2 còn column_n: 0
```

```text
python -W error TOOLS/server/lint_names.py --stats
```

Thoát 0:

```text
shared: cột 17247, chưa tên 14661, nhãn rỗng 14531, chỉ chữ Hán 129, ASCII và chữ Hán 1, chỉ ASCII 0
server: cột 2172, chưa tên 284, nhãn rỗng 6, chỉ chữ Hán 277, ASCII và chữ Hán 0, chỉ ASCII 1
scenes: cột 95, chưa tên 5, nhãn rỗng 0, chỉ chữ Hán 4, ASCII và chữ Hán 0, chỉ ASCII 1
```

Nhóm `server`: chưa tên giảm 1 (285 xuống 284), chỉ ASCII giảm 1 (2 xuống 1). Số còn lại là `odds` nói trên.

## Xét chéo C

Chỉ đọc. Không sửa mã của C. Lệnh chung: `python -B -W error build\p1-b-xet-c\probe.py`, exe `build\gcc-debug\thienlong_lint.exe`. Cây giả nằm trong `build\p1-b-xet-c\`.

### X-BC-01 [CHẶN] Dòng dữ liệu có ô đầu bắt đầu bằng `#` biến mất, lint vẫn thoát 0

- Chỗ: `SRC/content/lint.cpp:780` gọi `parse_tsv`. `SRC/table/tsv.cpp:38` bỏ mọi dòng có ký tự đầu là `#`.
- Bằng chứng: ca `hash`. `tables/child.tsv` có hai dòng dữ liệu `1` và `#3364`. Cha chỉ có `1`. `known_missing` là 0. Nếu `#3364` còn là bản ghi thì thiếu một giá trị, phải thoát 1.

```text
EXIT 0
tệp: 2
bản ghi: 2
ô: 2
dòng tham chiếu: 1
lỗi: 0
```

Hai tệp, mỗi tệp một bản ghi. Dòng `#3364` không vào số bản ghi và không vào K5. `tests/content_tests.cpp` ca `k1_file_shape` chỉ có dòng thừa ô, không có ô đầu bắt đầu bằng `#`.
- Đòi hỏi: dòng ấy là lỗi, đúng tệp và đúng số dòng. Nó vẫn bị tính là bản ghi, hoặc bị từ chối trước khi so `known_missing`. Ca test này phải đỏ nếu dòng biến mất.

### X-BC-02 [CHẶN] Kiểu cột con chỉ lấy từ tệp khớp đầu tiên

- Chỗ: `SRC/content/lint.cpp:676` `set_type` giữ kiểu đầu rồi bỏ qua. `lint.cpp:716` gọi nó cho mọi tệp của một mẫu.
- Bằng chứng: ca `types`. `scenes/a/spawns.tsv` cột `type` là `int`, ô `1`. `scenes/b/spawns.tsv` cùng cột là `float`, ô `1`. Cha `monster_id` là `int`. Mục 5.2: hai cột phải cùng kiểu, và không phải `float`.

```text
EXIT 0
tệp: 3
bản ghi: 3
ô: 3
dòng tham chiếu: 1
lỗi: 0
```

`tests/content_tests.cpp` `parent_column_type` mỗi mẫu một tệp. Không có hai tệp cùng mẫu mà khác kiểu.
- Đòi hỏi: mọi tệp khớp mẫu con đều được so kiểu với đúng cột cha. Ca `a` int và `b` float phải có lỗi kiểu, dù nguyên văn ô là `1`.

### X-BC-03 [SỬA] Biểu thức không đọc được thành mẫu `*`, không phải `unresolved`

- Chỗ: `TOOLS/server/scene_refs.py:581`. Đầu tệp nói không ra được mẫu thì `how` là `unresolved`. Nhánh này trả `("*",)` cho mọi mảnh không phải định danh.
- Bằng chứng: ca `star`. Hai lời gọi, cả hai ra `format`, thoát 0.

```text
guess.lua	2	monster	Mystery() .. ".ini"	*.ini	format	3
guess.lua	3	monster	"shuilao_monster_" .. Mystery() .. ".ini"	shuilao_monster_*.ini	format	2
shuilao_monster_10.ini			map_unknown
shuilao_monster_99.ini			map_unknown
unrelated_monster_10.ini			unpointed
```

`*.ini` đếm 3 tệp, gồm `unrelated_monster_10.ini`. `shuilao_monster_99.ini` thành `map_unknown` dù script không nêu số 99. `test_scene_refs.py` `test_format_local_long_string_and_name_table` chỉ đòi mẫu có tiền tố dài khớp `_10` và `_20`, không cấm `_99` và không có `Mystery() .. ".ini"`.

Trên cây thật, 45 `resolved` có `*`. `shuilao_monster_*.ini` khớp 20 tệp cấp, `bianguan_*_monster_*.ini` khớp 80. Cả hai nhóm đều là tên `_monster_<số>.ini` (`build\p1-b-xet-c\probe3.py`). Chưa thấy tên thừa hậu tố trên đĩa. Lỗ này vẫn ghi nhầm khi có tệp cùng dạng.
- Đòi hỏi: mảnh không đọc được không được biến cả đối số thành `*.ini`. `files_on_disk` của dòng đó không đếm tệp mà lời gọi không nêu. `shuilao_monster_99.ini` không được `map_unknown` chỉ vì `Mystery()`.

### X-BC-04 [SỬA] `files_on_disk` không phân biệt hoa thường, phán quyết cấp thì có

- Chỗ: `TOOLS/server/scene_refs.py:790` so `casefold`. `scene_refs.py:909` so `==`. D-06 bắt so tên không phân biệt hoa thường.
- Bằng chứng: ca `case`. Script nêu `plain_monster_10.ini`. Đĩa có `Plain_monster_10.ini`. `[System]` của `plain.scn` trỏ đúng tên trên đĩa. Thoát 0.

```text
case.lua	4	monster	"plain_monster_10.ini"	plain_monster_10.ini	literal	1
Plain_monster_10.ini	plain		unpointed
```

`files_on_disk` là 1, `verdict` là `unpointed`. `test_disk_count_and_level_verdict` tạo `Literal_Monster.ini`. Tên đó là quái thường, không vào bảng cấp, nên ca không thấy `unpointed`. Cây thật: 250 lời gọi, 0 literal/constant lệch hoa thường với tên trên đĩa. Bảng 1.344 dòng hiện không dính.
- Đòi hỏi: cùng một tên, hai bảng không mâu thuẫn chỉ vì hoa thường. `files_on_disk` là 1 thì dòng cấp không được `unpointed` vì khác chữ hoa.

### X-BC-05 [SỬA] `*.TSV` không được đọc, thoát 0

- Chỗ: `SRC/linttool/main.cpp:128` so `extension()` với `".tsv"`. `main.cpp:161` bỏ giá trị trả về của lần duyệt cây.
- Bằng chứng: ca `ext`. `tables/a.TSV` chứa id `7`. Cạnh đó `scenes/keep.tsv` hợp lệ. Refs không có dòng dữ liệu.

```text
EXIT 0
tệp: 1
bản ghi: 1
ô: 1
dòng tham chiếu: 0
lỗi: 0
```

Một tệp, là `keep.tsv`. `a.TSV` không có trong số đếm và không có lỗi. `content_tests` không gọi `main`, không đụng đuôi tệp.
- Đòi hỏi: tệp `.TSV` dưới `tables` hoặc `scenes` được đọc, hoặc là lỗi có tên. Không được biến mất khi `lỗi` là 0.

### X-BC-06 [SỬA] Số vượt int32 luôn báo dòng 1

- Chỗ: `TOOLS/server/export_scene.py:1475`.
- Bằng chứng: ca `overflow`. Bảng hai dòng, ô hỏng là dòng dữ liệu thứ hai, `9999999999`.

```text
['demo/spawns.tsv:1: số vượt int32']
```

`test_export_scene.py` không có ô int vượt int32. Hàm vẫn fail, không ghi bảng. Sai ở số dòng.
- Đòi hỏi: dòng trong thông báo là dòng nguồn của ô đó, không phải 1. Test một bảng nhiều dòng, ô hỏng không nằm dòng đầu.

## Trả lời xét chéo

### X-AB-01 NHẬN

`Ini.cpp` `ReadDataName` dừng ở `=`, `;`, `\r`. Dòng `#extra=9` là khoá `#extra`, giá trị `9`. `_ini_noise` và `_ini_entries` trước đây bỏ mọi dòng strip bắt đầu bằng `#`.

Đã sửa: dòng `#` có dấu `=` là khoá. Trong `SceneInfo` thì `#extra` là khoá lạ, có số dòng, không ghi bảng. `import_rules` báo `chưa có dòng` đúng dòng nguồn. Dòng `#` không có dấu `=` vẫn bỏ: `CombatLimits.ini` có 49 dòng như vậy, 0 dòng có `=`, và chính tệp nói chú thích bắt đầu bằng `#` hoặc `;`. Bỏ dòng đó không giấu một giá trị.

Trước khi sửa, bốn ca mới đỏ:

```text
python -B -W error -m unittest TOOLS.server.test_import_legacy.ExportLegacyTest.test_hash_ini_key_is_not_swallowed TOOLS.server.test_import_legacy.ExportLegacyTest.test_shop_merge_and_total TOOLS.server.test_import_legacy.ExportLegacyTest.test_drop_box_note_names_code_index
```

```text
AssertionError: '9' not found in ['0', '0', 'a', 'a.scn', '0', '0', '', '', '', '', '1']
AssertionError: 'odds' != 'odds_1'
AssertionError: 'cột 2' not found in 'luật: M1'
FAILED (failures=3)
```

```text
python -B -W error -m unittest TOOLS.server.test_import_rules.ExportRulesTest.test_hash_equals_is_a_key
```

```text
AssertionError: False is not true
FAILED (failures=1)
```

Sau khi sửa:

```text
python -B -W error -m unittest TOOLS.server.test_import_legacy.ExportLegacyTest.test_hash_ini_key_is_not_swallowed TOOLS.server.test_import_rules.ExportRulesTest.test_hash_equals_is_a_key
```

```text
Ran 2 tests in 0.002s
OK
```

Ca cảnh đòi lỗi `khoá lạ` kèm `#extra` và `SceneInfo.ini:12:`, và không ghi `scenes.tsv`. Ca luật đòi `chưa có dòng` kèm `#extra` và `Demo.ini:3:`.

`import_rules.py "<tlbb>" SERVER/config/rules --check` vẫn thoát 0: luật 142, tiến trình 26, bỏ 9, chưa rõ 401, lệch tiến trình 0, đã ghi 0.

### X-AB-02 NHẬN

`Odds` rồi `odds` cùng ra `odds`. Luật tên lặp đánh số mọi lần, từ 1. `_shop_columns` đưa hai nhãn qua `number_repeated`. Tên là `odds_1` và `odds_2`. Note cả hai là `mã 2008 không có hàm nạp`, không còn `?`. Ô dữ liệu không đổi: dòng đầu vẫn `workshop_100	0	30300006	1	1	1		1000		1`.

`test_shop_merge_and_total` đọc đúng hai tên, đúng ô `Odds=2` và `odds=4`, và note không có `?`. Ca này nằm trong lần đỏ ở X-AB-01 (`'odds' != 'odds_1'`).

```text
python -B -W error -m unittest TOOLS.server.test_import_legacy.ExportLegacyTest.test_shop_merge_and_total
```

```text
Ran 1 test in 0.003s
OK
```

`import_legacy.py` trên cây 0859602, đích `SERVER/tables/server`, dòng tổng kết:

```text
random_shop_goods.tsv: bản ghi 458, cột 10, tên thật 10, cột ? 0, cắt chú thích ini 2167, dòng ngoài số khai báo 1, cột text toàn số: id, count_per_unit, value
```

`lint_names.py --stats`, nhóm server: chưa tên 283 (trước 284), chỉ ASCII 0 (trước 1).

### X-AB-03 NHẬN

`InitDropBoxTable`: `TBDropBoxBegin = 2`, `j < 100`. Slot 0 là cột 2, không phải `item_1_id`. Cột 202 là `item_100_id`, vòng không tới. Không đổi tên. Note của cột 2, 4, 200, 202 nối câu `mã InitDropBoxTable bắt đầu ở cột 2, 100 cặp; item_100_id nằm ngoài vòng`.

Tên trên cây thật giữ nguyên:

```text
2 broadcast_type_id
4 item_1_id
200 item_99_id
202 item_100_id
```

`test_drop_box_note_names_code_index` dùng bảng giả 203 cột, cột 2 là `NotItem`, không phải `Item1ID`. Tên ra `not_item`. Note bốn cột đều có `cột 2` và `item_100_id`. Ca này đỏ trước khi sửa (`'cột 2' not found in 'luật: M1'`).

```text
python -B -W error -m unittest TOOLS.server.test_import_legacy.ExportLegacyTest.test_drop_box_note_names_code_index
```

```text
Ran 1 test in 0.038s
OK
```

Cả hai tệp test, đã đặt `THIENLONG_LEGACY_ROOT`:

```text
python -B -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
python -B -W error -m unittest discover -s TOOLS/server -p "test_import_rules.py"
```

```text
Ran 28 tests in 3.593s
OK
Ran 8 tests in 0.017s
OK
```

```text
python -B -W error TOOLS/server/lint_py.py TOOLS/server/import_legacy.py TOOLS/server/import_rules.py TOOLS/server/test_import_legacy.py TOOLS/server/test_import_rules.py
```

Thoát 0, không in dòng. `test_real_tree` cũng đọc `odds_1`, `odds_2` và note bốn cột hòm đồ trên cây thật.
