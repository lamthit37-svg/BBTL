
local g_DuanWu_JiFenShop_UnifiedPosition;

local DuanWu_JiFenShop_BuyItem_Num = {}
local g_DuanWu_JiFenShop_ItemNumMax = 999
local g_DuanWu_JiFenShop_ShowItemInfo = {}
local DuanWu_JiFenShop_ActionButton = {}
local DuanWu_JiFenShop_ItemName = {}
local DuanWu_JiFenShop_ItemButton = {}
local DuanWu_JiFenShop_Num = {}
local DuanWu_JiFenShop_Cost = {}
local DuanWu_JiFenShop_Mark = {}
local DuanWu_JiFenShop_Mark2 = {}
--活动时间
local g_DuanWuShop_StartDayTime = 20210614
local g_DuanWuShop_YBCostEndDayTime = 20210627
local g_DuanWuShop_CreditEndDayTime = 20210630

local g_DuanWu_JiFenShop_ItemList = {
	[1] = {id = 39921716, type = 1, limit = -1, yuanbao = 98, credit = 0, extra = 98},
	[2] = {id = 39921701, type = 1, limit = -1, yuanbao = 298, credit = 0, extra = 298},
	[3] = {id = 39921737, type = 2, limit = -1, yuanbao = 0, credit = 20},
	[4] = {id = 39920180, type = 2, limit = 30, yuanbao = 0, credit = 2700},
	[5] = {id = 39920397, type = 2, limit = 10, yuanbao = 0, credit = 9000},
	[6] = {id = 39920396, type = 2, limit = 10, yuanbao = 0, credit = 9000},
	[7] = {id = 39921749, type = 3, limit = -1, yuanbao = 0, credit = 1},

}

local g_DuanWu_MD_List = {}
local g_DuanWu_JiFen = 0;
local g_DuanWu_YB = 0;
local g_DuanWuShop_CurIndex = 0

function DuanWu_JiFenShop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("UPDATE_YUANBAO",false)
end

function DuanWu_JiFenShop_OnLoad()

	for i = 1, 7 do
		DuanWu_JiFenShop_ActionButton[i] = "DuanWu_JiFenShop_Item".. i .. "_Icon"
		DuanWu_JiFenShop_ItemName[i] = "DuanWu_JiFenShop_Item".. i .. "_Name"
		DuanWu_JiFenShop_ItemButton[i] = "DuanWu_JiFenShop_Item".. i
		--DuanWu_JiFenShop_Num[i] = "DuanWu_JiFenShop_Item".. i .. "_Num"
		DuanWu_JiFenShop_Cost[i] = "DuanWu_JiFenShop_Item".. i .. "_Cost"
		DuanWu_JiFenShop_Mark[i] = "DuanWu_JiFenShop_Item".. i .. "_Mark"
		DuanWu_JiFenShop_Mark2[i] = "DuanWu_JiFenShop_Item".. i .. "_Mark2"
	end
	for i = 1, 7 do
		g_DuanWu_JiFenShop_ShowItemInfo[i] = {
			ActionButton = _G[DuanWu_JiFenShop_ActionButton[i]],
			NameStr = _G[DuanWu_JiFenShop_ItemName[i]],
			BuyButton = _G[DuanWu_JiFenShop_ItemButton[i]],
			--ItemNum = _G[DuanWu_JiFenShop_Num[i]],
			CostText = _G[DuanWu_JiFenShop_Cost[i]],
			Mark = _G[DuanWu_JiFenShop_Mark[i]],
			Mark2 = _G[DuanWu_JiFenShop_Mark2[i]],
		}
	end
	
	g_DuanWu_JiFenShop_UnifiedPosition = DuanWu_JiFenShop:GetProperty("UnifiedPosition")
	
end

