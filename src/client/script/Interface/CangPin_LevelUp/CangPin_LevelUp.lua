--CangPin_LevelUp
--!!!reloadscript =CangPin_LevelUp

local g_CangPin_LevelUp_Frame_UnifiedPosition = ""
local m_ObjServerId = -1
local g_CurCangPinId = 0
local g_MaxStar = 9
local g_LimitLevel = 30
local g_HideCommon = 1

local g_StarImg = {
	"set:CangPin image:CangPin_Level1",
	"set:CangPin image:CangPin_Level2",
	"set:CangPin image:CangPin_Level3",
	"set:CangPin image:CangPin_Level4",
	"set:CangPin image:CangPin_Level5",
	"set:CangPin image:CangPin_Level6",
	"set:CangPin image:CangPin_Level7",
	"set:CangPin image:CangPin_Level8",
	"set:CangPin image:CangPin_Level9",
}

function CangPin_LevelUp_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("OPEN_CANGPIN_LEVELUP", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
	this:RegisterEvent("UPDATE_CANGPIN_COMMON_CHIP", false)
end

function CangPin_LevelUp_OnLoad()
	g_CangPin_LevelUp_Frame_UnifiedPosition = CangPin_LevelUp_Frame:GetProperty("UnifiedPosition")
end

function CangPin_LevelUp_OnEvent(event)

	if event == "OPEN_CANGPIN_LEVELUP" then
		g_CurCangPinId = tonumber(arg0)
		if not this:IsVisible() then
			this:Show()
		else
			this:Activate()
		end
		CangPin_LevelUp_Update()
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_LevelUp_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" and this:IsVisible()  then
		CangPin_LevelUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		CangPin_LevelUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		CangPin_LevelUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		CangPin_LevelUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "CANGPIN_UPDATE" and this:IsVisible() then
		if arg0 == "starup" then
			if g_CurCangPinId == tonumber(arg1) then
				CangPin_LevelUp_Update()
			end
		end
		return
	end
	
	if event == "UPDATE_CANGPIN_COMMON_CHIP" and this:IsVisible() then
		local nCommonChipCount = Player:LuaFnGetCangPinCommonChip()
		local strTemp = ScriptGlobal_Format("#{CPSJ_260112_32}", tostring(nCommonChipCount))
		CangPin_LevelUp_CommonCostNumText:SetText(tostring(strTemp))
	end
end

function CangPin_LevelUp_Update()
	
	local strTemp = ""
	
	CangPin_LevelUp_CurrentLevel:SetText("")
	CangPin_LevelUp_NextLevel:SetText("")
	CangPin_LevelUp_CurrentShuXing:SetText("")
	CangPin_LevelUp_NextShuXing:SetText("")
	CangPin_LevelUp_CostNum:SetText("")
	
	CangPin_LevelUp_CurrentCangPin:SetActionItem(-1)
	CangPin_LevelUp_Cost:SetActionItem(-1)
	
	CangPin_LevelUp_Money:SetProperty("MoneyNumber", "0")
	CangPin_LevelUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	CangPin_LevelUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	
	CangPin_LevelUp_CommonCostBtn:Disable()
	
	local nCommonChipCount = Player:LuaFnGetCangPinCommonChip()
	strTemp = ScriptGlobal_Format("#{CPSJ_260112_32}", tostring(nCommonChipCount))
	CangPin_LevelUp_CommonCostNumText:SetText(tostring(strTemp))

	if g_CurCangPinId == 0 then
		return
	end

	local theAction = EnumAction(g_CurCangPinId, "cangpin")
	if theAction:GetID() ~= 0 then
		CangPin_LevelUp_CurrentCangPin:SetActionItem(theAction:GetID())
	end
	
	local theChipAction = EnumAction(g_CurCangPinId, "cangpinchip")
	if theChipAction:GetID() ~= 0 then
		CangPin_LevelUp_Cost:SetActionItem(theChipAction:GetID())
	end
	
	local nStar = DataPool:LuaFnGetCangPinData(g_CurCangPinId, "Star")
	strTemp = ScriptGlobal_Format("#{CPSJ_260112_22}", tostring(nStar))
	CangPin_LevelUp_CurrentLevel:SetText(tostring(strTemp))
	
	CangPin_LevelUp_CurrentLevel_LevelNum:SetProperty("Image", tostring(g_StarImg[nStar]))
	
	local nQualUpLevel = DataPool:LuaFnGetCangPinData(g_CurCangPinId, "QualUpLevel")	
	local strAttr = SuperTooltips:LuaFnGetCangPinAttr(g_CurCangPinId, nStar, nQualUpLevel)
	CangPin_LevelUp_CurrentShuXing:SetText(strAttr)
	
	CangPin_LevelUp_NextShuXing:SetText("")
	CangPin_LevelUp_NextCangPin:SetActionItem(-1)
	if nStar < g_MaxStar then
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_22}", tostring(nStar + 1))
		CangPin_LevelUp_NextLevel:SetText(tostring(strTemp))
		
		local strNextAttr = SuperTooltips:LuaFnGetCangPinAttr(g_CurCangPinId, nStar + 1, nQualUpLevel)
		CangPin_LevelUp_NextShuXing:SetText(strNextAttr)
		
		CangPin_LevelUp_NextLevel_LevelNum:Show()
		CangPin_LevelUp_NextLevel_LevelNum:SetProperty("Image", tostring(g_StarImg[nStar + 1]))
		
		local theNextAction = EnumAction(g_CurCangPinId, "cangpin_nextlevel")
		if theNextAction:GetID() ~= 0 then
			CangPin_LevelUp_NextCangPin:SetActionItem(theNextAction:GetID())
		end
	else
		CangPin_LevelUp_NextLevel_LevelNum:Hide()
	end
	
	local need_money, need_count, can_use_common = DataPool:LuaFnGetCangPinStarInfo(g_CurCangPinId, nStar, "Need")
	CangPin_LevelUp_Money:SetProperty("MoneyNumber", tostring(need_money))
	
	local nChipCount = DataPool:LuaFnGetCangPinData(g_CurCangPinId, "ChipCount")
	strTemp = ScriptGlobal_Format("#{CPSJ_260112_26}", tostring(nChipCount), tostring(need_count))
	CangPin_LevelUp_CostNum:SetText(strTemp)
	
	if can_use_common == 1 and g_HideCommon == 0 then
		CangPin_LevelUp_CommonCostBtn:Enable()
	end
	
	if g_HideCommon == 1 then
		CangPin_LevelUp_CommonCostBK:Hide()
	end
