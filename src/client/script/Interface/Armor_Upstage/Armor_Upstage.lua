--Armor_Upstage
--!!!reloadscript =Armor_Upstage

local g_Armor_Upstage_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Cur_Sel = 1

local g_UA_ExAttr_Before = {}
local g_UA_ExAttr_After = {}
local g_UA_Button = {}

local g_UA_Rank_Name = {
	"#{NJBZ_220816_333}",
	"#{NJBZ_220816_334}",
	"#{NJBZ_220816_335}",
	"#{NJBZ_220816_336}",
	"#{NJBZ_220816_337}",
	"#{NJBZ_220816_338}",
}

function Armor_Upstage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
end

function Armor_Upstage_OnLoad()
	g_Armor_Upstage_Frame_UnifiedPosition = Armor_Upstage_Frame:GetProperty("UnifiedPosition")
	
	g_UA_Button[1] = Armor_Upstage_Choose_Item1
	g_UA_Button[2] = Armor_Upstage_Choose_Item2
	g_UA_Button[3] = Armor_Upstage_Choose_Item3
	
	g_UA_ExAttr_Before[1] = Armor_Upstage_AttrBefore2
	g_UA_ExAttr_Before[2] = Armor_Upstage_AttrBefore3
	g_UA_ExAttr_Before[3] = Armor_Upstage_AttrBefore4
	g_UA_ExAttr_Before[4] = Armor_Upstage_AttrBefore5
	g_UA_ExAttr_Before[5] = Armor_Upstage_AttrBefore6
	g_UA_ExAttr_Before[6] = Armor_Upstage_AttrBefore7
	g_UA_ExAttr_Before[7] = Armor_Upstage_AttrBefore8
	
	g_UA_ExAttr_After[1] = Armor_Upstage_AttrAfter2
	g_UA_ExAttr_After[2] = Armor_Upstage_AttrAfter3
	g_UA_ExAttr_After[3] = Armor_Upstage_AttrAfter4
	g_UA_ExAttr_After[4] = Armor_Upstage_AttrAfter5
	g_UA_ExAttr_After[5] = Armor_Upstage_AttrAfter6
	g_UA_ExAttr_After[6] = Armor_Upstage_AttrAfter7
	g_UA_ExAttr_After[7] = Armor_Upstage_AttrAfter8
end

function Armor_Upstage_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500102 then
		if not this:IsVisible() then
			Armor_Upstage_CleanUp()
			this:Show()
			Armor_Upstage_Update()
			Armor_Upstage_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		Armor_Upstage_Update()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		Armor_Upstage_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Armor_Upstage_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		Armor_Upstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		Armor_Upstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end
end

function Armor_Upstage_Update()
	
	Armor_Upstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	Armor_Upstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))	

	Armor_Upstage_UpdateSelect()
end

