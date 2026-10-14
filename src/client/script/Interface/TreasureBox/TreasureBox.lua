--TreasureBox
local g_TreasureBox_UnifiedPosition;

local TreasureBox_BuyItem_Num = {}
local g_TreasureBox_ItemNumMax = 999
local g_TreasureBox_ShowItemInfo = {}
local TreasureBox_ActionButton = {}
local TreasureBox_ItemName = {}
local TreasureBox_ItemButton = {}
local TreasureBox_ItemText1 = {}
local TreasureBox_Num = {}
local TreasureBox_Cost = {}
local TreasureBox_Cost2 = {}
local TreasureBox_Mark = {}
local TreasureBox_Mark2 = {}
local TreasureBox_pagebuttonleft = {}

local g_curDaibi1 = 0
local g_curDaibi2 = 0

local g_LibaoBuy_MD_List = {}

local g_curTBIndex = 0
local g_RedPointIsShow = 0
local g_RedPointIsShow2 = 0

local g_CurItemIndex = 0
local g_MaxLibaoCount = 3

function TreasureBox_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("UPDATE_YUANBAO",false)
end

function TreasureBox_OnLoad()

	for i = 1, 3 do
		TreasureBox_ActionButton[i] = "TreasureBox_Item".. i .. "_Icon"
		TreasureBox_ItemName[i] = "TreasureBox_Item".. i .. "_Text"
		TreasureBox_ItemText1[i] = "TreasureBox_Item".. i .. "_Text2"
		TreasureBox_Cost[i] = "TreasureBox_Item".. i .. "_Text3"
		TreasureBox_Cost2[i] = "TreasureBox_Item".. i .. "_Text4"
		--TreasureBox_Mark[i] = "TreasureBox_Item".. i .. "_Mark"
		--TreasureBox_Mark2[i] = "TreasureBox_Item".. i .. "_Mark2"
	end
	for i = 1, 3 do
		g_TreasureBox_ShowItemInfo[i] = {
			ActionButton = _G[TreasureBox_ActionButton[i]],
			NameStr = _G[TreasureBox_ItemName[i]],
			LimitText = _G[TreasureBox_ItemText1[i]],			
			CostText = _G[TreasureBox_Cost[i]],
			NormalCost = _G[TreasureBox_Cost2[i]],
			--Mark = _G[TreasureBox_Mark[i]],
			--Mark2 = _G[TreasureBox_Mark2[i]],
		}
	end
	
	TreasureBox_pagebuttonleft[1] = TreasureBox_Buttontab01
	TreasureBox_pagebuttonleft[2] = TreasureBox_Buttontab02
	TreasureBox_pagebuttonleft[3] = TreasureBox_Buttontab03
	TreasureBox_pagebuttonleft[4] = TreasureBox_Buttontab04
	
	g_TreasureBox_UnifiedPosition = TreasureBox_FrameNULL:GetProperty("UnifiedPosition")
	
end

function TreasureBox_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88814301 ) then
		if IsWindowShow("TreasureBox_MBuy") then
			CloseWindow("TreasureBox_MBuy", true)
		end
		if IsWindowShow("TreasureBox_Preview") then
			CloseWindow("TreasureBox_Preview", true)
		end
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
			g_curDaibi1 = Get_XParam_INT(1)		
			g_curDaibi2 = Get_XParam_INT(2)
			g_curTBIndex = Get_XParam_INT(3)
			g_RedPointIsShow = Get_XParam_INT(4)
			--g_RedPointIsShow2 = Get_XParam_INT(5)
			for i = 1, 3 do
				g_LibaoBuy_MD_List[i] = Get_XParam_INT(i+4)
			end
			
			TreasureBox_On_SetLastPos()
			
			TreasureBox_Update(0)
		elseif operator == 2 then
			if this:IsVisible() then
				g_curDaibi1 = Get_XParam_INT(1)		
				g_curDaibi2 = Get_XParam_INT(2)
				g_curTBIndex = Get_XParam_INT(3)
				g_RedPointIsShow = Get_XParam_INT(4)
				--g_RedPointIsShow2 = Get_XParam_INT(5)
				for i = 1, 3 do
					g_LibaoBuy_MD_List[i] = Get_XParam_INT(i+4)
				end
				TreasureBox_Update(0)
			end
		elseif operator == 3 then
			if this:IsVisible() then
				g_curDaibi1 = Get_XParam_INT(1)		
				g_curDaibi2 = Get_XParam_INT(2)
				g_curTBIndex = Get_XParam_INT(3)
				g_RedPointIsShow = Get_XParam_INT(4)
				--g_RedPointIsShow2 = Get_XParam_INT(5)
				for i = 1, 3 do
					g_LibaoBuy_MD_List[i] = Get_XParam_INT(i+4)
				end
				TreasureBox_Update(1)
			end
		end

	elseif (event == "ADJEST_UI_POS" ) then
		TreasureBox_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TreasureBox_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if IsWindowShow("TreasureBox_MBuy") then
			CloseWindow("TreasureBox_MBuy", true)
		end
		if IsWindowShow("TreasureBox_Preview") then
			CloseWindow("TreasureBox_Preview", true)
		end
		if IsWindowShow("TreasureBox_AwardPreview") then
			CloseWindow("TreasureBox_AwardPreview", true)
		end
		if IsWindowShow("TreasureBox_Award") then
			CloseWindow("TreasureBox_Award", true)
		end
		if IsWindowShow("TreasureBox_Prize") then
			CloseWindow("TreasureBox_Prize", true)
		end
		this:Hide()
	--elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		--TreasureBox_YuanBaoNum:SetText(ScriptGlobal_Format( "#{RCLS_200731_45}", Player:GetData("YUANBAO")))
	end

