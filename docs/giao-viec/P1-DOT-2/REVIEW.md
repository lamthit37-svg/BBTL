# Review P1 đợt 2 — bước 2

Script giữ ở `docs/giao-viec/P1-DOT-2/kiem/`. Không sửa mã A, B, C, L. Không mở `Account.txt`. Chưa có vòng sửa sau review, không có mục Phán quyết.

Mốc trước mọi test, và cả sau T2 lẫn sau ba lần `build_data.py` thất bại, năm dòng băm không đổi:

```text
SERVER/tables/shared: 574 tệp, 91885697 byte, dd4944063cda6261
SERVER/tables/variants: 61 tệp, 2024362 byte, 03024419321c7627
SERVER/tables/server: 70 tệp, 8691252 byte, d6a885f2e550506c
SERVER/scenes: 3797 tệp, 149647004 byte, 7b13dc5b68556b0e
TOOLS/server/columns: 716 tệp, 1199068 byte, 3b4103519629e248
```

Mốc đầu đợt ở `moc/treehash.txt` khác năm dòng này. Đó là đầu ra của đợt, không phải test làm đổi cây.

## Tiêu chí mục 7

T1 đạt. Không đặt hai biến môi trường.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_*.py"
Ran 163 tests in 0.373s
OK (skipped=8)
```

Tám ca bỏ qua, cùng lệnh thêm `-v`: `test_two_digests_match` và `test_real_tables_roundtrip`, `test_real_config_is_classified`, `test_every_source_file_once` là thiếu một hoặc cả hai biến; `test_real_tree_if_present`, `test_real_tree` của legacy, `test_real_tree` của rules, `test_real_scripts_if_present` là thiếu `THIENLONG_LEGACY_ROOT`.

T2 đạt. Đã đặt hai biến. `Ran 163 tests in 726.719s`, `OK`, không ca nào bị bỏ qua. Log đầy đủ ở `build/p1-r/t2.txt`. PowerShell bọc stderr của thanh tiến trình thành `NativeCommandError`. Đó không phải dòng công cụ. Bản thân unittest chỉ in dấu chấm và `OK`.

T3 không đạt. `python -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` thoát 1 sau 135,7 giây. `export_tables` ghi xong rồi `import_legacy` dừng. Không có dòng tổng kết từng thư mục đích. Log: `kiem/t3.txt`.

```text
bảng đã ghi: 635
bản ghi: 994925
cột: 17247
cột có tên: 764
cột còn ?: 2138
cặp căn: 76
cột chữ toàn số: 33
SERVER/tables/server/scene_load_refs.tsv:1: tệp lạ, không xoá
```

Ba lần chạy ghi lại cùng byte với băm ở trên. Cảnh không được xuất lại vì lệnh chết trước bước đó.

T4 không đạt. Cùng lệnh thêm `--digest`, hai lần, đều thoát 1 với cùng dòng `scene_load_refs.tsv`. Không in `sha256:`. Log: `kiem/t4-a.txt`, `kiem/t4-b.txt`. 137,3 giây và 132,7 giây.

T5 đạt. `python -W error TOOLS/server/lint_py.py` thoát 0, không in dòng.

Đếm tay ba hàm, khớp bộ đếm (độ dài là dòng cuối trừ dòng `def` cộng 1; `elif` không thêm mức):

- `export_scene.py` `_fill_scene` dòng 1018–1063: 46 dòng, lồng 2.
- `import_legacy.py` `_parse_system` dòng 812–852: 41 dòng, lồng 1.
- `export_scene.py` `_read_scn` dòng 1371–1415: 45 dòng, lồng 3. Mức 3 là `for` rồi `if item is None` rồi `if key in OPTIONAL_MISSING`.

Hàm 53 dòng dựng ở `build/p1-r/pha/dai.py` bị báo `dài 53 dòng, quá 50`. Ngưỡng có cắn.

T6 đạt.

```text
python -W error TOOLS/server/lint_config.py
18 tệp sạch, 237 cài đặt đều có chú thích và thẳng cột
```

18 = 12 tệp `SERVER/config` lúc đầu đợt cộng 6 tệp luật. `lint_config.py` theo cụm 40 đường dẫn trên 244 `scene.toml`: bảy cụm, mỗi cụm thoát 0. Số cài đặt 502 + 858 + 853 + 371 + 1070 + 903 + 66 = 4623.

T7 đạt. `treehash.py` trước và sau T2 trùng năm dòng ở đầu tệp này.

T8 đạt ở phần ô lệch. `python -W error docs/giao-viec/P1-DOT-1/kiem-claude/verify_p1.py` thoát 0.

```text
D: 4730 tệp TSV, có vấn đề 0
B: 67 bảng đích, 41634 bản ghi; so 92 tệp chữ và 22 tệp ini; ô lệch 0
C: 244 cảnh, 1577 bảng spawns, 40168 dòng, ô lệch 0, bảng lệch số đếm 0
    walk.nav khớp nguồn 244, lệch 0
