# Đối chất vai A

## Trả lời review

### R-A-01 NHẬN

Nội suy giữa hai neo đang gán tên cột gốc cho cột mà cả hai bên có từ 3 giá trị và khớp dưới 95%. `ShopTable.txt` cột 258 vì thế nhận `PID(商品编号42)` dù chỉ khớp 12/172.

Đã sửa `TOOLS/server/align_columns.py`: cặp như vậy không được ghép, cột 2026 là `mới ở 2026`, cột gốc tương ứng ghi mất. Cột ít thông tin vẫn nội suy. Test mới đỏ trước khi sửa:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_align_columns.py" -k varied_column
FAIL: test_varied_column_between_anchors_stays_new
AssertionError: Lists differ: ['neo', 'interpolated', 'neo'] != ['neo', 'new', 'neo']
First differing element 1:
'interpolated'
'new'
Ran 1 test in 0.001s
FAILED (failures=1)
```

Exit 1.

Sau khi sửa, cùng bộ test, exit 0:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_align_columns.py"
Ran 11 tests in 0.002s
OK
```

`pha.py` trên ca nhiều giá trị khớp 0%:

```text
python -W error docs/giao-viec/P1-DOT-2/kiem/pha.py
## căn cột: giữa hai neo, cột nhiều giá trị khớp 0%
loại ['neo', 'new', 'neo']
cột giữa mới ở 2026 tên gốc ''
```

Xuất lại cây thật, exit 0, 137,5 giây. Bản ghi vẫn 994925. `columns/shared/shops.tsv` cột 258:

```text
258	column_258	int	mới ở 2026
```

Không còn `PID(商品编号42)`. `can_cot.py` đo lại mọi nội suy dưới 95%:

```text
python -W error docs/giao-viec/P1-DOT-2/kiem/can_cot.py
nội suy ghi dưới 95%: 62; trong đó cả hai bên từ 3 giá trị và đo dưới 95%: 0
```

62 cột còn lại có ít nhất một bên dưới 3 giá trị. So 635 tệp dữ liệu với bản xuất `build/p1-a/real-export` trước lần sửa này: lệch ô dữ liệu 0.

### R-A-02 NHẬN

Đổi hai dòng trong `TOOLS/server/column_terms.tsv`, không thêm và không bớt dòng.

Dòng 49, `引导` là dẫn chiêu, không dùng `charge`:

```text
连续攻击次数或引导的时间间隔(ms)	consecutive_hits_or_channel_interval_ms	direct	nhãn: số lần đánh liên tiếp hoặc khoảng dẫn chiêu, mili giây
```

Dòng 96, basis là mã nên tên theo `m_DropSearchRange`:

```text
掉落分配半径(米)	drop_search_range_m	code:Server/GameServer/Server/Main/GameTable.cpp:390	đọc vào m_DropSearchRange
```

`python -W error -m unittest discover -s TOOLS/server -p "test_align_columns.py"` ở trên đọc lại tệp này và thoát 0.

## Xét chéo B

### X-AB-01 Dòng trong section ini biến mất, bộ đếm trống

Chỗ: `TOOLS/server/import_legacy.py`, `_parse_ini`, nhánh `raw is None or key.strip() == ""` rồi `continue`. `CHANGE_LABELS` không có khóa cho lần bỏ này.

Trên ini thật, nhánh đó nhận dòng trống và dòng chú thích. `python -W error build/p1-a/xet_b15.py` đếm, sau khi đã vào section:

```text
Server/Config/SceneInfo.ini: trống 924, chú thích 0, khác 0
Server/Config/SystemInfo.ini: trống 53, chú thích 47, khác 0
Server/Config/BaseValueTable.ini: trống 9, chú thích 9, khác 0
Server/Config/GuildMemberAccess.ini: trống 6, chú thích 0, khác 0
Public/Config/MonsterAITable.ini: trống 33, chú thích 0, khác 0
```

Mười lăm tệp `Public/Config/RandShop/*.ini` cùng lệnh đều `khác 0`. Một tệp có chú thích: `xunluozawu.ini` chú thích 1.

