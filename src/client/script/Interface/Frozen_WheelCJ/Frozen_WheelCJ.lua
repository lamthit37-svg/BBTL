--Frozen_WheelCJ
local g_Frozen_WheelCJ_UnifiedPosition;


local Frozen_WheelCJAward_Icon = {}
local Frozen_WheelCJAward_Light = {}
local Frozen_WheelCJ_RewardBtn = {}
local Frozen_WheelCJ_Tips = {}
local Frozen_WheelCJ_RewardBtnOK = {}
local Frozen_WheelCJ_RewardNumText = {}

--local Frozen_WheelCJ_Client2_Item_SellOut = {}
--local Frozen_WheelCJ_Client2_Item = {}
--local Frozen_WheelCJ_Client2_Item_Mask = {}
--local Frozen_WheelCJ_Client2_Item_BuyLimitNumBK = {}
--local Frozen_WheelCJ_Client2_Item_BuyLimitNum = {}
--local Frozen_WheelCJ_Client2_Item_BuyLimit = {}
--local Frozen_WheelCJ_Client2_Item_Name = {}
--local Frozen_WheelCJ_Client2_Item_Currency = {}
--local Frozen_WheelCJ_Client2_Item_SellOut = {}

--变量
local g_curpage = 0

local g_FrozenCJDaibi = 0
local g_FrozenCJCount = 0
local g_FrozenCJLevel = 0
local g_FrozenRewardFlag = {0}
local g_Frozen_animate_Step = 0
local g_Frozen_animate_Round = 0
local g_Frozen_animate_rewardidx = 0
local g_Frozen_refresh = 0
local g_FrozenNextCJLevel = 0
local g_FrozenDHDaibi = 0
local g_FrozenBuyDaibi = 0
local g_FrozenWeekDaibi = 0

local g_curShopPage = 1
local g_Frozen_ShopLimit = {0}
local g_ItemCanBuy = {0}

local g_FrozenItem_Max = 8

local g_Frozen_animate = {round = 3, minSpeed = 20, decay = 10}
local g_Frozen_animateState = 0

local g_FrozenReward_Need = {10, 20, 30, 40, 60, 90, 120}

local g_Frozen_BuyBeginTime = 20241219
local g_Frozen_EndTime = 20250108

function Frozen_WheelCJ_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function Frozen_WheelCJ_OnLoad()
	
	for i = 1, 8 do
		Frozen_WheelCJAward_Icon[i] = _G["Frozen_WheelCJAward_Icon"..i]
		Frozen_WheelCJAward_Light[i] = _G["Frozen_WheelCJAward"..i.."_Light"]		
	end
	
	for i = 1, 7 do
		Frozen_WheelCJ_RewardBtn[i] = _G["Frozen_WheelCJ_Reward"..i.."Btn"]
		Frozen_WheelCJ_Tips[i] = _G["Frozen_WheelCJ_Reward"..i.."_tips"]
		Frozen_WheelCJ_RewardBtnOK[i] = _G["Frozen_WheelCJ_Reward"..i.."BtnOK"]
		Frozen_WheelCJ_RewardNumText[i] = _G["Frozen_WheelCJ_Reward"..i.."Text"]
	end
	
	--for i = 1, 12 do
	--	Frozen_WheelCJ_Client2_ItemFrame[i] = _G["Frozen_WheelCJ_Client2_Item"..i.."Frame"]
	--	Frozen_WheelCJ_Client2_Item[i] = _G["Frozen_WheelCJ_Client2_Item"..i]
	--	Frozen_WheelCJ_Client2_Item_Mask[i] = _G["Frozen_WheelCJ_Client2_Item"..i.."_Mask"]
	--	Frozen_WheelCJ_Client2_Item_BuyLimitNumBK[i] = _G["Frozen_WheelCJ_Client2_Item"..i.."_BuyLimitNumBK"]
	--	Frozen_WheelCJ_Client2_Item_BuyLimitNum[i] = _G["Frozen_WheelCJ_Client2_Item"..i.."_BuyLimitNum"]
	--	Frozen_WheelCJ_Client2_Item_BuyLimit[i] = _G["Frozen_WheelCJ_Client2_Item"..i.."_BuyLimit"]
	--	Frozen_WheelCJ_Client2_Item_Name[i] = _G["Frozen_WheelCJ_Client2_ItemInfo"..i.."_Text"]
	--	Frozen_WheelCJ_Client2_Item_Currency[i] = _G["Frozen_WheelCJ_Client2_ItemInfo"..i.."_Currency"]
	--	Frozen_WheelCJ_Client2_Item_SellOut[i] = _G["Frozen_WheelCJ_Client2_Item"..i.."_SellOut"]
	--end
		
	g_Frozen_WheelCJ_UnifiedPosition = Frozen_WheelCJ_FrameNULL:GetProperty("UnifiedPosition")
	
