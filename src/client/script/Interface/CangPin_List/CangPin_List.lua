--CangPin_List
--!!!reloadscript =CangPin_List

local g_CangPin_List_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_InitList = 0

local g_MaxBarNum = 100

local g_BarList = {}

local g_CurRankType = 0

local g_ClassCount = 4
local g_SunShineBonusLevel = 6
local g_LimitLevel = 30

function CangPin_List_PreLoad()
	this:RegisterEvent("CANGPIN_RANK_SHOWLIST", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function CangPin_List_OnLoad()
	g_CangPin_List_Frame_UnifiedPosition = CangPin_List_Frame:GetProperty("UnifiedPosition")
end

function CangPin_List_OnEvent(event)

	if event == "CANGPIN_RANK_SHOWLIST" then
		if not this:IsVisible() then
			local obj_id = tonumber(arg0)
			g_CurRankType = 0
			this:Show()
			CangPin_List_Update()
			CangPin_List_BeginCareObj(obj_id)
		else
			local obj_id = tonumber(arg0)
			this:Activate()
			CangPin_List_Update()
			CangPin_List_BeginCareObj(obj_id)
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_List_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
end

function CangPin_List_OnShow()

end

function CangPin_List_InitList()
	if g_InitList == 0 then
		
		for i = 1, g_MaxBarNum do
			local bar = CangPin_List_List:AddChild("CangPin_List_ListItem")
		--	bar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
			g_BarList[i] = bar
			
			bar:GetSubItem("CangPin_List_ListItem_Text1"):SetText(tostring(i))
		--	bar:GetSubItem("CangPin_List_ListItem_Icon"):SetEvent("MouseLButtonDown", string.format("CangPin_List_SetSelect(%d)", i))
		end

		g_InitList = 1
	end
end

function CangPin_List_Update()

	if g_CurRankType == 0 then
		CangPin_List_DragTitle:SetText("#{CPPH_20260417_3}")
		CangPin_List_Info:SetText("#{CPPH_20260417_4}")
		CangPin_List_PageTab1:SetCheck(1)
		CangPin_List_PageTab2:SetCheck(0)
	else
		CangPin_List_DragTitle:SetText("#{CPPH_20260417_17}")
		CangPin_List_Info:SetText("#{CPPH_20260417_18}")
		CangPin_List_PageTab1:SetCheck(0)
		CangPin_List_PageTab2:SetCheck(1)
	end
	
	CangPin_List_Update_UpdateList()
	CangPin_List_Update_PlayerInfo()
end

function CangPin_List_Update_UpdateList()
	CangPin_List_InitList()
	
	for i = 1, g_MaxBarNum do
		bar = g_BarList[i]
		if bar ~= nil then
			local is_empty = DataPool:LuaFnGetCangPinRankData(g_CurRankType, i - 1, "IsEmpty")
			if is_empty == 1 then
				bar:GetSubItem("CangPin_List_ListItem_Text2"):SetText("")
				bar:GetSubItem("CangPin_List_ListItem_Text3"):SetText("")
				bar:GetSubItem("CangPin_List_ListItem_Text4"):SetText("")
				bar:GetSubItem("CangPin_List_ListItem_Icon"):SetActionItem(-1)
				bar:GetSubItem("CangPin_List_ListItem_Icon"):Hide()
				bar:GetSubItem("CangPin_List_ListItemBK2"):Show("")
			else
				bar:GetSubItem("CangPin_List_ListItem_Text2"):SetText("")
				bar:GetSubItem("CangPin_List_ListItem_Text3"):SetText("")
				bar:GetSubItem("CangPin_List_ListItem_Text4"):SetText("")
				bar:GetSubItem("CangPin_List_ListItem_Icon"):SetActionItem(-1)
				bar:GetSubItem("CangPin_List_ListItem_Icon"):Show()
				bar:GetSubItem("CangPin_List_ListItemBK2"):Hide("")
				
				local player_name = DataPool:LuaFnGetCangPinRankData(g_CurRankType, i - 1, "PlayerName")
				local col_value = DataPool:LuaFnGetCangPinRankData(g_CurRankType, i - 1, "ColValue")
				local ranking = DataPool:LuaFnGetCangPinRankData(g_CurRankType, i - 1, "Ranking")
				
				bar:GetSubItem("CangPin_List_ListItem_Text2"):SetText(tostring(player_name))
				bar:GetSubItem("CangPin_List_ListItem_Text3"):SetText(tostring(col_value))				
				
				local bonus_lv = LuaFnGetCangPinRankBonusLevel(g_CurRankType, ranking)
				bar:GetSubItem("CangPin_List_ListItem_Text4"):SetText(tostring(bonus_lv))
				
				local bonus_name, dummy_item = LuaFnGetCangPinRankBonusInfo(g_CurRankType, bonus_lv)
				local theAction = DataPool:CreateActionItemForShow(dummy_item, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem("CangPin_List_ListItem_Icon"):SetActionItem(theAction:GetID())
				end
				
			end
		end
		
	end
	
	CangPin_List_List:RefreshLayout()
end

function CangPin_List_Update_PlayerInfo()

	CangPin_List_MySelfList_Text1:SetText("")
	CangPin_List_MySelfList_Text2:SetText("")
	CangPin_List_MySelfList_Text3:SetText("")
	CangPin_List_MySelfList_Text4:SetText("")
	CangPin_List_MySelfList_Icon:SetActionItem(-1)
	CangPin_List_MySelfList_Icon:Hide()
	
	local can_golden_rank = DataPool:LuaFnIsHaveEligibilityOfCangPinRank(0)
	local can_silver_rank = DataPool:LuaFnIsHaveEligibilityOfCangPinRank(1)
	
	local in_rank_type, in_rank_index = DataPool:LuaFnGetPlayerCangPinRankInfo()
	local strTemp = ""
	
	local player_name = Player:GetName()
	local col_value = 0
	for i = 1, g_ClassCount do
		local collect_val = DataPool:LuaFnGetCangPinClassCollectValue(i - 1)
		col_value = col_value + collect_val
	end
	
	CangPin_List_MySelfList_Text2:SetText(tostring(player_name))
	CangPin_List_MySelfList_Text3:SetText(tostring(col_value))

	if g_CurRankType == 0 then
		if in_rank_type == 0 then
			CangPin_List_MySelfList_Text1:SetText(tostring(in_rank_index + 1))			
			
			local ranking = DataPool:LuaFnGetCangPinRankData(in_rank_type, in_rank_index, "Ranking")
			local bonus_lv = LuaFnGetCangPinRankBonusLevel(in_rank_type, ranking)
			CangPin_List_MySelfList_Text4:SetText(tostring(bonus_lv))
			
			CangPin_List_MySelfList_Icon:Show()
			local bonus_name, dummy_item = LuaFnGetCangPinRankBonusInfo(in_rank_type, bonus_lv)
			local theAction = DataPool:CreateActionItemForShow(dummy_item, 1)
			if theAction:GetID() ~= 0 then
				CangPin_List_MySelfList_Icon:SetActionItem(theAction:GetID())
			end
		else
			if can_golden_rank == 1 then
				CangPin_List_MySelfList_Text1:SetText("100+")
				
				local bonus_lv = g_SunShineBonusLevel
				CangPin_List_MySelfList_Text4:SetText(tostring(bonus_lv))
				
				CangPin_List_MySelfList_Icon:Show()
				local bonus_name, dummy_item = LuaFnGetCangPinRankBonusInfo(0, bonus_lv)
				local theAction = DataPool:CreateActionItemForShow(dummy_item, 1)
				if theAction:GetID() ~= 0 then
					CangPin_List_MySelfList_Icon:SetActionItem(theAction:GetID())
				end
			else
				CangPin_List_MySelfList_Text1:SetText("#{CPPH_20260417_13}")
			end
		end
	elseif g_CurRankType == 1 then
		if in_rank_type == 0 or in_rank_type == 1 then
			if in_rank_type == 0 then
				CangPin_List_MySelfList_Text1:SetText("#{CPPH_20260417_19}")
			elseif in_rank_type == 1 then
				CangPin_List_MySelfList_Text1:SetText(tostring(in_rank_index + 1))
			end

			local ranking = DataPool:LuaFnGetCangPinRankData(in_rank_type, in_rank_index, "Ranking")
			local bonus_lv = LuaFnGetCangPinRankBonusLevel(in_rank_type, ranking)
			CangPin_List_MySelfList_Text4:SetText(tostring(bonus_lv))
			
			CangPin_List_MySelfList_Icon:Show()
			local bonus_name, dummy_item = LuaFnGetCangPinRankBonusInfo(in_rank_type, bonus_lv)
			local theAction = DataPool:CreateActionItemForShow(dummy_item, 1)
			if theAction:GetID() ~= 0 then
				CangPin_List_MySelfList_Icon:SetActionItem(theAction:GetID())
			end
		else
			if can_golden_rank == 1 then
				CangPin_List_MySelfList_Text1:SetText("#{CPPH_20260417_19}")
				
				local bonus_lv = g_SunShineBonusLevel
				CangPin_List_MySelfList_Text4:SetText(tostring(bonus_lv))
				
				CangPin_List_MySelfList_Icon:Show()
				local bonus_name, dummy_item = LuaFnGetCangPinRankBonusInfo(0, bonus_lv)
				local theAction = DataPool:CreateActionItemForShow(dummy_item, 1)
				if theAction:GetID() ~= 0 then
					CangPin_List_MySelfList_Icon:SetActionItem(theAction:GetID())
				end
			elseif can_silver_rank == 1 then
				CangPin_List_MySelfList_Text1:SetText("100+")
				
				local bonus_lv = g_SunShineBonusLevel
				CangPin_List_MySelfList_Text4:SetText(tostring(bonus_lv))
				
				CangPin_List_MySelfList_Icon:Show()
				local bonus_name, dummy_item = LuaFnGetCangPinRankBonusInfo(1, bonus_lv)
				local theAction = DataPool:CreateActionItemForShow(dummy_item, 1)
				if theAction:GetID() ~= 0 then
					CangPin_List_MySelfList_Icon:SetActionItem(theAction:GetID())
				end
			else
				CangPin_List_MySelfList_Text1:SetText("#{CPPH_20260417_13}")
			end
		end
	end
	
	local last_bonus = Lua_GetMissionData(3450)
	local last_rank_type = math.floor(last_bonus / 1000)
	local last_bonus_level = math.mod(last_bonus, 1000)
	if last_bonus == 0 then
		CangPin_List_BottomFrame_Text2:Show()
		CangPin_List_BottomFrame_Text2:SetText("#{CPPH_20260417_15}")
		CangPin_List_BottomFrame_Icon:Hide()
	else
		CangPin_List_BottomFrame_Text2:Hide()
		CangPin_List_BottomFrame_Icon:Show()
		local bonus_name, dummy_item = LuaFnGetCangPinRankBonusInfo(last_rank_type, last_bonus_level)
		local theAction = DataPool:CreateActionItemForShow(dummy_item, 1)
		if theAction:GetID() ~= 0 then
			CangPin_List_BottomFrame_Icon:SetActionItem(theAction:GetID())
		end
	end
end

function CangPin_List_SetSelect(idx)
	local set_id = g_SetList[g_CurClass][idx]
	if set_id == nil then
		return
	end

	g_CurSet = set_id
	CangPin_List_SetClassSelected(idx)
	
	g_CurCangPinPage = 0
	CangPin_List_Update_CangPinList()
	CangPin_List_Update_SetInfo()
end

function CangPin_List_PageTabClicked(idx)
	if idx ~= g_CurRankType then
		g_CurRankType = idx
		CangPin_List_Update()
	end
end

function CangPin_List_HelpClicked()
	PushEvent("OPEN_SWEEPPAGE_QUEST", "CangPin_List_Help")
end

function CangPin_List_OpenBonusUI()
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CPPH_20260417_2}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenCangPinRankBonus")
		Set_XSCRIPT_ScriptID(885554)
		Set_XSCRIPT_Parameter(0, m_ObjServerId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function CangPin_List_CloseClicked()
	this:Hide()
end

function CangPin_List_CleanUp()
	g_CurSet = -1
end

function CangPin_List_OnHidden()
	CangPin_List_CleanUp()
	m_ObjServerId = -1
end

--Care Obj
function CangPin_List_BeginCareObj(obj_id)	
	m_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function CangPin_List_Frame_On_ResetPos()
	if g_CangPin_List_Frame_UnifiedPosition ~= nil then
		CangPin_List_Frame:SetProperty("UnifiedPosition", g_CangPin_List_Frame_UnifiedPosition)
	end
end
