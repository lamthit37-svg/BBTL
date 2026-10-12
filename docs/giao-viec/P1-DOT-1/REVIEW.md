# Review P1 đợt 1 — bước 2

Script giữ ở `docs/giao-viec/P1-DOT-1/kiem/kiem_doc_lap.py` và `kiem/pha.py`. Không sửa mã A, B, C, L. Không mở `Account.txt` và không mở `SERVER/config/secrets.local.toml`.

## Tiêu chí mục 10

T1 đạt. Không đặt hai biến môi trường.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_*.py"
Ran 103 tests in 0.297s
OK (skipped=5)
```

Lý do bỏ qua, cùng lệnh thêm `-v`: `test_real_tree_if_present` và `test_real_tree` là `thiếu THIENLONG_LEGACY_ROOT`; `test_real_tables_roundtrip`, `test_real_config_is_classified`, `test_every_source_file_once` là `thiếu THIENLONG_RAW_ROOT hoặc THIENLONG_LEGACY_ROOT`.

T2 đạt. Đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT`.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_*.py"
Ran 103 tests in 53.350s
OK
```

Không ca nào bị bỏ qua. Lệnh này gọi lại `export_tables.py` vào `SERVER/tables`. Đối chiếu ô ở T6 chạy trước lệnh này.

T3 chưa chạy. `TOOLS/server/build_data.py` không có. Đó là bước 5 của L.

T4 chưa chạy. Cùng lý do T3. Không có mã SHA-256 của `build_data.py --digest`.

T5 đạt với ba cây bảng tên và với `Public/Scene`.

```text
python -W error docs/giao-viec/P1-DOT-1/kiem/kiem_doc_lap.py
server_config: đĩa 113, bảng tên 113, thiếu 0, thừa 0
public_config: đĩa 271, bảng tên 271, thiếu 0, thừa 0
client_2026: đĩa 1877, bảng tên 1877, thiếu 0, thừa 0
Public/Scene: tệp 3251, thư mục con 0
tên cảnh chỉ khác hoa thường: 0
```

`python -W error TOOLS/server/export_scene.py "<tlbb>" build/p1-r/scene-check --check` thoát 0. Cộng các loại in ra đúng 3251. `python -W error TOOLS/server/table_census.py "<_raw>" --check` thoát 0: tệp 1877, chưa phân loại 0, table 635, client_only 109, deferred 1132, dropped 1.

T6 không đạt. Ô DBC và bảng chữ khớp. 13 ô `level` của `caoyuan/spawns.tsv` không phải giá trị `LoadMonster` đọc. Chi tiết ở R-C-01.

`python -W error docs/giao-viec/P1-DOT-1/kiem/kiem_doc_lap.py` (exit 0, 223 giây):

```text
bảng 635, bản ghi 994925, lệch 0
section 923, scenenumber '723', lệch 0
bảng quái đã so số dòng 1429, lệch 0
Script.dat: gốc 4307 tsv 4307 khớp True
AIScript.dat: gốc 269 tsv 269 khớp True
```

Bảng chữ gọi riêng `section_legacy()` của cùng script:

```text
bảng chữ đã so 58, lệch 0, dòng dài nhất 2901 byte
```

Đếm section `MerchandiseN` theo `shop_key`: `lech 0 dong 458 khoa 15`. Lệnh đó không so từng ô giá. Chưa so từng ô `SystemInfo.ini`, `BaseValueTable.ini`, `GuildMemberAccess.ini`.

T7 đạt.

```text
python -W error TOOLS/server/lint_config.py
12 tệp sạch, 144 cài đặt đều có chú thích và thẳng cột
```

256 `scene.toml` không nhét một lần vào dòng lệnh Windows. Chạy cùng `lint_config.py` theo cụm 40 đường dẫn: bảy cụm, `nhom loi 0`. Số cài đặt 498 + 829 + 872 + 357 + 1080 + 712 + 343 = 4691.

T8 chưa đối được với mốc bước 0. Repo không có bản `git status` lúc L bắt đầu. `git status --short` hiện có sửa ở `SRC/`, `tests/`, `CMakeLists.txt`, `AGENTS.md`, `docs/NGHI-NGO.md`, `docs/TIEN-DO.md` và nhiều tệp client khác. Đề bài mục 2 đã nói cây này bẩn vì phiên khác. Không có chứng cứ những đường đó do đợt này sửa. Tệp của đợt này nằm ở `TOOLS/server/`, `SERVER/tables/`, `SERVER/scenes/`, `docs/giao-viec/`. Cả `SERVER/` đang untracked nên `git status` không tách được config cũ với bảng mới.

T9 đạt trong phạm vi không mở `Account.txt`. `table_names.tsv` ghi `Account.txt` là `dropped`. Script đối chiếu chỉ thấy tên tệp trong `DE-BAI.md` và `BAO-CAO-B.md`. Không thấy trong `SERVER/tables` hay `SERVER/scenes`. Hai báo cáo không dán nội dung mật khẩu.

## Finding

### R-A-01 [CHẶN] Một bảng lỗi vẫn ghi các bảng còn lại và xoá bảng cũ không được ghi lại
- Chỗ: `TOOLS/server/export_tables.py:623`
- Bằng chứng: `python -W error docs/giao-viec/P1-DOT-1/kiem/pha.py` rồi

```text
## một bảng có tab, bảng Also không còn trong danh sách xuất
exit 1
Bad.txt:1: cột 0 chứa tab hoặc xuống dòng
bảng xuất: 1
good.tsv còn: True
bad.tsv còn: False
also.tsv còn: False
## bản đối chiếu UTF-8 hỏng
exit 1
Pet.txt:2: byte UTF-8 hỏng
bảng xuất: 1
pets.tsv đã ghi: True
```

`also.tsv` có sau lượt xuất sạch, mất sau lượt thoát 1. `test_reject_tab_in_cell_but_keep_other_table` và `test_reject_bad_utf8_reference` đòi tệp bảng kia vẫn tồn tại khi đã có lỗi.
- Đòi hỏi: có một bảng lỗi thì không ghi tệp nào và không xoá tệp của lượt trước. Thoát 1. Test phải đỏ nếu còn tệp mới hoặc mất tệp cũ.

### R-C-01 [CHẶN] level trong spawns.tsv của caoyuan không còn là level mà LoadMonster đọc
- Chỗ: `TOOLS/server/export_scene.py:632`
- Bằng chứng: `MonsterManager.cpp` dòng 477 đọc khoá `level` trong chính section quái, `atoi`. Grep `monster_level` trong `C:\Users\myhea\Desktop\New folder\tlbb_server` không có chỗ nào. `python -W error docs/giao-viec/P1-DOT-1/kiem/kiem_doc_lap.py` rồi

```text
caoyuan: dòng 67 tệp quái '-1' tệp level '63' tsv '63'
caoyuan: dòng 124 tệp quái '-1' tệp level '66' tsv '66'
caoyuan: dòng 125 tệp quái '-1' tệp level '60' tsv '60'
caoyuan: dòng 126 tệp quái '-1' tệp level '60' tsv '60'
caoyuan: dòng 127 tệp quái '-1' tệp level '64' tsv '64'
caoyuan: dòng 128 tệp quái '-1' tệp level '64' tsv '64'
caoyuan: dòng 129 tệp quái '-1' tệp level '62' tsv '62'
caoyuan: dòng 130 tệp quái '-1' tệp level '60' tsv '60'
cặp đã so 2, ô level khác tệp quái 13, ô trống bị điền 0
```

Nguồn của `SERVER/scenes/caoyuan/spawns.tsv` là `Public/Scene/caoyuan_monster.ini + Public/Scene/caoyuan_monster_level.ini`. `test_level_override_and_patrol_unread` chỉ đặt level ở tệp level khi tệp quái không có khoá `level`, rồi đòi ô TSV bằng giá trị tệp level. Ca hai bên khác nhau không bị test bắt.
- Đòi hỏi: `spawns.tsv` cột `level` là nguyên văn khoá `level` của tệp quái, đúng ô `LoadMonster` đọc. `*_monster_level.ini` xuất riêng. 13 ô caoyuan phải còn `-1` trong `spawns.tsv`.

### R-C-02 [SỬA] Tệp không gắn được vào cảnh nào vẫn thoát 0 và thành cảnh mới
- Chỗ: `TOOLS/server/export_scene.py:1027`
- Bằng chứng: đề bài mục 5 nói tệp không gắn được vào cảnh nào là lỗi có tên tệp. `export_scene.py --check` in `cảnh không scn: 12` và thoát 0. `pha.py`:

```text
khong-scn: ok True lỗi 0 cảnh 1
  tệp đích: 3