end


function Frozen_WheelCJ_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99950101 ) then
		local operator = Get_XParam_INT(0)
		g_FrozenCJDaibi = Get_XParam_INT(1)
		g_FrozenCJCount = Get_XParam_INT(2)
		g_FrozenCJLevel = Get_XParam_INT(3)
		g_FrozenBuyDaibi = Get_XParam_INT(4)
		g_FrozenWeekDaibi = Get_XParam_INT(5)
		for i = 1, 7 do
			g_FrozenRewardFlag[i] = Get_XParam_INT(i+5)
		end
		
		if operator == 1 then
			g_curpage = 1			
			Frozen_WheelCJ_Update()
		elseif operator == 2 and this:IsVisible() then
			if g_curpage == 1 then
				Frozen_WheelCJ_Update_Client1()	
			end	
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99950102 and this:IsVisible() ) then
		if g_curpage == 1 then
			local rewardIdx = Get_XParam_INT(0)
			g_FrozenCJDaibi = Get_XParam_INT(1)
			g_FrozenCJCount = Get_XParam_INT(2)
			g_FrozenNextCJLevel = Get_XParam_INT(3)

			if rewardIdx > 0 then
				Frozen_WheelCJ_Client1_Animate_Start(rewardIdx)	
			end
		end
	--elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99950103 ) then
	--	local paramcount = Get_XParam_INT_Count()		
	--	local operator = Get_XParam_INT(0)
	--	g_FrozenDHDaibi =  Get_XParam_INT(1) 
		
	--	for i = 2, paramcount do
	--		g_Frozen_ShopLimit[i-1] = Get_XParam_INT(i) 
	--	end
		
	--	if operator == 1 then
	--		g_curpage = 2
	--		g_curShopPage = 1
	--		Frozen_WheelCJ_Update()
		--elseif operator == 2 and this:IsVisible() then
		--	if g_curpage == 2 then
		--		Frozen_WheelCJ_Update_Client2()	
		--	end	
	--	end	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99944109 ) then
	
	elseif (event == "ADJEST_UI_POS" ) then
		Frozen_WheelCJ_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_WheelCJ_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "UPDATE_YUANBAO") then
		--Frozen_WheelCJ_Client2_Balance2:SetText("#L拥有元宝"..Player:GetData("YUANBAO"))
	end

end

--=========================================================
--更新界面
--=========================================================
function Frozen_WheelCJ_Update()
	if g_curpage == 1 then
		--Frozen_WheelCJ_Client1:Show()
		--Frozen_WheelCJ_Client2:Hide()
		--Frozen_WheelCJ_Item1:SetCheck(1)
		--Frozen_WheelCJ_Item2:SetCheck(0)
		Frozen_WheelCJ_Update_Client1()
	--elseif g_curpage == 2 then
	--	Frozen_WheelCJ_Client1:Hide()
	--	Frozen_WheelCJ_Client2:Show()
	--	Frozen_WheelCJ_Item1:SetCheck(0)
	--	Frozen_WheelCJ_Item2:SetCheck(1)
	--	Frozen_WheelCJ_Update_Client2()
	end

	this:Show()
end

function Frozen_WheelCJ_CleanUp()

end

