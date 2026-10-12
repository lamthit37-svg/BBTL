# Đối chất vai C

## Trả lời review

### R-C-01 NHẬN

`LoadMonster` đọc khoá `level` trong section `[monsterN]` của chính tệp quái. Không có chỗ nào trong mã 2008 đọc `*_monster_level.ini`. Gộp cấp của tệp đó vào `spawns.tsv` làm 13 ô caoyuan thành 63, 66, 60... thay vì `-1`.

Đã tách. `spawns.tsv` chỉ lấy khoá `level` của tệp quái. Cả tệp `*_monster_level.ini` ra `spawn_levels.tsv`, không ghi đè.

`caoyuan/spawns.tsv` nguồn chỉ còn `Public/Scene/caoyuan_monster.ini`. Dòng monster 67: cột `level` là `-1`. `caoyuan/spawn_levels.tsv` có 173 dòng, dòng chỉ số 67 là `67` và `63`. `petisland_2` có `spawns.tsv` 0 dòng (`monstercount=0`) và `spawn_levels.tsv` 188 dòng.

```text
python -W error -c "import sys; sys.path.insert(0,'TOOLS/server'); import tsv_file; from pathlib import Path; root=Path('SERVER/scenes'); s=tsv_file.read_table(root/'caoyuan'/'spawns.tsv'); print(s.source); print(s.rows[67][s.columns.index('level')]); L=tsv_file.read_table(root/'caoyuan'/'spawn_levels.tsv'); print(len(L.rows), L.rows[67])"
```

```text
Public/Scene/caoyuan_monster.ini
-1
173 ('67', '63')
```

Exit code 0.

Test giả: tệp quái `level=-1`, tệp level `level=63`. Ô `spawns` vẫn `-1`. `spawn_levels.tsv` là `0` và `63`.

### R-C-02 NHẬN

45 tệp không có `.scn` và không được `.scn` nào trỏ. Lệnh thoát 1. Mỗi tệp một dòng `Public/Scene/<tên>:1: không gắn được vào cảnh nào`. Không tạo 12 cảnh mồ côi. Thư mục đích còn 244 cảnh có `.scn`. `chuangjian`, `登陆`, `选人`, `选人11`, `_pingpan_40` không còn.

Cảnh có `.scn` vẫn được ghi trong lượt này, vì nếu không ghi thì `caoyuan/spawns.tsv` cũ (level đã bị ghi đè) không được sửa. Tệp mồ côi nằm trên nguồn chỉ đọc, không xoá được.

```text
python -W error TOOLS/server/export_scene.py "<THIENLONG_LEGACY_ROOT>" SERVER/scenes --check
```

Exit code 1. Đầu stdout:

```text
Public/Scene/_pingpan_40_monster.ini:1: không gắn được vào cảnh nào
Public/Scene/_pingpan_55_monster.ini:1: không gắn được vào cảnh nào
Public/Scene/_pingpan_70_monster.ini:1: không gắn được vào cảnh nào
Public/Scene/_pingpan_85_monster.ini:1: không gắn được vào cảnh nào
Public/Scene/chuangjian.nav:1: không gắn được vào cảnh nào
```

45 dòng như vậy, rồi các dòng ô int. Cuối stdout: `scn 244`, không còn dòng `cảnh không scn: 12`. Đếm thư mục `SERVER/scenes`: 244. Lint 244 `scene.toml`: 0 lỗi.

### R-C-03 NHẬN

Ô `teleport_to_respawn` giá trị `0 ` không đi qua bộ đếm. Đã đếm mọi ô kiểu int không phải dạng `-?\d+` không có số 0 thừa, và in `tệp:dòng:cột`.

`--check` in `int_not_canonical 265`. Trong đó 200 dòng kết thúc bằng `:teleport_to_respawn`, 65 dòng kết thúc bằng `:script_id`. Mẫu:

```text
Public/Scene/bashu_1_monster.ini:892:script_id
Public/Scene/bianguan_1_area.ini:5:script_id
Public/Scene/cangmang_patrolpoint.ini:37:teleport_to_respawn
```

`cangmang` lặp cùng dòng nguồn vì một khoá `isTeleportToRespawnPos` áp cho nhiều điểm. Mỗi ô một dòng, đủ 200.

### Lệnh test sau khi sửa

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_scene.py"
```

Đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT`. Exit code 0.

```text
Ran 19 tests in 4.294s
OK
```

Test giả bắt ca level hai bên khác nhau, ca tệp không gắn cảnh (thoát lỗi, không tạo thư mục), và ca ô `040001` cùng `0 ` có mặt trong `int_places`.

## Xét chéo A

Chạy `export_tables.py` trên DBC và bảng chữ giả trong `build/p1-c/probe-a/`. Không ghi vào `SERVER/tables`. `test_export_tables.py` không có chuỗi `1e308`, `1.0` ở id, hay ô id rỗng.

### X-CA-01 Dòng id rỗng của bản đối chiếu bị bỏ, không đếm

`export_tables.py` khoảng dòng 296: `if cells[0] == "": continue`. Không cộng vào `notices`. Dòng chú thích `#` và dòng thiếu ô thì có thông báo.

