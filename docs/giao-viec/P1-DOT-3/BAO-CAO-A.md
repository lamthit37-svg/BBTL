# Báo cáo vai A

## 1. Tệp đã tạo hoặc sửa

- `TOOLS/server/column_terms.tsv`: gộp dòng một nghĩa thành `scope` rỗng, giữ dòng `code:` đúng bảng mã đọc, thêm nhãn của 106 cặp.
- `TOOLS/server/diff_tables.py`, `TOOLS/server/test_diff_tables.py`.
- `TOOLS/server/refs/shared.tsv`: 25 dòng.
- `SERVER/tables/shared`, `SERVER/tables/variants`, `TOOLS/server/columns/shared`: xuất lại. Ô dữ liệu không đổi; dòng tên cột đổi ở 84 bảng.

Không sửa `glossary.tsv`, `column_names.py`, `lint_names.py`, `table_refs.py`, test của các tệp đó, `table_names.tsv`, `moc/`, `refs/server.tsv`, `refs/scenes.tsv`.

## 2. Đã kiểm

Đỏ, trước khi có `diff_tables.py`. Exit 1.

```text
python -B -W error -m unittest discover -s TOOLS/server -p test_diff_tables.py
ModuleNotFoundError: No module named 'diff_tables'
Ran 1 test in 0.000s
FAILED (errors=1)
```

Xanh sau khi có module. Exit 0.

```text
python -B -W error -m unittest discover -s TOOLS/server -p test_diff_tables.py
Ran 4 tests in 0.202s
OK

python -B -W error TOOLS/server/lint_py.py TOOLS/server/diff_tables.py TOOLS/server/test_diff_tables.py
```

`lint_py.py` không in lỗi.

`python -B -W error -m unittest` của `test_align_columns.py` (11) và `test_column_names.py` (5) đều OK.

Xuất lại sang `build/p1-a/tables`, 221,8 giây, exit 0:

```text
bảng đã ghi: 635
bản ghi: 994925
cột: 17247
cột có tên: 2586
cột còn ?: 130
```

So với `SERVER/tables` trước khi chép đè: 0 tệp lệch ô dữ liệu hoặc dòng `#`. 84 tệp chỉ lệch dòng tên cột, 551 tệp nguyên. `column_alignment.tsv` cùng SHA-256. Đã chép 635 bảng client và 635 tệp cột, không đụng `tables/server`.

`diff_tables.py --check` trên cây thật, exit 0:

```text
cặp: 106
ids_2026: 354614
ids_legacy: 62374
common: 61522
only_2026: 293092
only_legacy: 852
dòng tham chiếu: 55
dòng có giá trị thiếu: 6
```

Năm tổng hiệu id trùng mục 3. So thêm nguyên văn ô đầu với khoá theo kiểu: 0 bảng lệch.

## 3. Số đo

`column_terms.tsv`: 707 dòng. `glossary` 15, `code` 105, `direct` 587. `scope` rỗng 635, `scope` theo tệp 72.

Luật đã đặt tên, đếm trên cột shared kể cả biến thể: nguyên văn 1.765, mẫu `{n}` 157, M1 497, M2 167. Cộng 2.586, khớp dòng `cột có tên` của lần xuất.

Trước khi mở thuật ngữ ra mọi bảng: 891 cột có tên. Sau: 2.586. 546 tệp cột không đổi số tên. 89 tệp đổi, cột trước, sau, và số tăng:

