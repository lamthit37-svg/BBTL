--CangPin_ChaiJie
--!!!reloadscript =CangPin_ChaiJie

local g_CangPin_ChaiJie_Frame_UnifiedPosition = ""
local m_ObjServerId = -1
local g_InitList = 0
local g_MaxStar = 9
local g_MaxCangPinBarNum = 0
local g_CangPinBarList = {}
local g_MaxQual = 5

function CangPin_ChaiJie_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("OPEN_CANGPIN_MELT", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function CangPin_ChaiJie_OnLoad()
	g_CangPin_ChaiJie_Frame_UnifiedPosition = CangPin_ChaiJie_Frame:GetProperty("UnifiedPosition")
end

function CangPin_ChaiJie_OnEvent(event)

	if event == "OPEN_CANGPIN_MELT" then
		if not this:IsVisible() then
			--CangPin_ChaiJie_CleanUp()
			this:Show()
			CangPin_ChaiJie_Update()
		else
			this:Activate()
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_ChaiJie_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "CANGPIN_UPDATE" and this:IsVisible() then
		if arg0 == "melt" and tonumber(arg1) == 0 then
			this:Hide()
		end
		
		if arg0 == "melt" and tonumber(arg1) == 1 then
			CangPin_ChaiJie_Update()
		end
		return
	end
end

function CangPin_ChaiJie_InitList()
	if g_InitList == 0 then
		g_MaxCangPinBarNum = 0
		local all_set_count = LuaFnGetMaxCangPinSetCount()
		for i = 1, all_set_count do
			local set_id, class_id = LuaFnGetCangPinSetFromTable(i - 1)
			local uCangPinNum = LuaFnGetCangPinCountInSet(set_id)
			g_MaxCangPinBarNum = g_MaxCangPinBarNum + uCangPinNum
		end
		
		for i = 1, g_MaxCangPinBarNum do
			local bar = CangPin_ChaiJie_CangPinList:AddChild("CangPin_ChaiJie_CangPinListItem")
		--	bar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
			g_CangPinBarList[i] = bar
		end
		g_InitList = 1
	end
end

function CangPin_ChaiJie_Update()
	CangPin_ChaiJie_InitList()
	
	for i = 1, g_MaxCangPinBarNum do
		g_CangPinBarList[i]:Hide()
	end
	
	local ret_val_1 = 0
	local ret_val_2 = 0
	local barIndex = 1
	local all_set_count = LuaFnGetMaxCangPinSetCount()

	for qual = g_MaxQual, 1, -1 do
		for i = 1, all_set_count do
			local set_id, class_id = LuaFnGetCangPinSetFromTable(i - 1)
			local uCangPinNum = LuaFnGetCangPinCountInSet(set_id)
			for j = 1, uCangPinNum do
				local cangpin_id = LuaFnGetCangPinIdInSet(set_id, j - 1)
				if tonumber(cangpin_id) ~= nil and tonumber(cangpin_id) > 0 then
					local nQuality = DataPool:LuaFnGetCangPinData(cangpin_id, "Quality")
					if nQuality == qual then
						local nStar = DataPool:LuaFnGetCangPinData(cangpin_id, "Star")
						local nChipCount = DataPool:LuaFnGetCangPinData(cangpin_id, "ChipCount")
						local nTokenType = DataPool:LuaFnGetCangPinData(cangpin_id, "TokenType")
						local nTokenCount = DataPool:LuaFnGetCangPinData(cangpin_id, "TokenCount")
						if nStar >= g_MaxStar and nChipCount > 0 then
							if barIndex <= g_MaxCangPinBarNum then
								g_CangPinBarList[barIndex]:Show()
								local theAction = EnumAction(cangpin_id, "cangpin")
								if theAction:GetID() ~= 0 then
									g_CangPinBarList[barIndex]:GetSubItem("CangPin_ChaiJie_CangPin_ActionButton"):SetActionItem(theAction:GetID())
								end
								local strName = DataPool:LuaFnGetCangPinData(cangpin_id, "Name")
								g_CangPinBarList[barIndex]:GetSubItem("CangPin_ChaiJie_ItemName"):SetText(tostring(strName))

								local strChipCount = ScriptGlobal_Format("#{CPSJ_260112_47}", tostring(nChipCount))
								g_CangPinBarList[barIndex]:GetSubItem("CangPin_ChaiJie_CangPin_ActionButton_Num"):SetText(tostring(strChipCount))

								--local strBK = DataPool:LuaFnGetCangPinData(cangpin_id, "BKImage")
								--g_CangPinBarList[barIndex]:GetSubItem("CangPin_ChaiJie_CangPin_BKImage"):SetProperty("Image", tostring(strBK))
								
								barIndex = barIndex + 1
								
								if nTokenType == 0 then
									ret_val_1 = ret_val_1 + nChipCount * nTokenCount
								elseif nTokenType == 1 then
									ret_val_2 = ret_val_2 + nChipCount * nTokenCount
								end
							end
						end
					end
				end
			end
		end
	end

	CangPin_ChaiJie_CangPinList:RefreshLayout()
	
	local strTemp = ""
	strTemp = ScriptGlobal_Format("#{CPSJ_260112_50}", tostring(ret_val_1))
	CangPin_ChaiJie_NumText_1:SetText(tostring(ret_val_1))
	
	strTemp = ScriptGlobal_Format("#{CPSJ_260112_50}", tostring(ret_val_2))
	CangPin_ChaiJie_NumText_2:SetText(tostring(ret_val_2))
end

function CangPin_ChaiJie_CloseClicked()
	this:Hide()
end

function CangPin_ChaiJie_CleanUp()

end

function CangPin_ChaiJie_OnHidden()
	CangPin_ChaiJie_CleanUp()
	m_ObjServerId = -1
end

function CangPin_ChaiJie_OnOK()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MeltAllCangPinChip")
		Set_XSCRIPT_ScriptID(885555)
	--	Set_XSCRIPT_Parameter(0, cangpin_id)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--Care Obj
function CangPin_ChaiJie_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function CangPin_ChaiJie_Frame_On_ResetPos()
	if g_CangPin_ChaiJie_Frame_UnifiedPosition ~= nil then
		CangPin_ChaiJie_Frame:SetProperty("UnifiedPosition", g_CangPin_ChaiJie_Frame_UnifiedPosition)
	end
end