DBC hai dòng `(1, 10)`, `(2, 20)`. Bản chữ thêm dòng `\t999`. Kết quả thoát 0, stdout không có dòng thông báo nào. Tệp cột ghi `khớp 100.0% (2/2 id)` cho cả hai cột. Giá trị 999 không còn ở đâu trong kết quả.

```text
python -W error build/p1-c/probe_a.py
```

```text
## empty-id
exit 0
notes:
0	ID	id	int	khớp 100.0% (2/2 id)
1	Value	value	int	khớp 100.0% (2/2 id)
```

Exit code 0.

### X-CA-02 Ô float `1e308` làm sập, không ra dòng `tệp:dòng:`

Mục 6: mỗi lỗi một dòng `tệp:dòng: nội dung`, thoát 1. `_float_bits` gọi `struct.pack("<f", value)` khi số đã hữu hạn với Python nhưng tràn float32. `collect` chỉ bắt `ValueError`. `OverflowError` thoát ra ngoài `main`.

DBC một dòng id 1, cột float 0. Bản chữ `1\t1e308`. `--check` không in gì ra stdout.

```text
## float-1e308
exit CRASH
stdout:
traceback:
OverflowError: float too large to pack with f format
traceback_has_OverflowError True
stdout_has_file_line False
```

### X-CA-03 Id `1.0` bị coi là không có id chung

`_id_key` chỉ nhận `[+-]?\d+`. Không khớp thì `_match_notes` bỏ dòng, không thông báo. `atoi("1.0")` của bộ đọc bảng chữ ra 1. DBC id 1, giá trị 10. Bản chữ `1.0\t10`. Thoát 0. Cả hai cột ghi `không có id chung`. Bảng vẫn được ghi (`bản ghi: 1`).

```text
## id-1.0
exit 0
notes:
0	ID	id	int	không có id chung
1	Value	value	int	không có id chung
```

`grep` `1e308`, `1.0` và `không có id chung` trong `test_export_tables.py` không có dòng nào.

## Trả lời xét chéo

### X-BC-01 NHẬN

Mục 6 bắt lỗi ô chứa tab kèm tệp, dòng và cột. `server_value` nhận tên khoá và báo `tệp:dòng:cột: ô chứa tab`.

Cây giả có `title=a<tab>b` và `chuangjian.nav`. Lệnh `python -W error build/p1-c/reply_xbc.py` (đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT`):

```text
FIXTURE ok False
FIXTURE errors ['Public/Scene/demo_monster.ini:23:title: ô chứa tab', 'Public/Scene/chuangjian.nav:1: không gắn được vào cảnh nào']
FIXTURE dest_exists False
```

Dòng 23 là khoá `title` thêm ở cuối tệp quái của test. Chuỗi lỗi có `title`. `test_reject_tab_inside_value` đòi `:title: ô chứa tab` và đòi thư mục đích không được tạo.

### X-BC-02 NHẬN

Mục 7: kiểm hết rồi mới ghi. Tệp không gắn được cũng là lỗi, nên lần đó không ghi và không xoá cây cũ.

Cùng lệnh, dữ liệu thật, đích `build/p1-c/reply-xbc/real-scenes`:

```text
REAL ok False
REAL unattached 45
REAL book_errors 0
REAL dest_exists False
```

`test_orphan_scene_and_dropped_test_file` đòi `self.dest` không tồn tại khi `ok` là false. `SERVER/scenes` không bị lượt này ghi lại: 244 thư mục, `caoyuan/spawns.tsv` nguồn `Public/Scene/caoyuan_monster.ini`, dòng 67 cột `level` là `-1`, `luoyang/walk.nav` 1638404 byte.

### X-BC-03 NHẬN

Câu note của cột `level` đổi thành `cấp trong tệp quái, khi vắng thì 0; monster_level không áp vào`. Cùng câu nằm trong `TOOLS/server/columns/scenes/spawns.tsv` và trong tệp cột do một lượt xuất sạch sinh ra. `test_published_spawn_level_note` và `test_minimal_scene_roundtrip` đọc câu đó. `test_level_override_and_patrol_unread` từ chối chữ `ghi đè` trong note.

`PATROLPOINTNUM` còn dấu cách được `note_int` in ra. Cùng lệnh trên dữ liệu thật:

```text
REAL int_not_canonical 289
REAL padded_count 24
REAL patrol_places 24
REAL patrol_sample ['Public/Scene/luoyang_patrolpoint.ini:341:PATROLPOINTNUM', 'Public/Scene/luoyang_patrolpoint.ini:399:PATROLPOINTNUM', 'Public/Scene/luoyang_patrolpoint.ini:457:PATROLPOINTNUM']
COLUMN level cấp trong tệp quái, khi vắng thì 0; monster_level không áp vào
```

289 = 200 `teleport_to_respawn` + 65 `script_id` + 24 `PATROLPOINTNUM`. `padded_count` vẫn 24 vì `luoyang_patrolpoint.ini` gắn cả `luoyang` và `luoyangsnow`. Test thật khoá ba số đó.

### Lệnh test

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_scene.py" -v
```

Đã đặt hai biến môi trường. Exit code 0.

```text
Ran 20 tests in 1.683s
OK
```

20 tên đều `ok`, gồm `test_reject_tab_inside_value`, `test_orphan_scene_and_dropped_test_file`, `test_published_spawn_level_note`, `test_level_override_and_patrol_unread` và `test_real_tree_if_present`.
