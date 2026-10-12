# Báo cáo vai B, P1 đợt 3

Làm trong `F:\tl 2026\THIENLONG`, không worktree, không commit. Cây lúc bắt đầu là sau nấc 2 của L.

## 1. Tệp đã tạo hoặc sửa

- `TOOLS/server/column_terms_server.tsv`: 969 dòng thuật ngữ cho bảng máy chủ.
- `TOOLS/server/refs/server.tsv`: 24 dòng tham chiếu.
- `TOOLS/server/legacy_rules.tsv`: tên khoá, nhóm, `convert=decimal`, `basis=name`, lý do `unknown`.
- `TOOLS/server/import_rules.py`: nhận `decimal` và `basis` `name`.
- `TOOLS/server/import_legacy.py`: cột `pvp_rules`; ô float bỏ khoảng trắng hai đầu.
- `TOOLS/server/test_import_rules.py`, `TOOLS/server/test_import_legacy.py`.
- `SERVER/config/rules/`: sáu toml luật sinh lại. Bảy tệp còn lại không sinh.
- `SERVER/tables/server/` và `TOOLS/server/columns/server/`: sinh lại bằng `import_legacy.py`. `scene_load_refs.tsv` của C giữ nguyên vì tool khác.

## 2. Đã kiểm

Test mới, trước khi có mã, `python -B -W error -m unittest` bốn ca:

```text
ERROR: test_decimal_keeps_source_digits
import_rules.RulesError: legacy_rules.tsv:4: convert lạ: decimal
FAIL: test_shape_and_fates
AssertionError: 'mốc P3' not found in 'chưa làm ở đợt 2'
FAIL: test_scene_pvp_column_uses_rules
AssertionError: 'pvp_rules' not found in [..., 'pvp_ruler', ...]
FAIL: test_float_strips_ends_only
AssertionError: ((' 0.50 ', '1.25'),) != (('0.50', '1.25'),)
Ran 4 tests, FAILED (failures=3, errors=1)
```

Sau khi sửa, cùng hai module, đã đặt `THIENLONG_LEGACY_ROOT`:

```text
Ran 33 tests in 3.252s
OK
```

`python -B -W error TOOLS/server/lint_py.py` trên `import_rules.py`, `import_legacy.py` và hai test: thoát 0.

`python -B -W error TOOLS/server/import_rules.py "<tlbb>" SERVER/config/rules` thoát 0: luật 142, tiến trình 26, bỏ 9, chưa rõ 401, lệch tiến trình 0. `lint_config.py` sáu tệp luật: `6 tệp sạch, 104 cài đặt đều có chú thích và thẳng cột`.

`import_legacy.py` cùng gốc, đích `SERVER/tables/server`: thoát 0. Băm phần bản ghi (bỏ dòng tên cột) trước và sau: chỉ `pet_ai_strategies.tsv` đổi, vẫn 5 dòng. Dòng tổng kết: `float bỏ khoảng trắng 25`.

`verify_p1.py B`: `B: 67 bảng đích, 41634 bản ghi; so 92 tệp chữ và 22 tệp ini; ô lệch 25`. Hai dòng mẫu là `PetAIStrategyTbl.txt` cột float `'0.50 '` thành `'0.50'` và `'0.80 '` thành `'0.80'`. Hai dòng khác không phải ô lệch mới: `flight_maps.tsv` không phải bảng chữ có dòng kiểu; `item_segment_values.tsv` 1 dòng ô thừa sau 65 cột kiểu. Khoá ini vắng vẫn 4546 ô trống.

`table_refs.read_refs` đọc cả ba tệp refs: 30 dòng, không lỗi hình dạng. 24 dòng là của `server.tsv`.

`lint_names.py` thoát 1. Không dòng nào trỏ tệp của B. Lỗi còn lại là `{n}` trong `column_terms.tsv` của A và `achievement_ability` trong `table_names.tsv`. Xem `HOI-DAP.md`.

## 3. Bảng nợ

