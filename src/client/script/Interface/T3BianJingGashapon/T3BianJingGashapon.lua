--T3BianJingGashapon
local g_T3BianJingGashapon_UnifiedPosition;

local T3BianJingGashapon_BuyItem_Num = {}
local g_T3BianJingGashapon_ItemNumMax = 999
local g_T3BianJingGashapon_ShowItemInfo = {}
local g_T3BianJingGashapon_ShowImage = {}
local g_T3BianJingGashapon_ShowStar = {}
local T3BianJingGashapon_ActionButton = {}
local T3BianJingGashapon_ItemName = {}
local T3BianJingGashapon_ItemButton = {}
local T3BianJingGashapon_ItemText1 = {}
local T3BianJingGashapon_Num = {}
local T3BianJingGashapon_Cost = {}
local T3BianJingGashapon_Limit = {}
local T3BianJingGashapon_Mark = {}
local T3BianJingGashapon_Mark2 = {}
local T3BianJingGashapon_Special = {}
local T3BianJingGashapon_LimitBK = {}
local T3BianJingGashapon_Preview = {}
local T3BianJingGashapon_pagebuttonleft = {}
local T3BianJingGashapon_ImageStar = {}
local T3BianJingGashapon_ImageAnim = {}
local T3BianJingGashapon_Image = {}
local T3BianJingGashapon_ImageAnimPulse = {}
local T3BianJingGashapon_ImageStarList1 = {}
local T3BianJingGashapon_ImageStarList2 = {}
local T3BianJingGashapon_ImageStarList3 = {}
local T3BianJingGashapon_ImageStarList4 = {}
local T3BianJingGashapon_ImageStarList5 = {}
local T3BianJingGashapon_rewardImage = {}
local T3BianJingGashapon_rewardTitle = {}
local T3BianJingGashapon_rewardImageStill = {}
local T3BianJingGashapon_rewardAnimAppear = {}
local T3BianJingGashapon_rewardAnimFailed = {}
local T3BianJingGashapon_rewardAnimSuccessed = {}
local T3BianJingGashapon_StarApper = {}
local T3BianJingGashapon_StarBroken = {}
local T3BianJingGashapon_StarDefense = {}

local g_curpageIndex = 0
local g_client1Index = 0
local g_curStarData = 0
local g_curRewardStar = 0
local g_curRewardIndex = 0
local g_RewardUIIndex = 0
local g_ItemLimitFlag = 0
local g_BuchangDaibi = 0
local g_FailFlag = 0
local g_curDoMakeCount = 0
local g_baohucount = 0
local g_lastRewardType = 0
local g_lastRewardStar = 0
local g_isShowRedPoint = 0
local g_isGet = 0
local g_IsPlay = 0
local g_Step = 0
local g_Round = 0
local g_animate = {round = 3, minSpeed = 20, decay = 10}
local g_animateState = 0
local g_operatortype = 0
local g_Param = 0
local g_curState = 0
local g_SelectRewardIndex = 0

local g_AnimTime = {
	[1] = {apper = 600, faild = 1200, success = 1400},
	[2] = {apper = 600, faild = 1200, success = 1200},
	[3] = {apper = 600, faild = 1400, success = 1400},
	[4] = {apper = 600, faild = 1400, success = 1400},
	[5] = {apper = 500, faild = 2000, success = 1200},
}

local g_StarText = {"一", "二", "三", "四", "五", "六", "七"}
-------商店
local g_curShopType = 0
local g_curDaibi1 = 0
local g_curDaibi2 = 0
local g_DuiHuan_MD_List = {}
local g_CurPageItemMax = 12
local g_CurShopPage = 0

local g_Star1List = {1,3,4,6,7,9}
local g_Star2List = {2,8}
local g_Star3List = {5}

--美食券
local g_MeishiQuanID = 38005702
local g_MeishiQuanCount = 1

--免费券
local g_FreeQuanID = 38005703
local g_FreeQuanCount = 1

--美食币数量
local g_RewardDaibi = {
 [0] = 2,
 [1] = 4,
 [2] = 16,
 [3] = 20,
 [4] = 110,
 [5] = 300,
 [6] = 650,
 [7] = 2800,
}
--奖池为空对应代币
local g_RewardBuchongDaibi = {
 [0] = 0,
 [1] = 0,
 [2] = 0,
 [3] = 40,
 [4] = 200,
 [5] = 500,
 [6] = 1000,
 [7] = 4000,
}
--保护追加补偿代币
local g_BuchangDaibiList = {
 [0] = 0,
 [1] = 1,
 [2] = 2,
 [3] = 6,
 [4] = 16,
 [5] = 24,
 [6] = 90,
 [7] = 0,
}

--所需元宝数
local g_NeedYBCount = {
 [0] = 110,
 [1] = 150,
 [2] = 200,
 [3] = 1200,
 [4] = 3200,
 [5] = 4800,
 [6] = 18000,
 [7] = 0,
}
--保护调制必定成功次数
local g_BaodiCount = 2

local g_Daibi1ShowID = 39923751
--活动时间
local g_BeginTime = 20220324
local g_EndTime = 20220331

