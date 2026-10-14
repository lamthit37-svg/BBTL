--ArmorGem_Change
--!!!reloadscript =ArmorGem_Change

local g_ArmorGem_Change_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Cur_Sel = 1

local g_UA_ExAttr_Before = {}
local g_UA_ExAttr_After = {}
local g_UA_Embed_Button = {}
local g_UA_Split_Button = {}

local g_UI_Type = 1
local g_Jewel_BagIndex = -1

local g_Embed_Need_Money = 100000
local g_Split_Need_Money = 100000

function ArmorGem_Change_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("UA_DATA_UPDATE", false)
	
	this:RegisterEvent("UA_JEWEL_EMBED_PUTIN", false)
	this:RegisterEvent("UA_JEWEL_EMBED_RCLICK", false)
	this:RegisterEvent("UA_JEWEL_EMBED_REMOVE", false)
end

function ArmorGem_Change_OnLoad()
	g_ArmorGem_Change_Frame_UnifiedPosition = ArmorGem_Change_Frame:GetProperty("UnifiedPosition")
	
	g_UA_Embed_Button[1] = ArmorGem_Change_Enchase_Choose_Item1
	g_UA_Embed_Button[2] = ArmorGem_Change_Enchase_Choose_Item2
	g_UA_Embed_Button[3] = ArmorGem_Change_Enchase_Choose_Item3
	
	g_UA_Split_Button[1] = ArmorGem_Change_Split_Choose_Item1
	g_UA_Split_Button[2] = ArmorGem_Change_Split_Choose_Item2
	g_UA_Split_Button[3] = ArmorGem_Change_Split_Choose_Item3	
	
end

function ArmorGem_Change_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 55500105 then
		if not this:IsVisible() then
			g_UI_Type = 1
			ArmorGem_Change_CleanUp(g_UI_Type)
			this:Show()
			ArmorGem_Change_Update()
			ArmorGem_Change_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "UA_DATA_UPDATE" then
		ArmorGem_Change_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ArmorGem_Change_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		ArmorGem_Change_Enchase_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_Change_Enchase_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		
		ArmorGem_Change_Split_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		ArmorGem_Change_Split_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		return
	end

	if event == "UA_JEWEL_EMBED_PUTIN" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Change_OnItemDragedDropFromBag(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_JEWEL_EMBED_RCLICK" then
		if tonumber(arg0) ~= nil then
			ArmorGem_Change_OnBagItemRClicked(tonumber(arg0))
		end
		return
	end
	
	if event == "UA_JEWEL_EMBED_REMOVE" then
		ArmorGem_Change_OnItemDragedDropAway()
		return
	end
	
end

function ArmorGem_Change_Update()
	
	ArmorGem_Change_Enchase_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_Change_Enchase_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	ArmorGem_Change_Split_Currency2Num:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	ArmorGem_Change_Split_Currency3Num:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	
	if g_UI_Type == 1 then
		ArmorGem_Change_Page1:SetCheck(1)
		ArmorGem_Change_Page2:SetCheck(0)
		ArmorGem_Change_EnchaseFrame:Show()
		ArmorGem_Change_SplitFrame:Hide()
	else
		ArmorGem_Change_Page1:SetCheck(0)
		ArmorGem_Change_Page2:SetCheck(1)
		ArmorGem_Change_EnchaseFrame:Hide()
		ArmorGem_Change_SplitFrame:Show()
	end
	ArmorGem_Change_UpdateSelect()
end

function ArmorGem_Change_UpdateSelect()
	
	if g_UI_Type == 1 then

		ArmorGem_Change_DragTitle:SetText("#{NJBZ_220816_125}")
		ArmorGem_Change_Enchase_Currency1Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Change_Enchase_GemItem:SetActionItem(-1)
		ArmorGem_Change_Enchase_GemItemAnim:Hide()
		
		for i = 1, 3 do
			local bActived = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
			if bActived == 1 then
				g_UA_Embed_Button[i]:Enable()
			else
				g_UA_Embed_Button[i]:Disable()
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
				g_UA_Embed_Button[i]:SetCheck(1)
			else
				g_UA_Embed_Button[i]:SetCheck(0)
			end
		end

		if g_Cur_Sel >= 1 and g_Cur_Sel <= 3 then
			local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
			if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
				local itemAction = EnumAction(g_Cur_Sel - 1, "UnderArmourJewel")
				ArmorGem_Change_Enchase_GemItem:SetActionItem(itemAction:GetID())
			else
				if g_Jewel_BagIndex ~= -1 then
					local theAction = EnumAction(g_Jewel_BagIndex, "packageitem")
					ArmorGem_Change_Enchase_GemItem:SetActionItem(theAction:GetID())
					LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 1)
					ArmorGem_Change_Enchase_GemItemAnim:Show()

					ArmorGem_Change_Enchase_Currency1Num:SetProperty("MoneyNumber", tostring(g_Embed_Need_Money))
				end
			end
		else
			g_Cur_Sel = 0
		end
	else
		ArmorGem_Change_DragTitle:SetText("#{NJBZ_220816_254}")
		ArmorGem_Change_Split_Currency1Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Change_Split_GemItem:SetActionItem(-1)
		
		for i = 1, 3 do
			local bActived = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")
			if bActived == 1 then
				g_UA_Split_Button[i]:Enable()
			else
				g_UA_Split_Button[i]:Disable()
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
				g_UA_Split_Button[i]:SetCheck(1)
			else
				g_UA_Split_Button[i]:SetCheck(0)
			end
		end

		if g_Cur_Sel >= 1 and g_Cur_Sel <= 3 then
			local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
			if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
				local itemAction = EnumAction(g_Cur_Sel - 1, "UnderArmourJewel")
				ArmorGem_Change_Split_GemItem:SetActionItem(itemAction:GetID())
			end

			ArmorGem_Change_Split_Currency1Num:SetProperty("MoneyNumber", tostring(g_Embed_Need_Money))
		else
			g_Cur_Sel = 0
		end	
	end