| Mã | Trạng thái | Chứng |
|---|---|---|
| D-01 | Đã trả | `xinfa_max_level` thành `inner_art_max_level`; `min_level_ingot_ticket` thành `min_level_ingot_voucher`; `pk_refix` thành `pk_modifier`; nhóm `[ability]` thành `[life_skill]`; nhóm `[copy]` thành `[instance]`. `lint_config` sạch. |
| D-02 phần B | Đã trả | `scenes.tsv` cột `pvp_rules`. `gacha_machines.tsv` đã là `gacha_id` từ nấc 2 (M1). `gacha_item_pools.tsv` `ZhuanDan_ID` từ `zhuan_dan_id` thành `gacha_id` bằng thuật ngữ, vì N1 ghép `zhuan`+`dan`. |
| D-04 | Đã trả | `position_x`/`position_z` kiểu số thực, `convert=decimal`, giá trị `165.0` và `169.0`. `_permille` không còn trên toạ độ. Các khoá thiếu đơn vị ghi `Đơn vị chưa xác lập.` `default_move_speed_permille` vì `Obj_Human_Attributes.cpp:566` chia cho 1000. |
| D-05 | Đã trả | Mười một khoá `DefaultChar.ini` thành `rule`, `basis=name`. `luckword` giữ `unknown`: mã 2008 ghi cứng câu tâm trạng, không đọc khoá. |
| D-07 phần B | Đã trả | 25 ô float của `pet_ai_strategies.tsv` bỏ khoảng trắng cuối. `verify_p1.py B` đếm đúng 25. |
| D-09 phần B | Đã trả trên bảng máy chủ | Năm nhãn M2: `ID(掉落包编号)` thành `id` ở `drop_packages` và `did_1` ở `monster_drops`; `BoxValue(掉落包价值)` thành `box_value`; `Mvalue(怪物价值)` thành `mvalue`; `DID1(掉落包编号)` thành `did_1`. Không còn nhãn M1/M2 mang tên `column_<n>`. |

## 4. Khoá luật trước và sau

410 khoá `unknown` lý do `chưa làm ở đợt 2` đổi thành `chưa làm ở đợt 3`, trừ 11 khoá D-05 chuyển thành `rule`. Còn 399 khoá lý do đó, cộng 2 khoá `mốc P3` (`TimeSetting.SMUKickUserTime`, `CacheLogTime.LogInCacheTime`). Tổng `unknown` 401, `rule` 142. Bảy tệp `pet`, `hidden_weapon`, `pvp`, `guild`, `social`, `economy`, `fatigue` không sinh. Mười một toml tiến trình không sửa. Lệch giá trị tiến trình: 0.

`character.toml`:

- `can_get_exp_range` giữ tên. Chú thích thêm đơn vị chưa xác lập. Mã đọc `ReadInt` vào bán kính, không nêu đơn vị.
- `default_move_speed` thành `default_move_speed_permille`.
- `default_attack_speed` giữ tên. Chú thích gốc: chỉ nạp, không chỗ nào đọc. `GetBaseAttackSpeed` không dùng giá trị ini.
- `pilfer_lock_time` giữ tên. Chú thích gốc `(毫少)`. Mã 2008 không đọc khoá. Không đoán mili giây.
- `xinfa_max_level` thành `inner_art_max_level`.
- `min_level_ingot_ticket` thành `min_level_ingot_voucher`.

`combat.toml`: `pk_refix` thành `pk_modifier`. Giá trị 100, chú thích chỉ nói sát thương PK giảm một nửa, không nêu đơn vị.

`global.toml`: `interval` của `[rolling_notice]` giữ tên. Chú thích gốc `公告间隔时间`, giá trị 300000, không nêu mili giây.

`new_character.toml`:

- `pos_x_permille` / `pos_z_permille` thành `position_x` / `position_z`, ghi `165.0` và `169.0`.
- Thêm `[attribute]` `str` `spr` `con` `int` `dex`.
- Thêm `camp` trong `[profile]`.
- `[ability]` thành `[life_skill]`, các khoá `count`, `id`, `level`, `exp` giữ.
- Thêm `[inner_art]` `number`.
- `[start_position]` thêm `scene_count`, `scene0`, `scene1`, `scene2` cạnh hai mảng toạ độ.

`instances.toml`: `[copy]` thành `[instance]`. `group_count`, `id`, `max_scene_count` giữ.

`monster.toml` sinh lại, không đổi khoá.

## 5. Tên cột

Đầu việc, đo trên `columns/server`: 2172 cột, 883 có tên, 1289 chưa tên. Sau lần sinh lại: 1887 có tên, 285 chưa tên.

