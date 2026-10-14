# SERVER-SCENEDATA — dữ liệu cảnh cho máy chủ (vai SCENE-DATA, đợt gameplay 1)

Cập nhật 2026-10-14. Gồm: đường ống công cụ sinh dữ liệu cảnh, số trước/sau, phần còn thiếu và vì sao, nguồn lưới đi
của từng cảnh, và API của module `src/server/scenedata` (bộ đọc một thư mục cảnh và bảng luật AI thành struct có kiểu).
Đủ để nối module vào `zone` mà không đọc mã. Module chỉ NẠP và KIỂM; sinh quái, chạy luật AI, di chuyển là việc của `zone`.

## 1. Đường ống dữ liệu

Chạy ở gốc repo, theo thứ tự (mỗi bước ghi đè đầu ra của chính nó, chạy lại cho byte y hệt):

```
python TOOLS/server/export_scene.py ...              # cảnh bản 0859602 (đã có từ trước; nguồn Public/Scene không còn trên máy)
python TOOLS/server/import_scene_xjl.py dev/server <XJL7457>/Server/rootfs/home/tlbb "<client>/Scene"
python TOOLS/server/scene_walk.py       dev/server <XJL7457>/Server/rootfs/home/tlbb "<client>/Scene"
python TOOLS/server/scene_xref.py       dev/server <XJL7457>/Server/rootfs/home/tlbb "<client>/Scene"
python TOOLS/server/scene_diff.py       dev/server <XJL7457>/Server/rootfs/home/tlbb
python TOOLS/server/ai_convert.py       dev/server <XJL7457>/Server/rootfs/home/tlbb
```

`<XJL7457>` là `G:\XJL7457\Server\rootfs\home\tlbb`, `<client>/Scene` là `F:\tl 2026\_goc\Scene` (cây client 2026 đã giải nén).
XJL7457 chỉ được ĐỌC: không chạy gì của nó, không chép tệp nhị phân hay script nguyên văn. Mọi công cụ có `--check` (chỉ
tính, không ghi). `build_data.py` và `table_names.tsv` chưa gọi các công cụ này: người điều phối nối sau (xem mục 8).

| Công cụ | Việc | Đầu ra |
|---|---|---|
| `scene_xref.py` | đối chiếu client 2026 (SceneAttr + SceneDefineEx) ↔ 0859602 (SceneInfo.ini) ↔ XJL7457, theo id rồi tài nguyên/tên tệp rồi tên cảnh | `tables/server/scene_xref.tsv` (369 dòng, mỗi dòng một thư mục cảnh), `scene_ids.tsv` (id client → thư mục), `scene_client_only.tsv` (252 tài nguyên client không có thư mục nào) |
| `import_scene_xjl.py` | nhập cảnh XJL7457 mà client 2026 có và `dev/server/scenes` chưa có; GBK → UTF-8, cùng bộ đọc ini và cùng kiểm miền với `export_scene.py` | 81 thư mục cảnh mới (`# tool:` là `import_scene_xjl.py`) |
| `scene_walk.py` | chọn nguồn lưới đi cho mọi thư mục cảnh, chép `.path` của client thành `walk.path`, ghi khối "Nguồn lưới đi" cuối `scene.toml` | `walk.path` (273 cảnh), `scene.toml` |
| `scene_diff.py` | so từng bảng của cảnh dùng chung 0859602 ↔ XJL7457 (cùng khoá, khác ô, chỉ một bên) | `tables/server/scene_xjl_diff.tsv` |
| `ai_convert.py` | 307 tệp `scriptN.ai` + `MonsterAITable` → bảng luật có kiểu | `tables/server/monster_ai_rules.tsv`, `monster_ai_rule_files.tsv` |

Thứ bậc nguồn (đề bài chung): client 2026 > XJL7457 (14 môn phái) > mã máy chủ 2008 > TLBB Dev > bản 0859602 đã nhập. Client 2026
không có dữ liệu quái đặt sẵn, nên quái/vùng/tuyến tuần/điểm thu thập lấy từ 0859602 (vào trước) rồi XJL7457 (chỉ cảnh 0859602
chưa có); client 2026 quyết định id cảnh gửi cho client và lưới đi.

