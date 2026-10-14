--清空购物车界面
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_SelectStartTime = 20210422 --可挑选商品放入购物车
local g_SelectEndTime = 20210430 --可挑选商品放入购物车

local g_AwardStartTime = 20210506--可使用抽奖代币抽奖
local g_AwardEndTime = 20210523 --可使用抽奖代币抽奖
local g_ExchangeEndTime = 20210526 --最终兑换时间

local g_PoolButtonList = {} --奖池按钮
local g_PoolTipsList = {}	--奖池小红点
local g_PoolCompleteList = {} --奖池完成标记

local g_SelectClient = {} --奖池界面
local g_SelectButtonList = {} --选择道具按钮
local g_SelectCompleteList = {} --选择完成标记

local g_AwardButtonList = {} --奖励道具按钮
local g_AwardCompleteList = {} --奖励完成标记
local g_AwardAnimateList = {} --奖励完成标记

local g_ScreenAnimateList = {} --特效

local g_Index2ItemPos = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1} --选择界面 数组下表到itemPos索引
local g_SelectItemPos = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1} --选择界面 选择的itemPos
local g_Award_Index2ItemPos = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1} --领奖界面

local g_SelectPoolId = -1
local g_DaiBiCost = {
	[1] = 30,
	[2] = 40,
	[3] = 50,
	[4] = 60,
	[5] = 70,
	[6] = 80,
	[7] = 120,
	[8] = 400,
	[9] = 1000,
	[10] = 0,
}

local g_MaxPool = {
	[0] = 5,
	[1] = 2,
	[2] = 1,
	[3] = 1,
	[4] = 1,
}

local g_LastCilckTime = 0
local g_ClickMaxTime = 1 * 1000

local g_HuoDongJieShao = {
	[0] = "#{QKGWC_210311_25}",
	[1] = "#{QKGWC_210311_25}",
	[2] = "#{QKGWC_210311_25}",
	[3] = "#{QKGWC_210311_25}",
	[4] = "#{QKGWC_210311_25}",
	[5] = "#{QKGWC_210311_31}",
}