function Armor_Upstage_UpdateSelect()
	
	Armor_Upstage_Before:SetText("")
	Armor_Upstage_After:SetText("")

	Armor_Upstage_UnlockedInfoTips:SetText("")

	Armor_Upstage_NeedItemText:SetText("")
	Armor_Upstage_NeedItemNum:SetText("")

	Armor_Upstage_Currency1Num:SetProperty("MoneyNumber", "0")

	Armor_Upstage_AttrBefore1:SetText("")
	Armor_Upstage_AttrAfter1:SetText("")
	for i = 1, 7 do
		g_UA_ExAttr_Before[i]:SetText("")
		g_UA_ExAttr_After[i]:SetText("")
	end
	
	for i = 1, 3 do
		local bActived = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
		if bActived == 1 then
			g_UA_Button[i]:Enable()
		else
			g_UA_Button[i]:Disable()
		end
	end

	if g_Cur_Sel < 1 or g_Cur_Sel > 3 then
		g_Cur_Sel = 0
	else
		local bActived = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "ACTIVED")
		if bActived ~= 1 then
			g_Cur_Sel = 0
		end
	end
	
	for i = 1, 3 do
		if i == g_Cur_Sel then
			g_UA_Button[i]:SetCheck(1)
		else
			g_UA_Button[i]:SetCheck(0)
		end
	end

	if g_Cur_Sel >= 1 and g_Cur_Sel <= 3 then
		
		local strTemp = ""
		
		local iLevel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "LEVEL")
		local iRank = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "RANK")		
		local iStar = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "STAR")
		local iExCount = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_COUNT")
		if iExCount > 7 then
			iExCount = 7
		end
		
		strTemp = DataPool:LuaFnGetUnderArmourMainAttrDesc(g_Cur_Sel - 1, iRank, iLevel, 0)
		Armor_Upstage_AttrBefore1:SetText(strTemp)
		
		for i = 1, iExCount do
			local ex_id = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_ATTR", i - 1)
			strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_Cur_Sel - 1, ex_id, iRank, iLevel, 0)
			g_UA_ExAttr_Before[i]:SetText(strTemp)
		end
		
		if iRank == 5 then
			Armor_Upstage_Before:SetText("#{NJBZ_220816_64}")
			Armor_Upstage_After:SetText("#{NJBZ_220816_68}")
		else
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_63}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel))
			Armor_Upstage_Before:SetText(strTemp)
			
			local next_rank = iRank + 1
			local next_level = 0
			
			if next_rank == 5 then
				Armor_Upstage_After:SetText("#{NJBZ_220816_64}")
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_67}", tostring(g_UA_Rank_Name[next_rank + 1]), "0")
				Armor_Upstage_After:SetText(strTemp)
			end
			strTemp = DataPool:LuaFnGetUnderArmourMainAttrDesc(g_Cur_Sel - 1, next_rank, 0, 0)
			Armor_Upstage_AttrAfter1:SetText(strTemp)
				
			for i = 1, iExCount do
				local ex_id = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_ATTR", i - 1)
				strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_Cur_Sel - 1, ex_id, next_rank, 0, 0)
				g_UA_ExAttr_After[i]:SetText(strTemp)
			end

			local need_item, need_item_count, costMoney, _ = DataPool:LuaFnGetUnderArmourRankUpInfo(iRank)
			Armor_Upstage_Currency1Num:SetProperty("MoneyNumber", costMoney)

			local have_count = PlayerPackage:Lua_GetUnLockItemCount(need_item)
			local have_bind_count = PlayerPackage:Lua_GetUnLockBindItemCount(need_item)
			local need_item_name = DataPool:Lua_GetItemNameByIndex(need_item)

			strTemp = ScriptGlobal_Format("#{NJBZ_220816_71}", tostring(need_item_name))
			Armor_Upstage_NeedItemText:SetText(strTemp)

			if have_count >= need_item_count then
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_375}", tostring(have_count), tostring(need_item_count))
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_394}", tostring(have_count), tostring(need_item_count))
			end
			Armor_Upstage_NeedItemNum:SetText(strTemp)

			if iRank == 0 and g_Cur_Sel == 1 then
				Armor_Upstage_UnlockedInfoTips:SetText("#{NJBZ_220816_224}")
			elseif iRank == 0 and g_Cur_Sel == 2 then
				Armor_Upstage_UnlockedInfoTips:SetText("#{NJBZ_220816_225}")
			end
		end
	else
		g_Cur_Sel = 0
	end
end

function Armor_Upstage_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local bActived = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "ACTIVED")
		if bActived == 1 then
			g_Cur_Sel = iIndex		
			Armor_Upstage_UpdateSelect()
		end
	end
end

function Armor_Upstage_CloseClicked()
	this:Hide()
end

function Armor_Upstage_CleanUp()

	g_Cur_Sel = 1	

	Armor_Upstage_Before:SetText("")
	Armor_Upstage_After:SetText("")
	
	Armor_Upstage_NeedItemText:SetText("")
	Armor_Upstage_NeedItemNum:SetText("")

	Armor_Upstage_Currency1Num:SetProperty("MoneyNumber", "0")
	Armor_Upstage_Currency2Num:SetProperty("MoneyNumber", "0")
	Armor_Upstage_Currency3Num:SetProperty("MoneyNumber", "0")
	
	Armor_Upstage_AttrBefore1:SetText("")
	Armor_Upstage_AttrAfter1:SetText("")
	for i = 1, 7 do
		g_UA_ExAttr_Before[i]:SetText("")
		g_UA_ExAttr_After[i]:SetText("")
	end
end

function Armor_Upstage_OnHidden()
	Armor_Upstage_CleanUp()
	m_ObjServerId = -1
end

function Armor_Upstage_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_75}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourUp")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_Parameter(2, g_Cur_Sel - 1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Armor_Upstage_HelpClicked()

end
--Care Obj
function Armor_Upstage_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function Armor_Upstage_Frame_On_ResetPos()
	if g_Armor_Upstage_Frame_UnifiedPosition ~= nil then
		Armor_Upstage_Frame:SetProperty("UnifiedPosition", g_Armor_Upstage_Frame_UnifiedPosition)
	end
end

function Armor_Upstage_GetPercentageString(num)	
	if tonumber(num) == nil then
		return ""
	end
	
	local intPart = math.floor(num / 100)
	local floatPart = math.floor(math.mod(num, 100) / 10)
			
	if floatPart == 0 then
		return tostring(intPart).."%"
	else
		return tostring(intPart).."."..tostring(floatPart).."%"
	end
end

function Armor_Upstage_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end