Kiểm: `python TOOLS/server/lint_py.py` (không lỗi ở tệp của vai này), `python -B -m unittest discover -s TOOLS/server -p
"test_scene_xjl.py"` (51 ca), `thienlong_lint --root dev/server --refs TOOLS/server/refs` (luật mới ở `refs/scenes.tsv` và
`refs/scene_data.tsv`; xem mục 8 về `known_missing`).

## 2. Số trước và sau

| | Trước (chỉ 0859602) | Sau |
|---|---|---|
| Thư mục cảnh `dev/server/scenes` | 244 | **325** (244 + 81 nhập từ XJL7457) |
| Quái và NPC đặt sẵn (mọi bảng `spawns*.tsv`) | 40 168 | **47 970** (+7 802); 47 938 có toạ độ, 32 bỏ trống ô x/z |
| Vùng sự kiện (`areas*.tsv`) | 382 | **488** (+106) |
| Điểm của tuyến tuần (`patrols.tsv`) | 2 996 | **3 430** (+434) |
| Điểm thu thập (`grow_points.tsv`) | 7 885 | **8 255** (+370) |
| Nhịp bổ sung điểm thu thập | 210 | **242** (+32) |
| Bàn chế tác | 107 | **116** (+9) |
| Trân thú hoang, cổng, xe, cấp quái, operate, giá trị operate | 3, 8, 6, 361, 423, 2 410 | không đổi (XJL7457 không thêm) |
| Lưới đi dùng khi chạy | `walk.nav` của 2008 (244) | **273** `.path` của client 2026 + **52** `walk.nav`; `walk.nav` còn ở 310 thư mục làm dự phòng |
| Luật AI quái | không có | **307** kịch bản, **1 073** luật, 2 443 điều kiện, 1 097 hành động (3 540 dòng `monster_ai_rules.tsv`) |

XJL7457 khai 724 mục `[sceneN]` (456 bật, 268 tắt); gộp theo thư mục + tài nguyên client ra 369 nhóm của `scene_xref.tsv`:
223 cảnh 0859602 giữ nguyên, 21 cảnh 0859602 không có tài nguyên client (ứng viên bỏ), 81 cảnh nhập mới, 44 cảnh riêng của
nhà phát hành bị bỏ.

## 3. Còn thiếu và vì sao

**44 cảnh XJL7457 không nhập** (client 2026 không có tài nguyên cho chúng, `status = absent_xjl_private`, `action = skip`):
buguilin 不归林, chengshiwangling 城市王陵, daliKV, fenghuang_war 凤凰战场, guhuolinggu 蛊惑灵谷, hanbinghaiyu 寒冰海域, jinling 金陵,
luoyangKV, mieshihuoku 灭世火窟, qianqiudian 千秋殿, qinshuidanlin 沁水丹林, Scene449..452, shenlongdao, shuipoliangshan
(+_01, _02s, _03, _04s, W_w01), suzhouKV, tianhuangshan 天皇山, weichengcaoyuan (+_01, _02s), wuyahai 无涯海, wuzhuzhidi 望云泊,
Xbw_LTJ, xingjudao 涯竹原, xinsanhuan 炎魔山, xuezhanymg 血战雁门关, yanluotian 炎罗天, yayuland 崖余岛, yunfu 云浮,
yunyaoqueling 云瑶鹊岭, ZhengBaSai, zhengding8 泰皇神域, zhoutian 虚空幻境, zhuangyuan_5, zhulin_01, zhulin_02s, zhulinax.
Không có client để vẽ nên nhập về cũng không dùng được.

**21 thư mục cảnh 0859602 mà client 2026 không có** (`action = drop_candidate`, vẫn nằm trong `dev/server/scenes`, chưa xoá:
việc bỏ hay giữ là quyết định của chủ dự án): bianguan_1..4, city0, homeda, homeda_1, homexiao, homexiao_1, homezhong, homezhong_1,
huanjing_1..4, jiaofei, luoyangsnow, PCity, protectguild, shengsileitai, talin. Cả 21 dùng `walk.nav` của 2008.

**252 tài nguyên cảnh của client 2026 không có thư mục cảnh nào** (`scene_client_only.tsv`: tên tài nguyên, tên cảnh, các tệp
`.Scene`/`.path`/`.WCollision`/vùng/độ cao). Cả 0859602 lẫn XJL7457 đều không dựng nó nên không có nguồn nào để điền (ví dụ
new_yanziwu 擂台, fenghuangpingyuan 凤凰平原, gusufb_1 藏书水阁). Id cảnh của client mà máy chủ chưa phục vụ nằm ngoài `scene_ids.tsv`.

