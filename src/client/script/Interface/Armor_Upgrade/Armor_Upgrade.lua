--Armor_Upgrade
--!!!reloadscript =Armor_Upgrade

local g_Armor_Upgrade_Frame_UnifiedPosition = ""
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

function Armor_Upgrade_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
	this:RegisterEvent("UPDATE_UA_EXP", false)
end

function Armor_Upgrade_OnLoad()
	g_Armor_Upgrade_Frame_UnifiedPosition = Armor_Upgrade_Frame:GetProperty("UnifiedPosition")
	
	g_UA_Button[1] = Armor_Upgrade_Choose_Item1
	g_UA_Button[2] = Armor_Upgrade_Choose_Item2
	g_UA_Button[3] = Armor_Upgrade_Choose_Item3
	
	g_UA_ExAttr_Before[1] = Armor_Upgrade_AttrBefore2
	g_UA_ExAttr_Before[2] = Armor_Upgrade_AttrBefore3
	g_UA_ExAttr_Before[3] = Armor_Upgrade_AttrBefore4
	g_UA_ExAttr_Before[4] = Armor_Upgrade_AttrBefore5
	g_UA_ExAttr_Before[5] = Armor_Upgrade_AttrBefore6
	g_UA_ExAttr_Before[6] = Armor_Upgrade_AttrBefore7
	g_UA_ExAttr_Before[7] = Armor_Upgrade_AttrBefore8
	
	g_UA_ExAttr_After[1] = Armor_Upgrade_AttrAfter2
	g_UA_ExAttr_After[2] = Armor_Upgrade_AttrAfter3
	g_UA_ExAttr_After[3] = Armor_Upgrade_AttrAfter4
	g_UA_ExAttr_After[4] = Armor_Upgrade_AttrAfter5
	g_UA_ExAttr_After[5] = Armor_Upgrade_AttrAfter6
	g_UA_ExAttr_After[6] = Armor_Upgrade_AttrAfter7
	g_UA_ExAttr_After[7] = Armor_Upgrade_AttrAfter8
end

function Armor_Upgrade_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500101 then
		if not this:IsVisible() then
			Armor_Upgrade_CleanUp()
			this:Show()
			Armor_Upgrade_Update()
			Armor_Upgrade_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		Armor_Upgrade_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Armor_Upgrade_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		Armor_Upgrade_Currency4Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		Armor_Upgrade_Currency5Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end
	
	if "UPDATE_UA_EXP" then
		Armor_Upgrade_Currency2Num:SetText(tostring(Player:GetData("UAEXP")))
		return
	end
	
end

function Armor_Upgrade_Update()
	
	Armor_Upgrade_Currency2Num:SetText(tostring(Player:GetData("UAEXP")))
	Armor_Upgrade_Currency4Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	Armor_Upgrade_Currency5Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))

	Armor_Upgrade_UpdateSelect()
end

function Armor_Upgrade_UpdateSelect()
	
	Armor_Upgrade_Before:SetText("")
	Armor_Upgrade_After:SetText("")
	
	Armor_Upgrade_Currency1Num:SetText("0")
	Armor_Upgrade_Currency3Num:SetProperty("MoneyNumber", "0")
	
	Armor_Upgrade_AttrBefore1:SetText("")
	Armor_Upgrade_AttrAfter1:SetText("")
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
		Armor_Upgrade_AttrBefore1:SetText(strTemp)
		
		for i = 1, iExCount do
			local ex_id = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_ATTR", i - 1)
			strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_Cur_Sel - 1, ex_id, iRank, iLevel, 0)
			g_UA_ExAttr_Before[i]:SetText(strTemp)
		end
		
		if iRank == 5 then
			Armor_Upgrade_Before:SetText("#{NJBZ_220816_31}")
			Armor_Upgrade_After:SetText("#{NJBZ_220816_35}")
			Armor_Upgrade_Currency1Num:SetText("0")
			Armor_Upgrade_Currency3Num:SetProperty("MoneyNumber", "0")
		else
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_30}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel))
			Armor_Upgrade_Before:SetText(strTemp)

			local next_rank = iRank
			local next_level = iLevel + 1
			
			if iLevel == 10 then
				next_rank = iRank + 1
				next_level = 0
				Armor_Upgrade_Currency1Num:SetText("0")
				Armor_Upgrade_Currency3Num:SetProperty("MoneyNumber", "0")
			else
				local costExp, costMoney = DataPool:LuaFnGetUnderArmourLevelUpInfo(g_Cur_Sel - 1, iRank, iLevel)
				Armor_Upgrade_Currency1Num:SetText(tostring(costExp))
				Armor_Upgrade_Currency3Num:SetProperty("MoneyNumber", costMoney)
			end
			
			if next_rank == 5 then
				Armor_Upgrade_After:SetText("#{NJBZ_220816_31}")
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_33}", tostring(g_UA_Rank_Name[next_rank + 1]), tostring(next_level))
				Armor_Upgrade_After:SetText(strTemp)
			end
				
			strTemp = DataPool:LuaFnGetUnderArmourMainAttrDesc(g_Cur_Sel - 1, next_rank, next_level, 0)
			Armor_Upgrade_AttrAfter1:SetText(strTemp)
				
			for i = 1, iExCount do
				local ex_id = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_ATTR", i - 1)
				strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_Cur_Sel - 1, ex_id, next_rank, next_level, 0)
				g_UA_ExAttr_After[i]:SetText(strTemp)
			end
		end
	else
		g_Cur_Sel = 0
	end
end

function Armor_Upgrade_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local bActived = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "ACTIVED")
		if bActived == 1 then
			g_Cur_Sel = iIndex		
			Armor_Upgrade_UpdateSelect()
		end
	end
end

function Armor_Upgrade_CloseClicked()
	this:Hide()
end

function Armor_Upgrade_CleanUp()

	g_Cur_Sel = 1	

	Armor_Upgrade_Before:SetText("")
	Armor_Upgrade_After:SetText("")
	
	Armor_Upgrade_Currency1Num:SetText("0")
	Armor_Upgrade_Currency2Num:SetText("0")
	Armor_Upgrade_Currency3Num:SetProperty("MoneyNumber", "0")
	Armor_Upgrade_Currency4Num:SetProperty("MoneyNumber", "0")
	Armor_Upgrade_Currency5Num:SetProperty("MoneyNumber", "0")
	
	Armor_Upgrade_AttrBefore1:SetText("")
	Armor_Upgrade_AttrAfter1:SetText("")
	for i = 1, 7 do
		g_UA_ExAttr_Before[i]:SetText("")
		g_UA_ExAttr_After[i]:SetText("")
	end
end

function Armor_Upgrade_OnHidden()
	Armor_Upgrade_CleanUp()
	m_ObjServerId = -1
end

function Armor_Upgrade_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_52}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourUp")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_Parameter(2, g_Cur_Sel - 1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Armor_Upgrade_HelpClicked()

end
--Care Obj
function Armor_Upgrade_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function Armor_Upgrade_Frame_On_ResetPos()
	if g_Armor_Upgrade_Frame_UnifiedPosition ~= nil then
		Armor_Upgrade_Frame:SetProperty("UnifiedPosition", g_Armor_Upgrade_Frame_UnifiedPosition)
	end
end

function Armor_Upgrade_GetPercentageString(num)	
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

function Armor_Upgrade_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end