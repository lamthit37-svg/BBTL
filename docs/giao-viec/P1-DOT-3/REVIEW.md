# Review P1 đợt 3 — bước 2

Script giữ ở `docs/giao-viec/P1-DOT-3/kiem/`. Không sửa mã A, B, C, L. Không mở `Account.txt`. Không chép nội dung `secrets.local.toml` vào báo cáo này. Chưa có vòng sửa sau review, không có mục Phán quyết.

Băm trước T2, và sau T2, trùng nhau:

```text
SERVER/tables/shared: 574 tệp, 91894837 byte, ca782a4eb09efd44
SERVER/tables/variants: 61 tệp, 2024610 byte, aa4814cb5bb29f01
SERVER/tables/server: 71 tệp, 8733474 byte, 35f3783c96bc6b65
SERVER/scenes: 3797 tệp, 149646681 byte, 9cd767cd33c209f3
TOOLS/server/columns: 716 tệp, 1214354 byte, fb17b8318594d360
```

Mốc `moc/treehash-sau-buoc-0.txt` khác năm dòng này. Đó là cây sau A, B, C, không phải test làm đổi.

## Tiêu chí mục 7

T1 không đạt. Không đặt hai biến.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_*.py"
Ran 198 tests in 0.645s
FAILED (failures=1, skipped=8)
```

Ca đỏ: `test_unknown_chinese_marks_question`. Nhãn `名称$1$` ra `name`, test đòi `column_1`. Tám ca bỏ qua là test dữ liệu thật thiếu biến, cùng kiểu đợt 2.

T2 không đạt. Đã đặt hai biến. `Ran 198 tests in 820.584s`, `FAILED (failures=1)`, không ca nào bị bỏ qua. Cùng một assertion. Log: `build/p1-dot3-r/t2-err.txt`. PowerShell bọc stderr thành `NativeCommandError`. Đó không phải dòng công cụ.

T3 không đạt hết chữ tiêu chí. Thoát 0 sau 256,8 giây, có tổng kết thư mục, không có dòng `lint_names` hay `diff_tables`. `build_data.py` không gọi hai công cụ đó.

```text
tables/server: 71 tệp, 47804 bản ghi
tables/shared: 574 tệp, 991160 bản ghi
tables/variants: 61 tệp, 3765 bản ghi
scenes: 3797 tệp, 54959 bản ghi
config/rules: 6 tệp, 0 bản ghi
```

`991160 + 3765 = 994925`. Cảnh: `cells_rewritten 266`, bốn số tệp cấp `863 / 80 / 221 / 180`. Luật `142 / 26 / 9 / 401`. Sau T3, băm `shared` và `columns` đổi, mỗi cây ít 13 byte. `variants`, `server`, `scenes` không đổi. T3 ghi đè nên không còn bản trước để chỉ tệp nào lệch.

```text
SERVER/tables/shared: 574 tệp, 91894824 byte, 56b9005201e48bc8
TOOLS/server/columns: 716 tệp, 1214341 byte, 79ae3c1f6635aefc
```

T4 đạt phần hai mã bằng nhau. Cùng lệnh thêm `--digest`, hai lần, đều thoát 0, cùng mã. Không in tổng kết `lint_names` hay `diff_tables`. Mã này là của cây sau T3, không phải cây trước T3.

```text
sha256: bd163f2c8179343467df6aa22f0f32fd983dce54e121495038df71dd53fc9d25
```

Sau hai lần đó, `treehash.py` vẫn ra đúng băm sau T3, kể cả `columns`. Lệch 13 byte chỉ xảy ra một lần, từ cây A/B/C để lại sang lần sinh của `build_data`.

T5 đạt. `python -W error TOOLS/server/lint_py.py` thoát 0, không in dòng.

Đếm tay ba hàm, khớp bộ đếm (dòng cuối trừ dòng `def` cộng 1; `if` trong `for` là mức 2):

- `scene_refs.py` `_split_args` dòng 207–232: 26 dòng, lồng 2.
- `diff_tables.py` `_cover_row` dòng 354–392: 39 dòng, lồng 2.
- `column_names.py` `number_repeated` dòng 139–146: 8 dòng, lồng 1.

T6 đạt.

```text
python -W error TOOLS/server/lint_config.py
18 tệp sạch, 248 cài đặt đều có chú thích và thẳng cột
```

18 = 12 tệp `SERVER/config` cộng 6 tệp luật. Bảy tệp luật còn lại không có trên đĩa. 244 `scene.toml`, bảy cụm, mỗi cụm thoát 0. Số cài đặt `423 + 798 + 859 + 504 + 1070 + 903 + 66 = 4623`.

T7 đạt. `treehash.py` trước và sau T2 trùng năm dòng ở đầu tệp này.

T8 đạt ở phần ô lệch có chủ đích. `verify_p1.py` và `verify_p2.py` đều thoát 0.

```text
A: 635 bảng, 994925 bản ghi, 18636500 ô, bảng có vấn đề 0
B: 67 bảng đích, 41634 bản ghi; ô lệch 25
C: 244 cảnh, 1577 bảng spawns, 40168 dòng, ô lệch 61, bảng lệch số đếm 0
```

25 ô B là float `pet_ai_strategies.tsv` bỏ trắng cuối (`'0.50 '` thành `'0.50'`). 61 ô C là `script_id` của `spawns` bỏ số 0 đứng đầu (`040001` thành `40001`). Hai dòng không phải ô lệch mới: `flight_maps.tsv` không phải bảng chữ có dòng kiểu; `item_segment_values.tsv` một dòng ô thừa. Khoá ini vắng: 4546. `verify_p2`: rule 142, tiến trình 26, bỏ 9, unknown 401, lệch giá trị 0. Bốn `shuilao_monster_15/25/35/45.ini` không có trên đĩa. `how` là constant 48, format 50, literal 140, unresolved 12.

`verify_p2` còn in: 115 cột ghi `mới ở 2026` khớp từ 95% một cột gốc bị ghi mất, trong đó hai cặp một-một: `Mission_Delivery.txt` cột 29 với cột gốc 28 (479/497), `Mission_LootItem.txt` cột 52 với cột gốc 51 (234/239). Script vẫn thoát 0.

T9 không đạt hết chữ. `lint_names.py` thoát 0. `--stats`:

```text
shared: cột 17247, chưa tên 14661, nhãn rỗng 14531, chỉ chữ Hán 129, ASCII và chữ Hán 1, chỉ ASCII 0
server: cột 2172, chưa tên 285, nhãn rỗng 6, chỉ chữ Hán 277, ASCII và chữ Hán 0, chỉ ASCII 2
scenes: cột 95, chưa tên 5, nhãn rỗng 0, chỉ chữ Hán 4, ASCII và chữ Hán 0, chỉ ASCII 1
```

Còn một nhãn khớp M1 mang tên `column_9`: `columns/server/scenes.tsv` gốc `_clientres`. `english_name` của định danh đó ra `clientres`, đụng cột `clientres` đã có. Luật lặp là đánh số, không phải `column_<n>`.

T10 đạt trên cây trước T3.

```text
python -W error TOOLS/server/diff_tables.py "<tlbb>" SERVER --check
cặp: 106
ids_2026: 354614
ids_legacy: 62374
common: 61522
only_2026: 293092
only_legacy: 852
dòng tham chiếu: 55
dòng có giá trị thiếu: 6
```

Năm tổng trùng mục 3. `refs/shared.tsv` 25 dòng, `refs/server.tsv` 24, `refs/scenes.tsv` 6. Mười `only_legacy` lớn nhất trùng bảng của A (`CityIdOfChina.txt` 318, `CampaignTable.txt` 141, `CommonItem.txt` 108, …).

T11 đạt trên ba preset. Cả ba `ninja: no work to do` rồi `ctest` 3/3 xanh. Không dịch lại nên không có dòng cảnh báo mới. Binaries khớp nguồn hiện tại.

gcc-debug, 8,91 giây: `layers` 0,19; `content_tests` 0,01; `server_data_lint` 8,71.

clang-asan, 91,79 giây: `layers` 0,16; `content_tests` 0,02; `server_data_lint` 91,61.

msvc-release, 2,28 giây: `layers` 0,16; `content_tests` 0,01; `server_data_lint` 2,11. MSVC qua `dev.bat`.

T12 đạt.

```text
python C:\Users\myhea\.claude\cpp23\tools\check.py SRC\content\lint.hpp SRC\content\lint.cpp SRC\linttool\main.cpp tests\content_tests.cpp
4 tệp, 0 lỗi.
```

T13 đạt trên cây trước T3. `build\msvc-release\thienlong_lint.exe --root SERVER --refs TOOLS\server\refs --report build\p1-dot3-r\msvc-coverage.tsv` thoát 0 trong 2138 ms.

```text
tệp: 4015
bản ghi: 1097688
ô: 22019096
dòng tham chiếu: 55
lỗi: 0
```

Phần sau các dòng `#` trùng `table_ref_coverage.tsv` do `diff_tables.py` ghi, 5662 byte. Bản gcc cùng kết quả. Chưa đo lại `PeakWorkingSet64`.

