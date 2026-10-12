# Đối chất vai A

## Trả lời review

### R-A-01 NHẬN

`名称$1$` có dòng scope rỗng thành `name` ở `column_terms.tsv`. Ca chữ Hán chưa có tên đổi nhãn thành `试探列甲`. Nhãn này không có trong `column_terms.tsv` và không khớp mẫu `{n}`.

Đỏ trước khi sửa:

```text
python -B -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py" -k test_unknown_chinese_marks_question
AssertionError: 'name' != 'column_1'
Ran 1 test in 0.011s
FAILED (failures=1)
```

Exit 1.

Sau khi sửa, cùng ca, exit 0:

```text
python -B -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py" -k test_unknown_chinese_marks_question
Ran 1 test in 0.010s
OK
```

`column_names.classify("试探列甲", "Pet.txt", ...)` ra `('column_1', 'failed')`. Note vẫn có `?`.

T1, không đặt hai biến:

```text
python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"
Ran 199 tests in 0.634s
OK (skipped=8)
```

T2, đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT`:

```text
python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"
Ran 199 tests in 831.399s
OK
```

Exit 0. Không ca nào bị bỏ qua. 199 vì thêm một ca của R-A-03.

### R-A-02 NHẬN

`Common/GameDefine_Item.h` dòng 41–43 là `IATTRIBUTE_COLD_ATTACK`, `IATTRIBUTE_COLD_RESIST`, `IATTRIBUTE_COLD_TIME`. Chữ 冰 trong tệp của A lấy một tên `cold`, theo enum và theo dòng 159 `冰攻击` → `cold_attack`.

Đổi hai dòng basis mã trong `column_terms.tsv`, không thêm và không bớt dòng:

```text
冰抵抗		cold_resist	code:Common/GameDefine_Item.h:42	enum IATTRIBUTE_COLD_RESIST
减少冰冻迟缓时间		cold_slow_reduction	code:Common/GameDefine_Item.h:43	enum IATTRIBUTE_COLD_TIME
```

Dòng 386 cũng là basis `COLD` mà tên cũ dùng `ice`, nên đổi cùng luật. Không sửa `column_terms_server.tsv`. Scope `ItemSegValue.txt` của B vẫn thắng: `冰抵抗` vẫn `ice_resist`, `减少冰冻迟缓时间` vẫn `reduce_freeze_time`.

```text
EquipBase.txt 冰抵抗 ('cold_resist', 'exact')
GemInfo.txt 冰抵抗 ('cold_resist', 'exact')
ItemSegValue.txt 冰抵抗 ('ice_resist', 'exact')
EquipBase.txt 减少冰冻迟缓时间 ('cold_slow_reduction', 'exact')
ItemSegValue.txt 减少冰冻迟缓时间 ('reduce_freeze_time', 'exact')
```

Đổi đúng tên cột trên dòng tên của `equipment.tsv` và `gems.tsv`, và ô `name` trong hai tệp `columns/shared` tương ứng. Không đụng `tables/server` hay `columns/server`. Mỗi tên mới xuất hiện đúng một ô, là ô tên cột. Ô dữ liệu đầu của hai cột đó vẫn là `-1` và `-1`. `item_segment_values.tsv` của shared giữ `ice_attack` và `ice_resist` vì scope của B thắng.

### R-A-03 NHẬN

Mẫu cha không khớp tệp nào thì `--check` báo lỗi, không tính mọi giá trị con là thiếu. Cảnh thiếu tệp cha khi mẫu `*` vẫn khớp tệp khác thì vẫn tính thiếu, như cũ.

Đỏ trước khi sửa, con một id `7`, cha `tables/missing.tsv` không có, `known_missing` là 1:

```text
python -B -W error -m unittest discover -s TOOLS/server -p "test_diff_tables.py" -k test_check_rejects_parent_that_matches_no_file
AssertionError: 0 != 1 : cặp: 1
dòng tham chiếu: 1
dòng có giá trị thiếu: 1
Ran 1 test in 0.059s
FAILED (failures=1)
```

Exit 1.

Sau khi sửa, cùng ca nằm trong 5 ca của `test_diff_tables.py`, exit 0. Lệnh `--check` trên cây thử đó:

```text
python -B -W error TOOLS/server/diff_tables.py build\p1-a\diff\absent\tlbb build\p1-a\diff\absent\server --names build\p1-a\diff\absent\names.tsv --refs build\p1-a\diff\absent\refs --check
dòng tham chiếu: 0
dòng có giá trị thiếu: 0
refs/shared.tsv:4: mẫu không khớp tệp nào
```

Exit 1.

Cây thật, exit 0, năm tổng không đổi:

```text
python -B -W error TOOLS/server/diff_tables.py "<tlbb>" SERVER --check
cặp: 106
ids_2026: 354614
ids_legacy: 62374
common: 61522
only_2026: 293092
only_legacy: 852
dòng tham chiếu: 55
dòng có giá trị thiếu: 6
```

`python -B -W error TOOLS/server/lint_py.py` trên `diff_tables.py`, `test_diff_tables.py` và `test_export_tables.py` thoát 0, không in dòng.

## Xét chéo B

Chỉ đọc mã và chạy công cụ. Không sửa tệp của B.

Đã chạy `python -B -W error TOOLS/server/import_legacy.py "<tlbb>" SERVER/tables/server --check`, thoát 0. Đối chiếu riêng mọi bảng chữ của B với `OpenFromMemoryImpl_Text`: bỏ token kiểu rỗng, lấy đúng số ô đầu, `atoi` cho `INT`, `strip` hai đầu cho `FLOAT`. Lệch 0 bảng. Ba tệp có ô kiểu rỗng (`ItemSegValue.txt`, `ItemSegRate.txt`, `CreateQualityOfVaryPetTbl.txt`) đều là ô rỗng ở đuôi, không xen giữa. Quét 69 bảng `import_legacy.py`: tên cột khớp `[a-z][a-z0-9_]*`, không trùng, không CR, không BOM, có LF cuối, dòng `source` là `<tree>/...`, không ô đầu bắt đầu bằng `#`. Ô `int` đều dạng chính tắc, ô `float` không rỗng và khớp số. Mục 6 trên các tệp TSV đã ghi: không thấy vi phạm.

