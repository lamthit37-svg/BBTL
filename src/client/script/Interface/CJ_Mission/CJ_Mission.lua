-- 任务界面

local g_unifiedposistion
local g_ui_command = 99932103
local g_killNum = 0
local g_monsterKillNum = 0
local g_airdropNum = 0
local g_scoreTotal = 0

local g_score = {
	kill = 2,
	monster = 1,
	airdrop = 10,
}
function CJ_Mission_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("TLCJ_BATTLE_MISSIONUI_SHOW")
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)
end

function CJ_Mission_OnLoad()
	g_unifiedposistion = CJ_Mission_Frame:GetProperty("UnifiedPosition")
end

function CJ_Mission_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then
		CJ_Mission_OnShow()
	elseif ( event == "TLCJ_BATTLE_MISSIONUI_SHOW" ) then
		CJ_Mission_OpenShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_Mission_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_Mission_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		CJ_Mission_CloseClicked()
	elseif(event == "PLAYER_LEAVE_WORLD") then
		CJ_Mission_CloseClicked()
	end

end

function CJ_Mission_OnShow()

	g_killNum = Get_XParam_INT(0)
	g_monsterKillNum = Get_XParam_INT(1)
	g_airdropNum = Get_XParam_INT(2)
	g_scoreTotal = Get_XParam_INT(3)

	CJ_Mission_UIShow()
end

function CJ_Mission_OpenShow()
	if IsWindowShow("CJ_MissionMini") then
		CloseWindow("CJ_MissionMini", true)
	end
	
	CJ_Mission_SetPosition()
	CJ_Mission_UIShow()
	this:Show()
end

function CJ_Mission_UIShow()
	local strKillNum = ScriptGlobal_Format("#{TLCJ_20240709_202}", g_killNum)
	CJ_Mission_Text_1_Num:SetText(strKillNum)

	local strMonsterKillNum = ScriptGlobal_Format("#{TLCJ_20240709_287}", g_monsterKillNum)
	CJ_Mission_Text_2_Num:SetText(strMonsterKillNum)

	local strAirdropNum = ScriptGlobal_Format("#{TLCJ_20240709_203}", g_airdropNum)
	CJ_Mission_Text_3_Num:SetText(strAirdropNum)

	--local score = g_score.kill*g_killNum + g_score.monster*g_monsterKillNum + g_score.airdrop*g_airdropNum
	local strScore = ScriptGlobal_Format("#{TLCJ_20240709_246}", g_scoreTotal)
	CJ_Misson_Explain_Text:SetText(strScore)
end

--================================================
-- 关闭
--================================================
function CJ_Mission_OpenMini()
	CJ_Mission_SavePosition()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_Mission_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_Mission_ResetPos()
	CJ_Mission_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

--================================================
-- 存储位置
--================================================
function CJ_Mission_SavePosition()
	Variable:SetVariable("CJMissionUnionPos", CJ_Mission_Frame:GetProperty("UnifiedPosition"), 1)
end

--================================================
-- 设置位置
--================================================
function CJ_Mission_SetPosition()	
	local cjUnionPos = Variable:GetVariable("CJMissionUnionPos")
	if cjUnionPos ~= nil then
		CJ_Mission_Frame:SetProperty("UnifiedPosition", cjUnionPos)
	end
end

--================================================
-- 帮助
--================================================
function CJ_Mission_OpenHelp()
	PushEvent("QUEST_HELP_MSG", "#{TLCJ_20240709_290}")
end