T14 đạt trong phạm vi git và không chép bí mật. So với `moc/git-status.txt`, thêm `M cmake/GameLayers.cmake`, `?? SRC/content/`, `?? SRC/linttool/`, `?? tests/content_tests.cpp`. Đúng chỗ được phép. `git diff --no-index` hai tệp CMake với bản `moc/` chỉ có dòng thêm. `secrets.local.toml` không nằm trong `git status`. Không thấy `Account.txt` trong cây đợt ngoài câu cấm của `DE-BAI.md`.

## Mẫu ngữ nghĩa

Hạt `random.Random(20261008)`, lần lượt `column_terms.tsv` (707 dòng), `column_terms_server.tsv` (969), rồi `refs/` theo tên tệp (55). Script `kiem/mau.py`, bản trích `kiem/mau-ra.txt`. Không còn bản 270 dòng cũ trên đĩa, nên 40 dòng đầu lấy từ cả tệp hiện tại.

`column_terms.tsv`, 40 dòng: đúng 39, sai 0, không đủ căn cứ 1.

- Không đủ căn cứ, dòng 13, `技能的心法等级限制` thành `inner_art_level_limit`, basis `code:Common/Combat/DataRecords.cpp:186`. Dòng đó gán `m_nSkillMaxLevel`. Tên theo nhãn, không theo trường.