local T3BianJingGashapon_ImageStill = {
	[1] = "set:Ach1 image:WDTXPMBtn_1_Normal",
	[2] = "set:Ach1 image:WDTXPMBtn_2_Normal",
	[3] = "set:Ach1 image:WDTXPMBtn_3_Normal",
	[4] = "set:Ach1 image:WDTXPMBtn_4_Normal",
	[5] = "set:Ach1 image:WDTXPMBtn_5_Normal",
}
function T3BianJingGashapon_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("UPDATE_YUANBAO",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function T3BianJingGashapon_OnLoad()

	T3BianJingGashapon_pagebuttonleft[1] = T3BianJingGashapon_ButtonTab01
	T3BianJingGashapon_pagebuttonleft[2] = T3BianJingGashapon_ButtonTab02
	T3BianJingGashapon_pagebuttonleft[3] = T3BianJingGashapon_ButtonTab03
	
	T3BianJingGashapon_ImageStar[0] = T3BianJingGashapon_Client1_Frame3_ImageStar0
	T3BianJingGashapon_ImageStar[1] = T3BianJingGashapon_Client1_Frame3_ImageStar1
	T3BianJingGashapon_ImageStar[2] = T3BianJingGashapon_Client1_Frame3_ImageStar2
	T3BianJingGashapon_ImageStar[3] = T3BianJingGashapon_Client1_Frame3_ImageStar3
	T3BianJingGashapon_ImageStar[4] = T3BianJingGashapon_Client1_Frame3_ImageStar4
	T3BianJingGashapon_ImageStar[5] = T3BianJingGashapon_Client1_Frame3_ImageStar5
	T3BianJingGashapon_ImageStar[6] = T3BianJingGashapon_Client1_Frame3_ImageStar6
	T3BianJingGashapon_ImageStar[7] = T3BianJingGashapon_Client1_Frame3_ImageStar7
	
	
	T3BianJingGashapon_ImageStarList1[1] = T3BianJingGashapon_Client1_Frame1_Image1StarBK1
	T3BianJingGashapon_ImageStarList1[2] = T3BianJingGashapon_Client1_Frame1_Image1StarBK2
	T3BianJingGashapon_ImageStarList1[3] = T3BianJingGashapon_Client1_Frame1_Image1StarBK3
	T3BianJingGashapon_ImageStarList2[1] = T3BianJingGashapon_Client1_Frame1_Image2StarBK1
	T3BianJingGashapon_ImageStarList2[2] = T3BianJingGashapon_Client1_Frame1_Image2StarBK2
	T3BianJingGashapon_ImageStarList2[3] = T3BianJingGashapon_Client1_Frame1_Image2StarBK3	
	T3BianJingGashapon_ImageStarList3[1] = T3BianJingGashapon_Client1_Frame1_Image3StarBK1
	T3BianJingGashapon_ImageStarList3[2] = T3BianJingGashapon_Client1_Frame1_Image3StarBK2
	T3BianJingGashapon_ImageStarList3[3] = T3BianJingGashapon_Client1_Frame1_Image3StarBK3
	T3BianJingGashapon_ImageStarList4[1] = T3BianJingGashapon_Client1_Frame1_Image4StarBK1
	T3BianJingGashapon_ImageStarList4[2] = T3BianJingGashapon_Client1_Frame1_Image4StarBK2
	T3BianJingGashapon_ImageStarList4[3] = T3BianJingGashapon_Client1_Frame1_Image4StarBK3
	T3BianJingGashapon_ImageStarList5[1] = T3BianJingGashapon_Client1_Frame1_Image5StarBK1
	T3BianJingGashapon_ImageStarList5[2] = T3BianJingGashapon_Client1_Frame1_Image5StarBK2
	T3BianJingGashapon_ImageStarList5[3] = T3BianJingGashapon_Client1_Frame1_Image5StarBK3
	
	for i = 1, 5 do
		T3BianJingGashapon_Image[i] = "T3BianJingGashapon_Client1_Frame1_Image" .. i
		T3BianJingGashapon_ImageAnim[i] = "T3BianJingGashapon_Client1_Frame1_Image" .. i .."Anim"
		T3BianJingGashapon_ImageAnimPulse[i] = "T3BianJingGashapon_Client1_Frame1_Image" .. i .."Pulse"
		--T3BianJingGashapon_rewardImage[i] = "T3BianJingGashapon_Client1_Frame3_Image".. i
		T3BianJingGashapon_rewardTitle[i] = "T3BianJingGashapon_Client1_Frame3_ImageTitle"..i
		--T3BianJingGashapon_rewardImageStill[i] = "T3BianJingGashapon_Client1_Frame3_Image".. i .."Still"
		--T3BianJingGashapon_rewardAnimAppear[i] = "T3BianJingGashapon_Client1_Frame3_Image".. i .."AnimAppear"
		--T3BianJingGashapon_rewardAnimFailed[i] = "T3BianJingGashapon_Client1_Frame3_Image".. i .."AnimFailed"
		--T3BianJingGashapon_rewardAnimSuccessed[i] = "T3BianJingGashapon_Client1_Frame3_Image".. i .."AnimSuccessd"
	end
	
	for i = 1, 5 do
		g_T3BianJingGashapon_ShowImage[i] = {
			Image = _G[T3BianJingGashapon_Image[i]],
			ImageLight = _G[T3BianJingGashapon_ImageAnim[i]],
			ImageAnimPulse = _G[T3BianJingGashapon_ImageAnimPulse[i]],
			--RewardImageFrame = _G[T3BianJingGashapon_rewardImage[i]],
			RewardTitle = _G[T3BianJingGashapon_rewardTitle[i]],
			--RewardStill = _G[T3BianJingGashapon_rewardImageStill[i]],
			--AnimAppear = _G[T3BianJingGashapon_rewardAnimAppear[i]],
			--AnimFailed = _G[T3BianJingGashapon_rewardAnimFailed[i]],
			--AnimSuccessed = _G[T3BianJingGashapon_rewardAnimSuccessed[i]],
		}
	end
	for i = 1, 7 do
		T3BianJingGashapon_StarApper[i] = "T3BianJingGashapon_Client1_Frame3_ImageStar".. i .."_Appear"
		T3BianJingGashapon_StarBroken[i] = "T3BianJingGashapon_Client1_Frame3_ImageStar".. i .."_Broken"
		T3BianJingGashapon_StarDefense[i] = "T3BianJingGashapon_Client1_Frame3_ImageStar".. i .."_Defense"
	end
	for i = 1, 7 do
		g_T3BianJingGashapon_ShowStar[i] = {
			StarApper = _G[T3BianJingGashapon_StarApper[i]],
			StarBroken = _G[T3BianJingGashapon_StarBroken[i]],
			StarDefense = _G[T3BianJingGashapon_StarDefense[i]],
		}
	end
	--商店界面
	for i = 1, 12 do
		T3BianJingGashapon_ActionButton[i] = "T3BianJingGashapon_Client2_Item".. i
		T3BianJingGashapon_ItemName[i] = "T3BianJingGashapon_Client2_ItemInfo" .. i .."_Text"
		--T3BianJingGashapon_ItemButton[i] = "DuanWu_JiFenShop_Item".. i
		T3BianJingGashapon_Num[i] = "T3BianJingGashapon_Client2_Item" .. i .. "_BuyLimitNum"
		T3BianJingGashapon_Cost[i] = "T3BianJingGashapon_Client2_ItemInfo".. i .."_Currency"
		T3BianJingGashapon_Mark[i] = "T3BianJingGashapon_Client2_Item".. i .. "_SellOut"
		T3BianJingGashapon_Mark2[i] = "T3BianJingGashapon_Client2_Item".. i .."_Mask"
		T3BianJingGashapon_Limit[i] = "T3BianJingGashapon_Client2_Item".. i .."_BuyLimit"
		T3BianJingGashapon_Special[i] = "T3BianJingGashapon_Client2_Item".. i .. "_Special"
		T3BianJingGashapon_LimitBK[i] = "T3BianJingGashapon_Client2_Item".. i .. "_BuyLimitNumBK"
	end
	for i = 1, 12 do
		g_T3BianJingGashapon_ShowItemInfo[i] = {
			ActionButton = _G[T3BianJingGashapon_ActionButton[i]],
			NameStr = _G[T3BianJingGashapon_ItemName[i]],
			ItemNum = _G[T3BianJingGashapon_Num[i]],
			CostText = _G[T3BianJingGashapon_Cost[i]],
			Mark = _G[T3BianJingGashapon_Mark[i]],
			Mark2 = _G[T3BianJingGashapon_Mark2[i]],
			Limit = _G[T3BianJingGashapon_Limit[i]],
			Special = _G[T3BianJingGashapon_Special[i]],
			LimitBK = _G[T3BianJingGashapon_LimitBK[i]],
		}
	end
	
	T3BianJingGashapon_OnLoad_new()
	
	g_T3BianJingGashapon_UnifiedPosition = T3BianJingGashapon_Frame:GetProperty("UnifiedPosition")
	
end

function T3BianJingGashapon_OnLoad_new()
	T3BianJingGashapon_Preview[1] = T3BianJingGashapon_Client2_Item1_Preview
	T3BianJingGashapon_Preview[2] = T3BianJingGashapon_Client2_Item2_Preview
	T3BianJingGashapon_Preview[3] = T3BianJingGashapon_Client2_Item3_Preview
	T3BianJingGashapon_Preview[4] = T3BianJingGashapon_Client2_Item4_Preview
	T3BianJingGashapon_Preview[5] = T3BianJingGashapon_Client2_Item5_Preview
	T3BianJingGashapon_Preview[6] = T3BianJingGashapon_Client2_Item6_Preview
	T3BianJingGashapon_Preview[7] = T3BianJingGashapon_Client2_Item7_Preview
	T3BianJingGashapon_Preview[8] = T3BianJingGashapon_Client2_Item8_Preview
	T3BianJingGashapon_Preview[9] = T3BianJingGashapon_Client2_Item9_Preview
	T3BianJingGashapon_Preview[10] = T3BianJingGashapon_Client2_Item10_Preview
	T3BianJingGashapon_Preview[11] = T3BianJingGashapon_Client2_Item11_Preview
	T3BianJingGashapon_Preview[12] = T3BianJingGashapon_Client2_Item12_Preview	
end

function T3BianJingGashapon_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88820501 ) then
		if IsWindowShow("T3BianJingGashapon_MBuy") then
			CloseWindow("T3BianJingGashapon_MBuy", true)
		end
		g_curState = 0
		g_lastRewardStar = 0
		local operator = Get_XParam_INT(0)
		g_operatortype = operator
		if operator == 1 then

			g_curDaibi1 = Get_XParam_INT(1)
			g_curDaibi2 = Get_XParam_INT(2)	
			g_curDoMakeCount = Get_XParam_INT(3)
			g_baohucount = Get_XParam_INT(4)
			g_isShowRedPoint = Get_XParam_INT(5)
			g_curpageIndex = 1
			g_client1Index = 1  --初始界面
			T3BianJingGashapon_ButtonPage(1)

			T3BianJingGashapon_Update()
		elseif operator == 2 then
			g_curDaibi1 = Get_XParam_INT(1)	
			g_curDaibi2 = Get_XParam_INT(2)	
			g_curStarData = Get_XParam_INT(3)
			g_curRewardStar = Get_XParam_INT(4)	
			g_lastRewardType = Get_XParam_INT(5)	
			g_isGet = Get_XParam_INT(6)	
			g_curDoMakeCount = Get_XParam_INT(7)
			g_baohucount = Get_XParam_INT(8)
			g_isShowRedPoint = Get_XParam_INT(9)
			g_curpageIndex = 1
			g_client1Index = 2  --追加界面
			T3BianJingGashapon_ButtonPage(1)

			T3BianJingGashapon_Update()		
		elseif operator == 3 or operator == 5 then
			if this:IsVisible() and g_curpageIndex == 1 and g_client1Index == 2 then
				g_FailFlag = Get_XParam_INT(1)
				g_curDaibi1 = Get_XParam_INT(2)	
				g_curDaibi2 = Get_XParam_INT(3)
				g_curStarData = Get_XParam_INT(4)
				g_curRewardStar = Get_XParam_INT(5)
				g_isGet = Get_XParam_INT(6)
				g_baohucount = Get_XParam_INT(7)
				g_isShowRedPoint = Get_XParam_INT(8)
				g_lastRewardStar = Get_XParam_INT(9)
				
				if Get_XParam_INT_Count() == 11 then
					g_Param = Get_XParam_INT(10)
				end
				g_animateState = 0
				T3BianJingGashapon_Start()
			end
		elseif operator == 4 then
			if this:IsVisible() and g_curpageIndex == 1 and g_client1Index == 1 then
				g_FailFlag = Get_XParam_INT(1)
				g_curDaibi1 = Get_XParam_INT(2)	
				g_curDaibi2 = Get_XParam_INT(3)	
				g_curStarData = Get_XParam_INT(4)
				g_curRewardStar = Get_XParam_INT(5)	
				g_lastRewardType = Get_XParam_INT(6)	
				g_isGet = Get_XParam_INT(7)	
				g_curDoMakeCount = Get_XParam_INT(8)
				g_baohucount = Get_XParam_INT(9)
				g_isShowRedPoint = Get_XParam_INT(10)
				g_animateState = 1
				T3BianJingGashapon_Start()
			end
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88820503 ) then --领奖界面
		if this:IsVisible() and g_curpageIndex == 1 and g_client1Index == 2 then
			local operator = Get_XParam_INT(0)
			if operator == 1 then
				g_FailFlag = Get_XParam_INT(1)
				g_curRewardStar = Get_XParam_INT(2)
				g_curRewardIndex = Get_XParam_INT(3)
				g_ItemLimitFlag = Get_XParam_INT(4)
				g_BuchangDaibi = Get_XParam_INT(5)
			end

			T3BianJingGashapon_Update_Reward(operator)	
		end	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88820601 ) then --商店界面
		if IsWindowShow("T3BianJingGashapon_MBuy") then
			CloseWindow("T3BianJingGashapon_MBuy", true)
		end
		g_curState = 0
		local operator = Get_XParam_INT(0)
		if operator == 1 then
			g_curShopType = Get_XParam_INT(1)	
			g_curDaibi1 = Get_XParam_INT(2)		
			g_curDaibi2 = Get_XParam_INT(3)
			g_isShowRedPoint = Get_XParam_INT(4)
			
			for i = 1, 10 do
				g_DuiHuan_MD_List[i] = Get_XParam_INT(i+4)
			end
			
			if g_curShopType == 1 then
				g_curpageIndex = 2
			elseif g_curShopType == 2 then
				g_curpageIndex = 3
			end
			g_CurShopPage = 1
			T3BianJingGashapon_ButtonPage(g_curpageIndex)
			
			T3BianJingGashapon_Update()
		elseif operator == 2 then
			if this:IsVisible() and ( g_curpageIndex == 2 or g_curpageIndex == 3 ) then
				g_curShopType = Get_XParam_INT(1)	
				g_curDaibi1 = Get_XParam_INT(2)		
				g_curDaibi2 = Get_XParam_INT(3)
				g_isShowRedPoint = Get_XParam_INT(4)
				
				for i = 1, 10 do
					g_DuiHuan_MD_List[i] = Get_XParam_INT(i+4)
				end
				
				T3BianJingGashapon_Update()
			end
		end

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		
		if (arg0~= nil and -1 == tonumber(arg0)) then
			return
		end 
		if g_curpageIndex == 1 then
			T3BianJingGashapon_Refresh_Item()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		T3BianJingGashapon_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		T3BianJingGashapon_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if IsWindowShow("T3BianJingGashapon_MBuy") then
			CloseWindow("T3BianJingGashapon_MBuy", true)
		end
		this:Hide()
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		T3BianJingGashapon_Client1_Balance2:SetText(ScriptGlobal_Format( "#{PTLS_200902_117}", Player:GetData("YUANBAO")))
		T3BianJingGashapon_Client2_Balance2:SetText(ScriptGlobal_Format( "#{PTLS_200902_117}", Player:GetData("YUANBAO")))
	end

