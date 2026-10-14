-------------------------------------------------------
-- 龙征十载龙火图册界面 by lishilong 2017-2-17
-- !!!reloadscript =HD_LongZhengTenYears
-------------------------------------------------------

local g_bDebug 					= 0
local MAX_OBJ_DISTANCE	 		= 3.0
local g_nObjCaredID 			= -1
local g_nUICommand				= 920170215

local g_Max_CardNumYear			= 7				-- 每年最大的火龙卡数量
local g_Max_ActCount			= 5				-- 每天最大的激活次数
local g_Max_PageNum				= 13			-- 龙火卡图册页数1-13
local g_Max_CardShowNum			= 4				-- 界面龙火卡最大显示数量 4
local g_Cardlist 				= {}			-- 龙火显示配置
local g_tabNumPerPage 	= 						-- 龙火卡图册里每年的卡片数量
{
	-- 2007 龙峥图天卷
	[1] 	= {nFirstVersion = 1, 		nCardType = 1,	nActCardNum = 0, nMaxNum = 3, strCardName = "#{LZWZ_180313_211}", },
	[2] 	= {nFirstVersion = 4, 		nCardType = 1,	nActCardNum = 0, nMaxNum = 7, strCardName = "#{LZWZ_180313_211}", },	
	[3] 	= {nFirstVersion = 11, 		nCardType = 1,	nActCardNum = 0, nMaxNum = 4, strCardName = "#{LZWZ_180313_211}", },
	[4] 	= {nFirstVersion = 15, 		nCardType = 1,	nActCardNum = 0, nMaxNum = 5, strCardName = "#{LZWZ_180313_211}", },
	-- 2011 龙峥图地卷
	[5] 	= {nFirstVersion = 20, 		nCardType = 2,	nActCardNum = 0, nMaxNum = 4, strCardName = "#{LZWZ_180313_212}", },
	[6] 	= {nFirstVersion = 24, 		nCardType = 2,	nActCardNum = 0, nMaxNum = 5, strCardName = "#{LZWZ_180313_212}", },
	[7] 	= {nFirstVersion = 29, 		nCardType = 2,	nActCardNum = 0, nMaxNum = 4, strCardName = "#{LZWZ_180313_212}", },
	[8] 	= {nFirstVersion = 33, 		nCardType = 2,	nActCardNum = 0, nMaxNum = 3, strCardName = "#{LZWZ_180313_212}", },
	-- 2015 龙峥图人卷
	[9] 	= {nFirstVersion = 36, 		nCardType = 3,	nActCardNum = 0, nMaxNum = 4, strCardName = "#{LZWZ_180313_213}", },
	[10] 	= {nFirstVersion = 40,		nCardType = 3,	nActCardNum = 0, nMaxNum = 5, strCardName = "#{LZWZ_180313_213}", },	
	[11] 	= {nFirstVersion = 45,		nCardType = 3,	nActCardNum = 0, nMaxNum = 4, strCardName = "#{LZWZ_180313_213}", },
	[12] 	= {nFirstVersion = 49,		nCardType = 3,	nActCardNum = 0, nMaxNum = 4, strCardName = "#{LZWZ_180313_213}", },
	-- 2019 龙征图日卷
	[13] 	= {nFirstVersion = 53,		nCardType = 4,	nActCardNum = 0, nMaxNum = 3, strCardName = "#{LZWZ_180313_229}", },
}

-- 龙征图名字
local g_tabScrollName 		= {"#{LZWZ_180313_211}", "#{LZWZ_180313_212}", "#{LZWZ_180313_213}", "#{LZWZ_180313_229}"}
-- 龙征图拥有的字典描述
local g_tabScrollHaveMsg 	= {"#{LZWZ_180313_218}", "#{LZWZ_180313_219}", "#{LZWZ_180313_220}", "#{LZWZ_180313_230}"}
-- 龙征图图片
local g_tabScrollImage		= {}

-- 龙征图点数
local g_tabScrollPoint 		= {0, 0, 0, 0}

