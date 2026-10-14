# Độ phủ bảng config XJL7457 (bản 14 môn phái) so với server THIENLONG

Ngày: 2026-10-13. Chỉ đọc G:\XJL7457; không build, không chép tệp.

## Phương pháp
- Nguồn đối chiếu: `Server/rootfs/home/tlbb/Server/Config` và `Public/Config` (đệ quy, .txt/.ini), bỏ `Public/Data/Script` (Lua).
- Phía mình: mọi tệp trong `dev/server/tables`, `release/server/tables`, `SERVER`, `dev/server`; cảnh: tên thư mục `dev/server/scenes`.
- Khớp: (1) bảng đổi tên `TOOLS/server/table_names.tsv` (tree+source -> target) và target có thật trên đĩa; (2) fate=reference thì tra tên cùng ở tree client_2026; (3) trùng tên tệp (không phân biệt hoa thường, bỏ đuôi).
- process_config/rules: đã chuyển sang TOML/luật, không phải bảng; dropped: cố ý bỏ.
- Số dòng ước lượng: .txt = dòng không rỗng/không chú thích trừ 2 dòng tiêu đề; .ini = số mục [..]; .tsv mình = dòng trừ `#` và tiêu đề. Cờ khi mình < 70% bản gốc (gốc ≥ 10 dòng).

## Tổng
- Bảng gốc: 302. Khớp thành bảng: 229 (75.8%). Thêm cấu hình tiến trình/luật: 243 (80.5%). Cố ý bỏ: 3.
- Khớp chỉ bằng tên tệp nguyên văn: 5 (1.7%) — vì dữ liệu đã đổi tên sang snake_case tiếng Anh.
- Public/Data: 307 tệp .ai (AI quái) chưa có tương ứng; 2/2 .dat đã có.
- Cảnh (.scn): 244/382 (63.9%).
- Bảng addon private-server ngoài Config (XYD_DataBase, JiuFeng, XiaoXiang_...): 167, khớp 0.

## Thiếu theo hệ thống
### skills (26)
- `Server/Config/XYJ_MenPaiJinJie.ini` — dòng≈2; fate=chưa có trong table_names
- `Server/Config/XYJ_MenpaiMifaData.txt` — dòng≈14; fate=chưa có trong table_names
- `Public/Config/SkillTemplate_V1X.txt` — dòng≈1930; fate=chưa có trong table_names
- `Public/Config/WuHunSkillLevelUp.txt` — dòng≈252; fate=chưa có trong table_names
- `Public/Config/XYJ_ScriptSkillTable.txt` — dòng≈479; fate=chưa có trong table_names
- `Public/Config/AbilityLevelUp/assistant_menpai.txt` — dòng≈100; fate=reference
- `Public/Config/AbilityLevelUp/caikuang.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/cailiaojiagong.txt` — dòng≈1; fate=reference
- `Public/Config/AbilityLevelUp/caiyao.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/diaoyu.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/dingweifu.txt` — dòng≈3; fate=reference
- `Public/Config/AbilityLevelUp/fengren.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/gaojishenghuo.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/gongyi.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/menpai.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/menpaifuzhu.txt` — dòng≈100; fate=reference
- `Public/Config/AbilityLevelUp/menpaishenghuo.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/pengren.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/putongshenghuo.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/shenghuofuzhu.txt` — dòng≈100; fate=reference
- `Public/Config/AbilityLevelUp/xiangqian.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/yangsheng.txt` — dòng≈100; fate=reference
- `Public/Config/AbilityLevelUp/yaoli.txt` — dòng≈100; fate=reference
- `Public/Config/AbilityLevelUp/zhiyao.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/zhongzhi.txt` — dòng≈10; fate=reference
- `Public/Config/AbilityLevelUp/zhuzao.txt` — dòng≈10; fate=reference
### items (10)
- `Server/Config/ItemSerial.ini` — dòng≈1; fate=dropped
- `Server/Config/PetConfigTable.ini` — dòng≈1; fate=rules
- `Server/Config/XYJ_StallInfo.txt` — dòng≈3; fate=chưa có trong table_names
- `Public/Config/EquipEnance.txt` — dòng≈99; fate=chưa có trong table_names
- `Public/Config/PetEquipUpProductInfo.txt` — dòng≈680; fate=chưa có trong table_names
- `Public/Config/XYJ_GemGrade.txt` — dòng≈964; fate=chưa có trong table_names
- `Public/Config/XYJ_ShopTable.txt` — dòng≈1618; fate=chưa có trong table_names
- `Public/Config/XYJ_ShopTableBak.txt` — dòng≈1524; fate=chưa có trong table_names
- `Public/Config/RandShop/mystery_shop.ini` — dòng≈21; fate=chưa có trong table_names
- `Public/Config/RandShop/Xiao_Huang_ZiRandomShop.ini` — dòng≈0; fate=chưa có trong table_names
### quests (0)
### scenes (2)
- `Server/Config/CopyScene.ini` — dòng≈3; fate=rules
- `Server/Config/IPRegionTable.txt` — dòng≈0; fate=dropped
### npc_monster (11)
- `Server/Config/Paiming/axchongzi.txt` — dòng≈27; fate=chưa có trong table_names
- `Server/Config/Paiming/bxchongzi.txt` — dòng≈27; fate=chưa có trong table_names
- `Server/Config/Paiming/chongzhi.txt` — dòng≈0; fate=chưa có trong table_names
- `Server/Config/Paiming/chongzi.txt` — dòng≈0; fate=chưa có trong table_names
- `Server/Config/Paiming/cxchongzi.txt` — dòng≈27; fate=chưa có trong table_names
- `Server/Config/Paiming/dengji.txt` — dòng≈0; fate=chưa có trong table_names
- `Server/Config/Paiming/laba.txt` — dòng≈0; fate=chưa có trong table_names
- `Server/Config/Paiming/mingdong.txt` — dòng≈0; fate=chưa có trong table_names
- `Server/Config/Paiming/sharen.txt` — dòng≈0; fate=chưa có trong table_names
- `Server/Config/Paiming/shouhua.txt` — dòng≈0; fate=chưa có trong table_names
- `Server/Config/Paiming/songhua.txt` — dòng≈0; fate=chưa có trong table_names
### other (24)
- `Server/Config/Account.txt` — dòng≈0; fate=dropped
- `Server/Config/ActionWeaponTable.txt` — dòng≈384; fate=chưa có trong table_names
- `Server/Config/AllowableScriptFuncEx.txt` — dòng≈569; fate=chưa có trong table_names
- `Server/Config/ConfigInfo.ini` — dòng≈42; fate=process_config
- `Server/Config/DarkConfigTable.ini` — dòng≈1; fate=rules
- `Server/Config/DefaultChar.ini` — dòng≈9; fate=rules
- `Server/Config/Filt.txt` — dòng≈6; fate=chưa có trong table_names
- `Server/Config/FiltV2.txt` — dòng≈341; fate=chưa có trong table_names
- `Server/Config/GMList.ini` — dòng≈1; fate=process_config
- `Server/Config/IPRange.ini` — dòng≈2; fate=process_config
- `Server/Config/LoginInfo.ini` — dòng≈1; fate=process_config
- `Server/Config/MachineInfo.ini` — dòng≈2; fate=process_config
- `Server/Config/MergeConfig.txt` — dòng≈7; fate=rules
- `Server/Config/proxyIP.txt` — dòng≈4; fate=process_config
- `Server/Config/ServerInfo.ini` — dòng≈7; fate=process_config
- `Server/Config/ShareMemInfo.ini` — dòng≈2; fate=process_config
- `Server/Config/WorldInfo.ini` — dòng≈1; fate=process_config
- `Server/Config/XYJ_BaseConfig.ini` — dòng≈4; fate=chưa có trong table_names
- `Public/Config/ActionWeaponTable.txt` — dòng≈384; fate=chưa có trong table_names
- `Public/Config/SuperWeaponUpgrade.txt` — dòng≈438; fate=chưa có trong table_names
- `Public/Config/UnderArmourLevel1.txt` — dòng≈163; fate=chưa có trong table_names
- `Public/Config/XiuLianDetial.txt` — dòng≈150; fate=chưa có trong table_names
- `Public/Config/XYJ_AgnameData.txt` — dòng≈857; fate=chưa có trong table_names
- `Public/Config/XYJ_TaoHuaDaoVisual.txt` — dòng≈25; fate=chưa có trong table_names