end

--=========================================================
--更新界面
--=========================================================
function T3BianJingGashapon_Update()

	if g_curpageIndex == 1 then
		T3BianJingGashapon_Client1:Show()
		T3BianJingGashapon_Client2:Hide()
		T3BianJingGashapon_Update_Client1()
	elseif g_curpageIndex == 2 then
		T3BianJingGashapon_Client1:Hide()
		T3BianJingGashapon_Client2:Show()
		T3BianJingGashapon_Update_Client2()
	elseif g_curpageIndex == 3 then
		T3BianJingGashapon_Client1:Hide()
		T3BianJingGashapon_Client2:Show()
		T3BianJingGashapon_Update_Client2()
	end

	this:Show()
end
	
--更新抽奖界面
function T3BianJingGashapon_Update_Client1()
	T3BianJingGashapon_Client1_RewardCollection_Frame:Hide()
	
	if g_isShowRedPoint == 1 then
		T3BianJingGashapon_ButtonTab01_Tips:Show()
	else
		T3BianJingGashapon_ButtonTab01_Tips:Hide()
	end
		
	for i = 1, 5 do
		g_T3BianJingGashapon_ShowImage[i].ImageLight:Hide()
		--g_T3BianJingGashapon_ShowImage[i].RewardImageFrame:Hide()
		g_T3BianJingGashapon_ShowImage[i].RewardTitle:Hide()
		g_T3BianJingGashapon_ShowImage[i].ImageAnimPulse:Hide()
	end

	for i = 1, 7 do
		g_T3BianJingGashapon_ShowStar[i].StarApper:Hide()
		g_T3BianJingGashapon_ShowStar[i].StarBroken:Hide()
		g_T3BianJingGashapon_ShowStar[i].StarDefense:Hide()
	end

	for i = 1, 3 do	
		T3BianJingGashapon_ImageStarList1[i]:Hide()
		T3BianJingGashapon_ImageStarList2[i]:Hide()
		T3BianJingGashapon_ImageStarList3[i]:Hide()
		T3BianJingGashapon_ImageStarList4[i]:Hide()
		T3BianJingGashapon_ImageStarList5[i]:Hide()
	end
	
	T3BianJingGashapon_Client1_Frame3_Result:Hide()
	T3BianJingGashapon_Client1_Frame3_FailedTipsBK:Hide()
	--T3BianJingGashapon_Client1_Frame2:Hide()
	T3BianJingGashapon_Client1_Frame2_Playing:Hide()
	
	if g_client1Index == 1 then --初始界面
		for i = 0, 7 do
			T3BianJingGashapon_ImageStar[i]:Hide()
		end
	
		--T3BianJingGashapon_Client1_Operate_Frame3_Tips:Hide()
		T3BianJingGashapon_Client1_Frame3_GetBtn:Hide()
	
		T3BianJingGashapon_Client1_Operate_Frame1:Show()
		T3BianJingGashapon_Client1_Operate_Frame2:Hide()
		
		T3BianJingGashapon_Client1_Operate_Frame1_Text:SetText(ScriptGlobal_Format("#{PTLS_200902_17}", g_MeishiQuanCount))
		
		T3BianJingGashapon_Client1_Frame2_Image0Still2:Hide()
		--T3BianJingGashapon_Client1_Frame2:Show()
	else 
		local lasttype = math.mod(g_curStarData,10)
		local laststar = math.floor(math.mod(g_curStarData, 100)/10)
		local lastState = math.floor(math.mod(g_curStarData, 1000)/100)
		local lastImageStar = math.floor(math.mod(g_curStarData, 10000)/1000)
		local ImageStarList = nil
		if lasttype > 0 and lasttype <= 5 then
			g_T3BianJingGashapon_ShowImage[lasttype].ImageLight:Show()
			if lasttype == 1 then
				ImageStarList =  T3BianJingGashapon_ImageStarList1
			elseif lasttype == 2 then
				ImageStarList =  T3BianJingGashapon_ImageStarList2
			elseif lasttype == 3 then
				ImageStarList =  T3BianJingGashapon_ImageStarList3
			elseif lasttype == 4 then
				ImageStarList =  T3BianJingGashapon_ImageStarList4
			elseif lasttype == 5 then
				ImageStarList =  T3BianJingGashapon_ImageStarList5
			end
		end
		
		if laststar > 0 and laststar <= 3 then
			ImageStarList[laststar]:Show()
		end
		
		T3BianJingGashapon_Client1_Frame2_Image0Still2:Show()
		--if g_lastRewardType > 0 and g_lastRewardType <= 5 then
			--g_T3BianJingGashapon_ShowImage[g_lastRewardType].RewardImageFrame:Show()
			--g_T3BianJingGashapon_ShowImage[g_lastRewardType].RewardTitle:Show()
			--g_T3BianJingGashapon_ShowImage[g_lastRewardType].AnimAppear:Hide()
			--g_T3BianJingGashapon_ShowImage[g_lastRewardType].AnimFailed:Hide()
			--g_T3BianJingGashapon_ShowImage[g_lastRewardType].AnimSuccessed:Hide()
		--end

		--PushDebugMessage(g_curRewardStar)
		--奖励星级
		for i = 0, 7 do
			if i <= g_curRewardStar then
				T3BianJingGashapon_ImageStar[i]:Show()
			else
				T3BianJingGashapon_ImageStar[i]:Hide()
			end
		end
		
		--保护调制保底次数
		if g_baohucount == g_BaodiCount then
			T3BianJingGashapon_Client1_Operate_Frame2_Tips:SetText("#{PTLS_200902_133}")
		elseif g_baohucount < g_BaodiCount then
			T3BianJingGashapon_Client1_Operate_Frame2_Tips:SetText(ScriptGlobal_Format("#{PTLS_200902_132}", g_BaodiCount-g_baohucount))
		end
		
		if laststar > 0 and laststar <= 3 then
			--免费券数量
			T3BianJingGashapon_Client1_Operate_Frame2_Text1:SetText(ScriptGlobal_Format("#{PTLS_200902_115}", g_FreeQuanCount))
			--元宝数量
			T3BianJingGashapon_Client1_Operate_Frame2_Text2:SetText(ScriptGlobal_Format("#{PTLS_200902_21}", g_NeedYBCount[g_curRewardStar]))
		end
		
		T3BianJingGashapon_Client1_Frame3_GetBtn:Show()
		if (lastState == 2 and g_isGet == 0) then --可领奖红点
			T3BianJingGashapon_Client1_Frame3_GetBtn_Tips:Show()
		else
			T3BianJingGashapon_Client1_Frame3_GetBtn_Tips:Hide()
		end		
		
		T3BianJingGashapon_Client1_Operate_Frame1:Hide()
		T3BianJingGashapon_Client1_Operate_Frame2:Show()

		if lastState == 2 then
			T3BianJingGashapon_Client1_Operate_Frame2_Btn1:Disable()
			T3BianJingGashapon_Client1_Operate_Frame2_Btn2:Disable()
		else
			T3BianJingGashapon_Client1_Operate_Frame2_Btn1:Enable()
			T3BianJingGashapon_Client1_Operate_Frame2_Btn2:Enable()
		end
	end
	
	--元宝数
	T3BianJingGashapon_Client1_Balance2:SetText(ScriptGlobal_Format( "#{PTLS_200902_117}", Player:GetData("YUANBAO")))
	--美食币
	T3BianJingGashapon_Client1_Balance:SetText(ScriptGlobal_Format( "#{PTLS_200902_118}", g_curDaibi1))
	--七星币
	T3BianJingGashapon_Client1_Balance3:SetText(ScriptGlobal_Format( "#{PTLS_200902_119}", g_curDaibi2))
	
	
	--美食券
	T3BianJingGashapon_Refresh_Item() 
	--次数
	T3BianJingGashapon_Client1_Currency3Number:SetText(ScriptGlobal_Format( "#{PTLS_200902_113}", g_curDoMakeCount, 4000))
