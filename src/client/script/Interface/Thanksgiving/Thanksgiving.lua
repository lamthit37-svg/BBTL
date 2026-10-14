--******************************************************************************
-- 2018感恩节活动
--页签1活动介绍
--页签2鉴宝
--页签3抽奖
--lmy  2018-10-30

--食谱鉴定 yee 11-2
--******************************************************************************
local g_Thanksgiving_Frame_UnifiedPosition;

local g_Thanksgiving_BeginTime 		= 20251117  --20221128	--活动开始时间
local g_Thanksgiving_EndTime 		= 20251130  --20221211	--活动结束时间
local g_Thanksgiving_FinalEndTime 	= 20251203  --20221214	--活动结束时间
local g_Thanksgiving_LimitLevel 	= 30		--活动限制等级
local g_Thanksgiving_ButtonCDTime 	= 1 		--抽奖按钮冷却时间
local g_Thanksgiving_FiveCDTime		= 4 		--五连抽按钮冷却时间
local g_Thanksgiving_ExRewardCDTime = 7.5 		--额外抽奖按钮冷却时间
local g_Thanksgiving_ButtonLastTime1= 0			--抽奖按钮冷却时间计时
local g_Thanksgiving_ButtonLastTime2= 0			--抽奖按钮冷却时间计时
local g_Thanksgiving_ButtonLastTime3= 0			--抽奖按钮冷却时间计时
local g_Thanksgiving_MaxJackpot		= 8			--最大宴席数
local g_Thanksgiving_FiveCount		= 5			--五连抽次数
local g_Thanksgiving_CurJackpotIndex= 1			--当前宴席index 1-9

local g_Thanksgiving_Client = {}			--4个分页
local g_Thanksgiving_JackpotList = {}		--九个奖池按钮
local g_Thanksgiving_JackpotTitleList = {}	--九个奖池按钮图片
local g_Thanksgiving_JackpotItemList = {}	--九个奖池按钮上的item

--预览界面
local g_Thanksgiving_PreShowItemList = {}		--预览奖池

--默认展示界面
local g_Thanksgiving_TakeShowItemList = {}		--展示界面奖品剩余情况item
local g_Thanksgiving_TakeShowItemTips = {}		--展示界面奖品剩余情况文本

--抽一次奖界面
local g_Thanksgiving_OneShowItemList = {}		--抽一次奖品剩余情况item
local g_Thanksgiving_OneShowItemTips = {}		--抽一次奖品剩余情况文本

--抽五次奖界面
local g_Thanksgiving_FiveItemList = {}			--抽五次后获得item
local g_Thanksgiving_FiveItemBkList = {}		--抽五次后获得item 背景
local g_Thanksgiving_UnComAnimeList = {}		--抽五次后获得item 稀有特效
local g_Thanksgiving_FiveIndex = 1				--五连抽动画顺序
local g_Thanksgiving_RewardItemList = {}		--五连抽物品id缓存
local g_Thanksgiving_FiveItemAnimeList = {}		--抽五次后获得item 每个的动画
local g_Thanksgiving_FiveShowItemList = {}		--抽五次奖品剩余情况item
local g_Thanksgiving_FiveShowItemTips = {}		--抽五次奖品剩余情况文本

--额外抽奖界面
local g_Thanksgiving_ExRewardList = {}			--额外抽奖九个额外奖励
local g_Thanksgiving_ExMaskList = {}			--额外抽奖九个已抽取
local g_Thanksgiving_ExLoopPicList = {}			--额外抽奖九个额外奖励图片
local g_Thanksgiving_ExLoopAnimeList = {}		--额外抽奖九个额外奖励选中动画
local g_Thanksgiving_ExTimerList = {}			--额外抽奖闪动数组
local g_Thanksgiving_ExTimerIndex = 1			--额外抽奖闪动数组index
local g_Thanksgiving_ExTimerCheckIndex = 1		--额外抽奖选中索引
local g_Thanksgiving_RemainExItemNo = 9			--额外抽奖选中索引

--页签红点
local g_RedPoint_State = {0, 0, 0, 0}  --红点状态（0不显示，1显示）
local g_RedPoint_Tips = {}   --4个页签上的红点控件

--宴席图标展示id
local g_Thanksgiving_JackpotItemEnum =
{
	-- 原服
	[0] = {
		[1] = 39920329,
		[2] = 39922684,
		[3] = 39922685,
		[4] = 39920396,
		[5] = 39924115,
		[6] = 39922685,
		[7] = 39920397,
		[8] = 39922684,
		[9] = 39920329,
	},
	-- 卡级服
	[1] = {
		[1] = 39920329,
		[2] = 39920490,
		[3] = 39923635,
		[4] = 39920396,
		[5] = 39924115,
		[6] = 39920396,
		[7] = 39923635,
		[8] = 39920490,
		[9] = 39920329,
	},
}

-- 保底获得饕餮柬的展示id
local g_Thanksgiving_TaoTieJian = 39921565

--额外奖励列表  前两个物品getname方法不支持，获取背包又麻烦，写死名字好了
local g_Thanksgiving_ExItemEnum =
{
	-- 原服
	[0] = {
		[1] = {Id=50231009, ShowID = 39921561},
		[2] = {Id=50413004, ShowID = 39920463},
		[3] = {Id=39910114, ShowID = 39922835},
		[4] = {Id=20502004, ShowID = 39920566},
		[5] = {Id=20501004, ShowID = 39920565},
		[6] = {Id=38000438, ShowID = 39921360},
		[7] = {Id=10126438, ShowID = 39923667},
		[8] = {Id=38008194, ShowID = 39925080},
		[9] = {Id=38000437, ShowID = 39921377},
	},
	-- 卡级服
	[1] = {
		[1] = {Id=50231009, ShowID = 39921561},
		[2] = {Id=50413004, ShowID = 39920463},
		[3] = {Id=39910114, ShowID = 39922835},
		[4] = {Id=20502004, ShowID = 39920566},
		[5] = {Id=20501004, ShowID = 39920565},
		[6] = {Id=20500004, ShowID = 39923638},
		[7] = {Id=10126438, ShowID = 39923667},
		[8] = {Id=38008194, ShowID = 39925080},
		[9] = {Id=10124468, ShowID = 39923637},
	},
}

--鉴定分页---------------------------------------

--UI控件
local UI_List = {}
local UI_Buttons = {}

--对应食谱级别相关变量
local g_Thanksgiving_List = {}

--其他变量

local g_Globalvar_List = {

	SumCateNum = -1,
	CurCateNum = -1,
	CurCookingNum = -1,
	CurMenuLevel = -1,
	MaxMenuLevel = 4,
	Menu_Bagpos = -1,
	RefreshType = -1,
	CurCookPage = -1,
	Old_Bagpos = -1,
	_02_Timer = 0,
	_05_Timer = 0,
	CDButton_Index = -1
}

local g_Thanksgiving_isMe = 0
local g_Thanksgiving_curTaotie = -1
local g_Thanksgiving_maxCate = 1000  --佳肴上限
local g_Thanksgiving_newPos = -1

local g_Thanksgiving_IdentifyAnimeList = {}
local g_Thanksgiving_UpgradeAnimeList = {}

local g_Thanksgiving_IdentifyAnimeIndex = 0
local g_Thanksgiving_UpgradeAnimeIndex = 0

local g_Thanksgiving_FestivalGiftFlag = 3368
local g_Thanksgiving_FestivalGift_KJID = 27
--鉴定分页完-------------------------------------


--===============================================
-- OnLoad()
--===============================================
function Thanksgiving_PreLoad()
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
	--yee
	this:RegisterEvent("IDENTIFY_MENU_UPDEATE",false)  --更新item
	
	this:RegisterEvent("MENU_UPANDGO_CMD",false)   --升级跳转
end

