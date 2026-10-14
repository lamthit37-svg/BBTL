--Armor_Purify
--!!!reloadscript =Armor_Purify

local g_Armor_Purify_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_WashNeedItem = 38007004
local g_WashNeedItemCount = 1

local g_Cur_Sel = 1

local g_UA_ExAttr_Before = {}
local g_UA_ExAttr_After = {}
local g_UA_Button = {}

local m_YuanbaoPay = 1

function Armor_Purify_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
	this:RegisterEvent("UPDATE_UA_WASH_TIMES", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
end

function Armor_Purify_OnLoad()
	g_Armor_Purify_Frame_UnifiedPosition = Armor_Purify_Frame:GetProperty("UnifiedPosition")
	
	g_UA_Button[1] = Armor_Purify_Choose_Item1
	g_UA_Button[2] = Armor_Purify_Choose_Item2
	g_UA_Button[3] = Armor_Purify_Choose_Item3
	
	g_UA_ExAttr_Before[1] = Armor_Purify_AttrBefore1
	g_UA_ExAttr_Before[2] = Armor_Purify_AttrBefore2
	g_UA_ExAttr_Before[3] = Armor_Purify_AttrBefore3
	g_UA_ExAttr_Before[4] = Armor_Purify_AttrBefore4
	g_UA_ExAttr_Before[5] = Armor_Purify_AttrBefore5
	g_UA_ExAttr_Before[6] = Armor_Purify_AttrBefore6
	g_UA_ExAttr_Before[7] = Armor_Purify_AttrBefore7
	
	g_UA_ExAttr_After[1] = Armor_Purify_AttrAfter1
	g_UA_ExAttr_After[2] = Armor_Purify_AttrAfter2
	g_UA_ExAttr_After[3] = Armor_Purify_AttrAfter3
	g_UA_ExAttr_After[4] = Armor_Purify_AttrAfter4
	g_UA_ExAttr_After[5] = Armor_Purify_AttrAfter5
	g_UA_ExAttr_After[6] = Armor_Purify_AttrAfter6
	g_UA_ExAttr_After[7] = Armor_Purify_AttrAfter7
end

function Armor_Purify_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500104 then
		if not this:IsVisible() then
			Armor_Purify_CleanUp()
			if m_YuanbaoPay == 1 or m_YuanbaoPay == 0 then
				Armor_Purify_YuanbaoTips:SetCheck(m_YuanbaoPay)
			end
			this:Show()
			Armor_Purify_Update()
			Armor_Purify_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		Armor_Purify_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Armor_Purify_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		Armor_Purify_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		Armor_Purify_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end	
	
	if event == "UPDATE_UA_WASH_TIMES" then
		local iTime = Player:GetData("UAWASHTIMES")
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_446}", tostring(iTime))
		Armor_Purify_BlankTips:SetText(strTemp)
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		Armor_Purify_Update()
		return
	end
	
end

function Armor_Purify_Update()
	
	Armor_Purify_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	Armor_Purify_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))

	local iTime = Player:GetData("UAWASHTIMES")
	local strTemp = ScriptGlobal_Format("#{NJBZ_220816_446}", tostring(iTime))
	Armor_Purify_BlankTips:SetText(strTemp)

	Armor_Purify_UpdateSelect()
end

function Armor_Purify_UpdateSelect()
	
	Armor_Purify_Before:SetText("")
	Armor_Purify_After:SetText("")
	
	Armor_Purify_NeedNum:SetText("")
	Armor_Purify_Currency1Num:SetProperty("MoneyNumber", "0")
	
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

		for i = 1, iExCount do
			local ex_id = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_ATTR", i - 1)
			strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_Cur_Sel - 1, ex_id, iRank, iLevel, 0)
			g_UA_ExAttr_Before[i]:SetText(strTemp)
		end
		
		local iExCountNew = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_COUNT_NEW")
		if iExCountNew > 7 then
			iExCountNew = 7
		end
		
		for i = 1, iExCountNew do
			local ex_id = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "EX_ATTR_NEW", i - 1)
			strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_Cur_Sel - 1, ex_id, iRank, iLevel, 0)
			g_UA_ExAttr_After[i]:SetText(strTemp)
		end
		
		local have_count = PlayerPackage:Lua_GetUnLockItemCount(g_WashNeedItem)
		
		if have_count >= g_WashNeedItemCount then
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_375}", tostring(have_count), tostring(g_WashNeedItemCount))
		else
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_394}", tostring(have_count), tostring(g_WashNeedItemCount))
		end
		Armor_Purify_NeedNum:SetText(strTemp)

		Armor_Purify_Currency1Num:SetProperty("MoneyNumber", "100000")
	else
		g_Cur_Sel = 0
	end
end

function Armor_Purify_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local bActived = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "ACTIVED")
		if bActived == 1 then
			g_Cur_Sel = iIndex		
			Armor_Purify_UpdateSelect()
		end
	end
end

function Armor_Purify_CloseClicked()
	this:Hide()
end

function Armor_Purify_CleanUp()

	g_Cur_Sel = 1	

	Armor_Purify_Before:SetText("")
	Armor_Purify_After:SetText("")
	
	Armor_Purify_NeedNum:SetText("")
	Armor_Purify_Currency1Num:SetProperty("MoneyNumber", "0")
	Armor_Purify_Currency2Num:SetProperty("MoneyNumber", "0")
	Armor_Purify_Currency3Num:SetProperty("MoneyNumber", "0")
	
	for i = 1, 7 do
		g_UA_ExAttr_Before[i]:SetText("")
		g_UA_ExAttr_After[i]:SetText("")
	end
end

function Armor_Purify_OnHidden()
	Armor_Purify_CleanUp()
	m_ObjServerId = -1
	m_YuanbaoPay = Armor_Purify_YuanbaoTips:GetCheck()
end

function Armor_Purify_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_117}")
		return
	end
	
	local bBuyConfirm = Armor_Purify_YuanbaoTips:GetCheck()

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourWash")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Cur_Sel - 1)
		Set_XSCRIPT_Parameter(2, tonumber(bBuyConfirm))
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Armor_Purify_AttrChangeClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_121}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourSwitch")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Cur_Sel - 1)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	

end

function Armor_Purify_HelpClicked()

end
--Care Obj
function Armor_Purify_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function Armor_Purify_Frame_On_ResetPos()
	if g_Armor_Purify_Frame_UnifiedPosition ~= nil then
		Armor_Purify_Frame:SetProperty("UnifiedPosition", g_Armor_Purify_Frame_UnifiedPosition)
	end
end

function Armor_Purify_GetPercentageString(num)	
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

function Armor_Purify_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end