`column_terms_server.tsv`, 40 dòng: đúng 40, sai 0, không đủ căn cứ 0.

Đã đối header `DropBoxContent.txt`: sau `Item100ID` là `Level`, rồi `101`, `Level`, `102`, … Cột nhãn `149` đứng ngay trước `Level`. Tên `item_149_id` khớp vị trí. Dấu nháy trong `允许自由PK` có thật trên dòng tên cột của `PvpRuler.txt`. `CampAndStand.cpp:38` ghi `m_aStands[nIdx]`, `StandByCampID` lấy đúng chỉ số đó, nên `stand_with_camp_2` theo mã.

`refs/`, 15 dòng: đúng 13, sai 0, không đủ căn cứ 2.

- Không đủ căn cứ, `scenes.tsv` dòng 7, `areas` `script_id`. `Obj_Human.cpp:924` chỉ gọi `ExeScript_DDD`. Gán `m_uScriptID` ở dòng 916, so `UINT_MAX` ở dòng 922.
- Không đủ căn cứ, `server.tsv` dòng 26, `scene_hosting.scene_id`. `ThreadManager.cpp:55` đọc `g_Config.m_SceneInfo...m_SceneID` để gắn luồng, không tra `scenes.tsv`.

Các dòng `did_*` trỏ `ItemTable.cpp:1212`, gán `m_DropBox[j]`. Nhánh `if(iValue!=-1)` ở dòng 1211 đang bị chú thích. `-1` vẫn là giá trị không có trong `drop_packages`, nên `absent` giữ được. `MonsterManager.cpp:397` đọc khoá `base_ai` vào `m_BaseAI`; `Obj_Monster.cpp:216` gán `m_AIType = m_BaseAI`; dòng 1588 tra bảng AI theo `GetAIType()`.