function DuanWu_JiFenShop_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 50508301 ) then
		local operator = Get_XParam_INT(0)
		if operator == 1 then
			if IsWindowShow("VIP_Shop") then
				CloseWindow("VIP_Shop", true)
			end
			if(IsWindowShow("YuanbaoShop")) then
				CloseWindow("YuanbaoShop", true)
			end
			if(IsWindowShow("ShowShop")) then
				CloseWindow("ShowShop", true)
			end
			if(IsWindowShow("XuanShop")) then
				CloseWindow("XuanShop", true)
			end
			g_DuanWu_JiFen = Get_XParam_INT(1)		
			g_DuanWu_YB = Get_XParam_INT(2)
			for i = 1, 5 do
				g_DuanWu_MD_List[i] = Get_XParam_INT(i+2)
			end
			local curDay = tonumber(DataPool:GetServerDayTime())
			if curDay >= g_DuanWuShop_StartDayTime and curDay <= g_DuanWuShop_YBCostEndDayTime then
				g_DuanWuShop_CurIndex = 1
			else
				g_DuanWuShop_CurIndex = 3
			end
			
			DuanWu_JiFenShop_BuyItem_NumText:SetText(1)
			DuanWu_JiFenShop_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				g_DuanWu_JiFen = Get_XParam_INT(1)		
				g_DuanWu_YB = Get_XParam_INT(2)
				for i = 1, 5 do
					g_DuanWu_MD_List[i] = Get_XParam_INT(i+2)
				end
				DuanWu_JiFenShop_Update()
			end
		end

	elseif (event == "ADJEST_UI_POS" ) then
		DuanWu_JiFenShop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DuanWu_JiFenShop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		DuanWu_JiFenShop_YuanBaoNum:SetText(ScriptGlobal_Format( "#{QHNF_190429_78}", Player:GetData("YUANBAO")))
	end

end

--=========================================================
--更新界面
--=========================================================
function DuanWu_JiFenShop_Update()
	local totalnum = table.getn(g_DuanWu_JiFenShop_ItemList)
	
	for i = 1, totalnum do
		local theAction = DataPool:CreateActionItemForShow(g_DuanWu_JiFenShop_ItemList[i].id, 1)
		g_DuanWu_JiFenShop_ShowItemInfo[i].ActionButton:SetActionItem(theAction:GetID())
		g_DuanWu_JiFenShop_ShowItemInfo[i].NameStr:SetText("#L"..theAction:GetName())
		local curDay = tonumber(DataPool:GetServerDayTime())
		if g_DuanWu_JiFenShop_ItemList[i].type == 1 then
			g_DuanWu_JiFenShop_ShowItemInfo[i].CostText:SetText(ScriptGlobal_Format( "#{QHNF_190429_127}", g_DuanWu_JiFenShop_ItemList[i].yuanbao))
			if curDay < g_DuanWuShop_StartDayTime or curDay > g_DuanWuShop_YBCostEndDayTime then
				g_DuanWu_JiFenShop_ShowItemInfo[i].Mark:Hide()
				g_DuanWu_JiFenShop_ShowItemInfo[i].Mark2:Show()
			else
				g_DuanWu_JiFenShop_ShowItemInfo[i].Mark:Show()
				g_DuanWu_JiFenShop_ShowItemInfo[i].Mark:SetProperty("Image","set:DuanWu1 image:ItemMark")
				g_DuanWu_JiFenShop_ShowItemInfo[i].Mark2:Hide()
				g_DuanWu_JiFenShop_ShowItemInfo[i].NameStr:SetText("#M"..theAction:GetName())
			end
		elseif g_DuanWu_JiFenShop_ItemList[i].type == 2 or g_DuanWu_JiFenShop_ItemList[i].type == 3 then
			if g_DuanWu_JiFenShop_ItemList[i].type == 2 then
				g_DuanWu_JiFenShop_ShowItemInfo[i].CostText:SetText(ScriptGlobal_Format( "#{QHNF_190429_128}", g_DuanWu_JiFenShop_ItemList[i].credit))
			elseif g_DuanWu_JiFenShop_ItemList[i].type == 3 then
				g_DuanWu_JiFenShop_ShowItemInfo[i].CostText:SetText(ScriptGlobal_Format( "#{QHNF_190429_129}", g_DuanWu_JiFenShop_ItemList[i].credit))
			end
			
			if g_DuanWu_JiFenShop_ItemList[i].limit > 0 then

				local curcnt = DuanWu_JiFenShop_GetLimitCount(i)
				if curcnt >= g_DuanWu_JiFenShop_ItemList[i].limit then
					g_DuanWu_JiFenShop_ShowItemInfo[i].Mark:Hide()
					g_DuanWu_JiFenShop_ShowItemInfo[i].Mark2:Show()
				else
					g_DuanWu_JiFenShop_ShowItemInfo[i].Mark:Show()
					g_DuanWu_JiFenShop_ShowItemInfo[i].Mark:SetProperty("Image","set:DuanWu2 image:ItemMark3")
					g_DuanWu_JiFenShop_ShowItemInfo[i].Mark2:Hide()
				end
			else
				g_DuanWu_JiFenShop_ShowItemInfo[i].Mark:Hide()
				g_DuanWu_JiFenShop_ShowItemInfo[i].Mark2:Hide()
			end
		end
		
	end
	
	DuanWu_JiFenShop_XiangNangNum:SetText(ScriptGlobal_Format( "#{QHNF_190429_76}", g_DuanWu_JiFen))
	
	DuanWu_JiFenShop_YuanBaoNum:SetText(ScriptGlobal_Format( "#{QHNF_190429_78}", g_DuanWu_YB))
	
	DuanWu_JiFenShop_UpdateBuy_Client()
	
	this:Show()
