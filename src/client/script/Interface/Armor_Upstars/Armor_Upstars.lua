--Armor_Upstars
--!!!reloadscript =Armor_Upstars

local g_Armor_Upstars_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Cur_Sel = 1

local g_UA_Button = {}

local g_UA_Rank_Name = {
	"#{NJBZ_220816_333}",
	"#{NJBZ_220816_334}",
	"#{NJBZ_220816_335}",
	"#{NJBZ_220816_336}",
	"#{NJBZ_220816_337}",
	"#{NJBZ_220816_338}",
}

local m_YuanbaoPay = 1

function Armor_Upstars_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
end

function Armor_Upstars_OnLoad()
	g_Armor_Upstars_Frame_UnifiedPosition = Armor_Upstars_Frame:GetProperty("UnifiedPosition")
	
	g_UA_Button[1] = Armor_Upstars_Choose_Item1
	g_UA_Button[2] = Armor_Upstars_Choose_Item2
	g_UA_Button[3] = Armor_Upstars_Choose_Item3
	
end

function Armor_Upstars_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500103 then
		if not this:IsVisible() then
			Armor_Upstars_CleanUp()
			if m_YuanbaoPay == 1 or m_YuanbaoPay == 0 then
				Armor_Upstars_YuanbaoTips:SetCheck(m_YuanbaoPay)
			end
			this:Show()
			Armor_Upstars_Update()
			Armor_Upstars_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		Armor_Upstars_Update()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		Armor_Upstars_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Armor_Upstars_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		Armor_Upstars_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		Armor_Upstars_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end
end

function Armor_Upstars_Update()
	
	Armor_Upstars_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	Armor_Upstars_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))

	Armor_Upstars_UpdateSelect()
end

function Armor_Upstars_UpdateSelect()
	
	Armor_Upstars_Before:SetText("")
	Armor_Upstars_After:SetText("")
	
	Armor_Upstars_NeedItemText:SetText("")
	Armor_Upstars_NeedItem:SetText("")
	Armor_Upstars_NeedLevelNum:SetText("")
	Armor_Upstars_Currency1Num:SetProperty("MoneyNumber", "0")
	
	Armor_Upstars_SuccessRateNum:SetText("")
	Armor_Upstars_AttrBefore1:SetText("")
	Armor_Upstars_AttrAfter1:SetText("")
	
	Armor_Upstars_BlankTips:SetText("")

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
		
		local _, _, _, max_star = DataPool:LuaFnGetUnderArmourRankUpInfo(iRank)
		local need_item, need_item_count, costMoney, odds, max_fail_times, fix_rate = DataPool:LuaFnGetUnderArmourStarUpInfo(iStar)
		
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_88}", tostring(iStar))
		Armor_Upstars_Before:SetText(strTemp)
		
		strTemp = Armor_Upstars_GetPercentageString(fix_rate)
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_386}", tostring(strTemp))
		Armor_Upstars_AttrBefore1:SetText(strTemp)
		
		if iStar == 9 then
			Armor_Upstars_After:SetText("#{NJBZ_220816_91}")
		else
			for i = 0, 5 do
				local _, _, _, max_star = DataPool:LuaFnGetUnderArmourRankUpInfo(i)
				if max_star > iStar then
					strTemp = ScriptGlobal_Format("#{NJBZ_220816_86}", tostring(g_UA_Rank_Name[i + 1]))
					Armor_Upstars_NeedLevelNum:SetText(strTemp)
					break
				end
			end		

			local _, _, _, _, _, next_fix_rate = DataPool:LuaFnGetUnderArmourStarUpInfo(iStar + 1)
			
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_92}", tostring(iStar + 1))
			Armor_Upstars_After:SetText(strTemp)
				
			strTemp = Armor_Upstars_GetPercentageString(next_fix_rate)
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_386}", tostring(strTemp))
			Armor_Upstars_AttrAfter1:SetText(strTemp)
				
			Armor_Upstars_Currency1Num:SetProperty("MoneyNumber", costMoney)
				
			local have_count = PlayerPackage:Lua_GetUnLockItemCount(need_item)
			local have_bind_count = PlayerPackage:Lua_GetUnLockBindItemCount(need_item)
			local need_item_name = DataPool:Lua_GetItemNameByIndex(need_item)
			
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_96}", tostring(need_item_name))
			Armor_Upstars_NeedItemText:SetText(strTemp)
			
			if have_count >= need_item_count then
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_375}", tostring(have_count), tostring(need_item_count))
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_394}", tostring(have_count), tostring(need_item_count))
			end
			Armor_Upstars_NeedItem:SetText(strTemp)
				
			local fTimes = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "FAILTIMES")
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_90}", tostring(max_fail_times - fTimes))
			Armor_Upstars_BlankTips:SetText(strTemp)
			
			strTemp = Armor_Upstars_GetPercentageString(odds)
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_95}", strTemp)
			Armor_Upstars_SuccessRateNum:SetText(strTemp)
		end
	else
		g_Cur_Sel = 0
	end
end

function Armor_Upstars_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local bActived = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "ACTIVED")
		if bActived == 1 then
			g_Cur_Sel = iIndex		
			Armor_Upstars_UpdateSelect()
		end
	end
end

function Armor_Upstars_CloseClicked()
	this:Hide()
end

function Armor_Upstars_CleanUp()

	g_Cur_Sel = 1	
	
	Armor_Upstars_Before:SetText("")
	Armor_Upstars_After:SetText("")
	
	Armor_Upstars_NeedItemText:SetText("")
	Armor_Upstars_NeedItem:SetText("")

	Armor_Upstars_NeedLevelNum:SetText("")
	Armor_Upstars_Currency1Num:SetProperty("MoneyNumber", "0")
	Armor_Upstars_Currency2Num:SetProperty("MoneyNumber", "0")
	Armor_Upstars_Currency3Num:SetProperty("MoneyNumber", "0")
	
	Armor_Upstars_SuccessRateNum:SetText("")
	Armor_Upstars_AttrBefore1:SetText("")
	Armor_Upstars_AttrAfter1:SetText("")
	
	Armor_Upstars_BlankTips:SetText("")

end

function Armor_Upstars_OnHidden()
	Armor_Upstars_CleanUp()
	m_ObjServerId = -1
	m_YuanbaoPay = Armor_Upstars_YuanbaoTips:GetCheck()
end

function Armor_Upstars_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_100}")
		return
	end
	
	local bBuyConfirm = Armor_Upstars_YuanbaoTips:GetCheck()

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourUp")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, 2)
		Set_XSCRIPT_Parameter(2, g_Cur_Sel - 1)
		Set_XSCRIPT_Parameter(3, bBuyConfirm)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function Armor_Upstars_HelpClicked()

end
--Care Obj
function Armor_Upstars_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function Armor_Upstars_Frame_On_ResetPos()
	if g_Armor_Upstars_Frame_UnifiedPosition ~= nil then
		Armor_Upstars_Frame:SetProperty("UnifiedPosition", g_Armor_Upstars_Frame_UnifiedPosition)
	end
end

function Armor_Upstars_GetPercentageString(num)	
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

function Armor_Upstars_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end