## Lệch số dòng lớn
|Tệp|Gốc|Mình|Đích|
|-|-|-|-|
|AttrLevelUpTable.txt|256|151|dev/server/tables/server/sect_attribute_growth.tsv|
|BaseValueTable.ini|21|10|dev/server/tables/server/sect_base_values.tsv|
|OnSaleLimit.txt|253|1|dev/server/tables/server/item_sale_limits.tsv|
|PetDieLoss.txt|255|155|dev/server/tables/server/pet_death_happiness_loss.tsv|
|PetDomesticationMoney.txt|255|155|dev/server/tables/server/pet_taming_costs.tsv|
|PetLevelUpTable.txt|255|155|dev/server/tables/shared/pet_exp_levels.tsv|
|SystemInfo.ini|41|10|dev/server/tables/server/rolling_announcements.tsv|
|CampaignTable.txt|268|106|dev/server/tables/shared/campaigns.tsv|
|CharTitle.txt|996|430|dev/server/tables/shared/titles.tsv|
|DarkExpLevel.txt|255|150|dev/server/tables/shared/hidden_weapon_exp_levels.tsv|
|EquipVisual.txt|37|10|dev/server/tables/shared/equipment_visual_groups.tsv|
|GemInfo.txt|2691|1195|dev/server/tables/shared/gems.tsv|
|LvMaxMoney.txt|255|150|dev/server/tables/shared/money_caps_by_level.tsv|
|PetHuanTongCost.txt|255|155|dev/server/tables/shared/pet_rejuvenation_costs.tsv|
|PetLevelUpTable.txt|255|155|dev/server/tables/shared/pet_exp_levels.tsv|
|PlayerExpLevel.txt|255|150|dev/server/tables/shared/player_exp_levels.tsv|