Luật trên tệp cột sau khi sinh: nguyên văn 1005, M1 751, M2 5, mẫu `{n}` 0. Thuật ngữ: direct 945, code 23, glossary 1.

Bảng có số tên đổi (trước, sau, tổng):

- `audit_item_filter` 1, 2, 2. `audit_monster_filter` 1, 2, 2.
- `camp_relations` 0, 17, 17. `drop_packages` 358, 516, 516. `monster_drops` 22, 23, 23.
- `effects` 1, 76, 76. `effect_atoms_legacy` 2, 46, 46. `effect_collections` 30, 34, 34.
- `item_quality_odds` 0, 101, 101. `item_attribute_value_ranges` 1, 201, 202.
- `item_segment_rates` 0, 61, 61. `item_segment_values` 1, 65, 65. `item_segment_distributions` 1, 11, 11.
- `item_segment_quality_rules` 0, 9, 191. `item_drop_rates` 0, 9, 9. `item_sale_limits` 0, 3, 3.
- `sect_attribute_growth` 0, 51, 51. `sect_damage_modifiers` 0, 13, 13.
- `sect_task_rewards_by_level` 0, 3, 3. `sect_task_round_multipliers` 0, 3, 3.
- `death_penalties` 11, 12, 12. Ba bảng phạt theo cấp, sát khí, trạng thái: 1, 16, 16.
- `pvp_rules` 1, 9, 9. `quiz_questions` 0, 15, 16. `skill_bullets` 1, 15, 15. `skill_objects` 0, 7, 7.
- `gacha_item_pools` 255, 259, 259. `guild_war_points` 1, 3, 3. `hair_style_costs` 2, 4, 4.
- `hidden_weapon_skill_learn_weights` 1, 7, 7. `hidden_weapon_skills_by_level` 0, 15, 16.
- `id_sets` 16, 18, 18. `life_skill_attribute_modifiers` 1, 5, 5. `mentor_exp_rewards` 0, 6, 6.
- `server_strings` 1, 2, 2. Ba bảng chênh cấp (`drop`, `exp`, `pet_exp`): 1, 2, 2.
- Trân thú: `pet_ai_strategies` 1, 7, 7; `pet_attribute_point_plans` 0, 6, 6; `pet_breeding_skill_inheritance` 0, 6, 6; `pet_death_happiness_loss` 0, 2, 2; `pet_mutant_quality_odds` 0, 2, 2; `pet_skill_comprehension_odds` 0, 6, 6; `pet_skill_index` 0, 2, 2; `pet_skill_learn_slots` 0, 6, 6; `pet_skill_odds` 0, 3, 96; `pet_taming_costs` 0, 2, 2.

Bảng không liệt kê giữ nguyên số tên lúc đầu.

Nhãn máy không đặt được, theo nhóm:

- Số trần `101`–`256` của `DropBoxContent.txt`: đã đặt `item_<số>_id` vì đứng ngay trước `Level` cùng số. Không phải M1.
- Số `0`–`15` của `CampAndStand.txt`: đã đặt `stand_with_camp_<số>`, mã `CampAndStand.cpp:38`.
- `Item Level`, `Delta LvlNpc -LvlPlayer`, `Camp\Camp`: có dấu cách, gạch hoặc gạch chéo ngược. Đã đặt bằng thuật ngữ.
- `odds` của `random_shop_goods` trùng `Odds` sau snake. Giữ dấu `?`, không bịa hậu tố.
- `_clientres` của `scenes`: tên gốc không hợp lệ. Giữ `column_9`.

Nhãn còn `?`, gộp:

- 182 cột `ItemSegQuality.txt`: các cột đã tách theo điểm lắp và cụm `三精`. Nhãn dài, không đủ căn cứ để một tên tiếng Anh.
- 93 tên kỹ năng trân thú trong `pet_skill_odds` (`冰精`, `高级借力`, …). Không có bảng đối chiếu trong mã 2008 đã đọc.
- 5 nhãn rỗng của `flight_maps`, 1 nhãn rỗng của `item_attribute_value_ranges`.
- `130级110级技能` trong `hidden_weapon_skills_by_level`: hai cấp trong một nhãn.
- Dòng chú giải cuối `quiz_questions` (`1=新，2=城，…`): nhãn là bảng mã, không phải tên cột.
- `odds` và `_clientres` như trên.

