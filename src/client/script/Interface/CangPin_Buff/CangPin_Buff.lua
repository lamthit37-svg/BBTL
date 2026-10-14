--CangPin_Buff
--!!!reloadscript =CangPin_Buff

local g_CangPin_Buff_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_InitList = 0

local g_MaxSetBarNum = 100

local g_BarList = {}

local g_CurRankType = 0

local g_ClassCount = 4
local g_SunShineBonusLevel = 6
local g_LimitLevel = 30

local g_BonuslevelName = {
	[0] = {"#{CPPH_20260417_34}", "#{CPPH_20260417_35}", "#{CPPH_20260417_36}", "#{CPPH_20260417_37}", "#{CPPH_20260417_38}", "#{CPPH_20260417_67}"},
	[1] = {"#{CPPH_20260417_39}", "#{CPPH_20260417_40}", "#{CPPH_20260417_41}", "#{CPPH_20260417_42}", "#{CPPH_20260417_43}", "#{CPPH_20260417_68}"}
}

local g_BuffMaxCount = 8
local g_BuffActionButtons = {}
local g_BuffText = {}
local g_BuffTakeButton = {}
local g_BuffNameText = {}

local g_LeftTakeTimes = 0

function CangPin_Buff_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function CangPin_Buff_OnLoad()
	g_CangPin_Buff_Frame_UnifiedPosition = CangPin_Buff_Frame:GetProperty("UnifiedPosition")
	
	g_BuffActionButtons[1] = CangPin_Buff_Item1
	g_BuffActionButtons[2] = CangPin_Buff_Item2
	g_BuffActionButtons[3] = CangPin_Buff_Item3
	g_BuffActionButtons[4] = CangPin_Buff_Item4
	g_BuffActionButtons[5] = CangPin_Buff_Item5
	g_BuffActionButtons[6] = CangPin_Buff_Item6
	g_BuffActionButtons[7] = CangPin_Buff_Item7
	g_BuffActionButtons[8] = CangPin_Buff_Item8
	
	g_BuffText[1] = CangPin_Buff_ItemPointText1
	g_BuffText[2] = CangPin_Buff_ItemPointText2
	g_BuffText[3] = CangPin_Buff_ItemPointText3
	g_BuffText[4] = CangPin_Buff_ItemPointText4
	g_BuffText[5] = CangPin_Buff_ItemPointText5
	g_BuffText[6] = CangPin_Buff_ItemPointText6
	g_BuffText[7] = CangPin_Buff_ItemPointText7
	g_BuffText[8] = CangPin_Buff_ItemPointText8
	
	g_BuffTakeButton[1] = CangPin_Buff_ItemButton1
	g_BuffTakeButton[2] = CangPin_Buff_ItemButton2
	g_BuffTakeButton[3] = CangPin_Buff_ItemButton3
	g_BuffTakeButton[4] = CangPin_Buff_ItemButton4
	g_BuffTakeButton[5] = CangPin_Buff_ItemButton5
	g_BuffTakeButton[6] = CangPin_Buff_ItemButton6
	g_BuffTakeButton[7] = CangPin_Buff_ItemButton7
	g_BuffTakeButton[8] = CangPin_Buff_ItemButton8
	
	g_BuffNameText[1] = CangPin_Buff_ItemName1
	g_BuffNameText[2] = CangPin_Buff_ItemName2
	g_BuffNameText[3] = CangPin_Buff_ItemName3
	g_BuffNameText[4] = CangPin_Buff_ItemName4
	g_BuffNameText[5] = CangPin_Buff_ItemName5
	g_BuffNameText[6] = CangPin_Buff_ItemName6
	g_BuffNameText[7] = CangPin_Buff_ItemName7
	g_BuffNameText[8] = CangPin_Buff_ItemName8

end

function CangPin_Buff_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88555401 then
		if not this:IsVisible() then
			g_LeftTakeTimes = Get_XParam_INT(0)
			local obj_id = Get_XParam_INT(1)
			this:Show()
			CangPin_Buff_Update()
			CangPin_Buff_BeginCareObj(obj_id)
		else
			g_LeftTakeTimes = Get_XParam_INT(0)
			local obj_id = Get_XParam_INT(1)
			this:Activate()
			CangPin_Buff_Update()
			CangPin_Buff_BeginCareObj(obj_id)
		end
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88555403 then
		if this:IsVisible() then
			g_LeftTakeTimes = Get_XParam_INT(0)
			CangPin_Buff_Update()
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_Buff_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
end

function CangPin_Buff_OnShow()
	
end