function Thanksgiving_OnLoad()
	-- 保存界面的默认相对位置
	g_Thanksgiving_Frame_UnifiedPosition = Thanksgiving_FrameNULL:GetProperty("UnifiedPosition");
	
	--4个分页
	g_Thanksgiving_Client[1] = Thanksgiving_Client1
	g_Thanksgiving_Client[2] = Thanksgiving_Client2
	g_Thanksgiving_Client[3] = Thanksgiving_Client3
	g_Thanksgiving_Client[4] = Thanksgiving_Client4
	
	--奖池
	g_Thanksgiving_JackpotList[1] = Thanksgiving_Client3_tab1
	g_Thanksgiving_JackpotList[2] = Thanksgiving_Client3_tab2
	g_Thanksgiving_JackpotList[3] = Thanksgiving_Client3_Tab3
	g_Thanksgiving_JackpotList[4] = Thanksgiving_Client3_Tab4
	g_Thanksgiving_JackpotList[5] = Thanksgiving_Client3_Tab5
	g_Thanksgiving_JackpotList[6] = Thanksgiving_Client3_Tab6
	g_Thanksgiving_JackpotList[7] = Thanksgiving_Client3_Tab7
	g_Thanksgiving_JackpotList[8] = Thanksgiving_Client3_Tab8
	g_Thanksgiving_JackpotList[9] = Thanksgiving_Client3_Tab9
	g_Thanksgiving_JackpotTitleList[1] = Thanksgiving_Client3_tab1Text2
	g_Thanksgiving_JackpotTitleList[2] = Thanksgiving_Client3_tab2Text2
	g_Thanksgiving_JackpotTitleList[3] = Thanksgiving_Client3_tab3Text2
	g_Thanksgiving_JackpotTitleList[4] = Thanksgiving_Client3_tab4Text2
	g_Thanksgiving_JackpotTitleList[5] = Thanksgiving_Client3_tab5Text2
	g_Thanksgiving_JackpotTitleList[6] = Thanksgiving_Client3_tab6Text2
	g_Thanksgiving_JackpotTitleList[7] = Thanksgiving_Client3_tab7Text2
	g_Thanksgiving_JackpotTitleList[8] = Thanksgiving_Client3_tab8Text2
	g_Thanksgiving_JackpotTitleList[9] = Thanksgiving_Client3_tab9Text2

	
	g_Thanksgiving_JackpotItemList[1] = Thanksgiving_Client3_tab1Item
	g_Thanksgiving_JackpotItemList[2] = Thanksgiving_Client3_tab2Item
	g_Thanksgiving_JackpotItemList[3] = Thanksgiving_Client3_Tab3Item
	g_Thanksgiving_JackpotItemList[4] = Thanksgiving_Client3_Tab4Item
	g_Thanksgiving_JackpotItemList[5] = Thanksgiving_Client3_Tab5Item
	g_Thanksgiving_JackpotItemList[6] = Thanksgiving_Client3_Tab6Item
	g_Thanksgiving_JackpotItemList[7] = Thanksgiving_Client3_Tab7Item
	g_Thanksgiving_JackpotItemList[8] = Thanksgiving_Client3_Tab8Item
	g_Thanksgiving_JackpotItemList[9] = Thanksgiving_Client3_Tab9Item
	
	--预览界面
	g_Thanksgiving_PreShowItemList[1] = Thanksgiving_Client3_Show_Item1
	g_Thanksgiving_PreShowItemList[2] = Thanksgiving_Client3_Show_Item2
	g_Thanksgiving_PreShowItemList[3] = Thanksgiving_Client3_Show_Item3
	g_Thanksgiving_PreShowItemList[4] = Thanksgiving_Client3_Show_Item4
	g_Thanksgiving_PreShowItemList[5] = Thanksgiving_Client3_Show_Item5
	g_Thanksgiving_PreShowItemList[6] = Thanksgiving_Client3_Show_Item6
	g_Thanksgiving_PreShowItemList[7] = Thanksgiving_Client3_Show_Item7
	g_Thanksgiving_PreShowItemList[8] = Thanksgiving_Client3_Show_Item8
	g_Thanksgiving_PreShowItemList[9] = Thanksgiving_Client3_Show_Item9
	g_Thanksgiving_PreShowItemList[10] = Thanksgiving_Client3_Show_Item10
	g_Thanksgiving_PreShowItemList[11] = Thanksgiving_Client3_Show_Item11
	g_Thanksgiving_PreShowItemList[12] = Thanksgiving_Client3_Show_Item12
	g_Thanksgiving_PreShowItemList[13] = Thanksgiving_Client3_Show_Item13
	g_Thanksgiving_PreShowItemList[14] = Thanksgiving_Client3_Show_Item14
	g_Thanksgiving_PreShowItemList[15] = Thanksgiving_Client3_Show_Item15
	g_Thanksgiving_PreShowItemList[16] = Thanksgiving_Client3_Show_Item16
	g_Thanksgiving_PreShowItemList[17] = Thanksgiving_Client3_Show_Item17
	g_Thanksgiving_PreShowItemList[18] = Thanksgiving_Client3_Show_Item18
	g_Thanksgiving_PreShowItemList[19] = Thanksgiving_Client3_Show_Item19
	g_Thanksgiving_PreShowItemList[20] = Thanksgiving_Client3_Show_Item20
	g_Thanksgiving_PreShowItemList[21] = Thanksgiving_Client3_Show_Item21
	g_Thanksgiving_PreShowItemList[22] = Thanksgiving_Client3_Show_Item22
	g_Thanksgiving_PreShowItemList[23] = Thanksgiving_Client3_Show_Item23
	g_Thanksgiving_PreShowItemList[24] = Thanksgiving_Client3_Show_Item24
	g_Thanksgiving_PreShowItemList[25] = Thanksgiving_Client3_Show_Item25
	g_Thanksgiving_PreShowItemList[26] = Thanksgiving_Client3_Show_Item26
	g_Thanksgiving_PreShowItemList[27] = Thanksgiving_Client3_Show_Item27
	g_Thanksgiving_PreShowItemList[28] = Thanksgiving_Client3_Show_Item28
	g_Thanksgiving_PreShowItemList[29] = Thanksgiving_Client3_Show_Item29
	g_Thanksgiving_PreShowItemList[30] = Thanksgiving_Client3_Show_Item30
	g_Thanksgiving_PreShowItemList[31] = Thanksgiving_Client3_Show_Item31
	g_Thanksgiving_PreShowItemList[32] = Thanksgiving_Client3_Show_Item32
	g_Thanksgiving_PreShowItemList[33] = Thanksgiving_Client3_Show_Item33
	g_Thanksgiving_PreShowItemList[34] = Thanksgiving_Client3_Show_Item34
	g_Thanksgiving_PreShowItemList[35] = Thanksgiving_Client3_Show_Item35
	g_Thanksgiving_PreShowItemList[36] = Thanksgiving_Client3_Show_Item36
	g_Thanksgiving_PreShowItemList[37] = Thanksgiving_Client3_Show_Item37
	g_Thanksgiving_PreShowItemList[38] = Thanksgiving_Client3_Show_Item38
	g_Thanksgiving_PreShowItemList[39] = Thanksgiving_Client3_Show_Item39
	g_Thanksgiving_PreShowItemList[40] = Thanksgiving_Client3_Show_Item40
	g_Thanksgiving_PreShowItemList[41] = Thanksgiving_Client3_Show_Item41
	g_Thanksgiving_PreShowItemList[42] = Thanksgiving_Client3_Show_Item42
	g_Thanksgiving_PreShowItemList[43] = Thanksgiving_Client3_Show_Item43
	g_Thanksgiving_PreShowItemList[44] = Thanksgiving_Client3_Show_Item44
	g_Thanksgiving_PreShowItemList[45] = Thanksgiving_Client3_Show_Item45

	
	--默认界面
	g_Thanksgiving_TakeShowItemList[1] = Thanksgiving_Client3_Take_NumItem1
	g_Thanksgiving_TakeShowItemList[2] = Thanksgiving_Client3_Take_NumItem2
	g_Thanksgiving_TakeShowItemList[3] = Thanksgiving_Client3_Take_NumItem3
	g_Thanksgiving_TakeShowItemList[4] = Thanksgiving_Client3_Take_NumItem4
	g_Thanksgiving_TakeShowItemTips[1] = Thanksgiving_Client3_Take_NumItem1Text
	g_Thanksgiving_TakeShowItemTips[2] = Thanksgiving_Client3_Take_NumItem2Text
	g_Thanksgiving_TakeShowItemTips[3] = Thanksgiving_Client3_Take_NumItem3Text
	g_Thanksgiving_TakeShowItemTips[4] = Thanksgiving_Client3_Take_NumItem4Text
	
	--一抽后
	g_Thanksgiving_OneShowItemList[1] = Thanksgiving_Client3_ResultOne_NumItem1
	g_Thanksgiving_OneShowItemList[2] = Thanksgiving_Client3_ResultOne_NumItem2
	g_Thanksgiving_OneShowItemList[3] = Thanksgiving_Client3_ResultOne_NumItem3
	g_Thanksgiving_OneShowItemList[4] = Thanksgiving_Client3_ResultOne_NumItem4
	g_Thanksgiving_OneShowItemTips[1] = Thanksgiving_Client3_ResultOne_NumItem1Text
	g_Thanksgiving_OneShowItemTips[2] = Thanksgiving_Client3_ResultOne_NumItem2Text
	g_Thanksgiving_OneShowItemTips[3] = Thanksgiving_Client3_ResultOne_NumItem3Text
	g_Thanksgiving_OneShowItemTips[4] = Thanksgiving_Client3_ResultOne_NumItem4Text
	
	--抽五次后
	g_Thanksgiving_FiveItemList[1] = Thanksgiving_Client3_ResultFive_Item1
	g_Thanksgiving_FiveItemList[2] = Thanksgiving_Client3_ResultFive_Item2
	g_Thanksgiving_FiveItemList[3] = Thanksgiving_Client3_ResultFive_Item3
	g_Thanksgiving_FiveItemList[4] = Thanksgiving_Client3_ResultFive_Item4
	g_Thanksgiving_FiveItemList[5] = Thanksgiving_Client3_ResultFive_Item5
	g_Thanksgiving_FiveItemBkList[1] = Thanksgiving_Client3_ResultFive_Item1BK
	g_Thanksgiving_FiveItemBkList[2] = Thanksgiving_Client3_ResultFive_Item2BK
	g_Thanksgiving_FiveItemBkList[3] = Thanksgiving_Client3_ResultFive_Item3BK
	g_Thanksgiving_FiveItemBkList[4] = Thanksgiving_Client3_ResultFive_Item4BK
	g_Thanksgiving_FiveItemBkList[5] = Thanksgiving_Client3_ResultFive_Item5BK
	g_Thanksgiving_UnComAnimeList[1] = Thanksgiving_Client3_ResultFive_Item1_Animate
	g_Thanksgiving_UnComAnimeList[2] = Thanksgiving_Client3_ResultFive_Item2_Animate
	g_Thanksgiving_UnComAnimeList[3] = Thanksgiving_Client3_ResultFive_Item3_Animate
	g_Thanksgiving_UnComAnimeList[4] = Thanksgiving_Client3_ResultFive_Item4_Animate
	g_Thanksgiving_UnComAnimeList[5] = Thanksgiving_Client3_ResultFive_Item5_Animate
	g_Thanksgiving_FiveItemAnimeList[1] = Thanksgiving_Client3_ResultFive_Animate1
	g_Thanksgiving_FiveItemAnimeList[2] = Thanksgiving_Client3_ResultFive_Animate2
	g_Thanksgiving_FiveItemAnimeList[3] = Thanksgiving_Client3_ResultFive_Animate3
	g_Thanksgiving_FiveItemAnimeList[4] = Thanksgiving_Client3_ResultFive_Animate4
	g_Thanksgiving_FiveItemAnimeList[5] = Thanksgiving_Client3_ResultFive_Animate5
	
	g_Thanksgiving_FiveShowItemList[1] = Thanksgiving_Client3_ResultFive_NumItem1
	g_Thanksgiving_FiveShowItemList[2] = Thanksgiving_Client3_ResultFive_NumItem2
	g_Thanksgiving_FiveShowItemList[3] = Thanksgiving_Client3_ResultFive_NumItem3
	g_Thanksgiving_FiveShowItemList[4] = Thanksgiving_Client3_ResultFive_NumItem4
	g_Thanksgiving_FiveShowItemTips[1] = Thanksgiving_Client3_ResultFive_NumItem1Text
	g_Thanksgiving_FiveShowItemTips[2] = Thanksgiving_Client3_ResultFive_NumItem2Text
	g_Thanksgiving_FiveShowItemTips[3] = Thanksgiving_Client3_ResultFive_NumItem3Text
	g_Thanksgiving_FiveShowItemTips[4] = Thanksgiving_Client3_ResultFive_NumItem4Text
	
	--额外奖励
	g_Thanksgiving_ExRewardList[1] = Thanksgiving_Client4_Item1
	g_Thanksgiving_ExRewardList[2] = Thanksgiving_Client4_Item2
	g_Thanksgiving_ExRewardList[3] = Thanksgiving_Client4_Item3
	g_Thanksgiving_ExRewardList[4] = Thanksgiving_Client4_Item4
	g_Thanksgiving_ExRewardList[5] = Thanksgiving_Client4_Item5
	g_Thanksgiving_ExRewardList[6] = Thanksgiving_Client4_Item6
	g_Thanksgiving_ExRewardList[7] = Thanksgiving_Client4_Item7
	g_Thanksgiving_ExRewardList[8] = Thanksgiving_Client4_Item8
	g_Thanksgiving_ExRewardList[9] = Thanksgiving_Client4_Item9
	g_Thanksgiving_ExMaskList[1] = Thanksgiving_Client4_Item1_Mask
	g_Thanksgiving_ExMaskList[2] = Thanksgiving_Client4_Item2_Mask
	g_Thanksgiving_ExMaskList[3] = Thanksgiving_Client4_Item3_Mask
	g_Thanksgiving_ExMaskList[4] = Thanksgiving_Client4_Item4_Mask
	g_Thanksgiving_ExMaskList[5] = Thanksgiving_Client4_Item5_Mask
	g_Thanksgiving_ExMaskList[6] = Thanksgiving_Client4_Item6_Mask
	g_Thanksgiving_ExMaskList[7] = Thanksgiving_Client4_Item7_Mask
	g_Thanksgiving_ExMaskList[8] = Thanksgiving_Client4_Item8_Mask
	g_Thanksgiving_ExMaskList[9] = Thanksgiving_Client4_Item9_Mask
	g_Thanksgiving_ExLoopPicList[1] = Thanksgiving_Client4_Item1Light
	g_Thanksgiving_ExLoopPicList[2] = Thanksgiving_Client4_Item2Light
	g_Thanksgiving_ExLoopPicList[3] = Thanksgiving_Client4_Item3Light
	g_Thanksgiving_ExLoopPicList[4] = Thanksgiving_Client4_Item4Light
	g_Thanksgiving_ExLoopPicList[5] = Thanksgiving_Client4_Item5Light
	g_Thanksgiving_ExLoopPicList[6] = Thanksgiving_Client4_Item6Light
	g_Thanksgiving_ExLoopPicList[7] = Thanksgiving_Client4_Item7Light
	g_Thanksgiving_ExLoopPicList[8] = Thanksgiving_Client4_Item8Light
	g_Thanksgiving_ExLoopPicList[9] = Thanksgiving_Client4_Item9Light
	g_Thanksgiving_ExLoopAnimeList[1] = Thanksgiving_Client4_Item1_Animate
	g_Thanksgiving_ExLoopAnimeList[2] = Thanksgiving_Client4_Item2_Animate
	g_Thanksgiving_ExLoopAnimeList[3] = Thanksgiving_Client4_Item3_Animate
	g_Thanksgiving_ExLoopAnimeList[4] = Thanksgiving_Client4_Item4_Animate
	g_Thanksgiving_ExLoopAnimeList[5] = Thanksgiving_Client4_Item5_Animate
	g_Thanksgiving_ExLoopAnimeList[6] = Thanksgiving_Client4_Item6_Animate
	g_Thanksgiving_ExLoopAnimeList[7] = Thanksgiving_Client4_Item7_Animate
	g_Thanksgiving_ExLoopAnimeList[8] = Thanksgiving_Client4_Item8_Animate
	g_Thanksgiving_ExLoopAnimeList[9] = Thanksgiving_Client4_Item9_Animate
	
	--yeeee
	UI_List.PreCook_Button = Thanksgiving_Client2_PreButton
	UI_List.NextCook_Button = Thanksgiving_Client2_NextButton
	UI_List.Menu_Item = Thanksgiving_Menu_Item
	UI_List.Cook_Button = Thanksgiving_Menu_CookButton
	UI_List.UpGrade_Button = Thanksgiving_Menu_UpgradeButton
	UI_List.CookingNum_Text = Thanksgiving_Menu_PointNum
	UI_List.CateNum_Text = Thanksgiving_Menu_MealNum
	UI_List.CookingNum_Tip = Thanksgiving_Menu_ExpendText
	UI_List.Menu_Name = Thanksgiving_Menu_ItemName
	UI_List.Cook_Saying = Thanksgiving_Talk_Text
	UI_List.Cook_Name = Thanksgiving_ManName
	UI_List.Taotie_Text = Thanksgiving_Menu_TaotieNum
	
	UI_List.NewButton = Thanksgiving_Menu_CookButtonMid
	
	UI_List.FestivalGift = Thanksgiving_Libao
	UI_List.FestivalGift_Tip = Thanksgiving_Libao_Tips

	UI_Buttons = {
		{ widget = Thanksgiving_Client2_PreButton, isOn = 1},
		{ widget = Thanksgiving_Client2_NextButton, isOn = 1},
		{ widget = Thanksgiving_Menu_CookButton, isOn = 1},
		{ widget = Thanksgiving_Menu_UpgradeButton, isOn = 1},
	}

	g_Thanksgiving_List = {
		{ menuID = 38002602, menuNameUI = "#{GEJY_181027_95}", menuName = "#{GEJY_181027_72}", cookimg = Thanksgiving_MenClient_Man1, cookbk = Thanksgiving_Namebk_Man1, cooknameUI = "#{GEJY_181027_73}", cookname = "#{GEJY_181027_102}", saying1 = "#{GEJY_181027_21}" , saying2 = "#{GEJY_181027_26}" , saying3 = "#{GEJY_181027_79}" , saying4 = "#{GEJY_181027_83}", cookingConsume = 200, cookingTips = "#{GEJY_181027_14}", cateAward = 5, upGradeTip = "#{GEJY_181027_106}" },
		{ menuID = 38002603, menuNameUI = "#{GEJY_181027_96}", menuName = "#{GEJY_181027_63}", cookimg = Thanksgiving_MenClient_Man2, cookbk = Thanksgiving_Namebk_Man2, cooknameUI = "#{GEJY_181027_74}", cookname = "#{GEJY_181027_103}", saying1 = "#{GEJY_181027_22}" , saying2 = "#{GEJY_181027_27}" , saying3 = "#{GEJY_181027_80}" , saying4 = "#{GEJY_181027_84}", cookingConsume = 200, cookingTips = "#{GEJY_181027_15}", cateAward = 6, upGradeTip = "#{GEJY_181027_107}" },
		{ menuID = 38002604, menuNameUI = "#{GEJY_181027_97}", menuName = "#{GEJY_181027_64}", cookimg = Thanksgiving_MenClient_Man3, cookbk = Thanksgiving_Namebk_Man3, cooknameUI = "#{GEJY_181027_76}", cookname = "#{GEJY_181027_104}", saying1 = "#{GEJY_181027_23}" , saying2 = "#{GEJY_181027_28}" , saying3 = "#{GEJY_181027_82}" , saying4 = "", cookingConsume = -1, cookingTips = "#{GEJY_181027_16}", cateAward = 7, upGradeTip = "" },
		{ menuID = 38002606, menuNameUI = "#{GEJY_181027_98}", menuName = "#{GEJY_181027_66}", cookimg = Thanksgiving_MenClient_Man4, cookbk = Thanksgiving_Namebk_Man4, cooknameUI = "#{GEJY_181027_77}", cookname = "#{GEJY_181027_105}", saying1 = "#{GEJY_181027_25}" , saying2 = "#{GEJY_181027_30}" , saying3 = "" , saying4 = "", cookingConsume = -1, cookingTips = "#{GEJY_181027_18}", cateAward = 7, upGradeTip = "" },
	--	{ menuID = 38002606, menuName = "#{GEJY_181027_66}", cookimg = Thanksgiving_MenClient_Man5, cookname = "#{GEJY_181027_77}", saying1 = "#{GEJY_181027_25}" , saying2 = "#{GEJY_181027_30}" , saying3 = "" , saying4 = "", cookingConsume = 10000, cookingTips = "#{GEJY_181027_18}"},
	}

	UI_List.NewButton:Hide()
	
	g_Thanksgiving_IdentifyAnimeList[1] = { widget = Thanksgiving_Client2_CookAmiate1, delay = 500}
	g_Thanksgiving_IdentifyAnimeList[2] = { widget = Thanksgiving_Client2_CookAmiate2, delay = 10}
	g_Thanksgiving_IdentifyAnimeList[3] = { widget = Thanksgiving_Client2_CookAmiate3, delay = 300}
	g_Thanksgiving_IdentifyAnimeList[4] = { widget = Thanksgiving_Client2_CookAmiate4, delay = 500}
	
	g_Thanksgiving_UpgradeAnimeList[1] = { widget = Thanksgiving_Client2_UpgradeAmiate1, delay = 500}
	g_Thanksgiving_UpgradeAnimeList[2] = { widget = Thanksgiving_Client2_UpgradeAmiate2, delay = 50}
	g_Thanksgiving_UpgradeAnimeList[3] = { widget = Thanksgiving_Client2_UpgradeAmiate3, delay = 400}
	g_Thanksgiving_UpgradeAnimeList[4] = { widget = Thanksgiving_Client2_UpgradeAmiate4, delay = 100}
	g_Thanksgiving_UpgradeAnimeList[5] = { widget = Thanksgiving_Client2_UpgradeAmiate5, delay = 300}
	g_Thanksgiving_UpgradeAnimeList[6] = { widget = Thanksgiving_Client2_UpgradeAmiate6, delay = 500}

	g_RedPoint_Tips[1] = Thanksgiving_Buttontab01_Tips
	g_RedPoint_Tips[4] = Thanksgiving_Buttontab04_Tips