end

--=========================================================
--更新界面
--=========================================================
function TreasureBox_Update(optype)
	TreasureBox_ButtonPage(1)
	local nCount = GetLashouShopLibaoCount(g_curTBIndex)
	if nCount == 0  or nCount > g_MaxLibaoCount then
		return
	end
		
	for i = 1, nCount do
		local nItemShowId, nItemNum, nLimit, nDisCount, nYB = GetLashouShopLibaoItem(g_curTBIndex, i)
		if nItemShowId < 0 then
			return
		end
		
		local theAction = DataPool:CreateActionItemForShow(nItemShowId, nItemNum)
		g_TreasureBox_ShowItemInfo[i].ActionButton:SetActionItem(theAction:GetID())
		g_TreasureBox_ShowItemInfo[i].NameStr:SetText("#L"..theAction:GetName())
		
		if nLimit ~=nil and nLimit > 0 then
			local curbuycnt = TreasureBox_GetLimitCount(i)
			if curbuycnt >= nLimit then
				g_TreasureBox_ShowItemInfo[i].LimitText:SetText("#{RCLS_200731_37}") --售罄
			else
				g_TreasureBox_ShowItemInfo[i].LimitText:SetText(ScriptGlobal_Format( "#{RCLS_200731_36}", curbuycnt, nLimit))
			end
		else
			g_TreasureBox_ShowItemInfo[i].LimitText:SetText("#{RCLS_260330_01}") 
		end
		
		if i ~= 1 then
			g_TreasureBox_ShowItemInfo[i].NormalCost:SetText(ScriptGlobal_Format( "#{RCLS_200731_139}", (400*nItemNum)))
		end

		--折扣
		if nDisCount < 100 then
			g_TreasureBox_ShowItemInfo[i].CostText:SetText(ScriptGlobal_Format( "#{RCLS_200731_39}", nYB))
		else
			g_TreasureBox_ShowItemInfo[i].CostText:SetText(ScriptGlobal_Format( "#{RCLS_200731_38}", nYB))
		end
	end

	if g_RedPointIsShow == 0 then
		TreasureBox_Buttontab01_Tips:Hide()
		TreasureBox_MissionInfo_RelieveBtn_Tips:Hide()
	else
		TreasureBox_Buttontab01_Tips:Show()
		TreasureBox_MissionInfo_RelieveBtn_Tips:Show()
	end

	--if g_RedPointIsShow2 == 0 then
	--	TreasureBox_CountInfo_RelieveBtn_Tips:Hide()
	--else
	--	TreasureBox_CountInfo_RelieveBtn_Tips:Show()
	--end
	--TreasureBox_YuanBaoNum:SetText(ScriptGlobal_Format( "#{RCLS_200731_45}", Player:GetData("YUANBAO")))
	
	--TreasureBox_YuanBaoNum2:SetText(ScriptGlobal_Format( "#{RCLS_200731_46}", g_curDaibi1))
	
	--TreasureBox_YuanBaoNum3:SetText(ScriptGlobal_Format( "#{RCLS_200731_48}", g_curDaibi2))

	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay >= 20260323 and curDay <= 20260329 then
		TreasureBox_BuyItem_CostText2:SetText( "#{RCLS_200731_130}" )
	elseif curDay >= 20260330 and curDay <= 20260405 then
		TreasureBox_BuyItem_CostText2:SetText( "#{RCLS_200731_134}" )
	else
		TreasureBox_BuyItem_CostText2:SetText( "#{RCLS_200731_200}" )
	end

	this:Show()
