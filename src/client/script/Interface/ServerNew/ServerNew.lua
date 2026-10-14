--===============================================
--local满了不能再加了

local g_ServerNew_Frame_UnifiedPosition;

local g_ServerNew_Event = {
	[1] = {text="#{XFHD_140919_04}", eventName="ServerNew_test1", isShow=0,},
	[2] = {text="#{XFHD_140919_05}", eventName="ServerNew_test2", isShow=0,},
	[3] = {text="#{XFHD_140919_07}", eventName="ServerNew_test3", isShow=0,}, --重楼献英豪
	[4] = {text="#{XFHD_140919_06}", eventName="ServerNew_test4", isShow=0,}, --豪情大派送
	[5] = {text="#{XFHD_140919_08}", eventName="ServerNew_test5", isShow=0,},
	[6] = {text="#{XFHD_140919_09}", eventName="ServerNew_test6", isShow=0,},
	[7] = {text="#{XFHD_140919_10}", eventName="ServerNew_test7", isShow=0,},
	[8] = {text="#{XFHD_140919_11}", eventName="ServerNew_test8", isShow=0,},
	[9] = {text="#{XFLSJ_160823_1}", eventName="ServerNew_test9", isShow=0,}, --新服乐事记
	[10] = {text="#{XFHD_140919_18}", eventName="ServerNew_test10", isShow=0,}, --新服欢乐月
	[11] = {text="#{HQYZ_180115_11}", eventName="ServerNew_test11", isShow=0,}, --豪情一掷
	[12] = {text="#{YCZJJ_181130_8}", eventName="ServerNew_test12", isShow=0,}, --新春享返利
	[13] = {text="#{XFDG_230103_01}", eventName="", isShow=0,}, -- 新服Boss
	[14] = {text="#{XYCSD_230203_4}", eventName="", isShow=0,}, --2023Q1新服欢乐月-喜迎财神到
	[15] = {text="#{JYTM_20230302_12}", eventName="", isShow=0,}, -- 新服经验点Boss
};

local g_ServerNew_Button = {
}

--副本竞速排行榜
local g_CSRankInfo = {
	[1] = {usetime = "",
		   leadericon = "",
		   blank = "",
		   name = {"","","","","",""}
	},
	[2] = {usetime = "",
		   leadericon = "",
		   blank = "",
		   name = {"","","","","",""}
	},
	[3] = {usetime = "",
		   leadericon = "",
		   blank = "",
		   name = {"","","","","",""}
	},
	-- [4] = {usetime = "",
		   -- leadericon = "",
		   -- blank = "",
		   -- name = {"","","","","",""}
	-- },
	--[5] = {usetime = "",
	--	   leadericon = "",
	--	   blank = "",
	--	   name = {"","","","","",""}
	--},
}
local  g_CSRankBKFrame = {}

local g_ServerNew_Paihang_PH = 0;  --刷新排行榜冷却
local g_ServerNew_Paihang_Jifen =1083		--【新服消费排行榜活动积分MD】(与活动消费排行榜分开)
local g_ServerNew_Send_Haoqing =575		--【新服消费排行榜活动积分MD】(与活动消费排行榜分开)
local g_ServerNew_Send_Button = {};


---江湖第一begin

local g_ServerNew_FirstOne_L_Name = {}
local g_ServerNew_FirstOne_L_Level = {}
local g_ServerNew_FirstOne_L_Menpai = {}
local g_ServerNew_FirstOne_R_Name = {}
local g_ServerNew_FirstOne_R_Level = {}
--local g_ServerNew_FirstOne_R_Menpai = {}
local g_ServerNew_FirstOne_MenpaiID = 
{
	[1] = 0,	--少林
	[2] = 1,	--明教
	[3] = 2,	--丐帮
	[4] = 3,	--武当·
	[5] = 4,	--峨嵋
	[6] = 5,	--星宿
	[7] = 6,	--天龙
	[8] = 7,	--天山
	[9] = 8,	--逍遥
	[10] = 10,	--慕容	
	[11] = 11,	--唐门
	[12] = 12,	--唐门
	[13] = 13,	--桃花岛
	[14] = 14,	--从刃
	[15] = 15,	--恶人
}
---江湖第一end

--双倍乐翻天begin
local g_ServerNew_Double = 
{
	[1] = 0,
	[2] = 0,
}
--双倍乐翻天end

--【新服欢乐月·升级送好礼】Begin
local g_ServerNew_LevelUp_PageIndex = 1;		-- 界面显示是分页的,分页索引:0.初入江湖 1.仗剑江湖
local g_ServerNew_LevelUp_GetGiftLevel = {		-- 领奖等级限制
	[1] = 10,[2] = 20,[3] = 30,[4] = 35,[5] = 40,[6] = 45,[7] = 50,[8] = 55,[9] = 60,[10] = 70,[11] = 80,[12] = 90,[13] = 100,[14] = 130,
}
local g_ServerNew_LevelUpBtnState = {			-- 领取按钮的状态
	[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1, [9] = 1, [10] = 1, [11] = 1, [12] = 1, [13] = 1,
}
--界面上显示奖励物品的ICON表
local g_ServerNew_LevelUp_GiftsIcons = { }
--界面上显示奖励物品的ICON右上角的小图标
local g_ServerNew_LevelUp_GiftsIconsImages = { }

--是否是第一次加载【升级送好礼】界面
local g_ServerNew_LevelUp_LoadFirstTime = 1

--界面上的每档奖励展示框
local g_ServerNew_LevelUp_Frames = { }
--界面【领取奖励】按钮表
local g_ServerNew_LevelUp_GetGiftsButtonList = {}
--奖励物品配表
local g_ServerNew_LevelUp_Gifts = {
	[1] = 	{
			{GiftItemID = 30008080, num = 1,},{GiftItemID = 10124418, num = 1,}
		,},
	[2] =	{	
			{GiftItemID = 31000006, num = 1,},{GiftItemID = 30607003, num = 1,}
		,},
	[3] =   {
			{GiftItemID = 30008027, num = 1,},{GiftItemID = 20309018, num = 8,},{GiftItemID = 30505216, num = 1,new = 1,}
		,},
	[4] =   {
			{GiftItemID = 30008027, num = 1,},{GiftItemID = 20309018, num = 16,},{GiftItemID = 30503132, num = 2,new = 1,}
		,},
	[5] =   {
			{GiftItemID = 30008027, num = 2,},{GiftItemID = 30309985, num = 1,},{GiftItemID = 39920156, num = 2,new = 1,}
		,},
	[6] =   {
			{GiftItemID = 30008027, num = 1,},{GiftItemID = 30900124, num = 1,},{GiftItemID = 20309021, num = 12,},{GiftItemID = 39920483, num = 2, new = 1,}
		,},
	[7] =	{
			{GiftItemID = 30008027, num = 2,},{GiftItemID = 20309021, num = 24,},{GiftItemID = 20310168, num = 5,new = 1,},
	},
	[8] =	{
			{GiftItemID = 30008027 ,num = 2,},{GiftItemID = 20309022, num = 28,},{GiftItemID = 38000656, num = 2,new = 1,},
	},
	[9] =	{
			{GiftItemID = 30008027 ,num = 2, new = 1,},{GiftItemID = 39920484, num = 2, new = 1,},{GiftItemID = 30700249, num = 5, new = 1,},
	},
	[10] = {
			{GiftItemID = 30008027 ,num = 2, new = 1,},{GiftItemID = 30008130, num = 1, new = 1,},{GiftItemID = 38000831, num = 2, new = 1,},
	},
	[11] = {
			{GiftItemID = 30008027 ,num = 2, new = 1,},{GiftItemID = 30008130, num = 1, new = 1,},{GiftItemID = 38000380, num = 2, new = 1,},
	},
	[12] = {
			{GiftItemID = 30008027 ,num = 2, new = 1,},{GiftItemID = 30008130, num = 1, new = 1,},{GiftItemID = 39920485, num = 1, new = 1,},
	},
	[13] = {
			{GiftItemID = 30008027 ,num = 2, new = 1,},{GiftItemID = 30008130, num = 1, new = 1,},{GiftItemID = 39920486, num = 1, new = 1,},
	},
}
--【新服欢乐月·升级送好礼】End

--【新服欢乐月·首充超值增】Begin
local g_ServerNew_SaveUpBtnState = {			-- 领取按钮的状态
	[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = -3, 
}

--界面上显示奖励物品的ICON表
local g_ServerNew_SaveUp_GiftsIcons = { }
--界面上显示奖励物品的ICON右上角的小图标
local g_ServerNew_SaveUp_GiftsIconImages = { }

--界面是否是第一次加载,如果是的话,需要创建物品图标
local g_ServerNew_SaveUp_LoadFirstTime = 1

--界面【领取奖励】按钮表
local g_ServerNew_SaveUp_GetGiftsButtonList = {}
--奖励物品配表
local g_ServerNew_SaveUp_Gifts =
{
	[1] = 	{
			{GiftItemID = 10155006, num = 1,},{GiftItemID = 39920503, num = 3,},{GiftItemID = 30900077, num = 2, new = 1,}
		,},
	[2] =	{	
			{GiftItemID = 30008130, num = 2,}
		,},
	[3] =   {
			{GiftItemID = 30900077, num = 2,}
		,},
	[4] =   {
			{GiftItemID = 30900077, num = 3, new = 1,},{GiftItemID = 30008130, num = 2, new = 1,}
		,},
	[5] =   {
			{GiftItemID = 30900077, num = 4, new = 1,},{GiftItemID = 30008130, num = 2, new = 1,}
		,},
	[6] =   {
			{GiftItemID = 30008130, num = 2,}
		,},
}

local g_ServerNew_SaveUp_GetGiftsCondition = 
{
	[1] = { Exch = 200,},				--首充好礼
	[2] = { Exch = 2000, Cost = 2000, },
	[3] = { Exch = 4000, Cost = 4000, },
	[4] = { Exch = 12000, Cost = 12000, },
	[5] = { Exch = 20000, Cost = 20000, },
	[6] = { Exch = 4000, Cost = 4000, },		--限时好礼
}

local g_ServerNew_SaveUp_NotifyTipsControlList	= { }	--【首充超值赠】界面上显示达成条件的Text控件,策划要求按照完成情况显示成动态的=...=

--目前已经消费的元宝数
local g_ServerNew_SaveUp_YuanBaoCost = 0
--目前已经兑换的元宝数
local g_ServerNew_SaveUp_YuanBaoExch = 0
--【新服欢乐月·首充超值增】End

local g_ServerNew_Frames = 
{
}

local g_ServerNew_PrizeItemButtonIcon = "set:CommonFrame20 image:Item_New"

local g_ServerNew_FBRankPrizeIcon = {}
local g_ServerNew_FBRankPrizeItem ={
	[1] = 30008130,
	[2] = 30008121,
	[3] = 38001067,
	[4] = 30008127,
	[5] = 30008121,
	[6] = 30008027,
	[7] = 30505216,
}

local g_ButtonCDTime = 1; --按钮冷却时间
local g_ButtonLastTime = 0;
local g_LastClickedId = -1; --上次选中的选项
local g_EventIndex = -1 --当前选中的选项

--新服乐事记
local g_Broadcast_LastRefreshTime = 0		--上次刷新时间
local g_Broadcast_LastClickChannelTime = 0	--上次点击频道时间	
local g_Broadcast_CDTime = 2		--冷却时间
local g_Broadcast_CurChannel = 1; 	--当前选中的频道 1=结婚频道 2=结拜频道 3=师徒频道 4=帮派频道
local g_Broadcast_IsShouTu = 0 --频道3是否显示收徒领奖界面 
local g_Broadcast_RedPointPos = -1	--红点位置
local g_Broadcast_RedPoint = 0	--红点开关标记
-- local g_Broadcast_SwitchFlag = 0	--轮播开关
-- local g_Broadcast_SwitchIndex = 0	--轮播起始下标
local g_ServerNew_Broadcast_Gifts = {	--奖励物品配表
	--结婚
	[1] = 	{
			{GiftItemID = 39920913, num = 1,}
		,},
	--结拜
	[2] =	{	
			{GiftItemID = 39921106, num = 1,}
		,},
	--拜师
	[3] =   {
			{GiftItemID = 39920247, num = 1,}
		,},
	--加帮
	[4] =   {
			{GiftItemID = 39921126, num = 1,}
		,},
	--收徒
	[5] =   {
			{GiftItemID = 39921123, num = 1,}
		,},
}
local g_ServerNew_Broadcast_GiftTextInfo = {
	[1] = "#{XFLSJ_160823_7}",
	[2] = "#{XFLSJ_160823_19}",
	[3] = "#{XFLSJ_160823_28}",
	[4] = "#{XFLSJ_160823_57}",
	[5] = "#{XFLSJ_160823_64}",
}
local g_ServerNew_BroadcastBtnTip = {	
	[1] = "#{XFLSJ_160823_8}",
	[2] = "#{XFLSJ_160823_20}",
	[3] = "#{XFLSJ_160823_29}",
	[4] = "#{XFLSJ_160823_46}",
	[5] = "#{XFLSJ_160823_30}",
}
--新服乐事记界面
local g_ServerNew_Broadcast_ChannelButtonn ={}
local g_Broadcast_Content = {}	--广播内容列表控件
local g_ServerNew_Broadcast_GiftsIcons = {} --界面上显示奖励物品的ICON表
local g_ServerNew_BroadcastButton = {}	--界面奖励按钮表
local g_ServerNew_BroadcastBtnState = {			-- 领取按钮的状态
	[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, 
}
local g_Broadcast_RedPointButton = {}
local g_ServerNew_Broadcast_TextInfo = {}	--奖励文字控件
local g_ServerNew_Broadcast_ChannelFrame = {}

--豪情一掷满江湖 begin
local g_MD_HQYZ_DATA = 1517
local g_HQYZ_RedPoint = 0	--红点开关标记
local g_HQYZ_RedPointPos = -1	--红点位置

--豪情一掷满江湖 end

-- 2023Q1新服欢乐月-喜迎财神到 begin
local g_XYCSD_ItemList = {{39910094,1,},{38006285,1,},{30008130,2,},{20502003,1,},{20501003,1,},{38001554,1,},{30008048,1,},{39924120,1,}}
local g_XYCSD_SpecialPrizeList = 
{
	[1] = {10141452,38005252,},
	[2] = {20501005,10126268,},
	[3] = {20502005,10146157,},
	[4] = {20501005,10126327,},
	[5] = {20502005,10147080,},
	[6] = {20501005,10126132,},
	[7] = {10101052,10141520,},
}
local g_XYCSD_RedPointPos = -1	--红点位置 
-- 2023Q1新服欢乐月-喜迎财神到 end

--新春享返利 begin 
local g_XCFL_RedPoint = 0	--红点开关标记
local g_XCFL_RedPointPos = -1	--红点位置 
local g_ServerNew_XCFL_ButtonState = {
	[1] =0,
	[2] =0,
	[3] =0,
	[4] =0,
	[5] =0,
	[6] =0,
	[7] =0,
	[8] =0, 
};
local g_ServerNew_XCFL_GetGiftsCondition =
{
	[1] = { Exch = 200, Cost = 4000, },
	[2] = { Exch = 200, Cost = 24000, },
	[3] = { Exch = 200, Cost = 60000, },
	[4] = { Exch = 200, Cost = 120000, }, 
}
local g_ServerNew_XCFL_ItemIcon =
{
	[1] = { 39923175, 39923179,},
	[2] = { 39923176, 39923180, 38008400,},
	[3] = { 39923177, 39923181, 38008401,},
	[4] = { 39923178, 39923182, 38008402,}, 
} 
local g_ServerNew_XinChunFanLi_Cost =0;
local g_ServerNew_XinChunFanLi_Exch =0;
local g_ServerNew_XCFL_Exch_Base =200;
local g_ServerNew_XinChunFanLi_ButtonState = {
	Gift 		={0,0,0,0,},
	Gift1 	={0,0,0,0,},
	Exch  	={0,0,0,0,},
}
local g_ServerNew_XinChunFanLi_Button = {
}
local g_ServerNew_XinChunFanLi_Text = {
} 
local g_XinChunFanLi_RedPointButton ={
}
local g_ServerNew_XinChunFanLi_Icon = {
}

local g_KajiTable_RHM = {
	--副本竞速榜 特殊字典
	[1] = {
		--type0 不卡级
		[0] = "#{XFJS_140922_14}",
		--type1 卡69级
		[1] = "#{KJFTS_210818_02}"
	},
	--副本竞速榜 卡级显示副本的最大index
	[2] = {
		--type0 不卡级
		[0] = 3,
		--type1 卡69级
		[1] = 2
	},
	--豪情一掷满江湖 奖励
	[3] = {
		--type0 不卡级
		[0] = {
			[1] = {10101052, 20502005, 10141427},
			[2] = {10126805, 20501005, 10146246},
			[3] = {10101059, 20502005, 10141678},
			[4] = {10127659, 20501005, 10125028},
			[5] = {10102976, 20502005, 10141562},
			[6] = {10127236, 20501005, 10147495},
			[7] = {10141518, 10102808, 10422155},
		},
		
		--type1 卡69级
		[1] = {
			[1] = {10101052, 20502005, 10141427},
			[2] = {10126805, 20501005, 10146246},
			[3] = {10101059, 20502005, 10141678},
			[4] = {10127659, 20501005, 10125028},
			[5] = {10102976, 20502005, 10141562},
			[6] = {10127236, 20501005, 10147495},
			[7] = {10141518, 10102808, 10422155},
		}
	},
	--豪情大派送 界面展示的10个格子
	[4] = {
		[0] = {
			[1] = 38005797,--38001189,--30008109,	--破军
			[2] = 38005798,--38001190,--30008110,	--七杀
			[3] = 38005799,--38001191,--30008111, --贪狼
			[4] = 30309869,
			[5] = 30504326,--10141519,
			[6] = 39920479,--10124097,--
			[7] = 39920480,--10141311,--
			[8] = 39920482,--30309058,--
			[9] = 38000380,--39920382,
			[10]= 38000839,--30700241,
			[11]= 38005591,
		},
		[1] = {
			[1] = 39923528,--30008109,	--破军
			[2] = 39923529,--30008110,	--七杀
			[3] = 39923530,--30008111, --贪狼
			[4] = 30309869,
			[5] = 30504326,--10141519,
			[6] = 39920479,--10124097,--
			[7] = 39920480,--10141311,--
			[8] = 39923532,--30309058,--
			[9] = 39920267,--30700241,
			[10]= 38000839,--30700241,
		}

	},
	--豪情大派送 界面字典
	[5] = {
		[0] = "#{XFXF_140919_04}",
		[1] = "#{XFXF_140919_04}"
	},
	--重楼献英豪 界面字典
	[6] = {
		[0] = "#{XFXF_140919_45}",
		[1] = "#{KJFTS_210818_23}"
	},
	--重楼献英豪 奖励字典
	[7] = {
		[0]={	
			[1] = "#{XFXF_140919_52}",
			[2] = "#{XFXF_140919_53}",
			[3] = "#{XFXF_140919_54}",
			[4] = "#{XFXF_140919_55}",
			[5] = "#{XFXF_140919_56}",
			[6] = "#{XFXF_140919_57}",
			[7] = "#{XFXF_140919_58}",
			[8] = "#{XFXF_140919_59}",
			[9] = "#{XFXF_140919_60}",
			[10] = "#{XFXF_140919_61}",
		},
		[1] = {
			[1] = "#{KJFTS_210818_65}",
			[2] = "#{KJFTS_210818_66}",
			[3] = "#{KJFTS_210818_67}",
			[4] = "#{KJFTS_210818_68}",
			[5] = "#{KJFTS_210818_69}",
			[6] = "#{KJFTS_210818_70}",
			[7] = "#{KJFTS_210818_71}",
			[8] = "#{KJFTS_210818_72}",
			[9] = "#{KJFTS_210818_73}",
			[10] = "#{KJFTS_210818_74}",
		}
	},
	--豪情大派送 buttontips
	[8] = {
		[0]={	
			[1] = "#{XFXF_140919_07}",
			[2] = "#{XFXF_140919_09}",
			[3] = "#{XFXF_140919_11}",
			[4] = "#{XFXF_140919_14}",
			[5] = "#{XFXF_140919_16}",
			[6] = "#{XFXF_140919_18}",
			[7] = "#{XFXF_140919_20}",
			[8] = "#{XFXF_140919_24}",
			[9] = "#{XFXF_140919_26}",
			[10] = "#{XFXF_140919_28}",
			[11] = "#{XFXF_220316_112}",
		},
		[1] = {
			[1] = "#{KJFTS_210818_103}",
			[2] = "#{KJFTS_210818_104}",
			[3] = "#{KJFTS_210818_105}",
			[4] = "#{KJFTS_210818_106}",
			[5] = "#{KJFTS_210818_107}",
			[6] = "#{KJFTS_210818_108}",
			[7] = "#{KJFTS_210818_109}",
			[8] = "#{KJFTS_210818_110}",
			[9] = "#{KJFTS_210818_111}",
			[10] = "#{KJFTS_210818_112}",
		}
	}
}

--local不能再加了
--===============================================

--新春享返利 end
--===============================================
-- PreLoad()
--===============================================
function ServerNew_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("GE_CSRANK_BIG")	                -- 副本竞速排行榜
	this:RegisterEvent("OPEN_XIAOFEI_NEWSRVTOPLIST");       -- 消费排行榜刷新
	this:RegisterEvent("MENPAIDIYI_RESULT") 		-- 江湖第一
	this:RegisterEvent("OPEN_FBRANKING_LIST")	   	-- 野外Boss排行榜
	this:RegisterEvent("UNIT_LEVEL")			-- 【新服欢乐月·升级送好礼】刷新界面,玩家升级的时候需要刷新界面
	this:RegisterEvent("PLAYER_ENTERING_WORLD" )		-- 进入游戏世界
	this:RegisterEvent("UPDATE_NEWSRVBC_MARRY" )		-- 刷新新服乐事记广播 结婚频道
	this:RegisterEvent("UPDATE_NEWSRVBC_BROTHER" )		-- 刷新新服乐事记广播 结拜频道
	this:RegisterEvent("UPDATE_NEWSRVBC_SHITU" )		-- 刷新新服乐事记广播 师徒频道
	this:RegisterEvent("UPDATE_NEWSRVBC_GUILD" )		-- 刷新新服乐事记广播 帮派频道
	this:RegisterEvent("SERVERNEWLOTTERY_NAME_UPDATE" )		-- 豪情一掷满江湖 更新中奖名单
end

--===============================================
-- OnEvent()
--===============================================
function ServerNew_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 8909332) then
		ServerNew_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 890997 ) then    	--【新服欢乐月·首冲超值增】
		-- 取参数
		for i = 1, table.getn(g_ServerNew_SaveUpBtnState) do
			g_ServerNew_SaveUpBtnState[i] = Get_XParam_INT( i - 1 )
		end	
		g_ServerNew_SaveUp_YuanBaoCost = Get_XParam_INT( 6 )
		g_ServerNew_SaveUp_YuanBaoExch = Get_XParam_INT( 7 )
		-- 更新Btn
		ServerNew_SaveUp_FlushWindow()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 890996 ) then	--【新服欢乐月·升级送好礼】
		-- 取参数
		for i = 1, table.getn(g_ServerNew_LevelUp_GetGiftLevel) do
			g_ServerNew_LevelUpBtnState[i] = Get_XParam_INT( i - 1 )
		end	
		-- 更新Btn
		ServerNew_LevelUp_FlushWindow();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20140924 ) then	--【新服欢乐月·充值排行榜刷新】
		local state = Get_XParam_INT(0)
		local ntype = Get_XParam_INT(1)
		local ndate = Get_XParam_INT(2)
		

		ServerNew_Paihang_LeftTime(state,ntype,ndate)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20140925 ) then	--【新服欢乐月·打开连接】
		GameProduceLogin:OpenURL(GetWeblink("WEB_QIXI"))
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20141006 ) then	--【新服欢乐月·刷新豪情值】
		ServerNew_Send_Update()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		ServerNew_Close()
	elseif (event == "ADJEST_UI_POS") then
		ServerNew_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ServerNew_On_ResetPos()
	elseif (event == "GE_CSRANK_BIG") then
		ServerNew_CSRank_Clear()
		ServerNew_CSRank_OnRefresh()
	elseif (event == "OPEN_XIAOFEI_NEWSRVTOPLIST") then
		ServerNew_Paihang_UpdateList()
	elseif (event == "MENPAIDIYI_RESULT") then
		ServerNew_FirstOne_Open()
	elseif (event == "OPEN_FBRANKING_LIST") then
		ServerNew_Plunder_Button01:SetProperty("Selected","False")
		ServerNew_Plunder_Button02:SetProperty("Selected","False")
		ServerNew_FBButton_Hide()
		ServerNew_Init_FBRankData()
		--ServerNew_FBRank_Clear()
		--ServerNew_FBRANK_CURWEEK_SHOW()
	elseif (event == "UNIT_LEVEL" ) then
		if IsWindowShow("ServerNew") then				--【新服欢乐月·升级送好礼】 界面刷新
			ServerNew_LevelUp_FlushWindow()
		end
	elseif (event == "PLAYER_ENTERING_WORLD" ) then				-- 【新服欢乐月·升级送好礼&首冲超值赠】重新加载物品奖励
		g_ServerNew_LevelUp_LoadFirstTime = 1;
		g_ServerNew_SaveUp_LoadFirstTime  = 1;
	elseif (event == "UPDATE_NEWSRVBC_MARRY" ) then	
		ServerNew_Broadcast_UpdateList(1)
	elseif (event == "UPDATE_NEWSRVBC_BROTHER" ) then	
		ServerNew_Broadcast_UpdateList(2)
	elseif (event == "UPDATE_NEWSRVBC_SHITU" ) then	
		ServerNew_Broadcast_UpdateList(3)
	elseif (event == "UPDATE_NEWSRVBC_GUILD" ) then	
		ServerNew_Broadcast_UpdateList(4)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201609202 ) then --新服乐事记 红点控制
		g_Broadcast_RedPoint = Get_XParam_INT(0) 
		if this:IsVisible() then
			if g_Broadcast_RedPoint == 1 then
				g_Broadcast_RedPointButton[g_Broadcast_RedPointPos]:Show()
			else
				g_Broadcast_RedPointButton[g_Broadcast_RedPointPos]:Hide()
			end
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201609203 ) then --新服乐事记 更新领奖按钮
		for i = 1, table.getn(g_ServerNew_BroadcastBtnState) do
			g_ServerNew_BroadcastBtnState[i] = Get_XParam_INT( i - 1 )
		end	
		ServerNew_Broadcast_FlushRewardButton()
	--elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201801171 ) then --豪情一掷 刷新界面
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 201801172 ) then --豪情一掷 刷新按钮
		if this:IsVisible() then
			ServerNew_HQYZ_UpdateButton()
			ServerNew_HQYZ_UpdateRedPoint()
		end
	elseif  ( event == "UI_COMMAND" and tonumber(arg0) == 89298101 ) then --新春送好礼
		ServerNew_XinChunFanLi_UpdateInfo()
	elseif  ( event == "UI_COMMAND" and tonumber(arg0) == 89298103 ) and this:IsVisible() then --新春送好礼 
		g_XCFL_RedPoint = Get_XParam_INT(0) 
		ServerNew_XinChunFanLi_UpdateRedPoint()
	elseif  ( event == "UI_COMMAND" and tonumber(arg0) == 99840701 ) and this:IsVisible() then -- 2023Q1新服欢乐月-喜迎财神到
		local bShow = Get_XParam_INT(0) 
		ServerNew_XYCSD_Update(bShow)
	elseif  ( event == "UI_COMMAND" and tonumber(arg0) == 99840702 ) and this:IsVisible() then -- 2023Q1新服欢乐月-喜迎财神到
		local redPoint = Get_XParam_INT(0)
		ServerNew_XYCSD_UpdateRedPoint(redPoint)
	elseif (event == "SERVERNEWLOTTERY_NAME_UPDATE" ) then	
		ServerNew_HQYZ_Update(arg0, arg1, arg2)
	end
