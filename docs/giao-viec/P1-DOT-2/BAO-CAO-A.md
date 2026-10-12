# Báo cáo vai A

## 1. Tệp đã tạo hoặc sửa

- `TOOLS/server/align_columns.py`: căn cột 2026 với bản 0859602, giữ thứ tự.
- `TOOLS/server/test_align_columns.py`: test căn cột và hình dạng `column_terms.tsv`.
- `TOOLS/server/column_terms.tsv`: 270 thuật ngữ soạn tay cho mười một bảng ưu tiên.
- `TOOLS/server/column_alignment.tsv`: 76 cặp bố cục khác, do `export_tables.py` ghi.
- `TOOLS/server/export_tables.py`: dùng phép căn khi bố cục khác; đánh số tên lặp; biến thể lấy tên bảng gốc khi cùng dãy kiểu.
- `TOOLS/server/test_export_tables.py`, `TOOLS/server/test_table_census.py`: test ghi vào `build/`, bắt stdout và stderr.
- `SERVER/tables/shared`, `SERVER/tables/variants`, `TOOLS/server/columns/shared`: xuất lại. Ô dữ liệu không đổi; dòng tên cột đổi.

Không sửa `tsv_file.py`, `table_census.py`, tệp của B và C, `SERVER/tables/server`.

## 2. Đã kiểm

Đỏ, trước khi có `align_columns.py`. Exit 1.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_align_columns.py"
ModuleNotFoundError: No module named 'align_columns'
Ran 1 test in 0.000s
FAILED (errors=1)
```

Đỏ tiếp, khi bản khác bố cục còn coi dòng thừa ô là lỗi cả lượt. Exit 1. Hai dòng chặn ghi:

```text
EquipBase.txt:732: dòng thừa ô
ImpactSEData_V1.txt:765: dòng thừa ô
```

Sau khi bản khác bố cục chỉ cắt ô thừa và ghi chú, cùng test thoát 0.

Xanh, không đặt hai biến môi trường. Exit 0.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_align_columns.py"
Ran 10 tests in 0.002s
OK

python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py"
Ran 29 tests in 0.073s
OK (skipped=1)

python -W error -m unittest discover -s TOOLS/server -p "test_table_census.py"
Ran 11 tests in 0.013s
OK (skipped=1)
```

