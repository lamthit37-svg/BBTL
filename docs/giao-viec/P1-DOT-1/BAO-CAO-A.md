# Báo cáo vai A

## 1. Tệp đã tạo

- `TOOLS/server/table_census.py`: kê mọi tệp `_raw/Config`, ghi một dòng cho mỗi bảng DBC.
- `TOOLS/server/export_tables.py`: xuất bảng `fate=table` của client 2026 ra TSV và tệp cột.
- `TOOLS/server/test_table_census.py`, `TOOLS/server/test_export_tables.py`: test `unittest`.
- `TOOLS/server/table_census.tsv`: 745 dòng, một dòng một tệp `.txt`.
- `TOOLS/server/columns/shared/`: 635 tệp cột. Biến thể nằm ở `columns/shared/variants/<khoá>/`.
- `SERVER/tables/shared/`: 574 bảng. `SERVER/tables/variants/`: 61 bảng.

## 2. Đã kiểm

Lệnh đỏ, chạy khi hai mô-đun còn trả kết quả rỗng, trước khi có test dữ liệu thật. Exit 1.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_table_census.py"
Ran 10 tests in 0.010s
FAILED (failures=9, errors=1)
```

Ca đúng lý do, không phải lỗi import: `test_counts_types_and_hash` báo `AssertionError: 0 != 1`; `test_bad_magic` báo `AssertionError: False is not true` vì chưa có chữ `sai magic`; `test_write_is_deterministic` báo `FileNotFoundError` vì chưa ghi `census.tsv`.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py"
Ran 20 tests in 0.022s
FAILED (failures=14, errors=5)
```

`test_ascii_snake_and_glossary` báo `(None, False) != ('id', False)`. `test_reject_duplicate_id` không thấy chữ `trùng`. `test_roundtrip_int_float_text` không thấy tệp TSV.

Lệnh xanh, không đặt hai biến môi trường, trên mã cuối. Exit 0. Một test dữ liệu thật mỗi tệp bị bỏ qua.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_table_census.py"
Ran 11 tests in 0.015s
OK (skipped=1)

python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py"
Ran 21 tests in 0.043s
OK (skipped=1)
```

Lý do bỏ qua in ra: `thiếu THIENLONG_RAW_ROOT hoặc THIENLONG_LEGACY_ROOT`.

Có đủ hai biến, cùng hai lệnh discover. Exit 0.

```text
Ran 11 tests in 0.841s
OK