-- 控件
local g_tabPageButton 			= {}			-- 年份分页的按钮
local g_tabVersionShowControl 	= {}			-- 资料片图片显示控件
local g_tabVersionShowMark 		= {}			-- 资料片图片Mark显示控件
-- local g_tabTextScrollPoint		= {}			-- 显示龙征图点数的控件

-- 逻辑参数
local g_nCurPage				= 1		-- 当前打开分页
local g_nVersionShowIndex		= 1		-- 本页第一个展示资料片的序号 从1开始
local g_nTargetId				= -1	-- 服务器传过来的targetId
--local g_nMDData					= -1	-- 服务器传过来的MD_10TH_ANNIVERSARY_DATA
--local g_nMDDay					= -1	-- 服务器传过来的MD_10TH_ANNIVERSARY_DAY
	
function HD_LongZhengTenYears_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false) 
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function HD_LongZhengTenYears_OnLoad()
	-- 显示龙征图点数的控件
	-- g_tabTextScrollPoint[1] = HD_LongZhengTenYears_Text2
	-- g_tabTextScrollPoint[2] = HD_LongZhengTenYears_Text3
	-- g_tabTextScrollPoint[3] = HD_LongZhengTenYears_Text4

	-- 龙征图图片
	g_tabScrollImage[1] =	HD_LongZhengTenYears_Text2Image
	g_tabScrollImage[2] =	HD_LongZhengTenYears_Text3Image
	g_tabScrollImage[3] =	HD_LongZhengTenYears_Text4Image
	g_tabScrollImage[4] =	HD_LongZhengTenYears_Text5Image

	-- 分页切换按钮
	g_tabPageButton[1] = HD_LongZhengTenYears_Button1
	g_tabPageButton[2] = HD_LongZhengTenYears_Button2
	g_tabPageButton[3] = HD_LongZhengTenYears_Button3
	g_tabPageButton[4] = HD_LongZhengTenYears_Button4
	g_tabPageButton[5] = HD_LongZhengTenYears_Button5
	g_tabPageButton[6] = HD_LongZhengTenYears_Button6
	g_tabPageButton[7] = HD_LongZhengTenYears_Button7
	g_tabPageButton[8] = HD_LongZhengTenYears_Button8
	g_tabPageButton[9] = HD_LongZhengTenYears_Button9
	g_tabPageButton[10] = HD_LongZhengTenYears_Button10
	g_tabPageButton[11] = HD_LongZhengTenYears_Button11
	g_tabPageButton[12] = HD_LongZhengTenYears_Button12
	g_tabPageButton[13] = HD_LongZhengTenYears_Button13
	
	-- 资料片图片显示控件
	g_tabVersionShowControl[1] = HD_LongZhengTenYears_Card_1
	g_tabVersionShowControl[2] = HD_LongZhengTenYears_Card_2
	g_tabVersionShowControl[3] = HD_LongZhengTenYears_Card_3
	g_tabVersionShowControl[4] = HD_LongZhengTenYears_Card_4
	
	-- 资料片图片Mark显示控件
	g_tabVersionShowMark[1] = HD_LongZhengTenYears_Card_1_Mark
	g_tabVersionShowMark[2] = HD_LongZhengTenYears_Card_2_Mark
	g_tabVersionShowMark[3] = HD_LongZhengTenYears_Card_3_Mark
	g_tabVersionShowMark[4] = HD_LongZhengTenYears_Card_4_Mark
	
	-- 初始化龙火卡显示配置
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
	g_Cardlist[45] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item45, 
				Text =HD_LongZhengTenYears1_ItemInfo45, 
				enablestr = "#{LZWZ_180313_166}",	-- 废弃
				disablestr = "#{LZWZ_180313_166}",	-- 废弃
				eventstr = "#{LZWZ_180313_170}",   	-- 后补的 左下角的版本文字说明
				normalstr = "#{LZWZ_180313_166}",	-- 正常版本名称文字显示
				NomalImage = "set:LongZhengWuZai17 image:LongZhengWuZai17_1",
				DisableImage = "set:LongZhengWuZai16 image:LongZhengWuZai16_3",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_5",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_5",
				ClieckFlash = HD_LongZhengTenYears1_Flash45,
				}	--十周年版龙火卡
	g_Cardlist[46] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item46, 
				Text =HD_LongZhengTenYears1_ItemInfo46, 
				enablestr = "#{LZWZ_180313_167}",	-- 废弃
				disablestr = "#{LZWZ_180313_167}",	-- 废弃
				eventstr = "#{LZWZ_180313_171}",   	-- 后补的 左下角的版本文字说明
				normalstr = "#{LZWZ_180313_167}",	-- 正常版本名称文字显示
				NomalImage = "set:LongZhengWuZai17 image:LongZhengWuZai17_2",
				DisableImage = "set:LongZhengWuZai16 image:LongZhengWuZai16_4",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_6",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_6",
				ClieckFlash = HD_LongZhengTenYears1_Flash46,
				}	--盛夏狂欢龙火卡
	g_Cardlist[47] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item47, 
				Text =HD_LongZhengTenYears1_ItemInfo47, 
				enablestr = "#{LZWZ_180313_168}",	-- 废弃
				disablestr = "#{LZWZ_180313_168}",	-- 废弃
				eventstr = "#{LZWZ_180313_172}",   	-- 后补的 左下角的版本文字说明
				normalstr = "#{LZWZ_180313_168}",	-- 正常版本名称文字显示
				NomalImage = "set:LongZhengWuZai17 image:LongZhengWuZai17_3",
				DisableImage = "set:LongZhengWuZai16 image:LongZhengWuZai16_5",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_7",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_7",
				ClieckFlash = HD_LongZhengTenYears1_Flash47,
				}	--武意纵横龙火卡
	g_Cardlist[48] = {
				active = 0,
				Button = HD_LongZhengTenYears1_Item48, 
				Text =HD_LongZhengTenYears1_ItemInfo48, 
				enablestr = "#{LZWZ_180313_169}",	-- 废弃
				disablestr = "#{LZWZ_180313_169}",	-- 废弃
				eventstr = "#{LZWZ_180313_173}",   	-- 后补的 左下角的版本文字说明
				normalstr = "#{LZWZ_180313_169}",	-- 正常版本名称文字显示
				NomalImage = "set:LongZhengWuZai17 image:LongZhengWuZai17_4",
				DisableImage = "set:LongZhengWuZai16 image:LongZhengWuZai16_6",
				NomalIcon = "set:LongZhengWuZai_Icon6 image:LongZhengWuZai_Icon6_8",
				DisableIcon = "set:LongZhengWuZai_Icon7 image:LongZhengWuZai_Icon7_8",
				ClieckFlash = HD_LongZhengTenYears1_Flash48,
				}	--武林萌主龙火卡
	
	-- set:LongZhengWuZai15 image:LongZhengWuZai15_3   Q1亮
	-- set:LongZhengWuZai15 image:LongZhengWuZai15_4   Q2亮
	-- set:LongZhengWuZai15 image:LongZhengWuZai15_5   Q3亮
	-- set:LongZhengWuZai15 image:LongZhengWuZai15_6   Q4亮
	-- set:LongZhengWuZai18 image:LongZhengWuZai18_1   Q1灰
	-- set:LongZhengWuZai18 image:LongZhengWuZai18_2   Q2灰
	-- set:LongZhengWuZai18 image:LongZhengWuZai18_3   Q3灰
	-- set:LongZhengWuZai18 image:LongZhengWuZai18_4   Q4灰
	g_Cardlist[49] = {

				NomalImage = "set:LongZhengWuZai15 image:LongZhengWuZai15_3",
				DisableImage = "set:LongZhengWuZai18 image:LongZhengWuZai18_1",

				}	--金戌迎瑞
	g_Cardlist[50] = {

				NomalImage = "set:LongZhengWuZai15 image:LongZhengWuZai15_4",
				DisableImage = "set:LongZhengWuZai18 image:LongZhengWuZai18_2",

				}	--侠路相逢		
	g_Cardlist[51] = {

				NomalImage = "set:LongZhengWuZai15 image:LongZhengWuZai15_5",
				DisableImage = "set:LongZhengWuZai18 image:LongZhengWuZai18_3",

				}	--世外桃源	
	g_Cardlist[52] = {

				NomalImage = "set:LongZhengWuZai15 image:LongZhengWuZai15_6",
				DisableImage = "set:LongZhengWuZai18 image:LongZhengWuZai18_4",

				}	--师门逆徒			

	-- 点亮的有
	-- LongZhengWuZai19_1 桃花岛
	-- LongZhengWuZai17_5 绿肥红瘦
	-- LongZhengWuZai17_6 十二周年

	-- LongZhengWuZai18_5 绿肥红烧
	-- LongZhengWuZai18_6 十二周年
	-- LongZhengWuZai20_1 桃花岛

	g_Cardlist[53] = {

				NomalImage = "set:LongZhengWuZai17 image:LongZhengWuZai17_6",
				DisableImage = "set:LongZhengWuZai18 image:LongZhengWuZai18_6",

				}	--十二周年		
	g_Cardlist[54] = {

				NomalImage = "set:LongZhengWuZai17 image:LongZhengWuZai17_5",
				DisableImage = "set:LongZhengWuZai18 image:LongZhengWuZai18_5",

				}	--绿肥红瘦	
	g_Cardlist[55] = {

				NomalImage = "set:LongZhengWuZai19 image:LongZhengWuZai19_1",
				DisableImage = "set:LongZhengWuZai20 image:LongZhengWuZai20_1",

				}	--桃花影落飞神剑	
