--******************************************************************************
-- 2019清明节抽奖活动
--页签1活动介绍
--页签2鉴宝
--页签3抽奖
--lmy  2019-02-28
--******************************************************************************
local g_Qingming_Frame_UnifiedPosition;

local g_Qingming_BeginTime 		= 20260402	--活动开始时间
local g_Qingming_EndTime 		= 20260415	--活动结束时间
local g_Qingming_FinalEndTime 	= 20260419	--活动结束时间
local g_Qingming_LimitLevel 	= 30		--活动限制等级
local g_Qingming_ButtonCDTime 	= 1 		--抽奖按钮冷却时间
local g_Qingming_FiveCDTime		= 5 		--五连抽按钮冷却时间
local g_Qingming_ExRewardCDTime = 7.5 		--额外抽奖按钮冷却时间
local g_Qingming_ButtonLastTime1= 0			--抽奖按钮冷却时间计时
local g_Qingming_ButtonLastTime2= 0			--抽奖按钮冷却时间计时
local g_Qingming_ButtonLastTime3= 0			--抽奖按钮冷却时间计时
local g_Qingming_MaxJackpot		= 8			--最大宴席数
local g_Qingming_FiveCount		= 5			--五连抽次数
local g_Qingming_CurJackpotIndex= 1			--当前宴席index 1-9

local g_Qingming_Client = {}			--4个分页
local g_Qingming_RedPoint = {}			--4个分页小红点
local g_Qingming_JackpotList = {}		--九个奖池按钮
local g_Qingming_JackpotTitleList = {}	--九个奖池按钮图片
--local g_Qingming_JackpotItemList = {}	--九个奖池按钮上的item

--预览界面
local g_Qingming_PreShowItemList = {}		--预览奖池
local g_Qingming_PreShowWind_Ex				--额外获得高级代币：锦灵珠
local g_Qingming_PreShowItem_Ex

--默认展示界面
local g_Qingming_TakeShowItemList = {}		--展示界面奖品剩余情况item
local g_Qingming_TakeShowItemTips = {}		--展示界面奖品剩余情况文本
local g_Qingming_TakeShowItem_Ex			--额外获得高级代币：锦灵珠
local g_Qingming_TakeShowItemTip_Ex
local g_Qingming_TakeShowItem_Bk

--抽一次奖界面
local g_Qingming_OneShowItemList = {}		--抽一次奖品剩余情况item
local g_Qingming_OneShowItemTips = {}		--抽一次奖品剩余情况文本
local g_Qingming_OneShowItem_Ex				--额外获得高级代币：锦灵珠
local g_Qingming_OneShowItemTip_Ex
local g_Qingming_OneShowItem_Bk

--抽五次奖界面
local g_Qingming_FiveItemList = {}			--抽五次后获得item
local g_Qingming_FiveItemBkList = {}		--抽五次后获得item 背景
local g_Qingming_UnComAnimeList = {}		--抽五次后获得item 稀有特效
local g_Qingming_FiveExIndex = 6			--五连抽额外奖励item索引号
local g_Qingming_FiveExItemShowId = 39921662--五连抽额外奖励item显示id
local g_Qingming_FiveIndex = 1				--五连抽动画顺序
local g_Qingming_RewardItemList = {}		--五连抽物品id缓存
local g_Qingming_FiveItemAnimeList = {}		--抽五次后获得item 每个的动画
local g_Qingming_FiveShowItemList = {}		--抽五次奖品剩余情况item
local g_Qingming_FiveShowItemTips = {}		--抽五次奖品剩余情况文本
local g_Qingming_FiveShowItem_Ex			--额外获得高级代币：锦灵珠
local g_Qingming_FiveShowItemTip_Ex
local g_Qingming_FiveShowItem_Bk

--额外抽奖界面
local g_Qingming_ExRewardList = {}			--额外抽奖九个额外奖励
local g_Qingming_ExMaskList = {}			--额外抽奖九个已抽取
local g_Qingming_ExLoopPicList = {}			--额外抽奖九个额外奖励图片
local g_Qingming_ExLoopAnimeList = {}		--额外抽奖九个额外奖励选中动画
local g_Qingming_ExTimerList = {}			--额外抽奖闪动数组
local g_Qingming_ExTimerIndex = 1			--额外抽奖闪动数组index
local g_Qingming_ExTimerCheckIndex = 1		--额外抽奖选中索引
local g_Qingming_RemainExItemNo = 9			--额外抽奖选中索引

-- 青团界面
local g_state1 = 0
local g_state2 = 0
local g_state3 = 0
local g_minute = 0

local g_redpoint_1 = 0
local g_redpoint_2 = 0
local g_redpoint_3 = 0
local g_activepoint = 0
local g_redpoint2 = 0
local g_sheet = 1
local g_2018QingMing_Start = 20260327
local g_2018QingMing_End = 20260415

--宴席图标展示id
local g_Qingming_JackpotItemEnum = 
{
	[1] = 39920329,
	[2] = 39920490,
	[3] = 39920397,
	[4] = 39920396,
	[5] = 39921389,
	[6] = 39920396,
	[7] = 39920397,
	[8] = 39920490,
	[9] = 39920329,
}	

--额外奖励列表
local g_Qingming_ExItemEnum = {
	[0] = {
		[1] = {Id=50232009, ShowID = 39921660},
		[2] = {Id=38005556, ShowID = 39924117},
		[3] = {Id=30503202, ShowID = 39921734},
		[4] = {Id=20502004, ShowID = 39920566},
		[5] = {Id=20501004, ShowID = 39920565},
		[6] = {Id=38000438, ShowID = 39921360},
		[7] = {Id=10126702, ShowID = 10126702},
		[8] = {Id=10141452, ShowID = 39921287},
		[9] = {Id=38000437, ShowID = 39921377},
	},
	[1] = {
		[1] = {Id=50232009, ShowID = 39921660},
		[2] = {Id=38006281, ShowID = 39924116},
		[3] = {Id=30503202, ShowID = 39921734},
		[4] = {Id=20502004, ShowID = 39920566},
		[5] = {Id=20501004, ShowID = 39920565},
		[6] = {Id=20500004, ShowID = 39923638},
		[7] = {Id=10126702, ShowID = 10126702},
		[8] = {Id=10141452, ShowID = 39921287},
		[9] = {Id=10124468, ShowID = 39923637},
	}
}


--===============================================
-- OnLoad()
--===============================================
function Qingming_PreLoad()
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
	
end

