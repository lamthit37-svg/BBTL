-----HLDF_Tips
local g_HLDF_Tips_Data = {}
local g_HLDF_Tips_floor = 0
local g_HLDF_Tips_UnifiedPosition;

function HLDF_Tips_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")		
end
--界面21点50到24点显示
function HLDF_Tips_OnLoad()	


	g_HLDF_Tips_UnifiedPosition  =HLDF_Tips_Frame:GetProperty("UnifiedPosition");
end

function HLDF_Tips_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 99973101 then
	--PushDebugMessage("HLDF_Tips")
		local flashtype = Get_XParam_INT(0)
		local restsec =  Get_XParam_INT(1);
		local nHumanNum = Get_XParam_INT(2)
		local nExpParam = Get_XParam_INT(3)
		local sceneName = Get_XParam_STR(0)
		if sceneName ~= "" then
			HLDF_Tips_DragTitle:SetText("#gFF0FA0"..sceneName)
		end
		if flashtype == 1000 then --关闭
			this:Hide()
			return
		end

		HLDF_Tips_InitFrame(restsec,nHumanNum,nExpParam)
		this:Show()
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		HLDF_Tips_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HLDF_Tips_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
		
end

function HLDF_Tips_On_ResetPos()
	HLDF_Tips_Frame:SetProperty("UnifiedPosition", g_HLDF_Tips_UnifiedPosition);
end

function HLDF_Tips_InitFrame(restsec,nHumanNum,nExpParam)
    HLDF_Tips_PlayerNumNow:SetText(ScriptGlobal_Format( "#{DFWF_250728_44}",nHumanNum))
    local exprate = "100%"
    if nExpParam == 1 then
        exprate = "10%"
    end
    HLDF_Tips_EXPNow:SetText(ScriptGlobal_Format( "#{DFWF_250728_45}",exprate))

	HLDF_Tips_TimeNow:SetProperty("TextColor","FB00FF00")
	HLDF_Tips_TimeNow:SetProperty("Timer",tostring(restsec))

end

function HLDF_Tips_Help_Clicked()
	PushEvent("CCSHOP_HELP", 237)
end