end	

--=========================================================
--关闭
--=========================================================
function TreasureBox_Close()
	if IsWindowShow("TreasureBox_MBuy") then
		CloseWindow("TreasureBox_MBuy", true)
	end
	if IsWindowShow("TreasureBox_Preview") then
		CloseWindow("TreasureBox_Preview", true)
	end
	if IsWindowShow("TreasureBox_AwardPreview") then
		CloseWindow("TreasureBox_AwardPreview", true)
	end
	if IsWindowShow("TreasureBox_Award") then
		CloseWindow("TreasureBox_Award", true)
	end
	if IsWindowShow("TreasureBox_Prize") then
		CloseWindow("TreasureBox_Prize", true)
	end
	this:Hide()
end

function TreasureBox_OnHiden()
	TreasureBox_Close()
end
--=========================================================
--刷新位置
--=========================================================
function TreasureBox_On_ResetPos()
	TreasureBox_FrameNULL:SetProperty("UnifiedPosition", g_TreasureBox_UnifiedPosition);
end

--===============================================
-- 设置共享位置信息
--===============================================
function TreasureBox_On_SetLastPos()
	local CurUIPos = Variable:GetVariable("TreasureBoxUIPos")
	if( CurUIPos ~= nil) then
	    TreasureBox_FrameNULL:SetProperty("UnifiedPosition", CurUIPos )
	end
end

function TreasureBox_Item_Click(nIndex)
	local ItemIndex = nIndex
	if ItemIndex < 1 or ItemIndex > g_MaxLibaoCount then
		return;
	end

	local curbuycnt = TreasureBox_GetLimitCount(nIndex)

	PushEvent( "UI_COMMAND", 88819002, g_curTBIndex, nIndex, curbuycnt )
	this:Show()
end

function TreasureBox_Buy_Click()
	local strNum = TreasureBox_BuyItem_NumText:GetText();
	if strNum == nil or strNum == "" then
		PushDebugMessage("输入不能为空")
		return
	end
	
	if(tonumber(strNum) > g_TreasureBox_ItemNumMax) then
		PushDebugMessage("输入超上限，请重新输入")
		TreasureBox_BuyItem_NumText:SetText(1)
		return;
	end;

	if tonumber(strNum) <= 0 then
		PushDebugMessage("请重新输入")
		TreasureBox_BuyItem_NumText:SetText(1)
		return;			
	end
	
	local ItemIndex = g_CurItemIndex
	if ItemIndex < 1 or ItemIndex > 4 then
		return;
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyLibao" )
		Set_XSCRIPT_ScriptID(888143)
		Set_XSCRIPT_Parameter(0,ItemIndex)
		Set_XSCRIPT_Parameter(1,tonumber(strNum))
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function TreasureBox_Help_Clicked()
	PushEvent("CCSHOP_HELP", 118)
end

function TreasureBox_Baodi_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenBaodiItem" )
		Set_XSCRIPT_ScriptID(888143)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function TreasureBox_Page_Clicked(index)
	if index == 1 then
		return
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 4 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 888143 )
			Set_XSCRIPT_Parameter(0,3)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	Variable:SetVariable("TreasureBoxUIPos", TreasureBox_FrameNULL:GetProperty("UnifiedPosition"), 1)
end

function TreasureBox_Reward_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenLiCheng" )
		Set_XSCRIPT_ScriptID( 888143 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--选中页签
function TreasureBox_ButtonPage(index)
	for i = 1, 4 do
		if index == i then
			TreasureBox_pagebuttonleft[i]:SetProperty("Selected", "True")
		else
			TreasureBox_pagebuttonleft[i]:SetProperty("Selected", "False")
		end
	end
end

--获取礼包已购买数
function TreasureBox_GetLimitCount(nIndex)
	if nIndex < 1 or nIndex > g_MaxLibaoCount then
		return -1
	end 	
	
	local MDData = nil
	for i = 1, table.getn(g_LibaoBuy_MD_List) do
		if nIndex > 2*(i-1) and nIndex <= 2*i then
			MDData = g_LibaoBuy_MD_List[i]
			break
		end
	end

	local ret = -1
	if MDData ~= nil then
		local temp = math.mod(nIndex-1, 2) --0,1
		if temp == 0 then
			ret = math.mod(MDData, 10000)
		elseif temp == 1 then
			ret = math.mod(math.floor(MDData/10000), 10000)
		end
	end
	
	return ret
end

function TreasureBox_MultiBuy( nIndex )
end

function TreasureBox_ItemShow()
	PushEvent( "UI_COMMAND", 88819005 )
	this:Show()
end