**Lệch id**: 79 cảnh có id XJL7457/0859602 khác id SceneAttr của client (`id_relation = shifted`; 78 trong số đó là cảnh nhập từ
XJL7457), ghép theo tài nguyên rồi theo tên; 71 nhóm không có id nào ở client (`client_missing`: 44 cảnh riêng của nhà phát hành,
21 ứng viên bỏ, 6 cảnh đang giữ: banghuihoushan, CampPVP2023, shengxiao, newbie_1, newbie_2, yuliu1; tài nguyên client của chúng
không có mục SceneAttr nào). Máy chủ phải gửi id của client (`scene_ids.tsv`), không gửi id nội bộ.
Ba tài nguyên client dùng chung cho hơn 256 id không được tính là cảnh riêng (`GENERIC_RES_IDS`): 擂台 `leitai_1` (23 968 id),
`shijianjhsPVP2` (2 000) và `jiayuanjichu` (347); xem mục 5.

**Quái không có mẫu trong client** (kiểm `tables/shared/monsters.tsv` của client 2026, 28 969 mẫu, với mọi `type` đã đặt):
41 id, 565 dòng quái, đều không có trong bảng của client:

| Cảnh (nguồn) | id không có | Dòng |
|---|---|---|
| PhoenixMaze (XJL7457) | 13750..13757 (8 id, quái không tên) | 441 |
| qinhuanggong_5 (XJL7457) | 50100, 50101, 50102, 50105, 50106 | 72 |
| fengmingzhen (XJL7457) | 42438, 42442, 42443, 42445..42449, 42451..42461, 42463, 42464, 42466..42469, 42521, 42958 (NPC có tên: 巢云珪, 天荒难民, 天荒守卫...) | 42 |
| muchang (0859602) | 3364 (少女) | 10 |

Bộ nạp vẫn nạp các dòng này (`Spawn::type` là id thô); `zone` phải bỏ qua hay báo khi tra mẫu quái. PhoenixMaze đáng chú ý nhất:
ghép tới `fenghuanglingmu` của client chỉ theo tên (`match = name`), 441/450 quái dùng id không có ở client, và 405/450 quái
đứng ngoài lưới `.path` của client: nhiều khả năng đây là map khác với map 2026 cùng tên.

**Mã script không có trong chỉ mục** (`tables/server/script_index.tsv`): quái 158 mã (client 2026 có 33, XJL7457 có 122, **35 không
có ở đâu**: 13021, 13022, 14100..14111, 100125, 100126, 100129, 390001, 390002, 402311, 600055, 760309, 760361, 760376, 760432,
760497..760499, 881185, 889431, 910104, 966716, 992382..992384); vùng sự kiện 80 mã (client có 15, XJL7457 có 73, **6 không có ở
đâu**: 760451, 900082, 900091, 900092, 900125, 900126). Các con số này là `known_missing` của `refs/scenes.tsv` (`spawns.script_id`
158, `areas.script_id` 80; ngoài ra `spawns.type` 41). Script thuộc vai MISSION.

**AI**: 3 luật trong `script86.ai:10`, `script124.ai:11`, `script235.ai:10` dùng dấu `(` thay `{` ở vế hành động; mã 2008 hiểu khác
nên `ai_convert.py` bỏ và báo, không đưa vào bảng. Năm hàm của bản private mã 2008 không có (`call_other_monster_by_group` 22 lần,
`call_other_monster_by_team`, `set_base_ai_type`, `set_patrol_id`, `start_patrol` mỗi cái 1 lần) vẫn vào bảng, ngữ nghĩa suy từ tên.
47 id kỹ năng trong luật AI chưa có trong bảng kỹ năng (`known_missing` của `refs/scene_data.tsv`).

**Không kiểm được trên máy này**: `export_scene.py` chạy trên nguồn 0859602 (`Public/Scene`) không còn trên máy, nên ca thật của nó
bị bỏ qua; dữ liệu 244 cảnh 0859602 là bản đã sinh từ trước, không tái sinh trong đợt này.

## 4. So sánh hai nguồn cho cảnh dùng chung (0859602 ↔ XJL7457)