function Qingming_OnLoad()
	-- 保存界面的默认相对位置
	g_Qingming_Frame_UnifiedPosition = Qingming_FrameNULL:GetProperty("UnifiedPosition");
	
	--4个分页
	g_Qingming_Client[1] = Qingming_Client1
	g_Qingming_Client[2] = Qingming_Client2
	g_Qingming_Client[3] = Qingming_Client3
	g_Qingming_Client[4] = Qingming_Client4
	--4个分页小红点
	g_Qingming_RedPoint[1] = Qingming_Buttontab01_Tips
	g_Qingming_RedPoint[2] = Qingming_Buttontab02_Tips
	g_Qingming_RedPoint[3] = Qingming_Buttontab03_Tips
	g_Qingming_RedPoint[4] = Qingming_Buttontab04_Tips
	
	--奖池
	g_Qingming_JackpotList[1] = Qingming_Client3_tab1
	g_Qingming_JackpotList[2] = Qingming_Client3_tab2
	g_Qingming_JackpotList[3] = Qingming_Client3_Tab3
	g_Qingming_JackpotList[4] = Qingming_Client3_Tab4
	g_Qingming_JackpotList[5] = Qingming_Client3_Tab5
	g_Qingming_JackpotList[6] = Qingming_Client3_Tab6
	g_Qingming_JackpotList[7] = Qingming_Client3_Tab7
	g_Qingming_JackpotList[8] = Qingming_Client3_Tab8
	g_Qingming_JackpotList[9] = Qingming_Client3_Tab9
	g_Qingming_JackpotTitleList[1] = Qingming_Client3_tab1Text2
	g_Qingming_JackpotTitleList[2] = Qingming_Client3_tab2Text2
	g_Qingming_JackpotTitleList[3] = Qingming_Client3_tab3Text2
	g_Qingming_JackpotTitleList[4] = Qingming_Client3_tab4Text2
	g_Qingming_JackpotTitleList[5] = Qingming_Client3_tab5Text2
	g_Qingming_JackpotTitleList[6] = Qingming_Client3_tab6Text2
	g_Qingming_JackpotTitleList[7] = Qingming_Client3_tab7Text2
	g_Qingming_JackpotTitleList[8] = Qingming_Client3_tab8Text2
	g_Qingming_JackpotTitleList[9] = Qingming_Client3_tab9Text2

	
	-- g_Qingming_JackpotItemList[1] = Qingming_Client3_tab1Item
	-- g_Qingming_JackpotItemList[2] = Qingming_Client3_tab2Item
	-- g_Qingming_JackpotItemList[3] = Qingming_Client3_Tab3Item
	-- g_Qingming_JackpotItemList[4] = Qingming_Client3_Tab4Item
	-- g_Qingming_JackpotItemList[5] = Qingming_Client3_Tab5Item
	-- g_Qingming_JackpotItemList[6] = Qingming_Client3_Tab6Item
	-- g_Qingming_JackpotItemList[7] = Qingming_Client3_Tab7Item
	-- g_Qingming_JackpotItemList[8] = Qingming_Client3_Tab8Item
	-- g_Qingming_JackpotItemList[9] = Qingming_Client3_Tab9Item
	
	--预览界面
	g_Qingming_PreShowItemList[1] = Qingming_Client3_Show_Item1
	g_Qingming_PreShowItemList[2] = Qingming_Client3_Show_Item2
	g_Qingming_PreShowItemList[3] = Qingming_Client3_Show_Item3
	g_Qingming_PreShowItemList[4] = Qingming_Client3_Show_Item4
	g_Qingming_PreShowItemList[5] = Qingming_Client3_Show_Item5
	g_Qingming_PreShowItemList[6] = Qingming_Client3_Show_Item6
	g_Qingming_PreShowItemList[7] = Qingming_Client3_Show_Item7
	g_Qingming_PreShowItemList[8] = Qingming_Client3_Show_Item8
	g_Qingming_PreShowItemList[9] = Qingming_Client3_Show_Item9
	g_Qingming_PreShowItemList[10] = Qingming_Client3_Show_Item10
	g_Qingming_PreShowItemList[11] = Qingming_Client3_Show_Item11
	g_Qingming_PreShowItemList[12] = Qingming_Client3_Show_Item12
	g_Qingming_PreShowItemList[13] = Qingming_Client3_Show_Item13
	g_Qingming_PreShowItemList[14] = Qingming_Client3_Show_Item14
	g_Qingming_PreShowItemList[15] = Qingming_Client3_Show_Item15
	g_Qingming_PreShowItemList[16] = Qingming_Client3_Show_Item16
	g_Qingming_PreShowItemList[17] = Qingming_Client3_Show_Item17
	g_Qingming_PreShowItemList[18] = Qingming_Client3_Show_Item18
	g_Qingming_PreShowItemList[19] = Qingming_Client3_Show_Item19
	g_Qingming_PreShowItemList[20] = Qingming_Client3_Show_Item20
	g_Qingming_PreShowItemList[21] = Qingming_Client3_Show_Item21
	g_Qingming_PreShowItemList[22] = Qingming_Client3_Show_Item22
	g_Qingming_PreShowItemList[23] = Qingming_Client3_Show_Item23
	g_Qingming_PreShowItemList[24] = Qingming_Client3_Show_Item24
	g_Qingming_PreShowItemList[25] = Qingming_Client3_Show_Item25
	g_Qingming_PreShowItemList[26] = Qingming_Client3_Show_Item26
	g_Qingming_PreShowItemList[27] = Qingming_Client3_Show_Item27
	g_Qingming_PreShowItemList[28] = Qingming_Client3_Show_Item28
	g_Qingming_PreShowItemList[29] = Qingming_Client3_Show_Item29
	g_Qingming_PreShowItemList[30] = Qingming_Client3_Show_Item30

	-- 额外奖励高级代币
	g_Qingming_PreShowWind_Ex = Qingming_Client3_ShowGiftInfo
	g_Qingming_PreShowItem_Ex = Qingming_Client3_Show_GiftInfo_Item
	
	--默认界面
	g_Qingming_TakeShowItem_Bk = Qingming_Client3_Take_NumClient
	g_Qingming_TakeShowItemList[1] = Qingming_Client3_Take_NumItem1
	g_Qingming_TakeShowItemList[2] = Qingming_Client3_Take_NumItem2
	g_Qingming_TakeShowItemList[3] = Qingming_Client3_Take_NumItem3
	g_Qingming_TakeShowItemList[4] = Qingming_Client3_Take_NumItem4
	if Qingming_Client3_Take_NumItem5 then
		g_Qingming_TakeShowItem_Ex = Qingming_Client3_Take_NumItem5
	else
		g_Qingming_TakeShowItem_Ex = nil
	end
	g_Qingming_TakeShowItemTips[1] = Qingming_Client3_Take_NumItem1Text
	g_Qingming_TakeShowItemTips[2] = Qingming_Client3_Take_NumItem2Text
	g_Qingming_TakeShowItemTips[3] = Qingming_Client3_Take_NumItem3Text
	g_Qingming_TakeShowItemTips[4] = Qingming_Client3_Take_NumItem4Text
	if Qingming_Client3_Take_NumItem5Text then
		g_Qingming_TakeShowItemTip_Ex = Qingming_Client3_Take_NumItem5Text
	else
		g_Qingming_TakeShowItemTip_Ex = nil
	end
	
	--一抽后
	g_Qingming_OneShowItem_Bk = Qingming_Client3_ResultOne_NumClient
	g_Qingming_OneShowItemList[1] = Qingming_Client3_ResultOne_NumItem1
	g_Qingming_OneShowItemList[2] = Qingming_Client3_ResultOne_NumItem2
	g_Qingming_OneShowItemList[3] = Qingming_Client3_ResultOne_NumItem3
	g_Qingming_OneShowItemList[4] = Qingming_Client3_ResultOne_NumItem4
	if Qingming_Client3_ResultOne_NumItem5 then
		g_Qingming_OneShowItem_Ex = Qingming_Client3_ResultOne_NumItem5
	else
		g_Qingming_OneShowItem_Ex = nil
	end
	g_Qingming_OneShowItemTips[1] = Qingming_Client3_ResultOne_NumItem1Text
	g_Qingming_OneShowItemTips[2] = Qingming_Client3_ResultOne_NumItem2Text
	g_Qingming_OneShowItemTips[3] = Qingming_Client3_ResultOne_NumItem3Text
	g_Qingming_OneShowItemTips[4] = Qingming_Client3_ResultOne_NumItem4Text
	if Qingming_Client3_ResultOne_NumItem5Text then
		g_Qingming_OneShowItemTip_Ex = Qingming_Client3_ResultOne_NumItem5Text
	else
		g_Qingming_OneShowItemTip_Ex = nil
	end
	
	--抽五次后
	g_Qingming_FiveItemList[1] = Qingming_Client3_ResultFive_Item1
	g_Qingming_FiveItemList[2] = Qingming_Client3_ResultFive_Item2
	g_Qingming_FiveItemList[3] = Qingming_Client3_ResultFive_Item3
	g_Qingming_FiveItemList[4] = Qingming_Client3_ResultFive_Item4
	g_Qingming_FiveItemList[5] = Qingming_Client3_ResultFive_Item5
	g_Qingming_FiveItemList[6] = Qingming_Client3_ResultFive_Item6
	g_Qingming_FiveItemBkList[1] = Qingming_Client3_ResultFive_Item1BK
	g_Qingming_FiveItemBkList[2] = Qingming_Client3_ResultFive_Item2BK
	g_Qingming_FiveItemBkList[3] = Qingming_Client3_ResultFive_Item3BK
	g_Qingming_FiveItemBkList[4] = Qingming_Client3_ResultFive_Item4BK
	g_Qingming_FiveItemBkList[5] = Qingming_Client3_ResultFive_Item5BK
	g_Qingming_FiveItemBkList[6] = Qingming_Client3_ResultFive_Item6BK
	g_Qingming_UnComAnimeList[1] = Qingming_Client3_ResultFive_Item1_Animate
	g_Qingming_UnComAnimeList[2] = Qingming_Client3_ResultFive_Item2_Animate
	g_Qingming_UnComAnimeList[3] = Qingming_Client3_ResultFive_Item3_Animate
	g_Qingming_UnComAnimeList[4] = Qingming_Client3_ResultFive_Item4_Animate
	g_Qingming_UnComAnimeList[5] = Qingming_Client3_ResultFive_Item5_Animate
	g_Qingming_UnComAnimeList[6] = Qingming_Client3_ResultFive_Item6_Animate
	g_Qingming_FiveItemAnimeList[1] = Qingming_Client3_ResultFive_Animate1
	g_Qingming_FiveItemAnimeList[2] = Qingming_Client3_ResultFive_Animate2
	g_Qingming_FiveItemAnimeList[3] = Qingming_Client3_ResultFive_Animate3
	g_Qingming_FiveItemAnimeList[4] = Qingming_Client3_ResultFive_Animate4
	g_Qingming_FiveItemAnimeList[5] = Qingming_Client3_ResultFive_Animate5
	g_Qingming_FiveItemAnimeList[6] = Qingming_Client3_ResultFive_Item6_Animate2
	
	g_Qingming_FiveShowItem_Bk = Qingming_Client3_ResultFive_NumClient
	g_Qingming_FiveShowItemList[1] = Qingming_Client3_ResultFive_NumItem1
	g_Qingming_FiveShowItemList[2] = Qingming_Client3_ResultFive_NumItem2
	g_Qingming_FiveShowItemList[3] = Qingming_Client3_ResultFive_NumItem3
	g_Qingming_FiveShowItemList[4] = Qingming_Client3_ResultFive_NumItem4
	if Qingming_Client3_ResultFive_NumItem5 then
		g_Qingming_FiveShowItem_Ex = Qingming_Client3_ResultFive_NumItem5
	else
		g_Qingming_FiveShowItem_Ex = nil
	end
	g_Qingming_FiveShowItemTips[1] = Qingming_Client3_ResultFive_NumItem1Text
	g_Qingming_FiveShowItemTips[2] = Qingming_Client3_ResultFive_NumItem2Text
	g_Qingming_FiveShowItemTips[3] = Qingming_Client3_ResultFive_NumItem3Text
	g_Qingming_FiveShowItemTips[4] = Qingming_Client3_ResultFive_NumItem4Text
	if Qingming_Client3_ResultFive_NumItem5Text then
		g_Qingming_FiveShowItemTip_Ex = Qingming_Client3_ResultFive_NumItem5Text
	else
		g_Qingming_FiveShowItemTip_Ex = nil
	end

	--额外奖励
	g_Qingming_ExRewardList[1] = Qingming_Client4_Item1
	g_Qingming_ExRewardList[2] = Qingming_Client4_Item2
	g_Qingming_ExRewardList[3] = Qingming_Client4_Item3
	g_Qingming_ExRewardList[4] = Qingming_Client4_Item4
	g_Qingming_ExRewardList[5] = Qingming_Client4_Item5
	g_Qingming_ExRewardList[6] = Qingming_Client4_Item6
	g_Qingming_ExRewardList[7] = Qingming_Client4_Item7
	g_Qingming_ExRewardList[8] = Qingming_Client4_Item8
	g_Qingming_ExRewardList[9] = Qingming_Client4_Item9
	g_Qingming_ExMaskList[1] = Qingming_Client4_Item1_Mask
	g_Qingming_ExMaskList[2] = Qingming_Client4_Item2_Mask
	g_Qingming_ExMaskList[3] = Qingming_Client4_Item3_Mask
	g_Qingming_ExMaskList[4] = Qingming_Client4_Item4_Mask
	g_Qingming_ExMaskList[5] = Qingming_Client4_Item5_Mask
	g_Qingming_ExMaskList[6] = Qingming_Client4_Item6_Mask
	g_Qingming_ExMaskList[7] = Qingming_Client4_Item7_Mask
	g_Qingming_ExMaskList[8] = Qingming_Client4_Item8_Mask
	g_Qingming_ExMaskList[9] = Qingming_Client4_Item9_Mask
	g_Qingming_ExLoopPicList[1] = Qingming_Client4_Item1Light
	g_Qingming_ExLoopPicList[2] = Qingming_Client4_Item2Light
	g_Qingming_ExLoopPicList[3] = Qingming_Client4_Item3Light
	g_Qingming_ExLoopPicList[4] = Qingming_Client4_Item4Light
	g_Qingming_ExLoopPicList[5] = Qingming_Client4_Item5Light
	g_Qingming_ExLoopPicList[6] = Qingming_Client4_Item6Light
	g_Qingming_ExLoopPicList[7] = Qingming_Client4_Item7Light
	g_Qingming_ExLoopPicList[8] = Qingming_Client4_Item8Light
	g_Qingming_ExLoopPicList[9] = Qingming_Client4_Item9Light
	g_Qingming_ExLoopAnimeList[1] = Qingming_Client4_Item1_Animate
	g_Qingming_ExLoopAnimeList[2] = Qingming_Client4_Item2_Animate
	g_Qingming_ExLoopAnimeList[3] = Qingming_Client4_Item3_Animate
	g_Qingming_ExLoopAnimeList[4] = Qingming_Client4_Item4_Animate
	g_Qingming_ExLoopAnimeList[5] = Qingming_Client4_Item5_Animate
	g_Qingming_ExLoopAnimeList[6] = Qingming_Client4_Item6_Animate
	g_Qingming_ExLoopAnimeList[7] = Qingming_Client4_Item7_Animate
	g_Qingming_ExLoopAnimeList[8] = Qingming_Client4_Item8_Animate
	g_Qingming_ExLoopAnimeList[9] = Qingming_Client4_Item9_Animate