function CangPin_Buff_Update()
	local strTemp = ""

	local last_bonus = Lua_GetMissionData(3450)
	local last_rank_type = math.floor(last_bonus / 1000)
	local last_bonus_level = math.mod(last_bonus, 1000)
	
	if last_bonus == 0 then
		last_rank_type = 1
		last_bonus_level = g_SunShineBonusLevel
		
		strTemp = ScriptGlobal_Format("#{CPPH_20260417_33}", "#{CPPH_20260417_44}")
		CangPin_Buff_Text1:SetText(strTemp)
		strTemp = ScriptGlobal_Format("#{CPPH_20260417_46}", tostring(g_BonuslevelName[1][6]))
		CangPin_Buff_ItemTitle:SetText(strTemp)		
	else
		strTemp = ScriptGlobal_Format("#{CPPH_20260417_33}", tostring(g_BonuslevelName[last_rank_type][last_bonus_level]))
		CangPin_Buff_Text1:SetText(strTemp)
		strTemp = ScriptGlobal_Format("#{CPPH_20260417_46}", tostring(g_BonuslevelName[last_rank_type][last_bonus_level]))
		CangPin_Buff_ItemTitle:SetText(strTemp)
	end
	
	local col_value = 0
	for i = 1, g_ClassCount do
		local collect_val = DataPool:LuaFnGetCangPinClassCollectValue(i - 1)
		col_value = col_value + collect_val
	end
	
	strTemp = ScriptGlobal_Format("#{CPPH_20260417_45}", tostring(col_value))
	CangPin_Buff_Text2:SetText(strTemp)
	
	for i = 1, g_BuffMaxCount do
		g_BuffActionButtons[i]:SetProperty("Empty", "False")
		g_BuffActionButtons[i]:SetProperty("UseDefaultTooltip", "True")
		g_BuffText[i]:SetText("")
		
		local buff_id, need_value, buff_name, buff_tip, buff_icon = LuaFnGetCangPinRankBonusBuff(last_rank_type, last_bonus_level, i - 1)
		if tonumber(buff_id) ~= nil and tonumber(buff_id) > 0 then
			local strImage = GetIconFullName(tostring(buff_icon))
			g_BuffActionButtons[i]:SetProperty("NormalImage", strImage)
			g_BuffActionButtons[i]:SetProperty("HoverImage", strImage)
			g_BuffActionButtons[i]:SetToolTip(tostring(buff_tip))
			g_BuffNameText[i]:SetText(tostring(buff_name))
			
			strTemp = ScriptGlobal_Format("#{CPPH_20260417_47}", tostring(need_value))
			g_BuffText[i]:SetText(strTemp)
			
			if last_bonus == 0 then
			--	g_BuffTakeButton[i]:Disable()
			else
				if col_value >= need_value then
					g_BuffTakeButton[i]:Enable()
				else
				--	g_BuffTakeButton[i]:Disable()
				end
			end
		else
			g_BuffActionButtons[i]:SetProperty("NormalImage", "")
			g_BuffActionButtons[i]:SetProperty("HoverImage", "")
			g_BuffActionButtons[i]:SetToolTip("")
			g_BuffText[i]:SetText("")
			g_BuffNameText[i]:SetText("")
		--	g_BuffTakeButton[i]:Disable()
		end
	end
	
	if last_bonus == 0 then
		strTemp = ScriptGlobal_Format("#{CPPH_20260417_49}", "0")
	else
		strTemp = ScriptGlobal_Format("#{CPPH_20260417_49}", tostring(g_LeftTakeTimes))
	end
	CangPin_Buff_BottomText1:SetText(strTemp)

end

function CangPin_Buff_Update_UpdateList()

end

function CangPin_Buff_ItemButtonClicked(idx)
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CPPH_20260417_2}")
		return
	end
	
	local last_bonus = Lua_GetMissionData(3450)
	local last_rank_type = math.floor(last_bonus / 1000)
	local last_bonus_level = math.mod(last_bonus, 1000)
	if last_bonus == 0 then
		PushDebugMessage("#{CPPH_20260417_51}")
		return
	end
	
	local buff_id, need_value, buff_name, buff_tip, buff_icon = LuaFnGetCangPinRankBonusBuff(last_rank_type, last_bonus_level, idx - 1)
	if tonumber(buff_id) ~= nil and tonumber(buff_id) > 0 then

		local col_value = 0
		for i = 1, g_ClassCount do
			local collect_val = DataPool:LuaFnGetCangPinClassCollectValue(i - 1)
			col_value = col_value + collect_val
		end
		
		if col_value < need_value then
			PushDebugMessage("#{CPPH_20260417_52}")
			return
		end
	end
	
	if g_LeftTakeTimes == 0 then
		PushDebugMessage("#{CPPH_20260417_53}")
		return
	end
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TakeCangPinRankBuff")
		Set_XSCRIPT_ScriptID(885554)
		Set_XSCRIPT_Parameter(0, last_rank_type)
		Set_XSCRIPT_Parameter(1, last_bonus_level)
		Set_XSCRIPT_Parameter(2, idx - 1)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function CangPin_Buff_ShowAllBonus()
	LuaFnOpenCangPinRankAllBuff()
end

function CangPin_Buff_CloseClicked()
	this:Hide()
end

function CangPin_Buff_CleanUp()
	g_CurSet = -1
end

function CangPin_Buff_OnHidden()
	CangPin_Buff_CleanUp()
	m_ObjServerId = -1
end

--Care Obj
function CangPin_Buff_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function CangPin_Buff_Frame_On_ResetPos()
	if g_CangPin_Buff_Frame_UnifiedPosition ~= nil then
		CangPin_Buff_Frame:SetProperty("UnifiedPosition", g_CangPin_Buff_Frame_UnifiedPosition)
	end
end
