-- 任务界面最小化

local g_unifiedposistion

function CJ_MissionMini_PreLoad()
	this:RegisterEvent("TLCJ_BATTLE_MINSSIONMINIUI_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CJ_MissionMini_OnLoad()
	g_unifiedposistion = CJ_MissionMini_Frame:GetProperty("UnifiedPosition")
end

function CJ_MissionMini_OnEvent(event)

	if ( event == "TLCJ_BATTLE_MINSSIONMINIUI_SHOW" ) then
		CJ_MissionMini_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_MissionMini_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_MissionMini_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		CJ_MissionMini_CloseClicked()
	end

end

function CJ_MissionMini_OnShow()
	if IsWindowShow("CJ_Mission") then
		CloseWindow("CJ_Mission", true)
	end
	
	CJ_MissionMini_SetPosition()
	this:Show()

end

--================================================
-- 关闭
--================================================
function CJ_MissionMini_Open()
	CJ_MissionMini_SavePosition()
	this:Hide()
	PushEvent("TLCJ_BATTLE_MISSIONUI_SHOW")
end

--================================================
-- 关闭
--================================================
function CJ_MissionMini_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_MissionMini_ResetPos()
	CJ_MissionMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

--================================================
-- 存储位置
--================================================
function CJ_MissionMini_SavePosition()
	Variable:SetVariable("CJMissionUnionPos", CJ_MissionMini_Frame:GetProperty("UnifiedPosition"), 1)
end

--================================================
-- 设置位置
--================================================
function CJ_MissionMini_SetPosition()	
	local cjUnionPos = Variable:GetVariable("CJMissionUnionPos")
	if cjUnionPos ~= nil then
		CJ_MissionMini_Frame:SetProperty("UnifiedPosition", cjUnionPos)
	end
end