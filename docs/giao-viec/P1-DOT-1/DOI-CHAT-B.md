# Đối chất vai B

## Trả lời review

Không có finding nào nhắm vào B. Không sửa mã.

Đã rà `docs/giao-viec/P1-DOT-1/REVIEW.md`: mọi tiêu đề finding là dòng `### R-<vai>-<số>`. Bảy mã tìm được:

- `R-A-01` [CHẶN], chỗ `TOOLS/server/export_tables.py`
- `R-A-02` [GHI], chỗ `TOOLS/server/export_tables.py`
- `R-C-01` [CHẶN], chỗ `TOOLS/server/export_scene.py`
- `R-C-02` [SỬA], chỗ `TOOLS/server/export_scene.py`
- `R-C-03` [SỬA], chỗ `TOOLS/server/export_scene.py`
- `R-L-01` [SỬA], chỗ `TOOLS/server/tsv_file.py`
- `R-L-02` [GHI], chỗ `TOOLS/server/table_names.tsv`

Không có dòng `R-B-`. Mục "Đã thử phá mà không phá được" của B không nêu finding: 58 bảng chữ lệch 0, hai tệp `.dat` khớp từng dòng, các đầu vào hỏng thoát lỗi và không ghi tệp.

`R-L-02` nhắc B đã xuất `script_index.tsv` và `monster_ai_scripts.tsv`, nhưng mã finding là `R-L`, chỗ sửa là bảng tên của L, và đòi hỏi là thêm dòng hợp đồng chứ không đổi byte hai TSV. Không trả lời thay L.

## Xét chéo C

Đã đọc `TOOLS/server/export_scene.py`, `scene_read.py`, `scene_classify.py`, `test_export_scene.py`. Chạy công cụ và một bộ đếm riêng trên `Public/Scene`. Không sửa mã của C.

### Mất im lặng: không thấy

Trong các cảnh đã gắn, không thấy ô bị bỏ mà không báo. Lệnh `python -W error build/p1-b/xet_c_run.py` (gọi `export_scenes(..., check_only=True)`):

```text
ok False
errors 45
other 0
unattached 45
kinds ... monster 237, monster_by_level 1171, ...
records {'spawns': 17210, 'grow_points': 7885, 'grow_point_rules': 210, ...}
dest_exists False
jiaochang value_index 11 ('spawns.tsv', '0', '3', '11', '21', '36') và ('...', '11', '53', '47')
meiling point13 speech_1='48' unread='49'
```

45 lỗi đều là `không gắn được vào cảnh nào`. Không có lỗi phân tích khác. Hai giá trị `value11` khác nhau trong `jiaochang_monster.ini` đều còn trong bảng. Hai `paopao13_1` của `meiling_patrolpoint.ini` còn ở `speech_1` và `speech_unread`.

Đếm riêng dòng dữ liệu `*_growpoint*.txt` (bỏ hai dòng đầu): 131 tệp có dòng, 8095 dòng. `grow_points` 7885 + `grow_point_rules` 210 = 8095. Khớp.

So 3543 bảng đang nằm trong bộ nhớ sau `_build`: 0 tên cột lệch `[a-z][a-z0-9_]*`, 0 tên trùng, 0 ô chứa tab/CR/LF, 0 ô đầu `#`, 0 `source` tuyệt đối.

Nội dung không xuất của `.path`, `.stall`, `.ObjRegion` là theo đề bài (chỉ phân loại). 45 tệp không gắn được nêu tên, không im lặng.

### X-BC-01 [SỬA] Lỗi ô chứa tab không kèm tên cột

Mục 6: ô chứa tab thì báo `tệp:dòng:cột`. `scene_read.server_value` chỉ in tệp và dòng.

`python -W error` gọi `export_scenes` trên cây giả `build/p1-b/xet-c-fixture` (dòng `title=a<tab>b`):

```text
TAB ok False
TAB errors ['Public/Scene/demo_monster.ini:8: ô chứa tab']
TAB wrote False
```

Dòng 8 là khoá `title`. Chuỗi lỗi không có `title`. `test_reject_tab_inside_value` chỉ đòi chữ `tab` nằm trong lỗi, nên vẫn xanh nếu thiếu tên cột.

### X-BC-02 [SỬA] Thoát lỗi vẫn ghi các cảnh đã gắn

Mục 7: kiểm hết rồi mới ghi; một lỗi thì không để tệp dở. Cùng cây giả, thêm `chuangjian.nav` không có `.scn`:

```text
ORPHAN ok False
ORPHAN errors ['Public/Scene/chuangjian.nav:1: không gắn được vào cảnh nào']
ORPHAN demo exists True
ORPHAN chuangjian exists False
```