function ShopingCart_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("UPDATE_GOUWUCHE")
	--
	this:RegisterEvent("GOUWUCHE_SUBMIT_CONFIRM", false)
	
	this:RegisterEvent("UI_COMMAND", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function ShopingCart_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ShoppingCart_FrameNULL:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ShoppingCart_FrameNULL:GetProperty("UnifiedYPosition");

	g_PoolButtonList[1] = ShoppingCart_Buttontab01
	g_PoolButtonList[2] = ShoppingCart_Buttontab02
	g_PoolButtonList[3] = ShoppingCart_Buttontab03
	g_PoolButtonList[4] = ShoppingCart_Buttontab04
	g_PoolButtonList[5] = ShoppingCart_Buttontab05
	g_PoolButtonList[6] = ShoppingCart_Buttontab06
	
	g_PoolTipsList[1] = ShoppingCart_Buttontab01_Tips
	g_PoolTipsList[2] = ShoppingCart_Buttontab02_Tips
	g_PoolTipsList[3] = ShoppingCart_Buttontab03_Tips
	g_PoolTipsList[4] = ShoppingCart_Buttontab04_Tips
	g_PoolTipsList[5] = ShoppingCart_Buttontab05_Tips
	g_PoolTipsList[6] = ShoppingCart_Buttontab06_Tips
	
	g_PoolCompleteList[1] = ShoppingCart_Buttontab01_Complete
	g_PoolCompleteList[2] = ShoppingCart_Buttontab02_Complete
	g_PoolCompleteList[3] = ShoppingCart_Buttontab03_Complete
	g_PoolCompleteList[4] = ShoppingCart_Buttontab04_Complete
	g_PoolCompleteList[5] = ShoppingCart_Buttontab05_Complete

	g_SelectClient[0] = ShoppingCart_ClientABK
	g_SelectClient[1] = ShoppingCart_ClientBBK
	g_SelectClient[2] = ShoppingCart_ClientCBK
	g_SelectClient[3] = ShoppingCart_ClientDBK
	g_SelectClient[4] = ShoppingCart_ClientEBK
	
	g_SelectButtonList = {
		[0] = {ShoppingCart_Item1_Icon, ShoppingCart_Item2_Icon, ShoppingCart_Item3_Icon, ShoppingCart_Item4_Icon, ShoppingCart_Item5_Icon,
			ShoppingCart_Item6_Icon, ShoppingCart_Item7_Icon, ShoppingCart_Item8_Icon, ShoppingCart_Item9_Icon, ShoppingCart_Item10_Icon,
			ShoppingCart_Item11_Icon, ShoppingCart_Item12_Icon},
		
		[1] = {ShoppingCart_ItemB1_Icon, ShoppingCart_ItemB2_Icon, ShoppingCart_ItemB3_Icon, ShoppingCart_ItemB4_Icon, ShoppingCart_ItemB5_Icon,
			ShoppingCart_ItemB6_Icon, ShoppingCart_ItemB7_Icon, ShoppingCart_ItemB8_Icon, ShoppingCart_ItemB9_Icon, ShoppingCart_ItemB10_Icon},
			
		[2] = {ShoppingCart_ItemC1_Icon, ShoppingCart_ItemC2_Icon, ShoppingCart_ItemC3_Icon, ShoppingCart_ItemC4_Icon, ShoppingCart_ItemC5_Icon,
			ShoppingCart_ItemC6_Icon},
	
		[3] = {ShoppingCart_ItemD1_Icon, ShoppingCart_ItemD2_Icon, ShoppingCart_ItemD3_Icon},
		
		[4] = {ShoppingCart_ItemE1_Icon},
	}
	
	g_SelectCompleteList = {
		[0] = {ShoppingCart_Choose_Page_Lace1ItemBK1_Mask, ShoppingCart_Choose_Page_Lace1ItemBK2_Mask, ShoppingCart_Choose_Page_Lace1ItemBK3_Mask,
			ShoppingCart_Choose_Page_Lace1ItemBK4_Mask, ShoppingCart_Choose_Page_Lace1ItemBK5_Mask, ShoppingCart_Choose_Page_Lace1ItemBK6_Mask, 
			ShoppingCart_Choose_Page_Lace1ItemBK7_Mask, ShoppingCart_Choose_Page_Lace1ItemBK8_Mask, ShoppingCart_Choose_Page_Lace1ItemBK9_Mask,
			ShoppingCart_Choose_Page_Lace1ItemBK10_Mask, ShoppingCart_Choose_Page_Lace1ItemBK11_Mask, ShoppingCart_Choose_Page_Lace1ItemBK12_Mask},
		
		[1] = {ShoppingCart_Choose_Page_Lace1ItemBKB1_Mask, ShoppingCart_Choose_Page_Lace1ItemBKB2_Mask, ShoppingCart_Choose_Page_Lace1ItemBKB3_Mask, 
			ShoppingCart_Choose_Page_Lace1ItemBKB4_Mask, ShoppingCart_Choose_Page_Lace1ItemBKB5_Mask,
			ShoppingCart_Choose_Page_Lace1ItemBKB6_Mask, ShoppingCart_Choose_Page_Lace1ItemBKB7_Mask,
			ShoppingCart_Choose_Page_Lace1ItemBKB8_Mask, ShoppingCart_Choose_Page_Lace1ItemBKB9_Mask, ShoppingCart_Choose_Page_Lace1ItemBKB10_Mask},
			
		[2] = {ShoppingCart_Choose_Page_Lace1ItemBKC1_Mask, ShoppingCart_Choose_Page_Lace1ItemBKC2_Mask, ShoppingCart_Choose_Page_Lace1ItemBKC3_Mask, 
			ShoppingCart_Choose_Page_Lace1ItemBKC4_Mask, ShoppingCart_Choose_Page_Lace1ItemBKC5_Mask, ShoppingCart_Choose_Page_Lace1ItemBKC6_Mask},
	
		[3] = {ShoppingCart_Choose_Page_Lace1ItemBKD1_Mask, ShoppingCart_Choose_Page_Lace1ItemBKD2_Mask, ShoppingCart_Choose_Page_Lace1ItemBKD3_Mask},
		
		[4] = {ShoppingCart_Choose_Page_Lace1ItemBKE1_Mask},
	}
	
	
	g_AwardButtonList[1] = ShoppingCart_Choose_Page_Lace1Item1
	g_AwardButtonList[2] = ShoppingCart_Choose_Page_Lace1Item2
	g_AwardButtonList[3] = ShoppingCart_Choose_Page_Lace1Item3
	g_AwardButtonList[4] = ShoppingCart_Choose_Page_Lace1Item4
	g_AwardButtonList[5] = ShoppingCart_Choose_Page_Lace1Item5
	g_AwardButtonList[6] = ShoppingCart_Choose_Page_Lace1Item6
	g_AwardButtonList[7] = ShoppingCart_Choose_Page_Lace1Item7
	g_AwardButtonList[8] = ShoppingCart_Choose_Page_Lace1Item8
	g_AwardButtonList[9] = ShoppingCart_Choose_Page_Lace1Item9
	g_AwardButtonList[10] = ShoppingCart_Choose_Page_Lace1Item10
	
	g_AwardCompleteList[1] = ShoppingCart_Choose_Page_Lace1Item1_Mask
	g_AwardCompleteList[2] = ShoppingCart_Choose_Page_Lace1Item2_Mask
	g_AwardCompleteList[3] = ShoppingCart_Choose_Page_Lace1Item3_Mask
	g_AwardCompleteList[4] = ShoppingCart_Choose_Page_Lace1Item4_Mask
	g_AwardCompleteList[5] = ShoppingCart_Choose_Page_Lace1Item5_Mask
	g_AwardCompleteList[6] = ShoppingCart_Choose_Page_Lace1Item6_Mask
	g_AwardCompleteList[7] = ShoppingCart_Choose_Page_Lace1Item7_Mask
	g_AwardCompleteList[8] = ShoppingCart_Choose_Page_Lace1Item8_Mask
	g_AwardCompleteList[9] = ShoppingCart_Choose_Page_Lace1Item9_Mask
	g_AwardCompleteList[10] = ShoppingCart_Choose_Page_Lace1Item10_Mask
	
	g_AwardAnimateList[1] = ShoppingCart_Choose_Page_Lace1Item1_Animate
	g_AwardAnimateList[2] = ShoppingCart_Choose_Page_Lace1Item2_Animate
	g_AwardAnimateList[3] = ShoppingCart_Choose_Page_Lace1Item3_Animate
	g_AwardAnimateList[4] = ShoppingCart_Choose_Page_Lace1Item4_Animate
	g_AwardAnimateList[5] = ShoppingCart_Choose_Page_Lace1Item5_Animate
	g_AwardAnimateList[6] = ShoppingCart_Choose_Page_Lace1Item6_Animate
	g_AwardAnimateList[7] = ShoppingCart_Choose_Page_Lace1Item7_Animate
	g_AwardAnimateList[8] = ShoppingCart_Choose_Page_Lace1Item8_Animate
	g_AwardAnimateList[9] = ShoppingCart_Choose_Page_Lace1Item9_Animate
	g_AwardAnimateList[10] = ShoppingCart_Choose_Page_Lace1Item10_Animate
	
	g_ScreenAnimateList[1] = ShoppingCart_Fireworks1_Animate
	g_ScreenAnimateList[2] = ShoppingCart_Fireworks2_Animate
	g_ScreenAnimateList[3] = ShoppingCart_Fireworks3_Animate
	g_ScreenAnimateList[4] = ShoppingCart_Fireworks4_Animate
	g_ScreenAnimateList[5] = ShoppingCart_Fireworks5_Animate
	g_ScreenAnimateList[6] = ShoppingCart_Fireworks6_Animate
	g_ScreenAnimateList[7] = ShoppingCart_Fireworks7_Animate
end

function ShopingCart_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		ShopingCart_ResetPos()
	
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ShopingCart_ResetPos()
		
	elseif event == "UPDATE_GOUWUCHE" then
		ShopingCart_Update()
		
		if (true ~= this:IsVisible()) then
			this:Show()
		end
	
	elseif event == "GOUWUCHE_SUBMIT_CONFIRM" then
		ShopingCart_OnSubmit(1)
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88839202 then
		ShopingCart_AwardItemFlash()
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88839203 then
		ShopingCart_ScreenFlash()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ShoppingCart_Close()
	end
	
end

function ShopingCart_ResetPos()
	ShoppingCart_FrameNULL:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ShoppingCart_FrameNULL:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--清空
function ShopingCart_Clear()
	g_SelectPoolId = -1
	
	for i=1, table.getn(g_PoolButtonList) do
		g_PoolButtonList[i]:SetCheck(0)
	end
	
	for i=1, table.getn(g_PoolTipsList) do
		g_PoolTipsList[i]:Hide()
	end
	
	for i=1, table.getn(g_PoolCompleteList) do
		g_PoolCompleteList[i]:Hide()
	end
	
	local maxPool = Lua_GetGouWuCheMaxPool()
	for i=0, maxPool - 1 do
		g_SelectClient[i]:Hide()
	end
	
	for i=0, maxPool - 1 do
		local buttonList = g_SelectButtonList[i]
		for i2=1, table.getn(buttonList) do
			buttonList[i2]:SetActionItem( -1 )
		end
	end
	
	for i=0, maxPool - 1 do
		local buttonList = g_SelectCompleteList[i]
		for i2=1, table.getn(buttonList) do
			buttonList[i2]:Hide()
		end
	end
	
	for i=1, table.getn(g_AwardButtonList) do
		g_AwardButtonList[i]:SetActionItem( -1 )
	end
	
	for i=1, table.getn(g_AwardCompleteList) do
		g_AwardCompleteList[i]:Hide()
	end
	
	for i=1, table.getn(g_AwardAnimateList) do
		g_AwardAnimateList[i]:Play(false)
		g_AwardAnimateList[i]:Hide()
	end
	ShopingCart_Kill_Timer()
	
	for i=1, table.getn(g_SelectItemPos) do
		g_SelectItemPos[i] = -1
	end
	
	ShoppingCart_Fireworks_Animate:Hide()
	for i=1, table.getn(g_ScreenAnimateList) do
		g_ScreenAnimateList[i]:Play(false)
	end
	
	ShoppingCart_Frame:Hide()
	ShoppingCart_Select_Frame:Hide()
end

function ShopingCart_Update_PoolButton()
	local poolId = DataPool:LuaFnGetGouWuChePoolId()
	g_PoolButtonList[poolId + 1]:SetCheck(1)
	
	local maxPool = Lua_GetGouWuCheMaxPool()
	for i=1, table.getn(g_PoolTipsList) do
		local bShow = DataPool:LuaFnGetGouWuCheShowPoint(i - 1)
		if bShow == 1 then
			g_PoolTipsList[i]:Show()
		end
		
		if i > maxPool then
			if bShow == 1 then
				ShoppingCart_ChooseA_GetButtonTips:Show()
			else
				ShoppingCart_ChooseA_GetButtonTips:Hide()
			end
		end
	end
	
	for i=1, table.getn(g_PoolCompleteList) do
		local bFinish = DataPool:LuaFnGetGouWuCheSelectInfo(i - 1)
		if bFinish == 1 then
			g_PoolCompleteList[i]:Show()
		end
	end
end


function ShopingCart_Update_Select(poolId)
	ShoppingCart_Select_Frame:Show()
	g_SelectClient[poolId]:Show()

	local selectButtonList = g_SelectButtonList[poolId]
	local completeButtonList = g_SelectCompleteList[poolId]
	
	local maxItemNum = Lua_GetGouWuCheMaxItemNum()
	local itemIndex = 0
	for itemPos=0, maxItemNum - 1 do
		local itemPoolId, ShowItemId, ItemCount = Lua_GetGouWuCheItemInfo(itemPos)
		if itemPoolId < 0 then
			break
		end
		
		if itemPoolId == poolId then
			local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)
			if theAction ~= nil then
				itemIndex = itemIndex + 1
				selectButtonList[itemIndex]:SetActionItem(theAction:GetID())
				g_Index2ItemPos[itemIndex] = itemPos
			end
		end
	end

	local bFinish, itemPos0, itemPos1, itemPos2, itemPos3, itemPos4 = DataPool:LuaFnGetGouWuCheSelectInfo(poolId)

	local itemNum = 0
	local itemPosList = {itemPos0, itemPos1, itemPos2, itemPos3, itemPos4}
	for i=1, table.getn(itemPosList) do
		if itemPosList[i] >= 0 then
			itemNum = itemNum + 1
			
			for index=1, table.getn(g_Index2ItemPos) do
				if g_Index2ItemPos[index] == itemPosList[i] then
					completeButtonList[index]:Show()
					break
				end
			end

		end
	end

	if itemNum >= g_MaxPool[poolId] then
		local text = ScriptGlobal_Format("#{QKGWC_210311_28}", itemNum, g_MaxPool[poolId])
		ShoppingCart_SelectItem_CostText:SetText(text)
	else
		local text = ScriptGlobal_Format("#{QKGWC_210311_27}", itemNum, g_MaxPool[poolId])
		ShoppingCart_SelectItem_CostText:SetText(text)
	end


	if bFinish ~= 1 then
		ShoppingCart_Choose_SelectButton:Enable()
	else
		ShoppingCart_Choose_SelectButton:Disable()
	end
