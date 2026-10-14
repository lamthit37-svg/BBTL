--试剑天下最小化
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition
local m_IsFuckBaby = 0
--预加载函数，可以而且只能在这里注册脚本关心的事件
function BS_SeaMatch_FightMiNi_PreLoad()
	this:RegisterEvent("SJTX_FIGHTUI_OP")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SJTX_JIESUAN", false)
	this:RegisterEvent("SJTX_CLOSEUI", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_SeaMatch_FightMiNi_ResetPos()
	BS_SeaMatch_FightMiNi_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BS_SeaMatch_FightMiNi_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function BS_SeaMatch_FightMiNi_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= BS_SeaMatch_FightMiNi_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= BS_SeaMatch_FightMiNi_Frame:GetProperty("UnifiedYPosition");
end


--响应事件的函数，当注册的事件发生时会调用的函数
function BS_SeaMatch_FightMiNi_OnEvent(event)
	-- PushDebugMessage(event)
	if event == "SJTX_FIGHTUI_OP" then
		local  opType = tonumber(arg0)
		if opType == 2 then --打开界面
			if (this:IsVisible()) then
				BS_SeaMatch_FightMiNi_Update()
				return
			end
			BS_SeaMatch_FightMiNi_Show()
			BS_SeaMatch_FightMiNi_Update()
		elseif opType == 1 then --关闭界面
			BS_SeaMatch_FightMiNi_Hide()
		end
	elseif (event == "SJTX_JIESUAN") then
		BS_SeaMatch_FightMiNi_Hide()
	elseif (event == "SJTX_CLOSEUI") then
		BS_SeaMatch_FightMiNi_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BS_SeaMatch_FightMiNi_Hide()
	elseif event == "ADJEST_UI_POS" then
		BS_SeaMatch_FightMiNi_ResetPos()
	end
end

--显示UI
function BS_SeaMatch_FightMiNi_Show()
	BS_SeaMatch_FightMiNi_ClearData()

	this:Show()
	
end
--隐藏UI
function BS_SeaMatch_FightMiNi_Hide()
	BS_SeaMatch_FightMiNi_ClearData()

	this:Hide()
end

--清除数据
function BS_SeaMatch_FightMiNi_ClearData()
	m_IsFuckBaby = 0
end
--更新
function BS_SeaMatch_FightMiNi_Update()
	local teamAName, teamBName = SJTX:LuaFnGetSJTXTeamName()
	if "" == teamAName or "" == teamBName then
		BS_SeaMatch_FightMiNi_Hide()
		return
	end
end

--##############点击事件##############
function BS_SeaMatch_FightMiNi_OnShowNormalUI()
	PushEvent("SJTX_FIGHTUI_OP", 1)
end
--####################################