end

function T3BianJingGashapon_Start()
	if(IsWindowShow("Packet")) then
		CloseWindow("Packet", true)
	end
	g_curState = 1
	for i = 1, 5 do
		if i == 1 then
			g_T3BianJingGashapon_ShowImage[1].ImageLight:Show()
		else
			g_T3BianJingGashapon_ShowImage[i].ImageLight:Hide()
		end
	end
	T3BianJingGashapon_Client1_Frame2_Playing:Show()
	T3BianJingGashapon_Client1_Frame2_Playing:Play(true)
	
	SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick()", g_animate.minSpeed)
	g_Step = 1
	g_Round = 1
end

function T3BianJingGashapon_Tick()
	KillTimer("T3BianJingGashapon_Tick()")
	g_T3BianJingGashapon_ShowImage[g_Step].ImageLight:Hide()
	local lasttype = math.mod(g_curStarData,10)
	if lasttype < 1 or lasttype > 5 then
		return
	end

	if g_Step < 5 and g_Round < g_animate.round then
		g_Step = g_Step+1
	elseif g_Step >= 5 and g_Round < g_animate.round then
		g_Step = 1
		g_Round = g_Round+1
	elseif g_Round == g_animate.round and g_Step < lasttype then
		g_Step = g_Step+1
	elseif g_Round == g_animate.round and g_Step == lasttype then
		T3BianJingGashapon_End()
		
		return
	end
	g_T3BianJingGashapon_ShowImage[g_Step].ImageLight:Show()
		
	local nTime = g_animate.minSpeed + g_animate.decay * (g_Step + 5 * g_Round)
	SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick()", g_animate.minSpeed + g_animate.decay * (g_Step + 5 * g_Round))
	--PushDebugMessage(nTime)
