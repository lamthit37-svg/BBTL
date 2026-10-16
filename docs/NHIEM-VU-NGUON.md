# Nguồn dữ liệu nhiệm vụ

Ngày ghi: 2026-10-16. Đây là sổ để tra nguồn, dùng khi đọc bảng hoặc script nhiệm vụ.

Trạng thái dự án vẫn nằm ở `docs/DU-AN.md`. Đặc tả cột đã mất của `docs/NHIEM-VU-VO-CONG-2026.md` không được dựng lại ở đây (quyết định D-5 trong `docs/DU-AN.md`). Tệp này cũng không phải schema chính thức của `MissionDictionary.txt` hay `MissionOutline.txt`: không có bản đối chiếu cột nào trong cây, và lần tìm web cùng ngày không thấy trang nào công bố thứ tự cột.

Mỗi mục dưới đây ghi nguồn của nó: tệp trong cây, công cụ, hay trang đã mở. Chỗ chỉ thấy trong kết quả tìm thì ghi là kết quả tìm, không ghi là đã đọc trang.

## 1. Hai nguồn, và trường nào được công cụ lấy

Máy chủ có hai nguồn, khai trong lời của `TOOLS/server/lua_extract.py` và trong `src/server/mission/catalog.hpp`:

- Danh bạ client 2026. Công cụ coi đây là thẩm quyền của tên, cấp, NPC giao và NPC trả. Lua chỉ quyết định logic.
- Script Lua 4.0 của cây 14 môn phái, đọc tĩnh từ `--lua <Public/Data>`. Công cụ không chạy Lua (`lua_syntax.py`, `lua_flow.py`). Hàm không hạ được về tập op thì ghi `status = unsupported` kèm lý do.

`lua_build.py` làm hai đường:

- `script_quest` lấy `g_MissionLevel`, `g_MissionName`, `g_MissionInfo`, `g_ContinueInfo`, `g_MissionComplete`, rồi `fill_from_client` ghi đè tên, loại, cấp tối thiểu, cảnh, NPC và tiền đề nếu id có trong danh bạ. `in_client = 1` khi id nằm trong danh bạ.
- `table_quest` lấy mục tiêu và thưởng từ năm bảng `Mission_*` của client 2026. Guid NPC lấy ô danh bạ chỉ số 14 và 16 khi id có mặt, không thì lấy guid của bảng. `repeat` là `loop` hoặc `once`.

Sửa tay các TSV sinh ra sẽ mất ở lượt xuất sau. Đầu `dev/server/tables/server/mission_quests.tsv` ghi `# source: Public/Data/Script` và `# tool: TOOLS/server/lua_extract.py`.

Lệnh sinh lại, chép từ lời công cụ: `python TOOLS/server/lua_extract.py --lua <Public/Data> --tables dev/server/tables --scenes dev/server/scenes --out dev/server/tables/server`. `--check` chạy hết nhưng không ghi bảng.

## 2. Client 2026 — bảng Config

`TOOLS/server/table_names.tsv`, cây `client_2026`, ánh xạ đã ghi:

| Tệp gốc | Tệp xuất |
|---|---|
| `MissionDictionary.txt` | `tables/shared/mission_dictionary.tsv` |
| `Mission_KillMonster.txt` | `tables/shared/quests_kill.tsv` |
| `Mission_LootItem.txt` | `tables/shared/quests_loot.tsv` |
| `Mission_Delivery.txt` | `tables/shared/quests_delivery.tsv` |
| `Mission_EnterArea.txt` | `tables/shared/quests_enter_area.tsv` |
| `Mission_Husong.txt` | `tables/shared/quests_escort.tsv` |
| `MissionItem_HashTable.txt` | `tables/shared/quest_item_pool.tsv` |
| `MissionItem_GroupHashTable.txt` | `tables/shared/quest_item_groups.tsv` |
| `MissionNPC_HashTable.txt` | `tables/shared/quest_npc_pool.tsv` |
| `MissionPet_HashTable.txt` | `tables/shared/quest_pet_pool.tsv` |
| `MissionKind.txt` | `tables/shared/mission_kinds.tsv` |
| `MissionOutline.txt` | `tables/shared/mission_outline.tsv` |

`TOOLS/server/table_census.tsv` ghi `MissionDictionary.txt`: 18 cột, 2139 dòng dữ liệu, kiểu `int,int,text,int,int,int,int,int,int,int,int,int,int,text,int,text,int,int`, sha256 `0ad87feb10562cb32d132f10d9478ce2d633892af5d78d83bada65dc66662088`. Phiên này đếm lại TSV đã xuất: 18 cột, 2139 dòng. Không tính lại sha256.

