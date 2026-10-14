--ArmorGem_Gilding
--!!!reloadscript =ArmorGem_Gilding

local g_ArmorGem_Gilding_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Cur_Sel = 0

local g_Jewel_Button = {}
local g_Jewel_Name_Text = {}

local g_Plate_ItemIndex = -1

local g_PlateItem = {
	[38007044] = {pId = 1, needCount = 50, needMoney = 2000000},
	[38007045] = {pId = 2, needCount = 50, needMoney = 2000000},
	[38007046] = {pId = 3, needCount = 50, needMoney = 2000000},
	[38007047] = {pId = 4, needCount = 50, needMoney = 2000000},
	[38007048] = {pId = 5, needCount = 50, needMoney = 2000000},
	[38007049] = {pId = 6, needCount = 50, needMoney = 2000000},
	[38007050] = {pId = 7, needCount = 50, needMoney = 2000000},
}

function ArmorGem_Gilding_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
	
	this:RegisterEvent("UA_JEWEL_PLATE_PUTIN", false)
	this:RegisterEvent("UA_JEWEL_PLATE_RCLICK", false)
	this:RegisterEvent("UA_JEWEL_PLATE_REMOVE", false)
end

function ArmorGem_Gilding_OnLoad()
	g_ArmorGem_Gilding_Frame_UnifiedPosition = ArmorGem_Gilding_Frame:GetProperty("UnifiedPosition")
	
	g_Jewel_Button[1] = ArmorGem_Gilding_Choose_Item1
	g_Jewel_Button[2] = ArmorGem_Gilding_Choose_Item2
	g_Jewel_Button[3] = ArmorGem_Gilding_Choose_Item3
	
	g_Jewel_Name_Text[1] = ArmorGem_Gilding_Choose_Item1_Text
	g_Jewel_Name_Text[2] = ArmorGem_Gilding_Choose_Item2_Text
	g_Jewel_Name_Text[3] = ArmorGem_Gilding_Choose_Item3_Text
	
end

function ArmorGem_Gilding_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500107 then
		if not this:IsVisible() then
			ArmorGem_Gilding_CleanUp()
			ArmorGem_Gilding_Init()
			this:Show()
			ArmorGem_Gilding_Update()
			ArmorGem_Gilding_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		ArmorGem_Gilding_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_Gilding_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_Gilding_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_Gilding_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end

	if event == "UA_JEWEL_PLATE_PUTIN" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Gilding_OnItemDragedDropFromBag(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_JEWEL_PLATE_RCLICK" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Gilding_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_JEWEL_PLATE_REMOVE" then
		ArmorGem_Gilding_OnItemDragedDropAway()
		return
	end
	
end

function ArmorGem_Gilding_Init()
	for i = 1, 3 do
		local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
		if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
			g_Cur_Sel = i
			return
		end
	end
end

function ArmorGem_Gilding_Update()
	
	ArmorGem_Gilding_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_Gilding_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
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
	
	ArmorGem_Gilding_UpdateSelect()
end

function ArmorGem_Gilding_UpdateSelect()
	
	ArmorGem_Gilding_Before:SetText("")
	ArmorGem_Gilding_After:SetText("")
	ArmorGem_Gilding_Currency1Num:SetProperty("MoneyNumber", "0")
	
	ArmorGem_Gilding_AttrBefore1:SetText("")
	ArmorGem_Gilding_AttrBefore2:SetText("")
	ArmorGem_Gilding_AttrAfter1:SetText("")
	ArmorGem_Gilding_AttrAfter2:SetText("")
	
	ArmorGem_Gilding_NeedItem:SetActionItem(-1)
	
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

		local iStar = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "STAR")
		local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
		local iJewelLevel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL_LEVEL")
		local iPlate = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "PLATE")
		local iPlateLevel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "PLATE_LEVEL")
		
		local jewel_name = DataPool:LuaFnGetUnderArmourJewelName(iJewel, iPlate)
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_160}", jewel_name)
		ArmorGem_Gilding_Before:SetText(strTemp)
			
		strTemp = DataPool:LuaFnGetUnderArmourJewelEffectDesc(tonumber(iJewel), iJewelLevel, iStar)
		ArmorGem_Gilding_AttrBefore1:SetText(strTemp)
		
		if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
			strTemp = DataPool:LuaFnGetUnderArmourPlateEffectDesc(tonumber(iPlate), iPlateLevel)
			ArmorGem_Gilding_AttrBefore2:SetText(strTemp)
			if g_Plate_ItemIndex > 0 then
				LifeAbility:Lock_Packet_ItemByID(g_Plate_ItemIndex, 0)
				g_Plate_ItemIndex = -1
			end
		end
		
		if g_Plate_ItemIndex > 0 then

			if g_PlateItem[g_Plate_ItemIndex] ~= nil then
				
				local have_bind_count = PlayerPackage:Lua_GetUnLockBindItemCount(g_Plate_ItemIndex)
				
				if have_bind_count > 0 then
					local itemAction = DataPool:CreateBindActionItemForShow(g_Plate_ItemIndex, 1)
					ArmorGem_Gilding_NeedItem:SetActionItem(itemAction:GetID())
				else
					local itemAction = DataPool:CreateActionItemForShow(g_Plate_ItemIndex, 1)
					ArmorGem_Gilding_NeedItem:SetActionItem(itemAction:GetID())
				end

				LifeAbility:Lock_Packet_ItemByID(g_Plate_ItemIndex, 1)

				ArmorGem_Gilding_Currency1Num:SetProperty("MoneyNumber", tostring(g_PlateItem[g_Plate_ItemIndex].needMoney))
				
				jewel_name = DataPool:LuaFnGetUnderArmourJewelName(iJewel, g_PlateItem[g_Plate_ItemIndex].pId)
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_162}", jewel_name)
				ArmorGem_Gilding_After:SetText(strTemp)

				strTemp = DataPool:LuaFnGetUnderArmourJewelEffectDesc(tonumber(iJewel), iJewelLevel, iStar)
				ArmorGem_Gilding_AttrAfter1:SetText(strTemp)
				
				strTemp = DataPool:LuaFnGetUnderArmourPlateEffectDesc(g_PlateItem[g_Plate_ItemIndex].pId, 0)
				ArmorGem_Gilding_AttrAfter2:SetText(strTemp)

			end

		end

	else
		g_Cur_Sel = 0
	end