end

function T3BianJingGashapon_Tick1()
	KillTimer("T3BianJingGashapon_Tick1()")
	local lasttype = math.mod(g_curStarData,10)
	if lasttype >= 1 and lasttype <= 5 then
		--g_T3BianJingGashapon_ShowImage[lasttype].Image:Show()
		--出场动画
		if g_animateState == 1 then
			--g_T3BianJingGashapon_ShowImage[lasttype].RewardStill:Hide()
			--g_T3BianJingGashapon_ShowImage[lasttype].AnimAppear:Show()
			--g_T3BianJingGashapon_ShowImage[lasttype].AnimAppear:Play(true)
			--SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick1_1()", g_AnimTime[lasttype].apper)
			T3BianJingGashapon_Tick1_1()
		else
			if g_FailFlag == 1 or g_FailFlag == 2 then --失败
			--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].RewardStill:Hide()
			--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].AnimFailed:Show()
			--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].AnimFailed:Play(true)
			--	SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick1_2()", g_AnimTime[g_lastRewardType].faild)
				T3BianJingGashapon_Tick1_2()
			else --成功
			--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].RewardStill:Hide()
			--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].AnimSuccessed:Show()
			--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].AnimSuccessed:Play(true)
			--	SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick1_3()", g_AnimTime[g_lastRewardType].success)		
				T3BianJingGashapon_Tick1_3()	
			end
		end
	end
	
	T3BianJingGashapon_Client1_Frame3_Result:Show()
	T3BianJingGashapon_Client1_Frame3_ResultSucceed:Hide()
	T3BianJingGashapon_Client1_Frame3_ResultFailed:Hide()
	T3BianJingGashapon_Client1_Frame3_ResultNumAdd:Hide()
	T3BianJingGashapon_Client1_Frame3_ResultNumLess:Hide()
	--星星特效
	if g_FailFlag == 1 then --失败
		for i = 1, 7 do
			if i <= g_lastRewardStar and i > g_curRewardStar then
				g_T3BianJingGashapon_ShowStar[i].StarBroken:Show()
				g_T3BianJingGashapon_ShowStar[i].StarBroken:Play(true)
			end
		end
		--结果特效
		T3BianJingGashapon_Client1_Frame3_ResultFailedAnim:Show()
		T3BianJingGashapon_Client1_Frame3_ResultFailedAnim:Play(true)
		SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_1()", 500)
		if (g_lastRewardStar-g_curRewardStar) == 1 then
			T3BianJingGashapon_Client1_Frame3_ResultNumLess_1Anim:Show()
			T3BianJingGashapon_Client1_Frame3_ResultNumLess_1Anim:Play(true)
			SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_3()", 300)
		elseif (g_lastRewardStar-g_curRewardStar) == 2 then
			T3BianJingGashapon_Client1_Frame3_ResultNumLess_2Anim:Show()
			T3BianJingGashapon_Client1_Frame3_ResultNumLess_2Anim:Play(true)
			SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_3()", 300)
		end
	elseif g_FailFlag == 2 then --保护
		for i = 1, 7 do
			if i <= g_curRewardStar then
				g_T3BianJingGashapon_ShowStar[i].StarDefense:Show()
				g_T3BianJingGashapon_ShowStar[i].StarDefense:Play(true)
			end
		end
		--结果特效
		T3BianJingGashapon_Client1_Frame3_ResultFailedAnim:Show()
		T3BianJingGashapon_Client1_Frame3_ResultFailedAnim:Play(true)
		SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_1()", 500)
		T3BianJingGashapon_Client1_Frame3_FailedTipsBK:Show()
		T3BianJingGashapon_Client1_Frame3_FailedTips:SetText(ScriptGlobal_Format( "#{PTLS_200902_177}",g_BuchangDaibiList[g_curRewardStar]))
		
	else --成功
		for i = 1, 7 do
			if i <= g_curRewardStar then
				g_T3BianJingGashapon_ShowStar[i].StarApper:Show()
				g_T3BianJingGashapon_ShowStar[i].StarApper:Play(true)
			end
		end		
		--结果特效		
		T3BianJingGashapon_Client1_Frame3_ResultSucceedAnim:Show()
		T3BianJingGashapon_Client1_Frame3_ResultSucceedAnim:Play(true)
		SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_2()", 400)
		if (g_curRewardStar-g_lastRewardStar) == 1 then
			T3BianJingGashapon_Client1_Frame3_ResultNumAdd_1Anim:Show()
			T3BianJingGashapon_Client1_Frame3_ResultNumAdd_1Anim:Play(true)
			SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_3()", 300)
		elseif (g_curRewardStar-g_lastRewardStar) == 2 then
			T3BianJingGashapon_Client1_Frame3_ResultNumAdd_2Anim:Show()
			T3BianJingGashapon_Client1_Frame3_ResultNumAdd_2Anim:Play(true)
			SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_3()", 300)
		elseif (g_curRewardStar-g_lastRewardStar) == 3 then
			T3BianJingGashapon_Client1_Frame3_ResultNumAdd_3Anim:Show()
			T3BianJingGashapon_Client1_Frame3_ResultNumAdd_3Anim:Play(true)
			SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick2_3()", 300)
		end
	end
	
	
end

function T3BianJingGashapon_Tick1_1()
	--KillTimer("T3BianJingGashapon_Tick1_1()")
	local lasttype = math.mod(g_curStarData,10)
	if lasttype >= 1 and lasttype <= 5 then
		if g_animateState == 1 then
		--	g_T3BianJingGashapon_ShowImage[lasttype].RewardStill:Show()
		end
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MakePlayEnd")
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_Parameter(0,g_operatortype)
		Set_XSCRIPT_Parameter(1,g_Param)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	g_curState = 2
end

function T3BianJingGashapon_Tick1_2()
	--KillTimer("T3BianJingGashapon_Tick1_2()")
	if g_lastRewardType >= 1 and g_lastRewardType <= 5 then
	--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].RewardStill:Show()
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MakePlayEnd")
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_Parameter(0,g_operatortype)
		Set_XSCRIPT_Parameter(1,g_Param)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	g_curState = 2
end

function T3BianJingGashapon_Tick1_3()
	--KillTimer("T3BianJingGashapon_Tick1_3()")
	if g_lastRewardType >= 1 and g_lastRewardType <= 5 then
	--	g_T3BianJingGashapon_ShowImage[g_lastRewardType].RewardStill:Show()
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MakePlayEnd")
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_Parameter(0,g_operatortype)
		Set_XSCRIPT_Parameter(1,g_Param)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	g_curState = 2
end

function T3BianJingGashapon_Tick2_1()
	KillTimer("T3BianJingGashapon_Tick2_1()")
	T3BianJingGashapon_Client1_Frame3_ResultFailed:Show()
end

function T3BianJingGashapon_Tick2_2()
	KillTimer("T3BianJingGashapon_Tick2_2()")
	T3BianJingGashapon_Client1_Frame3_ResultSucceed:Show()
end