`scene_xjl_diff.tsv` (228 cảnh có ở cả hai, 582 dòng cảnh × loại bảng): 95 cảnh giống hệt ở mọi bảng, 133 cảnh có khác biệt.
Cộng theo loại bảng:

| Bảng | dòng 0859602 | dòng XJL7457 | giống | cùng khoá khác ô | chỉ 0859602 | chỉ XJL7457 |
|---|---|---|---|---|---|---|
| spawns | 40 168 | 27 542 | 22 162 | 4 681 | 13 325 | 699 |
| areas | 382 | 384 | 358 | 16 | 8 | 10 |
| patrols | 2 996 | 2 993 | 2 842 | 132 | 22 | 19 |
| grow_points | 7 885 | 8 021 | 7 885 | 0 | 0 | 136 |
| platforms | 107 | 105 | 90 | 1 | 16 | 14 |
| wild_pets | 3 | 3 | 3 | 0 | 0 | 0 |

Phần lớn "chỉ 0859602" của spawns là các bảng quái theo cấp (`spawns.level_*`, `spawns.set_*`) mà XJL7457 không tách. 0859602
vào trước nên là bản đang dùng; mọi chênh lệch chỉ để người duyệt nội dung xem, không tự gộp. Với lưới đi, cảnh có cả `.path` của
client lẫn `walk.nav` được so ở mục 5 và client thắng.

## 5. Nguồn lưới đi của từng cảnh

Thứ bậc (`scene_walk.py`): `.path` của client 2026 nếu cảnh ghép được vào đúng một tệp riêng của nó và tệp đó chứa chỗ đặt quái;
không thì `walk.nav`; không có gì thì `none`. Khối "Nguồn lưới đi" cuối mỗi `scene.toml` ghi `walk_source`, `walk_path`,
`walk_client_file`, `walk_nav` và (khi bỏ `.path`) một dòng "Đã bỏ <tệp>: lý do". Cột `walk_source` của `scene_xref.tsv` có đủ 325 cảnh.

| Nguồn | Số cảnh |
|---|---|
| `client_2026_path` | 273 |
| `legacy_nav_0859602` | 48 |
| `legacy_nav_xjl7457` | 4 |
| `none` | 0 |

52 cảnh dùng `walk.nav` vì:
- 21 ứng viên bỏ (không có tài nguyên client) — liệt kê ở mục 3;
- 18 vùng `PCity*` (clientres 10001 của client không có tệp `.Scene`/`.path`);
- 8 cảnh ghép tài nguyên chung 擂台 (`leitai_1`, 64 x 64 ô, giữ chỗ cho hàng nghìn id): `_pingpan_1`, dumuchang, huomuchang,
  leitai_1, songliao, xuanmuchang, yewai, zhulin. Tài nguyên có hơn 256 id (`GENERIC_RES_IDS`) không phải lưới của cảnh nào (chỉ `leitai_1` ảnh hưởng cảnh hiện có);
- 3 cảnh khớp theo tên nhiều tài nguyên client nên chưa chọn được `.path`: cangjingge, guigu_2, yanziwu;
- 2 cảnh bị bỏ `.path` vì hộp bao đỉnh của nó không chứa chỗ đặt quái: `gusufb` (lưới 64 x 64, 200/269 quái ngoài; quái ở x 23..179,
  z 24..465) và `tangmenjj` (26/122 quái ngoài). Ngưỡng bỏ: quá 10% quái nằm ngoài hộp bao (nới 1 đơn vị), xem hằng
  `MAX_OUTSIDE_PERCENT`, `EXTENT_SLACK` ở `scene_walk.py`; vài quái lạc ngoài hộp (tianqinanhuai 1/137, gusu_1 1/710) không bỏ lưới.

Đo bằng `audit_scene` (module scenedata) trên dữ liệu hiện có, 47 938 quái có toạ độ:

- **Cảnh dùng `walk.nav` làm nguồn** (52): 5 766 quái có toạ độ, 1 ngoài ô đi được (độc lập với C++: một chương trình Python tự giải
  lưới ô cho cùng số 5 766 / 1).