A: 635 bảng, 994925 bản ghi, 18636500 ô, lệch 0
```

Hai dòng không phải ô lệch: `flight_maps.tsv` không phải bảng chữ có dòng kiểu nên bị bỏ qua; `item_segment_values.tsv` có 1 dòng ô thừa sau 65 cột kiểu. Khoá ini vắng để ô trống: 4546. Ô spawns khi khoá vắng: 293306 ô trống. Đổi tên cột và cột `within_declared_count` không làm A/B/C báo lệch ô.

T9 đạt trên các phép đếm của `kiem/phu.py` và `export_scene.py --check`.

- `legacy_rules.tsv`: 578 dòng, khớp 578 khoá đọc lại từ tám tệp nguồn, thiếu 0, thừa 0, trùng 0. Fate: rule 131, process_config 26, dropped 9, unknown 412. Hai unknown không mang `chưa làm ở đợt 2` là `SMUKickUserTime` và `LogInCacheTime`, lý do mốc P3.
- `Public/Scene`: 3251 tệp, 0 thư mục con. `scene_attach.tsv`: 45 dòng, 10 `scene_set`, 35 `client_only`, không trùng, cả 45 tên có trên đĩa.
- `export_scene.py "<tlbb>" build/p1-r/scene-check --check` thoát 0: cảnh 244, cảnh không scn 0, `client_only` 35. Cộng các loại tệp nguồn ra 3251. `ops.*.tsv` 0, `vals.*.tsv` 0, `spawns.set_*.tsv` 7, `areas.set_*.tsv` 3.
- `column_alignment.tsv`: 76 dòng. Tổng cột 2026 là 4517, cột cũ 3157, neo 945, nội suy 902, đổi kiểu 173, mới 2497, mất 1137.
- `column_terms.tsv`: 270 dòng. `glossary` 1, `code` 70, `direct` 199.
- `scene_load_refs.tsv`: 250 dòng. `map` 83, `monster` 122, `area` 45. `literal` 140, `constant` 48, `format` 44, `unresolved` 18. `scene_refs.py --check` in cùng các số và `chú thích bỏ qua: 5`.

Năm bảng C-04: `scenes` và `scene_hosting` có `within_declared_count` 1 đúng 723 dòng và 0 đúng 200 dòng, `scenenumber=723`. `rolling_announcements` 10 dòng đều 0. `scheduled_events` 30 dòng đều 0. `random_shop_goods` 457 dòng 1 và 1 dòng 0. Không còn cột `broadtime`, `broadcount`, `huodongcount`.

Mười một bảng ưu tiên trong `column_alignment.tsv` khớp bảng của báo cáo A. `PlayerExpLevel.txt` không có dòng vì cùng bố cục.

T10 đạt trong phạm vi git và không mở `Account.txt`. `git status --short` trùng từng dòng `moc/git-status.txt` (46 dòng). Tệp đợt nằm trong `SERVER/`, `TOOLS/server/`, `docs/giao-viec/` vốn đã untracked từ mốc. Mười lăm tệp `SERVER/config` ngoài `rules/` có mtime không mới hơn `moc/treehash.txt`. Chuỗi `Account.txt` hoặc `password` chỉ thấy ở `DE-BAI.md`, `BAO-CAO-B.md` (chữ `MinorPassword`) và `kiem/phu.py`. Không thấy nội dung mật khẩu.

## Mẫu ngữ nghĩa

Hạt `random.Random(20261007).sample` theo thứ tự dòng trong tệp. Script `kiem/mau_ngu_nghia.py`, bản trích `kiem/mau-ra.txt`.

`column_terms.tsv`, 30 dòng: đúng 28, sai 1, không đủ căn cứ 1.

- Sai, T16, dòng 49, `连续攻击次数或引导的时间间隔(ms)` thành `charge_or_interval_ms`. Nhãn là số lần đánh liên tiếp hoặc khoảng dẫn chiêu, không phải thời gian tụ khí. `聚气` mới là tụ khí, và dòng khác đã dịch thành `charge_time_ms`.
- Không đủ căn cứ, T21, dòng 96, `掉落分配半径(米)` thành `drop_share_radius_m`, basis `code:GameTable.cpp:390`. Dòng 390 đọc cột `MonsterDropSearchRange` (chỉ số 10) vào `m_DropSearchRange`. Cột 10 của tệp gốc đúng là nhãn đó, nhưng tên lấy từ nhãn chứ không từ trường mã.

`legacy_rules.tsv` fate `rule`, 40 dòng: đúng 37, sai 0, không đủ căn cứ 3.

- Không đủ căn cứ, dòng 575, `[info] huodongcount`. Chú thích gốc chỉ là `活动数量`. Câu ghi thêm "theo giờ" và "được khai báo".
- Không đủ căn cứ, dòng 573, `[info] broadcount`. Chú thích gốc chỉ là `公告数量`. Câu ghi thêm "luân phiên" và "được khai báo".
- Không đủ căn cứ, dòng 176, `ExpPrenticeAddRate`. Chú thích là cộng kinh nghiệm sau khi nhận đồ đệ. Câu tiếng Việt bỏ chữ kinh nghiệm. Giá trị TOML `50` khớp `0.05` phần nghìn.

Các dòng `code:` trong mẫu trỏ đúng dòng đọc khoá hoặc đúng chỉ số cột đã đối với header 0859602 (`TBBasePrice = 9`, `MonsterLevel = 3`, `Monster_CATTR_LEVEL2_ATTACKRATE_P = 15` với chú thích `物理攻击`, cột 6 và 21 của `SpecialObjData`). Chỉ số mảng `id1`, `level3`, `abilityskill3`, `settingtype0`, `pos_z1` khớp hậu tố. `1.0` thành `1000`, `169.0` và `165.0` thành `169000` và `165000`, `37.1` là phần tử cuối của `assistant_demand_param`.

## Căn cột

Ba bảng đọc hết bằng `kiem/can_cot.py`, không gọi `align_columns`: `CommonItem.txt`, `XinFa_V1.txt`, `ImpactSEData_V1.txt`. Id chung lần lượt 4839, 63, 805. Không id trùng. Tỉ lệ ghi trong note khớp lại, kể cả đổi kiểu chuỗi số sang float sau khi so bit float32.

`items_common` cột `is_consumed` chéo về cột gốc 15, khớp 4839/4839. Đó là chéo có số liệu, không phải ghép sai.

Nội suy dưới 95% trên mọi `columns/shared`: 183 cột ghi vậy, 121 cột có cả hai bên từ 3 giá trị khác nhau. Ba bảng chọn có `description` 72,0% (3268 giá trị), `inner_art_description` 0/63, `priority` 0/805 (2026 là 40001, gốc là 0). Mô tả tâm pháp là cùng chỗ cột: chuỗi mới nối thêm vào chuỗi cũ, hai neo hai bên khớp 100%. Luật đề vẫn không cho nội suy cột nhiều giá trị dưới 95%.

`ShopTable.txt` cột 2026 số 258 là ghép sai hẳn. Note gán `PID(商品编号42)`, cột gốc 271, khớp 12/172. Cột gốc 224 tên `PNUM(每组多少个)` khớp 171/172 và không được ghép vào cột 2026 nào. Mẫu id 1: giá trị 2026 là 1, PNUM là 1, PID là 0.

`pha.py`: giữa hai neo, cột bốn giá trị khác nhau khớp 0% vẫn ra `interpolated` và mang tên cột gốc. `test_constant_between_anchors_is_interpolated` chỉ dùng hằng số nên vẫn xanh.

## Finding

### R-A-01 [CHẶN] Nội suy gán tên cột gốc cho cột nhiều giá trị khớp dưới 95%, và có cột nhận nhầm tên
- Chỗ: `TOOLS/server/align_columns.py:332` và `TOOLS/server/columns/shared/shops.tsv:264`
- Bằng chứng: `python -W error docs/giao-viec/P1-DOT-2/kiem/pha.py` rồi `python -W error docs/giao-viec/P1-DOT-2/kiem/can_cot.py`

```text
loại ['neo', 'interpolated', 'neo']
cột giữa nội suy: cột gốc 1, khớp 0.0% (0/4 id) tên gốc 'Khác'
nội suy ghi dưới 95%: 183; cả hai bên từ 3 giá trị và đo dưới 95%: 121
ShopTable.txt cột 258: cột gốc 224 PNUM khớp 99.4% (171/172); cột đang gán 271 PID khớp 7.0% (12/172)
```

`ImpactSEData` cột `priority`: id 1 giá trị 2026 là 40001, gốc là 0, khác nhau 128 và 10.
- Đòi hỏi: cột từ 3 giá trị khác nhau mà khớp dưới 95% id chung thì là `mới ở 2026`, cột gốc tương ứng ghi mất. Không gán `PID(商品编号42)` cho cột 258 của `shops`. Test phải đỏ với cột nhiều giá trị khớp 0% nằm giữa hai neo.

### R-A-02 [SỬA] Hai tên trong mẫu hạt 20261007 không theo căn cứ đã ghi
- Chỗ: `TOOLS/server/column_terms.tsv:49` và `TOOLS/server/column_terms.tsv:96`
- Bằng chứng: `python -W error docs/giao-viec/P1-DOT-2/kiem/mau_ngu_nghia.py`. Nhãn dòng 49 là số lần đánh liên tiếp hoặc khoảng dẫn chiêu. `GameTable.cpp:390` gán `m_DropSearchRange`, header cột 10 của `MonsterAttrExTable.txt` là `掉落分配半径(米)`.
- Đòi hỏi: dòng 49 không dùng `charge` cho `引导`. Dòng 96, vì basis là mã, tên theo `m_DropSearchRange`, không theo cách diễn "bán kính chia đồ" khi đã chọn basis mã.

### R-B-01 [SỬA] Ba chú thích luật trong mẫu nói thêm điều chú thích gốc không có
- Chỗ: `TOOLS/server/legacy_rules.tsv:573`, `legacy_rules.tsv:575`, `legacy_rules.tsv:176`
- Bằng chứng: cùng script mẫu. `SystemInfo.ini:2` là `broadcount=0` kèm `公告数量`. `SystemInfo.ini:4` là `huodongcount=0` kèm `活动数量`. `ConfigInfo.ini:236` là `ExpPrenticeAddRate=0.05` kèm `收徒后的经验加成`.
- Đòi hỏi: câu tiếng Việt không thêm "luân phiên", "theo giờ", "được khai báo" khi chú thích gốc chỉ là số lượng. Câu của `ExpPrenticeAddRate` phải nói cộng kinh nghiệm.

### R-B-02 [CHẶN] build_data chết vì coi scene_load_refs.tsv là tệp lạ
- Chỗ: `TOOLS/server/import_legacy.py:1388`
- Bằng chứng: `python -W error docs/giao-viec/P1-DOT-2/kiem/chay_t3_t4.py`. Ba lần thoát 1, dòng cuối `SERVER/tables/server/scene_load_refs.tsv:1: tệp lạ, không xoá`. `_foreign` trả tệp có chủ khác `import_legacy.py` trước khi `_write_built` tới `keep_tools=("scene_refs.py",)`.
- Đòi hỏi: `import_legacy` trên `SERVER/tables/server` không xoá và không chết vì `scene_load_refs.tsv`. `build_data.py` không `--check` thoát 0 và in tổng kết bốn thư mục. Hai lần `--digest` in cùng một `sha256:`.

### R-C-01 [SỬA] Lời gọi trong chú thích khối và trong chuỗi vẫn thành lời gọi thật
- Chỗ: `TOOLS/server/scene_refs.py:273`
- Bằng chứng: `pha.py` với `build/p1-r/pha/tlbb/Public/Data/Script/block.lua`

```text
chú thích đếm 0
  dòng 2 kind=map how=literal commented=False resolved='hidden.nav'
  dòng 6 kind=area how=unresolved commented=False
