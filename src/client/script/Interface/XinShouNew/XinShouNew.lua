--!!!reloadscript =XinShouNew
local g_XinShouNew_Frame_UnifiedPosition;

--各个功能的Frame
local g_XinShouNew_Frames =
{
}

--===============================================
-- 这一段是为了动态显示Button Tips ---------begin
--===============================================
local g_XinShouNew_Event = {
	[1] = {text="双倍乐翻天",  isShow=0,},	 	--双倍乐翻天
	[2] = {text="7日献豪礼",  isShow=0,},	 	--七日献好礼
	[3] = {text="7日献好礼", isShow=0,},  		--七日献好礼2023
	[4] = {text="首充享好礼", isShow=0,},	 		--首充超值赠
	[5] = {text="首充超值赠",isShow=0,}, 		--首充超值赠2023
	[6] = {text="限时充值礼馈", isShow=0,},	 	--限时充值好礼
	[7] = {text="天龙豪侠路", isShow=0,},  		--天龙豪侠路
	[8] = {text="充值超值赠",isShow=0,},  		--充值超值赠
	[9] = {text="升级有好礼", isShow=0,},	 		--升级有好礼
	[10] = {text="升级有好礼",isShow=0,},		--升级有好礼2023
	[11] = {text="英雄百宝囊", isShow=0,},	 		--英雄百宝囊
	[12] = {text="江湖幸运星", isShow=0,},  		--江湖幸运星
	[13] = {text="江湖幸运星",isShow=0,}, --新版江湖幸运星
	[14] = {text="天龙携手行",isShow=0,}, 		--天龙携手行
	[15] = {text="天龙携手行",isShow=0,},		--新版天龙携手行

};

--左侧Button 合集 加这个合集 是因为以后策划 想要某个特定的Button 上移
local g_XinShouNew_Button =
{
}
local g_XinShouNew_Tip =
{
}
local g_HaoXialuRed = {}
local g_Button_StateTemp = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}  --暂时的 后续改  先用
local g_Tips_StateTemp = {0,0,0,0,0,0,0,0,0,0,1}  --暂时的 后续改  先用
local g_lastDay = -1
local g_lastMaiDian = -1
--===============================================
-- 这一段是为了动态显示Button Tips -----------end
--=============================================== 
local g_EventIndex = -1 --当前选中的选项
local g_XinShouNew_ButtonCDTime = 1; --按钮冷却时间
local g_XinShouNew_ButtonLastTime = 0;
local g_XinShouNew_LastClickedId = -1; --上次选中的选项
local g_XinShouNew_EventIndex = -1 --当前选中的选项
local g_XinShouNew_MD = 1533 			--新手嘉年华MD 结束时间 YYMMDDHHMM  --MD_XINSHOUCARN_DATE
--===============================================
-- 首充
--===============================================
--首充奖励物品配表
local g_XinShouNew_ShouChong_Gifts = {
	[1] =   {GiftItemID = 10155006, num = 1,},
	[2] =   {GiftItemID = 39920503, num = 3,},
	[3] =   {GiftItemID = 30900077, num = 2,},
}
--奖励物品配表
local g_XinShouNew_ShouChong_GiftsIcons = {

}
local g_XinShouNew_ShouChong_ButtonState =0;
--
local g_XinShouNew_ShouChong_LoadFirstTime =1;

--===============================================
-- 首充2023
--===============================================
--首充奖励物品配表
local g_XinShouNew_ShouChong_Gifts_2023 = {
	[1] = {
		[1] =   {GiftItemID = 10155006, num = 1},
		[2] =   {GiftItemID = 39920503, num = 3},
		[3] =   {GiftItemID = 39920977, num = 2},
	},
	[2] = {
		[1] =   {GiftItemID = 39920085, num = 20},
		[2] =   {GiftItemID = 39920382, num = 1},
		[3] =   {GiftItemID = 39920181, num = 1},
	},
	[3] = {
		[1] =   {GiftItemID = 39920977, num = 1},
		[2] =   {GiftItemID = 39920181, num = 1},
		[3] =   {GiftItemID = 39924018, num = 1},
	},
}

local g_XinShouNew_ShouChong_CurGiftLevel_2023 =1;
local g_XinShouNew_ShouChong_CurExch_2023 = 0
--奖励物品配表
local g_XinShouNew_ShouChong_GiftsIcons_2023 = {}
local g_XinShouNew_ShouChong_BKImg_2023 = {}
local g_XinShouNew_ShouChong_ButtonState_2023 =0;
--
local g_XinShouNew_ShouChong_LastShow_2023 =0;

--===============================================
-- 限时
--===============================================

--set:ZhizunHaoli","")
local g_XinShouNew_LimitedSaveUp_GiftsImage = {
	[1] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_1", },
	[2] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_2", },
	[3] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_3", },
	[4] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_4", },
	[5] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_5", },
	[6] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_6", },
	[7] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_7", },
	[8] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_8", },
	[9] = {Set ="XSYNewBK02" , Image = "XSYNewBK_LeiChong_HLicon9", },
	[10] ={Set ="XSYNewBK02" , Image = "XSYNewBK_LeiChong_HLicon10", },
}
--Button
local g_XinShouNew_LimitedSaveUp_ButtonDone = { 
}
local g_XinShouNew_LimitedSaveUp_GiftsIcons ={
}
local g_XinShouNew_LimitedSaveUp_Button = { 
}
local g_XinShouNew_LimitedSaveUp_Content = {
	[1] ={Content="#{XSJNH_180111_63}",Tips="#{XSJNH_180111_76}",},
	[2] ={Content="#{XSJNH_180111_64}",Tips="#{XSJNH_180111_77}",},
	[3] ={Content="#{XSJNH_180111_65}",Tips="#{XSJNH_180111_78}",},
}
local g_XinShouNew_LimitedSaveUp_ButtonState = {
	[1] =0,
	[2] =0,
	[3] =0,
};
local g_XinShouNew_LimitedSaveUp_GetGiftsCondition =
{
	[1] = { Exch = 4000, Cost = 4000, },
	[2] = { Exch = 8000, Cost = 8000, },
	[3] = { Exch = 20000, Cost = 20000, },
}
local g_XinShouNew_LimitedSaveUp_WDCImage =
{ 
	[2] = {Set ="set:XSYNew01" , Image = "image:XinShouNew_Time_DisabledDay3", },
	[3] = {Set ="set:XSYNew01" , Image = "image:XinShouNew_Time_DisabledDay7", },
}
 
local g_XinShouNew_LimitedSaveUp_Cost =0;
local g_XinShouNew_LimitedSaveUp_Exch =0;
local g_XinShouNew_LimitedSaveUp_RemainTime =0;
local g_XinShouNew_LimitedSaveUp_RemainDay =0;
local g_XinShouNew_LimitedSaveUp_CurSelect =1;
--===============================================
-- 充值超值赠
--===============================================
local g_XinShouNew_SuperSaveUp_LoadFirstTime = 1
local g_XinShouNew_SuperSaveUp_ScrollbarPosition = 0
--Button
local g_XinShouNew_SuperSaveUp_Buttons = {
}
local g_XinShouNew_SuperSaveUp_ButtonState = {
	[1] =0,
	[2] =0,
	[3] =0,
	[4] =0,
	[5] =0,
	[6] =0,
	[7] =0,
	[8] =0,
	[9] =0,
	[10]=0,
};
local g_XinShouNew_SuperSaveUp_GetGiftsCondition =
{
	[1] = { Exch = 2000, Cost = 2000, },
	[2] = { Exch = 8000, Cost = 8000, },
	[3] = { Exch = 20000, Cost = 20000, },
	[4] = { Exch = 40000, Cost = 40000, },
	[5] = { Exch = 80000, Cost = 80000, },
	[6] = { Exch = 150000, Cost = 150000, },
	[7] = { Exch = 250000, Cost = 250000, },
	[8] = { Exch = 400000, Cost = 400000, },
	[9] = { Exch = 800000, Cost = 800000, },
	[10] ={ Exch = 2000000, Cost = 2000000, },
}
local g_XinShouNew_SuperSaveUp_Cost =0;
local g_XinShouNew_SuperSaveUp_Exch =0;
local g_XinShouNew_SuperSaveUp_ContentButton = {}
local g_XinShouNew_SuperSaveUp_CurrentSelect = 0;
--

local g_XinShouNew_7DayShowTimes =0;
local g_XinShouNew_7DayButtom ={};
local g_MD_XINSHOU_7DAY_1=1534        --【2017Q4】春节新版新手月，7日豪礼
local g_MD_XINSHOU_7DAY_2=1535        --【2017Q4】春节新版新手月，7日豪礼

local g_XinShouNew_7DayPrize_Button = {}
local g_XinShouNew_7DayPrize_Click = 0
local g_XinShouNew_7DayButtonText = {
	[1] = "#{XSJNH_180111_39}",
	[2] = "#{XSJNH_180111_39}",
	[3] = "#{XSJNH_180111_40}",
	[4] = "#{XSJNH_180111_41}",
	[5] = "#{XSJNH_180111_42}",
	[6] = "#{XSJNH_180111_43}",
	[7] = "#{XSJNH_180111_44}",
};
local g_XinShouNew_7DayImage = {
	[1] ={
				[1]="set:XSYNew07 image:XSYNew_7Days_ShowD1",
				[2]="set:XSYNew01 image:XSYNew_7Days_D1",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD1",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay2",
				},
	[2] ={
				[1]="set:XSYNew06 image:XSYNew_7Days_ShowD2",
				[2]="set:XSYNew01 image:XSYNew_7Days_D2",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD2",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay2",				
				},
	[3] ={
				[1]="set:XSYNew06 image:XSYNew_7Days_ShowD3",
				[2]="set:XSYNew01 image:XSYNew_7Days_D3",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD3",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay3",				
				},
	[4] ={
				[1]="set:XSYNew05 image:XSYNew_7Days_ShowD4",
				[2]="set:XSYNew01 image:XSYNew_7Days_D4",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD4",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay4",				
				},
	[5] ={
				[1]="set:XSYNew05 image:XSYNew_7Days_ShowD5",
				[2]="set:XSYNew01 image:XSYNew_7Days_D5",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD5",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay5",				
				},
	[6] ={
				[1]="set:XSYNew04 image:XSYNew_7Days_ShowD6",
				[2]="set:XSYNew01 image:XSYNew_7Days_D6",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD6",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay6",				
				},
	[7] ={
				[1]="set:XSYNew04 image:XSYNew_7Days_ShowD7",
				[2]="set:XSYNew01 image:XSYNew_7Days_D7",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD7",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay7",				
				},	
};


---新7daybegin
local g_XinShouNew_7DayShowTimes_2023 =0;
local g_XinShouNew_7DayButtom_2023 ={};
local g_XinShouNew_7Day_ImgBK_2023 = {}
local g_MD_XINSHOU_7DAY_1_2023=2718
local g_MD_XINSHOU_7DAY_2_2023=2719
local g_MD_XINSHOU_7DAY_1_2023_Consume1 = 2716
local g_MD_XINSHOU_7DAY_1_2023_Consume2 = 2717
local g_XinShouNew_7Day_CurConsume_2023 = 0
local g_XinShouNew_7Day_CurExch_2023 = 0

local g_XinShouNew_7Day_ConsumeLimit1 = {xf = 40000,dh = 40000}
local g_XinShouNew_7Day_ConsumeLimit2 = {xf = 250000,dh = 250000}

local g_XinShouNew_7DayPrize_Button_2023 = {}
local g_XinShouNew_7DayPrize_Click_2023 = 1
local g_XinShouNew_7DayButtonText_2023 = {
	[1] = "#{XSJNH_180111_39}",
	[2] = "#{XSJNH_180111_39}",
	[3] = "#{XSJNH_180111_40}",
	[4] = "#{XSJNH_180111_41}",
	[5] = "#{XSJNH_180111_42}",
	[6] = "#{XSJNH_180111_43}",
	[7] = "#{XSJNH_180111_44}",
};
local g_XinShouNew_7DayImage_2023 = {
	[1] ={
				[1]="set:XSYNew07 image:XSYNew_7Days_ShowD1",
				[2]="set:XSYNew01 image:XSYNew_7Days_D1",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD1",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay1",
				},
	[2] ={
				[1]="set:XSYNew06 image:XSYNew_7Days_ShowD2",
				[2]="set:XSYNew01 image:XSYNew_7Days_D2",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD2",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay2",				
				},
	[3] ={
				[1]="set:XSYNew06 image:XSYNew_7Days_ShowD3",
				[2]="set:XSYNew01 image:XSYNew_7Days_D3",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD3",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay3",				
				},
	[4] ={
				[1]="set:XSYNew05 image:XSYNew_7Days_ShowD4",
				[2]="set:XSYNew01 image:XSYNew_7Days_D4",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD4",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay4",				
				},
	[5] ={
				[1]="set:XSYNew05 image:XSYNew_7Days_ShowD5",
				[2]="set:XSYNew01 image:XSYNew_7Days_D5",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD5",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay5",				
				},
	[6] ={
				[1]="set:XSYNew04 image:XSYNew_7Days_ShowD6",
				[2]="set:XSYNew01 image:XSYNew_7Days_D6",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD6",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay6",				
				},
	[7] ={
				[1]="set:XSYNew04 image:XSYNew_7Days_ShowD7",
				[2]="set:XSYNew01 image:XSYNew_7Days_D7",
				[3]="set:XSYNew03 image:XSYNew_7Days_ItemD7",
				[4]="set:XSYNew01 image:XinShouNew_Time_DisabledDay7",				
				},	
};

---新7dayend


local g_PlayerLevel = 0
local g_CurConsume = 0
local g_CurExch = 0
--【新服欢乐月·升级送好礼】Begin
local g_XinShouNew_LevelUp_PageIndex = 1;		-- 界面显示是分页的,分页索引:0.初入江湖 1.仗剑江湖
local g_XinShouNew_LevelUp_GetGiftLevel = {		-- 领奖等级限制
	[1] = 10,[2] = 20,[3] = 30,[4] = 35,[5] = 40,[6] = 45,[7] = 50,[8] = 55,[9] = 60,[10] = 70,[11] = 80,[12] = 90,[13] = 100,[14] = 130,
}

local g_XinShouNew_LevelUpBtnState = {			-- 领取按钮的状态
	[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1, [9] = 1, [10] = 1, [11] = 1, [12] = 1, [13] = 1,
}

local g_XinShouNew_LevelUpPageState = {			-- 领取在哪个页面
	[1] = 1, [2] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1, [9] = 2, [10] = 2, [11] = 2, [12] = 2, [13] = 2,
}
--界面上显示奖励物品的ICON表
local g_XinShouNew_LevelUp_GiftsIcons = { }
--界面上显示奖励物品的ICON右上角的小图标
local g_XinShouNew_LevelUp_GiftsIconsImages = { }

--是否是第一次加载【升级送好礼】界面
local g_XinShouNew_LevelUp_LoadFirstTime = 1

--界面上的每档奖励展示框
local g_XinShouNew_LevelUp_Frames = { }
--界面【领取奖励】按钮表
local g_XinShouNew_LevelUp_GetGiftsButtonList = {}
--奖励物品配表
local g_XinShouNew_LevelUp_Gifts = {
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

--2023新【新服欢乐月·升级送好礼】Begin
local g_XinShouNew_LevelUp_TotalEnum_2023 = 13   --总行数

local g_XinShouNew_LevelUp_LoadFirstTime_2023 = 1

local g_XinShouNew_LevelUp_GetGiftLevel_2023 = {		-- 领奖等级限制/消费限制
	[1] = { level = 10, consume1 = 40000, consume2 = 250000},
	[2] = { level = 20, consume1 = 40000, consume2 = 250000},
	[3] = { level = 30, consume1 = 40000, consume2 = 250000},
	[4] = { level = 35, consume1 = 40000, consume2 = 250000},
	[5] = { level = 40, consume1 = 40000, consume2 = 250000},
	[6] = { level = 45, consume1 = 40000, consume2 = 250000},
	[7] = { level = 50, consume1 = 40000, consume2 = 250000},
	[8] = { level = 55, consume1 = 40000, consume2 = 250000},
	[9] = { level = 60, consume1 = 40000, consume2 = 250000},
	[10] = { level = 70, consume1 = 40000, consume2 = 250000},
	[11] = { level = 80, consume1 = 40000, consume2 = 250000},
	[12] = { level = 90, consume1 = 40000, consume2 = 250000},
	[13] = { level = 100, consume1 = 40000, consume2 = 250000},
	[14] = { level = 999, consume1 = 999999, consume2 = 999999},
}

local g_XinShouNew_LevelUpBtnState_2023 = {			-- 领取按钮的状态
	[1] = { level = 1, consume1 = 1, consume2 = 1},
	[2] = { level = 1, consume1 = 1, consume2 = 1},
	[3] = { level = 1, consume1 = 1, consume2 = 1},
	[4] = { level = 1, consume1 = 1, consume2 = 1},
	[5] = { level = 1, consume1 = 1, consume2 = 1},
	[6] = { level = 1, consume1 = 1, consume2 = 1},
	[7] = { level = 1, consume1 = 1, consume2 = 1},
	[8] = { level = 1, consume1 = 1, consume2 = 1},
	[9] = { level = 1, consume1 = 1, consume2 = 1},
	[10] = { level = 1, consume1 = 1, consume2 = 1},
	[11] = { level = 1, consume1 = 1, consume2 = 1},
	[12] = { level = 1, consume1 = 1, consume2 = 1},
	[13] = { level = 1, consume1 = 1, consume2 = 1},
}

local g_XinShouNew_LevelUp_List_2023 = ""   --superlist name

local g_XinShouNew_LevelUp_List_Item_2023 = { }

local g_XinShouNew_LevelUp_ListItemText_2023 = 
{
	[1] = "#{XSJNH_180111_96}",
	[2] = "#{XSJNH_180111_97}",
	[3] = "#{XSJNH_180111_98}",
	[4] = "#{XSJNH_180111_99}",
	[5] = "#{XSJNH_180111_100}",
	[6] = "#{XSJNH_180111_101}",
	[7] = "#{XSJNH_180111_102}",
	[8] = "#{XSJNH_180111_103}",
	[9] = "#{XSJNH_180111_104}",
	[10] = "#{XSJNH_180111_105}",
	[11] = "#{XSJNH_180111_106}",
	[12] = "#{XSJNH_180111_107}",
	[13] = "#{XSJNH_180111_108}",
}

--界面上显示奖励物品的ICON表
local g_XinShouNew_LevelUp_GiftsIcons_2023 = 
{
	Normal  = { [1] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon1", [2] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon2", [3] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon3" }, ---, [4] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon4" },
	Consume1 = { [1] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon1" , [2] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon2"},  ---, [3] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon3", [4] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon4" },
	Consume2 = { [1] = "XinShouNew_LevelUp2_Frame3_Bk3_Icon1" , [2] = "XinShouNew_LevelUp2_Frame3_Bk3_Icon2"},  ---, [3] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon3", [4] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon4" },
}
--界面上显示奖励物品的ICON右上角的小图标
local g_XinShouNew_LevelUp_GiftsIconsImages_2023 = 
{
	Normal  = { [1] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon1_Xin" , [2] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon2_Xin", [3] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon3_Xin"}, ---[4] = "XinShouNew_LevelUp2_Frame3_Bk1_Icon4_Xin" },
	Consume1 = { [1] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon1_Xin" , [2] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon2_Xin"}, ---[3] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon3_Xin", [4] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon4_Xin" },
	Consume2 = { [1] = "XinShouNew_LevelUp2_Frame3_Bk3_Icon1_Xin" , [2] = "XinShouNew_LevelUp2_Frame3_Bk3_Icon2_Xin"}, ---[3] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon3_Xin", [4] = "XinShouNew_LevelUp2_Frame3_Bk2_Icon4_Xin" },
}

--界面【领取奖励】按钮表

--奖励物品配表
local g_XinShouNew_LevelUp_Gifts_2023 = {
	[1] ={
			Normal = {
				{GiftItemID = 30008080, num = 1},{GiftItemID = 10124418, num = 1},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			},
		},
	[2] ={ 
			Normal = {
				{GiftItemID = 31000006, num = 1},{GiftItemID = 30607003, num = 1},
			}, 
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[3] ={
			Normal = {
				{GiftItemID = 30008027, num = 1},{GiftItemID = 31000007, num = 1},{GiftItemID = 30505216, num = 1}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[4] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 1},{GiftItemID = 31000006, num = 1},{GiftItemID = 30503132, num = 2}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[5] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 2},{GiftItemID = 30309985, num = 1},{GiftItemID = 31000007, num = 1}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[6] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 1},{GiftItemID = 30900124, num = 1},{GiftItemID = 38001553, num = 2}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[7] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 2},{GiftItemID = 20310168, num = 5},{GiftItemID = 20310021, num = 10},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 6},{GiftItemID = 38001553, num = 5},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 6},{GiftItemID = 38001554, num = 1},
			}
		},
	[8] ={ 
			Normal = {
				{GiftItemID = 30008027 ,num = 2},{GiftItemID = 30700241, num = 1},{GiftItemID = 38000833, num = 3},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 6},{GiftItemID = 38006284, num = 1},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 6},{GiftItemID = 38006285, num = 1},
			}
		},	
	[9] ={  
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 20310158, num = 2},{GiftItemID = 30700249, num = 5},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 8},{GiftItemID = 30700241, num = 3},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 8},{GiftItemID = 20310131, num = 10},
			}
		},
	[10] ={ 	
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 38000831, num = 2},{GiftItemID = 30008027, num = 2},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 8},{GiftItemID = 20502003, num = 1},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 8},{GiftItemID = 20502003, num = 3},
			}
		},
	[11] ={ 
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 38000989, num = 3},{GiftItemID = 38000930, num = 50},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 10},{GiftItemID = 20501003, num = 1},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 10},{GiftItemID = 20501003, num = 3},
			}
		},
	[12] ={
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 30505805, num = 1},{GiftItemID = 30505817, num = 5},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 10},{GiftItemID = 30505805, num = 5},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 10},{GiftItemID = 30505817, num = 10},
			}
		},
	[13] ={ 
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 30505806, num = 1},{GiftItemID = 30505908, num = 5},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 20},{GiftItemID = 30505908, num = 10},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 20},{GiftItemID = 30505706, num = 1},
			}
		},
}
--2023新【新服欢乐月·升级送好礼】End

local g_XinShouNew_Heroes_Road_2023 = 0

--江湖幸运星begin
local g_LuckyDrawCount 			= 0;
local g_LuckyDrawRemainTime = 0;
local g_LuckyDrawTotalCount =3; 
--抽中哪个奖项
local g_LuckyDrawIndex = 0
--界面上显示购买物品的ICON表
local g_XinShouNew_LuckyDraw_GiftsIcons = { }
--界面上显示购买物品的ICON右上角的小图标
local g_XinShouNew_LuckyDraw_GiftsIconImages = { } 
--界面是否是第一次加载,如果是的话,需要创建物品图标
local g_XinShouNew_LuckyDraw_LoadFirstTime = 1 


local g_XinShouNew_LuckyDraw_GiftLightImage =
{	
}

local g_XinShouNew_LuckyDraw_TimerLength = 5000
--江湖幸运星end

--===============================================
-- 天龙豪侠路-begin
--===============================================


local g_XinShouNew_Heroes_Road_LastClickedId = -1; --上次选中的选项

local g_XinShouNew_Heroes_Road_Button =
{
} 

local g_XinShouNew_Heroes_Road_HX_Value_MD = 1518

-- local g_XinShouNew_Heroes_ItemBounsId = 39921378
local g_XinShouNew_Heroes_ItemBounsId = 39925365

local g_XinShouNew_Heroes_ButtonTextSelected = {
"#{XSJNH_180131_272}",
"#{XSJNH_180131_273}",
"#{XSJNH_180131_274}",
"#{XSJNH_180131_275}",
"#{XSJNH_180131_276}",
"#{XSJNH_180131_277}",
"#{XSJNH_180131_278}",
}

local g_XinShouNew_Heroes_ButtonText = {
"#{XSJNH_180125_260}",
"#{XSJNH_180125_261}",
"#{XSJNH_180125_262}",
"#{XSJNH_180125_263}",
"#{XSJNH_180125_264}",
"#{XSJNH_180125_265}",
"#{XSJNH_180125_266}",
}

--===============================================
-- 天龙豪侠路-end
--===============================================

