# Đối chất vai C

## Trả lời review

### R-C-01 NHẬN

`add_rule` trong `SRC/content/lint.cpp` gọi `parse_known` rồi `return` khi `known_missing` rỗng hoặc không phải số nguyên không âm. Dòng refs không vào danh sách, không có `Issue`. Exe vì vậy in `dòng tham chiếu: 0`, `lỗi: 0` và thoát 0.

Đỏ, trước khi sửa. Đã thêm `known_missing_text` vào `tests/content_tests.cpp`, chưa sửa `lint.cpp`.

```text
cmake --build --preset gcc-debug --target content_tests
.\build\gcc-debug\content_tests.exe
```

Build thoát 0. Exe thoát -1073740791 (`core::check` dừng sau khi in các ca sai).

```text
./tests/content_tests.cpp:288: [known_missing_text] known_missing rỗng là lỗi
./tests/content_tests.cpp:291: [known_missing_text] lỗi known_missing đúng tệp và dòng
./tests/content_tests.cpp:292: [known_missing_text] dòng refs rỗng vẫn nằm trong báo cáo
./tests/content_tests.cpp:293: [known_missing_text] đếm dòng và lỗi
./tests/content_tests.cpp:296: [known_missing_text] known_missing chữ là lỗi
./tests/content_tests.cpp:297: [known_missing_text] dòng refs chữ vẫn nằm trong báo cáo
```

Đã sửa: `note_known` ghi `known_missing không phải số nguyên` tại đúng tệp và đúng dòng, rồi vẫn `push_back` rule. `note_gap` bỏ qua so khớp khi số không đọc được, để không bịa thêm một lệch với 0.

Xanh. Cùng hai lệnh, exe im và `CONTENT_EXIT:0`.

Cây của `docs/giao-viec/P1-DOT-3/kiem/pha.py`, ca `known_missing` trống, exe gcc-debug:

```text
known_missing trống exe 1
a.tsv:4: known_missing không phải số nguyên
tệp: 1
bản ghi: 1
ô: 1
dòng tham chiếu: 1
lỗi: 1
```

Dòng refs còn trong báo cáo (`dòng tham chiếu: 1`) và là lỗi (thoát 1). Ca chữ `x` nằm trong `known_missing_text`, cùng thông điệp, `coverage.size() == 1`.

### R-C-02 NHẬN

`report_clash` chỉ so `parent_column`. `agree_types` đi mọi khoá của session, nên hai tệp cha cùng tên cột `id` mà khác kiểu làm cả hai dòng refs đỏ, dù mỗi dòng trỏ đúng cha cùng kiểu với nó.

Đỏ, cùng lần chạy ở R-C-01, ca `parent_column_type`:

```text
./tests/content_tests.cpp:315: [parent_column_type] hai cha cùng tên cột khác kiểu không làm nhau đỏ
```

Kỳ vọng còn lại của ca này, con `int` trỏ cha `text` phải báo `khác kiểu`, không nằm trong output đỏ. Lệch thật vẫn bị bắt trước khi sửa.

Đã sửa: `owns_parent` chỉ nhận tệp khớp mẫu `parent` của đúng dòng refs, rồi mới so kiểu.

Xanh. `content_tests` gcc-debug im, thoát 0. Cùng ca trong `pha.py`:

```text
khác kiểu giả exe 0
tệp: 4
bản ghi: 4
ô: 4
dòng tham chiếu: 2
lỗi: 0
```

`ctest --preset gcc-debug -R "^(content_tests|server_data_lint)$" --output-on-failure` thoát 0. `content_tests` 0,00 giây, `server_data_lint` 8,34 giây, 2/2. Cây `SERVER` thật vẫn `lỗi` 0; thu hẹp phép so kiểu không làm cây thật đỏ.

## Đã kiểm