Cùng nhánh nuốt một dòng có giá trị. Tệp dựng `build/p1-a/mat-ini/SceneInfo.ini` có `PvpRuler 7` (dấu cách, không có `=`). `_parse_scene` vẫn trả bảng. Ô `PvpRuler` là chuỗi rỗng. `changes` là `{}`:

```text
dòng PvpRuler 7: bản ghi ('0', '0', 'a', 'a.scn', '0', '', '', '', '', '', '1')
changes {}
```

`test_unknown_ini_key` chỉ đưa `weird=1`, tức dòng có dấu `=`. Ca không có dấu `=` không nằm trong `test_import_legacy.py`.

### X-AB-02 Cột token kiểu trống bị ghi kiểu text

Chỗ: `TOOLS/server/import_legacy.py`, `_extend_blank_types` gắn `"text"`. Đầu ra: `SERVER/tables/server/item_segment_values.tsv` dòng `# types:`, và `TOOLS/server/columns/server/item_segment_values.tsv` dòng 71 (chỉ số 65): `column_65`, kiểu `text`, chú thích `? kiểu trống, bộ đọc gốc bỏ cột này`.

Mục 6 của đề bài đợt 1: kiểu cột theo khai báo của tệp gốc, không đoán lại kiểu. Dòng kiểu của `Server/Config/ItemSegValue.txt` có token rỗng từ cột 65. Cùng lệnh `xet_b15.py`:

```text
ItemSegValue token 129 token[65] '' types[65] text
số cột text từ 65 64 trên 129
dòng gốc 272 cột 65-67 ['15051', '50', '-1']
```

`python -W error build/p1-a/xet_b10.py` đối chiếu 64 ô khác rỗng ở các cột token trống với bảng đã ghi: cả 64 ô đều có mặt, `kept_blank_type` 64. Mẫu dòng gốc 272 là `15051`, `50`, `-1` tại cột 65, 66, 67. `OpenFromMemoryImpl_Text` gọi `_ConvertStringToVector` cho dòng kiểu với `bIgnoreEmpty` TRUE (`Common/DataBase/TLBB_DBC.cpp:243`), nên token rỗng không phải khai báo `STRING`.

`test_keep_value_under_blank_type` đòi `table.types == ("int", "int", "text")` khi token thứ ba rỗng. Bộ test giữ cách gán `text`.

### X-AB-03 Mảng luật khuyết chỉ số bị dồn slot

Chỗ: `TOOLS/server/import_rules.py`, `_one_literal`. Các dòng có `index` được sort rồi nối thành một mảng. Hàm không đòi dãy `0..n-1` liền nhau. `_check_row` chỉ kiểm `index` là chữ số.

`_array_rows` trong `test_import_rules.py` dùng `id0` index `0` và `id1` index `1`, kỳ vọng `id = [3, 4]`. Không có ca khuyết chỉ số.

Ca dựng `build/p1-a/mat-rules`: `id0=3` index 0, `id2=9` index 2, không có index 1. `export_rules` thoát sạch và ghi:

```text
lỗi []
tóm tắt ['luật: 2', 'tiến trình: 0', 'bỏ: 0', 'chưa rõ: 0', 'lệch tiến trình: 0', 'đã ghi: instances.toml']
toml id = [3, 9]   # Số hiệu.
```

Giá trị 9 của index 2 nằm ở slot 1. Trên `legacy_rules.tsv` hiện tại, các nhóm `fate=rule` là `0..n-1`. Lỗi nằm ở chỗ khuyết chỉ số mà test không đưa vào.

## Trả lời xét chéo

### X-CA-01 NHẬN

`1` và `01` cùng ra số 1. Bố cục khác trả bảng dòng rỗng và ghi mọi cột `mới ở 2026`, không có notice.

Đỏ trước khi sửa:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py" -k padded_legacy_id_is_reported -k help_is_vietnamese -k missing_arguments_exit_one
FAIL: test_padded_legacy_id_is_reported
AssertionError: False is not true
```

Dòng assert là `any("01" in note for note in result.notices)`.

Đã sửa `TOOLS/server/export_tables.py`: id chữ khác nhau mà cùng khóa thì không căn. Note cột là `id bản đối chiếu không duy nhất`. Notice ghi cả hai chữ. Báo cáo căn không nhận một dòng “mọi cột mới”.

Xanh, exit 0:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py"
Ran 32 tests in 0.074s
OK (skipped=1)
```