end

--从背包拖拽到UI
function ArmorGem_Change_OnItemDragedDropFromBag(iBagIndex)
	
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_132}")
		return
	end

	if PlayerPackage:LuaFnIsUnderArmourJewel(iBagIndex) ~= 1 then
		return
	end

	--加锁
	if PlayerPackage:IsLock(iBagIndex) == 1 then
		PushDebugMessage("#{NJBZ_220816_252}")
		return
	end
	
	local iJewel = DataPool:LuaFnGetUnderArmourData(g_Cur_Sel - 1, "JEWEL")
	if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
		PushDebugMessage("#{NJBZ_220816_253}")
		return
	end

	--释放原来的道具
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
	end
	g_Jewel_BagIndex = iBagIndex

	ArmorGem_Change_Update()

end

function ArmorGem_Change_OnBagItemRClicked(iBagIndex)	
	if g_UI_Type ~= 1 then
		return
	end
	
	ArmorGem_Change_OnItemDragedDropFromBag(iBagIndex)	
end

function ArmorGem_Change_Enchase_AfterGemItem_OnRBClicked()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_Change_UpdateSelect()
	end
end

function ArmorGem_Change_OnItemDragedDropAway()
	if g_Jewel_BagIndex ~= -1 then
		LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		g_Jewel_BagIndex = -1
		ArmorGem_Change_UpdateSelect()
	end
end

function ArmorGem_Change_Enchase_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local bActived = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "ACTIVED")
		if bActived == 1 then
			g_Cur_Sel = iIndex
			if g_Jewel_BagIndex ~= -1 then
				LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
			end
			g_Jewel_BagIndex = -1
			ArmorGem_Change_UpdateSelect()
		end
	end
end

function ArmorGem_Change_Split_Choose_ItemClicked(iIndex)
	if g_Cur_Sel ~= iIndex then
		local bActived = DataPool:LuaFnGetUnderArmourData(iIndex - 1, "ACTIVED")
		if bActived == 1 then
			g_Cur_Sel = iIndex		
			ArmorGem_Change_UpdateSelect()
		end
	end
end

function ArmorGem_Change_PageClicked(iIndex)
	if g_UI_Type ~= iIndex then
		ArmorGem_Change_CleanUp(g_UI_Type)
		g_UI_Type = iIndex		
		ArmorGem_Change_Update()
	end
end

function ArmorGem_Change_CloseClicked()
	this:Hide()
end

function ArmorGem_Change_CleanUp(iType)

	g_Cur_Sel = 1

	if iType == 0 or iType == 1 then
		ArmorGem_Change_Enchase_Currency1Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Change_Enchase_Currency2Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Change_Enchase_Currency3Num:SetProperty("MoneyNumber", "0")
		
		ArmorGem_Change_Enchase_GemItem:SetActionItem(-1)

		if g_Jewel_BagIndex ~= -1 then
			LifeAbility:Lock_Packet_Item(g_Jewel_BagIndex, 0)
		end
		g_Jewel_BagIndex = -1
	end

	if iType == 0 or iType == 2 then
		ArmorGem_Change_Split_Currency1Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Change_Split_Currency2Num:SetProperty("MoneyNumber", "0")
		ArmorGem_Change_Split_Currency3Num:SetProperty("MoneyNumber", "0")

		ArmorGem_Change_Split_GemItem:SetActionItem(-1)		
	end	
end

function ArmorGem_Change_OnHidden()
	ArmorGem_Change_CleanUp(0)
	m_ObjServerId = -1
end

function ArmorGem_Change_Enchase_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_132}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourEmbed")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Cur_Sel - 1)
		Set_XSCRIPT_Parameter(2, g_Jewel_BagIndex)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function ArmorGem_Change_Split_OKClicked()
	if g_Cur_Sel == 0 then
		PushDebugMessage("#{NJBZ_220816_132}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555001)
		Set_XSCRIPT_Function_Name("UnderArmourSplit")
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_Cur_Sel - 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function ArmorGem_Change_HelpClicked()

end
--Care Obj
function ArmorGem_Change_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ArmorGem_Change_Frame_On_ResetPos()
	if g_ArmorGem_Change_Frame_UnifiedPosition ~= nil then
		ArmorGem_Change_Frame:SetProperty("UnifiedPosition", g_ArmorGem_Change_Frame_UnifiedPosition)
	end
end

function ArmorGem_Change_GetPercentageString(num)	
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

function ArmorGem_Change_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end