- **Mọi cảnh có `walk.nav`** (310): 45 430 quái, 3 066 ngoài ô đi được (Python độc lập cho đúng số này).
- **Cảnh dùng `.path` làm nguồn** (273): 42 172 quái, 4 957 đứng ngoài tam giác đi được (11,8%). Với 258 cảnh có cả hai lưới: 4 499
  quái ngoài `.path` so với 3 065 ngoài `walk.nav` trên 39 664 quái.
- 230 điểm tuần đã đặt nằm ngoài lưới đi (luoyang 132, suzhou 26, langhuanfudi 22, dali 14, sancaixiagu 12, yanziwu 5, Songliao_War 3,
  còn lại 1-2); không tuyến tuần nào bị treo (`spawns_dangling_patrol` = 0).

Hai nguyên nhân chính của quái ngoài `.path` (chưa sửa; nội dung phải làm lại, không phải lỗi bộ đọc):

1. **2 302 quái đứng đúng (64, 64)** — góc của lưới 64 x 64 ở các phó bản `_1`/`_2` (guangmingdong, gudi, jiujiao, lingxingfeng,
   tadi, taohuazhen, tongrenxiang, wushendong, zhemeifeng: mỗi bản `_1` 42 quái, `_2` 168 quái) và jiaochang (420), dùng
   chung GUID 13826514 và `respawn_time = -1`; trông như mục giữ chỗ do script sinh, không phải chỗ đứng thật. Ngoài cả `.path` lẫn
   `walk.nav`. Chưa chứng minh được đó là sentinel nên bộ đọc vẫn tính là quái đặt.
   Thêm 17 mục `type = 0` không tên ở đúng (0, 0) (12 cảnh) cũng là mục chỉ chạy kịch bản; `scene_walk.py` bỏ chúng khi so hộp bao.
2. **Bố cục map 2026 khác bản cũ**: lưới ô cũ chứa đủ quái nhưng `.path` mới thì không — gusu 160/229, tangmen 180/322, luoyang 119/207,
   suzhou 83/158, kunlunshan 143/325, guigu 80/234, dali 50/164, qinhuanggong_4 38/164, gusu_2 34/110, wedding_2 8/16, wedding_3 12/27,
   huashan 12/37, guigusg 60/606, tangmensg 102/722, gusu_1 74/710 (đều 0 quái ngoài lưới ô cũ). Cảnh mới dựng lại thì bảng quái
   phải sinh lại theo bố cục 2026; client thắng nên lưới vẫn là `.path`. Hai cảnh khác: emei_1 420/630 và gaibang_1 315/630 (ngoài
   cả hai lưới, 324 và 294 ở lưới ô cũ), PhoenixMaze 405/450 (không có `walk.nav`).

Cả 51 cảnh có từ 10% quái ngoài `.path` trở lên có thể tính lại bằng `audit_scene` (struct `SceneAudit`: `spawns_off_walk` là lưới đang
dùng, `spawns_off_legacy_grid` là `walk.nav`). `scenedata_tests` in một dòng tổng và khẳng định các số ở trên.

## 6. API của `src/server/scenedata`

Header (include `"scenedata/<x>.hpp"` từ gốc `src/server`): `types.hpp` (mọi struct), `tables.hpp` (từng bảng), `walk.hpp`,
`scene.hpp`, `ai_rules.hpp`, `disk.hpp` (đọc đĩa). Chỉ `disk.cpp` chạm tệp; phần còn lại nhận chuỗi/byte nên test được không cần đĩa.
Phụ thuộc: `core`, `io`, `table`, `ids`, `nav` (hàng `game_layer_scenedata` ở `cmake/GameLayers.cmake`). Lỗi trả
`std::expected<T, LoadError>` (`Loaded<T>`), `LoadError::what` là câu tiếng Việt `<tệp>:<dòng>: cột <tên>: <lý do>`; không throw.

```cpp
const auto scene = scenedata::load_scene("dev/server/scenes/luoyang");        // Loaded<Scene>
if (!scene) { log(scene.error().what); return; }
for (const scenedata::Spawn& s : scene->spawns) { /* bảng gốc */ }
for (const auto& v : scene->spawn_variants)     { /* spawns.<nhãn>.tsv: v.label, v.rows */ }
bool ok = scene->walk.walkable({.x = 120.0F, .z = 80.0F});                    // theo nguồn lưới đang dùng
const scenedata::Patrol* route = scene->find_patrol(spawn.patrol_id);        // nullptr nếu không có
const auto ai = scenedata::load_ai_rules("dev/server/tables/server");         // Loaded<AiRuleTable>
const scenedata::AiScript* script = ai->find(spawn.ai_file.value_or(-1));     // theo ai_id; luật: script->rules(AiSection::kCommon)
```