end	

function DuanWu_JiFenShop_UpdateBuy_Client()
	for i = 1, table.getn(g_DuanWu_JiFenShop_ItemList) do
		-- 选中
		if g_DuanWuShop_CurIndex == i then
			g_DuanWu_JiFenShop_ShowItemInfo[i].BuyButton:SetProperty("Selected", "True")
		else
			g_DuanWu_JiFenShop_ShowItemInfo[i].BuyButton:SetProperty("Selected", "False")
		end
	end
	
	local ItemIndex = g_DuanWuShop_CurIndex
	if ItemIndex >= 1 and ItemIndex <= 7 then
		local theAction = DataPool:CreateActionItemForShow(g_DuanWu_JiFenShop_ItemList[ItemIndex].id, 1)
		DuanWu_JiFenShop_BuyItem:SetActionItem(theAction:GetID())
		DuanWu_JiFenShop_BuyItem_Name:SetText("#L"..theAction:GetName())
	
		local num = tonumber(DuanWu_JiFenShop_BuyItem_NumText:GetText())
		if(num == nil or num < 1) then
			num = 0
		end
		if( num > g_DuanWu_JiFenShop_ItemNumMax )then
			num = g_DuanWu_JiFenShop_ItemNumMax
		end
		
		local curDay = tonumber(DataPool:GetServerDayTime())
		if g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 1 then  --元宝

			DuanWu_JiFenShop_BuyItem_DuiHuanText:SetText("")
			DuanWu_JiFenShop_BuyItem_XiangNangText:SetText(ScriptGlobal_Format( "#{QHNF_190429_118}",g_DuanWu_JiFenShop_ItemList[ItemIndex].extra*num))
			DuanWu_JiFenShop_BuyItem_Cost:SetText(ScriptGlobal_Format( "#{QHNF_190429_23}", g_DuanWu_JiFenShop_ItemList[ItemIndex].yuanbao*num))
			DuanWu_JiFenShop_BuyItem_Time:SetText("#{QHNF_190429_108}")
			if curDay < g_DuanWuShop_StartDayTime or curDay > g_DuanWuShop_YBCostEndDayTime then
				DuanWu_JiFenShop_BuyItem_Btn:SetText("#{QHNF_190429_74}")
				DuanWu_JiFenShop_BuyItem_Btn:Disable()
				DuanWu_JiFenShop_BuyItem_Mark:Hide()
				DuanWu_JiFenShop_BuyItem_Mark2:Show()
			else
				DuanWu_JiFenShop_BuyItem_Btn:SetText("#{QHNF_190429_73}")
				DuanWu_JiFenShop_BuyItem_Btn:Enable()
				DuanWu_JiFenShop_BuyItem_Mark:Show()
				DuanWu_JiFenShop_BuyItem_Mark:SetProperty("Image","set:DuanWu1 image:ItemMark")
				DuanWu_JiFenShop_BuyItem_Mark2:Hide()
			end
		elseif g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 2 or g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 3 then --积分
			if g_DuanWu_JiFenShop_ItemList[ItemIndex].limit > 0 then --限量
				local curcnt = DuanWu_JiFenShop_GetLimitCount(ItemIndex)
				if curcnt < g_DuanWu_JiFenShop_ItemList[ItemIndex].limit then
					DuanWu_JiFenShop_BuyItem_DuiHuanText:SetText(ScriptGlobal_Format( "#{QHNF_190429_116}", curcnt, g_DuanWu_JiFenShop_ItemList[ItemIndex].limit))
					DuanWu_JiFenShop_BuyItem_Btn:SetText("#{QHNF_190429_75}")
					DuanWu_JiFenShop_BuyItem_Btn:Enable()
					DuanWu_JiFenShop_BuyItem_Mark:Show()
					DuanWu_JiFenShop_BuyItem_Mark:SetProperty("Image","set:DuanWu2 image:ItemMark3")
					DuanWu_JiFenShop_BuyItem_Mark2:Hide()
				else
					DuanWu_JiFenShop_BuyItem_DuiHuanText:SetText(ScriptGlobal_Format( "#{QHNF_190429_117}", curcnt, g_DuanWu_JiFenShop_ItemList[ItemIndex].limit))
					DuanWu_JiFenShop_BuyItem_Btn:SetText("#{QHNF_190429_74}")
					DuanWu_JiFenShop_BuyItem_Btn:Disable()
					DuanWu_JiFenShop_BuyItem_Mark:Hide()
					DuanWu_JiFenShop_BuyItem_Mark2:Show()
				end
			else
				DuanWu_JiFenShop_BuyItem_Mark:Hide()
				DuanWu_JiFenShop_BuyItem_Mark2:Hide()
				DuanWu_JiFenShop_BuyItem_DuiHuanText:SetText("")
				DuanWu_JiFenShop_BuyItem_Btn:SetText("#{QHNF_190429_75}")
				DuanWu_JiFenShop_BuyItem_Btn:Enable()
			end
			DuanWu_JiFenShop_BuyItem_XiangNangText:SetText("")
			if g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 2 then
				DuanWu_JiFenShop_BuyItem_Cost:SetText(ScriptGlobal_Format( "#{QHNF_190429_71}", g_DuanWu_JiFenShop_ItemList[ItemIndex].credit*num))	
			elseif g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 3 then
				DuanWu_JiFenShop_BuyItem_Cost:SetText(ScriptGlobal_Format( "#{QHNF_190429_124}", g_DuanWu_JiFenShop_ItemList[ItemIndex].credit*num))	
			end
			DuanWu_JiFenShop_BuyItem_Time:SetText("")	
		end
	end
	
	