end


--===============================================
-- OnEvent()
--===============================================

function Thanksgiving_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 89283102) then
		if(IsWindowShow("Thanksgiving")) then
			CloseWindow("Thanksgiving", true)
		end
		if Get_XParam_INT(0) == 1 then
			--打开主界面
			Thanksgiving_OpenFenye( 1 )
			Thanksgiving_UpdateRedPoint()
			this:Show()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89283103) then
		--更新到再抽一次界面
		Thanksgiving_JackpotResultOne(Get_XParam_INT(0),Get_XParam_INT(1))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89283104) then
		--更新到再抽5次界面
		Thanksgiving_JackpotResultFive(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2),
			Get_XParam_INT(3),Get_XParam_INT(4),Get_XParam_INT(5))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89283901) then
		--打开额外抽奖界面
		Thanksgiving_OpenFenye( 4 )
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89283902) then
		--更新额外抽奖界面
		 Thanksgiving_OpenExRewardAnime(Get_XParam_INT(0))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89283106) then
		-- 重置分页红点
		g_RedPoint_State[1] = Get_XParam_INT(0)
		g_RedPoint_State[4] = Get_XParam_INT(1)
		-- 如果是开着界面跨天
		if this:IsVisible() and Get_XParam_INT(2) == 1 then
			if g_Thanksgiving_Client[1]:IsVisible() and g_RedPoint_State[1] == 1 then
				Thanksgiving_RemoveRedPoint(1)
			end
			if g_Thanksgiving_Client[4]:IsVisible() and g_RedPoint_State[4] == 1 then
				Thanksgiving_UpdateTaotieNum()
			end
		end
		-- 如果是开着页面4得到饕餮
		if g_Thanksgiving_Client[4]:IsVisible() and Get_XParam_INT(2) == 2 then
			Thanksgiving_UpdateTaotieNum()
		end
		Thanksgiving_UpdateRedPoint()
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Thanksgiving_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Thanksgiving_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Thanksgiving_OnHiden()
	------------------------------------------------------------
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 810210261) then
		--更改佳肴上限
		g_Thanksgiving_maxCate = Get_XParam_INT( 0 )
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 810210262 ) then
	--PushDebugMessage("xxx1 g_Globalvar_List.CurCookingNum"..g_Globalvar_List.CurCookingNum.."g_Globalvar_List.CurCateNum"..g_Globalvar_List.CurCateNum)	

		g_Globalvar_List.RefreshType = Get_XParam_INT( 0 );
		g_Globalvar_List.CurCateNum = Get_XParam_INT( 1 );
		g_Globalvar_List.CurCookingNum = Get_XParam_INT( 2 );
		--g_Globalvar_List.CurMenuLevel = Get_XParam_INT( 3 );
		if g_Globalvar_List.CurMenuLevel ~= -1 then g_Globalvar_List.CurCookPage = g_Globalvar_List.CurMenuLevel end
		g_Globalvar_List.Old_Bagpos = g_Globalvar_List.Menu_Bagpos;
		--g_Globalvar_List.Menu_Bagpos = Get_XParam_INT( 4 );
		g_Thanksgiving_curTaotie = Get_XParam_INT( 5 );
		g_Thanksgiving_newPos = Get_XParam_INT( 6 );
		--Thanksgiving_ClearOld()
		Thanksgiving_RefreshAll()

		if g_Globalvar_List._05_Timer == 0 then
			g_Globalvar_List._05_Timer = 1
			SetTimer("Thanksgiving_05_Timer","Thanksgiving_05_Timer()", 500)
			Thanksgiving_MakeAllButtons_Disabled()
		end
		
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 810210263 ) then
	
		g_Globalvar_List.CurCateNum = Get_XParam_INT( 0 );
		g_Globalvar_List.CurCookingNum = Get_XParam_INT( 1 );
		g_Thanksgiving_curTaotie = Get_XParam_INT( 2 );
	
		local catenumstr = ScriptGlobal_Format("#{GEJY_181027_08}" , g_Globalvar_List.CurCateNum)
		UI_List.CateNum_Text:SetText(catenumstr)  --更新佳肴
		local cookingnumstr = ScriptGlobal_Format("#{GEJY_181027_12}" , g_Globalvar_List.CurCookingNum)
		UI_List.CookingNum_Text:SetText(cookingnumstr)  --更新厨艺点
		local taotienumstr = ScriptGlobal_Format("#{GEJY_181027_90}" , g_Thanksgiving_curTaotie)
		UI_List.Taotie_Text:SetText(taotienumstr)  --更新饕餮	

	elseif( event == "IDENTIFY_MENU_UPDEATE") then
		if arg0 == nil then
			return
		end
		if g_Thanksgiving_isMe == 0 then
			local pos_packet =tonumber(arg0)
			local theAction = EnumAction(pos_packet, "packageitem");
			local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
			if theAction:GetID() ~= 0 then
			-- 判断当前物品是否为普通食谱、初级食谱、高级食谱、稀有食谱、绝世食谱
				local isMenu = 0
				for idx = 1, g_Globalvar_List.MaxMenuLevel do
					if ItemID == g_Thanksgiving_List[idx].menuID then
						isMenu = 1
						g_Globalvar_List.CurMenuLevel = idx
						break
					end
				end
				if isMenu == 0 then 
					PushDebugMessage("#{GEJY_181027_110}")  --开启当前千味烹秋页面时无法使用该道具
				else
					PushDebugMessage("#{GEJY_181027_111}")  --可前往炊金馔玉页签将食谱交予厨师
				end
			end		
			return
		end
		Thanksgiving_UpdateItem(tonumber(arg0));
	
	elseif ( event == "MENU_UPANDGO_CMD" ) then
		if arg0 == nil then
			return
		end
		local isToGO = tonumber(arg0)
		if isToGO == 0 or isToGO == 1 then
			--PushDebugMessage(isToGO)
			Thanksgiving_UpAndGo(isToGO)	
		end

	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 89283121 ) then
		Thanksgiving_FestivalGift_RedPoint_Update()
	------------------------------------------------------------
	end
end

--===============================================
-- 刷新分页红点
--===============================================
function Thanksgiving_UpdateRedPoint()
	-- PushDebugMessage("刷新UI "..g_RedPoint_State[1].."  "..g_RedPoint_State[4])
	if g_RedPoint_State[1] == 1 then
		g_RedPoint_Tips[1]:Show()
	else
		g_RedPoint_Tips[1]:Hide()
	end
	if g_RedPoint_State[4] == 1 then
		g_RedPoint_Tips[4]:Show()
	else
		g_RedPoint_Tips[4]:Hide()
	end
end
	
--===============================================
-- OnHiden
--===============================================
function Thanksgiving_OnHiden()
	Thanksgiving_Clear()
	KillTimer("Thanksgiving_FiveAnimeTimer()")
	KillTimer("Thanksgiving_ExItemAnimeTimer()")
	KillTimer("Thanksgiving_ExItemCheckTimer()")
	g_Thanksgiving_ButtonLastTime1 = 0
	g_Thanksgiving_ButtonLastTime2 = 0
	g_Thanksgiving_ButtonLastTime3 = 0
	
	g_Thanksgiving_isMe = 0
	PushEvent( "MENU_UPANDGO_CONFIRM", -1, -1, 0);		
	PushEvent( "MENU_UPGRADE_CONFIRM", -1, -1, -1, 0, -1);		

	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Thanksgiving_Frame_On_ResetPos()
	Thanksgiving_FrameNULL:SetProperty("UnifiedPosition", g_Thanksgiving_Frame_UnifiedPosition);
end


--**********************************************
--初始化界面
--**********************************************
function Thanksgiving_OpenFenye( nIndex )
	--判断
	if nIndex < 1 or nIndex > 4 then
		return
	end
	
	--等级和事件判断
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay < g_Thanksgiving_BeginTime or curDay > g_Thanksgiving_FinalEndTime then
		PushDebugMessage("#{GEHJ_181026_65}")
		return
	end
	local nLevel = Player:GetLevel();
	if nLevel < g_Thanksgiving_LimitLevel then
		PushDebugMessage("#{GEHJ_181026_66}")
		return
	end
	
	--分页逻辑
	for index=1,table.getn(g_Thanksgiving_Client)  do
		if index == nIndex then
			g_Thanksgiving_Client[index]:Show()
		else
			g_Thanksgiving_Client[index]:Hide()
		end
	end

	-- 消除当前分页的小红点
	if (nIndex == 1 and g_RedPoint_State[1] == 1) or (nIndex == 4 and g_RedPoint_State[4] == 1) then
		Thanksgiving_RemoveRedPoint(nIndex)
	end	
	
	--按钮选中状态
	if nIndex == 1 then
		Thanksgiving_Buttontab01:SetCheck(1)
		Thanksgiving_Buttontab02:SetCheck(0)
		Thanksgiving_Buttontab03:SetCheck(0)
		Thanksgiving_Buttontab04:SetCheck(0)
	elseif nIndex == 2 then
		Thanksgiving_Buttontab01:SetCheck(0)
		Thanksgiving_Buttontab02:SetCheck(1)
		Thanksgiving_Buttontab03:SetCheck(0)
		Thanksgiving_Buttontab04:SetCheck(0)
	elseif nIndex == 3 then
		Thanksgiving_Buttontab01:SetCheck(0)
		Thanksgiving_Buttontab02:SetCheck(0)
		Thanksgiving_Buttontab03:SetCheck(1)
		Thanksgiving_Buttontab04:SetCheck(0)
	elseif nIndex == 3 then
		Thanksgiving_Buttontab01:SetCheck(0)
		Thanksgiving_Buttontab02:SetCheck(0)
		Thanksgiving_Buttontab03:SetCheck(0)
		Thanksgiving_Buttontab04:SetCheck(1)
	end
	
	--置空鉴定页
	g_Thanksgiving_isMe = 0
	Thanksgiving_Clear()
	
	--展示奖池
	if nIndex == 3 then
		--背包互斥
		if(IsWindowShow("Packet")) then
			CloseWindow("Packet", true);
		end 
		Thanksgiving_JackpotInfo()
	elseif nIndex == 4 then
		--背包互斥
		if(IsWindowShow("Packet")) then
			CloseWindow("Packet", true);
		end 
		--额外抽奖界面
		Thanksgiving_OpenExReward()
	elseif nIndex == 2 then  
		--鉴定页	
		Thanksgiving_OpenIdentify()		
	end

	--动画重置
	KillTimer("Thanksgiving_FiveAnimeTimer()")
	KillTimer("Thanksgiving_ExItemAnimeTimer()")
	KillTimer("Thanksgiving_ExItemCheckTimer()")
	g_Thanksgiving_ButtonLastTime1 = 0
	g_Thanksgiving_ButtonLastTime2 = 0
	g_Thanksgiving_ButtonLastTime3 = 0

	--节日礼包
	Thanksgiving_FestivalGift_UIUpdate()
end