| Hàm | Việc |
|---|---|
| `read_scene_files(dir)` / `load_scene(dir)` | đọc cả thư mục (`scene.toml` bắt buộc, `walk.path`, `walk.nav`, mọi `*.tsv`; phẳng, bỏ symlink, ≤ 8 192 mục) rồi `parse_scene` |
| `parse_scene(const SceneFiles&)` | thuần bộ nhớ; kết quả không phụ thuộc thứ tự tệp (nạp theo tên đã sắp) |
| `split_table_name(name)` | `spawns.level_100.tsv` → loại `spawns`, nhãn `level_100` |
| `audit_scene(const Scene&)` | số kiểm chéo: quái, quái có toạ độ, ngoài lưới đang dùng, ngoài `walk.nav`, tuyến treo, điểm tuần ngoài |
| `parse_spawns/areas/patrols/grow_points/grow_rules/platforms/wild_pets/portals/buses/spawn_levels/spawn_operates/operate_values(file, text)` | từng bảng |
| `parse_manifest(text)`, `parse_legacy_grid(bytes)`, `build_walk(manifest, path, nav)` | `scene.toml`, `walk.nav`, ghép lưới đi |
| `load_ai_rules(tables_dir)` / `parse_ai_rules({.rules, .files})` | `monster_ai_rules.tsv` + `monster_ai_rule_files.tsv` → `AiRuleTable` |

`Scene` gồm: `spawns` + `spawn_variants` (bảng quái theo nhãn, `zone` chọn theo cấp người chơi qua `spawn_operates` /
`operate_values`), `areas` + `area_variants`, `spawn_levels`, `patrols` (điểm xếp theo `point_index`), `grow_points`, `grow_rules`,
`platforms`, `wild_pets`, `portals`, `buses`, `walk`, `unread_files` (tệp lạ trong thư mục, rỗng là bình thường).
Thư mục thật có các họ bảng: `spawns[.nhãn]`, `areas[.nhãn]`, `patrols`, `grow_points`, `grow_point_rules`, `platforms`,
`wild_pets`, `portals`, `buses`, `spawn_levels`, `spawn_operates[.nhãn]`, `spawn_operate_values[.nhãn]`.

Ngữ nghĩa đáng biết (đã đọc từ mã máy chủ 2008, `MonsterManager.cpp`, `AreaManager.h`, `GrowPointManager.cpp`, `PathFinder.cpp`):
- Ô rỗng ≠ 0 mọi lúc: khoá bắt buộc rỗng đọc 0 (`atoi("")`), khoá tuỳ chọn rỗng lấy mặc định của mẫu quái (`std::optional`
  trong struct). `Spawn::position_given` false khi ô x hoặc z rỗng (quái ở (0, 0) theo mã 2008, bên dùng quyết định có sinh không).
- `Spawn::heading_degrees()` = `dir * 10 + 90`, trừ 360 một lần khi vượt 360 (số nguyên, tất định).
- `Area::contains`: cạnh phải và cạnh dưới không thuộc vùng; vùng có `left > right` là vùng rỗng, không phải lỗi (taohuadao).
- `GrowPoint`: cột `position_y` của bảng là trục Z của cảnh (mã 2008 gán nó vào `m_fZ`).
- `LegacyGrid`: ô 0,5 đơn vị gốc (0, 0), đầu tệp hai `u16` (rộng, cao), mỗi ô 4 byte, trạng thái = bốn bit thấp byte đầu; đi
  được khi `level >= state`; ngoài lưới là không đi được. `Walk::walkable` với `.path`: nằm trong tam giác đi được, `level` bị bỏ qua.
- GUID của quái KHÔNG duy nhất (nhiều NPC bản private chung một GUID): không dùng làm khoá.
- Luật AI: năm đoạn `common/skill/beskill/damage/dead`; mỗi lần xử lý một đoạn chỉ luật ĐẦU TIÊN (đã sắp ưu tiên giảm dần, ổn định)
  có mọi điều kiện đúng và còn lượt chạy rồi dừng; `times` -1 vô hạn, 0 không bao giờ (cũng là giá trị khi vắng `AIS_SetTimes`),
  hữu hạn thì phải đếm theo `rule_index` trên từng quái; trong `common` luật có điều kiện `get_ai_state` chỉ chạy ở trạng thái đó.