```

Dòng 2 nằm trong `--[[ ... ]]`. Dòng 6 nằm trong chuỗi của `print`. Quét 4248 tệp `.lua` thật: 0 tệp có `--[[` hoặc `--[`, 0 dòng có lời gọi sau dấu nháy chưa đóng. `scene_load_refs.tsv` hiện không bị cộng dòng từ hai kiểu này.
- Đòi hỏi: lời gọi trong chú thích khối và trong chuỗi không thành dòng, vẫn được đếm là chú thích hoặc bị bỏ. Test phải đỏ nếu `hidden.nav` thành `how=literal`.

## Đã thử phá mà không phá được

A. 635 bảng, 994925 bản ghi, 18636500 ô so DBC lệch 0. Note neo, chéo và đổi kiểu của ba bảng chọn khớp lại từng tỉ lệ. `is_consumed` chéo 100%. Đổi kiểu `心法修正率` là chuỗi `0.2` sang float cùng bit. Header shared và variants không trùng tên. 764 cột có tên không dấu `?`, 2138 cột còn `?`.

B. 578 khoá phủ kín, không trùng. `within_declared_count` đúng 723/200, 10, 30 và 457/1. Sáu TOML luật nằm trong 18 tệp sạch. `import_rules.py --check` in luật 131, tiến trình 26, bỏ 9, chưa rõ 412, lệch tiến trình 0, đã ghi 0. Cây giả `MergeConfig.txt` rỗng bị từ chối `bảng chữ cụt`.

C. `export_scene --check` thoát 0, 0 tệp không gắn. Tệp `khong_co_cha.nav` dựng trong `build/` làm thoát 1, dòng `không gắn được vào cảnh nào`, không tạo thư mục đích. Bốn quái `_pingpan_*` và map `_pingpan_1.nav` đúng dòng `ezhaochen.lua`. `gongdi.nav`, `jishi.nav`, hằng `yamentianshanmis_*` với `yamen.nav` đúng tệp script đã dẫn. `murenxiang_monster_10.ini` đi cùng `xingxiu.nav`, đúng kiểu lệch cảnh đã báo, không bị chuyển thư mục.

L. `lint_py.py` sạch trên cây thật và bắt hàm 53 dòng. T2 không đổi năm băm. `format` của đợt 1 không được đụng trong review này.

## Chưa kiểm

Chưa đếm lại 803 và 541 của đối chiếu 1344 tệp quái bằng bộ phân loại riêng. Đã thấy tổng loại `monster_by_level` 1171, `monster_group` 153, `monster_bare` 2, `monster_entrance` 18 cộng thành 1344, và mẫu `murenxiang` lệch cảnh như báo cáo C.

Chưa đọc 240 dòng `column_terms.tsv` ngoài mẫu 30, và 91 dòng `fate=rule` ngoài mẫu 40.

`build_data.py` chưa gọi `import_rules.py`. Việc đó là bước 5. T3 chết trước khi tới câu hỏi đó.

## Phán quyết

Chạy lại trên mã cuối, sau review và sau xét chéo. T7 so băm trước và sau T2, không so với mốc đầu đợt. Hai lần đó trùng nhau:

```text
SERVER/tables/shared: 574 tệp, 91885649 byte, ec8f90ea675fb6f4
SERVER/tables/variants: 61 tệp, 2024362 byte, 03024419321c7627
SERVER/tables/server: 70 tệp, 8660785 byte, f666efecc8577cf0
SERVER/scenes: 3797 tệp, 149647004 byte, 7b13dc5b68556b0e
TOOLS/server/columns: 716 tệp, 1179128 byte, fbf28991cf95a421
```

Sau T3 và hai lần T4, `treehash.py` vẫn ra đúng năm dòng đó.

T1 đạt. Không đặt biến. `Ran 173 tests in 0.416s`, `OK (skipped=8)`.

T2 đạt. Đã đặt hai biến. `Ran 173 tests in 447.973s`, `OK`, không bỏ qua. Log `build/p1-r/t2.txt`.

T3 đạt. `build_data.py --legacy "<tlbb>" --raw "<_raw>"` thoát 0. Log `kiem/t3.txt`.

```text
tables/server: 70 tệp, 46460 bản ghi
tables/shared: 574 tệp, 991160 bản ghi
tables/variants: 61 tệp, 3765 bản ghi
scenes: 3797 tệp, 54959 bản ghi
```

991160 + 3765 = 994925 bản ghi client.

T4 đạt. Hai lần `--digest` đều thoát 0 và in cùng một dòng. Log `kiem/t4-a.txt`, `kiem/t4-b.txt`.

```text
sha256: d3ffb5bf6599f34f341cc19d10f7136eb48c1b277cebdbb1ae6041a25cbadb62
```

Mã này khác mã B in lúc đối chất. Các sửa sau đó đã đổi byte. Hai lần của vòng này thì trùng nhau.

T5 đạt. `lint_py.py` thoát 0, không in dòng.

T6 đạt. `lint_config.py` không tham số: `18 tệp sạch, 237 cài đặt`. Bảy cụm `scene.toml`, 244 tệp, 0 cụm lỗi, 4623 cài đặt.

T7 đạt. Năm dòng băm trước và sau T2 giống nhau, như ở trên.

T8 đạt. `verify_p1.py` thoát 0. A 635 bảng, 994925 bản ghi, 18636500 ô, lệch 0. B 67 bảng, 41634 bản ghi, 92 tệp chữ, 22 tệp ini, lệch 0. C 244 cảnh, 1577 bảng spawns, 40168 dòng, lệch 0, `walk.nav` khớp 244. D 4730 tệp, vấn đề 0. Dòng không phải ô lệch: `flight_maps.tsv` không phải bảng chữ có dòng kiểu; `item_segment_values.tsv` có 1 dòng ô thừa sau 65 cột kiểu của tệp gốc. Khoá ini vắng để ô trống: 4546.

T9 đạt. `kiem/phu.py`: 578 khoá nguồn, 578 dòng luật, thiếu 0, thừa 0, trùng 0. `Public/Scene` 3251 tệp, `scene_attach.tsv` 45 dòng (10 `scene_set`, 35 `client_only`), 0 tên thiếu trên đĩa. `column_alignment.tsv` 76 dòng. T3 thoát 0 nên không còn tệp cảnh chưa gắn.

T10 đạt. `git status --short` trùng 46 dòng `moc/git-status.txt`, thêm 0, bớt 0. Không mở `Account.txt`. Chỗ thấy chữ `Account.txt` hoặc `password` là đề, báo cáo và script kiểm, không phải nội dung mật khẩu.

- R-A-01 ĐÃ SỬA. `pha.py`: loại `['neo', 'new', 'neo']`, tên gốc rỗng. `can_cot.py`: nội suy ghi dưới 95% còn 62, cả hai bên từ 3 giá trị và đo dưới 95% là 0. `shops.tsv` dòng chỉ số 258 là `mới ở 2026`, không còn `PID(商品编号42)`.
- R-A-02 ĐÃ SỬA. `column_terms.tsv:49` là `consecutive_hits_or_channel_interval_ms`. Dòng 96 là `drop_search_range_m`, basis vẫn `GameTable.cpp:390`.
- R-B-01 ĐÃ SỬA. `character.toml` ghi `Cộng kinh nghiệm sau khi nhận đồ đệ.` `global.toml` ghi `Số lượng thông báo.` và `Số lượng hoạt động.`
- R-B-02 ĐÃ SỬA. T3 và hai lần T4 thoát 0. `# tool:` của `scene_load_refs.tsv` vẫn là `TOOLS/server/scene_refs.py`. Không còn dòng `tệp lạ`.
- R-C-01 ĐÃ SỬA. `pha.py` trên `block.lua`: chú thích đếm 1, dòng 2 `commented=True` và `how=unresolved`, không còn `hidden.nav` dạng literal. Dòng `print` không thành lời gọi. Dòng 5 vẫn là hằng `shown.nav`.
- X-AB-01 ĐÃ SỬA. T2 gồm `test_ini_line_without_equals` và thoát 0. `_parse_ini` báo `dòng không có dấu bằng` thay vì bỏ qua.
- X-AB-02 ĐÃ SỬA. `item_segment_values.tsv` dòng `# types:` toàn `int`, hết ở `column_64`, không còn cột `text`.
- X-AB-03 ĐÃ SỬA. T2 gồm `test_index_gap_is_rejected` và thoát 0. `_ordered_indexes` từ chối khi chỉ số không phải số liền trước cộng 1.
- X-BC-01 ĐÃ SỬA. `scene_load_refs.tsv`: `bamboo_forest.lua:458` là `format` `zhulin_monster_%d.ini`; `boundary_between_song_and_liao.lua:459` là `songliao_monster_%d.ini`; `field_fastness.lua:461` là `yewai_monster_%d.ini`. How trên cả bảng: literal 140, constant 48, format 50, unresolved 12.
- X-BC-02 ĐÃ SỬA. T2 gồm `test_check_rejects_foreign_without_deleting` và thoát 0.
- X-BC-03 ĐÃ SỬA. T2 gồm `test_format_local_long_string_and_name_table` và thoát 0. Ca đó đòi `[[plain.nav]]` thành `how=literal`.
- X-CA-01 ĐÃ SỬA. T2 gồm `test_padded_legacy_id_is_reported` và thoát 0.
- X-CA-02 ĐÃ SỬA. `export_tables.py` không đối số thoát 1, in `export_tables.py:1: cần thư mục _raw, tlbb và thư mục bảng`. `--help` thoát 0, tiếng Việt, không có `usage:`.
- X-CA-03 BÁC ĐÚNG. `ShopTable.txt` cột 270 vẫn nội suy `PID(商品编号44)`, khớp 12/172. Đo lại: phía 2026 có 2 giá trị khác nhau, dưới ngưỡng 3. Đề chỉ cấm nội suy khi cả hai bên từ 3 giá trị và khớp dưới 95%. Cột 2 giá trị nằm giữa hai neo được phép nội suy. Sửa R-A-01 không bắt buộc phải gỡ dòng này.

Trạng thái cuối: T1 tới T10 đều đạt trên mã sau mọi lần sửa. Một finding bị bác và bác đó đứng. Không còn finding mở. `build_data.py` vẫn chưa gọi `import_rules.py`; đó là bước 5, không chặn T3.