--英雄百宝囊begin
local g_XinShouNew_BaiBaoBtnState = {			-- 领取按钮的状态
	[1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, 
}
--奖励框
local g_XinShouNew_BaiBao_Bk = {}

--界面上显示购买物品的ICON表
local g_XinShouNew_BaiBao_GiftsIcons = { }
--界面上显示购买物品的ICON右上角的小图标
local g_XinShouNew_BaiBao_GiftsIconImages = { }

--界面是否是第一次加载,如果是的话,需要创建物品图标
local g_XinShouNew_BaiBao_LoadFirstTime = 1

--界面【领取购买】按钮表
local g_XinShouNew_BaiBao_GetGiftsButtonList = {}
--购买物品配表
local g_XinShouNew_BaiBao_Gifts =
{
	[1] = 	{
			{GiftItemID = 39920172, num = 2,},{GiftItemID = 39920838, num = 1,}
		,},
	[2] =	{	
			{GiftItemID = 39920172, num = 2,},{GiftItemID = 39920839, num = 2},{GiftItemID = 38005783, num = 1}
		,},
	[3] =   {
			{GiftItemID = 39920172, num = 2,},{GiftItemID = 39920085, num = 10},{GiftItemID = 39920334, num = 3},{GiftItemID = 39920332, num = 2}
		,},
	[4] =   {
			{GiftItemID = 39920172, num = 2,},{GiftItemID = 38005784, num = 1,},{GiftItemID = 39920383, num = 1}
		,},
	[5] =   {
			{GiftItemID = 39920172, num = 2,},{GiftItemID = 39920335, num = 2,},{GiftItemID = 38005785, num = 6}
		,},
	[6] =   {
			{GiftItemID = 39920172, num = 2,},{GiftItemID = 38005782, num = 2,},{GiftItemID = 39920567, num = 4,},{GiftItemID = 39920505, num = 4}
		,},
} 
local g_XinShouNew_BaiBao_GetGiftsCondition = 
{
	[1] = {  Level = 30,Cost = 90,	PriCost = 150,  Discount = "6" },				--英雄百宝囊
	[2] = {  Level = 40,Cost = 394, PriCost = 656, Discount = "6" 	},
	[3] = {  Level = 50,Cost = 576, PriCost = 960, Discount = "6" },
	[4] = {  Level = 60,Cost = 960, PriCost = 1600, Discount = "6" },
	[5] = {  Level = 70,Cost = 1032, PriCost = 1720, Discount = "6" },
	[6] = {  Level = 80,Cost = 1104, PriCost = 1840, Discount = "6" 	},		 
}
 
local g_XinShouNew_HeroBag_NotifyTipsControlList	= { }	--【英雄百宝囊】界面上显示达成条件的Text控件,策划要求按照完成情况显示成动态的=...=
local g_XinShouNew_PrizeItemButtonIcon = "set:CommonFrame20 image:Item_New"
local g_XinShouNew_HeroBag_IsShowTips =1;
--英雄百宝囊end

--社交达人汇
local g_SheJiaoButtons = {}
local g_SheJiaoButtonKongs = {}
local g_SheJiaoButtonDisbles = {}
local g_SheJiaoButtonAima = {}
local g_SheJiaoRewardBtnState = {
[1] = 0, --结婚奖励按钮状态 0不可领取 1可领取 2已领取
[2] = 0, --结拜
[3] = 0, --拜师
[4] = 0, --收徒
[5] = 0, --帮会
}
local g_SheJiaoBtnToolTips = 
{
	[1] ="#{XSJNH_180111_169}",
	[2] ="#{XSJNH_180111_175}",
	[3] ="#{XSJNH_180111_181}",
	[4] ="#{XSJNH_180111_187}",
	[5] ="#{XSJNH_180111_193}",
}
local g_SheJiaoBtnToolTipsDisbles = 
{
	[1] ="#{XSJNH_180111_172}",
	[2] ="#{XSJNH_180111_178}",
	[3] ="#{XSJNH_180111_184}",
	[4] ="#{XSJNH_180111_190}",
	[5] ="#{XSJNH_180111_196}",
}
local g_SheJiaoDaRenGitf =
{
	[1] = 
	{
		{GiftItemID = 39920913,num = 2},{GiftItemID = 39921125,num = 1}
	},
	[2] = 
	{
		{GiftItemID = 39921106,num = 1}
	},
	[3] = 
	{
		{GiftItemID = 39920280,num = 1},{GiftItemID = 39921124,num = 1}
	},
	[4] = 
	{
		{GiftItemID = 39921123,num = 1}
	},
	[5] = 
	{
		{GiftItemID = 39921166,num = 1}
	},
}
local g_SheJiaoSheJiaoDaRenIcons = {}
local g_SheJiaoDeadLine = 0
local g_bInitSheJiao = 0
local g_SheJiaoLastClick = 0
local g_SheJiaoIsFillIcon = 0

--双倍乐翻天begin
local g_XinShouNew_Double = 
{
	[1] = 0,
	[2] = 0,
}
--双倍乐翻天end

--天龙携手行2018新版
local g_SheJiaoNewPages = {}
local g_SheJiaoNewPageButtons = {}
local g_SheJiaoNewCurPage = 0
local g_SheJiaoNewActionCurAchieveId = 0
--定义活动所有的事件
local g_SheJiaoNew_EventId2Data = 
{
	[1] = 	{Len=1,Start = 0,MaxValue = 1},   	 --结婚
	[2] = 	{Len=7,Start = 1,MaxValue = 1},	 --与配偶同时在线
	[3] = 	{Len=1,Start = 8,MaxValue = 1	},	 --私聊配偶
	[4] = 	{Len=1,Start = 9,MaxValue = 1	},	 --与配偶到达指定点
	[5] = 	{Len=1,Start = 10,MaxValue = 1	},	 --完成一次伉俪情深
	[6] = 	{Len=1,Start = 11,MaxValue = 1	},	 --完成一次心有灵犀
	[7] = 	{Len=1,Start = 12,MaxValue = 1},	 --与配偶一起回到洛阳
	[8] = 	{Len=12,Start = 13,MaxValue = 900}, --获得恩爱值
	[9] = 	{Len=1,Start = 25,MaxValue = 1	},	 --加入帮会
	[10] = 	{Len=2,Start = 26,MaxValue = 1	},	 --完成 1 次帮会扫雷
	[11] = 	{Len=1,Start = 28,MaxValue = 1	},	 --领取 1 次扫雷boss奖励
	[12] = 	{Len=7,Start = 29,MaxValue = 3},   --与帮会成员完成 3 次副本
	[13] = 	{Len=7,Start = 36,MaxValue = 2},   --完成 2 次帮会扫雷
	[14] = 	{Len=1,Start = 43,MaxValue = 1	},   --完成 1 次凤凰古城
	[15] = 	{Len=14,Start = 44,MaxValue = 300}, --与帮会成员杀怪
	[16] = 	{Len=12,Start = 58,MaxValue = 2500},  --帮贡
	[17] =	{Len=1,Start = 70,MaxValue = 1},	 --结拜
	[18] =  {Len=1,Start = 71,MaxValue = 1},	 --拜师
	[19] =  {Len=1,Start = 72,MaxValue = 1},	 --收徒
	--以下数据位用于玩家个别数据的存储，不作为事件
	[20] =  {Len=4,Start = 73,MaxValue = 3},    --旅行坐标随机index
	[21] =  {Len=1,Start = 77,MaxValue = 1},	--是否数据初始化
	[22] =  {Len=4,Start = 78,MaxValue = 7},    --结婚任务解锁的天数
}
local g_SheJiaoNew_MarryUnkLockDayBit = 22

local g_SheJiaoNew_AhieveIdData = 
{
	[1]  = 	{EventId=1,NeedValue = 1,		RewardList={Id=39921125,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_119}",unlockDic="#{TLXS_180427_133}",szTitleName="#{TLXS_180427_133}",szNameDic="#{TLXS_180427_21}",Desc="#{TLXS_180427_14}",},    	 --结婚1次
	[2]  = 	{EventId=2,NeedValue = 1,		RewardList={Id=39921447,Count = 40,bag=1,mat=0},szUnReward="#{TLXS_180427_120}",unlockDic="#{TLXS_180427_134}",szTitleName="#{TLXS_180427_134}",szNameDic="#{TLXS_180427_22}",Desc="#{TLXS_180427_15}",},   	 --与配偶同时在线1小时
	[3]  = 	{EventId=3,NeedValue = 1,		RewardList={Id=39920913,Count = 2,bag=1,mat=0},szUnReward="#{TLXS_180427_121}",unlockDic="#{TLXS_180427_135}",szTitleName="#{TLXS_180427_135}",szNameDic="#{TLXS_180427_23}",Desc="#{TLXS_180427_16}",},	   	 --与配偶私聊一次
	[4]  = 	{EventId=4,NeedValue = 1,		RewardList={Id=39921448,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_122}",unlockDic="#{TLXS_180427_136}",szTitleName="#{TLXS_180427_136}",szNameDic="#{TLXS_180427_24}",Desc="#{TLXS_180427_17}",},    	 --与配偶同时去目标点
	[5]  = 	{EventId=5,NeedValue = 1,		RewardList={Id=39921449,Count = 5,bag=1,mat=0},szUnReward="#{TLXS_180427_123}",unlockDic="#{TLXS_180427_137}",szTitleName="#{TLXS_180427_137}",szNameDic="#{TLXS_180427_25}",Desc="#{TLXS_180427_18}",},	   	 --与配偶完成一次伉俪情深
	[6]  = 	{EventId=6,NeedValue = 1,		RewardList={Id=39921450,Count = 7,bag=1,mat=0},szUnReward="#{TLXS_180427_124}",unlockDic="#{TLXS_180427_138}",szTitleName="#{TLXS_180427_138}",szNameDic="#{TLXS_180427_26}",Desc="#{TLXS_180427_19}",},    	 --与配偶完成一次心有灵犀
	[7]  = 	{EventId=7,NeedValue = 1,		RewardList={Id=39920549,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_125}",unlockDic="#{TLXS_180427_139}",szTitleName="#{TLXS_180427_139}",szNameDic="#{TLXS_180427_27}",Desc="#{TLXS_180427_20}",},	   	 --与配偶一起回到洛阳
	[8]  = 	{EventId=8,NeedValue = 200,	RewardList={Id=39921313,Count = 4,bag=1,mat=0},szUnReward="#{TLXS_180427_151}",unlockDic="",szNameDic="#{TLXS_180427_94}",Desc="",TrackDesc="",},	 --获得恩爱值1000
	[9]  = 	{EventId=8,NeedValue = 500,	RewardList={Id=39920538,Count = 4,bag=1,mat=0},szUnReward="#{TLXS_180427_151}",unlockDic="",szNameDic="#{TLXS_180427_94}",Desc="",TrackDesc="",},	 --获得恩爱值2000
	[10] = 	{EventId=8,NeedValue = 900,	RewardList={Id=39920537,Count = 5,bag=1,mat=0},szUnReward="#{TLXS_180427_151}",unlockDic="",szNameDic="#{TLXS_180427_94}",Desc="",TrackDesc="",},	 --获得恩爱值3000
	[11] = 	{EventId=9,NeedValue = 1,		RewardList={Id=39920280,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_126}",unlockDic="#{TLXS_180427_38}",szTitleName="#{TLXS_180427_142}",szNameDic="#{TLXS_180427_38}",Desc="#{TLXS_180427_31}",},	     --加入一次帮会
	[12] = 	{EventId=10,NeedValue = 1,		RewardList={Id=39921124,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_127}",unlockDic="#{TLXS_180427_39}",szTitleName="#{TLXS_180427_143}",szNameDic="#{TLXS_180427_39}",Desc="#{TLXS_180427_32}",},	 --完成 1 次帮会扫雷
	[13] = 	{EventId=11,NeedValue = 1,		RewardList={Id=39921451,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_128}",unlockDic="#{TLXS_180427_40}",szTitleName="#{TLXS_180427_144}",szNameDic="#{TLXS_180427_40}",Desc="#{TLXS_180427_33}",},	 --领取 1 次扫雷boss奖励
	[14] = 	{EventId=12,NeedValue = 3,		RewardList={Id=39920505,Count = 2,bag=1,mat=0},szUnReward="#{TLXS_180427_129}",unlockDic="#{TLXS_180427_41}",szTitleName="#{TLXS_180427_145}",szNameDic="#{TLXS_180427_41}",Desc="#{TLXS_180427_34}",},	 --与帮会成员完成3次副本
	[15] = 	{EventId=13,NeedValue = 2,	RewardList={Id=39921442,Count = 5,bag=1,mat=0},szUnReward="#{TLXS_180427_130}",unlockDic="#{TLXS_180427_42}",szTitleName="#{TLXS_180427_146}",szNameDic="#{TLXS_180427_42}",Desc="#{TLXS_180427_35}",},	 --完成 2 次帮会扫雷
	[16] = 	{EventId=14,NeedValue = 1,		RewardList={Id=39921452,Count = 50,bag=1,mat=0},szUnReward="#{TLXS_180427_131}",unlockDic="#{TLXS_180427_43}",szTitleName="#{TLXS_180427_147}",szNameDic="#{TLXS_180427_43}",Desc="#{TLXS_180427_36}",},      --完成 1 次凤凰古城
	[17] = 	{EventId=15,NeedValue = 300,	RewardList={Id=39920181,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_132}",unlockDic="#{TLXS_180427_44}",szTitleName="#{TLXS_180427_148}",szNameDic="#{TLXS_180427_44}",Desc="#{TLXS_180427_37}",},  --与帮会成员杀怪10000只
	[18] = 	{EventId=16,NeedValue = 500,	RewardList={Id=39920378,Count = 3,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},	 --获得帮贡500
	[19] = 	{EventId=16,NeedValue = 1000,	RewardList={Id=39921452,Count = 100,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},    --获得帮贡1000
	[20] = 	{EventId=16,NeedValue = 1750,	RewardList={Id=39921442,Count = 20,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},    --获得帮贡1500
	[21] = 	{EventId=16,NeedValue = 2500,	RewardList={Id=38001090,Count = 2,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},    --获得帮贡2000
	[22] = 	{EventId=17,NeedValue = 1,		RewardList={Id=39921445,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_152}",unlockDic="",szNameDic="#{TLXS_180427_95}",Desc="结拜：义结金兰，领取专属贺礼！(字典呢？)",},   --结拜1次
	[23] = 	{EventId=18,NeedValue = 1,		RewardList={Id=39921446,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_153}",unlockDic="",szNameDic="#{TLXS_180427_97}",Desc="拜师：名师高徒，领取专属贺礼！(字典呢？)",},    --拜师1次
	[24] = 	{EventId=19,NeedValue = 1,		RewardList={Id=39921454,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_154}",unlockDic="",szNameDic="#{TLXS_180427_96}",Desc="收徒：桃李天下，领取专属贺礼！(字典呢？)",},   --收徒1次
}
local g_SheJiaoNew_GiftActions = {}
local g_SheJiaoNew_ProcessList = {}
local g_SheJiaoNew_PageButtonList = {}
local g_SheJiaoNew_PageHasAchieves = 
{
	[1] = {1,2,3,4,5,6,7,8,9,10},
	[2] = {11,12,13,14,15,16,17,18,19,20,21},
	[3] = {22},
	[4] = {23},
	[5] = {24},
}
local g_SheJiaoNew_RandPosTips = 
{
	[1] = "#{TLXS_180427_155}",
	[2] = "#{TLXS_180427_156}",
	[3] = "#{TLXS_180427_157}",
}
local g_SheJiaoNew_AhieveDataPool = {0,0,0}
local g_SheJiaoNew_RewardData = 0
local g_SheJiaoNew_CreateTime = 0
--天龙携手行2018新版end

local g_KajiTable_XSJNH = {
	--充值超值赠
	[1] = {
		[0] = {
			[1] = 	{
				{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920977, num = 2,}
				,},
			[2] =	{
					{GiftItemID = 39921376, num = 1,},{GiftItemID = 39920977, num = 3,},{ GiftItemID = 39920181, num = 2,}		 
				,},
			[3] =   {
					{GiftItemID = 39920977, num = 4,},{GiftItemID = 39920181, num = 2,},{GiftItemID = 38005782, num = 1,}	 
				,},
			[4] = 	{
					{GiftItemID = 39920397, num = 1,},{GiftItemID = 39920396, num = 1,},{ GiftItemID = 39920383, num = 1,}
				,},
			[5] =	{
					{GiftItemID = 39920181, num = 2,},{GiftItemID = 38005789, num = 1,},{ GiftItemID = 38005785, num = 5,}		 
				,},
			[6] =   {
					{GiftItemID = 39921379, num = 1,},{GiftItemID = 38005786, num = 1,},{GiftItemID = 39920490, num = 5,}	 
				,},
			[7] = 	{
					{GiftItemID = 39920181, num = 3,},{GiftItemID = 38005787, num = 1,},{ GiftItemID = 38005785, num = 10,}
				,},
			[8] =	{
					{GiftItemID = 38005788, num = 1,},{GiftItemID = 38005789, num = 2,},{ GiftItemID = 38005786, num = 2,}	 
				,},
			[9] =   {
					{GiftItemID = 39920181, num = 4,},{GiftItemID = 38005787, num = 2,},{GiftItemID = 38005785, num = 20,}	 
				,},
			[10] =   {
					{GiftItemID = 39921380, num = 1,},{GiftItemID = 39921668, num = 1,},{GiftItemID = 39920981, num = 1,}	 
				,},
		},
		[1] = {
			[1] = 	{
				{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920977, num = 2,}
				,},
			[2] =	{
					{GiftItemID = 39921376, num = 1,},{GiftItemID = 39920977, num = 3,},{ GiftItemID = 39920181, num = 2,}		 
				,},
			[3] =   {
					{GiftItemID = 39920977, num = 4,},{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920267, num = 5,}	 
				,},
			[4] = 	{
					{GiftItemID = 39920397, num = 1,},{GiftItemID = 39920396, num = 1,},{ GiftItemID = 39920383, num = 1,}
				,},
			[5] =	{
					{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920490, num = 5,},{ GiftItemID = 39920329, num = 5,}		 
				,},
			[6] =   {
					{GiftItemID = 39921379, num = 1,},{GiftItemID = 39922089, num = 1,},{GiftItemID = 39920490, num = 5,}	 
				,},
			[7] = 	{
					{GiftItemID = 39920181, num = 3,},{GiftItemID = 39920089, num = 25,},{ GiftItemID = 39920329, num = 10,}
				,},
			[8] =	{
					{GiftItemID = 39920329, num = 15,},{GiftItemID = 39920383, num = 2,},{ GiftItemID = 39920334, num = 5,}	 
				,},
			[9] =   {
					{GiftItemID = 39920181, num = 4,},{GiftItemID = 39923526, num = 2,},{GiftItemID = 39920329, num = 20,}	 
				,},
			[10] =   {
					{GiftItemID = 39921380, num = 1,},{GiftItemID = 39923527, num = 1,} 
				,},
		}
	},
	--7日送好礼展示
	[2] = {
		[0] = {
			[1] ={
				[1]={ItemID = 39920181, num = 1,},
				[2]={ItemID = 39920066, num = 1,},
				[3]={ItemID = 39921272, num = 1,},
				},
			[2] ={
				[1]={ItemID = 39921375, num = 1,},
				[2]={ItemID = 39920172, num = 1,},
				[3]={ItemID = 39920545, num = 1,},
				},
			[3] ={
				[1]={ItemID = 39920490, num = 3,},
				[2]={ItemID = 39921313, num = 3,},
				[3]={ItemID = 39920311, num = 3,},
				},
			[4] ={
				[1]={ItemID = 39920999, num = 3,},
				[2]={ItemID = 39920332, num = 5,},
				[3]={ItemID = 39920334, num = 5,},
				},
			[5] ={
				[1]={ItemID = 39920181, num = 1,},
				[2]={ItemID = 39920505, num = 3,},
				[3]={ItemID = 39920329, num = 3,},
				},
			[6] ={
				[1]={ItemID = 39920397, num = 1,},
				[2]={ItemID = 39920163, num = 50,},
				[3]={ItemID = 39920162, num = 25,},
				},
			[7] ={
				[1]={ItemID = 39920396, num = 1,},
				[2]={ItemID = 39920163, num = 50,},
				[3]={ItemID = 39920162, num = 25,},
				},	
		},
		[1] = {
			[1] ={
				[1]={ItemID = 39920181, num = 1,},
				[2]={ItemID = 39920066, num = 1,},
				[3]={ItemID = 39921272, num = 1,},
				},
			[2] ={
				[1]={ItemID = 39921375, num = 1,},
				[2]={ItemID = 39920172, num = 1,},
				[3]={ItemID = 39920545, num = 1,},
				},
			[3] ={
				[1]={ItemID = 39920490, num = 3,},
				[2]={ItemID = 39921313, num = 3,},
				[3]={ItemID = 39920311, num = 3,},
				},
			[4] ={
				[1]={ItemID = 39920999, num = 3,},
				[2]={ItemID = 39920332, num = 5,},
				[3]={ItemID = 39920334, num = 5,},
				},
			[5] ={
				[1]={ItemID = 39920181, num = 1,},
				[2]={ItemID = 39920383, num = 1,},
				[3]={ItemID = 39920329, num = 3,},
				},
			[6] ={
				[1]={ItemID = 39920397, num = 1,},
				[2]={ItemID = 39920085, num = 10,},
				[3]={ItemID = 39920329, num = 3,},
				},
			[7] ={
				[1]={ItemID = 39920396, num = 1,},
				[2]={ItemID = 39920085, num = 10,},
				[3]={ItemID = 39920329, num = 3,},
				},
		}
	},
	--限时充值好礼
	[3] = {
		[0] = {
			[1] = 	{
				{GiftItemID = 39920085, num = 5,},{GiftItemID = 38005781, num = 1,},{ GiftItemID = 39920235, num = 1,}
			,},
			[2] =	{
				{GiftItemID = 39920977, num = 1,},{GiftItemID = 38005782, num = 1,},{ GiftItemID = 39920181, num = 1,}	 
			,},
			[3] =   {
				{GiftItemID = 39920977, num = 2,},{GiftItemID = 39920829, num = 1,},{GiftItemID = 39920181, num = 2,}	 
			,},
		},
		[1] = {
			[1] = 	{
				{GiftItemID = 39920085, num = 5,},{GiftItemID = 39920999, num = 1,},{ GiftItemID = 39920235, num = 1,}
			,},
			[2] =	{
				{GiftItemID = 39920977, num = 1,},{GiftItemID = 39920267, num = 2,},{ GiftItemID = 39920181, num = 1,}	 
			,},
			[3] =   {
				{GiftItemID = 39920977, num = 2,},{GiftItemID = 39920829, num = 1,},{GiftItemID = 39920181, num = 2,}	 
			,},
		}
	},
	--升级赠好礼 需要隐藏的奖励等级index段
	[4] = {
		[0] = {0,0},
		[1] = {10,13}
	},
	--英雄百宝囊 奖励maxindex
	[5] = {
		[0] = 6,
		[1] = 4
	},
	--江湖幸运星 抽奖展示道具
	[6] = {
		[0] = {
			[1] = 	{
				{GiftItemID = 39920588, num = 1,}
			,},
			[2] =	{	
					{GiftItemID = 39920589, num = 1,}
				,},
			[3] =   {
					{GiftItemID = 39920590, num = 1,}
				,},
			[4] =   {
					{GiftItemID = 39920399, num = 1,}
				,},
			[5] =   {
					{GiftItemID = 39920840, num = 1,}
				,},
			[6] =   {
					{GiftItemID = 39920099, num = 1,}
				,},
			[7] =   {
					{GiftItemID = 39920841, num = 1,}
				,},
			[8] =   {
					{GiftItemID = 39920842, num = 1,}
				,},
			[9] =   {
					{GiftItemID = 39920591, num = 1,}
				,},
		},
		[1] = {
			[1] = 	{
				{GiftItemID = 39920588, num = 1,}
			,},
			[2] =	{	
					{GiftItemID = 39920589, num = 1,}
				,},
			[3] =   {
					{GiftItemID = 39920590, num = 1,}
				,},
			[4] =   {
					{GiftItemID = 39920399, num = 1,}
				,},
			[5] =   {
					{GiftItemID = 39920840, num = 1,}
				,},
			[6] =   {
					{GiftItemID = 39923621, num = 1,}
				,},
			[7] =   {
					{GiftItemID = 39920841, num = 1,}
				,},
			[8] =   {
					{GiftItemID = 39920842, num = 1,}
				,},
			[9] =   {
					{GiftItemID = 39920591, num = 1,}
				,},
		}
	},
	--7日送好礼展示2023
	[7] = {
		[0] = {
			[1] ={	{ItemID = 39920181, num = 1},{ItemID = 39920066, num = 1},{ItemID = 39921272, num = 1},{ItemID = 39920181, num = 1},{ItemID = 39920181, num = 2}},
			[2] ={	{ItemID = 39921375, num = 1},{ItemID = 39920172, num = 1},{ItemID = 39920545, num = 1},{ItemID = 39921375, num = 2},{ItemID = 39921375, num = 5}},
			[3] ={	{ItemID = 39920490, num = 3},{ItemID = 39921313, num = 3},{ItemID = 39920311, num = 3},{ItemID = 39924121, num = 1},{ItemID = 39924122, num = 1}},
			[4] ={	{ItemID = 39920999, num = 3},{ItemID = 39920332, num = 5},{ItemID = 39920334, num = 5},{ItemID = 39920181, num = 1},{ItemID = 39920181, num = 2}},
			[5] ={	{ItemID = 39920181, num = 1},{ItemID = 39920505, num = 3},{ItemID = 39920329, num = 3},{ItemID = 39920397, num = 1},{ItemID = 39920566, num = 1}},
			[6] ={	{ItemID = 39920397, num = 1},{ItemID = 39920163, num = 50},{ItemID = 39920162, num = 25},{ItemID = 39920396, num = 1},{ItemID = 39920565, num = 1}},
			[7] ={	{ItemID = 39920396, num = 1},{ItemID = 39920163, num = 50},{ItemID = 39920162, num = 25},{ItemID = 39922051, num = 1},{ItemID = 39921051, num = 5}},
		},
		[1] = {
			[1] ={	{ItemID = 39920181, num = 1},{ItemID = 39920066, num = 1},{ItemID = 39921272, num = 1},{ItemID = 39920181, num = 1},{ItemID = 39920181, num = 2}},
			[2] ={	{ItemID = 39921375, num = 1},{ItemID = 39920172, num = 1},{ItemID = 39920545, num = 1},{ItemID = 39921375, num = 2},{ItemID = 39921375, num = 5}},
			[3] ={	{ItemID = 39920490, num = 3},{ItemID = 39921313, num = 3},{ItemID = 39920311, num = 3},{ItemID = 39924121, num = 1},{ItemID = 39924122, num = 1}},
			[4] ={	{ItemID = 39920999, num = 3},{ItemID = 39920332, num = 5},{ItemID = 39920334, num = 5},{ItemID = 39920181, num = 1},{ItemID = 39920181, num = 2}},
			[5] ={	{ItemID = 39920181, num = 1},{ItemID = 39920383, num = 1},{ItemID = 39920329, num = 3},{ItemID = 39920397, num = 1},{ItemID = 39920566, num = 1}},
			[6] ={	{ItemID = 39920397, num = 1},{ItemID = 39920085, num = 10},{ItemID = 39920329, num = 3},{ItemID = 39920396, num = 1},{ItemID = 39920565, num = 1}},
			[7] ={	{ItemID = 39920396, num = 1},{ItemID = 39920085, num = 10},{ItemID = 39920329, num = 3},{ItemID = 39922051, num = 1},{ItemID = 39921051, num = 5}},
		}
	},
}
--2023江湖幸运星begin
local g_NewLuckyDraw_TodayPoint = 0;
local g_NewLuckyDraw_TodayOnlineTime = 0;
local g_NewLuckyDraw_SignCount = 0;
local g_NewLuckyDraw_Flag = {0,0,0}
local g_NewLuckyDraw_LJ_Flag = {0,0,0,0,0,0,0}

local g_XinShouNew_LuckStar2_Action1 = {}
local g_XinShouNew_LuckStar2_Action1_Image = {}
local g_XinShouNew_LuckStar2_Action1_Xin = {}

local g_XinShouNew_LuckStar2_Action2 = {}
local g_XinShouNew_LuckStar2_Action2_Image = {}
local g_XinShouNew_LuckStar2_Action2_Xin = {}


--在线时长(分钟)
local g_NewLuckyDraw_NeedTime = {
	[1] = 30,
	[2] = 60,
	[3] = 120,
}
--签到次数
local g_NewLuckyDraw_TotalCount = {
	[1] = 1,
	[2] = 3,
	[3] = 5,
	[4] = 8,
	[5] = 12,
	[6] = 16,
	[7] = 20,
}
--2023江湖幸运星end

local g_XinShouNew_2606S_GiftInfo =
{
	[1] = { --累充
		[1] = 	{
			{GiftItemID = 30008027, num = 2,},{GiftItemID = 30900077, num = 2,}
			,},
		[2] =	{
				{GiftItemID = 39921376, num = 1,},{GiftItemID = 30900077, num = 3,},{GiftItemID = 30008027, num = 2,}	  
			,},
		[3] =   {
				{GiftItemID = 30900077, num = 4,},{GiftItemID = 30008027, num = 2,},{GiftItemID = 38005782, num = 1,}
			,},
		[4] =   {
				{GiftItemID = 20502003, num = 1,},{GiftItemID = 20501003, num = 1,},{GiftItemID = 30008048, num = 1,}
			,},
		[5] =   {
				{GiftItemID = 30008027, num = 2,},{GiftItemID = 38008712, num = 1,},{GiftItemID = 38005785, num = 5,}
			,},
		[6] = 	{
				{GiftItemID = 38002176, num = 1,},{GiftItemID = 38005786, num = 1,},{GiftItemID = 38000992, num = 5,}
			,},
		[7] =	{
				{GiftItemID = 30008027, num = 3,},{GiftItemID = 38005786, num = 1,},{GiftItemID = 38005785, num = 10,}
			,},
		[8] =   {
				{GiftItemID = 38005788, num = 1,},{GiftItemID = 38008712, num = 2,},{GiftItemID = 38005786, num = 2,}
			,},
		[9] =   {
				{GiftItemID = 30008027, num = 4,},{GiftItemID = 38005786, num = 2,},{GiftItemID = 38005785, num = 20,}
			,},
		[10] =   {
				{GiftItemID = 10125108, num = 1,},{GiftItemID = 10141411, num = 1,},{GiftItemID = 38008711, num = 1,}
			,},
	},
	[2] = { --升级20203
		[1] ={
				Normal = {
					{GiftItemID = 30008080, num = 1},{GiftItemID = 10124418, num = 1},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 4},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 4},
				},
			},
		[2] ={ 
				Normal = {
					{GiftItemID = 31000006, num = 1},{GiftItemID = 30607003, num = 1},
				}, 
				Consume1 = {
					{GiftItemID = 30008080, num = 4},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 4},
				}
			},
		[3] ={
				Normal = {
					{GiftItemID = 30008027, num = 1},{GiftItemID = 31000007, num = 1},{GiftItemID = 30505216, num = 1},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 4},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 4},
				}
			},
		[4] ={ 
				Normal = {
					{GiftItemID = 30008027, num = 1},{GiftItemID = 31000006, num = 1},{GiftItemID = 30503132, num = 2},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 4},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 4},
				}
			},
		[5] ={ 
				Normal = {
					{GiftItemID = 30008027, num = 2},{GiftItemID = 30309985, num = 1},{GiftItemID = 31000007, num = 1},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 4},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 4},
				}
			},
		[6] ={ 
				Normal = {
					{GiftItemID = 30008027, num = 1},{GiftItemID = 38001553, num = 2},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 4},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 4},
				}
			},
		[7] ={ 
				Normal = {
					{GiftItemID = 30008027, num = 2},{GiftItemID = 20310168, num = 5},{GiftItemID = 20310021, num = 10},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 6},{GiftItemID = 38001553, num = 5},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 6},{GiftItemID = 38001554, num = 1},
				}
			},
		[8] ={ 
				Normal = {
					{GiftItemID = 30008027 ,num = 2},{GiftItemID = 30700241, num = 1},{GiftItemID = 38000833, num = 3},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 6},{GiftItemID = 38006284, num = 1},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 6},{GiftItemID = 38006285, num = 1},
				}
			},	
		[9] ={  
				Normal = {
					{GiftItemID = 30700241 ,num = 2},{GiftItemID = 20310158, num = 2},{GiftItemID = 30700249, num = 5},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 8},{GiftItemID = 30700241, num = 3},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 8},{GiftItemID = 20310131, num = 10},
				}
			},
		[10] ={ 	
				Normal = {
					{GiftItemID = 30700241 ,num = 2},{GiftItemID = 38000831, num = 2},{GiftItemID = 30008027, num = 2},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 8},{GiftItemID = 20502003, num = 1},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 8},{GiftItemID = 20502003, num = 3},
				}
			},
		[11] ={ 
				Normal = {
					{GiftItemID = 30700241 ,num = 2},{GiftItemID = 38000989, num = 3},{GiftItemID = 38000930, num = 50},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 10},{GiftItemID = 20501003, num = 1},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 10},{GiftItemID = 20501003, num = 3},
				}
			},
		[12] ={
				Normal = {
					{GiftItemID = 38000380 ,num = 2},{GiftItemID = 30505805, num = 1},{GiftItemID = 30505817, num = 5},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 10},{GiftItemID = 30505805, num = 5},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 10},{GiftItemID = 30505817, num = 10},
				}
			},
		[13] ={ 
				Normal = {
					{GiftItemID = 38000380 ,num = 2},{GiftItemID = 30505806, num = 1},{GiftItemID = 30505908, num = 5},
				},
				Consume1 = {
					{GiftItemID = 30008080, num = 20},{GiftItemID = 30505908, num = 10},
				},
				Consume2 = {
					{GiftItemID = 20310168, num = 20},{GiftItemID = 30505706, num = 1},
				}
			},
	}, 
	[3] ={ --社交达人
		[1]  = 	{EventId=1,NeedValue = 1,		RewardList={Id=39921125,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_119}",unlockDic="#{TLXS_180427_133}",szTitleName="#{TLXS_180427_133}",szNameDic="#{TLXS_180427_21}",Desc="#{TLXS_180427_14}",},    	 --结婚1次
		[2]  = 	{EventId=2,NeedValue = 1,		RewardList={Id=39921447,Count = 40,bag=1,mat=0},szUnReward="#{TLXS_180427_120}",unlockDic="#{TLXS_180427_134}",szTitleName="#{TLXS_180427_134}",szNameDic="#{TLXS_180427_22}",Desc="#{TLXS_180427_15}",},   	 --与配偶同时在线1小时
		[3]  = 	{EventId=3,NeedValue = 1,		RewardList={Id=39920913,Count = 2,bag=1,mat=0},szUnReward="#{TLXS_180427_121}",unlockDic="#{TLXS_180427_135}",szTitleName="#{TLXS_180427_135}",szNameDic="#{TLXS_180427_23}",Desc="#{TLXS_180427_16}",},	   	 --与配偶私聊一次
		[4]  = 	{EventId=4,NeedValue = 1,		RewardList={Id=39921448,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_122}",unlockDic="#{TLXS_180427_136}",szTitleName="#{TLXS_180427_136}",szNameDic="#{TLXS_180427_24}",Desc="#{TLXS_180427_17}",},    	 --与配偶同时去目标点
		[5]  = 	{EventId=5,NeedValue = 1,		RewardList={Id=39921449,Count = 5,bag=1,mat=0},szUnReward="#{TLXS_180427_123}",unlockDic="#{TLXS_180427_137}",szTitleName="#{TLXS_180427_137}",szNameDic="#{TLXS_180427_25}",Desc="#{TLXS_180427_18}",},	   	 --与配偶完成一次伉俪情深
		[6]  = 	{EventId=6,NeedValue = 1,		RewardList={Id=39921450,Count = 7,bag=1,mat=0},szUnReward="#{TLXS_180427_124}",unlockDic="#{TLXS_180427_138}",szTitleName="#{TLXS_180427_138}",szNameDic="#{TLXS_180427_26}",Desc="#{TLXS_180427_19}",},    	 --与配偶完成一次心有灵犀
		[7]  = 	{EventId=7,NeedValue = 1,		RewardList={Id=39920549,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_125}",unlockDic="#{TLXS_180427_139}",szTitleName="#{TLXS_180427_139}",szNameDic="#{TLXS_180427_27}",Desc="#{TLXS_180427_20}",},	   	 --与配偶一起回到洛阳
		[8]  = 	{EventId=8,NeedValue = 200,	RewardList={Id=39921313,Count = 4,bag=1,mat=0},szUnReward="#{TLXS_180427_151}",unlockDic="",szNameDic="#{TLXS_180427_94}",Desc="",TrackDesc="",},	 --获得恩爱值1000
		[9]  = 	{EventId=8,NeedValue = 500,	RewardList={Id=39920538,Count = 4,bag=1,mat=0},szUnReward="#{TLXS_180427_151}",unlockDic="",szNameDic="#{TLXS_180427_94}",Desc="",TrackDesc="",},	 --获得恩爱值2000
		[10] = 	{EventId=8,NeedValue = 900,	RewardList={Id=39920537,Count = 5,bag=1,mat=0},szUnReward="#{TLXS_180427_151}",unlockDic="",szNameDic="#{TLXS_180427_94}",Desc="",TrackDesc="",},	 --获得恩爱值3000
		[11] = 	{EventId=9,NeedValue = 1,		RewardList={Id=39920280,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_126}",unlockDic="#{TLXS_180427_38}",szTitleName="#{TLXS_180427_142}",szNameDic="#{TLXS_180427_38}",Desc="#{TLXS_180427_31}",},	     --加入一次帮会
		[12] = 	{EventId=10,NeedValue = 1,		RewardList={Id=39921124,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_127}",unlockDic="#{TLXS_180427_39}",szTitleName="#{TLXS_180427_143}",szNameDic="#{TLXS_180427_39}",Desc="#{TLXS_180427_32}",},	 --完成 1 次帮会扫雷
		[13] = 	{EventId=11,NeedValue = 1,		RewardList={Id=39921451,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_128}",unlockDic="#{TLXS_180427_40}",szTitleName="#{TLXS_180427_144}",szNameDic="#{TLXS_180427_40}",Desc="#{TLXS_180427_33}",},	 --领取 1 次扫雷boss奖励
		[14] = 	{EventId=12,NeedValue = 3,		RewardList={Id=39920505,Count = 2,bag=1,mat=0},szUnReward="#{TLXS_180427_129}",unlockDic="#{TLXS_180427_41}",szTitleName="#{TLXS_180427_145}",szNameDic="#{TLXS_180427_41}",Desc="#{TLXS_180427_34}",},	 --与帮会成员完成3次副本
		[15] = 	{EventId=13,NeedValue = 2,	RewardList={Id=38000989,Count = 2,bag=1,mat=0},szUnReward="#{TLXS_180427_130}",unlockDic="#{TLXS_180427_42}",szTitleName="#{TLXS_180427_146}",szNameDic="#{TLXS_180427_42}",Desc="#{TLXS_180427_35}",},	 --完成 2 次帮会扫雷
		[16] = 	{EventId=14,NeedValue = 1,		RewardList={Id=39921452,Count = 50,bag=1,mat=0},szUnReward="#{TLXS_180427_131}",unlockDic="#{TLXS_180427_43}",szTitleName="#{TLXS_180427_147}",szNameDic="#{TLXS_180427_43}",Desc="#{TLXS_180427_36}",},      --完成 1 次凤凰古城
		[17] = 	{EventId=15,NeedValue = 300,	RewardList={Id=30008027,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_132}",unlockDic="#{TLXS_180427_44}",szTitleName="#{TLXS_180427_148}",szNameDic="#{TLXS_180427_44}",Desc="#{TLXS_180427_37}",},  --与帮会成员杀怪10000只
		[18] = 	{EventId=16,NeedValue = 500,	RewardList={Id=39920378,Count = 3,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},	 --获得帮贡500
		[19] = 	{EventId=16,NeedValue = 1000,	RewardList={Id=39921452,Count = 100,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},    --获得帮贡1000
		[20] = 	{EventId=16,NeedValue = 1750,	RewardList={Id=38000989,Count = 8,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},    --获得帮贡1500
		[21] = 	{EventId=16,NeedValue = 2500,	RewardList={Id=38000932,Count = 4,bag=1,mat=0},szUnReward="#{TLXS_180427_150}",unlockDic="",szNameDic="#{TLXS_180427_84}",Desc="",},    --获得帮贡2000
		[22] = 	{EventId=17,NeedValue = 1,		RewardList={Id=30008027,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_152}",unlockDic="",szNameDic="#{TLXS_180427_95}",Desc="结拜：义结金兰，领取专属贺礼！(字典呢？)",},   --结拜1次
		[23] = 	{EventId=18,NeedValue = 1,		RewardList={Id=39921446,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_153}",unlockDic="",szNameDic="#{TLXS_180427_97}",Desc="拜师：名师高徒，领取专属贺礼！(字典呢？)",},    --拜师1次
		[24] = 	{EventId=19,NeedValue = 1,		RewardList={Id=39921454,Count = 1,bag=1,mat=0},szUnReward="#{TLXS_180427_154}",unlockDic="",szNameDic="#{TLXS_180427_96}",Desc="收徒：桃李天下，领取专属贺礼！(字典呢？)",},   --收徒1次
	},
	[4] = {	--首充	
		[1] = {
			{GiftItemID = 10155006, num = 1,bind =1},{GiftItemID = 30900077, num = 2,bind =0},
			{GiftItemID = 20109003, num = 3,bind =1},
		},
		[2] = {
				{GiftItemID = 20310168, num = 20,bind =1},{GiftItemID = 38001554, num = 1,bind =0},
				{GiftItemID = 30008027, num = 1,bind =1},
			},
		[3] = {
				{GiftItemID = 30900077, num = 1,bind =1},{GiftItemID = 30008027, num = 1,bind =0},
				{GiftItemID = 10146616, num = 1,bind =1},
			},	
	},
	--七日
	[7] = {
		[1] ={	{ItemID = 39920172, num = 1},{ItemID = 39920066, num = 1},{ItemID = 39921272, num = 1},{ItemID = 39920172, num = 1},{ItemID = 39920172, num = 2}},
		[2] ={	{ItemID = 39921375, num = 1},{ItemID = 39920172, num = 1},{ItemID = 39920545, num = 1},{ItemID = 39920172, num = 1},{ItemID = 39920172, num = 2}},
		[3] ={	{ItemID = 39920490, num = 3},{ItemID = 39921313, num = 3},{ItemID = 39920311, num = 3},{ItemID = 39924121, num = 1},{ItemID = 39924122, num = 1}},
		[4] ={	{ItemID = 39920085, num = 10},{ItemID = 39920332, num = 5},{ItemID = 39920334, num = 5},{ItemID = 39920172, num = 1},{ItemID = 39920172, num = 2}},
		[5] ={	{ItemID = 39920172, num = 1},{ItemID = 39920505, num = 3},{ItemID = 39920329, num = 3},{ItemID = 39920397, num = 1},{ItemID = 39920566, num = 1}},
		[6] ={	{ItemID = 39920397, num = 1},{ItemID = 39920267, num = 3},{ItemID = 39920235, num = 3},{ItemID = 39920396, num = 1},{ItemID = 39920565, num = 1}},
		[7] ={	{ItemID = 39920396, num = 1},{ItemID = 39920267, num = 3},{ItemID = 39920235, num = 3},{ItemID = 39922051, num = 1},{ItemID = 39921051, num = 5}},
	}, 
	[8] = {
		[1] ={	{ItemID = 38006791, num = 1},{ItemID = 10146614, num = 1},{ItemID = 10126970, num = 1},{ItemID = 39920172, num = 1},{ItemID = 39920172, num = 2}},
		[2] ={	{ItemID = 38008863, num = 1},{ItemID = 38001554, num = 1},{ItemID = 38001083, num = 1},{ItemID = 39920172, num = 1},{ItemID = 39920172, num = 2}},
		[3] ={	{ItemID = 38006791, num = 1},{ItemID = 38000992, num = 3},{ItemID = 38000443, num = 3},{ItemID = 39924121, num = 1},{ItemID = 39924122, num = 1}},
		[4] ={	{ItemID = 38008863, num = 1},{ItemID = 38008073, num = 1},{ItemID = 30503133, num = 3},{ItemID = 39920172, num = 1},{ItemID = 39920172, num = 2}},
		[5] ={	{ItemID = 38008863, num = 1},{ItemID = 20310168, num = 20},{ItemID = 38000571, num = 3},{ItemID = 39920397, num = 1},{ItemID = 39920566, num = 1}},
		[6] ={	{ItemID = 38008863, num = 1},{ItemID = 30700241, num = 5},{ItemID = 20502004, num = 1},{ItemID = 39920396, num = 1},{ItemID = 39920565, num = 1}},
		[7] ={	{ItemID = 38006791, num = 1},{ItemID = 38008837, num = 1},{ItemID = 20501004, num = 1},{ItemID = 39922051, num = 1},{ItemID = 39921051, num = 5}},
	}, 
}
--===============================================
-- PreLoad()
--===============================================
function XinShouNew_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("XINSHOUNEW_OPEN",true)		--
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("UNIT_LEVEL",false)			-- 【新服欢乐月·升级送好礼】刷新界面,玩家升级的时候需要刷新界面
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true)		-- 进入游戏世界
	this:RegisterEvent("PLAYER_FRESH_HAOXIA_FRAM",false)	
	this:RegisterEvent("TODAY_ACTIVE_POINT",false)
end

--===============================================
-- OnEvent()
--===============================================
function XinShouNew_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 8926771 ) then

		local nIndex = Get_XParam_INT(1)
		if nIndex == 0 then
			if g_XinShouNew_Heroes_Road_LastClickedId >=1 and g_XinShouNew_Heroes_Road_LastClickedId <= 7 then
				for i = 1,  table.getn(g_XinShouNew_Heroes_Road_Button) do
					if i == g_XinShouNew_Heroes_Road_LastClickedId then
						g_XinShouNew_Heroes_Road_Button[i]:SetCheck(1)
					else
						g_XinShouNew_Heroes_Road_Button[i]:SetCheck(0)
					end
				end
			end
		end
		if nIndex >= 1 and nIndex <= 7 then
			local nValue = Get_XParam_INT(2)
			local nDayGap = Get_XParam_INT(3)
			g_XinShouNew_Heroes_Road_2023 = Get_XParam_INT(4)
			XinShouNew_Heroes_Road_OnSwitchPage(nIndex,nValue,nDayGap,g_XinShouNew_Heroes_Road_2023)
		end
		
		if g_XinShouNew_Heroes_Road_2023 == 1 then 
			XinShouNew_Heroes_RoadFrameBk2_New:Show()
			XinShouNew_Heroes_RoadFrameBk2_L:Hide()
			XinShouNew_Heroes_RoadFrameBk2_R:Hide()
		else
			XinShouNew_Heroes_RoadFrameBk2_New:Hide()
			XinShouNew_Heroes_RoadFrameBk2_L:Show()
			XinShouNew_Heroes_RoadFrameBk2_R:Show()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 8926776 ) then

		local nValue = Get_XParam_INT(1)
		if IsWindowShow("XinShouNew") then
			local strMsg = ScriptGlobal_Format( "#{XSJNH_180120_242}", nValue)
			XinShouNew_Heroes_Road_Detailtips_text:SetText(strMsg)
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2303226 ) then

		local nValue = Get_XParam_INT(1)
		if IsWindowShow("XinShouNew") then
			local strMsg = ScriptGlobal_Format( "#{XSJNH_230209_76}", nValue)
			XinShouNew_Heroes_Road_Detailtips_text:SetText(strMsg)
		end
	elseif (event == "XINSHOUNEW_OPEN") then
		XinShouNew_Open()
	elseif (event == "PLAYER_FRESH_HAOXIA_FRAM") then
		XinShouNew_Heroes_Road_Page_Clicked(g_XinShouNew_Heroes_Road_LastClickedId)	
	elseif (event == "PLAYER_LEAVE_WORLD") then
		XinShouNew_Close()
	elseif (event == "ADJEST_UI_POS") then
		XinShouNew_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XinShouNew_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD" ) then				-- 【新服欢乐月·升级送好礼&首冲超值赠】重新加载物品奖励
		g_XinShouNew_ShouChong_LoadFirstTime = 1;
		g_XinShouNew_ShouChong_LastShow_2023 = 0
		XinShouNew_SheJiaoNew_Request()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20180118 ) then
		g_XinShouNew_7DayShowTimes =  Get_XParam_INT( 0 );
		if g_XinShouNew_LastClickedId == 2 and this:IsVisible() then
			XinShouNew_7Day_Update()
		end
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99841001 ) then
		--PushDebugMessage(g_XinShouNew_LastClickedId)
		g_XinShouNew_7DayShowTimes_2023 =  Get_XParam_INT( 0 );
		g_XinShouNew_7Day_CurConsume_2023 = Get_XParam_INT( 1 );
		g_XinShouNew_7Day_CurExch_2023 = Get_XParam_INT( 2 );
		--if g_XinShouNew_LastClickedId == 12 and this:IsVisible() then
			XinShouNew_7Day2_Update()
		--end
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 892675 ) then
		local nLogin=  Get_XParam_INT( 0 );
		if nLogin == 1 then
			for i = 1,7 do
				g_HaoXialuRed[i]:Hide()
			end
		end
		local nDayGap =  Get_XParam_INT( 1 );
		XinShouNew_OnCheckRed(nDayGap)
	elseif (event == "PLAYER_ENTERING_WORLD" ) then				-- 【新服欢乐月·升级送好礼&首冲超值赠】重新加载物品奖励
		g_XinShouNew_LevelUp_LoadFirstTime 	= 1;
		g_XinShouNew_LevelUp_LoadFirstTime_2023 = 1;
		g_XinShouNew_BaiBao_LoadFirstTime  	= 1;
		g_XinShouNew_LuckyDraw_LoadFirstTime= 1;		
	elseif (event == "UNIT_LEVEL" ) then
		if IsWindowShow("XinShouNew") then				--【新服欢乐月·升级送好礼】 界面刷新
			g_PlayerLevel = Player : GetLevel()
			XinShouNew_LevelUp_FlushWindow(2)
			XinShouNew_LevelUp2_FlushWindow(2)
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 892684 ) then	--【新服欢乐月·升级送好礼】
		-- 取参数
		for i = 1, table.getn(g_XinShouNew_LevelUpBtnState) do
			g_XinShouNew_LevelUpBtnState[i] = Get_XParam_INT( i - 1 )
		end	
		g_PlayerLevel = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState) )
		-- 更新Btn
		XinShouNew_LevelUp_FlushWindow(2); 	
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99841201 ) then	--【新服欢乐月·升级送好礼】
		-- 取参数
		local uiType = Get_XParam_INT( 0 )
		for i = 1, table.getn(g_XinShouNew_LevelUpBtnState_2023) do
			g_XinShouNew_LevelUpBtnState_2023[i].level = Get_XParam_INT( i-1 )
		end
		g_PlayerLevel = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023))
		g_CurConsume = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023)+1)
		g_CurExch = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023)+2)
		-- 更新Btn
		XinShouNew_LevelUp2_FlushWindow(2); 	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99841202 ) then	--【新服欢乐月·升级送好礼】
		-- 取参数
		local uiType = Get_XParam_INT( 0 )
		for i = 1, table.getn(g_XinShouNew_LevelUpBtnState_2023) do
			g_XinShouNew_LevelUpBtnState_2023[i].consume1 = Get_XParam_INT( i-1 )
		end
		g_PlayerLevel = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023))
		g_CurConsume = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023)+1)
		g_CurExch = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023)+2)
		-- 更新Btn
		XinShouNew_LevelUp2_FlushWindow(2); 
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99841203 ) then	--【新服欢乐月·升级送好礼】
		-- 取参数
		local uiType = Get_XParam_INT( 0 )
		for i = 1, table.getn(g_XinShouNew_LevelUpBtnState_2023) do
			g_XinShouNew_LevelUpBtnState_2023[i].consume2 = Get_XParam_INT( i-1 )
		end
		--PushDebugMessage(g_XinShouNew_LevelUpBtnState_2023[1].consume2)
		g_PlayerLevel = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023))
		g_CurConsume = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023)+1)
		g_CurExch = Get_XParam_INT( table.getn(g_XinShouNew_LevelUpBtnState_2023)+2)
		-- 更新Btn
		XinShouNew_LevelUp2_FlushWindow(2); 
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89267601 ) then
		XinShouNew_ShouChong_UpdateButtonState()		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99841101 ) then
		XinShouNew_ShouChong2_UpdateButtonState()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89268901 ) then
		XinShouNew_LimitedSaveUp_UpdateInfo()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89269001 ) then
		XinShouNew_SuperSaveUp_UpdateInfo()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 892685 ) then	--【新服欢乐月·英雄百宝囊】
		-- 取参数
		for i = 1, table.getn(g_XinShouNew_BaiBaoBtnState) do
			g_XinShouNew_BaiBaoBtnState[i] = Get_XParam_INT( i - 1 )
		end	
		g_PlayerLevel = Get_XParam_INT( table.getn(g_XinShouNew_BaiBaoBtnState) )
		-- 更新Btn
		XinShouNew_BaiBao_FlushWindow(2); 	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 892686 ) then	--【新服欢乐月·江湖幸运星】
		-- 取参数 
		g_LuckyDrawCount 			= Get_XParam_INT( 0 ); 
 		g_LuckyDrawRemainTime = Get_XParam_INT( 1 );  
		XinShouNew_LuckyDraw_Tick()
 		-- g_LuckyDrawIndex			= 0;
		-- 更新Btn
		XinShouNew_LuckyDraw_FlushWindow(2); 
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 8926861 ) then	--【新服欢乐月·江湖幸运星-特效】
		-- 取参数 
		g_LuckyDrawIndex 			= Get_XParam_INT( 0 );    
		-- 更新Btn
		XinShouNew_LuckyDraw_FlushWindow(2); 			
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 892687) then --	【新服欢乐月·社交达人汇-数据刷新】
		XinShouNew_SheJiaoDaRen_UpDateDate()
	--elseif(event == "UI_COMMAND" and tonumber(arg0) == 8926871) then --【新服欢乐月·社交达人汇-领取奖励成功】
	--	local nIndex = Get_XParam_INT(0)
	--	XinShouNew_SheJiaoDaRen_RetReward(nIndex)
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89267501) then --显示小红点
		
		for index=1,table.getn(g_XinShouNew_Button)  do
			 local TipsState 					= Get_XParam_INT(index-1) 
			 if index ~= 11 then
			 	g_Tips_StateTemp[index]  = TipsState 
			 elseif index == 11 and g_XinShouNew_HeroBag_IsShowTips == 1  then
			 	g_Tips_StateTemp[index]  = TipsState
			 else
			 	g_Tips_StateTemp[index]  = 0 
			 end 
		end
		

	
		XinShouNew_ShowButtonTips()		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 2018020101) then --  
		g_XinShouNew_HeroBag_IsShowTips = 1	
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 892753) then --新版天龙携手行数据刷新
		XinShouNew_SheJiaoNew_UpdateData()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99841301 ) then	--【新服欢乐月·新版江湖幸运星】
		-- 取参数 
 		g_NewLuckyDraw_TodayOnlineTime 	= Get_XParam_INT( 0 );  
 		g_NewLuckyDraw_SignCount = Get_XParam_INT( 1 ); 
		for i = 1, 3 do
			g_NewLuckyDraw_Flag[i] = Get_XParam_INT( 1+i ); 
		end
		for i = 1, 7 do
			g_NewLuckyDraw_LJ_Flag[i] = Get_XParam_INT( 4+i ); 
		end
		-- 更新Btn
		XinShouNew_LuckyDraw2023_FlushWindow(); 
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		XinShouNew_LuckyDraw2023_FlushWindow() 
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 99840103 ) then
		if 1==  Get_XParam_INT(0) then
			XinShouNew_Supe_VIP_Btn_Tips:Show()
		else
			XinShouNew_Supe_VIP_Btn_Tips:Hide()
		end
	end