`import_rules.py`: với mọi khoá `fate=rule`, chuỗi `Ini::ReadText` (cắt tại `;`, tab, `]`) sau `convert` khớp giá trị trong toml, kể cả các mảng. Riêng `PkRefixOfDamage` là `100    ;...`: `ReadText` còn bốn dấu cách, `_split_value` cắt trước khi `int`, toml vẫn `100`, cùng `atoi`. Không lệch số.

### X-AB-01 [SỬA] Dòng ini bắt đầu bằng `#` bị bỏ, không đếm, không lỗi

- Chỗ: `TOOLS/server/import_legacy.py:406` (`_ini_noise`) và `TOOLS/server/import_rules.py:259`
- `Ini.cpp` `ReadDataName` dừng ở `=`, `;`, `\r`. `#` không phải chú thích. Dòng `#extra=9` là khoá `#extra`, giá trị `9`. Công cụ coi mọi dòng strip xong bắt đầu bằng `#` là nhiễu và `continue`, không tăng bộ đếm nào.
- Bằng chứng: ghi `build/p1-a-xet-b/SceneInfo.ini` một cảnh đủ khoá bắt buộc, thêm dòng `#extra=9`, gọi `_parse_scene`. `changes` là `{}`. Không ô nào là `9`. Không exception.
- Trên cây thật, quét `SceneInfo.ini`, `SystemInfo.ini`, `BaseValueTable.ini`, `GuildMemberAccess.ini`, `Public/Config/MonsterAITable.ini` và 15 `RandShop/*.ini`: 0 dòng strip bắt đầu bằng `#`. Chưa mất dòng nào của bản 0859602. `test_import_legacy.py` không có ca này. `test_ini_line_without_equals` chỉ có dòng không có `=`.
- Đòi hỏi: dòng `#khoá=giá trị` trong section là khoá lạ hoặc được xuất, có vị trí. Không được nuốt. Test một ca, đỏ nếu `changes` rỗng và ô không còn giá trị.

### X-AB-02 [SỬA] `Odds` và `odds` thành `odds` với `odds_lower`, không đánh số

- Chỗ: `TOOLS/server/import_legacy.py:986` và `TOOLS/server/columns/server/random_shop_goods.tsv:12`
- Mục 5.1 đợt 3: tên lặp đánh số từ 1, áp cho cả bảng máy chủ. Mục 5 vai B đợt 1: không đặt tên theo phỏng đoán; chưa chắc thì `column_<n>` và `?`. Hai nhãn `Odds` và `odds` cùng ra `odds` sau snake. Tên đang là `odds` và `odds_lower`. Note dòng `odds` vẫn có `?`.
- `--check` in `random_shop_goods.tsv: ... tên thật 9, cột ? 1`. `test_shop_merge_and_total` không đọc tên cột. `test_real_tree` cũng không. R-B-01 đã bắt cùng luật này với `_clientres`; ca `odds` còn nguyên.
- Mục 6 vẫn ổn: `odds_lower` khớp regex và không trùng tên. Lệch là luật tên lặp, không phải regex.
- Đòi hỏi: `odds_1` và `odds_2` theo thứ tự cột, note không còn `?`. Test đọc đúng hai tên đó.