end

--===============================================
-- OnLoad()
--===============================================
function ServerNew_OnLoad()
	g_ServerNew_Button[1] = ServerNew_Button01
	g_ServerNew_Button[2] = ServerNew_Button02
	g_ServerNew_Button[3] = ServerNew_Button03
	g_ServerNew_Button[4] = ServerNew_Button04
	g_ServerNew_Button[5] = ServerNew_Button05
	g_ServerNew_Button[6] = ServerNew_Button06
	g_ServerNew_Button[7] = ServerNew_Button07
	g_ServerNew_Button[8] = ServerNew_Button08
	g_ServerNew_Button[9] = ServerNew_Button09
	g_ServerNew_Button[10] = ServerNew_Button10
	g_ServerNew_Button[11] = ServerNew_Button11
	g_ServerNew_Button[12] = ServerNew_Button12
	g_ServerNew_Button[13] = ServerNew_Button13
	g_ServerNew_Button[14] = ServerNew_Button14--2023Q1新服欢乐月-喜迎财神到
	g_ServerNew_Button[15] = ServerNew_Button15	-- 新服经验点Boss

	g_ServerNew_Frame_UnifiedPosition = ServerNew_Frame:GetProperty("UnifiedPosition")
	--副本竞速排行榜开始
	--少室山
	g_CSRankInfo[3].usetime = ServerNew_Velocity_JJFrame_Text0_1
	g_CSRankInfo[3].leadericon = ServerNew_Velocity_JJFrame_DUI0
	g_CSRankInfo[3].name[1] = ServerNew_Velocity_JJFrame_Text0_2
	g_CSRankInfo[3].name[2] = ServerNew_Velocity_JJFrame_Text0_3
	g_CSRankInfo[3].name[3] = ServerNew_Velocity_JJFrame_Text0_4
	g_CSRankInfo[3].name[4] = ServerNew_Velocity_JJFrame_Text0_5
	g_CSRankInfo[3].name[5] = ServerNew_Velocity_JJFrame_Text0_6
	g_CSRankInfo[3].name[6] = ServerNew_Velocity_JJFrame_Text0_7
	g_CSRankInfo[3].blank = ServerNew_Velocity_JJFrame_Text0_8
	--g_CSRankInfo[2].usetime = ServerNew_Velocity_JJFrame_Text1_1
	--g_CSRankInfo[2].leadericon = ServerNew_Velocity_JJFrame_DUI1
	--g_CSRankInfo[2].name[1] = ServerNew_Velocity_JJFrame_Text1_2
	--g_CSRankInfo[2].name[2] = ServerNew_Velocity_JJFrame_Text1_3
	--g_CSRankInfo[2].name[3] = ServerNew_Velocity_JJFrame_Text1_4
	--g_CSRankInfo[2].name[4] = ServerNew_Velocity_JJFrame_Text1_5
	--g_CSRankInfo[2].name[5] = ServerNew_Velocity_JJFrame_Text1_6
	--g_CSRankInfo[2].name[6] = ServerNew_Velocity_JJFrame_Text1_7
	--g_CSRankInfo[2].blank = ServerNew_Velocity_JJFrame_Text1_8
	--燕子坞
	g_CSRankInfo[2].usetime = ServerNew_Velocity_JJFrame_Text2_1
	g_CSRankInfo[2].leadericon = ServerNew_Velocity_JJFrame_DUI2
	g_CSRankInfo[2].name[1] = ServerNew_Velocity_JJFrame_Text2_2
	g_CSRankInfo[2].name[2] = ServerNew_Velocity_JJFrame_Text2_3
	g_CSRankInfo[2].name[3] = ServerNew_Velocity_JJFrame_Text2_4
	g_CSRankInfo[2].name[4] = ServerNew_Velocity_JJFrame_Text2_5
	g_CSRankInfo[2].name[5] = ServerNew_Velocity_JJFrame_Text2_6
	g_CSRankInfo[2].name[6] = ServerNew_Velocity_JJFrame_Text2_7
	g_CSRankInfo[2].blank = ServerNew_Velocity_JJFrame_Text2_8
	--大飘
	-- g_CSRankInfo[3].usetime = ServerNew_Velocity_JJFrame_Text3_1
	-- g_CSRankInfo[3].leadericon = ServerNew_Velocity_JJFrame_DUI3
	-- g_CSRankInfo[3].name[1] = ServerNew_Velocity_JJFrame_Text3_2
	-- g_CSRankInfo[3].name[2] = ServerNew_Velocity_JJFrame_Text3_3
	-- g_CSRankInfo[3].name[3] = ServerNew_Velocity_JJFrame_Text3_4
	-- g_CSRankInfo[3].name[4] = ServerNew_Velocity_JJFrame_Text3_5
	-- g_CSRankInfo[3].name[5] = ServerNew_Velocity_JJFrame_Text3_6
	-- g_CSRankInfo[3].name[6] = ServerNew_Velocity_JJFrame_Text3_7
	-- g_CSRankInfo[3].blank = ServerNew_Velocity_JJFrame_Text3_8
	--四绝
	g_CSRankInfo[1].usetime = ServerNew_Velocity_JJFrame_Text4_1
	g_CSRankInfo[1].leadericon = ServerNew_Velocity_JJFrame_DUI4
	g_CSRankInfo[1].name[1] = ServerNew_Velocity_JJFrame_Text4_2
	g_CSRankInfo[1].name[2] = ServerNew_Velocity_JJFrame_Text4_3
	g_CSRankInfo[1].name[3] = ServerNew_Velocity_JJFrame_Text4_4
	g_CSRankInfo[1].name[4] = ServerNew_Velocity_JJFrame_Text4_5
	g_CSRankInfo[1].name[5] = ServerNew_Velocity_JJFrame_Text4_6
	g_CSRankInfo[1].name[6] = ServerNew_Velocity_JJFrame_Text4_7
	g_CSRankInfo[1].blank = ServerNew_Velocity_JJFrame_Text4_8

	g_CSRankBKFrame[1] = ServerNew_Velocity_JJFrame_Bk0
	g_CSRankBKFrame[2] = ServerNew_Velocity_JJFrame_Bk2
	--g_CSRankBKFrame[3] = ServerNew_Velocity_JJFrame_Bk3
	g_CSRankBKFrame[3] = ServerNew_Velocity_JJFrame_Bk4


	--副本竞速排行榜结束
	
	--豪情兑换
	g_ServerNew_Send_Button.showBtn = {}
	g_ServerNew_Send_Button.showBtn[1] = ServerNew_Send_HQFrameLi1_Icon
	g_ServerNew_Send_Button.showBtn[2] = ServerNew_Send_HQFrameLi2_Icon
	g_ServerNew_Send_Button.showBtn[3] = ServerNew_Send_HQFrameLi3_Icon
	g_ServerNew_Send_Button.showBtn[4] = ServerNew_Send_QLFrameLi1_Icon
	g_ServerNew_Send_Button.showBtn[5] = ServerNew_Send_QLFrameLi2_Icon
	g_ServerNew_Send_Button.showBtn[6] = ServerNew_Send_QLFrameLi3_Icon
	g_ServerNew_Send_Button.showBtn[7] = ServerNew_Send_QLFrameLi4_Icon
	g_ServerNew_Send_Button.showBtn[8] = ServerNew_Send_QLFrameLi6_Icon
	g_ServerNew_Send_Button.showBtn[9] = ServerNew_Send_QLFrameLi7_Icon
	g_ServerNew_Send_Button.showBtn[10] = ServerNew_Send_QLFrameLi8_Icon
	g_ServerNew_Send_Button.showBtn[11] = ServerNew_Send_QLFrameLi9_Icon

	g_ServerNew_Send_Button.getBtn = {}
	g_ServerNew_Send_Button.getBtn[1] = ServerNew_Send_HQFrameLi1_Button
	g_ServerNew_Send_Button.getBtn[2] = ServerNew_Send_HQFrameLi2_Button
	g_ServerNew_Send_Button.getBtn[3] = ServerNew_Send_HQFrameLi3_Button
	g_ServerNew_Send_Button.getBtn[4] = ServerNew_Send_QLFrameLi1_Button
	g_ServerNew_Send_Button.getBtn[5] = ServerNew_Send_QLFrameLi2_Button
	g_ServerNew_Send_Button.getBtn[6] = ServerNew_Send_QLFrameLi3_Button
	g_ServerNew_Send_Button.getBtn[7] = ServerNew_Send_QLFrameLi4_Button
	g_ServerNew_Send_Button.getBtn[8] = ServerNew_Send_QLFrameLi6_Button
	g_ServerNew_Send_Button.getBtn[9] = ServerNew_Send_QLFrameLi7_Button
	g_ServerNew_Send_Button.getBtn[10] = ServerNew_Send_QLFrameLi8_Button
	g_ServerNew_Send_Button.getBtn[11] = ServerNew_Send_QLFrameLi9_Button

	g_ServerNew_Send_Button.bk = {}
	g_ServerNew_Send_Button.bk[1] = ServerNew_Send_HQFrameLi1
	g_ServerNew_Send_Button.bk[2] = ServerNew_Send_HQFrameLi2
	g_ServerNew_Send_Button.bk[3] = ServerNew_Send_HQFrameLi3
	g_ServerNew_Send_Button.bk[4] = ServerNew_Send_QLFrameLi1
	g_ServerNew_Send_Button.bk[5] = ServerNew_Send_QLFrameLi2
	g_ServerNew_Send_Button.bk[6] = ServerNew_Send_QLFrameLi3
	g_ServerNew_Send_Button.bk[7] = ServerNew_Send_QLFrameLi4
	g_ServerNew_Send_Button.bk[8] = ServerNew_Send_QLFrameLi6
	g_ServerNew_Send_Button.bk[9] = ServerNew_Send_QLFrameLi7
	g_ServerNew_Send_Button.bk[10] = ServerNew_Send_QLFrameLi8
	g_ServerNew_Send_Button.bk[11] = ServerNew_Send_QLFrameLi9
		
	---江湖第一begin
	--天下第一
	g_ServerNew_FirstOne_L_Name[1]		= ServerNew_FirstOne_L_P_BK1_Text1
	g_ServerNew_FirstOne_L_Level[1]		= ServerNew_FirstOne_L_P_BK1_Text2
	g_ServerNew_FirstOne_L_Menpai[1]	= ServerNew_FirstOne_L_P_BK1_Text3
	--g_ServerNew_FirstOne_L_Name[2]		= ServerNew_FirstOne_L_P2_BK1_Text1
	--g_ServerNew_FirstOne_L_Level[2]		= ServerNew_FirstOne_L_P2_BK1_Text2
	--g_ServerNew_FirstOne_L_Menpai[2]	= ServerNew_FirstOne_L_P2_BK1_Text3
	--g_ServerNew_FirstOne_L_Name[3]		= ServerNew_FirstOne_L_P3_BK1_Text1
	--g_ServerNew_FirstOne_L_Level[3]		= ServerNew_FirstOne_L_P3_BK1_Text2
	--g_ServerNew_FirstOne_L_Menpai[3]	= ServerNew_FirstOne_L_P3_BK1_Text3
	
	--门派第一
	g_ServerNew_FirstOne_R_Name[1]		= ServerNew_FirstOne_R_P1_BK1_Text1
	g_ServerNew_FirstOne_R_Level[1]		= ServerNew_FirstOne_R_P1_BK1_Text2
	--g_ServerNew_FirstOne_R_Menpai[1]	= ServerNew_FirstOne_R_P1_BK1_Text3

	g_ServerNew_FirstOne_R_Name[2]		= ServerNew_FirstOne_R_P1_BK5_Text1
	g_ServerNew_FirstOne_R_Level[2]		= ServerNew_FirstOne_R_P1_BK5_Text2
	--g_ServerNew_FirstOne_R_Menpai[2]	= ServerNew_FirstOne_R_P1_BK2_Text3

	g_ServerNew_FirstOne_R_Name[3]		= ServerNew_FirstOne_R_P1_BK9_Text1
	g_ServerNew_FirstOne_R_Level[3]		= ServerNew_FirstOne_R_P1_BK9_Text2
	--g_ServerNew_FirstOne_R_Menpai[3]	= ServerNew_FirstOne_R_P1_BK3_Text3

	g_ServerNew_FirstOne_R_Name[4]		= ServerNew_FirstOne_R_P1_BK2_Text1
	g_ServerNew_FirstOne_R_Level[4]		= ServerNew_FirstOne_R_P1_BK2_Text2
	--g_ServerNew_FirstOne_R_Menpai[4]	= ServerNew_FirstOne_R_P1_BK4_Text3

	g_ServerNew_FirstOne_R_Name[5]		= ServerNew_FirstOne_R_P1_BK6_Text1
	g_ServerNew_FirstOne_R_Level[5]		= ServerNew_FirstOne_R_P1_BK6_Text2
	--g_ServerNew_FirstOne_R_Menpai[5]	= ServerNew_FirstOne_R_P1_BK5_Text3

	g_ServerNew_FirstOne_R_Name[6]		= ServerNew_FirstOne_R_P1_BK10_Text1
	g_ServerNew_FirstOne_R_Level[6]		= ServerNew_FirstOne_R_P1_BK10_Text2
	--g_ServerNew_FirstOne_R_Menpai[6]	= ServerNew_FirstOne_R_P1_BK6_Text3

	g_ServerNew_FirstOne_R_Name[7]		= ServerNew_FirstOne_R_P1_BK3_Text1
	g_ServerNew_FirstOne_R_Level[7]		= ServerNew_FirstOne_R_P1_BK3_Text2
	--g_ServerNew_FirstOne_R_Menpai[7]	= ServerNew_FirstOne_R_P1_BK7_Text3

	g_ServerNew_FirstOne_R_Name[8]		= ServerNew_FirstOne_R_P1_BK7_Text1
	g_ServerNew_FirstOne_R_Level[8]		= ServerNew_FirstOne_R_P1_BK7_Text2
	--g_ServerNew_FirstOne_R_Menpai[8]	= ServerNew_FirstOne_R_P1_BK8_Text3

	g_ServerNew_FirstOne_R_Name[9]		= ServerNew_FirstOne_R_P1_BK11_Text1
	g_ServerNew_FirstOne_R_Level[9]		= ServerNew_FirstOne_R_P1_BK11_Text2
	--g_ServerNew_FirstOne_R_Menpai[9]	= ServerNew_FirstOne_R_P1_BK9_Text3

	g_ServerNew_FirstOne_R_Name[10]		= ServerNew_FirstOne_R_P1_BK4_Text1
	g_ServerNew_FirstOne_R_Level[10]	= ServerNew_FirstOne_R_P1_BK4_Text2
	--g_ServerNew_FirstOne_R_Menpai[10]	= ServerNew_FirstOne_R_P1_BK10_Text3

	g_ServerNew_FirstOne_R_Name[11]		= ServerNew_FirstOne_R_P1_BK8_Text1
	g_ServerNew_FirstOne_R_Level[11]	= ServerNew_FirstOne_R_P1_BK8_Text2
	
	g_ServerNew_FirstOne_R_Name[12]		= ServerNew_FirstOne_R_P1_BK12_Text1
	g_ServerNew_FirstOne_R_Level[12]	= ServerNew_FirstOne_R_P1_BK12_Text2
	--g_ServerNew_FirstOne_R_Menpai[11]	= ServerNew_FirstOne_R_P1_BK11_Text3

	g_ServerNew_FirstOne_R_Name[13]		= ServerNew_FirstOne_R_P1_BK13_Text1
	g_ServerNew_FirstOne_R_Level[13]	= ServerNew_FirstOne_R_P1_BK13_Text2
	
	g_ServerNew_FirstOne_R_Name[14]		= ServerNew_FirstOne_R_P1_BK14_Text1
	g_ServerNew_FirstOne_R_Level[14]	= ServerNew_FirstOne_R_P1_BK14_Text2
	
	g_ServerNew_FirstOne_R_Name[15]		= ServerNew_FirstOne_R_P1_BK15_Text1
	g_ServerNew_FirstOne_R_Level[15]	= ServerNew_FirstOne_R_P1_BK15_Text2
	
	---江湖第一end
	
	--【新服欢乐月·升级送好礼】Begin

	--界面上显示奖励物品的ICON表
	g_ServerNew_LevelUp_GiftsIcons =
	{
	[1] = {ServerNew_LevelUp_Frame3_Bk1_Icon1, ServerNew_LevelUp_Frame3_Bk1_Icon2, ServerNew_LevelUp_Frame3_Bk1_Icon3, ServerNew_LevelUp_Frame3_Bk1_Icon4, }, 
	[2] = {ServerNew_LevelUp_Frame3_Bk2_Icon1, ServerNew_LevelUp_Frame3_Bk2_Icon2, ServerNew_LevelUp_Frame3_Bk2_Icon3, ServerNew_LevelUp_Frame3_Bk2_Icon4, }, 
	[3] = {ServerNew_LevelUp_Frame3_Bk3_Icon1, ServerNew_LevelUp_Frame3_Bk3_Icon2, ServerNew_LevelUp_Frame3_Bk3_Icon3, ServerNew_LevelUp_Frame3_Bk3_Icon4, }, 
	[4] = {ServerNew_LevelUp_Frame3_Bk4_Icon1, ServerNew_LevelUp_Frame3_Bk4_Icon2, ServerNew_LevelUp_Frame3_Bk4_Icon3, ServerNew_LevelUp_Frame3_Bk4_Icon4, }, 
	[5] = {ServerNew_LevelUp_Frame3_Bk5_Icon1, ServerNew_LevelUp_Frame3_Bk5_Icon2, ServerNew_LevelUp_Frame3_Bk5_Icon3, ServerNew_LevelUp_Frame3_Bk5_Icon4, }, 
	[6] = {ServerNew_LevelUp_Frame3_Bk6_Icon1, ServerNew_LevelUp_Frame3_Bk6_Icon2, ServerNew_LevelUp_Frame3_Bk6_Icon3, ServerNew_LevelUp_Frame3_Bk6_Icon4, }, 
	[7] = {ServerNew_LevelUp_Frame3_Bk7_Icon1, ServerNew_LevelUp_Frame3_Bk7_Icon2, ServerNew_LevelUp_Frame3_Bk7_Icon3, ServerNew_LevelUp_Frame3_Bk7_Icon4, }, 
	[8] = {ServerNew_LevelUp_Frame3_Bk8_Icon1, ServerNew_LevelUp_Frame3_Bk8_Icon2, ServerNew_LevelUp_Frame3_Bk8_Icon3, ServerNew_LevelUp_Frame3_Bk8_Icon4, }, 
	[9] = {ServerNew_LevelUp_Frame3_Bk9_Icon1, ServerNew_LevelUp_Frame3_Bk9_Icon2, ServerNew_LevelUp_Frame3_Bk9_Icon3, ServerNew_LevelUp_Frame3_Bk9_Icon4, }, 
	[10] = {ServerNew_LevelUp_Frame3_Bk10_Icon1, ServerNew_LevelUp_Frame3_Bk10_Icon2, ServerNew_LevelUp_Frame3_Bk10_Icon3, ServerNew_LevelUp_Frame3_Bk10_Icon4, }, 
	[11] = {ServerNew_LevelUp_Frame3_Bk11_Icon1, ServerNew_LevelUp_Frame3_Bk11_Icon2, ServerNew_LevelUp_Frame3_Bk11_Icon3, ServerNew_LevelUp_Frame3_Bk11_Icon4, }, 
	[12] = {ServerNew_LevelUp_Frame3_Bk12_Icon1, ServerNew_LevelUp_Frame3_Bk12_Icon2, ServerNew_LevelUp_Frame3_Bk12_Icon3, ServerNew_LevelUp_Frame3_Bk12_Icon4, }, 
	[13] = {ServerNew_LevelUp_Frame3_Bk13_Icon1, ServerNew_LevelUp_Frame3_Bk13_Icon2, ServerNew_LevelUp_Frame3_Bk13_Icon3, ServerNew_LevelUp_Frame3_Bk13_Icon4, }, 
	}

	g_ServerNew_LevelUp_GiftsIconsImages =
	{
	[1] = {ServerNew_LevelUp_Frame3_Bk1_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk1_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk1_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk1_Icon4_Xin, }, 
	[2] = {ServerNew_LevelUp_Frame3_Bk2_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk2_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk2_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk2_Icon4_Xin, }, 
	[3] = {ServerNew_LevelUp_Frame3_Bk3_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk3_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk3_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk3_Icon4_Xin, }, 
	[4] = {ServerNew_LevelUp_Frame3_Bk4_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk4_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk4_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk4_Icon4_Xin, }, 
	[5] = {ServerNew_LevelUp_Frame3_Bk5_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk5_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk5_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk5_Icon4_Xin, }, 
	[6] = {ServerNew_LevelUp_Frame3_Bk6_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk6_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk6_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk6_Icon4_Xin, }, 
	[7] = {ServerNew_LevelUp_Frame3_Bk7_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk7_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk7_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk7_Icon4_Xin, }, 
	[8] = {ServerNew_LevelUp_Frame3_Bk8_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk8_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk8_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk8_Icon4_Xin, }, 
	[9] = {ServerNew_LevelUp_Frame3_Bk9_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk9_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk9_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk9_Icon4_Xin, }, 
	[10] = {ServerNew_LevelUp_Frame3_Bk10_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk10_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk10_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk10_Icon4_Xin, }, 
	[11] = {ServerNew_LevelUp_Frame3_Bk11_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk11_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk11_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk11_Icon4_Xin, }, 
	[12] = {ServerNew_LevelUp_Frame3_Bk12_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk12_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk12_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk12_Icon4_Xin, }, 
	[13] = {ServerNew_LevelUp_Frame3_Bk13_Icon1_Xin, ServerNew_LevelUp_Frame3_Bk13_Icon2_Xin, ServerNew_LevelUp_Frame3_Bk13_Icon3_Xin, ServerNew_LevelUp_Frame3_Bk13_Icon4_Xin, }, 
	}
	--界面上的每档奖励展示框
	g_ServerNew_LevelUp_Frames = 
	{
		[1] = ServerNew_LevelUp_Frame3_Bk1, [2] = ServerNew_LevelUp_Frame3_Bk2, [3] = ServerNew_LevelUp_Frame3_Bk3, [4] = ServerNew_LevelUp_Frame3_Bk4,
		[5] = ServerNew_LevelUp_Frame3_Bk5, [6] = ServerNew_LevelUp_Frame3_Bk6, [7] = ServerNew_LevelUp_Frame3_Bk7, [8] = ServerNew_LevelUp_Frame3_Bk8,
		[9] = ServerNew_LevelUp_Frame3_Bk9, [10] = ServerNew_LevelUp_Frame3_Bk10, [11] = ServerNew_LevelUp_Frame3_Bk11, [12] = ServerNew_LevelUp_Frame3_Bk12,
		[13] = ServerNew_LevelUp_Frame3_Bk13,
	}
	--界面【领取奖励】按钮表
	g_ServerNew_LevelUp_GetGiftsButtonList =
	{
		[1] = ServerNew_LevelUp_Frame3_Bk1_Button1,
		[2] = ServerNew_LevelUp_Frame3_Bk2_Button1,
		[3] = ServerNew_LevelUp_Frame3_Bk3_Button1,
		[4] = ServerNew_LevelUp_Frame3_Bk4_Button1,
		[5] = ServerNew_LevelUp_Frame3_Bk5_Button1,
		[6] = ServerNew_LevelUp_Frame3_Bk6_Button1,
		[7] = ServerNew_LevelUp_Frame3_Bk7_Button1,
		[8] = ServerNew_LevelUp_Frame3_Bk8_Button1,
		[9] = ServerNew_LevelUp_Frame3_Bk9_Button1,
		[10] = ServerNew_LevelUp_Frame3_Bk10_Button1,
		[11] = ServerNew_LevelUp_Frame3_Bk11_Button1,
		[12] = ServerNew_LevelUp_Frame3_Bk12_Button1,
		[13] = ServerNew_LevelUp_Frame3_Bk13_Button1,
	}	
	--【新服欢乐月·升级送好礼】End

	--【新服欢乐月·首充超值增】Begin
	--界面上显示奖励物品的ICON表
	g_ServerNew_SaveUp_GiftsIcons =
	{
	[1] = {ServerNew_SaveUp_Frame3_Bk1_Icon1, ServerNew_SaveUp_Frame3_Bk1_Icon2, ServerNew_SaveUp_Frame3_Bk1_Icon3, ServerNew_SaveUp_Frame3_Bk1_Icon4, }, 
	[2] = {ServerNew_SaveUp_Frame3_Bk2_Icon1, ServerNew_SaveUp_Frame3_Bk2_Icon2, ServerNew_SaveUp_Frame3_Bk2_Icon3, ServerNew_SaveUp_Frame3_Bk2_Icon4, }, 
	[3] = {ServerNew_SaveUp_Frame3_Bk3_Icon1, ServerNew_SaveUp_Frame3_Bk3_Icon2, ServerNew_SaveUp_Frame3_Bk3_Icon3, ServerNew_SaveUp_Frame3_Bk3_Icon4, }, 
	[4] = {ServerNew_SaveUp_Frame3_Bk4_Icon1, ServerNew_SaveUp_Frame3_Bk4_Icon2, ServerNew_SaveUp_Frame3_Bk4_Icon3, ServerNew_SaveUp_Frame3_Bk4_Icon4, }, 
	[5] = {ServerNew_SaveUp_Frame3_Bk5_Icon1, ServerNew_SaveUp_Frame3_Bk5_Icon2, ServerNew_SaveUp_Frame3_Bk5_Icon3, ServerNew_SaveUp_Frame3_Bk5_Icon4, }, 
	[6] = {ServerNew_SaveUp_Frame3_Bk6_Icon1, ServerNew_SaveUp_Frame3_Bk6_Icon2, ServerNew_SaveUp_Frame3_Bk6_Icon3, ServerNew_SaveUp_Frame3_Bk6_Icon4, }, 
	}

	g_ServerNew_SaveUp_GiftsIconImages =
	{
	[1] = {ServerNew_SaveUp_Frame3_Bk1_Icon1_Xin, ServerNew_SaveUp_Frame3_Bk1_Icon2_Xin, ServerNew_SaveUp_Frame3_Bk1_Icon3_Xin, ServerNew_SaveUp_Frame3_Bk1_Icon4_Xin, }, 
	[2] = {ServerNew_SaveUp_Frame3_Bk2_Icon1_Xin, ServerNew_SaveUp_Frame3_Bk2_Icon2_Xin, ServerNew_SaveUp_Frame3_Bk2_Icon3_Xin, ServerNew_SaveUp_Frame3_Bk2_Icon4_Xin, }, 
	[3] = {ServerNew_SaveUp_Frame3_Bk3_Icon1_Xin, ServerNew_SaveUp_Frame3_Bk3_Icon2_Xin, ServerNew_SaveUp_Frame3_Bk3_Icon3_Xin, ServerNew_SaveUp_Frame3_Bk3_Icon4_Xin, }, 
	[4] = {ServerNew_SaveUp_Frame3_Bk4_Icon1_Xin, ServerNew_SaveUp_Frame3_Bk4_Icon2_Xin, ServerNew_SaveUp_Frame3_Bk4_Icon3_Xin, ServerNew_SaveUp_Frame3_Bk4_Icon4_Xin, }, 
	[5] = {ServerNew_SaveUp_Frame3_Bk5_Icon1_Xin, ServerNew_SaveUp_Frame3_Bk5_Icon2_Xin, ServerNew_SaveUp_Frame3_Bk5_Icon3_Xin, ServerNew_SaveUp_Frame3_Bk5_Icon4_Xin, }, 
	[6] = {ServerNew_SaveUp_Frame3_Bk6_Icon1_Xin, ServerNew_SaveUp_Frame3_Bk6_Icon2_Xin, ServerNew_SaveUp_Frame3_Bk6_Icon3_Xin, ServerNew_SaveUp_Frame3_Bk6_Icon4_Xin, }, 
	}

	--界面【领取奖励】按钮表
	g_ServerNew_SaveUp_GetGiftsButtonList =
	{
		[1] = ServerNew_SaveUp_Frame3_Bk1_Button1,
		[2] = ServerNew_SaveUp_Frame3_Bk2_Button1,
		[3] = ServerNew_SaveUp_Frame3_Bk3_Button1,
		[4] = ServerNew_SaveUp_Frame3_Bk4_Button1,
		[5] = ServerNew_SaveUp_Frame3_Bk5_Button1,
		[6] = ServerNew_SaveUp_Frame3_Bk6_Button1,
	}

	--界面领取条件提示Text控件表,策划需要根据完成情况动态显示=...=
	g_ServerNew_SaveUp_NotifyTipsControlList = 
	{
		[1] = { ExchText = ServerNew_SaveUp_Frame3_Bk1_Text1_2, },
		[2] = { ExchText =  ServerNew_SaveUp_Frame3_Bk2_Text1_1, CostText = ServerNew_SaveUp_Frame3_Bk2_Text1_2, ExchAmount = ServerNew_SaveUp_Frame3_Bk2_Text1_1_1, CostAmount = ServerNew_SaveUp_Frame3_Bk2_Text1_2_1, },
		[3] = { ExchText =  ServerNew_SaveUp_Frame3_Bk3_Text1_1, CostText = ServerNew_SaveUp_Frame3_Bk3_Text1_2, ExchAmount = ServerNew_SaveUp_Frame3_Bk3_Text1_1_1, CostAmount = ServerNew_SaveUp_Frame3_Bk3_Text1_2_1, },
		[4] = { ExchText =  ServerNew_SaveUp_Frame3_Bk4_Text1_1, CostText = ServerNew_SaveUp_Frame3_Bk4_Text1_2, ExchAmount = ServerNew_SaveUp_Frame3_Bk4_Text1_1_1, CostAmount = ServerNew_SaveUp_Frame3_Bk4_Text1_2_1, },
		[5] = { ExchText =  ServerNew_SaveUp_Frame3_Bk5_Text1_1, CostText = ServerNew_SaveUp_Frame3_Bk5_Text1_2, ExchAmount = ServerNew_SaveUp_Frame3_Bk5_Text1_1_1, CostAmount = ServerNew_SaveUp_Frame3_Bk5_Text1_2_1, },
		[6] = { ExchText =  ServerNew_SaveUp_Frame3_Bk6_Text1_1, CostText = ServerNew_SaveUp_Frame3_Bk6_Text1_2, ExchAmount = ServerNew_SaveUp_Frame3_Bk6_Text1_1_1, CostAmount = ServerNew_SaveUp_Frame3_Bk6_Text1_2_1, },
	}


	--【新服欢乐月·首充超值增】End
	g_FBrankGuildList = ServerNew_Plunder_TopList

	--【新服欢乐月 野外Boss排行榜】
	g_ServerNew_FBRankPrizeIcon =
	{
		[1] = ServerNew_Plunder_Icon1_1,
		[2] = ServerNew_Plunder_Icon1_2,
		[3] = ServerNew_Plunder_Icon1_3,
		[4] = ServerNew_Plunder_Icon2_1,
		[5] = ServerNew_Plunder_Icon2_2,
		[6] = ServerNew_Plunder_Icon3_1,
		[7] = ServerNew_Plunder_Icon3_2,
	}

	--【新服欢乐月 新服乐事记】
	--频道列表
	g_ServerNew_Broadcast_ChannelButtonn =
	{
		[1] = ServerNew_FunNoteFrame_TopButton1,
		[2] = ServerNew_FunNoteFrame_TopButton2,
		[3] = ServerNew_FunNoteFrame_TopButton3,
		[4] = ServerNew_FunNoteFrame_TopButton4,
	}
	--广播内容列表
	g_Broadcast_Content = {
		[1] =ServerNew_FunNoteFrame_JHFrame_NoteListInfo_text1,
		[2] =ServerNew_FunNoteFrame_JBFrame_NoteListInfo_text1,
		[3] =ServerNew_FunNoteFrame_STFrame_NoteListInfo_text1,
		[4] =ServerNew_FunNoteFrame_BHFrame_NoteListInfo_text1,
	}
	--奖励文字
	g_ServerNew_Broadcast_TextInfo = {
		[1] = ServerNew_FunNoteFrame_JHFrame_textinfo,
		[2] = ServerNew_FunNoteFrame_JBFrame_textinfo,
		[3] = ServerNew_FunNoteFrame_STFrame1_textinfo,
		[4] = ServerNew_FunNoteFrame_BHFrame_textinfo,
		[5] = ServerNew_FunNoteFrame_STFrame2_textinfo,
	}
	--奖励物品显示
	g_ServerNew_Broadcast_GiftsIcons = {
		[1] = {ServerNew_FunNoteFrame_JHFrame_RewardItem1},
		[2] = {ServerNew_FunNoteFrame_JBFrame_RewardItem1},
		[3] = {ServerNew_FunNoteFrame_STFrame1_RewardItem1},
		[4] = {ServerNew_FunNoteFrame_BHFrame_RewardItem1},
		[5] = {ServerNew_FunNoteFrame_STFrame2_RewardItem1},
	}
	--领奖button
	g_ServerNew_BroadcastButton = {
		[1] = ServerNew_FunNoteFrame_JHFrame_RewardGet,
		[2] = ServerNew_FunNoteFrame_JBFrame_RewardGet,
		[3] = ServerNew_FunNoteFrame_STFrame1_RewardGet,
		[4] = ServerNew_FunNoteFrame_BHFrame_RewardGet,
		[5] = ServerNew_FunNoteFrame_STFrame2_RewardGet,
	}
	--频道Frame
	g_ServerNew_Broadcast_ChannelFrame = {
		[1] = ServerNew_FunNoteFrame_JHFrame,
		[2] = ServerNew_FunNoteFrame_JBFrame,
		[3] = ServerNew_FunNoteFrame_STFrame,
		[4] = ServerNew_FunNoteFrame_BHFrame,
	}
	
	g_ServerNew_Frames = 
	{
		[1] = ServerNew_LevelUp_RewardFrame,
		[2] = ServerNew_SaveUp_RewardFrame,
		[3] = ServerNew_Paihang_RewardFrame,
		[4] = ServerNew_Send_RewardFrame,
		[5] = ServerNew_FirstOne_RewardFrame,
		[6] = ServerNew_Velocity_RewardFrame,
		[7] = ServerNew_Plunder_RewardFrame,
		[8] = ServerNew_DoubleExp_RewardFrame,
		[9] = ServerNew_FunNoteFrame,
		[10] = ServerNew_NewServerIntoFrame,
		[11] = ServerNew_HQYZFrame,
		[12] = ServerNew_NewYearFrame,
		[13] = ServerNew_BossDropFrame,	-- 新服Boss
		[14] = ServerNew_XYCSDFrame,	--2023Q1新服欢乐月-喜迎财神到
		[15] = ServerNew_ExpPoint_RewardFrame,	-- 新服经验点Boss
	}

	g_ServerNew_HQYZ_Icons ={
		[1] = ServerNew_HQYZ_Main_BK1_Icon,
		[2] = ServerNew_HQYZ_Main_BK2_Icon,
		[3] = ServerNew_HQYZ_Main_BK3_Icon,
	}
	--红点
	g_Broadcast_RedPointButton ={
		[1] = ServerNew_Button01_Tips,
		[2] = ServerNew_Button02_Tips,
		[3] = ServerNew_Button03_Tips,
		[4] = ServerNew_Button04_Tips,
		[5] = ServerNew_Button05_Tips,
		[6] = ServerNew_Button06_Tips,
		[7] = ServerNew_Button07_Tips,
		[8] = ServerNew_Button08_Tips,
		[9] = ServerNew_Button09_Tips,
		[10] = ServerNew_Button10_Tips,
		[11] = ServerNew_Button11_Tips,
		[12] = ServerNew_Button12_Tips,
		[13] = ServerNew_Button13_Tips,	-- 新服Boss
		[14] = ServerNew_Button14_Tips,	--2023Q1新服欢乐月-喜迎财神到
		[15] = ServerNew_Button15_Tips,	-- 新服经验点Boss
	}
	
	g_ServerNew_XinChunFanLi_Button ={
		GIFT ={
			[1] = ServerNew_NewYear_Bk1_Button1,
			[2] = ServerNew_NewYear_Bk2_Button1,
			[3] = ServerNew_NewYear_Bk3_Button1,
			[4] = ServerNew_NewYear_Bk4_Button1,
			},
		GIFT1 ={
			[1] = ServerNew_NewYear_Bk1_Button2,
			[2] = ServerNew_NewYear_Bk2_Button2,
			[3] = ServerNew_NewYear_Bk3_Button2,
			[4] = ServerNew_NewYear_Bk4_Button2,
			},
		EXCH ={ 
			[1] = ServerNew_NewYear_Bk2_Button3,
			[2] = ServerNew_NewYear_Bk3_Button3,
			[3] = ServerNew_NewYear_Bk4_Button3, 
			},
	}
	
	g_ServerNew_XinChunFanLi_Text ={
		TEXT1 ={
			[1] = ServerNew_NewYear_Bk1_Text1,
			[2] = ServerNew_NewYear_Bk2_Text1,
			[3] = ServerNew_NewYear_Bk3_Text1,
			[4] = ServerNew_NewYear_Bk4_Text1,
			}, 
		TEXT2 ={ 
			[1] = ServerNew_NewYear_Bk1_Text2,
			[2] = ServerNew_NewYear_Bk2_Text2,
			[3] = ServerNew_NewYear_Bk3_Text2,
			[4] = ServerNew_NewYear_Bk4_Text2,
			},  
	}
	
	
	--红点
	g_XinChunFanLi_RedPointButton ={
		[1] = ServerNew_Button01_Tips,
		[2] = ServerNew_Button02_Tips,
		[3] = ServerNew_Button03_Tips,
		[4] = ServerNew_Button04_Tips,
		[5] = ServerNew_Button05_Tips,
		[6] = ServerNew_Button06_Tips,
		[7] = ServerNew_Button07_Tips,
		[8] = ServerNew_Button08_Tips,
		[9] = ServerNew_Button09_Tips,
		[10] = ServerNew_Button10_Tips,
		[11] = ServerNew_Button11_Tips,
		[12] = ServerNew_Button12_Tips,
	}
	g_ServerNew_XinChunFanLi_Icon = {
		[1] = {ServerNew_NewYear_Bk1_Icon1,ServerNew_NewYear_Bk1_Icon2,},
		[2] = {ServerNew_NewYear_Bk2_Icon1,ServerNew_NewYear_Bk2_Icon2,ServerNew_NewYear_Bk2_Icon3,},
		[3] = {ServerNew_NewYear_Bk3_Icon1,ServerNew_NewYear_Bk3_Icon2,ServerNew_NewYear_Bk3_Icon3,},
		[4] = {ServerNew_NewYear_Bk4_Icon1,ServerNew_NewYear_Bk4_Icon2,ServerNew_NewYear_Bk4_Icon3,},
	}
	if SystemSetup:IsClassic() == 0 then		--如果客户端是唯美版
		g_ServerNew_PrizeItemButtonIcon = "set:WM_CommonFrame1 image:Xin"
	end
	
