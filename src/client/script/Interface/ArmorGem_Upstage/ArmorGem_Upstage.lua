--ArmorGem_Upstage
--!!!reloadscript =ArmorGem_Upstage

local g_ArmorGem_Upstage_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Cur_Sel = 0

local g_UA_ExAttr_Before = {}
local g_UA_ExAttr_After = {}
local g_Jewel_Button = {}
local g_Jewel_Name_Text = {}

function ArmorGem_Upstage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
end

function ArmorGem_Upstage_OnLoad()
	g_ArmorGem_Upstage_Frame_UnifiedPosition = ArmorGem_Upstage_Frame:GetProperty("UnifiedPosition")
	
	g_Jewel_Button[1] = ArmorGem_Upstage_Choose_Item1
	g_Jewel_Button[2] = ArmorGem_Upstage_Choose_Item2
	g_Jewel_Button[3] = ArmorGem_Upstage_Choose_Item3

	g_Jewel_Name_Text[1] = ArmorGem_Upstage_Choose_Item1_Text
	g_Jewel_Name_Text[2] = ArmorGem_Upstage_Choose_Item2_Text
	g_Jewel_Name_Text[3] = ArmorGem_Upstage_Choose_Item3_Text
end

function ArmorGem_Upstage_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500106 then
		if not this:IsVisible() then
			ArmorGem_Upstage_CleanUp()
			ArmorGem_Upstage_Init()
			this:Show()
			ArmorGem_Upstage_Update()
			ArmorGem_Upstage_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		ArmorGem_Upstage_Update()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		ArmorGem_Upstage_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_Upstage_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_Upstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_Upstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end
end

function ArmorGem_Upstage_Init()
	for i = 1, 3 do
		local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
		if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
			g_Cur_Sel = i
			return
		end
	end
end

function ArmorGem_Upstage_Update()
	
	ArmorGem_Upstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_Upstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	for i = 1, 3 do
		g_Jewel_Button[i]:Enable()
		g_Jewel_Button[i]:SetActionItem(-1)
		g_Jewel_Name_Text[i]:SetText("#{NJBZ_220816_138}")
		local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
		if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
				local itemAction = EnumAction(i - 1, "UnderArmourJewel")
				g_Jewel_Button[i]:SetActionItem(itemAction:GetID())
			
			local iPlate = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE")
			local jewel_name = DataPool:LuaFnGetUnderArmourJewelName(iJewel, iPlate)
			g_Jewel_Name_Text[i]:SetText(tostring(jewel_name))
		else
			g_Jewel_Button[i]:Disable()
		end	
	end

	ArmorGem_Upstage_UpdateSelect()
end