end


--===============================================
-- OnEvent()
--===============================================

function Qingming_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 50508002) then
		if(IsWindowShow("Qingming")) then
			CloseWindow("Qingming", true)
		end
		if Get_XParam_INT(0) == 1 then
			--打开主界面
			Qingming_OpenFenye( 1 ,Get_XParam_INT(1))
			this:Show()
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 50508007) then
		if(IsWindowShow("Qingming")) then
			Qingming_OpenFenye( 1 ,1)
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508005) then
		--更新小红点
		--PushDebugMessage("nFlag1="..Get_XParam_INT(0).."  nFlag2="..Get_XParam_INT(1).."  nFlag3="..Get_XParam_INT(2).."  nFlag4="..Get_XParam_INT(3))
		Qingming_UpdateRedPoint( Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3) )
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508003) then
		--更新到再抽一次界面
		Qingming_JackpotResultOne(Get_XParam_INT(0), Get_XParam_INT(1))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508004) then
		--更新到再抽5次界面
		Qingming_JackpotResultFive(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),
			Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508101) then
		--打开额外抽奖界面
		Qingming_OpenFenye( 4 ,0)
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508102) then
		--更新额外抽奖界面
		 Qingming_OpenExRewardAnime(Get_XParam_INT(0))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508103) then
		--更新补偿按钮 2021年重开用不上
		-- Qingming_RefreshBuChangBtn(Get_XParam_INT(0),Get_XParam_INT(1))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89272102) then
		-- 刷新青团界面	
		if Get_XParam_INT(0) == 0 then
			if this:IsVisible() then
			else
				return
			end
		else
			g_sheet = Get_XParam_INT(0)
		end
		g_state1 = Get_XParam_INT(1)
		g_state2 = Get_XParam_INT(2)
		g_state3 = Get_XParam_INT(3)
		g_minute = Get_XParam_INT(4)				
		g_activepoint = Get_XParam_INT(5) 
			
		if g_state1 == 1 then
			g_redpoint_1 = 1
		else
			g_redpoint_1 = 0
		end
		if g_state2 == 1 then
			g_redpoint_2 = 1
		else
			g_redpoint_2 = 0
		end
		if g_state3 == 1 then
			g_redpoint_3 = 1
		else
			g_redpoint_3 = 0
		end			
		
		Qingming_UpdateUI( g_sheet )
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Qingming_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Qingming_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Qingming_OnHiden()
	end
end
	
	
--===============================================
-- OnHiden
--===============================================
function Qingming_OnHiden()
	KillTimer("Qingming_FiveAnimeTimer()")
	KillTimer("Qingming_OneAnimeTimer()")
	KillTimer("Qingming_ExItemAnimeTimer()")
	KillTimer("Qingming_ExItemCheckTimer()")
	g_Qingming_ButtonLastTime1 = 0
	g_Qingming_ButtonLastTime2 = 0
	g_Qingming_ButtonLastTime3 = 0
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Qingming_Frame_On_ResetPos()
	Qingming_FrameNULL:SetProperty("UnifiedPosition", g_Qingming_Frame_UnifiedPosition);
end