end
--=========================================================
--商店说明
--=========================================================
function DuanWu_JiFenShop_Help_Clicked()
	PushEvent("CCSHOP_HELP", 102)
end

--=========================================================
--关闭
--=========================================================
function DuanWu_JiFenShop_Close()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function DuanWu_JiFenShop_On_ResetPos()
	DuanWu_JiFenShop:SetProperty("UnifiedPosition", g_DuanWu_JiFenShop_UnifiedPosition);
end


function DuanWu_JiFenShop_Item_Click(nIndex)
	if nIndex < 1 or nIndex > 7 then
		return
	end
	
	local ItemIndex = nIndex
	if ItemIndex < 1 or ItemIndex > table.getn(g_DuanWu_JiFenShop_ItemList) then
		return;
	end
	
	g_DuanWuShop_CurIndex = ItemIndex
	DuanWu_JiFenShop_BuyItem_NumText:SetText(1)
	
	DuanWu_JiFenShop_UpdateBuy_Client()
	--local curDay = tonumber(DataPool:GetServerDayTime())
	--if g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 1 then
	--	if curDay < g_DuanWuShop_StartDayTime or curDay > g_DuanWuShop_YBCostEndDayTime then
	--		PushDebugMessage("#{QHNF_190429_01}")
	--		return
	--	end
	--elseif g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 2 or g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 3 then
	--	if curDay < g_DuanWuShop_StartDayTime or curDay > g_DuanWuShop_CreditEndDayTime then
	--		PushDebugMessage("#{QHNF_190429_82}")
	--		return
	--	end
	--end
	
	--PushEvent("OPEN_DUANWU_SHOP_BUY", g_DuanWu_JiFenShop_ItemList[ItemIndex].type, ItemIndex, g_DuanWu_YB, g_DuanWu_JiFen)

end

function DuanWu_JiFenShop_Buy_Click()
	local strNum = DuanWu_JiFenShop_BuyItem_NumText:GetText();
	if strNum == nil or strNum == "" then
		PushDebugMessage("输入不能为空")
		return
	end
	
	if(tonumber(strNum) > g_DuanWu_JiFenShop_ItemNumMax) then
		PushDebugMessage("输入超上限，请重新输入")
		DuanWu_JiFenShop_BuyItem_NumText:SetText(1)
		return;
	end;

	if tonumber(strNum) <= 0 then
		PushDebugMessage("请重新输入")
		DuanWu_JiFenShop_BuyItem_NumText:SetText(1)
		return;			
	end

	local ItemIndex = g_DuanWuShop_CurIndex
	if ItemIndex < 1 or ItemIndex > table.getn(g_DuanWu_JiFenShop_ItemList) then
		return;
	end
	
	--1、表示元宝 2、表示积分
	if g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "YuanBaoBuy" )
			Set_XSCRIPT_ScriptID(505083)
			Set_XSCRIPT_Parameter(0,ItemIndex)
			Set_XSCRIPT_Parameter(1,tonumber(strNum))
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeReward" )
			Set_XSCRIPT_ScriptID(505083)
			Set_XSCRIPT_Parameter(0,ItemIndex)
			Set_XSCRIPT_Parameter(1,tonumber(strNum))
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeLiHe" )
			Set_XSCRIPT_ScriptID(505083)
			Set_XSCRIPT_Parameter(0,tonumber(strNum))
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
end