function T3BianJingGashapon_Tick2_3()
	KillTimer("T3BianJingGashapon_Tick2_3()")
	
	if (g_curRewardStar-g_lastRewardStar) == -1 then
		T3BianJingGashapon_Client1_Frame3_ResultNumLess:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumLess_1:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumLess_2:Hide()
		T3BianJingGashapon_Client1_Frame3_ResultNumLess_3:Hide()
	elseif (g_curRewardStar-g_lastRewardStar) == -2 then
		T3BianJingGashapon_Client1_Frame3_ResultNumLess:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumLess_2:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumLess_1:Hide()
		T3BianJingGashapon_Client1_Frame3_ResultNumLess_3:Hide()
	elseif (g_curRewardStar-g_lastRewardStar) == 1 then
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_1:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_2:Hide()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_3:Hide()
	elseif (g_curRewardStar-g_lastRewardStar) == 2 then
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_2:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_1:Hide()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_3:Hide()
	elseif (g_curRewardStar-g_lastRewardStar) == 3 then
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_3:Show()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_1:Hide()
		T3BianJingGashapon_Client1_Frame3_ResultNumAdd_2:Hide()
	end
end

function T3BianJingGashapon_End()
	g_client1Index = 2
	
	T3BianJingGashapon_Update_Client1()
	local lasttype = math.mod(g_curStarData,10)
	if lasttype >= 1 and lasttype <= 5 then
		--g_T3BianJingGashapon_ShowImage[lasttype].Image:Hide()
		g_T3BianJingGashapon_ShowImage[lasttype].ImageAnimPulse:Show()
		--g_T3BianJingGashapon_ShowImage[lasttype].ImageAnimPulse:Play(true)
		SetTimer("T3BianJingGashapon","T3BianJingGashapon_Tick1()", 500)
		T3BianJingGashapon_Client1_Frame2_Image0Still2:Show()
		T3BianJingGashapon_Client1_Frame2_Image0Still2:SetProperty("Image", T3BianJingGashapon_ImageStill[lasttype])
	end

end
--更新兑换界面
function T3BianJingGashapon_Update_Client2()
	for i = 1, 12 do
	--PushDebugMessage(i)
		if g_T3BianJingGashapon_ShowItemInfo[i].ActionButton ~= nil then
			g_T3BianJingGashapon_ShowItemInfo[i].ActionButton:SetActionItem(-1)
			g_T3BianJingGashapon_ShowItemInfo[i].ActionButton:Disable()

			g_T3BianJingGashapon_ShowItemInfo[i].NameStr:SetText("")
			g_T3BianJingGashapon_ShowItemInfo[i].ItemNum:SetText("")
			g_T3BianJingGashapon_ShowItemInfo[i].CostText:SetText("")
			g_T3BianJingGashapon_ShowItemInfo[i].Mark:Hide()
			g_T3BianJingGashapon_ShowItemInfo[i].Mark2:Hide()
			g_T3BianJingGashapon_ShowItemInfo[i].Limit:Hide()
			g_T3BianJingGashapon_ShowItemInfo[i].Special:Hide()
			T3BianJingGashapon_Preview[i]:Hide()
		end
	end

	if g_isShowRedPoint == 1 then
		T3BianJingGashapon_ButtonTab01_Tips:Show()
	else
		T3BianJingGashapon_ButtonTab01_Tips:Hide()
	end
	
	if g_curShopType == 1 then
		T3BianJingGashapon_Client2_InfoText:SetText("#{PTLS_200902_33}")
	else
		T3BianJingGashapon_Client2_InfoText:SetText("#{PTLS_200902_168}")
	end
	
	local nCount = GetNiudanShopDuihuanCount( g_curShopType )
	local maxpagenum = math.floor(nCount/g_CurPageItemMax)+1

	for i = 1, 12 do
		local nID, nNeedDaibi, nShowItemId, nItemNum, nLimit, nIsView = GetNiudanShopDuihuanItem( g_curShopType, i+(g_CurShopPage-1)*12 )

		if nID < 0 then
			break
		end
		
		local theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
		g_T3BianJingGashapon_ShowItemInfo[i].ActionButton:SetActionItem(theAction:GetID())
		g_T3BianJingGashapon_ShowItemInfo[i].ActionButton:Enable()
		g_T3BianJingGashapon_ShowItemInfo[i].NameStr:SetText("#L"..theAction:GetName())

		if g_curShopType == 1 then
			g_T3BianJingGashapon_ShowItemInfo[i].CostText:SetText(ScriptGlobal_Format( "#{PTLS_200902_35}",nNeedDaibi))
		else
			g_T3BianJingGashapon_ShowItemInfo[i].CostText:SetText(ScriptGlobal_Format( "#{PTLS_200902_142}",nNeedDaibi))
		end
		
		if nLimit == 0 then
			g_T3BianJingGashapon_ShowItemInfo[i].LimitBK:Hide()
		else
			local curbuycnt = T3BianJingGashapon_GetLimitCount(i+(g_CurShopPage-1)*12)
			g_T3BianJingGashapon_ShowItemInfo[i].ItemNum:SetText(nLimit-curbuycnt)
			g_T3BianJingGashapon_ShowItemInfo[i].Limit:Show()
			g_T3BianJingGashapon_ShowItemInfo[i].LimitBK:Show()
			if curbuycnt >= nLimit then
				g_T3BianJingGashapon_ShowItemInfo[i].Mark:Show() --售罄
				g_T3BianJingGashapon_ShowItemInfo[i].Mark2:Show()
				g_T3BianJingGashapon_ShowItemInfo[i].LimitBK:Hide()
			end
		end
		
		if nShowItemId == 39923752 then --七星币
			g_T3BianJingGashapon_ShowItemInfo[i].Special:Show()
		end
		
		if nIsView == 1 then --预览
			T3BianJingGashapon_Preview[i]:Show()
		else
			T3BianJingGashapon_Preview[i]:Hide()
		end
	end
	
	T3BianJingGashapon_Client2_CurrentlyPage:SetText(ScriptGlobal_Format( "#{PTLS_200902_37}", g_CurShopPage, maxpagenum ) )
	if maxpagenum == 1 then
		T3BianJingGashapon_Client2_UpPage:Disable()
		T3BianJingGashapon_Client2_DownPage:Disable()
	else
		if g_CurShopPage <= 1 then
			T3BianJingGashapon_Client2_UpPage:Disable()
			T3BianJingGashapon_Client2_DownPage:Enable()
		elseif g_CurShopPage >= maxpagenum then
			T3BianJingGashapon_Client2_UpPage:Enable()
			T3BianJingGashapon_Client2_DownPage:Disable()
		else
			T3BianJingGashapon_Client2_UpPage:Enable()
			T3BianJingGashapon_Client2_DownPage:Enable()
		end
	end
	--元宝数
	T3BianJingGashapon_Client2_Balance2:SetText(ScriptGlobal_Format( "#{PTLS_200902_117}", Player:GetData("YUANBAO")))
	--美食币
	T3BianJingGashapon_Client2_Balance:SetText(ScriptGlobal_Format( "#{PTLS_200902_118}", g_curDaibi1))
	--七星币
	T3BianJingGashapon_Client2_Balance3:SetText(ScriptGlobal_Format( "#{PTLS_200902_119}", g_curDaibi2))
end

-- 获取已兑换数
function T3BianJingGashapon_GetLimitCount(nIndex)
	local ret = -1

	local MDData = nil
	for i = 1, 10 do
		if nIndex > 4*(i-1) and nIndex <= 4*i then
			MDData = g_DuiHuan_MD_List[i]
			break
		end
	end

	if MDData ~= nil then
		local temp = math.mod(nIndex-1, 4) --0,1,2,3

		if temp == 0 then
			ret = math.mod(MDData, 100)
		elseif temp == 1 then
			ret = math.mod(math.floor(MDData/100), 100)
		elseif temp == 2 then
			ret = math.mod(math.floor(MDData/10000), 100)
		elseif temp == 3 then
			ret = math.mod(math.floor(MDData/1000000), 100)
		end
	end

	return ret
