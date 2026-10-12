# Báo cáo vai C — đợt 2

## 1. Tệp đã tạo hoặc sửa

- `TOOLS/server/scene_refs.py`: đọc `LuaFnSetSceneLoad_*` trong `Public/Data/Script`, ghi `scene_load_refs.tsv`.
- `TOOLS/server/test_scene_refs.py`: test giả trong `build/p1-c-refs/`, test dữ liệu thật khi có `THIENLONG_LEGACY_ROOT`.
- `TOOLS/server/scene_attach.tsv`: 45 tệp không gắn được bằng thân tên. Không có dòng `# tool:`.
- `TOOLS/server/export_scene.py`: gắn 10 tệp `scene_set`, đếm 35 `client_only`, đổi tên `ops.`/`vals.`, đưa chú thích TOML dài lên dòng trên, rút dòng quá 120 và thêm kiểu còn thiếu.
- `TOOLS/server/test_export_scene.py`: test tên mới, bộ script, tệp lạ vẫn là lỗi; test thật kỳ vọng xuất được.
- `SERVER/tables/server/scene_load_refs.tsv`: 250 dòng lời gọi. `prepare_directory` giữ tệp của `import_legacy.py` (69 tệp cũ còn, thêm 1).
- `SERVER/scenes/`: xuất lại. 244 thư mục. Không còn `ops.*.tsv` hay `vals.*.tsv`.

`scene_classify.py` và `scene_read.py` không sửa.

## 2. Đã kiểm

Đỏ, `scene_refs` lúc bộ giải còn coi nối chuỗi là literal và test đòi `# types:` sai chỗ tab. Lệnh:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_scene_refs.py"
```

Exit code 1. `Ran 5 tests in 0.007s`, `FAILED (failures=2, skipped=1)`. Hai ca: `test_resolves_literal_constant_format_and_skips_comment` không thấy `lvl_monster_*.ini`; `test_attach_shape` không thấy dòng `# types:` bắt đầu bằng tab (dòng đúng là `# types: text` rồi tab).

Xanh, cùng lệnh, đã đặt `THIENLONG_LEGACY_ROOT`. Exit code 0. `Ran 5 tests in 4.332s`, `OK`. Output chỉ có dòng của `unittest`.

Xanh, xuất cảnh:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_export_scene.py"
```

Exit code 0. `Ran 21 tests in 4.551s`, `OK`. Output chỉ có dòng của `unittest`. Test CLI bắt stdout/stderr bằng `subprocess` `capture_output`. Test `scene_refs` gọi `main` qua `io.StringIO`, stderr rỗng.

Cổng mã, không in dòng nào, exit code 0:

```text
python TOOLS/server/lint_py.py TOOLS/server/export_scene.py TOOLS/server/test_export_scene.py TOOLS/server/scene_refs.py TOOLS/server/test_scene_refs.py TOOLS/server/scene_classify.py TOOLS/server/scene_read.py
```

Xuất vào đích thật, 4,36 giây, exit code 0:

```text
python -W error TOOLS/server/export_scene.py "<THIENLONG_LEGACY_ROOT>" SERVER/scenes
```

Lệnh in 289 dòng `int_places` rồi tổng kết. Phần tổng kết:

```text
cảnh: 244
cảnh không scn: 0
tệp nguồn:
  area 233
  bus 1
  dropped 2
  growpoint 228
  growpoint_setup 61
  monster 237
  monster_bare 2
  monster_by_level 1171
  monster_entrance 18
  monster_group 153
  monster_level 2
  nav 231
  object_region 28
  path 234
  patrol 229
  pet 63
  platform 39
  portal 2
  scn 244
  stall 73
bản ghi:
  spawns 17210
  areas 379
  patrols 2996
  spawns_entrance 234
  spawns_set 236
  grow_points 7885
  wild_pets 3
  grow_point_rules 210
  spawns_level 20928
  platforms 107
  spawn_levels 361
  buses 6
  spawn_operates 423
  spawn_operate_values 2410
  areas_set 3
  spawns_group 1530
  portals 8
  spawns_alt 30
biến đổi:
  client_only 35
  direction_kept_as_integer 40275
  distinct_duplicate_key 44
  duplicate_guid 5190
  int_not_canonical 289
  padded_count 24
  point_outside_declared 1
  same_key_repeats 1
  trailing_lf 30
  zero_count_but_sections 4