## Cảnh thiếu
- BattleField.scn
- CampPVP2023.scn
- HJ_xianshoutan.scn
- PhoenixMaze.scn
- Scene449.scn
- Scene450.scn
- Scene451.scn
- Scene452.scn
- SongliaoWar.scn
- Songliao_War.scn
- Songliao_Xiuxi.scn
- Tianjielou_1.scn
- Tianjielou_2.scn
- Tianjielou_3.scn
- Tianjielou_4.scn
- Tianjielou_5.scn
- Tianjielou_6.scn
- Tianjielou_7.scn
- Xbw_HX.scn
- Xbw_HXJ_XiuXi.scn
- Xbw_LTJ.scn
- Xbw_LTJ_XiuXi.scn
- Xbw_YYJ.scn
- Xbw_YYJ_XiuXi.scn
- ZBS_GameArea.scn
- ZhengBaSai.scn
- banghuihoushan.scn
- bianjing.scn
- buguilin.scn
- cangjingge.scn
- cangjingge_80JQTZ.scn
- cangwumijing.scn
- chaojingcheng.scn
- chengshiwangling.scn
- congren.scn
- congrenfb.scn
- congrensg.scn
- congrentx.scn
- dafo.scn
- dakuiyihai.scn
- daliKV.scn
- fenghuang_war.scn
- fengmingzhen.scn
- guhuolinggu.scn
- guigu.scn
- guigu_2.scn
- guigufb.scn
- guigujj.scn
- guigusg.scn
- guishi.scn
- gusu.scn
- gusu_1.scn
- gusu_2.scn
- gusufb.scn
- hanbinghaiyu.scn
- huangshanzhidian.scn
- jinling.scn
- juntiancheng.scn
- kunlunfudi.scn
- kunlunshan.scn
- langhuanfudi.scn
- lingyuanqijing.scn
- linhaixigu.scn
- luofucheng.scn
- luoyangKV.scn
- luoyang_Pata.scn
- mieshihuoku.scn
- monanqingyuan.scn
- qianqiudian.scn
- qinhuanggong_4.scn
- qinhuanggong_5.scn
- qinshuidanlin.scn
- quanzhou.scn
- quanzhoushandong.scn
- samaerhan.scn
- sancaixiagu.scn
- sanshenhuanjing.scn
- shenghuogong.scn
- shengxiao.scn
- shenlongdao.scn
- shuipoliangshan.scn
- shuipoliangshanW_w01.scn
- shuipoliangshan_01.scn
- shuipoliangshan_02s.scn
- shuipoliangshan_03.scn
- shuipoliangshan_04s.scn
- shuiyuedongtian.scn
- sijuezhuang.scn
- sulingyuan.scn
- suzhouKV.scn
- tangmen.scn
- tangmenfb.scn
- tangmenjj.scn
- tangmensg.scn
- tangmensg1.scn
- taohuadao.scn
- taohuadao_1.scn
- taohuadao_2.scn
- taohuadaofb.scn
- taoyuanzhijin.scn
- taoyuanzhijing.scn
- tianbofu.scn
- tianhuangshan.scn
- tianlonghuanjing.scn
- tianqinanhuai.scn
- tongquetai.scn
- tongtianta1.scn
- tongtianta2.scn
- tongtianta3.scn
- tongtianta4.scn
- tongtianta5.scn
- wangchuanhuahai.scn
- weichengcaoyuan.scn
- weichengcaoyuan_01.scn
- weichengcaoyuan_02s.scn
- wufangjing_1.scn
- wufangjing_2.scn
- wufangjing_3.scn
- wufangjing_4.scn
- wufangjing_5.scn
- wuyahai.scn
- wuzhuzhidi.scn
- xianshoutan.scn
- xingjudao.scn
- xinsanhuan.scn
- xuanhai.scn
- xuezhanymg.scn
- yanluotian.scn
- yayuland.scn
- yihuakaitian.scn
- yunfu.scn
- yunyaoqueling.scn
- zhengding8.scn
- zhoutian.scn
- zhuangyuan_5.scn
- zhulin_01.scn
- zhulin_02s.scn
- zhulinax.scn

## Addon (theo thư mục)
- JiuFeng: 51
- JiYuanMiBao: 7
- PlayerLog: 1
- Q546528533: 7
- RuMeng: 4
- ServerBD: 4
- UK: 2
- XiaoXiang_: 21
- XYD_DataBase: 70