end

function HD_LongZhengTenYears_OnEvent(event)
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_Update")
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommand ) then
		
		-- 参数 0 操作类型 1 targetId 2 MD_10TH_ANNIVERSARY_DATA 3 MD_10TH_ANNIVERSARY_DAY
		-- 操作类型，0关闭界面，1打开界面，2刷新界面
		local bOpType = Get_XParam_INT(0)
		if nil == bOpType then
			return
		end
		
		-- 关闭界面
		if 0 == bOpType then
			if this:IsVisible() then
				HD_LongZhengTenYears_Close()
			end
			return
		end
				
		-- 刷新界面
		if 2 == bOpType then
			if this:IsVisible() then
				-- 获取参数
				HD_LongZhengTenYears_Init()
				-- 刷新界面
				HD_LongZhengTenYears_Update(1)
			end

			return
		end
		
		-- 打开界面
		-- 重置更新数据
		HD_LongZhengTenYears_Reset()
		-- 获取参数
		g_nTargetId 	= Get_XParam_INT(1)
		HD_LongZhengTenYears_Init()
		
		local ObjCaredID = DataPool : GetNPCIDByServerID( g_nTargetId )
		-- 关注npc
		if nil == ObjCaredID or -1 == ObjCaredID then
			--PushDebugMessage("server传过来的数据有问题。")
			return
		end
		
		g_nObjCaredID = ObjCaredID
		BeginCareObject_HD_LongZhengTenYears()
		
		-- 刷新界面
		HD_LongZhengTenYears_Update(1)
		-- 显示界面
		this:Show()

	elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= g_nObjCaredID) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
			--关闭界面
			HD_LongZhengTenYears_Close()
		end	
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		--关闭界面
		HD_LongZhengTenYears_Close()
	end