```

`kiem_doc_lap.py` liệt kê 12 thư mục có `scene_file = 0`: `_pingpan_40`, `_pingpan_55`, `_pingpan_70`, `_pingpan_85`, `chuangjian`, `gongdishaolinmis`, `jishiemeimis`, `xuanren`, `yamentianshanmis`, `登陆`, `选人`, `选人11`. `test_orphan_scene_and_dropped_test_file` đòi `report.ok` và `scene_file = 0`.
- Đòi hỏi: những tệp này làm lệnh thoát 1, mỗi tệp một dòng `tệp:dòng: không gắn được vào cảnh nào`. Không tạo cảnh mồ côi trong lượt thoát lỗi. Test phải đỏ nếu lệnh vẫn thoát 0.

### R-C-03 [SỬA] Ô kiểu int không chuẩn chưa được đếm hết và chưa in vị trí
- Chỗ: `TOOLS/server/export_scene.py:301` và `export_scene.py:724`
- Bằng chứng: `--check` in `int_not_canonical 65`, không có tên tệp. Đếm riêng trong TSV cảnh:

```text
tong 265
200 ('patrols.tsv', 'teleport_to_respawn', 'space')
61 ('spawns.tsv', 'script_id', 'zero')
4 ('areas.tsv', 'script_id', 'zero')
```

Mẫu: `bashu_1/spawns.tsv` dòng 40 `script_id='040001'`; `cangmang/patrols.tsv` dòng 0 `teleport_to_respawn='0 '`. 61 + 4 = 65 đúng bộ đếm hiện có. 200 ô `0 ` của patrol không đi qua `_note_text`.
- Đòi hỏi: mỗi ô int không phải dạng `-?\d+` không có số 0 thừa phải được đếm và in `tệp:dòng:cột`. Bộ đếm phải gồm 200 ô `teleport_to_respawn` đang là `0 `.

### R-L-01 [SỬA] format_float32 ném OverflowError với float32 hữu hạn lớn nhất
- Chỗ: `TOOLS/server/tsv_file.py:299`
- Bằng chứng:

```text
python -W error -c "import sys; sys.path.insert(0,'TOOLS/server'); import tsv_file
for bits in (0x7F7FFFFF, 0xFF7FFFFF, 0x7F7FFFFE):
    try:
        print(hex(bits), tsv_file.format_float32(bits))
    except Exception as exc:
        print(hex(bits), type(exc).__name__, exc)"