end

------外框
--===============================================
-- Close()
--===============================================
function ServerNew_Close()
	g_EventIndex = -1
	ServerNew_Broadcast_Hide()
	this:Hide()
end

function ServerNew_Close_Clicked()
	ServerNew_Close()
end

function ServerNew_On_ResetPos()
	ServerNew_Frame:SetProperty("UnifiedPosition", g_ServerNew_Frame_UnifiedPosition)
end

function ServerNew_Open( )
	for index=1,table.getn(g_ServerNew_Event) do
		local event = g_ServerNew_Event[index]
		event.isShow = 0
	end

	--关闭所有红点
	for index = 1, table.getn(g_Broadcast_RedPointButton) do
		g_Broadcast_RedPointButton[index]:Hide()
	end
	
	local buttonId = 0
	for index=0,6 do
		local isShow = Get_XParam_INT(index)
		local event = g_ServerNew_Event[index+1]
		if isShow == 1 then
			buttonId = buttonId + 1
			g_ServerNew_Button[buttonId]:SetText(event.text)
			g_ServerNew_Button[buttonId]:Show()
			event.isShow = 1
		end
	end
	--双倍乐翻天特写下
	local dExp = Get_XParam_INT(7)
	local dPower = Get_XParam_INT(8)
	if dExp==1 or dPower==1 then
		local event = g_ServerNew_Event[8]
		buttonId = buttonId + 1
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		event.isShow = 1
	end
	g_ServerNew_Double[1] = dExp
	g_ServerNew_Double[2] = dPower
	
	--新服乐事记
	local broadcast = Get_XParam_INT(9)
	if broadcast == 1 then
		local event = g_ServerNew_Event[9]
		buttonId = buttonId + 1
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		g_Broadcast_RedPointPos = buttonId
		--红点控制
		if g_Broadcast_RedPoint == 1 then
			g_Broadcast_RedPointButton[g_Broadcast_RedPointPos]:Show()
		elseif g_Broadcast_RedPoint == 0 then
			g_Broadcast_RedPointButton[g_Broadcast_RedPointPos]:Hide()
		end
		event.isShow = 1
	end
	
	--新服欢乐月
	local showXFHLY = Get_XParam_INT(10)
	if showXFHLY == 1 then
		buttonId = buttonId + 1
		local event = g_ServerNew_Event[10]
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		event.isShow = 1
	end
	
	--豪情一掷
	local showHQYZ = Get_XParam_INT(11)
	if showHQYZ == 1 then
		buttonId = buttonId + 1
		local event = g_ServerNew_Event[11]
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		event.isShow = 1
		g_HQYZ_RedPointPos = buttonId
		ServerNew_HQYZ_UpdateRedPoint()
	end
	
	--新春享返利
	local showXCFL = Get_XParam_INT(12)
	if showXCFL == 1 then
		buttonId = buttonId + 1
		local event = g_ServerNew_Event[12]
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		event.isShow = 1
		
		g_XCFL_RedPointPos = buttonId
		--ServerNew_XinChunFanLi_UpdateRedPoint()
	end


	-- 新服Boss
	local bShowNewServerBoss = Get_XParam_INT(13)
	if bShowNewServerBoss == 1 then
		buttonId = buttonId + 1
		local event = g_ServerNew_Event[13]
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		event.isShow = 1
		
		-- g_XCFL_RedPointPos = buttonId
		--ServerNew_XinChunFanLi_UpdateRedPoint()
	end
	
	--2023Q1新服欢乐月-喜迎财神到
	local bShowNewServerXYCSD = Get_XParam_INT(14)
	if bShowNewServerXYCSD == 1 then
		buttonId = buttonId + 1
		local event = g_ServerNew_Event[14]
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		event.isShow = 1		
		g_XYCSD_RedPointPos = buttonId
		ServerNew_XYCSD_UpdateRedPoint(0)
	end

	-- 新服经验点Boss
	if 1 == Get_XParam_INT(15) then
		buttonId = buttonId + 1
		local event = g_ServerNew_Event[15]
		g_ServerNew_Button[buttonId]:SetText(event.text)
		g_ServerNew_Button[buttonId]:Show()
		event.isShow = 1
		
		-- g_XCFL_RedPointPos = buttonId
		--ServerNew_XinChunFanLi_UpdateRedPoint()
	end
		
	for index=buttonId+1, table.getn(g_ServerNew_Button) do 
		g_ServerNew_Button[index]:Hide()
	end
	ServerNew_Project_Clicked( 1 )
	--野外Boss排行需要提前请求数据
	local bFBRank = Get_XParam_INT(6)
	if bFBRank == 1 then
		g_FBrankGuildList:RemoveAllItem()
		ServerNew_FBRank_GetList()
	end