--================================================
-- 删除某一分页的红点
--================================================
function Thanksgiving_RemoveRedPoint(fenye_index)
	-- PushDebugMessage("remove red")
	g_RedPoint_State[fenye_index] = 0
	-- 通知服务器
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RemoveRedPoint")
		Set_XSCRIPT_ScriptID(892831)
		Set_XSCRIPT_Parameter(0, fenye_index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--================================================
-- 奖池界面处理 
-- 九个按钮的显示状态
--================================================
function Thanksgiving_NineBtnState( nOptionIndex )
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetThanksJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Thanksgiving_MaxJackpot 
		or nOptionIndex < 1 or nOptionIndex > 9 then
		PushDebugMessage("Thanksgiving_JackpotInfo Data error")
		return
	end
	g_Thanksgiving_CurJackpotIndex = nOptionIndex
	--九个按钮显示状态
	for index=1,table.getn(g_Thanksgiving_JackpotList)  do
		if index < mCurJackpotIndex + 1 then
			g_Thanksgiving_JackpotList[index]:Disable()
			g_Thanksgiving_JackpotItemList[index]:Hide()
			g_Thanksgiving_JackpotList[index]:SetCheck(0)
			g_Thanksgiving_JackpotTitleList[index]:Hide()
			g_Thanksgiving_JackpotList[index]:SetToolTip("#{GEHJ_181026_20}")	
		elseif index  == mCurJackpotIndex + 1 then
			g_Thanksgiving_JackpotList[index]:Enable()
			local itemlist = Thanksgiving_Libao_GetGiftData()
			local theAction = DataPool:CreateActionItemForShow(itemlist[index], 1)
			if theAction:GetID() ~= 0 then
				g_Thanksgiving_JackpotItemList[index]:SetActionItem(theAction:GetID());
				g_Thanksgiving_JackpotItemList[index]:Show()
			else
				g_Thanksgiving_JackpotItemList[index]:Hide()
			end
			g_Thanksgiving_JackpotList[index]:SetCheck(1)
			g_Thanksgiving_JackpotTitleList[index]:Show()
			local totalTimes,useTimes = DataPool:Lua_ThanksJackpotTimes();
			local curJackRemain = ScriptGlobal_Format("#{GEHJ_181026_21}",totalTimes-useTimes)
			g_Thanksgiving_JackpotList[index]:SetToolTip(curJackRemain)	
		else
			g_Thanksgiving_JackpotList[index]:Enable()
			local itemlist = Thanksgiving_Libao_GetGiftData()
			local theAction = DataPool:CreateActionItemForShow(itemlist[index], 1)
			if theAction:GetID() ~= 0 then
				g_Thanksgiving_JackpotItemList[index]:SetActionItem(theAction:GetID());
				g_Thanksgiving_JackpotItemList[index]:Show()
			else
				g_Thanksgiving_JackpotItemList[index]:Hide()
			end
			g_Thanksgiving_JackpotList[index]:SetCheck(0)
			g_Thanksgiving_JackpotTitleList[index]:Hide()
			g_Thanksgiving_JackpotList[index]:SetToolTip("#{GEHJ_181026_22}")	
		end
	end

	Thanksgiving_Client3_ShowGiftInfo:Hide()
	if mCurJackpotIndex == 2 or mCurJackpotIndex == 6 then
		--奖池3\7显示保底奖励
		local theAction = DataPool:CreateActionItemForShow(g_Thanksgiving_TaoTieJian, 1)
		if theAction:GetID() ~= 0 then
			Thanksgiving_Client3_ShowGiftInfo_Item:SetActionItem(theAction:GetID())
			Thanksgiving_Client3_ShowGiftInfo:Show()
		end
	end
end

--================================================
-- 奖池界面处理 
-- 默认界面
--================================================
function Thanksgiving_JackpotInfo()
	Thanksgiving_Client3_Show:Hide()
	Thanksgiving_Client3_Take:Show()
	Thanksgiving_Client3_ResultOne:Hide()
	Thanksgiving_Client3_ResultFive:Hide()

	--初始化信息
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetThanksJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Thanksgiving_MaxJackpot then
		PushDebugMessage("Thanksgiving_JackpotInfo Data error")
		return
	end
	g_Thanksgiving_CurJackpotIndex = mCurJackpotIndex + 1
	Thanksgiving_NineBtnState( g_Thanksgiving_CurJackpotIndex )
	
	--可上菜数量
	local totalTimes,useTimes = DataPool:Lua_ThanksJackpotTimes();
	local curJackRemain = ScriptGlobal_Format("#{GEHJ_181026_24}",totalTimes-useTimes,totalTimes)
	Thanksgiving_Client3_Take_FeastNum:SetText(curJackRemain)	
	
	--剩余佳肴
	local mThanksgivingNum = DataPool:Lua_ThanksgivingNum();
	local ThanksgivingNum = ""
	if mThanksgivingNum > 0 then
		ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_33}",mThanksgivingNum)
		--Thanksgiving_Client3_TakeOneBtn:SetToolTip("#{GEHJ_181026_37}")	
	else
		ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_32}",mThanksgivingNum)
		--Thanksgiving_Client3_TakeOneBtn:SetToolTip("#{GEHJ_181026_36}")	
	end
	Thanksgiving_Client3_Take_NowNum:SetText("#{GEHJ_181026_31}"..ThanksgivingNum)
	
	-- --五连抽tips
	-- if mThanksgivingNum < g_Thanksgiving_FiveCount then
		-- Thanksgiving_Client3_TakeFiveBtn:SetToolTip("#{GEHJ_181026_39}")
	-- else
		-- if totalTimes-useTimes < g_Thanksgiving_FiveCount then
			-- Thanksgiving_Client3_TakeFiveBtn:SetToolTip("#{GEHJ_181026_40}")
		-- else
			-- Thanksgiving_Client3_TakeFiveBtn:SetToolTip("#{GEHJ_181026_41}")
		-- end
	-- end
	
	--宴会名字
	local curImgName = Thanksgiving_GetFeastImgName(g_Thanksgiving_CurJackpotIndex)
	Thanksgiving_Client3_TakeTitle:SetProperty("Image", curImgName);
	
	--显示奖池剩余情况
	for index=1,table.getn(g_Thanksgiving_TakeShowItemList)  do
		g_Thanksgiving_TakeShowItemList[index]:Hide()
		g_Thanksgiving_TakeShowItemTips[index]:Hide()
	end	
	local remainKind = DataPool:Lua_ThanksJackRemainKind();
	if remainKind > 0 then
		for index=1,remainKind do
			local remainID,remainNum,totalNum = DataPool:Lua_ThanksJackRemainInfo(index-1);
			--PushDebugMessage("remainID="..remainID.."  remainNum="..remainNum.."  totalNum"..totalNum)
			if remainID > 0 then
				--显示item
				local theAction = DataPool:CreateActionItemForShow(remainID, 1)
				if theAction:GetID() ~= 0 then
					g_Thanksgiving_TakeShowItemList[index]:SetActionItem(theAction:GetID());
					g_Thanksgiving_TakeShowItemList[index]:Show()
					g_Thanksgiving_TakeShowItemTips[index]:Show()
					--显示剩余
					if remainNum > 0 then
						g_Thanksgiving_TakeShowItemTips[index]:SetText(ScriptGlobal_Format("#{GEHJ_181026_91}",remainNum,totalNum))
					else
						g_Thanksgiving_TakeShowItemTips[index]:SetText(ScriptGlobal_Format("#{GEHJ_181026_92}",remainNum,totalNum))
					end
				end
			end
		end
	end
	
end
--================================================
-- 奖池界面处理
-- 预览界面
--================================================
function Thanksgiving_JackpotPreShow(nOptionIndex)
	--判断
	if nOptionIndex < 1 or nOptionIndex > 9 then
		return
	end

	--显示界面
	Thanksgiving_Client3_Show:Show()
	Thanksgiving_Client3_Take:Hide()
	Thanksgiving_Client3_ResultOne:Hide()
	Thanksgiving_Client3_ResultFive:Hide()
	
	--赋值
	g_Thanksgiving_CurJackpotIndex = nOptionIndex
	
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetThanksJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Thanksgiving_MaxJackpot then
		PushDebugMessage("Thanksgiving_JackpotPreShow Data error")
		return
	end
	
	--PushDebugMessage("正在预览宴会号"..nOptionIndex.." 在抽奖池为"..mCurJackpotIndex)
	Thanksgiving_NineBtnState( nOptionIndex )
	--可上菜数量
	local totalTimes = DataPool:Lua_PreThanksJackpotTimes(nOptionIndex - 1);
	local curJackRemain = ScriptGlobal_Format("#{GEHJ_181026_24}",totalTimes,totalTimes)
	Thanksgiving_Client3_Show_FeastNum:SetText(curJackRemain)	
	
	-- --剩余佳肴
	-- local mThanksgivingNum = DataPool:Lua_ThanksgivingNum();
	-- local ThanksgivingNum = ""
	-- if mThanksgivingNum > 0 then
		-- ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_33}",mThanksgivingNum)
	-- else
		-- ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_32}",mThanksgivingNum)
	-- end
	-- Thanksgiving_Client3_Show_NowNum:SetText("#{GEHJ_181026_31}"..ThanksgivingNum)
	
	--开启条件
	local curConditionText = ScriptGlobal_Format("#{GEHJ_181026_47}",Thanksgiving_GetFeastName(nOptionIndex - 1))
	Thanksgiving_Client3_Show_Condition:SetText(curConditionText)
	
	--预览宴名字
	local preImgName = Thanksgiving_GetFeastImgName(nOptionIndex)
	Thanksgiving_Client3_ShowTitle:SetProperty("Image", preImgName);
	
	--获取预览信息
	local preNum,PreInfo =	DataPool:Lua_ThanksShowInfo(nOptionIndex -1);
	if preNum < 0 then
		PushDebugMessage("preNum Data error")
		return
	end

	--PushDebugMessage("预览信息  preNum="..preNum.."  PreInfo="..PreInfo)	
	--奖池物品
	--先隐藏
	for index=1,table.getn(g_Thanksgiving_PreShowItemList)  do
		--不够了隐藏
		g_Thanksgiving_PreShowItemList[index]:Hide()
	end
	local PreInfoList = Thanksgiving_Split( PreInfo,"," ) --index List
	local nShowIndex = 1
	for index=1,table.getn(PreInfoList)  do
		local nItemId,isUnCommon ,nItemNum= DataPool:Lua_ThanksRewardInfo(tonumber(PreInfoList[index]))
		for showList=1,nItemNum  do
			--显示item
			local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
			if theAction:GetID() ~= 0 then
				g_Thanksgiving_PreShowItemList[nShowIndex]:SetActionItem(theAction:GetID());
				g_Thanksgiving_PreShowItemList[nShowIndex]:Show()
			else
				g_Thanksgiving_PreShowItemList[nShowIndex]:Hide()
			end	
			nShowIndex = nShowIndex + 1
		end
	end	
	
	Thanksgiving_Client3_ShowGiftInfo:Hide()
	if nOptionIndex == 3 or nOptionIndex == 7 then
		--奖池3\7显示保底奖励
		local theAction = DataPool:CreateActionItemForShow(g_Thanksgiving_TaoTieJian, 1)
		if theAction:GetID() ~= 0 then
			Thanksgiving_Client3_ShowGiftInfo_Item:SetActionItem(theAction:GetID())
			Thanksgiving_Client3_ShowGiftInfo:Show()
		end
	end
end

--================================================
-- 奖池界面处理
-- 抽奖结果
--================================================
function Thanksgiving_JackpotResultOne(nTablIndex, nDaiBi)
	Thanksgiving_Client3_Show:Hide()
	Thanksgiving_Client3_Take:Hide()
	Thanksgiving_Client3_ResultOne:Show()
	Thanksgiving_Client3_ResultFive:Hide()
	if nDaiBi > 0 then
		Thanksgiving_Client3_ResultOne_ItemClient2:Show()
		Thanksgiving_Client3_ResultOne_ItemClient:Hide()
		Thanksgiving_Client3_ResultOne_ItemClient2_R:Hide()
	else
		Thanksgiving_Client3_ResultOne_ItemClient2:Hide()
		Thanksgiving_Client3_ResultOne_ItemClient:Show()
	end
	
	--九个按钮状态
	local mCurJackpotIndex = DataPool:Lua_GetThanksJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Thanksgiving_MaxJackpot then
		PushDebugMessage("Thanksgiving_JackpotInfo Data error")
		return
	end
	Thanksgiving_NineBtnState( mCurJackpotIndex + 1 )
	 
	--可上菜数量
	local totalTimes,useTimes = DataPool:Lua_ThanksJackpotTimes();
	local curJackRemain = ScriptGlobal_Format("#{GEHJ_181026_24}",totalTimes-useTimes,totalTimes)
	Thanksgiving_Client3_ResultOne_FeastNum:SetText(curJackRemain)	
	
	--剩余佳肴
	local mThanksgivingNum = DataPool:Lua_ThanksgivingNum();
	local ThanksgivingNum = ""
	if mThanksgivingNum > 0 then
		ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_33}",mThanksgivingNum)
		--Thanksgiving_Client3_ResultOne_Again:SetToolTip("#{GEHJ_181026_37}")
	else
		ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_32}",mThanksgivingNum)
		--Thanksgiving_Client3_ResultOne_Again:SetToolTip("#{GEHJ_181026_36}")
	end
	Thanksgiving_Client3_ResultOne_NowNum:SetText("#{GEHJ_181026_31}"..ThanksgivingNum)
	
	--宴会名字
	local nowImgName = Thanksgiving_GetFeastImgName(mCurJackpotIndex + 1)
	Thanksgiving_Client3_ResultOneTitle:SetProperty("Image", nowImgName);
	
	--奖励item信息
	--PushDebugMessage("JackpotResultOne nTablIndex="..nTablIndex)
	local nItemId,isUnCommon = DataPool:Lua_ThanksRewardInfo(nTablIndex)
	if nItemId < 0 then
		PushDebugMessage("JackpotResultOne nTablIndex error"..nTablIndex)
		return
	end
	--显示item
	if nDaiBi > 0 then
		Thanksgiving_JackpotResultOne_ShowItem(nItemId, isUnCommon, Thanksgiving_Client3_ResultOne_Item2_L,
			Thanksgiving_Client3_ResultOne_Animate2_L, Thanksgiving_Client3_ResultOne_Item_Animate2_L)
		SetTimer("Thanksgiving", "Thanksgiving_OneAnimeTimer()", 1000)
		g_Thanksgiving_ButtonCDTime = 1.5
	else
		Thanksgiving_JackpotResultOne_ShowItem(nItemId, isUnCommon,	Thanksgiving_Client3_ResultOne_Item,
			Thanksgiving_Client3_ResultOne_Animate, Thanksgiving_Client3_ResultOne_Item_Animate)
		g_Thanksgiving_ButtonCDTime = 1
	end
	
	--显示奖池剩余情况
	for index=1,table.getn(g_Thanksgiving_OneShowItemList)  do
		g_Thanksgiving_OneShowItemList[index]:Hide()
		g_Thanksgiving_OneShowItemTips[index]:Hide()
	end	
	local remainKind = DataPool:Lua_ThanksJackRemainKind();
	if remainKind > 0 then
		for index=1,remainKind do
			local remainID,remainNum,totalNum = DataPool:Lua_ThanksJackRemainInfo(index-1);
			--PushDebugMessage("remainID="..remainID.."  remainNum="..remainNum.."  totalNum"..totalNum)
			if remainID > 0 then
				--显示item
				local theAction = DataPool:CreateActionItemForShow(remainID, 1)
				if theAction:GetID() ~= 0 then
					g_Thanksgiving_OneShowItemList[index]:SetActionItem(theAction:GetID());
					g_Thanksgiving_OneShowItemList[index]:Show()
					g_Thanksgiving_OneShowItemTips[index]:Show()
					--显示剩余
					if remainNum > 0 then
						g_Thanksgiving_OneShowItemTips[index]:SetText(ScriptGlobal_Format("#{GEHJ_181026_91}",remainNum,totalNum))
					else
						g_Thanksgiving_OneShowItemTips[index]:SetText(ScriptGlobal_Format("#{GEHJ_181026_92}",remainNum,totalNum))
					end
				end
			end
		end
	end
