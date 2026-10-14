----------------------
-- HD_LongZhengWuZai2 ---
----------------------
local ITEM_ID = -1
local FIVEYEAR_NPC_ID = -1
local objCared = -1
local g_Cardlist = {}
local MAX_OBJ_DISTANCE = 3.0;
local g_HD_LongZhengWuZai2_Frame_UnifiedPosition =nil;
--===============================================
-- PreLoad()
--===============================================
function HD_LongZhengWuZai2_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
end

--===============================================
-- OnLoad()
--===============================================
function HD_LongZhengWuZai2_OnLoad()

	g_HD_LongZhengWuZai2_Frame_UnifiedPosition = HD_LongZhengWuZai2_Frame:GetProperty("UnifiedPosition")
	g_Cardlist[1] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item1, 
				Text =HD_LongZhengWuZai2_ItemInfo1, 
				enablestr = "#{LZWZ_120117_94}",
				disablestr = "#{LZWZ_120117_118}",
				eventstr = "#{LZWZ_120117_142}",
				normalstr = "#{LZWZ_120117_204}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_1",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_1",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_1",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_9",
				ClieckFlash = HD_LongZhengWuZai2_Flash1,
				}	--乔峰归来纪念卡
	g_Cardlist[2] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item2, 
				Text =HD_LongZhengWuZai2_ItemInfo2,
				enablestr = "#{LZWZ_120117_95}",
				disablestr = "#{LZWZ_120117_119}",
				eventstr = "#{LZWZ_120117_143}",
				normalstr = "#{LZWZ_120117_205}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_2",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_2",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_2",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_10",
				ClieckFlash = HD_LongZhengWuZai2_Flash2,
				}	--仙人指路纪念卡
	g_Cardlist[3] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item3, 
				Text =HD_LongZhengWuZai2_ItemInfo3, 
				enablestr = "#{LZWZ_120117_96}",
				disablestr = "#{LZWZ_120117_120}",
				eventstr = "#{LZWZ_120117_144}",
				normalstr = "#{LZWZ_120117_206}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_3",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_3",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_3",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_11",
				ClieckFlash = HD_LongZhengWuZai2_Flash3,
				}	--准正式版纪念卡
	g_Cardlist[4] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item4, 
				Text =HD_LongZhengWuZai2_ItemInfo4, 
				enablestr = "#{LZWZ_120117_97}",
				disablestr = "#{LZWZ_120117_121}",
				eventstr = "#{LZWZ_120117_145}",
				normalstr = "#{LZWZ_120117_207}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_4",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_4",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_4",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_12",
				ClieckFlash = HD_LongZhengWuZai2_Flash4,
				}	--贺岁版纪念卡
	g_Cardlist[5] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item5,
				Text =HD_LongZhengWuZai2_ItemInfo5,
				enablestr = "#{LZWZ_120117_98}",
				disablestr = "#{LZWZ_120117_122}",
				eventstr = "#{LZWZ_120117_146}",
				normalstr = "#{LZWZ_120117_208}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_5",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_5",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_5",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_13",
				ClieckFlash = HD_LongZhengWuZai2_Flash5,
				}	--沙漠迷城纪念卡
	g_Cardlist[6] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item6, 
				Text =HD_LongZhengWuZai2_ItemInfo6, 
				enablestr = "#{LZWZ_120117_99}",
				disablestr = "#{LZWZ_120117_123}",
				eventstr = "#{LZWZ_120117_147}",
				normalstr = "#{LZWZ_120117_209}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_6",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_6",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_6",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_14",
				ClieckFlash = HD_LongZhengWuZai2_Flash6,
				}	--战神版纪念卡
	g_Cardlist[7] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item7, 
				Text =HD_LongZhengWuZai2_ItemInfo7, 
				enablestr = "#{LZWZ_120117_100}",
				disablestr = "#{LZWZ_120117_124}",
				eventstr = "#{LZWZ_120117_148}",
				normalstr = "#{LZWZ_120117_210}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_1",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_1",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_7",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_15",
				ClieckFlash = HD_LongZhengWuZai2_Flash7,
				}	--秦皇地宫纪念卡
	g_Cardlist[8] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item8, 
				Text =HD_LongZhengWuZai2_ItemInfo8, 
				enablestr = "#{LZWZ_120117_101}",
				disablestr = "#{LZWZ_120117_125}",
				eventstr = "#{LZWZ_120117_149}",
				normalstr = "#{LZWZ_120117_211}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_2",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_2",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_8",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_16",
				ClieckFlash = HD_LongZhengWuZai2_Flash8,
				}	--麻辣国子监纪念卡
	g_Cardlist[9] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item9, 
				Text =HD_LongZhengWuZai2_ItemInfo9, 
				enablestr = "#{LZWZ_120117_102}",
				disablestr = "#{LZWZ_120117_126}",
				eventstr = "#{LZWZ_120117_150}",
				normalstr = "#{LZWZ_120117_212}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_3",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_3",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_9",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_1",
				ClieckFlash = HD_LongZhengWuZai2_Flash9,
				
				}	--功夫之王纪念卡
	g_Cardlist[10] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item10, 
				Text =HD_LongZhengWuZai2_ItemInfo10, 
				enablestr = "#{LZWZ_120117_103}",
				disablestr = "#{LZWZ_120117_127}",
				eventstr = "#{LZWZ_120117_151}",
				normalstr = "#{LZWZ_120117_213}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_4",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_4",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_10",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_2",
				ClieckFlash = HD_LongZhengWuZai2_Flash10,
				}	--大决战纪念卡
	g_Cardlist[11] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item11, 
				Text =HD_LongZhengWuZai2_ItemInfo11, 
				enablestr = "#{LZWZ_120117_104}",
				disablestr = "#{LZWZ_120117_128}",
				eventstr = "#{LZWZ_120117_152}",
				normalstr = "#{LZWZ_120117_214}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_5",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_5",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_11",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_3",
				ClieckFlash = HD_LongZhengWuZai2_Flash11,
				}	--影子传说纪念卡
	g_Cardlist[12] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item12, 
				Text =HD_LongZhengWuZai2_ItemInfo12, 
				enablestr = "#{LZWZ_120117_105}",
				disablestr = "#{LZWZ_120117_129}",
				eventstr = "#{LZWZ_120117_153}",
				normalstr = "#{LZWZ_120117_215}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_6",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_6",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_12",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_4",
				ClieckFlash = HD_LongZhengWuZai2_Flash12,
				}	--笑傲昆仑纪念卡
	g_Cardlist[13] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item13, 
				Text =HD_LongZhengWuZai2_ItemInfo13, 
				enablestr = "#{LZWZ_120117_106}",
				disablestr = "#{LZWZ_120117_130}",
				eventstr = "#{LZWZ_120117_154}",
				normalstr = "#{LZWZ_120117_216}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_1",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_1",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_13",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_5",
				ClieckFlash = HD_LongZhengWuZai2_Flash13,
				}	--正式版纪念卡
	g_Cardlist[14] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item14, 
				Text =HD_LongZhengWuZai2_ItemInfo14, 
				enablestr = "#{LZWZ_120117_107}",
				disablestr = "#{LZWZ_120117_131}",
				eventstr = "#{LZWZ_120117_155}",
				normalstr = "#{LZWZ_120117_217}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_2",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_2",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_14",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_6",
				ClieckFlash = HD_LongZhengWuZai2_Flash14,
				}	--新春百乐汇纪念卡
	g_Cardlist[15] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item15, 
				Text =HD_LongZhengWuZai2_ItemInfo15, 
				enablestr = "#{LZWZ_120117_108}",
				disablestr = "#{LZWZ_120117_132}",
				eventstr = "#{LZWZ_120117_249}",   --后补的
				normalstr = "#{LZWZ_120117_218}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_3",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_3",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_15",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_7",
				ClieckFlash = HD_LongZhengWuZai2_Flash15,
				}	--剑影侠情纪念卡
	g_Cardlist[16] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item16, 
				Text =HD_LongZhengWuZai2_ItemInfo16, 
				enablestr = "#{LZWZ_120117_109}",
				disablestr = "#{LZWZ_120117_133}",
				eventstr = "#{LZWZ_120117_156}",
				normalstr = "#{LZWZ_120117_219}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_4",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_4",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_16",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_8",
				ClieckFlash = HD_LongZhengWuZai2_Flash16,
				}	--慕容世家纪念卡
	g_Cardlist[17] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item17, 
				Text =HD_LongZhengWuZai2_ItemInfo17, 
				enablestr = "#{LZWZ_120117_110}",
				disablestr = "#{LZWZ_120117_134}",
				eventstr = "#{LZWZ_120117_157}",
				normalstr = "#{LZWZ_120117_220}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_5",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_5",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_1",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_9",
				ClieckFlash = HD_LongZhengWuZai2_Flash17,
				}	--天机奇缘纪念卡
	g_Cardlist[18] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item18, 
				Text =HD_LongZhengWuZai2_ItemInfo18, 
				enablestr = "#{LZWZ_120117_111}",
				disablestr = "#{LZWZ_120117_135}",
				eventstr = "#{LZWZ_120117_158}",
				normalstr = "#{LZWZ_120117_221}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_6",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_6",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_2",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_10",
				ClieckFlash = HD_LongZhengWuZai2_Flash18,
				}	--血战雁门关纪念卡
	g_Cardlist[19] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item19, 
				Text =HD_LongZhengWuZai2_ItemInfo19, 
				enablestr = "#{LZWZ_120117_112}",
				disablestr = "#{LZWZ_120117_136}",
				eventstr = "#{LZWZ_120117_159}",
				normalstr = "#{LZWZ_120117_222}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_1",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_1",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_3",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_11",
				ClieckFlash = HD_LongZhengWuZai2_Flash19,
				}	--暴雪狂欢节纪念卡
	g_Cardlist[20] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item20, 
				Text =HD_LongZhengWuZai2_ItemInfo20, 
				enablestr = "#{LZWZ_120117_113}",
				disablestr = "#{LZWZ_120117_137}",
				eventstr = "#{LZWZ_120117_160}",
				normalstr = "#{LZWZ_120117_223}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_2",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_2",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_4",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_12",
				ClieckFlash = HD_LongZhengWuZai2_Flash20,
				}	--飞龙在天纪念卡
	g_Cardlist[21] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item21, 
				Text =HD_LongZhengWuZai2_ItemInfo21, 
				enablestr = "#{LZWZ_120117_114}",
				disablestr = "#{LZWZ_120117_138}",
				eventstr = "#{LZWZ_120117_161}",
				normalstr = "#{LZWZ_120117_224}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_3",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_3",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_5",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_13",
				ClieckFlash = HD_LongZhengWuZai2_Flash21,
				}	--给利一夏纪念卡
	g_Cardlist[22] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item22, 
				Text =HD_LongZhengWuZai2_ItemInfo22, 
				enablestr = "#{LZWZ_120117_115}",
				disablestr = "#{LZWZ_120117_139}",
				eventstr = "#{LZWZ_120117_162}",
				normalstr = "#{LZWZ_120117_225}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_4",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_4",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_6",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_14",
				ClieckFlash = HD_LongZhengWuZai2_Flash22,
				}	--天外江湖纪念卡
	g_Cardlist[23] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item23, 
				Text =HD_LongZhengWuZai2_ItemInfo23, 
				enablestr = "#{LZWZ_120117_116}",
				disablestr = "#{LZWZ_120117_140}",
				eventstr = "#{LZWZ_120117_163}",
				normalstr = "#{LZWZ_120117_226}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_5",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_5",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_7",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_15",
				ClieckFlash = HD_LongZhengWuZai2_Flash23,
				}  --雪舞燃情纪念卡
	g_Cardlist[24] = {
				active = 0,
				Button = HD_LongZhengWuZai2_Item24, 
				Text =HD_LongZhengWuZai2_ItemInfo24, 
				enablestr = "#{LZWZ_120117_117}",
				disablestr = "#{LZWZ_120117_141}",
				eventstr = "#{LZWZ_120117_164}",
				normalstr = "#{LZWZ_120117_227}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_6",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_6",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_8",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_16",
				ClieckFlash = HD_LongZhengWuZai2_Flash24,
				}	--龙腾盛世纪念卡
	
	HD_LongZhengWuZai2_Item1:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item2:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item3:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item4:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item5:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item6:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item7:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item8:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item9:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item10:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item11:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item12:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item13:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item14:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item15:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item16:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item17:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item18:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item19:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item20:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item21:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item22:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item23:SetProperty("Disabled", "True");
	HD_LongZhengWuZai2_Item24:SetProperty("Disabled", "True");
	
	