end

function ServerNew_Project_Clicked( clickId )
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
 	 	for index=1, table.getn(g_ServerNew_Button) do
			if index==g_LastClickedId then
				g_ServerNew_Button[index]:SetCheck(1)
			else
				g_ServerNew_Button[index]:SetCheck(0)
			end
		end
 	 	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end
	g_ButtonLastTime = curTime;
	
	local buttonId = 0
	for index=1, table.getn(g_ServerNew_Button) do
		local event = g_ServerNew_Event[index]
		if event.isShow == 1 then
			buttonId = buttonId + 1
			if buttonId == clickId then
				g_EventIndex = index
				break
			end
		end
	end

	for index=1, table.getn(g_ServerNew_Button) do
		if index==clickId then
			g_ServerNew_Button[index]:SetCheck(1)
		else
			g_ServerNew_Button[index]:SetCheck(0)
		end	
	end
	g_LastClickedId = clickId

	for index=1, table.getn(g_ServerNew_Button) do
		if index~=g_EventIndex then
			g_ServerNew_Frames[index]:Hide()
		end
	end
	
	--点击其他事件，关闭新服乐事记轮播
	if 9 ~= g_EventIndex then
		ServerNew_Broadcast_Hide()
	end
	
	if g_EventIndex==1 then
		ServerNew_LevelUp_OnShow() --升级有好礼
	elseif g_EventIndex==2 then
		ServerNew_SaveUp_OnShow()	--首充超值赠
	elseif g_EventIndex==3 then
		ServerNew_Paihang_Show()	--重楼献英豪
	elseif g_EventIndex==4 then
		ServerNew_Send_Show()			--豪情大派送
	elseif g_EventIndex==5 then
		ServerNew_FirstOne_Show()	--江湖第一人
	elseif g_EventIndex==6 then
		ServerNew_CSRank_Show()		--副本竞速榜
	elseif g_EventIndex==7 then
		ServerNew_FBRank_Show()	--匪首征讨榜
	elseif g_EventIndex==8 then
		ServerNew_DoubleExp_Show()	--双倍乐翻天
	elseif g_EventIndex==9 then
		--默认显示婚姻频道
		g_Broadcast_CurChannel = 1
		ServerNew_Broadcast_Show()	--新服乐事记
	elseif g_EventIndex==10 then
		ServerNew_NewServerHappy_Show()	--新服欢乐月
	elseif g_EventIndex==11 then
		ServerNew_HQYZ_Show()	--豪情一掷
	elseif g_EventIndex==12 then
		ServerNew_XinChunFanLi_Show()	--新春享返利
	elseif g_EventIndex==13 then
		ServerNew_Boss_Show()	-- 新服Boss
	elseif g_EventIndex==14 then
		ServerNew_XYCSD_Show()	--2023Q1新服欢乐月-喜迎财神到
	elseif g_EventIndex==15 then
		ServerNew_JingYanDianBoss_Show()	-- 新服经验点Boss
	else
		return
	end
	this:Show()
end
------外框

--=========================================================
-- 新服Boss 展示本页签
-- !!!reloadscript =ServerNew
--=========================================================
function ServerNew_Boss_Show()
	ServerNew_BossDropFrame : Show()
end

--=========================================================
-- 新服经验点Boss 展示本页签
-- !!!reloadscript =ServerNew
--=========================================================
function ServerNew_JingYanDianBoss_Show()
	ServerNew_ExpPoint_RewardFrame : Show()
	
	local IsPVPNoPunishOpen,PVPNoPunishOpenTime,PVPNoPunishEndTime = DataPool:Lua_IsXinFuPVPNoPunishEXPOpen()
	ServerNew_ExpPoint_QX_Frame:Hide()
	if IsPVPNoPunishOpen == 1 then
		ServerNew_ExpPoint2_Frame:Hide()
		ServerNew_ExpPoint_Frame:Show()
	else
		ServerNew_ExpPoint2_Frame:Show()
		ServerNew_ExpPoint_Frame:Hide()
	end 

	if Player:GetData("Is2606S") == 1 then
		ServerNew_ExpPoint_QX_Frame:Show()
		ServerNew_ExpPoint2_Frame:Hide()
		ServerNew_ExpPoint_Frame:Hide()
	end
	local bOpen, nOpenTime, nEndTime = DataPool:Lua_GetNewServerJingYanDianBossTime()

	local nOpenYear = math.floor(nOpenTime / 10000)
	local nTemp = math.mod(nOpenTime, 10000)
	local nOpenMonth = math.floor(nTemp / 100)
	local nOpenDay = math.mod(nTemp, 100)

	local nEndYear = math.floor(nEndTime / 10000)
	local nTemp2 = math.mod(nEndTime, 10000)
	local nEndMonth = math.floor(nTemp2 / 100)
	local nEndDay = math.mod(nTemp2, 100)

	ServerNew_ExpPoint_Info : SetText(ScriptGlobal_Format("#{JYTM_20230302_2}", nOpenYear, nOpenMonth, nOpenDay, nEndYear, nEndMonth, nEndDay))
	ServerNew_ExpPoint2_Info : SetText(ScriptGlobal_Format("#{PKPK_20251119_1}", nOpenYear, nOpenMonth, nOpenDay, nEndYear, nEndMonth, nEndDay))
	if Player:GetData("Is2606S") == 1 then 
		local nQXOpenYear = math.floor(PVPNoPunishOpenTime / 10000)
		local nQXTemp = math.mod(PVPNoPunishOpenTime, 10000)
		local nQXOpenMonth = math.floor(nQXTemp / 100)
		local nQXOpenDay = math.mod(nQXTemp, 100)

		local nQXEndYear = math.floor(PVPNoPunishEndTime / 10000)
		local nQXTemp2 = math.mod(PVPNoPunishEndTime, 10000)
		local nQXEndMonth = math.floor(nQXTemp2 / 100)
		local nQXEndDay = math.mod(nQXTemp2, 100)
		ServerNew_ExpPoint_QX_Info:SetText(ScriptGlobal_Format("#{QXFXG_260703_8}", nQXOpenYear, nQXOpenMonth, nQXOpenDay, nQXEndYear, nQXEndMonth, nQXEndDay))
	end 
end

--=========================================================
--2023Q1新服欢乐月-喜迎财神到
-- !!!reloadscript =ServerNew
--=========================================================
function ServerNew_XYCSD_Show()
	ServerNew_XYCSD_Init()
	ServerNew_XYCSD_AskData()
	ServerNew_XYCSDFrame : Show()
end
function ServerNew_XYCSD_AskData()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateUI" )
		Set_XSCRIPT_ScriptID( 998407 )
		Set_XSCRIPT_Parameter( 0,1 )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end
function ServerNew_XYCSD_Init()
	ServerNew_XYCSD_RewardFrame:Show()
	--财神宠物图片--默认未找到
	ServerNew_XYCSD_CaiShenImage1:Show()
	ServerNew_XYCSD_CaiShenImage2:Hide()
	--特殊奖励
	local nStartTime, _ = DataPool:Lua_XFXYCSDTime()
	local nDifDay = DataPool:GetDifDayWithServerTime(nStartTime)
	local nDayIndex = math.mod(nDifDay,7)+1
	if g_XYCSD_SpecialPrizeList[nDayIndex] ~= nil then
		local theAction1 = DataPool:CreateBindActionItemForShow(g_XYCSD_SpecialPrizeList[nDayIndex][1], 1)
		if theAction1:GetID() ~= 0 then
			ServerNew_XYCSD_RewardItem1:SetActionItem(theAction1:GetID())
		end
		local theAction2 = DataPool:CreateBindActionItemForShow(g_XYCSD_SpecialPrizeList[nDayIndex][2], 1)
		if theAction2:GetID() ~= 0 then
			ServerNew_XYCSD_RewardItem10:SetActionItem(theAction2:GetID())
		end
	end
	--奖池数据
	local g_XYCSD_Icon = 
	{
		ServerNew_XYCSD_RewardItem2,ServerNew_XYCSD_RewardItem3,ServerNew_XYCSD_RewardItem4,ServerNew_XYCSD_RewardItem5,
		ServerNew_XYCSD_RewardItem6,ServerNew_XYCSD_RewardItem7,ServerNew_XYCSD_RewardItem8,ServerNew_XYCSD_RewardItem9,		
	}	
	for i=1,table.getn(g_XYCSD_Icon) do
		local theAction = DataPool:CreateBindActionItemForShow(g_XYCSD_ItemList[i][1], g_XYCSD_ItemList[i][2])
		if theAction:GetID() ~= 0 then
			g_XYCSD_Icon[i]:SetActionItem(theAction:GetID())
		end
	end
end
function ServerNew_XYCSD_Update(bShow)
	--财神宠物图片
	if bShow == 1 then--已找到
		ServerNew_XYCSD_CaiShenImage1:Hide()
		ServerNew_XYCSD_CaiShenImage2:Show()
	else--未找到
		ServerNew_XYCSD_CaiShenImage1:Show()
		ServerNew_XYCSD_CaiShenImage2:Hide()
	end
end
function ServerNew_XYCSD_UpdateRedPoint(redPoint)
	if g_XYCSD_RedPointPos < 0 then
		return
	end	
	local nLevel = Player : GetLevel()
	if nLevel < 30 then
		g_Broadcast_RedPointButton[g_XYCSD_RedPointPos]:Hide()
		return
	end	
	if redPoint == 1 then
		g_Broadcast_RedPointButton[g_XYCSD_RedPointPos]:Show()
	else
		g_Broadcast_RedPointButton[g_XYCSD_RedPointPos]:Hide()
	end
end
function ServerNew_XYCSD_OnClickHelp()
	PushEvent("CCSHOP_HELP", 182)
end

