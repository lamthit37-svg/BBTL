--TreasureBox_Award
local g_TreasureBox_Award_UnifiedPosition;

local TreasureBox_Award_BuyItem_Num = {}
local g_TreasureBox_Award_ShowItemInfo = {}
local TreasureBox_Award_ActionButton = {}
local TreasureBox_Award_ItemName = {}
local TreasureBox_Award_ItemButton = {}
local TreasureBox_Award_ItemText1 = {}
local TreasureBox_Award_Num = {}
local TreasureBox_Award_Cost = {}
local TreasureBox_Award_Mark = {}
local TreasureBox_Award_Mark2 = {}
local TreasureBox_Award_ScrollBar = {}

local g_curTBIndex = 0
local g_CurItemIndex = 0
local g_CurLibaoUseCnt = 0
local g_BaodiFlag = 0
local g_BaodiReward = 0

local g_TreasureBox_Award_LiBaoUseCount = 5

function TreasureBox_Award_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("UPDATE_YUANBAO",false)
end

function TreasureBox_Award_OnLoad()	
	g_TreasureBox_Award_UnifiedPosition = TreasureBox_Award_Frame:GetProperty("UnifiedPosition")
	
end

function TreasureBox_Award_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88814303 ) then
		local operator = Get_XParam_INT(0)
		if operator == 1 then
			g_CurLibaoUseCnt = Get_XParam_INT(1)
			g_BaodiReward = Get_XParam_INT(2)
			g_curTBIndex = Get_XParam_INT(3)
			
			TreasureBox_Award_Update()

		elseif operator == 2 then
			if this:IsVisible() then
				g_CurLibaoUseCnt = Get_XParam_INT(1)
				g_BaodiReward = Get_XParam_INT(2)
				g_curTBIndex = Get_XParam_INT(3)

				TreasureBox_Award_Update()
			end
		end

	elseif (event == "ADJEST_UI_POS" ) then
		TreasureBox_Award_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TreasureBox_Award_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--更新界面
--=========================================================
function TreasureBox_Award_Update()

	for i = 1, table.getn(TreasureBox_Award_ActionButton) do
		if TreasureBox_Award_ActionButton[i] ~= nil then
			TreasureBox_Award_ActionButton[i]:SetActionItem(-1)
			TreasureBox_Award_ActionButton[i] = nil
		end
	end
		
	TreasureBox_Award_List:Clear()

	local nCount = GetLashouShopBaodiCount(g_curTBIndex)

	local j = 1
	for i = 1, nCount do
		local bar1 = TreasureBox_Award_List:AddChild("TreasureBox_Award_Item")
		if not bar1 then
    		break
  		end		
		local nLibaoId, nLibaoUseCnt, nNotGetItemId, nGiftShowId1, nGiftNum1, nGiftShowId2, nGiftNum2 = GetLashouShopBaodiItem(g_curTBIndex, i)
		local oActionBtn = bar1:GetSubItem("TreasureBox_Award_GetCondition_Icon1");
		if nGiftShowId1 > 0 and nGiftNum1 > 0 then
			if oActionBtn ~= nil then
				local theAction = DataPool:CreateActionItemForShow(nGiftShowId1, nGiftNum1)
				oActionBtn:Show()
				oActionBtn:SetActionItem( theAction:GetID() );
				TreasureBox_Award_ActionButton[j] = oActionBtn
				j = j+1
			end
		else
			oActionBtn:Hide()
		end 
		
		--local oActionBtn = bar1:GetSubItem("TreasureBox_Award_GetCondition_Icon2");
		--if nGiftShowId2 > 0 and nGiftNum2 > 0 then
		--	if oActionBtn ~= nil then
		--		local theAction = DataPool:CreateActionItemForShow(nGiftShowId2, nGiftNum2)
		--		oActionBtn:Show()
		--		oActionBtn:SetActionItem( theAction:GetID() );
		--		TreasureBox_Award_ActionButton[j] = oActionBtn
		--		j = j+1
		--	end
		--else
		--	oActionBtn:Hide()
		--end 

		local LibaoName = DataPool:Lua_GetItemNameByIndex(nLibaoId)
		local NotGetItemName = DataPool:Lua_GetItemNameByIndex(nNotGetItemId)

		if g_CurLibaoUseCnt < nLibaoUseCnt then
			if i == 1 then
				bar1:GetSubItem("TreasureBox_Award_GetCondition"):SetText( ScriptGlobal_Format( "#{RCLS_200731_186}", g_CurLibaoUseCnt ) )
			elseif i == 2 then
				bar1:GetSubItem("TreasureBox_Award_GetCondition"):SetText( ScriptGlobal_Format( "#{RCLS_200731_187}", g_CurLibaoUseCnt ) )
			elseif i == 3 then
				bar1:GetSubItem("TreasureBox_Award_GetCondition"):SetText( ScriptGlobal_Format( "#{RCLS_200731_188}", g_CurLibaoUseCnt ) )
			elseif i == 4 then
				bar1:GetSubItem("TreasureBox_Award_GetCondition"):SetText( ScriptGlobal_Format( "#{RCLS_200731_189}", g_CurLibaoUseCnt ) )
			elseif i == 5 then
				bar1:GetSubItem("TreasureBox_Award_GetCondition"):SetText( ScriptGlobal_Format( "#{RCLS_200731_190}", g_CurLibaoUseCnt ) )
			end
		else
			bar1:GetSubItem("TreasureBox_Award_GetCondition"):SetText( "#{RCLS_200731_191}" )
		end
				
		--领取按钮
		local isGetReward = Lua_GetDataByBinary( g_BaodiReward, i-1 )
		local oButton = bar1:GetSubItem("TreasureBox_Award_GetCondition_Btn")
		if oButton ~= nil then
			oButton:SetEvent( "Clicked", string.format("TreasureBox_Award_Clicked(%d)",i) )
		end
		
		if isGetReward == 1 then
			oButton:Hide()

			bar1:GetSubItem("TreasureBox_Award_GetCondition_BtnImage"):Show()
			bar1:GetSubItem("TreasureBox_Award_GetCondition_BtnImage2"):Hide()
		else
			oButton:Show()
				oButton:Enable()
				bar1:GetSubItem("TreasureBox_Award_GetCondition_BtnImage"):Hide()
				bar1:GetSubItem("TreasureBox_Award_GetCondition_BtnImage2"):Hide()
			
		end
	end

	this:Show()
	this:Activate()
end	

--=========================================================
--商店说明
--=========================================================
function TreasureBox_Award_Help_Clicked()
	PushEvent("CCSHOP_HELP", 118)
end

--=========================================================
--关闭
--=========================================================
function TreasureBox_Award_Close()
	for i = 1, table.getn(TreasureBox_Award_ActionButton) do
		if TreasureBox_Award_ActionButton[i] ~= nil then
			TreasureBox_Award_ActionButton[i]:SetActionItem(-1)
			TreasureBox_Award_ActionButton[i] = nil
		end
	end
	
	TreasureBox_Award_List:Clear()
	
	this:Hide()
end

function TreasureBox_Award_OnHiden()
	TreasureBox_Award_Close()
end

--=========================================================
--刷新位置
--=========================================================
function TreasureBox_Award_On_ResetPos()
	TreasureBox_Award_Frame:SetProperty("UnifiedPosition", g_TreasureBox_Award_UnifiedPosition);
end


function TreasureBox_Award_Clicked(nIndex)
	local nCount = GetLashouShopBaodiCount(g_curTBIndex)
	if nIndex < 1 or nIndex > nCount then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetBaodiReward" )
		Set_XSCRIPT_ScriptID(888143)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