Ran 21 tests in 45.081s
OK
```

Test xuất thật gọi `python -W error TOOLS/server/export_tables.py <_raw> <tlbb> SERVER/tables`, rồi đọc lại 635 TSV bằng `tsv_file.read_table` và so từng ô với `TOOLS/content/dbc.py`. Không ô nào lệch. Kê bảng trong lần unittest đó chạy trước khi đổi dòng in `đã ghi` (bỏ đường dẫn tuyệt đối). Lệnh CLI chạy lại sau đó, exit 0, nội dung `table_census.tsv` không đổi:

```text
python -W error TOOLS/server/table_census.py "F:\tl 2026\_raw"
tệp: 1877
chưa phân loại: 0
client_only: 109
deferred: 1132
dropped: 1
table: 635
bảng: 745
bản ghi: 1198441
thư mục: 131
thư mục chưa phân loại: 0
đã ghi table_census.tsv
thời gian: 0.8 giây
```

Stdout của lần xuất thật, 23,1 giây, exit 0:

```text
tệp: 1877
chưa phân loại: 0
client_only: 109
deferred: 1132
dropped: 1
table: 635
thư mục: 131
thư mục chưa phân loại: 0
bảng xuất: 635
bản ghi: 994925
cột: 17247
cột có tên: 148
cột còn ?: 504
cột chữ toàn số: 33
cột chữ toàn số: CardRule.txt	6	column_6
cột chữ toàn số: CardRule.txt	7	column_7
cột chữ toàn số: CardRule.txt	8	column_8
cột chữ toàn số: CardRule.txt	9	column_9
cột chữ toàn số: CardRule.txt	10	column_10
cột chữ toàn số: EquipBase.txt	12	column_12
cột chữ toàn số: EquipBase_TM.txt	12	column_12
cột chữ toàn số: EquipBase_TM9.txt	12	column_12
cột chữ toàn số: InfantDressColorRate.txt	27	column_27
cột chữ toàn số: InfantDressColorRate.txt	30	column_30
cột chữ toàn số: MilitaryDetails.txt	5	column_5
cột chữ toàn số: MilitaryDetails.txt	6	column_6
cột chữ toàn số: MilitaryDetails.txt	7	column_7
cột chữ toàn số: MilitaryEffect.txt	6	column_6
cột chữ toàn số: MilitaryEffect.txt	7	column_7
cột chữ toàn số: MilitaryEffect.txt	8	column_8
cột chữ toàn số: PetEquipSetAttr.txt	7	column_7
cột chữ toàn số: PetEquipSetAttr.txt	10	column_10
cột chữ toàn số: PetEquipSetAttr.txt	13	column_13
cột chữ toàn số: PetEquipSetAttr.txt	16	column_16
cột chữ toàn số: PlayerExpLevel.txt	1	exp
cột chữ toàn số: SpringFestivalBiddingBonus.txt	39	column_39
cột chữ toàn số: SpringFestivalBiddingBonus.txt	45	column_45
cột chữ toàn số: SpringFestivalBiddingBonus.txt	51	column_51
cột chữ toàn số: SpringFestivalBiddingBonus.txt	57	column_57
cột chữ toàn số: SpringFestivalBiddingBonus_KaJi_1.txt	33	column_33
cột chữ toàn số: SpringFestivalBiddingBonus_KaJi_1.txt	39	column_39
cột chữ toàn số: SpringFestivalBiddingBonus_KaJi_1.txt	45	column_45
cột chữ toàn số: SpringFestivalBiddingBonus_KaJi_1.txt	51	column_51
cột chữ toàn số: SpringFestivalBiddingBonus_KaJi_1.txt	57	column_57
cột chữ toàn số: XunzhangInfo.txt	12	column_12
cột chữ toàn số: XunzhangInfo.txt	16	column_16
cột chữ toàn số: ZM_CharTitle.txt	21	column_21
thời gian: 23.1 giây
```

33 cột khai `STRING` mà mọi ô là số thập phân. Kiểu trong TSV vẫn là `text`.

## 3. Số đo

Nguồn `_raw/Config`, đối chiếu `table_names.tsv`: 1.877 tệp, khớp từng đường dẫn, không tệp thừa, không tệp thiếu. 131 thư mục, không thư mục trống.

- `.lua`: 1.130, `deferred`.
- `.dat`: 2 (`Script.dat`, `AIScript.dat`), `deferred`.
- `.txt` DBC: 745. Trong đó `table` 635, `client_only` 109, `dropped` 1 (`AbilityLevelUp/XinFaStudySpend_V1.txt`).
- Gốc `Config`: 722 tệp, đúng số phụ lục (718 `.txt` cộng 4 tệp không phải bảng). Thêm `AbilityLevelUp` 24, `obj` 22, `ActionSet` 3, `event` 1.106.

Xuất 635 bảng, 994.925 bản ghi, 17.247 cột. 574 bảng ở `shared`, 61 bảng ở `variants`. Không đích trùng.

Tên cột: 148 cột có tên tiếng Anh và không có `?`. 504 cột có `?`: 253 ghi `? chưa có tên tiếng Anh`, 251 ghi `? trùng tên` (cột sau của một tên lặp, giữ `column_<chỉ số>`, tên gốc vẫn ở cột `original`). 16.595 cột để `column_<chỉ số>` không có `?`: 4.517 vì bản 0859602 khác bố cục, còn lại không có tệp cùng tên. 30 bảng có cùng số cột và cùng dãy kiểu nên mới lấy tên. Không cột nào dính `thuật ngữ chưa chốt`. Không bản đối chiếu nào bị từ chối vì UTF-8, BOM hay dòng thừa ô.

`StrDictionary.txt` (`client_only`, không xuất) có 46 dòng trùng giá trị 4 byte của cột 0, trên 154.965 dòng. Không bảng xuất nào trùng id cột 0. Không ô DBC nào chứa tab, CR, LF. Không float NaN hay vô cực. Không tệp DBC cụt, sai magic, hay thừa byte.

So với byte DBC, bản ghi xuất ra không bỏ dòng và không đổi ô: int32 thành thập phân có dấu, float32 thành chuỗi `format_float32`, chuỗi GB18030 thành Unicode. Phần trăm trong tệp cột chỉ tính các id có ở cả hai bản. Ví dụ `Ability.txt` có 66 dòng nhưng chỉ 51 id chung, nên ghi `khớp 100.0% (51/51 id)`.

Trên 107 tệp chữ cùng tên ở `Public/Config`, đo riêng trước khi xuất: `EquipBase.txt` 8 dòng thừa ô, `ImpactSEData_V1.txt` 1 dòng thừa ô, `Mission_NpcDefault.txt` 4 dòng thiếu ô, 16 tệp có dòng `#`. Cả bốn nhóm này đều khác bố cục DBC nên công cụ không lấy tên và không đưa các dòng đó vào lỗi. 30 bảng được lấy tên không có các ca đó.