end

--更新奖励界面
function ShopingCart_Update_Award()
	ShoppingCart_Frame:Show()
	
	local buttonIndex = 1
	local maxPool = Lua_GetGouWuCheMaxPool()
	for i=1, maxPool do
		local bFinish, itemPos0, itemPos1, itemPos2, itemPos3, itemPos4 = DataPool:LuaFnGetGouWuCheSelectInfo(i - 1)
		if bFinish == 1 then
			local itemList = {itemPos0, itemPos1, itemPos2, itemPos3, itemPos4}
			
			for itemIndex=1, table.getn(itemList) do
			
				if itemList[itemIndex] >= 0 then
					local poolId, ShowItemId, ItemCount = Lua_GetGouWuCheItemInfo(itemList[itemIndex])--获得表里的道具
					local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)
					if theAction ~= nil then
						g_AwardButtonList[buttonIndex]:SetActionItem(theAction:GetID())
					end
					g_Award_Index2ItemPos[buttonIndex] = itemList[itemIndex]
					buttonIndex = buttonIndex + 1
				end
				
			end
			
		end
	end
	
	for i=1, table.getn(g_AwardCompleteList) do
		local itemPos = DataPool:LuaFnGetGouWuCheAward(i - 1)
		if itemPos >= 0 then
		
			for itemIndex=1, table.getn(g_Award_Index2ItemPos) do
				if g_Award_Index2ItemPos[itemIndex] == itemPos then
					g_AwardCompleteList[itemIndex]:Show()
					break
				end
			end
			
		end
	end
	
	--抽奖次数显示
	local awardNum = DataPool:LuaFnGetGouWuCheAwardNum()
	local maxNum = Lua_GetGouWuCheMaxAwardNum()
	
	local bFinishAll = 1
	local maxPool = Lua_GetGouWuCheMaxPool()
	for i=1, maxPool do
		local bFinish = DataPool:LuaFnGetGouWuCheSelectInfo(i - 1)
		if bFinish == 0 then
			bFinishAll = 0
			break
		end
	end
		
	local nFree = DataPool:LuaFnGetGouWuCheFreeType()
	if nFree >= 1 then
		ShoppingCart_ChooseA_GetButtonAll:Show()
		ShoppingCart_ChooseA_GetButton:Hide()
		
		--	清除购物车活动介绍说明
		--5月6日至5月26日间，已获得清空购物车大奖纳尽绮珍资格的少侠，可以直接将已选择的奖励宝物逐个领取放入背包。QKGWC_210311_38
		ShoppingCart_Description_Text:SetText("#{QKGWC_210311_38}")
		
		if nFree == 1 then --通过清空购物车获得
			--恭喜获得清空购物车大奖纳尽绮珍资格！请逐一领取放入背包 QKGWC_210311_39
			ShoppingCart_BuyItem_CostText2:SetText("#{QKGWC_210311_39}")
		elseif nFree == 2 then --通过锦鲤榜获得
			ShoppingCart_BuyItem_CostText2:SetText("#{QKGWC_210311_83}")
		elseif nFree == 3 then --通过灯如昼获得
			ShoppingCart_BuyItem_CostText2:SetText("#{QKGWC_210311_84}")
		elseif nFree == 4 then --通过h5获得
			ShoppingCart_BuyItem_CostText2:SetText("#{QKGWC_210311_85}")
		end
		
		--4月22日至30日后如奖励未选择完，则隐藏上方文字，显示“恭喜获得清空购物车大奖！当前购物车暂未填满，请前往选择奖励” QKGWC_210311_41
		local nServerTime = DataPool:GetServerDayTime()
		if nServerTime >= g_SelectStartTime and nServerTime <= g_SelectEndTime and bFinishAll == 0 then
			ShoppingCart_BuyItem_CostText2:SetText("#{QKGWC_210311_41}")
			ShoppingCart_ChooseA_GetButtonAll:Disable()
		else
			ShoppingCart_ChooseA_GetButtonAll:Enable()
		end
		
		--隐藏拥有代币
		ShoppingCart_CostHave_Text_BK:Hide()
		ShoppingCart_CostHave_Text_Icon:Hide()
		
		ShoppingCart_TimeHave_Text_BK:Hide()
		ShoppingCart_TimeHave_Text_Icon:Hide()
		
	else
		
		ShoppingCart_ChooseA_GetButtonAll:Hide()
		ShoppingCart_ChooseA_GetButton:Show()
		
		--神品心诀选录只有获得拦芳华资格的人才能获取。QKGWC_210311_81  
		ShoppingCart_BuyItem_CostText2:SetText("#{QKGWC_210311_81}")
	
		local nServerTime = DataPool:GetServerDayTime()
		if nServerTime > g_AwardEndTime or awardNum >= maxNum then
			--	5月23日后，隐藏消耗代币显示
			ShoppingCart_BuyItem_CostText2:Hide()
			
			--5月23日后，隐藏该按钮
			ShoppingCart_ChooseA_GetButton:Disable()
			
		elseif nServerTime >= g_SelectStartTime and nServerTime <= g_SelectEndTime and bFinishAll == 0 then
			--	4月22日至30日如奖励未选择完，则隐藏代币花费
			ShoppingCart_BuyItem_CostText2:Hide()
			ShoppingCart_ChooseA_GetButton:Enable()
			
		else
			ShoppingCart_BuyItem_CostText2:Show()		
			ShoppingCart_ChooseA_GetButton:Enable()
			
			local newTimes = awardNum + 1
			if newTimes < maxNum then
				--	需要：%s0
				local needDaiBi = g_DaiBiCost[newTimes]
				local strTemp = ScriptGlobal_Format("#{QKGWC_210311_32}", tostring(needDaiBi))
				ShoppingCart_BuyItem_CostText2:SetText(strTemp)
			else
				ShoppingCart_BuyItem_CostText2:SetText("#{QKGWC_210311_86}")
			end
		end
		
		--	A道具数量：%s0
		local daibi = DataPool:LuaFnGetGouWuCheDaiBi()
		ShoppingCart_CostHave_Text:SetText(daibi)
		
		--显示拥有代币
		ShoppingCart_CostHave_Text_BK:Show()
		ShoppingCart_CostHave_Text_Icon:Show()
		
		local numText = ScriptGlobal_Format("#{QKGWC_210311_43}", awardNum)
		ShoppingCart_TimeHave_Text:SetText(numText)
		
		ShoppingCart_TimeHave_Text_BK:Show()
		ShoppingCart_TimeHave_Text_Icon:Show()
	end