end

function Thanksgiving_JackpotResultOne_ShowItem(nItemId, isUnCommon, actionBtn, animate, itemAnim)
	local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
	if theAction:GetID() ~= 0 then
		actionBtn:SetActionItem(theAction:GetID());
		actionBtn:Show()
	else
		actionBtn:Hide()
	end
	
	animate:Show()
	animate:Play(true)
		
	--稀有
	if isUnCommon > 0 then
		itemAnim:Show()
		itemAnim:Play(true)
	else
		itemAnim:Play(false)
		itemAnim:Hide()
	end
end

function Thanksgiving_OneAnimeTimer()
	KillTimer("Thanksgiving_OneAnimeTimer()")
	Thanksgiving_Client3_ResultOne_ItemClient2_R:Show()
	Thanksgiving_JackpotResultOne_ShowItem(
		g_Thanksgiving_TaoTieJian,
		1,
		Thanksgiving_Client3_ResultOne_Item2_R,
		Thanksgiving_Client3_ResultOne_Animate2_R,
		Thanksgiving_Client3_ResultOne_Item_Animate2_R
	)
	local itemname = DataPool:Lua_GetItemNameByIndex(g_Thanksgiving_TaoTieJian)
	PushDebugMessage( ScriptGlobal_Format("#{GEHJ_181026_55}", itemname))
end

--================================================
-- 奖池界面处理
-- 抽奖结果
--================================================
function Thanksgiving_JackpotResultFive(nTablIndex1,nTablIndex2,nTablIndex3,nTablIndex4,nTablIndex5,nDaiBi)
	Thanksgiving_Client3_Show:Hide()
	Thanksgiving_Client3_Take:Hide()
	Thanksgiving_Client3_ResultOne:Hide()
	Thanksgiving_Client3_ResultFive:Show()
	
	--九个按钮状态
	local mCurJackpotIndex = DataPool:Lua_GetThanksJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Thanksgiving_MaxJackpot then
		PushDebugMessage("Thanksgiving_JackpotInfo Data error")
		return
	end
	Thanksgiving_NineBtnState( mCurJackpotIndex + 1 )
	 
	--可上菜数量
	local totalTimes,useTimes = DataPool:Lua_ThanksJackpotTimes();
	local curJackRemain = ScriptGlobal_Format("#{GEHJ_181026_24}",totalTimes-useTimes,totalTimes)
	Thanksgiving_Client3_ResultFive_FeastNum:SetText(curJackRemain)
	
	--剩余佳肴
	local mThanksgivingNum = DataPool:Lua_ThanksgivingNum();
	local ThanksgivingNum = ""
	if mThanksgivingNum > 0 then
		ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_33}",mThanksgivingNum)
	else
		ThanksgivingNum = ScriptGlobal_Format("#{GEHJ_181026_32}",mThanksgivingNum)
	end
	Thanksgiving_Client3_ResultFive_NowNum:SetText("#{GEHJ_181026_31}"..ThanksgivingNum)
	
	-- --五连抽tips
	-- if mThanksgivingNum < g_Thanksgiving_FiveCount then
		-- Thanksgiving_Client3_ResultFive_Again:SetToolTip("#{GEHJ_181026_39}")
	-- else
		-- if totalTimes-useTimes < g_Thanksgiving_FiveCount then
			-- Thanksgiving_Client3_ResultFive_Again:SetToolTip("#{GEHJ_181026_40}")
		-- else
			-- Thanksgiving_Client3_ResultFive_Again:SetToolTip("#{GEHJ_181026_41}")
		-- end
	-- end
	
	--宴会名字
	local preImgName = Thanksgiving_GetFeastImgName(mCurJackpotIndex + 1)
	Thanksgiving_Client3_ResultFiveTitle:SetProperty("Image", preImgName);
	
	--先都隐藏了
	for index=1,table.getn(g_Thanksgiving_FiveItemList) do
		g_Thanksgiving_FiveItemList[index]:Hide()
		g_Thanksgiving_FiveItemBkList[index]:Hide()
		g_Thanksgiving_UnComAnimeList[index]:Play(false)
		g_Thanksgiving_UnComAnimeList[index]:Hide()
		g_Thanksgiving_FiveItemAnimeList[index]:Play(false)
		g_Thanksgiving_FiveItemAnimeList[index]:Hide()
	end	
	Thanksgiving_Client3_ResultFive_Item6Client:Hide()
	if nDaiBi > 0 then
		Thanksgiving_Client3_ResultFive_Item6ClientBK:Show()
	else
		Thanksgiving_Client3_ResultFive_Item6ClientBK:Hide()
	end
	
	--显示奖池剩余情况
	for index=1,table.getn(g_Thanksgiving_FiveShowItemList)  do
		g_Thanksgiving_FiveShowItemList[index]:Hide()
		g_Thanksgiving_FiveShowItemTips[index]:Hide()
	end	
	local remainKind = DataPool:Lua_ThanksJackRemainKind();
	if remainKind > 0 then
		for index=1,remainKind do
			local remainID,remainNum,totalNum = DataPool:Lua_ThanksJackRemainInfo(index-1);
			--PushDebugMessage("remainID="..remainID.."  remainNum="..remainNum.."  totalNum"..totalNum)
			if remainID > 0 then
				--显示item
				local theAction = DataPool:CreateActionItemForShow(remainID, 1)
				if theAction:GetID() ~= 0 then
					g_Thanksgiving_FiveShowItemList[index]:SetActionItem(theAction:GetID());
					g_Thanksgiving_FiveShowItemList[index]:Show()
					g_Thanksgiving_FiveShowItemTips[index]:Show()
					--显示剩余
					if remainNum > 0 then
						g_Thanksgiving_FiveShowItemTips[index]:SetText(ScriptGlobal_Format("#{GEHJ_181026_91}",remainNum,totalNum))
					else
						g_Thanksgiving_FiveShowItemTips[index]:SetText(ScriptGlobal_Format("#{GEHJ_181026_92}",remainNum,totalNum))
					end
				end
			end
		end
	end
	--奖励列表
	g_Thanksgiving_RewardItemList[1] = nTablIndex1
	g_Thanksgiving_RewardItemList[2] = nTablIndex2
	g_Thanksgiving_RewardItemList[3] = nTablIndex3
	g_Thanksgiving_RewardItemList[4] = nTablIndex4
	g_Thanksgiving_RewardItemList[5] = nTablIndex5
	if nDaiBi > 0 then
		g_Thanksgiving_RewardItemList[6] = g_Thanksgiving_TaoTieJian
		g_Thanksgiving_FiveCDTime = 5
	else
		g_Thanksgiving_RewardItemList[6] = nil
		g_Thanksgiving_FiveCDTime = 4
	end
	
	--播放动画
	SetTimer("Thanksgiving","Thanksgiving_FiveAnimeTimer()", 0)
	g_Thanksgiving_FiveIndex = 1
end


--================================================
-- 奖池界面处理
-- 抽奖说明
-- 五连抽动画
--================================================
function Thanksgiving_FiveAnimeTimer()
	KillTimer("Thanksgiving_FiveAnimeTimer()")
	--挨个播
	for index=1,table.getn(g_Thanksgiving_FiveItemList) do
		if index <= table.getn(g_Thanksgiving_RewardItemList) and  index == g_Thanksgiving_FiveIndex then
			if g_Thanksgiving_RewardItemList[index] >= 1 then
				local nItemId,isUnCommon = DataPool:Lua_ThanksRewardInfo(g_Thanksgiving_RewardItemList[index])
				local nUseItemId = DataPool:Lua_ThanksRewardID(g_Thanksgiving_RewardItemList[index])
				if nItemId < 0 or nUseItemId < 0 then
					PushDebugMessage("Thanksgiving_JackpotResultFive nTablIndex error"..g_Thanksgiving_RewardItemList[index])
					return
				end
				--tips
				local itemname = DataPool:Lua_GetItemNameByIndex(nUseItemId)
				PushDebugMessage( ScriptGlobal_Format("#{GEHJ_181026_55}",itemname))
				local theAction = DataPool:CreateActionItemForShow(nItemId, 1)
				if theAction:GetID() ~= 0 then
					g_Thanksgiving_FiveItemList[index]:SetActionItem(theAction:GetID());
					g_Thanksgiving_FiveItemList[index]:Show()
					g_Thanksgiving_FiveItemBkList[index]:Show()
					g_Thanksgiving_FiveItemAnimeList[index]:Show()
					g_Thanksgiving_FiveItemAnimeList[index]:Play(true)
				else
					g_Thanksgiving_FiveItemList[index]:Hide()
				end
				if isUnCommon > 0 then
					g_Thanksgiving_UnComAnimeList[index]:Show()
					g_Thanksgiving_UnComAnimeList[index]:Play(true)
				end
			end
		end
	end	
	
	g_Thanksgiving_FiveIndex = g_Thanksgiving_FiveIndex + 1
	if g_Thanksgiving_FiveIndex <= g_Thanksgiving_FiveCount then
		SetTimer("Thanksgiving","Thanksgiving_FiveAnimeTimer()", 800)
	elseif g_Thanksgiving_RewardItemList[6] ~= nil then
		SetTimer("Thanksgiving","Thanksgiving_FiveAnimeTimer_Ex()", 800)
	end
end

function Thanksgiving_FiveAnimeTimer_Ex()
	KillTimer("Thanksgiving_FiveAnimeTimer_Ex()")
	Thanksgiving_Client3_ResultFive_Item6Client:Show()
	Thanksgiving_JackpotResultOne_ShowItem(
		g_Thanksgiving_TaoTieJian,
		1,
		Thanksgiving_Client3_ResultFive_Item6,
		Thanksgiving_Client3_ResultFive_Animate6,
		Thanksgiving_Client3_ResultFive_Item6_Animate
	)
	local itemname = DataPool:Lua_GetItemNameByIndex(g_Thanksgiving_TaoTieJian)
	PushDebugMessage( ScriptGlobal_Format("#{GEHJ_181026_55}", itemname))
end

--================================================
-- 奖池界面处理
-- 抽奖说明
-- 显示选中状态奖池剩余的奖励内容 
--================================================
function Thanksgiving_TakeHelpBtn()

	--PushDebugMessage("查询剩余  index="..g_Thanksgiving_CurJackpotIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("QueryJackpotRemain")
		Set_XSCRIPT_ScriptID(892831)
		Set_XSCRIPT_Parameter( 0 ,g_Thanksgiving_CurJackpotIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end


--================================================
-- 奖池界面处理
-- 抽一次
--================================================
function Thanksgiving_TakeOneBtn(nIsmore)
	--抽奖按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Thanksgiving_ButtonLastTime1 < g_Thanksgiving_ButtonCDTime * 1000) then
		PushDebugMessage("#{GEHJ_181026_59}"); --当前操作过快，请稍后点击
		return
	end
	g_Thanksgiving_ButtonLastTime1 = curTime;
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetJackpotOnce")
		Set_XSCRIPT_ScriptID(892831)
		Set_XSCRIPT_Parameter( 0 ,nIsmore)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

--================================================
-- 奖池界面处理
-- 抽五次
--================================================
function Thanksgiving_TakeFiveBtn(nIsmore)	
	--抽奖按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Thanksgiving_ButtonLastTime2 < g_Thanksgiving_FiveCDTime * 1000) then
		PushDebugMessage("#{GEHJ_181026_59}"); --当前操作过快，请稍后点击
		return
	end
	g_Thanksgiving_ButtonLastTime2 = curTime;
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetJackpotFiveTimes")
		Set_XSCRIPT_ScriptID(892831)
		Set_XSCRIPT_Parameter( 0 ,nIsmore)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

--================================================
-- 奖池界面处理
-- 关闭界面
--================================================
function Thanksgiving_Close()
	Thanksgiving_Clear()
	Thanksgiving_OnHiden()
end


--================================================
-- 奖池界面处理
-- 返回索引宴会img名字
--================================================
function Thanksgiving_GetFeastImgName(nOptionIndex)
	if nOptionIndex < 1 or nOptionIndex > 9 then
		return
	end
		if nOptionIndex == 1 then
		return "set:Thanksgiving2 image:title1"
	elseif nOptionIndex == 2 then
		return "set:Thanksgiving2 image:title2"
	elseif nOptionIndex == 3 then
		return "set:Thanksgiving2 image:title3"
	elseif nOptionIndex == 4 then
		return "set:Thanksgiving2 image:title4"
	elseif nOptionIndex == 5 then
		return "set:Thanksgiving2 image:title5"
	elseif nOptionIndex == 6 then
		return "set:Thanksgiving2 image:title6"
	elseif nOptionIndex == 7 then
		return "set:Thanksgiving3 image:title7"
	elseif nOptionIndex == 8 then
		return "set:Thanksgiving3 image:title8"
	elseif nOptionIndex == 9 then
		return "set:Thanksgiving3 image:title9"
	end
end