end

--=========================================================
-- 初始化服务器传过来的激活数据
--=========================================================
function HD_LongZhengTenYears_Init()
	for i = 1, table.getn(g_tabScrollPoint) do
		g_tabScrollPoint[i]= Get_XParam_INT(i + 1)
	end	

	-- 需要读取的参数个数
	local nForMaxNum =  math.ceil(table.getn(g_tabNumPerPage) / 4)

	-- PushDebugMessage("nForMaxNum"..nForMaxNum)

	for i = 1, nForMaxNum do
		-- 参数合并过了，每个INT包含4个参数，从个位开始取
		local nParamIndex = table.getn(g_tabScrollPoint) + i + 1
		local nParamValue = Get_XParam_INT(nParamIndex)
		-- PushDebugMessage("nParamValue"..nParamValue..",nParamIndex"..nParamIndex)
		for j = 1, 4 do
			local nPageIndex = (i - 1) * 4 + j
			if nPageIndex > table.getn(g_tabNumPerPage) then
				return
			end	
			g_tabNumPerPage[nPageIndex].nActCardNum = math.mod(nParamValue, 10)	
			nParamValue = math.floor(nParamValue/10)
		end
	end

	-- PushDebugMessage("g_tabScrollPoint"..g_tabScrollPoint[1]..","..g_tabScrollPoint[2]..","..g_tabScrollPoint[3])
	-- PushDebugMessage("g_tabNumPerPage"..g_tabNumPerPage[1].nActCardNum..","..g_tabNumPerPage[2].nActCardNum..","..g_tabNumPerPage[3].nActCardNum..","..g_tabNumPerPage[4].nActCardNum..","..g_tabNumPerPage[5].nActCardNum..","..g_tabNumPerPage[6].nActCardNum)
	-- PushDebugMessage("g_tabNumPerPage"..g_tabNumPerPage[7].nActCardNum..","..g_tabNumPerPage[8].nActCardNum..","..g_tabNumPerPage[9].nActCardNum..","..g_tabNumPerPage[10].nActCardNum..","..g_tabNumPerPage[11].nActCardNum..","..g_tabNumPerPage[12].nActCardNum)	