### X-AB-03 [SỬA] Mã nạp hòm đồ không đọc `item_1_id` làm vật phẩm đầu; test không mở enum

- Chỗ: `TOOLS/server/columns/server/drop_packages.tsv` cột 2, 4, 200, 202. Mã: `ItemTable.cpp:1115` và `ItemTypes.h:28`
- `TBDropBoxBegin = 2`, vòng `j < MAX_DROPBOX_CARRAGE` (100). Ô vật phẩm là cột `2+2*j`, phẩm chất là cột kế. Đo trên tệp cột hiện tại:

```text
cột 2  broadcast_type_id
cột 3  force_bind
cột 4  item_1_id
cột 200 item_99_id
cột 202 item_100_id
```

- Slot 0 của mã là cột 2, tức `broadcast_type_id`, không phải `item_1_id`. Slot 99 là cột 200, tức `item_99_id`. `item_100_id` ở cột 202, `j` không tới. Ô vẫn còn trong TSV, không mất byte. Người đọc tên cột sẽ gắn sai slot so với máy chủ 2008. `test_real_tree` không so chỉ số với `InitDropBoxTable`.
- Đòi hỏi: note của các cột này ghi rõ mã bắt đầu ở cột 2, 100 cặp, `item_100_id` nằm ngoài vòng. Không đổi tên nhãn nếu nhãn tệp đã nói khác mã. Test một bảng giả có cột 2 không phải `Item1ID` thì note phải nhắc chỉ số mã.

## Trả lời xét chéo

### X-CA-01 NHẬN

Id cột đầu không trùng thì `_pair_rows` trả hai tuple rỗng, `align` thấy không có dòng đã ghép và đánh mọi cột là `mới ở 2026`. Không sửa `align`: nhánh đó đúng khi không có dòng để căn. Sửa ở `_aligned_links`: từ hai dòng trở lên, nếu đúng một độ lệch cột làm mọi ô gốc bằng ô 2026 cùng kiểu, gắn tên gốc vào lát đó (`neo`, khớp 100%). Một dòng vẫn để `column_0`, đúng `test_layout_mismatch_keeps_default_names`. Lát không khớp hết thì không mượn tên.

Đỏ trước khi sửa:

```text
python -B -W error -m unittest TOOLS.server.test_export_tables.ExportCollectTest.test_leading_id_keeps_embedded_legacy_names
AssertionError: ('column_0', 'column_1', 'column_2') != ('column_0', 'id', 'sect')
Ran 1 test in 0.009s
FAILED (failures=1)
```

Exit 1.

Trên cây thật, chỉ `AbilityExpTable.txt` (20 dòng, lệch 1) và `Mission_NpcDefault.txt` (16 dòng, lệch 1) rơi vào nhánh này. `AbilityLevelUp/cailiaojiagong.txt` có neo 0 nhưng vẫn ghép được id, không đổi. Bảng một dòng `material_processing` không đổi.

Xuất lại:

```text
python -B -W error TOOLS/server/export_tables.py "<_raw>" "<tlbb>" SERVER/tables
```

Exit 0. `bảng đã ghi: 635`, `bản ghi: 994925`, `thời gian: 251.9 giây`. So SHA-256 phần ô sau dòng tên cột của mọi bảng `shared` và `variants`: 0 bảng đổi ô. Đúng năm tệp đổi byte: hai bảng dữ liệu (chỉ dòng tên cột), hai tệp cột, `column_alignment.tsv`.

`AbilityExpTable.txt` trong `column_alignment.tsv` thành `7 6 6 0 0 1 0` (trước đó neo 0, mất 6). `Mission_NpcDefault.txt` thành `10 9 9 0 0 1 0`. Tệp cột giữ `对象名称$1$`, `基础熟练度`, `对应技能等级`, `损耗比例`, `AbilityId`, `编号（对象的编号）` và chín tên của `Mission_NpcDefault`. `AbilityId` thành `life_skill_id`, `ScriptId` thành `script_id`, `SceneID` thành `scene_id`, `NpcName$1$` thành `npc_name`. Nhãn chữ Hán chưa có thuật ngữ vẫn `column_<n>` kèm `?`. Ô đầu của hai bảng vẫn `1	铜矿脉	...	20003001` và `1	1040000	6	干光豪	...`.