| Bảng | Trước | Sau | Tăng |
|---|---|---|---|
| activity_notices.tsv | 10 | 13 | 3 |
| attack_traits.tsv | 8 | 9 | 1 |
| bullets.tsv | 9 | 10 | 1 |
| bus_types.tsv | 1 | 8 | 7 |
| chat_channels.tsv | 1 | 11 | 10 |
| drop_broadcasts.tsv | 0 | 5 | 5 |
| effect_instant_visuals.tsv | 1 | 17 | 16 |
| equipment.tsv | 9 | 93 | 84 |
| equipment_enhance.tsv | 0 | 1 | 1 |
| equipment_extra_attributes.tsv | 1 | 4 | 3 |
| equipment_level_up_odds.tsv | 1 | 3 | 2 |
| equipment_sets.tsv | 0 | 17 | 17 |
| equipment_slot_costs.tsv | 1 | 2 | 1 |
| equipment_visual_groups.tsv | 11 | 12 | 1 |
| face_models.tsv | 4 | 5 | 1 |
| gem_carving.tsv | 0 | 4 | 4 |
| gem_melting.tsv | 0 | 5 | 5 |
| gems.tsv | 5 | 77 | 72 |
| grow_point_types.tsv | 0 | 7 | 7 |
| guild_cities.tsv | 1 | 18 | 17 |
| guild_research_conditions.tsv | 1 | 2 | 1 |
| hair_models.tsv | 4 | 5 | 1 |
| hit_level_modifiers.tsv | 1 | 2 | 1 |
| id_collections.tsv | 30 | 35 | 5 |
| inner_art_learn_costs.tsv | 0 | 1 | 1 |
| item_aptitude_rates.tsv | 0 | 7 | 7 |
| item_segment_values.tsv | 1 | 32 | 31 |
| items_common.tsv | 15 | 21 | 6 |
| life_skill_levels/advanced_life.tsv | 0 | 8 | 8 |
| life_skill_levels/assistant.tsv | 0 | 4 | 4 |
| life_skill_levels/assistant_sect.tsv | 0 | 4 | 4 |
| life_skill_levels/basic_life.tsv | 0 | 8 | 8 |
| life_skill_levels/cooking.tsv | 0 | 8 | 8 |
| life_skill_levels/crafting.tsv | 0 | 11 | 11 |
| life_skill_levels/fishing.tsv | 0 | 8 | 8 |
| life_skill_levels/forging.tsv | 0 | 11 | 11 |
| life_skill_levels/gem_setting.tsv | 0 | 8 | 8 |
| life_skill_levels/health.tsv | 0 | 4 | 4 |
| life_skill_levels/herb_gathering.tsv | 0 | 7 | 7 |
| life_skill_levels/life_assist.tsv | 0 | 4 | 4 |
| life_skill_levels/locator_charm.tsv | 0 | 6 | 6 |
| life_skill_levels/medicine_making.tsv | 0 | 7 | 7 |
| life_skill_levels/mining.tsv | 0 | 7 | 7 |
| life_skill_levels/normal.tsv | 0 | 8 | 8 |
| life_skill_levels/pharmacology.tsv | 0 | 4 | 4 |
| life_skill_levels/planting.tsv | 0 | 8 | 8 |
| life_skill_levels/sect.tsv | 0 | 8 | 8 |
| life_skill_levels/sect_assist.tsv | 0 | 4 | 4 |
| life_skill_levels/sect_life.tsv | 0 | 7 | 7 |
| life_skill_levels/tailoring.tsv | 0 | 11 | 11 |
| life_skills.tsv | 1 | 21 | 20 |
| mentor_exp_share.tsv | 0 | 2 | 2 |
| money_caps_by_level.tsv | 1 | 3 | 2 |
| monster_respawn_points.tsv | 49 | 52 | 3 |
| monsters.tsv | 47 | 64 | 17 |
| mounts.tsv | 4 | 7 | 3 |
| pet_exp_levels.tsv | 0 | 1 | 1 |
| pet_pill_compounds.tsv | 0 | 3 | 3 |
| pet_rejuvenation_costs.tsv | 0 | 2 | 2 |
| pet_skill_books.tsv | 0 | 2 | 2 |
| pet_skill_upgrades.tsv | 0 | 4 | 4 |
| pet_titles.tsv | 4 | 8 | 4 |
| pet_types.tsv | 0 | 3 | 3 |
| pets.tsv | 0 | 37 | 37 |
| portraits.tsv | 5 | 10 | 5 |
| quest_item_pool.tsv | 0 | 652 | 652 |
| quest_npc_pool.tsv | 0 | 6 | 6 |
| quest_pet_pool.tsv | 0 | 17 | 17 |
| quests_delivery.tsv | 2 | 44 | 42 |
| quests_enter_area.tsv | 2 | 28 | 26 |
| quests_escort.tsv | 2 | 27 | 25 |
| quests_kill.tsv | 2 | 54 | 52 |
| quests_loot.tsv | 2 | 55 | 53 |
| recipes.tsv | 13 | 24 | 11 |
| recycle_classes.tsv | 1 | 2 | 1 |
| recycle_items.tsv | 3 | 4 | 1 |
| recycle_types.tsv | 3 | 4 | 1 |
| repair_rates.tsv | 1 | 4 | 3 |
| reputation_factions.tsv | 1 | 4 | 3 |
| scene_attributes.tsv | 13 | 14 | 1 |
| scene_trade_zones.tsv | 1 | 4 | 3 |
| shop_scene_limits.tsv | 1 | 12 | 11 |
| shops.tsv | 78 | 166 | 88 |
| special_objects.tsv | 22 | 23 | 1 |
| storyteller_dialogue.tsv | 0 | 2 | 2 |
| titles.tsv | 1 | 5 | 4 |
| trade_zone_relations.tsv | 0 | 22 | 22 |
| treasure_maps.tsv | 7 | 15 | 8 |
| variants/level_cap/shops.tsv | 78 | 166 | 88 |

Số trước được tính lại: bảng không thuộc mười một bảng ưu tiên chỉ nhận M1/M2 và dòng `code:` đúng `scope`; bảng ưu tiên nhận thêm thuật ngữ cũ đã gộp. Không còn bản tệp cột trước lần sửa.

130 cột còn `?`, không kể 14.531 nhãn rỗng ngoài đợt:

- 65 cột `MissionItem_GroupHashTable.txt`, dạng `{số}-{tên nhân vật}-{số}`. Không phiên âm. Không có tên Latin sẵn trong phụ lục.
- 64 cột `ReputationTable.txt`, nhãn chỉ là `0` tới `63`. Nhãn không nói các số đó là gì.
- `起手音xiao` của `SkillTemplate_V1.txt`. Nhãn cụt, không chắc là âm thanh lúc ra chiêu.