end

function ShopingCart_Update()
	ShopingCart_Clear()
	
	--更新左侧按钮栏
	ShopingCart_Update_PoolButton()
	
	local poolId = DataPool:LuaFnGetGouWuChePoolId()
	local maxPool = Lua_GetGouWuCheMaxPool()

	g_SelectPoolId = poolId

	local text = g_HuoDongJieShao[g_SelectPoolId]
	if text ~= nil then
		if g_SelectPoolId == maxPool then
			ShoppingCart_Description_Text:SetText(text)
		else
			ShoppingCart_Description_Text1:SetText(text)
		end
	end

	if g_SelectPoolId == maxPool then
		--更新领奖界面
		ShopingCart_Update_Award()
	else
		ShopingCart_Update_Select(g_SelectPoolId)
	end
end

--点击ABC奖池选中道具
function ShopingCart_OnSelect(index)
	local nPlayerLevel = Player:GetData("LEVEL");
	if nPlayerLevel < 30 then
		PushDebugMessage("#{QKGWC_210311_20}")
		return
	end
	
	local bFinish = DataPool:LuaFnGetGouWuCheSelectInfo(g_SelectPoolId)
	if bFinish == 1 then
		return
	end

	local itemPos = g_Index2ItemPos[index]
	if itemPos == nil or itemPos < 0 then
		return
	end

	local itemNum = 0
	for i=1, table.getn(g_SelectItemPos) do
		if g_SelectItemPos[i] ~= nil and g_SelectItemPos[i] >= 0 then
			itemNum = itemNum + 1
		end
	end

	if g_SelectItemPos[index] < 0 and itemNum >= g_MaxPool[g_SelectPoolId] then
		PushDebugMessage("#{QKGWC_210311_45}")
		return
	end

	--可以选了
	local completeButtonList = g_SelectCompleteList[g_SelectPoolId]
	if g_SelectItemPos[index] >= 0 then
		completeButtonList[index]:Hide()
		g_SelectItemPos[index] = -1
		itemNum = itemNum - 1
	else
		completeButtonList[index]:Show()
		g_SelectItemPos[index] = itemPos
		itemNum = itemNum + 1
	end

	if itemNum >= g_MaxPool[g_SelectPoolId] then
		local text = ScriptGlobal_Format("#{QKGWC_210311_28}", itemNum, g_MaxPool[g_SelectPoolId])
		ShoppingCart_SelectItem_CostText:SetText(text)
	else
		local text = ScriptGlobal_Format("#{QKGWC_210311_27}", itemNum, g_MaxPool[g_SelectPoolId])
		ShoppingCart_SelectItem_CostText:SetText(text)
	end