end

--===============================================
-- OnLoad()
--===============================================
function XinShouNew_OnLoad()
	g_XinShouNew_Frame_UnifiedPosition = XinShouNew_Frame:GetProperty("UnifiedPosition")
	XinShouNew_SetButtonPos()

	g_XinShouNew_7DayButtom[1] ={Button =XinShouNew_SevenDay_Top_day1_Button1 , Done = XinShouNew_SevenDay_Top_day1_done };
	g_XinShouNew_7DayButtom[2] ={Button =XinShouNew_SevenDay_Top_day2_Button1 , Done = XinShouNew_SevenDay_Top_day2_done };
	g_XinShouNew_7DayButtom[3] ={Button =XinShouNew_SevenDay_Top_day3_Button1 , Done = XinShouNew_SevenDay_Top_day3_done };
	g_XinShouNew_7DayButtom[4] ={Button =XinShouNew_SevenDay_Top_day4_Button1 , Done = XinShouNew_SevenDay_Top_day4_done };
	g_XinShouNew_7DayButtom[5] ={Button =XinShouNew_SevenDay_Top_day5_Button1 , Done = XinShouNew_SevenDay_Top_day5_done };
	g_XinShouNew_7DayButtom[6] ={Button =XinShouNew_SevenDay_Top_day6_Button1 , Done = XinShouNew_SevenDay_Top_day6_done };
	g_XinShouNew_7DayButtom[7] ={Button =XinShouNew_SevenDay_Top_day7_Button1 , Done = XinShouNew_SevenDay_Top_day7_done };

	g_XinShouNew_7DayPrize_Button[1] = XinShouNew_SevenDay_Right_ShowA;
	g_XinShouNew_7DayPrize_Button[2] = XinShouNew_SevenDay_Right_ShowB;
	g_XinShouNew_7DayPrize_Button[3] = XinShouNew_SevenDay_Right_ShowC;
	g_XinShouNew_7DayPrize_Button[4] = XinShouNew_SevenDay_Right_ShowD;
	
	
	--新7day2023
	g_XinShouNew_7DayButtom_2023[1] ={Button =XinShouNew_SevenDay2_Top_day1_Button1 , Done = XinShouNew_SevenDay2_Top_day1_done };
	g_XinShouNew_7DayButtom_2023[2] ={Button =XinShouNew_SevenDay2_Top_day2_Button1 , Done = XinShouNew_SevenDay2_Top_day2_done };
	g_XinShouNew_7DayButtom_2023[3] ={Button =XinShouNew_SevenDay2_Top_day3_Button1 , Done = XinShouNew_SevenDay2_Top_day3_done };
	g_XinShouNew_7DayButtom_2023[4] ={Button =XinShouNew_SevenDay2_Top_day4_Button1 , Done = XinShouNew_SevenDay2_Top_day4_done };
	g_XinShouNew_7DayButtom_2023[5] ={Button =XinShouNew_SevenDay2_Top_day5_Button1 , Done = XinShouNew_SevenDay2_Top_day5_done };
	g_XinShouNew_7DayButtom_2023[6] ={Button =XinShouNew_SevenDay2_Top_day6_Button1 , Done = XinShouNew_SevenDay2_Top_day6_done };
	g_XinShouNew_7DayButtom_2023[7] ={Button =XinShouNew_SevenDay2_Top_day7_Button1 , Done = XinShouNew_SevenDay2_Top_day7_done };

	g_XinShouNew_7DayPrize_Button_2023[1] = XinShouNew_SevenDay2_Client1_ShowA;
	g_XinShouNew_7DayPrize_Button_2023[2] = XinShouNew_SevenDay2_Client1_ShowB;
	g_XinShouNew_7DayPrize_Button_2023[3] = XinShouNew_SevenDay2_Client1_ShowC;
	g_XinShouNew_7DayPrize_Button_2023[4] = XinShouNew_SevenDay2_Client2_ShowA;
	g_XinShouNew_7DayPrize_Button_2023[5] = XinShouNew_SevenDay2_Client3_ShowA;
	
	g_XinShouNew_7Day_ImgBK_2023[1] = XinShouNew_SevenDay2_Null1
	g_XinShouNew_7Day_ImgBK_2023[2] = XinShouNew_SevenDay2_Null2
	g_XinShouNew_7Day_ImgBK_2023[3] = XinShouNew_SevenDay2_Null3
	g_XinShouNew_7Day_ImgBK_2023[4] = XinShouNew_SevenDay2_Null4
	g_XinShouNew_7Day_ImgBK_2023[5] = XinShouNew_SevenDay2_Null5
	g_XinShouNew_7Day_ImgBK_2023[6] = XinShouNew_SevenDay2_Null6
	g_XinShouNew_7Day_ImgBK_2023[7] = XinShouNew_SevenDay2_Null7

	--【新服欢乐月·升级送好礼】Begin

	--界面上显示奖励物品的ICON表
	g_XinShouNew_LevelUp_GiftsIcons =
	{
	[1] = {XinShouNew_LevelUp_Frame3_Bk1_Icon1, XinShouNew_LevelUp_Frame3_Bk1_Icon2, XinShouNew_LevelUp_Frame3_Bk1_Icon3, XinShouNew_LevelUp_Frame3_Bk1_Icon4, },
	[2] = {XinShouNew_LevelUp_Frame3_Bk2_Icon1, XinShouNew_LevelUp_Frame3_Bk2_Icon2, XinShouNew_LevelUp_Frame3_Bk2_Icon3, XinShouNew_LevelUp_Frame3_Bk2_Icon4, },
	[3] = {XinShouNew_LevelUp_Frame3_Bk3_Icon1, XinShouNew_LevelUp_Frame3_Bk3_Icon2, XinShouNew_LevelUp_Frame3_Bk3_Icon3, XinShouNew_LevelUp_Frame3_Bk3_Icon4, },
	[4] = {XinShouNew_LevelUp_Frame3_Bk4_Icon1, XinShouNew_LevelUp_Frame3_Bk4_Icon2, XinShouNew_LevelUp_Frame3_Bk4_Icon3, XinShouNew_LevelUp_Frame3_Bk4_Icon4, },
	[5] = {XinShouNew_LevelUp_Frame3_Bk5_Icon1, XinShouNew_LevelUp_Frame3_Bk5_Icon2, XinShouNew_LevelUp_Frame3_Bk5_Icon3, XinShouNew_LevelUp_Frame3_Bk5_Icon4, },
	[6] = {XinShouNew_LevelUp_Frame3_Bk6_Icon1, XinShouNew_LevelUp_Frame3_Bk6_Icon2, XinShouNew_LevelUp_Frame3_Bk6_Icon3, XinShouNew_LevelUp_Frame3_Bk6_Icon4, },
	[7] = {XinShouNew_LevelUp_Frame3_Bk7_Icon1, XinShouNew_LevelUp_Frame3_Bk7_Icon2, XinShouNew_LevelUp_Frame3_Bk7_Icon3, XinShouNew_LevelUp_Frame3_Bk7_Icon4, },
	[8] = {XinShouNew_LevelUp_Frame3_Bk8_Icon1, XinShouNew_LevelUp_Frame3_Bk8_Icon2, XinShouNew_LevelUp_Frame3_Bk8_Icon3, XinShouNew_LevelUp_Frame3_Bk8_Icon4, },
	[9] = {XinShouNew_LevelUp_Frame3_Bk9_Icon1, XinShouNew_LevelUp_Frame3_Bk9_Icon2, XinShouNew_LevelUp_Frame3_Bk9_Icon3, XinShouNew_LevelUp_Frame3_Bk9_Icon4, },
	[10] = {XinShouNew_LevelUp_Frame3_Bk10_Icon1, XinShouNew_LevelUp_Frame3_Bk10_Icon2, XinShouNew_LevelUp_Frame3_Bk10_Icon3, XinShouNew_LevelUp_Frame3_Bk10_Icon4, },
	[11] = {XinShouNew_LevelUp_Frame3_Bk11_Icon1, XinShouNew_LevelUp_Frame3_Bk11_Icon2, XinShouNew_LevelUp_Frame3_Bk11_Icon3, XinShouNew_LevelUp_Frame3_Bk11_Icon4, },
	[12] = {XinShouNew_LevelUp_Frame3_Bk12_Icon1, XinShouNew_LevelUp_Frame3_Bk12_Icon2, XinShouNew_LevelUp_Frame3_Bk12_Icon3, XinShouNew_LevelUp_Frame3_Bk12_Icon4, },
	[13] = {XinShouNew_LevelUp_Frame3_Bk13_Icon1, XinShouNew_LevelUp_Frame3_Bk13_Icon2, XinShouNew_LevelUp_Frame3_Bk13_Icon3, XinShouNew_LevelUp_Frame3_Bk13_Icon4, },
	}

	g_XinShouNew_LevelUp_GiftsIconsImages =
	{
	[1] = {XinShouNew_LevelUp_Frame3_Bk1_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk1_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk1_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk1_Icon4_Xin, },
	[2] = {XinShouNew_LevelUp_Frame3_Bk2_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk2_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk2_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk2_Icon4_Xin, },
	[3] = {XinShouNew_LevelUp_Frame3_Bk3_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk3_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk3_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk3_Icon4_Xin, },
	[4] = {XinShouNew_LevelUp_Frame3_Bk4_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk4_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk4_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk4_Icon4_Xin, },
	[5] = {XinShouNew_LevelUp_Frame3_Bk5_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk5_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk5_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk5_Icon4_Xin, },
	[6] = {XinShouNew_LevelUp_Frame3_Bk6_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk6_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk6_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk6_Icon4_Xin, },
	[7] = {XinShouNew_LevelUp_Frame3_Bk7_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk7_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk7_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk7_Icon4_Xin, },
	[8] = {XinShouNew_LevelUp_Frame3_Bk8_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk8_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk8_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk8_Icon4_Xin, },
	[9] = {XinShouNew_LevelUp_Frame3_Bk9_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk9_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk9_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk9_Icon4_Xin, },
	[10] = {XinShouNew_LevelUp_Frame3_Bk10_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk10_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk10_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk10_Icon4_Xin, },
	[11] = {XinShouNew_LevelUp_Frame3_Bk11_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk11_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk11_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk11_Icon4_Xin, },
	[12] = {XinShouNew_LevelUp_Frame3_Bk12_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk12_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk12_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk12_Icon4_Xin, },
	[13] = {XinShouNew_LevelUp_Frame3_Bk13_Icon1_Xin, XinShouNew_LevelUp_Frame3_Bk13_Icon2_Xin, XinShouNew_LevelUp_Frame3_Bk13_Icon3_Xin, XinShouNew_LevelUp_Frame3_Bk13_Icon4_Xin, },
	}
	--界面上的每档奖励展示框
	g_XinShouNew_LevelUp_Frames =
	{
		[1] = XinShouNew_LevelUp_Frame3_Bk1, [2] = XinShouNew_LevelUp_Frame3_Bk2, [3] = XinShouNew_LevelUp_Frame3_Bk3, [4] = XinShouNew_LevelUp_Frame3_Bk4,
		[5] = XinShouNew_LevelUp_Frame3_Bk5, [6] = XinShouNew_LevelUp_Frame3_Bk6, [7] = XinShouNew_LevelUp_Frame3_Bk7, [8] = XinShouNew_LevelUp_Frame3_Bk8,
		[9] = XinShouNew_LevelUp_Frame3_Bk9, [10] = XinShouNew_LevelUp_Frame3_Bk10, [11] = XinShouNew_LevelUp_Frame3_Bk11, [12] = XinShouNew_LevelUp_Frame3_Bk12,
		[13] = XinShouNew_LevelUp_Frame3_Bk13,
	}
	--界面【领取奖励】按钮表
	g_XinShouNew_LevelUp_GetGiftsButtonList =
	{
		[1] = XinShouNew_LevelUp_Frame3_Bk1_Button1,
		[2] = XinShouNew_LevelUp_Frame3_Bk2_Button1,
		[3] = XinShouNew_LevelUp_Frame3_Bk3_Button1,
		[4] = XinShouNew_LevelUp_Frame3_Bk4_Button1,
		[5] = XinShouNew_LevelUp_Frame3_Bk5_Button1,
		[6] = XinShouNew_LevelUp_Frame3_Bk6_Button1,
		[7] = XinShouNew_LevelUp_Frame3_Bk7_Button1,
		[8] = XinShouNew_LevelUp_Frame3_Bk8_Button1,
		[9] = XinShouNew_LevelUp_Frame3_Bk9_Button1,
		[10] = XinShouNew_LevelUp_Frame3_Bk10_Button1,
		[11] = XinShouNew_LevelUp_Frame3_Bk11_Button1,
		[12] = XinShouNew_LevelUp_Frame3_Bk12_Button1,
		[13] = XinShouNew_LevelUp_Frame3_Bk13_Button1,
	}
	--【新服欢乐月·升级送好礼】End
	
	--2023新【新服欢乐月·升级送好礼】Begin
	
	g_XinShouNew_LevelUp_List_2023 = XinShouNew_LevelUp2_Frame3_List

	--2023新【新服欢乐月·升级送好礼】End	
	

	-- 英雄百宝囊begin
	g_XinShouNew_BaiBao_Bk = {
		[1] = XinShouNew_BaiBao_Frame3_Bk1,
		[2] = XinShouNew_BaiBao_Frame3_Bk2,
		[3] = XinShouNew_BaiBao_Frame3_Bk3,
		[4] = XinShouNew_BaiBao_Frame3_Bk4,
		[5] = XinShouNew_BaiBao_Frame3_Bk5,
		[6] = XinShouNew_BaiBao_Frame3_Bk6,

	}
	--界面上显示奖励物品的ICON表
	g_XinShouNew_BaiBao_GiftsIcons =
	{
	[1] = {XinShouNew_BaiBao_Frame3_Bk1_Icon1, XinShouNew_BaiBao_Frame3_Bk1_Icon2, XinShouNew_BaiBao_Frame3_Bk1_Icon3, XinShouNew_BaiBao_Frame3_Bk1_Icon4, }, 
	[2] = {XinShouNew_BaiBao_Frame3_Bk2_Icon1, XinShouNew_BaiBao_Frame3_Bk2_Icon2, XinShouNew_BaiBao_Frame3_Bk2_Icon3, XinShouNew_BaiBao_Frame3_Bk2_Icon4, }, 
	[3] = {XinShouNew_BaiBao_Frame3_Bk3_Icon1, XinShouNew_BaiBao_Frame3_Bk3_Icon2, XinShouNew_BaiBao_Frame3_Bk3_Icon3, XinShouNew_BaiBao_Frame3_Bk3_Icon4, }, 
	[4] = {XinShouNew_BaiBao_Frame3_Bk4_Icon1, XinShouNew_BaiBao_Frame3_Bk4_Icon2, XinShouNew_BaiBao_Frame3_Bk4_Icon3, XinShouNew_BaiBao_Frame3_Bk4_Icon4, }, 
	[5] = {XinShouNew_BaiBao_Frame3_Bk5_Icon1, XinShouNew_BaiBao_Frame3_Bk5_Icon2, XinShouNew_BaiBao_Frame3_Bk5_Icon3, XinShouNew_BaiBao_Frame3_Bk5_Icon4, }, 
	[6] = {XinShouNew_BaiBao_Frame3_Bk6_Icon1, XinShouNew_BaiBao_Frame3_Bk6_Icon2, XinShouNew_BaiBao_Frame3_Bk6_Icon3, XinShouNew_BaiBao_Frame3_Bk6_Icon4, }, 
	}

	g_XinShouNew_BaiBao_GiftsIconImages =
	{
	[1] = {XinShouNew_BaiBao_Frame3_Bk1_Icon1_Xin, XinShouNew_BaiBao_Frame3_Bk1_Icon2_Xin, XinShouNew_BaiBao_Frame3_Bk1_Icon3_Xin, XinShouNew_BaiBao_Frame3_Bk1_Icon4_Xin, }, 
	[2] = {XinShouNew_BaiBao_Frame3_Bk2_Icon1_Xin, XinShouNew_BaiBao_Frame3_Bk2_Icon2_Xin, XinShouNew_BaiBao_Frame3_Bk2_Icon3_Xin, XinShouNew_BaiBao_Frame3_Bk2_Icon4_Xin, }, 
	[3] = {XinShouNew_BaiBao_Frame3_Bk3_Icon1_Xin, XinShouNew_BaiBao_Frame3_Bk3_Icon2_Xin, XinShouNew_BaiBao_Frame3_Bk3_Icon3_Xin, XinShouNew_BaiBao_Frame3_Bk3_Icon4_Xin, }, 
	[4] = {XinShouNew_BaiBao_Frame3_Bk4_Icon1_Xin, XinShouNew_BaiBao_Frame3_Bk4_Icon2_Xin, XinShouNew_BaiBao_Frame3_Bk4_Icon3_Xin, XinShouNew_BaiBao_Frame3_Bk4_Icon4_Xin, }, 
	[5] = {XinShouNew_BaiBao_Frame3_Bk5_Icon1_Xin, XinShouNew_BaiBao_Frame3_Bk5_Icon2_Xin, XinShouNew_BaiBao_Frame3_Bk5_Icon3_Xin, XinShouNew_BaiBao_Frame3_Bk5_Icon4_Xin, }, 
	[6] = {XinShouNew_BaiBao_Frame3_Bk6_Icon1_Xin, XinShouNew_BaiBao_Frame3_Bk6_Icon2_Xin, XinShouNew_BaiBao_Frame3_Bk6_Icon3_Xin, XinShouNew_BaiBao_Frame3_Bk6_Icon4_Xin, }, 
	}

	--界面【领取奖励】按钮表
	g_XinShouNew_BaiBao_GetGiftsButtonList =
	{
		[1] = XinShouNew_BaiBao_Frame3_Bk1_Button1,
		[2] = XinShouNew_BaiBao_Frame3_Bk2_Button1,
		[3] = XinShouNew_BaiBao_Frame3_Bk3_Button1,
		[4] = XinShouNew_BaiBao_Frame3_Bk4_Button1,
		[5] = XinShouNew_BaiBao_Frame3_Bk5_Button1,
		[6] = XinShouNew_BaiBao_Frame3_Bk6_Button1,
	}

	--界面领取条件提示Text控件表,策划需要根据完成情况动态显示=...=
	g_XinShouNew_BaiBao_NotifyTipsControlList = 
	{ 
		[1] = { LevelText =  XinShouNew_BaiBao_Frame3_Bk1_Text1_1, YBText = XinShouNew_BaiBao_Frame3_Bk1_Text1_2, CostYBText = XinShouNew_BaiBao_Frame3_Bk1_Text1_2_1, },
		[2] = { LevelText =  XinShouNew_BaiBao_Frame3_Bk2_Text1_1, YBText = XinShouNew_BaiBao_Frame3_Bk2_Text1_2, CostYBText = XinShouNew_BaiBao_Frame3_Bk2_Text1_2_1, },
		[3] = { LevelText =  XinShouNew_BaiBao_Frame3_Bk3_Text1_1, YBText = XinShouNew_BaiBao_Frame3_Bk3_Text1_2, CostYBText = XinShouNew_BaiBao_Frame3_Bk3_Text1_2_1, },
		[4] = { LevelText =  XinShouNew_BaiBao_Frame3_Bk4_Text1_1, YBText = XinShouNew_BaiBao_Frame3_Bk4_Text1_2, CostYBText = XinShouNew_BaiBao_Frame3_Bk4_Text1_2_1, },
		[5] = { LevelText =  XinShouNew_BaiBao_Frame3_Bk5_Text1_1, YBText = XinShouNew_BaiBao_Frame3_Bk5_Text1_2, CostYBText = XinShouNew_BaiBao_Frame3_Bk5_Text1_2_1, },
		[6] = { LevelText =  XinShouNew_BaiBao_Frame3_Bk6_Text1_1, YBText = XinShouNew_BaiBao_Frame3_Bk6_Text1_2, CostYBText = XinShouNew_BaiBao_Frame3_Bk6_Text1_2_1, },
	}

	-- 英雄百宝囊end

	-- 江湖幸运星begin
	g_XinShouNew_LuckyDraw_GiftsIcons =
	{
	[1] = {XinShouNew_LuckStar_Frame3_Bk2_Icon1, }, 
	[2] = {XinShouNew_LuckStar_Frame3_Bk2_Icon2, }, 
	[3] = {XinShouNew_LuckStar_Frame3_Bk2_Icon3, }, 
	[4] = {XinShouNew_LuckStar_Frame3_Bk2_Icon4, }, 
	[5] = {XinShouNew_LuckStar_Frame3_Bk2_Icon5, }, 
	[6] = {XinShouNew_LuckStar_Frame3_Bk2_Icon6, }, 
	[7] = {XinShouNew_LuckStar_Frame3_Bk2_Icon7, }, 
	[8] = {XinShouNew_LuckStar_Frame3_Bk2_Icon8, }, 
	[9] = {XinShouNew_LuckStar_Frame3_Bk2_Icon9, }, 
	}

	g_XinShouNew_LuckyDraw_GiftsIconImages =
	{
	[1] = {XinShouNew_LuckStar_Frame3_Bk2_Icon1_Xin, }, 
	[2] = {XinShouNew_LuckStar_Frame3_Bk2_Icon2_Xin, }, 
	[3] = {XinShouNew_LuckStar_Frame3_Bk2_Icon3_Xin, }, 
	[4] = {XinShouNew_LuckStar_Frame3_Bk2_Icon4_Xin, }, 
	[5] = {XinShouNew_LuckStar_Frame3_Bk2_Icon5_Xin, }, 
	[6] = {XinShouNew_LuckStar_Frame3_Bk2_Icon6_Xin, }, 
	[7] = {XinShouNew_LuckStar_Frame3_Bk2_Icon7_Xin, }, 
	[8] = {XinShouNew_LuckStar_Frame3_Bk2_Icon8_Xin, }, 
	[9] = {XinShouNew_LuckStar_Frame3_Bk2_Icon9_Xin, }, 
	}
	
	g_XinShouNew_LuckyDraw_GiftLightImage =
	{
	[1] = XinShouNew_LuckStar_Frame3_Bk2_Icon1_Image,
	[2] = XinShouNew_LuckStar_Frame3_Bk2_Icon2_Image,
	[3] = XinShouNew_LuckStar_Frame3_Bk2_Icon3_Image,
	[4] = XinShouNew_LuckStar_Frame3_Bk2_Icon4_Image, 
	[5] = XinShouNew_LuckStar_Frame3_Bk2_Icon5_Image, 
	[6] = XinShouNew_LuckStar_Frame3_Bk2_Icon6_Image,  
	[7] = XinShouNew_LuckStar_Frame3_Bk2_Icon7_Image, 
	[8] = XinShouNew_LuckStar_Frame3_Bk2_Icon8_Image, 
	[9] = XinShouNew_LuckStar_Frame3_Bk2_Icon9_Image,  
	}
	-- 江湖幸运星end 


	g_HaoXialuRed[1]  = XinShouNew_Heroes_RoadBK_day1_Button1_tips;
	g_HaoXialuRed[2]  = XinShouNew_Heroes_RoadBK_day2_Button1_tips;
	g_HaoXialuRed[3]  = XinShouNew_Heroes_RoadBK_day3_Button1_tips;
	g_HaoXialuRed[4]  = XinShouNew_Heroes_RoadBK_day4_Button1_tips;
	g_HaoXialuRed[5]  = XinShouNew_Heroes_RoadBK_day5_Button1_tips;
	g_HaoXialuRed[6]  = XinShouNew_Heroes_RoadBK_day6_Button1_tips;	
	g_HaoXialuRed[7]  = XinShouNew_Heroes_RoadBK_day7_Button1_tips;	
	
	XinShouNew_SheJiaoInit()	
	XinShouNew_SheJiaoNew_Init()
	
	XinShouNew_LuckyDraw2023_Init()