--================================================
-- 奖池界面处理
-- 点选每个宴席
--================================================
function Thanksgiving_FeastClicked( nOptionIndex)
	--判断
	if nOptionIndex < 1 or nOptionIndex > 9 or g_Thanksgiving_CurJackpotIndex == nOptionIndex then
		return
	end
	--获取当前宴index
	local mCurJackpotIndex = DataPool:Lua_GetThanksJackIndex();
	if mCurJackpotIndex < 0 or mCurJackpotIndex > g_Thanksgiving_MaxJackpot then
		PushDebugMessage("Thanksgiving_FeastClicked Data error")
		return
	end
	
	--只能预览还没抽奖的
	if nOptionIndex ==  mCurJackpotIndex + 1 then
		--回到当前奖池
		Thanksgiving_JackpotInfo()
	elseif nOptionIndex >  mCurJackpotIndex + 1 then
		--预览奖池
		Thanksgiving_JackpotPreShow(nOptionIndex)
	end
	
	--按钮状态切换
	for index=1,table.getn(g_Thanksgiving_JackpotList)  do
		if index == nOptionIndex then
			g_Thanksgiving_JackpotList[index]:SetCheck(1)
			g_Thanksgiving_JackpotTitleList[index]:Show()
		else
			g_Thanksgiving_JackpotList[index]:SetCheck(0)
			g_Thanksgiving_JackpotTitleList[index]:Hide()
		end
	end
end

--================================================
-- 奖池界面处理
-- 获得宴会名字
--================================================
function Thanksgiving_GetFeastName( nOptionIndex)
	--判断
	if nOptionIndex < 1 or nOptionIndex > 9 then
		return
	end
	if  nOptionIndex == 1 then
		return "#{GEHJ_181026_11}"
	elseif  nOptionIndex == 2 then
		return "#{GEHJ_181026_12}"
	elseif  nOptionIndex == 3 then
		return "#{GEHJ_181026_13}"
	elseif  nOptionIndex == 4 then
		return "#{GEHJ_181026_14}"
	elseif  nOptionIndex == 5 then
		return "#{GEHJ_181026_15}"
	elseif  nOptionIndex == 6 then
		return "#{GEHJ_181026_16}"
	elseif  nOptionIndex == 7 then
		return "#{GEHJ_181026_17}"
	elseif  nOptionIndex == 8 then
		return "#{GEHJ_181026_18}"
	elseif  nOptionIndex == 9 then
		return "#{GEHJ_181026_19}"
	end
end

--================================================
-- 功能函数，分隔符
--================================================
function Thanksgiving_Split( str,reps )
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
function Thanksgiving_Return()
	KillTimer("Thanksgiving_FiveAnimeTimer()")
	Thanksgiving_OpenFenye( 3 )
end

--================================================
-- 更新剩余饕餮柬数量
--================================================
function Thanksgiving_UpdateTaotieNum()
	local mExNum = DataPool:Lua_ThanksgivingExNum()
	local EXNum = ""
	if mExNum > 0 then
		EXNum = ScriptGlobal_Format("#{GEHJ_181026_33}",mExNum)
		Thanksgiving_Client4_Btn:SetToolTip("#{GEHJ_181026_82}")
	else
		EXNum = ScriptGlobal_Format("#{GEHJ_181026_32}",mExNum)
		Thanksgiving_Client4_Btn:SetToolTip("#{GEHJ_181026_70}")
		Thanksgiving_RemoveRedPoint(4)
	end
	Thanksgiving_Client4_Num:SetText("#{GEHJ_181026_68}"..EXNum)
end

--================================================
-- 奖池界面处理 
-- 额外奖励
-- 九个按钮的显示状态
--================================================
function Thanksgiving_OpenExReward()
	Thanksgiving_UpdateTaotieNum()
	
	--隐藏轮转图片
	for index=1,table.getn(g_Thanksgiving_ExLoopPicList)  do
		g_Thanksgiving_ExLoopPicList[index]:Hide()
	end
	
	--隐藏选中特效
	for index=1,table.getn(g_Thanksgiving_ExLoopAnimeList)  do
		g_Thanksgiving_ExLoopAnimeList[index]:Hide()
		g_Thanksgiving_ExLoopAnimeList[index]:Play(false)
	end
	
	--获取状态
	local nFlagInfo =	DataPool:Lua_ThanksExRewardList();
	--PushDebugMessage("额外奖励  nFlagList="..nFlagInfo)	
	--奖池物品展示
	local nFlagList = Thanksgiving_Split( nFlagInfo,"," )
	local tempNum = 0
	local exItemEnum = Thanksgiving_Libao_GetExItemEnum()
	for index=1,table.getn(g_Thanksgiving_ExRewardList)  do
		if index <= table.getn(nFlagList) then	
			local theAction = DataPool:CreateActionItemForShow(exItemEnum[index].ShowID, 1)
			if theAction:GetID() ~= 0 then
				g_Thanksgiving_ExRewardList[index]:SetActionItem(theAction:GetID());
				g_Thanksgiving_ExRewardList[index]:Show()
				if tonumber(nFlagList[index]) == 0 then
					--待抽取
					g_Thanksgiving_ExMaskList[index]:Hide()
					tempNum = tempNum + 1
				else
					--已经抽了
					g_Thanksgiving_ExMaskList[index]:Show()
				end
			else
				g_Thanksgiving_ExRewardList[index]:Hide()
			end
		end
		--隐藏轮转图片
		g_Thanksgiving_ExLoopPicList[index]:Hide()
		--隐藏选中特效
		g_Thanksgiving_ExLoopAnimeList[index]:Hide()
	end
	
	
	g_Thanksgiving_RemainExItemNo = tempNum
end

--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽奖逻辑
--================================================
function Thanksgiving_GetExRewardBtn()
	--抽奖按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Thanksgiving_ButtonLastTime3 < g_Thanksgiving_ExRewardCDTime * 1000) then
		PushDebugMessage("#{GEHJ_181026_71}"); --当前操作过快，请稍后点击
		return
	end
	g_Thanksgiving_ButtonLastTime3 = curTime;
	

	KillTimer("Thanksgiving_ExItemAnimeTimer()")
	KillTimer("Thanksgiving_ExItemCheckTimer()")
	Thanksgiving_OpenExReward()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetGetExReward")
		Set_XSCRIPT_ScriptID(892839)
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

end


--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽完奖励动画
--================================================
function Thanksgiving_OpenExRewardAnime(nRewardIndex)
	Thanksgiving_UpdateTaotieNum()	

	--隐藏轮转图片
	for index=1,table.getn(g_Thanksgiving_ExLoopPicList)  do
		g_Thanksgiving_ExLoopPicList[index]:Hide()
	end
	
	--隐藏选中特效
	for index=1,table.getn(g_Thanksgiving_ExLoopAnimeList)  do
		g_Thanksgiving_ExLoopAnimeList[index]:Hide()
		g_Thanksgiving_ExLoopAnimeList[index]:Play(false)
	end
	
	--开始动画
	--获取状态
	local nFlagInfo = DataPool:Lua_ThanksExRewardList();
	--PushDebugMessage("额外奖励结束  nFlagList="..nFlagInfo)	
	--奖池物品展示 轮换两遍
	local nFlagList = Thanksgiving_Split( nFlagInfo,"," )
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
	local exItemEnum = Thanksgiving_Libao_GetExItemEnum()
	--看是否需要直接显示
	if nRemainNum == 0 then
		for index=1,table.getn(g_Thanksgiving_ExRewardList)  do
			if index == nRewardIndex then
				--tips
				local itemname = DataPool:Lua_GetItemNameByIndex(exItemEnum[index].Id)
				PushDebugMessage( ScriptGlobal_Format("#{GEHJ_181026_58}",itemname))
				--已经抽了
				--g_Thanksgiving_ExMaskList[index]:Show()
				--选中特效
				g_Thanksgiving_ExLoopAnimeList[index]:Show()
				g_Thanksgiving_ExLoopAnimeList[index]:Play(true)
			end
		end
		return
	end
	
	--还有剩余就需要轮换了
	g_Thanksgiving_ExTimerList = {}
	--乱序
	Thanksgiving_RandomArray(nTempExTimerList1)
	--合并数组
	for index=1,table.getn(nTempExTimerList1)  do	
		if nTempExTimerList1[index] > 0 then
			table.insert(g_Thanksgiving_ExTimerList,nTempExTimerList1[index])
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
	Thanksgiving_RandomArray(nTempExTimerList2)
	
	--合并数组
	for index=1,table.getn(nTempExTimerList2)  do	
		if nTempExTimerList2[index] > 0 then
			table.insert(g_Thanksgiving_ExTimerList,nTempExTimerList2[index])
		end
	end
	
	--插入最后的
	table.insert(g_Thanksgiving_ExTimerList,nRewardIndex)
	
	-- 去闪吧
	g_Thanksgiving_ExTimerIndex = 1
	SetTimer("Thanksgiving","Thanksgiving_ExItemAnimeTimer()", 0)

end

--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽取额外奖励闪动画
-- 闪完常亮
--================================================
function Thanksgiving_ExItemAnimeTimer()
	KillTimer("Thanksgiving_ExItemAnimeTimer()")
	--挨个遍历
	for index=1,table.getn(g_Thanksgiving_ExTimerList)  do	
		local nCurValue = g_Thanksgiving_ExTimerList[index]
		if index == g_Thanksgiving_ExTimerIndex then
			--闪耀
			g_Thanksgiving_ExLoopPicList[nCurValue]:Show()
			g_Thanksgiving_ExLoopPicList[nCurValue]:Play(true)
			if index == table.getn(g_Thanksgiving_ExTimerList) then
				g_Thanksgiving_ExTimerCheckIndex = nCurValue
				SetTimer("Thanksgiving","Thanksgiving_ExItemCheckTimer()", 300)
			end
		end
	end
	if g_Thanksgiving_ExTimerIndex < table.getn(g_Thanksgiving_ExTimerList) then
		g_Thanksgiving_ExTimerIndex = g_Thanksgiving_ExTimerIndex + 1
		SetTimer("Thanksgiving","Thanksgiving_ExItemAnimeTimer()", 1350 - (2*g_Thanksgiving_RemainExItemNo - g_Thanksgiving_ExTimerIndex)*70)
	end
end


--================================================
-- 奖池界面处理 
-- 额外奖励
-- 抽取额外奖励闪动画
-- 选中
--================================================
function Thanksgiving_ExItemCheckTimer()
	KillTimer("Thanksgiving_ExItemCheckTimer()")
	--tips
	--PushDebugMessage("获得物品index="..g_Thanksgiving_ExTimerCheckIndex); 
	local exItemEnum = Thanksgiving_Libao_GetExItemEnum()
	local itemname = DataPool:Lua_GetItemNameByIndex(exItemEnum[g_Thanksgiving_ExTimerCheckIndex].Id)
	PushDebugMessage( ScriptGlobal_Format("#{GEHJ_181026_58}",itemname))
				
	--已经抽了
	--g_Thanksgiving_ExMaskList[g_Thanksgiving_ExTimerCheckIndex]:Show()
	--选中特效
	g_Thanksgiving_ExLoopAnimeList[g_Thanksgiving_ExTimerCheckIndex]:Show()
	g_Thanksgiving_ExLoopAnimeList[g_Thanksgiving_ExTimerCheckIndex]:Play(true)
end
--================================================
-- 功能函数，打乱顺序
--================================================
function Thanksgiving_RandomArray(arr)
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


--yeee--------------------------------------------

--烹饪按钮
function Thanksgiving_Cooking_Button_Click()
	
	if UI_Buttons[3].isOn == 0 then 
		PushDebugMessage("#{GEJY_181027_39}");  --您操作过快，请稍后再试。
		return
	end
	
	-- 活动时间判断
	if Thanksgiving_CheckRightTime() == 0 then  --不在活动时间
		PushDebugMessage("#{GEJY_181027_35}")
		return 0
	end

	-- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90619_04}" )
		return 0
	end
	
    --玩家等级是否已达到30级
    local level = Player : GetData( "LEVEL" )
    if level < g_Thanksgiving_LimitLevel then
        PushDebugMessage( "#{GEJY_181027_36}" ) 
        return 0
    end
	
	if g_Globalvar_List.Menu_Bagpos == -1 then
		PushDebugMessage("#{GEJY_181027_37}");  --请放入普通食谱、初级食谱、高级食谱、或稀有食谱或绝世食谱。
		return
	end

	--是否加锁
	if (PlayerPackage:IsLock(g_Globalvar_List.Menu_Bagpos) == 1) then
		PushDebugMessage("#{GEJY_181027_38}")
		return 0
	end	
	
	local curCateNum = DataPool:Lua_ThanksgivingNum();
	local temp = curCateNum + g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cateAward

	if (curCateNum + g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cateAward) > g_Thanksgiving_maxCate then 
		PushDebugMessage("#{GEJY_181027_40}")  --您本次活动累计获得的佳肴已达到上限，厨师无法继续为您烹饪。
		return 0
	end	
	
	if g_Globalvar_List.CurMenuLevel ~= -1 and g_Globalvar_List.CurCookPage ~= g_Globalvar_List.CurMenuLevel then
		PushDebugMessage("#{GEJY_181027_87}")  --保底
		return 0
	end
	
	if(CalcItemSpace(38002608) < 1) then  --在二次确认框之前判断背包空间？？
		PushDebugMessage("#{GEJY_181027_44}")
		return 0
	end	

	

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "IdentifyItemFC" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892979 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, g_Globalvar_List.Menu_Bagpos );			-- 参数一:类型
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
	
	--Thanksgiving_02CD_Buttons(3)
end