function Frozen_WheelCJ_Update_Client1()

	for i = 1, 8 do
		Frozen_WheelCJAward_Light[i]:Play(false)
		
		local nShowItemId,nItemNum,nIsBind = DataPool:LuaFnGetSnowShopCJItemInfo(g_FrozenCJLevel, i)
		if nShowItemId ~= nil and nShowItemId > 0 then
			local theAction = nil
			if nIsBind == 1 then
				theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
			else
				theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
			end
			if theAction ~= nil then
				Frozen_WheelCJAward_Icon[i]:SetActionItem(theAction:GetID())
			end			
		end
	end	
	
	Frozen_WheelCJ_Update_Client1_Text()
end

function Frozen_WheelCJ_Update_Client1_Text()
	Frozen_WheelCJ_Reward_ResultText1:SetText(ScriptGlobal_Format("#{BXZP_240911_30}", g_FrozenCJDaibi))
	Frozen_WheelCJ_RewardText2:SetText(ScriptGlobal_Format("#{BXZP_240911_34}", g_FrozenCJCount))
	Frozen_WheelCJ_Reward_ResultText2:SetText(ScriptGlobal_Format("#{BXZP_240911_111}", g_FrozenWeekDaibi))
	
	for i = 1, 7 do
		if g_FrozenRewardFlag[i] > 0 then
			Frozen_WheelCJ_RewardBtnOK[i]:Show()
			Frozen_WheelCJ_RewardBtn[i]:Disable()
			Frozen_WheelCJ_Tips[i]:Hide()
		else
			if g_FrozenCJCount >= g_FrozenReward_Need[i] then --可领取
				Frozen_WheelCJ_RewardBtnOK[i]:Hide()
				Frozen_WheelCJ_RewardBtn[i]:Enable()
				Frozen_WheelCJ_Tips[i]:Show()				
			else
				Frozen_WheelCJ_RewardBtnOK[i]:Hide()
				Frozen_WheelCJ_RewardBtn[i]:Enable()
				Frozen_WheelCJ_Tips[i]:Hide()			
			end
		end
	end	
end
--=========================================================
--开始
--=========================================================
function Frozen_WheelCJ_Client1_Animate_Start(rewardidx)
	g_Frozen_animate_Step = 1
	g_Frozen_animate_rewardidx = rewardidx
	g_Frozen_animate_Round = 1
	for i = 1, 8 do
		if i == rewardidx then
			Frozen_WheelCJAward_Light[i]:Play(true)
		else
			Frozen_WheelCJAward_Light[i]:Play(false)
		end
	end
	
	Frozen_WheelCJ_Update_Client1_Text()
	
	if g_FrozenNextCJLevel > g_FrozenCJLevel then
		g_FrozenCJLevel = g_FrozenNextCJLevel
		Frozen_WheelCJ_Update_Client1()
	end
	
	--SetTimer("Frozen_WheelCJ","Frozen_WheelCJ_Tick()", g_Frozen_animate.minSpeed)
end

--function Frozen_WheelCJ_Tick()
--	KillTimer("Frozen_WheelCJ_Tick()")
--	for i = 1, 8 do
--		Frozen_WheelCJAward_Light[i]:Play(false)
--	end
	
--	if g_Frozen_animate_Round < g_Frozen_animate.round then
--		if g_Frozen_animate_Step < g_FrozenItem_Max then
--			g_Frozen_animate_Step = g_Frozen_animate_Step + 1
--		else
--			g_Frozen_animate_Step = 1
--			g_Frozen_animate_Round = g_Frozen_animate_Round + 1
--		end
--	elseif g_Frozen_animate_Round == g_Frozen_animate.round then
--		if g_Frozen_animate_Step < g_Frozen_animate_rewardidx then
--			g_Frozen_animate_Step = g_Frozen_animate_Step + 1
--		elseif g_Frozen_animate_Step == g_Frozen_animate_rewardidx then
--			Frozen_WheelCJ_Client1_Animate_End()
--			return
--		end
--	end
--	Frozen_WheelCJAward_Light[g_Frozen_animate_Step]:Play(true)
	