end

--===============================================
-- SetButtonPos()
--===============================================
function XinShouNew_SetButtonPos()
	g_XinShouNew_Frames =
	{
		[1] = XinShouNew_DoubleExp_RewardFrame,
		[2] = XinShouNew_Seven_DayFrame,
		[4] = XinShouNew_SaveUp_RewardFrame,
		[6] = XinShouNew_Time_LimitFrame,
		[7] = XinShouNew_Heroes_RoadFrame,
		[8] = XinShouNew_Supe_ValueFrame,
		[9] = XinShouNew_LevelUp_RewardFrame,
		[11] = XinShouNew_BaiBao_RewardFrame,
		[12] = XinShouNew_LuckStar_RewardFrame,
		[14]= XinShouNew_SheJiaoDaRen_RewardFrame,
		[15] = XinShouNew_SheJiaoFrame,
		[3] = XinShouNew_Seven2_DayFrame,
		[5] = XinShouNew_SaveUp2_RewardFrame,
		[10] = XinShouNew_LevelUp2_RewardFrame,
		[13] = XinShouNew_LuckStar2_RewardFrame,
	}
	g_XinShouNew_Button[1] 	= XinShouNew_Button01; --
	g_XinShouNew_Button[2] 	= XinShouNew_Button02; --
	g_XinShouNew_Button[3] 	= XinShouNew_Button03;
	g_XinShouNew_Button[4] 	= XinShouNew_Button04;
	g_XinShouNew_Button[5] 	= XinShouNew_Button05;
	g_XinShouNew_Button[6] 	= XinShouNew_Button06;
	g_XinShouNew_Button[7] 	= XinShouNew_Button07;
	g_XinShouNew_Button[8] 	= XinShouNew_Button08;
	g_XinShouNew_Button[9] 	= XinShouNew_Button09;
	g_XinShouNew_Button[10] = XinShouNew_Button10;
	g_XinShouNew_Button[11] = XinShouNew_Button11;
	
	g_XinShouNew_Button[12] = XinShouNew_Button12;
	g_XinShouNew_Button[13] = XinShouNew_Button13;
	g_XinShouNew_Button[14] = XinShouNew_Button14;
	g_XinShouNew_Button[15] = XinShouNew_Button15;

	g_XinShouNew_Tip[1] 		= XinShouNew_Button01tips;
	g_XinShouNew_Tip[2] 		= XinShouNew_Button02tips;
	g_XinShouNew_Tip[3] 		= XinShouNew_Button03tips;
	g_XinShouNew_Tip[4] 		= XinShouNew_Button04tips;
	g_XinShouNew_Tip[5] 		= XinShouNew_Button05tips;
	g_XinShouNew_Tip[6] 		= XinShouNew_Button06tips;
	g_XinShouNew_Tip[7] 		= XinShouNew_Button07tips;
	g_XinShouNew_Tip[8] 		= XinShouNew_Button08tips;
	g_XinShouNew_Tip[9] 		= XinShouNew_Button09tips;
	g_XinShouNew_Tip[10] 		= XinShouNew_Button10tips;
	g_XinShouNew_Tip[11] 		= XinShouNew_Button11tips;
	g_XinShouNew_Tip[12] 		= XinShouNew_Button12tips;
	g_XinShouNew_Tip[13] 		= XinShouNew_Button13tips;
	g_XinShouNew_Tip[14] 		= XinShouNew_Button14tips;
	g_XinShouNew_Tip[15] 		= XinShouNew_Button15tips;
	--首充
	XinShouNew_ShouChong_LoadControl()
	--2023首充
	XinShouNew_ShouChong2_LoadControl()
	--限时充值赠好礼
	XinShouNew_LimitedSaveUp_LoadControl()
	--豪侠路
	g_XinShouNew_Heroes_Road_Button[1] = XinShouNew_Heroes_RoadBK_day1_Button1;
	g_XinShouNew_Heroes_Road_Button[2] = XinShouNew_Heroes_RoadBK_day2_Button1;
	g_XinShouNew_Heroes_Road_Button[3] = XinShouNew_Heroes_RoadBK_day3_Button1;
	g_XinShouNew_Heroes_Road_Button[4] = XinShouNew_Heroes_RoadBK_day4_Button1;
	g_XinShouNew_Heroes_Road_Button[5] = XinShouNew_Heroes_RoadBK_day5_Button1;
	g_XinShouNew_Heroes_Road_Button[6] = XinShouNew_Heroes_RoadBK_day6_Button1;
	g_XinShouNew_Heroes_Road_Button[7] = XinShouNew_Heroes_RoadBK_day7_Button1;

--	g_XinShouNew_Heroes_Road_Button_lock[1] = XinShouNew_Heroes_RoadBK_day1_lock;
--	g_XinShouNew_Heroes_Road_Button_lock[2] = XinShouNew_Heroes_RoadBK_day2_lock;
--	g_XinShouNew_Heroes_Road_Button_lock[3] = XinShouNew_Heroes_RoadBK_day3_lock;
--	g_XinShouNew_Heroes_Road_Button_lock[4] = XinShouNew_Heroes_RoadBK_day4_lock;
--	g_XinShouNew_Heroes_Road_Button_lock[5] = XinShouNew_Heroes_RoadBK_day5_lock;
--	g_XinShouNew_Heroes_Road_Button_lock[6] = XinShouNew_Heroes_RoadBK_day6_lock;
--	g_XinShouNew_Heroes_Road_Button_lock[7] = XinShouNew_Heroes_RoadBK_day7_lock;

end
--===============================================
-- Hide()
--===============================================
function XinShouNew_Hide() 
	XinShouNew_Close()
end

--===============================================
-- Close()
--===============================================
function XinShouNew_Close() 
	g_XinShouNew_ShouChong_LoadFirstTime = 1;
	g_XinShouNew_ShouChong_LastShow_2023 = 0;
	g_XinShouNew_LevelUp_LoadFirstTime   = 1;
	g_XinShouNew_LevelUp_LoadFirstTime_2023 = 1;
	g_XinShouNew_LuckyDraw_LoadFirstTime = 1;
	g_XinShouNew_BaiBao_LoadFirstTime 	 = 1;
	g_XinShouNew_SuperSaveUp_LoadFirstTime = 1;
	g_SheJiaoIsFillIcon 					 = 0;
	g_EventIndex = -1
	this:Hide()
	
end
--===============================================
-- ResetPos()
--===============================================
function XinShouNew_On_ResetPos()
	XinShouNew_Frame:SetProperty("UnifiedPosition", g_XinShouNew_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function  XinShouNew_Open()
	for index=1,table.getn(g_XinShouNew_Event) do
		local event = g_XinShouNew_Event[index]
		event.isShow = 0
	end

	for index=1,table.getn(g_XinShouNew_Button) do
		g_XinShouNew_Button[index]:Hide()
		g_XinShouNew_Tip[index]:Hide()
	end
	
	for index=1,table.getn(g_XinShouNew_Button)  do
		 local ButtonState,TipsState = DataPool:Lua_GetXinShouCarnButtonState(index-1)
		 g_Button_StateTemp[index] 	 = ButtonState
		 if index == 11 and g_XinShouNew_HeroBag_IsShowTips == 0 then
		   g_Tips_StateTemp[index] 	   = 0
		 else
		 	 g_Tips_StateTemp[index] 	   = TipsState
		 end
		
	end
	
	local buttonId = 1
	for index=1,table.getn(g_XinShouNew_Event) do
		local isButtonShow = g_Button_StateTemp[index]
		local isTipsShow   = g_Tips_StateTemp[index]
		local event  = g_XinShouNew_Event[index]
		if isButtonShow == 1 then
			g_XinShouNew_Button[buttonId]:SetText(event.text)
			g_XinShouNew_Button[buttonId]:Show()
			if isTipsShow == 1 then
				g_XinShouNew_Tip[buttonId]:Show()
			end
			event.isShow = 1
			buttonId = buttonId+1
		end
	end
	
	XinShouNew_Project_Clicked( 1 )
	this:Show()

end

--===============================================
-- Clicked() 找到真正的函数
--===============================================
function XinShouNew_Project_Clicked(clickId)
	if(clickId == g_XinShouNew_LastClickedId) then
		return
	end
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_XinShouNew_ButtonLastTime < g_XinShouNew_ButtonCDTime * 1000) then
   	for index=1,table.getn(g_XinShouNew_Button) do
			if index==g_XinShouNew_LastClickedId then
				g_XinShouNew_Button[index]:SetCheck(1)
			else
				g_XinShouNew_Button[index]:SetCheck(0)
			end
		end
   	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end
	g_XinShouNew_ButtonLastTime = curTime;

	local buttonId = 0
	for index=1,table.getn(g_XinShouNew_Event) do
		local event = g_XinShouNew_Event[index]
		if event.isShow == 1 then
			buttonId = buttonId + 1
			if buttonId == clickId then
				g_EventIndex = index
				break
			end
		end
	end

	for index=1,table.getn(g_XinShouNew_Button) do
		if index==clickId then
			g_XinShouNew_Button[index]:SetCheck(1)
		else
			g_XinShouNew_Button[index]:SetCheck(0)
		end
	end
	g_XinShouNew_LastClickedId = clickId

	for index=1,table.getn(g_XinShouNew_Frames) do
		if index~=g_EventIndex then
			g_XinShouNew_Frames[index]:Hide()
		else
			g_XinShouNew_Frames[index]:Show()
		end
	end
	if g_EventIndex==1 then
		XinShouNew_DoubleExp_Show()	--双倍乐翻天
	elseif g_EventIndex==2 then
		XinShouNew_7Day_Show(0) --7日献豪礼
	elseif g_EventIndex==4 then
		XinShouNew_ShouChong_Show(1)	--首充超值赠
	elseif g_EventIndex==6 then
		XinShouNew_LimitedSaveUp_Show(1)--限时充值赠好礼
	elseif g_EventIndex==7 then
		XinShouNew_Heroes_Road_Ask()	--天龙豪侠路
	elseif g_EventIndex == 8 then 
		XinShouNew_SuperSaveUp_Show()  -- 充值赠好礼
	elseif g_EventIndex == 9 then  --升级有好礼
		XinShouNew_LevelUp_OnShow(1)
	elseif g_EventIndex == 11 then  --英雄百宝囊 
		g_XinShouNew_HeroBag_IsShowTips = 0;
		g_Tips_StateTemp[11] = 0
		XinShouNew_BaiBao_OnShow(1)
		XinShouNew_ShowButtonTips()
	elseif g_EventIndex == 12 then  --江湖幸运星
		XinShouNew_LuckyDraw_Show(1)
	elseif g_EventIndex == 14 then --社交达人
		XinShouNew_SheJiaoDaRen_Show()
	elseif g_EventIndex == 15 then --新版天龙携手行
		XinShouNew_SheJiaoNew_Show()
	elseif g_EventIndex==3 then
		XinShouNew_7Day2_Show(0) --7日献豪礼2023
	elseif g_EventIndex==5 then
		XinShouNew_ShouChong2_Show(1)	--首充超值赠2023
	elseif g_EventIndex==10 then
		XinShouNew_LevelUp2_OnShow(1)  --升级有好礼2023
	elseif g_EventIndex == 13 then --新版江湖幸运星
		XinShouNew_LuckyDraw2023_Show()
	else
		return
	end
	this:Show()
end
--===============================================
-- 设置Button 小红点
--===============================================
function XinShouNew_ShowButtonTips()   --nIndex,nIsShow
 
	local buttonId = 1
	for index=1,table.getn(g_XinShouNew_Event) do
		local isButtonShow = g_Button_StateTemp[index]
		local isTipsShow   = g_Tips_StateTemp[index] 
		if isButtonShow == 1 then 
			if isTipsShow == 1 then
				g_XinShouNew_Tip[buttonId]:Show() 
			else
				g_XinShouNew_Tip[buttonId]:Hide()
			end 
			buttonId = buttonId+1
		end
	end 
	
	local IsHideMiniMapPoint = 0
	for index=1,table.getn(g_Tips_StateTemp) do
		if g_Tips_StateTemp[index] == 1 then
			IsHideMiniMapPoint = 1
			break
		end
	end 
	PushEvent("UI_COMMAND", 2018013002, IsHideMiniMapPoint)
end
--===============================================
-- 双倍乐翻天 -begin
--===============================================

--双倍乐翻天begin 
function XinShouNew_DoubleExp_Show( )
	--双倍经验的时间 
	--双倍功力值的时间
	local pEndTime = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)
	local dpEndYear= math.floor(pEndTime/100000000)
	local dpEndMon = math.mod(math.floor(pEndTime/1000000),100)
	local dpEndDay =math.mod(math.floor(pEndTime/10000),100) 
	local dpEndHour = math.mod(math.floor(pEndTime/100),100)  

	local dexpText 		= ScriptGlobal_Format("#{XSJNH_180111_30}", dpEndYear,dpEndMon,dpEndDay,dpEndHour)
	if Player:GetData("Is2606S") == 1 then
		dexpText 		= ScriptGlobal_Format("#{XSJNH_180111_31}", dpEndYear,dpEndMon,dpEndDay,dpEndHour)
	end
	XinShouNew_DoubleExp_T_Text:SetText(dexpText)

	if Player:GetData("Is2606S") == 1 then
		XinShouNew_DoubleExp_T:Hide()
		XinShouNew_DoubleExp_Ttop:Hide()
		XinShouNew_DoubleExp_QX:Show()
	else
		XinShouNew_DoubleExp_T:Show()
		XinShouNew_DoubleExp_Ttop:Show()
		XinShouNew_DoubleExp_QX:Hide()
	end
end

--双倍乐翻天end

--===============================================
-- 双倍乐翻天 -end
--===============================================

--===============================================
-- 7日献好礼 -begin
--===============================================



--===============================================
-- 7日献好礼 -end
--===============================================

--===============================================
-- 首充享好礼-begin
--===============================================
function XinShouNew_ShouChong_LoadControl()
	g_XinShouNew_ShouChong_GiftsIcons[1] = XinShouNew_SaveUp_Right_ShowA;
	g_XinShouNew_ShouChong_GiftsIcons[2] = XinShouNew_SaveUp_Right_ShowB;
	g_XinShouNew_ShouChong_GiftsIcons[3] = XinShouNew_SaveUp_Right_ShowC;
	g_XinShouNew_ShouChong_GiftsIcons[4] = XinShouNew_SaveUp_Right_ShowD;
end

function XinShouNew_ShouChong_Show(ShowTime)
	XinShouNew_ShouChong_UpdateButtonReq();
	XinShouNew_ShouChong_FlushWindow()		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end
function XinShouNew_ShouChong_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSaveUpGiftsButtonState" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892676 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_ShouChong_UpdateButtonState()
	local ButtonState = Get_XParam_INT(0)
	g_XinShouNew_ShouChong_ButtonState = ButtonState
	XinShouNew_ShouChong_FlushWindow()
end
function XinShouNew_ShouChong_FlushWindow()
	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_XinShouNew_ShouChong_LoadFirstTime == 1 then
		for i = 1,  table.getn(g_XinShouNew_ShouChong_Gifts) do
			local GiftItemID	=		g_XinShouNew_ShouChong_Gifts[i].GiftItemID
			local GiftItemNum	= 	g_XinShouNew_ShouChong_Gifts[i].num
			local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then
				g_XinShouNew_ShouChong_GiftsIcons[i]:SetActionItem(theAction:GetID());
				g_XinShouNew_ShouChong_GiftsIcons[i]:Show();
			end
		end
		g_XinShouNew_ShouChong_LoadFirstTime = 0
	end
	if g_XinShouNew_ShouChong_ButtonState == 0 then
		XinShouNew_SaveUp_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LKCZ_Normal")
		XinShouNew_SaveUp_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LKCZ_Hover")
		XinShouNew_SaveUp_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LKCZ_Pushed")
		XinShouNew_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_55}", 0))
		XinShouNew_SaveUp_Right_Button1 : Enable()
	elseif g_XinShouNew_ShouChong_ButtonState == 1 then
		XinShouNew_SaveUp_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LQCZJL_Normal")
		XinShouNew_SaveUp_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LQCZJL_Hover")
		XinShouNew_SaveUp_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LQCZJL_Pushed")
		XinShouNew_SaveUp_Right_Button1 : Show()
		XinShouNew_SaveUp_Right_Button1 : Enable()
		XinShouNew_SaveUp_Right_ConditionText:SetText("#{XSJNH_180111_56}")
	elseif g_XinShouNew_ShouChong_ButtonState == 2 then
		XinShouNew_SaveUp_Right_Button1 : SetProperty("DisabledImage","set:XSYNew01 image:XSYNew_LQCZJL_Disabled")
		XinShouNew_SaveUp_Right_Button1 : Disable()
		XinShouNew_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_56}", 200))
	end
end
function XinShouNew_ShouChong_GetGiftsForCostYuanBao()
	--前往充值
	if g_XinShouNew_ShouChong_ButtonState == 0 then
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
		return
	end
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForSaveUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892676 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end

--===============================================
-- 首充享好礼 -end
--===============================================

--===============================================
-- 首充享好礼2023-begin
--===============================================
function XinShouNew_ShouChong2_LoadControl()
	g_XinShouNew_ShouChong_GiftsIcons_2023[1] = XinShouNew_SaveUp2_Right_ShowA;
	g_XinShouNew_ShouChong_GiftsIcons_2023[2] = XinShouNew_SaveUp2_Right_ShowB;
	g_XinShouNew_ShouChong_GiftsIcons_2023[3] = XinShouNew_SaveUp2_Right_ShowC;
	
	g_XinShouNew_ShouChong_BKImg_2023[1] = XinShouNew_SaveUp2BK1
	g_XinShouNew_ShouChong_BKImg_2023[2] = XinShouNew_SaveUp2BK2
	g_XinShouNew_ShouChong_BKImg_2023[3] = XinShouNew_SaveUp2BK3
	
end

function XinShouNew_ShouChong2_Show(ShowTime)
	XinShouNew_ShouChong2_UpdateButtonReq();
	XinShouNew_ShouChong2_FlushWindow()		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end
function XinShouNew_ShouChong2_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSaveUpGiftsButtonState_2023" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998411 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_ShouChong2_UpdateButtonState()
	local buttonState = Get_XParam_INT(0)
	local curLevel = Get_XParam_INT(1)
	local curExch = Get_XParam_INT(2)
	g_XinShouNew_ShouChong_ButtonState_2023 = buttonState
	g_XinShouNew_ShouChong_CurGiftLevel_2023 = curLevel
	g_XinShouNew_ShouChong_CurExch_2023 = curExch
	XinShouNew_ShouChong2_FlushWindow()
end

---!!!reloadscript =XinShouNew
function XinShouNew_ShouChong2_FlushWindow()

	---XinShouNew_SaveUp2_Right_ConditionText:Hide()
	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_XinShouNew_ShouChong_LastShow_2023 == 0 or g_XinShouNew_ShouChong_LastShow_2023 ~= g_XinShouNew_ShouChong_CurGiftLevel_2023 then
		local GiftInfo = g_XinShouNew_ShouChong_Gifts_2023[g_XinShouNew_ShouChong_CurGiftLevel_2023]
		if Player:GetData("Is2606S") == 1 then
			GiftInfo = g_XinShouNew_2606S_GiftInfo[4][g_XinShouNew_ShouChong_CurGiftLevel_2023]
		end
		for i = 1,  table.getn(GiftInfo) do
			local GiftItemID	=	GiftInfo[i].GiftItemID
			local GiftItemNum	= 	GiftInfo[i].num
			local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then
				g_XinShouNew_ShouChong_GiftsIcons_2023[i]:SetActionItem(theAction:GetID());
				g_XinShouNew_ShouChong_GiftsIcons_2023[i]:Show();
			end
		end
		g_XinShouNew_ShouChong_LastShow_2023 = g_XinShouNew_ShouChong_CurGiftLevel_2023
	end
	
	for i = 1,3 do
		g_XinShouNew_ShouChong_BKImg_2023[i]:Hide()	
	end
	g_XinShouNew_ShouChong_BKImg_2023[g_XinShouNew_ShouChong_CurGiftLevel_2023]:Show()	
	
	if g_XinShouNew_ShouChong_ButtonState_2023 == 0 then  --立刻兑换元宝
		XinShouNew_SaveUp2_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LKCZ_Normal")
		XinShouNew_SaveUp2_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LKCZ_Hover")
		XinShouNew_SaveUp2_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LKCZ_Pushed")
		if g_XinShouNew_ShouChong_CurGiftLevel_2023 == 1 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_55}", 0))
		elseif g_XinShouNew_ShouChong_CurGiftLevel_2023 == 2 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_07}", g_XinShouNew_ShouChong_CurExch_2023))
		elseif g_XinShouNew_ShouChong_CurGiftLevel_2023 == 3 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_08}", g_XinShouNew_ShouChong_CurExch_2023))
		end

		XinShouNew_SaveUp2_Right_Button1 : Enable()
	elseif g_XinShouNew_ShouChong_ButtonState_2023 == 1 then  --领奖
		XinShouNew_SaveUp2_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LQCZJL_Normal")
		XinShouNew_SaveUp2_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LQCZJL_Hover")
		XinShouNew_SaveUp2_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LQCZJL_Pushed")
		XinShouNew_SaveUp2_Right_Button1 : Show()
		XinShouNew_SaveUp2_Right_Button1 : Enable()
		if g_XinShouNew_ShouChong_CurGiftLevel_2023 == 1 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText("#{XSJNH_180111_56}")
		elseif g_XinShouNew_ShouChong_CurGiftLevel_2023 == 2 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText("#{XSJNH_230209_09}")
		elseif g_XinShouNew_ShouChong_CurGiftLevel_2023 == 3 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText("#{XSJNH_230209_10}")
		end
	elseif g_XinShouNew_ShouChong_ButtonState_2023 == 2 then  --不可用
		XinShouNew_SaveUp2_Right_Button1 : SetProperty("DisabledImage","set:XSYNew01 image:XSYNew_LQCZJL_Disabled")
		XinShouNew_SaveUp2_Right_Button1 : Disable()
		if g_XinShouNew_ShouChong_CurGiftLevel_2023 == 1 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_56}", 200))
		elseif g_XinShouNew_ShouChong_CurGiftLevel_2023 == 2 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_07}", 800))
		elseif g_XinShouNew_ShouChong_CurGiftLevel_2023 == 3 then
			XinShouNew_SaveUp2_Right_ConditionText:SetText("#{XSJNH_230209_10}")
		end
	end
	
	
end
function XinShouNew_ShouChong2_GetGiftsForCostYuanBao()
	--前往充值
	if g_XinShouNew_ShouChong_ButtonState_2023 == 0 then
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
		return
	end
	---PushDebugMessage("XinShouNew_ShouChong2_GetGiftsForCostYuanBao g_XinShouNew_ShouChong_CurGiftLevel_2023 = "..g_XinShouNew_ShouChong_CurGiftLevel_2023)

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForSaveUp_2023" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998411 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一
		Set_XSCRIPT_Parameter( 1, g_XinShouNew_ShouChong_CurGiftLevel_2023 );		-- 当前奖励等级
		Set_XSCRIPT_ParamCount( 2 );				-- 参数个数
	Send_XSCRIPT()
end

--===============================================
-- 首充享好礼2023 -end
--===============================================


--===============================================
-- 限时充值好礼-begin
--===============================================
function XinShouNew_LimitedSaveUp_LoadControl()
	g_XinShouNew_LimitedSaveUp_GiftsIcons[1] = XinShouNew_Time_Mian_ShowA;
	g_XinShouNew_LimitedSaveUp_GiftsIcons[2] = XinShouNew_Time_Mian_ShowB;
	g_XinShouNew_LimitedSaveUp_GiftsIcons[3] = XinShouNew_Time_Mian_ShowC;
	g_XinShouNew_LimitedSaveUp_ButtonDone[1] = XinShouNew_Time_Bottom_day1_done
	g_XinShouNew_LimitedSaveUp_ButtonDone[2] = XinShouNew_Time_Bottom_day3_done
	g_XinShouNew_LimitedSaveUp_ButtonDone[3] = XinShouNew_Time_Bottom_day7_done 
	g_XinShouNew_LimitedSaveUp_Button[1] = XinShouNew_Time_Bottom_day1_Button1
	g_XinShouNew_LimitedSaveUp_Button[2] = XinShouNew_Time_Bottom_day3_Button1
	g_XinShouNew_LimitedSaveUp_Button[3] = XinShouNew_Time_Bottom_day7_Button1
end

function XinShouNew_LimitedSaveUp_Show()
	XinShouNew_LimitedSaveUp_UpdateButtonReq();
	XinShouNew_LimitedSaveUp_FlushWindow(1)		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end
function XinShouNew_LimitedSaveUp_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLimitedSaveGiftsInfo" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892689 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_LimitedSaveUp_UpdateInfo()
	g_XinShouNew_LimitedSaveUp_RemainDay  = Get_XParam_INT(0)
	g_XinShouNew_LimitedSaveUp_RemainTime = Get_XParam_INT(1)
	g_XinShouNew_LimitedSaveUp_Exch 			= Get_XParam_INT(2)
	g_XinShouNew_LimitedSaveUp_Cost 			= Get_XParam_INT(3)

	for i=1,table.getn(g_XinShouNew_LimitedSaveUp_ButtonState) do
		g_XinShouNew_LimitedSaveUp_ButtonState[i] = Get_XParam_INT(3+i)
	end

	local nFlushIndex = 1;
	for i=1,table.getn(g_XinShouNew_LimitedSaveUp_ButtonState) do
		if g_XinShouNew_LimitedSaveUp_ButtonState[i] ~= 2 then
			nFlushIndex = i;
			break;
		end
	end
	XinShouNew_LimitedSaveUp_FlushWindow(nFlushIndex)
	
end
function XinShouNew_LimitedSaveUp_FlushWindow( Index )
	g_XinShouNew_LimitedSaveUp_CurSelect = 	Index
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local tableXinShouNew_LimitedSaveUp_Gifts = g_KajiTable_XSJNH[3][kajiType]
	for i = 1,  table.getn(tableXinShouNew_LimitedSaveUp_Gifts[Index]) do
		if g_XinShouNew_LimitedSaveUp_GiftsIcons[i] == nil then
			return
		end
		g_XinShouNew_LimitedSaveUp_GiftsIcons[i]:SetActionItem(-1);
		local GiftItemID	=	tableXinShouNew_LimitedSaveUp_Gifts[Index][i].GiftItemID
		local GiftItemNum	= 	tableXinShouNew_LimitedSaveUp_Gifts[Index][i].num
		local theAction 	= 	DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
		if theAction:GetID() ~= 0 then
			g_XinShouNew_LimitedSaveUp_GiftsIcons[i]:SetActionItem(theAction:GetID());
			g_XinShouNew_LimitedSaveUp_GiftsIcons[i]:Show();
		end
	end
	if g_XinShouNew_LimitedSaveUp_ButtonState[Index] == 0 then --未达成
		XinShouNew_Time_Mian_Button1:Disable()
		XinShouNew_Time_Mian_Info1:SetText(g_XinShouNew_LimitedSaveUp_Content[Index].Content)
		if g_XinShouNew_LimitedSaveUp_RemainTime <= 0 then
			XinShouNew_Time_Mian_Info2:SetText("#{XSJNH_180111_70}")
		else
			if g_XinShouNew_LimitedSaveUp_RemainDay > 0 then
				XinShouNew_Time_Mian_Info2:SetText(ScriptGlobal_Format("#{XSJNH_180111_66}",g_XinShouNew_LimitedSaveUp_RemainDay))
			elseif g_XinShouNew_LimitedSaveUp_RemainDay == 0 and g_XinShouNew_LimitedSaveUp_RemainTime >= 3600 then 
				XinShouNew_Time_Mian_Info2:SetText(ScriptGlobal_Format("#{XSJNH_180111_67}",math.floor(g_XinShouNew_LimitedSaveUp_RemainTime/3600)))
			elseif g_XinShouNew_LimitedSaveUp_RemainTime >= 60 then
				XinShouNew_Time_Mian_Info2:SetText(ScriptGlobal_Format("#{XSJNH_180111_68}",math.floor(g_XinShouNew_LimitedSaveUp_RemainTime/60)))
			elseif g_XinShouNew_LimitedSaveUp_RemainTime < 60 then
				XinShouNew_Time_Mian_Info2:SetText(ScriptGlobal_Format("#{XSJNH_180127_267}",g_XinShouNew_LimitedSaveUp_RemainTime))
			end
		end
			--Exch = 4000, Cost
		if g_XinShouNew_LimitedSaveUp_Exch < g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch then
			XinShouNew_Time_Mian_ConditionText1:SetText(ScriptGlobal_Format("#{XSJNH_180111_71}", g_XinShouNew_LimitedSaveUp_Exch,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch))
		else
			XinShouNew_Time_Mian_ConditionText1:SetText(ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch))
		end
		if g_XinShouNew_LimitedSaveUp_Cost < g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost then
			XinShouNew_Time_Mian_ConditionText2:SetText(ScriptGlobal_Format("#{XSJNH_180111_72}", g_XinShouNew_LimitedSaveUp_Cost,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost))
		else
			XinShouNew_Time_Mian_ConditionText2:SetText(ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost))
		end
		--XinShouNew_Time_Mian_Button1_tips:SetProperty("Tooltip",g_XinShouNew_LimitedSaveUp_Content[Index].Tips)
		XinShouNew_Time_Mian_Button1_tips:SetToolTip(g_XinShouNew_LimitedSaveUp_Content[Index].Tips)
		XinShouNew_Time_Mian_Button1_tips:Show()
		--金钱不满足  设置图片
		if g_XinShouNew_LimitedSaveUp_Exch < g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch or g_XinShouNew_LimitedSaveUp_Cost < g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost then
			XinShouNew_Time_Mian_Button1:SetProperty("DisabledImage","set:XSYNew02 image:XinShouNew_Time_DisabledWDC")
		else --时间未到
			XinShouNew_Time_Mian_Button1:SetProperty("DisabledImage",g_XinShouNew_LimitedSaveUp_WDCImage[Index].Set.." "..g_XinShouNew_LimitedSaveUp_WDCImage[Index].Image)
		end
	elseif g_XinShouNew_LimitedSaveUp_ButtonState[Index] == 1 then -- 可以领取
		XinShouNew_Time_Mian_Button1:Enable()
		--XinShouNew_Time_Mian_Button1:SetText("#{XSJNH_180111_79}")
		XinShouNew_Time_Mian_Info1:SetText(g_XinShouNew_LimitedSaveUp_Content[Index].Content)
		XinShouNew_Time_Mian_Info2:SetText("#{XSJNH_180111_69}")
		XinShouNew_Time_Mian_ConditionText1:SetText(ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch))
		XinShouNew_Time_Mian_ConditionText2:SetText(ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost))
		XinShouNew_Time_Mian_Button1:SetToolTip(g_XinShouNew_LimitedSaveUp_Content[Index].Tips) 
		XinShouNew_Time_Mian_Button1_tips:Hide()
	elseif g_XinShouNew_LimitedSaveUp_ButtonState[Index] == 2 then -- 已经领取
		XinShouNew_Time_Mian_Button1:SetProperty("DisabledImage","set:XSYNew02 image:XinShouNew_Time_DisabledYLQ")
		XinShouNew_Time_Mian_Button1:Disable() 
		XinShouNew_Time_Mian_Info1:SetText(g_XinShouNew_LimitedSaveUp_Content[Index].Content)
		XinShouNew_Time_Mian_Info2:SetText("#{XSJNH_180111_69}")
		XinShouNew_Time_Mian_ConditionText1:SetText(ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Exch))
		XinShouNew_Time_Mian_ConditionText2:SetText(ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost,g_XinShouNew_LimitedSaveUp_GetGiftsCondition[Index].Cost))
		XinShouNew_Time_Mian_Button1_tips:Show()
		XinShouNew_Time_Mian_Button1_tips:SetToolTip(g_XinShouNew_LimitedSaveUp_Content[Index].Tips)
	end
	 
	for i =1 , table.getn(g_XinShouNew_LimitedSaveUp_ButtonDone) do
		if g_XinShouNew_LimitedSaveUp_ButtonState[i] == 2 then
			g_XinShouNew_LimitedSaveUp_ButtonDone[i]:Show()
		else 
			g_XinShouNew_LimitedSaveUp_ButtonDone[i]:Hide()
		end
		if i ~= Index then
			g_XinShouNew_LimitedSaveUp_Button[i]:SetCheck(0)
		else
			g_XinShouNew_LimitedSaveUp_Button[i]:SetCheck(1)
		end
	end 
	