--=========================================================
-- 新服Boss 帮助按钮
--=========================================================
function ServerNew_Boss_OnClickHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelp" )
		Set_XSCRIPT_ScriptID(810010)			
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--=========================================================
-- 新服经验点Boss 帮助按钮
--=========================================================
function ServerNew_JingYanDianBoss_OnClickHelp(nHelpIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelp" )
		Set_XSCRIPT_ScriptID(790095)			
		Set_XSCRIPT_Parameter(0, nHelpIndex)		
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--副本竞速排行榜开始
--领奖
function ServerNew_CSRank_Clicked( clickId )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskPrize")  
		Set_XSCRIPT_ScriptID(890912) 
		Set_XSCRIPT_Parameter(0,clickId);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function ServerNew_CSRank_DetailsClicked( clickId )
	PushEvent( "GE_CSRANK_SMALL", clickId)	
end
--显示（师姐调这个）
function ServerNew_CSRank_Show( )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskRankList")  
		Set_XSCRIPT_ScriptID(890912) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--刷新
function ServerNew_CSRank_OnRefresh()
	ServerNew_CSRank_Clear()
	local maxIndex = g_KajiTable_RHM[2][0]
	local kajiType = KaJi:LuaFnGetKaJiType(15)
	if nil~=kajiType and nil~=g_KajiTable_RHM[2][kajiType]  then
		maxIndex = g_KajiTable_RHM[2][kajiType] 
	end
	if maxIndex < 1 or maxIndex > 3 then
		maxIndex = 3
	end
	for i=1,3 do
		if i <= maxIndex then
			g_CSRankBKFrame[i]:Show()
		else
			g_CSRankBKFrame[i]:Hide()
		end
	end
	for i=1,3 do
		local nDate,
		nUseTime,
		szCharName,
		nMenpai,
		nLevel	= WenDingUI:GetCSRankByIdx( (i-1)*6 )
		
		local min=math.floor(nUseTime/60)
		local sec=math.mod(nUseTime,60)
		local year=math.floor(nDate/10000)
		local month=math.mod(math.floor(nDate/100),100)
		local day=math.mod(nDate,100)
		
		if szCharName ~= "" then
			g_CSRankInfo[i].usetime:SetText(min.."分"..sec.."秒");
			g_CSRankInfo[i].leadericon:Show();
			g_CSRankInfo[i].name[1]:SetText(szCharName);
			g_CSRankInfo[i].blank:SetText("");
			for j=2,6 do
				local nDateMember,
				nUseTimeMember,
				szCharNameMember,
				nMenpaiMember,
				nLevelMember	= WenDingUI:GetCSRankByIdx( (i-1)*6+j-1 )
				if szCharNameMember ~= "" then
					g_CSRankInfo[i].name[j]:SetText(szCharNameMember);
				else
					break
				end
			end
		end
				
	end
	
	local theAction = DataPool:CreateActionItemForShow(39920396, 1)
	if theAction:GetID() ~= 0 then
		ServerNew_Velocity_JJFrame_Icon5:SetActionItem(theAction:GetID());
	end
	theAction = DataPool:CreateActionItemForShow(39920397, 1)
	if theAction:GetID() ~= 0 then
		ServerNew_Velocity_JJFrame_Icon6:SetActionItem(theAction:GetID());
	end
	
	local eStartTime,eEndTime = DataPool:Lua_GetFubenRankTime()
	local deStartYear = math.floor(eStartTime/10000)
	local deStartMon = math.mod(math.floor(eStartTime/100),100)
	local deStartDay = math.mod(eStartTime,100)
	local deEndYear = math.floor(eEndTime/10000)
	local deEndMon = math.mod(math.floor(eEndTime/100),100)
	local deEndDay = math.mod(eEndTime,100)

	local strText = g_KajiTable_RHM[1][0]
	if nil~=kajiType and nil~=g_KajiTable_RHM[1][kajiType]  then
		strText = g_KajiTable_RHM[1][kajiType] 
	end
	ServerNew_Velocity_Info:SetText(ScriptGlobal_Format(strText,deStartYear,deStartMon,deStartDay,deEndYear,deEndMon,deEndDay))
	if g_EventIndex == 6 then
		ServerNew_Velocity_RewardFrame:Show()
	end
end
--清空
function ServerNew_CSRank_Clear()
	for i=1,3 do
		g_CSRankInfo[i].usetime:SetText("");
		g_CSRankInfo[i].leadericon:Hide()
		g_CSRankInfo[i].name[1]:SetText("");
		g_CSRankInfo[i].name[2]:SetText("");
		g_CSRankInfo[i].name[3]:SetText("");
		g_CSRankInfo[i].name[4]:SetText("");
		g_CSRankInfo[i].name[5]:SetText("");
		g_CSRankInfo[i].name[6]:SetText("");
		g_CSRankInfo[i].blank:SetText("虚位以待");
	end
end
--隐藏（师姐调这个）
function ServerNew_CSRank_Hide( )
	ServerNew_Velocity_RewardFrame:Hide()
end
--副本竞速排行榜结束

---江湖第一begin
--显示（师姐调这个）
function ServerNew_FirstOne_Show( )
	AskServerNew_FirstOne()
end

function ServerNew_FirstOne_Open( )
	local rank,name,level,menpai,sex
	for index=0,0 do			--这里只要全服第一的数据
		rank,name,level,menpai,sex = DataPool:Lua_TianXiaDiYi_Data(index)
		if name==nil or name=="" or level==nil or level==0 or menpai==nil or menpai==-1 then
			g_ServerNew_FirstOne_L_Name[index+1]:SetText("#{MPDYR_140919_21}")
			g_ServerNew_FirstOne_L_Level[index+1]:SetText("")
			g_ServerNew_FirstOne_L_Menpai[index+1]:SetText("")
		else
			local menpaiName = ServerNew_GetMenpai(menpai)
			g_ServerNew_FirstOne_L_Name[index+1]:SetText("#G"..tostring(name))
			g_ServerNew_FirstOne_L_Level[index+1]:SetText( "#G"..tostring(level).."级" )
			g_ServerNew_FirstOne_L_Menpai[index+1]:SetText("#G"..tostring(menpaiName))
		end
	end
	for index=0, table.getn(g_ServerNew_FirstOne_MenpaiID) - 1 do
		local menpaiId = g_ServerNew_FirstOne_MenpaiID[index+1]
		name,level,menpai,sex = DataPool:Lua_MenPaiDiYi_Data(menpaiId)
		if name==nil or name=="" or level==nil or level==0 or menpai==nil or menpai==-1 then
			g_ServerNew_FirstOne_R_Name[index+1]:SetText("#{MPDYR_140919_21}")
			g_ServerNew_FirstOne_R_Level[index+1]:SetText("")
			--g_ServerNew_FirstOne_R_Menpai[index+1]:SetText("")
		else
			local menpaiName = ServerNew_GetMenpai(menpai)
			g_ServerNew_FirstOne_R_Name[index+1]:SetText("#G"..tostring(name))
			g_ServerNew_FirstOne_R_Level[index+1]:SetText( "#{MPDYR_140919_43}".."#G"..tostring(level) )
			--g_ServerNew_FirstOne_R_Menpai[index+1]:SetText(tostring(menpaiName))
		end
	end
	local startTime,endTime,awardTime = DataPool:Lua_GetFirstManTime()
	local stTimeShow = ServerNew_TimeStr(startTime)
	local endTimeShow = ServerNew_TimeStr(endTime)
	local enTimeShowNoYear = ServerNew_TimeStrNoYear(endTime)
	local awTimeShowNoYear = ServerNew_TimeStrNoYear(awardTime)
	local text = ScriptGlobal_Format("#{MPDYR_140919_1}", stTimeShow,endTimeShow,enTimeShowNoYear,awTimeShowNoYear)
	ServerNew_FirstOne_T_Text:SetText(text)

	local g_ServerNew_FirstOne_BK = {
		ServerNew_FirstOne_R_P1_BK1, ServerNew_FirstOne_R_P1_BK5, ServerNew_FirstOne_R_P1_BK9, ServerNew_FirstOne_R_P1_BK2, ServerNew_FirstOne_R_P1_BK6,
		ServerNew_FirstOne_R_P1_BK10, ServerNew_FirstOne_R_P1_BK3, ServerNew_FirstOne_R_P1_BK7, ServerNew_FirstOne_R_P1_BK11, ServerNew_FirstOne_R_P1_BK4,
		ServerNew_FirstOne_R_P1_BK8, ServerNew_FirstOne_R_P1_BK12, ServerNew_FirstOne_R_P1_BK13, ServerNew_FirstOne_R_P1_BK14, ServerNew_FirstOne_R_P1_BK15 
	}

	local selfzoneid = DataPool:GetSelfZoneWorldID()
	for index = 0, table.getn(g_ServerNew_FirstOne_MenpaiID) - 1 do
		local menpaiId = g_ServerNew_FirstOne_MenpaiID[index+1]
		if Lua_IsCJDingZhiMenPaiOpen(selfzoneid, menpaiId) == 1 then
			g_ServerNew_FirstOne_BK[index+1]:Show()
		else
			g_ServerNew_FirstOne_BK[index+1]:Hide()
		end
	end
		
	if g_EventIndex == 5 then
		ServerNew_FirstOne_RewardFrame:Show()
	end
end

--获取天下第一的奖励
function ServerNew_FirstOne_L_GetPrize( )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "TianXiaFirst_GetPrize" ); 	-- 函数名
		Set_XSCRIPT_ScriptID( 890934 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end

--获取门派第一的奖励
function ServerNew_FirstOne_R_GetPrize( )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "MenPaiFirst_GetPrize" ); 	-- 函数名
		Set_XSCRIPT_ScriptID( 890934 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end

--隐藏（师姐调这个）
function ServerNew_FirstOne_Hide( )
	ServerNew_FirstOne_RewardFrame:Hide()
end
---江湖第一end

--双倍乐翻天begin
--显示（师姐调这个）
function ServerNew_DoubleExp_Show( )
	--双倍经验的时间
	local eStartTime,eEndTime = DataPool:Lua_DoubleExpTime()
	local deStartYear = math.floor(eStartTime/10000)
	local deStartMon = math.mod(math.floor(eStartTime/100),100)
	local deStartDay = math.mod(eStartTime,100)
	local deEndYear = math.floor(eEndTime/10000)
	local deEndMon = math.mod(math.floor(eEndTime/100),100)
	local deEndDay = math.mod(eEndTime,100)
	
	--双倍功力值的时间
	local pStartTime,pEndTime = DataPool:Lua_GetPowfixTime()
	local dpStartYear = math.floor(pStartTime/10000)
	local dpStartMon = math.mod(math.floor(pStartTime/100),100)
	local dpStartDay = math.mod(pStartTime,100)
	local dpEndYear = math.floor(pEndTime/10000)
	local dpEndMon = math.mod(math.floor(pEndTime/100),100)
	local dpEndDay = math.mod(pEndTime,100)
	local powfixValue = DataPool:Lua_GetPowfixValue()

	local dexpText = ScriptGlobal_Format("#{MPDYR_140919_38}", deStartYear,deStartMon,deStartDay,deEndYear,deEndMon,deEndDay)
	local dpowerText = ScriptGlobal_Format("#{MPDYR_140919_39}", dpStartYear,dpStartMon,dpStartDay,dpEndYear,dpEndMon,dpEndDay,powfixValue)
	
	if g_ServerNew_Double[1]==1 and g_ServerNew_Double[2]==1 then
		ServerNew_DoubleExp_T_Text:SetText(dexpText)
		ServerNew_DoubleExp_B_Text:SetText(dpowerText)
		ServerNew_DoubleExp_T_Icon_01 : SetProperty("Image","set:XFHLY01 image:XFHLY01_L")
		ServerNew_DoubleExp_T_Icon_02 : SetProperty("Image","set:XFHLY01 image:XFHLY01_R")
		ServerNew_DoubleExp_B_Icon_01 : SetProperty("Image","set:XFHLY02 image:XFHLY02_L")
		ServerNew_DoubleExp_B_Icon_02 : SetProperty("Image","set:XFHLY02 image:XFHLY02_R")
		ServerNew_DoubleExp_T:Show()
		ServerNew_DoubleExp_B:Show()
	elseif g_ServerNew_Double[1]==1 and g_ServerNew_Double[2]~=1 then
		ServerNew_DoubleExp_T_Text:SetText(dexpText)
		ServerNew_DoubleExp_T_Icon_01 : SetProperty("Image","set:XFHLY01 image:XFHLY01_L")
		ServerNew_DoubleExp_T_Icon_02 : SetProperty("Image","set:XFHLY01 image:XFHLY01_R")
		ServerNew_DoubleExp_T:Show()
		ServerNew_DoubleExp_B:Hide()
	elseif g_ServerNew_Double[1]~=1 and g_ServerNew_Double[2]==1 then
		ServerNew_DoubleExp_T_Text:SetText(dpowerText)
		ServerNew_DoubleExp_T_Icon_01 : SetProperty("Image","set:XFHLY02 image:XFHLY02_L")
		ServerNew_DoubleExp_T_Icon_02 : SetProperty("Image","set:XFHLY02 image:XFHLY02_R")
		ServerNew_DoubleExp_T:Show()
		ServerNew_DoubleExp_B:Hide()
	else
		ServerNew_DoubleExp_T:Hide()
		ServerNew_DoubleExp_B:Hide()
	end
	if g_EventIndex == 8 then
		ServerNew_DoubleExp_RewardFrame:Show()
	end
end

function ServerNew_NewServerHappy_Show()
	if g_EventIndex == 10 then
		ServerNew_NewServerIntoFrame:Show()
	end
end

--隐藏（师姐调这个）
function ServerNew_DoubleExp_Hide( )
	ServerNew_DoubleExp_RewardFrame:Hide()
end
--双倍乐翻天end


--【新服欢乐月·首充超值增】Begin
--**********************************
-- 界面显示函数
--**********************************
function ServerNew_SaveUp_OnShow()
	ServerNew_SaveUp_UpdateButtonReq();						-- 在服务器数据返回之前,先根据默认初始值刷新一次界面
	ServerNew_SaveUp_FlushWindow()						
end

--**********************************
-- 请求更新Btn状态
--**********************************
function ServerNew_SaveUp_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateInfo" ); 				-- 脚本号
		Set_XSCRIPT_ScriptID( 890997 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()

end

--**********************************
-- 更新Btn状态
--**********************************
function ServerNew_SaveUp_FlushWindow()
	if g_ServerNew_SaveUp_LoadFirstTime == 1 then
		--将物品奖励加载到页面显示
		for i = 1,  table.getn(g_ServerNew_SaveUp_GiftsIcons) do
			for j = 1, table.getn(g_ServerNew_SaveUp_GiftsIcons[i]) do
				local	GiftItemID	=	-1
				local	GiftItemNum	=	0
				if j > table.getn( g_ServerNew_SaveUp_Gifts[i] ) then
					g_ServerNew_SaveUp_GiftsIcons[i][j]:Hide();
				else
					GiftItemID	=	g_ServerNew_SaveUp_Gifts[i][j].GiftItemID
					GiftItemNum	= 	g_ServerNew_SaveUp_Gifts[i][j].num
					local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
					if theAction:GetID() ~= 0 then
						if g_ServerNew_SaveUp_Gifts[i][j].new ~= nil and g_ServerNew_SaveUp_Gifts[i][j].new == 1 then
							g_ServerNew_SaveUp_GiftsIconImages[i][j] : SetProperty("Image",g_ServerNew_PrizeItemButtonIcon);
						end
						g_ServerNew_SaveUp_GiftsIcons[i][j]:SetActionItem(theAction:GetID());
						g_ServerNew_SaveUp_GiftsIcons[i][j]:Show();
					end
				end
			end
		end
		--设置领取的按钮全都为不可用
		for i = 1, 6 do
			g_ServerNew_SaveUp_GetGiftsButtonList[i]:SetProperty("Disabled", "True");
		end
		g_ServerNew_SaveUp_LoadFirstTime = 0
	end

	--设置界面上显示的活动起止时间
	local BeginDate,EndDate = DataPool:Lua_GetYuanBaoCostGiftTime()

	local InfoText = ScriptGlobal_Format("#{SJSHL_140919_29}",ServerNew_TimeStr(BeginDate),ServerNew_TimeStr(EndDate))

	ServerNew_SaveUp_Info:SetText( InfoText )
	

	--先设置所有Button的状态为:"已领取"或者"未领取",或者"未领取"
	for i = 1, table.getn(g_ServerNew_SaveUp_GetGiftsButtonList) - 1 do
		if g_ServerNew_SaveUpBtnState[i] == 2 then		--状态为【已领取】
			g_ServerNew_SaveUp_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
			g_ServerNew_SaveUp_GetGiftsButtonList[i] : Disable()
		elseif g_ServerNew_SaveUpBtnState[i] == 0 then		--状态为【未达成】
			g_ServerNew_SaveUp_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
			g_ServerNew_SaveUp_GetGiftsButtonList[i] : Disable()
		elseif g_ServerNew_SaveUpBtnState[i] == 1 then		--状态为【可以领取】
			g_ServerNew_SaveUp_GetGiftsButtonList[i] : Enable()
		end
	end
	--对于限时奖励,需要特殊处理一些
	local TimeLimitGiftIndex = table.getn(g_ServerNew_SaveUp_GetGiftsButtonList) 
	local TimeLimitGiftState = g_ServerNew_SaveUpBtnState[TimeLimitGiftIndex]
	if TimeLimitGiftState == -4 then				--已经超出时限
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : Disable()
		--设置文字:已超出时限
		ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetText("#{SJSHL_140919_92}")
	elseif TimeLimitGiftState == -3 then				--已经领取了
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : Disable()
		ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetText("#{SJSHL_140919_91}")
	elseif TimeLimitGiftState == -2 then				--倒计时未开始
		ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetText("#{SJSHL_140919_40}")
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : Disable()
	elseif TimeLimitGiftState == -1 then				--倒计时结束,可以领取
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : Enable()
		ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetText("#{SJSHL_140919_91}")
	else								--在倒计时时间内,设置倒计时文字
		--需要设置倒计时文字
		local LimitHour	  = math.floor(TimeLimitGiftState/(3600))
		local LimitMinute = math.floor(math.mod(TimeLimitGiftState,3600)/60)
		if LimitHour > 0 then
			ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetText("#{SJSHL_140919_90}"..LimitHour.."时"..LimitMinute.."分钟")
		elseif LimitMinute > 0 then
			ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetText("#{SJSHL_140919_90}"..LimitMinute.."分钟")
		elseif LimitMinute == 0 then
			ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetText("#{SJSHL_140919_90}小于1分钟")
		end
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
		g_ServerNew_SaveUp_GetGiftsButtonList[TimeLimitGiftIndex] : Disable()
	end

	--策划补充,需要根据奖励完成情况,显示界面上的奖励提示 =...=
	for i = 1, table.getn(g_ServerNew_SaveUp_NotifyTipsControlList) do
		if i == 1 then		--首充好礼特写
			if g_ServerNew_SaveUpBtnState[i] == 0 then	--条件尚未满足
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : SetText("#{SJSHL_140919_84}");
			else
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : SetText("#{SJSHL_140919_85}");
			end
		elseif i == 6 then 	--限时好礼特写
			if g_ServerNew_SaveUpBtnState[i] == -4 then 			--已经超时,计算数值也没有意义,直接隐藏
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : Hide()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchAmount : Hide()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostText : Hide()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostAmount : Hide()
				--还要把已经超时的提示语移到中间
				ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetProperty("UnifiedPosition","{{0.000000,5.000000},{0.000000,19.000000}}")
			elseif 	g_ServerNew_SaveUpBtnState[i] == -2 then		--计时未开始,显示红色的警示字体
				local strTemp = ScriptGlobal_Format("#{SJSHL_140919_97}",0, g_ServerNew_SaveUp_GetGiftsCondition[i].Exch)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : SetText("#{SJSHL_140919_93}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchAmount : SetText(strTemp);
				strTemp = ScriptGlobal_Format("#{SJSHL_140919_97}",0, g_ServerNew_SaveUp_GetGiftsCondition[i].Cost)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostText : SetText("#{SJSHL_140919_94}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostAmount : SetText(strTemp);
				--数值需要显示,提示语回到原位
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : Show()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchAmount : Show()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostText : Show()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostAmount : Show()
				ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetProperty("UnifiedPosition","{{0.000000,5.000000},{0.000000,3.000000}}")
			else
				local YuanBaoExchStr = 0
				if g_ServerNew_SaveUp_YuanBaoExch > g_ServerNew_SaveUp_GetGiftsCondition[i].Exch then
					YuanBaoExchStr = g_ServerNew_SaveUp_GetGiftsCondition[i].Exch
				else
					YuanBaoExchStr = g_ServerNew_SaveUp_YuanBaoExch
				end
				local YuanBaoCostStr = 0
				if g_ServerNew_SaveUp_YuanBaoCost > g_ServerNew_SaveUp_GetGiftsCondition[i].Cost then
					YuanBaoCostStr = g_ServerNew_SaveUp_GetGiftsCondition[i].Cost
				else
					YuanBaoCostStr = g_ServerNew_SaveUp_YuanBaoCost
				end
				local strTemp = ScriptGlobal_Format("#{SJSHL_140919_98}",YuanBaoExchStr, g_ServerNew_SaveUp_GetGiftsCondition[i].Exch)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : SetText("#{SJSHL_140919_95}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchAmount : SetText(strTemp);
				strTemp = ScriptGlobal_Format("#{SJSHL_140919_98}",YuanBaoCostStr, g_ServerNew_SaveUp_GetGiftsCondition[i].Cost)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostText : SetText("#{SJSHL_140919_96}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostAmount : SetText(strTemp);
				--数值需要显示,提示语回到原位
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : Show()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchAmount : Show()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostText : Show()
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostAmount : Show()
				ServerNew_SaveUp_Frame3_Bk6_Text1_0 : SetProperty("UnifiedPosition","{{0.000000,5.000000},{0.000000,3.000000}}")
			end
		else							--通用逻辑
			--1.设置元宝消耗的满足情况
			if g_ServerNew_SaveUp_YuanBaoCost < g_ServerNew_SaveUp_GetGiftsCondition[i].Cost then
				strTemp = ScriptGlobal_Format("#{SJSHL_140919_97}",g_ServerNew_SaveUp_YuanBaoCost, g_ServerNew_SaveUp_GetGiftsCondition[i].Cost)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostText : SetText("#{SJSHL_140919_94}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostAmount : SetText(strTemp);
			else
				strTemp = ScriptGlobal_Format("#{SJSHL_140919_98}",g_ServerNew_SaveUp_GetGiftsCondition[i].Cost, g_ServerNew_SaveUp_GetGiftsCondition[i].Cost)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostText : SetText("#{SJSHL_140919_96}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].CostAmount : SetText(strTemp);
			end
			--2.设置元宝兑换的满足情况
			if g_ServerNew_SaveUp_YuanBaoExch < g_ServerNew_SaveUp_GetGiftsCondition[i].Exch then
				local strTemp = ScriptGlobal_Format("#{SJSHL_140919_97}",g_ServerNew_SaveUp_YuanBaoExch, g_ServerNew_SaveUp_GetGiftsCondition[i].Exch)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : SetText("#{SJSHL_140919_93}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchAmount : SetText(strTemp);
			else
				local strTemp = ScriptGlobal_Format("#{SJSHL_140919_98}",g_ServerNew_SaveUp_GetGiftsCondition[i].Exch, g_ServerNew_SaveUp_GetGiftsCondition[i].Exch)
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchText : SetText("#{SJSHL_140919_95}");
				g_ServerNew_SaveUp_NotifyTipsControlList[i].ExchAmount : SetText(strTemp);
			end
		end
	end
	if g_EventIndex == 2 then
		ServerNew_SaveUp_RewardFrame : Show();
	end
end

--********************************************************************
-- 按钮,客户端界面"领取奖励"按钮点击响应事件函数
--********************************************************************
function ServerNew_SaveUp_Frame3_GetGift( nIndex )
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForCostYuanBao" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 890997 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end
--【新服欢乐月·首充超值增】End

--【新服欢乐月·升级送好礼】Begin
--**********************************
-- 更新Data
--**********************************
function ServerNew_LevelUp_OnShow()
	ServerNew_LevelUp_UpdateButtonReq();
	ServerNew_LevelUp_FlushWindow()		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end

--**********************************
-- 请求更新Btn状态
--**********************************
function ServerNew_LevelUp_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 890996 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()

end


--**********************************
-- 【新服欢乐月·升级送好礼】刷新界面
--**********************************
function ServerNew_LevelUp_FlushWindow()
	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_ServerNew_LevelUp_LoadFirstTime == 1 then
		for i = 1,  table.getn(g_ServerNew_LevelUp_GiftsIcons) do
			for j = 1, table.getn(g_ServerNew_LevelUp_GiftsIcons[i]) do
				local	GiftItemID	=	-1
				local	GiftItemNum	=	0
				if j > table.getn( g_ServerNew_LevelUp_Gifts[i] ) then
					g_ServerNew_LevelUp_GiftsIcons[i][j]:Hide();
				else
					GiftItemID	=	g_ServerNew_LevelUp_Gifts[i][j].GiftItemID
					GiftItemNum	= 	g_ServerNew_LevelUp_Gifts[i][j].num
					local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
					if theAction:GetID() ~= 0 then
						if g_ServerNew_LevelUp_Gifts[i][j].new ~= nil and g_ServerNew_LevelUp_Gifts[i][j].new == 1 then
							g_ServerNew_LevelUp_GiftsIconsImages[i][j] : SetProperty("Image",g_ServerNew_PrizeItemButtonIcon);
						end
						g_ServerNew_LevelUp_GiftsIcons[i][j]:SetActionItem(theAction:GetID());
						g_ServerNew_LevelUp_GiftsIcons[i][j]:Show();
					end
				end
			end
		end
		g_ServerNew_LevelUp_LoadFirstTime = 0
	end

	local nLevel = Player : GetLevel();

	local LevelGrade = 1;

	for i = 1,table.getn(g_ServerNew_LevelUp_GetGiftLevel)  do
		if nLevel < g_ServerNew_LevelUp_GetGiftLevel[i] then
			LevelGrade = i
			break
		end
	end

	--获取活动起止时间
	local BeginDate,EndDate = DataPool:Lua_GetLevelUpGiftTime()
	
	--设置【新服欢乐月·升级送好礼】界面提示语
	if g_ServerNew_LevelUp_PageIndex == 1 then
		ServerNew_LevelUp_Info : SetText(ScriptGlobal_Format("#{SJSHL_140919_4}",ServerNew_TimeStr(BeginDate),ServerNew_TimeStr(EndDate)));
	else

		ServerNew_LevelUp_Info : SetText(ScriptGlobal_Format("#{SJSHL_140919_5}",ServerNew_TimeStr(BeginDate),ServerNew_TimeStr(EndDate)));
	end
	--先设置所有可以领取的Button的状态为:"已领取"或者"未领取"
	for i = 1, LevelGrade - 1 do
		if g_ServerNew_LevelUpBtnState[i] == 1 then
			--设置按钮图片为已领取
			g_ServerNew_LevelUp_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
			g_ServerNew_LevelUp_GetGiftsButtonList[i] : Disable()
		else
			g_ServerNew_LevelUp_GetGiftsButtonList[i] : Enable()
		end
	end

	for i = LevelGrade, table.getn(g_ServerNew_LevelUp_GetGiftsButtonList) do
			--设置未达成的Button
			g_ServerNew_LevelUp_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
			g_ServerNew_LevelUp_GetGiftsButtonList[i] : Disable()
	end

	local	ShowIndexBegin = 0
	local 	ShowIndexEnd   = 0
	local   HideIndexBegin = 0
	local   HideIndexEnd   = 0
	if g_ServerNew_LevelUp_PageIndex == 1 then
		ShowIndexBegin = 1
		ShowIndexEnd   = 8
		HideIndexBegin = 9
		HideIndexEnd   = 13
	else
		ShowIndexBegin = 9
		ShowIndexEnd   = 13
		HideIndexBegin = 1
		HideIndexEnd   = 8
	end

	--设置当前页面的[按钮]和图标为可见
	for i = ShowIndexBegin, ShowIndexEnd do
		for j = 1, table.getn(g_ServerNew_LevelUp_Gifts[i]) do
			g_ServerNew_LevelUp_GiftsIcons[i][j] : Show();
		end
	end
	for i = ShowIndexBegin, ShowIndexEnd do
		g_ServerNew_LevelUp_GetGiftsButtonList[i] : Show();
		--g_ServerNew_LevelUp_Frames[i] : SetProperty("AlwaysOnTop","True")
		g_ServerNew_LevelUp_Frames[i] : Show()
	end

	--设置另一页面的[按钮]和图标为不可见
	for i = HideIndexBegin, HideIndexEnd do
		for j = 1, table.getn(g_ServerNew_LevelUp_GiftsIcons[i]) do
			g_ServerNew_LevelUp_GiftsIcons[i][j] : Hide();
		end
	end
	for i = HideIndexBegin, HideIndexEnd do
		g_ServerNew_LevelUp_GetGiftsButtonList[i] : Hide();
		--g_ServerNew_LevelUp_Frames[i] : SetProperty("AlwaysOnTop","False")
		g_ServerNew_LevelUp_Frames[i] : Hide()
	end

	if g_EventIndex == 1 then
		ServerNew_LevelUp_RewardFrame:Show()
	end
end
--********************************************************************
-- 按钮,客户端界面"领取奖励"按钮点击响应事件函数
--********************************************************************
function ServerNew_LevelUp_Frame3_GetGift( nIndex )
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--1.检测玩家的等级是否到达可领奖的等级
	local nLevel = Player : GetLevel()
	if nLevel < g_ServerNew_LevelUp_GetGiftLevel[nIndex] then
		PushDebugMessage("#{SJSHL_140919_24}")					--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end
	--2.玩家是否未领取该奖励
	if nIndex < 1 or nIndex > 13 then
		return
	elseif g_ServerNew_LevelUpBtnState[nIndex] == 1 then					--按钮为"未点亮"状态,说明根据MF判断玩家已经领取过该两例
		PushDebugMessage("#{SJSHL_140919_25}")					--对不起,您已经领取过此奖励,无法再次领取
		return
	end
	--3.判断玩家背包位置数是否足够
--	local nBegin = -1;
	--for i = 1, table.getn( ServerNew_LevelUpBtnState ) do
		--if ( ServerNew_LevelUpBtnState[ i ] == 0 ) then
		--	nBegin = i
		--	break
		--end
	--end
	
	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 890996 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end
--**********************************
-- 按钮【初出茅庐】点击事件
--**********************************
function ServerNew_LevelUp_Click_Button1()
	g_ServerNew_LevelUp_PageIndex  = 1
	ServerNew_LevelUp_Client_Button01:Disable();
	ServerNew_LevelUp_Client_Button02:Enable();
	ServerNew_LevelUp_FlushWindow();
end

--**********************************
-- 按钮【仗剑江湖】点击事件
--**********************************
function ServerNew_LevelUp_Click_Button2()
	g_ServerNew_LevelUp_PageIndex  = 2
	ServerNew_LevelUp_Client_Button02:Disable();
	ServerNew_LevelUp_Client_Button01:Enable();	
	ServerNew_LevelUp_FlushWindow();
end
--【新服欢乐月·升级送好礼】End

	

--新服消费排行榜 start-----------------------------------
--隐藏
function ServerNew_Paihang_Hide()
	ServerNew_Paihang_RewardFrame:Hide();
end

--显示
function ServerNew_Paihang_Show()

	--ServerNew_HideAll()
	ServerNew_Paihang_TopList:RemoveAllItem();

	ServerNew_Paihang_Refresh()

	--ServerNew_Title:SetText("#{XFXF_140919_44}")
	local time1,time2,time3,time4,time5 = DataPool:Lua_GetCostRankTime()
	local strFormat = g_KajiTable_RHM[6][0]
	local kajiType = KaJi:LuaFnGetKaJiType(15)
	if nil~=kajiType and nil~=g_KajiTable_RHM[6][kajiType]  then
		strFormat = g_KajiTable_RHM[6][kajiType] 
	end
	local szTitle = ScriptGlobal_Format(strFormat, ServerNew_TimeStr(time1),ServerNew_TimeStr(time4),ServerNew_TimeStr(time2),ServerNew_TimeStr(time3),ServerNew_TimeStr(time4),ServerNew_TimeStr(time5)) --反人类拼字典,shit
	--local szTitle = ScriptGlobal_Format("#{XFXF_140919_45}", "2014年-1月-1日","2014年-1月-1日","2014年-1月-1日","2014年-1月-1日","2014年-1月-1日","2014年-1月-1日") --反人类拼字典,shit
	ServerNew_Paihang_Info:SetText(szTitle)

	if g_EventIndex == 3 then
		ServerNew_Paihang_RewardFrame:Show();
	end
end

--刷新
function ServerNew_Paihang_Refresh()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientAskNewSrvTopList" )
		Set_XSCRIPT_ScriptID( 890084 )
		Set_XSCRIPT_Parameter(0,1);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--点击刷新
function ServerNew_Paihang_F5_Click()

	local iCur = FindFriendDataPool:GetTickCount()
	if ( iCur - g_ServerNew_Paihang_PH < 4000) then
		PushDebugMessage("#{MDJH_130507_33}");
	  return ;
	end
	g_ServerNew_Paihang_PH = iCur;
	ServerNew_Paihang_Refresh();
end

--领奖
function ServerNew_Paihang_Prize(ntype)
	if ntype < 1 or ntype > 3 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientNewSrvPrize" )
		Set_XSCRIPT_ScriptID( 890084 )
		Set_XSCRIPT_Parameter(0,ntype);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--显示具体的内容
function ServerNew_Paihang_UpdateList()

	
	local curJifen =  DataPool:GetPlayerMission_DataRound(g_ServerNew_Paihang_Jifen);
	local totalJifenStr = ScriptGlobal_Format("#{XFXF_140919_62}", curJifen)
	ServerNew_Paihang_Accumulate:SetText(totalJifenStr)
	
	local curDay = DataPool:GetServerDayTime()
	local nPrizeTime1 = DataPool:Lua_GetYBNewSrvTopListState(2)
	local nPrizeTime2 = DataPool:Lua_GetYBNewSrvTopListState(3)
	local nPrizeTime3 = DataPool:Lua_GetYBNewSrvTopListState(4)
	
	local firstname =""
	local secondname =""
	local fwinername = DataPool:Lua_GetYBNewSrvTopListWinerName(0)
	local swinername = DataPool:Lua_GetYBNewSrvTopListWinerName(1)


	local timeMsg=""
	
	if curDay <= nPrizeTime1 then

		firstname="#{XFXF_140919_67}";
		secondname="#{XFXF_140919_67}";
		
	elseif curDay <= nPrizeTime2 then
	
		if(fwinername == "") then
			firstname="#{XFXF_140919_68}";
		else
			firstname="#{XFXF_140919_69}"..fwinername;
		end
		secondname="#{XFXF_140919_67}"
		
	elseif curDay <= nPrizeTime3 then
	
		if(fwinername == "") then
			firstname="#{XFXF_140919_68}";
		else
			firstname="#{XFXF_140919_69}"..fwinername;
		end
		if(swinername == "") then
			secondname="#{XFXF_140919_68}";
		else
			secondname="#{XFXF_140919_69}"..swinername;
		end
		
	else
	
		if(fwinername == "") then
			firstname="#{XFXF_140919_68}";
		else
			firstname="#{XFXF_140919_69}"..fwinername;
		end
		if(swinername == "") then
			secondname="#{XFXF_140919_68}";
		else
			secondname="#{XFXF_140919_69}"..swinername;
		end
		
	end
	
	ServerNew_Paihang_PlayerNameText1:SetText(firstname)
	ServerNew_Paihang_PlayerNameText2:SetText(secondname);
	
	local time1,time2,time3,time4,time5 = DataPool:Lua_GetCostRankTime()
	local nYear = math.floor(time4/10000)
	local nMon = math.mod(math.floor(time4/100),100)
	local nDay = math.mod(time4,100)
	
	local finalname = ScriptGlobal_Format("#{XFXF_140919_70}", nYear,nMon,nDay)
	ServerNew_Paihang_PlayerNameText3:SetText(finalname)
		
	ServerNew_Paihang_TopList:RemoveAllItem()

	local tableServerNew_awardtips = g_KajiTable_RHM[7][0]
	local kajiType = KaJi:LuaFnGetKaJiType(15)
	if nil~=kajiType and nil~=g_KajiTable_RHM[7][kajiType]  then
		tableServerNew_awardtips = g_KajiTable_RHM[7][kajiType] 
	end
	for i=0,9 do
		ServerNew_Paihang_TopList:AddNewItem(" #cfff263"..tostring(i+1),0,i)
		ServerNew_Paihang_TopList:AddNewItem("#{MDJH_130507_42}",1,i)
		ServerNew_Paihang_TopList:AddNewItem("",2,i)
		ServerNew_Paihang_TopList:AddNewItem("",3,i)
		ServerNew_Paihang_TopList:AddNewItem("",4,i)
		ServerNew_Paihang_TopList:AddNewItem(tableServerNew_awardtips[i+1],5,i)
		local index,name,menpai,level,cost = DataPool:Lua_GetYBNewSrvTopListInfo(i)
		local menpaistr = ServerNew_GetMenpai(menpai)
		if index ~= nil and index >= 0 then
			if name ~= "" then
				ServerNew_Paihang_TopList:AddNewItem(" #cfff263"..tostring(i+1),0,i)
				ServerNew_Paihang_TopList:AddNewItem("#cfff263"..name,1,i)
				ServerNew_Paihang_TopList:AddNewItem("#cfff263"..menpaistr,2,i)
				ServerNew_Paihang_TopList:AddNewItem("#cfff263"..level,3,i)
				ServerNew_Paihang_TopList:AddNewItem("#cfff263"..cost,4,i)
				ServerNew_Paihang_TopList:AddNewItem(tableServerNew_awardtips[i+1],5,i)
			end
		end
	end
	
end

function ServerNew_Paihang_LeftTime(state,type,ndate)

	local curJifen =  DataPool:GetPlayerMission_DataRound(g_ServerNew_Paihang_Jifen);
	local totalJifenStr = ScriptGlobal_Format("#{XFXF_140919_62}", curJifen)
	ServerNew_Paihang_Accumulate:SetText(totalJifenStr)
	
	
	if state == 4 then
		ServerNew_Paihang_LastTime:SetText("#{XFXF_140919_66}")
		return
	end
	
	local lefttime = "";
	local lefttype = ""
	if state == 1 then
		lefttype = "#{XFXF_140919_63}";
	elseif state == 2 then
		lefttype = "#{XFXF_140919_64}";
	elseif state == 3 then
		lefttype = "#{XFXF_140919_65}";
	end
	if type == 1 then
		--天
		lefttime = ""..ndate.."天"
	elseif type == 2 then
		lefttime = ""..ndate.."小时"
	elseif type == 3 then
		lefttime = ""..ndate.."分"
	elseif type == 4 then
		lefttime = "不足一分钟"
	end
	
	local szLeftTime = ScriptGlobal_Format(lefttype, lefttime)
	ServerNew_Paihang_LastTime:SetText(szLeftTime)

end

function ServerNew_TimeStr(strtime)
	--输入格式 20141012 返回 2014年10月12日
	local nYear = math.floor(strtime/10000)
	local nMon = math.mod(math.floor(strtime/100),100)
	local nDay = math.mod(strtime,100)
	
	return ""..nYear.."年"..nMon.."月"..nDay.."日"
end

function ServerNew_TimeStrNoYear(strtime)
	--输入格式 20141012 返回 10月12日
	local nYear = math.floor(strtime/10000)
	local nMon = math.mod(math.floor(strtime/100),100)
	local nDay = math.mod(strtime,100)

	return ""..nMon.."月"..nDay.."日"
end

function ServerNew_GetMenpai(menpai)
	-- 得到门派名称.
	if(0 == menpai) then
		strName = "少林";

	elseif(1 == menpai) then
		strName = "明教";

	elseif(2 == menpai) then
		strName = "丐帮";

	elseif(3 == menpai) then
		strName = "武当";

	elseif(4 == menpai) then
		strName = "峨嵋";

	elseif(5 == menpai) then
		strName = "星宿";

	elseif(6 == menpai) then
		strName = "天龙";

	elseif(7 == menpai) then
		strName = "天山";

	elseif(8 == menpai) then
		strName = "逍遥";

	elseif(9 == menpai) then
		strName = "无门派";

	elseif(10== menpai) then
		strName = "慕容";

	elseif(11== menpai) then
		strName = "唐门";
		
	elseif(12== menpai) then
	strName = "鬼谷";		
	elseif(13== menpai) then
		strName = "#{XQ_MP_15}";--桃花岛	

	elseif(14== menpai) then
		strName = "#{XMPHM_210604_01}";
		
	elseif(15== menpai) then
		strName = "#{XMPHM_210604_30}";
		
	end
	return strName;
end

--消费排行榜 end

--豪情大派送 start
function ServerNew_Send_Hide()
	ServerNew_Send_RewardFrame:Hide()
end

function ServerNew_Send_Show()

	--ServerNew_HideAll()
	
	local haoqing =  DataPool:GetPlayerMission_DataRound(g_ServerNew_Send_Haoqing);

	local haoqingStr = ScriptGlobal_Format("#{XFXF_140919_05}", haoqing)

	ServerNew_Send_HQFrameText:SetText(haoqingStr)
	
	local time1,time2,time3 = DataPool:Lua_GetHaoQingTime()
	local strFormat = g_KajiTable_RHM[5][0]
	local kajiType = KaJi:LuaFnGetKaJiType(15)
	if nil~=kajiType and nil~=g_KajiTable_RHM[5][kajiType]  then
		strFormat = g_KajiTable_RHM[5][kajiType] 
	end
	if Player:GetData("Is2606S") == 1 then
		strFormat = "#{QXFXG_260703_14}"
	end
	
	local szTitle = ScriptGlobal_Format(strFormat, ServerNew_TimeStr(time1),ServerNew_TimeStr(time2),ServerNew_TimeStr(time3)) 
	ServerNew_Send_Info:SetText(szTitle)

	ServerNew_Send_SetItems()

	-- 兼容卡级服更换奖励后的buttontips
	for index=1,table.getn(g_ServerNew_Send_Button.getBtn) do
		if g_KajiTable_RHM[8][kajiType][index] ~= nil then
			g_ServerNew_Send_Button.getBtn[index]:SetToolTip(g_KajiTable_RHM[8][kajiType][index])
		end
	end
	
	--ServerNew_Title:SetText("#{XFXF_140919_03}")

	if g_EventIndex == 4 then
		ServerNew_Send_RewardFrame:Show()
	end
end

function ServerNew_Send_Update()

	local haoqing =  DataPool:GetPlayerMission_DataRound(g_ServerNew_Send_Haoqing);

	local haoqingStr = ScriptGlobal_Format("#{XFXF_140919_05}", haoqing)

	ServerNew_Send_HQFrameText:SetText(haoqingStr)
end

function ServerNew_Send_PrizeHQ(index)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Haoqing_Prize" )
		Set_XSCRIPT_ScriptID( 503030 )
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end
function ServerNew_Send_PrizeQL(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Haoqing_Prize" )
		Set_XSCRIPT_ScriptID( 503030 )
		Set_XSCRIPT_Parameter(0,index+3);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ServerNew_Send_SetItems()

	local tableServerNew_Send_Items = g_KajiTable_RHM[4][0]
	local kajiType = KaJi:LuaFnGetKaJiType(15)
	if nil~=kajiType and nil~=g_KajiTable_RHM[4][kajiType]  then
		tableServerNew_Send_Items = g_KajiTable_RHM[4][kajiType] 
	end
	local index = 0
	for index=1,table.getn(tableServerNew_Send_Items) do
		if tableServerNew_Send_Items[index] ~= nil then
			DataPool:Lua_Haoqing_Prize_SetItem(index-1,tableServerNew_Send_Items[index])
		end
	end

	for index=1,table.getn(g_ServerNew_Send_Button.showBtn) do
		if tableServerNew_Send_Items[index] ~= nil then
			g_ServerNew_Send_Button.bk[index]:Show()
			local theAction = EnumAction(index-1, "haoqingprize");
			if theAction:GetID() ~= 0 then
				g_ServerNew_Send_Button.showBtn[index]:SetActionItem(theAction:GetID());
			end
		else
			g_ServerNew_Send_Button.bk[index]:Hide()
		end
	end
	
end
--豪情大派送 end

--野外Boss排行榜开始
--领奖
function ServerNew_FBRank_Clicked( clickId )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskFBPrize")  
		Set_XSCRIPT_ScriptID(890998) 
		Set_XSCRIPT_Parameter(0,clickId);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--请求排行榜数据
function ServerNew_FBRank_GetList()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskFBRankList")  
		Set_XSCRIPT_ScriptID(890998) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--显示（师姐调这个）默认显示本周，打开页面时候去调用数据？
function ServerNew_FBRank_Show()
	ServerNew_Plunder_Button01:SetProperty("Selected","False")
	ServerNew_Plunder_Button02:SetProperty("Selected","False")
	--野外Boss的事件
	local eStartTime,eEndTime,eRewardTime = DataPool:Lua_GetBossRankTime()
	local deStartYear = math.floor(eStartTime/10000)
	local deStartMon = math.mod(math.floor(eStartTime/100),100)
	local deStartDay = math.mod(eStartTime,100)
	local deEndYear = math.floor(eEndTime/10000)
	local deEndMon = math.mod(math.floor(eEndTime/100),100)
	local deEndDay = math.mod(eEndTime,100)
	
	local szTitle = ScriptGlobal_Format("#{XFJS_140922_49}", deStartYear,deStartMon,deStartDay,deEndYear,deEndMon,deEndDay)
	ServerNew_Plunder_Info:SetText(szTitle)
	
	for i=1,7 do
		local theAction = DataPool:CreateActionItemForShow(g_ServerNew_FBRankPrizeItem[i], 1)
		if theAction ~= 0 then
			g_ServerNew_FBRankPrizeIcon[i]:SetActionItem(theAction:GetID())
			g_ServerNew_FBRankPrizeIcon[i]:Show()
		end
	end
	ServerNew_FBButton_Hide()
	if g_EventIndex == 7 then
		ServerNew_Plunder_RewardFrame:Show()
	end
end
--初始化本周控件数据
function ServerNew_Init_FBRankData()
	local nListIdx = 0;
	local nVaildNum = 0
	ServerNew_FBRank_Clear()
	nVaildNum = Guild:GetFieldBossNumber(1)
	--if nVaildNum <= 0 then
	--	return
	--end
	local i = 0
	while i < nVaildNum do
		local GuildID = Guild:GetFieldBossRankGuild(i,"ID",1)
		if( 0 > GuildID ) then
			i = i+1
			continue
		end
		local GuildName = Guild:GetFieldBossRankGuild(i,"GuildName",1)
		local BossOneNum = Guild:GetFieldBossRankGuild(i,"BossOne",1)
		local BossTwoNum = Guild:GetFieldBossRankGuild(i,"BossTwo",1)
		local BossThreeNum = Guild:GetFieldBossRankGuild(i,"BossThree",1)
		local BossFourNum = Guild:GetFieldBossRankGuild(i,"BossFour",1)
		local BossFiveNum = Guild:GetFieldBossRankGuild(i,"BossFive",1)
		local Score = Guild:GetFieldBossRankGuild(i,"Score",1)
		
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(nListIdx+1),0,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..GuildName,1,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(GuildID),2,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossOneNum),3,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossTwoNum),4,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossThreeNum),5,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossFourNum),6,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossFiveNum),7,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(Score),8,nListIdx)
		nListIdx = nListIdx+1
		i = i+1
	end
	
	while nVaildNum < 3 do
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(nListIdx+1),0,nListIdx)
		g_FBrankGuildList:AddNewItem("虚位以待",1,nListIdx)
		nVaildNum = nVaildNum + 1
		nListIdx = nListIdx + 1
	end
end
--显示本周数据
function ServerNew_FBRANK_CURWEEK_SHOW()
	ServerNew_FBButton_Hide()
	ServerNew_Init_FBRankData()
end
--显示上周数据
function ServerNew_FBRANK_LASTWEEK_SHOW()
	ServerNew_FBButton_Show()
	local nListIdx = 0
	local nVaildNum = 0
	ServerNew_FBRank_Clear()
	nVaildNum = Guild:GetFieldBossNumber(0)
	--if nVaildNum <= 0 then
	--	return
	--end
	local i = 0
	while i < nVaildNum do
		local GuildID = Guild:GetFieldBossRankGuild(i,"ID",0)
		if( 0 > GuildID ) then
			i = i+1
			continue
		end
		local GuildName = Guild:GetFieldBossRankGuild(i,"GuildName",0)
		local BossOneNum = Guild:GetFieldBossRankGuild(i,"BossOne",0)
		local BossTwoNum = Guild:GetFieldBossRankGuild(i,"BossTwo",0)
		local BossThreeNum = Guild:GetFieldBossRankGuild(i,"BossThree",0)
		local BossFourNum = Guild:GetFieldBossRankGuild(i,"BossFour",0)
		local BossFiveNum = Guild:GetFieldBossRankGuild(i,"BossFive",0)
		local Score = Guild:GetFieldBossRankGuild(i,"Score",0)
		
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(nListIdx+1),0,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..GuildName,1,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(GuildID),2,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossOneNum),3,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossTwoNum),4,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossThreeNum),5,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossFourNum),6,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(BossFiveNum),7,nListIdx)
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(Score),8,nListIdx)
		nListIdx = nListIdx+1
		i = i+1
	end
	
	while nVaildNum < 3 do
		g_FBrankGuildList:AddNewItem("#cfff263"..tostring(nListIdx+1),0,nListIdx)
		g_FBrankGuildList:AddNewItem("未能决出",1,nListIdx)
		nVaildNum = nVaildNum + 1
		nListIdx = nListIdx + 1
	end