end
function T3BianJingGashapon_PageUp()
	g_CurShopPage = g_CurShopPage - 1

	T3BianJingGashapon_Update_Client2()
end

function T3BianJingGashapon_PageDown()
	g_CurShopPage = g_CurShopPage + 1

	T3BianJingGashapon_Update_Client2()
end

--奖励领取界面
function T3BianJingGashapon_Update_Reward(nIsShow)
	if nIsShow == 1 then
		T3BianJingGashapon_Client1_RewardCollection_Frame:Show()
	else
		T3BianJingGashapon_Client1_RewardCollection_Frame:Hide()
		return
	end
	
	--标题
	if g_FailFlag == 1 then
		T3BianJingGashapon_Client1_RewardCollection_Title1:Hide()
		T3BianJingGashapon_Client1_RewardCollection_Title2:Show()
		if g_curRewardStar == 0 then
			T3BianJingGashapon_Client1_RewardCollection_Title2T:SetText("#{PTLS_200902_56}")
		else
			T3BianJingGashapon_Client1_RewardCollection_Title2T:SetText(ScriptGlobal_Format("#{PTLS_200902_51}",g_StarText[g_curRewardStar]))
		end

	else
		T3BianJingGashapon_Client1_RewardCollection_Title1:Show()
		T3BianJingGashapon_Client1_RewardCollection_Title2:Hide()
		if g_curRewardStar == 0 then
			T3BianJingGashapon_Client1_RewardCollection_Title1T:SetText("#{PTLS_200902_56}")
		else
			T3BianJingGashapon_Client1_RewardCollection_Title1T:SetText(ScriptGlobal_Format("#{PTLS_200902_51}",g_StarText[g_curRewardStar]))
		end
	end
	
	--图标
	local ItemIconFlag = 0
	if g_curRewardStar >= 0 and g_curRewardStar < 3 then
		ItemIconFlag = 1
	else
		if g_ItemLimitFlag == 1 then --奖池空
			ItemIconFlag = 1
		else
			ItemIconFlag = 2
		end
	end
	
	g_SelectRewardIndex = 0
	if ItemIconFlag == 1 then --只显示1个
		g_SelectRewardIndex = 2
		T3BianJingGashapon_Client1_RewardCollection_ItemFrame1:Hide()
		T3BianJingGashapon_Client1_RewardCollection_ItemFrame2:Show()
		T3BianJingGashapon_Client1_RewardCollection_Item3_Mask:Hide()
		T3BianJingGashapon_Client1_RewardCollection_Item3_BuyLimit:Hide()
		local theAction = nil
		
		if g_ItemLimitFlag == 1 then --奖池空
			theAction = DataPool:CreateActionItemForShow( g_Daibi1ShowID, 1 )
			T3BianJingGashapon_Client1_RewardCollection_Item3_Num:SetText(g_RewardBuchongDaibi[g_curRewardStar])
			T3BianJingGashapon_Client1_RewardCollection_Item3_DoubleTips:Show()
		else
			theAction = DataPool:CreateActionItemForShow( g_Daibi1ShowID, 1 )
			T3BianJingGashapon_Client1_RewardCollection_Item3_Num:SetText(g_RewardDaibi[g_curRewardStar])
			T3BianJingGashapon_Client1_RewardCollection_Item3_DoubleTips:Hide()
		end		

		T3BianJingGashapon_Client1_RewardCollection_Item3:SetActionItem(theAction:GetID())	
		T3BianJingGashapon_Client1_RewardCollection_Item3_Name:SetText("#{PTLS_200902_164}")
	else --二选一
		T3BianJingGashapon_Client1_RewardCollection_ItemFrame1:Show()
		T3BianJingGashapon_Client1_RewardCollection_ItemFrame2:Hide()
		
		T3BianJingGashapon_Client1_RewardCollection_Item1_Mask:Hide()
		T3BianJingGashapon_Client1_RewardCollection_Item2_Mask:Hide()
		T3BianJingGashapon_Client1_RewardCollection_Item2_BuyLimit:Hide()
		
		local nItemId, nNum, nLimit, nLimitIndex = GetNiudanRewardItem(g_curRewardStar, g_curRewardIndex-1)
		if nItemId ~= nil and nItemId > 0 then
			--物品
			if nLimit > 0 then
				T3BianJingGashapon_Client1_RewardCollection_Item1_BuyLimit:Show()
			else
				T3BianJingGashapon_Client1_RewardCollection_Item1_BuyLimit:Hide()
			end
			local theAction1 = DataPool:CreateActionItemForShow( nItemId, nNum )
			T3BianJingGashapon_Client1_RewardCollection_Item1:SetActionItem(theAction1:GetID())	
			T3BianJingGashapon_Client1_RewardCollection_Item1_Name:SetText("#L"..theAction1:GetName())	
			--代币
			local theAction2 = DataPool:CreateActionItemForShow( g_Daibi1ShowID,  1)
			T3BianJingGashapon_Client1_RewardCollection_Item2:SetActionItem(theAction2:GetID())	
			T3BianJingGashapon_Client1_RewardCollection_Item2_Name:SetText("#{PTLS_200902_164}")
			T3BianJingGashapon_Client1_RewardCollection_Item2_Num:SetText(g_RewardDaibi[g_curRewardStar])
		end
	end
	
	--按钮
	T3BianJingGashapon_Client1_RewardCollection_Get1:Hide()
	T3BianJingGashapon_Client1_RewardCollection_Get2:Hide()

	T3BianJingGashapon_Client1_RewardCollection_TitleEnd:Hide()
	if g_FailFlag == 1 then
		--if g_curRewardStar >= 0 and g_curRewardStar < 3 then
		--	T3BianJingGashapon_Client1_RewardCollection_Get4:Show()
		--else
		--	if g_ItemLimitFlag == 1 then --奖池空
		--		T3BianJingGashapon_Client1_RewardCollection_Get4:Show()
		--	else
		--		T3BianJingGashapon_Client1_RewardCollection_Get3:Show()
		--	end
		--end
		T3BianJingGashapon_Client1_RewardCollection_TitleEnd:Show()
		T3BianJingGashapon_Client1_RewardCollection_Get2:Show()
	else
		--if g_curRewardStar >= 0 and g_curRewardStar < 3 then
		--	T3BianJingGashapon_Client1_RewardCollection_Get1:Show()
		if g_curRewardStar == 7 then --7星
			--if g_ItemLimitFlag == 1 then --奖池空
			--	T3BianJingGashapon_Client1_RewardCollection_Get4:Show()
			--else
			--	T3BianJingGashapon_Client1_RewardCollection_Get3:Show()
			--end
			T3BianJingGashapon_Client1_RewardCollection_TitleEnd:Show()
			T3BianJingGashapon_Client1_RewardCollection_Get2:Show()
		else
			--if g_ItemLimitFlag == 1 then --奖池空
			--	T3BianJingGashapon_Client1_RewardCollection_Get1:Show()
			--else
			--	T3BianJingGashapon_Client1_RewardCollection_Get2:Show()
			--end		
			T3BianJingGashapon_Client1_RewardCollection_Get1:Show()
		end		
	end
	
	--保底补偿奖励
	if g_BuchangDaibi > 0 then
		T3BianJingGashapon_Client1_RewardCollection_Info1:Show()
		T3BianJingGashapon_Client1_RewardCollection_Info1:SetText(ScriptGlobal_Format("#{PTLS_200902_59}",g_BuchangDaibi))
	else
		T3BianJingGashapon_Client1_RewardCollection_Info1:Hide()
	end
	
	--奖池空
	if g_ItemLimitFlag == 1 then
		local nItemId, nNum, nLimit, nLimitIndex = GetNiudanRewardItem(g_curRewardStar, g_curRewardIndex-1)
		if nItemId ~= nil and nItemId > 0 then
			local namestr = DataPool:Lua_GetItemNameByIndex(nItemId)
			T3BianJingGashapon_Client1_RewardCollection_Info2:SetText(ScriptGlobal_Format("#{PTLS_200902_121}",namestr,g_RewardBuchongDaibi[g_curRewardStar]))
		end
		T3BianJingGashapon_Client1_RewardCollection_Info2:Show()
	else
		T3BianJingGashapon_Client1_RewardCollection_Info2:Hide()
	end