--**********************************************
--初始化界面
--**********************************************
function Qingming_OpenFenye( nIndex ,nGiftFlag)
	-- 隐藏那些废弃的控件
	if Qingming_Client3_Tab5Client_Image and Qingming_Client3_Tab5Client_Image:IsVisible() then
		Qingming_Client3_Tab5Client_Image:Hide()
	end
	Qingming_ShowItemAlreadyGetEx(g_Qingming_TakeShowItem_Ex, g_Qingming_TakeShowItemTip_Ex, g_Qingming_TakeShowItem_Bk)
	Qingming_ShowItemAlreadyGetEx(g_Qingming_OneShowItem_Ex, g_Qingming_OneShowItemTip_Ex, g_Qingming_OneShowItem_Bk)
	Qingming_ShowItemAlreadyGetEx(g_Qingming_FiveShowItem_Ex, g_Qingming_FiveShowItemTip_Ex, g_Qingming_FiveShowItem_Bk)


	--判断
	if nIndex < 1 or nIndex > 4 then
		return
	end
	
	--等级和事件判断
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay < g_Qingming_BeginTime or curDay > g_Qingming_FinalEndTime then
		PushDebugMessage("#{QMCJ_190310_07}")
		return
	end
	
	if nIndex == 2 and (curDay < g_2018QingMing_Start or curDay > g_2018QingMing_End) then
		PushDebugMessage("#{QMCJ_190310_07}")
		return
	end
	
	local nLevel = Player:GetLevel();
	if nLevel < g_Qingming_LimitLevel then
		PushDebugMessage("#{QMCJ_190310_08}")
		return
	end
	
	--分页逻辑
	for index=1,table.getn(g_Qingming_Client)  do
		if index == nIndex then
			g_Qingming_Client[index]:Show()
		else
			g_Qingming_Client[index]:Hide()
		end
	end
	
	--按钮选中状态
	if nIndex == 1 then
		Qingming_Buttontab01:SetCheck(1)
		Qingming_Buttontab02:SetCheck(0)
		Qingming_Buttontab03:SetCheck(0)
		Qingming_Buttontab04:SetCheck(0)
	elseif nIndex == 2 then
		Qingming_Buttontab01:SetCheck(0)
		Qingming_Buttontab02:SetCheck(1)
		Qingming_Buttontab03:SetCheck(0)
		Qingming_Buttontab04:SetCheck(0)
	elseif nIndex == 3 then
		Qingming_Buttontab01:SetCheck(0)
		Qingming_Buttontab02:SetCheck(0)
		Qingming_Buttontab03:SetCheck(1)
		Qingming_Buttontab04:SetCheck(0)
	elseif nIndex == 3 then
		Qingming_Buttontab01:SetCheck(0)
		Qingming_Buttontab02:SetCheck(0)
		Qingming_Buttontab03:SetCheck(0)
		Qingming_Buttontab04:SetCheck(1)
	end
	
	--展示奖池
	if nIndex == 3 then
		--背包互斥
		if(IsWindowShow("Packet")) then
			CloseWindow("Packet", true);
		end 
		Qingming_JackpotInfo()
	elseif nIndex == 4 then
		--背包互斥
		if(IsWindowShow("Packet")) then
			CloseWindow("Packet", true);
		end 
		--额外抽奖界面
		Qingming_OpenExReward()
	elseif nIndex == 2 then		
		-- 请求数据
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Open2018QingMing")
			Set_XSCRIPT_ScriptID(892721)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		--g_Qingming_RedPoint[3]:Hide() -- 把小红点隐了
	elseif nIndex == 1 then
		if nGiftFlag < 1 then
			-- 请求数据
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OpenWindowRequest")
				Set_XSCRIPT_ScriptID(505080)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		else
			--0+1 不可以领取   1+1 可以领取  2+1过时间了
			if nGiftFlag == 2 then
				--领取礼包小红点
				Qingming_GiftBtn_Received:Hide()
				Qingming_GiftBtn:Show()
				Qingming_GiftBtn:Enable()
				Qingming_GiftBtn_Tips:Show()
			else
				Qingming_GiftBtn_Received:Hide()
				Qingming_GiftBtn:Hide()
				Qingming_GiftBtn_Tips:Hide()
			end
		end
	end
	--小红点逻辑
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PageClicked")
		Set_XSCRIPT_ScriptID(505080)
		Set_XSCRIPT_Parameter( 0 ,nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	
	--动画重置
	KillTimer("Qingming_FiveAnimeTimer()")
	KillTimer("Qingming_OneAnimeTimer()")
	KillTimer("Qingming_ExItemAnimeTimer()")
	KillTimer("Qingming_ExItemCheckTimer()")
	g_Qingming_ButtonLastTime1 = 0
	g_Qingming_ButtonLastTime2 = 0
	g_Qingming_ButtonLastTime3 = 0
end

--================================================
-- 奖池界面处理 
-- 九个按钮的显示状态
--================================================
function Qingming_NineBtnState( nOptionIndex )
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetQingmingJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Qingming_MaxJackpot 
		or nOptionIndex < 1 or nOptionIndex > 9 then
		PushDebugMessage("Qingming_JackpotInfo Data error")
		return
	end
	g_Qingming_CurJackpotIndex = nOptionIndex
	--九个按钮显示状态
	for index=1,table.getn(g_Qingming_JackpotList)  do
		if index < mCurJackpotIndex + 1 then
			g_Qingming_JackpotList[index]:Disable()
			--g_Qingming_JackpotItemList[index]:Hide()
			g_Qingming_JackpotList[index]:SetCheck(0)
			g_Qingming_JackpotTitleList[index]:Hide()
			g_Qingming_JackpotList[index]:SetToolTip("#{QMCJ_190310_26}")	
		elseif index  == mCurJackpotIndex + 1 then
			g_Qingming_JackpotList[index]:Enable()
			-- local theAction = DataPool:CreateActionItemForShow(g_Qingming_JackpotItemEnum[index], 1)
			-- if theAction:GetID() ~= 0 then
				-- g_Qingming_JackpotItemList[index]:SetActionItem(theAction:GetID());
				-- g_Qingming_JackpotItemList[index]:Show()
			-- else
				-- g_Qingming_JackpotItemList[index]:Hide()
			-- end
			g_Qingming_JackpotList[index]:SetCheck(1)
			g_Qingming_JackpotTitleList[index]:Show()
			local totalTimes,useTimes = DataPool:Lua_QingmingJackpotTimes();
			local curJackRemain = ScriptGlobal_Format("#{QMCJ_190310_27}",totalTimes-useTimes)
			g_Qingming_JackpotList[index]:SetToolTip(curJackRemain)	
		else
			g_Qingming_JackpotList[index]:Enable()
			-- local theAction = DataPool:CreateActionItemForShow(g_Qingming_JackpotItemEnum[index], 1)
			-- if theAction:GetID() ~= 0 then
				-- g_Qingming_JackpotItemList[index]:SetActionItem(theAction:GetID());
				-- g_Qingming_JackpotItemList[index]:Show()
			-- else
				-- g_Qingming_JackpotItemList[index]:Hide()
			-- end
			g_Qingming_JackpotList[index]:SetCheck(0)
			g_Qingming_JackpotTitleList[index]:Hide()
			g_Qingming_JackpotList[index]:SetToolTip("#{QMCJ_190310_28}")	
		end
	end
end

--================================================
-- 奖池界面处理 
-- 默认界面
--================================================
function Qingming_JackpotInfo()
	Qingming_Client3_Show:Hide()
	Qingming_Client3_Take:Show()
	Qingming_Client3_ResultOne:Hide()
	Qingming_Client3_ResultFive:Hide()

	--初始化信息
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetQingmingJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Qingming_MaxJackpot then
		PushDebugMessage("Qingming_JackpotInfo Data error")
		return
	end
	g_Qingming_CurJackpotIndex = mCurJackpotIndex + 1
	Qingming_NineBtnState( g_Qingming_CurJackpotIndex )
	
	--可上菜数量
	local totalTimes,useTimes = DataPool:Lua_QingmingJackpotTimes();
	local nJackRemainNum = totalTimes-useTimes
	local curJackRemain = ScriptGlobal_Format("#{QMCJ_190310_30}",nJackRemainNum,totalTimes)
	Qingming_Client3_Take_FeastNum:SetText(curJackRemain)	
	
	--代币数显示
	local nDaibi1 = DataPool:Lua_QingmingNum()
	if nDaibi1 > 0 then
		Qingming_Client3_Take_NowNum1:SetText(ScriptGlobal_Format("#{QMCJ_190310_33}",nDaibi1))--代币1
		Qingming_Client3_TakeOneBtn:SetToolTip("#{QMCJ_190310_39}")	--悬浮tips
	else
		Qingming_Client3_Take_NowNum1:SetText(ScriptGlobal_Format("#{QMCJ_190310_34}",nDaibi1)) --代币1
		Qingming_Client3_TakeOneBtn:SetToolTip("#{QMCJ_190310_38}")	--悬浮tips
	end
	
	--五抽按钮tips
	if nDaibi1 >= g_Qingming_FiveCount then
		if nJackRemainNum >= g_Qingming_FiveCount then
			Qingming_Client3_TakeFiveBtn:SetToolTip("#{QMCJ_190310_44}")	--悬浮tips
		else
			Qingming_Client3_TakeFiveBtn:SetToolTip("#{QMCJ_190310_43}")	--悬浮tips
		end
	else
		Qingming_Client3_TakeFiveBtn:SetToolTip("#{QMCJ_190310_42}")	--悬浮tips
	end
		
		
	local nDaibi2 = DataPool:Lua_QingmingExNum()
	if nDaibi2 > 0 then
		Qingming_Client3_Take_NowNum2:SetText(ScriptGlobal_Format("#{QMCJ_190310_35}",nDaibi2)) --代币2
	else
		Qingming_Client3_Take_NowNum2:SetText(ScriptGlobal_Format("#{QMCJ_190310_36}",nDaibi2)) --代币2
	end

	

	--宴会名字
	local curImgName = Qingming_GetFeastImgName(g_Qingming_CurJackpotIndex)
	Qingming_Client3_TakeTitle:SetProperty("Image", curImgName);
	
	--显示奖池剩余情况
	for index=1,table.getn(g_Qingming_TakeShowItemList)  do
		g_Qingming_TakeShowItemList[index]:Hide()
		g_Qingming_TakeShowItemTips[index]:Hide()
	end
	
	local remainKind = DataPool:Lua_QingmingJackRemainKind();
	if remainKind > 0 then
		for index=1,remainKind do
			local remainID,remainNum,totalNum = DataPool:Lua_QingmingJackRemainInfo(index-1);
			--PushDebugMessage("remainID="..remainID.."  remainNum="..remainNum.."  totalNum"..totalNum)
			if remainID > 0 then
				--显示item
				local theAction = DataPool:CreateActionItemForShow(remainID, 1)
				if theAction:GetID() ~= 0 then
					g_Qingming_TakeShowItemList[index]:SetActionItem(theAction:GetID());
					g_Qingming_TakeShowItemList[index]:Show()
					g_Qingming_TakeShowItemTips[index]:Show()
					--显示剩余
					if remainNum > 0 then
						g_Qingming_TakeShowItemTips[index]:SetText(ScriptGlobal_Format("#{QMCJ_190310_90}",remainNum,totalNum))
					else
						g_Qingming_TakeShowItemTips[index]:SetText(ScriptGlobal_Format("#{QMCJ_190310_91}",remainNum,totalNum))
					end
				end
			end
		end
	end

	Qingming_SetJinLingZhuVisible()
	
end
--================================================
-- 奖池界面处理
-- 预览界面
--================================================
function Qingming_JackpotPreShow(nOptionIndex)
	--判断
	if nOptionIndex < 1 or nOptionIndex > 9 then
		return
	end

	--显示界面
	Qingming_Client3_Show:Show()
	Qingming_Client3_Take:Hide()
	Qingming_Client3_ResultOne:Hide()
	Qingming_Client3_ResultFive:Hide()
	
	--赋值
	g_Qingming_CurJackpotIndex = nOptionIndex
	
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetQingmingJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Qingming_MaxJackpot then
		PushDebugMessage("Qingming_JackpotPreShow Data error")
		return
	end
	
	--PushDebugMessage("正在预览宴会号"..nOptionIndex.." 在抽奖池为"..mCurJackpotIndex)
	Qingming_NineBtnState( nOptionIndex )
	
	--可上菜数量
	local totalTimes = DataPool:Lua_PreQingmingJackpotTimes(nOptionIndex - 1);
	local curJackRemain = ScriptGlobal_Format("#{QMCJ_190310_92}",totalTimes,totalTimes)
	Qingming_Client3_Show_FeastNum:SetText(curJackRemain)	
	
	--开启条件
	local curConditionText = ScriptGlobal_Format("#{QMCJ_190310_55}",Qingming_GetFeastName(nOptionIndex - 1))
	Qingming_Client3_Show_Condition:SetText(curConditionText)
	
	--预览宴名字
	local preImgName = Qingming_GetFeastImgName(nOptionIndex)
	Qingming_Client3_ShowTitle:SetProperty("Image", preImgName);
	
	--获取预览信息
	local preNum,PreInfo =	DataPool:Lua_QingmingShowInfo(nOptionIndex -1);
	if preNum < 0 then
		PushDebugMessage("preNum Data error")
		return
	end

	--PushDebugMessage("预览信息  preNum="..preNum.."  PreInfo="..PreInfo)	
	--奖池物品
	--先隐藏
	for index=1,table.getn(g_Qingming_PreShowItemList)  do
		--不够了隐藏
		g_Qingming_PreShowItemList[index]:Hide()
	end
	local PreInfoList = Qingming_Split( PreInfo,"," ) --index List
	local nShowIndex = 1
	for index=1,table.getn(PreInfoList)  do
		local nItemId,isUnCommon ,nItemNum= DataPool:Lua_QingmingRewardInfo(tonumber(PreInfoList[index]))
		for showList=1,nItemNum  do
			--显示item
			local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
			if theAction:GetID() ~= 0 then
				g_Qingming_PreShowItemList[nShowIndex]:SetActionItem(theAction:GetID());
				g_Qingming_PreShowItemList[nShowIndex]:Show()
			else
				g_Qingming_PreShowItemList[nShowIndex]:Hide()
			end	
			nShowIndex = nShowIndex + 1
		end
	end		

	Qingming_SetJinLingZhuVisible()
end

--================================================
-- 奖池界面处理
-- 抽奖结果
--================================================
function Qingming_JackpotResultOne(nTablIndex, nGetDaiBi)
	Qingming_Client3_Show:Hide()
	Qingming_Client3_Take:Hide()
	Qingming_Client3_ResultOne:Show()
	Qingming_Client3_ResultFive:Hide()

	Qingming_Client3_ResultOne_Item2:Hide()
	Qingming_Client3_ResultOne_Item2Client:Hide()
	Qingming_Client3_ResultOne_Item2_Animate2:Play(false)
	Qingming_Client3_ResultOne_Item2_Animate:Play(false)
	
	--九个按钮状态
	local mCurJackpotIndex = DataPool:Lua_GetQingmingJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Qingming_MaxJackpot then
		PushDebugMessage("Qingming_JackpotInfo Data error")
		return
	end
	Qingming_NineBtnState( mCurJackpotIndex + 1 )
	 
	--可上菜数量
	local totalTimes,useTimes = DataPool:Lua_QingmingJackpotTimes();
	local curJackRemain = ScriptGlobal_Format("#{QMCJ_190310_30}",totalTimes-useTimes,totalTimes)
	Qingming_Client3_ResultOne_FeastNum:SetText(curJackRemain)	
	
	--剩余佳肴
	--代币数显示
	local nDaibi1 = DataPool:Lua_QingmingNum()
	if nDaibi1 > 0 then
		Qingming_Client3_ResultOne_NowNum1:SetText(ScriptGlobal_Format("#{QMCJ_190310_33}",nDaibi1)) --代币1
		Qingming_Client3_ResultOne_Again:SetToolTip("#{QMCJ_190310_39}")	--悬浮tips
	else
		Qingming_Client3_ResultOne_NowNum1:SetText(ScriptGlobal_Format("#{QMCJ_190310_34}",nDaibi1)) --代币1
		Qingming_Client3_ResultOne_Again:SetToolTip("#{QMCJ_190310_38}")	--悬浮tips
	end
	
	local nDaibi2 = DataPool:Lua_QingmingExNum()
	if nDaibi2 > 0 then
		Qingming_Client3_ResultOne_NowNum2:SetText(ScriptGlobal_Format("#{QMCJ_190310_35}",nDaibi2)) --代币2
	else
		Qingming_Client3_ResultOne_NowNum2:SetText(ScriptGlobal_Format("#{QMCJ_190310_36}",nDaibi2)) --代币2
	end
	
	
	--宴会名字
	local nowImgName = Qingming_GetFeastImgName(mCurJackpotIndex + 1)
	Qingming_Client3_ResultOneTitle:SetProperty("Image", nowImgName);
	
	--奖励item信息
	--PushDebugMessage("JackpotResultOne nTablIndex="..nTablIndex)
	local nItemId,isUnCommon = DataPool:Lua_QingmingRewardInfo(nTablIndex)
	if nItemId < 0 then
		PushDebugMessage("JackpotResultOne nTablIndex error"..nTablIndex)
		return
	end
	--显示item
	local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
	if theAction:GetID() ~= 0 then
		Qingming_Client3_ResultOne_Item:SetActionItem(theAction:GetID());
		Qingming_Client3_ResultOne_Item:Show()
	else
		Qingming_Client3_ResultOne_Item:Hide()
	end
	
	Qingming_Client3_ResultOne_Animate:Show()
	Qingming_Client3_ResultOne_Animate:Play(true)
		
	--稀有
	if isUnCommon > 0 then
		Qingming_Client3_ResultOne_Item_Animate:Show()
		Qingming_Client3_ResultOne_Item_Animate:Play(true)
	else
		Qingming_Client3_ResultOne_Item_Animate:Play(false)
		Qingming_Client3_ResultOne_Item_Animate:Hide()
	end
	
	--显示奖池剩余情况
	for index=1,table.getn(g_Qingming_OneShowItemList)  do
		g_Qingming_OneShowItemList[index]:Hide()
		g_Qingming_OneShowItemTips[index]:Hide()
	end
	
	local remainKind = DataPool:Lua_QingmingJackRemainKind();
	if remainKind > 0 then
		for index=1,remainKind do
			local remainID,remainNum,totalNum = DataPool:Lua_QingmingJackRemainInfo(index-1);
			--PushDebugMessage("remainID="..remainID.."  remainNum="..remainNum.."  totalNum"..totalNum)
			if remainID > 0 then
				--显示item
				local theAction = DataPool:CreateActionItemForShow(remainID, 1)
				if theAction:GetID() ~= 0 then
					g_Qingming_OneShowItemList[index]:SetActionItem(theAction:GetID());
					g_Qingming_OneShowItemList[index]:Show()
					g_Qingming_OneShowItemTips[index]:Show()
					--显示剩余
					if remainNum > 0 then
						g_Qingming_OneShowItemTips[index]:SetText(ScriptGlobal_Format("#{QMCJ_190310_90}",remainNum,totalNum))
					else
						g_Qingming_OneShowItemTips[index]:SetText(ScriptGlobal_Format("#{QMCJ_190310_91}",remainNum,totalNum))
					end
				end
			end
		end
	end

	-- 获得锦灵珠时播放动画
	if nGetDaiBi > 0 then
		SetTimer("Qingming","Qingming_OneAnimeTimer()", 800)
	end

	Qingming_SetJinLingZhuVisible()
end


--================================================
-- 奖池界面处理
-- 抽奖结果
--================================================
function Qingming_JackpotResultFive(nTablIndex1,nTablIndex2,nTablIndex3,nTablIndex4,nTablIndex5,nIsEx)
	Qingming_Client3_Show:Hide()
	Qingming_Client3_Take:Hide()
	Qingming_Client3_ResultOne:Hide()
	Qingming_Client3_ResultFive:Show()
	
	--九个按钮状态
	local mCurJackpotIndex = DataPool:Lua_GetQingmingJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Qingming_MaxJackpot then
		PushDebugMessage("Qingming_JackpotInfo Data error")
		return
	end
	Qingming_NineBtnState( mCurJackpotIndex + 1 )
	 
	--可上菜数量
	local totalTimes,useTimes = DataPool:Lua_QingmingJackpotTimes();
	local nJackRemainNum = totalTimes-useTimes
	local curJackRemain = ScriptGlobal_Format("#{QMCJ_190310_30}",nJackRemainNum,totalTimes)
	Qingming_Client3_ResultFive_FeastNum:SetText(curJackRemain)
	
	--代币数显示
	local nDaibi1 = DataPool:Lua_QingmingNum()
	if nDaibi1 > 0 then
		Qingming_Client3_ResultFive_NowNum1:SetText(ScriptGlobal_Format("#{QMCJ_190310_33}",nDaibi1))--代币1
	else
		Qingming_Client3_ResultFive_NowNum1:SetText(ScriptGlobal_Format("#{QMCJ_190310_34}",nDaibi1)) --代币1
	end
	local nDaibi2 = DataPool:Lua_QingmingExNum()
	if nDaibi2 > 0 then
		Qingming_Client3_ResultFive_NowNum2:SetText(ScriptGlobal_Format("#{QMCJ_190310_35}",nDaibi2)) --代币2
	else
		Qingming_Client3_ResultFive_NowNum2:SetText(ScriptGlobal_Format("#{QMCJ_190310_36}",nDaibi2)) --代币2
	end
	
	--五抽按钮tips
	if nDaibi1 >= g_Qingming_FiveCount then
		if nJackRemainNum >= g_Qingming_FiveCount then
			Qingming_Client3_ResultFive_Again:SetToolTip("#{QMCJ_190310_44}")	--悬浮tips
		else
			Qingming_Client3_ResultFive_Again:SetToolTip("#{QMCJ_190310_43}")	--悬浮tips
		end
	else
		Qingming_Client3_ResultFive_Again:SetToolTip("#{QMCJ_190310_42}")	--悬浮tips
	end
		
	--宴会名字
	local preImgName = Qingming_GetFeastImgName(mCurJackpotIndex + 1)
	Qingming_Client3_ResultFiveTitle:SetProperty("Image", preImgName);
	
	--先都隐藏了
	for index=1,table.getn(g_Qingming_FiveItemList) do
		g_Qingming_FiveItemList[index]:Hide()
		g_Qingming_FiveItemBkList[index]:Hide()
		g_Qingming_UnComAnimeList[index]:Play(false)
		g_Qingming_UnComAnimeList[index]:Hide()
		g_Qingming_FiveItemAnimeList[index]:Play(false)
		g_Qingming_FiveItemAnimeList[index]:Hide()
	end	
	Qingming_Client3_ResultFive_Item6Client:Hide()
	
	--显示奖池剩余情况
	for index=1,table.getn(g_Qingming_FiveShowItemList)  do
		g_Qingming_FiveShowItemList[index]:Hide()
		g_Qingming_FiveShowItemTips[index]:Hide()
	end

	local remainKind = DataPool:Lua_QingmingJackRemainKind();
	if remainKind > 0 then
		for index=1,remainKind do
			local remainID,remainNum,totalNum = DataPool:Lua_QingmingJackRemainInfo(index-1);
			--PushDebugMessage("remainID="..remainID.."  remainNum="..remainNum.."  totalNum"..totalNum)
			if remainID > 0 then
				--显示item
				local theAction = DataPool:CreateActionItemForShow(remainID, 1)
				if theAction:GetID() ~= 0 then
					g_Qingming_FiveShowItemList[index]:SetActionItem(theAction:GetID());
					g_Qingming_FiveShowItemList[index]:Show()
					g_Qingming_FiveShowItemTips[index]:Show()
					--显示剩余
					if remainNum > 0 then
						g_Qingming_FiveShowItemTips[index]:SetText(ScriptGlobal_Format("#{QMCJ_190310_90}",remainNum,totalNum))
					else
						g_Qingming_FiveShowItemTips[index]:SetText(ScriptGlobal_Format("#{QMCJ_190310_91}",remainNum,totalNum))
					end
				end
			end
		end
	end
	--奖励列表
	g_Qingming_RewardItemList[1] = nTablIndex1
	g_Qingming_RewardItemList[2] = nTablIndex2
	g_Qingming_RewardItemList[3] = nTablIndex3
	g_Qingming_RewardItemList[4] = nTablIndex4
	g_Qingming_RewardItemList[5] = nTablIndex5
	g_Qingming_RewardItemList[6] = nIsEx
	
	--播放动画
	SetTimer("Qingming","Qingming_FiveAnimeTimer()", 0)
	g_Qingming_FiveIndex = 1

	Qingming_SetJinLingZhuVisible()
end


--================================================
-- 奖池界面处理
-- 抽奖说明
-- 五连抽动画
--================================================
function Qingming_FiveAnimeTimer()
	KillTimer("Qingming_FiveAnimeTimer()")
	--挨个播
	for index=1,table.getn(g_Qingming_FiveItemList) do
		if index <= table.getn(g_Qingming_RewardItemList) and  index == g_Qingming_FiveIndex then
			if g_Qingming_RewardItemList[index] > 0 and  index < g_Qingming_FiveExIndex then
				local nItemId,isUnCommon = DataPool:Lua_QingmingRewardInfo(g_Qingming_RewardItemList[index])
				local nUseItemId = DataPool:Lua_QingmingRewardID(g_Qingming_RewardItemList[index])
				if nItemId < 0 or nUseItemId < 0 then
					PushDebugMessage("Qingming_JackpotResultFive nTablIndex error"..g_Qingming_RewardItemList[index])
					return
				end
				--tips
				local itemname = DataPool:Lua_GetItemNameByIndex(nUseItemId)
				PushDebugMessage( ScriptGlobal_Format("#{QMCJ_190310_77}",itemname))
				local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
				if theAction:GetID() ~= 0 then
					g_Qingming_FiveItemList[index]:SetActionItem(theAction:GetID());
					g_Qingming_FiveItemList[index]:Show()
					g_Qingming_FiveItemBkList[index]:Show()
					g_Qingming_FiveItemAnimeList[index]:Show()
					g_Qingming_FiveItemAnimeList[index]:Play(true)
				else
					g_Qingming_FiveItemList[index]:Hide()
				end
				if isUnCommon > 0 then
					g_Qingming_UnComAnimeList[index]:Show()
					g_Qingming_UnComAnimeList[index]:Play(true)
				end
			elseif g_Qingming_RewardItemList[index] > 0 and index == g_Qingming_FiveExIndex then
				--显示第六个id
				Qingming_Client3_ResultFive_Item6Client:Show()
				--tips
				PushDebugMessage("#{QMCJ_190310_95}")
				local theAction = DataPool:CreateActionItemForShow(g_Qingming_FiveExItemShowId, 1)
				if theAction:GetID() ~= 0 then
					g_Qingming_FiveItemList[index]:SetActionItem(theAction:GetID());
					g_Qingming_FiveItemList[index]:Show()
					g_Qingming_FiveItemBkList[index]:Show()
					--稀有特效
					g_Qingming_UnComAnimeList[index]:Show()
					g_Qingming_UnComAnimeList[index]:Play(true)
					g_Qingming_FiveItemAnimeList[index]:Show()
					g_Qingming_FiveItemAnimeList[index]:Play(true)
				else
					g_Qingming_FiveItemList[index]:Hide()
				end
			end
		end
	end	
	
	g_Qingming_FiveIndex = g_Qingming_FiveIndex + 1
	if g_Qingming_FiveIndex <= g_Qingming_FiveExIndex then
		SetTimer("Qingming","Qingming_FiveAnimeTimer()", 800)
	end
	
end


--================================================
-- 单抽后 获得保底锦灵珠的动画
--================================================
function Qingming_OneAnimeTimer()
	KillTimer("Qingming_OneAnimeTimer()")
	PushDebugMessage("#{QMCJ_190310_95}")
	local theAction = DataPool:CreateActionItemForShow(g_Qingming_FiveExItemShowId, 1)
	if theAction:GetID() ~= 0 then		
		Qingming_Client3_ResultOne_Item2:SetActionItem(theAction:GetID())
		Qingming_Client3_ResultOne_Item2:Show()
		Qingming_Client3_ResultOne_Item2Client:Show()
		Qingming_Client3_ResultOne_Item2_Animate2:Play(true)
		Qingming_Client3_ResultOne_Item2_Animate:Play(true)
	end
end

--================================================
-- 奖池界面处理
-- 抽奖说明
-- 显示选中状态奖池剩余的奖励内容 
--================================================
function Qingming_TakeHelpBtn()

	--PushDebugMessage("查询剩余  index="..g_Qingming_CurJackpotIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("QueryJackpotRemain")
		Set_XSCRIPT_ScriptID(505080)
		Set_XSCRIPT_Parameter( 0 ,g_Qingming_CurJackpotIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end


--================================================
-- 奖池界面处理
-- 抽一次
--================================================
function Qingming_TakeOneBtn(nIsmore)
	--抽奖按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Qingming_ButtonLastTime1 < g_Qingming_ButtonCDTime * 1000) then
		PushDebugMessage("#{QMCJ_190310_97}"); --当前操作过快，请稍后点击
		return
	end
	g_Qingming_ButtonLastTime1 = curTime;
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetJackpotOnce")
		Set_XSCRIPT_ScriptID(505080)
		Set_XSCRIPT_Parameter( 0 ,nIsmore)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

--================================================
-- 奖池界面处理
-- 抽五次
--================================================
function Qingming_TakeFiveBtn(nIsmore)	
	--抽奖按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Qingming_ButtonLastTime2 < g_Qingming_FiveCDTime * 1000) then
		PushDebugMessage("#{QMCJ_190310_97}"); --当前操作过快，请稍后点击
		return
	end
	g_Qingming_ButtonLastTime2 = curTime;
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetJackpotFiveTimes")
		Set_XSCRIPT_ScriptID(505080)
		Set_XSCRIPT_Parameter( 0 ,nIsmore)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

--================================================
-- 奖池界面处理
-- 关闭界面
--================================================
function Qingming_Close()
	Qingming_OnHiden()
	Qingming_Clear()
end


--================================================
-- 奖池界面处理
-- 返回索引宴会img名字
--================================================
function Qingming_GetFeastImgName(nOptionIndex)
	if nOptionIndex < 1 or nOptionIndex > 9 then
		return
	end
	if nOptionIndex == 1 then
		return "set:Qingming2 image:title1"
	elseif nOptionIndex == 2 then
		return "set:Qingming2 image:title2"
	elseif nOptionIndex == 3 then
		return "set:Qingming2 image:title3"
	elseif nOptionIndex == 4 then
		return "set:Qingming2 image:title4"
	elseif nOptionIndex == 5 then
		return "set:Qingming2 image:title5"
	elseif nOptionIndex == 6 then
		return "set:Qingming2 image:title6"
	elseif nOptionIndex == 7 then
		return "set:Qingming2 image:title7"
	elseif nOptionIndex == 8 then
		return "set:Qingming2 image:title8"
	elseif nOptionIndex == 9 then
		return "set:Qingming2 image:title9"
	end
end


--================================================
-- 奖池界面处理
-- 点选每个宴席
--================================================
function Qingming_FeastClicked( nOptionIndex)
	--判断
	if nOptionIndex < 1 or nOptionIndex > 9 or g_Qingming_CurJackpotIndex == nOptionIndex then
		return
	end
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetQingmingJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Qingming_MaxJackpot then
		PushDebugMessage("Qingming_FeastClicked Data error")
		return
	end
	
	--只能预览还没抽奖的
	if nOptionIndex ==  mCurJackpotIndex + 1 then
		--回到当前奖池
		Qingming_JackpotInfo()
	elseif nOptionIndex >  mCurJackpotIndex + 1 then
		--预览奖池
		Qingming_JackpotPreShow(nOptionIndex)
	end
	
	--按钮状态切换
	for index=1,table.getn(g_Qingming_JackpotList)  do
		if index == nOptionIndex then
			g_Qingming_JackpotList[index]:SetCheck(1)
			g_Qingming_JackpotTitleList[index]:Show()
		else
			g_Qingming_JackpotList[index]:SetCheck(0)
			g_Qingming_JackpotTitleList[index]:Hide()
		end
	end
end

--================================================
-- 奖池界面处理
-- 获得宴会名字
--================================================
function Qingming_GetFeastName( nOptionIndex)
	--判断
	if nOptionIndex < 1 or nOptionIndex > 9 then
		return
	end
	if  nOptionIndex == 1 then
		return "#{QMCJ_190310_17}"
	elseif  nOptionIndex == 2 then
		return "#{QMCJ_190310_18}"
	elseif  nOptionIndex == 3 then
		return "#{QMCJ_190310_19}"
	elseif  nOptionIndex == 4 then
		return "#{QMCJ_190310_20}"
	elseif  nOptionIndex == 5 then
		return "#{QMCJ_190310_21}"
	elseif  nOptionIndex == 6 then
		return "#{QMCJ_190310_22}"
	elseif  nOptionIndex == 7 then
		return "#{QMCJ_190310_23}"
	elseif  nOptionIndex == 8 then
		return "#{QMCJ_190310_24}"
	elseif  nOptionIndex == 9 then
		return "#{QMCJ_190310_25}"
	end
end

--================================================
-- 功能函数，分隔符
--================================================
function Qingming_Split( str,reps )
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end

--================================================
-- 奖池界面处理
-- 抽完奖的返回按钮
--================================================
function Qingming_Return()
	KillTimer("Qingming_FiveAnimeTimer()")
	KillTimer("Qingming_OneAnimeTimer()")
	Qingming_OpenFenye( 3,0 )
end


--================================================
-- 奖池界面处理 
-- 额外奖励
-- 九个按钮的显示状态
--================================================
function Qingming_OpenExReward()
	--代币数
	local mExNum = DataPool:Lua_QingmingExNum();
	if mExNum > 0 then
		Qingming_Client4_Num:SetText(ScriptGlobal_Format("#{QMCJ_190310_35}",mExNum))
		Qingming_Client4_Btn:SetToolTip("#{QMCJ_190310_61}")	
	else
		Qingming_Client4_Num:SetText(ScriptGlobal_Format("#{QMCJ_190310_36}",mExNum))
		Qingming_Client4_Btn:SetToolTip("#{QMCJ_190310_60}")	
	end
	
	--隐藏轮转图片
	for index=1,table.getn(g_Qingming_ExLoopPicList)  do
		g_Qingming_ExLoopPicList[index]:Hide()
	end
	
	--隐藏选中特效
	for index=1,table.getn(g_Qingming_ExLoopAnimeList)  do
		g_Qingming_ExLoopAnimeList[index]:Hide()
		g_Qingming_ExLoopAnimeList[index]:Play(false)
	end
	
	--获取状态
	local nFlagInfo =	DataPool:Lua_QingmingExRewardList();
	--PushDebugMessage("额外奖励  nFlagList="..nFlagInfo)	
	--奖池物品展示
	local kajiType = KaJi:LuaFnGetKaJiType(60)
	if kajiType ~= 0 and kajiType ~= 1 then
		kajiType = 0
	end
	local itemList = g_Qingming_ExItemEnum[kajiType]
	local nFlagList = Qingming_Split( nFlagInfo,"," )
	local tempNum = 0
	for index=1,table.getn(g_Qingming_ExRewardList)  do
		if index <= table.getn(nFlagList) then	
			local theAction = DataPool:CreateActionItemForShow(itemList[index].ShowID, 1)
			if theAction:GetID() ~= 0 then
				g_Qingming_ExRewardList[index]:SetActionItem(theAction:GetID());
				g_Qingming_ExRewardList[index]:Show()
				if tonumber(nFlagList[index]) == 0 then
					--待抽取
					g_Qingming_ExMaskList[index]:Hide()
					tempNum = tempNum + 1
				else
					--已经抽了
					g_Qingming_ExMaskList[index]:Show()
				end
			else
				g_Qingming_ExRewardList[index]:Hide()
			end
		end
		--隐藏轮转图片
		g_Qingming_ExLoopPicList[index]:Hide()
		--隐藏选中特效
		g_Qingming_ExLoopAnimeList[index]:Hide()
	end
	
	
	g_Qingming_RemainExItemNo = tempNum
end

--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽奖逻辑
--================================================
function Qingming_GetExRewardBtn()
	--抽奖按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Qingming_ButtonLastTime3 < g_Qingming_ExRewardCDTime * 1000) then
		PushDebugMessage("#{QMCJ_190310_63}"); --当前操作过快，请稍后点击
		return
	end
	g_Qingming_ButtonLastTime3 = curTime;
	

	KillTimer("Qingming_ExItemAnimeTimer()")
	KillTimer("Qingming_ExItemCheckTimer()")
	Qingming_OpenExReward()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetGetExReward")
		Set_XSCRIPT_ScriptID(505081)
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