--	local nTime = g_Frozen_animate.minSpeed+g_Frozen_animate.decay*(g_Frozen_animate_Round*3 + g_Frozen_animate_Step)
--	SetTimer("Frozen_WheelCJ","Frozen_WheelCJ_Tick()", nTime)
--end
--=========================================================
--结束
--=========================================================
function Frozen_WheelCJ_Client1_Animate_End(nIndex)
--	Frozen_WheelCJAward_Light[g_Frozen_animate_Step]:Play(true)
	
--	Frozen_WheelCJ_Update_Client1_Text()
	
--	if g_FrozenNextCJLevel > g_FrozenCJLevel then
--		g_FrozenCJLevel = g_FrozenNextCJLevel
--		Frozen_WheelCJ_Update_Client1()
--	end
end

--=========================================================
--兑换界面刷新
--=========================================================
--function Frozen_WheelCJ_Update_Client2()
--	local sumnum = DataPool:LuaFnGetSnowShopItemInfoCount()
--	local maxPageNum = math.ceil(sumnum/12)
--	if maxPageNum<1 then
--		maxPageNum = 1
--	end
	
--	if g_curShopPage <= 0 then
--		g_curShopPage = 1
--	end
	
--	if g_curShopPage > maxPageNum then
--		g_curShopPage = maxPageNum
--	end
	
--	local startidx = (g_curShopPage-1)*12+1
--	local endidx = startidx + 12 - 1
--	if endidx > sumnum then
--		endidx = sumnum
--	end
	
--	local idx = startidx
--	local limitidx = 1
--	for i = 1, 12 do			
--		Frozen_WheelCJ_Client2_ItemFrame[i]:Hide()
				
--		if idx <= endidx then
--			Frozen_WheelCJ_Client2_ItemFrame[i]:Show()
--			Frozen_WheelCJ_Client2_Item_BuyLimit[i]:Hide()
--			Frozen_WheelCJ_Client2_Item_BuyLimitNumBK[i]:Hide()
--			Frozen_WheelCJ_Client2_Item_SellOut[i]:Hide()
--			Frozen_WheelCJ_Client2_Item_Mask[i]:Hide()
				
--			local nShowItemId,nItemNum,nIsBind,nMaxnum,nPrice = DataPool:LuaFnGetSnowShopItemInfo(idx)
			
--			if nShowItemId ~= nil and nShowItemId > 0 then
--				local theAction = nil
--				if nIsBind == 1 then
--					theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
--				else
--					theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
--				end
--				if theAction ~= nil then
--					Frozen_WheelCJ_Client2_Item[i]:SetActionItem(theAction:GetID())
--					Frozen_WheelCJ_Client2_Item_Name[i]:SetText(ScriptGlobal_Format("#{FPLS_240715_66}",theAction:GetName()))
--				end
				--限量
--				if nMaxnum > 0 then
--					Frozen_WheelCJ_Client2_Item_BuyLimit[i]:Show()
--					Frozen_WheelCJ_Client2_Item_BuyLimitNumBK[i]:Show()
--					if g_Frozen_ShopLimit[limitidx] ~= nil and g_Frozen_ShopLimit[limitidx] >= 0 then
--						local canbuy = nMaxnum - g_Frozen_ShopLimit[limitidx]
--						if canbuy <= 0 then
--							Frozen_WheelCJ_Client2_Item_SellOut[i]:Show() --售罄
--							Frozen_WheelCJ_Client2_Item_Mask[i]:Show()
--						end
--						Frozen_WheelCJ_Client2_Item_BuyLimitNum[i]:SetText(tostring(canbuy))
--						limitidx = limitidx + 1
--					end	
--				end
				
--				Frozen_WheelCJ_Client2_Item_Currency[i]:SetText(ScriptGlobal_Format("#{BXZP_240911_51}",nPrice))
--			end
--			idx = idx + 1
--		end
--	end		
--	Frozen_WheelCJ_Client2_Balance2:SetText("#L拥有元宝"..Player:GetData("YUANBAO"))
--	Frozen_WheelCJ_Client2_Balance:SetText("#L拥有代币"..g_FrozenDHDaibi)
	--上下页
