--CangPin_BuffTuJian
--!!!reloadscript =CangPin_BuffTuJian

local g_CangPin_BuffTuJian_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_InitList = 0

local g_BarList = {}

local g_SunShineBonusLevel = 6
local g_LimitLevel = 60

local g_BonuslevelName = {
	[0] = {"#{CPPH_20260417_34}", "#{CPPH_20260417_35}", "#{CPPH_20260417_36}", "#{CPPH_20260417_37}", "#{CPPH_20260417_38}", "#{CPPH_20260417_67}"},
	[1] = {"#{CPPH_20260417_39}", "#{CPPH_20260417_40}", "#{CPPH_20260417_41}", "#{CPPH_20260417_42}", "#{CPPH_20260417_43}", "#{CPPH_20260417_68}"}
}

local g_BuffMaxCount = 8
local g_BuffActionButtons = {}
local g_BuffText = {}
local g_BuffNameText = {}

local g_CurRankType = 0
local g_CurBonusLevel = 1

function CangPin_BuffTuJian_PreLoad()
	this:RegisterEvent("OPEN_CANGPIN_RANK_ALL_BUFF", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function CangPin_BuffTuJian_OnLoad()
	g_CangPin_BuffTuJian_Frame_UnifiedPosition = CangPin_BuffTuJian_Frame:GetProperty("UnifiedPosition")
	
	g_BuffActionButtons[1] = CangPin_BuffTuJian_Item1
	g_BuffActionButtons[2] = CangPin_BuffTuJian_Item2
	g_BuffActionButtons[3] = CangPin_BuffTuJian_Item3
	g_BuffActionButtons[4] = CangPin_BuffTuJian_Item4
	g_BuffActionButtons[5] = CangPin_BuffTuJian_Item5
	g_BuffActionButtons[6] = CangPin_BuffTuJian_Item6
	g_BuffActionButtons[7] = CangPin_BuffTuJian_Item7
	g_BuffActionButtons[8] = CangPin_BuffTuJian_Item8
	
	g_BuffText[1] = CangPin_BuffTuJian_ItemPointText1
	g_BuffText[2] = CangPin_BuffTuJian_ItemPointText2
	g_BuffText[3] = CangPin_BuffTuJian_ItemPointText3
	g_BuffText[4] = CangPin_BuffTuJian_ItemPointText4
	g_BuffText[5] = CangPin_BuffTuJian_ItemPointText5
	g_BuffText[6] = CangPin_BuffTuJian_ItemPointText6
	g_BuffText[7] = CangPin_BuffTuJian_ItemPointText7
	g_BuffText[8] = CangPin_BuffTuJian_ItemPointText8
	
	g_BuffNameText[1] = CangPin_BuffTuJian_ItemName1
	g_BuffNameText[2] = CangPin_BuffTuJian_ItemName2
	g_BuffNameText[3] = CangPin_BuffTuJian_ItemName3
	g_BuffNameText[4] = CangPin_BuffTuJian_ItemName4
	g_BuffNameText[5] = CangPin_BuffTuJian_ItemName5
	g_BuffNameText[6] = CangPin_BuffTuJian_ItemName6
	g_BuffNameText[7] = CangPin_BuffTuJian_ItemName7
	g_BuffNameText[8] = CangPin_BuffTuJian_ItemName8
end

function CangPin_BuffTuJian_OnEvent(event)

	if event == "OPEN_CANGPIN_RANK_ALL_BUFF" then
		if not this:IsVisible() then
			this:Show()
			CangPin_BuffTuJian_Update()
		else
			this:Activate()
			CangPin_BuffTuJian_Update()
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_BuffTuJian_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
end

function CangPin_BuffTuJian_OnShow()
	
end

function CangPin_BuffTuJian_Update()
	local strTemp = ""
	
	if g_CurRankType ~= 0 and g_CurRankType ~= 1 then
		g_CurRankType = 0
	end
	
	if g_CurBonusLevel < 1 or g_CurBonusLevel > 6 then
		g_CurBonusLevel = 1
	end
	
	if g_CurRankType == 0 and g_CurBonusLevel == 1 then
		CangPin_BuffTuJian_UpPage:Disable()
	else
		CangPin_BuffTuJian_UpPage:Enable()
	end
	
	if g_CurRankType == 1 and g_CurBonusLevel == 6 then
		CangPin_BuffTuJian_DownPage:Disable()
	else
		CangPin_BuffTuJian_DownPage:Enable()
	end
	
	local cur_page = g_CurRankType * 6 + g_CurBonusLevel
	CangPin_BuffTuJian_CurrentlyPage:SetText(tostring(cur_page))
	
	strTemp = ScriptGlobal_Format("#{CPPH_20260417_61}", tostring(g_BonuslevelName[g_CurRankType][g_CurBonusLevel]))
	CangPin_BuffTuJian_ItemTitle:SetText(strTemp)
	
	for i = 1, g_BuffMaxCount do
		g_BuffActionButtons[i]:SetProperty("Empty", "False")
		g_BuffActionButtons[i]:SetProperty("UseDefaultTooltip", "True")
		g_BuffText[i]:SetText("")
		
		local buff_id, need_value, buff_name, buff_tip, buff_icon = LuaFnGetCangPinRankBonusBuff(g_CurRankType, g_CurBonusLevel, i - 1)
		if tonumber(buff_id) ~= nil and tonumber(buff_id) > 0 then
			local strImage = GetIconFullName(tostring(buff_icon))
			g_BuffActionButtons[i]:SetProperty("NormalImage", strImage)
			g_BuffActionButtons[i]:SetProperty("HoverImage", strImage)
			g_BuffActionButtons[i]:SetToolTip(tostring(buff_tip))
			g_BuffNameText[i]:SetText(tostring(buff_name))
			strTemp = ScriptGlobal_Format("#{CPPH_20260417_47}", tostring(need_value))
			g_BuffText[i]:SetText(strTemp)
		end
	end
end

function CangPin_BuffTuJian_PageUp()
	if g_CurRankType == 0 and g_CurBonusLevel == 1 then
		return
	elseif g_CurRankType == 1 and g_CurBonusLevel == 1 then
		g_CurRankType = 0
		g_CurBonusLevel = 6
	else
		g_CurBonusLevel = g_CurBonusLevel - 1
	end
	CangPin_BuffTuJian_Update()
end

function CangPin_BuffTuJian_PageDown()
	if g_CurRankType == 1 and g_CurBonusLevel == 6 then
		return
	elseif g_CurRankType == 0 and g_CurBonusLevel == 6 then
		g_CurRankType = 1
		g_CurBonusLevel = 1
	else
		g_CurBonusLevel = g_CurBonusLevel + 1
	end
	CangPin_BuffTuJian_Update()
end

function CangPin_BuffTuJian_CloseClicked()
	this:Hide()
end

function CangPin_BuffTuJian_CleanUp()
	g_CurSet = -1
end

function CangPin_BuffTuJian_OnHidden()
	CangPin_BuffTuJian_CleanUp()
	m_ObjServerId = -1
end

--Care Obj
function CangPin_BuffTuJian_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function CangPin_BuffTuJian_Frame_On_ResetPos()
	if g_CangPin_BuffTuJian_Frame_UnifiedPosition ~= nil then
		CangPin_BuffTuJian_Frame:SetProperty("UnifiedPosition", g_CangPin_BuffTuJian_Frame_UnifiedPosition)
	end
end
