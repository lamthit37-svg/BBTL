--2022Q3新天外服务器进度活动
--二选一界面

local g_Frame_UnifiedPosition = nil

local g_Index = 1
local g_SelectIndex = 0

local g_Prize = 
{
	[2] = { id1 = 39923985, id2 = 39923986, },
	[5] = { id1 = 39923987, id2 = 39923988, },
	[7] = { id1 = 39923989, id2 = 39923990, },
}

--=========
-- PreLoad()
--=========
function ThreeCity_fuwuqijindu_PickOne_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ThreeCity_fuwuqijindu_PickOne_OnLoad()
	g_Frame_UnifiedPosition = ThreeCity_fuwuqijindu_PickOne_Frame_BK:GetProperty("UnifiedPosition")
end

--=========
-- On_ResetPos()
--=========
function ThreeCity_fuwuqijindu_PickOne_On_ResetPos()
	ThreeCity_fuwuqijindu_PickOne_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- OnEvent(event)
--=========
function ThreeCity_fuwuqijindu_PickOne_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 88879602) then
		local flag = tonumber(Get_XParam_INT(0))
		if flag == 1 then--关界面再开界面
			if this:IsVisible() then
				ThreeCity_fuwuqijindu_PickOne_Close()
			end
			g_Index = tonumber(Get_XParam_INT(1))
			if g_Prize[g_Index] ~= nil then
				this:Show()
				g_SelectIndex = 0
				ThreeCity_fuwuqijindu_PickOne_Open()
			end
		elseif flag == 2 then-- 关界面
			if this:IsVisible() then
				ThreeCity_fuwuqijindu_PickOne_Close()
			end
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ThreeCity_fuwuqijindu_PickOne_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ThreeCity_fuwuqijindu_PickOne_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ThreeCity_fuwuqijindu_PickOne_Close()
	end	
end

--=========
-- Open()
--=========
function ThreeCity_fuwuqijindu_PickOne_Open()
	local tPrize = g_Prize[g_Index]
	if tPrize == nil then
		return
	end	
	local theAction1 = DataPool:CreateActionItemForShow(tPrize.id1, 1) 
	if (theAction1:GetID() ~= 0) then
		ThreeCity_fuwuqijindu_PickOne_Item1:SetActionItem(theAction1:GetID()) 
		local szItemName = DataPool:Lua_GetItemNameByIndex(tPrize.id1)
		ThreeCity_fuwuqijindu_PickOne_Item1_Name:SetText("#L"..szItemName)
	end 
	local theAction2 = DataPool:CreateActionItemForShow(tPrize.id2, 1) 
	if (theAction2:GetID() ~= 0) then
		ThreeCity_fuwuqijindu_PickOne_Item2:SetActionItem(theAction2:GetID())  
		local szItemName = DataPool:Lua_GetItemNameByIndex(tPrize.id2)
		ThreeCity_fuwuqijindu_PickOne_Item2_Name:SetText("#L"..szItemName)
	end
	ThreeCity_fuwuqijindu_PickOne_ShowChoose()
end

--=========
-- OnHidden()
--=========
function ThreeCity_fuwuqijindu_PickOne_CleanUp()
	g_Index = 1
	g_SelectIndex = 0
end

--=========
-- Close()
--=========
function ThreeCity_fuwuqijindu_PickOne_Close()
	ThreeCity_fuwuqijindu_PickOne_CleanUp()
	this:Hide()
end

--=========
-- 显示选中状态
--=========
function ThreeCity_fuwuqijindu_PickOne_ShowChoose()
	if g_SelectIndex == 1 then
		ThreeCity_fuwuqijindu_PickOne_Item1_Mask:Show()
		ThreeCity_fuwuqijindu_PickOne_Item2_Mask:Hide()
	elseif g_SelectIndex == 2 then
		ThreeCity_fuwuqijindu_PickOne_Item1_Mask:Hide()
		ThreeCity_fuwuqijindu_PickOne_Item2_Mask:Show()
	else
		ThreeCity_fuwuqijindu_PickOne_Item1_Mask:Hide()
		ThreeCity_fuwuqijindu_PickOne_Item2_Mask:Hide()
	end
end

--=========
-- 选中奖励
--=========
function ThreeCity_fuwuqijindu_PickOne_Choose(nIndex)
	g_SelectIndex = nIndex
	ThreeCity_fuwuqijindu_PickOne_ShowChoose()
end

--=========
-- 领取
--=========
function ThreeCity_fuwuqijindu_PickOne_GetClick()
	if g_SelectIndex == nil or g_SelectIndex <= 0 then
		PushDebugMessage("#{TWFW_220802_31}")
	end
	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnPrize")
    Set_XSCRIPT_ScriptID(888796)
    Set_XSCRIPT_Parameter(0, g_Index)
		Set_XSCRIPT_Parameter(1, g_SelectIndex)
    Set_XSCRIPT_ParamCount(2)
  Send_XSCRIPT()
end