0x7f7fffff OverflowError float too large to pack with f format
0xff7fffff OverflowError float too large to pack with f format
0x7f7ffffe OverflowError float too large to pack with f format
```

`pha.py` cũng chết tại `0x7f7fffff` trước khi được bọc. Dữ liệu 635 bảng hiện không đụng mẫu này: xuất `--check` thoát 0 và so từng ô float lệch 0. Hàm vẫn không đúng hợp đồng "mọi float32 hữu hạn có chuỗi đọc lại đúng bit".
- Đòi hỏi: `0x7F7FFFFF`, `0xFF7FFFFF` và `0x7F7FFFFE` trả chuỗi, `struct.pack("<f", float(chuỗi))` ra đúng bit, không ném `OverflowError`.

### R-L-02 [GHI] table_names không có Public/Data của bản 0859602
- Chỗ: `TOOLS/server/table_names.tsv`
- Bằng chứng: grep `Script.dat` và `AIScript.dat` chỉ thấy hai dòng `client_2026`, fate `deferred`. Không có dòng `Public/Data`. B vẫn xuất `script_index.tsv` (4307 dòng) và `monster_ai_scripts.tsv` (269 dòng). Đối chiếu độc lập khớp từng dòng.
- Đòi hỏi: nếu hai tệp này là bảng của đợt này thì hợp đồng phải có dòng `tree`, `source`, `target`. Không đổi byte hai TSV khi chúng đã khớp bộ đọc `CFileDataMgr::Init`.

### R-A-02 [GHI] --check in bảng xuất bằng 0 dù có 635 bảng hợp lệ
- Chỗ: `TOOLS/server/export_tables.py:659`
- Bằng chứng: `export_tables.py "<_raw>" "<tlbb>" build/p1-r/tables-check --check` thoát 0 và in `bảng xuất: 0` rồi `bản ghi: 994925`. Thư mục đích không được tạo.
- Đòi hỏi: dòng tổng kết khi `--check` phải nói số bảng sẽ ghi, khác với số tệp vừa ghi. Không ghi đĩa.

## Đã thử phá mà không phá được

A. So 635 bảng, 994925 bản ghi, với `TOOLS/content/dbc.py` và `split("\t")`: lệch 0. Mẫu hạt `20261006` mười hai ô đều khớp. Tab trong ô chuỗi bị từ chối. Hợp đồng TSV của cây đã xuất: 4032 tệp, 0 BOM, 0 CR, 0 tên cột lệch, 0 đường dẫn tuyệt đối trong `source`.

B. `pha.py`: thừa ô, UTF-8 hỏng, id trùng, tab trong giá trị ini, số vượt int32, khoá lạ — mỗi ca một lỗi và 0 tệp ghi. 58 bảng chữ so với bộ đọc tự viết theo `OpenFromMemoryImpl_Text`: lệch 0, dòng dài nhất 2901 byte, dưới 10239. `SceneInfo.ini` 923 section khớp `scenes.tsv`, `scenenumber` vẫn `723`. `AIPARAM9` và `AIPARAM10`: 62 ô, lệch 0 so với nguyên văn. Hai `.dat` khớp từng dòng. Mười lăm shop: 458 dòng, số section khớp `shop_key`. `--check` không tạo `build/p1-r/legacy-check`.

C. Nav: lệch cỡ 0; `luoyang/walk.nav` 1638404 byte, đầu 640 x 640; 249 bản `walk.nav` đều có hash thuộc nav gốc (165 hash khác nhau vì có tệp gốc trùng byte). 1429 bảng quái: số dòng khớp `monstercount`. `pha.py`: nav lệch cỡ, khoá lạ, `monstercount` lệch, tệp chưa phân loại — đều thoát lỗi và 0 tệp đích. Guid trùng được giữ (`guid-trung: ok True`). `LoadMonster` không bỏ guid trùng, nên giữ cả hai dòng không phải mất dữ liệu.

L. `write_table` từ chối tab, xuống dòng, ô đầu `#`, bảng một cột rỗng. `format_float32(1)` ra `1e-45` và khớp bit. `0x80000000` ra `-0` và khớp bit. `0x00800000` ra `1.1754944e-38` và khớp bit.