Chống đầu vào thù địch (mọi bảng đều có thể bị sửa tay): kiểm cỡ trước khi tách dòng, miền từng ô, UTF-8 hợp lệ, tên bảng
(không `..`, không phân cách đường dẫn), `spawn_file` của operate phải trỏ tới bảng quái có thật. Trần:

| Trần | Giá trị |
|---|---|
| mỗi bảng (byte, dòng, cột) | 64 MiB, 200 000, 64 |
| điểm của một tuyến tuần, số tuyến, câu nói mỗi điểm | 4 096, 4 096, 16 |
| ô văn bản, toạ độ tuyệt đối | 256 byte, 100 000 |
| số bảng một cảnh, độ dài tên bảng | 2 048, 128 |
| `scene.toml` | 1 MiB, 4 096 dòng |
| `walk.nav` | 4 096 x 4 096 ô (kiểm bằng số học, không cấp phát trước) |
| bảng luật AI | 400 000 dòng, 20 000 kịch bản, 4 096 luật/kịch bản, 64 nguyên tử/luật |

## 7. Kiểm chứng đã chạy (2026-10-14)

- `build\ag-scene\scenedata_tests.exe` (MSVC `msvc-release`, /W4 -WX, 0 cảnh báo): 23 ca đạt. Ca `real_scenes` nạp đủ 325 cảnh thật và
  khẳng định các tổng ở mục 2 và 5; ca `real_ai_rules` nạp 307 kịch bản thật.
- `check.py` (GCC 16.2 + Clang 23.1 `-Werror`, clang-tidy 23): 13 tệp nguồn `src/server/scenedata` sạch; `Test/Scenedata/scenedata_tests.cpp`
  sạch cả ba. `check.py --run`: Clang với ASan + UBSan mở rộng + hardening STL và GCC với debug mode libstdc++ đều chạy hết 23 ca
  (gồm dữ liệu thật) không báo gì.
- `header_check` dựng sạch các header scenedata; `ctest -R scenedata_tests` đạt; test `layers` hiện đỏ vì module `combat` của vai khác chưa
  có dòng trong `cmake/GameLayers.cmake` (không phải scenedata).
- Python: `test_scene_xjl.py` 51 ca đạt; `lint_py.py` không lỗi ở tệp của vai này.
- `thienlong_lint` trên toàn cây dữ liệu: các bảng của vai này không lỗi; lỗi còn lại (1 037) đều ở `mission_strings.tsv` của vai MISSION.
- Chưa kiểm: chạy trên Linux (chỉ Windows); TSan (Windows không có); nối vào `zone` (việc của người điều phối).

## 8. Việc để người điều phối nối

- Thêm các bảng mới vào `TOOLS/server/table_names.tsv` (`scene_xref`, `scene_client_only`, `scene_ids`, `scene_xjl_diff`,
  `monster_ai_rules`, `monster_ai_rule_files`) và gọi 5 công cụ ở mục 1 từ `build_data.py` sau `export_scene.py`.
- `refs/scenes.tsv` và `refs/scene_data.tsv` mang `known_missing` bằng đúng số id còn thiếu hôm nay (41, 158, 80, 47); khi vai
  khác bổ sung mẫu quái, script hay kỹ năng thì số này phải giảm (lint báo khi sai).
- `docs/README.md` chưa có dòng cho tệp này.
- Module `scenedata` chưa được `zone`/`world` dùng; dòng `game_layer_scenedata` đã có ở `cmake/GameLayers.cmake`, tên
  `scenedata` đã có trong `game_server_names` của `CMakeLists.txt` gốc, `cmake/server/scenedata.{modules,tests}.cmake` đăng ký
  module và test.
- Số tự đặt: không có số game nào được bịa. Hằng của bộ đọc là trần an toàn (mục 6); `EXTENT_SLACK` = 1 và `MAX_OUTSIDE_PERCENT` = 10
  của `scene_walk.py` là ngưỡng của công cụ (chọn lưới), không phải dữ liệu game; không có bảng `basis = made_up` nào cần duyệt.
