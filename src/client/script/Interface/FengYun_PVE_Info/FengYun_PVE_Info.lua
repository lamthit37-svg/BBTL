-- 风云联动
-- 默认位置
local FengYun_PVE_Info_UnifiedPosition = nil
local FengYun_PVE_Info_UICommand = 33592302


function FengYun_PVE_Info_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Info_PreLoad()

function FengYun_PVE_Info_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == FengYun_PVE_Info_UICommand) then
		FengYun_PVE_Info_Show()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_PVE_Info_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Info_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Info_UnifiedPos()
	end
end -- end func FengYun_PVE_Info_OnEvent()

function FengYun_PVE_Info_OnLoad()
	FengYun_PVE_Info_UnifiedPosition = FengYun_PVE_Info_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Info_OnLoad()

-- 界面默认位置
function FengYun_PVE_Info_UnifiedPos()
	if (FengYun_PVE_Info_UnifiedPosition ~= nil) then
		FengYun_PVE_Info_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Info_UnifiedPosition)
	end
end -- end func FengYun_PVE_Info_UnifiedPos()

function FengYun_PVE_Info_Show()
	if IsWindowShow("FengYun_PVE_InfoMini") then
		this:Hide()
		return
	end

	local leftTime = Get_XParam_INT(0)
	local teamPoint = Get_XParam_INT(1)

	-- 团队价值
	local szPoint = ScriptGlobal_Format("#{FYPVE_260108_91}", teamPoint)
	FengYun_PVE_Info_BottomText:SetText(szPoint)

	if leftTime > 0 then
		FengYun_PVE_Info_StopWatch:SetProperty("Timer", leftTime)
	else
		FengYun_PVE_Info_StopWatch:SetProperty("Timer", 0)
	end
	FengYun_PVE_Info_StopWatch:SetProperty("TextColor", "FF00FF00")

    this:Show()
end -- end func FengYun_PVE_Info_Show()

function FengYun_PVE_Info_Hide()
    this:Hide()
end -- end func FengYun_PVE_Info_Hide()

function FengYun_PVE_Info_Btn_Clicked()
	PushEvent("FYPVE_INFOMINIOPEN")
end -- end func FengYun_PVE_Info_Btn_Clicked()

function FengYun_PVE_Info_OnHide()

end