## Đếm lại `missing_values`

`kiem/thieu.py`, không gọi `diff_tables.py` hay `thienlong_lint`. Khớp `known_missing` đã ghi.

| Dòng | Thiếu | Ô | Giá trị |
|---|---|---|---|
| `monsters.attack_trait_id` | 1 | 18 | `31` |
| `items_common.required_skill` | 0 | 0 | |
| `monster_drops.id` | 30 | 30 | gồm `12300` trở đi |
| `gacha_item_pools.gacha_id` | 1 | 1 | `30504013` |
| `spawns*.tsv` `type` | 1 | 10 | `3364`, 1577 tệp, 40168 dòng, 3490 giá trị |
| `spawns*.tsv` `script_id` | 2 | 2 | `13021`, `13022` |

`patrols*.tsv`: 244 tệp, cộng số giá trị `patrol_index` lặp trong từng tệp là 246. Không đưa vào `refs/` là đúng luật cột cha. `scene_level_files.tsv`: 1344 dòng, `same` 863, `mismatch` 80, `unpointed` 221, `map_unknown` 180. Bốn dòng Thuỷ Lao `15/25/35/45` có `files_on_disk` 0. Ô `int` không chính tắc: 0. Ô `float` còn trắng: 0. Trên 4015 tệp, 1097688 bản ghi, 22019096 ô.

`column_terms.tsv`: 707 dòng, glossary 15, code 105, direct 587, khoá trùng 0, `{n}` lệch 0. `column_terms_server.tsv`: 969 dòng, direct 945, code 23, glossary 1, cùng sạch hình dạng.

## Finding

### R-A-01 [CHẶN] T1 và T2 đỏ vì nhãn thử đã có thuật ngữ scope rỗng
- Chỗ: `TOOLS/server/test_export_tables.py:204` và `TOOLS/server/column_terms.tsv:112`
- Bằng chứng: unittest không biến và có biến. Cùng assertion `'name' != 'column_1'`. Dòng 112 là `名称$1$` scope rỗng thành `name`.
- Đòi hỏi: T1 và T2 xanh. Ca chữ Hán chưa có tên phải dùng một nhãn không có trong `column_terms.tsv`, và vẫn ra `column_<n>` kèm `?`.

### R-A-02 [SỬA] Cùng chữ 冰, tên theo mã lại là ice trong khi enum là COLD
- Chỗ: `TOOLS/server/column_terms.tsv:348` và `TOOLS/server/column_terms.tsv:159`
- Bằng chứng: dòng 348 `冰抵抗` thành `ice_resist`, basis `code:Common/GameDefine_Item.h:42`. Dòng 42 là `IATTRIBUTE_COLD_RESIST`. Dòng 159 `冰攻击` thành `cold_attack`. `column_terms_server.tsv` dòng 270, cùng nhãn `冰攻击` scope `ItemSegRate.txt`, thành `ice_attack`.
- Đòi hỏi: một chữ 冰 một tên. Dòng basis mã theo `COLD` thì tên không dùng `ice`.

### R-A-03 [SỬA] `--check` không báo khi mẫu cha không khớp tệp nào
- Chỗ: `TOOLS/server/diff_tables.py:312`
- Bằng chứng: `python -B -W error docs/giao-viec/P1-DOT-3/kiem/pha.py`, ca `cha không có`. Con có một id `7`, cha `tables/missing.tsv` không có, `known_missing` là 1.

```text
cha không có py 0
dòng tham chiếu: 1
dòng có giá trị thiếu: 1
cha không có exe 1
a.tsv:4: mẫu không khớp tệp nào
```

- Đòi hỏi: `--check` thoát 1 và in mẫu không khớp. Test phải đỏ nếu cha không có tệp mà `known_missing` bằng số giá trị con.