function ArmorGem_Upstage_UpdateSelect()
	
	ArmorGem_Upstage_Before:SetText("")
	ArmorGem_Upstage_After:SetText("")

	ArmorGem_Upstage_NeedItemText:SetText("")
	ArmorGem_Upstage_NeedItemNum:SetText("")

	ArmorGem_Upstage_FragGemItemText:SetText("")
	ArmorGem_Upstage_FragGemItemNum:SetText("")

	ArmorGem_Upstage_Currency1Num:SetProperty("MoneyNumber", "0")

	ArmorGem_Upstage_AttrBefore1:SetText("")
	ArmorGem_Upstage_AttrAfter1:SetText("")
	
	if g_Cur_Sel < 1 or g_Cur_Sel > 3 then
		g_Cur_Sel = 0
	else
		local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
		if tonumber(iJewel) == nil or tonumber(iJewel) <= 0 then
			g_Cur_Sel = 0
		end
	end
	
	for i = 1, 3 do
		if i == g_Cur_Sel then
			g_Jewel_Button[i]:SetPushed(1)
		else
			g_Jewel_Button[i]:SetPushed(0)
		end
	end

	if g_Cur_Sel >= 1 and g_Cur_Sel <= 3 then
		
		local strTemp = ""
		
		local iLevel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "LEVEL")
		local iRank = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "RANK")		
		--local iStar = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "STAR")
		local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
		local iJewelLevel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL_LEVEL")
		
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_141}", tostring(iJewelLevel + 1))
		ArmorGem_Upstage_Before:SetText(strTemp)
		
		strTemp = DataPool:LuaFnGetUnderArmourJewelEffectDesc(tonumber(iJewel), iJewelLevel, 0)
		ArmorGem_Upstage_AttrBefore1:SetText(strTemp)
		
		if iJewelLevel == 4 then
			ArmorGem_Upstage_After:SetText("#{NJBZ_220816_144}")
		else
			strTemp = DataPool:LuaFnGetUnderArmourJewelEffectDesc(tonumber(iJewel), iJewelLevel + 1, 0)
			ArmorGem_Upstage_AttrAfter1:SetText(strTemp)
			
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_143}", tostring(iJewelLevel + 2))
			ArmorGem_Upstage_After:SetText(strTemp)

			local need_item, need_item_count, need_item_1, need_item_count_1, costMoney, _ = DataPool:LuaFnGetUnderArmourJewelLevelUpInfo(iJewel, iJewelLevel)
			ArmorGem_Upstage_Currency1Num:SetProperty("MoneyNumber", costMoney)
				
			local have_count = PlayerPackage:Lua_GetUnLockItemCount(need_item)
			local have_bind_count = PlayerPackage:Lua_GetUnLockBindItemCount(need_item)
				
			local need_item_name = DataPool:Lua_GetItemNameByIndex(need_item)
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_147}", tostring(need_item_name))
			ArmorGem_Upstage_NeedItemText:SetText(strTemp)

			if have_count >= need_item_count then
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_375}", tostring(have_count), tostring(need_item_count))
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_394}", tostring(have_count), tostring(need_item_count))
			end
			ArmorGem_Upstage_NeedItemNum:SetText(strTemp)
			
			-----
			
			local have_count_1 = PlayerPackage:Lua_GetUnLockItemCount(need_item_1)
			local have_bind_count_1 = PlayerPackage:Lua_GetUnLockBindItemCount(need_item_1)
				
			local need_item_name_1 = DataPool:Lua_GetItemNameByIndex(need_item_1)
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_147}", tostring(need_item_name_1))
			ArmorGem_Upstage_FragGemItemText:SetText(strTemp)

			if have_count_1 >= need_item_count_1 then
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_375}", tostring(have_count_1), tostring(need_item_count_1))
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_394}", tostring(have_count_1), tostring(need_item_count_1))
			end
			ArmorGem_Upstage_FragGemItemNum:SetText(strTemp)
		end
	else
		g_Cur_Sel = 0
	end
end

function ArmorGem_Upstage_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local iJewel = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "JEWEL")
		if tonumber(iJewel) ~= nil then
			if tonumber(iJewel) > 0 then
				g_Cur_Sel = iIndex
				ArmorGem_Upstage_UpdateSelect()
			end
		end
	end
end

function ArmorGem_Upstage_CloseClicked()
	this:Hide()
end

function ArmorGem_Upstage_CleanUp()

	g_Cur_Sel = 0	

	ArmorGem_Upstage_Before:SetText("")
	ArmorGem_Upstage_After:SetText("")
	
	ArmorGem_Upstage_NeedItemText:SetText("")
	ArmorGem_Upstage_NeedItemNum:SetText("")
	
	ArmorGem_Upstage_FragGemItemText:SetText("")
	ArmorGem_Upstage_FragGemItemNum:SetText("")

	ArmorGem_Upstage_Currency1Num:SetProperty("MoneyNumber", "0")
	ArmorGem_Upstage_Currency2Num:SetProperty("MoneyNumber", "0")
	ArmorGem_Upstage_Currency3Num:SetProperty("MoneyNumber", "0")
	
	ArmorGem_Upstage_AttrBefore1:SetText("")
	ArmorGem_Upstage_AttrAfter1:SetText("")
	
	for i = 1, 3 do
		g_Jewel_Button[i]:SetActionItem(-1)
	end

end

function ArmorGem_Upstage_OnHidden()
	ArmorGem_Upstage_CleanUp()
	m_ObjServerId = -1
end

function ArmorGem_Upstage_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_151}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourJewelUp")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Cur_Sel - 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function ArmorGem_Upstage_HelpClicked()

end
--Care Obj
function ArmorGem_Upstage_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_Upstage_Frame_On_ResetPos()
	if g_ArmorGem_Upstage_Frame_UnifiedPosition ~= nil then
		ArmorGem_Upstage_Frame:SetProperty("UnifiedPosition", g_ArmorGem_Upstage_Frame_UnifiedPosition)
	end
end

function ArmorGem_Upstage_GetPercentageString(num)	
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

function ArmorGem_Upstage_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end