end

function ArmorGem_Gilding_OnItemDragedDropFromBag(iBagIndex)
	
	if g_Cur_Sel == 0 then
		return
	end
	
	local item_table_index = PlayerPackage:GetItemTableIndex(iBagIndex)
	if g_PlateItem[item_table_index] == nil then
	--	PushDebugMessage("not plate")
		return
	end

	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{NJBZ_220816_252}")
		return
	end

	local iPlate = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "PLATE")
	if tonumber(iPlate) ~= nil and tonumber(iPlate) > 0 then
		PushDebugMessage("#{NJBZ_220816_169}")
		return
	end

	local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
	if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
		local jewel_qual = DataPool:LuaFnGetUnderArmourJewelQual(tonumber(iJewel))
		if jewel_qual ~= 1 then
			PushDebugMessage("#{NJBZ_220816_227}")
			return
		end
		
		if g_Plate_ItemIndex > 0 then
			LifeAbility:Lock_Packet_ItemByID(g_Plate_ItemIndex, 0)
		end
		g_Plate_ItemIndex = item_table_index

		ArmorGem_Gilding_Update()
	end	
end

function ArmorGem_Gilding_OnBagItemRClicked(iBagIndex)	
	ArmorGem_Gilding_OnItemDragedDropFromBag(iBagIndex)	
end

function ArmorGem_Gilding_NeedItem_OnRBClicked()
	if g_Plate_ItemIndex > 0 then
		LifeAbility:Lock_Packet_ItemByID(g_Plate_ItemIndex, 0)
		g_Plate_ItemIndex = -1
		ArmorGem_Gilding_UpdateSelect()
	end
end

function ArmorGem_Gilding_OnItemDragedDropAway()
	if g_Plate_ItemIndex > 0 then
		LifeAbility:Lock_Packet_ItemByID(g_Plate_ItemIndex, 0)
		g_Plate_ItemIndex = -1
		ArmorGem_Gilding_UpdateSelect()
	end
end

function ArmorGem_Gilding_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local iJewel = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "JEWEL")
		if tonumber(iJewel) ~= nil then
			if tonumber(iJewel) > 0 then
				g_Cur_Sel = iIndex
				ArmorGem_Gilding_UpdateSelect()
			end
		end
	end
end

function ArmorGem_Gilding_CloseClicked()
	this:Hide()
end

function ArmorGem_Gilding_CleanUp()

	g_Cur_Sel = 0

	ArmorGem_Gilding_Before:SetText("")
	ArmorGem_Gilding_After:SetText("")
	
	ArmorGem_Gilding_AttrBefore1:SetText("")
	ArmorGem_Gilding_AttrBefore2:SetText("")
	ArmorGem_Gilding_AttrAfter1:SetText("")
	ArmorGem_Gilding_AttrAfter2:SetText("")

	ArmorGem_Gilding_Currency1Num:SetProperty("MoneyNumber", "0")
	ArmorGem_Gilding_Currency2Num:SetProperty("MoneyNumber", "0")
	ArmorGem_Gilding_Currency3Num:SetProperty("MoneyNumber", "0")
	
	ArmorGem_Gilding_NeedItem:SetActionItem(-1)		
	if g_Plate_ItemIndex > 0 then
		LifeAbility:Lock_Packet_ItemByID(g_Plate_ItemIndex, 0)
	end
	g_Plate_ItemIndex = -1	
end

function ArmorGem_Gilding_OnHidden()
	ArmorGem_Gilding_CleanUp()
	m_ObjServerId = -1
end

function ArmorGem_Gilding_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_167}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourJewelPlate")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Cur_Sel - 1)
		Set_XSCRIPT_Parameter(2, g_Plate_ItemIndex)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function ArmorGem_Gilding_HelpClicked()

end
--Care Obj
function ArmorGem_Gilding_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_Gilding_Frame_On_ResetPos()
	if g_ArmorGem_Gilding_Frame_UnifiedPosition ~= nil then
		ArmorGem_Gilding_Frame:SetProperty("UnifiedPosition", g_ArmorGem_Gilding_Frame_UnifiedPosition)
	end
end

function ArmorGem_Gilding_GetPercentageString(num)	
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

function ArmorGem_Gilding_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end