### R-B-01 [SỬA] Nhãn ASCII `_clientres` vẫn là `column_9`
- Chỗ: `TOOLS/server/import_legacy.py:623` và `TOOLS/server/columns/server/scenes.tsv:15`
- Bằng chứng: `python -B -W error docs/giao-viec/P1-DOT-3/kiem/thieu.py` in `M1/M2 còn column_n: 1` và `server/scenes.tsv: M1 '_clientres' -> column_9`. Cột `clientres` đã chiếm tên đó. Luật lặp đánh số từ 1.
- Đòi hỏi: không còn nhãn khớp M1 hoặc M2 mang tên `column_<n>`. Hai cột cùng ra `clientres` thì là `clientres_1` và `clientres_2`.

### R-C-01 [SỬA] `known_missing` không phải số thì exe bỏ dòng và thoát 0
- Chỗ: `SRC/content/lint.cpp:629`
- Bằng chứng: cùng `pha.py`, ca `known_missing trống`. Python: `known/refs/a.tsv:4: known_missing không phải số nguyên`, thoát 1. Exe:

```text
known_missing trống exe 0
dòng tham chiếu: 0
lỗi: 0
```

- Đòi hỏi: dòng refs sai số là lỗi, không biến mất khỏi báo cáo. Test một ca `known_missing` rỗng hoặc không phải số.

### R-C-02 [SỬA] Kiểm kiểu so mọi cột cùng tên, không phải đúng tệp cha
- Chỗ: `SRC/content/lint.cpp:932`
- Bằng chứng: ca `khác kiểu giả`. Con int trỏ cha int, con text trỏ cha text, hai cột cha đều tên `id`. Exe thoát 1:

```text
a.tsv:4: cột con và cột cha khác kiểu
a.tsv:5: cột con và cột cha khác kiểu
```

Cây thật không dính vì các cột `id` đang dùng cùng kiểu, nên `server_data_lint` vẫn xanh.
- Đòi hỏi: chỉ so kiểu của đúng tệp cha. Hai cha cùng tên cột mà khác kiểu không được làm dòng kia đỏ. Test phải có ca này.

## Đã thử phá mà không phá được

Năm lỗi cấy trong `build/p1-dot3-r/cay`, exe gcc, thoát 1, đúng năm dòng:

```text
probe.tsv:4: số giá trị thiếu 1 khác known_missing 0
tables/server/pet_death_happiness_loss.tsv:1: có BOM
tables/server/pet_mutant_quality_odds.tsv:1: có ký tự CR
tables/server/pet_skill_index.tsv:6: cột skill_id: ô int không hợp lệ
tables/server/scenes.tsv:7: cột scene_id lặp giá trị 0
```

Ô int là `0652` ở dòng 6. Khoá lặp là bản chép của dòng `scene_id` 0, chèn thành dòng 7. Id hụt `999999` ở `scene_hosting.tsv` dòng 6. Cây này có `tables/server` và hai cảnh `homexiao`, `homezhong`.

Tệp rỗng và tệp cụt không có LF: `thiếu xuống dòng cuối`, không dừng giữa chừng. Dòng thiếu ô: `không đọc được: dòng 4: 1 ô, dòng tên cột có 2`. Byte `0xFF`: `byte UTF-8 hỏng` đúng dòng 4. `parse_tsv` từ chối dòng ngắn trước khi lấy ô theo chỉ số.

`diff_tables.py` và exe msvc trên cây thật: 55 dòng phủ, sau khi bỏ dòng `#` thì trùng byte. Sáu dòng đếm tay ở trên khớp `known_missing`. `attack_trait` thiếu `31`. `type` thiếu `3364`.

## Chưa kiểm

Chưa đo `PeakWorkingSet64`. Thời gian msvc-release của riêng exe là 2138 ms, chưa kể ctest.

Chưa đọc 667 dòng `column_terms.tsv` và 929 dòng `column_terms_server.tsv` ngoài mẫu. Chưa đọc 40 dòng `refs/` ngoài mẫu 15.

`TOOLS/server/__pycache__` vẫn còn. D-08 chưa dọn hết. Các `build/tmp*` và `build/p1c_xem_a*.py` của đợt 2 vẫn nằm đó; không xoá vì không phải thứ phiên này tạo để thay chúng.

## Phán quyết