## Phán quyết

Chạy lại sau khi sửa. Không ghi đè `SERVER/tables` và `SERVER/scenes`. `python -W error -m unittest discover -s TOOLS/server -p "test_*.py"` không đặt biến môi trường: `Ran 117 tests in 0.321s`, `OK (skipped=6)`. Không chạy `build_data.py` trên dữ liệu thật.

- R-A-01 ĐÃ SỬA. `Remove-Item -Recurse -Force build\p1-r\pha` rồi `python -W error docs/giao-viec/P1-DOT-1/kiem/pha.py`: lượt tab thoát 1, `bảng đã ghi: 0`, `good.tsv còn: True`, `bad.tsv còn: False`, `also.tsv còn: True`. Bản đối chiếu UTF-8 hỏng: `pets.tsv đã ghi: False`.
- R-A-02 ĐÃ SỬA. `python -W error TOOLS/server/export_tables.py "<_raw>" "<tlbb>" build/p1-r/tables-check --check --columns build/p1-r/columns-check`: thoát 0, `bảng sẽ ghi: 635`, `bảng đã ghi: 0`. `build/p1-r/tables-check` không được tạo.
- R-C-01 ĐÃ SỬA. Đọc `SERVER/scenes/caoyuan/spawns.tsv`: `source` là `Public/Scene/caoyuan_monster.ini`, dòng 67 cột `level` là `-1`. `spawn_levels.tsv` 173 dòng, dòng 67 là `('67', '63')`, nguồn `Public/Scene/caoyuan_monster_level.ini`.
- R-C-02 ĐÃ SỬA. `export_scene.py "<tlbb>" build/p1-r/scene-check --check` thoát 1. Log có 45 dòng `Public/Scene/<tên>:1:` gồm `_pingpan_40_monster.ini` và `chuangjian.nav`. `SERVER/scenes` còn 244 thư mục. `_pingpan_40`, `chuangjian`, `xuanren` không còn. `pha.py` sạch: `khong-scn` `ok False`, `tệp đích: 0`.
- R-C-03 ĐÃ SỬA. Cùng log `--check` in `int_not_canonical 289`. Trong đó 200 dòng kết thúc `:teleport_to_respawn`, 65 dòng `:script_id`, 24 dòng `:PATROLPOINTNUM`. Mẫu `Public/Scene/luoyang_patrolpoint.ini:341:PATROLPOINTNUM`.
- R-L-01 ĐÃ SỬA. Lệnh trong finding, nay có `_packed_f32`: `0x7f7fffff '3.4028235e+38' khop True`, `0xff7fffff '-3.4028235e+38' khop True`, `0x7f7ffffe '3.4028233e+38' khop True`. Không còn `OverflowError`.
- R-L-02 ĐÃ SỬA. `tsv_file.read_name_map()` ra đúng 2 dòng `public_data`: `Script.dat` tới `tables/server/script_index.tsv` owner B, `AIScript.dat` tới `tables/server/monster_ai_scripts.tsv` owner B.
- X-AB-01 ĐÃ SỬA. `import_legacy.py "<tlbb>" build/p1-r/legacy-check --check` thoát 0, không tạo thư mục đích. `script_index.tsv: ... dòng script bỏ 649`. Đếm độc lập trên `Script.dat`: 476 dòng `;`, 172 dòng trống, 1 dòng khác, cộng 649.
- X-AB-02 ĐÃ SỬA. Cùng stdout `--check`: `effects.tsv` liệt kê `cột text toàn số` có `column_29`. Kiểu không bị đổi trong câu tổng kết.
- X-AB-03 ĐÃ SỬA. `python -W error docs/giao-viec/P1-DOT-1/kiem/phan_buoc4.py`: `errors []`, ghi `sample.tsv`, `types ('int', 'text')`, `rows (('1', '2'),)`, tổng kết `ô sau kiểu bị bỏ 1`.
- X-CA-01 ĐÃ SỬA. Cùng script, ca `id-rong`: thoát 0, `Pet.txt:1: đối chiếu bỏ 1 dòng ô đầu rỗng`, note `khớp 100.0% (2/2 id)`.
- X-CA-02 ĐÃ SỬA. Ca `float-tran`: thoát 1, `Pet.txt:3: số thực không vừa float32`, `bảng đã ghi: 0`, `pets False`.
- X-CA-03 ĐÃ SỬA. Ca `id-thap-phan`: thoát 0, `Pet.txt:1: đối chiếu 1 id không phải số nguyên thuần`, note `khớp 100.0% (1/1 id)`. Không còn chữ `không có id chung`.
- X-BC-01 ĐÃ SỬA. Cùng script: `ok False`, `errors ['Public/Scene/demo_monster.ini:6:title: ô chứa tab']`, `dest False`.
- X-BC-02 ĐÃ SỬA. Cùng script: lượt một `first_ok True`, lượt thêm `chuangjian.nav` thì `second_ok False`, `marker_same True`, `chuangjian False`.
- X-BC-03 ĐÃ SỬA. `TOOLS/server/columns/scenes/spawns.tsv` cột `level`: `cấp trong tệp quái, khi vắng thì 0; monster_level không áp vào`. `--check` cảnh in `int_not_canonical 289` và `padded_count 24`, có dòng `PATROLPOINTNUM`. `luoyang/walk.nav` vẫn 1638404 byte.
