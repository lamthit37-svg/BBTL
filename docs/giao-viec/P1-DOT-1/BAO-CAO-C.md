# Báo cáo vai C — xuất cảnh bản 0859602

## 1. Tệp đã tạo

- `TOOLS/server/export_scene.py`: lệnh xuất `Public/Scene` thành `SERVER/scenes/<cảnh>/`.
- `TOOLS/server/scene_read.py`: đọc ini theo `Ini.cpp` và bảng chữ theo `OpenFromMemoryImpl_Text`.
- `TOOLS/server/scene_classify.py`: mỗi tên tệp một loại, theo mục 7 của phụ lục.
- `TOOLS/server/test_export_scene.py`: test `unittest`, dữ liệu giả trong `build/p1-c/`, dữ liệu thật khi có biến môi trường.
- `TOOLS/server/columns/scenes/*.tsv`: 12 tệp cột (spawns, areas, patrols, grow_points, grow_point_rules, wild_pets, platforms, portals, buses, spawn_operates, spawn_operate_values, spawn_levels).
- `SERVER/scenes/<cảnh>/`: 256 cảnh. `scene.toml` sinh bằng `config_style.render`. `walk.nav` là bản chép byte của `.nav`. Bảng TSV đi qua `tsv_file.write_table`.

## 2. Đã kiểm

Đỏ, trước khi có mã xuất. Lệnh:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_scene.py"
```

Exit code 1. `Ran 19 tests in 0.071s`, `FAILED (failures=18, skipped=1)`. Lý do: `export_scenes` chưa ghi bảng. Một ca:

```text
AssertionError: False is not true : ['export_scene.py:1: chưa xuất cảnh']
```

Ca bỏ qua là test dữ liệu thật vì chưa đặt `THIENLONG_LEGACY_ROOT`.

Xanh, sau khi có mã, đã đặt cả hai biến môi trường. Cùng lệnh discover. Exit code 0. `Ran 19 tests in 3.925s`, `OK`. Test thật xuất vào `build/p1-c/`, kiểm 3.251 tệp, `luoyang/walk.nav` dài 1.638.404 byte, rồi lint mọi `scene.toml`.

Xuất vào đích thật:

```text
python -W error TOOLS/server/export_scene.py "<THIENLONG_LEGACY_ROOT>" SERVER/scenes
```

Exit code 0. Thời gian 3,36 giây. Output ở mục 3.

`--check` cùng tham số: exit code 0, in cùng các số, không ghi đè. Không đo byte trước và sau lệnh này.

Lint mọi `scene.toml` bằng `lint_config.main` (cùng hàm với `lint_config.py`):

```text
256 tệp sạch, 4691 cài đặt đều có chú thích và thẳng cột
```

Exit code 0. Mẫu ba tệp qua CLI `python -W error TOOLS/server/lint_config.py SERVER/scenes/luoyang/scene.toml SERVER/scenes/dali/scene.toml SERVER/scenes/PCity/scene.toml`: `3 tệp sạch, 39 cài đặt đều có chú thích và thẳng cột`, exit code 0.

Đối chiếu `monstercount` với số dòng `spawns.tsv`: 238 tệp, 0 lệch. Lệnh đọc `# source` rồi `parse_ini`, exit code 0.

Sau khi xoá `import io` không dùng, discover không đặt biến môi trường: exit code 0, `OK (skipped=1)`.

## 3. Số đo

Tệp nguồn `Public/Scene`: 3.251, đúng một loại.

| Loại | Số tệp |
|---|---|
| scn | 244 |
| nav | 231 |
| path | 234 |
| stall | 73 |
| object_region | 28 |
| monster | 237 |
| monster_by_level | 1.171 |
| monster_group | 153 |
| monster_bare | 2 |
| monster_entrance | 18 |
| monster_level | 2 |
| area | 233 |
| patrol | 229 |
| growpoint | 228 |
| growpoint_setup | 61 |
| pet | 63 |
| platform | 39 |
| portal | 2 |
| bus | 1 |
| dropped (`testdata.txt`, `testsetup.txt`) | 2 |

1.171 + 153 + 2 + 18 = 1.344 tệp quái theo cấp hoặc lối vào.

Cảnh: 256 thư mục. 244 có `.scn`. 12 không có `.scn`: `_pingpan_40`, `_pingpan_55`, `_pingpan_70`, `_pingpan_85`, `chuangjian`, `xuanren`, `gongdishaolinmis`, `jishiemeimis`, `yamentianshanmis`, `登陆`, `选人`, `选人11`.

`walk.nav`: 249 tệp, 144.626.468 byte. Nhiều hơn 231 vì một `.nav` được chép vào mỗi cảnh có trỏ tới nó. `luoyang/walk.nav` là 1.638.404 byte, đầu tệp 640 x 640.

Dòng đã ghi. Tệp gốc dùng chung được tính mỗi cảnh một lần.