- Đỏ rồi xanh: `cmake --build --preset gcc-debug --target content_tests` và `.\build\gcc-debug\content_tests.exe`. Đỏ thoát -1073740791 với bảy dòng ở trên. Xanh im, thoát 0.
- `ctest --preset gcc-debug -R "^(content_tests|server_data_lint)$" --output-on-failure`: 2/2, thoát 0.
- `cmake --build --preset clang-asan --target content_tests` rồi `.\build\clang-asan\content_tests.exe`: im, `ASAN_EXIT:0`.
- `python -B -W error docs\giao-viec\P1-DOT-3\kiem\pha.py`: hai ca của C như trên. Exe vẫn thoát 1 với tệp cụt, tệp rỗng, byte `0xFF`, dòng thiếu ô, và cha không có tệp. Phần Python `cha không có py 0` là R-A-03, không sửa.
- `python C:\Users\myhea\.claude\cpp23\tools\check.py SRC\content\lint.hpp SRC\content\lint.cpp SRC\linttool\main.cpp tests\content_tests.cpp`: `4 tệp, 0 lỗi.`

## Chưa kiểm

Không dựng lại `msvc-release`. Sửa là logic so chuỗi và một nhánh lỗi; gcc-debug đã chạy exe trên cây thật, clang-asan đã chạy `content_tests`, `check.py` đã dịch bằng gcc 16.2 và clang 23.1.

## Giả định

Đường dẫn trong bảng khoá cha dùng `/`, cùng dạng `linttool` đưa vào. `server_data_lint` trên cây thật vẫn xanh nên giả định này khớp dữ liệu hiện có.

## Lệch quy tắc

Không.

## Xét chéo A

Đã đọc `diff_tables.py`, `export_tables.py`, `align_columns.py` và test của A. Đã chạy lại 106 cặp trên cây thật và vài ca giả trong `build/p1c-xet-a/`. Không sửa mã A.

106 cặp: id nguyên văn và id theo kiểu đều 354614 / 62374, 0 bảng gộp hai chữ thành một khoá, 0 id int không thuần, 0 ô đầu rỗng. Phần hiệu id không lệch mục 3. Lỗi ở dưới không nằm trong các tổng đó.

### X-CA-01 Tên cột gốc mất im lặng khi không ghép được id cột đầu

- Chỗ: `TOOLS/server/export_tables.py:588` `_aligned_links`, `TOOLS/server/align_columns.py:448` `align`.
- `_pair_rows` chỉ giữ dòng có id cột đầu trùng. Không trùng dòng nào thì trả hai tuple rỗng, không phải `None`. `align` thấy `rows_new` rỗng thì `_all_new`: mọi cột thành `mới ở 2026`, `legacy_name` rỗng. Không có dòng notice. Khác nhánh id đụng nhau, nhánh đó ghi `id bản đối chiếu không duy nhất`.

`AbilityExpTable.txt` và `tables/shared/life_skill_proficiency.tsv`, 20 dòng. Cột 0 bên 2026 là số thứ tự mới. Bỏ cột đó thì 20/20 dòng bằng nguyên dòng gốc, kể cả `铜矿脉` và `20003001`. Sáu tên bị xoá: `对象名称$1$`, `基础熟练度`, `对应技能等级`, `损耗比例`, `AbilityId`, `编号（对象的编号）`. Tệp cột để `original` rỗng.

`Mission_NpcDefault.txt` và `tables/shared/npc_default_dialogue.tsv`, 16 dòng. Dòng `#无量山` bị bỏ đúng kiểu chú thích. Cột 0 là 1, 2, 3. Phần còn lại bằng nguyên dòng gốc 16/16, từ `ScriptId` `1040000` tới năm cột đối thoại. Chín tên bị xoá. Tệp cột cũng `original` rỗng, note chỉ `mới ở 2026`.

```text
python -B -W error build\p1c-xet-a\chung.py
```

```text
AbilityExpTable.txt dòng 20 20
  client[1:] bằng nguyên dòng gốc 20
Mission_NpcDefault.txt dòng 16 16
  client[1:] bằng nguyên dòng gốc 16
=== align không có dòng đã ghép ===
['mới ở 2026', 'mới ở 2026'] ['', '']
```

`test_different_layout_names_anchors` vẫn dùng id 1..4 ở cả hai bên, nên cột hai đầu giữ `neo`. `test_layout_mismatch_keeps_default_names` chỉ một dòng. Không ca nào là cột id mới đứng đầu, nhiều dòng, phần còn lại khớp từng ô.

