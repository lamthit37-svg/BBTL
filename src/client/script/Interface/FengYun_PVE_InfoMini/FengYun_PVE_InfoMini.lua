-- 风云联动
-- 默认位置
local FengYun_PVE_InfoMini_UnifiedPosition = nil
local FengYun_PVE_InfoMini_ScriptId = 335927


function FengYun_PVE_InfoMini_PreLoad()
	this:RegisterEvent("FYPVE_INFOMINIOPEN", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_InfoMini_PreLoad()

function FengYun_PVE_InfoMini_OnEvent(event)
	if (event == "FYPVE_INFOMINIOPEN") then
		FengYun_PVE_InfoMini_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_InfoMini_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_InfoMini_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_InfoMini_UnifiedPos()
	end
end -- end func FengYun_PVE_InfoMini_OnEvent()

function FengYun_PVE_InfoMini_OnLoad()
	FengYun_PVE_InfoMini_UnifiedPosition = FengYun_PVE_InfoMini_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_InfoMini_OnLoad()

-- 界面默认位置
function FengYun_PVE_InfoMini_UnifiedPos()
	if (FengYun_PVE_InfoMini_UnifiedPosition ~= nil) then
		FengYun_PVE_InfoMini_Frame:SetProperty("UnifiedPosition", FengYun_PVE_InfoMini_UnifiedPosition)
	end
end -- end func FengYun_PVE_InfoMini_UnifiedPos()

function FengYun_PVE_InfoMini_Show()
	if IsWindowShow("FengYun_PVE_Info") then
		CloseWindow("FengYun_PVE_Info", true)
	end


    this:Show()
end -- end func FengYun_PVE_InfoMini_Show()

function FengYun_PVE_InfoMini_Hide()
    this:Hide()
end -- end func FengYun_PVE_InfoMini_Hide()


function FengYun_PVE_InfoMini_Open()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskDetailInfo")
		Set_XSCRIPT_ScriptID(FengYun_PVE_InfoMini_ScriptId)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	this:Hide()
end-- end func FengYun_PVE_InfoMini_Open()