end

--3.5.7	点击ABC奖池中确认选择判断
function ShopingCart_OnSubmit( confirm )
	
	local nPlayerLevel = Player:GetData("LEVEL");
	if nPlayerLevel < 30 then
		PushDebugMessage("#{QKGWC_210311_20}")
		return
	end

	if nil == g_MaxPool[g_SelectPoolId] then
		PushDebugMessage("#{QKGWC_210311_46}")
		return
	end
	
	local itemNum = 0
	for index=1, table.getn(g_SelectItemPos) do
		if g_SelectItemPos[index] ~= nil and g_SelectItemPos[index] >= 0 then
			itemNum = itemNum + 1
		end
	end
		
	if itemNum ~= g_MaxPool[g_SelectPoolId] then
		PushDebugMessage("#{QKGWC_210311_46}")
		return
	end
	
	--	弹出二级确认框
	if confirm == 0 then
		PushEvent("GOUWUCHE_SUBMIT", itemNum)
		return
	end
	
	--已经确认过了
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SelectItem")
		Set_XSCRIPT_ScriptID(888392)
		
		Set_XSCRIPT_Parameter(0, g_SelectPoolId)
		
		itemNum = 1
		for index=1, table.getn(g_SelectItemPos) do
			if g_SelectItemPos[index] ~= nil and g_SelectItemPos[index] >= 0 then
				Set_XSCRIPT_Parameter(itemNum, g_SelectItemPos[index])
				itemNum = itemNum + 1
			end
		end
	
		Set_XSCRIPT_ParamCount(itemNum)
	Send_XSCRIPT()