end

--===============================================
-- OnEvent()
--===============================================
function HD_LongZhengWuZai2_OnEvent(event)

	if (event  == "UI_COMMAND") and (tonumber(arg0) == 20120203) then
	
			FIVEYEAR_NPC_ID = Get_XParam_INT(0);
			objCared = DataPool : GetNPCIDByServerID(FIVEYEAR_NPC_ID);
			BeginCareObject_HD_LongZhengWuZai2(objCared)
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("ClientUpdataCardlist");
				Set_XSCRIPT_ScriptID(889669);
				Set_XSCRIPT_ParamCount(0);
			Send_XSCRIPT();			
	elseif (event  == "UI_COMMAND") and (tonumber(arg0) == 20120205) then
		HD_LongZhengWuZai2_Init()
		HD_LongZhengWuZai2_Text:SetText("#{LZWZ_120117_93}")
		local done = Get_XParam_STR(0);
		for i = 1, 24 do
			if tonumber(string.sub(done,i,i)) == 1 then
				g_Cardlist[i].Button : SetProperty("Disabled", "False")
				g_Cardlist[i].Text : SetText(g_Cardlist[i].enablestr)
				g_Cardlist[i].active = 1
			else
				g_Cardlist[i].Button : SetProperty("Disabled", "False")
				g_Cardlist[i].Button : SetProperty("NormalImage", g_Cardlist[i].DisableIcon)
				g_Cardlist[i].Button : SetProperty("PushedImage", g_Cardlist[i].DisableIcon)
				g_Cardlist[i].Button : SetProperty("HoverImage", g_Cardlist[i].DisableIcon)
				g_Cardlist[i].Text : SetText(g_Cardlist[i].disablestr)
			end
		end
		HD_LongZhengWuZai2_Clicked(1)  --默认按第一个
		this:Show()
	elseif (event  == "UI_COMMAND") and (tonumber(arg0) == 20120206) then
		HD_LongZhengWuZai2_Init()
		for i = 1, 24 do
			g_Cardlist[i].Button : SetProperty("Disabled", "False")
			g_Cardlist[i].active = 1
		end
		HD_LongZhengWuZai2_Text:SetText("#{LZWZ_120117_241}")
		HD_LongZhengWuZai2_Clicked(1)  --默认按第一个
		this:Show()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			
			--取消关心
			HD_LongZhengWuZai2_Cancel_Clicked()
		end
	elseif (event == "ADJEST_UI_POS") then
		HD_LongZhengWuZai2_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then	
		HD_LongZhengWuZai2_ResetPos()
	end
