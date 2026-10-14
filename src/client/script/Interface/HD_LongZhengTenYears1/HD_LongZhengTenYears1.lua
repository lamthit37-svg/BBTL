-------------------------------------------------------
-- 龙征十载纪念册 by lishilong 2017-2-17
-------------------------------------------------------
local ITEM_ID = -1
local FIVEYEAR_NPC_ID = -1
local objCared = -1
local g_Cardlist = {}
local MAX_OBJ_DISTANCE = 3.0;
local g_HD_LongZhengTenYears1_Frame_UnifiedPosition = nil;
local g_nUICommand	= 920170214

--===============================================
-- PreLoad()
--===============================================
function HD_LongZhengTenYears1_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
end

--===============================================
-- OnLoad()
--===============================================
function HD_LongZhengTenYears1_OnLoad()

	g_HD_LongZhengTenYears1_Frame_UnifiedPosition = HD_LongZhengTenYears1_Frame:GetProperty("UnifiedPosition")
	g_Cardlist[1] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item1, 
				Text =HD_LongZhengTenYears1_ItemInfo1, 
				enablestr = "#{LZWZ_120117_94}",
				disablestr = "#{LZWZ_120117_118}",
				eventstr = "#{LZWZ_120117_142}",
				normalstr = "#{LZWZ_120117_204}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_1",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_1",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_1",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_9",
				ClieckFlash = HD_LongZhengTenYears1_Flash1,
				}	--乔峰归来纪念卡
	g_Cardlist[2] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item2, 
				Text =HD_LongZhengTenYears1_ItemInfo2,
				enablestr = "#{LZWZ_120117_95}",
				disablestr = "#{LZWZ_120117_119}",
				eventstr = "#{LZWZ_120117_143}",
				normalstr = "#{LZWZ_120117_205}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_2",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_2",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_2",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_10",
				ClieckFlash = HD_LongZhengTenYears1_Flash2,
				}	--仙人指路纪念卡
	g_Cardlist[3] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item3, 
				Text =HD_LongZhengTenYears1_ItemInfo3, 
				enablestr = "#{LZWZ_120117_96}",
				disablestr = "#{LZWZ_120117_120}",
				eventstr = "#{LZWZ_120117_144}",
				normalstr = "#{LZWZ_120117_206}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_3",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_3",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_3",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_11",
				ClieckFlash = HD_LongZhengTenYears1_Flash3,
				}	--准正式版纪念卡
	g_Cardlist[4] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item4, 
				Text =HD_LongZhengTenYears1_ItemInfo4, 
				enablestr = "#{LZWZ_120117_97}",
				disablestr = "#{LZWZ_120117_121}",
				eventstr = "#{LZWZ_120117_145}",
				normalstr = "#{LZWZ_120117_207}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_4",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_4",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_4",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_12",
				ClieckFlash = HD_LongZhengTenYears1_Flash4,
				}	--贺岁版纪念卡
	g_Cardlist[5] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item5,
				Text =HD_LongZhengTenYears1_ItemInfo5,
				enablestr = "#{LZWZ_120117_98}",
				disablestr = "#{LZWZ_120117_122}",
				eventstr = "#{LZWZ_120117_146}",
				normalstr = "#{LZWZ_120117_208}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_5",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_5",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_5",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_13",
				ClieckFlash = HD_LongZhengTenYears1_Flash5,
				}	--沙漠迷城纪念卡
	g_Cardlist[6] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item6, 
				Text =HD_LongZhengTenYears1_ItemInfo6, 
				enablestr = "#{LZWZ_120117_99}",
				disablestr = "#{LZWZ_120117_123}",
				eventstr = "#{LZWZ_120117_147}",
				normalstr = "#{LZWZ_120117_209}",
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_6",
				DisableImage = "set:LongZhengWuZai5 image:LongZhengWuZai5_6",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_6",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_14",
				ClieckFlash = HD_LongZhengTenYears1_Flash6,
				}	--战神版纪念卡
	g_Cardlist[7] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item7, 
				Text =HD_LongZhengTenYears1_ItemInfo7, 
				enablestr = "#{LZWZ_120117_100}",
				disablestr = "#{LZWZ_120117_124}",
				eventstr = "#{LZWZ_120117_148}",
				normalstr = "#{LZWZ_120117_210}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_1",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_1",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_7",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_15",
				ClieckFlash = HD_LongZhengTenYears1_Flash7,
				}	--秦皇地宫纪念卡
	g_Cardlist[8] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item8, 
				Text =HD_LongZhengTenYears1_ItemInfo8, 
				enablestr = "#{LZWZ_120117_101}",
				disablestr = "#{LZWZ_120117_125}",
				eventstr = "#{LZWZ_120117_149}",
				normalstr = "#{LZWZ_120117_211}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_2",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_2",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_8",
				DisableIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_16",
				ClieckFlash = HD_LongZhengTenYears1_Flash8,
				}	--麻辣国子监纪念卡
	g_Cardlist[9] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item9, 
				Text =HD_LongZhengTenYears1_ItemInfo9, 
				enablestr = "#{LZWZ_120117_102}",
				disablestr = "#{LZWZ_120117_126}",
				eventstr = "#{LZWZ_120117_150}",
				normalstr = "#{LZWZ_120117_212}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_3",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_3",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_9",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_1",
				ClieckFlash = HD_LongZhengTenYears1_Flash9,
				
				}	--功夫之王纪念卡
	g_Cardlist[10] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item10, 
				Text =HD_LongZhengTenYears1_ItemInfo10, 
				enablestr = "#{LZWZ_120117_103}",
				disablestr = "#{LZWZ_120117_127}",
				eventstr = "#{LZWZ_120117_151}",
				normalstr = "#{LZWZ_120117_213}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_4",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_4",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_10",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_2",
				ClieckFlash = HD_LongZhengTenYears1_Flash10,
				}	--大决战纪念卡
	g_Cardlist[11] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item11, 
				Text =HD_LongZhengTenYears1_ItemInfo11, 
				enablestr = "#{LZWZ_120117_104}",
				disablestr = "#{LZWZ_120117_128}",
				eventstr = "#{LZWZ_120117_152}",
				normalstr = "#{LZWZ_120117_214}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_5",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_5",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_11",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_3",
				ClieckFlash = HD_LongZhengTenYears1_Flash11,
				}	--影子传说纪念卡
	g_Cardlist[12] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item12, 
				Text =HD_LongZhengTenYears1_ItemInfo12, 
				enablestr = "#{LZWZ_120117_105}",
				disablestr = "#{LZWZ_120117_129}",
				eventstr = "#{LZWZ_120117_153}",
				normalstr = "#{LZWZ_120117_215}",
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_6",
				DisableImage = "set:LongZhengWuZai6 image:LongZhengWuZai6_6",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_12",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_4",
				ClieckFlash = HD_LongZhengTenYears1_Flash12,
				}	--笑傲昆仑纪念卡
	g_Cardlist[13] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item13, 
				Text =HD_LongZhengTenYears1_ItemInfo13, 
				enablestr = "#{LZWZ_120117_106}",
				disablestr = "#{LZWZ_120117_130}",
				eventstr = "#{LZWZ_120117_154}",
				normalstr = "#{LZWZ_120117_216}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_1",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_1",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_13",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_5",
				ClieckFlash = HD_LongZhengTenYears1_Flash13,
				}	--正式版纪念卡
	g_Cardlist[14] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item14, 
				Text =HD_LongZhengTenYears1_ItemInfo14, 
				enablestr = "#{LZWZ_120117_107}",
				disablestr = "#{LZWZ_120117_131}",
				eventstr = "#{LZWZ_120117_155}",
				normalstr = "#{LZWZ_120117_217}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_2",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_2",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_14",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_6",
				ClieckFlash = HD_LongZhengTenYears1_Flash14,
				}	--新春百乐汇纪念卡
	g_Cardlist[15] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item15, 
				Text =HD_LongZhengTenYears1_ItemInfo15, 
				enablestr = "#{LZWZ_120117_108}",
				disablestr = "#{LZWZ_120117_132}",
				eventstr = "#{LZWZ_120117_249}",   --后补的
				normalstr = "#{LZWZ_120117_218}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_3",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_3",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_15",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_7",
				ClieckFlash = HD_LongZhengTenYears1_Flash15,
				}	--剑影侠情纪念卡
	g_Cardlist[16] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item16, 
				Text =HD_LongZhengTenYears1_ItemInfo16, 
				enablestr = "#{LZWZ_120117_109}",
				disablestr = "#{LZWZ_120117_133}",
				eventstr = "#{LZWZ_120117_156}",
				normalstr = "#{LZWZ_120117_219}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_4",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_4",
				NomalIcon = "set:LongZhengWuZai_Icon1 image:LongZhengWuZai_Icon1_16",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_8",
				ClieckFlash = HD_LongZhengTenYears1_Flash16,
				}	--慕容世家纪念卡
	g_Cardlist[17] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item17, 
				Text =HD_LongZhengTenYears1_ItemInfo17, 
				enablestr = "#{LZWZ_120117_110}",
				disablestr = "#{LZWZ_120117_134}",
				eventstr = "#{LZWZ_120117_157}",
				normalstr = "#{LZWZ_120117_220}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_5",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_5",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_1",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_9",
				ClieckFlash = HD_LongZhengTenYears1_Flash17,
				}	--天机奇缘纪念卡
	g_Cardlist[18] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item18, 
				Text =HD_LongZhengTenYears1_ItemInfo18, 
				enablestr = "#{LZWZ_120117_111}",
				disablestr = "#{LZWZ_120117_135}",
				eventstr = "#{LZWZ_120117_158}",
				normalstr = "#{LZWZ_120117_221}",
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_6",
				DisableImage = "set:LongZhengWuZai7 image:LongZhengWuZai7_6",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_2",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_10",
				ClieckFlash = HD_LongZhengTenYears1_Flash18,
				}	--血战雁门关纪念卡
	g_Cardlist[19] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item19, 
				Text =HD_LongZhengTenYears1_ItemInfo19, 
				enablestr = "#{LZWZ_120117_112}",
				disablestr = "#{LZWZ_120117_136}",
				eventstr = "#{LZWZ_120117_159}",
				normalstr = "#{LZWZ_120117_222}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_1",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_1",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_3",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_11",
				ClieckFlash = HD_LongZhengTenYears1_Flash19,
				}	--暴雪狂欢节纪念卡
	g_Cardlist[20] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item20, 
				Text =HD_LongZhengTenYears1_ItemInfo20, 
				enablestr = "#{LZWZ_120117_113}",
				disablestr = "#{LZWZ_120117_137}",
				eventstr = "#{LZWZ_120117_160}",
				normalstr = "#{LZWZ_120117_223}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_2",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_2",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_4",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_12",
				ClieckFlash = HD_LongZhengTenYears1_Flash20,
				}	--飞龙在天纪念卡
	g_Cardlist[21] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item21, 
				Text =HD_LongZhengTenYears1_ItemInfo21, 
				enablestr = "#{LZWZ_120117_114}",
				disablestr = "#{LZWZ_120117_138}",
				eventstr = "#{LZWZ_120117_161}",
				normalstr = "#{LZWZ_120117_224}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_3",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_3",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_5",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_13",
				ClieckFlash = HD_LongZhengTenYears1_Flash21,
				}	--给利一夏纪念卡
	g_Cardlist[22] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item22, 
				Text =HD_LongZhengTenYears1_ItemInfo22, 
				enablestr = "#{LZWZ_120117_115}",
				disablestr = "#{LZWZ_120117_139}",
				eventstr = "#{LZWZ_120117_162}",
				normalstr = "#{LZWZ_120117_225}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_4",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_4",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_6",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_14",
				ClieckFlash = HD_LongZhengTenYears1_Flash22,
				}	--天外江湖纪念卡
	g_Cardlist[23] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item23, 
				Text =HD_LongZhengTenYears1_ItemInfo23, 
				enablestr = "#{LZWZ_120117_116}",
				disablestr = "#{LZWZ_120117_140}",
				eventstr = "#{LZWZ_120117_163}",
				normalstr = "#{LZWZ_120117_226}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_5",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_5",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_7",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_15",
				ClieckFlash = HD_LongZhengTenYears1_Flash23,
				}  --雪舞燃情纪念卡
	g_Cardlist[24] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item24, 
				Text =HD_LongZhengTenYears1_ItemInfo24, 
				enablestr = "#{LZWZ_120117_117}",
				disablestr = "#{LZWZ_120117_141}",
				eventstr = "#{LZWZ_120117_164}",
				normalstr = "#{LZWZ_120117_227}",
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_6",
				DisableImage = "set:LongZhengWuZai8 image:LongZhengWuZai8_6",
				NomalIcon = "set:LongZhengWuZai_Icon2 image:LongZhengWuZai_Icon2_8",
				DisableIcon = "set:LongZhengWuZai_Icon3 image:LongZhengWuZai_Icon3_16",
				ClieckFlash = HD_LongZhengTenYears1_Flash24,
				}	--龙腾盛世纪念卡
	
	g_Cardlist[25] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item25, 
				Text =HD_LongZhengTenYears1_ItemInfo25, 
				enablestr = "#{LZWZ_160223_037}",
				disablestr = "#{LZWZ_160223_054}",
				eventstr = "#{LZWZ_160223_071}",
				normalstr = "#{LZWZ_160223_088}",
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_1",
				DisableImage = "set:LongZhengWuZai12 image:LongZhengWuZai12_1",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_1",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_1",
				ClieckFlash = HD_LongZhengTenYears1_Flash25,
				}	--龙战九天龙火卡
	
	g_Cardlist[26] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item26, 
				Text =HD_LongZhengTenYears1_ItemInfo26, 
				enablestr = "#{LZWZ_160223_038}",
				disablestr = "#{LZWZ_160223_055}",
				eventstr = "#{LZWZ_160223_072}",
				normalstr = "#{LZWZ_160223_089}",
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_2",
				DisableImage = "set:LongZhengWuZai12 image:LongZhengWuZai12_2",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_2",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_2",
				ClieckFlash = HD_LongZhengTenYears1_Flash26,
				}	--猎命江湖龙火卡
	g_Cardlist[27] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item27, 
				Text =HD_LongZhengTenYears1_ItemInfo27,
				enablestr = "#{LZWZ_160223_039}",
				disablestr = "#{LZWZ_160223_056}",
				eventstr = "#{LZWZ_160223_073}",
				normalstr = "#{LZWZ_160223_090}",
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_3",
				DisableImage = "set:LongZhengWuZai12 image:LongZhengWuZai12_3",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_3",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_3",
				ClieckFlash = HD_LongZhengTenYears1_Flash27,
				}	--神兵海域龙火卡
	g_Cardlist[28] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item28, 
				Text =HD_LongZhengTenYears1_ItemInfo28, 
				enablestr = "#{LZWZ_160223_040}",
				disablestr = "#{LZWZ_160223_057}",
				eventstr = "#{LZWZ_160223_074}",
				normalstr = "#{LZWZ_160223_091}",
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_4",
				DisableImage = "set:LongZhengWuZai12 image:LongZhengWuZai12_4",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_4",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_4",
				ClieckFlash = HD_LongZhengTenYears1_Flash28,
				}	--天降灵兽龙火卡
	g_Cardlist[29] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item29, 
				Text =HD_LongZhengTenYears1_ItemInfo29, 
				enablestr = "#{LZWZ_160223_041}",
				disablestr = "#{LZWZ_160223_058}",
				eventstr = "#{LZWZ_160223_075}",
				normalstr = "#{LZWZ_160223_092}",
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_5",
				DisableImage = "set:LongZhengWuZai12 image:LongZhengWuZai12_5",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_5",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_5",
				ClieckFlash = HD_LongZhengTenYears1_Flash29,
				}	--武林派对龙火卡
	g_Cardlist[30] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item30,
				Text =HD_LongZhengTenYears1_ItemInfo30,
				enablestr = "#{LZWZ_160223_042}",
				disablestr = "#{LZWZ_160223_059}",
				eventstr = "#{LZWZ_160223_076}",
				normalstr = "#{LZWZ_160223_093}",
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_6",
				DisableImage = "set:LongZhengWuZai12 image:LongZhengWuZai12_6",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_6",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_6",
				ClieckFlash = HD_LongZhengTenYears1_Flash30,
				}	--天下第一招龙火卡
				
				
	g_Cardlist[31] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item31, 
				Text =HD_LongZhengTenYears1_ItemInfo31, 
				enablestr = "#{LZWZ_160223_043}",
				disablestr = "#{LZWZ_160223_060}",
				eventstr = "#{LZWZ_160223_077}",
				normalstr = "#{LZWZ_160223_094}",
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_1",
				DisableImage = "set:LongZhengWuZai13 image:LongZhengWuZai13_1",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_7",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_7",
				ClieckFlash = HD_LongZhengTenYears1_Flash31,
				}	--天下第一擂龙火卡
	g_Cardlist[32] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item32, 
				Text =HD_LongZhengTenYears1_ItemInfo32, 
				enablestr = "#{LZWZ_160223_044}",
				disablestr = "#{LZWZ_160223_061}",
				eventstr = "#{LZWZ_160223_078}",
				normalstr = "#{LZWZ_160223_095}",
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_2",
				DisableImage = "set:LongZhengWuZai13 image:LongZhengWuZai13_2",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_8",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_8",
				ClieckFlash = HD_LongZhengTenYears1_Flash32,
				}	--绝世唐门龙火卡
	g_Cardlist[33] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item33, 
				Text =HD_LongZhengTenYears1_ItemInfo33, 
				enablestr = "#{LZWZ_160223_046}",
				disablestr = "#{LZWZ_160223_063}",
				eventstr = "#{LZWZ_160223_079}",
				normalstr = "#{LZWZ_160223_096}",
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_3",
				DisableImage = "set:LongZhengWuZai13 image:LongZhengWuZai13_3",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_9",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_9",
				ClieckFlash = HD_LongZhengTenYears1_Flash33,
				}	--狂战天下龙火卡
	g_Cardlist[34] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item34, 
				Text =HD_LongZhengTenYears1_ItemInfo34, 
				enablestr = "#{LZWZ_160223_047}",
				disablestr = "#{LZWZ_160223_064}",
				eventstr = "#{LZWZ_160223_080}",
				normalstr = "#{LZWZ_160223_097}",
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_4",
				DisableImage = "set:LongZhengWuZai13 image:LongZhengWuZai13_4",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_10",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_10",
				ClieckFlash = HD_LongZhengTenYears1_Flash34,
				
				}	--号令天下龙火卡
	g_Cardlist[35] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item35, 
				Text =HD_LongZhengTenYears1_ItemInfo35, 
				enablestr = "#{LZWZ_160223_048}",
				disablestr = "#{LZWZ_160223_065}",
				eventstr = "#{LZWZ_160223_081}",
				normalstr = "#{LZWZ_160223_098}",
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_5",
				DisableImage = "set:LongZhengWuZai13 image:LongZhengWuZai13_5",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_11",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_11",
				ClieckFlash = HD_LongZhengTenYears1_Flash35,
				}	--雄霸天下龙火卡
	g_Cardlist[36] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item36, 
				Text =HD_LongZhengTenYears1_ItemInfo36, 
				enablestr = "#{LZWZ_160223_049}",
				disablestr = "#{LZWZ_160223_066}",
				eventstr = "#{LZWZ_160223_082}",
				normalstr = "#{LZWZ_160223_099}",
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_6",
				DisableImage = "set:LongZhengWuZai13 image:LongZhengWuZai13_6",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_12",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_12",
				ClieckFlash = HD_LongZhengTenYears1_Flash36,
				}	--缘聚天下龙火卡
	g_Cardlist[37] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item37, 
				Text =HD_LongZhengTenYears1_ItemInfo37, 
				enablestr = "#{LZWZ_160223_050}",
				disablestr = "#{LZWZ_160223_067}",
				eventstr = "#{LZWZ_160223_083}",
				normalstr = "#{LZWZ_160223_100}",
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_1",
				DisableImage = "set:LongZhengWuZai14 image:LongZhengWuZai14_1",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_13",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_13",
				ClieckFlash = HD_LongZhengTenYears1_Flash37,
				}	--情满江湖龙火卡
	g_Cardlist[38] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item38, 
				Text =HD_LongZhengTenYears1_ItemInfo38, 
				enablestr = "#{LZWZ_160223_051}",
				disablestr = "#{LZWZ_160223_068}",
				eventstr = "#{LZWZ_160223_084}",
				normalstr = "#{LZWZ_160223_101}",
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_2",
				DisableImage = "set:LongZhengWuZai14 image:LongZhengWuZai14_2",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_14",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_14",
				ClieckFlash = HD_LongZhengTenYears1_Flash38,
				}	--纵情四海龙火卡
	g_Cardlist[39] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item39, 
				Text =HD_LongZhengTenYears1_ItemInfo39, 
				enablestr = "#{LZWZ_160223_052}",
				disablestr = "#{LZWZ_160223_069}",
				eventstr = "#{LZWZ_160223_085}",
				normalstr = "#{LZWZ_160223_102}",
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_3",
				DisableImage = "set:LongZhengWuZai14 image:LongZhengWuZai14_3",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_15",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_15",
				ClieckFlash = HD_LongZhengTenYears1_Flash39,
				}	--君临天下龙火卡
	g_Cardlist[40] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item40, 
				Text =HD_LongZhengTenYears1_ItemInfo40, 
				enablestr = "#{LZWZ_160223_053}",
				disablestr = "#{LZWZ_160223_070}",
				eventstr = "#{LZWZ_160223_086}",   --后补的
				normalstr = "#{LZWZ_160223_103}",
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_4",
				DisableImage = "set:LongZhengWuZai14 image:LongZhengWuZai14_4",
				NomalIcon = "set:LongZhengWuZai_Icon4 image:LongZhengWuZai_Icon4_16",
				DisableIcon = "set:LongZhengWuZai_Icon5 image:LongZhengWuZai_Icon5_16",
				ClieckFlash = HD_LongZhengTenYears1_Flash40,
				}	--犒赏群雄龙火卡
				
	g_Cardlist[41] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item41, 
				Text =HD_LongZhengTenYears1_ItemInfo41, 
				enablestr = "#{LZWZ_170213_142}",
				disablestr = "#{LZWZ_170213_142}",
				eventstr = "#{LZWZ_170213_146}",   --后补的
				normalstr = "#{LZWZ_170213_142}",
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_5",
				DisableImage = "set:LongZhengWuZai14 image:LongZhengWuZai14_5",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_1",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_1",
				ClieckFlash = HD_LongZhengTenYears1_Flash41,
				}	--袖里乾坤龙火卡
				
	g_Cardlist[42] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item42, 
				Text =HD_LongZhengTenYears1_ItemInfo42, 
				enablestr = "#{LZWZ_170213_143}",
				disablestr = "#{LZWZ_170213_143}",
				eventstr = "#{LZWZ_170213_147}",   --后补的
				normalstr = "#{LZWZ_170213_143}",
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_6",
				DisableImage = "set:LongZhengWuZai14 image:LongZhengWuZai14_6",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_2",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_2",
				ClieckFlash = HD_LongZhengTenYears1_Flash42,
				}	--群雄逐鹿龙火卡
				
	g_Cardlist[43] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item43, 
				Text =HD_LongZhengTenYears1_ItemInfo43, 
				enablestr = "#{LZWZ_170213_144}",
				disablestr = "#{LZWZ_170213_144}",
				eventstr = "#{LZWZ_170213_148}",   --后补的
				normalstr = "#{LZWZ_170213_144}",
				NomalImage = "set:LongZhengWuZai15 image:LongZhengWuZai15_1",
				DisableImage = "set:LongZhengWuZai16 image:LongZhengWuZai16_1",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_3",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_3",
				ClieckFlash = HD_LongZhengTenYears1_Flash43,
				}	--鬼谷奇谋龙火卡
				
	g_Cardlist[44] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item44, 
				Text =HD_LongZhengTenYears1_ItemInfo44, 
				enablestr = "#{LZWZ_170213_145}",	-- 废弃
				disablestr = "#{LZWZ_170213_145}",	-- 废弃
				eventstr = "#{LZWZ_170213_149}",   	-- 后补的 左下角的版本文字说明
				normalstr = "#{LZWZ_170213_145}",	-- 正常版本名称文字显示
				NomalImage = "set:LongZhengWuZai15 image:LongZhengWuZai15_2",
				DisableImage = "set:LongZhengWuZai16 image:LongZhengWuZai16_2",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_4",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_4",
				ClieckFlash = HD_LongZhengTenYears1_Flash44,
				}	--比武招亲龙火卡