--升级按钮
function Thanksgiving_Upgrade_Button_Click()
	
	if UI_Buttons[4].isOn == 0 then 
		PushDebugMessage("#{GEJY_181027_39}");  --您操作过快，请稍后再试。
		return
	end
	
	-- 活动时间判断
	if Thanksgiving_CheckRightTime() == 0 then  --不在活动时间
		PushDebugMessage("#{GEJY_181027_52}")
		return 0
	end

	-- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90619_04}" )
		return 0
	end
	
    --玩家等级是否已达到30级
    local level = Player : GetData( "LEVEL" )
    if level < g_Thanksgiving_LimitLevel then
        PushDebugMessage( "#{GEJY_181027_53}" ) 
        return 0
    end
	
	if g_Globalvar_List.Menu_Bagpos == -1 then
		PushDebugMessage("#{GEJY_181027_54}");  --请放入普通食谱、初级食谱、高级食谱、或稀有食谱或绝世食谱。
		return
	end

	local ItemIndex = PlayerPackage:GetItemTableIndex(g_Globalvar_List.Menu_Bagpos)
	local currentMenuLevel = -1;

	for i = 1, g_Globalvar_List.MaxMenuLevel do
		if ItemIndex == g_Thanksgiving_List[i].menuID then
			currentMenuLevel = i;
			break
		end
	end
	
	if currentMenuLevel == -1 then
		PushDebugMessage("#{GEJY_181027_54}");  --请放入普通食谱、初级食谱、高级食谱、或稀有食谱或绝世食谱。	
		return 0
	end
	
	if currentMenuLevel == g_Globalvar_List.MaxMenuLevel then
		PushDebugMessage("#{GEJY_181027_93}");  --绝世食谱无需继续进行食谱品质提升
		return 0
	end
	
	if currentMenuLevel == g_Globalvar_List.MaxMenuLevel - 1 then
		PushDebugMessage("#{GEJY_181027_55}");  --高级无需继续进行食谱品质提升
		return 0
	end
	
	--是否加锁
	if (PlayerPackage:IsLock(g_Globalvar_List.Menu_Bagpos) == 1) then
		PushDebugMessage("#{GEJY_181027_56}")
		return
	end
	
	
	local curCooking = DataPool:Lua_GetCookingNum();

	if (curCooking - g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cookingConsume) < 0 then 
		PushDebugMessage("#{GEJY_181027_58}")  --您的厨艺点不足，无法进行食谱品质提升#{GEJY_181027_58}
		return 0
	end	
	
	if(CalcItemSpace(38002608) < 1) then  --在二次确认框之前判断背包空间？？
		PushDebugMessage("#{GEJY_181027_59}")
		return 0
	end	
	
	
	PushEvent( "MENU_UPGRADE_CONFIRM", g_Globalvar_List.Menu_Bagpos, g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel+1].menuName, g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cookingConsume , 1, g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].menuName);		
	
	--Thanksgiving_02CD_Buttons(4)
end

function Thanksgiving_Menu_Help()
	if KaJi:LuaFnIsKaJiServer() == 1 then
		PushEvent( "OPEN_HUODONGTEXT_HELP", 1, "#{GEJY_211116_01}" )
	else
		PushEvent( "OPEN_HUODONGTEXT_HELP", 1, "#{GEJY_181027_20}" )
	end	
end

function Thanksgiving_Menu_Item_RClick()
	Thanksgiving_Clear();
end

--清空menu_item
function Thanksgiving_Clear()

		if g_Globalvar_List.Menu_Bagpos ~= -1 then
			UI_List.Menu_Item : SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(g_Globalvar_List.Menu_Bagpos,0);
			g_Globalvar_List.Menu_Bagpos = -1;
			local str = ScriptGlobal_Format("#{GEJY_181027_14}" , 200)
			UI_List.CookingNum_Tip:SetText(str)
			UI_List.Menu_Name:SetText("")
			UI_List.UpGrade_Button:SetToolTip("#{GEJY_181027_11}")
			g_Globalvar_List.CurMenuLevel = -1
		end

end

--清空old menu_item
function Thanksgiving_ClearOld()
		if g_Globalvar_List.Old_Bagpos ~= -1 then
			UI_List.Menu_Item : SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(g_Globalvar_List.Old_Bagpos,0);
			g_Globalvar_List.Old_Bagpos = -1;
			local str = ScriptGlobal_Format("#{GEJY_181027_14}" , 200)
			UI_List.CookingNum_Tip:SetText(str)
			UI_List.Menu_Name:SetText("")
		end
end


--刷新界面显示（参数来自服务器）uicommand后面调
function Thanksgiving_RefreshAll()

	--PushDebugMessage("3进入刷新函数  Menu_Bagpos"..g_Globalvar_List.Menu_Bagpos.."   CurMenuLevel"..g_Globalvar_List.CurMenuLevel.."   RefreshType"..g_Globalvar_List.RefreshType.."   CurCookPage"..g_Globalvar_List.CurCookPage)	
	--PushDebugMessage("xxx3 g_Globalvar_List.CurCookingNum"..g_Globalvar_List.CurCookingNum.."g_Globalvar_List.CurCateNum"..g_Globalvar_List.CurCateNum)	

--	UI_List.CookingNum_Text:SetText(g_Globalvar_List.CurCookingNum)  --更新厨艺点
--	UI_List.CateNum_Text:SetText(g_Globalvar_List.CurCateNum)  --更新佳肴
--	UI_List.Taotie_Text:SetText(g_Thanksgiving_curTaotie)  --更新饕餮
	
	local catenumstr = ScriptGlobal_Format("#{GEJY_181027_08}" , g_Globalvar_List.CurCateNum)
	UI_List.CateNum_Text:SetText(catenumstr)  --更新佳肴
	local cookingnumstr = ScriptGlobal_Format("#{GEJY_181027_12}" , g_Globalvar_List.CurCookingNum)
	UI_List.CookingNum_Text:SetText(cookingnumstr)  --更新厨艺点
	local taotienumstr = ScriptGlobal_Format("#{GEJY_181027_90}" , g_Thanksgiving_curTaotie)
	UI_List.Taotie_Text:SetText(taotienumstr)  --更新饕餮	
	
	Thanksgiving_CanBeLevelup()
	
	if g_Globalvar_List.RefreshType == 1 then  -- 有新item放入（手动）

		for idx = 1, g_Globalvar_List.MaxMenuLevel do
			if idx == g_Globalvar_List.CurMenuLevel then
				g_Thanksgiving_List[idx].cookimg:Show()  -- 新厨师图
				g_Thanksgiving_List[idx].cookbk:Show()  -- 新厨师名字板
				UI_List.Cook_Name:SetText(g_Thanksgiving_List[idx].cooknameUI)  --新厨师名
				UI_List.Cook_Saying:SetText(g_Thanksgiving_List[idx].saying1)  --新厨师文字
			else
				g_Thanksgiving_List[idx].cookimg:Hide()
				g_Thanksgiving_List[idx].cookbk:Hide()
			end
		end
		--修改食谱名字和厨艺点tip
		if g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cookingConsume ~= -1 then
			local tip = ScriptGlobal_Format(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cookingTips, g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cookingConsume)	
			UI_List.CookingNum_Tip:SetText(tip)
		else 
			UI_List.CookingNum_Tip:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].cookingTips)
		end
		UI_List.Menu_Name:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].menuNameUI)
		
		--把新食谱置入item
		local theAction = EnumAction(g_Globalvar_List.Menu_Bagpos, "packageitem");
		UI_List.Menu_Item:SetActionItem(theAction:GetID())
		LifeAbility : Lock_Packet_Item(g_Globalvar_List.Menu_Bagpos,1);
	
	elseif g_Globalvar_List.RefreshType == 0 then  --鉴定成功 item为空 但是需要改文字

		if Thanksgiving_IfCurPosNil(g_Globalvar_List.Menu_Bagpos) ~= 1 then  --不空
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].saying2)  --切换当前等级的鉴定文字2
		else
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].saying2)  --切换当前等级的鉴定文字2
			local str = ScriptGlobal_Format("#{GEJY_181027_14}" , 200)
			UI_List.CookingNum_Tip:SetText(str)
			UI_List.Menu_Name:SetText("")
			Thanksgiving_Clear();
		end

		SetTimer("Thanksgiving_IdentifyAnimeTimer","Thanksgiving_IdentifyAnimeTimer()", 50)
	
	elseif g_Globalvar_List.RefreshType == -1 then  -- 初始化/重新打开
		local str = ScriptGlobal_Format("#{GEJY_181027_14}" , 200)
		UI_List.CookingNum_Tip:SetText(str)
		UI_List.Menu_Name:SetText("")
		for idx = 1, g_Globalvar_List.MaxMenuLevel do
			if idx == g_Globalvar_List.CurCookPage then
				g_Thanksgiving_List[idx].cookimg:Show()  -- 新厨师图
				g_Thanksgiving_List[idx].cookbk:Show()  -- 新厨师图
				UI_List.Cook_Name:SetText(g_Thanksgiving_List[idx].cooknameUI)  --新厨师名
				UI_List.Cook_Saying:SetText(g_Thanksgiving_List[idx].saying1)  --新厨师文字
			else
				g_Thanksgiving_List[idx].cookimg:Hide()
				g_Thanksgiving_List[idx].cookbk:Hide()
			end
		end
		
	elseif g_Globalvar_List.RefreshType == 2 then  -- 来自升级的升级
		--PushDebugMessage("来自升级的升级  Menu_Bagpos"..g_Globalvar_List.Menu_Bagpos.."   CurMenuLevel"..g_Globalvar_List.CurMenuLevel.."   RefreshType"..g_Globalvar_List.RefreshType.."   CurCookPage"..g_Globalvar_List.CurCookPage)	
		
		if Thanksgiving_IfCurPosNil(g_Globalvar_List.Menu_Bagpos) ~= 1 then  --不空
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].saying4)  --切换当前等级的鉴定文字4
		else
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].saying4)  --切换当前等级的鉴定文字4
			local str = ScriptGlobal_Format("#{GEJY_181027_14}" , 200)
			UI_List.CookingNum_Tip:SetText(str)
			UI_List.Menu_Name:SetText("")
		end	
		
		SetTimer("Thanksgiving_UpgradeAnimeTimer","Thanksgiving_UpgradeAnimeTimer()", 50)
			
		PushEvent( "MENU_UPANDGO_CONFIRM", g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel+1].menuName, g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel+1].cookname , 1);		
	
	elseif g_Globalvar_List.RefreshType == 3 then  -- 来自鉴定的升级	
		--PushDebugMessage("来自鉴定的升级  Menu_Bagpos"..g_Globalvar_List.Menu_Bagpos.."   CurMenuLevel"..g_Globalvar_List.CurMenuLevel.."   RefreshType"..g_Globalvar_List.RefreshType.."   CurCookPage"..g_Globalvar_List.CurCookPage)	
	
		if Thanksgiving_IfCurPosNil(g_Globalvar_List.Menu_Bagpos) ~= 1 then  --不空
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].saying3)  --切换当前等级的鉴定文字3
		else
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].saying3)  --切换当前等级的鉴定文字3
			local str = ScriptGlobal_Format("#{GEJY_181027_14}" , 200)
			UI_List.CookingNum_Tip:SetText(str)
			UI_List.Menu_Name:SetText("")
		end
		
		SetTimer("Thanksgiving_UpgradeAnimeTimer","Thanksgiving_UpgradeAnimeTimer()", 50)
		
		PushEvent( "MENU_UPANDGO_CONFIRM", g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel+1].menuName, g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel+1].cookname , 1);		
	
	end
	
	--PushDebugMessage("xxx4 g_Globalvar_List.CurCookingNum"..g_Globalvar_List.CurCookingNum.."g_Globalvar_List.CurCateNum"..g_Globalvar_List.CurCateNum)	
	
	if g_Globalvar_List.CurCookPage == 1 then
		UI_List.PreCook_Button:Disable()
	else 
		UI_List.PreCook_Button:Enable()
	end
	
	if g_Globalvar_List.CurCookPage == g_Globalvar_List.MaxMenuLevel then
		UI_List.NextCook_Button:Disable()
	else 
		UI_List.NextCook_Button:Enable()
	end
	
end

function Thanksgiving_UpAndGo(isGO)  --升级跳转
	
	if isGO == 1 then --切换
		local theAction = EnumAction(g_Thanksgiving_newPos, "packageitem");
		UI_List.Menu_Item:SetActionItem(theAction:GetID());
		
		if g_Globalvar_List.Menu_Bagpos ~= -1 then
			LifeAbility : Lock_Packet_Item(g_Globalvar_List.Menu_Bagpos,0);
		end
		g_Globalvar_List.RefreshType = 1	
		g_Globalvar_List.Menu_Bagpos = g_Thanksgiving_newPos;
		LifeAbility : Lock_Packet_Item(g_Globalvar_List.Menu_Bagpos,1);
		g_Globalvar_List.CurMenuLevel = g_Globalvar_List.CurMenuLevel + 1
		g_Globalvar_List.CurCookPage = g_Globalvar_List.CurCookPage + 1			
		g_Thanksgiving_newPos = -1
			
		Thanksgiving_RefreshAll()		
	
	else  --不切换
		if Thanksgiving_IfCurPosNil(g_Globalvar_List.Menu_Bagpos) ~= 1 then  --不空
		--donothing
		else
			local str = ScriptGlobal_Format("#{GEJY_181027_14}" , 200)
			UI_List.CookingNum_Tip:SetText(str)
			UI_List.Menu_Name:SetText("")
			Thanksgiving_Clear();
		end
	end

end

function Thanksgiving_PreCook_Click()
	
	if UI_Buttons[1].isOn == 0 then 
		PushDebugMessage("#{GEJY_181027_39}");  --您操作过快，请稍后再试。
		return
	end
		
	UI_List.NextCook_Button:Enable()
    if g_Globalvar_List.CurCookPage < 1 or g_Globalvar_List.CurCookPage > g_Globalvar_List.MaxMenuLevel then
		g_Globalvar_List.CurCookPage = 1
    end
	
	if g_Globalvar_List.CurCookPage - 1 <= 1 then
		g_Globalvar_List.CurCookPage = 1
		UI_List.PreCook_Button:Disable()
	else
		g_Globalvar_List.CurCookPage = g_Globalvar_List.CurCookPage - 1
	end	

   
	for idx = 1, g_Globalvar_List.MaxMenuLevel do
		if idx == g_Globalvar_List.CurCookPage then
			g_Thanksgiving_List[idx].cookimg:Show()  -- 新厨师图
			g_Thanksgiving_List[idx].cookbk:Show()  -- 新厨师图
			UI_List.Cook_Name:SetText(g_Thanksgiving_List[idx].cooknameUI)  --新厨师名
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[idx].saying1)  --新厨师文字
		else
			g_Thanksgiving_List[idx].cookimg:Hide()
			g_Thanksgiving_List[idx].cookbk:Hide()
		end
	end
	Thanksgiving_Clear();
	
	Thanksgiving_CanBeLevelup()	
	
	g_Globalvar_List.CDButton_Index = 1
	Thanksgiving_02CD_Buttons()