Không tính `life_skill_levels/material_processing.tsv`. Bảng đó một dòng, từng ô bằng `AbilityLevelUp/cailiaojiagong.txt`, nhưng test một dòng ở trên đang bắt `column_0` và `mới ở 2026`.

### X-CA-02 Hợp đồng mục 6: lỗi không đúng tệp:dòng, source không phải đường dẫn gốc

- Chỗ: `TOOLS/server/diff_tables.py:123` và `diff_tables.py:472`.
- Byte UTF-8 hỏng luôn báo dòng 1. `export_tables._decode_legacy` đếm `\n` tới byte hỏng; bản trong `diff_tables` bỏ bước đó. `test_diff_tables.py` không có byte `0xFF`.

Tệp `INT`, `ID`, `1`, rồi byte `0xFF` ở dòng 4:

```text
Pet.txt:1: byte UTF-8 hỏng
exit 1
```

Cột đầu `FLOAT`, ô `1e39`. `export_tables._float_bits` ném `số thực không vừa float32` không kèm tệp. `main` in nguyên câu đó. Trên 106 cặp không có cột đầu float, nên cây thật không đụng. Test của A không có ca này. `test_export_tables.py` có ca float tràn nhưng là cột không phải id, và bắt chữ `Odd.txt:`.

```text
số thực không vừa float32
exit 1
```

Bảng ghi ra cũng lệch dòng `source`. Hợp đồng mục 6: `# source: <cây>/<đường dẫn gốc>`; bảng gộp thì ghi mẫu tên và số tệp. Ca một cặp, ghi `--output`:

```text
# source: client_2026
```

và

```text
# source: docs/giao-viec/P1-DOT-3/DE-BAI.md/muc-5.3
```

Không có đường dẫn tệp gốc, không có số tệp. `test_write_sorts_first_missing_by_number_and_scene` chỉ tìm chuỗi `first_missing`, không đọc dòng source.

### X-CA-03 Test không bắt thư mục refs không tồn tại: thoát 0, mất hết dòng phủ

- Chỗ: `TOOLS/server/table_refs.py:157` `read_refs`. `directory.glob` trên đường dẫn không có thì ra rỗng, không lỗi.
- `--refs` trỏ vào `build\p1c-xet-a\hop\khong-co`, thư mục đó không được tạo. Thoát 0. Không có dòng `tệp:dòng:`.

```text
cặp: 1
ids_2026: 1
ids_legacy: 1
common: 1
only_2026: 0
only_legacy: 0
dòng tham chiếu: 0
dòng có giá trị thiếu: 0
exit 0
```

Mọi dòng `refs/` biến mất mà lệnh vẫn sạch. `test_check_rejects_parent_that_matches_no_file` tự `mkdir` thư mục refs trước, nên không thấy ca này. Đường mặc định `TOOLS/server/refs` đang có, T10 không đi qua nhánh này.

### X-CA-04 Khác kiểu thì bỏ dòng phủ; exe vẫn giữ một dòng

- Chỗ: `TOOLS/server/diff_tables.py:432`. `_type_error` có chữ thì `continue`, không đưa dòng vào `cover_rows`.
- Mục 5.3: mỗi dòng `refs/` một dòng trong `table_ref_coverage.tsv`. Con `pets.tsv` cột `id` kiểu `int`, cha `skills.tsv` cột `id` kiểu `text`, cùng ô `7`, `known_missing` 0.

```text
python -B -W error TOOLS\server\diff_tables.py build\p1c-xet-a\hop\tlbb build\p1c-xet-a\hop\server --names build\p1c-xet-a\hop\names.tsv --refs build\p1c-xet-a\hop\refs --check
```

```text
dòng tham chiếu: 0
refs/shared.tsv:4: hai cột khác kiểu
PY_EXIT:1
```

Cùng cây, `build\gcc-debug\thienlong_lint.exe --root build\p1c-xet-a\hop\server --refs build\p1c-xet-a\hop\refs --report build\p1c-xet-a\hop\cpp-coverage.tsv`:

```text
shared.tsv:4: cột con và cột cha khác kiểu
dòng tham chiếu: 1
lỗi: 1
CPP_EXIT:1
```