end

--=========================================================
-- 更新界面 nTypeAuto 0 为不自动翻页 1为自动翻页
--=========================================================
function HD_LongZhengTenYears_Update(nTypeAuto)
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_Update")
	--local strDebugMsg = "g_nMDData:".. tostring(g_nMDData).."g_nMDDay"..tostring(g_nMDDay)
	--HD_LongZhengTenYears1_Debug(strDebugMsg)
	
	-- 全局变量参数合法性判断
	if g_nCurPage <= 0 or g_nCurPage > g_Max_PageNum then
		return
	end
	if g_nVersionShowIndex <= 0 or g_nVersionShowIndex > g_tabNumPerPage[g_nCurPage].nMaxNum then
		return
	end
	
	-- 设置页面选中点亮
	for i = 1, g_Max_PageNum do
		if i == g_nCurPage then
			g_tabPageButton[i] : SetProperty("Selected", "True")
		else
			g_tabPageButton[i] : SetProperty("Selected", "False")
		end
	end
	
	-- 设置说明文字1 介绍
	-- nCostItemID = g_tabNumPerPage[g_nCurPage].nPicID
	-- nCostItemIDNew = g_tabNumPerPage[g_nCurPage].nPicID2018
	-- local strItemName = PlayerPackage:GetItemName(nCostItemID)
	-- local strItemNameNew = PlayerPackage:GetItemName(nCostItemIDNew)
	strScrollName = g_tabNumPerPage[g_nCurPage].strCardName
	local strMsg = ScriptGlobal_Format("#{LZWZ_170210_120}", strScrollName)
	HD_LongZhengTenYears_Explain : SetText(strMsg)
	
	-- 设置说明文字2 LZWZ_170210_134	#cfff263当前年份共#G%s0#cfff263张龙火卡，已激活#G%s1#cfff263张。
	local nMaxNumCurYear = g_tabNumPerPage[g_nCurPage].nMaxNum
	local nActNumCurYear =  g_tabNumPerPage[g_nCurPage].nActCardNum
	if nActNumCurYear < 0 then
		nActNumCurYear = 0
	end
	if nActNumCurYear > nMaxNumCurYear then
		nActNumCurYear = nMaxNumCurYear
	end
	strMsg = ScriptGlobal_Format("#{LZWZ_170210_134}", nMaxNumCurYear, nActNumCurYear)
	if 0 == nActNumCurYear then
		strMsg = ScriptGlobal_Format("#{LZWZ_170324_159}", nMaxNumCurYear, nActNumCurYear)
	end
	HD_LongZhengTenYears_Text1 : SetText(strMsg)
	
	-- 设置说明文字3 拥有的龙火卡点数
	local nCardType = g_tabNumPerPage[g_nCurPage].nCardType
	local strMsgPoint = ScriptGlobal_Format("#{LZWZ_180313_221}", g_tabScrollPoint[nCardType])
	if 0 == g_tabScrollPoint[nCardType] then
		strMsgPoint = ScriptGlobal_Format("#{LZWZ_180313_222}", g_tabScrollPoint[nCardType])
	end

	-- 描述
	HD_LongZhengTenYears_Text2 		: SetText(g_tabScrollHaveMsg[nCardType])
	-- 数量 
	HD_LongZhengTenYears_Text2_1 	: SetText(strMsgPoint)
	-- 图片
	g_tabScrollImage[1]				: Hide()
	g_tabScrollImage[2]				: Hide()
	g_tabScrollImage[3]				: Hide()
	g_tabScrollImage[4]				: Hide()
	g_tabScrollImage[nCardType]		: Show()

	-- local nHaveNum = PlayerPackage:CountAvailableItemByIDTable(nCostItemID) + PlayerPackage:CountAvailableItemByIDTable(nCostItemIDNew)
	-- strMsg = ScriptGlobal_Format("#{LZWZ_170213_137}", strItemNameNew, nHaveNum)
	-- if 0 == nHaveNum then
	-- 	strMsg = ScriptGlobal_Format("#{LZWZ_170324_160}", strItemNameNew, nHaveNum)
	-- end
	-- HD_LongZhengTenYears_Text2 : SetText(strMsg)

	-- for i = 1, table.getn(g_tabTextScrollPoint) do

	-- 	strMsg = ScriptGlobal_Format("#{LZWZ_170213_137}", g_tabScrollName[i], g_tabScrollPoint[i])
	-- 	if 0 == g_tabScrollPoint[i] then
	-- 		strMsg = ScriptGlobal_Format("#{LZWZ_170324_160}", g_tabScrollName[i], g_tabScrollPoint[i])
	-- 	end

	-- 	g_tabTextScrollPoint[i] : SetText(strMsg)
	-- end
	
	local tabShow 		= {}
	local tabShowAct 	= {}
	
	-- 根据是否激活重新排序显示顺序
	-- for i = 1, g_tabNumPerPage[g_nCurPage].nMaxNum do
		-- if i + nActNumCurYear > g_tabNumPerPage[g_nCurPage].nMaxNum then
			-- tabShow[i] = i + nActNumCurYear - g_tabNumPerPage[g_nCurPage].nMaxNum
			-- tabShowAct[i] = 1
		-- else
			-- tabShow[i] = i + nActNumCurYear
			-- tabShowAct[i] = 0
		-- end
	-- end
	
	-- 不调整显示顺序
	for i = 1, nMaxNumCurYear do
		if i <= nActNumCurYear then
				tabShow[i] = i
				tabShowAct[i] = 1
		else
				tabShow[i] = i
				tabShowAct[i] = 0
		end
	end
	
	-- 显示图片
	for i = 1, g_Max_CardShowNum do
		-- 获取显示的资料片index
		local nBeginVersionCurYear = g_tabNumPerPage[g_nCurPage].nFirstVersion
		local nEndVersionCurYear = g_tabNumPerPage[g_nCurPage].nFirstVersion + nMaxNumCurYear - 1
		
		if i > g_tabNumPerPage[g_nCurPage].nMaxNum then
			-- 显示卡背 当前逻辑下只有两年(1,8)会显示出卡背，暂时先强写吧
			if 1 == g_nCurPage then
				g_tabVersionShowControl[i] : SetProperty("Image", "set:LongZhengWuZai0 image:LongZhengWuZai0_1")	-- 2007年
			else
				g_tabVersionShowControl[i] : SetProperty("Image", "set:LongZhengWuZai0 image:LongZhengWuZai0_6")	-- 其他年份，目前只有2014年
			end
			g_tabVersionShowControl[i] : SetToolTip("")
			g_tabVersionShowMark[i] : Hide()
		else
			-- 显示卡片
			-- 该资料片的总序号
			local nShowIndex = g_nVersionShowIndex -1 + i
			local nTotalVersionIndex = nBeginVersionCurYear + tabShow[nShowIndex] - 1
			local strImageEnable 	= g_Cardlist[nTotalVersionIndex].NomalImage
			local strImageDisable 	= g_Cardlist[nTotalVersionIndex].DisableImage
						
			if 0 ==  tabShowAct[nShowIndex] then
				-- 未激活
				g_tabVersionShowControl[i] : SetProperty("Image", strImageDisable)
				local strToolTips = "" -- ScriptGlobal_Format("#{LZWZ_170210_118}", strItemName)
				g_tabVersionShowControl[i] : SetToolTip(strToolTips)
				g_tabVersionShowMark[i] : Show()
			else
				-- 激活
				g_tabVersionShowControl[i] : SetProperty("Image", strImageEnable)
				g_tabVersionShowControl[i] : SetToolTip("")--("#{LZWZ_170210_119}")
				g_tabVersionShowMark[i] : Hide()
			end
		end	
	end
	
	-- 显示左拖动按钮
	if g_nVersionShowIndex <= 1 then
		HD_LongZhengTenYears_LeftPass : Disable()
		HD_LongZhengTenYears_LeftPass : SetToolTip("")
	else
		HD_LongZhengTenYears_LeftPass : Enable()
		HD_LongZhengTenYears_LeftPass : SetToolTip("#{LZWZ_170210_135}")
	end
	
	-- 显示右拖动按钮
	if g_nVersionShowIndex + g_Max_CardShowNum -1 >= g_tabNumPerPage[g_nCurPage].nMaxNum then
		HD_LongZhengTenYears_RightPass : Disable()
		HD_LongZhengTenYears_RightPass : SetToolTip("")
	else
		HD_LongZhengTenYears_RightPass : Enable()
		HD_LongZhengTenYears_RightPass : SetToolTip("#{LZWZ_170210_136}")
	end
	
	-- 自动换页逻辑
	if nMaxNumCurYear > 4 and nActNumCurYear >= 4 and 1 == g_nVersionShowIndex and 1 == nTypeAuto then
		HD_LongZhengTenYears_DoRightPass()
	end
	
	if nActNumCurYear < 4 and 1 ~= g_nVersionShowIndex and 1 == nTypeAuto then
		HD_LongZhengTenYears_DoLeftPass()
	end