`ok` là false nhưng `demo/spawns.tsv` đã được ghi. Trên dữ liệu thật cũng vậy: 45 lỗi không gắn, 0 lỗi `book.errors`, nhánh ghi trong `export_scenes` vẫn chạy (`export_scene.py` khoảng dòng 1176). `test_orphan_scene_and_dropped_test_file` đòi `demo/spawns.tsv` tồn tại khi `ok` là false, nên không bắt vi phạm này.

### X-BC-03 [SỬA] Tệp cột nói level bị monster_level ghi đè; mã và TSV thì không

`TOOLS/server/columns/scenes/spawns.tsv` dòng 24: `cấp, khi vắng thì 0; tệp monster_level ghi đè`.

`export_scene.py` hàm `_level_table` ghi chú ngược lại: tệp level không được `LoadMonster` đọc, không ghi đè `spawns`. Đọc TSV đã xuất:

```text
python -W error -c "import sys; sys.path.insert(0,'TOOLS/server'); import tsv_file
sp=tsv_file.read_table('SERVER/scenes/caoyuan/spawns.tsv')
print(sp.source, sp.rows[67][sp.columns.index('level')])"
```

```text
Public/Scene/caoyuan_monster.ini -1
```

`SERVER/scenes/caoyuan/spawn_levels.tsv` dòng chỉ số 67 là `67` và `63`. Level trong `spawns.tsv` vẫn là `-1` của tệp quái. `test_level_override_and_patrol_unread` kiểm ô `-1` và bảng `spawn_levels`, không đọc câu note. Grep `ghi đè` trong `test_export_scene.py` không có.

Thêm chỗ test không in vị trí: 12 khoá `PATROLPOINTNUM` trong `luoyang_patrolpoint.ini` có dạng `12 ;chú thích` nên giá trị còn dấu cách (`'12 '`). Gọi `_patrol` một lần trên tệp đó cho `padded_count` 12. Cả lần xuất thì `padded_count` là 24 vì tệp gắn cả `luoyang` và `luoyangsnow`. `int_places` có 265 dòng; test khoá cứng 200 `teleport_to_respawn` cộng 65 `script_id`. Không dòng nào là `PATROLPOINTNUM`. Test không có ca `PATROLPOINTNUM` kèm dấu cách.

## Trả lời xét chéo

### X-AB-01 NHẬN

Dòng `;` và dòng không phải bản ghi trong `Script.dat` bị bỏ mà không vào bộ đếm. Đã thêm `dòng script bỏ`. Trên đĩa: 476 dòng `;`, 1 dòng `帮会同盟`, 172 dòng trống, cộng 649.

`table_names.tsv` đã có `public_data/Script.dat` và `AIScript.dat`. `_kind` không nhận `.dat` nên test thật đỏ `không có bộ đọc`. Đã đọc hai tệp đó qua `CFileDataMgr`, không ghi đúp khi `--` gồm cả bảng tên và cờ chỉ mục.

Đỏ, trước khi sửa, bốn test:

```text
python -W error -c "import sys,unittest; sys.path.insert(0,'TOOLS/server'); import test_import_legacy; ..."
FAIL test_script_index: 'dòng script bỏ 2' không có trong tổng kết
FAIL test_real_tree: ['AIScript.dat:1: không có bộ đọc', 'Script.dat:1: không có bộ đọc']
Ran 4 tests in 1.017s
FAILED (failures=4)
```

Xanh, sau khi sửa:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
Ran 21 tests in 3.055s
OK
```

Exit code 0. Tổng kết dữ liệu thật: `script_index.tsv: ... dòng script bỏ 649`. `monster_ai_scripts.tsv` có `dòng script bỏ 1` (một dòng trống sau magic).

### X-AB-02 NHẬN

`_numeric_text` chỉ khớp `^[+-]?\d+$` nên sót số có dấu chấm. Đã đổi mẫu thành số nguyên hoặc số thập phân. Không đổi kiểu cột: `column_29` vẫn `text`.

Đỏ, cùng lần bốn test ở trên:

```text
FAIL test_decimal_text_column_is_listed: 'mixed' not found in '... cột text toàn số: whole'
```

Xanh: cùng lệnh `discover`, 21 test, `OK`. `effects.tsv` liệt kê 32 cột text toàn số, có `column_29`, `column_32`, `column_35`, `column_65`, `column_68`.

### X-AB-03 NHẬN

`INT\t\tSTRING` bị từ chối dù bộ đọc gốc bỏ token rỗng và chỉ lấy hai ô đầu. Đuôi kiểu trống (như `ItemSegValue.txt`) vẫn giữ ô có chữ, vì đó không phải lỗ xen giữa.

Đỏ:

```text
FAIL test_middle_empty_type_reads_first_fields
['Server/Config/sample.txt:1: ô kiểu rỗng xen giữa']
```

Xanh: cùng `discover`, 21 test, `OK`. Ca giả ra hai cột `int`/`text`, một dòng `1` và `2`, tổng kết `ô sau kiểu bị bỏ 1`. `item_segment_values.tsv` vẫn 129 cột.