`TOOLS/server/columns/shared/mission_dictionary.tsv` ghi mọi cột `column_0` … `column_17` với chú thích `không có bản đối chiếu`.

`client_quest_summary` trong `TOOLS/server/lua_world.py` vẫn đọc các ô sau, và lời hàm ghi đây là suy từ dữ liệu, không phải bản đối chiếu:

| Chỉ số | Tên trong hàm |
|---|---|
| 1 | id nhiệm vụ |
| 2 | tên |
| 3 | loại |
| 5 | cảnh |
| 6 | cấp tối thiểu |
| 7 | cấp tối đa |
| 8 đến 12 | năm tiền đề |
| 13 | tên NPC giao |
| 14 | guid NPC giao |
| 15 | tên NPC trả |
| 16 | guid NPC trả |

`load_client_quests` chỉ nhận dòng có ít nhất 18 ô. Đếm lại: 2139 dòng đều đủ 18 ô, 1617 id khác nhau ở cột 1, trong đó có id giữ chỗ `-1`, không có ô không phải số.

Năm bảng `Mission_*`: lời `TOOLS/server/lua_tables.py` nói bố cục đo ngày 2026-10-14 bằng cách so tiêu đề `Public/Config/Mission_*.txt` của cây 14 môn phái với dữ liệu client 2026. Các cột trước cột tiền giống nhau. Từ cột tiền, client là tiền, tiền khoá, kinh nghiệm, rồi các cột sau lệch +1. Giữa nhóm thưởng ẩn và chỉ số nhiệm vụ kế tiếp, client có thêm một cột, lời công cụ nói cột ấy chưa dùng và luôn 0. Cùng lời nói bản máy chủ cũ chạy các bảng này bằng `event/EventScript/event_*.lua`, id 6666..6672, còn dự án này chạy bằng C++ trong module `mission`. Test đối chiếu là `test_lua_tables.py`. Phiên ghi sổ này không chạy lại test ấy.

Cùng cây `public_config` trong `table_names.tsv`, năm tệp `Mission_*.txt` và bốn bảng hash được đánh dấu `reference`, chú thích `đối chiếu tên cột, không xuất`.

`MissionOutline` có hai tệp xuất, cùng 994 dòng dữ liệu khi đếm dòng, hai bộ xuất khác nhau:

- `dev/server/tables/shared/mission_outline.tsv`, công cụ `export_tables.py`, nguồn `client_2026/MissionOutline.txt`. 26 cột, tên `column_0` … `column_25`.
- `dev/client/assets/Table/mission_outline.tsv`, dòng đầu nói sinh bằng `TOOLS/content/export_config.py` từ `Config/MissionOutline.txt`. Dòng chú thích ghi `994 dòng x 26 cột` và sha256 `ce81964446e22d389a7ffca3bac4b7dc82356573562fc852eb560a5ec7fe5d41`. Đếm lại: dòng tên cột và cả 994 dòng dữ liệu đều có 27 ô. Ô cuối tên là `scene_name`. Phiên này không tính lại sha256 và không so từng ô với bản 26 cột của `export_tables.py`.

`mission_kinds.tsv` ở `dev/server/tables/shared/` và ở `dev/client/assets/Table/` mỗi bên 200 dòng dữ liệu. Chưa so từng ô.

Script client `event/dali/edali_newquest_*.lua` và `edali_zhidao_*.lua` trong `table_names.tsv` đều là `deferred`, chú thích `script client, không xuất đợt này`. `lua_extract.py` đọc cây `Public/Data` đưa vào `--lua`, không đọc `src/client/script`.

## 3. Lua của cây 14 môn phái

Khảo sát chỉ đọc `docs/AUDIT/G-XJL7457.md`, ngày 2026-10-13: `Public\Config` có `Mission_*.txt` (KillMonster, Delivery, EnterArea, Husong, LootItem, NpcDefault) và `MissionNPC_HashTable.txt`. `Public\Data\Script` có 5494 tệp `.lua`. Cùng khảo sát: cây ấy có môn phái id 0–8 và 10–14, không có id 15; bảng tâm pháp của client 2026 có thêm id 15. Tên thư mục `XJL7457` không xuất hiện trong các trang mở ở mục 6.

`TOOLS/server/lua_out.py` ghi các bảng sau, `source` là `Public/Data/Script`, `layout` căn cột. Tên cột đúng như `SPECS`:

- `mission_quests`: script, quest, source, status, reason, in_client, kind, level, repeat, elite, name, detail, continue_text, complete_text, accept_scene, accept_guid, turn_scene, turn_guid, accept_cond, ready_cond, accept_fx, submit_fx, abandon_fx, next_quest, next_script, penalty, ban_slot, ban_seconds, path
- `mission_objectives`: script, seq, kind, index, target, count, item, rate, scene, flag, name
- `mission_rewards`: script, seq, group, kind, ref, count, cond
- `mission_prereqs`: script, prereq
- `mission_hooks`: script, seq, event, effects
- `mission_npcs`: script, role, guid, scene, name, how
- `mission_auto`: level, quest, script, pre_quest, event, full_level, complete_idx, record_idx, message
- `mission_name_groups`: group, template, name
- `ops_conditions`: set, clause, seq, op, neg, a1, a2, a3, word
- `ops_effects`: set, seq, op, a1, a2, a3, text, args, cond
- `talk_blocks`: block, seq, kind, cond, a, b, c, text, args
- `talk_entries`: script, num, block, status, reason
- `talk_npc_roles`: script, path, events
- `talk_npc_events`: script, seq, event

`catalog.hpp` còn có phân loại lúc nạp, khác cột `status` của TSV: `kRunnable`, `kUnsupported`, `kNotInClient`, `kBlocked`. Loại mục tiêu: `kTalk`, `kKill`, `kLoot`, `kDeliver`, `kArea`, `kEscort` (lời trong mã: chưa có bộ chạy), `kProgress`, `kCollect`. Khoá chính của danh mục là `script`. Nhiều dòng có thể cùng một `quest`.

## 4. Số đếm trên đĩa ngày 2026-10-16, trước khi gộp tân thủ

Số trong mục này đo trước khi `quest_chains.py` gộp 22 dòng. Số sau gộp ở mục 9.

Đếm `dev/server/tables/server/mission_quests.tsv` bằng `tsv_file.read_table`:

- 1349 dòng, 29 cột.
- `source`: `script` 207, `table` 1142.
- `status`: `ok` 1202, `unsupported` 147. Chỉ hai giá trị này.
- `in_client`: `1` có 1308 dòng, `0` có 41 dòng. 39 id có mọi dòng `in_client = 0`. Không có id nào vừa có dòng `0` vừa có dòng `1`.
- 829 id khác nhau ở cột `quest`. 701 id có ít nhất một dòng `ok`. 128 id không có dòng `ok` nào.
- 827 id của danh bạ không có dòng nào trong bảng này. Trong 827 có id `-1`. 22 id 1400–1408 và 1412–1424 nằm trong 827. Cột `quest` không có id nào từ 1400 đến 1424.

Lý do gặp nhiều nhất trong cột `reason`, đúng chuỗi của ô:

| Số dòng | Lý do |
|---|---|
| 14 | `OnAccept: phép tính * trên giá trị không phải hằng số` |
| 13 | `CheckSubmit: id vật phẩm không phải số nguyên hằng` |
| 9 | `CheckAccept: chỉ số dữ liệu nhiệm vụ không phải số nguyên hằng` |
| 8 | `OnAccept: API GetMonsterCount` |
| 8 | `OnAccept không AddMission đúng nhiệm vụ` |
| 5 | `CheckAccept: API LuaFnGetSceneType` |
| 5 | `CheckAccept: API LuaFnGetCopySceneData_Param` |
| 5 | `CheckAccept: thiếu hàm CheckAccept` |

`docs/SERVER-MISSION.md` mục 3 ghi số của `mission_data_tests` lúc commit `9e0cc4d0`: 1349 nhiệm vụ, 1063 chạy được, 260 chưa hỗ trợ, 26 ngoài client, 0 bị chặn. Đó là phân loại của catalog sau khi nạp, trước lần gộp. Lần chạy sau khi gộp ở mục 9. Mục 5 của cùng tệp, đo 2026-10-15, ghi 1617 id và 827 id vắng, trong đó 22 id 1400–1408 và 1412–1424: hai số này trùng với lần đếm lại ở trên, cũng là lúc các id ấy chưa có dòng máy chủ.

Tìm chữ `1400` trong cùng TSV gặp 4 dòng có cột `quest` khác 1400, vì guid NPC chứa các chữ số đó: quest 610 script 1030170, quest 611 script 1030171, quest 612 script 1030172 (cả `accept_guid` và `turn_guid`), quest 614 script 1010171 (`turn_guid`). Đó không phải id nhiệm vụ 1400.

