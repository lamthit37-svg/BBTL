--CangPin_ChangePinJie
--!!!reloadscript =CangPin_ChangePinJie

local g_CangPin_ChangePinJie_Frame_UnifiedPosition = ""
local m_ObjServerId = -1
local g_CurCangPinId = 0
local g_MaxStar = 9
local g_LimitLevel = 30
local g_MaxQualUpLevel = 4

function CangPin_ChangePinJie_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
--	this:RegisterEvent("MONEY_CHANGE_EX", false)
--	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
--	this:RegisterEvent("UPDATE_CANGPIN_COMMON_CHIP", false)
--	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
end

function CangPin_ChangePinJie_OnLoad()
	g_CangPin_ChangePinJie_Frame_UnifiedPosition = CangPin_ChangePinJie_Frame:GetProperty("UnifiedPosition")
end

function CangPin_ChangePinJie_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88555501 then
		g_CurCangPinId = Get_XParam_INT(0)
		local obj_id = Get_XParam_INT(1)
		if not this:IsVisible() then
			this:Show()
			CangPin_ChangePinJie_BeginCareObj(obj_id)
		else
			this:Activate()
			CangPin_ChangePinJie_BeginCareObj(obj_id)
		end
		CangPin_ChangePinJie_Update()
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_ChangePinJie_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" and this:IsVisible()  then
	--	CangPin_ChangePinJie_JiangPin_CurrentJiaoZi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	--	CangPin_ChangePinJie_JiangPin_CurrentlyMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
	--	CangPin_ChangePinJie_JiangPin_CurrentJiaoZi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	--	CangPin_ChangePinJie_JiangPin_CurrentlyMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "CANGPIN_UPDATE" and this:IsVisible() then
		CangPin_ChangePinJie_Update()
		return
	end
	
	if event == "UPDATE_CANGPIN_COMMON_CHIP" and this:IsVisible() then
	--	local nCommonChipCount = Player:LuaFnGetCangPinCommonChip()
	--	local strTemp = ScriptGlobal_Format("#{CPSJ_260112_32}", tostring(nCommonChipCount))
	--	CangPin_ChangePinJie_CommonCostNumText:SetText(tostring(strTemp))
	end
	
	if event == "UPDATE_YUANBAO" and this:IsVisible() then
	--	CangPin_ChangePinJie_JiangPin_SelfYuanBao:SetText(tostring(Player:GetData("YUANBAO")))
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		CangPin_ChangePinJie_Update()
		return
	end
end

function CangPin_ChangePinJie_Update()
	local strTemp = ""
	
	CangPin_ChangePinJie_CurrentCangPin_ShengPin:SetActionItem(-1)
	CangPin_ChangePinJie_NextCangPin_ShengPin:SetActionItem(-1)
	CangPin_ChangePinJie_ShengPin_CostItem:SetActionItem(-1)
	CangPin_ChangePinJie_CurrentLevel_ShengPin:SetText("")
	CangPin_ChangePinJie_NextLevel_ShengPin:SetText("")
	
	CangPin_ChangePinJie_ShengPin_CostNumBK:Hide()
	CangPin_ChangePinJie_ShengPin_CostNum:SetText("")
	
	if g_CurCangPinId == 0 then
		return
	end

	local theAction = EnumAction(g_CurCangPinId, "cangpin")
	if theAction:GetID() ~= 0 then
		CangPin_ChangePinJie_CurrentCangPin_ShengPin:SetActionItem(theAction:GetID())
	end
	
	local nUnLocked = DataPool:LuaFnGetCangPinData(g_CurCangPinId, "UnLocked")
	local nQualUpLevel = DataPool:LuaFnGetCangPinData(g_CurCangPinId, "QualUpLevel")		
	local set_id = DataPool:LuaFnGetCangPinData(g_CurCangPinId, "SetId")
	local newQualUpLevel = 0

	if nQualUpLevel == 0 then
		newQualUpLevel = 1
		CangPin_ChangePinJie_CurrentLevel_ShengPin:SetText("#{CPSJ_260112_175}")
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_176}", "1")
		CangPin_ChangePinJie_NextLevel_ShengPin:SetText(tostring(strTemp))
	elseif nQualUpLevel == g_MaxQualUpLevel then
		newQualUpLevel = nQualUpLevel
		CangPin_ChangePinJie_CurrentLevel_ShengPin:SetText("#{CPSJ_260112_177}")
		CangPin_ChangePinJie_NextLevel_ShengPin:SetText("#{CPSJ_260112_205}")
	else
		newQualUpLevel = nQualUpLevel + 1
		strTemp = ScriptGlobal_Format("#{CPSJ_260112_176}", tostring(nQualUpLevel))
		CangPin_ChangePinJie_CurrentLevel_ShengPin:SetText(tostring(strTemp))
		
		if newQualUpLevel == g_MaxQualUpLevel then
			CangPin_ChangePinJie_NextLevel_ShengPin:SetText("#{CPSJ_260112_177}")
		else
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_176}", tostring(newQualUpLevel))
			CangPin_ChangePinJie_NextLevel_ShengPin:SetText(tostring(strTemp))
		end
	end
	
	local theNextAction = EnumAction(g_CurCangPinId, "cangpin_qualup")
	if theNextAction:GetID() ~= 0 then
		CangPin_ChangePinJie_NextCangPin_ShengPin:SetActionItem(theNextAction:GetID())
	end
	
	if nQualUpLevel >= 0 and nQualUpLevel < g_MaxQualUpLevel then
		local need_item, need_item_count = LuaFnGetCangPinQualUpNeed(g_CurCangPinId, nQualUpLevel + 1)
		if tonumber(need_item) ~= nil then
			local theMaterialAction = DataPool:CreateActionItemForShow(need_item, 1)
			CangPin_ChangePinJie_ShengPin_CostItem:SetActionItem(theMaterialAction:GetID())
			local have_count = PlayerPackage:Lua_GetUnLockItemCount(need_item)
			CangPin_ChangePinJie_ShengPin_CostNum:SetText(tostring(have_count).."/"..tostring(need_item_count))
			CangPin_ChangePinJie_ShengPin_CostNumBK:Show()
		end
	end
end

function CangPin_ChangePinJie_CloseClicked()
	this:Hide()
end

function CangPin_ChangePinJie_CleanUp()
	CangPin_ChangePinJie_CurrentCangPin_ShengPin:SetActionItem(-1)
	CangPin_ChangePinJie_NextCangPin_ShengPin:SetActionItem(-1)
	CangPin_ChangePinJie_ShengPin_CostItem:SetActionItem(-1)
end

function CangPin_ChangePinJie_OnHidden()
	CangPin_ChangePinJie_CleanUp()
	g_CurCangPinId = 0
end

function CangPin_ChangePinJie_OnOK()
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	
	if g_CurCangPinId == 0 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CangPinQualUp")
		Set_XSCRIPT_ScriptID(885555)
		Set_XSCRIPT_Parameter(0, g_CurCangPinId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--Care Obj
function CangPin_ChangePinJie_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function CangPin_ChangePinJie_Frame_On_ResetPos()
	if g_CangPin_ChangePinJie_Frame_UnifiedPosition ~= nil then
		CangPin_ChangePinJie_Frame:SetProperty("UnifiedPosition", g_CangPin_ChangePinJie_Frame_UnifiedPosition)
	end
end