end


--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽完奖励动画
--================================================
function Qingming_OpenExRewardAnime(nRewardIndex)
	--代币数
	local mExNum = DataPool:Lua_QingmingExNum();
	if mExNum > 0 then
		Qingming_Client4_Num:SetText(ScriptGlobal_Format("#{QMCJ_190310_35}",mExNum))
		Qingming_Client4_Btn:SetToolTip("#{QMCJ_190310_61}")	
	else
		Qingming_Client4_Num:SetText(ScriptGlobal_Format("#{QMCJ_190310_36}",mExNum))
		Qingming_Client4_Btn:SetToolTip("#{QMCJ_190310_60}")	
	end
	
	--隐藏轮转图片
	for index=1,table.getn(g_Qingming_ExLoopPicList)  do
		g_Qingming_ExLoopPicList[index]:Hide()
	end
	
	--隐藏选中特效
	for index=1,table.getn(g_Qingming_ExLoopAnimeList)  do
		g_Qingming_ExLoopAnimeList[index]:Hide()
		g_Qingming_ExLoopAnimeList[index]:Play(false)
	end
	
	--开始动画
	--获取状态
	local nFlagInfo = DataPool:Lua_QingmingExRewardList();
	--PushDebugMessage("额外奖励结束  nFlagList="..nFlagInfo)	
	--奖池物品展示 轮换两遍
	local nFlagList = Qingming_Split( nFlagInfo,"," )
	local nRemainNum = 0
	local nTempExTimerList1 ={} 
	for index=1,table.getn(nFlagList)  do	
		if tonumber(nFlagList[index]) == 0 then
			table.insert(nTempExTimerList1,index)
			nRemainNum = nRemainNum + 1
		else
			if index == nRewardIndex then
				table.insert(nTempExTimerList1,nRewardIndex)
			end
		end
	end
	--看是否需要直接显示
	if nRemainNum == 0 then
		local kajiType = KaJi:LuaFnGetKaJiType(60)
		if kajiType ~= 0 and kajiType ~= 1 then
			kajiType = 0
		end
		local itemList = g_Qingming_ExItemEnum[kajiType]
		for index=1,table.getn(g_Qingming_ExRewardList)  do
			if index == nRewardIndex then
				--tips
				local itemname = DataPool:Lua_GetItemNameByIndex(itemList[index].Id)
				PushDebugMessage( ScriptGlobal_Format("#{QMCJ_190310_73}",itemname))
				--已经抽了
				--g_Qingming_ExMaskList[index]:Show()
				--选中特效
				g_Qingming_ExLoopAnimeList[index]:Show()
				g_Qingming_ExLoopAnimeList[index]:Play(true)
			end
		end
		return
	end
	
	--还有剩余就需要轮换了
	g_Qingming_ExTimerList = {}
	--乱序
	Qingming_RandomArray(nTempExTimerList1)
	--合并数组
	for index=1,table.getn(nTempExTimerList1)  do	
		if nTempExTimerList1[index] > 0 then
			table.insert(g_Qingming_ExTimerList,nTempExTimerList1[index])
		end
	end
	
	
	--第二圈
	local nTempExTimerList2 ={}
	for index=1,table.getn(nFlagList)  do	
		if tonumber(nFlagList[index]) == 0 then
			table.insert(nTempExTimerList2,index)
		end
	end
	--乱序
	Qingming_RandomArray(nTempExTimerList2)
	
	--合并数组
	for index=1,table.getn(nTempExTimerList2)  do	
		if nTempExTimerList2[index] > 0 then
			table.insert(g_Qingming_ExTimerList,nTempExTimerList2[index])
		end
	end
	
	--插入最后的
	table.insert(g_Qingming_ExTimerList,nRewardIndex)
	
	-- 去闪吧
	g_Qingming_ExTimerIndex = 1
	SetTimer("Qingming","Qingming_ExItemAnimeTimer()", 0)