end

--=========================================================
-- 左拖动
--=========================================================
function HD_LongZhengTenYears_DoLeftPass()
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_LeftPass")
	g_nVersionShowIndex = 1
	
	HD_LongZhengTenYears_Update(0)
end

--=========================================================
-- 右拖动
--=========================================================
function HD_LongZhengTenYears_DoRightPass()
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_RightPass")
	if g_tabNumPerPage[g_nCurPage].nMaxNum <= g_Max_CardShowNum then
		g_nVersionShowIndex = 1
	else
		g_nVersionShowIndex = g_tabNumPerPage[g_nCurPage].nMaxNum - g_Max_CardShowNum + 1
	end
	HD_LongZhengTenYears_Update(0)
end

--=========================================================
-- 切换年份
--=========================================================
function HD_LongZhengTenYears_ChangeYear(nPage)
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_ChangeYear")
	if nPage <= 0 or nPage > g_Max_PageNum then
		return
	end
	g_nCurPage = nPage
	g_nVersionShowIndex = 1
	HD_LongZhengTenYears_Update(1)
end

--=========================================================
-- 装帧
--=========================================================
function HD_LongZhengTenYears_OnActivate()
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_OnActivate")
	
	-- 调用服务器脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnActivate" )
		Set_XSCRIPT_ScriptID( 892423 )
		Set_XSCRIPT_Parameter( 0, g_nTargetId )
		Set_XSCRIPT_Parameter( 1, g_nCurPage )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end