end
function XinShouNew_LimitedSaveUp_GetGiftsForCostYuanBao()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLimitedSaveUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892689 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( g_XinShouNew_LimitedSaveUp_CurSelect ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end




--===============================================
-- 限时充值礼馈 -end
--===============================================


--===============================================
-- 充值超值赠-begin
--===============================================
function XinShouNew_SuperSaveUp_LoadControl()
end

function XinShouNew_SuperSaveUp_Show()
	XinShouNew_SuperSaveUp_UpdateButtonReq();
	--XinShouNew_SuperSaveUp_FlushWindow(1)		--在服务器数据返回之前,根据数据初始值,先初步构建界面
	--控制新服特权商店按钮显隐
	if 1 == DataPool:Lua_XFTQShopIsOpen() then
		XinShouNew_Supe_VIP_Btn:Show()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskShowShopBtnRedPoint" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998401 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
		Send_XSCRIPT()
	else
		XinShouNew_Supe_VIP_Btn:Hide()
		XinShouNew_Supe_VIP_Btn_Tips:Hide()
	end
	--新服特权卡
	if 1==DataPool:Lua_TeQuanKaIsOpen()   then
		XinShouNew_Supe_ChaKan_Image:Show()
		local timel,timeh = Lua_GetTeQuanKaTime("jingtong")
		if timeh and timel then
			if  timeh > 0  then
				--激活高级
				XinShouNew_Supe_ChaKan_Image:SetProperty("Image","set:Xinfu_Tequan image:zunxiang")
				
				local leftdays = math.floor( timeh/1440 )
				if leftdays > 0 then
					XinShouNew_Supe_ChaKan_Image:SetToolTip( ScriptGlobal_Format("#{XFTQ_230203_91}",leftdays) )
				else
					XinShouNew_Supe_ChaKan_Image:SetToolTip("#{XFTQ_230203_92}")
				end
			elseif  timel > 0 then
				--激活普通
				XinShouNew_Supe_ChaKan_Image:SetProperty("Image","set:Xinfu_Tequan image:youxiang")
				local leftdays = math.floor( timel/1440 )
				if leftdays > 0 then
					XinShouNew_Supe_ChaKan_Image:SetToolTip( ScriptGlobal_Format("#{XFTQ_230203_89}",leftdays) )
				else
					XinShouNew_Supe_ChaKan_Image:SetToolTip("#{XFTQ_230203_90}")
				end
			else
				XinShouNew_Supe_ChaKan_Image:SetProperty("Image","set:Xinfu_Tequan image:weijihuo")
				XinShouNew_Supe_ChaKan_Image:SetToolTip("#{XFTQ_230203_93}")
			end
		end
	else
		XinShouNew_Supe_ChaKan_Image:Hide()
	end
end
function XinShouNew_SuperSaveUp_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSuperSaveUpGiftsInfo" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892690 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_SuperSaveUp_UpdateInfo() 
	g_XinShouNew_SuperSaveUp_Exch  = Get_XParam_INT(0)
	g_XinShouNew_SuperSaveUp_Cost  = Get_XParam_INT(1)
	for i=1,table.getn(g_XinShouNew_SuperSaveUp_ButtonState) do
		g_XinShouNew_SuperSaveUp_ButtonState[i] = Get_XParam_INT(i+1)
	end
	g_XinShouNew_SuperSaveUp_ScrollbarPosition = XinShouNew_Supe_MianList:GetVertScrollbarPosition()
	XinShouNew_SuperSaveUp_FlushWindow()
end
function XinShouNew_SuperSaveUp_FlushWindow()
	XinShouNew_SuperSaveUp_CleanActionItemInfo()
	XinShouNew_Supe_MianList:CleanAllElement("XinShouNew") 
	local nCurIndex = 0
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local tableXinShouNew_SuperSaveUp_Gifts = g_KajiTable_XSJNH[1][kajiType]
	if Player:GetData("Is2606S") == 1 then
		tableXinShouNew_SuperSaveUp_Gifts = g_XinShouNew_2606S_GiftInfo[1]
	end
	for i = 1,  table.getn(tableXinShouNew_SuperSaveUp_Gifts) do
		local ItemBar = XinShouNew_Supe_MianList:AddItemElement( "SupeValueButton", "LEFT", "XinShouNew","" ,"")
		if ItemBar == nil then
			return
		end
		ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
		ItemBar:Setm_newImage(1,g_XinShouNew_LimitedSaveUp_GiftsImage[i].Set, g_XinShouNew_LimitedSaveUp_GiftsImage[i].Image)
		
		for j = 1,  table.getn(tableXinShouNew_SuperSaveUp_Gifts[i]) do
			local itemButton  = 	ItemBar:GetLuaActionButton(j,"XinShouNew")
			local GiftItemID	=		tableXinShouNew_SuperSaveUp_Gifts[i][j].GiftItemID
			local GiftItemNum	= 	tableXinShouNew_SuperSaveUp_Gifts[i][j].num
			local theAction 	= 	DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then 
				itemButton:SetActionItem(theAction:GetID())
			end
		end
		
		if i == 1 then
			ItemBar:Setm_newImageHide(4)
		end
		--卡69级服第10档奖励只有2个
		if kajiType == 1 and i == 10 then
			ItemBar:Setm_newImageHide(4)
		end


		--未达成
		if g_XinShouNew_SuperSaveUp_ButtonState[i] == 0 then 
			--ItemBar:SetButton1Text("#{XSJNH_180111_75}")
			if g_XinShouNew_SuperSaveUp_Exch < g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch then
				local Text1 = ScriptGlobal_Format("#{XSJNH_180111_71}", g_XinShouNew_SuperSaveUp_Exch,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1,Text1)
			else
				local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1,Text1)
			end
			if g_XinShouNew_SuperSaveUp_Cost < g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost then
				local Text2 = ScriptGlobal_Format("#{XSJNH_180111_72}", g_XinShouNew_SuperSaveUp_Cost,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost)
				ItemBar:Setm_newText(2,Text2)
			else
				local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost)
				ItemBar:Setm_newText(2,Text2)
			end
			ItemBar:Setm_newImage(7,"CommonFrame34", "SignSummerButton_Weidacheng")
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImageShow(7)
		--可以领取
		elseif g_XinShouNew_SuperSaveUp_ButtonState[i] == 1 then 
			--ItemBar:SetButton1Text("#{XSJNH_180111_79}")
			local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1,Text1)
			local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost)
			ItemBar:Setm_newText(2,Text2)
			--ItemBar:SetButton1Show()
			ItemBar:Setm_newImageHide(7)
			--已经领取
			if nCurIndex == 0 then
				nCurIndex = i
			end
		elseif g_XinShouNew_SuperSaveUp_ButtonState[i] == 2 then  
			local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1,Text1)
			local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost,g_XinShouNew_SuperSaveUp_GetGiftsCondition[i].Cost)
			ItemBar:Setm_newText(2,Text2)
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImage(7,"CommonFrame34", "SignSummerButton_Yilingqu")
			ItemBar:Setm_newImageShow(7)
		end
		table.insert(g_XinShouNew_SuperSaveUp_ContentButton, ItemBar) 
	end
	 
	if nCurIndex ~= 0 and g_XinShouNew_SuperSaveUp_LoadFirstTime == 1 then
		g_XinShouNew_SuperSaveUp_LoadFirstTime = 0;
		g_XinShouNew_SuperSaveUp_CurrentSelect = nCurIndex  
		XinShouNew_SuperSaveUp_SetButtonSelected(nCurIndex)
		XinShouNew_Supe_MianList:Flash()
		local curPos = XinShouNew_SuperSaveUp_CalcListScrollPos(g_XinShouNew_SuperSaveUp_CurrentSelect)
		XinShouNew_Supe_MianList:SetVertScrollbarPosition(curPos)
	else
		XinShouNew_Supe_MianList:Flash() 
		XinShouNew_Supe_MianList:SetVertScrollbarPosition(g_XinShouNew_SuperSaveUp_ScrollbarPosition)
	end
end
function XinShouNew_SuperSaveUp_CleanActionItemInfo()
	local nListCount = table.getn(g_XinShouNew_SuperSaveUp_ContentButton)
	if nListCount <= 0 then
		g_XinShouNew_SuperSaveUp_ContentButton = {}
		return
	end
	for i = 1, nListCount do
		if nil ~= g_XinShouNew_SuperSaveUp_ContentButton[i] then
			for j = 1, 3 do
				local itemButton = g_XinShouNew_SuperSaveUp_ContentButton[i]:GetLuaActionButton(j,"XinShouNew")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
				end
			end
		end
	end 
	g_XinShouNew_SuperSaveUp_ContentButton = {}
end
function XinShouNew_SuperSaveUp_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		XinShouNew_SuperSaveUp_SetButtonSelected(nIndex + 1)
		XinShouNew_Supe_MianList:Flash()
		g_XinShouNew_SuperSaveUp_CurrentSelect = nIndex 
	end
	  
end

function XinShouNew_SuperSaveUp_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) 
	if nIndex >= 0 then 
		XinShouNew_SuperSaveUp_SetButtonSelected(nIndex + 1)
		XinShouNew_Supe_MianList:Flash()
		g_XinShouNew_SuperSaveUp_CurrentSelect = nIndex+1  
		XinShouNew_SuperSaveUp_GetGiftsForCostYuanBao(g_XinShouNew_SuperSaveUp_CurrentSelect)
	end
end
function XinShouNew_SuperSaveUp_GetGiftsForCostYuanBao( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForSuperSaveUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892690 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, Index );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_SuperSaveUp_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_XinShouNew_SuperSaveUp_ContentButton) do
		if nil ~= g_XinShouNew_SuperSaveUp_ContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_XinShouNew_SuperSaveUp_ContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_XinShouNew_SuperSaveUp_ContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function XinShouNew_SuperSaveUp_CalcListScrollPos(SelectIdx)
	if	SelectIdx <= 2 then
		return 0
	elseif SelectIdx == 3 then
		return 64
	elseif SelectIdx == 4 then
		return 128
	elseif SelectIdx == 5 then
		return 192
	elseif SelectIdx >= 6 then
		return 270
	end
end
--===============================================
-- 充值超值赠 -end
--===============================================

--===============================================
-- 升级有好礼-begin
--===============================================

--**********************************
-- 更新Data
--**********************************
function XinShouNew_LevelUp_OnShow(ShowTime)
	XinShouNew_LevelUp_UpdateButtonReq();
	XinShouNew_LevelUp_FlushWindow(ShowTime)		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end

--**********************************
-- 请求更新Btn状态
--**********************************
function XinShouNew_LevelUp_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892684 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()

end

function XinShouNew_LevelUp_UpdateRedPoint(ShowTime)
	local nLevel = g_PlayerLevel;--Player : GetLevel();
	local LevelNeed = 0;

	for i = 1,table.getn(g_XinShouNew_LevelUp_GetGiftLevel)  do
		if nLevel >= g_XinShouNew_LevelUp_GetGiftLevel[i] then
			LevelNeed = i
		end
	end

	local flagpage = {[1]=0,[2]=0}

	for i = 1, table.getn(g_XinShouNew_LevelUpBtnState) do
			if LevelNeed < i then
				break
			end
			if g_XinShouNew_LevelUpBtnState[i] ~= 1 then
				if g_XinShouNew_LevelUpPageState[i] == 1 then
					flagpage[1] = 1
				elseif g_XinShouNew_LevelUpPageState[i] == 2 then
					flagpage[2] = 1
				end
			end
	end

	if flagpage[1] == 1 then
		XinShouNew_LevelUp_Client_Button01tips:Show()
	else
		XinShouNew_LevelUp_Client_Button01tips:Hide()
	end
	if flagpage[2] == 1 then
		XinShouNew_LevelUp_Client_Button02tips:Show()
	else
		XinShouNew_LevelUp_Client_Button02tips:Hide()
	end
	--if flagpage[1] ~= 1 and flagpage[2] ~= 1 then
	--	XinShouNew_ShowButtonTips(7,0)
	--else
	--	XinShouNew_ShowButtonTips(7,1)
	--end
end
--**********************************
-- 【新服欢乐月·升级送好礼】刷新界面
--**********************************
function XinShouNew_LevelUp_FlushWindow(ShowTime)

	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_XinShouNew_LevelUp_LoadFirstTime == 1 then
		for i = 1,  table.getn(g_XinShouNew_LevelUp_GiftsIcons) do
			for j = 1, table.getn(g_XinShouNew_LevelUp_GiftsIcons[i]) do
				local	GiftItemID	=	-1
				local	GiftItemNum	=	0
				if j > table.getn( g_XinShouNew_LevelUp_Gifts[i] ) then
					g_XinShouNew_LevelUp_GiftsIcons[i][j]:Hide();
				else
					GiftItemID	=	g_XinShouNew_LevelUp_Gifts[i][j].GiftItemID
					GiftItemNum	= 	g_XinShouNew_LevelUp_Gifts[i][j].num
					local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
					if theAction:GetID() ~= 0 then
						if g_XinShouNew_LevelUp_Gifts[i][j].new ~= nil and g_XinShouNew_LevelUp_Gifts[i][j].new == 1 then
							g_XinShouNew_LevelUp_GiftsIconsImages[i][j] : SetProperty("Image",g_XinShouNew_PrizeItemButtonIcon);
						end
						g_XinShouNew_LevelUp_GiftsIcons[i][j]:SetActionItem(theAction:GetID());
						g_XinShouNew_LevelUp_GiftsIcons[i][j]:Show();
					end
				end
			end
		end
		g_XinShouNew_LevelUp_LoadFirstTime = 0
	end

	local nLevel = g_PlayerLevel; --Player : GetLevel();

	local LevelGrade = 1;

	for i = 1,table.getn(g_XinShouNew_LevelUp_GetGiftLevel)  do
		if nLevel < g_XinShouNew_LevelUp_GetGiftLevel[i] then
			LevelGrade = i
			break
		end
	end

	--获取活动起止时间
  local EndDate = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)

  local deEndYear = math.floor(EndDate/100000000)
	local deEndMon = math.mod(math.floor(EndDate/1000000),100)
	local deEndDay = math.mod(math.floor(EndDate/10000),100)
	local deEndHour = math.mod(math.floor(EndDate/100),100)

	--设置【新服欢乐月·升级送好礼】界面提示语
	if g_XinShouNew_LevelUp_PageIndex == 1 then
		XinShouNew_LevelUp_Info : SetText(ScriptGlobal_Format("#{XSJNH_180111_94}", deEndYear,deEndMon , deEndDay , deEndHour) );
	else

		XinShouNew_LevelUp_Info : SetText(ScriptGlobal_Format("#{XSJNH_180111_95}",deEndYear,deEndMon , deEndDay , deEndHour) );
	end
	--先设置所有可以领取的Button的状态为:"已领取"或者"未领取"
	for i = 1, LevelGrade - 1 do
		if g_XinShouNew_LevelUpBtnState[i] == 1 then
			--设置按钮图片为已领取
			g_XinShouNew_LevelUp_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
			g_XinShouNew_LevelUp_GetGiftsButtonList[i] : Disable()
		else
			g_XinShouNew_LevelUp_GetGiftsButtonList[i] : Enable()
		end
	end

	for i = LevelGrade, table.getn(g_XinShouNew_LevelUp_GetGiftsButtonList) do
			--设置未达成的Button
			g_XinShouNew_LevelUp_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC")
			g_XinShouNew_LevelUp_GetGiftsButtonList[i] : Disable()
	end

	local		ShowIndexBegin = 0
	local 	ShowIndexEnd   = 0
	local   HideIndexBegin = 0
	local   HideIndexEnd   = 0
	if g_XinShouNew_LevelUp_PageIndex == 1 then
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
		for j = 1, table.getn(g_XinShouNew_LevelUp_Gifts[i]) do
			g_XinShouNew_LevelUp_GiftsIcons[i][j] : Show();
		end
	end
	for i = ShowIndexBegin, ShowIndexEnd do
		g_XinShouNew_LevelUp_GetGiftsButtonList[i] : Show();
		--g_XinShouNew_LevelUp_Frames[i] : SetProperty("AlwaysOnTop","True")
		g_XinShouNew_LevelUp_Frames[i] : Show()
	end

	--设置另一页面的[按钮]和图标为不可见
	for i = HideIndexBegin, HideIndexEnd do
		for j = 1, table.getn(g_XinShouNew_LevelUp_GiftsIcons[i]) do
			g_XinShouNew_LevelUp_GiftsIcons[i][j] : Hide();
		end
	end
	for i = HideIndexBegin, HideIndexEnd do
		g_XinShouNew_LevelUp_GetGiftsButtonList[i] : Hide();
		--g_XinShouNew_LevelUp_Frames[i] : SetProperty("AlwaysOnTop","False")
		g_XinShouNew_LevelUp_Frames[i] : Hide()
	end

	--设置额外需要隐藏的[按钮]和图标为不可见
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local extraHideIndexBegin = g_KajiTable_XSJNH[4][kajiType][1]
	local extraHideIndexEnd = g_KajiTable_XSJNH[4][kajiType][2]
	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	if nSpecKaJi89 == 1 or nSpecKaJi89 == 2 then
		extraHideIndexBegin = 12
		extraHideIndexEnd = 13
	end
	if  extraHideIndexBegin > 0 and extraHideIndexBegin <= extraHideIndexEnd then
		for i = extraHideIndexBegin, extraHideIndexEnd do
			for j = 1, table.getn(g_XinShouNew_LevelUp_GiftsIcons[i]) do
				g_XinShouNew_LevelUp_GiftsIcons[i][j] : Hide();
			end
			g_XinShouNew_LevelUp_GetGiftsButtonList[i] : Hide();
			g_XinShouNew_LevelUp_Frames[i] : Hide()
		end
	end

	-- 更新小红点
	XinShouNew_LevelUp_UpdateRedPoint(ShowTime)

end
--********************************************************************
-- 按钮,客户端界面"领取奖励"按钮点击响应事件函数
--********************************************************************
function XinShouNew_LevelUp_Frame3_GetGift( nIndex )
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--1.检测玩家的等级是否到达可领奖的等级
	local nLevel = Player : GetLevel()
	if nLevel < g_XinShouNew_LevelUp_GetGiftLevel[nIndex] then
		PushDebugMessage("#{SJSHL_140919_24}")					--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end
	--2.玩家是否未领取该奖励
	if nIndex < 1 or nIndex > 13 then
		return
	elseif g_XinShouNew_LevelUpBtnState[nIndex] == 1 then					--按钮为"未点亮"状态,说明根据MF判断玩家已经领取过该两例
		PushDebugMessage("#{SJSHL_140919_25}")					--对不起,您已经领取过此奖励,无法再次领取
		return
	end
	--3.判断玩家背包位置数是否足够
--	local nBegin = -1;
	--for i = 1, table.getn( XinShouNew_LevelUpBtnState ) do
		--if ( XinShouNew_LevelUpBtnState[ i ] == 0 ) then
		--	nBegin = i
		--	break
		--end
	--end

	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892684 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end
--**********************************
-- 按钮【初出茅庐】点击事件
--**********************************
function XinShouNew_LevelUp_Click_Button1()
	g_XinShouNew_LevelUp_PageIndex  = 1
	XinShouNew_LevelUp_Client_Button01:Disable();
	XinShouNew_LevelUp_Client_Button02:Enable();
	XinShouNew_LevelUp_FlushWindow(1);
end

--**********************************
-- 按钮【仗剑江湖】点击事件
--**********************************
function XinShouNew_LevelUp_Click_Button2()
	g_XinShouNew_LevelUp_PageIndex  = 2
	XinShouNew_LevelUp_Client_Button02:Disable();
	XinShouNew_LevelUp_Client_Button01:Enable();
	XinShouNew_LevelUp_FlushWindow(1);
end

--===============================================
-- 升级有好礼 -end
--===============================================
--===============================================
-- 2023新升级有好礼-begin
--===============================================

--**********************************
-- 更新Data
--**********************************
function XinShouNew_LevelUp2_OnShow(ShowTime)
	XinShouNew_LevelUp2_UpdateButtonReq();
	XinShouNew_LevelUp2_FlushWindow(ShowTime)		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end

--**********************************
-- 请求更新Btn状态
--**********************************
function XinShouNew_LevelUp2_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState_2023" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 998412 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()

end

--**********************************
-- 【新服欢乐月·升级送好礼】刷新界面
--**********************************
function XinShouNew_LevelUp2_FlushWindow(ShowTime)
		

	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_XinShouNew_LevelUp_LoadFirstTime_2023 == 1 then
			
		
		g_XinShouNew_LevelUp_List_2023:Clear()	
		
		for levelidx = 1,  g_XinShouNew_LevelUp_TotalEnum_2023 do

			local singleGift = g_XinShouNew_LevelUp_Gifts_2023[levelidx]
			if Player:GetData("Is2606S") == 1 then
				singleGift = g_XinShouNew_2606S_GiftInfo[2][levelidx]
			end
			if singleGift == nil then
			   break
			end
			
			local bar = g_XinShouNew_LevelUp_List_2023:AddChild("XinShouNew_LevelUp2_Frame3_Bk")
			if not bar then
			   
			end

			g_XinShouNew_LevelUp_List_Item_2023[levelidx] = bar	
			
			local normalBK = 0
			local consume1BK = 0
			local consume2BK = 0
			
			g_XinShouNew_LevelUp_List_Item_2023[levelidx]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1_Button1"):SetEvent("Clicked", string.format("XinShouNew_LevelUp2_Frame3_GetGift1(%d)", levelidx))
			g_XinShouNew_LevelUp_List_Item_2023[levelidx]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1"):SetEvent("Clicked", string.format("XinShouNew_LevelUp2_Frame3_GetGift2(%d)", levelidx))  
			g_XinShouNew_LevelUp_List_Item_2023[levelidx]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1"):SetEvent("Clicked", string.format("XinShouNew_LevelUp2_Frame3_GetGift3(%d)", levelidx))  

			
			local singleNormal = singleGift.Normal
			if singleNormal ~= nil then
				bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1"):Show()
				bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk_Text"):SetText(g_XinShouNew_LevelUp_ListItemText_2023[levelidx])
				normalBK = 1
				for j = 1, 3 do
					---local j = 1
					local	giftItemID	=	-1
					local	giftItemNum	=	0		
					if singleNormal[j] ~= nil then									
						giftItemID	=	singleNormal[j].GiftItemID
						giftItemNum	= 	singleNormal[j].num
						local theAction = DataPool:CreateBindActionItemForShow(giftItemID, giftItemNum)
						if theAction:GetID() ~= 0 then
							bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Normal[j]):SetActionItem(theAction:GetID());
							bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Normal[j]):Show();
							if singleNormal[j].new ~= nil and singleNormal[j].new == 1 then
								bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Normal[j]) : SetProperty("Image", g_XinShouNew_PrizeItemButtonIcon);
							else
								bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Normal[j]) : Hide()
							end
						end					
					else
						bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Normal[j]):Hide()  
						bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Normal[j]):Hide()
					end
				end
			else
				bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1"):Hide()
				normalBK = 0
			end
							
			local singleConsume1 = singleGift.Consume1
			if singleConsume1 ~= nil then
				bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2"):Show()
				local bk2Text = ScriptGlobal_Format("#{XSJNH_230209_13}",g_XinShouNew_LevelUp_GetGiftLevel_2023[levelidx].consume1)
				---bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Text1"):SetText(bk2Text)
				consume1BK = 1
				for j = 1, 2 do
					if singleConsume1[j] ~= nil then		
						giftItemID	=	singleConsume1[j].GiftItemID
						giftItemNum	= 	singleConsume1[j].num
						local theAction = DataPool:CreateBindActionItemForShow(giftItemID, giftItemNum)
						if theAction:GetID() ~= 0 then
							bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Consume1[j]):SetActionItem(theAction:GetID());
							bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Consume1[j]):Show();
							if singleConsume1[j].new ~= nil and singleConsume1[j].new == 1 then
								bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Consume1[j]) : SetProperty("Image", g_XinShouNew_PrizeItemButtonIcon);
							else
								bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Consume1[j]) : Hide()
							end
						end					
					else
						bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Consume1[j]):Hide()  
						bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Consume1[j]):Hide()  
					end	
				end
			else
				bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2"):Hide()
				consume1BK = 0				
			end
			
			local singleConsume2 = singleGift.Consume2
			if singleConsume2 ~= nil then
				bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2"):Show()
				local bk3Text = ScriptGlobal_Format("#{XSJNH_230209_13}",g_XinShouNew_LevelUp_GetGiftLevel_2023[levelidx].consume2)
				---bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Text1"):SetText(bk3Text)
				consume2BK = 1
				for j = 1, 2 do
					if singleConsume2[j] ~= nil then		
						giftItemID	=	singleConsume2[j].GiftItemID
						giftItemNum	= 	singleConsume2[j].num
						local theAction = DataPool:CreateBindActionItemForShow(giftItemID, giftItemNum)
						if theAction:GetID() ~= 0 then
							bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Consume2[j]):SetActionItem(theAction:GetID());
							bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Consume2[j]):Show();
							if singleConsume2[j].new ~= nil and singleConsume2[j].new == 1 then
								bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Consume2[j]) : SetProperty("Image", g_XinShouNew_PrizeItemButtonIcon);
							else
								bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Consume2[j]) : Hide()
							end
						end					
					else
						bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIcons_2023.Consume2[j]):Hide()  
						bar:GetSubItem(g_XinShouNew_LevelUp_GiftsIconsImages_2023.Consume2[j]):Hide()  
					end	
				end
			else
				bar:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3"):Hide()
				consume2BK = 0				
			end			
			
		end
		
		g_XinShouNew_LevelUp_LoadFirstTime_2023 = 0
	end

	local nLevel = g_PlayerLevel; --Player : GetLevel();

	local levelGrade = 1;

	for i = 1,table.getn(g_XinShouNew_LevelUp_GetGiftLevel_2023)  do
		if nLevel < g_XinShouNew_LevelUp_GetGiftLevel_2023[i].level then
			levelGrade = i
			break
		end
	end
	
	--PushDebugMessage("levelGrade = "..levelGrade.."  nLevel = "..nLevel)

	--获取活动起止时间
	local EndDate = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)

	local deEndYear = math.floor(EndDate/100000000)
	local deEndMon = math.mod(math.floor(EndDate/1000000),100)
	local deEndDay = math.mod(math.floor(EndDate/10000),100)
	local deEndHour = math.mod(math.floor(EndDate/100),100)

	--先设置所有可以领取的Button的状态为:"已领取"或者"未领取"
	for i = 1, levelGrade - 1 do

		if g_XinShouNew_LevelUpBtnState_2023[i].level == 1 then
			--设置按钮图片为已领取
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1_Button1") : SetProperty("DisabledImage","set:XSYNew2023 image:YLQ")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1_Button1") : Disable()
		else
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1_Button1") : Enable()
		end
		
		if g_XinShouNew_LevelUpBtnState_2023[i].consume1 == 1 then
			--设置按钮图片为已领取
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : SetProperty("DisabledImage","set:XSYNew2023 image:YLQ")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : Disable()
		else
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : Enable()
		end
		
		if g_XinShouNew_LevelUpBtnState_2023[i].consume2 == 1 then
			--设置按钮图片为已领取
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : SetProperty("DisabledImage","set:XSYNew2023 image:YLQ")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : Disable()
		else
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : Enable()
		end
		
	end
	
	for i = 1, levelGrade - 1 do
		if g_CurConsume < g_XinShouNew_LevelUp_GetGiftLevel_2023[i].consume1 or g_CurExch < g_XinShouNew_LevelUp_GetGiftLevel_2023[i].consume1 then
			--未达成
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : Disable()
		else
		--	g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : Enable()
		end
		
		if g_CurConsume < g_XinShouNew_LevelUp_GetGiftLevel_2023[i].consume2 or g_CurExch < g_XinShouNew_LevelUp_GetGiftLevel_2023[i].consume2 then
			--未达成
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : Disable()
		else
		--	g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : Enable()
		end
	end
	
	

	for i = levelGrade, table.getn(g_XinShouNew_LevelUp_List_Item_2023) do
			--设置未达成的Button
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk1_Button1") : Disable()
			
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk2_Button1") : Disable()

			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_XinShouNew_LevelUp_List_Item_2023[i]:GetSubItem("XinShouNew_LevelUp2_Frame3_Bk3_Button1") : Disable()
	end
	

	--设置额外需要隐藏的[按钮]和图标为不可见
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local extraHideIndexBegin = g_KajiTable_XSJNH[4][kajiType][1]
	local extraHideIndexEnd = g_KajiTable_XSJNH[4][kajiType][2]
	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	if nSpecKaJi89 == 1 or nSpecKaJi89 == 2 then
		extraHideIndexBegin = 12
		extraHideIndexEnd = 13
	end
	if  extraHideIndexBegin > 0 and extraHideIndexBegin <= extraHideIndexEnd then
		for i = extraHideIndexBegin, extraHideIndexEnd do
	--		g_XinShouNew_LevelUp_List_Item_2023[i] : Hide()
		end
	end

end
--********************************************************************
-- 按钮,客户端界面"领取奖励"按钮点击响应事件函数
--********************************************************************
function XinShouNew_LevelUp2_Frame3_GetGift1( nIndex )
	
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp_common" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998412 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end

function XinShouNew_LevelUp2_Frame3_GetGift2( nIndex )
	
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp_ljxf1" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998412 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end

function XinShouNew_LevelUp2_Frame3_GetGift3( nIndex )
	
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp_ljxf2" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998412 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end

--===============================================
-- 升级有好礼 -end
--===============================================

--===============================================
-- 英雄百宝囊-begin
--===============================================

function XinShouNew_BaiBao_OnShow( ShowTime )
	XinShouNew_BaiBao_UpdateButtonReq();						-- 在服务器数据返回之前,先根据默认初始值刷新一次界面
	XinShouNew_BaiBao_FlushWindow(ShowTime)						
end

--**********************************
-- 请求更新Btn状态
--**********************************
function XinShouNew_BaiBao_UpdateButtonReq() 
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateInfo" ); 				-- 脚本号
		Set_XSCRIPT_ScriptID( 892685 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()

end

--function XinShouNew_BaiBao_UpdateRedPoint( ShowTime )
--
--	local redshow = 0
--	for i = 1,table.getn(g_XinShouNew_BaiBaoBtnState)  do
--		if g_XinShouNew_BaiBaoBtnState[i] == 0 then
--			redshow = 1
--			break
--		end
--	end
--	if redshow == 1 then   
--		XinShouNew_ShowButtonTips(8,1)
--	else
--		XinShouNew_ShowButtonTips(8,0)
--	end  
--end

--**********************************
-- 更新Btn状态
--**********************************
function XinShouNew_BaiBao_FlushWindow( ShowTime )  
 if g_XinShouNew_BaiBao_LoadFirstTime == 1 then 
  	--将物品奖励加载到页面显示
  	for i = 1,  table.getn(g_XinShouNew_BaiBao_GiftsIcons) do
  		for j = 1, table.getn(g_XinShouNew_BaiBao_GiftsIcons[i]) do
  			local	GiftItemID	=	-1
  			local	GiftItemNum	=	0
  			if j > table.getn( g_XinShouNew_BaiBao_Gifts[i] ) then
  				g_XinShouNew_BaiBao_GiftsIcons[i][j]:Hide(); 
  			else
  				GiftItemID	=	g_XinShouNew_BaiBao_Gifts[i][j].GiftItemID
  				GiftItemNum	= 	g_XinShouNew_BaiBao_Gifts[i][j].num
  				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
  				if theAction:GetID() ~= 0 then
  					--if g_XinShouNew_BaiBao_Gifts[i][j].new ~= nil and g_XinShouNew_BaiBao_Gifts[i][j].new == 1 then
  					--	g_XinShouNew_BaiBao_GiftsIconImages[i][j] : SetProperty("Image",g_XinShouNew_PrizeItemButtonIcon);
  					--end
  					g_XinShouNew_BaiBao_GiftsIcons[i][j]:SetActionItem(theAction:GetID());
  					g_XinShouNew_BaiBao_GiftsIcons[i][j]:Show(); 
  				end
  			end
  		end
  	end
  	--设置领取的按钮全都为不可用
  	for i = 1, 6 do
  		g_XinShouNew_BaiBao_GetGiftsButtonList[i] : Disable()
  		g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI4 image:XinShouYueUI_GM_Normal") 
  	end
  	g_XinShouNew_BaiBao_LoadFirstTime = 0
  	
  	--XinShouNew_ShowButtonTips(8,0)
 end

---设置界面上显示的活动起止时间
  
  --获取活动起止时间  
  local EndDate = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)
    
  local deEndYear = math.floor(EndDate/100000000)
	local deEndMon = math.mod(math.floor(EndDate/1000000),100)
	local deEndDay = math.mod(math.floor(EndDate/10000),100)  
	local deEndHour = math.mod(math.floor(EndDate/100),100)  
	--设置公告
 	local InfoText = ScriptGlobal_Format("#{XSJNH_180111_138}",deEndYear,deEndMon,deEndDay,deEndHour)	
	XinShouNew_BaiBao_Info:SetText( InfoText )
	--通过级别 设置条件 
	local nLevel = g_PlayerLevel; --Player : GetLevel();
	local LevelGrade = 0;
	for i = 1,table.getn(g_XinShouNew_BaiBao_GetGiftsCondition)  do
		if nLevel < g_XinShouNew_BaiBao_GetGiftsCondition[i].Level then
			g_XinShouNew_BaiBao_NotifyTipsControlList[i].LevelText:SetText( ScriptGlobal_Format("#{XSJNH_180111_139}", g_XinShouNew_BaiBao_GetGiftsCondition[i].Level ))
			g_XinShouNew_BaiBao_NotifyTipsControlList[i].YBText:SetText(ScriptGlobal_Format("#{XSJNH_180111_140}", g_XinShouNew_BaiBao_GetGiftsCondition[i].Cost , g_XinShouNew_BaiBao_GetGiftsCondition[i].PriCost  ) )
			if i <= table.getn(g_XinShouNew_BaiBao_GetGiftsButtonList) then	--未达成
				g_XinShouNew_BaiBao_GetGiftsButtonList[i] : Disable()
				g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI2 image:ServerNewUI_LQ_WDC") 
    	  g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetToolTip(ScriptGlobal_Format("#{XSJNH_180111_143}", g_XinShouNew_BaiBao_GetGiftsCondition[i].Level ))	
			end
		else
			g_XinShouNew_BaiBao_NotifyTipsControlList[i].LevelText:SetText( ScriptGlobal_Format("#{XSJNH_180111_141}", g_XinShouNew_BaiBao_GetGiftsCondition[i].Level ))
			g_XinShouNew_BaiBao_NotifyTipsControlList[i].YBText:SetText(ScriptGlobal_Format("#{XSJNH_180111_142}", g_XinShouNew_BaiBao_GetGiftsCondition[i].Cost , g_XinShouNew_BaiBao_GetGiftsCondition[i].PriCost  ) )
			if i <= table.getn(g_XinShouNew_BaiBao_GetGiftsButtonList) and  g_XinShouNew_BaiBaoBtnState[i] == 0 then		--可以购买
				g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI4 image:XinShouYueUI_GM_Normal") 
    		g_XinShouNew_BaiBao_GetGiftsButtonList[i] : Enable()  
    		g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetToolTip(ScriptGlobal_Format("#{XSJNH_180111_144}", g_XinShouNew_BaiBao_GetGiftsCondition[i].Cost ))		 
			end
			if i <= table.getn(g_XinShouNew_BaiBao_GetGiftsButtonList) and  g_XinShouNew_BaiBaoBtnState[i] == 1 then		--已购买
				g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI4 image:XinShouYueUI_GM_Disable")  	 
    	  g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetToolTip("#{XSJNH_180111_145}")		
    		g_XinShouNew_BaiBao_GetGiftsButtonList[i] : Disable()
			end
		end
	end
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local maxShowIndex = g_KajiTable_XSJNH[5][kajiType]
	for i=1,table.getn(g_XinShouNew_BaiBao_Bk) do
		if i <= maxShowIndex then
			g_XinShouNew_BaiBao_Bk[i]:Show()
		else
			g_XinShouNew_BaiBao_Bk[i]:Hide()
		end
	end
	