end
--清空
function ServerNew_FBRank_Clear()
	g_FBrankGuildList:RemoveAllItem()
end
--隐藏（师姐调这个）
function ServerNew_FBRank_Hide( )
	ServerNew_Plunder_RewardFrame:Hide()
end

function ServerNew_FBButton_Show()
	ServerNew_Plunder_Get1:Show()
	ServerNew_Plunder_Get2:Show()
	ServerNew_Plunder_Get3:Show()
	ServerNew_Plunder_PlayerNameText1:Hide()
	ServerNew_Plunder_PlayerNameText2:Hide()
	ServerNew_Plunder_PlayerNameText3:Hide()
end

function ServerNew_FBButton_Hide()
	ServerNew_Plunder_Get1:Hide()
	ServerNew_Plunder_Get2:Hide()
	ServerNew_Plunder_Get3:Hide()
	ServerNew_Plunder_PlayerNameText1:Show()
	ServerNew_Plunder_PlayerNameText2:Show()
	ServerNew_Plunder_PlayerNameText3:Show()
end
--野外Boss排行榜结束

--新服乐事记begin
--显示
function ServerNew_Broadcast_Show( )
	--第一次打开界面，默认显示婚姻频道
	for i=1,4 do	
		g_ServerNew_Broadcast_ChannelButtonn[i]:SetCheck(0)
	end
	g_Broadcast_CurChannel = 1
	
	--请求婚姻数据
	ServerNew_Broadcast_Refresh(g_Broadcast_CurChannel)
	--婚姻按钮 为选中状态
	g_ServerNew_Broadcast_ChannelButtonn[g_Broadcast_CurChannel]:SetCheck(1)
	--设置领奖界面
	ServerNew_Broadcast_RewardWindow()
	--清空广播列表
	g_Broadcast_Content[g_Broadcast_CurChannel]:RemoveAllText()
	--显示界面
	if g_EventIndex == 9 then
		ServerNew_FunNoteFrame:Show()
		--ServerNew_FunNoteFrame_TopButton:Show()
		ServerNew_Broadcast_ChannelShow(g_Broadcast_CurChannel)
	end