--=========================================================
-- 重置数据
--=========================================================
function HD_LongZhengTenYears_Reset()
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_Reset")
	
	g_nCurPage				= 1		-- 当前打开分页
	g_nVersionShowIndex		= 1		-- 本页第一个展示资料片的序号
	g_nTargetId				= -1	-- 服务器传过来的targetId
	--g_nMDData				= -1	-- 服务器传过来的MD_10TH_ANNIVERSARY_DATA
	--g_nMDDay				= -1	-- 服务器传过来的MD_10TH_ANNIVERSARY_DAY
	for i = 1, table.getn(g_tabNumPerPage) do
		g_tabNumPerPage[i].nActCardNum = 0
	end

	for i = 1, table.getn(g_tabScrollPoint) do
		g_tabScrollPoint[i] = 0
	end
	
	HD_LongZhengTenYears_LeftPass : Disable()
	HD_LongZhengTenYears_RightPass : Disable()
end

--=========================================================
-- 获取某年的激活卡片数量
--=========================================================
-- function HD_LongZhengTenYears_GetActCardNum( nPage )
	-- if nPage <= 0 or nPage > g_Max_PageNum or -1 == g_nMDData then
		-- return 0, 0
	-- end
	
	-- local arrCardNum = {}
	-- local nTotalNum = 0
	-- local nValue = g_nMDData
	-- for i = 1, 10 do
		-- arrCardNum[i] = math.mod(nValue, 8)
		-- nValue = math.floor(nValue / 8)
		-- nTotalNum = arrCardNum[i] + nTotalNum
	-- end
	
	-- return arrCardNum[nPage], nTotalNum