`python -B -W error TOOLS/server/lint_names.py` thoát 0.

### X-CA-02 NHẬN

Ba chỗ. Byte UTF-8 hỏng đếm `\n` tới byte hỏng, cùng `export_tables._decode_legacy`. `1e39` ở cột id bọc lại thành `tệp:dòng: số thực không vừa float32`. Dòng `source` của bảng gộp ghi mẫu và số tệp: một cặp là `public_config/Pet.txt (1 tệp)`; nhiều cặp là `public_config/* (N tệp)`. Bảng phủ ghi `<thư mục refs>/*.tsv (N tệp)`, đường dẫn tương đối từ gốc dự án, không đường dẫn tuyệt đối.

Đỏ trước khi sửa, trong lần chạy bốn ca mới của `test_diff_tables`, exit 1. Hai ca của finding này:

```text
'Pet.txt:4: byte UTF-8 hỏng' not found in 'Pet.txt:1: byte UTF-8 hỏng'
'Pet.txt:3: số thực không vừa float32' not found in 'số thực không vừa float32'
```

### X-CA-03 NHẬN

`directory.glob` trên thư mục không có thì rỗng. Không sửa `table_refs.py` (của L). `diff_tables` kiểm `is_dir` trước khi đọc. Thiếu thư mục thì một dòng `đường/tương/đối:1: thư mục refs không tồn tại`, thoát 1, không in tổng kết. Thư mục có mà không có `*.tsv` vẫn là 0 dòng phủ.

Đỏ, cùng ca đã dựng tên và một cặp, trước khi sửa:

```text
python -B -W error -m unittest TOOLS.server.test_diff_tables.CommandTest.test_missing_refs_directory_is_an_error
AssertionError: 0 != 1 : cặp: 1
ids_2026: 1
ids_legacy: 1
common: 1
only_2026: 0
only_legacy: 0
dòng tham chiếu: 0
dòng có giá trị thiếu: 0
```

Exit 1 của test. Lệnh công cụ thoát 0.

### X-CA-04 NHẬN

`hai cột khác kiểu` vẫn là lỗi, nhưng không `continue` trước khi đo. Dòng phủ được tính. `--check` không ghi, đúng mục 5.3. Không `--check`, nếu mọi dòng `refs/` đều ra một dòng phủ thì vẫn ghi rồi thoát 1. Lỗi khác làm rơi dòng (mẫu không khớp, cột float) thì không ghi tệp thiếu dòng.

Đỏ trước khi sửa: `dòng tham chiếu: 1` không có trong output `dòng tham chiếu: 0` kèm `refs/shared.tsv:4: hai cột khác kiểu`.

Cây `build/p1c-xet-a/hop` của C, sau khi sửa:

```text
python -B -W error TOOLS/server/diff_tables.py build\p1c-xet-a\hop\tlbb build\p1c-xet-a\hop\server --names build\p1c-xet-a\hop\names.tsv --refs build\p1c-xet-a\hop\refs --output build\p1-a-xet-c\hop-out
cặp: 1
ids_2026: 1
ids_legacy: 1
common: 1
only_2026: 0
only_legacy: 0
dòng tham chiếu: 1
dòng có giá trị thiếu: 0
refs/shared.tsv:4: hai cột khác kiểu
EXIT:1
```

Sau khi bỏ dòng `#`, `table_ref_coverage.tsv` trùng `cpp-coverage.tsv` từng byte, gồm dòng `pets.tsv` / `id` / `1 1 1 1 0 0`.

Cây thật, `--check`, exit 0, năm tổng và hai số phủ không đổi: cặp 106, ids_2026 354614, ids_legacy 62374, common 61522, only_2026 293092, only_legacy 852, dòng tham chiếu 55, dòng có giá trị thiếu 6.

Sau khi sửa, exit 0:

```text
python -B -W error -m unittest TOOLS.server.test_diff_tables TOOLS.server.test_export_tables.ExportCollectTest TOOLS.server.test_export_tables.EnglishNameTest TOOLS.server.test_export_tables.ExportCommandTest
Ran 42 tests in 0.710s
OK
```

`python -B -W error TOOLS/server/lint_py.py` trên `diff_tables.py`, `export_tables.py`, `test_diff_tables.py`, `test_export_tables.py` thoát 0, không in dòng. Không chạy `RealExportTest`: xuất cây thật ở trên đã so ô. Không sửa tệp của B hay C.