end

function CangPin_LevelUp_CloseClicked()
	this:Hide()
end

function CangPin_LevelUp_CleanUp()
	CangPin_LevelUp_Money:SetProperty("MoneyNumber", "0")
	CangPin_LevelUp_SelfJiaozi:SetProperty("MoneyNumber", "0")
	CangPin_LevelUp_SelfMoney:SetProperty("MoneyNumber", "0")
	CangPin_LevelUp_CurrentCangPin:SetActionItem(-1)
	CangPin_LevelUp_Cost:SetActionItem(-1)
	CangPin_LevelUp_NextCangPin:SetActionItem(-1)
	
	CangPin_LevelUp_CurrentLevel:SetText("")
	CangPin_LevelUp_NextLevel:SetText("")
	CangPin_LevelUp_CurrentShuXing:SetText("")
	CangPin_LevelUp_NextShuXing:SetText("")
	CangPin_LevelUp_CostNum:SetText("")
	CangPin_LevelUp_CommonCostNumText:SetText("")
end

function CangPin_LevelUp_OnHidden()
	CangPin_LevelUp_CleanUp()
	m_ObjServerId = -1
	g_CurCangPinId = 0
end

function CangPin_LevelUp_OnOK()
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	
	if g_CurCangPinId == 0 then
		return
	end

	local nStar = DataPool:LuaFnGetCangPinData(g_CurCangPinId, "Star")
	if nStar >= g_MaxStar then
		PushDebugMessage("#{CPSJ_260112_37}")
		return
	end
	
	local use_common = 0
	if g_HideCommon == 0 then
		use_common = CangPin_LevelUp_CommonCostBtn:GetCheck()
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CangPinStarUp")
		Set_XSCRIPT_ScriptID(885555)
		Set_XSCRIPT_Parameter(0, g_CurCangPinId)
		Set_XSCRIPT_Parameter(1, use_common)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--Care Obj
function CangPin_LevelUp_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function CangPin_LevelUp_Frame_On_ResetPos()
	if g_CangPin_LevelUp_Frame_UnifiedPosition ~= nil then
		CangPin_LevelUp_Frame:SetProperty("UnifiedPosition", g_CangPin_LevelUp_Frame_UnifiedPosition)
	end
end