--===============================================
-- 个数加1
--===============================================
function DuanWu_JiFenShop_Add_Clicked()
	local szNum = DuanWu_JiFenShop_BuyItem_NumText:GetText();
	if szNum == "" then 
		szNum = "0"
	end

	local nNum = szNum + 1;
	
	if( nNum > g_DuanWu_JiFenShop_ItemNumMax )then
		nNum = g_DuanWu_JiFenShop_ItemNumMax
		PushDebugMessage("#{QHNF_190429_131}")
	end
	
	local ItemIndex = g_DuanWuShop_CurIndex
	if g_DuanWu_JiFenShop_ItemList[ItemIndex].limit > 0 and nNum > g_DuanWu_JiFenShop_ItemList[ItemIndex].limit then
		nNum = g_DuanWu_JiFenShop_ItemList[ItemIndex].limit
		PushDebugMessage("#{QHNF_190429_131}")
	end	
	
	DuanWu_JiFenShop_BuyItem_NumText:SetText(tostring(nNum));
	
	DuanWu_JiFenShop_UpdateBuy_Client()
end


--===============================================
-- 个数减1
--===============================================
function DuanWu_JiFenShop_Desc_Clicked()
	local szNum = DuanWu_JiFenShop_BuyItem_NumText:GetText();
	if szNum == "" then 
		szNum = "0"
	end
	
	local nNum = szNum - 1;

	local ItemIndex = g_DuanWuShop_CurIndex
	if( nNum < 1 )then
		nNum = 1
		if g_DuanWu_JiFenShop_ItemList[ItemIndex].type == 1 then
			PushDebugMessage("#{QHNF_190429_132}")
		else
			PushDebugMessage("#{QHNF_190429_133}")
		end
	end
	
	DuanWu_JiFenShop_BuyItem_NumText:SetText(tostring(nNum));
	
	DuanWu_JiFenShop_UpdateBuy_Client()
end
--===============================================
-- 变化
--===============================================
function DuanWu_JiFenShop_Changed()
	local szNum = DuanWu_JiFenShop_BuyItem_NumText:GetText()
	local num = 0
	
	if szNum == nil then
		return
	elseif szNum == "" then
		num = 1
	elseif szNum == "0" then
		DuanWu_JiFenShop_BuyItem_NumText:SetText("1")
		num = 1
	else
		num = tonumber(szNum)
	end
	
	--if(num == nil or num < 1) then
	--	DuanWu_JiFenShop_BuyItem_NumText:SetText("")
	--	return
	--end
	if(num > g_DuanWu_JiFenShop_ItemNumMax) then
		DuanWu_JiFenShop_BuyItem_NumText:SetText(tostring(g_DuanWu_JiFenShop_ItemNumMax))
	end	
	
	local ItemIndex = g_DuanWuShop_CurIndex
	if g_DuanWu_JiFenShop_ItemList[ItemIndex].limit > 0 and num > g_DuanWu_JiFenShop_ItemList[ItemIndex].limit then
		DuanWu_JiFenShop_BuyItem_NumText:SetText(tostring(g_DuanWu_JiFenShop_ItemList[ItemIndex].limit))
	end	
	
	DuanWu_JiFenShop_UpdateBuy_Client()
end


--获取物品已兑换数
function DuanWu_JiFenShop_GetLimitCount(nIndex)
	local totalnum = table.getn(g_DuanWu_JiFenShop_ItemList)
	if nIndex < 1 or nIndex > totalnum then
		return -1
	end 	
	
	local MDData = nil
	for i = 1, table.getn(g_DuanWu_MD_List) do
		if nIndex > 3*(i-1) and nIndex <= 3*i then
			MDData = g_DuanWu_MD_List[i]
			break
		end
	end

	local ret = -1
	if MDData ~= nil then
		local temp = math.mod(nIndex-1, 3) --0,1,2
		if temp == 0 then
			ret = math.mod(MDData, 1000)
		elseif temp == 1 then
			ret = math.mod(math.floor(MDData/1000), 1000)
		elseif temp == 2 then
			ret = math.mod(math.floor(MDData/1000000),1000)
		end
	end
	
	return ret
end