## Danh sách đầy đủ
|Nhóm|Tệp|Cách khớp|Đích|Gốc|Mình|
|-|-|-|-|-|-|
|Server/Config|Account.txt|dropped||0|-1|
|Server/Config|ActionWeaponTable.txt|THIẾU||384|-1|
|Server/Config|AllowableScriptFuncEx.txt|THIẾU||569|-1|
|Server/Config|AttrLevelUpTable.txt|map|dev/server/tables/server/sect_attribute_growth.tsv|256|151|
|Server/Config|AttrRefixTable.txt|map|dev/server/tables/server/life_skill_attribute_modifiers.tsv|6|6|
|Server/Config|BaseValueTable.ini|map|dev/server/tables/server/sect_base_values.tsv|21|10|
|Server/Config|boxdroplist.txt|map|dev/server/tables/server/loot_box_entries.tsv|576|1512|
|Server/Config|boxdroplist_baibaoshuxia.txt|map|dev/server/tables/server/loot_box_entries.tsv|64|1512|
|Server/Config|boxdroplist_jubao.txt|map|dev/server/tables/server/loot_box_entries.tsv|12|1512|
|Server/Config|boxdroplist_zhuandan1.txt|map|dev/server/tables/server/loot_box_entries.tsv|10|1512|
|Server/Config|boxdroplist_zhuandan16.txt|map|dev/server/tables/server/loot_box_entries.tsv|24|1512|
|Server/Config|boxdroplist_zhuandan17.txt|map|dev/server/tables/server/loot_box_entries.tsv|14|1512|
|Server/Config|boxdroplist_zhuandan18.txt|map|dev/server/tables/server/loot_box_entries.tsv|49|1512|
|Server/Config|boxdroplist_zhuandan19.txt|map|dev/server/tables/server/loot_box_entries.tsv|77|1512|
|Server/Config|boxdroplist_zhuandan2.txt|map|dev/server/tables/server/loot_box_entries.tsv|24|1512|
|Server/Config|boxdroplist_zhuandan20.txt|map|dev/server/tables/server/loot_box_entries.tsv|15|1512|
|Server/Config|boxdroplist_zhuandan21.txt|map|dev/server/tables/server/loot_box_entries.tsv|12|1512|
|Server/Config|boxdroplist_zhuandan22.txt|map|dev/server/tables/server/loot_box_entries.tsv|51|1512|
|Server/Config|boxdroplist_zhuandan23.txt|map|dev/server/tables/server/loot_box_entries.tsv|97|1512|
|Server/Config|boxdroplist_zhuandan24.txt|map|dev/server/tables/server/loot_box_entries.tsv|48|1512|
|Server/Config|boxdroplist_zhuandan26.txt|map|dev/server/tables/server/loot_box_entries.tsv|30|1512|
|Server/Config|boxdroplist_zhuandan27.txt|map|dev/server/tables/server/loot_box_entries.tsv|36|1512|
|Server/Config|boxdroplist_zhuandan28.txt|map|dev/server/tables/server/loot_box_entries.tsv|26|1512|
|Server/Config|boxdroplist_zhuandan29.txt|map|dev/server/tables/server/loot_box_entries.tsv|25|1512|
|Server/Config|boxdroplist_zhuandan3.txt|map|dev/server/tables/server/loot_box_entries.tsv|24|1512|
|Server/Config|boxdroplist_zhuandan30.txt|map|dev/server/tables/server/loot_box_entries.tsv|8|1512|
|Server/Config|boxdroplist_zhuandan31.txt|map|dev/server/tables/server/loot_box_entries.tsv|8|1512|
|Server/Config|boxdroplist_zhuandan32.txt|map|dev/server/tables/server/loot_box_entries.tsv|25|1512|
|Server/Config|boxdroplist_zhuandan33.txt|map|dev/server/tables/server/loot_box_entries.tsv|45|1512|
|Server/Config|boxdroplist_zhuandan4.txt|map|dev/server/tables/server/loot_box_entries.tsv|5|1512|
|Server/Config|boxdroplist_zhuandan5.txt|map|dev/server/tables/server/loot_box_entries.tsv|12|1512|
|Server/Config|boxdroplist_zhuandan6.txt|map|dev/server/tables/server/loot_box_entries.tsv|33|1512|
|Server/Config|boxdroplist_zhuandanem.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandangb.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandanmj.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandansl.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandantl.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandants.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandanwd.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandanxx.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|boxdroplist_zhuandanxy.txt|map|dev/server/tables/server/loot_box_entries.tsv|18|1512|
|Server/Config|ConfigInfo.ini|process_config||42|-1|
|Server/Config|CopyScene.ini|rules||3|-1|
|Server/Config|CreateQualityOfVaryPetTbl.txt|map|dev/server/tables/server/pet_mutant_quality_odds.tsv|8|8|
|Server/Config|CreateSkillOfVaryPetTbl.txt|map|dev/server/tables/server/pet_breeding_skill_inheritance.tsv|12|12|
|Server/Config|DarkConfigTable.ini|rules||1|-1|
|Server/Config|DarkSkillList.txt|map|dev/server/tables/server/hidden_weapon_skills_by_level.tsv|31|31|
|Server/Config|DarkSkillStudy.txt|map|dev/server/tables/server/hidden_weapon_skill_learn_weights.tsv|11|11|
|Server/Config|DefaultChar.ini|rules||9|-1|
|Server/Config|DiePenalty.txt|map|dev/server/tables/server/death_penalties.tsv|105|105|
|Server/Config|DropAttenuation.txt|map|dev/server/tables/server/drop_level_gap_factors.tsv|401|401|
|Server/Config|DropBoxContent.txt|map|dev/server/tables/server/drop_packages.tsv|320|2034|
|Server/Config|DropRateOfItemTable.txt|map|dev/server/tables/server/item_drop_rates.tsv|233|233|
|Server/Config|ExpAttenuation.txt|map|dev/server/tables/server/exp_level_gap_factors.tsv|401|401|
|Server/Config|Filt.txt|THIẾU||6|-1|
|Server/Config|FiltV2.txt|THIẾU||341|-1|
|Server/Config|GeneralSets.txt|map|dev/server/tables/server/id_sets.tsv|1|1|
|Server/Config|GMList.ini|process_config||1|-1|
|Server/Config|GuildMemberAccess.ini|map|dev/server/tables/server/guild_position_permissions.tsv|6|5|
|Server/Config|GuildWarPoint.txt|map|dev/server/tables/server/guild_war_points.tsv|7|7|
|Server/Config|InterfaceEx.txt|name|dev/server/tables/client/interfaceex.tsv|583|1978|
|Server/Config|IPRange.ini|process_config||2|-1|
|Server/Config|IPRegionTable.txt|dropped||0|-1|
|Server/Config|ItemAuditFilter.txt|map|dev/server/tables/server/audit_item_filter.tsv|11506|11506|
|Server/Config|ItemQuality.txt|map|dev/server/tables/server/item_quality_odds.tsv|50|50|
|Server/Config|ItemSegAffect.txt|map|dev/server/tables/server/item_segment_distributions.tsv|496|480|
|Server/Config|ItemSegQuality.txt|map|dev/server/tables/server/item_segment_quality_rules.tsv|20|20|
|Server/Config|ItemSegRate.txt|map|dev/server/tables/server/item_segment_rates.tsv|10|10|
|Server/Config|ItemSegValue.txt|map|dev/server/tables/server/item_segment_values.tsv|656|468|
|Server/Config|ItemSerial.ini|dropped||1|-1|
|Server/Config|ItemValue.txt|map|dev/server/tables/server/item_attribute_value_ranges.tsv|60|60|
|Server/Config|LoginInfo.ini|process_config||1|-1|
|Server/Config|MachineInfo.ini|process_config||2|-1|
|Server/Config|MasterExpBounty.txt|map|dev/server/tables/server/mentor_exp_rewards.tsv|6|6|
|Server/Config|MenPaiAttackRefix.txt|map|dev/server/tables/server/sect_damage_modifiers.tsv|9|9|
|Server/Config|MergeConfig.txt|rules||7|-1|
|Server/Config|MonsterDropBoxs.txt|map|dev/server/tables/server/monster_drops.tsv|462|3984|
|Server/Config|NotifyDate.txt|map|dev/server/tables/server/notices_by_date.tsv|40|40|
|Server/Config|NotifyOnline.txt|map|dev/server/tables/server/notices_on_login.tsv|0|12|
|Server/Config|NotifyWeek.txt|map|dev/server/tables/server/notices_by_weekday.tsv|7|7|
|Server/Config|NpcAuditFilter.txt|map|dev/server/tables/server/audit_monster_filter.tsv|557|557|
|Server/Config|NPCChat.txt|map|dev/server/tables/server/npc_chat_lines.tsv|12|12|
|Server/Config|NPCPaoPaoIndexTable.txt|map|dev/server/tables/server/npc_speech_bubbles.tsv|65|65|
|Server/Config|OnSaleLimit.txt|map|dev/server/tables/server/item_sale_limits.tsv|253|1|
|Server/Config|PetAIStrategyTbl.txt|map|dev/server/tables/server/pet_ai_strategies.tsv|5|5|
|Server/Config|PetApperceiveSkillTable.txt|map|dev/server/tables/server/pet_skill_comprehension_odds.tsv|57|57|
|Server/Config|PetAttrPointDistribute.txt|map|dev/server/tables/server/pet_attribute_point_plans.tsv|172|172|
|Server/Config|PetConfigTable.ini|rules||1|-1|
|Server/Config|PetDieLoss.txt|map|dev/server/tables/server/pet_death_happiness_loss.tsv|255|155|
|Server/Config|PetDomesticationMoney.txt|map|dev/server/tables/server/pet_taming_costs.tsv|255|155|
|Server/Config|PetExpAttenuation.txt|map|dev/server/tables/server/pet_exp_level_gap_factors.tsv|401|401|
|Server/Config|PetLevelUpTable.txt|map-ref|dev/server/tables/shared/pet_exp_levels.tsv|255|155|
|Server/Config|PetSkillDistribute.txt|map|dev/server/tables/server/pet_skill_odds.tsv|1448|1448|
|Server/Config|PetSkillIndexTable.txt|map|dev/server/tables/server/pet_skill_index.tsv|94|94|
|Server/Config|PetStudySkllTable.txt|map|dev/server/tables/server/pet_skill_learn_slots.tsv|21|21|
|Server/Config|proxyIP.txt|process_config||4|-1|
|Server/Config|PunishByLevel.txt|map|dev/server/tables/server/death_penalty_by_level.tsv|16|16|
|Server/Config|PunishByPkValue.txt|map|dev/server/tables/server/death_penalty_by_pk_value.tsv|7|7|
|Server/Config|PunishByState.txt|map|dev/server/tables/server/death_penalty_by_state.tsv|5|5|
|Server/Config|PvpRuler.txt|map|dev/server/tables/server/pvp_rules.tsv|10|10|
|Server/Config|Questions.txt|map|dev/server/tables/server/quiz_questions.tsv|3703|3703|
|Server/Config|SceneInfo.ini|map|dev/server/tables/server/scene_hosting.tsv|725|923|
|Server/Config|ServerInfo.ini|process_config||7|-1|
|Server/Config|ShareMemInfo.ini|process_config||2|-1|
|Server/Config|ShimenLevelMoneyBonusTable.txt|map|dev/server/tables/server/sect_task_rewards_by_level.tsv|141|141|
|Server/Config|ShimenRoundMultipleTable.txt|map|dev/server/tables/server/sect_task_round_multipliers.tsv|20|20|
|Server/Config|StandardImpact.txt|map|dev/server/tables/server/effects.tsv|14041|9860|
|Server/Config|StringTable.txt|map|dev/server/tables/server/server_strings.tsv|352|312|
|Server/Config|SystemInfo.ini|map|dev/server/tables/server/rolling_announcements.tsv|41|10|
|Server/Config|UnderArmourLevel.txt|map|dev/server/tables/shared/under_armour_levels.tsv|163|165|
|Server/Config|WorldInfo.ini|process_config||1|-1|
|Server/Config|XYJ_BaseConfig.ini|THIẾU||4|-1|
|Server/Config|XYJ_MenPaiJinJie.ini|THIẾU||2|-1|
|Server/Config|XYJ_MenpaiMifaData.txt|THIẾU||14|-1|
|Server/Config|XYJ_StallInfo.txt|THIẾU||3|-1|
|Server/Config|ZhuandanBase.txt|map|dev/server/tables/server/gacha_machines.tsv|9|8|
|Server/Config|ZhuandanConfig.txt|map|dev/server/tables/server/gacha_item_pools.tsv|1|1|
|Server/Config|ZhuandanOutput.txt|map|dev/server/tables/server/gacha_outputs.tsv|390|350|
|Server/Config|Paiming/axchongzi.txt|THIẾU||27|-1|
|Server/Config|Paiming/bxchongzi.txt|THIẾU||27|-1|
|Server/Config|Paiming/chongzhi.txt|THIẾU||0|-1|
|Server/Config|Paiming/chongzi.txt|THIẾU||0|-1|
|Server/Config|Paiming/cxchongzi.txt|THIẾU||27|-1|
|Server/Config|Paiming/dengji.txt|THIẾU||0|-1|
|Server/Config|Paiming/laba.txt|THIẾU||0|-1|
|Server/Config|Paiming/mingdong.txt|THIẾU||0|-1|
|Server/Config|Paiming/sharen.txt|THIẾU||0|-1|
|Server/Config|Paiming/shouhua.txt|THIẾU||0|-1|
|Server/Config|Paiming/songhua.txt|THIẾU||0|-1|
|Public/Config|Ability.txt|map-ref|dev/server/tables/shared/life_skills.tsv|61|66|
|Public/Config|AbilityExpTable.txt|map-ref|dev/server/tables/shared/life_skill_proficiency.tsv|20|20|
|Public/Config|ActionWeaponTable.txt|THIẾU||384|-1|
|Public/Config|ActivityNotice.txt|map-ref|dev/server/tables/shared/activity_notices.tsv|44|226|
|Public/Config|ActivityRuler.txt|map-ref|dev/server/tables/shared/activity_rules.tsv|23|107|
|Public/Config|AppearanceAchivement.txt|map|dev/server/tables/shared/appearance_achievement.tsv|1094|4980|
|Public/Config|Appearanceshop.txt|map|dev/server/tables/shared/appearance_shop.tsv|56|96|
|Public/Config|AttackTraits.txt|map-ref|dev/server/tables/shared/attack_traits.tsv|19|20|
|Public/Config|BlueEquipBase.txt|map|dev/server/tables/shared/equipment_blue.tsv|248|248|
|Public/Config|Bullet.txt|map-ref|dev/server/tables/shared/bullets.tsv|199|337|
|Public/Config|BusInfo.txt|map-ref|dev/server/tables/shared/bus_types.tsv|18|38|
|Public/Config|CampaignTable.txt|map-ref|dev/server/tables/shared/campaigns.tsv|268|106|
|Public/Config|CampAndStand.txt|map|dev/server/tables/server/camp_relations.tsv|16|16|
|Public/Config|CharFaceGeo.txt|map-ref|dev/server/tables/shared/face_models.tsv|256|448|
|Public/Config|CharHairGeo.txt|map-ref|dev/server/tables/shared/hair_models.tsv|244|612|
|Public/Config|CharHead.txt|map-ref|dev/server/tables/shared/portraits.tsv|142|150|
|Public/Config|CharMount.txt|map-ref|dev/server/tables/shared/mounts.tsv|42|353|
|Public/Config|CharTitle.txt|map-ref|dev/server/tables/shared/titles.tsv|996|430|
|Public/Config|ChatConfig.txt|map-ref|dev/server/tables/shared/chat_channels.tsv|13|25|
|Public/Config|ChatMood.txt|map|dev/server/tables/shared/chat_moods.tsv|106|402|
|Public/Config|CityBuilding.txt|map-ref|dev/server/tables/shared/city_buildings.tsv|3240|4104|
|Public/Config|CityIdOfChina.txt|map-ref|dev/server/tables/shared/real_cities_cn.tsv|340|340|
|Public/Config|CityInfo.txt|map-ref|dev/server/tables/shared/guild_cities.tsv|216|216|
|Public/Config|CommerceRelation.txt|map-ref|dev/server/tables/shared/trade_zone_relations.tsv|22|22|
|Public/Config|CommonItem.txt|map-ref|dev/server/tables/shared/items_common.tsv|17461|20501|
|Public/Config|Condition.txt|map-ref|dev/server/tables/shared/guild_research_conditions.tsv|79|88|
|Public/Config|DarkExpLevel.txt|map-ref|dev/server/tables/shared/hidden_weapon_exp_levels.tsv|255|150|
|Public/Config|DoubleGemCompound.txt|map|dev/server/tables/shared/double_gem_compound.tsv|280|280|
|Public/Config|DropNotify.txt|map-ref|dev/server/tables/shared/drop_broadcasts.tsv|142|205|
|Public/Config|EquipBase.txt|map-ref|dev/server/tables/shared/equipment.tsv|15937|24577|
|Public/Config|EquipEnance.txt|THIẾU||99|-1|
|Public/Config|EquipExtraAttr.txt|map-ref|dev/server/tables/shared/equipment_extra_attributes.tsv|1613|25819|
|Public/Config|EquipLevelUp.txt|map-ref|dev/server/tables/shared/equipment_level_up_odds.tsv|7|7|
|Public/Config|EquipSetAttr.txt|map-ref|dev/server/tables/shared/equipment_sets.tsv|234|259|
|Public/Config|EquipVisual.txt|map-ref|dev/server/tables/shared/equipment_visual_groups.tsv|37|10|
|Public/Config|Exterior_Ride.txt|map|dev/server/tables/shared/exterior_rides.tsv|260|297|
|Public/Config|Exterior_Weapon.txt|map|dev/server/tables/shared/exterior_weapons.tsv|613|966|
|Public/Config|Exterior_WeaponGroup.txt|map|dev/server/tables/shared/exterior_weapon_group.tsv|111|197|
|Public/Config|FiveElementsValue.txt|map|dev/server/tables/shared/five_elements_values.tsv|100|100|
|Public/Config|GemCarve.txt|map-ref|dev/server/tables/shared/gem_carving.tsv|128|128|
|Public/Config|GemInfo.txt|map-ref|dev/server/tables/shared/gems.tsv|2691|1195|
|Public/Config|GemMelting.txt|map-ref|dev/server/tables/shared/gem_melting.tsv|64|64|
|Public/Config|GreenEquipBase.txt|map|dev/server/tables/shared/equipment_green.tsv|8197|8197|
|Public/Config|GrowPoint.txt|map-ref|dev/server/tables/shared/grow_point_types.tsv|401|424|
|Public/Config|HairStyle.txt|map|dev/server/tables/server/hair_style_costs.tsv|2|2|
|Public/Config|HXYBase.txt|map|dev/server/tables/shared/hero_seal_base.tsv|32|32|
|Public/Config|HXYEffect.txt|map|dev/server/tables/shared/hero_seal_effects.tsv|147|147|
|Public/Config|HXYLevel.txt|map|dev/server/tables/shared/hero_seal_levels.tsv|100|100|
|Public/Config|IDCollections.txt|map-ref|dev/server/tables/shared/id_collections.tsv|365|523|
|Public/Config|Impact.txt|map|dev/server/tables/server/effect_atoms_legacy.tsv|17|17|
|Public/Config|ImpactCollections.txt|map|dev/server/tables/server/effect_collections.tsv|11|11|
|Public/Config|ImpactDirectly.txt|map-ref|dev/server/tables/shared/effect_instant_visuals.tsv|385|523|
|Public/Config|ImpactSEData_V1.txt|map-ref|dev/server/tables/shared/effect_visuals.tsv|997|9419|
|Public/Config|ItemAptRate.txt|map-ref|dev/server/tables/shared/item_aptitude_rates.tsv|255|255|
|Public/Config|ItemCompound.txt|map-ref|dev/server/tables/shared/recipes.tsv|1374|1482|
|Public/Config|ItemEnhance.txt|map-ref|dev/server/tables/shared/equipment_enhance.tsv|2098|2277|
|Public/Config|ItemRule.txt|map-ref|dev/server/tables/shared/item_rules.tsv|82|94|
|Public/Config|ItemSegValue.txt|map-ref|dev/server/tables/shared/item_segment_values.tsv|659|615|
|Public/Config|ItemVisualLocator.txt|name|dev/server/tables/client/itemvisuallocator.tsv|1752|2936|
|Public/Config|LevelRefix_Hit.txt|map-ref|dev/server/tables/shared/hit_level_modifiers.tsv|201|201|
|Public/Config|LogicSceneAttr.txt|map-ref|dev/server/tables/shared/scene_trade_zones.tsv|219|219|
|Public/Config|LvMaxMoney.txt|map-ref|dev/server/tables/shared/money_caps_by_level.tsv|255|150|
|Public/Config|MartialAttr.txt|map|dev/server/tables/shared/martial_attributes.tsv|8|9|
|Public/Config|MartialLevel.txt|map|dev/server/tables/shared/martial_levels.tsv|151|151|
|Public/Config|MasterExpAssign.txt|map-ref|dev/server/tables/shared/mentor_exp_share.tsv|150|150|
|Public/Config|MissionItem_GroupHashTable.txt|map-ref|dev/server/tables/shared/quest_item_groups.tsv|701|701|
|Public/Config|MissionItem_HashTable.txt|map-ref|dev/server/tables/shared/quest_item_pool.tsv|2292|2302|
|Public/Config|MissionNPC_HashTable.txt|map-ref|dev/server/tables/shared/quest_npc_pool.tsv|767|765|
|Public/Config|MissionPet_HashTable.txt|map-ref|dev/server/tables/shared/quest_pet_pool.tsv|262|262|
|Public/Config|Mission_Delivery.txt|map-ref|dev/server/tables/shared/quests_delivery.tsv|718|672|
|Public/Config|Mission_EnterArea.txt|map-ref|dev/server/tables/shared/quests_enter_area.tsv|55|55|
|Public/Config|Mission_Husong.txt|map-ref|dev/server/tables/shared/quests_escort.tsv|6|6|
|Public/Config|Mission_KillMonster.txt|map-ref|dev/server/tables/shared/quests_kill.tsv|180|152|
|Public/Config|Mission_LootItem.txt|map-ref|dev/server/tables/shared/quests_loot.tsv|254|257|
|Public/Config|Mission_NpcDefault.txt|map-ref|dev/server/tables/shared/npc_default_dialogue.tsv|16|16|
|Public/Config|MonsterAITable.ini|map|dev/server/tables/server/monster_ai_types.tsv|34|31|
|Public/Config|MonsterAttrExTable.txt|map-ref|dev/server/tables/shared/monsters.tsv|21439|28969|
|Public/Config|MonsterRespawnPos.txt|map-ref|dev/server/tables/shared/monster_respawn_points.tsv|267|267|
|Public/Config|PetAttrTable.txt|map-ref|dev/server/tables/shared/pets.tsv|7474|8589|
|Public/Config|PetEquipBase.txt|map|dev/server/tables/shared/pet_equipment_base.tsv|815|875|
|Public/Config|PetEquipUpProductInfo.txt|THIẾU||680|-1|
|Public/Config|PetHuanhuaTable.txt|map|dev/server/tables/shared/pet_transforms.tsv|5607|7039|
|Public/Config|PetHuanTongCost.txt|map-ref|dev/server/tables/shared/pet_rejuvenation_costs.tsv|255|155|
|Public/Config|PetLevelUpTable.txt|map-ref|dev/server/tables/shared/pet_exp_levels.tsv|255|155|
|Public/Config|PetMedicineHCCompound.txt|map-ref|dev/server/tables/shared/pet_pill_compounds.tsv|96|96|
|Public/Config|PetSkillBook.txt|map-ref|dev/server/tables/shared/pet_skill_books.tsv|125|125|
|Public/Config|PetSkillLevelup.txt|map-ref|dev/server/tables/shared/pet_skill_upgrades.tsv|267|267|
|Public/Config|PetTitle.txt|map-ref|dev/server/tables/shared/pet_titles.tsv|149|323|
|Public/Config|PetTypeAttr.txt|map-ref|dev/server/tables/shared/pet_types.tsv|1144|1378|
|Public/Config|PlayerExpLevel.txt|map-ref|dev/server/tables/shared/player_exp_levels.tsv|255|150|
|Public/Config|PneumaInfo.txt|map|dev/server/tables/shared/pneuma.tsv|2052|2052|
|Public/Config|RecycleItem.txt|map-ref|dev/server/tables/shared/recycle_items.tsv|462|465|
|Public/Config|RecycleItemClass.txt|map-ref|dev/server/tables/shared/recycle_classes.tsv|7|7|
|Public/Config|RecycleItemType.txt|map-ref|dev/server/tables/shared/recycle_types.tsv|38|41|
|Public/Config|RepairRate.txt|map-ref|dev/server/tables/shared/repair_rates.tsv|15|15|
|Public/Config|ReputationTable.txt|map-ref|dev/server/tables/shared/reputation_factions.tsv|64|64|
|Public/Config|ResearchItem.txt|map-ref|dev/server/tables/shared/guild_research_items.tsv|106|106|
|Public/Config|RLAttrEx.txt|map|dev/server/tables/shared/rl_extra_attributes.tsv|11|11|
|Public/Config|SceneAttr.txt|map-ref|dev/server/tables/shared/scene_attributes.tsv|727|32736|
|Public/Config|ShopSceneLimiti.txt|map-ref|dev/server/tables/shared/shop_scene_limits.tsv|237|383|
|Public/Config|ShopTable.txt|map-ref|dev/server/tables/shared/shops.tsv|237|383|
|Public/Config|SkillBullet.txt|map|dev/server/tables/server/skill_bullets.tsv|4|4|
|Public/Config|SkillData_V1.txt|map-ref|dev/server/tables/shared/skill_levels.tsv|8672|20667|
|Public/Config|SkillTemplate_V1.txt|map-ref|dev/server/tables/shared/skills.tsv|1986|4586|
|Public/Config|SkillTemplate_V1X.txt|THIẾU||1930|-1|
|Public/Config|SlotCost.txt|map-ref|dev/server/tables/shared/equipment_slot_costs.tsv|702|520|
|Public/Config|SpecialObjData.txt|map-ref|dev/server/tables/shared/special_objects.tsv|507|1843|
|Public/Config|StandardImpact.txt|map|dev/server/tables/server/effects.tsv|13311|9860|
|Public/Config|StoreMapItem.txt|map-ref|dev/server/tables/shared/treasure_maps.tsv|1|1|
|Public/Config|StorytellingDuologue.txt|map-ref|dev/server/tables/shared/storyteller_dialogue.tsv|123|123|
|Public/Config|SuperWeapon9WG.txt|map|dev/server/tables/shared/super_weapon_9_wg.tsv|126|135|
|Public/Config|SuperWeaponQH.txt|map|dev/server/tables/shared/super_weapon_enhance.tsv|79|79|
|Public/Config|SuperWeaponSX.txt|map|dev/server/tables/shared/super_weapon_attributes.tsv|81|81|
|Public/Config|SuperWeaponTL.txt|map|dev/server/tables/shared/super_weapon_tl.tsv|282|302|
|Public/Config|SuperWeaponUp.txt|map|dev/server/tables/shared/super_weapon_up.tsv|652|699|
|Public/Config|SuperWeaponUpgrade.txt|THIẾU||438|-1|
|Public/Config|SuperWeaponWG.txt|map|dev/server/tables/shared/super_weapon_wg.tsv|154|167|
|Public/Config|UnderArmourLevel.txt|map|dev/server/tables/shared/under_armour_levels.tsv|163|165|
|Public/Config|UnderArmourLevel1.txt|THIẾU||163|-1|
|Public/Config|WhiteEquipBase.txt|map|dev/server/tables/shared/equipment_white.tsv|354|354|
|Public/Config|WuHunSkillLevelUp.txt|THIẾU||252|-1|
|Public/Config|XinFaStudySpend_V1.txt|map-ref|dev/server/tables/shared/inner_art_learn_costs.tsv|257|302|
|Public/Config|XinFa_V1.txt|map-ref|dev/server/tables/shared/inner_arts.tsv|112|120|
|Public/Config|XiuLianDetial.txt|THIẾU||150|-1|
|Public/Config|XYJ_AgnameData.txt|THIẾU||857|-1|
|Public/Config|XYJ_GemGrade.txt|THIẾU||964|-1|
|Public/Config|XYJ_ScriptSkillTable.txt|THIẾU||479|-1|
|Public/Config|XYJ_ShopTable.txt|THIẾU||1618|-1|
|Public/Config|XYJ_ShopTableBak.txt|THIẾU||1524|-1|
|Public/Config|XYJ_TaoHuaDaoVisual.txt|THIẾU||25|-1|
|Public/Config|ZhanLingInfo.txt|map|dev/server/tables/shared/battle_pass.tsv|434|407|
|Public/Config|ZMPTEnter.txt|map|dev/server/tables/shared/clan_tower_enter.tsv|98|100|
|Public/Config|AbilityLevelUp/assistant.txt|name|dev/server/tables/shared/life_skill_levels/assistant.tsv|100|100|
|Public/Config|AbilityLevelUp/assistant_menpai.txt|THIẾU||100|-1|
|Public/Config|AbilityLevelUp/caikuang.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/cailiaojiagong.txt|THIẾU||1|-1|
|Public/Config|AbilityLevelUp/caiyao.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/diaoyu.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/dingweifu.txt|THIẾU||3|-1|
|Public/Config|AbilityLevelUp/fengren.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/gaojishenghuo.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/gongyi.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/menpai.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/menpaifuzhu.txt|THIẾU||100|-1|
|Public/Config|AbilityLevelUp/menpaishenghuo.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/normal.txt|name|dev/server/tables/shared/life_skill_levels/normal.tsv|10|10|
|Public/Config|AbilityLevelUp/pengren.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/putongshenghuo.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/shenghuofuzhu.txt|THIẾU||100|-1|
|Public/Config|AbilityLevelUp/xiangqian.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/XinFaStudySpend_V1.txt|name|dev/server/tables/client/abilitylevelup/xinfastudyspend_v1.tsv|152|152|
|Public/Config|AbilityLevelUp/yangsheng.txt|THIẾU||100|-1|
|Public/Config|AbilityLevelUp/yaoli.txt|THIẾU||100|-1|
|Public/Config|AbilityLevelUp/zhiyao.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/zhongzhi.txt|THIẾU||10|-1|
|Public/Config|AbilityLevelUp/zhuzao.txt|THIẾU||10|-1|
|Public/Config|RandShop/100wufang.ini|map|dev/server/tables/server/random_shop_goods.tsv|67|458|
|Public/Config|RandShop/60wufang.ini|map|dev/server/tables/server/random_shop_goods.tsv|15|458|
|Public/Config|RandShop/70wufang.ini|map|dev/server/tables/server/random_shop_goods.tsv|25|458|
|Public/Config|RandShop/80wufang.ini|map|dev/server/tables/server/random_shop_goods.tsv|39|458|
|Public/Config|RandShop/90wufang.ini|map|dev/server/tables/server/random_shop_goods.tsv|53|458|
|Public/Config|RandShop/dazaotu.ini|map|dev/server/tables/server/random_shop_goods.tsv|81|458|
|Public/Config|RandShop/huanglong_randgemshop.ini|map|dev/server/tables/server/random_shop_goods.tsv|6|458|
|Public/Config|RandShop/miaojiang_randgemshop.ini|map|dev/server/tables/server/random_shop_goods.tsv|7|458|
|Public/Config|RandShop/mystery_shop.ini|THIẾU||21|-1|
|Public/Config|RandShop/petskillshop.ini|map|dev/server/tables/server/random_shop_goods.tsv|10|458|
|Public/Config|RandShop/qiongzhou_randgemshop.ini|map|dev/server/tables/server/random_shop_goods.tsv|10|458|
|Public/Config|RandShop/randgemshop.ini|map|dev/server/tables/server/random_shop_goods.tsv|21|458|
|Public/Config|RandShop/shanedian.ini|map|dev/server/tables/server/random_shop_goods.tsv|85|458|
|Public/Config|RandShop/shide.ini|map|dev/server/tables/server/random_shop_goods.tsv|11|458|
|Public/Config|RandShop/shuhe_randgemshop.ini|map|dev/server/tables/server/random_shop_goods.tsv|21|458|
|Public/Config|RandShop/Xiao_Huang_ZiRandomShop.ini|THIẾU||0|-1|
|Public/Config|RandShop/xunluozawu.ini|map|dev/server/tables/server/random_shop_goods.tsv|22|458|