Trong các dòng đã đọc của bảng này có nhiệm vụ kịch tính cấp 20 ở `event/juqing/wanjiegu_*.lua` (ví dụ quest 5, tên `相会在万劫谷`) và cấp 30 ở `event/juqing/yanziwu_*.lua` (ví dụ quest 11, tên `独战双雄`). Các dòng ấy là chuỗi khác với script `edali_newquest_*.lua` ở mục 5.

## 5. Id 1400–1424 trong script client

Thư mục `src/client/script/Config/event/dali/` có 22 tệp `edali_newquest_*.lua`: `000`–`010` và `013`–`023`. Không có `011` và `012`. Id 1409, 1410, 1411 không có trong các gán `g_MissionId` đã quét, không có trong danh bạ, và không có trong cột `quest`.

Bảng dưới lấy từ dòng gán đầu tiên của từng tệp (`g_ScriptId`, `g_MissionId`, `g_MissionName`, `g_MissionLevel`, `g_MissionIdPre` hoặc `g_MissionIdPer`, `g_NextScriptId`). Cột danh bạ là ô tên (chỉ số 2) của `mission_dictionary.tsv`, cùng id. Thứ tự theo `g_NextScriptId`, bắt đầu từ script 210262.

| Tệp | Script | Mission | Tên trong script | Tên ô danh bạ | Cấp script | Tiền đề trong script | Script kế |
|---|---|---|---|---|---|---|---|
| `edali_newquest_001.lua` | 210262 | 1400 | 初涉江湖 | 初入江湖 | 1 | `g_MissionIdPre = 0` | 210255 |
| `edali_newquest_002.lua` | 210255 | 1401 | 第一把武器 | cùng chữ | 1 | 1400 | 210256 |
| `edali_newquest_003.lua` | 210256 | 1402 | 第一件防具 | cùng chữ | 1 | 1401 | 210257 |
| `edali_newquest_004.lua` | 210257 | 1403 | 第一次杀怪 | cùng chữ | 2 | 1402 | 210258 |
| `edali_newquest_005.lua` | 210258 | 1404 | 回访天师 | cùng chữ | 3 | 1403 | 210263 |
| `edali_newquest_006.lua` | 210263 | 1405 | 初级技能 | cùng chữ | 3 | `g_MissionIdPre = 0` | 210259 |
| `edali_newquest_007.lua` | 210259 | 1406 | 灵丹妙药 | cùng chữ | 4 | 1405 | 210273 |
| `edali_newquest_008.lua` | 210273 | 1407 | 剑阁猴患 | cùng chữ | 4 | 1406 | 210274 |
| `edali_newquest_009.lua` | 210274 | 1408 | 大理怪人 | cùng chữ | 5 | 1407 | 210280 |
| `edali_newquest_010.lua` | 210280 | 1423 | 何谓行善 | cùng chữ | 5 | 1408 | 210275 |
| `edali_newquest_013.lua` | 210275 | 1412 | 再访天师 | cùng chữ | 6 | 1423 | 210276 |
| `edali_newquest_014.lua` | 210276 | 1413 | 珍兽家族 | cùng chữ | 7 | không có dòng `g_MissionIdPre` | 210264 |
| `edali_newquest_015.lua` | 210264 | 1414 | 第一只珍兽 | cùng chữ | 7 | 1413 | 210265 |
| `edali_newquest_016.lua` | 210265 | 1415 | 抓珍兽 | cùng chữ | 7 | 1414 | 210277 |
| `edali_newquest_017.lua` | 210277 | 1416 | 三访天师 | cùng chữ | 8 | 1415 | 210266 |
| `edali_newquest_018.lua` | 210266 | 1417 | 大理美景 | 喜庆焰火 | 8 | không có dòng `g_MissionIdPre` | 210278 |
| `edali_newquest_019.lua` | 210278 | 1418 | 大善人 | cùng chữ | 8 | 1417 | 210267 |
| `edali_newquest_020.lua` | 210267 | 1419 | 江湖问答 | cùng chữ | 9 | 1418 | 210269 |
| `edali_newquest_021.lua` | 210269 | 1420 | 最后的试炼 | cùng chữ | 9 | 1419 | 210268 |
| `edali_newquest_022.lua` | 210268 | 1421 | `#{XMPHM_210604_22}` | 十一大门派 | 10 | `g_MissionIdPer = 1424` | 210279 |
| `edali_newquest_023.lua` | 210279 | 1422 | 宏大的江湖 | cùng chữ | 10 | 1421 | không có dòng `g_NextScriptId` |
| `edali_newquest_000.lua` | 210270 | 1424 | 十年 | cùng chữ | 1 | không có dòng `g_MissionIdPre` | 210268 |

