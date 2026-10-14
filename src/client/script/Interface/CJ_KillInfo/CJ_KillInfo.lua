-- 击杀界面

local g_unifiedposistion
local g_ui_command = 99932101
local g_ui_showtime = 3
local g_timer = 0

function CJ_KillInfo_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CJ_KillInfo_OnLoad()
	g_unifiedposistion = CJ_KillInfo_Frame:GetProperty("UnifiedPosition")
end

function CJ_KillInfo_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then
		CJ_KillInfo_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_KillInfo_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_KillInfo_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		CJ_KillInfo_CloseClicked()
	end

end

function CJ_KillInfo_OnShow()

	CJ_KillInfo_Left_Text:SetText("")
	CJ_KillInfo_Right_Text:SetText("")

	local killerName = Get_XParam_STR(0)
	local playerName = Get_XParam_STR(1)
	local killerWolrdId = Get_XParam_INT(0)
	local playerWolrdId = Get_XParam_INT(1)

	if killerWolrdId < 0 then
		CJ_KillInfo_Left_Text:SetText(killerName)
		CJ_KillInfo_Right_Text:SetText(playerName)
	else
		local killerFullName = CJ_KillInfo_TransformName(killerName, killerWolrdId)
		local playerFullName = CJ_KillInfo_TransformName(playerName, playerWolrdId)
		CJ_KillInfo_Left_Text:SetText(killerFullName)
		CJ_KillInfo_Right_Text:SetText(playerFullName)
	end
	-- 消失倒计时
	g_timer = g_ui_showtime

	KillTimer("CJ_KillInfo_Timer()")
	SetTimer("CJ_KillInfo","CJ_KillInfo_Timer()", 1*1000)

	this:Show()
end

function CJ_KillInfo_Timer()
	g_timer = g_timer - 1 
	if g_timer == 0 then
		KillTimer("CJ_KillInfo_Timer()")
		this:Hide()
	end
end

function CJ_KillInfo_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name

	local selfzoneid = DataPool:GetSelfZoneWorldID()
	if selfzoneid ~= zoneid then
		local serverName = DataPool:GetServerName( zoneid )
		retname = name.."@"..tostring(serverName)
	end

	return retname
end


--================================================
-- 关闭
--================================================
function CJ_KillInfo_CloseClicked()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_KillInfo_OnHide()
	KillTimer("CJ_KillInfo_Timer()")
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_KillInfo_ResetPos()
	CJ_KillInfo_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

