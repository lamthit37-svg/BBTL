# Báo cáo vai B — P1 đợt 1

## 1. Tệp đã tạo

- `TOOLS/server/import_legacy.py` — đọc bảng chữ và ini của bản 0859602, ghi TSV.
- `TOOLS/server/test_import_legacy.py` — test `unittest` của công cụ, gồm một ca dữ liệu thật.
- `SERVER/tables/server/*.tsv` — 69 bảng. 67 bảng là đích `owner=B`, `fate=table` trong `table_names.tsv`. Thêm `script_index.tsv` và `monster_ai_scripts.tsv` (mục 8 của phụ lục; chưa có dòng trong hợp đồng, xem mục 8 báo cáo này).
- `TOOLS/server/columns/server/*.tsv` — một tệp cột cho mỗi bảng, cùng tên.

## 2. Đã kiểm

Lệnh chạy ở gốc dự án. Dữ liệu thật: `THIENLONG_LEGACY_ROOT=C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`.

Đỏ, khi `import_legacy.py` mới chỉ là stub trả về không ghi tệp, chưa đặt biến môi trường:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
```

Exit code 1. `Ran 19 tests in 0.017s`. `FAILED (failures=10, errors=7, skipped=1)`. Ca dữ liệu thật bị bỏ qua vì thiếu biến môi trường. Một ca (`test_check_writes_nothing`) xanh trên stub vì stub không ghi tệp. Các ca còn lại đỏ vì assertion, không phải lỗi import. Ví dụ:

```text
FAIL: test_reject_extra_cell
AssertionError: [] is not true

ERROR: test_int_float_string_and_padding
FileNotFoundError: build\p1-b\unit\test_int_float_string_and_padding\out\sample.tsv
```

Xanh, sau khi có bộ đọc, đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT`:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
```

Exit code 0. `Ran 19 tests in 2.902s`. `OK`. Không ca nào bị bỏ qua.

Xuất dữ liệu thật:

```text
python -W error TOOLS/server/import_legacy.py "<THIENLONG_LEGACY_ROOT>" SERVER/tables/server
```

Exit code 0. Lần đo đồng hồ PowerShell: 1895 ms. Lần gọi lại trong tiến trình Python: 1.856 s, không lỗi. SHA-256 của toàn bộ byte các `.tsv` (kèm đường dẫn tương đối, thứ tự tên) trước và sau lần ghi thứ hai trùng nhau.

- `SERVER/tables/server`: 69 tệp, `5b63e1763fe19ac0921f52b74222ddcb551ab5b4a0e36811375c08ced737eebb`
- `TOOLS/server/columns/server`: 69 tệp, `0ca2fd175bcfb23025ac3cbdee78340d475c8d4bbc480137cf8154bdad6f6006`

Danh sách từng bảng, số bản ghi, số cột `?` và từng biến đổi nằm ở stdout của lệnh xuất. Bản UTF-8 đã chép vào `build/p1-b/summary.txt` trong lúc đo.

Ca dữ liệu thật trong test so độc lập: số dòng `effects.tsv` bằng số dòng dữ liệu của `StandardImpact.txt` sau khi bỏ dòng `#` và ô đầu rỗng; `item_segment_values.tsv` có 129 cột và còn ô `15051`; dòng đầu `loot_box_entries.tsv` là `default`, vật phẩm `10500002`, ô dự trữ rỗng thành `0`; `scenes.tsv` có 923 dòng và dòng 0 tên `洛阳`; số dòng `script_index.tsv` và `monster_ai_scripts.tsv` bằng số dòng gốc bắt đầu bằng chữ số rồi dấu `=`.

## 3. Số đo

Nguồn đọc, đếm từ `table_names.tsv` (`owner=B`, `fate=table`) cộng hai tệp `.dat`:

- 113 tệp trong bảng tên: 93 `.txt`, 20 `.ini`. `SceneInfo.ini` và `SystemInfo.ini` mỗi tệp thành hai bảng.
- Thêm `Public/Data/Script.dat`, `Public/Data/AIScript.dat`.
- 69 bảng, 46.210 bản ghi, 2.234 cột. Tên cột lấy từ định danh ASCII: 420. Còn `?`: 1.814.

Biến đổi so với nguyên văn, cộng từ stdout của lệnh xuất. Một bảng một lần; hai bảng cùng một hiện tượng thì cộng hai lần và được ghi rõ bên dưới.

- Ô `INT` viết khác nguyên văn (`atoi`, ô rỗng thành `0`, `12abc` thành `12`, số 0 đệm đầu): 6.259. Trong đó `loot_box_entries.tsv` 4.775, `script_index.tsv` 1.079, `effect_collections.tsv` 238, `gacha_item_pools.tsv` 141, `mentor_exp_rewards.tsv` 16, `item_segment_rates.tsv` 10.
- Dòng bỏ vì bắt đầu bằng `#`: 70. `effects.tsv` 44, `notices_on_login.tsv` 11, `notices_by_date.tsv` 9, `notices_by_weekday.tsv` 4, `gacha_machines.tsv` 1, `gacha_outputs.tsv` 1.
- Dòng bỏ vì ô đầu rỗng: 14. `pet_mutant_quality_odds.tsv` 8, `loot_box_entries.tsv` 6.
- Ô thừa rỗng bị bỏ (tab cuối hoặc kiểu trống không có chữ): 59. `pet_mutant_quality_odds.tsv` 32, `effects.tsv` 17, `item_segment_rates.tsv` 10.
- Ô dưới kiểu trống nhưng có chữ, được giữ thành cột `text`: 64, tất cả ở một dòng của `item_segment_values.tsv`.
- Cắt chú thích ini (phần sau tab hoặc `;` mà `Ini::ReadText` không lấy): 3.124. `random_shop_goods.tsv` 2.167, `sect_base_values.tsv` 420, `monster_ai_types.tsv` 341, `scheduled_events.tsv` 181, `scenes.tsv` 10, `scene_hosting.tsv` 3, `rolling_announcements.tsv` 2.
- Đổi `\` thành `/` trong đường dẫn script: 4.307, mọi dòng `script_index.tsv`.
- Cắt mô tả sau dấu cách trong tên tệp AI: 269, mọi dòng `monster_ai_scripts.tsv`. Ví dụ gốc `0=script0.ai =生砍`, giá trị ghi ra `script0.ai`.
- Dòng ngoài số khai báo, vẫn ghi: 441 lượt đếm. `scenes.tsv` và `scene_hosting.tsv` mỗi bảng 200 (cùng 200 cảnh, `scenenumber=723`, section là `scene0` tới `scene922`). `scheduled_events.tsv` 30 (`huodongcount=0`). `rolling_announcements.tsv` 10 (`broadcount=0`). `random_shop_goods.tsv` 1 (`RandShop/shide.ini` ghi `Total=9` nhưng có `Merchandise0` tới `Merchandise9`).
- Ô đệm vì dòng thiếu ô, và dòng trống bị bỏ: 0 trên dữ liệu thật. Ca này chỉ thấy ở test giả.

`FLOAT` của bảng chữ giữ nguyên văn, không đổi thành chuỗi `atof`. Cột khai `STRING` hoặc cột ini không có `ReadInt` trong mã 2008 mà mọi ô đều là số thập phân nguyên: không đổi kiểu. Các bảng có cột như vậy, đếm từ dòng `cột text toàn số` của stdout: `sect_attribute_growth.tsv` 50, `item_attribute_value_ranges.tsv` 200, `effects.tsv` 22, `scheduled_events.tsv` 13, `flight_maps.tsv` 4, `random_shop_goods.tsv` 3, `life_skill_attribute_modifiers.tsv` 2, `death_penalties.tsv` 2, `scenes.tsv` 2 (`clientres`, `pvp_ruler`), `rolling_announcements.tsv` 2, `sect_task_rewards_by_level.tsv` 1, `effect_atoms_legacy.tsv` 1.

`SkillObjData_V1.txt` chỉ có dòng kiểu và dòng tên. `skill_objects.tsv` có 0 bản ghi.

`script_index.tsv`: 4.307 dòng. `monster_ai_scripts.tsv`: 269 dòng.

## 4. Chưa kiểm

- Không chạy exe máy chủ 2008. Exe trong bản chạy bị đóng gói. Ngữ nghĩa lấy từ mã nguồn đã đọc (`TLBB_DBC.cpp`, `Ini.cpp`, `Config.cpp`, `GameTable.cpp`, `WorldTable.cpp`, `FileDataMgr.cpp`).
- Không gọi `msvcrt.atoi` từng ô. Mọi ô `INT` của dữ liệu thật vừa `int32` có dấu; không có ca tràn nên nhánh từ chối tràn chưa gặp dữ liệu thật.
- Không so bit `atof` vì ô `FLOAT` giữ nguyên văn.
- Không có test cho dòng dài hơn 10239 byte. Lần xuất này không gặp dòng đó.
- `python -W error` chỉ với `test_import_legacy.py`. Không discover cả `TOOLS/server`.
- Không mở `Account.txt`, không mở `SERVER/config/secrets.local.toml`.

## 5. Giả định

- Ô `INT` là `atoi` của C trên miền `int32`. Ngoài miền thì lỗi, không bão hoà.
- Kiểu trống chỉ được phép là hậu tố của dòng kiểu. Lỗ trống xen giữa là lỗi. Dữ liệu thật không có lỗ xen giữa.
- Ô thừa khác rỗng nằm sau hết dòng kiểu là lỗi. Ô có chữ nằm dưới kiểu trống ở cuối dòng kiểu thì giữ, kiểu `text`, ghi `?`.
- Khoá `ReadInt` trong mã 2008 ghi số đã `atoi`. Khoá mã không đọc, và tệp không có hàm nạp (`SystemInfo.ini`, `RandShop`, `MountFlightMaps.txt`), giữ chuỗi `ReadText`, không đoán `int`.
- `scene_id` là chỉ số `sceneN`. Mã 2008 gán `m_SceneID = i`, không đọc một khoá id.
- Khoá tệp `serverid` là trường mã tìm bằng `serverId`. Ghi chú trong tệp cột, vẫn đọc giá trị trên đĩa.
- Section vượt số khai báo vẫn xuất. Thiếu section trong khoảng đã khai thì lỗi.
- `CFileDataMgr::Init`: magic `MGR_TXT`, bỏ byte cuối nếu là xuống dòng, bỏ chú thích `;`, `atoi` id, `\` thành `/`, cắt tại dấu cách đầu tiên.
- Dòng đầu `MountFlightMaps.txt` (`MountFlightMaps` và `1`) không phải bản ghi. Giá trị `1` nằm trong chú thích cột `column_0`.
- Id trùng xét trong từng tệp gốc, trên cột 0 sau khi đổi như bộ đọc, không xét chéo các `box_key`.
- Tên cột: định danh ASCII thì `snake_case`. Còn lại `column_<chỉ số>` và `?`. Không dịch tiếng Trung.
- `broadtime`, `broadcount`, `huodongcount` lặp trên mỗi dòng vì hợp đồng không có bảng thứ ba cho ba số này.
- Không dịch `StringTable.txt` sang tiếng Việt. Không sinh mười ba tệp TOML luật chơi.

## 6. Lệch quy tắc

- Đã xuất `script_index.tsv` và `monster_ai_scripts.tsv` dù `table_names.tsv` không có hai tệp gốc. Đề bài mục 5 (nguồn của B) và mục 8 của phụ lục nêu đích. Hợp đồng của L không có cây `Public/Data`. Yêu cầu sửa hợp đồng ở mục 8.
- Dùng `tsv_file._owned_tool` trước khi gọi `prepare_directory`. Hai thư mục đích phải được xét tệp lạ trước khi xoá thư mục nào. Hàm công khai xoá ngay trong một thư mục.
- `scenes.tsv` và `scene_hosting.tsv` cùng đếm 200 dòng ngoài `scenenumber`. Đó là một tập cảnh, ghi ở cả hai bảng.

## 7. Tài liệu khác đĩa

- Phụ lục nói 924 cảnh. Đĩa: 923 section `scene0`..`scene922` và một section `system`. `scenenumber=723`.
- `StandardImpact.txt` 9.906 dòng tệp = 2 dòng đầu + 44 dòng `#` + 9.860 bản ghi. Phụ lục ghi 9.906 dòng.
- `Questions.txt`: phụ lục 3.705, bản ghi xuất 3.703. Lệch đúng 2 dòng đầu.
- `StringTable.txt`: phụ lục 314, bản ghi xuất 312. Cùng kiểu lệch.
- `DropBoxContent.txt`: phụ lục 2.036 gói, bản ghi xuất 2.034. Cùng kiểu lệch nếu tệp có đúng hai dòng đầu; chưa đếm riêng số dòng vật lý của tệp này ngoài số bản ghi.
- `MonsterAITable.ini` có `AIPARAM0`..`AIPARAM10` và `DESC`. `AIPARAM_NUMBER` trong mã 2008 là 9 (`0`..`8`). Phụ lục nói 11 tham số. Xuất đủ 11, cột 9 và 10 ghi là mã không đọc.
- `BaseValueTable.ini` có `AINFOTYPE0`..`AINFOTYPE41`. `AINFOTYPE_NUMBER` trong mã là 34. Xuất đủ 42, từ 34 trở đi ghi là mã không đọc.
- `GuildMemberAccess.ini` có `access_type0`..`access_type22`. `GUILD_AUTHORITY_NUMBER` là 8. Xuất đủ 23.
- Mã 2008 gọi `ReadInt(..., "serverId")`. Tệp ghi `serverid`.
- `SystemInfo.ini`, `RandShop\*.ini`, `MountFlightMaps.txt` không có hàm nạp trong cây mã 2008 đã grep.
- `broadcount=0` và `huodongcount=0` trong khi có 10 section `broad` và 30 section `huodong`.
- `SkillObjData_V1.txt` không có dòng dữ liệu.
- Bảng chữ đã đo (`ItemSegValue.txt`, `StandardImpact.txt`, `CreateQualityOfVaryPetTbl.txt`) là CRLF. `MountFlightMaps.txt` là LF, 0 byte CR. Câu "mọi tệp chữ là CRLF" trong đề bài không đúng với tệp này.
- Dòng kiểu `ItemSegValue.txt` có 65 token `INT` và 64 ô kiểu rỗng ở cuối. Một dòng dữ liệu (dòng tệp 272) có chữ ở 64 ô đó, bắt đầu bằng `15051`. Bộ đọc gốc bỏ vì `bIgnoreEmpty` trên dòng kiểu. Phụ lục nói 129 cột. Bảng xuất giữ 129 cột; 64 cột cuối là `text`, ghi `?`.

## 8. Yêu cầu sửa hợp đồng của L

`table_names.tsv` và `tsv_file.TREES` không có `Public/Data`. Đề bài vẫn giao hai tệp này cho B và mục 8 của phụ lục đặt tên đích. Đã xuất, không sửa tệp của L. Cần thêm, nếu L muốn lần tích hợp thấy chúng:

- Một giá trị `tree` mới, đề nghị `public_data`, và `tsv_file.py` phải chấp nhận giá trị đó.
- `public_data`, `Script.dat`, `table`, `tables/server/script_index.tsv`, owner `B`.
- `public_data`, `AIScript.dat`, `table`, `tables/server/monster_ai_scripts.tsv`, owner `B`.

Không cần thêm cột hay hàm của `tsv_file.py` cho phần bảng chữ và ini đã xuất.
