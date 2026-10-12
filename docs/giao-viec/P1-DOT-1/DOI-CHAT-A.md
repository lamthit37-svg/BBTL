# Đối chất vai A

## Trả lời review

### R-A-01 NHẬN

Một bảng lỗi vẫn ghi bảng còn lại và `prepare_directory` xoá bảng của lượt trước không được ghi lại. Đã sửa `TOOLS/server/export_tables.py`: có lỗi thì trả về trước khi `prepare_directory`, `written` rỗng, không đụng tệp cũ.

Test mới đỏ trước khi sửa, vì vẫn ghi `good.tsv` và `pets.tsv`:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py"
FAIL: test_one_error_writes_nothing_and_keeps_previous
AssertionError: Tuples differ: ('tables/shared/good.tsv',) != ()
FAIL: test_reject_bad_utf8_reference
AssertionError: Tuples differ: ('tables/shared/pets.tsv',) != ()
FAIL: test_reject_extra_legacy_cell
AssertionError: Tuples differ: ('tables/shared/pets.tsv',) != ()
Ran 22 tests in 0.051s
FAILED (failures=4, skipped=1)
```

Exit 1.

Sau khi sửa, cùng lệnh, exit 0:

```text
Ran 22 tests in 0.045s
OK (skipped=1)
```

`test_one_error_writes_nothing_and_keeps_previous` xuất sạch `also.tsv`, rồi bỏ `Also.txt` và thêm bảng có tab cùng một bảng sạch. Lượt sau thoát lỗi, byte `also.tsv` và tệp cột của nó không đổi, `good.tsv` và `bad.tsv` không được tạo. `test_reject_bad_utf8_reference` giữ `also.tsv` và không tạo `pets.tsv`. `test_reject_extra_legacy_cell` không tạo `pets.tsv`.

Không chạy lại xuất 635 bảng lên `SERVER/tables`. Lượt đó không có lỗi bảng, đường ghi khi sạch không đổi.

### R-A-02 NHẬN

`--check` in `bảng xuất: 0` vì đếm `len(written)`, mà `--check` không ghi. Đã tách `bảng sẽ ghi` và `bảng đã ghi`.

Test đỏ trước khi sửa:

```text
FAIL: test_check_names_tables_it_would_write
AssertionError: 'bảng sẽ ghi: 1' not found in '...bảng xuất: 0...'
```

Cùng lần `FAILED (failures=4, skipped=1)` ở trên. Exit 1.

Sau khi sửa, test đó nằm trong 22 test xanh, exit 0.

Dữ liệu thật, không tạo thư mục đích:

```text
python -W error TOOLS/server/export_tables.py "<_raw>" "<tlbb>" build/p1-a/tables-check --check
tệp: 1877
chưa phân loại: 0
client_only: 109
deferred: 1132
dropped: 1
table: 635
thư mục: 131
thư mục chưa phân loại: 0
bảng sẽ ghi: 635
bảng đã ghi: 0
bản ghi: 994925
cột: 17247
cột có tên: 148
cột còn ?: 504
cột chữ toàn số: 33
thời gian: 2.0 giây
```

Exit 0. `build/p1-a/tables-check` không được tạo.

## Xét chéo B

### X-AB-01 Dòng Script.dat bị bỏ không được đếm

`Public/Data/Script.dat` có 476 dòng chú thích bắt đầu bằng `;` và một dòng `帮会同盟` (dòng 3586 sau khi bỏ khối `;`). `CFileDataMgr::Init` cũng không nạp chúng. `import_legacy._load_mgr` bỏ luôn và không cộng bộ đếm nào.

```text
python -W error -c "... _load_mgr(Script.dat) ..."
4307
{'int_cells': 1079, 'slash_cells': 4307}
```

`script_index.tsv` có 4307 dòng và không chứa `帮会同盟`. `CHANGE_LABELS` không có mục cho dòng script bị bỏ. `test_real_tree` chỉ so số dòng với số dòng gốc bắt đầu bằng chữ số và có `=`, nên ca này không làm test đỏ. Test đó hiện đỏ trước đó vì `Script.dat:1: không có bộ đọc` (dòng `public_data` mới trong `table_names.tsv`, `_kind` không nhận `.dat`).

### X-AB-02 Cột STRING toàn là số thập phân không được liệt kê

Hợp đồng mục 6: cột khai STRING mà mọi ô là số thì liệt kê, không đổi kiểu. `StandardImpact.txt` cột 29 khai `STRING`. Cả 9860 ô của `effects.tsv` cột `column_29` đều là số, trong đó 51 giá trị có dấu chấm, ví dụ `-0.083333333`, `-7.5`, `0.1`. Kiểu TSV vẫn là `text`.

```text
python -W error build/p1-a/probe_b12.py
source_type_29 'STRING'
all_numeric True n 9860
decimals ['-0.083333333', '-12.69968', '-19.04952', '-6.34984', '-7.5', '-80.64093605'] count 51
SUMMARY effects.tsv: ... cột text toàn số: column_28, column_31, column_34, ...
```

`column_29` không có trong danh sách. `_numeric_text` chỉ nhận `^[+-]?\d+$`, nên số có phần thập phân bị sót. Cùng kiểu còn `column_32`, `column_35`, `column_38`, `column_41`, `column_44`, `column_47`, `column_50`, `column_65`, `column_68`. Test của B không kiểm danh sách này.

### X-AB-03 Kiểu trống ở giữa làm cả bảng bị từ chối

`OpenFromMemoryImpl_Text` tách dòng kiểu với `bIgnoreEmpty = TRUE`, nên token rỗng bị bỏ và tệp vẫn nạp. Dòng dữ liệu giữ ô rỗng. Với `INT\t\tSTRING` và dòng `1\t2\thello`, máy chủ thấy hai cột: int `1`, chuỗi `2`. Ô `hello` không được đọc.

`import_legacy` báo lỗi và không ghi:

```text
python -W error build/p1-a/probe_b10.py
middle_empty_errors ['Server/Config/shift.txt:1: ô kiểu rỗng xen giữa']
middle_empty_wrote False
```

`test_keep_value_under_blank_type` chỉ có kiểu trống ở đuôi (`INT\tINT\t`), không có kiểu trống xen giữa. Trên đĩa 0859602 không thấy kiểu trống xen giữa; chỉ có đuôi trống ở `ItemSegValue.txt`, `ItemSegRate.txt`, `CreateQualityOfVaryPetTbl.txt`.

## Trả lời xét chéo

### X-CA-01 NHẬN

Dòng id rỗng của bản chữ bị bỏ và không được đếm. Bộ đọc gốc cũng bỏ dòng ô đầu rỗng, nên dòng đó không vào mẫu số phần trăm. Đã cộng vào thông báo.

Đỏ trước khi sửa:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py"
FAIL: test_empty_legacy_id_is_counted
AssertionError: False is not true
```