--先设置所有Button的状态为:"已购买"或者"购买""
   -- for i = 1, table.getn(g_XinShouNew_BaiBao_GetGiftsButtonList) do  
   -- 	if g_XinShouNew_BaiBaoBtnState[i] == 0 then		--状态为【购买】   
	 --		  g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI4 image:XinShouYueUI_GM_Normal") 
   -- 		g_XinShouNew_BaiBao_GetGiftsButtonList[i] : Enable()  
   -- 	elseif g_XinShouNew_BaiBaoBtnState[i] == 1 then	--状态为【已购买】   
   -- 	  g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetProperty("DisabledImage","set:ServerNewUI4 image:XinShouYueUI_GM_Disable") 
   -- 	  g_XinShouNew_BaiBao_GetGiftsButtonList[i] : SetToolTip("#{XSJNH_180111_159}")		
   -- 		g_XinShouNew_BaiBao_GetGiftsButtonList[i] : Disable()
   -- 	end
   -- end
      
  -- 更新小红点
  --XinShouNew_BaiBao_UpdateRedPoint(ShowTime)
end

--********************************************************************
-- 按钮,客户端界面"领取奖励"按钮点击响应事件函数
--********************************************************************
function XinShouNew_BaiBao_Frame3_GetGift( nIndex )
	
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--1.检测玩家的等级是否到达可领奖的等级
	local nLevel = Player : GetLevel()
	if nLevel < g_XinShouNew_BaiBao_GetGiftsCondition[nIndex].Level then
		PushDebugMessage("#{SJSHL_140919_24}")					--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end
	--2.玩家是否未领取该奖励
	if nIndex < 1 or nIndex > 6 then
		return
	elseif g_XinShouNew_BaiBaoBtnState[nIndex] == 1 then					--按钮为"未点亮"状态,说明根据MF判断玩家已经领取过该两例
		PushDebugMessage("#{SJSHL_140919_25}")					--对不起,您已经领取过此奖励,无法再次领取
		return
	end
	--3.判断玩家背包位置数是否足够
--	local nBegin = -1;
	--for i = 1, table.getn( XinShouNew_LevelUpBtnState ) do
		--if ( XinShouNew_LevelUpBtnState[ i ] == 0 ) then
		--	nBegin = i
		--	break
		--end
	--end
	
	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForHeroBag" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892685 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT() 
end

--英雄百宝囊end

--===============================================
-- 英雄百宝囊 -end
--===============================================


--===============================================
-- 江湖幸运星-begin
--===============================================

--江湖幸运星begin
function XinShouNew_LuckyDraw_Show( ShowTime )
	XinShouNew_LuckyDraw_UpdateInfo();
 	XinShouNew_LuckyDraw_FlushWindow(ShowTime);
end
--**********************************
-- 请求更新Btn状态
--**********************************
function XinShouNew_LuckyDraw_UpdateInfo() 
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateLuckyInfo" ); 				-- 脚本号
		Set_XSCRIPT_ScriptID( 892686 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT() 
end

--function XinShouNew_LuckyDraw_UpdateRedPoint(ShowTime)
--	if g_LuckyDrawCount < g_LuckyDrawTotalCount and  g_LuckyDrawCount >= 0 and g_LuckyDrawRemainTime == 0 then   
--		XinShouNew_ShowButtonTips(9,1)
--	else
--		XinShouNew_ShowButtonTips(9,0)
--	end  
--end

function XinShouNew_LuckyDraw_FlushWindow( ShowTime ) 
		
	if g_XinShouNew_LuckyDraw_LoadFirstTime == 1 then
	  --将物品奖励加载到页面显示
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local tableXinShouNew_LuckyDraw_Gifts = g_KajiTable_XSJNH[6][kajiType]  
	
  	for i = 1,  table.getn(g_XinShouNew_LuckyDraw_GiftsIcons) do
  		for j = 1, table.getn(g_XinShouNew_LuckyDraw_GiftsIcons[i]) do
  			local	GiftItemID	=	-1
  			local	GiftItemNum	=	0
  			if j > table.getn( tableXinShouNew_LuckyDraw_Gifts[i] ) then
  				g_XinShouNew_LuckyDraw_GiftsIcons[i][j]:Hide();
  			else
  				GiftItemID	=	tableXinShouNew_LuckyDraw_Gifts[i][j].GiftItemID
  				GiftItemNum	= 	tableXinShouNew_LuckyDraw_Gifts[i][j].num
  				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
  				if theAction:GetID() ~= 0 then
  					--if g_XinShouNew_BaiBao_Gifts[i][j].new ~= nil and g_XinShouNew_BaiBao_Gifts[i][j].new == 1 then
  					--	g_XinShouNew_BaiBao_GiftsIconImages[i][j] : SetProperty("Image",g_XinShouNew_PrizeItemButtonIcon);
  					--end
  					g_XinShouNew_LuckyDraw_GiftsIcons[i][j]:SetActionItem(theAction:GetID());
  					g_XinShouNew_LuckyDraw_GiftsIcons[i][j]:Show();
  				end
  			end
  		end
  	end 
  	g_XinShouNew_LuckyDraw_LoadFirstTime = 0
  end
  
  
	--江湖幸运星时间 
	local eEndTime = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)
	local deEndYear= math.floor(eEndTime/100000000)
	local deEndMon = math.mod(math.floor(eEndTime/1000000),100)
	local deEndDay = math.mod(math.floor(eEndTime/10000),100) 
	local deEndHour = math.mod(math.floor(eEndTime/100),100)  
	
  --设置公告
	local dexpText = ScriptGlobal_Format("#{XSJNH_180111_154}", deEndYear,deEndMon,deEndDay,deEndHour)  
	XinShouNew_LuckStar_Info:SetText(dexpText) 
	
	--设置时间控件 
	XinShouNew_LuckStar_Time_Watch:SetProperty("Timer",tostring(g_LuckyDrawRemainTime) ); 
	XinShouNew_LuckStar_Time_Watch:Show();
	--设置次数文字
	XinShouNew_LuckStar_Numbertext:SetText( ScriptGlobal_Format("#{XSJNH_180111_158}", g_LuckyDrawCount) )
	
	--判断是否是抽奖之后 如果是 则播放特效
	if g_LuckyDrawIndex > 0 and g_LuckyDrawIndex <= table.getn(g_XinShouNew_LuckyDraw_GiftLightImage) then
		SetTimer("XinShouNew","XinShouNew_LuckyDraw_Tick()", g_XinShouNew_LuckyDraw_TimerLength )
		g_XinShouNew_LuckyDraw_GiftLightImage[g_LuckyDrawIndex]:PlayWarning( 1 )
	end
	-- 不同的情况 显示不同的倒计时字典
	--倒计时没结束时 显示倒计时
	if g_LuckyDrawRemainTime > 0 then
		XinShouNew_LuckStar_Time:SetText( "#{XSJNH_180111_155}" )   --#G距离下一次抽奖时间：
	end 
	--倒计时结束 
	if g_LuckyDrawRemainTime == 0 then
		XinShouNew_LuckStar_Time:SetText( "#{XSJNH_180111_156}" )   --距离下一次抽奖时间：00：00：00
	end
	
	if g_LuckyDrawCount >= g_LuckyDrawTotalCount then
		XinShouNew_LuckStar_Time:SetText( "#{XSJNH_180111_157}" )   --距离下一次抽奖时间：今日抽奖次数已用完//金色
	end 
	
	
	XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("DisabledImage","set:ServerNewUI4 image:XinShouYueUI_CJ_Disable")  
	XinShouNew_LuckStar_Frame3_Bk1_Button1 : Disable();
	
	-- 如果有剩余次数 倒计时结束 则Button 可用
	if g_LuckyDrawCount < g_LuckyDrawTotalCount and  g_LuckyDrawCount >= 0 and g_LuckyDrawRemainTime == 0 then   
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("NormalImage","set:XSHLY03 image:XSHLY_CJ_Normal")
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("PushedImage","set:XSHLY03 image:XSHLY_CJ_Pushed")   
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("HoverImage","set:XSHLY03 image:XSHLY_CJ_Hover")        
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : Enable(); 
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : PlayWarning( 0 )
  		XinShouNew_LuckStar_Frame3_Bk1_Button1 : PlayWarning( 1 )
	end  
	
	-- 如果有剩余次数 倒计时未结束 则Button Disable 添加tips
	if g_LuckyDrawCount < g_LuckyDrawTotalCount and  g_LuckyDrawCount >= 0 and g_LuckyDrawRemainTime > 0 then  
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("NormalImage","set:XSHLY03 image:XSHLY_CJ_Disabled")
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("PushedImage","set:XSHLY03 image:XSHLY_CJ_Disabled")   
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("HoverImage","set:XSHLY03 image:XSHLY_CJ_Disabled")  
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : Enable(); 
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetToolTip("#{XSJNH_180111_159}")	
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : PlayWarning( 0 )	
	end  
	
	-- 如果抽奖次数用完 添加用完tips
	if g_LuckyDrawCount >= g_LuckyDrawTotalCount then   
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("NormalImage","set:XSHLY03 image:XSHLY_CJ_Disabled")
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("PushedImage","set:XSHLY03 image:XSHLY_CJ_Disabled")   
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("HoverImage","set:XSHLY03 image:XSHLY_CJ_Disabled")  
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : Enable();
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetToolTip("#{XSJNH_180111_160}")	
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : PlayWarning( 0 )	
	end  	
		
	-- 更新小红点
	--XinShouNew_LuckyDraw_UpdateRedPoint(ShowTime)
end

function XinShouNew_LuckyDraw_Frame3_GetGift( )
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--1.检测玩家的等级是否到达可领奖的等级 
	
	--2.玩家是否未领取该奖励
	if g_LuckyDrawCount >= g_LuckyDrawTotalCount and  g_LuckyDrawCount < 0 then
		PushDebugMessage("#{XSHLY_150522_32}")					--对不起,您已经领取过此奖励,无法再次领取
		return 
	end
	--3.判断玩家背包位置数是否足够
--	local nBegin = -1;
	--for i = 1, table.getn( XinShouNew_LevelUpBtnState ) do
		--if ( XinShouNew_LevelUpBtnState[ i ] == 0 ) then
		--	nBegin = i
		--	break
		--end
	--end 
	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLuckyDraw" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892686 );				-- 脚本编号 
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
-- 5秒的特效
function XinShouNew_LuckyDraw_Tick()
	if g_XinShouNew_LuckyDraw_GiftLightImage[g_LuckyDrawIndex] ~= nil then
		g_XinShouNew_LuckyDraw_GiftLightImage[g_LuckyDrawIndex]:PlayWarning( 0 )
	end
	KillTimer("XinShouNew_LuckyDraw_Tick()")
	g_LuckyDrawIndex = 0
end

-- 时间到达
function XinShouNew_LuckStar_TimeReach()
	--XinShouNew_LuckStar_Time_Watch:SetProperty("Timer","0") 
	XinShouNew_LuckStar_Time:SetText( "#{XSJNH_180111_156}" )   --距离下一次抽奖时间：00：00：00
	-- 如果有剩余次数 倒计时结束 则Button 可用
	if g_LuckyDrawCount < g_LuckyDrawTotalCount and  g_LuckyDrawCount >= 0  then   
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("NormalImage","set:XSHLY03 image:XSHLY_CJ_Normal")
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("PushedImage","set:XSHLY03 image:XSHLY_CJ_Pushed")   
			XinShouNew_LuckStar_Frame3_Bk1_Button1 : SetProperty("HoverImage","set:XSHLY03 image:XSHLY_CJ_Hover")        
		  XinShouNew_LuckStar_Frame3_Bk1_Button1 : Enable(); 
	end  
	XinShouNew_LuckStar_Frame3_Bk1_Button1:PlayWarning( 0 )
  XinShouNew_LuckStar_Frame3_Bk1_Button1:PlayWarning( 1 )
	--this:Hide()
end
--江湖幸运星end

--===============================================
-- 江湖幸运星 -end
--===============================================

--===============================================
-- 社交达人汇-begin
--===============================================



--===============================================
-- 社交达人汇 -end
--===============================================


--===============================================
-- 天龙豪侠路-begin
--===============================================

--点击按钮豪侠路分页，向服务器请求打开
function  XinShouNew_Heroes_Road_Ask()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AskHeroesRoadInfo");
		Set_XSCRIPT_ScriptID(892677);
		Set_XSCRIPT_Parameter(0,0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();

end

--豪侠路七天分页切换，服务器返回，刷新界面
function XinShouNew_Heroes_Road_OnSwitchPage(nIndex,nValue,nDayGap,uitype)

	local idx = nIndex-1
	g_nContentButton = {}
	if idx<0 or idx >6 then
		return
	end
	Lua_SortHaoXia()
	XinShouNew_Heroes_RoadList:CleanAllElement("XinShouNew")

	local Num = Lua_GetMaiDianNumByDay(idx)
	for i = 0,Num-1 do
		local MaiDianValue = 0

		local BounsFlag = 0
		local nChangeIndex = Lua_GetHaoXiaIndex(idx,i)
		local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
		BounsFlag = DataPool:Lua_GetHaoXiaRoadFlag(idx,nChangeIndex)
		local Desc,TargetNum,BounsNum,Isspecial,Image1,Image2,nType,param0,param1,param2 = Lua_GetXinShouHeroesRoadInfo(idx,nChangeIndex)
		if idx == 6 and nChangeIndex == 9 and uitype == 1 then
			--donothing
		else
			if idx == 6 and nChangeIndex == 0 and (nSpecKaJi89 == 1 or nSpecKaJi89 == 2) then
				Desc = "#{BJKJ_220701_18}"
				TargetNum = 89 
			end
			local ItemBar = XinShouNew_Heroes_RoadList:AddItemElement( "HeroesRoadButton", "LEFT", "XinShouNew","" ,"")
			ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")

			if Isspecial == 0 then
				MaiDianValue = DataPool:Lua_GetHaoXiaRoad(idx,nChangeIndex)
			--	MaiDianValue = 1
			--	ItemBar:SetText1("#G"..Desc.."\n当前进度"..MaiDianValue.."/"..TargetNum )
			elseif Isspecial == 1 then
				MaiDianValue = Player:GetData("EQUIPSCOREHH");
			--	ItemBar:SetText1("#G"..Desc.."\n当前进度"..MaiDianValue.."/"..TargetNum )
			end
			if MaiDianValue >= TargetNum then
				ItemBar:SetText1("#G"..Desc)
				ItemBar:SetText2("#G".."当前进度"..TargetNum.."/"..TargetNum)
				ItemBar:SetText3( "#G".."完成获得豪侠值:"..BounsNum )
			else
				ItemBar:SetText1(Desc)
				ItemBar:SetText2("当前进度"..MaiDianValue.."/"..TargetNum)
				ItemBar:SetText3("完成获得豪侠值:"..BounsNum )
			end
		--	ItemBar:SetText1()
		--	ItemBar:SetText3( "#G".."完成获得豪侠值:"..BounsNum )

		--	ItemBar:SetButton1Show();
		--	ItemBar:SetButton2Show();

			if MaiDianValue < TargetNum then
				ItemBar:SetButton1Show()
				ItemBar:SetButton1Text("前往")
				ItemBar:SetImage2Hide()
			elseif BounsFlag == 0 then
				ItemBar:SetButton1Show()
				ItemBar:SetButton1Text( "#G".."领取")
				ItemBar:SetImage2Hide()
			elseif BounsFlag == 1 then
				ItemBar:SetButton1Hide();
				ItemBar:SetImage2Show()
			end

			ItemBar:SetImage1( Image1, Image2 )
			--ItemBar:SetImage1Hide()
			ItemBar:SetImage1Show()

			table.insert(g_nContentButton,ItemBar);
		end
	end

--	XinShouNew_Heroes_Road_Huoyue:SetProgress(tonumber(nValue) , 150)
--	local strMsg = ScriptGlobal_Format( "#{HDRCYH_130118_03}", nValue)
--	XinShouNew_Heroes_Road_Huoyue:SetToolTip(strMsg)
	
	local theAction
	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	-- if nSpecKaJi89 ~= 0 then
	-- 	theAction = DataPool:CreateActionItemForShow(38006013, 1)
	-- else
		theAction = DataPool:CreateActionItemForShow(g_XinShouNew_Heroes_ItemBounsId, 1)
	-- end 
	
	
		

	local strMsg = ScriptGlobal_Format( "#{XSJNH_180120_242}", nValue)
	if uitype == 1 then
		strMsg = ScriptGlobal_Format( "#{XSJNH_230209_76}", nValue)
		theAction = DataPool:CreateActionItemForShow(39921377, 1)
	end

	XinShouNew_Heroes_Road_Icon1 : SetActionItem(theAction:GetID())

	XinShouNew_Heroes_Road_Detailtips_text:SetText(strMsg)

	XinShouNew_Heroes_RoadList:Flash()

	g_XinShouNew_Heroes_Road_LastClickedId = nIndex


	for i = 1,  table.getn(g_XinShouNew_Heroes_Road_Button) do
		if i == g_XinShouNew_Heroes_Road_LastClickedId then
			g_XinShouNew_Heroes_Road_Button[i]:SetCheck(1)
			g_XinShouNew_Heroes_Road_Button[i]:SetText(g_XinShouNew_Heroes_ButtonTextSelected[i])
		else
			g_XinShouNew_Heroes_Road_Button[i]:SetCheck(0)
			g_XinShouNew_Heroes_Road_Button[i]:SetText(g_XinShouNew_Heroes_ButtonText[i])
		end
	end


--	if nDayGap > 0 then
--		for i = 1,  table.getn(g_XinShouNew_Heroes_Road_Button_lock) do
--			if i <= nDayGap then
--				g_XinShouNew_Heroes_Road_Button_lock[i]:Hide()
--		end
--		end
--	end

		--豪侠路时间
	local eEndTime = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)
	local deEndYear= math.floor(eEndTime/100000000)
	local deEndMon = math.mod(math.floor(eEndTime/1000000),100)
	local deEndDay = math.mod(math.floor(eEndTime/10000),100)
	local deEndHour = math.mod(math.floor(eEndTime/100),100)

  --设置公告
	local dexpText = ScriptGlobal_Format("#{XSJNH_180112_235}", deEndYear,deEndMon,deEndDay,deEndHour)
	XinShouNew_Heroes_Road_Des1:SetText(dexpText)

--	PushDebugMessage("n="..i)
--		if n==g_XinShouNew_Heroes_Road_LastClickedId then
--			PushDebugMessage(g_XinShouNew_Heroes_Road_Button[i].."1")
--		--	g_XinShouNew_Heroes_Road_Button[i]:SetCheck(1)
--		else
--			PushDebugMessage(g_XinShouNew_Heroes_Road_Button[i].."0")
--		--	g_XinShouNew_Heroes_Road_Button[i]:SetCheck(0)
--		end
--	end
	--XinShouNew_OnCheckMe()
	XinShouNew_OnCheckRed(nDayGap)
end

--点击豪侠路七天分页切换
function XinShouNew_Heroes_Road_Page_Clicked(nPage)
	if nPage <1 or nPage > 7 then
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AskHeroesRoadInfo");
		Set_XSCRIPT_ScriptID(892677);
		Set_XSCRIPT_Parameter(0,nPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end

--点击豪侠路条目
function XinShouNew_Heroes_Road_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos+1, -1))
	nIndex = nIndex+1
	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function XinShouNew_Heroes_Road_OnButton2Click()
end

function XinShouNew_Heroes_Road_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	local nDay =g_XinShouNew_Heroes_Road_LastClickedId-1
	local nChangeIndex = Lua_GetHaoXiaIndex(nDay,nIndex)
	local BounsFlag = DataPool:Lua_GetHaoXiaRoadFlag(nDay,nChangeIndex)

	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	local Desc,TargetNum,BounsNum,Isspecial,Image1,Image2,nType,param0,param1,param2 = Lua_GetXinShouHeroesRoadInfo(nDay,nChangeIndex)
	if nDay == 6 and nChangeIndex == 0 and (nSpecKaJi89 == 1 or nSpecKaJi89 == 2) then
		Desc = "#{BJKJ_220701_18}"
		TargetNum = 89 
	end
	local MaiDianValue = 0
	if Isspecial == 0 then
		MaiDianValue = DataPool:Lua_GetHaoXiaRoad(nDay,nChangeIndex)
	--	MaiDianValue = 1
	elseif Isspecial == 1 then
		MaiDianValue = Player:GetData("EQUIPSCOREHH");
	end

	if MaiDianValue < TargetNum then
		XinShouNew_Heroes_Road_GoTo(nDay,nChangeIndex,nType,param0,param1,param2)
	elseif BounsFlag == 0 then
		XinShouNew_Heroes_Road_GetBounsValue(nDay,nIndex)
		g_lastMaiDian = nChangeIndex
		g_lastDay = nDay
	end
	
	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			g_nContentButton[nButtonIndex]:SetButton1Normal()
		end
	end

end

function XinShouNew_Heroes_Road_GoTo(nDay,nIndex,nType,param0,param1,param2)
	--打开界面
	if nType == 1 then
		XinShouNew_Heroes_Road_GoTo_OpenUI(nDay,nIndex,nType,param0,param1,param2)
	--固定场景坐标的自动寻路
	elseif nType == 2 then
		AutoRunToTargetEx(param1,param2,param0)

	--特殊自动寻路1,按等级区分不同的寻路目标
	elseif nType ==  3 then
		if  Player:GetLevel() < 65  then
			AutoRunToTargetEx(65,92,202)
		else
			AutoRunToTargetEx(281,81,7)
		end
		--特殊自动寻路1,按门派区分不同的寻路目标
	elseif nType ==  4 then
		local menpai = Player : GetData( "MEMPAI" );		--获取玩家门派ID
		if ( menpai < 0 or menpai > 15 ) then--menpai15
			return
		end
		if(0 == menpai) then
	--		strName = "少林";
			AutoRunToTargetEx(91.7971,71.3921,9)
		elseif(1 == menpai) then
	--		strName = "明教";
			AutoRunToTargetEx(109.1598,59.3804,11)
		elseif(2 == menpai) then
	--		strName = "丐帮";
			AutoRunToTargetEx(94.1281,99.142,10)
		elseif(3 == menpai) then
	--		strName = "武当";
			AutoRunToTargetEx(82.8534,84.9902,12)
		elseif(4 == menpai) then
	--		strName = "峨嵋";
			AutoRunToTargetEx(98.105,51.7009,15)
		elseif(5 == menpai) then
	--		strName = "星宿";
			AutoRunToTargetEx(87.068,70.1534,16)
		elseif(6 == menpai) then
	--		strName = "天龙";
			AutoRunToTargetEx(97.9375,67.0415,13)
		elseif(7 == menpai) then
	--		strName = "天山";
			AutoRunToTargetEx(88.6175,44.5456,17)
		elseif(8 == menpai) then
	--		strName = "逍遥";
			AutoRunToTargetEx(125.1805,142.0748,14)
		elseif(9 == menpai) then
	--		strName = "无门派";
				PushDebugMessage("#{XY_0110_67}")
		elseif(10== menpai) then
	--		strName = "慕容";
			AutoRunToTargetEx(48,134.5865,284)
		elseif(11== menpai) then
	--		strName = "唐门";
			AutoRunToTargetEx(38.4,75.2,615)
		elseif(12== menpai) then
	--		strName = "鬼谷";		
			AutoRunToTargetEx(92,55,678)
		elseif(13== menpai) then
			AutoRunToTargetEx(188,79,731) --桃花岛
		elseif(14== menpai) then
			AutoRunToTargetEx(245,190,824) --从刃
		elseif(15== menpai) then
			AutoRunToTargetEx(179.8,120.8,987) --menpai15 恶人谷武功传授人附近
		end

	end
end
-- 打开精彩活动--全天活动
function XinShouNew_Heroes_Road_OpenJCHD()
		-- 动态提示
	if IsInTServer() == 1 then
--		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	local nLevel = Player:GetLevel();	
	if ( nLevel < 10 ) then		
		PushDebugMessage("#{XSJNH_180112_236}")		
		return	
	end		-- 打开UI
	OpenTodayCampaignList();
	PushEvent("UI_COMMAND",2018012302)
end
-- 打开精彩活动--默认
function XinShouNew_Heroes_Road_OpenJCHD_Default()
		-- 动态提示
	if IsInTServer() == 1 then
--		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	local nLevel = Player:GetLevel();	
	if ( nLevel < 10 ) then		
		PushDebugMessage("#{XSJNH_180112_236}")		
		return	
	end		-- 打开UI
	OpenTodayCampaignList();

end
--打开武林风云录
function XinShouNew_Heroes_Road_OpenWLFYL(nIndex)
		-- 打开UI
	local menpai = Player : GetData( "MEMPAI" );		--获取玩家门派ID
	if ( menpai < 0 or menpai > 15 or menpai == 9 ) then--menpai15
		PushDebugMessage( "#{JDZY_120806_875}" );
		return
	end
		-- 等级	
		local nLevel = Player:GetLevel();	
		if ( nLevel < 30 ) then		
			PushDebugMessage("#{XSJNH_180112_236}")		
			return	
		end	
	Lua_ToggleFengyunlu();
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnClientBnClicked" );	-- 脚本入口
		Set_XSCRIPT_ScriptID( 290099 )						-- 脚本ID
		Set_XSCRIPT_ParamCount( 0 )							-- 参数个数
	Send_XSCRIPT()
	PushEvent("UI_COMMAND",2018012303,nIndex)
end
--打开门派技能
function XinShouNew_Heroes_Road_OpenMPJN()
		-- 打开UI	
		local menpai = Player : GetData( "MEMPAI" );		
		--获取玩家门派ID	
		if ( menpai < 0 or menpai > 15 or menpai == 9 ) then--menpai15
			PushDebugMessage( "你还没有拜入门派。" );		
			return	
		end	
		DataPool:Lua_SetLastSkill_UI(2)
	ToggleSkillBook();

	local LastSKilltap = GetLastSkill_UI()
	local nProcess = DataPool:GetCurrentFreshManGuideItemValue();
	if nProcess ==22  then
		if LastSKilltap == 1 then
			NotifyPopUITip("CommonSkill", -1, 1)
		elseif LastSKilltap == 2 then
			PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",8)
		end
		DataPool:SetCurrentFreshManGuideItemValue(0);
	end
end

function XinShouNew_Heroes_Road_OpenMZTH()
		local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	local curDay = tonumber(DataPool:GetServerDayTime()); 
end
--打开装备评分提升指引界面
function XinShouNew_Heroes_Road_OpenFightScore()
	if Player:GetLevel() >= 30 then
			PushEvent("OPEN_EQUIP_SCORE_CONDUCT")
	else
		PushDebugMessage("#{PFZY_140613_174}")
	end
end

function XinShouNew_Heroes_Road_GoTo_OpenUI(nDay,nIndex,nType,param0,param1,param2)
	--PushDebugMessage("g_PageNum="..g_PageNum)
	if param0 == 0 then --打开好友界面
		DataPool:OpenFriendList();
	elseif param0 == 1 then --打开任务界面
		ToggleMission();
	elseif param0 == 2 then --打开精彩活动界面 选中全天活动
		XinShouNew_Heroes_Road_OpenJCHD()
	elseif param0 == 3 then --打开武林风云录 选中该暗器页签
		XinShouNew_Heroes_Road_OpenWLFYL(1)
	elseif param0 == 4 then --新手嘉年华-首充界面
		XinShouNew_Project_Clicked(3)
	elseif param0 == 5 then  --打开武林风云录 选中宝石页签
		XinShouNew_Heroes_Road_OpenWLFYL(6)
	elseif param0 == 6 then --打开主界面 珍兽页
		TogglePetPage();
	elseif param0 == 7 then --打开精彩活动界面 选中全天活动
		XinShouNew_Heroes_Road_OpenJCHD()
	elseif param0 == 8 then -- 打开主界面-技能界面-门派技能分页
		XinShouNew_Heroes_Road_OpenMPJN()
	elseif param0 == 9 then -- 打开武林风云录 选中武魂
		XinShouNew_Heroes_Road_OpenWLFYL(11)
	elseif param0 == 10 then -- 打开精彩活动
		XinShouNew_Heroes_Road_OpenJCHD_Default()
	elseif param0 == 11 then --福利-每周特惠界面功能关闭 改为 天龙战令
		--XinShouNew_Heroes_Road_OpenMZTH()
		OpenZhanLing(0) 
	elseif param0 == 12 then --主界面-人物-神鼎
		OpenShenDingPage();
	elseif param0 == 13 then --打开精彩活动界面 选中全天活动
		XinShouNew_Heroes_Road_OpenJCHD()
	elseif param0 == 14 then -- 打开主界面-技能界面-门派技能分页
		XinShouNew_Heroes_Road_OpenMPJN()
	elseif param0 == 15 then -- 武林风云录，选中真元页签
		XinShouNew_Heroes_Road_OpenWLFYL(17)
	elseif param0 == 16 then -- 打开精彩活动
		XinShouNew_Heroes_Road_OpenJCHD_Default()
	elseif param0 == 17 then --打开装备评分提升指引界面
		XinShouNew_Heroes_Road_OpenFightScore()
	elseif param0 == 18 then --主界面-人物-神鼎
		OpenShenDingPage();
	elseif param0 == 19 then --打开装备评分提升指引界面
		XinShouNew_Heroes_Road_OpenFightScore()
	elseif param0 == 20 then -- 打开精彩活动
		XinShouNew_Heroes_Road_OpenJCHD()
	elseif param0 == 21 then -- 武林风云录，选中进阶页签
		XinShouNew_Heroes_Road_OpenWLFYL(25)
	elseif param0 == 22 then --打开装备评分提升指引界面
		XinShouNew_Heroes_Road_OpenFightScore()
	end

end

--领取豪侠值
function XinShouNew_Heroes_Road_GetBounsValue(nDay,nIndex)
	local nChangeIndex = Lua_GetHaoXiaIndex(nDay,nIndex)
	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	local Desc,TargetNum,BounsNum,Isspecial,Image1,Image2,nType,param0,param1,param2 = Lua_GetXinShouHeroesRoadInfo(nDay,nChangeIndex)
	if nDay == 6 and nChangeIndex == 0 and (nSpecKaJi89 == 1 or nSpecKaJi89 == 2) then 
		TargetNum = 89 
	end
	local MaiDianValue = 0
	if Isspecial == 0 then
		MaiDianValue = DataPool:Lua_GetHaoXiaRoad(nDay,nChangeIndex)
	--	MaiDianValue = 1
	elseif Isspecial == 1 then
		MaiDianValue = Player:GetData("EQUIPSCOREHH");
	end
	local BounsFlag = DataPool:Lua_GetHaoXiaRoadFlag(nDay,nChangeIndex)

	if MaiDianValue >= TargetNum then
		if BounsFlag == 0 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("GiveBounsValue")
				Set_XSCRIPT_ScriptID(892677)
				Set_XSCRIPT_Parameter(0,nDay)
				Set_XSCRIPT_Parameter(1,nChangeIndex)		--想要洗的属性
				Set_XSCRIPT_Parameter(2,g_XinShouNew_Heroes_Road_LastClickedId)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end
	end
end

--领奖
function XinShouNew_Heroes_Road_HuoYueHaoLiFunc()

	--打开领奖界面
	local g_IsOpenUI = 1
--	PushEvent("XINSHOUNEW_HEROERROAD_GETBOUNS_OPEN")
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AskHeroesRoadBounsUI");
		Set_XSCRIPT_ScriptID(892677);
		Set_XSCRIPT_Parameter(0,g_IsOpenUI)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();

end


--===============================================
-- 天龙豪侠路 -end
--===============================================


--===============================================
-- 天龙7日豪礼-begin
--===============================================

function XinShouNew_7Day_Show(nType)
	for i=1,7 do
		g_XinShouNew_7DayButtom[i].Done:Hide()
	end

	local nDate1= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1)
	local nDate2= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_2)

	local nTimes = math.mod(nDate1,10)

	for i=1,nTimes do
		g_XinShouNew_7DayButtom[i].Done:Hide()
	end

	local nDate = 1
	for i=1,nTimes do
		if math.mod(nDate2,10) == 1 then
			g_XinShouNew_7DayButtom[i].Done:Show()
		end
		nDate2 = math.floor(nDate2/10)
	end
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	if kajiType == 1 then
		--卡级服特写 上面一排最后一栏图标改成棉布
		XinShouNew_SevenDay_Top_day7_bk:SetProperty( "Image", "set:Ore image:Ore_14" )
	else
		XinShouNew_SevenDay_Top_day7_bk:SetProperty( "Image", "set:CircularTaskTool49 image:CircularTaskTool49_5" )		
	end
	
	if nType == 0 then
		XinShouNew_SevenDay_Click(nTimes)
	else
		XinShouNew_SevenDay_Click(g_XinShouNew_7DayPrize_Click)
	end
	
end

function XinShouNew_7Day_Update()
	XinShouNew_7Day_Show(1)
end