end

--点击频道
function ServerNew_Broadcast_Channel_Click( clickId )
	if ( clickId < 1 or clickId > 4) then
		--debug信息
		PushDebugMessage("频道错误")
		return ;
	end
	
	--点击频道CD
	local iCur = FindFriendDataPool:GetTickCount()
	if ( iCur - g_Broadcast_LastClickChannelTime < g_Broadcast_CDTime * 1000) then
		PushDebugMessage("#{MDJH_130507_33}");
		g_ServerNew_Broadcast_ChannelButtonn[clickId]:SetCheck(0)
		g_ServerNew_Broadcast_ChannelButtonn[g_Broadcast_CurChannel]:SetCheck(1)
		return ;
	end
	g_Broadcast_LastClickChannelTime = iCur
	
	--频道按钮
	for i=1,4 do
		if i ~= clickId then
			g_ServerNew_Broadcast_ChannelButtonn[i]:SetCheck(0)
		else
			g_ServerNew_Broadcast_ChannelButtonn[i]:SetCheck(1)
		end
	end
	
	g_Broadcast_CurChannel = clickId
	ServerNew_Broadcast_Refresh(g_Broadcast_CurChannel)	
	ServerNew_Broadcast_ChannelShow(g_Broadcast_CurChannel)
end

--发送消息包 请求数据
function ServerNew_Broadcast_Refresh( CurChannel )
	if ( CurChannel < 1 or CurChannel > 4) then
		--debug信息
		PushDebugMessage("频道错误")
		return ;
	end

	Lua_SendAskNewServerBroadcastMsg(CurChannel)
end

--更新滚屏信息
function ServerNew_Broadcast_UpdateList( CurChannel )
	for i = 1 ,4 do
		g_Broadcast_Content[i]:RemoveAllText()
	end
	
	local broadcastnum = 0
	--播放顺序 95,96,97,98,99,0,1...94
	if (CurChannel == 1)  then	--结婚频道
		for j=95, 194 do
			local eTime, eName1, eName2 = DataPool:Lua_GetNewServerBroadcastInfo( CurChannel, math.mod(j,100) )
			if eTime ~= 0 then
				broadcastnum = broadcastnum + 1
				local str = ServerNew_Broadcast_str(CurChannel, eName1, eName2, "","","","")
				g_Broadcast_Content[CurChannel]:InsertText(str)
			end
		end
		if broadcastnum == 0 then
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText("#{XFLSJ_160823_67}")
		end
	elseif (CurChannel == 2)  then	--结拜频道
		for j=95, 194 do
			local eTime, eName1, eName2, eName3,eName4,eName5,eName6= DataPool:Lua_GetNewServerBroadcastInfo( CurChannel, math.mod(j,100) )
			if eTime ~= 0 then	
				broadcastnum = broadcastnum + 1
				local str = ServerNew_Broadcast_str(CurChannel, eName1, eName2, eName3, eName4, eName5, eName6)
				g_Broadcast_Content[CurChannel]:InsertText(str)
			end
		end
		if broadcastnum == 0 then
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText("#{XFLSJ_160823_68}")
		end
	elseif (CurChannel == 3)  then	--师徒频道
		for j=95, 194 do
			local eTime, eName1, eName2 = DataPool:Lua_GetNewServerBroadcastInfo( CurChannel, math.mod(j,100) )
			if eTime ~= 0 then
				broadcastnum = broadcastnum + 1
				local str = ServerNew_Broadcast_str(CurChannel, eName1, eName2, "","","","")
				g_Broadcast_Content[CurChannel]:InsertText(str)
			end
		end
		if broadcastnum == 0 then
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText("#{XFLSJ_160823_69}")
		end
	elseif (CurChannel == 4)  then	--帮派频道	
		for j=95, 194 do
			local eTime, eType, eName1, eGuild = DataPool:Lua_GetNewServerBroadcastInfo( CurChannel, math.mod(j,100) )
			if eTime ~= 0 then	
				broadcastnum = broadcastnum + 1
				local str = ServerNew_Broadcast_str(eType, eName1, eGuild, "","","","")
				g_Broadcast_Content[CurChannel]:InsertText(str)
			end
		end
		if broadcastnum == 0 then
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText(" ")
			g_Broadcast_Content[CurChannel]:InsertText("#{XFLSJ_160823_70}")
		end
	end
	
end

--新服乐事记拼字典
function ServerNew_Broadcast_str(eType, eName1, eName2, eName3, eName4, eName5, eName6)
	local str =""
	if eType == 1 then	--结婚
		str = ScriptGlobal_Format("#{XFLSJ_160823_6}", eName1, eName2)
	elseif eType == 2 then	--	结拜
		if eName6 ~= "" then
			str = ScriptGlobal_Format("#{XFLSJ_160823_63}", eName1, eName2, eName3, eName4, eName5, eName6 )
		elseif eName5 ~= "" then
			str = ScriptGlobal_Format("#{XFLSJ_160823_62}", eName1, eName2, eName3, eName4, eName5 )
		elseif eName4 ~= "" then
			str = ScriptGlobal_Format("#{XFLSJ_160823_61}", eName1, eName2, eName3, eName4 )
		elseif eName3 ~= "" then
			str = ScriptGlobal_Format("#{XFLSJ_160823_60}", eName1, eName2, eName3 )
		elseif eName2 ~= "" then
			str = ScriptGlobal_Format("#{XFLSJ_160823_59}", eName1, eName2 )
		end
	elseif eType == 3 then	--师徒
		str = ScriptGlobal_Format("#{XFLSJ_160823_27}", eName1, eName2 )
	elseif eType == 4 then	--建帮
		str = ScriptGlobal_Format("#{XFLSJ_160823_43}", eName1, eName2 )
	elseif eType == 5 then	--加帮
		str = ScriptGlobal_Format("#{XFLSJ_160823_45}", eName1, eName2 )
	elseif eType == 6 then	--帮升级
		str = ScriptGlobal_Format("#{XFLSJ_160823_44}", eName2, eName1 )
	end
	return str	
end

--新服乐事记领奖
function ServerNew_Broadcast_Reward_Click(nType)
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskNewSrvBcReward" )
		Set_XSCRIPT_ScriptID( 892308 )
		Set_XSCRIPT_Parameter(0,nType); --1结婚 2结拜 3拜师 4帮会 5收徒
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

function ServerNew_Broadcast_ShiTu_Click(IsShouTu)
	g_Broadcast_IsShouTu = IsShouTu
	if IsShouTu == 0 then
		ServerNew_FunNoteFrame_STFrame_RewardTopBtn1:SetCheck(1)
		ServerNew_FunNoteFrame_STFrame_RewardTopBtn2:SetCheck(0)
		ServerNew_FunNoteFrame_STFrame2_RewardClient:Hide()
		ServerNew_FunNoteFrame_STFrame1_RewardClient:Show()
	else
		ServerNew_FunNoteFrame_STFrame_RewardTopBtn1:SetCheck(0)
		ServerNew_FunNoteFrame_STFrame_RewardTopBtn2:SetCheck(1)
		ServerNew_FunNoteFrame_STFrame1_RewardClient:Hide()
		ServerNew_FunNoteFrame_STFrame2_RewardClient:Show()
	end
	--刷新领奖区域
	--ServerNew_Broadcast_RewardWindow(3)
end

--隐藏
function ServerNew_Broadcast_Hide( )
	ServerNew_FunNoteFrame:Hide()
end

--领奖区域 
function ServerNew_Broadcast_RewardWindow()

		for CurChannel = 1, table.getn(g_ServerNew_BroadcastBtnState) do
			--显示领奖区域文字
			local _,EndDate = DataPool:Lua_GetBroadcastGiftTime()
			local nYear = math.floor(EndDate/10000)
			local nMon = math.mod(math.floor(EndDate/100),100)
			local nDay = math.mod(EndDate,100)
			local InfoText = ScriptGlobal_Format(g_ServerNew_Broadcast_GiftTextInfo[CurChannel],nYear,nMon,nDay)
			g_ServerNew_Broadcast_TextInfo[CurChannel]:SetText(InfoText)
			
			--将物品奖励加载到页面显示
			for i = 1,  table.getn(g_ServerNew_Broadcast_Gifts[CurChannel]) do
				local GiftItemID = g_ServerNew_Broadcast_Gifts[CurChannel][i].GiftItemID
				local GiftItemNum = g_ServerNew_Broadcast_Gifts[CurChannel][i].num
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
				if theAction:GetID() ~= 0 then
					g_ServerNew_Broadcast_GiftsIcons[CurChannel][i]:SetActionItem(theAction:GetID());
					g_ServerNew_Broadcast_GiftsIcons[CurChannel][i]:Show();
				end
			end
		end
		
end

--设置领奖Button
function ServerNew_Broadcast_FlushRewardButton()
	for i = 1, table.getn(g_ServerNew_BroadcastBtnState) do
		if g_ServerNew_BroadcastBtnState[i] == 1 then  --可领取状态
			g_ServerNew_BroadcastButton[i]:Enable()
			g_ServerNew_BroadcastButton[i]:SetToolTip(g_ServerNew_BroadcastBtnTip[CurChannel])
		elseif g_ServerNew_BroadcastBtnState[i] == 2 then --已领取状态
			g_ServerNew_BroadcastButton[i]:SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
			g_ServerNew_BroadcastButton[i]:Disable()
		elseif g_ServerNew_BroadcastBtnState[i] == 0 then --不可领取状态
			g_ServerNew_BroadcastButton[i]:SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
			g_ServerNew_BroadcastButton[i]:Disable()
		end
	end
end

--显示指定频道
function ServerNew_Broadcast_ChannelShow(CurChannel)
	--隐藏所有频道
	for i = 1, table.getn(g_ServerNew_Broadcast_ChannelFrame) do
		g_ServerNew_Broadcast_ChannelFrame[i]:Hide()
	end	
	--师徒频道 显示拜师-隐藏收徒奖励
	if CurChannel == 3 then
		ServerNew_FunNoteFrame_STFrame_RewardTopBtn1:SetCheck(1)
		ServerNew_FunNoteFrame_STFrame_RewardTopBtn2:SetCheck(0)
		ServerNew_FunNoteFrame_STFrame1_RewardClient:Show()
		ServerNew_FunNoteFrame_STFrame2_RewardClient:Hide()
	end
	--显示
	g_ServerNew_Broadcast_ChannelFrame[CurChannel]:Show()
end

function ServerNew_Broadcast_OpenLink_Click(nType)
	if nType == 1 then  --师徒
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnAskShiMenInfo")
			Set_XSCRIPT_ScriptID(891116)
			Set_XSCRIPT_Parameter(0,2);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif nType == 2 then	--结拜
		PushEvent("NEWFRIEND_JIEBAI_OPEN")
	elseif nType == 3 then --结婚
		ZhanTuanInterface:FriendMaritalRelations()
	end
end
--新服乐事记end

--全部隐藏
function ServerNew_HideAll()
	ServerNew_SaveUp_RewardFrame:Hide()
	ServerNew_LevelUp_RewardFrame:Hide()
	ServerNew_Velocity_RewardFrame:Hide()
	ServerNew_FirstOne_RewardFrame:Hide()
	ServerNew_DoubleExp_RewardFrame:Hide()
	ServerNew_Paihang_RewardFrame:Hide()
	ServerNew_Send_RewardFrame:Hide()
	ServerNew_Plunder_RewardFrame:Hide()
	ServerNew_Broadcast_Hide()
end

