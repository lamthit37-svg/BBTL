--!!!reloadscript =ZongMenSkill_Upstage

local g_ZongMenSkill_Upstage_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_LimitLevel = 5
local g_Need_Mondy = 1000000

local g_Level_Info = {
	"#{XWXT_230825_03}",
	"#{XWXT_230825_04}",
	"#{XWXT_230825_05}",
	"#{XWXT_230825_06}",
	"#{XWXT_230825_07}",
}

local g_Level_Name = {
	"#{XWXT_230825_08}",
	"#{XWXT_230825_09}",
	"#{XWXT_230825_10}",
	"#{XWXT_230825_11}",
	"#{XWXT_230825_12}",
}

function ZongMenSkill_Upstage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED", false)
	this:RegisterEvent("UNIT_MONEY", false)
	this:RegisterEvent("MONEYJZ_CHANGE", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("REFRESH_EQUIP", false)
end

function ZongMenSkill_Upstage_OnLoad()
	g_ZongMenSkill_Upstage_Frame_UnifiedPosition = ZongMenSkill_Upstage_Frame:GetProperty("UnifiedPosition")
end

function ZongMenSkill_Upstage_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88110001 then
		if not this:IsVisible() then
			ZongMenSkill_Upstage_CleanUp()
			this:Show()
			ZongMenSkill_Upstage_Update()
			ZongMenSkill_Upstage_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88110002 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end	
	
	if event == "UI_COMMAND" and tonumber(arg0) == 88110003 then
		Player:LuaFnStartCanWu(Get_XParam_INT(0))
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ZongMenSkill_Upstage_Frame_On_ResetPos()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible() then
		this:Hide()
		return
	end
	
	if event == "UNIT_MONEY" or event == "MONEYJZ_CHANGE" then
		if this:IsVisible() then
			ZongMenSkill_Upstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
			ZongMenSkill_Upstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		end
		return
	end
	
	if event == "REFRESH_EQUIP" and this:IsVisible() then
		ZongMenSkill_Upstage_Update()
	end
end

function ZongMenSkill_Upstage_Update()
	
	local strTemp = ""
	ZongMenSkill_Upstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ZongMenSkill_Upstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	ZongMenSkill_Upstage_Item:SetActionItem(-1)
	ZongMenSkill_Upstage_Currency1Num:SetProperty("MoneyNumber", "0")
	
	ZongMenSkill_Upstage_Before:SetText("")
	ZongMenSkill_Upstage_After:SetText("")
	
	ZongMenSkill_Upstage_AttrBefore1:SetText("")
	ZongMenSkill_Upstage_AttrAfter1:SetText("")
	
	ZongMenSkill_Upstage_OK:Disable()
	
	if DataPool:LuaFnIsEquipZMXW() == 1 then
		local ActionEquip = EnumAction(23, "equip")
		ZongMenSkill_Upstage_Item:SetActionItem(ActionEquip:GetID())
		
		local item_table_index = DataPool:LuaFnGetEquipItemTableIndex(23)

		if tonumber(item_table_index) ~= nil and tonumber(item_table_index) > 0 then
			local equip_level = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "LEVEL")
			local need_money = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "NEEDMONEY")
			ZongMenSkill_Upstage_Currency1Num:SetProperty("MoneyNumber", tostring(need_money))
			
			local strTemp = ScriptGlobal_Format("#{XWXT_230825_106}" ,tostring(g_Level_Name[equip_level]))
			ZongMenSkill_Upstage_Before:SetText("#{XWXT_230825_105}"..strTemp)
			
			local short_skill_desc = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "SHORTDESC")
			ZongMenSkill_Upstage_AttrBefore1:SetText(tostring(g_Level_Info[equip_level]).."#r"..short_skill_desc)
			
			if tonumber(equip_level) == 5 then
				ZongMenSkill_Upstage_After:SetText("#{XWXT_230825_108}")
			else
				strTemp = ScriptGlobal_Format("#{XWXT_230825_106}" ,tostring(g_Level_Name[equip_level + 1]))
				ZongMenSkill_Upstage_After:SetText("#{XWXT_230825_107}"..strTemp)
				
				local new_equip = DataPool:LuaFnGetZMXWInfo(tonumber(item_table_index), "NEW_XW")
				short_skill_desc = DataPool:LuaFnGetZMXWInfo(tonumber(new_equip), "SHORTDESC")
				ZongMenSkill_Upstage_AttrAfter1:SetText(tostring(g_Level_Info[equip_level + 1]).."#r"..short_skill_desc)
			end
		end
		
		
		ZongMenSkill_Upstage_OK:Enable()
	end	
	
end

function ZongMenSkill_Upstage_CloseClicked()
	this:Hide()
end

function ZongMenSkill_Upstage_CleanUp()
	ZongMenSkill_Upstage_Currency1Num:SetProperty("MoneyNumber", "0")
	ZongMenSkill_Upstage_Currency2Num:SetProperty("MoneyNumber", "0")
	ZongMenSkill_Upstage_Currency3Num:SetProperty("MoneyNumber", "0")	
	ZongMenSkill_Upstage_Item:SetActionItem(-1)
end

function ZongMenSkill_Upstage_OnHidden()
	ZongMenSkill_Upstage_CleanUp()
	m_ObjServerId = -1
end

function ZongMenSkill_Upstage_OK_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(881100)
		Set_XSCRIPT_Function_Name("StartCanWu")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ZongMenSkill_Upstage_HelpClicked()

end

--Care Obj
function ZongMenSkill_Upstage_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ZongMenSkill_Upstage_Frame_On_ResetPos()
	if g_ZongMenSkill_Upstage_Frame_UnifiedPosition ~= nil then
		ZongMenSkill_Upstage_Frame:SetProperty("UnifiedPosition", g_ZongMenSkill_Upstage_Frame_UnifiedPosition)
	end
end