Có đủ hai biến, test xuất thật ghi vào `build/p1-a/real-export`, không ghi `SERVER/tables`. Exit 0. Output của unittest chỉ còn dấu chấm và `OK`.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_tables.py" -k real_tables
Ran 1 test in 257.758s
OK
```

`test_table_census.py` với hai biến, đích `build/p1-a/real-census/table_census.tsv`. Exit 0.

```text
Ran 11 tests in 0.837s
OK
```

`python -W error TOOLS/server/lint_py.py` trên sáu tệp `.py` của A. Exit 0, không in lỗi.

Lệnh xuất cây thật, exit 0, 239,6 giây:

```text
python -W error TOOLS/server/export_tables.py "<_raw>" "<tlbb>" SERVER/tables
tệp: 1877
chưa phân loại: 0
client_only: 109
deferred: 1132
dropped: 1
table: 635
thư mục: 131
thư mục chưa phân loại: 0
bảng sẽ ghi: 635
bảng đã ghi: 635
bản ghi: 994925
cột: 17247
cột có tên: 764
cột còn ?: 2138
cặp căn: 76
cột chữ toàn số: 33
thời gian: 239.6 giây
```

So ô dữ liệu của `build/p1-a/real-export/tables` với `SERVER/tables` sau lệnh đó: `shared` 574 tệp, `variants` 61 tệp, lệch dữ liệu 0. Lệch chỉ nằm ở dòng tên cột và tệp cột.

## 3. Số đo

635 bảng, 994.925 bản ghi, 17.247 cột. 574 ở `shared`, 61 ở `variants`.

Tên cột: 764 cột có tên và không có `?`. 2.138 cột còn `?`, gần hết là nhãn tiếng Trung của bảng không thuộc mười một bảng ưu tiên: những bảng đó chỉ nhận tên ASCII do máy đổi. Đợt 1 có 148 tên và 504 dấu `?` vì bố cục khác chưa được căn và tên lặp bị đổi thành `column_<chỉ số>`.

76 cặp khác bố cục có một dòng trong `column_alignment.tsv`. Cộng dồn: neo 945 (gồm 10 cặp `chéo`), nội suy 902, đổi kiểu 173, mới ở 2026 là 2.497, mất 1.137. `PlayerExpLevel.txt` cùng bố cục nên không có dòng; hai cột là `level` và `exp`.

`column_terms.tsv`: 270 dòng. `glossary` 1, `code` 70, `direct` 199.

Mười một bảng. Cột `neo` trong bảng này là số `anchors` của tệp, gồm cả `chéo`.

| Bảng | Cột 2026 | Cột cũ | Neo | Nội suy | Đổi kiểu | Mới | Mất |
|---|---|---|---|---|---|---|---|
| AttackTraits.txt | 10 | 9 | 9 | 0 | 0 | 1 | 0 |
| Bullet.txt | 16 | 15 | 9 | 1 | 0 | 6 | 5 |
| CommonItem.txt | 28 | 26 | 20 | 2 | 0 | 6 | 4 |
| ImpactSEData_V1.txt | 28 | 17 | 12 | 4 | 0 | 12 | 1 |
| MonsterAttrExTable.txt | 73 | 70 | 22 | 28 | 15 | 8 | 5 |
| PlayerExpLevel.txt | 2 | 2 | cùng bố cục |  |  |  |  |
| SceneAttr.txt | 26 | 23 | 14 | 1 | 0 | 11 | 8 |
| SkillData_V1.txt | 54 | 48 | 20 | 9 | 7 | 18 | 12 |
| SkillTemplate_V1.txt | 102 | 79 | 56 | 9 | 0 | 37 | 14 |
| SpecialObjData.txt | 63 | 61 | 14 | 16 | 0 | 33 | 31 |
| XinFa_V1.txt | 37 | 29 | 6 | 2 | 11 | 18 | 10 |

Cột mất của các bảng này nằm ở cột `lost_list`. Hai nhãn không đặt tên vì không chắc: `起手音xiao` và `是否播放融合，闪避，搁挡动作`.

## 4. Bảng nợ

| Mã | Trạng thái | Chứng |
|---|---|---|
| C-02 | Đã trả phần A | Test xuất thật ghi `build/p1-a/real-export`. Trong lúc test, một TSV có sẵn ở `SERVER/tables/shared` không đổi byte. Kê bảng ghi `build/p1-a/real-census`. |
| C-03 | Đã trả phần A | Tách hàm ở lượt trước. `lint_py.py` trên tệp `.py` của A thoát 0: không hàm quá 50 dòng, không lồng quá 3, không dòng quá 120, không thiếu kiểu. |
| C-06 | Đã trả phần A | `_run` của hai tệp test bắt stdout và stderr. Lệnh unittest ở mục 2 chỉ in dòng của `unittest`. |
| C-07 | Đã trả phần A | `export_tables.py` gọi `tsv_file.owned_tool` và `table_census.coverage`. Không xoá hai hàm đó. |

## 5. Chưa kiểm

Chưa chạy `verify_p1.py`. Script đó sẽ thấy dòng tên cột đổi; ô dữ liệu thì lệnh so ở mục 2 đã thấy 0 lệch.

Chưa chạy unittest của B và C. Chưa mở từng dòng `code:` trong 270 thuật ngữ ở lượt đọc cuối; các dòng `code` được lấy từ `DataRecords.cpp`, `GameTable.cpp` và `ItemTable.cpp` khi chỉ số cột của mã còn khớp nhãn 0859602.

## 6. Giả định

Chỉ số cột trong ghi chú là 0. Neo cần cùng kiểu, khớp ít nhất 95% id chung, và mỗi bên có ít nhất 3 giá trị khác nhau. Giữa hai neo, chỉ nội suy khi số cột hai bên bằng nhau. Đổi kiểu ngoài khe đó cần khớp nội dung từ 99% và cũng từ 3 giá trị. Cặp chéo chỉ khi mỗi bên còn đúng một ứng viên đạt ngưỡng neo; có 10 cặp, ghi `chéo:` và vẫn đếm vào `anchors`.

`HP上限` và `MaxHP` cùng thành `max_hp`, nên được đánh số `max_hp_1`, `max_hp_2`. Mọi tên lặp khác cũng đánh số từ 1.

Mã 2008 của `SkillTemplate` lệch chỉ số sau cột hồi chiêu so với tệp 0859602. Những cột sau đó lấy tên từ nhãn, `basis` là `direct`, không gán nhầm trường của mã.

## 7. Lệch quy tắc

`column_alignment.tsv` thêm cột `lost_list` để danh sách cột mất tái hiện được từ tệp. Đề chỉ bắt các số đếm.

Thêm cờ `--alignment`. Mặc định vẫn là `TOOLS/server/column_alignment.tsv`. Test truyền đường dẫn dưới `build/`.

## 8. Chỗ tài liệu mâu thuẫn với đĩa

Đề đợt 1 nói chỉ lấy tên khi bố cục khớp. Đợt 2 yêu cầu căn khi bố cục khác. Đã làm theo đợt 2.

`PlayerExpLevel.txt` không nằm trong 76 cặp vì hai bên cùng 2 cột và cùng dãy kiểu. Mười bảng ưu tiên còn lại có dòng trong `column_alignment.tsv`.