end

function Thanksgiving_NextCook_Click()
	
	if UI_Buttons[2].isOn == 0 then 
		PushDebugMessage("#{GEJY_181027_39}");  --您操作过快，请稍后再试。
		return
	end
		
	UI_List.PreCook_Button:Enable()
    if g_Globalvar_List.CurCookPage < 1 or g_Globalvar_List.CurCookPage > g_Globalvar_List.MaxMenuLevel then
		g_Globalvar_List.CurCookPage = g_Globalvar_List.MaxMenuLevel
    end
	
	if g_Globalvar_List.CurCookPage + 1 >= g_Globalvar_List.MaxMenuLevel then
		g_Globalvar_List.CurCookPage = g_Globalvar_List.MaxMenuLevel
		UI_List.NextCook_Button:Disable()
	else
		g_Globalvar_List.CurCookPage = g_Globalvar_List.CurCookPage + 1
	end	
	
	Thanksgiving_CanBeLevelup()
   
	for idx = 1, g_Globalvar_List.MaxMenuLevel do
		if idx == g_Globalvar_List.CurCookPage then
			g_Thanksgiving_List[idx].cookimg:Show()  -- 新厨师图
			g_Thanksgiving_List[idx].cookbk:Show()  -- 新厨师图
			UI_List.Cook_Name:SetText(g_Thanksgiving_List[idx].cooknameUI)  --新厨师名
			UI_List.Cook_Saying:SetText(g_Thanksgiving_List[idx].saying1)  --新厨师文字
		else
			g_Thanksgiving_List[idx].cookimg:Hide()
			g_Thanksgiving_List[idx].cookbk:Hide()
		end
	end
	Thanksgiving_Clear();
	g_Globalvar_List.CDButton_Index = 2
	Thanksgiving_02CD_Buttons()
end

function Thanksgiving_UpdateItem(param0)
	
	local pos_packet =tonumber(param0)
	
	local theAction = EnumAction(pos_packet, "packageitem");
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)

	if theAction:GetID() ~= 0 then

		-- 判断当前物品是否为普通食谱、初级食谱、高级食谱、稀有食谱、绝世食谱
		local isMenu = 0
		for idx = 1, g_Globalvar_List.MaxMenuLevel do
			if ItemID == g_Thanksgiving_List[idx].menuID then
				isMenu = 1
				g_Globalvar_List.CurMenuLevel = idx
				break
			end
		end
		if isMenu == 0 then 
			PushDebugMessage("#{GEJY_181027_33}");  --请放入食谱
			return
		end
		
		if g_Globalvar_List.CurMenuLevel ~= -1 then
			g_Globalvar_List.CurCookPage = g_Globalvar_List.CurMenuLevel
		end
		
		--是否加锁
		if PlayerPackage:IsLock(pos_packet) == 1 then
			PushDebugMessage("#{GEJY_181027_34}");  --当前物品已加锁。
			--g_Globalvar_List.CurMenuLevel = -1
			return
		end
		UI_List.Menu_Item:SetActionItem(theAction:GetID());
		if g_Globalvar_List.Menu_Bagpos ~= -1 then
			LifeAbility : Lock_Packet_Item(g_Globalvar_List.Menu_Bagpos,0);
		end

		g_Globalvar_List.RefreshType = 1	
		g_Globalvar_List.Menu_Bagpos = pos_packet;
		LifeAbility : Lock_Packet_Item(g_Globalvar_List.Menu_Bagpos,1);
		
		Thanksgiving_RefreshAll()
		
	else
		UI_List.Menu_Item:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(g_Globalvar_List.Menu_Bagpos,0);
		g_Globalvar_List.Menu_Bagpos = -1;
		g_Globalvar_List.CurMenuLevel = -1;
		Thanksgiving_RefreshAll()
		return
	end
end


function Thanksgiving_MenuItem_RClick()
	Thanksgiving_Clear();
end

function Thanksgiving_MakeAllButtons_Disabled()
	for idx = 1, 4 do 
		--UI_Buttons[idx].widget:Disable()
		UI_Buttons[idx].isOn = 0
	end
end

function Thanksgiving_MakeAllButtons_Enabled()
	for idx = 1, 4 do 
		--UI_Buttons[idx].widget:Enable()
		UI_Buttons[idx].isOn = 1
	end
end

function Thanksgiving_02_Timer()
	g_Globalvar_List._02_Timer = 0
	KillTimer("Thanksgiving_02_Timer()")
	--UI_Buttons[g_Globalvar_List.CDButton_Index].widget:Enable()
	UI_Buttons[g_Globalvar_List.CDButton_Index].isOn = 1
	g_Globalvar_List.CDButton_Index = -1
end

function Thanksgiving_02CD_Buttons()
	if g_Globalvar_List.CDButton_Index ~= -1 then
		if g_Globalvar_List._02_Timer == 0 then
			g_Globalvar_List._02_Timer = 1
			SetTimer("Thanksgiving_02_Timer","Thanksgiving_02_Timer()", 200)
			--UI_Buttons[g_Globalvar_List.CDButton_Index].widget:Disable()
			UI_Buttons[g_Globalvar_List.CDButton_Index].isOn = 0
		end
	end
end

function Thanksgiving_05_Timer()
	g_Globalvar_List._05_Timer = 0
	KillTimer("Thanksgiving_05_Timer()")
	Thanksgiving_MakeAllButtons_Enabled()
end

function Thanksgiving_CheckRightTime()
	local curDayTime = tonumber(DataPool:GetServerDayTime());
	if curDayTime >= g_Thanksgiving_BeginTime and curDayTime <= g_Thanksgiving_FinalEndTime then
		return 1  --在活动时间
	else
		return 0  --不在活动时间
	end
end

function Thanksgiving_IfCurPosNil(bagpos)
	local ItemIndex = PlayerPackage:GetItemTableIndex(g_Globalvar_List.Menu_Bagpos)
	
	--PushDebugMessage("IfCurPosNil:ItemIndex "..ItemIndex.." Menu_Bagpos "..g_Globalvar_List.Menu_Bagpos)
	local currentMenuLevel = -1;

	for i = 1, g_Globalvar_List.MaxMenuLevel do
		if ItemIndex == g_Thanksgiving_List[i].menuID then
			currentMenuLevel = i;
			break
		end
	end
	
	if currentMenuLevel == -1 or ItemIndex == -1 or g_Globalvar_List.CurMenuLevel ~= currentMenuLevel then
		return 1
	else 
		return 0
	end
	
end

function Thanksgiving_OpenIdentify()
		g_Globalvar_List.CurCookingNum = DataPool:Lua_GetCookingNum()  --更新厨艺点
		g_Globalvar_List.CurCateNum = DataPool:Lua_ThanksgivingNum();  --更新佳肴
		g_Thanksgiving_curTaotie =  DataPool:Lua_GetTaotieNum()    --更新饕餮
		g_Globalvar_List.CurMenuLevel = -1
		--修改打开时看到的页面
		if g_Globalvar_List.CurCookPage == -1 then g_Globalvar_List.CurCookPage = 1 end
		g_Globalvar_List.RefreshType = -1
		Thanksgiving_RefreshAll()		
		g_Thanksgiving_isMe = 1
		
	for index = 1, table.getn(g_Thanksgiving_UpgradeAnimeList) do
		g_Thanksgiving_UpgradeAnimeList[index].widget:Hide()
	end	
	
	for index = 1, table.getn(g_Thanksgiving_IdentifyAnimeList) do
		g_Thanksgiving_IdentifyAnimeList[index].widget:Hide()
	end
	
	if KaJi:LuaFnIsKaJiServer() == 1 then
		Thanksgiving_Menu_PointIcon:SetToolTip("#{GEJY_211116_02}")
		Thanksgiving_Menu_PointNum:SetToolTip("#{GEJY_211116_02}")
	else
		Thanksgiving_Menu_PointIcon:SetToolTip("#{GEJY_181027_13}")
		Thanksgiving_Menu_PointNum:SetToolTip("#{GEJY_181027_13}")
	end	
end

function Thanksgiving_CanBeLevelup()

	if (g_Globalvar_List.CurMenuLevel == g_Globalvar_List.MaxMenuLevel) or (g_Globalvar_List.CurMenuLevel == g_Globalvar_List.MaxMenuLevel - 1)
		or (g_Globalvar_List.CurCookPage == g_Globalvar_List.MaxMenuLevel) or (g_Globalvar_List.CurCookPage == g_Globalvar_List.MaxMenuLevel - 1) then
		UI_List.Cook_Button:Hide()
		UI_List.UpGrade_Button:Hide()
		UI_List.NewButton:Show()
		UI_List.CookingNum_Tip:Hide()
		return 1
	else
		UI_List.Cook_Button:Show()
		UI_List.UpGrade_Button:Show()
		UI_List.NewButton:Hide()
		UI_List.CookingNum_Tip:Show()
		UI_List.UpGrade_Button:SetToolTip(g_Thanksgiving_List[g_Globalvar_List.CurMenuLevel].upGradeTip)
		return 0
	end
end


--鉴定动画

function Thanksgiving_IdentifyAnimeTimer()
	KillTimer("Thanksgiving_IdentifyAnimeTimer()")
	--挨个播
	g_Thanksgiving_IdentifyAnimeIndex = g_Thanksgiving_IdentifyAnimeIndex + 1
	for index = 1, table.getn(g_Thanksgiving_IdentifyAnimeList) do
		if g_Thanksgiving_IdentifyAnimeIndex == index then
			g_Thanksgiving_IdentifyAnimeIndex = index
			g_Thanksgiving_IdentifyAnimeList[index].widget:Show()
			g_Thanksgiving_IdentifyAnimeList[index].widget:Play(true)
			if g_Thanksgiving_IdentifyAnimeIndex < table.getn(g_Thanksgiving_IdentifyAnimeList) then	
				SetTimer("Thanksgiving_IdentifyAnimeTimer","Thanksgiving_IdentifyAnimeTimer()", g_Thanksgiving_IdentifyAnimeList[index].delay)
			else 
				g_Thanksgiving_IdentifyAnimeIndex = 0
			end
		end
	end	
end


--升级动画
function Thanksgiving_UpgradeAnimeTimer()
	KillTimer("Thanksgiving_UpgradeAnimeTimer()")
	--挨个播
	g_Thanksgiving_UpgradeAnimeIndex = g_Thanksgiving_UpgradeAnimeIndex + 1
	for index = 1, table.getn(g_Thanksgiving_UpgradeAnimeList) do
		if g_Thanksgiving_UpgradeAnimeIndex == index then
			g_Thanksgiving_UpgradeAnimeIndex = index
			g_Thanksgiving_UpgradeAnimeList[index].widget:Show()
			g_Thanksgiving_UpgradeAnimeList[index].widget:Play(true)
			if g_Thanksgiving_UpgradeAnimeIndex < table.getn(g_Thanksgiving_UpgradeAnimeList) then	
				SetTimer("Thanksgiving_UpgradeAnimeTimer","Thanksgiving_UpgradeAnimeTimer()", g_Thanksgiving_UpgradeAnimeList[index].delay)
			else 
				g_Thanksgiving_UpgradeAnimeIndex = 0
			end
		end
	end	
end


function Thanksgiving_FestivalGift_UIUpdate()
	--展示节日礼包
	local bGet = Pneuma:GetMF(g_Thanksgiving_FestivalGiftFlag)
	if bGet > 0 then
		UI_List.FestivalGift:Hide()
	else
		local nLevel = Player:GetLevel()
		if nLevel < g_Thanksgiving_LimitLevel then
			--小红点
			UI_List.FestivalGift_Tip:Hide()
		else
			UI_List.FestivalGift_Tip:Show()
		end
		UI_List.FestivalGift:Show()
	end
end

function Thanksgiving_FestivalGift_RedPoint_Update()
	--展示节日礼包
	local bGet = Pneuma:GetMF(g_Thanksgiving_FestivalGiftFlag)
	if bGet > 0 then
		UI_List.FestivalGift_Tip:Hide()
	else
		local nLevel = Player:GetLevel()
		if nLevel < g_Thanksgiving_LimitLevel then
			--小红点
			UI_List.FestivalGift_Tip:Hide()
		else
			UI_List.FestivalGift_Tip:Show()
		end
	end
end

-- 节日礼包
function Thanksgiving_Libao_Clicked()
	-- 活动时间判断
	if Thanksgiving_CheckRightTime() == 0 then  --不在活动时间
		PushDebugMessage("#{GEHJ_181026_107}")
		return 0
	end
	
    -- 玩家等级是否已达到30级
    local level = Player : GetData( "LEVEL" )
    if level < g_Thanksgiving_LimitLevel then
        PushDebugMessage( "#{GEHJ_181026_108}" ) 
        return 0
	end
	
	--是否领取过节日礼包
	if Pneuma:GetMF(g_Thanksgiving_FestivalGiftFlag) > 0 then
		PushDebugMessage( "#{GEHJ_181026_114}" )
		return
	end

	--关闭整合界面
	Thanksgiving_OnHiden()
	
	-- 开启节日礼包界面
	PushEvent("THANKSGIVING_GIFT_OPENUI")
end

function Thanksgiving_Libao_GetGiftData()
	local kajiType = KaJi:LuaFnGetKaJiType(g_Thanksgiving_FestivalGift_KJID)
	if kajiType >= 0 and kajiType <= table.getn(g_Thanksgiving_JackpotItemEnum) then
		return g_Thanksgiving_JackpotItemEnum[kajiType]
	end

	-- 默认原服
	return g_Thanksgiving_JackpotItemEnum[0]
end

function Thanksgiving_Libao_GetExItemEnum()
	local kajiType = KaJi:LuaFnGetKaJiType(g_Thanksgiving_FestivalGift_KJID)
	if kajiType >= 0 and kajiType <= table.getn(g_Thanksgiving_ExItemEnum) then
		return g_Thanksgiving_ExItemEnum[kajiType]
	end

	-- 默认原服
	return g_Thanksgiving_ExItemEnum[0]
end