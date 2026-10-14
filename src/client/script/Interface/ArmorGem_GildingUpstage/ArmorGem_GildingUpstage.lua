--ArmorGem_GildingUpstage
--!!!reloadscript =ArmorGem_GildingUpstage

local g_ArmorGem_GildingUpstage_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Cur_Sel = 0

local g_Jewel_Button = {}
local g_Jewel_Name_Text = {}

function ArmorGem_GildingUpstage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
end

function ArmorGem_GildingUpstage_OnLoad()
	g_ArmorGem_GildingUpstage_Frame_UnifiedPosition = ArmorGem_GildingUpstage_Frame:GetProperty("UnifiedPosition")
	
	g_Jewel_Button[1] = ArmorGem_GildingUpstage_Choose_Item1
	g_Jewel_Button[2] = ArmorGem_GildingUpstage_Choose_Item2
	g_Jewel_Button[3] = ArmorGem_GildingUpstage_Choose_Item3

	g_Jewel_Name_Text[1] = ArmorGem_GildingUpstage_Choose_Item1_Text
	g_Jewel_Name_Text[2] = ArmorGem_GildingUpstage_Choose_Item2_Text
	g_Jewel_Name_Text[3] = ArmorGem_GildingUpstage_Choose_Item3_Text
	
end

function ArmorGem_GildingUpstage_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500108 then
		if not this:IsVisible() then
			ArmorGem_GildingUpstage_CleanUp()
			ArmorGem_GildingUpstage_Init()
			this:Show()
			ArmorGem_GildingUpstage_Update()
			ArmorGem_GildingUpstage_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		ArmorGem_GildingUpstage_Update()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" then
		ArmorGem_GildingUpstage_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_GildingUpstage_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_GildingUpstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_GildingUpstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end
end

function ArmorGem_GildingUpstage_Init()
	for i = 1, 3 do
		local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
		if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
			local iPlate = DataPool:LuaFnGetUnderArmourData(i - 1, "PLATE")
			if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
				g_Cur_Sel = i
			end
		end
	end
end

function ArmorGem_GildingUpstage_Update()
	
	ArmorGem_GildingUpstage_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_GildingUpstage_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
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

	ArmorGem_GildingUpstage_UpdateSelect()
end

function ArmorGem_GildingUpstage_UpdateSelect()
	
	ArmorGem_GildingUpstage_Before:SetText("")
	ArmorGem_GildingUpstage_After:SetText("")

	ArmorGem_GildingUpstage_NeedItemText:SetText("")
	ArmorGem_GildingUpstage_NeedItemNum:SetText("")

	ArmorGem_GildingUpstage_Currency1Num:SetProperty("MoneyNumber", "0")

	ArmorGem_GildingUpstage_AttrBefore1:SetText("")
	ArmorGem_GildingUpstage_AttrAfter1:SetText("")
	
	if g_Cur_Sel < 1 or g_Cur_Sel > 3 then
		g_Cur_Sel = 0
	else
		local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
		if iJewel == nil or iJewel == -1 then
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
		
		local iStar = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "STAR")
		local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
		local iJewelLevel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL_LEVEL")
		local iPlate = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "PLATE")
		local iPlateLevel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "PLATE_LEVEL")

		if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then

			strTemp = ScriptGlobal_Format("#{NJBZ_220816_178}", tostring(iPlateLevel + 1))
			ArmorGem_GildingUpstage_Before:SetText(strTemp)

			strTemp = DataPool:LuaFnGetUnderArmourPlateEffectDesc(tonumber(iPlate), iPlateLevel)
			ArmorGem_GildingUpstage_AttrBefore1:SetText(strTemp)
			
			if iPlateLevel == 2 then
				ArmorGem_GildingUpstage_After:SetText("#{NJBZ_220816_182}")
			else
				strTemp = DataPool:LuaFnGetUnderArmourPlateEffectDesc(tonumber(iPlate), iPlateLevel + 1)
				ArmorGem_GildingUpstage_AttrAfter1:SetText(strTemp)

				strTemp = ScriptGlobal_Format("#{NJBZ_220816_180}", tostring(iPlateLevel + 2))
				ArmorGem_GildingUpstage_After:SetText(strTemp)

				local need_item, need_item_count, costMoney = DataPool:LuaFnGetUnderArmourPlateLevelUpInfo(iPlate, iPlateLevel)
				ArmorGem_GildingUpstage_Currency1Num:SetProperty("MoneyNumber", costMoney)
					
				local have_count = PlayerPackage:Lua_GetUnLockItemCount(need_item)
				local have_bind_count = PlayerPackage:Lua_GetUnLockBindItemCount(need_item)

				local need_item_name = DataPool:Lua_GetItemNameByIndex(need_item)
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_183}", tostring(need_item_name))
				ArmorGem_GildingUpstage_NeedItemText:SetText(strTemp)

				if have_count >= need_item_count then
					strTemp = ScriptGlobal_Format("#{NJBZ_220816_185}", tostring(need_item_count))					
				else
					strTemp = ScriptGlobal_Format("#{NJBZ_220816_184}", tostring(need_item_count))
				end
				ArmorGem_GildingUpstage_NeedItemNum:SetText(strTemp)
			end
		else
			ArmorGem_GildingUpstage_Before:SetText("#{NJBZ_220816_177}")
		end
	else
		g_Cur_Sel = 0
	end
end

function ArmorGem_GildingUpstage_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local iJewel = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "JEWEL")
		if tonumber(iJewel) ~= nil then
			if tonumber(iJewel) > 0 then
				g_Cur_Sel = iIndex
				ArmorGem_GildingUpstage_UpdateSelect()
			end
		end
	end
end

function ArmorGem_GildingUpstage_CloseClicked()
	this:Hide()
end

function ArmorGem_GildingUpstage_CleanUp()

	g_Cur_Sel = 0	

	ArmorGem_GildingUpstage_Before:SetText("")
	ArmorGem_GildingUpstage_After:SetText("")
	
	ArmorGem_GildingUpstage_NeedItemText:SetText("")
	ArmorGem_GildingUpstage_NeedItemNum:SetText("")

	ArmorGem_GildingUpstage_Currency1Num:SetProperty("MoneyNumber", "0")
	ArmorGem_GildingUpstage_Currency2Num:SetProperty("MoneyNumber", "0")
	ArmorGem_GildingUpstage_Currency3Num:SetProperty("MoneyNumber", "0")
	
	ArmorGem_GildingUpstage_AttrBefore1:SetText("")
	ArmorGem_GildingUpstage_AttrAfter1:SetText("")
	
	for i = 1, 3 do
		g_Jewel_Button[i]:SetActionItem(-1)
	end

end

function ArmorGem_GildingUpstage_OnHidden()
	ArmorGem_GildingUpstage_CleanUp()
	m_ObjServerId = -1
end

function ArmorGem_GildingUpstage_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_187}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourPlateUp")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Cur_Sel - 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function ArmorGem_GildingUpstage_HelpClicked()

end
--Care Obj
function ArmorGem_GildingUpstage_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_GildingUpstage_Frame_On_ResetPos()
	if g_ArmorGem_GildingUpstage_Frame_UnifiedPosition ~= nil then
		ArmorGem_GildingUpstage_Frame:SetProperty("UnifiedPosition", g_ArmorGem_GildingUpstage_Frame_UnifiedPosition)
	end
end

function ArmorGem_GildingUpstage_GetPercentageString(num)	
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

function ArmorGem_GildingUpstage_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end