-- 风云联动
-- 默认位置
local FengYun_PVE_Guide_UnifiedPosition = nil
local FengYun_PVE_Guide_ScriptId = 335927
local FengYun_PVE_Guide_UICommand = 33592301

function FengYun_PVE_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS", false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Guide_PreLoad()

function FengYun_PVE_Guide_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == FengYun_PVE_Guide_UICommand) then
		FengYun_PVE_Guide_Show()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Guide_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Guide_UnifiedPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		FengYun_PVE_Guide_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if FYPVE:IsInFYPVEScene() ~= 1 then
			FengYun_PVE_Guide_Hide()
		end
	end
end -- end func FengYun_PVE_Guide_OnEvent()

function FengYun_PVE_Guide_OnLoad()
	FengYun_PVE_Guide_UnifiedPosition = FengYun_PVE_Guide_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Guide_OnLoad()

-- 界面默认位置
function FengYun_PVE_Guide_UnifiedPos()
	if (FengYun_PVE_Guide_UnifiedPosition ~= nil) then
		FengYun_PVE_Guide_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Guide_UnifiedPosition)
	end
end -- end func FengYun_PVE_Guide_UnifiedPos()

function FengYun_PVE_Guide_Show()
    this:Show()
end -- end func FengYun_PVE_Guide_Show()

function FengYun_PVE_Guide_Hide()
    this:Hide()
end -- end func FengYun_PVE_Guide_Hide()

function CJ_Btn_ResetPos()
	CJ_Btn_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function FengYun_PVE_Guide_BackpackButton_OnClick()
	if IsWindowShow("FengYun_PVE_Backpack") then
		CloseWindow("FengYun_PVE_Backpack", true)
		return 
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskOpenBag")
		Set_XSCRIPT_ScriptID(FengYun_PVE_Guide_ScriptId)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end-- end func FengYun_PVE_Guide_BackpackButton_OnClick()