end

--===============================================
-- OnEvent()
--===============================================
function HD_LongZhengTenYears1_OnEvent(event)

	if (event  == "UI_COMMAND") and (tonumber(arg0) == g_nUICommand) then
		--PushDebugMessage(arg0)
		HD_LongZhengTenYears1_Init()
		this:Show()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			
			--取消关心
			HD_LongZhengTenYears1_Cancel_Clicked()
		end
	elseif (event == "ADJEST_UI_POS") then
		HD_LongZhengTenYears1_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then	
		HD_LongZhengTenYears1_ResetPos()
	end
end
      
--===============================================
-- Close()
--===============================================
function HD_LongZhengTenYears1_Close()
	return this:Hide()
end

function HD_LongZhengTenYears1_ResetPos()
	HD_LongZhengTenYears1_Frame:SetProperty("UnifiedPosition",g_HD_LongZhengTenYears1_Frame_UnifiedPosition)
end

--===============================================
-- Init()
--===============================================
function HD_LongZhengTenYears1_Init()
	for i = 1, 44 do
		g_Cardlist[i].Button : SetProperty("Disabled", "False")
		g_Cardlist[i].Button : SetProperty("NormalImage", g_Cardlist[i].NomalIcon)
		g_Cardlist[i].Button : SetProperty("PushedImage", g_Cardlist[i].NomalIcon)
		g_Cardlist[i].Button : SetProperty("HoverImage", g_Cardlist[i].NomalIcon)
		g_Cardlist[i].Text   : SetText(g_Cardlist[i].normalstr)
		g_Cardlist[i].active = 1
		g_Cardlist[i].ClieckFlash:Hide()
	end
	HD_LongZhengTenYears1_Clicked(1)  --默认按第一个
end

--===============================================
-- Clicked()
--===============================================
function HD_LongZhengTenYears1_Clicked(ButtonID)
	--PushDebugMessage(ButtonID)
	HD_LongZhengTenYears1_Text : SetText(g_Cardlist[ButtonID].eventstr)
	HD_LongZhengTenYears1_Image : SetProperty("Image", g_Cardlist[ButtonID].NomalImage)	--已经激活的

	for i = 1,44 do
		if i == ButtonID then
			g_Cardlist[i].ClieckFlash:Show()
		else
			g_Cardlist[i].ClieckFlash:Hide()
		end
	end
end

function HD_LongZhengTenYears1_Cancel_Clicked()
	HD_LongZhengTenYears1_Close();
	return;
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_HD_LongZhengTenYears1(objCaredId)
	
	this:CareObject(objCaredId, 0, "HD_LongZhengTenYears1");
	g_Object = -1;

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_HD_LongZhengTenYears1(objCaredId)
	
	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "HD_LongZhengTenYears1");

end