end

--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽取额外奖励闪动画
-- 闪完常亮
--================================================
function Qingming_ExItemAnimeTimer()
	KillTimer("Qingming_ExItemAnimeTimer()")
	--挨个遍历
	for index=1,table.getn(g_Qingming_ExTimerList)  do	
		local nCurValue = g_Qingming_ExTimerList[index]
		if index == g_Qingming_ExTimerIndex then
			--闪耀
			g_Qingming_ExLoopPicList[nCurValue]:Show()
			g_Qingming_ExLoopPicList[nCurValue]:Play(true)
			if index == table.getn(g_Qingming_ExTimerList) then
				g_Qingming_ExTimerCheckIndex = nCurValue
				SetTimer("Qingming","Qingming_ExItemCheckTimer()", 300)
			end
		end
	end
	if g_Qingming_ExTimerIndex < table.getn(g_Qingming_ExTimerList) then
		g_Qingming_ExTimerIndex = g_Qingming_ExTimerIndex + 1
		SetTimer("Qingming","Qingming_ExItemAnimeTimer()", 1350 - (2*g_Qingming_RemainExItemNo - g_Qingming_ExTimerIndex)*70)
	end
end


--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽取额外奖励闪动画
-- 选中
--================================================
function Qingming_ExItemCheckTimer()
	KillTimer("Qingming_ExItemCheckTimer()")
	--tips
	--PushDebugMessage("获得物品index="..g_Qingming_ExTimerCheckIndex); 

	local kajiType = KaJi:LuaFnGetKaJiType(60)
	if kajiType ~= 0 and kajiType ~= 1 then
		kajiType = 0
	end
	local itemList = g_Qingming_ExItemEnum[kajiType]
	local itemname = DataPool:Lua_GetItemNameByIndex(itemList[g_Qingming_ExTimerCheckIndex].Id)
	PushDebugMessage( ScriptGlobal_Format("#{QMCJ_190310_73}",itemname))
				
	--已经抽了
	--g_Qingming_ExMaskList[g_Qingming_ExTimerCheckIndex]:Show()
	--选中特效
	g_Qingming_ExLoopAnimeList[g_Qingming_ExTimerCheckIndex]:Show()
	g_Qingming_ExLoopAnimeList[g_Qingming_ExTimerCheckIndex]:Play(true)