Ba tên không trùng giữa script và danh bạ: 1400, 1417, 1421. Khoá `#{XMPHM_210604_22}` chưa được giải ra chữ. 19 id còn lại, ô tên danh bạ trùng `g_MissionName`.

Với cả 22 id, danh bạ ghi cảnh (chỉ số 5) là 2, cấp tối thiểu (chỉ số 6) trùng `g_MissionLevel`, cấp tối đa (chỉ số 7) hơn cấp tối thiểu đúng 20, loại (chỉ số 3) là 0. Bốn ô tiền đề sau ô đầu, và cả bốn ô NPC, đều là `-1`. Khi script có `g_MissionIdPre` là một id dương, ô tiền đề đầu của danh bạ là id đó. Khi script ghi `0` hoặc không có dòng `g_MissionIdPre`, ô tiền đề đầu của danh bạ cũng là `-1`. `g_MissionIdPer = 1424` của mission 1421 không nằm trong các ô tiền đề của danh bạ.

`edali_newquest_001.lua` còn ghi: cảnh 2, toạ độ 160 và 158, NPC hoàn thành và `g_Name` đều là 赵天师, `g_MissionKind = 13`, `g_MoneyBonus = 1`, `g_ExpBonus = 50`, biển chỉ `SignPost` cùng 160, 158. `edali_newquest_002.lua` ghi cảnh 2, toạ độ 219 và 123, NPC hoàn thành 蒲良, `g_Name` là 赵天师, `g_MissionKind = 13`, `g_MoneyBonus = 1`, `g_ExpBonus = 50`. Các tệp còn lại trong bảng chưa được đọc hết phần toạ độ và thưởng.

Một script cũ cùng thư mục, `edali_zhidao_0200.lua`, cũng có `g_MissionName="第一把武器"` nhưng là nhiệm vụ khác: `g_ScriptId = 210200`, `g_MissionId = 440`, `g_MissionLevel = 1`, `g_MissionKind = 13`, cảnh 2, toạ độ 219 và 123, cả `g_Name` và NPC hoàn thành đều là 蒲良, `g_MoneyBonus=1`. `table_names.tsv` cũng đánh dấu tệp này `deferred`.

`Interface/QuestLog/QuestLog.lua` chú thích script 210262 là 初涉江湖, 210255 là 第一把武器, và đặt 210256 cùng 890252 dưới một chú thích 第一件防具. Script 890252 nằm ở `Config/event/wuliang/emission_2.lua`: `g_MissionId = 1683`, `g_MissionName = "#{XSLC_130831_03}"`, cảnh 6, NPC hoàn thành 遇险的钟灵, `g_MissionLevel = 1`.

`Interface/MainMenuBar/MainMenuBar.lua` chú thích `Mission:1400` là 初涉江湖 và `Mission:1424` là 十年. `Interface/MissionTrack/MissionTrack.lua` có nhánh đang dùng chú thích `Mission:1424` là 十年, và một nhánh đã chú thích bằng `--` ghi `Mission:1424` là 初涉江湖.

Cây `src/client/script` có `Config/event/dali/xinshoujineng.lua` và các thư mục giao diện `XinShou*`. Phiên này không đọc nội dung các tệp đó. Không có tên tệp nào khớp chuỗi hiện trên trang DieAngel ở mục 6.

`Script.dat` của `G:\XJL7457` chưa được mở để xem có id 210200 hoặc 210262 hay không.

## 6. Trang công khai đã mở

Đã mở nguyên văn ngày 2026-10-16. Các trang này là ghi chú người chơi hoặc ghi chú máy chủ cũ. Chúng không phải schema cột của client 2026.