- spawns 17.446
- spawns_level 20.928
- spawns_group 1.530
- spawns_entrance 234
- spawns_alt 30
- spawn_levels 188
- areas 382
- patrols 2.996
- grow_points 7.885
- grow_point_rules 210
- wild_pets 3
- platforms 107
- portals 8
- buses 6
- spawn_operates 423
- spawn_operate_values 2.410

Cột trong 12 tệp cột: 95. 91 cột có tên lấy từ khoá hoặc từ chỗ mã 2008 gán. 4 cột còn tên tạm `column_2` tới `column_5` ở `grow_point_rules.tsv`. 5 cột có `?` trong `note`: bốn cột đó và `cshop`.

Biến đổi đã đếm, không theo từng bảng vì công cụ chỉ in số gộp:

- `direction_kept_as_integer` 40.275: giữ số nguyên `dir`, không đổi sang radian. Không đổi chữ so với tệp.
- `duplicate_guid` 5.190: hai dòng quái cùng guid, cả hai đều ghi.
- `distinct_duplicate_key` 44: 21 tệp `jiaochang*_monster*.ini` mỗi tệp lặp `value11` và `valueex11` khác giá trị (42), cộng `paopao13_1` ở `meiling_patrolpoint.ini` và `paopao11_1` ở `miaojiang_patrolpoint.ini`. Giá trị đầu là giá trị `FindData` đọc. Giá trị sau vẫn có: thêm dòng trong `spawn_operate_values.tsv`, hoặc cột `speech_unread`.
- `int_not_canonical` 65: ô kiểu int không phải dạng `-?\d+` không có số 0 thừa. Giữ nguyên văn, không đếm được từng tên cột trong lần chạy này.
- `level_replaced` 13: cột `level` của `spawns.tsv` khác dòng quái gốc, lấy từ `*_monster_level.ini`.
- `level_without_spawn` 188: `petisland_2_monster.ini` có `monstercount=0`, `petisland_2_monster_level.ini` có 188 section. Ghi `spawn_levels.tsv`, không bịa dòng quái.
- `padded_count` 24: `PATROLPOINTNUM` có cách trước `;` hoặc tab. Số đếm lấy sau khi cắt, đúng `atoi`.
- `point_outside_declared` 1: `petisland_1_patrolpoint.ini` có `settletime34` trong tuyến chỉ 24 điểm. Thêm một dòng `point_index=34`, không đoán là điểm 23.
- `same_key_repeats` 1: `yanhu.scn` khai `eventfile` hai lần, cùng giá trị.
- `trailing_lf` 30: dòng cuối của 30 tệp `.scn` là `petfile` kết thúc bằng LF, không CR. Khoá này mã 2008 không đọc.
- `zero_count_but_sections` 4: `xingxiu_monster_10.ini` và `xingxiu_monster_110.ini` có `operatecount=0` và `datacount=0` nhưng vẫn có `[operate0]` và `[data_def0]`. Mã không đọc. Vẫn xuất.

Ô ini ghi ra là phần `Ini::ReadText` giữ: cắt tại tab, `;` hoặc `]`. Chú thích sau `;` không tính là mất ô. Bảng chữ grow point: 7.885 và 210 dòng, 0 dòng rỗng, 0 dòng `#`, 0 dòng thiếu ô, 0 dòng thừa ô. Số thực giữ nguyên văn (`1.50` không rút thành `1.5`).

Thời gian xuất đầy đủ: 3,36 giây.

## 4. Chưa kiểm

- Không chạy exe máy chủ 2008 để so số quái sau `LoadMonster`. Không build được exe đó trong đợt này.
- Không băm hai lần cả cây `SERVER/scenes` để chứng minh từng byte. Test giả đã so từng byte hai lần xuất. Lần `--check` sau lần ghi in cùng số đếm.
- 65 ô `int_not_canonical` chưa liệt kê từng tệp.
- `.path`, `.stall`, `.ObjRegion` không đối byte vì không chép. `StallInfoManager::Load` có trong mã 2008; đề bài cấm chép ba định dạng này.
- `MONSTER_FILE::Do` dùng `rand()`. Không áp vào bảng. Luật nằm ở `spawn_operates.tsv`.

## 5. Giả định

- Cảnh có `.scn` lấy tên từ thân tệp. Tệp không được scn nào trỏ thì gắn vào thân `.scn` dài nhất mà tên bắt đầu bằng thân đó cộng `_` hoặc `.`. Không khớp thì thành cảnh không scn, `scene_file = 0`.
- Tệp được nhiều `.scn` trỏ thì chép vào từng cảnh. `luoyangsnow.scn` dùng quái và lưới của `luoyang`. Các `PCity*.scn` dùng `PCity.nav`.
- Khoá lặp: giá trị đầu, giống `FindData`. Giá trị sau khác thì không bỏ.
- `dir` giữ số nguyên. Mã nhân với pi/18 rồi cộng pi/2.
- Cỡ lưới là hai `u16` đầu `.nav`. Mỗi ô 4 byte, đúng `fread` của `PathFinder::ReadNavMap` (`sizeof(_NAVMAP_HEAD)` là 4). Cả 231 tệp khớp công thức `4 + rộng * cao * 4`.
- `petfile` trong `Scene::SetLoadData` đang bị chú thích. `PetManager::LoadPet` không có thân. `portal.ini` và `bus.ini` không thấy hàm nạp. Vẫn xuất, `note` ghi mã không đọc.
- Tên cột grow point lấy theo chỉ số mã đọc, vì dòng tên của `*_growpoint.txt` chỉ lặp lại `INT` và `FLOAT`.