function XinShouNew_SevenDay_Click(nIndex)

	if nIndex<1 or nIndex>7 then
		return
	end
	local kajiType = KaJi:LuaFnGetKaJiType(10)


	
	XinShouNew_SevenDay_Right_imageDay:SetProperty( "Image", g_XinShouNew_7DayImage[nIndex][2] )

	if kajiType == 1 and nIndex == 7 then
		XinShouNew_SevenDay_Left_image:SetProperty( "Image", g_XinShouNew_7DayImage[6][1] )
		XinShouNew_SevenDay_Right_imageDayItem:SetProperty( "Image", g_XinShouNew_7DayImage[6][3] )
	else
		XinShouNew_SevenDay_Left_image:SetProperty( "Image", g_XinShouNew_7DayImage[nIndex][1] )
		XinShouNew_SevenDay_Right_imageDayItem:SetProperty( "Image", g_XinShouNew_7DayImage[nIndex][3] )
	end

	for i=1, 7 do
		g_XinShouNew_7DayButtom[i].Button:SetCheck(0)
	end

	g_XinShouNew_7DayPrize_Click = nIndex

	--显示一下奖励
	for i=1, 4 do
		g_XinShouNew_7DayPrize_Button[i]:SetActionItem( -1 );
	end

	local tableXinShouNew_7DayPrize = g_KajiTable_XSJNH[2][kajiType]
	local nCount = table.getn(tableXinShouNew_7DayPrize[nIndex])

	for i=1,nCount do
		local nItemID = tableXinShouNew_7DayPrize[nIndex][i].ItemID
		local nNum = tableXinShouNew_7DayPrize[nIndex][i].num
		DataPool:Lua_SetFaTieActionItem( i+4, nItemID, nNum );
	end

	DataPool:Lua_UpdateFaTieActionItem();

	for i=1,nCount do
		local theAction = EnumAction( i+4, "FaTie_item");
		if theAction:GetID() ~= 0 then
			g_XinShouNew_7DayPrize_Button[i]:SetActionItem( theAction:GetID() );
		else
			g_XinShouNew_7DayPrize_Button[i]:SetActionItem( -1 );
		end
	end

	g_XinShouNew_7DayButtom[nIndex].Button:SetCheck(1)


	--看一下这页是不是可以打开
	local nDate1= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1)
	local nTimes = math.mod(nDate1,10)
	if nIndex > nTimes then
		--第X日可领取
		XinShouNew_SevenDay_Right_Button1:Disable()
		XinShouNew_SevenDay_Right_Button1: SetProperty("DisabledImage",g_XinShouNew_7DayImage[nIndex][4])
	else
		--看是不是已经领取了
		local nData2 = DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_2)
		local nBase = 1
		for i=1,nIndex-1 do
			nBase = nBase * 10
		end
		local nFlag = math.mod(math.floor(nData2/nBase),10)
		if nFlag == 0 then
		--未领取
			XinShouNew_SevenDay_Right_Button1:Enable()
		elseif nFlag == 1 then
		--已领取
			XinShouNew_SevenDay_Right_Button1:Disable()
			XinShouNew_SevenDay_Right_Button1: SetProperty("DisabledImage","set:XSYNew02 image:XinShouNew_Time_DisabledYLQ")
		end
	end


end

function XinShouNew_SevenDay_GetPrize()
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("Get7DayPrize");
			Set_XSCRIPT_ScriptID(892679);
			Set_XSCRIPT_Parameter(0,g_XinShouNew_7DayPrize_Click)
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
end

--===============================================
-- 天龙7日豪礼 -end
--===============================================


--===============================================
-- 天龙7日豪礼2023-begin
--===============================================

function XinShouNew_7Day2_RequestInfo(nType)
	if nType == 0 then
		-- 执行脚本
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateInfo_2023" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 998410 );				-- 脚本编号
			Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
		Send_XSCRIPT()
	end
end

function XinShouNew_7Day2_Show(nType)
	
	XinShouNew_7Day2_RequestInfo(nType)
	
	for i=1,7 do
		g_XinShouNew_7DayButtom_2023[i].Done:Hide()
		g_XinShouNew_7Day_ImgBK_2023[i]:Hide()
	end

	local nDate1= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1_2023)
	local nDate2= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_2_2023)
	
	local nDate3= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1_2023_Consume1)
	local nDate4= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1_2023_Consume2)

	local nTimes = math.mod(nDate1,10)

	local nDate = 1
	for i=1,nTimes do
		if math.mod(nDate2,10) == 1 and math.mod(nDate3,10) == 1 and math.mod(nDate4,10) == 1 then
			g_XinShouNew_7DayButtom_2023[i].Done:Show()
		end
		nDate2 = math.floor(nDate2/10)
		nDate3 = math.floor(nDate3/10)
		nDate4 = math.floor(nDate4/10)
	end
	---local kajiType = KaJi:LuaFnGetKaJiType(10)
	---if kajiType == 1 then
	---	--卡级服特写 上面一排最后一栏图标改成棉布
	---	XinShouNew_SevenDay_Top_day7_bk:SetProperty( "Image", "set:Ore image:Ore_14" )
	---else
	---	XinShouNew_SevenDay_Top_day7_bk:SetProperty( "Image", "set:CircularTaskTool49 image:CircularTaskTool49_5" )		
	---end
	
	if nType == 0 then
		XinShouNew_SevenDay2_Click(nTimes)
	else
		XinShouNew_SevenDay2_Click(g_XinShouNew_7DayPrize_Click_2023)
	end
	
end

function XinShouNew_7Day2_Update()
	XinShouNew_7Day2_Show(1)
end

function XinShouNew_SevenDay2_Click(nIndex)

	if nIndex<1 or nIndex>7 then
		return
	end

	XinShouNew_SevenDay2_Null1_Day1_Get:SetProperty( "Image", "set:XSYNew2023 image:1LS")
	XinShouNew_SevenDay2_Null2_Day2_Get:SetProperty( "Image", "set:XSYNew2023 image:2DHD")
	XinShouNew_SevenDay2_Null4_Day4_Get:SetProperty( "Image", "set:XSYNew2023 image:4YC")
	XinShouNew_SevenDay2_Null7_Day7_Get:SetProperty( "Image", "set:XSYNew2023 image:7WQ")
	if Player:GetData("Is2606S") == 1 then
		XinShouNew_SevenDay2_Null4_Day4_Get:SetProperty( "Image", "set:XinShou_QX image:JinCanSi_4" ) 
	end 
	if DataPool:GetSelfZoneWorldID() == 5177 then
		XinShouNew_SevenDay2_Null1_Day1_Get:SetProperty( "Image", "set:XinShou_QX3 image:Ride_Text")
		XinShouNew_SevenDay2_Null2_Day2_Get:SetProperty( "Image", "set:XinShou_QX3 image:Item_Text")
		XinShouNew_SevenDay2_Null4_Day4_Get:SetProperty( "Image", "set:XinShou_QX3 image:EqupicMent_Text")
		XinShouNew_SevenDay2_Null7_Day7_Get:SetProperty( "Image", "set:XinShou_QX3 image:Gem_Text")
	end
	for i=1,7 do
		if i ~= nIndex then
			g_XinShouNew_7Day_ImgBK_2023[i]:Hide()
		end
	end	
	
	g_XinShouNew_7Day_ImgBK_2023[nIndex]:Show()
	--id先暂时不改
	local kajiType = KaJi:LuaFnGetKaJiType(10)

	XinShouNew_SevenDay_Right_imageDay:SetProperty( "Image", g_XinShouNew_7DayImage_2023[nIndex][2] )

	if kajiType == 1 and nIndex == 7 then
		XinShouNew_SevenDay_Left_image:SetProperty( "Image", g_XinShouNew_7DayImage_2023[6][1] )
		XinShouNew_SevenDay_Right_imageDayItem:SetProperty( "Image", g_XinShouNew_7DayImage_2023[6][3] )
	else
		XinShouNew_SevenDay_Left_image:SetProperty( "Image", g_XinShouNew_7DayImage_2023[nIndex][1] )
		XinShouNew_SevenDay_Right_imageDayItem:SetProperty( "Image", g_XinShouNew_7DayImage_2023[nIndex][3] )
	end

	for i=1, 7 do
		g_XinShouNew_7DayButtom_2023[i].Button:SetCheck(0)
	end

	g_XinShouNew_7DayPrize_Click_2023 = nIndex

	--显示一下奖励
	for i=1, 5 do
		g_XinShouNew_7DayPrize_Button_2023[i]:SetActionItem( -1 );
	end
	
	XinShouNew_SevenDay2_Top_day1_bk:SetProperty("Image","set:RideHeader6 image:RideHeader6_5") 
	XinShouNew_SevenDay2_Top_day2_bk:SetProperty("Image","set:Medicine4 image:Medicine4_1") 
	XinShouNew_SevenDay2_Top_day3_bk:SetProperty("Image","set:CircularTaskTool78 image:CircularTaskTool78_9")
	XinShouNew_SevenDay2_Top_day4_bk:SetProperty("Image","set:CircularTaskTool60 image:CircularTaskTool60_2")
	XinShouNew_SevenDay2_Top_day5_bk:SetProperty("Image","set:CircularTaskTool47 image:CircularTaskTool47_12")
	XinShouNew_SevenDay2_Top_day6_bk:SetProperty("Image","set:Ore image:Ore_13")
	XinShouNew_SevenDay2_Top_day7_bk:SetProperty("Image","set:CircularTaskTool49 image:CircularTaskTool49_5")	

	local tableXinShouNew_7DayPrize = g_KajiTable_XSJNH[7][kajiType]
	if Player:GetData("Is2606S") == 1 then
		tableXinShouNew_7DayPrize = g_XinShouNew_2606S_GiftInfo[7] 
		XinShouNew_SevenDay2_Top_day4_bk:SetProperty("Image","set:Tattoo image:Tattoo_1")
		XinShouNew_SevenDay2_Top_day7_bk:SetProperty("Image","set:Ore image:Ore_14") 
	end
	--5177
	if DataPool:GetSelfZoneWorldID() == 5177 then
		tableXinShouNew_7DayPrize = g_XinShouNew_2606S_GiftInfo[8] 
		XinShouNew_SevenDay2_Top_day1_bk:SetProperty("Image","set:RideHeader12 image:RideHeader12_2") 
		XinShouNew_SevenDay2_Top_day2_bk:SetProperty("Image","set:Treasure image:Treasure_16") 
		XinShouNew_SevenDay2_Top_day3_bk:SetProperty("Image","set:CircularTaskTool146 image:CircularTaskTool146_1")
		XinShouNew_SevenDay2_Top_day4_bk:SetProperty("Image","set:CircularTaskTool133 image:CircularTaskTool133_12")
		XinShouNew_SevenDay2_Top_day5_bk:SetProperty("Image","set:Ore image:Ore_13")
		XinShouNew_SevenDay2_Top_day6_bk:SetProperty("Image","set:Ore image:Ore_14")
		XinShouNew_SevenDay2_Top_day7_bk:SetProperty("Image","set:CircularTaskTool181 image:CircularTaskTool181_8") 
	end
	local nCount = table.getn(tableXinShouNew_7DayPrize[nIndex])

	for i=1,nCount do
		local nItemID = tableXinShouNew_7DayPrize[nIndex][i].ItemID
		local nNum = tableXinShouNew_7DayPrize[nIndex][i].num
		
		local theAction = DataPool:CreateBindActionItemForShow(nItemID, nNum)
		if theAction:GetID() ~= 0 then
			g_XinShouNew_7DayPrize_Button_2023[i]:SetActionItem( theAction:GetID() );
		else
			g_XinShouNew_7DayPrize_Button_2023[i]:SetActionItem( -1 );
		end
	end


	g_XinShouNew_7DayButtom_2023[nIndex].Button:SetCheck(1)


	--看一下这页是不是可以打开
	local nDate1= DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1_2023)
	local nTimes = math.mod(nDate1,10)
	if nIndex > nTimes then
		--第X日可领取
		XinShouNew_SevenDay2_Client1_Button1:Disable()
		XinShouNew_SevenDay2_Client1_Button1: SetProperty("DisabledImage",g_XinShouNew_7DayImage[nIndex][4])
		XinShouNew_SevenDay2_Client2_Button1:Disable()
		XinShouNew_SevenDay2_Client2_Button1: SetProperty("DisabledImage",g_XinShouNew_7DayImage[nIndex][4])
		XinShouNew_SevenDay2_Client3_Button1:Disable()
		XinShouNew_SevenDay2_Client3_Button1: SetProperty("DisabledImage",g_XinShouNew_7DayImage[nIndex][4])
	else
		--看是不是已经领取了
		local nData1 = DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_2_2023)
		local nBase1 = 1
		for i=1,nIndex-1 do
			nBase1 = nBase1 * 10
		end
		local nFlag = math.mod(math.floor(nData1/nBase1),10)
		if nFlag == 0 then
		--未领取
			XinShouNew_SevenDay2_Client1_Button1:Enable()
		elseif nFlag == 1 then
		--已领取
			XinShouNew_SevenDay2_Client1_Button1:Disable()
			XinShouNew_SevenDay2_Client1_Button1: SetProperty("DisabledImage","set:XSYNew02 image:XinShouNew_Time_DisabledYLQ")
		end
		
		--看是不是已经领取了
		XinShouNew_SevenDay2_Client2_Text:SetText("#{XSJNH_230209_74}")
		local nData2 = DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1_2023_Consume1)
		local nBase2 = 1
		for i=1,nIndex-1 do
			nBase2 = nBase2 * 10
		end
		local nFlag = math.mod(math.floor(nData2/nBase2),10)
		if nFlag == 0 then
		--未领取
			if g_XinShouNew_7Day_CurConsume_2023 < g_XinShouNew_7Day_ConsumeLimit1.xf or g_XinShouNew_7Day_CurExch_2023 < g_XinShouNew_7Day_ConsumeLimit1.dh then
				XinShouNew_SevenDay2_Client2_Text:SetText("#{XSJNH_230209_43}")
			end
			XinShouNew_SevenDay2_Client2_Button1:Enable()
			
		elseif nFlag == 1 then
			--已领取
			XinShouNew_SevenDay2_Client2_Button1:Disable()
			XinShouNew_SevenDay2_Client2_Button1: SetProperty("DisabledImage","set:XSYNew02 image:XinShouNew_Time_DisabledYLQ")
		end
		
		--看是不是已经领取了
		XinShouNew_SevenDay2_Client3_Text:SetText("#{XSJNH_230209_75}")
		local nData3 = DataPool:GetPlayerMission_DataRound(g_MD_XINSHOU_7DAY_1_2023_Consume2)
		local nBase3 = 1
		for i=1,nIndex-1 do
			nBase3 = nBase3 * 10
		end
		local nFlag = math.mod(math.floor(nData3/nBase3),10)
		if nFlag == 0 then
			if g_XinShouNew_7Day_CurConsume_2023 < g_XinShouNew_7Day_ConsumeLimit2.xf or g_XinShouNew_7Day_CurExch_2023 < g_XinShouNew_7Day_ConsumeLimit2.dh then
				XinShouNew_SevenDay2_Client3_Text:SetText("#{XSJNH_230209_44}")
			end	
			XinShouNew_SevenDay2_Client3_Button1:Enable()
		elseif nFlag == 1 then
			--已领取
			XinShouNew_SevenDay2_Client3_Button1:Disable()
			XinShouNew_SevenDay2_Client3_Button1: SetProperty("DisabledImage","set:XSYNew02 image:XinShouNew_Time_DisabledYLQ")
		end
	end


end

--!!!reloadscript =XinShouNew

function XinShouNew_SevenDay2_GetPrize()
	---PushDebugMessage("XinShouNew_SevenDay2_GetPrize")
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("Get7DayPrize_2023");
			Set_XSCRIPT_ScriptID(998410);
			Set_XSCRIPT_Parameter(0,g_XinShouNew_7DayPrize_Click_2023)
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
end

function XinShouNew_SevenDay2_GetPrize_Consume1()
	---PushDebugMessage("XinShouNew_SevenDay2_GetPrize_Consume1")
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("Get7DayPrize_2023_Consume1");
			Set_XSCRIPT_ScriptID(998410);
			Set_XSCRIPT_Parameter(0,g_XinShouNew_7DayPrize_Click_2023)
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
end

function XinShouNew_SevenDay2_GetPrize_Consume2()
	---PushDebugMessage("XinShouNew_SevenDay2_GetPrize_Consume2")
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("Get7DayPrize_2023_Consume2");
			Set_XSCRIPT_ScriptID(998410);
			Set_XSCRIPT_Parameter(0,g_XinShouNew_7DayPrize_Click_2023)
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
end

--===============================================
-- 天龙7日豪礼2023 -end
--===============================================


--==========================社交达人==========================
--============================================================
--显示窗口
function XinShouNew_SheJiaoDaRen_Show()
	XinShouNew_SheJiaoRequest()
	XinShouNew_SheJiaoDaRen_FreshWindow()
	--XinShouNew_SheJiaoDaRen_UpdateRedPoint()
end
--数据刷新
function XinShouNew_SheJiaoDaRen_UpDateDate()
	for i = 1,5 do
		g_SheJiaoRewardBtnState[i] = Get_XParam_INT(i - 1)
	end
	--玩家活动的截止日期
	g_SheJiaoDeadLine = Get_XParam_INT(5)
	if(this:IsVisible()) then
		--刷新界面
		XinShouNew_SheJiaoDaRen_FreshWindow()
	end
	--XinShouNew_SheJiaoDaRen_UpdateRedPoint()
end
--刷新小红点逻辑
--function XinShouNew_SheJiaoDaRen_UpdateRedPoint()
--	local show = 0
--	for i = 1,5 do
--		if(g_SheJiaoRewardBtnState[i] == 1) then
--			show = 1
--			break
--		end
--	end
--	if(show == 1) then
--		XinShouNew_ShowButtonTips(10,1)
--	else
--		XinShouNew_ShowButtonTips(10,0)
--	end
--end
--奖励领取成功返回
--function XinShouNew_SheJiaoDaRen_RetReward(nIndex)
--	--XinShouNew_SheJiaoDaRen_UpdateRedPoint()
--end
--刷新窗口yymmddhhmm
function XinShouNew_SheJiaoDaRen_FreshWindow()
	local year,month,day,hour = XinShouNew_SheJiaoGetTime()
	for i = 1,5 do
		g_SheJiaoButtonAima[i]:Hide()
		local tooltip = ScriptGlobal_Format(g_SheJiaoBtnToolTips[i],year,month,day,hour)
		local tooltipDisble = ScriptGlobal_Format(g_SheJiaoBtnToolTipsDisbles[i],year,month,day,hour)
		g_SheJiaoButtons[i]:SetToolTip(tooltip)
		g_SheJiaoButtonDisbles[i]:SetToolTip(tooltipDisble)
		if(g_SheJiaoRewardBtnState[i] == 1) then
			g_SheJiaoButtons[i]:Show()
			g_SheJiaoButtonKongs[i]:Hide()
			g_SheJiaoButtonDisbles[i]:Hide()
		elseif (g_SheJiaoRewardBtnState[i] == 2) then
			g_SheJiaoButtons[i]:Hide()
			g_SheJiaoButtonKongs[i]:Show()
			g_SheJiaoButtonDisbles[i]:Hide()
		elseif(g_SheJiaoRewardBtnState[i] == 0) then
			g_SheJiaoButtons[i]:Hide()
			g_SheJiaoButtonKongs[i]:Hide()
			g_SheJiaoButtonDisbles[i]:Show()
		else
			g_SheJiaoButtons[i]:Hide()
			g_SheJiaoButtonKongs[i]:Hide()
			g_SheJiaoButtonDisbles[i]:Show()
		end
	end
	XinShouNew_SheJiaoFillGiftIcons()
end
--道具奖励都是不变的，第一次打开的时候填充一次就行了
function XinShouNew_SheJiaoFillGiftIcons()
	if(g_SheJiaoIsFillIcon == 0) then
		g_SheJiaoIsFillIcon = 1
		for i=1,table.getn(g_SheJiaoSheJiaoDaRenIcons) do
			for j = 1,table.getn(g_SheJiaoSheJiaoDaRenIcons[i]) do
				g_SheJiaoSheJiaoDaRenIcons[i][j]:Hide()
			end
		end
		for i=1,table.getn(g_SheJiaoDaRenGitf) do
			for j=1,table.getn(g_SheJiaoDaRenGitf[i]) do
				local theAction = DataPool:CreateActionItemForShow(g_SheJiaoDaRenGitf[i][j].GiftItemID, g_SheJiaoDaRenGitf[i][j].num)
				if theAction:GetID() ~= 0 then
					g_SheJiaoSheJiaoDaRenIcons[i][j]:SetActionItem(theAction:GetID());
					g_SheJiaoSheJiaoDaRenIcons[i][j]:Show();
				end
			end
		end
	end
end
function XinShouNew_SheJiaoInit()
	if(g_bInitSheJiao == 1) then
		return 
	end
	g_bInitSheJiao = 1
	g_SheJiaoButtons[1] = XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_Button
	g_SheJiaoButtons[2] = XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_Button
	g_SheJiaoButtons[3] = XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_Button
	g_SheJiaoButtons[4] = XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_Button
	g_SheJiaoButtons[5] = XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_Button
	
	g_SheJiaoButtonKongs[1] = XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_kong
	g_SheJiaoButtonKongs[2] = XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_kong
	g_SheJiaoButtonKongs[3] = XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_kong
	g_SheJiaoButtonKongs[4] = XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_kong
	g_SheJiaoButtonKongs[5] = XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_kong

	
	g_SheJiaoButtonDisbles[1] = XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_Disable
	g_SheJiaoButtonDisbles[2] = XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_Disable
	g_SheJiaoButtonDisbles[3] = XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_Disable
	g_SheJiaoButtonDisbles[4] = XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_Disable
	g_SheJiaoButtonDisbles[5] = XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_Disable
	
	--说明一下这个按钮动画，现在没有用，之前有做，后来策划功能给干掉了，xml没改，所以需要初始化隐藏
	g_SheJiaoButtonAima[1] = XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_Ani
	g_SheJiaoButtonAima[2] = XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_Ani
	g_SheJiaoButtonAima[3] = XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_Ani
	g_SheJiaoButtonAima[4] = XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_Ani
	g_SheJiaoButtonAima[5] = XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_Ani
	--奖励道具的ICON
	g_SheJiaoSheJiaoDaRenIcons = 
	{
		{XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_Icon1,XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_Icon2,XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_Icon3,XinShouNew_SheJiaoDaRen_RewardFrame_JieHun_Icon4},
		{XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_Icon1,XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_Icon2,XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_Icon3,XinShouNew_SheJiaoDaRen_RewardFrame_JieBai_Icon4},
		{XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_Icon1,XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_Icon2,XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_Icon3,XinShouNew_SheJiaoDaRen_RewardFrame_BaiShi_Icon4},
		{XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_Icon1,XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_Icon2,XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_Icon3,XinShouNew_SheJiaoDaRen_RewardFrame_ShouTu_Icon4},
		{XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_Icon1,XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_Icon2,XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_Icon3,XinShouNew_SheJiaoDaRen_RewardFrame_BangHui_Icon4},
	}

end
--领奖按钮点击 1结婚  2结拜 3拜师 4收徒 5加入帮会
function XinShouNew_SheJiao_ClickRward(nIndex)
	local curTime = OSAPI:GetTickCount()
	--按钮点击频率限制
	if(curTime - g_SheJiaoLastClick < 1000) then
		return
	end
	g_SheJiaoLastClick = curTime
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GetReward")
	Set_XSCRIPT_ScriptID(892687)
	Set_XSCRIPT_Parameter(0,nIndex)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function XinShouNew_OnAnimaOver(nIndex)
	--g_SheJiaoButtons[nIndex]:Hide()
	--g_SheJiaoButtonAima[nIndex]:Hide()
	--g_SheJiaoButtonKongs[nIndex]:Show()
	--local strFun = string.format("XinShouNew_OnAnimaOver(%d)",nIndex)
	--KillTimer(strFun)
end
--向服务器请求数据
function XinShouNew_SheJiaoRequest()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("UpDateInfo")
	Set_XSCRIPT_ScriptID(892687)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function XinShouNew_SheJiaoGetTime()
	local nTime = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)
	local year = math.floor(nTime/100000000) + 2000
	local month = math.floor(math.mod(nTime,100000000)/1000000)
	local day = math.floor(math.mod(nTime,1000000)/10000)
	local hour = math.floor(math.mod(nTime,10000)/100)
	return year,month,day,hour
end
function XinShouNew_SheJiaoDaRen_ClickDisble(nIndex)
	local strTips = "#{XSJNH_180111_170}"
	local strTips1 = ""
	local year,month,day,hour = XinShouNew_SheJiaoGetTime()
	if(1 == nIndex) then
		strTips = "#{XSJNH_180111_170}"
		strTips1 = ScriptGlobal_Format("#{XSJNH_180111_171}",year,month,day,hour)
	elseif (2 == nIndex) then
		strTips = "#{XSJNH_180111_176}"
		strTips1 = ScriptGlobal_Format("#{XSJNH_180111_177}",year,month,day,hour)
	elseif (3 == nIndex) then
		strTips = "#{XSJNH_180111_182}"
		strTips1 = ScriptGlobal_Format("#{XSJNH_180111_183}",year,month,day,hour)
	elseif (4 == nIndex) then
		strTips = "#{XSJNH_180111_188}"
		strTips1 = ScriptGlobal_Format("#{XSJNH_180111_189}",year,month,day,hour)
	elseif (5 == nIndex) then
		strTips = "#{XSJNH_180111_194}"
		strTips1 = ScriptGlobal_Format("#{XSJNH_180111_195}",year,month,day,hour)
	end
	PushDebugMessage(strTips)
	PushDebugMessage(strTips1)
end
--============================================================

--=======================新版天龙携手行========================================
--显示窗口
function XinShouNew_SheJiaoNew_Show()
	XinShouNew_SheJiaoNew_Request()
	g_SheJiaoNewCurPage = 0
	g_SheJiaoNewActionCurAchieveId = 0
	XinShouNew_FreshTopButtonTips()
	XinShouNew_SheJiaoNew_SwitchPage(1)
end

function XinShouNew_SheJiaoNew_Request()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("UpdateDataClient")
	Set_XSCRIPT_ScriptID(892753)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function XinShouNew_FreshTopButtonTips()
	for i=1,table.getn(g_SheJiaoNewPageButtons) do
		local bShowTips = 0
		for j=1,table.getn(g_SheJiaoNew_PageHasAchieves[i]) do
			
			local nAchieve = g_SheJiaoNew_PageHasAchieves[i][j]
			local bLock = XinShouNew_SheJiaoNew_EventCheck(g_SheJiaoNew_AhieveIdData[nAchieve].EventId)
			if(XinShouNew_SheJiaoNew_GetAhieveState(nAchieve) == 1 and bLock == 1) then
				bShowTips = 1
			end			
		end
		if(bShowTips == 1) then
			g_SheJiaoNewPageButtons[i].btntips:Show()
		else
			g_SheJiaoNewPageButtons[i].btntips:Hide()
		end
	end
end

function XinShouNew_SheJiaoNew_UpdateData()
	local nCount = Get_XParam_INT(0)
	for i=1,nCount do
		g_SheJiaoNew_AhieveDataPool[i] = Get_XParam_INT(i)
	end
	g_SheJiaoNew_RewardData = Get_XParam_INT(nCount + 1)
	g_SheJiaoNew_CreateTime = Get_XParam_INT(nCount + 2)
	-- local nPage = g_SheJiaoNewCurPage
	-- g_SheJiaoNewCurPage = 0
	XinShouNew_FreshTopButtonTips()
	XinShouNew_SheJiaoNew_SwitchPage(g_SheJiaoNewCurPage)
end

function XinShouNew_SheJiaoNew_SwitchPage(nIndex)
	-- if(g_SheJiaoNewCurPage == nIndex) then
		-- return
	-- end
	local nPages = table.getn(g_SheJiaoNewPages)
	if(nIndex >=1 and nIndex <= nPages)then
		for i=1,nPages do
			g_SheJiaoNewPages[i]:Hide()
		end
		g_SheJiaoNewPageButtons[nIndex].btn:SetCheck(1)
		g_SheJiaoNewPages[nIndex]:Show()
		XinShouNew_SheJiaoNew_FreshPage(nIndex)
	end
end

function XinShouNew_SheJiaoNew_FreshPage(nIndex)
	if(g_SheJiaoNewActionCurAchieveId <= 0 or g_SheJiaoNewCurPage ~= nIndex) then
		g_SheJiaoNewActionCurAchieveId = XinShouNew_SheJiaoNew_GetDefaultAhieveId(nIndex)
	end
	if(g_SheJiaoNewActionCurAchieveId == nil or g_SheJiaoNewActionCurAchieveId <= 0) then
		return
	end
	g_SheJiaoNewCurPage = nIndex
	XinShouNew_SheJiaoNew_FreshProcess()
	XinShouNew_SheJiaoNew_SwitchAcieve(g_SheJiaoNewActionCurAchieveId)
end

function XinShouNew_SheJiaoNew_GetDefaultAhieveId(nIndex)
	local nDefault1 = -1
	local nDefault2 = -1
	local nDefault3 = -1
	local nButtonMax = 7
	for i=1,table.getn(g_SheJiaoNew_PageHasAchieves[nIndex]) do
		local nAchieveId = g_SheJiaoNew_PageHasAchieves[nIndex][i]
		local nState = XinShouNew_SheJiaoNew_GetAhieveState(nAchieveId)
		local bLock = XinShouNew_SheJiaoNew_EventCheck(g_SheJiaoNew_AhieveIdData[nAchieveId].EventId)
		if(bLock == 1 and i<= nButtonMax) then
			if(nState == 0 and nDefault1 == -1) then
				nDefault1 = g_SheJiaoNew_PageHasAchieves[nIndex][i]
			end
			if(nState == 1 and nDefault2 == -1 ) then
				nDefault2 = g_SheJiaoNew_PageHasAchieves[nIndex][i]
			end
			nDefault3 = g_SheJiaoNew_PageHasAchieves[nIndex][i]
		end
	end
	if(nDefault1 ~= -1) then
		return nDefault1
	end
	if(nDefault2 ~= -1) then
		return nDefault2
	end
	if(nDefault3 ~= -1) then
		return nDefault3
	end
	return g_SheJiaoNew_PageHasAchieves[nIndex][1]
end

function XinShouNew_SheJiaoNew_FreshButtonList()
	local ButtonList = g_SheJiaoNew_PageButtonList[g_SheJiaoNewCurPage]
	if(ButtonList == nil) then
		return
	end
	for i=1,table.getn(ButtonList) do
		local nAchieveId = ButtonList[i].AchieveId
		local EventId = g_SheJiaoNew_AhieveIdData[nAchieveId].EventId
		local nRet = XinShouNew_SheJiaoNew_EventCheck(EventId)
		if(nRet == 1) then
			if(ButtonList[i].text ~= nil) then
				ButtonList[i].text:SetText(g_SheJiaoNew_AhieveIdData[nAchieveId].szNameDic)
				ButtonList[i].text:Show()
			end
			local state = XinShouNew_SheJiaoNew_GetAhieveState(nAchieveId)
			if(ButtonList[i].Tips ~= nil) then
				if(state == 1) then
					ButtonList[i].Tips:Show()
				else
					ButtonList[i].Tips:Hide()
				end
			end
			if(ButtonList[i].ToolTip ~= nil) then
				ButtonList[i].ToolTip:Hide()
			end
			if(ButtonList[i].rewardbtn ~= nil) then
				if(state == 2) then
					ButtonList[i].rewardbtn:Disable()
					ButtonList[i].rewardbtn:SetText("#{TLXS_180427_181}")
				else
					ButtonList[i].rewardbtn:Enable()
					ButtonList[i].rewardbtn:SetText("#{TLXS_180427_182}")
				end
			end
			if(ButtonList[i].btn ~= nil) then
				ButtonList[i].btn:Enable()
				if(g_SheJiaoNewActionCurAchieveId ~= nAchieveId) then
					ButtonList[i].btn:SetCheck(0)
				else
					ButtonList[i].btn:SetCheck(1)
				end
			end
			if(ButtonList[i].DisbleText ~= nil) then
				ButtonList[i].DisbleText:Hide()
			end
		else
			local szUnlock = g_SheJiaoNew_AhieveIdData[nAchieveId].unlockDic
			if(g_SheJiaoNew_AhieveIdData[nAchieveId].unlockdicparam ~= nil) then
				szUnlock = ScriptGlobal_Format(szUnlock,g_SheJiaoNew_AhieveIdData[nAchieveId].unlockdicparam)
			end
			if(ButtonList[i].text ~= nil) then
				ButtonList[i].text:SetText(szUnlock)
			end
			if(ButtonList[i].Tips ~= nil) then
				ButtonList[i].Tips:Hide()
			end
			if(ButtonList[i].btn ~= nil) then
				ButtonList[i].btn:Disable()
				ButtonList[i].btn:SetCheck(0)
			end
			if(ButtonList[i].DisbleText ~= nil) then
				ButtonList[i].DisbleText:Show()
				if(ButtonList[i].text ~= nil) then
					ButtonList[i].text:Hide()
				end
				ButtonList[i].DisbleText:SetText(g_SheJiaoNew_AhieveIdData[nAchieveId].szNameDic)
			end
			if(ButtonList[i].rewardbtn ~= nil) then
				ButtonList[i].rewardbtn:Enable()
				ButtonList[i].rewardbtn:SetText("#{TLXS_180427_182}")
			end
			if(ButtonList[i].ToolTip ~= nil) then
				ButtonList[i].ToolTip:Show()
			end
		end
	end
end