end


--3.5.8	点击清空购物车抽取一次判断
function ShopingCart_GetAward()
	local nPlayerLevel = Player:GetData("LEVEL");
	if nPlayerLevel < 30 then
		PushDebugMessage("#{QKGWC_210311_20}")
		return
	end
	
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	local curTime = OSAPI:GetTickCount()
	if(curTime - g_LastCilckTime < g_ClickMaxTime) then
		PushDebugMessage("#{QKGWC_210311_49}") 
		return
	end
	
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	local awardNum = DataPool:LuaFnGetGouWuCheAwardNum()
	local maxNum = Lua_GetGouWuCheMaxAwardNum()
	if awardNum >= maxNum then
		PushDebugMessage("#{QKGWC_210311_52}")
		return
	end
	
	g_LastCilckTime = curTime

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CleanUpGouWuChe")
		Set_XSCRIPT_ScriptID(888392)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ShoppingCart_Page_Clicked(poolId)
	local maxPool = Lua_GetGouWuCheMaxPool()
	if poolId < 0 or poolId > maxPool then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SwitchClientUI")
		Set_XSCRIPT_ScriptID(888392)
		Set_XSCRIPT_Parameter(0, poolId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ShoppingCart_Close()
	CloseWindow("ShopingReceive", true);
	ShopingCart_Kill_Timer()
	this:Hide();
end

function ShoppingCart_OnHiden()
	ShoppingCart_Close()
end

function ShoppingCart_Help_Clicked()
	PushEvent("QUEST_HELP_MSG", "#{QKGWC_210311_26}")
end

function ShoppingCart_Item_Click()
end

function ShopingCart_AwardItemFlash()

	local itemPos = Get_XParam_INT(0)	
	if itemPos == nil or itemPos < 0 then
		return
	end
	
	for itemIndex=1, table.getn(g_Award_Index2ItemPos) do
		if g_Award_Index2ItemPos[itemIndex] == itemPos then
			g_AwardAnimateList[itemIndex]:Show()
			g_AwardAnimateList[itemIndex]:Play(true)
			
			SetTimer("ShopingCart", "ShopingCart_AutoClick_Timer()", 2000)
			
			break
		end
	end
	
end

function ShopingCart_AutoClick_Timer()
	for i=1, table.getn(g_AwardAnimateList) do
		g_AwardAnimateList[i]:Hide()
		g_AwardAnimateList[i]:Play(false)
	end
	
	ShopingCart_Kill_Timer()
end

function ShopingCart_Kill_Timer()
	
	KillTimer("ShopingCart_AutoClick_Timer()")
end

function ShopingCart_ScreenFlash()
	ShoppingCart_Fireworks_Animate:Show()
	
	for i=1, table.getn(g_ScreenAnimateList) do
		g_ScreenAnimateList[i]:Play(true)
	end
end