[01zt, bài giới thiệu tệp máy chủ](https://www.01zt.com/forum-post/1581.html) viết nguyên câu: `Mission开头的文件是各种任务相关，奖励、经验等。不包括剧情任务`. Cùng bài: `Script.dat` là số của mọi script; script thêm mới phải có đường dẫn và số trong `Script.dat`; tệp cùng tên giữa máy chủ và `config.axp` của client thì đồng bộ, riêng `ImpactSEData_V1.txt` thì bài nói không thay chéo hai chiều. Bài không liệt kê thứ tự cột.

[DieAngel, 2012-08-21, bài ghi là bài chuyển](https://www.cnblogs.com/dieangel/archive/2012/08/21/3326955.html) liệt kê tên hàm script: `OnDefaultEvent`, `OnKillObject`, `OnItemChanged`, `OnPetChanged`, `OnEnterArea`, `OnLeaveArea`, `OnTimer`, `OnMissionAccept`, `OnAbandon`, `OnMissionRefuse`, `OnMissionSubmit`, `OnMissionCheck`, `OnMissionContinue`. Bài nói id script là 6 chữ số, và `Script.dat` ánh xạ id sang tên tệp, nạp theo cảnh trong `Scene::Load`. Phần mẫu về 赵天师, đúng chuỗi nhìn thấy trên trang (dấu `\` của đường dẫn không còn trong văn bản trang trả về): tên script `Scriptobjdaliodali_xinshoutian.lua`, `x002030_g_scriptId = 002030`, danh sách sự kiện bắt đầu bằng 210200 và không có 210262 trong đoạn đã in, rồi `210200=eventdaliedali_zhidao_0200.lua` với hai dòng chú thích `大理城新手指导任务` và `赵天师寻找蒲良`. Đó là mô tả một cây máy chủ cũ trong bài, không phải bằng chứng về `G:\XJL7457` và không phải chuỗi `edali_newquest_*.lua`.

[Trang hướng dẫn tân thủ của Changyou](https://tl.changyou.com/events/helper/index87.shtml), mục 新手任务. Đây là hướng dẫn người chơi: không có id nhiệm vụ, không có id script, không có tên tệp. Trang nói nhiệm vụ đầu là 初涉江湖, nói chuyện với 赵天师 tại `[160,156]`, thưởng ghi là 1 đồng và một phần kinh nghiệm; rồi 第一把武器 tại 蒲良 `[216，135]`. Câu mở nói hoàn thành hết chuỗi tân thủ thì nhân vật ở khoảng cấp 10. Thứ tự tên trên trang: 初涉江湖, 第一把武器, 第一件防具, 第一次杀怪, 回访天师, 初级技能, 灵丹妙药, 剑阁猴患, 大理怪人, 何谓行善, 再访天师, 珍兽家族, 第一只珍兽, 抓珍兽, 三访天师, 喜庆焰火, 大善人, 江湖问答, 最后的试炼, 十四大门派, 宏大的江湖, NPC cuối 崔逢九 `[241,137]`.

Chỗ trang này và tệp trong cây cùng nói một việc thì ghi cả hai, vì số không trùng hết:

- Toạ độ 赵天师 trên trang là `[160,156]`. `edali_newquest_001.lua` ghi 160 và 158.
- Toạ độ 蒲良 trên trang là `[216，135]`. `edali_newquest_002.lua` và `edali_zhidao_0200.lua` đều ghi 219 và 123.
- Tên 初涉江湖 trên trang trùng script và trùng chú thích `MainMenuBar`, trong khi ô danh bạ của id 1400 là 初入江湖.
- Tên 喜庆焰火 trên trang trùng ô danh bạ của id 1417, trong khi `g_MissionName` của script ấy là 大理美景.
- Tên 十四大门派 trên trang nằm giữa 最后的试炼 và 宏大的江湖 trong lời trang. Script nằm giữa hai tên đó theo `g_NextScriptId` là mission 1421, `g_MissionName` là khoá `#{XMPHM_210604_22}`, ô danh bạ là 十一大门派.
- Trang không có tên 十年 và không có tên 大理美景. Script 1424 và danh bạ cùng ghi 十年.

## 7. Chỗ dễ lấy nhầm

- `第一把武器` xuất hiện ở mission 1401 script 210255 và ở mission 440 script 210200. Cùng một chuỗi tên, hai id.
- Chữ `1400` trong `mission_quests.tsv` gặp guid của quest 610–612 và 614. Trước lần gộp, cột `quest` của dải 1400–1424 trống. Sau lần gộp ở mục 9, cột ấy có 22 id.
- Cột `status` của TSV (`ok` 1202, `unsupported` 147) và số `1063 / 260 / 26 / 0` trong `SERVER-MISSION.md` mục 3 là hai lần phân loại khác nhau. Số sau là test lúc commit `9e0cc4d0`, chưa chạy lại.
- Thứ tự id số và thứ tự `g_NextScriptId` khác nhau: 何谓行善 là 1423 và đứng trước 再访天师 1412 trên đường `NextScriptId`. 十年 là 1424, tệp `000`, cấp 1, `g_NextScriptId` trỏ tới 210268.
- Nhánh chú thích đã tắt trong `MissionTrack.lua` ghi `Mission:1424` là 初涉江湖. `g_MissionName` và ô danh bạ cùng ghi 十年. Nhánh đang dùng của cùng tệp cũng chú thích 十年.
- Chú thích `QuestLog.lua` gom 890252 với 第一件防具. Tệp script của 890252 ghi mission 1683.
- Bài 01zt nói tệp tên `Mission*` không gồm nhiệm vụ kịch. `mission_quests.tsv` của dự án vẫn có dòng `source = script` từ `event/juqing/`, vì công cụ trích script chứ không chỉ đọc năm bảng `Mission_*`.
- Ô danh bạ được `client_quest_summary` gọi là loại đang là 0 với 22 id này. `edali_newquest_001.lua` và `edali_newquest_002.lua` ghi `g_MissionKind = 13`. Lần gộp ở mục 9 không gọi `fill_from_client`. Nếu một lượt xuất sau gọi hàm ấy lên 22 id này, ô danh bạ sẽ ghi đè tên script và loại 13.

## 8. Chưa làm trong lần ghi này

- Chưa mở `Script.dat` của `G:\XJL7457` cho 210200 và 210262.
- Chưa giải `#{XMPHM_210604_22}` và `#{XSLC_130831_03}`.
- Chưa so từng ô hai bản `mission_outline.tsv`, chưa tính lại sha256 ghi trong đầu tệp client.
- Chưa chạy lại `test_lua_tables.py`. Đã chạy lại `mission_data_tests` sau khi gộp; số ở mục 9.
- Chưa đọc `xinshoujineng.lua`.
- Kết quả tìm có một đoạn của [szonline, 2023-03-21](http://m.szonline.cn/care/rd/2023/0321/131192.html) nói chuỗi kịch bắt đầu ở cấp 20 (万劫谷) và cấp 30 (燕子坞), NPC giao là 赵天师. Trang đó chưa được mở hết. Phần đã chắc nằm ở các dòng `event/juqing/` của mục 4.
- Tìm `XJL7457`, `MissionDictionary` và `MissionOutline` kèm từ khoá nhiệm vụ không ra trang nào ghi thứ tự cột, cũng không ra trang nào dùng tên thư mục `XJL7457`. Các kết quả còn lại là hướng dẫn game khác, tiểu thuyết, hoặc bài cấu hình của game 传奇. Không dùng chúng làm nguồn.

## 9. Chuỗi tân thủ đã gộp

22 tệp `src/client/script/Config/event/dali/edali_newquest_*.lua` chỉ có khối MisDesc, hết ở `--MisDescEnd`. Không có `OnAccept` hay `OnSubmit`, nên `lua_flow` không hạ được. `TOOLS/server/newquest.py` đọc tĩnh và dựng `source = table`. Bộ chạy bảng là: một `DemandTrueKill` có tên và số lớn hơn 0 thành mục tiêu giết; một custom mở đầu bằng `已找到` thành mục tiêu nói chuyện; mọi custom mở đầu bằng `学习` và khớp hết thầy trong `edali_zhidao_0209.lua` cùng `skill_id` nhỏ nhất có icon `FightSkillXinShou` thành mục tiêu học (mở hội thoại với thầy thì học); đúng một custom `已达等级` với `num` lớn hơn 0 thành mục tiêu đạt cấp. Còn lại giữ `status = unsupported`. Thưởng của script vẫn ghi, kể cả dòng chưa chạy được. `g_MissionIdPre` dương mới là tiền đề. `g_MissionIdPer` của 1421 không phải tiền đề. `g_AcceptNPC_Name` khác `g_Name` thì NPC giao lấy tên đó; 1405 giao ở 赵天师 và trả ở 钱龙.

`fill_from_client` không áp cho 22 id này. Ô NPC danh bạ là `-1`. Ô loại là 0, không có trong `mission_kinds` (loại bắt đầu từ 1; script ghi 13, tức 大理). Ba tên lệch giữ nguyên tên script: 1400 script `初涉江湖` và ô danh bạ `初入江湖`; 1417 script `大理美景` và ô danh bạ `喜庆焰火`; 1421 script `#{XMPHM_210604_22}` và ô danh bạ `十一大门派`. Khoá chuỗi không có trong `StrDictionary.tsv` thì để nguyên.

`TOOLS/server/quest_chains.py` ghi một lần `docs/NHIEM-VU-CHUOI.xlsx` và gộp vào các bảng `mission_*` mà `lua_extract.py` sở hữu. Lệnh: `py -B TOOLS/server/quest_chains.py`. `--check` in kế hoạch và không ghi. Lượt `lua_extract` sau gọi `newquest.append_quests` trước `resolve_next`. Sửa tay các TSV này sẽ mất ở lượt xuất đó.

Tiền và kinh nghiệm giữ số trong script, không quy đổi chữ trên trang hướng dẫn. Vòng cày có sẵn không chỉnh số. Id chỉ có trong danh bạ không được bịa thành nhiệm vụ. Bước không có bộ chạy không đổi thành nói chuyện.

Đếm `mission_quests.tsv` sau lần gộp học kỹ năng và đạt cấp, cùng ngày: 1371 dòng. 22 dòng có đường `Config/event/dali/edali_newquest_`: 16 `ok`, 6 `unsupported`, mọi dòng `source = table`. Tên giữ đúng script, gồm `初涉江湖` ở 1400 và khoá `#{XMPHM_210604_22}` ở 1421. 1405 có hai mục tiêu `skill`: mã 244 với 张获 (guid 3202248) và mã 248 với 程青霜 (guid 3542065). 1424 có một mục tiêu `level` với số 10; thưởng là tiền khoá 500; `g_exp` bằng 0 nên không có dòng kinh nghiệm.

`talk::Service::talk` ghi lần gặp NPC (`bus::Kind::kTalk`) trước khi dựng hội thoại. `choose` không ghi. `Gameplay::sync` gửi `kLevelUp` khi cấp tăng, `a` là cấp mới và `c` là cấp đã gửi. Học kỹ năng ghi vào `actor::Record`: sổ rỗng vẫn là phiên bản 1, có kỹ năng thì phiên bản 2.

`build/msvc-release/mission_data_tests.exe` dựng lại rồi chạy trên bảng sau gộp. Output:

- `[độ phủ] 1371 nhiệm vụ: chạy được 1079, chưa hỗ trợ 266, ngoài client 26, bị chặn 0; 18 có tiền đề ngoài danh mục`
- `[đi hết] nhiệm vụ bảng chạy được: 1045, đi hết nhận-tiến độ-nộp: 1045`
- `[chuỗi] dài nhất 50 nhiệm vụ (bắt đầu script 1020100, cấp 75), đi hết 50`
- `[chuỗi] cấp thấp nhất 9 nhiệm vụ (bắt đầu script 210262, cấp 1), đi hết 9`
- Bốn ca `real_catalog_loads`, `every_table_quest_completes`, `longest_chain_end_to_end`, `lowest_chain_end_to_end`: đạt.

Đoạn người chơi đi được khi đứng nói chuyện với NPC: 1400 tới 1408 (dừng trước 1423), nhánh 1413, và 1424 đạt cấp 10 (dừng trước 1421). 1412, 1416, 1418, 1420, 1422 có bộ chạy nhưng đứng sau bước không nộp được. Sáu bước không có bộ chạy, cố ý: 1414 trân thú lên cấp, 1415 bắt trân thú, 1417 đốt pháo, 1419 năm câu hỏi, 1421 vào môn phái, 1423 bốn món tặng không có mã vật phẩm. Ca `every_table_quest_completes` đánh dấu tiền đề là xong trước khi thử, nên 16 dòng `ok` đều nộp được trong test; người chơi thật không vượt bước unsupported.

`actor_tests` và `talk_flow_tests` cùng lượt dựng đều đạt, gồm ca học kỹ năng (phiên bản 1/2) và ca mở hội thoại ghi mục nói chuyện. `test_lua_tables.py` chưa chạy lại. Client HUD và zone thật chưa chạy với bảng này.

Hội thoại danh sách (`kList`, `kBox`) gắn thêm một dòng dấu cho mỗi nhiệm vụ của NPC, sau lời NPC, khi còn chỗ trong 16 dòng của `DialogOpen`. Dạng là `TLQ`, dấu US, `1` nhận hoặc `2` đang làm hoặc `3` nộp được (đúng `MarkStage` của protocol), dấu US, id thập phân, dấu US, tên trong danh mục. Có biến thể chạy được thì lấy tên biến thể đó. Client vẽ `!tên` thành nút gửi `QuestAccept`, `?tên` của bước nộp được thành nút gửi `QuestTurnIn` với thưởng `-1`, bước đang làm chỉ là chữ. Thiếu tên thì nút hiện số id. Chỉ số nút là cục bộ (`0x8000+id`, `0x9000+id`), không đi qua `DialogChoose`. Nộp khi `Engine::turn_in` trả `kNeedChoice` thì giữ phiên và mở bảng nộp (`kDemand`) với tiền thường, vật phẩm cố định và các món chọn một. Tiền khoá, kinh nghiệm, quan hệ và nhóm ẩn không có ô trên dây đó. `Engine::turn_in` không đổi. Ca `talk_accept_and_keep` thấy tên `初涉江湖` trong lời của 赵天师 cấp 30. Cửa sổ client thật chưa mở. Sáu bước 1414, 1415, 1417, 1419, 1421, 1423 vẫn `unsupported`.