Chạy lại trên mã cuối, sau review và sau xét chéo. Không sửa mã A, B, C, L. T7 so băm trước và sau T2. Hai lần trùng nhau, và sau T3 cùng hai lần T4 `treehash.py` vẫn ra đúng năm dòng này:

```text
SERVER/tables/shared: 574 tệp, 91894834 byte, 26b703f41f00d718
SERVER/tables/variants: 61 tệp, 2024610 byte, aa4814cb5bb29f01
SERVER/tables/server: 71 tệp, 8733477 byte, 66278d43f609cb0a
SERVER/scenes: 3797 tệp, 149646681 byte, 9cd767cd33c209f3
TOOLS/server/columns: 716 tệp, 1215679 byte, cc29aec1904121b8
```

T1 đạt. Không đặt hai biến. `Ran 211 tests in 1.020s`, `OK (skipped=8)`.

T2 đạt. Đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT`. `Ran 211 tests in 830.439s`, `OK`, không bỏ qua. Thoát 0.

T3 đạt. `python -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` thoát 0 sau 262,9 giây. Có tổng kết `lint_names` và `diff_tables`.

```text
tables/server: 71 tệp, 47804 bản ghi
tables/shared: 574 tệp, 991160 bản ghi
tables/variants: 61 tệp, 3765 bản ghi
scenes: 3797 tệp, 54959 bản ghi
config/rules: 6 tệp, 0 bản ghi
```

`991160 + 3765 = 994925`. Cảnh `cells_rewritten 266`. Tệp cấp `863 / 80 / 221 / 180`. Luật `142 / 26 / 9 / 401`, lệch tiến trình 0.

T4 đạt. Cùng lệnh thêm `--digest`, hai lần, đều thoát 0, cùng một dòng.

```text
sha256: 29a45614a089d6f506b7ffd4d178f365a1935862f7b6a01a28438d1561b8633f
```

T5 đạt. `python -W error TOOLS/server/lint_py.py` thoát 0, không in dòng.

T6 đạt. `lint_config.py` không tham số: `18 tệp sạch, 248 cài đặt`. 244 `scene.toml` đi qua `lint_config.main` trong một tiến trình (dòng lệnh không chứa nổi 244 đường dẫn): `244 tệp sạch, 4623 cài đặt`. Thoát 0.

T7 đạt. Năm dòng băm trước và sau T2 giống nhau, như ở trên.

T8 đạt ở phần ô lệch có chủ đích. `verify_p1.py` và `verify_p2.py` đều thoát 0.

```text
A: 635 bảng, 994925 bản ghi, 18636500 ô, bảng có vấn đề 0
B: 67 bảng đích, 41634 bản ghi; ô lệch 25
C: 244 cảnh, 1577 bảng spawns, 40168 dòng, ô lệch 61, bảng lệch số đếm 0
D: 4731 tệp TSV, có vấn đề 0
```

25 ô B là float `pet_ai_strategies.tsv` bỏ trắng cuối. 61 ô C là `script_id` bỏ số 0 đứng đầu. `verify_p2`: rule 142, tiến trình 26, bỏ 9, unknown 401, lệch giá trị 0. Phần G in `tỉ lệ tôi tính khác bảng 15`, neo dưới 95% là 0. Script chỉ in 12 dòng đầu, đều `AbilityExpTable.txt` (bảng 20/20, phép đếm theo id của script là 0/0) và `Mission_NpcDefault.txt` (16/16, cùng 0/0). Đó là căn lát khi id cột đầu không chung, hệ quả X-CA-01, không làm script đỏ. 115 cột `mới ở 2026` khớp từ 95% một cột gốc bị ghi mất, trong đó hai cặp một-một: `Mission_Delivery.txt` 29 với gốc 28 (479/497), `Mission_LootItem.txt` 52 với gốc 51 (234/239).

T9 đạt. `lint_names.py` thoát 0. `--stats`:

```text
shared: cột 17247, chưa tên 14657, nhãn rỗng 14516, chỉ chữ Hán 140, ASCII và chữ Hán 1, chỉ ASCII 0
server: cột 2172, chưa tên 283, nhãn rỗng 6, chỉ chữ Hán 277, ASCII và chữ Hán 0, chỉ ASCII 0
scenes: cột 95, chưa tên 5, nhãn rỗng 0, chỉ chữ Hán 4, ASCII và chữ Hán 0, chỉ ASCII 1
```

`kiem/thieu.py` `scan_machine_names`: `M1/M2 còn column_n: 0`. `scan_cells`: 4015 tệp, 1097688 bản ghi, 22019096 ô, int lệch 0, float có trắng 0.

T10 đạt. `diff_tables.py "<tlbb>" SERVER --check` thoát 0. Cùng năm tổng mục 3: cặp 106, ids_2026 354614, ids_legacy 62374, common 61522, only_2026 293092, only_legacy 852, dòng tham chiếu 55, dòng có giá trị thiếu 6. `refs/shared.tsv` 25 dòng, `refs/server.tsv` 24, `refs/scenes.tsv` 6.

T11 đạt. Ba preset dựng thoát 0 rồi `ctest` 3/3. gcc-debug: exe đã mới hơn `lint.cpp`, chỉ dựng lại `header_check`; `layers` 0,17, `content_tests` 0,01, `server_data_lint` 6,62. clang-asan: liên kết lại `thienlong_lint`; 0,18 / 0,02 / 68,89. msvc-release qua `dev.bat`: dịch lại `lint.cpp` và cả hai exe; 0,17 / 0,11 / 2,23. Log dựng không có dòng cảnh báo.

T12 đạt. `check.py` trên bốn tệp C++ mới: `4 tệp, 0 lỗi.`

T13 đạt. `build\msvc-release\thienlong_lint.exe --root SERVER --refs TOOLS\server\refs --report build\p1-dot3-r\cpp-coverage.tsv` thoát 0 trong 2278 ms. `lỗi` là 0. `tệp` 4015, `bản ghi` 1097688, `ô` 22019096, `dòng tham chiếu` 55. Sau khi bỏ dòng `#`, báo cáo trùng `table_ref_coverage.tsv` từng byte, 5662 byte.