D-09 trên bảng shared: 0 nhãn khớp M1 hoặc M2 còn tên `column_<n>`. `RepairType(修理类型)` thành `repair_type`, `PNUM(...)` thành `pnum_1`...

Năm tổng hiệu id như mục 2. Mười cặp `only_legacy` lớn nhất:

| Nguồn | only_legacy | only_2026 | common |
|---|---|---|---|
| CityIdOfChina.txt | 318 | 318 | 22 |
| CampaignTable.txt | 141 | 66 | 40 |
| CommonItem.txt | 108 | 15635 | 4839 |
| ActivityNotice.txt | 77 | 154 | 71 |
| Mission_Delivery.txt | 49 | 175 | 497 |
| MonsterAttrExTable.txt | 32 | 19466 | 9503 |
| EquipExtraAttr.txt | 29 | 25014 | 778 |
| Mission_KillMonster.txt | 27 | 5 | 147 |
| AbilityExpTable.txt | 20 | 20 | 0 |
| Mission_NpcDefault.txt | 16 | 16 | 0 |

`refs/shared.tsv`, `missing_values`:

| Cột con | Cột cha | Thiếu |
|---|---|---|
| skills.inner_art_id | inner_arts.inner_art_id | 0 |
| skills.bullet_id | bullets.id | 0 |
| skills.skill_id_at_inner_art_level_1 tới _16 | skill_levels.id | 0 |
| monsters.attack_trait_id | attack_traits.id | 1 |
| items_common.required_skill | life_skills.id | 0 |
| grow_point_types.life_skill_id | life_skills.id | 0 |
| recycle_items.item_id | items_common.index | 0 |
| pet_skill_books.item_id | items_common.index | 0 |
| face_models.cost_item_id | items_common.index | 0 |
| gem_carving.required_item_id | items_common.index | 0 |

Thiếu một giá trị: `31`, 18 dòng quái. Các id còn gặp là 4, 10, 11, 12, 13 và đều có trong `attack_traits.id`, nên không phải ghép nhầm cột. `0` là một đặc tính thật nên không đưa vào `absent`. Không thấy cột cha shared nào định tham chiếu mà bị lặp khoá.

`special_objects.bullet_id` khớp 0% với cột gốc nên không đưa vào refs. `skills.pet_skill_effect_id` chỉ có 1 giá trị khác `-1` và `0`, không đủ để chọn bảng cha.

## 4. Bảng nợ

| Mã | Trạng thái | Chứng |
|---|---|---|
| D-02 | Đã trả phần A | `inner_art_refix_parameter` thành `inner_art_level_modifier_parameter`. `grep refix` trên `TOOLS/server/*.tsv` không còn dòng. Nhãn không nằm trên bảng 2026 đã căn. |
| D-03 | Chưa đổi được tên tệp | Đọc bảng: cột 2 là id kỹ năng sống. Tên phải là `achievement_life_skill`. Hỏi L ở `HOI-DAP.md` H2 vì không được sửa `table_names.tsv`. Không ghi ngoại lệ. |
| D-09 | Đã kiểm phần A | 0 nhãn M1/M2 của shared còn `column_<n>`. |

## 5. Chưa kiểm

Chưa chạy `unittest discover` cả `TOOLS/server`. `test_table_refs.py` đỏ vì còn bắt `refs/shared.tsv` trống; hai test kia của tệp đó xanh. Chi tiết ở H3.

Chưa chạy `verify_p1.py`. So byte ô dữ liệu đã thấy 0 lệch trước khi chép tên mới vào `SERVER`.

Chưa chạy `lint_names.py` tới lúc thoát 0. Cổng báo 26 dòng mẫu `{n}` sai dạng, cộng `achievement_ability` và hai tên của B (`pvp_ruler`, `zhuan_dan_id`). Tên mẫu sau khi thay `{n}` bằng `1` không dính từ cấm.

## 6. Giả định

Cặp hiệu id là giao `public_config`/`reference` với `client_2026`/`table` cùng `source`. Đủ 106, không thừa.

`first_missing` nối bằng `;` không có dấu cách, cùng kiểu `absent` mẫu `-1;0`. Cột `int` xếp theo số rồi theo byte của chữ gốc. `*` của cha lấy `*` đầu của con. Ô rỗng không trỏ. `--names` chỉ để test, mặc định vẫn là `table_names.tsv`.

`心法ID` ở `XinFa_V1.txt`, `名称$1$` ở `SpecialObjData.txt` và `等级` ở `CommonItem.txt` bỏ `basis` `code:` vì đoạn mã đó đọc bảng khác. Cùng nhãn vẫn được tên qua dòng `scope` rỗng.

## 7. Lệch quy tắc

Không sửa `lint_names.py` dù N2 chưa hiểu `{n}`. Không đổi tên `achievement_ability` vì tệp tên bảng không thuộc vai này. Không sửa test đang bắt refs trống.

`--names` không có trong mục 5.3. Thêm để test không đụng 106 bảng thật. Lệnh không có cờ này vẫn đọc `table_names.tsv`.