function XinShouNew_SheJiaoNew_FreshProcess()
	local ProcessList = g_SheJiaoNew_ProcessList[g_SheJiaoNewCurPage]
	if(ProcessList == nil) then
		return
	end
	local EventId = g_SheJiaoNew_ProcessList[g_SheJiaoNewCurPage].EventId
	local nCurValue = XinShouNew_SheJiaoNew_GetEventDataById(EventId)
	g_SheJiaoNew_ProcessList[g_SheJiaoNewCurPage].ValueText:SetText(ScriptGlobal_Format(ProcessList.szDesc,nCurValue))
	for i=1,table.getn(ProcessList.List) do
		local object = ProcessList.List[i]
		local RewardList = g_SheJiaoNew_AhieveIdData[object.AhieveId].RewardList
		if Player:GetData("Is2606S") == 1 then
			RewardList = g_XinShouNew_2606S_GiftInfo[3][object.AhieveId].RewardList
		end
		local nNeedValue = g_SheJiaoNew_AhieveIdData[object.AhieveId].NeedValue
		if(RewardList ~= nil) then
			local theAction = DataPool:CreateActionItemForShow(RewardList.Id, RewardList.Count)
			if theAction:GetID() ~= 0 then
				object.GiftAction:SetActionItem(theAction:GetID())
			end
		end
		local nState = XinShouNew_SheJiaoNew_GetAhieveState(object.AhieveId)
		if(nState == 2) then
			object.Mark:Show()
		else
			object.Mark:Hide()
		end
		if(nState == 1) then
			object.Tips:Show()
		else
			object.Tips:Hide()
		end
		object.NumText:SetText("#cfff263"..tostring(nNeedValue))
	end
end

function XinShouNew_SheJiaoNew_SwitchAcieve(AchieveID)
	local GiftActions = g_SheJiaoNew_GiftActions[g_SheJiaoNewCurPage]
	if(GiftActions == nil) then
		return
	end
	if(g_SheJiaoNew_AhieveIdData[AchieveID] == nil) then
		return
	end
	if(XinShouNew_SheJiaoNew_EventCheck(g_SheJiaoNew_AhieveIdData[AchieveID].EventId) == 0) then
		return
	end
	local RewardList = g_SheJiaoNew_AhieveIdData[AchieveID].RewardList
	if(RewardList == nil) then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		RewardList = g_XinShouNew_2606S_GiftInfo[3][AchieveID].RewardList
	end
	g_SheJiaoNewActionCurAchieveId = AchieveID
	local nAchieveData = XinShouNew_SheJiaoNew_GetEventDataById(g_SheJiaoNew_AhieveIdData[AchieveID].EventId)
	local nState = XinShouNew_SheJiaoNew_GetAhieveState(AchieveID)
	local szDebug = g_SheJiaoNew_AhieveIdData[AchieveID].Desc
	local szTitle = g_SheJiaoNew_AhieveIdData[AchieveID].szTitleName
	if(AchieveID == 4) then
		local nPos = XinShouNew_SheJiaoNew_GetEventDataById(20)
		if(g_SheJiaoNew_RandPosTips[nPos] ~= nil) then
			szDebug = ScriptGlobal_Format(szDebug,g_SheJiaoNew_RandPosTips[nPos])
		end
	end
	if(GiftActions.Title ~= nil and szTitle ~= nil) then
		GiftActions.Title:SetText(szTitle)
	end
	if(GiftActions.DescText ~= nil) then
		GiftActions.DescText:SetText(szDebug)
	end
	if(GiftActions.ValueText ~= nil) then
		local szColor = "#cff0000"
		if(AchieveID == 3) then
			nAchieveData = 100
			if(nState == 0) then
				nAchieveData = DataPool:GetPlayerMission_DataRound(1229)
			end
			
			if(nAchieveData >= 100) then
				--GiftActions.ValueText:Hide()
				GiftActions.ValueText:SetText("#{TLXS_180427_183}")
			else
				--GiftActions.ValueText:Show()
				GiftActions.ValueText:SetText(szColor..nAchieveData.."#cfff263".."/100")
			end
		else
			
			if(nAchieveData >= g_SheJiaoNew_AhieveIdData[AchieveID].NeedValue) then
				--GiftActions.ValueText:Hide()
				GiftActions.ValueText:SetText("#{TLXS_180427_183}")
			else
				--GiftActions.ValueText:Show()
				GiftActions.ValueText:SetText(szColor..nAchieveData.."#cfff263".."/"..g_SheJiaoNew_AhieveIdData[AchieveID].NeedValue)
			end
		end
	end
	if(GiftActions.helpbtn ~= nil) then
		GiftActions.helpbtn:Show()
	end
	local theAction = DataPool:CreateActionItemForShow(RewardList.Id, RewardList.Count)
	if theAction:GetID() ~= 0 then
		GiftActions.GiftAction:SetActionItem(theAction:GetID())
	end
	if(GiftActions.Mark ~= nil) then
		if(nState == 2) then
			GiftActions.Mark:Show()
		else
			GiftActions.Mark:Hide()
		end
	end
	local nYear,nMonth,nDay,nHour = XinShouNew_SheJiaoGetTime()
	if(GiftActions.TimeTips ~= nil) then
		GiftActions.TimeTips:SetText(ScriptGlobal_Format("#{TLXS_180427_161}",nYear,nMonth,nDay))
	end
	if(GiftActions.TimeToolTips ~= nil and GiftActions.ToolTipValue ~= nil) then
		GiftActions.TimeToolTips:SetToolTip(ScriptGlobal_Format(GiftActions.ToolTipValue,nYear,nMonth,nDay))
	end
	XinShouNew_SheJiaoNew_FreshButtonList()
end
--点击中间的action领奖
function XinShouNew_SheJiaoNew_PageActionClick()
	XinShouNew_SheJiaoNew_ProcessActionClick(g_SheJiaoNewActionCurAchieveId)
end
--点击下面一排的action领奖
function XinShouNew_SheJiaoNew_ProcessActionClick(AchieveId)
	if(AchieveId == nil or AchieveId <= 0) then
		return
	end
	if(g_SheJiaoNew_AhieveIdData[AchieveId] == nil) then
		return
	end
	local state = XinShouNew_SheJiaoNew_GetAhieveState(AchieveId)
	if(state == 1) then
		--向服务器请求领奖
		if (IsInTServer() == 1) then
			PushDebugMessage("#{BHKF_140909_327}")
			return
		end		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetReward" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 892753 );				-- 脚本编号
			Set_XSCRIPT_Parameter( 0, AchieveId );		-- 参数一
			Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
		Send_XSCRIPT()
		return
	elseif(state == 0) then
		local szTips = g_SheJiaoNew_AhieveIdData[AchieveId].szUnReward
		PushDebugMessage(szTips)
	elseif(state == 2) then
		PushDebugMessage("#{TLXS_180427_51}")
	end
end

function XinShouNew_SheJiaoNew_HelpClick(nIndex)
	if(nIndex == 1)then
		PushEvent("SHOW_SHEJAO2018_HELP","#{TLXS_180427_160}")
	else
		if Player:GetData("Is2606S") == 1 then
			PushEvent("SHOW_SHEJAO2018_HELP","#{QXF_260623_139}")
		else 
			PushEvent("SHOW_SHEJAO2018_HELP","#{TLXS_180427_179}")
		end
	end
end

function XinShouNew_SheJiaoNew_Init()
	g_SheJiaoNewPages[1] = XinShouNew_SheJiaoFrame_Page1
	g_SheJiaoNewPages[2] = XinShouNew_SheJiaoFrame_Page2
	g_SheJiaoNewPages[3] = XinShouNew_SheJiaoFrame_Page3
	g_SheJiaoNewPages[4] = XinShouNew_SheJiaoFrame_Page4
	g_SheJiaoNewPages[5] = XinShouNew_SheJiaoFrame_Page5
	
	g_SheJiaoNewPageButtons[1] = {btn=XinShouNew_SheJiaoFrame_Button01,btntips=XinShouNew_SheJiaoFrame_Button01tips}
	g_SheJiaoNewPageButtons[2] = {btn=XinShouNew_SheJiaoFrame_Button02,btntips=XinShouNew_SheJiaoFrame_Button02tips}
	g_SheJiaoNewPageButtons[3] = {btn=XinShouNew_SheJiaoFrame_Button03,btntips=XinShouNew_SheJiaoFrame_Button03tips}
	g_SheJiaoNewPageButtons[4] = {btn=XinShouNew_SheJiaoFrame_Button04,btntips=XinShouNew_SheJiaoFrame_Button04tips}
	g_SheJiaoNewPageButtons[5] = {btn=XinShouNew_SheJiaoFrame_Button05,btntips=XinShouNew_SheJiaoFrame_Button05tips}
	
	g_SheJiaoNew_GiftActions[1] = {TimeTips=XinShouNew_SheJiaoFrame_Page1_EveryMissionInfo2,Mark=XinShouNew_SheJiaoFrame_Page1_MissionGiftMark,GiftAction = XinShouNew_SheJiaoFrame_Page1_MissionGift,Title=XinShouNew_SheJiaoFrame_Page1_EveryMissionText,DescText = XinShouNew_SheJiaoFrame_Page1_EveryMissionInfo,ValueText=XinShouNew_SheJiaoFrame_Page1_EveryMissionTimes,helpbtn=XinShouNew_SheJiaoFrame_Page1_EveryMission_Help}
	g_SheJiaoNew_GiftActions[2] = {TimeTips=XinShouNew_SheJiaoFrame_Page2_EveryMissionInfo2,Mark=XinShouNew_SheJiaoFrame_Page2_EveryMissionGiftMark,GiftAction = XinShouNew_SheJiaoFrame_Page2_EveryMissionGift,Title=XinShouNew_SheJiaoFrame_Page2_EveryMissionText,DescText = XinShouNew_SheJiaoFrame_Page2_EveryMissionInfo,ValueText=XinShouNew_SheJiaoFrame_Page2_EveryMissionTimes,helpbtn=XinShouNew_SheJiaoFrame_Page2_EveryMission_Help,}
	g_SheJiaoNew_GiftActions[3] = {TimeToolTips=XinShouNew_SheJiaoFrame_Page3_EveryMissionButton,ToolTipValue="#{TLXS_180427_47}",GiftAction = XinShouNew_SheJiaoFrame_Page3_EveryMissionGift}
	g_SheJiaoNew_GiftActions[4] = {TimeToolTips=XinShouNew_SheJiaoFrame_Page4_EveryMissionButton,ToolTipValue="#{TLXS_180427_49}",GiftAction = XinShouNew_SheJiaoFrame_Page4_EveryMissionGift}
	g_SheJiaoNew_GiftActions[5] = {TimeToolTips=XinShouNew_SheJiaoFrame_Page5_EveryMissionButton,ToolTipValue="#{TLXS_180427_48}",GiftAction = XinShouNew_SheJiaoFrame_Page5_EveryMissionGift}

	g_SheJiaoNew_PageButtonList[1] = {
										[1] = {btn=XinShouNew_SheJiaoFrame_Page1_Mission1,ToolTip=XinShouNew_SheJiaoFrame_Page1_Mission1Warning,Tips=XinShouNew_SheJiaoFrame_Page1_Mission1tips,text=XinShouNew_SheJiaoFrame_Page1_Mission1Text,AchieveId=1,DisbleText=XinShouNew_SheJiaoFrame_Page1_Mission1Text2,},
										[2] = {btn=XinShouNew_SheJiaoFrame_Page1_Mission2,ToolTip=XinShouNew_SheJiaoFrame_Page1_Mission2Warning,Tips=XinShouNew_SheJiaoFrame_Page1_Mission2tips,text=XinShouNew_SheJiaoFrame_Page1_Mission2Text,AchieveId=2,DisbleText=XinShouNew_SheJiaoFrame_Page1_Mission2Text2,},
										[3] = {btn=XinShouNew_SheJiaoFrame_Page1_Mission3,ToolTip=XinShouNew_SheJiaoFrame_Page1_Mission3Warning,Tips=XinShouNew_SheJiaoFrame_Page1_Mission3tips,text=XinShouNew_SheJiaoFrame_Page1_Mission3Text,AchieveId=3,DisbleText=XinShouNew_SheJiaoFrame_Page1_Mission3Text2,},
										[4] = {btn=XinShouNew_SheJiaoFrame_Page1_Mission4,ToolTip=XinShouNew_SheJiaoFrame_Page1_Mission4Warning,Tips=XinShouNew_SheJiaoFrame_Page1_Mission4tips,text=XinShouNew_SheJiaoFrame_Page1_Mission4Text,AchieveId=4,DisbleText=XinShouNew_SheJiaoFrame_Page1_Mission4Text2,},
										[5] = {btn=XinShouNew_SheJiaoFrame_Page1_Mission5,ToolTip=XinShouNew_SheJiaoFrame_Page1_Mission5Warning,Tips=XinShouNew_SheJiaoFrame_Page1_Mission5tips,text=XinShouNew_SheJiaoFrame_Page1_Mission5Text,AchieveId=5,DisbleText=XinShouNew_SheJiaoFrame_Page1_Mission5Text2,},
										[6] = {btn=XinShouNew_SheJiaoFrame_Page1_Mission6,ToolTip=XinShouNew_SheJiaoFrame_Page1_Mission6Warning,Tips=XinShouNew_SheJiaoFrame_Page1_Mission6tips,text=XinShouNew_SheJiaoFrame_Page1_Mission6Text,AchieveId=6,DisbleText=XinShouNew_SheJiaoFrame_Page1_Mission6Text2,},
										[7] = {btn=XinShouNew_SheJiaoFrame_Page1_Mission7,ToolTip=XinShouNew_SheJiaoFrame_Page1_Mission7Warning,Tips=XinShouNew_SheJiaoFrame_Page1_Mission7tips,text=XinShouNew_SheJiaoFrame_Page1_Mission7Text,AchieveId=7,DisbleText=XinShouNew_SheJiaoFrame_Page1_Mission7Text2,},
									 }
	g_SheJiaoNew_PageButtonList[2] = {
										[1] = {btn=XinShouNew_SheJiaoFrame_Page2_Mission1,ToolTip=XinShouNew_SheJiaoFrame_Page2_Mission1Warning,Tips=XinShouNew_SheJiaoFrame_Page2_Mission1tips,text=XinShouNew_SheJiaoFrame_Page2_Mission1Text,AchieveId=11},
										[2] = {btn=XinShouNew_SheJiaoFrame_Page2_Mission2,ToolTip=XinShouNew_SheJiaoFrame_Page2_Mission2Warning,Tips=XinShouNew_SheJiaoFrame_Page2_Mission2tips,text=XinShouNew_SheJiaoFrame_Page2_Mission2Text,AchieveId=12},
										[3] = {btn=XinShouNew_SheJiaoFrame_Page2_Mission3,ToolTip=XinShouNew_SheJiaoFrame_Page2_Mission3Warning,Tips=XinShouNew_SheJiaoFrame_Page2_Mission3tips,text=XinShouNew_SheJiaoFrame_Page2_Mission3Text,AchieveId=13},
										[4] = {btn=XinShouNew_SheJiaoFrame_Page2_Mission4,ToolTip=XinShouNew_SheJiaoFrame_Page2_Mission4Warning,Tips=XinShouNew_SheJiaoFrame_Page2_Mission4tips,text=XinShouNew_SheJiaoFrame_Page2_Mission4Text,AchieveId=14},
										[5] = {btn=XinShouNew_SheJiaoFrame_Page2_Mission5,ToolTip=XinShouNew_SheJiaoFrame_Page2_Mission5Warning,Tips=XinShouNew_SheJiaoFrame_Page2_Mission5tips,text=XinShouNew_SheJiaoFrame_Page2_Mission5Text,AchieveId=15},
										[6] = {btn=XinShouNew_SheJiaoFrame_Page2_Mission6,ToolTip=XinShouNew_SheJiaoFrame_Page2_Mission6Warning,Tips=XinShouNew_SheJiaoFrame_Page2_Mission6tips,text=XinShouNew_SheJiaoFrame_Page2_Mission6Text,AchieveId=16},
										[7] = {btn=XinShouNew_SheJiaoFrame_Page2_Mission7,ToolTip=XinShouNew_SheJiaoFrame_Page2_Mission7Warning,Tips=XinShouNew_SheJiaoFrame_Page2_Mission7tips,text=XinShouNew_SheJiaoFrame_Page2_Mission7Text,AchieveId=17},
									 }
	g_SheJiaoNew_PageButtonList[3] = {
										[1] = {rewardbtn=XinShouNew_SheJiaoFrame_Page3_EveryMissionButton,AchieveId=22},
									 }
	g_SheJiaoNew_PageButtonList[4] = {
										[1] = {rewardbtn=XinShouNew_SheJiaoFrame_Page4_EveryMissionButton,AchieveId=23},
									 }
	g_SheJiaoNew_PageButtonList[5] = {
										[1] = {rewardbtn=XinShouNew_SheJiaoFrame_Page5_EveryMissionButton,AchieveId=24},
									 }
	
	
	g_SheJiaoNew_ProcessList[1] = {ValueText = XinShouNew_SheJiaoFrame_Page1_TotalNumber,EventId = 8,szDesc="#{TLXS_180427_105}",
									List={
									[1] = {AhieveId=8,GiftAction=XinShouNew_SheJiaoFrame_Page1_Gift1,Mark=XinShouNew_SheJiaoFrame_Page1_Gift1Mark,NumText=XinShouNew_SheJiaoFrame_Page1_Number1,Tips=XinShouNew_SheJiaoFrame_Page1_Gift1tips,},
									[2] = {AhieveId=9,GiftAction=XinShouNew_SheJiaoFrame_Page1_Gift2,Mark=XinShouNew_SheJiaoFrame_Page1_Gift2Mark,NumText=XinShouNew_SheJiaoFrame_Page1_Number2,Tips=XinShouNew_SheJiaoFrame_Page1_Gift2tips,},
									[3] = {AhieveId=10,GiftAction=XinShouNew_SheJiaoFrame_Page1_Gift3,Mark=XinShouNew_SheJiaoFrame_Page1_Gift3Mark,NumText=XinShouNew_SheJiaoFrame_Page1_Number3,Tips=XinShouNew_SheJiaoFrame_Page1_Gift3tips,},
										 }
								  }
	g_SheJiaoNew_ProcessList[2] = {ValueText = XinShouNew_SheJiaoFrame_Page2_TotalNumber,EventId = 16,szDesc="#{TLXS_180427_106}",
									List={
									[1] = {AhieveId=18,GiftAction=XinShouNew_SheJiaoFrame_Page2_Gift1,Mark=XinShouNew_SheJiaoFrame_Page2_Gift1Mark,NumText=XinShouNew_SheJiaoFrame_Page2_Number1,Tips=XinShouNew_SheJiaoFrame_Page2_Gift1tips,},
									[2] = {AhieveId=19,GiftAction=XinShouNew_SheJiaoFrame_Page2_Gift2,Mark=XinShouNew_SheJiaoFrame_Page2_Gift2Mark,NumText=XinShouNew_SheJiaoFrame_Page2_Number2,Tips=XinShouNew_SheJiaoFrame_Page2_Gift2tips,},
									[3] = {AhieveId=20,GiftAction=XinShouNew_SheJiaoFrame_Page2_Gift3,Mark=XinShouNew_SheJiaoFrame_Page2_Gift3Mark,NumText=XinShouNew_SheJiaoFrame_Page2_Number3,Tips=XinShouNew_SheJiaoFrame_Page2_Gift3tips,},
									[4] = {AhieveId=21,GiftAction=XinShouNew_SheJiaoFrame_Page2_Gift4,Mark=XinShouNew_SheJiaoFrame_Page2_Gift4Mark,NumText=XinShouNew_SheJiaoFrame_Page2_Number4,Tips=XinShouNew_SheJiaoFrame_Page2_Gift4tips,},
										 }
								  }
end
--检测事件是否解锁0 未解锁 1解锁
function XinShouNew_SheJiaoNew_EventCheck(EventId)
	--结婚事件，一天解锁一个
	if(EventId >=2 and EventId <= 7) then
		local UnLockDay = XinShouNew_SheJiaoNew_GetEventDataById(g_SheJiaoNew_MarryUnkLockDayBit)
		if(UnLockDay + 1 < EventId) then
			return 0
		end
	end
	-- if(EventId >=1 and EventId <= 8) then
		-- local nRet,_guid = Friend:Lua_GetSpouseGuid()
		-- if(nRet == 0) then
			-- return 2
		-- end
	-- end
	--帮会完成前一个任务才能解锁后一个
	if(EventId >= 10 and EventId <= 15) then
		local LastEvent = EventId - 1
		local nValue = XinShouNew_SheJiaoNew_GetEventDataById(LastEvent)
		if(nValue < g_SheJiaoNew_EventId2Data[LastEvent].MaxValue) then
			return 0
		end
	end
	-- if(EventId >= 10 and EventId <= 16) then
		-- local guildID, clanID = DataPool:GetGuildClanID()
		-- if(guildID < 0) then
			-- return 2
		-- end
	-- end
	return 1
end
--获取成就的状态 0未完成 1已完成 2已领奖
function XinShouNew_SheJiaoNew_GetAhieveState(AhieveId)
	local EventId = g_SheJiaoNew_AhieveIdData[AhieveId].EventId
	if(EventId == nil) then
		return 0
	end

	local nCur = XinShouNew_SheJiaoNew_GetEventDataById(EventId)
	if(nCur >= g_SheJiaoNew_AhieveIdData[AhieveId].NeedValue) then
		if(XinShouNew_SheJiaoNew_RewardBitGet(AhieveId) == 1) then
			return 2
		end
		return 1
	end
	return 0
end

--根据事件ID解析出事件的数据
function XinShouNew_SheJiaoNew_GetEventDataById(nId)
	if(nId == nil or g_SheJiaoNew_EventId2Data[nId] == nil) then
		return
	end
	local nStart = g_SheJiaoNew_EventId2Data[nId].Start
	local nLen = g_SheJiaoNew_EventId2Data[nId].Len
	local nIndex = math.floor(nStart / 32) + 1
	--处理跨MD数据
	local nNum = math.mod(nStart ,32)
	local nRetValue = 0
	local nRetValueLen = 0
	local nMaxClycle = 99 --做一个循环限制
	while(1) do
		if(nIndex >= nMaxClycle) then
			return
		end
		if(g_SheJiaoNew_AhieveDataPool[nIndex] == nil) then
			return
		end
		local nEnd = nNum + nLen
		if(nEnd > 32) then
			nEnd = 32
		end
		local nSize = nEnd - nNum
		local nData = g_SheJiaoNew_AhieveDataPool[nIndex]
		local nRet,nValue = GetBitValueInUINT(nData,nNum,nSize)
		nRet,nRetValue = SetBitValueInUINT(nRetValue,nRetValueLen,nSize,nValue)
		nLen = nLen - nSize
		nRetValueLen = nRetValueLen + nSize
		nNum = 0
		nIndex = nIndex + 1
		if(nLen <= 0) then
			return nRetValue
		end
	end
end

--奖励领取标志位获取函数
function XinShouNew_SheJiaoNew_RewardBitGet(nBit)
	if(nBit < 1 or nBit > 31) then
		return 0
	end
	local Data = g_SheJiaoNew_RewardData
	local bRet,state = GetBitValueInUINT(Data,nBit,1)
	return state
end

--=============================================================================

function XinShouNew_OnCheckMe()
	if g_lastDay == -1 or  g_lastMaiDian == -1 then
		return
	end

	local nHaoXiaIndex = Lua_GetHaoXiaIndexChange(g_lastDay,g_lastMaiDian);
	local viewPos = 0;

	for i,v in ipairs(g_nContentButton) do

		if (i-1) == nHaoXiaIndex then
			v:SetBarButtonSelected(true)
			viewPos = i - 1
		else
			v:SetBarButtonSelected(false)
		end
	end
	XinShouNew_Heroes_RoadList:SetVertScrollbarPosition(80.0*viewPos)
	g_lastDay = -1
	g_lastMaiDian = -1
end

function XinShouNew_OnCheckRed(nDayGap)

	for idx=0,6 do
		if idx > (nDayGap - 1) then
			continue
		end
		local bCheckRed = 0	
		local Num = Lua_GetMaiDianNumByDay(idx)
		for i = 0,Num-1 do
			local MaiDianValue = 0

			local BounsFlag = 0
			local nChangeIndex = Lua_GetHaoXiaIndex(idx,i)
			BounsFlag = DataPool:Lua_GetHaoXiaRoadFlag(idx,nChangeIndex)
			local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
			local Desc,TargetNum,BounsNum,Isspecial,Image1,Image2,nType,param0,param1,param2 = Lua_GetXinShouHeroesRoadInfo(idx,nChangeIndex)
			if idx == 6 and nChangeIndex == 0 and (nSpecKaJi89 == 1 or nSpecKaJi89 == 2) then
				Desc = "#{BJKJ_220701_18}"
				TargetNum = 89 
			end
			if Isspecial == 0 then
				MaiDianValue = DataPool:Lua_GetHaoXiaRoad(idx,nChangeIndex)
			elseif Isspecial == 1 then
				if g_XinShouNew_Heroes_Road_2023 ~= 1 then 
					MaiDianValue = Player:GetData("EQUIPSCOREHH");
				end
				
			end

			if MaiDianValue < TargetNum then
			elseif BounsFlag == 0 then
				bCheckRed = 1
			elseif BounsFlag == 1 then
			end

		end	
		
		local ii = idx+1
		if bCheckRed == 1 then
			g_HaoXialuRed[ii]:Show()
		else
			g_HaoXialuRed[ii]:Hide()
		end	
	end

	



end


function XinShouNew_Supe_TeQuanShop_Clicked()
	if 1 ~= DataPool:Lua_XFTQShopIsOpen() then
		PushDebugMessage("#{TQSD_230201_01}")
		return
	end
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenShop" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998401 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );				-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end

--**********************************
--江湖幸运星begin
--**********************************
function XinShouNew_LuckyDraw2023_Init()
	g_XinShouNew_LuckStar2_Action1[1] = XinShouNew_LuckStar2_Frame3_Bk_Icon1
	g_XinShouNew_LuckStar2_Action1[2] = XinShouNew_LuckStar2_Frame3_Bk_Icon2
	g_XinShouNew_LuckStar2_Action1[3] = XinShouNew_LuckStar2_Frame3_Bk_Icon3
	
	g_XinShouNew_LuckStar2_Action1_Image[1] = XinShouNew_LuckStar2_Frame3_Bk_Icon1Tips
	g_XinShouNew_LuckStar2_Action1_Image[2] = XinShouNew_LuckStar2_Frame3_Bk_Icon2Tips
	g_XinShouNew_LuckStar2_Action1_Image[3] = XinShouNew_LuckStar2_Frame3_Bk_Icon3Tips
	
	g_XinShouNew_LuckStar2_Action1_Xin[1] = XinShouNew_LuckStar2_Frame3_Bk_Icon1_Xin
	g_XinShouNew_LuckStar2_Action1_Xin[2] = XinShouNew_LuckStar2_Frame3_Bk_Icon2_Xin
	g_XinShouNew_LuckStar2_Action1_Xin[3] = XinShouNew_LuckStar2_Frame3_Bk_Icon3_Xin
	
	g_XinShouNew_LuckStar2_Action2[1] = XinShouNew_LuckStar2_Frame3_Bk2_Icon1
	g_XinShouNew_LuckStar2_Action2[2] = XinShouNew_LuckStar2_Frame3_Bk2_Icon2
	g_XinShouNew_LuckStar2_Action2[3] = XinShouNew_LuckStar2_Frame3_Bk2_Icon3
	g_XinShouNew_LuckStar2_Action2[4] = XinShouNew_LuckStar2_Frame3_Bk2_Icon4
	g_XinShouNew_LuckStar2_Action2[5] = XinShouNew_LuckStar2_Frame3_Bk2_Icon5
	g_XinShouNew_LuckStar2_Action2[6] = XinShouNew_LuckStar2_Frame3_Bk2_Icon6
	g_XinShouNew_LuckStar2_Action2[7] = XinShouNew_LuckStar2_Frame3_Bk2_Icon7
	
	g_XinShouNew_LuckStar2_Action2_Image[1] = XinShouNew_LuckStar2_Frame3_Bk2_Icon1Tips
	g_XinShouNew_LuckStar2_Action2_Image[2] = XinShouNew_LuckStar2_Frame3_Bk2_Icon2Tips
	g_XinShouNew_LuckStar2_Action2_Image[3] = XinShouNew_LuckStar2_Frame3_Bk2_Icon3Tips
	g_XinShouNew_LuckStar2_Action2_Image[4] = XinShouNew_LuckStar2_Frame3_Bk2_Icon4Tips
	g_XinShouNew_LuckStar2_Action2_Image[5] = XinShouNew_LuckStar2_Frame3_Bk2_Icon5Tips
	g_XinShouNew_LuckStar2_Action2_Image[6] = XinShouNew_LuckStar2_Frame3_Bk2_Icon6Tips
	g_XinShouNew_LuckStar2_Action2_Image[7] = XinShouNew_LuckStar2_Frame3_Bk2_Icon7Tips
	
	g_XinShouNew_LuckStar2_Action2_Xin[1] = XinShouNew_LuckStar2_Frame3_Bk2_Icon1_Xin
	g_XinShouNew_LuckStar2_Action2_Xin[2] = XinShouNew_LuckStar2_Frame3_Bk2_Icon2_Xin
	g_XinShouNew_LuckStar2_Action2_Xin[3] = XinShouNew_LuckStar2_Frame3_Bk2_Icon3_Xin
	g_XinShouNew_LuckStar2_Action2_Xin[4] = XinShouNew_LuckStar2_Frame3_Bk2_Icon4_Xin
	g_XinShouNew_LuckStar2_Action2_Xin[5] = XinShouNew_LuckStar2_Frame3_Bk2_Icon5_Xin
	g_XinShouNew_LuckStar2_Action2_Xin[6] = XinShouNew_LuckStar2_Frame3_Bk2_Icon6_Xin
	g_XinShouNew_LuckStar2_Action2_Xin[7] = XinShouNew_LuckStar2_Frame3_Bk2_Icon7_Xin
	
end

function XinShouNew_LuckyDraw2023_Show()
	XinShouNew_LuckyDraw2023_UpdateInfo();
 	XinShouNew_LuckyDraw2023_FlushWindow();
end
--**********************************
-- 请求更新Btn状态
--**********************************
function XinShouNew_LuckyDraw2023_UpdateInfo() 
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateUI" ); 	
		Set_XSCRIPT_ScriptID( 998413 );				
		Set_XSCRIPT_ParamCount( 0 );		
	Send_XSCRIPT() 
end

function XinShouNew_LuckyDraw2023_FlushWindow() 
	
	--在线时长
	if g_NewLuckyDraw_TodayOnlineTime >= g_NewLuckyDraw_NeedTime[3] and g_NewLuckyDraw_TodayPoint >= 150 then
		XinShouNew_LuckStar2_Time:SetText("#{XSJNH_230209_24}")
	else
		local onlineTime = ""
		local nHour = math.floor(g_NewLuckyDraw_TodayOnlineTime/60)
		local nMinute = math.mod(g_NewLuckyDraw_TodayOnlineTime, 60)
		if nHour > 0 then	
			onlineTime = nHour.."小时"..nMinute.."分"
		else	
			onlineTime = nMinute.."分"
		end
		XinShouNew_LuckStar2_Time:SetText(ScriptGlobal_Format( "#{XSJNH_230209_23}", onlineTime))
	end

	g_NewLuckyDraw_TodayPoint = Player:GetData("TODAYACTIVEPOINT")
	XinShouNew_LuckStar2_Activitytext:SetText(ScriptGlobal_Format( "#{XSJNH_230209_22}", g_NewLuckyDraw_TodayPoint))
	
	for i = 1, 3 do

		g_XinShouNew_LuckStar2_Action1[i]:Show()
		g_XinShouNew_LuckStar2_Action1_Image[i]:Hide()
		g_XinShouNew_LuckStar2_Action1_Xin[i]:Hide()
		if g_NewLuckyDraw_Flag[i] == 1 then--已领取
			g_XinShouNew_LuckStar2_Action1[i]:Hide()
			g_XinShouNew_LuckStar2_Action1_Xin[i]:Show()
		else
			--可领取
			if g_NewLuckyDraw_TodayPoint >= 150 and g_NewLuckyDraw_TodayOnlineTime >= g_NewLuckyDraw_NeedTime[i] and g_NewLuckyDraw_Flag[i] == 0 then
				g_XinShouNew_LuckStar2_Action1_Image[i]:Show()
			end
		end
	end
	
	--签到次数
	XinShouNew_LuckStar2_Info:SetText(ScriptGlobal_Format( "#{XSJNH_230209_25}", g_NewLuckyDraw_SignCount))
	for i = 1, 7 do
		--local itemAction = DataPool:CreateBindActionItemForShow(g_NewLuckyDraw_LJPrize[i].itemId, g_NewLuckyDraw_LJPrize[i].num)
		--if itemAction:GetID() ~= 0 then
		--	g_XinShouNew_LuckStar2_Action2[i]:SetActionItem(itemAction:GetID())
		--end
		g_XinShouNew_LuckStar2_Action2[i]:Show()
		g_XinShouNew_LuckStar2_Action2_Image[i]:Hide()
		g_XinShouNew_LuckStar2_Action2_Xin[i]:Hide()
		if g_NewLuckyDraw_LJ_Flag[i] == 1 then --已领取
			g_XinShouNew_LuckStar2_Action2[i]:Hide()
			g_XinShouNew_LuckStar2_Action2_Xin[i]:Show()
		else
			--可领取
			if g_NewLuckyDraw_SignCount >= g_NewLuckyDraw_TotalCount[i] and g_NewLuckyDraw_LJ_Flag[i] == 0 then
				g_XinShouNew_LuckStar2_Action2_Image[i]:Show()
			end
		end
	end
	if Player:GetData("Is2606S") == 1 then
		XinShouNew_LuckStar2_Frame3_Bk2_Icon1:SetToolTip("#{QXF_260623_135}")
		XinShouNew_LuckStar2_Frame3_Bk2_Icon5:SetToolTip("#{QXF_260623_136}")
	else
		XinShouNew_LuckStar2_Frame3_Bk2_Icon1:SetToolTip("#{XSJNH_230209_31}")
		XinShouNew_LuckStar2_Frame3_Bk2_Icon5:SetToolTip("#{XSJNH_230209_55}")
	end
end

function XinShouNew_LuckyDraw2023_DoSign(index) 
		-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLuckyDraw2023" ); 	
		Set_XSCRIPT_ScriptID( 998413 );	
		Set_XSCRIPT_Parameter( 0, index );			
		Set_XSCRIPT_ParamCount( 1 );		
	Send_XSCRIPT() 
end

function XinShouNew_LuckyDraw2023_GetLJPrize(index) 
		-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLJPrize" ); 	
		Set_XSCRIPT_ScriptID( 998413 );	
		Set_XSCRIPT_Parameter( 0, index );			
		Set_XSCRIPT_ParamCount( 1 );		
	Send_XSCRIPT() 
end