Báo cáo exe có một dòng dữ liệu `pets.tsv` / `id`. Python không ghi tệp và đếm 0. `test_diff_tables.py` không có hai cột khác kiểu. Cây thật không có cặp này nên T13 vẫn trùng byte.

## Trả lời xét chéo

### X-BC-01 NHẬN

`parse_tsv` bỏ mọi dòng bắt đầu bằng `#`. Sau dòng tên cột, dòng đó là bản ghi: lint vẫn thoát 0 và không tính vào `known_missing`. Không sửa `SRC/table`. `check_file` đọc lại văn bản, báo `ô đầu bắt đầu bằng #` đúng dòng, và gắn dòng đó vào bảng nếu đủ số cột.

Đỏ, trước khi sửa. Ca `hash_data_row` đã có trong `tests/content_tests.cpp`.

```text
cmake --build --preset gcc-debug --target content_tests
.\build\gcc-debug\content_tests.exe
```

Build thoát 0. Exe thoát -1073740791.

```text
./tests/content_tests.cpp:309: [hash_data_row] ô đầu bắt đầu bằng # không được thoát sạch
./tests/content_tests.cpp:310: [hash_data_row] dòng # vẫn là một bản ghi
./tests/content_tests.cpp:316: [hash_data_row] lỗi đúng tệp và đúng dòng của ô #
```

Xanh. Cùng hai lệnh, exe im, `CONTENT_EXIT:0`. Cây `SERVER`: 4015 tệp TSV, 0 dòng `#` sau tiêu đề, nên `server_data_lint` không đổi.

### X-BC-02 NHẬN

`remember_type` giữ kiểu tệp khớp đầu. Tệp sau khác kiểu vào `clashes`. Lúc chốt, kiểu `float` báo `cột tham chiếu là float` trên đúng tệp con; kiểu khác được so với cột cha.

Đỏ, cùng lần chạy ở X-BC-01:

```text
./tests/content_tests.cpp:331: [child_types_differ] hai tệp cùng mẫu khác kiểu phải lỗi
./tests/content_tests.cpp:332: [child_types_differ] có lỗi kiểu dù ô nguyên văn là 1
```

Ca là `scenes/a/spawns.tsv` kiểu `int`, `scenes/b/spawns.tsv` kiểu `float`, ô đều `1`, cha `monster_id` kiểu `int`.

Xanh. `content_tests` gcc-debug im, `CONTENT_EXIT:0`. `server_data_lint` vẫn thoát 0, nên cây thật không có hai tệp cùng mẫu mà khác kiểu.

### X-BC-03 NHẬN

Mảnh không phải định danh không còn thành `*`. `Mystery() .. ".ini"` và `"shuilao_monster_" .. Mystery() .. ".ini"` là `unresolved`, `files_on_disk` rỗng. `shuilao_monster_99.ini` là `unpointed`, không phải `map_unknown`.

Ngoại lệ đã đo: `tostring(tên)` vẫn là `*`. Bốn lời gọi thật dùng nó (`yamen_monster_*.ini`, `muxue_monster_*.ini`, `kaochang_monster_*.ini`, và bảng tên ở `ecity_0602military.lua`). Đổi chúng thành `unresolved` thì bỏ trỏ các tệp cấp mà script có nêu. `test_real_scripts_if_present` vẫn ra 863 / 80 / 221 / 180.

Đỏ:

```text
python -B -W error -m unittest TOOLS.server.test_scene_refs.SceneRefsTest.test_unreadable_call_stays_unresolved
```

```text
AssertionError: 'format' != 'unresolved'
- format
+ unresolved
```

Xanh. Cùng lệnh nằm trong lượt 8 test (thêm ca hoa thường, format cũ, và xuất cảnh), thoát 0. Rồi không đặt biến:

```text
python -B -W error -m unittest TOOLS.server.test_scene_refs TOOLS.server.test_export_scene
```

33 test, 2 bỏ qua. Có `THIENLONG_LEGACY_ROOT`:

```text
python -B -W error -m unittest TOOLS.server.test_scene_refs.RealScriptTest.test_real_scripts_if_present
```

Thoát 0, 24,8 giây.

### X-BC-04 NHẬN

