-- !!!reloadscript =FC_FreeChoices
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local m_ItemList = 
{
	30008034, 30008034, 30008034, 30008034, 30008034,
}

local m_uiItem = {}

local m_bagIndex = -1

local m_selectIndex = 0
--预加载函数，可以而且只能在这里注册脚本关心的事件
function FC_FreeChoices_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FC_FreeChoices_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= FC_FreeChoices_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= FC_FreeChoices_Frame:GetProperty("UnifiedYPosition");
	
	for i = 1, table.getn(m_ItemList) do
		m_uiItem[i] = {}
		m_uiItem[i]["Item"] = _G["FC_FreeChoices_Item"..i]
		m_uiItem[i]["Name"] = _G["FC_FreeChoices_ItemInfo"..i.."_Text"]
		m_uiItem[i]["Select"] = _G["FC_FreeChoices_Item"..i.."_Object1Select"]
	end

	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FC_FreeChoices_ResetPos()
	FC_FreeChoices_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	FC_FreeChoices_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FC_FreeChoices_OnEvent(event)
	if( event == "UI_COMMAND" and (tonumber(arg0) == 820065001) ) then--
		-- PushDebugMessage("111111111111111111")
		local opType = Get_XParam_INT(0)
		if opType == 1 then
			m_selectIndex = 0
			m_bagIndex = Get_XParam_INT(1)
			if (this:IsVisible()) then
				FC_FreeChoices_Update()
				return
			end
			FC_FreeChoices_Show()
			FC_FreeChoices_Update()
		else
			FC_FreeChoices_Hide()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FC_FreeChoices_Hide()
	elseif event == "ADJEST_UI_POS" then
		FC_FreeChoices_ResetPos()
	end
end

--显示UI
function FC_FreeChoices_Show()
	FC_FreeChoices_ClearData()
	this:Show()
	
end
--隐藏UI
function FC_FreeChoices_Hide()
	FC_FreeChoices_ClearData()

	this:Hide()
end

--清除数据
function FC_FreeChoices_ClearData()
	m_selectIndex = 0
end
--更新
function FC_FreeChoices_Update()
	for i = 1, table.getn(m_ItemList) do
		-- PushDebugMessage(m_bagIndex.." " ..m_ItemList[i])
		local theAction1 = DataPool:CreateActionItemForShow(m_ItemList[i], 1) 
		if (theAction1:GetID() ~= 0) then
			m_uiItem[i].Item:SetActionItem(theAction1:GetID())  
			m_uiItem[i].Name:SetText(theAction1:GetName())  
		end 
	end
	FC_FreeChoices_UpdateSelect()
end
function FC_FreeChoices_UpdateSelect()
	for i = 1, table.getn(m_ItemList) do
		m_uiItem[i].Select:Hide()
	end
	if nil ~= m_uiItem[m_selectIndex] then
		m_uiItem[m_selectIndex].Select:Show()
	end
end
--##############点击事件##############
function FC_FreeChoices_CloseShop()
	FC_FreeChoices_Hide()
end
function FC_FreeChoices_ItemClicked(index)
	if index == m_selectIndex then
		return
	end
	m_selectIndex = index
	FC_FreeChoices_UpdateSelect()
end
function FC_FreeChoices_SelectClicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClientUseItem")
		Set_XSCRIPT_ScriptID(820065);
		Set_XSCRIPT_Parameter(0, m_bagIndex);
		Set_XSCRIPT_Parameter(1, m_selectIndex);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end
--####################################