`effects` cột `logic_id` là id logic C++ (`m_nLogicID`), 70 giá trị. Không có bảng cha. `effect_atoms_legacy` là hệ hiệu ứng cũ, không phải bảng logic này. Không đưa vào `refs/`.

`drop_packages` cột `item_*_id`: mã 2008 (`ItemTable.cpp` `InitDropBoxTable`) tách serial bằng `TSerialHelper`, không tra một bảng vật phẩm. Đo `item_1_id`: thiếu 281 giá trị so với `items_common.index`, 288 so với `equipment.index_1`, còn 7 so với hợp của hai bảng. Không có một cột cha duy nhất, nên không có dòng refs.

`广播类型ID（Form DropNotify.txt）` đã đặt `broadcast_type_id`. Cột cha bên `tables/shared/drop_broadcasts.tsv` vẫn là `column_<n>`. Nhờ L ghép khi A đặt tên.

## 6. Tham chiếu `refs/server.tsv`

24 dòng. `known_missing` đo bằng script riêng, so nguyên văn ô, trước khi viết tệp.

- `monster_drops.id` sang `monsters.monster_id`: thiếu 30 giá trị, 30 dòng. Id `9621`–`9635` và `12300`–`12314` không có trong bảng quái 2026. Mã đọc cột 0 vào `m_MonsterId`, nên đây là id gốc thiếu chứ không ghép nhầm cột.
- `monster_drops.did_1` tới `did_20` sang `drop_packages.id`: thiếu 0. Giá trị `-1` là không trỏ (`ItemTable.cpp:1211` có nhánh bỏ `-1`). `0` có thật trong `drop_packages`, không đưa vào `absent`.
- `scene_hosting.scene_id` sang `scenes.scene_id`: thiếu 0, 923 dòng. Cùng chỉ số section `sceneN`.
- `pet_skill_index.skill_id` sang `skills.skill_id`: thiếu 0, 94/94. Mã đọc cột 1 vào `m_nSkillID`.
- `gacha_item_pools.gacha_id` sang `gacha_machines.gacha_id`: thiếu 1. Bảng con một dòng, giá trị `30504013`, không nằm trong 8 id máy (cùng dạng `30504…`). Mã 2008 không có bảng này. `basis` là `data`.

## 7. Chưa kiểm

- `diff_tables.py --check` đã chạy hơn 10 phút mà chưa in dòng nào (stdout còn trống). Số `known_missing` ở mục 6 là số script riêng đo trước đó, không phải output của `diff_tables.py`.
- Chưa chạy `verify_p1.py` phần A, C, D.
- Chưa chạy exe 2008.
- `logic_id` không đối chiếu với bản server mới hơn 2008.

## 8. Giả định

- `毫少` không đủ để gắn `_ms` khi mã không đọc khoá.
- Chia tốc độ đi cho 1000 là phần nghìn của hệ số tốc độ, nên hậu tố `_permille`.
- Tên riêng môn phái giữ Latin: `shaolin`, `emei`, `dali`, …
- `玄` trong bốn hệ là lightning.
- Dòng thuật ngữ viết nguyên văn thay cho mẫu `{n}` vì N2. Nghĩa không đổi.

## 9. Lệch quy tắc

- Không dùng mẫu `{n}` trong `column_terms_server.tsv` dù mục 5.1 cho phép. Lý do ở mục 8 và `HOI-DAP.md`.
- `test_import_legacy.py` bỏ kỳ vọng `column_29` trong dòng tổng kết `effects`, vì cột đó đã có tên `parameter_value_*`. Kỳ vọng mới kiểm `tên thật 76` và `parameter_value_1`.

## 10. Ngoài phạm vi

Không sửa `glossary.tsv`, `column_names.py`, `lint_names.py`, `table_refs.py`, test của các tệp đó, `table_names.tsv`, `moc/`, `refs/shared.tsv`, `refs/scenes.tsv`. Không đụng bảy tệp luật còn lại ngoài lý do `unknown`, không đụng toml tiến trình. `zhuandan_*.lua` trong `script_index.tsv` là đường dẫn gốc, không phải tên cột.