`files_on_disk` so `casefold`. `_points_at` so `==`, nên `plain_monster_10.ini` đếm 1 mà dòng cấp là `unpointed`. Literal, constant và mẫu format giờ cùng so không phân biệt hoa thường. Luật mảnh dài dưới 8 ký tự của phán quyết cấp giữ nguyên.

Đỏ:

```text
python -B -W error -m unittest TOOLS.server.test_scene_refs.SceneRefsTest.test_level_file_case_matches_disk_count
```

```text
AssertionError: Tuples differ: (('Plain_monster_10.ini', 'plain', '', 'unpointed'),) != (('Plain_monster_10.ini', 'plain', 'plain', 'same'),)
```

Xanh. Ca này nằm trong lượt 8 test ở X-BC-03, thoát 0. Cây thật không lệch hoa thường: test mục đó vẫn 863 / 80 / 221 / 180.

### X-BC-05 NHẬN

`extension()` so đúng `.tsv`, nên `a.TSV` biến mất và thoát 0. `is_tsv_extension` hạ ASCII rồi so. Tệp được đọc, không thành lỗi nếu nội dung sạch.

Đỏ, exe cũ:

```text
.\build\gcc-debug\thienlong_lint.exe --root build\p1-b-xet-c\ext\server --refs build\p1-b-xet-c\ext\refs
```

```text
tệp: 1
bản ghi: 1
ô: 1
dòng tham chiếu: 0
lỗi: 0
EXIT:0
```

Xanh, exe sau sửa, cùng lệnh:

```text
tệp: 2
bản ghi: 2
ô: 2
dòng tham chiếu: 0
lỗi: 0
EXIT:0
```

`keep.tsv` và `a.TSV` đều vào số đếm. Ca `tsv_extension_case` nằm trong `content_tests`.

### X-BC-06 NHẬN

`_rewrite_row` ghi sẵn `:1:`. Mỗi bảng giờ giữ dòng nguồn của từng ô. Ô int vượt int32 báo dòng khoá trong tệp ini, không phải 1.

Đỏ:

```text
python -B -W error -m unittest TOOLS.server.test_export_scene.ExportSceneTest.test_int32_overflow_names_source_line
```

```text
AssertionError: 'spawns.tsv:27: số vượt int32' not found in 'demo/spawns.tsv:1: số vượt int32'
```

Xanh. Ca này nằm trong lượt 8 test ở X-BC-03, thoát 0. Lượt 33 test cũng thoát 0. Có `THIENLONG_LEGACY_ROOT`, `RealSceneTest.test_real_tree_if_present` thoát 0 trong 4,6 giây: 3251 tệp, `cells_rewritten` vẫn 266.

## Đã kiểm sau xét chéo

- Đỏ rồi xanh: `content_tests` gcc-debug như X-BC-01. Xanh im, `CONTENT_EXIT:0`.
- `ctest --preset gcc-debug -R "^(content_tests|server_data_lint)$" --output-on-failure`: 2/2, `server_data_lint` 8,41 giây.
- `cmake --build --preset clang-asan --target content_tests` rồi `.\build\clang-asan\content_tests.exe`: im, `ASAN_EXIT:0`.
- `python C:\Users\myhea\.claude\cpp23\tools\check.py SRC\content\lint.hpp SRC\content\lint.cpp SRC\linttool\main.cpp tests\content_tests.cpp`: `4 tệp, 0 lỗi.`
- `python -B -W error TOOLS\server\lint_py.py` trên `scene_refs.py`, `export_scene.py` và hai tệp test: thoát 0.
- Quét `SERVER/tables` và `SERVER/scenes`: 4015 tệp, 0 dòng `#` sau tiêu đề.

## Chưa kiểm sau xét chéo

Không dựng lại `msvc-release`. Sửa không đổi byte cây `SERVER` khi dữ liệu thật không có dòng `#`, không lệch hoa thường, và không có số vượt int32. `server_data_lint` gcc-debug đã đọc cây thật.

## Giả định

`tostring(tên)` là phần biến của mẫu, không phải lời gọi lạ. Bốn lời gọi thật và số 863 / 80 / 221 / 180 đứng trên giả định đó.

## Lệch quy tắc

Không.