end
      

--===============================================
-- Close()
--===============================================
function HD_LongZhengWuZai2_Close()
	--并设置，让背包里的位置变亮
	StopCareObject_EquipRepair(objCared)
	EQUIP_NPC_ID = -1
	return this:Hide()
end

function HD_LongZhengWuZai2_ResetPos()
	HD_LongZhengWuZai2_Frame:SetProperty("UnifiedPosition",g_HD_LongZhengWuZai2_Frame_UnifiedPosition)
end

--===============================================
-- Init()
--===============================================
function HD_LongZhengWuZai2_Init()
	for i = 1, 24 do
		g_Cardlist[i].Button : SetProperty("Disabled", "True")
		g_Cardlist[i].Button : SetProperty("NormalImage", g_Cardlist[i].NomalIcon)
		g_Cardlist[i].Button : SetProperty("PushedImage", g_Cardlist[i].NomalIcon)
		g_Cardlist[i].Button : SetProperty("HoverImage", g_Cardlist[i].NomalIcon)
		g_Cardlist[i].Text   : SetText(g_Cardlist[i].normalstr)
		
		g_Cardlist[i].active = 0
		g_Cardlist[i].ClieckFlash:Hide()
	end
	HD_LongZhengWuZai2_Image : SetProperty("Image","set:LongZhengWuZai9 image:LongZhengWuZai9_1")
	HD_LongZhengWuZai2__Text:SetText("")
end
--===============================================
-- Clicked()
--===============================================

function HD_LongZhengWuZai2_Clicked(ButtonID)
	HD_LongZhengWuZai2__Text : SetText(g_Cardlist[ButtonID].eventstr)
	if(g_Cardlist[ButtonID].active == 1) then  
		HD_LongZhengWuZai2_Image : SetProperty("Image", g_Cardlist[ButtonID].NomalImage)	--已经激活的
	else
		HD_LongZhengWuZai2_Image : SetProperty("Image", g_Cardlist[ButtonID].DisableImage)	--未激活的
	end
	for i = 1,24 do
		if i == ButtonID then
			g_Cardlist[i].ClieckFlash:Show()
		else
			g_Cardlist[i].ClieckFlash:Hide()
		end
	end
end


function HD_LongZhengWuZai2_Cancel_Clicked()
	HD_LongZhengWuZai2_Close();
	return;
end


--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_HD_LongZhengWuZai2(objCaredId)
	
	this:CareObject(objCaredId, 0, "HD_LongZhengWuZai2");
	g_Object = -1;

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_HD_LongZhengWuZai2(objCaredId)
	
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "HD_LongZhengWuZai2");

end