end
--================================================
-- 功能函数，打乱顺序
--================================================
function Qingming_RandomArray(arr)
	local tmp, index
	for i=1, table.getn(arr)-1 do
		index = math.random(i, table.getn(arr))
		if i ~= index then
			tmp = arr[index]
			arr[index] = arr[i]
			arr[i] = tmp
		end
	end
end


--================================================
-- 小红点更新
--================================================
function Qingming_UpdateRedPoint( nFlag1,nFlag2,nFlag3,nFlag4)
	if nFlag1 == 0 then
		g_Qingming_RedPoint[1]:Hide()
	else
		g_Qingming_RedPoint[1]:Show()
	end
	if nFlag2 == 0 then
		g_Qingming_RedPoint[2]:Hide()
	else
		g_Qingming_RedPoint[2]:Show()
	end
	if nFlag3 == 0 then
		g_Qingming_RedPoint[3]:Hide()
	else
		g_Qingming_RedPoint[3]:Show()
	end
	if nFlag4 == 0 then
		g_Qingming_RedPoint[4]:Hide()
	else
		g_Qingming_RedPoint[4]:Show()
	end
end

--点击团子：白团、青团、红团
function Qingming_TZ_Clicked(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClickTuanZi")
		Set_XSCRIPT_ScriptID(892721)
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Qingming_UpdateUI( index )
	Qingming_Clear()
	if index ~= 1 then
		return
	end
	--Qingming_FenYeChange_Clicked(2)
	-- 设置当前的选中页签
	g_sheet = index
	
	if g_redpoint_1 == 1 then
		Qingming_Plum1_Button3_tips:Show()
	else
		Qingming_Plum1_Button3_tips:Hide()
	end
	
	if g_redpoint_2 == 1 then
		Qingming_Plum2_Button3_tips:Show()
	else
		Qingming_Plum2_Button3_tips:Hide()
	end

	if g_redpoint_3 == 1 then
		Qingming_Plum3_Button3_tips:Show()
	else
		Qingming_Plum3_Button3_tips:Hide()
	end	
	
	if g_sheet == 1 then
	
		--Qingming_Frame_Fenye1:SetCheck(1)
		--Qingming_Frame_Fenye2:SetCheck(0)	
		Qingming_Info_Time:Show()
		Qingming_Help:Show()
		
		--白团
		if g_state1 == 2 then
			Qingming_Plum1_Info2:SetText("#{QMQT_180309_08}")
			Qingming_Plum1_Info1:SetText("#{QMQT_180309_11}")
			Qingming_Plum1_Button2:Hide()
			Qingming_Plum1_Button3:Show()
			Qingming_Plum1_Button3_Finish:Show() --326
		else
			Qingming_Plum1_Info2:SetText("#{QMQT_180309_08}")
			Qingming_Plum1_Info1:SetText("#{QMQT_180309_09}")
			Qingming_Plum1_Button2:Show()
			Qingming_Plum1_Button3:Hide()				
		end
		--青团
		if g_state2 == 2 then
			Qingming_Plum2_Info2:SetText("#{QMQT_180309_13}")
			Qingming_Plum2_Info1:SetText("#{QMQT_180309_11}")
			Qingming_Plum2_Button1:Hide()
			Qingming_Plum2_Button2:Hide()
			Qingming_Plum2_Button3:Show()	
			Qingming_Plum2_Button3_Finish:Show() --326		
		elseif g_state2 == 1 then
			Qingming_Plum2_Info2:SetText("#{QMQT_180309_13}")	
			Qingming_Plum2_Info1:SetText("#{QMQT_180309_09}")
			Qingming_Plum2_Button1:Hide()
			Qingming_Plum2_Button2:Show()
			Qingming_Plum2_Button3:Hide()				
		else
			Qingming_Plum2_Info2:SetText("#{QMQT_180309_13}")
			Qingming_Plum2_Info1:SetText(ScriptGlobal_Format("#{QMQT_180309_14}", g_minute))				
			Qingming_Plum2_Button1:Show()
			Qingming_Plum2_Button2:Hide()
			Qingming_Plum2_Button3:Hide()
		end
		--红团
		if g_state3 == 2 then
			if KaJi:LuaFnIsKaJiServer() == 1 then
				Qingming_Plum3_Info2:SetText("#{QMQTKJ_211215_2}")
			else
				Qingming_Plum3_Info2:SetText("#{QMQT_180309_17}")
			end
			Qingming_Plum3_Info1:SetText("#{QMQT_180309_11}")			
			Qingming_Plum3_Button1:Hide()
			Qingming_Plum3_Button2:Hide()
			Qingming_Plum3_Button3:Show()	
			Qingming_Plum3_Button3_Finish:Show() --326		
		elseif g_state3 == 1 then
			if KaJi:LuaFnIsKaJiServer() == 1 then
				Qingming_Plum3_Info2:SetText("#{QMQTKJ_211215_2}")
			else
				Qingming_Plum3_Info2:SetText("#{QMQT_180309_17}")
			end
			Qingming_Plum3_Info1:SetText("#{QMQT_180309_09}")
			Qingming_Plum3_Button1:Hide()
			Qingming_Plum3_Button2:Show()
			Qingming_Plum3_Button3:Hide()				
		else
			if KaJi:LuaFnIsKaJiServer() == 1 then
				Qingming_Plum3_Info2:SetText("#{QMQTKJ_211215_2}")
			else
				Qingming_Plum3_Info2:SetText("#{QMQT_180309_17}")
			end
			Qingming_Plum3_Info1:SetText(ScriptGlobal_Format("#{QMQT_180309_18}", g_activepoint))				
			Qingming_Plum3_Button1:Show()
			Qingming_Plum3_Button2:Hide()
			Qingming_Plum3_Button3:Hide()
		end				
		
		Qingming_ActivityClient_Plum1:Show()
		Qingming_ActivityClient_Plum2:Show()
		Qingming_ActivityClient_Plum3:Show()
		Qingming_ActivityClient_BK1:Show()
		--Qingming_Client2:Show()	
	
	end
	
end

function Qingming_Clear()

	Qingming_ActivityClient_Plum1:Hide()
	Qingming_Plum1_Button2:Hide()
	Qingming_Plum1_Button3:Hide()
	Qingming_ActivityClient_BK1:Hide()

	Qingming_ActivityClient_Plum2:Hide()
	Qingming_Plum2_Button1:Hide()
	Qingming_Plum2_Button2:Hide()
	Qingming_Plum2_Button3:Hide()


	Qingming_ActivityClient_Plum3:Hide()
	Qingming_Plum3_Button1:Hide()
	Qingming_Plum3_Button2:Hide()
	Qingming_Plum3_Button3:Hide()
	
	
	--326
	Qingming_Plum1_Button3_Finish:Hide()
	Qingming_Plum2_Button3_Finish:Hide()
	Qingming_Plum3_Button3_Finish:Hide()
	Qingming_Info_Time:Hide()
	Qingming_Help:Hide()
	
	--this:Hide()
	
end


function Qingming_Help_Clicked(index) --326
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NPCTalk")
		Set_XSCRIPT_ScriptID(892721)
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end


function Qingming_RefreshBuChangBtn( btnstate, mExNum )
	--Qingming_Client4_Num:SetText(ScriptGlobal_Format("#{QMCJ_190310_35}",mExNum))
	-- if btnstate == 0  then
		-- Qingming_Client4_GetPerl_Btn:Disable()
	-- else
		-- Qingming_Client4_GetPerl_Btn:Enable()
	-- end
	Qingming_Client4_GetPerl_Btn:Disable()
end

function Qingming_GetBuChang()
	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name("GetBuChang")
		-- Set_XSCRIPT_ScriptID(505081) 
		-- Set_XSCRIPT_ParamCount(0)
	-- Send_XSCRIPT()	
end

--*****************************************
--分页1 领取礼包
--*****************************************
function Qingming_GiftBtn_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetGift")
		Set_XSCRIPT_ScriptID(505080) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function Qingming_ShowItemAlreadyGetEx(actBtn, smpTxt, bk)
	local str = "{{0.000000,110.000000},{0.000000,150.000000}}"
	
	-- if g_Qingming_CurJackpotIndex == 3 or g_Qingming_CurJackpotIndex == 7 then
	-- 	str = "{{0.000000,110.000000},{0.000000,180.000000}}"

	-- 	local daibiAction = DataPool:CreateActionItemForShow(g_Qingming_FiveExItemShowId, 1) --锦灵珠展示道具ID
	-- 	if daibiAction:GetID() ~= 0 then
	-- 		actBtn:SetActionItem(daibiAction:GetID())
	-- 	end

	-- 	actBtn:Show()
	-- 	smpTxt:SetText("#{QMCJ_211220_3}")
	-- 	smpTxt:Show()
	-- else
	if actBtn then
		actBtn:Hide()
	end
	if smpTxt then
		smpTxt:Hide()
	end
	-- end

	bk:SetProperty("UnifiedSize", str)
end

function Qingming_SetJinLingZhuVisible()
	if g_Qingming_CurJackpotIndex == 3 or g_Qingming_CurJackpotIndex == 7 then
		local theAction = DataPool:CreateActionItemForShow(g_Qingming_FiveExItemShowId, 1) --锦灵珠的展示道具ID
		if theAction:GetID() ~= 0 then
			g_Qingming_PreShowItem_Ex:SetActionItem(theAction:GetID())
			g_Qingming_PreShowItem_Ex:SetProperty("AlwaysOnTop", "True")
			g_Qingming_PreShowWind_Ex:SetProperty("AlwaysOnTop", "True")
		end
		g_Qingming_PreShowWind_Ex:Show()
	else
		if g_Qingming_PreShowWind_Ex:IsVisible() == true then
			g_Qingming_PreShowWind_Ex:Hide()
			g_Qingming_PreShowWind_Ex:SetProperty("AlwaysOnTop", "False")
			g_Qingming_PreShowItem_Ex:SetProperty("AlwaysOnTop", "False")
		end
	end
end