## 6. Lệch quy tắc

- Đề bài liệt kê đích `spawns.tsv`, `spawns.level_<cấp>.tsv`, `spawns.<entrance>.tsv`. Đĩa còn `[setting]`, `[operateN]`, `[data_defN]`. Thêm `spawn_operates.tsv`, `spawn_operate_values.tsv`. Cảnh có nhiều tệp quái thì tên rút thành `ops.<hậu tố>.tsv` và `vals.<hậu tố>.tsv` để dòng `scene.toml` không quá 110 cột.
- `<s>_<n>monster_<cấp>.ini` trùng cấp với `<s>_monster_<cấp>.ini` (9 cảnh, ví dụ `guangmingdong`). Ghi `spawns.n<n>_level_<cấp>.tsv`, 1.530 dòng. Không gộp vì hai tệp khác `type` dù có guid giống nhau.
- `tianshan_1_monster30.ini` và `tianshan_1_monster_30.ini` khác hash. Tệp thiếu gạch dưới thành `spawns.level_30.alt.tsv`. `tianshan_1_monster320.ini` không đụng tên nên là `spawns.level_320.tsv`. 30 dòng alt.
- Đề bài nói tệp không gắn cảnh là lỗi. 45 tệp không có `.scn` và không được scn trỏ (trừ 2 tệp test đã loại). Nếu thoát 1 thì không xuất 244 cảnh kia. Đã xuất 12 cảnh mồ côi và ghi `scene_file = 0`.
- Mục 7 lấy "id trùng" làm đầu vào phải từ chối. Guid quái trùng là dữ liệu thật, `LoadMonster` không loại. Giữ cả hai dòng và đếm 5.190.
- `PCity_Level_1.path` tới `PCity_Level_5.path` không có trong phụ lục. Phân loại `.path`, không chép, nhiều khoá `path_file`, `path_file_2`, ...

## 7. Tài liệu khác đĩa

- Phụ lục cộng các hàng mục 7 ra 3.269 vì 18 tệp `PCity_monster_<lối vào>.ini` nằm cả trong hàng 1.344 và hàng riêng 18. Đĩa có 3.251. 1.344 = 1.171 + 153 + 2 + 18.
- `petisland_2_monster_level.ini` không thể thành cột `level` của `spawns.tsv`: tệp quái gốc có 0 quái.
- `SceneInfo.ini` có 923 khoá `file`, không có `chuangjian`, `登陆`, `选人`, `选人11`, `xuanren`, ba tệp `*mis`, hay `_pingpan_40`. Bốn tệp `_pingpan_<số>_monster.ini` không phải `_pingpan_1_monster_<cấp>.ini`.
- Phụ lục nói `paths.bin`, `stalls.bin`, `object_regions.bin`. Đề bài bảo chỉ đếm, không chép. Làm theo đề bài.
- `GrowPointManager` đọc cột 0, 1 và 3 của `*_growpointsetup.txt` (cột 3 bằng `atoi` vào khoảng bổ sung). Dòng tên là `类型`, `数量`, `每次生成数量`, `生成函数`, `种子补充的间隔时间`, `补充时间随机增量`. Cột 4 mới là khoảng 3.900.000 trong mẫu `bashu_1`. Không đổi chỗ cột.
- `LuaFnSetSceneLoad_Pet` gọi `SetSceneLoad_GrowPointData`, không gọi `LoadPet`.

## Yêu cầu với hợp đồng của L

Không sửa `tsv_file.py`, `config_style.py`, `lint_config.py`, `table_names.tsv`. Ba tệp đó đủ để ghi. `table_names.tsv` không có cây cảnh, đúng như hợp đồng đã ghi.

Khi `build_data.py` gom `SERVER/scenes`, cần nhận các tên không có trong danh sách đích của đề bài: `spawn_operates.tsv`, `spawn_operate_values.tsv`, `ops.*.tsv`, `vals.*.tsv`, `spawn_levels.tsv`, `spawns.n<số>_level_<cấp>.tsv`, `spawns.level_<cấp>.alt.tsv`, `spawns.<lối vào>.tsv`. Nhờ chốt năm điểm ở mục 6 (cảnh không scn, guid trùng, tên nhóm dính, hậu tố alt, tệp level không có dòng quái) trước khi coi đó là lỗi tích hợp.
