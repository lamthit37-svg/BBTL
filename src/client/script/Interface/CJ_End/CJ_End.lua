-- 结果界面

local g_unifiedposistion
local g_ui_command = 99932104


function CJ_End_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)
end

function CJ_End_OnLoad()
	g_unifiedposistion = CJ_End_Frame:GetProperty("UnifiedPosition")
end

function CJ_End_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then
		CJ_End_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_End_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_End_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		CJ_End_CloseClicked()
	elseif(event == "PLAYER_LEAVE_WORLD") then
		CJ_End_CloseClicked()
	end

end

function CJ_End_OnShow()

	CJ_End_Win_Img:Hide()
	CJ_End_Lose_Img:Hide()
	local rank = Get_XParam_INT(0)
	if rank == 1 then
		CJ_End_Win_Img:Show()
	else
		CJ_End_Lose_Img:Show()
	end

	this:Show()
end

--================================================
-- 关闭
--================================================
function CJ_End_OnHide()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_End_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_End_ResetPos()
	CJ_End_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