T14 đạt. So với `moc/git-status.txt`, thêm `M cmake/GameLayers.cmake`, `?? SRC/content/`, `?? SRC/linttool/`, `?? tests/content_tests.cpp`. `git diff --no-index` hai tệp CMake với bản `moc/` chỉ có dòng thêm. `secrets.local.toml` không nằm trong `git status`. Không có tệp tên `Account.txt` dưới `SERVER/`, `TOOLS/server/` và `docs/giao-viec/P1-DOT-3/`.

Probe riêng, không dùng test của vai: `python -B -W error build/p1-dot3-r/phan.py` thoát 0. Cây giả nằm trong `build/p1-dot3-r/phan/`.

- R-A-01 ĐÃ SỬA. T1 và T2 xanh. `classify("试探列甲", "Pet.txt")` ra `column_1`, luật `failed`.
- R-A-02 ĐÃ SỬA. `classify`: `EquipBase.txt` `冰抵抗` ra `cold_resist`; `GemInfo.txt` `减少冰冻迟缓时间` ra `cold_slow_reduction`. Hai dòng basis `GameDefine_Item.h` `COLD` không còn tên `ice`. Scope `ItemSegValue.txt` vẫn `ice_resist` vì dòng `direct` của B thắng scope rỗng, đúng mục 5.1. Không sửa tệp của B.
- R-A-03 ĐÃ SỬA. Probe cha `tables/missing.tsv` không có, `known_missing` là 1: thoát 1, `dòng tham chiếu: 0`, `refs/a.tsv:4: mẫu không khớp tệp nào`.
- R-B-01 ĐÃ SỬA. `number_repeated` ra `clientres_1`, `clientres_2`. Dòng tên `scenes.tsv` sau T3 có hai tên đó, không còn `column_9`. `M1/M2 còn column_n: 0`.
- R-C-01 ĐÃ SỬA. Probe `known_missing` trống, exe gcc-debug thoát 1, in `known_missing không phải số nguyên` và `dòng tham chiếu: 1`.
- R-C-02 ĐÃ SỬA. Probe hai cha cùng tên cột `id` khác kiểu, mỗi dòng trỏ đúng cha: exe thoát 0, `lỗi: 0`, `dòng tham chiếu: 2`.
- X-AB-01 ĐÃ SỬA. `_parse_scene` trên `SceneInfo.ini` có `#extra=9` ném `SceneInfo.ini:12: khoá lạ #extra`. `export_rules` trên `Demo.ini` in `Demo.ini:3: chưa có dòng cho [Global] #extra`. T2 gồm hai ca này và thoát 0.
- X-AB-02 ĐÃ SỬA. `_shop_columns` ra `odds_1`, `odds_2`, note không có `?`. Dòng tên `random_shop_goods.tsv` sau T3 có hai tên đó.
- X-AB-03 ĐÃ SỬA. `_annotate_drop_code` ghi câu mã vào cột 2, 4, 200, 202, không đụng cột 3. `drop_packages.tsv` trên đĩa có `item_100_id nằm ngoài vòng` ở bốn cột đó. Tên cột không đổi.
- X-BC-01 ĐÃ SỬA. Probe dòng dữ liệu `#3364`, cha chỉ có `1`, `known_missing` 0: exe thoát 1, `ô đầu bắt đầu bằng #`, `bản ghi: 3`.
- X-BC-02 ĐÃ SỬA. Probe `scenes/a/spawns.tsv` kiểu `int` và `scenes/b/spawns.tsv` kiểu `float`, ô đều `1`: exe thoát 1, có chữ `float` hoặc `khác kiểu`.
- X-BC-03 ĐÃ SỬA. `scene_refs.main` trên `Mystery() .. ".ini"` và `"shuilao_monster_" .. Mystery() .. ".ini"`: cả hai `unresolved`, `files_on_disk` rỗng, không ra `*.ini`. `shuilao_monster_99.ini` là `unpointed`. Cây thật sau T3 vẫn `863 / 80 / 221 / 180`.
- X-BC-04 ĐÃ SỬA. Script nêu `plain_monster_10.ini`, đĩa có `Plain_monster_10.ini`: `files_on_disk` là 1, dòng cấp `same`.
- X-BC-05 ĐÃ SỬA. Probe `tables/a.TSV` cạnh `scenes/keep.tsv`: exe thoát 0, `tệp: 2`, `lỗi: 0`.
- X-BC-06 ĐÃ SỬA. Cảnh giả hai quái, ô `9999999999` ở dòng 26: `demo/spawns.tsv:26: số vượt int32`, không phải dòng 1.
- X-CA-01 ĐÃ SỬA. T1 gồm `test_leading_id_keeps_embedded_legacy_names`. Sau T3, `life_skill_proficiency.tsv` giữ `对象名称$1$`, `基础熟练度`, `AbilityId` thành `life_skill_id`; `npc_default_dialogue.tsv` giữ `ScriptId` thành `script_id` và `NpcName$1$` thành `npc_name`. Ô dữ liệu đầu của bảng độ thuần thục vẫn bắt đầu `1`, `铜矿脉`, và có `20003001`.
- X-CA-02 ĐÃ SỬA. Probe byte `0xFF` ở dòng 4: `Pet.txt:4: byte UTF-8 hỏng`. Id `1e39`: `Pet.txt:3: số thực không vừa float32`. Dòng source của một cặp là `public_config/Pet.txt (1 tệp)`; bảng phủ là `…/refs/*.tsv (1 tệp)`.
- X-CA-03 ĐÃ SỬA. `--refs` trỏ thư mục không có: thoát 1, `thư mục refs không tồn tại`, không in `cặp:`.
- X-CA-04 ĐÃ SỬA. Con `int` trỏ cha `text`, cùng ô `7`: Python thoát 1, `dòng tham chiếu: 1`, `hai cột khác kiểu`, và vẫn ghi một dòng phủ. Sau khi bỏ dòng `#`, dòng đó trùng báo cáo của exe. Exe cũng thoát 1.

Trạng thái cuối: T1 tới T14 đều đạt trên mã sau mọi lần sửa. Mười chín finding đều ĐÃ SỬA. Không có BÁC, không còn CÒN MỞ, không có TRANH CHẤP.