end
--=========================================================
--关闭
--=========================================================
function T3BianJingGashapon_Close()
	if IsWindowShow("T3BianJingGashapon_MBuy") then
		CloseWindow("T3BianJingGashapon_MBuy", true)
	end
	g_curState = 0
	g_lastRewardStar = 0
	KillTimer("T3BianJingGashapon_Tick()")
	this:Hide()
end

function T3BianJingGashapon_OnHiden()
	T3BianJingGashapon_Close()
end
--=========================================================
--刷新位置
--=========================================================
function T3BianJingGashapon_On_ResetPos()
	T3BianJingGashapon_Frame:SetProperty("UnifiedPosition", g_T3BianJingGashapon_UnifiedPosition);
end


function T3BianJingGashapon_Client1_InfoHelp_Click()
	PushEvent("CCSHOP_HELP", 121)
end

function T3BianJingGashapon_Client2_InfoHelp_Click()
	PushEvent("CCSHOP_HELP", 122)
end


function T3BianJingGashapon_Start_Clicked()
	if g_curState == 1 then
		PushDebugMessage("#{PTLS_200902_61}")
		return 
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoStartMake" )
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function T3BianJingGashapon_Free_Clicked()
	if g_curState == 1 then
		PushDebugMessage("#{PTLS_200902_61}")
		return 
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoMakeForFree" )
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_Parameter(0,0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function T3BianJingGashapon_ProTect_Clicked()
	if g_curState == 1 then
		PushDebugMessage("#{PTLS_200902_61}")
		return 
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoMakeProtect" )
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_Parameter(0,0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function T3BianJingGashapon_OpenReward_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenRewardUI" )
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function T3BianJingGashapon_Reward_Select(Index)
	if Index == 1 then
		g_SelectRewardIndex = 1
		T3BianJingGashapon_Client1_RewardCollection_Item1_Mask:Show()
		T3BianJingGashapon_Client1_RewardCollection_Item2_Mask:Hide()
	elseif Index == 2 then
		g_SelectRewardIndex = 2 
		T3BianJingGashapon_Client1_RewardCollection_Item1_Mask:Hide()
		T3BianJingGashapon_Client1_RewardCollection_Item2_Mask:Show()
	end
end

function T3BianJingGashapon_GetReward_Clicked()
	if g_SelectRewardIndex ~= 1 and g_SelectRewardIndex ~= 2 then	
		PushDebugMessage("#{PTLS_200902_85}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_Parameter(0,g_SelectRewardIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

function T3BianJingGashapon_Client1_ViewReward_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenDetailUI" )
		Set_XSCRIPT_ScriptID(888205)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function T3BianJingGashapon_GetReward_Closed()
	T3BianJingGashapon_Client1_RewardCollection_Frame:Hide()
end

--选中页签
function T3BianJingGashapon_ButtonPage(index)
	for i = 1, 3 do
		if index == i then
			T3BianJingGashapon_pagebuttonleft[i]:SetProperty("Selected", "True")
		else
			T3BianJingGashapon_pagebuttonleft[i]:SetProperty("Selected", "False")
		end
	end
end

function T3BianJingGashapon_Page_Clicked(index)
	if index == 1 then
		local curDay = DataPool:GetServerDayTime()
		if curDay < g_BeginTime or curDay > g_EndTime then
			T3BianJingGashapon_ButtonPage(g_curpageIndex)
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenChoujiangUI" )
			Set_XSCRIPT_ScriptID( 888205 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888206 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888206 )
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

--点兑换
function T3BianJingGashapon_Client2_ItemClicked(nIndex)
	local ItemIndex = nIndex
	if ItemIndex < 1 or ItemIndex > g_CurPageItemMax then
		return
	end
	
	local nID, nNeedDaibi, nShowItemId, nItemNum, nLimit = GetNiudanShopDuihuanItem( g_curShopType, nIndex+(g_CurShopPage-1)*12 )

	if nID < 0 then
		return
	end
	
	local curbuycnt = T3BianJingGashapon_GetLimitCount(nIndex+(g_CurShopPage-1)*12)
	if nLimit > 0 and curbuycnt >= nLimit then  --售罄
		return
	end
	
	if IsWindowShow("T3BianJingGashapon_MBuy") then
		CloseWindow("T3BianJingGashapon_MBuy", true)
	end
		
	if g_curShopType == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenMBuyUI" )
			Set_XSCRIPT_ScriptID( 888206 )
			Set_XSCRIPT_Parameter(0,g_curShopType)
			Set_XSCRIPT_Parameter(1,g_CurShopPage)
			Set_XSCRIPT_Parameter(2,nIndex)
			Set_XSCRIPT_Parameter(3,curbuycnt)
			Set_XSCRIPT_Parameter(4,g_curDaibi1)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif g_curShopType == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenMBuyUI" )
			Set_XSCRIPT_ScriptID( 888206 )
			Set_XSCRIPT_Parameter(0,g_curShopType)
			Set_XSCRIPT_Parameter(1,g_CurShopPage)
			Set_XSCRIPT_Parameter(2,nIndex)
			Set_XSCRIPT_Parameter(3,curbuycnt)
			Set_XSCRIPT_Parameter(4,g_curDaibi2)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	end

	this:Show()	
end
--预览
function T3BianJingGashapon_Client2_ItemPreviewClicked(nIndex)
	local ItemIndex = nIndex
	if ItemIndex < 1 or ItemIndex > g_CurPageItemMax then
		return
	end
	
	local nID, nNeedDaibi, nShowItemId, nItemNum, nLimit, nIsView = GetNiudanShopDuihuanItem( g_curShopType, nIndex+(g_CurShopPage-1)*12 )

	if nID < 0 then
		return
	end
	
	PushEvent( "UI_COMMAND", 88820603, nShowItemId )
end

function T3BianJingGashapon_Refresh_Item() 
	local count1 = PlayerPackage:CountAvailableItemByIDTable(g_MeishiQuanID) 
	local count2 = PlayerPackage:CountAvailableItemByIDTable(g_FreeQuanID) 

	T3BianJingGashapon_Client1_Currency1Number:SetText("#L"..count1)
	T3BianJingGashapon_Client1_Currency2Number:SetText("#L"..count2)
	--if HaveIDcount < g_DuanWu_DuiHuan_NeedItem_Count then	
	--	DuanWu_DuiHuan_NeedNum:SetText(ScriptGlobal_Format("#{DWDH_190502_16}",DataPool:Lua_GetItemNameByIndex(g_DuanWu_DuiHuan_NeedItemID), HaveIDcount, g_DuanWu_DuiHuan_NeedItem_Count))
	--else
	--	DuanWu_DuiHuan_NeedNum:SetText(ScriptGlobal_Format("#{DWDH_190502_15}",DataPool:Lua_GetItemNameByIndex(g_DuanWu_DuiHuan_NeedItemID), HaveIDcount, g_DuanWu_DuiHuan_NeedItem_Count))
	--end
end

function T3BianJingGashapon_Client1_GO_Button_Clicked()
	local bRet = AutoRuntoTargetExWithName(272, 255, 0, "乔致广")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end

end