-- end

--=========================================================
-- 获取今天的激活次数
--=========================================================
-- function HD_LongZhengTenYears_GetActCountToday()
	-- if -1 == g_nMDDay then
		-- return g_Max_ActCount
	-- end
	-- local nLastDay 	= math.floor(g_nMDDay / 10)
	-- local nCount 	= math.mod(g_nMDDay, 10)
	-- local curDay 	= GetTime2Day()
	-- if curDay > nLastDay then
		-- nCount = 0
	-- end
	-- return nCount
-- end

--=========================================================
-- 点击关闭界面
--=========================================================
function HD_LongZhengTenYears_Close_Click()
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_Close_Click")
	HD_LongZhengTenYears_Close()
end

--=========================================================
--关闭
--=========================================================
function HD_LongZhengTenYears_Close()
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_Close")
	this : Hide()
	StopCareObject_HD_LongZhengTenYears()
	HD_LongZhengTenYears_Reset()
end

--=========================================================
--界面隐藏
--=========================================================
function HD_LongZhengTenYears_OnHiden()
	HD_LongZhengTenYears1_Debug("HD_LongZhengTenYears_OnHiden")
	StopCareObject_HD_LongZhengTenYears()
	HD_LongZhengTenYears_Reset()
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_HD_LongZhengTenYears()
	HD_LongZhengTenYears1_Debug("BeginCareObject_HD_LongZhengTenYears")
	this : CareObject( g_nObjCaredID, 1, "HD_LongZhengTenYears" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_HD_LongZhengTenYears()
	HD_LongZhengTenYears1_Debug("StopCareObject_HD_LongZhengTenYears")
	this : CareObject( g_nObjCaredID, 0, "HD_LongZhengTenYears" )
end

--=========================================================
-- 调试信息
--=========================================================
function HD_LongZhengTenYears1_Debug(strMsg)
	if 1 == g_bDebug then
		PushDebugMessage(strMsg)
	end
end

function HD_LongZhengTenYears1_Debug2(strMsg)
	if 2 == g_bDebug then
		PushDebugMessage(strMsg)
	end
end