## 4. Chưa kiểm

Chưa đọc TSV bằng `game::table::parse_tsv`. Đã đọc bằng `tsv_file.read_table`, cùng hợp đồng dòng `#` và tab. Chưa chạy bộ đọc C++.

Chưa so từng ô bản chữ 0859602 với TSV ngoài phần trăm đã ghi trong tệp cột của 30 bảng khớp bố cục.

Chưa phát hiện tab trong ô trên dữ liệu thật, nên ca từ chối tab chỉ mới chạy trên DBC giả.

## 5. Giả định

Id là 4 byte cột 0, cùng `CreateIndex` của mã 2008, không phải nội dung chuỗi. Hai offset khác nhau nhưng cùng chữ không bị coi là trùng.

Ô "bằng nhau" khi so id chung: int so giá trị, float so đúng 32 bit sau khi đọc cả ô, chuỗi so Unicode. Không so nguyên văn `1` với `1.0` cho số nguyên. Mẫu số là số id có ở cả hai bên, không phải số dòng của DBC.

`mission` và `task` giữ nguyên, không đổi thành `quest`, vì phụ lục nói bảng 2026 chưa đổi cột thì giữ mission. `任务` vì vậy cũng không được đặt tên.

Tên ASCII đưa về snake_case bằng cách tách camelCase. Hậu tố `$<số>$` chỉ bỏ khi thử dịch; cột `original` giữ nguyên cả hậu tố. Tên lặp trong một bảng (như nhiều cột `ItemIndex`) chỉ cột đầu giữ tên dịch; cột sau là `column_<chỉ số>` và `? trùng tên`.

Thư mục được coi là đã phân loại khi không trống và mọi tệp bên trong có trong `table_names.tsv`. Không có dòng fate riêng cho thư mục.

## 6. Lệch quy tắc

Ba cờ không có trong dòng lệnh mẫu, để test không ghi đè cây thật: `--names`, `--output` (kê bảng), `--columns` (thư mục tệp cột). Lệnh không cờ vẫn ghi đúng đích đã chốt.

Tệp cột của biến thể ghi ở `TOOLS/server/columns/shared/variants/<khoá>/`, vì hợp đồng chỉ có `columns/shared/` trong khi nhiều biến thể cùng tên tệp.

`collect` của bên xuất gọi `table_census._coverage` và `tsv_file._owned_tool`. Hợp đồng chưa có hàm công khai để hỏi "tệp này của công cụ nào" trước khi `prepare_directory`. Cần hàm đó: kiểm ba thư mục (`shared`, `variants`, `columns/shared`) thấy tệp lạ thì dừng, chưa xoá thư mục nào. Yêu cầu L thêm hàm public, không tự sửa `tsv_file.py`.

## 7. Chỗ tài liệu mâu thuẫn với đĩa

`docs/KE-HOACH-SERVER.md` mục 9 nói `table_census.py` báo cáo 718 bảng. Đĩa có 745 tệp `.txt` DBC: 718 ở gốc `Config` (gồm 109 bảng `client_only`) cộng 24 `AbilityLevelUp` và 3 `ActionSet`. Phụ lục đã tách 718 là tệp gốc. Kê bảng ghi cả 745. Không sửa tài liệu.