--	if g_curShopPage == 1 then
--		Frozen_WheelCJ_Client2_UpPage:Disable()
--	else
--		Frozen_WheelCJ_Client2_DownPage:Enable()
--	end

--	if g_curShopPage == maxPageNum then
--		Frozen_WheelCJ_Client2_DownPage:Disable()
--	else
--		Frozen_WheelCJ_Client2_UpPage:Enable()
--	end

--	Frozen_WheelCJ_Client2_CurrentlyPage:SetText(ScriptGlobal_Format("#{FPLS_240715_78}", g_curShopPage,maxPageNum))
--end
--=========================================================
--上一页
--=========================================================
--function Frozen_WheelCJ_PageUp()
--	if g_curpage ~= 2 then
--		return
--	end
	
--	if g_curShopPage > 1 then
--		g_curShopPage = g_curShopPage - 1
--		Frozen_WheelCJ_Update_Client2()
--	end
--end
--=========================================================
--下一页
--=========================================================
--function Frozen_WheelCJ_PageDown()
--	if g_curpage ~= 2 then
--		return
--	end
--	local sumnum = DataPool:LuaFnGetSnowShopItemInfoCount()
--	local maxPageNum = math.ceil(sumnum/12)
--	if g_curShopPage < maxPageNum then
--		g_curShopPage = g_curShopPage + 1
--		Frozen_WheelCJ_Update_Client2()
--	end
--end

--function Frozen_WheelCJ_Client2_ItemClicked(nIndex)
--	local sumnum = DataPool:LuaFnGetSnowShopItemInfoCount()
--	local idx = (g_curShopPage-1)*12+nIndex
--	if idx < 1 or idx > sumnum then
--		return
--	end
	
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name( "BuyItem" )
--		Set_XSCRIPT_ScriptID( 999501 )
--		Set_XSCRIPT_Parameter(0,idx)
--		Set_XSCRIPT_ParamCount(1)
--	Send_XSCRIPT()	
--end

function Frozen_WheelCJ_PageBtn_SwitchPage(nPage)
	if g_curpage == nPage then
		return
	end
		
	if nPage == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenSnowUI" )
			Set_XSCRIPT_ScriptID( 999501 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif nPage == 2 then
		
	end
end

function Frozen_WheelCJ_GetReward(nIndex)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetLJReward" )
			Set_XSCRIPT_ScriptID( 999501 )
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
end
--=========================================================
--关闭
--=========================================================
function Frozen_WheelCJ_Close()
	this:Hide()
end

function Frozen_WheelCJ_OnHiden()
	Frozen_WheelCJ_Close()
end
--=========================================================
--刷新位置
--=========================================================
function Frozen_WheelCJ_On_ResetPos()
	Frozen_WheelCJ_FrameNULL:SetProperty("UnifiedPosition", g_Frozen_WheelCJ_UnifiedPosition);
end


function Frozen_WheelCJ_Help_Clicked()
	PushEvent("CCSHOP_HELP", 229)
end

function Frozen_WheelCJ_LotteryBtnClick()
	if g_curpage == 1 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DrawLottery" )
			Set_XSCRIPT_ScriptID( 999501 )
    		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	end
end

function Frozen_WheelCJ_BuyBtn()
	local curDay = DataPool:GetServerDayTime()
	if curDay >= g_Frozen_BuyBeginTime and curDay <= g_Frozen_EndTime then
		PushEvent("OPEN_SNOW_WhEElCJMBUY", g_FrozenBuyDaibi)
	else
		PushDebugMessage("#{BXZP_240911_103}")
	end
end

function Frozen_WheelCJ_Preview()
	PushEvent("OPEN_SNOW_WhEElPREVIEW")
end

function Frozen_WheelCJAward7_Preview()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10128101)
		Set_XSCRIPT_Parameter(1, -1)
		Set_XSCRIPT_Parameter(2, -1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end