function ServerNew_NewServerHappy_OpenLink()
	GameProduceLogin:OpenURL(GetWeblink("WEB_NEWSERVER"))
end

function ServerNew_HQYZ_Show()
	local curTime = tonumber(DataPool:GetServerMinuteTime())
	curTime=math.mod(curTime,1000000);
	local curHour = math.floor(curTime/10000)	
	
	local nHour = curHour

	if nHour < 21 then
		ServerNew_HQYZ_Update("", "", "")
	else
		DataPool:Lua_AskServerNewLotteryNameList()
	end
end

function ServerNew_HQYZ_Update(nName1, nName2, nName3)
	local curTime = tonumber(DataPool:GetServerMinuteTime())
	
	curTime=math.mod(curTime,1000000);
	local curHour = math.floor(curTime/10000)
	local curLeft = math.mod(curTime, 10000)
	local nMin = math.floor(curLeft/100)
	local nHourMinute = curHour * 100 + nMin
	
	--按钮显示
	ServerNew_HQYZ_UpdateButton()
	
	--显示奖励
	ServerNew_HQYZ_UpdateRewardList()
	
	if nName1 == "" then
		if nHourMinute >= 2100 then
			ServerNew_HQYZ_Main_BK1_Text1:SetText("#{HQYZ_180115_07}")
			ServerNew_HQYZ_Main_BK1_Text2:SetText("#{HQYZ_180115_10}")
		else
			ServerNew_HQYZ_Main_BK1_Text1:SetText("#{HQYZ_180115_04}")
			ServerNew_HQYZ_Main_BK1_Text2:SetText("#{HQYZ_180115_09}")
		end	
	else
		ServerNew_HQYZ_Main_BK1_Text1:SetText("#{HQYZ_180115_07}")
		ServerNew_HQYZ_Main_BK1_Text2:SetText("#M"..nName1)
	end
	
	if nName2 == "" then
		if nHourMinute >= 2115 then
			ServerNew_HQYZ_Main_BK2_Text1:SetText("#{HQYZ_180115_07}")
			ServerNew_HQYZ_Main_BK2_Text2:SetText("#{HQYZ_180115_10}")
		else
			ServerNew_HQYZ_Main_BK2_Text1:SetText("#{HQYZ_180115_05}")
			ServerNew_HQYZ_Main_BK2_Text2:SetText("#{HQYZ_180115_09}")
		end
	else
		ServerNew_HQYZ_Main_BK2_Text1:SetText("#{HQYZ_180115_07}")
		ServerNew_HQYZ_Main_BK2_Text2:SetText("#M"..nName2)
	end
	
	if nName3 == "" then
		if nHourMinute >= 2130 then
			ServerNew_HQYZ_Main_BK3_Text1:SetText("#{HQYZ_180115_07}")
			ServerNew_HQYZ_Main_BK3_Text2:SetText("#{HQYZ_180115_10}")
		else
			ServerNew_HQYZ_Main_BK3_Text1:SetText("#{HQYZ_180115_06}")
			ServerNew_HQYZ_Main_BK3_Text2:SetText("#{HQYZ_180115_09}")
		end
	else
		ServerNew_HQYZ_Main_BK3_Text1:SetText("#{HQYZ_180115_07}")
		ServerNew_HQYZ_Main_BK3_Text2:SetText("#M"..nName3)
	end
	ServerNew_HQYZFrame:Show()
end

function ServerNew_HQYZ_UpdateButton()
	local curTime = tonumber(DataPool:GetServerMinuteTime())
	curTime=math.mod(curTime,1000000);
	local nHour = math.floor(curTime/10000)
	local curLeft = math.mod(curTime, 10000)
	local nMinute = math.floor(curLeft/100)
	local nHourMinute = nHour * 100 + nMinute

	local nMD_HQYZ_DATA = DataPool:GetPlayerMission_DataRound(g_MD_HQYZ_DATA)

	if math.mod(nMD_HQYZ_DATA, 10) == 0 then
		ServerNew_HQYZ_Main_Button:SetProperty("PushedImage", "set:XSYNew02 image:XFHLYNEW_HQYZCJ_Pushed")
		ServerNew_HQYZ_Main_Button:SetProperty("NormalImage", "set:XSYNew02 image:XFHLYNEW_HQYZCJ_Normal")
		ServerNew_HQYZ_Main_Button:SetProperty("HoverImage", "set:XSYNew02 image:XFHLYNEW_HQYZCJ_Hover")
		ServerNew_HQYZ_Main_Button:SetProperty("DisabledImage", "set:XSYNew02 image:XFHLYNEW_HQYZCJ_Disabled")
		ServerNew_HQYZ_Main_Button:SetToolTip("#{HQYZ_180115_12}")
	else
		ServerNew_HQYZ_Main_Button:SetProperty("PushedImage", "set:XSYNew02 image:XFHLYNEW_HQYZLQ_Pushed")
		ServerNew_HQYZ_Main_Button:SetProperty("NormalImage", "set:XSYNew02 image:XFHLYNEW_HQYZLQ_Normal")
		ServerNew_HQYZ_Main_Button:SetProperty("HoverImage", "set:XSYNew02 image:XFHLYNEW_HQYZLQ_Hover")
		ServerNew_HQYZ_Main_Button:SetProperty("DisabledImage", "set:XSYNew02 image:XFHLYNEW_HQYZLQ_Disabled")
		
		local nPrizeFlag = math.floor(math.mod(nMD_HQYZ_DATA, 100)/10)
		local nRevPrizeFlag = math.floor(math.mod(nMD_HQYZ_DATA, 1000)/100)
		
		local nPrizestr = {"#{HQYZ_180115_31}", "#{HQYZ_180115_32}", "#{HQYZ_180115_33}"}
		if nPrizeFlag > 0 and nRevPrizeFlag == 0 then --优先显示中奖未领取
			ServerNew_HQYZ_Main_Button:SetToolTip( ScriptGlobal_Format("#{HQYZ_180115_15}",nPrizestr[nPrizeFlag]) )
		elseif nHour < 21 then 
			ServerNew_HQYZ_Main_Button:SetToolTip("#{HQYZ_180115_14}")
		elseif nHour == 21 and nMinute < 15 then
			ServerNew_HQYZ_Main_Button:SetToolTip("#{HQYZ_180115_16}")
		elseif nHour == 21 and nMinute < 30 then
			ServerNew_HQYZ_Main_Button:SetToolTip("#{HQYZ_180115_19}")
		else
			if nPrizeFlag > 0 then
				ServerNew_HQYZ_Main_Button:SetToolTip( ScriptGlobal_Format("#{HQYZ_180115_22}",nPrizestr[nPrizeFlag]) )
			else
				ServerNew_HQYZ_Main_Button:SetToolTip("#{HQYZ_180115_23}")
			end	
		end
	end
end

function ServerNew_HQYZ_UpdateRewardList()
	local nHQYZ_StartTime, _ = DataPool:Lua_GetServerNewLotteryTime()
	local nDayIndex = DataPool:GetDifDayWithServerTime(nHQYZ_StartTime) + 1
	if nDayIndex <= 0 or nDayIndex > 7 then
		return
	end
	local tableLotteryRewardList = g_KajiTable_RHM[3][0]
	local kajiType = KaJi:LuaFnGetKaJiType(15)
	if nil~=kajiType and nil~=g_KajiTable_RHM[3][kajiType]  then
		tableLotteryRewardList = g_KajiTable_RHM[3][kajiType] 
	end

	for i = 1,  table.getn(g_ServerNew_HQYZ_Icons) do
		local GiftItemID = tableLotteryRewardList[nDayIndex][i]
		local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, 1)
		if theAction:GetID() ~= 0 then
			g_ServerNew_HQYZ_Icons[i]:SetActionItem(theAction:GetID());
			g_ServerNew_HQYZ_Icons[i]:Show();
		end
	end
	
end

function ServerNew_HQYZ_UpdateRedPoint()
	if g_HQYZ_RedPointPos < 0 then
		return
	end
	
	local nLevel = Player : GetLevel()
	if nLevel < 30 then
		g_Broadcast_RedPointButton[g_HQYZ_RedPointPos]:Hide()
		return
	end
	
	local nMD_HQYZ_DATA = DataPool:GetPlayerMission_DataRound(g_MD_HQYZ_DATA)
	local nPrizeFlag = math.floor(math.mod(nMD_HQYZ_DATA, 100)/10)
	local nRevPrizeFlag = math.floor(math.mod(nMD_HQYZ_DATA, 1000)/100)
	local nIsSighUp = math.mod(nMD_HQYZ_DATA, 10)
	
	if ( nIsSighUp == 0 ) or ( nPrizeFlag > 0 and nRevPrizeFlag == 0 ) then
		g_Broadcast_RedPointButton[g_HQYZ_RedPointPos]:Show()			
	else
		g_Broadcast_RedPointButton[g_HQYZ_RedPointPos]:Hide()
	end
end

function ServerNew_HQYZ_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HQYZ_GetPrize")  
		Set_XSCRIPT_ScriptID(892678) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ServerNew_HQYZ_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HQYZ_Help")  
		Set_XSCRIPT_ScriptID(892678) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ServerNew_HQYZ_IntroClick()
	PushEvent("OPEN_SERVERNEW_HQYZ_INTRO");
end

---------------------------------------------------------------------------------------------------------------------------------------
-- 新春享返利 Begin
---------------------------------------------------------------------------------------------------------------------------------------
function ServerNew_XinChunFanLi_LoadControl()
end

function ServerNew_XinChunFanLi_Show()
	ServerNew_XinChunFanLi_UpdateButtonReq(); 
	ServerNew_NewYearFrame:Show()
end
function ServerNew_XinChunFanLi_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetXinChunFanLiGiftsInfo" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892981 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function ServerNew_XinChunFanLi_UpdateInfo() 

	g_ServerNew_XinChunFanLi_Exch  = Get_XParam_INT(0)
	g_ServerNew_XinChunFanLi_Cost  = Get_XParam_INT(1)
	
	for i=1,4 do  
		g_ServerNew_XinChunFanLi_ButtonState.Gift[i]  = Get_XParam_INT(i+1)    
--		Lua_TDU_Log("g_ServerNew_XinChunFanLi_ButtonState.Gift:"..Get_XParam_INT(i+1) )
	end     
	
	for i=1,4 do  
		g_ServerNew_XinChunFanLi_ButtonState.Gift1[i]  = Get_XParam_INT(i+5)     
--		Lua_TDU_Log("g_ServerNew_XinChunFanLi_ButtonState.Gift1:"..Get_XParam_INT(i+5) )
	end   
	
	for i=1,3 do  
		g_ServerNew_XinChunFanLi_ButtonState.Exch[i] = Get_XParam_INT(i+9)
--		Lua_TDU_Log("g_ServerNew_XinChunFanLi_ButtonState.Exch:"..Get_XParam_INT(i+9) )
	end   
	
	ServerNew_XinChunFanLi_FlushWindow()
end
function ServerNew_XinChunFanLi_FlushWindow() 
	local MDEndTime 	= DataPool:Lua_GetServerNewFanLiMDEndTime() 
	local nDay 				= math.mod(MDEndTime,100)
	local nMonth 			= math.mod( math.floor(MDEndTime/100),100)
	--  达到兑换起始点
	if g_ServerNew_XinChunFanLi_Exch >= g_ServerNew_XCFL_Exch_Base then  
		ServerNew_NewYear_TopInfo1:SetText( ScriptGlobal_Format("#{YCZJJ_181130_58}",nMonth,nDay) )
		ServerNew_NewYear_TopInfo2:SetText(ScriptGlobal_Format("#{YCZJJ_181130_13}",g_ServerNew_XCFL_Exch_Base,g_ServerNew_XCFL_Exch_Base)) 
		ServerNew_NewYear_Button:Hide()
	else
		ServerNew_NewYear_TopInfo1:SetText( ScriptGlobal_Format("#{YCZJJ_181130_58}",nMonth,nDay) )
		ServerNew_NewYear_TopInfo2:SetText(ScriptGlobal_Format("#{YCZJJ_181130_12}",g_ServerNew_XinChunFanLi_Exch,g_ServerNew_XCFL_Exch_Base)) 
		ServerNew_NewYear_Button:Show()
	end
	--文字
	for i=1, 4 do
		if g_ServerNew_XinChunFanLi_Cost >= g_ServerNew_XCFL_GetGiftsCondition[i].Cost and g_ServerNew_XinChunFanLi_Exch >= g_ServerNew_XCFL_Exch_Base then
			--文字 
			g_ServerNew_XinChunFanLi_Text.TEXT1[i]:SetText("#{YCZJJ_181130_15}")
			if g_ServerNew_XinChunFanLi_Cost >= g_ServerNew_XCFL_GetGiftsCondition[i].Cost then
				g_ServerNew_XinChunFanLi_Text.TEXT2[i]:SetText(ScriptGlobal_Format("#{YCZJJ_181130_48}",g_ServerNew_XCFL_GetGiftsCondition[i].Cost,g_ServerNew_XCFL_GetGiftsCondition[i].Cost))
			else
				g_ServerNew_XinChunFanLi_Text.TEXT2[i]:SetText(ScriptGlobal_Format("#{YCZJJ_181130_48}",g_ServerNew_XinChunFanLi_Cost,g_ServerNew_XCFL_GetGiftsCondition[i].Cost))
			end  
		else
			--文字
			g_ServerNew_XinChunFanLi_Text.TEXT1[i]:SetText("#{YCZJJ_181130_14}")
			if g_ServerNew_XinChunFanLi_Cost >= g_ServerNew_XCFL_GetGiftsCondition[i].Cost then
				g_ServerNew_XinChunFanLi_Text.TEXT2[i]:SetText(ScriptGlobal_Format("#{YCZJJ_181130_33}",g_ServerNew_XCFL_GetGiftsCondition[i].Cost,g_ServerNew_XCFL_GetGiftsCondition[i].Cost))
			else
				g_ServerNew_XinChunFanLi_Text.TEXT2[i]:SetText(ScriptGlobal_Format("#{YCZJJ_181130_33}",g_ServerNew_XinChunFanLi_Cost,g_ServerNew_XCFL_GetGiftsCondition[i].Cost))
			end
		end
	end
	
	-- 0 未达成 1 领取 2 已领取 奖励部分
	for i=1, table.getn(g_ServerNew_XCFL_GetGiftsCondition) do
		--未达成
		if g_ServerNew_XinChunFanLi_ButtonState.Gift[i] == 0 then 			
			--Button 
			--设置未达成的Button
			g_ServerNew_XinChunFanLi_Button.GIFT[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_DH_NotFinish")
			g_ServerNew_XinChunFanLi_Button.GIFT[i] : Disable()
		--领取
		elseif g_ServerNew_XinChunFanLi_ButtonState.Gift[i] == 1 then
			--Button 
			g_ServerNew_XinChunFanLi_Button.GIFT[i] : Enable()
		--已领取
		elseif g_ServerNew_XinChunFanLi_ButtonState.Gift[i] == 2 then
			--设置按钮图片为已领取
			g_ServerNew_XinChunFanLi_Button.GIFT[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_LQ_Finish")
			g_ServerNew_XinChunFanLi_Button.GIFT[i] : Disable()
		--已过期
		elseif g_ServerNew_XinChunFanLi_ButtonState.Gift[i] == 3 then
			--文字
			
			--设置按钮图片为已过期
			g_ServerNew_XinChunFanLi_Button.GIFT[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_Expired")
			g_ServerNew_XinChunFanLi_Button.GIFT[i] : Disable()
		end
	end  
	
	-- 0 未达成 1 领取 2 已领取 奖励部分
	for i=1, table.getn(g_ServerNew_XCFL_GetGiftsCondition) do
		--未达成
		if g_ServerNew_XinChunFanLi_ButtonState.Gift1[i] == 0 then
			--Button 
			--设置未达成的Button
			g_ServerNew_XinChunFanLi_Button.GIFT1[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_DH_NotFinish")
			g_ServerNew_XinChunFanLi_Button.GIFT1[i] : Disable()
		--领取
		elseif g_ServerNew_XinChunFanLi_ButtonState.Gift1[i] == 1 then
			g_ServerNew_XinChunFanLi_Button.GIFT1[i] : Enable()
		--已领取
		elseif g_ServerNew_XinChunFanLi_ButtonState.Gift1[i] == 2 then
			--设置按钮图片为已领取
			g_ServerNew_XinChunFanLi_Button.GIFT1[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_LQ_Finish")
			g_ServerNew_XinChunFanLi_Button.GIFT1[i] : Disable()
		--已领取
		elseif g_ServerNew_XinChunFanLi_ButtonState.Gift1[i] == 3 then
			--设置按钮图片为已领取
			g_ServerNew_XinChunFanLi_Button.GIFT1[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_Expired")
			g_ServerNew_XinChunFanLi_Button.GIFT1[i] : Disable()
		end
	end
	
	-- 0 未达成 1 领取 2 已领取 兑换部分
	for i=1,table.getn(g_ServerNew_XCFL_GetGiftsCondition)-1 do
		--未达成
		if g_ServerNew_XinChunFanLi_ButtonState.Exch[i] == 0 then
			--Button 
			--设置未达成的Button
			g_ServerNew_XinChunFanLi_Button.EXCH[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_DH_NotFinish")
			g_ServerNew_XinChunFanLi_Button.EXCH[i] : Disable()
		--领取
		elseif g_ServerNew_XinChunFanLi_ButtonState.Exch[i] == 1 then
			g_ServerNew_XinChunFanLi_Button.EXCH[i] : Enable()
		--已领取
		elseif g_ServerNew_XinChunFanLi_ButtonState.Exch[i] == 2 then
			--设置按钮图片为已领取
			g_ServerNew_XinChunFanLi_Button.EXCH[i] : SetProperty("DisabledImage","set:JSYN image:JSYN_DH_Finish")
			g_ServerNew_XinChunFanLi_Button.EXCH[i] : Disable()
		end
	end 	
	
	for i=1,table.getn(g_ServerNew_XinChunFanLi_Icon) do
		for j=1,table.getn(g_ServerNew_XinChunFanLi_Icon[i]) do 
			local theAction = DataPool:CreateActionItemForShow(g_ServerNew_XCFL_ItemIcon[i][j], 1)
			if theAction:GetID() ~= 0 then
				g_ServerNew_XinChunFanLi_Icon[i][j]:SetActionItem(theAction:GetID());
			end
		end
	end	
end
function ServerNew_XinChunFanLi_GetGifts_A( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForXinChunFanLi_GiftA" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892981 );				-- 脚本编号 
		Set_XSCRIPT_Parameter(0,Index)				-- 第几档
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end 
function ServerNew_XinChunFanLi_GetGifts_B( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForXinChunFanLi_GiftB" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892981 );				-- 脚本编号 
		Set_XSCRIPT_Parameter(0,Index)				-- 第几档
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end 

function ServerNew_XinChunFanLi_ExchGifts( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForXinChunFanLi_Exch" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892981 );				-- 脚本编号 
		Set_XSCRIPT_Parameter(0,Index)			     -- 第几档
		Set_XSCRIPT_Parameter(1,0)			    	-- 确认
		Set_XSCRIPT_ParamCount( 2 );					-- 参数个数
	Send_XSCRIPT()
end 

function ServerNew_XinChunFanLi_UpdateRedPoint()
	if g_XCFL_RedPoint == 1 then
		g_XinChunFanLi_RedPointButton[g_XCFL_RedPointPos]:Show()
	elseif g_XCFL_RedPointPos ~= -1 then
		g_XinChunFanLi_RedPointButton[g_XCFL_RedPointPos]:Hide() 
	end
end

function ServerNew_NewYear_Button_ShouChong() 
	   local bflg =YuanbaoExange()
	   if bflg~= 1 then
	  	 return ;
	   end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AskOpenDuihuanWindow");
			Set_XSCRIPT_ScriptID(181000);
			--Set_XSCRIPT_Parameter(2,shopB);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
end

function ServerNew_NewYear_Help_Clicked()  
--		Clear_XSCRIPT();
--			Set_XSCRIPT_Function_Name("OpenFanLiHelp");
--			Set_XSCRIPT_ScriptID(892981); 
--			Set_XSCRIPT_ParamCount(0);
--		Send_XSCRIPT();
	local MDEndTime 	= DataPool:Lua_GetServerNewFanLiMDEndTime() 
	local nDay 				= math.mod(MDEndTime,100)
	local nMonth 			= math.mod( math.floor(MDEndTime/100),100)
	
	local msg = ScriptGlobal_Format( "#{YCZJJ_181130_60}", nMonth , nDay)  
	PushEvent("OPEN_SWEEPPAGE_QUEST", "ServerNew", msg) 
end
---------------------------------------------------------------------------------------------------------------------------------------
-- 新春享返利 End
---------------------------------------------------------------------------------------------------------------------------------------
