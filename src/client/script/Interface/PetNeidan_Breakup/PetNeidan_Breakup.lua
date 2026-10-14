--!!!reloadscript =PetNeidan_Breakup

local g_PetNeidan_Breakup_Frame_UnifiedPosition = ""
local g_posIndex = -1
local g_CurNum = 1
local g_MaxCount = 0
local g_PlayerLevelLimit = 60
local g_PreMissionID = 3000
local g_DanQiMax = 100000

function PetNeidan_Breakup_PreLoad()
	this:RegisterEvent("OPEN_BATCH_HUAQI")
	this:RegisterEvent("PACKET_NEIDAN_UPDATE", false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

function PetNeidan_Breakup_OnLoad()
	g_PetNeidan_Breakup_Frame_UnifiedPosition = PetNeidan_Breakup_Frame:GetProperty("UnifiedPosition")
end

function PetNeidan_Breakup_OnEvent(event)
	
	if event == "OPEN_BATCH_HUAQI" then
		local pos_index = tonumber(arg0)
		if PetNeidan_Breakup_Check(pos_index) ~= 1 then
			return
		end
		g_CurNum = 1
		g_posIndex	= pos_index
		PetNeidan_Breakup_Open()
		this:Activate()
	end	
	
	if event == "PACKET_NEIDAN_UPDATE" then
		this:Hide()
		return
	end
	
	if event == "PLAYER_ENTERING_WORLD" then
		this:Hide()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		if g_PetNeidan_Breakup_Frame_UnifiedPosition ~= nil then
			PetNeidan_Breakup_Frame:SetProperty("UnifiedPosition", g_PetNeidan_Breakup_Frame_UnifiedPosition)	
		end
	end
end

function PetNeidan_Breakup_Open()
	PushEvent("T3SHOP_BUY_ITEM_CONFIRM", "close")
	
	local pnd_name = DataPool:LuaFnGetPetNeiDanName(g_posIndex)
	PetNeidan_Breakup_ItemInfo_Text:SetText(tostring(pnd_name))	
	
	PetNeidan_Breakup_Item_Num:Hide()
	PetNeidan_Breakup_Item:SetActionItem(-1)
	local theAction = EnumAction(g_posIndex, "pnd")
	if theAction:GetID() ~= 0 then
		PetNeidan_Breakup_Item:SetActionItem(theAction:GetID())
	end
	
	PetNeidan_Breakup_InputNum:SetProperty("DefaultEditBox", "True")
	PetNeidan_Breakup_InputNum:SetText(tostring(g_CurNum))
	PetNeidan_Breakup_InputNum:SetSelected(0, -1)
	PetNeidan_Breakup_UpdateMaxCount()
	PetNeidan_Breakup_UpdateTokenInfo()
	this:Show()

end

function PetNeidan_Breakup_UpdateTokenInfo()
	
	local pnd_qual = DataPool:LuaFnGetPetNeiDanQual(g_posIndex)
	
	if pnd_qual == 0 then
		PetNeidan_Breakup_Yuanye:SetText("#{ZSND_230428_144}")
	elseif pnd_qual == 1 then
		PetNeidan_Breakup_Yuanye:SetText("#{ZSND_230428_143}")
	elseif pnd_qual == 2 then
		PetNeidan_Breakup_Yuanye:SetText("#{ZSND_230428_142}")
	else
		PetNeidan_Breakup_Yuanye:SetText("")
	end
	
	local total_add = g_CurNum * 15	
	PetNeidan_Breakup_YuanyeNUM:SetText(tostring(total_add))
	
	local danqi_i = Player:GetData("DANQI_I")
	local danqi_ii = Player:GetData("DANQI_II")
	local danqi_iii = Player:GetData("DANQI_III")
end

function PetNeidan_Breakup_UpdateMaxCount()	
	g_MaxCount = 0
	local pn_count = DataPool:LuaFnGetPetNeiDanCount(g_posIndex)
	if tonumber(pn_count) ~= nil and tonumber(pn_count) > 0 then
		g_MaxCount = pn_count
	end
	
end

function PetNeidan_Breakup_CalMax()
	PetNeidan_Breakup_UpdateMaxCount()	
	PetNeidan_Breakup_InputNum:SetText(tostring(g_MaxCount))
end

function PetNeidan_Breakup_TextChanged()
	
	local nString = PetNeidan_Breakup_InputNum:GetText()
	
	local nChangNum = 1
	
	if nString == nil or nString == "" then
		g_CurNum = 0
		--PetNeidan_Breakup_InputNum:SetText(tostring(g_CurNum))
		PetNeidan_Breakup_UpdateTokenInfo()
		return
	else
		nChangNum = tonumber(nString)
	end
	
	if nChangNum >= g_MaxCount then
		nChangNum = g_MaxCount
	end
	
	if nChangNum <= 0 then
		nChangNum = 1
	end
	
	if g_CurNum ~= tonumber(nString) then
		g_CurNum = nChangNum
		PetNeidan_Breakup_InputNum:SetText(tostring(g_CurNum))		
		PetNeidan_Breakup_UpdateTokenInfo()
	end
end

function PetNeidan_Breakup_Close_Clicked()
	this:Hide()
end

function PetNeidan_Breakup_OnHidden()
	g_CurNum = 1
	g_posIndex = -1
	PetNeidan_Breakup_Item:SetActionItem(-1)
	PetNeidan_Breakup_ItemInfo_Text:SetText("")
	
	PetNeidan_Breakup_Yuanye:SetText("")
	PetNeidan_Breakup_YuanyeNUM:SetText("")
end

function PetNeidan_Breakup_OK_Clicked()
	
	if tonumber(g_posIndex) == nil or tonumber(g_posIndex) < 0 then
		return
	end	
	
	local nString = PetNeidan_Breakup_InputNum:GetText()
	if nString == nil or nString == "" then
		return
	end
	
	if g_CurNum == 0 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PetNeiDan_HuaQi")
		Set_XSCRIPT_ScriptID(888562)
		Set_XSCRIPT_Parameter(0, tonumber(g_posIndex))
		Set_XSCRIPT_Parameter(1, g_CurNum)
		Set_XSCRIPT_Parameter(2, 1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	PetNeidan_Breakup_Close_Clicked()
end

function PetNeidan_Breakup_Check(pos_index)
	if tonumber(pos_index) == nil or tonumber(pos_index) < 0 then
		return 0
	end
	
	local my_level = Player:GetData("LEVEL")
	if my_level < g_PlayerLevelLimit then
		PushDebugMessage("#{ZSND_230428_60}")
		return 0
	end
	
	if DataPool:Lua_IsMissionHaveDone(g_PreMissionID) ~= 1 then
		PushDebugMessage("#{ZSND_230428_06}")
		return 0
	end
	
	local pnd_qual = DataPool:LuaFnGetPetNeiDanQual(tonumber(pos_index))
	local danqi_i = Player:GetData("DANQI_I")
	local danqi_ii = Player:GetData("DANQI_II")
	local danqi_iii = Player:GetData("DANQI_III")
	
	local add_danqi = 15
	
	if pnd_qual == 0 then
		if danqi_i >= g_DanQiMax then
			PushDebugMessage("#{ZSND_230428_80}")
			return 0
		end
		
		if danqi_i + add_danqi > g_DanQiMax then
			PushDebugMessage("#{ZSND_230428_83}")
			return 0
		end
	end
	
	if pnd_qual == 1 then
		if danqi_ii >= g_DanQiMax then
			PushDebugMessage("#{ZSND_230428_79}")
			return 0
		end
		
		if danqi_ii + add_danqi > g_DanQiMax then
			PushDebugMessage("#{ZSND_230428_82}")
			return 0
		end		
	end
	
	if pnd_qual == 2 then
		if danqi_iii >= g_DanQiMax then
			PushDebugMessage("#{ZSND_230428_78}")
			return 0
		end
		
		if danqi_iii + add_danqi > g_DanQiMax then
			PushDebugMessage("#{ZSND_230428_81}")
			return 0
		end
	end
	
	local pnd_level = DataPool:LuaFnGetPetNeiDanLevel(tonumber(pos_index))
	if pnd_level ~= 0 then
		PushDebugMessage("#{ZSND_230428_137}")
		return 0
	end
	
	return 1
end
