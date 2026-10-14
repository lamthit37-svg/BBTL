-- 全民8星 开炉打造
-- !!!reloadscript =StarEquip_Orientation

local g_StarEquip_DaZaoIdx = -1
local g_StarEquip_Orientation_Idx = -1
local g_StarEquip_CurSelEquipLevel = -1
local g_StarEquip_CurSelEquipPoint = -1
local g_StarEquip_CurSelEquipType = -1

local g_StarEquip_Orientation_Frame_UnifiedPosition = nil

local g_StarEquip_LevelList = {
[1] = "#{XFXB_230823_39}",
[2] = "#{XFXB_230823_40}",
[3] = "#{XFXB_230823_41}",
[4] = "#{XFXB_230823_42}",
[5] = "#{XFXB_230823_43}",
[6] = "#{XFXB_230823_44}",
[7] = "#{XFXB_230823_45}",
[8] = "#{XFXB_230823_46}",
[9] = "#{XFXB_230823_47}",
[10] = "#{XFXB_230823_48}",
}

local g_StarEquip_Type = {
[1] = {15,3,4,5},
[2] = {14,6,12},
[3] = {15,3,4,5},
[4] = {14,6,12},
}

local g_StarEquip_PointList = {
[15] = "#{XFXB_230823_49}",
[14] = "#{XFXB_230823_50}",
[3] = "#{XFXB_230823_51}",
[5] = "#{XFXB_230823_52}",
[4] = "#{XFXB_230823_53}",
[6] = "#{XFXB_230823_54}",
[12] = "#{XFXB_230823_55}",
}

function StarEquip_Orientation_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("QM8X_UPDATA_MAINUI",false);
	
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	
end

function StarEquip_Orientation_OnLoad()

	g_StarEquip_Orientation_Frame_UnifiedPosition = StarEquip_Orientation_Frame:GetProperty("UnifiedPosition");

end

function StarEquip_Orientation_OnEvent(event)

	if (event == "UI_COMMAND") and  tonumber(arg0) == 99884701 then
	
		local g_nUIType	= Get_XParam_INT(0) 
		if 1 ~= g_nUIType then
			StarEquip_Orientation_OnClosed()
			return
		end
		
		g_StarEquip_DaZaoIdx = Get_XParam_INT(1) 
		if g_StarEquip_Type[g_StarEquip_DaZaoIdx] == nil then 
			StarEquip_Orientation_OnClosed()
			return
		end

		StarEquip_Orientation_Clear()
		
		StarEquip_Orientation_Show()
		
		StarEquip_Orientation_Frame:SetForce()
		
		this:Show()
		
	elseif (event == "QM8X_UPDATA_MAINUI") then
	
		if this:IsVisible() then
			StarEquip_Orientation_OnClosed()
			return
		end
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		StarEquip_Orientation_OnClosed()
			
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS") then
		StarEquip_Orientation_ResetPos()
		
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		StarEquip_Orientation_ResetPos()
	end
	
end

function StarEquip_Orientation_Show()
	
	for i = 1, table.getn(g_StarEquip_LevelList) do
		if i == 1 then
			StarEquip_Orientation_EquipLevelList:AddTextItem(g_StarEquip_LevelList[i], i)	
		else
			StarEquip_Orientation_EquipLevelList:AddTextItem(g_StarEquip_LevelList[i], (i-1)*10)	
		end
	end
	
	for i,v in ipairs(g_StarEquip_Type[g_StarEquip_DaZaoIdx]) do
		StarEquip_Orientation_EquipPartList:AddTextItem(g_StarEquip_PointList[v], v)		
	end 
	
end

function StarEquip_Orientation_OK_Clicked()

	if g_StarEquip_CurSelEquipLevel == -1 then
		PushDebugMessage("#{XFXB_230823_57}")
		return
	end

	if g_StarEquip_CurSelEquipPoint == -1 then
		PushDebugMessage("#{XFXB_230823_58}")
		return
	end

	if g_StarEquip_CurSelEquipType == -1 then
		PushDebugMessage("#{XFXB_230823_56}")
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("KaiLuDaZao");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_Parameter(0, g_StarEquip_DaZaoIdx);
		Set_XSCRIPT_Parameter(1, g_StarEquip_Orientation_Idx)
		Set_XSCRIPT_Parameter(2, g_StarEquip_CurSelEquipLevel)
		Set_XSCRIPT_Parameter(3, g_StarEquip_CurSelEquipPoint)
		Set_XSCRIPT_Parameter(4, g_StarEquip_CurSelEquipType)
		Set_XSCRIPT_ParamCount(5);
	Send_XSCRIPT();		
	
end