```

`spawn_levels` 361 = `caoyuan` 173 + `petisland_2` 188. Đợt 1 ghi 188 vì lúc đó chỉ đếm một tệp.

`python -W error TOOLS/server/scene_refs.py "<THIENLONG_LEGACY_ROOT>" SERVER/tables/server` exit code 0. Trước 69 tệp trong `SERVER/tables/server`, sau 70. Output:

```text
lời gọi: 250
chú thích bỏ qua: 5
how:
  constant 48
  format 44
  literal 140
  unresolved 18
```

`ops.*.tsv` và `vals.*.tsv` dưới `SERVER/scenes`: 0 và 0. Thư mục cảnh: 244. `spawns.set_*.tsv`: 7. `areas.set_*.tsv`: 3.

Lint 244 `scene.toml` bằng `lint_config.check_file`: 0 lỗi. Mẫu CLI `luoyang`, `gudi_2`, `_pingpan_1`, `gongdi`: `4 tệp sạch, 135 cài đặt đều có chú thích và thẳng cột`, exit code 0.

`build_data.py --legacy "<tlbb>" --raw "<_raw>" --dest build/p1-c-buildcheck --check` exit code 1 sau 202 giây, dừng ở `export_tables` (vai A đang sửa). Không tạo thư mục đích. Không tới bước cảnh. Lỗi đầu: `EquipBase.txt:732: dòng thừa ô`, `ImpactSEData_V1.txt:765: dòng thừa ô`, rồi các dòng đối chiếu. `export_scene.py` một mình thì thoát 0, như trên.

## 3. Số đo

`Public/Data/Script`: 4.248 tệp `.lua`. Lời gọi `LuaFnSetSceneLoad_*`: 255, trong đó 5 nằm sau `--` và không thành dòng.

| how | Số dòng |
|---|---|
| literal | 140 |
| constant | 48 |
| format | 44 |
| unresolved | 18 |

250 dòng ghi ra. Loại: `map` 83, `monster` 122, `area` 45. Không có loại khác. Năm chú thích là 2 `area` và 3 `monster` (`yezhu_catch.lua`, `yezhu_protect.lua`, `event_diaorubaozang.lua`).

18 `unresolved`, không đoán: trường bảng (`MenpaiInfo.Map`, `FuBen_Data.MapFile`, `fubenData.MapFile`, `FubenTbl.MapFile`), chỉ số (`x600032_g_CopySceneMap[nMenpai]`), biến cục bộ `monsterINI`, và `format( MenpaiInfo.Monster, iniLevel )` khi chuỗi mẫu không phải hằng trong cùng tệp.

Đối chiếu 1.344 tệp quái theo cấp, nhóm và lối vào (`monster_by_level` 1.171 + `monster_group` 153 + `monster_bare` 2 + `monster_entrance` 18). Script trỏ tới khi `resolved` trùng tên, hoặc `how=format` mà mẫu (sau khi đổi `%s`/`%d` thành `*`) khớp và có một mảnh chữ dài ít nhất 8 ký tự. Cảnh script là cảnh có `navmapname` bằng `Map` literal hoặc constant trong cùng tệp script. Không chuyển tệp.

| Kết quả | Số tệp |
|---|---|
| script trỏ tới | 803 |
| không script nào trỏ tới | 541 |
| có trỏ nhưng không suy được Map | 0 |
| lệch cảnh | 20 |

20 tệp lệch, tất cả là `murenxiang_monster_<cấp>.ini` trừ cấp 7 và 9. Thư mục theo tên là `murenxiang`. Script `event/fuben/efuben_2_murenxiang.lua:297` chọn `xingxiu.nav`, và dòng 311 trở đi ghi thẳng `murenxiang_monster_<cấp>.ini`. Cấp 7 và 9 không có lời gọi nên nằm ở danh sách không trỏ.

`scene_attach.tsv`: 45 dòng, không trùng `file`.

| file | fate | scene | evidence |
|---|---|---|---|
| `_pingpan_40_monster.ini` | scene_set | `_pingpan_1` | `event/pingpan/ezhaochen.lua:324` |
| `_pingpan_55_monster.ini` | scene_set | `_pingpan_1` | `event/pingpan/ezhaochen.lua:329` |
| `_pingpan_70_monster.ini` | scene_set | `_pingpan_1` | `event/pingpan/ezhaochen.lua:334` |
| `_pingpan_85_monster.ini` | scene_set | `_pingpan_1` | `event/pingpan/ezhaochen.lua:339` |
| `gongdishaolinmis_area.ini` | scene_set | `gongdi` | `event/shaolin/eshaolin_skill_03.lua:142` |
| `gongdishaolinmis_monster.ini` | scene_set | `gongdi` | `event/shaolin/eshaolin_skill_03.lua:143` |
| `jishiemeimis_area.ini` | scene_set | `jishi` | `event/emei/emei_skill_01.lua:139` |
| `jishiemeimis_monster.ini` | scene_set | `jishi` | `event/emei/emei_skill_01.lua:140` |
| `yamentianshanmis_area.ini` | scene_set | `yamen` | `event/tianshan/tianshan_skill_02.lua:256` |
| `yamentianshanmis_monster.ini` | scene_set | `yamen` | `event/tianshan/tianshan_skill_02.lua:257` |

`ezhaochen.lua` và `ezhaoliu.lua` cùng bốn dòng quái và cùng `LuaFnSetSceneLoad_Map(..., "_pingpan_1.nav")`. Bảng dẫn `ezhaochen.lua`. Yamen đi qua hằng `x228903_g_Monster` và `x228903_g_Exit` trong cùng tệp. Map của bốn cảnh là `navmapname` của `_pingpan_1.scn`, `gongdi.scn`, `jishi.scn`, `yamen.scn`.

Tên xuất: `spawns.set_<thân>.tsv` hoặc `areas.set_<thân>.tsv`. Thân là phần bỏ hậu tố đã biết, nên `_pingpan_40_monster.ini` thành `spawns.set__pingpan_40.tsv` (hai gạch dưới). Bốn tệp quái bình định cộng ba quái mật thất là 7 tệp, 236 dòng `spawns_set`. Ba vùng mật thất là `areas_set`, 3 dòng. `17210 + 236 = 17446` dòng quái và `379 + 3 = 382` dòng vùng, bằng số đợt 1 trước khi tách bucket.

35 dòng `client_only` là đủ tệp của `chuangjian`, `xuanren`, `登陆`, `选人`, `选人11` (mỗi cảnh 7 tệp). `evidence` là lệnh `findstr /s /m /c:"<tên>" Public\Scene\*.scn Server\Config\SceneInfo.ini Public\Data\Script\*.lua`. Đã chạy lệnh đó với `chuangjian.nav`: exit code 1, không in tệp nào. Quét cả 35 tên trong `*.scn`, `SceneInfo.ini` (GBK) và `Script\*.lua`: 0 lần xuất hiện.

## 4. Chưa kiểm

- `build_data.py` cả bốn bước chưa thoát 0. Lần `--check` chết ở `export_tables` của vai A. Chưa chạy lại sau khi A xong.
- Không chạy exe máy chủ 2008.
- 541 tệp không script trỏ tới chưa được người duyệt quyết định có chuyển thư mục hay không. Đề bài cấm tự chuyển.
- Mẫu `format` chỉ khớp khi mảnh chữ dài từ 8 ký tự. Mẫu chỉ còn `*` không được tính là trỏ tới một tệp.

## 5. Giả định

- Hằng chuỗi là một phép gán `tên = "...."` hoặc `local tên = "...."` trong cùng tệp, không nằm sau `--`. Hai giá trị khác nhau thì bỏ hằng đó.
- Nối bằng `..` là `format`. Mảnh không phải chuỗi hay hằng thành `*`.
- `format("mẫu", ...)` lấy đúng chuỗi mẫu. `format(biến, ...)` là `unresolved` nếu biến không phải hằng chuỗi.
- Cảnh của `Map` chỉ lấy từ literal và constant. `Map` là biểu thức thì không suy cảnh.
- Tệp `scene_set` không đi qua luật tên đợt 1. Tệp đã được `.scn` hoặc thân tên gắn thì không đọc `scene_attach`.
- `client_only` chỉ đếm trong `changes`, không tạo thư mục, không đọc nội dung.

## 6. Lệch quy tắc

- Đề ghi 7 tệp script và 38 tệp client. Đo lại: 10 và 35. Bốn quái bình định, hai tệp `gongdishaolinmis`, hai `jishiemeimis`, và hai `yamentianshanmis` (hằng, không phải chuỗi viết thẳng). Năm cảnh đăng nhập là 35 tệp, mỗi cảnh 7. Không gắn `client_only` cho tệp script có trỏ.
- Tên `spawn_operates.<hậu tố>.tsv` dài hơn `ops.`. Chú thích vẫn ngang hàng khi dòng sau khi căn không quá 110. `gudi_2/scene.toml` giữ chú thích ngang hàng. 244 tệp đều qua `lint_config`.

## 7. Tài liệu khác đĩa

- Đề nói 189 dòng chuỗi viết thẳng và 66 dòng biến hoặc `format`, cộng bằng 255 kể cả chú thích. Bộ đọc này: 140 literal, 48 constant, 44 format, 18 unresolved, cộng 5 chú thích là 255. Khác vì nối `"a" .. biến .. ".ini"` không phải literal.
- `LuaFnTbl_Scene.h`: `LuaFnSetSceneLoad_Area`, `_Pet`, `_PatrolPointData`, `_GrowPointSetup` trong mã 2008 đều gọi `SetSceneLoad_GrowPointData`. Tool vẫn ghi `kind` theo tên hàm (`area`), không theo hàm C++ nó gọi nhầm.

## Bảng nợ

| Mã | Trạng thái | Lệnh |
|---|---|---|
| C-01 | Phần cảnh đã trả: `export_scene.py` thoát 0, 0 tệp không gắn, 35 `client_only`, 10 `scene_set` đã xuất. `build_data.py` cả lệnh chưa thoát 0 vì `export_tables` của A. | `export_scene.py` exit 0 ở mục 2. `build_data.py --check` exit 1, không tới cảnh. |
| C-03 | Đã trả trên tệp của C. Tách hàm ở lượt trước (`moc/split-C.txt`). Lượt này hết dòng quá 120 và tham số thiếu kiểu. | `lint_py.py` trên sáu tệp C, exit 0, không in dòng. |
| C-05 | Đã trả. `ops.` và `vals.` còn 0 tệp. Tên là `spawn_operates.<hậu tố>.tsv` và `spawn_operate_values.<hậu tố>.tsv`. | Đếm `ops`/`vals` = 0. `lint_config` 244 `scene.toml`, 0 lỗi. |
| C-06 | Đã trả trên test của C. | Hai lệnh `unittest discover` ở mục 2 chỉ in dòng `unittest`. |

## Không script nào trỏ tới

541 tên, từ `scene_refs.compare_level_files`. Không chuyển thư mục.

bianguan_1_monster_10.ini
bianguan_1_monster_100.ini
bianguan_1_monster_110.ini
bianguan_1_monster_120.ini
bianguan_1_monster_130.ini
bianguan_1_monster_140.ini
bianguan_1_monster_150.ini
bianguan_1_monster_160.ini
bianguan_1_monster_170.ini
bianguan_1_monster_180.ini
bianguan_1_monster_190.ini
bianguan_1_monster_20.ini
bianguan_1_monster_200.ini
bianguan_1_monster_30.ini
bianguan_1_monster_40.ini
bianguan_1_monster_50.ini
bianguan_1_monster_60.ini
bianguan_1_monster_70.ini
bianguan_1_monster_80.ini
bianguan_1_monster_90.ini
bianguan_2_monster_10.ini
bianguan_2_monster_100.ini
bianguan_2_monster_110.ini
bianguan_2_monster_120.ini
bianguan_2_monster_130.ini
bianguan_2_monster_140.ini
bianguan_2_monster_150.ini
bianguan_2_monster_160.ini
bianguan_2_monster_170.ini
bianguan_2_monster_180.ini
bianguan_2_monster_190.ini
bianguan_2_monster_20.ini
bianguan_2_monster_200.ini
bianguan_2_monster_30.ini
bianguan_2_monster_40.ini
bianguan_2_monster_50.ini
bianguan_2_monster_60.ini
bianguan_2_monster_70.ini
bianguan_2_monster_80.ini
bianguan_2_monster_90.ini
bianguan_3_monster_10.ini
bianguan_3_monster_100.ini
bianguan_3_monster_110.ini
bianguan_3_monster_120.ini
bianguan_3_monster_130.ini
bianguan_3_monster_140.ini
bianguan_3_monster_150.ini
bianguan_3_monster_160.ini
bianguan_3_monster_170.ini
bianguan_3_monster_180.ini
bianguan_3_monster_190.ini
bianguan_3_monster_20.ini
bianguan_3_monster_200.ini
bianguan_3_monster_30.ini
bianguan_3_monster_40.ini
bianguan_3_monster_50.ini
bianguan_3_monster_60.ini
bianguan_3_monster_70.ini
bianguan_3_monster_80.ini
bianguan_3_monster_90.ini
bianguan_4_monster_10.ini
bianguan_4_monster_100.ini
bianguan_4_monster_110.ini
bianguan_4_monster_120.ini
bianguan_4_monster_130.ini
bianguan_4_monster_140.ini
bianguan_4_monster_150.ini
bianguan_4_monster_160.ini
bianguan_4_monster_170.ini
bianguan_4_monster_180.ini
bianguan_4_monster_190.ini
bianguan_4_monster_20.ini
bianguan_4_monster_200.ini
bianguan_4_monster_30.ini
bianguan_4_monster_40.ini
bianguan_4_monster_50.ini
bianguan_4_monster_60.ini
bianguan_4_monster_70.ini
bianguan_4_monster_80.ini
bianguan_4_monster_90.ini
guangmingdong_1_monster_10.ini
guangmingdong_1_monster_100.ini
guangmingdong_1_monster_110.ini
guangmingdong_1_monster_120.ini
guangmingdong_1_monster_130.ini
guangmingdong_1_monster_140.ini
guangmingdong_1_monster_150.ini
guangmingdong_1_monster_160.ini
guangmingdong_1_monster_170.ini
guangmingdong_1_monster_180.ini
guangmingdong_1_monster_190.ini
guangmingdong_1_monster_20.ini
guangmingdong_1_monster_200.ini
guangmingdong_1_monster_30.ini
guangmingdong_1_monster_40.ini
guangmingdong_1_monster_50.ini
guangmingdong_1_monster_60.ini
guangmingdong_1_monster_70.ini
guangmingdong_1_monster_80.ini
guangmingdong_1_monster_90.ini
guangmingdong_2_monster_10.ini
guangmingdong_2_monster_100.ini
guangmingdong_2_monster_110.ini
guangmingdong_2_monster_120.ini
guangmingdong_2_monster_130.ini
guangmingdong_2_monster_140.ini
guangmingdong_2_monster_150.ini
guangmingdong_2_monster_160.ini
guangmingdong_2_monster_170.ini
guangmingdong_2_monster_180.ini
guangmingdong_2_monster_190.ini
guangmingdong_2_monster_20.ini
guangmingdong_2_monster_200.ini
guangmingdong_2_monster_30.ini
guangmingdong_2_monster_40.ini
guangmingdong_2_monster_50.ini
guangmingdong_2_monster_60.ini
guangmingdong_2_monster_70.ini
guangmingdong_2_monster_80.ini
guangmingdong_2_monster_90.ini
gudi_1_monster_10.ini
gudi_1_monster_100.ini
gudi_1_monster_110.ini
gudi_1_monster_120.ini
gudi_1_monster_130.ini
gudi_1_monster_140.ini
gudi_1_monster_150.ini
gudi_1_monster_160.ini
gudi_1_monster_170.ini
gudi_1_monster_180.ini
gudi_1_monster_190.ini
gudi_1_monster_20.ini
gudi_1_monster_200.ini
gudi_1_monster_30.ini
gudi_1_monster_40.ini
gudi_1_monster_50.ini
gudi_1_monster_60.ini
gudi_1_monster_70.ini
gudi_1_monster_80.ini
gudi_1_monster_90.ini
gudi_2_monster_10.ini
gudi_2_monster_100.ini
gudi_2_monster_110.ini
gudi_2_monster_120.ini
gudi_2_monster_130.ini
gudi_2_monster_140.ini
gudi_2_monster_150.ini
gudi_2_monster_160.ini
gudi_2_monster_170.ini
gudi_2_monster_180.ini
gudi_2_monster_190.ini
gudi_2_monster_20.ini
gudi_2_monster_200.ini
gudi_2_monster_30.ini
gudi_2_monster_40.ini
gudi_2_monster_50.ini
gudi_2_monster_60.ini
gudi_2_monster_70.ini
gudi_2_monster_80.ini
gudi_2_monster_90.ini
jiujiao_1_monster_10.ini
jiujiao_1_monster_100.ini
jiujiao_1_monster_110.ini
jiujiao_1_monster_120.ini
jiujiao_1_monster_130.ini
jiujiao_1_monster_140.ini
jiujiao_1_monster_150.ini
jiujiao_1_monster_160.ini
jiujiao_1_monster_170.ini
jiujiao_1_monster_180.ini
jiujiao_1_monster_190.ini
jiujiao_1_monster_20.ini
jiujiao_1_monster_200.ini
jiujiao_1_monster_30.ini
jiujiao_1_monster_40.ini
jiujiao_1_monster_50.ini
jiujiao_1_monster_60.ini
jiujiao_1_monster_70.ini
jiujiao_1_monster_80.ini
jiujiao_1_monster_90.ini
jiujiao_2_monster_10.ini
jiujiao_2_monster_100.ini
jiujiao_2_monster_110.ini
jiujiao_2_monster_120.ini
jiujiao_2_monster_130.ini
jiujiao_2_monster_140.ini
jiujiao_2_monster_150.ini
jiujiao_2_monster_160.ini
jiujiao_2_monster_170.ini
jiujiao_2_monster_180.ini
jiujiao_2_monster_190.ini
jiujiao_2_monster_20.ini
jiujiao_2_monster_200.ini
jiujiao_2_monster_30.ini
jiujiao_2_monster_40.ini
jiujiao_2_monster_50.ini
jiujiao_2_monster_60.ini
jiujiao_2_monster_70.ini
jiujiao_2_monster_80.ini
jiujiao_2_monster_90.ini
lingxingfeng_1_monster_10.ini
lingxingfeng_1_monster_100.ini
lingxingfeng_1_monster_110.ini
lingxingfeng_1_monster_120.ini
lingxingfeng_1_monster_130.ini
lingxingfeng_1_monster_140.ini
lingxingfeng_1_monster_150.ini
lingxingfeng_1_monster_160.ini
lingxingfeng_1_monster_170.ini
lingxingfeng_1_monster_180.ini
lingxingfeng_1_monster_190.ini
lingxingfeng_1_monster_20.ini
lingxingfeng_1_monster_200.ini
lingxingfeng_1_monster_30.ini
lingxingfeng_1_monster_40.ini
lingxingfeng_1_monster_50.ini
lingxingfeng_1_monster_60.ini
lingxingfeng_1_monster_70.ini
lingxingfeng_1_monster_80.ini
lingxingfeng_1_monster_90.ini
lingxingfeng_2_monster_10.ini
lingxingfeng_2_monster_100.ini
lingxingfeng_2_monster_110.ini
lingxingfeng_2_monster_120.ini
lingxingfeng_2_monster_130.ini
lingxingfeng_2_monster_140.ini
lingxingfeng_2_monster_150.ini
lingxingfeng_2_monster_160.ini
lingxingfeng_2_monster_170.ini
lingxingfeng_2_monster_180.ini
lingxingfeng_2_monster_190.ini
lingxingfeng_2_monster_20.ini
lingxingfeng_2_monster_200.ini
lingxingfeng_2_monster_30.ini
lingxingfeng_2_monster_40.ini
lingxingfeng_2_monster_50.ini
lingxingfeng_2_monster_60.ini
lingxingfeng_2_monster_70.ini
lingxingfeng_2_monster_80.ini
lingxingfeng_2_monster_90.ini
murenxiang_monster_7.ini
murenxiang_monster_9.ini
PCity_monster_cangshanzhengbei.ini
PCity_monster_caoyuanzhengxi.ini
PCity_monster_changbaishanxibei.ini
PCity_monster_erhaizhengxi.ini
PCity_monster_huanglongfuxibei.ini
PCity_monster_liaoxixibei.ini
PCity_monster_longquanzhengbei.ini
PCity_monster_meilingxibei.ini
PCity_monster_miaojiangzhengdong.ini
PCity_monster_nanhaizhengbei.ini
PCity_monster_nanzhaoxinan.ini
PCity_monster_qiongzhouzhengxi.ini
PCity_monster_shilinzhengnan.ini
PCity_monster_wuyizhengxi.ini
PCity_monster_xihuzhengxi.ini
PCity_monster_yanbeizhengxi.ini
PCity_monster_yannanzhengnan.ini
PCity_monster_yuxixinan.ini
songliao_monster_10.ini
songliao_monster_100.ini
songliao_monster_110.ini
songliao_monster_120.ini
songliao_monster_130.ini
songliao_monster_140.ini
songliao_monster_150.ini
songliao_monster_160.ini
songliao_monster_170.ini
songliao_monster_180.ini
songliao_monster_190.ini
songliao_monster_20.ini
songliao_monster_200.ini
songliao_monster_30.ini
songliao_monster_40.ini
songliao_monster_50.ini
songliao_monster_60.ini
songliao_monster_70.ini
songliao_monster_80.ini
songliao_monster_90.ini
tadi_1_monster_10.ini
tadi_1_monster_100.ini
tadi_1_monster_110.ini
tadi_1_monster_120.ini
tadi_1_monster_130.ini
tadi_1_monster_140.ini
tadi_1_monster_150.ini
tadi_1_monster_160.ini
tadi_1_monster_170.ini
tadi_1_monster_180.ini
tadi_1_monster_190.ini
tadi_1_monster_20.ini
tadi_1_monster_200.ini
tadi_1_monster_30.ini
tadi_1_monster_40.ini
tadi_1_monster_50.ini
tadi_1_monster_60.ini
tadi_1_monster_70.ini
tadi_1_monster_80.ini
tadi_1_monster_90.ini
tadi_2_monster_10.ini
tadi_2_monster_100.ini
tadi_2_monster_110.ini
tadi_2_monster_120.ini
tadi_2_monster_130.ini
tadi_2_monster_140.ini
tadi_2_monster_150.ini
tadi_2_monster_160.ini
tadi_2_monster_170.ini
tadi_2_monster_180.ini
tadi_2_monster_190.ini
tadi_2_monster_20.ini
tadi_2_monster_200.ini
tadi_2_monster_30.ini
tadi_2_monster_40.ini
tadi_2_monster_50.ini
tadi_2_monster_60.ini
tadi_2_monster_70.ini
tadi_2_monster_80.ini
tadi_2_monster_90.ini
taohuazhen_1_monster_10.ini
taohuazhen_1_monster_100.ini
taohuazhen_1_monster_110.ini
taohuazhen_1_monster_120.ini
taohuazhen_1_monster_130.ini
taohuazhen_1_monster_140.ini
taohuazhen_1_monster_150.ini
taohuazhen_1_monster_160.ini
taohuazhen_1_monster_170.ini
taohuazhen_1_monster_180.ini
taohuazhen_1_monster_190.ini
taohuazhen_1_monster_20.ini
taohuazhen_1_monster_200.ini
taohuazhen_1_monster_30.ini
taohuazhen_1_monster_40.ini
taohuazhen_1_monster_50.ini
taohuazhen_1_monster_60.ini
taohuazhen_1_monster_70.ini
taohuazhen_1_monster_80.ini
taohuazhen_1_monster_90.ini
taohuazhen_2_monster_10.ini
taohuazhen_2_monster_100.ini
taohuazhen_2_monster_110.ini
taohuazhen_2_monster_120.ini
taohuazhen_2_monster_130.ini
taohuazhen_2_monster_140.ini
taohuazhen_2_monster_150.ini
taohuazhen_2_monster_160.ini
taohuazhen_2_monster_170.ini
taohuazhen_2_monster_180.ini
taohuazhen_2_monster_190.ini
taohuazhen_2_monster_20.ini
taohuazhen_2_monster_30.ini
taohuazhen_2_monster_40.ini
taohuazhen_2_monster_50.ini
taohuazhen_2_monster_60.ini
taohuazhen_2_monster_70.ini
taohuazhen_2_monster_80.ini
taohuazhen_2_monster_90.ini
tianshan_1_monster30.ini
tianshan_1_monster320.ini
tongrenxiang_1_monster_10.ini
tongrenxiang_1_monster_100.ini
tongrenxiang_1_monster_110.ini
tongrenxiang_1_monster_120.ini
tongrenxiang_1_monster_130.ini
tongrenxiang_1_monster_140.ini
tongrenxiang_1_monster_150.ini
tongrenxiang_1_monster_160.ini
tongrenxiang_1_monster_170.ini
tongrenxiang_1_monster_180.ini
tongrenxiang_1_monster_190.ini
tongrenxiang_1_monster_20.ini
tongrenxiang_1_monster_200.ini
tongrenxiang_1_monster_30.ini
tongrenxiang_1_monster_40.ini
tongrenxiang_1_monster_50.ini
tongrenxiang_1_monster_60.ini
tongrenxiang_1_monster_70.ini
tongrenxiang_1_monster_80.ini
tongrenxiang_1_monster_90.ini
tongrenxiang_2_monster_10.ini
tongrenxiang_2_monster_100.ini
tongrenxiang_2_monster_110.ini
tongrenxiang_2_monster_120.ini
tongrenxiang_2_monster_130.ini
tongrenxiang_2_monster_140.ini
tongrenxiang_2_monster_150.ini
tongrenxiang_2_monster_160.ini
tongrenxiang_2_monster_170.ini
tongrenxiang_2_monster_180.ini
tongrenxiang_2_monster_190.ini
tongrenxiang_2_monster_20.ini
tongrenxiang_2_monster_200.ini
tongrenxiang_2_monster_30.ini
tongrenxiang_2_monster_40.ini
tongrenxiang_2_monster_50.ini
tongrenxiang_2_monster_60.ini
tongrenxiang_2_monster_70.ini
tongrenxiang_2_monster_80.ini
tongrenxiang_2_monster_90.ini
wushendong_1_monster_10.ini
wushendong_1_monster_100.ini
wushendong_1_monster_110.ini
wushendong_1_monster_120.ini
wushendong_1_monster_130.ini
wushendong_1_monster_140.ini
wushendong_1_monster_150.ini
wushendong_1_monster_160.ini
wushendong_1_monster_170.ini
wushendong_1_monster_180.ini
wushendong_1_monster_190.ini
wushendong_1_monster_20.ini
wushendong_1_monster_200.ini
wushendong_1_monster_30.ini
wushendong_1_monster_40.ini
wushendong_1_monster_50.ini
wushendong_1_monster_60.ini
wushendong_1_monster_70.ini
wushendong_1_monster_80.ini
wushendong_1_monster_90.ini
wushendong_2_monster_10.ini
wushendong_2_monster_100.ini
wushendong_2_monster_110.ini
wushendong_2_monster_120.ini
wushendong_2_monster_130.ini
wushendong_2_monster_140.ini
wushendong_2_monster_150.ini
wushendong_2_monster_160.ini
wushendong_2_monster_170.ini
wushendong_2_monster_180.ini
wushendong_2_monster_190.ini
wushendong_2_monster_20.ini
wushendong_2_monster_200.ini
wushendong_2_monster_30.ini
wushendong_2_monster_40.ini
wushendong_2_monster_50.ini
wushendong_2_monster_60.ini
wushendong_2_monster_70.ini
wushendong_2_monster_80.ini
wushendong_2_monster_90.ini
xingxiu_monster_10.ini
xingxiu_monster_100.ini
xingxiu_monster_110.ini
xingxiu_monster_120.ini
xingxiu_monster_130.ini
xingxiu_monster_140.ini
xingxiu_monster_150.ini
xingxiu_monster_160.ini
xingxiu_monster_170.ini
xingxiu_monster_180.ini
xingxiu_monster_190.ini
xingxiu_monster_20.ini
xingxiu_monster_200.ini
xingxiu_monster_30.ini
xingxiu_monster_40.ini
xingxiu_monster_50.ini
xingxiu_monster_60.ini
xingxiu_monster_70.ini
xingxiu_monster_80.ini
xingxiu_monster_90.ini
yewai_monster_10.ini
yewai_monster_100.ini
yewai_monster_110.ini
yewai_monster_120.ini
yewai_monster_130.ini
yewai_monster_140.ini
yewai_monster_150.ini
yewai_monster_160.ini
yewai_monster_170.ini
yewai_monster_180.ini
yewai_monster_190.ini
yewai_monster_20.ini
yewai_monster_200.ini
yewai_monster_30.ini
yewai_monster_40.ini
yewai_monster_50.ini
yewai_monster_60.ini
yewai_monster_70.ini
yewai_monster_80.ini
yewai_monster_90.ini
zhemeifeng_1_monster_10.ini
zhemeifeng_1_monster_100.ini
zhemeifeng_1_monster_110.ini
zhemeifeng_1_monster_120.ini
zhemeifeng_1_monster_130.ini
zhemeifeng_1_monster_140.ini
zhemeifeng_1_monster_150.ini
zhemeifeng_1_monster_160.ini
zhemeifeng_1_monster_170.ini
zhemeifeng_1_monster_180.ini
zhemeifeng_1_monster_190.ini
zhemeifeng_1_monster_20.ini
zhemeifeng_1_monster_200.ini
zhemeifeng_1_monster_30.ini
zhemeifeng_1_monster_40.ini
zhemeifeng_1_monster_50.ini
zhemeifeng_1_monster_60.ini
zhemeifeng_1_monster_70.ini
zhemeifeng_1_monster_80.ini
zhemeifeng_1_monster_90.ini
zhemeifeng_2_monster_10.ini
zhemeifeng_2_monster_100.ini
zhemeifeng_2_monster_110.ini
zhemeifeng_2_monster_120.ini
zhemeifeng_2_monster_130.ini
zhemeifeng_2_monster_140.ini
zhemeifeng_2_monster_150.ini
zhemeifeng_2_monster_160.ini
zhemeifeng_2_monster_170.ini
zhemeifeng_2_monster_180.ini
zhemeifeng_2_monster_190.ini
zhemeifeng_2_monster_20.ini
zhemeifeng_2_monster_200.ini
zhemeifeng_2_monster_30.ini
zhemeifeng_2_monster_40.ini
zhemeifeng_2_monster_50.ini
zhemeifeng_2_monster_60.ini
zhemeifeng_2_monster_70.ini
zhemeifeng_2_monster_80.ini
zhemeifeng_2_monster_90.ini
zhulin_monster_10.ini
zhulin_monster_100.ini
zhulin_monster_110.ini
zhulin_monster_120.ini
zhulin_monster_130.ini
zhulin_monster_140.ini
zhulin_monster_150.ini
zhulin_monster_160.ini
zhulin_monster_170.ini
zhulin_monster_180.ini
zhulin_monster_190.ini
zhulin_monster_20.ini
zhulin_monster_200.ini
zhulin_monster_30.ini
zhulin_monster_40.ini
zhulin_monster_50.ini
zhulin_monster_60.ini
zhulin_monster_70.ini
zhulin_monster_80.ini
zhulin_monster_90.ini