`result.notices` không có chữ `ô đầu rỗng`.

Xanh sau khi sửa, cùng lệnh, exit 0:

```text
Ran 25 tests in 0.055s
OK (skipped=1)
```

`test_empty_legacy_id_is_counted` vẫn ghi `khớp 100.0% (2/2 id)` và thông báo có `ô đầu rỗng`. Giá trị 999 không vào phần trăm.

### X-CA-02 NHẬN

`1e308` làm `struct.pack("<f", ...)` ném `OverflowError`, không thành dòng `tệp:dòng:`. Đỏ:

```text
ERROR: test_legacy_float_overflow_is_an_error_line
OverflowError: float too large to pack with f format
```

Cùng lần `FAILED (failures=2, errors=1, skipped=1)`, exit 1.

Đã bắt `OverflowError` và trả `Odd.txt:<dòng>: số thực không vừa float32`. Có lỗi thì không ghi, theo R-A-01. Test xanh nằm trong 25 test ở trên, exit 0: lỗi có `Odd.txt:` và `float32`, `odd.tsv` không được tạo.

### X-CA-03 NHẬN

Id int của bản chữ đi qua `atoi`, nên `1.0` là id 1. Khớp thuần `[+-]?\d+` bỏ dòng này và ghi `không có id chung`. Đỏ:

```text
FAIL: test_fractional_legacy_id_still_pairs
AssertionError: 'không có id chung' unexpectedly found in 'không có id chung'
```

Đã ghép bằng `atoi` và đếm id không phải số nguyên thuần. Hai cột ghi `khớp 100.0% (1/1 id)`. Test xanh trong cùng 25 test, exit 0.

`--check` trên dữ liệu thật sau sửa, exit 0, không thông báo id mới, `bảng sẽ ghi: 635`, `bảng đã ghi: 0`.