function StarEquip_Orientation_Update()

	if g_StarEquip_CurSelEquipLevel == -1 or g_StarEquip_CurSelEquipPoint == -1 then
		return
	end

	StarEquip_Orientation_ClearType()
	
	local nEquipId = {0}
	g_StarEquip_Orientation_Idx, nEquipId[1],nEquipId[2],nEquipId[3],nEquipId[4],nEquipId[5] = Player:LuaFnGetQM8XEquipId(g_StarEquip_CurSelEquipLevel, g_StarEquip_CurSelEquipPoint)
	if g_StarEquip_Orientation_Idx > 0 then
		StarEquip_Orientation_EquipTypeList:Enable()	
		StarEquip_Orientation_EquipTypeList:SetText("#{XFXB_230823_37}")
		for i = 1, 5 do
			if nEquipId[i] > 0 then
				local itemname = PlayerPackage:GetEquipItemName(nEquipId[i]);
				StarEquip_Orientation_EquipTypeList:AddTextItem(itemname, nEquipId[i])
			end
		end
	end
	
end

function StarEquip_Orientation_ClearType()

	g_StarEquip_CurSelEquipType = -1
	
	StarEquip_Orientation_EquipTypeList:ResetList()
	StarEquip_Orientation_EquipTypeList:ResetText()
	StarEquip_Orientation_EquipTypeList:ResetLastSelectIndex()
	StarEquip_Orientation_EquipTypeList:Disable()
	StarEquip_Orientation_EquipTypeList:SetText("#{XFXB_230823_75}")
	
end	

function StarEquip_Orientation_ClearPart()

	g_StarEquip_CurSelEquipPoint = -1

	StarEquip_Orientation_EquipPartList:ResetList()
	StarEquip_Orientation_EquipPartList:ResetText()
	StarEquip_Orientation_EquipPartList:ResetLastSelectIndex()
	StarEquip_Orientation_EquipPartList:SetText("#{XFXB_230823_37}")
	
end

function StarEquip_Orientation_ClearLevel()

	g_StarEquip_CurSelEquipLevel = -1

	StarEquip_Orientation_EquipLevelList:ResetList()
	StarEquip_Orientation_EquipLevelList:ResetText()
	StarEquip_Orientation_EquipLevelList:ResetLastSelectIndex()
	StarEquip_Orientation_EquipLevelList:SetText("#{XFXB_230823_37}")
	
end

function StarEquip_Orientation_Clear()

	StarEquip_Orientation_ClearLevel()
	
	StarEquip_Orientation_ClearPart()

	StarEquip_Orientation_ClearType()
	
end

function StarEquip_Orientation_EquipLevelSel()

	local _,nIndex = StarEquip_Orientation_EquipLevelList:GetCurrentSelect()
	
	if g_StarEquip_CurSelEquipLevel ~= nIndex then
		g_StarEquip_CurSelEquipLevel = nIndex
	end
	
	if g_StarEquip_CurSelEquipLevel ~= -1 and g_StarEquip_CurSelEquipPoint ~= -1 then
		StarEquip_Orientation_Update()
	end
	
end

function StarEquip_Orientation_EquipPointSel()

	local _,nIndex = StarEquip_Orientation_EquipPartList:GetCurrentSelect()
	
	if g_StarEquip_CurSelEquipPoint ~= nIndex then
		g_StarEquip_CurSelEquipPoint = nIndex
	end
	
	if g_StarEquip_CurSelEquipLevel ~= -1 and g_StarEquip_CurSelEquipPoint ~= -1 then
		StarEquip_Orientation_Update()
	end
	
end

function StarEquip_Orientation_EquipTypeSel()

	if g_StarEquip_CurSelEquipLevel == -1 then
		PushDebugMessage("#{XFXB_230823_57}")
		return
	end

	if g_StarEquip_CurSelEquipPoint == -1 then
		PushDebugMessage("#{XFXB_230823_58}")
		return
	end

	local _,nIndex = StarEquip_Orientation_EquipTypeList:GetCurrentSelect()
	
	if g_StarEquip_CurSelEquipType ~= nIndex then
		g_StarEquip_CurSelEquipType = nIndex
	end
	
end

function StarEquip_Orientation_PreClick()

	if g_StarEquip_CurSelEquipLevel == -1 then
		PushDebugMessage("#{XFXB_230823_57}")
		return
	end

	if g_StarEquip_CurSelEquipPoint == -1 then
		PushDebugMessage("#{XFXB_230823_58}")
		return
	end
	
end

function StarEquip_Orientation_OnHidden()
	StarEquip_Orientation_Clear()
end

function StarEquip_Orientation_OnClosed()
	StarEquip_Orientation_Clear()
	this:Hide()
end

function StarEquip_Orientation_ResetPos()
	StarEquip_Orientation_Frame:SetProperty("UnifiedPosition", g_StarEquip_Orientation_Frame_UnifiedPosition)	
end