Ca `1` / `01`:

```text
python -W error build/p1-a/xet_ca01.py
errors ()
notices ('Pet.txt:1: id bản đối chiếu không duy nhất: 1=1 và 01=1',)
align 0
note0 id bản đối chiếu không duy nhất
note1 id bản đối chiếu không duy nhất
note2 id bản đối chiếu không duy nhất
```

`python -W error TOOLS/server/lint_py.py TOOLS/server/export_tables.py TOOLS/server/test_export_tables.py` thoát 0, không in dòng. Cây `columns/shared` và `SERVER/tables` không xuất lại: ca này không có trên 76 bảng đang căn.

### X-CA-02 NHẬN

Thiếu đối số làm argparse thoát 2, dòng lỗi tiếng Anh. `--help` còn `usage:`, `positional arguments:`, `show this help message and exit`.

Đỏ trước khi sửa, cùng lệnh unittest ở X-CA-01:

```text
ERROR: test_missing_arguments_exit_one
SystemExit: 2
FAIL: test_help_is_vietnamese
AssertionError: 'usage:' unexpectedly found in 'usage: export_tables.py ...'
```

Đã bỏ argparse. Thiếu đối số in một dòng `tệp:dòng:` và thoát 1. `--help` là tiếng Việt, có chữ “không ghi”.

```text
python -W error TOOLS/server/export_tables.py
export_tables.py:1: cần thư mục _raw, tlbb và thư mục bảng
```

Exit code của lệnh đó là 1.

```text
python -W error TOOLS/server/export_tables.py --help
cách dùng: python TOOLS/server/export_tables.py <_raw> <tlbb> <thư mục bảng> [--check]
[--names <tsv>] [--columns <thư mục>] [--alignment <tsv>]

Xuất DBC của client 2026 thành TSV. --check kiểm hết và không ghi tệp nào.
Thoát 0 khi sạch, 1 khi có lỗi. Mỗi lỗi một dòng tệp:dòng: nội dung.
```

Exit code 0. Ba test mới nằm trong lần `32 tests` ở trên.

### X-CA-03 BÁC

Hợp đồng mục A của đợt 2: neo cần cùng kiểu, khớp ít nhất 95%, và từ 3 giá trị khác nhau. Cột hằng hoặc gần hằng không tự làm neo; nó được nội suy khi nằm giữa hai neo liền kề và hai khe cùng số cột. `_varied_low_match` chỉ chặn khi cả hai bên có từ 3 giá trị và khớp dưới 95%. Đó là sửa R-A-01.

`TOOLS/server/columns/shared/shops.tsv` dòng chỉ số 270:

```text
270	PID(商品编号44)	column_270	int	nội suy: cột gốc 283, khớp 7.0% (12/172 id); ? chưa có tên tiếng Anh
```

```text
python -W error build/p1-a/xet_ca03.py
index 270 original PID(商品编号44)
note nội suy: cột gốc 283, khớp 7.0% (12/172 id); ? chưa có tên tiếng Anh
left 2 right 10 legacy 283
atoi abc 0
errors ()
notices ('Pet.txt:1: đối chiếu 1 id không phải số nguyên thuần',)
note khớp 100.0% (4/4 id)
```

Bản 2026 của cột 270 có 2 giá trị, dưới ngưỡng neo. Note ghi 7,0%. `test_two_distinct_values_are_not_anchors` giữ cột 2 giá trị ngoài neo. `test_constant_between_anchors_is_interpolated` giữ nội suy cột hằng giữa hai neo.

Id `abc` trên cột INT đi qua atoi thành 0, đúng bộ đọc bảng chữ. Lệnh in notice `đối chiếu 1 id không phải số nguyên thuần`. Note 100% là so sau atoi, trên 4 id đã ghép.
